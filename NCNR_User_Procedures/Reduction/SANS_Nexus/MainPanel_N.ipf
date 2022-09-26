#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*********************
// Vers 1.2 091901
//
//draws main panel of buttons for all data reduction operations
//panel can't be killed (without really trying)
// initialize() from the SANS menu will redraw the panel
//panel simply dispatches to previously written procedures (not functions)
//
// **function names are really self-explanatory...see the called function for the real details
//
//**********************

Proc PickPath_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	PickPath()
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
	
	DrawMask()
End

Proc DisplayMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Variable err=	LoadRawSANSData("Select a Raw SANS data file")
	Variable err=	LoadRawSANSData("","RAW")
	if(!err)
		UpdateDisplayInformation("RAW")
	endif
End

Proc PatchMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	PatchFiles()
End

Proc TransMainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	 CalcTrans()
End

Proc BuildProtocol_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ReductionProtocolPanel()
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

Proc FitRPA_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	OpenFITRPAPanel()
End

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

	ChangeDisplay()
End

Proc KillWork_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	KillWorkFolder()
End

Proc ReadMask_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	ReadMask()
End

Proc Draw3D_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Plot3DSurface()
End

//on Misc Ops tab, generates a notebook
Proc CatShort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	BuildCatShortNotebook()
End

//button is labeled "File Catalog"
Proc CatVShort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//BuildCatVeryShortNotebook()
	BuildCatVeryShortTable()
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
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
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

	CopyWorkFolder()		//will put up missing param dialog
End

Proc PRODIV_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//new, May 2009. show a full panel for input
	BuildDIVPanel()
//	MakeDIVFile("","")			
End


// TODO - this panel is not yet operational with the Nexus macros
//
// --as long as the ASC export is correct, this should work with minor modifications
//
//
Proc WorkMath_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	DoAlert 0,"This operation is not yet available in this set of macros"

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

Proc Event_MultReduceButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
		ReduceEventFilesPanel()
	
End

Proc Event_FileTableButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if(exists("MakeEventFileTable")==0)
		// procedure file was not loaded
		DoAlert 0,"This operation is not available in this set of macros"
	else
		MakeEventFileTable()
	endif
End

Proc Raw2ASCII_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Export_RAW_Ascii_Panel()
End

Proc FileSort_MainButtonProc(ctrlName) : ButtonControl
	String ctrlName

	S_Catalog_Sort()
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

	Show_Preferences_Panel()
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
Window Main_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(500,60,924,320) /K=2 as "SANS Reduction Controls"
	ModifyPanel cbRGB=(65535,58981,27524)
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
	TabControl MainTab labelBack=(65535,58981,27524)
	
//on tab(0) - Raw Data - initially visible
	Button MainButton_0a,pos={15,90},size={120,20},proc=DisplayMainButtonProc,title="Display Raw Data"
	Button MainButton_0a,help={"Display will load and plot a single 2-D raw data file"}
	Button MainButton_0b,pos={15,120},size={70,20},proc=PatchMainButtonProc,title="Patch"
	Button MainButton_0b,help={"Patch will update incorrect information in raw data headers"}
	Button MainButton_0c,pos={15,150},size={120,20},proc=TransMainButtonProc,title="Transmission"
	Button MainButton_0c,help={"Shows the \"Patch\" panel which allows calculation of sample transmissions and entering these values into raw data headers"}
	Button MainButton_0d,pos={15,180},size={120,20},proc=RealTime_MainButtonProc,title="RealTime Display"
	Button MainButton_0d,help={"Shows the panel for control of the RealTime data display. Only used during data collection"}
	Button MainButton_0e,pos={15,210},size={120,20},proc=FileSort_MainButtonProc,title="Sort Catalog"
	Button MainButton_0e,help={"Shows the panel for sorting the file catalog"}

