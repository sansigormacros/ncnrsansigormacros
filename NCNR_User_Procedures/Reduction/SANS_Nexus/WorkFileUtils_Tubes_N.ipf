#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
//
// SEP 2022
//
//
//
// Work file (folder) operations that work with the tube detector panel on the
// 10m SANS instrument. If 30m insturments eventually convert to tubes, this set of corrections
// can be used.
//
// This set of procedures has been tested and does work if the Ordela data is converted to "fake"
//  tubes with appropriate parameters.
//
// There are some simple switches for the corrrections that are different for the two different
//  detector types. Search for the string constant ksDetType

//
// Loading of the data is the same for every HDF5/Nexus file. It's all loaded.
// Reading/Writing is "common", but care must be taken to use only R/W functions that
// correspond to actual fields that are in the data files.
//
// The functions here are for convering raw data to a work folder, adding raw data files (as work files)
//
//

//testing procedure, not called anymore
Proc Add_to_Workfile(type, add)
	String type,add
	Prompt type,"WORK data type",popup,"SAM;EMP;BGD"
	Prompt add,"Add to current WORK contents?",popup,"No;Yes"
	
	//macro will take whatever is in RAW folder and "ADD" it to the folder specified
	//in the popup menu
	
	//"add" = yes/no, don't add to previous runs
	//switch here - two separate functions to avoid (my) confusion
	Variable err
	if(cmpstr(add,"No")==0)
		//don't add to prev work contents, copy RAW contents to work and convert
		err = Raw_to_work_for_Tubes(type)
	else
		//yes, add RAW to the current work folder contents
		err = Add_raw_to_work_for_Tubes(type)
	endif
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	fRawWindowHook()
	
End

//will "ADD" the current contents of the RAW folder to the newType work folder
//and will ADD the RAW contents to the existing content of the newType folder
// - used when adding multiple runs together
//(the function Raw_to_work(type) makes a fresh workfile)
//
// 2nd file is temporarily converted toa a workfile (ADJ), then added
//
//the current display type is updated to newType (global)
Function Add_raw_to_work_for_Tubes(newType)
	String newType
	
	// NEW OCT 2014
	// this corrects for adding raw data files with different attenuation	
	// does nothing if the attenuation of RAW and destination are the same
	NVAR doAdjustRAW_Atten = root:Packages:NIST:gDoAdjustRAW_Atten
	if(doAdjustRAW_Atten)
		Adjust_RAW_Attenuation(newType)
	endif
	
	String destPath=""
	
	// if the desired workfile doesn't exist, let the user know, and just make a new one
	// root:Packages:NIST:RAW:entry:instrument:detector:data
	if(WaveExists($("root:Packages:NIST:" + newType + ":entry:instrument:detector:data")) == 0)
		Print "There is no old work file to add to - a new one will be created"
		//call Raw_to_work(), then return from this function
		Raw_to_Work_for_Tubes(newType)
		Return(0)		//does not generate an error - a single file was converted to work.newtype
	Endif
	

	// convert the RAW data to a WORK file.
	// this will do all of the necessary corrections to the data
	// put this in some separate work folder that can be cleaned out at the end (ADJ)
	String tmpType="ADJ"
	
	//this step removes the read noise from the back so that neither added file will have this constant
	Raw_to_Work_for_Tubes(tmpType)	


/////////////////
//fields that need to be added together
// entry block
	// collection_time  		getCollectionTime(fname)		putCollectionTime(fname,val)

// instrument block
	// beam_monitor_norm
		// data (this will be 1e8)				getBeamMonNormData(fname)		putBeamMonNorm_data(fname,val)
		// saved_count (this is the original monitor count)  getBeamMonNormSaved_count(fname)		putBeamMonNormSaved_count(fname,val)

	// for each detector
	// data		getDetectorDataW(fname,detStr)
	// integrated_count		getDet_IntegratedCount(fname,detStr)   putDet_IntegratedCount(fname,detStr,val)
	// linear_data		 getDetectorLinearDataW(fname,detStr)
	// RECALCULATE (or add properly) linear_data_error		getDetectorDataErrW(fname,detStr)


// control block (these may not actually be used?)
	// count_time				getCount_time(fname)						putCount_time(fname,val)
	// detector_counts		getDetector_counts(fname)				putDetector_counts(fname,val)
	// monitor_counts		getControlMonitorCount(fname)		putControlMonitorCount(fname,val)

