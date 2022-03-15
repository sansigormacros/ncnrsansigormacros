#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.10
#pragma IgorVersion=6.1


// this is the flag for the relative error = W_sigma/coef that will
// trip the bold/red color of W_sigma in the table.
//
Constant kRelErrorTolerance=0.5

//Macro OpenWrapperPanel()
//	Init_WrapperPanel()
//End

Function Init_WrapperPanel()

	if(itemsinlist(WinList("SA_includes_v400.ipf", ";","INCLUDE:6"),";") != 0)
		//must be opening a v4.00 or earlier template
		DoAlert 0,"This experiment was created with an old version (v4.0) of the macros. I'll try to make this work, but please start new work with a current version"
	endif
	
	//make sure that folders exist - this is the first initialization to be called
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST

	//Create useful globals
	Variable/G root:Packages:NIST:SANS_ANA_VERSION=4.10
	String/G root:Packages:NIST:SANS_ANA_EXTENSION="_v40"
	//Set this variable to 1 to force use of trapezoidal integration routine for USANS smearing
	Variable/G root:Packages:NIST:USANSUseTrap = 0
	Variable/G root:Packages:NIST:USANS_dQv = 0.117
	Variable/G root:Packages:NIST:gUseGenCurveFit = 0			//set to 1 to use genetic optimization
			
	//Ugly. Put this here to make sure things don't break
	String/G root:Packages:NIST:gXMLLoader_Title
	
	
	//initializes preferences. this includes XML y/n, and SANS Reduction items. 
	// if they already exist, they won't be overwritten
	Execute "Initialize_Preferences()"		
	
	DoWindow/F WrapperPanel
	if(V_flag==0)
		if(exists("root:Packages:NIST:coefKWStr")==0)
			String/G root:Packages:NIST:coefKWStr=""
		endif
		if(exists("root:Packages:NIST:suffixKWStr")==0)
			String/G root:Packages:NIST:suffixKWStr=""
		endif
		if(exists("root:Packages:NIST:paramKWStr")==0)
			String/G root:Packages:NIST:paramKWStr=""
		endif
		Execute "WrapperPanel()"
	endif
End

////////
//
// if model is Smeared, search the DF for coefficients
// if new DF chosen, need to reset
// if new model function, need to reset table
//
// create hold_mod (0/1), constr_low_mod, constr_hi_mod
// in either DF (smeared) or in root: (normal)
// and put these in the table as needed
//
Window WrapperPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(459,44,1113,499)/N=wrapperPanel/K=1 as "Curve Fit Setup"
	ModifyPanel fixedSize=1
	
	GroupBox grpBox_0,pos={18,11},size={390,113}
	GroupBox grpBox_1,pos={426,10},size={207,113}
	GroupBox grpBox_2 title="No Fit",pos={10,130},size={0,0},frame=1,fSize=10,fstyle=1,fColor=(39321,1,1)
	GroupBox grpBox_3 title="",pos={10,150},size={0,0},frame=1,fSize=10,fstyle=1,fColor=(39321,1,1)

	Button button_1,pos={280,57},size={120,20},proc=PlotModelFunction,title="Plot 1D Function"
	Button button_2,pos={300,93},size={100,20},proc=AppendModelToTarget,title="Append 1D"
	Button button_3,pos={300,20},size={100,20},proc=W_LoadDataButtonProc,title="Load 1D Data"
	PopupMenu popup_0,pos={30,21},size={218,20},title="Data Set",proc=DataSet_PopMenuProc
	PopupMenu popup_0,mode=1,value= #"W_DataSetPopupList()"
	PopupMenu popup_1,pos={30,57},size={136,20},title="Function"
	PopupMenu popup_1,mode=1,value= #"W_FunctionPopupList()",proc=Function_PopMenuProc
	PopupMenu popup_2,pos={30,93},size={123,20},title="Coefficients"
	PopupMenu popup_2,mode=1,value= #"W_CoefPopupList()",proc=Coef_PopMenuProc
	CheckBox check_0,pos={430,19},size={79,14},title="Use Cursors?",value= 0
	CheckBox check_0,proc=UseCursorsWrapperProc
	CheckBox check_1,pos={430,42},size={74,14},title="Use Epsilon?",value= 0
	CheckBox check_2,pos={430,65},size={95,14},title="Use Constraints?",value= 0
	CheckBox check_3,pos={530,18},size={72,14},title="2D Functions?",value= 0
	CheckBox check_3 proc=Toggle2DControlsCheckProc
	CheckBox check_4,pos={430,85},size={72,14},title="Report?",value= 0
	CheckBox check_5,pos={444,103},size={72,14},title="Save it?",value= 0
	CheckBox check_6,pos={530,38},size={72,14},title="Use Residuals?",value= 0
	CheckBox check_6,proc=UseResidualsCheckProc
	CheckBox check_7,pos={530,57},size={72,14},title="Info Box?",value= 0
	CheckBox check_7,proc=UseInfoTextBoxCheckProc
	CheckBox check_8, pos={530,75}, size={72,14}, title="Rescale Axis?", value=0
	CheckBox check_8,proc=UseRescaleAxisCheckProc
	//change draw order to put button over text of checkbox
	Button button_0,pos={520,93},size={100,20},proc=DoTheFitButton,title="Do 1D Fit"
	Button button_4,pos={520,126},size={100,20},proc=FeedbackButtonProc,title="Feedback"
	Button button_5,pos={520,150},size={100,20},proc=FitHelpButtonProc,title="Help"

	Edit/W=(20,174,634,435)/HOST=#  
	ModifyTable width(Point)=0
	RenameWindow #,T0
	SetActiveSubwindow ##
EndMacro

//open the Help file for the Fit Manager
Function FitHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Fit Manager"
			if(V_flag !=0)
				DoAlert 0,"The Fit Manager Help file could not be found"
			endif
			break
	endswitch

	return 0
End


//open the trac page for feedback
Function FeedbackButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			OpenTracTicketPage()
			break
	endswitch

	return 0
End


//obvious use, now finds the most recent data loaded, finds the folder, and pops the menu with that selection...
//
Function W_LoadDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String	topGraph= WinName(0,1)
			if(strlen(topGraph) != 0)
				DoWindow/F $topGraph			//so that the panel is not on top
			endif
			Execute "A_LoadOneDData()"
			
			ControlUpdate/W=WrapperPanel popup_0
			//instead of a simple controlUpdate, better to pop the menu to make sure that the other menus follow
			// convoluted method to find the right item and pop the menu.

			// data is plotted, so get the "new" top graph
			topGraph= WinName(0,1)	//this is the topmost graph, and should exist, but...
			if(cmpstr(topGraph,"")==0)
				return(0)
			endif
			String list,folderStr
			Variable num
			list = TraceNameList(topGraph,";",1)		//want the last item in the list
			num= ItemsInList(list)
			FolderStr = StringFromList(num-1,list,";")
			folderStr = folderStr[0,strlen(folderStr)-3]		//remove the "_i" that the loader enforced
			list = W_DataSetPopupList()
			num=WhichListItem(folderStr,list,";",0,0)
			if(num != -1)
				PopupMenu popup_0,mode=num+1,win=WrapperPanel
				ControlUpdate/W=WrapperPanel popup_0
				
				// fake mouse up to pop the menu
				Struct WMPopupAction ps
				ps.eventCode = 2		//fake mouse up
				DataSet_PopMenuProc(ps)
			endif
			break
	endswitch
	
	return 0
End


// is there a simpler way to do this? I don't think so.
Function/S W_DataSetPopupList()

	String str=GetAList(4)

	if(strlen(str)==0)
		str = "No data loaded"
	endif
	str = SortList(str)
	
	return(str)
End


// show the available models
// not the f*(cw,xw) point calculations
// not the *X(cw,xw) XOPS
//
// KIND:10 should show only user-defined curve fitting functions
// - not XOPs
// - not other user-defined functions
Function/S W_FunctionPopupList()
	String list,tmp
	//get every user defined curve fit function, remove everything the user doesn't need to see...
	list = User_FunctionPopupList()		

	if(strlen(list)==0)
		list = "No functions plotted"
	endif
	
	list = SortList(list)
	return(list)
End


// show all the appropriate coefficient waves
// 
// also need to search the folder listed in "data set" popup
// for smeared coefs
//
// - or - restrict the coefficient list based on the model function
// - new way, filter the possible values based on the data folder and function
Function/S W_CoefPopupList()

	String notPlotted="Please plot the function"
	ControlInfo/W=wrapperpanel popup_1
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
	
	// is it in the data folder?
	ControlInfo/W=wrapperpanel popup_0
	String folderStr=S_Value
	if(exists("root:"+folderStr+":"+coefStr) != 0)
		return(coefStr)
	endif

	return(notPlotted)
End

