#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////////
//	J. Barker, 2-10-99
/////////////////////////////
Proc PlotLorentz_Model(num,qmin,qmax)
	Variable num=512, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	 Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_Lorentz, ywave_Lorentz
	xwave_Lorentz =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Lorentz = {100.0, 50.0, 1.0}
	make/o/t parameters_Lorentz = {"Scale Factor, I0 ", "Screening Length (A)","Incoherent Bgd (cm-1)"}
	Edit parameters_Lorentz, coef_Lorentz
	Variable/G root:g_Lorentz
	g_Lorentz  := Lorentz_Model(coef_Lorentz,ywave_Lorentz, xwave_Lorentz)
//	ywave_Lorentz  := Lorentz_Model(coef_Lorentz, xwave_Lorentz)
	Display ywave_Lorentz vs xwave_Lorentz
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log(left)=1
	Label bottom "q (A\\S-1\\M) "
	Label left "Lorentzian (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Lorentz_Model","coef_Lorentz","parameters_Lorentz","Lorentz")
End

////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedLorentz_Model(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Lorentz = {100.0, 50.0, 1.0}
	make/o/t smear_parameters_Lorentz = {"Scale Factor, I0 ", "Screening Length (A)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Lorentz,smear_coef_Lorentz					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Lorentz,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Lorentz							//					
		
	Variable/G gs_Lorentz=0
	gs_Lorentz := fSmearedLorentz_Model(smear_coef_Lorentz,smeared_Lorentz,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_Lorentz vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Lorentz Model (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
		
	SetDataFolder root:
	AddModelToStrings("SmearedLorentz_Model","smear_coef_Lorentz","smear_parameters_Lorentz","Lorentz")
End


//AAO version
Function Lorentz_model(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("Lorentz_modelX")
	yw = Lorentz_modelX(cw,xw)
#else
	yw = fLorentz_model(cw,xw)
#endif
	return(0)
End

Function fLorentz_model(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] screening length
	//[2] incoherent background
//	give them nice names
	Variable I0, L,bgd
	I0 = w[0]
	L = w[1]
	bgd = w[2]
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = I0/(1 + (qval*L)^2) + bgd
	Return (inten)
End
/////////////////////////////////////////////////////////////////////////////////


// this is all there is to the smeared calculation!
Function SmearedLorentz_Model(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(Lorentz_model,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedLorentz_Model(coefW,yW,xW)
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
	err = SmearedLorentz_Model(fs)
	
	return (0)
End