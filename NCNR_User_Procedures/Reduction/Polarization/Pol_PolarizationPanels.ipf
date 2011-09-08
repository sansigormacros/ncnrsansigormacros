#pragma rtGlobals=1		// Use modern global access method.


// Polarized Beam Reduction Procedures
//
//
// input panels to set and calculate polarization parameters necessary for the 
// matrix corrections to the cross sections
//
// -1- Fundamental Cell Parameters -- these are constants, generally not editable. (this file)
// -2- Decay Parameters -- these are fitted values based on transmission mearurements (this file)
// -3- Flipper Panel is in its own procedure (FlipperPanel.ipf)
// -4- PolCor_Panel is in PolarizationCorrection.ipf

//
// Driven by 4 panels to get the necessary information from the users
// -1- Fundamental cell parameters: root:Packages:NIST:Polarization:Cells
//		- default cell parameters are loaded. More cell definitions can be added as more cells are used
//		- changes are saved per experiment
//		- important parameters are held in global key=value strings gCell_<name> 
//		- cell names and parameters are used by the 2nd panel for calculation of the Decay constant
//
// -2- Decay Constant Panel
//		- decay constant determined for each cell.
//		- popping the cell name makes 2 waves, Decay_<cellname> and DecayCalc_<cellname>
//		- Decay_ is the wave presented in the table. Specified transmission run numbers are entered
//			and "Calc Sel Row" does the calculation of mu and Pcell (for all rows, actually)
//		- DimLabels are used for the arrays to make the column identity more readable than simply an index
//		- time=0 is taken from the first file
//		- Calculations are based on the count rate of the file, corrected for monitor and attenuation
//		- alerts are posted for files in any row that are not at the same attenuation or SDD
//		- if "include" column is == 1, that row will be included in the fit of the decay data
//		- excluded points are plotted in red
//		- results of the fit are printed on the panel, and written to the wave note of the Decay_ wave 
//			(not DecayCalc_) for use in the next panel
//		- manual entry of all of the parameters in the wave note is allowed.
//
//
// -3- Flipper Panel (not in this procedure - in Pol_FlipperPanel.ipf)
//		- calculates the flipper and supermirror efficiencies for a given "condition"
//		- this "condition" may have contributions from multiple cells
//		- start by entering a condition name
//		- Waves Cond_<condition> and CondCalc_<condition>, and CondCell are created
//		- DimLabels are used for the arrays to make the column identity more readable than simply an index
//		- Enter the name of the cell in the first column (the cell must be defined and decay calculated)
// 		- enter transmission run numbers as specified in the table
//		- Do Average will calculate the Psm and PsmPfl values (and errors) and average if more than
//			one row of data is present (and included)
//		- results are printed on the panel, and written to the wave note of Cond_<condition>
//		- results are used in the calculation of the polarization matrix
//		- (the cell name is not entered using a contextual menu, since this is difficult for a subwindow)
//		- (the wave note no longer needs the cell name)
//
// -4- PolCor_Panel (not in this procedure - in Pol_PolarizationCorrection.ipf)
//		- gets all of the parameters from the user to do the polariztion correction, then the "normal" SANS reduction
//		- up to 10 files can be added together for each of the different spin states (more than this??)
//		- one polarization condition is set for everything with the popup @ the top
//		- two-column list boxes for each state hold the run number and the cell name
//		- the same list boxes are duplicated (hidden) for the SAM/EMP/BGD tabs as needed
//		- on loading of the data, the 2-letter spin state is tagged onto the loaded waves (all of them)
//		- displayed data is simply re-pointed to the desired data
//		- on loading, the raw files are added together as ususal, normalized to monitor counts. Then each contribution 
//			of the file to the polarization matrix is added (scaling each by mon/1e8)
//		- loaded data and PolMatrix are stored in the ususal SAM, EMP, BGD folders.
//		- Polarization correction is done with one click (one per tab). "_pc" tags are added to the resulting names,
//			and copies of all of the associated waves are again copied (wasteful), but makes switching display very easy
//		- Once all of the polariztion correction is done, then the UU_pc (etc.) data can be reduced as usual (xx_pc = 4 passes)
//		- protocol is built as ususal, from this panel only (since the SAM, EMP, and BGD need to be switched, rather than loaded
//		- protocols can be saved/recalled.
//		- reduction will always ask for a protocol rather than using what's on the panel.
//		- closing the panel will save the state (except the protocol). NOT initializing when re-opening will restore the 
//			state of the entered runs and the popups of conditions.
//
//
//
//




//
// Panel -1-
//
// Fundamental He cell parameters. Most of these are pre-defined, so that they are supplied as a 
// static table, only edited as parameters are refined.
//
// work with this as kwString
// cell=nameStr
// lambda=num
// Te=num
// err_Te=num
// mu=nnum
// err_mu=num
//
//
// for this panel, the cell parameters are stored as kw strings
// all of the strings start w/ "gCell_"
//
Macro ShowCellParamPanel()
	
	// init folders
	// ASK before initializing cell constants
	// open the panel
	DoWindow/F CellParamPanel
	if(V_flag == 0)
		InitPolarizationFolders()
		DoAlert 1,"Do you want to use default parameters?"
		if(V_flag == 1)
			InitPolarizationGlobals()
		endif
		Make_HeCell_ParamWaves()
		DrawCellParamPanel()
	endif

end

