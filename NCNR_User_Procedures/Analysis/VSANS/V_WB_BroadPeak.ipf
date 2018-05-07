#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


////////////////////////////////////////////////////
//
// an empirical model containing power law scattering + a broad peak
//
// B. Hammouda OCT 2008
//
//
// updated for use with latest macros SRK Nov 2008
//
// Updated 2018 to White Beam Smearing
//
//
////////////////////////////////////////////////////

//
Proc PlotBroadPeakWB(num,qmin,qmax)
	Variable num=200, qmin=0.001, qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: " 
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
//
	Make/O/D/n=(num) xwave_BroadPeakWB, ywave_BroadPeakWB
	xwave_BroadPeakWB =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_BroadPeakWB = {1e-5, 3, 10, 50.0, 0.1,2,0.1}		
	make/o/t parameters_BroadPeakWB = {"Porod Scale", "Porod Exponent","Lorentzian Scale","Lor Screening Length [A]","Qzero [1/A]","Lorentzian Exponent","Bgd [1/cm]"}	//CH#2
	Edit parameters_BroadPeakWB, coef_BroadPeakWB
	
	Variable/G root:g_BroadPeakWB
	g_BroadPeakWB := BroadPeakWB(coef_BroadPeakWB, ywave_BroadPeakWB, xwave_BroadPeakWB)
	Display ywave_BroadPeakWB vs xwave_BroadPeakWB
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1,grid=1,mirror=2
	Label bottom "q (Å\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("BroadPeakWB","coef_BroadPeakWB","parameters_BroadPeakWB","BroadPeakWB")
//
End


//
//no input parameters are necessary, it MUST use the experimental q-values
// from the experimental data read in from an AVE/QSIG data file
////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedBroadPeakWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_BroadPeakWB = {1e-5, 3, 10, 50.0, 0.1,2,0.1}		
	make/o/t smear_parameters_BroadPeakWB = {"Porod Scale", "Porod Exponent","Lorentzian Scale","Lor Screening Length [A]","Qzero [1/A]","Lorentzian Exponent","Bgd [1/cm]"}
	Edit smear_parameters_BroadPeakWB,smear_coef_BroadPeakWB					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_BroadPeakWB,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_BroadPeakWB
					
	Variable/G gs_BroadPeakWB=0
	gs_BroadPeakWB := fSmearedBroadPeakWB(smear_coef_BroadPeakWB,smeared_BroadPeakWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_BroadPeakWB vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedBroadPeakWB","smear_coef_BroadPeakWB","smear_parameters_BroadPeakWB","BroadPeakWB")
End


//
//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function BroadPeakWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BroadPeakX")
//	yw = BroadPeakX(cw,xw)
	yw = V_fBroadPeakWB(cw,xw)
#else
//	yw = fBroadPeakWB(cw,xw)
	yw = 1
#endif
	return(0)
End

//
// unsmeared model calculation
//
Function V_fBroadPeakWB(w,x) : FitFunc
	Wave w
	Variable x
	
	// variables are:							
	//[0] Porod term scaling
	//[1] Porod exponent
	//[2] Lorentzian term scaling
	//[3] Lorentzian screening length [A]
	//[4] peak location [1/A]
	//[5] Lorentzian exponent
	//[6] background
	
	Variable aa,nn,cc,LL,Qzero,mm,bgd,inten,lolim,uplim

	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 8.37/5.3
	
	inten = V_IntegrBroadPeakWB_mid(w,loLim,upLim,x)

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
Function V_IntegrBroadPeakWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_BroadPeakWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_BroadPeakWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_WhiteBeamDist_mid(dum*5.3)*BroadPeakX(cw,qq/dum)
	
	return (val)
End

//CH#4	
///////////////////////////////////////////////////////////////
// smeared model calculation
//
// you don't need to do anything with this function, as long as
// your BroadPeak works correctly, you get the resolution-smeared
// version for free.
//
// this is all there is to the smeared model calculation!
Function SmearedBroadPeakWB(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_76(BroadPeakWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End


///////////////////////////////////////////////////////////////


// nothing to change here
//
//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedBroadPeakWB(coefW,yW,xW)
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
	err = SmearedBroadPeakWB(fs)
	
	return (0)
End
