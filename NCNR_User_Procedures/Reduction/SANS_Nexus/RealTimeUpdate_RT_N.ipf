#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma version=5.0
#pragma IgorVersion=6.1

//
// JUNE 2022
//
// This file and RT operations have been updated for the Nexus file
// -- but has not been tested - since I do not know what the file strucure of the "live"
// file will be - I'm assuming that it will be Nexus, and will be populated with
// all of the correct (available) metadata
//
//

//*****************************
// Vers. 1.0 100401
//
// hook function and associated procedures that interact with the user
// and the RealTime_SANS window
// -displays pixel counts
// - displays Q, qx, qy values
// - displays q axes and pixel axes
//
// - of course, displays the detector image, w/ nice colors, legend, sliders to adjust color mapping
// and a control bar to let the user adjust scaling, do averaging...
//
// as of 110101, the help file has not been written
//
//
//
// for Summer School 2011 --- a fake update
// 1) set the flag
// Variable/G root:myGlobals:gFakeUpdate=1
// 2) load any data file as the RT data
// 3) get SASCALC set up to the correct configuration
// 4) run ClearRTFolder() to empty out the SAS folder, and update the display
// 5) start the updating
//
// -- generate a script that will (from scratch) open everything needed, open/hide windows
// as needed, and be sure that all of the files, varaibles, etc. that are needed are actually there.
//
// --needs SASCALC + an analysis model for it to work, and still some details to work out for
// smooth initialization of the process, but it should work.
//
//
//
//Proc Init_FakeRT()
//	pInit_FakeRT()
//End

//Proc Clear_RT_Folder()
//	ClearRTFolder()
//End

//
//
//*****************************

// takes care of all of the necessary initialization for the RT control process
// creates the folders, etc. that are needed for the SANS reduction package as well, but the end user
// doesn't need to see this.
//
// only used for testing - as this will re-initialize everything, including globals used as preferences
//
Proc Init_for_RealTime()
	// initialize the reduction folders as for normal SANS Reduction, but don't draw the main Reduction control panel
	DoWindow/K RT_Panel
	InitFolders()
	InitFakeProtocols()
	InitGlobals()
	N_InitFacilityGlobals()

	// specific for RealTime display
	//set the current display type to RealTime
	string/G root:myGlobals:gDataDisplayType = "RealTime"
	// draw the RealTime control panel
	Show_RealTime_Panel()
EndMacro

// Proc to bring the RT control panel to the front, always initializes the panel
// - always initialize to make sure that the background task is properly set
//
Proc Show_RealTime_Panel()
	Init_RT() //always init, data folders and globals are created here
	DoWindow/F RT_Panel
	if(V_flag == 0)
		RT_Panel()
	endif
EndMacro

// folder and globals that are needed ONLY for the RT process
//
Function Init_RT()

	//create folders
	NewDataFolder/O root:Packages:NIST:RealTime
	NewDataFolder/O/S root:myGlobals:RT
	//create default globals only if they don't already exist, so you don't overwrite user-entered values.
	NVAR/Z xCtr = xCtr
	if(NVAR_Exists(xctr) == 0)
		variable/G xCtr = 110 //pixels
	endif
	NVAR/Z yCtr = yCtr
	if(NVAR_Exists(yCtr) == 0)
		variable/G yCtr = 64
	endif
	NVAR/Z SDD = SDD
	if(NVAR_Exists(SDD) == 0)
		variable/G SDD = 3.84 //in meters
	endif
	NVAR/Z lambda = lambda
	if(NVAR_Exists(lambda) == 0)
		variable/G lambda = 6 //angstroms
	endif
	NVAR/Z updateInt = updateInt
	if(NVAR_Exists(updateInt) == 0)
		variable/G updateInt = 5 //seconds
	endif
	NVAR/Z timeout = timeout
	if(NVAR_Exists(timeout) == 0)
		variable/G timeout = 300 //seconds
	endif
	NVAR/Z elapsed = elapsed
	if(NVAR_Exists(elapsed) == 0)
		variable/G elapsed = 0
	endif
	NVAR/Z totalCounts = totalCounts //total detector counts
	if(NVAR_Exists(totalCounts) == 0)
		variable/G totalCounts = 0
	endif
	NVAR/Z countTime = root:myGlobals:RT:countTime
	if(NVAR_Exists(countTime) == 0)
		variable/G countTime = 0
	endif
	NVAR/Z countRate = root:myGlobals:RT:countRate
	if(NVAR_Exists(countRate) == 0)
		variable/G countRate = 0
	endif
	NVAR/Z monitorCountRate = root:myGlobals:RT:monitorCountRate
	if(NVAR_Exists(monitorCountRate) == 0)
		variable/G monitorCountRate = 0
	endif
	NVAR/Z monitorCounts = root:myGlobals:RT:monitorCounts
	if(NVAR_Exists(monitorCounts) == 0)
		variable/G monitorCounts = 0
	endif

	// set the explicit path to the data file on "relay" computer (the user will be propmted for this)
	SVAR/Z RT_fileStr = RT_fileStr
	if(SVAR_Exists(RT_fileStr) == 0)
		string/G RT_fileStr = ""
	endif

	// set the background task
	AssignBackgroundTask()

	SetDataFolder root:
