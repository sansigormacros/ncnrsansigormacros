#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method.
#pragma IgorVersion=7.00

//
//*********************
//
//draws main panel of buttons for all data reduction operations
//panel can't be killed (without really trying)
// V_initialize() from the VSANS menu will redraw the panel
//panel simply dispatches to previously written procedures (not functions)
//
// **function names are really self-explanatory...see the called function for the real details
//
//**********************
//

//
//
// x- update this to be VSANS-specific, eliminating junk that is SANS only or VAX-specific
//

//
// x- decide whether to automatically read in the mask, or not (NO)
// x- there could be a default mask, or look for the mask that is speficied in the
// next file that is read in from the path
Proc V_PickPath_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_PickPath()
	// read in DEFAULT.MASK, if it exists, otherwise, do nothing
	//
	//	PathInfo catPathName
	//	if(V_flag==1)
	//		String str = S_Path + "DEFAULT.MASK"
	//		Variable refnum
	//		Open/R/Z=1 refnum as str
	//		if(strlen(S_filename) != 0)
	//			Close refnum		//file can be found OK
	//			ReadMCID_MASK(str)
	//		else
	//			// file not found, close just in case
	//			Close/A
	//		endif
	//	endif
EndMacro

Proc V_DrawMask_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_Edit_a_Mask()
EndMacro

//
// this will only load the data into RAW, overwriting whatever is there. no copy is put in rawVSANS
//
Proc V_DisplayMainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	variable err = V_LoadHDF5Data("", "RAW") // load the data
	//	Print "Load err = "+num2str(err)
	if(!err)
		string hdfDF  = root:file_name // last file loaded, may not be the safest way to pass
		string folder = StringFromList(0, hdfDF, ".")

		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

		// set the global to display ONLY if the load was called from here, not from the
		// other routines that load data (to read in values)
		root :Packages:NIST:VSANS:Globals:gLastLoadedFile=root:file_name

	endif
EndMacro

Proc V_PatchMainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_PatchFiles()
EndMacro

Proc V_Patch_XY_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_PatchDet_xyCenters_Panel()
EndMacro

Proc V_Patch_DeadTime_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_PatchDetectorDeadtimePanel()
EndMacro

Proc V_Patch_Calib_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_PatchDetectorCalibrationPanel()
EndMacro

Proc V_TransMainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_InitTransmissionPanel()
EndMacro

Proc V_BuildProtocol_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ReductionProtocolPanel()
EndMacro

Proc V_ReduceAFile_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ReductionProtocolPanel()
	//	ReduceAFile()
EndMacro

Proc V_ReduceMultiple_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ReduceMultipleFiles()
EndMacro

Proc V_Plot1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	//LoadOneDData()
	Show_Plot_Manager()
EndMacro

Proc V_Sort1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	//	ShowNSORTPanel()

EndMacro

Proc V_Combine1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	//	ShowCombinePanel()
	V_CombineDataGraph()
EndMacro

Proc V_Fit1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	DoAlert 0, "This function has not been updated for VSANS yet..."

	//	OpenFITPanel()
EndMacro

//Proc V_FitRPA_MainButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	OpenFITRPAPanel()
//End

Proc V_Subtract1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	OpenSubtract1DPanel()
EndMacro

Proc V_Arithmetic1D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	DoAlert 0, "This function has not been updated for VSANS yet..."

	//	MakeDAPanel()
EndMacro

Proc V_DisplayInterm_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ChangeDisplay()
EndMacro

//
// - fill in with a proper reader that will display the mask(s)
Proc V_ReadMask_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	DoAlert 0, "Loading MASK data"
	V_LoadMASKData()
EndMacro

Proc V_Draw3D_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	//	DoAlert 0, "This function has not been updated for VSANS yet..."
	DoAlert 0, "Right-click on the image and select '3D Surface from data'"

	//	Plot3DSurface()

EndMacro

////on Misc Ops tab, generates a notebook
//Proc V_CatShort_MainButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	BuildCatShortNotebook()
//End

//button is labeled "File Catalog"
Proc V_CatVShort_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_BuildCatVeryShortTable()
EndMacro

Proc V_CatSort_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_Catalog_Sort()
EndMacro

Proc V_ShowCatShort_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	ShowCATWindow()
EndMacro

Proc V_ShowSchematic_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	if(root:myGlobals:isDemoVersion == 1)
		//	comment out in DEMO_MODIFIED version, and show the alert
		DoAlert 0, "This operation is not available in the Demo version of IGOR"
	else
		ShowSchematic()
	endif