// show all the appropriate coefficient waves
// 
// also need to search the folder listed in "data set" popup
// for smeared coefs
//
// - or - restrict the coefficient list based on the model function
//
// --old way
//Function/S W_CoefPopupList()
//	String list
//	setDataFolder root:
//	list = WaveList("coef*",";","")
//	
//	ControlInfo/W=wrapperpanel popup_0
//	if(V_Value != 0)		//0== no items in menu
//		if(DataFolderExists("root:"+S_Value))
//			SetDataFolder $("root:"+S_Value)
//			list += WaveList("*coef*",";","")
//		endif
//	endif
//	
//	// tmp coefficients that aren't being cleaned up from somewhere...
//	list = RemoveFromList("temp_coef_1;temp_coef_2;", list  ,";")
//
//	if(strlen(list)==0)
//		list = "No functions plotted"
//	endif
//	list = SortList(list)
//	
////	Print itemsinlist(list,";")
//	
//	setDataFolder root:
//	return(list)
//End

// if the coefficients are changed, then update the table
//
//update the table
// may be easier to just kill the subwindow (table) and create a new one
// need to set/reset all of the waves in the table
//
// !! only respond to mouse up
//
Function Coef_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			ControlInfo/W=WrapperPanel popup_1
			String funcStr=S_Value
			String suffix = getModelSuffix(funcStr)
			ControlInfo/W=WrapperPanel popup_0
			String folderStr=S_Value
			
			if(cmpstr(popStr,"Please plot the function")==0)
//				Print "function not plotted"
				return(0)
			endif

// this if/else/endif should not ever return an error alert	
// it should simply set the data folder properly	
			if(DataFolderExists("root:"+folderStr))
				SetDataFolder $("root:"+folderStr)
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
			
			// farm the work out to another function?
			Variable num=numpnts($popStr)
			// make the necessary waves if they don't exist already
			if(exists("Hold_"+suffix) == 0)
				Make/O/D/N=(num) $("Hold_"+suffix)
			endif
			if(exists("epsilon_"+suffix) == 0)
				Make/O/D/N=(num) $("epsilon_"+suffix)
			endif
			if(exists("LoLim_"+suffix) == 0)
				Make/O/T/N=(num) $("LoLim_"+suffix)
			endif
			if(exists("HiLim_"+suffix) == 0)
				Make/O/T/N=(num) $("HiLim_"+suffix)
			endif
						
			Wave eps = $("epsilon_"+suffix)
			Wave coef=$popStr
			if(eps[0] == 0)		//if eps already if filled, don't change it
				eps = abs(coef*1e-4) + 1e-10			//default eps is proportional to the coefficients
			endif
			
			// default epsilon values, sometimes needed for the fit
			
			WAVE/T LoLim = $("LoLim_"+suffix)
			WAVE/T HiLim = $("HiLim_"+suffix)
			
			// clear the table (a subwindow)
			DoWindow/F WrapperPanel				// ?? had to add this in during all of the cursor meddling...
			KillWindow wrapperPanel#T0
			Edit/W=(20,174,634,435)/HOST=wrapperPanel
			RenameWindow #,T0
			// get them onto the table
			// how do I get the parameter name?
			String param = getFunctionParams(funcStr)
			AppendtoTable/W=wrapperPanel#T0 $param,$(popStr)
			AppendToTable/W=wrapperPanel#T0 $("Hold_"+suffix),$("LoLim_"+suffix),$("HiLim_"+suffix),$("epsilon_"+suffix)
			ModifyTable/W=wrapperPanel#T0 width(Point)=0
			
			SetDataFolder root:
			break
	endswitch

	return 0
End

// if the Function is changed, then update the coef popup (if possible) and then the table (if possible)
//
// !! only respond to mouse up
//
Function Function_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String funcStr = pa.popStr
			String coefStr = W_CoefPopupList()
			
//			Print "coefStr = ",coefStr
			
			ControlInfo/W=WrapperPanel popup_0
			String folderStr=S_Value
			
			String listStr = W_CoefPopupList()
			Variable num=WhichListItem(coefStr, listStr, ";")
			String str=StringFromList(num, listStr  ,";")
//			print "str = ",str
			//set the item in the coef popup, and pop it
			PopupMenu popup_2 win=WrapperPanel,mode=(num+1)
			
			Struct WMPopupAction ps
			ps.eventCode = 2		//fake mouse up
			ps.popStr = str
			Coef_PopMenuProc(ps)
			
			SetDataFolder root:
			break
	endswitch

	return 0
End

// if the Data Set is changed, then update the function (if possible)
// and the coef popup (if possible) and then the table (if possible)
//
// !! only respond to mouse up here, and simply send a fake mouse up
// to the function pop, which will do what it can do
//
Function DataSet_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			// make sure that the cursors are on/off appropriately
			// let the cursors checkbox decide what to do, sending the current state
			ControlInfo/W=WrapperPanel check_0
			STRUCT WMCheckboxAction cba
			cba.eventCode = 2
			cba.checked = V_Value
			UseCursorsWrapperProc(cba)
					
			// then cascade the function/coefficient popups
			Struct WMPopupAction ps
			ps.eventCode = 2		//fake mouse up
			Function_PopMenuProc(ps)
			
			SetDataFolder root:
			break
	endswitch

	return 0
End


