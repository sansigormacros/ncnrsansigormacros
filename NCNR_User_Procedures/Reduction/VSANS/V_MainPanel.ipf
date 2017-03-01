#pragma rtGlobals=1		// Use modern global access method.


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


// TODO
//
// -- update this to be VSANS-specific, eliminating junk that is SANS only or VAX-specific
//


// TODO-- decide whether to automatically read in the mask, or not
// -- there could be a default mask, or look for the mask that is speficied in the
// next file that is read in from the path
Proc PickPath_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
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
End

Proc DrawMask_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	V_Edit_a_Mask()
End


//
// this will only load the data into RAW, overwriting whatever is there. no copy is put in rawVSANS
//
Proc DisplayMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Variable err=	V_LoadHDF5Data("","RAW")			// load the data 
//	Print "Load err = "+num2str(err)
	if(!err)
		String hdfDF = root:file_name			// last file loaded, may not be the safest way to pass
		String folder = StringFromList(0,hdfDF,".")
		
		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW")		// plot the data in whatever folder type
				
		// set the global to display ONLY if the load was called from here, not from the 
		// other routines that load data (to read in values)
		root:Packages:NIST:VSANS:Globals:gLastLoadedFile = root:file_name
		
	endif
End

Proc PatchMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_PatchFiles()
End

Proc TransMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	 CalcTrans()
End

Proc BuildProtocol_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_ReductionProtocolPanel()
End

Proc ReduceAFile_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ReduceAFile()
End

Proc ReduceMultiple_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ReduceMultipleFiles()
End

Proc Plot1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//LoadOneDData()
	Show_Plot_Manager()
End

Proc Sort1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ShowNSORTPanel()
End

Proc Combine1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ShowCombinePanel()
End


Proc Fit1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	OpenFITPanel()
End

//Proc FitRPA_MainButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	OpenFITRPAPanel()
//End

Proc Subtract1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	OpenSubtract1DPanel()
End

Proc Arithmetic1D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	MakeDAPanel()
End

Proc DisplayInterm_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_ChangeDisplay()
End

// TODO -- fill in with a proper reader that will display the mask(s)
Proc ReadMask_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoAlert 0, "Loading MASK data"
	V_LoadMASKData()
End

Proc Draw3D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Plot3DSurface()
End

////on Misc Ops tab, generates a notebook
//Proc CatShort_MainButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	BuildCatShortNotebook()
//End

//button is labeled "File Catalog"
Proc CatVShort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_BuildCatVeryShortTable()
End

Proc CatSort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	V_Catalog_Sort()
End

Proc ShowCatShort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ShowCATWindow()
End

Proc ShowSchematic_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if(root:myGlobals:isDemoVersion == 1)
		//	comment out in DEMO_MODIFIED version, and show the alert
		DoAlert 0,"This operation is not available in the Demo version of IGOR"
	else
		ShowSchematic()
	endif
End

Proc ShowAvePanel_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ShowAveragePanel()
End

Proc HelpMainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
	endif
End

Proc ShowTilePanel_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if(root:myGlobals:isDemoVersion == 1)
		//	comment out in DEMO_MODIFIED version, and show the alert
		DoAlert 0,"This operation is not available in the Demo version of IGOR"
	else
		Show_Tile_2D_Panel()
	endif
End

Proc NG1TransConv_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	TransformToTransFile()
End

Proc CopyWork_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_CopyWorkFolder()		//will put up missing param dialog
End

Proc PRODIV_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//new, May 2009. show a full panel for input
	BuildDIVPanel()
//	MakeDIVFile("","")			
End


Proc WorkMath_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Show_WorkMath_Panel()
End

//Proc TISANE_MainButtonProc(ctrlName) : ButtonControl
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

Proc Event_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if(exists("Show_Event_Panel")==0)
		// procedure file was not loaded
		DoAlert 0,"This operation is not available in this set of macros"
	else
		Show_Event_Panel()
	endif
	
End

Proc Raw2ASCII_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Export_RAW_Ascii_Panel()
End

Proc RealTime_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	if(exists("Init_for_RealTime")==0)
		// procedure file was not loaded
		DoAlert 0,"This operation is not available in this set of macros"
	else
		Show_RealTime_Panel()
	endif
End

Proc Preferences_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Show_VSANSPreferences_Panel()
End


Proc DataTree_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_ShowDataFolderTree()
End

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
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(500,60,924,320) /K=2 as "VSANS Reduction Controls"
	ModifyPanel cbRGB=(49694,61514,27679)
	ModifyPanel fixedSize=1
