#pragma rtGlobals=1		// Use modern global access method.


// panel meant to make it easier to fit two data sets with a single model
// typically (but not necessarily) U+S, resolution smeared
//
// Uses a lot of the functionality from the Wrapper Panel - so be careful
// if the behavior of that panel changes - especially the popup menus
//
// currently unsupported:
// mask
// constraints
// epsilon (used, set behind the scenes but is not user-settable)
//
// ** some of the other assumptions/behaviors are:
// - if a global variable is held by one set, it is (must be) held for the other set
//   even though I don't automatically check the other box
// - global parameter values are set from SET A. values in set B are overwritten during
//   the fit
// - upon initialization of the coefficients, coef_A and coef_B are set to those from the 
//   first data set (A). So the appropriate model must be plotted for set A. It does not
//   need to be plotted for set B, although if you fit the sets separately, each fit can 
//   be used as a good first guess for the global fitting by cut/pase into the table.
// - reports are always generated and automatically saved. Beware overwriting.
// - weighting waves are automatically selected, as usual, since I know the data sets
// - both data sets should be on the top graph. The fit, when finished, will try to append
//   the results of the fit on the top graph.
//
// SRK FEB 2009 

// these waves feed the WM NewGlobalFit package, and must have the proper
// names, locations, *and* dimLabels to work properly. But then it can be run
// through all of the same machinery.

//	Make/O/T/N=(numDataSets) root:Packages:NewGlobalFit:NewGF_FitFuncNames = ""
//	Wave/T FitFuncNames = root:Packages:NewGlobalFit:NewGF_FitFuncNames

//Make/O/T/N=(numDataSets, 2) root:Packages:NewGlobalFit:NewGF_DataSetsList
//	Wave/T DataSets = root:Packages:NewGlobalFit:NewGF_DataSetsList

//	Make/N=(numDataSets, numLinkageCols)/O root:Packages:NewGlobalFit:NewGF_LinkageMatrix
//	Wave LinkageMatrix = root:Packages:NewGlobalFit:NewGF_LinkageMatrix

//	Make/O/D/N=(nRealCoefs, 3) root:Packages:NewGlobalFit:NewGF_CoefWave
//	Wave coefWave = root:Packages:NewGlobalFit:NewGF_CoefWave
//	SetDimLabel 1,1,Hold,coefWave
//	SetDimLabel 1,2,Epsilon,coefWave
//	Make/O/T/N=(nRealCoefs) root:Packages:NewGlobalFit:NewGF_CoefficientNames
//	Wave/T CoefNames = root:Packages:NewGlobalFit:NewGF_CoefficientNames	

//Wave/T/Z ConstraintWave = root:Packages:NewGlobalFit:GFUI_GlobalFitConstraintWave
// or $""


 
Proc OpenSimpleGlobalFit()
	Init_SimpleGlobalFit()
End

Menu "SANS Models"
//	"Global Fit", InitGlobalFitPanel()
	Submenu "Packages"
		"Unload Simple Global Fit",  UnloadSimpleGlobalFit()
	End
end

Function Init_SimpleGlobalFit()
	//make sure that folders exist - this is the first initialization to be called
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NewGlobalFit
	
	DoWindow/F SimpGFPanel
	if(V_flag==0)
		SetDataFolder root:Packages:NewGlobalFit
		// create waves for the list box, or for the embedded table?
		Make/O/T/N=(10,4) listW
		Make/O/B/N=(10,4) selW
		Make/O/T/N=4 titles
		titles[0] = "Coef #"
		titles[1] = "Global?"
		titles[2] = "Hold for Set A?"
		titles[3] = "Hold for Set B?"
		
		listW[][0] = num2str(p)
		selW[][0] = 0
		selW[][1] = 2^5		// column is a checkbox
		selW[][2] = 2^5
		selW[][3] = 2^5
		
		Execute "SimpGFPanel()"
		setDataFolder root:
	endif
End

