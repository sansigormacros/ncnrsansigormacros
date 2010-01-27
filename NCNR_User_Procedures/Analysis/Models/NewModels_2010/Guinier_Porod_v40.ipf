#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// this procedure calculates an empirical Guinier-Porod scattering function
//
// 25 JAN 2010 BH
// updated SRK
//
//
////////////////////////////////////////////////

Proc PlotGuinierPorod(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_GP,ywave_GP					
	xwave_GP = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_GP = {1., 1, 100, 3, 0.1}						
	make/o/t parameters_GP = {"Guinier Scale", "Dimension Variable, s","Rg [A]","Porod Exponent","Bgd [cm-1]"}		
	Edit parameters_GP,coef_GP	
	Variable/G root:g_GP=0			
	root:g_GP := GuinierPorod(coef_GP,ywave_GP,xwave_GP)	// AAO calculation, "fake" dependency
	Display ywave_GP vs xwave_GP							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("GuinierPorod","coef_GP","parameters_GP","GP")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedGuinierPorod(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_GP = {1., 1, 100, 3, 0.1}					
	make/o/t smear_parameters_GP = {"Guinier Scale", "Dimension Variable, s","Rg [A]","Porod Exponent","Bgd [cm-1]"}
	Edit smear_parameters_GP,smear_coef_GP					
	
	Duplicate/O $(str+"_q") smeared_GP,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_GP					
		
	Variable/G gs_GP=0
	gs_GP := fSmearedGuinierPorod(smear_coef_GP,smeared_GP,smeared_qvals)	//this wrapper fills the STRUCT
	Display smeared_GP vs smeared_qvals								
	
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedGuinierPorod","smear_coef_GP","smear_parameters_GP","GP")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)

// Using MultiThread keyword:
// 1.2x speedup for 1000 points (yawn)
// !! 3.0x SLOWER for 100 points (ouch!)
Function GuinierPorod(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)
	
#if exists("GuinierPorodX")
	yw = GuinierPorodX(cw,xw)
#else
	yw = fGuinierPorod(cw,xw)
#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
// this is a "regular" calculation at a single q-value
///////////////////////////
Function fGuinierPorod(w,x)					
	Wave w
	Variable x
	
//	 Input (fitting) variables are:
	//[0] guinier scale
	//[1] dimension, s
	//[2] radius of gyration
	//[3] porod exponent
	//[4] incoherent background
	
//	give them nice names
	Variable G,Rg,m,bgd,q1,C,F,n,s
	G = w[0]
	s = w[1]
	Rg = w[2]
	m =w[3]
	bgd =w[4]
	
	n = 3-s
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	q1=sqrt((n-3+m)*n/2)/Rg

//	C=G*exp((-q1^2*Rg^2)/n)*q1^(n-3+m)
//	if(qval < q1)
//	F = (G/qval^(3-n))*exp((-qval^2*Rg^2)/n)
//	else
//	F = C/qval^m
//	endif

//	F = (G/qval^(3-n))*exp((-qval^2*Rg^2)/n) + (G/qval^m)*exp(-(n-3+m)/2)*((n-3+m)*n/2)^((n-3+m)/2)/Rg^(n-3+m)
	
	if(qval < q1)
		F = (G/qval^(3-n))*exp((-qval^2*Rg^2)/n) 
	else
		F = (G/qval^m)*exp(-(n-3+m)/2)*((n-3+m)*n/2)^((n-3+m)/2)/Rg^(n-3+m)
	endif

	inten = F + bgd

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
Function fSmearedGuinierPorod(coefW,yW,xW)
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
	err = SmearedGuinierPorod(fs)
	
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
Function SmearedGuinierPorod(s) : FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(GuinierPorod,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
 