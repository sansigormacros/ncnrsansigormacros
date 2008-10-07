#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0


////////////////////////////////////////////////
// this procedure is for the Teubner-Strey Model
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotTeubnerStreyModel(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_ts,ywave_ts
	xwave_ts =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_ts = {0.1,-30,5000,0.1}
	make/o/t parameters_ts = {"scale (a2)","c1","c2","bkg"}
	Edit parameters_ts,coef_ts
	Variable/G root:g_ts
	g_ts := TeubnerStreyModel(coef_ts,ywave_ts,xwave_ts)
//	ywave_ts := TeubnerStreyModel(coef_ts,xwave_ts)
	Display ywave_ts vs xwave_ts
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)

	AddModelToStrings("TeubnerStreyModel","coef_ts","ts")
End

///////////////////////////////////////////////////////////

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedTeubnerStreyModel(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ts = {0.1,-30,5000,0.1}
	make/o/t smear_parameters_ts = {"scale (a2)","c1","c2","bkg"}
	Edit smear_parameters_ts,smear_coef_ts
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_ts,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_ts			
		
	Variable/G gs_ts=0
	gs_ts := fSmearedTeubnerStreyModel(smear_coef_ts,smeared_ts,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_ts vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedTeubnerStreyModel","smear_coef_ts","ts")
End

//AAO version
Function TeubnerStreyModel(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("TeubnerStreyModelX")
	yw = TeubnerStreyModelX(cw,xw)
#else
	yw = fTeubnerStreyModel(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fTeubnerStreyModel(w,x) : FitFunc
	Wave w;Variable x
	
	//Varialbes are:
	//[0]	scale factor a2
	//[1] 	coeff c1
	//[2]	coeff c2
	//[3] 	incoh. background
	
	Variable inten,q2,q4
	
	q2 = x*x
	q4 = q2*q2
	inten = 1.0/(w[0]+w[1]*q2+w[2]*q4)
	inten += w[3]
	
	return (inten)
	
End	

Macro TeubnerStreyLengths()
	If(exists("coef_ts")!=1)		//coefficients don't exist
		Abort "You must plot the Teubner-Strey model before calculating the lengths"
	Endif
	// calculate the correlation length and the repeat distance
	Variable a2,c1,c2,xi,dd
	a2 = coef_ts[0]
	c1 = coef_ts[1]
	c2 = coef_ts[2]
	
	xi = 0.5*sqrt(a2/c2) + c1/4/c2
	xi = 1/sqrt(xi)
	
	dd = 0.5*sqrt(a2/c2) - c1/4/c2
	dd = 1/sqrt(dd)
	dd *=2*Pi
	
	Printf "The correlation length (the dispersion of d) xi = %g A\r",xi
	Printf "The quasi-periodic repeat distance, d = %g A\r",dd
	
End

// this is all there is to the smeared calculation!
Function SmearedTeubnerStreyModel(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(TeubnerStreyModel,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedTeubnerStreyModel(coefW,yW,xW)
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
	err = SmearedTeubnerStreyModel(fs)
	
	return (0)
End