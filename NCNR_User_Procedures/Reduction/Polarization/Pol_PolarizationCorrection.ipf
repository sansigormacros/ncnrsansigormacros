#pragma rtGlobals=1		// Use modern global access method.

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
// error propagation was written up elsewhere, and will be implemented as well
// - each of the calculations based on transmissions will need to have errors
// brought in, and carried through the calculations. Some will be simple, some
// will probably be easiest with expansions.
//





// This is a first pass at the input panel (step 3)
// to gather all of the files and conditions necessary to do the polarization correction
//
//

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
// of each file that was added
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
//
// TODO:
// - need a better way of flowing through the process, to be sure that values are set
// as needed and that one step won't fail because a previous step wasn't done yet. Combining the
// first three panels into one w/ tabs would help a lot, but that is rather complex to implement.
// and is still not a fool-proof situation
//
// X- mathod to save and restore the panel state - especially the popup selections
//
// -- should I force the Polarization correction to be re-done just before the protocol is
//			executed? Then I'm sure that the PC is done. Must do for each tab (only if part of the protocol)
//			Except that the procedures work on the "active" tab...
//
// -- When multiple files are added together, there are changes made to the RealsRead (monCts, etc.). Are these
//		properly made, and then properly copied to the "_UU", and then properly copied back to the untagged waves
//		for use in the reduction?
//




// main entry to the PolCor Panel
Proc ShowPolCorSetup()

	Variable restore=0
	DoWindow/F PolCor_Panel
	if(V_flag==0)
	
		InitProtocolPanel()		//this will reset the strings.
		
		restore=Initialize_PolCorPanel()
		PolCor_Panel()
		SetWindow PolCor_Panel hook(kill)=PolCorPanelHook		//to save the state when panel is killed
		//disable the controls on other tabs
		ToggleSelControls("_1_",1)
		ToggleSelControls("_2_",1)
		
		//restore the entries
		if(restore)
			RestorePolCorPanel()
		endif
		

	endif
End


Function RestorePolCorPanel()
	//restore the popup state
	Wave/T/Z w=root:Packages:NIST:Polarization:PolCor_popState

	Variable ii,num
	String name,popStr,list
	
	list = P_GetConditionNameList()		//list of conditions
	if(WaveExists(w))
		num = DimSize(w,0)
		for(ii=0;ii<num;ii+=1)
			name = w[ii][0]
			popStr = w[ii][1]
			if(cmpstr("none",popStr) !=0 )
				PopupMenu $name,win=PolCor_Panel,mode=WhichListItem(popStr, list,";",0,0),popvalue=popStr
			endif
		endfor
	endif
	return(0)
End


//
// TODO:
// X- only re-initialize values if user wants to. maybe ask.
//
Function Initialize_PolCorPanel()


	Variable ii,num
	String name,popStr
		
	DoAlert 1,"Do you want to initialize, wiping out all of your entries?"
	if(V_flag != 1)		//1== yes initialize, so everything else, restore the entries
		return(1)
	endif
	
	//initialize all of the strings for the input
	SetDataFolder root:Packages:NIST:Polarization
	
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
// - 4-panel display (maybe a layout with labels?) Maybe a panel with 4 subwindows. Can I use color bars in them?
//
//
Window PolCor_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(925,44,1662,800) /K=1
	ModifyPanel cbRGB=(64349,63913,44660)