Window SimpGFPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel/W=(689,526,1318,1035)/K=1/N=SimpGFPanel as "Simple Global Fit Setup"
	ModifyPanel cbRGB=(65535,65534,49151)
	
	GroupBox grpBox_0,pos={18,11},size={310,129}

	PopupMenu popup_0a,pos={30,21},size={218,20},title="Data Set A "
	PopupMenu popup_0a,mode=1,value= #"W_DataSetPopupList()"
	PopupMenu popup_0b,pos={30,49},size={218,20},title="Data Set B "
	PopupMenu popup_0b,mode=1,value= #"W_DataSetPopupList()"
	PopupMenu popup_1,pos={30,80},size={136,20},title="Function"
	PopupMenu popup_1,mode=1,value= #"W_FunctionPopupList()"
	PopupMenu popup_2,pos={30,110},size={123,20},title="Coefficients"
	PopupMenu popup_2,mode=1,value= #"SGF_CoefPopupList()",proc=SGF_CoefPopMenuProc
	ListBox list0,pos={355,195},size={260,288},listWave=root:Packages:NewGlobalFit:listW
	ListBox list0 selWave=root:Packages:NewGlobalFit:selW,proc=SGF_ListBoxProc
	ListBox list0 titleWave=root:Packages:NewGlobalFit:titles//,userColumnResize=1
	ListBox list0 widths={30,50,80,80}
	
	Button button_0,pos={344,13},size={100,20},title="Do The Fit"
	Button button_0 proc=SGF_DoFitButtonProc
	Button button_1,pos={369,173},size={50,20},proc=SaveCheckStateButtonProc,title="Save"
	Button button_2,pos={429,173},size={70,20},proc=RestoreCheckStateButtonProc,title="Restore"
	Button button_3,pos={500,13},size={100,20},proc=SGFitHelpButtonProc,title="Help"
	
	Edit/W=(14,174,348,495)/HOST=# 
	ModifyTable format(Point)=1,width(Point)=34
	RenameWindow #,T0
	SetActiveSubwindow ##
	
EndMacro

//open the Help file for the Simple Global Fit
Function SGFitHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Simple Global Fit"
			if(V_flag !=0)
				DoAlert 0,"The Simple Global Fit Help file could not be found"
			endif
			break
	endswitch

	return 0
End


// save the state of the checkboxes
Function SaveCheckStateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Duplicate/O root:Packages:NewGlobalFit:selW, root:Packages:NewGlobalFit:selW_saved
			break
	endswitch

	return 0
End

//restore the state of the checkboxes if the number of rows is correct
Function RestoreCheckStateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Wave sw_cur = root:Packages:NewGlobalFit:selW
			Wave sw_sav = root:Packages:NewGlobalFit:selW_saved

			Variable num_cur,num_sav
			num_cur = DimSize(sw_cur,0)
			num_sav = DimSize(sw_sav,0)

			if(num_cur == num_sav)
				sw_cur = sw_sav
			endif
			
			break
	endswitch

	return 0
End




// show the appropriate coefficient waves
// 
// also need to search the folder listed in "data set" popup
// for smeared coefs
//
// - or - restrict the coefficient list based on the model function
// - new way, filter the possible values based on the data folder and function
Function/S SGF_CoefPopupList()

	String notPlotted="Please plot the function"
	ControlInfo/W=SimpGFPanel popup_1
	String funcStr=S_Value
	String coefStr=getFunctionCoef(funcStr)
	
	if(cmpstr(coefStr,"")==0)		//no correspondence in the KW string
		return(notPlotted)
	endif
	
	
	//found a coefficient wave - only two places to look
	// is it in the root folder?
	if(exists("root:"+coefStr) != 0)
		return(coefStr)
	endif
	
	// is it in the data folder? (this only checks "a")
	ControlInfo/W=SimpGFPanel popup_0a
	String folderStr=S_Value
	if(exists("root:"+folderStr+":"+coefStr) != 0)
		return(coefStr)
	endif

	return(notPlotted)
End

Function SGF_CoefPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			//////
			String suffix = getModelSuffix(popStr)
			ControlInfo/W=SimpGFPanel popup_0a
			String folderStr_a=S_Value
			
			ControlInfo/W=SimpGFPanel popup_0b
			String folderStr_b=S_Value
			
			if(cmpstr(popStr,"Please plot the function")==0)
