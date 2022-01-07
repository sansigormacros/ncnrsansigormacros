#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion = 7.00



//
// functions to apply corrections to the detector panels
//
// these are meant to be called by the procedures that convert "raw" data to 
// "adjusted" or corrected data sets
//
// 



// the function V_WindowTransmission(tw) is a testing function that can be used to 
// plot the transmission correction as a function of angle or q-value
// - it is named for the window transmission, but it is the same equation as the large
// angle sample transmission correction.
//




////////////////
// Constants for detector efficiency and shadowing
//
// V_TubeEfficiencyShadowCorr()
//
// JAN 2020
///////////////
Constant kTube_ri = 0.372		// inner radius of tube [cm]
Constant kTube_cc = 0.84			// center to center spacing [cm]
Constant kTube_ss = 0.025		// stainless steel shell thickness [cm]
// note that the total outer diameter of the tubes is 2*0.372 + 2*0.025 = 0.794 cm
// such that the 0.84 cm c-to-c spacing accounts for the gaps between tubes as mounted.


Constant kSig_2b_He = 0.146		// abs xs for 2 bar He(3) [cm-1 A-1] (multiply this by wavelength)
Constant kSig_8b_He = 0.593		// abs xs for 8 bar He(3) [cm-1 A-1] (multiply this by wavelength)
Constant kSig_Al = 0.00967		// abs xs for Al [cm-1 A-1] (multiply this by wavelength)
Constant kSig_ss = 0.146		// abs xs for 304 SS [cm-1 A-1] (multiply this by wavelength)




//
// detector dead time
// 
// input is the data array (N tubes x M pixels)
// input of N x 1 array of dead time values
//
// output is the corrected counts in data, overwriting the input data
//
// Note that the equation in Roe (eqn 2.15, p. 63) looks different, but it is really the 
// same old equation, just written in a more complex form.
//
// (DONE)
// x- verify the direction of the tubes and indexing
// x- decide on the appropriate functional form for the tubes
// x- need count time as input
// x- be sure I'm working in the right data folder (all waves are passed in)
// x- clean up when done
// x- calculate + return the error contribution?
// x- verify the error propagation
Function V_DeadTimeCorrectionTubes(dataW,data_errW,dtW,ctTime)
	Wave dataW,data_errW,dtW
	Variable ctTime
	
	// do I count on the orientation as an input, or do I just figure it out on my own?
	String orientation
	Variable dimX,dimY
	dimX = DimSize(dataW,0)
	dimY = DimSize(dataw,1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif
	
	// sum the counts in each tube and divide by time for total cr per tube
	Variable npt
	
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
		
		MatrixOp/O sumTubes = sumRows(dataW)		// n x 1 result
		sumTubes /= ctTime		//now count rate per tube
		
		dataW[][] = dataW[p][q]/(1-sumTubes[p]*dtW[p])		//correct the data
		data_errW[][] = data_errW[p][q]/(1-sumTubes[p]*dtW[p])		// propagate the error wave

	elseif(cmpstr(orientation,"horizontal")==0)
	//	this is data (horizontal) dimensioned as (Npix,Ntubes)

		MatrixOp/O sumTubes = sumCols(dataW)		// 1 x m result
		sumTubes /= ctTime
		
		dataW[][] = dataW[p][q]/(1-sumTubes[q]*dtW[q])
		data_errW[][] = data_errW[p][q]/(1-sumTubes[q]*dtW[q])
	
	else		
		DoAlert 0,"Orientation not correctly passed in DeadTimeCorrectionTubes(). No correction done."
	endif
	
	return(0)
end

// test function
Function V_testDTCor()

	String detStr = ""
	String fname = "RAW"
	Variable ctTime
	
	detStr = "FR"
	Wave w = V_getDetectorDataW(fname,detStr)
	Wave w_err = V_getDetectorDataErrW(fname,detStr)
	Wave w_dt = V_getDetector_deadtime(fname,detStr)

	ctTime = V_getCount_time(fname)
	
//	ctTime = 10
	V_DeadTimeCorrectionTubes(w,w_err,w_dt,ctTime)

End


//
// Non-linear data correction
// 
// DOES NOT modify the data, only calculates the spatial relationship
//
// input is the data array (N tubes x M pixels)
// input of N x M array of quadratic coefficients
//
// output is wave of corrected real space distance corresponding to each pixel of the data
// ** its distance from the nominal beam center of (0,0) **
//
//
// (DONE)
// x- UNITS!!!! currently this is mm, which certainly doesn't match anything else!!!
//
// x- verify the direction of the tubes and indexing
// x- be sure I'm working in the right data folder (it is passed in, and the full path is used)
// x- clean up when done
// x- calculate + return the error contribution? (there is none for this operation)
// x- do I want this to return a wave? (no, default names are generated)
// x- do I need to write a separate function that returns the distance wave for later calculations?
// x- do I want to make the distance array 3D to keep the x and y dims together? Calculate them all right now?
// x- what else do I need to pass to the function? (fname=folder? detStr?)
// y- (yes,see below) need a separate block or function to handle "B" detector which will be ? different
//
//
Function V_NonLinearCorrection(fname,dataW,coefW,tube_width,detStr,destPath)
	String fname		//can also be a folder such as "RAW"
	Wave dataW,coefW
	Variable tube_width
	String detStr,destPath
	
	 
	// do I count on the orientation as an input, or do I just figure it out on my own?
	String orientation
	Variable dimX,dimY
	dimX = DimSize(dataW,0)
	dimY = DimSize(dataW,1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif

	// make a wave of the same dimensions, in the same data folder for the distance
	// ?? or a 3D wave?
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	
	// then per tube, do the quadratic calculation to get the real space distance along the tube
	// the distance perpendicular to the tube is n*(8.4mm) per tube index
	
	// DONE
	// -- GAP was hard-wired, but in 2018 proper values for all 4 gaps were measured
	// and added to the file header for each detector panel. there is now a read from the 
	// header to get the gap value 
	Variable offset,gap

	gap = V_getDet_panel_gap(fname,detStr)

// DONE:
// -- in case of error, V_getDet_panel_gap() will return -999999
// -- it should only apply to data pre-2018 when the field did not exist in the file
// -- any VSANS data from 2018+ should read gap from the file and bypass the if()

	if(gap < -100)		//-999999 returned if field is missing from file
	
		if(cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"FR") == 0)
			gap = 3.5		//mm (measured, JB 1/4/18)
		endif
		if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
			gap = 3.3		//mm (measured, JB 2/1/18)
		endif
		if(cmpstr(detStr,"ML") == 0 || cmpstr(detStr,"MR") == 0)
			gap = 5.9		//mm (measured, JB 1/4/18)
		endif
		if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
			gap = 18.3		//mm (measured, JB 2/1/18)
		endif
	
	endif

	
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
	
		// adjust the x postion based on the beam center being nominally (0,0) in units of cm, not pixels
		if(cmpstr(fname,"VCALC")== 0 )
			offset = VCALC_getPanelTranslation(detStr)
			offset *= 10			// convert to units of mm
//			if(cmpstr("L",detStr[1]) == 0)
//				offset *= -1		//negative value for L
//			endif
		else
			//normal case
			offset = V_getDet_LateralOffset(fname,detStr)
			offset *= 10 //convert cm to mm
		endif
		
	// calculation is in mm, not cm
	// offset will be a negative value for the L panel, and positive for the R panel
		if(kBCTR_CM)
			if(cmpstr("L",detStr[1]) == 0)
//				data_realDistX[][] = offset - (dimX - p)*tube_width			// 
				data_realDistX[][] = offset - (dimX - p - 1/2)*tube_width - gap/2		// 
			else
			//	right
//				data_realDistX[][] = tube_width*(p+1) + offset + gap		//add to the Right det,
				data_realDistX[][] = tube_width*(p+1/2) + offset + gap/2		//add to the Right det
			endif
		else
			data_realDistX[][] = tube_width*(p)
		endif
		data_realDistY[][] = coefW[0][p] + coefW[1][p]*q + coefW[2][p]*q*q
	
	
	elseif(cmpstr(orientation,"horizontal")==0)
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)
		data_realDistY[][] = tube_width*q

		if(cmpstr(fname,"VCALC")== 0 )
			offset = VCALC_getPanelTranslation(detStr)
			offset *= 10			// convert to units of mm
//			if(cmpstr("B",detStr[1]) == 0)
//				offset *= -1	// negative value for Bottom det
//			endif
		else
			//normal case
			offset = V_getDet_VerticalOffset(fname,detStr)
			offset *= 10 //convert cm to mm
		endif
		
		if(kBCTR_CM)
			if(cmpstr("T",detStr[1]) == 0)
//				data_realDistY[][] = tube_width*(q+1) + offset + gap			
				data_realDistY[][] = tube_width*(q+1/2) + offset + gap/2			
			else
				// bottom
