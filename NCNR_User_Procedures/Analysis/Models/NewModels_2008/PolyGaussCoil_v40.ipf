#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0


//
// this function is for the form factor of polydisperse Gaussian coil
//
// -- see Boualem's book - pg 298 (Higgins and Benoit)
// -- Glatter & Kratky - pg.404
//
// June 2008 SRK
////////////////////////////////////////////////

Proc PlotPolyGaussCoil(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_pgc,ywave_pgc
	xwave_pgc =alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_pgc = {1.,60,2,0.001}
	make/o/t parameters_pgc = {"scale","Rg (A)","polydispersity (Mw/Mn)","bkg (cm-1)"}
	Edit parameters_pgc,coef_pgc
	Variable/G root:g_pgc
	g_pgc := PolyGaussCoil(coef_pgc,ywave_pgc,xwave_pgc)
//	ywave_pgc := PolyGaussCoil(coef_pgc,xwave_pgc)
	Display ywave_pgc vs xwave_pgc
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyGaussCoil","coef_pgc","parameters_pgc","pgc")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyGaussCoil(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/d smear_coef_pgc = {1.,60,2,0.001}
	make/o/t smear_parameters_pgc = {"scale","Rg (A)","polydispersity (Mw/Mn)","bkg (cm-1)"}
	Edit smear_parameters_pgc,smear_coef_pgc
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	
	Duplicate/O $(str+"_q") smeared_pgc,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgc							
					
	Variable/G gs_pgc=0
	gs_pgc := fSmearedPolyGaussCoil(smear_coef_pgc,smeared_pgc,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_pgc vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyGaussCoil","smear_coef_pgc","smear_parameters_pgc","pgc")
End


//AAO version
Function PolyGaussCoil(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("PolyGaussCoilX")
	yw = PolyGaussCoilX(cw,xw)
#else
	yw = fPolyGaussCoil(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fPolyGaussCoil(w,x) : FitFunc
	Wave w
	Variable x
	
	//assign nice names to the input wave
	//w[0] = scale
	//w[1] = radius of gyration [Å]
	//w[2] = polydispersity, ratio of Mw/Mn
	//w[3] = bkg [cm-1]
	Variable scale,bkg,Rg,uval,Mw_Mn
		
	scale = w[0]
	Rg = w[1]
	Mw_Mn = w[2]
	bkg = w[3]
	
	uval = Mw_Mn - 1
	if(uval == 0)
		uval = 1e-6		//avoid divide by zero error
	endif
	//calculations on input parameters
	
	//local variables
	Variable xi,inten
	
	xi = Rg^2*x^2/(1+2*uval)
	
	if(xi < 1e-3)
		return(scale+bkg)		//limiting value
	endif
	
	inten = 2*((1+uval*xi)^(-1/uval)+xi-1)
	inten /= (1+uval)*xi^2

	inten *= scale
	//add in the background
	inten += bkg
      
	Return (inten)
End

// this is all there is to the smeared calculation!
Function SmearedPolyGaussCoil(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(PolyGaussCoil,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyGaussCoil(coefW,yW,xW)
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
	err = SmearedPolyGaussCoil(fs)
	
	return (0)
End