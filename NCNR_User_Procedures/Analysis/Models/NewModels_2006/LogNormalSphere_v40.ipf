#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

#include "sphere_v40"
// plots the form factor of spherical particles with a log-normal radius distribution
//
// for the integration it may be better to use adaptive routine

//Proc to setup data and coefficients to plot the model
Proc PlotLogNormalSphere(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_lns,ywave_lns
	xwave_lns = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_lns = {0.01,60,0.2,1e-6,2e-6,0}
	make/O/T parameters_lns = {"Volume Fraction (scale)","exp(mu)=median Radius (A)","sigma","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_lns,coef_lns
	
	Variable/G root:g_lns
	g_lns := LogNormalSphere(coef_lns,ywave_lns,xwave_lns)
	Display ywave_lns vs xwave_lns
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("LogNormalSphere","coef_lns","parameters_lns","lns")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedLogNormalSphere(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_lns = {0.01,60,0.2,1e-6,2e-6,0}					
	make/o/t smear_parameters_lns = {"Volume Fraction (scale)","exp(mu)=median Radius (A)","sigma","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}		
	Edit smear_parameters_lns,smear_coef_lns					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_lns,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_lns							
					
	Variable/G gs_lns=0
	gs_lns := fSmearedLogNormalSphere(smear_coef_lns,smeared_lns,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_lns vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedLogNormalSphere","smear_coef_lns","smear_parameters_lns","lns")
End




//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function LogNormalSphere(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("LogNormalSphereX")
	yw = LogNormalSphereX(cw,xw)
#else
	yw = fLogNormalSphere(cw,xw)
#endif
	return(0)
End


// calculates the model at each q-value by integrating over the normalized size distribution
// integration is done by gauss quadrature of either 20 or 76 points (nord)
// 76 points is slower, but reccommended to remove high-q oscillations
//
Function fLogNormalSphere(w,xx): FitFunc
	wave w
	variable xx
	
	Variable scale,rad,sig,rho,rhos,bkg,delrho,mu,r3
	
	//set up the coefficient values
	scale=w[0]
	rad=w[1]		//rad is the median radius
	mu = ln(w[1])
	sig=w[2]
	rho=w[3]
	rhos=w[4]
	delrho=rho-rhos
	bkg=w[5]
	
//temp set scale=1 and bkg=0 for quadrature calc
	Make/O/D/N=4 sphere_temp
	sphere_temp[0] = 1
	sphere_temp[1] = rad		//changed in loop
	sphere_temp[2] = rho
	sphere_temp[3] = rhos
	sphere_temp[4] = 0
	
	//currently using 20 pts...
	Variable va,vb,ii,zi,nord,yy,summ,inten
	String weightStr,zStr
	
	//select number of gauss points by setting nord=20 or76 points
//	nord = 20
	nord = 76
	
	weightStr = "gauss"+num2str(nord)+"wt"
	zStr = "gauss"+num2str(nord)+"z"
	
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave gauWt = $weightStr
		Wave gauZ = $zStr		// wave references to pass
		if(nord==20)
			Make20GaussPoints(gauWt,gauZ)
		else
			Make76GaussPoints(gauWt,gauZ)
		endif	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave gauWt = $weightStr
		Wave gauZ = $zStr		// create the wave references
	endif
	
	// end points of integration
	// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
	// +/- 3 sigq catches 99.73% of distrubution
	// change limits (and spacing of zi) at each evaluation based on R()
	//integration from va to vb
	
//	va = -3*sig + rad
	va = -3.5*sig +mu		//in ln(R) space
	va = exp(va)			//in R space
	if (va<0)
		va=0		//to avoid numerical error when  va<0 (-ve q-value)
	endif
//	vb = 3*exp(sig) +rad
	vb = 3.5*sig*(1+sig)+ mu
	vb = exp(vb)
	
	summ = 0.0		// initialize integral
	Make/O/N=1 tmp_yw,tmp_xw
	tmp_xw[0] = xx
	for(ii=0;ii<nord;ii+=1)
		// calculate Gauss points on integration interval (r-value for evaluation)
		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0
		sphere_temp[1] = zi
		// calculate sphere scattering
		SphereForm(sphere_temp,tmp_yw,tmp_xw)			//AAO calculation, one point wave
		yy = gauWt[ii] *  LogNormal_distr(sig,mu,zi) * tmp_yw[0]
		yy *= 4*pi/3*zi*zi*zi		//un-normalize by current sphere volume
		
		summ += yy		//add to the running total of the quadrature
   	endfor
// calculate value of integral to return
	inten = (vb-va)/2.0*summ
	
	//re-normalize by polydisperse sphere volume
	//third moment
	r3 = exp(3*mu + 9/2*sig^2)		// <R^3> directly
	inten /= (4*pi/3*r3)		//polydisperse volume
	
	inten *= scale
	inten+=bkg
	
	Return(inten)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedLogNormalSphere(coefW,yW,xW)
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
	err = SmearedLogNormalSphere(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedLogNormalSphere(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(LogNormalSphere,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	


// normalization is correct, using 3rd moment of lognormal distribution
//
Function LogNormal_distr(sig,mu,pt)
	Variable sig,mu,pt
	
	Variable retval
	
	retval = (1/ ( sig*pt*sqrt(2*pi)) )*exp( -0.5*((ln(pt) - mu)^2)/sig^2 )
	return(retval)
End

//calculates number density given the coefficients of the lognormal distribution
// the scale factor is the volume fraction
// then nden = phi/<V> where <V> is calculated using the 3rd moment of the radius
Macro NumberDensity_LogN()
	
	Variable nden,r3,rg,sv,i0,ravg,rpk
	
	if(Exists("coef_lns")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	Print "median radius (A) = ",coef_lns[1]
	Print "sigma = ",coef_lns[2]
	Print "volume fraction = ",coef_lns[0]
	
	r3 = exp(3*ln(coef_lns[1]) + 9/2*coef_lns[2]^2)		// <R^3> directly,[A^3]
	nden = coef_lns[0]/(4*pi/3*r3)		//nden in 1/A^3
	ravg = exp(ln(coef_lns[1]) + 0.5*coef_lns[2]^2)
	rpk = exp(ln(coef_lns[1]) - coef_lns[2]^2)
	rg = (3./5.)^0.5*exp(ln(coef_lns[1]) + 7.*coef_lns[2]^2)
	sv = 1.0e8*3*coef_lns[0]*exp(-ln(coef_lns[1]) - 2.5*coef_lns[2]^2)
	i0 = 1.0e8*(4*pi/3)*coef_lns[0]*(coef_lns[3]-coef_lns[4])^2*exp(3*ln(coef_lns[1]) + 13.5*coef_lns[2]^2)
	
	Print "number density (A^-3) = ",nden
	Print "mean radius (A) = ",ravg
	Print "peak dis. radius (A) = ",rpk
	Print "Guinier radius (A) = ",rg
	Print "Interfacial surface area / volume (cm-1) Sv = ",sv
	Print "Forward cross section (cm-1 sr-1) I(0) = ",i0
End

// plots the lognormal distribution based on the coefficient values
// a static calculation, so re-run each time
//
Macro PlotLogNormalDistribution()

	variable sig,mu,maxr
	
	if(Exists("coef_lns")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	sig=coef_lns[2]
	mu = ln(coef_lns[1])
	
	Make/O/D/N=1000 lognormal_distribution
	maxr = 5*sig*(1+sig)+ mu
	maxr = exp(maxr)
	SetScale/I x, 0, maxr, lognormal_distribution
	lognormal_distribution = LogNormal_distr(sig,mu,x)
	Display lognormal_distribution
	modifygraph log(bottom)=1
	legend
End