//				data_realDistY[][] = offset - (dimY - q)*tube_width	// 
				data_realDistY[][] = offset - (dimY - q - 1/2)*tube_width - gap/2	// 
			endif
		else
			data_realDistY[][] = tube_width*(q)
		endif
		data_realDistX[][] = coefW[0][q] + coefW[1][q]*p + coefW[2][q]*p*p

	else		
		DoAlert 0,"Orientation not correctly passed in NonLinearCorrection(). No correction done."
		return(0)
	endif
	
	return(0)
end



//
// Only the first elelment of the three is actually used
// - the stored values are in cm, and converted to mm
//
// cal_x[0] = 0.03175 [cm] = 0.3175 mm/pixel
//
// Since only the first element is used, the "correction" is linear.
//
Function V_NonLinearCorrection_B(folder,dataW,cal_x,cal_y,detStr,destPath)
	String folder
	Wave dataW,cal_x,cal_y
	String detStr,destPath

	if(cmpstr(detStr,"B") != 0)
		return(0)
	endif

Print "***Cal_X and Cal_Y for Back are using file values ***"

//		cal_x[0] = VCALC_getPixSizeX(detStr)*10			// pixel size in mm  VCALC_getPixSizeX(detStr) is [cm]
//		cal_x[1] = 1
//		cal_x[2] = 10000
//		cal_y[0] = VCALC_getPixSizeY(detStr)*10			// pixel size in mm  VCALC_getPixSizeX(detStr) is [cm]
//		cal_y[1] = 1
//		cal_y[2] = 10000

	
	// do I count on the orientation as an input, or do I just figure it out on my own?
	Variable dimX,dimY
	
//	Wave dataW = V_getDetectorDataW(folder,detStr)
	
	dimX = DimSize(dataW,0)
	dimY = DimSize(dataW,1)

	// make a wave of the same dimensions, in the same data folder for the distance
	// ?? or a 3D wave?
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	
//	Wave cal_x = V_getDet_cal_x(folder,detStr)
//	Wave cal_y = V_getDet_cal_y(folder,detStr)
	
	data_realDistX[][] = cal_x[0]*p*10		// cal_x and cal_y are in [cm], need mm
	data_realDistY[][] = cal_y[0]*q*10
	
	return(0)
end


//
// This function is essentially never used as the beam centers are never defined
// in terms of pixels, so this calculation is never called
//
// 
// x- VERIFY the calculations
// x- verify where this needs to be done (if the beam center is changed)
// x- then the q-calculation needs to be re-done
// x- the position along the tube length is referenced to tube[0], for no particular reason
//    It may be better to take an average? but [0] is an ASSUMPTION
// x- distance along tube is simple interpolation, or do I use the coefficients to
//    calculate the actual value
//
// x- distance in the lateral direction is based on tube width, which is a fixed parameter
//
//
Function V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
	String folder,detStr,destPath
	
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")	

	String orientation
	Variable dimX,dimY,xCtr,yCtr
	dimX = DimSize(data_realDistX,0)
	dimY = DimSize(data_realDistX,1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif
	
	xCtr = V_getDet_beam_center_x(folder,detStr)
	yCtr = V_getDet_beam_center_y(folder,detStr)	
	
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
	WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")

	Variable tube_width = V_getDet_tubeWidth(folder,detStr)		//this is also in mm

//
	strswitch(detStr)	// string switch
		case "FL":
		case "ML":
			// for Left/Right
			// for left
			x_mm[0] = data_realDistX[dimX-1][0] + (xCtr-dimX-1)*tube_width
			y_mm[0] = data_realDistY[0][yCtr]
	
			break		
		case "FR":	
		case "MR":
			// for Left/Right
			// for right
			x_mm[0] = data_realDistX[0][0] + xCtr*tube_width
			y_mm[0] = data_realDistY[0][yCtr]
			
			break
		case "FT":	
		case "MT":
			// for Top			
			x_mm[0] = data_realDistX[xCtr][0]
			y_mm[0] = data_realDistY[0][0] + yCtr*tube_width
			
			break		
		case "FB":	
		case "MB":
			// for Bottom			
			x_mm[0] = data_realDistX[xCtr][0]
			y_mm[0] = data_realDistY[0][dimY-1] + (yCtr-dimY-1)*tube_width
						
			break
		default:			// optional default expression executed
			Print "No case matched in V_Convert_FittedPix_2_cm"
			return(1)
	endswitch
		
	return(0)
end

//
//
// (DONE)
// x- VERIFY the calculations
// x- verify where this needs to be done (if the beam center is changed)
// x- then the q-calculation needs to be re-done
// x- the position along the tube length is referenced to tube[0], for no particular reason
//    It may be better to take an average? but [0] is an ASSUMPTION
// x- distance along tube is simple interpolation
//
// x- distance in the lateral direction is based on tube width, which is a fixed parameter
//
// the value in pixels is written to the local data folder, NOT to disk (it is recalculated as needed)
//
Function V_ConvertBeamCtr_to_pix(folder,detStr,destPath)
	String folder,detStr,destPath
	
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")	

	String orientation
	Variable dimX,dimY,xCtr,yCtr
	dimX = DimSize(data_realDistX,0)
	dimY = DimSize(data_realDistX,1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif
	
	xCtr = V_getDet_beam_center_x(folder,detStr)		//these are in cm
	yCtr = V_getDet_beam_center_y(folder,detStr)	
	
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_pix")
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_pix")
	WAVE x_pix = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_pix")
	WAVE y_pix = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_pix")

	Variable tube_width = V_getDet_tubeWidth(folder,detStr)

	variable edge,delta
	Variable gap 

// the gap is split equally between the panel pairs
// DONE -- replace hard-wired values with V_getDet_panel_gap(fname,detStr) once it is added to the file

	gap = V_getDet_panel_gap(folder,detStr)

// DONE:
// -- check in case of error, value should be read from header
// -- it should only apply to data pre-2018 when the field did not exist in the file
// -- any VSANS data from 2018+ should read gap from the file.

	if(gap < -100)		//-999999 returned if field is missing from file
		if(cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"FR") == 0)
			gap = 3.5		//mm (measured, JB 1/4/18)
		endif
		if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
			gap = 3.3		//mm (measured, JB 2/1/18)
		endif
		if(cmpstr(detStr,"ML") == 0 || cmpstr(detStr,"MR") == 0)
			gap = 5.9		//mm (measured, JB 1/4/18)
		endif
		if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
			gap = 18.3		//mm (measured, JB 2/1/18)
		endif
	endif

//
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)

		if(kBCTR_CM)
			if(cmpstr("L",detStr[1]) == 0)
				Make/O/D/N=(dimX) tmpTube
				tmpTube = data_RealDistX[p][0]
				FindLevel/P/Q tmpTube xCtr*10
				if(V_Flag)
					edge = data_realDistX[47][0]		//tube 47
					delta = abs(xCtr*10 - edge)
					x_pix[0] = dimX-1 + delta/tube_width
				else
					// beam center is on the panel, report the pixel value
					x_pix[0] = V_LevelX
				endif
				
			else
			// R panel
				Make/O/D/N=(dimX) tmpTube
				tmpTube = data_RealDistX[p][0]
				FindLevel/P/Q tmpTube xCtr*10
				if(V_Flag)
					//level not found
					edge = data_realDistX[0][0]
					delta = abs(xCtr*10 - edge + gap)		// how far past the edge of the panel
					x_pix[0] = -delta/tube_width		//since the left edge of the R panel is pixel 0
				else
					// beam center is on the panel, report the pixel value
					x_pix[0] = V_LevelX
				endif
				
			endif

		endif

// the y-center will be on the panel in this direction
		Make/O/D/N=(dimY) tmpTube
		tmpTube = data_RealDistY[0][p]
		FindLevel /P/Q tmpTube, yCtr*10
		
		y_pix[0] = V_levelX
		KillWaves/Z tmpTube
//		Print x_pix[0],y_pix[0]
		
	else
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)

		if(kBCTR_CM)
			if(cmpstr("T",detStr[1]) == 0)
				Make/O/D/N=(dimY) tmpTube
				tmpTube = data_RealDistY[p][0]
				FindLevel/P/Q tmpTube yCtr*10
				if(V_Flag)
					edge = data_realDistY[0][0]		//tube 0
					delta = abs(yCtr*10 - edge + gap)
					y_pix[0] =  -delta/tube_width		//since the bottom edge of the T panel is pixel 0				
				else
					y_pix[0] = V_LevelX
				endif				
				
			else
			// FM(B) panel
				Make/O/D/N=(dimY) tmpTube
				tmpTube = data_RealDistY[p][0]
				FindLevel/P/Q tmpTube yCtr*10
				if(V_Flag)
					edge = data_realDistY[0][47]		//y tube 47
					delta = abs(yCtr*10 - edge)
					y_pix[0] = dimY-1 + delta/tube_width		//since the top edge of the B panels is pixel 47		
				else
					y_pix[0] = V_LevelX
				endif

			endif
		endif

// the x-center will be on the panel in this direction		
		Make/O/D/N=(dimX) tmpTube
		tmpTube = data_RealDistX[p][0]
		FindLevel /P/Q tmpTube, xCtr*10
		
		x_pix[0] = V_levelX
		KillWaves/Z tmpTube
		
	endif
		
	return(0)
