#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//#include "TISANE"


// TODO:
//
// -- fix the log/lin display - it's not working correctly
// -- add controls to show the bar graph
// x- add popup for selecting the binning type
// x- add ability to save the slices to RAW VAX files
// -- add control to show the bin counts and bin end times
// x- ADD buttons, switches, etc for the oscillatory mode - so that this can be accessed
//
// x- How are the headers filled for the VAX files from Teabag???
// -- I currently read the events 2x. Once to count the events to make the waves the proper
//     size, then a second time to actualy process the events. Would it be faster to insert points
//     as needed, or to estimate the size, and make it too large, then trim at the end...
// ((( NO -- deleting the extra zeros at the end is WAY WAY slower - turns 2sec into 100 sec)))
//
//
//
// -- for the 19 MB file - the max time is reported as 67.108s, but the max rescaled time = 61 s
//    based on the last point... there are "spikes" in the time! -- look at the plot in the
//    data browser... (so waveMax() gives a different answer than the end point, and BinarySearch()
//    doesn't have a monotonic file to work with... ugh.)
//
//
//
// differentiate may be useful at some point, but not sure
//¥Differentiate rescaledTime/D=rescaledTime_DIF
//¥Display rescaledTime,rescaledTime_DIF
//
//



Macro Show_Event_Panel()
	DoWindow/F EventModePanel
	if(V_flag ==0)
		Init_Event()
		EventModePanel()
	EndIf
End


Function Init_Event()
	String/G 	root:Packages:NIST:gEvent_logfile
	Variable/G 	root:Packages:NIST:AIMTYPE_XY=0 // XY Event
	Variable/G 	root:Packages:NIST:AIMTYPE_XYM=2 // XY Minor event
	Variable/G 	root:Packages:NIST:AIMTYPE_MIR=1 // Minor rollover event
	Variable/G 	root:Packages:NIST:AIMTYPE_MAR=3 // Major rollover event

	Variable/G root:Packages:NIST:gEvent_time_msw = 0
	Variable/G root:Packages:NIST:gEvent_time_lsw = 0
	Variable/G root:Packages:NIST:gEvent_t_longest = 0

	Variable/G root:Packages:NIST:gEvent_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:gEvent_nslices = 10  //Number of time slices
	Variable/G root:Packages:NIST:gEvent_slicewidth  = 1000 // slice width (us)
	
	Variable/G root:Packages:NIST:gEvent_prescan // Do we prescan the file?
	Variable/G root:Packages:NIST:gEvent_logint = 1

	Variable/G root:Packages:NIST:gEvent_Mode = 1		// ==0 for "stream", ==1 for Oscillatory

	NVAR nslices = root:Packages:NIST:gEvent_nslices
	
	SetDataFolder root:
	NewDataFolder/O/S root:Packages:NIST:Event
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData
	
	SetDataFolder root:
End

Proc EventModePanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=2 /W=(100,50,600,680)/N=EventModePanel
	DoWindow/C EventModePanel
	ModifyPanel fixedSize=1,noEdit =1
	//ShowTools/A
	SetDrawLayer UserBack
	Button button0,pos = {10,10}, size={150,20},title="Load Event Log File",fSize=12
	Button button0,proc=LoadEventLog_Button
	SetVariable setvar3,pos= {20,590},size={460,20},title=" ",fSize=12
	SetVariable setvar3,disable=2,variable=root:Packages:NIST:gEvent_logfile
	CheckBox chkbox1,pos={170,15},title="Oscillatory Mode?"
	CheckBox chkbox1,variable = root:Packages:NIST:gEvent_mode
	Button doneButton,pos={400,10}, size={50,20},title="Done",fSize=12
	Button doneButton,proc=EventDone_Proc
	
	//DrawLine 10,35,490,35
	Button button1,pos = {10,50}, size={150,20},title="Process Data",fSize=12
	Button button1,proc=ProcessEventLog_Button
	SetVariable setvar1,pos={170,50},size={160,20},title="Number of slices",fSize=12
	SetVariable setvar1,value=root:Packages:NIST:gEvent_nslices
	SetVariable setvar2,pos={330,50},size={160,20},title="Max Time (s)",fSize=12
	SetVariable setvar2,value=root:Packages:NIST:gEvent_t_longest
	//DrawLine 10,65,490,65
	
