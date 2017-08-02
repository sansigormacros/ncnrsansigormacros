#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.22

//
// Event mode prcessing for VSANS
//
// First pass, getting the basics to work
//
// -- need TOF processing for wavelength calibration
//  -- document this so it can be done quickly and easily.
//




// TODO:
//
// -- Can any of this be multithreaded?
//  -- the histogram operation, the Indexing for the histogram, all are candidates
//  -- can the decoding be multithreaded as a wave assignment speedup?
//
//
// -- search for TODO for unresolved issues not on this list
//
// -- add comments to the code as needed
//
// -- write the help file, and link the help buttons to the help docs
//
// -- examples?
//
//
// X- the slice display "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
//     interprets the data as being RGB - and so does nothing.
//     need to find a way around this. This was fixed by displaying the data using the G=1 flag on AppendImage
//     to prevent the "atuo-detection" of data as RGB
//
//
///////////////   SWITCHES     /////////////////
//
// for the "File Too Big" limit:
//	Variable/G root:Packages:NIST:VSANS:Event:gEventFileTooLarge = 150		// 150 MB considered too large
//
// for the tolerance of "step" detection
//	Variable/G root:Packages:NIST:VSANS:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
//
//
//
//


//  
// x- these dimensions are hard-wired (OK for now, will need to be additional definitions for Back detector)
//
// XBINS is for an individual panel
// NTUBES is the total number of tubes = (4)(48)=192
//
Constant XBINS=48
Constant NTUBES=192
Constant YBINS=128

Static Constant MODE_STREAM = 0
Static Constant MODE_OSCILL = 1
Static Constant MODE_TISANE = 2
Static Constant MODE_TOF = 3



// Initialization of the VSANS event mode panel
Proc V_Show_Event_Panel()
	DoWindow/F VSANS_EventModePanel
	if(V_flag ==0)
		V_Init_Event()
		VSANS_EventModePanel()
	EndIf
End

// 
//  x- need an index table with the tube <-> panel correspondence
//    NO, per Phil, the tube numbering is sequential:
//
// Based on the numbering 0-191:
// group 1 = R (0,47) 			MatrixOp out = ReverseRows(in)
// group 2 = T (48,95) 		output = slices_T[q][p][r]
// group 3 = B (96,143) 		output = slices_B[XBINS-q-1][YBINS-p-1][r]		(reverses rows and columns)
// group 4 = L (144,191) 	MatrixOp out = ReverseCols(in)
//
// There is a separate function that does the proper flipping to get the panels into the correct orientation
//
Function V_Init_Event()

	NewDataFolder/O/S root:Packages:NIST:VSANS:Event

	String/G 	root:Packages:NIST:VSANS:Event:gEvent_logfile
	String/G 	root:Packages:NIST:VSANS:Event:gEventDisplayString="Details of the file load"


// globals that are the header of the VSANS event file
	String/G root:Packages:NIST:VSANS:Event:gVsansStr=""
	Variable/G root:Packages:NIST:VSANS:Event:gRevision = 0
	Variable/G root:Packages:NIST:VSANS:Event:gOffset=0		// = 22 bytes if no disabled tubes
	Variable/G root:Packages:NIST:VSANS:Event:gTime1=0
	Variable/G root:Packages:NIST:VSANS:Event:gTime2=0
	Variable/G root:Packages:NIST:VSANS:Event:gTime3=0
	Variable/G root:Packages:NIST:VSANS:Event:gTime4=0	// these 4 time pieces are supposed to be 8 bytes total
	Variable/G root:Packages:NIST:VSANS:Event:gTime5=0	// these 5 time pieces are supposed to be 10 bytes total
	String/G root:Packages:NIST:VSANS:Event:gDetStr=""
	Variable/G root:Packages:NIST:VSANS:Event:gVolt=0
	Variable/G root:Packages:NIST:VSANS:Event:gResol=0		//time resolution in nanoseconds
// TODO -- need a wave? for the list of disabled tubes
// don't know how many there might be, or why I would need to know

	Variable/G root:Packages:NIST:VSANS:Event:gEvent_t_longest = 0

	Variable/G root:Packages:NIST:VSANS:Event:gEvent_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:VSANS:Event:gEvent_nslices = 10  //Number of time slices
	
	Variable/G root:Packages:NIST:VSANS:Event:gEvent_logint = 1

	Variable/G root:Packages:NIST:VSANS:Event:gEvent_Mode = 3				// ==0 for "stream", ==1 for Oscillatory
	Variable/G root:Packages:NIST:VSANS:Event:gRemoveBadEvents = 1		// ==1 to remove "bad" events, ==0 to read "as-is"
	Variable/G root:Packages:NIST:VSANS:Event:gSortStreamEvents = 0		// ==1 to sort the event stream, a last resort for a stream of data
	
	Variable/G root:Packages:NIST:VSANS:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices
	
		
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData


// for decimation (not used for VSANS - may be added back in the future
	Variable/G root:Packages:NIST:VSANS:Event:gEventFileTooLarge = 1500		// 1500 MB considered too large
	Variable/G root:Packages:NIST:VSANS:Event:gDecimation = 100
	Variable/G root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated = 0

// for large file splitting (unused)
	String/G root:Packages:NIST:VSANS:Event:gSplitFileList = ""		// a list of the file names as split
	
// for editing (unused)
	Variable/G root:Packages:NIST:VSANS:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
	
	SetDataFolder root:
End


//
// the main panel for VSANS Event mode
// -- a duplicate of the SANS panel, with the functions I'm not using disabled.
//  could be added back in the future
//
Proc VSANS_EventModePanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(82,44,884,664)/N=VSANS_EventModePanel/K=2
	DoWindow/C VSANS_EventModePanel
	ModifyPanel fixedSize=1,noEdit =1

	SetDrawLayer UserBack
	DrawText 479,345,"Stream Data"
	DrawLine 563,338,775,338
	DrawText 479,419,"Oscillatory or Stream Data"
	DrawLine 647,411,775,411

//	ShowTools/A
	Button button0,pos={14,87},size={150,20},proc=V_LoadEventLog_Button,title="Load Event Log File"
	Button button0,fSize=12
	TitleBox tb1,pos={475,500},size={266,86},fSize=10
	TitleBox tb1,variable= root:Packages:NIST:VSANS:Event:gEventDisplayString

	CheckBox chkbox2,pos={376,151},size={81,15},proc=V_LogIntEvent_Proc,title="Log Intensity"
	CheckBox chkbox2,fSize=10,variable= root:Packages:NIST:VSANS:Event:gEvent_logint
	CheckBox chkbox3,pos={14,125},size={119,15},title="Remove Bad Events?",fSize=10
	CheckBox chkbox3,variable= root:Packages:NIST:VSANS:Event:gRemoveBadEvents
	
	Button doneButton,pos={738,36},size={50,20},proc=V_EventDone_Proc,title="Done"
	Button doneButton,fSize=12
	Button button2,pos={486,200},size={140,20},proc=V_ShowEventDataButtonProc,title="Show Event Data"
	Button button3,pos={486,228},size={140,20},proc=V_ShowBinDetailsButtonProc,title="Show Bin Details"
	Button button5,pos={633,228},size={140,20},proc=V_ExportSlicesButtonProc,title="Export Slices as VAX",disable=2
	Button button6,pos={748,9},size={40,20},proc=V_EventModeHelpButtonProc,title="?"
		
	Button button7,pos={211,33},size={120,20},proc=V_AdjustEventDataButtonProc,title="Adjust Events"
	Button button8,pos={653,201},size={120,20},proc=V_CustomBinButtonProc,title="Custom Bins"
	Button button4,pos={211,63},size={120,20},proc=V_UndoTimeSortButtonProc,title="Undo Time Sort"
	Button button18,pos={211,90},size={120,20},proc=V_EC_ImportWavesButtonProc,title="Import Edited"
	
	SetVariable setvar0,pos={208,149},size={160,16},proc=V_sliceSelectEvent_Proc,title="Display Time Slice"
	SetVariable setvar0,fSize=10
	SetVariable setvar0,limits={0,1000,1},value= root:Packages:NIST:VSANS:Event:gEvent_tsdisp	
	SetVariable setvar1,pos={389,29},size={160,16},title="Number of slices",fSize=10
	SetVariable setvar1,limits={1,1000,1},value= root:Packages:NIST:VSANS:Event:gEvent_nslices
	SetVariable setvar2,pos={389,54},size={160,16},title="Max Time (s)",fSize=10
	SetVariable setvar2,value= root:Packages:NIST:VSANS:Event:gEvent_t_longest
	
	PopupMenu popup0,pos={389,77},size={119,20},proc=V_BinTypePopMenuProc,title="Bin Spacing"
	PopupMenu popup0,fSize=10
	PopupMenu popup0,mode=1,popvalue="Equal",value= #"\"Equal;Fibonacci;Custom;\""
	Button button1,pos={389,103},size={120,20},fSize=12,proc=V_ProcessEventLog_Button,title="Bin Event Data"

