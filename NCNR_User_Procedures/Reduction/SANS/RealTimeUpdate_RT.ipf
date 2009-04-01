#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

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
//*****************************

// takes care of all of the necessary initialization for the RT control process
// creates the folders, etc. that are needed for the SANS reduction package as well, but the end user
// doesn't need to see this.
//
// only used for testing - as this will re-initialize everything, including globals used as preferences
//
Proc Init_for_RealTime()
	// initialize the reduction folders as for normal SANS Reduction, but don't draw the main Reduction control panel
	InitFolders()
	InitFakeProtocols()
	InitGlobals()
	
	// specific for RealTime display
	//set the current display type to RealTime
	String/G root:myGlobals:gDataDisplayType = "RealTime"
	// draw the RealTime control panel
	Show_RealTime_Panel()
End

// Proc to bring the RT control panel to the front, always initializes the panel
// - always initialize to make sure that the background task is properly set
//
Proc Show_RealTime_Panel()
	Init_RT()		//always init, data folders and globals are created here
	DoWindow/F RT_Panel
	if(V_flag==0)
		RT_Panel()
	Endif
End

// folder and globals that are needed ONLY for the RT process
//
Function Init_RT()
	//create folders
	NewDataFolder/O root:Packages:NIST:RealTime
	NewDataFolder/O/S root:myGlobals:RT
	//create default globals only if they don't already exist, so you don't overwrite user-entered values.
	NVAR xCtr=xCtr
	if(NVAR_Exists(xctr)==0)
		Variable/G xCtr=110			//pixels
	endif
	NVAR yCtr=yCtr
	if(NVAR_Exists(yCtr)==0)
		Variable/G yCtr=64
	endif
	NVAR SDD=SDD
	if(NVAR_Exists(SDD)==0)
		Variable/G SDD=3.84					//in meters
	endif
	NVAR lambda=lambda
	if(NVAR_Exists(lambda)==0)
		Variable/G lambda=6				//angstroms
	endif
	NVAR updateInt=updateInt
	if(NVAR_Exists(updateInt)==0)
		Variable/G updateInt=5			//seconds
	endif
	NVAR timeout=timeout
	if(NVAR_Exists(timeout)==0)
		Variable/G timeout=300		//seconds
	endif
	NVAR elapsed=elapsed
	if(NVAR_Exists(elapsed)==0)
		Variable/G elapsed=0
	endif
	NVAR totalCounts=totalCounts		//total detector counts
	if(NVAR_Exists(totalCounts)==0)
		Variable/G totalCounts=0
	endif
	
	// set the explicit path to the data file on "relay" computer (the user will be propmted for this)
	SVAR RT_fileStr=RT_fileStr
	if(SVAR_Exists(RT_fileStr)==0)
		String/G RT_fileStr=""
	endif

	// set the background task
	AssignBackgroundTask()
	
	SetDataFolder root:
End

//sets the background task and period (in ticks)
//
Function AssignBackgroundTask()

	Variable updateInt=NumVarOrDefault("root:myGlobals:RT:updateInt",5)
	// set the background task
	SetBackground BkgUpdateHST()
	CtrlBackground period=(updateInt*60),noBurst=1		//noBurst prevents rapid "catch-up calls
	return(0)
End

//draws the RT panel and enforces bounds on the SetVariable controls for update period and timeout
//
Proc RT_Panel() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(500,350,802,480) /K=2
	DoWindow/C RT_Panel
	DoWindow/T RT_Panel,"Real Time Display Controls"
	ModifyPanel cbRGB=(65535,52428,6168)
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1
	DrawText 26,21,"Enter values for real-time display"
	Button bkgStart,pos={171,54},size={120,20},proc=UpdateHSTButton,title="Start Updating"
	Button bkgStart,help={"Starts or stops the updating of the real-time SANS image"}
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
	SetVariable setvar_4,pos={11,31},size={150,20},proc=UpdateInt_SetVarProc,title="Update Interval (s)"
	SetVariable setvar_4,help={"This is the period of the update"}
	SetVariable setvar_4,limits={1,3600,0},value= root:myGlobals:RT:updateInt
	SetVariable setvar_5,pos={11,56},size={150,20},title="Timeout Interval (s)"
	SetVariable setvar_5,help={"After the timeout interval has expired, the update process will automatically stop"}
	SetVariable setvar_5,limits={1,3600,0},value= root:myGlobals:RT:timeout
	Button button_1,pos={170,29},size={120,20},proc=LoadRTButtonProc,title="Load Live Data"
	Button button_1,help={"Load the data file for real-time display"}
	Button button_2,pos={250,2},size={30,20},proc=RT_HelpButtonProc,title="?"
	Button button_2,help={"Display the help file for real-time controls"}
	Button button_3,pos={230,80},size={60,20},proc=RT_DoneButtonProc,title="Done"
	Button button_3,help={"Closes the panel and stops the updating process"}
	SetVariable setvar_6,pos={11,82},size={200,20},title="Total Detector Counts"
	SetVariable setvar_6,help={"Total counts on the detector, as displayed"}
	SetVariable setvar_6,limits={0,Inf,0},value= root:myGlobals:RT:totalCounts
