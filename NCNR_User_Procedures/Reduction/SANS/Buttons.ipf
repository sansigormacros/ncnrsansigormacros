#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//************
//Vers 1.2 083101
//
// Button procedures for control bar on the SANS_Data graph window
// some additional procedures that are called are in WorkFileUtils
//******************

//toggles the display from linear to log-scale, changing all waves and global
//in the currently displayed folder
Function Log_Lin(ctrlName) : ButtonControl
	String ctrlName
	
	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	Variable err=0
	
	if (cmpstr(ctrlName,"bisLog") == 0)
		//	MakeLinear
		err = ConvertFolderToLinearScale(cur_folder)		//will abort if there is an error
		if( !err )
			//update the button
			Button $ctrlName,title="isLin",rename=bisLin,win=SANS_Data
		Endif
	else
		//make log-scale
		err = ConvertFolderToLogScale(cur_folder)	//checks for negative values, and will abort if there is an error
		if( !err )
			//update the button
			Button $ctrlName,title="isLog",rename=bisLog,win=SANS_Data
		Endif
	endif
	
	//back to root folder (redundant)
	SetDataFolder root:
End

//prints out information about the currently displayed file to the history window
//
Function StatusButton(ctrlName) : ButtonControl
	String ctrlName
	
	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	String cur = "root:Packages:NIST:"+cur_folder
	
	WAVE reals=$(cur + ":realsread")
	WAVE ints = $(cur + ":integersRead")
	WAVE/T text=$(cur + ":textread")
	SVAR fileList = $(cur +":fileList")
	String toPrint
	
	Print "\r***Current file status***"
	Print "FILE(S) : " + fileList
	Print "LABEL:  "+ text[6]
	sprintf toPrint, "Counting time = %g seconds",ints[2]
	Print toPrint
	sprintf toPrint,"Detector counts = %g for %g monitor counts",reals[2],reals[0]
	Print toPrint
	sprintf toPrint,"Trans = %g , thick = %g cm,  Xcenter = %g, Ycenter = %g",reals[4],reals[5],reals[16],reals[17]
	Print toPrint
	sprintf toPrint,"%g attenuators used",reals[3]
	Print toPrint
	
	//back to root folder (redundant)
	SetDataFolder root:
End

/////not used////
// function control a background task of "live" image updating
//
Function UpdateImage(ctrlName) : ButtonControl
	String ctrlName
	
	if (cmpstr(ctrlName,"bStart") == 0)
		Button $ctrlName,title="Stop",rename=bStop
	//	Start the updating - FakeUpdate() has been designated as the background task
		CtrlBackground period=60,start
	else
		Button $ctrlName,title="Start",rename=bStart
	//	Stop the updating 
		CtrlBackground stop
	endif
End

//not used, but useful for real-time display of the detector
//old, and likely not up-to-date with the present data folder structure
Function FakeUpdate()

	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	SetDataFolder "root:Packages:NIST:"+cur_folder		//use the full path, so it will always work
	WAVE data = $"data"
//	WAVE vlegend = $"vlegend"
	
	//alter the raw data
	data = abs(enoise(10))
	
	// adjust the color bar
	WaveStats/Q data
//	SetScale/I y,V_min,V_max,"" vlegend
//	vlegend=y
		
	// assume all is OK, return 0
	// button1 controls the start/stop of the background task
	
	//back to root folder
	SetDataFolder root:
	
	return 0
End

//Updates the color map used for the SANS data based on the values of the slider bars
// checks to see which (name) slider was moved and its value. event is ignored
//
// procedure is attached to the sliders, but is also called to reset the color map
// using MapSliderProc("junk",0,0) to skip to default map values
// MapSliderProc("both",0,0) will produce behavior as if either slider was hit
// but will poll for values
//
// when called by a moving slider, all is OK
// when called manually to force a reset, SANS_Data window must be the target 
Function MapSliderProc(name, value, event)
	String name	// name of this slider control
	Variable value	// value of slider
	Variable event	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	
	WAVE NIHColors = $"root:myGlobals:NIHColors"
	Variable loscale,hiScale,maxData,minData,loRange,hiRange
	
//	DoWindow/F SANS_Data
	if(WinType("SANS_Data")==0)		//check for existence without explicity bringing it to the front
		return(1)		//no data window, don't do anything
	Endif
	
	StrSwitch(name)
		case "loSlide":
			loScale=value
			ControlInfo/W=SANS_Data hiSlide
			hiScale=V_Value
			break
		case "hiSlide":
			hiScale=value
			ControlInfo/W=SANS_Data loSlide
			loScale=V_Value
			break
		case "both":	//poll both of the sliders for their values
			ControlInfo/W=SANS_Data hiSlide
			hiScale=V_Value
			ControlInfo/W=SANS_Data loSlide
			loScale=V_Value
			break
		case "reset":		//reset both of the sliders
			Slider hiSlide,win=SANS_Data,value=1
			hiScale=1
			Slider loSlide,win=SANS_Data,value=0
			loScale=0
			break
		default:
			loScale=0
			hiScale=1
	endswitch
	String result = ImageInfo("SANS_Data","data",0)
	String fullPath = StringByKey("ZWAVEDF", result, ":", ";")
	fullpath += "data"
	//Print fullpath
	WaveStats/Q $fullpath
	maxData=V_max
	minData=V_min
		
	loRange = (maxData-minData)*loScale + minData
	hiRange = (maxData-minData)*hiScale + minData
	
