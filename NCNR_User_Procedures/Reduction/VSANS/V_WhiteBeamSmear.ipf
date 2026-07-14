#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
//
// testing routines to compare various integration methods and approximations
// for calculating the resolution smearing from the white beam wavelength distribution
//
// none of these functions are used in the final version of the resolution smearing
// for white beam or super white beam. Functions and definitions of WB and SWB are contained
// in the file: V_WhiteBeamDistribution.ipf
//
//
//
//
//
// IntegrateFn_N is something that I wrote (in GaussUtils) for quadrature with any number of
//  points (user-selected)
//
// 2018:
// my quadrature and the built-in function are equivalent. Romberg may be useful in some cases
// especially for multiple integrals. then number of points and timing can be optimized. But either
// method can be used.
//
//		answer = IntegrateFn_N(V_WB_testKernel,loLim,upLim,cw,qVals,nord)
// 	answer_Rom_WB = Integrate_BuiltIn(cw,loLim,upLim,qVals)

// using a matrix multiplication for this calculation of the white beam wavelength smearing is NOT
// recommended -- the calculation is not nearly accurate enough.
//
//
// Using my built-in quadrature routines (see V_TestWavelengthIntegral) may be of use when
// writing fitting functions for all of these cases. The built-in Integrate may be limited
//
// NOTE: -- beware what might happen to the calculations since there is a single global string
//   containing the function name.
//
// NOTE:
// -- a significant problem with using the coef waves that are used in the wrapper are that
//   they are set up with a dependency, so doing the WB calculation also does the "regular"
//   smeared calculation, doubling the time required...

//
// needs V_DummyFunctions for the FUNCREF to work - since it fails if I simply call the XOP
//
//
// SANSModel_proto(w,x)		is in GaussUtils_v40.ipf
//
// FUNCREF SANSModel_proto fcn
//

// call the calculation
// see DoTheFitButton in Wrapper_v40.ipf
//
//
Proc V_Calc_WB_Smearing_top()

	string folderStr, funcStr, coefStr

	ControlInfo/W=WrapperPanel popup_0
	folderStr = S_Value

	ControlInfo/W=WrapperPanel popup_1
	funcStr = S_Value

	ControlInfo/W=WrapperPanel popup_2
	coefStr = S_Value

	V_DoWavelengthIntegral_top(folderStr, funcStr, coefStr)

	SetDataFolder root:
EndMacro

Proc V_Calc_WB_Smearing_mid()

	string folderStr, funcStr, coefStr

	ControlInfo/W=WrapperPanel popup_0
	folderStr = S_Value

	ControlInfo/W=WrapperPanel popup_1
	funcStr = S_Value

	ControlInfo/W=WrapperPanel popup_2
	coefStr = S_Value

	V_DoWavelengthIntegral_mid(folderStr, funcStr, coefStr)

	SetDataFolder root:
EndMacro

Proc V_Calc_WB_Smearing_interp()

	string folderStr, funcStr, coefStr

	ControlInfo/W=WrapperPanel popup_0
	folderStr = S_Value

	ControlInfo/W=WrapperPanel popup_1
	funcStr = S_Value

	ControlInfo/W=WrapperPanel popup_2
	coefStr = S_Value

	V_DoWavelengthIntegral_interp(folderStr, funcStr, coefStr)

	SetDataFolder root:
EndMacro

Proc V_Calc_WB_Smearing_triang()

	string folderStr, funcStr, coefStr

	ControlInfo/W=WrapperPanel popup_0
	folderStr = S_Value

	ControlInfo/W=WrapperPanel popup_1
	funcStr = S_Value

	ControlInfo/W=WrapperPanel popup_2
	coefStr = S_Value

	V_DoWavelengthIntegral_triang(folderStr, funcStr, coefStr)

	SetDataFolder root:
EndMacro

