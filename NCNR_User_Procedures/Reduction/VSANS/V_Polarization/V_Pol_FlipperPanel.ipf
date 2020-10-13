#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=7.0


/// JUNE 2020
// this is a first, crude implementation of the Polarization routines for VSANS
//
// - need to reach out to Polarized beam folks to get their input on how each of these
// panels should be populated (from metadata info) and if the work flow
// should be the same, or different
//




// input panels to set and calculate polarization parameters necessary for the 
// matrix corrections to the cross sections
//
//
// -3-Flipper efficiency



// **** search for TODO to find items still to be fixed in other procedures  **********



//
// TODO: 
// X- add a way to manually enter the P values into a "blank" condition, in case that the users
// calculate the values in a different way. This should be as simple as a dialog to enter values and 
// change the wave note (and displayed strings).
//
//
// Polarization parameters for each condition. Results are stored in a wave note for each condition
//
//
// str = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,Cell=asdf,"
//
// two waves per condition "Cond_Name_Cell" and "CondCalc_Name_Cell"
//
Proc V_ShowFlipperPanel()
	
	// init folders
	// ASK before initializing cell constants
	// open the panel
	DoWindow/F V_FlipperPanel
	if(V_flag == 0)
		V_InitPolarizationFolders()
		V_InitFlipperGlobals()
		V_DrawFlipperPanel()
	endif
	// be sure that the panel is onscreen
	DoIgorMenu "Control","Retrieve Window"
end

Function V_InitFlipperGlobals()

//	SetDataFolder root:Packages:NIST:Polarization:Cells
	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells
	
	String/G gPsmPf = "Psm*Pf"
	String/G gPsm = "Psm"
	
	SetDataFolder root:
	return(0)
End


//
// makes the panel for the calculation of flipper and supermirror efficiencies
//
Function V_DrawFlipperPanel()

	Variable sc=1
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(250*sc,44*sc,1056*sc,480*sc)/N=V_FlipperPanel/K=1 as "Flipper and Supermirror"
	ModifyPanel cbRGB=(1,52428,26586)
	
	PopupMenu popup_0,pos={sc*13,8*sc},size={sc*49,20*sc},title="Field Condition",proc=V_FlipperPanelPopMenuProc
	PopupMenu popup_0,mode=1,value= #"V_D_ConditionNameList()"
	
	Button button_0,pos={sc*18,288*sc},size={sc*100,20*sc},proc=V_FlipperAverageButtonProc,title="Do Average"

	SetVariable setvar_4,pos={sc*130,288*sc},size={sc*100,13*sc},title="Panel",fStyle=1
	SetVariable setvar_4,value=root:Packages:NIST:VSANS:Globals:Polarization:Cells:gDecayTransPanel
	
	GroupBox group_0,pos={sc*18,316*sc},size={sc*290,102*sc},title="AVERAGED RESULTS",fSize=10
	GroupBox group_0,fStyle=1
	SetVariable setvar_0,pos={sc*33,351*sc},size={sc*250,15*sc},title="Sam_depol*Psm*Pf"
	SetVariable setvar_0,fStyle=1
	SetVariable setvar_0,limits={0,0,0*sc},value= root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
	SetVariable setvar_1,pos={sc*33,383*sc},size={sc*250,15*sc},title="Sam_depol*Psm",fStyle=1
	SetVariable setvar_1,limits={0,0,0*sc},value= root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
//	SetVariable setvar_2,pos={sc*560,518*sc},size={sc*200,13*sc},title="Gamma (h)",fStyle=1
//	SetVariable setvar_2,limits={0,0,0*sc},barmisc={0,1000}
//	SetVariable setvar_2,value= root:Packages:NIST:Polarization:Cells:gGamma
//	SetVariable setvar_3,pos={sc*560,488*sc},size={sc*200,15*sc},title="T0",fStyle=1
//	SetVariable setvar_3,limits={0,0,0*sc},value= root:Packages:NIST:Polarization:Cells:gT0
	

	Button button_1,pos={sc*322,8*sc},size={sc*120,20*sc},proc=V_AddFlipperConditionButton,title="Add Condition"
	Button button_2,pos={sc*482,323*sc},size={sc*110,20*sc},proc=V_ClearAllFlipperWavesButton,title="Clear Table"
	Button button_3,pos={sc*330,288*sc},size={sc*110,20*sc},proc=V_ShowFlipperCalcButton,title="Show Calc"
	Button button_4,pos={sc*482,288*sc},size={sc*110,20*sc},proc=V_ClearFlipperRowButton,title="Clear Row"
	Button button_5,pos={sc*759,8*sc},size={sc*30,20*sc},proc=V_FlipperHelpParButtonProc,title="?"
	Button button_6,pos={sc*328,358*sc},size={sc*110,20*sc},proc=V_WindowSnapshotButton,title="Snapshot"
	Button button_7,pos={sc*331,323*sc},size={sc*110,20*sc},proc=V_ManualEnterPfPsmButton,title="Manual Entry"

	Button button_8,pos={sc*615,288*sc},size={sc*110,20*sc},proc=V_SaveFlipperPanelButton,title="Save State"
	Button button_9,pos={sc*615,323*sc},size={sc*110,20*sc},proc=V_RestoreFlipperPanelButton,title="Restore State"
	
	// table
	Edit/W=(14*sc,40*sc,794*sc,275*sc)/HOST=# 
	ModifyTable format=1,width=0
	RenameWindow #,T0
	SetActiveSubwindow ##

//	//hook to set contextual menu in subwindow
// can't set a hook for asubwindow, so
// sets hook for entire panel, I need to look for subwindow T0
	SetWindow kwTopWin hook=V_FlipperTableHook, hookevents=1	// mouse down events

	SetDataFolder root:
	return(0)
End

Function V_SaveFlipperPanelButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_SaveFlipperTable()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_RestoreFlipperPanelButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_RestoreFlipperTable()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// now, this does not depend on the cell, just the condition
Function V_AddFlipperConditionButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			

			String condStr//, cellStr
			Prompt condStr,"Condition, <12 characters, NO UNDERSCORES"
//			Prompt cellStr,"Cell",popup,D_CellNameList()
			DoPrompt "Add new condition",condStr//, cellStr
			if(V_Flag==1)
				return 0									// user canceled
			endif
			
			if(strlen(condStr) > 12)
				condStr = condStr[0,11]
				Print "Condition String trimmed to ",condStr
			endif
			
			condStr = ReplaceString("_", condStr, "", 0, inf)
			
			String popStr
