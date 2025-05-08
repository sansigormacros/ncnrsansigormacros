#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

// Work file (folder) operations that work with the Ordela detector on the 30m SANS instruments
// and the Nexus file definition
//
// The plan is to separate out the detector-specific functions (for each of the detecor
// types, and keep everything else in common files
//
// Loading of the data is the same for every HDF5/Nexus file. It's all loaded.
// Reading/Writing is "common", but care must be taken to use only R/W functions that
// correspond to actual fields that are in the data files.
//
// The functions here are for convering raw data to a work folder, adding raw data files (as work files)
//
//
//
//
//
//
//
// MARCH 2011 - changed the references that manipulate the data to explcitly work on the linear_data wave
//					at the end of routines that manipulate linear_data, it is copied back to "data" which is displayed
//

//

//testing procedure, not called anymore
Proc Add_to_Workfile(type, add)
	string type, add
	Prompt type, "WORK data type", popup, "SAM;EMP;BGD"
	Prompt add, "Add to current WORK contents?", popup, "No;Yes"

	//macro will take whatever is in RAW folder and "ADD" it to the folder specified
	//in the popup menu

	//"add" = yes/no, don't add to previous runs
	//switch here - two separate functions to avoid (my) confusion
	variable err
	if(cmpstr(add, "No") == 0)
		//don't add to prev work contents, copy RAW contents to work and convert
		err = Raw_to_work(type)
	else
		//yes, add RAW to the current work folder contents
		err = Add_raw_to_work(type)
	endif

	string newTitle = "WORK_" + type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle

	//need to update the display with "data" from the correct dataFolder
	fRawWindowHook()

EndMacro

