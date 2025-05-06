#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=6.1
#pragma IgorVersion=7.00

// technically, I'm passing a coefficient wave that's TOO LONG to the XOP
// BEWARE: see
//ThreadSafe Function I_BroadPeak_Pix2D(w,x,y)

// ALSO -- the pixels are not square in general, so this will add more complications...
//	qval = sqrt((x-xCtr)^2+(y-yCtr)^2)			// use if the pixels are square
//	qval = sqrt((x-xCtr)^2+(y-yCtr)^2/4)			// use for LR panels where the y pixels are half the size of x
//	qval = sqrt((x-xCtr)^2/4+(y-yCtr)^2)			// use for TB panels where the y pixels are twice the size of x

//
//
// WaveStats/Q data_FL
// coef_peakPix2d[2] = V_max
// coef_peakPix2d[0] = 1
// then set the xy center to something somewhat close (could do this based on FL, etc.)
// then set the peak position somewhat close (how to do this??)
//
// FuncFitMD/H="11000111100"/NTHR=0 BroadPeak_Pix2D coef_PeakPix2D  data_FT /D
//

//
// the calculation is done as for the QxQy data set:
// three waves XYZ, then converted to a matrix
//
Proc V_PlotBroadPeak_Pix2D(xDim, yDim)
	variable xDim = 48
	variable yDim = 128
	Prompt xDim, "Enter X dimension: "
	Prompt yDim, "Enter Y dimension: "

	Make/O/D coef_PeakPix2D = {0, 3, 100, 0.5, 25, 2, 10, 8, 8, -10, 64}
	//	Make/O/D tmp_Pix2D = 	{10, 3, 10, 0.3, 10, 2, 0.1}		//without the pixel ctrs
	make/O/T parameters_PeakPix2D = {"Porod Scale", "Porod Exponent", "Lorentzian Scale", "Lor Screening Length", "Peak position", "Lorentzian Exponent", "Bgd [1/cm]", "xPix size (mm)", "yPix size (mm)", "xCtr (pixels)", "yCtr (pixels)"}
	Edit parameters_PeakPix2D, coef_PeakPix2D

	// generate the triplet representation
	Make/O/D/N=(xDim * yDim) xwave_PeakPix2D, ywave_PeakPix2D, zwave_PeakPix2D
	V_FillPixTriplet(xwave_PeakPix2D, ywave_PeakPix2D, zwave_PeakPix2D, xDim, yDim)

	variable/G g_PeakPix2D = 0
	g_PeakPix2D :=V_BroadPeak_Pix2D(coef_PeakPix2D, zwave_PeakPix2D, xwave_PeakPix2D, ywave_PeakPix2D) //AAO 2D calculation

	Display ywave_PeakPix2D vs xwave_PeakPix2D
	modifygraph log=0
	ModifyGraph mode=3, marker=16, zColor(ywave_PeakPix2D)={zwave_PeakPix2D, *, *, YellowHot, 0}
	ModifyGraph standoff=0
	ModifyGraph width={Plan, 1, bottom, left}
	ModifyGraph lowTrip=0.001
	Label bottom, "X pixels"
	Label left, "Y pixels"
	AutoPositionWindow/M=1/R=$(WinName(0, 1)) $WinName(0, 2)

	// generate the matrix representation
	Make/O/D/N=(xDim, yDim) PeakPix2D_mat // use the point scaling of the matrix (=pixels)
	Duplicate/O $"PeakPix2D_mat", $"PeakPix2D_lin" //keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	// and since coef_PeakPix2D is part of the parameter list (but not used) it will trigger a re-sync of the matrix
	// every time the coefficients are changed
	variable/G g_PeakPix2Dmat = 0
	g_PeakPix2Dmat :=V_UpdatePix2Mat(coef_PeakPix2D, xwave_PeakPix2D, ywave_PeakPix2D, zwave_PeakPix2D, PeakPix2D_lin, PeakPix2D_mat)

	SetDataFolder root:
	//	AddModelToStrings("BroadPeak_Pix2D","coef_PeakPix2D","parameters_PeakPix2D","PeakPix2D")
EndMacro

//
// this sets the x and y waves of the triplet to be the pixel numbers
//
//
// -- this will need to be changed if I want to fit based on real-space mm
//
Function V_FillPixTriplet(WAVE xwave_PeakPix2D, WAVE ywave_PeakPix2D, WAVE zwave_PeakPix2D, variable xDim, variable yDim)

	variable ii, jj
	ii = 0
	jj = 0
	do
		do
			xwave_PeakPix2D[ii * yDim + jj] = ii
			ywave_PeakPix2D[ii * yDim + jj] = jj
			jj                             += 1
		while(jj < yDim)
		jj  = 0
		ii += 1
	while(ii < xDim)
	return (0)
End

// the coefficient wave is only part of the parameter list to trigger this function when coefficients are changed
Function V_UpdatePix2Mat(WAVE coefW, WAVE Qx, WAVE Qy, WAVE inten, WAVE linMat, WAVE mat)

	variable xrows = DimSize(mat, 0)
	variable yrows = DimSize(mat, 1)

	string folderStr   = GetWavesDataFolder(Qx, 1)
	NVAR/Z gIsLogScale = $(folderStr + "gIsLogScale")

	//	linMat = inten[q*xrows+p]
	linMat = inten[p * yrows + q]

	if(gIsLogScale)
		mat = log(linMat)
	else
		mat = linMat
	endif

	return (0)