//			popStr = condStr+"_"+cellStr
			popStr = condStr
			
			V_MakeFlipperResultWaves(popStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_FlipperPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	Variable sc=1
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

			// based on the selected string, display the right set of inputs
//			Print "now I need to display the right set of waves (2D text?) for ",popStr
			
			if(cmpstr(popStr,"no conditions defined") == 0)
				SetDataFolder root:
				return(0)
			endif
			
			
			// for the given cell name, if the wave(s) exist, declare them
			if(exists(popStr) == 1)
				WAVE cond = $(popStr)
				WAVE/T cellW = $("CondCell_"+popStr[5,strlen(popStr)-1])
			else
				// if not, report an error				
				DoAlert 0,"The Cond_ waves should exist, this is an error"
				
				SetDataFolder root:
				return(0)
				//MakeFlipperResultWaves(popStr)
				//WAVE cond = $("root:Packages:NIST:Polarization:Cells:Cond_"+popStr)
			endif			
			// append matrix, clearing the old one first
			SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

			KillWindow V_FlipperPanel#T0
			Edit/W=(14*sc,55*sc,794*sc,275*sc)/HOST=V_FlipperPanel
			RenameWindow #,T0
			AppendtoTable/W=V_FlipperPanel#T0 cellW			//
			AppendtoTable/W=V_FlipperPanel#T0 cond.ld			//show the labels
			ModifyTable width(Point)=0
			ModifyTable width(cond.l)=20
			
			SetActiveSubwindow ##
	
			SetDataFolder root:
			
			// update the globals that are displayed from the wave note
			String nStr=Note(cond)
			SVAR gPsmPf = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
			SVAR gPsm = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
			sprintf gPsmPf, "%g +/- %g",NumberByKey("P_sm_f", nStr, "=",","),NumberByKey("err_P_sm_f", nStr, "=",",")
			sprintf gPsm, "%g +/- %g",NumberByKey("P_sm", nStr, "=",","),NumberByKey("err_P_sm", nStr, "=",",")
			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// waves are:
// "Cond_"+popStr
// and "CondCalc_"+popStr
// ... and now "CondCell"+popStr

Function V_MakeFlipperResultWaves(popStr)
	String popStr

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

	Make/O/T/N=1  $("CondCell_"+popStr)
	WAVE/T cell=$("CondCell_"+popStr)
	cell[0] = "Enter cell name"
//	SetDimLabel 0,-1,'Cell Name?',cell

	Make/O/D/N=(1,8) $("Cond_"+popStr)
	WAVE cond = $("Cond_"+popStr)
	// set the column labels
	SetDimLabel 1,0,'UU_Trans?',cond
	SetDimLabel 1,1,'DU_Trans?',cond
	SetDimLabel 1,2,'DD_Trans?',cond
	SetDimLabel 1,3,'UD_Trans?',cond
	SetDimLabel 1,4,'Blocked?',cond
	SetDimLabel 1,5,Pol_SM_FL,cond
	SetDimLabel 1,6,Pol_SM,cond			//for a mask wave, non-zero is used in the fit
	SetDimLabel 1,7,'Include?',cond
	cond[0][7] = 1			//default to include the point
	
	// generate the dummy wave note now, change as needed
	String cellStr = StringFromList(1, popStr,"_")
	String testStr = "P_sm_f=0,err_P_sm_f=0,P_sm=0,err_P_sm=0,T0=undefined,"
//	testStr = ReplaceStringByKey("Cell", testStr, cellStr ,"=", ",", 0)
	Note cond, testStr

	// to hold the results of the calculation
	Make/O/D/N=(1,14) $("CondCalc_"+popStr)
	WAVE CondCalc = $("CondCalc_"+popStr)
	SetDimLabel 1,0,CR_UU,CondCalc
	SetDimLabel 1,1,err_CR_UU,CondCalc
	SetDimLabel 1,2,CR_DU,CondCalc
	SetDimLabel 1,3,err_CR_DU,CondCalc
	SetDimLabel 1,4,CR_DD,CondCalc
	SetDimLabel 1,5,err_CR_DD,CondCalc
	SetDimLabel 1,6,CR_UD,CondCalc
	SetDimLabel 1,7,err_CR_UD,CondCalc
	SetDimLabel 1,8,CR_Blocked,CondCalc
	SetDimLabel 1,9,err_CR_Blocked,CondCalc
	SetDimLabel 1,10,P_sm_f,CondCalc
	SetDimLabel 1,11,err_P_sm_f,CondCalc
	SetDimLabel 1,12,P_sm,CondCalc
	SetDimLabel 1,13,err_P_sm,CondCalc	

	SetDataFolder root:

	return(0)
End


// allows manual entry of Psm and Pf values
//
Function V_ManualEnterPfPsmButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable selRow,err=0
	String fname, t0str, condStr,noteStr,t1Str,cellStr

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable cr1,cr2,cr3,cr4,cr5,err_cr1,err_cr2,err_cr3,err_cr4,err_cr5
			Variable PsmPf, err_PsmPf, Psm, err_Psm
				
			ControlInfo/W=V_FlipperPanel popup_0
			condStr = S_Value
			WAVE w=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:"+condStr)		//the one that is displayed
			WAVE calc=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:CondCalc_"+condStr[5,strlen(condStr)-1])		//the one that holds results
			

			Prompt PsmPf, "Enter PsmPf: "		
			Prompt err_PsmPf, "Enter err_PsmPf: "		
			Prompt Psm, "Enter Psm: "		
			Prompt err_Psm, "Enter err_Psm: "		
			DoPrompt "Enter Supermirror and Flipper Parameters", PsmPf, err_PsmPf, Psm, err_Psm
			if (V_Flag)
				return -1								// User canceled
			endif
			
//	this is the format of the note that is attached to the "Cond_" wave		
//	String testStr = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,Cell=asdf,"
// the "Cell" value was filled in when the Condition was created
	
	
// Put the average values into the wave note and display on the panel
			SVAR gT0 = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gT0
			
			noteStr = note(w)
			noteStr = ReplaceNumberByKey("P_sm_f", noteStr, PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("P_sm", noteStr, Psm ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm_f", noteStr, err_PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm", noteStr, err_Psm ,"=", ",", 0)
			noteStr = ReplaceStringByKey("T0", noteStr, gT0 ,"=", ",", 0)
			
			
			// replace the string
			Note/K w
			Note w, noteStr
					
			//update the global values for display	
			SVAR gPsmPf = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
			SVAR gPsm = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
			sprintf gPsmPf, "%g +/- %g",PsmPf,err_PsmPf
			sprintf gPsm, "%g +/- %g",Psm,err_Psm
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// just recalculate everything, every time
//
// -- now that the cell name is entered, I need to try to catch errors where the cell decay parameters are not
// properly calculated -- right now, invalid cell names are caught, but valid cell names with no decay data
// behind them just calculate Inf for the polarization values. This is hopefull enough to catch someone's attention...
//
Function V_FlipperAverageButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable selRow,err=0
	String fname, t0str, condStr,noteStr,t1Str,cellStr

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable cr1,cr2,cr3,cr4,cr5,err_cr1,err_cr2,err_cr3,err_cr4,err_cr5
			Variable PsmPf, err_PsmPf, Psm, err_Psm
				
			ControlInfo/W=V_FlipperPanel popup_0
			condStr = S_Value
			WAVE w=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:"+condStr)		//the one that is displayed
			WAVE calc=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:CondCalc_"+condStr[5,strlen(condStr)-1])		//the one that holds results
			WAVE/T CellW=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:CondCell_"+condStr[5,strlen(condStr)-1])		//the textW with cell name
			
			Variable numRows,ncalc,diff
			numRows = DimSize(w,0)		//rows in the displayed table
			ncalc = DimSize(calc,0)
			
			// add rows to the ConcCalc_ matrix as needed
			if(numRows != ncalc)
				if(ncalc > numRows)
					DoAlert 0,"The CondCalc_ is larger than displayed. Seek help."
					err = 1
					return(err)
				else
					diff = numRows - ncalc
					InsertPoints/M=0 ncalc, diff, calc
				endif
			endif
			
//			noteStr=note(w)
//			cellStr = StringByKey("Cell", noteStr, "=", ",", 0)
//			Wave decay = $("root:Packages:NIST:Polarization:Cells:Decay_"+cellStr)	
//			noteStr=note(decay)
//			t0Str = StringByKey("T0", noteStr, "=", ",", 0)
//			Print "CellStr, T0 = ",cellStr, t0Str

			Variable sum_PsmPf, err_sum_PsmPf, sum_Psm, err_sum_Psm,nRowsIncluded=0
			sum_PsmPf = 0
			err_sum_PsmPf = 0
			sum_Psm = 0
			err_sum_Psm = 0
			
			for(selRow=0;selRow<numRows;selRow+=1)
				Print "calculate the row ",selRow

				//include this row of data?
				if(w[selRow][%'Include?'] == 1)
					nRowsIncluded += 1
					
					// now the cell depends on the row
					cellStr = CellW[selRow]
					Wave/Z decay = $("root:Packages:NIST:VSANS:Globals:Polarization:Cells:Decay_"+cellStr)
					if(WaveExists(decay) == 0)		// catch gross errors
						Abort "The cell "+cellStr+" in row "+num2str(selRow)+" does not exist"
					endif
					noteStr=note(decay)
					t0Str = StringByKey("T0", noteStr, "=", ",", 0)
	
					// parse the rows, report errors (there, not here), exit if any found
					err = V_ParseFlipperRow(w,selRow)
					if(err)
						return 0
					endif
					
					// do the calculations:
//					cr1 = TotalCR_FromRun(w[selRow][%'UU_Trans?'],err_cr1,1)
//					cr2 = TotalCR_FromRun(w[selRow][%'DU_Trans?'],err_cr2,1)
//					cr3 = TotalCR_FromRun(w[selRow][%'DD_Trans?'],err_cr3,1)	
//					cr4 = TotalCR_FromRun(w[selRow][%'UD_Trans?'],err_cr4,1)
//					cr5 = TotalCR_FromRun(w[selRow][%'Blocked?'],err_cr5,1)		//blocked beam is NOT normalized to zero attenuators
//					Print "The Blocked CR is *NOT* rescaled to zero attenuators -- FlipperAverageButtonProc"
					cr1 = V_TotalCR_FromRun(w[selRow][%'UU_Trans?'],err_cr1,0)
					cr2 = V_TotalCR_FromRun(w[selRow][%'DU_Trans?'],err_cr2,0)
					cr3 = V_TotalCR_FromRun(w[selRow][%'DD_Trans?'],err_cr3,0)	
					cr4 = V_TotalCR_FromRun(w[selRow][%'UD_Trans?'],err_cr4,0)
					cr5 = V_TotalCR_FromRun(w[selRow][%'Blocked?'],err_cr5,0)		//blocked beam is normalized to zero attenuators
					Print "The Blocked CR *IS* rescaled to zero attenuators -- FlipperAverageButtonProc"
	
					calc[selRow][%cr_UU] = cr1
					calc[selRow][%cr_DU] = cr2
					calc[selRow][%cr_DD] = cr3
					calc[selRow][%cr_UD] = cr4
					calc[selRow][%cr_Blocked] = cr5
					calc[selRow][%err_cr_UU] = err_cr1
					calc[selRow][%err_cr_DU] = err_cr2
					calc[selRow][%err_cr_DD] = err_cr3
					calc[selRow][%err_cr_UD] = err_cr4
					calc[selRow][%err_cr_Blocked] = err_cr5
		
					// Calc PsmPf, and assign the values
					PsmPf = V_Calc_PsmPf(w,calc,noteStr,selRow,err_PsmPf)
					calc[selRow][%P_sm_f] = PsmPf
					calc[selRow][%err_P_sm_f] = err_PsmPf
					w[selRow][%Pol_SM_FL] = PsmPf
					
					// Calc Psm, and assign the values
					Psm = V_Calc_Psm(w,calc,noteStr,selRow,err_Psm)
					calc[selRow][%P_sm] = Psm
					calc[selRow][%err_P_sm] = err_Psm
					w[selRow][%Pol_SM] = Psm
	
					// running average of PsmPf and Psm
					sum_PsmPf += PsmPf
					err_sum_PsmPf += err_PsmPf^2 
					sum_Psm += Psm
					err_sum_Psm += err_Psm^2
					
				endif
				
			endfor		//loop over rows
			
			// now get a running average of muP, Po, and the errors
			// use the actual number of rows included
			PsmPf = sum_PsmPf/nRowsIncluded
			Psm = sum_Psm/nRowsIncluded
			err_PsmPf = sqrt(err_sum_PsmPf) / nRowsIncluded
			err_Psm = sqrt(err_sum_Psm) / nRowsIncluded
			
//	this is the format of the note that is attached to the "Cond_" wave		
//	String testStr = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,"
// the "Cell" value is not longer used
	
	
// Put the average values into the wave note and display on the panel
			noteStr = note(w)
			noteStr = ReplaceNumberByKey("P_sm_f", noteStr, PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("P_sm", noteStr, Psm ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm_f", noteStr, err_PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm", noteStr, err_Psm ,"=", ",", 0)
			
			// replace the string
			Note/K w
			Note w, noteStr
					
			//update the global values for display	
			SVAR gPsmPf = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
			SVAR gPsm = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
			sprintf gPsmPf, "%g +/- %g",PsmPf,err_PsmPf
			sprintf gPsm, "%g +/- %g",Psm,err_Psm
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// gCellKW passed in has gamma, muPo, etc. needed for PCell(t) calculation
//
//	TODO:
//  this is only using the measurement at t1 for the calculation!
// -- do I need to recalculate at the midpoint of the time interval?
// -- then how do I define the beginning and ending time?
//
Function V_Calc_PsmPf(w,calc,gCellKW,selRow,err_PsmPf)
	WAVE w,calc
	String gCellKW
	Variable selRow,&err_PsmPf
	
	// DD is cr3, DU is cr2, Blocked is cr5
	String t0Str,t1Str,t2Str,fname
	Variable PsmPf,t1,t2,PCell_t1,PCell_t2,err_PCell_t1,err_PCell_t2
	Variable muPo,err_muPo,gam,err_gam
	Variable crDD, crDU,err_crDD,err_crDU,crBB, err_crBB
	
	t0Str = StringByKey("T0", gCellKW, "=", ",", 0)
	muPo = NumberByKey("muP", gCellKW, "=", ",", 0)
	err_muPo = NumberByKey("err_muP", gCellKW, "=", ",", 0)
	gam = NumberByKey("gamma", gCellKW, "=", ",", 0)
	err_gam = NumberByKey("err_gamma", gCellKW, "=", ",", 0)

	fname = V_FindFileFromRunNumber(w[selRow][%'UU_Trans?'])
	t1str = V_getDataStartTime(fname)		//
	t1 = V_ElapsedHours(t0Str,t1Str)
	
	fname = V_FindFileFromRunNumber(w[selRow][%'DU_Trans?'])
	t2str = V_getDataStartTime(fname)		//
	t2 = V_ElapsedHours(t0Str,t2Str)

	PCell_t1 = V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell_t1)
	PCell_t2 = V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell_t2)
	
	// DD is cr3, DU is cr2, Blocked is cr5
	crDD = calc[selRow][%cr_DD]
	crDU = calc[selRow][%cr_DU]
	crBB = calc[selRow][%cr_Blocked]
	err_crDD = calc[selRow][%err_cr_DD]
	err_crDU = calc[selRow][%err_cr_DU]
	err_crBB = calc[selRow][%err_cr_Blocked]
	
	// this really needs transmissions
//	PsmPf = (crDD - crDU)/(PCell_t1 + PCell_t2)
	
	// eqn (15) from the SS handout
	Variable tmp,dfdx
	tmp = (crDD - crBB)/(crDU - crBB)
	
	PsmPf = (tmp - 1)/(Pcell_t1*(1+tmp))
	
	dfdx = 1/(Pcell_t1*(1+tmp)) - (tmp-1)*Pcell_t1/(Pcell_t1^2*(1+tmp)^2)
	
	err_PsmPf = ( (tmp-1)/((1+tmp)*Pcell_t1^2) *err_Pcell_t1 )^2
	err_PsmPf += ( dfdx / (crDU-crBB) * err_crDD)^2
	err_PsmPf += ( dfdx*(crDD-crBB)/(crDU-crBB)^2 * err_crDU)^2
	err_PsmPf += ( dfdx*(-tmp/(crDD-crBB) + tmp/(crDU-crBB)) * err_crBB)^2
	
	err_PsmPf = sqrt(err_PsmPf)
	Printf "At t1=%g  PsmPf = %g +/- %g (%g %%)\r",t1,PsmPf,err_PsmPf,err_PsmPf/PsmPf*100


	return(PsmPf)
end


// gCellKW passed in has gamma, muPo, etc. needed for PCell(t) calculation
//
//	TODO:
//  this is only using the measurement at t1 for the calculation!
// -- do I need to recalculate at the midpoint of the time interval?
// -- then how do I define the beginning and ending time?
//
//
Function V_Calc_Psm(w,calc,gCellKW,selRow,err_Psm)
	WAVE w,calc
	String gCellKW
	Variable selRow,&err_Psm
	
	// UU is cr1, UD is cr4, Blocked is cr5
	String t0Str,t1Str,t2Str,fname
	Variable Psm,t1,t2,PCell_t1,PCell_t2,err_PCell_t1,err_PCell_t2
	Variable muPo,err_muPo,gam,err_gam
	Variable crUU, crUD,err_crUU,err_crUD,crBB, err_crBB
	
	t0Str = StringByKey("T0", gCellKW, "=", ",", 0)
	muPo = NumberByKey("muP", gCellKW, "=", ",", 0)
	err_muPo = NumberByKey("err_muP", gCellKW, "=", ",", 0)
	gam = NumberByKey("gamma", gCellKW, "=", ",", 0)
	err_gam = NumberByKey("err_gamma", gCellKW, "=", ",", 0)

	fname = V_FindFileFromRunNumber(w[selRow][%UU_Trans])
	t1str = V_getDataStartTime(fname)		//
	t1 = V_ElapsedHours(t0Str,t1Str)
	
	fname = V_FindFileFromRunNumber(w[selRow][%DU_Trans])
	t2str = V_getDataStartTime(fname)		//
	t2 = V_ElapsedHours(t0Str,t2Str)

	PCell_t1 = V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell_t1)
	PCell_t2 = V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell_t2)
	
	// UU is cr1, UD is cr4, Blocked is cr5
	crUU = calc[selRow][%cr_UU]
	crUD = calc[selRow][%cr_UD]
	crBB = calc[selRow][%cr_Blocked]
	err_crUU = calc[selRow][%err_cr_UU]
	err_crUD = calc[selRow][%err_cr_UD]
	err_crBB = calc[selRow][%err_cr_Blocked]
	
	// this really needs transmissions
	
	// eqn (14) from the SS handout
	Variable tmp,dfdx
	tmp = (crUU - crBB)/(crUD - crBB)
	
	Psm = (tmp - 1)/(Pcell_t1*(1+tmp))
	
	dfdx = 1/(Pcell_t1*(1+tmp)) - (tmp-1)*Pcell_t1/(Pcell_t1^2*(1+tmp)^2)
	
	err_Psm = ( (tmp-1)/((1+tmp)*Pcell_t1^2) *err_Pcell_t1 )^2
	err_Psm += ( dfdx / (crUD-crBB) * err_crUU)^2
	err_Psm += ( dfdx*(crUU-crBB)/(crUD-crBB)^2 * err_crUD)^2
	err_Psm += ( dfdx*(-tmp/(crUU-crBB) + tmp/(crUD-crBB)) * err_crBB)^2
	
	err_Psm = sqrt(err_Psm)
	Printf "At t1=%g  Psm = %g +/- %g (%g %%)\r",t1,Psm,err_Psm,err_Psm/Psm*100


	return(Psm)
