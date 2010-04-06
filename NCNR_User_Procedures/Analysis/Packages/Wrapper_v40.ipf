#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.00
#pragma IgorVersion=6.1

//
// need a way of importing more functions into the experiment
// ? call the picker panel from the panel?
//
//

//Macro OpenWrapperPanel()
//	Init_WrapperPanel()
//End

Function Init_WrapperPanel()
	//make sure that folders exist - this is the first initialization to be called
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST

	//Create useful globals
	Variable/G root:Packages:NIST:SANS_ANA_VERSION=4.00
	String/G root:Packages:NIST:SANS_ANA_EXTENSION="_v40"
	//Set this variable to 1 to force use of trapezoidal integration routine for USANS smearing
	Variable/G root:Packages:NIST:USANSUseTrap = 0
	Variable/G root:Packages:NIST:USANS_dQv = 0.117
	Variable/G root:Packages:NIST:gUseGenCurveFit = 0			//set to 1 to use genetic optimization
			
	//Ugly. Put this here to make sure things don't break
	String/G root:Packages:NIST:gXMLLoader_Title
	Variable/G root:Packages:NIST:gXML_Write = 1
	
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
	CheckBox check_0,pos={440,19},size={79,14},title="Use Cursors?",value= 0
	CheckBox check_0,proc=UseCursorsWrapperProc
	CheckBox check_1,pos={440,42},size={74,14},title="Use Epsilon?",value= 0
	CheckBox check_2,pos={440,65},size={95,14},title="Use Constraints?",value= 0
	CheckBox check_3,pos={530,18},size={72,14},title="2D Functions?",value= 0
	CheckBox check_3 proc=Toggle2DControlsCheckProc
	CheckBox check_4,pos={440,85},size={72,14},title="Report?",value= 0
	CheckBox check_5,pos={454,103},size={72,14},title="Save it?",value= 0
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


// always pass this the function string
//
// this is new in the 2009 release, so make sure that it generates itself as needed.
// Two options: (1) search and construct as needed, ask for intervention if I need it.
// (2) since I'm passed the function, try to replot it to re-run the function
// to fill in the strings. (Being sure to save the coefficients)
//
// using method (1) to fill in what I need with no intervention
//
Function/S getFunctionParams(funcStr)
	String funcStr

	String paramStr=""
	SVAR/Z listStr=root:Packages:NIST:paramKWStr

	if(SVAR_Exists(listStr))
		paramStr = StringByKey(funcStr, listStr  ,"=",";",0)
		if(strlen(paramStr)!=0)			//will drop out of loop if string can't be found
			return(paramStr)
		endif
	else	//global string does not exist, create it and fill it in
		Variable/G root:Pacakges:NIST:gReconstructStrings = 1			//coefficients old style and must be rebuilt too
		String/G root:Packages:NIST:paramKWStr=""
		SVAR/Z listStr=root:Packages:NIST:paramKWStr
	endif	
	
	// find everything to rebuild only if the model has been plotted (if so, coefficients will exist)
	String coef = getFunctionCoef(funcStr)
	if(strlen(coef)==0)
		//model not plotted, don't reconstruct, return null string
		return(paramStr)
	endif
	
	///// NEED TO BE IN PROPER DATA FOLDER FOR SMEARED FUNCTIONS
	// FUNCTION POP MENU WILL LOOK IN ROOT OTHERWISE
	ControlInfo/W=WrapperPanel popup_0
	String folderStr=S_Value
	// this if/else/endif should not ever return an error alert	
	// it should simply set the data folder properly	
	if(Stringmatch(funcStr,"Smear*"))		//simple test for smeared function
		if(DataFolderExists("root:"+folderStr))
			SetDataFolder $("root:"+folderStr)
		else
			SetDataFolder root:
		endif
	else
		SetDataFolder root:
	endif
	
	// model was plotted, find the suffix to fill in the parameter wave
	SVAR suffListStr=root:Packages:NIST:suffixKWStr
	String suffix = StringByKey(coef, suffListStr  ,"=",";",0)
	
	String paramWave = WaveList("*par*"+suffix,"","TEXT:1")		//should be one wave name, no trailing semicolon
	listStr += funcStr+"="+paramWave+";"

	//now look it up again
	paramStr = StringByKey(funcStr, listStr  ,"=",";",0)

	return(paramStr)
End

// always pass this the function string
//
Function/S getFunctionCoef(funcStr)
	String funcStr

	SVAR listStr=root:Packages:NIST:coefKWStr
	String coefStr = StringByKey(funcStr, listStr  ,"=",";",0)

	return(coefStr)
End