end

// converts from [cm] beam center to pixels
//
// the value in pixels is written to the local data folder, NOT to disk (it is recalculated as needed)
//
Function V_ConvertBeamCtr_to_pixB(folder,detStr,destPath)
	String folder,detStr,destPath
	
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")	

	Variable dimX,dimY,xCtr,yCtr
	dimX = DimSize(data_realDistX,0)
	dimY = DimSize(data_realDistX,1)
	
	xCtr = V_getDet_beam_center_x(folder,detStr)			//these are in cm, *10 to get mm
	yCtr = V_getDet_beam_center_y(folder,detStr)	
	
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_pix")
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_pix")
	WAVE x_pix = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_pix")
	WAVE y_pix = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_pix")


// simple wave lookup
// can't use x_pix[0] = data_RealDistX(xCtr)[0] since the data has no x-scale and (xCtr) is interpreted 
// as a point value

//
//xCtr, yCtr are in cm, *10 to get mm to compare to distance array

	Make/O/D/N=(dimX) tmpTube
	tmpTube = data_RealDistX[p][0]
	FindLevel /P/Q tmpTube, xCtr*10
	
	x_pix[0] = V_levelX
	KillWaves/Z tmpTube
	
	
	Make/O/D/N=(dimY) tmpTube
	tmpTube = data_RealDistY[0][p]
	FindLevel /P/Q tmpTube, yCtr*10
	
	y_pix[0] = V_levelX
	KillWaves/Z tmpTube
		
	print "pixel ctr B = ",x_pix[0],y_pix[0]
		
	return(0)
end

//
//
// (DONE)
// x- VERIFY the calculations
// x- verify where this needs to be done (if the beam center is changed)
// x- then the q-calculation needs to be re-done
//
// x- not much is known about the "B" detector, so this
//    all hinges on the non-linear corrections being done correctly for that detector
//
// 	Variable detCtrX, detCtrY
//	// get the pixel center of the detector (not the beam center)
//	detCtrX = trunc( DimSize(dataW,0)/2 )		//
//	detCtrY = trunc( DimSize(dataW,1)/2 )
//
//
Function V_ConvertBeamCtrPix_to_mmB(folder,detStr,destPath)
	String folder,detStr,destPath
	
	
//	DoAlert 0,"Error - Beam center is being interpreted as pixels, but needs to be in cm. V_ConvertBeamCtrPix_to_mmB()"
	
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")	
	
	Variable xCtr,yCtr
	xCtr = V_getDet_beam_center_x(folder,detStr)
	yCtr = V_getDet_beam_center_y(folder,detStr)	
	
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
	WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")

	x_mm[0] = data_realDistX[xCtr][0]
	y_mm[0] = data_realDistY[0][yCtr]
		
	return(0)
end






/////
//
// non-linear corrections to the tube pixels
// - returns the distance in mm (although this may change)
//
// c0,c1,c2,pix
// c0-c2 are the fit coefficients
// pix is the test pixel
//
// returns the distance in mm (relative to ctr pixel)
// ctr is the center pixel, as defined when fitting to quadratic was done
//
Function V_TubePixel_to_mm(c0,c1,c2,pix)
	Variable c0,c1,c2,pix
	
	Variable dist
	dist = c0 + c1*pix + c2*pix*pix
	
	return(dist)
End
//
////


//
// TESTING ONLY
Proc V_MakeFakeCalibrationWaves()
	// make these in the RAW data folder, before converting to a work folder
	// - then they will be "found" by get()
	// -- only for the tube, not the Back det
	
//	DoAlert 0, "re-do this and do a better job of filling the fake calibration data"

	DoAlert 0, "Calibration waves are read in from the data file"
	
//	V_fMakeFakeCalibrationWaves()
End



//
// TESTING ONLY
//
// orientation does not matter, there are 48 tubes in each bank
// so dimension (3,48) for everything.
//
// -- but the orientation does indicate TB vs LR, which has implications for 
//  the (fictional) dimension of the pixel along the tube axis, at least as far
// as for making the fake coefficients.
//
Function V_fMakeFakeCalibrationWaves()

	Variable ii,pixSize
	String detStr,fname="RAW",orientation
	
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
//		Wave w = V_getDetectorDataW(fname,detStr)
		Make/O/D/N=(3,48) $("root:Packages:NIST:VSANS:RAW:entry:instrument:detector_"+detStr+":spatial_calibration")
		Wave calib = $("root:Packages:NIST:VSANS:RAW:entry:instrument:detector_"+detStr+":spatial_calibration")
		// !!!! this overwrites what is there

		orientation = V_getDet_tubeOrientation(fname,detStr)
		if(cmpstr(orientation,"vertical")==0)
		//	this is vertical tube data dimensioned as (Ntubes,Npix)
			pixSize = 8.4		//V_getDet_y_pixel_size(fname,detStr)
			
		elseif(cmpstr(orientation,"horizontal")==0)
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)
			pixSize = 4			//V_getDet_x_pixel_size(fname,detStr)
			
		else		
			DoAlert 0,"Orientation not correctly passed in NonLinearCorrection(). No correction done."
		endif
		
		calib[0][] = -(128/2)*pixSize			//approx (n/2)*pixSixe
		calib[1][] = pixSize
		calib[2][] = 2e-4
		
	endfor
	
	// now fake calibration for "B"
	Wave cal_x = V_getDet_cal_x("RAW","B")
	Wave cal_y = V_getDet_cal_y("RAW","B")
	
	cal_x = .34		// mm, ignore the other 2 values
	cal_y = .34		// mm
	return(0)
End

//
// (DONE)
// x- MUST VERIFY the definition of SDD and how (if) setback is written to the data files
// x- currently I'm assuming that the SDD is the "nominal" value which is correct for the 
//    L/R panels, but is not correct for the T/B panels (must add in the setback)
//
//
//
// data_realDistX, Y must be previously generated from running NonLinearCorrection()
//
// call with:
// fname as the WORK folder, "RAW"
// detStr = detector String, "FL"
// destPath = path to destination WORK folder ("root:Packages:NIST:VSANS:"+folder)
//
Function V_Detector_CalcQVals(fname,detStr,destPath)
	String fname,detStr,destPath

	String orientation
	Variable xCtr,yCtr,lambda,sdd
	
// get all of the geometry information	
	orientation = V_getDet_tubeOrientation(fname,detStr)


	sdd = V_getDet_ActualDistance(fname,detStr)		//sdd derived, including setback [cm]

	// this is the ctr in pixels --xx-- (now it is in cm!)
//	xCtr = V_getDet_beam_center_x(fname,detStr)
//	yCtr = V_getDet_beam_center_y(fname,detStr)
	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	lambda = V_getWavelength(fname)
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")

// make the new waves
	Duplicate/O data_realDistX $(destPath + ":entry:instrument:detector_"+detStr+":qTot_"+detStr)
	Duplicate/O data_realDistX $(destPath + ":entry:instrument:detector_"+detStr+":qx_"+detStr)
	Duplicate/O data_realDistX $(destPath + ":entry:instrument:detector_"+detStr+":qy_"+detStr)
	Duplicate/O data_realDistX $(destPath + ":entry:instrument:detector_"+detStr+":qz_"+detStr)
	Wave qTot = $(destPath + ":entry:instrument:detector_"+detStr+":qTot_"+detStr)
	Wave qx = $(destPath + ":entry:instrument:detector_"+detStr+":qx_"+detStr)
	Wave qy = $(destPath + ":entry:instrument:detector_"+detStr+":qy_"+detStr)
	Wave qz = $(destPath + ":entry:instrument:detector_"+detStr+":qz_"+detStr)

// calculate all of the q-values
// sdd is passed in [cm]