// setup the data folder, etc
//
//
Function InitPolarizationFolders()

	NewDataFolder/O root:Packages:NIST:Polarization
	NewDataFolder/O root:Packages:NIST:Polarization:Cells			//holds the cell constants and waves
	
	SetDataFolder root:
	return(0)
End

//
// add more cells here as they are defined
//
Function InitPolarizationGlobals()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	// cell constants
	String/G gCell_Maverick = "cell=Maverick,lambda=5.0,Te=0.87,err_Te=0.01,mu=3.184,err_mu=0.2,"
	String/G gCell_Burgundy = "cell=Burgundy,lambda=5.0,Te=0.86,err_Te=0.01,mu=3.138,err_mu=0.15,"
	String/G gCell_Olaf = "cell=Olaf,lambda=7.5,Te=0.86,err_Te=0.005,mu=2.97,err_mu=0.18,"
	
	
	SetDataFolder root:
	return(0)
End


// parse strings to fill in waves
//
//
Function Make_HeCell_ParamWaves()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	String listStr,item
	Variable num,ii
	
	// get a list of the strings
	listStr=StringList("gCell_*",";")
	num=ItemsInList(listStr,";")
	print listStr
	
	Make/O/T/N=0 CellName
	Make/O/N=0 lambda,Te,err_Te,mu,err_mu
	
	// parse the strings to fill the table
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		SVAR gStr = $item
		InsertPoints  ii, 1, CellName,lambda,Te,err_Te,mu,err_mu
		CellName[ii] = StringByKey("cell", gStr, "=", ",", 0)
		lambda[ii] = NumberByKey("lambda", gStr, "=", ",", 0)
		Te[ii] = NumberByKey("Te", gStr, "=", ",", 0)
		err_Te[ii] = NumberByKey("err_Te", gStr, "=", ",", 0)
		mu[ii] = NumberByKey("mu", gStr, "=", ",", 0)
		err_mu[ii] = NumberByKey("err_mu", gStr, "=", ",", 0)
		
	endfor

	
	SetDataFolder root:
	return(0)
End

// take the waves from the table and write these back to the string, only for the current experiment
//
Function Save_HeCell_ParamWaves()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	String listStr,item,dummyStr
	Variable num,ii
	
	// get a list of the strings
	listStr=StringList("gCell_*",";")
	num=ItemsInList(listStr,";")
	KillStrings/Z listStr
	
	Wave/T CellName
	Wave lambda,Te,err_Te,mu,err_mu
	
	dummyStr = "cell=Maverick,lambda=5.0,Te=0.87,err_Te=0.01,mu=3.184,err_mu=0.2,"
	
	num=numpnts(CellName)
	
	// parse the table to fill the Strings
	for(ii=0;ii<num;ii+=1)
		item = "gCell_"+CellName[ii]
		String/G $item = dummyStr
		SVAR kwListStr = $item
		
		kwListStr = ReplaceStringByKey("cell", kwListStr, CellName[ii], "=", ",", 0)
		kwListStr = ReplaceNumberByKey("lambda", kwListStr, lambda[ii], "=", ",", 0)
		kwListStr = ReplaceNumberByKey("Te", kwListStr, Te[ii], "=", ",", 0)
		kwListStr = ReplaceNumberByKey("err_Te", kwListStr, err_Te[ii], "=", ",", 0)
		kwListStr = ReplaceNumberByKey("mu", kwListStr, mu[ii], "=", ",", 0)
		kwListStr = ReplaceNumberByKey("err_mu", kwListStr, err_mu[ii], "=", ",", 0)
		
	endfor

	SetDataFolder root:
	return(0)
End


// makes the panel after the waves are generated
//
// allow edits of the cells to update the string values
// add a button to "revert" (with warning)
// add a button to add new cells (insert a new row in the table, then update)
//
Function DrawCellParamPanel()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(775,44,1375,377)/N=CellParamPanel/K=1 as "Fundamental Cell Parameters"
	ModifyPanel cbRGB=(65535,49151,55704)
	ModifyPanel fixedSize=1

//	ShowTools/A
	Button button_0,pos={10,10},size={90,20},proc=AddCellButtonProc,title="Add Cell"
	Button button_1,pos={118,10},size={130,20},proc=SaveCellParButtonProc,title="Save Parameters"
	Button button_2,pos={265,10},size={130,20},proc=RevertCellParButtonProc,title="Revert Parameters"
	Button button_3,pos={420,10},size={35,20},proc=CellHelpParButtonProc,title="?"

	
	Edit/W=(14,55,582,318)/HOST=#
	ModifyTable width(Point)=0
	RenameWindow #,T0

	WAVE/T CellName
	WAVE lambda,Te,err_Te,mu,err_mu

	AppendtoTable/W=# CellName,lambda,Te,err_Te,mu,err_mu
	SetActiveSubwindow ##

	SetDataFolder root:
	return(0)
End

Function CellHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"Help for Cell Param Panel not written yet"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AddCellButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Polarization:Cells

			WAVE/T CellName
			WAVE lambda,Te,err_Te,mu,err_mu
			Variable ii= numpnts(CellName)
			
			InsertPoints  ii, 1, CellName,lambda,Te,err_Te,mu,err_mu
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SaveCellParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Save_HeCell_ParamWaves()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function RevertCellParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			InitPolarizationGlobals()
			Make_HeCell_ParamWaves()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// END PROCEDURES for He cell parameters
/////////////////////////////////






