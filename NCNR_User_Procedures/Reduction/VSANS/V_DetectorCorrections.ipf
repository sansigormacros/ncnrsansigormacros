#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion=6.1



//
// functions to apply corrections to the detector panels
//
// these are meant to be called by the procedures that convert "raw" data to 
// "adjusted" or corrected data sets
//




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
	
	// TODO
	// -- GAP IS HARD-WIRED as constant values 
	Variable offset,gap

// kPanelTouchingGap is in mm	
// the gap is split equally between the panel pairs
// TODO -- replace all of this with V_getDet_panel_gap(fname,detStr) once it is added to the file
// these hard-wired values were determined from 6A and WB beam centers. LR values were exactly the same for
// both beam conditions (+/- 0.0 mm). FTB was +/- 0.8 mm, MTB +/- 2 mm
	if(cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"FR") == 0)
		gap = 3.8		//mm (measured, JB 1/4/18)
	endif
	if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
		gap = 8		//mm
	endif
	if(cmpstr(detStr,"ML") == 0 || cmpstr(detStr,"MR") == 0)
		gap = 5.9		//mm (measured, JB 1/4/18)
	endif
	if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
		gap = 5		//mm
	endif
// TODO: this is the line to keep, to replace the hard-wired values
//	gap = V_getDet_panel_gap(fname,detStr)
	
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
	
		// adjust the x postion based on the beam center being nominally (0,0) in units of cm, not pixels
		if(cmpstr(fname,"VCALC")== 0 )
			offset = VCALC_getPanelSeparation(detStr)
			offset *= 10			// convert to units of mm
			offset /= 2			// 1/2 the total separation
			if(cmpstr("L",detStr[1]) == 0)
				offset *= -1		//negative value for L
			endif
		else
			//normal case
			offset = V_getDet_LateralOffset(fname,detStr)
			offset *= 10 //convert cm to mm
		endif
		
	// calculation is in mm, not cm
	// offset will be a negative value for the L panel, and positive for the R panel
		if(kBCTR_CM)
			if(cmpstr("L",detStr[1]) == 0)
//				data_realDistX[][] = offset - (dimX - p)*tube_width			// TODO should this be dimX-1-p = 47-p?
				data_realDistX[][] = offset - (dimX - p - 1/2)*tube_width - gap/2		// TODO should this be dimX-1-p = 47-p?
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
			offset = VCALC_getPanelSeparation(detStr)
			offset *= 10			// convert to units of mm
			offset /= 2			// 1/2 the total separation
			if(cmpstr("B",detStr[1]) == 0)
				offset *= -1	// negative value for Bottom det
			endif
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
//				data_realDistY[][] = offset - (dimY - q)*tube_width	// TODO should this be dimY-1-q = 47-q?
				data_realDistY[][] = offset - (dimY - q - 1/2)*tube_width - gap/2	// TODO should this be dimY-1-q = 47-q?
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




// TODO:
// -- the cal_x and y coefficients are totally fake
// -- the wave assignment may not be correct.. so beware
//
//
Function V_NonLinearCorrection_B(folder,dataW,cal_x,cal_y,detStr,destPath)
	String folder
	Wave dataW,cal_x,cal_y
	String detStr,destPath

	if(cmpstr(detStr,"B") != 0)
		return(0)
	endif
	
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
	
	data_realDistX[][] = cal_x[0]*p
	data_realDistY[][] = cal_y[0]*q
	
	return(0)
end


//
//
// TODO
// -- VERIFY the calculations
// -- verify where this needs to be done (if the beam center is changed)
// -- then the q-calculation needs to be re-done
// -- the position along the tube length is referenced to tube[0], for no particular reason
//    It may be better to take an average? but [0] is an ASSUMPTION
// -- distance along tube is simple interpolation, or do I use the coefficients to
//    calculate the actual value
//
// -- distance in the lateral direction is based on tube width, which is a fixed parameter
//
//
Function V_ConvertBeamCtr_to_mm(folder,detStr,destPath)
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

	Variable tube_width = V_getDet_tubeWidth(folder,detStr)

