#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
//
// -- DONE -- Feb 2021 got the "correct" header structure from Phil
// x- the clock frequency (time step) is hard wired as 100 x 10-9 s
//  since I still can't read a correct value from the file header
// x- see the test function: V_ReadEventHeader()
//
//

//
// There are functions in this file to generate "fake" event data for testing
//

//
// for the event mode data with the proposed 64 bit structure, I use Igor for everything.
// No need to write an XOP - Igor 8 has uint64 data type, and fast bit manipulation
//
//
// Skipping the appropriate bits of the header (after I read them in) is possible with
// either GBLoadWave (treating the entire wave as 64 bit, unsigned)
// -- see in LoadWave, the suggestions for "Loading Large Waves" is speed is an issue
//
// Using a STRUCT for the specific bits of the 64-bit word does not seem possible, and direct decoding
// seems to work fine.
//
//Structure eventWord
//	uchar eventTime[6]
//	uchar location
//	uchar tube
//endStructure
//

//
// (5/2017)
// The basic bits of reading work, but will need to be customized to be able to accomodate file names in/out
// and especially the number of disabled tubes (although as long as I have the offset, it shouldn't be that
// big of an issue.
//

// TODO:
//
// There may be memory issues with this
//
// -- do I want to do the time binning first?
// -- does it really matter?
//
Function V_SortAndSplitEvents()

	SetDataFolder root:Packages:NIST:VSANS:Event:

	WAVE eventTime = EventTime
	WAVE location  = location
	WAVE tube      = tube

	variable t1 = ticks
	Print "sort started"
	Sort tube, tube, eventTime, location
	print "sort done ", (ticks - t1) / 60

	variable b1, e1, b2, e2, b3, e3, b4, e4
	FindValue/S=0/I=48 tube
	b1 = 0
	e1 = V_Value - 1
	b2 = V_Value
	FindValue/S=(b2)/I=96 tube
	e2 = V_Value - 1
	b3 = V_Value
	FindValue/S=(b3)/I=144 tube
	e3 = V_Value - 1
	b4 = V_Value
	e4 = numpnts(tube) - 1

	Print b1, e1
	Print b2, e2
	Print b3, e3
	Print b4, e4

	//	tube and location become x and y, and can be byte data
	// eventTime still needs to be 64 bit - when do I convert it to FP?
	Make/O/B/U/N=(e1 - b1 + 1) tube1, location1
	Make/O/L/U/N=(e1 - b1 + 1) eventTime1

	Make/O/B/U/N=(e2 - b2 + 1) tube2, location2
	Make/O/L/U/N=(e2 - b2 + 1) eventTime2

	Make/O/B/U/N=(e3 - b3 + 1) tube3, location3
	Make/O/L/U/N=(e3 - b3 + 1) eventTime3

	Make/O/B/U/N=(e4 - b4 + 1) tube4, location4
	Make/O/L/U/N=(e4 - b4 + 1) eventTime4

	tube1 = tube[p + b1]
	tube2 = tube[p + b2]
	tube3 = tube[p + b3]
	tube4 = tube[p + b4]

	location1 = location[p + b1]
	location2 = location[p + b2]
	location3 = location[p + b3]
	location4 = location[p + b4]

	eventTime1 = eventTime[p + b1]
	eventTime2 = eventTime[p + b2]
	eventTime3 = eventTime[p + b3]
	eventTime4 = eventTime[p + b4]

	KillWaves/Z eventTime, location, tube

	return (0)
End

//
// switch the "active" panel to the selected group (1-4) (5 concatenates them all together)
//

//
// copy the set of tubes over to the "active" set that is to be histogrammed
// and redimension them to be sure that they are double precision
//
Function V_SwitchTubeGroup(variable tubeGroup)

	SetDataFolder root:Packages:NIST:VSANS:Event:

	if(tubeGroup <= 4)
		WAVE tube      = $("tube" + num2Str(tubeGroup))
		WAVE location  = $("location" + num2Str(tubeGroup))
		WAVE eventTime = $("eventTime" + num2Str(tubeGroup))

		WAVE/Z xloc, yLoc, timePt

		KillWaves/Z timePt, xLoc, yLoc
		Duplicate/O eventTime, timePt

		// TODO:
		// -- for processing, initially treat all of the tubes along x, and 128 pixels along y
		//   panels can be transposed later as needed to get the orientation correct

		//		if(tubeGroup == 1 || tubeGroup == 4)
		// L/R panels, they have tubes along x
		Duplicate/O tube, xLoc
		Duplicate/O location, yLoc
		//		else
		//		// T/B panels, tubes are along y
		//			Duplicate/O tube yLoc
		//			Duplicate/O location xLoc
		//		endif

		Redimension/D xLoc, yLoc, timePt

	endif

	if(tubeGroup == 5)
		WAVE xloc, yLoc, timePt

		KillWaves/Z timePt, xLoc, yLoc

		string str = ""
		str = "tube1;tube2;tube3;tube4;"
		Concatenate/O/NP str, xloc
		str = "location1;location2;location3;location4;"
		Concatenate/O/NP str, yloc
		str = "eventTime1;eventTime2;eventTime3;eventTime4;"
		Concatenate/O/NP str, timePt

		Redimension/D xLoc, yLoc, timePt
	endif

	return (0)
End

Proc V_SwitchGroupAndCleanup(num)
	variable num

	V_SwitchTubeGroup(num)
	SetDataFolder root:Packages:NIST:VSANS:Event:
	Duplicate/O timePt, rescaledTime
	KillWaves/Z OscSortIndex
	print WaveMax(rescaledTime)
	root:Packages:NIST:VSANS:Event:gEvent_t_longest=waveMax(rescaledTime)

	SetDataFolder root:

EndMacro

// Counts the number of x or y location values at an input number
// -- does not appear to be used
//
Function V_count(variable num)

	SetDataFolder root:Packages:NIST:VSANS:Event:

	WAVE xloc = xloc
	WAVE yloc = yloc
	variable ii, npt
	variable total = 0
	npt = numpnts(xloc)
	for(ii = 0; ii < npt; ii += 1)
		if(xloc[ii] == num)
			total += 1
		endif
		if(yloc[ii] == num)
			total += 1
		endif
	endfor

	Print total

	SetDataFolder root:
	return (0)
End

// Based on the numbering 0-191:
// group 1 = R (0,47) 			MatrixOp out = ReverseRows(in)
// group 2 = T (48,95) 		output = slices_T[q][p][r]
// group 3 = B (96,143) 		output = slices_B[XBINS-q-1][YBINS-p-1][r]		(reverses rows and columns)
// group 4 = L (144,191) 	MatrixOp out = ReverseCols(in)
//
// the transformation flips the panel to the view as if the detector was viewed from the sample position
// (this is the standard view for SANS and VSANS)
//
// Takes the data that was binned, and separates it into the 4 detector panels
// Waves are 3D waves x-y-time
//
// MatrixOp may not be necessary for the R/L transformations, but indexing or MatrixOp are both really fast.
//
//
Function V_SplitBinnedToPanels()

	SetDataFolder root:Packages:NIST:VSANS:Event:
	WAVE slicedData = slicedData //this is 3D

	variable nSlices = DimSize(slicedData, 2)

	Make/O/D/N=(XBINS, YBINS, nSlices) slices_R, slices_L, slices_T, slices_B, output

	slices_R = slicedData[p][q][r]
	slices_T = slicedData[p + 48][q][r]
	slices_B = slicedData[p + 96][q][r]
	slices_L = slicedData[p + 144][q][r]

	MatrixOp/O output = ReverseRows(slices_R)
	slices_R = output

	MatrixOp/O output = ReverseCols(slices_L)
	slices_L = output

	Redimension/N=(YBINS, XBINS, nSlices) output
	output = slices_T[q][p][r]
	KillWaves/Z slices_T
	Duplicate/O output, slices_T

	output = slices_B[XBINS - q - 1][YBINS - p - 1][r]
	KillWaves/Z slices_B
	Duplicate/O output, slices_B

	KillWaves/Z output
	SetDataFolder root:

	return (0)