// Decay parameters for each cell. Results are stored in a wave note for each cell
//
//	muP=
//	err_muP=
// P0=
//	err_P0=		? is this needed?
//	T0=
// gamma=
//	err_gamma=
//
// str = "muP=2,err_muP=0,P0=0.6,err_P0=0,T0=asdf,gamma=200,err_gamma=0,"
//
//
// for this panel, the cell parameters are stored as kw strings
// all of the strings start w/ "gDecay_"
//
Macro ShowCellDecayPanel()
	
	// init folders
	// ASK before initializing cell constants
	// open the panel
	DoWindow/F DecayPanel
	if(V_flag == 0)
		InitPolarizationFolders()
		InitDecayGlobals()
		DecayParamPanel()
	endif
end

Function InitDecayGlobals()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	String/G gMuPo = "muPo"
	String/G gPo = "Po"
	String/G gGamma = "gamma"
	String/G gT0 = "today's the day"
	
	
	SetDataFolder root:
	return(0)
End




// makes the panel for the decay parameter and gamma fitting
//
Function DecayParamPanel()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(759,44,1572,713)/N=DecayPanel/K=1 as "Cell Decay Parameters"
	ModifyPanel cbRGB=(32768,54615,65535)
//	Button button_3,pos={505,16},size={35,20},proc=DecayHelpParButtonProc,title="?"
	PopupMenu popup_0,pos={32,18},size={49,20},title="Cell",proc=DecayPanelPopMenuProc
	PopupMenu popup_0,mode=1,value= #"D_CellNameList()"
	
	Button button_0,pos={584,365},size={70,20},proc=DecayFitButtonProc,title="Do Fit"
	
	GroupBox group_0,pos={550,399},size={230,149},title="FIT RESULTS",fSize=10
	GroupBox group_0,fStyle=1
	SetVariable setvar_0,pos={560,428},size={200,13},title="muPo of 3He"
	SetVariable setvar_0,fStyle=1,limits={0,0,0},barmisc={0,1000}
	SetVariable setvar_0,value= root:Packages:NIST:Polarization:Cells:gMuPo
	SetVariable setvar_1,pos={560,460},size={200,13},title="Po of 3He"
	SetVariable setvar_1,fStyle=1,limits={0,0,0},barmisc={0,1000}
	SetVariable setvar_1,value= root:Packages:NIST:Polarization:Cells:gPo
	SetVariable setvar_2,pos={560,518},size={200,13},title="Gamma (h)",fStyle=1
	SetVariable setvar_2,limits={0,0,0},barmisc={0,1000}
	SetVariable setvar_2,value= root:Packages:NIST:Polarization:Cells:gGamma
	SetVariable setvar_3,pos={560,488},size={200,15},title="T0",fStyle=1
	SetVariable setvar_3,limits={0,0,0},value= root:Packages:NIST:Polarization:Cells:gT0
	

	Button button_1,pos={579,294},size={120,20},proc=CalcRowParamButton,title="Calc Sel Row"
	Button button_2,pos={307,18},size={110,20},proc=ClearDecayWavesButton,title="Clear Table"
	Button button_3,pos={579,333},size={120,20},proc=ShowCalcRowButton,title="Show Calc"
	Button button_4,pos={440,18},size={110,20},proc=ClearDecayWavesRowButton,title="Clear Row"
	Button button_5,pos={620,18},size={40,20},proc=DecayHelpParButtonProc,title="?"
	Button button_6,pos={620,620},size={100,20},proc=WindowSnapshotButton,title="Snapshot"
	Button button_7,pos={620,580},size={130,20},proc=ManualEnterDecayButton,title="Manual Entry"



	// table
	Edit/W=(14,55,794,275)/HOST=# 
	ModifyTable format=1,width=0
	RenameWindow #,T0
	SetActiveSubwindow ##
	
	// graph
	Display/W=(15,291,540,652)/HOST=#  //root:yy vs root:xx
	ModifyGraph frameStyle=2
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=2

	Legend
//	ModifyGraph log(left)=1
//	ErrorBars yy OFF 
	RenameWindow #,G0
	SetActiveSubwindow ##

	SetDataFolder root:
	return(0)
End

// allows manual entry of Decay values
//
// see DecayFitButtonProc
//
Function ManualEnterDecayButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable selRow,err=0
	String fname, t0str, condStr,noteStr,t1Str,cellStr

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable gamma_val,err_gamma,muPo, err_muPo, Po, err_Po, runNum

			ControlInfo/W=DecayPanel popup_0
			cellStr = S_Value
				
//			SetDataFolder root:Packages:NIST:Polarization:Cells:
			
			WAVE decay=$("root:Packages:NIST:Polarization:Cells:Decay_"+cellStr)		//the one that is displayed
//			WAVE calc=$("root:Packages:NIST:Polarization:Cells:DecayCalc_"+cellStr)		//with the results


			Prompt Po, "Enter Po: "		
			Prompt err_Po, "Enter err_Po: "		
			Prompt muPo, "Enter muPo: "		
			Prompt err_muPo, "Enter err_muPo: "		
			Prompt gamma_val, "Enter gamma: "		
			Prompt err_gamma, "Enter err_gamma: "
			Prompt runNum,"Run number for time=0 of decay"	
			DoPrompt "Enter Cell Decay Parameters", Po, err_Po, muPo, err_muPo, gamma_val, err_gamma, runNum
			if (V_Flag)
				return -1								// User canceled
			endif
			
			fname = FindFileFromRunNumber(runNum)
			t0str = getFileCreationDate(fname)
					
