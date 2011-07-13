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

// I'll need space for 4 input files in, say SAM_P
// - load in all of the UU files, adding together
// - rename the UU data, error
//
// - repeat for the other three cross sections. then in the SAM_P folder, there will be 
// scattering data for all four cross sections present.
//
// then add together the values for the coefficient matrix.
// -- this can be tricky with rescaling for time, and adding to the proper row of the 
// coefficient matrix. I'll need to re-read either the monitor or the time from the header
// of each file that was added
//
// Then everything is set to do the inversion.
// -- the result of the inversion is 4 corrected data sets, with no polarization effects.
//
//
// --- repeat it all for EMP_P (and maybe BKG_P)
//
// Now I can one-by-one, copy the correct UU, UD, etc. into "data" and "linear_data"
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
//

Macro ShowPolCorSetup()

	DoWindow/F PolCor_Panel
	if(V_flag==0)
		Initialize_PolCorPanel()
		PolCor_Panel()
	endif
End

//
// TODO:
// X- only re-initialize values if user wants to. maybe ask.
//
Function Initialize_PolCorPanel()

	DoAlert 1,"Do you want to initialize, wiping out all of your entries?"
	if(V_flag != 1)		//1== yes, everything else, get out
		return(0)
	endif
	
	//initialize all of the strings for the input
	Variable ii
	SetDataFolder root:Packages:NIST:Polarization
	
	for(ii=0;ii<5;ii+=1)
		String/G $("gStr_PolCor_0_UU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_0_DU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_0_DD_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_0_UD_"+num2str(ii)) = "none"
	endfor

	for(ii=0;ii<5;ii+=1)
		String/G $("gStr_PolCor_1_UU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_1_DU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_1_DD_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_1_UD_"+num2str(ii)) = "none"
	endfor
	
	for(ii=0;ii<5;ii+=1)
		String/G $("gStr_PolCor_2_UU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_2_DU_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_2_DD_"+num2str(ii)) = "none"
		String/G $("gStr_PolCor_2_UD_"+num2str(ii)) = "none"
	endfor
	
	// blank matrix of coefficients
	Make/O/D/N=(4,4) PolMatrix = 0

	SetDataFolder root:

	// initialize new folders for SAM_P, etc, or maybe just use the existing folders
	//
	
	return(0)

end