End

//sets the background task and period (in ticks)
//
Function AssignBackgroundTask()

	variable updateInt = NumVarOrDefault("root:myGlobals:RT:updateInt", 5)
	// set the background task
	SetBackground BkgUpdateHST()
	CtrlBackground period=(updateInt * 60), noBurst=0 //noBurst prevents rapid "catch-up calls
	return (0)
End

//draws the RT panel and enforces bounds on the SetVariable controls for update period and timeout
//
Proc RT_Panel()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(300, 350, 602, 580)/K=2
	DoWindow/C RT_Panel
	DoWindow/T RT_Panel, "Real Time Display Controls"
	ModifyPanel cbRGB=(65535, 52428, 6168)
	SetDrawLayer UserBack
	SetDrawEnv fstyle=1
	DrawText 26, 21, "Enter values for real-time display"
	Button bkgStart, pos={171, 54}, size={120, 20}, proc=UpdateHSTButton, title="Start Updating"
	Button bkgStart, help={"Starts or stops the updating of the real-time SANS image"}
	//	SetVariable setvar_0,pos={15,29},size={100,15},proc=RT_Param_SetVarProc,title="X Center"
	//	SetVariable setvar_0,help={"Set this to the current beamcenter x-coordinate (in pixels)"}
	//	SetVariable setvar_0,limits={0,128,0},value= root:myGlobals:RT:xCtr
	//	SetVariable setvar_1,pos={14,46},size={100,15},proc=RT_Param_SetVarProc,title="Y Center"
	//	SetVariable setvar_1,help={"Set this to the current beamcenter y-coordinate (in pixels)"}
	//	SetVariable setvar_1,limits={0,128,0},value= root:myGlobals:RT:yCtr
	//	SetVariable setvar_2,pos={14,64},size={100,15},proc=RT_Param_SetVarProc,title="SDD (m)"
	//	SetVariable setvar_2,help={"Set this to the sample-to-detector distance of the current instrument configuration"}
	//	SetVariable setvar_2,limits={0,1600,0},value= root:myGlobals:RT:SDD
	//	SetVariable setvar_3,pos={15,82},size={100,15},proc=RT_Param_SetVarProc,title="Lambda (A)"
	//	SetVariable setvar_3,help={"Set this to the wavelength of the current instrument configuration"}
	//	SetVariable setvar_3,limits={0,30,0},value= root:myGlobals:RT:lambda
	SetVariable setvar_4, pos={11, 31}, size={150, 20}, proc=UpdateInt_SetVarProc, title="Update Interval (s)"
	SetVariable setvar_4, help={"This is the period of the update"}
	SetVariable setvar_4, limits={1, 3600, 0}, value=root:myGlobals:RT:updateInt
	//	SetVariable setvar_5,pos={11,56},size={150,20},title="Timeout Interval (s)"
	//	SetVariable setvar_5,help={"After the timeout interval has expired, the update process will automatically stop"}
	//	SetVariable setvar_5,limits={1,3600,0},value= root:myGlobals:RT:timeout
	Button button_1, pos={170, 29}, size={120, 20}, proc=LoadRTButtonProc, title="Load Live Data"
	Button button_1, help={"Load the data file for real-time display"}
	Button button_2, pos={250, 2}, size={30, 20}, proc=RT_HelpButtonProc, title="?"
	Button button_2, help={"Display the help file for real-time controls"}

	SetVariable setvar_6, pos={11, 105}, size={250, 20}, title="Total Detector Counts"
	SetVariable setvar_6, help={"Total counts on the detector, as displayed"}, noedit=1
	SetVariable setvar_6, limits={0, Inf, 0}, value=root:myGlobals:RT:totalCounts
	SetVariable setvar_7, pos={11, 82}, size={250, 20}, title="                  Count Time"
	SetVariable setvar_7, help={"Count time, as displayed"}, noedit=1
	SetVariable setvar_7, limits={0, Inf, 0}, value=root:myGlobals:RT:countTime
	SetVariable setvar_8, pos={11, 127}, size={250, 20}, title="  Detector Count Rate"
	SetVariable setvar_8, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_8, limits={0, Inf, 0}, value=root:myGlobals:RT:countRate
	SetVariable setvar_9, pos={11, 149}, size={250, 20}, title="           Monitor Counts"
	SetVariable setvar_9, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_9, limits={0, Inf, 0}, value=root:myGlobals:RT:monitorCounts
	SetVariable setvar_10, pos={11, 171}, size={250, 20}, title="    Monitor Count Rate"
	SetVariable setvar_10, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_10, limits={0, Inf, 0}, value=root:myGlobals:RT:monitorCountRate

	Button button_3, pos={230, 195}, size={60, 20}, proc=RT_DoneButtonProc, title="Done"
	Button button_3, help={"Closes the panel and stops the updating process"}