//				Print "function not plotted"
				return(0)
			endif

// this if/else/endif should not ever return an error alert	
// it should simply set the data folder properly
//
// !! works only with folder/set A	
			if(DataFolderExists("root:"+folderStr_a))
				SetDataFolder $("root:"+folderStr_a)
				if(!exists(popStr))
					// must be unsmeared model, work in the root folder
					SetDataFolder root:				
					if(!exists(popStr))		//this should be fine if the coef filter is working, but check anyhow
						DoAlert 0,"the coefficient and data sets do not match (1)"
						return 0
					endif
				endif
			else
				// must be unsmeared model, work in the root folder
				SetDataFolder root:	
				if(!exists(popStr))		//this should be fine if the coef filter is working, but check anyhow
					DoAlert 0,"the coefficient and data sets do not match (2)"
					return 0
				endif
			endif
//			
			// farm the work out to another function?
			Variable num=numpnts($popStr)
			// make the necessary waves, overwriting anything that exists?
			
// duplicate the coefficient waves, A/B
			Duplicate/O $(popStr) root:Packages:NewGlobalFit:coef_A,root:Packages:NewGlobalFit:coef_B
			Wave coef_A = root:Packages:NewGlobalFit:coef_A
			Wave coef_B = root:Packages:NewGlobalFit:coef_B
			
			if(exists("Hold_"+suffix) == 0)
				Make/O/D/N=(num) $("epsilon_"+suffix),$("Hold_"+suffix)
				Make/O/T/N=(num) $("LoLim_"+suffix),$("HiLim_"+suffix)
				Wave eps = $("epsilon_"+suffix)
				Wave coef=$popStr
				if(eps[0] == 0)		//if eps already if filled, don't change it
					eps = abs(coef*1e-4) + 1e-10			//default eps is proportional to the coefficients
				endif
			endif
			// default epsilon values, sometimes needed for the fit
			
			WAVE/T LoLim = $("LoLim_"+suffix)
			WAVE/T HiLim = $("HiLim_"+suffix)
			
			// clear the table (a subwindow)
			DoWindow/F SimpGFPanel				// ?? had to add this in during all of the cursor meddling...
			KillWindow SimpGFPanel#T0
			Edit/W=(14,174,348,495)/HOST=SimpGFPanel
			RenameWindow #,T0
			// get them onto the table
			// how do I get the parameter name?
			String param = WaveList("*parameters_"+suffix, "", "TEXT:1," )		//this is *hopefully* one wave
			AppendtoTable/W=SimpGFPanel#T0 $param
			AppendToTable/W=SimpGFPanel#T0 coef_A,coef_B
//			AppendToTable/W=SimpGFPanel#T0 $("Hold_"+suffix),$("LoLim_"+suffix),$("HiLim_"+suffix),$("epsilon_"+suffix)
			ModifyTable/W=SimpGFPanel#T0 width(Point)=34
			
			SetDataFolder root:
			
// resize the list boxes based on the number of coefficients			
			WAVE/T lw=root:Packages:NewGlobalFit:listW
			WAVE sw=root:Packages:NewGlobalFit:selW
			Redimension/N=(num,4) lw
			Redimension/N=(num,4) sw
			lw[][0] = num2str(p)
			sw[][0] = 0
			sw[][1] = 2^5		// column is a checkbox
			sw[][2] = 2^5
			sw[][3] = 2^5
			///////
			
			
			break
	endswitch

	return 0
End

// tricky logic here - to make sure that selections are all in-sync and the coefficients too.
//
// maybe better to not do anything here, just update states after parsing the details of the selections
//
// bit 4 (0x10) is checkbox state
Function SGF_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	//Print "event code = ",lba.eventCode

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1:	//mouse down
			//if( (selWave[row][col] & 0x10) != 0)			//test here is BEFORE the state changes
			//	Print "row,col is checked ",row,col
			//endif 
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
	endswitch

	return 0
End