// controls are labeled "name_#_UU_#" where name is the type of control, # is the tab #, and (2nd) # is the control #
// -- this will allow for future use of tabs. right now 0 will be the "SAM" data
//
// - always visible controls will have no "_" characters
// 
// TODO:
// - tabs for SAM, EMP, and BGD
// - input fields for the other protocol items, like the Protocol Panel
// - need a way of saving the "protocol" since the setup is so complex.
// - generate a report of the setup.
// - 4-panel display (maybe a layout with labels?) Maybe a panel with 4 subwindows. Can I use color bars in them?
//
//
Window PolCor_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(554,44,1265,770)
//	ShowTools/A
	ModifyPanel cbRGB=(64349,63913,44660)
	TitleBox title_0,pos={116,21},size={24,24},title="\\f01UU",fSize=12

	SetVariable setvar_0_UU_0,pos={34,57},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_0
	SetVariable setvar_0_UU_1,pos={34,80},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_1
	SetVariable setvar_0_UU_2,pos={34,104},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_2
	SetVariable setvar_0_UU_3,pos={34,128},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_3
	SetVariable setvar_0_UU_4,pos={34,152},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UU_4
	PopupMenu popup_0_UU_0,pos={142,54},size={102,20},title="Condition"
	PopupMenu popup_0_UU_0,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UU_1,pos={142,77},size={102,20},title="Condition"
	PopupMenu popup_0_UU_1,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UU_2,pos={142,101},size={102,20},title="Condition"
	PopupMenu popup_0_UU_2,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UU_3,pos={142,125},size={102,20},title="Condition"
	PopupMenu popup_0_UU_3,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UU_4,pos={142,149},size={102,20},title="Condition"
	PopupMenu popup_0_UU_4,mode=1,popvalue="none",value= #"P_GetConditionNameList()"

	
	TitleBox title_1,pos={450,21},size={24,24},title="\\f01DU",fSize=12
	SetVariable setvar_0_DU_0,pos={368,57},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DU_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_0
	SetVariable setvar_0_DU_1,pos={368,80},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DU_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_1
	SetVariable setvar_0_DU_2,pos={368,104},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DU_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_2
	SetVariable setvar_0_DU_3,pos={368,128},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DU_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_3
	SetVariable setvar_0_DU_4,pos={368,152},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DU_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DU_4
	PopupMenu popup_0_DU_0,pos={476,54},size={102,20},title="Condition"
	PopupMenu popup_0_DU_0,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DU_1,pos={476,77},size={102,20},title="Condition"
	PopupMenu popup_0_DU_1,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DU_2,pos={476,101},size={102,20},title="Condition"
	PopupMenu popup_0_DU_2,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DU_3,pos={476,125},size={102,20},title="Condition"
	PopupMenu popup_0_DU_3,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DU_4,pos={476,149},size={102,20},title="Condition"
	PopupMenu popup_0_DU_4,mode=1,popvalue="none",value= #"P_GetConditionNameList()"

	TitleBox title_2,pos={115,205},size={25,24},title="\\f01DD",fSize=12
	SetVariable setvar_0_DD_0,pos={33,241},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_0
	SetVariable setvar_0_DD_1,pos={33,264},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_1
	SetVariable setvar_0_DD_2,pos={33,288},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_2
	SetVariable setvar_0_DD_3,pos={33,312},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_3
	SetVariable setvar_0_DD_4,pos={33,336},size={70,16},title="File",fSize=10
	SetVariable setvar_0_DD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_DD_4
	PopupMenu popup_0_DD_0,pos={141,238},size={102,20},title="Condition"
	PopupMenu popup_0_DD_0,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DD_1,pos={141,261},size={102,20},title="Condition"
	PopupMenu popup_0_DD_1,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DD_2,pos={141,285},size={102,20},title="Condition"
	PopupMenu popup_0_DD_2,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DD_3,pos={141,309},size={102,20},title="Condition"
	PopupMenu popup_0_DD_3,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_DD_4,pos={141,333},size={102,20},title="Condition"
	PopupMenu popup_0_DD_4,mode=1,popvalue="none",value= #"P_GetConditionNameList()"

	TitleBox title_3,pos={450,205},size={24,24},title="\\f01UD",fSize=12
	SetVariable setvar_0_UD_0,pos={368,241},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UD_0,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_0
	SetVariable setvar_0_UD_1,pos={368,264},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UD_1,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_1
	SetVariable setvar_0_UD_2,pos={368,288},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UD_2,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_2
	SetVariable setvar_0_UD_3,pos={368,312},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UD_3,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_3
	SetVariable setvar_0_UD_4,pos={368,336},size={70,16},title="File",fSize=10
	SetVariable setvar_0_UD_4,limits={-inf,inf,0},value= root:Packages:NIST:Polarization:gStr_PolCor_0_UD_4
	PopupMenu popup_0_UD_0,pos={476,238},size={102,20},title="Condition"
	PopupMenu popup_0_UD_0,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UD_1,pos={476,261},size={102,20},title="Condition"
	PopupMenu popup_0_UD_1,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UD_2,pos={476,285},size={102,20},title="Condition"
	PopupMenu popup_0_UD_2,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UD_3,pos={476,309},size={102,20},title="Condition"
	PopupMenu popup_0_UD_3,mode=1,popvalue="none",value= #"P_GetConditionNameList()"
	PopupMenu popup_0_UD_4,pos={476,333},size={102,20},title="Condition"
	PopupMenu popup_0_UD_4,mode=1,popvalue="none",value= #"P_GetConditionNameList()"

	
// always visible
	Button button0,pos={26,485},size={80,20},proc=LoadRawPolarizedButton,title="Load ..."
	Button button1,pos={26,513},size={130,20},proc=PolCorButton,title="Pol Correct Data"
	Button button2,pos={222,488},size={130,20},proc=ShowPolMatrixButton,title="Show Coef Matrix"
	Button button3,pos={222,518},size={160,20},proc=ChangeDisplayedPolData,title="Change Displayed Data"
	
	
EndMacro

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
// -- SAM folder is currently hard-wired
// X- if all of the conditions are "none" - stop and report the error
//
Function LoadRawPolarizedButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			String listStr="",runList="",parsedRuns,condStr
			Variable ii,num,err

			// depends on which tab you're on
			// (maybe) select UD type
			String pType
			Prompt pType,"Pol Type",popup,"UU;DU;DD;UD;"
			DoPrompt "Type to load",pType
			if (V_Flag)
				return 0									// user canceled
			endif
