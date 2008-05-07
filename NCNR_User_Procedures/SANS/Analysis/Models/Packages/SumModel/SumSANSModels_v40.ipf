#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0

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
// JUL 2007
// - data folder aware
// - AAO, structure aware
// (smeared fitting still broken)
// - created data folders are now buried in myGlobals
// DEC 07
// - created data folders are now :Packages:NIST:SumModel
//
///////////////////////////////

//create the panel as needed
//
Proc Init_SumModelPanel()
	DoWindow/F Sum_Model_Panel
	if(V_flag==0)
		if(!DataFolderExists("root:Packages:NIST"))
			NewDataFolder root:Packages:NIST
		endif
		NewDataFolder/O root:Packages:NIST:SumModel
		InitSMPGlobals()
		Sum_Model_Panel()
	endif
end

// create the globals that the panel needs
//
Function InitSMPGlobals()
	Variable/G root:Packages:NIST:SumModel:gNParMod1=0
	Variable/G root:Packages:NIST:SumModel:gNParMod2=0
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
	SetVariable setvar1,limits={0,20,1},value= root:Packages:NIST:SumModel:gNParMod1
	GroupBox group2,pos={5,171},size={216,107},title="Function # 2"
	SetVariable setvar2,pos={14,249},size={140,15},title="# of Parameters"
	SetVariable setvar2,limits={0,20,1},value= root:Packages:NIST:SumModel:gNParMod2
	Button button0,pos={36,299},size={150,20},proc=PlotSumButtonProc,title="Plot Summed Model"
	Button button1,pos={15,330},size={190,20},proc=PlotSmearedSumButtonProc,title="Plot Smeared Summed Model"
	Button button2,pos={190,23},size={25,20},proc=Sum_HelpButtonProc,title="?"
EndMacro

// show the available models
// but not the smeared versions
// not the f*
// not the *X XOPS
//
// KIND:10 should show only user-defined curve fitting functions
// - not XOPs
// - not other user-defined functions
Function/S SumModelPopupList()
	String list,tmp
	list = FunctionList("!Smear*",";","KIND:10")		//don't show smeared models
	
	list = RemoveFromList("Sum_Model", list  ,";")
	
	tmp = FunctionList("*_proto",";","KIND:10")		//prototypes
	list = RemoveFromList(tmp, list  ,";")

//	Print list
	tmp = GrepList(FunctionList("f*",";","KIND:10"),"^f")	
//	tmp = FunctionList("f*",";","KIND:10")		//point calculations
	
//	Print tmp
	
	list = RemoveFromList(tmp, list  ,";")
	
	// this should be a null string with KIND:10
	tmp = FunctionList("*X",";","KIND:10")		//XOPs, also point calculations
	list = RemoveFromList(tmp, list  ,";")
	
	// remove some odds and ends...
	tmp = "UpdateQxQy2Mat;"
	tmp += "MakeBSMask;"
	list = RemoveFromList(tmp, list  ,";")
	
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
	DisplayHelpTopic/Z/K=1 "Sum SANS Models"
	if(V_flag != 0)
		DoAlert 0, "The Sum SANS Models Help file can not be found"
	endif
End

//////////////////////////////