End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// nthreads is 1 or an even number, typically 2
// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
//
Function V_BroadPeak_Pix2D(WAVE cw, WAVE zw, WAVE xw, WAVE yw) : FitFunc

#if exists("BroadPeak_Pix2DX") //to hide the function if XOP not installed
	MultiThread zw = BroadPeak_Pix2DX(cw, xw, yw)
#else
	MultiThread zw = V_I_BroadPeak_Pix2D(cw, xw, yw)
#endif

	return (0)
End

//threaded version of the function
threadsafe Function V_BroadPeak_Pix2D_T(WAVE cw, WAVE zw, WAVE xw, WAVE yw, variable p1, variable p2)

#if exists("BroadPeak_Pix2DX") //to hide the function if XOP not installed
	zw[p1, p2] = BroadPeak_Pix2DX(cw, xw, yw)
#else
	zw[p1, p2] = V_I_BroadPeak_Pix2D(cw, xw, yw)
#endif

	return 0
End

//// technically, I'm passing a coefficient wave that's TOO LONG to the XOP
//// BEWARE
//ThreadSafe Function I_BroadPeak_Pix2D(w,x,y)
//	Wave w
//	Variable x,y
//
//	Variable retVal,qval
////	WAVE tmp = root:tmp_Pix2D
////	tmp = w[p]
//
//	Variable xCtr,yCtr
//	xCtr = w[7]
//	yCtr = w[8]
//
////	qval = sqrt((x-xCtr)^2+(y-yCtr)^2)			// use if the pixels are square
//	qval = sqrt((x-xCtr)^2+(y-yCtr)^2/4)			// use for LR panels where the y pixels are half the size of x
////	qval = sqrt((x-xCtr)^2/4+(y-yCtr)^2)			// use for TB panels where the y pixels are twice the size of x
//
//	if(qval< 0.001)
//		retval = w[6]			//bgd
//	else
//		retval = BroadPeakX(w,qval)		//pass only what BroadPeak needs
////		retval = BroadPeakX(tmp,qval)		//pass only what BroadPeak needs
//	endif
//
//	return(retVal)
//End

//
// This is not an XOP, but is correct in what it is passing and speed seems to be just fine.
//
threadsafe Function V_I_BroadPeak_Pix2D(WAVE w, variable xw, variable yw)

	//ThreadSafe Function fBroadPeak_Pix2D(w,xw,yw)

	// variables are:
	//[0] Porod term scaling
	//[1] Porod exponent
	//[2] Lorentzian term scaling
	//[3] Lorentzian screening length [A]
	//[4] peak location [1/A]
	//[5] Lorentzian exponent
	//[6] background

	//[7] xSize
	//[8] ySize

	//[9] xCtr
	//[10] yCtr

	variable aa, nn, cc, LL, Qzero, mm, bgd, xctr, yctr, xSize, ySize
	aa    = w[0]
	nn    = w[1]
	cc    = w[2]
	LL    = w[3]
	Qzero = w[4]
	mm    = w[5]
	bgd   = w[6]
	xSize = w[7]
	ySize = w[8]
	xCtr  = w[9]
	yCtr  = w[10]

	//	local variables
	variable inten, qval, ratio

	//	x is the q-value for the calculation
	//	qval = sqrt(xw^2+yw^2)

	// ASSUMPTION
	//
	// base the scaling on the xSize

	// *** NOTE ***
	// "qval" here is NOT q
	// qval is a real space distance in the units of PIXELS. Not mm, not q, PIXELS
	// Don't put any meaning in the fitted values, it's simply a functional shape

	ratio = (xSize / ySize)^2
	if(ratio > 1)
		//	qval = sqrt((xw-xCtr)^2+(yw-yCtr)^2)			// use if the pixels are square
		qval = sqrt((xw - xCtr)^2 + ((yw - yCtr)^2) / ratio) // use for LR panels where the y pixels are half the size of x
	else
		qval = sqrt(((xw - xCtr)^2) * ratio + (yw - yCtr)^2) // use for TB panels where the y pixels are twice the size of x
	endif

	if(qval < .001)
		return (bgd)
	endif

	//	do the calculation and return the function value

	inten = aa / (qval)^nn + cc / (1 + (abs(qval - Qzero) * LL)^mm) + bgd

	return (inten)

End

//non-threaded version of the function, necessary for the smearing calculation
// -- the smearing calculation can only calculate (nord) points at a time.
//
threadsafe Function V_BroadPeak_Pix2D_noThread(WAVE cw, WAVE zw, WAVE xw, WAVE yw)

#if exists("BroadPeak_Pix2DX") //to hide the function if XOP not installed
	zw = BroadPeak_Pix2DX(cw, xw, yw)
#else
	zw = V_I_BroadPeak_Pix2D(cw, xw, yw)
#endif

	return 0
End

