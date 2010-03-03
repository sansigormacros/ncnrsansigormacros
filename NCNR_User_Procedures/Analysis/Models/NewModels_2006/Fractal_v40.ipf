#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// plots scattering from a mass fractal object
// uses the model of Teixeria
//
// REFERENCE: J. Appl. Cryst. vol 21, p781-785
//  Uses eq.1, 4, and 16
//
// Macro for fractal parameters added JGB 2004

Proc PlotFractal(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fra,ywave_fra					
	xwave_fra = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_fra = {0.05,5,2,100,2e-6,6.35e-6,0}						
	make/o/t parameters_fra = {"Volume Fraction (scale)","Block Radius (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}		
	Edit parameters_fra,coef_fra		
	
	Variable/G root:g_fra
	g_fra := Fractal(coef_fra,ywave_fra,xwave_fra)			
	Display ywave_fra vs xwave_fra							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Fractal","coef_fra","parameters_fra","fra")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFractal(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fra =  {0.05,5,2,100,2e-6,6.35e-6,0}
	make/o/t smear_parameters_fra = {"Volume Fraction (scale)","Block Radius (A)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","bkgd (cm^-1 sr^-1)"}
	Edit smear_parameters_fra,smear_coef_fra					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fra,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fra						//
					
	Variable/G gs_fra=0
	gs_fra := fSmearedFractal(smear_coef_fra,smeared_fra,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fra vs smeared_qvals		
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFractal","smear_coef_fra","smear_parameters_fra","fra")
End



//calculates the physical parameters related to the 
//model parameters. See the reference at the top of the 
//file for details
Macro NumberDensity_Fractal()
	
	Variable nden,phi,r0,Df,corr,s0,vpoly,i0,rg
	
	if(Exists("coef_fra")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	phi = coef_fra[0]   // volume fraction of building blocks
	r0 = coef_fra[1]    // building block radius
	Df = coef_fra[2]    // fractal dimension
	corr = coef_fra[3]  // fractal correlation length (of cluster)
	
	Print "mean building block radius (A) = ",r0
	Print "volume fraction = ",phi
	
 //  average particle volume   	
	vpoly = 4*Pi/3*r0^3
	nden = phi/vpoly		//nden in 1/A^3
	i0 = 1.0e8*phi*vpoly*(coef_fra[4]-coef_fra[5])^2  // 1/cm/sr
	rg = corr*( Df*(Df+1)/2 )^0.5
	s0 = exp(gammln(Df+1))*(corr/r0)^Df
	Print "number density (A^-3) = ",nden
	Print "Guinier radius (A) = ",rg
	Print "Aggregation number G = ",s0
	Print "Forward cross section of building blocks (cm-1 sr-1) I(0) = ",i0
	Print "Forward cross section of clusters (cm-1 sr-1) I(0) = ",i0*s0
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Fractal(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FractalX")
	yw = FractalX(cw,xw)
#else
	yw = fFractal(cw,xw)
#endif
	return(0)
End

//fractal scattering function
Function fFractal(w,x) :FitFunc
	wave w
	variable x
	
	variable r0,Df,corr,phi,sldp,sldm,bkg,bes
	variable pq,sq,ans
	phi=w[0]   // volume fraction of building block spheres...
	r0=w[1]    //  radius of building block
	Df=w[2]     //  fractal dimension
	corr=w[3] //  correlation length of fractal-like aggregates
	sldp = w[4] // SLD of building block
	sldm = w[5] // SLD of matrix or solution
	bkg=w[6]  //  flat background
	
	//calculate P(q) for the spherical subunits, units cm-1 sr-1
	if(x*r0 == 0)
		bes = 1
	else
		bes = (3*(sin(x*r0) - x*r0*cos(x*r0))/(x*r0)^3)^2
	endif
	
	pq = 1.0e8*phi*4/3*pi*r0^3*(sldp-sldm)^2*bes

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
Function fSmearedFractal(coefW,yW,xW)
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
	err = SmearedFractal(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedFractal(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Fractal,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End