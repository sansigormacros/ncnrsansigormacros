#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


/////////////////////////////////////////////////////
//
// Plot's Greg Beaucage's Rg-power Law "model" of scattering
// somewhat useful for identifying length scales, but short on
// physical inerpretation of the real structure of the sample.
//
// up to 4 "levels" can be calculated
// best to start with single level, and fit a small range of
// the data, and add more levels as needed
//
// see the help file for the original references
//
Proc PlotOnelevelSWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b1SWB,ywave_b1SWB
	xwave_b1SWB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b1SWB = {1,3,21,6e-4,2,0}
	make/o/t parameters_b1SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","bkg (cm-1 sr-1)"}
	Edit parameters_b1SWB,coef_b1SWB
	
	Variable/G root:g_b1SWB
	g_b1SWB := OneLevelSWB(coef_b1SWB,ywave_b1SWB,xwave_b1SWB)
	Display ywave_b1SWB vs xwave_b1SWB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("OneLevelSWB","coef_b1SWB","parameters_b1SWB","b1SWB")
End

Proc PlotTwoLevelSWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b2SWB,ywave_b2SWB
	xwave_b2SWB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b2SWB = {1,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b2SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","bkg (cm-1 sr-1)"}
	Edit parameters_b2SWB,coef_b2SWB
	
	Variable/G root:g_b2SWB
	g_b2SWB := TwoLevelSWB(coef_b2SWB,ywave_b2SWB,xwave_b2SWB)
	Display ywave_b2SWB vs xwave_b2SWB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("TwoLevelSWB","coef_b2SWB","parameters_b2SWB","b2SWB")
End

Proc PlotThreeLevelSWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b3SWB,ywave_b3SWB
	xwave_b3SWB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b3SWB = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b3SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","bkg (cm-1)"}
	Edit parameters_b3SWB,coef_b3SWB
	
	Variable/G root:g_b3SWB
	g_b3SWB := ThreeLevelSWB(coef_b3SWB,ywave_b3SWB,xwave_b3SWB)	
	Display ywave_b3SWB vs xwave_b3SWB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("ThreeLevelSWB","coef_b3SWB","parameters_b3SWB","b3SWB")
End

Proc PlotFourLevelSWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b4SWB,ywave_b4SWB
	xwave_b4SWB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b4SWB = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b4SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1 A^-Pow)","Pow4","bkg (cm-1)"}
	Edit parameters_b4SWB,coef_b4SWB
	
	Variable/G root:g_b4SWB
	g_b4SWB := FourLevelSWB(coef_b4SWB,ywave_b4SWB,xwave_b4SWB)	
	Display ywave_b4SWB vs xwave_b4SWB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FourLevelSWB","coef_b4SWB","parameters_b4SWB","b4SWB")
End

/////////// macros for smeared model calculations

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOneLevelSWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b1SWB ={1,3,21,6e-4,2,0}					
	make/o/t smear_parameters_b1SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b1SWB,smear_coef_b1SWB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b1SWB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b1SWB							
					
	Variable/G gs_b1SWB=0
	gs_b1SWB := fSmearedOneLevelSWB(smear_coef_b1SWB,smeared_b1SWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b1SWB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOneLevelSWB","smear_coef_b1SWB","smear_parameters_b1SWB","b1SWB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedTwoLevelSWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b2SWB = {1,400,200,5e-6,4,3,21,6e-4,2,0}				
	make/o/t smear_parameters_b2SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b2SWB,smear_coef_b2SWB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b2SWB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b2SWB							
					
	Variable/G gs_b2SWB=0
	gs_b2SWB := fSmearedTwoLevelSWB(smear_coef_b2SWB,smeared_b2SWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b2SWB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedTwoLevelSWB","smear_coef_b2SWB","smear_parameters_b2SWB","b2SWB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedThreeLevelSWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b3SWB = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t smear_parameters_b3SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","bkg (cm-1)"}
	Edit smear_parameters_b3SWB,smear_coef_b3SWB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b3SWB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b3SWB							
					
	Variable/G gs_b3SWB=0
	gs_b3SWB := fSmearedThreeLevelSWB(smear_coef_b3SWB,smeared_b3SWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b3SWB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedThreeLevelSWB","smear_coef_b3SWB","smear_parameters_b3SWB","b3SWB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFourLevelSWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b4SWB = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	Make/o/t smear_parameters_b4SWB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1 A^-Pow)","Pow4","bkg (cm-1)"}
	Edit smear_parameters_b4SWB,smear_coef_b4SWB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b4SWB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b4SWB							
					
	Variable/G gs_b4SWB=0
	gs_b4SWB := fSmearedFourLevelSWB(smear_coef_b4SWB,smeared_b4SWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b4SWB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFourLevelSWB","smear_coef_b4SWB","smear_parameters_b4SWB","b4SWB")
End
	



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function OneLevelSWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("OneLevelX")
//	yw = OneLevelX(cw,xw)
	yw = V_fOneLevelSWB(cw,xw)
#else
//	yw = fOneLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

//////////Function definitions

Function V_fOneLevelSWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 20/5.3
	
	inten = V_IntegrOneLevelSWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 30955		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrOneLevelSWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_OneLevelSWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_OneLevelSWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_SuperWhiteBeamDist_mid(dum*5.3)*OneLevelX(cw,qq/dum)
	
	return (val)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function TwoLevelSWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("TwoLevelX")
//	yw = TwoLevelX(cw,xw)
	yw = V_fTwoLevelSWB(cw,xw)
#else
//	yw = fTwoLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

Function V_fTwoLevelSWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 20/5.3
	
	inten = V_IntegrTwoLevelSWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 30955		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)

End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrTwoLevelSWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_TwoLevelSWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_TwoLevelSWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_SuperWhiteBeamDist_mid(dum*5.3)*TwoLevelX(cw,qq/dum)
	
	return (val)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function ThreeLevelSWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("ThreeLevelX")
//	yw = ThreeLevelX(cw,xw)
	yw = V_fThreeLevelSWB(cw,xw)
#else
//	yw = fThreeLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

Function V_fThreeLevelSWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 20/5.3
	
	inten = V_IntegrThreeLevelSWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 30955		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrThreeLevelSWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_ThreeLevelSWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_ThreeLevelSWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_SuperWhiteBeamDist_mid(dum*5.3)*ThreeLevelX(cw,qq/dum)
	
	return (val)
End


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FourLevelSWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FourLevelX")
//	yw = FourLevelX(cw,xw)
	yw = V_fFourLevelSWB(cw,xw)
#else
//	yw = fFourLevel(cw,xw)
	yw = 1
#endif
	return(0)
End


Function V_fFourLevelSWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 20/5.3
	
	inten = V_IntegrFourLevelSWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 30955		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrFourLevelSWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_FourLevelSWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_FourLevelSWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_SuperWhiteBeamDist_mid(dum*5.3)*FourLevelX(cw,qq/dum)
	
	return (val)
End



Function SmearedOneLevelSWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(OneLevelSWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	

Function SmearedTwoLevelSWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(TwoLevelSWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	

Function SmearedThreeLevelSWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(ThreeLevelSWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

Function SmearedFourLevelSWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FourLevelSWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOneLevelSWB(coefW,yW,xW)
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
	err = SmearedOneLevelSWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedTwoLevelSWB(coefW,yW,xW)
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
	err = SmearedTwoLevelSWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedThreeLevelSWB(coefW,yW,xW)
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
	err = SmearedThreeLevelSWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFourLevelSWB(coefW,yW,xW)
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
	err = SmearedFourLevelSWB(fs)
	
	return (0)
End

