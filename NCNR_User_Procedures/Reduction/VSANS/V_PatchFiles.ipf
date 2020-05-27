#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 7.00


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

// TODOs have been inserted to comment out all of the calls that don't compile and need to be replaced

// TODO
// x- not all of the functions here have been prefixed with "V_", especially the action procedures from the panel
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
// -- need to add some mechanism (new panel?) to enter:
//    -- box coordinates
//    -- ABS parameters
//    -- averaging options -- these will have new options versus SANS (binning panels, slit mode, etc.)
//
//
// TODO:
// V_fPatch_GroupID_catTable()
//	V_fPatch_Purpose_catTable()
//	V_fPatch_Intent_catTable()
/// -- these three functions are part of a growing list for faster patching. edit the file catalog, and 
//    write out the contents of the column (vs. filename)
// -- make a simple panel w/buttons (like the sort panel) to call these functions
//

//**************************
//
//procedures required to allow patching of raw vSANS data headers
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
//variables if necessary - 
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
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchCurLabel = "no file selected"
	
	PathInfo catPathName
	If(V_flag==1)
		String dum = S_path
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = dum
	else
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = "no path selected"
	endif
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = "none"

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

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif
	
	PauseUpdate; Silent 1	   // building window...
	NewPanel /W=(533*sc,50*sc,1140*sc,588*sc)/K=1 as "Patch Raw VSANS Data Files"
	DoWindow/C V_Patch_Panel
//	ShowTools/A
	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch:

	
	ModifyPanel cbRGB=(11291,48000,3012)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7*sc,30*sc,422*sc,30*sc

	
	SetVariable PathDisplay,pos={sc*77,7*sc},size={sc*310,13*sc},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while patching. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,font="Courier",fSize=10*sc
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr
	Button PathButton,pos={sc*2,3*sc},size={sc*70,20*sc},proc=V_PickPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={sc*400,3*sc},size={sc*25,20*sc},proc=V_ShowPatchHelp,title="?"
	Button helpButton,help={"Show the help file for patching raw data headers"}
	PopupMenu PatchPopup,pos={sc*4,37*sc},size={sc*156,19*sc},proc=V_PatchPopMenuProc,title="File(s) to Patch"
	PopupMenu PatchPopup,help={"The displayed file is the one that will be edited. The entire list will be edited if \"Change All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh. \r List items are selected from the file based on MatchString"}
	PopupMenu PatchPopup,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:Patch:gPatchList"

	Button CHButton,pos={sc*314,37*sc},size={sc*110,20*sc},proc=V_ChangeHeaderButtonProc,title="Change Header"
	Button CHButton,help={"This will change the checked values (ONLY) in the single file selected in the popup."}
	SetVariable PMStr,pos={sc*6,63*sc},size={sc*174,13*sc},proc=V_SetMatchStrProc,title="Match String"
	SetVariable PMStr,help={"Enter the search string to narrow the list of files. \"*\" is the wildcard character. After entering, \"pop\" the menu to refresh the file list."}
	SetVariable PMStr,font="Courier",fSize=10*sc
	SetVariable PMStr,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	Button ChAllButton,pos={sc*245,60*sc},size={sc*180,20*sc},proc=V_ChAllHeadersButtonProc,title="Change All Headers in List"
	Button ChAllButton,help={"This will change the checked values (ONLY) in ALL of the files in the popup list, not just the top file. If the \"change\" checkbox for the item is not checked, nothing will be changed for that item."}
	Button DoneButton,pos={sc*450,60*sc},size={sc*110,20*sc},proc=V_DoneButtonProc,title="Done Patching"
	Button DoneButton,help={"When done Patching files, this will close this control panel."}
	CheckBox check0,pos={sc*18,80*sc},size={sc*40,15*sc},title="Run #",value= 1,mode=1,proc=V_MatchCheckProc
	CheckBox check1,pos={sc*78,80*sc},size={sc*40,15*sc},title="Text",value= 0,mode=1,proc=V_MatchCheckProc
	CheckBox check2,pos={sc*138,80*sc},size={sc*40,15*sc},title="Group_ID",value= 0,mode=1,proc=V_MatchCheckProc

	SetVariable curStr,pos={sc*50,112*sc},size={sc*350,20*sc},title="File Label:"
	SetVariable curStr,help={"Label of current file in popup list"}
	SetVariable curStr,font="Courier",fSize=10*sc
	SetVariable curStr,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPatchCurLabel
	
	PopupMenu popup_0,pos={sc*450,112*sc},size={sc*109,20*sc},title="Detector Panel",proc=V_PatchPopMenuProc
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""


	TabControl PatchTab,pos={sc*20,140*sc},size={sc*570,380*sc}
	TabControl PatchTab,tabLabel(0)="Control",tabLabel(1)="Reduction",tabLabel(2)="Sample"
	TabControl PatchTab,tabLabel(3)="Instrument",tabLabel(4)="Detectors",tabLabel(5)="PolSANS"
	TabControl PatchTab,value=0,labelBack=(47748,57192,54093),proc=V_PatchTabProc


	ListBox list0,pos={sc*30,170.00*sc},size={sc*550.00,330*sc},proc=V_PatchListBoxProc,frame=1
	ListBox list0,fSize=10*sc,userColumnResize= 1,listWave=PP_ListWave,selWave=PP_SelWave,titleWave=PP_TitleWave
	ListBox list0,mode=2,widths={30,200}


// put these in a tabbed? section for the 9 different panels
// will it be able to patch all "FL" with the proper values, then all "FR", etc. to batchwise correct files?

// TODO: add functions for these, make the intent a popup (since it's an enumerated type)

//	PopupMenu popup_1,pos={sc*42,base+14*step*sc},size={sc*109,20*sc},title="File intent"
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
			//Print "tab 0 = CONTROL"
			
			V_FillListBox0(PP_ListWave,PP_SelWave)
			break		
		case 1:	
			//Print "tab 1 = REDUCTION"
			
			V_FillListBox1(PP_ListWave,PP_SelWave)
			break
		case 2:	
			//Print "tab 2 = SAMPLE"
			
			V_FillListBox2(PP_ListWave,PP_SelWave)
			break
		case 3:	
			//Print "tab 3 = INSTRUMENT"
			
			V_FillListBox3(PP_ListWave,PP_SelWave)
			break
		case 4:	
			//Print "tab 4 = DETECTORS"
			
			V_FillListBox4(PP_ListWave,PP_SelWave)
			break
		case 5:	
			//Print "tab 5 = POL_SANS"

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
// *** if the number of elements is changed, then be sure that the variable nRows is updated
//    * this is the same procedure for all of the tabs
//    * then be sure that the new listWave assignments are properly indexed
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
	
	
	
	listWave[0][1] = "count_time (s)"
	listWave[0][2] = num2str(V_getCount_time(fname))
	
	listWave[1][1] = "detector_counts"
	listWave[1][2] = num2str(V_getDetector_counts(fname))
	
	listWave[2][1] = "monitor_counts"
//	listWave[2][2] = num2str(V_getControlMonitorCount(fname))
	listWave[2][2] = num2str(V_getBeamMonNormData(fname))
	
	return(0)
End

