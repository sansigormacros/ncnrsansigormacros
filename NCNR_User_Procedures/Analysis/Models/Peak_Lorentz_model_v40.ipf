#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//	J. Barker, 2-10-99
////////////////////////////////////
Proc PlotPeak_Lorentz_Model(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	 Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_Peak_Lorentz, ywave_Peak_Lorentz
	xwave_Peak_Lorentz =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Peak_Lorentz = {100.0, 0.05,0.005, 1.0}
	make/o/t parameters_Peak_Lorentz = {"Scale Factor, I0 ", "Peak position (A^-1)", "Peak hwhm (A^-1)","Incoherent Bgd (cm-1)"}
	Edit parameters_Peak_Lorentz, coef_Peak_Lorentz
	Variable/G root:g_Peak_Lorentz
	g_Peak_Lorentz  := Peak_Lorentz_Model(coef_Peak_Lorentz, ywave_Peak_Lorentz,xwave_Peak_Lorentz)
//	ywave_Peak_Lorentz  := Peak_Lorentz_Model(coef_Peak_Lorentz, xwave_Peak_Lorentz)
	Display ywave_Peak_Lorentz vs xwave_Peak_Lorentz
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Peak - Lorentzian (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Peak_Lorentz_Model","coef_Peak_Lorentz","parameters_Peak_Lorentz","Peak_Lorentz")
//
End

////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPeak_Lorentz_Model(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Peak_Lorentz = {100.0, 0.05,0.005, 1.0}
	make/o/t smear_parameters_Peak_Lorentz = {"Scale Factor, I0 ", "Peak position (A^-1)", "Peak hwhm (A^-1)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Peak_Lorentz,smear_coef_Peak_Lorentz					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Peak_Lorentz,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Peak_Lorentz							//					
		
	Variable/G gs_Peak_Lorentz=0
	gs_Peak_Lorentz := fSmearedPeak_Lorentz_Model(smear_coef_Peak_Lorentz,smeared_Peak_Lorentz,smeared_qvals)	//this wrapper fills the STRUCT

	Display smeared_Peak_Lorentz vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Peak_Lorentz Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)	
	
	AddModelToStrings("SmearedPeak_Lorentz_Model","smear_coef_Peak_Lorentz","smear_parameters_Peak_Lorentz","Peak_Lorentz")
End


//AAO version
Function Peak_Lorentz_model(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("Peak_Lorentz_modelX")
	yw = Peak_Lorentz_modelX(cw,xw)
#else
	yw = fPeak_Lorentz_model(cw,xw)
#endif
	return(0)
End

Function fPeak_Lorentz_model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] peak position
	//[2] peak hwhm
	//[3] incoherent background
//	give them nice names
	Variable I0, qpk, dq,bgd
	I0 = w[0]
	qpk = w[1]
	dq = w[2]
	bgd = w[3]
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = I0/(1 + ((qval-qpk)/dq)^2) + bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////

// this is all there is to the smeared calculation!
Function SmearedPeak_Lorentz_Model(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(Peak_Lorentz_model,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPeak_Lorentz_Model(coefW,yW,xW)
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
	err = SmearedPeak_Lorentz_Model(fs)
	
	return (0)
End