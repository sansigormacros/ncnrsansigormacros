#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


//////////////////////////////////
//
// TODO --  January 2107
//
// This is experimental, making the patch work with list boxes as "groups" of the Nexus file structure
//
// some of the groupings are more natural, some will need to be re-organized for the
// more natural needs of what will typically be patched in the most common cases.
//
///////////////////////////////

//
// Updated for use with VSANS (in process)
// -- currently very crude, and needs to be changed to accomodate the 
//   large number of parameters in the file that may/will need to be patched.
// -- if this turns out to be too crude or too difficult to work with for what 
//   VSANS needs, I may ditch the entire procedure and start fresh
//
// June 2016 SRK
//

// TODOs have been inserted to comment out all of the calls that don't compile and need to be replaced

// TODO
// -- not all of the functions here have been prefixed with "V_", especially the action procedures from the panel
//   so this cannot be opened with the SANS Reduction, or there will be clashes
// -- same file load/reload issue as with other operations that read a field from the file. ANY read requires
//   that the entire file is read in, even just to check and see if it's raw data... then there is a local
//   copy present to confuse matters of what was actually written
//
// -- for the batch entering of fields, when all of the proper beam center values are determined, then
//    all (2 x 9 = 18) of these values will need to be entered in all of the data files that "match" this 
//    "configuration" - however a configuration is to be defined and differentiated from other configurations.
//
// -- there may be other situations where batch entering needs are
//		 different, and this may lead to different interface choices
//
//


//**************************
// Vers. 1.2 092101
//
//procedures required to allow patching of raw SANS data headers
//only a limited number of fields are allowable for changes, although the list could
//be enhanced quite easily, at the expense of a larger, more complex panel
//information for the Patch Panel is stored in the root:Packages:NIST:VSANS:Globals:Patch subfolder
//
// writes changes directly to the raw data headers as requested
// * note that if a data file is currently in a work folder, the (real) header on disk
// will be updated, but the data in the (WORK) folder will not reflect these changes, unless
// the data folder is first cleared and the data is re-loaded
//
//**************************

//main entry procedure for displaying the Patch Panel
//
Proc V_PatchFiles()
	
	DoWindow/F V_Patch_Panel
	If(V_flag == 0)
		V_InitializePatchPanel()
		//draw panel
		V_Patch_Panel()
	Endif
End

//initialization of the panel, creating the necessary data folder and global
//variables if necessary - simultaneously initialize the globals for the Trans
//panel at this time, to make sure they all exist
//
// root:Packages:NIST:VSANS:Globals:
Proc V_InitializePatchPanel()
	//create the global variables needed to run the Patch Panel
	//all are kept in root:Packages:NIST:VSANS:Globals:Patch
	If( ! (DataFolderExists("root:Packages:NIST:VSANS:Globals:Patch"))  )
		//create the data folder and the globals for BOTH the Patch and Trans panels
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Patch
	Endif
	V_CreatePatchGlobals()		//re-create them every time (so text and radio buttons are correct)
End

//the data folder root:Packages:NIST:VSANS:Globals:Patch must exist
//
Proc V_CreatePatchGlobals()
	//ok, create the globals
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr = "*"
	PathInfo catPathName
	If(V_flag==1)
		String dum = S_path
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = dum
	else
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = "no path selected"
	endif
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = "none"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS1 = "no file selected"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS2 = "no file selected"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS3 = "no box selected"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS4 = "no file selected"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS5 = "no file selected"
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS6 = "no file selected"
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV1 =0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV2 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV3 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV4 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV5 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV6 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV7 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV8 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV9 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV10 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV11 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV12 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV13 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV14 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV15 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV16 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV17 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV18 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV19 = 0
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gTransCts = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gRadioVal = 1
	

	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch:	
	Make/O/T/N=(10,3) PP_ListWave
	Make/O/B/N=(10,3) PP_SelWave
	Make/O/T/N=3 PP_TitleWave
	
	PP_TitleWave = {"Ch?","Label","Value"}
	
	PP_SelWave[][0] = 2^5		// checkboxes
	PP_SelWave[][2] = 2^1		// 3rd column editable
	
	
	SetDataFolder root:
	
End


//panel recreation macro for the PatchPanel...
//
Proc V_Patch_Panel()
	PauseUpdate; Silent 1	   // building window...
	NewPanel /W=(533,50,1140,588)/K=2 as "Patch Raw VSANS Data Files"
	DoWindow/C V_Patch_Panel
