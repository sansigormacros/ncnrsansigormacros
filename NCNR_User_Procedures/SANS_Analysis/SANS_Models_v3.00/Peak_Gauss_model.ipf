#pragma rtGlobals=1		// Use modern global access method.
////////////////////////////////////////////////////
//	J. Barker, 2-10-99
//////////////////
Proc PlotPeak_Gauss(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^1) for model: " 
	 Prompt qmax "Enter maximum q-value (Å^1) for model: "
//
	Make/O/D/n=(num) xwave_Peak_Gauss, ywave_Peak_Gauss
	xwave_Peak_Gauss =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Peak_Gauss = {100.0, 0.05,0.005, 1.0}
	make/o/t parameters_Peak_Gauss = {"Scale Factor, I0 ", "Peak position (Å^-1)", "Std Dev (Å^-1)","Incoherent Bgd (cm-1)"}
	Edit parameters_Peak_Gauss, coef_Peak_Gauss
	ywave_Peak_Gauss  := Peak_Gauss_Model(coef_Peak_Gauss, xwave_Peak_Gauss)
	Display ywave_Peak_Gauss vs xwave_Peak_Gauss
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (Å\\S-1\\M) "
	Label left "Peak - Gauss (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
//
End
////////////////////////////////////////////////////
Proc PlotSmearedPeak_Gauss()								//Peak_Gauss
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Peak_Gauss = {100.0, 0.05,0.005, 1.0}
	make/o/t smear_parameters_Peak_Gauss = {"Scale Factor, I0 ", "Peak position (Å^-1)", "Std Dev (Å^-1)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Peak_Gauss,smear_coef_Peak_Gauss					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_Peak_Gauss,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Peak_Gauss							//

	smeared_Peak_Gauss := SmearedPeak_Gauss_Model(smear_coef_Peak_Gauss,$gQvals)		// SMEARED function name
	Display smeared_Peak_Gauss vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Peak_Gauss Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro PlotSmearedPeak_Gauss

Function Peak_Gauss_model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] peak position
	//[2] Std Dev
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
	
	inten = I0*exp(-0.5*((qval-qpk)/dq)^2)+ bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////

// this is all there is to the smeared calculation!
Function SmearedPeak_Gauss_Model(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Peak_Gauss_model,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
