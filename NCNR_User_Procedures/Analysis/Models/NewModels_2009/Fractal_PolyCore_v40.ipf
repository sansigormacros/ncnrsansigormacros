#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// plots scattering from a mass fractal object
// uses the model of Teixeria
//
// REFERENCE: J. Appl. Cryst. vol 21, p781-785
//  Uses eq.1, 4, and 16
//
// - basic subunit is a polydisperse (Schulz) sphere w/ shell - SRK Jun 2009
// - based on two existing XOPs, so no need to write a new one
//
// Macro for fractal parameters added JGB 2004

Proc PlotFractalPolyCore(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fraPolyCore,ywave_fraPolyCore					
	xwave_fraPolyCore = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_fraPolyCore = {0.05,20,0.1,5,2,100,3.5e-6,1e-6,6.35e-6,0}						
	make/o/t parameters_fraPolyCore = {"Volume Fraction (scale)","Block Radius (A)","block polydispersity (0,1)","shell thickness (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}		
	Edit parameters_fraPolyCore,coef_fraPolyCore		
	
	Variable/G root:g_fraPolyCore
	g_fraPolyCore := FractalPolyCore(coef_fraPolyCore,ywave_fraPolyCore,xwave_fraPolyCore)			
	Display ywave_fraPolyCore vs xwave_fraPolyCore							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FractalPolyCore","coef_fraPolyCore","parameters_fraPolyCore","fraPolyCore")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFractalPolyCore(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fraPolyCore =  {0.05,20,0.1,5,2,100,3.5e-6,1e-6,6.35e-6,0}
	make/o/t smear_parameters_fraPolyCore = {"Volume Fraction (scale)","Block Radius (A)","block polydispersity (0,1)","shell thickness (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}
	Edit smear_parameters_fraPolyCore,smear_coef_fraPolyCore					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fraPolyCore,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fraPolyCore						//
					
	Variable/G gs_fraPolyCore=0
	gs_fraPolyCore := fSmearedFractalPolyCore(smear_coef_fraPolyCore,smeared_fraPolyCore,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fraPolyCore vs smeared_qvals		
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFractalPolyCore","smear_coef_fraPolyCore","smear_parameters_fraPolyCore","fraPolyCore")
End



//calculates the physical parameters related to the 
//model parameters. See the reference at the top of the 
//file for details
//
// this macro is currently only appicable to the monodisperse case and must be appropriately
// modified before use
//
//Macro NumberDensity_FractalPolyCore()
//	
//	Variable nden,phi,r0,Df,corr,s0,vpoly,i0,rg
//	
//	if(Exists("coef_fraPolyCore")!=1)
//		abort "You need to plot the unsmeared model first to create the coefficient table"
//	Endif
//	
//	phi = coef_fraPolyCore[0]   // volume fraction of building blocks
//	r0 = coef_fraPolyCore[1]    // building block radius
//	Df = coef_fraPolyCore[2]    // fractal dimension
//	corr = coef_fraPolyCore[3]  // fractal correlation length (of cluster)
//	
//	Print "mean building block radius (A) = ",r0
//	Print "volume fraction = ",phi
//	
// //  average particle volume   	
//	vpoly = 4*Pi/3*r0^3
//	nden = phi/vpoly		//nden in 1/A^3
//	i0 = 1.0e8*phi*vpoly*(coef_fraPolyCore[4]-coef_fraPolyCore[5])^2  // 1/cm/sr
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
Function FractalPolyCore(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FractalPolyCoreX")
	yw = FractalPolyCoreX(cw,xw)
#else
	yw = fFractalPolyCore(cw,xw)
#endif
	return(0)
End

//fractal scattering function
Function fFractalPolyCore(w,x) :FitFunc
	wave w
	variable x
	
	variable r0,Df,corr,phi,sldp,sldm,bkg
	variable pq,sq,ans,pd,thick,slds
	phi=w[0]   // volume fraction of building block spheres...
	r0=w[1]    //  radius of building block
	pd = w[2]		// polydispersity of core
	thick = w[3] // thell thickness
	Df=w[4]     //  fractal dimension
	corr=w[5] //  correlation length of fractal-like aggregates
	sldp = w[6] // SLD of building block
	slds = w[7]	//SLD of shell
	sldm = w[8] // SLD of matrix or solution
	bkg=w[9]  //  flat background
	
	//calculate P(q) for the spherical subunits, units cm-1 sr-1
	Make/O/D/N=8 tmp_PolyCor
	tmp_PolyCor[0] = phi
	tmp_PolyCor[1] = r0
	tmp_PolyCor[2] = pd
	tmp_PolyCor[3] = thick
	tmp_PolyCor[4] = sldp
	tmp_PolyCor[5] = slds
	tmp_PolyCor[6] = sldm
	tmp_PolyCor[7] = 0

#if exists("PolyCoreFormX")
	pq = PolyCoreFormX(tmp_PolyCor,x)
#else
	pq = fPolyCoreForm(tmp_PolyCor,x)
#endif

	//calculate S(q)
	sq = Df*exp(gammln(Df-1))*sin((Df-1)*atan(x*corr))
	sq /= (x*(r0+thick))^Df * (1 + 1/(x*corr)^2)^((Df-1)/2)
	sq += 1
	//combine and return
	//ans = pq*sq + bkg
	ans = pq +bkg
	
	return (ans)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFractalPolyCore(coefW,yW,xW)
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
	err = SmearedFractalPolyCore(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedFractalPolyCore(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FractalPolyCore,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End