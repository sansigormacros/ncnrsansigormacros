#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// this procedure calculates the scattering from a 
// polymer chain with excluded volume
//
// 25 JAN 2010 BH
// converted SRK
//
////////////////////////////////////////////////

Proc PlotPolymerExclVol(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PolExVol,ywave_PolExVol					
	xwave_PolExVol = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_PolExVol = {1, 100, 3,0}						
	make/o/t parameters_PolExVol = {"Scale Factor I0", "radius of gyration Rg [A]","Porod exponent m","Incoh Bgd (cm-1)"}		
	Edit parameters_PolExVol,coef_PolExVol	
	Variable/G root:g_PolExVol=0			
	root:g_PolExVol := PolymerExclVol(coef_PolExVol,ywave_PolExVol,xwave_PolExVol)	// AAO calculation, "fake" dependency
	Display ywave_PolExVol vs xwave_PolExVol							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolymerExclVol","coef_PolExVol","parameters_PolExVol","PolExVol")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolymerExclVol(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PolExVol = {1, 100, 3,0}					
	make/o/t smear_parameters_PolExVol = {"Scale Factor I0", "radius of gyration Rg [A]","Porod exponent m","Incoh Bgd (cm-1)"}
	Edit smear_parameters_PolExVol,smear_coef_PolExVol					
	
	Duplicate/O $(str+"_q") smeared_PolExVol,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_PolExVol					
		
	Variable/G gs_PolExVol=0
	gs_PolExVol := fSmearedPolymerExclVol(smear_coef_PolExVol,smeared_PolExVol,smeared_qvals)	//this wrapper fills the STRUCT
	Display smeared_PolExVol vs smeared_qvals								
	
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolymerExclVol","smear_coef_PolExVol","smear_parameters_PolExVol","PolExVol")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)

// Using MultiThread keyword:
// 1.2x speedup for 1000 points (yawn)
// !! 3.0x SLOWER for 100 points (ouch!)
Function PolymerExclVol(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)
	
#if exists("PolymerExclVolX")
	yw = PolymerExclVolX(cw,xw)
#else
	yw = fPolymerExclVol(cw,xw)
#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
// this is a "regular" calculation at a single q-value
///////////////////////////
Function fPolymerExclVol(w,x)					
	Wave w
	Variable x
	
//	 Input (fitting) variables are:
	//[0] I0 scale factor
	//[1] Rg
	//[2] m, Porod Exponent = 1/nu
	//[3] bgd incoherent background
//	give them nice names
	Variable I0, Rg, m, bgd,  nu, Xx, onu, o2nu, Ps, Debye
	I0 = w[0]
	Rg = w[1]
	m=w[2]
	bgd = w[3]
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
// 	Nn:degree of polymerization...nu:excluded volume parameter...bb:statistical segment length

	nu=1/m
	Xx=qval^2*Rg^2*(2*nu+1)*(2*nu+2)/6
	onu=1.0/(nu)
	o2nu=1.0/(2*nu)
	Ps=(1/(nu*Xx^o2nu))*(gammaInc(o2nu,Xx,0)-(1/Xx^o2nu)*gammaInc(onu,Xx,0))
	Debye=(2/Xx^2)*(exp(-Xx)-1+Xx)
	
	if(qval == 0)
		Ps = 1
	endif
	
	inten = I0*Ps + bgd 
	
//	inten = I0*Debye/(1+Vv*Debye) + bgd + Aa/qval^mm
//	print "exp(gammln(3/2))=",exp(gammln(3/2)) 
//	print Nn,alpha,Xx,onu,o2nu,Ps,int

	Return (inten)
	
End


//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct
// calls the ususal function with the STRUCT parameter
//
// -- problem- this assumes USANS w/no matrix
// -- needs experimental q-values to properly calculate the fitted curve?? is this true?
// -- how to fill the struct if the type of data is unknown?
// -- where do I find the matrix?
//
Function fSmearedPolymerExclVol(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW		//is this the proper way to populate? seems redundant...
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedPolymerExclVol(fs)
	
	return (0)
End

// smeared calculation, AAO and using a structure...
// defined as as STRUCT, there can never be a dependency linked directly to this function
// - so set a dependency to the wrapper
//
// like the unsmeared function, AAO is equivalent to a wave assignment to the point calculation
// - but now the function passed is an AAO function
//
// Smear_Model_20() takes care of what calculation is done, depending on the resolution information
//
//
Function SmearedPolymerExclVol(s) : FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(PolymerExclVol,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
 