EndMacro

Proc V_ShowAvePanel_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	ShowAveragePanel()
EndMacro

Proc V_HelpMainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	//	DoAlert 0,"Do you want video help? You will be taken to the NCNR YouTube page."
	//	BrowseURL "https://youtu.be/_SB2gDxpwcI"
	//	BrowseURL "https://www.nist.gov/video/sans-reduction-macros-installation-instructions"

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Help file could not be found"
	endif
EndMacro

Proc V_ShowTilePanel_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	if(root:myGlobals:isDemoVersion == 1)
		//	comment out in DEMO_MODIFIED version, and show the alert
		DoAlert 0, "This operation is not available in the Demo version of IGOR"
	else
		Show_Tile_2D_Panel()
	endif
EndMacro

Proc V_NonLinTubes_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_TubeCoefPanel()
EndMacro

Proc V_CopyWork_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_CopyWorkFolder() //will put up missing param dialog
EndMacro

Proc V_PRODIV_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	DoWindow/F DIV_Setup_Panel
	if(V_flag == 0)
		DIV_Setup_Panel()
	endif

	DoWindow/F VSANS_DIVPanels
	if(V_flag == 0)
		V_Display_DIV_Panels()
	endif
EndMacro

Proc V_WorkMath_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	Show_WorkMath_Panel()
EndMacro

//Proc V_TISANE_MainButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	if(exists("Show_TISANE_Panel")==0)
//		// procedure file was not loaded
//		DoAlert 0,"This operation is not available in this set of macros"
//	else
//		Show_TISANE_Panel()
//	endif
//
//End

Proc V_Event_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	if(exists("V_Show_Event_Panel") == 0)
		// procedure file was not loaded
		DoAlert 0, "Only test procedures exist. See V_VSANS_Event_Testing.ipf"
	else
		V_Show_Event_Panel()
	endif

EndMacro

Proc V_Event_MultReduceButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ReduceEventFilesPanel()

EndMacro

Proc V_Event_FileTableButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_MakeEventFileTable()

EndMacro

Proc V_Raw2ASCII_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	Export_RAW_Ascii_Panel()
EndMacro

Proc V_RealTime_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	if(exists("V_Init_RT") == 0)
		// procedure file was not loaded
		DoAlert 0, "This operation is not available in this set of macros"
	else
		V_Show_RealTime_Panel()
	endif
EndMacro

Proc V_RTReduce_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ShowOnlineReductionPanel()
EndMacro

Proc V_Preferences_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	Show_VSANSPreferences_Panel()
EndMacro

Proc V_DataTree_MainButtonProc(ctrlName) : ButtonControl
	string ctrlName

	V_ShowDataFolderTree()
EndMacro