//		for the wave note
			noteStr = note(decay)
			noteStr = ReplaceNumberByKey("muP", noteStr, MuPo ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("P0", noteStr, Po ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_muP", noteStr, err_muPo ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P0", noteStr, err_Po ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("gamma", noteStr, gamma_val ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_gamma", noteStr, err_gamma ,"=", ",", 0)
			noteStr = ReplaceStringByKey("T0", noteStr, t0Str  ,"=", ",", 0)
			// replace the string
			Note/K decay
			Note decay, noteStr

			// for the panel display
			SVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			SVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo		
			SVAR gT0 = root:Packages:NIST:Polarization:Cells:gT0
			
			gT0 = t0Str		//for display
			sprintf gMuPo, "%g +/- %g",muPo, err_muPo
			sprintf gPo, "%g +/- %g",Po,err_Po
			sprintf gGamma, "%g +/- %g",gamma_val,err_gamma

			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function DecayPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			// based on the selected string, display the right set of inputs
//			Print "now I need to display the right set of waves (2D text?) for ",popStr

			// for the given cell name, if the wave(s) exist, declare them
			if(exists("Decay_"+popStr) == 1)
				WAVE decay = $("Decay_"+popStr)
			else
				// if not, make it, and the space for the results of the calculation
				MakeDecayResultWaves(popStr)
				WAVE decay = $("root:Packages:NIST:Polarization:Cells:Decay_"+popStr)
			endif			
			// append matrix, clearing the old one first
			SetDataFolder root:Packages:NIST:Polarization:Cells

			KillWindow DecayPanel#T0
			Edit/W=(14,55,794,275)/HOST=DecayPanel
			RenameWindow #,T0
			AppendtoTable/W=DecayPanel#T0 decay.ld			//show the labels
			ModifyTable width(Point)=0
			ModifyTable width(decay.l)=20
			
			SetActiveSubwindow ##
	
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MakeDecayResultWaves(popStr)
	String popStr

	SetDataFolder root:Packages:NIST:Polarization:Cells

	Make/O/D/N=(1,8) $("Decay_"+popStr)
	WAVE decay = $("Decay_"+popStr)
	// set the column labels
	SetDimLabel 1,0,Trans_He_In,decay
	SetDimLabel 1,1,Trans_He_Out,decay
	SetDimLabel 1,2,Blocked,decay
	SetDimLabel 1,3,mu_star,decay
	SetDimLabel 1,4,Pol_Cell,decay
	SetDimLabel 1,5,T_Major,decay
	SetDimLabel 1,6,Include,decay			//for a mask wave, non-zero is used in the fit
	SetDimLabel 1,7,elapsed_hr,decay
	decay[0][6] = 1			//default to include the point
	
	// generate the dummy wave note now, change as needed
	Note decay, "muP=2,err_muP=0,P0=0.6,err_P0=0,T0=asdf,gamma=200,err_gamma=0,"
	
	// to hold the results of the calculation
	Make/O/D/N=(1,14) $("DecayCalc_"+popStr)
	WAVE decayCalc = $("DecayCalc_"+popStr)
	SetDimLabel 1,0,CR_Trans_He_In,decayCalc
	SetDimLabel 1,1,err_CR_Trans_He_In,decayCalc
	SetDimLabel 1,2,CR_Trans_He_Out,decayCalc
	SetDimLabel 1,3,err_CR_Trans_He_Out,decayCalc
	SetDimLabel 1,4,CR_Blocked,decayCalc
	SetDimLabel 1,5,err_CR_Blocked,decayCalc
	SetDimLabel 1,6,muPo,decayCalc
	SetDimLabel 1,7,err_muPo,decayCalc
	SetDimLabel 1,8,Po,decayCalc
	SetDimLabel 1,9,err_Po,decayCalc
	SetDimLabel 1,10,Tmaj,decayCalc
	SetDimLabel 1,11,err_Tmaj,decayCalc
	SetDimLabel 1,12,gamm,decayCalc
	SetDimLabel 1,13,err_gamm,decayCalc	

	SetDataFolder root:

	return(0)
End


// since the "Decay_" table can be edited directly to increase the number of rows, it is tough
// to increase the number of rows in the "DecayCalc_" wave and keep them in sync.
//
// --so make sure that the sizes match, and do them all
//
Function CalcRowParamButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable selRow,err=0
	String fname, t0str, cellStr,noteStr,t1Str

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable cr1,cr2,cr3,err_cr1,err_cr2,err_cr3
			Variable muPo,err_muPo,Po,err_Po,Pcell,err_Pcell,Tmaj,err_Tmaj
			//Variable Te,err_Te,mu,err_mu
				
			ControlInfo/W=DecayPanel popup_0
			cellStr = S_Value
			WAVE w=$("root:Packages:NIST:Polarization:Cells:Decay_"+cellStr)		//the one that is displayed
			WAVE calc=$("root:Packages:NIST:Polarization:Cells:DecayCalc_"+cellStr)		// behind the scenes
			
			Variable numRows,ncalc,diff
			numRows = DimSize(w,0)		//rows in the displayed table
			ncalc = DimSize(calc,0)
			
			// add rows to the DecayCalc_ matrix as needed
			if(numRows != ncalc)
				if(ncalc > numRows)
					DoAlert 0,"The DecayCalc_ is larger than displayed. Seek help."
					err = 1
					return(err)
				else
					diff = numRows - ncalc
					InsertPoints/M=0 ncalc, diff, calc
				endif
			endif
			
			
//			GetSelection table, DecayPanel#T0, 1
//			selRow = V_startRow

			Variable sum_muP, err_avg_muP, sum_Po, err_avg_Po, avg_muP, avg_Po
			sum_muP = 0
			sum_Po = 0
			err_avg_muP = 0
			err_avg_Po = 0
			
			for(selRow=0;selRow<numRows;selRow+=1)
				Print "calculate the row ",selRow

				if(selRow == 0)
					//find T0
					fname = FindFileFromRunNumber(w[0][%Trans_He_In])
					t0str = getFileCreationDate(fname)
					SVAR gT0 = root:Packages:NIST:Polarization:Cells:gT0
					gT0 = t0Str		//for display
					noteStr = note(w)
					noteStr = ReplaceStringByKey("T0", noteStr, gT0  ,"=", ",", 0)
					Note/K w
					Note w, noteStr
					Print t0str
					w[selRow][%elapsed_hr] = 0			//by definition
				endif
				
				// parse the rows, report errors (there, not here), exit if any found
				err = ParseDecayRow(w,selRow)
				if(err)
					return 0
				endif
				
				// do the calculations:
				// 1 for each file, return the count rate and err_CR (normalize to atten or not)
	
				Print "The Blocked CR is not rescaled to zero attenuators"
				cr1 = TotalCR_FromRun(w[selRow][%Trans_He_In],err_cr1,0)
				cr2 = TotalCR_FromRun(w[selRow][%Trans_He_Out],err_cr2,0)
				cr3 = TotalCR_FromRun(w[selRow][%Blocked],err_cr3,1)			//blocked beam is NOT normalized to zero attenuators
				
				calc[selRow][%CR_Trans_He_In] = cr1
				calc[selRow][%CR_Trans_He_Out] = cr2
				calc[selRow][%CR_Blocked] = cr3
				calc[selRow][%err_cr_Trans_He_In] = err_cr1
				calc[selRow][%err_cr_Trans_He_Out] = err_cr2
				calc[selRow][%err_cr_Blocked] = err_cr3
	
	
				// 2 find the mu and Te values for cellStr
				SVAR gCellKW = $("root:Packages:NIST:Polarization:Cells:gCell_"+cellStr)
				//(moved to a separate function, just pass the string)
	//			Te = NumberByKey("Te", gCellKW, "=", ",", 0)
	//			err_Te = NumberByKey("err_Te", gCellKW, "=", ",", 0)
	//			mu = NumberByKey("mu", gCellKW, "=", ",", 0)
	//			err_mu = NumberByKey("err_mu", gCellKW, "=", ",", 0)
	//			
				// 3 Calc muPo and error
				muPo = Calc_muPo(calc,gCellKW,selRow,err_muPo)
				calc[selRow][%muPo] = muPo
				calc[selRow][%err_muPo] = err_muPo
				w[selRow][%mu_star] = muPo
				
				// 3.5 calc Polarization of cell (no value or error stored in calc wave?)
				PCell = Calc_PCell(muPo,err_muPo,err_PCell)
	//			PCell = Calc_PCell(2,err_muPo,err_PCell)
				w[selRow][%Pol_Cell] = PCell
	
				// 4 calc Po and error
				Po = Calc_Po(gCellKW,muPo,err_muPo,err_Po)
	//			Po = Calc_Po(gCellKW,2,err_muPo,err_Po)
				calc[selRow][%Po] = Po
				calc[selRow][%err_Po] = err_Po
				
				// 5 calc Tmaj and error
				Tmaj = Calc_Tmaj(gCellKW,Po,err_Po,err_Tmaj)
				calc[selRow][%Tmaj] = Tmaj
				calc[selRow][%err_Tmaj] = err_Tmaj
				w[selRow][%T_major] = Tmaj
				
				// elapsed hours
				fname = FindFileFromRunNumber(w[selRow][%Trans_He_In])
				t1str = getFileCreationDate(fname)
				w[selRow][%elapsed_hr] = ElapsedHours(t0Str,t1Str)
				
				// running average of muP and Po
				sum_muP += muPo
				sum_Po += Po
				err_avg_muP += err_muPo^2
				err_avg_Po += err_Po^2
				
			endfor		//loop over rows
			
			// now get a running average of muP, Po, and the errors
			avg_muP = sum_muP/numRows
			avg_Po = sum_Po/numRows
			err_avg_muP = sqrt(err_avg_muP) / numRows
			err_avg_Po = sqrt(err_avg_Po) / numRows
			
//			str = "muP=2,err_muP=0,P0=0.6,err_P0=0,T0=asdf,gamma=200,err_gamma=0,"

			// Don't put the average values into the wave note, but rather the results of the fit
//			noteStr = note(w)
//			noteStr = ReplaceNumberByKey("muP", noteStr, avg_muP ,"=", ",", 0)
//			noteStr = ReplaceNumberByKey("P0", noteStr, avg_Po ,"=", ",", 0)
//			noteStr = ReplaceNumberByKey("err_muP", noteStr, err_avg_muP ,"=", ",", 0)
//			noteStr = ReplaceNumberByKey("err_P0", noteStr, err_avg_Po ,"=", ",", 0)
//			
//			// replace the string
//			Note/K w
//			Note w, noteStr
					
			Printf "Average muP = %g +/- %g (%g%)\r",avg_muP,err_avg_muP,err_avg_muP/avg_muP*100
			Printf "Average Po = %g +/- %g (%g%)\r",avg_Po,err_avg_Po,err_avg_Po/avg_Po*100
			
			//update the global values for display (not these, but after the fit)
//			Print " -- need to add the error to the display on the panel	"
//			NVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
//			NVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
//			gMuPo = avg_muP
//			gPo = avg_Po
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// calculate Tmaj and its error
Function Calc_Tmaj(cellStr,Po,err_Po,err_Tmaj)
	String cellStr
	Variable Po,err_Po,&err_Tmaj
	
	Variable Tmaj,arg
	Variable Te,err_Te,mu,err_mu
// cell constants	
	Te = NumberByKey("Te", cellStr, "=", ",", 0)
	err_Te = NumberByKey("err_Te", cellStr, "=", ",", 0)
	mu = NumberByKey("mu", cellStr, "=", ",", 0)
	err_mu = NumberByKey("err_mu", cellStr, "=", ",", 0)
	
	Tmaj = Te*exp(-mu*(1-Po))
	
	//the error
	err_Tmaj = (Tmaj/Te)^2*err_Te^2 + (Tmaj*(1-Po))^2*err_mu^2 + (Tmaj*mu)^2*err_Po^2
	err_Tmaj = sqrt(err_Tmaj)
	
	Printf "Tmaj = %g +/- %g (%g%)\r",Tmaj,err_Tmaj,err_Tmaj/Tmaj*100

	
	return(Tmaj)
End


// calculate PCell and its error
//
// 
Function Calc_PCell(muPo,err_muPo,err_PCell)
	Variable muPo,err_muPo,&err_PCell
	
	Variable PCell,arg

	PCell = tanh(muPo)
	
	// error (single term, sqrt already done)
	err_Pcell = (1 - (tanh(muPo))^2) * err_muPo
	
	Printf "Pcell = %g +/- %g (%g%)\r",Pcell,err_Pcell,err_Pcell/PCell*100

	return(PCell)
End

// calculate Po and its error
Function Calc_Po(cellStr,muPo,err_muPo,err_Po)
	String cellStr
	Variable muPo,err_muPo,&err_Po
	
	Variable Po,tmp
	Variable mu,err_mu
// cell constants	
	mu = NumberByKey("mu", cellStr, "=", ",", 0)
	err_mu = NumberByKey("err_mu", cellStr, "=", ",", 0)
	
	Po = muPo/mu
	
	tmp = (err_muPo/muPo)^2 + (err_mu/mu)^2
	err_Po = Po * sqrt(tmp)
	
	Printf "Po = %g +/- %g (%g%)\r",Po,err_Po,err_Po/Po*100
	return(Po)
End

// calculate muPo and its error
Function Calc_muPo(calc,cellStr,selRow,err_muPo)
	Wave calc
	String cellStr
	Variable selRow,&err_muPo
	
	Variable muPo,arg
	Variable Te,err_Te,mu,err_mu
// cell constants	
	Te = NumberByKey("Te", cellStr, "=", ",", 0)
	err_Te = NumberByKey("err_Te", cellStr, "=", ",", 0)
	mu = NumberByKey("mu", cellStr, "=", ",", 0)
	err_mu = NumberByKey("err_mu", cellStr, "=", ",", 0)
	
	Variable cr1,cr2,cr3,err_cr1,err_cr2,err_cr3
	// cr1 is He in, 2 is He out, 3 is blocked
	cr1	 =	calc[selRow][%CR_Trans_He_In]
	cr2 =	calc[selRow][%CR_Trans_He_Out]
	cr3 =	calc[selRow][%CR_Blocked]
	err_cr1 =	calc[selRow][%err_cr_Trans_He_In]
	err_cr2 =	calc[selRow][%err_cr_Trans_He_Out]
	err_cr3 =	calc[selRow][%err_cr_Blocked]
	
	muPo = acosh( (cr1 - cr3)/(cr2 - cr3) * (1/(Te*exp(-mu))) )
	
	Variable arg_err, tmp1, tmp2
	// the error is a big mess to calculate, since it's messy argument inside acosh
	arg = (cr1 - cr3)/(cr2 - cr3) * (1/(Te*exp(-mu)))
	tmp2 =  (1/sqrt(arg+1)/sqrt(arg-1))^2					// derivative of acosh(arg) (squared)
	
	// calculate the error of the argument first, then the error of acosh(arg)
	// there are 5 partial derivatives
	arg_err = tmp2 * ( arg/(cr1 - cr3) * err_cr1 )^2		//CR in
	arg_err += tmp2 * ( arg/(cr2 - cr3) * err_cr2 )^2	//CR out
	arg_err += tmp2 * ((-arg/(cr1 - cr3) +  arg/(cr2 - cr3) )* err_cr3 )^2//CR bkg 
	arg_err += tmp2 * ( -arg/Te * err_Te )^2					//Te
	arg_err += tmp2 * ( arg * err_mu )^2						//mu  (probably the dominant relative error)
	
	err_muPo = sqrt(arg_err)
	
	
	return(muPo)
End


//Function testCR(num)
//	Variable num
//	Variable err_cr
//	
//	Variable noNorm=0
//	Variable cr = TotalCR_FromRun(num,err_cr,noNorm)
//	printf "CR = %g +/- %g (%g%)\r",cr,err_cr,err_cr/cr*100	
//	return(0)
//End

// calculate the total detector CR ane its error.
//
// the result is automatically normalized to 10^8 monitor counts, and to zero attenuators
//
// if noNorm = 1, then the normalization to attenuators is not done
//
Function TotalCR_FromRun(num,err_cr,noNorm)
	Variable num,&err_cr,noNorm

	String fname="",instr="",tmpStr=""
	Variable cr,cts,err_cts,ctTime,monCts,attenNo,lambda,attenTrans,atten_err
	
	fname = FindFileFromRunNumber(num)
	cts = getDetCount(fname)
	err_cts = sqrt(cts)
	
	ctTime = getCountTime(fname)
	monCts = getMonitorCount(fname)
	attenNo = getAttenNumber(fname)
	instr = getAcctName(fname)		//this is 11 characters
	lambda = getWavelength(fname)
	attenTrans = AttenuationFactor(instr,lambda,AttenNo,atten_err)
	
	if(noNorm==1)			//don't normalize to attenuation
		attenTrans=1
		atten_err=0
	endif
	cr = cts/ctTime*1e8/monCts/attenTrans
	err_cr = cr * sqrt(err_cts^2/cts^2 + atten_err^2/attenTrans^2)
	
	printf "CR = %g +/- %g (%g%)\r",cr,err_cr,err_cr/cr*100	

		
	return(cr)
end


// input is VAX date and time string, t1 later than t0
//
Function ElapsedHours(t0Str,t1Str)
	String t0Str,t1Str
	
	Variable t0,t1,elapsed
	
	t0 = ConvertVAXDateTime2Secs(t0Str)		//seconds
	t1 = ConvertVAXDateTime2Secs(t1Str)
	
	elapsed = t1-t0
	elapsed /= 3600			//convert to hours
	
	return(elapsed)
End

// bring up a table with the calculation results
Function ShowCalcRowButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo/W=DecayPanel popup_0
			String cellStr = S_Value
			WAVE calc=$("root:Packages:NIST:Polarization:Cells:DecayCalc_"+cellStr)		//the one that is displayed
			edit calc.ld
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function DecayFitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String cellStr=""
	Variable num

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			ControlInfo/W=DecayPanel popup_0
			cellStr = S_Value
			
			SetDataFolder root:Packages:NIST:Polarization:Cells:
			
			WAVE decay=$("Decay_"+cellStr)		//the one that is displayed
			WAVE calc=$("DecayCalc_"+cellStr)		//the one that is displayed
			
//			make temp copies for the fit and plot, extra for mask
			num = DimSize(calc,0)
			Make/O/D/N=(num)		tmp_Mask,tmp_hr,tmp_muP,tmp_err_muP,tmp_muP2
			
			tmp_Mask = decay[p][%Include]
			tmp_hr = decay[p][%elapsed_hr]
			tmp_muP = calc[p][%muPo]
			tmp_muP2 = tmp_muP
			tmp_err_muP = calc[p][%err_muPo]
			
			tmp_muP2 = (tmp_Mask == 1) ? NaN : tmp_muP2			//only excluded points will plot
			
			// clear old data, and plot the new
			//
			CheckDisplayed/W=DecayPanel#G0 tmp_muP,tmp_muP2,fit_tmp_muP
			// if both present, bit 0 + bit 1 = 3
			if(V_flag & 2^0)			//check bit 0
				RemoveFromGraph/W=DecayPanel#G0 tmp_muP
			endif
			if(V_flag & 2^1)
				RemoveFromGraph/W=DecayPanel#G0 tmp_muP2
			endif
			if(V_flag & 2^2)
				RemoveFromGraph/W=DecayPanel#G0 fit_tmp_muP
			endif
			
			AppendToGraph/W=DecayPanel#G0 tmp_muP vs tmp_hr
			AppendToGraph/W=DecayPanel#G0 tmp_muP2 vs tmp_hr

			ModifyGraph/W=DecayPanel#G0 log(left)=1
			ModifyGraph/W=DecayPanel#G0 frameStyle=2
			ModifyGraph/W=DecayPanel#G0 mode=3
			ModifyGraph/W=DecayPanel#G0 marker=19
			ModifyGraph/W=DecayPanel#G0 rgb(tmp_muP)=(1,16019,65535),rgb(tmp_muP2)=(65535,0,0)
			ModifyGraph/W=DecayPanel#G0 msize=3
			ErrorBars/W=DecayPanel#G0 tmp_muP,Y wave=(tmp_err_muP,tmp_err_muP)
			
			Label/W=DecayPanel#G0 left "mu*P"
			Label/W=DecayPanel#G0 bottom "time (h)"
			
// do the fit
//	 as long as the constant X0 doesn't stray from zero, exp_XOffset is OK, otherwise I'll need to switch to the exp function

			SetActiveSubwindow DecayPanel#G0			//to get the automatic fit to show up on the graph

//			Make/O/D/N=3 fitCoef={0,5,0.05}
//			CurveFit/H="100"/M=2/W=0/TBOX=(0x310) exp_XOffset, kwCWave=fitCoef, tmp_muP /X=tmp_hr /D /I=1 /W=tmp_err_muP /M=tmp_Mask


			Make/O/D/N=3 fitCoef={0,5,0.05}
			CurveFit/H="100"/M=2/W=0/TBOX=(0x310) exp, kwCWave=fitCoef, tmp_muP /X=tmp_hr /D /I=1 /W=tmp_err_muP /M=tmp_Mask
			

			SetActiveSubwindow ##
			
			
// then report and save the results
//			the exp function => y = y0 + A*exp(-Bx)
//			W_coef[0] = y0 should be close to zero (or fixed at zero)
//			W_coef[1] = A should be close to the initial muP value
//			W_coef[2] = B is 1/Gamma
//			WAVE W_coef=W_coef
			WAVE W_sigma=W_sigma
			Variable gamma_val,err_gamma,muPo, err_muPo, Po, err_Po
			String noteStr=""
	
			SVAR gCellKW = $("root:Packages:NIST:Polarization:Cells:gCell_"+cellStr)	
			SVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			SVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
			
			muPo = fitCoef[1]
			err_muPo = W_sigma[1]
			
			Po = Calc_Po(gCellKW,muPo,err_muPo,err_Po)

			// if exp_XOffset used
//			gGamma = fitCoef[2]
//			err_Gamma = W_sigma[2]

			// calculating the error using exp is the inverse of coef[2]:
			gamma_val  = 1/fitCoef[2]
			err_gamma = W_sigma[2]/(fitCoef[2])^2
		
			
//		for the wave note
			noteStr = note(decay)
			noteStr = ReplaceNumberByKey("muP", noteStr, MuPo ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("P0", noteStr, Po ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_muP", noteStr, err_muPo ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P0", noteStr, err_Po ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("gamma", noteStr, gamma_val ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_gamma", noteStr, err_gamma ,"=", ",", 0)

			// replace the string
			Note/K decay
			Note decay, noteStr
			
			
			// for the panel display
			sprintf gMuPo, "%g +/- %g",fitCoef[1],W_sigma[1]
			sprintf gPo, "%g +/- %g",Po,err_Po
			sprintf gGamma, "%g +/- %g",gamma_val,err_gamma

			
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// clear just the row
//
Function ClearDecayWavesRowButton(ba) : ButtonControl
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
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			ControlInfo/W=DecayPanel popup_0
			popStr = S_Value
			
			Wave decay = $("Decay_"+popStr)
			Wave calc = $("DecayCalc_"+popStr)

			// Delete just those points
						
			GetSelection table, DecayPanel#T0, 1
			selRow = V_startRow
			DeletePoints selRow,1,decay,calc			
			
			// clear the graph and the results			
			SVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			SVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
			SVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gT0  = root:Packages:NIST:Polarization:Cells:gT0
			gMuPo = "0"
			gPo = "0"
			gGamma = "0"
			gT0 = "recalculate"
			
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
Function ClearDecayWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String popStr=""
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 1,"Clear all of the decay waves for the selected cell?"
			if(V_flag !=1)
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			ControlInfo/W=DecayPanel popup_0
			popStr = S_Value
			
			Wave decay = $("Decay_"+popStr)
			Wave calc = $("DecayCalc_"+popStr)
			
//			re-initialize the decay waves, so it appears as a blank, initialized table

			MakeDecayResultWaves(popStr)
			decay = 0
			calc = 0
	
			// clear the graph and the results?	
			
			
					
			SVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			SVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
			SVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gT0  = root:Packages:NIST:Polarization:Cells:gT0
			gMuPo = "0"
			gPo = "0"
			gGamma = "0"
			gT0 = "recalculate"
			
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function DecayHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"Help for Cell Decay Panel not written yet"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// E=-5 is a PNG, =8 is PDF
// there are other options to do EPS, embed fonts, etc.
//
Function WindowSnapshotButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SavePICT /E=-5/SNAP=1
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
Function/S D_CellNameList()

	String retStr="",listStr,item
	Variable num,ii
	
	SetDataFolder root:Packages:NIST:Polarization:Cells

	// get a list of the cell strings
	listStr=StringList("gCell_*",";")
	num=ItemsInList(listStr,";")
//	print listStr
	
	// parse the strings to fill the table
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, listStr,";")
		SVAR gStr = $item
		retStr += StringByKey("cell", gStr, "=", ",", 0) + ";"
	endfor
	
	if(strlen(retStr) == 0)
		retStr = "no cells defined;"
	endif
	
	SetDataFolder root:		
	return(retStr)
End


// parse the row to be sure that:
//
// - files are valid numbers
// - files are all at same SDD
// - files are all with same attenuation (just print a warning to cmd)
//
Function ParseDecayRow(w,selRow)
	Wave w
	Variable selRow
	
	Variable err=0, atten1,atten2,atten3,sdd1,sdd2,sdd3
	String fname=""
	// are all file numbers valid?
	fname = FindFileFromRunNumber(w[selRow][%Trans_He_In])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"Trans_He_In run "+num2str(w[selRow][%Trans_He_In])+" is not a valid run number"
		err = 1
	else
		atten1 = getAttenNumber(fname)
		sdd1 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%Trans_He_Out])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"Trans_He_Out run "+num2str(w[selRow][%Trans_He_Out])+" is not a valid run number"
		err = 1
	else
		atten2 = getAttenNumber(fname)
		sdd2 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%Blocked])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"Blocked run "+num2str(w[selRow][%Blocked])+" is not a valid run number"
		err = 1
	else
		atten3 = getAttenNumber(fname)
		sdd3 = getSDD(fname)
	endif
	
	if( (sdd1 != sdd2) || (sdd2 != sdd3) || (sdd1 != sdd3) )
		DoAlert 0,"Files in row "+num2str(selRow)+" are not all at the same detector distance"
		err = 1
	endif
	
	if( (atten1 != atten2) || (atten2 != atten3) || (atten1 != atten3) )
		DoAlert 0,"Files in row "+num2str(selRow)+" are not all collected with the same attenuation. Just so you know."
		err = 0
	endif
	
	return(err)
end


////////////////////////////////////////////