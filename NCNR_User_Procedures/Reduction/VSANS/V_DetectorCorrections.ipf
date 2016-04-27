#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion=6.1



//
// functions to apply corrections to the detector panels
//
// these are meant to be called by the procedures that convert "raw" data to 
// "adjusted" or corrected data sets
//
// may be relocated in the future
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
// TODO
// -- verify the direction of the tubes and indexing
// x- decide on the appropriate functional form for the tubes
// x- need count time as input
// -- be sure I'm working in the right data folder
// -- clean up when done
// -- calculate + return the error contribution?
//
Function DeadTimeCorrectionTubes(dataW,data_errW,dtW,ctTime)
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

	elseif(cmpstr(orientation,"horizontal")==0)
	//	this is data (horizontal) dimensioned as (Npix,Ntubes)

		MatrixOp/O sumTubes = sumCols(dataW)		// 1 x m result
		sumTubes /= ctTime
		
		dataW[][] = dataW[p][q]/(1-sumTubes[q]*dtW[q])
	
	else		
		DoAlert 0,"Orientation not correctly passed in DeadTimeCorrectionTubes(). No correction done."
	endif
	
	return(0)
end

// test function
Function testDTCor()

	String detStr = ""
	String fname = "RAW"
	Variable ctTime
	
	detStr = "FR"
	Wave w = V_getDetectorDataW(fname,detStr)
	Wave w_err = V_getDetectorDataErrW(fname,detStr)
	Wave w_dt = V_getDetector_deadtime(fname,detStr)

	ctTime = V_getCount_time(fname)
	
//	ctTime = 10
	DeadTimeCorrectionTubes(w,w_err,w_dt,ctTime)

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
// TODO
// -- UNITS!!!! currently this is mm, which certainly doesn't match anything else!!!
// -- verify the direction of the tubes and indexing
// -- be sure I'm working in the right data folder
// -- clean up when done
// -- calculate + return the error contribution?
// -- do I want this to return a wave?
// -- do I need to write a separate function that returns the distance wave for later calculations?
// -- do I want to make the distance array 3D to keep the x and y dims together? Calculate them all right now?
// -- what else do I need to pass to the function? (fname=folder? detStr?)
// -- need a separate block or function to handle "B" detector which will be ? different
//
//
Function NonLinearCorrection(dataW,coefW,tube_width,detStr,destPath)
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
	
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
		data_realDistX[][] = tube_width*p
		data_realDistY[][] = coefW[0][p] + coefW[1][p]*q + coefW[2][p]*q*q
	
	elseif(cmpstr(orientation,"horizontal")==0)
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)
		data_realDistX[][] = coefW[0][q] + coefW[1][q]*p + coefW[2][q]*p*p
		data_realDistY[][] = tube_width*q

	else		
		DoAlert 0,"Orientation not correctly passed in NonLinearCorrection(). No correction done."
	endif
	
	return(0)
end

// TODO:
// -- the cal_x and y coefficients are totally fake
// -- the wave assignment may not be correct.. so beware
//
//
Function NonLinearCorrection_B(folder,detStr,destPath)
	String folder,detStr,destPath

	if(cmpstr(detStr,"B") != 0)
		return(0)
	endif
	
	// do I count on the orientation as an input, or do I just figure it out on my own?
	Variable dimX,dimY
	
	Wave dataW = V_getDetectorDataW(folder,detStr)
	
	dimX = DimSize(dataW,0)
	dimY = DimSize(dataW,1)

	// make a wave of the same dimensions, in the same data folder for the distance
	// ?? or a 3D wave?
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Make/O/D/N=(dimX,dimY) $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
	Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	
	
	Wave cal_x = V_getDet_cal_x(folder,detStr)
	Wave cal_y = V_getDet_cal_y(folder,detStr)
	
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
Function ConvertBeamCtr_to_mm(folder,detStr,destPath)
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
// TODO
// -- VERIFY the calculations
// -- verify where this needs to be done (if the beam center is changed)
// -- then the q-calculation needs to be re-done
// -- the position along the tube length is referenced to tube[0], for no particular reason
//    It may be better to take an average? but [0] is an ASSUMPTION
// -- distance along tube is simple interpolation
//
// -- distance in the lateral direction is based on tube width, which is well known
//
//
Function ConvertBeamCtr_to_mmB(folder,detStr,destPath)
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

// TODO
// get rid of this in the real data
//
// TESTING ONLY
Proc MakeFakeCalibrationWaves()
	// make these in the RAW data folder, before converting to a work folder
	// - then they will be "found" by get()
	// -- only for the tube, not the Back det
	