// uses built-in Integrate1d()
//
Function V_DoWavelengthIntegral_top(string folderStr, string funcStr, string coefStr)

	SetDataFolder $("root:" + folderStr)

	// gather the input waves
	WAVE qVals = $(folderStr + "_q")
	//	WAVE cw = smear_coef_BroadPeak
	WAVE cw = $coefStr

	funcStr = V_getXFuncStrFromCoef(cw) + "_" //get the modelX name, tag on "_"
	string/G root:gFunctionString = funcStr // need a global reference to pass to Integrate1D

	// make a wave for the answer
	Duplicate/O qvals, answer_Rom_WB_top

	// do the integration
	variable loLim, upLim

	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "top" of the peaks
	loLim = 3.37 / 5.3
	upLim = 8.25 / 5.3

	//	// using the "middle"
	//	loLim = 3.37/5.3
	//	upLim = 8.37/5.3
	//
	//	// using the interpolated distribution (must change the function call)
	//	lolim = 3/5.3
	//	uplim = 9/5.3

	// using the "triangular" distribution (must change the function call)
	//	loLim = 4/5.3
	//	upLim = 8/5.3

	answer_Rom_WB_top = V_Integrate_BuiltIn_top(cw, loLim, upLim, qVals)

	// why do I need this? Is this because this is defined as the mean of the distribution
	//  and is needed to normalize the integral? verify this on paper.
	answer_Rom_WB_top *= 5.3

	// normalize the integral
	answer_Rom_WB_top /= 20926 // "top"  of peaks
	//	answer_Rom_WB /= 19933		// "middle"  of peaks
	//	answer_Rom_WB /= 20051		// interpolated distribution
	//	answer_Rom_WB /= 1		// triangular distribution (it's already normalized)

	// additional normalization???
	answer_Rom_WB_top /= 1.05 //

	SetDataFolder root:

	return 0
End

// uses built-in Integrate1d()
//
Function V_DoWavelengthIntegral_mid(string folderStr, string funcStr, string coefStr)

	SetDataFolder $("root:" + folderStr)

	// gather the input waves
	WAVE qVals = $(folderStr + "_q")
	//	WAVE cw = smear_coef_BroadPeak
	WAVE cw = $coefStr

	funcStr = V_getXFuncStrFromCoef(cw) + "_" //get the modelX name, tag on "_"
	string/G root:gFunctionString = funcStr // need a global reference to pass to Integrate1D

	// make a wave for the answer
	Duplicate/O qvals, answer_Rom_WB_mid

	// do the integration
	variable loLim, upLim

	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "top" of the peaks
	//	loLim = 3.37/5.3
	//	upLim = 8.25/5.3

	//	// using the "middle"
	loLim = 3.37 / 5.3
	upLim = 8.37 / 5.3
	//
	//	// using the interpolated distribution (must change the function call)
	//	lolim = 3/5.3
	//	uplim = 9/5.3

	// using the "triangular" distribution (must change the function call)
	//	loLim = 4/5.3
	//	upLim = 8/5.3

	answer_Rom_WB_mid = V_Integrate_BuiltIn_mid(cw, loLim, upLim, qVals)

	// why do I need this? Is this because this is defined as the mean of the distribution
	//  and is needed to normalize the integral? verify this on paper.
	answer_Rom_WB_mid *= 5.3

	// normalize the integral
	//	answer_Rom_WB /= 20926		// "top"  of peaks
	answer_Rom_WB_mid /= 19933 // "middle"  of peaks
	//	answer_Rom_WB /= 20051		// interpolated distribution
	//	answer_Rom_WB /= 1		// triangular distribution (it's already normalized)

	// additional normalization???
	answer_Rom_WB_mid /= 1.05 // "middle"  of peaks

	SetDataFolder root:

	return 0
End