EndMacro

//
Proc RT_HelpButtonProc(ctrlName) : ButtonControl
	string ctrlName
	//	DoAlert 0,"the help file has not been written yet :-("
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Real Time Data Display]"
EndMacro

//close the panel gracefully, and stop the background task if necessary
//
Proc RT_DoneButtonProc(ctrlName) : ButtonControl
	string ctrlName

	BackgroundInfo
	if(V_Flag == 2) //task is currently running
		CtrlBackground stop
	endif
	DoWindow/K RT_Panel
EndMacro

//prompts for the RT data file - only needs to be set once, then the user can start/stop
//
Function LoadRTButtonProc(string ctrlName) : ButtonControl

	DoAlert 0, "The RealTime detector image is located on charlotte"
	Read_RT_File("Select the Live Data file")
	return (0)
End

// Sets "fake" header information to allow qx,qy scales on the graph, and to allow
// averaging to be done on the real-time dataset
//
// keep in mind that only the select bits of header information that is USER-SUPPLIED
// on the panel is available for calculations. The RT data arrives at the relay computer
// with NO header, only the 128x128 data....
//
// see also FillFakeHeader() for a few constant header values ...
//
//
// check on a case-by-case basis
Function RT_Param_SetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	strswitch(ctrlName) // string switch
		case "setvar_0": //xCtr
			putDet_beam_center_x("RealTime", varNum)
			//			rw[16]=varNum
			break
		case "setvar_1": //yCtr
			putDet_beam_center_y("RealTime", varNum)
			//			rw[17]=varNum
			break
		case "setvar_2": //SDD
			putDet_distance("RealTime", varNum)
			//			rw[18]=varNum
			break
		case "setvar_3": //lambda
			putWavelength("RealTime", varNum)
			//			rw[26]=varNum
			break
		default:
			// FIXME(BugproneMissingSwitchDefaultCase)
			break
	endswitch
	//only update the graph if it is open, and is a RealTime display...
	if(WinType("SANS_Data") == 0)
		return (0) //SANS_Data window not open
	endif
	SVAR type = root:myGlobals:gDataDisplayType
	if(cmpstr("RealTime", type) != 0)
		return (0) //display not RealTime
	endif
	fRawWindowHook() //force a redraw of the graph
	DoWindow/F RT_Panel //return panel to the front
	return (0)
End

// (re)-sets the period of the update background task
//
Function UpdateInt_SetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	//	BackgroundInfo
	//	if(V_flag==2)
	//		CtrlBackground stop
	//	Endif

	// quite surprised that you can change the period of repeat while the task is active
	CtrlBackground period=(varNum * 60), noBurst=1
	return (0)
End

/////////////////////////////
//simple, main entry procedure that will load a HST sans data file (not a work file)
//into the RealTime dataFolder
//(typically called from main panel button)
//
//(ununsed)
Proc Load_RT_Data()
	string msgStr = "Select the RT data file"
	Read_RT_File(msgStr)
EndMacro

