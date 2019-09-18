#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=0.1
#pragma IgorVersion=6.1

//***********************
// NOV 2015 Vers 0.1
//
// Initialization procedures that must be run before anything
// this is accomplished by placing:
//
// Initialize()
// #include "includes"
//
// in the built-in procedure window of the .pxt (template) experiment
// IGOR recognizes this, and executes Initialize() immediately after
// compiling all of the included procedures. This is all done as the blank
// template is opened
//
// Choosing initialize from the VSANS menu will do the same, and no harm is done
// to the experiment by re- initializing. no data or folders are overwritten
//
//************************

Constant kVSANSVersion = 7.96

// TODO -- need to set up a separate file of "constants" or "globals" where the actual numbers are
//stored. If there are not a lot, that place could be here. InitFacilityGlobals() is currently in NCNR_Utils.ipf


// for the change in July 2017 where the beam center is now defined in cm, rather than pixels.
// this need not ever change from 1
// the back detector is always treated as a beam center in pixels, since it is the natural definition
Constant kBCTR_CM = 1			//set to 1 to use beam center in cm. O to use pixels

// // TODO: -- replace this constant with V_getDet_panel_gap(fname,detStr)
//Constant kPanelTouchingGap = 10			// TODO -- measure this gap when panels "touch", UNITS OF mm, not cm


// the base data folder path where the raw data is loaded
Strconstant ksBaseDFPath = "root:Packages:NIST:VSANS:RawVSANS:"


// the list of WORK Folders
// RawVSANS does not behave as a WORK folder, but it is local. so add it in explicitly to the list if needed
// VCALC behaves *almost* as a WORK folder, but it is local. so add it in explicitly to the list if needed
//Strconstant ksWorkFolderList = "RAW;SAM;EMP;BGD;COR;DIV;ABS;MSK;CAL;STO;SUB;DRK;ADJ;VCALC;RawVSANS;"
Strconstant ksWorkFolderListShort = "RAW;SAM;EMP;BGD;COR;DIV;ABS;MSK;CAL;STO;SUB;DRK;ADJ;"


// for defining which "bin type" corresponds to which set of extensions for I(q) data
// !! see V_BinTypeStr2Num() for the numbering, not the order of the list
//
//////////////////
//Strconstant ksBinTypeStr = "One;Two;Four;Slit Mode;"
Strconstant ksBinTypeStr = "F4-M4-B;F2-M2-B;F1-M1-B;F2-M1-B;F1-M2xTB-B;F2-M2xTB-B;SLIT-F2-M2-B;"
Strconstant ksBinType1 = "FT;FB;FL;FR;MT;MB;ML;MR;B;"		//these are the "active" extensions
Strconstant ksBinType2 = "FTB;FLR;MTB;MLR;B;"
Strconstant ksBinType3 = "FLRTB;MLRTB;B;"
Strconstant ksBinType4 = "FL;FR;ML;MR;B;"		//in SLIT mode, disregard the T/B panels
Strconstant ksBinType5 = "FTB;FLR;MLRTB;B;"
Strconstant ksBinType6 = "FLRTB;MLR;B;"
Strconstant ksBinType7 = "FTB;FLR;MLR;B;"
///////////////////


// for looping over each detector
Strconstant ksDetectorListNoB = "FL;FR;FT;FB;ML;MR;MT;MB;"
Strconstant ksDetectorListAll = "FL;FR;FT;FB;ML;MR;MT;MB;B;"


// for Protocols
Constant kNumProtocolSteps = 12
// for trimming of the I(q) data sets, and part of the protocol
Strconstant ksPanelBinTypeList = "B;FT;FB;FL;FR;MT;MB;ML;MR;FTB;FLR;MTB;MLR;FLRTB;MLRTB;"
Strconstant ksBinTrimBegDefault = "B=5;FT=3;FB=3;FL=3;FR=3;MT=3;MB=3;ML=3;MR=3;FTB=2;FLR=2;MTB=2;MLR=2;FLRTB=1;MLRTB=1;"
Strconstant ksBinTrimEndDefault = "B=10;FT=5;FB=5;FL=5;FR=5;MT=5;MB=5;ML=5;MR=5;FTB=4;FLR=4;MTB=4;MLR=4;FLRTB=3;MLRTB=3;"



//////// HIGH RESOLUTION DETECTOR  ///////////////


