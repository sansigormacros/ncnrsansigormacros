#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
// The base functions for R/W from HDF5 files.
// All of the specific "get" and "write" functions call these base functions which are responsible
// for all of the open/close mechanics.
//
// These VSANS file-specific functions are in:
// V_HDF5_Read.ipf
//		 and
// V_HDF5_Write.ipf
//

// data is read into:
// 	NewDataFolder/O/S root:Packages:NIST:VSANS:RawVSANS
// so that the data folders of the raw data won't be lying around on the top level, looking like
// 1D data sets and interfering.

// loads a raw data set into RAW, then copies into the ReadNoise folder
// all I really need from this set is the data from the back detector, nothing else.
Proc LoadHighResReadNoiseData()
	V_LoadHDF5Data("", "RAW")
	V_CopyHDFToWorkFolder("RAW", "ReadNoise")
EndMacro

// passing null file string presents a dialog
Proc LoadFakeDIVData()
	V_LoadHDF5Data("", "DIV")
EndMacro

// Moved to V_MaskUtils.ipf
// passing null file string presents a dialog
//Proc LoadFakeMASKData()
//	V_LoadHDF5Data("","MSK")
//End

// passing null file string presents a dialog
Proc Read_HDF5_Raw_No_Attributes()
	V_LoadHDF5Data("", "RAW")
EndMacro