//
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
//		data_realDistX[][] = tube_width*p
//		data_realDistY[][] = coefW[0][p] + coefW[1][p]*q + coefW[2][p]*q*q
		x_mm[0] = tube_width*xCtr
		y_mm[0] = data_realDistY[0][yCtr]
	else
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)
//		data_realDistX[][] = coefW[0][q] + coefW[1][q]*p + coefW[2][q]*p*p
//		data_realDistY[][] = tube_width*q
		x_mm[0] = data_realDistX[xCtr][0]
		y_mm[0] = tube_width*yCtr
	endif
		
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

// kPanelTouchingGap is in mm	
// the gap is split equally between the panel pairs
// TODO -- replace all of this with V_getDet_panel_gap(fname,detStr) once it is added to the file
// these hard-wired values were determined from 6A and WB beam centers. LR values were exactly the same for
// both beam considitions (+/- 0.0 mm). FTB was +/- 0.8 mm, MTB +/- 2 mm
	if(cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"FR") == 0)
		gap = 3.8		//mm
	endif
	if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
		gap = 5		//mm
	endif
	if(cmpstr(detStr,"ML") == 0 || cmpstr(detStr,"MR") == 0)
		gap = 5.9		//mm
	endif
	if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
		gap = 5		//mm
	endif
// TODO: this is the line to keep, to replace the hard-wired values
//	gap = V_getDet_panel_gap(fname,detStr)
	
//
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)

		if(kBCTR_CM)
			if(cmpstr("L",detStr[1]) == 0)
				edge = data_realDistX[47][0]		//tube 47
				delta = abs(xCtr*10 - edge)
				x_pix[0] = dimX-1 + delta/tube_width
			else
			// R panel
				edge = data_realDistX[0][0]
				delta = abs(xCtr*10 - edge + gap)
				x_pix[0] = -delta/tube_width		//since the left edge of the R panel is pixel 0
			endif
		endif

		Make/O/D/N=(dimY) tmpTube
		tmpTube = data_RealDistY[0][p]
		FindLevel /P/Q tmpTube, yCtr
		
		y_pix[0] = V_levelX
		KillWaves/Z tmpTube
	else
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)

		if(kBCTR_CM)
			if(cmpstr("T",detStr[1]) == 0)
				edge = data_realDistY[0][0]		//tube 0
				delta = abs(yCtr*10 - edge + gap)
				y_pix[0] =  -delta/tube_width		//since the bottom edge of the T panel is pixel 0
			else
			// FM(B) panel
				edge = data_realDistY[0][47]		//y tube 47
				delta = abs(yCtr*10 - edge)
				y_pix[0] = dimY-1 + delta/tube_width		//since the top edge of the B panels is pixel 47		
			endif
		endif

		
		Make/O/D/N=(dimX) tmpTube
		tmpTube = data_RealDistX[p][0]
		FindLevel /P/Q tmpTube, xCtr
		
		x_pix[0] = V_levelX
		KillWaves/Z tmpTube
		
		
	endif
		
	return(0)
end