//will "ADD" the current contents of the RAW folder to the newType work folder
//and will ADD the RAW contents to the existing content of the newType folder
// - used when adding multiple runs together
//(the function Raw_to_work(type) makes a fresh workfile)
//
//the current display type is updated to newType (global)
Function Add_raw_to_work(string newType)

	// NEW OCT 2014
	// this corrects for adding raw data files with different attenuation
	// does nothing if the attenuation of RAW and destination are the same
	NVAR doAdjustRAW_Atten = root:Packages:NIST:gDoAdjustRAW_Atten
	if(doAdjustRAW_Atten)
		Adjust_RAW_Attenuation(newType)
	endif

	string destPath = ""

	// if the desired workfile doesn't exist, let the user know, and just make a new one
	if(WaveExists($("root:Packages:NIST:" + newType + ":data")) == 0)
		Print "There is no old work file to add to - a new one will be created"
		//call Raw_to_work(), then return from this function
		Raw_to_Work_for_Ordela(newType)
		return (0) //does not generate an error - a single file was converted to work.newtype
	endif

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	variable pixelsX = getDet_pixel_num_x(newType)
	variable pixelsY = getDet_pixel_num_y(newType)

	//now make references to data in newType folder
	DestPath = "root:Packages:NIST:" + newType

	WAVE data = getDetectorDataW(newType) // these wave references point to the EXISTING work data
	//	WAVE data_copy=$(destPath +":data")			// these wave references point to the EXISTING work data
	WAVE dest_data_err = getDetectorDataErrW(newType) // these wave references point to the EXISTING work data

	variable deadTime, defmon, total_mon, total_det, total_trn, total_numruns, total_rtime
	variable ii, jj, itim, cntrate, dscale, scale, uscale, wrk_beamx, wrk_beamy, xshift, yshift

	// 08/01 detector constants are now returned from a function, based on the detector type and beamline
	//	dt_ornl = 3.4e-6		//deadtime of Ordella detectors	as of 30-AUG-99
	//	dt_ill=3.0e-6			//Cerca detector deadtime constant as of 30-AUG-99

	defmon = 1e8 //default monitor counts

	//Yes, add to previous run(s) in work, that does exist
	//use the actual monitor count run.savmon rather than the normalized monitor count
	//in run.moncnt and unscale the work data

	total_mon = getBeamMonNormSaved_count(newType)   //saved monitor count
	uscale    = total_mon / defmon                   //unscaling factor
	total_det = uscale * getDetector_counts(newType) //unscaled detector count

	total_rtime = getCount_time(newType) //total counting time in workfile

	//retrieve workfile beamcenter
	wrk_beamx = getDet_beam_center_x(newType)
	wrk_beamy = getDet_beam_center_y(newType)
	//unscale the workfile data in "newType"
	//
	//check for log-scaling and adjust if necessary
	// no need to convert the Nexus data to linear scale
	//	ConvertFolderToLinearScale(newType)
	//
	//then unscale the data array
	data          *= uscale
	dest_data_err *= uscale

	//DetCorr() has not been applied to the data in RAW , do it now in a local reference to the raw data
	WAVE raw_data     = getDetectorDataW("RAW")
	WAVE raw_data_err = getDetectorDataErrW("RAW")

	//check for log-scaling of the raw data - make sure it's linear
	//	ConvertFolderToLinearScale("RAW")

	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR     doEfficiency = root:Packages:NIST:gDoDetectorEffCorr
	NVAR     gDoTrans     = root:Packages:NIST:gDoTransmissionCorr
	variable doTrans      = gDoTrans
	if(cmpstr("BGD", newtype) == 0)
		doTrans = 0 //skip the trans correction for the BGD file but don't change the value of the global
	endif

	DetCorr(raw_data, raw_data_err, newType, doEfficiency, doTrans) //applies correction to raw_data, and overwrites it

	//	//if RAW data is ILL type detector, correct raw_data for same counts being written to 4 pixels
	//	if(cmpstr(raw_text[9], "ILL   ") == 0 )		//text field in header is 6 characters "ILL---"
	//		raw_data /= 4
	//		raw_data_err /= 4
	//	endif
	//

	// TODO -- the dead time correction will be different for the tube detectors,
	// and for the Ordela will be accessed differently - with the dt constant in the file header
	//

	//deadtime corrections to raw data
	//	deadTime = DetectorDeadtime(raw_text[3],raw_text[9],dateAndTimeStr=raw_text[1],dtime=raw_reals[48])		//pick the correct detector deadtime, switch on date too
	deadTime = getDetectorDeadtime_Value("RAW") // TODO -- returns a HARD WIRED value of 1e-6!!!
	itim     = getCount_time("RAW")
	cntrate  = sum(raw_data, -Inf, Inf) / itim  //080802 use data sum, rather than scaler value
	dscale   = 1 / (1 - deadTime * cntrate)

	// dead time correction on all other RAW data, including NCNR
	raw_data     *= dscale
	raw_data_err *= dscale

	//update totals by adding RAW values to the local ones (write to work header at end of function)
	total_mon += getControlMonitorCount("RAW")

	total_det += dscale * getDetector_counts("RAW")

	//	total_trn += raw_reals[39]
	total_rtime   += getCount_time("RAW")
	total_numruns += 1

	//do the beamcenter shifting if there is a mismatch
	//and then add the two data sets together, changing "data" since it is the workfile data
	xshift = getDet_beam_center_x("RAW") - wrk_beamx
	yshift = getDet_beam_center_x("RAW") - wrk_beamy

	if((xshift != 0) || (yshift != 0))
		DoAlert 1, "Do you want to ignore the beam center mismatch?"
		if(V_flag == 1)
			xshift = 0
			yshift = 0
		endif
	endif

	if((xshift == 0) && (yshift == 0)) //no shift, just add them
		data         += raw_data                               //deadtime correction has already been done to the raw data
		dest_data_err = sqrt(dest_data_err^2 + raw_data_err^2) // error of the sum
	else
		//shift the beamcenter, then add
		Make/O/N=1 $(destPath + ":noadd") //needed to get noadd condition back from ShiftSum()
		WAVE noadd = $(destPath + ":noadd")
		variable sh_sum //returned value
		Print "BEAM CENTER MISMATCH - - BEAM CENTER WILL BE SHIFTED TO THIS FILE'S VALUE"
		//ii,jj are just indices here, not physical locations - so [0,127] is fine
		ii = 0
		do
			jj = 0
			do
				//get the contribution of shifted data
				sh_sum = ShiftSum(data, ii, jj, xshift, yshift, noadd)
				if(noadd[0])
					//don't do anything to data[][]
				else
					//add the raw_data + shifted sum (and do the deadtime correction on both)
					data[ii][jj]         += (raw_data[ii][jj] + sh_sum)                            //do the deadtime correction on RAW here
					dest_data_err[ii][jj] = sqrt(dest_data_err[ii][jj]^2 + raw_data_err[ii][jj]^2) // error of the sum
				endif
				jj += 1
			while(jj < pixelsY)
			ii += 1
		while(ii < pixelsX)
	endif

	//scale the data to the default montor counts
	scale          = defmon / total_mon
	data          *= scale
	dest_data_err *= scale

	//all is done, except for the bookkeeping of updating the header info in the work folder
	//	textread[1] = date() + " " + time()		//date + time stamp
	putBeamMonNormSaved_count(newType, total_mon) //save the true monitor count
	putControlMonitorCount(newType, defmon) //monitor ct = defmon
	putCollectionTime(newType, total_rtime) // total counting time
	putDetector_counts(newType, scale * total_det) //scaled detector counts

	//Add the added raw filename to the list of files in the workfile
	string   newfile                   = ";" + getFileNameFromFolder("RAW")
	SVAR     oldList                   = $(destPath + ":fileList")
	string/G $(destPath + ":fileList") = oldList + newfile

	//reset the current displaytype to "newtype"
	string/G root:myGlobals:gDataDisplayType = newType

	//return to root folder (redundant)
	SetDataFolder root:

	return (0)