// (DONE):
//  x- move the initialization of the raw data folder to be in the as-yet unwritten initialization routine for
// reduction. be sure that it's duplicated in the VCALC initialization too.
// x- as needed, get rid of the fake redimension of the data from 3D->2D and from 128x128 to something else for VSANS
//    This is fake since I don't have anything close to correct fake data yet. (1/29/16)
//
// DONE: x- is there an extra "entry" heading? Am I adding this by mistake by setting base_name="entry" for RAW data?
//			x- as dumb as it is -- do I just leave it now, or break everything. On the plus side, removing the extra "entry"
//          layer may catch a lot of the hard-wired junk that is present...
//      extra entry layer is no longer generated for any WORK folders
//
Function V_LoadHDF5Data(string file, string folder)

	string base_name, detStr
	string   destPath
	variable ii

	destPath = "root:Packages:NIST:VSANS:" + folder
	// before reading in new data, clean out what old data can be cleaned. hopefully new data will overwrite what is in use
	V_KillWavesFullTree($destPath, folder, 0, "", 1) // this will traverse the whole tree, trying to kill what it can

	if(DataFolderExists("root:Packages:NIST:VSANS:" + folder) == 0) //if it was just killed?
		NewDataFolder/O $("root:Packages:NIST:VSANS:" + folder)
	endif
	SetDataFolder $("root:Packages:NIST:VSANS:" + folder)

	variable err = V_LoadHDF5_NoAtt(file, folder) // reads into current folder

	if(err)
		DoAlert 0, "User cancelled or other file read error..."
		return (1)
	endif

	// if a file was read in (by DisplayRawData), then pick up the file name
	if(strlen(file) == 0)
		SVAR gFileName = root:file_name
		file = gFileName
	endif

	// if RAW data, then generate the errors and linear data copy
	// do this 9x
	// then do any "massaging" needed to redimension, fake values, etc.
	//
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:"

	// if the data is DIV, then handle the data errors differently since they are already part of the data file
	// root:Packages:NIST:VSANS:DIV:entry:instrument:detector_B:
	if(cmpstr(folder, "DIV") == 0)
		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above
		tmpStr = "root:Packages:NIST:VSANS:DIV:entry:instrument:"
		for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			SetDataFolder $(tmpStr + "detector_" + detStr)
			//V_MakeDataError(tmpStr+"detector_"+detStr)
			WAVE data = data
			Duplicate/O data, $(tmpStr + "detector_" + detStr + ":linear_data")
			WAVE linear_data_error = linear_data_error
			Duplicate/O linear_data_error, $(tmpStr + "detector_" + detStr + ":data_error")
			SetDataFolder root:
		endfor
	endif

	if(cmpstr(folder, "RAW") == 0)

		// 15 SEP 2020
		// with the change in how NICE handles data from detectors that are not active,
		// the data for the highRes detector is no longer written out as dummy values
		// when it is not in use. Since this generates errors in the reduction
		// (display, transmission, + other?) - I will generate my own fake data to fill in
		// the missing data. The data is only filled into the loaded data set, and does not
		// add the fake data to the data stored on disk (although this is a possibility for the
		// future)

		// ? do I also set the flag here to ignore the back detector? I probably should, since
		// the data is bogus (one reason NICE doesn't write it out). I may choose to leave the
		// flag in the hands of the user. Better for debugging since I have control

		// does the data wave exist?
		// check for the data wave directly in the file. The data wave in the RAW data folder
		// may exist if the data display is open and folder is simply overwritten
		WAVE/Z testB = V_getDetectorDataW(file, "B")
		if(WaveExists(testB) == 0) // null wave reference

			variable isDenex = 0
			variable nx, ny, ctrX, ctrY

			// since det_B does not exist... test for Denex will always FAIL
			// I need a different way to do this..
			if(cmpstr("Denex", V_getDetDescription("RAW", "B")) == 0)
				isDenex = 1
				nx      = 512
				ny      = 512
				ctrX    = 255
				ctrY    = 255
			else
				nx   = 680
				ny   = 1656
				ctrX = 340
				ctrY = 828
			endif

			// generate the fake data
			Make/O/I/N=(nx, ny) root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:data = 0
			WAVE dataB = root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:data
			ii = 0
			do
				dataB[ii][ii]      = 1
				dataB[20 - ii][ii] = 1
				ii                += 1
			while(ii < 20)

			// beam center (x,y) is also not written out
			// use put function to work on the local folder only, not the data on disk
			// must make the wave first, since it doesn't exist
			// (could write the value in make, but use the call for completeness)
			Make/O/D/N=1 root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:beam_center_x = 0
			Make/O/D/N=1 root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:beam_center_y = 0
			V_putDet_beam_center_x("RAW", "B", ctrX)
			V_putDet_beam_center_y("RAW", "B", ctrY)

			// the integrated count is not written out - fake this == 1
			Make/O/D/N=1 root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:integrated_count = 0
			V_putDet_IntegratedCount("RAW", "B", 1)

			//			// set the ignore flag
			//			NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
			//			gIgnoreDetB = 1

			//			// write the fake data out to the file
			// important to write data now, since the data is still integer
			//			V_writeDetectorData(file,"B",dataB)
			//			V_writeDet_beam_center_x(file,"B",340)
			//			V_writeDet_beam_center_y(file,"B",828)
			//			V_writeDet_IntegratedCount(file,"B",1)

		endif
		///////

		// (DONE) -- once I get "real" data, get rid of this call to force the data to be proper dimensions.
		//		V_RedimFakeData()

		V_MakeDataWaves_DP(folder)
		//		V_FakeBeamCenters()
		//		V_FakeScaleToCenter()

		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above
		for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			V_MakeDataError(tmpStr + "detector_" + detStr)
		endfor

		// (DONE)
		//  -- get rid of these fake calibration waves as "real" ones are filled in by NICE
		//		(currently does nothing)
		//		Execute "MakeFakeCalibrationWaves()"

		//		fMakeFakeCalibrationWaves()		//skips the alert

		// (DONE) -- calculate the nonlinear x/y arrays and the q-values here
		// -- otherwise the mouse-over doesn't calculate the correct Q_values
		// the display currently is not shifted or altered at all to account for the non-linearity
		// or for display in q-values -- so why bother with this?
		NVAR gDoNonLinearCor = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
		// generate a distance matrix for each of the detectors

		// APR 2025 - both true and false pass in, switch in V_NonLinearCorrection to either apply non-linear
		// corections as in the data file, or "no", don't apply non-linear corrections and in V_NonLinearCorrection
		// use the "perfect" values
		if(gDoNonLinearCor == 1 || gDoNonLinearCor == 0)
			Print "Calculating Non-linear correction at RAW load time" // for "+ detStr
			for(ii = 0; ii < ItemsInList(ksDetectorListNoB); ii += 1)
				detStr = StringFromList(ii, ksDetectorListNoB, ";")
				WAVE w = V_getDetectorDataW(folder, detStr)
				//			Wave w_err = V_getDetectorDataErrW(fname,detStr)		//not here, done above w/V_MakeDataError()
				WAVE     w_calib    = V_getDetTube_spatialCalib(folder, detStr)
				variable tube_width = V_getDet_tubeWidth(folder, detStr)
				V_NonLinearCorrection(folder, w, w_calib, tube_width, detStr, destPath)

				//(2.4) Convert the beam center values from pixels to mm
				// --The proper definition of beam center is in [cm], so the conversion
				// is no longer needed (kBCTR_CM==1)

				// (DONE)
				// x- the beam center value in mm needs to be present - it is used in calculation of Qvalues
				// x- but having both the same is wrong...
				// x- the pixel value is needed for display of the panels
				if(kBCTR_CM)
					//V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
					//

					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_" + detStr + ":beam_center_x_mm")
					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_" + detStr + ":beam_center_y_mm")
					WAVE x_mm = $(destPath + ":entry:instrument:detector_" + detStr + ":beam_center_x_mm")
					WAVE y_mm = $(destPath + ":entry:instrument:detector_" + detStr + ":beam_center_y_mm")
					x_mm[0] = V_getDet_beam_center_x(folder, detStr) * 10 // convert cm to mm
					y_mm[0] = V_getDet_beam_center_y(folder, detStr) * 10 // convert cm to mm

					// (DONE):::
					// now I need to convert the beam center in mm to pixels
					// and have some rational place to look for it...
					V_ConvertBeamCtr_to_pix(folder, detStr, destPath)
				else
					// beam center is in pixels, so use the old routine
					V_ConvertBeamCtrPix_to_mm(folder, detStr, destPath)
				endif

				// (2.5) Calculate the q-values
				// calculating q-values can't be done unless the non-linear corrections are calculated
				// so go ahead and put it in this loop.
				// (DONE) :
				// x- make sure that everything is present before the calculation
				// x- beam center must be properly defined in terms of real distance
				// x- distances/zero location/ etc. must be clearly documented for each detector
				//	** this assumes that NonLinearCorrection() has been run to generate data_RealDistX and Y
				// ** this routine Makes the waves QTot, qx, qy, qz in each detector folder.
				//
				V_Detector_CalcQVals(folder, detStr, destPath)

			endfor

			//"B" is handled separately
			//
			// (DONE) - "B" is more naturally be defined initially in terms of pixel centers, then converted to [cm]?
			//
			detStr = "B"
			WAVE w     = V_getDetectorDataW(folder, detStr)
			WAVE cal_x = V_getDet_cal_x(folder, detStr)
			WAVE cal_y = V_getDet_cal_y(folder, detStr)

			V_NonLinearCorrection_B(folder, w, cal_x, cal_y, detStr, destPath)

			// "B" is always naturally defined in terms of a pixel center. This can be converted to mm,
			// but the experiment will measure pixel x,y - just like ordela detectors.

			//			if(kBCTR_CM)
			//
			//				Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
			//				Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
			//				WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
			//				WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
			//				x_mm[0] = V_getDet_beam_center_x(folder,detStr) * 10 		// convert cm to mm
			//				y_mm[0] = V_getDet_beam_center_y(folder,detStr) * 10 		// convert cm to mm
			//
			//				// now I need to convert the beam center in mm to pixels
			//				// and have some rational place to look for it...
			//				V_ConvertBeamCtr_to_pixB(folder,detStr,destPath)
			//			else

			// beam center is in pixels, so use the old routine
			V_ConvertBeamCtrPix_to_mmB(folder, detStr, destPath)

			//			endif
			V_Detector_CalcQVals(folder, detStr, destPath)

		else
			Print "Non-linear correction not done"
		endif

		// shift the detector image on the back detector to get the three CCD images to match up
		// in real space. the distance matrices x and y still apply. be sure to mask out the chunks
		// that were lost in the shift

		// the data wave is altered
		// the linear_data wave is not altered

		WAVE adjW = V_getDetectorDataW(folder, "B")
		WAVE w    = V_getDetectorLinearDataW(folder, "B")
		V_ShiftBackDetImage(w, adjW)

		// and repeat for the error wave
		WAVE adjW = V_getDetectorDataErrW(folder, "B")
		WAVE w    = V_getDetectorLinearDataErrW(folder, "B")
		V_ShiftBackDetImage(w, adjW)

		/// END DATA CORRECTIONS FOR LOADER

	endif

	SetDataFolder root:
	return (err)
