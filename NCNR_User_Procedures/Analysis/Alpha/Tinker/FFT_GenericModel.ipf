#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
//
// This is a proof of principle to convert a structure built of spheres
// into a fitting function that can be used for simulation
// the "model function" is nothing but a scale and background on top of
// whatever is calculated from the FFT
//
//
//	N=256 and T=5 are relatively good choices for simulating SANS
// Qmin = 0.005 and Qmax = 0.62
// -- Qmin = 2*pi/(N*T)
// -- Qmax = pi/T
//
//
//
////////////////////////////////////////////////

Proc PlotGenericFFT(num,qmin,qmax)
	Variable num=100,qmin=0.004,qmax=0.4
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/D/n=(num) xwave_genFFT,ywave_genFFT
	xwave_genFFT =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_genFFT = {1,0.001}
	make/o/t parameters_genFFT = {"scale","incoh. bkg (cm^-1)"}
	Edit parameters_genFFT,coef_genFFT
	Variable/G root:g_genFFT
	g_genFFT := GenericFFT(coef_genFFT,ywave_genFFT,xwave_genFFT)

	Display ywave_genFFT vs xwave_genFFT
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("GenericFFT","coef_genFFT","parameters_genFFT","genFFT")
End

/////////////////////////////////////////////////////////////
//// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedGenericFFT(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_genFFT = {1,0.001}
	make/o/t smear_parameters_genFFT = {"scale","incoh. bkg (cm^-1)"}
	Edit smear_parameters_genFFT,smear_coef_genFFT
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_genFFT,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_genFFT	
					
	Variable/G gs_genFFT=0
	gs_genFFT := fSmearedGenericFFT(smear_coef_genFFT,smeared_genFFT,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_genFFT vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedGenericFFT","smear_coef_genFFT","smear_parameters_genFFT","genFFT")
End

// The calculation is inherently AAO, so it's all done here, not passed to another FitFunc
//
Function GenericFFT(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

//The input variables are (and output)
	//[0] scale
	//[1] background (cm^-1)
	Variable scale,bkg
	scale = cw[0]
	bkg = cw[1]

	yw=0
	
// do the calculation , if mat has been defined

	if(exists("root:mat")==1)
		Calc_IQ_FFT()
		
		Wave iBin=root:iBin
		Wave qBin=root:qBin
		
		// now interpoate to the requested q-values	
		// fft is already scaled to proper intensity units
		//	Variable frac
		//	frac = VolumeFraction_Occ(m)
	
		yw = interp(xw[p], qBin, iBin )
	endif
	
	yw *= scale
	yw += bkg

//	Print "elapsed time for unsmeared = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End


//
// this is all there is to the smeared calculation!
Function SmearedGenericFFT(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(GenericFFT,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
//
//
////wrapper to calculate the smeared model as an AAO-Struct
//// fills the struct and calls the ususal function with the STRUCT parameter
////
//// used only for the dependency, not for fitting
////
Function fSmearedGenericFFT(coefW,yW,xW)
	Wave coefW,yW,xW
	
//	Variable t1=StopMSTimer(-2)

	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedGenericFFT(fs)

//	Print "elapsed time for smeared = ",(StopMSTimer(-2) - t1)/1e6
	
	return (0)
End