// uses built-in Integrate1d()
//
Function V_DoWavelengthIntegral_interp(string folderStr, string funcStr, string coefStr)

	SetDataFolder $("root:" + folderStr)

	// gather the input waves
	WAVE qVals = $(folderStr + "_q")
	//	WAVE cw = smear_coef_BroadPeak
	WAVE cw = $coefStr

	funcStr = V_getXFuncStrFromCoef(cw) + "_" //get the modelX name, tag on "_"
	string/G root:gFunctionString = funcStr // need a global reference to pass to Integrate1D

	// make a wave for the answer
	Duplicate/O qvals, answer_Rom_WB_interp

	// do the integration
	variable loLim, upLim

	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "top" of the peaks
	//	loLim = 3.37/5.3
	//	upLim = 8.25/5.3

	//	// using the "middle"
	//	loLim = 3.37/5.3
	//	upLim = 8.37/5.3
	//
	//	// using the interpolated distribution (must change the function call)
	lolim = 3 / 5.3
	uplim = 9 / 5.3

	// using the "triangular" distribution (must change the function call)
	//	loLim = 4/5.3
	//	upLim = 8/5.3

	answer_Rom_WB_interp = V_Integrate_BuiltIn_interp(cw, loLim, upLim, qVals)

	// why do I need this? Is this because this is defined as the mean of the distribution
	//  and is needed to normalize the integral? verify this on paper.
	answer_Rom_WB_interp *= 5.3

	// normalize the integral
	//	answer_Rom_WB /= 20926		// "top"  of peaks
	//	answer_Rom_WB /= 19933		// "middle"  of peaks
	answer_Rom_WB_interp /= 20051 // interpolated distribution
	//	answer_Rom_WB /= 1		// triangular distribution (it's already normalized)

	// additional normalization???
	answer_Rom_WB_interp /= 1.05 // "middle"  of peaks

	SetDataFolder root:

	return 0
End

// uses built-in Integrate1d()
//
Function V_DoWavelengthIntegral_triang(string folderStr, string funcStr, string coefStr)

	SetDataFolder $("root:" + folderStr)

	// gather the input waves
	WAVE qVals = $(folderStr + "_q")
	//	WAVE cw = smear_coef_BroadPeak
	WAVE cw = $coefStr

	funcStr = V_getXFuncStrFromCoef(cw) + "_" //get the modelX name, tag on "_"
	string/G root:gFunctionString = funcStr // need a global reference to pass to Integrate1D

	// make a wave for the answer
	Duplicate/O qvals, answer_Rom_WB_triang

	// do the integration
	variable loLim, upLim

	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "top" of the peaks
	//	loLim = 3.37/5.3
	//	upLim = 8.25/5.3

	//	// using the "middle"
	//	loLim = 3.37/5.3
	//	upLim = 8.37/5.3
	//
	//	// using the interpolated distribution (must change the function call)
	//	lolim = 3/5.3
	//	uplim = 9/5.3

	// using the "triangular" distribution (must change the function call)
	loLim = 4 / 5.3
	upLim = 8 / 5.3

	answer_Rom_WB_triang = V_Integrate_BuiltIn_triangle(cw, loLim, upLim, qVals)

	// why do I need this? Is this because this is defined as the mean of the distribution
	//  and is needed to normalize the integral? verify this on paper.
	answer_Rom_WB_triang *= 5.3

	// normalize the integral
	//	answer_Rom_WB /= 20926		// "top"  of peaks
	//	answer_Rom_WB /= 19933		// "middle"  of peaks
	//	answer_Rom_WB /= 20051		// interpolated distribution
	answer_Rom_WB_triang /= 1 // triangular distribution (it's already normalized)

	// additional normalization???
	answer_Rom_WB_triang /= 1.1 //

	SetDataFolder root:

	return 0
End

//
// not used anymore - the built-in works fine, but this
// may be of use if I convert all of these to fitting functions.
//
Function V_TestWavelengthIntegral(string folderStr)

	SetDataFolder $("root:" + folderStr)

	// gather the input waves
	WAVE qVals = $(folderStr + "_q")
	//	WAVE cw = smear_coef_sf
	//	WAVE cw = smear_coef_pgs
	WAVE cw = smear_coef_BroadPeak

	// make a wave for the answer
	//	Duplicate/O qvals answer, answer_builtIn
	Duplicate/O qvals, answer_Quad

	// do the integration
	// Function IntegrateFn_N(fcn,loLim,upLim,w,x,nord)

	variable loLim, upLim, nord

	nord = 76 // 20 quadrature points not enough for white beam (especially AgBeh test)

	loLim = 4 / 5.3
	upLim = 8 / 5.3

	// 2018:
	// my quadrature and the built-in function are equivalent. Romberg may be useful in some cases
	// especially for multiple integrals. then number of points and timing can be optimized. But either
	// method can be used.
	answer_Quad = IntegrateFn_N(V_WB_testKernel, loLim, upLim, cw, qVals, nord)

	// why do I need this? Is this because this is defined as the mean of the distribution
	//  and is needed to normalize the integral? verify this on paper.
	answer_Quad *= 5.3
	//	answer_builtIn *= 5.3

	SetDataFolder root:

	return 0