//function called by the main entry procedure (the load button)
//sets global display variable, reads in the data, and displays it
//aborts if no file was selected
//
//(re)-sets the GLOBAL path:filename of the RT file to update
// also resets the path to the RT file, so that the dialog brings you back to the right spot
//
// reads the data in if all is OK
//
Function Read_RT_File(string msgStr)

	string filename = ""
	string pathStr  = ""
	variable refnum

	//check for the path
	PathInfo RT_Path
	if(V_Flag == 1) //	/D does not open the file
		Open/D/R/T="????"/M=(msgStr)/P=RT_Path refNum
	else
		Open/D/R/T="????"/M=(msgStr) refNum
	endif
	filename = S_FileName //get the filename, or null if canceled from dialog
	if(strlen(filename) == 0)
		//user cancelled, abort
		SetDataFolder root:
		Abort "No file selected, action aborted"
	endif

	//set the globals and reset the RT_Path value
	pathStr = N_GetPathStrFromfullName(filename)
	NewPath/O RT_Path, pathStr
	variable/G root:Packages:NIST:RealTime:gIsLogScale = 0        //force data to linear scale (1st read)
	string/G   root:myGlobals:RT:RT_fileStr            = filename //full path:file of the Run.hst file to re-read
	//read in the data
	//ReadOrdelaHST(filename)

	LoadRawSANSData(filename, "RAW")
	Raw_to_Work_for_Tubes("RealTime")

	//the calling macro must change the display type
	string/G root:myGlobals:gDataDisplayType = "RealTime" //displayed data type is RealTime

	//FillFakeHeader() 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	WAVE   data             = getDetectorDataW("RealTime") //this will be the linear data
	NVAR   totCounts        = root:myGlobals:RT:totalCounts
	NVAR   countTime        = root:myGlobals:RT:countTime
	NVAR   countRate        = root:myGlobals:RT:countRate
	NVAR   monitorCounts    = root:myGlobals:RT:monitorCounts
	NVAR   monitorCountRate = root:myGlobals:RT:monitorCountRate
	SVAR/Z title            = root:myGlobals:gCurDispFile

	title = "Real-Time : " + filename
	//sum the total counts, global variable will automatically update
	WAVE/Z linear_data = getDetectorDataW("RealTime") //this will be the linear data

	if(WaveExists(linear_data))
		totCounts = sum(linear_data, -Inf, Inf)
	else
		WAVE/Z data = getDetectorDataW("RealTime") //this will be the linear data
		totCounts = sum(data, -Inf, Inf)
	endif
	//Update other live values

	countTime        = getCount_time("RealTime")
	countRate        = totCounts / countTime
	monitorCounts    = getBeamMonNormData("RealTime")
	monitorCountRate = monitorCounts / countTime

	fRawWindowHook()

	// set the SANS_Data graph to "live" mode to allow fast updating
	//fRawWindowHook just drew the graph, so it should exist
	ModifyGraph/W=SANS_Data live=1 //not much speed help...

	return (0)
End