End

// fname is the folder = "RAW"
Function V_MakeDataWaves_DP(string fname)

	variable ii
	string   detStr

	for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		WAVE w = V_getDetectorDataW(fname, detStr)
		//		Wave w_err = V_getDetectorDataErrW(fname,detStr)  //not here, done in V_MakeDataError() by duplicating dataW
		Redimension/D w
		//		Redimension/D w_err
	endfor

	return (0)
End

//
// (DONE)
// -- this is all FAKED since all the data arrays are written to hdf as (1,128,128)
//  -- try to fill in the bits from VCALC, if it exists (or force it)
//
// the SetScale parts may be useful later.
//
// This is NOT CALLED anymore.
// the rescaling (SetScale) of the data sets is still done separately to a "fake" beam center
Function xV_RedimFakeData()

	// check for fake data in VCALC folder...
	WAVE/Z tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B:det_B"
	if(WaveExists(tmpw) == 0)
		Execute "VCALC_Panel()"
	endif

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B
	WAVE det_B = data
	//	Redimension/N=(150,150)/E=1 det_B
	Redimension/D det_B
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B:det_B"
	//	det_B=tmpw
	//	det_B += 2
	WAVE distance = distance
	distance = VC_getSDD("B") * 100 // to convert m to cm

	variable ctr  = 20
	variable npix = 128
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MT
	WAVE det_MT = data
	//	Redimension/N=(npix,48)/E=1 det_MT
	Redimension/D det_MT
	SetScale/I x - npix / 2, npix / 2, "", det_MT
	SetScale/I y, ctr, ctr + 48, "", det_MT
	//	det_MT *= 10
	//	det_MT += 2
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MT:det_MT"
	//	det_MT=tmpw
	//	det_MT += 2
	WAVE distance = distance
	distance = VC_getSDD("MT") * 100 // to convert m to cm

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MB
	WAVE det_MB = data
	//	Redimension/N=(npix,48)/E=1 det_MB
	Redimension/D det_MB
	SetScale/I x - npix / 2, npix / 2, "", det_MB
	SetScale/I y - ctr - 48, -ctr, "", det_MB
	//	det_MB *= 5
	//	det_MB += 2
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MB:det_MB"
	//	det_MB=tmpw
	//	det_MB += 2
	WAVE distance = distance
	distance = VC_getSDD("MB") * 100 // to convert m to cm

	ctr = 30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_ML
	WAVE det_ML = data
	//	Redimension/N=(48,npix)/E=1 det_ML
	Redimension/D det_ML
	SetScale/I x - ctr - 48, -ctr, "", det_ML
	SetScale/I y - npix / 2, npix / 2, "", det_ML
	//	det_ML *= 2
	//	det_ML += 2
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_ML:det_ML"
	//	det_ML=tmpw
	//	det_ML += 2
	WAVE distance = distance
	distance = VC_getSDD("ML") * 100 // to convert m to cm

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MR
	WAVE det_MR = data
	//	Redimension/N=(48,npix)/E=1 det_MR
	Redimension/D det_MR
	SetScale/I x, ctr, ctr + 48, "", det_MR
	SetScale/I y - npix / 2, npix / 2, "", det_MR
	//	det_MR +=2
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MR:det_MR"
	//	det_MR=tmpw
	//	det_MR += 2
	WAVE distance = distance
	distance = VC_getSDD("MR") * 100 // to convert m to cm

	ctr = 30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FT
	WAVE det_FT = data
	//	Redimension/N=(npix,48)/E=1 det_FT
	Redimension/D det_FT
	SetScale/I x - npix / 2, npix / 2, "", det_FT
	SetScale/I y, ctr, ctr + 48, "", det_FT
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FT:det_FT"
	//	det_FT=tmpw
	WAVE distance = distance
	distance = VC_getSDD("FT") * 100 // to convert m to cm

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB
	WAVE det_FB = data
	//	Redimension/N=(npix,48)/E=1 det_FB
	Redimension/D det_FB
	SetScale/I x - npix / 2, npix / 2, "", det_FB
	SetScale/I y - ctr - 48, -ctr, "", det_FB
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FB:det_FB"
	//	det_FB=tmpw
	WAVE distance = distance
	distance = VC_getSDD("FB") * 100 // to convert m to cm

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL
	WAVE det_FL = data
	//	Redimension/N=(48,npix)/E=1 det_FL
	Redimension/D det_FL
	SetScale/I x - ctr - 48, -ctr, "", det_FL
	SetScale/I y - npix / 2, npix / 2, "", det_FL
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FL:det_FL"
	//	det_FL=tmpw
	WAVE distance = distance
	distance = VC_getSDD("FL") * 100 // to convert m to cm

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FR
	WAVE det_FR = data
	//	Redimension/N=(48,npix)/E=1 det_FR
	Redimension/D det_FR
	SetScale/I x, ctr, ctr + 48, "", det_FR
	SetScale/I y - npix / 2, npix / 2, "", det_FR
	WAVE tmpw = $"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FR:det_FR"
	//	det_FR=tmpw
	WAVE distance = distance
	distance = VC_getSDD("FR") * 100 // to convert m to cm

	// get rid of zeros
	//	det_FL += 2
	//	det_FR += 2
	//	det_FT += 2
	//	det_FB += 2

	// fake beam center values
	V_putDet_beam_center_x("RAW", "B", 75)
	V_putDet_beam_center_y("RAW", "B", 75)

	V_putDet_beam_center_x("RAW", "MB", 64)
	V_putDet_beam_center_y("RAW", "MB", 55)
	V_putDet_beam_center_x("RAW", "MT", 64)
	V_putDet_beam_center_y("RAW", "MT", -8.7)
	V_putDet_beam_center_x("RAW", "MR", -8.1)
	V_putDet_beam_center_y("RAW", "MR", 64)
	V_putDet_beam_center_x("RAW", "ML", 55)
	V_putDet_beam_center_y("RAW", "ML", 64)

	V_putDet_beam_center_x("RAW", "FB", 64)
	V_putDet_beam_center_y("RAW", "FB", 55)
	V_putDet_beam_center_x("RAW", "FT", 64)
	V_putDet_beam_center_y("RAW", "FT", -8.7)
	V_putDet_beam_center_x("RAW", "FR", -8.1)
	V_putDet_beam_center_y("RAW", "FR", 64)
	V_putDet_beam_center_x("RAW", "FL", 55)
	V_putDet_beam_center_y("RAW", "FL", 64)

	V_RescaleToBeamCenter("RAW", "MB", 64, 55)
	V_RescaleToBeamCenter("RAW", "MT", 64, -8.7)
	V_RescaleToBeamCenter("RAW", "MR", -8.1, 64)
	V_RescaleToBeamCenter("RAW", "ML", 55, 64)
	V_RescaleToBeamCenter("RAW", "FL", 55, 64)
	V_RescaleToBeamCenter("RAW", "FR", -8.1, 64)
	V_RescaleToBeamCenter("RAW", "FT", 64, -8.7)
	V_RescaleToBeamCenter("RAW", "FB", 64, 55)

	return (0)