// sample block - nothing
// reduction block - nothing
// user block - nothing

// ?? need to add the file name to a list of what was actually added - so it will be saved with I(q)
//
////////////////////


	//now make references to data in newType folder
	DestPath="root:Packages:NIST:"+newType	
	
	
	
	WAVE data=getDetectorDataW(newType)			// these wave references point to the EXISTING work data
	WAVE dest_data_err=getDetectorDataErrW(newType)			// these wave references point to the EXISTING work data
	

	Variable saved_mon_dest,scale_dest,saved_mon_tmp,scale_tmp
	Variable collection_time_dest,collection_time_tmp,count_time_dest,count_time_tmp
	Variable detCount_dest,detCount_tmp,det_integrated_ct_dest,det_integrated_ct_tmp
	Variable ii,new_scale,defMon
	
	defMon=1e8			//default monitor counts
	
	
	// find the scaling factors, one for each folder
	saved_mon_dest = getBeamMonNormSaved_count(newType)
	scale_dest = saved_mon_dest/defMon		//un-scaling factor
	
	saved_mon_tmp = getBeamMonNormSaved_count(tmpType)
	scale_tmp = saved_mon_tmp/defMon			//un-scaling factor

	new_scale = defMon / (saved_mon_dest+saved_mon_tmp)
	
	
	// get the count time for each (two locations)
	collection_time_dest = getCollectionTime(newType)
	collection_time_tmp = getCollectionTime(tmpType)
	
	count_time_dest = getCount_time(newType)
	count_time_tmp = getCount_time(tmpType)
	
	detCount_dest = getDetector_counts(newType)
	detCount_tmp = getDetector_counts(tmpType)

// update the fields that are not in the detector blocks
// in entry
	putCollectionTime(newType,collection_time_dest+collection_time_tmp)


	putCount_time(newType,count_time_dest+count_time_tmp)
	putDetector_counts(newType,detCount_dest+detCount_tmp)
//	putBeamMonNorm_data(newType,saved_mon_dest+saved_mon_tmp)		//NO -- real total mon ct is saved below
	putBeamMonNorm_data(newType,defmon)			// added files will still be scaled to defMon

// (DONE)
// the new, unscaled monitor count was written to the control block, but it needs to be 
// written to the BeamMonNormSaved_count field instead, since this is where I read it from.
// - so this worked in the past for adding two files, but fails on 3+
// x- write to the NormSaved_count field...
	putBeamMonNormSaved_count(newType,saved_mon_dest+saved_mon_tmp)			// save the true count



// now adjust the data

	Wave data_dest = getDetectorDataW(newType)
	Wave data_err_dest = getDetectorDataErrW(newType)
//	Wave linear_data_dest = getDetectorLinearDataW(newType)
	det_integrated_ct_dest = getDet_IntegratedCount(newType)

	Wave data_tmp = getDetectorDataW(tmpType)
	Wave data_err_tmp = getDetectorDataErrW(tmpType)
//	Wave linear_data_tmp = getDetectorLinearDataW(tmpType)
	det_integrated_ct_tmp = getDet_IntegratedCount(tmpType)
	
	// unscale the data arrays
	data_dest *= scale_dest
	data_err_dest *= scale_dest
//	linear_data_dest *= scale_dest
	
	data_tmp *= scale_tmp
	data_err_tmp *= scale_tmp
//	linear_data_tmp *= scale_tmp

//			
	// add them together, the dest is a wave so it is automatically changed in the "dest" folder
	putDet_IntegratedCount(tmpType,sum(data_dest)+sum(data_tmp))		// adds the unscaled data sums
//		putDet_IntegratedCount(tmpType,detStr,det_integrated_ct_dest+det_integrated_ct_tmp)		// wrong for "B", may be wrong for ML
	data_dest += data_tmp
	data_err_dest = sqrt(data_err_dest^2 + data_err_tmp^2)		// add in quadrature
//	linear_data_dest += linear_data_tmp
	
	// now rescale the data_dest to the summed monitor counts
	data_dest *= new_scale
	data_err_dest *= new_scale
//	linear_data_dest *= new_scale

	
	//Add the added raw filename to the list of files in the workfile
	String newfile = ";" + getFileNameFromFolder("RAW")
	SVAR oldList = $(destPath + ":fileList")
	String/G $(destPath + ":fileList") = oldList + newfile
	
	//reset the current displaytype to "newtype"
	String/G root:myGlobals:gDataDisplayType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End


