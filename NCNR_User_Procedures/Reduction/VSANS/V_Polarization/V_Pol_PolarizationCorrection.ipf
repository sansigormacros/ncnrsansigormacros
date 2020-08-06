#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=7.0


//
// JUNE 2020
// first implementation of the Polarization routines to work with VSANS
// 



// These procedures and calculations duplicate the work of K. Krycka and WC Chen
// in calculating the state of the He cell and subsequent correction of scattering data
//
//
// SRK May 2011
//
//
//
// there is a particular sequence of things that need to be calculated
// lots of constants, and lots of confusing, similar notation.
//
//
// for this implementation, I'll follow what is described in the "PASANS"
// writeup by K. Krycka, and I'll try to follow the equations as numbered there
// and keep the notation as close as possible.
//
// error propagation is written up elsewhere


// I'll need space for 4 input files in, say SAM
// - load in all of the UU files, adding together
// - rename the UU data, error
//
// - repeat for the other three cross sections, in the SAM folder, there will be 
// scattering data for all four cross sections present.
//
// then add together the values for the coefficient matrix.
// -- this can be tricky with rescaling for time, and adding to the proper row of the 
// coefficient matrix. I'll need to re-read either the monitor or the time from the header
// of each file that was added so that the contributions are added to the matrix in correct proportion
//
// Then everything is set to do the inversion.
// -- the result of the inversion is 4 corrected data sets, with no polarization effects. "_pc"
//
// Now I can one-by-one, copy the correct UU, UD, etc. into "data" and "linear_data" (and the Reals, etc)
// and run through the corrections as if it was normal SANS data
//
// this whole procedure is going to be essentially a big script of existing procedures
//
//

// **** search for TODO to find items still to be fixed in other procedures  **********
//
//
// TODO:
//
// X- mathod to save and restore the panel state - especially the popup selections
//
// X- should I force the Polarization correction to be re-done just before the protocol is
//			executed? Then I'm sure that the PC is done. Must do for each tab (only if part of the protocol)
//			Except that the procedures work on the "active" tab... (YES, and this has been done)
//
// -- When multiple files are added together, there are changes made to the RealsRead (monCts, etc.). Are these
//		properly made, and then properly copied to the "_UU", and then properly copied back to the untagged waves
//		for use in the reduction? (now at this later date, I don't understand this question...)
//
// -- still not sure what is needed for absolute scaling
//
// -- what is the sample transmission, and exactly what +/- states are the proper measurements to use for transmission?
//
// -- generate some sort of report of what was set up, and what was used in the calculation
//
//




// main entry to the PolCor Panel
Proc V_ShowPolCorSetup()

	Variable restore=0
	DoWindow/F V_PolCor_Panel
	if(V_flag==0)
	
		V_InitProtocolPanel()		//this will reset the strings.
		
		restore=V_Initialize_PolCorPanel()
		V_PolCor_Panel()
		
		// be sure that the panel is onscreen
		DoIgorMenu "Control","Retrieve Window"
	
		SetWindow V_PolCor_Panel hook(kill)=V_PolCorPanelHook		//to save the state when panel is killed
		//disable the controls on other tabs
		V_ToggleSelControls("_1_",1)
		V_ToggleSelControls("_2_",1)
		
		//restore the entries
		if(restore)
			V_RestorePolCorPanel()
		endif
		

	endif
End


Function V_RestorePolCorPanel()
	//restore the popup state
	Wave/T/Z w=root:Packages:NIST:VSANS:Globals:Polarization:PolCor_popState

	Variable ii,num
	String name,popStr,list
	
	list = V_P_GetConditionNameList()		//list of conditions
	if(WaveExists(w))
		num = DimSize(w,0)
		for(ii=0;ii<num;ii+=1)
			name = w[ii][0]
			popStr = w[ii][1]
			if(cmpstr("none",popStr) !=0 )
				PopupMenu $name,win=V_PolCor_Panel,mode=WhichListItem(popStr, list,";",0,0),popvalue=popStr
			endif
		endfor
	endif
	return(0)
End


// saves the runs+cells for the PolCor Panel, separate from what is saved when the panel is closed
//
// 	fname = "CellDecayPanelSaveState.itx"
//
//
Function V_SavePolCorPanelState()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "PolCorPanelSaveState"
	
	// get a list of the List waves
	listStr=WaveList("ListWave_*",";","")
	num=ItemsInList(listStr,";")