End

// This loads for speed, since loading the attributes takes a LOT of time.
//
// this will load in the whole Nexus file all at once.
// -- the DAS_Logs are SKIPPED - since they are not needed for reduction
// Attributes are NOT loaded at all.
//
// -- the Gateway function H5GW_ReadHDF5(parentFolder, fileName, [hdf5Path])
//    reads in the attributes too, but is very slow
//   -- the H5GW function is called by: H_HDF5Gate_Read_Raw(file)
//
// (DONE):
// -x remove the P=home restriction top make this more generic (replaced with catPathName from PickPath)
// x- get rid of bits leftover here that I don't need
// x- be sure I'm using all of the correct flags in the HDF5LoadGroup operation
// x- settle on how the base_name is to be used. "entry" for the RAW, fileName for the "rawVSANS"?
// x- error check for path existence
//
// passing in "" for base_name will take the name from the file name as selected
//
Function V_LoadHDF5_NoAtt(string fileName, string base_name)

	//	if ( ParamIsDefault(hdf5Path) )
	//		hdf5Path = "/"
	//	endif

	PathInfo/S catPathName
	if(V_flag == 0)
		DoAlert 0, "Pick the data folder, then the data file"
		V_PickPath()
	endif

	string hdf5path = "/" //always read from the top
	string status   = ""

	variable fileID = 0
	//	HDF5OpenFile/R/P=home/Z fileID as fileName		//read file from home directory?
	HDF5OpenFile/R/P=catPathName/Z fileID as fileName
	if(V_Flag != 0)
		return 1
	endif

	string/G root:file_path = S_path
	string/G root:file_name = S_FileName

	if(fileID == 0)
		Print fileName + ": could not open as HDF5 file"
		return (1)
	endif

	//v_tic()		//fast

	SVAR tmpStr = root:file_name
	fileName = tmpStr //SRK - in case the file was chosen from a dialog, I'll need access to the name later

	//   read the data (too bad that HDF5LoadGroup does not read the attributes)
	//	if(cmpstr(base_name,"") == 0)
	//		base_name = StringFromList(0,FileName,".")
	//	endif

	// if base_name is from my list of WORK folders + RawVSANS;, then base_name = ""
	// use a stringSwitch? WhichListItem?
	variable isFolder = WhichListItem(base_name, ksWorkFolderListShort + "RawVSANS;")
	if(isFolder != -1)
		base_name = ""
	else
		base_name = StringFromList(0, FileName, ".") // just the first part of the name, no .nxs.ngv
	endif

	// TODO
	// -- write a separate function or add a flag to this one that will read everything, including the DAS_logs
	//   -- the DAS_logs are not needed for reduction, and slow everything down a LOT (0.6 s per file vs 0.04 s per file!)

	//
	//// loads everything with one line	 (includes /DAS_logs)
	//	HDF5LoadGroup/Z/L=7/O/R/T=$base_name  :, fileID, hdf5Path		//	recursive
	//

	// ***NOTE***
	// The temperature block definitons inculde dupilcated groups. As of 7/27/17 (HDF 5 XOP version 1.24, in Igor 7.05)
	// these duplicated blocks are now handled "correctly" by reading in the multiple copies into
	// duplciated data folders. WM (Howard) modifed the XOP to accomodate this condition.
	// This is the R=2 flag for HDF5LoadGroup

	//// to skip DAS_logs. I need to generate all of the data folders myself
	//// must be an easier way to handle the different path syntax, but at least this works

	string curDF = GetDataFolder(1)

	// load root/entry
	hdf5path = "/entry"
	//	NewDataFolder/O $(curDF)
	if(isFolder == -1)
		NewDataFolder/O $(curDF + base_name)
	endif
	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry")
	else
		// base_name is "", so get rid of the leading ":" on ":entry"
		NewDataFolder/O/S $(curDF + base_name + "entry")
	endif
	HDF5LoadGroup/Z/L=7/O :, fileID, hdf5Path //	NOT recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry:control")
	else
		NewDataFolder/O/S $(curDF + base_name + "entry:control")
	endif
	hdf5path = "/entry/control"
	HDF5LoadGroup/Z/L=7/O/R=2 :, fileID, hdf5Path //	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry:instrument")
	else
		NewDataFolder/O/S $(curDF + base_name + "entry:instrument")
	endif
	hdf5path = "/entry/instrument"
	HDF5LoadGroup/Z/L=7/O/R=2 :, fileID, hdf5Path //	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry:reduction")
	else
		NewDataFolder/O/S $(curDF + base_name + "entry:reduction")
	endif
	hdf5path = "/entry/reduction"
	HDF5LoadGroup/Z/L=7/O/R=2 :, fileID, hdf5Path //	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry:sample")
	else
		NewDataFolder/O/S $(curDF + base_name + "entry:sample")
	endif
	hdf5path = "/entry/sample"
	HDF5LoadGroup/Z/L=7/O/R=2 :, fileID, hdf5Path //	YES recursive (This is the only one that may have duplicated groups)

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF + base_name + ":entry:user")
	else
		NewDataFolder/O/S $(curDF + base_name + "entry:user")
	endif
	hdf5path = "/entry/user"
	HDF5LoadGroup/Z/L=7/O/R=2 :, fileID, hdf5Path //	YES recursive

	if(V_Flag != 0)
		Print fileName + ": could not open as HDF5 file"
		setdatafolder root:
		return (1)
	endif

	HDF5CloseFile fileID

	//v_toc()

	// save a global string with the file name to be picked up for the status on the display
	// this string can be carried around as the data is moved to other folders
	//	Print curDF+"gFileList"
	string/G $(curDF + "gFileList") = fileName

	SetDataFolder root:

	return (0)