//			Print pType
			
			// get a list of the file numbers to load, must be in proper data folder
			SetDataFolder root:Packages:NIST:Polarization
			listStr = StringList("gStr_PolCor*"+pType+"*", ";" )

//			print listStr
			for(ii=0;ii<itemsinlist(listStr);ii+=1)
				SVAR str=$StringFromList(ii, listStr ,";")
				if(cmpstr(str, "none" ) != 0)
					runList += str + ","
					
					// and check that the condition is not "none"
					Print "ControlInfo call is hard-wired for tab=0 = SAM"
			
					ControlInfo/W=PolCor_Panel $("popup_0_"+pType+"_"+num2str(ii))
					condStr = S_Value
					if(cmpstr(condStr, "none" ) == 0)
						DoAlert 0,"Condition for file index "+num2str(ii)+" is not set."
						SetDataFolder root:
						return(0)
					endif
				endif
			endfor

//			Print runList
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
			err = AddFilesInList("SAM",ParseRunNumberList(runlist))		// adds to a work file, not RAW
			UpdateDisplayInformation("SAM")
			
			TagLoadedData("SAM",pType)		//see also DisplayTaggedData()
			
			// now add the appropriate bits to the matrix
			
			WAVE matA = root:Packages:NIST:Polarization:PolMatrix