//	PopupMenu popup0 title="Bin Spacing",pos={150,90},value="Equal;Fibonacci;Log;"
	PopupMenu popup0 title="Bin Spacing",pos={150,90},value="Equal;Fibonacci;"
	
	CheckBox chkbox2,pos={20,95},title="Log Intensity",value=1
	CheckBox chkbox2,variable=root:Packages:NIST:gEvent_logint,proc=LogIntEvent_Proc
	SetVariable setvar0,pos={320,90},size={160,20},title="Display Time Slice",fSize=12
	SetVariable setvar0,value= root:Packages:NIST:gEvent_tsdisp
	SetVariable setvar0,proc=sliceSelectEvent_Proc
	Display/W=(20,120,480,580)/HOST=EventModePanel/N=Event_slicegraph
	AppendImage/W=EventModePanel#Event_slicegraph/T root:Packages:NIST:Event:dispsliceData
	ModifyImage/W=EventModePanel#Event_slicegraph  ''#0 ctab= {*,*,Grays,0}
	ModifyImage/W=EventModePanel#Event_slicegraph ''#0 ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A left
	SetActiveSubwindow ##
EndMacro

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
	
	NVAR mode=root:Packages:NIST:gEvent_Mode
	
	if(mode == 0)
		Stream_ProcessEventLog("")
	endif
	
	if(mode == 1)
		Osc_ProcessEventLog("")
	endif
	
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

	SetDataFolder root:Packages:NIST:Event
	IndexForHistogram(xLoc,yLoc,binnedData)
	SetDataFolder root:
	Wave index = root:Packages:NIST:Event:SavedIndex
	
	JointHistogram(xLoc,yLoc,binnedData,index)		// puts everything into one array


// now with the number of slices and max time, process the events
	Osc_ProcessEvents(xLoc,yLoc,index)


	SetDataFolder root:Packages:NIST:Event:

	SetDataFolder root:

	return(0)
End


Function Stream_ProcessEventLog(ctrlName)
	String ctrlName

//	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth

	
	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

	SetDataFolder root:Packages:NIST:Event
	IndexForHistogram(xLoc,yLoc,binnedData)
	SetDataFolder root:
	Wave index = root:Packages:NIST:Event:SavedIndex
	
	JointHistogram(xLoc,yLoc,binnedData,index)		// puts everything into one array


// now with the number of slices and max time, process the events
	Stream_ProcessEvents(xLoc,yLoc,index)


	SetDataFolder root:Packages:NIST:Event:

	SetDataFolder root:

	return(0)
End


Macro	UndoTheSorting()
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

// for oscillatory mode
//
//// use indexSort to be able to restore the original data
//¥Duplicate rescaledTime OscSortIndex
//¥MakeIndex rescaledTime OscSortIndex
//¥IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime
//¥Sort OscSortIndex OscSortIndex,yLoc,xLoc,timePt,rescaledTime
//
// sort the data by time, then do the binning
// save an index to be able to "undo" the sorting
//
Function Osc_ProcessEvents(xLoc,yLoc,index)
	Wave xLoc,yLoc,index
	
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount
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
			SetLinearBins(binEndTime,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,nslices,t_longest)
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,nslices,t_longest)
	endswitch


// now before binning, sort the data

	//this is slow - undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	SetDataFolder root:Packages:NIST:Event:

	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
	Endif
	
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
		Print p1,p2


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


// for the mode of "one continuous exposure"
//
Function Stream_ProcessEvents(xLoc,yLoc,index)
	Wave xLoc,yLoc,index
	
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount//,binStartTime
	Wave binEndTime = binEndTime
//	Wave binStartTime = binStartTime
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
			SetLinearBins(binEndTime,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,nslices,t_longest)
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,nslices,t_longest)
	endswitch
	
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
		Print p1,p2


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

Function SetLinearBins(binEndTime,nslices,t_longest)
	Wave binEndTime
	Variable nslices,t_longest

	Variable del,ii,t2
	binEndTime[0]=0		//so the bar graph plots right...
	del = t_longest/nslices
	
	for(ii=0;ii<nslices;ii+=1)
		t2 = (ii+1)*del
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest*(1-1e-6)		//otherwise floating point errors such that the last time point is off the end of the Binary search

	return(0)	
End


Function SetLogBins(binEndTime,nslices,t_longest)
	Wave binEndTime
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

Function SetFibonacciBins(binEndTime,nslices,t_longest)
	Wave binEndTime
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
	
	return(0)
End




Function LoadEventLog_Button(ctrlName) : ButtonControl
	String ctrlName

	NVAR mode=root:Packages:NIST:gEvent_mode
	
	if(mode == 0)
		Stream_LoadEventLog("")
	endif
	
	if(mode == 1)
		Osc_LoadEventLog("")
	endif
	
	return(0)
End