//
// In May 2019 - after testing with Phil's procesing, the data from the detector has a
// larger read noise value. It can also no longer be treated  as a constant value, but rather 
// a detector file that is read in and subtracted pixel-by-pixel. 
//


// the average read noise level of the back detector
// taken from multiple runs with the beam off, 6-28-18
// runs sans12324 - sans12353
//
// used in V_Raw_to_Work()
// average of whole panel (tested several data files) = 208 +/- 14
//
// 200 appears to be a better value - (empirical, based on teflon/converging pinhole data)
//Constant kReadNoiseLevel_bin4 = 200
//Constant kReadNoiseLevel_Err_bin4 = 14
// after binning/processing changes from March 2019:
Constant kReadNoiseLevel_bin4 = 3160			// from bkg area of sans30201 (a transmission measurement)
Constant kReadNoiseLevel_Err_bin4 = 50		//estimated

// TODOHIGHRES: these values are complete fiction
Constant kReadNoiseLevel_bin1 = 20
Constant kReadNoiseLevel_Err_bin1 = 1

// Pixel shifts for the back detector to bring the three CCDs into registry
// data from pinholes used to match up CCDs
// 27 JUN 2018
// runs 12221,12225,27,33,34,35,38,42
// middle CCD is not moved
// See V_ShiftBackDetImage() for implementation
Constant 	kShift_TopX_bin4 = 7
Constant		kShift_TopY_bin4 = 105
Constant		kShift_BottomX_bin4 = 5
Constant		kShift_BottomY_bin4 = 35

// TODOHIGHRES -- these values need to be verified. they are currently simply 4x the bin4 values
Constant 	kShift_TopX_bin1 = 28
Constant		kShift_TopY_bin1 = 420
Constant		kShift_BottomX_bin1 = 20
Constant		kShift_BottomY_bin1 = 130








Proc Initialize_VSANS()
	V_Initialize()
End

//this is the main initialization procedure that must be the first thing
//done when opening a new Data reduction experiment
//
//sets up data folders, globals, protocols, and draws the main panel
Proc V_Initialize()

	Variable curVersion = kVSANSVersion
	Variable oldVersion = NumVarOrDefault("root:VSANS_RED_VERSION",curVersion)
		
	if(oldVersion == curVersion)
		//must just be a new startup with the current version
		Variable/G root:VSANS_RED_VERSION=kVSANSVersion
	endif
	
	if(oldVersion < curVersion)
		String str = 	"This experiment was created with version "+num2str(oldVersion)+" of the macros. I'll try to make this work, but please start new work with a current template"
		DoAlert 0,str
	endif
	
	V_InitFolders()
	
	
	V_InitFakeProtocols()
	V_InitGlobals()	
	V_InitFacilityGlobals()
	DoWindow/F Main_VSANS_Panel
	If(V_flag == 0)
		//draw panel
		Main_VSANS_Panel()
	Endif
//	V_ResizeCmdWindow()

	VC_Initialize_Space()		//initialize folders for VCALC

// TODO - be sure that NCNR is defined correctly	
	//unload the NCNR_Package_Loader, if NCNR not defined
	UnloadNCNR_VSANS_Procedures()

End

//creates all the necessary data folders in the root folder
//does not overwrite any existing folders of the same name
//it leaves data in them untouched
//
// x-- make sure that I have all of the folders that I need
//
Function V_InitFolders()
	
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:VSANS
	
// for the file catalog
	NewDataFolder/O root:Packages:NIST:VSANS:CatVSHeaderInfo
// for the globals
	NewDataFolder/O root:Packages:NIST:VSANS:Globals
// for the raw nexus data (so I don't need to reload to get a single value)
	NewDataFolder/O root:Packages:NIST:VSANS:RawVSANS

// folders for the reduction steps		
	NewDataFolder/O root:Packages:NIST:VSANS:RAW
	NewDataFolder/O root:Packages:NIST:VSANS:SAM
	NewDataFolder/O root:Packages:NIST:VSANS:EMP
	NewDataFolder/O root:Packages:NIST:VSANS:BGD
	NewDataFolder/O root:Packages:NIST:VSANS:COR
	NewDataFolder/O root:Packages:NIST:VSANS:DIV
	NewDataFolder/O root:Packages:NIST:VSANS:MSK
	NewDataFolder/O root:Packages:NIST:VSANS:ABS
	NewDataFolder/O root:Packages:NIST:VSANS:CAL
	NewDataFolder/O root:Packages:NIST:VSANS:STO
	NewDataFolder/O root:Packages:NIST:VSANS:SUB
	NewDataFolder/O root:Packages:NIST:VSANS:DRK
	NewDataFolder/O root:Packages:NIST:VSANS:ADJ
	NewDataFolder/O root:Packages:NIST:VSANS:RealTime
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC
	NewDataFolder/O root:Packages:NIST:VSANS:ReadNoise