end

//
// calculate the (atomic) He polarization at some delta time
//
// t2 is in hours, gamma in hours
//
Function V_Calc_PHe_atT(Po,err_Po,gam,err_gam,t2,err_Pt)
	Variable Po,err_Po,gam,err_gam,t2,&err_Pt


	Variable Pt	

	Pt = Po*exp(-t2/gam)
	
	Variable arg,tmp2
	// 2 terms, no error in t2
	err_Pt = Pt^2/Po^2*err_Po^2 + t2^2/gam^4*Pt^2*err_gam^2
	
	err_Pt = sqrt(err_Pt)
	
	Printf "At (delta)t=%g  P_He(t) = %g +/- %g (%g %%)\r",t2,Pt,err_Pt,err_Pt/Pt*100

	return(Pt)
End



//
// t2 is in hours, muP0 is at t0
//
Function V_Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell)
	Variable muPo,err_muPo,gam,err_gam,t2,&err_PCell


	Variable Pcell

	PCell = tanh(muPo * exp(-t2/gam))
//	PCell = (muPo * exp(-t2/gam))
	
	Variable arg,tmp2
	arg = PCell
	tmp2 = (1-tanh(arg)^2)^2
	err_PCell = tmp2 * (exp(-t2/gam) * err_muPo)^2			//dominant term (10x larger)
	err_PCell += tmp2 * (arg*t2/gam/gam * err_gam)^2
	
	err_PCell = sqrt(err_Pcell)
	
	Printf "At t=%g  Pcell = %g +/- %g (%g %%)\r",t2,Pcell,err_Pcell,err_Pcell/PCell*100

	return(PCell)
