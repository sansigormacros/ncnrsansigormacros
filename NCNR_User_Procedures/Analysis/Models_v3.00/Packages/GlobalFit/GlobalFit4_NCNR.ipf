#pragma rtGlobals=2		// Use modern global access method.
#pragma version = 2.16
#pragma IgorVersion = 4.00

//
//	SRK NOV 2004
// These procedures have been changed to allow fitting of USANS and SANS
// data simultaneously with a smeared model. Special allowances have been made 
// so that the smearing routines (in GaussUtils) can find the proper
// resolution information
//
// This is based on the Igor 4 version of <Global Fit> and does not incorporate the
// module concept of Igor 5, or the added features of <Global Fit 2> , also with Igor 5
//
//

//**************************************
// Changes in Global Fit procedures
// 
//	1.01: 	Added ability to hold parameters and calculate residuals Jan 31, 1997
//	2.00: 	Complete re-design of the control panel to use ListBox controls
//			Use FUNCREF variable to pass the user's fitting function
//	2.01:	Changed GlobalFitFunc template function to indicate that the wrong function was called.
//			Removed /D's from GlobalFitFunc that made it look like it was different from user's function,
//				causing the FUNCREF to use the template instead.
//			Added menus to copy initial guesses to/from waves
//			Allow resize of control panel to change size of list boxes
//			Added divider between list boxes to allow changing relative sizes of the lists
// 			Added memory of window size and position
// 2.10:	Added support for constraints
//			Added support for weighting
//			Moved the Global Fit menu item to the Analysis menu
//			New Wave... item in the Copy List To Wave menu
//			The fit coefficient wave is now copied to the current data folder, into GlobalFitCoefficients
// 2.11:	Added support for all-at-once fit functions
//			Added covariance matrix option
// 2.12:	Fixed a bug: if you have two traces with waves having the same names, the wrong X wave is selected when
//				the All From Target button was clicked.
// 2.13:	Added support for data masking.
// 2.14:	Added creation of coefficient waves for each data set.
//     	Fixed a liberal-name bug in the Add Wave menu handling.
// 2.15:	Added support for epsilon.
//			Made a GlobalParams and LocalParams waves double precision.
// 2.16:	Added "Require FitFunc keyword checkbox. Moved creation of fit_ waves to a point inside the DoTheFit
//			function for increased reliability. Add control to set the number of points in the fit_ waves.
//**************************************

//**************************************
// Things to add in the future:
//	1) Somehow support graph cursors to restrict fit range.
//
//	2) Allow moving the list column dividers. That's really Larry's job...
// 
// 		Anything else? tell support@wavemetrics.com about it!
//**************************************

Menu "Macros"
//	"Global Fit", InitGlobalFitPanel()
	Submenu "Packages"
		"Unload Global Fit", UnloadGlobalFit()
	End
end

// This is the prototype function for the user's fit function
// If you create your fitting function using the New Fit Function button in the Curve Fitting dialog,
// it will have the FitFunc keyword, and that will make it show up in the menu in the Global Fit control panel.
Function GlobalFitFunc(w, xx)
	Wave w
	Variable xx
	
	DoAlert 0, "Global Fit is running the template fitting function for some reason."
	return nan
end

Function GlobalFitAllAtOnce(pw, yw, xw)
	Wave pw, yw, xw
	
	DoAlert 0, "Global Fit is running the template fitting function for some reason."
	yw = nan
	return nan
end

Function GlblFitFunc(w, pp)
	Wave w
	Variable pp
	
	Wave Xw = root:Packages:GlobalFit:XCumData
	Wave IndexW = root:Packages:GlobalFit:Index
	Wave SC=root:Packages:GlobalFit:ScratchCoefs
	Wave IndexP = root:Packages:GlobalFit:IndexPointer

	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	NVAR DoFitFunc=root:Packages:GlobalFit:DoFitFunc
	
	SVAR UserFitFunc=root:Packages:GlobalFit:UserFitFunc
	FUNCREF GlobalFitFunc theFitFunc = $UserFitFunc
	
	Variable IndexPvar, i
	
	if (DoFitFunc)
		IndexPvar = DoFitFunc-1
	else
		IndexPvar = IndexP[pp]
	endif
	
	SC = w[IndexW[IndexPvar][p+1]]
	
	if (DoFitFunc)
		return theFitFunc(SC, pp)
	else
		return theFitFunc(SC, Xw[pp])
	endif
end

Function GlblFitFuncAllAtOnce(inpw, inyw, inxw)
	Wave inpw, inyw, inxw
	
	Wave Xw = root:Packages:GlobalFit:XCumData
	Wave IndexW = root:Packages:GlobalFit:Index
	Wave SC=root:Packages:GlobalFit:ScratchCoefs
	Wave IndexP = root:Packages:GlobalFit:IndexPointer

	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	NVAR DoFitFunc=root:Packages:GlobalFit:DoFitFunc
	NVAR NumSets=root:Packages:GlobalFit:NumSets
	
	SVAR UserFitFunc=root:Packages:GlobalFit:UserFitFunc
	FUNCREF GlobalFitAllAtOnce theFitFunc = $UserFitFunc
	
	Variable IndexPvar, i, firstP, lastP
	
	if (DoFitFunc)
		Variable whichSet = DoFitFunc-1
		SC = inpw[IndexW[whichSet][p+1]]
		theFitFunc(SC, inyw, inxw)
	else
		for (i = 0; i < NumSets-1; i += 1)
			firstP = IndexW[i][0]
			lastP = IndexW[i+1][0] - 1
			Duplicate/O/R=[firstP,lastP] Xw, TempXW, TempYW
			TempXW = Xw[p+firstP]
			SC = inpw[IndexW[i][p+1]]
			theFitFunc(SC, TempYW, TempXW)
			inyw[firstP, lastP] = TempYW[p-firstP]
		endfor
		i = NumSets-1
		firstP = IndexW[i][0]
		lastP = numpnts(inyw)-1
		Duplicate/O/R=[firstP,lastP] Xw, TempXW, TempYW
		TempXW = Xw[p+firstP]
		SC = inpw[IndexW[i][p+1]]
		theFitFunc(SC, TempYW, TempXW)
		inyw[firstP, lastP] = TempYW[p-firstP]
	endif
end

//---------------------------------------------
//  All the setup stuff
//---------------------------------------------	

