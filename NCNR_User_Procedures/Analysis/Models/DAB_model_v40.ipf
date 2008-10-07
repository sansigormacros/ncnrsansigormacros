#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//	C. Glinka, 11-22-98
////////////////


								//Debye-Anderson-Brumberger


Proc PlotDAB_Model(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	 Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_DAB, ywave_DAB
	xwave_DAB =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_DAB = {10.0, 40, 1.0}
	make/o/t parameters_DAB = {"Scale Factor, A ", "Correlation Length (A)", "Incoherent Bgd (cm-1)"}
	Edit parameters_DAB, coef_DAB
	Variable/G root:g_DAB
	g_DAB  := DAB_Model(coef_DAB, ywave_DAB, xwave_DAB)
//	ywave_DAB  := DAB_Model(coef_DAB, xwave_DAB)
	Display ywave_DAB vs xwave_DAB
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Debye-Anderson-Brumberger Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("DAB_Model","coef_DAB","DAB")
End

////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedDAB_Model(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_DAB = {10.0, 40, 1.0}					//model  coef values to match unsmeared model above
	make/o/t smear_parameters_DAB = {"Scale Factor, A ", "Correlation Length (A)", "Incoherent Bgd (cm-1)"}// parameter names
	Edit smear_parameters_DAB,smear_coef_DAB					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_DAB,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_DAB							//
					
	Variable/G gs_DAB=0
	gs_DAB := fSmearedDAB_Model(smear_coef_DAB,smeared_DAB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_DAB vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Debye-Anderson-Brumberger Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedDAB_Model","smear_coef_DAB","DAB")
End

//AAO version
Function DAB_model(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("DAB_modelX")
	yw = DAB_modelX(cw,xw)
#else
	yw = fDAB_model(cw,xw)
#endif
	return(0)
End

Function fDAB_model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] correlation range
	//[2] incoherent background
//	give them nice names
	Variable Izero, range, incoh
	Izero = w[0]
	range = w[1]
	incoh = w[2]
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = Izero/(1 + (qval*range)^2)^2 + incoh
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////

// this is all there is to the smeared calculation!
Function SmearedDAB_Model(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(DAB_Model,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedDAB_Model(coefW,yW,xW)
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
	err = SmearedDAB_Model(fs)
	
	return (0)
End