// fill list boxes based on the tab
//
// REDUCTION items
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

	Variable nRows = 14
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
	
	listWave[7][1] = "file_purpose"
	listWave[7][2] = V_getReduction_purpose(fname)
	
	listWave[8][1] = "group_id (sample)"
	listWave[8][2] = num2str(V_getSample_groupID(fname))
	
	listWave[9][1] = "Box Coordinates"
	WAVE boxCoord = V_getBoxCoordinates(fname)
	listWave[9][2] = V_NumWave2List(boxCoord,";")

	listWave[10][1] = "box_count"
	listWave[10][2] = num2str(V_getBoxCounts(fname))
	
	listWave[11][1] = "box_count_error"
	listWave[11][2] = num2str(V_getBoxCountsError(fname))
	
	listWave[12][1] = "whole_trans"
	listWave[12][2] = num2str(V_getSampleTransWholeDetector(fname))
	
	listWave[13][1] = "whole_trans_error"
	listWave[13][2] = num2str(V_getSampleTransWholeDetErr(fname))	
		
	

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
	
	listWave[1][1] = "thickness [cm]"
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

	Variable nRows = 17
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable

//
// TODO - the attenuation factor is always calculated from the table. How do I devise a method to 
// overrride this behavior if a factor needs to be forced to a new value (old table, lambda out of range, etc.)?
//	
// currently, this simply prevents anyone from "patching" the header, which really doesn't work as intended
//
	SelWave[0][0] += 2^7		// disable the checkbox for attenuator
	SelWave[1][0] += 2^7		// disable the checkbox for attenuator_err
	
	listWave[0][1] = "attenuator_transmission"
	listWave[0][2] = num2str(V_getAttenuator_transmission(fname))	
	
	listWave[1][1] = "attenuator_transmission_error"
	listWave[1][2] = num2str(V_getAttenuator_trans_err(fname))	

	listWave[2][1] = "monochromator type"
	listWave[2][2] = V_getMonochromatorType(fname)
	
	listWave[3][1] = "wavelength (A)"
	listWave[3][2] = num2str(V_getWavelength(fname))	
	
	listWave[4][1] = "wavelength_spread"
	listWave[4][2] = num2str(V_getWavelength_spread(fname))	
	
	listWave[5][1] = "Number of Guides OR COLLIMATION"
	listWave[5][2] = V_getNumberOfGuides(fname)

	listWave[6][1] = "distance (source aperture to GV) [cm]"
	listWave[6][2] = num2str(V_getSourceAp_distance(fname))		

	listWave[7][1] = "source aperture size [mm]"
	listWave[7][2] = V_getSourceAp_size(fname)
	
	listWave[8][1] = "sample aperture size (internal) [mm]"
	listWave[8][2] = V_getSampleAp_size(fname)

	listWave[9][1] = "sample aperture(2) SHAPE (external)"
	listWave[9][2] = V_getSampleAp2_shape(fname)
		
	listWave[10][1] = "sample aperture(2) diam (external) [cm]"
	listWave[10][2] = num2str(V_getSampleAp2_size(fname))	
	
	listWave[11][1] = "sample aperture(2) height (external) [cm]"
	listWave[11][2] = num2str(V_getSampleAp2_height(fname))	

	listWave[12][1] = "sample aperture(2) width (external) [cm]"
	listWave[12][2] = num2str(V_getSampleAp2_width(fname))	

	listWave[13][1] = "beam stop diameter (Middle) [mm]"
//	listWave[13][2] = num2str(V_getBeamStopC2_size(fname))	
	listWave[13][2] = num2str(V_IdentifyBeamstopDiameter(fname,"MR"))	
	
	listWave[14][1] = "beam stop diameter (Back) [mm]"
//	listWave[14][2] = num2str(V_getBeamStopC3_size(fname))	
	listWave[14][2] = num2str(V_IdentifyBeamstopDiameter(fname,"B"))	

	listWave[15][1] = "sample aperture(2) to gate valve [cm]"
	listWave[15][2] = num2str(V_getSampleAp2_distance(fname))	

	listWave[16][1] = "sample to gate valve [cm]"
	listWave[16][2] = num2str(V_getSampleTableOffset(fname))	

				
	return(0)
End