//
// this is the main procedure to get raw data to a corrected work file
//
// there are switches in place to use code proper for Tubes or Ordela as needed
//
//
//
//will copy the current contents of the RAW folder to the newType work folder
//and do the geometric corrections and normalization to monitor counts
//(the function Add_Raw_to_work(type) adds multiple runs together)
//
//the current display type is updated to newType (global)
//
Function Raw_to_work_for_Tubes(newType)
	String newType
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale,wrk_beamx,wrk_beamy
	String destPath
	
	String fname = newType

	
// 08/01 detector constants are now returned from a function, based on the detector type and beamline
//	dt_ornl = 3.4e-6		//deadtime of Ordela detectors	as of 30-AUG-99
//	dt_ill=3.0e-6			//Cerca detector deadtime constant as of 30-AUG-99
	defmon=1e8			//default monitor counts
	
	//initialize values before normalization
	total_mon=0
	total_det=0
	total_trn=0
	total_numruns=0
	total_rtime=0
	
	//Not adding multiple runs, so wipe out the old contents of the work folder and 
	// replace with the contents of raw

	destPath = "root:Packages:NIST:" + newType
	
	//copy from current dir (RAW) to work, defined by newType
	CopyHDFToWorkFolder("RAW",newType)
	
	// now work with the waves from the destination folder.	
	
	// apply corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	// start with the DIV correction, before conversion to mm
	// then do all of the other corrections, order doesn't matter.
	// rescaling to default monitor counts however, must be LAST.

	
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable pixelsX = getDet_pixel_num_x(newType)
	Variable pixelsY = getDet_pixel_num_y(newType)
	
	Variable/G $(destPath + ":gIsLogscale")=0			//overwite flag in newType folder, data converted (above) to linear scale


	WAVE data=getDetectorDataW(newType)			// these wave references point to the EXISTING work data
//	WAVE data_copy=$(destPath +":data")			// these wave references point to the EXISTING work data
	WAVE data_err=getDetectorDataErrW(newType)	
	
	String/G $(destPath + ":fileList") = getFileNameFromFolder(newType) 			//a list of names of the files in the work file (1)		//02JUL13

	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR gDoTrans = root:Packages:NIST:gDoTransmissionCorr
	Variable doTrans = gDoTrans
	if(cmpstr("BGD",newtype) == 0)
		doTrans = 0		//skip the trans correction for the BGD file but don't change the value of the global
	endif
	
	Variable error = 0
	
	// (1) DIV correction
	NVAR gDoDIVCor = root:Packages:NIST:gDoDIVCor
	if (gDoDIVCor == 1)
		// need extra check here for file existence
		// if not in DIV folder, load.
		// if unable to load, skip correction and report error (Alert?) (Ask to Load?)
		Print "Doing DIV correction"// for "+ detStr

		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)
		
		error = DIVCorrection(w,w_err,newType)
		if(error)
			Print "DIV correction NOT DONE -- DIV files do not exist"		// an error
		endif
	else
		Print "DIV correction NOT DONE"		// not an error since correction was unchecked
	endif
	
	
	// (2) non-linear correction	
	// (DONE):
	// x- document what is generated here:
	//    **in each detector folder: data_realDistX and data_realDistY (2D waves of the [mm] position of each pixel)
	// x- these spatial calculations ARE DONE as the RAW data is loaded. It allows the RAW
	//    data to be properly displayed, but without all of the (complete) set of detector corrections
	// * the corrected distances are calculated into arrays, but nothing is done with them yet
	// * there is enough information now to calculate the q-arrays, so it is done now
	// - other corrections may modify the data, this calculation does NOT modify the data
	NVAR gDoNonLinearCor = root:Packages:NIST:gDoNonLinearCor
	// generate a distance matrix for each of the detectors
	if (gDoNonLinearCor == 1)
		Print "Doing Non-linear correction"
			Wave w = getDetectorDataW(fname)
//			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_calib = getDetTube_spatialCalib(fname)
			Variable tube_width = getDet_tubeWidth(fname)
			NonLinearCorrection(fname,w,w_calib,tube_width,destPath)

			//(2.4) Convert the beam center values from pixels to mm
			//
				// (DONE)
				// x- the beam center value in mm needs to be present - it is used in calculation of Qvalues
				// x- but having both the same is wrong...
				// x- the pixel value is needed for display of the panels
				if(kBCTR_CM)