End

// bring up a table with the calculation results
Function V_ShowFlipperCalcButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo/W=V_FlipperPanel popup_0
			String condStr = S_Value
			condStr = condStr[5,strlen(condStr)-1]		// trim off "Calc_" from the beginning of the string
			WAVE calc=$("root:Packages:NIST:VSANS:Globals:Polarization:Cells:CondCalc_"+condStr)		
			edit calc.ld
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// clear just the row
//
Function V_ClearFlipperRowButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String popStr=""
	Variable selRow
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 1,"Clear the selected row?"
			if(V_flag !=1)
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

			ControlInfo/W=V_FlipperPanel popup_0
			popStr = S_Value
			popStr = StringFromList(1,S_Value,"_")			//pop is "Cond_<condition>", so get list item 1
			
			Wave cond = $("Cond_"+popStr)
			Wave calc = $("CondCalc_"+popStr)
			Wave/T cellW = $("CondCell_"+popStr)
			
			// Delete just those points
						
			GetSelection table, V_FlipperPanel#T0, 1
			selRow = V_startRow
			DeletePoints selRow,1,cond,calc,cellW			
			
			// clear the graph and the results			
			SVAR gPsm = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
			SVAR gPsmPf  = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
			gPsm = "0"
			gPsmPf = "0"
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// for this, do I want to clear everything, or just a selected row??
//
//
Function V_ClearAllFlipperWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String popStr=""
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 1,"Clear all of the flipper waves for the selected cell?"
			if(V_flag !=1)
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

			ControlInfo/W=V_FlipperPanel popup_0
			popStr = StringFromList(1,S_Value,"_")			//pop is "Cond_<condition>", so get list item 1
			
			Wave cond = $("Cond_"+popStr)
			Wave calc = $("CondCalc_"+popStr)
			Wave/T cellW = $("CondCell_"+popStr)
			