//on tab(1) - Reduction
	Button MainButton_1a,pos={15,90},size={120,20},proc=BuildProtocol_MainButtonProc,title="Build Protocol"
	Button MainButton_1a,help={"Shows a panel where the CATalog window is used as input for creating a protocol. Can also be used for standard reductions"}
	Button MainButton_1b,pos={15,120},size={120,20},proc=ReduceAFile_MainButtonProc,title="Reduce a File"
	Button MainButton_1b,help={"Presents a questionnare for creating a reduction protocol, then reduces a single file"}
	Button MainButton_1c,pos={15,150},size={120,20},proc=ReduceMultiple_MainButtonProc,title="Reduce Multiple Files"
	Button MainButton_1c,help={"Use for reducing multiple raw datasets after protocol(s) have been created"}
	Button MainButton_1d,pos={15,180},size={120,20},proc=ShowCatShort_MainButtonProc,title="Show CAT Table"
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
	Button MainButton_2d,pos={15,180},size={60,20},proc=FITRPA_MainButtonProc,title="FIT/RPA"
	Button MainButton_2d,help={"Shows panel for performing a fit to a polymer standard."}
//	Button MainButton_2e,pos={120,90},size={90,20},proc=Subtract1D_MainButtonProc,title="Subtract 1D"
//	Button MainButton_2e,help={"Shows panel for subtracting two 1-D data sets"}
	Button MainButton_2e,pos={120,90},size={110,20},proc=Arithmetic1D_MainButtonProc,title="1D Arithmetic"
	Button MainButton_2e,help={"Shows panel for doing arithmetic on 1D data sets"}
	Button MainButton_2f,pos={120,120},size={110,20},proc=Combine1D_MainButtonProc,title="Combine 1D Files"
	Button MainButton_2f,help={"Shows panel for batch combination of 1D data files. Use after you're comfortable with NSORT"}
	Button MainButton_2a,disable=1
	Button MainButton_2b,disable=1
	Button MainButton_2c,disable=1
	Button MainButton_2d,disable=1
	Button MainButton_2e,disable=1
	Button MainButton_2f,disable=1



//on tab(3) - 2-D Operations
	Button MainButton_3a,pos={15,90},size={90,20},proc=DisplayInterm_MainButtonProc,title="Display 2D"
	Button MainButton_3a,help={"Display will plot a 2-D work data file that has previously been created during data reduction"}
	Button MainButton_3b,pos={15,120},size={90,20},title="Draw Mask",proc=DrawMask_MainButtonProc
	Button MainButton_3b,help={"Draw a mask file and save it."}
	Button MainButton_3c,pos={15,150},size={90,20},proc=ReadMask_MainButtonProc,title="Read Mask"
	Button MainButton_3c,help={"Reads a mask file into the proper work folder, and displays a small image of the mask. Yellow areas will be excluded from the data"}
	Button MainButton_3d,pos={15,180},size={90,20},title="Tile RAW 2D",proc=ShowTilePanel_MainButtonProc
	Button MainButton_3d,help={"Adds selected RAW data files to a layout."}
	Button MainButton_3e,pos={150,90},size={100,20},title="Copy Work",proc=CopyWork_MainButtonProc
	Button MainButton_3e,help={"Copies WORK data from specified folder to destination folder."}
	Button MainButton_3f,pos={150,120},size={100,20},title="WorkFile Math",proc=WorkMath_MainButtonProc
	Button MainButton_3f,help={"Perfom simple math operations on workfile data"}
	Button MainButton_3g,pos={150,150},size={100,20},title="Event Data",proc=Event_MainButtonProc
	Button MainButton_3g,help={"Manipulate Event data"}
	
	Button MainButton_3h,pos={150,180},size={140,20},title="Event Reduction",proc=Event_MultReduceButtonProc
	Button MainButton_3h,help={"Reduce SANS Event Mode data"}
	Button MainButton_3i,pos={150,210},size={140,20},title="Event File Table",proc=Event_FileTableButtonProc
	Button MainButton_3i,help={"Make a table of raw data files and the associated event files"}
	
	
	Button MainButton_3a,disable=1
	Button MainButton_3b,disable=1
	Button MainButton_3c,disable=1
	Button MainButton_3d,disable=1
	Button MainButton_3e,disable=1
	Button MainButton_3f,disable=1
	Button MainButton_3g,disable=1
	Button MainButton_3h,disable=1
	Button MainButton_3i,disable=1