//	print listStr


	// get the full path to the new file name before creating it
	fname = V_DoSaveFileDialog("Save the Pol_Cor Panel State",fname=fname,suffix=".itx")
	If(cmpstr(fname,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	
	
	Open/P=home refnum as fname		// creates a new file, or overwrites the existing file	
	fprintf refNum,"IGOR\r"
			
	// Save each of the list waves, 2D text
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave/T tw = $item
		
		V_Write2DTextWaveToITX(tw,refnum)
		
		fprintf refNum,"\r"		//space between waves
	endfor	

	// get a list of the Selection waves
	listStr=WaveList("lbSelWave_*",";","")
	num=ItemsInList(listStr,";")	
	
	// Save each of the Selection waves, 2D numerical
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item

		V_Write2DWaveToITX(w,refnum)

		fprintf refNum,"\r"	
	endfor	

// save the popState wave
	Wave/T tw=root:Packages:NIST:VSANS:Globals:Polarization:PolCor_popState
	V_Write2DTextWaveToITX(tw,refnum)
	
	Close refnum

	SetDataFolder root:
	return(0)
End

// restores the waves for the cell decay table
//
// 	fname = "PolCorPanelSaveState.itx"
//
//
Function V_RestorePolCorPanelState()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "PolCorPanelSaveState.itx"
	LoadWave/O/T fname
	
	SetDataFolder root:
	
	V_RestorePolCorPanel()		// put the condition popups in the proper state
	
	return(0)
End

//
// TODO:
// X- only re-initialize values if user wants to. maybe ask.
//
Function V_Initialize_PolCorPanel()


	Variable ii,num
	String name,popStr
		
	DoAlert 1,"Do you want to initialize, wiping out all of your entries?"
	if(V_flag != 1)		//1== yes initialize, so everything else, restore the entries
		return(1)			//send back 1 to say yes, restore the saved state
	endif
	
	//initialize all of the strings for the input
	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization
	
	//controls are labeled "name_#_UU_#" where name is the type of control, # is the tab #, and (2nd) # is the control #

/// new method using a listBox for each state	
	Make/O/T/N=2 lbTitles
	lbTitles[0] = "Run #"
	lbTitles[1] = "Cell"
	
	Make/O/N=(10,2) lbSelWave
	lbSelWave[][0] = 2			//Run # column is editable
	lbSelWave[][1] = 1			//Cell name is a popup, not editable
	
	Make/O/T/N=(10,2) ListWave_0_UU=""
	Make/O/T/N=(10,2) ListWave_0_DU=""
	Make/O/T/N=(10,2) ListWave_0_DD=""
	Make/O/T/N=(10,2) ListWave_0_UD=""
	Make/O/N=(10,2) lbSelWave_0_UU
	Make/O/N=(10,2) lbSelWave_0_DU
	Make/O/N=(10,2) lbSelWave_0_DD
	Make/O/N=(10,2) lbSelWave_0_UD
	lbSelWave_0_UU[][0] = 2			//Run # column is editable
	lbSelWave_0_DU[][0] = 2			//Run # column is editable
	lbSelWave_0_DD[][0] = 2			//Run # column is editable
	lbSelWave_0_UD[][0] = 2			//Run # column is editable
	lbSelWave_0_UU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_0_DU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_0_DD[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_0_UD[][1] = 1			//Cell name is a popup, not editable	
	
	Make/O/T/N=(10,2) ListWave_1_UU=""
	Make/O/T/N=(10,2) ListWave_1_DU=""
	Make/O/T/N=(10,2) ListWave_1_DD=""
	Make/O/T/N=(10,2) ListWave_1_UD=""
	Make/O/N=(10,2) lbSelWave_1_UU
	Make/O/N=(10,2) lbSelWave_1_DU
	Make/O/N=(10,2) lbSelWave_1_DD
	Make/O/N=(10,2) lbSelWave_1_UD
	lbSelWave_1_UU[][0] = 2			//Run # column is editable
	lbSelWave_1_DU[][0] = 2			//Run # column is editable
	lbSelWave_1_DD[][0] = 2			//Run # column is editable
	lbSelWave_1_UD[][0] = 2			//Run # column is editable
	lbSelWave_1_UU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_1_DU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_1_DD[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_1_UD[][1] = 1			//Cell name is a popup, not editable		
	
	Make/O/T/N=(10,2) ListWave_2_UU=""
	Make/O/T/N=(10,2) ListWave_2_DU=""
	Make/O/T/N=(10,2) ListWave_2_DD=""
	Make/O/T/N=(10,2) ListWave_2_UD=""
	Make/O/N=(10,2) lbSelWave_2_UU
	Make/O/N=(10,2) lbSelWave_2_DU
	Make/O/N=(10,2) lbSelWave_2_DD
	Make/O/N=(10,2) lbSelWave_2_UD
	lbSelWave_2_UU[][0] = 2			//Run # column is editable
	lbSelWave_2_DU[][0] = 2			//Run # column is editable
	lbSelWave_2_DD[][0] = 2			//Run # column is editable
	lbSelWave_2_UD[][0] = 2			//Run # column is editable
	lbSelWave_2_UU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_2_DU[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_2_DD[][1] = 1			//Cell name is a popup, not editable	
	lbSelWave_2_UD[][1] = 1			//Cell name is a popup, not editable	


////// old method using individual setVars and popups	
//	for(ii=0;ii<5;ii+=1)
//		String/G $("gStr_PolCor_0_UU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_0_DU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_0_DD_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_0_UD_"+num2str(ii)) = "none"
//	endfor
//
//	for(ii=0;ii<5;ii+=1)
//		String/G $("gStr_PolCor_1_UU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_1_DU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_1_DD_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_1_UD_"+num2str(ii)) = "none"
//	endfor
//	
//	for(ii=0;ii<5;ii+=1)
//		String/G $("gStr_PolCor_2_UU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_2_DU_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_2_DD_"+num2str(ii)) = "none"
//		String/G $("gStr_PolCor_2_UD_"+num2str(ii)) = "none"
//	endfor
////////////

	SetDataFolder root:


	return(0)

end


// 		Button button31,pos={sc*260,9*sc},size={sc*110,20*sc},proc=V_ManualRunEntry,title="Manual Entry"
//
// state = 2 = editable, no popup appears
// state = 1 = not editable, yes popup to fill in numbers
Function V_ManualRunEntry(ba) : ButtonControl
	STRUCT WMButtonAction &ba	
	Variable state

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

		// if button is "->Manual" then we are inAuto entry mode, so set state=2
			if(cmpstr(ba.userData, "InAuto")==0)
				state = 2
				Button button31,title="->Popup Entry",userData="InManual"
			else
				state = 1
				Button button31,title="->Manual Entry",userData="InAuto"
			endif
		
			
			SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization


		// SAM tab
			Wave lbSelWave_0_UU,lbSelWave_0_DU,lbSelWave_0_DD,lbSelWave_0_UD
			lbSelWave_0_UU[][0] = state		//Run # column is editable if state = 2, not if = 1
			lbSelWave_0_DU[][0] = state		//Run # column is editable
			lbSelWave_0_DD[][0] = state		//Run # column is editable
			lbSelWave_0_UD[][0] = state		//Run # column is editable
		
		// EMP tab
			Wave lbSelWave_1_UU,lbSelWave_1_DU,lbSelWave_1_DD,lbSelWave_1_UD
			lbSelWave_1_UU[][0] = state		//Run # column is editable if state = 2, not if = 1
			lbSelWave_1_DU[][0] = state		//Run # column is editable
			lbSelWave_1_DD[][0] = state		//Run # column is editable
			lbSelWave_1_UD[][0] = state		//Run # column is editable
		
		// BGD tab (only one listBox)
			Wave lbSelWave_2_UU
			lbSelWave_2_UU[][0] = state		//Run # column is editable if state = 2, not if = 1

			break
		case -1: // control being killed
			break
	endswitch



	SetDataFolder root:
	return(0)
End


// controls are labeled "name_#_UU_#" where name is the type of control, # is the tab #, and (2nd) # is the control #
// -- this will allow for future use of tabs. right now 0 will be the "SAM" data
//
// - always visible controls will have no "_" characters
// 
// TODO:
// X- tabs for SAM, EMP, and BGD
// X- input fields for the other protocol items, like the Protocol Panel
// X- save the popup state
// X- need a way of saving the "protocol" since the setup is so complex.
// - generate a report of the setup.
// X- 4-panel display (maybe a layout with labels?) Maybe a panel with 4 subwindows. Can I use color bars in them?
//
//
Window V_PolCor_Panel()
	Variable sc=1
	
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(300*sc,44*sc,1036*sc,524*sc) /K=1 as "Polarization Correction"
	ModifyPanel cbRGB=(64349,63913,44660)
//	ShowTools/A
	SetDrawEnv linethick= 2.00
	DrawLine 11,427,696,427

	TabControl PolCorTab,pos={sc*15,20*sc},size={sc*515,360*sc},proc=V_PolCorTabProc
	TabControl PolCorTab,tabLabel(0)="SAM",tabLabel(1)="EMP",tabLabel(2)="BGD"
	TabControl PolCorTab,value= 0
	
	// always visible
	Button button0,pos={sc*23,396*sc},size={sc*80,20*sc},proc=V_LoadRawPolarizedButton,title="Load ..."
	Button button1,pos={sc*136,396*sc},size={sc*130,20*sc},proc=V_PolCorButton,title="Pol Correct Data"
	Button button2,pos={sc*546,92*sc},size={sc*130,20*sc},proc=V_ShowPolMatrixButton,title="Show Coef Matrix"
	Button button3,pos={sc*546,151*sc},size={sc*160,20*sc},proc=V_ChangeDisplayedPolData,title="Change Display Data"
	Button button4,pos={sc*503,9*sc},size={sc*30,20*sc},proc=V_PolCorHelpParButtonProc,title="?"
	Button button12,pos={sc*546,121*sc},size={sc*120,20*sc},proc=V_Display4XSButton,title="Display 4 XS"
	Button button13,pos={sc*360,9*sc},size={sc*110,20*sc},proc=V_ClearPolCorEntries,title="Clear Entries"

	Button button31,pos={sc*220,9*sc},size={sc*130,20*sc},proc=V_ManualRunEntry,title="->Popup Entry",userData="InManual"



	TitleBox title0,pos={sc*100,48*sc},size={sc*24,24*sc},title="\\f01UU or + +",fSize=12
	TitleBox title1,pos={sc*380,48*sc},size={sc*24,24*sc},title="\\f01DU or - +",fSize=12
	TitleBox title2,pos={sc*100,210*sc},size={sc*25,24*sc},title="\\f01DD or - -",fSize=12
	TitleBox title3,pos={sc*380,210*sc},size={sc*24,24*sc},title="\\f01UD or + -",fSize=12


	// bits to set up reduction protocol
	//
	// now use the main protocol panel rather than trying to duplicate it here
	//
	Button button21,pos={sc*500,396*sc},size={sc*160,20*sc},proc=V_BuildProtocol_PolCorButtonProc,title="Build Protocol"
	Button button21,help={"Build a PolCor protocol using the standard Protocol Panel"}

	Button button9,pos={sc*500,435*sc},size={sc*160,20*sc},proc=V_ReducePolCorDataButton,title="Reduce Polarized Data"
	Button button9,help={"Reduce PolCor data"}


//	PopupMenu popup5,pos={sc*129,458*sc},size={sc*51,23*sc},proc=V_DIVFilePopMenuProc,title="set DIV file"
//	PopupMenu popup5,mode=1,value= #"V_getDIVList()"
//
//	PopupMenu popup6,pos={sc*129,482*sc},size={sc*51,23*sc},proc=V_MSKFilePopMenuProc,title="set MASK file"
//	PopupMenu popup6,mode=1,value= #"V_getMSKList()"
//	
//	Button button7,pos={sc*129,506*sc},size={sc*110,20*sc},proc=V_SetABSParamsButton,title="set ABS params"
//	Button button7,help={"This button will prompt the user for absolute scaling parameters"}
//	
//	Button button8,pos={sc*129,530*sc},size={sc*150,20*sc},proc=V_SetAverageParamsButtonProc,title="set AVERAGE params"
//	Button button8,help={"Prompts the user for the type of 1-D averaging to perform, as well as saving options"}
//	Button button10,pos={sc*581,460*sc},size={sc*120,20*sc},proc=V_SavePolCorProtocolButton,title="Save Protocol"
//	Button button10,help={"Save the PolCor protocol, within this experiment only"}
//	Button button11,pos={sc*546,333*sc},size={sc*120,20*sc},proc=V_RecallPolCorProtocolButton,title="Recall Protocol"
//	Button button11,help={"Recall a PolCor protocol from memory"}
//	Button button14,pos={sc*546,303*sc},size={sc*120,20*sc},proc=V_ExportPolCorProtocolButton,title="Export Protocol"
//	Button button14,help={"Export the PolCor protocol, saving it on disk"}
//	Button button15,pos={sc*546,363*sc},size={sc*120,20*sc},proc=V_ImportPolCorProtocolButton,title="Import Protocol"
//	Button button15,help={"Import a PolCor protocol from a protocol previously saved to disk"}
//	Button button16,pos={sc*546,216*sc},size={sc*110,20*sc},proc=V_SavePolCorPanelButton,title="Save State"
//	Button button16,help={"Save the state of the panel for later recall"}
//	Button button17,pos={sc*546,245*sc},size={sc*110,20*sc},proc=V_RestorePolCorPanelButton,title="Restore State"
//	Button button17,help={"Recall a saved state of the Pol_Cor panel"}


			
//	SetVariable setvar0,pos={sc*303,458*sc},size={sc*250,15*sc},title="file:"
//	SetVariable setvar0,help={"Filename of the detector sensitivity file to be used in the data reduction"}
//	SetVariable setvar0,limits={-inf,inf,0*sc},value= root:Packages:NIST:VSANS:Globals:Protocols:gDIV
//	SetVariable setvar1,pos={sc*303,483*sc},size={sc*250,15*sc},title="file:"
//	SetVariable setvar1,help={"Filename of the mask file to be used in the data reduction"}
//	SetVariable setvar1,limits={-inf,inf,0*sc},value= root:Packages:NIST:VSANS:Globals:Protocols:gMASK
//	SetVariable setvar2,pos={sc*303,509*sc},size={sc*250,15*sc},title="parameters:"
//	SetVariable setvar2,help={"Keyword-string of values necessary for absolute scaling of data. Remaining parameters are taken from the sample file."}
//	SetVariable setvar2,limits={-inf,inf,0*sc},value= root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
//	SetVariable setvar3,pos={sc*303,535*sc},size={sc*250,15*sc},title="parameters:"
//	SetVariable setvar3,help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
//	SetVariable setvar3,limits={-inf,inf,0*sc},value= root:Packages:NIST:VSANS:Globals:Protocols:gAVE
	
//	CheckBox check0,pos={sc*13,463*sc},size={sc*63,14*sc},title="Sensitivity"
//	CheckBox check0,help={"If checked, the specified detector sensitivity file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
//	CheckBox check0,value= 1
//	CheckBox check1,pos={sc*13,486*sc},size={sc*39,14*sc},title="Mask",value= 1
//	CheckBox check2,pos={sc*13,509*sc},size={sc*82,14*sc},title="Absolute Scale",value= 1
//	CheckBox check3,pos={sc*13,532*sc},size={sc*96,14*sc},title="Average and Save",value= 1
//	CheckBox check4,pos={sc*13,436*sc},size={sc*59,14*sc},title="Use EMP?",value= 1
//	CheckBox check5,pos={sc*103,436*sc},size={sc*60,14*sc},title="Use BGD?",value= 1
	

// SAM Tab	
	PopupMenu popup_0_1,pos={sc*190,45*sc},size={sc*102,20*sc},title="Condition"
	PopupMenu popup_0_1, mode=1,popvalue="none",value= #"V_P_GetConditionNameList()"
	// UU
	ListBox ListBox_0_UU,pos={sc*34,80*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_UU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_0_UU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_0_UU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_0_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

	// DU
	ListBox ListBox_0_DU,pos={sc*310,80*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_DU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_0_DU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_0_DU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_0_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// DD
	ListBox ListBox_0_DD,pos={sc*33,245*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_DD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_0_DD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_0_DD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_0_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
	
// UD
	ListBox ListBox_0_UD,pos={sc*310,245*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_UD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_0_UD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_0_UD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_0_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2


// EMP Tab
	PopupMenu popup_1_1,pos={sc*190,45*sc},size={sc*102,20*sc},title="Condition"
	PopupMenu popup_1_1, mode=1,popvalue="none",value= #"V_P_GetConditionNameList()"	
	// UU
	ListBox ListBox_1_UU,pos={sc*34,80*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_UU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_1_UU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_1_UU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_1_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

	// DU
	ListBox ListBox_1_DU,pos={sc*310,80*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_DU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_1_DU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_1_DU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_1_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// DD
	ListBox ListBox_1_DD,pos={sc*33,245*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_DD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_1_DD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_1_DD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_1_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// UD
	ListBox ListBox_1_UD,pos={sc*310,245*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_UD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_1_UD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_1_UD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_1_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// TODO
// BKG Tab -- DU, DD, UD are not shown, since the background is not dependent on the flipper states, so only one background
// file is necessary - this is "incorrectly" labeled as UU. I'll get around to changing this in the future...
//
	TitleBox title_2_UU,pos={sc*250,100*sc},size={sc*400,48*sc},title="\\f01BGD files are independent\r of polarization\rEnter all as UU",fSize=12


	// UU
	ListBox ListBox_2_UU,pos={sc*34,80*sc},size={sc*200,120*sc},proc=V_PolCor_FileListBoxProc,frame=2
	ListBox ListBox_2_UU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_2_UU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
	ListBox ListBox_2_UU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_2_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

	// DU
////////	ListBox ListBox_2_DU,pos={sc*368,102*sc},size={sc*200,130*sc},proc=V_PolCor_FileListBoxProc,frame=2
////////	ListBox ListBox_2_DU,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_2_DU,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
////////	ListBox ListBox_2_DU,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_2_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// DD
////////	ListBox ListBox_2_DD,pos={sc*33,286*sc},size={sc*200,130*sc},proc=V_PolCor_FileListBoxProc,frame=2
////////	ListBox ListBox_2_DD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_2_DD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
////////	ListBox ListBox_2_DD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_2_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2

// UD
////////	ListBox ListBox_2_UD,pos={sc*368,286*sc},size={sc*200,130*sc},proc=V_PolCor_FileListBoxProc,frame=2
////////	ListBox ListBox_2_UD,listWave=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_2_UD,titleWave=root:Packages:NIST:VSANS:Globals:Polarization:lbTitles
////////	ListBox ListBox_2_UD,selWave=root:Packages:NIST:VSANS:Globals:Polarization:lbSelWave_2_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2

EndMacro

Function V_SavePolCorPanelButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_SavePolCorPanelState()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_RestorePolCorPanelButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_RestorePolCorPanelState()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// action procedure for the list box that allows the popup menu
// -- much easier to make a contextual popup with a list box than on a table/subwindow hook
//
Function V_PolCor_FileListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	
	String intent,flipStr,boxType
	Variable selTab
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
		
//			Print lba.ctrlName
//			Print lba.col		//selection column
//			WAVE/T lba.listWave		// list wave specified by listBox
			boxType = NameOfWave(lba.listWave)
			ControlInfo PolCorTab
			selTab = V_Value

			if (lba.col == 0)											// file list
				// which tab are we on?
				if(selTab==0)
					intent="Sample"
				elseif(selTab==1)
					intent="Empty Cell"
					else
					intent="Blocked Beam"
				endif
				// what is the flip state? ListWave_x_FF
				flipStr = boxType[11,12]
				Print flipStr
				flipStr = "S_"+flipStr
				

				PopupContextualMenu V_ListForCorrectionPanel(flipStr,intent)
				if (V_flag > 0)
					listWave[lba.row][lba.col] = S_Selection
				endif
			endif		
			
			if (lba.col == 1)											// cell list
//				SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
//				SelWave[][s.col][0] = SelWave[p][s.col] | 1				// select all rows
//				ControlUpdate/W=$(s.win) $(s.ctrlName)
				PopupContextualMenu V_D_CellNameList()
				if (V_flag > 0)
					listWave[lba.row][lba.col] = S_Selection
				endif
			endif
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


// This hook is activated when the whole window is killed. It saves the state of the popups and list boxes.
// -- the protocol is not saved since it can be recalled
//
Function V_PolCorPanelHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	switch(s.eventCode)
//		case 0:				// Activate
//			// Handle activate
//			break
//
//		case 1:				// Deactivate
//			// Handle deactivate
//			break
		case 2:				// kill
			// Handle kill
			
			// the variables with the run numbers are automatically saved and restored if not re-initialized
			// get a list of all of the popups
			String popList="",item
			Variable num,ii

//		-- old way, with popups for the conditions
//			popList=ControlNameList("PolCor_Panel",";","popup_*")
//		-- new way - list boxes automatically saved, condition popup needs to be saved
			popList=ControlNameList("V_PolCor_Panel",";","popup*")
			num=ItemsInList(popList,";")
			Make/O/T/N=(num,2) root:Packages:NIST:VSANS:Globals:Polarization:PolCor_popState
			Wave/T w=root:Packages:NIST:VSANS:Globals:Polarization:PolCor_popState
			for(ii=0;ii<num;ii+=1)
				item=StringFromList(ii, popList,";")
				ControlInfo/W=V_PolCor_Panel $item
				w[ii][0] = item
				w[ii][1] = S_Value
			endfor

			break

	endswitch

	return hookResult		// 0 if nothing done, else 1
End

// val = 1 to disable
// val = 0 to show
Function V_ToggleSelControls(str,val)
	String str
	Variable val
	
	String listStr
	listStr = ControlNameList("V_PolCor_Panel", ";", "*"+str+"*")
//	print listStr
	
	ModifyControlList/Z listStr  , disable=(val)
	return(0)
end


Function V_PolCorTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab		
			Variable val
//			Print "Selected tab = ",tab
			
			val = (tab != 0)
//			Print "tab 0 val = ",val
			V_ToggleSelControls("_0_",val)
			
			val = (tab != 1)
//			Print "tab 1 val = ",val
			V_ToggleSelControls("_1_",val)
			
			val = (tab != 2)
//			Print "tab 2 val = ",val
			V_ToggleSelControls("_2_",val)
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// 0 = SAM, 1 = EMP, 2 = BGD
Function V_ChangeDataTab(tab)
	Variable tab
	Variable val
	
	TabControl PolCorTab win=V_PolCor_Panel,value=tab
	
	// as if the tab was clicked
	val = (tab != 0)
//			Print "tab 0 val = ",val
	V_ToggleSelControls("_0_",val)
	
	val = (tab != 1)
//			Print "tab 1 val = ",val
	V_ToggleSelControls("_1_",val)
	
	val = (tab != 2)
//			Print "tab 2 val = ",val
	V_ToggleSelControls("_2_",val)

	return(0)			
End

Function V_PolCorHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Polarization Correction Panel"
			if(V_flag !=0)
				DoAlert 0,"The Polarization Correction Panel Help file could not be found"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// loads the specified type of data (SAM, EMP, BGD) based on the active tab
// loads either specified spin type or all four
//
//  -- during loading, the proper row of the PolMatrix is filled, based on pType
//
// then after all data is loaded:
// 		-the inverse Inv_PolMatrix is calculated
//		-the error in the PolMatrix is calculated
//		-the error in Inv_PolMatrix is calculated
//
// TODO:
// (( now, defaults to trying to load ALL four data spin states ))
// 		- I'll have to fix this later if only 2 of the four are needed
//
Function V_LoadRawPolarizedButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// depends on which tab you're on
			// (maybe) select UD type, maybe force all to load
			
			String pType
//			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;All;"
//			DoPrompt "Type to load",pType
//			if (V_Flag)
//				return 0									// user canceled
//			endif

			pType = "All"
			
			if(cmpstr(pType,"All") == 0)
				V_LoadPolarizedData("UU")
				V_LoadPolarizedData("DU")
				V_LoadPolarizedData("DD")
				V_LoadPolarizedData("UD")
			else
				V_LoadPolarizedData(pType)
			endif
			
			String type
			Variable row,col,flag=1
			Variable ii,jj,aa,bb
			
// The PolMatrix is filled on loading the data sets
// once all files are added, take the SQRT of the error matrix
// now calculate its inverse
// -- first checking to be sure that no rows are zero - this will result in a singular matrix otherwise		
			ControlInfo/W=V_PolCor_Panel PolCorTab
			type = S_value
			WAVE matA = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")
			WAVE matA_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix_err")
			matA_err = sqrt(matA_err)
			
			// check for zero rows before inverting -- means not all data loaded
			for(row=0;row<4;row+=1)
				if(matA[row][0] == 0 && matA[row][1] == 0 && matA[row][2] == 0 && matA[row][3] == 0)
					Print "**** some elements of PolMatrix are zero. Inverse not calculated. Be sure that all four XS are loaded."
					row=10
					flag=0
				endif
			endfor
			if(flag)		//PolMatrix OK
				// calculate the inverse of the coefficient matrix
//				SetDataFolder $("root:Packages:NIST:VSANS:Globals:")
				MatrixInverse/G matA
				Duplicate/O M_Inverse $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix")
				Wave Inv_PolMatrix = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix")
				
				// now calculate the error of the inverse matrix
				Duplicate/O Inv_PolMatrix $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix_err")
				Wave Inv_PolMatrix_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix_err")

				Inv_PolMatrix_err=0
				
				for(aa=0;aa<4;aa+=1)
					for(bb=0;bb<4;bb+=1)
						for(ii=0;ii<4;ii+=1)
							for(jj=0;jj<4;jj+=1)
								Inv_PolMatrix_err[aa][bb] += (Inv_PolMatrix[aa][ii])^2 * (matA_err[ii][jj])^2 * (Inv_PolMatrix[jj][bb])^2
							endfor
						endfor
//						Inv_PolMatrix_err[aa][bb] = sqrt(Inv_PolMatrix_err[aa][bb])
					endfor
				endfor
				
				Inv_PolMatrix_err = sqrt(Inv_PolMatrix_err)
				
			endif
	
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// Loading of the polarized scattering data
//
// with the file numbers set
// and the conditions specified
//
// -- For the specified pType of data (=UU, DU, DD, UD)
//
// -the time midpoint is found from the list of runs (needed for PCell(t) later)
// -raw data is loaded (from a list of run numbers)
// -data and loaded waves are tagged with a suffix (_UU, _DU, etc.)
// -the PolMatrix of coefficients is filled (the specified row) (in Globals: SAM_PolMatrix, EMP_PolMatrix, etc.
//
// *** IF THE DATA IS BGD ***
// take the file list from UU every time, but load and put this in all 4 XS locations
//  *************************
//
// TODO:
// X- pre-parsing is not done to check for valid file numbers. This should be done gracefully.
// X- SAM folder is currently hard-wired
// X- if all of the conditions are "none" - stop and report the error
//
Function V_LoadPolarizedData(pType)
	String pType


	String listStr="",runList="",parsedRuns,condStr
	Variable ii,num,err,row
			
	// get the current tab
	String type,runStr,cellStr
	Variable tabNum
	ControlInfo/W=V_PolCor_Panel PolCorTab
	type = S_value
	Print "selected data type = ",type
	tabNum = V_Value
	
	
	// get a list of the file numbers to load, must be in proper data folder
	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization
//			Print "Searching  "+"gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*"
//	listStr = StringList("gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*", ";" )

////////////
	if(tabNum == 2)		//BGD data, read from UU every time, but don't change the pType tag
		Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+"UU")
	else
		Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+pType)
	endif
	num = DimSize(lb,0)		//should be 10, as initialized
	
	// pick the condition, based on the tabNum
	// == 0 = sam
	// == 1 = emp
	// == 2 = bgd, which requires no condition, so use the emp condition...
	//
	if(tabNum==0 || tabNum==1)
		ControlInfo/W=V_PolCor_Panel $("popup_"+num2str(tabNum)+"_1")
	else
		ControlInfo/W=V_PolCor_Panel $("popup_"+num2str(1)+"_1")		//use the condition of the empty tab
	endif
	condStr = S_Value
	Print "Using condition ",condStr," for ",type
	if(cmpstr(condStr, "none" ) == 0)
		DoAlert 0,"Condition is not set."
		SetDataFolder root:
		return(0)
	endif
	
//			step through, stop at the first null run number or missing cell specification
	for(row=0;row<num;row+=1)
		runStr = lb[row][0]
		CellStr = lb[row][1]
		
		if(strlen(runStr) > 0 && strlen(cellStr) > 0)			//non-null entries, go on
			runList += runStr+","		// this is a comma-delimited list
		else
			if(strlen(runStr) == 0 && strlen(cellStr) == 0)
				// not a problem, don't bother reporting
			else
				//report the error and stop
				DoAlert 0,"run number or cell is not set in row "+num2str(row)+" for type "+pType
				SetDataFolder root:
				return(0)
			endif
		endif
	endfor

	Print runList
	// check for errors
	parsedRuns = V_ParseRunNumberList(runlist)
	if(strlen(parsedRuns) == 0)
		Print "enter a valid file number before proceeding"
		SetDataFolder root:
		return(0)
	endif
	SetDataFolder root:

	
	// find time midpoint for the files to load
	Variable tMid
	tMid = V_getTimeMidpoint(runList)
	Print/D "time midpoint",tmid
	
	// this adds multiple raw data files, as specified by the list
	err = V_AddFilesInList(type,parsedRuns)		// adds to a work file = type, not RAW
	V_UpdateDisplayInformation(type)
	
	V_TagLoadedData(type,pType)		//see also DisplayTaggedData()
	
	// now add the appropriate bits to the matrix
	if(!WaveExists($("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")))
		Make/O/D/N=(4,4) $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")
	endif
	if(!WaveExists($("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix_err")))
		Make/O/D/N=(4,4) $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix_err")
	endif
	WAVE matA = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")
	WAVE matA_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix_err")

//			listStr = ControlNameList("PolCor_Panel",";","*"+pType+"*")

	//This loops over all of the files and adds the coefficients to the PolMatrix
	// the PolMatrix rows are cleared on pass 0 as each pType data is loaded.
	// this way repeated loading will always result in the correct fill
	// returns the error matrix as the squared error (take sqrt in calling function)		
	V_AddToPolMatrix(matA,matA_err,pType,tMid)


// be sure the flag for polarization correction is cleared (killed)
	// $("root:Packages:NIST:VSANS:"+type+"_UU:PolCorDone")
	// check for their existence first to avoid errors (even though /Z) ???	
	if(DataFolderExists("root:Packages:NIST:VSANS:"+type+"_UU"))
		KillWaves/Z $("root:Packages:NIST:VSANS:"+type+"_UU:PolCorDone")
	endif
	if(DataFolderExists("root:Packages:NIST:VSANS:"+type+"_DU"))
		KillWaves/Z $("root:Packages:NIST:VSANS:"+type+"_DU:PolCorDone")
	endif
	if(DataFolderExists("root:Packages:NIST:VSANS:"+type+"_DD"))
		KillWaves/Z $("root:Packages:NIST:VSANS:"+type+"_DD:PolCorDone")
	endif
	if(DataFolderExists("root:Packages:NIST:VSANS:"+type+"_UD"))
		KillWaves/Z $("root:Packages:NIST:VSANS:"+type+"_UD:PolCorDone")
	endif

	SetDataFolder root:
	
	return(0)
End


// by definition-- the rows are:
//
//	UU = 0
//	DU = 1
//	DD = 2
//	UD = 3
//
//
// TODO:
// -- check all of the math
// -- not yet using the midpoint time, even though it is passed in (?)
//		exactly where in the math would I use the time midpoint? The midpoint passed in is the 
//    midpoint of all of the files in the list. Individual contributions to the matrix are here
//    calculated at the (start) time of each file. So is a midpoint really necessary?
//
// -- the PolMatrix_err returned from here is the squared error!
//
Function V_AddToPolMatrix(matA,matA_err,pType,tMid)
	Wave matA,matA_err
	String pType
	Variable tMid
	
	Variable row,Psm, PsmPf, PCell,err_Psm, err_PsmPf, err_PCell
	Variable ii,jj,muPo,err_muPo,gam,err_gam,monCts,t1,num,fileCount
	Variable Po,err_Po,Pt,err_Pt,Tmaj,Tmin,err_Tmaj,err_Tmin,Te,err_Te,mu,err_mu,summedMonCts

	Variable ea_uu, ea_ud, ea_dd, ea_du
	Variable ec_uu, ec_ud, ec_dd, ec_du
	
	String listStr,fname="",condStr,condNote,decayNote,cellStr,t0Str,t1Str,runStr

	// get the current tab
	String type
	Variable tabNum
	ControlInfo/W=V_PolCor_Panel PolCorTab
	type = S_value
	Print "selected data type = ",type
	tabNum = V_Value
	
	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization
//	listStr = StringList("gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*", ";" )

////////////
	if(tabNum == 2)		//BGD data, read from UU every time, but don't change the pType tag
		Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+"UU")
	else
		Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+pType)
	endif
	num = DimSize(lb,0)		//should be 10, as initialized
	
	// if the condition (for all of the sets) is "none", get out
	if(tabNum==0 || tabNum==1)
		ControlInfo/W=V_PolCor_Panel $("popup_"+num2str(tabNum)+"_1")
	else
		ControlInfo/W=V_PolCor_Panel $("popup_"+num2str(1)+"_1")		//use the condition of the empty tab
	endif
	condStr = S_Value
//	Print "Using condition ",condStr," for ",type

	if(cmpstr(condStr, "none" ) == 0)
		DoAlert 0,"Condition is not set."
		SetDataFolder root:
		return(0)
	endif
	
	Wave condition = $("root:Packages:NIST:VSANS:Globals:Polarization:Cells:"+condStr)
	// get wave note from condition
	condNote = note(condition)
	// get P's from note
	Psm = NumberByKey("P_sm", condNote, "=", ",", 0)
	PsmPf = NumberByKey("P_sm_f", condNote, "=", ",", 0)
	err_Psm = NumberByKey("err_P_sm", condNote, "=", ",", 0)
	err_PsmPf = NumberByKey("err_P_sm_f", condNote, "=", ",", 0)

//
//
//		find the proper propotions to add the matrix contributions
//		if only one file, this = 1, otherwise it should sum to one
//
	Make/O/D/N=10 proportion
	proportion = 0
	summedMonCts = 0
	// loop over the (10) rows in the listWave
	for(ii=0;ii<num;ii+=1)
		runStr = 	lb[ii][0]		//the run number
		if(cmpstr(runStr, "" ) != 0)
			fname = V_FindFileFromRunNumber(str2num(runStr))
			proportion[ii] = V_getBeamMonNormData(fname)		//
			summedMonCts += proportion[ii]
		endif
	endfor
	proportion /= summedMonCts

	// loop over the (10) rows in the listWave
	fileCount=0
	for(ii=0;ii<num;ii+=1)
		runStr = 	lb[ii][0]		//the run number
		if(cmpstr(runStr, "" ) != 0)
		
			fileCount += 1		//one more file is added
			// get run number (str)
			// get file name
			fname = V_FindFileFromRunNumber(str2num(runStr))
		
			// get the cell string to get the Decay wave
			cellStr = lb[ii][1]
//			print "Cell = ",cellStr
			// get info to calc Pcell (from the Decay wave)
			Wave decay = $("root:Packages:NIST:VSANS:Globals:Polarization:Cells:Decay_"+cellStr)	
			decayNote=note(decay)
		
			t0Str = StringByKey("T0", decayNote, "=", ",", 0)
			muPo = NumberByKey("muP", decayNote, "=", ",", 0)
			err_muPo = NumberByKey("err_muP", decayNote, "=", ",", 0)
			gam = NumberByKey("gamma", decayNote, "=", ",", 0)
			err_gam = NumberByKey("err_gamma", decayNote, "=", ",", 0)
			Po = NumberByKey("P0", decayNote, "=", ",", 0)
			err_Po = NumberByKey("err_P0", decayNote, "=", ",", 0)
			// get the elapsed time to calculate PCell at the current file time
			t1str = V_getDataStartTime(fname)		//
			t1 = V_ElapsedHours(t0Str,t1Str)
			
			PCell = V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell)
			

			
			SVAR cellParamStr = $("root:Packages:NIST:VSANS:Globals:Polarization:Cells:gCell_"+cellStr)
			
			Pt = V_Calc_PHe_atT(Po,err_Po,gam,err_gam,t1,err_Pt)
			
			Tmaj = V_Calc_Tmaj(cellParamStr,Pt,err_Pt,err_Tmaj)
			Tmin = V_Calc_Tmin(cellParamStr,Pt,err_Pt,err_Tmin)

//			printf "File: %s\r",fname
//			printf "Elapsed time = %g hours\r",t1
//			printf "Pcell = %g\tTMaj = %g\tTmin = %g\r",PCell,(1+PCell)/2,(1-Pcell)/2
//			printf "\t\tRecalculated TMaj = %g\tTmin = %g\r",Tmaj,Tmin
						
			// get file info (monitor counts)
//			monCts = getMonitorCount(fname)
//			monCts /= 1e8		//to get a normalized value to add proportionally
			
			// use the proper proportion of each file to add to each row
//			monCts = proportion[ii]
			
			Variable err_monCts
			err_monCts = sqrt(monCts)
			// add appropriate values to matrix elements (switch on UU, DD, etc)
			// error in monCts is a negligible contribution
			strswitch(pType)
				case "UU":		
					row = 0
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
// original version
//					ea_uu = (1+Psm)/2
//					ea_du = (1-Psm)/2
//					ec_uu = (1+Pcell)/2
//					ec_du = (1-Pcell)/2
//					
//					matA[row][0] += ea_uu*ec_uu*monCts
//					matA[row][1] += ea_du*ec_uu*monCts
//					matA[row][2] += ea_du*ec_du*monCts
//					matA[row][3] += ea_uu*ec_du*monCts
//
//					matA_err[row][0] += (ea_uu*ec_uu*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][1] += (ea_du*ec_uu*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][2] += (ea_du*ec_du*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][3] += (ea_uu*ec_du*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
// end original version

// using Tmaj, Tmin calc from Po, not Pcell					
					matA[row][0] += (1+Psm)*Tmaj*proportion[ii]
					matA[row][1] += (1-Psm)*Tmaj*proportion[ii]
					matA[row][2] += (1-Psm)*Tmin*proportion[ii]
					matA[row][3] += (1+Psm)*Tmin*proportion[ii]

// this seems to be too large... do I need to add the errors in proportion too? squared?
					matA_err[row][0] += proportion[ii]*( (Tmaj)^2*err_Psm^2 + (1+Psm)^2*err_Tmaj^2 )
					matA_err[row][1] += proportion[ii]*( (Tmaj)^2*err_Psm^2 + (1-Psm)^2*err_Tmaj^2 )
					matA_err[row][2] += proportion[ii]*( (Tmin)^2*err_Psm^2 + (1-Psm)^2*err_Tmin^2 )
					matA_err[row][3] += proportion[ii]*( (Tmin)^2*err_Psm^2 + (1+Psm)^2*err_Tmin^2 )
						
					break
				case "DU":		
					row = 1
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
// original version
//					ea_ud = (1-PsmPf)/2
//					ea_dd = (1+PsmPf)/2
//					ec_uu = (1+Pcell)/2
//					ec_du = (1-Pcell)/2
//					
//					matA[row][0] += ea_ud*ec_uu*monCts
//					matA[row][1] += ea_dd*ec_uu*monCts
//					matA[row][2] += ea_dd*ec_du*monCts
//					matA[row][3] += ea_ud*ec_du*monCts
//					
//					matA_err[row][0] += (ea_ud*ec_uu*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][1] += (ea_dd*ec_uu*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][2] += (ea_dd*ec_du*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][3] += (ea_ud*ec_du*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
// original version

// using Tmaj, Tmin calc from Po, not Pcell					
					matA[row][0] += (1-PsmPf)*Tmaj*proportion[ii]
					matA[row][1] += (1+PsmPf)*Tmaj*proportion[ii]
					matA[row][2] += (1+PsmPf)*Tmin*proportion[ii]
					matA[row][3] += (1-PsmPf)*Tmin*proportion[ii]

// this seems to be too large... do I need to add the errors in proportion too? squared?
					matA_err[row][0] += proportion[ii]*( (Tmaj)^2*err_PsmPf^2 + (1-PsmPf)^2*err_Tmaj^2 )
					matA_err[row][1] += proportion[ii]*( (Tmaj)^2*err_PsmPf^2 + (1+PsmPf)^2*err_Tmaj^2 )
					matA_err[row][2] += proportion[ii]*( (Tmin)^2*err_PsmPf^2 + (1+PsmPf)^2*err_Tmin^2 ) 
					matA_err[row][3] += proportion[ii]*( (Tmin)^2*err_PsmPf^2 + (1-PsmPf)^2*err_Tmin^2 )


					break	
				case "DD":		
					row = 2
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
// original version
//					ea_ud = (1-PsmPf)/2
//					ea_dd = (1+PsmPf)/2
//					ec_ud = (1-Pcell)/2
//					ec_dd = (1+Pcell)/2
//					
//					matA[row][0] += ea_ud*ec_ud*monCts
//					matA[row][1] += ea_dd*ec_ud*monCts
//					matA[row][2] += ea_dd*ec_dd*monCts
//					matA[row][3] += ea_ud*ec_dd*monCts					
//
//					matA_err[row][0] += (ea_ud*ec_ud*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][1] += (ea_dd*ec_ud*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][2] += (ea_dd*ec_dd*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][3] += (ea_ud*ec_dd*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
// original version

// using Tmaj, Tmin calc from Po, not Pcell					
					matA[row][0] += (1-PsmPf)*Tmin*proportion[ii]
					matA[row][1] += (1+PsmPf)*Tmin*proportion[ii]
					matA[row][2] += (1+PsmPf)*Tmaj*proportion[ii]
					matA[row][3] += (1-PsmPf)*Tmaj*proportion[ii]

// this seems to be too large... do I need to add the errors in proportion too? squared?
					matA_err[row][0] += proportion[ii]*( (Tmin)^2*err_PsmPf^2 + (1-PsmPf)^2*err_Tmin^2 )
					matA_err[row][1] += proportion[ii]*( (Tmin)^2*err_PsmPf^2 + (1+PsmPf)^2*err_Tmin^2 )
					matA_err[row][2] += proportion[ii]*( (Tmaj)^2*err_PsmPf^2 + (1+PsmPf)^2*err_Tmaj^2 )
					matA_err[row][3] += proportion[ii]*( (Tmaj)^2*err_PsmPf^2 + (1-PsmPf)^2*err_Tmaj^2 )
										
					break						
				case "UD":		
					row = 3
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
// original version
//					ea_uu = (1+Psm)/2
//					ea_du = (1-Psm)/2
//					ec_ud = (1-Pcell)/2
//					ec_dd = (1+Pcell)/2
//					
//					matA[row][0] += ea_uu*ec_ud*monCts
//					matA[row][1] += ea_du*ec_ud*monCts
//					matA[row][2] += ea_du*ec_dd*monCts
//					matA[row][3] += ea_uu*ec_dd*monCts					
//										
//					matA_err[row][0] += (ea_uu*ec_ud*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][1] += (ea_du*ec_ud*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][2] += (ea_du*ec_dd*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
//					matA_err[row][3] += (ea_uu*ec_dd*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
// original version
	
// using Tmaj, Tmin calc from Po, not Pcell					
					matA[row][0] += (1+Psm)*Tmin*proportion[ii]
					matA[row][1] += (1-Psm)*Tmin*proportion[ii]
					matA[row][2] += (1-Psm)*Tmaj*proportion[ii]
					matA[row][3] += (1+Psm)*Tmaj*proportion[ii]

// this seems to be too large... do I need to add the errors in proportion too? squared?
					matA_err[row][0] += proportion[ii]*( (Tmin)^2*err_Psm^2 + (1+Psm)^2*err_Tmin^2 )
					matA_err[row][1] += proportion[ii]*( (Tmin)^2*err_Psm^2 + (1-Psm)^2*err_Tmin^2 )
					matA_err[row][2] += proportion[ii]*( (Tmaj)^2*err_Psm^2 + (1-Psm)^2*err_Tmaj^2 )
					matA_err[row][3] += proportion[ii]*( (Tmaj)^2*err_Psm^2 + (1+Psm)^2*err_Tmaj^2 )
																			
					break
			endswitch

		endif
	endfor
	
// can't take the SQRT here, since the matrix won't necessarily be full yet, 
	
	SetDataFolder root:
	return(0)
End


// duplicate the correct waves for use as the PolCor result
// lots of extra waves, but it makes things easier down the road
// type is the data folder (=SAM, etc)
// pType is the pol extension (=UU, etc.)
//
// an extra "_pc" is tagged on to indicate that the 
// polarization correction has been done
//
Function V_MakePCResultWaves(type,pType)
	String type,pType

	
	ptype = type+ "_" + pType + "_pc"			// add an extra underscore
	
	V_CopyHDFToWorkFolder(type,ptype)

	
	return(0)
End

//
// tag the loaded data with the type (spin states)
// -- for VSANS, do this by duplicating the whole data folder
//
// type is the usual "SAM" or "EMP", etc.
// and ptype is the polarization "UU", etc.
//
// TODO_POL: need to test this out to be sure that the size of the Igor
// experiment does not balloon up too much.
//
//
Function V_TagLoadedData(type,pType)
	String type,pType



	ptype = type+"_" + pType			// add an extra underscore
	
	V_CopyHDFToWorkFolder(type,ptype)

// not sure that I need this at all - since each folder that I duplicate will have its
// own file list
//	
//	SVAR FileList = $(destPath + ":FileList")		//stick the list of files as a wave note. Very inelegant...
//	Note $(destPath + ":textread"+pType),FileList
	
	
	return(0)
End

//
// BUG -- for WM: If I  declare the parameter workType with the name "type", then the function
//    fails at the step of DuplicateDataFolder "name already in use" error. This appears to be stopping
// the duplication at the point where in the /instrument block there is a wave named "type"
// ---so for some odd reason, if there is a matching local variable (somewhere in the stack) that matches
//  the name of an object in the data folder that is being copied, it fails.
//
//
//
// (DONE)
// x- Be sure that fRawWindowHook is picking up all of the correct information - identifying what the 
//    displayed data set really is...
//
// a procedure (easier than a function) to point the current data to the tagged data
Proc V_DisplayTaggedData(workType,pType)
	String workType="SAM",pType="UU"

	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=workType

	V_CopyHDFToWorkFolder(workType+"_"+pType,workType)

	V_UpdateDisplayInformation(workType)

	//update the displayed filename, using FileList in the current data folder
	String/G root:Packages:NIST:VSANS:Globals:gCurDispFile = ("root:Packages:NIST:VSANS:"+workType+":gFileList")
	
End


// this takes the 4 loaded experimental cross sections, and solves for the 
// polarization corrected result.
//
// exp cross sections have _UU extensions
// polCor result has same extesion, _UU
// but now folder is flagged at the top level with a wave PolCorDone that will only exist if the
// correction has been done
//
// error propagation through the inversion follows the paper...
//
Function V_PolCorButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Variable ii,jj,numRows,numCols,row,kk,mm
			
			// get the current tab
			String type,detStr
			Variable tabNum
			ControlInfo/W=V_PolCor_Panel PolCorTab
			type = S_value
			Print "selected data type = ",type
			tabNum = V_Value
			
			// make waves for the result
			// these duplicate the entire data folder and add "_pc" for later use
			// data waves for all detectors have the same name underneath
			
			// Don't do this -- it makes too many folders and the experiment becomes too large
//			V_MakePCResultWaves(type,"UU")
//			V_MakePCResultWaves(type,"DU")
//			V_MakePCResultWaves(type,"DD")
//			V_MakePCResultWaves(type,"UD")
			
			if(exists("root:Packages:NIST:VSANS:"+type+"_UU:PolCorDone") == 0)
			// instead, add a flag in the folders (each of the four) to signify that the polarization
			// correction has been done and to be sure to not do it again
				Make/O/D/N=1 $("root:Packages:NIST:VSANS:"+type+"_UU:PolCorDone")	
				Make/O/D/N=1 $("root:Packages:NIST:VSANS:"+type+"_DU:PolCorDone")	
				Make/O/D/N=1 $("root:Packages:NIST:VSANS:"+type+"_DD:PolCorDone")	
				Make/O/D/N=1 $("root:Packages:NIST:VSANS:"+type+"_UD:PolCorDone")	
			else
				DoAlert 0,"Polarization correction already done, skipping"
				return(0)
			endif

			// Now loop over all of the detector panels
				// in the loop:
				// -- switch to the correct data folder (dont' copy, SetDataFolder)
				// -- declare the waves (OK to re-declare them?)
				// -- duplicate so that I have 
				// -- do the math
				//

			NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
			
			for(mm=0;mm<ItemsInList(ksDetectorListAll);mm+=1)
				detStr = StringFromList(mm, ksDetectorListAll, ";")

				if(cmpstr(detStr,"B") == 0 && gIgnoreDetB)
					// do nothing
				else
					// do everything
					
					// Use the data in "data" since it is always linear in VSANS
					// Store the result in "linear_data"
					// copy the PolCor result back into linear_data so that the whole folder is consistent
					
					// the linear data and its errors, declare and initialize
					//  root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:linear_data			
					//  $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":linear_data")			
					WAVE linear_data_UU_pc = $("root:Packages:NIST:VSANS:"+type+"_UU:entry:instrument:detector_"+detStr+":linear_data")
					WAVE linear_data_DU_pc = $("root:Packages:NIST:VSANS:"+type+"_DU:entry:instrument:detector_"+detStr+":linear_data")
					WAVE linear_data_DD_pc = $("root:Packages:NIST:VSANS:"+type+"_DD:entry:instrument:detector_"+detStr+":linear_data")
					WAVE linear_data_UD_pc = $("root:Packages:NIST:VSANS:"+type+"_UD:entry:instrument:detector_"+detStr+":linear_data")
					WAVE linear_data_error_UU_pc = $("root:Packages:NIST:VSANS:"+type+"_UU:entry:instrument:detector_"+detStr+":linear_data_error")
					WAVE linear_data_error_DU_pc = $("root:Packages:NIST:VSANS:"+type+"_DU:entry:instrument:detector_"+detStr+":linear_data_error")
					WAVE linear_data_error_DD_pc = $("root:Packages:NIST:VSANS:"+type+"_DD:entry:instrument:detector_"+detStr+":linear_data_error")
					WAVE linear_data_error_UD_pc = $("root:Packages:NIST:VSANS:"+type+"_UD:entry:instrument:detector_"+detStr+":linear_data_error")
				
					linear_data_UU_pc = 0
					linear_data_DU_pc = 0
					linear_data_DD_pc = 0
					linear_data_UD_pc = 0
					linear_data_error_UU_pc = 0
					linear_data_error_DU_pc = 0
					linear_data_error_DD_pc = 0
					linear_data_error_UD_pc = 0
				
					// make a temp wave for the experimental data vector
					Make/O/D/N=4 vecB
					WAVE vecB = vecB
			
					// the coefficient matrix and the experimental data
					WAVE matA = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")
			
					//this is the actual data to be corrected (taken from data)
					WAVE linear_data_UU = $("root:Packages:NIST:VSANS:"+type+"_UU:entry:instrument:detector_"+detStr+":data")
					WAVE linear_data_DU = $("root:Packages:NIST:VSANS:"+type+"_DU:entry:instrument:detector_"+detStr+":data")
					WAVE linear_data_DD = $("root:Packages:NIST:VSANS:"+type+"_DD:entry:instrument:detector_"+detStr+":data")
					WAVE linear_data_UD = $("root:Packages:NIST:VSANS:"+type+"_UD:entry:instrument:detector_"+detStr+":data")
					WAVE linear_data_error_UU = $("root:Packages:NIST:VSANS:"+type+"_UU:entry:instrument:detector_"+detStr+":data_error")
					WAVE linear_data_error_DU = $("root:Packages:NIST:VSANS:"+type+"_DU:entry:instrument:detector_"+detStr+":data_error")
					WAVE linear_data_error_DD = $("root:Packages:NIST:VSANS:"+type+"_DD:entry:instrument:detector_"+detStr+":data_error")
					WAVE linear_data_error_UD = $("root:Packages:NIST:VSANS:"+type+"_UD:entry:instrument:detector_"+detStr+":data_error")			
				
					// everything needed for the error calculation
					// the PolMatrix error matrices
					// and the data error
					
					
					
					// TODO_POL -- where are these matrices??
					WAVE inv = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix")
					WAVE inv_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix_err")
			
				
					numRows = DimSize(linear_data_UU_pc, 0 )
					numCols = DimSize(linear_data_UU_pc, 1 )
					
					// this is certainly not slow. takes < 1 second to complete the double loop.
					for(ii=0;ii<numRows;ii+=1)
						for(jj=0;jj<numCols;jj+=1)
							vecB[0] = linear_data_UU[ii][jj]
							vecB[1] = linear_data_DU[ii][jj]
							vecB[2] = linear_data_DD[ii][jj]
							vecB[3] = linear_data_UD[ii][jj]
						
							MatrixLinearSolve/M=1 matA vecB
							// result is M_B[][0]
							WAVE M_B = M_B
							linear_data_UU_pc[ii][jj] = M_B[0][0]
							linear_data_DU_pc[ii][jj] = M_B[1][0]
							linear_data_DD_pc[ii][jj] = M_B[2][0]
							linear_data_UD_pc[ii][jj] = M_B[3][0]
						
					
							// and the error at each pixel, once for each of the four
							row = 0		//== UU
							for(kk=0;kk<4;kk+=1)
								linear_data_error_UU_pc[ii][jj] += inv_err[row][kk]^2*linear_data_UU[ii][jj]^2 + inv[row][kk]^2*linear_data_error_UU[ii][jj]^2
							endfor
							row = 1		//== DU
							for(kk=0;kk<4;kk+=1)
								linear_data_error_DU_pc[ii][jj] += inv_err[row][kk]^2*linear_data_DU[ii][jj]^2 + inv[row][kk]^2*linear_data_error_DU[ii][jj]^2
							endfor
							row = 2		//== DD
							for(kk=0;kk<4;kk+=1)
								linear_data_error_DD_pc[ii][jj] += inv_err[row][kk]^2*linear_data_DD[ii][jj]^2 + inv[row][kk]^2*linear_data_error_DD[ii][jj]^2
							endfor
							row = 3		//== UD
							for(kk=0;kk<4;kk+=1)
								linear_data_error_UD_pc[ii][jj] += inv_err[row][kk]^2*linear_data_UD[ii][jj]^2 + inv[row][kk]^2*linear_data_error_UD[ii][jj]^2
							endfor
									
						endfor
					//	Print ii	
					endfor
					
					// sqrt of the squared error...
					linear_data_error_UU_pc = sqrt(linear_data_error_UU_pc)
					linear_data_error_DU_pc = sqrt(linear_data_error_DU_pc)
					linear_data_error_DD_pc = sqrt(linear_data_error_DD_pc)
					linear_data_error_UD_pc = sqrt(linear_data_error_UD_pc)
					
					// copy the PC result (linear_data) to data in each of the folders
					linear_data_UU = linear_data_UU_pc
					linear_data_DU = linear_data_DU_pc
					linear_data_DD = linear_data_DD_pc
					linear_data_UD = linear_data_UD_pc
					linear_data_error_UU = linear_data_error_UU_pc
					linear_data_error_DU = linear_data_error_DU_pc
					linear_data_error_DD = linear_data_error_DD_pc
					linear_data_error_UD = linear_data_error_UD_pc
				
				
				endif		// if ignoreB
				
			endfor
			
			//// end loop over all of the detector panels			
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// display all 4 XS at once in the same graph
// - crude right now
//
Function V_Display4XSButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String dataType,pType,str,scaling
//			Prompt dataType,"Display WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;"
////			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;UU_pc;DU_pc;DD_pc;UD_pc;"
//			Prompt scaling,"scaling",popup,"log;linear;"
//			DoPrompt "Change Display",dataType,scaling
	
			dataType = "SAM"
			scaling = "log"
			
			DoWindow/F VSANS_X4	
				
			if(V_flag==0)		//continue
				V_Display_4(dataType,scaling)
				
				// then fill each subwindow with each XS (9 panels)
				V_FillXSPanels(dataType,"UU")
				V_FillXSPanels(dataType,"UD")
				V_FillXSPanels(dataType,"DU")
				V_FillXSPanels(dataType,"DD")
			endif		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// Change the displayed SANS data by pointing the data with the 
// specified tag (suffix) at data, linear_data, etc.
// all of the read waves are pointed too.
//
Function V_ChangeDisplayedPolData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String dataType,pType,str
			Prompt dataType,"Display WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;"
			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;"
			DoPrompt "Change Display",dataType,pType
			
			if(V_flag==0)		//continue
				sprintf str,"V_DisplayTaggedData(\"%s\",\"%s\")",dataType,pType
				Execute str
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// display the 4x4 polariztion efficiency matrix in a table, and its inverse (if it exists)
Function V_ShowPolMatrixButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// get the current tab
			String type
			Variable tabNum
			ControlInfo/W=V_PolCor_Panel PolCorTab
			type = S_value
			Print "selected data type = ",type
			tabNum = V_Value
			
			Wave/Z Pol = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix")
			if(WaveExists(Pol))
				Edit/W=(5,44,510,251)/K=1 Pol
			endif
			Wave/Z Inv_Pol = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix")
			if(WaveExists(Inv_Pol))
				Edit/W=(6,506,511,713)/K=1 Inv_Pol
			endif
			Wave/Z Pol_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_PolMatrix_err")
			if(WaveExists(Pol_err))
				Edit/W=(5,275,510,482)/K=1 Pol_err
			endif
			Wave/Z Inv_Pol_err = $("root:Packages:NIST:VSANS:Globals:"+type+"_Inv_PolMatrix_err")
			if(WaveExists(Inv_Pol_err))
				Edit/W=(6,736,511,943)/K=1 Inv_Pol_err
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// return a list of conditions, prepended with "none" for use in a popup menu
Function/S V_P_GetConditionNameList()
	return("none;"+V_D_ConditionNameList())
End


// for a run, or a list of runs, determine the midpoint of the data collection
//
// list is passed COMMA-delimited, like normal lists of run numbers
//
// the time is returned in seconds (equivalent to a VAX date and time)
//
Function V_getTimeMidpoint(listStr)
	String listStr

	Variable ii,t_first,runt_first,t_last,runt_last,elap,run,t1,num,tMid
	String fname
	
	t1=0
	t_first = 1e100
	t_last = 0
	
	num=itemsinlist(listStr,",")
	for(ii=0;ii<num;ii+=1)
		run = str2num( StringFromList(ii, listStr ,",") )
		fname = V_FindFileFromRunNumber(run)
		// TODO_POL -- need to get t1 in seconds
//		Abort"Need to convert the time to seconds"
		
		t1 = V_ISO8601_to_IgorTime(V_getDataStartTime(fname))		//values returned in seconds
//		t1 = V_ConvertVAXDateTime2Secs(V_getFileCreationDate(fname))


		if(t1 < t_first)
			t_first = t1
		endif
		if(t1 > t_last)
			t_last = t1
			runt_last = V_getCount_time(fname)		//V_getCountTime(fname)		//seconds
		endif
	
	endfor
//	print/D t_last
//	Print/D runt_last
//	print/D t_first
	
	elap = (t_last + runt_last) - t_first		// from start of first file, to end of last

	tMid = t_first + elap/2
	return(tMid)
End


//
// options to reduce one or all types, in the same manner as the load.
//
// largely copied from ReduceAFile()
//
//
//
//
Function V_ReducePolCorDataButton(ctrlName) : ButtonControl
	String ctrlName


	String pType
//	Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;All;"
//	DoPrompt "Type to load",pType
//	if (V_Flag)
//		return 0									// user canceled
//	endif
//	Print pType


	pType = "All"

// get the protocol to use
// this is pulled from ReduceAFile()
	Variable err
	String waveStr
	
	//pick a protocol wave from the Protocols folder
	//must switch to protocols folder to get wavelist (missing parameter)
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols:
	Execute	"V_PickAProtocol()"
	
	//get the selected protocol wave choice through a global string variable
	SVAR protocolName = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	
	//If "CreateNew" was selected, go to the questionnare, to make a new set
	//and put the name of the new Protocol wave in gProtoStr
	if(cmpstr("CreateNew",protocolName) == 0)
		DoAlert 0,"For Polarization, must choose a pre-saved protocol"
		return(0)
	Endif
	
	//give the full path:name to the executeProtocol function
	waveStr = "root:Packages:NIST:VSANS:Globals:Protocols:"+protocolName
	WAVE/T prot = $waveStr
	
	
	// outside of the protocol execution, load all of the SAM, BGD, and EMP data files as needed
	// and do the polarization correction to be sure that all of the corrected files
	// exist - then they can simply be copied into place sequentially for the 4XS
	// rather than the time-waster of re-loading them 4x4=16 times
	
	STRUCT WMButtonAction ba
	ba.eventCode = 2		// mouse up
	
//////////////////////////////
// SAM
//////////////////////////////
// Now ensure that the proper SAM data is loaded, then re-tag it	
// the Polarization corrected data is UU_pc, DU_pc, etc.
// this tags it for display, and puts it in the correctly named waves
//	
	V_ChangeDataTab(0)		//SAM
	V_LoadRawPolarizedButton(ba)
	V_PolCorButton(ba)

// save the name of the last-loaded SAM file for data save later
	SVAR gSAMFile = root:Packages:NIST:VSANS:SAM:gFileList
	String samFileLoaded = gSAMFile
		
//	dataType="SAM"
//	sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//	Execute str



//////////////////////////////
// BGD
//////////////////////////////
	// force a re-load of BGD data, then re-tag it	
	if(cmpstr(prot[0],"none") != 0)		//if BGD is used, protStr[0] = ""

		V_ChangeDataTab(2)		//BGD
		V_LoadRawPolarizedButton(ba)
		V_PolCorButton(ba)
		
//		dataType="BGD"
//		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//		Execute str
	endif



//////////////////////////////
// EMP
//////////////////////////////	
	
// force a re-load the EMP data, then re-tag it
	if(cmpstr(prot[1],"none") != 0)		//if EMP is used, protStr[1] = ""

		V_ChangeDataTab(1)		//EMP
		V_LoadRawPolarizedButton(ba)
		V_PolCorButton(ba)
	
//		dataType="EMP"
//		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//		Execute str
	endif

	
	// now reduce the data
	if(cmpstr(pType,"All") == 0)
		V_ExecutePolarizedProtocol(waveStr,"UU")
		V_ExecutePolarizedProtocol(waveStr,"DU")
		V_ExecutePolarizedProtocol(waveStr,"DD")
		V_ExecutePolarizedProtocol(waveStr,"UD")
	else
		V_ExecutePolarizedProtocol(waveStr,pType)
	endif	
	
	SetDataFolder root:
	return(0)
End


//
// Copied from V_ExecuteProtocol
// with the changes to copy the data from the tagged data folders for SAM, EMP, BGD
// instead of reading the files from the protocol. For VSANS, there are no _pc extensions
// but rather a flag in the folder that signifies that the polarization correction has been done.
//
//
// 
// OCT 2012 - changed this to force a re-load of all of the data, and a re-calculation 
//   of the Pol-corrected data, so that all of the "_pc" waves that are present are the 
// correct, and current values. Only re-loads the data that is used for the particular protocol, 
// just like a normal reduction. This is, somewhat redundant, since the data is re-loaded 4x, when
// it really only needs to be re-loaded 1x, but this is only a minor speed hit.
//
// -- the "extensions" now all are "_UU_pc" and similar, to use the polarization corrected data and errors
//
//
//function is long, but straightforward logic
//
Function V_ExecutePolarizedProtocol(protStr,pType)
	String protStr,pType
	
	//protStr is the full path to the selected protocol wave
	//pType is the "tag" of the polarization spin states
	
	WAVE/T prot = $protStr
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	
	Variable filesOK,err,notDone
	String activeType, msgStr, junkStr, pathStr="",samStr=""
	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
//	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)
	//7 = beginning trim points
	//8 = end trim points
	//9 = collimation type for reduced data
	//10 = unused
	//11 = unused

//////////////////////////////
// DIV
//////////////////////////////
// for VSANS, DIV is used on each data file as it is converted to WORK, so it needs to be
//  the first thing in place, before any data or backgrounds are loaded

	//check for work.div file (prot[2])
	//load in if needed
	// no math is done here, DIV is applied as files are converted to WORK (the first operation in VSANS)
	//

	// save the state of the DIV preference
	NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	Variable saved_gDoDIVCor = gDoDIVCor
	
	err = V_Proto_LoadDIV(prot[2])
	
	if(err)
		SetDataFolder root:
		Abort "No file selected, data reduction aborted"
	endif


	
	// For each of the tabs (SAM, EMP, BGD)
	// -- reload the data
	// -- re-do the polarization correction
	
	// then, and only then, after we're sure that all of the data is correct and current, then proceed with the
	// correction of the data with the selected protocol
	String dataType,str
	Variable dfExists,polCorFlag

	STRUCT WMButtonAction ba
	ba.eventCode = 2		// mouse up
	
//////////////////////////////
// SAM
//////////////////////////////
// Now ensure that the proper SAM data is loaded, then re-tag it	
// the Polarization corrected data is UU_pc, DU_pc, etc.
// this tags it for display, and puts it in the correctly named waves
//
// now, for VSANS, the data is already loaded and in SAM_UU, etc. Simply copy it over
// to the SAM folder

	dfExists = DataFolderExists("root:Packages:NIST:VSANS:SAM_"+pType)
	polCorflag = Exists("root:Packages:NIST:VSANS:SAM_"+pType+":PolCorDone")	//==1 if wave exists
	
	if(dfExists == 1 && PolCorFlag == 1)
		V_CopyHDFToWorkFolder("SAM_"+pType,"SAM")
	else
		DoAlert 0,"Error with Polarized SAM Data"
		Return(0)
	endif	
//	V_ChangeDataTab(0)		//SAM
//	V_LoadRawPolarizedButton(ba)
//	V_PolCorButton(ba)

// save the name of the last-loaded SAM file for data save later
	SVAR gSAMFile = root:Packages:NIST:VSANS:SAM:gFileList
	String samFileLoaded = gSAMFile
		
//	dataType="SAM"
//	sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//	Execute str



//////////////////////////////
// BGD
//////////////////////////////
	// force a re-load of BGD data, then re-tag it	
	if(cmpstr(prot[0],"none") != 0)		//if BGD is used, protStr[0] = ""

// simply copy the data to the BGD folder
		dfExists = DataFolderExists("root:Packages:NIST:VSANS:BGD_"+pType)
		polCorflag = Exists("root:Packages:NIST:VSANS:BGD_"+pType+":PolCorDone")	//==1 if wave exists
		
		if(dfExists == 1 && PolCorFlag == 1)
			V_CopyHDFToWorkFolder("BGD_"+pType,"BGD")
		else
			DoAlert 0,"Error with Polarized BGD Data"
			Return(0)
		endif	

//		V_ChangeDataTab(2)		//BGD
//		V_LoadRawPolarizedButton(ba)
//		V_PolCorButton(ba)
		
//		dataType="BGD"
//		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//		Execute str
	endif



//////////////////////////////
// EMP
//////////////////////////////	
	
// force a re-load the EMP data, then re-tag it
	if(cmpstr(prot[1],"none") != 0)		//if EMP is used, protStr[1] = ""

// simply copy the data to the EMP folder
		dfExists = DataFolderExists("root:Packages:NIST:VSANS:EMP_"+pType)
		polCorflag = Exists("root:Packages:NIST:VSANS:EMP_"+pType+":PolCorDone")	//==1 if wave exists
		
		if(dfExists == 1 && PolCorFlag == 1)
			V_CopyHDFToWorkFolder("EMP_"+pType,"EMP")
		else
			DoAlert 0,"Error with Polarized EMP Data"
			Return(0)
		endif	


//		V_ChangeDataTab(1)		//EMP
//		V_LoadRawPolarizedButton(ba)
//		V_PolCorButton(ba)
	
//		dataType="EMP"
//		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
//		Execute str
	endif


//
// from here down, the steps are identical
//
// - with the exceptions of:
// - file naming. Names are additionally tagged with pType


//////////////////////////////
// CORRECT
//////////////////////////////

	//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction 
	//additional modes 091301
	//11 = emp, bgd, drk
	//12 = bgd and drk
	//13 = emp and drk
	//14 = no subtractions
	//work.drk is from proto[6]
	//
	//subtracting just the DRK data is NOT an option - it doesnt' really make any physical sense
	// - in this case, DRK is skipped (equivalent to mode==4)
	// automatically accounts for attenuators given the lookup tables and the 
	//desired subtractions
	//Attenuator lookup tables are alredy implemented (NG1 = NG7)
	//


/////// DRK is SKIPPED
	
//	//read in the DRK data if necessary
//	//only one file, assumed to be RAW data
//	//
//	String fname="",drkStr=""
//	drkStr=StringByKey("DRK",prot[6],"=",",")
//	if(cmpstr(drkStr,"none") != 0)
//		err = ReadHeaderAndData( (pathStr+drkStr) )
//		if(err)
//			PathInfo/S catPathName
//			Abort "reduction sequence aborted"
//		endif
//		err = V_Raw_to_Work_NoNorm("DRK")
//	endif

	//dispatch to the proper "mode" of Correct()
//	V_Dispatch_to_Correct(bgdStr,empStr,drkStr)
	V_Dispatch_to_Correct(prot[0],prot[1],prot[6])
	
	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "error in Correct, called from executeprotocol, normal cor"
	endif
	activeType = "COR"

// always update - COR will always be generated
	V_UpdateDisplayInformation(ActiveType)		


//////////////////////////////
//  ABSOLUTE SCALE
//////////////////////////////

	err = V_Proto_ABS_Scale(prot[4],activeType)		//activeType is pass-by-reference and updated IF ABS is used
	
	if(err)
		SetDataFolder root:
		Abort "Error in V_Absolute_Scale(), called from V_ExecuteProtocol"
	endif
//	activeType = "ABS"


//////////////////////////////
// MASK
//////////////////////////////
//
// DONE
//		x- fill in the "ask" step
//  x- none is OK, except if the kill fails for any reason
// x- the regular case of the file name specified by the protocol works correctly
// x- don't create a null mask if not used, it will handle the error and print out that the mask is missing
//
//mask data if desired (mask is applied when the data is binned to I(q)) and is
//not done explicitly here
	
	//check for mask
	//doesn't change the activeType
	V_Proto_ReadMask(prot[3])

	
//////////////////////////////
// AVERAGING
//////////////////////////////

	// average/save data as specified
	//Parse the keyword=<Value> string as needed, based on AVTYPE
	
	//average/plot first 
	String av_type = StringByKey("AVTYPE",prot[5],"=",";")
	If(cmpstr(av_type,"none") != 0)
		If (cmpstr(av_type,"")==0)		//if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit in the panel
			V_SetAverageParamsButtonProc("dummy")		//from "ProtocolAsPanel"
			SVAR tempAveStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE",tempAveStr,"=",";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			String/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = prot[5]
		Endif
	Endif


	String detGroup = StringByKey("DETGROUP",prot[5],"=",";")		//only for annular, null if not present

	
//convert the folder to linear scale before averaging, then revert by calling the window hook
// (not needed for VSANS, data is always linear scale)

//
// (DONE)
// -x this generates a "Bin Type Not Found" error if reducing only to a 2D level (like for DIV)
//		because binTypeStr is null
	String binTypeStr = StringByKey("BINTYPE",prot[5],"=",";")
	// plotting is not really necessary, and the graph may not be open - so skip for now?
	Variable binType
	// only get the binning type if user asks for averaging
	If(cmpstr(av_type,"none") != 0)
		binType = V_BinTypeStr2Num(binTypeStr)
		if(binType == 0)
				Abort "Binning mode not found in V_QBinAllPanels() "// when no case matches
		endif
	endif


// identify the collimation type
// this will be a string used to determine how the resolution information is to be calculated
// and written to the reduced data file
//
// possible values are:
//
// pinhole
// pinhole_whiteBeam
// narrowSlit
// narrowSlit_whiteBeam
// convergingPinholes
//

	String collimationStr
	collimationStr = V_IdentifyCollimation(activeType)
	

////////////////////////////////////////
// DISPATCH TO AVERAGING
/////////////////////////////////////////
//
// TODO:
// -- do I calculate the proper resolution here?, YES, I've already decoded the binning type
//   and the averaging type has been specified by the protocol.
//
// so currently, the resolution is calculated every time that the data is averaged (in VC_fDoBinning_QxQy2D)
//
// -- if I calculate the resolution here, then the Trimming routines must be updated
//    to trim the resolution waves also. This will work for the columns present in
//    pinhole resolution, but anything using the matrix method - it won't work - and I'll need 
//    a different solution
//

	V_Proto_doAverage(prot[5],av_type,activeType,binType,collimationStr)



////////////////////////
// PLOT THE DATA
////////////////////////

	V_Proto_doPlot(prot[5],av_type,activeType,binType,detGroup)
	
	

////////////////////	
// SAVE THE DATA
////////////////////

// 
// x- how do I get the sample file name?
//    local variable samFileLoaded is the file name loaded (contains the extension)
//
// V_Proto_SaveFile(avgStr,activeType,samFileLoaded,av_type,binType,detGroup,trimBegStr,trimEndStr)
//
// this step does more than save...
// - trims the selected points from the data set
// - concatenates the data sets
// - removes NaN points and removes duplicate q-values by averaging q-values that are within 0.1% of each other
//

	prot[9] = collimationStr

	String newFileName = RemoveEnding(samFileLoaded,".nxs.ngv")
	newFileName += "_" + pType

	V_Proto_SaveFile(prot[5],activeType,newFileName,av_type,binType,detGroup,prot[7],prot[8])
	
//////////////////////////////
// DONE WITH THE PROTOCOL
//////////////////////////////	

// copy the activeType folder to a _pType extension to save it for display
//
	
	V_CopyHDFToWorkFolder(activeType,activeType+"_"+ptype)



	// reset any global preferences that I had changed
	gDoDIVCor = saved_gDoDIVCor
	
	
	Return(0)
End







// just like the RecallProtocolButton
// - the reset Function V_is different
//
//Function V_RecallPolCorProtocolButton(ctrlName) : ButtonControl
//	String ctrlName
//	
//	//will reset panel values based on a previously saved protocol
//	//pick a protocol wave from the Protocols folder
//	//MUST move to Protocols folder to get wavelist
//	SetDataFolder root:myGlobals:Protocols
//	Execute "V_PickAProtocol()"
//	
//	//get the selected protocol wave choice through a global string variable
//	SVAR protocolName = root:myGlobals:Protocols:gProtoStr
//
//	//If "CreateNew" was selected, ask user to try again
//	if(cmpstr("CreateNew",protocolName) == 0)
//		Abort "CreateNew is for making a new Protocol. Select a previously saved Protocol"
//	Endif
//	
//	//reset the panel based on the protocol textwave (currently a string)
//	V_ResetToSavedPolProtocol(protocolName)
//	
//	SetDataFolder root:
//	return(0)
//end

////Function V_that actually parses the protocol specified by nameStr
////which is just the name of the wave, without a datafolder path
////
//Function V_ResetToSavedPolProtocol(nameStr)
//	String nameStr
//	
//	//allow special cases of Base and DoAll Protocols to be recalled to panel - since they "ask"
//	//and don't need paths
//	
//	String catPathStr
//	PathInfo catPathName
//	catPathStr=S_path
//	
//	//SetDataFolder root:myGlobals:Protocols		//on windows, data folder seems to get reset (erratically) to root: 
//	Wave/T w=$("root:myGlobals:Protocols:" + nameStr)
//	
//	String fullPath="",comma=",",list="",nameList="",PathStr="",item=""
//	Variable ii=0,numItems,checked,specialProtocol=0
//	
//	if((cmpstr(nameStr,"Base")==0) || (cmpstr(nameStr,"DoAll")==0))
//		return(0)		//don't allow these
//	Endif
//
//	//background = check5
//	checked = 1
//	nameList = w[0]
//	If(cmpstr(nameList,"none") ==0)
//		checked = 0
//	Endif
//
//	//set the global string to display and checkbox
//	CheckBox check5 win=V_PolCor_Panel,value=checked
//
//	//EMP = check4
//	checked = 1
//	nameList = w[1]
//	If(cmpstr(nameList,"none") ==0)
//		checked = 0
//	Endif
//
//	//set the global string to display and checkbox
//	CheckBox check4 win=V_PolCor_Panel,value=checked
//	
//	
//	//DIV file
//	checked = 1
//	nameList = w[2]
//	If(cmpstr(nameList,"none") ==0)
//		checked = 0
//	Endif
//
//	//set the global string to display and checkbox
//	String/G root:myGlobals:Protocols:gDIV = nameList
//	CheckBox check0 win=V_PolCor_Panel,value=checked
//	
//	//Mask file
//	checked = 1
//	nameList = w[3]
//	If(cmpstr(nameList,"none") ==0)
//		checked = 0
//	Endif
//
//	//set the global string to display and checkbox
//	String/G root:myGlobals:Protocols:gMASK = nameList
//	CheckBox check1 win=V_PolCor_Panel,value=checked
//	
//	//4 = abs parameters
//	list = w[4]
//	numItems = ItemsInList(list,";")
//	checked = 1
//	if(numitems == 4 || numitems == 5)		//allow for protocols with no SDEV list item
//		//correct number of parameters, assume ok
//		String/G root:myGlobals:Protocols:gAbsStr = list
//		CheckBox check2 win=V_PolCor_Panel,value=checked
//	else
//		item = StringFromList(0,list,";")
//		if(cmpstr(item,"none")==0)
//			checked = 0
//			list = "none"
//			String/G root:myGlobals:Protocols:gAbsStr = list
//			CheckBox check2 win=V_PolCor_Panel,value=checked
//		else
//			//force to "ask"
//			checked = 1
//			String/G root:myGlobals:Protocols:gAbsStr = "ask"
//			CheckBox check2 win=V_PolCor_Panel,value=checked
//		Endif
//	Endif
//	
//	//5 = averaging choices
//	list = w[5]
//	item = StringByKey("AVTYPE",list,"=",";")
//	if(cmpstr(item,"none") == 0)
//		checked = 0
//		String/G root:myGlobals:Protocols:gAVE = "none"
//		CheckBox check3 win=V_PolCor_Panel,value=checked
//	else
//		checked = 1
//		String/G root:myGlobals:Protocols:gAVE = list
//		CheckBox check3 win=V_PolCor_Panel,value=checked
//	Endif
//	
//	//6 = DRK choice
//
//	//7 = unused
//	
//	//all has been reset, get out
//	Return (0)
//End


//Function V_ExportPolCorProtocolButton(ctrlName) : ButtonControl
//	String ctrlName
//	
//	V_ExportProtocol(ctrlName)
//	return(0)
//End
//
//
//Function V_ImportPolCorProtocolButton(ctrlName) : ButtonControl
//	String ctrlName
//	
//	V_ImportProtocol(ctrlName)
//	return(0)
//End

Proc V_BuildProtocol_PolCorButtonProc(ctrlName) : ButtonControl
	String ctrlName

	V_ReductionProtocolPanel()
End

// at a first pass, uses the regular reduction protocol 	SaveProtocolButton(ctrlName)
//
// TODO
// X- won't work, as it uses the MakeProtocolFromPanel function... so replace this
//
Function V_SavePolCorProtocolButton(ctrlName) : ButtonControl
	String ctrlName
	
	
	Variable notDone=1, newProto=1
	//will prompt for protocol name, and save the protocol as a text wave
	//prompt for name of new protocol wave to save
	do
		Execute "AskForName()"
		SVAR newProtocol = root:myGlobals:Protocols:gNewStr
		
		//make sure it's a valid IGOR name
		newProtocol = CleanupName(newProtocol,0)	//strict naming convention
		String/G root:myGlobals:Protocols:gNewStr=newProtocol		//reassign, if changed
		Print "newProtocol = ",newProtocol
		
		SetDataFolder root:myGlobals:Protocols
		if(WaveExists( $("root:myGlobals:Protocols:" + newProtocol) ) == 1)
			//wave already exists
			DoAlert 1,"That name is already in use. Do you wish to overwrite the existing protocol?"
			if(V_Flag==1)
				notDone = 0
				newProto = 0
			else
				notDone = 1
			endif
		else
			//name is good
			notDone = 0
		Endif
	while(notDone)
	
	//current data folder is  root:myGlobals:Protocols
	if(newProto)
		Make/O/T/N=8 $("root:myGlobals:Protocols:" + newProtocol)
	Endif
	
//	MakeProtocolFromPanel( $("root:myGlobals:Protocols:" + newProtocol) )
	V_MakePolProtocolFromPanel( $("root:myGlobals:Protocols:" + newProtocol) )
	String/G  root:myGlobals:Protocols:gProtoStr = newProtocol
	
	//the data folder WAS changed above, this must be reset to root:
	SetDatafolder root:	
		
	return(0)
End

//
// -- I use the regular protocol panel instead and this has not been updated
//
//Function V_that does the guts of reading the panel controls and globals
//to create the necessary text fields for a protocol
//Wave/T w (input) is an empty text wave of 8 elements for the protocol
//on output, w[] is filled with the protocol strings as needed from the panel 
//
// -- For polarized beam protocols, don't fill in EMP or BGD, as these are handled differently, since 4 XS
//
Function V_MakePolProtocolFromPanel(w)
	Wave/T w

	DoAlert 0,"Not updated for VSANS -- using regular protocol panel instead"
	return(0)
		
	//construct the protocol text wave form the panel
	//it is to be parsed by ExecuteProtocol() for the actual data reduction
	PathInfo catPathName			//this is where the files came from
	String pathstr=S_path,tempStr,curList
	Variable checked,ii,numItems
	
	//look for checkboxes, then take each item in list and prepend the path
	//w[0] = background
	ControlInfo/W=V_PolCor_Panel check5
	checked = V_Value
	if(checked)
		w[0] = ""		// BKG will be used
	else
		w[0] = "none"		// BKG will not be used
	endif
	
	//w[1] = empty
	ControlInfo/W=V_PolCor_Panel check4
	checked = V_Value
	if(checked)
		w[1] = ""		// EMP will be used
	else
		w[1] = "none"		// EMP will not be used
	endif

	
	//w[2] = div file
	ControlInfo/W=V_PolCor_Panel check0
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gDIV
		if(cmpstr(str,"ask")==0)
			w[2] = str
		else
			tempStr = V_ParseRunNumberList(str)
			if(strlen(tempStr)==0)
				return(1)
			else
				w[2] = tempstr
				str=tempstr
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[2] = "none"
		String/G root:myGlobals:Protocols:gDIV = "none"
	endif
	
	//w[3] = mask file
	ControlInfo/W=V_PolCor_Panel check1
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gMASK
		if(cmpstr(str,"ask")==0)
			w[3] = str
		else
			tempstr = V_ParseRunNumberList(str)
			if(strlen(tempstr)==0)
				return(1)
			else
				w[3] = tempstr
				str = tempstr
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[3] = "none"
		String/G root:myGlobals:Protocols:gMASK = "none"
	endif
	
	//w[4] = abs parameters
	ControlInfo/W=V_PolCor_Panel check2
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gAbsStr
		w[4] = str
	else
		//none used - set textwave (and global?)
		w[4] = "none"
		String/G root:myGlobals:Protocols:gAbsStr = "none"
	endif
	
	//w[5] = averaging choices
	ControlInfo/W=V_PolCor_Panel check3
	checked = V_value
	if(checked)
		//just read the global
		SVAR avestr=root:myGlobals:Protocols:gAVE
		w[5] = avestr
	else
		//none used - set textwave
		w[5] = "AVTYPE=none;"
	endif
	
	//w[6]
	//work.DRK information
	SVAR drkStr=root:myGlobals:Protocols:gDRK
	w[6] = ""
	
	//w[7]
	//currently unused
	w[7] = ""
	
	return(0)
End



// the data in the SAM, EMP, BKG folders will be either _UU or _UU_pc, depending if the data
// is as-loaded, or if it's been polarization corrected. This is to display the polarization-corrected "_pc"
// data sets ONLY. If you want to see the individual data sets, well that's just the SAM, EMP, BGD files.
// look at thum one-by-one...
//
// -- data in subsequent correction step folders do have the _pc extensions, the _pc data is
//		used for each step, so the _pc is redundant, but consistent
//
Function V_Display_4(type,scaling)
	String type,scaling

	Variable sc=1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	

	DoWindow/F VSANS_X4
	if(V_flag==0)
		Display /W=(800*sc,40*sc,1480*sc,780*sc)/K=1
		ControlBar 100*sc
		DoWindow/C VSANS_X4
		DoWindow/T VSANS_X4,type+"_pc"
		Button button0 pos={sc*130,65*sc},size={sc*50,20*sc},title="Do It",proc=V_Change4xsButtonProc
		PopupMenu popup0 pos={sc*20,35*sc},title="Data Type",value="SAM;EMP;BGD;COR;CAL;ABS;"		//RAW, SAS, DIV, etc, won't have _pc data and are not valid
//		PopupMenu popup1 pos={sc*190,35*sc},title="Scaling",value="log;linear;"
		TitleBox title0 title="Only Polarization-corrected sets are displayed",pos={sc*5,5}

		DrawText 0.019,0.063,"\\Z18\\f01UU"
		DrawText 0.50,0.063,"\\Z18\f01UD"
		DrawText 0.019,0.52,"\\Z18\\f01DU"
		DrawText 0.50,0.52,"\\Z18\\f01DD"


		SetVariable setVar_b,pos={sc*300,35*sc},size={sc*120,15},title="axis Q",proc=V_2DQ_Range_SetVarProc
		SetVariable setVar_b,limits={0.02,1,0.02},value=_NUM:0.12
		CheckBox check_0a title="Log?",size={sc*60,20*sc},pos={sc*190,35*sc},proc=V_X4_Log_CheckProc


	// allocate space for the 4 xs. each will be filled in with the 8 or 9 panels
	// control bar is 100*sc pixels
	//		Display /W=(811*sc,44*sc,1479*sc,758*sc)/K=1
	
	// top left
	//	Display/W=(14,20,223,204)/HOST=#  fv_degY vs fv_degX
	
		Variable wd=220,ht=220,ll=20,tt=10,gp=2
	
	// for UU (as 2D Q)
		if(gLaptopMode == 1)
		// note that the dimensions here are not strictly followed since the aspect ratio is set below
			Display/W=(ll,tt,ll+wd,tt+ht)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		else
			Display/W=(10/sc,20/sc,200/sc,200/sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		endif	
		RenameWindow #,UU_Panels_Q
		ModifyGraph mode=2		// mode = 2 = dots
		ModifyGraph tick=2,mirror=1,grid=2,standoff=0
		ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
		SetAxis left -0.2,0.2
		SetAxis bottom -0.2,0.2
		Label left "Qy"
		Label bottom "Qx"	
		SetActiveSubwindow ##
	
	
	// for UD (as 2D Q)
		if(gLaptopMode == 1)
		// note that the dimensions here are not strictly followed since the aspect ratio is set below
			Display/W=(ll+wd+gp,tt,ll+wd+gp+wd,tt+ht)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		else
			Display/W=(220/sc,20/sc,400/sc,200/sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		endif	
		RenameWindow #,UD_Panels_Q
		ModifyGraph mode=2		// mode = 2 = dots
		ModifyGraph tick=2,mirror=1,grid=2,standoff=0
		ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
		SetAxis left -0.2,0.2
		SetAxis bottom -0.2,0.2
		Label left "Qy"
		Label bottom "Qx"	
		SetActiveSubwindow ##
		
		// for DU (as 2D Q)
		if(gLaptopMode == 1)
		// note that the dimensions here are not strictly followed since the aspect ratio is set below
			Display/W=(ll,tt+ht+gp,ll+wd,tt+ht+gp+ht)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		else
			Display/W=(10/sc,220/sc,400/sc,400/sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		endif	
		RenameWindow #,DU_Panels_Q
		ModifyGraph mode=2		// mode = 2 = dots
		ModifyGraph tick=2,mirror=1,grid=2,standoff=0
		ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
		SetAxis left -0.2,0.2
		SetAxis bottom -0.2,0.2
		Label left "Qy"
		Label bottom "Qx"	
		SetActiveSubwindow ##
		
		// for DD (as 2D Q)
		if(gLaptopMode == 1)
		// note that the dimensions here are not strictly followed since the aspect ratio is set below
			Display/W=(ll+wd+gp,tt+ht+gp,ll+wd+gp+wd,tt+ht+gp+ht)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		else
			Display/W=(220/sc,220/sc,400/sc,400/sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		endif	
		RenameWindow #,DD_Panels_Q
		ModifyGraph mode=2		// mode = 2 = dots
		ModifyGraph tick=2,mirror=1,grid=2,standoff=0
		ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
		SetAxis left -0.2,0.2
		SetAxis bottom -0.2,0.2
		Label left "Qy"
		Label bottom "Qx"	
		SetActiveSubwindow ##

	endif
	
	SetDataFolder root:
	
	return(0)
End


Function V_X4_Log_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			Struct WMButtonAction ba
			ba.eventCode = 2		//fake mouse up
			V_Change4xsButtonProc(ba)		//fake click on "do it"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_Change4xsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String dataType,scaling
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup0
			dataType = S_Value

			
			// remove all of the old data from the 4 subgraphs
			// ?? each call here is supposed to clear everything from all 4 subwindows,
			// but for some reason, I need to do this multiple times...
			V_ClearXSPanels()
			V_ClearXSPanels()
			V_ClearXSPanels()
			V_ClearXSPanels()
			
//			V_Display_4(dataType,scaling)

			// then fill each subwindow with each XS (9 panels)
			V_FillXSPanels(dataType,"UU")
			V_FillXSPanels(dataType,"UD")
			V_FillXSPanels(dataType,"DU")
			V_FillXSPanels(dataType,"DD")
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// UU_Panels_Q
//VSANS_X4

// type is the work folder
// polType is UU, UD, etc.
//
Function V_FillXSPanels(type,polType)
	String type,polType

	// set the strings
	
	
	//fill the back, if used
	
	//fill the middle
	V_PolPanels_AsQ(type,polType,"M")
	//fill the front
	V_PolPanels_AsQ(type,polType,"F")

	
	return(0)
end


// with a data wave passed in and the detStr,
//locate the qx and qy waves, and return the min/max values (PBR)
// to be used for the data scaling
Function V_getQxQyScaling(dataW,detStr,minQx,maxQx,minQy,maxQy)
	Wave dataW
	String detStr
	Variable &minQx,&maxQx,&minQy,&maxQy

	
	DFREF dfr = GetWavesDataFolderDFR(dataW)
	WAVE qx = dfr:$("qx_"+detStr)
	WAVE qy = dfr:$("qy_"+detStr)
	
	minQx = waveMin(qx)
	maxQx = waveMax(qx)
	minQy = waveMin(qy)
	maxQy = waveMax(qy)
		
	return(0)
End

//
// type = work folder type
// polType = "nn" spin state
// carr = det carriage str (F, M, or B)
//
Function V_PolPanels_AsQ(type,polType,carr)
	String type,polType,carr

	Variable dval,minQx,maxQx,minQy,maxQy

	// -- set the log/lin scaling
	ControlInfo/W=VSANS_X4 check_0a
	// V_Value == 1 if checked
	
//	NVAR state = root:Packages:NIST:VSANS:Globals:gIsLogScale
	if(V_Value == 0)
		// lookup wave
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:linearLookupWave
	else
		// lookup wave - the linear version
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:logLookupWave
	endif
	
	String pathStr = "root:Packages:NIST:VSANS:"+type+"_"+polType+":entry:instrument:detector_"

	Wave/Z det_xB = $(pathStr + carr+"B:data")
	Wave/Z det_xT = $(pathStr + carr+"T:data")
	Wave/Z det_xL = $(pathStr + carr+"L:data")
	Wave/Z det_xR = $(pathStr + carr+"R:data")

// check for the existence of the data - if it doesn't exist, abort gracefully
	if( !WaveExists(det_xB) || !WaveExists(det_xT) || !WaveExists(det_xL) || !WaveExists(det_xR) )
		Abort "No Data in the "+type+"_"+polType+" folder"
	endif

// (DONE) -- for each of the 4 data waves, find qmin, qmax and set the scale to q, rather than pixels
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// (DONE): this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	V_getQxQyScaling(det_xB,carr+"B",minQx,maxQx,minQy,maxQy)
	SetScale/I x minQx,maxQx,"", det_xB		//this sets the left and right ends of the data scaling
	SetScale/I y minQy,maxQy,"", det_xB	

	V_getQxQyScaling(det_xT,carr+"T",minQx,maxQx,minQy,maxQy)
	SetScale/I x minQx,maxQx,"", det_xT		//this sets the left and right ends of the data scaling
	SetScale/I y minQy,maxQy,"", det_xT	

	V_getQxQyScaling(det_xL,carr+"L",minQx,maxQx,minQy,maxQy)
	SetScale/I x minQx,maxQx,"", det_xL		//this sets the left and right ends of the data scaling
	SetScale/I y minQy,maxQy,"", det_xL	

	V_getQxQyScaling(det_xR,carr+"R",minQx,maxQx,minQy,maxQy)
	SetScale/I x minQx,maxQx,"", det_xR		//this sets the left and right ends of the data scaling
	SetScale/I y minQy,maxQy,"", det_xR	
	
	
	String imageList,item
	Variable ii,num

	
// UU subwindow

	if(cmpstr(polType,"UU") == 0)
	// append in this order to get LR on top	
//		CheckDisplayed /W=VSANS_X4#UU_Panels_Q det_xB
//		if(V_flag == 0)
		AppendImage/W=VSANS_X4#UU_Panels_Q det_xT
		AppendImage/W=VSANS_X4#UU_Panels_Q det_xB
		AppendImage/W=VSANS_X4#UU_Panels_Q det_xL
		AppendImage/W=VSANS_X4#UU_Panels_Q det_xR
		
		imageList= ImageNameList("VSANS_X4#UU_Panels_Q",";")
		num = ItemsInList(imageList)			
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,imageList,";")
			// faster way than to write them explicitly
			//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#UU_Panels_Q $item ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#UU_Panels_Q $item ctabAutoscale=0,lookup= LookupWave
			//ModifyImage/W=VSANS_X4#UU_Panels_Q $item log=V_Value
		endfor

	// TODO -- set the q-range of the axes
		ControlInfo/W=VSANS_X4 setVar_b
		dval = V_Value
	
		SetAxis/W=VSANS_X4#UU_Panels_Q left -dval,dval
		SetAxis/W=VSANS_X4#UU_Panels_Q bottom -dval,dval	
	
	endif


// UD subwindow

	if(cmpstr(polType,"UD") == 0)
	// append in this order to get LR on top	
		AppendImage/W=VSANS_X4#UD_Panels_Q det_xT
		AppendImage/W=VSANS_X4#UD_Panels_Q det_xB
		AppendImage/W=VSANS_X4#UD_Panels_Q det_xL
		AppendImage/W=VSANS_X4#UD_Panels_Q det_xR
	
			
		imageList= ImageNameList("VSANS_X4#UD_Panels_Q",";")
		num = ItemsInList(imageList)			
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,imageList,";")
			// faster way than to write them explicitly
			//				ModifyImage/W=VSANS_X4#UD_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#UD_Panels_Q $item ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#UD_Panels_Q $item ctabAutoscale=0,lookup= LookupWave
			//ModifyImage/W=VSANS_X4#UD_Panels_Q $item log=V_Value
		endfor
	
	
	// TODO -- set the q-range of the axes
		ControlInfo/W=VSANS_X4 setVar_b
		dval = V_Value
	
		SetAxis/W=VSANS_X4#UD_Panels_Q left -dval,dval
		SetAxis/W=VSANS_X4#UD_Panels_Q bottom -dval,dval	
	
	endif

// DU subwindow

	if(cmpstr(polType,"DU") == 0)
	// append in this order to get LR on top	
		AppendImage/W=VSANS_X4#DU_Panels_Q det_xT
		AppendImage/W=VSANS_X4#DU_Panels_Q det_xB
		AppendImage/W=VSANS_X4#DU_Panels_Q det_xL
		AppendImage/W=VSANS_X4#DU_Panels_Q det_xR


		imageList= ImageNameList("VSANS_X4#DU_Panels_Q",";")
		num = ItemsInList(imageList)			
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,imageList,";")
			// faster way than to write them explicitly
			//				ModifyImage/W=VSANS_X4#DU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#DU_Panels_Q $item ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#DU_Panels_Q $item ctabAutoscale=0,lookup= LookupWave
			//ModifyImage/W=VSANS_X4#DU_Panels_Q $item log=V_Value
		endfor
		
	// TODO -- set the q-range of the axes
		ControlInfo/W=VSANS_X4 setVar_b
		dval = V_Value
	
		SetAxis/W=VSANS_X4#DU_Panels_Q left -dval,dval
		SetAxis/W=VSANS_X4#DU_Panels_Q bottom -dval,dval	
	

	endif


// DD subwindow

	if(cmpstr(polType,"DD") == 0)
	// append in this order to get LR on top	
		AppendImage/W=VSANS_X4#DD_Panels_Q det_xT
		AppendImage/W=VSANS_X4#DD_Panels_Q det_xB
		AppendImage/W=VSANS_X4#DD_Panels_Q det_xL
		AppendImage/W=VSANS_X4#DD_Panels_Q det_xR

				
		imageList= ImageNameList("VSANS_X4#DD_Panels_Q",";")
		num = ItemsInList(imageList)			
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,imageList,";")
			// faster way than to write them explicitly
			//				ModifyImage/W=VSANS_X4#DD_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#DD_Panels_Q $item ctab= {*,*,ColdWarm,0}
			ModifyImage/W=VSANS_X4#DD_Panels_Q $item ctabAutoscale=0,lookup= LookupWave
			//ModifyImage/W=VSANS_X4#DD_Panels_Q $item log=V_Value
		endfor
		
	// TODO -- set the q-range of the axes
		ControlInfo/W=VSANS_X4 setVar_b
		dval = V_Value
	
		SetAxis/W=VSANS_X4#DD_Panels_Q left -dval,dval
		SetAxis/W=VSANS_X4#DD_Panels_Q bottom -dval,dval	
	

	endif


	SetDataFolder root:
	
End


// clear all of the images to start fresh again
//
Function V_ClearXSPanels()
	String type,polType,carr

	
	String imageList,item
	Variable ii,num

	imageList= ImageNameList("VSANS_X4#UU_Panels_Q",";")
	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		RemoveImage/Z/W=VSANS_X4#UU_Panels_Q  $item 
	endfor

	imageList= ImageNameList("VSANS_X4#UD_Panels_Q",";")
	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		RemoveImage/Z/W=VSANS_X4#UD_Panels_Q  $item 
	endfor
	
	imageList= ImageNameList("VSANS_X4#DU_Panels_Q",";")
	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		RemoveImage/Z/W=VSANS_X4#DU_Panels_Q  $item 
	endfor
	
	imageList= ImageNameList("VSANS_X4#DD_Panels_Q",";")
	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		RemoveImage/Z/W=VSANS_X4#DD_Panels_Q  $item 
	endfor

	return(0)
End



// setVar for the range (in Q) for the 2D plot of the detectors
//
// this assumes that everything (the data) is already updated - this only updates the plot range
Function V_2DQ_Range_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			SetAxis/W=VSANS_X4#UU_Panels_Q left -dval,dval
			SetAxis/W=VSANS_X4#UU_Panels_Q bottom -dval,dval

			SetAxis/W=VSANS_X4#UD_Panels_Q left -dval,dval
			SetAxis/W=VSANS_X4#UD_Panels_Q bottom -dval,dval
			
			SetAxis/W=VSANS_X4#DU_Panels_Q left -dval,dval
			SetAxis/W=VSANS_X4#DU_Panels_Q bottom -dval,dval
			
			SetAxis/W=VSANS_X4#DD_Panels_Q left -dval,dval
			SetAxis/W=VSANS_X4#DD_Panels_Q bottom -dval,dval			
//			FrontPanels_AsQ()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End










// clear the entries for all 4 XS for the currently selected Tab only
// clears both the run numbers and the cell assignments
//
Function V_ClearPolCorEntries(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//
//			String type
			Variable tabNum
			ControlInfo/W=V_PolCor_Panel PolCorTab
//			type = S_value
//			Print "selected data type = ",type,V_Value
			tabNum = V_Value
			
			WAVE/T twDD = $("root:Packages:NIST:VSANS:Globals:Polarization:ListWave_"+num2str(tabNum)+"_DD")
			WAVE/T twUU = $("root:Packages:NIST:VSANS:Globals:Polarization:ListWave_"+num2str(tabNum)+"_UU")
			WAVE/T twUD = $("root:Packages:NIST:VSANS:Globals:Polarization:ListWave_"+num2str(tabNum)+"_UD")
			WAVE/T twDU = $("root:Packages:NIST:VSANS:Globals:Polarization:ListWave_"+num2str(tabNum)+"_DU")
			
			twDD = ""
			twUU = ""
			twUD = ""
			twDU = ""
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



















































//////////////////////////////////////////////////////////////
//
/////////// all of the functions below are unused. See the procedures for the 
//// panels for the functions that interact with the input and calculated matrices
//
//
//
//
//
////
//// (/S) FindFileFromRunNumber(num) gets fname
//// [4] is trans, [41] is trans error, [40] is Twhole
////
//
//
//
//Constant kTe = 0.87		// transmission of the unfilled cell
//
//
//
//// calculation of mu
////
//// Known: Te ===> Global constant currently, may change later
////
//// Input: T He (unpolarized), using unpolarized beam
////			T He cell out, using unpolarized beam
////			T background, using unpolarized beam
////
//// Equation 7
////
//Function V_opacity_mu(T_he,T_out,T_bk)
//	Variable T_he,T_out,T_bk
//
//	Variable mu
//
//// using the global constant!
//
//	mu = (1/kTe)*(T_he - T_bk)/(T_out - t_bk)
//	mu = -1*ln(mu)
//
//	return(mu)
//End
//
//
//
//Proc calc_muP(mu, runT_he, runT_out, runT_bk)
//	Variable mu=3.108, runT_he, runT_out, runT_bk
//
//	Variable muP,T_he, T_out, T_bk
//	String fname
//	
//	fname = FindFileFromRunNumber(runT_he)
//	T_he = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)	//use CR, not trans (since no real empty condition)
//	
//	fname = FindFileFromRunNumber(runT_out)
//	T_out = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)
//	
//	fname = FindFileFromRunNumber(runT_bk)
//	T_bk = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)
//	
//	muP = Cell_muP(mu, T_he, T_out, T_bk)
//	
//	Print "Count rates T_he, T_out, T_bk = ",T_he, T_out, T_bk
//	Print "Mu*P = ",muP
//	Print "Time = ",getFileCreationDate(fname)
//	
//end
//
//
//// ???? is this correct ????
//// -- check the form of the equation. It's not the same in some documents
////
//// calculation of mu.P(t) from exerimental measurements
////
//// Known: Te and mu
//// Input: T He cell (polarized cell), using unpolarized beam
////			T He cell OUT, using unpolarized beam
////			T background, using unpolarized beam
////
//// Equation 9, modified by multiplying the result by mu + moving tmp inside the acosh() 
////
//Function V_Cell_muP(mu, T_he, T_out, T_bk)
//	Variable mu, T_he, T_out, T_bk
//
//// using the global constant!
//
//	Variable muP,tmp
//	
//	tmp = kTe*exp(-mu)		//note mu has been moved
//	muP = acosh( (T_he - T_bk)/(T_out - T_bk)  * (1/tmp)) 
//
//	return(muP)
//End
//
//
////
//// calculation of mu.P(t) from Gamma and t=0 value
////
//// Known: Gamma, muP_t0, t0, tn
////
//// times are in hours, Gamma [=] hours
//// tn is later than t0, so t0-tn is negative
////
//// Equation 11
////
//Function V_muP_at_t(Gam_He, muP_t0, t0, tn)
//	Variable Gam_He, muP_t0, t0, tn
//
//	Variable muP
//	
//	muP = muP_t0 * exp( (t0 - tn)/Gam_He )
//	
//	return(muP)
//End
//
//// Calculation of Pcell(t)
//// note that this is a time dependent quantity
////
//// Known: muP(t)
//// Input: nothing additional
////
//// Equation 10
////
//Function V_PCell(muP)
//	Variable muP
//	
//	Variable PCell
//	PCell = tanh(muP)
//	
//	return(PCell)
//End
//
//
//// calculation of Pf (flipper)
////
//// Known: nothing
//// Input: Tuu, Tdu, and Tdd, Tud
////			(but exactly what measurement conditions?)
////			( are these T's also calculated quantities???? -- Equation(s) 12--)
////
//// Equation 14
////
//// (implementation of equation 13 is more complicated, and not implemented yet)
////
//Function V_Flipper_Pf(Tuu, Tdu, Tdd, Tud)
//	Variable Tuu, Tdu, Tdd, Tud
//	
//	Variable pf
//	
//	pf = (Tdd - Tdu)/(Tuu - Tud)
//	
//	return(pf)
//End
//
//
//
//// (this is only one of 4 methods, simply the first one listed)
//// ???? this equation doesn't match up with the equation in the SS handout
////
//// calculation of P'sm (supermirror)
////
//// Known: Pcell(t1), Pcell(t2) (some implementations need Pf )
//// Input: Tuu(t1), Tud(t2)
////
//// Equation 15??
////
//Function V_SupMir_Psm(Pcell1,Pcell2,Tuu,Tud)
//	Variable Pcell1,Pcell2,Tuu,Tud
//	
//	Variable Psm
//	
//	Psm = (Tuu - Tud)/(PCell1 + PCell2)
//	
//	return(Psm)
//End
