#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.22

// vers 7.13e

// TODO:
//
// -- search for TODO for unresolved issues not on this list
//
// -- add comments to the code as needed
//
// -- write the help file, and link the help buttons to the help docs
//
// -- examples?
//
// -- added a test function AutoFix_Rollover_Steps() that will search for steps (simple delta) that 
//    are +/- 0.1s away from the 6.7s missed rollover. This function looks for up, down, then re-calculates
//    the derivative. ?? should this be set to work only between the cursors? Currently it does the whole set.
//
// -- added a test function PutCursorsAtBigStep(tol). that will look for a big "jump", larger than tol.
//    find a way to work this into the panel, maybe add a button and a setVar to set the value
//
//
// -- EC_FindStepButton_down (and up) now both do the SAME thing -- using the "PutCursorsAtBigStep" function 
//    as above. This may change in the future...
//
//
// -- NEW 2016
//
// -- see the Procedure DecodeBinaryEvents(numToPrint) for a first implementation of a "viewer"
//    for the binary events. Prints out the decoded 32-bit binary to the command window for inspection
//    Could be modified as needed to flag events, see what bad events really look like, etc. (May 2016)

//  -- see the proc DisplayForSlicing() that may aid in setting the bins properly by plotting the 
//     bins along with the differential collection rate
//
// -- ?? need way to get correspondence between .hst files and VAX files? Names are all different. See
//    DateAndTime2HSTName() functions and similar @ bottom of this file
//
// x- add the XOP to the distribution package
//
// x- Need to make sure that the rescaledTime and the differentiated time graphs are
//     being properly updated when the data is processed, modified, etc.
//
// -- I need better nomenclature other than "stream" for the "continuous" data set.
//     It's all a stream, just sometimes it's not oscillatory
//
//
// X- the slice display "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
//     interprets the data as being RGB - and so does nothing.
//     need to find a way around this. This was fixed by displaying the data using the G=1 flag on AppendImage
//     to prevent the "atuo-detection" of data as RGB
//
// -- Do something with the PP events. Currently, only the PP events that are XY (just the
//    type 0 events (since I still need to find out what they realy mean)
//
// -- Add a switch to allow Sorting of the Stream data to remove the "time-reversed" data
//     points. Maybe not kosher, but would clean things up.
//
// -- when a large stream file is split, and each segment is edited, it is re-loaded from a list and is currently
//    NOT decimated, and there is no option. There could be an option for this, especially for these
//    large files. The issue is that the data segments are concatentated (adjusting the time) and can
//    be too large to handle (a 420 MB event file split and edited and re-loaded becomes a 1.6 GB Igor experiment!!)
//
//    -- so allow the option of either decimation of the segments as they are loaded, or create the option to 
//       bin on the fly so that the full concatentated set does not need to be stored. Users could be 
//       directed to determine the binning and manipulate the data of a sufficiently decimated data set
//       first to set the binning, then only process the full set.
//
///////////////////////////////
//
// NOTE -- to be able to show the T0 and PP event locations/times, force the loader to use the Igor code rather than
// the XOP. Then there will be waves generated with their locations: T0Time and T0EventNum, PPTime and PPEventNum. Edit these waves
// and (1) delete the zero points at the end of the waves and (2) multiply the Time wave * 1e-7 to convert to seconds.
// Then the waves can be plotted on top of the event data, so it can be seen where these events were identified.
//
///////////////   SWITCHES     /////////////////
//
// for the "File Too Big" limit:
//	Variable/G root:Packages:NIST:Event:gEventFileTooLarge = 150		// 150 MB considered too large
//
// for the tolerance of "step" detection
//	Variable/G root:Packages:NIST:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
//
//
///////// DONE //////////
//
// X- memory issues:
//		-- in LoadEvents -- should I change the MAKE to:
//				/I/U is unsigned 32-bit integer (for the time)
//	   			/B/U is unsigned 8-bit integer (max val=255) for the x and y values
//			-- then how does this affect downstream processing - such as rescaledTime, differentiation, etc.
//			x- and can I re-write the XOP to create these types of data waves, and properly fill them...
//
//  **- any integer waves must be translated by Igor into FP to be able to be displayed or for any
//    type of analysis. so it's largely a waste of time to use integers. so simply force the XOP to 
//    generate only SP waves. this will at least save some space.
//
//
//
// x- Is there any way to improve the speed of the loader? How could an XOP be structured
//     for maximum flexibility? Leave the post processing to Igor, but how much for the XOP
//     to do? And can it handle such large amounts of data to pass back and forth, or
//     does it need to be written as an operation, rather than a function??? I'd really 
//     rather that Igor handles the memory management, not me, if I write the XOP.
//
// **- as of 11/27, the OSX version of the XOP event loader is about 35x faster for the load!
//    and is taking approx 1.8s/28MB, or about 6.5s/100MB of file. quite reasonable now, and
//    probably a bit faster yet on the PC.
//
//
// X- fix the log/lin display - it's not working correctly
// 			I could use ModifyImage and log = 0|1 keyword for the log Z display
// 			rather than creating a duplicate wave of log(data)
// 			-- it's in the Function sliceSelectEvent_Proc()
//
// X- add controls to show the bar graph
// x- add popup for selecting the binning type
// x- add ability to save the slices to RAW VAX files
// X- add control to show the bin counts and bin end times
// x- ADD buttons, switches, etc for the oscillatory mode - so that this can be accessed
//
// x- How are the headers filled for the VAX files from Teabag???
// -- I currently read the events 2x. Once to count the events to make the waves the proper
//     size, then a second time to actualy process the events. Would it be faster to insert points
//     as needed, or to estimate the size, and make it too large, then trim at the end...
// ((( NO -- I have no good way of getting a proper estimate of how many XY events there are for a file))
//
//
//


//
// These are also defined in the TISANE procedure file. In both files they are declared
// as Static, so they are local to each procedure
//
Static Constant ATXY = 0
Static Constant ATXYM = 2
Static Constant ATMIR = 1
Static Constant ATMAR = 3

Static Constant USECSPERTICK=0.1 // microseconds
Static Constant TICKSPERUSEC=10
Static Constant XBINS=128
Static Constant YBINS=128
//

Static Constant MODE_STREAM = 0
Static Constant MODE_OSCILL = 1
Static Constant MODE_TISANE = 2
Static Constant MODE_TOF = 3

//Menu "Macros"
//	"Split Large File",SplitBigFile()
//	"Accumulate First Slice",AccumulateSlices(0)
//	"Add Current Slice",AccumulateSlices(1)
//	"Display Accumulated Slices",AccumulateSlices(2)	
//End



Proc Show_Event_Panel()
	DoWindow/F EventModePanel
	if(V_flag ==0)
		Init_Event()
		EventModePanel()
	EndIf
End


Function Init_Event()

	NewDataFolder/O/S root:Packages:NIST:Event

	String/G 	root:Packages:NIST:Event:gEvent_logfile
	String/G 	root:Packages:NIST:Event:gEventDisplayString="Details of the file load"
	
	Variable/G 	root:Packages:NIST:Event:AIMTYPE_XY=0 // XY Event
	Variable/G 	root:Packages:NIST:Event:AIMTYPE_XYM=2 // XY Minor event
	Variable/G 	root:Packages:NIST:Event:AIMTYPE_MIR=1 // Minor rollover event
	Variable/G 	root:Packages:NIST:Event:AIMTYPE_MAR=3 // Major rollover event

	Variable/G root:Packages:NIST:Event:gEvent_time_msw = 0
	Variable/G root:Packages:NIST:Event:gEvent_time_lsw = 0
	Variable/G root:Packages:NIST:Event:gEvent_t_longest = 0

	Variable/G root:Packages:NIST:Event:gEvent_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:Event:gEvent_nslices = 10  //Number of time slices
	
	Variable/G root:Packages:NIST:Event:gEvent_logint = 1

	Variable/G root:Packages:NIST:Event:gEvent_Mode = MODE_OSCILL				// ==0 for "stream", ==1 for Oscillatory
	Variable/G root:Packages:NIST:Event:gRemoveBadEvents = 1		// ==1 to remove "bad" events, ==0 to read "as-is"
	Variable/G root:Packages:NIST:Event:gSortStreamEvents = 0		// ==1 to sort the event stream, a last resort for a stream of data
	
	Variable/G root:Packages:NIST:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	
		
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData


// for decimation
	Variable/G root:Packages:NIST:Event:gEventFileTooLarge = 2500		// 2500 MB considered too large
	Variable/G root:Packages:NIST:Event:gDecimation = 100
	Variable/G root:Packages:NIST:Event:gEvent_t_longest_decimated = 0
	Variable/G root:Packages:NIST:Event:gEvent_t_segment_start = 0
	Variable/G root:Packages:NIST:Event:gEvent_t_segment_end = 0

// for large file splitting
	String/G root:Packages:NIST:Event:gSplitFileList = ""		// a list of the file names as split
	
// for editing
	Variable/G root:Packages:NIST:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
	
	SetDataFolder root:
End

//
// -- extra bits of buttons... not used
//
//	Button button9 title="Decimation",size={100,20},pos={490,400},proc=E_ShowDecimateButton
//
//	Button button11,pos={490,245},size={150,20},proc=LoadDecimateButtonProc,title="Load and Decimate"
//	Button button12,pos={490,277},size={150,20},proc=ConcatenateButtonProc,title="Concatenate"
//	Button button13,pos={490,305},size={150,20},proc=DisplayConcatenatedButtonProc,title="Display Concatenated"
//	
//	GroupBox group0 title="Manual Controls",size={185,112},pos={490,220}
//
//	NewPanel /W=(82,44,854,664)/N=EventModePanel/K=2
//	DoWindow/C EventModePanel
//	ModifyPanel fixedSize=1,noEdit =1
Proc EventModePanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(82,44,884,664)/N=EventModePanel/K=2
	DoWindow/C EventModePanel
//	ModifyPanel fixedSize=1,noEdit =1

	SetDrawLayer UserBack
	DrawText 479,345,"Stream Data"
	DrawLine 563,338,775,338
	DrawText 479,419,"Oscillatory Data"
	DrawLine 580,411,775,411

//	ShowTools/A
	Button button0,pos={14,87},size={150,20},proc=LoadEventLog_Button,title="Load Event Log File"
	Button button0,fSize=12
	TitleBox tb1,pos={475,500},size={266,86},fSize=10
	TitleBox tb1,variable= root:Packages:NIST:Event:gEventDisplayString

	CheckBox chkbox2,pos={376,151},size={81,15},proc=LogIntEvent_Proc,title="Log Intensity"
	CheckBox chkbox2,fSize=10,variable= root:Packages:NIST:Event:gEvent_logint
	CheckBox chkbox3,pos={14,125},size={119,15},title="Remove Bad Events?",fSize=10
	CheckBox chkbox3,variable= root:Packages:NIST:Event:gRemoveBadEvents
	
	Button doneButton,pos={738,36},size={50,20},proc=EventDone_Proc,title="Done"
	Button doneButton,fSize=12
	Button button2,pos={486,200},size={140,20},proc=ShowEventDataButtonProc,title="Show Event Data"
	Button button3,pos={486,228},size={140,20},proc=ShowBinDetailsButtonProc,title="Show Bin Details"
	Button button5,pos={633,228},size={140,20},proc=ExportSlicesButtonProc,title="Export Slices as VAX"
	Button button6,pos={748,9},size={40,20},proc=EventModeHelpButtonProc,title="?"
		
	Button button7,pos={211,33},size={120,20},proc=AdjustEventDataButtonProc,title="Adjust Events"
	Button button8,pos={653,201},size={120,20},proc=CustomBinButtonProc,title="Custom Bins"
	Button button4,pos={211,63},size={120,20},proc=UndoTimeSortButtonProc,title="Undo Time Sort"
	Button button18,pos={211,90},size={120,20},proc=EC_ImportWavesButtonProc,title="Import Edited"
	
	SetVariable setvar0,pos={208,149},size={160,16},proc=sliceSelectEvent_Proc,title="Display Time Slice"
	SetVariable setvar0,fSize=10
	SetVariable setvar0,limits={0,1000,1},value= root:Packages:NIST:Event:gEvent_tsdisp	
	SetVariable setvar1,pos={389,29},size={160,16},title="Number of slices",fSize=10
	SetVariable setvar1,limits={1,1000,1},value= root:Packages:NIST:Event:gEvent_nslices
	SetVariable setvar2,pos={389,54},size={160,16},title="Max Time (s)",fSize=10
	SetVariable setvar2,value= root:Packages:NIST:Event:gEvent_t_longest
	
	PopupMenu popup0,pos={389,77},size={119,20},proc=BinTypePopMenuProc,title="Bin Spacing"
	PopupMenu popup0,fSize=10
	PopupMenu popup0,mode=1,popvalue="Equal",value= #"\"Equal;Fibonacci;Custom;\""
	Button button1,pos={389,103},size={120,20},fSize=12,proc=ProcessEventLog_Button,title="Bin Event Data"

	Button button10,pos={488,305},size={100,20},proc=SplitFileButtonProc,title="Split Big File"
	Button button14,pos={488,350},size={120,20},proc=Stream_LoadDecim,title="Load+Decimate"
	Button button19,pos={639,350},size={130,20},proc=Stream_LoadAdjustedList,title="Load+Concatenate"
	Button button20,pos={680,305},size={90,20},proc=ShowList_ToLoad,title="Show List"

	Button button21,pos={649,378},size={120,20},proc=Stream_LoadAdjList_BinOnFly,title="Load+Accumulate"

	SetVariable setvar3,pos={487,378},size={150,16},title="Decimation factor"
	SetVariable setvar3,fSize=10
	SetVariable setvar3,limits={1,inf,1},value= root:Packages:NIST:Event:gDecimation

	Button button15_0,pos={488,425},size={110,20},proc=AccumulateSlicesButton,title="Add First Slice"
	Button button16_1,pos={488,450},size={110,20},proc=AccumulateSlicesButton,title="Add Next Slice"
	Button button17_2,pos={620,425},size={110,20},proc=AccumulateSlicesButton,title="Display Total"
	Button button22,pos={620,450},size={120,20},proc=Osc_LoadAdjList_BinOnFly,title="Load+Accumulate"

	CheckBox chkbox1_0,pos={25,34},size={69,14},title="Oscillatory",fSize=10
	CheckBox chkbox1_0,mode=1,proc=EventModeRadioProc,value=1
	CheckBox chkbox1_1,pos={25,59},size={53,14},title="Stream",fSize=10
	CheckBox chkbox1_1,proc=EventModeRadioProc,value=0,mode=1
	CheckBox chkbox1_2,pos={104,59},size={53,14},title="TISANE",fSize=10
	CheckBox chkbox1_2,proc=EventModeRadioProc,value=0,mode=1
	CheckBox chkbox1_3,pos={104,34},size={37,14},title="TOF",fSize=10
	CheckBox chkbox1_3,proc=EventModeRadioProc,value=0,mode=1
	
	GroupBox group0_0,pos={5,5},size={174,112},title="(1) Loading Mode",fSize=12,fStyle=1
	GroupBox group0_1,pos={372,5},size={192,127},title="(3) Bin Events",fSize=12,fStyle=1
	GroupBox group0_2,pos={477,169},size={310,92},title="(4) View / Export",fSize=12,fStyle=1
	GroupBox group0_3,pos={191,5},size={165,117},title="(2) Edit Events",fSize=12,fStyle=1
	GroupBox group0_4,pos={474,278},size={312,200},title="Split / Accumulate Files",fSize=12
	GroupBox group0_4,fStyle=1
	
	Display/W=(10,170,460,610)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:Event:dispsliceData		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage dispsliceData ctab= {*,*,ColdWarm,0}
	ModifyImage dispsliceData ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slicegraph
	SetActiveSubwindow ##