//on tab(4) - Miscellaneous operations
//	Button MainButton_4a,pos={15,90},size={80,20},proc=Draw3D_MainButtonProc,title="3D Display"
//	Button MainButton_4a,help={"Plots a 3-D surface of the selected file type"}
	Button MainButton_4b,pos={15,120},size={100,20},proc=ShowSchematic_MainButtonProc,title="Show Schematic"
	Button MainButton_4b,help={"Use this to show a schematic of the data reduction process for a selected sample file and reduction protocol"}
	Button MainButton_4c,pos={15,150},size={100,20},proc=ShowAvePanel_MainButtonProc,title="Average"
	Button MainButton_4c,help={"Shows a panel for interactive selection of the 1-D averaging step"}
	Button MainButton_4d,pos={15,180},size={100,20},proc=CatShort_MainButtonProc,title="CAT/Notebook"
	Button MainButton_4d,help={"This will generate a CATalog notebook of all files in a specified local folder"}


	Button MainButton_4e,pos={180,90},size={120,20},proc=KillWork_MainButtonProc,title="Kill Work Folder"
	Button MainButton_4e,help={"Kill a work data folder"}

//	Button MainButton_4e,pos={180,90},size={130,20},proc=NG1TransConv_MainButtonProc,title="NG1 Files to Trans"
//	Button MainButton_4e,help={"Converts NG1 transmission data files to be interpreted as such"}
	Button MainButton_4f,pos={180,120},size={120,20},proc=PRODIV_MainButtonProc,title="Make DIV file"
	Button MainButton_4f,help={"Merges two stored workfiles (CORrected) into a DIV file, and saves the result"}
	Button MainButton_4g,pos={180,150},size={120,20},proc=Raw2ASCII_MainButtonProc,title="RAW ASCII Export"
	Button MainButton_4g,help={"Exports selected RAW (2D) data file(s) as ASCII, either as pixel values or I(Qx,Qy)"}
	Button MainButton_4h,pos={180,180},size={120,20},proc=Preferences_MainButtonProc,title="Preferences"
	Button MainButton_4h,help={"Sets user preferences for selected parameters"}
	
//	Button MainButton_4a,disable=1
	Button MainButton_4b,disable=1
	Button MainButton_4c,disable=1
	Button MainButton_4d,disable=1
	Button MainButton_4e,disable=1
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

	String str = "Your web browser will open to the NCNR software page. "
	str += "At the bottom of the page there is contact information for where you can submit your bug report or feature request."
	DoAlert 1,str
	if(V_flag==1)
//		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
		BrowseURL "https://www.nist.gov/ncnr/data-reduction-analysis/sans-software"
	endif

End