// first, it must parse everything for "OK-ness"
// then construct the waves that GlobalFit needs
// then dispatch
// then do something with the results
//
Function SGF_DoFitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable err=0
	switch( ba.eventCode )
		case 2: // mouse up
			// parse
			err = ParseSGFPanel()
			if(err)
				Print "Parse Error"
				break
			endif
			
			//wave construct (Waves exist if no parse errors)
			WAVE/T FitFuncNames = root:Packages:NewGlobalFit:NewGF_FitFuncNames
			Wave/T DataSets = root:Packages:NewGlobalFit:NewGF_DataSetsList
			Wave CoefDataSetLinkage = root:Packages:NewGlobalFit:NewGF_LinkageMatrix
			WAVE CoefWave = root:Packages:NewGlobalFit:NewGF_CoefWave
			
			//dispatch
			Variable options=105		//=64+32+16+1
			Variable FitCurvePoints = 200
			Variable DoAlertsOnError = 1
			
			err = DoNewGlobalFit(FitFuncNames, DataSets, CoefDataSetLinkage, CoefWave, $"", $"", Options, FitCurvePoints, DoAlertsOnError)
			//post-process results
			//Print "err = ",err
			// put results back into coef_a and coef_b
			UpdateSGFCoefs(CoefWave)
						
			break
	endswitch

	return 0
End

// parse the panel and generate the necessary waves
//
Function ParseSGFPanel()

	Variable err=0
	SetDataFolder root:Packages:NewGlobalFit
	
//////Fitfunc names
	ControlInfo/W=SimpGFPanel popup_1
	String funcStr=S_Value
	Make/O/T/N=1 NewGF_FitFuncNames
	WAVE/T FitFuncNames = NewGF_FitFuncNames
	FitFuncNames[0] = funcStr
	
////// data sets
	ControlInfo/W=SimpGFPanel popup_2
	String popStr=S_Value
	String suffix = getModelSuffix(popStr)

	
	ControlInfo/W=SimpGFPanel popup_0a
	String folderStr_a=S_Value
	
	ControlInfo/W=SimpGFPanel popup_0b
	String folderStr_b=S_Value
	Make/O/T/N=(2,4) NewGF_DataSetsList
	Wave/T DataSets = NewGF_DataSetsList
	// full paths to the waves
	DataSets[0][0] = "root:"+folderStr_a+":"+folderStr_a + "_i"
	DataSets[1][0] = "root:"+folderStr_b+":"+folderStr_b + "_i"
	DataSets[0][1] = "root:"+folderStr_a+":"+folderStr_a + "_q"
	DataSets[1][1] = "root:"+folderStr_b+":"+folderStr_b + "_q"
	DataSets[0][2] = "root:"+folderStr_a+":"+folderStr_a + "_s"
	DataSets[1][2] = "root:"+folderStr_b+":"+folderStr_b + "_s"
	SetDimLabel 1, 2, Weights, DataSets
// column [3] is the mask wave, not supported here
	DataSets[0][3] = ""
	DataSets[1][3] = ""
	
////// coefficient linkage matrix
	Wave coef_A = coef_A
	Wave coef_b = coef_b
	Variable nc = numpnts(coef_A)
	
	Make/O/D/N=(2,nc+4) NewGF_LinkageMatrix
	Wave CoefDataSetLinkage = NewGF_LinkageMatrix

	WAVE selW = selW
	Variable nRealCoefs = 0		// accumulates the number of independent coefficients (that is, non-link coefficients)
	Variable ii,jj,numDataSets=2
	
	CoefDataSetLinkage[0][0] = 0		//function number, same for both
	CoefDataSetLinkage[1][0] = 0
	CoefDataSetLinkage[0][1] = 0		//first/last data pt numbers, set to zero on input
	CoefDataSetLinkage[1][1] = 0		//first/last data pt numbers, set to zero on input
	CoefDataSetLinkage[0][2] = 0		//first/last data pt numbers, set to zero on input
	CoefDataSetLinkage[1][2] = 0		//first/last data pt numbers, set to zero on input
	CoefDataSetLinkage[0][3] = nc		//number of coefficients
	CoefDataSetLinkage[1][3] = nc		//number of coefficients
	
	//loop through coefs for first data set [0][]
	// ! everything hits here - all coefficients are used...
	Variable offset=4
	for(ii=0;ii < nc; ii+=1)
		CoefDataSetLinkage[0][ii+offset] = ii		
	endfor
	nRealCoefs = nc
	// now 2nd data set may have some links
	for(ii=0;ii < nc; ii+=1)
		if (selW[ii][1] & 0x10)		//global coefficient
			CoefDataSetLinkage[1][ii+offset] = ii
		else
			CoefDataSetLinkage[1][ii+offset] = nRealCoefs
			nRealCoefs +=1
		endif
	endfor
	