//////
//on main portion of panel
	Button MainButtonA,pos={8,8},size={80,20},title="Pick Path",proc=PickPath_MainButtonProc
	Button MainButtonA,help={"Pick the local data folder that contains the SANS data"}
	Button MainButtonB,pos={100,8},size={90,20},proc=CatVShort_MainButtonProc,title="File Catalog"
	Button MainButtonB,help={"This will generate a condensed CATalog table of all files in a specified local folder"}
	Button MainButtonC,pos={250,8},size={50,20},proc=HelpMainButtonProc,title="Help"
	Button MainButtonC,help={"Display the help file"}
	Button MainButtonD,pos={320,8},size={80,20},proc=SR_OpenTracTicketPage,title="Feedback"
	Button MainButtonD,help={"Submit bug reports or feature requests"}
	
	TabControl MainTab,pos={7,49},size={410,202},tabLabel(0)="Raw Data",proc=MainTabProc
	TabControl MainTab,tabLabel(1)="Reduction",tabLabel(2)="1-D Ops",tabLabel(3)="2-D Ops",tabLabel(4)="Misc Ops"
	TabControl MainTab,value=0
	//
	TabControl MainTab labelBack=(47748,57192,54093)
	
//on tab(0) - Raw Data - initially visible
	Button MainButton_0a,pos={15,90},size={130,20},proc=DisplayMainButtonProc,title="Display Raw Data"
	Button MainButton_0a,help={"Display will load and plot a single 2-D raw data file"}
	Button MainButton_0b,pos={15,120},size={70,20},proc=PatchMainButtonProc,title="Patch"
	Button MainButton_0b,help={"Patch will update incorrect information in raw data headers"}
	Button MainButton_0c,pos={15,150},size={110,20},proc=TransMainButtonProc,title="Transmission"
	Button MainButton_0c,help={"Shows the \"Patch\" panel which allows calculation of sample transmissions and entering these values into raw data headers"}
	Button MainButton_0d,pos={15,180},size={130,20},proc=RealTime_MainButtonProc,title="RealTime Display"
	Button MainButton_0d,help={"Shows the panel for control of the RealTime data display. Only used during data collection"}
	Button MainButton_0e,pos={15,210},size={130,20},proc=CatSort_MainButtonProc,title="Sort Catalog"
	Button MainButton_0e,help={"Sort the Data Catalog, courtesy of ANSTO"}
	Button MainButton_0f,pos={170,90},size={90,20},proc=DataTree_MainButtonProc,title="Data Tree"
	Button MainButton_0f,help={"Show the header and data tree"}


//on tab(1) - Reduction
	Button MainButton_1a,pos={15,90},size={110,20},proc=BuildProtocol_MainButtonProc,title="Build Protocol"
	Button MainButton_1a,help={"Shows a panel where the CATalog window is used as input for creating a protocol. Can also be used for standard reductions"}
	Button MainButton_1b,pos={15,120},size={110,20},proc=ReduceAFile_MainButtonProc,title="Reduce a File"
	Button MainButton_1b,help={"Presents a questionnare for creating a reduction protocol, then reduces a single file"}
	Button MainButton_1c,pos={15,150},size={160,20},proc=ReduceMultiple_MainButtonProc,title="Reduce Multiple Files"
	Button MainButton_1c,help={"Use for reducing multiple raw datasets after protocol(s) have been created"}
	Button MainButton_1d,pos={15,180},size={110,20},proc=ShowCatShort_MainButtonProc,title="Show CAT Table"
	Button MainButton_1d,help={"This button will bring the CATalog window to the front, if it exists"}
	Button MainButton_1a,disable=1
	Button MainButton_1b,disable=1
	Button MainButton_1c,disable=1
	Button MainButton_1d,disable=1

//on tab(2) - 1-D operations
	Button MainButton_2a,pos={15,90},size={60,20},proc=Plot1D_MainButtonProc,title="Plot"
	Button MainButton_2a,help={"Loads and plots a 1-D dataset in the format expected by \"FIT\""}
	Button MainButton_2b,pos={15,120},size={60,20},proc=Sort1D_MainButtonProc,title="Sort"
	Button MainButton_2b,help={"Sorts and combines 2 or 3 separate 1-D datasets into a single file. Use \"Plot\" button to import 1-D data files"}
	Button MainButton_2c,pos={15,150},size={60,20},proc=Fit1D_MainButtonProc,title="FIT"
	Button MainButton_2c,help={"Shows panel for performing a variety of linearized fits to 1-D data files. Use \"Plot\" button to import 1-D data files"}
//	Button MainButton_2d,pos={15,180},size={60,20},proc=FITRPA_MainButtonProc,title="FIT/RPA"
//	Button MainButton_2d,help={"Shows panel for performing a fit to a polymer standard."}
//	Button MainButton_2e,pos={120,90},size={90,20},proc=Subtract1D_MainButtonProc,title="Subtract 1D"
//	Button MainButton_2e,help={"Shows panel for subtracting two 1-D data sets"}
	Button MainButton_2e,pos={120,90},size={110,20},proc=Arithmetic1D_MainButtonProc,title="1D Arithmetic"
	Button MainButton_2e,help={"Shows panel for doing arithmetic on 1D data sets"}
	Button MainButton_2f,pos={120,120},size={130,20},proc=Combine1D_MainButtonProc,title="Combine 1D Files"
	Button MainButton_2f,help={"Shows panel for batch combination of 1D data files. Use after you're comfortable with NSORT"}
	Button MainButton_2a,disable=1
	Button MainButton_2b,disable=1
	Button MainButton_2c,disable=1