// - this is based on stringent "PlotNNN" naming requirements
//
//  ???
// - how to kill the generated table and graph, that are not needed now
//
Function PlotModelFunction(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String folderStr,funcStr,coefStr,cmdStr=""
	Variable useCursors,useEps,useConstr
	
	Variable killWhat=0		//kill nothing as default
	
	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo/W=WrapperPanel popup_0
			folderStr=S_Value
			
			ControlInfo/W=WrapperPanel popup_1
			funcStr=S_Value
			
			// maybe nothing has been loaded yet...
			if(cmpstr(funcStr,"No functions plotted") == 0)
				break
			endif
			
			// check for smeared or smeared function
			if(stringmatch(funcStr, "Smear*" )==1)
				//it's a smeared model
				// check for the special case of RPA that has an extra parameter
				if(strsearch(funcStr, "RPAForm", 0 ,0) == -1)
					sprintf cmdStr, "Plot%s(\"%s\")",funcStr,folderStr		//not RPA
				else
					sprintf cmdStr, "Plot%s(\"%s\",)",funcStr,folderStr		//yes RPA, leave a comma for input
				endif
				killWhat = 1
			else
				// it's not, 	don't kill the graph, just the table		
				sprintf cmdStr, "Plot%s()",funcStr
				killWhat = 2
			endif
			
			//Print cmdStr
			Execute cmdStr
			
			//pop the function menu to set the proper coefficients
			DoWindow/F WrapperPanel
			STRUCT WMPopupAction pa
			pa.popStr = funcStr
			pa.eventcode = 2
			Function_PopMenuProc(pa)
	
			KillTopGraphAndTable(killWhat)		// crude
	
			break
	endswitch
	
	return 0
End

// passing 0 kills nothing
// passing 1 kills the top graph and table
// passing 2 kills the top table only
//
Function KillTopGraphAndTable(killwhat)
	Variable killWhat
	
	String topGraph= WinName(0,1)	//this is the topmost graph	
	String topTable= WinName(0,2)	//this is the topmost table

	if(killWhat == 0)
		return(0)
	endif
	
	if(killWhat == 1)
		KillWindow $topGraph
		KillWindow $topTable
	endif
	
	if(killWhat == 2)
		KillWindow $topTable
	endif
	
	return(0)
End

// How to bypass the step of plot and append?
//
// do it in two separate events
//
Function AppendModelToTarget(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String coefStr,suffix,yWStr,xWStr,folderStr,funcStr
	
	switch( ba.eventCode )
		case 2: // mouse up			
			ControlInfo/W=WrapperPanel popup_2
			coefStr=S_Value
			
			ControlInfo/W=WrapperPanel popup_1
			funcStr=S_Value
			suffix = getModelSuffix(funcStr)
			
			// check for smeared or smeared function
			if(stringmatch(coefStr, "smear*" )==1)
				//it's a smeared model
				ControlInfo/W=WrapperPanel popup_0
				folderStr=S_Value
				xWStr = "root:"+folderStr+":smeared_qvals"
				ywStr = "root:"+folderStr+":smeared_"+suffix
			else
				// it's not, so it's in the root folder
				xWStr = "xwave_"+suffix
				yWStr = "ywave_"+suffix
			endif
			
			Wave/Z yw = $yWStr
			Wave/Z xw = $xWStr
			if(WaveExists(yw) && WaveExists(xw))
				AppendtoGraph yw vs xw
			else
				DoAlert 0,"The selected model has not been plotted for the selected data set."
			endif
			break
	endswitch
	
	return 0
End


// this should parse the panel and call the FitWrapper() function
Function DoTheFitButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String folderStr,funcStr,coefStr
	Variable useCursors,useEps,useConstr,useResiduals,useTextBox, useRescaleAxis
	
	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo/W=WrapperPanel popup_0
			folderStr=S_Value
			
			ControlInfo/W=WrapperPanel popup_1
			funcStr=S_Value
			
			ControlInfo/W=WrapperPanel popup_2
			coefStr=S_Value
			
			ControlInfo/W=WrapperPanel check_0
			useCursors=V_Value
			ControlInfo/W=WrapperPanel check_1
			useEps=V_Value
			ControlInfo/W=WrapperPanel check_2
			useConstr=V_Value
			
			ControlInfo/W=WrapperPanel check_6
			useResiduals=V_Value
			
			ControlInfo/W=WrapperPanel check_7
			useTextBox = V_Value
			
			ControlInfo/W=WrapperPanel check_8
			useRescaleAxis = V_Value
			
			if(!CheckFunctionAndCoef(funcStr,coefStr))
				DoAlert 0,"The coefficients and function type do not match. Please correct the selections in the popup menus."
				break
			endif
			
			FitWrapper(folderStr,funcStr,coefStr,useCursors,useEps,useConstr,useResiduals,useTextBox,useRescaleAxis)
			
			//	DoUpdate (does not work!)
			//?? why do I need to force an update ??
			if(!exists("root:"+folderStr+":"+coefStr))
				Wave w=$coefStr
			else
				Wave w=$("root:"+folderStr+":"+coefStr) //smeared coefs in data folder 
			endif
			w[0] += 1e-6
			w[0] -= 1e-6

		// in Igor 8, the fit results don't seem to update automatically
		// unless I click off the wrapper and back on. even a direct ControlUpdate
		// doesn't work
			String topWin=WinName(0,1)  // Name of top graph
			DoWindow/F topWin
			DoUpdate
//			ControlUpdate/W=WrapperPanel grpBox_2
//			ControlUpdate/W=WrapperPanel grpBox_3
//			DoWindow/F WrapperPanel
					
			break
	endswitch
	
	return 0
End

Function CheckFunctionAndCoef(funcStr,coefStr)
	String funcStr,coefStr
	
	SVAR listStr=root:Packages:NIST:coefKWStr
	String properCoefStr = StringByKey(funcStr, listStr  ,"=",";",0)
	if(cmpstr("",properCoefStr)==0)
		return(0)		//false, no match found, so properCoefStr is returned null
	endif
	if(cmpstr(coefStr,properCoefStr)==0)
		return(1)		//true, the coef is the correct match
	endif
	return(0)			//false, wrong coef
End

/////////////////////////////////

// wrapper to do the desired fit
// 
// folderStr is the data folder for the desired data set
//
//
Function FitWrapper(folderStr,funcStr,coefStr,useCursors,useEps,useConstr,useResiduals,useTextBox,useRescaleAxis)
	String folderStr,funcStr,coefStr
	Variable useCursors,useEps,useConstr,useResiduals,useTextBox,useRescaleAxis

	String suffix=getModelSuffix(funcStr)
	
	SetDataFolder $("root:"+folderStr)
	if(!exists(coefStr))
		// must be unsmeared model, work in the root folder
		SetDataFolder root:				
		if(!exists(coefStr))		//this should be fine if the coef filter is working, but check anyhow
			DoAlert 0,"the coefficient and data sets do not match"
			return 0
		endif
	endif
		
	WAVE cw=$(coefStr)	
	Wave hold=$("Hold_"+suffix)
	Wave/T lolim=$("LoLim_"+suffix)
	Wave/T hilim=$("HiLim_"+suffix)
	
	if(useEps)
		Wave eps=$("epsilon_"+suffix)
	endif
// fill a struct instance whether I need one or not
	String DF="root:"+folderStr+":"	
	
	Struct ResSmearAAOStruct fs
	WAVE/Z resW = $(DF+folderStr+"_res")			//these may not exist, if 3-column data is used	
	WAVE/Z fs.resW =  resW
	WAVE yw=$(DF+folderStr+"_i")
	WAVE xw=$(DF+folderStr+"_q")
	WAVE sw=$(DF+folderStr+"_s")
	Wave fs.coefW = cw
	Wave fs.yW = yw
	Wave fs.xW = xw
	
	Duplicate/O yw $(DF+"FitYw")
	WAVE fitYw = $(DF+"FitYw")
	fitYw = NaN
	
	Variable useResol=0,isUSANS=0,val
	if(stringmatch(funcStr, "Smear*"))		// if it's a smeared function, need a struct
		useResol=1
	endif
	if(dimsize(resW,1) > 4)
		isUSANS=1
	endif
	
	// do not construct constraints for any of the coefficients that are being held
	// -- this will generate an "unknown error" from the curve fitting
	// -- if constraints are not used, the constr wave is killed. This apparently
	// confuses the /NWOK flag, since there is not even a null reference present. So generate one.
	if(useConstr)
		Make/O/T/N=0 constr
		String constraintExpression
		Variable i, nPnts=DimSize(lolim, 0),nextRow=0
		for (i=0; i < nPnts; i += 1)
			if (strlen(lolim[i]) > 0 && hold[i] == 0)
				InsertPoints nextRow, 1, constr
				sprintf constraintExpression, "K%d > %s", i, lolim[i]
				constr[nextRow] = constraintExpression
				nextRow += 1
			endif
			if (strlen(hilim[i]) > 0 && hold[i] == 0)
				InsertPoints nextRow, 1, constr
				sprintf constraintExpression, "K%d < %s", i, hilim[i]
				constr[nextRow] = constraintExpression
				nextRow += 1
			endif
		endfor
	else
		Wave/T/Z constr = constr
		KillWaves/Z constr
		Wave/T/Z constr = constr		//this is intentionally a null reference
	endif

	// 20JUN if useCursors is true, and there are no cursors on the specified data set, uncheck and set to false
	// this is a last line of defense, and should never actually do anything...
	if(useCursors)
		useCursors = AreCursorsCorrect(folderStr)
	endif
	//if useCursors, and the data is USANS, need to recalculate the matrix if the range is new
	Variable pt1,pt2,newN,mPt1,mPt2
	String noteStr
	if(useCursors && isUSANS )
		//where are the cursors, and what is the status of the current matrix?
		if(pcsr(A) > pcsr(B))
			pt1 = pcsr(B)
			pt2 = pcsr(A)
		else
			pt1 = pcsr(A)
			pt2 = pcsr(B)
		endif
		
		noteStr = note(resW)
		mPt1 = NumberByKey("P1",noteStr,"=",";")
		mPt2 = NumberByKey("P2",noteStr,"=",";")
		if((mPt1 != pt1) || (mPt2 != pt2) )
			// need to recalculate
			USANS_RE_CalcWeights(folderStr,pt1,pt2)
			Print "Done recalculating the matrix"
		endif
		
		Wave trimResW=$(DF+folderStr+"_res"+"t")	//put the trimmed resW in the struct for the fit!
		Wave fs.resW=trimResW
	endif
	if(useCursors)
		//find the points so that genetic optimization can use them
		if(pcsr(A) > pcsr(B))
			pt1 = pcsr(B)
			pt2 = pcsr(A)
		else
			pt1 = pcsr(A)
			pt2 = pcsr(B)
		endif
	else
		//if cursors are not being used, find the first and last points of the data set, and pass them
		pt1 = 0
		pt2 = numpnts(yw)-1
	endif
		
// create these variables so that FuncFit will set them on exit
	Variable/G V_FitError=0				//0=no err, 1=error,(2^1+2^0)=3=singular matrix
	Variable/G V_FitQuitReason=0		//0=ok,1=maxiter,2=user stop,3=no chisq decrease

	NVAR useGenCurveFit = root:Packages:NIST:gUseGenCurveFit
// don't use the auto-destination with no flag, it doesn't appear to work correctly
// dispatch the fit

// currently, none of the fit functions are defined as threadsafe, so I don't think that the /NTHR flag really
// does anything. The functions themselves can be threaded since they are AAO, and that is probably enough,
// since it doesn't make much sense to thread threads. In addition, there is a little-publicized warning
// in the WM help file that /C=texWave cannot be used to specify constraints for threadsafe functions!
// The textwave would have to be parsed into a constraint matrix first, then passed as /C={cMat,cVec}.
// -- just something to watch out for.

// now two more flags... ,useResiduals,useTextBox
	Variable tb = 1+2+4+8+16+256+512		//See CurveFit docs for bit settings for /TBOX flag

	do
		Variable t0 = stopMStimer(-2)		// corresponding print is at the end of the do-while loop (outside)


		if(useGenCurveFit)
		
#if !(exists("GenCurveFit"))
			// XOP not available
			useGenCurveFit = 0
			Abort "Genetic Optimiztion XOP not available. Reverting to normal optimization."	
#endif
			//send everything to a function, to reduce the clutter
			// useEps and useConstr are not needed
			// pass the structure to get the current waves, including the trimmed USANS matrix
			//
			// I don't know that GetCurveFit can do residuals, so I'm not passing that flag, or the text box flag
			//
			Variable chi,pt

			chi = DoGenCurveFit(useResol,useCursors,sw,fitYw,fs,funcStr,getHStr(hold),val,lolim,hilim,pt1,pt2)
			pt = val

			break
			
		endif

// for Igor 7 -- add the flag /N=0 to force the curve fit to update at each iteration. Some loss in speed
//   over the new default of no update, but the user can see what is happening.
		
		// now useCursors, useEps, and useConstr are all handled w/ /NWOK
		// so there are only three conditions to test == 1 + 3 + 3 + 1 = 8 conditions
		
		if(useResol && useResiduals && useTextBox)		//do it all
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 /TBOX=(tb) $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs /R /NWOK
			break
		endif
		
		if(useResol && useResiduals)		//res + resid
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs /R /NWOK
			break
		endif

		
		if(useResol && useTextBox)		//res + text
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 /TBOX=(tb) $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs /NWOK
			break
		endif
		
		if(useResol)		//res only
//			Print "timing test for Cylinder_PolyRadius---"
//			Variable t0 = stopMStimer(-2)

			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs /NWOK
			
//			t0 = (stopMSTimer(-2) - t0)*1e-6
//			Printf  "CylPolyRad fit time using res and eps and /NTHR=0 time = %g seconds\r\r",t0
//			cw[0] = .01
//			cw[1] = 20
//			cw[2] = 400
//			cw[3] = 0.2
//			cw[4] = 3e-6
//			cw[5] = 0.0
//			
//			t0 = stopMSTimer(-2)
//			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs /NWOK
//			t0 = (stopMSTimer(-2) - t0)*1e-6
//			Printf  "CylPolyRad fit time using res and eps and NO THREADING time = %g seconds\r\r",t0
			break
		endif
			
		
		
/////	same as above, but all without useResol (no /STRC flag)
		if(useResiduals && useTextBox)		//resid+ text
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 /TBOX=(tb) $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /R /NWOK
			break
		endif
		
		if(useResiduals)		//resid
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /R /NWOK
			break
		endif

		
		if(useTextBox)		//text
			FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 /TBOX=(tb) $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /NWOK
			break
		endif
		
		//just a plain vanilla fit

		FuncFit/H=getHStr(hold) /N=0 /M=2 /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /NWOK
		
	while(0)
	
	t0 = (stopMSTimer(-2) - t0)*1e-6
	Printf  "fit time = %g seconds\r\r",t0
	
	
	// append the fit
	// need to manage duplicate copies
	// Don't plot the full curve if cursors were used (set fitYw to NaN on entry...)
	String traces=TraceNameList("", ";", 1 )		//"" as first parameter == look on the target graph
	if(strsearch(traces,"FitYw",0) == -1 )
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	elseif (strsearch(traces,"FitYw_RA",0) == -1)
		RemoveFromGraph FitYw
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	else
		RemoveFromGraph FitYw_RA
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	endif
	ModifyGraph lsize(FitYw)=2,rgb(FitYw)=(0,0,0)
	
	DoUpdate		//force update of table and graph with fitted values (why doesn't this work? - the table still does not update)

// 	this is the top graph, and I do this in Igor 7 to force update of the infoBox and for the report to appear
	DoWindow/F $(WinName(0,1))	
	// report the results (to the panel?)
	if(useGenCurveFit)
		V_chisq = chi
		V_npnts = pt
	endif
	print "V_chisq = ",V_chisq
	print cw
	WAVE/Z w_sigma
	print w_sigma
	String resultStr=""
	Variable maxRelError=0
	
	if(waveexists(W_sigma))
		//append it to the table, if it's not already there
		CheckDisplayed/W=WrapperPanel#T0 W_sigma
		if(V_flag==0)
			//not there, append it
			AppendtoTable/W=wrapperPanel#T0 W_sigma
		else
			//remove it, and put it back on to make sure it's the right one (do I need to do this?)
			// -- not really, since any switch of the function menu takes W_Sigma off
		endif
		// then do I want to color it if the errors are horrible?
		Duplicate/O cw, relError
		relError = W_sigma/cw
		maxRelError = WaveMax(relError)
		if(maxRelError > kRelErrorTolerance)
			ModifyTable/W=wrapperPanel#T0 style(W_sigma)=1,rgb(W_sigma)=(65535,0,0)
		else
			ModifyTable/W=wrapperPanel#T0 style=0,rgb=(0,0,0)
	endif
	
	endif
	
	//now re-write the results
	sprintf resultStr,"Chi^2 = %g  Sqrt(X^2/N) = %g",V_chisq,sqrt(V_chisq/V_Npnts)
	resultStr = PadString(resultStr,63,0x20)
	DoWIndow/F WrapperPanel
	GroupBox grpBox_2 title=resultStr
	ControlUpdate/W=WrapperPanel grpBox_2
	sprintf resultStr,"FitErr = %s : FitQuit = %s",W_ErrorMessage(V_FitError),W_QuitMessage(V_FitQuitReason)
	resultStr = PadString(resultStr,63,0x20)
	GroupBox grpBox_3 title=resultStr
	ControlUpdate/W=WrapperPanel grpBox_3
	DoUpdate/W=WrapperPanel		//this still doesn't update the text...
	
	Variable yesSave=0,yesReport=0
	ControlInfo/W=WrapperPanel check_4
	yesReport = V_Value
	ControlInfo/W=WrapperPanel check_5
	yesSave = V_Value
	
	
	if(yesReport)
		String parStr=GetWavesDataFolder(cw,1)+ WaveList("*param*"+"_"+suffix, "", "TEXT:1," )		// this is *hopefully* one wave
		String topGraph= WinName(0,1)	//this is the topmost graph
	
		DoUpdate		//force an update of the graph before making a copy of it for the report

		//if GenCurveFit used, V_startRow and V_endRow may not exist - so read the cursors? but the cursors may not be used, so 
		// there won't be anything on the graph... but pt1 and pt2 are set and passed!. The V_ variables are more foolproof
		// so keep these for the "normal" report
		//
		if(useGenCurveFit)	
			W_GenerateReport(funcStr,folderStr,$parStr,cw,yesSave,V_chisq,W_sigma,V_npnts,V_FitError,V_FitQuitReason,pt1,pt2,topGraph)
		else
			W_GenerateReport(funcStr,folderStr,$parStr,cw,yesSave,V_chisq,W_sigma,V_npnts,V_FitError,V_FitQuitReason,V_startRow,V_endRow,topGraph)
		endif
	endif
	
	//Rescale the Plot depending on the user choice
	if(useRescaleAxis)
		string ctrlName = "GoRescale"
		RescalePlot(ctrlName)
	elseif (DataFolderExists("root:Packages:NIST:RescaleAxis"))
		SetDataFolder root:
		String PlotGraph= WinName(0,1)	//this is the topmost graph
		DoWindow/F $PlotGraph
		
		GetWindow/Z $PlotGraph, wavelist
		if (V_flag != 0)
			DoPrompt/Help="" "I couldn't find the graph"
			Abort
		endif
		
		wave/t W_Wavelist
		
		variable j
		string temp
		SetDataFolder root:Packages:NIST:RescaleAxis
		if (exists("W_WaveList")==1)
			KillWaves/Z root:Packages:NIST:RescaleAxis:W_WaveList
		endif
		MoveWave root:W_WaveList, root:Packages:NIST:RescaleAxis:W_WaveList
		
		for(i=0; i < numpnts(W_Wavelist)/3; i+=1)
			temp = W_WaveList[i][0]
			if(stringmatch(temp, "*_RA"))
		
				string WaveDataFolder, WaveToRescale
				WaveDataFolder = ReplaceString(W_WaveList[i][0], W_WaveList[i][1], "")
				if(strlen(WaveDataFolder)==0)
					WaveDataFolder = ":"
				endif
				WaveDataFolder = "root"+WaveDataFolder	
				SetDataFolder $WaveDataFolder
				temp = RemoveEnding(temp, "_RA")
				
				string xwave, ywave, oldywave, swave
				if(exists(temp)==1)
					Wave/T WaveString = $temp
					WaveToRescale = temp
					if (stringmatch(WaveToRescale, "*_i"))
						DoWindow/F PlotGraph
						oldywave = WaveToRescale+"_RA"
						ywave = WaveToRescale
						replacewave/Y/W=$PlotGraph trace=$oldywave, $ywave
						xwave = RemoveEnding(WaveToRescale, "_i")+"_q"
						replacewave/X/W=$PlotGraph trace=$ywave, $xwave	
						ModifyGraph log=0
						swave = RemoveEnding(WaveToRescale, "_i")+"_s"
						if(exists(swave)==1)
							ErrorBars/W=$PlotGraph $ywave, Y wave=($swave,$swave)	
						endif
					elseif(stringmatch(WaveToRescale, "smeared*") && stringmatch(WaveToRescale, "!*_qvals"))
						oldywave = WaveToRescale+"_RA"
						ywave = WaveToRescale
						replacewave/Y/W=$PlotGraph trace=$oldywave, $ywave
						xwave = "smeared_qvals"
						replacewave/X/W=$PlotGraph trace=$ywave, $xwave	
						ModifyGraph log=0
					elseif(stringmatch(WaveToRescale,"ywave*"))
						oldywave = WaveToRescale+"_RA"
						ywave = WaveToRescale
						xwave = ReplaceString("ywave",ywave,"xwave")
						replacewave/Y/W=$PlotGraph trace=$oldywave, $ywave
						replacewave/X/W=$PlotGraph trace=$ywave, $xwave					
					endif
				SetDataFolder root:Packages:NIST:RescaleAxis
				endif
			endif
		endfor
		KillWaves/Z W_WaveList
		modifygraph log=1
		Label left "I(q)"
		Label bottom "q (A\S-1\M)"
	Endif

	SetDataFolder root:
	return(0)
End

// parse something off of a table, or ?
Function/S getHStr(hold)
	Wave hold
	
	String str=""
	Variable ii
	for(ii=0;ii<numpnts(hold);ii+=1)
		str += num2str(hold[ii])
	endfor

//	print str
	if(strsearch(str, "1", 0) == -1)
		return ("")
	else
		return(str)
	endif
End

//taken from SRK Auto_Fit, and modified to work better with FitWrapper
//must have AutoGraph as the name of the graph window (any size)
// func is the name of the function (for print only)
//par and coef are the exact names of the waves
//yesSave==1 will save the file(name=func+time)
//
Function W_GenerateReport(func,dataname,param,ans,yesSave,chiSq,sigWave,npts,fitErr,fitQuit,fitStart,fitEnd,topGraph)
	String func,dataname
	Wave/T param
	Wave ans
	Variable yesSave,chiSq
	Wave sigWave
	Variable npts,fitErr,fitQuit,fitStart,fitEnd
	String topGraph
	
	String str,pictStr="P_"
	String nb="Report"
		
	// bring report up
	DoWindow/F Report
	if (V_flag == 0)		// Report notebook doesn't exist ?
		NewNotebook/W=(10,45,550,620)/F=1/N=Report as "Report"
	endif
	// delete old stuff
	Notebook $nb selection={startOfFile, endOfFile}, text="\r", selection={startOfFile, startOfFile}
	
	//setup
	Notebook $nb defaultTab=36, statusWidth=252, pageMargins={72,72,72,72}
	Notebook $nb showRuler=1, rulerUnits=1, updating={1, 60}
	Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Geneva",10,0,(0,0,0)}
//	
	// insert title
	Notebook $nb newRuler=Title, justification=1, rulerDefaults={"Times", 16, 1, (0, 0, 0)}
	sprintf str, "Fit to %s, %s, %s\r\r", func,Secs2Date(datetime, 0), time()
	Notebook $nb ruler=Title, text=str
	
	// insert fit results
	Variable num=numpnts(ans),ii=0
	Notebook $nb ruler=Normal
	Notebook $nb  margins={18,18,504}, tabs={63 + 3*8192}
	str = "Data file: " + dataname + "\r\r"
	Notebook $nb text=str
	Notebook $nb ruler=Normal
	Notebook $nb margins={18,18,504}, tabs={144,234,252}
	do
		sprintf str, "%s = \t%g\t�\t%g\r", param[ii],ans[ii],sigwave[ii]
		Notebook $nb text=str
		ii+=1
	while(ii<num)
	
	//
	// no "fitted range" for 2D data, so make sure that this exists before using it
	Wave/Z dataXw = $("root:"+dataname+":"+dataname+"_q")	
	//
	Notebook $nb ruler=Normal
	Notebook $nb  margins={18,18,504}, tabs={63+3*8192}, fStyle=1, textRGB=(65000,0,0)
	
	sprintf str,"chisq = %g\r",chisq
	Notebook $nb textRGB=(65000,0,0),fstyle=1,text=str
	sprintf str,"Npnts = %g \t\t Sqrt(X^2/N) = %g\r",npts,sqrt(chiSq/npts)
	Notebook $nb textRGB=(0,0,0),fstyle=0, text=str
	if(WaveExists(dataXw))
		sprintf str "Fitted range = [%d,%d] = %g < Q < %g\r",fitStart,fitEnd,dataXw(fitStart),dataXw(fitEnd)
		Notebook $nb textRGB=(0,0,0),fstyle=0, text=str
	endif
	sprintf str,"FitError = %s\t\tFitQuitReason = %s\r",W_ErrorMessage(FitErr),W_QuitMessage(FitQuit)
	Notebook $nb textRGB=(65000,0,0),fstyle=1,text=str
	Notebook $nb ruler=Normal
	
	// insert graphs
	// extra flag "2" (Igor >=7.00) is 2x screen resolution
	if(WaveExists(dataXw))
//		Notebook $nb picture={$topGraph(0, 0, 400, 300), -5, 1}, text="\r"
		Notebook $nb scaling={50, 50}, picture={$topGraph(0, 0, 800, 600), -5, 1,2}, text="\r"
	//
	else		//must be 2D Gizmo
		Execute "ExportGizmo Clip"			//this ALWAYS is a PICT or BMP. Gizmo windows are different...
		LoadPict/Q/O "Clipboard",tmp_Gizmo
		Notebook $nb picture={tmp_Gizmo(0, 0, 800, 600), 0, 1,2}, text="\r"
	endif
	
	// show the top of the report
	Notebook $nb  selection= {startOfFile, startOfFile},  findText={"", 1}
	
	//save the notebook and the graphic file
	// saving with a unique name can be an issue if there are a lot of files with similar names
	// and the fit function has a long name
	if(yesSave)
		String nameStr
		// function first		
//		nameStr=CleanupName(func,0)
//		nameStr += "_"+dataname
//		nameStr = ReplaceString("Smeared",nameStr,"Sm_")		//if Smeared function, shorten the name
		// -- or
		// data first
		nameStr = dataname+"_"
		nameStr += CleanupName(func,0)
		nameStr = ReplaceString("Smeared",nameStr,"Sm_")		//if Smeared function, shorten the name

		//make sure the name is no more than 31 characters
		namestr = namestr[0,26]		//if shorter than 31, this will NOT pad to 31 characters
		nameStr += ".ifn"			//extension is needed, otherwise the files are not recognized on Windows
		
		Print "file saved as ",nameStr
		SaveNotebook /O/P=home/S=2 $nb as nameStr
		//save the graph separately as a PNG file, 2x screen
		pictStr += nameStr
		pictStr = pictStr[0,24]+".png"		//need a shorter name - only 29 characters allowed - why?
//		DoWindow/F $topGraph
		// E=-5 is png @screen resolution
		// E=2 is PICT @2x screen resolution
///		SavePICT /E=-5/O/P=home /I/W=(0,0,3,3) as pictStr
		if(WaveExists(dataXw))
			SavePICT /E=-5/O/B=144/P=home/WIN=$topGraph /W=(0,0,800,600) as pictStr
		else
			Execute "ExportGizmo /P=home as \""+pictStr+"\""		//this won't be of very high quality
			//SavePICT /E=-5/O/P=home/WIN=$topGraph /W=(0,0,400,300) as pictStr
		endif
	Endif
	
	// ???maybe print the notebook too?
End

Function/S W_ErrorMessage(code)
	Variable code
	
	switch (code)
		case 0:
			return "No Error"
			break
		case 3:	//2^0 + 2^1
			return "Singular Matrix"
			break
		case 5:		//(2^0 + 2^2)
			return "Out of Memory"
			break
		case 9:		//(2^0 + 2^3)
			return "Func= NaN or Inf"
			break
		default:
			return "Unknown error code "+num2str(code)
	endswitch
end

Function/S W_QuitMessage(code)
	Variable code
	
	switch (code)
		case 0:
			return "No Error"
			break
		case 1:
			return "Max iterations - re-run fit"
			break
		case 2:
			return "User terminated fit"
			break
		case 3:
			return "No decrease in chi-squared"
			break
		default:
			return "Unknown Quit code "+num2str(code)
	endswitch
end

Function UseInfoTextBoxCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				//print "checked, use textBox in the next fit"
			else
				//print "unchecked, ask to remove TextBox from the graph"
				ControlInfo/W=WrapperPanel popup_0
				RemoveTextBox(S_value)
			endif
			break
	endswitch

	return 0
End

//does not report an error if the text box is not there
// -- so I'll just be lazy and not check to see if it's there
//
Function RemoveTextBox(folderStr)
	String folderStr
	
	DoAlert 1,"Remove the TextBox from the graph?"
	if(V_flag == 1)
		String str = "CF_"+folderStr+"_i"
		TextBox/K/N=$str
	endif
	return(0)
End

Function UseResidualsCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				//print "checked, use them in the next fit"
			else
				//print "unchecked, ask to remove residuals from the graph"
				ControlInfo/W=WrapperPanel popup_0
				RemoveResiduals(S_value)
			endif
			break
	endswitch

	return 0
End

// the default name from the /R flag is "Res_" + yWaveName
//
// better to find the wave that starts with "Res_" and remove that one in case the
// wave names get too long
//
// the difficulty now is that the residual wave ends up in root: and not with the data....
// -- not really a problem, but adds to clutter
Function RemoveResiduals(folderStr)
	String folderStr
	
	String list="",topWin=""
	Variable num,ii
	String str

	DoAlert 1,"Remove the residuals from the graph?"
	if(V_flag == 1)
//		String topGraph= WinName(0,1)	//this is the topmost graph
		list=TraceNameList("", ";", 1 )		//"" as first parameter == look on the target graph
		num=ItemsInList(list)
		
		for(ii=0;ii<num;ii+=1)
			str = StringFromList(ii, list ,";")
			if(strsearch(str, "Res_", 0) != -1)
				RemoveFromGraph $str
			endif
		endfor
	
		SetDataFolder root:
	endif
	
	return(0)
End

Function Toggle2DControlsCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				//print "change the buttons to 2D"
				Button button_0,proc=Do2DFitButtonProc,title="Do 2D Fit"
				Button button_1,size={120,20},proc=Plot2DFunctionButtonProc,title="Plot 2D Function"
				Button button_2,size={100,20},proc=Append2DModelButtonProc,title="Append 2D"
				Button button_3,size={100,20},proc=Load2DDataButtonProc,title="Load 2D Data"
				
				Button button_2D_0,pos={550,60},size={70,20},proc=LogToggle2DButtonProc,title="Log/Lin"
				Button button_2D_1,pos={520,37},size={100,20},proc=Plot2DButtonProc,title="Plot 2D Data"
				
				Button button_2D_0,disable=0		//visible again, and enabled
				Button button_2D_1,disable=0
				
				CheckBox check_6,disable=1			//info box and residual check, remove these from view
				CheckBox check_7,disable=1
				CheckBox check_8,disable=1
			else
				//print "unchecked, change them back to 1D"
				Button button_0,pos={520,93},size={100,20},proc=DoTheFitButton,title="Do 1D Fit"
				Button button_1,pos={280,57},size={120,20},proc=PlotModelFunction,title="Plot 1D Function"
				Button button_2,pos={300,93},size={100,20},proc=AppendModelToTarget,title="Append 1D"
				Button button_3,pos={300,20},size={100,20},proc=W_LoadDataButtonProc,title="Load 1D Data"
				
				Button button_2D_0,disable=3	//hide the extra 2D buttons, and disable
				Button button_2D_1,disable=3
				
				CheckBox check_6,disable=0			//info box and residual check, bring them back
				CheckBox check_7,disable=0
				CheckBox check_8,disable=0
			endif
			break
	endswitch

	return 0
End

// function to either add or remove the cursors from the topmost graph, as needed

Function UseCursorsWrapperProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba


	switch( cba.eventCode )
		case 2: // mouse up
		
			// check to make sure there really is a "topmost" graph		
			String topGraph= WinName(0,1)	//this is the topmost graph
			if(cmpstr(topGraph,"")==0) 	//no graphs, uncheck and exit
				CheckBox check_0,value=0
				return(0)
			endif
			
			//if in 2D mode, just exit
			ControlInfo/W=WrapperPanel check_3
			if(V_Value == 1)
				return (0)
			endif
				
			String ciStr = CsrInfo(A , topGraph)
			
			ControlInfo/W=wrapperpanel popup_0
			String folderStr=S_Value
			String traceList = TraceNameList(topGraph, ";", 1 )		
		
			Variable checked = cba.checked
			
			if(checked)
				//print "add the cursors to the topmost graph, if the data set is there, or move them"
				if(strlen(ciStr)==0 && strsearch(traceList, folderStr, 0) != -1 )		//no cursors && data is there
					ShowInfo
					Wave yw=$("root:"+folderStr+":"+folderStr+"_i")
					Cursor/P/W=$topGraph A, $(folderStr+"_i"),0
					Cursor/P/W=$topGraph/A=0 B, $(folderStr+"_i"),numpnts(yw)-1			//deactivate the one at the high Q end
					DoUpdate
				elseif (strlen(ciStr)!=0 && strsearch(traceList, folderStr, 0) != -1 ) //cursors present, but on wrong data
					Wave yw=$("root:"+folderStr+":"+folderStr+"_i")
					Cursor/P/W=$topGraph A, $(folderStr+"_i"),0								//move the cursors
					Cursor/P/W=$topGraph/A=0 B, $(folderStr+"_i"),numpnts(yw)-1
					DoUpdate
				endif
				
				AreCursorsCorrect(folderStr)
			else
				//print "unchecked, remove the cursors"
				// go back to the full matrix for the resolution calculation (not if SANS data...)
				if(waveExists($("root:"+folderStr+":weights_save")))
					Duplicate/O $("root:"+folderStr+":weights_save"), $("root:"+folderStr+":"+folderStr+"_res"),$("root:"+folderStr+":"+folderStr+"_rest")
				endif

				HideInfo/W=$topGraph
				Cursor/K A
				Cursor/K B
			endif
			break
	endswitch

	return 0
End

// returns 1 if the specified data is on the top graph && has cursors on it
// returns 0 and unchecks the box if anything is wrong
//
// only call this function if the cursor box is checked, to uncheck it as needed
// if the box is unchecked, leave it be.
//
Function AreCursorsCorrect(folderStr)
	String folderStr
	
	String topGraph= WinName(0,1)	//this is the topmost graph
	if(cmpstr(topGraph,"")==0) 	//no graphs, uncheck and exit
		CheckBox check_0,win=wrapperpanel,value=0
		return(0)
	endif
		
	String traceAisOn = CsrWave(A , "", 0)
	if(	strsearch(traceAisOn, folderStr, 0) == -1)		//data and cursors don't match
		CheckBox check_0,win=wrapperpanel,value=0
		HideInfo
		Cursor/K A
		Cursor/K B
		return(0)
	endif
	
	return(1)
End



//////////////////////////////
//
// displays the covariance matrix for the current data set in the popup
// AND whatever was the last fit for that data set. it may not necessarily
// be the displayed function...
Function DisplayCovarianceMatrix()

	

	ControlInfo/W=wrapperpanel popup_0
	String folderStr=S_Value

	ControlInfo/W=WrapperPanel popup_1
	String funcStr=S_Value
			
	if(Stringmatch(funcStr,"Smear*"))		//simple test for smeared function
		if(DataFolderExists("root:"+folderStr))
			SetDataFolder $("root:"+folderStr)
		else
			SetDataFolder root:
		endif
	else
		SetDataFolder root:
	endif
	
	Wave M_Covar=M_Covar
	Duplicate/O M_Covar, CorMat	 // You can use any name instead of CorMat
	CorMat = M_Covar[p][q]/sqrt(M_Covar[p][p]*M_Covar[q][q])

	// clear the table (a subwindow)
	DoWindow/F CorMatPanel				// ?? had to add this in during all of the cursor meddling...
	KillWindow CorMatPanel#T0
	Edit/W=(20,74,634,335)/HOST=CorMatPanel
	RenameWindow #,T0
	// get them onto the table
	// how do I get the parameter name?
	String param = getFunctionParams(funcStr)
	AppendtoTable/W=CorMatPanel#T0 $param
	AppendToTable/W=CorMatPanel#T0 CorMat
	ModifyTable/W=CorMatPanel#T0 width(Point)=0

	GroupBox grpBox_1 title="Data set: "+folderStr
	GroupBox grpBox_2 title="Function: "+funcStr


	SetDataFolder root:
	
	return(0)
End


Window CorMatPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(459,44,1113,399)/N=CorMatPanel/K=1 as "Correlation Matrix"
	ModifyPanel fixedSize=1
	
	GroupBox grpBox_1 title="box 1",pos={10,20},size={0,0},frame=1,fSize=10,fstyle=1,fColor=(39321,1,1)
	GroupBox grpBox_2 title="box 2",pos={10,40},size={0,0},frame=1,fSize=10,fstyle=1,fColor=(39321,1,1)

	Button button_1,pos={520,30},size={100,20},proc=CorMatHelpButtonProc,title="Help"

	Edit/W=(20,74,634,335)/HOST=#  
	ModifyTable width(Point)=0
	RenameWindow #,T0
	SetActiveSubwindow ##
EndMacro


Proc DisplayCovariance()
	DoWindow/F CorMatPanel
	if(V_Flag==0)
		CorMatPanel()
	endif
	
	DisplayCovarianceMatrix()

End

//open the Help file for the Fit Manager
Function CorMatHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Covariance Matrix"
			if(V_flag !=0)
				DoAlert 0,"Help for the correlation matrix could not be found"
			endif
			break
	endswitch

	return 0
End


//////////////////////////////////
// this is a snippet from Andy Nelson, posted at the Igor Exchange web site.
//
// search area appears to be a percent (so enter 10 to get +/- 10% variation in the parameter)
//
// TODO:
//		x- rename the function for just me
//		x- make the edata a mandatory parameter
//		x- remove rhs, lhs? or keep these if cursors were used to properly trim the data set
//		x- label the graph
//		x- make a panel to control this - to either pick a single parameter, or show all of them
//		x- have it re-use the same graph, not draw a (new) duplicate one
//		x- update it to use the AAO as the input function (new func template -- see Gauss Utils)
//		x- the wrapper must be data folder aware, and data set aware like in the Wrapper panel
//		x- need a different wrapper for smeared and unsmeared functions
//
//



Proc MapChiSquared(paramNum,percent)
	Variable paramNum=0,percent=10
	Prompt paramNum, "Enter parameter number: "
	Prompt percent, "Enter percent variation +/- : "

	fChiMap(paramNum,percent)
End


// this does the setup
Function fChiMap(paramNum,percent)
	Variable paramNum,percent

	String folderStr,funcStr,coefStr
	Variable useCursors,useResol=0,pt1,pt2,minIndex
	
	ControlInfo/W=WrapperPanel popup_0
	folderStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_1
	funcStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_2
	coefStr=S_Value
	
	ControlInfo/W=WrapperPanel check_0
	useCursors=V_Value
	
	
// first, figure out where we are...
	String suffix=getModelSuffix(funcStr)
	
	SetDataFolder $("root:"+folderStr)
	if(!exists(coefStr))
		// must be unsmeared model, work in the root folder
		SetDataFolder root:				
		if(!exists(coefStr))		//this should be fine if the coef filter is working, but check anyhow
			DoAlert 0,"the coefficient and data sets do not match"
			return 0
		endif
	endif
		
	WAVE cw=$(coefStr)


// test for smeared function
	if(stringmatch(funcStr, "Smear*"))		// if it's a smeared function, need a struct
		useResol=1
	endif
	
	// fill a struct instance whether I need one or not
	String DF="root:"+folderStr+":"	
	
//	Struct ResSmearAAOStruct fs
//	WAVE/Z resW = $(DF+folderStr+"_res")			//these may not exist, if 3-column data is used	
//	WAVE/Z fs.resW =  resW
	WAVE yw=$(DF+folderStr+"_i")
	WAVE xw=$(DF+folderStr+"_q")
	WAVE sw=$(DF+folderStr+"_s")
//	Wave fs.coefW = cw
//	Wave fs.yW = yw
//	Wave fs.xW = xw	
	
	if(useCursors)
		if(pcsr(A) > pcsr(B))
			pt1 = pcsr(B)
			pt2 = pcsr(A)
		else
			pt1 = pcsr(A)
			pt2 = pcsr(B)
		endif
	else
		//if cursors are not being used, find the first and last points of the data set, and pass them
		pt1 = 0
		pt2 = numpnts(yw)-1
	endif
	
	minIndex = chi2gen(funcStr,folderStr,xw,yw,sw,cw,paramNum,percent,pt1,pt2,useResol)
	
	WAVE chi2_map=chi2_map
	cw[paramNum] = pnt2x(chi2_map, minIndex)
	
	return(0)
End

// this does the math for a single value of "whichParam"
Function chi2gen(funcStr,folderStr,xw,yw,sw,cw,whichParam,searchArea,lhs,rhs,useResol)
	String funcStr,folderStr
	Wave xw,yw,sw,cw      //	x data, y data, error wave, and coefficient wave
	variable whichParam, searchArea  //which of the parameters to you want to vary, how far from the original value do you want to search (%)
	variable lhs, rhs    //specify a region of interest in the data using a left hand side and right hand side.
 	variable useResol		// =1 if smeared used
 
	variable originalvalue = cw[whichparam]
	variable range = originalValue * searchArea/100
	variable ii,err,minIndex
 
	duplicate/o yw, :theoretical_data, :chi2_data
	Wave theoretical_data, chi2_data
 
	make/o/n=50/d chi2_map
	setscale/I x,  originalvalue - range, originalvalue + range, chi2_map
 
 	String DF="root:"+folderStr+":"	
	String suffix=getModelSuffix(funcStr)

 	// fill a struct instance whether it is needed or not
	Struct ResSmearAAOStruct fs
	WAVE/Z resW = $(DF+folderStr+"_res")			//these may not exist, if 3-column data is used	
	WAVE/Z fs.resW =  resW
//		WAVE yw=$(DF+folderStr+"_i")
//		WAVE xw=$(DF+folderStr+"_q")
//		WAVE sw=$(DF+folderStr+"_s")
	Wave fs.coefW = cw
	Wave fs.yW = theoretical_data
	Wave fs.xW = xw	
 
 
 
	for(ii=0 ; ii < numpnts(chi2_map) ; ii+=1)
		cw[whichparam] = pnt2x(chi2_map, ii)
 
		if(useResol)
			FUNCREF SANSModelSTRUCT_proto func1=$funcStr
			err = func1(fs)
		else
			FUNCREF SANSModelAAO_proto func2=$funcStr
			func2(cw,theoretical_data,xw)
		endif
		
		chi2_data = (yw-theoretical_data)^2
 
		chi2_data /= sw^2

		Wavestats/q/R=[lhs, rhs] chi2_data
 
		chi2_map[ii] = V_avg * V_npnts
	endfor
 
	cw[whichparam] = originalvalue
 
 	DoWindow/F Chi2
 	if(V_flag==0)
		display/K=1/N=Chi2 chi2_map
		Label left "Chi^2"
 	endif

	String parStr=GetWavesDataFolder(cw,1)+ WaveList("*param*"+"_"+suffix, "", "TEXT:1," )		// this is *hopefully* one wave
	Wave/T parW = $parStr
 	Label bottom parW[whichParam]
 	
 	WaveStats/Q chi2_map
 	minIndex = V_minRowLoc
 	Print "minimum at: ", minIndex,chi2_map[minIndex]
 	
 	
	killwaves/z theoretical_data, chi2_data
	return(minIndex)
End
 

//////////////////////////////////
// this is based on a snippet from Andy Nelson, posted at the Igor Exchange web site.
// -- modified to do "manual fitting" - mapping out chi-squared along one or two directions
//////////////////////////////////

Proc OpenManualFitPanel()

	DoWindow/F ManualFitPanel
	if(V_flag==0)
		init_manualFit()
		ManualFitPanel()
	Endif

End

Function init_manualFit()

	Variable/G root:gNumManualParam=0
	Variable/G root:gNumManualParam2=1
	Variable/G root:gCurrentChiSq=0
	Variable/G root:gNumManualSteps=50
	
	Make/O/D/N=1 root:chi2_map,root:testVals
	Make/O/D/N=(1,1) root:chi2D
	
	return(0)
end

Window ManualFitPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1170,44,1842,412) /K=1
	ModifyPanel cbRGB=(51664,44236,58982)
	DoWindow/C ManualFitPanel
	
//	ShowTools/A
	SetVariable setvar0,pos={25,10},size={150,15},title="Parameter number"
	SetVariable setvar0,limits={0,inf,1},value=root:gNumManualParam,disable=0
	SetVariable setvar3,pos={25,30},size={150,15},title="Parameter number"
	SetVariable setvar3,limits={0,inf,1},value=root:gNumManualParam2,disable=2
	
	CheckBox check0,pos={200,10},size={37,15},value=0,title="2D?",proc=Vary2DCheck
		
	Button button0,pos={25,55},size={100,20},title="Vary 100 %",proc=VaryPCTButton
	Button button1,pos={25,80},size={100,20},title="Vary 25 %",proc=VaryPCTButton
	Button button2,pos={25,105},size={100,20},title="Vary 5 %",proc=VaryPCTButton
	Button button3,pos={25,130},size={100,20},title="Vary 1 %",proc=VaryPCTButton
	SetVariable setvar1,pos={31,196},size={200,15},title="Current Chi-Squared"
	SetVariable setvar1,limits={0,0,0},value=root:gCurrentChiSq	
	SetVariable setvar2,pos={31,222},size={200,15},title="Number of steps"
	SetVariable setvar2,limits={5,500,1},value=root:gNumManualSteps
	
	//
	Display/W=(259,23,643,346)/HOST=# root:chi2_map vs root:testVals
	RenameWindow #,G0
	ModifyGraph mode=4,msize=1,rgb=(65535,0,0)
	ModifyGraph tick=2,mirror=1
//	Label left "Chi-squared"
//	Label bottom "degrees"	
	SetActiveSubwindow ##
		
EndMacro


Function Vary2DCheck(ctrlName,checked)
	String ctrlName
	Variable checked
	
	ControlInfo check0
	Variable isChecked = V_Value
	
	Wave chi2D=chi2D
	Wave chi2_map=chi2_map
	wave testVals=testVals
	
	if(isChecked)
		SetVariable setvar0,disable=0
		SetVariable setvar3,disable=0
		
		//
		RemoveFromGraph/W=ManualFitPanel#G0 chi2_map
		
//		Display/W=(259,23,643,346)/HOST=# 
		AppendImage/W=ManualFitPanel#G0 chi2D
		SetActiveSubwindow ManualFitPanel#G0
		ModifyImage chi2D ctab= {*,*,ColdWarm,0}
		Label left "par"
		Label bottom "par2"
		SetActiveSubwindow ##
		
	else
		SetVariable setvar0,disable=0
		SetVariable setvar3,disable=2
		
		//
		RemoveImage/W=ManualFitPanel#G0 chi2D

		AppendToGraph/W=ManualFitPanel#G0 root:chi2_map vs root:testVals
		SetActiveSubwindow ManualFitPanel#G0
//		Display/W=(259,23,643,346)/HOST=# root:chi2_map vs root:testVals
		ModifyGraph mode=4,msize=1,rgb=(65535,0,0)
		ModifyGraph tick=2,mirror=1
		Label left "Chi-squared"
	//	Label bottom "degrees"	
		SetActiveSubwindow ##
		
		
	endif
	
	return(0)
End


Function getParamFromWrapper()

	Variable parNum
	
	GetSelection table, WrapperPanel#T0, 1
	parNum = V_startRow
	return(parNum)
End


Function VaryPCTButton(ctrlName) : ButtonControl
	String ctrlName

	Variable percent
	strswitch(ctrlName)	// string switch
		case "button0":		
			percent = 105
			break
		case "button1":		
			percent = 25
			break
		case "button2":		
			percent = 5
			break		
		case "button3":		
			percent = 1
			break
		default:							
			percent = 10					
	endswitch

	ControlInfo check0
	Variable isChecked = V_Value

	// get the necessary info about parameters, etc.
	String folderStr,funcStr,coefStr
	Variable useCursors,useResol=0,pt1,pt2,minIndex
	
	ControlInfo/W=WrapperPanel popup_0
	folderStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_1
	funcStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_2
	coefStr=S_Value
	
//	ControlInfo/W=WrapperPanel check_0
//	useCursors=V_Value
//	
	
// first, figure out where we are...
	String suffix=getModelSuffix(funcStr)
	
	SetDataFolder $("root:"+folderStr)
	if(!exists(coefStr))
		// must be unsmeared model, work in the root folder
		SetDataFolder root:				
		if(!exists(coefStr))		//this should be fine if the coef filter is working, but check anyhow
			DoAlert 0,"the coefficient and data sets do not match"
			return 0
		endif
	endif
		
	WAVE cw=$(coefStr)
	SetDataFolder root:

	
	Variable loLim,hiLim,minChiSq

	NVAR numStep = root:gNumManualSteps
	make/o/n=(numStep)/D root:testVals
	Wave testVals = root:testVals
	WAVE chi2_map = root:chi2_map
	Make/O/D/N=(numStep,numStep) root:chi2D
	WAVE chi2D = root:chi2D
	
	
	// then do either a 1D or 2D map of the chi squared
	if(isChecked)
	
		NVAR par = root:gNumManualParam
		NVAR par2 = root:gNumManualParam2
		
		Variable ii,jj,saveVal2
		saveVal2 = cw[par2]		//initial value of par2
		
		//steps in par2 direction
		make/o/n=(numStep)/D root:testVals2
		Wave testVals2 = root:testVals2
		loLim = cw[par2] - percent*cw[par2]/100
		hiLim = cw[par2] + percent*cw[par2]/100
		testVals2 = loLim + x*(hiLim-loLim)/numStep

		SetScale/I x LoLim,HiLim,"", chi2D

		//steps in par1 direction
		if(cw[par] != 0)	
			loLim = cw[par] - percent*cw[par]/100
			hiLim = cw[par] + percent*cw[par]/100
		else
			loLim = -1
			hiLim = 1
		endif
		testVals = loLim + x*(hiLim-loLim)/numStep
		SetScale/I y LoLim,HiLim,"", chi2D

		
		for(ii=0;ii<numStep;ii+=1)
			cw[par2] = testVals2[ii]		//set the value for par2, vary par
		
			fChiMap_new(par,percent,cw,testVals)		//the wave chi2_map is generated

			chi2D[ii][] = chi2_map[q]
	
		endfor

		// set the new minimum value
		WaveStats/Q chi2D
	// now with scaled dimensions of Chi2D, the reported values are the values, not the point index
		cw[par] = V_MinColLoc
		cw[par2] = V_MinRowLoc	
	
		// the minimum chi_squared  along this path is at: -- is it better?
		minChiSq = V_Min
	
		NVAR curChi2=root:gCurrentChiSq
		curChi2 = minChiSq	
	
		//V_min*1.01 = the 1% neighborhood around the solution
		ModifyImage/W=ManualFitPanel#G0 chi2D ctab= {(V_min*1.01),*,ColdWarm,0}
		ModifyImage/W=ManualFitPanel#G0 chi2D minRGB=(0,65535,0),maxRGB=(0,65535,0)
	
	else
		NVAR par = root:gNumManualParam
//		par = getParamFromWrapper()			//SRK 2022
		
		if(cw[par] != 0)	
			loLim = cw[par] - percent*cw[par]/100
			hiLim = cw[par] + percent*cw[par]/100
		else
			loLim = -1
			hiLim = 1
		endif
		testVals = loLim + x*(hiLim-loLim)/numStep

		
		fChiMap_new(par,percent,cw,testVals)		//the wave chi2_map is generated
			
		// set the new minimum value
		WaveStats/Q chi2_map
	 	minIndex = V_minRowLoc
		cw[par] = testVals[minIndex]
		
		// the minimum chi_squared  along this path is at: -- is it better?
		minChiSq = chi2_map[minIndex]
	
		NVAR curChi2=root:gCurrentChiSq
		curChi2 = minChiSq
	endif
	
	
	return(0)
End


Proc mMapChiSquared_Pct(paramNum,percent)
	Variable paramNum=0,percent=50
	Prompt paramNum, "Enter parameter number: "
	Prompt percent, "Enter percent variation:"

	fChiMap_new(paramNum,percent)
End

//Macro mMapChiSquared(paramNum,loLim,hiLim)
//	Variable paramNum=0,loLim=0,hiLim=1
//	Prompt paramNum, "Enter parameter number: "
//	Prompt loLim, "Enter lower value:"
//	Prompt hiLim, "Enter higher value:"
//
//	fChiMap_new(paramNum,loLim,hiLim)
//End


// this does the setup
Function fChiMap_new(paramNum,percent,cw,testVals)
	Variable paramNum,percent
	Wave cw,testVals
	
//Function fChiMap_new(paramNum,percent)
//	Variable paramNum,percent


	String folderStr,funcStr,coefStr
	Variable useCursors,useResol=0,pt1,pt2,minIndex
	
	ControlInfo/W=WrapperPanel popup_0
	folderStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_1
	funcStr=S_Value
	
	ControlInfo/W=WrapperPanel popup_2
	coefStr=S_Value
	
	ControlInfo/W=WrapperPanel check_0
	useCursors=V_Value
	
// coefficent wave cw is passed in

// test for smeared function
	if(stringmatch(funcStr, "Smear*"))		// if it's a smeared function, need a struct
		useResol=1
	endif
	
	// wave references for the data (to pass)
	String DF="root:"+folderStr+":"	
	
	WAVE yw=$(DF+folderStr+"_i")
	WAVE xw=$(DF+folderStr+"_q")
	WAVE sw=$(DF+folderStr+"_s")

	if(useCursors)
		if(pcsr(A) > pcsr(B))
			pt1 = pcsr(B)
			pt2 = pcsr(A)
		else
			pt1 = pcsr(A)
			pt2 = pcsr(B)
		endif
	else
		//if cursors are not being used, find the first and last points of the data set, and pass them
		pt1 = 0
		pt2 = numpnts(yw)-1
	endif

	Variable loLim,hiLim,minChiSq

	SetDataFolder root:
	
	NVAR numStep = root:gNumManualSteps
	make/o/n=(numStep)/D root:chi2_map
	Wave chi2_map = root:chi2_map
//	Wave testVals = root:testVals
	
	//the testVals are genereated and passed by the calling routine	
			
	minIndex = chi2gen_new(funcStr,folderStr,xw,yw,sw,cw,paramNum,pt1,pt2,useResol,chi2_map,testVals)
	
	return(0)
End


// this does the math for a single value of "whichParam"
Function chi2gen_new(funcStr,folderStr,xw,yw,sw,cw,whichParam,lhs,rhs,useResol,chi2_map,testVals)
	String funcStr,folderStr
	Wave xw,yw,sw,cw      //	x data, y data, error wave, and coefficient wave
	variable whichParam  //which of the parameters to you want to vary, how far from the original value do you want to search (%)
	variable lhs, rhs    //specify a region of interest in the data using a left hand side and right hand side.
 	variable useResol		// =1 if smeared used
 	Wave chi2_map,testVals
 
	variable originalvalue = cw[whichparam]
//	variable range = originalValue * searchArea/100
	variable ii,err,minIndex
 
	duplicate/o yw, :theoretical_data, :chi2_data
	Wave theoretical_data, chi2_data
 
 	String DF="root:"+folderStr+":"	
	String suffix=getModelSuffix(funcStr)

 	// fill a struct instance whether it is needed or not
	Struct ResSmearAAOStruct fs
	WAVE/Z resW = $(DF+folderStr+"_res")			//these may not exist, if 3-column data is used	
	WAVE/Z fs.resW =  resW
//		WAVE yw=$(DF+folderStr+"_i")			//these are passed in
//		WAVE xw=$(DF+folderStr+"_q")
//		WAVE sw=$(DF+folderStr+"_s")
	Wave fs.coefW = cw
	Wave fs.yW = theoretical_data
	Wave fs.xW = xw	
 
 
 
	for(ii=0 ; ii < numpnts(chi2_map) ; ii+=1)
		cw[whichparam] = testVals[ii]
 
		if(useResol)
			FUNCREF SANSModelSTRUCT_proto func1=$funcStr
			err = func1(fs)
		else
			FUNCREF SANSModelAAO_proto func2=$funcStr
			func2(cw,theoretical_data,xw)
		endif
		
		chi2_data = (yw-theoretical_data)^2
 
		chi2_data /= sw^2

		Wavestats/q/R=[lhs, rhs] chi2_data
 
		chi2_map[ii] = V_avg * V_npnts
	endfor
 
	cw[whichparam] = originalvalue

 	
 	WaveStats/Q chi2_map
 	minIndex = V_minRowLoc
// 	Print "minimum at: ", minIndex,chi2_map[minIndex]
 	
	killwaves/z theoretical_data, chi2_data
	return(minIndex)
End

//////////////////////////