// ?? anything else

// for simulation
//	NewDataFolder/O root:Packages:NIST:VSANS:SAS


	
	Return(0)
End




//
//Global folder already exists...
//adds appropriate globals to the newly created myGlobals folder
//return data folder to root: before leaving
//
//
Function V_InitGlobals()
	
	
	Variable/G root:Packages:NIST:VSANS:Globals:gIsLogScale = 0
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType = "RAW"
	
	//check platform, so Angstrom can be drawn correctly

	//TODO	-- this is different on Igor 7. Macintosh # has been updated, but Windows has not
	// use Print char2num("Å") to find the magic number
	if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		String/G root:Packages:NIST:VSANS:Globals:gAngstStr = num2char(197)
		String/G root:Packages:NIST:gAngstStr = num2char(197)
		Variable/G root:Packages:NIST:VSANS:Globals:gIsMac = 1
	else
		//either Windows or Windows NT
		String/G root:Packages:NIST:VSANS:Globals:gAngstStr = num2char(-59)
		String/G root:Packages:NIST:gAngstStr = num2char(-59)
		Variable/G root:Packages:NIST:VSANS:Globals:gIsMac = 0
		//SetIgorOption to keep some PC's (graphics cards?) from smoothing the 2D image
		// SRK APRIL 2019 - removed this, does not exist in Igor 8 on WIN, and cause an error.
//		Execute "SetIgorOption WinDraw,forceCOLORONCOLOR=1"
	endif
	
	// TODO x- find the SANS preferences, copy over and update for VSANS
	// x- these are all in PlotUtilsMacro_v40.ipf as the preferences are set up as common
	// to all packages. I'm not sure that I want to do this with VSANS, but make the packages
	// separate entities. I'm seeing little benefit of the crossover, especially now that 
	// Analysis is not mine. So for VSANS, there is a new, separate file: V_VSANS_Preferences.ipf

	//this is critical to initialize now - as it has the y/n flags for the detector correction steps
	Execute "Initialize_VSANSPreferences()"	

	Execute "V_TubeZeroPointTables()"			// correction to the beam center
	
	// set the lookup waves for log/lin display of the detector images
	V_MakeImageLookupTables(10000,0,1)



	//set flag if Demo Version is detected
	Variable/G root:Packages:NIST:VSANS:Globals:isDemoVersion = V_isDemo()

	
	//set XML globals
//	String/G root:Packages:NIST:gXMLLoader_Title = ""
	
	Return(0)
End

//
//num = number of points (10000 seeems to be a good number so far)
// lo = lower value (between 0 and 1)
// hi = upper value (between 0 and 1)
//
// note that it is currenty NOT OK for lo > hi (!= reversed color scale, right now log(negative) == bad)
//
// TODO hi, lo not used properly here, seems to mangle log display now that I'm switching the lo,hi of the ctab
//
Function V_MakeImageLookupTables(num,lo,hi)
	Variable num,lo,hi

		// lookup waves for log and linear display of images
	// this is used for the main data display. With this, I can use the original
	// detector data (no copy) and the zeros in the data set are tolerated when displaying
	// on log scale
	SetDataFolder root:Packages:NIST:VSANS:Globals
	Variable val,offset
	
	offset = 1/num		//can't use 1/lo if lo == 0
	
	Make/O/D/N=(num) logLookupWave,linearLookupWave
	
	linearLookupWave = (p+1)/num
	
	
	logLookupWave = log(linearLookupWave)
	val = logLookupWave[0]
	logLookupWave += -val + offset
	val = logLookupWave[num-1]
	logLookupWave /= val
	
	SetDataFolder root:
	
	return(0)
end

//
// initializes globals that are specific to VSANS
//
// there really should be nothing here... all of this should now be in the Nexus data file
// and not tethered to hard-wired constants.
//
// -- what was here was:
// number of detector pixels
// pixel size
// deadtime
// beamstop "tolerance" to identify Trans files
// sample aperture offset
//
Function V_InitFacilityGlobals()

