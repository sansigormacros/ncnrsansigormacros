#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

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
//  7th Jan 2007  DS  Core-shell to include varying SLD in rim and face: Model 2
//  Jan 2009  ACH - changed to run in Igor 6.03 
//
//  May 2009 AJJ - Renamed to PolyCoreBicelle_v40.ipf
/////////////////////////////////////////////////////////////////

Proc PlotPolyCoreBicelle(num,qmin,qmax)
	Variable num=100,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_PCBicelle,ywave_PCBicelle
	xwave_PCBicelle = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_PCBicelle = {0.01,150,0.10,10,20.,10.,4.0e-6, 1.0e-6,2.0e-6,4.0e-6,0.001}
	make/o/t parameters_PCBicelle = {"scale","mean CORE radius (A)","radial polydispersity (sigma)","CORE length (A)","radial shell thickness (A)","face shell thickness (A)","SLD core (A^-2)","SLD face (A^-2)","SLD rim(A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit/W=(410,44,757,306)  parameters_PCBicelle,coef_PCBicelle
	ModifyTable width(parameters_PCBicelle)=162
	
	Variable/G root:g_PCBicelle
	g_PCBicelle := PolyCoreBicelle(coef_PCBicelle,ywave_PCBicelle,xwave_PCBicelle)
	Display ywave_PCBicelle vs xwave_PCBicelle
	ModifyGraph log=1, marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCoreBicelle","coef_PCBicelle","parameters_PCBicelle","PCBicelle")
End


Proc PlotSmearedPolyCoreBicelle(str)
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)							
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/d smear_coef_PCBicelle = {0.01,150,0.10,10,20.,10.,4.0e-6,1.0e-6,2.0e-6,4.0e-6,0.001}
	make/o/t smear_parameters_PCBicelle = {"scale","mean CORE radius (A)","radial polydispersity (sigma)","CORE length (A)","radial shell thickness (A)","face shell thickness (A)","SLD core (A^-2)","SLD face (A^-2)","SLD rim(A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_PCBicelle,smear_coef_PCBicelle
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	
	Duplicate/O $(str+"_q") smeared_PCBicelle,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCBicelle							
					
	Variable/G gs_PCBicelle=0
	gs_PCBicelle := fSmearedPolyCoreBicelle(smear_coef_PCBicelle,smeared_PCBicelle,smeared_qvals)
		
	Display smeared_PCBicelle vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCoreBicelle","smear_coef_PCBicelle","smear_parameters_PCBicelle","PCBicelle")
End
///////////////////////////////////////////////////////////////////////////////
// unsmeared model calculation: function integrates for a polydisperse radius.
//  Relies on the following two functions to return the monodisperse form factor.
///////////////////////////////////////////////////////////////////////////////
Function PolyCoreBicelle(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("PolyCoreBicelleX")
	yw = PolyCoreBicelleX(cw,xw)
#else
	yw = fPolyCoreBicelle(cw,xw)
#endif
	return(0)
End

Function  fPolyCoreBicelle(w,x) : FitFunc
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
	//[7] face SLD (A^-2)
	//[8] rim SLD (A^-2)
	//[9] solvent SLD (A^-2)
	//[10] background (cm^-1)
	Variable scale,length,sigma,bkg,radius,radthick,facthick,rhoc,rhoh, rhor, rhosolv
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
	rhoh = w[7]
	rhor=w[8]
	rhosolv = w[9]
	bkg = w[10]
	
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

// evaluate at Gauss points 
// remember to index from 0,size-1
	qq = x 		
	summ = 0.0			// initialize integral
	Rsqrsumm = 0.0
        
	ii=0
	do
		// Using 20 Gauss points
		rad = ( z20[ii]*(vb-va) + vb + va )/2.0			//make distribution points
		
		AR=(1/(rad*sigma*sqrt(2*Pi)))*exp(-(0.5*((ln(radius/rad))/sigma)*((ln(radius/rad))/sigma)))

		yyy = w20[ii] * AR * BicelleIntegration(qq,rad,radthick,facthick,rhoc,rhoh,rhor,rhosolv,length)
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
//BicelleIntegration calculates the Form factor for the Bicelle core shell cylinder
////////////////////////////////////////////////////////////////////////////
Function  BicelleIntegration(qq,rad,radthick,facthick,rhoc, rhoh, rhor, rhosolv, length)
	Variable  qq,rad,radthick,facthick,rhoc,rhoh,rhor,rhosolv,length
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
		yyy = w76[ii] * BicelleKernel(qq, rad, radthick, facthick, rhoc,rhoh, rhor,rhosolv, halfheight, zi)
		summ += yyy 
     ii+=1
	while(ii<nord)		// end of loop over quadrature points

// calculate value of integral to return
  answer = (vb-va)/2.0*summ
	Return (answer)

End				//End of function cylintegration

////////////////////////////////////////////////////////////////////////
// F(qq, rcore, thick, rhoc,rhos,rhosolv, length, zi)  This returns the
// arguments used for the integration over theta for orientational average
////////////////////////////////////////////////////////////////////////
Function BicelleKernel(qq, rad, radthick, facthick, rhoc,rhoh, rhor,rhosolv, length, dum)
	Variable qq, rad, radthick, facthick, rhoc,rhoh,rhor,rhosolv, length, dum
	
// qq is the q-value for the calculation (1/A)
// radius is the core radius of the cylinder (A)
//  radthick and facthick are the radial and face layer thicknesses
// rho(n) are the respective SLD's
// length is the *Half* CORE-LENGTH of the cylinder 
// dum is the dummy variable for the integration (theta)

	Variable dr1,dr2, dr3, besarg1,besarg2, vol1,vol2, vol3,sinarg1,sinarg2,t1,t2,t3, retval		//Local variables 

	dr1 = rhoc-rhoh
	dr2 = rhor-rhosolv
	dr3=  rhoh-rhor
	vol1 = Pi*rad*rad*(2*length)
	vol2 = Pi*(rad+radthick)*(rad+radthick)*(2*length+2*facthick)
	vol3= Pi*(rad)*(rad)*(2*length+2*facthick)
	besarg1 = qq*rad*sin(dum)
	besarg2 = qq*(rad+radthick)*sin(dum)
	sinarg1 = qq*length*cos(dum)
	sinarg2 = qq*(length+facthick)*cos(dum)
	
	t1 = 2*vol1*dr1*sin(sinarg1)/sinarg1*bessJ(1,besarg1)/besarg1
	t2 = 2*vol2*dr2*sin(sinarg2)/sinarg2*bessJ(1,besarg2)/besarg2
	t3 = 2*vol3*dr3*sin(sinarg2)/sinarg2*bessJ(1,besarg1)/besarg1
	
	retval = ((t1+t2+t3)^2)*sin(dum)
	return retval
    
End 

// this is all there is to the smeared calculation!
Function fSmearedPolyCoreBicelle(coefW,yW,xW)
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
	err = SmearedPolyCoreBicelle(fs)
	 
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCoreBicelle(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(PolyCoreBicelle,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	