End

//will copy the current contents of the RAW folder to the newType work folder
//and do the geometric corrections and normalization to monitor counts
//(the function Add_Raw_to_work(type) adds multiple runs together)
//
//the current display type is updated to newType (global)
//
Function Raw_to_work(string newType)

	variable deadTime, defmon, total_mon, total_det, total_trn, total_numruns, total_rtime
	variable ii, jj, itim, cntrate, dscale, scale, uscale, wrk_beamx, wrk_beamy
	string destPath

	// 08/01 detector constants are now returned from a function, based on the detector type and beamline
	//	dt_ornl = 3.4e-6		//deadtime of Ordela detectors	as of 30-AUG-99
	//	dt_ill=3.0e-6			//Cerca detector deadtime constant as of 30-AUG-99
	defmon = 1e8 //default monitor counts

	//initialize values before normalization
	total_mon     = 0
	total_det     = 0
	total_trn     = 0
	total_numruns = 0
	total_rtime   = 0

	//Not adding multiple runs, so wipe out the old contents of the work folder and
	// replace with the contents of raw

	destPath = "root:Packages:NIST:" + newType

	//copy from current dir (RAW) to work, defined by newType
	CopyHDFToWorkFolder("RAW", newType)

	// now work with the waves from the destination folder.

	// apply corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	// start with the DIV correction, before conversion to mm
	// then do all of the other corrections, order doesn't matter.
	// rescaling to default monitor counts however, must be LAST.

	variable pixelsX = getDet_pixel_num_x(newType)
	variable pixelsY = getDet_pixel_num_y(newType)

	variable/G $(destPath + ":gIsLogscale") = 0 //overwite flag in newType folder, data converted (above) to linear scale

	WAVE data     = getDetectorDataW(newType) // these wave references point to the EXISTING work data
	WAVE data_err = getDetectorDataErrW(newType)

	string/G $(destPath + ":fileList") = getFileNameFromFolder(newType) //a list of names of the files in the work file (1)		//02JUL13

	//apply nonlinear, Jacobian corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR     doEfficiency = root:Packages:NIST:gDoDetectorEffCorr
	NVAR     gDoTrans     = root:Packages:NIST:gDoTransmissionCorr
	variable doTrans      = gDoTrans
	if(cmpstr("BGD", newtype) == 0)
		doTrans = 0 //skip the trans correction for the BGD file but don't change the value of the global
	endif

	DetCorr(data, data_err, newType, doEfficiency, doTrans) //the parameters are waves, and will be changed by the function

	// TODO -- the dead time correction will be different for the tube detectors,
	// and for the Ordela will be accessed differently - with the dt constant in the file header
	//

	//deadtime corrections to raw data
	//	deadTime = DetectorDeadtime(raw_text[3],raw_text[9],dateAndTimeStr=raw_text[1],dtime=raw_reals[48])		//pick the correct detector deadtime, switch on date too
	deadTime = getDetectorDeadtime_Value(newType) //
	itim     = getCount_time(newType)
	cntrate  = sum(data, -Inf, Inf) / itim        //use sum of detector counts rather than scaler value
	dscale   = 1 / (1 - deadTime * cntrate)

	// NO xcenter,ycenter shifting is done - this is the first (and only) file in the work folder

	//only ONE data file- no addition of multiple runs in this function, so data is
	//just simply corrected for deadtime.

	data     *= dscale //deadtime correction for everyone else, including NCNR
	data_err *= dscale

	//update totals to put in the work header (at the end of the function)
	total_mon += getControlMonitorCount(newType)

	total_det += dscale * getDetector_counts(newType)

	total_rtime   += getCount_time(newType)
	total_numruns += 1

	//scale the data to the default montor counts
	scale     = defmon / total_mon
	data     *= scale
	data_err *= scale //assumes total monitor count is so large there is essentially no error

	//all is done, except for the bookkeeping, updating the header information in the work folder
	//	textread[1] = date() + " " + time()		//date + time stamp
	putBeamMonNormSaved_count(newType, total_mon) //save the true monitor count
	putControlMonitorCount(newType, defmon) //monitor ct = defmon
	putCollectionTime(newType, total_rtime) // total counting time
	putDetector_counts(newType, scale * total_det) //scaled detector counts

	//reset the current displaytype to "newtype"
	string/G root:myGlobals:gDataDisplayType = newType

	//return to root folder (redundant)
	SetDataFolder root:

	return (0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Raw_to_Work_NoNorm(string type)

	putBeamMonNormSaved_count("RAW", 1) //true monitor counts, still in raw, set to 1
	Raw_to_work(type)
	//data is now in "type" folder
	WAVE data     = getDetectorDataW(type)
	WAVE data_err = getDetectorDataErrW(type)

	variable norm_mon, tot_mon, scale

	norm_mon = getControlMonitorCount(type)    //should be 1e8
	tot_mon  = getBeamMonNormSaved_count(type) //should be 1
	scale    = norm_mon / tot_mon

	data     /= scale //unscale the data
	data_err /= scale

	return (0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Add_Raw_to_Work_NoNorm(string type)

	putBeamMonNormSaved_count("RAW", 1) //true monitor counts, still in raw, set to 1
	Add_Raw_to_work(type)
	//data is now in "type" folder
	WAVE data     = getDetectorDataW(type)
	WAVE data_err = getDetectorDataErrW(type)

	variable norm_mon, tot_mon, scale

	norm_mon = getControlMonitorCount(type)    //should be 1e8
	tot_mon  = getBeamMonNormSaved_count(type) //should be 1
	scale    = norm_mon / tot_mon

	data     /= scale //unscale the data
	data_err /= scale

	return (0)
End

//performs solid angle and non-linear detector corrections to raw data as it is "added" to a work folder
//function is called by Raw_to_work() and Add_raw_to_work() functions
//works on the actual data array, assumes that is is already on LINEAR scale
//
//fname = folder with the data
Function DetCorr(WAVE data, WAVE data_err, string fname, variable doEfficiency, variable doTrans)

	variable xcenter, ycenter, x0, y0, sx, sx3, sy, sy3, xx0, yy0
	variable ii, jj, dtdist, dtdis2
	variable xi, xd, yd, rad, ratio, domega, xy
	variable lambda, trans, trans_err, lat_err, tmp_err, lat_corr

	//	Print "...doing jacobian and non-linear corrections"

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	//set up values to send to auxiliary trig functions
	xcenter = pixelsX / 2 + 0.5 // == 64.5 for 128x128 Ordela
	ycenter = pixelsY / 2 + 0.5 // == 64.5 for 128x128 Ordela

	x0 = getDet_beam_center_x(fname)
	y0 = getDet_beam_center_y(fname)

	//	WAVE calX=getDet_cal_x(fname)
	//	WAVE calY=getDet_cal_y(fname)
	sx  = getDet_x_pixel_size(fname)
	sx3 = 10000 // nonlinear correction - (10,000 turns correction "off")
	sy  = getDet_y_pixel_size(fname)
	sy3 = 10000

	dtdist = 10 * getDet_Distance(fname) //sdd in mm
	dtdis2 = dtdist^2

	lambda    = getWavelength(fname)
	trans     = getSampleTransmission(fname)
	trans_err = getSampleTransError(fname) //new, March 2011

	xx0 = dc_fx(x0, sx, sx3, xcenter)
	yy0 = dc_fy(y0, sy, sy3, ycenter)

	//waves to contain repeated function calls
	Make/O/N=(pixelsX) fyy, xx, yy //Assumes square detector !!!
	ii = 0
	do
		xi      = ii
		fyy[ii] = dc_fy(ii + 1, sy, sy3, ycenter)
		xx[ii]  = dc_fxn(ii + 1, sx, sx3, xcenter)
		yy[ii]  = dc_fym(ii + 1, sy, sy3, ycenter)
		ii     += 1
	while(ii < pixelsX)

	Make/O/N=(pixelsX, pixelsY) SolidAngle // testing only

	ii = 0
	do
		xi = ii
		xd = dc_fx(ii + 1, sx, sx3, xcenter) - xx0
		jj = 0
		do
			yd = fyy[jj] - yy0
			//rad is the distance of pixel ij from the sample
			//domega is the ratio of the solid angle of pixel ij versus center pixel
			// product xy = 1 for a detector with a linear spatial response (modern Ordela)
			// solid angle calculated, dW^3 >=1, so multiply data to raise measured values to correct values.
			rad    = sqrt(dtdis2 + xd^2 + yd^2)
			domega = rad / dtdist
			ratio  = domega^3
			xy     = xx[ii] * yy[jj]

			data[ii][jj] *= xy * ratio

			solidAngle[ii][jj] = xy * ratio //testing only
			data_err[ii][jj]  *= xy * ratio //error propagation assumes that SA and Jacobian are exact, so simply scale error

			// correction factor for detector efficiency JGB memo det_eff_cor2.doc 3/20/07
			// correction inserted 11/2007 SRK
			// large angle detector efficiency is >= 1 and will "bump up" the measured value at the highest angles
			// so divide here to get the correct answer (5/22/08 SRK)
			if(doEfficiency)

				data[ii][jj]     /= DetEffCorr(lambda, dtdist, xd, yd)
				data_err[ii][jj] /= DetEffCorr(lambda, dtdist, xd, yd)
				//				solidAngle[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)		//testing only
			endif

			// large angle transmission calculation is <= 1 and will "bump down" the measured value at the highest angles
			// so divide here to get the correct answer
			if(doTrans)

				if(trans < 0.1 && ii == 0 && jj == 0)
					Print "***transmission is less than 0.1*** and is a significant correction"
				endif

				if(trans == 0)
					if(ii == 0 && jj == 0)
						Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
					endif
					trans = 1
				endif

				// pass in the transmission error, and the error in the correction is returned as the last parameter
				lat_corr      = LargeAngleTransmissionCorr(trans, dtdist, xd, yd, trans_err, lat_err) //moved from 1D avg SRK 11/2007
				data[ii][jj] /= lat_corr                                                              //divide by the correction factor
				//
				//
				//
				// relative errors add in quadrature
				tmp_err = (data_err[ii][jj] / lat_corr)^2 + (lat_err / lat_corr)^2 * data[ii][jj] * data[ii][jj] / lat_corr^2
				tmp_err = sqrt(tmp_err)

				data_err[ii][jj] = tmp_err

				//				solidAngle[ii][jj] = lat_err

				//solidAngle[ii][jj] = LargeAngleTransmissionCorr(trans,dtdist,xd,yd)		//testing only
			endif

			jj += 1
		while(jj < pixelsX)
		ii += 1
	while(ii < pixelsX)

	//clean up waves
	Killwaves/Z fyy, xx, yy

	return (0)
End

//trig function used by DetCorr()
Function dc_fx(variable x, variable sx, variable sx3, variable xcenter)

	variable result

	result = sx3 * tan((x - xcenter) * sx / sx3)
	return (result)
End

//trig function used by DetCorr()
Function dc_fy(variable y, variable sy, variable sy3, variable ycenter)

	variable result

	result = sy3 * tan((y - ycenter) * sy / sy3)
	return (result)
End

//trig function used by DetCorr()
Function dc_fxn(variable x, variable sx, variable sx3, variable xcenter)

	variable result

	result = (cos((x - xcenter) * sx / sx3))^2
	return (result)
End

//trig function used by DetCorr()
Function dc_fym(variable y, variable sy, variable sy3, variable ycenter)

	variable result

	result = (cos((y - ycenter) * sy / sy3))^2
	return (result)
End

//distances passed in are in mm
// dtdist is SDD
// xd and yd are distances from the beam center to the current pixel
//
Function DetEffCorr(variable lambda, variable dtdist, variable xd, variable yd)

	variable theta, cosT, ff, stAl, stHe

	theta = atan((sqrt(xd^2 + yd^2)) / dtdist)
	cosT  = cos(theta)

	stAl = 0.00967 * lambda * 0.8 //dimensionless, constants from JGB memo
	stHe = 0.146 * lambda * 2.5

	ff = exp(-stAl / cosT) * (1 - exp(-stHe / cosT)) / (exp(-stAl) * (1 - exp(-stHe)))

	return (ff)
End

// DIVIDE the intensity by this correction to get the right answer
Function LargeAngleTransmissionCorr(variable trans, variable dtdist, variable xd, variable yd, variable trans_err, variable &err)

	//angle dependent transmission correction
	variable uval, arg, cos_th, correction, theta

	////this section is the trans_correct() VAX routine
	//	if(trans<0.1)
	//		Print "***transmission is less than 0.1*** and is a significant correction"
	//	endif
	//	if(trans==0)
	//		Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
	//		trans = 1
	//	endif

	theta = atan((sqrt(xd^2 + yd^2)) / dtdist) //theta at the input pixel

	//optical thickness
	uval   = -ln(trans) //use natural logarithm
	cos_th = cos(theta)
	arg    = (1 - cos_th) / cos_th

	// a Taylor series around uval*arg=0 only needs about 4 terms for very good accuracy
	// 			correction= 1 - 0.5*uval*arg + (uval*arg)^2/6 - (uval*arg)^3/24 + (uval*arg)^4/120
	// OR
	if((uval < 0.01) || (cos_th > 0.99))
		//small arg, approx correction
		correction = 1 - 0.5 * uval * arg
	else
		//large arg, exact correction
		correction = (1 - exp(-uval * arg)) / (uval * arg)
	endif

	variable tmp

	if(trans == 1)
		err = 0 //no correction, no error
	else
		//sigT, calculated from the Taylor expansion
		tmp  = (1 / trans) * (arg / 2 - arg^2 / 3 * uval + arg^3 / 8 * uval^2 - arg^4 / 30 * uval^3)
		tmp *= tmp
		tmp *= trans_err^2
		tmp  = sqrt(tmp) //sigT

		err = tmp
	endif

	//	Printf "trans error = %g\r",trans_err
	//	Printf "correction = %g +/- %g\r", correction, err

	//end of transmission/pathlength correction

	return (correction)
End

//******************
//direct port of the FORTRAN code for calculating the weighted
//shifted element to add when beam centers in data headers do not match
//(indices updated to [0,n-1] indexing rather than (1,n) of fortran
//
// as of IGOR 4.0, could be rewritten to pass-by-reference noadd, rather than wave, but the function
// is so little used, it's not worth the time
Function ShiftSum(WAVE DATA, variable ip, variable jp, variable XSHIFT, variable YSHIFT, WAVE noadd)

	//
	//       COMPUTE WEIGHTED OFFSET ELEMENT SUM FOR USE IN SANS DATA
	//       ANALYSIS MODULES.
	//
	// "data" wave passed in is the current contents of the work file
	// sum_val is the return value of the function
	// "noadd" is passed back to the calling function as a one-point wave

	variable XDELTA, YDELTA, kk, II, JJ, ISHIFT, JSHIFT, sum_val
	Make/O/N=4 iii, jjj, a

	//       -----------------------------------------------------------------

	ISHIFT = trunc(XSHIFT)   // INTEGER PART, trunc gives int closest in dierction of zero
	XDELTA = XSHIFT - ISHIFT //FRACTIONAL PART.
	JSHIFT = trunc(YSHIFT)
	YDELTA = YSHIFT - JSHIFT
	II     = ip + ISHIFT
	JJ     = jp + JSHIFT

	//       SHIFT IS DEFINED AS A VECTOR ANCHORED AT THE STATIONARY CENTER
	//       AND POINTING TO THE MOVABLE CENTER.  THE MOVABLE FIELD IS THUS
	//       ACTUALLY MOVED BY -SHIFT.
	//
	if((XDELTA >= 0) && (YDELTA >= 0)) // CASE I ---- "%&" is "and"
		III[0] = II
		JJJ[0] = JJ
		III[1] = II + 1
		JJJ[1] = JJ
		III[2] = II + 1
		JJJ[2] = JJ + 1
		III[3] = II
		JJJ[3] = JJ + 1
		A[0]   = (1. - XDELTA) * (1. - YDELTA)
		A[1]   = XDELTA * (1. - YDELTA)
		A[2]   = XDELTA * YDELTA
		A[3]   = (1. - XDELTA) * YDELTA
	endif
	if((XDELTA >= 0) && (YDELTA < 0)) // CASE II.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ - 1
		III[2] = II + 1
		JJJ[2] = JJ - 1
		III[3] = II + 1
		JJJ[3] = JJ
		A[0]   = (1. - XDELTA) * (1. + YDELTA)
		A[1]   = (1. - XDELTA) * (-YDELTA)
		A[2]   = XDELTA * (-YDELTA)
		A[3]   = XDELTA * (1. + YDELTA)
	endif
	if((XDELTA < 0) && (YDELTA >= 0)) // CASE III.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ + 1
		III[2] = II - 1
		JJJ[2] = JJ + 1
		III[3] = II - 1
		JJJ[3] = JJ
		A[0]   = (1. + XDELTA) * (1 - YDELTA)
		A[1]   = (1. + XDELTA) * YDELTA
		A[2]   = -XDELTA * YDELTA
		A[3]   = -XDELTA * (1. - YDELTA)
	endif
	if((XDELTA < 0) && (YDELTA < 0)) //CASE IV.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II - 1
		JJJ[1] = JJ
		III[2] = II - 1
		JJJ[2] = JJ - 1
		III[3] = II
		JJJ[3] = JJ - 1
		A[0]   = (1. + XDELTA) * (1. + YDELTA)
		A[1]   = -XDELTA * (1. + YDELTA)
		A[2]   = (-XDELTA) * (-YDELTA)
		A[3]   = (1. + XDELTA) * (-YDELTA)
	endif

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	//check to see if iii[0],jjj[0] are valid detector elements, in [0,127]
	//if not set noadd[0] to 1, to let calling routine know NOT to add
	//        CALL TESTIJ(III(1),JJJ(1),OKIJ)
	NOADD[0] = 0
	if((iii[0] < 0) || (iii[0] > (pixelsX - 1)))
		noadd[0] = 1
	endif
	if((jjj[0] < 0) || (jjj[0] > (pixelsY - 1)))
		noadd[0] = 1
	endif

	sum_val = 0.
	kk      = 0
	do
		if(JJJ[kk] == pixelsX)
			//do nothing
		else
			sum_val += A[kk] * DATA[III[kk]][JJJ[kk]]
		endif
		kk += 1
	while(kk < 4)

	//clean up waves
	KillWaves/Z iii, jjj, a

	return (sum_val)

End //function ShiftSum