//			re-initialize the flipper waves, so it appears as a blank, initialized table

			V_MakeFlipperResultWaves(popStr)
			cond = 0
			calc = 0
//			cellW = ""
			cond[0][7] = 1			//default to include the point

			// clear the graph and the results?	
			
			
			SVAR gPsm = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsm
			SVAR gPsmPf  = root:Packages:NIST:VSANS:Globals:Polarization:Cells:gPsmPf
			gPsm = "0"
			gPsmPf = "0"
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_FlipperHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Flipper States Panel"
			if(V_flag !=0)
				DoAlert 0,"The Flipper States Panel Help file could not be found"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// null condition is not right. if the loop fails, then the 
// retStr will be ";;;;", not zero length. What's the proper test?
// Does it matter? the list of default gCell_sss should already be there.
//
Function/S V_D_ConditionNameList()

	String listStr=""
	
	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

	// get a list of the Condition waves
	listStr=WaveList("Cond_*",";","")
//	print listStr
	
	if(strlen(listStr) == 0)
		listStr = "no conditions defined;"
	endif
	
	SetDataFolder root:		
	return(listStr)
End


// parse the row to be sure that:
//
// - files are valid numbers
// - files are all at same SDD
// - files are all with same attenuation (just print a warning to cmd)
// - files all use the same cell
// - files are all within 20 minutes of each other
//
//
//	SetDimLabel 1,0,UU_Trans,cond
//	SetDimLabel 1,1,DU_Trans,cond
//	SetDimLabel 1,2,DD_Trans,cond
//	SetDimLabel 1,3,UD_Trans,cond
//	SetDimLabel 1,4,Blocked,cond
//	SetDimLabel 1,5,Pol_SM_FL,cond
//	SetDimLabel 1,6,Pol_SM,cond			//for a mask wave, non-zero is used in the fit
//	SetDimLabel 1,7,Include,cond
//
// There are 5 separate files now
//
Function V_ParseFlipperRow(w,selRow)
	Wave w
	Variable selRow
	
	Variable err=0
	Variable atten1,atten2,atten3,atten4,atten5
	Variable sdd1,sdd2,sdd3,sdd4,sdd5
	Variable t1,t2,t3,t4,t5
	String cell1,cell2,cell3,cell4,cell5
	

	DoAlert 0,"I am trusting that the configurations match in parseFlipperRow"
	
	String fname=""
	
	
	// are all file numbers valid?
	fname = V_FindFileFromRunNumber(w[selRow][%'UU_Trans?'])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"UU_Trans run "+num2str(w[selRow][%'UU_Trans?'])+" is not a valid run number"
		err = 1
	else
//				Abort "bad flipper"
//		atten1 = V_getAttenNumber(fname)
//		sdd1 = V_getSDD(fname)
	endif
	
	fname = V_FindFileFromRunNumber(w[selRow][%'DU_Trans?'])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"DU_Trans run "+num2str(w[selRow][%'DU_Trans?'])+" is not a valid run number"
		err = 1
	else
