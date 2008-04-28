#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//	J. Barker, 2-10-99
//////////////////////////////////
Proc PlotPower_Law_Model(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.2
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^1) for model: " 
	 Prompt qmax "Enter maximum q-value (Å^1) for model: "
//
	Make/O/D/n=(num) xwave_Power_Law, ywave_Power_Law
	xwave_Power_Law =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Power_Law = {1e-6, 4.0, 1.0}
	make/o/t parameters_Power_Law = {"Coefficient, A ", "(-)Power","Incoherent Bgd (cm-1)"}
	Edit parameters_Power_Law, coef_Power_Law
	Variable/G root:g_Power_Law
	g_Power_Law  := Power_Law_Model(coef_Power_Law, ywave_Power_Law, xwave_Power_Law)
//	ywave_Power_Law  := Power_Law_Model(coef_Power_Law, xwave_Power_Law)
	Display ywave_Power_Law vs xwave_Power_Law
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	ModifyGraph log(bottom)=1
	Label bottom "q (Å\\S-1\\M) "
	Label left "Power-Law (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Power_Law_Model","coef_Power_Law","Power_Law")
//
End

////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPower_Law_Model(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Power_Law = {1e-6, 4.0, 1.0}
	make/o/t smear_parameters_Power_Law = {"Coefficient, A ", "(-)Power","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Power_Law,smear_coef_Power_Law					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Power_Law,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Power_Law							//
					
		
	Variable/G gs_Power_Law=0
	gs_Power_Law := fSmearedPower_Law_Model(smear_coef_Power_Law,smeared_Power_Law,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_Power_Law vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Power_Law (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPower_Law_Model","smear_coef_Power_Law","Power_Law")
//
End     // end macro PlotSmearedPower_Law

//AAO version
Function Power_Law_Model(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("Power_Law_ModelX")
	yw = Power_Law_ModelX(cw,xw)
#else
	yw = fPower_Law_Model(cw,xw)
#endif
	return(0)
End

Function fPower_Law_Model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] Coefficient
	//[1] (-) Power
	//[2] incoherent background
//	give them nice names
	Variable A, m,bgd
	A = w[0]
	m = w[1]
	bgd = w[2]
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = A*qval^-m + bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////


// this is all there is to the smeared calculation!
Function SmearedPower_Law_Model(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(Power_Law_model,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPower_Law_Model(coefW,yW,xW)
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
	err = SmearedPower_Law_Model(fs)
	
	return (0)
End