End

// read a single real value
// - fname passed in is the full path to the file on disk --OR-- a WORK folder
// - path is the path to the value in the HDF tree
//
/// -- if data requested from a WORK or VCALC folder:
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local WORK folder
//		if it does not exist, return DUMMY value
//
//// -- if data requested from a file:
// check to see if the value exists locally in RawVSANS (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
//
Function V_getRealValueFromHDF5(string fname, string path)

	string   folderStr  = ""
	variable valExists  = 0
	variable errorValue = -999999

	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	// (1) if requesting data from a WORK folder, get it, or report error
	variable isWORKFolder = WhichListItem(fname, ksWorkFolderListShort + "VCALC;RealTime;")
	if(isWORKFolder != -1) //requesting value from a WORK folder (not RawVSANS)
		// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:VSANS:" + folderStr + ":" + path))
			WAVE/Z w = $("root:Packages:NIST:VSANS:" + folderStr + ":" + path)
			return (w[0])
		endif

		return (errorValue)
	endif

	// (2) requesting from a file.
	// look locally in RawVSANS if possible, or if not, load in the data from disk
	// - if thee both fail, report an error
	if(Exists(ksBaseDFPath + folderStr + ":" + path))
		valExists = 1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname, "")
		SetDataFolder root:
	endif

	// this should exist now - if not, I need to see the error
	WAVE/Z w = $(ksBaseDFPath + folderStr + ":" + path)

	if(WaveExists(w))
		return (w[0])
	endif

	return (errorValue)
