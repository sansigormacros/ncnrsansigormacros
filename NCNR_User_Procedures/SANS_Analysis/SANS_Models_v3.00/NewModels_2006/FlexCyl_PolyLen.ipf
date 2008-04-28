#pragma rtGlobals=1		// Use modern global access method.

#include "FlexibleCylinder"
//uses the function FlexibleCylinder(.ipf) as basic function
//
// code has been updated with WRC's changes (located in FlexibleCylinder.ipf)
// JULY 2006
//
Proc PlotFlexCyl_PolyLength(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	// Setup parameter table for model function
	Make/O/D/n=(num) xwave_flepl,ywave_flepl
	xwave_flepl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_flepl = {1.,1000,0.001,100,20,3.0e-6,0.0001}
	make/o/t parameters_flepl =  {"scale","Contour Length (A)","polydispersity of Contour Length","Kuhn Length, b (A)","Radius (A)","contrast (A^-2)","bkgd (cm^-1)"}
	Edit parameters_flepl,coef_flepl
	ywave_flepl := FlexCyl_PolyLen(coef_flepl,xwave_flepl)
	Display ywave_flepl vs xwave_flepl
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmeared_FlexCyl_PolyLen()								//MyModel
	// if no gQvals wave, data must not have been loaded => abort
	
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_flepl = {1.,1000,0.001,100,20,3.0e-6,0.0001}		//CH#4
	make/o/t smear_parameters_flepl = {"scale","Contour Length (A)","polydispersity of Contour Length","Kuhn Length, b (A)","Radius (A)","contrast (A^-2)","bkgd (cm^-1)"}
	Edit smear_parameters_flepl,smear_coef_flepl					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_flepl,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_flepl							//

	smeared_flepl := SmearedFlexCyl_PolyLen(smear_coef_flepl,$gQvals)		// SMEARED function name
	Display smeared_flepl vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro 

Function Schulz_Point_flepl(x,avg,zz)

	//Wave w
	Variable x,avg,zz
	Variable dr
	
	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
	
	return (exp(dr))
	
End

Function FlexCyl_PolyLen(w,x) : FitFunc
	Wave w
	Variable x
      
	Variable scale,radius,pd,delrho,bkg,zz,length,lb
	scale = w[0]
	length = w[1]
	pd = w[2]
	lb = w[3]
	radius = w[4]
	delrho = w[5]
	bkg = w[6]
	
	zz = (1/pd)^2-1
//
// the OUTPUT form factor is <f^2>/Vavg [cm-1]
//
// local variables
	Variable nord,ii,a,b,va,vb,contr,vcyl,nden,summ,yyy,zi,qq
	Variable answer,zp1,zp2,zp3,vpoly
	String weightStr,zStr
	
	nord = 20
	weightStr = "gauss20wt"
	zStr = "gauss20z"

// use 20 Gauss points
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave wtGau = $weightStr
		Wave zGau = $zStr		// wave references to pass
		Make20GaussPoints(wtGau,zGau)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	// execute if condition is false
		endif
		Wave wtGau = $weightStr
		Wave zGau = $zStr
	endif

// set up the integration
// end points and weights
// limits are technically 0-inf, but wisely choose non-zero region of distribution
	Variable range=3.4		//multiples of the std. dev. fom the mean
	a = length*(1-range*pd)
	if (a<0)
		a=0		//otherwise numerical error when pd >= 0.3, making a<0
	endif
	If(pd>0.3)
		range = 3.4 + (pd-0.3)*18
	Endif
	b = length*(1+range*pd) // is this far enough past avg length?
	va =a 
	vb =b 

// evaluate at Gauss points 
	// remember to index from 0,size-1	
	qq = x		//current x point is the q-value for evaluation
	summ = 0.0		// initialize integral
   ii=0
   do
		zi = ( zGau[ii]*(vb-va) + vb + va )/2.0		
		yyy = wtGau[ii] * fle_kernel(qq,radius,length,lb,zz,delrho,zi)
		summ = yyy + summ
		ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return
   answer = (vb-va)/2.0*summ
      
//  contrast^2 is included in integration rad_kernel
//	answer *= delrho*delrho
//normalize by polydisperse volume
// now volume depends on polydisperse Length - so normalize by the FIRST moment
// 1st moment = volume!
	vpoly = Pi*(radius)^2*length
//Divide by vol, since volume has been "un-normalized" out
	answer /= vpoly
//convert to [cm-1]
	answer *= 1.0e8
//scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
End		//End of function PolyLenExclVolCyl(w,x)

Function fle_kernel(qw,rad,len_avg,lb,zz,delrho,len_i)
	Variable qw,rad,len_avg,lb,zz,delrho,len_i
	
	//ww[0] = scale
	//ww[1] = L [A]
	//ww[2] = B [A]
	//ww[3] = rad [A] cross-sectional radius
	//ww[4] = contrast [A^-2]
	//ww[5] = bkg [cm-1]
	Variable Pq,vcyl,dl
	Make/O/n=6 fle_ker
	Wave kp = fle_ker
	kp[0] = 1		//scale fixed at 1
	kp[1] = len_i
	kp[2] = lb
	kp[3] = rad
	kp[4] = delrho
	kp[5] = 0		//bkg fixed at 0
	
	Pq = FlexExclVolCyl(kp,qw)
	vcyl=Pi*rad*rad*len_i
	Pq *= vcyl
	//un-convert from [cm-1]
	Pq /= 1.0e8
	
	dl = Schulz_Point_flepl(len_i,len_avg,zz)
	return (Pq*dl)	
End

// this is all there is to the smeared calculation!
Function SmearedFlexCyl_PolyLen(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(FlexCyl_PolyLen,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