// NEW FOR VSANS
	Button button21,pos={580,70},size={120,20},proc=V_SplitToPanels_Button,title="Split to Panels"
	Button button22,pos={580,90},size={120,20},proc=V_GraphPanels_Button,title="Show Panels"

	Button button10,pos={488,305},size={100,20},proc=V_SplitFileButtonProc,title="Split Big File",disable=2
	Button button14,pos={488,350},size={120,20},proc=V_Stream_LoadDecim,title="Load Split List",disable=2
	Button button19,pos={649,350},size={120,20},proc=V_Stream_LoadAdjustedList,title="Load Edited List",disable=2
	Button button20,pos={680,376},size={90,20},proc=V_ShowList_ToLoad,title="Show List",disable=2
	SetVariable setvar3,pos={487,378},size={150,16},title="Decimation factor",disable=2
	SetVariable setvar3,fSize=10
	SetVariable setvar3,limits={1,inf,1},value= root:Packages:NIST:VSANS:Event:gDecimation

	Button button15_0,pos={488,425},size={110,20},proc=V_AccumulateSlicesButton,title="Add First Slice",disable=2
	Button button16_1,pos={488,450},size={110,20},proc=V_AccumulateSlicesButton,title="Add Next Slice",disable=2
	Button button17_2,pos={620,425},size={110,20},proc=V_AccumulateSlicesButton,title="Display Total",disable=2

	CheckBox chkbox1_0,pos={25,34},size={69,14},title="Oscillatory",fSize=10
	CheckBox chkbox1_0,mode=1,proc=V_EventModeRadioProc,value=0
	CheckBox chkbox1_1,pos={25,59},size={53,14},title="Stream",fSize=10
	CheckBox chkbox1_1,proc=V_EventModeRadioProc,value=0,mode=1
	CheckBox chkbox1_2,pos={104,59},size={53,14},title="TISANE",fSize=10
	CheckBox chkbox1_2,proc=V_EventModeRadioProc,value=0,mode=1
	CheckBox chkbox1_3,pos={104,34},size={37,14},title="TOF",fSize=10
	CheckBox chkbox1_3,proc=V_EventModeRadioProc,value=1,mode=1
	
	GroupBox group0_0,pos={5,5},size={174,112},title="(1) Loading Mode",fSize=12,fStyle=1
	GroupBox group0_1,pos={372,5},size={192,127},title="(3) Bin Events",fSize=12,fStyle=1
	GroupBox group0_2,pos={477,169},size={310,92},title="(4) View / Export",fSize=12,fStyle=1
	GroupBox group0_3,pos={191,5},size={165,117},title="(2) Edit Events",fSize=12,fStyle=1
	GroupBox group0_4,pos={474,278},size={312,200},title="Split / Accumulate Files",fSize=12
	GroupBox group0_4,fStyle=1
	
	Display/W=(10,170,460,610)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:dispsliceData		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
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

//
// takes the data that is loaded and binned as a fake
// (192 x 128) panel to the four LRTB panels, each with 48 tubes
//
Function V_SplitToPanels_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_SplitBinnedToPanels()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// after splitting the data into the 4 panels, draws a simple graph to display the panels
//
Function V_GraphPanels_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/F VSANS_EventPanels
			if(V_flag == 0)
				Execute "VSANS_EventPanels()"
			endif
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// mode selector
//Static Constant MODE_STREAM = 0
//Static Constant MODE_OSCILL = 1
//Static Constant MODE_TISANE = 2
//Static Constant MODE_TOF = 3
//
Function V_EventModeRadioProc(name,value)
	String name
	Variable value
	
	NVAR gEventModeRadioVal= root:Packages:NIST:VSANS:Event:gEvent_mode
	
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

Function V_AdjustEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_ShowEventCorrectionPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_CustomBinButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_Show_CustomBinPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_ShowEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_ShowRescaledTimeGraph()"
			//
			V_DifferentiatedTime()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_BinTypePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			if(cmpstr(popStr,"Custom")==0)
				Execute "V_Show_CustomBinPanel()"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_ShowBinDetailsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_ShowBinTable()"
			Execute "V_BinEventBarGraph()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_UndoTimeSortButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_UndoTheSorting()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_ExportSlicesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_ExportSlicesAsVAX()"		//will invoke the dialog
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_EventModeHelpButtonProc(ba) : ButtonControl
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


Function V_EventDone_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K VSANS_EventModePanel
			break
	endswitch
	return(0)
End