EndMacro

//
Proc RT_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName
//	DoAlert 0,"the help file has not been written yet :-("
	DisplayHelpTopic/K=1 "SANS Data Reduction Tutorial[Real Time Data Display]"
End

//close the panel gracefully, and stop the background task if necessary
//
Proc RT_DoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	BackgroundInfo
	if(V_Flag==2)		//task is currently running
		CtrlBackground stop
	endif
	DoWindow/K RT_Panel
End

//prompts for the RT data file - only needs to be set once, then the user can start/stop
//
Function LoadRTButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoAlert 0,"The RealTime detector image is located somewhere"
	Read_RT_File("Select the Live Data file")
	return(0)
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
Function RT_Param_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Wave rw=$"root:Packages:NIST:RealTime:RealsRead"
	if(WaveExists(rw)==0)
		return(1)
	Endif
	strswitch(ctrlName)	// string switch
		case "setvar_0":		//xCtr
			rw[16]=varNum
			break	
		case "setvar_1":		//yCtr
			rw[17]=varNum
			break	
		case "setvar_2":		//SDD
			rw[18]=varNum
			break
		case "setvar_3":		//lambda
			rw[26]=varNum
			break
	endswitch
	//only update the graph if it is open, and is a RealTime display...
	if(WinType("SANS_Data")==0)
		return(0) //SANS_Data window not open
	Endif
	SVAR type=root:myGlobals:gDataDisplayType
	if(cmpstr("RealTime",type)!=0)
		return(0)		//display not RealTime
	Endif
	fRawWindowHook()		//force a redraw of the graph
	DoWindow/F RT_Panel		//return panel to the front
	return(0)
End

// (re)-sets the period of the update background task
//
Function UpdateInt_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

//	BackgroundInfo
//	if(V_flag==2)
//		CtrlBackground stop
//	Endif

	// quite surprised that you can change the period of repeat while the task is active
	CtrlBackground period=(varNum*60),noBurst=1
	return(0)
End


/////////////////////////////
//simple, main entry procedure that will load a HST sans data file (not a work file)
//into the RealTime dataFolder
//(typically called from main panel button)
//
//(ununsed)
Proc Load_RT_Data()
	String msgStr = "Select a RT Ordela data file"
	Read_RT_File(msgStr)
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
Function Read_RT_File(msgStr)
	String msgStr

	String filename="",pathStr=""
	Variable refnum

	//check for the path
	PathInfo RT_Path
	If(V_Flag==1)		//	/D does not open the file
		Open/D/R/T="????"/M=(msgStr)/P=RT_Path refNum
	else
		Open/D/R/T="????"/M=(msgStr) refNum
	endif
	filename = S_FileName		//get the filename, or null if canceled from dialog
	if(strlen(filename)==0)
		//user cancelled, abort
		SetDataFolder root:
		Abort "No file selected, action aborted"
	Endif
	//set the globals and reset the RT_Path value
	pathStr = GetPathStrFromfullName(filename)
	NewPath/O RT_Path,pathStr
	Variable/G root:Packages:NIST:RealTime:gIsLogScale = 0		//force data to linear scale (1st read)
	String/G root:myGlobals:RT:RT_fileStr=filename	//full path:file of the Run.hst file to re-read
	//read in the data
	//ReadOrdelaHST(filename)
	
	//ReadHeaderAndData(filename)
	//Raw_to_Work("RealTime")
	ReadRTAndData(filename)

	//the calling macro must change the display type
	String/G root:myGlobals:gDataDisplayType="RealTime"		//displayed data type is RealTime
	
	//FillFakeHeader() 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	
	fRawWindowHook()
	
	// set the SANS_Data graph to "live" mode to allow fast updating
	//fRawWindowHook just drew the graph, so it should exist
	ModifyGraph/W=SANS_Data live=1		//not much speed help...
	
	return(0)