//********************************
//************* OLD version of Main Panel *************
//Window Main_Panel()
Window OLD_Main_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=2 /W=(630,75,938,408) as "SANS Reduction Controls"
	ModifyPanel cbRGB=(52428,52425,1)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 2,250,303,325
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 2,243,186,194
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 2,140,303,189
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 2,59,303,133
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 2,2,303,53
	SetDrawEnv fstyle= 5
	DrawText 6,20,"Raw Data Operations"
	SetDrawEnv fstyle= 5
	DrawText 6,79,"Data Reduction Operations"
	SetDrawEnv fstyle= 5
	DrawText 6,158,"1-D Data Operations"
	SetDrawEnv fstyle= 5
	DrawText 6,212,"Intermediate 2-D Files"
	SetDrawEnv fstyle= 5
	DrawText 6,268,"Miscellaneous"
	SetDrawEnv fillfgc= (24672,51914,36494)
	DrawRect 190,194,303,242
	SetDrawEnv fstyle= 5
	DrawText 200,211,"Data Folder"
	Button MainButton_0,pos={6,25},size={70,20},proc=DisplayMainButtonProc,title="Display"
	Button MainButton_0,help={"Display will load and plot a single 2-D raw data file"}
	Button MainButton_1,pos={86,25},size={70,20},proc=PatchMainButtonProc,title="Patch"
	Button MainButton_1,help={"Patch will update incorrect information in raw data headers"}
	Button MainButton_2,pos={166,25},size={110,20},proc=TransMainButtonProc,title="Transmission"
	Button MainButton_2,help={"Shows the \"Patch\" panel which allows calculation of sample transmissions and entering these values into raw data headers"}
	Button MainButton_3,pos={6,82},size={110,20},proc=BuildProtocol_MainButtonProc,title="Build Protocol"
	Button MainButton_3,help={"Shows a panel where the CATalog window is used as input for creating a protocol. Can also be used for standard reductions"}
	Button MainButton_4,pos={147,82},size={110,20},proc=ReduceAFile_MainButtonProc,title="Reduce a File"
	Button MainButton_4,help={"Presents a questionnare for creating a reduction protocol, then reduces a single file"}
	Button MainButton_5,pos={6,107},size={160,20},proc=ReduceMultiple_MainButtonProc,title="Reduce Multiple Files"
	Button MainButton_5,help={"Use for reducing multiple raw datasets after protocol(s) have been created"}

	Button MainButton_19,pos={175,107},size={80,20},title="Draw Mask",proc=DrawMask_MainButtonProc
	Button MainButton_19,help={"Draw a mask file and save it."}
	
	Button MainButton_6,pos={6,162},size={60,20},proc=Plot1D_MainButtonProc,title="Plot"
	Button MainButton_6,help={"Loads and plots a 1-D dataset in the format expected by \"Sort\" and \"FIT\""}
	Button MainButton_7,pos={77,162},size={60,20},proc=Sort1D_MainButtonProc,title="Sort"
	Button MainButton_7,help={"Sorts and combines 2 or 3 separate 1-D datasets into a single file. Use \"Plot\" button to import 1-D data files"}
	Button MainButton_8,pos={147,162},size={60,20},proc=Fit1D_MainButtonProc,title="FIT"
	Button MainButton_8,help={"Shows panel for performing a variety of linearized fits to 1-D data files. Use \"Plot\" button to import 1-D data files"}

	Button MainButton_17,pos={217,162},size={60,20},proc=FITRPA_MainButtonProc,title="FIT/RPA"
	Button MainButton_17,help={"Shows panel for performing a fit to a polymer standard."}

	Button MainButton_9,pos={6,216},size={70,20},proc=DisplayInterm_MainButtonProc,title="Display"
	Button MainButton_9,help={"Display will plot a 2-D work data file that has previously been created during data reduction"}
	Button MainButton_10,pos={89,216},size={90,20},proc=ReadMask_MainButtonProc,title="Read Mask"
	Button MainButton_10,help={"Reads a mask file into the proper work folder, and displays a small image of the mask. Yellow areas will be excluded from the data"}
	Button MainButton_11,pos={6,298},size={80,20},proc=Draw3D_MainButtonProc,title="3D Display"
	Button MainButton_11,help={"Plots a 3-D surface of the selected file type"}
	Button MainButton_12,pos={6,273},size={90,20},proc=CatShort_MainButtonProc,title="CAT/SHORT"
	Button MainButton_12,help={"This will generate a CATalog window of all files in a specified local folder"}

	Button MainButton_18,pos={106,273},size={90,20},proc=CatVShort_MainButtonProc,title="CAT/VShort"
	Button MainButton_18,help={"This will generate a condensed CATalog table of all files in a specified local folder"}

	Button MainButton_13,pos={206,273},size={90,20},proc=ShowCatShort_MainButtonProc,title="Show CAT"
	Button MainButton_13,help={"This button will bring the CATalog window to the front, if it exists"}
	Button MainButton_14,pos={96,298},size={110,20},proc=ShowSchematic_MainButtonProc,title="Show Schematic"
	Button MainButton_14,help={"Use this to show a schematic of the data reduction process for a selected sample file and reduction protocol"}
	Button MainButton_15,pos={216,298},size={80,20},proc=ShowAvePanel_MainButtonProc,title="Average"
	Button MainButton_15,help={"Shows a panel for interactive selection of the 1-D averaging step"}
	Button MainButton_16,pos={200,214},size={80,20},title="Pick Path",proc=PickPath_MainButtonProc
	Button MainButton_16,help={"Pick the local data folder that contains the SANS data"}
	
EndMacro
//****************above is OLD********************