End

// Returns a wave reference, not just a single value
// ---then you pick what you need from the wave
//
// - fname passed in is the full path to the file on disk
// - path is the path to the value in the HDF tree
//
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
// if the wave is null, then that is returned, and the calling function is responsible
//
Function/WAVE V_getRealWaveFromHDF5(string fname, string path)

	string   folderStr = ""
	variable valExists = 0

	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	// (1) if requesting data from a WORK folder, get it
	// no need to check for any existence, null return is OK
	variable isWORKFolder = WhichListItem(fname, ksWorkFolderListShort + "VCALC;RealTime;")
	if(isWORKFolder != -1) //requesting value from a WORK folder (not RawVSANS)
		//	// check for a work folder first (note that "entry" is now NOT doubled)
		//		if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		WAVE/Z wOut = $("root:Packages:NIST:VSANS:" + folderStr + ":" + path)
		return wOut
	endif

	//// check for a work folder first (note that "entry" is NOT doubled)
	//	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
	//		Wave wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
	//		return wOut
	//	endif

	// (2) requesting from a file
	if(Exists(ksBaseDFPath + folderStr + ":" + path))
		valExists = 1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname, "")
		SetDataFolder root:
	endif

	// this should exist now - if not, I need to see the error
	WAVE/Z wOut = $(ksBaseDFPath + folderStr + ":" + path)

	return wOut

End

// Returns a wave reference, not just a single value
// ---then you pick what you need from the wave
//
// - fname passed in is the full path to the file on disk
// - path is the path to the value in the HDF tree
//
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
// if the wave is null, then that is returned, and the calling function is responsible
//
Function/WAVE V_getTextWaveFromHDF5(string fname, string path)

	string   folderStr = ""
	variable valExists = 0

	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	// (1) if requesting data from a WORK folder, get it
	// no need to check for any existence, null return is OK
	variable isWORKFolder = WhichListItem(fname, ksWorkFolderListShort + "VCALC;RealTime;")
	if(isWORKFolder != -1) //requesting value from a WORK folder (not RawVSANS)
		//	// check for a work folder first (note that "entry" is now NOT doubled)
		//		if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		WAVE/Z/T wOut = $("root:Packages:NIST:VSANS:" + folderStr + ":" + path)
		return wOut
	endif

	//// check for a work folder first (note that "entry" is NOT doubled)
	//	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
	//		Wave/T wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
	//		return wOut
	//	endif

	// (2) requesting from a file
	if(Exists(ksBaseDFPath + folderStr + ":" + path))
		valExists = 1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname, "")
		SetDataFolder root:
	endif

	// this should exist now - if not, I will see the error in the calling function
	WAVE/Z/T wOut = $(ksBaseDFPath + folderStr + ":" + path)

	return wOut

End