//	ShowTools/A
	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch:

	
	ModifyPanel cbRGB=(11291,48000,3012)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7,30,422,30

	
	SetVariable PathDisplay,pos={77,7},size={310,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while patching. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,font="Courier",fSize=10
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr
	Button PathButton,pos={2,3},size={70,20},proc=V_PickPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={400,3},size={25,20},proc=V_ShowPatchHelp,title="?"
	Button helpButton,help={"Show the help file for patching raw data headers"}
	PopupMenu PatchPopup,pos={4,37},size={156,19},proc=V_PatchPopMenuProc,title="File(s) to Patch"
	PopupMenu PatchPopup,help={"The displayed file is the one that will be edited. The entire list will be edited if \"Change All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh. \r List items are selected from the file based on MatchString"}
	PopupMenu PatchPopup,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:Patch:gPatchList"
//	Button SHButton,pos={324,37},size={100,20},proc=ShowHeaderButtonProc,title="Show Header"
//	Button SHButton,help={"This will display the header of the file indicated in the popup menu."}
	Button CHButton,pos={314,37},size={110,20},proc=V_ChangeHeaderButtonProc,title="Change Header"
	Button CHButton,help={"This will change the checked values (ONLY) in the single file selected in the popup."}
	SetVariable PMStr,pos={6,63},size={174,13},proc=V_SetMatchStrProc,title="Match String"
	SetVariable PMStr,help={"Enter the search string to narrow the list of files. \"*\" is the wildcard character. After entering, \"pop\" the menu to refresh the file list."}
	SetVariable PMStr,font="Courier",fSize=10
	SetVariable PMStr,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	Button ChAllButton,pos={245,60},size={180,20},proc=V_ChAllHeadersButtonProc,title="Change All Headers in List"
	Button ChAllButton,help={"This will change the checked values (ONLY) in ALL of the files in the popup list, not just the top file. If the \"change\" checkbox for the item is not checked, nothing will be changed for that item."}
	Button DoneButton,pos={314,85},size={110,20},proc=V_DoneButtonProc,title="Done Patching"
	Button DoneButton,help={"When done Patching files, this will close this control panel."}
	CheckBox check0,pos={18,80},size={40,15},title="Run #",value= 1,mode=1,proc=V_MatchCheckProc
	CheckBox check1,pos={78,80},size={40,15},title="Text",value= 0,mode=1,proc=V_MatchCheckProc
	CheckBox check2,pos={138,80},size={40,15},title="SDD",value= 0,mode=1,proc=V_MatchCheckProc

	PopupMenu popup_0,pos={450,85},size={109,20},title="Detector Panel",proc=V_PatchPopMenuProc
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""


	TabControl PatchTab,pos={20,120},size={570,400}
	TabControl PatchTab,tabLabel(0)="Control",tabLabel(1)="Reduction",tabLabel(2)="Sample"
	TabControl PatchTab,tabLabel(3)="Instrument",tabLabel(4)="Detectors",tabLabel(5)="PolSANS"
	TabControl PatchTab,value=0,labelBack=(47748,57192,54093),proc=V_PatchTabProc


	ListBox list0,pos={30,150.00},size={550.00,350},proc=V_PatchListBoxProc,frame=1
	ListBox list0,fSize=10,userColumnResize= 1,listWave=PP_ListWave,selWave=PP_SelWave,titleWave=PP_TitleWave
	ListBox list0,mode=2,widths={30,200}


// put these in a tabbed? section for the 9 different panels
// will it be able to patch all "FL" with the proper values, then all "FR", etc. to batchwise correct files?

// TODO: add functions for these, make the intent a popup (since it's an enumerated type)

//	PopupMenu popup_1,pos={42,base+14*step},size={109,20},title="File intent"
//	PopupMenu popup_1,mode=1,popvalue="SCATTER",value= #"\"SCATTER;EMPTY;BLOCKED BEAM;TRANS;EMPTY BEAM;\""



	SetDataFolder root:
End

//
// function to control the display of the list box, based on the selection of the tab
//
Function V_PatchTabProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch:
	
	Wave/T PP_listWave = PP_ListWave
	Wave PP_selWave = PP_selWave
	
	//clear the listWave and SelWave
	PP_ListWave = ""
	PP_SelWave = 0
	
	Variable nRows=1
	// switch based on the tab number
	switch(tab)	
		case 0:	
			//Print "tab 0"
			
			V_FillListBox0(PP_ListWave,PP_SelWave)
			break		
		case 1:	
			//Print "tab 1"
			
			V_FillListBox1(PP_ListWave,PP_SelWave)
			break
		case 2:	
			//Print "tab 2"
			
			V_FillListBox2(PP_ListWave,PP_SelWave)
			break
		case 3:	
			//Print "tab 3"
			
			V_FillListBox3(PP_ListWave,PP_SelWave)
			break
		case 4:	
			//Print "tab 4"
			
			V_FillListBox4(PP_ListWave,PP_SelWave)
			break
		case 5:	
			//Print "tab 5"

			V_FillListBox5(PP_ListWave,PP_SelWave)
			break
		default:			// optional default expression executed
			SetDataFolder root:
			Abort "No tab found -- PatchTabProc"		// when no case matches
	endswitch


	SetDataFolder root:
	return(0)
End

// fill list boxes based on the tab
//
// CONTROL
//
Function V_FillListBox0(listWave,selWave)
	Wave/T listWave
	Wave selWave
	
	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 3
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	
	
	listWave[0][1] = "count_time"
	listWave[0][2] = num2str(V_getCount_time(fname))
	
	listWave[1][1] = "detector_counts"
	listWave[1][2] = num2str(V_getDetector_counts(fname))
	
	listWave[2][1] = "monitor_counts"
	listWave[2][2] = num2str(V_getMonitorCount(fname))
	
	return(0)
End

// fill list boxes based on the tab
//
// Reduction items
//
Function V_FillListBox1(listWave,selWave)
	Wave/T listWave
	Wave selWave

	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 13
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	
	listWave[0][1] = "empty_beam_file_name"
	listWave[0][2] = V_getEmptyBeamFileName(fname)
	
	listWave[1][1] = "background_file_name"
	listWave[1][2] = V_getBackgroundFileName(fname)
	
	listWave[2][1] = "empty_file_name"
	listWave[2][2] = V_getEmptyFileName(fname)
	
	listWave[3][1] = "sensitivity_file_name"
	listWave[3][2] = V_getSensitivityFileName(fname)
	
	listWave[4][1] = "mask_file_name"
	listWave[4][2] = V_getMaskFileName(fname)
	
	listWave[5][1] = "transmission_file_name"
	listWave[5][2] = V_getTransmissionFileName(fname)
	
	listWave[6][1] = "intent"
	listWave[6][2] = V_getReduction_intent(fname)
	
	listWave[7][1] = "file_purpose (polSANS)"
	listWave[7][2] = V_getReduction_polSANSPurpose(fname)
	
	listWave[8][1] = "group_id (sample)"
	listWave[8][2] = num2str(V_getSample_group_ID(fname))

	listWave[9][1] = "box_count"
	listWave[9][2] = num2str(V_getBoxCounts(fname))
	
	listWave[10][1] = "box_count_error"
	listWave[10][2] = num2str(V_getBoxCountsError(fname))
	
	listWave[11][1] = "whole_trans"
	listWave[11][2] = num2str(V_getSampleTransWholeDetector(fname))
	
	listWave[12][1] = "whole_trans_error"
	listWave[12][2] = num2str(V_getSampleTransWholeDetErr(fname))
	
	
		
	

	return(0)
End

// fill list boxes based on the tab
//
// SAMPLE
//
Function V_FillListBox2(listWave,selWave)
	Wave/T listWave
	Wave selWave
	
	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 4
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	
	listWave[0][1] = "description"
	listWave[0][2] = V_getSampleDescription(fname)
	
	listWave[1][1] = "thickness"
	listWave[1][2] = num2str(V_getSampleThickness(fname))
	
	listWave[2][1] = "transmission"
	listWave[2][2] = num2str(V_getSampleTransmission(fname))
	
	listWave[3][1] = "transmission_error"
	listWave[3][2] = num2str(V_getSampleTransError(fname))
	


	return(0)
End

// fill list boxes based on the tab
//
// INSTRUMENT
//
Function V_FillListBox3(listWave,selWave)
	Wave/T listWave
	Wave selWave
	
	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 6
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	
	listWave[0][1] = "attenuator_transmission"
	listWave[0][2] = num2str(V_getAttenuator_transmission(fname))	
	
	listWave[1][1] = "attenuator_transmission_error"
	listWave[1][2] = num2str(V_getAttenuator_trans_err(fname))	

	listWave[2][1] = "monochromator type"
	listWave[2][2] = V_getMonochromatorType(fname)
	
	listWave[3][1] = "wavelength"
	listWave[3][2] = num2str(V_getWavelength(fname))	
	
	listWave[4][1] = "wavelength_spread"
	listWave[4][2] = num2str(V_getWavelength_spread(fname))	

	listWave[5][1] = "distance (source aperture)"
	listWave[5][2] = num2str(V_getSourceAp_distance(fname))		
		
	return(0)
End


// fill list boxes based on the tab
//
// TODO --
// DETECTORS
//
Function V_FillListBox4(listWave,selWave)
	Wave/T listWave
	Wave selWave
	
	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 12
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	ControlInfo popup_0			// which detector panel?
	String detStr = S_value
	
	listWave[0][1] = "beam_center_x"
	listWave[0][2] = num2str(V_getDet_Beam_center_x(fname,detStr))	

	listWave[1][1] = "beam_center_y"
	listWave[1][2] = num2str(V_getDet_Beam_center_y(fname,detStr))	

	listWave[2][1] = "distance (nominal)"
	listWave[2][2] = num2str(V_getDet_NominalDistance(fname,detStr))	

	listWave[3][1] = "integrated_count"
	listWave[3][2] = num2str(V_getDet_IntegratedCount(fname,detStr))	

	listWave[4][1] = "pixel_fwhm_x"
	listWave[4][2] = num2str(V_getDet_pixel_fwhm_x(fname,detStr))	

	listWave[5][1] = "pixel_fwhm_y"
	listWave[5][2] = num2str(V_getDet_pixel_fwhm_y(fname,detStr))	

	listWave[6][1] = "pixel_num_x"
	listWave[6][2] = num2str(V_getDet_pixel_num_x(fname,detStr))	

	listWave[7][1] = "pixel_num_y"
	listWave[7][2] = num2str(V_getDet_pixel_num_y(fname,detStr))	

	listWave[8][1] = "setback"
	listWave[8][2] = num2str(V_getDet_TBSetback(fname,detStr))	

	if(cmpstr(detStr,"B") == 0 ||cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		listWave[9][1] = "lateral_offset"			// "B" detector drops here
		listWave[9][2] = num2str(V_getDet_LateralOffset(fname,detStr))	
	else	
		listWave[9][1] = "vertical_offset"	
		listWave[9][2] = num2str(V_getDet_VerticalOffset(fname,detStr))	
	endif	

	listWave[10][1] = "x_pixel_size"
	listWave[10][2] = num2str(V_getDet_x_pixel_size(fname,detStr))	

	listWave[11][1] = "y_pixel_size"
	listWave[11][2] = num2str(V_getDet_y_pixel_size(fname,detStr))	


	return(0)
End


// fill list boxes based on the tab
//
// TODO --
// PolSANS
//
Function V_FillListBox5(listWave,selWave)
	Wave/T listWave
	Wave selWave
	
	// trust that I'm getting a valid raw data file name from the popup
	String fname
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		Abort "no file selected in popup menu"		//null selection
	else
		fname = S_value				//selection not null
	Endif
	//prepend path for read routine 
	PathInfo catPathName
	fname = S_path + fname

	Variable nRows = 3
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	
	listWave[0][1] = "count_time"
	listWave[0][2] = num2str(V_getCount_time(fname))	

	return(0)
End


// TODO - determine if I really need this --- I don't 
//  think I really have any reason to respond to events from list box actions
// or edits. the final action of patching is done with the button
//
Function V_PatchListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End






//button action procedure to select the local path to the folder that
//contains the SANS data
//sets catPathName, updates the path display and the popup of files (in that folder)
//
Function V_PickPathButton(PathButton) : ButtonControl
	String PathButton
	
	//set the global string to the selected pathname
	V_PickPath()
	//set a local copy of the path for Patch
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = "no folder selected"
	else
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=V_Patch_Panel $"PathDisplay"
	
	//then update the popup list
	// (don't update the list - not until someone enters a search critera) -- Jul09
	//
	V_SetMatchStrProc("",0,"*","")		//this is equivalent to finding everything, typical startup case

End


//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
Function/S xGetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = V_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	if(strlen(match) == 0)		//if nothing is entered for a match string, return everything, rather than nothing
		match = "*"
	endif

	newlist = V_MyMatchList(match,newlist,";")
	
	newList = SortList(newList,";",0)
	Return(newList)
End

//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
// Uses Grep to look through the any text in the file, which includes the sample label
// can be very slow across the network, as it re-pops the menu on a selection (since some folks don't hit
// enter when inputing a filter string)
//
// - or -
// a list or range of run numbers
// - or - 
// a SDD (to within 0.001m)
// - or -
// * to get everything
//
// 	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
 // 1== Run # (comma range OK)
 // 2== Grep the text (SLOW)
 // 3== filter by SDD (within 0.001 m)
Function/S V_GetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = V_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	if(strlen(match) == 0 || cmpstr(match,"*")==0)		//if nothing or "*" entered for a match string, return everything, rather than nothing
		match = "*"
	// old way, with simply a wildcard
		newlist = V_MyMatchList(match,newlist,";")
		newList = SortList(newList,";",0)
		return(newList)
	endif
	
	//loop through all of the files as needed

	
	String list="",item="",fname,runList="",numStr=""
	Variable ii,num=ItemsInList(newList),val,sdd
	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
	
	// run number list
	if(gRadioVal == 1)
			
		list = V_ExpandNumRanges(match)		//now simply comma delimited
		num=ItemsInList(list,",")
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,list,",")
			val=str2num(item)

			runList += V_GetFileNameFromPathNoSemi(V_FindFileFromRunNumber(val)) + ";"		
		endfor
		newlist = runList
		
	endif
	
	//grep through what text I can find in the VAX binary
	// Grep Note: the \\b sequences limit matches to a word boundary before and after
	// "boondoggle", so "boondoggles" and "aboondoggle" won't match.
	if(gRadioVal == 2)
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
//			Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
			Grep/P=catPathName/Q/E=("(?i)"+match) item
			if( V_value )	// at least one instance was found
//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

		newList = list
	endif
	
	// SDD
	Variable pos
	String SDDStr=""
	if(gRadioVal == 3)
		pos = strsearch(match, "*", 0)
		if(pos == -1)		//no wildcard
			val = str2num(match)
		else
			val = str2num(match[0,pos-1])
		endif
		
//		print val
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
			fname = path + item
// TODO -- replace call -- this is hard-wired for "FL"
			sdd = V_getDet_ActualDistance(fname,"FL")
			if(pos == -1)
				//no wildcard
				if(abs(val - sdd) < 0.01	)		//if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif
			else
				//yes, wildcard, try a string match?
				// string match doesn't work -- 1* returns 1m and 13m data
				// round the value (or truncate?)
				
				//SDDStr = num2str(sdd)
				//if(strsearch(SDDStr,match[0,pos-1],0) != -1)
				//	list += item + ";"
				//endif
				
				if(abs(val - round(sdd)) < 0.01	)		//if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif
	
			endif
		endfor
		
		newList = list
	endif

	newList = SortList(newList,";",0)
	Return(newList)
End




// -- no longer refreshes the list - this seems redundant, and can be slow if grepping
//
//updates the popup list when the menu is "popped" so the list is 
//always fresh, then automatically displays the header of the popped file
//value of match string is used in the creation of the list - use * to get
//all valid files
//
Function V_PatchPopMenuProc(PatchPopup,popNum,popStr) : PopupMenuControl
	String PatchPopup
	Variable popNum
	String popStr

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
//	ControlUpdate PatchPopup
	V_ShowHeaderButtonProc("SHButton")
End

//when text is entered in the match string, the popup list is refined to 
//include only the selected files, useful for trimming a lengthy list, or selecting
//a range of files to patch
//only one wildcard (*) is allowed
//
Function V_SetMatchStrProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)
	
	String list = V_GetValidPatchPopupList()
	
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
	ControlUpdate PatchPopup
	PopupMenu PatchPopup,mode=1
	
	if(strlen(list) > 0)
		V_ShowHeaderButtonProc("SHButton")
	endif
