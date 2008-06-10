#pragma rtGlobals=1		// Use modern global access method.
////////////////////////////////////////////////////
//	J. Barker, 2-10-99
//////////////////////////////////
Proc PlotPower_Law(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.2
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	 Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_Power_Law, ywave_Power_Law
	xwave_Power_Law =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Power_Law = {1e-6, 4.0, 1.0}
	make/o/t parameters_Power_Law = {"Coefficient, A ", "(-)Power","Incoherent Bgd (cm-1)"}
	Edit parameters_Power_Law, coef_Power_Law
	ywave_Power_Law  := Power_Law_Model(coef_Power_Law, xwave_Power_Law)
	Display ywave_Power_Law vs xwave_Power_Law
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	ModifyGraph log(bottom)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Power-Law (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
//
End
////////////////////////////////////////////////////
Proc PlotSmearedPower_Law()								// Power-Law
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Power_Law = {1e-6, 4.0, 1.0}
	make/o/t smear_parameters_Power_Law = {"Coefficient, A ", "(-)Power","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Power_Law,smear_coef_Power_Law					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_Power_Law,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Power_Law							//

	smeared_Power_Law := SmearedPower_Law_Model(smear_coef_Power_Law,$gQvals)		// SMEARED function name
	Display smeared_Power_Law vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Power_Law (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro PlotSmearedPower_Law

Function Power_Law_model(w,x) : FitFunc
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
Function SmearedPower_Law_Model(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Power_Law_model,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
