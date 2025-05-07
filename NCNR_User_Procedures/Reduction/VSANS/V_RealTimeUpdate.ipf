#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// Two versions are present here, and in partial states of operation:

// (1) RealTime Display
// -- this is the typical read every (n) seconds. It is assumed that the data file is complete - with a
//    complete header that reflects the current data acquisition snapshot.
//
//
// (2) RT Reduction
// -- this is the ANSTO version, which will read data in and apply the reduction protocol. This
//    will likely be the most useful, but may suffer from speed issues in re-executing a protocol
//    and re-loading all of the data every time. That will be seen.
//
// -- what may be more useful for this is "partial" reduction, where say only the DIV is applied to the data
//    so that its effects can be seen on the data. This implies that a new set of "default" protocols that
//    carry out simple subsets of the corrections would be quite useful. See how everyone responds.

//TODO:
// -- currently, RAW data is copied over to RealTime. The data is titled "WORK_RealTime", but has
//    only the same corrections as RAW data, not all of the WORK conversions.
//
//

//
//
//*****************************

// Proc to bring the RT control panel to the front, always initializes the panel
// - always initialize to make sure that the background task is properly set
//
Proc V_Show_RealTime_Panel()
	V_Init_RT() //always init, data folders and globals are created here
	DoWindow/F VSANS_RT_Panel
	if(V_flag == 0)
		VSANS_RT_Panel()
	endif
EndMacro

// folder and globals that are needed ONLY for the RT process
//
Function V_Init_RT()

	//create folders
	NewDataFolder/O root:Packages:NIST:VSANS:RealTime
	NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:RT
	//create default globals only if they don't already exist, so you don't overwrite user-entered values.
	//	NVAR/Z xCtr=xCtr
	//	if(NVAR_Exists(xctr)==0)
	//		Variable/G xCtr=110			//pixels
	//	endif
	//	NVAR/Z yCtr=yCtr
	//	if(NVAR_Exists(yCtr)==0)
	//		Variable/G yCtr=64
	//	endif
	//	NVAR/Z SDD=SDD
	//	if(NVAR_Exists(SDD)==0)
	//		Variable/G SDD=3.84					//in meters
	//	endif
	//	NVAR/Z lambda=lambda
	//	if(NVAR_Exists(lambda)==0)
	//		Variable/G lambda=6				//angstroms
	//	endif
	NVAR/Z updateInt = updateInt
	if(NVAR_Exists(updateInt) == 0)
		variable/G updateInt = 10 //seconds
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
	NVAR/Z countTime = countTime
	if(NVAR_Exists(countTime) == 0)
		variable/G countTime = 0
	endif
	NVAR/Z countRate = countRate
	if(NVAR_Exists(countRate) == 0)
		variable/G countRate = 0
	endif
	NVAR/Z monitorCountRate = monitorCountRate
	if(NVAR_Exists(monitorCountRate) == 0)
		variable/G monitorCountRate = 0
	endif
	NVAR/Z monitorCounts = monitorCounts
	if(NVAR_Exists(monitorCounts) == 0)
		variable/G monitorCounts = 0
	endif

	// set the explicit path to the data file on "relay" computer (the user will be propmted for this)
	SVAR/Z RT_fileStr = RT_fileStr
	if(SVAR_Exists(RT_fileStr) == 0)
		string/G RT_fileStr = ""
	endif

	// set the background task
	V_AssignBackgroundTask()

	SetDataFolder root:
End

//sets the background task and period (in ticks)
//
Function V_AssignBackgroundTask()

	variable updateInt = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:RT:updateInt", 10)
	// set the background task
	SetBackground V_BkgUpdate_RTData()
	CtrlBackground period=(updateInt * 60), noBurst=1 //noBurst=1 prevents rapid "catch-up" calls
	return (0)
End

