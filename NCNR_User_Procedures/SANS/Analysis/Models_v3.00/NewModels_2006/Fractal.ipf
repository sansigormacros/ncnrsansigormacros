#pragma rtGlobals=1		// Use modern global access method.

// plots scattering from a mass fractal object
// uses the model of Teixeria
//
// REFERENCE: J. Appl. Cryst. vol 21, p781-785
//  Uses eq.1, 4, and 16
//
// Macro for fractal parameters added JGB 2004

Proc PlotFractal(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fra,ywave_fra					
	xwave_fra = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_fra = {0.05,5,2,100,2e-6,6.35e-6,0}						
	make/o/t parameters_fra = {"Volume Fraction (scale)","Block Radius (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}		
	Edit parameters_fra,coef_fra								
	ywave_fra := Fractal(coef_fra,xwave_fra)			
	Display ywave_fra vs xwave_fra							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedFractal()
	
	// if no gQvals wave, data must not have been loaded => abort
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fractal =  {0.05,5,2,100,2e-6,6.35e-6,0}
	make/o/t smear_parameters_fractal = {"Volume Fraction (scale)","Block Radius (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}
	Edit smear_parameters_fractal,smear_coef_fractal					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_fractal,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fractal							//

	smeared_fractal := SmearedFractal(smear_coef_fractal,$gQvals)
	Display smeared_fractal vs smeared_qvals		
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro 

//calculates the physical parameters related to the 
//model parameters. See the reference at the top of the 
//file for details
Macro NumberDensity_Fractal()
	
	Variable nden,phi,r0,Df,corr,s0,vpoly,i0,rg
	
	if(WaveExists(coef_fra)==0)
		abort "You need to plot the model first to create the coefficient table"
	Endif
	
	phi = coef_fra[0]   // volume fraction of building blocks
	r0 = coef_fra[1]    // building block radius
	Df = coef_fra[2]    // fractal dimension
	corr = coef_fra[3]  // fractal correlation length (of cluster)
	
	Print "mean building block radius (A) = ",r0
	Print "volume fraction = ",phi
	
 //  average particle volume   	
	vpoly = 4*Pi/3*r0^3
	nden = phi/vpoly		//nden in 1/A^3
	i0 = 1.0e8*phi*vpoly*(coef_fra[4]-coef_fra[5])^2  // 1/cm/sr
	rg = corr*( Df*(Df+1)/2 )^0.5
	s0 = exp(gammln(Df+1))*(corr/r0)^Df
	Print "number density (A^-3) = ",nden
	Print "Guinier radius (A) = ",rg
	Print "Aggregation number G = ",s0
	Print "Forward cross section of building blocks (cm-1 sr-1) I(0) = ",i0
	Print "Forward cross section of clusters (cm-1 sr-1) I(0) = ",i0*s0
End

//fractal scattering function
Function Fractal(w,x) :FitFunc
	wave w
	variable x
	
	variable r0,Df,corr,phi,sldp,sldm,bkg
	variable pq,sq,ans
	phi=w[0]   // volume fraction of building block spheres...
	r0=w[1]    //  radius of building block
	Df=w[2]     //  fractal dimension
	corr=w[3] //  correlation length of fractal-like aggregates
	sldp = w[4] // SLD of building block
	sldm = w[5] // SLD of matrix or solution
	bkg=w[6]  //  flat background
	
	//calculate P(q) for the spherical subunits, units cm-1 sr-1
	pq = 1.0e8*phi*4/3*pi*r0^3*(sldp-sldm)^2*(3*(sin(x*r0) - x*r0*cos(x*r0))/(x*r0)^3)^2

	//calculate S(q)
	sq = Df*exp(gammln(Df-1))*sin((Df-1)*atan(x*corr))
	sq /= (x*r0)^Df * (1 + 1/(x*corr)^2)^((Df-1)/2)
	sq += 1
	//combine and return
	ans = pq*sq + bkg

	return (ans)
End

//the smeared model calculation
Function SmearedFractal(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(Fractal,$sq,$qb,$sh,$gQ,w,x)	

	return(ans)
End