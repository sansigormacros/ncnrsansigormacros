#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// APRIL 2025--
// no code here is hard-wired for either detector style
//

// MAY 2022
//
// this file has been copied over from VSANS, and modified for SANS(Tubes)and Nexus output/reduction
//
// - the SANS-Tube event file is different than VSANS, but still easy to read and decode
//
// The SANS-Tube event file format is not the same as VSANS. It is 10 bytes per event:
// 1 byte = xPos
// 1 byte = yPos
// 8 bytes = timeStamp
//
// the header is very similar to VSANS, and is well documented.
//

// **** NOTE *****
//
// -- this file is, however NOT specific to the Tube event file format. It works with the
//   Nexus-style data files that are the (sliced) output of the event processing. This file
//   has the routines for Event Mode Reduction -- using the same protocols as the Tube data
//  -- this includes Ordela data that has been "faked" to be tubes.
//  --so this file is correct to be included for both the 10m Tubes and converted Ordela "tubes"
//   (the processing panel + loader is different for 10m Tube/Ordela)
//

//
// There are functions in this file to generate "fake" event data for testing
//
// to generate and save a fake event file, run the two commands:
//
//  MakeFakeEventWave(1e6)
//  writeFakeEventFile("")
//
// currently the code for the fake event files is using 112 tubes as are on the 10m SANS
// and the new 10-byte event word format, and 128 "Tubes" for the Ordela
//
//

//
/////// to copy a sliced data set to a folder to save
//

// load event file from RAW data loaded
// pick the "mode" of loading data (osc, stream, etc.)
// process the event data
// move slices to "export" location
// move bin details to export location
//
// save the data file, giving a new name to not overwrite the original data file
//

Function DuplicateRAWForExport()

	KillDataFolder/Z root:export

	if(DataFolderExists("root:Packages:NIST:RAW:Entry") == 1)
		DuplicateDataFolder root:Packages:NIST:RAW root:export
	else
		DoAlert 0, "No RAW data folder exists. Please load the correct RAW data file and repeat this Duplicate step"
	endif

	return (0)
End

Function CopySlicesForExport()

	Duplicate/O root:Packages:NIST:Event:slicedData, root:export:entry:instrument:detector:slices

	Duplicate/O root:Packages:NIST:Event:binEndTime, root:export:entry:reduction:binEndTime
	Duplicate/O root:Packages:NIST:Event:timeWidth, root:export:entry:reduction:timeWidth
	Duplicate/O root:Packages:NIST:Event:binCount, root:export:entry:reduction:binCount

	//
	// TODO -- determine what the proper time is to fill in when the data is oscillatory
	//  and the slices have different meaning. Updating to the full collection time seems appropriate
	//  but what does that mean for absolute scaling?
	//
	//
	// update the count time to reflect the event times that were kept - after discarding the bad events
	//
	// update the time everywhere
	//
	//
	// entry:control:count_time	// this is the field that is used
	// entry:collection_time		//this field is not used, but write it here too

	NVAR gEvent_Mode = root:Packages:NIST:Event:gEvent_Mode // ==0 for "stream", ==1 for Oscillatory

	NVAR longestTime = root:Packages:NIST:Event:gEvent_t_longest

	WAVE count_time      = $"root:export:entry:control:count_time"
	WAVE collection_time = $"root:export:entry:collection_time"

	if(gEvent_Mode == 0) // stream
		count_time      = longestTime
		collection_time = longestTime
	else
		//other ocsillatory modes

		// don't change any of the count times..
	endif

	return (0)
End

//
// data is intact in the file so that it can still be read in as a regular raw data file.
//
Proc SaveExportedEvents()

	string filename = root:Packages:NIST:RAW:fileList //name of the data file(s) in raw (take 1st from semi-list)
	string saveName

	saveName = StringFromList(0, fileName + ";")
	Save_SANS_file("root:export", "Events_" + saveName)
	Printf "Saved file %s\r", "Events_" + saveName
EndMacro

//////////////////////////////////////////////////////////////
//
//
// Panel for reducing event data
//
//
//
//		Panel to have readout/buttons for:
//			# slices
//			timing information (table, graph)
//			protocol to use (popup)
//			Event_ file (popup)
//
//			Manually advance slice and display in RAW (for testing)
//
//

//
//		Save the total monitor count
//		Save the total count time
//		Save the sample label
//
//		? Don't need to save the original detector data (I can sum the slices)
//
//
// for each slice(N)
//		find the binWidth -> bin fraction
//		adjust count time
// 	adjust monitor count
//		? adjust integrated detector count
// 	adjust sample label (mark as slice(N)?)
//
//		copy slice(N) to each detector panel (ignore B)
//
//		Process through reduction protocol
//
//		give appropriate output name (N)
//
//

//*************************
//
// Procedures to allow batch reduction of Event data files
//
//****note that much of this file is becoming obsolete as improved methods for
//reducing multiple files are introduced. Some of these procedures may not last long***
//
//**************************

//
//panel to allow reduction of a series of files using a selected  protocol
//
//main entry procedure to open the panel, initializing if necessary
Proc ReduceEventFilesPanel()

	DoWindow/F Event_Reduce_Panel
	if(V_flag == 0)
		InitializeEventReducePanel()
		//draw panel
		Event_Reduce_Panel()
		//pop the protocol list
		EVR_ProtoPopMenuProc("", 1, "")
		//then update the popup list
		EVR_RedPopMenuProc("ERFilesPopup", 1, "")
	endif
EndMacro