//// Cumulative coefficient wave and coefficient names
// coefficient wave also contains hold[][1] and epsilon[][2]
// do nothing with epsilon right now

	Make/O/T/N=(nRealCoefs) NewGF_CoefficientNames=""
	Make/O/D/N=(nRealCoefs,3) NewGF_CoefWave=0
	Wave coefWave = NewGF_CoefWave
	Wave/T CoefNames = NewGF_CoefficientNames
	SetDimLabel 1,1,Hold,coefWave
//	SetDimLabel 1,2,Epsilon,coefWave

	
//	String param = WaveList("*parameters_"+suffix, "", "TEXT:1," )		//this is *hopefully* one wave
//	print "Param = ",param
	
	// take the global values from the coef_A wave
	for(ii=0;ii < nc; ii+=1)
		CoefWave[ii][0] = coef_a[ii]
		if(selW[ii][2] & 0x10)		//held
			coefWave[ii][1] = 1
		endif
//		CoefNames[ii] = 		
	endfor
	// now 2nd data set may have some links
	for(ii=0;ii < nc; ii+=1)
		if (coefDataSetLinkage[0][ii+offset] == CoefDataSetLinkage[1][ii+offset])		//global coefficient
			//do nothing to set the coefficients
		else
			CoefWave[CoefDataSetLinkage[1][ii+offset]][0] = coef_b[ii]			//take non-global value from b
		endif
		if(selW[ii][3] & 0x10)		//global held, "b" checked
			coefWave[CoefDataSetLinkage[1][ii+offset]][1] = 1
		endif
	endfor

//// constraint wave is not currently supported


//// that's all of the waves

	setDataFolder root:
	
	return(err)
end

Function UpdateSGFCoefs(CoefWave)
	Wave CoefWave
	
	SetDataFolder root:Packages:NewGlobalFit
	Wave coef_a=coef_a
	Wave coef_b=coef_b
	Variable nc = numpnts(coef_A)
	Variable nTotal = DimSize(CoefWave, 0)
	
	Wave CoefDataSetLinkage=NewGF_LinkageMatrix
	//loop through coefs for first data set [0][]
	// ! everything hits here - all coefficients are used...
	Variable ii,offset=4,index
	for(ii=0;ii < nc; ii+=1)
		coef_a[ii] = CoefWave[ii][0]	
	endfor
	// now 2nd data set may have some duplicates from globals
	for(ii=0;ii < nc; ii+=1)
		index = CoefDataSetLinkage[1][ii+offset]
		coef_b[ii] = coefWave[index][0]
	endfor
	
	SetDataFolder root:
	return(0)
End

// clean up after itself, don't kill any data folder
Function UnloadSimpleGlobalFit()
	if (WinType("SimpGFPanel") == 7)
		DoWindow/K SimpGFPanel
	endif
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif

	SVAR fileVerExt=root:Packages:NIST:SANS_ANA_EXTENSION
	String fname="SimpleGlobalFit_NCNR"
	Execute/P "DELETEINCLUDE \""+fname+fileVerExt+"\""
	Execute/P "COMPILEPROCEDURES "
	KillWaves/Z root:Packages:NewGlobalFit:listW
	KillWaves/Z root:Packages:NewGlobalFit:selW
	KillWaves/Z root:Packages:NewGlobalFit:titles
	
//	KillDataFolder/Z root:Packages:NewGlobalFit
	
	
end