End

//function that does the guts of reading the binary data file
//fname is the full path:name;vers required to open the file
//The final root:Packages:NIST:RealTime:data wave is the real
//neutron counts and can be directly used
//
//returns 0 if read was ok
//returns 1 if there was an error
Function ReadOrdelaHST(fname)
	String fname
	//this function is for reading in RealTime data only, so it will always put data in RealTime folder
	SetDataFolder "root:Packages:NIST:RealTime"	
	//keep a string with the filename in the RealTime folder
	String/G root:Packages:NIST:RealTime:fileList = "Real-Time Data Display"
	//get log/linear state based on SANS_Data window
	Variable isLogScale=NumVarOrDefault("root:Packages:NIST:RealTime:gIsLogScale", 0)
	Variable/G root:Packages:NIST:RealTime:gIsLogScale = isLogScale		//creates if needed, "sets" to cur val if already exists
	
	Variable refNum=0,ii,p1,p2,tot,num=128
	String str=""
	Make/O/T/N=11 hdrLines
	Make/O/I/N=(num*num) a1		// /I flag = 32 bit integer data
	
	//full filename and path is now passed in...
	//actually open the file
	Open/R/Z refNum as fname		// /Z flag means I must handle open errors
	if(refnum==0)		//FNF error, get out
		DoAlert 0,"Could not find file: "+fname
		Close/A
		return(1)
	endif
	if(V_flag!=0)
		DoAlert 0,"File open error: V_flag="+num2Str(V_Flag)
		Close/A
		return(1)
	Endif
	// as of 12MAY03, the run.hst for real-time display has no header lines (M. Doucet)
//	for(ii=0;ii<11;ii+=1)		//read (or skip) 11 header lines
//		FReadLine refnum,str
//		hdrLines[ii]=str
//	endfor
	// 4-byte integer binary data follows, num*num integer values 
	FBinRead/B=3/F=3 refnum,a1
	//	
	Close refnum
	
	//we want only the first [0,127][0,127] quadrant of the 256x256 image
	// this is done most quickly by two successive redimension operations
	// (the duplicate is for testing only)
	//final redimension can make the data FP if desired..
	//Redimension/N=(256,256) a1
	Redimension/N=(128,128) a1

	if(exists("root:Packages:NIST:RealTime:data")!=1)		//wave DN exist
		Make/O/N=(128,128) $"root:Packages:NIST:RealTime:data"
	endif
	WAVE data=$"root:Packages:NIST:RealTime:data"
	Duplicate/O data,$"root:Packages:NIST:RealTime:linear_data"
	WAVE lin_data=$"root:Packages:NIST:RealTime:linear_data"
	lin_data=a1
	if(isLogScale)
		data=log(a1)
	else
		data=a1
	Endif
	
	KillWaves/Z a1  
	
	//return the data folder to root
	SetDataFolder root:
	
	Return 0
End

// fills the "default" fake header so that the SANS Reduction machinery does not have to be altered
// pay attention to what is/not to be trusted due to "fake" information
//
Function FillFakeHeader()

	Make/O/N=23 $"root:Packages:NIST:RealTime:IntegersRead"
	Make/O/N=52 $"root:Packages:NIST:RealTime:RealsRead"
	Make/O/T/N=11 $"root:Packages:NIST:RealTime:TextRead"
	
	Wave intw=$"root:Packages:NIST:RealTime:IntegersRead"
	Wave realw=$"root:Packages:NIST:RealTime:RealsRead"
	Wave/T textw=$"root:Packages:NIST:RealTime:TextRead"
	
	//Put in appropriate "fake" values
	// first 4 are user-defined on the Real Time control panel, so user has the opportunity to change these values.
	//
	realw[16]=NumVarOrDefault("root:myGlobals:RT:xCtr", 64.5)		//xCtr(pixels)
	realw[17]=NumVarOrDefault("root:myGlobals:RT:yCtr", 64.5)		//yCtr (pixels)
	realw[18]=NumVarOrDefault("root:myGlobals:RT:SDD", 5)		//SDD (m)
	realw[26]=NumVarOrDefault("root:myGlobals:RT:lambda", 6)		//wavelength (A)
	//
	// necessary values
	realw[10]=5			//detector calibration constants, needed for averaging
	realw[11]=10000
	realw[13]=5
	realw[14]=10000
	//
	// used in the resolution calculation, ONLY here to keep the routine from crashing
	realw[20]=65		//det size
	realw[27]=0.15	//delta lambda
	realw[21]=50.8	//BS size
	realw[23]=50		//A1
	realw[24]=12.7	//A2
	realw[25]=8.57	//A1A2 distance
	realw[4]=1		//trans
	realw[3]=0		//atten
	realw[5]=0.1		//thick
	//
	//
	realw[0]=1e8		//def mon cts

	// fake values to get valid deadtime and detector constants
	//
	textw[9]="ORNL  "		//6 characters
	textw[3]="[NGxSANS00]"	//11 chars, NGx will return default values for atten trans, deadtime... 
	
	return(0)