////////////////////////////////////////////////
//************* NEW version of Main control Panel *****************
//
// button management for the different tabs is handled by consistent
// naming of each button with its tab number as documented below
// then MainTabProc() can enable/disable the appropriate buttons for the
// tab that is displayed
//
// panel must be killed and redrawn for new buttons to appear
//
Window Main_VSANS_Panel()
	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(500 * sc, 60 * sc, 924 * sc, 320 * sc)/K=1 as "VSANS Reduction Controls" + " " + num2str(kVSANSVersion)
	ModifyPanel cbRGB=(49694, 61514, 27679)
	ModifyPanel fixedSize=1
	//////
	//on main portion of panel
	Button MainButtonA, pos={sc * 8, 8 * sc}, size={sc * 80, 20 * sc}, title="Pick Path", proc=V_PickPath_MainButtonProc
	Button MainButtonA, help={"Pick the local data folder that contains the VSANS data"}
	Button MainButtonB, pos={sc * 100, 8 * sc}, size={sc * 90, 20 * sc}, proc=V_CatVShort_MainButtonProc, title="File Catalog"
	Button MainButtonB, help={"This will generate a condensed CATalog table of all files in a specified local folder"}
	Button MainButtonC, pos={sc * 250, 8 * sc}, size={sc * 50, 20 * sc}, proc=V_HelpMainButtonProc, title="Help"
	Button MainButtonC, help={"Display the help file"}
	Button MainButtonD, pos={sc * 320, 8 * sc}, size={sc * 80, 20 * sc}, proc=V_emailFeedback, title="Feedback"
	Button MainButtonD, help={"Submit bug reports or feature requests"}

	TabControl MainTab, pos={sc * 7, 49 * sc}, size={sc * 410, 202 * sc}, tabLabel(0)="Raw Data", proc=V_MainTabProc
	TabControl MainTab, tabLabel(1)="Reduction", tabLabel(2)="1-D Ops", tabLabel(3)="2-D Ops", tabLabel(4)="Misc Ops"
	TabControl MainTab, value=0
	//
	TabControl MainTab, labelBack=(47748, 57192, 54093)

	//on tab(0) - Raw Data - initially visible
	Button MainButton_0a, pos={sc * 15, 90 * sc}, size={sc * 130, 20 * sc}, proc=V_DisplayMainButtonProc, title="Display Raw Data"
	Button MainButton_0a, help={"Display will load and plot a single 2-D raw data file"}
	Button MainButton_0b, pos={sc * 15, 120 * sc}, size={sc * 70, 20 * sc}, proc=V_PatchMainButtonProc, title="Patch"
	Button MainButton_0b, help={"Patch will update incorrect information in raw data headers"}
	Button MainButton_0c, pos={sc * 15, 150 * sc}, size={sc * 110, 20 * sc}, proc=V_TransMainButtonProc, title="Transmission"
	Button MainButton_0c, help={"Shows the panel which allows calculation of sample transmissions and patching values into raw data headers"}
	Button MainButton_0d, pos={sc * 15, 180 * sc}, size={sc * 130, 20 * sc}, proc=V_RealTime_MainButtonProc, title="RealTime Display"
	Button MainButton_0d, help={"Shows the panel for control of the RealTime data display. Only used during data collection"}
	Button MainButton_0e, pos={sc * 15, 210 * sc}, size={sc * 130, 20 * sc}, proc=V_CatSort_MainButtonProc, title="Sort Catalog"
	Button MainButton_0e, help={"Sort the Data Catalog, courtesy of ANSTO"}
	Button MainButton_0f, pos={sc * 300, 90 * sc}, size={sc * 90, 20 * sc}, proc=V_DataTree_MainButtonProc, title="Data Tree"
	Button MainButton_0f, help={"Show the header and data tree"}
	Button MainButton_0g, pos={sc * 170, 180 * sc}, size={sc * 110, 20 * sc}, proc=V_RTReduce_MainButtonProc, title="RT Reduction"
	Button MainButton_0g, help={"Reduce live (incomplete) data files during acquisition"}
	Button MainButton_0h, pos={sc * 170, 90 * sc}, size={sc * 90, 20 * sc}, proc=V_Patch_XY_MainButtonProc, title="Patch XY"
	Button MainButton_0h, help={"Easy patching of XY beam center to multiple files"}
	Button MainButton_0i, pos={sc * 170, 120 * sc}, size={sc * 110, 20 * sc}, proc=V_Patch_DeadTime_MainButtonProc, title="Patch DeadTime"
	Button MainButton_0i, help={"Easy patching of dead time tables to multiple files"}
	Button MainButton_0j, pos={sc * 170, 150 * sc}, size={sc * 90, 20 * sc}, proc=V_Patch_Calib_MainButtonProc, title="Patch Calib"
	Button MainButton_0j, help={"Easy patching of nonlinear calibration tables to multiple files"}

	//on tab(1) - Reduction
	Button MainButton_1a, pos={sc * 15, 90 * sc}, size={sc * 110, 20 * sc}, proc=V_BuildProtocol_MainButtonProc, title="Build Protocol"
	Button MainButton_1a, help={"Shows a panel where the CATalog window is used as input for creating a protocol. Can also be used for standard reductions"}
	//	Button MainButton_1b,pos={sc*15,120*sc},size={sc*110,20*sc},proc=V_ReduceAFile_MainButtonProc,title="Reduce a File"
	//	Button MainButton_1b,help={"Presents a questionnare for creating a reduction protocol, then reduces a single file"}
	Button MainButton_1c, pos={sc * 15, 150 * sc}, size={sc * 160, 20 * sc}, proc=V_ReduceMultiple_MainButtonProc, title="Reduce Multiple Files"
	Button MainButton_1c, help={"Use for reducing multiple raw datasets after protocol(s) have been created"}
	//	Button MainButton_1d,pos={sc*15,180*sc},size={sc*110,20*sc},proc=V_ShowCatShort_MainButtonProc,title="Show CAT Table"
	//	Button MainButton_1d,help={"This button will bring the CATalog window to the front, if it exists"}
	Button MainButton_1a, disable=1
	//	Button MainButton_1b,disable=1
	Button MainButton_1c, disable=1
	//	Button MainButton_1d,disable=1

	//on tab(2) - 1-D operations
	Button MainButton_2a, pos={sc * 15, 90 * sc}, size={sc * 60, 20 * sc}, proc=V_Plot1D_MainButtonProc, title="Plot"
	Button MainButton_2a, help={"Loads and plots a 1-D dataset in the format expected by \"FIT\""}
	//	Button MainButton_2b,pos={sc*15,120*sc},size={sc*60,20*sc},proc=V_Sort1D_MainButtonProc,title="Sort"
	//	Button MainButton_2b,help={"Sorts and combines 2 or 3 separate 1-D datasets into a single file. Use \"Plot\" button to import 1-D data files"}
	Button MainButton_2c, pos={sc * 15, 150 * sc}, size={sc * 60, 20 * sc}, proc=V_Fit1D_MainButtonProc, title="FIT"
	Button MainButton_2c, help={"Shows panel for performing a variety of linearized fits to 1-D data files. Use \"Plot\" button to import 1-D data files"}
	//	Button MainButton_2d,pos={sc*15,180*sc},size={sc*60,20*sc},proc=V_FITRPA_MainButtonProc,title="FIT/RPA"
	//	Button MainButton_2d,help={"Shows panel for performing a fit to a polymer standard."}
	//	Button MainButton_2e,pos={sc*120,90*sc},size={sc*90,20*sc},proc=V_Subtract1D_MainButtonProc,title="Subtract 1D"
	//	Button MainButton_2e,help={"Shows panel for subtracting two 1-D data sets"}
	Button MainButton_2e, pos={sc * 120, 90 * sc}, size={sc * 110, 20 * sc}, proc=V_Arithmetic1D_MainButtonProc, title="1D Arithmetic"
	Button MainButton_2e, help={"Shows panel for doing arithmetic on 1D data sets"}
	Button MainButton_2f, pos={sc * 120, 120 * sc}, size={sc * 130, 20 * sc}, proc=V_Combine1D_MainButtonProc, title="Combine 1D Files"
	Button MainButton_2f, help={"Shows panel for selecting points to trim before combining files"}
	Button MainButton_2a, disable=1
	//	Button MainButton_2b,disable=1
	Button MainButton_2c, disable=1
	//	Button MainButton_2d,disable=1
	Button MainButton_2e, disable=1
	Button MainButton_2f, disable=1

	//on tab(3) - 2-D Operations
	Button MainButton_3a, pos={sc * 15, 90 * sc}, size={sc * 90, 20 * sc}, proc=V_DisplayInterm_MainButtonProc, title="Display 2D"
	Button MainButton_3a, help={"Display will plot a 2-D work data file that has previously been created during data reduction"}
	Button MainButton_3b, pos={sc * 15, 120 * sc}, size={sc * 90, 20 * sc}, title="Draw Mask", proc=V_DrawMask_MainButtonProc
	Button MainButton_3b, help={"Draw a mask file and save it."}
	Button MainButton_3c, pos={sc * 15, 150 * sc}, size={sc * 90, 20 * sc}, proc=V_ReadMask_MainButtonProc, title="Read Mask"
	Button MainButton_3c, help={"Reads a mask file into the proper work folder"}
	//	Button MainButton_3d,pos={sc*15,180*sc},size={sc*100,20*sc},title="Tile RAW 2D",proc=V_ShowTilePanel_MainButtonProc
	//	Button MainButton_3d,help={"Adds selected RAW data files to a layout."}
	Button MainButton_3e, pos={sc * 150, 90 * sc}, size={sc * 100, 20 * sc}, title="Copy Work", proc=V_CopyWork_MainButtonProc
	Button MainButton_3e, help={"Copies WORK data from specified folder to destination folder."}
	//	Button MainButton_3f,pos={sc*150,120*sc},size={sc*110,20*sc},title="WorkFile Math",proc=V_WorkMath_MainButtonProc
	//	Button MainButton_3f,help={"Perfom simple math operations on workfile data"}
	Button MainButton_3g, pos={sc * 150, 150 * sc}, size={sc * 100, 20 * sc}, title="Event Data", proc=V_Event_MainButtonProc
	Button MainButton_3g, help={"Manipulate VSANS Event Mode data"}
	Button MainButton_3h, pos={sc * 150, 180 * sc}, size={sc * 140, 20 * sc}, title="Event Reduction", proc=V_Event_MultReduceButtonProc
	Button MainButton_3h, help={"Reduce VSANS Event Mode data"}
	Button MainButton_3i, pos={sc * 150, 210 * sc}, size={sc * 140, 20 * sc}, title="Event File Table", proc=V_Event_FileTableButtonProc
	Button MainButton_3i, help={"Make a table of raw data files and the associated event files"}

	Button MainButton_3a, disable=1
	Button MainButton_3b, disable=1
	Button MainButton_3c, disable=1
	//	Button MainButton_3d,disable=1
	Button MainButton_3e, disable=1
	//	Button MainButton_3f,disable=1
	Button MainButton_3g, disable=1
	Button MainButton_3h, disable=1
	Button MainButton_3i, disable=1

	//on tab(4) - Miscellaneous operations
	Button MainButton_4a, pos={sc * 15, 90 * sc}, size={sc * 80, 20 * sc}, proc=V_Draw3D_MainButtonProc, title="3D Display"
	Button MainButton_4a, help={"Plots a 3-D surface of the selected file type"}
	//	Button MainButton_4b,pos={sc*15,120*sc},size={sc*120,20*sc},proc=V_ShowSchematic_MainButtonProc,title="Show Schematic"
	//	Button MainButton_4b,help={"Use this to show a schematic of the data reduction process for a selected sample file and reduction protocol"}
	//	Button MainButton_4c,pos={sc*15,150*sc},size={sc*80,20*sc},proc=V_ShowAvePanel_MainButtonProc,title="Average"
	//	Button MainButton_4c,help={"Shows a panel for interactive selection of the 1-D averaging step"}
	//	Button MainButton_4d,pos={sc*15,180*sc},size={sc*110,20*sc},proc=V_CatShort_MainButtonProc,title="CAT/Notebook"
	//	Button MainButton_4d,help={"This will generate a CATalog notebook of all files in a specified local folder"}
	Button MainButton_4e, pos={sc * 180, 90 * sc}, size={sc * 130, 20 * sc}, proc=V_NonLinTubes_MainButtonProc, title="Fit NonLinear Tubes"
	Button MainButton_4e, help={""}
	Button MainButton_4f, pos={sc * 180, 120 * sc}, size={sc * 130, 20 * sc}, proc=V_PRODIV_MainButtonProc, title="Make DIV file"
	Button MainButton_4f, help={"Displays panels and outlines the steps for generating a detector sensitivity file"}
	//	Button MainButton_4g,pos={sc*180,150*sc},size={sc*130,20*sc},proc=V_Raw2ASCII_MainButtonProc,title="RAW ASCII Export"
	//	Button MainButton_4g,help={"Exports selected RAW (2D) data file(s) as ASCII, either as pixel values or I(Qx,Qy)"}
	Button MainButton_4h, pos={sc * 180, 180 * sc}, size={sc * 130, 20 * sc}, proc=V_Preferences_MainButtonProc, title="Preferences"
	Button MainButton_4h, help={"Sets user preferences for selected parameters"}

	Button MainButton_4a, disable=1
	//	Button MainButton_4b,disable=1
	//	Button MainButton_4c,disable=1
	//	Button MainButton_4d,disable=1
	Button MainButton_4e, disable=1
	Button MainButton_4f, disable=1
	//	Button MainButton_4g,disable=1
	Button MainButton_4h, disable=1
	//
EndMacro

// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will
// appear in odd places...
// all buttons are named MainButton_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly..
//
Function V_MainTabProc(string name, variable tab)

	//	Print "name,number",name,tab
	string ctrlList = ControlNameList("", ";")
	string item     = ""
	string nameStr  = ""
	variable ii, onTab
	variable num = ItemsinList(ctrlList, ";")
	for(ii = 0; ii < num; ii += 1)
		//items all start w/"MainButton_"
		item    = StringFromList(ii, ctrlList, ";")
		nameStr = item[0, 10]
		if(cmpstr(nameStr, "MainButton_") == 0)
			onTab = str2num(item[11])
			Button $item, disable=(tab != onTab)
		endif
	endfor
End

//can't point to the gitHub page - you need to have an account to create a ticket
Function V_emailFeedback(string ctrlName)

	DoAlert 0, "To submit your feature/question/bug report, email directly to the support contacts as noted on the NCNR web page"
	//	DoAlert 1,"Your web browser will open to a page where you can submit your bug report or feature request. OK?"
	if(V_flag == 1)
		//		BrowseURL "https://github.com/sansigormacros/ncnrsansigormacros/issues"
		//		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
	endif
End

