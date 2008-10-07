#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

#include "FlexibleCylinder_v40"
//
// code has been updated with WRC's changes (located in FlexibleCylinder.ipf)
// JULY 2006
//
Proc PlotFlexCyl_PolyRad(num,qmin,qmax)
	Variable num=100,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fcpr,ywave_fcpr
	xwave_fcpr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_fcpr = {1.,1000,100,20,0.2,1e-6,6.3e-6,0.0001}
	make/o/t parameters_fcpr = {"scale","Contour Length (A)","Kuhn Length, b (A)","Radius (A)","polydispersity of radius","SLD cylinder (A^-2)","SLD solvent (A^-2)","bkgd (cm^-1)"}
	Edit parameters_fcpr,coef_fcpr
	
	Variable/G root:g_fcpr
	g_fcpr := FlexCyl_PolyRad(coef_fcpr,ywave_fcpr,xwave_fcpr)
	Display ywave_fcpr vs xwave_fcpr
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FlexCyl_PolyRad","coef_fcpr","fcpr")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFlexCyl_PolyRad(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fcpr = {1.,1000,100,20,0.2,1e-6,6.3e-6,0.0001}			
	make/o/t smear_parameters_fcpr = {"scale","Contour Length (A)","Kuhn Length, b (A)","Radius (A)","polydispersity of radius","SLD cylinder (A^-2)","SLD solvent (A^-2)","bkgd (cm^-1)"}		
	Edit smear_parameters_fcpr,smear_coef_fcpr					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fcpr,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fcpr							
					
	Variable/G gs_fcpr=0
	gs_fcpr := fSmearedFlexCyl_PolyRad(smear_coef_fcpr,smeared_fcpr,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fcpr vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFlexCyl_PolyRad","smear_coef_fcpr","fcpr")
End



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FlexCyl_PolyRad(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FlexCyl_PolyRadX")
	yw = FlexCyl_PolyRadX(cw,xw)
#else
	yw = fFlexCyl_PolyRad(cw,xw)
#endif
	return(0)
End

// do a numerical average over the flexible cylinder form factor
// to account for the polydispersity of the radius.
//
Function fFlexCyl_PolyRad(w,x)  : FitFunc
	Wave w
	Variable x

	//The input variables are (and output)
	//[0] scale
	//[1] contour length (A)
	//[2] Kuhn Length (A)
	//[3] radius (A)
	//[4] polydispersity of radius (0<p<1)
	//[5] sld cylinder (A^-2)
	//[6] sld solvent
	//[7] background (cm^-1)
	Variable scale,radius,pd,delrho,bkg,zz,Lc,Lb,sldc,slds
	scale = w[0]
	Lc = w[1]
	Lb = w[2]
	radius = w[3]
	pd = w[4]
	sldc = w[5]
	slds = w[6]
	bkg = w[7]
	
	delrho = sldc - slds
	zz = (1/pd)^2-1
//
// the OUTPUT form factor is <f^2>/Vavg [cm-1]
//
// local variables
	Variable nord,ii,a,b,va,vb,contr,vcyl,nden,summ,yyy,zi,qq
	Variable answer,zp1,zp2,zp3,vpoly
	String weightStr,zStr
	
//	nord = 5	
//	weightStr = "gauss5wt"
//	zStr = "gauss5z"
	nord = 20
	weightStr = "gauss20wt"
	zStr = "gauss20z"

//	if wt,z waves don't exist, create them
// 5 Gauss points (not enough for cylinder radius = high q oscillations)
// use 20 Gauss points
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave wtGau = $weightStr
		Wave zGau = $zStr		// wave references to pass
		Make20GaussPoints(wtGau,zGau)	
		//Make5GaussPoints(wtGau,zGau)	
//	//		    printf "w[0],z[0] = %g %g\r", wtGau[0],zGau[0]
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	// execute if condition is false
		endif
		Wave wtGau = $weightStr
		Wave zGau = $zStr
//	//	    printf "w[0],z[0] = %g %g\r", wtGau[0],zGau[0]	
	endif

// set up the integration
// end points and weights
// limits are technically 0-inf, but wisely choose non-zero region of distribution
	Variable range=3.4		//multiples of the std. dev. fom the mean
	a = radius*(1-range*pd)
	if (a<0)
		a=0		//otherwise numerical error when pd >= 0.3, making a<0
	endif
	If(pd>0.3)
		range = 3.4 + (pd-0.3)*18
	Endif
	b = radius*(1+range*pd) // is this far enough past avg radius?
//	printf "a,b,ravg = %g %g %g\r", a,b,radius
	va =a 
	vb =b 

// evaluate at Gauss points 
	// remember to index from 0,size-1	
	qq = x		//current x point is the q-value for evaluation
	summ = 0.0		// initialize integral
   ii=0
   do
   //printf "top of nord loop, i = %g\r",i
	// Using 5 Gauss points		
		zi = ( zGau[ii]*(vb-va) + vb + va )/2.0		
		yyy = wtGau[ii] * fle_rad_kernel(qq,radius,Lc,Lb,zz,sldc,slds,zi)
		summ = yyy + summ
		ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return
   answer = (vb-va)/2.0*summ
      
//  contrast^2 is included in integration rad_kernel
//	answer *= delrho*delrho
//normalize by polydisperse volume
// now volume depends on polydisperse RADIUS - so normalize by the second moment
// 2nd moment = (zz+2)/(zz+1)
	vpoly = Pi*(radius)^2*Lc*(zz+2)/(zz+1)
//Divide by vol, since volume has been "un-normalized" out
	answer /= vpoly
//convert to [cm-1]
	answer *= 1.0e8
//scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
End		//End of function PolyRadCylForm()

Function fle_rad_kernel(qw,ravg,Lc,Lb,zz,sldc,slds,rad)
	Variable qw,ravg,Lc,Lb,zz,sldc,slds,rad
	
	Variable Pq,vcyl,dr
	
	//calculate the orientationally averaged P(q) for the input rad
	//this is correct - see K&C (1983) or Lin &Tsao JACryst (1996)29 170.
	Make/O/n=7 kernpar
	Wave kp = kernpar
	kp[0] = 1		//scale fixed at 1
	kp[1] = Lc
	kp[2] = Lb
	kp[3] = rad
	kp[4] = sldc
	kp[5] = slds
	kp[6] = 0		//bkg fixed at 0
	
#if exists("FlexExclVolCylX")
	Pq = FlexExclVolCylX(kp,qw)
#else
	Pq = fFlexExclVolCyl(kp,qw)
#endif
	
	// undo the normalization that the form factor does
	vcyl=Pi*rad*rad*Lc
	Pq *= vcyl
	//un-convert from [cm-1]
	Pq /= 1.0e8
	
	// calculate normalized distribution at len value
	dr = Schulz_Point_frc(rad,ravg,zz)
	
	return (Pq*dr)	
End


Function Schulz_Point_frc(x,avg,zz)
	Variable x,avg,zz
	
	Variable dr
	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
	return (exp(dr))
	
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFlexCyl_PolyRad(coefW,yW,xW)
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
	err = SmearedFlexCyl_PolyRad(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedFlexCyl_PolyRad(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FlexCyl_PolyRad,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
