#pragma rtGlobals=1		// Use modern global access method.

#include "CylinderForm"

// calculates the form factor of a cylinder with polydispersity of radius
// the length distribution is a Schulz distribution, and any normalized distribution
// could be used, as the average is performed numerically
//
// since the cylinder form factor is already a numerical integration, the size average is a 
// second integral, and significantly slows the calculation, and smearing adds a third integration.
//
//CORRECT! 12/5/2000 - Invariant is now correct vs. monodisperse cylinders
// + upper limit of integration has been changed to account for skew of 
//Schulz distribution at high (>0.5) polydispersity
//Requires 20 gauss points for integration of the radius (5 is not enough)
//Requires either CylinderFit XOP (MacOSX only) or the normal CylinderForm Function
//
Proc PlotCyl_PolyRadius(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_cypr,ywave_cypr
	xwave_cypr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_cypr = {1.,20.,400,0.2,3.0e-6,0.01}
	make/o/t parameters_cypr = {"scale","radius (A)","length (A)","polydispersity of Radius","SLD diff (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_cypr,coef_cypr
	ywave_cypr := Cyl_PolyRadius(coef_cypr,xwave_cypr)
	Display ywave_cypr vs xwave_cypr
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedCyl_PolyRadius()	
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	make/o/D smear_coef_cypr = {1.,20.,400,0.2,3.0e-6,0.01}
	make/o/t smear_parameters_cypr = {"scale","radius (A)","length (A)","polydispersity of Radius","SLD diff (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_cypr,smear_coef_cypr
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_cypr,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_cypr	

	smeared_cypr := SmearedCyl_PolyRadius(smear_coef_cypr,$gQvals)
	Display smeared_cypr vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Cyl_PolyRadius(w,x) :FitFunc
	Wave w
	Variable x

	//The input variables are (and output)
	//[0] scale
	//[1] avg RADIUS (A)
	//[2] Length (A)
	//[3] polydispersity (0<p<1)
	//[4] contrast (A^-2)
	//[5] background (cm^-1)
	Variable scale,radius,pd,delrho,bkg,zz,length
	scale = w[0]
	radius = w[1]
	length = w[2]
	pd = w[3]
	delrho = w[4]
	bkg = w[5]
	
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
		yyy = wtGau[ii] * rad_kernel(qq,radius,length,zz,delrho,zi)
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
	vpoly = Pi*(radius)^2*length*(zz+2)/(zz+1)
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

Function rad_kernel(qw,ravg,len,zz,delrho,rad)
	Variable qw,ravg,len,zz,delrho,rad
	
	Variable Pq,vcyl,dr
	
	//calculate the orientationally averaged P(q) for the input rad
	//this is correct - see K&C (1983) or Lin &Tsao JACryst (1996)29 170.
	Make/O/D/n=5 kernpar
	Wave kp = kernpar
	kp[0] = 1		//scale fixed at 1
	kp[1] = rad
	kp[2] = len
	kp[3] = delrho
	kp[4] = 0		//bkg fixed at 0
	
	Pq = CylinderForm(kp,qw)
//	Pq = CylinderFormX(kp,qw)	//from the XOP
	
	// undo the normalization that CylinderForm does
	vcyl=Pi*rad*rad*len
	Pq *= vcyl
	//un-convert from [cm-1]
	Pq /= 1.0e8
	
	// calculate normalized distribution at len value
	dr = Schulz_Point_pr(rad,ravg,zz)
	
	return (Pq*dr)	
End

Function Schulz_Point_pr(x,avg,zz)
	Variable x,avg,zz
	
	Variable dr
	
	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
	
	return (exp(dr))
End

// this is all there is to the smeared calculation!
Function SmearedCyl_PolyRadius(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Cyl_PolyRadius,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