EndMacro




// mode selector
//Static Constant MODE_STREAM = 0
//Static Constant MODE_OSCILL = 1
//Static Constant MODE_TISANE = 2
//Static Constant MODE_TOF = 3
//
Function EventModeRadioProc(name,value)
	String name
	Variable value
	
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	
	strswitch (name)
		case "chkbox1_0":
			gEventModeRadioVal= MODE_OSCILL
			break
		case "chkbox1_1":
			gEventModeRadioVal= MODE_STREAM
			break
		case "chkbox1_2":
			gEventModeRadioVal= MODE_TISANE
			break
		case "chkbox1_3":
			gEventModeRadioVal= MODE_TOF
			break
	endswitch
	CheckBox chkbox1_0,value= gEventModeRadioVal==MODE_OSCILL
	CheckBox chkbox1_1,value= gEventModeRadioVal==MODE_STREAM
	CheckBox chkbox1_2,value= gEventModeRadioVal==MODE_TISANE
	CheckBox chkbox1_3,value= gEventModeRadioVal==MODE_TOF

	return(0)
End

Function AdjustEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowEventCorrectionPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CustomBinButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "Show_CustomBinPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ShowEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowRescaledTimeGraph()"
			//
			DifferentiatedTime()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BinTypePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			if(cmpstr(popStr,"Custom")==0)
				Execute "Show_CustomBinPanel()"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ShowBinDetailsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowBinTable()"
			Execute "BinEventBarGraph()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function UndoTimeSortButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "UndoTheSorting()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ExportSlicesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ExportSlicesAsVAX()"		//will invoke the dialog
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EventModeHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z "Event Mode Data"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EventDone_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K EventModePanel
			break
	endswitch
	return(0)
End



Function ProcessEventLog_Button(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR mode=root:Packages:NIST:Event:gEvent_Mode
	
	if(mode == MODE_STREAM)
		Stream_ProcessEventLog("")
	endif
	
	if(mode == MODE_OSCILL)
		Osc_ProcessEventLog("")
	endif
	
	// If TOF mode, process as Oscillatory -- that is, take the times as is
	if(mode == MODE_TOF)
		Osc_ProcessEventLog("")
	endif
	
	// toggle the checkbox for log display to force the display to be correct
	NVAR gLog = root:Packages:NIST:Event:gEvent_logint
	LogIntEvent_Proc("",gLog)
	
	return(0)
end

// for oscillatory mode
//
Function Osc_ProcessEventLog(ctrlName)
	String ctrlName

	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount
	Make/O/D/N=(nslices) timeWidth
	Wave timeWidth = timeWidth
	Wave binEndTime = binEndTime
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0


	String binTypeStr=""
	ControlInfo /W=EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch


// now before binning, sort the data

	//MakeIndex is REALLY SLOW - this is slow - to allow undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	//
	// for a 500 MB hst, MakeIndex = 83s, everything else in this function totalled < 5s
	//
	SetDataFolder root:Packages:NIST:Event:

	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
//		tic()
		MakeIndex rescaledTime OscSortIndex
//		toc()
//		tic()
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
//		toc()
		//SetDataFolder root:Packages:NIST:Event
//		tic()
		IndexForHistogram(xLoc,yLoc,binnedData)			// index the events AFTER sorting
//		toc()
		//SetDataFolder root:
	Endif
	
	Wave index = root:Packages:NIST:Event:SavedIndex		//this is the histogram index

//	tic()
	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

	// typically zero will never be a valid time value in oscillatory mode. in "stream" mode, the first is normalized to == 0
	// but not here - times are what they are.
		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
//		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

//	toc()
	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End

// for a "continuous exposure"
//
// if there is a sort of these events, I need to re-index the events for the histogram
// - see the oscillatory mode  - and sort the events here, then immediately re-index for the histogram
// - but with the added complication that I need to always remember to index for the histogram, every time
// - since I don't know if I've sorted or un-sorted. Osc mode always forces a re-sort and a re-index
//
Function Stream_ProcessEventLog(ctrlName)
	String ctrlName

//	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth

	
	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR yesSortStream = root:Packages:NIST:Event:gSortStreamEvents		//do I sort the events?
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount//,binStartTime
	Make/O/D/N=(nslices) timeWidth
	Wave binEndTime = binEndTime
	Wave timeWidth = timeWidth
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0
	
	String binTypeStr=""
	ControlInfo /W=EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch

// TODO
// the global exists for this switch, but it is not implemented - not sure whether
// it's correct to implement this at all --
//
	if(yesSortStream == 1)
		SortTimeData()
	endif
	
// index the events before binning
// if there is a sort of these events, I need to re-index the events for the histogram
//	SetDataFolder root:Packages:NIST:Event
	IndexForHistogram(xLoc,yLoc,binnedData)
//	SetDataFolder root:
	Wave index = root:Packages:NIST:Event:SavedIndex		//the index for the histogram
	
	
	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
//		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End


Proc	UndoTheSorting()
	Osc_UndoSort()
End

// for oscillatory mode
//
// -- this takes the previously generated index, and un-sorts the data to restore to the
// "as-collected" state
//
Function Osc_UndoSort()

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	Wave rescaledTime = rescaledTime
	Wave OscSortIndex = OscSortIndex
	Wave yLoc = yLoc
	Wave xLoc = xLoc
	Wave timePt = timePt

	Sort OscSortIndex OscSortIndex,yLoc,xLoc,timePt,rescaledTime

	KillWaves/Z OscSortIndex
	
	SetDataFolder root:
	return(0)
End


// now before binning, sort the data
//
//this is slow - undoing the sorting and starting over, but if you don't,
// you'll never be able to undo the sort
//
Function SortTimeData()


	SetDataFolder root:Packages:NIST:Event:

	KillWaves/Z OscSortIndex
	
	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
	Endif
	
	SetDataFolder root:
	return(0)
End



Function SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable del,ii,t2
	binEndTime[0]=0		//so the bar graph plots right...
	del = t_longest/nslices
	
	for(ii=0;ii<nslices;ii+=1)
		t2 = (ii+1)*del
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest*(1-1e-6)		//otherwise floating point errors such that the last time point is off the end of the Binary search

	timeWidth = binEndTime[p+1]-binEndTime[p]

	return(0)	
End

// TODO
// either get this to work, or scrap it entirely. it currently isn't on the popup
// so it can't be accessed
Function SetLogBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii

	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime
	
	binEndTime[0]=0		//so the bar graph plots right...

	// just like the log-scaled q-points
	tMin = rescaledTime[1]/1			//just a guess... can't use tMin=0, and rescaledTime[0] == 0 by definition
	Print rescaledTime[1], tMin
	for(ii=0;ii<nslices;ii+=1)
		binEndTime[ii+1] =alog(log(tMin) + (ii+1)*((log(t_longest)-log(tMin))/nslices))
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	timeWidth = binEndTime[p+1]-binEndTime[p]

	return(0)
End

Function MakeFibonacciWave(w,num)
	Wave w
	Variable num

	//skip the initial zero
	Variable f1,f2,ii
	f1=1
	f2=1
	w[0] = f1
	w[1] = f2
	for(ii=2;ii<num;ii+=1)
		w[ii] = f1+f2
		f1=f2
		f2=w[ii]
	endfor
		
	return(0)
end

Function SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii,total,t2,tmp
	Make/O/D/N=(nslices) fibo
	fibo=0
	MakeFibonacciWave(fibo,nslices)
	
//	Make/O/D tmpFib={1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946}

	binEndTime[0]=0		//so the bar graph plots right...
	total = sum(fibo,0,nslices-1)		//total number of "pieces"
	
	tmp=0
	for(ii=0;ii<nslices;ii+=1)
		t2 = sum(fibo,0,ii)/total*t_longest
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	timeWidth = binEndTime[p+1]-binEndTime[p]
	
	return(0)
End



// TODO:
//
// ** currently, the "stream" loader uses the first data point as time=0
//    and rescales everything to that time. "Osc" loading uses the times "as-is"
//    from the file, trusting the times to be correct.
//
// Would TISANE or TOF need a different loader?
//	
Function LoadEventLog_Button(ctrlName) : ButtonControl
	String ctrlName

	NVAR mode=root:Packages:NIST:Event:gEvent_mode
	Variable err=0
	Variable fileref,totBytes
	NVAR fileTooLarge = root:Packages:NIST:Event:gEventFileTooLarge		//limit load to 150MB

	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	String abortStr
	
	PathInfo/S catPathName
	if(V_flag==0)
		DoAlert 0,"Please 'Pick Path' to the data from the Main (yellow) Panel."
		return(0)
	endif
	
	
	Open/R/D/P=catPathName/F=fileFilters fileref
	filename = S_filename
	if(strlen(S_filename) == 0)
		// user cancelled
		DoAlert 0,"No file selected, no file loaded."
		return(1)
	endif
	
/// Abort if the files are too large
	Open/R fileref as fileName
		FStatus fileref
	Close fileref

	totBytes = V_logEOF/1e6		//in MB
	if(totBytes > fileTooLarge)
		sprintf abortStr,"File is %g MB, larger than the limit of %g MB. Split and Decimate.",totBytes,fileTooLarge
		Abort abortStr
	endif
	

#if (exists("EventLoadWave")==4)
	LoadEvents_XOP()
#else
	// XOP is not present, warn the user to re-run the installer
	//check the 32-bit or 64-bit
	String igorKindStr = StringByKey("IGORKIND", IgorInfo(0) )
	String alertStr
	if(strsearch(igorKindStr, "64", 0 ) != -1)
		alertStr = "The Event Loader XOP is not installed for the 64-bit version of Igor. Without it, event loading will "
		alertStr += "be slow. It is recommended that you re-run the NCNR Installer. Click NO to stop and "
		alertStr += "do the installation, or YES to continue with the file loading."
	else
		alertStr = "The Event Loader XOP is not installed for the 32-bit version of Igor. Without it, event loading will "
		alertStr += "be slow. It is recommended that you re-run the NCNR Installer. Click NO to stop and "
		alertStr += "do the installation, or YES to continue with the file loading."
	endif
	DoAlert 1,alertStr
	
	if(V_flag == 0)
		// get out gracefully
		SetDataFolder root:
		return(0)
	endif

	LoadEvents_New_noXOP()
//	LoadEvents()

	
#endif	

	SetDataFolder root:Packages:NIST:Event:

//tic()
	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes	
//toc()
	
	
/////
// now do a little processing of the times based on the type of data
//	
	if(mode == MODE_STREAM)		// continuous "Stream" mode - start from zero
		Duplicate/O timePt rescaledTime
		MultiThread rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
		t_longest = waveMax(rescaledTime)		//should be the last point	
	endif
	
	if(mode == MODE_OSCILL)		// oscillatory mode - don't adjust the times, we get periodic t0 to reset t=0
		Duplicate/O timePt rescaledTime
		MultiThread rescaledTime *= 1e-7			//convert to seconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif

// MODE_TISANE
//TODO -- tisane doesn't do anything different than oscillatory. Is this really correct??
	if(mode == MODE_TISANE)		// TISANE mode - don't adjust the times, we get periodic t0 to reset t=0
		Duplicate/O timePt rescaledTime
		MultiThread rescaledTime *= 1e-7			//convert to seconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif
	
// MODE_TOF
	if(mode == MODE_TOF)		// TOF mode - don't adjust the times, we get periodic t0 to reset t=0
		Duplicate/O timePt rescaledTime
		MultiThread rescaledTime *= 1e-7			//convert to seconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif

	SetDataFolder root:

	STRUCT WMButtonAction ba
	ba.eventCode = 2
	ShowEventDataButtonProc(ba)

	SetDataFolder root:

	return(0)
End

//// for the mode of "one continuous exposure"
////
//Function Stream_LoadEventLog(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
//	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
//	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
//	
//	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
//	
//	Open/R/D/F=fileFilters fileref
//	filename = S_filename
//	if(strlen(S_filename) == 0)
//		// user cancelled
//		DoAlert 0,"No file selected, no file loaded."
//		return(1)
//	endif
//
//#if (exists("EventLoadWave")==4)
//	LoadEvents_XOP()
//#else
//	LoadEvents()
//#endif	
//
//	SetDataFolder root:Packages:NIST:Event:
//
////tic()
//	Wave timePt=timePt
//	Wave xLoc=xLoc
//	Wave yLoc=yLoc
//	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//	
////toc()
//
//	Duplicate/O timePt rescaledTime
//	rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
//	t_longest = waveMax(rescaledTime)		//should be the last point
//
//	SetDataFolder root:
//
//	return(0)
//End
//
//// for the mode "oscillatory"
////
//Function Osc_LoadEventLog(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
//	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
//	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
//	
//	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
//	
//	Open/R/D/F=fileFilters fileref
//	filename = S_filename
//		if(strlen(S_filename) == 0)
//		// user cancelled
//		DoAlert 0,"No file selected, no file loaded."
//		return(1)
//	endif
//	
//#if (exists("EventLoadWave")==4)
//	LoadEvents_XOP()
//#else
//	LoadEvents()
//#endif	
//	
//	SetDataFolder root:Packages:NIST:Event:
//
//	Wave timePt=timePt
//	Wave xLoc=xLoc
//	Wave yLoc=yLoc
//	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//	
//	Duplicate/O timePt rescaledTime
//	rescaledTime *= 1e-7			//convert to seconds and that's all
//	t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
//
//	KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
//
//	SetDataFolder root:
//
//	return(0)
//End


//
// -- MUCH faster to count the number of lines to remove, then delete (N)
// rather then delete them one-by-one in the do-loop
Function CleanupTimes(xLoc,yLoc,timePt)
	Wave xLoc,yLoc,timePt

	// start at the back and remove zeros
	Variable num=numpnts(xLoc),ii,numToRemove

	numToRemove = 0
	ii=num
	do
		ii -= 1
		if(timePt[ii] == 0 && xLoc[ii] == 0 && yLoc[ii] == 0)
			numToRemove += 1
		endif
	while(timePt[ii-1] == 0 && xLoc[ii-1] == 0 && yLoc[ii-1] == 0)
	
	if(numToRemove != 0)
		DeletePoints ii, numToRemove, xLoc,yLoc,timePt
	endif
	
	return(0)
End

Function LogIntEvent_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:Event
	
	Wave slicedData = slicedData
	Wave logSlicedData = logSlicedData
	Wave dispSliceData = dispSliceData
	
	if(checked)
		logslicedData = log(slicedData)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	NVAR selectedslice = root:Packages:NIST:Event:gEvent_tsdisp

	sliceSelectEvent_Proc("", selectedslice, "", "")

	SetDataFolder root:

End


// TODO (DONE)
// this "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
// interprets the data as being RGB - and so does nothing.
// need to find a way around this
//
////  When first plotted, AppendImage/G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
///
// I could modify this procedure to use the log = 0|1 keyword for the log Z display
// rather than creating a duplicate wave of log(data)
//
Function sliceSelectEvent_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	NVAR selectedslice = root:Packages:NIST:Event:gEvent_tsdisp
	
	if(varNum < 0)
		selectedslice = 0
		DoUpdate
	elseif (varNum > nslices-1)
		selectedslice = nslices-1
		DoUpdate
	else
		ModifyImage/W=EventModePanel#Event_slicegraph ''#0 plane = varNum 
	endif

End

Function DifferentiatedTime()

	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime

	SetDataFolder root:Packages:NIST:Event:
		
	Differentiate rescaledTime/D=rescaledTime_DIF
//	Display rescaledTime,rescaledTime_DIF
	DoWindow/F Differentiated_Time
	if(V_flag == 0)
		Display/N=Differentiated_Time/K=1 rescaledTime_DIF
		Legend
		Modifygraph gaps=0
		ModifyGraph zero(left)=1
		Label left "\\Z14Delta (dt/event)"
		Label bottom "\\Z14Event number"
	endif
	
	SetDataFolder root:
	
	return(0)
End


//
// for the bit shifts, see the decimal-binary conversion
// http://www.binaryconvert.com/convert_unsigned_int.html
//
//		K0 = 536870912
// 		Print (K0 & 0x08000000)/134217728 	//bit 27 only, shift by 2^27
//		Print (K0 & 0x10000000)/268435456		//bit 28 only, shift by 2^28
//		Print (K0 & 0x20000000)/536870912		//bit 29 only, shift by 2^29
//
// This is duplicated by the XOP, but the Igor code allows quick access to print out
// all of the gory details of the events and every little bit of them. the print
// statements and flags are kept for this reason, so the code is a bit messy.
//
Function LoadEvents_OLD()
	
	NVAR time_msw = root:Packages:NIST:Event:gEvent_time_msw
	NVAR time_lsw = root:Packages:NIST:Event:gEvent_time_lsw
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:Event:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	
	
////	Variable decFac = 10			//decimation factor
////	Variable jj,keep
	
	SetDataFolder root:Packages:NIST:Event

	Variable fileref
	String buffer
	String fileStr,tmpStr
	Variable dataval,timeval,type,numLines,verbose,verbose3
	Variable xval,yval,rollBit,nRoll,roll_time,bit29,bit28,bit27
	Variable ii,flaggedEvent,rolloverHappened,numBad=0,tmpPP=0,tmpT0=0
	Variable Xmax, yMax
	
	xMax = 127		// number the detector from 0->127 
	yMax = 127
	
	verbose3 = 0			//prints out the rollover events (type==3)
	verbose = 0
	numLines = 0

	
	// what I really need is the number of XY events
	Variable numXYevents,num1,num2,num3,num0,totBytes,numPP,numT0,numDL,numFF,numZero
	Variable numRemoved
	numXYevents = 0
	num0 = 0
	num1 = 0
	num2 = 0
	num3 = 0
	numPP = 0
	numT0 = 0
	numDL = 0
	numFF = 0
	numZero = 0
	numRemoved = 0

//tic()
	Open/R fileref as filepathstr
		FStatus fileref
	Close fileref

	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	if(EventDataType(filePathStr) != 1)		//if not hst extension of raw data
		Abort "Data must be raw event data with file extension .hst for this operation"
		return(0)
	endif	
//toc()
//


// do a "pre-scan to get some of the counts, so that I can allocate space. This does
// double the read time, but is still faster than adding points to waves as the file is read
//	

	tic()

	Open/R fileref as filepathstr
	do
		do
			FReadLine fileref, buffer			//skip the "blank" lines that have one character
		while(strlen(buffer) == 1)		

		if (strlen(buffer) == 0)
			break
		endif
		
		sscanf buffer,"%x",dataval
		
		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
				
		if(type == 0)
			num0 += 1
			numXYevents += 1
		endif
		if(type == 2)
			num2 += 1
			numXYevents += 1
		endif
		if(type == 1)
			num1 += 1
		endif
		if(type == 3)
			num3 += 1
		endif	
		
		bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
		
		if(type==0 || type==2)
			numPP += round(bit29)
		endif
		
		if(type==1 || type==3)
			numT0 += round(bit29)
		endif
		
		if(dataval == 0)
			numZero += 1
		endif
		
	while(1)
	Close fileref
//		done counting the number of XY events
	printf("Igor pre-scan done in  ")
	toc()
	

	Print "(Igor) numT0 = ",numT0	
	Print "num0 = ",num0	
	Print "num1 = ",num1	
	Print "num2 = ",num2	
	Print "num3 = ",num3	

//
//	
//	Printf "numXYevents = %d\r",numXYevents
//	Printf "XY = num0 = %d\r",num0
//	Printf "XY time = num2 = %d\r",num2
//	Printf "time MSW = num1 = %d\r",num1
//	Printf "Rollover = num3 = %d\r",num3
//	Printf "num0 + num2 = %d\r",num0+num2

// dispStr will be displayed on the panel
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numXYevents
	dispStr += tmpStr
	sprintf tmpStr,"PP = %d  :  ",numPP
	dispStr += tmpStr
	sprintf tmpStr,"ZeroData = %d\r",numZero
	dispStr += tmpStr
	sprintf tmpStr,"Rollover = %d",num3
	dispStr += tmpStr

	// /I/U is unsigned 32-bit integer (for the time)
	// /B/U is unsigned 8-bit integer (max val=255) for the x and y values
	
	Make/O/U/N=(numXYevents) xLoc,yLoc
	Make/O/D/N=(numXYevents) timePt
////	Make/O/U/N=(numXYevents/decFac) xLoc,yLoc
////	Make/O/D/N=(numXYevents/decFac) timePt
//	Make/O/U/N=(totBytes/4) xLoc,yLoc		//too large, trim when done (bad idea)
//	Make/O/D/N=(totBytes/4) timePt
	Make/O/D/N=1000 badTimePt,badEventNum,PPTime,PPEventNum,T0Time,T0EventNum
	badTimePt=0
	badEventNum=0
	PPTime=0
	PPEventNum=0
	T0Time=0
	T0EventNum=0
	xLoc=0
	yLoc=0
	timePt=0
	
	nRoll = 0		//number of rollover events
	roll_time = 2^26		//units of 10-7 sec
	
	NVAR removeBadEvents = root:Packages:NIST:Event:gRemoveBadEvents
	
	time_msw=0
	
	tic()
	
	ii = 0		//indexes the points in xLoc,yLoc,timePt
////	keep = decFac		//keep the first point
	
	
	Open/R fileref as filepathstr
	
	// remove events at the beginning up to a type==2 so that the msw and lsw times are reset properly
	if(RemoveBadEvents == 1)
		do
			do
				FReadLine fileref, buffer			//skip the "blank" lines that have one character
			while(strlen(buffer) == 1)		
	
			if (strlen(buffer) == 0)
				break
			endif
			
			sscanf buffer,"%x",dataval
		// two most sig bits (31-30)
			type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
			
			if(type == 2)
				// this is the first event with a proper time value, so process the XY-time event as ususal
				// and then break to drop to the main loop, where the next event == type 1
				
				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8
		
				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
		
				if(verbose)
		//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif
				
				// this is the first point, be sure that ii = 0, and always keep this point
////				if(keep==decFac)
					ii = 0
					xLoc[ii] = xval
					yLoc[ii] = yval
////					keep = 0
////				endif
				Print "At beginning of file, numBad = ",numBad
				break	// the next do loop processes the bulk of the file (** the next event == type 1 = MIR)
			else
				numBad += 1
				numRemoved += 1
			endif
			
			//ii+=1		don't increment the counter
		while(1)
	endif
	
	// now read the main portion of the file.
////	// keep is = 0 if bad points were removed, or is decFac is I need to keep the first point
	do
		do
			FReadLine fileref, buffer			//skip the "blank" lines that have one character
		while(strlen(buffer) == 1)		

		if (strlen(buffer) == 0)				// this marks the end of the file and is our only way out
			break
		endif
		
		sscanf buffer,"%x",dataval
		

//		type = (dataval & ~(2^32 - 2^30 -1))/2^30

		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
		
		//
		// The defintions of the event types
		//
		//Constant ATXY = 0
		//Constant ATXYM = 2
		//Constant ATMIR = 1
		//Constant ATMAR = 3
		//
						
		if(verbose > 0)
			verbose -= 1
		endif
//		
		switch(type)
			case ATXY:		// 0
				if(verbose)		
					printf "XY : "		
				endif
				
				// if the datavalue is == 0, just skip it now (it can only be interpreted as type 0, obviously)
				if(dataval == 0 && RemoveBadEvents == 1)
					numRemoved += 1
//					Print "zero at ii= ",ii
					break		//don't increment ii
				endif
				
				// if it's a pileup event, skip it now (this can be either type 0 or 2)
				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				if(bit29 == 1 && RemoveBadEvents == 1)
					PPTime[tmpPP] = timeval
					PPEventNum[tmpPP] = ii
					tmpPP += 1
					numRemoved += 1
					break		//don't increment ii
				endif
				
//				xval = ~(dataval & ~(2^32 - 2^8)) & 127
//				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
//				time_lsw = (dataval & ~(2^32 - 2^29))/2^16

				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8
				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16

				timeval = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw )		//left shift msw by 2^13, then add in lsw, as an integer
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				
				
				// catch the "bad" events:
				// if an XY event follows a rollover, time_msw is 0 by definition, but does not immediately get 
				// re-evalulated here. Throw out only the immediately following points where msw is still 8191
				if(rolloverHappened && RemoveBadEvents == 1)
					// maybe a bad event
					if(time_msw == 8191)
						badTimePt[numBad] = timeVal
						badEventNum[numBad] = ii
						numBad +=1
						numRemoved += 1
					else
						// time_msw has been reset, points are good now, so keep this one