//	//Detector -specific globals
//	Variable/G root:myGlobals:gNPixelsX=128
//	Variable/G root:myGlobals:gNPixelsY=128
//	
//	// as of Jan2008, detector pixel sizes are read directly from the file header, so they MUST
//	// be set correctly in instr.cfg - these values are not used, but declared to avoid errors
//	Variable/G root:myGlobals:PixelResNG3_ILL = 1.0		//pixel resolution in cm
//	Variable/G root:myGlobals:PixelResNG5_ILL = 1.0
//	Variable/G root:myGlobals:PixelResNG7_ILL = 1.0
//	Variable/G root:myGlobals:PixelResNG3_ORNL = 0.5
//	Variable/G root:myGlobals:PixelResNG5_ORNL = 0.5
//	Variable/G root:myGlobals:PixelResNG7_ORNL = 0.5
//	Variable/G root:myGlobals:PixelResNGB_ORNL = 0.5
////	Variable/G root:myGlobals:PixelResCGB_ORNL = 0.5		// fiction
//
//	Variable/G root:myGlobals:PixelResDefault = 0.5
//	
//	Variable/G root:myGlobals:DeadtimeNG3_ILL = 3.0e-6		//deadtime in seconds
//	Variable/G root:myGlobals:DeadtimeNG5_ILL = 3.0e-6
//	Variable/G root:myGlobals:DeadtimeNG7_ILL = 3.0e-6
//	Variable/G root:myGlobals:DeadtimeNGB_ILL = 4.0e-6		// fictional
//	Variable/G root:myGlobals:DeadtimeNG3_ORNL_VAX = 3.4e-6		//pre - 23-JUL-2009 used VAX
//	Variable/G root:myGlobals:DeadtimeNG3_ORNL_ICE = 1.5e-6		//post - 23-JUL-2009 used ICE
//	Variable/G root:myGlobals:DeadtimeNG5_ORNL = 0.6e-6			//as of 9 MAY 2002
//	Variable/G root:myGlobals:DeadtimeNG7_ORNL_VAX = 3.4e-6		//pre 25-FEB-2010 used VAX
//	Variable/G root:myGlobals:DeadtimeNG7_ORNL_ICE = 2.3e-6		//post 25-FEB-2010 used ICE
//	Variable/G root:myGlobals:DeadtimeNGB_ORNL_ICE = 4.0e-6		//per JGB 16-JAN-2013, best value we have for the oscillating data
//
////	Variable/G root:myGlobals:DeadtimeCGB_ORNL_ICE = 1.5e-6		// fiction
//
//	Variable/G root:myGlobals:DeadtimeDefault = 3.4e-6
//
//	//new 11APR07
//	Variable/G root:myGlobals:BeamstopXTol = -8			// (cm) is BS Xpos is -5 cm or less, it's a trans measurement
//	// sample aperture offset is NOT stored in the VAX header, but it should be
//	// - when it is, remove the global and write an accessor AND make a place for 
//	// it in the RealsRead 
//	Variable/G root:myGlobals:apOff = 5.0				// (cm) distance from sample aperture to sample position

End

///////////////////////////////////////////////
// TODO
////////////// everything below needs to be re-written for VSANS
//
//////////////////////////////////////////////


// 
// do I need to make the protocols any longer for VSANS? (yes -- now 12 points)
// What other options for processing / averaging / saving are needed??
//  TODO
// x- likely that I'll want to have #pts to cut from I(q) as input to NSORT within the protocol so that the 
// entire reduction can be automatic
//
//
// x- creates the "base" protocols that should be available, after creating the data folder
// x- all protocols are kept in the root:Packages:NIST:VSANS:Globals:Protocols folder, created here
//
//
//*****as of 05_2017, protocols are 12 points long, [6] is used for work.drk, [7,8] are for trimmig points, and [9,11] are currently unused 
//
Function V_InitFakeProtocols()
	
	NewDataFolder/O root:Packages:NIST:VSANS:Globals:Protocols
	Make/O/T $"root:Packages:NIST:VSANS:Globals:Protocols:Base"={"none","none","ask","ask","none","AVTYPE=Circular;SAVE=Yes;NAME=Auto;PLOT=Yes;BINTYPE=F4-M4-B;","DRK=none,DRKMODE=0,","","","","",""}
	Make/O/T $"root:Packages:NIST:VSANS:Globals:Protocols:DoAll"={"ask","ask","ask","ask","ask","AVTYPE=Circular;SAVE=Yes;NAME=Auto;PLOT=Yes;BINTYPE=F4-M4-B;","DRK=none,DRKMODE=0,","","","","",""}
	Make/O/T/N=(kNumProtocolSteps) $"root:Packages:NIST:VSANS:Globals:Protocols:CreateNew"			//null wave
	//Initialize waves to store values in
	
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gNewStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = "AVTYPE=Circular;SAVE=Yes;NAME=Auto;PLOT=Yes;BINTYPE=F4-M4-B;"
	
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr=""
	
	Return(0)