//create the global variables needed to run the MReduce Panel
//all are kept in root:Packages:NIST:MRED
//
Proc InitializeEventReducePanel()

	if(DataFolderExists("root:Packages:NIST:EVRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:Packages:NIST:EVRED
		//		String/G root:Packages:NIST:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		if(V_flag == 1)
			string   dum                                  = S_path
			string/G root:Packages:NIST:EVRED:gCatPathStr = dum
		else
			string/G root:Packages:NIST:EVRED:gCatPathStr = "no path selected"
		endif
		string/G   root:Packages:NIST:EVRED:gMRedList    = "none"
		string/G   root:Packages:NIST:EVRED:gMRProtoList = "none"
		string/G   root:Packages:NIST:EVRED:gFileNumList = ""
		variable/G root:Packages:NIST:EVRED:gNumSlices   = 1
		variable/G root:Packages:NIST:EVRED:gCurSlice    = 1

	endif
EndMacro

//
// borrows some of the basic functions from the MRED panel
//
Window Event_Reduce_Panel()
	variable sc = 1

	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(535 * sc, 72 * sc, 951 * sc, 288 * sc)/K=1 as "Event File File Reduction"
	ModifyPanel cbRGB=(60535, 51151, 51490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7 * sc, 30 * sc, 422 * sc, 30 * sc
	SetVariable PathDisplay, pos={sc * 77, 7 * sc}, size={sc * 300, 13 * sc}, title="Path", fSize=12 * sc
	SetVariable PathDisplay, help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay, limits={-Inf, Inf, 0}, value=root:Packages:NIST:EVRED:gCatPathStr
	Button PathButton, pos={sc * 3, 3 * sc}, size={sc * 70, 20 * sc}, proc=PickEVRPathButton, title="Pick Path"
	Button PathButton, help={"Select the folder containing the raw SANS data files"}, fSize=12 * sc
	Button helpButton, pos={sc * 385, 3 * sc}, size={sc * 25, 20 * sc}, proc=ShowEVRHelp, title="?"
	Button helpButton, help={"Show the help file for reducing event files"}, fSize=12 * sc
	PopupMenu ERFilesPopup, pos={sc * 3, 45 * sc}, size={sc * 167, 19 * sc}, proc=EVR_RedPopMenuProc, title="File to Reduce"
	PopupMenu ERFilesPopup, help={"The displayed file is the one that will be reduced."}
	PopupMenu ERFilesPopup, mode=1, popvalue="none", value=#"root:Packages:NIST:EVRED:gMRedList", fSize=12 * sc

	SetVariable ERSlices, pos={sc * 3, 75 * sc}, size={sc * 110, 15 * sc}, title="# of slices"
	SetVariable ERSlices, limits={0, 1000, 0}, value=root:Packages:NIST:EVRED:gNumSlices, fSize=12 * sc

	SetVariable ERSelSlice, pos={sc * 130, 75 * sc}, size={sc * 130, 15 * sc}, title="current slice"
	SetVariable ERSelSlice, limits={0, 1000, 1}, value=root:Packages:NIST:EVRED:gCurSlice
	SetVariable ERSelSlice, proc=ChangeSliceViewSetVar, fSize=12 * sc

	Button ToSTOButton, pos={sc * 305, 45 * sc}, size={sc * 100, 20 * sc}, proc=EVR_LoadAndSTO, title="Load to STO"
	Button ToSTOButton, help={"Load the event file and copy to STO"}, fSize=12 * sc

	Button TimeBinButton, pos={sc * 305, 75 * sc}, size={sc * 100, 20 * sc}, proc=EVR_TimeBins, title="Time Bins"
	Button TimeBinButton, help={"Display the time bins"}, fSize=12 * sc

	//	SetVariable ERList,pos={sc*3,48*sc},size={sc*350,13*sc},proc=FileNumberListProc,title="File number list: "
	//	SetVariable ERList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	//	SetVariable ERList,limits={-Inf,Inf,1},value= root:Packages:NIST:EVRED:gFileNumList

	PopupMenu ERProto_pop, pos={sc * 3, 118 * sc}, size={sc * 119, 19 * sc}, proc=EVR_ProtoPopMenuProc, title="Protocol "
	PopupMenu ERProto_pop, help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu ERProto_pop, mode=1, popvalue="none", value=#"root:Packages:NIST:EVRED:gMRProtoList", fSize=12 * sc
	Button ReduceAllButton, pos={sc * 3, 178 * sc}, size={sc * 180, 20 * sc}, proc=EVR_ReduceAllSlices, title="Reduce All Slices"
	Button ReduceAllButton, help={"This will reduce all slices."}, fSize=12 * sc
	Button ReduceOneButton, pos={sc * 3, 148 * sc}, size={sc * 180, 20 * sc}, proc=EVR_ReduceTopSlice, title="Reduce Selected Slice"
	Button ReduceOneButton, help={"This will reduce the selected slice."}, fSize=12 * sc

	Button DoneButton, pos={sc * 290, 178 * sc}, size={sc * 110, 20 * sc}, proc=EVR_DoneButtonProc, title="Done Reducing"
	Button DoneButton, help={"When done reducing files, this will close this control panel."}, fSize=12 * sc
EndMacro

//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function PickEVRPathButton(string PathButton) : ButtonControl

	PickPath() //sets the main global path string for catPathName

	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
	string dum = S_path
	if(V_flag == 0)
		//path does not exist - no folder selected
		string/G root:Packages:NIST:EVRED:gCatPathStr = "no folder selected"
	else
		string/G root:Packages:NIST:EVRED:gCatPathStr = dum
	endif

	//Update the pathStr variable box
	ControlUpdate/W=Event_Reduce_Panel $"PathDisplay"

	//then update the popup list
	EVR_RedPopMenuProc("ERFilesPopup", 1, "")
End

//
// loads the file in the popup (to RAW as usual)
// then copies the data to STO
//
//	updates the total number of slices
//
// resets the slice view to 0
//		changes the limits on the SetVar control {0,n,1}
//
Function EVR_LoadAndSTO(string PathButton) : ButtonControl

	string   fileName
	variable err

	ControlInfo ERFilesPopup
	fileName = S_Value

	err = LoadRawSANSData(FileName, "RAW")
	if(!err) //directly from, and the same steps as DisplayMainButtonProc(ctrlName)
		SVAR   hdfDF  = root:file_name // last file loaded, may not be the safest way to pass
		string folder = StringFromList(0, hdfDF, ".")

		// this (in SANS) just passes directly to fRawWindowHook()
		UpdateDisplayInformation("RAW") // plot the data in whatever folder type

		// set the global to display ONLY if the load was called from here, not from the
		// other routines that load data (to read in values)
		SVAR gLast = root:myGlobals:gCurDispFile // is this correct?
		gLast = hdfDF

	endif

	// now copy RAW to STO for safe keeping...
	//CopyHDFToWorkFolder(oldtype,newtype)
	CopyHDFToWorkFolder("RAW", "STO")

	// read the number of slices
	WAVE/Z w   = root:Packages:NIST:RAW:entry:instrument:detector:slices
	NVAR   num = root:Packages:NIST:EVRED:gNumSlices

	num = DimSize(w, 2)

	//change the slice view to slice 0
	SetVariable ERSelSlice, win=Event_Reduce_Panel, limits={0, (num - 1), 1}
	NVAR value = root:Packages:NIST:EVRED:gCurSlice
	value = 0
	ChangeSliceViewSetVar("", 0, "", "")

	return (0)
End

// given a file already loaded into RAW (and copied to STO)
// display a selected slice (8 panels)
// rescale the monitor count
// rescale the count time
// update the sample label
//
// TODO -- and I missing anything that is done at the normal RAW load time
// that I am not doing here simply by copying over
// -- like... data error, nonlinear corrections, etc.
// the nonlinear corrections need only be done once, since the detector is the same for all slices.
//
Function ChangeSliceViewSetVar(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	variable ii
	string detStr, fname
	// varNum is the only meaningful input, the slice number

	// copy STO to RAW
	CopyHDFToWorkFolder("STO", "RAW")

	// switch data to point to the correct slice
	string tmpStr = "root:Packages:NIST:RAW:entry:instrument:"

	fname = "RAW"
	//	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
	//		detStr = StringFromList(ii, ksDetectorListNoB, ";")

	WAVE data = getDetectorDataW(fname)

	WAVE/Z slices = $("root:Packages:NIST:RAW:entry:instrument:detector:slices")
	data = slices[p][q][varNum]
	MakeDataError(tmpStr + "detector") //update the error wave to match the slice
	//	endfor

	// TODO: update the times and counts
	// use a special "put", not "write" so it is written to the RAW folder, not the file
	//
	WAVE binEnd    = root:Packages:NIST:RAW:entry:reduction:binEndTime
	WAVE timeWidth = root:Packages:NIST:RAW:entry:reduction:timeWidth

	variable timeFract, num
	num       = numpnts(binEnd)
	timeFract = timeWidth[varNum] / binEnd[num - 1]

	// get values from STO
	variable mon_STO, ctTime_STO
	string label_STO

	ctTime_STO = getCount_time("STO")
	mon_STO    = getBeamMonNormData("STO")
	label_STO  = getSampleDescription("STO")

	// mon ct
	putBeamMonNorm_Data("RAW", mon_STO * timeFract)
	// ct time
	putCount_time("RAW", ctTime_STO * timeFract)
	// label
	putSampleDescription("RAW", label_STO + " slice " + num2str(varNum))

	return (0)
End

//
// locates the time bins and shows the time bin table (and plot?) - loaded to RAW
//
// Can't show the plot of counts/bin since there would be 8 of these now, one for
// each panel. Could show a total count per slice, but the numbers (binCount) is currently
// not written to the Event_ file.
//
// the macro that is called from the main Event panel shows the total counts/bin for the carriage
// that is active. Maybe this would be OK, but then there are still two sets of data, one for
// Front and one for Middle...
//
// take the aproach of being able to reproduce the bin data that was presented at the time
// of the data slicing - that is, the total bin counts for each carriage
//
// -- so data is saved for each carriage (_F and _M) suffix
//
Function EVR_TimeBins(string PathButton) : ButtonControl

	WAVE binEnd    = root:Packages:NIST:RAW:entry:reduction:binEndTime
	WAVE timeWidth = root:Packages:NIST:RAW:entry:reduction:timeWidth
	WAVE binCount  = root:Packages:NIST:RAW:entry:reduction:binCount

	DoWindow/F EVR_BinTable
	if(V_flag == 0)
		edit/K=1/N=EVR_BinTable binEnd, binCount, timeWidth
	endif

	DoWindow/F EVR_BarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1 // building window...

		SetDataFolder root:Packages:NIST:RAW:
		Display/W=(70, 222, 370, 486)/N=EVR_BarGraph/K=1 binCount vs binEnd

		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0, 0, 0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=0
		ModifyGraph useBarStrokeRGB=1
		ModifyGraph standoff=0
		SetAxis left, 0, *
		Label bottom, "\\Z14Time (seconds)"
		Label left, "\\Z14Number of Events"
	endif

	SetDataFolder root:

	return (0)
End

Proc ShowEVRHelp(ctrlName) : ButtonControl
	string ctrlName

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Reducing Event Data]"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Tutorial Help file could not be found"
	endif
EndMacro

//
//
//
Function EVR_RedPopMenuProc(string ERFilesPopup, variable popNum, string popStr) : PopupMenuControl

	string list = GetValidEVRedPopupList()
	//
	SVAR str = root:Packages:NIST:EVRED:gMredList
	str = list
	ControlUpdate ERFilesPopup
	return (0)
End

// get a  list of all of the sample files, based on intent
//
// only accepts files in the list that are purpose=scattering
//
// then return just the ones that start with "Events_"
//
Function/S GetValidEVRedPopupList()

	string semiList = ""

	semiList = GetSAMList() //TODO -- need to add this functionality

	semiList = GrepList(semiList, "Events_")

	return (semiList)

End

//returns a list of the available protocol waves in the protocols folder
//removes "CreateNew", "tempProtocol" and "fakeProtocol" from list (if they exist)
//since these waves do not contain valid protocol instructions
//
// also removes Base and DoAll since for event file reduction, speed is of the essence
// and there is no provision in the protocol for "asking" for the files to be identified
//
Function EVR_ProtoPopMenuProc(string ERProto_pop, variable popNum, string popStr) : PopupMenuControl

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:myGlobals:Protocols
	string list = WaveList("*", ";", "")
	SetDataFolder root:

	//remove items from the list (list is unchanged if the items are not present)
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("fakeProtocol", list, ";")
	list = RemoveFromList("PanelNameW", list, ";")
	list = RemoveFromList("Beg_pts", list, ";")
	list = RemoveFromList("End_pts", list, ";")
	list = RemoveFromList("trimUpdate", list, ";")
	list = RemoveFromList("Base", list, ";")
	list = RemoveFromList("DoAll", list, ";")

	string/G root:Packages:NIST:EVRED:gMRProtoList = list
	ControlUpdate ERProto_pop

End

//
//button procedure to close the panel,
//
Function EVR_DoneButtonProc(string ctrlName) : ButtonControl

	// this button will make sure all files are closed
	//and close the panel

	Close/A
	DoWindow/K Event_Reduce_Panel

	KillDataFolder root:Packages:NIST:EVRED
End

//
// reduce just the selected slice
//
// Assumes that:
// - the event data file has been loaded and copied to STO for repeated access
// - the protocol has been properly and completely defined (test one slice first!)
//
//
Function EVR_ReduceTopSlice(string ctrlName) : ButtonControl

	//get the selected protocol
	ControlInfo ERProto_pop
	string protocolNameStr = S_Value

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:myGlobals:Protocols:gProtoStr = protocolNameStr

	// get the file name from the popup
	ControlInfo ERFilesPopup
	string samStr = S_Value

	// get the current slice number
	NVAR curSlice = root:Packages:NIST:EVRED:gCurSlice
	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:EVRED:gNumSlices

	//reduce all the files in the list here, using the global protocol(the full reference)
	//see -- DoReduceList is found in MultipleReduce.ipf

	//	DoReduceList(commaList)
	variable skipLoad = 0
	ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)

	return 0
End

//
// reduce all slices
//
Function EVR_ReduceAllSlices(string ctrlName) : ButtonControl

	//get the selected protocol
	ControlInfo ERProto_pop
	string protocolNameStr = S_Value

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:myGlobals:Protocols:gProtoStr = protocolNameStr

	// get the file name from the popup
	ControlInfo ERFilesPopup
	string samStr = S_Value

	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:EVRED:gNumSlices

	variable skipLoad = 0
	variable curSlice = 0
	// do the first one (slice 0)
	ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)

	skipLoad = 1
	for(curSlice = 1; curSlice < totalSlices; curSlice += 1)
		ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)
	endfor

	return 0