//
//   (DONE)
// depricated? in HDF5 - store all of the values as real?
// Igor sees no difference in real and integer variables (waves are different)
// BUT-- Igor 7 will have integer variables
//
// truncate to integer before returning??
//
//  (DONE)
// write a "getIntegerWave" function??
//
//////  integer values
// reads 32 bit integer
//
// fname = full path+name
// path = path to the hdf5 location
Function V_getIntegerFromHDF5(string fname, string path)

	variable val = V_getRealValueFromHDF5(fname, path)

	val = round(val)
	return (val)
End

// read a single string
// - fname passed in is the full path to the file on disk --OR-- a WORK folder
// - path is the path to the value in the HDF tree
// - num is the number of characters in the VAX string
//
/// -- if data requested from a WORK or VCALC folder:
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local WORK folder
//		if it does not exist, return DUMMY value
//
//// -- if data requested from a file:
// check to see if the value exists locally in RawVSANS (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
// (DONE) -- string could be checked for length, but returned right or wrong
//
// -- currently num is completely ignored
//
Function/S V_getStringFromHDF5(string fname, string path, variable num)

	string   folderStr   = ""
	variable valExists   = 0
	string   errorString = "The specified wave does not exist: " + path

	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	// (1) if requesting data from a WORK folder, get it, or report error
	variable isWORKFolder = WhichListItem(fname, ksWorkFolderListShort + "VCALC;RealTime;")
	if(isWORKFolder != -1) //requesting value from a WORK folder (not RawVSANS)
		// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:VSANS:" + folderStr + ":" + path))
			WAVE/Z/T tw = $("root:Packages:NIST:VSANS:" + folderStr + ":" + path)
			return (tw[0])
		endif

		return (errorSTring)
	endif

	// (2) requesting from a file.
	// look locally in RawVSANS if possible, or if not, load in the data from disk
	// - if thee both fail, report an error
	if(Exists(ksBaseDFPath + folderStr + ":" + path))
		valExists = 1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname, "")
		SetDataFolder root:
	endif

	// this should exist now - if not, I need to see the error
	WAVE/Z/T tw = $(ksBaseDFPath + folderStr + ":" + path)

	if(WaveExists(tw))

		//	if(strlen(tw[0]) != num)
		//		Print "string is not the specified length"
		//	endif

		return (tw[0])
	endif

	return (errorString)
End

///////////////////////////////