//				Abort "bad flipper"
//		atten2 = V_getAttenNumber(fname)
//		sdd2 = V_getSDD(fname)
	endif
	
	fname = V_FindFileFromRunNumber(w[selRow][%'DD_Trans?'])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"DD_Trans run "+num2str(w[selRow][%'DD_Trans?'])+" is not a valid run number"
		err = 1
	else
//				Abort "bad flipper"
//		atten3 = V_getAttenNumber(fname)
//		sdd3 = V_getSDD(fname)
	endif
	
	fname = V_FindFileFromRunNumber(w[selRow][%'UD_Trans?'])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"UD_Trans run "+num2str(w[selRow][%'UD_Trans?'])+" is not a valid run number"
		err = 1
	else
//				Abort "bad flipper"
//		atten4 = V_getAttenNumber(fname)
//		sdd4 = V_getSDD(fname)
	endif
	
	fname = V_FindFileFromRunNumber(w[selRow][%'Blocked?'])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"Blocked run "+num2str(w[selRow][%'Blocked?'])+" is not a valid run number"
		err = 1
	else
//				Abort "bad flipper"
//		atten5 = V_getAttenNumber(fname)
//		sdd5 = V_getSDD(fname)
	endif
	
	
	
	// do a check of the elapsed time from start to finish
	
//	if( (sdd1 != sdd2) || (sdd2 != sdd3) || (sdd1 != sdd3) )
//		DoAlert 0,"Files in row "+num2str(selRow)+" are not all at the same detector distance"
//		err = 1
//	endif
//	
//
//	if( (atten1 != atten2) || (atten2 != atten3) || (atten1 != atten3) )
//		DoAlert 0,"Files in row "+num2str(selRow)+" are not all collected with the same attenuation. Just so you know."
//		err = 0
//	endif
	
	return(err)
end


////////////////////////////////////////////



///////////////////////
//
//
// Utilities to write out waves as Igor Text
//
//
// -- TODO
// -- add flags for SetScale, Note, DimLabels, text? (or a separate function)
// x- add a function for 2D waves. wfprintf is not 2D aware...


Function V_testWriteITX()

	Variable refnum
	String fname="a_test.itx"
//	WAVE w=root:testMat
//	WAVE/T w=root:testText
	WAVE/T w=root:Packages:NIST:VSANS:Globals:Polarization:ListWave_0_UU
	
	
	Open/P=home refnum as fname		// creates a new file, or overwrites the existing file
	
	fprintf refNum,"IGOR\r"
	
//	Write1DWaveToITX(w,refnum)
//	Write2DWaveToITX(w,refnum)
//	Write1DTextWaveToITX(w,refnum)
	V_Write2DTextWaveToITX(w,refnum)	
	Close refnum

	return(0)
end

// writes out a 1D wave as Igor Text
// 
// the wave and a valid refNum to an open file are passed
//
// the file is NOT closed when exiting
//
Function V_Write1DWaveToITX(w,refnum)
	Wave w
	Variable refNum
	
	String tmpStr,waveStr
	waveStr=NameOfWave(w)
	
	fprintf refNum,"WAVES/D\t%s\r",waveStr

	fprintf refNum,"BEGIN\r"

	wfprintf refnum, "\t%g\r",w
	
	fprintf refNum,"END\r"

	fprintf refnum,"X SetScale/P x 0,1,\"\", %s; SetScale y 0,0,\"\", %s\r",waveStr,waveStr
	
//	X SetScale/P x 0,1,"", fyy; SetScale y 0,0,"", fyy
	
	
	return(0)
End

// writes out a 1D TEXT wave as Igor Text
// 
// the wave and a valid refNum to an open file are passed
//
// the file is NOT closed when exiting
//
Function V_Write1DTextWaveToITX(w,refnum)
	Wave/T w
	Variable refNum
	
	String tmpStr,waveStr
	waveStr=NameOfWave(w)
	
	fprintf refNum,"WAVES/T\t%s\r",waveStr

	fprintf refNum,"BEGIN\r"

	wfprintf refnum, "\t\"%s\"\r",w
	
	fprintf refNum,"END\r"

	fprintf refnum,"X SetScale/P x 0,1,\"\", %s; SetScale y 0,0,\"\", %s\r",waveStr,waveStr	
	
	return(0)
End

// writes out a 2D TEXT wave as Igor Text
// 
// the wave and a valid refNum to an open file are passed
//
// the file is NOT closed when exiting
//
Function V_Write2DTextWaveToITX(w,refnum)
	Wave/T w
	Variable refNum
	
	String tmpStr,waveStr
	Variable row,col,ii,jj,tmp
	
	row=DimSize(w, 0 )
	col=DimSize(w, 1 )
	waveStr=NameOfWave(w)
		
	fprintf refNum,"WAVES/T/N=(%d,%d)\t%s\r",row,col,waveStr
	fprintf refNum,"BEGIN\r"

	for(ii=0;ii<row;ii+=1)
		for(jj=0;jj<col;jj+=1)
			fprintf refnum, "\t\"%s\"",w[ii][jj]
		endfor
		fprintf refnum, "\r"
	endfor
	
	
	fprintf refNum,"END\r"

	fprintf refnum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",waveStr,waveStr,waveStr
	
//	X SetScale/P x 0,1,"", testMat; SetScale/P y 0,1,"", testMat; SetScale d 0,0,"", testMat

	
	
	return(0)
End

// writes out a 2D wave as Igor Text
// 
// the wave and a valid refNum to an open file are passed
//
// the file is NOT closed when exiting
//
Function V_Write2DWaveToITX(w,refnum)
	Wave w
	Variable refNum
	
	String tmpStr,waveStr
	Variable row,col,ii,jj,tmp
	
	row=DimSize(w, 0 )
	col=DimSize(w, 1 )
	waveStr=NameOfWave(w)
		
	fprintf refNum,"WAVES/D/N=(%d,%d)\t%s\r",row,col,waveStr
	fprintf refNum,"BEGIN\r"

	for(ii=0;ii<row;ii+=1)
		for(jj=0;jj<col;jj+=1)
			fprintf refnum, "\t%g",w[ii][jj]
		endfor
		fprintf refnum, "\r"
	endfor
	
	
	fprintf refNum,"END\r"

	fprintf refnum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",waveStr,waveStr,waveStr
	
//	X SetScale/P x 0,1,"", testMat; SetScale/P y 0,1,"", testMat; SetScale d 0,0,"", testMat

	
	
	return(0)
End