////						if(keep==decFac)
							xLoc[ii] = xval
							yLoc[ii] = yval
							timePt[ii] = timeval
							
	//						if(xval == 127 && yval == 0)
	//							// check bit 29
	//							bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
	//							Print "XY=127,0 : bit29 = ",bit29
	//						endif
							
							ii+=1
							rolloverHappened = 0
////							keep = 0
////						else
////							keep += 1
////						endif
					endif
				else
					// normal processing of good point, keep it
////					if(keep==decFac)
						xLoc[ii] = xval
						yLoc[ii] = yval
						timePt[ii] = timeval
					
	//					if(xval == 127 && yval == 0)
	//						// check bit 29
	//						bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
	//						Printf "XY=127,0 : bit29 = %u : d=%u\r",bit29,dataval
	//					endif
						ii+=1
////						keep = 0
////					else
////						keep += 1
////					endif
				endif


				if(verbose)		
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "d=%u : t=%u : msw=%u : lsw=%u : %u : %u \r",dataval,timeval,time_msw,time_lsw,xval,yval
				endif				
	
//				verbose = 0
				break
			case ATXYM: // 2 
				if(verbose)
					printf "XYM : "
				endif
				
				// if it's a pileup event, skip it now (this can be either type 0 or 2)
				// - but can I do this if this is an XY-time event? This will lead to a wrong time, and a time 
				// assigned to an XY (0,0)...
//				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
//				if(bit29 == 1 && RemoveBadEvents == 1)
//					Print "*****Bit 29 (PP) event set for Type==2, but not handled, ii = ",ii
////					break		//don't increment ii
//				endif
				
//				xval = ~(dataval & ~(2^32 - 2^8)) & 127
//				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
//				time_lsw =  (dataval & ~(2^32 - 2^29 ))/2^16		//this method gives a FP result!! likely since the "^" operation gives FP result...

				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8

				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16 (result is integer)

				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif
				
////				if(keep==decFac)			//don't reset keep yet, do this only when ii increments
					xLoc[ii] = xval
					yLoc[ii] = yval
////				endif
				
				// don't fill in the time yet, or increment the index ii
				// the next event MUST be ATMIR with the MSW time bits
				//
//				verbose = 0
				break
			case ATMIR:  // 1
				if(verbose)
					printf "MIR : "
				endif

				time_msw =  (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
				timeval = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw )
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "d=%u : t=%u : msw=%u : lsw=%u : tlong=%u\r",dataval,timeval,time_msw,time_lsw,t_longest
				endif
				
				// the XY position was in the previous event ATXYM
////				if(keep == decFac)
					timePt[ii] = timeval
////				endif

				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				if(bit29 != 0)		// bit 29 set is a T0 event
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = timeval
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
				
////				if(keep == decFac)			
					ii+=1
////					keep = 0
////				endif
//				verbose = 0
				break
			case ATMAR:  // 3
				if(verbose3)
//					verbose = 15
//					verbose = 2
					printf "MAR : "
				endif
				
				// do something with the rollover event?
				
				// check bit 29
				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				nRoll += 1
// not doing anything with these bits yet	
				bit28 = (dataval & 0x10000000)/268435456		//bit 28 only, shift by 2^28	
				bit27 = (dataval & 0x08000000)/134217728 	//bit 27 only, shift by 2^27

				if(verbose3)
					printf "d=%u : b29=%u : b28=%u : b27=%u : #Roll=%u \r",dataval,bit29, bit28, bit27,nRoll
				endif
				
				if(bit29 != 0)		// bit 29 set is a T0 event
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = timeval
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
				
				rolloverHappened = 1

				break
		endswitch
		
//		if(ii<18)
//			printf "TYPE=%d : ii=%d : d=%u : t=%u : msw=%u : lsw=%u : %u : %u \r",type,ii,dataval,timeval,time_msw,time_lsw,xval,yval
//		endif	
			
	while(1)
	
	Close fileref
	
	printf("Igor full file read done in  ")	
	toc()
	
	Print "Events removed (Igor) = ",numRemoved
	
	sPrintf tmpStr,"\rBad Rollover Events = %d (%4.4g %% of events)",numBad,numBad/numXYevents*100
	dispStr += tmpStr
	sPrintf tmpStr,"\rTotal Events Removed = %d (%4.4g %% of events)",numRemoved,numRemoved/numXYevents*100
	dispStr += tmpStr
	SetDataFolder root:
	
	return(0)
	
End 

//////////////
//
// This calls the XOP, as an operation to load the events
//
// -- it's about 35x faster than the Igor code, so I guess that's OK.
//
// conditional compile the whole inner workings in case XOP is not present
Function LoadEvents_XOP()
#if (exists("EventLoadWave")==4)
	
//	NVAR time_msw = root:Packages:NIST:Event:gEvent_time_msw
//	NVAR time_lsw = root:Packages:NIST:Event:gEvent_time_lsw
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:Event:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	
	SetDataFolder root:Packages:NIST:Event



	Variable fileref
	String buffer
	String fileStr,tmpStr
	Variable dataval,timeval,type,numLines,verbose,verbose3
	Variable xval,yval,rollBit,nRoll,roll_time,bit29,bit28,bit27
	Variable ii,flaggedEvent,rolloverHappened,numBad=0,tmpPP=0,tmpT0=0
	Variable Xmax, yMax
	
	xMax = 127		// number the detector from 0->127 
	yMax = 127
	
	numLines = 0

	//Have to declare local variables for Loadwave so that this compiles without XOP.
	String S_waveNames
	//  and those for the XOP
	Variable V_nXYevents,V_num1,V_num2,V_num3,V_num0,V_totBytes,V_numPP,V_numT0,V_numDL,V_numFF,V_numZero
	Variable V_numBad,V_numRemoved
	
	// what I really need is the number of XY events
	Variable numXYevents,num1,num2,num3,num0,totBytes,numPP,numT0,numDL,numFF,numZero
	Variable numRemoved
	numXYevents = 0
	num0 = 0
	num1 = 0
	num2 = 0
	num3 = 0
	numPP = 0
	numT0 = 0
	numDL = 0
	numFF = 0
	numZero = 0
	numRemoved = 0

// get the total number of bytes in the file
	Open/R fileref as filepathstr
		FStatus fileref
	Close fileref

	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	
	if(EventDataType(filePathStr) != 1)		//if not hst extension of raw data
		Abort "Data must be raw event data with file extension .hst for this operation"
		return(0)
	endif
//
//	Print "scan only"
//	tic()
//		EventLoadWave/R/N=EventWave/W filepathstr
//	toc()

////
//
//  use the XOP operation to load in the data
// -- this does everything - the pre-scan and creating the waves
//
// need to zero the waves before loading, just in case
//

	NVAR removeBadEvents = root:Packages:NIST:Event:gRemoveBadEvents

tic()