//	Button MainButton_2d,disable=1
	Button MainButton_2e,disable=1
	Button MainButton_2f,disable=1



//on tab(3) - 2-D Operations
	Button MainButton_3a,pos={15,90},size={90,20},proc=DisplayInterm_MainButtonProc,title="Display 2D"
	Button MainButton_3a,help={"Display will plot a 2-D work data file that has previously been created during data reduction"}
	Button MainButton_3b,pos={15,120},size={90,20},title="Draw Mask",proc=DrawMask_MainButtonProc
	Button MainButton_3b,help={"Draw a mask file and save it."}
	Button MainButton_3c,pos={15,150},size={90,20},proc=ReadMask_MainButtonProc,title="Read Mask"
	Button MainButton_3c,help={"Reads a mask file into the proper work folder, and displays a small image of the mask. Yellow areas will be excluded from the data"}
	Button MainButton_3d,pos={15,180},size={100,20},title="Tile RAW 2D",proc=ShowTilePanel_MainButtonProc
	Button MainButton_3d,help={"Adds selected RAW data files to a layout."}
	Button MainButton_3e,pos={150,90},size={100,20},title="Copy Work",proc=CopyWork_MainButtonProc
	Button MainButton_3e,help={"Copies WORK data from specified folder to destination folder."}
	Button MainButton_3f,pos={150,120},size={110,20},title="WorkFile Math",proc=WorkMath_MainButtonProc
	Button MainButton_3f,help={"Perfom simple math operations on workfile data"}
	Button MainButton_3g,pos={150,180},size={100,20},title="Event Data",proc=Event_MainButtonProc
	Button MainButton_3g,help={"Manipulate TISANE Timeslice data"}
	
	Button MainButton_3a,disable=1
	Button MainButton_3b,disable=1
	Button MainButton_3c,disable=1
	Button MainButton_3d,disable=1
	Button MainButton_3e,disable=1
	Button MainButton_3f,disable=1
	Button MainButton_3g,disable=1

//on tab(4) - Miscellaneous operations
	Button MainButton_4a,pos={15,90},size={80,20},proc=Draw3D_MainButtonProc,title="3D Display"
	Button MainButton_4a,help={"Plots a 3-D surface of the selected file type"}
	Button MainButton_4b,pos={15,120},size={120,20},proc=ShowSchematic_MainButtonProc,title="Show Schematic"
	Button MainButton_4b,help={"Use this to show a schematic of the data reduction process for a selected sample file and reduction protocol"}
	Button MainButton_4c,pos={15,150},size={80,20},proc=ShowAvePanel_MainButtonProc,title="Average"
	Button MainButton_4c,help={"Shows a panel for interactive selection of the 1-D averaging step"}
//	Button MainButton_4d,pos={15,180},size={110,20},proc=CatShort_MainButtonProc,title="CAT/Notebook"
//	Button MainButton_4d,help={"This will generate a CATalog notebook of all files in a specified local folder"}
//	Button MainButton_4e,pos={180,90},size={130,20},proc=NG1TransConv_MainButtonProc,title="NG1 Files to Trans"
//	Button MainButton_4e,help={"Converts NG1 transmission data files to be interpreted as such"}
	Button MainButton_4f,pos={180,120},size={130,20},proc=PRODIV_MainButtonProc,title="Make DIV file"
	Button MainButton_4f,help={"Merges two stored workfiles (CORrected) into a DIV file, and saves the result"}
	Button MainButton_4g,pos={180,150},size={130,20},proc=Raw2ASCII_MainButtonProc,title="RAW ASCII Export"
	Button MainButton_4g,help={"Exports selected RAW (2D) data file(s) as ASCII, either as pixel values or I(Qx,Qy)"}
	Button MainButton_4h,pos={180,180},size={130,20},proc=Preferences_MainButtonProc,title="Preferences"
	Button MainButton_4h,help={"Sets user preferences for selected parameters"}
	
	Button MainButton_4a,disable=1
	Button MainButton_4b,disable=1
	Button MainButton_4c,disable=1
//	Button MainButton_4d,disable=1
//	Button MainButton_4e,disable=1
	Button MainButton_4f,disable=1
	Button MainButton_4g,disable=1
	Button MainButton_4h,disable=1
//	
EndMacro

// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will 
// appear in odd places...
// all buttons are named MainButton_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly..
//
Function MainTabProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"MainButton_"
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,10]
		if(cmpstr(nameStr,"MainButton_")==0)
			onTab = str2num(item[11])
			Button $item,disable=(tab!=onTab)
		endif
	endfor 
End

//
Function SR_OpenTracTicketPage(ctrlName)
	String ctrlName
	DoAlert 1,"Your web browser will open to a page where you can submit your bug report or feature request. OK?"
	if(V_flag==1)
		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
	endif
End

