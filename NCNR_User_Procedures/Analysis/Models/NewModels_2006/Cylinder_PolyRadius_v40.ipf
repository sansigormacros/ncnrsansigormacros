#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

#include "Cylinder_v40"

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
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_cypr,ywave_cypr
	xwave_cypr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_cypr = {1.,20.,400,0.2,1e-6,6.3e-6,0.01}
	make/o/t parameters_cypr = {"scale","radius (A)","length (A)","polydispersity of Radius","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_cypr,coef_cypr
	
	Variable/G root:g_cypr
	g_cypr := Cyl_PolyRadius(coef_cypr,ywave_cypr,xwave_cypr)
	Display ywave_cypr vs xwave_cypr
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cyl_PolyRadius","coef_cypr","cypr")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCyl_PolyRadius(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_cypr = {1.,20.,400,0.2,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_cypr = {"scale","radius (A)","length (A)","polydispersity of Radius","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_cypr,smear_coef_cypr
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_cypr,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_cypr	
					
	Variable/G gs_cypr=0
	gs_cypr := fSmearedCyl_PolyRadius(smear_coef_cypr,smeared_cypr,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_cypr vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCyl_PolyRadius","smear_coef_cypr","cypr")
End
	

// non-threaded version, use the threaded version instead...
//
//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
//Function Cyl_PolyRadius(cw,yw,xw) : FitFunc
//	Wave cw,yw,xw
//	
//#if exists("Cyl_PolyRadiusX")
//	yw = Cyl_PolyRadiusX(cw,xw)
//#else
//	yw = fCyl_PolyRadius(cw,xw)
//#endif
//	return(0)
//End

Function fCyl_PolyRadius(w,x) :FitFunc
	Wave w
	Variable x

	//The input variables are (and output)
	//[0] scale
	//[1] avg RADIUS (A)
	//[2] Length (A)
	//[3] polydispersity (0<p<1)
	//[4] sld cylinder (A^-2)
	//[5] sld solvent
	//[6] background (cm^-1)
	Variable scale,radius,pd,delrho,bkg,zz,length,sldc,slds
	scale = w[0]
	radius = w[1]
	length = w[2]
	pd = w[3]
	sldc = w[4]
	slds = w[5]
	bkg = w[6]
	
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
		yyy = wtGau[ii] * rad_kernel(qq,radius,length,zz,sldc,slds,zi)
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

Function rad_kernel(qw,ravg,len,zz,sldc,slds,rad)
	Variable qw,ravg,len,zz,sldc,slds,rad
	
	Variable Pq,vcyl,dr
	
	//calculate the orientationally averaged P(q) for the input rad
	//this is correct - see K&C (1983) or Lin &Tsao JACryst (1996)29 170.
	Make/O/D/n=6 kernpar
	Wave kp = kernpar
	kp[0] = 1		//scale fixed at 1
	kp[1] = rad
	kp[2] = len
	kp[3] = sldc
	kp[4] = slds
	kp[5] = 0		//bkg fixed at 0
	
#if exists("CylinderFormX")
	Pq = CylinderFormX(kp,qw)
#else
	Pq = fCylinderForm(kp,qw)
#endif
	
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

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCyl_PolyRadius(coefW,yW,xW)
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
	err = SmearedCyl_PolyRadius(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedCyl_PolyRadius(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Cyl_PolyRadius,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// nthreads is 1 or an even number, typically 2
// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
//
Function Cyl_PolyRadius(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

///////NON-THREADED VERSION ///////
#if exists("Cyl_PolyRadiusX")	
	yw = Cyl_PolyRadiusX(cw,xw)
#else
	yw = fCyl_PolyRadius(cw,xw)
#endif

/// THREADED VERSION HAS BEEN REMOVED DUE TO CRASHES //////	
//#if exists("Cyl_PolyRadiusX")
//
//	Variable npt=numpnts(yw)
//	Variable i,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
//	for(i=0;i<nthreads;i+=1)
//	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
//		ThreadStart mt,i,Cyl_PolyRadius_T(cw,yw,xw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
//	endfor
//
//	do
//		variable tgs= ThreadGroupWait(mt,100)
//	while( tgs != 0 )
//
//	variable dummy= ThreadGroupRelease(mt)
//	
//#else
//		yw = fCyl_PolyRadius(cw,xw)		//the Igor, non-XOP, non-threaded calculation, messy to make ThreadSafe
//#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End

//// experimental threaded version...
// don't try to thread the smeared calculation, it's good enough
// to thread the unsmeared version

//threaded version of the function
ThreadSafe Function Cyl_PolyRadius_T(cw,yw,xw,p1,p2)
	WAVE cw,yw,xw
	Variable p1,p2
	
#if exists("Cyl_PolyRadiusX")			//this check is done in the calling function, simply hide from compiler
	yw[p1,p2] = Cyl_PolyRadiusX(cw,xw)
#else
	yw[p1,p2] = fCyl_PolyRadius(cw,xw)
#endif

	return 0
End