//	Wave/Z wave0=wave0
//	Wave/Z wave1=wave1
//	Wave/Z wave2=wave2
//
//	if(WaveExists(wave0))
//		MultiThread wave0=0
//	endif
//	if(WaveExists(wave1))
//		MultiThread wave1=0
//	endif
//	if(WaveExists(wave2))
//		MultiThread wave2=0
//	endif

	if(removeBadEvents)
		EventLoadWave/R/N=EventWave filepathstr
	else
		EventLoadWave/N=EventWave  filepathstr
	endif


	Print "XOP files loaded = ",S_waveNames

////		-- copy the waves over to xLoc,yLoc,timePt
	Wave/Z EventWave0=EventWave0
	Wave/Z EventWave1=EventWave1
	Wave/Z EventWave2=EventWave2
	
	
	Duplicate/O EventWave0,xLoc
	KillWaves/Z EventWave0

	Duplicate/O EventWave1,yLoc
	KillWaves/Z EventWave1

	Duplicate/O EventWave2,timePt
	KillWaves/Z EventWave2

// could do this, but rescaled time will neeed to be converted to SP (or DP)
// and Igor loader was written with Make generating SP/DP waves
	// /I/U is unsigned 32-bit integer (for the time)
	// /B/U is unsigned 8-bit integer (max val=255) for the x and y values
	
//	Redimension/B/U xLoc,yLoc
//	Redimension/I/U timePt

	// access the variables from the XOP
	numT0 = V_numT0
	numPP = V_numPP
	num0 = V_num0
	num1 = V_num1
	num2 = V_num2
	num3 = V_num3
	numXYevents = V_nXYevents
	numZero = V_numZero
	numBad = V_numBad
	numRemoved = V_numRemoved
	
	Print "(XOP) numT0 = ",numT0	
	Print "num0 = ",num0	
	Print "num1 = ",num1	
	Print "num2 = ",num2	
	Print "num3 = ",num3	
	

// dispStr will be displayed on the panel
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numXYevents
	dispStr += tmpStr
	sprintf tmpStr,"PP = %d  :  ",numPP
	dispStr += tmpStr
	sprintf tmpStr,"ZeroData = %d\r",numZero
	dispStr += tmpStr
	sprintf tmpStr,"Rollover = %d",num3
	dispStr += tmpStr

	toc()
	
	Print "Events removed (XOP) = ",numRemoved
	
	sPrintf tmpStr,"\rBad Rollover Events = %d (%4.4g %% of events)",numBad,numBad/numXYevents*100
	dispStr += tmpStr
	sPrintf tmpStr,"\rTotal Events Removed = %d (%4.4g %% of events)",numRemoved,numRemoved/numXYevents*100
	dispStr += tmpStr


// simply to compile a table of # XY vs # bytes
//	Wave/Z nxy = root:numberXY
//	Wave/Z nBytes = root:numberBytes
//	if(WaveExists(nxy) && WaveExists(nBytes))
//		InsertPoints 0, 1, nxy,nBytes
//		nxy[0] = numXYevents
//		nBytes[0] = totBytes
//	endif

	SetDataFolder root:

#endif	
	return(0)
	
End 

//////////////

Proc BinEventBarGraph()
	
	DoWindow/F EventBarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(110,705,610,1132)/N=EventBarGraph /K=1 binCount vs binEndTime
		SetDataFolder fldrSav0
		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=1
		ModifyGraph useBarStrokeRGB=1
		ModifyGraph standoff=0
		SetAxis left 0,*
		Label bottom "\\Z14Time (seconds)"
		Label left "\\Z14Number of Events"
	endif
End


Proc ShowBinTable() 

	DoWindow/F BinEventTable
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Edit/W=(498,699,1003,955) /K=1/N=BinEventTable binCount,binEndTime,timeWidth
		ModifyTable format(Point)=1,sigDigits(binEndTime)=8,width(binEndTime)=100
		SetDataFolder fldrSav0
	endif
EndMacro


// only show the first 1500 data points
//
Proc ShowRescaledTimeGraph()

	DoWindow/F RescaledTimeGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(25,44,486,356)/K=1/N=RescaledTimeGraph rescaledTime
		SetDataFolder fldrSav0
		ModifyGraph mode=0
		ModifyGraph marker=19
		ModifyGraph rgb(rescaledTime)=(0,0,0)
		ModifyGraph msize=1
//		SetAxis/A=2 left			//only autoscale the visible data (based on the bottom limits)
		SetAxis bottom 0,1500
		ErrorBars rescaledTime OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"
		ShowInfo
	endif
	
EndMacro



Proc ExportSlicesAsVAX(firstNum,prefix)
	Variable firstNum=1
	String prefix="SAMPL"

	SaveSlicesAsVAX(firstNum,prefix[0,4])		//make sure that the prefix is 5 chars
End

//////// procedures to be able to export the slices as RAW VAX files.
//
// 1- load the raw data file to use the header (it must already be in RAW)
// 1.5- copy the raw data to the temp folder (STO)
// 1.7- ask for the prefix and starting run number (these are passed in)
// 2- copy the slice of data to the temp folder (STO)
// 3- touch up the time/counts in the slice header values in STO
// 4- write out the VAX file
// 5- repeat (2-4) for the number of slices
//
//
Function SaveSlicesAsVAX(firstNum,prefix)
	Variable firstNum
	String prefix

	DoAlert 1,"Is the full data file loaded as a RAW data file? If not, load it and start over..."
	if(V_flag == 2)
		return (0)
	endif
	
// copy the contents of RAW to STO so I can work from there
	CopyWorkContents("RAW","STO")

	// now declare all of the waves, now that they are sure to be there

	WAVE slicedData=root:Packages:NIST:Event:slicedData
	Make/O/D/N=(128,128) curSlice
	
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	WAVE binEndTime = root:Packages:NIST:Event:binEndTime

	Wave rw=root:Packages:NIST:STO:realsRead
	Wave iw=root:Packages:NIST:STO:integersRead
	Wave/T tw=root:Packages:NIST:STO:textRead
	Wave data=root:Packages:NIST:STO:data
	Wave linear_data=root:Packages:NIST:STO:linear_data
	
	
	Wave rw_raw=root:Packages:NIST:RAW:realsRead
	Wave iw_raw=root:Packages:NIST:RAW:integersRead
	Wave/T tw_raw=root:Packages:NIST:RAW:textRead

// for generating the alphanumeric
	String timeStr= secs2date(datetime,-1)
	String monthStr=StringFromList(1, timeStr  ,"/")
	String numStr="",labelStr

	Variable ii,err,binFraction
	
	for(ii=0;ii<nslices;ii+=1)

		//get the current slice and put it in the STO folder
		curSlice = slicedData[p][q][ii]
		data = curSlice
		linear_data = curSlice
		
		// touch up the header as needed
		// count time = iw[2]
		// monCt = rw[0]
		// detCt = rw[2]
		//tw[0] must now be the file name
		//
		// count time = fraction of total binning * total count time
		// ** NOTE that the count time can only be saved to the VAX file as an INTEGER VALUE
		// so beware what time show up in the file for narrow time bins. Keep track of bin times
		// manually and adjust the ABS scaling accordingly
		//
		binFraction = (binEndTime[ii+1]-binEndTime[ii])/(binEndTime[nslices]-binEndTime[0])
		
		iw[2] = trunc(binFraction*iw_raw[2])
//		Print (binFraction*iw_raw[2])		//this is the REAL precision value, not the saved integer value
		rw[0] = trunc(binFraction*rw_raw[0])
		rw[2] = sum(curSlice,-inf,inf)		//total counts in slice
	
		if(firstNum<10)
			numStr = "00"+num2str(firstNum)
		else
			if(firstNum<100)
				numStr = "0"+num2str(firstNum)
			else
				numStr = num2str(firstNum)
			Endif
		Endif	
		tw[0] = prefix+numstr+".SA2_EVE_"+(num2char(str2num(monthStr)+64))+numStr
		labelStr = tw_raw[6]
		
		labelStr = PadString(labelStr,60,0x20) 	//60 fortran-style spaces
		tw[6] = labelStr[0,59]
		
		//write out the file - this uses the tw[0] and home path
		Write_VAXRaw_Data("STO","",0)

		//increment the run number, alpha
		firstNum += 1	
	endfor

	return(0)
End





/////////////
//The histogramming
//
// 6 AUG 2012
//
// from Igor Exchange, RGerkin
//  http://www.igorexchange.com/node/1373
// -- see the related thread on the mailing list
//
//Function Setup_JointHistogram()
//
////	tic()
//
//	make/D /o/n=1000000 data1=gnoise(1), data2=gnoise(1)
//	make/D /o/n=(25,25) myHist
//	setscale x,-3,3,myHist
//	setscale y,-3,3,myHist
//	IndexForHistogram(data1,data2,myhist)
//	Wave index=SavedIndex
//	EV_JointHistogram(data1,data2,myHist,index)
//	NewImage myHist
//	
////	toc()
//	
//End


Function EV_JointHistogram(w0,w1,hist,index)
	wave w0,w1,hist,index
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 	
	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1} index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// histogram with a point range
//
// x- just need to send x2pnt or findLevel, or something similar to define the POINT
// values
//
// x- can also speed this up since the index only needs to be done once, so the
// histogram operation can be done separately, as the bins require
//
//
Function JointHistogramWithRange(w0,w1,hist,index,pt1,pt2)
	wave w0,w1,hist,index
	Variable pt1,pt2
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)

	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1}/R=[pt1,pt2] index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// just does the indexing, creates wave SavedIndex in the current folder for the index
//
Function IndexForHistogram(w0,w1,hist)
	wave w0,w1,hist
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 
	// Scale between 0 and the number of bins to create an index wave.  
	if(ThreadProcessorCount<4) // For older machines, matrixop is faster.  
		matrixop /free idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	else // For newer machines with many cores, multithreading with make is faster.  
		make/free/n=(n) idx
		multithread idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	endif
 
 	KillWaves/Z SavedIndex
 	MoveWave idx,SavedIndex
 	
//	// Compute the histogram and redimension it.  
//	histogram /b={0,1,bins0*bins1} idx,hist
//	redimension /n=(bins0,bins1) hist // Redimension to 2D.  
//	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
//	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End





////////////// Post-processing of the event mode data
Proc ShowEventCorrectionPanel()
	DoWindow/F EventCorrectionPanel
	if(V_flag ==0)
		EventCorrectionPanel()
	EndIf
End

Proc EventCorrectionPanel()

	PauseUpdate; Silent 1		// building window...
	SetDataFolder root:Packages:NIST:Event:
	
	if(exists("rescaledTime") == 1)
		Display /W=(35,44,761,533)/K=2 rescaledTime
		DoWindow/C EventCorrectionPanel
		ModifyGraph mode=0
		ModifyGraph marker=19
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=1
		ErrorBars rescaledTime OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"	
		SetAxis bottom 0,0.10*numpnts(rescaledTime)		//show 1st 10% of data for speed in displaying
		
		ControlBar 100
		Button button0,pos={18,12},size={70,20},proc=EC_AddCursorButtonProc,title="Cursors"
		Button button1,pos={18,38},size={80,20},proc=EC_ShowAllButtonProc,title="All Data"
		Button button2,pos={18,64},size={110,20},proc=EC_DoDifferential,title="Differential"


		SetVariable setvar0 pos={153,12},title="Tol",size={90,20},value=gStepTolerance
		Button button3,pos={153,38},size={100,20},proc=EC_AutoCorrectSteps,title="Auto Correct"
		Button button4,pos={153,64},size={110,20},proc=EC_AddFindNext,title="Add Find Next"

		
		Button button5,pos={285,12},size={80,20},proc=EC_AddTimeButtonProc,title="Add 6.7s"
		Button button6,pos={285,38},size={80,20},proc=EC_SubtractTimeButtonProc,title="Subtr 6.7s"		
		Button button7,pos={285,64},size={90,20},proc=EC_TrimPointsButtonProc,title="Trim points"
		
	
		Button button8,pos={400,12},size={110,20},proc=EC_FindStepButton_down,title="Find Step Down"
		Button button9,pos={400,38},size={110,20},proc=EC_FindStepButton_up,title="Find Step Up"
		Button button10,pos={400,64},size={100,20},proc=EC_FindOutlierButton,title="Find Outlier"
		Button button11,pos={520,12},size={20,20},proc=EC_NudgeCursor,title=">"
		

		Button button12,pos={683,12},size={30,20},proc=EC_HelpButtonProc,title="?"
		Button button13,pos={625,38},size={90,20},proc=EC_SaveWavesButtonProc,title="Save Waves"
		Button button14,pos={655,64},size={60,20},proc=EC_DoneButtonProc,title="Done"
	

	else
		DoAlert 0, "Please load some event data, then you'll have something to edit."
	endif
	
	SetDataFolder root:
	
EndMacro


Function EC_AutoCorrectSteps(ba)
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			AutoFix_Rollover_Steps()
			
			break
		case -1: // control being killed
			break
	endswitch
		
	return(0)
End

Function EC_NudgeCursor(ba)
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// nudge the leftmost cursor to the right two points
			// presumably to bypass a desired time step
			//
	
			Wave rescaledTime = root:Packages:NIST:Event:rescaledTime
			Variable ptA,ptB,lo
			ptA = pcsr(A)
			ptB = pcsr(B)
			lo=min(ptA,ptB)

			if(lo == ptA)
				Cursor/P A rescaledTime ptA+2	//at the point + 2
				Print "Nudged cursor A two points right"
			else
				Cursor/P B rescaledTime ptB+2	//at the point + 2
				Print "Nudged cursor B two points right"
			endif
			
			break
		case -1: // control being killed
			break
	endswitch
		
	return(0)
End

Function EC_AddFindNext(ba)
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// add time	
			EC_AddTimeButtonProc(ba)
			
		// re-do the differential
			EC_DoDifferential("")
			
		// find the next step down
			EC_FindStepButton_down("")
			
			break
		case -1: // control being killed
			break
	endswitch
		
	return(0)
End



Function EC_AddCursorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Cursor/P A rescaledTime 0
			Cursor/P B rescaledTime numpnts(rescaledTime)-1
			ShowInfo
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// updates the longest time (as does every operation of adjusting the data)
//
Function EC_AddTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Wave timePt = timePt
			Variable rollTime,rollTicks,ptA,ptB,lo,hi
			
			rollTicks = 2^26				// in ticks
			rollTime = 2^26*1e-7		// in seconds
			ptA = pcsr(A)
			ptB = pcsr(B)
			lo=min(ptA,ptB)
			hi=max(ptA,ptB)

			MultiThread timePt[lo,hi] += rollTicks
			MultiThread rescaledTime[lo,hi] += rollTime

			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EC_SubtractTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Wave timePt = timePt
			Variable rollTime,rollTicks,ptA,ptB,lo,hi
			
			rollTicks = 2^26				// in ticks
			rollTime = 2^26*1e-7		// in seconds
			ptA = pcsr(A)
			ptB = pcsr(B)
			lo=min(ptA,ptB)
			hi=max(ptA,ptB)
			
			MultiThread timePt[lo,hi] -= rollTicks
			MultiThread rescaledTime[lo,hi] -= rollTime

			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// points removed are inclusive
//
// put both cursors on the same point to remove just that single point
//
Function EC_TrimPointsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Wave timePt = timePt
			Wave xLoc = xLoc
			Wave yLoc = yLoc
			Variable rollTime,ptA,ptB,numElements,lo,hi
			
			rollTime = 2^26*1e-7		// in seconds
			ptA = pcsr(A)
			ptB = pcsr(B)
			lo=min(ptA,ptB)
			hi=max(ptA,ptB)			
			numElements = abs(ptA-ptB)+1			//so points removed are inclusive
			DeletePoints lo, numElements, rescaledTime,timePt,xLoc,yLoc
			
			printf "Points %g to %g have been deleted in rescaledTime, timePt, xLoc, and yLoc\r",ptA,ptB
			
			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// un-sort the data first, then save it
