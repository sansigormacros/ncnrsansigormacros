#pragma rtGlobals=1		// Use modern global access method.
////////////////////////////////////////////////////
//	C. Glinka, 11-22-98
////////////////

Proc PlotDAB(num,qmin,qmax)
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
	ywave_DAB  := DAB_Model(coef_DAB, xwave_DAB)
	Display ywave_DAB vs xwave_DAB
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Debye-Anderson-Brumberger Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End
////////////////////////////////////////////////////
Proc PlotSmearedDAB()								//Debye-Anderson-Brumberger
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_DAB = {10.0, 40, 1.0}					//model  coef values to match unsmeared model above
	make/o/t smear_parameters_DAB = {"Scale Factor, A ", "Correlation Length (A)", "Incoherent Bgd (cm-1)"}// parameter names
	Edit smear_parameters_DAB,smear_coef_DAB					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_DAB,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_DAB							//

	smeared_DAB := SmearedDAB_Model(smear_coef_DAB,$gQvals)		// SMEARED function name
	Display smeared_DAB vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Debye-Anderson-Brumberger Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro PlotSmearedDAB

Function DAB_model(w,x) : FitFunc
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
Function SmearedDAB_Model(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(DAB_Model,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
