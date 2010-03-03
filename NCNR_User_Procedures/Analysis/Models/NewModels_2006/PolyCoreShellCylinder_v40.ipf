#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// This function is for the form factor of a right circular
// cylinder with core/shell scattering length density profile. 
// Note that a different shell thickness is added on the edge of
// the particle, compared to the face.  
// Furthermore the scattering is convoluted by a log normal (or Schultz)
// distribution that creates polydispersity for the radius of the
// particle core.
// 
// 30 Apr 2003 Andrew Nelson
//
// 17 MAY 2006 SRK - changed to normalize to total particle dimensions
// 						(core+shell)
//
// The Gaussian quadrature routines are based on those in the
// current NIST macros. 
/////////////////////////////////////////////////////////////////

Proc PlotPolyCoShCylinder(num,qmin,qmax)
	Variable num=100,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_CSCpr,ywave_CSCpr
	xwave_CSCpr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_CSCpr = {0.01,150,0.10,10,20.,10.,4.0e-6,1.0e-6,4.0e-6,0.001}
	make/o/t parameters_CSCpr = {"scale","mean CORE radius (A)","radial polydispersity (sigma)","CORE length (A)","radial shell thickness (A)","face shell thickness (A)","SLD core (A^-2)","SLD shell (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit/W=(410,44,757,306)  parameters_CSCpr,coef_CSCpr
	ModifyTable width(parameters_CSCpr)=162
	
	Variable/G root:g_CSCpr
	g_CSCpr := PolyCoShCylinder(coef_CSCpr,ywave_CSCpr,xwave_CSCpr)
	Display ywave_CSCpr vs xwave_CSCpr
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCoShCylinder","coef_CSCpr","parameters_CSCpr","CSCpr")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCoShCylinder(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/d smear_coef_CSCpr = {0.01,150,0.10,10,20.,10.,4.0e-6,1.0e-6,4.0e-6,0.001}
	make/o/t smear_parameters_CSCpr = {"scale","mean CORE radius (A)","radial polydispersity (sigma)","CORE length (A)","radial shell thickness (A)","face shell thickness (A)","SLD core (A^-2)","SLD shell (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CSCpr,smear_coef_CSCpr
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	
	Duplicate/O $(str+"_q") smeared_CSCpr,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSCpr							
					
	Variable/G gs_CSCpr=0
	gs_CSCpr := fSmearedPolyCoShCylinder(smear_coef_CSCpr,smeared_CSCpr,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CSCpr vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCoShCylinder","smear_coef_CSCpr","smear_parameters_CSCpr","CSCpr")
End
	


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function PolyCoShCylinder(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("PolyCoShCylinderX")
	MultiThread yw = PolyCoShCylinderX(cw,xw)
#else
	yw = fPolyCoShCylinder(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////////////////////
// unsmeared model calculation: function integrates for a polydisperse radius.
//  Relies on the following two functions to return the monodisperse form factor.
///////////////////////////////////////////////////////////////////////////////

Function fPolyCoShCylinder(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] cylinder CORE RADIUS (A)
	//[2] radial polydispersity (sigma)
	//[3] cylinder CORE LENGTH (A)
	//[4] radial shell Thickness (A)
	//[5] face shell Thickness (A)
	//[6] core SLD (A^-2)
	//[7] shell SLD (A^-2)
	//[8] solvent SLD (A^-2)
	//[9] background (cm^-1)
	Variable scale,length,sigma,bkg,radius,radthick,facthick,rhoc,rhos,rhosolv
	Variable fc, vcyl,qq
	Variable nord,ii,va,vb,summ,yyy,rad,AR,lgAR,zed,Rsqr,lgRsqr,Rsqrsumm,Rsqryyy,tot
	String weightStr,zStr
	scale = w[0]
	radius = w[1]
	sigma = w[2]				//sigma is the standard mean deviation
	length = w[3]
	radthick = w[4]
	facthick= w[5]
	rhoc = w[6]
	rhos = w[7]
	rhosolv = w[8]
	bkg = w[9]
	
	weightStr = "gauss20wt"
	zStr = "gauss20z"
	
//	if wt,z waves don't exist, create them
	
	if (WaveExists($weightStr) == 0) 		// wave reference is not valid, 
		Make/D/N=20 $weightStr,$zStr
		Wave w20 = $weightStr
		Wave z20 = $zStr				// wave references to pass
		Make20GaussPoints(w20,z20)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		// execute if condition is false
		endif
		Wave w20 = $weightStr
		Wave z20 = $zStr			
	endif

/////////////////////////////////////////////////////////////////////////
// This integration loop is for the radial polydispersity.
//  The loop uses values from cylintegration to average
// the scattering over a radial size distribution.
/////////////////////////////////////////////////////////////////////////

	nord = 20
	va = exp(ln(radius)-(4.*sigma))
	if (va<0)
		va=0					//to avoid numerical error when  va<0 (-ve r value)
	endif
	vb = exp(ln(radius)+(4.*sigma))

//	zed = ((radius*radius)/(sigma*sigma))-1		// If you want to use a Schultz distribution instead 

// evaluate at Gauss points 
// remember to index from 0,size-1
	qq = x 		
	summ = 0.0			// initialize integral
	Rsqrsumm = 0.0
        
	ii=0
	do
		// Using 20 Gauss points
		rad = ( z20[ii]*(vb-va) + vb + va )/2.0			//make distribution points

//		lgAR = (zed*ln(rad))-((rad*(zed+1))/radius)-((zed+1)*ln(radius/(zed+1)))-gammln(zed+1)
		//create Schultz distribution 
//		AR = exp(lgAR)					//invert Schultz to prevent overflow/underflow
		
//		AR=(1/(rad*sigma*sqrt(2*Pi)))*exp(-(0.5*((ln(radius/rad))/sigma)*((ln(radius/rad))/sigma)))
		AR=(1/(rad*sigma*sqrt(2*Pi)))*exp(-(0.5*((ln(rad/radius))/sigma)*((ln(rad/radius))/sigma)))

		yyy = w20[ii] * AR * cylintegration(qq,rad,radthick,facthick,rhoc,rhos,rhosolv,length)
//		Rsqryyy= w20[ii] * AR * rad*rad		//A.Nelson, original does not include shell
		Rsqryyy= w20[ii] * AR * (rad+radthick)*(rad+radthick)		//SRK normalize to total dimensions
		
		summ += yyy
		Rsqrsumm +=  Rsqryyy
		ii+=1
	while (ii<nord)		// end of loop over quadrature points


// calculate value of integral to return
	fc = (vb-va)/2.0*summ
	Rsqr=(vb-va)/2.0*Rsqrsumm

//NOTE that for absolute intensity scaling you need to multiply by the
// number density of particles. This is the vol frac of core particles
// divided by the core volume.

//	lgRsqr=2*ln(radius/(zed+1))+gammln(zed+3)-gammln(zed+1)
//	Rsqr=exp(lgRsqr)																	

//	vcyl=Pi*Rsqr*length		//but you have to multiply by <R2> not <R>2.
	vcyl=Pi*Rsqr*(length+2*facthick)		//SRK normalize to total dimensions
	fc /= vcyl

//convert to [cm-1]
	fc *= 1.0e8
//Scale
	fc *= scale			//scale will be the volume fraction of core particles.
// add in the  incoherent background
	fc += bkg

	Return (fc)
End

////////////////////////////////////////////////////////////////////////////
//Cylintegration calculates the Form factor for the monodisperse core shell
////////////////////////////////////////////////////////////////////////////
Function cylintegration(qq,rad,radthick,facthick,rhoc,rhos,rhosolv,length)
	Variable  qq,rad,radthick,facthick,rhoc,rhos,rhosolv,length
	Variable  answer,halfheight
	Variable nord,ii,va,vb,summ,yyy,zi
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"

//	if wt,z waves don't exist, create them
//     20 Gauss points is not enough for cylinder calculation
	
	if (WaveExists($weightStr) == 0) 				// wave reference is not valid, 
		Make/D/N=76 $weightStr,$zStr
		Wave w76 = $weightStr
		Wave z76 = $zStr							// wave references to pass
		Make76GaussPoints(w76,z76)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	
		endif
		Wave w76 = $weightStr
		Wave z76 = $zStr	
	endif

// set up the integration end points 
	nord = 76
	va = 0
	vb = Pi/2
	halfheight = length/2.0

// evaluate at Gauss points 
// remember to index from 0,size-1

	summ = 0.0				// initialize integral
	ii=0
	do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0		
		yyy = w76[ii] * CScyl(qq, rad, radthick, facthick, rhoc,rhos,rhosolv, halfheight, zi)
		summ += yyy 
     ii+=1
	while(ii<nord)		// end of loop over quadrature points

// calculate value of integral to return
  answer = (vb-va)/2.0*summ
	Return (answer)

End				//End of function cylintegration

////////////////////////////////////////////////////////////////////////
// F(qq, rcore, thick, rhoc,rhos,rhosolv, length, zi)  This returns the
// arguments used for the integration over theta.
////////////////////////////////////////////////////////////////////////
Function CScyl(qq, rad, radthick, facthick, rhoc,rhos,rhosolv, length, dum)
	Variable qq, rad, radthick, facthick, rhoc,rhos,rhosolv, length, dum
	
// qq is the q-value for the calculation (1/A)
// radius is the core radius of the cylinder (A)
//  radthick and facthick are the radial and face layer thicknesses
// rho(n) are the respective SLD's
// length is the *Half* CORE-LENGTH of the cylinder 
// dum is the dummy variable for the integration (theta)

	Variable dr1,dr2,besarg1,besarg2,vol1,vol2,sinarg1,sinarg2,t1,t2,retval		//Local variables 
	Variable si1,si2,be1,be2
	
	dr1 = rhoc-rhos
	dr2 = rhos-rhosolv
	vol1 = Pi*rad*rad*(2*length)
	vol2 = Pi*(rad+radthick)*(rad+radthick)*(2*length+2*facthick)
	
	besarg1 = qq*rad*sin(dum)
	besarg2 = qq*(rad+radthick)*sin(dum)
	sinarg1 = qq*length*cos(dum)
	sinarg2 = qq*(length+facthick)*cos(dum)
	
	if(besarg1 == 0)
		be1 = 0.5
	else
		be1 = bessJ(1,besarg1)/besarg1
	endif
	if(besarg2 == 0)
		be2 = 0.5
	else
		be2 = bessJ(1,besarg2)/besarg2
	endif
	if(sinarg1 == 0)
		si1 = 1
	else
		si1 = sin(sinarg1)/sinarg1
	endif
	if(sinarg2 == 0)
		si2 = 1
	else
		si2 = sin(sinarg2)/sinarg2
	endif
	
	
	t1 = 2*vol1*dr1*si1*be1
	t2 = 2*vol2*dr2*si2*be2
	
	retval = ((t1+t2)^2)*sin(dum)
	return retval
    
End 	//Function CScyl()

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCoShCylinder(coefW,yW,xW)
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
	err = SmearedPolyCoShCylinder(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCoShCylinder(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(PolyCoShCylinder,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	