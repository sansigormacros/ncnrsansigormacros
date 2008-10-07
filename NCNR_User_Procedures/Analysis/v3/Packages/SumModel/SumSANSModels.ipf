#pragma rtGlobals=1		// Use modern global access method.

///////////////////////////////
//
//	17 DEC 04 SRK
//
// SumSANSModels.ipf
//
// 	Procedures to sum two SANS model into a function that can
// be used to fit SANS data sets. does this by soliciting input 
// from the user through a panel. Needs the function names, the
// names of the coefficients, and the number of parameters
// (same information for each model)
//
// 	Then the "Plot" button on the panel creates the function
// based on the panel selections. The model is named "Sum_Model",
// the coef/params are "coef_sum" and "parameters_sum", respectively
//
// 	The two original coef/param waves are tacked together. No attempt
// is made to remove duplicate parameters. This is up to the user
// to keep appropriate values fixed. (especially background)
//
// 	Changing the popup values will not immediately change the output
// function. The model must be re-plotted to "pick up" these new
// selections.
//
// TO FIX:
// - add a help button to call the help file
// ...(and write the documentation)
// - must be thoroughly tested...
//
///////////////////////////////

//create the panel as needed
//
Proc Init_SumModelPanel()
	DoWindow/F Sum_Model_Panel
	if(V_flag==0)
		NewDataFolder/O root:SumModel
		InitSMPGlobals()
		Sum_Model_Panel()
	endif
end

// create the globals that the panel needs
//
Function InitSMPGlobals()
	Variable/G root:SumModel:gNParMod1=0
	Variable/G root:SumModel:gNParMod2=0
end

Window Sum_Model_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(670,75,900,450)/K=1
	DoWindow/C Sum_Model_Panel
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1
	DrawText 14,17,"Sum Two Model Functions"
	PopupMenu popup1_0,pos={15,69},size={131,20},title="Model"
	PopupMenu popup1_0,mode=1,popvalue="Pick model 1",value= #"SumModelPopupList()"
	PopupMenu popup2_0,pos={15,190},size={131,20},title="Model"
	PopupMenu popup2_0,mode=1,popvalue="Pick model 2",value= #"SumModelPopupList()"
	PopupMenu popup1_1,pos={15,98},size={173,20},title="Coef"
	PopupMenu popup1_1,mode=1,popvalue="Pick coef for model 1",value= #"CoefPopupList()"
	PopupMenu popup2_1,pos={15,221},size={173,20},title="Coef"
	PopupMenu popup2_1,mode=1,popvalue="Pick coef for model 2",value= #"CoefPopupList()"
	GroupBox group1,pos={5,50},size={216,107},title="Function # 1"
	SetVariable setvar1,pos={14,128},size={140,15},title="# of Parameters"
	SetVariable setvar1,limits={0,20,1},value= root:SumModel:gNParMod1
	GroupBox group2,pos={5,171},size={216,107},title="Function # 2"
	SetVariable setvar2,pos={14,249},size={140,15},title="# of Parameters"
	SetVariable setvar2,limits={0,20,1},value= root:SumModel:gNParMod2
	Button button0,pos={36,299},size={150,20},proc=PlotSumButtonProc,title="Plot Summed Model"
	Button button1,pos={15,330},size={190,20},proc=PlotSmearedSumButtonProc,title="Plot Smeared Summed Model"
	Button button2,pos={190,23},size={25,20},proc=Sum_HelpButtonProc,title="?"
EndMacro

// show the availabel models
// but not the smeared versions
Function/S SumModelPopupList()
	String list
	list = FunctionList("!Smear*",";","KIND:14,NINDVARS:1")		//don't show smeared models
	list = RemoveFromList("Sum_Model", list  ,";")
	list = RemoveFromList("SANSModel_proto", list  ,";")
	return(list)
End

// show all the appropriate coefficient waves
Function/S CoefPopupList()
	String list
	list = WaveList("coef*",";","")
	list = RemoveFromList("coef_sum", list  ,";")
	return(list)
End

//button procedure
Function PlotSumButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "PlotSum_Model()"
End

//button procedure
Function PlotSmearedSumButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "PlotSmeared_Sum_Model()"
End

Function Sum_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic "Sum SANS Models"
End

//////////////////////////////


