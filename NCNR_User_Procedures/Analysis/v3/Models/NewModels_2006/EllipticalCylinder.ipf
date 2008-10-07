#pragma rtGlobals=1		// Use modern global access method.

///////////////////////////////////////////
// this function is for the form factor of an cylinder with an ellipsoidal cross-section
// and a uniform scattering length density
//
// 06 NOV 98 SRK
//
// re-written to not use MacOS XOP for calculation
// now requires the "new" version of GaussUtils that includes the generic quadrature routines
//
// 09 SEP 03 SRK
////////////////////////////////////////////////

Proc PlotEllipCylinderForm(num,qmin,qmax)
	Variable num=50,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
//	//constants needed for the integration if qtrap is used (in a separate procedure file!)
//	Variable/G root:gNumPoints=200
//	Variable/G root:gTol=1e-5
//	Variable/G root:gMaxIter=20
	//
	Make/O/D/n=(num) xwave_ecf,ywave_ecf
	xwave_ecf =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_ecf = {1.,20.,1.5,400,3.0e-6,0.0}
	make/o/t parameters_ecf = {"scale","minor radius (A)","nu = major/minor (-)","length (A)","SLD diff (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_ecf,coef_ecf
	ywave_ecf := EllipCylForm(coef_ecf,xwave_ecf)
	Display ywave_ecf vs xwave_ecf
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End
///////////////////////////////////////////////////////////

Proc PlotSmearedEllipCylForm()	
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ecf =  {1.,20.,1.5,400,3.0e-6,0.0}
	make/o/t smear_parameters_ecf = {"scale","minor radius (A)","nu = major/minor (-)","length (A)","SLD diff (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_ecf,smear_coef_ecf
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ecf,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_ecf	

	smeared_ecf := SmearedEllipCylForm(smear_coef_ecf,$gQvals)
	Display smeared_ecf vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

// the main function that calculates the form factor of an elliptical cylinder
// integrates EllipCyl_integrand, which itself is an integral function
// 20 points of quadrature seems to be sufficient for both integrals
//
Function EllipCylForm(w,x) 	: FitFunc
	Wave w
	Variable x
	
	Variable inten,scale,rad,nu,len,contr,bkg,ii
	scale = w[0]
	rad = w[1]
	nu = w[2]
	len = w[3]
	contr = w[4]
	bkg = w[5]
	
	inten = IntegrateFn20(EllipCyl_Integrand,0,1,w,x)
	
	//multiply by volume
	inten *= Pi*rad*rad*nu*len
	inten *= 1e8	//convert to 1/cm
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	return(inten)
End

//the outer integral
Function EllipCyl_Integrand(w,x,dum)
	Wave w
	Variable x,dum
	
	Variable val,rad,arg,len
	rad = w[1]
	len = w[3]
	
	arg = rad*sqrt(1-dum^2)
	duplicate/O w temp_w
	Wave temp_w=temp_w
	temp_w[1] = arg		//replace radius with transformed variable
	val = (1/pi)*IntegrateFn20(Phi_EC,0,Pi,temp_w,x)
	
	// equivalent to the 20-pt quadrature
//	val = (1/pi)*qtrap(Phi_EC,temp_w,x,0,Pi,1e-3,20)
	
	arg = x*len*dum/2
	if(arg==0)
		val *= 1
	else
		val *= sin(arg)*sin(arg)/arg/arg
	endif
	//Print "val=",val
	return(val)
End

//the inner integral
Function Phi_EC(w,x,dum)
	Wave w
	Variable x,dum
	
	Variable ans,arg,aa,nu
	aa = w[1]		// = rad*sqrt(1-dum^2)
	nu = w[2]
	arg = x*aa*sqrt( (1+nu^2)/2 + (1-nu^2)/2*cos(dum) )
	if(arg==0)
		ans = (2*0.5)^2		// == 1
	else
		ans = 2*2*bessJ(1,arg)*bessJ(1,arg)/arg/arg
	endif
	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedEllipCylForm(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(EllipCylForm,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