End

// action procedure to start/stop the updating process.
//checks for update display graph, current background task, etc..
// then update the button and at last controls the background task
//
Function UpdateHSTButton(ctrlName) : ButtonControl
	String ctrlName
	
	//check that the RT window is open, and that the display type is "RealTime"
	if(WinType("SANS_Data")==0)
		return(1) //SANS_Data window not open
	Endif
	SVAR type=root:myGlobals:gDataDisplayType
	if(cmpstr("RealTime",type)!=0)
		return(1)		//display not RealTime
	Endif
	//check the current state of the background task
	BackgroundInfo		//returns 0 if no task defined, 1 if idle, 2 if running
	if(V_flag==0)
		AssignBackgroundTask()
	Endif
	
	String Str=""
	//control the task, and update the button text
	if (cmpstr(ctrlName,"bkgStart") == 0)
		Button $ctrlName,win=RT_Panel,title="Stop Updating",rename=bkgStop		
	//	Start the updating - BkgUpdateHST() has been designated as the background task
		CtrlBackground start
	else
		Button $ctrlName,win=RT_Panel,title="Start Updating",rename=bkgStart
		NVAR elapsed=root:myGlobals:RT:elapsed
		elapsed=0	//reset the timer
	//	Stop the updating 
		CtrlBackground stop
	endif
	return(0)
End


// THIS IS THE BACKGROUND TASK
//
// simply re-reads the designated .hst file (which can be located anywhere, as long as it
// appears as a local disk)
// return value of 0 continues background execution
// return value of 1 turns background task off
//
Function BkgUpdateHST()

	WAVE data = $"root:Packages:NIST:RealTime:data"
	NVAR elapsed=root:myGlobals:RT:elapsed
	NVAR timeout=root:myGlobals:RT:timeout
	NVAR updateInt=root:myGlobals:RT:updateInt
	NVAR totCounts=root:myGlobals:RT:totalCounts
	
	Variable err=0
//	Variable t1=ticks
	SVAR RT_fileStr=root:myGlobals:RT:RT_fileStr
	
	elapsed += updateInt
//	get the new data by re-reading the datafile from the relay computer
	if(elapsed<timeout)
	
		if(WinType("SANS_Data")==0)
			Button $"bkgStop",win=RT_Panel,title="Start Updating",rename=bkgStart
			return(1) //SANS_Data window not open
		Endif
		SVAR type=root:myGlobals:gDataDisplayType
		if(cmpstr("RealTime",type)!=0)
			Button $"bkgStop",win=RT_Panel,title="Start Updating",rename=bkgStart
			return(1)		//display not RealTime
		Endif
		SVAR title=root:myGlobals:gCurDispFile
		title="Reading new data..."
		ControlUpdate/W=SANS_Data/A
		
		//Copy file from ICE server
		ExecuteScriptText/B "\"C:\\Documents and Settings\\user\\Desktop\\ICE Test\\getdata.bat\""
		
		//err = ReadOrdelaHST(RT_fileStr)
		//err = ReadHeaderAndData(RT_fileStr)
		err = ReadRTAndData(RT_fileStr)
		if(err==1)
			Button $"bkgStop",win=RT_Panel,title="Start Updating",rename=bkgStart
			return(err)	//file not found
		Endif
		//Raw_to_work("RealTime")
		// for testing only...
