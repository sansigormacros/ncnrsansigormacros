#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// plots scattering from a mass fractal object
// uses the model of Teixeria
//
// REFERENCE: J. Appl. Cryst. vol 21, p781-785
//  Uses eq.1, 4, and 16
//
// - basic subunit is a polydisperse (Schulz) sphere - SRK July 2008
//
// Macro for fractal parameters added JGB 2004

Proc PlotFractalPolySphere(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fraPolySph,ywave_fraPolySph					
	xwave_fraPolySph = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_fraPolySph = {0.05,5,0.1,2,100,2e-6,6.35e-6,0}						
	make/o/t parameters_fraPolySph = {"Volume Fraction (scale)","Block Radius (A)","block polydispersity (0,1)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}		
	Edit parameters_fraPolySph,coef_fraPolySph		
	
	Variable/G root:g_fraPolySph
	g_fraPolySph := FractalPolySphere(coef_fraPolySph,ywave_fraPolySph,xwave_fraPolySph)			
	Display ywave_fraPolySph vs xwave_fraPolySph							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FractalPolySphere","coef_fraPolySph","parameters_fraPolySph","fraPolySph")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFractalPolySphere(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fraPolySph =  {0.05,5,0.1,2,100,2e-6,6.35e-6,0}
	make/o/t smear_parameters_fraPolySph = {"Volume Fraction (scale)","Block Radius (A)","block polydispersity (0,1)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}
	Edit smear_parameters_fraPolySph,smear_coef_fraPolySph					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fraPolySph,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fraPolySph						//
					
	Variable/G gs_fraPolySph=0
	gs_fraPolySph := fSmearedFractalPolySphere(smear_coef_fraPolySph,smeared_fraPolySph,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fraPolySph vs smeared_qvals		
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFractalPolySphere","smear_coef_fraPolySph","smear_parameters_fraPolySph","fraPolySph")
End



//calculates the physical parameters related to the 
//model parameters. See the reference at the top of the 
//file for details
//
// this macro is currently only appicable to the monodisperse case and must be appropriately
// modified before use
//
//Macro NumberDensity_FractalPolySphere()
//	
//	Variable nden,phi,r0,Df,corr,s0,vpoly,i0,rg
//	
//	if(Exists("coef_fraPolySph")!=1)
//		abort "You need to plot the unsmeared model first to create the coefficient table"
//	Endif
//	
//	phi = coef_fraPolySph[0]   // volume fraction of building blocks
//	r0 = coef_fraPolySph[1]    // building block radius
//	Df = coef_fraPolySph[2]    // fractal dimension
//	corr = coef_fraPolySph[3]  // fractal correlation length (of cluster)
//	
//	Print "mean building block radius (A) = ",r0
//	Print "volume fraction = ",phi
//	
// //  average particle volume   	
//	vpoly = 4*Pi/3*r0^3
//	nden = phi/vpoly		//nden in 1/A^3
//	i0 = 1.0e8*phi*vpoly*(coef_fraPolySph[4]-coef_fraPolySph[5])^2  // 1/cm/sr
//	rg = corr*( Df*(Df+1)/2 )^0.5
//	s0 = exp(gammln(Df+1))*(corr/r0)^Df
//	Print "number density (A^-3) = ",nden
//	Print "Guinier radius (A) = ",rg
//	Print "Aggregation number G = ",s0
//	Print "Forward cross section of building blocks (cm-1 sr-1) I(0) = ",i0
//	Print "Forward cross section of clusters (cm-1 sr-1) I(0) = ",i0*s0
//End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FractalPolySphere(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FractalPolySphereX")
	yw = FractalPolySphereX(cw,xw)
#else
	yw = fFractalPolySphere(cw,xw)
#endif
	return(0)
End

//fractal scattering function
Function fFractalPolySphere(w,x) :FitFunc
	wave w
	variable x
	
	variable r0,Df,corr,phi,sldp,sldm,bkg
	variable pq,sq,ans,pd
	phi=w[0]   // volume fraction of building block spheres...
	r0=w[1]    //  radius of building block
	pd = w[2]		// polydispersity of sphere
	Df=w[3]     //  fractal dimension
	corr=w[4] //  correlation length of fractal-like aggregates
	sldp = w[5] // SLD of building block
	sldm = w[6] // SLD of matrix or solution
	bkg=w[7]  //  flat background
	
	//calculate P(q) for the spherical subunits, units cm-1 sr-1
//	pq = 1.0e8*phi*4/3*pi*r0^3*(sldp-sldm)^2*(3*(sin(x*r0) - x*r0*cos(x*r0))/(x*r0)^3)^2
	Make/O/D/N=6 tmp_SchSph
	tmp_SchSph[0] = phi
	tmp_SchSph[1] = r0
	tmp_SchSph[2] = pd
	tmp_SchSph[3] = sldp
	tmp_SchSph[4] = sldm
	tmp_SchSph[5] = 0

#if exists("SchulzSpheresX")
	pq = SchulzSpheresX(tmp_SchSph,x)
#else
	pq = fSchulzSpheres(tmp_SchSph,x)
#endif

	//calculate S(q)
	sq = Df*exp(gammln(Df-1))*sin((Df-1)*atan(x*corr))
	sq /= (x*r0)^Df * (1 + 1/(x*corr)^2)^((Df-1)/2)
	sq += 1
	//combine and return
	ans = pq*sq + bkg

	return (ans)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFractalPolySphere(coefW,yW,xW)
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
	err = SmearedFractalPolySphere(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedFractalPolySphere(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FractalPolySphere,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End