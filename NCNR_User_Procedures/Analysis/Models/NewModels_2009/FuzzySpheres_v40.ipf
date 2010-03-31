#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1


// plots the form factor of spheres with a Gaussian radius distribution
// and a fuzzy surface
//
// M. Stieger, J. S. Pedersen, P. Lindner, W. Richtering, Langmuir 20 (2004) 7283-7292.
// M. Stieger, W. Richtering, J. S. Pedersen, P. Lindner, Journal of Chemical Physics 120(13) (2004) 6197-6206.
//
// potentially a lorentzian could be added to the low Q, if absolutely necessary
//
// SRK JUL 2009
//
// Include lorentzian term for *high* Q component of the scattering.
//
// AJJ Feb 2010

#include "Lorentz_model_v40"

Proc PlotFuzzySpheres(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_fuzz,ywave_fuzz
	xwave_fuzz = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_fuzz = {0.01,60,0.2,10,1e-6,3e-6,1,50,0.001}
	make/O/T parameters_fuzz = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","Lorentz Scale","Lorentz length","bkg (cm-1 sr-1)"}
	Edit parameters_fuzz,coef_fuzz
	
	Variable/G root:g_fuzz
	g_fuzz := FuzzySpheres(coef_fuzz,ywave_fuzz,xwave_fuzz)
	Display ywave_fuzz vs xwave_fuzz
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FuzzySpheres","coef_fuzz","parameters_fuzz","fuzz")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFuzzySpheres(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fuzz = {0.01,60,0.2,10,1e-6,3e-6,1,50,0.001}					
	make/o/t smear_parameters_fuzz = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","Lorentz Scale","Lorentz length","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_fuzz,smear_coef_fuzz					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fuzz,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fuzz							
					
	Variable/G gs_fuzz=0
	gs_fuzz := fSmearedFuzzySpheres(smear_coef_fuzz,smeared_fuzz,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fuzz vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFuzzySpheres","smear_coef_fuzz","smear_parameters_fuzz","fuzz")
End
	



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FuzzySpheres(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FuzzySpheresX")
	yw = FuzzySpheresX(cw,xw)
#else
	yw = fFuzzySpheres(cw,xw)
#endif
	return(0)
End

Function fFuzzySpheres(w,xx) : FitFunc
	wave w
	variable xx
	
	Variable scale,rad,pd,sig,rho,rhos,bkg,delrho,sig_surf,lor_sf,lor_len
	
	//set up the coefficient values
	scale=w[0]
	rad=w[1]
	pd=w[2]
	sig=pd*rad
	sig_surf = w[3]
	rho=w[4]
	rhos=w[5]
	delrho=rho-rhos
	bkg=w[8]

	
	//could use 5 pt quadrature to integrate over the size distribution, since it's a gaussian
	//currently using 20 pts...
	Variable va,vb,ii,zi,nord,yy,summ,inten
	Variable bes,f,vol,f2
	String weightStr,zStr
	
	//select number of gauss points by setting nord=20 or76 points
	nord = 20
//	nord = 76
	
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
	va = -4*sig + rad
	if (va<0)
		va=0		//to avoid numerical error when  va<0 (-ve q-value)
	endif
	vb = 4*sig +rad
	
	summ = 0.0		// initialize integral
	for(ii=0;ii<nord;ii+=1)
		// calculate Gauss points on integration interval (r-value for evaluation)
		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0
		
		// calculate sphere scattering
		//
		//handle q==0 separately
		If(xx==0)
			f2 = 4/3*pi*zi^3*delrho*delrho*1e8
			f2 *= exp(-0.5*sig_surf*sig_surf*xx*xx)
			f2 *= exp(-0.5*sig_surf*sig_surf*xx*xx)
		else
			bes = 3*(sin(xx*zi)-xx*zi*cos(xx*zi))/xx^3/zi^3
			vol = 4*pi/3*zi^3
			f = vol*bes*delrho		// [=] A
			f *= exp(-0.5*sig_surf*sig_surf*xx*xx)
			// normalize to single particle volume, convert to 1/cm
			f2 = f * f / vol * 1.0e8		// [=] 1/cm
		endif
	
		yy = gauWt[ii] *  Gauss_f_distr(sig,rad,zi) * f2
		yy *= 4*pi/3*zi*zi*zi		//un-normalize by current sphere volume
		
		summ += yy		//add to the running total of the quadrature
   	endfor
// calculate value of integral to return
	inten = (vb-va)/2.0*summ
	
	//re-normalize by polydisperse sphere volume
	inten /= (4*pi/3*rad^3)*(1+3*pd^2)
	
	inten *= scale
	
	//Lorentzian term
	Make/O/N=3 tmp_lor
	tmp_lor[0] = w[6]
	tmp_lor[1] = w[7]
	tmp_lor[2] = 0
	
	inten+=fLorentz_model(tmp_lor,xx)
	
	inten+=bkg
	
	Return(inten)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFuzzySpheres(coefW,yW,xW)
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
	err = SmearedFuzzySpheres(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedFuzzySpheres(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FuzzySpheres,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End



Function Gauss_f_distr(sig,avg,pt)
	Variable sig,avg,pt
	
	Variable retval
	
	retval = (1/ ( sig*sqrt(2*Pi)) )*exp(-(avg-pt)^2/sig^2/2)
	return(retval)
End