// this is the procedure that sets up the plot, just like
// a normal procedure for a model function
// - there's just a bit more going on, since it needs to 
// build things up based on the settings of the panel
Proc PlotSum_Model(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_sum,ywave_sum					
	xwave_sum = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	
	//make the coefficients and parameters based on the panel values	
	Variable nParam,n1,n2
	n1 = root:Packages:NIST:SumModel:gNParMod1
	n2 = root:Packages:NIST:SumModel:gNParMod2
	nParam = n1 + n2
	if(n1==0 || n2==0 || nparam==0)
		Abort "# of parameters must not be zero"
	endif
	// n is ok, keep extra copy so changing panel will not affect functions
	Variable/G root:Packages:NIST:SumModel:gN1=n1
	Variable/G root:Packages:NIST:SumModel:gN2=n2
	
	// these are the function names - make global so the fit function
	// can find them
	ControlInfo/W=Sum_Model_Panel popup1_0
	String/G root:Packages:NIST:SumModel:gModelStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_0
	String/G root:Packages:NIST:SumModel:gModelStr2=S_Value
	
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
	
	Variable/G root:g_sum
	g_sum := Sum_Model(coef_sum,ywave_sum,xwave_sum)			
	Display ywave_sum vs xwave_sum							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	Legend					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Sum_Model","coef_sum","sum")
	
	// additional step to make sure the "helper waves" are the right dimension, in case the user
	// has changed the functions (M. Laver)
	// if it exists here, redimension. otherwise, let the Wrapper create it
	String suffix = "sum"
	if(exists("Hold_"+suffix) == 1)
		Redimension/N=(nParam) $("epsilon_"+suffix),$("Hold_"+suffix)
		Redimension/N=(nParam) $("LoLim_"+suffix),$("HiLim_"+suffix)
		$("epsilon_"+suffix) = abs(coef_sum*1e-4) + 1e-10			//default eps is proportional to the coefficients
	endif
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
// the usual macro for plotting the smeared model, updated
// to take input from the panel
//
// - somewhat confusing as the unsmeared coefficients are in root:
// and all of the newly created smeared waves and coefficients are in the 
// selected data folder
//
Proc PlotSmeared_Sum_Model(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	//make the coefficients and parameters based on the panel values	
	Variable nParam,n1,n2
	n1 = root:Packages:NIST:SumModel:gNParMod1
	n2 = root:Packages:NIST:SumModel:gNParMod2
	nParam = n1 + n2
	if(n1==0 || n2==0 || nparam==0)
		Abort "# of parameters must not be zero"
	endif
	// n is ok, keep extra copy so changing panel will not affect functions
	Variable/G root:Packages:NIST:SumModel:gN1=n1
	Variable/G root:Packages:NIST:SumModel:gN2=n2
	
	// these are the function names - make global so the fit function
	// can find them
	ControlInfo/W=Sum_Model_Panel popup1_0
	String/G root:Packages:NIST:SumModel:gModelStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_0
	String/G root:Packages:NIST:SumModel:gModelStr2=S_Value
	
	//these are the coefficent waves - local only, in the current data folder!
	ControlInfo/W=Sum_Model_Panel popup1_1
	String/G coefStr1=S_Value
	ControlInfo/W=Sum_Model_Panel popup2_1
	String/G coefStr2=S_Value
	
	Make/O/D/N=(nParam) smear_coef_sum	
	smear_coef_sum[0,(n1-1)] = $("root:"+coefStr1)
	smear_coef_sum[n1,(n1+n2-1)] = $("root:"+coefStr2)[p-n1]
						
	make/o/t/N=(nParam) smear_parameters_sum
	String paramStr1 = "parameters"+coefStr1[4,strlen(coefStr1)-1]
	String paramStr2 = "parameters"+coefStr2[4,strlen(coefStr2)-1]
	smear_parameters_sum[0,(n1-1)] = $("root:"+paramStr1)
	smear_parameters_sum[n1,(n1+n2-1)] = $("root:"+paramStr2)[p-n1]
				
	Edit smear_parameters_sum,smear_coef_sum					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sum,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sum							
					
	Variable/G gs_sum=0
	gs_sum := fSmeared_Sum_Model(smear_coef_sum,smeared_sum,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sum vs $(str+"_q")									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	Legend
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("Smeared_Sum_Model","smear_coef_sum","sum")
	
	// additional step to make sure the "helper waves" are the right dimension, in case the user
	// has changed the functions (M. Laver)
	SetDataFolder $("root:"+str)
	String suffix = "sum"
	if(exists("Hold_"+suffix) == 1)
		Redimension/N=(nParam) $("epsilon_"+suffix),$("Hold_"+suffix)
		Redimension/N=(nParam) $("LoLim_"+suffix),$("HiLim_"+suffix)
		$("epsilon_"+suffix) = abs(smear_coef_sum*1e-4) + 1e-10			//default eps is proportional to the coefficients
	endif
	SetDataFolder root:
End


// this is the actual fitting function that is the 
// sum of the two selected models.
//
// this is an AAO function, there is no XOP version
// since it should be the sum of two XOPs
//
Function Sum_Model(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	SVAR funcStr1=root:Packages:NIST:SumModel:gModelStr1		//string names of the functions, set by the macro
	SVAR funcStr2=root:Packages:NIST:SumModel:gModelStr2
	NVAR n1=root:Packages:NIST:SumModel:gN1			//number of coefficients, set by the macro
	NVAR n2=root:Packages:NIST:SumModel:gN2
	
	Variable retVal
	
	FUNCREF SANSModelAAO_proto f1 = $funcStr1		//convert str to FCN
	FUNCREF SANSModelAAO_proto f2 = $funcStr2
	// make temporary coefficient waves for each model
	Make/O/D/N=(n1) temp_cw1
	Make/O/D/N=(n2) temp_cw2
	temp_cw1 = w[p]
	temp_cw2 = w[p+n1]
	
	// calculate the sum of each of the AAO functions
	Duplicate/O xw tmp_sum_yw1,tmp_sum_yw2
	
	f1(temp_cw1,tmp_sum_yw1,xw)
	f2(temp_cw2,tmp_sum_yw2,xw)
	yw = tmp_sum_yw1 + tmp_sum_yw2
	
	return(0)
end

// this is all there is to the smeared calculation!
Function Smeared_Sum_Model(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Sum_Model,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmeared_Sum_Model(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = Smeared_Sum_Model(fs)
	
	return (0)
End

//procedures to clean up after itself
Function UnloadSumModel()
	if (WinType("Sum_Model_Panel") == 7)
		DoWindow/K Sum_Model_Panel
	endif
	SVAR fileVerExt=root:Packages:NIST:SANS_ANA_EXTENSION
	String fname="SumSANSModels"
	Execute/P "DELETEINCLUDE \""+fname+fileVerExt+"\""
	Execute/P "COMPILEPROCEDURES "
end

Menu "SANS Models"
	Submenu "Packages"
		"Unload Sum SANS Models", UnloadSumModel()
	End
end