// this is the procedure that sets up the plot, just like
// a normal procedure for a model function
// - there's just a bit more going on, since it needs to 
// build things up based on the settings of the panel
Proc PlotSum_Model(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_sum,ywave_sum					
	xwave_sum = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	
	//make the coefficients and parameters based on the panel values	
	Variable nParam,n1,n2
	n1 = root:SumModel:gNParMod1
	n2 = root:SumModel:gNParMod2
	nParam = n1 + n2
	if(n1==0 || n2==0 || nparam==0)
		Abort "# of parameters must not be zero"
	endif
	// n is ok, keep extra copy so changing panel will not affect functions
	Variable/G root:SumModel:gN1=n1
	Variable/G root:SumModel:gN2=n2
	
	// these are the function names - make global so the fit function
	// can find them
	ControlInfo/W=Sum_Model_Panel popup1_0
	String/G root:SumModel:gModelStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_0
	String/G root:SumModel:gModelStr2=S_Value
	
	//these are the coefficent waves - local only
	ControlInfo/W=Sum_Model_Panel popup1_1
	String/G root:coefStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_1
	String/G root:coefStr2=S_Value
	
	Make/O/D/N=(nParam) coef_sum	
	coef_sum[0,(n1-1)] = $coefStr1
	coef_sum[n1,(n1+n2-1)] = $coefStr2[p-n1]
						
	make/o/t/N=(nParam) parameters_sum
	String paramStr1 = "parameters"+coefStr1[4,strlen(coefStr1)-1]
	String paramStr2 = "parameters"+coefStr2[4,strlen(coefStr2)-1]
	parameters_sum[0,(n1-1)] = $paramStr1
	parameters_sum[n1,(n1+n2-1)] = $paramStr2[p-n1]
	
	Edit parameters_sum,coef_sum								
	ywave_sum := Sum_Model(coef_sum,xwave_sum)			
	Display ywave_sum vs xwave_sum							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	Legend					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

// the usual macro for plotting the smeared model, updated
// to take input from the panel
Proc PlotSmeared_Sum_Model()								

	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	//make the coefficients and parameters based on the panel values	
	Variable nParam,n1,n2
	n1 = root:SumModel:gNParMod1
	n2 = root:SumModel:gNParMod2
	nParam = n1 + n2
	if(n1==0 || n2==0 || nparam==0)
		Abort "# of parameters must not be zero"
	endif
	// n is ok, keep extra copy so changing panel will not affect functions
	Variable/G root:SumModel:gN1=n1
	Variable/G root:SumModel:gN2=n2
	
	// these are the function names - make global so the fit function
	// can find them
	ControlInfo/W=Sum_Model_Panel popup1_0
	String/G root:SumModel:gModelStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_0
	String/G root:SumModel:gModelStr2=S_Value
	
	//these are the coefficent waves - local only
	ControlInfo/W=Sum_Model_Panel popup1_1
	String/G root:coefStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_1
	String/G root:coefStr2=S_Value
	
	Make/O/D/N=(nParam) smear_coef_sum	
	smear_coef_sum[0,(n1-1)] = $coefStr1
	smear_coef_sum[n1,(n1+n2-1)] = $coefStr2[p-n1]
						
	make/o/t/N=(nParam) smear_parameters_sum
	String paramStr1 = "parameters"+coefStr1[4,strlen(coefStr1)-1]
	String paramStr2 = "parameters"+coefStr2[4,strlen(coefStr2)-1]
	smear_parameters_sum[0,(n1-1)] = $paramStr1
	smear_parameters_sum[n1,(n1+n2-1)] = $paramStr2[p-n1]
				
	Edit smear_parameters_sum,smear_coef_sum					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sum,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sum							

	smeared_sum := Smeared_Sum_Model(smear_coef_sum,$gQvals)		
	Display smeared_sum vs $gQvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	Legend
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End


// this is the actual fitting function that is the 
// sum of the two selected models.
//
Function Sum_Model(w,x) :FitFunc
	Wave w;Variable x
	
	SVAR funcStr1=root:SumModel:gModelStr1		//string names of the functions, set by the macro
	SVAR funcStr2=root:SumModel:gModelStr2
	NVAR n1=root:SumModel:gN1			//number of coefficients, set by the macro
	NVAR n2=root:SumModel:gN2
	
	Variable retVal
	
	FUNCREF SANSModel_proto f1 = $funcStr1		//convert str to FCN
	FUNCREF SANSModel_proto f2 = $funcStr2
	// make temporary coefficient waves for each model
	Make/O/D/N=(n1) temp_cw1
	Make/O/D/N=(n2) temp_cw2
	temp_cw1 = w[p]
	temp_cw2 = w[p+n1]
	
	// calculate the sum
	retVal = f1(temp_cw1,x) + f2(temp_cw2,x)
	return(retVal)
end

// this is all there is to the smeared calculation!
Function Smeared_Sum_Model(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Sum_Model,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

//procedures to clean up after itself
Function UnloadSumModel()
	if (WinType("Sum_Model_Panel") == 7)
		DoWindow/K Sum_Model_Panel
	endif
	Execute/P "DELETEINCLUDE \"SumSANSModels\""
	Execute/P "COMPILEPROCEDURES "
end

Menu "Macros"
	Submenu "Packages"
		"Unload Sum SANS Models", UnloadSumModel()
	End
end
