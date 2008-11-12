#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

//
// empirical model to fit two power law regions. Model is a "v". No attempt is made to 
// smooth the transition at the crossover q-value. The two power law slopes are the important
// results, not fudging some crossover function.
//
// JUN 2008 SRK

//////////////////////////////////
Proc PlotTwoPowerLaw(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.2
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^1) for model: " 
	 Prompt qmax "Enter maximum q-value (Å^1) for model: "
//
	Make/O/D/n=(num) xwave_TwoPowerLaw, ywave_TwoPowerLaw
	xwave_TwoPowerLaw =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_TwoPowerLaw = {1e-6, 4, 1, 0.01, 0}
	make/o/t parameters_TwoPowerLaw = {"Coefficient, A ", "(-)Low Q Power","(-) high Q Power","Crossover Qc (A-1)","Incoherent Bgd (cm-1)"}
	Edit parameters_TwoPowerLaw, coef_TwoPowerLaw
	Variable/G root:g_TwoPowerLaw
	g_TwoPowerLaw  := TwoPowerLaw(coef_TwoPowerLaw, ywave_TwoPowerLaw, xwave_TwoPowerLaw)
//	ywave_TwoPowerLaw  := TwoPowerLaw(coef_TwoPowerLaw, xwave_TwoPowerLaw)
	Display ywave_TwoPowerLaw vs xwave_TwoPowerLaw
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	ModifyGraph log(bottom)=1
	Label bottom "q (Å\\S-1\\M) "
	Label left "Power-Law (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("TwoPowerLaw","coef_TwoPowerLaw","TwoPowerLaw")
//
End

////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedTwoPowerLaw(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_TwoPowerLaw = {1e-6, 4, 1, 0.01, 0}
	make/o/t smear_parameters_TwoPowerLaw = {"Coefficient, A ", "(-)Low Q Power","(-) high Q Power","Crossover Qc (A-1)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_TwoPowerLaw,smear_coef_TwoPowerLaw					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_TwoPowerLaw,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_TwoPowerLaw							//
					
		
	Variable/G gs_TwoPowerLaw=0
	gs_TwoPowerLaw := fSmearedTwoPowerLaw(smear_coef_TwoPowerLaw,smeared_TwoPowerLaw,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_TwoPowerLaw vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "TwoPowerLaw (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedTwoPowerLaw","smear_coef_TwoPowerLaw","TwoPowerLaw")
//
End     // end macro PlotSmearedTwoPowerLaw

//AAO version
Function TwoPowerLaw(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("TwoPowerLawX")
	yw = TwoPowerLawX(cw,xw)
#else
	yw = fTwoPowerLaw(cw,xw)
#endif
	return(0)
End

Function fTwoPowerLaw(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] Coefficient
	//[1] (-) Power @ low Q
	//[2] (-) Power @ high Q
	//[3] crossover Q-value
	//[4] incoherent background
//	give them nice names
	Variable A, m1,m2,qc,bgd,scale
	A = w[0]
	m1 = w[1]
	m2 = w[2]
	qc = w[3]
	bgd = w[4]
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	if(qval<=qc)
		inten = A*qval^-m1
	else
		scale = A*qc^-m1 / qc^-m2
		inten = scale*qval^-m2
	endif
	
	inten += bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////


// this is all there is to the smeared calculation!
Function SmearedTwoPowerLaw(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(TwoPowerLaw,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedTwoPowerLaw(coefW,yW,xW)
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
	err = SmearedTwoPowerLaw(fs)
	
	return (0)
End