//					//V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
//					//
//	
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
//					WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
//					WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
//					x_mm[0] = V_getDet_beam_center_x(fname,detStr) * 10 		// convert cm to mm
//					y_mm[0] = V_getDet_beam_center_y(fname,detStr) * 10 		// convert cm to mm
//					
//					// (DONE):::
//				// now I need to convert the beam center in mm to pixels
//				// and have some rational place to look for it...
//					V_ConvertBeamCtr_to_pix(fname,detStr,destPath)
				else
					// beam center is in pixels, so use the old routine
					ConvertBeamCtrPix_to_mm(fname,destPath)
				endif		
							
			// (2.5) Calculate the q-values
			// calculating q-values can't be done unless the non-linear corrections are calculated
			// so go ahead and put it in this loop.
			// x- distances/zero location/ etc. must be clearly documented for each detector
			//	** this assumes that NonLinearCorrection() has been run to generate data_RealDistX and Y
			// ** this routine Makes the waves QTot, qx, qy, qz in each detector folder.
			//
			Detector_CalcQVals(fname,destPath)
					
	else
		Print "Non-linear correction NOT DONE"
	endif

	// (3) dead time correction
	// DONE:
	// x- test for correct operation
	// x- this DOES alter the data
	// x- verify the error propagation
	//
	// rescaling the total detector counts is not done here. the number of 
	// detector counts is increased here my directly multiplying the data array.
	// in step (8), when the monitor normalization is done, the integrated count 
	// is updated by summing the actual counts in the data wave directly
	// and replacing the value of the integrated counts (May 2022)
	//
	//
	// *** there are different corrections for Ordela and Tubes ***
	//
	Variable countRate,ctTime
	NVAR gDoDeadTimeCor = root:Packages:NIST:gDoDeadTimeCor
	if (gDoDeadTimeCor == 1)
		Print "Doing DeadTime correction"
		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)
		ctTime = getCount_time(fname)

		if(cmpstr(ksDetType,"Ordela") != 0)
			// not a match, it's tubes
			
			// do the corrections for tube panels
			Wave w_dt = getDetector_deadtime(fname)
			DeadTimeCorrectionTubes(w,w_err,w_dt,ctTime)
		
		else
			// Ordela - only a single DT value

			// not correct, but get the "fake" Ordela tubes dt wave, and read only a single value
			//		
			Wave w_dt = getDetector_deadtime(fname)
			Variable dt_val = w_dt[0][0]
			DeadTimeCorrectionOrdela(w,w_err,dt_val,ctTime)
		
		endif
		
	else
		Print "Dead Time correction NOT DONE"
	endif	
	

	// (4) solid angle correction
	//  -- this currently calculates the correction factor AND applies it to the data
	//  -- as a result, the data values are very large since they are divided by a very small
	//     solid angle per pixel. But all of the count values are now on the basis of 
	//    counts/(solid angle) --- meaning that they can all be binned together for I(q)
	//    -and- - this is taken into account for absolute scaling (this part is already done)
	//
	// *** there are different corrections for Ordela and Tubes ***
	//
	NVAR gDoSolidAngleCor = root:Packages:NIST:gDoSolidAngleCor
	NVAR/Z gDo_OLD_SolidAngleCor = root:Packages:NIST:gDo_OLD_SolidAngleCor
	// for older experiments, this won't exist, so generate it and default to zero
	// so the old calculation is not done
	if(NVAR_Exists(gDo_OLD_SolidAngleCor)==0)
		Variable/G root:Packages:NIST:gDo_OLD_SolidAngleCor=0
		NVAR/Z gDo_OLD_SolidAngleCor = root:Packages:NIST:gDo_OLD_SolidAngleCor
	endif
	if (gDoSolidAngleCor == 1)
		Print "Doing Solid Angle correction"// for "+ detStr
			

		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)


		if(cmpstr(ksDetType,"Ordela") != 0)
			// not a match, it's tubes
		
			if(gDo_OLD_SolidAngleCor == 0)
				SolidAngleCorrection(w,w_err,fname,destPath)
			else
				// for testing ONLY -- the cos^3 correction is incorrect for tubes, and the normal
				// function call above	 correctly handles either high-res grid or tubes. This COS3 function
				// will incorrectly treat tubes as a grid	
				//				Print "TESTING -- using incorrect COS^3 solid angle !"		
	//			SolidAngleCorrection_COS3(w,w_err,fname,destPath)
			endif
					
				
			if(gDo_OLD_SolidAngleCor == 1)
				DoAlert 0,"TESTING -- using incorrect COS^3 solid angle !"		
			endif
			
		else
			// it's Ordela, so use the "old" COS3 correction, which is the right thing to
			// do for Ordela
			SolidAngleCorrection_COS3(w,w_err,fname,destPath)
		endif

	else
		Print "Solid Angle correction NOT DONE"
	endif	
	

	// (5) angle-dependent tube shadowing + detection efficiency
	//  done together as one correction
	//
	// (DONE):
	// x- this correction accounts for the efficiency of the tubes
	//		(depends on angle and wavelength)
	//    and the shadowing, only happens at large angles (> 23.7 deg, lateral to tubes)
	//
	// TubeEfficiencyShadowCorr(w,w_err,fname,destPath)
	//
	// *** there are different corrections for Ordela and Tubes ***
	//
	NVAR gDoTubeShadowCor = root:Packages:NIST:gDoTubeShadowCor
	if (gDoTubeShadowCor == 1)
		Print "Doing Tube Efficiency+Shadow correction"
			

		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)

		if(cmpstr(ksDetType,"Ordela") != 0)
			// not a match, it's tubes
		
			TubeEfficiencyShadowCorr(w,w_err,fname,destPath)
		
		else
			// it's Ordela, do the proper detector efficiency correction
			
			Print "DetEffCorr calculated but NOT TESTED for Ordela - verify that the det_eff matrix is correctly calculated and applied"
			OrdelaEfficiencyCorr(w,w_err,fname,destPath)

		endif
			
	else
		Print "Tube efficiency+shadowing correction NOT DONE"
	endif	



	// (6) Downstream window angle dependent transmission correction
	// TODO:
	// -- HARD WIRED value
	// x- find a temporary way to pass this value into the function (global?)
	//
	// -- currently the transmission is set as a global (in Preferences)
	// -- need a permanent location in the file header to store the transmission value
	//
	NVAR/Z gDoWinTrans = root:Packages:NIST:gDoDownstreamWindowCor
	if(NVAR_Exists(gDoWinTrans) != 1)
		InitializeWindowTrans()		//set up the globals (need to check in multiple places)
	endif
		
	if (gDoWinTrans == 1)
		Print "Doing Large-angle Downstream window transmission correction"// for "+ detStr
	
		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)
		
		DownstreamWindowTransmission(w,w_err,fname,destPath)
			
	else
		Print "Downstream Window Transmission correction NOT DONE"
	endif	
		



	// (7) angle dependent transmission correction
	// (DONE):
	// x- still some debate of when/where in the corrections that this is best applied
	//    - do it here, and it's done whether the output is 1D or 2D
	//    - do it later (where SAMPLE information is used) since this section is ONLY instrument-specific
	// x- verify that the calculation is correct
	// x- verify that the error propagation (in 2D) is correct
	//
	NVAR gDoTrans = root:Packages:NIST:gDoTransmissionCorr
	if (gDoTrans == 1)
		Print "Doing Large-angle sample transmission correction"// for "+ detStr

		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)
		
		LargeAngleTransmissionCorr(w,w_err,fname,destPath)

	else
		Print "Sample Transmission correction NOT DONE"
	endif	
	
	
	// (8) normalize to default monitor counts
	//
	// rescaled valuea are written only the work folder - the raw detector data and 
	// the raw data monitor counts are NOT changed, and the rescaling factor is NOT stored in
	// the data file
	//
	NVAR gDoMonitorNormalization = root:Packages:NIST:gDoMonitorNormalization
	if (gDoMonitorNormalization == 1)
		
		Variable monCount,savedMonCount
		defmon=1e8			//default monitor counts