End

// x = the q-value for the calculation
// dum = the dummy integration variable
Function V_WB_testKernel(WAVE cw, variable x, variable dum)

	variable val
	SVAR                    funcStr = root:gFunctionString
	FUNCREF SANSModel_proto func    = $funcStr

	//	val = (1-dum*5.3/8)*BroadPeakX(cw,x/dum)
	val = (1 - dum * 5.3 / 8) * func(cw, x / dum)

	//	val = V_WhiteBeamDist(dum*5.3)*BroadPeakX(cw,x/dum)
	//	val = V_WhiteBeamDist(dum*5.3)*func(cw,x/dum)

	return (val)
End

Proc WBDistr()

	make/O/D distr
	SetScale/I x, 0.755, 1.509, "", distr
	distr = (1 - x * 5.3 / 8)
	display distr

EndMacro

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_Integrate_BuiltIn_top(WAVE cw, variable loLim, variable upLim, variable qVal)

	variable/G root:qq = qval
	variable ans

	//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_intgrnd_top, lolim, uplim, 1, 0, cw) // Romberg integration

	return ans
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_Integrate_BuiltIn_mid(WAVE cw, variable loLim, variable upLim, variable qVal)

	variable/G root:qq = qval
	variable ans

	//	ans = Integrate1D(V_intgrnd_mid,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_intgrnd_mid, lolim, uplim, 1, 0, cw) // Romberg integration

	return ans
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_Integrate_BuiltIn_triangle(WAVE cw, variable loLim, variable upLim, variable qVal)

	variable/G root:qq = qval
	variable ans

	//	ans = Integrate1D(V_intgrnd_triangle,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_intgrnd_triangle, lolim, uplim, 1, 0, cw) // Romberg integration

	return ans
End

// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_Integrate_BuiltIn_interp(WAVE cw, variable loLim, variable upLim, variable qVal)

	variable/G root:qq = qval
	variable ans

	//	ans = Integrate1D(V_intgrnd_interp,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_intgrnd_interp, lolim, uplim, 1, 0, cw) // Romberg integration

	return ans
End

//
// See V_DummyFunctions.ipf for the full list
//
//Function BroadPeakX_(cw,x)
//	Wave cw
//	Variable x
//
//	return(BroadPeakX(cw,x))
//end

Function V_intgrnd_top(WAVE cw, variable dum)

	variable val
	NVAR                    qq      = root:qq //the q-value of the integration, not part of cw, so pass global
	SVAR                    funcStr = root:gFunctionString
	FUNCREF SANSModel_proto func    = $funcStr

	//	val = (1-dum*5.3/8)*BroadPeakX(cw,qq/dum)
	//	val = (1-dum*5.3/8)*func(cw,qq/dum)

	//	val = V_WhiteBeamDist(dum*5.3)*BroadPeakX(cw,qq/dum)
	val = V_WhiteBeamDist_top(dum * 5.3) * func(cw, qq / dum)

	//	val = V_WhiteBeamInterp(dum*5.3)*func(cw,qq/dum)

	return (val)
End

// dum = the dummy of the integration
Function V_intgrnd_mid(WAVE cw, variable dum)

	variable val
	NVAR                    qq      = root:qq //the q-value of the integration, not part of cw, so pass global
	SVAR                    funcStr = root:gFunctionString
	FUNCREF SANSModel_proto func    = $funcStr

	//	val = (1-dum*5.3/8)*BroadPeakX(cw,qq/dum)
	//	val = (1-dum*5.3/8)*func(cw,qq/dum)

	//	val = V_WhiteBeamDist(dum*5.3)*BroadPeakX(cw,qq/dum)
	val = V_WhiteBeamDist_mid(dum * 5.3) * func(cw, qq / dum)

	//	val = V_WhiteBeamInterp(dum*5.3)*func(cw,qq/dum)

	return (val)