End

//simple function to resize the comand window to a nice size, no matter what the resolution
//need to test out on several different monitors and both platforms
//
// could easily be incorporated into the initialization routines to ensure that the 
// command window is always visible at startup of the macros. No need for a hook function
//
Function V_ResizeCmdWindow()

	String str=IgorInfo(0),rect="",platform=igorinfo(2)
	Variable depth,left,top,right,bottom,factor
	
	if(cmpstr(platform,"Macintosh")==0)
		factor=1
	else
		factor = 0.6		//fudge factor to get command window on-screen on Windows
	endif
	rect = StringByKey("SCREEN1", str  ,":",";")	
	sscanf rect,"DEPTH=%d,RECT=%d,%d,%d,%d",depth, left,top,right,bottom
	MoveWindow/C  (left+3)*factor,(bottom-150)*factor,(right-50)*factor,(bottom-10)*factor
End

// since the NCNR procedures can't be loaded concurrently with the other facility functions,
// unload this procedure file, and add this to the functions that run at initialization of the 
// experiment
//
// TODO - be sure that this unloads correctly
Function UnloadNCNR_VSANS_Procedures()

#if (exists("NCNR_VSANS")==6)			//defined in the main #includes file.
	//do nothing if an NCNR reduction experiment
#else
	if(ItemsInList(WinList("NCNR_Package_Loader.ipf", ";","WIN:128")))
		Execute/P "CloseProc /NAME=\"NCNR_Package_Loader.ipf\""
		Execute/P "COMPILEPROCEDURES "
	endif
#endif

End

//returns 1 if demo version, 0 if full version
Function V_IsDemo()

	// create small offscreen graph
	Display/W=(3000,3000,3010,3010)
	DoWindow/C IsDemoGraph

	// try to save a PICT or bitmap of it to the clipboard
	SavePICT/Z  as "Clipboard"
	Variable isDemo= V_Flag != 0	// if error: must be demo
	DoWindow/K IsDemoGraph
	return isDemo
End

// Clean out the RawVSANS folder before saving
Function BeforeExperimentSaveHook(rN,fileName,path,type,creator,kind)
	Variable rN,kind
	String fileName,path,type,creator

	// clean out, so that the file SAVE is not slow due to the large experiment size
	// TODO -- decide if this is really necessary
//	
//	V_CleanOutRawVSANS()
// present a progress window
	V_CleanupData_w_Progress(0,1)
	Printf "Hook cleaned out RawVSANS, experiment saved\r"

	NVAR/Z gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
	if(gHighResBinning == 1)
// these KillDF are a bad idea - it wipes out all of the current work
// whenever a save is done - which is the opposite of what you want
// to happen when you save!
	
		Printf "Hook cleaned out WORK folders, experiment saved\r"

		KillDataFolder/Z root:Packages:NIST:VSANS:RAW
		KillDataFolder/Z root:Packages:NIST:VSANS:SAM
		KillDataFolder/Z root:Packages:NIST:VSANS:EMP
		KillDataFolder/Z root:Packages:NIST:VSANS:BGD
		KillDataFolder/Z root:Packages:NIST:VSANS:COR
		KillDataFolder/Z root:Packages:NIST:VSANS:DIV
		KillDataFolder/Z root:Packages:NIST:VSANS:MSK
		KillDataFolder/Z root:Packages:NIST:VSANS:ABS
		KillDataFolder/Z root:Packages:NIST:VSANS:CAL
		KillDataFolder/Z root:Packages:NIST:VSANS:STO
		KillDataFolder/Z root:Packages:NIST:VSANS:SUB
		KillDataFolder/Z root:Packages:NIST:VSANS:DRK
		KillDataFolder/Z root:Packages:NIST:VSANS:ADJ
		KillDataFolder/Z root:Packages:NIST:VSANS:VCALC

	endif
// re-create anthing that was killed
	V_initFolders()

End