End


//displays the header of the selected file (top in the popup) when the button is clicked
//sort of a redundant button, since the procedure is automatically called (as if it were
//clicked) when a new file is chosen from the popup
//
// TODO - make sure this is tab-aware
//
Function V_ShowHeaderButtonProc(SHButton) : ButtonControl
	String SHButton

	//displays (editable) header information about current file in popup control
	//putting the values in the SetVariable displays (resetting the global variables)
	
	//get the popup string
	String partialName, tempName
	Variable ok
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		partialName = S_value
		//Print partialName
	Endif
	//get a valid file based on this partialName and catPathName
	tempName = V_FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = V_CheckIfRawData(tempName)			//--- This loads the whole file to read the instrument string
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
	//Print tempName
	
	V_ReadHeaderForPatch(tempName)
	
	ControlUpdate/A/W=V_Patch_Panel
	
End



//simple function to get the string value from the popup list of filenames
//returned string is only the text in the popup, a partial name with no path
//or VAX version number.
//
Function/S V_GetPatchPopupString()

	String str=""
	
	ControlInfo patchPopup
	If(cmpstr(S_value,"")==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		str = S_value
		//Print str
	Endif
	
	Return str
End

//Changes (writes to disk!) the specified changes to the (single) file selected in the popup
//reads the checkboxes to determine which (if any) values need to be written
//
// This currently makes sure the name is valid,
// determines the active tab, 
// and dispatches to the correct (numbered) writer
//
Function V_ChangeHeaderButtonProc(CHButton) : ButtonControl
	String CHButton

	String partialName="", tempName = ""
	Variable ok
	//get the popup string
	partialName = V_GetPatchPopupString()
	
	//get a valid file based on this partialName and catPathName
	tempName = V_FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = V_CheckIfRawData(tempName)
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
	// which tab is active?
	ControlInfo/W=V_Patch_Panel PatchTab
	
	switch(V_Value)	// numeric switch
		case 0:	// execute if case matches expression
			V_WriteHeaderForPatch_0(tempName)
			break		// exit from switch
		case 1:	
			V_WriteHeaderForPatch_1(tempName)
			break
		case 2:	
			V_WriteHeaderForPatch_2(tempName)
			break
		case 3:	
			V_WriteHeaderForPatch_3(tempName)
			break
		case 4:	
			V_WriteHeaderForPatch_4(tempName)
			break
		case 5:	
			V_WriteHeaderForPatch_5(tempName)
			break
		default:			// optional default expression executed
			Abort "Tab not found - V_ChangeHeaderButtonProc"
	endswitch

	
	//after writing the changes to the file
	// clean up, to force a reload from disk
	V_CleanupData_w_Progress(0,1)
	
	return(0)
End

//	
//*****this function actually writes the data to disk*****
//
// TODO - re-write a series of these function to mirror the "fill" functions
//   specific to each tab
//
// TODO x- clear out the old data and force a re-load from disk, or the old data
//    will be read in from the RawVSANS folder, and it will look like nothing was written
//			(done in the calling function)
//
// currently, all errors are printed out by the writer, but ignored here
//
Function V_WriteHeaderForPatch_0(fname)
	String fname
	
	Variable val,err
	String textstr
		
	Wave/T listWave = root:Packages:NIST:VSANS:Globals:Patch:PP_ListWave
	Wave selWave = root:Packages:NIST:VSANS:Globals:Patch:PP_selWave

	// test bit 4 to see if the checkbox is selected
	if ((selWave[0][0] & 2^4) != 0)		// Test if bit 4 is set
		val = str2num(listWave[0][2])
		err = V_writeCount_time(fname,val)		// count_time
	endif

	if ((selWave[1][0] & 2^4) != 0)		// "detector_counts"
		val = str2num(listWave[1][2])
		err = V_writeDetector_counts(fname,val)
	endif	
	
	if ((selWave[2][0] & 2^4) != 0)		//"monitor_counts"
		val = str2num(listWave[2][2])
		err = V_writeMonitorCount(fname,val)
	endif	
	

//
//	ControlInfo checkPS1		//change the sample label ?
//	if(V_Value == 1)
//		SVAR gPS1 = root:Packages:NIST:VSANS:Globals:Patch:gPS1
//		V_writeSampleDescription(fname,gPS1)
//	endif
//	
//	ControlInfo checkPV1
//	if(V_Value == 1)		//sample transmission
//		ControlInfo PV1
//		V_writeSampleTransmission(fname,V_value)
//	Endif
//	
//	ControlInfo checkPV2
//	if(V_Value == 1)		//sample thickness
//		ControlInfo PV2
//		V_writeSampleThickness(fname,V_Value)
//	Endif
//	
//	ControlInfo checkPV5
//	if(V_Value == 1)		//attenuator number
//		ControlInfo PV5
//		V_writeAttenThickness(fname,V_value)
//	Endif
//
//	ControlInfo checkPV6		// count time
//	if(V_Value == 1)
//		ControlInfo PV6
//		V_writeCount_time(fname,V_Value)
//	Endif
//
//	ControlInfo checkPV7	
//	if(V_Value == 1)    //monitor count
//		ControlInfo PV7 
//		V_writeMonitorCount(fname,V_Value)
//	Endif
//
//	ControlInfo checkPV10	
//	if(V_Value == 1)      //wavelength
//		ControlInfo PV10
//		V_writeWavelength(fname,V_Value)
//	Endif
//
//	ControlInfo checkPV11		
//	if(V_Value == 1)      //wavelength spread
//		ControlInfo PV11
//		V_writeWavelength_spread(fname,V_Value)
//	Endif	
//
//	ControlInfo checkPV14		
//	if(V_Value == 1)      //source aperture
//		ControlInfo PV14
//		textStr = num2str(V_Value)
//		V_writeSourceAp_size(fname,textStr)		//this is expecting a string
//	Endif
//	
//	ControlInfo checkPV15		
//	if(V_Value == 1)      //sample aperture
//		ControlInfo PV15
//		V_writeSampleAp2_size(fname,V_Value)		//TODO -- not sure if this is correct call
//	Endif
//
//	ControlInfo checkPV16
//	if(V_Value == 1)      //source-sam dist
//		ControlInfo PV16
//// TODO -- replace call
////		WriteSrcToSamDistToHeader(fname,num)
//	Endif
//
//	ControlInfo checkPV18
//	if(V_Value == 1)      //beamstop diam
//		ControlInfo PV18
//		V_writeBeamStopC2_size(fname,V_Value)			//TODO depends on which det carriage I'm working with (2) or (3)
//	Endif	
//
//	ControlInfo checkPS2		//change the DIV file name?
//	if(V_Value == 1)
//		SVAR gPS2 = root:Packages:NIST:VSANS:Globals:Patch:gPS2
//		V_writeSensitivityFileName(fname,gPS2)
//	endif	
//	
//	ControlInfo checkPS3		//change the sample intent?
//	if(V_Value == 1)
//		SVAR gPS3 = root:Packages:NIST:VSANS:Globals:Patch:gPS3
//		V_writeReductionIntent(fname,gPS3)
//	endif	
//
//	
//// individual detector values	
//	ControlInfo checkPV3
//	if(V_Value == 1)		//pixel X
//		ControlInfo PV3
//		V_writeDet_beam_center_x(fname,detStr,V_Value)	
//	Endif
//	
//	ControlInfo checkPV4
//	if(V_Value == 1)		// pixel Y
//		ControlInfo PV4
//		V_writeDet_beam_center_y(fname,detStr,V_Value)	
//	Endif
//	
//	ControlInfo checkPV17
//	if(V_Value == 1)      //det offset
//		ControlInfo PV17
//		V_writeDet_LateralOffset(fname,detStr,V_Value)		// TODO lateral or vertical offset, based on detStr
//	Endif
//
//	ControlInfo checkPV19
//	if(V_Value == 1)     //SDD
//		ControlInfo PV19
//		V_writeDet_distance(fname,detStr,V_Value)	 
//	Endif
//
//	ControlInfo checkPV8	
//	if(V_Value == 1)     //total detector count
//		ControlInfo PV8
//		V_writeDet_IntegratedCount(fname,detStr,V_value)		
//	Endif


	Return(0)
End

//
// tab 1
//
Function V_WriteHeaderForPatch_1(fname)
	String fname

	Variable val,err
	String str
		
	Wave/T listWave = root:Packages:NIST:VSANS:Globals:Patch:PP_ListWave
	Wave selWave = root:Packages:NIST:VSANS:Globals:Patch:PP_selWave

	// test bit 4 to see if the checkbox is selected
	if ((selWave[0][0] & 2^4) != 0)		// Test if bit 4 is set
		str = listWave[0][2]			// empty_beam_file_name
		err = V_writeEmptyBeamFileName(fname,str)		
	endif

	if ((selWave[1][0] & 2^4) != 0)		// "background_file_name"
		str = listWave[1][2]
		err = V_writeBackgroundFileName(fname,str)
	endif	
	
	if ((selWave[2][0] & 2^4) != 0)		//"empty_file_name"
		str = listWave[2][2]
		err = V_writeEmptyFileName(fname,str)
	endif	
	
	if ((selWave[3][0] & 2^4) != 0)		//"sensitivity_file_name"
		str = listWave[3][2]
		err = V_writeSensitivityFileName(fname,str)
	endif	
	
	if ((selWave[4][0] & 2^4) != 0)		//"mask_file_name"
		str = listWave[4][2]
		err = V_writeMaskFileName(fname,str)
	endif	
	
	if ((selWave[5][0] & 2^4) != 0)		//"transmission_file_name"
		str = listWave[5][2]
		err = V_writeTransmissionFileName(fname,str)
	endif	

	if ((selWave[6][0] & 2^4) != 0)		//"intent"
		str = listWave[6][2]
		err = V_writeReductionIntent(fname,str)
	endif	
	
	if ((selWave[7][0] & 2^4) != 0)		//"file_purpose (polSANS)"
		str = listWave[7][2]
		err = V_writePolReduction_purpose(fname,str)
	endif		

	if ((selWave[8][0] & 2^4) != 0)		//"group_id (sample)"
		val = str2num(listWave[8][2])
		err = V_writeReduction_group_ID(fname,val)
	endif	
	
	if ((selWave[9][0] & 2^4) != 0)		//"box_count"
		val = str2num(listWave[9][2])
		err = V_writeBoxCounts(fname,val)
	endif	
	
	if ((selWave[10][0] & 2^4) != 0)		//"box_count_error"
		val = str2num(listWave[10][2])
		err = V_writeBoxCountsError(fname,val)
	endif	
	
	if ((selWave[11][0] & 2^4) != 0)		//"whole_trans"
		val = str2num(listWave[11][2])
		err = V_writeSampleTransWholeDetector(fname,val)
	endif	
	
	if ((selWave[12][0] & 2^4) != 0)		//"whole_trans_error"
		val = str2num(listWave[12][2])
		err = V_writeSampleTransWholeDetErr(fname,val)
	endif	
	
	
		
		
	return(0)
End

// SAMPLE
Function V_WriteHeaderForPatch_2(fname)
	String fname
	
	Variable val,err
	String str
		
	Wave/T listWave = root:Packages:NIST:VSANS:Globals:Patch:PP_ListWave
	Wave selWave = root:Packages:NIST:VSANS:Globals:Patch:PP_selWave

	// test bit 4 to see if the checkbox is selected
	if ((selWave[0][0] & 2^4) != 0)		// Test if bit 4 is set
		str = listWave[0][2]			// "description"
		err = V_writeSampleDescription(fname,str)		
	endif

	if ((selWave[1][0] & 2^4) != 0)		// "thickness"
		val = str2num(listWave[1][2])
		err = V_writeSampleThickness(fname,val)
	endif	
	
	if ((selWave[2][0] & 2^4) != 0)		//"transmission"
		val = str2num(listWave[2][2])
		err = V_writeSampleTransmission(fname,val)
	endif	
	
	if ((selWave[3][0] & 2^4) != 0)		//"transmission_error"
		val = str2num(listWave[3][2])
		err = V_writeSampleTransError(fname,val)
	endif	
	
	return(0)
End

// INSTRUMENT
Function V_WriteHeaderForPatch_3(fname)
	String fname

	Variable val,err
	String str
		
	Wave/T listWave = root:Packages:NIST:VSANS:Globals:Patch:PP_ListWave
	Wave selWave = root:Packages:NIST:VSANS:Globals:Patch:PP_selWave

	// test bit 4 to see if the checkbox is selected
	if ((selWave[0][0] & 2^4) != 0)		// Test if bit 4 is set
		val = str2num(listWave[0][2])			// "attenuator_transmission"
		err = V_writeAttenuator_transmission(fname,val)		
	endif

	if ((selWave[1][0] & 2^4) != 0)		// "attenuator_transmission_error"
		val = str2num(listWave[1][2])
		err = V_writeAttenuator_trans_err(fname,val)
	endif	
	
	if ((selWave[2][0] & 2^4) != 0)		//"monochromator type"
		str = listWave[2][2]
		err = V_writeMonochromatorType(fname,str)
	endif	
	
	if ((selWave[3][0] & 2^4) != 0)		//"wavelength"
		val = str2num(listWave[3][2])
		err = V_writeWavelength(fname,val)
	endif	

	if ((selWave[4][0] & 2^4) != 0)		//"wavelength_spread"
		val = str2num(listWave[4][2])
		err = V_writeWavelength_spread(fname,val)
	endif	
	
	if ((selWave[5][0] & 2^4) != 0)		//"distance (source aperture)"
		val = str2num(listWave[5][2])
		err = V_writeSourceAp_distance(fname,val)
	endif		
	
	
	return(0)
End

// DETECTOR
Function V_WriteHeaderForPatch_4(fname)
	String fname

	Variable val,err
	String str
		
	Wave/T listWave = root:Packages:NIST:VSANS:Globals:Patch:PP_ListWave
	Wave selWave = root:Packages:NIST:VSANS:Globals:Patch:PP_selWave

	ControlInfo popup_0
	String detStr = S_Value

	// test bit 4 to see if the checkbox is selected
	if ((selWave[0][0] & 2^4) != 0)		// Test if bit 4 is set
		val = str2num(listWave[0][2])			// "beam_center_x"
		err = V_writeDet_beam_center_x(fname,detStr,val)	
	endif

	if ((selWave[1][0] & 2^4) != 0)		// "beam_center_y"
		val = str2num(listWave[1][2])
		err = V_writeDet_beam_center_y(fname,detStr,val)
	endif	
	
	if ((selWave[2][0] & 2^4) != 0)		//"distance (nominal)"
		val = str2num(listWave[2][2])
		err = V_writeDet_distance(fname,detStr,val)
	endif	
	
	if ((selWave[3][0] & 2^4) != 0)		//"integrated_count"
		val = str2num(listWave[3][2])
		err = V_writeDet_IntegratedCount(fname,detStr,val)
	endif	
	
	if ((selWave[4][0] & 2^4) != 0)		//"pixel_fwhm_x"
		val = str2num(listWave[4][2])
		err = V_writeDet_pixel_fwhm_x(fname,detStr,val)
	endif	
	
	if ((selWave[5][0] & 2^4) != 0)		//"pixel_fwhm_y"
		val = str2num(listWave[5][2])
		err = V_writeDet_pixel_fwhm_y(fname,detStr,val)
	endif	

	if ((selWave[6][0] & 2^4) != 0)		//"pixel_num_x"
		val = str2num(listWave[6][2])
		err = V_writeDet_pixel_num_x(fname,detStr,val)
	endif	
	
	if ((selWave[7][0] & 2^4) != 0)		//"pixel_num_y"
		val = str2num(listWave[7][2])
		err = V_writeDet_pixel_num_y(fname,detStr,val)
	endif		
	
	if ((selWave[8][0] & 2^4) != 0)		//"setback" -- only for TB detectors
		val = str2num(listWave[8][2])
		if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0 || cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
			err = V_writeDet_TBSetback(fname,detStr,val)
		endif
	endif	

	if ((selWave[9][0] & 2^4) != 0)		//"lateral_offset" or "vertical_offset"
		val = str2num(listWave[9][2])
		if(cmpstr(detStr,"B") == 0 ||cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
			err = V_writeDet_LateralOffset(fname,detStr,val)
		else
			err = V_writeDet_VerticalOffset(fname,detStr,val)
		endif
	endif	
	
	if ((selWave[10][0] & 2^4) != 0)		//"x_pixel_size"
		val = str2num(listWave[10][2])
		err = V_writeDet_x_pixel_size(fname,detStr,val)
	endif	
	
	if ((selWave[11][0] & 2^4) != 0)		//"y_pixel_size"
		val = str2num(listWave[11][2])
		err = V_writeDet_y_pixel_size(fname,detStr,val)
	endif	
	


	
	return(0)
End

// TODO -- not yet implemented
Function V_WriteHeaderForPatch_5(fname)
	String fname
	
	return(0)
End


// control the display of the radio buttons
Function V_MatchCheckProc(name,value)
	String name
	Variable value
	
	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
	
	strswitch (name)
		case "check0":
			gRadioVal= 1
			break
		case "check1":
			gRadioVal= 2
			break
		case "check2":
			gRadioVal= 3
			break
	endswitch
	CheckBox check0,value= gRadioVal==1
	CheckBox check1,value= gRadioVal==2
	CheckBox check2,value= gRadioVal==3
	return(0)
End

//This function will read only the selected values editable in the patch panel
//
// -- TODO --
// re-write this to be tab-aware. ShowHeaderForPatch() calls this, but does nothing
// to update the tab content. Figure out which function is in charge, and update the content.
//
Function V_ReadHeaderForPatch(fname)
	String fname
	
	
	// figure out which is the active tab, then let PatchTabProc fill it in
	ControlInfo/W=V_Patch_Panel PatchTab
	V_PatchTabProc("",V_Value)	
	
	Return 0
End

Function V_ShowPatchHelp(ctrlName) : ButtonControl
	String ctrlName
//	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial[Patch File Headers]"
//	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
//	endif
End

//button action procedure to change the selected information (checked values)
//in each file in the popup list. This will change multiple files, and as such,
//the user is given a chance to bail out before the whole list of files
//is modified
//useful for patching a series of runs with the same beamcenters, or transmissions
//
Function V_ChAllHeadersButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String msg
	msg = "Do you really want to write all of these values to each data file in the popup list? "
	msg += "- clicking NO will leave all files unchanged"
	DoAlert 1,msg
	If(V_flag == 2)
		Abort "no files were changed"
	Endif
	
	//this will change (checked) values in ALL of the headers in the popup list
	SVAR list = root:Packages:NIST:VSANS:Globals:Patch:gPatchList
	Variable numitems,ii
	String partialName="", tempName = ""
	Variable ok
	
	numitems = ItemsInList(list,";")
	
	if(numitems == 0)
		Abort "no items in list for multiple patch"
	Endif
	
	// loop through all of the files
	ii=0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		   
		//get a valid file based on this partialName and catPathName
		tempName = V_FindValidFilename(partialName)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
	
		//make sure the file is really a RAW data file
		ok = V_CheckIfRawData(tempName)
		if (!ok)
		   Print "this file is not recognized as a RAW SANS data file = ",tempName
		else
		   //go write the changes to the file
			// which tab is active?
			ControlInfo/W=V_Patch_Panel PatchTab
			
			switch(V_Value)	// numeric switch
				case 0:	// execute if case matches expression
					V_WriteHeaderForPatch_0(tempName)
					break		// exit from switch
				case 1:	
					V_WriteHeaderForPatch_1(tempName)
					break
				case 2:	
					V_WriteHeaderForPatch_2(tempName)
					break
				case 3:	
					V_WriteHeaderForPatch_3(tempName)
					break
				case 4:	
					V_WriteHeaderForPatch_4(tempName)
					break
				case 5:	
					V_WriteHeaderForPatch_5(tempName)
					break
				default:			// optional default expression executed
					Abort "Tab not found - V_ChAllHeadersButtonProc"
			endswitch
		Endif
		
		ii+=1
	while(ii<numitems)


	//after writing the changes to the file
	// clean up, to force a reload from disk
	V_CleanupData_w_Progress(0,1)

	return(0)
End


//simple action for button to close the panel
//
// cleans out the RawVSANS folder on closing 
//
Function V_DoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K V_Patch_Panel

//	V_CleanOutRawVSANS()
// present a progress window
	V_CleanupData_w_Progress(0,1)	
	
	return(0)
End



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////
//
// this is a block to patch waves to the file headers, and can patch multiple files
// 
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
// TODO -- need to clear out the contents from RawVSANS, or else re-reading to check the values
//        will read locally, and it will look like nothing was written. Executing "save" will also 
//        trigger a cleanout.
//
// TODO - link this to a panel somewhere - a button? menu item? will there be a lot more of these little panels?
//
Proc V_PatchDetectorDeadtime(firstFile,lastFile,detStr,deadtimeStr)
	Variable firstFile=1,lastFile=100
	String detStr = "FL",deadtimeStr="deadTimeWave"

	V_fPatchDetectorDeadtime(firstFile,lastFile,detStr,$deadtimeStr)

End

Proc V_ReadDetectorDeadtime(firstFile,lastFile,detStr)
	Variable firstFile=1,lastFile=100
	String detStr = "FL"
	
	V_fReadDetectorDeadtime(firstFile,lastFile,detStr)
End

// simple utility to patch the detector deadtime in the file headers
// pass in the account name as a string
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDetectorDeadtime(lo,hi,detStr,deadtimeW)
	Variable lo,hi
	String detStr
	Wave deadtimeW
	
	Variable ii
	String fname
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeDetector_deadtime(fname,detStr,deadtimeW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector deadtime stored in the file header
Function V_fReadDetectorDeadtime(lo,hi,detStr)
	Variable lo,hi
	String detStr
	
	String fname
	Variable ii
	
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			Wave deadtimeW = V_getDetector_deadtime(fname,detStr)
			Duplicate/O deadTimeW root:Packages:NIST:VSANS:Globals:Patch:deadtimeWave
//			printf "File %d:  Detector Dead time (s) = %g\r",ii,deadtime
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End



Proc V_PatchDetectorDeadtimePanel()
	DoWindow/F Patch_Deadtime
	if(V_flag==0)
	
		NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Patch

		Make/O/D/N=48 deadTimeWave
		
		SetDataFolder root:
		
		Execute "V_DeadtimePatchPanel()"
	endif
End


//
// TODO - needs some minor adjustment to be of practical use, but a proof of concept
//
Proc V_DeadtimePatchPanel() : Panel
	PauseUpdate; Silent 1		// building window...


	NewPanel /W=(600,400,1000,1000)/N=DeadtimePanel/K=1
//	ShowTools/A
	
	PopupMenu popup_0,pos={20,20},size={109,20},title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;\""
	
	Button button0,pos={22.00,62.00},size={50.00,20.00},proc=V_ReadDTButtonProc,title="Read"
	Button button0_1,pos={95.00,62.00},size={50.00,20.00},proc=V_WriteDTButtonProc,title="Write"
	SetVariable setvar0,pos={19.00,128.00},size={100.00,14.00},title="first"
	SetVariable setvar0,value= K0
	SetVariable setvar1,pos={20.00,154.00},size={100.00,14.00},title="last"
	SetVariable setvar1,value= K1

	

// display the wave	
	Edit/W=(180,40,380,550)/HOST=#  root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
	ModifyTable width(Point)=0
	ModifyTable width(root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave)=120
	RenameWindow #,T0
	SetActiveSubwindow ##

	
EndMacro


Function V_ReadDTButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ControlInfo popup_0
			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			Variable hi=lo
			
			V_fReadDetectorDeadtime(lo,hi,detStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_WriteDTButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ControlInfo popup_0
			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			ControlInfo setvar1
			Variable hi=V_Value
			Wave deadTimeW = root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
			
			V_fPatchDetectorDeadtime(lo,hi,detStr,deadtimeW)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////
//
// this is a block to patch beam centers to the file headers
// it will patch the headers for all 9 detectors
// and can patch multiple files
// 
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents. this is the "good" set of XY
//  that you want to write out to other files.
//
// TODO -- need to clear out the contents from RawVSANS, or else re-reading to check the values
//        will read locally, and it will look like nothing was written. Executing "save" will also 
//        trigger a cleanout.
//
// TODO - link this to a panel somewhere - a button? menu item? will there be a lot more of these little panels?
//
Proc V_PatchDet_xyCenters(firstFile,lastFile)
	Variable firstFile=1,lastFile=100

	V_fPatchDet_xyCenters(firstFile,lastFile)

End

Proc V_ReadDet_xyCenters(firstFile,lastFile)
	Variable firstFile=1,lastFile=100

	
	V_fReadDet_xyCenters(firstFile,lastFile)
End

// simple utility to patch the xy center in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDet_xyCenters(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
	
	Wave xCtr_pix = root:Packages:NIST:VSANS:Globals:Patch:xCtr_pix
	Wave yCtr_pix = root:Packages:NIST:VSANS:Globals:Patch:yCtr_pix
	Wave/T panelW = root:Packages:NIST:VSANS:Globals:Patch:panelW
		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
				detStr = panelW[ii]
				V_writeDet_beam_center_x(fname,detStr,xCtr_pix[ii])
				V_writeDet_beam_center_y(fname,detStr,yCtr_pix[ii])		
			endfor	
		
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector xy centers stored in the file header
Function V_fReadDet_xyCenters(lo,hi)
	Variable lo,hi

	
	String fname,detStr
	Variable ii,jj
	
	Wave xCtr_pix = root:Packages:NIST:VSANS:Globals:Patch:xCtr_pix
	Wave yCtr_pix = root:Packages:NIST:VSANS:Globals:Patch:yCtr_pix
	Wave/T panelW = root:Packages:NIST:VSANS:Globals:Patch:panelW
	
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
				detStr = StringFromList(ii, ksDetectorListAll, ";")
				panelW[ii] = detStr
				xCtr_pix[ii] = V_getDet_beam_center_x(fname,detStr)
				yCtr_pix[ii] = V_getDet_beam_center_y(fname,detStr)
			endfor
		
		
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor

	
	return(0)
End



Proc V_PatchDet_xyCenters_Panel()
	DoWindow/F Patch_Deadtime
	if(V_flag==0)
	
		NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Patch

		Make/O/D/N=9 xCtr_pix,yCtr_pix
		Make/O/T/N=9 panelW
		
		SetDataFolder root:
		
		Execute "V_Patch_xyCtr_Panel()"
	endif
End


//
// TODO - document, make setVar controls larger, make cleaner
//
// TODO - link to main panel? link to Patch Panel?
//
Proc V_Patch_xyCtr_Panel() : Panel
	PauseUpdate; Silent 1		// building window...


	NewPanel /W=(600,400,1150,800)/N=Patch_XY_Panel/K=1
//	ShowTools/A
	
//	PopupMenu popup_0,pos={20,20},size={109,20},title="Detector Panel"
//	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""
	
	Button button0,pos={22.00,62.00},size={50.00,20.00},proc=V_ReadXYButtonProc,title="Read"
	Button button0_1,pos={95.00,62.00},size={50.00,20.00},proc=V_WriteXYButtonProc,title="Write"
	SetVariable setvar0,pos={19.00,128.00},size={100.00,14.00},title="first"
	SetVariable setvar0,value= K0
	SetVariable setvar1,pos={20.00,154.00},size={100.00,14.00},title="last"
	SetVariable setvar1,value= K1

	
	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch
// display the wave	
	Edit/W=(180,40,480,350)/HOST=#  panelW,xCtr_pix,yCtr_pix
	ModifyTable width(Point)=0
	ModifyTable width(panelW)=80
	ModifyTable width(xCtr_pix)=100
	ModifyTable width(yCtr_pix)=100
	RenameWindow #,T0
	SetActiveSubwindow ##

	SetDataFolder root:
	
EndMacro


Function V_ReadXYButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			ControlInfo popup_0
//			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			Variable hi=lo
			
			V_fReadDet_xyCenters(lo,hi)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_WriteXYButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			ControlInfo popup_0
//			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			ControlInfo setvar1
			Variable hi=V_Value
//			Wave deadTimeW = root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
			
			V_fPatchDet_xyCenters(lo,hi)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
