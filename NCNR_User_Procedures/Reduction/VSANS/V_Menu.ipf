#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


//**************************
// Vers 1.2 091901
//
//****************************
//


Menu "VSANS"
	"Initialize",Initialize_VSANS()
	"VSANS Help"
	"-"
	"Main Control Panel",DoWindow/F Main_VSANS_Panel
	"Data Display",DoWindow/F VSANS_Data
	"VCALC",VCALC_Panel()
	"-"
	Submenu "In Progress Panels"
		"VSANS Preferences",Show_VSANSPreferences_Panel()
		"Beam Center Panel",V_FindBeamCenter()
		"Patch Beam Center XY",V_PatchDet_xyCenters_Panel()
		"Patch Detector Deadtime",V_PatchDetectorDeadtimePanel()
	End
	Submenu "Work Files"
		"Convert to WORK",Convert_to_Workfile()
		"Load Fake DIV Data"
		"DIV a work file",DIV_a_Workfile()
		"Load Fake MASK Data"
		"Correct Data",V_CorrectData()
	End
	
End


//
Menu "SANS"
	"Initialize"
	"SANS Help"
	"-"
	"Main Control Panel",DoWindow/F Main_Panel
	"SASCALC"
	"-"
	Submenu "Data Display"
		"Show 2D SANS Data",DoWindow/F SANS_Data
		"Show File Table",ShowCatWindow()
	End
	Submenu "Input Panels"
		"Calculate Transmissions",CalcTrans()
		"Build Reduction Protocols",ReductionProtocolPanel()
		"Reduce Multiple Files",ReduceMultipleFiles()
		"Patch Files",PatchFiles()
		"1D Average",ShowAveragePanel()		
	End
	Submenu "1-D Processing"
		"Load and Plot 1D Data",Show_Plot_Manager()
		"Open FIT Panel",OpenFITPanel()
		"Sort and Combine data",ShowNSORTPanel()
//		"Subtract 1D Data Sets",OpenSubtract1DPanel()
		"ReWrite Experimental Data",MakeDMPanel()		//,ReWrite1DData()	// SRK SEP10
		"1D Arithmetic Panel",MakeDAPanel()
		"ReBin 1D Data",OpenRebin()
	End
	Submenu "2-D Processing"
		"2D Work file Math",Show_WorkMath_Panel()
		"Tile Raw 2D files",Show_Tile_2D_Panel()
		"Export 2D ASCII data",Export_RAW_Ascii_Panel()
		"Bin QxQy Data to 1D",BinQxQy_to_1D()
	End
	Submenu "Event Processing"
		"Event Mode Process Panel",Show_Event_Panel()
		"Adjust Events",ShowEventCorrectionPanel()
		"Create Custom Bins",Show_CustomBinPanel()
		"-"
		"Split Large File",SplitBigFile()
		"Accumulate First Slice",AccumulateSlices(0)
		"Add Current Slice",AccumulateSlices(1)
		"Display Accumulated Slices",AccumulateSlices(2)	
	End
	"-"
	"NCNR Preferences",Show_Preferences_Panel()
	"Feedback or Bug Report",OpenTracTicketPage()
	"Open Help Movie Page",OpenHelpMoviePage()
	"Check for Updates",CheckForLatestVersion()
//	Submenu "Utility Routines"
//		"Clear Work Folders"
//		"Clear Root Folder"
//	End
End

Function VSANSHelp()
	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found, because it has not yet been written"
	endif
End