End

// dum = the dummy of the integration
Function V_intgrnd_triangle(WAVE cw, variable dum)

	variable val
	NVAR                    qq      = root:qq //the q-value of the integration, not part of cw, so pass global
	SVAR                    funcStr = root:gFunctionString
	FUNCREF SANSModel_proto func    = $funcStr

	//	val = (1-dum*5.3/8)*BroadPeakX(cw,qq/dum)
	val = (1 - dum * 5.3 / 8) * func(cw, qq / dum)

	//	val = V_WhiteBeamDist(dum*5.3)*BroadPeakX(cw,qq/dum)
	//	val = V_WhiteBeamDist(dum*5.3)*func(cw,qq/dum)

	//	val = V_WhiteBeamInterp(dum*5.3)*func(cw,qq/dum)

	return (val)
End

// dum = the dummy of the integration
Function V_intgrnd_interp(WAVE cw, variable dum)

	variable val
	NVAR                    qq      = root:qq //the q-value of the integration, not part of cw, so pass global
	SVAR                    funcStr = root:gFunctionString
	FUNCREF SANSModel_proto func    = $funcStr

	//	val = (1-dum*5.3/8)*BroadPeakX(cw,qq/dum)
	//	val = (1-dum*5.3/8)*func(cw,qq/dum)

	//	val = V_WhiteBeamDist(dum*5.3)*BroadPeakX(cw,qq/dum)
	//	val = V_WhiteBeamDist(dum*5.3)*func(cw,qq/dum)

	val = V_WhiteBeamInterp(dum * 5.3) * func(cw, qq / dum)

	return (val)
End

////////////////////////////

// need a function to return the model function name
// given the coefficient wave
//
// want the function NameX for use in the integration, not the AAO function
//

// from the name of the coefficient wave, get the function name
// be sure that there is no "Smeared" at the beginning of the name
// tag X to the end of the name string
//
// then the funcString must be passed in as a global to the built-in integration function.
//
Function/S V_getXFuncStrFromCoef(WAVE cw)

	string cwStr  = NameOfWave(cw)
	string outStr = ""
	string extStr = ""

	//	String convStr = ReplaceString("_",cwStr,".")		// change the _ to .
	//	extStr = ParseFilePath(4, convStr, ":", 0, 0)		// extracts the last .nnn, without the .

	// go through the list of coefKWStr pairs
	// look for the cwStr
	// take up to the = (that is the funcStr)
	// remove "Smeared" if needed
	SVAR coefList = root:Packages:NIST:coefKWStr

	variable ii, num
	string item

	num = ItemsInList(coefList, ";")
	ii  = 0
	do
		item = StringFromList(ii, coefList, ";")

		if(strsearch(item, cwStr, 0) != -1) //match
			item   = ReplaceString("=", item, ".")        //replace the = with .
			outStr = ParseFilePath(3, item, ":", 0, 0)    // extract file name without extension
			outStr = ReplaceString("Smeared", outStr, "") // replace "Smeared" with null, if it's there
			ii     = num + 1
		endif

		ii += 1
	while(ii < num)

	return (outStr + "X")
End

//////////////////////////////////////////
// generates dummy functions of the form:
//
//Function BroadPeakX_(cw,x)
//	Wave cw
//	Variable x
//	return(BroadPeakX(cw,x))
//End
//
// so that I can use the FUNCREF
// which fails for some reason when I just use the XOP name?
//
//
// not everything ending in X is a model function - trimmed list is in V_DummyFunctions.ipf
//
Function V_generateDummyFuncs()

	string list = FunctionList("*X", ";", "KIND:4")
	variable ii, num
	string item, str

	num = ItemsInList(list, ";")

	NewNotebook/N=Notebook1/F=0

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		str  = "\r"
		str  = "Function " + item + "_(cw,x)\r"
		str += "\tWave cw\r"
		str += "\tVariable x\r"
		str += "\treturn(" + item + "(cw,x))\r"
		str += "End\r\r"

		//print str

		Notebook $"", text=str

	endfor
	return (0)

End