// after adding in the 680x1656 back detector, load time was 7.8s, without multithreading
// with multithreading, 1.9s
//	 qTot = V_CalcQval(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
//	 	qx = V_CalcQX(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
//	 	qy = V_CalcQY(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
//	 	qz = V_CalcQZ(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)	

	MultiThread qTot = V_CalcQval(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	MultiThread 	qx = V_CalcQX(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	MultiThread 	qy = V_CalcQY(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	MultiThread 	qz = V_CalcQZ(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	
	return(0)
End


//function to calculate the overall q-value, given all of the necesary trig inputs
//
// (DONE)
// x- verify the calculation (accuracy - in all input conditions)
// x- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// x- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
//sdd is in [cm]
// distX and distY are in [mm]
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
ThreadSafe Function V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY
	
	Variable dx,dy,qval,two_theta,dist
		

	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	dist = sqrt(dx^2 + dy^2)
	
	dist /= 10  // convert mm to cm
	
	two_theta = atan(dist/sdd)

	qval = 4*Pi/lam*sin(two_theta/2)
	
	return qval
End

//calculates just the q-value in the x-direction on the detector
// (DONE)
// x- verify the calculation (accuracy - in all input conditions)
// x- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// x- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
//
// this properly accounts for qz
//
ThreadSafe Function V_CalcQX(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY

	Variable qx,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	

	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	dist /= 10  // convert mm to cm

	two_theta = atan(dist/sdd)

	qx = qval*cos(two_theta/2)*cos(phi)
	
	return qx
End

//calculates just the q-value in the y-direction on the detector
// (DONE)
// x- verify the calculation (accuracy - in all input conditions)
// x- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// x- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
//
// this properly accounts for qz
//
ThreadSafe Function V_CalcQY(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY

	Variable qy,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	

	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	dist /= 10  // convert mm to cm

	two_theta = atan(dist/sdd)

	qy = qval*cos(two_theta/2)*sin(phi)
	
	return qy
End

//calculates just the q-value in the z-direction on the detector
// (DONE)
// x- verify the calculation (accuracy - in all input conditions)
// x- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// x- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
// not actually used for any calculations, but here for completeness if anyone asks, or for 2D data export
//
// this properly accounts for qz, because it is qz
//
ThreadSafe Function V_CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY

	Variable qz,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	

	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	dist /= 10  // convert mm to cm

	two_theta = atan(dist/sdd)

	qz = qval*sin(two_theta/2)
	
	return qz
End


//
// (DONE)
// x- VERIFY calculations
// x- This is the actual solid angle per pixel, not a ratio vs. some "unit SA" 
//    Do I just correct for the different area vs. the "nominal" central area?
// x- decide how to implement - YES - directly change the data values (as was done in the past)
//    or (NOT done this way...use this as a weighting for when the data is binned to I(q). In the second method, 2D data
//    would need this to be applied before exporting)
// x- do I keep a wave note indicating that this correction has been applied to the data
//    so that it can be "un-applied"? NO
// x- do I calculate theta from geometry directly, or get it from Q (Assuming it's present?)
//    (YES just from geometry, since I need SDD and dx and dy values...)
//
//		"B" is passed, so I need to check for "B" and for panel orientation
// -if it is detector "B" (not tubes), then the normal solid angle correction applies
// -if it is a tube panel, then I need to know the orientation, to know which angles
//    and pixel dimensions to use
//
// *** UPDATED 1/2020 SRK
// -using new calculation since the lateral direction of the tubes does not affect the solid angle
// projection (see He (2015) and John's memo)
//
//
Function V_SolidAngleCorrection(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,lambda
	String orientation
	
// get all of the geometry information	
	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)

	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	lambda = V_getWavelength(fname)
	
	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w solid_angle,tmp_theta,tmp_dist,tmp_theta_i	//in the current df

//// calculate the scattering angle
//	dx = (distX - xctr)		//delta x in mm
//	dy = (distY - yctr)		//delta y in mm
	tmp_dist = sqrt((data_realDistX - xctr)^2 + (data_realDistY - yctr)^2)
	
	tmp_dist /= 10  // convert mm to cm
	// sdd is in [cm]

	tmp_theta = atan(tmp_dist/sdd)		//this is two_theta, the (total) scattering angle

	Variable ii,jj,numx,numy,dx,dy
	numx = DimSize(tmp_theta,0)
	numy = DimSize(tmp_theta,1)

	if(cmpstr(detStr,"B")==0)
		//detector B is a grid, straightforward cos^3 solid angle
		for(ii=0	;ii<numx;ii+=1)
			for(jj=0;jj<numy;jj+=1)
				
				if(ii==0)		//do a forward difference if ii==0
					dx = (data_realDistX[ii+1][jj] - data_realDistX[ii][jj])	//delta x for the pixel
				else
					dx = (data_realDistX[ii][jj] - data_realDistX[ii-1][jj])	//delta x for the pixel
				endif
				
				
				if(jj==0)
					dy = (data_realDistY[ii][jj+1] - data_realDistY[ii][jj])	//delta y for the pixel
				else
					dy = (data_realDistY[ii][jj] - data_realDistY[ii][jj-1])	//delta y for the pixel
				endif
		
				dx /= 10
				dy /= 10		// convert mm to cm (since sdd is in cm)
				solid_angle[ii][jj] = dx*dy		//this is in cm^2
			endfor
		endfor
		
		// to cover up any issues w/negative dx or dy
		solid_angle = abs(solid_angle)
		
		// solid_angle correction
		// == dx*dy*cos^3/sdd^2
		solid_angle *= (cos(tmp_theta))^3
		solid_angle /= sdd^2
		
		// Here it is! Apply the correction to the intensity (I divide -- to get the counts per solid angle!!)
		w /= solid_angle

		// correctly apply the correction to the error wave (assume a perfect value?)
	 	w_err /= solid_angle		//

	else
		//		
		//different calculation for the tubes, different calculation based on XY orientation
		//
		if(cmpstr(orientation,"vertical")==0)
			// L/R panels, tube axis is y-direction
			// this is now a different tmp_dist
			// convert everything to cm first!
			// sdd is in [cm], everything else is in [mm]
			tmp_dist = (data_realDistY/10 - yctr/10)/sqrt((data_realDistX/10 - xctr/10)^2 + sdd^2)		
			tmp_theta_i = atan(tmp_dist)		//this is theta_y
			
		else
			// horizontal orientation (T/B panels)
			// this is now a different tmp_dist
			// convert everything to cm first!
			// sdd is in [cm], everything else is in [mm]
			tmp_dist = (data_realDistX/10 - xctr/10)/sqrt((data_realDistY/10 - yctr/10)^2 + sdd^2)		
			tmp_theta_i = atan(tmp_dist)		//this is theta_x
		
		endif
		
		for(ii=0	;ii<numx;ii+=1)
			for(jj=0;jj<numy;jj+=1)
				
				if(ii==0)		//do a forward difference if ii==0
					dx = (data_realDistX[ii+1][jj] - data_realDistX[ii][jj])	//delta x for the pixel
				else
					dx = (data_realDistX[ii][jj] - data_realDistX[ii-1][jj])	//delta x for the pixel
				endif
				
				
				if(jj==0)
					dy = (data_realDistY[ii][jj+1] - data_realDistY[ii][jj])	//delta y for the pixel
				else
					dy = (data_realDistY[ii][jj] - data_realDistY[ii][jj-1])	//delta y for the pixel
				endif
		
				dx /= 10
				dy /= 10		// convert mm to cm (since sdd is in cm)
				solid_angle[ii][jj] = dx*dy		//this is in cm^2
			endfor
		endfor
		
		// to cover up any issues w/negative dx or dy
		solid_angle = abs(solid_angle)
		
		// solid_angle correction
		// == dx*dy*cos(th)^2*cos(th_i)/sdd^2		using either the theta_x or theta_y value
		solid_angle *= (cos(tmp_theta))^2*cos(tmp_theta_i)
		solid_angle /= sdd^2
		
		// Here it is! Apply the correction to the intensity (I divide -- to get the counts per solid angle!!)
		w /= solid_angle
		
		//
		// correctly apply the correction to the error wave (assume a perfect value?)
	 	w_err /= solid_angle		//
	
	endif
	

// DONE x- clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_theta_i
	
	return(0)
end

// this is the incorrect solid angle correction that does not take into 
// account the tube geometry. It is correct for the high-res detector (and the 30m Ordela)
//
// -- only for testing to prove that the cos(th)^2 *cos(th_i) is correct
//
Function V_SolidAngleCorrection_COS3(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,lambda
	String orientation
	
// get all of the geometry information	
	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)

	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	lambda = V_getWavelength(fname)
	
	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w solid_angle,tmp_theta,tmp_dist	//in the current df

//// calculate the scattering angle
//	dx = (distX - xctr)		//delta x in mm
//	dy = (distY - yctr)		//delta y in mm
	tmp_dist = sqrt((data_realDistX - xctr)^2 + (data_realDistY - yctr)^2)
	
	tmp_dist /= 10  // convert mm to cm
	// sdd is in [cm]

	tmp_theta = atan(tmp_dist/sdd)		//this is two_theta, the (total) scattering angle

	Variable ii,jj,numx,numy,dx,dy
	numx = DimSize(tmp_theta,0)
	numy = DimSize(tmp_theta,1)

	for(ii=0	;ii<numx;ii+=1)
		for(jj=0;jj<numy;jj+=1)
			
			if(ii==0)		//do a forward difference if ii==0
				dx = (data_realDistX[ii+1][jj] - data_realDistX[ii][jj])	//delta x for the pixel
			else
				dx = (data_realDistX[ii][jj] - data_realDistX[ii-1][jj])	//delta x for the pixel
			endif
			
			
			if(jj==0)
				dy = (data_realDistY[ii][jj+1] - data_realDistY[ii][jj])	//delta y for the pixel
			else
				dy = (data_realDistY[ii][jj] - data_realDistY[ii][jj-1])	//delta y for the pixel
			endif
	
			dx /= 10
			dy /= 10		// convert mm to cm (since sdd is in cm)
			solid_angle[ii][jj] = dx*dy		//this is in cm^2
		endfor
	endfor
	
	// to cover up any issues w/negative dx or dy
	solid_angle = abs(solid_angle)
	
	// solid_angle correction
	// == dx*dy*cos^3/sdd^2
	solid_angle *= (cos(tmp_theta))^3
	solid_angle /= sdd^2
	
	// Here it is! Apply the correction to the intensity (I divide -- to get the counts per solid angle!!)
	w /= solid_angle

	// correctly apply the correction to the error wave (assume a perfect value?)
 	w_err /= solid_angle		//
	

// DONE x- clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_theta_i
	
	return(0)
end



//
// Large angle transmission correction
//
// DIVIDE the intensity by this correction to get the right answer
//
//
// Apply the large angle transmssion correction as the data is converted to WORK
// so that whether the data is saved as 2D or 1D, the correction has properly been done.
//
// This is, however, a SAMPLE dependent calculation, not purely instrument geometry.
//
Function V_LargeAngleTransmissionCorr(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,trans,trans_err,uval

// get all of the geometry information	
//	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)

	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	trans = V_getSampleTransmission(fname)
	trans_err = V_getSampleTransError(fname)
	
	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w lat_corr,tmp_theta,tmp_dist,lat_err,tmp_err		//in the current df

//// calculate the scattering angle
//	dx = (distX - xctr)		//delta x in mm
//	dy = (distY - yctr)		//delta y in mm
	tmp_dist = sqrt((data_realDistX - xctr)^2 + (data_realDistY - yctr)^2)
	
	tmp_dist /= 10  // convert mm to cm
	// sdd is in [cm]

	tmp_theta = atan(tmp_dist/sdd)		//this is two_theta, the scattering angle

	Variable ii,jj,numx,numy,dx,dy,cos_th,arg,tmp
	numx = DimSize(tmp_theta,0)
	numy = DimSize(tmp_theta,1)
	
	
	//optical thickness
	uval = -ln(trans)		//use natural logarithm
	
	for(ii=0	;ii<numx;ii+=1)
		for(jj=0;jj<numy;jj+=1)
			
			cos_th = cos(tmp_theta[ii][jj])
			arg = (1-cos_th)/cos_th
			
			// a Taylor series around uval*arg=0 only needs about 4 terms for very good accuracy
			// 			correction= 1 - 0.5*uval*arg + (uval*arg)^2/6 - (uval*arg)^3/24 + (uval*arg)^4/120
			// OR
			if((uval<0.01) || (cos_th>0.99))	
				//small arg, approx correction
				lat_corr[ii][jj] = 1-0.5*uval*arg
			else
				//large arg, exact correction
				lat_corr[ii][jj] = (1-exp(-uval*arg))/(uval*arg)
			endif
			 
			// (DONE)
			// x- properly calculate and apply the 2D error propagation
			if(trans == 1)
				lat_err[ii][jj] = 0		//no correction, no error
			else
				//sigT, calculated from the Taylor expansion
				tmp = (1/trans)*(arg/2-arg^2/3*uval+arg^3/8*uval^2-arg^4/30*uval^3)
				tmp *= tmp
				tmp *= trans_err^2
				tmp = sqrt(tmp)		//sigT
				
				lat_err[ii][jj] = tmp
			endif
			 
 
		endfor
	endfor
	

	
	// Here it is! Apply the correction to the intensity (divide -- to get the proper correction)
	w /= lat_corr

	// relative errors add in quadrature to the current 2D error
	tmp_err = (w_err/lat_corr)^2 + (lat_err/lat_corr)^2*w*w/lat_corr^2
	tmp_err = sqrt(tmp_err)
	
	w_err = tmp_err	
	

	// DONE x- clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_err,lat_err
	
	return(0)
end



//
//test procedure, not called anymore
Proc V_AbsoluteScaling(type,c0,c1,c2,c3,c4,c5,I_err)
	String type
	Variable c0=1,c1=0.1,c2=0.95,c3=0.1,c4=1,c5=32.0,I_err=0.32
	Prompt type,"WORK data type",popup,"CAL;COR;SAM"
	Prompt c0, "Sample Transmission"
	Prompt c1, "Sample Thickness (cm)"
	Prompt c2, "Standard Transmission"
	Prompt c3, "Standard Thickness (cm)"
	Prompt c4, "I(0) from standard fit (normalized to 1E8 monitor cts)"
	Prompt c5, "Standard Cross-Section (cm-1)"
	Prompt I_err, "error in I(q=0) (one std dev)"

	Variable err
	//call the function to do the math
	//data from "type" will be scaled and deposited in ABS
	err = V_Absolute_Scale(type,c0,c1,c2,c3,c4,c5,I_err)
	
	if(err)
		Abort "Error in V_Absolute_Scale()"
	endif
	
	//contents are always dumped to ABS
	type = "ABS"
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current display type to "type"
	SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
	gCurDispType = Type	
	
	V_UpdateDisplayInformation(Type)
	
End

//
//
// kappa comes in as s_izero, so be sure to use 1/kappa_err
//
//convert the "type" data to absolute scale using the given standard information
//s_ is the standard
//w_ is the "work" file
//both are work files and should already be normalized to 10^8 monitor counts
Function V_Absolute_Scale(type,absStr)
	String type,absStr
	
	
	Variable w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err

	Variable defmon = 1e8,w_moncount,s1,s2,s3,s4
	Variable scale,trans_err
	Variable err,ii
	String detStr
	
	// be sure that the starting data exists
	err = V_WorkDataExists(type)
	if(err==1)
		return(err)
	endif
		
	//copy from current dir (type) to ABS
	V_CopyHDFToWorkFolder(type,"ABS")	

// TODO: -- which monitor to use? Here, I think it should already be normalized to 10^8
//	
//	w_moncount = V_getMonitorCount(type)		//monitor count in "type"
	
	w_moncount = V_getBeamMonNormData(type)
		
	if(w_moncount == 0)
		//zero monitor counts will give divide by zero ---
		DoAlert 0,"Total monitor count in data file is zero. No rescaling of data"
		Return(1)		//report error
	Endif

	w_trans = V_getSampleTransmission(type)		//sample transmission
	w_thick = V_getSampleThickness(type)		//sample thickness
	trans_err = V_getSampleTransError(type)	
	
	
	//get the parames from the list
	s_trans = NumberByKey("TSTAND", absStr, "=", ";")	//parse the list of values
	s_thick = NumberByKey("DSTAND", absStr, "=", ";")
	s_izero = NumberByKey("IZERO", absStr, "=", ";")
	s_cross = NumberByKey("XSECT", absStr, "=", ";")
	kappa_err = NumberByKey("SDEV", absStr, "=", ";")

	
	//calculate scale factor
	s1 = defmon/w_moncount		// monitor count (s1 should be 1)
	s2 = s_thick/w_thick
	s3 = s_trans/w_trans
	s4 = s_cross/s_izero
	scale = s1*s2*s3*s4

	
	// kappa comes in as s_izero, so be sure to use 1/kappa_err

	// and now loop through all of the detectors
	//do the actual absolute scaling here, modifying the data in ABS
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		Wave data = V_getDetectorDataW("ABS",detStr)
		Wave data_err = V_getDetectorDataErrW("ABS",detStr)
		
		data *= scale
		data_err = sqrt(scale^2*data_err^2 + scale^2*data^2*(kappa_err^2/s_izero^2 +trans_err^2/w_trans^2))
	endfor

	// do the back detector separately, if it is set to be used
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(gIgnoreDetB == 0)
		detStr = "B"
		Wave data = V_getDetectorDataW("ABS",detStr)
		Wave data_err = V_getDetectorDataErrW("ABS",detStr)
		
		//get the parames from the list
		s_trans = NumberByKey("TSTAND_B", absStr, "=", ";")	//parse the list of values
		s_thick = NumberByKey("DSTAND_B", absStr, "=", ";")
		s_izero = NumberByKey("IZERO_B", absStr, "=", ";")
		s_cross = NumberByKey("XSECT_B", absStr, "=", ";")
		kappa_err = NumberByKey("SDEV_B", absStr, "=", ";")

		//calculate scale factor
		s1 = defmon/w_moncount		// monitor count (s1 should be 1)
		s2 = s_thick/w_thick
		s3 = s_trans/w_trans
		s4 = s_cross/s_izero
		scale = s1*s2*s3*s4
		
		data *= scale
		data_err = sqrt(scale^2*data_err^2 + scale^2*data^2*(kappa_err^2/s_izero^2 +trans_err^2/w_trans^2))
	endif
	
	//********* 15APR02
	// DO NOT correct for atenuators here - the COR step already does this, putting all of the data on equal
	// footing (zero atten) before doing the subtraction.
	
	Return (0) //no error
End


//
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
//
// match the attenuation of the RAW data to the "type" data
// so that they can be properly added
//
// are the attenuator numbers the same? if so exit
//
// if not, find the attenuator number for type
// - find both attenuation factors
//
// rescale the raw data to match the ratio of the two attenuation factors
// -- adjust the detector count (rw)
// -- the linear data
//
//
Function V_Adjust_RAW_Attenuation(type)
	String type

	DoAlert 0,"This has not yet been updated for VSANS"
	
	WAVE rw=$("root:Packages:NIST:RAW:realsread")
	WAVE linear_data=$("root:Packages:NIST:RAW:linear_data")
	WAVE data=$("root:Packages:NIST:RAW:data")
	WAVE data_err=$("root:Packages:NIST:RAW:linear_data_error")
	WAVE/T tw = $("root:Packages:NIST:RAW:textRead")
	
	WAVE dest_reals=$("root:Packages:NIST:"+type+":realsread")

	Variable dest_atten,raw_atten,tol
	Variable lambda,raw_atten_err,raw_AttenFactor,dest_attenFactor,dest_atten_err
	String fileStr

	dest_atten = dest_reals[3]
	raw_atten = rw[3]
	
	tol = 0.1		// within 0.1 atten units is OK
	if(abs(dest_atten - raw_atten) < tol )
		return(0)
	endif

	fileStr = tw[3]
	lambda = rw[26]
	// TODO access correct values
	raw_AttenFactor = 1//AttenuationFactor(fileStr,lambda,raw_atten,raw_atten_err)
	dest_AttenFactor = 1//AttenuationFactor(fileStr,lambda,dest_atten,dest_atten_err)
		
	rw[2] *= dest_AttenFactor/raw_AttenFactor
	linear_data *= dest_AttenFactor/raw_AttenFactor
	
	// to keep "data" and linear_data in sync
	data = linear_data
	
	return(0)
End

//
// testing procedure, called from a menu selection
//
Proc V_DIV_a_Workfile(type)
	String type
	Prompt type,"WORK data type",popup,"SAM;EMP;BGD;ADJ;"
	
	//macro will take whatever is in SELECTED folder and DIVide it by the current
	//contents of the DIV folder - the function will check for existence 
	//before proceeding

	Abort "This has not yet been updated for VSANS"
	
	Variable err
	err = V_DIVCorrection(type)		//returns err = 1 if data doesn't exist in specified folders
	
	if(err)
		Abort "error in V_DIVCorrection()"
	endif
	
	//contents are NOT always dumped to CAL, but are in the new type folder
	
	String newTitle = "WORK_"+type
	DoWindow/F VSANS_Data
	DoWindow/T VSANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=Type
	
	V_UpdateDisplayInformation(type)
	
End


//
// (DONE):
//   x- 	DoAlert 0,"This has not yet been updated for VSANS"
//   x- how is the error propagation handled? Done the same way as for SANS.
//      Be sure it is calculated correctly when DIV is generated
//      and is applied correctly here...
//
//function will divide the contents of "workType" folder with the contents of 
//the DIV folder + detStr
// all data is linear scale for the calculation
//
Function V_DIVCorrection(data,data_err,detStr,workType)
	Wave data,data_err
	String detStr,workType
	
	//check for existence of data in type and DIV
	// if the desired data doesn't exist, let the user know, and abort
	String destPath=""

	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(cmpstr(detStr,"B")==0 && gIgnoreDetB)
		return(0)
	endif


	if(WaveExists(data) == 0)
		Print "The data wave does not exist in V_DIVCorrection()"
		Return(1) 		//error condition
	Endif
	
	//check for DIV
	// if the DIV workfile doesn't exist, let the user know,and abort
	// !! be sure to check first, before trying to access the wave
	
//	WAVE/Z div_data = $("root:Packages:NIST:VSANS:DIV:entry:instrument:detector_"+detStr+":data")
	if(WaveExists($("root:Packages:NIST:VSANS:DIV:entry:instrument:detector_"+detStr+":data")) == 0)
		Print "The DIV wave does not exist in V_DIVCorrection()"
		Return(1)		//error condition
	Endif
	if(WaveExists($("root:Packages:NIST:VSANS:DIV:entry:instrument:detector_"+detStr+":linear_data_error")) == 0)
		Print "The DIV error wave does not exist in V_DIVCorrection()"
		Return(1)		//error condition
	Endif
	//files exist, proceed

	WAVE/Z div_data_err = V_getDetectorDataErrW("DIV",detStr)
	WAVE/Z div_data = V_getDetectorDataW("DIV",detStr)



// do the error propagation first, since data is changed by the correction
	data_err = sqrt(data_err^2/div_data^2 + div_data_err^2 * data^2/div_data^4 )

// then the correction
	data /= div_data

	
	Return(0)
End


//////////////////////////
// detector corrections to stitch the back detector into one proper image
//
//
//


//
// to register the image on the back detector panel
//
// middle portion (552 pix in Y) is held fixed
// top portion of image is shifted right and down
// bottom portion of image is shifted right and up
//
// remainder of image is filled with Zero (NaN causes problems converting to WORK)
//
// currently, data is not added together and averaged, but it could be
//
Function V_ShiftBackDetImage(w,adjW)
	Wave w,adjW

	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning

// this is necessary for some old data with the 150x150 back (dummy) panel
// the proper back detector has an x-dimension of 680 pixels. Don't do the shift
// if the dimensions are incorrect.
	if(DimSize(w,0) < 680)
		adjW=w
		return(0)
	endif
	
	adjW=0
		
	Variable topX,bottomX
	Variable topY,bottomY
	Variable totalY,ccdX,ccdY
	
//	topX = 7
//	topY = 105
	
//	bottomX = 5
//	bottomY = 35

// TODOHIGHRES
// the detector pix dimensions are hard-wired, be sure the are correct
	switch(gHighResBinning)
		case 1:
			topX = kShift_topX_bin1
			topY = kShift_topY_bin1
			bottomX = kShift_bottomX_bin1
			bottomY = kShift_bottomY_bin1
			
			totalY = 6624	// total YDim
			ccdY = 2208		// = YDim/3
			ccdX = 2720		// = xDim
			break
		case 4:
			topX = kShift_topX_bin4
			topY = kShift_topY_bin4
			bottomX = kShift_bottomX_bin4
			bottomY = kShift_bottomY_bin4
			
			totalY = 1656	// total YDim
			ccdY = 552		// = YDim/3
			ccdX = 680		// = xDim

			
			break
		default:		
			Abort "No binning case matches in V_ShiftBackDetImage"
			
	endswitch

		// middle
		adjW[][ccdY,ccdY+ccdY] = w[p][q]
	
		//top
		adjW[0+topX,ccdX-1][ccdY+ccdY,totalY-1-topY] = w[p-topX][q+topY]
		
		//bottom
		adjW[0+bottomX,ccdX-1][0+bottomY,ccdY-1] = w[p-bottomX][q-bottomY]

	
	return(0)
End


Proc pV_MedianFilterBack(folder)
	String folder="RAW"
	
	V_MedianFilterBack(folder)
end

Function V_MedianFilterBack(folder)
	String folder

	Wave w = V_getDetectorDataW(folder,"B")

	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
	switch(gHighResBinning)
		case 1:
			MatrixFilter /N=11 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)
			
			Print "*** median noise filter 11x11 applied to the back detector (1 pass) ***"
			break
		case 4:
			MatrixFilter /N=3 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)
			
			Print "*** median noise filter 3x3 applied to the back detector (1 pass) ***"
			break
		default:
			Abort "No binning case matches in V_MedianFilterBack"
	endswitch

	return(0)
End


Proc pV_SubtractReadNoiseBack(folder,ReadNoise)
	String folder="RAW"
	Variable readNoise=3160
	
	V_SubtractReadNoiseBack(folder,readNoise)
end

Function V_SubtractReadNoiseBack(folder,readNoise)
	String folder
	Variable readNoise

		Wave w = V_getDetectorDataW(folder,"B")
		w -= readNoise		// a constant value
		
//		MatrixFilter /N=3 median w
//		Print "*** median noise filter applied to the back detector***"
	
	return(0)
End


Proc pV_MedianAndReadNoiseBack(folder,ReadNoise)
	String folder="RAW"
	Variable readNoise=3160
	
	V_MedianAndReadNoiseBack(folder,readNoise)
end

Function V_MedianAndReadNoiseBack(folder,readNoise)
	String folder
	Variable readNoise

		Wave w = V_getDetectorDataW(folder,"B")
		w -= readNoise		// a constant value

		NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
		switch(gHighResBinning)
			case 1:
				MatrixFilter /N=11 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)
				
				Print "*** median noise filter 11x11 applied to the back detector (1 pass) ***"
				break
			case 4:
				MatrixFilter /N=3 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)
				
				Print "*** median noise filter 3x3 applied to the back detector (1 pass) ***"
				break
			default:
				Abort "No binning case matches in V_MedianAndReadNoiseBack"
		endswitch
		
	return(0)
End



////////////////
// Detector efficiency and shadowing
///////////////

//
// Tube efficiency + shadowing
//
//
// -- check for the existence of the proper tables (correct wavelength)
//  -- generate tables if needed (one-time calculation)
//
// interpolate the table for the correction - to avoid repeated integration
//
// store the tables in: root:Packages:NIST:VSANS:Globals:Efficiency:
//
Function V_TubeEfficiencyShadowCorr(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,lambda
	String orientation

// if the panel is "B", exit - since it is not tubes, and this should not be called
	if(cmpstr(detStr,"B")==0)
		return(1)
	endif

// get all of the geometry information	
	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)

	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	lambda = V_getWavelength(fname)
	
	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w tmp_theta_x,tmp_theta_y,tmp_dist,tmp_corr		//in the current df

//// calculate the scattering angles theta_x and theta_y

// flip the definitions of x and y for the T/B panels so that x is always lateral WRT the tubes
// and y is always along the length of the tubes

	if(cmpstr(orientation,"vertical")==0)
		// L/R panels, tube axis is y-direction
		// this is now a different tmp_dist
		// convert everything to cm first!
		// sdd is in [cm], everything else is in [mm]
		tmp_dist = (data_realDistY/10 - yctr/10)/sqrt((data_realDistX/10 - xctr/10)^2 + sdd^2)		
		tmp_theta_y = atan(tmp_dist)		//this is theta_y
		tmp_theta_x = atan( (data_realDistX/10 - xctr/10)/sdd )
		
	else
		// horizontal orientation (T/B panels)
		// this is now a different tmp_dist
		// convert everything to cm first!
		// sdd is in [cm], everything else is in [mm]
		tmp_dist = (data_realDistX/10 - xctr/10)/sqrt((data_realDistY/10 - yctr/10)^2 + sdd^2)		
		tmp_theta_y = atan(tmp_dist)		//this is theta_y, along tube direction
		tmp_theta_x = atan( (data_realDistY/10 - yctr/10)/sdd )		// this is laterally across tubes
	endif


// identify if the 2D efficiency wave has been generated for the data wavelength
//
// if so, declare
// if not, generate

	if(WaveExists($"root:Packages:NIST:VSANS:Globals:Efficiency:eff") == 0)
		// generate the proper efficiency wave, at lambda
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Efficiency
		Print "recalculating efficiency table ..."
		V_TubeShadowEfficTableOneLam(lambda)
		// declare the wave
		Wave/Z effW = root:Packages:NIST:VSANS:Globals:Efficiency:eff
	else
		Wave/Z effW = root:Packages:NIST:VSANS:Globals:Efficiency:eff
		//is the efficiency at the correct wavelength?
		string str=note(effW)
//		Print "Note = ",str
		
		if(V_CloseEnough(lambda,NumberByKey("LAMBDA", str,"="),0.1))		//absolute difference of < 0.1 A
				// yes, proceed, no need to do anything
		else
			// no, regenerate the efficiency and then proceed (wave already declared)
			Print "recalculating efficiency table ..."
			V_TubeShadowEfficTableOneLam(lambda)
		endif
	endif
	
	
	Variable ii,jj,numx,numy,xAngle,yAngle
	numx = DimSize(w,0)
	numy = DimSize(w,1)

// loop over all of the pixels of the panel and find the interpolated correction (save as a wave)
//
	for(ii=0	;ii<numx;ii+=1)
		for(jj=0;jj<numy;jj+=1)

			// from the angles, find the (x,y) point to interpolate to get the efficiency
		
			xAngle = tmp_theta_x[ii][jj]
			yAngle = tmp_theta_y[ii][jj]

			xAngle = abs(xAngle)
			yAngle = abs(yAngle)
			
//			the x and y scaling of the eff wave (2D) was set when it was generated (in radians)
// 		 simply reading the scaled xy value does not interpolate!!
//			tmp_corr[ii][jj] = effW(xAngle)(yAngle)		// NO, returns "stepped" values
			tmp_corr[ii][jj] = Interp2D(effW,xAngle,yAngle)

		endfor
	endfor
//	
//	
// apply the correction and calculate the error
//	
// Here it is! Apply the correction to the intensity (divide -- to get the proper correction)
	w /= tmp_corr
//
// relative errors add in quadrature to the current 2D error
// assume that this numerical calculation of efficiency is exact
//
//	tmp_err = (w_err/tmp_corr)^2 + (lat_err/lat_corr)^2*w*w/lat_corr^2
//	tmp_err = sqrt(tmp_err)
//	
//	w_err = tmp_err	
//	

	// (DONE)
	// - clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta_x,tmp_theta_y,tmp_dist,tmp_err,tmp_corr
	
	return(0)
end



// the actual integration of the efficiency for an individual pixel
Function V_Efficiency_Integral(pWave,in_u)
	Wave pWave
	Variable in_u
	
	Variable lambda,th_x,th_y,u_p,integrand,T_sh,max_x,d_ss,d_He
	
	lambda = pWave[0]
	th_x = pWave[1]
	th_y = pWave[2]
	
	u_p = in_u + kTube_cc * cos(th_x)
	
	// calculate shadow if th_x > 23.727 deg. th_x is input in radians
	max_x = 23.727 / 360 * 2*pi
	if(th_x < max_x)
		T_sh = 1
	else
		
		// get d_ss
		if(abs(u_p) < kTube_ri)
			d_ss = sqrt( (kTube_ri + kTube_ss)^2 - in_u^2 ) - sqrt(	kTube_ri^2 - in_u^2	)
		elseif (abs(u_p) < (kTube_ri + kTube_ss))
			d_ss = sqrt( (kTube_ri + kTube_ss)^2 - in_u^2 )
		else
			d_ss = 0
		endif
		
		// get d_He
		if(abs(u_p) < kTube_ri)
			d_He = 2 * sqrt(	kTube_ri^2 - in_u^2	)
		else
			d_He = 0
		endif
		
		//calculate T_sh		
		T_sh = exp(-2*kSig_ss*lambda*d_ss/cos(th_y)) * exp(-kSig_8b_He*lambda*d_He/cos(th_y))
		
	endif
	
	
	// calculate the integrand
	
	//note that the in_u value is used here to find d_ss and d_he (not u_p)
	// get d_ss
	if(abs(in_u) < kTube_ri)
		d_ss = sqrt( (kTube_ri + kTube_ss)^2 - in_u^2 ) - sqrt(	kTube_ri^2 - in_u^2	)
	elseif (abs(in_u) < (kTube_ri + kTube_ss))
		d_ss = sqrt( (kTube_ri + kTube_ss)^2 - in_u^2 )
	else
		d_ss = 0
	endif
	
	// get d_He
	if(abs(in_u) < kTube_ri)
		d_He = 2 * sqrt(	kTube_ri^2 - in_u^2	)
	else
		d_He = 0
	endif
	
	integrand = T_sh*exp(-kSig_ss*lambda*d_ss/cos(th_y))*( 1-exp(-kSig_8b_He*lambda*d_He/cos(th_y)) )

	return(integrand)
end

//
// Tube efficiency + shadowing
//
// function to generate the table for interpolation
//
// table is generated for a specific wavelength and normalized to eff(lam,0,0)
//
// below 24 deg (theta_x), there is no shadowing, so the table rows are all identical
//
// Only one table is stored, and the wavelength of that table is stored in the wave note
// -- detector correction checks the note, and recalculates the table if needed
// (calculation takes approx 5 seconds)
//
//
// reduced the length of the function name to avoid issues with Igor 7 (31 char max)
//
Function V_TubeShadowEfficTableOneLam(lambda)
	Variable lambda
		
// storage location for tables
	SetDataFolder root:Packages:NIST:VSANS:Globals:Efficiency

//make waves that will be filed with the scattering angles and the result of the calculation
//

//// fill arrays with the scattering angles theta_x and theta_y
// 0 < x < 50
// 0 < y < 50

// *** the definitions of x and y for the T/B panels is flipped so that x is always lateral WRT the tubes
// and y is always along the length of the tubes

	Variable ii,jj,numx,numy,dx,dy,cos_th,arg,tmp,normVal
	numx = 25
	numy = numx

	Make/O/D/N=(numx,numy) eff
	Make/O/D/N=(numx) theta_x, theta_y,eff_with_shadow,lam_cos
	
	SetScale x 0,(numx*2)/360*2*pi,"", eff
	SetScale y 0,(numy*2)/360*2*pi,"", eff

	Note/K eff		// clear the note
	Note eff "LAMBDA="+num2str(lambda)
	
//	theta_x = p*2
	theta_y = p	*2	// value range from 0->45, changes if you change numx
	
	//convert degrees to radians
//	theta_x = theta_x/360*2*pi
	theta_y = theta_y/360*2*pi

//	Make/O/D/N=12 lam_wave
//	lam_wave = {0.5,0.7,1,1.5,2,3,4,6,8,10,15,20}
	
//	Make/O/D/N=(12*numx) eff_withX_to_interp,lam_cos_theta_y
//	eff_withX_to_interp=0
//	lam_cos_theta_y=0
	
	Make/O/D/N=3 pWave
	pWave[0] = lambda
	

	for(ii=0	;ii<numx;ii+=1)

		for(jj=0;jj<numx;jj+=1)	
				
				pWave[1] = indexToScale(eff,ii,0)		//set theta x 
				pWave[2] = indexToScale(eff,jj,1)		//set theta y
	
				eff_with_shadow[jj] = Integrate1D(V_Efficiency_Integral,-kTube_ri,kTube_ri,2,0,pWave)		// adaptive Gaussian quadrature
				eff_with_shadow[jj] /= (2*kTube_ri)
				
				eff[ii][jj] = eff_with_shadow[jj]
		endfor
		
		//eff[ii][] = eff_with_shadow[q]
	endfor
	
	lam_cos = lambda/cos(theta_y)
	
	Sort lam_cos,eff_with_shadow,lam_cos	
	
//	
//////	// value for normalization at current wavelength
	pWave[0] = lambda
	pWave[1] = 0
	pWave[2] = 0
////	
	normVal = Integrate1D(V_Efficiency_Integral,-kTube_ri,kTube_ri,2,0,pWave)
	normVal /= (2*kTube_ri)
//	
//	print normVal
//	
	eff_with_shadow /= normVal		// eff(lam,th_x,th_y) / eff(lam,0,0)

	eff /= normVal
	
	// (DONE)
	// - clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_err,lat_err
	
	SetDataFolder root:
	return(0)
end



//
// Tube efficiency + shadowing
//
//
// TESTING function to generate the tables for interpolation
// and various combinations of the corrections for plotting
//
Function V_TubeShadowEffTables_withX()


	Variable lambda
	lambda = 6
	
	Variable theta_val=3			//the single theta_x value that is used
	
// TODO
// -- better storage location for tables
// bad place for now...	
	SetDataFolder root:

//make waves that will be filed with the scattering angles and the result of the calculation
//

//// fill arrays with the scattering angles theta_x and theta_y
// 0 < x < 50
// 0 < y < 50

// *** the definitions of x and y for the T/B panels is flipped so that x is always lateral WRT the tubes
// and y is always along the length of the tubes

	Variable ii,jj,numx,numy,dx,dy,cos_th,arg,tmp,normVal
	numx = 10
	numy = 10

//	Make/O/D/N=(numx,numy) eff
	Make/O/D/N=(numx) theta_x, theta_y,eff_with_shadow,lam_cos
	
	theta_x = p*5
	theta_y = p*5		// value range from 0->45, changes if you change numx
	
	//convert degrees to radians
	theta_x = theta_x/360*2*pi
	theta_y = theta_y/360*2*pi

	Make/O/D/N=12 lam_wave
	lam_wave = {0.5,0.7,1,1.5,2,3,4,6,8,10,15,20}
	
	Make/O/D/N=(12*numx) eff_withX_to_interp,lam_cos_theta_y
	eff_withX_to_interp=0
	lam_cos_theta_y=0
	
	Make/O/D/N=3 pWave

	for(jj=0;jj<12;jj+=1)

		pWave[0] = lam_wave[jj]

		for(ii=0	;ii<numx;ii+=1)
			
				pWave[1] = theta_val/360*2*pi		//set theta x to any value
				pWave[2] = theta_y[ii]
	
				eff_with_shadow[ii] = Integrate1D(V_Efficiency_Integral,-kTube_ri,kTube_ri,2,0,pWave)		// adaptive Gaussian quadrature
				eff_with_shadow[ii] /= (2*kTube_ri)
				
		endfor
		
		lam_cos = lam_wave[jj]/cos(theta_y)

// messy indexing for the concatentation		
		lam_cos_theta_y[jj*numx,(jj+1)*numx-1] = lam_cos[p-jj*numx]
		eff_withX_to_interp[jj*numx,(jj+1)*numx-1] = eff_with_shadow[p-jj*numx]
		
	endfor
	
	Sort lam_cos_theta_y,eff_withX_to_interp,lam_cos_theta_y	
	
//	
////////	// value for normalization at what wavelength???
//	pWave[0] = 6
//	pWave[1] = 0
//	pWave[2] = 0
//////	
//	normVal = Integrate1D(V_Efficiency_Integral,-kTube_ri,kTube_ri,2,0,pWave)
//	normVal /= (2*kTube_ri)
////	
//	print normVal
////	
//	eff_withX_to_interp /= normVal		// eff(lam,th_x,th_y) / eff(lam,0,0)

	// (DONE)
	// - clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_err,lat_err
	
	return(0)
end



/////////////

//
//
// testing function to calculate the correction for the attenuation
// of the scattered beam by windows downstream of the sample
// (the back window of the sample block, the Si window)
//
// For implementation, this function could be made identical
// to the large angle transmission correction, since the math is
// identical - only the Tw value is different (and should ideally be
// quite close to 1). With Tw near 1, this would be a few percent correction
// at the largest scattering angles.
//
//
Function V_WindowTransmission(tw)
	Variable tw
	
	Make/O/D/N=100 theta,method1,method2,arg,qval_6a,theta_deg
	
	theta = p/2
	theta = theta/360*2*pi		//convert to radians

// for plotting
	qval_6a = 4*pi/6*sin(theta/2)
	theta_deg = p/2
	
//	method1 = exp( -ln(tw)/cos(theta) )/tw
	
	Variable tau
	tau = -ln(tw)
	arg = (1-cos(theta))/cos(theta)
	
	if(tau < 0.01)
		method2 = 1 - 0.5*tau*arg	
	else
		method2 = ( 1 - exp(-tau*arg) )/(tau*arg)
	endif
	
	return(0)
end


//
// Large angle transmission correction for the downstream window
//
// DIVIDE the intensity by this correction to get the right answer
//
// -- this is a duplication of the math for the large angle
// sample tranmission correction. Same situation, but now the 
// scattered neutrons are attenuated by whatever windows are 
// downstream of the scattering event.
// (the back window of the sample block, the Si window)
//
// For implementation, this function is made identical
// to the large angle transmission correction, since the math is
// identical - only the Tw value is different (and should ideally be
// quite close to 1). With Tw near 1, this would be a few percent correction
// at the largest scattering angles.
//
//
Function V_DownstreamWindowTransmission(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,uval

// get all of the geometry information	
//	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)

	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)

// get the value of the overall transmission of the downstream components
// + error if available.
//	trans = V_getSampleTransmission(fname)
//	trans_err = V_getSampleTransError(fname)
// TODO -- HARD WIRED values, need to set a global or find a place in the header (instrument block?) (reduction?)
// currently globals are forced to one in WorkFolderUtils.ipf as the correction is done
	NVAR trans = root:Packages:NIST:VSANS:Globals:gDownstreamWinTrans
	NVAR trans_err = root:Packages:NIST:VSANS:Globals:gDownstreamWinTransErr	

	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w dwt_corr,tmp_theta,tmp_dist,dwt_err,tmp_err		//in the current df

//// calculate the scattering angle
//	dx = (distX - xctr)		//delta x in mm
//	dy = (distY - yctr)		//delta y in mm
	tmp_dist = sqrt((data_realDistX - xctr)^2 + (data_realDistY - yctr)^2)
	
	tmp_dist /= 10  // convert mm to cm
	// sdd is in [cm]

	tmp_theta = atan(tmp_dist/sdd)		//this is two_theta, the scattering angle

	Variable ii,jj,numx,numy,dx,dy,cos_th,arg,tmp
	numx = DimSize(tmp_theta,0)
	numy = DimSize(tmp_theta,1)
	
	
	//optical thickness
	uval = -ln(trans)		//use natural logarithm
	
	for(ii=0	;ii<numx;ii+=1)
		for(jj=0;jj<numy;jj+=1)
			
			cos_th = cos(tmp_theta[ii][jj])
			arg = (1-cos_th)/cos_th
			
			// a Taylor series around uval*arg=0 only needs about 4 terms for very good accuracy
			// 			correction= 1 - 0.5*uval*arg + (uval*arg)^2/6 - (uval*arg)^3/24 + (uval*arg)^4/120
			// OR
			if((uval<0.01) || (cos_th>0.99))	
				//small arg, approx correction
				dwt_corr[ii][jj] = 1-0.5*uval*arg
			else
				//large arg, exact correction
				dwt_corr[ii][jj] = (1-exp(-uval*arg))/(uval*arg)
			endif
			 
			// (DONE)
			// x- properly calculate and apply the 2D error propagation
			if(trans == 1)
				dwt_err[ii][jj] = 0		//no correction, no error
			else
				//sigT, calculated from the Taylor expansion
				tmp = (1/trans)*(arg/2-arg^2/3*uval+arg^3/8*uval^2-arg^4/30*uval^3)
				tmp *= tmp
				tmp *= trans_err^2
				tmp = sqrt(tmp)		//sigT
				
				dwt_err[ii][jj] = tmp
			endif
			 
		endfor
	endfor
	
	// Here it is! Apply the correction to the intensity (divide -- to get the proper correction)
	w /= dwt_corr

	// relative errors add in quadrature to the current 2D error
	tmp_err = (w_err/dwt_corr)^2 + (dwt_err/dwt_corr)^2*w*w/dwt_corr^2
	tmp_err = sqrt(tmp_err)
	
	w_err = tmp_err	
	
	// DONE x- clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist,tmp_err,dwt_err
	
	return(0)
end