//		monCount = getControlMonitorCount(fname)			// TODO -- this is read in since VCALC fakes this on output
		monCount = getBeamMonNormData(fname)		// TODO -- I think this is the *real* one to read
		savedMonCount	= monCount
		scale = defMon/monCount		// scale factor to MULTIPLY data by to rescale to defmon

		// PUT to newType=fname will put new values in the destination WORK folder
		putBeamMonNormSaved_count(fname,savedMonCount)			// save the true count
		putBeamMonNorm_Data(fname,defMon)		// mon ct is now 10^8
					

		Wave w = getDetectorDataW(fname)
		Wave w_err = getDetectorDataErrW(fname)

		// do the calculation right here. It's a simple scaling and not worth sending to another function.	
		//scale the data and error to the default monitor counts
//
		w *= scale
		w_err *= scale		//assumes total monitor count is so large there is essentially no error

		Variable integratedCount = sum(w)
		putDet_IntegratedCount(fname,integratedCount)		//already the scaled value for counts

	else
		Print "Monitor Normalization correction NOT DONE"
	endif
	
// STILL TODO
// flag to allow adding raw data files with different attenuation (normally not done)	
// -- yet to be implemented as a preference panel item?
//	NVAR gAdjustRawAtten = root:Packages:NIST:gDoAdjustRAW_Atten	
	
	
//	// (not done) 
// angle dependent efficiency correction
//	// -- efficiency and shadowing are now done together (step 5)
//	NVAR doEfficiency = root:Packages:NIST:gDoDetectorEffCor