//	Print loRange,hiRange
//	ScaleColorsToData((loScale*maxData),(hiScale*maxData),NIHColors)
	ScaleColorsToData(loRange,hiRange,NIHColors)
	ModifyImage/W=SANS_Data data cindex=NIHColors
			
	return 0	// other return values reserved
End

//button procedure to display previous RAW data file
//incremented by run number, not dependent on file prefix
Function BackOneFileButtonProc(ctrlName) : ButtonControl
	String ctrlName

	LoadPlotAndDisplayRAW(-1)
	
	return(0)
End

//button procedure to display next RAW data file
//incremented by run number, not dependent on file prefix
Function ForwardOneFileButtonProc(ctrlName) : ButtonControl
	String ctrlName

	LoadPlotAndDisplayRAW(1)
	
	return (0)
End

//displays next (or previous) file in series of run numbers
//file is read from disk, if path is set and the file number is present
//increment +1, adds 1 to run number, -1 subtracts one
Function LoadPlotAndDisplayRAW(increment)
	Variable increment

	//take the currently displayed RAW file (there is only one name in fileList)
	SVAR oldName = root:Packages:NIST:RAW:fileList
	
	//get the run number
	Variable num = GetRunNumFromFile(oldName)
	
	//increment
	num += increment
	
	//find the next specified file by number
	String fileName = FindFileFromRunNumber(num)
	if(cmpstr(fileName,"")==0)
		//null return, do nothing
		Return(1)
	Endif
	
	// display the specified RAW data file
	String/G root:myGlobals:gDataDisplayType="RAW"
	ReadHeaderAndData(filename)
	
	//do the average and plot (either the default, or what is on the panel currently
	if(!DataFolderExists("root:myGlobals:Drawing"))
		Execute "InitializeAveragePanel()"
	endif
	Panel_DoAverageButtonProc("")		//the avg panel does not need to be open, folders must exist
	
	//data is displayed here
	fRawWindowHook()
	
	return(0)
End

//toggles the overlay of the current mask file
//no effect if no mask exists
Proc maskButtonProc(ctrlName) : ButtonControl
	String ctrlName
		
	DoWindow/F SANS_Data		 //do nothing if SANS_Data is not displayed, make it target if it is open
	if(V_flag==0)
		return
	endif
	
	CheckDisplayed/W=SANS_Data root:Packages:NIST:MSK:overlay
	if(V_flag==1)		//the overlay is present
		Button $ctrlName,title="Show Mask",win=SANS_Data
		OverlayMask(0)		//hide the mask
	else
		Button $ctrlName,title="Hide Mask",win=SANS_Data
		OverlayMask(1)		//show the mask
	endif
	

End

//I vs. Q button on control bar of SANS_Data window activates this pocedure
//and simply displays the AvgPanel to solicit input
//from the user (graphically) before any averaging is done
//
Proc ShowAvgPanel_SANSData(ctrlName) : ButtonControl
	String ctrlName

	ShowAveragePanel()
End


//invoked by function key, (if menu declared)
// if no window, or if display type is not RAW, do nothing
Function NextRawFile()

	DoWindow/F SANS_Data
	if( V_Flag==0 )
		return 1			//return error, currently ignored
	endif
	SVAR str=root:myGlobals:gDataDisplayType
	if(cmpstr(str,"RAW")!=0)
		return 1
	endif
	
	LoadPlotAndDisplayRAW(1)		//go to next file

	return 0
end

//invoked by function key, (if menu declared)
// if no window, or if display type is not RAW, do nothing
Function PreviousRawFile()

	DoWindow/F SANS_Data
	if( V_Flag==0 )
		return 1			//do nothing and return error, currently ignored
	endif
	SVAR str=root:myGlobals:gDataDisplayType
	if(cmpstr(str,"RAW")!=0)
		return 1
	endif
	
	LoadPlotAndDisplayRAW(-1)		//go to previous file

	return 0
end

//test function invoked by F5
// takes the selected file forom the file catalog
// and displays that file
// if several files are selected, displays ONLY the first one
//
Function LoadSelectedData()

	if(WinType("CatVSTable")==0)
		return(1)
	endif
	GetSelection table,CatVSTable,3
	
	Wave/T fWave = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	String filename=fWave[V_StartRow]
	PathInfo catPathName
	
	// display the specified RAW data file
	String/G root:myGlobals:gDataDisplayType="RAW"
	ReadHeaderAndData(S_Path+filename)
	//data is displayed here
	fRawWindowHook()

	// if you want a plot, too
	//do the average and plot (either the default, or what is on the panel currently
	if(!DataFolderExists("root:myGlobals:Drawing"))
		Execute "InitializeAveragePanel()"
	endif
	Panel_DoAverageButtonProc("")		//the avg panel does not need to be open, folders must exist
	
	return(0)
End