// fill list boxes based on the tab
//
// TODO -- is this all of the fields that I want to edit?
//
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

	Variable nRows = 13
	Redimension/N=(nRows,3) ListWave
	Redimension/N=(nRows,3) selWave
	// clear the contents
	listWave = ""
	selWave = 0
	SelWave[][0] = 2^5		// checkboxes
	SelWave[][2] = 2^1		// 3rd column editable
	
	ControlInfo popup_0			// which detector panel?
	String detStr = S_value
	
	listWave[0][1] = "beam_center_x [cm]"
	listWave[0][2] = num2str(V_getDet_Beam_center_x(fname,detStr))	

	listWave[1][1] = "beam_center_y [cm]"
	listWave[1][2] = num2str(V_getDet_Beam_center_y(fname,detStr))	

	listWave[2][1] = "distance (nominal) [cm]"
	listWave[2][2] = num2str(V_getDet_NominalDistance(fname,detStr))	

	listWave[3][1] = "integrated_count"
	listWave[3][2] = num2str(V_getDet_IntegratedCount(fname,detStr))	

	listWave[4][1] = "pixel_fwhm_x [cm]"
	listWave[4][2] = num2str(V_getDet_pixel_fwhm_x(fname,detStr))	

	listWave[5][1] = "pixel_fwhm_y [cm]"
	listWave[5][2] = num2str(V_getDet_pixel_fwhm_y(fname,detStr))	

	listWave[6][1] = "pixel_num_x"
	listWave[6][2] = num2str(V_getDet_pixel_num_x(fname,detStr))	

	listWave[7][1] = "pixel_num_y"
	listWave[7][2] = num2str(V_getDet_pixel_num_y(fname,detStr))	

	listWave[8][1] = "setback [cm]"
	listWave[8][2] = num2str(V_getDet_TBSetback(fname,detStr))	

	if(cmpstr(detStr,"B") == 0 ||cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		listWave[9][1] = "lateral_offset [cm]"			// "B" detector drops here
		listWave[9][2] = num2str(V_getDet_LateralOffset(fname,detStr))	
	else	
		listWave[9][1] = "vertical_offset [cm]"	
		listWave[9][2] = num2str(V_getDet_VerticalOffset(fname,detStr))	
	endif	

	listWave[10][1] = "x_pixel_size [mm]"
	listWave[10][2] = num2str(V_getDet_x_pixel_size(fname,detStr))	

	listWave[11][1] = "y_pixel_size [mm]"
	listWave[11][2] = num2str(V_getDet_y_pixel_size(fname,detStr))	

	listWave[12][1] = "dead time (s) (back only)"
	listWave[12][2] = num2str(V_getDetector_deadtime_B(fname,detStr))			//returns 0 if not "B"

	return(0)
End


// fill list boxes based on the tab
//
// TODO -- this all needs to be filled in, once I figure out what is needed
//
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
	
	
	listWave[0][1] = "count_time (s)"
	listWave[0][2] = num2str(V_getCount_time(fname))	

	return(0)
End


// TODO -- determine if I really need this --- I don't 
//  think I really have any reason to respond to events from list box actions
//  or edits. the final action of patching is done with the button
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
//contains the vSANS data
//sets catPathName, updates the path display and the popup of files (in that folder)
//
Function V_PickPathButton(PathButton) : ButtonControl
	String PathButton
	
	// call the main procedure to set the data path
	V_PickPath()
	
	//set the global string to the selected pathname
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
	
	STRUCT WMSetVariableAction sva
	sva.eventCode = 2	
	V_SetMatchStrProc(sva)		//this is equivalent to finding everything, typical startup case

	return(0)
End

//
//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
Function/S V_xGetValidPatchPopupList()

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



//
// TODO:
// -- test all of the filters to be sure they actually work properly.
//   Run # filter works
//   Text filter works
//
// -- SDD filter does not apply -- what is a better filter choice?
// -- can I filter intent? group_id?
// -- can't just search for "sample" - this returns everything
//
//
//
//
//
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
	Variable ii,num=ItemsInList(newList),val,group_id
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
	
	// group_id
	// replace this with: V_getSample_GroupID(fname)
	Variable pos
	String IDStr=""
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
			group_id = V_getSample_GroupID(fname)
			if(group_id == val)
				list += item + ";"
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

	
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
//	ControlUpdate PatchPopup
	V_ShowHeaderButtonProc("SHButton")
	
	return(0)
End


//when text is entered in the match string, the popup list is refined to 
//include only the selected files, useful for trimming a lengthy list, or selecting
//a range of files to patch
//only one wildcard (*) is allowed
//
//change the contents of gPatchList that is displayed
//based on selected Path, match str, and
//further trim list to include only RAW SANS files
//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)
Function V_SetMatchStrProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 8:		// edit end
			Variable dval = sva.dval
			String sval = sva.sval
			
			String list = V_GetValidPatchPopupList()
	
			String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
			ControlUpdate PatchPopup
			PopupMenu PatchPopup,mode=1
			
			if(strlen(list) > 0)
				V_ShowHeaderButtonProc("SHButton")
			endif
		case 3: // Live update

			break
		case -1: // control being killed
			break
	endswitch

	return 0
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
	
	// no matter what tab is selected, show the file label
	SVAR fileLabel = root:Packages:NIST:VSANS:Globals:Patch:gPatchCurLabel
	fileLabel = V_getSampleDescription(tempName)
	
	return(0)
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
			V_WriteHeaderForPatch_0(tempName)		//control
			break		// exit from switch
		case 1:	
			V_WriteHeaderForPatch_1(tempName)		//reduction
			break
		case 2:	
			V_WriteHeaderForPatch_2(tempName)		// sample
			break
		case 3:	
			V_WriteHeaderForPatch_3(tempName)		// instrument
			break
		case 4:	
			V_WriteHeaderForPatch_4(tempName)		//detectors
			break
		case 5:	
			V_WriteHeaderForPatch_5(tempName)		// polSANS
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
// DONE x- re-write a series of these function to mirror the "fill" functions
//   specific to each tab
//
// DONE x- clear out the old data and force a re-load from disk, or the old data
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
//		err = V_writeControlMonitorCount(fname,val)
		err = V_writeBeamMonNormData(fname,val)
	endif	
	



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
	
	if ((selWave[7][0] & 2^4) != 0)		//"file_purpose"
		str = listWave[7][2]
		err = V_writeReduction_purpose(fname,str)
	endif		

	if ((selWave[8][0] & 2^4) != 0)		//"group_id (sample)"
		val = str2num(listWave[8][2])
		err = V_writeSample_GroupID(fname,val)
	endif	



	if ((selWave[9][0] & 2^4) != 0)		//"box coordinates"
		str = listWave[9][2]
		err = V_writeBoxCoordinates(fname,V_List2NumWave(str,";","inW"))
	endif	
	

	
	if ((selWave[10][0] & 2^4) != 0)		//"box_count"
		val = str2num(listWave[10][2])
		err = V_writeBoxCounts(fname,val)
	endif	
	
	if ((selWave[11][0] & 2^4) != 0)		//"box_count_error"
		val = str2num(listWave[11][2])
		err = V_writeBoxCountsError(fname,val)
	endif	
	
	if ((selWave[12][0] & 2^4) != 0)		//"whole_trans"
		val = str2num(listWave[12][2])
		err = V_writeSampleTransWholeDetector(fname,val)
	endif	
	
	if ((selWave[13][0] & 2^4) != 0)		//"whole_trans_error"
		val = str2num(listWave[13][2])
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

	if ((selWave[5][0] & 2^4) != 0)		//"number of guides (a string value)"
		str = listWave[5][2]
		err = V_writeNumberOfGuides(fname,str)
	endif		
	
	if ((selWave[6][0] & 2^4) != 0)		//"distance (source aperture)"
		val = str2num(listWave[6][2])
		err = V_writeSourceAp_distance(fname,val)
	endif		

	if ((selWave[7][0] & 2^4) != 0)		//"source aperture size [mm]" (a string with units)
		str = listWave[7][2]
		err = V_writeSourceAp_size(fname,str)
	endif		

	if ((selWave[8][0] & 2^4) != 0)		//"sample aperture size (internal) [mm]" (a string with units)
		str = listWave[8][2]
		err = V_writeSampleAp_size(fname,str)
	endif	

	if ((selWave[9][0] & 2^4) != 0)		//"sample aperture SHAPE (external) [cm]"
		str = listWave[9][2]
		err = V_writeSampleAp2_shape(fname,str)
	endif		
	
	if ((selWave[10][0] & 2^4) != 0)		//"sample aperture diam (external) [cm]"
		val = str2num(listWave[10][2])
		err = V_writeSampleAp2_size(fname,val)
	endif		
	
	if ((selWave[11][0] & 2^4) != 0)		//"sample aperture height (external) [cm]"
		val = str2num(listWave[11][2])
		err = V_writeSampleAp2_height(fname,val)
	endif		
		
	if ((selWave[12][0] & 2^4) != 0)		//"sample aperture width (external) [cm]"
		val = str2num(listWave[12][2])
		err = V_writeSampleAp2_width(fname,val)
	endif		

	if ((selWave[13][0] & 2^4) != 0)		//"beam stop diameter (Middle) [mm]"
		val = str2num(listWave[13][2])
		err = V_writeBeamStopC2_size(fname,val)
	endif		
	
	if ((selWave[14][0] & 2^4) != 0)		//"beam stop diameter (Back) [mm]"
		val = str2num(listWave[14][2])
		err = V_writeBeamStopC3_size(fname,val)
	endif		

	if ((selWave[15][0] & 2^4) != 0)		//"sample aperture to gate valve [cm]"
		val = str2num(listWave[15][2])
		err = V_writeSampleAp_distance(fname,val)
	endif	

	if ((selWave[16][0] & 2^4) != 0)		//"sample to gate valve [cm]"
		val = str2num(listWave[16][2])
		err = V_writeSampleTableOffset(fname,val)
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
	
	if ((selWave[12][0] & 2^4) != 0)		//"dead time, "B" only"
		val = str2num(listWave[12][2])
		if(cmpstr(detStr,"B") == 0)
			err = V_writeDetector_deadtime_B(fname,detStr,val)
		endif
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
// DONE
// x- re-write this to be tab-aware. ShowHeaderForPatch() calls this, but does nothing
//    to update the tab content. Figure out which function is in charge, and update the content.
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
	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Patch File Headers]"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
	endif
	return(0)
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
// this is a block to patch DEADTIME waves to the file headers, and can patch multiple files
// 
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
// TODO -- need to clear out the contents from RawVSANS, or else re-reading to check the values
//        will read locally, and it will look like nothing was written. Executing "save" will also 
//        trigger a cleanout.
//
// TODO -- link this to a panel somewhere - a button? menu item? will there be a lot more of these little panels?
//
// TODO -- currently, this does not patch the deadtime for the back "B" detector. it is a single
//        value, not a wave see V_WritePerfectDeadTime(filename) for how the perfect (fake) values is written.
//
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
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDetectorDeadtime(lo,hi,detStr,deadtimeW)
	Variable lo,hi
	String detStr
	Wave deadtimeW
	
	Variable ii
	String fname
	
	// check the dimensions of the deadtimeW/N=48
	if (DimSize(deadtimeW, 0) != 48 )
		Abort "dead time wave is not of proper dimension (48)"
	endif
	
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
	DoWindow/F DeadtimePanel
	if(V_flag==0)
	
		NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Patch

		Make/O/D/N=48 deadTimeWave
		Variable/G gFileNum_Lo,gFileNum_Hi
		
		SetDataFolder root:
		
		Execute "V_DeadtimePatchPanel()"
	endif