Function EC_SaveWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			Execute "UndoTheSorting()"
			
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Wave timePt = timePt
			Wave xLoc = xLoc
			Wave yLoc = yLoc
			Save/T xLoc,yLoc,timePt,rescaledTime		//will ask for a name
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// this duplicates all of the bits that would be done if the "load" button was pressed
//
Function EC_ImportWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:

			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
			String tmpStr="",fileStr,filePathStr
			
			// load in the waves, saved as Igor text to preserve the data type
			PathInfo/S catPathName		//should set the next dialog to the proper path...
			filePathStr = PromptForPath("Pick the edited event data")
			if(EventDataType(filePathStr) != 2)		//if not itx extension of edited data
				Abort "Data must be edited data with file extension .itx for this operation"
				return(0)
			endif
			LoadWave/T/O/P=catPathName filePathStr
//			filePathStr = S_fileName

			if(strlen(S_fileName) == 0)
				//user cancelled
				DoAlert 0,"No file selected, nothing done."
				return(0)
			endif
			
			NVAR mode = root:Packages:NIST:Event:gEvent_Mode				// ==0 for "stream", ==1 for Oscillatory
			// clear out the old sort index, if present, since new data is being loaded
			KillWaves/Z OscSortIndex
			Wave timePt=timePt
			Wave rescaledTime=rescaledTime
			
			t_longest = waveMax(rescaledTime)		//should be the last point
			
	
			fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
			sprintf tmpStr, "%s: a user-modified event file\r",fileStr 
			dispStr = tmpStr
	
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EC_ShowAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetAxis/A
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EC_HelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z "Event Mode Data[Correcting for things that go wrong]"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EC_DoneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K EventCorrectionPanel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//upDown 5 or -5 looks for spikes +5 or -5 std deviations from mean
//
// will search from the leftmost cursor to the end. this allows skipping of oscillations
// that are not timing errors. It may introduce other issues, but we'll see what happens
//
Function PutCursorsAtStep(upDown)
	Variable upDown
	
	SetDataFolder root:Packages:NIST:Event:

	Wave rescaledTime=rescaledTime
	Wave rescaledTime_DIF=rescaledTime_DIF
	Variable avg,pt,zoom
	Variable ptA,ptB,startPt
		
	zoom = 200		//points in each direction
	
	WaveStats/M=1/Q rescaledTime_DIF
	avg = V_avg
	
	ptA = pcsr(A)
	ptB = pcsr(B)
	startPt = min(ptA,ptB)
	
	FindLevel/P/Q/R=[startPt] rescaledTime_DIF abs(avg)*upDown		// in case the average is negative
	if(V_flag==0)
		pt = V_levelX
		WaveStats/Q/R=[pt-zoom,pt+zoom] rescaledTime		// find the max/min y-values within the point range
	else
		Print "Level not found"
//		return(0)
	endif
	
	Variable loLeft,hiLeft, loBottom,hiBottom
	loLeft = V_min*0.98		//+/- 2%
	hiLeft = V_max*1.02
	
	SetAxis left loLeft,hiLeft
	SetAxis bottom pnt2x(rescaledTime,pt-zoom),pnt2x(rescaledTime,pt+zoom)
	
	Cursor/P A rescaledTime pt+2	//at the point
	Cursor/P B rescaledTime numpnts(rescaledTime)-1		//at the end

	SetDataFolder root:

	return(0)
End


// find the max (or min) of the rescaled time set
// and place both cursors there
Function fFindOutlier()

	SetDataFolder root:Packages:NIST:Event:

	Wave rescaledTime=rescaledTime
	Variable avg,pt,zoom,maxPt,minPt,maxVal,minVal
	
	zoom = 200		//points in each direction
	
	WaveStats/M=1/Q rescaledTime
	maxPt = V_maxLoc
	minPt = V_minLoc
	avg = V_avg
	maxVal = abs(V_max)
	minVal = abs(V_min)

	pt = abs(maxVal - avg) > abs(minVal - avg) ? maxPt : minPt
	
//	Variable loLeft,hiLeft, loBottom,hiBottom
//	loLeft = V_min*0.98		//+/- 2%
//	hiLeft = V_max*1.02
	
//	SetAxis left loLeft,hiLeft
//	SetAxis bottom pnt2x(rescaledTime,pt-zoom),pnt2x(rescaledTime,pt+zoom)
	
	Cursor/P A rescaledTime pt		//at the point
	Cursor/P B rescaledTime pt		//at the same point

	SetDataFolder root:
	
	return(0)
End

Function EC_FindStepButton_down(ctrlName) : ButtonControl
	String ctrlName
	
//	Variable upDown = -5
	NVAR upDown = root:Packages:NIST:Event:gStepTolerance
	
	PutCursorsAtBigStep(upDown)
//	PutCursorsAtStep(-1*upDown)

	return(0)
end


Function EC_FindStepButton_up(ctrlName) : ButtonControl
	String ctrlName
	
//	Variable upDown = 5
	NVAR upDown = root:Packages:NIST:Event:gStepTolerance

	PutCursorsAtBigStep(upDown)
//	PutCursorsAtStep(upDown)

	return(0)
end

// if the Trim button section is uncommented, it's "Zap outlier"
//
Function EC_FindOutlierButton(ctrlName) : ButtonControl
	String ctrlName
	
	fFindOutlier()
//
//	STRUCT WMButtonAction ba
//	ba.eventCode = 2
//
//	EC_TrimPointsButtonProc(ba)

	return(0)
end

Function EC_DoDifferential(ctrlName) : ButtonControl
	String ctrlName
	
	DifferentiatedTime()
	DoWindow/F EventCorrectionPanel
	
	//if trace is not on graph, add it
	SetDataFolder root:Packages:NIST:Event:

	String list = WaveList("*_DIF", ";", "WIN:EventCorrectionPanel")
	if(strlen(list) == 0)
		AppendToGraph/R rescaledTime_DIF
		ModifyGraph msize=1,rgb(rescaledTime_DIF)=(65535,0,0)
		ReorderTraces rescaledTime,{rescaledTime_DIF}		// put the differential behind the event data
	endif
	SetDataFolder root:
	return(0)
end

//////////////   Custom Bins  /////////////////////
//
//
//
// make sure that the bins are defined and the waves exist before
// trying to draw the panel
//
Proc Show_CustomBinPanel()
	DoWindow/F CustomBinPanel
	if(V_flag ==0)
		Init_CustomBins()
		CustomBinPanel()
	EndIf
End


Function Init_CustomBins()

	NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest

	Variable/G root:Packages:NIST:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	SetDataFolder root:Packages:NIST:Event:
		
	Make/O/D/N=(nSlice) timeWidth
	Make/O/D/N=(nSlice+1) binEndTime,binCount
	
	timeWidth = t_longest/nslice
	binEndTime = p
	binCount = p+1	
	
	SetDataFolder root:
	
	return(0)
End

////////////////	
//
// Allow custom definitions of the bin widths
//
// Define by the number of bins, and the time width of each bin
//
// This shares the number of slices and the maximum time with the main panel
//
Proc CustomBinPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(130,44,851,455)/K=2 /N=CustomBinPanel
	DoWindow/C CustomBinPanel
	ModifyPanel fixedSize=1//,noEdit =1
	SetDrawLayer UserBack
	
	Button button0,pos={654,42}, size={50,20},title="Done",fSize=12
	Button button0,proc=CB_Done_Proc
	Button button1,pos={663,14},size={40,20},proc=CB_HelpButtonProc,title="?"
	Button button2,pos={216,42},size={80,20},title="Update",proc=CB_UpdateWavesButton	
	SetVariable setvar1,pos={23,13},size={160,20},title="Number of slices",fSize=12
	SetVariable setvar1,proc=CB_NumSlicesSetVarProc,value=root:Packages:NIST:Event:gEvent_nslices
	SetVariable setvar2,pos={24,44},size={160,20},title="Max Time (s)",fSize=10
	SetVariable setvar2,value=root:Packages:NIST:Event:gEvent_t_longest	

	CheckBox chkbox1,pos={216,14},title="Enforce Max Time?"
	CheckBox chkbox1,variable = root:Packages:NIST:Event:gEvent_ForceTmaxBin
	Button button3,pos={500,14},size={90,20},proc=CB_SaveBinsButtonProc,title="Save Bins"
	Button button4,pos={500,42},size={100,20},proc=CB_ImportBinsButtonProc,title="Import Bins"	
		
	SetDataFolder root:Packages:NIST:Event:

	Display/W=(291,86,706,395)/HOST=CustomBinPanel/N=BarGraph binCount vs binEndTime
	ModifyGraph mode=5
	ModifyGraph marker=19
	ModifyGraph lSize=2
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=2
	ModifyGraph hbFill=2
	ModifyGraph gaps=0
	ModifyGraph usePlusRGB=1
	ModifyGraph toMode=1
	ModifyGraph useBarStrokeRGB=1
	ModifyGraph standoff=0
	SetAxis left 0,*
	Label bottom "\\Z14Time (seconds)"
	Label left "\\Z14Number of Events"
	SetActiveSubwindow ##
	
	// and the table
	Edit/W=(13,87,280,394)/HOST=CustomBinPanel/N=T0
	AppendToTable/W=CustomBinPanel#T0 timeWidth,binEndTime
	ModifyTable width(Point)=40
	SetActiveSubwindow ##
	
	SetDataFolder root:
	
EndMacro

// save the bins - use Igor Text format
//
Function CB_SaveBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			
			Save/T timeWidth,binEndTime			//will ask for a name

			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End

// Import the bins - use Igor Text format
//
// -- be sure that the number of bins is reset
// -?- how about the t_longest? - this should be set by the load, not here
//
// -- loads in timeWidth and binEndTime
//
Function CB_ImportBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices

			SetDataFolder root:Packages:NIST:Event:

			// prompt for the load of data
			LoadWave/T/O
			if(strlen(S_fileName) == 0)
				//user cancelled
				DoAlert 0,"No file selected, nothing done."
				return(0)
			endif

			Wave timeWidth = timeWidth
			nSlice = numpnts(timeWidth)
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End



//
// can either use the widths as stated -- then the end time may not
// match the actual end time of the data set
//
// -- or --
//
// enforce the end time of the data set to be the end time of the bins,
// then the last bin width must be reset to force the constraint
//
//
Function CB_UpdateWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			NVAR enforceTmax = root:Packages:NIST:Event:gEvent_ForceTmaxBin
			
			// update the waves, and recalculate everything for the display
			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			Wave binCount = binCount
			
			// use the widths as entered
			binEndTime[0] = 0
			binEndTime[1,] = binEndTime[p-1] + timeWidth[p-1]
			
			// enforce the longest time as the end bin time
			// note that this changes the last time width
			if(enforceTmax)
				binEndTime[nSlice] = t_longest
				timeWidth[nSlice-1] = t_longest - binEndTime[nSlice-1]
			endif
			
			binCount = p+1
			binCount[nSlice] = 0		// last point is zero, just for display
//			binCount *= sign(timeWidth)		//to alert to negative time bins
			
			// make the timeWidth bold and red if the widths are negative
			WaveStats/Q timeWidth
			if(V_min < 0)
				ModifyTable/W=CustomBinPanel#T0 style(timeWidth)=1,rgb(timeWidth)=(65535,0,0)			
			else
				ModifyTable/W=CustomBinPanel#T0 style(timeWidth)=0,rgb(timeWidth)=(0,0,0)			
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End

Function CB_HelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z "Event Mode Data[Setting up Custom Bin Widths]"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CB_Done_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K CustomBinPanel
			break
	endswitch
	return(0)
End


Function CB_NumSlicesSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			
			Redimension/N=(dval) timeWidth
			Redimension/N=(dval+1) binEndTime,binCount
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


///////////////////
//
// utility to split a large file
// 100 MB is the recommended size
// events can be clipped here, so be sure to trim the ends of the 
// resulting files as needed.
//
// - works like the unix 'split' command
//
//

Proc SplitBigFile(splitSize, baseStr)
	Variable splitSize = 100
	String baseStr="split"
	Prompt splitSize,"Target file size, in MB (< 150 MB!!)"
	Prompt baseStr,"File prefix, number will be appended"
	
	if(splitSize > root:Packages:NIST:Event:gEventFileTooLarge)
		Abort "File split must be less than 150 MB. Please try again"
	endif
	
	fSplitBigFile(splitSize, baseStr)
	
	ShowSplitFileTable()
End

Function/S fSplitBigFile(splitSize, baseStr)
	Variable splitSize
	String baseStr		


	String fileName=""		// File name, partial path, full path or "" for dialog.
	Variable refNum
	String str
	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
	
	listStr=""		//initialize output list

	Variable readSize=1e6		//1 MB
	Make/O/B/U/N=(readSize) aBlob			//1MB worth
	Variable numSplit
	Variable num,ii,jj,outRef,frac
	String thePath, outStr
	
	Printf "SplitSize = %u MB\r",splitSize
	splitSize = trunc(splitSize) * 1e6		// now in bytes
	
	
	// Open file for read.
	Open/R/Z=2/F="????"/P=catPathName refNum as fileName
	thePath = ParseFilePath(1, S_fileName, ":", 1, 0)
	Print "thePath = ",thePath
	
	// Store results from Open in a safe place.
	Variable err = V_flag
	String fullPath = S_fileName

	if (err == -1)
		Print "cancelled by user."
		return ("")
	endif

	FStatus refNum
	
	Printf "total # bytes = %u\r",V_logEOF

	numSplit=0
	if(V_logEOF > splitSize)
		numSplit = trunc(V_logEOF/splitSize)
	endif

	frac = V_logEOF - numSplit*splitSize
	Print "numSplit = ",numSplit
	Printf "frac = %u\r",frac
	
	num=0
	if(frac > readSize)
		num = trunc(frac/readSize)
	endif

	
	frac = frac - num*readSize

	Print "num = ",num
	Printf "frac = %u\r",frac
	
//	baseStr = "split"
	
	for(ii=0;ii<numSplit;ii+=1)
		outStr = (thePath+baseStr+num2str(ii)+".hst")
//		Print "outStr = ",outStr
		Open outRef as outStr

		for(jj=0;jj<(splitSize/readSize);jj+=1)
			FBinRead refNum,aBlob
			FBinWrite outRef,aBlob
		endfor

		Close outRef
//		listStr += outStr+";"		//no, this is the FULL path
		listStr += baseStr+num2str(ii)+".hst"+";"
	endfor

	Make/O/B/U/N=(frac) leftover
	// ii was already incremented past the loop
	outStr = (thePath+baseStr+num2str(ii)+".hst")
	Open outRef as outStr
	for(jj=0;jj<num;jj+=1)
		FBinRead refNum,aBlob
		FBinWrite outRef,aBlob
	endfor
	FBinRead refNum,leftover
	FBinWrite outRef,leftover

	Close outRef
//	listStr += outStr+";"
	listStr += baseStr+num2str(ii)+".hst"+";"

	FSetPos refNum,V_logEOF
	Close refNum
	
	KillWaves/Z aBlob,leftover
	return(listStr)
End

// allows the list of loaded files to be edited
Function ShowSplitFileTable()

	SVAR str = root:Packages:NIST:Event:gSplitFileList
	
	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	if(waveExists(tw) != 1)	
		Make/O/T/N=1 root:Packages:NIST:Event:SplitFileWave
		WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	endif

	List2TextWave(str,tw)
	Edit tw

	return(0)
End


