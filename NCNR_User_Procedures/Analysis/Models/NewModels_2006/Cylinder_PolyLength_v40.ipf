#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

#include "Cylinder_v40"

// calculates the form factor of a cylinder with polydispersity of length
// the length distribution is a Schulz distribution, and any normalized distribution
// could be used, as the average is performed numerically
//
// since the cylinder form factor is already a numerical integration, the size average is a 
// second integral, and significantly slows the calculation, and smearing adds a third integration.
//
//CORRECTED 12/5/2000 - Invariant is now correct vs. monodisperse cylinders
// + upper limit of integration has been changed to account for skew of 
//Schulz distribution at high (>0.5) polydispersity
//Requires 20 gauss points for integration of the radius (5 is not enough)
//Requires either CylinderFit XOP (MacOSX only) or the normal CylinderForm Function
//
Proc PlotCyl_PolyLength(num,qmin,qmax)
	Variable num=100,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_cypl,ywave_cypl
	xwave_cypl = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_cypl = {1.,20.,1000,0.2,1e-6,6.3e-6,0.01}
	make/o/t parameters_cypl = {"scale","radius (A)","length (A)","polydispersity of Length","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_cypl,coef_cypl
	
	Variable/G root:g_cypl
	g_cypl := Cyl_PolyLength(coef_cypl,ywave_cypl,xwave_cypl)
	Display ywave_cypl vs xwave_cypl
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cyl_PolyLength","coef_cypl","parameters_cypl","cypl")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCyl_PolyLength(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_cypl = {1.,20.,1000,0.2,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_cypl = {"scale","radius (A)","length (A)","polydispersity of Length","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_cypl,smear_coef_cypl
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_cypl,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_cypl	
					
	Variable/G gs_cypl=0
	gs_cypl := fSmearedCyl_PolyLength(smear_coef_cypl,smeared_cypl,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_cypl vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCyl_PolyLength","smear_coef_cypl","smear_parameters_cypl","cypl")
End
	


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Cyl_PolyLength(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("Cyl_PolyLengthX")
	yw = Cyl_PolyLengthX(cw,xw)
#else
	yw = fCyl_PolyLength(cw,xw)
#endif
	return(0)
End

//calculate the form factor averaged over the size distribution
// both integrals are done using quadrature, although both may benefit from an
// adaptive integration
Function fCyl_PolyLength(w,x)  : FitFunc
	Wave w
	Variable x

	//The input variables are (and output)
	//[0] scale
	//[1] avg RADIUS (A)
	//[2] Length (A)
	//[3] polydispersity (0<p<1)
	//[4] contrast (A^-2)
	//[5] background (cm^-1)
	Variable scale,radius,pd,delrho,bkg,zz,length,sldc,slds
	scale = w[0]
	radius = w[1]
	length = w[2]
	pd = w[3]
	sldc = w[4]
	slds = w[5]
	delrho = sldc - slds
	bkg = w[6]
	
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

// 5 Gauss points (not enough for cylinder radius = high q oscillations)
// use 20 Gauss points
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave wtGau = $weightStr
		Wave zGau = $zStr		
		Make20GaussPoints(wtGau,zGau)	
		//Make5GaussPoints(wtGau,zGau)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	
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
//	printf "a,b,len_avg = %g %g %g\r", a,b,length
	va =a 
	vb =b 

	qq = x		//current x point is the q-value for evaluation
	summ = 0.0		// initialize integral
   ii=0
   do
   //printf "top of nord loop, i = %g\r",i
	// Using 5 Gauss points		
		zi = ( zGau[ii]*(vb-va) + vb + va )/2.0		
		yyy = wtGau[ii] * len_kernel(qq,radius,length,zz,sldc,slds,zi)
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
End		//End of function PolyRadCylForm()

Function len_kernel(qw,rad,len_avg,zz,sldc,slds,len)
	Variable qw,rad,len_avg,zz,sldc,slds,len
	
	Variable Pq,vcyl,dl
	
	//calculate the orientationally averaged P(q) for the input rad
	//this is correct - see K&C (1983) or Lin &Tsao JACryst (1996)29 170.
	Make/O/n=6 kernpar
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
	//CylinderForm returns P(q)/V, we want P(q)
	vcyl=Pi*rad*rad*len
	Pq *= vcyl
	//un-convert from [cm-1]
	Pq /= 1.0e8
	
	// calculate normalized distribution at len value
	dl = Schulz_Point_pollen(len,len_avg,zz)
	
	return (Pq*dl)	
End

Function Schulz_Point_pollen(x,avg,zz)
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
Function fSmearedCyl_PolyLength(coefW,yW,xW)
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
	err = SmearedCyl_PolyLength(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedCyl_PolyLength(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Cyl_PolyLength,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	