End

//////////////////////////////////
//
// This is the Event-equivalent version of ExecuteProtocol
// with special handling for shuffling the event slices from STO to RAW->SAM
// -skips repetitive loads
// -adjusts timing
// -names slices

//protStr is the full path to the selected protocol wave
//samStr is the name of the event data file "Event_sansNNNN.nxs.ngv"
// SliceNum is the number of slice to reduce (copy it from STO)
// skipLoad is a flag (0|1) to allow skip of loading EMP, BGD, etc. on repeated passes
Function ExecuteProtocol_Event(string protStr, string samStr, variable sliceNum, variable skipLoad)

	string protoPath = "root:myGlobals:Protocols:"
	WAVE/T prot      = $(protoPath + protStr)
	//	SetDataFolder root:myGlobals:Protocols

	variable filesOK, err, notDone
	string activeType, msgStr, junkStr
	string pathStr = ""
	PathInfo catPathName //this is where the files are
	pathStr = S_path

	//	NVAR useXMLOutput = root:Packages:NIST:gXML_Write

	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)

	//////////////////////////////
	// DIV
	//////////////////////////////
	// for SANS tubes, DIV is used on each data file as it is converted to WORK, so it needs to be
	//  the first thing in place, before any data or backgrounds are loaded

	//check for work.div file (prot[2])
	//load in if needed
	// no math is done here, DIV is applied as files are converted to WORK (the first operation in SANS)
	//
	// save the state of the DIV preference (this is not the choice in the protocol
	//
	NVAR     gDoDIVCor       = root:Packages:NIST:gDoDIVCor
	variable saved_gDoDIVCor = gDoDIVCor

	if(!skipLoad)

		err = Proto_LoadDIV(prot[2]) // will load only if requested

		if(err)
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif
	endif

	//////////////////////////////
	// SAM
	//////////////////////////////

	// move the selected slice number to RAW, then to SAM
	ChangeSliceViewSetVar("", sliceNum, "", "")

	//Execute "Convert_to_Workfile()"
	err = Raw_to_work_for_Tubes("SAM")

	//always update
	activeType = "SAM"
	UpdateDisplayInformation(ActiveType)

	//////////////////////////////
	// BGD
	//////////////////////////////

	//check for BGD file  -- "ask" might not fail - "ask?" will - ? not allowed in VAX filenames
	// add if needed
	//use a "case" statement
	if(!skipLoad)

		msgStr     = "Select background file"
		activeType = "BGD"

		err = Proto_LoadFile(prot[0], activeType, msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif

		//	//Loader is in charge of updating, since it knows if data was loaded
		//	UpdateDisplayInformation(ActiveType)
	endif

	//////////////////////////////
	// EMP
	//////////////////////////////

	//check for emp file (prot[1])
	// add if needed
	if(!skipLoad)

		msgStr     = "Select empty cell data"
		activeType = "EMP"

		err = Proto_LoadFile(prot[1], activeType, msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif

		//	//Loader is in charge of updating, since it knows if data was loaded
		//	UpdateDisplayInformation(ActiveType)
	endif

	//////////////////////////////
	// CORRECT
	//////////////////////////////

	//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction
	//additional modes 091301
	//11 = emp, bgd, drk
	//12 = bgd and drk
	//13 = emp and drk
	//14 = no subtractions
	//work.drk is from proto[6]
	//
	//subtracting just the DRK data is NOT an option - it doesnt' really make any physical sense
	// - in this case, DRK is skipped (equivalent to mode==4)
	// automatically accounts for attenuators given the lookup tables and the
	//desired subtractions
	//Attenuator lookup tables are alredy implemented (NG1 = NG7)
	//

	/////// DRK is SKIPPED

	//	//read in the DRK data if necessary
	//	//only one file, assumed to be RAW data
	//	//
	//	String fname="",drkStr=""
	//	drkStr=StringByKey("DRK",prot[6],"=",",")
	//	if(cmpstr(drkStr,"none") != 0)
	//		err = ReadHeaderAndData( (pathStr+drkStr) )
	//		if(err)
	//			PathInfo/S catPathName
	//			Abort "reduction sequence aborted"
	//		endif
	//		err = Raw_to_Work_NoNorm("DRK")
	//	endif

	//dispatch to the proper "mode" of Correct()
	//	Dispatch_to_Correct(bgdStr,empStr,drkStr)

	//		DoAlert 0,"NO DISPATCH TO CORRECT - PROTO"

	Dispatch_to_Correct(prot[0], prot[1], prot[6])

	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "error in Correct, called from executeprotocol, normal cor"
	endif
	activeType = "COR"

	// always update - COR will always be generated
	UpdateDisplayInformation(ActiveType)

	//
	// DIV is not done here any more (CAL is not generated)
	// since the DIV step is done at Raw_to_Work() step -- doing it here would be
	// double-DIV-ing
	//

	//////////////////////////////
	//  ABSOLUTE SCALE
	//////////////////////////////

	err = Proto_ABS_Scale(prot[4], activeType)

	if(err)
		SetDataFolder root:
		Abort "Error in Absolute_Scale(), called from ExecuteProtocol"
	endif
	// activeType is set pass-by-reference in Proto_ABS_Scale only if ABS is used
	//	activeType = "ABS"

	//////////////////////////////
	// MASK
	//////////////////////////////
	//
	// DONE
	//		x- fill in the "ask" step
	//  x- none is OK, except if the kill fails for any reason
	// x- the regular case of the file name specified by the protocol works correctly
	// x- don't create a null mask if not used, it will handle the error and print out that the mask is missing
	//
	//mask data if desired (mask is applied when the data is binned to I(q)) and is
	//not done explicitly here

	//check for mask
	//doesn't change the activeType
	if(!skipLoad)

		Proto_ReadMask(prot[3])
	endif

	//////////////////////////////
	// AVERAGING
	//////////////////////////////

	// average/save data as specified
	//Parse the keyword=<Value> string as needed, based on AVTYPE

	//average/plot first
	string aV_type = StringByKey("AVTYPE", prot[5], "=", ";")
	if(cmpstr(av_type, "none") != 0)
		if(cmpstr(av_type, "") == 0) //if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit in the panel
			SetAverageParamsButtonProc("dummy") //from "ProtocolAsPanel"
			SVAR tempAveStr = root:myGlobals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE", tempAveStr, "=", ";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			string/G root:myGlobals:Protocols:gAvgInfoStr = prot[5]
		endif
	endif

	////////////////////////////////////////
	// DISPATCH TO AVERAGING
	/////////////////////////////////////////
	//
	// TODO:
	// -- do I calculate the proper resolution here?, YES, I've already decoded the binning type
	//   and the averaging type has been specified by the protocol.
	//
	// so currently, the resolution is calculated every time that the data is averaged (in VC_fDoBinning_QxQy2D)
	//
	// -- if I calculate the resolution here, then the Trimming routines must be updated
	//    to trim the resolution waves also. This will work for the columns present in
	//    pinhole resolution, but anything using the matrix method - it won't work - and I'll need
	//    a different solution
	//

	Proto_doAverage(prot[5], av_type, activeType)

	////////////////////////
	// PLOT THE DATA
	////////////////////////

	//
	// Plotting as actually done within the averaging routines (there is a y/n flag in the prot[5] string)
	// - this function exists, but does nothing and has not been updated from VSANS yet
	//
	//	Proto_doPlot(prot[5],av_type,activeType,binType,detGroup)

	////////////////////
	// SAVE THE DATA
	////////////////////

	//
	// x- how do I get the sample file name?
	//    local variable samFileLoaded is the file name loaded (contains the extension)
	//
	// Proto_SaveFile(avgStr,activeType,samFileLoaded,av_type,binType,detGroup,trimBegStr,trimEndStr)

	string outputFileName
	//	outputFileName = RemoveEnding(samStr,".nxs.ngv") + "_SL"+num2str(sliceNum)

	variable offset = StrSearch(samStr, ".", 0) //find the first "."
	outputFileName = samStr[0, offset - 1] + "_SL" + num2str(sliceNum)

	Proto_SaveFile(prot[5], activeType, outputFileName, av_type)

	//////////////////////////////
	// DONE WITH THE PROTOCOL
	//////////////////////////////

	// reset any global preferences that I had changed
	gDoDIVCor = saved_gDoDIVCor

	return (0)
End

Function Dispatch_to_Correct(string bgdStr, string empStr, string drkStr)

	variable val, err
	variable mode = 4

	if((cmpstr("none", bgdStr) == 0) && (cmpstr("none", empStr) == 0))
		//no subtraction (mode = 4),
		mode = 4
	endif
	if((cmpstr(bgdStr, "none") != 0) && (cmpstr(empStr, "none") == 0))
		//subtract BGD only
		mode = 2
	endif
	if((cmpstr(bgdStr, "none") == 0) && (cmpstr(empStr, "none") != 0))
		//subtract EMP only
		mode = 3
	endif
	if((cmpstr(bgdStr, "none") != 0) && (cmpstr(empStr, "none") != 0))
		// bkg and emp subtraction are to be done (BOTH not "none")
		mode = 1
	endif
	//	activeType = "COR"
	//add in DRK mode (0= not used, 10 = used)
	// TODO: DRK has been de-activated for now
	//	val = NumberByKey("DRKMODE",drkStr,"=","," )
	//	mode += val

	//		print "mode = ",mode

	err = Correct(mode)
	if(err)
		return (err)
		//		SetDataFolder root:
		//		Abort "error in Correct, called from executeprotocol, normal cor"
	endif

	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation("COR")

	return (0)
End

Function Proto_ABS_Scale(string absStr, string &activeType)

	variable c2, c3, c4, c5, kappa_err, err
	//do absolute scaling if desired

	if(cmpstr("none", absStr) != 0)
		if(cmpstr("ask", absStr) == 0)
			//			//get the params from the user
			//			Execute "AskForAbsoluteParams_Quest()"
			//			//then from the list
			//			SVAR junkAbsStr = root:Packages:NIST:Protocols:gAbsStr
			//			c2 = NumberByKey("TSTAND", junkAbsStr, "=", ";")	//parse the list of values
			//			c3 = NumberByKey("DSTAND", junkAbsStr, "=", ";")
			//			c4 = NumberByKey("IZERO", junkAbsStr, "=", ";")
			//			c5 = NumberByKey("XSECT", junkAbsStr, "=", ";")
			//			kappa_err = NumberByKey("SDEV", junkAbsStr, "=", ";")
		else
			//get the parames from the list
			c2        = NumberByKey("TSTAND", absStr, "=", ";") //parse the list of values
			c3        = NumberByKey("DSTAND", absStr, "=", ";")
			c4        = NumberByKey("IZERO", absStr, "=", ";")
			c5        = NumberByKey("XSECT", absStr, "=", ";")
			kappa_err = NumberByKey("SDEV", absStr, "=", ";")
		endif
		//get the sample trans and thickness from the activeType folder
		//		Variable c0 = getSampleTransmission(activeType)		//sample transmission
		//		Variable c1 = getSampleThickness(activeType)		//sample thickness

		err = Absolute_Scale_P(activeType, absStr)
		if(err)
			return (err)
			SetDataFolder root:
			Abort "Error in Absolute_Scale_P(), called from ExecuteProtocol"
		endif
		activeType = "ABS"
		UpdateDisplayInformation(ActiveType) //update before breaking from loop
	endif

	return (0)
End

// kappa comes in as s_izero, so be sure to use 1/kappa_err
//
//convert the "type" data to absolute scale using the given standard information
//s_ is the standard
//w_ is the "work" file
//both are work files and should already be normalized to 10^8 monitor counts
Function Absolute_Scale_P(string type, string absStr)

	variable w_trans, w_thick, s_trans, s_thick, s_izero, s_cross, kappa_err

	variable w_moncount, s1, s2, s3, s4
	variable defmon = 1e8
	variable scale, trans_err
	variable err, ii
	string detStr

	// be sure that the starting data exists
	err = WorkDataExists(type)
	if(err == 1)
		return (err)
	endif

	//copy from current dir (type) to ABS
	CopyHDFToWorkFolder(type, "ABS")

	// TODO: -- which monitor to use? Here, I think it should already be normalized to 10^8
	//
	//	w_moncount = V_getMonitorCount(type)		//monitor count in "type"

	w_moncount = getBeamMonNormData(type)

	if(w_moncount == 0)
		//zero monitor counts will give divide by zero ---
		DoAlert 0, "Total monitor count in data file is zero. No rescaling of data"
		return (1) //report error
	endif

	w_trans   = getSampleTransmission(type) //sample transmission
	w_thick   = getSampleThickness(type)    //sample thickness
	trans_err = getSampleTransError(type)

	//get the parames from the list
	s_trans   = NumberByKey("TSTAND", absStr, "=", ";") //parse the list of values
	s_thick   = NumberByKey("DSTAND", absStr, "=", ";")
	s_izero   = NumberByKey("IZERO", absStr, "=", ";")
	s_cross   = NumberByKey("XSECT", absStr, "=", ";")
	kappa_err = NumberByKey("SDEV", absStr, "=", ";")

	//calculate scale factor
	s1    = defmon / w_moncount // monitor count (s1 should be 1)
	s2    = s_thick / w_thick
	s3    = s_trans / w_trans
	s4    = s_cross / s_izero
	scale = s1 * s2 * s3 * s4

	// kappa comes in as s_izero, so be sure to use 1/kappa_err

	//do the actual absolute scaling here, modifying the data in ABS
	WAVE data     = getDetectorDataW("ABS")
	WAVE data_err = getDetectorDataErrW("ABS")

	data    *= scale
	data_err = sqrt(scale^2 * data_err^2 + scale^2 * data^2 * (kappa_err^2 / s_izero^2 + trans_err^2 / w_trans^2))

	//********* 15APR02
	// DO NOT correct for atenuators here - the COR step already does this, putting all of the data on equal
	// footing (zero atten) before doing the subtraction.

	return (0) //no error
End

Function Proto_ReadMask(string maskStr)

	//check for mask
	//doesn't change the activeType
	string mskFileName = ""
	string pathStr     = ""
	PathInfo catPathName //this is where the files are
	pathStr = S_path

	if(cmpstr("none", maskStr) != 0)
		if(cmpstr("ask", maskStr) == 0)
			//get file from user
			// x- fill in the get file prompt, and handle the result
			Prompt mskFileName, "MASK File", popup, GetMSKList()
			DoPrompt "Select File", mskFileName
			//			if (V_Flag)
			//				return 0									// user cancelled
			//			endif

			if(strlen(mskFileName) == 0) //use cancelled
				//if none desired, make sure that the old mask is deleted
				KillDataFolder/Z root:Packages:NIST:MSK:
				NewDataFolder/O root:Packages:NIST:MSK

				DoAlert 0, "No Mask file selected, data not masked"
			else
				//read in the file from the selection
				LoadRawSANSData(mskFileName, "MSK")
			endif
		else
			//just read it in from the protocol
			//list processing is necessary to remove any final comma
			mskFileName = pathStr + StringFromList(0, maskStr, ",")
			LoadRawSANSData(mskFileName, "MSK")
		endif

	else
		//if none desired, make sure that the old mask is deleted
		//
		KillDataFolder/Z root:Packages:NIST:MSK:
		NewDataFolder/O root:Packages:NIST:MSK

	endif

	return (0)
End

Function Proto_doAverage(string avgStr, string av_type, string activeType)

	strswitch(av_type) //dispatch to the proper routine to average to 1D data
		case "none":
			//still do nothing
			break

		case "Circular":
			CircularAverageTo1D(activeType) // this does a default circular average
			break

		case "Sector":
			SectorAverageTo1D(activeType)
			break

		case "Sector_PlusMinus":
			Sector_PlusMinus1D(activeType)
			break

		case "Rectangular":
			RectangularAverageTo1D(activeType)
			break

		case "Annular":
			AnnularAverageTo1D(activeType)
			break

		case "2D_ASCII":
			//do nothing
			break
		case "QxQy_ASCII":
			//do nothing
			break
		case "PNG_Graphic":
			//do nothing
			break
		default: // FIXME(CodeStyleFallthroughCaseRequireComment)
			// FIXME(BugproneMissingSwitchDefaultCase)
			break
		//do nothing
	endswitch

	return (0)
End

// for later use? currently the averaging routines also plot the data
// may be better in the future to have them separated
//
//
// this function currently does nothing and has not been updated from VSANS yet
//
Function Proto_doPlot(string plotStr, string av_type, string activeType)

	//	String doPlot = StringByKey("PLOT",plotStr,"=",";")
	//
	//	If( (cmpstr(doPlot,"Yes")==0) && (cmpstr(av_type,"none") != 0) )
	//
	//		strswitch(av_type)	//dispatch to the proper routine to PLOT 1D data
	//			case "none":
	//				//still do nothing
	//				break
	//
	//			case "Circular":
	//			case "Sector":
	//				V_PlotData_Panel()		//this brings the plot window to the front, or draws it (ONLY)
	//				V_Update1D_Graph(activeType,binType)		//update the graph, data was already binned
	//				break
	//			case "Sector_PlusMinus":
	//	//			Sector_PlusMinus1D(activeType)
	//				break
	//			case "Rectangular":
	//	//			RectangularAverageTo1D(activeType)
	//				break
	//
	//			case "Annular":
	//				V_Phi_Graph_Proc(activeType,detGroup)
	//				break
	//
	//			case "Narrow_Slit":
	//			// these are the same plotting routines as for standard circular average
	//				V_PlotData_Panel()		//this brings the plot window to the front, or draws it (ONLY)
	//				V_Update1D_Graph(activeType,binType)		//update the graph, data was already binned
	//				break
	//
	//			case "2D_ASCII":
	//				//do nothing
	//				break
	//			case "QxQy_ASCII":
	//				//do nothing
	//				break
	//			case "PNG_Graphic":
	//				//do nothing
	//				break
	//			default:
	//				//do nothing
	//		endswitch
	//
	//	endif		// end of plotting switch
	//
	return (0)
End

Function Proto_SaveFile(string avgStr, string activeType, string samFileLoaded, string av_type)

	string fullpath          = ""
	string newfileName       = ""
	string saveType          = StringByKey("SAVE", avgStr, "=", ";") //does user want to save data?
	NVAR   useNXcanSASOutput = root:Packages:NIST:gNXcanSAS_Write
	NVAR   useXMLOutput      = root:Packages:NIST:gXML_Write

	if((cmpstr(saveType[0, 2], "Yes") == 0) && (cmpstr(av_type, "none") != 0))
		//then save
		newFileName = RemoveEnding(samFileLoaded, ".nxs.ngv")

		//pick ABS or AVE extension
		string exten = activeType
		if(cmpstr(exten, "ABS") != 0)
			exten = "AVE"
		endif
		if(cmpstr(av_type, "2D_ASCII") == 0)
			exten = "ASC"
		endif
		if(cmpstr(av_type, "QxQy_ASCII") == 0)
			exten = "DAT"
		endif

		//		// add an "x" to the file extension if the output is XML
		//		// currently (2010), only for ABS and AVE (1D) output
		//		if( cmpstr(exten,"ABS") == 0 || cmpstr(exten,"AVE") == 0 )
		//			if(useXMLOutput == 1)
		//				exten += "x"
		//			endif
		//		endif

		//Path is catPathName, symbolic path
		//if this doesn't exist, a dialog will be presented by setting dialog = 1
		//
		variable dialog = 0

		PathInfo/S catPathName
		string item     = StringByKey("NAME", avgStr, "=", ";")     //Auto or Manual naming
		string autoname = StringByKey("AUTONAME", avgStr, "=", ";") //autoname -  will get empty string if not present
		if((cmpstr(item, "Manual") == 0) || (cmpstr(newFileName, "") == 0))
			//manual name if requested or if no name can be derived from header
			fullPath = newfileName + "." + exten //puts possible new name or null string in dialog
			dialog   = 1                         //force dialog for user to enter name
		else
			//auto-generate name and prepend path - won't put up any dialogs since it has all it needs
			//use autoname if present
			if(cmpstr(autoname, "") != 0)
				fullPath = S_Path + autoname + "." + exten
			else
				fullPath = S_Path + newFileName + "." + exten
			endif
		endif
		//
		strswitch(av_type)
			case "Annular":
				WritePhiave_W_Protocol(activeType, fullPath, dialog)
				break
			case "2D_ASCII":
				Fast2DExport(activeType, fullPath, dialog)
				break
			case "2D_NXcanSAS":
				WriteNxCanSAS2D(activeType, fullPath, dialog)
				break
			case "QxQy_ASCII":
				QxQy_Export(activeType, fullPath, dialog)
				break
			case "PNG_Graphic":
				SaveAsPNG(activeType, fullpath, dialog)
				break
			default: // this is the circular/sector/rectangular averages, FIXME(CodeStyleFallthroughCaseRequireComment)
				if(useXMLOutput == 1)
					WriteXMLWaves_W_Protocol(activeType, fullPath, dialog)
				elseif(useNXcanSASOutput == 1)
					WriteNxCanSAS1D(activeType, fullPath, dialog)
				else
					WriteWaves_W_Protocol(activeType, fullpath, dialog)
				endif

		endswitch

	endif
	return (0)
End

Proc EstFrameOverlap(lambda, fwhm, sdd)
	variable lambda = 6
	variable fwhm   = 0.12
	variable sdd    = 13
	FrameOverlap(lambda, fwhm, sdd)
EndMacro

//fwhm = 2.355 sigma of the Gaussian
// two standard deviations = 95% of distribution
//
// lam =5A, fwhm = 0.138, sdd=13.7m
//
Function FrameOverlap(variable lam, variable fwhm, variable sdd)

	variable speed_lo, speed_hi, sig, lam_lo, lam_hi
	variable time_lo, time_hi, delta

	sig    = fwhm / 2.355
	lam_lo = lam - 2 * lam * sig
	lam_hi = lam + 2 * lam * sig

	speed_lo = 3956 / lam_lo //if lam [=] A, speed [=] m/s
	speed_hi = 3956 / lam_hi //if lam [=] A, speed [=] m/s

	// then the time to travel from sample to detector is:
	time_lo = sdd / speed_lo
	time_hi = sdd / speed_hi

	delta = (time_hi - time_lo) //hi wavelength is slower

	Print "Accounting for 2 sigma = 95% of distribution"
	Print "Use bin widths larger than frame overlap time (s) = ", delta

	return (delta)
End

// check for the existence of Event waves, and clean them out if the user
// agrees - this will greatly speed up the save and reduce the experiment size,
// but the current loaded work will be lost.
//
Function EventWaveCleanup()

	if(exists("root:Packages:NIST:Event:rescaledTime") == 0)
		// no event data exists, exit
		return (0)
	endif

	SetDataFolder root:Packages:NIST:Event:
	WAVE/Z rescaledTime = rescaledTime

	string str = ""
	str  = "Do you want to delete the event waves? \r\r"
	str += "Deleting saves space and time, but you lose your currently loaded data.\r\r"
	str += "Delete waves?"
	if(waveExists(rescaledTime) != 0)
		DoAlert 2, str

		// "no" or "cancel" will pass through and do nothing
		if(V_flag == 1) //yes, delete them
			string list = ""
			variable ii, num

			list = WaveList("*", ";", "")
			num  = ItemsinList(list)
			for(ii = 0; ii < num; ii += 1)
				WAVE w = $(StringFromList(ii, list))
				KillWaves/Z w
			endfor

		endif

	endif

	SetDataFolder root:
	return (0)
End

//
//
//Duplicate/O :Packages:NIST:Event:rescaledTime,rescaledTime_samp;DelayUpdate
//Resample/DOWN=1000 rescaledTime_samp;DelayUpdate
//
//

////////////////////////////////////////////////////////////////////////////
//
//
/////////////////////////   TESTING ROUTINES
//
/////////////////////////   "FAKE" EVENT FILES - WRITE/READ
//

//
//
// to generate and save a file, run the two commands:
//
//  MakeFakeEventWave(1e6)
//  writeFakeEventFile("")
//
//

Structure eventWord_fake
	uchar xPos
	uchar yPos
	uint64 eventTime
EndStructure

Function testBitShift()

	//	// /L=64 bit, /U=unsigned
	//	Make/L/U/N=100 eventWave
	//	eventWave = 0

	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit

	int64 i64_num, b1, b2, b3, b4, b5, b6, b7, b8
	int64 i64_ticks, i64_start

	//	b1=255
	//	b3=255
	//	b5=255
	//	b7=255
	//	b2=0
	//	b4=0
	//	b6=0
	//	b8=0

	b1 = 5
	b3 = 15
	b5 = 25
	b7 = 35
	b2 = 10
	b4 = 20
	b6 = 30
	b8 = 40

	b7 = b7 << 8
	b6 = b6 << 16
	b5 = b5 << 24
	b4 = b4 << 32
	b3 = b3 << 40
	b2 = b2 << 48
	b1 = b1 << 56

	i64_num = b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8
	printf "%64b\r", i64_num

	//

	b1 = (i64_num >> 56) & 0xFF // = last byte, after shifting
	b2 = (i64_num >> 48) & 0xFF
	b3 = (i64_num >> 40) & 0xFF
	b4 = (i64_num >> 32) & 0xFF
	b5 = (i64_num >> 24) & 0xFF
	b6 = (i64_num >> 16) & 0xFF
	b7 = (i64_num >> 8) & 0xFF
	b8 = (i64_num) & 0xFF       // first byte

	Print b1, b2, b3, b4, b5, b6, b7, b8

	return (0)
End

//
Function MakeFakeEventWave(variable num)

	variable ii

	//	// /B= 8 bits, /U=unsigned, need 10 values per event
	Make/O/B/U/N=(num * 10) eventWave
	eventWave = 0

	// for each 80-bit value:
	// byte 1: tube index [0,127]
	// byte 2: pixel value [0,127]
	// bytes 3-10 (= 8 bytes): time stamp in resolution unit

	uint64 i64_num, b1, b2, b3, b4, b5, b6, b7, b8, xPos, yPos
	uint64 i64_ticks, i64_start

	i64_start = ticks
	for(ii = 0; ii < num; ii += 1)
		//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)

		if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
			xPos = trunc(abs(enoise(128)))
		else
			xPos = trunc(abs(enoise(112)))
		endif
		yPos = trunc(abs(enoise(128))) // same here, to get results [0,127]

		//		i64_ticks = ticks-i64_start
		i64_ticks = i64_start + ii * 1e6 // to get the time values into the correct magnitude (1e6->)

		//write out the x and y positions
		eventWave[10 * ii]     = xPos
		eventWave[10 * ii + 1] = yPos

		// pick out each byte of the 64-bit time value
		b1 = (i64_ticks >> 56) & 0xFF // = last byte, after shifting
		b2 = (i64_ticks >> 48) & 0xFF
		b3 = (i64_ticks >> 40) & 0xFF
		b4 = (i64_ticks >> 32) & 0xFF
		b5 = (i64_ticks >> 24) & 0xFF
		b6 = (i64_ticks >> 16) & 0xFF
		b7 = (i64_ticks >> 8) & 0xFF
		b8 = (i64_ticks) & 0xFF       // first byte

		//
		//  this is apparently the wrong order?
		//
		//		eventWave[10*ii+2] = b1
		//		eventWave[10*ii+3] = b2
		//		eventWave[10*ii+4] = b3
		//		eventWave[10*ii+5] = b4
		//		eventWave[10*ii+6] = b5
		//		eventWave[10*ii+7] = b6
		//		eventWave[10*ii+8] = b7
		//		eventWave[10*ii+9] = b8

		//
		// this is correct -- it depends if I'm little or big endian...
		//  I need this to be little-endian
		//
		//	"Under little-endian byte ordering,
		// which is commonly used on Windows,
		// the low-order byte is read from the file first."
		//
		eventWave[10 * ii + 2] = b8
		eventWave[10 * ii + 3] = b7
		eventWave[10 * ii + 4] = b6
		eventWave[10 * ii + 5] = b5
		eventWave[10 * ii + 6] = b4
		eventWave[10 * ii + 7] = b3
		eventWave[10 * ii + 8] = b2
		eventWave[10 * ii + 9] = b1

	endfor

	return (0)
End

Function ReadFakeEvents()

	string gNASStr = ""
	gNASStr = PadString(gNASStr, 3, 0x20) //pad to 3 bytes

	variable gRevision, gOffset, gTime1, gTime2, gTime3, gTime4, gTime5, gVolt, gResol, gTime6
	variable refnum, ii
	string filePathStr = ""

	Open/R refnum as filepathstr

	FBinRead refnum, gNASStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
	//	FBinRead/F=2/U/B=3 refnum, gTime6
	//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol

	FStatus refnum
	FSetPos refnum, V_logEOF

	Close refnum

	Print "string = ", gNASStr
	Print "revision = ", gRevision
	Print "offset = ", gOffset
	Print "time part 1 = ", gTime1
	Print "time part 2 = ", gTime2
	Print "time part 3 = ", gTime3
	Print "time part 4 = ", gTime4
	Print "time part 5 = ", gTime5
	//	Print "time part 6 = ",gTime6
	//	Print "det group = ",gDetStr
	Print "voltage (V) = ", gVolt
	Print "clock freq (Hz) = ", gResol

	print "1/freq (s) = ", 1 / gResol

	return (0)
End

//
// TODO - Mar 2023
// --untested--
//
Function writeFakeEventFile(string fname)

	WAVE w = eventWave
	variable refnum

	string   sansStr  = "NAS"
	variable revision = 11
	variable offset   = 26   // no disabled tubes
	variable time1    = 2017
	variable time2    = 0525
	variable time3    = 1122
	variable time4    = 3344 // these 4 time pieces are supposed to be 8 bytes total
	variable time5    = 3344 // these 5 time pieces are supposed to be 10 bytes total
	//	Variable time6 = 5566		// these 6 time pieces are supposed to be 10 bytes total
	//	String detStr = "M"
	variable volt  = 1500
	variable resol = 1e9

	string gNASStr = ""
	gNASStr = PadString(gNASStr, 3, 0x20) //pad to 3 bytes

	Open refnum as fname

	FBinWrite refnum, sansStr
	FBinWrite/F=2/U refnum, revision
	FBinWrite/F=2/U refnum, offset
	FBinWrite/F=2/U refnum, time1
	FBinWrite/F=2/U refnum, time2
	FBinWrite/F=2/U refnum, time3
	FBinWrite/F=2/U refnum, time4
	FBinWrite/F=2/U refnum, time5
	//	FBinWrite/F=2/U refnum, time6
	//	FBinWrite refnum, detStr
	FBinWrite/F=2/U refnum, volt
	FBinWrite/F=3/U refnum, resol

	FGetPos refnum
	Print "End of header = ", V_filePos
	offset = V_filePos

	FSetPos refnum, 7
	FBinWrite/F=2/U refnum, offset //write the correct offset

	FSetPos refNum, offset

	FBinWrite refnum, w

	close refnum

	return (0)
End

////
////
//xFunction MakeFakeEvents()
//
////	// /L=64 bit, /U=unsigned
//	Make/O/L/U/N=10 smallEventWave
//	smallEventWave = 0
//
//	// for each 64-bit value:
//	// byte 1: tube index [0,191]
//	// byte 2: pixel value [0,127]
//	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
//
//	uint64 i64_num,b1,b2,b3,b4,b5,b6,b7,b8
//	uint64 i64_ticks,i64_start
//
////	b1 = 47
////	b2 = 123
////	i64_ticks = 123456789
//	b1 = 41
//	b2 = 66
//	i64_ticks = 15
//
//
////	b2 = b2 << 48
////	b1 = b1 << 56
////
////	i64_num = b1+b2+i64_ticks
//
//	// don't shift b1
//	b2 = b2 << 8
//	i64_ticks = i64_ticks << 16
//
//	i64_num = b1+b2+i64_ticks
//
//	printf "%64b\r",i64_num
//	print i64_num
//
//	smallEventWave[0] = i64_num
//
//	return(0)
//End
//

