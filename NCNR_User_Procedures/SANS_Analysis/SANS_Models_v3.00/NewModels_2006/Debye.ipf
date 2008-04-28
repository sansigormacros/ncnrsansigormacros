#pragma rtGlobals=1		// Use modern global access method.

// plots the Debye function for polymer scattering
//
Proc PlotDebye(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/O/D/N=(num) xwave_deb,ywave_deb
	xwave_deb = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	make/O/D coef_deb = {1.,50,0.001}
	make/O/T parameters_deb = {"scale","Rg (A)","bkg (cm-1)"}
	Edit parameters_deb,coef_deb
	ywave_deb := Debye(coef_deb,xwave_deb)
	Display ywave_deb vs xwave_deb
	ModifyGraph marker=29,msize=2,mode=4,log=1
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////
Proc PlotSmearedDebye()
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	make/O/D smear_coef_deb = {1.,50,0.001}
	make/O/T smear_parameters_deb = {"scale","Rg (A)","bkg (cm-1)"}
	Edit smear_parameters_deb,smear_coef_deb
	
	// output smeared intensity wave
	Duplicate/O $gQvals smeared_deb,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_deb

	smeared_deb := SmearedDebye(smear_coef_deb,$gQvals)
	Display smeared_deb vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End
///////////////////////////////////////////////////////////////


Function Debye(w,x) : FitFunc
	Wave w
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of gyration [Å]
	//[2] background	[cm-1]
	
	Variable scale,rg,bkg
	scale = w[0]
	rg = w[1]
	bkg = w[2]
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add in the background
	return (Pq+bkg)
End

// this is all there is to the smeared calculation!
Function SmearedDebye(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Debye,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End