//
//
// TODO
// -- VERIFY the calculations
// -- verify where this needs to be done (if the beam center is changed)
// -- then the q-calculation needs to be re-done
//
// -- not much is known about the "B" detector, so this
//    all hinges on the non-linear corrections being done correctly for that detector
//
//
Function V_ConvertBeamCtr_to_mmB(folder,detStr,destPath)
	String folder,detStr,destPath
	
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
	
	cal_x = 1		// mm, ignore the other 2 values
	cal_y = 1		// mm
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
	qTot = V_CalcQval(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qx = V_CalcQX(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qy = V_CalcQY(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qz = V_CalcQZ(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	
	
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
Function V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
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
Function V_CalcQX(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
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
Function V_CalcQY(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
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
Function V_CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
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
//
Function V_SolidAngleCorrection(w,w_err,fname,detStr,destPath)
	Wave w,w_err
	String fname,detStr,destPath

	Variable sdd,xCtr,yCtr,lambda

// get all of the geometry information	
//	orientation = V_getDet_tubeOrientation(fname,detStr)
	sdd = V_getDet_ActualDistance(fname,detStr)


	// this is ctr in mm
	xCtr = V_getDet_beam_center_x_mm(fname,detStr)
	yCtr = V_getDet_beam_center_y_mm(fname,detStr)
	lambda = V_getWavelength(fname)
	
	SetDataFolder $(destPath + ":entry:instrument:detector_"+detStr)
	
	Wave data_realDistX = data_realDistX
	Wave data_realDistY = data_realDistY

	Duplicate/O w solid_angle,tmp_theta,tmp_dist		//in the current df

//// calculate the scattering angle
//	dx = (distX - xctr)		//delta x in mm
//	dy = (distY - yctr)		//delta y in mm
	tmp_dist = sqrt((data_realDistX - xctr)^2 + (data_realDistY - yctr)^2)
	
	tmp_dist /= 10  // convert mm to cm
	// sdd is in [cm]

	tmp_theta = atan(tmp_dist/sdd)		//this is two_theta, the scattering angle

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
	
	//
	// correctly apply the correction to the error wave (assume a perfect value?)
 	w_err /= solid_angle		//

// DONE x- clean up after I'm satisfied computations are correct		
	KillWaves/Z tmp_theta,tmp_dist
	
	return(0)
end


////////////
// TODO: all of below is untested code
//   copied from SANS
//
//
// NOV 2017
// Currently, this is not called from any VSANS routines. it is only referenced
// from V_Add_raw_to_work(), which would add two VSANS raw data files together. This has
// not yet been implemented. I am only keeping this function around to be sure that 
// if/when V_Add_raw_to_work() is implemented, all of the functionality of V_DetCorr() is
// properly duplicated.
//
//
//
//performs solid angle and non-linear detector corrections to raw data as it is "added" to a work folder
//function is called by Raw_to_work() and Add_raw_to_work() functions
//works on the actual data array, assumes that is is already on LINEAR scale
//
Function V_DetCorr(data,data_err,realsread,doEfficiency,doTrans)
	Wave data,data_err,realsread
	Variable doEfficiency,doTrans

	DoAlert 0,"This has not yet been updated for VSANS"
	
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,xx0,yy0
	Variable ii,jj,dtdist,dtdis2
	Variable xi,xd,yd,rad,ratio,domega,xy
	Variable lambda,trans,trans_err,lat_err,tmp_err,lat_corr
	
//	Print "...doing jacobian and non-linear corrections"

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//set up values to send to auxiliary trig functions
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela

	x0 = realsread[16]
	y0 = realsread[17]
	sx = realsread[10]
	sx3 = realsread[11]
	sy = realsread[13]
	sy3 = realsread[14]
	
	dtdist = 1000*realsread[18]	//sdd in mm
	dtdis2 = dtdist^2
	
	lambda = realsRead[26]
	trans = RealsRead[4]
	trans_err = RealsRead[41]		//new, March 2011
	

	//waves to contain repeated function calls
	Make/O/N=(pixelsX) fyy,xx,yy		//Assumes square detector !!!
	ii=0
	do
		xi = ii
//		fyy[ii] = dc_fy(ii+1,sy,sy3,ycenter)
//		xx[ii] = dc_fxn(ii+1,sx,sx3,xcenter)
//		yy[ii] = dc_fym(ii+1,sy,sy3,ycenter)
		ii+=1
	while(ii<pixelsX)
	
	Make/O/N=(pixelsX,pixelsY) SolidAngle		// testing only
	
	ii=0
	do
		xi = ii
//		xd = dc_fx(ii+1,sx,sx3,xcenter)-xx0
		jj=0
		do
			yd = fyy[jj]-yy0
			//rad is the distance of pixel ij from the sample
			//domega is the ratio of the solid angle of pixel ij versus center pixel
			// product xy = 1 for a detector with a linear spatial response (modern Ordela)
			// solid angle calculated, dW^3 >=1, so multiply data to raise measured values to correct values.
			rad = sqrt(dtdis2 + xd^2 + yd^2)
			domega = rad/dtdist
			ratio = domega^3
			xy = xx[ii]*yy[jj]
			
			data[ii][jj] *= xy*ratio
			
			solidAngle[ii][jj] = xy*ratio		//testing only	
			data_err[ii][jj] *= xy*ratio			//error propagation assumes that SA and Jacobian are exact, so simply scale error
			
			
			// correction factor for detector efficiency JBG memo det_eff_cor2.doc 3/20/07
			// correction inserted 11/2007 SRK
			// large angle detector efficiency is >= 1 and will "bump up" the measured value at the highest angles
			// so divide here to get the correct answer (5/22/08 SRK)
			if(doEfficiency)
//				data[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
//				data_err[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
//				solidAngle[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)		//testing only
			endif
			
			// large angle transmission calculation is <= 1 and will "bump down" the measured value at the highest angles
			// so divide here to get the correct answer
			if(doTrans)
			
				if(trans<0.1 && ii==0 && jj==0)
					Print "***transmission is less than 0.1*** and is a significant correction"
				endif
				
				if(trans==0)
					if(ii==0 && jj==0)
						Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
					endif
					trans = 1
				endif
				
				// pass in the transmission error, and the error in the correction is returned as the last parameter

//				lat_corr = V_LargeAngleTransmissionCorr(trans,dtdist,xd,yd,trans_err,lat_err)		//moved from 1D avg SRK 11/2007

				data[ii][jj] /= lat_corr			//divide by the correction factor
				//
				//
				//
				// relative errors add in quadrature
				tmp_err = (data_err[ii][jj]/lat_corr)^2 + (lat_err/lat_corr)^2*data[ii][jj]*data[ii][jj]/lat_corr^2
				tmp_err = sqrt(tmp_err)
				
				data_err[ii][jj] = tmp_err
				
//				solidAngle[ii][jj] = lat_err

				
				//solidAngle[ii][jj] = LargeAngleTransmissionCorr(trans,dtdist,xd,yd)		//testing only
			endif
			
			jj+=1
		while(jj<pixelsX)
		ii+=1
	while(ii<pixelsX)
	
	//clean up waves
	
	Return(0)
End


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
Function V_Absolute_Scale(type,w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err)
	String type
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
	
	//calculate scale factor
	s1 = defmon/w_moncount		// monitor count (s1 should be 1)
	s2 = s_thick/w_thick
	s3 = s_trans/w_trans
	s4 = s_cross/s_izero
	scale = s1*s2*s3*s4

	trans_err = V_getSampleTransError(type)	
	
	// kappa comes in as s_izero, so be sure to use 1/kappa_err

	// and now loop through all of the detectors
	//do the actual absolute scaling here, modifying the data in ABS
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave data = V_getDetectorDataW("ABS",detStr)
		Wave data_err = V_getDetectorDataErrW("ABS",detStr)
		
		data *= scale
		data_err = sqrt(scale^2*data_err^2 + scale^2*data^2*(kappa_err^2/s_izero^2 +trans_err^2/w_trans^2))
	endfor
	
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
// TODO:
//   x- 	DoAlert 0,"This has not yet been updated for VSANS"
//   -- how is the error propagation handled? Be sure it is calculated correctly when DIV is generated
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

	if(WaveExists(data) == 0)
		Print "The data wave does not exist in V_DIVCorrection()"
		Return(1) 		//error condition
	Endif
	
	//check for DIV
	// if the DIV workfile doesn't exist, let the user know,and abort

	WAVE/Z div_data = $("root:Packages:NIST:VSANS:DIV:entry:instrument:detector_"+detStr+":data")
	if(WaveExists(div_data) == 0)
		Print "The DIV wave does not exist in V_DIVCorrection()"
		Return(1)		//error condition
	Endif
	//files exist, proceed

	data /= div_data

// TODO: -- correct the error propagation	
	data_err /= div_data
	
	Return(0)
End


//////////////////////////