//	ShowTools/A
	SetDrawEnv linethick= 2.00
	DrawLine 10,510,600,510

	TabControl PolCorTab,pos={15,27},size={708,401},proc=PolCorTabProc
	TabControl PolCorTab,tabLabel(0)="SAM",tabLabel(1)="EMP",tabLabel(2)="BGD"
	TabControl PolCorTab,value= 0
	
	// always visible
	Button button0,pos={26,445},size={80,20},proc=LoadRawPolarizedButton,title="Load ..."
	Button button1,pos={26,473},size={130,20},proc=PolCorButton,title="Pol Correct Data"
	Button button2,pos={222,445},size={130,20},proc=ShowPolMatrixButton,title="Show Coef Matrix"
	Button button3,pos={222,473},size={160,20},proc=ChangeDisplayedPolData,title="Change Displayed Data"
	Button button4,pos={620,18},size={30,20},proc=PolCorHelpParButtonProc,title="?"
	Button button12,pos={440,473},size={120,20},proc=Display4XSButton,title="Display 4 XS"
	Button button13,pos={440,446},size={120,20},proc=ClearPolCorEntries,title="Clear Entries"

	PopupMenu popup1,pos={210,24},size={102,20},title="Condition"
	PopupMenu popup1, mode=1,popvalue="none",value= #"P_GetConditionNameList()"

	TitleBox title0,pos={100,66},size={24,24},title="\\f01UU or + +",fSize=12
	TitleBox title1,pos={430,66},size={24,24},title="\\f01DU or - +",fSize=12
	TitleBox title2,pos={100,250},size={25,24},title="\\f01DD or - -",fSize=12
	TitleBox title3,pos={430,250},size={24,24},title="\\f01UD or + -",fSize=12
	
	// bits to set up reduction protocol
	Button button5,pos={126,560},size={100,20},proc=PickDIVButton,title="set DIV file"
	Button button5,help={"This button will set the file selected in the File Catalog table to be the sensitivity file."}
	Button button6,pos={126,590},size={100,20},proc=PickMASKButton,title="set MASK file"
	Button button6,help={"This button will set the file selected in the File Catalog table to be the mask file."}
	Button button7,pos={126,620},size={110,20},proc=SetABSParamsButton,title="set ABS params"
	Button button7,help={"This button will prompt the user for absolute scaling parameters"}
	Button button8,pos={126,650},size={150,20},proc=SetAverageParamsButtonProc,title="set AVERAGE params"
	Button button8,help={"Prompts the user for the type of 1-D averaging to perform, as well as saving options"}
	Button button9,pos={80,690},size={120,20},proc=ReducePolCorDataButton,title="Reduce Data"
	Button button9,help={"Reduce PolCor data"}
	Button button10,pos={226,690},size={120,20},proc=SavePolCorProtocolButton,title="Save Protocol"
	Button button10,help={"Save the PolCor protocol"}
	Button button11,pos={370,690},size={120,20},proc=RecallPolCorProtocolButton,title="Recall Protocol"
	Button button11,help={"Recall the PolCor protocol"}		
	
	SetVariable setvar0,pos={322,560},size={250,15},title="file:"
	SetVariable setvar0,help={"Filename of the detector sensitivity file to be used in the data reduction"}
	SetVariable setvar0,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gDIV
	SetVariable setvar1,pos={322,590},size={250,15},title="file:"
	SetVariable setvar1,help={"Filename of the mask file to be used in the data reduction"}
	SetVariable setvar1,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gMASK
	SetVariable setvar2,pos={322,620},size={250,15},title="parameters:"
	SetVariable setvar2,help={"Keyword-string of values necessary for absolute scaling of data. Remaining parameters are taken from the sample file."}
	SetVariable setvar2,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gAbsStr	
	SetVariable setvar3,pos={322,650},size={250,15},title="parameters:"
	SetVariable setvar3,help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
	SetVariable setvar3,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gAVE	
	
	CheckBox check0,pos={10,560},size={72,14},title="Sensitivity"
	CheckBox check0,help={"If checked, the specified detector sensitivity file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox check0,value= 1
	CheckBox check1,pos={10,590},size={72,14},title="Mask"
	CheckBox check1,help={""}
	CheckBox check1,value= 1
	CheckBox check2,pos={10,620},size={72,14},title="Absolute Scale"
	CheckBox check2,help={""}
	CheckBox check2,value= 1
	CheckBox check3,pos={10,650},size={72,14},title="Average and Save"
	CheckBox check3,help={""}
	CheckBox check3,value= 1		
	CheckBox check4,pos={10,530},size={72,14},title="Use EMP?"
	CheckBox check4,help={""}
	CheckBox check4,value= 1	
	CheckBox check5,pos={100,530},size={72,14},title="Use BGD?"
	CheckBox check5,help={""}
	CheckBox check5,value= 1	

	

// SAM Tab	
	// UU
	ListBox ListBox_0_UU,pos={34,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_UU,listWave=root:Packages:NIST:Polarization:ListWave_0_UU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_0_UU,selWave=root:Packages:NIST:Polarization:lbSelWave_0_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_0_UU_0,pos={34,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_0
//	SetVariable setvar_0_UU_1,pos={34,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_1
//	SetVariable setvar_0_UU_2,pos={34,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_2
//	SetVariable setvar_0_UU_3,pos={34,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_3
//	SetVariable setvar_0_UU_4,pos={34,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_4
//	PopupMenu popup_0_UU_0,pos={142,99},size={210,20},title="Cell"
//	PopupMenu popup_0_UU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UU_1,pos={142,122},size={102,20},title="Cell"
//	PopupMenu popup_0_UU_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UU_2,pos={142,146},size={102,20},title="Cell"
//	PopupMenu popup_0_UU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UU_3,pos={142,170},size={102,20},title="Cell"
//	PopupMenu popup_0_UU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UU_4,pos={142,194},size={102,20},title="Cell"
//	PopupMenu popup_0_UU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

	// DU
	ListBox ListBox_0_DU,pos={368,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_DU,listWave=root:Packages:NIST:Polarization:ListWave_0_DU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_0_DU,selWave=root:Packages:NIST:Polarization:lbSelWave_0_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_0_DU_0,pos={368,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_0
//	SetVariable setvar_0_DU_1,pos={368,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_1
//	SetVariable setvar_0_DU_2,pos={368,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_2
//	SetVariable setvar_0_DU_3,pos={368,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_3
//	SetVariable setvar_0_DU_4,pos={368,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_4
//	PopupMenu popup_0_DU_0,pos={476,99},size={210,20},title="Cell"
//	PopupMenu popup_0_DU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DU_1,pos={476,122},size={210,20},title="Cell"
//	PopupMenu popup_0_DU_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DU_2,pos={476,146},size={102,20},title="Cell"
//	PopupMenu popup_0_DU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DU_3,pos={476,170},size={102,20},title="Cell"
//	PopupMenu popup_0_DU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DU_4,pos={476,194},size={102,20},title="Cell"
//	PopupMenu popup_0_DU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

// DD
	ListBox ListBox_0_DD,pos={33,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_DD,listWave=root:Packages:NIST:Polarization:ListWave_0_DD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_0_DD,selWave=root:Packages:NIST:Polarization:lbSelWave_0_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_0_DD_0,pos={33,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_0
//	SetVariable setvar_0_DD_1,pos={33,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_1
//	SetVariable setvar_0_DD_2,pos={33,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_2
//	SetVariable setvar_0_DD_3,pos={33,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_3
//	SetVariable setvar_0_DD_4,pos={33,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_DD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_4
//	PopupMenu popup_0_DD_0,pos={141,283},size={210,20},title="Cell"
//	PopupMenu popup_0_DD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DD_1,pos={141,306},size={102,20},title="Cell"
//	PopupMenu popup_0_DD_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DD_2,pos={141,330},size={102,20},title="Cell"
//	PopupMenu popup_0_DD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DD_3,pos={141,354},size={102,20},title="Cell"
//	PopupMenu popup_0_DD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_DD_4,pos={141,378},size={102,20},title="Cell"
//	PopupMenu popup_0_DD_4,mode=1,popvalue="none",value= #"D_CellNameList()"
	
// UD
	ListBox ListBox_0_UD,pos={368,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_0_UD,listWave=root:Packages:NIST:Polarization:ListWave_0_UD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_0_UD,selWave=root:Packages:NIST:Polarization:lbSelWave_0_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_0_UD_0,pos={368,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_0
//	SetVariable setvar_0_UD_1,pos={368,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_1
//	SetVariable setvar_0_UD_2,pos={368,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_2
//	SetVariable setvar_0_UD_3,pos={368,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_3
//	SetVariable setvar_0_UD_4,pos={368,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_0_UD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_4
//	PopupMenu popup_0_UD_0,pos={476,283},size={210,20},title="Cell"
//	PopupMenu popup_0_UD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UD_1,pos={476,306},size={210,20},title="Cell"
//	PopupMenu popup_0_UD_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UD_2,pos={476,330},size={102,20},title="Cell"
//	PopupMenu popup_0_UD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UD_3,pos={476,354},size={102,20},title="Cell"
//	PopupMenu popup_0_UD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_0_UD_4,pos={476,378},size={102,20},title="Cell"
//	PopupMenu popup_0_UD_4,mode=1,popvalue="none",value= #"D_CellNameList()"


// EMP Tab	
	// UU
	ListBox ListBox_1_UU,pos={34,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_UU,listWave=root:Packages:NIST:Polarization:ListWave_1_UU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_1_UU,selWave=root:Packages:NIST:Polarization:lbSelWave_1_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_1_UU_0,pos={34,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UU_0
//	SetVariable setvar_1_UU_1,pos={34,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UU_1
//	SetVariable setvar_1_UU_2,pos={34,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UU_2
//	SetVariable setvar_1_UU_3,pos={34,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UU_3
//	SetVariable setvar_1_UU_4,pos={34,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UU_4
//	PopupMenu popup_1_UU_0,pos={142,99},size={210,20},title="Cell"
//	PopupMenu popup_1_UU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UU_1,pos={142,122},size={102,20},title="Cell"
//	PopupMenu popup_1_UU_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UU_2,pos={142,146},size={102,20},title="Cell"
//	PopupMenu popup_1_UU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UU_3,pos={142,170},size={102,20},title="Cell"
//	PopupMenu popup_1_UU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UU_4,pos={142,194},size={102,20},title="Cell"
//	PopupMenu popup_1_UU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

	// DU
	ListBox ListBox_1_DU,pos={368,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_DU,listWave=root:Packages:NIST:Polarization:ListWave_1_DU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_1_DU,selWave=root:Packages:NIST:Polarization:lbSelWave_1_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_1_DU_0,pos={368,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DU_0
//	SetVariable setvar_1_DU_1,pos={368,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DU_1
//	SetVariable setvar_1_DU_2,pos={368,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DU_2
//	SetVariable setvar_1_DU_3,pos={368,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DU_3
//	SetVariable setvar_1_DU_4,pos={368,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DU_4
//	PopupMenu popup_1_DU_0,pos={476,99},size={210,20},title="Cell"
//	PopupMenu popup_1_DU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DU_1,pos={476,122},size={210,20},title="Cell"
//	PopupMenu popup_1_DU_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DU_2,pos={476,146},size={102,20},title="Cell"
//	PopupMenu popup_1_DU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DU_3,pos={476,170},size={102,20},title="Cell"
//	PopupMenu popup_1_DU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DU_4,pos={476,194},size={102,20},title="Cell"
//	PopupMenu popup_1_DU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

// DD
	ListBox ListBox_1_DD,pos={33,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_DD,listWave=root:Packages:NIST:Polarization:ListWave_1_DD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_1_DD,selWave=root:Packages:NIST:Polarization:lbSelWave_1_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_1_DD_0,pos={33,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DD_0
//	SetVariable setvar_1_DD_1,pos={33,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DD_1
//	SetVariable setvar_1_DD_2,pos={33,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DD_2
//	SetVariable setvar_1_DD_3,pos={33,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DD_3
//	SetVariable setvar_1_DD_4,pos={33,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_DD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_DD_4
//	PopupMenu popup_1_DD_0,pos={141,283},size={210,20},title="Cell"
//	PopupMenu popup_1_DD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DD_1,pos={141,306},size={102,20},title="Cell"
//	PopupMenu popup_1_DD_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DD_2,pos={141,330},size={102,20},title="Cell"
//	PopupMenu popup_1_DD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DD_3,pos={141,354},size={102,20},title="Cell"
//	PopupMenu popup_1_DD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_DD_4,pos={141,378},size={102,20},title="Cell"
//	PopupMenu popup_1_DD_4,mode=1,popvalue="none",value= #"D_CellNameList()"

// UD
	ListBox ListBox_1_UD,pos={368,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_1_UD,listWave=root:Packages:NIST:Polarization:ListWave_1_UD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_1_UD,selWave=root:Packages:NIST:Polarization:lbSelWave_1_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_1_UD_0,pos={368,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UD_0
//	SetVariable setvar_1_UD_1,pos={368,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UD_1
//	SetVariable setvar_1_UD_2,pos={368,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UD_2
//	SetVariable setvar_1_UD_3,pos={368,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UD_3
//	SetVariable setvar_1_UD_4,pos={368,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_1_UD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_1_UD_4
//	PopupMenu popup_1_UD_0,pos={476,283},size={210,20},title="Cell"
//	PopupMenu popup_1_UD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UD_1,pos={476,306},size={210,20},title="Cell"
//	PopupMenu popup_1_UD_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UD_2,pos={476,330},size={102,20},title="Cell"
//	PopupMenu popup_1_UD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UD_3,pos={476,354},size={102,20},title="Cell"
//	PopupMenu popup_1_UD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_1_UD_4,pos={476,378},size={102,20},title="Cell"
//	PopupMenu popup_1_UD_4,mode=1,popvalue="none",value= #"D_CellNameList()"


// BKG Tab	
	// UU
	ListBox ListBox_2_UU,pos={34,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_2_UU,listWave=root:Packages:NIST:Polarization:ListWave_2_UU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_2_UU,selWave=root:Packages:NIST:Polarization:lbSelWave_2_UU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_2_UU_0,pos={34,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UU_0
//	SetVariable setvar_2_UU_1,pos={34,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UU_1
//	SetVariable setvar_2_UU_2,pos={34,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UU_2
//	SetVariable setvar_2_UU_3,pos={34,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UU_3
//	SetVariable setvar_2_UU_4,pos={34,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UU_4
//	PopupMenu popup_2_UU_0,pos={142,99},size={210,20},title="Cell"
//	PopupMenu popup_2_UU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UU_1,pos={142,122},size={102,20},title="Cell"
//	PopupMenu popup_2_UU_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UU_2,pos={142,146},size={102,20},title="Cell"
//	PopupMenu popup_2_UU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UU_3,pos={142,170},size={102,20},title="Cell"
//	PopupMenu popup_2_UU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UU_4,pos={142,194},size={102,20},title="Cell"
//	PopupMenu popup_2_UU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

	// DU
	ListBox ListBox_2_DU,pos={368,102},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_2_DU,listWave=root:Packages:NIST:Polarization:ListWave_2_DU,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_2_DU,selWave=root:Packages:NIST:Polarization:lbSelWave_2_DU,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_2_DU_0,pos={368,102},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DU_0
//	SetVariable setvar_2_DU_1,pos={368,125},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DU_1
//	SetVariable setvar_2_DU_2,pos={368,149},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DU_2
//	SetVariable setvar_2_DU_3,pos={368,173},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DU_3
//	SetVariable setvar_2_DU_4,pos={368,197},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DU_4
//	PopupMenu popup_2_DU_0,pos={476,99},size={210,20},title="Cell"
//	PopupMenu popup_2_DU_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DU_1,pos={476,122},size={210,20},title="Cell"
//	PopupMenu popup_2_DU_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DU_2,pos={476,146},size={102,20},title="Cell"
//	PopupMenu popup_2_DU_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DU_3,pos={476,170},size={102,20},title="Cell"
//	PopupMenu popup_2_DU_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DU_4,pos={476,194},size={102,20},title="Cell"
//	PopupMenu popup_2_DU_4,mode=1,popvalue="none",value= #"D_CellNameList()"

// DD
	ListBox ListBox_2_DD,pos={33,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_2_DD,listWave=root:Packages:NIST:Polarization:ListWave_2_DD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_2_DD,selWave=root:Packages:NIST:Polarization:lbSelWave_2_DD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_2_DD_0,pos={33,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DD_0
//	SetVariable setvar_2_DD_1,pos={33,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DD_1
//	SetVariable setvar_2_DD_2,pos={33,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DD_2
//	SetVariable setvar_2_DD_3,pos={33,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DD_3
//	SetVariable setvar_2_DD_4,pos={33,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_DD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_DD_4
//	PopupMenu popup_2_DD_0,pos={141,283},size={210,20},title="Cell"
//	PopupMenu popup_2_DD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DD_1,pos={141,306},size={102,20},title="Cell"
//	PopupMenu popup_2_DD_1,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DD_2,pos={141,330},size={102,20},title="Cell"
//	PopupMenu popup_2_DD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DD_3,pos={141,354},size={102,20},title="Cell"
//	PopupMenu popup_2_DD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_DD_4,pos={141,378},size={102,20},title="Cell"
//	PopupMenu popup_2_DD_4,mode=1,popvalue="none",value= #"D_CellNameList()"

// UD
	ListBox ListBox_2_UD,pos={368,286},size={200,130},proc=PolCor_FileListBoxProc,frame=2
	ListBox ListBox_2_UD,listWave=root:Packages:NIST:Polarization:ListWave_2_UD,titleWave=root:Packages:NIST:Polarization:lbTitles
	ListBox ListBox_2_UD,selWave=root:Packages:NIST:Polarization:lbSelWave_2_UD,mode= 6,selRow= 0,selCol= 0,editStyle= 2
//	SetVariable setvar_2_UD_0,pos={368,286},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UD_0
//	SetVariable setvar_2_UD_1,pos={368,309},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UD_1
//	SetVariable setvar_2_UD_2,pos={368,333},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UD_2
//	SetVariable setvar_2_UD_3,pos={368,357},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UD_3
//	SetVariable setvar_2_UD_4,pos={368,381},size={70,16},title="File",fSize=10
//	SetVariable setvar_2_UD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_2_UD_4
//	PopupMenu popup_2_UD_0,pos={476,283},size={210,20},title="Cell"
//	PopupMenu popup_2_UD_0,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UD_1,pos={476,306},size={210,20},title="Cell"
//	PopupMenu popup_2_UD_1,mode=3,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UD_2,pos={476,330},size={102,20},title="Cell"
//	PopupMenu popup_2_UD_2,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UD_3,pos={476,354},size={102,20},title="Cell"
//	PopupMenu popup_2_UD_3,mode=1,popvalue="none",value= #"D_CellNameList()"
//	PopupMenu popup_2_UD_4,pos={476,378},size={102,20},title="Cell"
//	PopupMenu popup_2_UD_4,mode=1,popvalue="none",value= #"D_CellNameList()"

EndMacro

// action procedure for the list box that allows the popup menu
// -- much easier to make a contextual popup with a list box than on a table/subwindow hook
//
Function PolCor_FileListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			if (lba.col == 1)											// cell list
//				SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
//				SelWave[][s.col][0] = SelWave[p][s.col] | 1				// select all rows
//				ControlUpdate/W=$(s.win) $(s.ctrlName)
				PopupContextualMenu D_CellNameList()
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
Function PolCorPanelHook(s)
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
			popList=ControlNameList("PolCor_Panel",";","popup*")
			num=ItemsInList(popList,";")
			Make/O/T/N=(num,2) root:Packages:NIST:Polarization:PolCor_popState
			Wave/T w=root:Packages:NIST:Polarization:PolCor_popState
			for(ii=0;ii<num;ii+=1)
				item=StringFromList(ii, popList,";")
				ControlInfo/W=PolCor_Panel $item
				w[ii][0] = item
				w[ii][1] = S_Value
			endfor

			break

	endswitch

	return hookResult		// 0 if nothing done, else 1
End

// val = 1 to disable
// val = 0 to show
Function ToggleSelControls(str,val)
	String str
	Variable val
	
	String listStr
	listStr = ControlNameList("PolCor_Panel", ";", "*"+str+"*")
//	print listStr
	
	ModifyControlList/Z listStr  , disable=(val)
	return(0)
end


Function PolCorTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab		
			Variable val
//			Print "Selected tab = ",tab
			
			val = (tab != 0)
//			Print "tab 0 val = ",val
			ToggleSelControls("_0_",val)
			
			val = (tab != 1)
//			Print "tab 1 val = ",val
			ToggleSelControls("_1_",val)
			
			val = (tab != 2)
//			Print "tab 2 val = ",val
			ToggleSelControls("_2_",val)
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function PolCorHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"Help for PolCor Panel not written yet"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// loads the specified type of data (SAM, EMP, BGD) based on the active tab
// loads either specified spin type or all four
// (( now, defaults to trying to load ALL four data spin states ))
// 		- I'll have to fix this later if only 2 of the four are needed
//  -- during loading, the proper row of the PolMatrix is filled, based on pType
//
// then after all data is loaded:
// 		-the inverse Inv_PolMatrix is calculated
//		-the error in the PolMatrix is calculated
//		-the error in Inv_PolMatrix is calculated
//
Function LoadRawPolarizedButton(ba) : ButtonControl
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
				LoadPolarizedData("UU")
				LoadPolarizedData("DU")
				LoadPolarizedData("DD")
				LoadPolarizedData("UD")
			else
				LoadPolarizedData(pType)
			endif
			
			String type
			Variable row,col,flag=1
			Variable ii,jj,aa,bb
			
// The PolMatrix is filled on loading the data sets
// once all files are added, take the SQRT of the error matrix
// now calculate its inverse
// -- first checking to be sure that no rows are zero - this will result in a singular matrix otherwise		
			ControlInfo/W=PolCor_Panel PolCorTab
			type = S_value
			WAVE matA = $("root:Packages:NIST:"+type+":PolMatrix")
			WAVE matA_err = $("root:Packages:NIST:"+type+":PolMatrix_err")
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
				SetDataFolder $("root:Packages:NIST:"+type)
				MatrixInverse/G matA
				Duplicate/O M_Inverse Inv_PolMatrix
				
				// now calculate the error of the inverse matrix
				Duplicate/O Inv_PolMatrix Inv_PolMatrix_err
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
// -the PolMatrix of coefficients is filled (the specified row)
//
// TODO:
// X- pre-parsing is not done to check for valid file numbers. This should be done gracefully.
// X- SAM folder is currently hard-wired
// X- if all of the conditions are "none" - stop and report the error
//
Function LoadPolarizedData(pType)
	String pType


	String listStr="",runList="",parsedRuns,condStr
	Variable ii,num,err,row
			
	// get the current tab
	String type,runStr,cellStr
	Variable tabNum
	ControlInfo/W=PolCor_Panel PolCorTab
	type = S_value
	Print "selected data type = ",type
	tabNum = V_Value
	
	
	// get a list of the file numbers to load, must be in proper data folder
	SetDataFolder root:Packages:NIST:Polarization
//			Print "Searching  "+"gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*"
//	listStr = StringList("gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*", ";" )

	Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+pType)
	num = DimSize(lb,0)		//should be 10, as initialized
	
	// if the condition (for all of the sets) is "none", get out
	ControlInfo/W=PolCor_Panel popup1
	condStr = S_Value
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
	parsedRuns =ParseRunNumberList(runlist)
	if(strlen(parsedRuns) == 0)
		Print "enter a valid file number before proceeding"
		SetDataFolder root:
		return(0)
	endif
	SetDataFolder root:

	
	// find time midpoint for the files to load
	Variable tMid
	tMid = getTimeMidpoint(runList)
	Print/D "time midpoint",tmid
	
	// this adds multiple raw data files, as specified by the list
	err = AddFilesInList(type,parsedRuns)		// adds to a work file = type, not RAW
	UpdateDisplayInformation(type)
	
	TagLoadedData(type,pType)		//see also DisplayTaggedData()
	
	// now add the appropriate bits to the matrix
	if(!WaveExists($("root:Packages:NIST:"+type+":PolMatrix")))
		Make/O/D/N=(4,4) $("root:Packages:NIST:"+type+":PolMatrix")
		Make/O/D/N=(4,4) $("root:Packages:NIST:"+type+":PolMatrix_err")
	endif
	WAVE matA = $("root:Packages:NIST:"+type+":PolMatrix")
	WAVE matA_err = $("root:Packages:NIST:"+type+":PolMatrix_err")

//			listStr = ControlNameList("PolCor_Panel",";","*"+pType+"*")

	//This loops over all of the files and adds the coefficients to the PolMatrix
	// the PolMatrix rows are cleared on pass 0 as each pType data is loaded.
	// this way repeated loading will always result in the correct fill
	// returns the error matrix as the squared error (take sqrt in calling function)		
	AddToPolMatrix(matA,matA_err,pType,tMid)


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
// -- check all of the math
// not yet using the midpoint time
//
// -- the PolMatrix_err returned from here is the squared error!
//
Function AddToPolMatrix(matA,matA_err,pType,tMid)
	Wave matA,matA_err
	String pType
	Variable tMid
	
	Variable row,Psm, PsmPf, PCell,err_Psm, err_PsmPf, err_PCell
	Variable ii,jj,muPo,err_muPo,gam,err_gam,monCts,t1,num,fileCount

	Variable ea_uu, ea_ud, ea_dd, ea_du
	Variable ec_uu, ec_ud, ec_dd, ec_du
	
	String listStr,fname="",condStr,condNote,decayNote,cellStr,t0Str,t1Str,runStr

	// get the current tab
	String type
	Variable tabNum
	ControlInfo/W=PolCor_Panel PolCorTab
	type = S_value
	Print "selected data type = ",type
	tabNum = V_Value
	
	SetDataFolder root:Packages:NIST:Polarization
//	listStr = StringList("gStr_PolCor_"+num2str(tabNum)+"_*"+pType+"*", ";" )


	Wave/T lb=$("ListWave_"+num2str(tabNum)+"_"+pType)
	num = DimSize(lb,0)		//should be 10, as initialized
	
	// if the condition (for all of the sets) is "none", get out
	ControlInfo/W=PolCor_Panel popup1
	condStr = S_Value
	if(cmpstr(condStr, "none" ) == 0)
		DoAlert 0,"Condition is not set."
		SetDataFolder root:
		return(0)
	endif
	
	Wave condition = $("root:Packages:NIST:Polarization:Cells:"+condStr)
	// get wave note from condition
	condNote = note(condition)
	// get P's from note
	Psm = NumberByKey("P_sm", condNote, "=", ",", 0)
	PsmPf = NumberByKey("P_sm_f", condNote, "=", ",", 0)
	err_Psm = NumberByKey("err_P_sm", condNote, "=", ",", 0)
	err_PsmPf = NumberByKey("err_P_sm_f", condNote, "=", ",", 0)


	// loop over the (10) rows in the listWave
	fileCount=0
	for(ii=0;ii<num;ii+=1)
		runStr = 	lb[ii][0]		//the run number
		if(cmpstr(runStr, "" ) != 0)
		
			fileCount += 1		//one more file is added
			// get run number (str)
			// get file name
			fname = FindFileFromRunNumber(str2num(runStr))
		
			// get the cell string to get the Decay wave
			cellStr = lb[ii][1]
//			print "Cell = ",cellStr
			// get info to calc Pcell (from the Decay wave)
			Wave decay = $("root:Packages:NIST:Polarization:Cells:Decay_"+cellStr)	
			decayNote=note(decay)
		
			t0Str = StringByKey("T0", decayNote, "=", ",", 0)
			muPo = NumberByKey("muP", decayNote, "=", ",", 0)
			err_muPo = NumberByKey("err_muP", decayNote, "=", ",", 0)
			gam = NumberByKey("gamma", decayNote, "=", ",", 0)
			err_gam = NumberByKey("err_gamma", decayNote, "=", ",", 0)
			// get the elapsed time to calculate PCell at the current file time
			t1str = getFileCreationDate(fname)
			t1 = ElapsedHours(t0Str,t1Str)
			
			PCell = Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell)
			
			// get file info (monitor counts)
			monCts = getMonitorCount(fname)
			monCts /= 1e8		//to get a normalized value to add proportionally
			
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
					ea_uu = (1+Psm)/2
					ea_du = (1-Psm)/2
					ec_uu = (1+Pcell)/2
					ec_du = (1-Pcell)/2
					
					matA[row][0] += ea_uu*ec_uu*monCts
					matA[row][1] += ea_du*ec_uu*monCts
					matA[row][2] += ea_du*ec_du*monCts
					matA[row][3] += ea_uu*ec_du*monCts

// this seems to be too large...
//					matA_err[row][0] += (1/2*ec_uu*monCts)^2*err_Psm^2 + (1/2*ea_uu*monCts)^2*err_Pcell^2
//					matA_err[row][1] += (1/2*ec_uu*monCts)^2*err_Psm^2 + (1/2*ea_du*monCts)^2*err_Pcell^2
//					matA_err[row][2] += (1/2*ec_du*monCts)^2*err_Psm^2 + (1/2*ea_du*monCts)^2*err_Pcell^2
//					matA_err[row][3] += (1/2*ec_du*monCts)^2*err_Psm^2 + (1/2*ea_uu*monCts)^2*err_Pcell^2

					matA_err[row][0] += (ea_uu*ec_uu*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][1] += (ea_du*ec_uu*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][2] += (ea_du*ec_du*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][3] += (ea_uu*ec_du*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
										
					break
				case "DU":		
					row = 1
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
					ea_ud = (1-PsmPf)/2
					ea_dd = (1+PsmPf)/2
					ec_uu = (1+Pcell)/2
					ec_du = (1-Pcell)/2
					
					matA[row][0] += ea_ud*ec_uu*monCts
					matA[row][1] += ea_dd*ec_uu*monCts
					matA[row][2] += ea_dd*ec_du*monCts
					matA[row][3] += ea_ud*ec_du*monCts
					
//					matA_err[row][0] += (1/2*(1+Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1-PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][1] += (1/2*(1+Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1+PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][2] += (1/2*(1-Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1+PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][3] += (1/2*(1-Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1-PsmPf)/2*monCts)^2*err_Pcell^2					

					matA_err[row][0] += (ea_ud*ec_uu*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][1] += (ea_dd*ec_uu*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][2] += (ea_dd*ec_du*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][3] += (ea_ud*ec_du*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
							
					break	
				case "DD":		
					row = 2
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
					ea_ud = (1-PsmPf)/2
					ea_dd = (1+PsmPf)/2
					ec_ud = (1-Pcell)/2
					ec_dd = (1+Pcell)/2
					
					matA[row][0] += ea_ud*ec_ud*monCts
					matA[row][1] += ea_dd*ec_ud*monCts
					matA[row][2] += ea_dd*ec_dd*monCts
					matA[row][3] += ea_ud*ec_dd*monCts					
					
//					matA_err[row][0] += (1/2*(1-Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1-PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][1] += (1/2*(1-Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1+PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][2] += (1/2*(1+Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1+PsmPf)/2*monCts)^2*err_Pcell^2
//					matA_err[row][3] += (1/2*(1+Pcell)/2*monCts)^2*err_PsmPf^2 + (1/2*(1-PsmPf)/2*monCts)^2*err_Pcell^2	

					matA_err[row][0] += (ea_ud*ec_ud*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][1] += (ea_dd*ec_ud*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][2] += (ea_dd*ec_dd*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
					matA_err[row][3] += (ea_ud*ec_dd*monCts)^2 * (err_PsmPf^2/PsmPf^2 + err_Pcell^2/Pcell^2)
										
					break						
				case "UD":		
					row = 3
					if(ii==0)
						matA[row][] = 0
						matA_err[row][] = 0
					endif
					ea_uu = (1+Psm)/2
					ea_du = (1-Psm)/2
					ec_ud = (1-Pcell)/2
					ec_dd = (1+Pcell)/2
					
					matA[row][0] += ea_uu*ec_ud*monCts
					matA[row][1] += ea_du*ec_ud*monCts
					matA[row][2] += ea_du*ec_dd*monCts
					matA[row][3] += ea_uu*ec_dd*monCts					
										
//					matA_err[row][0] += (1/2*(1-Pcell)/2*monCts)^2*err_Psm^2 + (1/2*(1+Psm)/2*monCts)^2*err_Pcell^2
//					matA_err[row][1] += (1/2*(1-Pcell)/2*monCts)^2*err_Psm^2 + (1/2*(1-Psm)/2*monCts)^2*err_Pcell^2
//					matA_err[row][2] += (1/2*(1+Pcell)/2*monCts)^2*err_Psm^2 + (1/2*(1-Psm)/2*monCts)^2*err_Pcell^2
//					matA_err[row][3] += (1/2*(1+Pcell)/2*monCts)^2*err_Psm^2 + (1/2*(1+Psm)/2*monCts)^2*err_Pcell^2					

					matA_err[row][0] += (ea_uu*ec_ud*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][1] += (ea_du*ec_ud*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][2] += (ea_du*ec_dd*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
					matA_err[row][3] += (ea_uu*ec_dd*monCts)^2 * (err_Psm^2/Psm^2 + err_Pcell^2/Pcell^2)
										
					break
			endswitch

			
		endif
	endfor
	
// can't take the SQRT here, since the matrix won't necessarily be full yet, 
	
// but now need to re-normalize the row based on the number of files that were added
// pType has only one value as passed in, so the row has already been set. It would be more correct
// to switch based on pType...
	
	matA[row][0] /= fileCount
	matA[row][1] /= fileCount
	matA[row][2] /= fileCount
	matA[row][3] /= fileCount	
	
	matA_err[row][0] /= fileCount
	matA_err[row][1] /= fileCount
	matA_err[row][2] /= fileCount
	matA_err[row][3] /= fileCount	
				
	SetDataFolder root:
	return(0)
End


// duplicate the correct waves for use as the PolCor result
// lots of extra waves, but it makes things easier down the road
// type is the data folder (=SAM, etc)
// pType is the pol extension (=UU, etc.)
Function MakePCResultWaves(type,pType)
	String type,pType

	ptype = "_" + pType			// add an extra underscore
	String pcExt = "_pc"
	String destPath = "root:Packages:NIST:" + type
	Duplicate/O $(destPath + ":data"+pType), $(destPath + ":data"+pType+pcExt)
	Duplicate/O $(destPath + ":linear_data"+pType),$(destPath + ":linear_data"+pType+pcExt)
	Duplicate/O $(destPath + ":linear_data_error"+pType),$(destPath + ":linear_data_error"+pType+pcExt)
	Duplicate/O $(destPath + ":textread"+pType),$(destPath + ":textread"+pType+pcExt)
	Duplicate/O $(destPath + ":integersread"+pType),$(destPath + ":integersread"+pType+pcExt)
	Duplicate/O $(destPath + ":realsread"+pType),$(destPath + ":realsread"+pType+pcExt)
	
	return(0)
End


// a function to tag the data in a particular folder with the UD state
Function TagLoadedData(type,pType)
	String type,pType

	ConvertFolderToLinearScale(type)

	ptype = "_" + pType			// add an extra underscore
	String destPath = "root:Packages:NIST:" + type
	Duplicate/O $(destPath + ":data"), $(destPath + ":data"+pType)
	Duplicate/O $(destPath + ":linear_data"),$(destPath + ":linear_data"+pType)
	Duplicate/O $(destPath + ":linear_data_error"),$(destPath + ":linear_data_error"+pType)
	Duplicate/O $(destPath + ":textread"),$(destPath + ":textread"+pType)
	Duplicate/O $(destPath + ":integersread"),$(destPath + ":integersread"+pType)
	Duplicate/O $(destPath + ":realsread"),$(destPath + ":realsread"+pType)
	
	return(0)
End


// a procedure (easier than a function) to point the current data to the tagged data
Proc DisplayTaggedData(type,pType)
	String type="SAM",pType="UU"

	String/G root:myGlobals:gDataDisplayType=type
	ConvertFolderToLinearScale(type)
	
	ptype = "_" + pType			// add an extra underscore
	String destPath = "root:Packages:NIST:" + type
	$(destPath + ":linear_data") = $(destPath + ":linear_data"+pType)
	$(destPath + ":linear_data_error") = $(destPath + ":linear_data_error"+pType)
	$(destPath + ":textread") = $(destPath + ":textread"+pType)
	$(destPath + ":integersread") = $(destPath + ":integersread"+pType)
	$(destPath + ":realsread") = $(destPath + ":realsread"+pType)

// make the data equal to linear data
	$(destPath + ":data") = $(destPath + ":linear_data"+pType)

	UpdateDisplayInformation(type)
// using fRawWindowHook() gets the log/lin correct
//	fRawWindowHook()


End


// this takes the 4 loaded experimental cross sections, and solves for the 
// polarization corrected result.
//
// exp cross sections have _UU extensions
// polCor result has _UU_pc
//
//
Function PolCorButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Variable ii,jj,numRows,numCols,row,kk
			
			// get the current tab
			String type
			Variable tabNum
			ControlInfo/W=PolCor_Panel PolCorTab
			type = S_value
			Print "selected data type = ",type
			tabNum = V_Value
			
			// make waves for the result
			// these duplicate the data and add "_pc" for later use
			// linear_data_error_UU_pc etc. are created
			MakePCResultWaves(type,"UU")
			MakePCResultWaves(type,"DU")
			MakePCResultWaves(type,"DD")
			MakePCResultWaves(type,"UD")
			
			
			SetDataFolder $("root:Packages:NIST:"+type)

// the linear data and its errors, declare and initialize			
			WAVE linear_data_UU_pc = linear_data_UU_pc
			WAVE linear_data_DU_pc = linear_data_DU_pc
			WAVE linear_data_DD_pc = linear_data_DD_pc
			WAVE linear_data_UD_pc = linear_data_UD_pc
			WAVE linear_data_error_UU_pc = linear_data_error_UU_pc
			WAVE linear_data_error_DU_pc = linear_data_error_DU_pc
			WAVE linear_data_error_DD_pc = linear_data_error_DD_pc
			WAVE linear_data_error_UD_pc = linear_data_error_UD_pc
						
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
			WAVE matA = $("root:Packages:NIST:"+type+":PolMatrix")
			WAVE linear_data_UU = linear_data_UU
			WAVE linear_data_DU = linear_data_DU
			WAVE linear_data_DD = linear_data_DD
			WAVE linear_data_UD = linear_data_UD

// everything needed for the error calculation
// the PolMatrix error matrices
// and the data error
			WAVE inv = Inv_PolMatrix
			WAVE inv_err = Inv_PolMatrix_err			
			WAVE linear_data_error_UU = linear_data_error_UU
			WAVE linear_data_error_DU = linear_data_error_DU
			WAVE linear_data_error_DD = linear_data_error_DD
			WAVE linear_data_error_UD = linear_data_error_UD			
			
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
			
			
			//update the data as log of the linear. more correct to use the default scaling
			// this is necessary for proper display of the data
			WAVE data_UU_pc = data_UU_pc
			WAVE data_DU_pc = data_DU_pc
			WAVE data_DD_pc = data_DD_pc
			WAVE data_UD_pc = data_UD_pc
			data_UU_pc = log(linear_data_UU_pc)
			data_DU_pc = log(linear_data_DU_pc)
			data_DD_pc = log(linear_data_DD_pc)
			data_UD_pc = log(linear_data_UD_pc)
			
			
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
Function Display4XSButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String dataType,pType,str,scaling
			Prompt dataType,"Display WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;"
//			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;UU_pc;DU_pc;DD_pc;UD_pc;"
			Prompt scaling,"scaling",popup,"log;linear;"
			DoPrompt "Change Display",dataType,scaling
			
			Display_4(dataType,scaling)
			
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
Function ChangeDisplayedPolData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String dataType,pType,str
			Prompt dataType,"Display WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;"
			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;UU_pc;DU_pc;DD_pc;UD_pc;"
			DoPrompt "Change Display",dataType,pType
			
			sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType
			Execute str
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// display the 4x4 polariztion efficiency matrix in a table, and its inverse (if it exists)
Function ShowPolMatrixButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// get the current tab
			String type
			Variable tabNum
			ControlInfo/W=PolCor_Panel PolCorTab
			type = S_value
			Print "selected data type = ",type
			tabNum = V_Value
			
			Wave/Z Pol = $("root:Packages:NIST:"+type+":PolMatrix")
			if(WaveExists(Pol))
				Edit/W=(5,44,510,251)/K=1 Pol
			endif
			Wave/Z Inv_Pol = $("root:Packages:NIST:"+type+":Inv_PolMatrix")
			if(WaveExists(Inv_Pol))
				Edit/W=(6,506,511,713)/K=1 Inv_Pol
			endif
			Wave/Z Pol_err = $("root:Packages:NIST:"+type+":PolMatrix_err")
			if(WaveExists(Pol_err))
				Edit/W=(5,275,510,482)/K=1 Pol_err
			endif
			Wave/Z Inv_Pol_err = $("root:Packages:NIST:"+type+":Inv_PolMatrix_err")
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
Function/S P_GetConditionNameList()
	return("none;"+D_ConditionNameList())
End


// for a run, or a list of runs, determine the midpoint of the data collection
//
// list is passed COMMA-delimited, like normal lists of run numbers
//
// the time is returned in seconds (equivalent to a VAX date and time)
//
Function getTimeMidpoint(listStr)
	String listStr

	Variable ii,t_first,runt_first,t_last,runt_last,elap,run,t1,num,tMid
	String fname
	
	t1=0
	t_first = 1e100
	t_last = 0
	
	num=itemsinlist(listStr,",")
	for(ii=0;ii<num;ii+=1)
		run = str2num( StringFromList(ii, listStr ,",") )
		fname = FindFileFromRunNumber(run)
		t1 = ConvertVAXDateTime2Secs(getFileCreationDate(fname))
		if(t1 < t_first)
			t_first = t1
		endif
		if(t1 > t_last)
			t_last = t1
			runt_last = getCountTime(fname)		//seconds
		endif
	
	endfor
//	print/D t_last
//	Print/D runt_last
//	print/D t_first
	
	elap = (t_last + runt_last) - t_first		// from start of first file, to end of last

	tMid = t_first + elap/2
	return(tMid)
End

// options to reduce one or all types, in the same manner as the load.
//
// largely copied from ReduceAFile()
//
Function ReducePolCorDataButton(ctrlName) : ButtonControl
	String ctrlName

	// depends on which tab you're on
	// (maybe) select UD type
	
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
	SetDataFolder root:myGlobals:Protocols
	Execute	"PickAProtocol()"
	
	//get the selected protocol wave choice through a global string variable
	SVAR protocolName = root:myGlobals:Protocols:gProtoStr
	
	//If "CreateNew" was selected, go to the questionnare, to make a new set
	//and put the name of the new Protocol wave in gProtoStr
	if(cmpstr("CreateNew",protocolName) == 0)
		return(0)
	Endif
	
	//give the full path:name to the executeProtocol function
	waveStr = "root:myGlobals:Protocols:"+protocolName
	//samStr is set at top to "ask", since this is the action always desired from "ReduceAFile"
		
	//return data folder to root before Macro is done
	SetDataFolder root:
	
	if(cmpstr(pType,"All") == 0)
		ExecutePolarizedProtocol(waveStr,"UU")
		ExecutePolarizedProtocol(waveStr,"DU")
		ExecutePolarizedProtocol(waveStr,"DD")
		ExecutePolarizedProtocol(waveStr,"UD")
	else
		ExecutePolarizedProtocol(waveStr,pType)
	endif	
	
	
	return(0)
End

// very similar to ExecuteProtocol
//
// -- SAM, EMP, and BGD do not need to be loaded
// -- but they do need to be "moved" into the regular data positions
//    rather then their tagged locations.
// 
// -- the "extensions" now all are "_UU_pc" and similar, to use the polarization corrected data and errors
//
Function ExecutePolarizedProtocol(protStr,pType)
	String protStr,pType

	//protStr is the full path to the selected protocol wave
	WAVE/T prot = $protStr
	SetDataFolder root:myGlobals:Protocols
	
	Variable filesOK,err,notDone
	String activeType, msgStr, junkStr, pathStr="", samStr=""
	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)

// don't load the SAM data, just re-tag it	
// the Polarization corrected data is UU_pc, DU_pc, etc.
// this tags it for display, and puts it in the correctly named waves
	String dataType,str
	
	dataType="SAM"
	sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
	Execute str
	


// don't load the BGD data, just re-tag it	
	if(cmpstr(prot[0],"none") != 0)		//if BGD is used, protStr[0] = ""
		dataType="BGD"
		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
		Execute str
	endif

// don't load the EMP data, just re-tag it
//
	if(cmpstr(prot[1],"none") != 0)		//if EMP is used, protStr[1] = ""
		dataType="EMP"
		sprintf str,"DisplayTaggedData(\"%s\",\"%s\")",dataType,pType+"_pc"
		Execute str
	endif
		
//
// from here down, the steps are identical
//
// - with the exceptions of:
// - file naming. Names are additionally tagged with pType
// - if the protocol[0] or [1] are "" <null>, then the step  will be used
//   the step is only skipped if the protocol is "none"
//

	
	//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction 
	//additional modes 091301
	// ------currently, for polarized reduction, DRK mode is not allowed or recognized at all...
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
		
	//dispatch to the proper "mode" of Correct()
	Variable mode=4,val
	do
		if( (cmpstr("none",prot[0]) == 0)	&& (cmpstr("none",prot[1]) == 0) )
			//no subtraction (mode = 4),
			mode = 4
		Endif
		If((cmpstr(prot[0],"none") != 0) && (cmpstr(prot[1],"none") == 0))
			//subtract BGD only
			mode=2
		Endif
		If((cmpstr(prot[0],"none") == 0) && (cmpstr(prot[1],"none") != 0))
			//subtract EMP only
			mode=3
		Endif
		If((cmpstr(prot[0],"none") != 0) && (cmpstr(prot[1],"none") != 0))
			// bkg and emp subtraction are to be done (BOTH not "none")
			mode=1
		Endif
		activeType = "COR"
//		//add in DRK mode (0= no used, 10 = used)
//		val = NumberByKey("DRKMODE",prot[6],"=","," )
//		mode += val
//		print "Correct mode = ",mode
		err = Correct(mode)
		if(err)
			SetDataFolder root:
			Abort "error in Correct, called from executeprotocol, normal cor"
		endif
		TagLoadedData(activeType,pType+"_pc")
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	While(0)
	
	//check for work.div file (prot[2])
	//add if needed
	// can't properly check the filename - so for now add and divide, if anything other than "none"
	//do/skip divide step based on div answer
	If(cmpstr("none",prot[2])!=0)		// if !0, then there's a file requested
		If(cmpstr("ask",prot[2]) == 0)
			//ask user for file
			 junkStr = PromptForPath("Select the detector sensitivity file")
			If(strlen(junkStr)==0)
				SetDataFolder root:
				Abort "No file selected, data reduction aborted"
			Endif
			 ReadHeaderAndWork("DIV", junkStr)
		else
			//assume it's a path, and that the first (and only) item is the path:file
			//list processing is necessary to remove any final comma
			junkStr = pathStr + StringFromList(0, prot[2],"," )
			ReadHeaderAndWork("DIV",junkStr)
		Endif
		//got a DIV file, select the proper type of work data to DIV (= activeType)
		err = Divide_work(activeType)		//returns err = 1 if data doesn't exist in specified folders
		If(err)
			SetDataFolder root:
			Abort "data missing in DIV step, call from executeProtocol"
		Endif
		activeType = "CAL"
		TagLoadedData(activeType,pType+"_pc")
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	Endif
	
	Variable c2,c3,c4,c5,kappa_err
	//do absolute scaling if desired
	if(cmpstr("none",prot[4])!=0)
		if(cmpstr("ask",prot[4])==0)
			//get the params from the user
			Execute "AskForAbsoluteParams_Quest()"
			//then from the list
			SVAR junkAbsStr = root:myGlobals:Protocols:gAbsStr
			c2 = NumberByKey("TSTAND", junkAbsStr, "=", ";")	//parse the list of values
			c3 = NumberByKey("DSTAND", junkAbsStr, "=", ";")
			c4 = NumberByKey("IZERO", junkAbsStr, "=", ";")
			c5 = NumberByKey("XSECT", junkAbsStr, "=", ";")
			kappa_err = NumberByKey("SDEV", junkAbsStr, "=", ";")
		else
			//get the parames from the list
			c2 = NumberByKey("TSTAND", prot[4], "=", ";")	//parse the list of values
			c3 = NumberByKey("DSTAND", prot[4], "=", ";")
			c4 = NumberByKey("IZERO", prot[4], "=", ";")
			c5 = NumberByKey("XSECT", prot[4], "=", ";")
			kappa_err = NumberByKey("SDEV", prot[4], "=", ";")
		Endif
		//get the sample trans and thickness from the activeType folder
		String destStr = "root:Packages:NIST:"+activeType+":realsread"
		Wave dest = $destStr
		Variable c0 = dest[4]		//sample transmission
		Variable c1 = dest[5]		//sample thickness
		
		err = Absolute_Scale(activeType,c0,c1,c2,c3,c4,c5,kappa_err)
		if(err)
			SetDataFolder root:
			Abort "Error in Absolute_Scale(), called from executeProtocol"
		endif
		activeType = "ABS"
		TagLoadedData(activeType,pType+"_pc")
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	Endif
	
	//check for mask
	//add mask if needed
	// can't properly check the filename - so for now always add
	//doesn't change the activeType
	if(cmpstr("none",prot[3])!=0)
		If(cmpstr("ask",prot[3])==0)
			//get file from user
			junkStr = PromptForPath("Select Mask file")
			If(strlen(junkStr)==0)
				//no selection of mask file is not a fatal error, keep going, and let cirave()
				//make a "null" mask 
				//if none desired, make sure that the old mask is deleted
				//junkStr = GetDataFolder(1)
				//SetDataFolder root:Packages:NIST:MSK
				KillWaves/Z root:Packages:NIST:MSK:data
				//SetDataFolder junkStr
				DoAlert 0,"No Mask file selected, data not masked"
			else
				//read in the file from the dialog
				ReadMCID_MASK(junkStr)
			Endif
		else
			//just read it in from the protocol
			//list processing is necessary to remove any final comma
			junkStr = pathStr + StringFromList(0, prot[3],"," )
			ReadMCID_MASK(junkStr)
		Endif
	else
		//if none desired, make sure that the old mask is deleted
		//junkStr = GetDataFolder(1)
		//SetDataFolder root:Packages:NIST:MSK
		KillWaves/Z root:Packages:NIST:MSK:data
		//SetDataFolder junkStr
	Endif
	
	//mask data if desired (this is done automatically  in the average step) and is
	//not done explicitly here (if no mask in MSK folder, a null mask is created and "used")
	
	// average/save data as specified
	
	//Parse the keyword=<Value> string as needed, based on AVTYPE
	
	//average/plot first 
	String av_type = StringByKey("AVTYPE",prot[5],"=",";")
	If(cmpstr(av_type,"none") != 0)
		If (cmpstr(av_type,"")==0)		//if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit
			//in the panel
			SetAverageParamsButtonProc("dummy")		//from "ProtocolAsPanel"
			SVAR tempAveStr = root:myGlobals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE",tempAveStr,"=",";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			String/G root:myGlobals:Protocols:gAvgInfoStr = prot[5]
		Endif
	Endif
	
	//convert the folder to linear scale before averaging, then revert by calling the window hook
	ConvertFolderToLinearScale(activeType)
	
	strswitch(av_type)	//dispatch to the proper routine to average to 1D data
		case "none":		
			//still do nothing
			break			
		case "2D_ASCII":	
			//do nothing
			break
		case "QxQy_ASCII":
			//do nothing
			break
		case "PNG_Graphic":
			//do nothing
			break
		case "Rectangular":
			RectangularAverageTo1D(activeType)
			break
		case "Annular":
			AnnularAverageTo1D(activeType)
			break
		case "Circular":
			CircularAverageTo1D(activeType)
			break
		case "Sector":
			CircularAverageTo1D(activeType)
			break
		case "Sector_PlusMinus":
			Sector_PlusMinus1D(activeType)
			break
		default:	
			//do nothing
	endswitch
///// end of averaging dispatch
	// put data back on log or lin scale as set by default
	fRawWindowHook()
	
	//save data if desired
	String fullpath = "", newfileName=""
	String item = StringByKey("SAVE",prot[5],"=",";")		//does user want to save data?
	If( (cmpstr(item,"Yes")==0) && (cmpstr(av_type,"none") != 0) )		
		//then save
		//get name from textwave of the activeType dataset
		String textStr = "root:Packages:NIST:"+activeType+":textread"
		Wave/T textPath = $textStr
		String tempFilename = samStr
		If(WaveExists(textPath) == 1)
#if (exists("QUOKKA")==6)
			newFileName = ReplaceString(".nx.hdf", tempFilename, "")
#elif (exists("HFIR")==6)
//			newFileName = ReplaceString(".xml",textPath[0],"")		//removes 4 chars
//			newFileName = ReplaceString("SANS",newFileName,"")		//removes 4 more chars = 8
//			newFileName = ReplaceString("exp",newFileName,"")			//removes 3 more chars = 11
//			newFileName = ReplaceString("scan",newFileName,"")		//removes 4 more chars = 15, should be enough?
			newFileName = GetPrefixStrFromFile(textPath[0])+GetRunNumStrFromFile(textPath[0])
#else
			newFileName = UpperStr(GetNameFromHeader(textPath[0]))		//NCNR data drops here, trims to 8 chars
#endif
		else
			newFileName = ""			//if the header is missing?
			//Print "can't read the header - newfilename is null"
		Endif
		
		//pick ABS or AVE extension
		String exten = activeType
		if(cmpstr(exten,"ABS") != 0)
			exten = "AVE"
		endif
		if(cmpstr(av_type,"2D_ASCII") == 0)
			exten = "ASC"
		endif
		if(cmpstr(av_type,"QxQy_ASCII") == 0)
			exten = "DAT"
		endif
		
		// add an "x" to the file extension if the output is XML
		// currently (2010), only for ABS and AVE (1D) output
		if( cmpstr(exten,"ABS") == 0 || cmpstr(exten,"AVE") == 0 )
			if(useXMLOutput == 1)
				exten += "x"
			endif
		endif
				
		//Path is catPathName, symbolic path
		//if this doesn't exist, a dialog will be presented by setting dialog = 1
		//
		// -- add in pType tag to the name
		//
		Variable dialog = 0
		PathInfo/S catPathName
		item = StringByKey("NAME",prot[5],"=",";")		//Auto or Manual naming
		String autoname = StringByKey("AUTONAME",prot[5],"=",";")		//autoname -  will get empty string if not present
		If((cmpstr(item,"Manual")==0) || (cmpstr(newFileName,"") == 0))
			//manual name if requested or if no name can be derived from header
			fullPath = newfileName + pType + "."+ exten //puts possible new name or null string in dialog
			dialog = 1		//force dialog for user to enter name
		else
			//auto-generate name and prepend path - won't put up any dialogs since it has all it needs
			//use autoname if present
			if (cmpstr(autoname,"") != 0)
				fullPath = S_Path + autoname + pType + "." +exten
			else
				fullPath = S_Path + newFileName + pType + "." + exten
			endif	
		Endif
		//
		strswitch(av_type)	
			case "Annular":
				WritePhiave_W_Protocol(activeType,fullPath,dialog)
				break
			case "2D_ASCII":
				Fast2DExport(activeType,fullPath,dialog)
				break
			case "QxQy_ASCII":
				QxQy_Export(activeType,fullPath,dialog)
				break
			case "PNG_Graphic":
				SaveAsPNG(activeType,fullpath,dialog)
				break
			default:
				if (useXMLOutput == 1)
					WriteXMLWaves_W_Protocol(activeType,fullPath,dialog)
				else
					WriteWaves_W_Protocol(activeType,fullpath,dialog)
				endif
		endswitch
		
		//Print "data written to:  "+ fullpath
	Endif
	
	//done with everything in protocol list
	return(0)
End


// just like the RecallProtocolButton
// - the reset function is different
//
Function RecallPolCorProtocolButton(ctrlName) : ButtonControl
	String ctrlName
	
	//will reset panel values based on a previously saved protocol
	//pick a protocol wave from the Protocols folder
	//MUST move to Protocols folder to get wavelist
	SetDataFolder root:myGlobals:Protocols
	Execute "PickAProtocol()"
	
	//get the selected protocol wave choice through a global string variable
	SVAR protocolName = root:myGlobals:Protocols:gProtoStr

	//If "CreateNew" was selected, ask user to try again
	if(cmpstr("CreateNew",protocolName) == 0)
		Abort "CreateNew is for making a new Protocol. Select a previously saved Protocol"
	Endif
	
	//reset the panel based on the protocol textwave (currently a string)
	ResetToSavedPolProtocol(protocolName)
	
	SetDataFolder root:
	return(0)
end

//function that actually parses the protocol specified by nameStr
//which is just the name of the wave, without a datafolder path
//
Function ResetToSavedPolProtocol(nameStr)
	String nameStr
	
	//allow special cases of Base and DoAll Protocols to be recalled to panel - since they "ask"
	//and don't need paths
	
	String catPathStr
	PathInfo catPathName
	catPathStr=S_path
	
	//SetDataFolder root:myGlobals:Protocols		//on windows, data folder seems to get reset (erratically) to root: 
	Wave/T w=$("root:myGlobals:Protocols:" + nameStr)
	
	String fullPath="",comma=",",list="",nameList="",PathStr="",item=""
	Variable ii=0,numItems,checked,specialProtocol=0
	
	if((cmpstr(nameStr,"Base")==0) || (cmpstr(nameStr,"DoAll")==0))
		return(0)		//don't allow these
	Endif

	//background = check5
	checked = 1
	nameList = w[0]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	CheckBox check5 win=PolCor_Panel,value=checked

	//EMP = check4
	checked = 1
	nameList = w[1]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	CheckBox check4 win=PolCor_Panel,value=checked
	
	
	//DIV file
	checked = 1
	nameList = w[2]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gDIV = nameList
	CheckBox check0 win=PolCor_Panel,value=checked
	
	//Mask file
	checked = 1
	nameList = w[3]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gMASK = nameList
	CheckBox check1 win=PolCor_Panel,value=checked
	
	//4 = abs parameters
	list = w[4]
	numItems = ItemsInList(list,";")
	checked = 1
	if(numitems == 4 || numitems == 5)		//allow for protocols with no SDEV list item
		//correct number of parameters, assume ok
		String/G root:myGlobals:Protocols:gAbsStr = list
		CheckBox check2 win=PolCor_Panel,value=checked
	else
		item = StringFromList(0,list,";")
		if(cmpstr(item,"none")==0)
			checked = 0
			list = "none"
			String/G root:myGlobals:Protocols:gAbsStr = list
			CheckBox check2 win=PolCor_Panel,value=checked
		else
			//force to "ask"
			checked = 1
			String/G root:myGlobals:Protocols:gAbsStr = "ask"
			CheckBox check2 win=PolCor_Panel,value=checked
		Endif
	Endif
	
	//5 = averaging choices
	list = w[5]
	item = StringByKey("AVTYPE",list,"=",";")
	if(cmpstr(item,"none") == 0)
		checked = 0
		String/G root:myGlobals:Protocols:gAVE = "none"
		CheckBox check3 win=PolCor_Panel,value=checked
	else
		checked = 1
		String/G root:myGlobals:Protocols:gAVE = list
		CheckBox check3 win=PolCor_Panel,value=checked
	Endif
	
	//6 = DRK choice

	//7 = unused
	
	//all has been reset, get out
	Return (0)
End

// at a first pass, uses the regular reduction protocol 	SaveProtocolButton(ctrlName)
//
// -- won't work, as it uses the MakeProtocolFromPanel function... so replace this
//
Function SavePolCorProtocolButton(ctrlName) : ButtonControl
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
	MakePolProtocolFromPanel( $("root:myGlobals:Protocols:" + newProtocol) )
	String/G  root:myGlobals:Protocols:gProtoStr = newProtocol
	
	//the data folder WAS changed above, this must be reset to root:
	SetDatafolder root:	
		
	return(0)
End

//function that does the guts of reading the panel controls and globals
//to create the necessary text fields for a protocol
//Wave/T w (input) is an empty text wave of 8 elements for the protocol
//on output, w[] is filled with the protocol strings as needed from the panel 
//
Function MakePolProtocolFromPanel(w)
	Wave/T w
	
	//construct the protocol text wave form the panel
	//it is to be parsed by ExecuteProtocol() for the actual data reduction
	PathInfo catPathName			//this is where the files came from
	String pathstr=S_path,tempStr,curList
	Variable checked,ii,numItems
	
	//look for checkboxes, then take each item in list and prepend the path
	//w[0] = background
	ControlInfo/W=PolCor_Panel check5
	checked = V_Value
	if(checked)
		w[0] = ""		// BKG will be used
	else
		w[0] = "none"		// BKG will not be used
	endif
	
	//w[1] = empty
	ControlInfo/W=PolCor_Panel check4
	checked = V_Value
	if(checked)
		w[1] = ""		// EMP will be used
	else
		w[1] = "none"		// EMP will not be used
	endif

	
	//w[2] = div file
	ControlInfo/W=PolCor_Panel check0
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gDIV
		if(cmpstr(str,"ask")==0)
			w[2] = str
		else
			tempStr = ParseRunNumberList(str)
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
	ControlInfo/W=PolCor_Panel check1
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gMASK
		if(cmpstr(str,"ask")==0)
			w[3] = str
		else
			tempstr = ParseRunNumberList(str)
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
	ControlInfo/W=PolCor_Panel check2
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
	ControlInfo/W=PolCor_Panel check3
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
Function Display_4(type,scaling)
	String type,scaling
	
	String dest = "root:Packages:NIST:"+type
	NVAR isLogscale = $(dest + ":gIsLogScale")

	SetDataFolder $("root:Packages:NIST:"+type)
	
	wave uu = linear_data_uu_pc
	wave d_uu = data_uu_pc
	
	wave du = linear_data_du_pc
	wave d_du = data_du_pc
	
	wave dd = linear_data_dd_pc
	wave d_dd = data_dd_pc
	
	wave ud = linear_data_ud_pc
	wave d_ud = data_ud_pc
		
	if(cmpstr(scaling,"log") == 0)

		d_uu = log(uu)
		d_du = log(du)
		d_dd = log(dd)
		d_ud = log(ud)			
		
		isLogScale = 1
			
	else

		d_uu = uu
		d_du = du
		d_dd = dd
		d_ud = ud
			
		isLogScale = 0

	endif

	DoWindow/F SANS_X4
	if(V_flag==0)
		Display /W=(811,44,1479,758)/K=1
		ControlBar 100
		DoWindow/C SANS_X4
		DoWindow/T SANS_X4,type+"_pc"
		Button button0 pos={130,65},size={50,20},title="Do It",proc=Change4xsButtonProc
		PopupMenu popup0 pos={20,35},title="Data Type",value="SAM;EMP;BGD;COR;CAL;ABS;"		//RAW, SAS, DIV, etc, won't have _pc data and are not valid
		PopupMenu popup1 pos={190,35},title="Scaling",value="log;linear;"
		TitleBox title0 title="Only Polarization-corrected sets are displayed",pos={5,5}

	else
		RemoveImage/Z data_uu_pc		//remove the old images (different data folder)
		RemoveImage/Z data_du_pc
		RemoveImage/Z data_dd_pc
		RemoveImage/Z data_ud_pc
		
		DoWindow/T SANS_X4,type+"_pc"

	endif
	
	AppendImage/B=bot_uu/L=left_uu data_UU_pc
	ModifyImage data_UU_pc ctab= {*,*,YellowHot,0}
	AppendImage/B=bot_dd/L=left_dd data_DD_pc
	ModifyImage data_DD_pc ctab= {*,*,YellowHot,0}
	AppendImage/B=bot_du/L=left_du data_DU_pc
	ModifyImage data_DU_pc ctab= {*,*,YellowHot,0}
	AppendImage/B=bot_ud/L=left_ud data_UD_pc
	ModifyImage data_UD_pc ctab= {*,*,YellowHot,0}
	
	DoUpdate
			
	ModifyGraph freePos(left_uu)={0,kwFraction},freePos(bot_uu)={0.6,kwFraction}
	ModifyGraph freePos(left_dd)={0,kwFraction},freePos(bot_dd)={0,kwFraction}
	ModifyGraph freePos(left_du)={0.6,kwFraction},freePos(bot_du)={0.6,kwFraction}
	ModifyGraph freePos(left_ud)={0.6,kwFraction},freePos(bot_ud)={0,kwFraction}
	
	ModifyGraph axisEnab(left_uu)={0.6,1},axisEnab(bot_uu)={0,0.4}
	ModifyGraph axisEnab(left_dd)={0,0.4},axisEnab(bot_dd)={0,0.4}
	ModifyGraph axisEnab(left_du)={0.6,1},axisEnab(bot_du)={0.6,1}
	ModifyGraph axisEnab(left_ud)={0,0.4},axisEnab(bot_ud)={0.6,1}
	
	ModifyGraph standoff=0
	ModifyGraph lblPosMode(left_uu)=4,lblPosMode(left_dd)=4,lblPosMode(left_du)=4,lblPosMode(left_ud)=4
	ModifyGraph lblPos(left_uu)=40,lblPos(left_dd)=40,lblPos(left_du)=40,lblPos(left_ud)=40
	Label left_uu "UU"
	Label left_dd "DD"
	Label left_du "DU"
	Label left_ud "UD"	
	
	ModifyGraph fSize=16
	// force a redraw to get the axes in the right spot
	DoUpdate
	
	SetDataFolder root:
	return(0)
End

Function Change4xsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String dataType,scaling
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup0
			dataType = S_Value
			ControlInfo popup1
			scaling = S_Value
			Display_4(dataType,scaling)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// clear the entries for all 4 XS for the currently selected Tab only
// clears both the run numbers and the cell assignments
//
Function ClearPolCorEntries(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//
//			String type
			Variable tabNum
			ControlInfo/W=PolCor_Panel PolCorTab
//			type = S_value
//			Print "selected data type = ",type,V_Value
			tabNum = V_Value
			
			WAVE/T twDD = $("root:Packages:NIST:Polarization:ListWave_"+num2str(tabNum)+"_DD")
			WAVE/T twUU = $("root:Packages:NIST:Polarization:ListWave_"+num2str(tabNum)+"_UU")
			WAVE/T twUD = $("root:Packages:NIST:Polarization:ListWave_"+num2str(tabNum)+"_UD")
			WAVE/T twDU = $("root:Packages:NIST:Polarization:ListWave_"+num2str(tabNum)+"_DU")
			
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
//Function opacity_mu(T_he,T_out,T_bk)
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
//Function Cell_muP(mu, T_he, T_out, T_bk)
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
//Function muP_at_t(Gam_He, muP_t0, t0, tn)
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
//Function PCell(muP)
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
//Function Flipper_Pf(Tuu, Tdu, Tdd, Tud)
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
//Function SupMir_Psm(Pcell1,Pcell2,Tuu,Tud)
//	Variable Pcell1,Pcell2,Tuu,Tud
//	
//	Variable Psm
//	
//	Psm = (Tuu - Tud)/(PCell1 + PCell2)
//	
//	return(Psm)
//End
