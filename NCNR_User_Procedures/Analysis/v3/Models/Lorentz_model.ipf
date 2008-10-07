#pragma rtGlobals=1		// Use modern global access method.
////////////////////////////////////////////////////
//	J. Barker, 2-10-99
/////////////////////////////
Proc Plot_Lorentz(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	 Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_Lorentz, ywave_Lorentz
	xwave_Lorentz =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Lorentz = {100.0, 50.0, 1.0}
	make/o/t parameters_Lorentz = {"Scale Factor, I0 ", "Screening Length (A)","Incoherent Bgd (cm-1)"}
	Edit parameters_Lorentz, coef_Lorentz
	ywave_Lorentz  := Lorentz_Model(coef_Lorentz, xwave_Lorentz)
	Display ywave_Lorentz vs xwave_Lorentz
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Lorentzian (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

////////////////////////////////////////////////////
Proc PlotSmeared_Lorentz()								//Lorentz
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Lorentz = {100.0, 50.0, 1.0}
	make/o/t smear_parameters_Lorentz = {"Scale Factor, I0 ", "Screening Length (A)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Lorentz,smear_coef_Lorentz					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_Lorentz,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Lorentz							//

	smeared_Lorentz := Smeared_Lorentz_Model(smear_coef_Lorentz,$gQvals)		// SMEARED function name
	Display smeared_Lorentz vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Lorentz Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro PlotSmearedPeak_Lorentz

Function Lorentz_model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] screening length
	//[2] incoherent background
//	give them nice names
	Variable I0, L,bgd
	I0 = w[0]
	L = w[1]
	bgd = w[2]
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = I0/(1 + (qval*L)^2) + bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////


// this is all there is to the smeared calculation!
Function Smeared_Lorentz_Model(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Lorentz_model,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
	