//
//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
//
// (DONE):
// x- figure out if this will write in the native format of the
//     wave as passed in, or if it will only write as DP.
// x-(NO) do I need to write separate functions for real, integer, etc.?
// x- the lines to create a missing group have been commented out to avoid filling
//    in missing fields that should have been generated by the data writer. Need to make
//    a separate function that will write and generate if needed, and use this in specific cases
//    only if I really have to force it.
//
// x-Attributes are not currently saved. Fix this, maybe make it optional? See the help file for
//  DemoAttributes(w) example under the HDF5SaveData operation
//
// -x change the /P=home to the user-defined data path (catPathName)
//
Function V_WriteWaveToHDF(string fname, string groupName, string varName, WAVE wav)

	// try a local folder first, then try to save to disk
	//
	string folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	string localPath = "root:Packages:NIST:VSANS:" + folderStr //+":entry"
	localPath += groupName + "/" + varName
	// make everything colons for local data folders
	localPath = ReplaceString("/", localPath, ":")

	WAVE/Z w = $localPath
	if(waveExists(w) == 1)
		w = wav
		//		Print "write to local folder done"
		return (0) //we're done, get out
	endif

	// if the local wave did not exist, then we proceed to write to disk

	variable fileID, groupID
	variable err = 0
	string temp
	string cDF = getDataFolder(1)
	string NXentry_name

	try
		HDF5OpenFile/P=catPathName/Z fileID as fname //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif

		//get the NXentry node name
		HDF5ListGroup/TYPE=1 fileID, "/"
		//remove trailing ; from S_HDF5ListGroup

		Print "S_HDF5ListGroup = ", S_HDF5ListGroup

		NXentry_name = S_HDF5ListGroup
		NXentry_name = ReplaceString(";", NXentry_name, "")
		if(strsearch(NXentry_name, ":", 0) != -1) //more than one entry under the root node
			err = 1
			abort "More than one entry under the root node. Ambiguous"
		endif
		//concatenate NXentry node name and groupName
		// SRK - NOV2015 - dropped this and require the full group name passed in
		//		groupName = "/" + NXentry_name + groupName
		Print "groupName = ", groupName
		HDF5OpenGroup/Z fileID, groupName, groupID

		if(!groupID)
			// don't create the group if the name isn't right -- throw up an error
			//HDF5CreateGroup /Z fileID, groupName, groupID
			err = 1
			HDF5CloseFile/Z fileID
			DoAlert 0, "HDF5 group does not exist " + groupName + varname
			return (err)
		endif

		// get attributes and save them
		//HDF5ListAttributes /Z fileID, groupName    this is returning null. expect it to return semicolon delimited list of attributes
		//Wave attributes = S_HDF5ListAttributes

		HDF5SaveData/O/Z/IGOR=0 wav, groupID, varName
		if(V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + varName
		endif

		//attributes - something could be added here as optional parameters and flagged
		//		String attributes = "units"
		//		Make/O/T/N=1 tmp
		//		tmp[0] = "dimensionless"
		//		HDF5SaveData /O /Z /IGOR=0 /A=attributes tmp, groupID, varName
		//		if (V_flag != 0)
		//			err = 1
		//			abort "Cannot save attributes to HDF5 dataset"
		//		endif
	catch

	endtry

	// it is not necessary to close the group here. HDF5CloseFile will close the group as well
	if(groupID)
		HDF5CloseGroup/Z groupID
	endif

	if(fileID)
		HDF5CloseFile/Z fileID
	endif

	setDataFolder $cDF
	return err
End

//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
//
// (DONE)
//
// -x change the /P=home to the user-defined data path (catPathName)
//
Function V_WriteTextWaveToHDF(string fname, string groupName, string varName, WAVE/T wav)

	// try a local folder first, then try to save to disk
	//
	string folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

	string localPath = "root:Packages:NIST:VSANS:" + folderStr //+":entry"
	localPath += groupName + "/" + varName
	// make everything colons for local data folders
	localPath = ReplaceString("/", localPath, ":")

	WAVE/Z/T w = $localPath
	if(waveExists(w) == 1)
		w = wav
		Print "write to local folder done"
		return (0) //we're done, get out
	endif

	// if the local wave did not exist, then we proceed to write to disk

	variable fileID, groupID
	variable err = 0
	string temp
	string cDF = getDataFolder(1)
	string NXentry_name

	try
		HDF5OpenFile/P=catPathName/Z fileID as fname //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif

		//get the NXentry node name
		HDF5ListGroup/TYPE=1 fileID, "/"
		//remove trailing ; from S_HDF5ListGroup

		Print "S_HDF5ListGroup = ", S_HDF5ListGroup

		NXentry_name = S_HDF5ListGroup
		NXentry_name = ReplaceString(";", NXentry_name, "")
		if(strsearch(NXentry_name, ":", 0) != -1) //more than one entry under the root node
			err = 1
			abort "More than one entry under the root node. Ambiguous"
		endif

		//concatenate NXentry node name and groupName
		// SRK - NOV2015 - dropped this and require the full group name passed in
		//		groupName = "/" + NXentry_name + groupName
		Print "groupName = ", groupName

		HDF5OpenGroup/Z fileID, groupName, groupID

		if(!groupID)
			// don't create the group it the name isn't right -- throw up an error
			//HDF5CreateGroup /Z fileID, groupName, groupID
			err = 1
			HDF5CloseFile/Z fileID
			DoAlert 0, "HDF5 group does not exist " + groupName + varname
			return (err)
		endif

		// get attributes and save them
		//HDF5ListAttributes /Z fileID, groupName    this is returning null. expect it to return semicolon delimited list of attributes
		//Wave attributes = S_HDF5ListAttributes

		HDF5SaveData/O/Z/IGOR=0 wav, groupID, varName
		if(V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + varName
		endif

		//attributes - something could be added here as optional parameters and flagged
		//		String attributes = "units"
		//		Make/O/T/N=1 tmp
		//		tmp[0] = "dimensionless"
		//		HDF5SaveData /O /Z /IGOR=0 /A=attributes tmp, groupID, varName
		//		if (V_flag != 0)
		//			err = 1
		//			abort "Cannot save attributes to HDF5 dataset"
		//		endif
	catch

	endtry

	if(groupID)
		HDF5CloseGroup/Z groupID
	endif

	if(fileID)
		HDF5CloseFile/Z fileID
	endif

	setDataFolder $cDF
	return err
End

//////////////////////////////
//////////////////////////////
//////////////////////////////

//////////
//
// These procedures are needed to write out MASK and DIV files
//
////////

//
// saves a specified folder, with a given filename.
// saves to the home path
//
// dfPath = local path, e.g., "root:FolderA" or ":"
Proc Save_VSANS_file(dfPath, filename)
	string dfPath   = "root:VSANS_file"
	string filename = "Test_VSANS_file.h5"

	H_NXSANS_SaveGroupAsHDF5(dfPath, filename)
EndMacro

//
// this is my procedure to save the folders to HDF5, once I've filled the folder tree
//
// this does NOT save attributes, but gets the folder structure correct
//
// dfPath = local path, e.g., "root:FolderA" or ":"
Function H_NXSANS_SaveGroupAsHDF5(string dfPath, string filename)

	variable result = 0 // 0 means no error

	variable fileID
	PathInfo home
	if(V_flag == 1)
		HDF5CreateFile/P=home/O/Z fileID as filename
	else
		HDF5CreateFile/O/I/Z fileID as filename
	endif
	if(V_flag != 0)
		Print "HDF5CreateFile failed"
		return -1
	endif

	HDF5SaveGroup/IGOR=0/O/R/Z $dfPath, fileID, "."
	//	HDF5SaveGroup /O /R /Z $dfPath, fileID, "."
	if(V_flag != 0)
		Print "HDF5SaveGroup failed"
		result = -1
	endif

	HDF5CloseFile fileID

	return result
End