//NOT DONE 
//-- linear data should be ignored in the reduction
// only use the "regular" data there is no need to drag an extra copy around
	
// keep the linear_data in sync with the data (And errors)
// by manually setting htem equal after all of the corrections to the data are done.
// -- it is the responsibility of the data reduction steps (COR) to keep linear_data up-to-date

//	Wave w = getDetectorDataW(fname)
//	Wave w_err = getDetectorDataErrW(fname)
//
//	Wave lin_w = getDetectorLinearDataW(fname)
//	Wave lin_w_err = getDetectorLinearDataErrW(fname)	
//
//	lin_w = w
//	lin_w_err = w_err
	

	//reset the current displaytype to "newtype"
	String/G root:myGlobals:gDataDisplayType=newType
	String/G root:Packages:NIST:gCurDispType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End




//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Raw_to_Work_NoNorm(type)
	String type
	
	putBeamMonNormSaved_count("RAW",1)		//true monitor counts, still in raw, set to 1
	Raw_to_Work_for_Tubes(type)
	//data is now in "type" folder
	Wave data = getDetectorDataW(type)
	Wave data_err = getDetectorDataErrW(type)
		
	Variable norm_mon,tot_mon,scale
	
	norm_mon = getBeamMonNormData(type)		//should be 1e8
	tot_mon = getBeamMonNormSaved_count(type)		//should be 1
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	
	return(0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Add_Raw_to_Work_NoNorm(type)
	String type
	
	putBeamMonNormSaved_count("RAW",1)		//true monitor counts, still in raw, set to 1
	Add_Raw_to_work_for_Tubes(type)
	//data is now in "type" folder
	Wave data = getDetectorDataW(type)
	Wave data_err = getDetectorDataErrW(type)
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = getBeamMonNormData(type)		//should be 1e8
	tot_mon = getBeamMonNormSaved_count(type)		//should be 1
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	
	return(0)
End











//
// OLD corrections, used for Ordela
// "x" comments out the whole function
// -- verify this shorthand in the WM documentation
//




//performs solid angle and non-linear detector corrections to raw data as it is "added" to a work folder
//function is called by Raw_to_work() and Add_raw_to_work() functions
//works on the actual data array, assumes that is is already on LINEAR scale
//
//
//-- OLD style corrections for Ordela, not used for 10m SANS w/tubes
//
xFunction DetCorr(data,data_err,fname,doEfficiency,doTrans)
	Wave data,data_err
	String fname			//folder with the data
	Variable doEfficiency,doTrans
	
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,xx0,yy0
	Variable ii,jj,dtdist,dtdis2
	Variable xi,xd,yd,rad,ratio,domega,xy
	Variable lambda,trans,trans_err,lat_err,tmp_err,lat_corr
	
//	Print "...doing jacobian and non-linear corrections"

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR type = root:myGlobals:gDataDisplayType
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
	
	//set up values to send to auxiliary trig functions
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela

	x0 = getDet_beam_center_x(fname)
	y0 = getDet_beam_center_y(fname)
	
//	WAVE calX=getDet_cal_x(fname)
//	WAVE calY=getDet_cal_y(fname)
	sx = getDet_x_pixel_size(fname)
	sx3 = 10000		// nonlinear correction - (10,000 turns correction "off")
	sy = getDet_y_pixel_size(fname)
	sy3 = 10000
	
	dtdist = 10*getDet_Distance(fname)	//sdd in mm
	dtdis2 = dtdist^2
	
	lambda = getWavelength(fname)
	trans = getSampleTransmission(fname)
	trans_err = getSampleTransError(fname)		//new, March 2011
	
	xx0 = dc_fx(x0,sx,sx3,xcenter)
	yy0 = dc_fy(y0,sy,sy3,ycenter)
	

	//waves to contain repeated function calls
	Make/O/N=(pixelsX) fyy,xx,yy		//Assumes square detector !!!
	ii=0
	do
		xi = ii
		fyy[ii] = dc_fy(ii+1,sy,sy3,ycenter)
		xx[ii] = dc_fxn(ii+1,sx,sx3,xcenter)
		yy[ii] = dc_fym(ii+1,sy,sy3,ycenter)
		ii+=1
	while(ii<pixelsX)
	
	Make/O/N=(pixelsX,pixelsY) SolidAngle		// testing only
	
	ii=0
	do
		xi = ii
		xd = dc_fx(ii+1,sx,sx3,xcenter)-xx0
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
			
			
			// correction factor for detector efficiency JGB memo det_eff_cor2.doc 3/20/07
			// correction inserted 11/2007 SRK
			// large angle detector efficiency is >= 1 and will "bump up" the measured value at the highest angles
			// so divide here to get the correct answer (5/22/08 SRK)
			if(doEfficiency)
#if (exists("ILL_D22")==6)
				data[ii][jj]  /= DetEffCorrILL(lambda,dtdist,xd) 		//tube-by-tube corrections 
				data_err[ii][jj] /= DetEffCorrILL(lambda,dtdist,xd) 			//assumes correction is exact
//	          solidAngle[ii][jj] = DetEffCorrILL(lambda,dtdist,xd)
#else
				data[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
				data_err[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
//				solidAngle[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)		//testing only
#endif
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
				
				// this function modifies the data + data_err
				LargeAngleTransmissionCorr(data,data_err,fname,"root:Packages:NIST:"+fname)
			
//				// pass in the transmission error, and the error in the correction is returned as the last parameter
//				lat_corr = LargeAngleTransmissionCorr(trans,dtdist,xd,yd,trans_err,lat_err)		//moved from 1D avg SRK 11/2007
//				data[ii][jj] /= lat_corr			//divide by the correction factor
//				//
//				//
//				//
//				// relative errors add in quadrature
//				tmp_err = (data_err[ii][jj]/lat_corr)^2 + (lat_err/lat_corr)^2*data[ii][jj]*data[ii][jj]/lat_corr^2
//				tmp_err = sqrt(tmp_err)
//				
//				data_err[ii][jj] = tmp_err
				
//				solidAngle[ii][jj] = lat_err

				
				//solidAngle[ii][jj] = LargeAngleTransmissionCorr(trans,dtdist,xd,yd)		//testing only
			endif
			
			jj+=1
		while(jj<pixelsX)
		ii+=1
	while(ii<pixelsX)
	
	//clean up waves
//	Killwaves/Z fyy,xx,yy
	
	Return(0)
End

//trig function used by DetCorr()
xFunction dc_fx(x,sx,sx3,xcenter)
	Variable x,sx,sx3,xcenter
	
	Variable result
	
	result = sx3*tan((x-xcenter)*sx/sx3)
	Return(result)
End

//trig function used by DetCorr()
xFunction dc_fy(y,sy,sy3,ycenter)
	Variable y,sy,sy3,ycenter
	
	Variable result
	
	result = sy3*tan((y-ycenter)*sy/sy3)
	Return(result)
End

//trig function used by DetCorr()
xFunction dc_fxn(x,sx,sx3,xcenter)
	Variable x,sx,sx3,xcenter
	
	Variable result
	
	result = (cos((x-xcenter)*sx/sx3))^2
	Return(result)
End

//trig function used by DetCorr()
xFunction dc_fym(y,sy,sy3,ycenter)
	Variable y,sy,sy3,ycenter
	
	Variable result
	
	result = (cos((y-ycenter)*sy/sy3))^2
	Return(result)
End



//******************
//direct port of the FORTRAN code for calculating the weighted
//shifted element to add when beam centers in data headers do not match
//(indices updated to [0,n-1] indexing rather than (1,n) of fortran
//
// as of IGOR 4.0, could be rewritten to pass-by-reference noadd, rather than wave, but the function
// is so little used, it's not worth the time
Function ShiftSum(DATA,ip,jp,XSHIFT,YSHIFT,noadd)
	Wave data
	Variable ip,jp,xshift,yshift
	Wave noadd
//
//       COMPUTE WEIGHTED OFFSET ELEMENT SUM FOR USE IN SANS DATA
//       ANALYSIS MODULES.
//
// "data" wave passed in is the current contents of the work file
// sum_val is the return value of the function
// "noadd" is passed back to the calling function as a one-point wave

	Variable XDELTA,YDELTA,kk,II,JJ,ISHIFT,JSHIFT,sum_val
	Make/O/N=4 iii,jjj,a

//       -----------------------------------------------------------------

	ISHIFT = trunc(XSHIFT)   	// INTEGER PART, trunc gives int closest in dierction of zero
	XDELTA = XSHIFT - ISHIFT   	//FRACTIONAL PART.
	JSHIFT = trunc(YSHIFT)
	YDELTA = YSHIFT - JSHIFT
	II = ip + ISHIFT
	JJ = jp + JSHIFT

//       SHIFT IS DEFINED AS A VECTOR ANCHORED AT THE STATIONARY CENTER
//       AND POINTING TO THE MOVABLE CENTER.  THE MOVABLE FIELD IS THUS
//       ACTUALLY MOVED BY -SHIFT.
//
	IF ((XDELTA>= 0) && (YDELTA >= 0))		// CASE I ---- "%&" is "and"
		III[0] = II
		JJJ[0] = JJ
		III[1] = II + 1
		JJJ[1] = JJ
		III[2] = II + 1
		JJJ[2] = JJ + 1
		III[3] = II
		JJJ[3] = JJ + 1
		A[0] = (1. - XDELTA)*(1. - YDELTA)
		A[1] = XDELTA*(1. - YDELTA)
		A[2] = XDELTA*YDELTA
		A[3] = (1. - XDELTA)*YDELTA
	Endif
	IF ((XDELTA >= 0) && (YDELTA < 0))		// CASE II.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ - 1
		III[2] = II + 1
		JJJ[2] = JJ - 1
		III[3] = II + 1
		JJJ[3] = JJ
		A[0] = (1. - XDELTA)*(1. + YDELTA)
		A[1] = (1. - XDELTA)*(-YDELTA)
		A[2] = XDELTA*(-YDELTA)
		A[3] = XDELTA*(1. + YDELTA)
	Endif
	IF ((XDELTA < 0) && (YDELTA >= 0))	 	// CASE III.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ + 1
		III[2] = II - 1
		JJJ[2] = JJ + 1
		III[3] = II - 1
		JJJ[3] = JJ
		A[0] = (1. + XDELTA)*(1 - YDELTA)
		A[1] = (1. + XDELTA)*YDELTA
		A[2] = -XDELTA*YDELTA
		A[3] = -XDELTA*(1. - YDELTA)
	Endif
	IF ((XDELTA < 0) && (YDELTA < 0))		//CASE IV.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II - 1
		JJJ[1] = JJ
		III[2] = II - 1
		JJJ[2] = JJ - 1
		III[3] = II
		JJJ[3] = JJ - 1
		A[0] = (1. + XDELTA)*(1. + YDELTA)
		A[1] = -XDELTA*(1. + YDELTA)
		A[2] = (-XDELTA)*(-YDELTA)
		A[3] = (1. + XDELTA)*(-YDELTA)
	Endif

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR type = root:myGlobals:gDataDisplayType
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
	
//check to see if iii[0],jjj[0] are valid detector elements, in [0,127]
//if not set noadd[0] to 1, to let calling routine know NOT to add
//        CALL TESTIJ(III(1),JJJ(1),OKIJ)
	NOADD[0] = 0
	if( (iii[0]<0) || (iii[0]>(pixelsX-1)) )
		noadd[0] = 1
	endif
	if((jjj[0]<0) || (jjj[0]>(pixelsY-1)) )
		noadd[0] = 1
	endif
	

	
	sum_val = 0.
	kk = 0
	Do
		IF(JJJ[kk] == pixelsX)
			//do nothing
		else
			sum_val += A[kk]*DATA[III[kk]][JJJ[kk]]
		endif
		kk+=1
	while(kk<4)
	
	//clean up waves
	KillWaves/z iii,jjj,a
	
	RETURN (sum_val)
	
End		//function ShiftSum