//			listStr = ControlNameList("PolCor_Panel",";","*"+pType+"*")

			// the PolMatrix rows are cleared on pass 0 as each pType data is loaded.
			// this way repeated loading will always result in the correct fill			
			AddToPolMatrix(matA,pType,tMid)

			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
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
//
Function AddToPolMatrix(matA,pType,tMid)
	Wave matA
	String pType
	Variable tMid
	
	Variable row,Psm, PsmPf, PCell,err_Psm, err_PsmPf, err_PCell
	Variable ii,muPo,err_muPo,gam,err_gam,monCts,t1

	Variable ea_uu, ea_ud, ea_dd, ea_du
	Variable ec_uu, ec_ud, ec_dd, ec_du
	
	String listStr,fname="",condStr,condNote,decayNote,cellStr,t0Str,t1Str
	
	
	SetDataFolder root:Packages:NIST:Polarization
	listStr = StringList("gStr_PolCor*"+pType+"*", ";" )

	
	// loop over the (5) fields
	for(ii=0;ii<itemsinlist(listStr);ii+=1)
		SVAR str=$StringFromList(ii, listStr ,";")		//the run number
		if(cmpstr(str, "none" ) != 0)
			// get run number (str)
			// get file name
			fname = FindFileFromRunNumber(str2num(str))
			// get condition from popup
			//
			Print "ControlInfo call is hard-wired for tab=0 = SAM"
			
			ControlInfo/W=PolCor_Panel $("popup_0_"+pType+"_"+num2str(ii))
			condStr = S_Value
			Wave condition = $("root:Packages:NIST:Polarization:Cells:"+condStr)
			// get wave note from condition
			condNote = note(condition)
			// get P's from note
			Psm = NumberByKey("P_sm", condNote, "=", ",", 0)
			PsmPf = NumberByKey("P_sm_f", condNote, "=", ",", 0)
			err_Psm = NumberByKey("err_P_sm", condNote, "=", ",", 0)
			err_PsmPf = NumberByKey("err_P_sm_f", condNote, "=", ",", 0)
		
			// get the cell string to get the Decay wave
			cellStr = StringFromList(2, condStr ,"_")		// treat the name as a list
			print "Cell = ",cellStr
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
			monCts /= 1e8		//just to get reasonable values
			
			// add appropriate values to matrix elements (switch on UU, DD, etc)
			
			strswitch(pType)
				case "UU":		
					row = 0
					if(ii==0)
						matA[row][] = 0
					endif
					ea_uu = (1+Psm)/2
					ea_du = (1-Psm)/2
					ec_uu = (1+Pcell)/2
					ec_du = (1-Pcell)/2
					
					matA[row][0] += ea_uu*ec_uu*monCts
					matA[row][1] += ea_du*ec_uu*monCts
					matA[row][2] += ea_du*ec_du*monCts
					matA[row][3] += ea_uu*ec_du*monCts
					
					
					break
				case "DU":		
					row = 1
					if(ii==0)
						matA[row][] = 0
					endif
					ea_ud = (1-PsmPf)/2
					ea_dd = (1+PsmPf)/2
					ec_uu = (1+Pcell)/2
					ec_du = (1-Pcell)/2
					
					matA[row][0] += ea_ud*ec_uu*monCts
					matA[row][1] += ea_dd*ec_uu*monCts
					matA[row][2] += ea_dd*ec_du*monCts
					matA[row][3] += ea_ud*ec_du*monCts
					
					break	
				case "DD":		
					row = 2
					if(ii==0)
						matA[row][] = 0
					endif
					ea_ud = (1-PsmPf)/2
					ea_dd = (1+PsmPf)/2
					ec_ud = (1-Pcell)/2
					ec_dd = (1+Pcell)/2
					
					matA[row][0] += ea_ud*ec_ud*monCts
					matA[row][1] += ea_dd*ec_ud*monCts
					matA[row][2] += ea_dd*ec_dd*monCts
					matA[row][3] += ea_ud*ec_dd*monCts					
					
					
					break						
				case "UD":		
					row = 3
					if(ii==0)
						matA[row][] = 0
					endif
					ea_uu = (1+Psm)/2
					ea_du = (1-Psm)/2
					ec_ud = (1-Pcell)/2
					ec_dd = (1+Pcell)/2
					
					matA[row][0] += ea_uu*ec_ud*monCts
					matA[row][1] += ea_du*ec_ud*monCts
					matA[row][2] += ea_du*ec_dd*monCts
					matA[row][3] += ea_uu*ec_dd*monCts					
										
					
					
					break
			endswitch

			
		endif
	endfor
	

	
	
	
	
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

	ptype = "_" + pType			// add an extra underscore
	String destPath = "root:Packages:NIST:" + type
	$(destPath + ":data") = $(destPath + ":data"+pType)
	$(destPath + ":linear_data") = $(destPath + ":linear_data"+pType)
	$(destPath + ":linear_data_error") = $(destPath + ":linear_data_error"+pType)
	$(destPath + ":textread") = $(destPath + ":textread"+pType)
	$(destPath + ":integersread") = $(destPath + ":integersread"+pType)
	$(destPath + ":realsread") = $(destPath + ":realsread"+pType)

	UpdateDisplayInformation("SAM")

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
			
			Variable ii,jj,numRows,numCols
			
			// make waves for the result
			Print "@@ PolCor is hard-wired for SAM --- this must be fixed"
			// these duplicate the data and add "_pc" for later use
			MakePCResultWaves("SAM","UU")
			MakePCResultWaves("SAM","DU")
			MakePCResultWaves("SAM","DD")
			MakePCResultWaves("SAM","UD")
			
			
			SetDataFolder root:Packages:NIST:SAM
			WAVE linear_data_UU_pc = linear_data_UU_pc
			WAVE linear_data_DU_pc = linear_data_DU_pc
			WAVE linear_data_DD_pc = linear_data_DD_pc
			WAVE linear_data_UD_pc = linear_data_UD_pc
			
			linear_data_UU_pc = 0
			linear_data_DU_pc = 0
			linear_data_DD_pc = 0
			linear_data_UD_pc = 0
			
			// make a temp wave for the experimental data vector
			Make/O/D/N=4 vecB
			WAVE vecB = vecB
			
			// the coefficient matrix and the experimental data
			WAVE matA = root:Packages:NIST:Polarization:PolMatrix
			WAVE linear_data_UU = linear_data_UU
			WAVE linear_data_DU = linear_data_DU
			WAVE linear_data_DD = linear_data_DD
			WAVE linear_data_UD = linear_data_UD
			
			
			
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
				
				endfor
			//	Print ii	
			endfor
			
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

// Change the displayed SANS data by pointing the data with the 
// specified tag (suffix) at data, linear_data, etc.
// all of the read waves are pointed too.
//
Function ChangeDisplayedPolData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String dataType="SAM",pType,str
			Prompt dataType,"Data Folder"
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


// display the 4x4 polariztion efficiency matrix in a table
Function ShowPolMatrixButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Edit root:Packages:NIST:Polarization:PolMatrix
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
