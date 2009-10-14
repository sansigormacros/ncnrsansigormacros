#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//#include "Sphere"
//plots the form factor for spheres with a Sculz distribution of radius
// at low polydispersity (< 0.2), it is very similar to the Gaussian distribution
// at larger polydispersities, it is more skewed and similar to log-normal
//

//
Proc PlotSchulzSpheres(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch,ywave_sch
	xwave_sch = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch = {0.01,60,0.2,1e-6,3e-6,0.001}
	make/O/T parameters_sch = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_sch,coef_sch
	
	Variable/G root:g_sch
	g_sch := SchulzSpheres(coef_sch,ywave_sch,xwave_sch)
	Display ywave_sch vs xwave_sch
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SchulzSpheres","coef_sch","parameters_sch","sch")
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSchulzSpheres(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch = {0.01,60,0.2,1e-6,3e-6,0.001}				
	make/o/t smear_parameters_sch = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}		
	Edit smear_parameters_sch,smear_coef_sch					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sch,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch							
					
	Variable/G gs_sch=0
	gs_sch := fSmearedSchulzSpheres(smear_coef_sch,smeared_sch,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sch vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SmearedSchulzSpheres","smear_coef_sch","smear_parameters_sch","sch")
End
	


Function Schulz_Point(x,avg,zz)
	Variable x,avg,zz
	
	Variable dr
	
	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
	return (exp(dr))
End


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function SchulzSpheres(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("SchulzSpheresX")
	yw = SchulzSpheresX(cw,xw)
#else
	yw = fSchulzSpheres(cw,xw)
#endif
	return(0)
End

//use the analytic formula from Kotlarchyk & Chen, JCP 79 (1983) 2461
//equations 23-30
//
// need to calculate in terms of logarithms to avoid numerical errors
//
Function fSchulzSpheres(w,x) : FitFunc
	Wave w
	Variable x

	Variable scale,ravg,pd,delrho,bkg,zz,rho,rhos,vpoly
	scale = w[0]
	ravg = w[1]
	pd = w[2]
	rho = w[3]
	rhos = w[4]
	bkg = w[5]
	
	delrho=rho-rhos
	zz = (1/pd)^2-1

	Variable zp1,zp2,zp3,zp4,zp5,zp6,zp7
	Variable aa,b1,b2,b3,at1,at2,rt1,rt2,rt3,t1,t2,t3
	Variable v1,v2,v3,g1,g11,gd,pq,g2,g22
	
	ZP1 = zz + 1
	ZP2 = zz + 2
	ZP3 = zz + 3
	ZP4 = zz + 4
	ZP5 = zz + 5
	ZP6 = zz + 6
	ZP7 = zz + 7
	
	//small QR limit - use Guinier approx
	Variable i_zero,Rg2,zp8
	zp8 = zz+8
	if(x*ravg < 0.1)
		i_zero = scale*delrho*delrho*1e8*4*Pi/3*ravg^3
		i_zero *= zp6*zp5*zp4/zp1/zp1/zp1		//6th moment / 3rd moment
		Rg2 = 3*zp8*zp7/5/(zp1^2)*ravg*ravg
		pq = i_zero*exp(-x*x*Rg2/3)
		pq += bkg
		return(pq)
	endif
//
	aa = (zz+1)/x/Ravg

	AT1 = atan(1/aa)
	AT2 = atan(2/aa)
//
//  CALCULATIONS ARE PERFORMED TO AVOID  LARGE # ERRORS
// - trick is to propogate the a^(z+7) term through the G1
// 
	T1 = ZP7*log(aa) - zp1/2*log(aa*aa+4)
	T2 = ZP7*log(aa) - zp3/2*log(aa*aa+4)
	T3 = ZP7*log(aa) - zp2/2*log(aa*aa+4)
//	Print T1,T2,T3
	RT1 = alog(T1)
	RT2 = alog(T2)
	RT3 = alog(T3)
	V1 = aa^6 - RT1*cos(zp1*at2)
	V2 = ZP1*ZP2*( aa^4 + RT2*cos(zp3*at2) )
	V3 = -2*ZP1*RT3*SIN(zp2*at2)
	G1 = (V1+V2+V3)
	
	Pq = log(G1) - 6*log(ZP1) + 6*log(Ravg)
	Pq = alog(Pq)*8*PI*PI*delrho*delrho
	
//
// beta factor is not used here, but could be for the 
// decoupling approximation
// 
//	G11 = G1
//	GD = -ZP7*log(aa)
//	G1 = log(G11) + GD
//                       
//	T1 = ZP1*at1
//	T2 = ZP2*at1
//	G2 = SIN( T1 ) - ZP1/SQRT(aa*aa+1)*COS( T2 )
//	G22 = G2*G2
//	BETA = ZP1*log(aa) - ZP1*log(aa*aa+1) - G1 + log(G22) 
//	BETA = 2*alog(BETA)
	
//re-normalize by the average volume
	vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(ravg)^3
	Pq /= vpoly
//scale, convert to cm^-1
	Pq *= scale * 1e8
// add in the background
	Pq += bkg
	
	//return (g1)
	Return (Pq)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSchulzSpheres(coefW,yW,xW)
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
	err = SmearedSchulzSpheres(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(SchulzSpheres,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End


//calculates number density given the coefficients of the Schulz distribution
// the scale factor is the volume fraction
// then nden = phi/<V> where <V> is calculated using the 3rd moment of the radius
Macro NumberDensity_Schulz()
	
	Variable nden,zz,zp1,zp2,zp3,zp4,zp5,zp6,zp7,zp8,vpoly,v2poly,rg,sv,i0
	
	if(Exists("coef_sch")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	Print "mean radius (A) = ",coef_sch[1]
	Print "polydispersity (sig/avg) = ",coef_sch[2]
	Print "volume fraction = ",coef_sch[0]
	
	zz = (1/coef_sch[2])^2-1
	zp1 = zz + 1.
	zp2 = zz + 2.
	zp3 = zz + 3.
 	zp4 = zz + 4.
	zp5 = zz + 5.
	zp6 = zz + 6.
	zp7 = zz + 7.
	zp8 = zz + 8.
 //  average particle volume   	
	vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(coef_sch[1])^3
 //  average particle volume   	
	v2poly = (4*Pi/3)^2*zp6*zp5*zp4*zp3*zp2/(zp1^5)*(coef_sch[1])^6
	nden = coef_sch[0]/vpoly		//nden in 1/A^3
	rg = coef_sch[1]*((3*zp8*zp7)/5/zp1/zp1)^0.5   // in A
	sv = 1.0e8*3*coef_sch[0]*zp1/coef_sch[1]/zp3  // in 1/cm
	i0 = 1.0e8*nden*v2poly*(coef_sch[3]-coef_sch[4])^2  // 1/cm/sr

	Print "number density (A^-3) = ",nden
	Print "Guinier radius (A) = ",rg
	Print "Interfacial surface area / volume (cm-1) Sv = ",sv
	Print "Forward cross section (cm-1 sr-1) I(0) = ",i0
End

// plots the Schulz distribution based on the coefficient values
// a static calculation, so re-run each time
//
Macro PlotSchulzDistribution()

	variable pd,avg,zz,maxr
	
	if(Exists("coef_sch")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	pd=coef_sch[2]
	avg = coef_sch[1]
	zz = (1/pd)^2-1
	
	Make/O/D/N=1000 Schulz_distribution
	maxr =  avg*(1+10*pd)

	SetScale/I x, 0, maxr, Schulz_distribution
	Schulz_distribution = Schulz_Point(x,avg,zz)
	Display Schulz_distribution
	legend
End

// don't use the integral technique here since there's an analytic solution
// available
//////////////////////
//requires that sphere.ipf is included
//
//
//Function SchulzSpheres_Integrated(w,x)
//	Wave w
//	Variable x
//
//	Variable scale,radius,pd,delrho,bkg,zz,rho,rhos
//	scale = w[0]
//	radius = w[1]
//	pd = w[2]
//	rho = w[3]
//	rhos = w[4]
//	bkg = w[5]
//	
//	delrho=rho-rhos
//	zz = (1/pd)^2-1
////
//// local variables
//	Variable nord,ii,a,b,va,vb,contr,vcyl,nden,summ,yyy,zi,qq
//	Variable answer,zp1,zp2,zp3,vpoly
//	String weightStr,zStr
//
//	//select number of gauss points by setting nord=20 or76 points
////	nord = 20
//	nord = 76
//	
//	weightStr = "gauss"+num2str(nord)+"wt"
//	zStr = "gauss"+num2str(nord)+"z"
//	
//	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
//		Make/D/N=(nord) $weightStr,$zStr
//		Wave gauWt = $weightStr
//		Wave gauZ = $zStr		// wave references to pass
//		if(nord==20)
//			Make20GaussPoints(gauWt,gauZ)
//		else
//			Make76GaussPoints(gauWt,gauZ)
//		endif	
//	else
//		if(exists(weightStr) > 1) 
//			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
//		endif
//		Wave gauWt = $weightStr
//		Wave gauZ = $zStr		// create the wave references
//	endif
//	
//// set up the integration
//// end points and weights
//// limits are technically 0-inf, but wisely choose non-zero region of distribution
//	Variable range=8		//multiples of the std. dev. from the mean
//	a = radius*(1-range*pd)
//	if (a<0)
//		a=0		//otherwise numerical error when pd >= 0.3, making a<0
//	endif
//	If(pd>0.3)
//		range = 3.4 + (pd-0.3)*18		//to account for skewed tail
//	Endif
//	b = radius*(1+range*pd) // is this far enough past avg radius?
//	va =a 
//	vb =b 
//
////temp set scale=1 and bkg=0 for quadrature calc
//	Make/O/D/N=4 sphere_temp
//	sphere_temp[0] = 1
//	sphere_temp[1] = radius		//changed in loop
//	sphere_temp[2] = delrho
//	sphere_temp[3] = 0
//	
//// evaluate at Gauss points 
//	summ = 0.0		// initialize integral
//   	for(ii=0;ii<nord;ii+=1)
//		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0
//		sphere_temp[1] = zi		
//		yyy = gauWt[ii] * Schulz_Point(zi,radius,zz) * SphereForm(sphere_temp,x)
//		//un-normalize by volume
//		yyy *= 4*pi/3*zi^3
//		summ += yyy
//	endfor
//// calculate value of integral to return
//   	answer = (vb-va)/2.0*summ
//   	
//   	//re-normalize by the average volume
//   	zp1 = zz + 1.
//		zp2 = zz + 2.
//		zp3 = zz + 3.
//		vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(radius)^3
//  	answer /= vpoly
////scale
//	answer *= scale
//// add in the background
//	answer += bkg
//
//	Return (answer)
//End
//