End

// simple panel to display the 4 detector panels after the data has been binned and sliced
//
// TODO:
// -- label panels, axes
// -- add a way to display different slices (this can still be done on the main panel, all at once)
// -- any other manipulations?
//

Proc VSANS_EventPanels()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(720, 45, 1530, 570)/N=VSANS_EventPanels/K=1
	DoWindow/C VSANS_EventPanels
	ModifyPanel fixedSize=1, noEdit=1

	//	Display/W=(745,45,945,425)/HOST=#
	Display/W=(10, 45, 210, 425)/HOST=#
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_L //  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_L, ctab={*, *, ColdWarm, 0}
	ModifyImage slices_L, ctabAutoscale=3
	ModifyGraph margin(left)=14, margin(bottom)=14, margin(top)=14, margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #, Event_slice_L
	SetActiveSubwindow ##

	//	Display/W=(1300,45,1500,425)/HOST=#
	Display/W=(565, 45, 765, 425)/HOST=#
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_R //  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_R, ctab={*, *, ColdWarm, 0}
	ModifyImage slices_R, ctabAutoscale=3
	ModifyGraph margin(left)=14, margin(bottom)=14, margin(top)=14, margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #, Event_slice_R
	SetActiveSubwindow ##

	//	Display/W=(945,45,1300,235)/HOST=#
	Display/W=(210, 45, 565, 235)/HOST=#
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_T //  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_T, ctab={*, *, ColdWarm, 0}
	ModifyImage slices_T, ctabAutoscale=3
	ModifyGraph margin(left)=14, margin(bottom)=14, margin(top)=14, margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #, Event_slice_T
	SetActiveSubwindow ##

	//	Display/W=(945,235,1300,425)/HOST=#
	Display/W=(210, 235, 565, 425)/HOST=#
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_B //  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_B, ctab={*, *, ColdWarm, 0}
	ModifyImage slices_B, ctabAutoscale=3
	ModifyGraph margin(left)=14, margin(bottom)=14, margin(top)=14, margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #, Event_slice_B
	SetActiveSubwindow ##
	//

EndMacro

//
/////// to copy a sliced data set to a folder to save
//

// load event file from RAW data loaded
// pick either the front or middle carriage
// pick the "mode" of loading data (osc, stream, etc.)
// process the event data
// split to panels
// move slices to "export" location
// move bin details to export location
// repeat load + process + move with the 2nd carriage, using the same time binning
//
// save the data file, giving a new name to not overwrite the original data file
//

//
// root:Packages:NIST:VSANS:RAW:gFileList		//name of the data file(s) in raw (take 1st from semi-list)
//

Function V_DuplicateRAWForExport()

	KillDataFolder/Z root:export
	DuplicateDataFolder root:Packages:NIST:VSANS:RAW  root:export
	return (0)
End

Function V_CopySlicesForExport(string detStr)

	if(cmpstr(detStr, "M") == 0)
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_B, root:export:entry:instrument:detector_MB:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_T, root:export:entry:instrument:detector_MT:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_L, root:export:entry:instrument:detector_ML:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_R, root:export:entry:instrument:detector_MR:slices

		Duplicate/O root:Packages:NIST:VSANS:Event:binEndTime, root:export:entry:reduction:binEndTime_M
		Duplicate/O root:Packages:NIST:VSANS:Event:timeWidth, root:export:entry:reduction:timeWidth_M
		Duplicate/O root:Packages:NIST:VSANS:Event:binCount, root:export:entry:reduction:binCount_M

	else
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_B, root:export:entry:instrument:detector_FB:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_T, root:export:entry:instrument:detector_FT:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_L, root:export:entry:instrument:detector_FL:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_R, root:export:entry:instrument:detector_FR:slices

		Duplicate/O root:Packages:NIST:VSANS:Event:binEndTime, root:export:entry:reduction:binEndTime_F
		Duplicate/O root:Packages:NIST:VSANS:Event:timeWidth, root:export:entry:reduction:timeWidth_F
		Duplicate/O root:Packages:NIST:VSANS:Event:binCount, root:export:entry:reduction:binCount_F

	endif

	return (0)
End

//
// data is intact in the file so that it can still be read in as a regular raw data file.
//
Proc V_SaveExportedEvents()

	string filename = root:Packages:NIST:VSANS:RAW:gFileList //name of the data file(s) in raw (take 1st from semi-list)
	string saveName

	saveName = StringFromList(0, fileName + ";")
	Save_VSANS_file("root:export", "Events_" + saveName)
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
Proc V_ReduceEventFilesPanel()

	DoWindow/F V_Event_Reduce_Panel
	if(V_flag == 0)
		V_InitializeEventReducePanel()
		//draw panel
		V_Event_Reduce_Panel()
		//pop the protocol list
		V_EVR_ProtoPopMenuProc("", 1, "")
		//then update the popup list
		V_EVR_RedPopMenuProc("ERFilesPopup", 1, "")
	endif
EndMacro