//// save the sliced data, and accumulate slices
//  *** this works with sliced data -- that is data that has been PROCESSED
//
// need some way of ensuring that the slices match up since I'm blindly adding them together. 
//
// mode = 0		wipe out the old accumulated, copy slicedData to accumulatedData
// mode = 1		add current slicedData to accumulatedData
// mode = 2		copy accumulatedData to slicedData in preparation of export or display
// mode = 3		unused...
//
//	"Split Large File",SplitBigFile()
//	"Accumulate First Slice",AccumulateSlices(0)
//	"Add Current Slice",AccumulateSlices(1)
//	"Display Accumulated Slices",AccumulateSlices(2)	
//
Function AccumulateSlicesButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable mode
	mode = str2num(ctrlName[strlen(ctrlName)-1])
//	Print "mode=",mode
	AccumulateSlices(mode)
	
	return(0)
End

// added an extra (optional) parameter for silent operation - to be used when a list of
// files are processed - so the user can walk away as it works. Using the buttons from the
// panel will still present the alerts
//
Function AccumulateSlices(mode,[skipAlert])
	Variable mode,skipAlert
	
	if(ParamIsDefault(skipAlert))
		skipAlert = 0
	endif
	SetDataFolder root:Packages:NIST:Event:

	switch(mode)	
		case 0:
			if(!skipAlert)
				DoAlert 0,"The current data has been copied to the accumulated set. You are now ready to add more data."
			endif
			KillWaves/Z accumulatedData
			Duplicate/O slicedData accumulatedData	
			KillWaves/Z accum_BinCount		// the accumulated BinCount
			Duplicate/O binCount accum_binCount	
			break
		case 1:
			if(!skipAlert)
				DoAlert 0,"The current data has been added to the accumulated data. You can add more data."
			endif
			Wave acc=accumulatedData
			Wave cur=slicedData
			acc += cur
			Wave binCount = binCount
			Wave accum_binCount = accum_BinCount
			accum_BinCount += binCount
			binCount = accum_binCount			// !! NOTE - the bin count wave is now the total
//			AccumulateSlices(2,skipAlert=skipAlert)						// and a recursive call to show the total!
			break
		case 2:
			if(!skipAlert)
				DoAlert 0,"The accumulated data is now the display data and is ready for display or export."
			endif
			Duplicate/O accumulatedData slicedData
			// do something to "touch" the display to force it to update
			NVAR gLog = root:Packages:NIST:Event:gEvent_logint
			LogIntEvent_Proc("",gLog)
			break
		default:			
				
	endswitch

	SetDataFolder root:
	return(0)
end


////////////////////////////////////////////
//
// Panel and procedures for decimation
//
////////////////////////////////////////////

//Function E_ShowDecimateButton(ctrlName) : ButtonControl
//	String ctrlName
//
//	DoWindow/F DecimatePanel
//	if(V_flag ==0)
//		Execute "DecimatePanel()"
//	endif
//End
//
//
//Proc DecimatePanel() //: Panel
//	
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(1602,44,1961,380)/K=1
////	ShowTools/A
//	Button button0,pos={29,15},size={100,20},proc=SplitFileButtonProc,title="Split Big File"
//	SetVariable setvar0,pos={182,55},size={150,15},title="Decimation factor",fsize=10
//	SetVariable setvar0,limits={1,inf,1},value= root:Packages:NIST:Event:gDecimation
//	Button button1,pos={26,245},size={150,20},proc=LoadDecimateButtonProc,title="Load and Decimate"
//	Button button2,pos={25,277},size={150,20},proc=ConcatenateButtonProc,title="Concatenate"
//	Button button3,pos={25,305},size={150,20},proc=DisplayConcatenatedButtonProc,title="Display Concatenated"
//	Button button4,pos={29,52},size={130,20},proc=Stream_LoadDecim,title="Load From List"
//	
//	GroupBox group0 title="Manual Controls",size={185,112},pos={14,220}
//EndMacro


Function SplitFileButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "SplitBigFile()"
End


// show all of the data
//
Proc ShowDecimatedGraph()

	DoWindow/F DecimatedGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(25,44,486,356)/K=1/N=DecimatedGraph rescaledTime_dec
		SetDataFolder fldrSav0
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb(rescaledTime_dec)=(0,0,0)
		ModifyGraph msize=1
		ErrorBars rescaledTime_dec OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"
		ShowInfo
	endif
	
EndMacro

// data has NOT been processed
//
// so work with x,y,t, and rescaled time
// variables -- t_longest
Function ConcatenateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoAlert 1,"Is this the first file?"
	Variable first = V_flag
	
	fConcatenateButton(first)
	
	return(0)
End

Function fConcatenateButton(first)
	Variable first


	SetDataFolder root:Packages:NIST:Event:

	Wave timePt_dTmp=timePt_dTmp
	Wave xLoc_dTmp=xLoc_dTmp
	Wave yLoc_dTmp=yLoc_dTmp
	Wave rescaledTime_dTmp=rescaledTime_dTmp
	
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	
	if(first==1)		//1==yes, 2==no
		//then copy the files over, adjusting the time to start from zero
		// rescaledTime starts from zero (set by the loader)

		timePt_dTmp -= timePt_dTmp[0]			//subtract the first value
		
		Duplicate/O timePt_dTmp timePt_dec
		Duplicate/O xLoc_dTmp xLoc_dec
		Duplicate/O yLoc_dTmp yLoc_dec
		Duplicate/O rescaledTime_dTmp rescaledTime_dec
		
		t_longest_dec = t_longest
	
	else
		// concatenate the files + adjust the time
		Wave timePt_dec=timePt_dec
		Wave xLoc_dec=xLoc_dec
		Wave yLoc_dec=yLoc_dec
		Wave rescaledTime_dec=rescaledTime_dec

		// adjust the times -- assuming they add
		// rescaledTime starts from zero (set by the loader)
		//
		//
		rescaledTime_dTmp += rescaledTime_dec[numpnts(rescaledTime_dec)-1]
		rescaledTime_dTmp += abs(rescaledTime_dec[numpnts(rescaledTime_dec)-1] - rescaledTime_dec[numpnts(rescaledTime_dec)-2])
		
		timePt_dTmp -= timePt_dTmp[0]			//subtract the first value	
		
		timePt_dTmp += timePt_dec[numpnts(timePt_dec)-1]		// offset by the last point
		timePt_dTmp += abs(timePt_dec[numpnts(timePt_dec)-1] - timePt_dec[numpnts(timePt_dec)-2])		// plus delta so there's not a flat step
		
		Concatenate/NP/O {timePt_dec,timePt_dTmp}, tmp
		Duplicate/O tmp timePt_dec
		
		Concatenate/NP/O {xLoc_dec,xLoc_dTmp}, tmp
		Duplicate/O tmp xLoc_dec
		
		Concatenate/NP/O {yLoc_dec,yLoc_dTmp}, tmp
		Duplicate/O tmp yLoc_dec
		
		Concatenate/NP/O {rescaledTime_dec,rescaledTime_dTmp}, tmp
		Duplicate/O tmp rescaledTime_dec
		

		KillWaves tmp

		t_longest_dec = rescaledTime_dec[numpnts(rescaledTime_dec)-1]

	endif
	
	
	SetDataFolder root:
	
	return(0)

End

Function DisplayConcatenatedButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//copy the files over to the display set for processing
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt_dec=timePt_dec
	Wave xLoc_dec=xLoc_dec
	Wave yLoc_dec=yLoc_dec
	Wave rescaledTime_dec=rescaledTime_dec
		
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	Duplicate/O timePt_dec timePt
	Duplicate/O xLoc_dec xLoc
	Duplicate/O yLoc_dec yLoc
	Duplicate/O rescaledTime_dec rescaledTime
	
	t_longest = t_longest_dec	
	
	SetDataFolder root:
	
	return(0)

End


Proc DisplayForSlicing()

	// plot the EventBarGraph?
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(110,705,610,1132)/N=SliceGraph /K=1 binCount vs binEndTime
		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=1
		ModifyGraph useBarStrokeRGB=1
		ModifyGraph standoff=0

		SetDataFolder root:

// append the differential
	AppendToGraph/R root:Packages:NIST:Event:rescaledTime_DIF vs root:Packages:NIST:Event:rescaledTime
	ModifyGraph rgb(rescaledTime_DIF)=(1,16019,65535)

End



// unused, old testing procedure
Function LoadDecimateButtonProc(ctrlName) : ButtonControl
	String ctrlName

	LoadEventLog_Button("")
	
	// now decimate
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated

	NVAR decimation = root:Packages:NIST:Event:gDecimation


	Duplicate/O timePt, timePt_dTmp
	Duplicate/O xLoc, xLoc_dTmp
	Duplicate/O yLoc, yLoc_dTmp
	Resample/DOWN=(decimation)/N=1 timePt_dTmp
	Resample/DOWN=(decimation)/N=1 xLoc_dTmp
	Resample/DOWN=(decimation)/N=1 yLoc_dTmp


	Duplicate/O timePt_dTmp rescaledTime_dTmp
	rescaledTime_dTmp = 1e-7*(timePt_dTmp - timePt_dTmp[0])		//convert to seconds and start from zero
	t_longest_dec = waveMax(rescaledTime_dTmp)		//should be the last point

	SetDataFolder root:

	
End







//
// loads a list of files, decimating each chunk as it is read in
//
Function Stream_LoadDecim(ctrlName)
	String ctrlName
	
	Variable fileref
	Variable num,ii
	
	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest

	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR decimation = root:Packages:NIST:Event:gDecimation

	String pathStr
	PathInfo catPathName
	pathStr = S_Path

// if "stream" mode is not checked - abort
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	if(gEventModeRadioVal != MODE_STREAM)
		Abort "The mode must be 'Stream' to use this function"
		return(0)
	endif

// if the list has been edited, turn it into a list
	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	if(WaveExists(tw))
		listStr = TextWave2SemiList(tw)
	else
		ShowSplitFileTable()
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	

	//loop through everything in the list
	num = ItemsInList(listStr)
	if(num == 0)
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return (0)
	endif
	
	for(ii=0;ii<num;ii+=1)

// (1) load the file, prepending the path		
		filename = pathStr + StringFromList(ii, listStr  ,";")
		if(EventDataType(filename) != 1)		//if not hst extension of raw data
			Abort "Data must be raw event data with file extension .hst for this operation"
			return(0)
		endif		

#if (exists("EventLoadWave")==4)
		LoadEvents_XOP()
#else
		LoadEvents_New_noXOP()
//		LoadEvents()
#endif	

		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root:

		Wave timePt=timePt
		Wave xLoc=xLoc
		Wave yLoc=yLoc
		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes

		Duplicate/O timePt rescaledTime
		MultiThread rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
		t_longest = waveMax(rescaledTime)		//should be the last point
		
// (2) do the decimation, just on timePt. create rescaledTime from the decimated timePt	
		
		Duplicate/O timePt, timePt_dTmp
		Duplicate/O xLoc, xLoc_dTmp
		Duplicate/O yLoc, yLoc_dTmp
		Resample/DOWN=(decimation)/N=1 timePt_dTmp
		Resample/DOWN=(decimation)/N=1 xLoc_dTmp
		Resample/DOWN=(decimation)/N=1 yLoc_dTmp
	
	
		Duplicate/O timePt_dTmp rescaledTime_dTmp
		rescaledTime_dTmp = 1e-7*(timePt_dTmp - timePt_dTmp[0])		//convert to seconds and start from zero
		t_longest_dec = waveMax(rescaledTime_dTmp)		//should be the last point
		

// (3) concatenate the files + adjust the time
		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
	
	endfor

////		Now that everything is decimated and concatenated, create the rescaled time wave
//	SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root:
//	Wave timePt_dec = timePt_dec
//	Duplicate/O timePt_dec rescaledTime_dec
//	rescaledTime_dec = 1e-7*(timePt_dec - timePt_dec[0])		//convert to seconds and start from zero
//	t_longest_dec = waveMax(rescaledTime_dec)		//should be the last point
	
	DisplayConcatenatedButtonProc("")
	
	SetDataFolder root:

	return(0)
End

Function ShowList_ToLoad(ctrlName)
	String ctrlName
	
	ShowSplitFileTable()
	
	return(0)
End