Function V_ProcessEventLog_Button(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR mode=root:Packages:NIST:VSANS:Event:gEvent_Mode
	
	if(mode == MODE_STREAM)
		V_Stream_ProcessEventLog("")
	endif
	
	if(mode == MODE_OSCILL)
		V_Osc_ProcessEventLog("")
	endif
	
	// If TOF mode, process as Oscillatory -- that is, take the times as is
	if(mode == MODE_TOF)
		V_Osc_ProcessEventLog("")
	endif
	
	// toggle the checkbox for log display to force the display to be correct
	NVAR gLog = root:Packages:NIST:VSANS:Event:gEvent_logint
	V_LogIntEvent_Proc("",gLog)
	
	return(0)
end

//
// for oscillatory mode
//
// Allocate the space for the data as if it was a single 192 x 128 pixel array.
// The (4) 48-tube panels will be split out later. this means that as defined,
// XBINS is for an individual panel
// NTUBES is the total number of tubes = (4)(48)=192
//
Function V_Osc_ProcessEventLog(ctrlName)
	String ctrlName

//	Make/O/D/N=(XBINS,YBINS) root:Packages:NIST:VSANS:Event:binnedData
	Make/O/D/N=(NTUBES,YBINS) root:Packages:NIST:VSANS:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:VSANS:Event:binnedData
	Wave xLoc = root:Packages:NIST:VSANS:Event:xLoc
	Wave yLoc = root:Packages:NIST:VSANS:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:VSANS:Event		//don't count on the folder remaining here
	
//	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Make/D/O/N=(NTUBES,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
//	Make/O/D/N=(XBINS,YBINS) tmpData
	Make/O/D/N=(NTUBES,YBINS) tmpData
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
	ControlInfo /W=VSANS_EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			V_SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			V_SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			V_SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			V_SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch


// now before binning, sort the data

	//this is slow - undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	SetDataFolder root:Packages:NIST:VSANS:Event:

v_tic()
	if(WaveExists($"root:Packages:NIST:VSANS:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
		//SetDataFolder root:Packages:NIST:VSANS:Event
		V_IndexForHistogram(xLoc,yLoc,binnedData)			// index the events AFTER sorting
		//SetDataFolder root:
	Endif
	
printf "sort time = "
v_toc()

	Wave index = root:Packages:NIST:VSANS:Event:SavedIndex		//this is the histogram index

v_tic()
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
		V_JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor
printf "histogram time = "
v_toc()

	Duplicate/O slicedData,root:Packages:NIST:VSANS:Event:dispsliceData,root:Packages:NIST:VSANS:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:VSANS:Event:logSlicedData
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
//
// Allocate the space for the data as if it was a single 192 x 128 pixel array.
// The (4) 48-tube panels will be split out later. this means that as defined,
// XBINS is for an individual panel
// NTUBES is the total number of tubes = (4)(48)=192
//
Function V_Stream_ProcessEventLog(ctrlName)
	String ctrlName

//	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth

	
//	Make/O/D/N=(XBINS,YBINS) root:Packages:NIST:VSANS:Event:binnedData
	Make/O/D/N=(NTUBES,YBINS) root:Packages:NIST:VSANS:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:VSANS:Event:binnedData
	Wave xLoc = root:Packages:NIST:VSANS:Event:xLoc
	Wave yLoc = root:Packages:NIST:VSANS:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR yesSortStream = root:Packages:NIST:VSANS:Event:gSortStreamEvents		//do I sort the events?
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:VSANS:Event		//don't count on the folder remaining here
	
//	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Make/D/O/N=(NTUBES,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
//	Make/O/D/N=(XBINS,YBINS) tmpData
	Make/O/D/N=(NTUBES,YBINS) tmpData
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
	ControlInfo /W=VSANS_EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			V_SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			V_SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			V_SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			V_SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch

// TODO
// the global exists for this switch, but it is not implemented - not sure whether
// it's correct to implement this at all --
//
	if(yesSortStream == 1)
		V_SortTimeData()
	endif
	
// index the events before binning
// if there is a sort of these events, I need to re-index the events for the histogram
//	SetDataFolder root:Packages:NIST:VSANS:Event
	V_IndexForHistogram(xLoc,yLoc,binnedData)
//	SetDataFolder root:
	Wave index = root:Packages:NIST:VSANS:Event:SavedIndex		//the index for the histogram
	
	
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
		V_JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

	Duplicate/O slicedData,root:Packages:NIST:VSANS:Event:dispsliceData,root:Packages:NIST:VSANS:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:VSANS:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End


Proc	V_UndoTheSorting()
	V_Osc_UndoSort()
End

// for oscillatory mode
//
// -- this takes the previously generated index, and un-sorts the data to restore to the
// "as-collected" state
//
Function V_Osc_UndoSort()

	SetDataFolder root:Packages:NIST:VSANS:Event		//don't count on the folder remaining here
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
Function V_SortTimeData()


	SetDataFolder root:Packages:NIST:VSANS:Event:

	KillWaves/Z OscSortIndex
	
	if(WaveExists($"root:Packages:NIST:VSANS:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
	Endif
	
	SetDataFolder root:
	return(0)
End



Function V_SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
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
Function V_SetLogBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii

	Wave rescaledTime = root:Packages:NIST:VSANS:Event:rescaledTime
	
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

Function V_MakeFibonacciWave(w,num)
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

Function V_SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii,total,t2,tmp
	Make/O/D/N=(nslices) fibo
	fibo=0
	V_MakeFibonacciWave(fibo,nslices)
	
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



// 
// -- The "file too large" check has currently been set to 1.5 GB
//
//	
Function V_LoadEventLog_Button(ctrlName) : ButtonControl
	String ctrlName

	NVAR mode=root:Packages:NIST:VSANS:Event:gEvent_mode
	Variable err=0
	Variable fileref,totBytes
	NVAR fileTooLarge = root:Packages:NIST:VSANS:Event:gEventFileTooLarge		//limit load to 1500MB

	SVAR filename = root:Packages:NIST:VSANS:Event:gEvent_logfile
	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	String abortStr
	
	PathInfo catPathName
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

//  keep this	, but set to 1.5 GB
// since I'm now in 64-bit space
/// Abort if the files are too large
	Open/R fileref as fileName
		FStatus fileref
	Close fileref
//
	totBytes = V_logEOF/1e6		//in MB
	if(totBytes > fileTooLarge)
		sprintf abortStr,"File is %g MB, larger than the limit of %g MB. Split and Decimate.",totBytes,fileTooLarge
		Abort abortStr
	endif
//	
	Print "TotalBytes (MB) = ",totBytes
	

	SetDataFolder root:Packages:NIST:VSANS:Event:

// load in the event file and decode it
	
//	V_readFakeEventFile(fileName)
	V_LoadEvents()			// this now loads, decodes, and returns location, tube, and timePt
	SetDataFolder root:Packages:NIST:VSANS:Event:			//GBLoadWave in V_LoadEvents sets back to root:

// Now, I have tube, location, and timePt (no units yet)
// assign to the proper panels

// 
// x- (YES - this is MUCH faster)  if I do the JointHistogram first, then break out the blocks of the 
//  3D sliced data into the individual panels. Then the sort operation can be skipped,
//  since it is implicitly be done during the histogram operation
// x- go back and redimension as needed to get the 128 x 192 histogram to work
// x- MatrixOp or a wave assignemt should be able to break up the 3D
//

		KillWaves/Z timePt,xLoc,yLoc
		Duplicate/O eventTime timePt

// 
// x- for processing, initially treat all of the tubes along x, and 128 pixels along y
//   panels can be transposed later as needed to get the orientation correct

		Duplicate/O tube xLoc
		Duplicate/O location yLoc
		
		Redimension/D xLoc,yLoc,timePt	
		
//v_tic()
//	V_SortAndSplitEvents()
//
//Printf "File sort and split time (s) = "
//v_toc()

//
// switch the "active" panel to the selected group (1-4) (5 concatenates them all together)
//
// copy the set of tubes over to the "active" set that is to be histogrammed
// and redimension them to be sure that they are double precision
//
//
//	V_SwitchTubeGroup(1)
//
//	

//tic()
	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	V_CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes	
//toc()
	
	NVAR gResol = root:Packages:NIST:VSANS:Event:gResol		//timeStep in clock frequency (Hz)
	Printf "Time Step = 1/Frequency (ns) = %g\r",(1/gResol)*1e9
	
/////
// now do a little processing of the times based on the type of data
//	

// TODO:
//  -- the time scaling is NOT done. it is still in raw ticks.
//
	if(mode == MODE_STREAM)		// continuous "Stream" mode - start from zero
		Duplicate/O timePt rescaledTime
		rescaledTime = 1*(timePt-timePt[0])		//convert to nanoseconds and start from zero
		t_longest = waveMax(rescaledTime)		//should be the last point	
	endif
	
	if(mode == MODE_OSCILL)		// oscillatory mode - don't adjust the times, we get periodic t0 to reset t=0
		Duplicate/O timePt rescaledTime
		rescaledTime *= 1			//convert to nanoseconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif

// MODE_TISANE


// MODE_TOF
	if(mode == MODE_TOF)		// TOF mode - don't adjust the times, we get periodic t0 to reset t=0
		Duplicate/O timePt rescaledTime
		rescaledTime *= 1			//convert to nanoseconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif

	SetDataFolder root:

	STRUCT WMButtonAction ba
	ba.eventCode = 2
	V_ShowEventDataButtonProc(ba)

	return(0)
End




//
// -- MUCH faster to count the number of lines to remove, then delete (N)
// rather then delete them one-by-one in the do-loop
//
Function V_CleanupTimes(xLoc,yLoc,timePt)
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

Function V_LogIntEvent_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:VSANS:Event
	
	Wave slicedData = slicedData
	Wave logSlicedData = logSlicedData
	Wave dispSliceData = dispSliceData
	
	if(checked)
		logslicedData = log(slicedData)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	NVAR selectedslice = root:Packages:NIST:VSANS:Event:gEvent_tsdisp

	V_sliceSelectEvent_Proc("", selectedslice, "", "")

	SetDataFolder root:

End


// (DONE)
// this "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
// interprets the data as being RGB - and so does nothing.
// need to find a way around this
//
////  When first plotted, AppendImage/G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
///
// I could modify this procedure to use the log = 0|1 keyword for the log Z display
// rather than creating a duplicate wave of log(data)
//
Function V_sliceSelectEvent_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices
	NVAR selectedslice = root:Packages:NIST:VSANS:Event:gEvent_tsdisp
	
	if(varNum < 0)
		selectedslice = 0
		DoUpdate
	elseif (varNum > nslices-1)
		selectedslice = nslices-1
		DoUpdate
	else
		ModifyImage/W=VSANS_EventModePanel#Event_slicegraph ''#0 plane = varNum 
	endif

End

Function V_DifferentiatedTime()

	Wave rescaledTime = root:Packages:NIST:VSANS:Event:rescaledTime

	SetDataFolder root:Packages:NIST:VSANS:Event:
		
	Differentiate rescaledTime/D=rescaledTime_DIF
//	Display rescaledTime,rescaledTime_DIF
	DoWindow/F V_Differentiated_Time
	if(V_flag == 0)
		Display/N=V_Differentiated_Time/K=1 rescaledTime_DIF
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
//  for 64-bit values:
// http://calc.penjee.com
//
//
//
//		K0 = 536870912
// 		Print (K0 & 0x08000000)/134217728 	//bit 27 only, shift by 2^27
//		Print (K0 & 0x10000000)/268435456		//bit 28 only, shift by 2^28
//		Print (K0 & 0x20000000)/536870912		//bit 29 only, shift by 2^29
//
//
//
// This function loads the events, and decodes them.
// Assigning them to detector panels is a separate function
//
//
//
Function V_LoadEvents()
	
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:VSANS:Event:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:VSANS:Event:gEventDisplayString
	
	SetDataFolder root:Packages:NIST:VSANS:Event

	Variable refnum
	String buffer
	String fileStr,tmpStr
	Variable verbose
	Variable xval,yval
	Variable numXYevents,totBytes

//  to read a VSANS event file:
//
// - get the file name
//	- read the header (all of it, since I need parts of it) (maybe read as a struct? but I don't know the size!)
// - move to EOF and close
//
// - Use GBLoadWave to read the 64-bit events in


/// globals to report the header back for use or status
	SVAR gVSANSStr = root:Packages:NIST:VSANS:Event:gVsansStr
	NVAR gRevision = root:Packages:NIST:VSANS:Event:gRevision
	NVAR gOffset = root:Packages:NIST:VSANS:Event:gOffset		// = 22 bytes if no disabled tubes
	NVAR gTime1 = root:Packages:NIST:VSANS:Event:gTime1
	NVAR gTime2 = root:Packages:NIST:VSANS:Event:gTime2
	NVAR gTime3 = root:Packages:NIST:VSANS:Event:gTime3
	NVAR gTime4 = root:Packages:NIST:VSANS:Event:gTime4	// these 4 time pieces are supposed to be 8 bytes total
	NVAR gTime5 = root:Packages:NIST:VSANS:Event:gTime5	// these 5 time pieces are supposed to be 10 bytes total
	SVAR gDetStr = root:Packages:NIST:VSANS:Event:gDetStr
	NVAR gVolt = root:Packages:NIST:VSANS:Event:gVolt
	NVAR gResol = root:Packages:NIST:VSANS:Event:gResol		//time resolution in nanoseconds
/////

	gVSANSStr = PadString(gVSANSStr,5,0x20)		//pad to 5 bytes
	gDetStr = PadString(gDetStr,1,0x20)				//pad to 1 byte

	numXYevents = 0


	Open/R refnum as filepathstr
	
v_tic()

	FBinRead refnum, gVSANSStr
	FBinRead/F=2/U refnum, gRevision
	FBinRead/F=2/U refnum, gOffset
	FBinRead/F=2/U refnum, gTime1
	FBinRead/F=2/U refnum, gTime2
	FBinRead/F=2/U refnum, gTime3
	FBinRead/F=2/U refnum, gTime4
	FBinRead/F=2/U refnum, gTime5
	FBinRead refnum, gDetStr
	FBinRead/F=2/U refnum, gVolt
	FBinRead/F=3/U refnum, gResol

	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum
	
// number of data bytes
	numXYevents = (V_logEOF-gOffset)/8
	Print "Number of data values = ",numXYevents
	
	GBLoadWave/B/T={192,192}/W=1/S=(gOffset) filepathstr
	
	Duplicate/O $(StringFromList(0,S_waveNames)) V_Events
	KillWaves/Z $(StringFromList(0,S_waveNames))

Printf "Time to read file (s) = "
v_toc()	


	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	

// V_Events is the uint64 wave that was read in
//
////// Now decode the events


v_tic()
	WAVE V_Events = V_Events
	uint64 val,b1,b2,btime

	
	Variable num,ii
	num=numpnts(V_Events)
	
	Make/O/L/U/N=(num) eventTime			//64 bit unsigned
	Make/O/U/B/N=(num) tube,location		//8 bit unsigned

// MultiThread is about 10x faster than the for loop
 MultiThread tube = (V_Events[p]) & 0xFF	
 MultiThread location = (V_Events[p] >> 8 ) & 0xFF	
 MultiThread eventTime = (V_Events[p] >> 16)
	
//	for(ii=0;ii<num;ii+=1)
//		val = V_Events[ii]
//		
////		b1 = (val >> 56 ) & 0xFF			// = 255, last two bytes, after shifting
////		b2 = (val >> 48 ) & 0xFF	
////		btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes
//
//		b1 = val & 0xFF
//		b2 = (val >> 8) & 0xFF
//		btime = (val >> 16)
//
//
//		tube[ii] = b1
//		location[ii] = b2
//		eventTime[ii] = btime
//		
//	endfor

Printf "File decode time (s) = "
v_toc()

//	KillWaves/Z timePt,xLoc,yLoc
//	Rename tube xLoc
//	Rename location yLoc
//	Rename eventTime timePt
//	
//	Redimension/D xLoc,yLoc,timePt
	

// TODO
// add more to the status display of the file load/decode
//	
	// dispStr will be displayed on the panel
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numXYevents
	dispStr += tmpStr
//	sPrintf tmpStr,"\rBad Rollover Events = %d (%4.4g %% of events)",numBad,numBad/numXYevents*100
//	dispStr += tmpStr
//	sPrintf tmpStr,"\rTotal Events Removed = %d (%4.4g %% of events)",numRemoved,numRemoved/numXYevents*100
//	dispStr += tmpStr

	SetDataFolder root:
	
	return(0)
	
End 

////////////////
////
//// This calls the XOP, as an operation to load the events
////
//// -- it's about 35x faster than the Igor code, so I guess that's OK.
////
//// conditional compile the whole inner workings in case XOP is not present
//Function LoadEvents_XOP()
//#if (exists("EventLoadWave")==4)
//	
////	NVAR time_msw = root:Packages:NIST:VSANS:Event:gEvent_time_msw
////	NVAR time_lsw = root:Packages:NIST:VSANS:Event:gEvent_time_lsw
//	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
//	
//	SVAR filepathstr = root:Packages:NIST:VSANS:Event:gEvent_logfile
//	SVAR dispStr = root:Packages:NIST:VSANS:Event:gEventDisplayString
//	
//	SetDataFolder root:Packages:NIST:VSANS:Event
//
//
//
//	Variable fileref
//	String buffer
//	String fileStr,tmpStr
//	Variable dataval,timeval,type,numLines,verbose,verbose3
//	Variable xval,yval,rollBit,nRoll,roll_time,bit29,bit28,bit27
//	Variable ii,flaggedEvent,rolloverHappened,numBad=0,tmpPP=0,tmpT0=0
//	Variable Xmax, yMax
//	
//	xMax = 127		// number the detector from 0->127 
//	yMax = 127
//	
//	numLines = 0
//
//	//Have to declare local variables for Loadwave so that this compiles without XOP.
//	String S_waveNames
//	//  and those for the XOP
//	Variable V_nXYevents,V_num1,V_num2,V_num3,V_num0,V_totBytes,V_numPP,V_numT0,V_numDL,V_numFF,V_numZero
//	Variable V_numBad,V_numRemoved
//	
//	// what I really need is the number of XY events
//	Variable numXYevents,num1,num2,num3,num0,totBytes,numPP,numT0,numDL,numFF,numZero
//	Variable numRemoved
//	numXYevents = 0
//	num0 = 0
//	num1 = 0
//	num2 = 0
//	num3 = 0
//	numPP = 0
//	numT0 = 0
//	numDL = 0
//	numFF = 0
//	numZero = 0
//	numRemoved = 0
//
//// get the total number of bytes in the file
//	Open/R fileref as filepathstr
//		FStatus fileref
//	Close fileref
//
//	totBytes = V_logEOF
//	Print "total bytes = ", totBytes
//	
////
////	Print "scan only"
////	tic()
////		EventLoadWave/R/N=EventWave/W filepathstr
////	toc()
//
//////
////
////  use the XOP operation to load in the data
//// -- this does everything - the pre-scan and creating the waves
////
//// need to zero the waves before loading, just in case
////
//
//	NVAR removeBadEvents = root:Packages:NIST:VSANS:Event:gRemoveBadEvents
//
//v_tic()
//
////	Wave/Z wave0=wave0
////	Wave/Z wave1=wave1
////	Wave/Z wave2=wave2
////
////	if(WaveExists(wave0))
////		MultiThread wave0=0
////	endif
////	if(WaveExists(wave1))
////		MultiThread wave1=0
////	endif
////	if(WaveExists(wave2))
////		MultiThread wave2=0
////	endif
//
//	if(removeBadEvents)
//		EventLoadWave/R/N=EventWave filepathstr
//	else
//		EventLoadWave/N=EventWave  filepathstr
//	endif
//
//
//	Print "XOP files loaded = ",S_waveNames
//
//////		-- copy the waves over to xLoc,yLoc,timePt
//	Wave/Z EventWave0=EventWave0
//	Wave/Z EventWave1=EventWave1
//	Wave/Z EventWave2=EventWave2
//	
//	
//	Duplicate/O EventWave0,xLoc
//	KillWaves/Z EventWave0
//
//	Duplicate/O EventWave1,yLoc
//	KillWaves/Z EventWave1
//
//	Duplicate/O EventWave2,timePt
//	KillWaves/Z EventWave2
//
//// could do this, but rescaled time will neeed to be converted to SP (or DP)
//// and Igor loader was written with Make generating SP/DP waves
//	// /I/U is unsigned 32-bit integer (for the time)
//	// /B/U is unsigned 8-bit integer (max val=255) for the x and y values
//	
////	Redimension/B/U xLoc,yLoc
////	Redimension/I/U timePt
//
//	// access the variables from the XOP
//	numT0 = V_numT0
//	numPP = V_numPP
//	num0 = V_num0
//	num1 = V_num1
//	num2 = V_num2
//	num3 = V_num3
//	numXYevents = V_nXYevents
//	numZero = V_numZero
//	numBad = V_numBad
//	numRemoved = V_numRemoved
//	
//	Print "(XOP) numT0 = ",numT0	
//	Print "num0 = ",num0	
//	Print "num1 = ",num1	
//	Print "num2 = ",num2	
//	Print "num3 = ",num3	
//	
//
//// dispStr will be displayed on the panel
//	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
//	
//	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
//	dispStr = tmpStr
//	sprintf tmpStr,"numXYevents = %d\r",numXYevents
//	dispStr += tmpStr
//	sprintf tmpStr,"PP = %d  :  ",numPP
//	dispStr += tmpStr
//	sprintf tmpStr,"ZeroData = %d\r",numZero
//	dispStr += tmpStr
//	sprintf tmpStr,"Rollover = %d",num3
//	dispStr += tmpStr
//
//	v_toc()
//	
//	Print "Events removed (XOP) = ",numRemoved
//	
//	sPrintf tmpStr,"\rBad Rollover Events = %d (%4.4g %% of events)",numBad,numBad/numXYevents*100
//	dispStr += tmpStr
//	sPrintf tmpStr,"\rTotal Events Removed = %d (%4.4g %% of events)",numRemoved,numRemoved/numXYevents*100
//	dispStr += tmpStr
//
//
//// simply to compile a table of # XY vs # bytes
////	Wave/Z nxy = root:numberXY
////	Wave/Z nBytes = root:numberBytes
////	if(WaveExists(nxy) && WaveExists(nBytes))
////		InsertPoints 0, 1, nxy,nBytes
////		nxy[0] = numXYevents
////		nBytes[0] = totBytes
////	endif
//
//	SetDataFolder root:
//
//#endif	
//	return(0)
//	
//End 

//////////////

Proc V_BinEventBarGraph()
	
	DoWindow/F V_EventBarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:VSANS:Event:
		Display /W=(110,705,610,1132)/N=V_EventBarGraph /K=1 binCount vs binEndTime
		SetDataFolder fldrSav0
		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=0
		ModifyGraph useBarStrokeRGB=1
		ModifyGraph standoff=0
		SetAxis left 0,*
		Label bottom "\\Z14Time (seconds)"
		Label left "\\Z14Number of Events"
	endif
End


Proc V_ShowBinTable() 

	DoWindow/F V_BinEventTable
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:VSANS:Event:
		Edit/W=(498,699,1003,955) /K=1/N=V_BinEventTable binCount,binEndTime,timeWidth
		ModifyTable format(Point)=1,sigDigits(binEndTime)=8,width(binEndTime)=100
		SetDataFolder fldrSav0
	endif
EndMacro


// only show the first 1500 data points
//
Proc V_ShowRescaledTimeGraph()

	DoWindow/F V_RescaledTimeGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:VSANS:Event:
		Display /W=(25,44,486,356)/K=1/N=V_RescaledTimeGraph rescaledTime
		SetDataFolder fldrSav0
		ModifyGraph mode=4
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



//Proc ExportSlicesAsVAX(firstNum,prefix)
//	Variable firstNum=1
//	String prefix="SAMPL"
//
//	SaveSlicesAsVAX(firstNum,prefix[0,4])		//make sure that the prefix is 5 chars
//End

////////// procedures to be able to export the slices as RAW VAX files.
////
//// 1- load the raw data file to use the header (it must already be in RAW)
//// 1.5- copy the raw data to the temp folder (STO)
//// 1.7- ask for the prefix and starting run number (these are passed in)
//// 2- copy the slice of data to the temp folder (STO)
//// 3- touch up the time/counts in the slice header values in STO
//// 4- write out the VAX file
//// 5- repeat (2-4) for the number of slices
////
////
//Function SaveSlicesAsVAX(firstNum,prefix)
//	Variable firstNum
//	String prefix
//
//	DoAlert 1,"Is the full data file loaded as a RAW data file? If not, load it and start over..."
//	if(V_flag == 2)
//		return (0)
//	endif
//	
//// copy the contents of RAW to STO so I can work from there
//	CopyWorkContents("RAW","STO")
//
//	// now declare all of the waves, now that they are sure to be there
//
//	WAVE slicedData=root:Packages:NIST:VSANS:Event:slicedData
//	Make/O/D/N=(128,128) curSlice
//	
//	NVAR nslices = root:Packages:NIST:VSANS:Event:gEvent_nslices
//	WAVE binEndTime = root:Packages:NIST:VSANS:Event:binEndTime
//
//	Wave rw=root:Packages:NIST:STO:realsRead
//	Wave iw=root:Packages:NIST:STO:integersRead
//	Wave/T tw=root:Packages:NIST:STO:textRead
//	Wave data=root:Packages:NIST:STO:data
//	Wave linear_data=root:Packages:NIST:STO:linear_data
//	
//	
//	Wave rw_raw=root:Packages:NIST:RAW:realsRead
//	Wave iw_raw=root:Packages:NIST:RAW:integersRead
//	Wave/T tw_raw=root:Packages:NIST:RAW:textRead
//
//// for generating the alphanumeric
//	String timeStr= secs2date(datetime,-1)
//	String monthStr=StringFromList(1, timeStr  ,"/")
//	String numStr="",labelStr
//
//	Variable ii,err,binFraction
//	
//	for(ii=0;ii<nslices;ii+=1)
//
//		//get the current slice and put it in the STO folder
//		curSlice = slicedData[p][q][ii]
//		data = curSlice
//		linear_data = curSlice
//		
//		// touch up the header as needed
//		// count time = iw[2]
//		// monCt = rw[0]
//		// detCt = rw[2]
//		//tw[0] must now be the file name
//		//
//		// count time = fraction of total binning * total count time
//		binFraction = (binEndTime[ii+1]-binEndTime[ii])/(binEndTime[nslices]-binEndTime[0])
//		
//		iw[2] = trunc(binFraction*iw_raw[2])
//		rw[0] = trunc(binFraction*rw_raw[0])
//		rw[2] = sum(curSlice,-inf,inf)		//total counts in slice
//	
//		if(firstNum<10)
//			numStr = "00"+num2str(firstNum)
//		else
//			if(firstNum<100)
//				numStr = "0"+num2str(firstNum)
//			else
//				numStr = num2str(firstNum)
//			Endif
//		Endif	
//		tw[0] = prefix+numstr+".SA2_EVE_"+(num2char(str2num(monthStr)+64))+numStr
//		labelStr = tw_raw[6]
//		
//		labelStr = PadString(labelStr,60,0x20) 	//60 fortran-style spaces
//		tw[6] = labelStr[0,59]
//		
//		//write out the file - this uses the tw[0] and home path
//		Write_VAXRaw_Data("STO","",0)
//
//		//increment the run number, alpha
//		firstNum += 1	
//	endfor
//
//	return(0)
//End
//




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
//	JointHistogram(data1,data2,myHist,index)
//	NewImage myHist
//	
////	toc()
//	
//End


// this is not used - it now conflicts with the name of a built-in function in Igor 7
//
Function xJointHistogram(w0,w1,hist,index)
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
Function V_JointHistogramWithRange(w0,w1,hist,index,pt1,pt2)
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
Function V_IndexForHistogram(w0,w1,hist)
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
//
//
// TODO:
// -- this is ALL geared towards ordela event mode data and the 6.7s errors, and bad signal
//   I don't know if I'll need any of this for the VSANS event data.
//
//
Proc V_ShowEventCorrectionPanel()
	DoWindow/F V_EventCorrectionPanel
	if(V_flag ==0)
		V_EventCorrectionPanel()
	EndIf
End

Proc V_EventCorrectionPanel()

	PauseUpdate; Silent 1		// building window...
	SetDataFolder root:Packages:NIST:VSANS:Event:
	
	if(exists("rescaledTime") == 1)
		Display /W=(35,44,761,533)/K=2 rescaledTime
		DoWindow/C V_EventCorrectionPanel
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=1
		ErrorBars rescaledTime OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"	
		SetAxis bottom 0,0.10*numpnts(rescaledTime)		//show 1st 10% of data for speed in displaying
		
		ControlBar 100
		Button button0,pos={18,12},size={70,20},proc=V_EC_AddCursorButtonProc,title="Cursors"
		Button button1,pos={153,12},size={80,20},proc=V_EC_AddTimeButtonProc,title="Add time"
		Button button2,pos={153,38},size={80,20},proc=V_EC_SubtractTimeButtonProc,title="Subtr time"
		Button button3,pos={153,64},size={90,20},proc=V_EC_TrimPointsButtonProc,title="Trim points"
		Button button4,pos={295+150,12},size={90,20},proc=V_EC_SaveWavesButtonProc,title="Save Waves"
		Button button5,pos={295,64},size={100,20},proc=V_EC_FindOutlierButton,title="Find Outlier"
		Button button6,pos={18,38},size={80,20},proc=V_EC_ShowAllButtonProc,title="All Data"
		Button button7,pos={683,12},size={30,20},proc=V_EC_HelpButtonProc,title="?"
		Button button8,pos={658,72},size={60,20},proc=V_EC_DoneButtonProc,title="Done"
	
		Button button9,pos={295,12},size={110,20},proc=V_EC_FindStepButton_down,title="Find Step Down"
		Button button10,pos={295,38},size={110,20},proc=V_EC_FindStepButton_up,title="Find Step Up"
		Button button11,pos={295+150,38},size={110,20},proc=V_EC_DoDifferential,title="Differential"
		
		
	else
		DoAlert 0, "Please load some event data, then you'll have something to edit."
	endif
	
	SetDataFolder root:
	
EndMacro

Function V_EC_AddCursorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:VSANS:Event:
			
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
Function V_EC_AddTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:VSANS:Event:
			
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
			NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_EC_SubtractTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:VSANS:Event:
			
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
			NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
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
Function V_EC_TrimPointsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:VSANS:Event:
			
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
			NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// un-sort the data first, then save it
Function V_EC_SaveWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			Execute "UndoTheSorting()"
			
			SetDataFolder root:Packages:NIST:VSANS:Event:
			
			Wave rescaledTime = rescaledTime
			Wave timePt = timePt
			Wave xLoc = xLoc
			Wave yLoc = yLoc
			Save/T xLoc,yLoc,timePt	,rescaledTime		//will ask for a name
			
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
Function V_EC_ImportWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:VSANS:Event:

			NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
			SVAR dispStr = root:Packages:NIST:VSANS:Event:gEventDisplayString
			String tmpStr="",fileStr,filePathStr
			
			// load in the waves, saved as Igor text to preserve the data type
			LoadWave/T/O/P=catPathName
			filePathStr = S_fileName
			if(strlen(S_fileName) == 0)
				//user cancelled
				DoAlert 0,"No file selected, nothing done."
				return(0)
			endif
			
			NVAR mode = root:Packages:NIST:VSANS:Event:gEvent_Mode				// ==0 for "stream", ==1 for Oscillatory
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


Function V_EC_ShowAllButtonProc(ba) : ButtonControl
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

Function V_EC_HelpButtonProc(ba) : ButtonControl
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

Function V_EC_DoneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K V_EventCorrectionPanel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//upDown 5 or -5 looks for spikes +5 or -5 std deviations from mean
Function V_PutCursorsAtStep(upDown)
	Variable upDown
	
	SetDataFolder root:Packages:NIST:VSANS:Event:

	Wave rescaledTime=rescaledTime
	Wave rescaledTime_DIF=rescaledTime_DIF
	Variable avg,pt,zoom
	
	zoom = 200		//points in each direction
	
	WaveStats/M=1/Q rescaledTime_DIF
	avg = V_avg
		
	FindLevel/P/Q rescaledTime_DIF avg*upDown
	if(V_flag==0)
		pt = V_levelX
		WaveStats/Q/R=[pt-zoom,pt+zoom] rescaledTime		// find the max/min y-vallues within the point range
	else
		Print "Level not found"
		return(0)
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
Function V_fFindOutlier()

	SetDataFolder root:Packages:NIST:VSANS:Event:

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

Function V_EC_FindStepButton_down(ctrlName) : ButtonControl
	String ctrlName
	
//	Variable upDown = -5
	NVAR upDown = root:Packages:NIST:VSANS:Event:gStepTolerance
	
	V_PutCursorsAtStep(-1*upDown)

	return(0)
end


Function V_EC_FindStepButton_up(ctrlName) : ButtonControl
	String ctrlName
	
//	Variable upDown = 5
	NVAR upDown = root:Packages:NIST:VSANS:Event:gStepTolerance

	V_PutCursorsAtStep(upDown)

	return(0)
end

// if the Trim button section is uncommented, it's "Zap outlier"
//
Function V_EC_FindOutlierButton(ctrlName) : ButtonControl
	String ctrlName
	
	V_fFindOutlier()
//
//	STRUCT WMButtonAction ba
//	ba.eventCode = 2
//
//	EC_TrimPointsButtonProc(ba)

	return(0)
end

Function V_EC_DoDifferential(ctrlName) : ButtonControl
	String ctrlName
	
	V_DifferentiatedTime()
	DoWindow/F V_EventCorrectionPanel
	
	//if trace is not on graph, add it
	SetDataFolder root:Packages:NIST:VSANS:Event:

	String list = WaveList("*_DIF", ";", "WIN:V_EventCorrectionPanel")
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
Proc V_Show_CustomBinPanel()
	DoWindow/F V_CustomBinPanel
	if(V_flag ==0)
		V_Init_CustomBins()
		V_CustomBinPanel()
	EndIf
End


Function V_Init_CustomBins()

	NVAR nSlice = root:Packages:NIST:VSANS:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest

	Variable/G root:Packages:NIST:VSANS:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	SetDataFolder root:Packages:NIST:VSANS:Event:
		
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
Proc V_CustomBinPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(130,44,851,455)/K=2 /N=V_CustomBinPanel
	DoWindow/C V_CustomBinPanel
	ModifyPanel fixedSize=1//,noEdit =1
	SetDrawLayer UserBack
	
	Button button0,pos={654,42}, size={50,20},title="Done",fSize=12
	Button button0,proc=V_CB_Done_Proc
	Button button1,pos={663,14},size={40,20},proc=V_CB_HelpButtonProc,title="?"
	Button button2,pos={216,42},size={80,20},title="Update",proc=V_CB_UpdateWavesButton	
	SetVariable setvar1,pos={23,13},size={160,20},title="Number of slices",fSize=12
	SetVariable setvar1,proc=CB_NumSlicesSetVarProc,value=root:Packages:NIST:VSANS:Event:gEvent_nslices
	SetVariable setvar2,pos={24,44},size={160,20},title="Max Time (s)",fSize=10
	SetVariable setvar2,value=root:Packages:NIST:VSANS:Event:gEvent_t_longest	

	CheckBox chkbox1,pos={216,14},title="Enforce Max Time?"
	CheckBox chkbox1,variable = root:Packages:NIST:VSANS:Event:gEvent_ForceTmaxBin
	Button button3,pos={500,14},size={90,20},proc=V_CB_SaveBinsButtonProc,title="Save Bins"
	Button button4,pos={500,42},size={100,20},proc=V_CB_ImportBinsButtonProc,title="Import Bins"	
		
	SetDataFolder root:Packages:NIST:VSANS:Event:

	Display/W=(291,86,706,395)/HOST=V_CustomBinPanel/N=BarGraph binCount vs binEndTime
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
	Edit/W=(13,87,280,394)/HOST=V_CustomBinPanel/N=T0
	AppendToTable/W=V_CustomBinPanel#T0 timeWidth,binEndTime
	ModifyTable width(Point)=40
	SetActiveSubwindow ##
	
	SetDataFolder root:
	
EndMacro

// save the bins - use Igor Text format
//
Function V_CB_SaveBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			SetDataFolder root:Packages:NIST:VSANS:Event:

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
Function V_CB_ImportBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:VSANS:Event:gEvent_nslices

			SetDataFolder root:Packages:NIST:VSANS:Event:

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
Function V_CB_UpdateWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:VSANS:Event:gEvent_nslices
			NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
			NVAR enforceTmax = root:Packages:NIST:VSANS:Event:gEvent_ForceTmaxBin
			
			// update the waves, and recalculate everything for the display
			SetDataFolder root:Packages:NIST:VSANS:Event:

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
				ModifyTable/W=V_CustomBinPanel#T0 style(timeWidth)=1,rgb(timeWidth)=(65535,0,0)			
			else
				ModifyTable/W=V_CustomBinPanel#T0 style(timeWidth)=0,rgb(timeWidth)=(0,0,0)			
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End

Function V_CB_HelpButtonProc(ba) : ButtonControl
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

Function V_CB_Done_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K V_CustomBinPanel
			break
	endswitch
	return(0)
End


Function V_CB_NumSlicesSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			SetDataFolder root:Packages:NIST:VSANS:Event:

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

Proc V_SplitBigFile(splitSize, baseStr)
	Variable splitSize = 100
	String baseStr="split"
	Prompt splitSize,"Target file size, in MB"
	Prompt baseStr,"File prefix, number will be appended"
	
	
	V_fSplitBigFile(splitSize, baseStr)
	
	V_ShowSplitFileTable()
End

Function/S V_fSplitBigFile(splitSize, baseStr)
	Variable splitSize
	String baseStr		


	String fileName=""		// File name, partial path, full path or "" for dialog.
	Variable refNum
	String str
	SVAR listStr = root:Packages:NIST:VSANS:Event:gSplitFileList
	
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
		outStr = (thePath+baseStr+num2str(ii))
//		Print "outStr = ",outStr
		Open outRef as outStr

		for(jj=0;jj<(splitSize/readSize);jj+=1)
			FBinRead refNum,aBlob
			FBinWrite outRef,aBlob
		endfor

		Close outRef
//		listStr += outStr+";"
		listStr += baseStr+num2str(ii)+";"
	endfor

	Make/O/B/U/N=(frac) leftover
	// ii was already incremented past the loop
	outStr = (thePath+baseStr+num2str(ii))
	Open outRef as outStr
	for(jj=0;jj<num;jj+=1)
		FBinRead refNum,aBlob
		FBinWrite outRef,aBlob
	endfor
	FBinRead refNum,leftover
	FBinWrite outRef,leftover

	Close outRef
//	listStr += outStr+";"
	listStr += baseStr+num2str(ii)+";"

	FSetPos refNum,V_logEOF
	Close refNum
	
	KillWaves/Z aBlob,leftover
	return(listStr)
End

//// allows the list of loaded files to be edited
//Function ShowSplitFileTable()
//
//	SVAR str = root:Packages:NIST:VSANS:Event:gSplitFileList
//	
//	WAVE/T/Z tw = root:Packages:NIST:VSANS:Event:SplitFileWave
//	if(waveExists(tw) != 1)	
//		Make/O/T/N=1 root:Packages:NIST:VSANS:Event:SplitFileWave
//		WAVE/T/Z tw = root:Packages:NIST:VSANS:Event:SplitFileWave
//	endif
//
//	List2TextWave(str,tw)
//	Edit tw
//
//	return(0)
//End


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
Function V_AccumulateSlicesButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable mode
	mode = str2num(ctrlName[strlen(ctrlName)-1])
//	Print "mode=",mode
	V_AccumulateSlices(mode)
	
	return(0)
End

Function V_AccumulateSlices(mode)
	Variable mode
	
	SetDataFolder root:Packages:NIST:VSANS:Event:

	switch(mode)	
		case 0:
			DoAlert 0,"The current data has been copied to the accumulated set. You are now ready to add more data."
			KillWaves/Z accumulatedData
			Duplicate/O slicedData accumulatedData		
			break
		case 1:
			DoAlert 0,"The current data has been added to the accumulated data. You can add more data."
			Wave acc=accumulatedData
			Wave cur=slicedData
			acc += cur
			break
		case 2:
			DoAlert 0,"The accumulated data is now the display data and is ready for display or export."
			Duplicate/O accumulatedData slicedData
			// do something to "touch" the display to force it to update
			NVAR gLog = root:Packages:NIST:VSANS:Event:gEvent_logint
			V_LogIntEvent_Proc("",gLog)
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
//	SetVariable setvar0,limits={1,inf,1},value= root:Packages:NIST:VSANS:Event:gDecimation
//	Button button1,pos={26,245},size={150,20},proc=LoadDecimateButtonProc,title="Load and Decimate"
//	Button button2,pos={25,277},size={150,20},proc=ConcatenateButtonProc,title="Concatenate"
//	Button button3,pos={25,305},size={150,20},proc=DisplayConcatenatedButtonProc,title="Display Concatenated"
//	Button button4,pos={29,52},size={130,20},proc=Stream_LoadDecim,title="Load From List"
//	
//	GroupBox group0 title="Manual Controls",size={185,112},pos={14,220}
//EndMacro


Function V_SplitFileButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "V_SplitBigFile()"
End


// show all of the data
//
Proc V_ShowDecimatedGraph()

	DoWindow/F V_DecimatedGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:VSANS:Event:
		Display /W=(25,44,486,356)/K=1/N=V_DecimatedGraph rescaledTime_dec
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
Function V_ConcatenateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoAlert 1,"Is this the first file?"
	Variable first = V_flag
	
	V_fConcatenateButton(first)
	
	return(0)
End

Function V_fConcatenateButton(first)
	Variable first


	SetDataFolder root:Packages:NIST:VSANS:Event:

	Wave timePt_dTmp=timePt_dTmp
	Wave xLoc_dTmp=xLoc_dTmp
	Wave yLoc_dTmp=yLoc_dTmp
	Wave rescaledTime_dTmp=rescaledTime_dTmp
	
	NVAR t_longest_dec = root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	
	
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

Function V_DisplayConcatenatedButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//copy the files over to the display set for processing
	SetDataFolder root:Packages:NIST:VSANS:Event:

	Wave timePt_dec=timePt_dec
	Wave xLoc_dec=xLoc_dec
	Wave yLoc_dec=yLoc_dec
	Wave rescaledTime_dec=rescaledTime_dec
		
	NVAR t_longest_dec = root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
	
	Duplicate/O timePt_dec timePt
	Duplicate/O xLoc_dec xLoc
	Duplicate/O yLoc_dec yLoc
	Duplicate/O rescaledTime_dec rescaledTime
	
	t_longest = t_longest_dec	
	
	SetDataFolder root:
	
	return(0)

End



// unused, old testing procedure
Function V_LoadDecimateButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_LoadEventLog_Button("")
	
	// now decimate
	SetDataFolder root:Packages:NIST:VSANS:Event:

	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	NVAR t_longest_dec = root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated

	NVAR decimation = root:Packages:NIST:VSANS:Event:gDecimation


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







////
//// loads a list of files, decimating each chunk as it is read in
////
//Function Stream_LoadDecim(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:VSANS:Event:gEvent_logfile
//	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
//
//	SVAR listStr = root:Packages:NIST:VSANS:Event:gSplitFileList
//	NVAR t_longest_dec = root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated
//	NVAR decimation = root:Packages:NIST:VSANS:Event:gDecimation
//
//	String pathStr
//	PathInfo catPathName
//	pathStr = S_Path
//
//// if "stream" mode is not checked - abort
//	NVAR gEventModeRadioVal= root:Packages:NIST:VSANS:Event:gEvent_mode
//	if(gEventModeRadioVal != MODE_STREAM)
//		Abort "The mode must be 'Stream' to use this function"
//		return(0)
//	endif
//
//// if the list has been edited, turn it into a list
//	WAVE/T/Z tw = root:Packages:NIST:VSANS:Event:SplitFileWave
//	if(WaveExists(tw))
//		listStr = TextWave2SemiList(tw)
//	else
//		ShowSplitFileTable()
//		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
//		return(0)
//	endif
//	
//
//	//loop through everything in the list
//	Variable num,ii
//	num = ItemsInList(listStr)
//	
//	for(ii=0;ii<num;ii+=1)
//
//// (1) load the file, prepending the path		
//		filename = pathStr + StringFromList(ii, listStr  ,";")
//		
//
//#if (exists("EventLoadWave")==4)
//		LoadEvents_XOP()
//#else
//		LoadEvents()
//#endif	
//
//		SetDataFolder root:Packages:NIST:VSANS:Event:			//LoadEvents sets back to root:
//
//		Wave timePt=timePt
//		Wave xLoc=xLoc
//		Wave yLoc=yLoc
//		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//
//		Duplicate/O timePt rescaledTime
//		rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
//		t_longest = waveMax(rescaledTime)		//should be the last point
//		
//// (2) do the decimation, just on timePt. create rescaledTime from the decimated timePt	
//		
//		Duplicate/O timePt, timePt_dTmp
//		Duplicate/O xLoc, xLoc_dTmp
//		Duplicate/O yLoc, yLoc_dTmp
//		Resample/DOWN=(decimation)/N=1 timePt_dTmp
//		Resample/DOWN=(decimation)/N=1 xLoc_dTmp
//		Resample/DOWN=(decimation)/N=1 yLoc_dTmp
//	
//	
//		Duplicate/O timePt_dTmp rescaledTime_dTmp
//		rescaledTime_dTmp = 1e-7*(timePt_dTmp - timePt_dTmp[0])		//convert to seconds and start from zero
//		t_longest_dec = waveMax(rescaledTime_dTmp)		//should be the last point
//		
//
//// (3) concatenate
//		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
//	
//	endfor
//
//////		Now that everything is decimated and concatenated, create the rescaled time wave
////	SetDataFolder root:Packages:NIST:VSANS:Event:			//LoadEvents sets back to root:
////	Wave timePt_dec = timePt_dec
////	Duplicate/O timePt_dec rescaledTime_dec
////	rescaledTime_dec = 1e-7*(timePt_dec - timePt_dec[0])		//convert to seconds and start from zero
////	t_longest_dec = waveMax(rescaledTime_dec)		//should be the last point
//	
//	DisplayConcatenatedButtonProc("")
//	
//	SetDataFolder root:
//
//	return(0)
//End
//
//Function ShowList_ToLoad(ctrlName)
//	String ctrlName
//	
//	ShowSplitFileTable()
//	
//	return(0)
//End


////
//// loads a list of files that have been adjusted and saved
//// -- does not decimate
////
//Function Stream_LoadAdjustedList(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:VSANS:Event:gEvent_logfile
//	NVAR t_longest = root:Packages:NIST:VSANS:Event:gEvent_t_longest
//
//	SVAR listStr = root:Packages:NIST:VSANS:Event:gSplitFileList
//	NVAR t_longest_dec = root:Packages:NIST:VSANS:Event:gEvent_t_longest_decimated
////	NVAR decimation = root:Packages:NIST:VSANS:Event:gDecimation
//
//	String pathStr
//	PathInfo catPathName
//	pathStr = S_Path
//
//// if "stream" mode is not checked - abort
//	NVAR gEventModeRadioVal= root:Packages:NIST:VSANS:Event:gEvent_mode
//	if(gEventModeRadioVal != MODE_STREAM)
//		Abort "The mode must be 'Stream' to use this function"
//		return(0)
//	endif
//
//// if the list has been edited, turn it into a list
//	WAVE/T/Z tw = root:Packages:NIST:VSANS:Event:SplitFileWave
//	if(WaveExists(tw))
//		listStr = TextWave2SemiList(tw)
//	else
//		ShowSplitFileTable()
//		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
//		return(0)
//	endif
//	
//
//	//loop through everything in the list
//	Variable num,ii
//	num = ItemsInList(listStr)
//	
//	for(ii=0;ii<num;ii+=1)
//
//// (1) load the file, prepending the path		
//		filename = pathStr + StringFromList(ii, listStr  ,";")
//		
//		SetDataFolder root:Packages:NIST:VSANS:Event:
//		LoadWave/T/O fileName
//
//		SetDataFolder root:Packages:NIST:VSANS:Event:			//LoadEvents sets back to root: ??
//
//// this is what is loaded -- _dec extension is what is concatenated, and will be copied back later
//		Wave timePt=timePt
//		Wave xLoc=xLoc
//		Wave yLoc=yLoc
//		Wave rescaledTime=rescaledTime
//
////		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//
////		Duplicate/O timePt rescaledTime
////		rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
////		t_longest = waveMax(rescaledTime)		//should be the last point
//		
//// (2) No decimation
//		
//		Duplicate/O timePt, timePt_dTmp
//		Duplicate/O xLoc, xLoc_dTmp
//		Duplicate/O yLoc, yLoc_dTmp
//		Duplicate/O rescaledTime, rescaledTime_dTmp
//
//
//// (3) concatenate
//		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
//	
//	endfor
//	
//	DisplayConcatenatedButtonProc("")		// this resets the longest time, too
//		
//	SetDataFolder root:
//
//	return(0)
//End
//
///////////////////////////////////////
//
//// dd-mon-yyyy hh:mm:ss -> Event file name
//// the VAX uses 24 hr time for hh
////
//// scans as string elements since I'm reconstructing a string name
//Function/S DateAndTime2HSTName(dateandtime)
//	string dateAndTime
//	
//	String day,yr,hh,mm,ss,time_secs
//	Variable mon
//	string str,monStr,fileStr
//	
//	str=dateandtime
//	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
//	mon = monStr2num(monStr)
//
//	fileStr = "Event"+yr+num2str(mon)+day+hh+mm+ss+".hst"
//	Print fileStr
//
//	return(fileStr)
//end
//
//// dd-mon-yyyy hh:mm:ss -> Event file name
//// the VAX uses 24 hr time for hh
////
//// scans as string elements since I'm reconstructing a string name
//Function DateAndTime2HSTNumber(dateandtime)
//	string dateAndTime
//	
//	String day,yr,hh,mm,ss,time_secs
//	Variable mon,num
//	string str,monStr,fileStr
//	
//	str=dateandtime
//	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
//	mon = monStr2num(monStr)
//
//	fileStr = yr+num2str(mon)+day+hh+mm+ss
//	num = str2num(fileStr)
//
//	return(num)
//end
//
//Function HSTName2Num(str)
//	String str
//	
//	Variable num
//	sscanf str,"Event%d.hst",num
//	return(num)
//end
///////////////////////////////