// always pass this the Function string
//
// does NOT return the leading "_" as part of the suffix
// may need to set the string correctly - so lost of messing around for back-compatibility
Function/S getModelSuffix(funcStr)
	String funcStr

	SVAR listStr=root:Packages:NIST:suffixKWStr
	String suffixStr = StringByKey(funcStr, listStr  ,"=",";",0)

	if(strlen(suffixStr) !=0)		//found it, get out
		return(suffixStr)
	endif
	
	// was the model plotted?
	String coef = getFunctionCoef(funcStr)
	if(strlen(coef)==0)		
		//nothing plotted
		return("")
	else
		//plotted, find the coeff
		String suffix = StringByKey(coef, ListStr  ,"=",";",0)
	
		// add to the suffix list in the new style, if it was found
		if(strlen(suffix) !=0)
			listStr += funcStr+"="+suffix+";"
		endif
		return(suffix)
	endif
	
	return("")
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
	Variable useCursors,useEps,useConstr
	
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
			
			if(!CheckFunctionAndCoef(funcStr,coefStr))
				DoAlert 0,"The coefficients and function type do not match. Please correct the selections in the popup menus."
				break
			endif
			
			FitWrapper(folderStr,funcStr,coefStr,useCursors,useEps,useConstr)
			
			//	DoUpdate (does not work!)
			//?? why do I need to force an update ??
			if(!exists("root:"+folderStr+":"+coefStr))
				Wave w=$coefStr
			else
				Wave w=$("root:"+folderStr+":"+coefStr) //smeared coefs in data folder 
			endif
			w[0] += 1e-6
			w[0] -= 1e-6
	
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
Function FitWrapper(folderStr,funcStr,coefStr,useCursors,useEps,useConstr)
	String folderStr,funcStr,coefStr
	Variable useCursors,useEps,useConstr

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
	Wave eps=$("epsilon_"+suffix)
	
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
	
	Variable useRes=0,isUSANS=0,val
	if(stringmatch(funcStr, "Smear*"))		// if it's a smeared function, need a struct
		useRes=1
	endif
	if(dimsize(resW,1) > 4)
		isUSANS=1
	endif
	// do not construct constraints for any of the coefficients that are being held
	// -- this will generate an "unknown error" from the curve fitting
	Make/O/T/N=0 constr
	if(useConstr)
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

	do
//		Variable t0 = stopMStimer(-2)		// corresponding print is at the end of the do-while loop (outside)


		if(useGenCurveFit)
		
#if !(exists("GenCurveFit"))
			// XOP not available
			useGenCurveFit = 0
			Abort "Genetic Optimiztion XOP not available. Reverting to normal optimization."	
#endif
			//send everything to a function, to reduce the clutter
			// useEps and useConstr are not needed
			// pass the structure to get the current waves, including the trimmed USANS matrix
			Variable chi,pt

			chi = DoGenCurveFit(useRes,useCursors,sw,fitYw,fs,funcStr,getHStr(hold),val,lolim,hilim,pt1,pt2)
			pt = val

			break
			
		endif
		
		
		if(useRes && useEps && useCursors && useConstr)		//do it all
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useEps && useCursors)		//no constr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /E=eps /D=fitYw /STRC=fs
			break
		endif
		
		if(useRes && useEps && useConstr)		//no crsr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useCursors && useConstr)		//no eps
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useCursors)		//no eps, no constr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /D=fitYw /STRC=fs
			break
		endif
		
		if(useRes && useEps)		//no crsr, no constr
//			Print "timing test for Cylinder_PolyRadius --- the supposedly threaded version ---"
//			Variable t0 = stopMStimer(-2)
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /STRC=fs
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
//			FuncFit/H=getHStr(hold) $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /STRC=fs
//			t0 = (stopMSTimer(-2) - t0)*1e-6
//			Printf  "CylPolyRad fit time using res and eps and NO THREADING time = %g seconds\r\r",t0
			break
		endif
	
		if(useRes && useConstr)		//no crsr, no eps
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes)		//just res
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /STRC=fs
			break
		endif
		
/////	same as above, but all without useRes (no /STRC flag)
		if(useEps && useCursors && useConstr)		//do it all
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr
			break
		endif
		
		if(useEps && useCursors)		//no constr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /E=eps /D=fitYw
			break
		endif
		
		if(useEps && useConstr)		//no crsr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr
			break
		endif
		
		if(useCursors && useConstr)		//no eps
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /D=fitYw /C=constr
			break
		endif
		
		if(useCursors)		//no eps, no constr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw[pcsr(A),pcsr(B)] /X=xw /W=sw /I=1 /D=fitYw
			break
		endif
		
		if(useEps)		//no crsr, no constr
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw
			break
		endif
	
		if(useConstr)		//no crsr, no eps
			FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /C=constr
			break
		endif
		
		//just a plain vanilla fit
		FuncFit/H=getHStr(hold) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw
	
	while(0)
	