End


// TODO:
// x- add method for generating "perfect" dead time to write
// x- check deadtime wave dimension before writing (check for bad paste operation)
// -- load from file? different ways to import?
// -- Dead time constants for "B" are different, and not handled here (yet)
// -- add help button/file
// -- add done button
// -- adjust after user testing
//
Proc V_DeadtimePatchPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel /W=(600*sc,400*sc,1000*sc,1000*sc)/N=DeadtimePanel /K=1
//	ShowTools/A
	ModifyPanel cbRGB=(16266,47753,2552,23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 85*sc,99*sc,"Current Values"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 18*sc,258*sc,"Write to all files (inlcusive)"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 209*sc,30*sc,"Dead Time Constants"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 18*sc,133*sc,"Run Number(s)"
	
	PopupMenu popup_0,pos={sc*20,40*sc},size={sc*109,20*sc},title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;\""
	
	Button button0,pos={sc*20,81*sc},size={sc*50.00,20.00*sc},proc=V_ReadDTButtonProc,title="Read"
	Button button0_1,pos={sc*20,220*sc},size={sc*50.00,20.00*sc},proc=V_WriteDTButtonProc,title="Write"
	Button button0_2,pos={sc*18.00,336.00*sc},size={sc*140.00,20.00*sc},proc=V_GeneratePerfDTButton,title="Perfect Dead Time"
	Button button0_3,pos={sc*18.00,370.00*sc},size={sc*140.00,20.00*sc},proc=V_LoadCSVDTButton,title="Load Dead Time CSV"
	Button button0_4,pos={sc*18.00,400.00*sc},size={sc*140.00,20.00*sc},proc=V_WriteCSVDTButton,title="Write Dead Time CSV"
	
	SetVariable setvar0,pos={sc*20,141*sc},size={sc*100.00,14.00*sc},title="first"
	SetVariable setvar0,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo
	SetVariable setvar1,pos={sc*20.00,167*sc},size={sc*100.00,14.00*sc},title="last"
	SetVariable setvar1,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi


// display the wave	
	Edit/W=(180*sc,40*sc,380*sc,550*sc)/HOST=#  root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
	ModifyTable width(Point)=30
	ModifyTable width(root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave)=110*sc
	RenameWindow #,T0
	SetActiveSubwindow ##

	
EndMacro


Function V_LoadCSVDTButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0				//will prompt for the file, auto name
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//TODO
// -- currently this skips detector "B", since its dead time is not like the tubes
// -- fails miserably if the deadtime_** waves don't exist
// -- the writing may take a long time. Warn the user.
// -- if the data files are not "cleaned up", re-reading will pick up the rawVSANS copy and it
//    will look like nothing was written
//
// writes the entire content of the CSV file (all 8 panels) to each detector entry in each data file
// as specified by the run number range
//
Function V_WriteCSVDTButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable ii
	String detStr
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			ControlInfo popup_0
//			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			ControlInfo setvar1
			Variable hi=V_Value
			Wave deadTimeW = root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
			
			for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
				detStr = StringFromList(ii, ksDetectorListNoB, ";")
				Wave tmpW = $("root:deadtime_"+detStr)
				deadTimeW = tmpW
				V_fPatchDetectorDeadtime(lo,hi,detStr,deadtimeW)
			endfor
			
			break
		case -1: // control being killed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
//
// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii=lo;ii<=hi;ii+=1)
		KillDataFolder/Z $("root:Packages:NIST:VSANS:RawVSANS:sans"+num2istr(ii))
	endfor
	return 0
End


Function V_GeneratePerfDTButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			WAVE deadTimeWave = root:Packages:NIST:VSANS:Globals:Patch:deadTimeWave
			ControlInfo popup_0
			strswitch(S_Value)
				case "FR":
				case "FL":
				case "MR":
				case "ML":
				case "FT":
				case "FB":
				case "MT":
				case "MB":
					deadTimeWave = 1e-18

					break
				default:
					Print "Det type not found: V_GeneratePerfDTButton()"
			endswitch
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




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
// this is a block to patch CALIBRATION waves to the file headers, and can patch multiple files
// 
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
// TODO -- need to clear out the contents from RawVSANS, or else re-reading to check the values
//        will read locally, and it will look like nothing was written. Executing "save" will also 
//        trigger a cleanout.
//
// TODO -- link this to a panel somewhere - a button? menu item? will there be a lot more of these little panels?
//
// TODO -- currently this does not handle the back detector "B". see V_WritePerfectSpatialCalib(filename)
//         for how fake data is written to the files
//
// TODO -- verify that the calibration waves are not transposed
//
Proc V_PatchDetectorCalibration(firstFile,lastFile,detStr,calibStr)
	Variable firstFile=1,lastFile=100
	String detStr = "FL",calibStr="calibrationWave"

	V_fPatchDetectorCalibration(firstFile,lastFile,detStr,$calibStr)

End

Proc V_ReadDetectorCalibration(firstFile,lastFile,detStr)
	Variable firstFile=1,lastFile=100
	String detStr = "FL"
	
	V_fReadDetectorCalibration(firstFile,lastFile,detStr)
End

// simple utility to patch the detector calibration wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDetectorCalibration(lo,hi,detStr,calibW)
	Variable lo,hi
	String detStr
	Wave calibW
	
	Variable ii
	String fname
	
	// check the dimensions of the calibW (3,48)
	if (DimSize(calibW, 0) != 3 || DimSize(calibW, 1) != 48 )
		Abort "Calibration wave is not of proper dimension (3,48)"
	endif
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeDetTube_spatialCalib(fname,detStr,calibW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector deadtime stored in the file header
Function V_fReadDetectorCalibration(lo,hi,detStr)
	Variable lo,hi
	String detStr
	
	String fname
	Variable ii
	
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			Wave calibW = V_getDetTube_spatialCalib(fname,detStr)
			Duplicate/O calibW root:Packages:NIST:VSANS:Globals:Patch:calibrationWave
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End


Proc V_PatchDetectorCalibrationPanel()
	DoWindow/F CalibrationPanel
	if(V_flag==0)
	
		NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Patch

		Make/O/D/N=(3,48) calibrationWave
		
		Variable/G gFileNum_Lo,gFileNum_Hi
		SetDataFolder root:
		
		Execute "V_CalibrationPatchPanel()"
	endif
End


//
// TODO:
// x- add method for generating "perfect" calibration to write
// x- check Nx3 dimension before writing (check for bad paste operation)
// -- load from file? different ways to import?
// -- calibration constants for "B" are different, and not handled here (yet)
// -- add help button/file
// -- add done button
// -- adjust after user testing
//
Proc V_CalibrationPatchPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel /W=(600*sc,400*sc,1200*sc,1000*sc)/N=CalibrationPanel /K=1
//	ShowTools/A
	ModifyPanel cbRGB=(16266,47753,2552,23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 85*sc,99*sc,"Current Values"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 18*sc,258*sc,"Write to all files (inlcusive)"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 227*sc,28*sc,"Quadratic Calibration Constants per Tube"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 18*sc,133*sc,"Run Number(s)"
		
	PopupMenu popup_0,pos={sc*20,40*sc},size={sc*109,20*sc},title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;\""
	
	Button button0,pos={sc*20,81*sc},size={sc*50.00,20.00*sc},proc=V_ReadCalibButtonProc,title="Read"
	Button button0_1,pos={sc*20,220*sc},size={sc*50.00,20.00*sc},proc=V_WriteCalibButtonProc,title="Write"
	Button button0_2,pos={sc*18.00,336.00*sc},size={sc*140.00,20.00*sc},proc=V_GeneratePerfCalibButton,title="Perfect Calibration"
	Button button0_3,pos={sc*18.00,370.00*sc},size={sc*140.00,20.00*sc},proc=V_LoadCSVCalibButton,title="Load Calibration CSV"
	Button button0_4,pos={sc*18.00,400.00*sc},size={sc*140.00,20.00*sc},proc=V_WriteCSVCalibButton,title="Write Calibration CSV"
		
	SetVariable setvar0,pos={sc*20,141*sc},size={sc*100.00,14.00*sc},title="first"
	SetVariable setvar0,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo
	SetVariable setvar1,pos={sc*20.00,167*sc},size={sc*100.00,14.00*sc},title="last"
	SetVariable setvar1,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi


// display the wave	
	Edit/W=(180*sc,40*sc,580*sc,550*sc)/HOST=#  root:Packages:NIST:VSANS:Globals:Patch:calibrationWave
	ModifyTable width(Point)=30
	ModifyTable width(root:Packages:NIST:VSANS:Globals:Patch:calibrationWave)=100*sc
	// the elements() command transposes the view in the table, but does not transpose the wave
	ModifyTable elements(root:Packages:NIST:VSANS:Globals:Patch:calibrationWave) = (-3, -2)
	RenameWindow #,T0
	SetActiveSubwindow ##

	
EndMacro


Function V_LoadCSVCalibButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0				//will prompt for the file, auto name
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//TODO
// -- currently this skips detector "B", since its calibration is not like the tubes
// -- fails miserably if the a,b,c_** waves don't exist
// -- the writing may take a long time. Warn the user.
// -- if the data files are not "cleaned up", re-reading will pick up the rawVSANS copy and it
//    will look like nothing was written
//
// writes the entire content of the CSV file (all 8 panels) to each detector entry in each data file
// as specified by the run number range
//
Function V_WriteCSVCalibButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable ii
	String detStr
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			ControlInfo popup_0
//			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			ControlInfo setvar1
			Variable hi=V_Value
			WAVE calibrationWave = root:Packages:NIST:VSANS:Globals:Patch:calibrationWave
			
			for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
				detStr = StringFromList(ii, ksDetectorListNoB, ";")
				Wave tmp_a = $("root:a_"+detStr)
				Wave tmp_b = $("root:b_"+detStr)
				Wave tmp_c = $("root:c_"+detStr)
				calibrationWave[0][] = tmp_a[q]
				calibrationWave[1][] = tmp_b[q]
				calibrationWave[2][] = tmp_c[q]
				V_fPatchDetectorCalibration(lo,hi,detStr,calibrationWave)
			endfor
			
			break
		case -1: // control being killed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
//
// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii=lo;ii<=hi;ii+=1)
		KillDataFolder/Z $("root:Packages:NIST:VSANS:RawVSANS:sans"+num2istr(ii))
	endfor
	return 0
End



//	// and for the back detector "B"
//	Make/O/D/N=3 tmpCalib
//	tmpCalib[0] = 1
//	tmpCalib[1] = 1
//	tmpcalib[2] = 10000
//	V_writeDet_cal_x(filename,"B",tmpCalib)
//	V_writeDet_cal_y(filename,"B",tmpCalib)
//
// "Perfect" values here are from Phil (2/2018)
//
Function V_GeneratePerfCalibButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			WAVE calibrationWave = root:Packages:NIST:VSANS:Globals:Patch:calibrationWave
			ControlInfo popup_0
			strswitch(S_Value)
				case "FR":
				case "FL":
				case "MR":
				case "ML":
					//	// for the "tall" L/R banks
					calibrationWave[0][] = -521
					calibrationWave[1][] = 8.14
					calibrationWave[2][] = 0
					break
				case "FT":
				case "FB":
				case "MT":
				case "MB":
					//	// for the "short" T/B banks
					calibrationWave[0][] = -266
					calibrationWave[1][] = 4.16
					calibrationWave[2][] = 0

					break
				default:
					Print "Det type not found: V_GeneratePerfCalibButton()"
			endswitch


			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_ReadCalibButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ControlInfo popup_0
			String detStr = S_Value
			ControlInfo setvar0
			Variable lo=V_Value
			Variable hi=lo
			
			V_fReadDetectorCalibration(lo,hi,detStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_WriteCalibButtonProc(ba) : ButtonControl
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
			Wave calibW = root:Packages:NIST:VSANS:Globals:Patch:calibrationWave
			
			V_fPatchDetectorCalibration(lo,hi,detStr,calibW)
			
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
//
//		added in May 2019 -- kill the same numbered files from RawVSANS to force a re-read since the XY
//  has been changed
Function V_fPatchDet_xyCenters(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
	
	Wave xCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:xCtr_cm
	Wave yCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:yCtr_cm
	Wave/T panelW = root:Packages:NIST:VSANS:Globals:Patch:panelW
	
	// check the dimensions of the waves (9)
	if (DimSize(xCtr_cm, 0) != 9 || DimSize(yCtr_cm, 0) != 9 || DimSize(panelW, 0) != 9)
		Abort "waves are not of proper dimension (9)"
	endif
	
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
				detStr = panelW[ii]
				V_writeDet_beam_center_x(fname,detStr,xCtr_cm[ii])
				V_writeDet_beam_center_y(fname,detStr,yCtr_cm[ii])		
			endfor	
		
		// then delete the file from RawVSANS
			V_KillNamedDataFolder(fname)
			
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector xy centers stored in the file header
Function V_fReadDet_xyCenters(lo,hi)
	Variable lo,hi

	
	String fname,detStr
	Variable ii,jj
	
	Wave xCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:xCtr_cm
	Wave yCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:yCtr_cm
	Wave/T panelW = root:Packages:NIST:VSANS:Globals:Patch:panelW
	
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
				detStr = StringFromList(ii, ksDetectorListAll, ";")
				panelW[ii] = detStr
				xCtr_cm[ii] = V_getDet_beam_center_x(fname,detStr)		//these values are in cm, not pixels
				yCtr_cm[ii] = V_getDet_beam_center_y(fname,detStr)
			endfor
		
		
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor

	
	return(0)
End



Proc V_PatchDet_xyCenters_Panel()
	DoWindow/F Patch_XY_Panel
	if(V_flag==0)
	
		NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Patch

		Make/O/D/N=9 xCtr_cm,yCtr_cm
		Make/O/T/N=9 panelW
		
		PanelW = {"FL","FR","FT","FB","ML","MR","MT","MB","B"}
		
		Variable/G gFileNum_Lo,gFileNum_Hi
		
		SetDataFolder root:
		
		Execute "V_Patch_xyCtr_Panel()"
	endif
End


// TODO:
// -- add method to read (import) from beam center panel
// x- check wave dimensions before writing (check for bad paste operation)
// -- load from file? different ways to import?
// -- add help button/file
// -- add done button
// -- adjust after user testing
//
Proc V_Patch_xyCtr_Panel() : Panel
	PauseUpdate; Silent 1		// building window...

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel /W=(600*sc,400*sc,1150*sc,800*sc)/N=Patch_XY_Panel /K=1
//	ShowTools/A
	
	ModifyPanel cbRGB=(16266,47753,2552,23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 85*sc,99*sc,"Current Values"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 18*sc,258*sc,"Write to all files(inlcusive)"
	SetDrawEnv fsize= 14*sc,fstyle= 1
	DrawText 20*sc,133*sc,"Run Number(s)"
	DrawText 262*sc,30*sc,"Beam Center [cm]"

	
	Button button0,pos={sc*20,81*sc},size={sc*50.00,20.00*sc},proc=V_ReadXYButtonProc,title="Read"
	Button button0_1,pos={sc*20,220*sc},size={sc*50.00,20.00*sc},proc=V_WriteXYButtonProc,title="Write"
	SetVariable setvar0,pos={sc*20,141*sc},size={sc*100.00,14.00*sc},title="first"
	SetVariable setvar0,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo
	SetVariable setvar1,pos={sc*20.00,167*sc},size={sc*100.00,14.00*sc},title="last"
	SetVariable setvar1,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi

	
	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch
// display the wave	
	Edit/W=(180*sc,40*sc,500*sc,370*sc)/HOST=#  panelW,xCtr_cm,yCtr_cm
	ModifyTable width(Point)=0
	ModifyTable width(panelW)=70*sc
	ModifyTable width(xCtr_cm)=90*sc
	ModifyTable width(yCtr_cm)=90*sc
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

// this function will write the new centers to the file and then delete the file from
// RawVSANS to force a re-read of the data			
			V_fPatchDet_xyCenters(lo,hi)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////


Proc V_PatchDet_Offset(lo,hi)
	Variable lo,hi
	
	V_fPatchDet_Offset(lo,hi)
End

Proc V_MarkLeftRightFlip_Done(lo,hi)
	Variable lo,hi
	
	V_fWriteFlipState(lo,hi,1)	// value == 1 means flip done
End

Proc V_MarkLeftRightFlip_Not_Done(lo,hi)
	Variable lo,hi
	
	V_fWriteFlipState(lo,hi,-999999)	// value == -999999 means flip not done
End


Proc V_Patch_GroupID_catTable()
	V_fPatch_GroupID_catTable()
end

Proc V_Patch_Purpose_catTable()
	V_fPatch_Purpose_catTable()
end

Proc V_Patch_Intent_catTable()
	V_fPatch_Intent_catTable()
end

Proc V_PatchDet_Gap(lo,hi)
	Variable lo,hi
	
	V_fPatchDet_Gap(lo,hi)
End

Proc V_ReadDet_Gap(lo,hi)
	Variable lo,hi
	
	V_fReadDet_Gap(lo,hi)
End

Proc V_PatchDet_Distance(lo,hi,dist_f,dist_m,dist_b)
	Variable lo,hi,dist_f=400,dist_m=1900,dist_b=2200
	
	V_fPatchDet_distance(lo,hi,dist_f,dist_m,dist_b)
End


//
// Not used any longer - as of 2019
// this was filling in default values that have since been replaced with proper values
//
//Proc V_Patch_Back_Detector(lo,hi)
//	Variable lo,hi
//	
//	V_fPatch_BackDetector(lo,hi)
//End

Proc V_Patch_Back_XYPixelSize(lo,hi)
	Variable lo,hi
	
	V_fPatch_BackDetectorPixel(lo,hi)
end

Proc V_Patch_XYPixelSize(lo,hi)
	Variable lo,hi
	
	V_fPatch_XYPixelSize(lo,hi)
End

// simple utility to patch the offset values in the file headers
//
// Swaps only the L/R detector values
// lo is the first file number
// hi is the last file number (inclusive)
//
//		V_getLeftRightFlipDone(fname)
//
//
// updated the function to check for the "already done" flag
// - if already done, report this and do nothing.
// - if not done, do the flip and set the flag
//
Function V_fPatchDet_Offset(lo,hi)
	Variable lo,hi

	
	Variable ii,jj,flipDone=0
	String fname,detStr
	
	Variable offset_ML,offset_MR,offset_FL,offset_FR

	
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			flipDone = V_getLeftRightFlipDone(fname)
			if(flipDone == 1)
				printf "run number %d already flipped - nothing done\r",jj
			else
				offset_FL = V_getDet_LateralOffset(fname,"FL")
				offset_FR = V_getDet_LateralOffset(fname,"FR")
	
				offset_ML = V_getDet_LateralOffset(fname,"ML")
				offset_MR = V_getDet_LateralOffset(fname,"MR")
			
			// swap L/R offset values
				V_WriteDet_LateralOffset(fname,"FL",-offset_FR)
				V_WriteDet_LateralOffset(fname,"FR",-offset_FL)
				
				V_WriteDet_LateralOffset(fname,"ML",-offset_MR)
				V_WriteDet_LateralOffset(fname,"MR",-offset_ML)
			
			// set the flag
				V_writeLeftRightFlipDone(fname,1)		// value == 1 means the flip was done
				Print fname
				Print "swapped FL, FR = ",-offset_FR,-offset_FL
				Print "swapped ML, MR = ",-offset_MR,-offset_ML
			
			endif
		
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor
	
	return(0)
End

//  utility to reset the flip state in the file headers
//
// lo is the first file number
// hi is the last file number (inclusive)
//
// setting value == 1 means done
// setting value == -999999 means not done (mimics a missing /entry)
//
Function V_fWriteFlipState(lo,hi,val)
	Variable lo,hi,val

	
	Variable ii,jj,flipDone=0
	String fname,detStr
	
	Variable offset_ML,offset_MR,offset_FL,offset_FR

	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
	
		// set the flag
			V_writeLeftRightFlipDone(fname,val)		// 
			Print fname
			printf "run number %d flag reset to %d\r",jj,val
			
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor
	
	return(0)
End



// simple utility to read the detector offset stored in the file header
Function V_fReadDet_Offset(lo,hi)
	Variable lo,hi

	String fname,detStr
	Variable jj
	Variable offset_ML,offset_MR,offset_FL,offset_FR
	
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			offset_FL = V_getDet_LateralOffset(fname,"FL")
			offset_FR = V_getDet_LateralOffset(fname,"FR")

			offset_ML = V_getDet_LateralOffset(fname,"ML")
			offset_MR = V_getDet_LateralOffset(fname,"MR")
		
			Print fname
			Print "FL, FR = ",offset_FL,offset_FR
			Print "ML, MR = ",offset_ML,offset_MR
		
		
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor

	
	return(0)
End


// patches the group_ID, based on whatever is in the catTable
//
Function V_fPatch_GroupID_catTable()
	Variable lo,hi

	
	Variable ii,jj,num
	
	Wave id = root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID
	Wave/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames

	num = numpnts(id)	
	//loop over all files
	for(jj=0;jj<num;jj+=1)
		Print "update file ",jj,fileNameW[jj]
		V_writeSample_GroupID(fileNameW[jj],id[jj])	
	endfor
	
	return(0)
End


// patches the Purpose, based on whatever is in the catTable
//
Function V_fPatch_Purpose_catTable()
	Variable lo,hi

	
	Variable ii,jj,num
	
	Wave/T purpose = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose
	Wave/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames

	num = numpnts(purpose)	
	//loop over all files
	for(jj=0;jj<num;jj+=1)
		Print "update file ",jj,fileNameW[jj]
		V_writeReduction_Purpose(fileNameW[jj],purpose[jj])	
	endfor
	
	return(0)
End

// patches the Intent, based on whatever is in the catTable
//
Function V_fPatch_Intent_catTable()
	Variable lo,hi

	
	Variable ii,jj,num
	
	Wave/T intent = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent
	Wave/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames

	num = numpnts(intent)	
	//loop over all files
	for(jj=0;jj<num;jj+=1)
		Print "update file ",jj,fileNameW[jj]
		V_writeReductionIntent(fileNameW[jj],intent[jj])	
	endfor
	
	return(0)
End



// simple utility to patch the detector gap values in the file headers
//
// values are measured values in [mm], not estimated
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDet_Gap(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
		// write gap values
			V_writeDet_panel_gap(fname,"FL",3.5)
			V_writeDet_panel_gap(fname,"FR",3.5)

			V_writeDet_panel_gap(fname,"FT",3.3)
			V_writeDet_panel_gap(fname,"FB",3.3)

			V_writeDet_panel_gap(fname,"ML",5.9)
			V_writeDet_panel_gap(fname,"MR",5.9)

			V_writeDet_panel_gap(fname,"MT",18.3)
			V_writeDet_panel_gap(fname,"MB",18.3)		
		
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector gap values stored in the file header
Function V_fReadDet_Gap(lo,hi)
	Variable lo,hi

	String fname,detStr
	Variable jj
	Variable gap_FL,gap_FR,gap_FT,gap_FB,gap_ML,gap_MR,gap_MT,gap_MB
	
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			gap_FL = V_getDet_panel_gap(fname,"FL")
			gap_FR = V_getDet_panel_gap(fname,"FR")
			gap_FT = V_getDet_panel_gap(fname,"FT")
			gap_FB = V_getDet_panel_gap(fname,"FB")

			gap_ML = V_getDet_panel_gap(fname,"ML")
			gap_MR = V_getDet_panel_gap(fname,"MR")
			gap_MT = V_getDet_panel_gap(fname,"MT")
			gap_MB = V_getDet_panel_gap(fname,"MB")
			
			print fname	
			Print "FL, FR, FT, FB = ",gap_FL,gap_FR,gap_FT,gap_FB
			Print "ML, MR, MT, MB = ",gap_ML,gap_MR,gap_MT,gap_MB
		
		
		else
			printf "run number %d not found\r",jj
		endif
		
	endfor

	
	return(0)
End


// simple utility to patch the detector distance values in the file headers
//
// values are in [cm]
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchDet_distance(lo,hi,d_f,d_m,d_b)
	Variable lo,hi,d_f,d_m,d_b

	
	Variable ii,jj
	String fname,detStr
		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
		// write gap values
			V_writeDet_distance(fname,"FL",d_f)
			V_writeDet_distance(fname,"FR",d_f)
			V_writeDet_distance(fname,"FT",d_f)
			V_writeDet_distance(fname,"FB",d_f)

			V_writeDet_distance(fname,"ML",d_m)
			V_writeDet_distance(fname,"MR",d_m)
			V_writeDet_distance(fname,"MT",d_m)
			V_writeDet_distance(fname,"MB",d_m)		

			V_writeDet_distance(fname,"B",d_b)		
		
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	return(0)
End


//
// simple utility to patch all of the values associated with the back detector
//
// as of Dec 2019, this is not used any longer as these values are all written correctly,
// except for patching old data with the XY pixel dimensions (separate macro)
//
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatch_BackDetector(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
	
	detStr = "B"
	
	Make/O/D/N=3 cal_x,cal_y
	cal_x[0] = VCALC_getPixSizeX(detStr)			// pixel size in VCALC_getPixSizeX(detStr) is [cm]
	cal_x[1] = 1
	cal_x[2] = 10000
	cal_y[0] = VCALC_getPixSizeY(detStr)			// pixel size in VCALC_getPixSizeX(detStr) is [cm]
	cal_y[1] = 1
	cal_y[2] = 10000
	
	Make/O/I/N=(680,1656) tmpData=1
	
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
		// patch cal_x and cal_y
			V_writeDet_cal_x(fname,detStr,cal_x)
			V_writeDet_cal_y(fname,detStr,cal_y)
		
		// patch n_pix_x and y
			V_writeDet_pixel_num_x(fname,detStr,680)
			V_writeDet_pixel_num_y(fname,detStr,1656)
			
		// patch pixel size x and y [cm]
			V_writeDet_x_pixel_size(fname,detStr,0.034)
			V_writeDet_y_pixel_size(fname,detStr,0.034)
			
		// patch dead time
		// TODO: enter a proper value here once it's actually measured
			V_writeDetector_deadtime_B(fname,detStr,1e-20)
		
		// patch fwhm_x and y
		// TODO: verify the values once they are measured, and also the UNITS!!! [cm]???
			V_writeDet_pixel_fwhm_x(fname,detStr,0.034)
			V_writeDet_pixel_fwhm_y(fname,detStr,0.034)
		
		// patch beam center (nominal x,y) [cm] values
			V_writeDet_beam_center_x(fname,detStr,11)
			V_writeDet_beam_center_y(fname,detStr,25)
		
		// fake data
//			V_writeDetectorData(fname,detStr,tmpData)
			
			
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	KillWaves/Z cal_x,cal_y,tmpData
	return(0)
End


//
// simple utility to patch the X and Y Pixel dimensions for the back detector
// the cal_x(y) values are what is actually used to calculate the real space distance
// and then ultimately the q-values.
//
// **this updated value for the pixel size is from a measurement of a grid of pinholes
// as a mask in front of the detector (done in Sept 2019,  run 43550 - calculations
// done in Dec 2019)
//
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatch_BackDetectorPixel(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
	
	detStr = "B"
	
	Make/O/D/N=3 cal_x,cal_y
	cal_x[0] = 0.03175			// pixel size in VCALC_getPixSizeX(detStr) is [cm]
	cal_x[1] = 1
	cal_x[2] = 10000
	cal_y[0] = 0.03175		// pixel size in VCALC_getPixSizeX(detStr) is [cm]
	cal_y[1] = 1
	cal_y[2] = 10000
	
	
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
		// patch cal_x and cal_y
			V_writeDet_cal_x(fname,detStr,cal_x)
			V_writeDet_cal_y(fname,detStr,cal_y)
				
		// patch pixel size x and y [cm]
			V_writeDet_x_pixel_size(fname,detStr,0.03175)
			V_writeDet_y_pixel_size(fname,detStr,0.03175)
					
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	KillWaves/Z cal_x,cal_y
	return(0)
End



//
// simple utility to patch all of the pixel sizes
// - in the header, the Y size for LR panels was grossly wrong (4 mm)
// and all of the values are slightly off from the true values
//
// data collected after 10/3/18 should not need this patch since the
// config.js file was updated
//
//
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatch_XYPixelSize(lo,hi)
	Variable lo,hi

	
	Variable ii,jj
	String fname,detStr
	
	
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
			
		// patch pixel size x and y [cm] L/R panels
			V_writeDet_x_pixel_size(fname,"FL",8.4)
			V_writeDet_y_pixel_size(fname,"FL",8.14)

			V_writeDet_x_pixel_size(fname,"FR",8.4)
			V_writeDet_y_pixel_size(fname,"FR",8.14)			

			V_writeDet_x_pixel_size(fname,"ML",8.4)
			V_writeDet_y_pixel_size(fname,"ML",8.14)

			V_writeDet_x_pixel_size(fname,"MR",8.4)
			V_writeDet_y_pixel_size(fname,"MR",8.14)
			
		// patch pixel size x and y [cm] T/B panels
			V_writeDet_x_pixel_size(fname,"FT",4.16)
			V_writeDet_y_pixel_size(fname,"FT",8.4)

			V_writeDet_x_pixel_size(fname,"FB",4.16)
			V_writeDet_y_pixel_size(fname,"FB",8.4)			

			V_writeDet_x_pixel_size(fname,"MT",4.16)
			V_writeDet_y_pixel_size(fname,"MT",8.4)

			V_writeDet_x_pixel_size(fname,"MB",4.16)
			V_writeDet_y_pixel_size(fname,"MB",8.4)			
			
		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	return(0)
End


Proc V_Patch_Guide_SSD_Aperture(lo,hi,numGuideStr,sourceDiam_mm)
	Variable lo,hi
	String numGuideStr="CONV_BEAMS"
	Variable sourceDiam_mm=30
	
	V_fPatch_Guide_SSD_Aperture(lo,hi,numGuideStr,sourceDiam_mm)
End



// simple utility to patch all three at once, since they are all linked and typically
/// are all incorrectly entered by NICE if the number of guides can't be determined
//
// Number of guides
// source aperture to gate valve distance [cm]
// source aperture diameter [mm]
//
// the source aperture is assumed to be circular and the diameter in mm
//
// the value for the A1_to_GV is from tabulated values.  (see VC_calcSSD) 
// This is the Source aperture to Gate Valve distance
//
//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatch_Guide_SSD_Aperture(lo,hi,numGuideStr,sourceDiam_mm)
	Variable lo,hi
	String numGuideStr
	Variable sourceDiam_mm

	
	Variable ii,jj,A1_to_GV
	String fname,detStr

	strswitch(numGuideStr)
		case "CONV_BEAMS":
		case "NARROW_SLITS":
		case "0":
				A1_to_GV = 2441
			break
		case "1":
				A1_to_GV = 2157
			break
		case "2":
				A1_to_GV = 1976
			break
		case "3":
				A1_to_GV = 1782
			break			
		case "4":
				A1_to_GV = 1582
			break			
		case "5":
				A1_to_GV = 1381
			break			
		case "6":
				A1_to_GV = 1181
			break			
		case "7":
				A1_to_GV = 980
			break			
		case "8":
				A1_to_GV = 780
			break			
		case "9":
				A1_to_GV = 579
			break			
		default:
			Print "Error - using default A1_to_GV value"
			A1_to_GV = 2441
	endswitch

		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
		// write values
		V_writeNumberOfGuides(fname,numGuideStr)

		V_writeSourceAp_distance(fname,A1_to_GV)

		V_writeSourceAp_shape(fname,"CIRCLE")
		V_writeSourceAp_size(fname,num2str(sourceDiam_mm))

		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	return(0)
End


//
// pick the carriage, beamstop number, beamstop shape, and beamstop diameter
// or height and width
Proc V_Patch_BeamStop(lo,hi,carriageStr,bs_num,bsShapeStr,bs_diam,bs_width,bs_height)
	Variable lo,hi
	String carriageStr="B"
	Variable bs_num=2
	String bsShapeStr="CIRCLE"
	Variable bs_diam=12,bs_width=12,bs_height=300
	
	V_fPatch_BeamStop(lo,hi,carriageStr,bs_num,bsShapeStr,bs_diam,bs_width,bs_height)
End


//
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatch_BeamStop(lo,hi,carriageStr,bs_num,bsShapeStr,bs_diam,bs_width,bs_height)
	Variable lo,hi
	String carriageStr
	Variable bs_num
	String bsShapeStr
	Variable bs_diam,bs_width,bs_height

	
	Variable ii,jj,A1_to_GV
	String fname,detStr

		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)

			if(cmpstr("F",carriageStr) == 0)
				Print "front carriage has no beamstops"
			endif
			
			if(cmpstr("M",carriageStr) == 0)
				// middle carriage (2)
				V_writeBeamStopC2num_stop(fname,bs_num)
				V_writeBeamStopC2_shape(fname,bsShapeStr)
				if(cmpstr("CIRCLE",bsShapeStr)==0)
					V_writeBeamStopC2_size(fname,bs_diam)
				else
					V_writeBeamStopC2_height(fname,bs_height)
					V_writeBeamStopC2_width(fname,bs_width)
				endif
			endif
		
			if(cmpstr("B",carriageStr) == 0)
				// back carriage (3)
				V_writeBeamStopC3num_stop(fname,bs_num)
				V_writeBeamStopC3_shape(fname,bsShapeStr)
				if(cmpstr("CIRCLE",bsShapeStr)==0)
					V_writeBeamStopC3_size(fname,bs_diam)
				else
					V_writeBeamStopC3_height(fname,bs_height)
					V_writeBeamStopC3_width(fname,bs_width)				
				endif
			endif	

		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	
	return(0)
End


Proc V_Patch_SampleAperture2(lo,hi,ShapeStr,diam,width,height)
	Variable lo,hi
	String shapeStr="CIRCLE"
	Variable diam,width,height
	
	V_fPatch_SampleAperture2(lo,hi,ShapeStr,diam,width,height)
End

//
// lo is the first file number
// hi is the last file number (inclusive)
//
// Patches sample aperture (2), the external aperture
//
// dimensions are expected to be in [cm]
//
Function V_fPatch_SampleAperture2(lo,hi,ShapeStr,diam,width,height)
	Variable lo,hi
	String ShapeStr
	Variable diam,width,height

	Variable jj
	String fname,detStr

		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			V_writeSampleAp2_shape(fname,ShapeStr)
			if(cmpstr("CIRCLE",ShapeStr)==0)
				V_writeSampleAp2_size(fname,diam)
			else
				//RECTANGLE
				V_writeSampleAp2_height(fname,height)
				V_writeSampleAp2_width(fname,width)				
			endif

		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	
	return(0)
End


Proc V_Patch_MonochromatorType(lo,hi,typeStr)
	Variable lo,hi
	String typeStr="super_white_beam"
	
	V_fPatch_MonochromatorType(lo,hi,typeStr)
End

//		err = V_writeMonochromatorType(fname,str)
Function V_fPatch_MonochromatorType(lo,hi,typeStr)
	Variable lo,hi
	String typeStr

	Variable jj
	String fname

		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			V_writeMonochromatorType(fname,typeStr)

		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	
	return(0)
End

Proc V_Patch_Wavelength(lo,hi,wavelength,delta)
	Variable lo,hi
	Variable wavelength=6.2,delta=0.8
	
	V_fPatch_Wavelength(lo,hi,wavelength,delta)
End

//		err = V_writeWavelength(fname,val)
Function V_fPatch_Wavelength(lo,hi,lam,delta)
	Variable lo,hi
	Variable lam,delta

	Variable jj
	String fname

		
	//loop over all files
	for(jj=lo;jj<=hi;jj+=1)
		fname = V_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)
		
			V_writeWavelength(fname,lam)
			V_writeWavelength_Spread(fname,delta)

		else
			printf "run number %d not found\r",jj
		endif
	endfor
	
	
	return(0)
End