//	DoAlert 0, "re-do this and do a better job of filling the fake calibration data"

	DoAlert 0, "Calibration waves are read in from the data file"
	
//	fMakeFakeCalibrationWaves()
End



// TODO
// get rid of this in the real data
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
Function fMakeFakeCalibrationWaves()

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
			pixSize = 8			//V_getDet_y_pixel_size(fname,detStr)
			
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
	sdd = V_getDet_distance(fname,detStr)
	sdd/=100		// sdd reported in cm, pass in m
	// this is the ctr in pixels
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
	qTot = V_CalcQval(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qx = V_CalcQX(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qy = V_CalcQY(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	qz = V_CalcQZ(p,q,xCtr,yCtr,sdd,lambda,data_realDistX,data_realDistY)
	
	
	return(0)
End


//function to calculate the overall q-value, given all of the necesary trig inputs
//
// TODO:
// -- verify the calculation (accuracy - in all input conditions)
// -- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// -- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
//sdd is in meters
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
Function V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY
	
	Variable dx,dy,qval,two_theta,dist
		
	sdd *=100		//convert to cm
	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	dist = sqrt(dx^2 + dy^2)
	
	dist /= 10  // convert mm to cm
	
	two_theta = atan(dist/sdd)

	qval = 4*Pi/lam*sin(two_theta/2)
	
	return qval
End

//calculates just the q-value in the x-direction on the detector
// TODO:
// -- verify the calculation (accuracy - in all input conditions)
// -- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// -- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
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
	
	sdd *=100		//convert to cm
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
// TODO:
// -- verify the calculation (accuracy - in all input conditions)
// -- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// -- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
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
	
	sdd *=100		//convert to cm
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
// TODO:
// -- verify the calculation (accuracy - in all input conditions)
// -- verify the units of everything here, it's currently all jumbled and wrong... and repeated
// -- the input data_realDistX and Y are essentially lookup tables of the real space distance corresponding
//    to each pixel
//
// not actually used for anything, but here for completeness if anyone asks
//
// this properly accounts for qz
//
Function V_CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam
	Wave distX,distY

	Variable qz,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,distX,distY)
	
	sdd *=100		//convert to cm
	dx = (distX[xaxval][yaxval] - xctr)		//delta x in mm
	dy = (distY[xaxval][yaxval] - yctr)		//delta y in mm
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	dist /= 10  // convert mm to cm

	two_theta = atan(dist/sdd)

	qz = qval*sin(two_theta/2)
	
	return qz
End



////////////
// TODO: all of below is untested code
//   copied from SANS
//
//
// TODO : 
//   -- DoAlert 0,"This has not yet been updated for VSANS"
//
//performs solid angle and non-linear detector corrections to raw data as it is "added" to a work folder
//function is called by Raw_to_work() and Add_raw_to_work() functions
//works on the actual data array, assumes that is is already on LINEAR scale
//
Function DetCorr(data,data_err,realsread,doEfficiency,doTrans)
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
				data[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
				data_err[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
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
				lat_corr = LargeAngleTransmissionCorr(trans,dtdist,xd,yd,trans_err,lat_err)		//moved from 1D avg SRK 11/2007
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



//distances passed in are in mm
// dtdist is SDD
// xd and yd are distances from the beam center to the current pixel
//
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
Function DetEffCorr(lambda,dtdist,xd,yd)
	Variable lambda,dtdist,xd,yd

	DoAlert 0,"This has not yet been updated for VSANS"
	
	Variable theta,cosT,ff,stAl,stHe
	
	theta = atan( (sqrt(xd^2 + yd^2))/dtdist )
	cosT = cos(theta)
	
	stAl = 0.00967*lambda*0.8		//dimensionless, constants from JGB memo
	stHe = 0.146*lambda*2.5
	
	ff = exp(-stAl/cosT)*(1-exp(-stHe/cosT)) / ( exp(-stAl)*(1-exp(-stHe)) )
		
	return(ff)
End

// DIVIDE the intensity by this correction to get the right answer
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
//
Function LargeAngleTransmissionCorr(trans,dtdist,xd,yd,trans_err,err)
	Variable trans,dtdist,xd,yd,trans_err,&err

	DoAlert 0,"This has not yet been updated for VSANS"
	
	//angle dependent transmission correction 
	Variable uval,arg,cos_th,correction,theta
	
	////this section is the trans_correct() VAX routine
//	if(trans<0.1)
//		Print "***transmission is less than 0.1*** and is a significant correction"
//	endif
//	if(trans==0)
//		Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
//		trans = 1
//	endif
	
	theta = atan( (sqrt(xd^2 + yd^2))/dtdist )		//theta at the input pixel
	
	//optical thickness
	uval = -ln(trans)		//use natural logarithm
	cos_th = cos(theta)
	arg = (1-cos_th)/cos_th
	
	// a Taylor series around uval*arg=0 only needs about 4 terms for very good accuracy
	// 			correction= 1 - 0.5*uval*arg + (uval*arg)^2/6 - (uval*arg)^3/24 + (uval*arg)^4/120
	// OR
	if((uval<0.01) || (cos_th>0.99))	
		//small arg, approx correction
		correction= 1-0.5*uval*arg
	else
		//large arg, exact correction
		correction = (1-exp(-uval*arg))/(uval*arg)
	endif

	Variable tmp
	
	if(trans == 1)
		err = 0		//no correction, no error
	else
		//sigT, calculated from the Taylor expansion
		tmp = (1/trans)*(arg/2-arg^2/3*uval+arg^3/8*uval^2-arg^4/30*uval^3)
		tmp *= tmp
		tmp *= trans_err^2
		tmp = sqrt(tmp)		//sigT
		
		err = tmp
	endif
	
//	Printf "trans error = %g\r",trans_err
//	Printf "correction = %g +/- %g\r", correction, err
	
	//end of transmission/pathlength correction

	return(correction)
end


//
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
//test procedure, not called anymore
Proc AbsoluteScaling(type,c0,c1,c2,c3,c4,c5)
	String type
	Variable c0=1,c1=0.1,c2=0.95,c3=0.1,c4=1,c5=32.0
	Prompt type,"WORK data type",popup,"CAL;COR;SAM"
	Prompt c0, "Sample Transmission"
	Prompt c1, "Sample Thickness (cm)"
	Prompt c2, "Standard Transmission"
	Prompt c3, "Standard Thickness (cm)"
	Prompt c4, "I(0) from standard fit (normalized to 1E8 monitor cts)"
	Prompt c5, "Standard Cross-Section (cm-1)"

	Variable err
	//call the function to do the math
	//data from "type" will be scaled and deposited in ABS
	err = Absolute_Scale(type,c0,c1,c2,c3,c4,c5)
	
	if(err)
		Abort "Error in Absolute_Scale()"
	endif
	
	//contents are always dumped to ABS
	type = "ABS"
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current display type to "type"
	SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
	gCurDispType = Type	
	
	fRawWindowHook()
	
End

//
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
//s_ is the standard
//w_ is the "work" file
//both are work files and should already be normalized to 10^8 monitor counts
Function Absolute_Scale(type,w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err)
	String type
	Variable w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err

	DoAlert 0,"This has not yet been updated for VSANS"
		
	//convert the "type" data to absolute scale using the given standard information
	//copying the "type" waves to ABS
	
	//check for existence of data, rescale to linear if needed
	String destPath
	//check for "type"
	if(WaveExists($("root:Packages:NIST:"+Type + ":data")) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	Endif
	//check for log-scaling of the "type" data and adjust if necessary
	destPath = "root:Packages:NIST:"+Type
	NVAR gIsLogScale = $(destPath + ":gIsLogScale")
	if(gIsLogScale)
		Duplicate/O $(destPath + ":linear_data") $(destPath + ":data")//back to linear scale
		Variable/G $(destPath + ":gIsLogScale")=0	//the "type" data is not logscale anymore
	endif
	
	//copy "oldtype" information to ABS
	//overwriting out the old contents of the ABS folder (/O option in Duplicate)
	//copy over the waves data,vlegend,text,integers,reals(read)

	String oldType= "root:Packages:NIST:"+type  		//this is where the data to be absoluted is 
	//copy from current dir (type) to ABS, defined by destPath
	Duplicate/O $(oldType + ":data"),$"root:Packages:NIST:ABS:data"
	Duplicate/O $(oldType + ":linear_data"),$"root:Packages:NIST:ABS:linear_data"
	Duplicate/O $(oldType + ":linear_data_error"),$"root:Packages:NIST:ABS:linear_data_error"
//	Duplicate/O $(oldType + ":vlegend"),$"root:Packages:NIST:ABS:vlegend"
	Duplicate/O $(oldType + ":textread"),$"root:Packages:NIST:ABS:textread"
	Duplicate/O $(oldType + ":integersread"),$"root:Packages:NIST:ABS:integersread"
	Duplicate/O $(oldType + ":realsread"),$"root:Packages:NIST:ABS:realsread"
	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(oldType + ":fileList")
	//need to copy filelist string too
	String/G $"root:Packages:NIST:ABS:fileList" = oldFileList
	
	//now switch to ABS folder
	//make appropriate wave references
	WAVE data=$"root:Packages:NIST:ABS:linear_data"					// these wave references point to the "type" data in ABS
	WAVE data_err=$"root:Packages:NIST:ABS:linear_data_error"					// these wave references point to the "type" data in ABS
	WAVE data_copy=$"root:Packages:NIST:ABS:data"					// just for display
	WAVE/T textread=$"root:Packages:NIST:ABS:textread"			//that are to be directly operated on
	WAVE integersread=$"root:Packages:NIST:ABS:integersread"
	WAVE realsread=$"root:Packages:NIST:ABS:realsread"
	Variable/G $"root:Packages:NIST:ABS:gIsLogscale"=0			//make new flag in ABS folder, data is linear scale
	
	//do the actual absolute scaling here, modifying the data in ABS
	Variable defmon = 1e8,w_moncount,s1,s2,s3,s4
	
	w_moncount = realsread[0]		//monitor count in "type"
	if(w_moncount == 0)
		//zero monitor counts will give divide by zero ---
		DoAlert 0,"Total monitor count in data file is zero. No rescaling of data"
		Return(1)		//report error
	Endif
	
	//calculate scale factor
	Variable scale,trans_err
	s1 = defmon/realsread[0]		//[0] is monitor count (s1 should be 1)
	s2 = s_thick/w_thick
	s3 = s_trans/w_trans
	s4 = s_cross/s_izero
	
	// kappa comes in as s_izero, so be sure to use 1/kappa_err
	
	data *= s1*s2*s3*s4
	
	scale = s1*s2*s3*s4
	trans_err = realsRead[41]
	
//	print scale
//	print data[0][0]
	
	data_err = sqrt(scale^2*data_err^2 + scale^2*data^2*(kappa_err^2/s_izero^2 +trans_err^2/w_trans^2))

//	print data_err[0][0]
	
// keep "data" in sync with linear_data	
	data_copy = data
	
	//********* 15APR02
	// DO NOt correct for atenuators here - the COR step already does this, putting all of the data one equal
	// footing (zero atten) before doing the subtraction.
	//
	//Print "ABS data multiplied by  ",s1*s2*s3*s4/attenFactor
	
	//update the ABS header information
	textread[1] = date() + " " + time()		//date + time stamp
	
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
Function Adjust_RAW_Attenuation(type)
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
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//
//************************
//unused testing procedure, may not be up-to-date with other procedures
//check before re-implementing
//
Proc DIV_a_Workfile(type)
	String type
	Prompt type,"WORK data type",popup,"SAM;EMP;BGD;ADJ;"
	
	//macro will take whatever is in SELECTED folder and DIVide it by the current
	//contents of the DIV folder - the function will check for existence 
	//before proceeding

//DoAlert 0,"This has not yet been updated for VSANS"
	
	Variable err
	err = DIVCorrection(type)		//returns err = 1 if data doesn't exist in specified folders
	
	if(err)
		Abort "error in DIVCorrection()"
	endif
	
	//contents are NOT always dumped to CAL, but are in the new type folder
	
	String newTitle = "WORK_"+type
	DoWindow/F VSANS_Data
	DoWindow/T VSANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=Type
	
	UpdateDisplayInformation(type)
	
End


//
// TODO:
//   -- 	DoAlert 0,"This has not yet been updated for VSANS"
//  -- how is the error propagation  handled?
//
//function will divide the contents of "workType" folder with the contents of 
//the DIV folder + detStr
// all data is linear scale for the calculation
//
Function DIVCorrection(data,data_err,detStr,workType)
	Wave data,data_err
	String detStr,workType
	
	//check for existence of data in type and DIV
	// if the desired data doesn't exist, let the user know, and abort
	String destPath=""

	if(WaveExists(data) == 0)
		Print "The data wave does not exist in DIVCorrection()"
		Return(1) 		//error condition
	Endif
	
	//check for DIV
	// if the DIV workfile doesn't exist, let the user know,and abort

	WAVE/Z div_data = $("root:Packages:NIST:VSANS:DIV:entry:instrument:detector_"+detStr+":data")
	if(WaveExists(div_data) == 0)
		Print "The DIV wave does not exist in DIVCorrection()"
		Return(1)		//error condition
	Endif
	//files exist, proceed

	data /= div_data
	
//	data_err /= div_data
	
	Return(0)
End


//////////////////////////