//		data += abs(enoise(data))
		//
		MapSliderProc("reset", 0, 1)
		
		title="Real-Time Data Display"
		//sum the total counts, global variable will automatically update
		WAVE/Z linear_data = $"root:Packages:NIST:RealTime:linear_data"
		if(WaveExists(linear_data))
			totCounts = sum(linear_data, -Inf, Inf )
		else
			WAVE/Z data = $"root:Packages:NIST:RealTime:data"
			totCounts = sum(data, -Inf, Inf )
		endif
		
//		print "Bkg task time (s) =",(ticks-t1)/60.15
		return 0		//keep the process going
	else
		//timeout, stop the process, reset the button label
		elapsed=0
		Button $"bkgStop",win=RT_Panel,title="Start Updating",rename=bkgStart
		return(1)
	endif
	
End

Function ReadRTAndData(fname)
	String fname
	//this function is for reading in RAW data only, so it will always put data in RAW folder
	String curPath = "root:Packages:NIST:RealTime:"
	SetDataFolder curPath		//use the full path, so it will always work
	//Variable/G root:Packages:NIST:RAW:gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	Variable isLogScale=NumVarOrDefault("root:Packages:NIST:RealTime:gIsLogScale", 0)
	Variable/G root:Packages:NIST:RealTime:gIsLogScale = isLogScale	
	
	Variable refNum,integer,realval
	String sansfname,textstr
	
	Make/O/N=23 $"root:Packages:NIST:RealTime:IntegersRead"
	Make/O/N=52 $"root:Packages:NIST:RealTime:RealsRead"
	Make/O/T/N=11 $"root:Packages:NIST:RealTime:TextRead"
	
	Wave intw=$"root:Packages:NIST:RealTime:IntegersRead"
	Wave realw=$"root:Packages:NIST:RealTime:RealsRead"
	Wave/T textw=$"root:Packages:NIST:RealTime:TextRead"
	
	//***NOTE ****
	// the "current path" gets mysteriously reset to "root:" after the SECOND pass through
	// this read routine, after the open dialog is presented
	// the "--read" waves end up in the correct folder, but the data does not! Why?
	//must re-set data folder before writing data array (done below)
	
	//full filename and path is now passed in...
	//actually open the file
	Open/R refNum as fname
	//skip first two bytes (VAX record length markers, not needed here)
	FSetPos refNum, 2
	//read the next 21 bytes as characters (fname)
	FReadLine/N=21 refNum,textstr
	textw[0]= textstr
	//read four i*4 values	/F=3 flag, B=3 flag
	FBinRead/F=3/B=3 refNum, integer
	intw[0] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[1] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[2] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[3] = integer
	// 6 text fields
	FSetPos refNum,55		//will start reading at byte 56
	FReadLine/N=20 refNum,textstr
	textw[1]= textstr
	FReadLine/N=3 refNum,textstr
	textw[2]= textstr
	FReadLine/N=11 refNum,textstr
	textw[3]= textstr
	FReadLine/N=1 refNum,textstr
	textw[4]= textstr
	FReadLine/N=8 refNum,textstr
	textw[5]= textstr
	FReadLine/N=60 refNum,textstr
	textw[6]= textstr
	
	//3 integers
	FSetPos refNum,174
	FBinRead/F=3/B=3 refNum, integer
	intw[4] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[5] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[6] = integer
	
	//2 integers, 3 text fields
	FSetPos refNum,194
	FBinRead/F=3/B=3 refNum, integer
	intw[7] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[8] = integer
	FReadLine/N=6 refNum,textstr
	textw[7]= textstr
	FReadLine/N=6 refNum,textstr
	textw[8]= textstr
	FReadLine/N=6 refNum,textstr
	textw[9]= textstr
	
	//2 integers
	FSetPos refNum,244
	FBinRead/F=3/B=3 refNum, integer
	intw[9] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[10] = integer
	
	//2 integers
	FSetPos refNum,308
	FBinRead/F=3/B=3 refNum, integer
	intw[11] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[12] = integer
	
	//2 integers
	FSetPos refNum,332
	FBinRead/F=3/B=3 refNum, integer
	intw[13] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[14] = integer
	
	//3 integers
	FSetPos refNum,376
	FBinRead/F=3/B=3 refNum, integer
	intw[15] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[16] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[17] = integer
	
	//1 text field - the file association for transmission are the first 4 bytes
	FSetPos refNum,404
	FReadLine/N=42 refNum,textstr
	textw[10]= textstr
	
	//1 integer
	FSetPos refNum,458
	FBinRead/F=3/B=3 refNum, integer
	intw[18] = integer
	
	//4 integers
	FSetPos refNum,478
	FBinRead/F=3/B=3 refNum, integer
	intw[19] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[20] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[21] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[22] = integer
	
	Close refNum
	
	//now get all of the reals
	//
	//Do all the GBLoadWaves at the end
	//
	//FBinRead Cannot handle 32 bit VAX floating point
	//GBLoadWave, however, can properly read it
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	String strToExecute
	//append "/S=offset/U=numofreals" to control the read
	// then append fname to give the full file path
	// then execute
	
	Variable a=0,b=0
	
	SetDataFolder curPath
	
	// 4 R*4 values
	strToExecute = GBLoadStr + "/S=39/U=4" + "\"" + fname + "\""
	Execute strToExecute
	Wave w=$"root:Packages:NIST:RealTime:tempGBWave0"
	b=4	//num of reals read
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 4 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=158/U=4" + "\"" + fname + "\""
	Execute strToExecute
	b=4	
	realw[a,a+b-1] = w[p-a]
	a+=b