// for the mode of "one continuous exposure"
//
Function Stream_LoadEventLog(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:gEvent_logfile
	NVAR prescan = root:Packages:NIST:gEvent_prescan
//	NVAR slicewidth = root:Packages:NIST:gEvent_slicewidth
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	
	Open/R/D/F=fileFilters fileref
	filename = S_filename
	
	LoadEvents()
	
	SetDataFolder root:Packages:NIST:Event:

tic()
	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
	
toc()

	Duplicate/O timePt rescaledTime
	rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
	t_longest = waveMax(rescaledTime)		//should be the last point

	SetDataFolder root:

	return(0)
End

// for the mode "oscillatory"
//
Function Osc_LoadEventLog(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:gEvent_logfile
	NVAR prescan = root:Packages:NIST:gEvent_prescan
//	NVAR slicewidth = root:Packages:NIST:gEvent_slicewidth
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	
	Open/R/D/F=fileFilters fileref
	filename = S_filename
	
	LoadEvents()
	
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
	
	Duplicate/O timePt rescaledTime
	rescaledTime *= 1e-7			//convert to seconds and that's all
	t_longest = waveMax(rescaledTime)		//won't be the last point, so get it this way

	KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around

	SetDataFolder root:

	return(0)
End



Function CleanupTimes(xLoc,yLoc,timePt)
	Wave xLoc,yLoc,timePt

	// start at the back and remove zeros
	Variable num=numpnts(xLoc),ii
	
	ii=num
	do
		ii -= 1
		if(timePt[ii] == 0 && xLoc[ii] == 0 && yLoc[ii] == 0)
			DeletePoints ii, 1, xLoc,yLoc,timePt
		endif
	while(timePt[ii-1] == 0 && xLoc[ii-1] == 0 && yLoc[ii-1] == 0)
	
	return(0)
End

Function LogIntEvent_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:Event
	if(checked)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	SetDataFolder root:
End




Function sliceSelectEvent_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR selectedslice = root:Packages:NIST:gEvent_tsdisp
	
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


//
Function LoadEvents()
	
	NVAR time_msw = root:Packages:NIST:gEvent_time_msw
	NVAR time_lsw = root:Packages:NIST:gEvent_time_lsw
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:gEvent_logfile
	SetDataFolder root:Packages:NIST:Event

	Variable fileref
	String buffer
	Variable dataval,timeval,type,numLines,verbose,verbose3
	Variable xval,yval,rollBit,nRoll,roll_time
	Variable Xmax, yMax
	xMax = 127		// number the detector from 0->127 
	yMax = 127
	
	verbose3 = 1
	verbose = 0
	numLines = 0

// this gets me the number of lines. not terribly useful	
//	Open/R fileref as filepathstr
//	do
//		numLines += 1
//		FReadLine fileref, buffer
//		if (strlen(buffer) == 0)
//			numLines -= 1			//last FReadLine wasn't really a line
//			break
//		endif
//	while(1)
//	Close fileref
	
	// what I really need is the number of XY events
	Variable numXYevents,num1,num2,num3,num0,totBytes
	numXYevents = 0
	num0 = 0
	num1 = 0
	num2 = 0
	num3 = 0

//tic()
	Open/R fileref as filepathstr
		FStatus fileref
	Close fileref

	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	
//toc()
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
		
	while(1)
	Close fileref
//		done counting the number of XY events

	toc()
//
//	
	Printf "numXYevents = %d\r",numXYevents
	Printf "XY = num0 = %d\r",num0
	Printf "XY time = num2 = %d\r",num2
	Printf "time MSW = num1 = %d\r",num1
	Printf "Rollover = num3 = %d\r",num3

	Printf "num0 + num2 = %d\r",num0+num2
	
	Make/O/U/N=(numXYevents) xLoc,yLoc
	Make/O/D/N=(numXYevents) timePt
//	Make/O/U/N=(totBytes/4) xLoc,yLoc		//too large, trim when done (bad idea)
//	Make/O/D/N=(totBytes/4) timePt
	xLoc=0
	yLoc=0
	timePt=0

	
	Variable ii=0
	nRoll = 0		//number of rollover events
	roll_time = 2^26		//units of 10-7 sec
	
	time_msw=0
	
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
		
		//
		//Constant ATXY = 0
		//Constant ATXYM = 2
		//Constant ATMIR = 1
		//Constant ATMAR = 3
		//
//		type = (dataval & ~(2^32 - 2^30 -1))/2^30

		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
		
//		
		switch(type)
			case ATXY:
				if(verbose)		
					printf "XY : "		
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
				xLoc[ii] = xval
				yLoc[ii] = yval
				timePt[ii] = timeval

				if(verbose)		
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif				

//				b = FindBin(timeval,nslices)
//				slicedData[xval][yval][b] += 1

				ii+=1
				
//				verbose = 0
				break
			case ATXYM:
				if(verbose)
					printf "XYM : "
				endif
//				xval = ~(dataval & ~(2^32 - 2^8)) & 127
//				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
//				time_lsw =  (dataval & ~(2^32 - 2^29 ))/2^16

				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8

				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16

				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif
				
				xLoc[ii] = xval
				yLoc[ii] = yval
				
				// don't fill in the time yet, or increment the index ii
				// the next event MUST be ATMIR with the MSW time bits
				//
//				verbose = 0
				break
			case ATMIR:
				if(verbose)
					printf "MIR : "
				endif
//				time_msw =  (dataval & ~(2^32 - 2^29 ))/2^16
				time_msw =  (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
				timeval = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw )
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval,t_longest
				endif
				
				// the XY position was in the previous event ATXYM
				timePt[ii] = timeval
				
				ii+=1
				
//				b = FindBin(timeval,nslices)
//				slicedData[xval][yval][b] += 1

//				verbose = 0
				break
			case ATMAR:
				if(verbose3)
//					verbose = 1
					printf "MAR : "
				endif
				
				// do something with the rollover event?
				
				// check bit 29
				rollBit = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				nRoll += 1
				
				if(verbose3)
					printf "%u : %u : %u \r",dataval,rollBit,nRoll
				endif
				
				break
		endswitch
				
	while(1)
	
	
	Close fileref
	
	toc()
	
	SetDataFolder root:
	
	return(0)
	
End 

///

Macro BinEventBarGraph()
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:Event:
	Display /W=(110,705,610,1132)/K=1 binCount vs binEndTime
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
//	ModifyGraph log=1
	ModifyGraph standoff=0
//	SetAxis left 0.1,4189
//	SetAxis bottom 0.0001,180.84853
End

Macro ShowBinTable() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:Event:
	Edit/W=(498,699,1003,955) /K=1 binCount,binEndTime
	ModifyTable format(Point)=1,sigDigits(binEndTime)=16,width(binEndTime)=218
	SetDataFolder fldrSav0
EndMacro


// only show the first 1500 data points
//
Macro ShowRescaledTimeGraph() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:Event:
	Display /W=(25,44,486,356)/K=1 rescaledTime
	SetDataFolder fldrSav0
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph rgb(rescaledTime)=(0,0,0)
	ModifyGraph msize=2
	SetAxis/A=2 left			//only autoscale the visible data (based on the bottom limits)
	SetAxis bottom 0,1500
	ErrorBars rescaledTime OFF 
	ShowInfo
EndMacro



Macro ExportSlicesAsVAX(firstNum,prefix)
	Variable firstNum=1
	String prefix="SAMPL"

	SaveSlicesAsVAX(firstNum,prefix[0,4])		//make sure that the prefix is 5 chars
End

//////// procedures to be able to export the slices as RAW VAX files.

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
	
	NVAR nslices = root:Packages:NIST:gEvent_nslices
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
		binFraction = (binEndTime[ii+1]-binEndTime[ii])/(binEndTime[nslices]-binEndTime[0])
		
		iw[2] = trunc(binFraction*iw_raw[2])
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

//
// Now see if this can be succesfully applied to the timeslicing data sets
// -- talk to Jeff about what he's gotten implemented, and what's still missing
// - both in timeslicing, and in TISANE
// - un-scale the wave? or make it work as 128x128

Function Setup_JointHistogram()

//	tic()

	make/D /o/n=1000000 data1=gnoise(1), data2=gnoise(1)
	make/D /o/n=(25,25) myHist
	setscale x,-3,3,myHist
	setscale y,-3,3,myHist
	IndexForHistogram(data1,data2,myhist)
	Wave index=SavedIndex
	JointHistogram(data1,data2,myHist,index)
	NewImage myHist
	
//	toc()
	
End


Function JointHistogram(w0,w1,hist,index)
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


// need a way of visualizing the bin spacing / number of bins vs the full time of the data collection
// then set the range of the source to send to the joint histogram operation
// to assign to arrays (or a 3D wave)
//
// -- see my model with the "layered" form factor - or whatever I called it. That shows different
// binning and visualizing as bar graphs.
//
// -- just need to send x2pnt or findLevel, or something similar to define the POINT
// values
//
// can also speed this up since the index only needs to be done once, so the
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




///////
//// @ IgorExchange
////TicToc
////Posted April 16th, 2009 by bgallarda
////	¥	in Programming 6.10.x
//	
//function tic()
//	variable/G tictoc = startMSTimer
//end
// 
//function toc()
//	NVAR/Z tictoc
//	variable ttTime = stopMSTimer(tictoc)
//	printf "%g seconds\r", (ttTime/1e6)
//	killvariables/Z tictoc
//end
//
//
//Function testTicToc()
// 
//	tic()
//	variable i
//	For(i=0;i<10000;i+=1)
//		make/O/N=512 temp = gnoise(2)
//		FFT temp
//	Endfor
//	killwaves/z temp
//	toc()
//End
//
////////////////