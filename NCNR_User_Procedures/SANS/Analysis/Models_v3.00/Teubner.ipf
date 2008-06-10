#pragma rtGlobals=1		// Use modern global access method.


////////////////////////////////////////////////
// this procedure is for the Teubner-Strey Model
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotTeubnerStreyModel(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_ts,ywave_ts
	xwave_ts =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_ts = {0.1,-30,5000,0.1}
	make/o/t parameters_ts = {"scale (a2)","c1","c2","bkg"}
	Edit parameters_ts,coef_ts
	ywave_ts := TeubnerStreyModel(coef_ts,xwave_ts)
	Display ywave_ts vs xwave_ts
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedTeubnerStreyModel()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ts = {0.1,-30,5000,0.1}
	make/o/t smear_parameters_ts = {"scale (a2)","c1","c2","bkg"}
	Edit smear_parameters_ts,smear_coef_ts
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ts,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_ts

	smeared_ts := SmearedTeubnerStreyModel(smear_coef_ts,$gQvals)
	Display smeared_ts vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function TeubnerStreyModel(w,x) : FitFunc
	Wave w;Variable x
	
	//Varialbes are:
	//[0]	scale factor a2
	//[1] 	coeff c1
	//[2]	coeff c2
	//[3] 	incoh. background
	
	Variable inten,q2,q4
	
	q2 = x*x
	q4 = q2*q2
	inten = 1.0/(w[0]+w[1]*q2+w[2]*q4)
	inten += w[3]
	
	return (inten)
	
End	

Macro TeubnerStreyLengths()
	If(exists("coef_ts")!=1)		//coefficients don't exist
		Abort "You must plot the Teubner-Strey model before calculating the lengths"
	Endif
	// calculate the correlation length and the repeat distance
	Variable a2,c1,c2,xi,dd
	a2 = coef_ts[0]
	c1 = coef_ts[1]
	c2 = coef_ts[2]
	
	xi = 0.5*sqrt(a2/c2) + c1/4/c2
	xi = 1/sqrt(xi)
	
	dd = 0.5*sqrt(a2/c2) - c1/4/c2
	dd = 1/sqrt(dd)
	dd *=2*Pi
	
	Printf "The correlation length (the dispersion of d) xi = %g A\r",xi
	Printf "The quasi-periodic repeat distance, d = %g A\r",dd
	
End
// this is all there is to the smeared calculation!
Function SmearedTeubnerStreyModel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(TeubnerStreyModel,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