//draws the RT panel and enforces bounds on the SetVariable controls for update period and timeout
//
Proc VSANS_RT_Panel()
	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(300 * sc, 350 * sc, 602 * sc, 580 * sc)/K=2 // force the user to close using done
	DoWindow/C VSANS_RT_Panel
	DoWindow/T RT_Panel, "Real Time Display Controls"
	ModifyPanel cbRGB=(65535, 52428, 6168)
	SetDrawLayer UserBack
	SetDrawEnv fstyle=1, fsize=14 * sc
	DrawText 26 * sc, 21 * sc, "Enter values for real-time display"
	Button bkgStart, pos={sc * 171, 54 * sc}, size={sc * 120, 20 * sc}, proc=V_UpdateHSTButton, title="Start Updating"
	Button bkgStart, help={"Starts or stops the updating of the real-time SANS image"}
	//	SetVariable setvar_0,pos={sc*15,29*sc},size={sc*100,15*sc},proc=RT_Param_SetVarProc,title="X Center"
	//	SetVariable setvar_0,help={"Set this to the current beamcenter x-coordinate (in pixels)"}
	//	SetVariable setvar_0,limits={0,128,0},value= root:myGlobals:RT:xCtr
	//	SetVariable setvar_1,pos={sc*14,46*sc},size={sc*100,15*sc},proc=RT_Param_SetVarProc,title="Y Center"
	//	SetVariable setvar_1,help={"Set this to the current beamcenter y-coordinate (in pixels)"}
	//	SetVariable setvar_1,limits={0,128,0},value= root:myGlobals:RT:yCtr
	//	SetVariable setvar_2,pos={sc*14,64*sc},size={sc*100,15*sc},proc=RT_Param_SetVarProc,title="SDD (m)"
	//	SetVariable setvar_2,help={"Set this to the sample-to-detector distance of the current instrument configuration"}
	//	SetVariable setvar_2,limits={0,1600,0},value= root:myGlobals:RT:SDD
	//	SetVariable setvar_3,pos={sc*15,82*sc},size={sc*100,15*sc},proc=RT_Param_SetVarProc,title="Lambda (A)"
	//	SetVariable setvar_3,help={"Set this to the wavelength of the current instrument configuration"}
	//	SetVariable setvar_3,limits={0,30,0},value= root:myGlobals:RT:lambda
	SetVariable setvar_4, pos={sc * 11, 31 * sc}, size={sc * 150, 20 * sc}, proc=V_UpdateInt_SetVarProc, title="Update Interval (s)"
	SetVariable setvar_4, help={"This is the period of the update"}
	SetVariable setvar_4, limits={1, 3600, 0}, value=root:Packages:NIST:VSANS:Globals:RT:updateInt
	//	SetVariable setvar_5,pos={sc*11,56*sc},size={sc*150,20*sc},title="Timeout Interval (s)"
	//	SetVariable setvar_5,help={"After the timeout interval has expired, the update process will automatically stop"}
	//	SetVariable setvar_5,limits={1,3600,0},value= root:myGlobals:RT:timeout
	Button button_1, pos={sc * 170, 29 * sc}, size={sc * 120, 20 * sc}, proc=V_LoadRTButtonProc, title="Load Live Data"
	Button button_1, help={"Load the data file for real-time display"}
	Button button_2, pos={sc * 250, 2 * sc}, size={sc * 30, 20 * sc}, proc=V_RT_HelpButtonProc, title="?"
	Button button_2, help={"Display the help file for real-time controls"}
	Button button_3, pos={sc * 230, 200 * sc}, size={sc * 60, 20 * sc}, proc=V_RT_DoneButtonProc, title="Done"
	Button button_3, help={"Closes the panel and stops the updating process"}
	SetVariable setvar_6, pos={sc * 11, 105 * sc}, size={sc * 250, 20 * sc}, title="Total Detector Counts"
	SetVariable setvar_6, help={"Total counts on the detector, as displayed"}, noedit=1
	SetVariable setvar_6, limits={0, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:RT:totalCounts
	SetVariable setvar_7, pos={sc * 11, 82 * sc}, size={sc * 250, 20 * sc}, title="                  Count Time"
	SetVariable setvar_7, help={"Count time, as displayed"}, noedit=1
	SetVariable setvar_7, limits={0, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:RT:countTime
	SetVariable setvar_8, pos={sc * 11, 127 * sc}, size={sc * 250, 20 * sc}, title="  Detector Count Rate"
	SetVariable setvar_8, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_8, limits={0, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:RT:countRate
	SetVariable setvar_9, pos={sc * 11, 149 * sc}, size={sc * 250, 20 * sc}, title="           Monitor Counts"
	SetVariable setvar_9, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_9, limits={0, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:RT:monitorCounts
	SetVariable setvar_10, pos={sc * 11, 171 * sc}, size={sc * 250, 20 * sc}, title="    Monitor Count Rate"
	SetVariable setvar_10, help={"Count rate, as displayed"}, noedit=1
	SetVariable setvar_10, limits={0, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:RT:monitorCountRate
EndMacro

//
Proc V_RT_HelpButtonProc(ctrlName) : ButtonControl
	string ctrlName
	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[VSANS RealTime Display]"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Tutorial Help file could not be found"
	endif
EndMacro

//close the panel gracefully, and stop the background task if necessary
//
Proc V_RT_DoneButtonProc(ctrlName) : ButtonControl
	string ctrlName

	BackgroundInfo
	if(V_Flag == 2) //task is currently running
		CtrlBackground stop
	endif
	DoWindow/K VSANS_RT_Panel
EndMacro

//prompts for the RT data file - only needs to be set once, then the user can start/stop
//
Function V_LoadRTButtonProc(string ctrlName) : ButtonControl

	DoAlert 0, "The RealTime detector image is located on charlotte"
	V_Read_RT_File("Select the Live Data file")
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
//// check on a case-by-case basis
//Function V_RT_Param_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
//	String ctrlName
//	Variable varNum
//	String varStr
//	String varName
//
//	Wave rw=$"root:Packages:NIST:RealTime:RealsRead"
//	if(WaveExists(rw)==0)
//		return(1)
//	Endif
//	strswitch(ctrlName)	// string switch
//		case "setvar_0":		//xCtr
//			rw[16]=varNum
//			break
//		case "setvar_1":		//yCtr
//			rw[17]=varNum
//			break
//		case "setvar_2":		//SDD
//			rw[18]=varNum
//			break
//		case "setvar_3":		//lambda
//			rw[26]=varNum
//			break
//	endswitch
//	//only update the graph if it is open, and is a RealTime display...
//	if(WinType("SANS_Data")==0)
//		return(0) //SANS_Data window not open
//	Endif
//	SVAR type=root:myGlobals:gDataDisplayType
//	if(cmpstr("RealTime",type)!=0)
//		return(0)		//display not RealTime
//	Endif
//
//
//
//
////	fRawWindowHook()		//force a redraw of the graph
//
//
//
//	DoWindow/F VSANS_RT_Panel		//return panel to the front
//	return(0)
//End

//
// (re)-sets the period of the update background task
//
Function V_UpdateInt_SetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	//	BackgroundInfo
	//	if(V_flag==2)
	//		CtrlBackground stop
	//	Endif

	// quite surprised that you can change the period of repeat while the task is active
	CtrlBackground period=(varNum * 60), noBurst=1
	return (0)
End

//function called by the main entry procedure (the load button)
//sets global display variable, reads in the data, and displays it
//aborts if no file was selected
//
//(re)-sets the GLOBAL path:filename of the RT file to update
// also resets the path to the RT file, so that the dialog brings you back to the right spot
//
// reads the data in if all is OK
//
Function V_Read_RT_File(string msgStr)

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
	pathStr = ParseFilePath(1, filename, ":", 1, 0)
	NewPath/O RT_Path, pathStr
	//	Variable/G root:Packages:NIST:RealTime:gIsLogScale = 0		//force data to linear scale (1st read)
	string/G root:Packages:NIST:VSANS:Globals:RT:RT_fileStr = filename //full path:file of the Run.hst file to re-read

	//read in the data

	//	get the new data by re-reading the datafile from charlotte?
	V_LoadHDF5Data(filename, "RAW")
	// data folder "old" will be copied to "new" (either kills/copies or will overwrite)
	V_CopyHDFToWorkFolder("RAW", "RealTime")

	V_UpdateDisplayInformation("RealTime") // plot the data in whatever folder type

	//the calling macro must change the display type
	string/G root:Packages:NIST:VSANS:Globals:gCurDispType = "RealTime" //displayed data type is RealTime

	//data is displayed here, and needs header info
	//	WAVE data = $"root:Packages:NIST:RealTime:data"
	NVAR   totCounts        = root:Packages:NIST:VSANS:Globals:RT:totalCounts
	NVAR   countTime        = root:Packages:NIST:VSANS:Globals:RT:countTime
	NVAR   countRate        = root:Packages:NIST:VSANS:Globals:RT:countRate
	NVAR   monitorCounts    = root:Packages:NIST:VSANS:Globals:RT:monitorCounts
	NVAR   monitorCountRate = root:Packages:NIST:VSANS:Globals:RT:monitorCountRate
	SVAR/Z title            = root:Packages:NIST:VSANS:Globals:gCurDispFile

	title = "Real-Time : " + filename
	//sum the total counts, global variable will automatically update

	totCounts = V_getDetector_counts("RealTime")

	//Update other live values

	countTime = V_getCount_time("RealTime")
	countRate = totCounts / countTime
	// TODO: -- this may not be the correct monitor to use
	// -- may not be the correct detectior integral to report

	monitorCounts    = V_getBeamMonNormData("RealTime")
	monitorCountRate = monitorCounts / countTime

	// set the VSANS_Data graph to "live" mode to allow fast updating

	//	ModifyGraph/W=VSANS_Data live=1		//not much speed help...

	return (0)
End

// action procedure to start/stop the updating process.
//checks for update display graph, current background task, etc..
// then update the button and at last controls the background task
//
Function V_UpdateHSTButton(string ctrlName) : ButtonControl

	//check that the RT window is open, and that the display type is "RealTime"
	if(WinType("VSANS_Data") == 0)
		return (1) //SANS_Data window not open
	endif
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType
	if(cmpstr("RealTime", type) != 0)
		return (1) //display not RealTime
	endif
	//check the current state of the background task
	BackgroundInfo //returns 0 if no task defined, 1 if idle, 2 if running
	if(V_flag == 0)
		V_AssignBackgroundTask()
	endif

	string Str = ""
	//control the task, and update the button text
	if(cmpstr(ctrlName, "bkgStart") == 0)
		Button $ctrlName, win=VSANS_RT_Panel, title="Stop Updating", rename=bkgStop
		//	Start the updating - BkgUpdateHST() has been designated as the background task
		CtrlBackground start
	else
		Button $ctrlName, win=VSANS_RT_Panel, title="Start Updating", rename=bkgStart
		NVAR elapsed = root:Packages:NIST:VSANS:Globals:RT:elapsed
		elapsed = 0 //reset the timer
		//	Stop the updating
		CtrlBackground stop
	endif
	return (0)
End

// THIS IS THE BACKGROUND TASK
//
// simply re-reads the designated Live Data file (which can be located anywhere, as long as it
// appears as a local disk)
// return value of 0 continues background execution
// return value of 1 turns background task off
//
Function V_BkgUpdate_RTData()

	//	WAVE data = $"root:Packages:NIST:RealTime:data"

	NVAR   elapsed          = root:Packages:NIST:VSANS:Globals:RT:elapsed
	NVAR   timeout          = root:Packages:NIST:VSANS:Globals:RT:timeout
	NVAR   updateInt        = root:Packages:NIST:VSANS:Globals:RT:updateInt
	NVAR   totCounts        = root:Packages:NIST:VSANS:Globals:RT:totalCounts
	NVAR   countTime        = root:Packages:NIST:VSANS:Globals:RT:countTime
	NVAR   countRate        = root:Packages:NIST:VSANS:Globals:RT:countRate
	NVAR   monitorCounts    = root:Packages:NIST:VSANS:Globals:RT:monitorCounts
	NVAR   monitorCountRate = root:Packages:NIST:VSANS:Globals:RT:monitorCountRate
	SVAR/Z title            = root:Packages:NIST:VSANS:Globals:gCurDispFile
	SVAR/Z sampledesc       = root:Packages:NIST:VSANS:Globals:gCurTitle

	variable err = 0
	//	Variable t1=ticks
	SVAR RT_fileStr = root:Packages:NIST:VSANS:Globals:RT:RT_fileStr

	elapsed += updateInt

	//	if(elapsed<timeout)

	if(WinType("VSANS_Data") == 0)
		Button $"bkgStop", win=VSANS_RT_Panel, title="Start Updating", rename=bkgStart
		return (1) //SANS_Data window not open
	endif
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType
	if(cmpstr("RealTime", type) != 0)
		Button $"bkgStop", win=VSANS_RT_Panel, title="Start Updating", rename=bkgStart
		return (1) //display not RealTime
	endif
	title = "Reading new data..."
	ControlUpdate/W=VSANS_Data/A

	if(err == 1)
		Button $"bkgStop", win=VSANS_RT_Panel, title="Start Updating", rename=bkgStart
		return (err) //file not found
	endif

	//	get the new data by re-reading the datafile from charlotte?
	V_LoadHDF5Data(RT_fileStr, "RAW")
	// data folder "old" will be copied to "new" (either kills/copies or will overwrite)
	V_CopyHDFToWorkFolder("RAW", "RealTime")

	V_UpdateDisplayInformation("RealTime") // plot the data in whatever folder type

	// for testing only...
	//		data += abs(enoise(data))
	//

	// TODO:
	// -- fill in the title and sampledesc fields from the realTime folder
	//		title=textw[0]
	//		sampledesc=textw[6]

	//		//sum the total counts, global variable will automatically update
	//
	totCounts = V_getDetector_counts("RealTime")

	//Update other live values

	countTime = V_getCount_time("RealTime")
	countRate = totCounts / countTime
	// TODO: -- this may not be the correct monitor to use
	// -- may not be the correct detectior integral to report

	monitorCounts    = V_getBeamMonNormData("RealTime")
	monitorCountRate = monitorCounts / countTime

	// DONE:
	// x- update the 1D plot
	// repeat what the IQ button does -- V_IvsQPanelButtonProc()
	V_PlotData_Panel() //-9999 requests a read from the popup on the panel
	variable binType = V_GetBinningPopMode()
	ControlInfo/W=V_1D_Data popup0
	V_BinningModePopup("", binType, S_Value) // does binning of current popString and updates the graph

	//		print "Bkg task time (s) =",(ticks-t1)/60.15
	return 0 //keep the process going

End

////////////// Routines from ANSTO
//
// these are designed to do the reduction (protocol) as the data is displayed
//
// also not loaded with SANS (R/T/I) baggage, as the complete header is assumed in the live file.
//
//
// TODO:
// -- completely untested, so that's a starting point...
// -- no provision for setting the refresh time
// -- is the file modification time actually written for the live file? if not - then nothing happens here
//    since it always looks like the file is unchanged.
//

Function V_ShowOnlineReductionPanel()

	variable sc = 1

	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode

	if(gLaptopMode == 1)
		sc = 0.7
	endif

	//check for the path
	PathInfo catPathName
	if(V_Flag == 0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		return 0
	endif

	DoWindow/F V_ORPanel
	if(V_flag != 0)
		return 0
	endif

	// data
	NewDataFolder/O root:Packages:NIST:VSANS:Globals:OnlineReduction

	string/G   root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename             = ""
	string/G   root:Packages:NIST:VSANS:Globals:OnlineReduction:Protocol             = ""
	variable/G root:Packages:NIST:VSANS:Globals:OnlineReduction:LastFileModification = 0

	// panel
	PauseUpdate; Silent 1
	NewPanel/W=(300 * sc, 350 * sc, 702 * sc, 481 * sc)/K=2 //K=2 to force exit using "done" button to exit the background procedure

	DoWindow/C V_ORPanel
	DoWindow/T V_ORPanel, "Online Reduction"
	ModifyPanel cbRGB=(240 * 255, 170 * 255, 175 * 255)

	variable top        = 5
	variable groupWidth = 390

	// filename
	GroupBox group_Flename, pos={sc * 6, top * sc}, size={sc * groupWidth, (18 + 26) * sc}, title="select file for online reduction:"
	PopupMenu popup_Filename, pos={sc * 12, (top + 18) * sc}, size={sc * (groupWidth - 12 - 0), 20 * sc}, title=""
	PopupMenu popup_Filename, mode=1, value=V_GetRawDataFileList(), bodyWidth=sc * (groupWidth - 12 - 0)
	PopupMenu popup_Filename, proc=V_ORPopupSelectFileProc

	string fileList = V_GetRawDataFileList()
	if(ItemsInList(fileList) > 0)
		string/G root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename = StringFromList(0, fileList)
	else
		string/G root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename = ""
	endif

	top += 18 + 26 + 7

	// protocol
	GroupBox group_Protocol, pos={sc * 6, top * sc}, size={sc * groupWidth, (18 + 22) * sc}, title="select protocol for online reduction:"
	SetVariable setvar_Protocol, pos={sc * 12, (top + 18) * sc}, size={sc * (groupWidth - 12 - 18), 0 * sc}, title=" "
	SetVariable setvar_Protocol, value=root:Packages:NIST:VSANS:Globals:OnlineReduction:Protocol

	Button button_SelectProtocol, pos={sc * (12 + groupWidth - 12 - 18), (top + 18 - 1) * sc}, size={sc * 18, 18 * sc}, title="...", proc=V_ORButtonSelectProtocolProc

	top += 18 + 22 + 7
	variable left = 12

	// sart, stop, done
	Button button_Start, pos={sc * (left + 70 * 0), top * sc}, size={sc * 60, 20 * sc}, title="Start", proc=V_ORButtonStartProc
	Button button_Stop, pos={sc * (left + 70 * 1), top * sc}, size={sc * 60, 20 * sc}, title="Stop", proc=V_ORButtonStopProc, disable=2
	Button button_Done, pos={sc * (left + 70 * 2), top * sc}, size={sc * 60, 20 * sc}, title="Done", proc=V_ORButtonDoneProc

End

Function V_ORPopupSelectFileProc(string ctrlName, variable popNum, string popStr) : PopupMenuControl

	string/G root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename = popStr

End

Function V_ORButtonSelectProtocolProc(string ctrlName) : ButtonControl

	string protocolName = ""
	SVAR   gProtoStr    = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr

	//pick a protocol wave from the Protocols folder
	//must switch to protocols folder to get wavelist (missing parameter)
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	Execute "V_PickAProtocol()"

	//get the selected protocol wave choice through a global string variable
	protocolName = gProtoStr

	//	//If "CreateNew" was selected, go to the questionnare, to make a new set
	//	//and put the name of the new Protocol wave in gProtoStr
	//	if(cmpstr("CreateNew",protocolName) == 0)
	//		ProtocolQuestionnare()
	//		protocolName = gProtoStr
	//	Endif

	string/G root:Packages:NIST:VSANS:Globals:OnlineReduction:Protocol = protocolName

	SetDataFolder root:

End

Function V_ORButtonStartProc(string ctrlName) : ButtonControl

	BackgroundInfo
	if(V_Flag != 2) // task is not running
		if(V_ORReduceFile() == 0) // check if first reduction works

			// set up task
			SetBackground V_ORUpdate()
			CtrlBackground period=(5 * 60), noBurst=1 // 60 = 1 sec // noBurst prevents rapid "catch-up" calls
			CtrlBackground start

			DoWindow/T V_ORPanel, "Online Reduction - Running (Updated: " + time() + ")"
			DoWindow/F V_ORPanel
			// enable
			Button button_Stop, disable=0
			// disable
			Button button_Start, disable=2
			PopupMenu popup_Filename, disable=2
			SetVariable setvar_Protocol, disable=2
			Button button_SelectProtocol, disable=2

		endif
	endif

End

Function V_ORButtonStopProc(string ctrlName) : ButtonControl

	BackgroundInfo
	if(V_Flag == 2) // task is running
		// stop task
		CtrlBackground stop
	endif

	DoWindow/T V_ORPanel, "Online Reduction"
	DoWindow/F V_ORPanel
	// enable
	Button button_Start, disable=0
	PopupMenu popup_Filename, disable=0
	SetVariable setvar_Protocol, disable=0
	Button button_SelectProtocol, disable=0
	// disable
	Button button_Stop, disable=2

End

Function V_ORButtonDoneProc(string ctrlName) : ButtonControl

	V_ORButtonStopProc(ctrlName)
	DoWindow/K V_ORPanel

End

Function V_ORUpdate()

	SVAR   filename             = root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename
	NVAR/Z lastFileModification = root:Packages:NIST:VSANS:Globals:OnlineReduction:LastFileModification

	if(lastFileModification == V_GetModificationDate(filename)) // no changes

		return 0 // continue task

	elseif(V_ORReduceFile() == 0) // update

		DoWindow/T V_ORPanel, "Online Reduction - Running (Updated: " + time() + ")"
		print "Last Update: " + time()
		return 0 // continue task

	else // failure

		Beep
		V_ORButtonStopProc("")
		return 2 // stop task if error occurs

	endif
End

Function V_ORReduceFile()

	SVAR protocol = root:Packages:NIST:VSANS:Globals:OnlineReduction:Protocol
	SVAR filename = root:Packages:NIST:VSANS:Globals:OnlineReduction:Filename

	string waveStr = "root:Packages:NIST:VSANS:Globals:Protocols:" + protocol
	string samStr  = filename

	if(exists(waveStr) != 1)
		DoAlert 0, "The Protocol with the name \"" + protocol + "\" was not found."
		return 1 // for error
	endif

	NVAR/Z lastFileModification = root:Packages:NIST:VSANS:Globals:OnlineReduction:LastFileModification
	lastFileModification = V_GetModificationDate(samStr)

	// TODO:
	// file needs to be removed from the DataFolder so that it will be reloaded
	//	string partialName = filename
	//	variable index = strsearch(partialName,".",0)
	//	if (index != -1)
	//		partialName = partialName[0,index-1]
	//	endif
	//	KillDataFolder/Z $"root:Packages:quokka:"+partialName

	return V_ExecuteProtocol(waveStr, samStr)

End

Function V_GetModificationDate(string filename)

	PathInfo catPathName // this is where the files are
	string path = S_path + filename

	Getfilefolderinfo/Q/Z path
	if(V_flag)
		Abort "file was not found"
	endif

	return V_modificationDate

End

