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



// TODO -- need to set up a separate file of "constants" or "globals" where the actual numbers are
//stored. If there are not a lot, that place could be here. InitFacilityGlobals() is currently in NCNR_Utils.ipf



//
/// Search for TODO to clean up the missing pieces
//





Proc Initialize_VSANS()
	V_Initialize()
End

//this is the main initualization procedure that must be the first thing
//done when opening a new Data reduction experiment
//
//sets up data folders, globals, protocols, and draws the main panel
Proc V_Initialize()

	Variable curVersion = 0.1
	Variable oldVersion = NumVarOrDefault("root:VSANS_RED_VERSION",curVersion)
		
	if(oldVersion == curVersion)
		//must just be a new startup with the current version
		Variable/G root:VSANS_RED_VERSION=0.1
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
//	ResizeCmdWindow()

// TODO - be sure that NCNR is defined correctly	
	//unload the NCNR_Package_Loader, if NCNR not defined
	UnloadNCNR_VSANS_Procedures()

End

//creates all the necessary data folders in the root folder
//does not overwrite any existing folders of the same name
//it leaves data in them untouched
//
// TODO -- make sure that I have all of the folders that I need
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

	//TODO	- this is different on Igor 7
	if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		String/G root:Packages:NIST:VSANS:Globals:gAngstStr = num2char(-127)
		Variable/G root:Packages:NIST:VSANS:Globals:gIsMac = 1
	else
		//either Windows or Windows NT
		String/G root:Packages:NIST:VSANS:Globals:gAngstStr = num2char(-59)
		Variable/G root:Packages:NIST:VSANS:Globals:gIsMac = 0
		//SetIgorOption to keep some PC's (graphics cards?) from smoothing the 2D image
		Execute "SetIgorOption WinDraw,forceCOLORONCOLOR=1"
	endif
	
	// TODO -- find the SANS preferences, copy over and update for VSANS
	// -- these are all in PlotUtilsMacro_v40.ipf as the preferences are set up as common
	// to all packages. I'm not sure that I want to do this with VSANS, but make the packages
	// separate entities. I'm seeing little benefit of the crossover, especially now that 
	// Analysis is not mine. So for VSANS, there is a new, separate file: V_VSANS_Preferences.ipf

	Execute "Initialize_VSANSPreferences()"	

	
	// lookup waves for log and linear display of images
	// this is used for the main data display. With this, I can use the original
	// detector data (no copy) and the zeros in the data set are tolerated when displaying
	// on log scale
	SetDataFolder root:Packages:NIST:VSANS:Globals
	Variable num,val,offset
	num=10000
	offset = 1/num
	
	Make/O/D/N=(num) logLookupWave,linearLookupWave
	linearLookupWave = (p+1)/num
	
	logLookupWave = log(linearLookupWave)
	val = logLookupWave[0]
	logLookupWave += -val + offset
	val = logLookupWave[num-1]
	logLookupWave /= val
	
	SetDataFolder root:


	//set flag if Demo Version is detected
	Variable/G root:Packages:NIST:VSANS:Globals:isDemoVersion = V_isDemo()
	
	//set XML globals
//	String/G root:Packages:NIST:gXMLLoader_Title = ""
	
	Return(0)
End


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
//
////////////// everything below needs to be re-written for VSANS
//
//////////////////////////////////////////////


// TODO
// do I need to make the protocols any longer for VSANS?
// What other options for processing / averaging / saving are needed??
// - TODO
// -- likely that I'll want to have #pts to cut from I(q) as input to NSORT within the protocol so that the 
// entire reduction can be automatic
//
//
// -- creates the "base" protocols that should be available, after creating the data folder
// -- all protocols are kept in the root:Packages:NIST:VSANS:Globals:Protocols folder, created here
//
Function V_InitFakeProtocols()
	
	//*****as of 0901, protocols are 8 points long, [6] is used for work.drk, [7] is unused 
	NewDataFolder/O root:Packages:NIST:VSANS:Globals:Protocols
	Make/O/T $"root:Packages:NIST:VSANS:Globals:Protocols:Base"={"none","none","ask","ask","none","AVTYPE=Circular;SAVE=Yes;NAME=Manual;PLOT=Yes","DRK=none,DRKMODE=0,",""}
	Make/O/T $"root:Packages:NIST:VSANS:Globals:Protocols:DoAll"={"ask","ask","ask","ask","ask","AVTYPE=Circular;SAVE=Yes;NAME=Manual;PLOT=Yes","DRK=none,DRKMODE=0,",""}
	Make/O/T/N=8 $"root:Packages:NIST:VSANS:Globals:Protocols:CreateNew"			//null wave
	//Initialize waves to store values in
	
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gNewStr=""
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = "AVTYPE=Circular;SAVE=Yes;NAME=Auto;PLOT=Yes;"
	
	Return(0)
End

//simple function to resize the comand window to a nice size, no matter what the resolution
//need to test out on several different monitors and both platforms
//
// could easily be incorporated into the initialization routines to ensure that the 
// command window is always visible at startup of the macros. No need for a hook function
//
Function ResizeCmdWindow()

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