//
// loads a list of files that have been adjusted and saved
// -- does not decimate
//
Function Stream_LoadAdjustedList(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest

	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
//	NVAR decimation = root:Packages:NIST:Event:gDecimation

	String pathStr
	PathInfo catPathName
	pathStr = S_Path

// if "stream" mode is not checked - abort
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	if(gEventModeRadioVal != MODE_STREAM)
		Abort "The mode must be 'Stream' to use this function"
		return(0)
	endif

// if the list has been edited, turn it into a list
	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	if(WaveExists(tw))
		listStr = TextWave2SemiList(tw)
	else
		ShowSplitFileTable()
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	

	//loop through everything in the list
	Variable num,ii
	num = ItemsInList(listStr)
	
	if(num == 0)
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	
	for(ii=0;ii<num;ii+=1)

// (1) load the file, prepending the path		
		filename = pathStr + StringFromList(ii, listStr  ,";")
		if(EventDataType(filename) != 2)		//if not itx extension of edited data
			Abort "Data must be edited data with file extension .itx for this operation"
			return(0)
		endif		
		SetDataFolder root:Packages:NIST:Event:
		LoadWave/T/O fileName

		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root: ??

// this is what is loaded -- _dec extension is what is concatenated, and will be copied back later
		Wave timePt=timePt
		Wave xLoc=xLoc
		Wave yLoc=yLoc
		Wave rescaledTime=rescaledTime

//		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes

//		Duplicate/O timePt rescaledTime
//		rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
//		t_longest = waveMax(rescaledTime)		//should be the last point
		
// (2) No decimation
		
		Duplicate/O timePt, timePt_dTmp
		Duplicate/O xLoc, xLoc_dTmp
		Duplicate/O yLoc, yLoc_dTmp
		Duplicate/O rescaledTime, rescaledTime_dTmp


// (3) concatenate the files + adjust the time
		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
	
	endfor
	
	DisplayConcatenatedButtonProc("")		// this resets the longest time, too
		
	SetDataFolder root:

	return(0)
End

//
// loads a list of files that have been adjusted and saved
// -- does not decimate
// -- bins as they are loaded
//
Function Stream_LoadAdjList_BinOnFly(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	SVAR listStr = root:Packages:NIST:Event:gSplitFileList

	String pathStr
	PathInfo catPathName
	pathStr = S_Path

// if "stream" mode is not checked - abort
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	if(gEventModeRadioVal != MODE_STREAM)
		Abort "The mode must be 'Stream' to use this function"
		return(0)
	endif

// if the list has been edited, turn it into a list
	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	if(WaveExists(tw))
		listStr = TextWave2SemiList(tw)
	else
		ShowSplitFileTable()
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	

	//loop through everything in the list
	Variable num,ii,jj
	num = ItemsInList(listStr)
	if(num == 0)
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	
////////////////
// declarations for the binning
// for the first pass, do all of this
	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR yesSortStream = root:Packages:NIST:Event:gSortStreamEvents		//do I sort the events?
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
//	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR t_segment_start = root:Packages:NIST:Event:gEvent_t_segment_start
	NVAR t_segment_end = root:Packages:NIST:Event:gEvent_t_segment_end
		
	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(128,128,nslices) slicedData
	
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount//,binStartTime
	Make/O/D/N=(nslices) timeWidth
	Wave binEndTime = binEndTime
	Wave timeWidth = timeWidth
	Wave binCount = binCount

	slicedData = 0
	binCount = 0

	variable p1,p2,t1,t2

	t_segment_start = 0
// start w/file 1??	
	for(jj=0;jj<num;jj+=1)

// (1) load the file, prepending the path		
		filename = pathStr + StringFromList(jj, listStr  ,";")
		if(EventDataType(filename) != 2)		//if not itx extension of edited data
			Abort "Data must be edited data with file extension .itx for this operation"
			return(0)
		endif		
		SetDataFolder root:Packages:NIST:Event:
		LoadWave/T/O fileName

		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root: ??

// this is what is loaded -- 
		Wave timePt=timePt
		Wave xLoc=xLoc
		Wave yLoc=yLoc
		Wave rescaledTime=rescaledTime

		if(jj==0)
			timePt -= timePt[0]			//make sure the first point is zero
			t_segment_start = 0
			t_segment_end = rescaledTime[numpnts(rescaledTime)-1]
		else
			t_segment_start = t_segment_end
			t_segment_end += rescaledTime[numpnts(rescaledTime)-1]
			
			rescaledTime += t_segment_start		
		endif
		
		Printf "jj=%g\t\tt_segment_start=%g\tt_segment_end=%g\r",jj,t_segment_start,t_segment_end
		
// this is the binning--

//		del = t_longest/nslices
	
	// TODO
	// the global exists for this switch, but it is not implemented - not sure whether
	// it's correct to implement this at all --
	//
		if(yesSortStream == 1)
			SortTimeData()
		endif
		
	// index the events before binning
	// if there is a sort of these events, I need to re-index the events for the histogram
	//	SetDataFolder root:Packages:NIST:Event
		IndexForHistogram(xLoc,yLoc,binnedData)
	//	SetDataFolder root:
		Wave index = root:Packages:NIST:Event:SavedIndex		//the index for the histogram
		
		for(ii=0;ii<nslices;ii+=1)
			if(ii==0)
	//			t1 = ii*del
	//			t2 = (ii+1)*del
				p1 = BinarySearch(rescaledTime,0)
				p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
			else
	//			t2 = (ii+1)*del
				p1 = p2+1		//one more than the old one
				p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
			endif
	
			if(p1 == -1)
				Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
				p1 = 0		//set to the first point if it's off the end
			Endif
			if(p2 == -2)
				Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
				p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
			Endif
	//		Print p1,p2
	
			tmpData=0
			JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
	//		slicedData[][][ii] = tmpData[p][q]
			slicedData[][][ii] += tmpData[p][q]
			
//			Duplicate/O tmpData,$("tmpData_"+num2str(ii)+"_"+num2str(jj))
			
	//		binEndTime[ii+1] = t2
	//		binCount[ii] = sum(tmpData,-inf,inf)
			binCount[ii] += sum(tmpData,-inf,inf)
		endfor
	
	endfor  //end loop over the file list

// after all of the files have been loaded
	t_longest = t_segment_end		//this is the total time

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)
	
		
	SetDataFolder root:

	return(0)
End


/////////////////////////////////////

// dd-mon-yyyy hh:mm:ss -> Event file name
// the VAX uses 24 hr time for hh
//
// scans as string elements since I'm reconstructing a string name
Function/S DateAndTime2HSTName(dateandtime)
	string dateAndTime
	
	String day,yr,hh,mm,ss,time_secs
	Variable mon
	string str,monStr,fileStr
	
	str=dateandtime
	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
#if (exists("NCNR_Nexus")==6)
	mon = N_monStr2num(monStr)
#else
	mon = monStr2num(monStr)	// regualar VAX reduction is loaded
#endif
	fileStr = "Event"+yr+num2str(mon)+day+hh+mm+ss+".hst"
	Print fileStr

	return(fileStr)
end

// dd-mon-yyyy hh:mm:ss -> Event file name
// the VAX uses 24 hr time for hh
//
// scans as string elements since I'm reconstructing a string name
Function DateAndTime2HSTNumber(dateandtime)
	string dateAndTime
	
	String day,yr,hh,mm,ss,time_secs
	Variable mon,num
	string str,monStr,fileStr
	
	str=dateandtime
	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
#if (exists("NCNR_Nexus")==6)
	mon = N_monStr2num(monStr)
#else
	mon = monStr2num(monStr)	// regualar VAX reduction is loaded
#endif
	fileStr = yr+num2str(mon)+day+hh+mm+ss
	num = str2num(fileStr)

	return(num)
end

Function HSTName2Num(str)
	String str
	
	Variable num
	sscanf str,"Event%d.hst",num
	return(num)
end
/////////////////////////////

Proc GetListofITXorSplitFiles(searchStr)
	String searchStr = ".itx"
	ShowList_ToLoad("")
	GetListofITXHST(searchStr)
end

// needs SANS_Utilites.ipf
Function GetListofITXHST(searchStr)
	String searchStr
	
	String fullList = IndexedFile(catpathName, -1, "????" )
	
	// list is currently everything -- trim it
	searchStr = "*" + searchStr + "*"
	String list = ListMatch(fullList, searchStr )
	
	Print "searchString = ",searchStr
	//
	Wave/T tw = root:Packages:NIST:Event:SplitFileWave
	List2TextWave(list,tw)
	Sort/A tw,tw			//alphanumeric sort
	Edit tw
	return(0)
End

//
// loads a list of files that have been adjusted and saved
// -- MUST run one through first manually to set the bin sapcing, then this
//    won't touch that, just process all of the files
// -- bins as they are loaded
//
Function Osc_LoadAdjList_BinOnFly(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	SVAR listStr = root:Packages:NIST:Event:gSplitFileList

	String pathStr,fileStr,tmpStr
	PathInfo catPathName
	pathStr = S_Path

// if "Osc" mode is not checked - abort
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	if(gEventModeRadioVal != MODE_OSCILL)
		Abort "The mode must be 'Oscillatory' to use this function"
		return(0)
	endif

// if the list has been edited, turn it into a list
	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
	if(WaveExists(tw))
		listStr = TextWave2SemiList(tw)
	else
		ShowSplitFileTable()
		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
		return(0)
	endif
	

	//loop through everything in the list
	Variable num,ii,jj
	num = ItemsInList(listStr)

//handle the first file differently
//(1) load (import edited)
	jj=0
	filename = pathStr + StringFromList(jj, listStr  ,";")
	if(EventDataType(filename) != 2)		//if not itx extension of edited data
		Abort "Data must be edited data with file extension .itx for this operation"
		return(0)
	endif
	
	SetDataFolder root:Packages:NIST:Event:
	LoadWave/T/O fileName
	SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root: ??

	// clear out the old sort index, if present, since new data is being loaded
	KillWaves/Z OscSortIndex	
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	sprintf tmpStr, "%s: a user-modified event file\r",StringFromList(jj, listStr  ,";")
	dispStr = tmpStr	
	
//(2) bin
	Osc_ProcessEventLog("")
	
//(3) display bin details
	Execute "ShowBinTable()"
	Execute "BinEventBarGraph()"
	
//(4) add first
	AccumulateSlices(0,skipAlert=1)		//bypass the dialog

	// with remaining files
	// load
	// bin
	// add next

// start w/file 1, since "0th" file was already processed
	for(jj=1;jj<num;jj+=1)
	
	//(1) load (import edited)
		filename = pathStr + StringFromList(jj, listStr  ,";")
		if(EventDataType(filename) != 2)		//if not itx extension of edited data
			Abort "Data must be edited data with file extension .itx for this operation"
			return(0)
		endif
		SetDataFolder root:Packages:NIST:Event:
		LoadWave/T/O fileName
		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root: ??
	
		// clear out the old sort index, if present, since new data is being loaded
		KillWaves/Z OscSortIndex	
		SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
		sprintf tmpStr, "%s: a user-modified event file\r",StringFromList(jj, listStr  ,";")
		dispStr = tmpStr	
		
	//(2) bin
		Osc_ProcessEventLog("")
		
	//(3) display bin details
		Execute "ShowBinTable()"
		Execute "BinEventBarGraph()"
		
	//(4) add next
		AccumulateSlices(1,skipAlert=1)
	
	endfor  //end loop over the file list

	
	//display total
	AccumulateSlices(2,skipAlert=1)

	// let user know we're done
	DoAlert 0,"The list has been processed and is ready for export"
	SetDataFolder root:

	return(0)
End


//returns 0 for unknown data
// 1 for raw hst files
// 2 for edited ITX files
//
//  TODO
//  -- currently, this blindly assumes an .hst extension for raw HST data, and .itx for edited data
//
Function EventDataType(filename)
	string filename
	
	Variable type
	Variable offset = strsearch(filename,".",Inf,1)		//work backwards
	String extension = filename[offset+1,strlen(filename)-1]
	//Print extension
	type = 0
	if(cmpstr(extension,"hst") == 0)
		type = 1
	endif
	if(cmpstr(extension,"itx") == 0)
		type = 2
	endif
	return(type)
end

////////////
// this could be jazzed up quite a bit, but it is a first pass at
// figuring out what is going on with the events
//
Proc DecodeBinaryEvents(numToPrint)
	Variable numToPrint=10
	
	DecodeEvents(numToPrint)
end

//	sscanf %x takes hex input and gives a real value output
// printf %d val gives the integer representation of the sscanf output
// printf %b val gives the binary representation.
Function DecodeEvents(numToPrint)
	Variable numToPrint

	String filePathStr,buffer
	Variable fileRef,type,dataval,num0,num1,num2,num3
	Variable numT0,numPP,numZero,numXYevents,bit29
	Variable ii

	ii=0
	Open/R fileref
	tic()
	do
		do
			FReadLine fileref, buffer			//skip the "blank" lines that have one character
		while(strlen(buffer) == 1)		

		if (strlen(buffer) == 0)
			break
		endif
		
		sscanf buffer,"%x",dataval
		if(ii<numToPrint)
			printf "%s  %0.32b  ",buffer[0,7],dataval
		endif
		
		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30

		if(ii<numToPrint)
			printf "%0.2b  ",type
		endif
						
		if(type == 0)
			num0 += 1
			numXYevents += 1
		endif
		if(type == 2)
			num2 += 1
			numXYevents += 1
		endif
		if(type == 1)
			num1 += 1
		endif
		if(type == 3)
			num3 += 1
		endif	
		
		bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
		if(ii<numToPrint)
			printf "%0.1b  ",bit29
		endif
				
		if(type==0 || type==2)
			numPP += round(bit29)
		endif
		
		if(type==1 || type==3)
			numT0 += round(bit29)
		endif
		
		if(dataval == 0)
			numZero += 1
		endif
		
		if(ii<numToPrint)
			printf "\r"
			ii += 1
		endif
		
	while(1)
	Close fileref
toc()

	Print "(Igor) numT0 = ",numT0	
	Print "num0 = ",num0	
	Print "num1 = ",num1	
	Print "num2 = ",num2	
	Print "num3 = rollover = ",num3
	Print "numXY = ",numXYevents
	Print "numZero = ",numZero
	Print "numPP = ",numPP
	
	return(0)

End


//////////////////
Function FixStepDown()
	
	SetDataFolder root:Packages:NIST:Event:
	
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Variable rollTime,rollTicks,ii,delta
	
	rollTicks = 2^26				// in ticks
	rollTime = 2^26*1e-7		// in seconds

	for(ii=0;ii<numpnts(rescaledTime)-1;ii+=1)
		delta = rescaledTime[ii+1] - rescaledTime[ii]
		if(delta < -6.6 && delta > -6.8)		//assume anything this large is a step down
		print ii, delta
			MultiThread timePt[ii+1,] += rollTicks
			MultiThread rescaledTime[ii+1,] += rollTime
		
			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
		endif
	
	endfor

	SetDataFolder root:

	return(0)
End

Function FixStepUp()
	
	SetDataFolder root:Packages:NIST:Event:
	
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Variable rollTime,rollTicks,ii,delta
	
	rollTicks = 2^26				// in ticks
	rollTime = 2^26*1e-7		// in seconds

	for(ii=0;ii<numpnts(rescaledTime)-1;ii+=1)
		delta = rescaledTime[ii+1] - rescaledTime[ii]
		if(delta > 6.6 && delta < 6.8)		//assume anything this large is a step up
		print ii, delta
			MultiThread timePt[ii+1,] -= rollTicks
			MultiThread rescaledTime[ii+1,] -= rollTime
		
			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
		endif
	
	endfor

	SetDataFolder root:

	return(0)
End

//    added a test function AutoFix_Rollover_Steps() that will search for steps (simple delta) that 
//    are +/- 0.1s away from the 6.7s missed rollover. This function looks for up, down, then re-calculates
//    the derivative.
//  - this way, both the simple steps, and the "square" steps can both be corrected.
//
Function AutoFix_Rollover_Steps()
// fix steps up, then down (order doesn't matter)
	Print "Fixing steps of 6.7s up"	
	FixStepUp()
	Print "Fixing steps of 6.7s down"
	FixStepDown()
//	re-do the differential
	DifferentiatedTime()
	return(0)
End


//upDown looks for a step up or down?
//
// plan is to be able to locate large (t0) steps from oscillations that are not timing errors
//
//
// will search from the leftmost cursor to the end. this allows skipping of oscillations
// that are not timing errors. It may introduce other issues, but we'll see what happens
//
Function PutCursorsAtBigStep(tol)
	Variable tol
	
	SetDataFolder root:Packages:NIST:Event:

	Wave rescaledTime=rescaledTime
	Variable ii,delta,ptA,ptB,startPt,pt
		
	ptA = pcsr(A)
	ptB = pcsr(B)
	startPt = min(ptA,ptB)
		
	for(ii=startPt;ii<numpnts(rescaledTime)-1;ii+=1)
		delta = rescaledTime[ii+1] - rescaledTime[ii]		//if there is a step down, this will be negative
		if(abs(delta) > tol)
			print ii, delta
			pt = ii
			break
		endif	
	endfor
	
	Cursor/P A rescaledTime pt+1	//at the point+1
	Cursor/P B rescaledTime numpnts(rescaledTime)-1		//at the end

	SetDataFolder root:

	return(0)
	
	
End



Proc InsertTimeReset(period)
	Variable period
	
	fInsertTimeReset(period)
End


//
// for event data where a time reset signal was not sent, but the data is
// actually periodic. This function will reset the time at the input period.
// This assumes that you accurately know the period, and that the start time
// of the data coincides with the start time of the period, otherwise the 
// time reset will happen in the middle of the cycle.
//
// period = period of reset (s)
//
// This can also be done efficiently with mod(period) (multithreaded?)
//
Function fInsertTimeReset(period)
	Variable period
	
	SetDataFolder root:Packages:NIST:Event:
	
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Variable rollTime,rollTicks,ii,delta
	
	Variable period_ticks
	
	period_ticks = period*1e7		//period in ticks
	

	for(ii=0;ii<numpnts(rescaledTime)-1;ii+=1)
		if(rescaledTime[ii] > period)
			MultiThread timePt[ii,] -= period_ticks
			MultiThread rescaledTime[ii,] -= period
		endif
	endfor

// updates the longest time (as does every operation of adjusting the data)
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	t_longest = waveMax(rescaledTime)
	SetDataFolder root:

	return(0)
End


Proc EstFrameOverlap(lambda,fwhm,sdd)
	Variable lambda=6,fwhm=0.12,sdd=13
	FrameOverlap(lambda,fwhm,sdd)
End

//fwhm = 2.355 sigma of the Gaussian
// two standard deviations = 95% of distribution
//
// lam =5A, fwhm = 0.138, sdd=13.7m
//
Function FrameOverlap(lam,fwhm,sdd)
	Variable lam,fwhm,sdd
	
	Variable speed_lo,speed_hi,sig,lam_lo,lam_hi
	Variable time_lo,time_hi,delta
	
	
	sig = fwhm/2.355
	lam_lo = lam - 2*lam*sig
	lam_hi = lam + 2*lam*sig


	speed_lo = 3956/lam_lo		//if lam [=] A, speed [=] m/s
	speed_hi = 3956/lam_hi		//if lam [=] A, speed [=] m/s

// then the time to travel from sample to detector is:
	time_lo = sdd/speed_lo
	time_hi = sdd/speed_hi
	
	delta = (time_hi-time_lo)		//hi wavelength is slower

	Print "Accounting for 2 sigma = 95% of distribution"
	Print "Use bin widths larger than frame overlap time (s) = ",delta

	return(delta)
end

/////////////////////////////////
//
//
//  Improved loading of SANS Event files
// 	without the use of an XOP (in case macOS / Igor XOPs can't be loaded)
//
// 	28 FEB 2020 SRK
//

// TODO
// -- still need to clean this up to provide an identical entry point and functionality
//   to the existing non-XOP loader
// -- all routines need to be made DataFolder aware. currently everything is in root:
// -- all waves need to be explicitly declared. currently the assumption is that they exist, in root:
// -- be sure that global variables are declared and set with the loaded values (t_max, values for status)
// -- clean up (kill) anything not needed so that I can save memory



//
//
// this now works properly and with reasonable speed:
// relative times:
// XOP = 1
// old Igor code = 28
// this new code = 6.3
//
// loaded variables, times, XY location have all been verified vs. XOP and old Igor routines
//

// this code loads 563 MB in 114 s (as predicted by scaling up XOP load speed)
// loads 979 MB in 266 s (slower than predicted)


Function LoadEvents_New_noXOP()

	SVAR fname = root:Packages:NIST:Event:gEvent_logfile

	Variable numBad = 0
	
//	String fname = DoOpenFileDialog("select an event file")

tic()		
	LoadEventAsHex(fname)
	Wave/T/Z newWave = root:Packages:NIST:Event:newWave

	RemoveFFF(newWave)
	
	GetBitsFromEvents()
	Wave/Z bit29 = root:Packages:NIST:Event:bit29
	Wave/Z events = root:Packages:NIST:Event:events
	Wave/Z time_lsw = root:Packages:NIST:Event:time_lsw
	Wave/Z type = root:Packages:NIST:Event:type
	Wave/Z xloc = root:Packages:NIST:Event:xloc
	Wave/Z yloc = root:Packages:NIST:Event:yloc

	numBad = CleanUpBeginning(type,events,bit29,xloc,yloc,time_lsw)

	DecodeEvents_New(type,events,bit29,xloc,yloc,time_lsw,numBad)
	Wave/Z timePt = root:Packages:NIST:Event:timePt
	Wave/Z deletePtFlag = root:Packages:NIST:Event:deletePtFlag

//
// see the trick for setting the deletePtFlag wave that I use in DecodeEvents_New
// -- I needed to do this since the sort operation does not preserve the order of 
// any items with the same value --- from the help file:
// "The algorithm used does not maintain the relative position of items with the same key value."
//
//
	Sort deletePtFlag,bit29,events,timePt,time_lsw,type,xloc,yloc,deletePtFlag
//	FindValue/I=10 deletePtFlag		//bad points are flagged as 1, first real point is 10 (unless it was replaced)
//	Print V_Value							//so this will fail...
	
	FindLevel/P/Q deletePtFlag 10
//	Print V_LevelX
	
	DeletePoints 0,trunc(V_LevelX)+1, bit29,events,timePt,time_lsw,type,xloc,yloc,deletePtFlag

	SetDataFolder root:Packages:NIST:Event:

// this is done after the file load/decode whether the XOP was used or the Igor code
// (don't do the time rescaling here)	
//	Duplicate/O timePt 	rescaledTime
//	// MultiThread shaves off significant time!
//	MultiThread rescaledTime *= 1e-7			//convert to seconds and that's all 


// cleanup as many waves as possible to save space
// these can be kept as needed for debugging
	KillWaves/Z bit29,type,time_lsw,events,deletePtFlag
	KillWaves/Z badTimePt,badEventNum,PPTime,PPEventNum,T0Time,T0EventNum
	toc()
	
	SetDataFolder root:
	return(0)
end

//Macro doDecodeOnly()
//	Variable numBad=0
//	DecodeEvents_New(type,events,bit29,xloc,yloc,time_lsw,numBad)
//End

Function LoadEventAsHex(fname)
	String fname
	
	SetDataFolder root:Packages:NIST:Event:
	
	LoadWave/J/O/A/K=2/B="C=1,F=10,T=96,N=newWave;"	 fname		//  /E=1 flag will display a table
	
	// table is useful to see as hexadecimal -- every other point
	// is FFFFFFFF = 4294967295 and is garbage to delete
	
	SetDataFolder root:
	return(0)
end

// no need to remove every other point that is zero
// (actually 4294967295 = FFFFFFFF)
// I can to this with a wave assignment
Function RemoveFFF(w)
	Wave w 
	
	SetDataFolder root:Packages:NIST:Event:
//	RemoveZeroEvents(w)
	
// 32 bit unsigned integer wave	
	Make/O/U/I/N=(trunc(numpnts(w))/2) events
	MultiThread events = w[2*p]
	
	KillWaves/Z w		//not needed any longer
	
	SetDataFolder root:
	return(0)
End



Function GetBitsFromEvents()

//	Wave events=events
	SetDataFolder root:Packages:NIST:Event:
	Wave events = root:Packages:NIST:Event:events
		
	Make/O/U/B/N=(numpnts(events))  xloc,yloc,type,bit29
	Make/O/U/I/N=(numpnts(events)) time_lsw

	MultiThread type = (events & 0xC0000000)/1073741824		//right shift by 2^30
	
	MultiThread bit29 = (events & 0x20000000)/536870912		//bit 29 only , shift by 2^29

	MultiThread xloc = 127 - (events & 255)						//last 8 bits (7-0)
	MultiThread yloc = (events & 65280)/256						//bits 15-8, right shift by 2^8


	MultiThread time_lsw = (events & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
	
	Variable/G numXYevents,num0,num1,num2,num3
	num0 = CountType(0)
	num1 = CountType(1)
	num2 = CountType(2)
	num3 = CountType(3)
	
	numXYevents = num0 + num2
	Printf "numXYevents = type 0 + type 2 = %d\r",numXYevents
	Printf "XY = num0 = %d\r",num0
	Printf "time MSW = num1 = %d\r",num1
	Printf "XY time = num2 = %d\r",num2
	Printf "Rollover = num3 = %d\r",num3


// dispStr will be displayed on the panel
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	SVAR filepathStr = root:Packages:NIST:Event:gEvent_logfile
	
	String tmpStr="",fileStr=""
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	Variable fileref,totBytes
	Open/R fileref as filepathstr
		FStatus fileref
	Close fileref

	totBytes = V_logEOF
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numXYevents
	dispStr += tmpStr
//	sprintf tmpStr,"PP = %d  :  ",numPP
//	dispStr += tmpStr
//	sprintf tmpStr,"ZeroData = %d\r",numZero
//	dispStr += tmpStr
	sprintf tmpStr,"Rollover = %d",num3
	dispStr += tmpStr

	
//	Print 127 - (events[5] & 255)
//	Print (events[5] & 65280)/256

	SetDataFolder root:
	return(0)
End

//
// a quick way to count the number of a particular value in a wave
//
Function CountType(val)
	Variable val
	
	Wave type=type
	// can't duplicate, since Byte data can't accept NaN
	Make/O/D/N=(numpnts(type)) tmp
	MultiThread tmp = type
	
	MultiThread tmp = (tmp[p] == val) ? NaN : tmp[p]				// replace matches with NaN
	
	WaveStats/Q tmp
	
	KillWaves/Z tmp
	return(V_numNaNs)
End

Function CleanUpBeginning(type,events,bit29,xloc,yloc,time_lsw)
	Wave type,events,bit29,xloc,yloc,time_lsw
	
	// for all of the waves, remove points from the beginning up to the
	// first one with a type==2 so that I know that the 
	// time has been properly reset to start
	
	variable ii,num
	num=numpnts(type)
	for(ii=0;ii<num;ii+=1)
		if(type[ii] == 2)
			break
		endif
	endfor
	
	Print "Num bad removed from beginning = ",ii
	DeletePoints 0,ii, type,events,bit29,xloc,yloc,time_lsw	

	return(ii)
End


//
// for the bit shifts, see the decimal-binary conversion
// http://www.binaryconvert.com/convert_unsigned_int.html
//
//		K0 = 536870912
// 		Print (K0 & 0x08000000)/134217728 	//bit 27 only, shift by 2^27
//		Print (K0 & 0x10000000)/268435456		//bit 28 only, shift by 2^28
//		Print (K0 & 0x20000000)/536870912		//bit 29 only, shift by 2^29
//
// This is duplicated by the XOP, but the Igor code allows quick access to print out
// all of the gory details of the events and every little bit of them. the print
// statements and flags are kept for this reason, so the code is a bit messy.
//
//
//Static Constant ATXY = 0
//Static Constant ATXYM = 2
//Static Constant ATMIR = 1
//Static Constant ATMAR = 3
//
//
Function DecodeEvents_New(type,events,bit29,xloc,yloc,time_lsw,numBad)
	Wave type,events,bit29,xloc,yloc,time_lsw
	Variable numBad		// number of bad points previously removed from beginning of file

//	NVAR time_msw = root:Packages:NIST:Event:gEvent_time_msw
//	NVAR time_lsw = root:Packages:NIST:Event:gEvent_time_lsw
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
//	SVAR filepathstr = root:Packages:NIST:Event:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	
	SetDataFolder root:Packages:NIST:Event


	variable ii,num,typ
	Variable nRoll,roll_time,time_msw,timeval
	Variable tmpPP,tmpT0,numRemoved,rolloverHappened
	Variable tmpX,tmpY

//	tic()
	// 32-bit unsigned, max value = 4,294,926,295 (= max number of events I can sort)
	Make/O/I/U/N=(numpnts(type))  deletePtFlag
	MultiThread deletePtFlag = p+10		// give them all a different number, starting from 10
	// flagged "bad" points will be set == 1
	
	Make/O/N=500000 badTimePt,badEventNum,PPTime,PPEventNum,T0Time,T0EventNum
	MultiThread badTimePt=0
	MultiThread badEventNum=0
	MultiThread PPTime=0
	MultiThread PPEventNum=0
	MultiThread T0Time=0
	MultiThread T0EventNum=0

	tmpPP=0
	tmpT0=0
	numRemoved=0
	
	Make/O/D/N=(numpnts(time_lsw)) timePt
	MultiThread timePt = 0		//need DP wave for time, time_lsw is 32 bit int


	nRoll = 0		//number of rollover events
	roll_time = 2^26		//units of 10-7 sec
	time_msw=0
	
	NVAR removeBadEvents = root:Packages:NIST:Event:gRemoveBadEvents
	
	num=numpnts(type)

//
// 		NOTE: I now have the types in 0123 order in the switch - so they will 
// 		appear different than the old Igor code which was 0132
//
	
	for(ii=0;ii<num;ii+=1)
//		if(mod(ii,10000)==0)
//			Print "step %g of %g",ii,num
//		endif
		
		typ = type[ii]
		
		switch(typ)
			case ATXY:
			
				// if the datavalue is == 0, just skip it now (it can only be interpreted as type 0, obviously)
				if(events[ii] == 0 && RemoveBadEvents == 1)
					numRemoved += 1
//					Print "zero at ii= ",ii

// flag for deletion later
					deletePtFlag[ii] = 1
					
//					DeletePoints ii,1, type,events,bit29,xloc,yloc,time_lsw,timePt
//					num -= 1
//					ii -= 1

					break		//don't increment ii
				endif
				
				//if bit29=1, it's pileup, delete the point, decrement ii and num and break out
				if(bit29[ii] == 1)
					PPTime[tmpPP] = timeval
					PPEventNum[tmpPP] = ii
					tmpPP += 1
					numRemoved += 1
					// flag for deletion later
					deletePtFlag[ii] = 1
//					DeletePoints ii,1, type,events,bit29,xloc,yloc,time_lsw,timePt
//					num -= 1
//					ii -= 1
					break
				endif
				
				//otherwise the point is good, calculate the time 
				timePt[ii] = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw[ii] )		//left shift msw by 2^13, then add in lsw, as an integer
				if (timePt[ii] > t_longest) 
					t_longest = timePt[ii]
				endif
				
				// catch the "bad" events:
				// if an XY event follows a rollover, time_msw is 0 by definition, but does not immediately get 
				// re-evalulated here. Throw out only the immediately following points where msw is still 8191
				if(rolloverHappened && RemoveBadEvents == 1)
					// maybe a bad event, throw it out
					if(time_msw == 8191)
						badTimePt[numBad] = timeVal
						badEventNum[numBad] = ii
						numBad +=1
						numRemoved += 1
						// flag for deletion later
						deletePtFlag[ii] = 1
//						DeletePoints ii,1, type,events,bit29,xloc,yloc,time_lsw,timePt
//						num -= 1
//						ii -= 1
					else
						// time_msw has been reset, points are good now, so keep this one
						rolloverHappened = 0
					endif
				endif
				
				break

			case ATMIR:		// 1

				time_msw =  (events[ii] & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
				timePt[ii] = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw[ii] )
				if (timePt[ii] > t_longest) 
					t_longest = timePt[ii]
				endif
				
				if(bit29[ii] != 0)		// bit 29 set is a T0 event, not a rollover
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = time_lsw[ii]
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
				
				// previous event was "2" (kept XY from there)
				// 
				xloc[ii] = tmpX
				yloc[ii] = tmpY
				
				break
			case ATXYM:		// 2
	
				//
				// keep only the XY position, next event will be ATMIR
				// where these XY points will be written
				//
				tmpX = xloc[ii]
				tmpY = yloc[ii]
				// flag for deletion later
				deletePtFlag[ii] = 1
//				DeletePoints ii,1, type,events,bit29,xloc,yloc,time_lsw	,timePt
//				num -= 1
//				ii -= 1
				
				// next event must be ATMIR (type 1) that will contain the MSW time bits
				break
			case ATMAR:		// 3
			
				nRoll += 1
				
				if(bit29[ii] != 0)		// bit 29 set is a T0 event, not a rollover
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = time_lsw[ii]
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
				
				rolloverHappened = 1
				
				// delete the point since it's not XY
				// flag for deletion later
				deletePtFlag[ii] = 1
//				DeletePoints ii,1, type,events,bit29,xloc,yloc,time_lsw	,timePt
//				num -= 1
//				ii -= 1
					
				break
			default:
		endswitch
	
	endfor

//	printf("Igor new method full file decode done in  ")	
//	toc()
	
	Print "Events removed (Igor) = ",numRemoved
	
	Variable numXYEvents = numpnts(xloc)
	String tmpStr=""
	
	sPrintf tmpStr,"\rBad Rollover Events = %d (%4.4g %% of events)",numBad,numBad/numXYevents*100
	dispStr += tmpStr
	sPrintf tmpStr,"\rTotal Events Removed = %d (%4.4g %% of events)",numRemoved,numRemoved/numXYevents*100
	dispStr += tmpStr
	SetDataFolder root:


	return(0)

end

// not used any longer since the one-by-one deletion of points is
// WAY too slow to use for any event files of > 50 MB
Function RemoveZeroEvents(events)
	Wave events
	
	// start at the back and remove zeros
	Variable num=numpnts(events),ii,numToRemove,count

	count = 0
	numToRemove = 2		//remove the zero, and the following FFFFFF
	ii=num
	do
		ii -= 1
		if(events[ii] == 0)
			DeletePoints ii, numToRemove, events
			count += 1
		endif
	while(ii > 0)
	
	print "removed zero events = ",count
	return(count)
End

//////////////////////////////