////function that does the guts of reading the binary data file
////fname is the full path:name;vers required to open the file
////The final root:Packages:NIST:RealTime:data wave is the real
////neutron counts and can be directly used
////
////returns 0 if read was ok
////returns 1 if there was an error
//Function ReadOrdelaHST(fname)
//	String fname
//	//this function is for reading in RealTime data only, so it will always put data in RealTime folder
//	SetDataFolder "root:Packages:NIST:RealTime"
//	//keep a string with the filename in the RealTime folder
//	String/G root:Packages:NIST:RealTime:fileList = "Real-Time Data Display"
//	//get log/linear state based on SANS_Data window
//	Variable isLogScale=NumVarOrDefault("root:Packages:NIST:RealTime:gIsLogScale", 0)
//	Variable/G root:Packages:NIST:RealTime:gIsLogScale = isLogScale		//creates if needed, "sets" to cur val if already exists
//
//	Variable refNum=0,ii,p1,p2,tot,num=128
//	String str=""
//	Make/O/T/N=11 hdrLines
//	Make/O/I/N=(num*num) a1		// /I flag = 32 bit integer data
//
//	//full filename and path is now passed in...
//	//actually open the file
//	Open/R/Z refNum as fname		// /Z flag means I must handle open errors
//	if(refnum==0)		//FNF error, get out
//		DoAlert 0,"Could not find file: "+fname
//		Close/A
//		return(1)
//	endif
//	if(V_flag!=0)
//		DoAlert 0,"File open error: V_flag="+num2Str(V_Flag)
//		Close/A
//		return(1)
//	Endif
//	// as of 12MAY03, the run.hst for real-time display has no header lines (M. Doucet)
////	for(ii=0;ii<11;ii+=1)		//read (or skip) 11 header lines
////		FReadLine refnum,str
////		hdrLines[ii]=str
////	endfor
//	// 4-byte integer binary data follows, num*num integer values
//	FBinRead/B=3/F=3 refnum,a1
//	//
//	Close refnum
//
//	//we want only the first [0,127][0,127] quadrant of the 256x256 image
//	// this is done most quickly by two successive redimension operations
//	// (the duplicate is for testing only)
//	//final redimension can make the data FP if desired..
//	//Redimension/N=(256,256) a1
//	Redimension/N=(128,128) a1
//
//	if(exists("root:Packages:NIST:RealTime:data")!=1)		//wave DN exist
//		Make/O/N=(128,128) $"root:Packages:NIST:RealTime:data"
//	endif
//	Wave data = getDetectorDataW("RealTIme")		//this will be the linear data
////	Duplicate/O data,$"root:Packages:NIST:RealTime:linear_data"
////	WAVE lin_data=$"root:Packages:NIST:RealTime:linear_data"
////	lin_data=a1
////	if(isLogScale)
////		data=log(a1)
////	else
//		data=a1
////	Endif
//
//	KillWaves/Z a1
//
//	//return the data folder to root
//	SetDataFolder root:
//
//	Return 0
//End

// fills the "default" fake header so that the SANS Reduction machinery does not have to be altered
// pay attention to what is/not to be trusted due to "fake" information
//
//Function FillFakeHeader()
//
//	Make/O/N=23 $"root:Packages:NIST:RealTime:IntegersRead"
//	Make/O/N=52 $"root:Packages:NIST:RealTime:RealsRead"
//	Make/O/T/N=11 $"root:Packages:NIST:RealTime:TextRead"
//
//	Wave intw=$"root:Packages:NIST:RealTime:IntegersRead"
//	Wave realw=$"root:Packages:NIST:RealTime:RealsRead"
//	Wave/T textw=$"root:Packages:NIST:RealTime:TextRead"
//
//	//Put in appropriate "fake" values
//	// first 4 are user-defined on the Real Time control panel, so user has the opportunity to change these values.
//	//
//	realw[16]=NumVarOrDefault("root:myGlobals:RT:xCtr", 64.5)		//xCtr(pixels)
//	realw[17]=NumVarOrDefault("root:myGlobals:RT:yCtr", 64.5)		//yCtr (pixels)
//	realw[18]=NumVarOrDefault("root:myGlobals:RT:SDD", 5)		//SDD (m)
//	realw[26]=NumVarOrDefault("root:myGlobals:RT:lambda", 6)		//wavelength (A)
//	//
//	// necessary values
//	realw[10]=5			//detector calibration constants, needed for averaging
//	realw[11]=10000
//	realw[13]=5
//	realw[14]=10000
//	//
//	// used in the resolution calculation, ONLY here to keep the routine from crashing
//	realw[20]=65		//det size
//	realw[27]=0.15	//delta lambda
//	realw[21]=50.8	//BS size
//	realw[23]=50		//A1
//	realw[24]=12.7	//A2
//	realw[25]=8.57	//A1A2 distance
//	realw[4]=1		//trans
//	realw[3]=0		//atten
//	realw[5]=0.1		//thick
//	//
//	//
//	realw[0]=1e8		//def mon cts
//
//	// fake values to get valid deadtime and detector constants
//	//
//	textw[9]="ORNL  "		//6 characters
//	textw[3]="[NGxSANS00]"	//11 chars, NGx will return default values for atten trans, deadtime...
//
//	return(0)
//End