//create the global variables needed to run the MReduce Panel
//all are kept in root:Packages:NIST:VSANS:Globals:MRED
//
Proc V_InitializeEventReducePanel()

	if(DataFolderExists("root:Packages:NIST:VSANS:Globals:EVRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:EVRED
		//		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		if(V_flag == 1)
			string   dum                                                = S_path
			string/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = dum
		else
			string/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = "no path selected"
		endif
		string/G   root:Packages:NIST:VSANS:Globals:EVRED:gMRedList    = "none"
		string/G   root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList = "none"
		string/G   root:Packages:NIST:VSANS:Globals:EVRED:gFileNumList = ""
		variable/G root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices   = 1
		variable/G root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice    = 1

	endif
EndMacro

//
// borrows some of the basic functions from the MRED panel
//
Window V_Event_Reduce_Panel()
	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(535 * sc, 72 * sc, 951 * sc, 288 * sc)/K=1 as "Event File File Reduction"
	ModifyPanel cbRGB=(60535, 51151, 51490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7 * sc, 30 * sc, 422 * sc, 30 * sc
	SetVariable PathDisplay, pos={sc * 77, 7 * sc}, size={sc * 300, 13 * sc}, title="Path"
	SetVariable PathDisplay, help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr
	Button PathButton, pos={sc * 3, 3 * sc}, size={sc * 70, 20 * sc}, proc=V_PickEVRPathButton, title="Pick Path"
	Button PathButton, help={"Select the folder containing the raw SANS data files"}
	Button helpButton, pos={sc * 385, 3 * sc}, size={sc * 25, 20 * sc}, proc=V_ShowEVRHelp, title="?"
	Button helpButton, help={"Show the help file for reducing event files"}
	PopupMenu ERFilesPopup, pos={sc * 3, 45 * sc}, size={sc * 167, 19 * sc}, proc=V_EVR_RedPopMenuProc, title="File to Reduce"
	PopupMenu ERFilesPopup, help={"The displayed file is the one that will be reduced."}
	PopupMenu ERFilesPopup, mode=1, popvalue="none", value=#"root:Packages:NIST:VSANS:Globals:EVRED:gMRedList"

	SetVariable ERSlices, pos={sc * 3, 75 * sc}, size={sc * 110, 15 * sc}, title="# of slices"
	SetVariable ERSlices, limits={0, 1000, 0}, value=root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices

	SetVariable ERSelSlice, pos={sc * 130, 75 * sc}, size={sc * 130, 15 * sc}, title="current slice"
	SetVariable ERSelSlice, limits={0, 1000, 1}, value=root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	SetVariable ERSelSlice, proc=V_ChangeSliceViewSetVar

	Button ToSTOButton, pos={sc * 305, 45 * sc}, size={sc * 100, 20 * sc}, proc=V_EVR_LoadAndSTO, title="Load to STO"
	Button ToSTOButton, help={"Load the event file and copy to STO"}

	Button TimeBinButton, pos={sc * 305, 75 * sc}, size={sc * 100, 20 * sc}, proc=V_EVR_TimeBins, title="Time Bins"
	Button TimeBinButton, help={"Display the time bins"}

	//	SetVariable ERList,pos={sc*3,48*sc},size={sc*350,13*sc},proc=V_FileNumberListProc,title="File number list: "
	//	SetVariable ERList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	//	SetVariable ERList,limits={-Inf,Inf,1},value= root:Packages:NIST:VSANS:Globals:EVRED:gFileNumList

	PopupMenu ERProto_pop, pos={sc * 3, 118 * sc}, size={sc * 119, 19 * sc}, proc=V_EVR_ProtoPopMenuProc, title="Protocol "
	PopupMenu ERProto_pop, help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu ERProto_pop, mode=1, popvalue="none", value=#"root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList"
	Button ReduceAllButton, pos={sc * 3, 178 * sc}, size={sc * 180, 20 * sc}, proc=V_EVR_ReduceAllSlices, title="Reduce All Slices"
	Button ReduceAllButton, help={"This will reduce all slices."}
	Button ReduceOneButton, pos={sc * 3, 148 * sc}, size={sc * 180, 20 * sc}, proc=V_EVR_ReduceTopSlice, title="Reduce Selected Slice"
	Button ReduceOneButton, help={"This will reduce the selected slice."}

	Button DoneButton, pos={sc * 290, 178 * sc}, size={sc * 110, 20 * sc}, proc=V_EVR_DoneButtonProc, title="Done Reducing"
	Button DoneButton, help={"When done reducing files, this will close this control panel."}
EndMacro

//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function V_PickEVRPathButton(string PathButton) : ButtonControl

	V_PickPath() //sets the main global path string for catPathName

	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
	string dum = S_path
	if(V_flag == 0)
		//path does not exist - no folder selected
		string/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = "no folder selected"
	else
		string/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = dum
	endif

	//Update the pathStr variable box
	ControlUpdate/W=V_Event_Reduce_Panel $"PathDisplay"

	//then update the popup list
	V_EVR_RedPopMenuProc("ERFilesPopup", 1, "")
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
Function V_EVR_LoadAndSTO(string PathButton) : ButtonControl

	string   fileName
	variable err

	ControlInfo ERFilesPopup
	fileName = S_Value

	err = V_LoadHDF5Data(FileName, "RAW")
	if(!err) //directly from, and the same steps as DisplayMainButtonProc(ctrlName)
		SVAR   hdfDF  = root:file_name // last file loaded, may not be the safest way to pass
		string folder = StringFromList(0, hdfDF, ".")

		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

		// set the global to display ONLY if the load was called from here, not from the
		// other routines that load data (to read in values)
		SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
		gLast = hdfDF

	endif

	// now copy RAW to STO for safe keeping...
	//V_CopyHDFToWorkFolder(oldtype,newtype)
	V_CopyHDFToWorkFolder("RAW", "STO")

	// read the number of slices from FL
	WAVE/Z w   = root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:slices
	NVAR   num = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices

	num = DimSize(w, 2)

	//change the slice view to slice 0
	SetVariable ERSelSlice, win=V_Event_Reduce_Panel, limits={0, (num - 1), 1}
	NVAR value = root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	value = 0
	V_ChangeSliceViewSetVar("", 0, "", "")

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
Function V_ChangeSliceViewSetVar(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	variable ii
	string detStr, fname
	// varNum is the only meaningful input, the slice number

	// copy STO to RAW
	V_CopyHDFToWorkFolder("STO", "RAW")

	// switch data to point to the correct slice
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:"

	fname = "RAW"
	for(ii = 0; ii < ItemsInList(ksDetectorListNoB); ii += 1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		WAVE data = V_getDetectorDataW(fname, detStr)

		WAVE/Z slices = $("root:Packages:NIST:VSANS:RAW:entry:instrument:detector_" + detStr + ":slices")
		data = slices[p][q][varNum]
		V_MakeDataError(tmpStr + "detector_" + detStr) //update the error wave to match the slice
	endfor

	// TODO: update the times and counts
	// use a special "put", not "write" so it is written to the RAW folder, not the file
	//
	WAVE binEnd_F    = root:Packages:NIST:VSANS:RAW:entry:reduction:binEndTime_F
	WAVE timeWidth_F = root:Packages:NIST:VSANS:RAW:entry:reduction:timeWidth_F

	variable timeFract, num
	num       = numpnts(binEnd_F)
	timeFract = timeWidth_F[varNum] / binEnd_F[num - 1]

	// get values from STO
	variable mon_STO, ctTime_STO
	string label_STO

	ctTime_STO = V_getCount_time("STO")
	mon_STO    = V_getBeamMonNormData("STO")
	label_STO  = V_getSampleDescription("STO")

	// mon ct
	V_putBeamMonNormData("RAW", mon_STO * timeFract)
	// ct time
	V_putCount_time("RAW", ctTime_STO * timeFract)
	// label
	V_putSampleDescription("RAW", label_STO + " slice " + num2str(varNum))

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
Function V_EVR_TimeBins(string PathButton) : ButtonControl

	WAVE binEnd_F    = root:Packages:NIST:VSANS:RAW:entry:reduction:binEndTime_F
	WAVE timeWidth_F = root:Packages:NIST:VSANS:RAW:entry:reduction:timeWidth_F
	WAVE binCount_F  = root:Packages:NIST:VSANS:RAW:entry:reduction:binCount_F

	WAVE binEnd_M    = root:Packages:NIST:VSANS:RAW:entry:reduction:binEndTime_M
	WAVE timeWidth_M = root:Packages:NIST:VSANS:RAW:entry:reduction:timeWidth_M
	WAVE binCount_M  = root:Packages:NIST:VSANS:RAW:entry:reduction:binCount_M

	DoWindow/F V_EVR_BinTable
	if(V_flag == 0)
		edit/K=1/N=V_EVR_BinTable binEnd_F, binEnd_M, binCount_F, binCount_M, timeWidth_F, timeWidth_M
	endif

	DoWindow/F V_EVR_F_BarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1 // building window...

		SetDataFolder root:Packages:NIST:VSANS:RAW:
		Display/W=(70, 222, 370, 486)/N=V_EVR_F_BarGraph/K=1 binCount_F vs binEnd_F

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

	DoWindow/F V_EVR_M_BarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1 // building window...

		SetDataFolder root:Packages:NIST:VSANS:RAW:
		Display/W=(400, 222, 700, 486)/N=V_EVR_M_BarGraph/K=1 binCount_M vs binEnd_M

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

Proc V_ShowEVRHelp(ctrlName) : ButtonControl
	string ctrlName

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Reducing Event Data]"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Tutorial Help file could not be found"
	endif
EndMacro

//
//
//
Function V_EVR_RedPopMenuProc(string ERFilesPopup, variable popNum, string popStr) : PopupMenuControl

	string list = V_GetValidEVRedPopupList()
	//
	SVAR str = root:Packages:NIST:VSANS:Globals:EVRED:gMredList
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
Function/S V_GetValidEVRedPopupList()

	string semiList = ""

	semiList = V_GetSAMList()

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
Function V_EVR_ProtoPopMenuProc(string ERProto_pop, variable popNum, string popStr) : PopupMenuControl

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
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

	string/G root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList = list
	ControlUpdate ERProto_pop

End

//
//button procedure to close the panel,
//
Function V_EVR_DoneButtonProc(string ctrlName) : ButtonControl

	// this button will make sure all files are closed
	//and close the panel

	Close/A
	DoWindow/K V_Event_Reduce_Panel

	KillDataFolder root:Packages:NIST:VSANS:Globals:EVRED
End

//
// reduce just the selected slice
//
// Assumes that:
// - the event data file has been loaded and copied to STO for repeated access
// - the protocol has been properly and completely defined (test one slice first!)
//
//
Function V_EVR_ReduceTopSlice(string ctrlName) : ButtonControl

	//get the selected protocol
	ControlInfo ERProto_pop
	string protocolNameStr = S_Value

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr

	// get the file name from the popup
	ControlInfo ERFilesPopup
	string samStr = S_Value

	// get the current slice number
	NVAR curSlice = root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices

	//reduce all the files in the list here, using the global protocol(the full reference)
	//see -- DoReduceList is found in MultipleReduce.ipf

	//	V_DoReduceList(commaList)
	variable skipLoad = 0
	V_ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)

	return 0
End

//
// reduce all slices
//
Function V_EVR_ReduceAllSlices(string ctrlName) : ButtonControl

	//get the selected protocol
	ControlInfo ERProto_pop
	string protocolNameStr = S_Value

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr

	// get the file name from the popup
	ControlInfo ERFilesPopup
	string samStr = S_Value

	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices

	variable skipLoad = 0
	variable curSlice = 0
	// do the first one (slice 0)
	V_ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)

	skipLoad = 1
	for(curSlice = 1; curSlice < totalSlices; curSlice += 1)
		V_ExecuteProtocol_Event(protocolNameStr, samStr, curSlice, skipLoad)
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
Function V_ExecuteProtocol_Event(string protStr, string samStr, variable sliceNum, variable skipLoad)

	string protoPath = "root:Packages:NIST:VSANS:Globals:Protocols:"
	WAVE/T prot      = $(protoPath + protStr)
	//	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

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
	//7 = beginning trim points
	//8 = end trim points
	//9 = unused
	//10 = unused
	//11 = unused

	//////////////////////////////
	// DIV
	//////////////////////////////
	// for VSANS, DIV is used on each data file as it is converted to WORK, so it needs to be
	//  the first thing in place, before any data or backgrounds are loaded

	//check for work.div file (prot[2])
	//load in if needed
	// no math is done here, DIV is applied as files are converted to WORK (the first operation in VSANS)
	//
	// save the state of the DIV preference
	NVAR     gDoDIVCor       = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	variable saved_gDoDIVCor = gDoDIVCor

	if(!skipLoad)

		err = V_Proto_LoadDIV(prot[2])

		if(err)
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif
	endif

	//////////////////////////////
	// SAM
	//////////////////////////////

	// move the selected slice number to RAW, then to SAM
	V_ChangeSliceViewSetVar("", sliceNum, "", "")

	//Execute "V_Convert_to_Workfile()"
	err = V_Raw_to_work("SAM")

	//always update
	activeType = "SAM"
	V_UpdateDisplayInformation(ActiveType)

	//////////////////////////////
	// BGD
	//////////////////////////////

	//check for BGD file  -- "ask" might not fail - "ask?" will - ? not allowed in VAX filenames
	// add if needed
	//use a "case" statement
	if(!skipLoad)

		msgStr     = "Select background file"
		activeType = "BGD"

		err = V_Proto_LoadFile(prot[0], activeType, msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif

		//	//Loader is in charge of updating, since it knows if data was loaded
		//	V_UpdateDisplayInformation(ActiveType)
	endif

	//////////////////////////////
	// EMP
	//////////////////////////////

	//check for emp file (prot[1])
	// add if needed
	if(!skipLoad)

		msgStr     = "Select empty cell data"
		activeType = "EMP"

		err = V_Proto_LoadFile(prot[1], activeType, msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif

		//	//Loader is in charge of updating, since it knows if data was loaded
		//	V_UpdateDisplayInformation(ActiveType)
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
	//		err = V_Raw_to_Work_NoNorm("DRK")
	//	endif

	//dispatch to the proper "mode" of Correct()
	//	V_Dispatch_to_Correct(bgdStr,empStr,drkStr)
	V_Dispatch_to_Correct(prot[0], prot[1], prot[6])

	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "error in Correct, called from executeprotocol, normal cor"
	endif
	activeType = "COR"

	// always update - COR will always be generated
	V_UpdateDisplayInformation(ActiveType)

	//////////////////////////////
	//  ABSOLUTE SCALE
	//////////////////////////////

	err = V_Proto_ABS_Scale(prot[4], activeType)

	if(err)
		SetDataFolder root:
		Abort "Error in V_Absolute_Scale(), called from V_ExecuteProtocol"
	endif
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

		V_Proto_ReadMask(prot[3])
	endif

	//////////////////////////////
	// AVERAGING
	//////////////////////////////

	// average/save data as specified
	//Parse the keyword=<Value> string as needed, based on AVTYPE

	//average/plot first
	string av_type = StringByKey("AVTYPE", prot[5], "=", ";")
	if(cmpstr(av_type, "none") != 0)
		if(cmpstr(av_type, "") == 0) //if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit in the panel
			V_SetAverageParamsButtonProc("dummy") //from "ProtocolAsPanel"
			SVAR tempAveStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE", tempAveStr, "=", ";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			string/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = prot[5]
		endif
	endif

	string detGroup = StringByKey("DETGROUP", prot[5], "=", ";") //only for annular, null if not present

	//convert the folder to linear scale before averaging, then revert by calling the window hook
	// (not needed for VSANS, data is always linear scale)

	//
	// (DONE)
	// -x this generates a "Bin Type Not Found" error if reducing only to a 2D level (like for DIV)
	//		because binTypeStr is null
	string binTypeStr = StringByKey("BINTYPE", prot[5], "=", ";")
	// plotting is not really necessary, and the graph may not be open - so skip for now?
	variable binType
	// only get the binning type if user asks for averaging
	if(cmpstr(av_type, "none") != 0)
		binType = V_BinTypeStr2Num(binTypeStr)
		if(binType == 0)
			Abort "Binning mode not found in V_QBinAllPanels() " // when no case matches
		endif
	endif

	// identify the collimation type
	// this will be a string used to determine how the resolution information is to be calculated
	// and written to the reduced data file
	//
	// possible values are:
	//
	// pinhole
	// pinhole_whiteBeam
	// narrowSlit
	// narrowSlit_whiteBeam
	// convergingPinholes
	//

	string collimationStr
	collimationStr = V_IdentifyCollimation(activeType)

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

	V_Proto_doAverage(prot[5], av_type, activeType, binType, collimationStr)

	////////////////////////
	// PLOT THE DATA
	////////////////////////

	V_Proto_doPlot(prot[5], av_type, activeType, binType, detGroup)

	////////////////////
	// SAVE THE DATA
	////////////////////

	//
	// x- how do I get the sample file name?
	//    local variable samFileLoaded is the file name loaded (contains the extension)
	//
	// V_Proto_SaveFile(avgStr,activeType,samFileLoaded,av_type,binType,detGroup,trimBegStr,trimEndStr)

	prot[9] = collimationStr
	string outputFileName
	outputFileName = RemoveEnding(samStr, ".nxs.ngv") + "_SL" + num2str(sliceNum)
	//? remove the "Events_" from the beginning? some other naming scheme entirely?

	V_Proto_SaveFile(prot[5], activeType, outputFileName, av_type, binType, detGroup, prot[7], prot[8])

	//////////////////////////////
	// DONE WITH THE PROTOCOL
	//////////////////////////////

	// reset any global preferences that I had changed
	gDoDIVCor = saved_gDoDIVCor

	return (0)
End

////////////////////////////////////////////////////////////////////////////
//
//
/////////////////////////   TESTING ROUTINES
//
/////////////////////////   "FAKE" EVENT FILES - WRITE/READ
//
//
Function V_testBitShift()

	//	// /L=64 bit, /U=unsigned
	//	Make/L/U/N=100 eventWave
	//	eventWave = 0

	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit

	int64 i64_num, b1, b2, b3, b4, b5, b6, b7, b8
	int64 i64_ticks, i64_start

	b1 = 255
	b3 = 255
	b5 = 255
	b7 = 255
	b2 = 0
	b4 = 0
	b6 = 0
	b8 = 0

	b7 = b7 << 8
	b6 = b6 << 16
	b5 = b5 << 24
	b4 = b4 << 32
	b3 = b3 << 40
	b2 = b2 << 48
	b1 = b1 << 56

	i64_num = b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8
	printf "%64b\r", i64_num

	return (0)
End

Function V_MakeFakeEvents()

	//	// /L=64 bit, /U=unsigned
	Make/O/L/U/N=10 smallEventWave
	smallEventWave = 0

	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit

	uint64 i64_num, b1, b2, b3, b4, b5, b6, b7, b8
	uint64 i64_ticks, i64_start

	//	b1 = 47
	//	b2 = 123
	//	i64_ticks = 123456789
	b1        = 41
	b2        = 66
	i64_ticks = 15

	//	b2 = b2 << 48
	//	b1 = b1 << 56
	//
	//	i64_num = b1+b2+i64_ticks

	// don't shift b1
	b2        = b2 << 8
	i64_ticks = i64_ticks << 16

	i64_num = b1 + b2 + i64_ticks

	printf "%64b\r", i64_num
	print i64_num

	smallEventWave[0] = i64_num

	return (0)
End

//Structure eventWord
//	uchar eventTime[6]
//	uchar location
//	uchar tube
//endStructure

Function V_decodeFakeEvent()

	WAVE w = smallEventWave
	uint64 val, b1, b2, btime
	val = w[0]

	//	printf "%64b\r",w[0]		//wrong (drops the last ≈ 9 bits)
	printf "%64b\r", val //correct, assign value to 64bit variable
	//	print w[0]				//wrong
	print val // correct

	//	b1 = (val >> 56 ) & 0xFF			// = 255, last byte, after shifting
	//	b2 = (val >> 48 ) & 0xFF
	//	btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes

	b1    = val & 0xFF
	b2    = (val >> 8) & 0xFF
	btime = (val >> 16)

	print b1
	print b2
	print btime

	//	//test as struct
	//	Print "as STRUCT"
	//
	//	STRUCT eventWord s
	//
	//	s = w[0]
	//
	//	print s.tube
	//	print s.location
	//	print s.eventTime

	return (0)
End

// Based on the numbering 0-191:
// group 1 = R (0,47) 			MatrixOp out = ReverseRows(in)
// group 2 = T (48,95) 		output = slices_T[q][p][r]
// group 3 = B (96,143) 		output = slices_B[XBINS-q-1][YBINS-p-1][r]		(reverses rows and columns)
// group 4 = L (144,191) 	MatrixOp out = ReverseCols(in)
//
//
// tested up to num=1e8 successfully
//
Function V_MakeFakeEventWave(variable num)

	variable ii

	//	num = 1e3

	//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=(num) eventWave
	eventWave = 0

	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit

	uint64 i64_num, b1, b2
	uint64 i64_ticks, i64_start

	i64_start = ticks
	for(ii = 0; ii < num; ii += 1)
		//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)

		//		b1 = trunc(abs(enoise(192)))		//since truncated, need 192 as highest random to give 191 after trunc
		b1 = trunc(mod(ii, 192))

		b2 = trunc(abs(enoise(128))) // same here, to get results [0,127]

		//		i64_ticks = ticks-i64_start
		i64_ticks = ii + 1

		// don't shift b1
		b2        = b2 << 8
		i64_ticks = i64_ticks << 16

		i64_num = b1 + b2 + i64_ticks

		eventWave[ii] = i64_num
	endfor

	return (0)
End

//
// TODO:
// -- can this be multithreaded (eliminating the loop)?
//
// MultiThread tube = (w[p]) & 0xFF
// MultiThread location = (w[p] >> 8 ) & 0xFF
// MultiThread eventTime = (w[p] >> 16)
//
// !!!!- yes - for a 35 MB file:
// for loop = 4.3 s
// MultiThread = 0.35 s
//
// !!! can I use the bit operations in MatrixOp? 1D waves are valid
//  to use with MatrixOp. Would it be better than multiThread?
//
//
Function V_decodeFakeEventWave(WAVE w)

	v_tic()
	//	WAVE w = eventWave
	uint64 val, b1, b2, btime
	val = w[0]

	//	printf "%64b\r",w[0]		//wrong (drops the last ≈ 9 bits)
	//	printf "%64b\r",val			//correct, assign value to 64bit variable
	//	print w[0]				//wrong
	//	print val				// correct

	variable num, ii
	num = numpnts(w)

	Make/O/L/U/N=(num) eventTime
	Make/O/U/B/N=(num) tube, location //8 bit unsigned

	MultiThread tube = (w[p]) & 0xFF
	MultiThread location = (w[p] >> 8) & 0xFF
	MultiThread eventTime = (w[p] >> 16)

	//	for(ii=0;ii<num;ii+=1)
	//		val = w[ii]
	//
	////		b1 = (val >> 56 ) & 0xFF			// = 255, last two bytes, after shifting
	////		b2 = (val >> 48 ) & 0xFF
	////		btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes
	//
	//		b1 = val & 0xFF
	//		b2 = (val >> 8) & 0xFF
	//		btime = (val >> 16)
	//
	//		tube[ii] = b1
	//		location[ii] = b2
	//		eventTime[ii] = btime
	//
	//	endfor

	v_toc()

	return (0)
End

//
// TODO - Feb 2021
// -- if I ever need to write out a "clean" event file, be sure to update
//   the header structure to the actual structure from Feb 2021
//   where time stamp is 12 bit, and detStr is NOT written
// -- is the offset really 26? should it be 27?
//
Function V_writeFakeEventFile(string fname)

	WAVE w = eventWave
	variable refnum

	string   vsansStr = "VSANS"
	variable revision = 11
	variable offset   = 26   // no disabled tubes
	variable time1    = 2017
	variable time2    = 0525
	variable time3    = 1122
	variable time4    = 3344 // these 4 time pieces are supposed to be 8 bytes total
	variable time5    = 3344 // these 5 time pieces are supposed to be 10 bytes total
	variable time6    = 5566 // these 6 time pieces are supposed to be 10 bytes total
	string   detStr   = "M"
	variable volt     = 1500
	variable resol    = 1e7

	Open refnum as fname

	FBinWrite refnum, vsansStr
	FBinWrite/F=2/U refnum, revision
	FBinWrite/F=2/U refnum, offset
	FBinWrite/F=2/U refnum, time1
	FBinWrite/F=2/U refnum, time2
	FBinWrite/F=2/U refnum, time3
	FBinWrite/F=2/U refnum, time4
	FBinWrite/F=2/U refnum, time5
	FBinWrite/F=2/U refnum, time6
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

//
// use GBLoadWave to do the reading, then I can do the decoding
//
Function V_readFakeEventFile(string fileName)

	// this reads in uint64 data, to a unit64 wave, skipping 22 bytes
	//	GBLoadWave/B/T={192,192}/W=1/S=22
	variable num, refnum

	//  to read a VSANS event file:
	//
	// - get the file name
	//	- read the header (all of it, since I need parts of it) (maybe read as a struct? but I don't know the size!)
	// - move to EOF and close
	//
	// - Use GBLoadWave to read the 64-bit events in

	string vsansStr = ""
	variable revision
	variable offset // no disabled tubes
	variable time1
	variable time2
	variable time3
	variable time4  // these 4 time pieces are supposed to be 8 bytes total
	variable time5  // these 5 time pieces are supposed to be 10 bytes total
	string detStr = ""
	variable volt
	variable resol

	vsansStr = PadString(vsansStr, 5, 0x20) //pad to 5 bytes
	detStr   = PadString(detStr, 1, 0x20)   //pad to 1 byte

	Open/R refnum as filename
	filename = S_fileName

	v_tic()

	FBinRead refnum, vsansStr
	FBinRead/F=2/U refnum, revision
	FBinRead/F=2/U refnum, offset
	FBinRead/F=2/U refnum, time1
	FBinRead/F=2/U refnum, time2
	FBinRead/F=2/U refnum, time3
	FBinRead/F=2/U refnum, time4
	FBinRead/F=2/U refnum, time5
	FBinRead refnum, detStr //NOTE - the example data file Phil sent skipped the detStr (no placeholder!)
	FBinRead/F=2/U refnum, volt
	FBinRead/F=3/U refnum, resol

	FStatus refnum
	FSetPos refnum, V_logEOF

	Close refnum

	// number of data bytes
	num = V_logEOF - offset
	Print "Number of data values = ", num / 8

	GBLoadWave/B/T={192, 192}/W=1/S=(offset) filename // intel, little-endian
	//	GBLoadWave/T={192,192}/W=1/S=(offset) filename			// motorola, big-endian

	Duplicate/O $(StringFromList(0, S_waveNames)), V_Events
	KillWaves/Z $(StringFromList(0, S_waveNames))
	v_toc()

	Print vsansStr
	Print revision
	Print offset
	Print time1
	Print time2
	Print time3
	Print time4
	Print time5
	Print detStr
	print volt
	print resol

	return (0)
End

//
//
//
Function V_MakeFakeEventWave_TOF(variable delayTime, variable std)

	variable num, ii, jj, numRepeat

	num       = 1000
	numRepeat = 1000

	//	delayTime = 50		//microseconds
	//	std = 4					//std deviation, microseconds

	//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=(num * numRepeat) eventWave
	eventWave = 0

	Make/O/D/N=(num) arrival

	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit

	uint64 i64_num, b1, b2, b3, b4, b5, b6, b7, b8
	uint64 i64_ticks, i64_start

	//	i64_start = ticks
	i64_ticks = 0
	for(jj = 0; jj < numRepeat; jj += 1)
		arrival = delayTime + gnoise(std)
		sort arrival, arrival
		arrival *= 1000 //milliseconds now

		for(ii = 0; ii < num; ii += 1)
			//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)
			b1 = trunc(abs(enoise(192))) //since truncated, need 192 as highest random to give 191 after trunc
			b2 = trunc(abs(enoise(128))) // same here, to get results [0,127]

			i64_ticks = trunc(arrival[ii])

			//			b2 = b2 << 48
			//			b1 = b1 << 56

			// don't shift b1
			b2        = b2 << 8
			i64_ticks = i64_ticks << 16

			i64_num                  = b1 + b2 + i64_ticks
			eventWave[jj * num + ii] = i64_num
		endfor

	endfor

	return (0)
End

// TODO:
//
// There may be memory issues with this
//
// -- do I want to do the time binning first?
// -- does it really matter?
//
Function V_SortAndSplitFakeEvents()

	WAVE eventTime = root:EventTime
	WAVE location  = root:location
	WAVE tube      = root:tube

	Sort tube, tube, eventTime, location

	variable b1, e1, b2, e2, b3, e3, b4, e4
	FindValue/S=0/I=48 tube
	b1 = 0
	e1 = V_Value - 1
	b2 = V_Value
	FindValue/S=(b2)/I=96 tube
	e2 = V_Value - 1
	b3 = V_Value
	FindValue/S=(b3)/I=144 tube
	e3 = V_Value - 1
	b4 = V_Value
	e4 = numpnts(tube) - 1

	Print b1, e1
	Print b2, e2
	Print b3, e3
	Print b4, e4

	//	tube and location become x and y, and can be byte data
	// eventTime still needs to be 64 bit - when do I convert it to FP?
	Make/O/B/U/N=(e1 - b1 + 1) tube1, location1
	Make/O/L/U/N=(e1 - b1 + 1) eventTime1

	Make/O/B/U/N=(e2 - b2 + 1) tube2, location2
	Make/O/L/U/N=(e2 - b2 + 1) eventTime2

	Make/O/B/U/N=(e3 - b3 + 1) tube3, location3
	Make/O/L/U/N=(e3 - b3 + 1) eventTime3

	Make/O/B/U/N=(e4 - b4 + 1) tube4, location4
	Make/O/L/U/N=(e4 - b4 + 1) eventTime4

	tube1 = tube[p + b1]
	tube2 = tube[p + b2]
	tube3 = tube[p + b3]
	tube4 = tube[p + b4]

	location1 = location[p + b1]
	location2 = location[p + b2]
	location3 = location[p + b3]
	location4 = location[p + b4]

	eventTime1 = eventTime[p + b1]
	eventTime2 = eventTime[p + b2]
	eventTime3 = eventTime[p + b3]
	eventTime4 = eventTime[p + b4]

	KillWaves/Z eventTime, location, tube

	return (0)
End

///////////////////////////////////////////////////////////

//////////////////////

// functions for testing the arrival time (reversal) seen in stream event data
// JAN 2021

// function to take the first 200 (or different number) of event points and
// mark them for which panel they are associated with
//
// after V_Group_as_Panel()
// - use the Event_per_Panel() graph macro to plot the data, marking each different
// panel with a different color.
//
//
// it is clear that the time reversals are ocurring when data is read from a different panel.
//
// there are long stretches in time where the data is exclusively from a single panel - quite
// improbable.
//
// sorting the time values makes the panel order much more random, as I would expect.
// (but is this the correct treatment?)
//
// -- I need to talk with Phil and find out if this is the expected behavior of "blocks" of data
// read in from each panel (from a buffer?)
//
// if numPt = -1, then the entire wave is used
Proc V_EventStream_by_Panel(numPt)
	variable numPt = 1000

	V_Group_as_Panel(numPt) //currently hard-wired as the first 200 points
	V_PlotEvent_per_Panel()

EndMacro

//
// this function takes a portion of the event stream and based on the tube number (0,191)
// assigns each event the correct panel (1,2,3,4) since all of the events for the 4 panels
// arrive in the same stream, but as it turns out, not necessarily in chronological order!
//
// if numPt = -1, then the entire wave is used
Function V_Group_as_Panel(variable numPt)

	SetDataFolder root:Packages:NIST:VSANS:Event:
	WAVE tube = tube
	//	Wave timePt=timePt
	WAVE rescaledTime = rescaledTime
	if(numPt == -1)
		Duplicate/O tube, tube_panel
		Duplicate/O rescaledTime, rescaledTime_panel
	else
		Duplicate/O/R=[0, (numPt - 1)] tube, tube_panel
		Duplicate/O/R=[0, (numPt - 1)] rescaledTime, rescaledTime_panel
	endif

	WAVE w  = tube_panel
	WAVE ti = rescaledTime_panel

	// do strictly in this order, so that the reassignment works
	// wave is unsigned byte
	// max tube number is 191, so assign to a larger number temporarily
	MultiThread w = (w[p] < 48) ? 201 : w[p]
	MultiThread w = (w[p] < 96) ? 202 : w[p]
	MultiThread w = (w[p] < 144) ? 203 : w[p]
	MultiThread w = (w[p] < 192) ? 204 : w[p]
	MultiThread w -= 200

	//	Variable num=numpnts(w)
	//	Variable ii,val
	//
	//	for(ii=0;ii<num;ii+=1)
	//		val=0
	//		if(w[ii] < 48)
	//			val = 1
	//		endif
	//		if(w[ii] > 47 && w[ii] < 96)
	//			val = 2
	//		endif
	//		if(w[ii] > 95 && w[ii] < 144)
	//			val = 3
	//		endif
	//		if(w[ii] > 143)
	//			val = 4
	//		endif
	//
	//		w[ii] = val
	//
	//	endfor
	SetDataFolder root:

	return (0)
End

Proc V_PlotEvent_per_Panel()

	DoWindow/F EventPerPanel
	if(V_Flag == 0)
		SetDataFolder root:Packages:NIST:VSANS:Event:
		PauseUpdate; Silent 1 // building window...
		Display/W=(34.8, 42.2, 543, 371)/K=1 rescaledTime_panel
		DoWindow/C EventPerPanel
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph msize=3
		ModifyGraph gaps=0
		ModifyGraph useMrkStrokeRGB=1
		ModifyGraph zColor(rescaledTime_panel)={tube_panel, *, *, Rainbow16}
		ModifyGraph grid=1
		ModifyGraph mirror=2
		Label left, "Time (s)"
		Label bottom, "neutron event"
		SetAxis left, 0, *
		//	SetAxis bottom *,100
		TextBox/C/N=text0/A=MC/X=40.42/Y=4.51 "Right = Red\rTop = Yellow\rBottom = Blue\rLeft = Purple"
		//	Tag/C/N=text1/X=-17.82/Y=4.69 rawTime_panel, 87, "Bottom"
		//	Tag/C/N=text2/X=-11.49/Y=16.13 rawTime_panel, 44, "Top"
		//	Tag/C/N=text3/X=-12.48/Y=23.75 rawTime_panel, 65, "Right"
		//	Tag/C/N=text4/X=-17.43/Y=18.18 rawTime_panel, 38, "Left"
	endif
	SetDataFolder root:
EndMacro

//////////////////////
//
// This test function looks for time reversal in a single panel
//
// 1) given a number of points, duplicate the time + tube number
// 2) replace tube number with panel 1,2,3, or 4
// 3) for the chosen panel number, keep only the times for than panel, all others set to NaN
// 4) differentate the time. NaN are skipped in the differential
//
// It seems that there are a few "bad" time points, but not that many, and nothing systematic.
//
// runs rather quickly, only a few seconds with 1e6 points
//
// panelVal = 1,2,3,4
// numPt = number of points to duplicate
Function V_Differentiate_onePanel(variable panelVal, variable numPt)

	SetDataFolder root:Packages:NIST:VSANS:Event:
	WAVE tube         = tube
	WAVE rescaledTime = rescaledTime
	if(numPt == -1)
		Duplicate/O tube, tube_panel
		Duplicate/O rescaledTime, rescaledTime_panel
	else
		Duplicate/O/R=[0, (numPt - 1)] tube, tube_panel
		Duplicate/O/R=[0, (numPt - 1)] rescaledTime, rescaledTime_panel
	endif

	WAVE w  = tube_panel
	WAVE ti = rescaledTime_panel

	// do strictly in this order, so that the reassignment works
	// wave is unsigned byte
	// max tube number is 191, so assign to a larger number temporarily
	MultiThread w = (w[p] < 48) ? 201 : w[p]
	MultiThread w = (w[p] < 96) ? 202 : w[p]
	MultiThread w = (w[p] < 144) ? 203 : w[p]
	MultiThread w = (w[p] < 192) ? 204 : w[p]
	MultiThread w -= 200

	//	Variable num=numpnts(w)
	//	Variable ii,val
	//
	//
	//	for(ii=0;ii<num;ii+=1)
	//		val=0
	//		if(w[ii] < 48)
	//			val = 1
	//		endif
	//		if(w[ii] > 47 && w[ii] < 96)
	//			val = 2
	//		endif
	//		if(w[ii] > 95 && w[ii] < 144)
	//			val = 3
	//		endif
	//		if(w[ii] > 143)
	//			val = 4
	//		endif
	//
	//		w[ii] = val
	//
	//	endfor

	//
	V_KeepOneGroup(panelVal)

	SetDataFolder root:Packages:NIST:VSANS:Event:
	WAVE onePanel = onePanel //generated in V_KeepOneGroup()

	// differentiate and plot
	Differentiate onePanel/D=onePanel_DIF

	DoWindow/F V_OnePanel_Differentiated
	if(V_flag == 0)
		Display/N=V_OnePanel_Differentiated/K=1 onePanel_DIF
		Legend
		Modifygraph gaps=0
		//		ModifyGraph zero(left)=1
		Label left, "\\Z14Delta (dt/event)"
		Label bottom, "\\Z14Event number"
	endif

	Duplicate/O onePanel_DIF, tmp
	tmp = 0
	MultiThread tmp = (onePanel_DIF < 0) ? 1 : 0

	//	Print "total # bad points = ",sum(tmp)
	//	Print "fraction bad points = ",sum(tmp)/numpnts(tmp)

	// want to make a wave directly withe the negative onePanel_DIF point values
	// rather than rely on FindLevels, which seems to miss too many points
	//
	// and a second wave with the actual (negative) time values so I can
	// directly get the "bad" times without needing to do the math
	//
	variable ii, jj
	variable numBadPt = sum(tmp)
	Make/O/D/N=(numBadPt) badPoints, badTime

	//v_tic()
	ii = 0
	jj = 0
	for(ii = 0; ii < numpnts(tmp); ii += 1)
		if(tmp[ii] == 1)
			badPoints[jj] = ii
			badTime[jj]   = onePanel_DIF[ii]
			jj           += 1
		endif
	endfor
	//v_toc()

	//
	//// slightly faster (<1 s for 15M events), but misses a few steps
	//v_tic()
	//	Make/O/D/N=0 badPoints
	//	FindLevels/P/Q/D=badPoints/EDGE=1 onePanel_DIF, 0
	//	if (V_LevelsFound)
	//		Print "numLevels = ",V_LevelsFound
	//		badPoints = trunc(badPoints)
	////		Print destWave
	//	endif
	//v_toc()

	KillWaves/Z tmp

	SetDataFolder root:

	return (0)
End

// as a proc
// panelVal = 1,2,3,4
//
Proc pV_Differentiate_onePanel(panelVal, numPt)
	variable panelVal, numpt
	V_Differentiate_onePanel(panelVal, numPt)
EndMacro

Function V_KeepOneGroup(variable panelVal)

	SetDataFolder root:Packages:NIST:VSANS:Event:

	WAVE w  = tube_panel
	WAVE ti = rescaledTime_panel

	Duplicate/O ti, onePanel
	WAVE one = onePanel
	one = 0

	MultiThread one = (w[p] == panelVal) ? ti[p] : NaN

	SetDataFolder root:

	return (0)
End

//File byte offset		Size (bytes)		Value				Description
//		0							5	 			'VSANS'				magic number
//		5							2				0xMajorMinor		Revision number = 0x00
//		7							2				n bytes				Offset to data in bytes
//		9							10				IEEE1588 - UTC	time origin for timestamp, IEEE1588 UTC
//		19							1	 			'F'/'M'/'R'			detector carriage group
//		20							2				HV (V)				HV Reading in Volt
//		22							4				clk (Hz)				timestamp clock frequency in Hz
//		26							N				tubeID				disabled tubes # ; 1 byte/tube if any
//
//
// Feb 2021
// !! per Phil, bug causes time stamp to be 12 bytes - but what happens to the remaing data?
//
//
//	This is the current header from file 20201119164154001_0.hst on vsansdet1:
//
//	56 53 41 4e 53 00 00 1b  00 40 3a 19 10 b3 e6 b6
//	5f 00 00 00 00 d2 05 80  96 98 00
//
//	(5 b)  56 53 41 4e 53: VSANS – magic number
//	(2 b)  00 00: file format revision
//	(2 b)  1b  00: byte offset in file to event data
//	(12 b)  40 3a 19 10 b3 e6 b6  5f 00 00 00 00 : time of origin (12 bytes instead of 10 as described in doc)
//	(2 b)  d2 05: HV Value  (0x05d2 = 1490)
//	(4 b)  80 96 98 00: timestamp clock frequency (0x989680 = 10000000)

Function V_ReadEventHeader()

	string gVSANSStr = ""
	string gDetStr   = ""
	gVSANSStr = PadString(gVSANSStr, 5, 0x20) //pad to 5 bytes
	gDetStr   = PadString(gDetStr, 1, 0x20)   //pad to 1 byte

	variable gRevision, gOffset, gTime1, gTime2, gTime3, gTime4, gTime5, gVolt, gResol, gTime6
	variable refnum, ii
	string filePathStr = ""

	Make/O/B/U/N=27 byteWave

	Open/R refnum as filepathstr

	FBinRead refnum, gVSANSStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
	FBinRead/F=2/U/B=3 refnum, gTime6
	//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol

	FStatus refnum
	FSetPos refnum, V_logEOF

	Close refnum

	Print "string = ", gVSANSStr
	Print "revision = ", gRevision
	Print "offset = ", gOffset
	Print "time part 1 = ", gTime1
	Print "time part 2 = ", gTime2
	Print "time part 3 = ", gTime3
	Print "time part 4 = ", gTime4
	Print "time part 5 = ", gTime5
	Print "time part 6 = ", gTime6
	//	Print "det group = ",gDetStr
	Print "voltage (V) = ", gVolt
	Print "clock freq (Hz) = ", gResol

	print "1/freq (s) = ", 1 / gResol

	//// read all as a byte wave
	Make/O/B/U/N=27 byteWave

	Open/R refnum as filepathstr

	FBinRead refnum, byteWave

	FStatus refnum
	FSetPos refnum, V_logEOF

	Close refnum

	for(ii = 0; ii < numpnts(byteWave); ii += 1)
		printf "%X  ", byteWave[ii]
	endfor
	printf "\r"

	return (0)
End

Proc V_EstFrameOverlap(lambda, fwhm, sdd)
	variable lambda = 6
	variable fwhm   = 0.12
	variable sdd    = 13
	V_FrameOverlap(lambda, fwhm, sdd)
EndMacro

//fwhm = 2.355 sigma of the Gaussian
// two standard deviations = 95% of distribution
//
// lam =5A, fwhm = 0.138, sdd=13.7m
//
Function V_FrameOverlap(variable lam, variable fwhm, variable sdd)

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
Function V_EventWaveCleanup()

	if(exists("root:Packages:NIST:VSANS:Event:rescaledTime") == 0)
		// no event data exists, exit
		return (0)
	endif

	SetDataFolder root:Packages:NIST:VSANS:Event:
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
//Duplicate/O :Packages:NIST:VSANS:Event:rescaledTime,rescaledTime_samp;DelayUpdate
//Resample/DOWN=1000 rescaledTime_samp;DelayUpdate
//
//