///////////
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=186/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2	
	realw[a,a+b-1] = w[p-a]
	a+=b

	// 6 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=220/U=6" + "\"" + fname + "\""
	Execute strToExecute
	b=6	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 13 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=252/U=13" + "\"" + fname + "\""
	Execute strToExecute
	b=13
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 3 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=320/U=3" + "\"" + fname + "\""
	Execute strToExecute
	b=3	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 7 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=348/U=7" + "\"" + fname + "\""
	Execute strToExecute
	b=7
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 4 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=388/U=4" + "\"" + fname + "\""
	Execute strToExecute
	b=4	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=450/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=470/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 5 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=494/U=5" + "\"" + fname + "\""
	Execute strToExecute
	b=5	
	realw[a,a+b-1] = w[p-a]
	
	//if the binary VAX data ws transferred to a MAC, all is OK
	//if the data was trasnferred to an Intel machine (IBM), all the real values must be
	//divided by 4 to get the correct floating point values
	// I can't find any combination of settings in GBLoadWave or FBinRead to read data in correctly
	// on an Intel machine.
	//With the corrected version of GBLoadWave XOP (v. 1.43 or higher) Mac and PC both read
	//VAX reals correctly, and no checking is necessary 12 APR 99
	//if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		//do nothing
	//else
		//either Windows or Windows NT
		//realw /= 4
	//endif
	
	SetDataFolder curPath
	//read in the data
	strToExecute = "GBLoadWave/O/N=tempGBwave/B/T={16,2}/S=514/Q" + "\"" + fname + "\""
	Execute strToExecute

	SetDataFolder curPath		//use the full path, so it will always work
	
	Make/O/N=16384 $"root:Packages:NIST:RealTime:data"
	WAVE data=$"root:Packages:NIST:RealTime:data"
	SkipAndDecompressVAX(w,data)
	Redimension/N=(128,128) data			//NIST raw data is 128x128 - do not generalize
	
	Duplicate/O data,$"root:Packages:NIST:RealTime:linear_data"
	WAVE lin_data=$"root:Packages:NIST:RealTime:linear_data"
	if(isLogScale)
		data=log(lin_data)
	else
		data=lin_data
	Endif
	
	//keep a string with the filename in the RAW folder
	String/G root:Packages:NIST:RealTime:fileList = textw[0]
	
	//set the globals to the detector dimensions (pixels)
	Variable/G root:myGlobals:gNPixelsX=128		//default for Ordela data (also set in Initialize/NCNR_Utils.ipf)
	Variable/G root:myGlobals:gNPixelsY=128
//	if(cmpstr(textW[9],"ILL   ")==0)		//override if OLD Cerca data
//		Variable/G root:myGlobals:gNPixelsX=64
//		Variable/G root:myGlobals:gNPixelsY=64
//	endif
	
	//clean up - get rid of w = $"root:Packages:NIST:RAW:tempGBWave0"
//	KillWaves/Z w
	
	//return the data folder to root
	SetDataFolder root:
	
	Return 0

End