//	t0 = (stopMSTimer(-2) - t0)*1e-6
//	Printf  "fit time = %g seconds\r\r",t0
	
	// append the fit
	// need to manage duplicate copies
	// Don't plot the full curve if cursors were used (set fitYw to NaN on entry...)
	String traces=TraceNameList("", ";", 1 )		//"" as first parameter == look on the target graph
	if(strsearch(traces,"FitYw",0) == -1)
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	else
		RemoveFromGraph FitYw
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	endif
	ModifyGraph lsize(FitYw)=2,rgb(FitYw)=(0,0,0)
	
	DoUpdate		//force update of table and graph with fitted values (why doesn't this work? - the table still does not update)
	
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
		
	//now re-write the results
	sprintf resultStr,"Chi^2 = %g  Sqrt(X^2/N) = %g",V_chisq,sqrt(V_chisq/V_Npnts)
	resultStr = PadString(resultStr,63,0x20)
	GroupBox grpBox_2 title=resultStr
	ControlUpdate/W=WrapperPanel grpBox_2
	sprintf resultStr,"FitErr = %s : FitQuit = %s",W_ErrorMessage(V_FitError),W_QuitMessage(V_FitQuitReason)
	resultStr = PadString(resultStr,63,0x20)
	GroupBox grpBox_3 title=resultStr
	ControlUpdate/W=WrapperPanel grpBox_3
	
	Variable yesSave=0,yesReport=0
	ControlInfo/W=WrapperPanel check_4
	yesReport = V_Value
	ControlInfo/W=WrapperPanel check_5
	yesSave = V_Value
	
	
	if(yesReport)
		String parStr=GetWavesDataFolder(cw,1)+ WaveList("*param*"+suffix, "", "TEXT:1," )		//this is *hopefully* one wave
		String topGraph= WinName(0,1)	//this is the topmost graph
	
		DoUpdate		//force an update of the graph before making a copy of it for the report

		W_GenerateReport(funcStr,folderStr,$parStr,cw,yesSave,V_chisq,W_sigma,V_npnts,V_FitError,V_FitQuitReason,V_startRow,V_endRow,topGraph)
	endif
	
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
		sprintf str, "%s = \t%g\t±\t%g\r", param[ii],ans[ii],sigwave[ii]
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
	if(WaveExists(dataXw))
		Notebook $nb picture={$topGraph(0, 0, 400, 300), -5, 1}, text="\r"
	//
	else		//must be 2D Gizmo
		Execute "ExportGizmo Clip"			//this ALWAYS is a PICT or BMP. Gizmo windows are different...
		LoadPict/Q/O "Clipboard",tmp_Gizmo
		Notebook $nb picture={tmp_Gizmo(0, 0, 400, 300), 0, 1}, text="\r"
	endif
	//Notebook Report picture={Table1, 0, 0}, text="\r"
	
	// show the top of the report
	Notebook $nb  selection= {startOfFile, startOfFile},  findText={"", 1}
	
	//save the notebook and the graphic file
	if(yesSave)
		String nameStr=CleanupName(func,0)
		nameStr = nameStr[0,8]	//shorten the name
		nameStr += "_"+dataname
		//make sure the name is no more than 31 characters
		namestr = namestr[0,30]		//if shorter than 31, this will NOT pad to 31 characters
		Print "file saved as ",nameStr
		SaveNotebook /O/P=home/S=2 $nb as nameStr
		//save the graph separately as a PICT file, 2x screen
		pictStr += nameStr
		pictStr = pictStr[0,28]		//need a shorter name - why?
//		DoWindow/F $topGraph
		// E=-5 is png @screen resolution
		// E=2 is PICT @2x screen resolution
///		SavePICT /E=-5/O/P=home /I/W=(0,0,3,3) as pictStr
		if(WaveExists(dataXw))
			SavePICT /E=-5/O/P=home/WIN=$topGraph /W=(0,0,400,300) as pictStr
		else
			Execute "ExportGizmo /P=home as \""+pictStr+"\""
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
			else
				//print "unchecked, change them back to 1D"
				Button button_0,pos={520,93},size={100,20},proc=DoTheFitButton,title="Do 1D Fit"
				Button button_1,pos={280,57},size={120,20},proc=PlotModelFunction,title="Plot 1D Function"
				Button button_2,pos={300,93},size={100,20},proc=AppendModelToTarget,title="Append 1D"
				Button button_3,pos={300,20},size={100,20},proc=W_LoadDataButtonProc,title="Load 1D Data"
				
				Button button_2D_0,disable=3	//hide the extra 2D buttons, and disable
				Button button_2D_1,disable=3
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

				HideInfo
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