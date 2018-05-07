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
Proc PlotOnelevelWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b1WB,ywave_b1WB
	xwave_b1WB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b1WB = {1,3,21,6e-4,2,0}
	make/o/t parameters_b1WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","bkg (cm-1 sr-1)"}
	Edit parameters_b1WB,coef_b1WB
	
	Variable/G root:g_b1WB
	g_b1WB := OneLevelWB(coef_b1WB,ywave_b1WB,xwave_b1WB)
	Display ywave_b1WB vs xwave_b1WB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("OneLevelWB","coef_b1WB","parameters_b1WB","b1WB")
End

Proc PlotTwoLevelWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b2WB,ywave_b2WB
	xwave_b2WB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b2WB = {1,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b2WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","bkg (cm-1 sr-1)"}
	Edit parameters_b2WB,coef_b2WB
	
	Variable/G root:g_b2WB
	g_b2WB := TwoLevelWB(coef_b2WB,ywave_b2WB,xwave_b2WB)
	Display ywave_b2WB vs xwave_b2WB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("TwoLevelWB","coef_b2WB","parameters_b2WB","b2WB")
End

Proc PlotThreeLevelWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b3WB,ywave_b3WB
	xwave_b3WB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b3WB = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b3WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","bkg (cm-1)"}
	Edit parameters_b3WB,coef_b3WB
	
	Variable/G root:g_b3WB
	g_b3WB := ThreeLevelWB(coef_b3WB,ywave_b3WB,xwave_b3WB)	
	Display ywave_b3WB vs xwave_b3WB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("ThreeLevelWB","coef_b3WB","parameters_b3WB","b3WB")
End

Proc PlotFourLevelWB(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/d/n=(num) xwave_b4WB,ywave_b4WB
	xwave_b4WB = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b4WB = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b4WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1 A^-Pow)","Pow4","bkg (cm-1)"}
	Edit parameters_b4WB,coef_b4WB
	
	Variable/G root:g_b4WB
	g_b4WB := FourLevelWB(coef_b4WB,ywave_b4WB,xwave_b4WB)	
	Display ywave_b4WB vs xwave_b4WB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FourLevelWB","coef_b4WB","parameters_b4WB","b4WB")
End

/////////// macros for smeared model calculations

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOneLevelWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b1WB ={1,3,21,6e-4,2,0}					
	make/o/t smear_parameters_b1WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b1WB,smear_coef_b1WB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b1WB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b1WB							
					
	Variable/G gs_b1WB=0
	gs_b1WB := fSmearedOneLevelWB(smear_coef_b1WB,smeared_b1WB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b1WB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOneLevelWB","smear_coef_b1WB","smear_parameters_b1WB","b1WB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedTwoLevelWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b2WB = {1,400,200,5e-6,4,3,21,6e-4,2,0}				
	make/o/t smear_parameters_b2WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b2WB,smear_coef_b2WB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b2WB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b2WB							
					
	Variable/G gs_b2WB=0
	gs_b2WB := fSmearedTwoLevelWB(smear_coef_b2WB,smeared_b2WB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b2WB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedTwoLevelWB","smear_coef_b2WB","smear_parameters_b2WB","b2WB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedThreeLevelWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b3WB = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t smear_parameters_b3WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","bkg (cm-1)"}
	Edit smear_parameters_b3WB,smear_coef_b3WB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b3WB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b3WB							
					
	Variable/G gs_b3WB=0
	gs_b3WB := fSmearedThreeLevelWB(smear_coef_b3WB,smeared_b3WB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b3WB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedThreeLevelWB","smear_coef_b3WB","smear_parameters_b3WB","b3WB")
End
	
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFourLevelWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b4WB = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	Make/o/t smear_parameters_b4WB = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1 A^-Pow)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1 A^-Pow)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1 A^-Pow)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1 A^-Pow)","Pow4","bkg (cm-1)"}
	Edit smear_parameters_b4WB,smear_coef_b4WB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_b4WB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b4WB							
					
	Variable/G gs_b4WB=0
	gs_b4WB := fSmearedFourLevelWB(smear_coef_b4WB,smeared_b4WB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_b4WB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFourLevelWB","smear_coef_b4WB","smear_parameters_b4WB","b4WB")
End
	



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function OneLevelWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("OneLevelX")
//	yw = OneLevelX(cw,xw)
	yw = V_fOneLevelWB(cw,xw)
#else
//	yw = fOneLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

//////////Function definitions

Function V_fOneLevelWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 8.37/5.3
	
	inten = V_IntegrOneLevelWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 19933		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrOneLevelWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_OneLevelWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_OneLevelWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_WhiteBeamDist_mid(dum*5.3)*OneLevelX(cw,qq/dum)
	
	return (val)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function TwoLevelWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("TwoLevelX")
//	yw = TwoLevelX(cw,xw)
	yw = V_fTwoLevelWB(cw,xw)
#else
//	yw = fTwoLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

Function V_fTwoLevelWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 8.37/5.3
	
	inten = V_IntegrTwoLevelWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 19933		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)

End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrTwoLevelWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_TwoLevelWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_TwoLevelWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_WhiteBeamDist_mid(dum*5.3)*TwoLevelX(cw,qq/dum)
	
	return (val)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function ThreeLevelWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("ThreeLevelX")
//	yw = ThreeLevelX(cw,xw)
	yw = V_fThreeLevelWB(cw,xw)
#else
//	yw = fThreeLevel(cw,xw)
	yw = 1
#endif
	return(0)
End

Function V_fThreeLevelWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 8.37/5.3
	
	inten = V_IntegrThreeLevelWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 19933		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrThreeLevelWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_ThreeLevelWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_ThreeLevelWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_WhiteBeamDist_mid(dum*5.3)*ThreeLevelX(cw,qq/dum)
	
	return (val)
End


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FourLevelWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FourLevelX")
//	yw = FourLevelX(cw,xw)
	yw = V_fFourLevelWB(cw,xw)
#else
//	yw = fFourLevel(cw,xw)
	yw = 1
#endif
	return(0)
End


Function V_fFourLevelWB(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable inten,lolim,uplim
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 8.37/5.3
	
	inten = V_IntegrFourLevelWB_mid(w,loLim,upLim,x)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 19933		// "middle"  of peaks

// additional normalization???
	inten /= 1.05		// 
	Return (inten)
	
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrFourLevelWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_FourLevelWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_FourLevelWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_WhiteBeamDist_mid(dum*5.3)*FourLevelX(cw,qq/dum)
	
	return (val)
End



Function SmearedOneLevelWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(OneLevelWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	

Function SmearedTwoLevelWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(TwoLevelWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	

Function SmearedThreeLevelWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(ThreeLevelWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

Function SmearedFourLevelWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FourLevelWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOneLevelWB(coefW,yW,xW)
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
	err = SmearedOneLevelWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedTwoLevelWB(coefW,yW,xW)
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
	err = SmearedTwoLevelWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedThreeLevelWB(coefW,yW,xW)
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
	err = SmearedThreeLevelWB(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFourLevelWB(coefW,yW,xW)
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
	err = SmearedFourLevelWB(fs)
	
	return (0)
End

