#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1


#include "FlexCyl_PolyRadius_v40"   //(this in turn includes Flexible Cylinder, which is needed for Rg calculation)


// 23 MAY 2012 - SRK / Y. Liu
//
// plots scattering from a mass fractal object
// uses the model of Teixeria using a flexible cylinder (polydisperse radius) as the "building block"
// - so the radius in the fractal S(q) is the Rg of the flexible chain
//
// - as long as the fractal length scale (correlation length) and the Rg of the 
//   chain are very different (so the that fractal knows no details of the chain
//   structure, then this should be fine)
//
// REFERENCE: J. Appl. Cryst. vol 21, p781-785
//  Uses eq.1, 4, and 16
//
// Macro for fractal parameters added JGB 2004

Proc PlotFractalFlexCylPRad(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fraFlePR,ywave_fraFlePR					
	xwave_fraFlePR = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_fraFlePR = {0.05,2,500,2e-6,6.35e-6,100,30,15,0.2,0}						
	make/o/t parameters_fraFlePR = {"Volume Fraction (scale)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","Contour Length (A)","Kuhn Length, b (A)","Cylinder Radius (A)","polydisp of Radius","bkgd (cm^-1 sr^-1)"}		
	Edit parameters_fraFlePR,coef_fraFlePR		
	
	Variable/G root:g_fraFlePR
	g_fraFlePR := FractalFlexCylPRad(coef_fraFlePR,ywave_fraFlePR,xwave_fraFlePR)			
	Display ywave_fraFlePR vs xwave_fraFlePR							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FractalFlexCylPRad","coef_fraFlePR","parameters_fraFlePR","fraFlePR")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFractalFlexCylPRad(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fraFlePR =  {0.05,2,500,2e-6,6.35e-6,100,30,15,0.2,0}
	make/o/t smear_parameters_fraFlePR = {"Volume Fraction (scale)","fractal dimension","correlation length (A)","SLD block (A-2)","SLD solvent (A-2)","Contour Length (A)","Kuhn Length, b (A)","Cylinder Radius (A)","polydisp of Radius","bkgd (cm^-1 sr^-1)"}
	Edit smear_parameters_fraFlePR,smear_coef_fraFlePR					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fraFlePR,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fraFlePR						//
					
	Variable/G gs_fraFlePR=0
	gs_fraFlePR := fSmearedFractalFlexCylPRad(smear_coef_fraFlePR,smeared_fraFlePR,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fraFlePR vs smeared_qvals		
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFractalFlexCylPRad","smear_coef_fraFlePR","smear_parameters_fraFlePR","fraFlePR")
End



////calculates the physical parameters related to the 
////model parameters. See the reference at the top of the 
////file for details
//Macro NumberDensity_FractalFlexCylPRad()
//	
//	Variable nden,phi,r0,Df,corr,s0,vpoly,i0,rg
//	
//	if(Exists("coef_fraFlePR")!=1)
//		abort "You need to plot the unsmeared model first to create the coefficient table"
//	Endif
//	
//	phi = coef_fraFlePR[0]   // volume fraction of building blocks
//	r0 = coef_fraFlePR[1]    // building block radius
//	Df = coef_fraFlePR[2]    // fractal dimension
//	corr = coef_fraFlePR[3]  // fractal correlation length (of cluster)
//	
//	Print "mean building block radius (A) = ",r0
//	Print "volume fraction = ",phi
//	
// //  average particle volume   	
//	vpoly = 4*Pi/3*r0^3
//	nden = phi/vpoly		//nden in 1/A^3
//	i0 = 1.0e8*phi*vpoly*(coef_fraFlePR[4]-coef_fraFlePR[5])^2  // 1/cm/sr
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
Function FractalFlexCylPRad(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FractalFlexCylPRadX")
	yw = FractalFlexCylPRadX(cw,xw)
#else
	yw = fFractalFlexCylPRad(cw,xw)
#endif
	return(0)
End

//fractal scattering function
Function fFractalFlexCylPRad(w,x) :FitFunc
	wave w
	variable x
	
	variable r0,Df,corr,phi,sldp,sldm,bkg,bes,Lc,kuhn,Rcyl,pd
	variable pq,sq,ans
	phi=w[0]   // volume fraction of building block spheres...
	Df=w[1]     //  fractal dimension
	corr=w[2] //  correlation length of fractal-like aggregates
	sldp = w[3] // SLD of building block
	sldm = w[4] // SLD of matrix or solution
	Lc = w[5]		//contour length of flexible cylinders
	kuhn = w[6]	// kuhn length
	Rcyl = w[7]		//cylinder radius
	pd = w[8]		//polydispersity of radius
	bkg=w[9]  //  flat background
	
	//calculate P(q) for the FlexibleCylinder subunits, units cm-1 sr-1
	Make/O/D/N=8 tmp_Pq_flePR
	tmp_Pq_flePR[0] = phi
	tmp_Pq_flePR[1] = Lc
	tmp_Pq_flePR[2] = kuhn
	tmp_Pq_flePR[3] = Rcyl
	tmp_Pq_flePR[4] = pd
	tmp_Pq_flePR[5] = sldp
	tmp_Pq_flePR[6] = sldm
	tmp_Pq_flePR[7] = 0		//set to zero here, add in at the end

//	pq = fFlexCyl_PolyRad(tmp_Pq_flePR,x)
	
	pq = FlexCyl_PolyRadX(tmp_Pq_flePR,x)		//use the XOP
	
	// calculate Rg of the flexible cylinders
	
	r0 = sqrt(Rgsquare(x,Lc,kuhn)) // from Wei-Ren's paper, and his code for the flexible cylinder
	
	//calculate S(q)
	// could call the Fractal function, but the calculation is so simple.
	
	sq = Df*exp(gammln(Df-1))*sin((Df-1)*atan(x*corr))
	sq /= (x*r0)^Df * (1 + 1/(x*corr)^2)^((Df-1)/2)
	sq += 1

	//combine and return
	ans = pq*sq + bkg
//	ans = sq

	return (ans)
End




//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFractalFlexCylPRad(coefW,yW,xW)
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
	err = SmearedFractalFlexCylPRad(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedFractalFlexCylPRad(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FractalFlexCylPRad,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End