// root:Packages:NIST:Polarization:Cells:
// save the state of the pink panel, as CellParamSaveState.itx
Function V_SaveCellParameterTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	// the waves are:
	// CellName (T)
	// lambda
	// Te, err_Te
	// mu, err_mu
	
	Variable refnum
	String fname="CellParamSaveState"
//	WAVE w=root:testMat
	WAVE/T cellName=root:Packages:NIST:VSANS:Globals:Polarization:Cells:CellName
	WAVE lambda=root:Packages:NIST:VSANS:Globals:Polarization:Cells:lambda
	WAVE Te=root:Packages:NIST:VSANS:Globals:Polarization:Cells:Te
	WAVE err_Te=root:Packages:NIST:VSANS:Globals:Polarization:Cells:err_Te
	WAVE mu=root:Packages:NIST:VSANS:Globals:Polarization:Cells:mu
	WAVE err_mu=root:Packages:NIST:VSANS:Globals:Polarization:Cells:err_mu
	
	// get the full path to the new file name before creating it
	fname = V_DoSaveFileDialog("Save the Cell Table",fname=fname,suffix=".itx")
	If(cmpstr(fname,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	
	Open/P=home refnum	as fname		// creates a new file, or overwrites the existing file	
	
	fprintf refNum,"IGOR\r"
	
	V_Write1DTextWaveToITX(cellName,refnum)
	fprintf refNum,"\r"	

	V_Write1DWaveToITX(lambda,refnum)
	fprintf refNum,"\r"	
	
	V_Write1DWaveToITX(Te,refnum)
	fprintf refNum,"\r"	

	V_Write1DWaveToITX(err_Te,refnum)
	fprintf refNum,"\r"	
	
	V_Write1DWaveToITX(mu,refnum)
	fprintf refNum,"\r"	
	
	V_Write1DWaveToITX(err_mu,refnum)
			
	Close refnum

	SetDataFolder root:
		
	return(0)
End

//could use /P=home, but the whole point is that this is for users without Igor licenses, that can't save... so "home" won't exist...
Function V_RestoreCellParameterTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	String fname="CellParamSaveState.itx"

//	LoadWave/P=home/O/T fname
	LoadWave/O/T fname
	
	SetDataFolder root:
	return(0)
End


// saves the parameters for the cell decay table
//
// 	fname = "CellDecayPanelSaveState.itx"
//
//
Function V_SaveCellDecayTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "CellDecaySaveState"
	
	// get a list of the Decay waves
	listStr=WaveList("Decay_*",";","")
	num=ItemsInList(listStr,";")
//	print listStr

	// get the full path to the new file name before creating it
	fname = V_DoSaveFileDialog("Save the Cell Decay Table",fname=fname,suffix=".itx")
	If(cmpstr(fname,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif

	Open/P=home refnum as fname		// creates a new file, or overwrites the existing file	
	fprintf refNum,"IGOR\r"
			
	// Save each of the decay waves, then be sure to add the DimLabels and Wave Note
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item
		wStr=NameOfWave(w)
		noteStr = note(w)
		
		V_Write2DWaveToITX(w,refnum)
		
//		fprintf refNum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",wStr,wStr,wStr
		fprintf refNum,"X SetDimLabel 1, 0, 'Trans_He_In?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 1, 'Trans_He_Out?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 2, 'Blocked?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 3, mu_star, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 4, Effective_Pol, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 5, Atomic_Pol, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 6, T_Major, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 7, 'Include?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 8, elapsed_hr, %s\r",wStr		
		fprintf refNum,"X Note %s, \"%s\"\r",wStr,noteStr

		fprintf refNum,"\r"		//space between waves
	endfor	

	// get a list of the DecayCalc_ waves
	listStr=WaveList("DecayCalc_*",";","")
	num=ItemsInList(listStr,";")	
	
	// Save each of the DecayCalc waves, and add all of the proper dim labels
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item
		wStr=NameOfWave(w)

		V_Write2DWaveToITX(w,refnum)
		
//		fprintf refNum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",wStr,wStr,wStr
		fprintf refNum,"X SetDimLabel 1, 0, CR_Trans_He_In, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 1, err_CR_Trans_He_In, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 2, CR_Trans_He_Out, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 3, err_CR_Trans_He_Out, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 4, CR_Blocked, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 5, err_CR_Blocked, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 6, muPo, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 7, err_muPo, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 8, Po, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 9, err_Po, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 10, Tmaj, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 11, err_Tmaj, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 12, gamm, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 13, err_gamm, %s\r",wStr

		fprintf refNum,"\r"	
	endfor	
	
	Close refnum

	SetDataFolder root:
	return(0)
End

// restores the waves for the cell decay table
//
// 	fname = "CellDecayPanelSaveState.itx"
//
//
Function V_RestoreCellDecayTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "CellDecayPanelSaveState.itx"
	LoadWave/O/T fname
	
	SetDataFolder root:
	return(0)
End



////////
//
// save the state of the Flipper panel
//
// 	fname = "FlipperPanelSaveState.itx"
//
Function V_SaveFlipperTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "FlipperSaveState"
	
	// get a list of the "Condition" waves
	listStr=WaveList("Cond_*",";","")
	num=ItemsInList(listStr,";")
//	print listStr

	// get the full path to the new file name before creating it
	fname = V_DoSaveFileDialog("Save the Flipper State Table",fname=fname,suffix=".itx")
	If(cmpstr(fname,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	
	Open/P=home refnum	as fname		// creates a new file, or overwrites the existing file	
	fprintf refNum,"IGOR\r"
			
	// Save each of the cond waves, then be sure to add the DimLabels and Wave Note
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item
		wStr=NameOfWave(w)
		noteStr = note(w)
		
		V_Write2DWaveToITX(w,refnum)
		
//		fprintf refNum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",wStr,wStr,wStr
		fprintf refNum,"X SetDimLabel 1, 0, 'UU_Trans?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 1, 'DU_Trans?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 2, 'DD_Trans?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 3, 'UD_Trans?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 4, 'Blocked?', %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 5, Pol_SM_FL, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 6, Pol_SM, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 7, 'Include?', %s\r",wStr
		fprintf refNum,"X Note %s, \"%s\"\r",wStr,noteStr

		fprintf refNum,"\r"		//space between waves
	endfor	

	// get a list of the CondCalc_ waves (2d, with dimlabels)
	listStr=WaveList("CondCalc_*",";","")
	num=ItemsInList(listStr,";")	
	
	// Save each of the DecayCalc waves, and add all of the proper dim labels
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item
		wStr=NameOfWave(w)

		V_Write2DWaveToITX(w,refnum)
		
//		fprintf refNum,"X SetScale/P x 0,1,\"\", %s; SetScale/P y 0,1,\"\", %s; SetScale d 0,0,\"\", %s\r",wStr,wStr,wStr
		fprintf refNum,"X SetDimLabel 1, 0, CR_UU, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 1, err_CR_UU, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 2, CR_DU, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 3, err_CR_DU, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 4, CR_DD, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 5, err_CR_DD, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 6, CR_UD, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 7, err_CR_UD, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 8, CR_Blocked, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 9, err_CR_Blocked, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 10, P_sm_f, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 11, err_P_sm_f, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 12, P_sm, %s\r",wStr
		fprintf refNum,"X SetDimLabel 1, 13, err_P_sm, %s\r",wStr

		fprintf refNum,"\r"	
	endfor	
	
	// get a list of the CondCell_ waves (these are text, 1d)
	listStr=WaveList("CondCell_*",";","")
	num=ItemsInList(listStr,";")	
	
	// Save each of the DecayCalc waves, and add all of the proper dim labels
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		Wave w = $item
		wStr=NameOfWave(w)

		V_Write1DTextWaveToITX(w,refnum)

//		fprintf refnum,"X SetScale/P x 0,1,\"\", wStr; SetScale y 0,0,\"\", %s\r",wStr

		fprintf refNum,"\r"	
	endfor	

	Close refnum

	SetDataFolder root:
	return(0)
end



// restores the state of the Flipper panel
//
// 	fname = "FlipperPanelSaveState.itx"
//
//
Function V_RestoreFlipperTable()

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells:
	
	String listStr,item,fname,noteStr,wStr
	Variable num,ii,refnum
	
	fname = "FlipperPanelSaveState.itx"
	LoadWave/O/T fname
	
	SetDataFolder root:
	return(0)
End

//
// TODO
//
// look for the active subwindow T0 (the table)
// then see if I can do somehting with this information - by putting
// up an appropriate list of files to choose from based on where I am
//
//
// - OR -- do I try to fill in the table based on parsing of the metadata
// do a "test" fill in, and then allow it to be copied over to the real table?
//
//
Function V_FlipperTableHook(infoStr)
	String infoStr
	String event= StringByKey("EVENT",infoStr)


// check to see that the table is where the click was - if not, exit
	GetWindow V_FlipperPanel activeSW
	String activeSubwindow = S_value
	if (CmpStr(activeSubwindow,"V_FlipperPanel#T0") != 0)
		return 0
	endif
	
	ControlInfo popup_0
	Variable ii
	WAVE/Z dw = $("root:Packages:NIST:VSANS:Globals:Polarization:Cells:"+ S_Value)
	
	// the different column labels are:
	//   	UU_Trans?
	//   	DU_Trans?
	//   	DD_Trans?
	//   	UD_Trans?
  	//		Blocked?
  	// and each of these need a different set of files
  	// if the label doesn't match, present no popup
  
  	Variable state
  	String intent,dimLbl,flipStr,popList
  	
//	Print "EVENT= ",event
	strswitch(event)
		case "mouseup":
//
			GetSelection table,V_FlipperPanel#T0,3
//			Print V_startRow, V_StartCol
//			Print S_Selection
//			Print GetDimLabel(dw, 1, V_StartCol -2 )

			if(V_StartCol < 2)
				break
			endif
			
			dimLbl = GetDimLabel(dw, 1, V_StartCol -2)
			// what am I looking for?
			if(cmpstr(dimLbl,"UU_Trans?")==0)
				flipStr = "T_UU"
				intent = "Sample"	
				popList = V_ListForFlipperPanel(flipStr,intent)
				intent = "Open Beam"
				popList += V_ListForFlipperPanel(flipStr,intent)
				
				popList = SortList(popList)
				
				PopupContextualMenu "Paste All;"+popList

				if(cmpstr(S_Selection,"Paste All")==0)
					popList = ReplaceString(";",popList,"\r")		//paste the whole list, in order
					PutScrapText popList
				else
					PutScrapText S_Selection
				endif	
				
				DoIgorMenu "Edit", "Paste"

			endif

			if(cmpstr(dimLbl,"DU_Trans?")==0)
				flipStr = "T_DU"
				intent = "Sample"	
				popList = V_ListForFlipperPanel(flipStr,intent)
				intent = "Open Beam"
				popList += V_ListForFlipperPanel(flipStr,intent)
				
				popList = SortList(popList)
				
				PopupContextualMenu "Paste All;"+popList

				if(cmpstr(S_Selection,"Paste All")==0)
					popList = ReplaceString(";",popList,"\r")		//paste the whole list, in order
					PutScrapText popList
				else
					PutScrapText S_Selection
				endif	
				
				DoIgorMenu "Edit", "Paste"

			endif

			if(cmpstr(dimLbl,"DD_Trans?")==0)
				flipStr = "T_DD"
				intent = "Sample"	
				popList = V_ListForFlipperPanel(flipStr,intent)
				intent = "Open Beam"
				popList += V_ListForFlipperPanel(flipStr,intent)
				
				popList = SortList(popList)
				
				PopupContextualMenu "Paste All;"+popList

				if(cmpstr(S_Selection,"Paste All")==0)
					popList = ReplaceString(";",popList,"\r")		//paste the whole list, in order
					PutScrapText popList
				else
					PutScrapText S_Selection
				endif	
				
				DoIgorMenu "Edit", "Paste"

			endif

			if(cmpstr(dimLbl,"UD_Trans?")==0)
				flipStr = "T_UD"
				intent = "Sample"	
				popList = V_ListForFlipperPanel(flipStr,intent)
				intent = "Open Beam"
				popList += V_ListForFlipperPanel(flipStr,intent)
				
				popList = SortList(popList)
				
				PopupContextualMenu "Paste All;"+popList

				if(cmpstr(S_Selection,"Paste All")==0)
					popList = ReplaceString(";",popList,"\r")		//paste the whole list, in order
					PutScrapText popList
				else
					PutScrapText S_Selection
				endif	
				
				DoIgorMenu "Edit", "Paste"

			endif
// this actually looks for a different type of file from the decay panel
			if(cmpstr(dimLbl,"Blocked?")==0) // check for both HeIN or HeOUT
				State = 0
				intent = "Blocked Beam"
				popList = V_ListForDecayPanel(state,intent)
				state = 1
				popList += V_ListForDecayPanel(state,intent)
				popList = SortList(popList)
				PopupContextualMenu popList
	
				PutScrapText S_Selection
				DoIgorMenu "Edit", "Paste"

			endif

	// any other column label, don't display anything


	endswitch	// event


	return(0)
end