Function DoTheFit(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR NumSets = root:Packages:GlobalFit:NumSets
	if (NumSets <= 0)
		DoAlert 0, "No Data Sets Selected"
		return -1
	endif
	
	NVAR DoFitFunc=root:Packages:GlobalFit:DoFitFunc
	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	
	SVAR TopGraph=root:Packages:GlobalFit:TopGraph
	SVAR UserFitFunc=root:Packages:GlobalFit:UserFitFunc
	Variable/G root:Packages:GlobalFit:isAllAtOnceFunc			// 0 for normal, 1 for all-at-once
	NVAR isAllAtOnceFunc = root:Packages:GlobalFit:isAllAtOnceFunc
	string FitFuncs = FunctionList("*", ";", "NPARAMS:2;VALTYPE:1")
	if (FindListItem(UserFitFunc, FitFuncs) >= 0)
		isAllAtOnceFunc = 0
	else
		FitFuncs = FunctionList("*", ";", "NPARAMS:3;VALTYPE:1")
		if (FindListItem(UserFitFunc, FitFuncs) >= 0)
			isAllAtOnceFunc = 1
		else
			DoAlert 0, "The fitting function "+UserFitFunc+" does not conform to the format required."
			return -1
		endif
	endif
	
	Make/O/D/N=(NBParams) root:Packages:GlobalFit:ScratchCoefs
	
	Wave AllCoefs = root:Packages:GlobalFit:AllCoefs	
	Wave Xw = root:Packages:GlobalFit:XCumData
	Wave Yw = root:Packages:GlobalFit:YCumData
	Wave IndexW = root:Packages:GlobalFit:Index
	Wave/U/B  GuessListSelection=root:Packages:GlobalFit:GuessListSelection
	Wave/T GuessListWave = root:Packages:GlobalFit:GuessListWave
	WAVE/T DataSetList=root:Packages:GlobalFit:DataSetList

	Variable i,j
	Variable DoResid=0
	Variable doConstraints=0
	Variable doWeighting=0
	Variable doMasking=0
	
	String ResidString=""
	String CovarianceString = ""
	String Command=""
	
	String YFitSet
	String YWaveName=""
	String saveDF
	
	Variable nCoefs = DimSize(AllCoefs, 0)
	for (i = 0; i < nCoefs; i += 1)
		AllCoefs[i] = str2num(GuessListWave[i][%'Initial Guess'])
		if (numtype(AllCoefs[i]) != 0)					// INF or NaN
			GuessListSelection = ~1 & GuessListSelection
			GuessListSelection[i][%'Initial Guess'] = 3				// editable and selected
			DoUpdate
			DoAlert 0,  "One of your initial guess values is not a number."
			return -1
		endif
	endfor
	
	TopGraph = WinName(0,1)
	
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	Display Yw vs Xw
	DoWindow/C GlobalFitGraph
	ModifyGraph Mode(YCumData)=3,Marker(YCumData)=8
	Duplicate/D/O Yw, root:Packages:GlobalFit:FitY
	Wave FitY = root:Packages:GlobalFit:FitY
	FitY = NaN
	AppendToGraph FitY vs Xw
	ModifyGraph Mode(FitY)=3,Marker(FitY)=0
	
	Duplicate/D/O AllCoefs, root:Packages:GlobalFit:EpsilonWave
	Wave EP = root:Packages:GlobalFit:EpsilonWave
	EP = str2num(GuessListWave[p][%Epsilon])
	for (i = 0; i < nCoefs; i += 1)
		if (numtype(EP[i]) != 0)					// INF or NaN
			GuessListSelection = ~1 & GuessListSelection
			GuessListSelection[i][%Epsilon] = 3				// editable and selected
			DoUpdate
			DoAlert 0, "One of your Epsilon guess values is not a number."
			return -1
		endif
		if (EP[i] <= 0)					// INF or NaN
			GuessListSelection = ~1 & GuessListSelection
			GuessListSelection[i][%Epsilon] = 3				// editable and selected
			DoUpdate
			DoAlert 0, "Epsilon values should be positive and non-zero."
			return -1
		endif
	endfor
	
	//// SRK 2004 Resolution Waves
	//		NumSets = number of data sets
	//		DataSetList (/T (n,2)) are the names of the n sets y=[][0], x=[][1]
	//
	Variable ii
	String str,wl1="",wl2="",wl3="",wl4=""
	//names of the concatenated resolution waves
	String sqwStr = "GF_SigQ",	qbwStr = "GF_QBar",	shwStr = "GF_Shadow",	gQwStr = "GF_Qvals"
	
	for(ii=0;ii<NumSets;ii+=1)
		str=DataSetList[ii][0]
		str=str[0,strlen(str)-3]		//strip the "_i" from the end
		wl1 += str + "sq" + ";"
		wl2 += str + "qb" + ";"
		wl3 += str + "fs" + ";"
		wl4 += str + "_q" + ";"			// construct the lists of waves
	endfor
	
	//concatenate each into a temporary wave
	// waves will be created in the root folder by this function!!
	ConcatenateResolWavesInList(sqwStr, wl1)
	ConcatenateResolWavesInList(qbwStr, wl2)
	ConcatenateResolWavesInList(shwStr, wl3)
	ConcatenateResolWavesInList(gQwStr, wl4)
	// sort them
	Sort $gQwStr, $gQwStr,$sqwStr,$qbwStr,$shwStr
	
	// remove the duplicate points so that interp() will work properly in GaussUtils
	RemoveDuplicatePts($gQwStr,$sqwStr,$qbwStr,$shwStr)
	
	// rename SVAR (x4) corresponding to the temp waves
	String/G root:gSig_Q = sqwStr
	String/G root:gQ_bar = qbwStr
	String/G root:gShadow = shwStr
	String/G root:gQVals = gQwStr
	
	Print "Resolution waves have been reset"
	////  e SRK Resolution Waves construction
	
	
	//  Constraints
	ControlInfo/W=GlobalFitPanel ConstraintsCheckBox
	if (V_value)
		doConstraints = 1
		GlobalFitMakeConstraintWave()
		Wave GlobalFitConstraintWave = root:Packages:GlobalFit:GlobalFitConstraintWave
		if (numpnts(GlobalFitConstraintWave) == 0)
			doConstraints = 0
		endif
	endif
	
	//  Weighting
	ControlInfo/W=GlobalFitPanel WeightingCheckBox
	if (V_value)
		doWeighting = (GlobalFitMakeWeightWave() > 0)
		if (!doWeighting)
			DoAlert 1, "There is a problem with weighting. Procede with the fit anyway?"
			if (V_flag != 1)
				return -1
			endif
		endif
	endif
	
	//  Masking
	ControlInfo/W=GlobalFitPanel MaskingCheckBox
	if (V_value)
		doMasking = (GlobalFitMakeMaskWave() > 0)
		if (!doMasking)
			DoAlert 1, "There is a problem with Masking. Procede with the fit anyway?"
			if (V_flag != 1)
				return -1
			endif
		endif
	endif
	
	Print "*** Doing Global fit ***"
	
	DoFitFunc = 0						// Makes GlblFitFunc do a global fit
	
	ControlInfo/W=GlobalFitPanel DoResidualCheck
	if (V_value)
		DoResid = 1
		ResidString="/R"
	endif
	
	ControlInfo/W=GlobalFitPanel DoCovarMatrix
	if (V_value)
		CovarianceString="/M=2"
	endif
	
	string funcName
	if (isAllAtOnceFunc)
		funcName = " GlblFitFuncAllAtOnce"
	else
		funcName = " GlblFitFunc"
	endif
	
	Command =  "FuncFit"+CovarianceString+" "
	Command += MakeHoldString()+funcName+", "		// MakeHoldString() returns "" if there are no holds
	Command += "root:Packages:GlobalFit:AllCoefs, "
	Command += "root:Packages:GlobalFit:YCumData "
	Command += "/D=root:Packages:GlobalFit:FitY "
	Command += "/E=root:Packages:GlobalFit:EpsilonWave"+ResidString
	if (doConstraints)
		Command += "/C=root:Packages:GlobalFit:GlobalFitConstraintWave"
	endif
	if (doWeighting)
		Command += "/W=root:Packages:GlobalFit:GFWeightWave"
	endif
	if (doMasking)
		Command += "/M=root:Packages:GlobalFit:GFMaskWave"
	endif
//	Print Command
	Execute Command

	GuessListWave[][%'Initial Guess'] = num2str(AllCoefs[p])
	Duplicate/O AllCoefs, GlobalFitCoefficients
	
	Print "\rGlobal fit to function "+	UserFitFunc+"\r"

	//The appended result waves "Fit_" created in MakeFitCurveWaves() are 
	// overwritten later in this funciton to force calculation at the 
	// experimental q-values (search 10JAN05)
	MakeFitCurveWaves()

	i = 0
	do
		YFitSet = DataSetList[i][0]
		
		// copy coefficients for each data set into a separate wave
		Wave YFit = $YFitSet
		saveDF = GetDatafolder(1)
		SetDatafolder $GetWavesDatafolder(YFit, 1)
		YWaveName = NameOfWave(YFit)
		if (CmpStr(YWaveName[0], "'") == 0)
			YWaveName = YWaveName[1, strlen(YWaveName)-2]
		endif
		String coefname = CleanupName("Coef_"+YWaveName, 0)
		Make/D/O/N=(NBParams) $coefname
		Wave w = $coefname
		w = AllCoefs[IndexW[i][p+1]]
		SetDataFolder $saveDF
		
		// and print the coefficients by data set into the history
		Print "Coefficients for data set", YFitSet
		printf "{"
		j = 0
		do
			printf "%g", AllCoefs[IndexW[i][j+1]]
			
				if (GuessListSelection[IndexW[i][j+1]][%'Hold?'] & 16)
					printf "(held)"
				endif
			j += 1
			if (j >= NBParams)
				break
			endif
			printf ", "
		while (1)
		printf "}\r"
		i += 1
	while (i < NumSets)
	
	//SRK 10JAN05 - for smeared fits, especially combined SANS/USANS, result must be calculated
	// at ONLY the experimental q-values where the resolution is known - otherwise
	// the interpolated values in the overlap region are wrong, and the display
	// is NOT representative of the fit (which is done correctly)
	String XFitSet="",MaskSet=""
	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	
	ControlInfo/W=GlobalFitPanel AppendResultsCheck
	if (V_value)
		DoWindow/F $TopGraph
		Wave w = AllCoefs
		i = 0
		do
			YFitSet = DataSetList[i][0]		//loop through each data set
			Wave YFit = $YFitSet
			XFitSet = DataSetList[i][1]			//SRK
			Wave XFit_NotMasked = $XFitSet					//SRK
			saveDF = GetDatafolder(1)
			SetDatafolder $GetWavesDatafolder(YFit, 1)
			YWaveName = NameOfWave(YFit)
			if (CmpStr(YWaveName[0], "'") == 0)
				YWaveName = YWaveName[1, strlen(YWaveName)-2]
			endif
			YFitSet = "Fit_"+YWaveName
			Wave YFit = $YFitSet
			DoFitFunc = i+1			// Makes GlblFitFunc select a certain set of parameters, and pass X directly to the fitting function
			if (isAllAtOnceFunc)
				Duplicate/O YFit, dummyX
				dummyX = x
				GlblFitFuncAllAtOnce(w, YFit, dummyX)
			else
				//SRK
				// make an Xwave that is the non-masked q-values
				XFitSet = "FitX_"+NameOfWave(XFit_NotMasked)
				Duplicate/O XFit_NotMasked,$XFitSet
				Wave XFit = $XFitSet
				if(WaveExists(MaskingListWave))
					MaskSet = MaskingListWave[i][1]
					Wave/Z XMask = $MaskSet
					if(!WaveExists(XMask))
						Duplicate/O XFit_NotMasked,XMask
						XMask = 1		//no masking wave was chosen, make one here
					endif
				else
					Duplicate/O XFit_NotMasked,XMask
					XMask = 1		//no masking wave was chosen, make one here
				endif
				RemoveMaskedXPoints(XFit_NotMasked,XFit,XMask)
				Duplicate/O XFit,YFit		//Yfit is now the same length as XFit
				YFit = GlblFitFunc(w, XFit)		//calculate at measured X-values, for this set only
				//eSRK
				//YFit = GlblFitFunc(w, x)
			endif
			CheckDisplayed YFit
			if (!V_flag)
				AppendToGraph YFit vs XFit		//ALWAYS XY pairs!!
				//AppendToGraph YFit
			endif
			SetDatafolder $saveDF
		
			if (DoResid)
				Wave Yw=$(DataSetList[i][0])
				saveDF = GetDatafolder(1)
				SetDatafolder $GetWavesDatafolder(Yw, 1)
				YWaveName = NameOfWave(Yw)
				if (CmpStr(YWaveName[0], "'") == 0)
					YWaveName = YWaveName[1, strlen(YWaveName)-2]
				endif
				YWaveName = "Res_"+YWaveName
				Duplicate/O Yw, $YWaveName
				Wave Rw = $YWaveName
				Wave/Z Xw=$(DataSetList[i][1])
				if (isAllAtOnceFunc)
					if (!WaveExists(Xw))
						Duplicate/O Rw, dummyX
						Wave Xw=dummyX
						Xw = x
					endif
					GlblFitFuncAllAtOnce(w, Rw, Xw)
					Rw = Yw - Rw
				else
					if (WaveExists(Xw))
						Rw=Yw-GlblFitFunc(w, Xw)
					else
						Rw=Yw-GlblFitfunc(w, x)
					endif
				endif
				SetDatafolder $saveDF
			endif
			
			i += 1
		while (i < NumSets)
	endif
	
	Wave/Z w = dummyX
	if (WaveExists(w))
		KillWaves w
	endif
	Wave/Z w = TempXW
	if (WaveExists(w))
		KillWaves w
	endif
	Wave/Z w = TempYW
	if (WaveExists(w))
		KillWaves w
	endif
End

Function MakeFitCurveWaves()

	WAVE/T List=root:Packages:GlobalFit:DataSetList

	NVAR FitCurvePoints=root:Packages:GlobalFit:FitCurvePoints

	Variable i
	String XSet, YSet
	String saveDF

	String WaveDF
	Variable CalcX=0
	Variable x1, x2
	
	i = 0
	do
		YSet = List[i][0]
		Wave/Z Ysetw = $YSet
		if (strlen(YSet) == 0)
			break
		endif
		XSet = List[i][1]
		Wave/Z Xsetw = $XSet
		if (cmpstr(XSet, "_Calculated_") == 0)
			CalcX = 1
		else
			CalcX = 0
		endif

		saveDF = GetDatafolder(1)
		SetDatafolder $GetWavesDataFolder(Ysetw, 1)
		WaveDF = NameofWave(Ysetw)
		if (CmpStr(WaveDF[0], "'") == 0)
			WaveDF = WaveDF[1, strlen(WaveDF)-2]
		endif
		WaveDF = "Fit_"+WaveDF
		Make/O/D/N=(FitCurvePoints) $WaveDF
		Wave YFit = $WaveDF
		if (WaveExists(Xsetw))
			WaveStats/Q Xsetw
			x1 = V_min
			x2 = V_max
			SetScale/I x x1,x2,YFit
		else
			CopyScales/I Ysetw, YFit
		endif
		SetDatafolder $saveDF
		
		i += 1
	while (1)
end


Function InitGlobalFitGlobals()
	
	String saveFolder = GetDataFolder(1)
	if (DatafolderExists("root:Packages:GlobalFit"))
		return 0
	endif
	
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S GlobalFit
	
	NVAR/Z NBasicCoefs = NBasicCoefs
	if (!NVAR_Exists(NBasicCoefs))
		Variable/G NBasicCoefs = 1
	endif
	Variable/G NGlobalParams
	Variable/G NLocalParams
	Variable/G NumSets=0
	Variable/G TotalParams = NBasicCoefs	// undoubtedly wrong...
	Variable/G DoFitFunc=0
	Variable/G FitCurvePoints = 200

	Make/T/N=(NBasicCoefs,2)/O ParamTypesText
	SetDimLabel 1,0,'Parameter',ParamTypesText
	SetDimLabel 1,1,'Global?',ParamTypesText
	Wave/Z CoefIsGlobal = CoefIsGlobal
	if (!WaveExists(CoefIsGlobal))
		Make/O/N=(NBasicCoefs) CoefIsGlobal = 0
	endif
	Make/N=(NBasicCoefs,2)/O/U/B ParamTypesSel
	ParamTypesSel[][1] = 32+16*CoefIsGlobal[p]
	ParamTypesSel[][0]=0
	ParamTypesText[][0] = "Coef "+num2istr(p)
	NGlobalParams = sum(CoefIsGlobal, -inf, inf)
	NLocalParams = NBasicCoefs - NGlobalParams
	
	Make/N=1/O/T GuessListWave="No Data Sets Selected"
	Make/N=1/O/U/B GuessListSelection=0
	
	Make/T/N=(1,2)/O DataSetList=""
	SetDimLabel 1,0,'Y Data Sets',DataSetList
	SetDimLabel 1,1,'X Data Sets',DataSetList
	Make/N=(1,2,2)/O DataSetListSelection		// one plane for colors?
	DataSetListSelection[0][0]=1
	DataSetListSelection[0][1]=0
	
	String/G TopGraph=""
	String/G UserFitFunc="GlobalFitFunc"
	
	SetDataFolder $saveFolder
end

Function InitGlobalFitPanel()

	Silent 1; PauseUpdate
	
	if (wintype("GlobalFitPanel") == 0)
		InitGlobalFitGlobals()
		fGlobalFitPanel()
		SetNumBasicParamsProc("",0,"","")
	else
		DoWindow/F GlobalFitPanel
	endif
end

Function UnloadGlobalFit()
	if (WinType("GlobalFitPanel") == 7)
		DoWindow/K GlobalFitPanel
	endif
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	if (WinType("CopyToFromInitialGuessesPanel") != 0)
		DoWindow/K CopyToFromInitialGuessesPanel
	endif
	if (DatafolderExists("root:Packages:GlobalFit"))
		KillDatafolder root:Packages:GlobalFit
	endif
	Execute/P "DELETEINCLUDE \"GlobalFit4_NCNR\""
	Execute/P "COMPILEPROCEDURES "
end

Function fGlobalFitPanel()

	Variable left = NumVarOrDefault("root:Packages:GlobalFit:GlobalFitPanelLeft", 45)
	Variable top = NumVarOrDefault("root:Packages:GlobalFit:GlobalFitPaneltop", 55)
	Variable right = NumVarOrDefault("root:Packages:GlobalFit:GlobalFitPanelright", 451)
	Variable bottom = NumVarOrDefault("root:Packages:GlobalFit:GlobalFitPanelbottom", 531)
	Variable DividerTop = NumVarOrDefault("root:Packages:GlobalFit:GlobalFitPanelDividerTop", 263)
	
	NewPanel /K=1 /W=(left, top, right, bottom) as "Global Analysis"
	DoWindow/C GlobalFitPanel
	
	Button GF_HelpButton,pos={372,5},size={25,20},proc=GF_HelpButtonProc,title="?"

	PopupMenu GlobalFitFuncMenu,pos={20,6},size={142,20},proc=BasicFitFunctionMenuProc,title="Basic Fit Function"
	PopupMenu GlobalFitFuncMenu,mode=0,value= #"ListPossibleFitFunctions()"
	SetVariable SetBasicFitFunction,pos={171,9},size={150,15},title=" "
	SetVariable SetBasicFitFunction,limits={-Inf,Inf,1},value= root:Packages:GlobalFit:UserFitFunc
	CheckBox RequireFitFuncCheckbox,pos={191,25},size={183,14},title="Require FitFunc Function Subtype"
	CheckBox RequireFitFuncCheckbox,value= 1

	GroupBox ParametersGroupBox,pos={5,30},size={397,100},title="Parameters"
	SetVariable SetNumBasicParms,pos={12,46},size={161,15},proc=SetNumBasicParamsProc,title=" # Basic Parameters:"
	SetVariable SetNumBasicParms,limits={1,Inf,1},value= root:Packages:GlobalFit:NBasicCoefs
	ListBox ParamTypesListBox,pos={208,47},size={154,79},proc=ParamTypeListBoxProc
	ListBox ParamTypesListBox,frame=2
	ListBox ParamTypesListBox,listWave=root:Packages:GlobalFit:ParamTypesText
	ListBox ParamTypesListBox,selWave=root:Packages:GlobalFit:ParamTypesSel,mode= 5
	ListBox ParamTypesListBox,widths= {70,40}

	GroupBox DataSetsGroupBox,pos={5,132},size={397,126},title="Data Sets"
	PopupMenu AddWaveMenu,pos={15,148},size={51,20},proc=AddWaveProc,title="Add"
	PopupMenu AddWaveMenu,mode=0,value= #"AddWaveMenuContents()"
	PopupMenu RemoveWaveMenu,pos={75,148},size={63,20},proc=RmveWaveProc,title="Rmve"
	PopupMenu RemoveWaveMenu,mode=0,value= #"\"Remove Selection;Remove Entire Row;Remove All\""
	Button WavesFromTarget,pos={286,148},size={110,20},proc=FromTargetProc,title="All From Target"
	ListBox xdatalist,pos={11,175},size={386,86},frame=2
	ListBox xdatalist,listWave=root:Packages:GlobalFit:DataSetList
	ListBox xdatalist,selWave=root:Packages:GlobalFit:DataSetListSelection,mode= 5

	GroupBox GuessesGroupBox,pos={5,270},size={397,146},title="Initial Guesses"
	Button CopyInitialGuessListButton,pos={12,289},size={161,20},proc=CopyInitialGuessButtonProc,title="Copy To/From Wave..."
	ListBox GuessesList,pos={11,317},size={386,93},frame=2
	ListBox GuessesList,listWave=root:Packages:GlobalFit:GuessListWave
	ListBox GuessesList,selWave=root:Packages:GlobalFit:GuessListSelection,mode= 7
	ListBox GuessesList,editStyle= 1,widths= {19,10,8,8}

	Variable BottomGroupBoxTop = bottom - top - 71
	GroupBox BottomGroupBox,pos={4,BottomGroupBoxTop},size={398,67}
	Variable CheckboxTops = BottomGroupBoxTop + 7
	CheckBox ConstraintsCheckBox,pos={11,CheckboxTops},size={114,14},proc=ConstraintsCheckProc,title="Apply Constraints..."
	CheckBox ConstraintsCheckBox,value= 0
	CheckBox WeightingCheckBox,pos={130,CheckboxTops},size={76,14},proc=WeightingCheckProc,title="Weighting..."
	CheckBox WeightingCheckBox,value= 0
	CheckBox MaskingCheckBox,pos={211,CheckboxTops},size={67,14},proc=MaskingCheckProc,title="Masking..."
	CheckBox MaskingCheckBox,value= 0
	CheckBox DoCovarMatrix,pos={285,CheckboxTops},size={108,14},title="Covariance Matrix"
	CheckBox DoCovarMatrix,value= 0
	CheckboxTops += 19
	CheckBox AppendResultsCheck,pos={11,CheckboxTops},size={166,14},title="Append fit results to top graph"
	CheckBox AppendResultsCheck,value= 1
	CheckBox DoResidualCheck,pos={201,CheckboxTops},size={111,14},title="Calculate Residuals"
	CheckBox DoResidualCheck,value= 0
	CheckboxTops += 19
	SetVariable GFSetFitCurveLength,pos={35,CheckboxTops},size={137,15},bodyWidth= 50,title="Fit Curve Points:"
	SetVariable GFSetFitCurveLength,limits={2,Inf,1},value= root:Packages:GlobalFit:FitCurvePoints
	SetVariable GFSetFitCurveLength,disable=1		//SRK - use experimental q-vals...
	Button DoFitButton,pos={336,CheckboxTops-9},size={50,20},proc=DoTheFit,title="Fit!"
	
	GroupBox ListDivider,pos={3,DividerTop},size={400,2}

	HandleDividerMoved(DividerTop)
	
	SaveGlobalFitPanelSize()
	SetWindow GlobalFitPanel,hook=GlobalFitWindowHook, hookevents=3
EndMacro

Function SaveGlobalFitPanelSize()

	String saveDF=GetDatafolder(1)
	Variable pointsToPixels = ScreenResolution/72
	SetDatafolder root:Packages:GlobalFit
	GetWindow GlobalFitPanel wsize			// sets root:Packages:GlobalFit:V_top, etc.
	Variable/G GlobalFitPanelTop = V_top*pointsToPixels
	Variable/G GlobalFitPanelBottom = V_bottom*pointsToPixels
	Variable/G GlobalFitPanelLeft = V_Left*pointsToPixels
	Variable/G GlobalFitPanelRight = V_Right*pointsToPixels
	ControlInfo ListDivider
	Variable/G GlobalFitPanelDividerTop = V_top
	SetDatafolder $saveDF
end

Function/S ListPossibleFitFunctions()

	string theList="", UserFuncs, XFuncs
	
	string options = "KIND:10"
	ControlInfo/W=GlobalFitPanel RequireFitFuncCheckbox
	if (V_value)
		options += ",SUBTYPE:FitFunc"
	endif
	options += ",NINDVARS:1"
	
	UserFuncs = FunctionList("*", ";",options)
	UserFuncs = RemoveFromList("GlobalFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("GlobalFitAllAtOnce", UserFuncs)
	UserFuncs = RemoveFromList("GlblFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("GlblFitFuncAllAtOnce", UserFuncs)

	XFuncs = FunctionList("*", ";", "KIND:12")
	
	if (strlen(UserFuncs) > 0)
		theList +=  "\\M1(User-defined functions:;"
		theList += UserFuncs
	endif
	if (strlen(XFuncs) > 0)
		theList += "\\M1(External Functions:;"
		theList += XFuncs
	endif
	
	if (strlen(theList) == 0)
		theList = "\\M1(No Fit Functions"
	endif
	
	return theList
end

Function BasicFitFunctionMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	SVAR UserFitFunc=root:Packages:GlobalFit:UserFitFunc
	
	UserFitFunc = popStr
End

Function/S AddWaveMenuContents()

	String theContents=""
	Variable DoingX=0
	Variable workingRow
	
	WAVE/T List=root:Packages:GlobalFit:DataSetList
	WAVE ListSelection=root:Packages:GlobalFit:DataSetListSelection
	
	FindSelection(ListSelection, workingRow, DoingX)
	if (DoingX)
		theContents += "_Calculated_;-;"
	endif
	theContents += WaveList("*", ";", "")
	
	return theContents
end

Function SetNumBasicParamsProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Wave CTypes = root:Packages:GlobalFit:CoefIsGlobal
	Wave/T ParamTypesText = root:Packages:GlobalFit:ParamTypesText
	Wave ParamTypesSel = root:Packages:GlobalFit:ParamTypesSel
	
	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	Variable OldNBParams = DimSize(CTypes, 0)
	Redimension/N=(NBParams, -1) CTypes, ParamTypesText, ParamTypesSel
	if (OldNBParams < NBParams)
		CTypes[OldNBParams,NBParams-1] = 0
		ParamTypesText[][0] = "Coef "+num2istr(p)
		ParamTypesText[][1] = ""
		ParamTypesSel[][1] = 32+16*CTypes[p]
		ParamTypesSel[][0]=0
	endif
	
	ParamTypeListBoxProc("",0,1,2)
	setParams()
End

Function ParamTypeListBoxProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code

	if (event != 2)
		return 0
	endif
	if (col != 1)
		return 0
	endif
	if (row < 0)
		return 0
	endif
	
	// now we have only a mouse-up in the Global? checkbox column
	Wave CTypes = root:Packages:GlobalFit:CoefIsGlobal
	Wave ParamTypesSel = root:Packages:GlobalFit:ParamTypesSel

	CTypes = (ParamTypesSel[p][1] & 16)!=0
	
	setParams()
   	 return 0            // other return values reserved
end

Function setParams()

	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	Make/O/N=(NBParams) root:Packages:GlobalFit:CoefIsGlobal
	Wave CTypes = root:Packages:GlobalFit:CoefIsGlobal
	NVAR NGlobalParams=root:Packages:GlobalFit:NGlobalParams
	NVAR NLocalParams=root:Packages:GlobalFit:NLocalParams
	
	NGlobalParams = 0
	NLocalParams = 0
	
	Variable i=0
	do
		if (CTypes[i])
			NGlobalParams += 1
		else
			NLocalParams += 1
		endif
		i += 1
	while (i < NBParams)
	
	Make/D/O/N=(NGlobalParams) root:Packages:GlobalFit:GlobalParams
	Make/D/O/N=(NLocalParams) root:Packages:GlobalFit:LocalParams
	Wave GParams=root:Packages:GlobalFit:GlobalParams
	Wave LParams=root:Packages:GlobalFit:LocalParams
	
	Variable theLocal = 0
	Variable theGlobal = 0
	i = 0
	do
		if (CTypes[i])
			GParams[theGlobal] = i
			theGlobal += 1
		else
			LParams[theLocal] = i
			theLocal += 1
		endif
		i += 1
	while (i < NBParams)
end


Function FindSelection(w, row, col)
	Wave w
	Variable &row
	Variable &col
	
	Variable numRows = DimSize(w, 0)
	Variable numCols = DimSize(w,1)
	Variable i,j
	for (i = 0; i < numRows; i += 1)
		for (j=0; j < numCols; j += 1)
			if (w[i][j] != 0)
				row = i
				col = j
				return 0
			endif
		endfor
	endfor
end

// works only on a coniguous rectangular selection
Function FindSelectionRectangle(w, startRow, endRow, startCol, endCol)
	Wave w
	Variable &startRow
	Variable &endRow
	Variable &startCol
	Variable &endCol
	
	Variable i,j
	Variable nRows = DimSize(w, 0)
	Variable nCols = DimSize(w, 1)
	if (nCols == 0)
		nCols = 1
	endif
	startRow = -1
	startCol = -1
	for (j = 0; j < nCols; j += 1)
		for (i = 0; i < nRows; i += 1)
			if (w[i][j] != 0)
				startRow = i
				startCol = j
				break
			endif
		endfor
	endfor
	if (startRow == -1)
		return -1;
	endif
	for (i = startRow; i < nRows; i += 1)
		if (w[i][startCol] == 0)
			endRow = i-1
			break
		endif
	endfor
	if (endRow == -1)
		endRow = nRows-1
	endif
	for (i = startCol; i < nCols; i += 1)
		if (w[endRow][i] == 0)
			endCol = i-1
			break
		endif
	endfor
	if (endCol == -1)
		endCol = nCols-1
	endif
	
	return 0
end

Function AddWaveProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable DoingX=0
	
	WAVE/T List=root:Packages:GlobalFit:DataSetList
	WAVE ListSelection=root:Packages:GlobalFit:DataSetListSelection
	Variable workingRow
	FindSelection(ListSelection, workingRow, DoingX)
	
	String CDF=GetDataFolder(1)
	String thisWave
	Variable i, wavetype
	Variable nItems
	
	Variable lastRow = DimSize(List, 0)-1
	
	if (workingRow == lastRow)
		InsertPoints lastRow+1, 1, List, ListSelection
		ListSelection = 0
		ListSelection[workingRow+1][DoingX] = 1
	endif
	if (DoingX %& (cmpstr(popStr, "_Calculated_") == 0))
		thisWave = "_Calculated_"
	else
		thisWave = CDF+PossiblyQuoteName(popStr)
	endif
	List[workingRow][DoingX] = thisWave
	
	DataSetsOKProc()
End

Function/S GetBrowserSelectionList()

	String theList = ""
	String oneItem
	Variable i=0
	do
		oneItem = GetBrowserSelection(i)
		if (strlen(oneItem) == 0)
			break
		endif
		theList += oneItem+";"
		i += 1
	while (1)
	
	return theList
end

Function RmveWaveProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Variable DoingX=0
	
	WAVE/T List=root:Packages:GlobalFit:DataSetList
	WAVE ListSelection=root:Packages:GlobalFit:DataSetListSelection
	Variable workingRow
	FindSelection(ListSelection, workingRow, DoingX)
	
	Variable lastRow = DimSize(List, 0)-1

	strswitch (popStr)
		case "Remove Selection":
			List[workingRow][DoingX] = ""
			if ( (strlen(List[workingRow][0]) == 0) && (strlen(List[workingRow][1]) == 0) )
				if (workingRow != lastRow)
					DeletePoints workingRow, 1, List, ListSelection
				endif
			endif
			break
		case "Remove Entire Row":
			if (workingRow != lastRow)
				DeletePoints workingRow, 1, List, ListSelection
			endif
			break
		case "Remove All":
			Redimension/N=(1,2) List,ListSelection
			List = ""
			ListSelection = 0
			ListSelection[0][DoingX] = 1
			break
	endswitch
	
	DataSetsOKProc()
End


Function DataSetsOKProc()

	WAVE/T List=root:Packages:GlobalFit:DataSetList
	WAVE ListSelection=root:Packages:GlobalFit:DataSetListSelection
	
	Wave/T GuessListWave = root:Packages:GlobalFit:GuessListWave
	WAVE/U/B GuessListSelection=root:Packages:GlobalFit:GuessListSelection

	Wave CTypes = root:Packages:GlobalFit:CoefIsGlobal
	NVAR NBParams=root:Packages:GlobalFit:NBasicCoefs
	NVAR NGlobalParams=root:Packages:GlobalFit:NGlobalParams
	NVAR NLocalParams=root:Packages:GlobalFit:NLocalParams
	NVAR NumSets=root:Packages:GlobalFit:NumSets
	NumSets = 0
	
	Variable i, j
	String XSet, YSet
	
	Make/D/N=0/O root:Packages:GlobalFit:XCumData, root:Packages:GlobalFit:YCumData, root:Packages:GlobalFit:IndexPointer
	Make/O/N=(0, NBParams+1) root:Packages:GlobalFit:Index
	Wave Xw = root:Packages:GlobalFit:XCumData
	Wave Yw = root:Packages:GlobalFit:YCumData
	Wave IndexP = root:Packages:GlobalFit:IndexPointer
	Wave IndexW = root:Packages:GlobalFit:Index
	String msg
	Variable CalcX=0
	
	i = 0
	do
		YSet = List[i][0]
		Wave/Z Ysetw = $YSet
		if (strlen(YSet) == 0)
			break
		endif
		if (!WaveExists(YSetw))
			ListSelection = 0
			ListSelection[i][0] = 1
			DoUpdate
			msg="The Y wave \""+YSet+"\" does not exist"
			abort msg
		endif
		XSet = List[i][1]
		Wave/Z Xsetw = $XSet
		if (cmpstr(XSet, "_Calculated_") == 0)
			CalcX = 1
		else
			CalcX = 0
			if (!WaveExists(Xsetw))
				ListSelection = 0
				ListSelection[i][1] = 1
				DoUpdate
				msg="The X wave \""+XSet+"\" does not exist"
				abort msg
			endif
		endif
		Redimension/N=((i+1), -1) IndexW
		IndexW[i][0] = numpnts(Xw)
		ConcatenateSets(Xw, Yw, Xsetw, Ysetw, IndexP, CalcX)

		i += 1
	while (1)

	if (i == 0)
		KillWaves/Z Xw, Yw
		Redimension/N=1 GuessListWave
		GuessListWave = "No Data Sets Selected"
		Redimension/N=1 GuessListSelection
		GuessListSelection = 0
		ListBox GuessesList,listWave=GuessListWave, mode=0
		ListBox GuessesList,selWave=GuessListSelection
		return 0
	endif

	NumSets = i
	NVAR TotalParams= root:Packages:GlobalFit:TotalParams
	TotalParams = NGlobalParams+NumSets*NLocalParams
	
	Make/O/D/N=(TotalParams) root:Packages:GlobalFit:AllCoefs
	Wave/D AllCoefs = root:Packages:GlobalFit:AllCoefs
	
	Wave GlobalParams=root:Packages:GlobalFit:GlobalParams
	Wave LocalParams=root:Packages:GlobalFit:LocalParams
	
	Make/N=(TotalParams, 4)/T/O root:Packages:GlobalFit:GuessListWave
	Wave/T GuessListWave = root:Packages:GlobalFit:GuessListWave
	Make/N=(TotalParams, 4)/O/U/B root:Packages:GlobalFit:GuessListSelection=0
	Wave/U/B GuessListSelection = root:Packages:GlobalFit:GuessListSelection

	SetDimLabel 1, 0, 'Coefficient', GuessListWave, GuessListSelection
	SetDimLabel 1, 1, 'Initial Guess', GuessListWave, GuessListSelection
	SetDimLabel 1, 2, 'Hold?', GuessListWave, GuessListSelection
	SetDimLabel 1, 3, Epsilon, GuessListWave, GuessListSelection

	for (i = 0;  i < NGlobalParams; i += 1)
		GuessListWave[i][%Coefficient] = "Global Parameter; Coef["+num2istr(GlobalParams[i])+"]"
		for (j = 0; j < NumSets; j += 1)
			IndexW[j][GlobalParams[i]+1] = i
		endfor
	endfor
	
	for (i = 0; i < NumSets; i += 1)
		for (j = 0; j < NLocalParams; j += 1)
			GuessListWave[NGlobalParams+i*NLocalParams+j][%Coefficient] = List[i][0]+"; Coef["+num2istr(LocalParams[j])+"]"
			IndexW[i][LocalParams[j]+1] = NGlobalParams+i*NLocalParams+j
		endfor
	endfor
	
	GuessListSelection[][%Coefficient] = 0				// labels for the coefficients
	GuessListSelection[][%'Initial Guess'] = 2			// editable field to enter initial guesses
	GuessListSelection[][%'Hold?'] = 32					// checkbox for holds
	GuessListSelection[][%Epsilon] = 2					// editable field to enter epsilon values
	GuessListWave[][%'Initial Guess'] = "0"
	GuessListWave[][%'Hold?'] = "Hold"
	GuessListWave[][%Epsilon] = "1e-4"
	ListBox GuessesList,listWave=GuessListWave, mode=7
	ListBox GuessesList,selWave=GuessListSelection,editstyle=1
	ListBox GuessesList,widths={19,10,8,8}
	
	Wave/Z HoldWave = root:Packages:GlobalFit:'Enter 1 to Hold'
	if (WaveExists(HoldWave))
		KillWaves HoldWave
	endif

	return(NumSets)
End

Function/S ListPossibleInitialGuessWaves()

	Wave/T/Z GuessListWave = root:Packages:GlobalFit:GuessListWave
	NVAR/Z TotalParams= root:Packages:GlobalFit:TotalParams
	if ( (!WaveExists(GuessListWave)) || (!NVAR_Exists(TotalParams)) || (TotalParams <= 0) )
		return "Data sets not initialized"
	endif
	
	Variable numpoints = DimSize(GuessListWave, 0)
	String theList = ""
	Variable i=0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		if ( (DimSize(w, 0) == numpoints) && (WaveType(w) & 6) )		// select floating-point waves with the right number of points
			theList += NameOfWave(w)+";"
		endif
		i += 1
	while (1)
	
	if (i == 0)
		return "None Available"
	endif
	return theList
end


Function CopyInitialGuessButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if (WinType("CopyToFromInitialGuessesPanel") == 7)
		DoWindow/F CopyToFromInitialGuessesPanel
	else
		Variable panelWidth = 200
		Variable panelHeight = 160
		ControlInfo/W=GlobalFitPanel GuessesList
		Variable top = V_top
		Variable left = V_left+V_width
		Variable bottom = top + panelHeight
		Variable right = left+panelWidth
		GetWindow GlobalFitPanel, wsize
		top += V_top
		bottom += V_top
		left += V_left
		right += V_left
		NewPanel/K=1/W=(left,top,right,bottom) as "Copy to/from Waves"
		DoWindow/C CopyToFromInitialGuessesPanel
		AutoPositionWindow/M=1/R=GlobalFitPanel CopyToFromInitialGuessesPanel	//keep onscreen
		
		Variable/G root:Packages:GlobalFit:CopyInitialGuessRadioValue = NumVarOrDefault("root:Packages:GlobalFit:CopyInitialGuessRadioValue", 1)
		NVAR CopyInitialGuessRadioValue = root:Packages:GlobalFit:CopyInitialGuessRadioValue
		
		PopupMenu InitGuessToWaveMenu,pos={22,90},size={145,20},proc=InitGuessToWaveMenuProc,title="Copy Guess To Wave"
		PopupMenu InitGuessToWaveMenu,mode=0,value= #"ListPossibleInitialGuessWaves()+\"-;New Wave...\""
		PopupMenu WaveToInitGuessMenu,pos={22,61},size={145,20},proc=WaveToInitGuessMenuProc,title="Copy Wave To Guess"
		PopupMenu WaveToInitGuessMenu,mode=0,value= #"ListPossibleInitialGuessWaves()"
		CheckBox CopyInitialGuessRadio,pos={36,13},size={115,14},title="Copy Initial Guesses"
		CheckBox CopyInitialGuessRadio,value = CopyInitialGuessRadioValue,mode=1, proc = CopyInitialGuessRadioProc
		CheckBox CopyEpsilonRadio,pos={36,30},size={80,14},title="Copy Epsilon"
		CheckBox CopyEpsilonRadio,value= !CopyInitialGuessRadioValue,mode=1, proc = CopyInitialGuessRadioProc
		Button CopyInitialGuessDoneButton,pos={65,123},size={50,20},title="Done", proc=CopyGuessWavesDoneButtonProc
	endif
End

Function CopyGuessWavesDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR CopyInitialGuessRadioValue = root:Packages:GlobalFit:CopyInitialGuessRadioValue
	ControlInfo CopyInitialGuessRadio
	CopyInitialGuessRadioValue = V_Value
	DoWindow/K CopyToFromInitialGuessesPanel
end

Function CopyInitialGuessRadioProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (CmpStr(ctrlName, "CopyInitialGuessRadio") == 0)
		CheckBox CopyInitialGuessRadio, value=checked
		CheckBox CopyEpsilonRadio, value=!checked
	else
		CheckBox CopyInitialGuessRadio, value=!checked
		CheckBox CopyEpsilonRadio, value=checked
	endif
End

Function WaveToInitGuessMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	ControlInfo/W=CopyToFromInitialGuessesPanel CopyInitialGuessRadio
	Variable DoInitialGuesses = V_value
	
	Wave/T/Z GuessListWave = root:Packages:GlobalFit:GuessListWave
	Wave/Z cWave = $popStr
	if (!WaveExists(cWave))
		DoAlert 0, "Strange- the wave "+popStr+" doesn't exist"
		return -1
	endif
	if (DoInitialGuesses)
		GuessListWave[][%'Initial Guess'] = num2str(cWave[p])
	else
		GuessListWave[][%'Epsilon'] = num2str(cWave[p])
	endif
	return 0
End

Function InitGuessToWaveMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	ControlInfo/W=CopyToFromInitialGuessesPanel CopyInitialGuessRadio
	Variable DoInitialGuesses = V_value
	
	Wave/T/Z GuessListWave = root:Packages:GlobalFit:GuessListWave
	if (CmpStr(popStr, "New Wave...") == 0)
		Variable npnts = DimSize(GuessListWave, 0)
		String newWaveName = NewGuessWaveName()
		if (Exists(newWaveName) == 1)
			newWaveName = UniqueName(newWaveName, 1, 0)
		endif
		Make/D/N=(npnts) $newWaveName
		Wave/Z cWave = $newWaveName
		if (!WaveExists(cWave))
			return -1
		endif
	else
		Wave/Z cWave = $popStr
		if (!WaveExists(cWave))
			DoAlert 0, "Strange- the wave "+popStr+" doesn't exist"
			return -1
		endif
	endif
	if (DoInitialGuesses)
		cWave = str2num(GuessListWave[p][%'Initial Guess'])
	else
		cWave = str2num(GuessListWave[p][%'Epsilon'])
	endif
	return 0
End

Function/S NewGuessWaveName()

	String theName = "GlobalFitCoefs"
	Prompt theName, "Enter a name for the wave:"
	DoPrompt "Save Global Fit Coefficients", theName
	
	return theName
end

Function ConcatenateSets(Xwave,Ywave, NextXWave, NextYWave, IndexP, CalcX)
	Wave Xwave, Ywave, NextYWave, IndexP
	Wave/Z NextXWave
	Variable CalcX
		
	Variable ndata, numcoefs
	NVAR NumSets=root:Packages:GlobalFit:NumSets
	NumSets += 1
		
	ndata = numpnts(Xwave)
	Variable NewPnts=ndata+numpnts(NextYWave)
	Redimension/N=(NewPnts) Ywave
	Redimension/N=(NewPnts) Xwave
	Redimension/N=(NewPnts) IndexP
	Ywave[ndata,] = NextYWave[p-ndata]
	if (!CalcX)
		Xwave[ndata,] = NextXWave[p-ndata]
	else
		Xwave[ndata,] = pnt2x(NextYWave, p-ndata)
	endif
	IndexP[ndata,] = NumSets-1
	return(0)
end


Function FromTargetProc(ctrlName) : ButtonControl
	String ctrlName
	
	WAVE/T List=root:Packages:GlobalFit:DataSetList
	WAVE ListSelection=root:Packages:GlobalFit:DataSetListSelection
	
	Variable i
	Variable pointInList
	String TName
	String theGraph=WinName(0,1)
	
	Redimension/N=(1,2) List, ListSelection
	List = ""
	ListSelection = 0
	i = 0
	pointInList = 0
	
	String tlist = TraceNameList(theGraph, ";", 1)
	String aTrace
	do
		aTrace = StringFromList(i, tlist)
		if (strlen(aTrace) == 0)
			break
		endif
		
		Wave/Z w = TraceNameToWaveRef(theGraph, aTrace)
		TName = NameOfWave(w)
		if (cmpstr(TName[0,3], "Fit_") != 0)
			if (!WaveExists(w))
				break
			endif
			InsertPoints pointInList+1, 1, List, ListSelection
			List[pointInList][0] += GetWavesDataFolder(w, 2)
			WAVE/Z w = XWaveRefFromTrace(theGraph, aTrace)
			if (WaveExists(w))
				List[pointInList][1] = GetWavesDataFolder(w, 2)
			else
				List[pointInList][1] = "_Calculated_"
			endif
			pointInList += 1
		endif
		i += 1
	while(1)
	ListSelection[i][0] = 1
	
	DataSetsOKProc()
End


Function/S MakeHoldString()

	Wave/U/B  GuessListSelection=root:Packages:GlobalFit:GuessListSelection
	
	String HS="/H=\""
	Variable nCoefs=DimSize(GuessListSelection, 0)
	Variable nHolds=0
	Variable i=0
	do
		if (GuessListSelection[i][%'Hold?'] & 16)
			HS += "1"
			nHolds += 1
		else
			HS += "0"
		endif
		i += 1
	while (i < nCoefs)
	
	if (nHolds == 0)
		HS = ""
	else
		HS += "\""
		print "Hold String=", HS
	endif
	return HS
end

Static Constant MOVECONTROLSDYNAMICALLY=0

Function GlobalFitWindowHook (infoStr)
	String infoStr

	Variable statusCode = 0
	Variable MouseX
	Variable MouseY

	String Event = StringByKey("EVENT", infoStr)
	strswitch (Event)
		case "kill":
			SaveGlobalFitPanelSize()
			DoAlert 1, "Closing Global Fit control panel. Remove private Global Fit data structures (your data fits will not be affected)?"
			if (V_flag == 1)
				if (WinType("GlobalFitGraph") != 0)
					DoWindow/K GlobalFitGraph
				endif
				KillDatafolder root:Packages:GlobalFit
				statusCode = 1
			endif
			break
		case "resize":
			String win= StringByKey("WINDOW",infoStr)
			Variable pixelsToPoints = ScreenResolution/72
			GlobalFitPanelMinWindowSize(win, 406/pixelsToPoints, 474/pixelsToPoints)	// make sure the window isn't too small
			GlobalFitResize()
			statusCode=1
			break
		case "mousedown":
			MouseX = NumberByKey("MOUSEX", infoStr)
			MouseY = NumberByKey("MOUSEY", infoStr)
			ControlInfo/W=GlobalFitPanel ListDivider
			if ( (MouseX >= V_left) && (MouseX <= V_left+V_width) && (MouseY >= V_top-3) && (MouseY <= V_top+V_height+3) )
				Variable/G root:Packages:GlobalFit:MovingDivider = 1
				Variable/G root:Packages:GlobalFit:lastMouseX = mouseX
				Variable/G root:Packages:GlobalFit:lastMouseY = mouseY
				Variable/G root:Packages:GlobalFit:dividerTop = V_top
				Variable/G root:Packages:GlobalFit:dividerLeft = V_left
				SetMinMaxDividerY()
			endif
			break
		case "mousemoved":
			NVAR/Z MovingDivider = root:Packages:GlobalFit:MovingDivider
			MouseX = NumberByKey("MOUSEX", infoStr)
			MouseY = NumberByKey("MOUSEY", infoStr)
			if (NVAR_Exists(MovingDivider) && (MovingDivider) )
				NVAR lastMouseX = root:Packages:GlobalFit:lastMouseX
				NVAR lastMouseY = root:Packages:GlobalFit:lastMouseY
				NVAR dividerTop = root:Packages:GlobalFit:dividerTop
				NVAR dividerLeft = root:Packages:GlobalFit:dividerLeft
				NVAR minDividerY = root:Packages:GlobalFit:minDividerY
				NVAR maxDividerY = root:Packages:GlobalFit:maxDividerY
				Variable deltaY = mouseY - lastMouseY
				dividerTop += deltaY
				if (dividerTop < minDividerY)
					dividerTop = minDividerY
				elseif (dividerTop > maxDividerY)
					dividerTop = maxDividerY
				endif
				ControlInfo/W=GlobalFitPanel ListDivider
				if (dividerTop != V_top)
					GroupBox ListDivider pos={dividerLeft, dividerTop}
					lastMouseY = mouseY
					lastMouseX = mouseX
					if (MOVECONTROLSDYNAMICALLY)
						HandleDividerMoved(dividerTop)
					endif
				endif
			else
				ControlInfo/W=GlobalFitPanel ListDivider
				if ( (MouseX >= V_left) && (MouseX <= V_left+V_width) && (MouseY >= V_top-3) && (MouseY <= V_top+V_height+3) )
					SetWindow GlobalFitPanel hookcursor=6
				else
					SetWindow GlobalFitPanel hookcursor=0
				endif
			endif
			break
		case "mouseup":
			NVAR/Z MovingDivider = root:Packages:GlobalFit:MovingDivider
			if (NVAR_Exists(MovingDivider) && (MovingDivider) )
				// update everything...
				ControlInfo/W=GlobalFitPanel ListDivider
				HandleDividerMoved(V_top)
			endif
			Variable/G root:Packages:GlobalFit:MovingDivider = 0
			break
	endswitch

	return statusCode				// 0 if nothing done, else 1
End

static Function SetMinMaxDividerY()

	ControlInfo/W=GlobalFitPanel DataSetsGroupBox
	Variable/G root:Packages:GlobalFit:minDividerY = V_top+94
	ControlInfo/W=GlobalFitPanel GuessesGroupBox
	Variable/G root:Packages:GlobalFit:maxDividerY = V_top+V_height-100
end

static Function HandleDividerMoved(DividerTop)
	Variable DividerTop

	// resize the data sets list box and the group box containing it
	ControlInfo/W=GlobalFitPanel xdatalist
	ListBox xdatalist, win=GlobalFitPanel, size={V_Width,DividerTop-V_top-11}
	ControlInfo/W=GlobalFitPanel DataSetsGroupBox
	GroupBox DataSetsGroupBox, win=GlobalFitPanel, size={V_Width,DividerTop-V_top-5}

	// move all the controls below the data sets list
	ControlInfo/W=GlobalFitPanel GuessesGroupBox
	Variable deltaTop = DividerTop-V_top+7
	
	GroupBox GuessesGroupBox, win=GlobalFitPanel, pos={V_left,V_top+deltaTop}
	ControlInfo/W=GlobalFitPanel CopyInitialGuessListButton
	Button CopyInitialGuessListButton, win=GlobalFitPanel, pos={V_left,V_top+deltaTop}
	ControlInfo/W=GlobalFitPanel GuessesList
	ListBox GuessesList, win=GlobalFitPanel, pos={V_left,V_top+deltaTop}

	// resize the initial guesses listbox and it's group box
	ControlInfo/W=GlobalFitPanel BottomGroupBox
	Variable BottomGroupBoxTop = V_top
	
	ControlInfo/W=GlobalFitPanel GuessesList
	ListBox GuessesList, win=GlobalFitPanel, size={V_Width,BottomGroupBoxTop - V_top - 13}
	ControlInfo/W=GlobalFitPanel GuessesGroupBox
	GroupBox GuessesGroupBox, win=GlobalFitPanel, size={V_Width,BottomGroupBoxTop - V_top - 7}
End

static Function GlobalFitResize()

	GetWindow GlobalFitPanel wsize
	Variable pointsToPixels = ScreenResolution/72
	V_top = round(V_top*pointsToPixels)			// points to pixels
	V_bottom = round(V_bottom*pointsToPixels)	// points to pixels
	V_left = round(V_left*pointsToPixels)		// points to pixels
	V_right = round(V_right*pointsToPixels)		// points to pixels
	Variable newHeight= V_bottom-V_top			// points
	Variable newWidth = V_right - V_left			// points
	
	NVAR oldTop = root:Packages:GlobalFit:GlobalFitPanelTop
	NVAR oldBottom = root:Packages:GlobalFit:GlobalFitPanelBottom
	NVAR oldLeft = root:Packages:GlobalFit:GlobalFitPanelLeft
	NVAR oldRight = root:Packages:GlobalFit:GlobalFitPanelright

	Variable oldHeight = oldBottom - oldTop
	Variable deltaHeight = newHeight - oldHeight
	Variable oldWidth = oldRight - oldLeft
	Variable deltaWidth = newWidth - oldWidth
	
	MoveWindow /W=GlobalFitPanel V_left/pointsToPixels, V_top/pointsToPixels, V_right/pointsToPixels, V_bottom/pointsToPixels
	SaveGlobalFitPanelSize()

	Variable DataSetsGroupBoxTop = 132		// this never moves!	
	
	// move all the controls below the initial guesses group box
	if ( (deltaHeight != 0) || (deltaWidth != 0) )
		ControlInfo/W=GlobalFitPanel ParametersGroupBox
		GroupBox ParametersGroupBox, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel ParamTypesListBox
		ListBox ParamTypesListBox, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel DataSetsGroupBox
		GroupBox DataSetsGroupBox, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel xdatalist
		ListBox xdatalist, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel WavesFromTarget
		Button WavesFromTarget, win=GlobalFitPanel, pos={V_left+deltaWidth, V_top}
		
		ControlInfo/W=GlobalFitPanel ListDivider
		GroupBox ListDivider, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel BottomGroupBox
		Variable BottomGroupBoxTop = V_top+deltaHeight
		GroupBox BottomGroupBox, win=GlobalFitPanel, pos={V_left,BottomGroupBoxTop}, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel GuessesGroupBox
		GroupBox GuessesGroupBox, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel GuessesList
		ListBox GuessesList, win=GlobalFitPanel, size = {V_width+deltaWidth, V_height}
		
		ControlInfo/W=GlobalFitPanel ConstraintsCheckBox
		CheckBox ConstraintsCheckBox, win=GlobalFitPanel, pos={V_left,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel WeightingCheckBox
		Variable DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
//		Variable DeltaControlPosition = 0
		CheckBox WeightingCheckBox, win=GlobalFitPanel, pos={DeltaControlPosition,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel MaskingCheckBox
		DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
		CheckBox MaskingCheckBox, win=GlobalFitPanel, pos={DeltaControlPosition,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel DoCovarMatrix
//		DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
		CheckBox DoCovarMatrix, win=GlobalFitPanel, pos={V_left + deltaWidth,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel AppendResultsCheck
		CheckBox AppendResultsCheck, win=GlobalFitPanel, pos={V_left,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel DoResidualCheck
		DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
		CheckBox DoResidualCheck, win=GlobalFitPanel, pos={DeltaControlPosition,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel GFSetFitCurveLength
		DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
		SetVariable GFSetFitCurveLength, win=GlobalFitPanel, pos={DeltaControlPosition,V_top+deltaHeight}
		
		ControlInfo/W=GlobalFitPanel DoFitButton
		DeltaControlPosition = round(NewWidth*(V_left/oldWidth))
		Button DoFitButton, win=GlobalFitPanel, pos={V_left + deltaWidth,V_top+deltaHeight}
		
		// Make sure that the lists won't be too short after resize
		ControlInfo/W=GlobalFitPanel ListDivider
		Variable DividerTop = V_top
		Variable DividerLeft = V_left
		
		if ( (BottomGroupBoxTop - DividerTop) < 107)
			DividerTop = BottomGroupBoxTop - 107
		endif
		
		if ( (DividerTop - DataSetsGroupBoxTop) < 94)
			DividerTop = DataSetsGroupBoxTop + 94
		endif
		
		if (DividerTop != V_top)
			// move the divider between the guess list and the datasets list
			GroupBox ListDivider, pos={DividerLeft, DividerTop}
		endif
		
		// and adjust everything around the divider
		HandleDividerMoved(DividerTop)
	endif
End

// keep the width always the same, allow height resize
static Function GlobalFitPanelMinWindowSize(winName,minwidth,minheight)
	String winName
	Variable minwidth,minheight

	GetWindow $winName wsize
	Variable width= max(V_right - V_left, minwidth)
	Variable height= max(V_bottom-V_top,minheight)
	MoveWindow/W=$winName V_left, V_top, V_left+width, V_top+height
End


//***********************************
//
// Constraints
//
//***********************************

Function ConstraintsCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	Wave/T/Z GuessListWave = root:Packages:GlobalFit:GuessListWave
	NVAR TotalParams= root:Packages:GlobalFit:TotalParams
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	if (checked)
		if (NumSets == 0)
			CheckBox ConstraintsCheckBox, win=GlobalFitPanel, value=0
			DoAlert 0, "You cannot add constraints until you have selected data sets"
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:GlobalFit
			
			Wave/T/Z SimpleConstraintsListWave
			if (!(WaveExists(SimpleConstraintsListWave) && (DimSize(SimpleConstraintsListWave, 0) == TotalParams)))
				Make/O/N=(TotalParams, 5)/T SimpleConstraintsListWave=""
			endif
			SimpleConstraintsListWave[][0] = "K"+num2istr(p)
			SimpleConstraintsListWave[][1] = GuessListWave[p][%Coefficient]
			SimpleConstraintsListWave[][3] = "< K"+num2istr(p)+" <"
			Make/O/N=(TotalParams,5) SimpleConstraintsSelectionWave
			SimpleConstraintsSelectionWave[][0] = 0		// K labels
			SimpleConstraintsSelectionWave[][1] = 0		// coefficient labels
			SimpleConstraintsSelectionWave[][2] = 2		// editable- greater than constraints
			SimpleConstraintsSelectionWave[][3] = 0		// "< Kn <"
			SimpleConstraintsSelectionWave[][4] = 2		// editable- less than constraints
			SetDimLabel 1, 0, 'Kn', SimpleConstraintsListWave
			SetDimLabel 1, 1, 'Actual Coefficient', SimpleConstraintsListWave
			SetDimLabel 1, 2, 'Min', SimpleConstraintsListWave
			SetDimLabel 1, 3, ' ', SimpleConstraintsListWave
			SetDimLabel 1, 4, 'Max', SimpleConstraintsListWave
			
			Wave/Z/T MoreConstraintsListWave
			if (!WaveExists(MoreConstraintsListWave))
				Make/N=(1,1)/T/O  MoreConstraintsListWave=""
				Make/N=(1,1)/O MoreConstraintsSelectionWave=6
				SetDimLabel 1,0,'Enter Constraint Expressions', MoreConstraintsListWave
			endif
			MoreConstraintsSelectionWave=6
			
			SetDatafolder $saveDF
			
			if (WinType("GlobalFitConstraintPanel") > 0)
				DoWindow/F GlobalFitConstraintPanel
			else
				fGlobalFitConstraintPanel()
			endif
		endif
	endif
End

Function fGlobalFitConstraintPanel()

	NewPanel /W=(45,203,451,568)
	DoWindow/C GlobalFitConstraintPanel
	AutoPositionWindow/M=1/E

	GroupBox SimpleConstraintsGroup,pos={5,7},size={394,184},title="Simple Constraints"
	Button SimpleConstraintsClearB,pos={21,24},size={138,20},proc=SimpleConstraintsClearBProc,title="Clear List"
	ListBox constraintsList,pos={12,49},size={380,127},listwave=root:Packages:GlobalFit:SimpleConstraintsListWave
	ListBox constraintsList,selWave=root:Packages:GlobalFit:SimpleConstraintsSelectionWave, mode=7
	ListBox constraintsList,widths={30,189,50,40,50}, editStyle= 1,frame=2

	GroupBox AdditionalConstraintsGroup,pos={5,192},size={394,138},title="Additional Constraints"
	ListBox moreConstraintsList,pos={12,239},size={380,85}, listwave=root:Packages:GlobalFit:MoreConstraintsListWave
	ListBox moreConstraintsList,selWave=root:Packages:GlobalFit:MoreConstraintsSelectionWave, mode=4
	ListBox moreConstraintsList, editStyle= 1,frame=2
	Button NewConstraintLineButton,pos={21,211},size={138,20},title="Add a Line", proc=NewConstraintLineButtonProc
	Button RemoveConstraintLineButton01,pos={185,211},size={138,20},title="Remove Selection", proc=RemoveConstraintLineButtonProc

	Button GlobalFitConstraintsDoneB,pos={6,339},size={50,20},proc=GlobalFitConstraintsDoneBProc,title="Done"
EndMacro

Function SimpleConstraintsClearBProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T SimpleConstraintsListWave = root:Packages:GlobalFit:SimpleConstraintsListWave
	SimpleConstraintsListWave[][2] = ""
	SimpleConstraintsListWave[][4] = ""
End

Function NewConstraintLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:Packages:GlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:Packages:GlobalFit:MoreConstraintsSelectionWave
	Variable nRows = DimSize(MoreConstraintsListWave, 0)
	InsertPoints nRows, 1, MoreConstraintsListWave, MoreConstraintsSelectionWave
	MoreConstraintsListWave[nRows] = ""
	MoreConstraintsSelectionWave[nRows] = 6
	Redimension/N=(nRows+1,1) MoreConstraintsListWave, MoreConstraintsSelectionWave
End

Function RemoveConstraintLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:Packages:GlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:Packages:GlobalFit:MoreConstraintsSelectionWave
	Variable nRows = DimSize(MoreConstraintsListWave, 0)
	Variable i = 0
	do
		if (MoreConstraintsSelectionWave[i] & 1)
			if (nRows == 1)
				MoreConstraintsListWave[0] = ""
				MoreConstraintsSelectionWave[0] = 6
			else
				DeletePoints i, 1, MoreConstraintsListWave, MoreConstraintsSelectionWave
				nRows -= 1
			endif
		else
			i += 1
		endif
	while (i < nRows)
	Redimension/N=(nRows,1) MoreConstraintsListWave, MoreConstraintsSelectionWave
End


Function GlobalFitConstraintsDoneBProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K GlobalFitConstraintPanel
End

Function GlobalFitMakeConstraintWave()

	Wave/Z/T SimpleConstraintsListWave = root:Packages:GlobalFit:SimpleConstraintsListWave
	Wave/Z/T MoreConstraintsListWave = root:Packages:GlobalFit:MoreConstraintsListWave
	
	Make/O/T/N=0 root:Packages:GlobalFit:GlobalFitConstraintWave
	Wave/T GlobalFitConstraintWave = root:Packages:GlobalFit:GlobalFitConstraintWave
	Variable nextRow = 0
	String constraintExpression
	Variable i, nPnts=DimSize(SimpleConstraintsListWave, 0)
	for (i=0; i < nPnts; i += 1)
		if (strlen(SimpleConstraintsListWave[i][2]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			sprintf constraintExpression, "K%d > %s", i, SimpleConstraintsListWave[i][2]
			GlobalFitConstraintWave[nextRow] = constraintExpression
			nextRow += 1
		endif
		if (strlen(SimpleConstraintsListWave[i][4]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			sprintf constraintExpression, "K%d < %s", i, SimpleConstraintsListWave[i][4]
			GlobalFitConstraintWave[nextRow] = constraintExpression
			nextRow += 1
		endif
	endfor
	
	nPnts = DimSize(MoreConstraintsListWave, 0)
	for (i = 0; i < nPnts; i += 1)
		if (strlen(MoreConstraintsListWave[i]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			GlobalFitConstraintWave[nextRow] = MoreConstraintsListWave[i]
			nextRow += 1
		endif
	endfor
end

//***********************************
//
// Weighting
//
//***********************************

Function WeightingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	WAVE/T DataSetList=root:Packages:GlobalFit:DataSetList
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	if (checked)
		if (NumSets == 0)
			CheckBox WeightingCheckBox, win=GlobalFitPanel, value=0
			DoAlert 0, "You cannot add weighting waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:GlobalFit
			
			Wave/T/Z WeightingListWave
			if (!(WaveExists(WeightingListWave) && (DimSize(WeightingListWave, 0) == NumSets)))
				Make/O/N=(NumSets, 2)/T WeightingListWave=""
			endif
			WeightingListWave[][0] = DataSetList[p][0]
			Make/O/N=(NumSets, 2) WeightingSelectionWave
			WeightingSelectionWave[][0] = 0		// Data Sets
			WeightingSelectionWave[][1] = 0		// Weighting Waves; not editable- select from menu
			SetDimLabel 1, 0, 'Data Set', WeightingListWave
			SetDimLabel 1, 1, 'Weight Wave', WeightingListWave
			
			SetDatafolder $saveDF
			
			if (WinType("GlobalFitWeightingPanel") > 0)
				DoWindow/F GlobalFitWeightingPanel
			else
				fGlobalFitWeightingPanel()
			endif
			
			if(NumVarOrDefault("root:Packages:GlobalFit:GlobalFit_WeightsAreSD", -1 ) == -1)
				Variable/G root:Packages:GlobalFit:GlobalFit_WeightsAreSD = 1		//SD by default	
			endif
			NVAR GlobalFit_WeightsAreSD = root:Packages:GlobalFit:GlobalFit_WeightsAreSD
			if (GlobalFit_WeightsAreSD)
				WeightsSDRadioProc("WeightsSDRadio",1)
			else
				WeightsSDRadioProc("WeightsInvSDRadio",1)
			endif
						
		endif
	endif	
end

Function fGlobalFitWeightingPanel() : Panel

	NewPanel /W=(339,193,745,408)
	DoWindow/C GlobalFitWeightingPanel
	AutoPositionWindow/M=1/E
	
	ListBox WeightWaveListBox,pos={9,63},size={387,112}, mode=2, listWave = root:Packages:GlobalFit:WeightingListWave
	ListBox WeightWaveListBox, selWave = root:Packages:GlobalFit:WeightingSelectionWave, frame=2
	Button GlobalFitWeightDoneButton,pos={24,186},size={50,20},proc=GlobalFitWeightDoneButtonProc,title="Done"
	Button GlobalFitWeightCancelButton,pos={331,186},size={50,20},proc=GlobalFitWeightCancelButtonProc,title="Cancel"
	PopupMenu GlobalFitWeightWaveMenu,pos={9,5},size={152,20},title="Select Weight Wave"
	PopupMenu GlobalFitWeightWaveMenu,mode=0,value= #"ListPossibleWeightWaves()", proc = WeightWaveSelectionMenu
	Button WeightClearSelectionButton,pos={276,5},size={120,20},proc=WeightClearSelectionButtonProc,title="Clear Selection"
	Button WeightClearAllButton,pos={276,32},size={120,20},proc=WeightClearSelectionButtonProc,title="Clear All"

	GroupBox WeightStdDevRadioGroup,pos={174,4},size={95,54},title="Weights  are"
	CheckBox WeightsSDRadio,pos={185,22},size={60,14},proc=WeightsSDRadioProc,title="Std. Dev."
	CheckBox WeightsSDRadio,value= 0, mode=1
	CheckBox WeightsInvSDRadio,pos={185,38},size={73,14},proc=WeightsSDRadioProc,title="1/Std. Dev."
	CheckBox WeightsInvSDRadio,value= 0, mode=1
EndMacro


Function GlobalFitWeightDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z WeightingListWave=root:Packages:GlobalFit:WeightingListWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(WeightingListWave[i][1])
		if (!WaveExists(w))
			ListBox WeightWaveListBox, win=GlobalFitWeightingPanel, selRow = i
			DoAlert 0, "The wave \""+WeightingListWave[i][1]+"\" does not exist."
			WeightingListWave[i][1] = ""
			return -1
		endif
	endfor
		
	DoWindow/K GlobalFitWeightingPanel
End

Function GlobalFitWeightCancelButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K GlobalFitWeightingPanel
	CheckBox WeightingCheckBox, win=GlobalFitPanel, value=0
End

Function/S ListPossibleWeightWaves()

	Wave/T/Z WeightingListWave=root:Packages:GlobalFit:WeightingListWave
	Wave/Z WeightingSelectionWave=root:Packages:GlobalFit:WeightingSelectionWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	String DataSetName=""
	Variable i
	
	ControlInfo/W=GlobalFitWeightingPanel WeightWaveListBox
	DataSetName = WeightingListWave[V_value][0]
	
	if (strlen(DataSetName) == 0)
		return "No Selection;"
	endif
	
	Wave/Z ds = $DataSetName
	if (!WaveExists(ds))
		return "Unknown Data Set;"
	endif
	
	Variable numpoints = DimSize(ds, 0)
	String theList = ""
	i=0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		if ( (DimSize(w, 0) == numpoints) && (WaveType(w) & 6) )		// select floating-point waves with the right number of points
			theList += NameOfWave(w)+";"
		endif
		i += 1
	while (1)
	
	if (i == 0)
		return "None Available;"
	endif
	
	return theList
end

Function WeightWaveSelectionMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Wave/Z w = $popStr
	if (WaveExists(w))
		Wave/T WeightingListWave=root:Packages:GlobalFit:WeightingListWave
		ControlInfo/W=GlobalFitWeightingPanel WeightWaveListBox
		WeightingListWave[V_value][1] = GetWavesDatafolder(w, 2)
	endif
end

Function WeightClearSelectionButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z WeightingListWave=root:Packages:GlobalFit:WeightingListWave
	StrSwitch (ctrlName)
		case "WeightClearSelectionButton":
			ControlInfo/W=GlobalFitWeightingPanel WeightWaveListBox
			if (V_flag == 11)
				WeightingListWave[V_value][1] = ""
			else
				DoAlert 0, "BUG: couldn't access weight list box for Global Fit"
			endif
			break;
		case "WeightClearAllButton":
			WeightingListWave[][1] = ""
			break;
	endswitch
End

Function WeightsSDRadioProc(name,value)
	String name
	Variable value
	
	NVAR GlobalFit_WeightsAreSD= root:Packages:GlobalFit:GlobalFit_WeightsAreSD
	
	strswitch (name)
		case "WeightsSDRadio":
			GlobalFit_WeightsAreSD = 1
			break
		case "WeightsInvSDRadio":
			GlobalFit_WeightsAreSD = 0
			break
	endswitch
	CheckBox WeightsSDRadio, win=GlobalFitWeightingPanel, value= GlobalFit_WeightsAreSD==1
	CheckBox WeightsInvSDRadio, win=GlobalFitWeightingPanel, value= GlobalFit_WeightsAreSD==0
End

Function GlobalFitMakeWeightWave()

	Wave/T/Z WeightingListWave=root:Packages:GlobalFit:WeightingListWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets
	NVAR GlobalFit_WeightsAreSD= root:Packages:GlobalFit:GlobalFit_WeightsAreSD

	Variable totalPoints = 0
	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(WeightingListWave[i][1])
		if (WaveExists(w))
			totalPoints += numpnts(w)
		else
			totalPoints = 0
			DoAlert 0,"The weighting wave \""+WeightingListWave[i][1]+"\" does not exist."
			break
		endif
	endfor
	
	Variable startPnt = 0
	Variable endPnt = -1
	
	if (totalPoints)
		Make/O/D/N=(totalPoints) root:Packages:GlobalFit:GFWeightWave
		Wave GFWeightWave = root:Packages:GlobalFit:GFWeightWave
		for (i = 0; i < NumSets; i += 1)
			Wave/Z w = $(WeightingListWave[i][1])
			startPnt = endPnt+1
			endPnt = startPnt+numPnts(w)-1
			GFWeightWave[startPnt, endPnt] = w[p-startPnt]
		endfor
		if (GlobalFit_WeightsAreSD)
			GFWeightWave = 1/GFWeightWave
		endif
	endif
	
	return totalPoints
end

//***********************************
//
// Data masking
//
//***********************************

Function MaskingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	WAVE/T DataSetList=root:Packages:GlobalFit:DataSetList
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	if (checked)
		if (NumSets == 0)
			CheckBox MaskingCheckBox, win=GlobalFitPanel, value=0
			DoAlert 0, "You cannot add Masking waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:GlobalFit
			
			Wave/T/Z MaskingListWave
			if (!(WaveExists(MaskingListWave) && (DimSize(MaskingListWave, 0) == NumSets)))
				Make/O/N=(NumSets, 2)/T MaskingListWave=""
			endif
			MaskingListWave[][0] = DataSetList[p][0]
			Make/O/N=(NumSets, 2) MaskingSelectionWave
			MaskingSelectionWave[][0] = 0		// Data Sets
			MaskingSelectionWave[][1] = 0		// Masking Waves; not editable- select from menu
			SetDimLabel 1, 0, 'Data Set', MaskingListWave
			SetDimLabel 1, 1, 'Mask Wave', MaskingListWave
			
			SetDatafolder $saveDF
			
			if (WinType("GlobalFitMaskingPanel") > 0)
				DoWindow/F GlobalFitMaskingPanel
			else
				fGlobalFitMaskingPanel()
			endif
		endif
	else
		//not checked, remove cursors
		Cursor/K A
		Cursor/K B
		HideInfo
	endif	
end

Function fGlobalFitMaskingPanel() : Panel

	NewPanel /W=(339,193,745,408)
	DoWindow/C GlobalFitMaskingPanel
	AutoPositionWindow/M=1/E
	
	ListBox MaskWaveListBox,pos={9,63},size={387,112}, mode=2, listWave = root:Packages:GlobalFit:MaskingListWave
	ListBox MaskWaveListBox, selWave = root:Packages:GlobalFit:MaskingSelectionWave, frame=2
	Button GlobalFitMaskDoneButton,pos={24,186},size={50,20},proc=GlobalFitMaskDoneButtonProc,title="Done"
	Button GlobalFitMaskCancelButton,pos={331,186},size={50,20},proc=GlobalFitMaskCancelButtonProc,title="Cancel"
	PopupMenu GlobalFitMaskWaveMenu,pos={9,5},size={152,20},title="Select Mask Wave"
	PopupMenu GlobalFitMaskWaveMenu,mode=0,value= #"ListPossibleMaskWaves()", proc = MaskWaveSelectionMenu
	Button MaskClearSelectionButton,pos={276,5},size={120,20},proc=MaskClearSelectionButtonProc,title="Clear Selection"
	Button MaskClearAllButton,pos={296,32},size={100,20},proc=MaskClearSelectionButtonProc,title="Clear All"
	
	//SRK
	Button MaskFromCursorsButton,pos={150,32},size={135,20},proc=MaskFromCursorsButtonProc,title="Mask From Cursors"
	ListBox MaskWaveListBox,proc=MaskListBoxSelectionProc
	Button MaskShowInfoButton,pos={150,5},size={120,20},proc=MaskShowInfoButtonProc,title="Show Cursors"
EndMacro


Function GlobalFitMaskDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(MaskingListWave[i][1])
		if (!WaveExists(w))
			if (strlen(MaskingListWave[i][1]) != 0)
				ListBox MaskWaveListBox, win=GlobalFitMaskingPanel, selRow = i
				DoAlert 0, "The wave \""+MaskingListWave[i][1]+"\" does not exist."
				MaskingListWave[i][1] = ""
				return -1
			endif
		endif
	endfor
		
	DoWindow/K GlobalFitMaskingPanel
End

Function GlobalFitMaskCancelButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K GlobalFitMaskingPanel
	CheckBox MaskingCheckBox, win=GlobalFitPanel, value=0
End

Function/S ListPossibleMaskWaves()

	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	Wave/Z MaskingSelectionWave=root:Packages:GlobalFit:MaskingSelectionWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	String DataSetName=""
	Variable i
	
	ControlInfo/W=GlobalFitMaskingPanel MaskWaveListBox
	DataSetName = MaskingListWave[V_value][0]
	
	if (strlen(DataSetName) == 0)
		return "No Selection;"
	endif
	
	Wave/Z ds = $DataSetName
	if (!WaveExists(ds))
		return "Unknown Data Set;"
	endif
	
	Variable numpoints = DimSize(ds, 0)
	String theList = ""
	i=0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		if ( (DimSize(w, 0) == numpoints) && (WaveType(w) & 6) )		// select floating-point waves with the right number of points
			theList += NameOfWave(w)+";"
		endif
		i += 1
	while (1)
	
	if (i == 0)
		return "None Available;"
	endif
	
	return theList
end

Function MaskWaveSelectionMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Wave/Z w = $popStr
	if (WaveExists(w))
		Wave/T MaskingListWave=root:Packages:GlobalFit:MaskingListWave
		ControlInfo/W=GlobalFitMaskingPanel MaskWaveListBox
		MaskingListWave[V_value][1] = GetWavesDatafolder(w, 2)
	endif
end

Function MaskClearSelectionButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	StrSwitch (ctrlName)
		case "MaskClearSelectionButton":
			ControlInfo/W=GlobalFitMaskingPanel MaskWaveListBox
			if (V_flag == 11)
				MaskingListWave[V_value][1] = ""
			else
				DoAlert 0, "BUG: couldn't access Mask list box for Global Fit"
			endif
			break;
		case "MaskClearAllButton":
			MaskingListWave[][1] = ""
			break;
	endswitch
End

//SRK
// make a temporary masking wave from the selected data set
// and the cursor positions
//
Function MaskFromCursorsButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	
	String DataSetName=""
	ControlInfo/W=GlobalFitMaskingPanel MaskWaveListBox
	DataSetName = MaskingListWave[V_value][0]		//"root:yTraceName"
	Wave w = $DataSetName
	
	Duplicate/O $DataSetName,$(DataSetName+"mask")	//mask is in root: folder
	
	MaskingListWave[V_value][1] = DataSetName+"mask"
	
	Wave mm = $(DataSetName+"mask")
	mm=1		//mask nothing as the default
	
	//set the masking based on the cursors
	Make/O/N=2 csrPts
	csrPts[0] = xcsr(A)
	csrPts[1] = xcsr(B)
	Sort csrPts,csrPts		//pt[0] is smaller - guaranteed
	
	if(csrPts[0] > 0)
		mm[0,csrPts[0]-1] = 0
	endif
	if(csrPts[1] < (numpnts(mm)-1) )
		mm[csrPts[1]+1,numpnts(mm)-1] = 0
	endif
	
	Killwaves/Z csrPts	
End

//SRK
Function MaskShowInfoButtonProc(ctrlName) : ButtonControl
	String ctrlName
	ShowInfo		//topmost graph
	return(0)
End

//SRK
// based on the selected data set in the list box, put cursors
// on the proper data set, and put them at the right points
// if the masking wave exists
//
Function MaskListBoxSelectionProc(ctrlName,row,col,event)	// : ListboxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	
	String str=MaskingListWave[row][0]		//"root:yTraceName"
	Variable ptA=0,ptB=numpnts($(str[5,strlen(str)-1]))-1		//default to end points
	WAVE/Z mm = $(str+"mask")
	if(waveexists(mm))
		FindLevel/P/Q mm,1
		ptA = V_LevelX
		FindLevel/P/Q/R=[ptA] mm,0
		if(V_flag==0)
			ptB = V_LevelX-1		//level was found, use it. otherwise use default
		endif
	endif
	Cursor/P A, $(str[5,strlen(str)-1]),ptA
	Cursor/P B, $(str[5,strlen(str)-1]),ptB
	
	return 0            // other return values reserved
End


//used in DoTheFit() to create the long mask wave
// don't touch this
Function GlobalFitMakeMaskWave()

	Wave/T/Z MaskingListWave=root:Packages:GlobalFit:MaskingListWave
	NVAR NumSets= root:Packages:GlobalFit:NumSets

	Variable totalPoints = 0
	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(MaskingListWave[i][1])
		if (WaveExists(w))
			totalPoints += numpnts(w)
		elseif (strlen(MaskingListWave[i][1]) == 0)
			Wave/Z w = $(MaskingListWave[i][0])
			if (!WaveExists(w))
				totalPoints = 0
				DoAlert 0,"The data wave \""+MaskingListWave[i][0]+"\" does not exist, so it is impossible to finish the masking wave."
				break
			endif	
			totalPoints += numpnts(w)
		else
			totalPoints = 0
			DoAlert 0,"The Masking wave \""+MaskingListWave[i][1]+"\" does not exist."
			break
		endif
	endfor
	
	Variable startPnt = 0
	Variable endPnt = -1
	
	if (totalPoints)
		Make/O/D/N=(totalPoints) root:Packages:GlobalFit:GFMaskWave
		Wave GFMaskWave = root:Packages:GlobalFit:GFMaskWave
		for (i = 0; i < NumSets; i += 1)
			Wave/Z w = $(MaskingListWave[i][1])
			if (!WaveExists(w))
				Wave/Z w = $(MaskingListWave[i][0])
				startPnt = endPnt+1
				endPnt = startPnt+numPnts(w)-1
				GFMaskWave[startPnt, endPnt] = 1	// no mask wave selected for this data set, set masking to all 1's
			else
				startPnt = endPnt+1
				endPnt = startPnt+numPnts(w)-1
				GFMaskWave[startPnt, endPnt] = w[p-startPnt]
			endif
		endfor
	endif
	
	return totalPoints
end

//	ConcatenateResolWavesInList(dest, wl)
//		Makes a dest wave that is the concatenation of the source waves.
//		Overwrites the dest wave if it already exists.
//		wl is assumed to contain at least one wave name.
//		This is designed for 1D waves only.
//
// SRK 2004 - simply changed name from WM code to avoid name conflict
Function ConcatenateResolWavesInList(dest, wl)
	String dest		// name of output wave
	String wl		// semicolon separated list of waves ("w0;w1;w2;")
	
	Variable i					// for walking through wavelist
	String theWaveName
	Variable destExisted
	
	destExisted = Exists(dest)
	if (destExisted)
		Redimension/N=0 $dest
	endif
	
	i = 0
	do
		theWaveName = StringFromList(i,wl)
		if (strlen(theWaveName) == 0)
			break										// no more waves
		endif
		if (cmpstr(theWaveName, dest) != 0)		// don't concat dest wave with itself
			ConcatenateResolWaves(dest, theWaveName)
		endif
		i += 1
	while (1)
End

//	ConcatenateResolWaves(w1, w2)
//		Tacks the contents of w2 on the to end of w1.
//		If w1 does not exist, it is created.
//		This is designed for 1D waves only.
Function ConcatenateResolWaves(w1, w2)
	String w1, w2
	
	Variable numPoints1, numPoints2

	if (Exists(w1) == 0)
		Duplicate $w2, $w1
	else
		String wInfo=WaveInfo($w2, 0)
		Variable WType=NumberByKey("NUMTYPE", wInfo)
		numPoints1 = numpnts($w1)
		numPoints2 = numpnts($w2)
		Redimension/N=(numPoints1 + numPoints2) $w1
		if (WType)				// Numeric wave
			Wave/C/D ww1=$w1
			Wave/C/D ww2=$w2
			ww1[numPoints1, ] = ww2[p-numPoints1]
		else						// Text wave
			Wave/T tw1=$w1
			Wave/T tw2=$w2
			tw1[numPoints1, ] = tw2[p-numPoints1]
		endif
	endif
End

// function to scan through xw and remove
// duplicate points (y1,y2,y3) are also trimmed
// specifically used for x=Qvals and y1,y2,y3 are the resolution waves
//
// comparison for "==" could be more sophisticated, but 
// if they don't equate, interp should still be happy
//
Function RemoveDuplicatePts(xw,y1,y2,y3)
	Wave xw,y1,y2,y3
	
	Variable npt,ii,cur,next
	
	npt=numpnts(xw)
	
	ii=0
	do
		cur=xw[ii]
		next=xw[ii+1]
		if(cur==next)
			do
				DeletePoints ii+1, 1, xw,y1,y2,y3
				npt-=1
				next=xw[ii+1]
			while(cur==next && ii < npt-1)
		endif
		ii+=1
	while(ii<npt-1)
	
	return(0)
End

//w0 is original
//w1 is returned after trimming
//mw is the masking wave (==0 if point is masked)
Function RemoveMaskedXPoints(w0,w1,mw)
	Wave w0,w1,mw
	
	Variable npt = numpnts(w0),ii
	Duplicate/O w0,tempW0		//don't mess with the originals of these
	Duplicate/O mw,tempMw		
	ii=0
	do
		if(tempMw[ii]==0)
			DeletePoints ii, 1, tempW0,w1,tempMW
			npt-=1
		else
			ii+=1
		endif
	while(ii<npt)
	Killwaves/Z tempMw,tempW0
	
	return(0)
end

Function GF_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic "Global Curve Fitting of SANS Data"
End