// action procedure to start/stop the updating process.
//checks for update display graph, current background task, etc..
// then update the button and at last controls the background task
//
Function UpdateHSTButton(string ctrlName) : ButtonControl

	//check that the RT window is open, and that the display type is "RealTime"
	if(WinType("SANS_Data") == 0)
		return (1) //SANS_Data window not open
	endif
	SVAR type = root:myGlobals:gDataDisplayType
	if(cmpstr("RealTime", type) != 0)
		return (1) //display not RealTime
	endif
	//check the current state of the background task
	BackgroundInfo //returns 0 if no task defined, 1 if idle, 2 if running
	if(V_flag == 0)
		AssignBackgroundTask()
	endif

	string Str = ""
	//control the task, and update the button text
	if(cmpstr(ctrlName, "bkgStart") == 0)
		Button $ctrlName, win=RT_Panel, title="Stop Updating", rename=bkgStop
		//	Start the updating - BkgUpdateHST() has been designated as the background task
		CtrlBackground start
	else
		Button $ctrlName, win=RT_Panel, title="Start Updating", rename=bkgStart
		NVAR elapsed = root:myGlobals:RT:elapsed
		elapsed = 0 //reset the timer
		//	Stop the updating
		CtrlBackground stop
	endif
	return (0)
End

// THIS IS THE BACKGROUND TASK
//
// simply re-reads the designated .hst file (which can be located anywhere, as long as it
// appears as a local disk)
// return value of 0 continues background execution
// return value of 1 turns background task off
//
Function BkgUpdateHST()

	WAVE data = getDetectorDataW("RealTime") //this will be the linear data

	NVAR   elapsed          = root:myGlobals:RT:elapsed
	NVAR   timeout          = root:myGlobals:RT:timeout
	NVAR   updateInt        = root:myGlobals:RT:updateInt
	NVAR   totCounts        = root:myGlobals:RT:totalCounts
	NVAR   countTime        = root:myGlobals:RT:countTime
	NVAR   countRate        = root:myGlobals:RT:countRate
	NVAR   monitorCounts    = root:myGlobals:RT:monitorCounts
	NVAR   monitorCountRate = root:myGlobals:RT:monitorCountRate
	SVAR/Z title            = root:myGlobals:gCurDispFile
	SVAR   sampledesc       = root:myGlobals:gCurTitle

	variable err = 0
	//	Variable t1=ticks
	SVAR RT_fileStr = root:myGlobals:RT:RT_fileStr

	elapsed += updateInt
	//	get the new data by re-reading the datafile from the relay computer
	//	if(elapsed<timeout)

	if(WinType("SANS_Data") == 0)
		Button $"bkgStop", win=RT_Panel, title="Start Updating", rename=bkgStart
		return (1) //SANS_Data window not open
	endif
	SVAR type = root:myGlobals:gDataDisplayType
	if(cmpstr("RealTime", type) != 0)
		Button $"bkgStop", win=RT_Panel, title="Start Updating", rename=bkgStart
		return (1) //display not RealTime
	endif
	title = "Reading new data..."
	ControlUpdate/W=SANS_Data/A

	//Copy file from ICE server
	//ExecuteScriptText/B "\"C:\\Documents and Settings\\user\\Desktop\\ICE Test\\getdata.bat\""

	//err = ReadOrdelaHST(RT_fileStr)
	//err = ReadHeaderAndData(RT_fileStr)
	//		NVAR/Z gFakeUpdate = root:myGlobals:gFakeUpdate
	//		if(NVAR_Exists(gFakeUpdate) && gFakeUpdate == 1)
	//			err = FakeUpdate()
	//		else

	//err = ReadRTAndData(RT_fileStr)

	LoadRawSANSData(RT_fileStr, "RAW")
	Raw_to_Work_for_Tubes("RealTime")

	//		endif

	if(err == 1)
		Button $"bkgStop", win=RT_Panel, title="Start Updating", rename=bkgStart
		return (err) //file not found
	endif
	//Raw_to_work("RealTime")
	// for testing only...
	//		data += abs(enoise(data))
	//
	MapSliderProc("reset", 0, 1)

	title      = getSampleDescription("RealTime")
	sampledesc = getSampleDescription("RealTime")
	//sum the total counts, global variable will automatically update
	WAVE/Z linear_data = $"root:Packages:NIST:RealTime:linear_data"
	if(WaveExists(linear_data))
		totCounts = sum(linear_data, -Inf, Inf)
	else
		WAVE/Z data = $"root:Packages:NIST:RealTime:data"
		totCounts = sum(data, -Inf, Inf)
	endif
	//Update other live values
	countTime        = getCount_time("RealTime")
	countRate        = totCounts / countTime
	monitorCounts    = getBeamMonNormData("RealTime")
	monitorCountRate = monitorCounts / countTime

	//if the 1D plot is open, update this too
	// make sure folders exist first
	if(!DataFolderExists("root:myGlobals:Drawing"))
		Execute "InitializeAveragePanel()"
	endif

	// check for the mask, generate one? Two pixels all around

	variable numx = getDet_pixel_num_x("RealTime")
	variable numy = getDet_pixel_num_y("RealTime")
	if(WaveExists($"root:Packages:NIST:MSK:data") == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(numx, numy) root:Packages:NIST:MSK:data
		WAVE mask = root:Packages:NIST:MSK:data
		mask[0][]        = 1
		mask[1][]        = 1
		mask[numx - 2][] = 1
		mask[numx - 1][] = 1

		mask[][0]        = 1
		mask[][1]        = 1
		mask[][numy - 2] = 1
		mask[][numy - 1] = 1
	endif

	// update the 1d plot
	if(WinType("Plot_1d") == 1) //if the 1D graph exists
		Panel_DoAverageButtonProc("")
		DoWindow/F SANS_Data
	endif
	///////

	//		print "Bkg task time (s) =",(ticks-t1)/60.15
	return 0 //keep the process going
	//	else
	//		//timeout, stop the process, reset the button label
	//		elapsed=0
	//		Button $"bkgStop",win=RT_Panel,title="Start Updating",rename=bkgStart
	//		return(1)
	//	endif

End

/////not used////
// function control a background task of "live" image updating
//
Function UpdateImage(string ctrlName) : ButtonControl

	if(cmpstr(ctrlName, "bStart") == 0)
		Button $ctrlName, title="Stop", rename=bStop
		//	Start the updating - FakeUpdate() has been designated as the background task
		CtrlBackground period=60, start
	else
		Button $ctrlName, title="Start", rename=bStart
		//	Stop the updating
		CtrlBackground stop
	endif
End

//// puts a "clean" instance of SAS into RealTime
//Function ClearRTFolder()
//
//	String 	RTPath = "root:Packages:NIST:RealTime"
//	String 	SimPath = "root:Packages:NIST:SAS"
//
//
//	Duplicate/O $(SimPath + ":data"),$(RTPath+":data")
//	Duplicate/O $(SimPath + ":linear_data"),$(RTPath+":linear_data")
//	Duplicate/O $(SimPath + ":textread"),$(RTPath+":textread")
//	Duplicate/O $(SimPath + ":integersread"),$(RTPath+":integersread")
//	Duplicate/O $(SimPath + ":realsread"),$(RTPath+":realsread")
//
//	WAVE RT_rw = $(RTPath+":RealsRead")
//	WAVE RT_iw = $(RTPath+":IntegersRead")
//
//	RT_iw[2] = 0
//	RT_rw[0] = 0
//
//	Wave RTData = $(RTPath+":data")
//	Wave RTLinData = $(RTPath+":linear_data")
//	RTLinData = 0
//	RTData = 0
//
//	// get the right Q axes on the display
//	//add the qx and qy axes
//	Wave q_x_axis=$"root:myGlobals:q_x_axis"
//	Wave q_y_axis=$"root:myGlobals:q_y_axis"
//	Set_Q_Axes(q_x_axis,q_y_axis,RTPath)
//
//	return(0)
//End

////not used, but useful for real-time display of the detector
////old, and likely not up-to-date with the present data folder structure
//Function FakeUpdate()
//
//	//get the current displayed data (so the correct folder is used)
//	SVAR cur_folder=root:myGlobals:gDataDisplayType
//
//	STRUCT WMButtonAction ba
//	ba.eventCode = 2			//fake mouse click on button
//	MC_DoItButtonProc(ba)
//
//// would copy the work contents, but I want to add the MC results + times, etc.
////	Execute	"CopyWorkFolder(\"Simulation\",\"RealTime\")"
//
//	//check for existence of data in oldtype
//	// if the desired workfile doesn't exist, let the user know, and abort
//	String RTPath,SimPath
//	if(WaveExists($("root:Packages:NIST:RealTime:data")) == 0)
////		ClearRTFolder()
////		Print "There is no work file in "+"SAS"+"--Aborting"
////		Return(1) 		//error condition
//	Endif
//
//	//check for log-scaling of the "type" data and adjust if necessary
////	ConvertFolderToLinearScale("SAS")
////	ConvertFolderToLinearScale("RealTime")
////	Fix_LogLinButtonState(0)		//make sure the button reflects the new linear scaling
//	//then continue
//
//	//copy from current dir (type)=destPath to newtype, overwriting newtype contents
//	SimPath = "root:Packages:NIST:SAS"
//	RTPath = "root:Packages:NIST:RealTime"
//
//
//
//	WAVE RT_rw = $(RTPath+":RealsRead")
//	WAVE Sim_rw = $(SimPath+":RealsRead")
//	WAVE RT_iw = $(RTPath+":IntegersRead")
//	WAVE Sim_iw = $(SimPath+":IntegersRead")
//
//	// accumulate the count time and monitor counts
//	RT_iw[2] += Sim_iw[2]
//	RT_rw[0] += Sim_rw[0]
//
//// accumulate the data
//	Wave RTData = $(RTPath+":data")
//	Wave RTLinData = $(RTPath+":linear_data")
//	Wave SimLinData = $(SimPath+":linear_data")
//	RTLinData += SimLinData
//
//	NVAR gIsLogScale = $(RTPath + ":gIsLogScale")
//	if(gIsLogScale)
//		RTData = log(RTLinData)
//	else
//		RTData = RTLinData
//	endif
//
////	Execute  "ChangeDisplay(\"RealTime\")"
//	//just need to update the color bar
////	MapSliderProc("both",0,0)
//
//	//alter the raw data
////	linear_data += abs(enoise(1)) + abs(cos(p*q))
////	data = linear_data
//
//
//	//back to root folder
//	SetDataFolder root:
//
//	return 0
//End

//
//
//
// to use, first load in the analysis and reduction packages
// -- then, load in the sphere model
//
// load sphere model
//	Execute/P "INSERTINCLUDE \"Sphere_v40\""
//	Execute/P "COMPILEPROCEDURES "
//
////
//Function pInit_FakeRT()
//
//
//
//// plot sphere model
//	String cmdStr,funcStr
//	funcStr = "SphereForm"
//	sprintf cmdStr, "Plot%s()",funcStr
//	Execute cmdStr
//
//// close graph (top) and table
//	String topGraph= WinName(0,1)	//this is the topmost graph
//	String topTable= WinName(0,2)	//this is the topmost table
//	KillWindow $topGraph
//	KillWindow $topTable
//
//// change coef_sf[0] = 0.01
//	Wave coef_sf = root:coef_sf
//	coef_sf[0] = 0.01
//
//
//
//// open SASCALC
//	Execute "SASCALC()"
//
//// open MC simulation window
//	DoWindow/F MC_SASCALC
//	if(V_flag==0)
//		Execute "MC_SASCALC()"		//sets the variable
//		AutoPositionWindow/M=1/R=SASCALC MC_SASCALC
//	endif
//	NVAR doSim = root:Packages:NIST:SAS:doSimulation
//	doSim=1
//
//// set model
//	SVAR gStr = root:Packages:NIST:SAS:gFuncStr
//	gStr = "SphereForm"
//	String listStr = MC_FunctionPopupList()
//	Variable item = WhichListItem("SphereForm", listStr )
//	PopupMenu MC_popup0,win=MC_SASCALC,mode=(item+1)
//
//// set ct time to 5 s
//	STRUCT WMSetVariableAction sva
//	NVAR ctTime = root:Packages:NIST:SAS:gCntTime
//	ctTime = 5
//	sva.eventCode = 3		//update
//	sva.dval = ctTime		//5 seconds
//	CountTimeSetVarProc(sva)
//
//// be sure check boxes are raw_cts / BS in / XOP
//	NVAR cts = root:Packages:NIST:SAS:gRawCounts
//	NVAR BSin = root:Packages:NIST:SAS:gBeamStopIn
//	NVAR xop = root:Packages:NIST:SAS:gUse_MC_XOP
//	cts = 1
//	BSin = 1
//	xop = 1
//
//// run 1 simulation to "set" things
//	DoWindow/F MC_SASCALC
//	STRUCT WMButtonAction ba
//	ba.eventCode = 2			//fake mouse click on button
//	MC_DoItButtonProc(ba)
//
//
//// set RT fake flag
//	Variable/G root:myGlobals:gFakeUpdate=1
//
//// open RT window
//
//// load (any) data file
//
//// ClearFolder
//
//
//
//
//End
