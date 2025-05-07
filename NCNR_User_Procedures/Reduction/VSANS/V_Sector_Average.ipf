#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
// routines to do a sector average
//
// possible ideas:
// - start with calculation of the phi matrix for each panel
// - with the definition of the angle +/-, I can decide which points to keep during the average.
// - I can also make this an actual mask (sum with the protocol mask) and use it this way
//  so that I can still run it through the circular average routine.
// - I can also then overlay the sector mask onto the data (once I figure out how to overlay masks on
//  the regular data display

Function/WAVE V_MakePhiMatrix(WAVE qTotal, string folderStr, string detStr, string folderPath)

	variable xctr, yctr

	if(cmpstr(detStr, "B") == 0)
		//if "B", the center is already in pixels by definition, and x_pix, y_pix fields do not exist
		xctr = V_getDet_beam_center_x(folderStr, detStr)
		yctr = V_getDet_beam_center_y(folderStr, detStr)
	else
		xctr = V_getDet_beam_center_x_pix(folderStr, detStr)
		yctr = V_getDet_beam_center_y_pix(folderStr, detStr)
	endif

	Duplicate/O qTotal, $(folderPath + ":phi")
	WAVE phi = $(folderPath + ":phi")
	variable pixSizeX, pixSizeY
	pixSizeX = V_getDet_x_pixel_size(folderStr, detStr)
	pixSizeY = V_getDet_y_pixel_size(folderStr, detStr)
	MultiThread phi = V_FindPhi(pixSizeX * ((p + 1) - xctr), pixSizeY * ((q + 1) - yctr)) //(dx,dy)

	return phi
End

//
// x- I want to mask out everything that is "out" of the sector
//
// 0 = keep the point
// 1 = yes, mask the point
//
//
// phiCtr is in the range (-90,90) degrees
// delta is in the range (0,90) for a total width of 2*delta = 180 degrees
//
Function V_MarkSectorOverlayPixels(WAVE phi, WAVE overlay, variable phiCtr, variable delta, string side)

	variable phiVal

	// convert the imput from degrees to radians	, since phi is in radians
	phiCtr *= pi / 180
	delta  *= pi / 180

	variable xDim = DimSize(phi, 0)
	variable yDim = DimSize(phi, 1)

	variable ii, jj, exclude, mirror_phiCtr, crossZero, keepPix

	// initialize the mask to == 1 == exclude everything
	overlay = 1

	// now give every opportunity to keep pixel in
	// comparisons use a modified phiCtr to match the definition of the phi field (0= +x-axis)
	//
	for(ii = 0; ii < xDim; ii += 1)
		for(jj = 0; jj < yDim; jj += 1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			phiVal  = phi[ii][jj]
			keepPix = 0 //start with not keeping

			// if within the right or left, flag to keep the pixel
			if(cmpstr(side, "right") == 0)
				//right, when 0->pi/2
				if(V_CloseEnough(phiVal, phiCtr, delta))
					keepPix = 1
				endif
				// condition here to get the 3pi/2 -> 2pi region
				if(V_CloseEnough(phiVal, phiCtr + 2 * pi, delta))
					keepPix = 1
				endif
			endif

			if(cmpstr(side, "left") == 0)
				if(V_CloseEnough(phiVal, phiCtr + pi, delta))
					keepPix = 1
				endif
			endif

			//	both sides, duplicates the conditions above
			if(cmpstr(side, "both") == 0)
				//right, when 0->pi/2
				if(V_CloseEnough(phiVal, phiCtr, delta))
					keepPix = 1
				endif
				// right, when 3pi/2 -> 2pi
				if(V_CloseEnough(phiVal, phiCtr + 2 * pi, delta))
					keepPix = 1
				endif

				//left
				if(V_CloseEnough(phiVal, phiCtr + pi, delta))
					keepPix = 1
				endif

			endif

			// set the mask value (entire overlay initialized to 1 to start)
			if(keepPix > 0)
				overlay[ii][jj] = 0
			endif

		endfor
	endfor

	return (0)
End

//
// side = one of "left;right;both;"
// phi_rad = center of sector in radians
// dphi_rad = half-width of sector, also in radians
Function V_QBinAllPanels_Sector(string folderStr, variable binType, string collimationStr, string side, variable phi_rad, variable dphi_rad)

	// do the back, middle, and front separately

	//	figure out the binning type (where is it set?)
	variable ii, delQ
	string detStr

	//	binType = V_GetBinningPopMode()

	// set delta Q for binning (used later inside VC_fDoBinning_QxQy2D)
	for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")

		delQ = V_SetDeltaQ(folderStr, detStr) // this sets (overwrites) the global value for each panel type
	endfor

	switch(binType)
		case 1:
			V_fDoSectorBin_QxQy2D(folderStr, "FL", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FT", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "ML", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MT", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break
		case 2:
			V_fDoSectorBin_QxQy2D(folderStr, "FLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break
		case 3:
			V_fDoSectorBin_QxQy2D(folderStr, "MLRTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FLRTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break
		case 4: /// this is for a tall, narrow slit mode
			VC_fBinDetector_byRows(folderStr, "FL")
			VC_fBinDetector_byRows(folderStr, "FR")
			VC_fBinDetector_byRows(folderStr, "ML")
			VC_fBinDetector_byRows(folderStr, "MR")
			VC_fBinDetector_byRows(folderStr, "B")

			break
		case 5:
			V_fDoSectorBin_QxQy2D(folderStr, "FTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MLRTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break
		case 6:
			V_fDoSectorBin_QxQy2D(folderStr, "FLRTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break
		case 7:
			V_fDoSectorBin_QxQy2D(folderStr, "FTB", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "FLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "MLR", collimationStr, side, phi_rad, dphi_rad)
			V_fDoSectorBin_QxQy2D(folderStr, "B", collimationStr, side, phi_rad, dphi_rad)

			break

		default:
			Abort "Binning mode not found in V_QBinAllPanels_Circular" // when no case matches
	endswitch

	return (0)
End

//////////
//
//		Function that bins a 2D detctor panel into I(q) based on the q-value of the pixel
//		- each pixel QxQyQz has been calculated beforehand
//		- if multiple panels are selected to be combined, it is done here during the binning
//		- the setting of deltaQ step is still a little suspect (TODO)
//
//
// see the equivalent function in PlotUtils2D_v40.ipf
//
//Function fDoBinning_QxQy2D(inten,qx,qy,qz)
//
// this has been modified to accept different detector panels and to take arrays
// -- type = FL or FR or...other panel identifiers
//
//  "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
//
// updated Feb2016 to take new folder structure
// (DONE)
// x- VERIFY
// x- figure out what the best location is to put the averaged data? currently @ top level of WORK folder
//    but this is a lousy choice.
// x- binning is now Mask-aware. If mask is not present, all data is used. If data is from VCALC, all data is used
// x- Where do I put the solid angle correction? In here as a weight for each point, or later on as
//    a blanket correction (matrix multiply) for an entire panel? (Solid Angle correction is done in the
//    step where data is added to a WORK file (see Raw_to_Work())
//
//
// TODO:
// -- some of the input parameters for the resolution calcuation are either assumed (apOff) or are currently
//    hard-wired. these need to be corrected before even the pinhole resolution is correct
// x- resolution calculation is in the correct place. The calculation is done per-panel (specified by TYPE),
//    and then the unwanted points can be discarded (all 6 columns) as the data is trimmed and concatenated
//    is separate functions that are resolution-aware.
//
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
//
// side = one of "left;right;both;"
// phi_rad = center of sector in radians
// dphi_rad = half-width of sector, also in radians
//
Function V_fDoSectorBin_QxQy2D(string folderStr, string type, string collimationStr, string side, variable phi_rad, variable dphi_rad)

	variable nSets = 0
	variable xDim, yDim
	variable ii, jj
	variable qVal, nq, var, avesq, aveisq
	variable binIndex, val, maskMissing
	variable isVCALC = 0

	string folderPath = "root:Packages:NIST:VSANS:" + folderStr
	string instPath   = ":entry:instrument:detector_"
	string detStr

	if(cmpstr(folderStr, "VCALC") == 0)
		isVCALC = 1
	endif

	detStr = type

	// now switch on the type to determine which waves to declare and create
	// since there may be more than one panel to step through. There may be two, there may be four
	//

	// TODO:
	// -- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
	//
	// assume that the mask files are missing unless we can find them. If VCALC data,
	//  then the Mask is missing by definition
	maskMissing = 1

	strswitch(type) // string switch

		// only one panel, simply pick that panel and move on out of the switch
		case "FL": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FR": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FT": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FB": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "ML": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MR": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MT": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MB": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "B":
			if(isVCALC)
				WAVE   inten = $(folderPath + instPath + detStr + ":det_" + detStr)
				WAVE/Z iErr  = $("iErr_" + detStr) // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten = V_getDetectorDataW(folderStr, detStr)
				WAVE   iErr  = V_getDetectorDataErrW(folderStr, detStr)
				WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + detStr + ":data")
				if(WaveExists(mask) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ   = $(folderPath + instPath + detStr + ":gDelQ_" + detStr)
			WAVE qTotal = $(folderPath + instPath + detStr + ":qTot_" + detStr) // 2D q-values
			WAVE phi    = V_MakePhiMatrix(qTotal, folderStr, detStr, folderPath + instPath + detStr)
			nSets = 1
			break

		case "FLR":
			// detStr has multiple values now, so unfortuntely, I'm hard-wiring things...
			// TODO
			// -- see if I can un-hard-wire some of this below when more than one panel is combined
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FL" + ":det_" + "FL")
				WAVE/Z iErr   = $("iErr_" + "FL") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FR" + ":det_" + "FR")
				WAVE/Z iErr2  = $("iErr_" + "FR") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "FL")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "FL")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "FR")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "FR")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FL" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FR" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "FL" + ":gDelQ_FL")

			WAVE qTotal  = $(folderPath + instPath + "FL" + ":qTot_" + "FL") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FR" + ":qTot_" + "FR") // 2D q-values
			WAVE phi     = V_MakePhiMatrix(qTotal, folderStr, "FL", folderPath + instPath + "FL")
			WAVE phi2    = V_MakePhiMatrix(qTotal2, folderStr, "FR", folderPath + instPath + "FR")

			nSets = 2
			break

		case "FTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FT" + ":det_" + "FT")
				WAVE/Z iErr   = $("iErr_" + "FT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FB" + ":det_" + "FB")
				WAVE/Z iErr2  = $("iErr_" + "FB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "FT")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "FT")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "FB")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "FB")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FT" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FB" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "FT" + ":gDelQ_FT")

			WAVE qTotal  = $(folderPath + instPath + "FT" + ":qTot_" + "FT") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FB" + ":qTot_" + "FB") // 2D q-values

			WAVE phi  = V_MakePhiMatrix(qTotal, folderStr, "FT", folderPath + instPath + "FT")
			WAVE phi2 = V_MakePhiMatrix(qTotal2, folderStr, "FB", folderPath + instPath + "FB")

			nSets = 2
			break

		case "FLRTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FL" + ":det_" + "FL")
				WAVE/Z iErr   = $("iErr_" + "FL") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FR" + ":det_" + "FR")
				WAVE/Z iErr2  = $("iErr_" + "FR") // 2D errors -- may not exist, especially for simulation
				WAVE   inten3 = $(folderPath + instPath + "FT" + ":det_" + "FT")
				WAVE/Z iErr3  = $("iErr_" + "FT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten4 = $(folderPath + instPath + "FB" + ":det_" + "FB")
				WAVE/Z iErr4  = $("iErr_" + "FB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "FL")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "FL")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "FR")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "FR")
				WAVE   inten3 = V_getDetectorDataW(folderStr, "FT")
				WAVE   iErr3  = V_getDetectorDataErrW(folderStr, "FT")
				WAVE   inten4 = V_getDetectorDataW(folderStr, "FB")
				WAVE   iErr4  = V_getDetectorDataErrW(folderStr, "FB")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FL" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FR" + ":data")
				WAVE/Z mask3  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FT" + ":data")
				WAVE/Z mask4  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FB" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "FL" + ":gDelQ_FL")

			WAVE qTotal  = $(folderPath + instPath + "FL" + ":qTot_" + "FL") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FR" + ":qTot_" + "FR") // 2D q-values
			WAVE qTotal3 = $(folderPath + instPath + "FT" + ":qTot_" + "FT") // 2D q-values
			WAVE qTotal4 = $(folderPath + instPath + "FB" + ":qTot_" + "FB") // 2D q-values

			WAVE phi  = V_MakePhiMatrix(qTotal, folderStr, "FL", folderPath + instPath + "FL")
			WAVE phi2 = V_MakePhiMatrix(qTotal2, folderStr, "FR", folderPath + instPath + "FR")
			WAVE phi3 = V_MakePhiMatrix(qTotal3, folderStr, "FT", folderPath + instPath + "FT")
			WAVE phi4 = V_MakePhiMatrix(qTotal4, folderStr, "FB", folderPath + instPath + "FB")

			nSets = 4
			break

		case "MLR":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "ML" + ":det_" + "ML")
				WAVE/Z iErr   = $("iErr_" + "ML") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MR" + ":det_" + "MR")
				WAVE/Z iErr2  = $("iErr_" + "MR") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "ML")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "ML")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "MR")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "MR")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "ML" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MR" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "ML" + ":gDelQ_ML")

			WAVE qTotal  = $(folderPath + instPath + "ML" + ":qTot_" + "ML") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MR" + ":qTot_" + "MR") // 2D q-values

			WAVE phi  = V_MakePhiMatrix(qTotal, folderStr, "ML", folderPath + instPath + "ML")
			WAVE phi2 = V_MakePhiMatrix(qTotal2, folderStr, "MR", folderPath + instPath + "MR")

			nSets = 2
			break

		case "MTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "MT" + ":det_" + "MT")
				WAVE/Z iErr   = $("iErr_" + "MT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MB" + ":det_" + "MB")
				WAVE/Z iErr2  = $("iErr_" + "MB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "MT")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "MT")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "MB")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "MB")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MT" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MB" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "MT" + ":gDelQ_MT")

			WAVE qTotal  = $(folderPath + instPath + "MT" + ":qTot_" + "MT") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MB" + ":qTot_" + "MB") // 2D q-values

			WAVE phi  = V_MakePhiMatrix(qTotal, folderStr, "MT", folderPath + instPath + "MT")
			WAVE phi2 = V_MakePhiMatrix(qTotal2, folderStr, "MB", folderPath + instPath + "MB")

			nSets = 2
			break

		case "MLRTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "ML" + ":det_" + "ML")
				WAVE/Z iErr   = $("iErr_" + "ML") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MR" + ":det_" + "MR")
				WAVE/Z iErr2  = $("iErr_" + "MR") // 2D errors -- may not exist, especially for simulation
				WAVE   inten3 = $(folderPath + instPath + "MT" + ":det_" + "MT")
				WAVE/Z iErr3  = $("iErr_" + "MT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten4 = $(folderPath + instPath + "MB" + ":det_" + "MB")
				WAVE/Z iErr4  = $("iErr_" + "MB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE   inten  = V_getDetectorDataW(folderStr, "ML")
				WAVE   iErr   = V_getDetectorDataErrW(folderStr, "ML")
				WAVE   inten2 = V_getDetectorDataW(folderStr, "MR")
				WAVE   iErr2  = V_getDetectorDataErrW(folderStr, "MR")
				WAVE   inten3 = V_getDetectorDataW(folderStr, "MT")
				WAVE   iErr3  = V_getDetectorDataErrW(folderStr, "MT")
				WAVE   inten4 = V_getDetectorDataW(folderStr, "MB")
				WAVE   iErr4  = V_getDetectorDataErrW(folderStr, "MB")
				WAVE/Z mask   = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "ML" + ":data")
				WAVE/Z mask2  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MR" + ":data")
				WAVE/Z mask3  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MT" + ":data")
				WAVE/Z mask4  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MB" + ":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
					maskMissing = 0
				endif
			endif
			NVAR delQ = $(folderPath + instPath + "ML" + ":gDelQ_ML")

			WAVE qTotal  = $(folderPath + instPath + "ML" + ":qTot_" + "ML") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MR" + ":qTot_" + "MR") // 2D q-values
			WAVE qTotal3 = $(folderPath + instPath + "MT" + ":qTot_" + "MT") // 2D q-values
			WAVE qTotal4 = $(folderPath + instPath + "MB" + ":qTot_" + "MB") // 2D q-values

			WAVE phi  = V_MakePhiMatrix(qTotal, folderStr, "ML", folderPath + instPath + "ML")
			WAVE phi2 = V_MakePhiMatrix(qTotal2, folderStr, "MR", folderPath + instPath + "MR")
			WAVE phi3 = V_MakePhiMatrix(qTotal3, folderStr, "MT", folderPath + instPath + "MT")
			WAVE phi4 = V_MakePhiMatrix(qTotal4, folderStr, "MB", folderPath + instPath + "MB")

			nSets = 4
			break

		default: // FIXME(CodeStyleFallthroughCaseRequireComment)
			nSets = 0
			Print "ERROR   ---- type is not recognized "
	endswitch

	//	Print "delQ = ",delQ," for ",type

	if(nSets == 0)
		SetDataFolder root:
		return (0)
	endif

	// RAW data is currently read in and the 2D error wave is correctly generated
	// 2D error is propagated through all reduction steps,
	//
	//
	// IF ther is no 2D error wave present for some reason, make a fake one
	if(WaveExists(iErr) == 0 && WaveExists(inten) != 0)
		Duplicate/O inten, iErr
		WAVE iErr = iErr
		//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten + 0.75) // -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr2) == 0 && WaveExists(inten2) != 0)
		Duplicate/O inten2, iErr2
		WAVE iErr2 = iErr2
		//		iErr2 = 1+sqrt(inten2+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr2 = sqrt(inten2 + 0.75) // -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr3) == 0 && WaveExists(inten3) != 0)
		Duplicate/O inten3, iErr3
		WAVE iErr3 = iErr3
		//		iErr3 = 1+sqrt(inten3+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr3 = sqrt(inten3 + 0.75) // -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr4) == 0 && WaveExists(inten4) != 0)
		Duplicate/O inten4, iErr4
		WAVE iErr4 = iErr4
		//		iErr4 = 1+sqrt(inten4+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr4 = sqrt(inten4 + 0.75) // -- here I'm just using some fictional value
	endif

	// -- nq will need to be larger, once the back detector is installed
	//
	if(cmpstr(type, "B") == 0)
		nq = 8000
	else
		nq = 600
	endif

	// -- where to put the averaged data -- right now, folderStr is forced to ""
	//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...
	Make/O/D/N=(nq) $(folderPath + ":" + "iBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "qBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "nBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "iBin2_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "eBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "eBin2D_qxqy" + "_" + type)

	WAVE iBin_qxqy   = $(folderPath + ":" + "iBin_qxqy_" + type)
	WAVE qBin_qxqy   = $(folderPath + ":" + "qBin_qxqy" + "_" + type)
	WAVE nBin_qxqy   = $(folderPath + ":" + "nBin_qxqy" + "_" + type)
	WAVE iBin2_qxqy  = $(folderPath + ":" + "iBin2_qxqy" + "_" + type)
	WAVE eBin_qxqy   = $(folderPath + ":" + "eBin_qxqy" + "_" + type)
	WAVE eBin2D_qxqy = $(folderPath + ":" + "eBin2D_qxqy" + "_" + type)

	//	delQ = abs(sqrt(qx[2]^2+qy[2]^2+qz[2]^2) - sqrt(qx[1]^2+qy[1]^2+qz[1]^2))		//use bins of 1 pixel width
	// TODO: not sure if I want to set dQ in x or y direction...
	// the short dimension is the 8mm tubes, use this direction as dQ?
	// but don't use the corner of the detector, since dQ will be very different on T/B or L/R due to the location of [0,0]
	// WRT the beam center. use qx or qy directly. Still not happy with this way...

	qBin_qxqy[] = p * delQ
	SetScale/P x, 0, delQ, "", qBin_qxqy //allows easy binning

	iBin_qxqy   = 0
	iBin2_qxqy  = 0
	eBin_qxqy   = 0
	eBin2D_qxqy = 0
	nBin_qxqy   = 0 //number of intensities added to each bin

	// now there are situations of:
	// 1 panel
	// 2 panels
	// 4 panels
	//
	// this needs to be a double loop now...
	//
	//
	// The 1D error does not use iErr, and IS CALCULATED CORRECTLY
	//
	// x- the solid angle per pixel will be present for WORK data other than RAW, but not for RAW

	//
	// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
	if(maskMissing == 1)
		Print "Mask file not found for at least one detector - so all data is used"
	endif

	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(gIgnoreDetB && cmpstr(type, "B") == 0)
		maskMissing = 1
		Print "Mask skipped for B due to possible mismatch (Panel B ignored in preferences)"
	endif

	variable mask_val, phiVal, isIn
	// use set 1 (no number) only
	if(nSets >= 1)
		xDim = DimSize(inten, 0)
		yDim = DimSize(inten, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten[ii][jj]

				if(isVCALC || maskMissing) // mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
					mask_val = 0
				else
					mask_val = mask[ii][jj]
				endif

				phiVal = phi[ii][jj]
				isIn   = 0 // start with exclude, now see if it's a keeper

				// if within the right or left, flag to keep the pixel
				if(cmpstr(side, "right") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// condition here to get the 3pi/2 -> 2pi region
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif
				endif

				if(cmpstr(side, "left") == 0)
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif
				endif

				//	both sides, duplicates the conditions above
				if(cmpstr(side, "both") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// right, when 3pi/2 -> 2pi
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif

					//left
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif

				endif //end the check of phiVal within sector and side

				if(numType(val) == 0 && mask_val == 0 && isIn > 0) //count only the good points, in the sector, and ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr[ii][jj] * iErr[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif

			endfor
		endfor

	endif

	// add in set 2 (set 1 already done)
	if(nSets >= 2)
		xDim = DimSize(inten2, 0)
		yDim = DimSize(inten2, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal2[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten2[ii][jj]

				if(isVCALC || maskMissing)
					mask_val = 0
				else
					mask_val = mask2[ii][jj]
				endif

				phiVal = phi2[ii][jj]
				isIn   = 0 // start with exclude, now see if it's a keeper

				// if within the right or left, flag to keep the pixel
				if(cmpstr(side, "right") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// condition here to get the 3pi/2 -> 2pi region
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif
				endif

				if(cmpstr(side, "left") == 0)
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif
				endif

				//	both sides, duplicates the conditions above
				if(cmpstr(side, "both") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// right, when 3pi/2 -> 2pi
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif

					//left
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif

				endif //end the check of phiVal within sector and side

				if(numType(val) == 0 && mask_val == 0 && isIn > 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr2[ii][jj] * iErr2[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

	endif

	// add in set 3 and 4 (set 1 and 2 already done)
	if(nSets == 4)
		xDim = DimSize(inten3, 0)
		yDim = DimSize(inten3, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal3[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten3[ii][jj]

				if(isVCALC || maskMissing)
					mask_val = 0
				else
					mask_val = mask3[ii][jj]
				endif

				phiVal = phi3[ii][jj]
				isIn   = 0 // start with exclude, now see if it's a keeper

				// if within the right or left, flag to keep the pixel
				if(cmpstr(side, "right") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// condition here to get the 3pi/2 -> 2pi region
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif
				endif

				if(cmpstr(side, "left") == 0)
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif
				endif

				//	both sides, duplicates the conditions above
				if(cmpstr(side, "both") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// right, when 3pi/2 -> 2pi
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif

					//left
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif

				endif //end the check of phiVal within sector and side

				if(numType(val) == 0 && mask_val == 0 && isIn > 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr3[ii][jj] * iErr3[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

		xDim = DimSize(inten4, 0)
		yDim = DimSize(inten4, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal4[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten4[ii][jj]

				if(isVCALC || maskMissing)
					mask_val = 0
				else
					mask_val = mask4[ii][jj]
				endif

				phiVal = phi4[ii][jj]
				isIn   = 0 // start with exclude, now see if it's a keeper

				// if within the right or left, flag to keep the pixel
				if(cmpstr(side, "right") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// condition here to get the 3pi/2 -> 2pi region
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif
				endif

				if(cmpstr(side, "left") == 0)
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif
				endif

				//	both sides, duplicates the conditions above
				if(cmpstr(side, "both") == 0)
					//right, when 0->pi/2
					if(V_CloseEnough(phiVal, phi_rad, dphi_rad))
						isIn = 1
					endif
					// right, when 3pi/2 -> 2pi
					if(V_CloseEnough(phiVal, phi_rad + 2 * pi, dphi_rad))
						isIn = 1
					endif

					//left
					if(V_CloseEnough(phiVal, phi_rad + pi, dphi_rad))
						isIn = 1
					endif

				endif //end the check of phiVal within sector and side

				if(numType(val) == 0 && mask_val == 0 && isIn > 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr4[ii][jj] * iErr4[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

	endif

	// after looping through all of the data on the panels, calculate errors on I(q),
	// just like in CircSectAve.ipf

	// x- 2D Errors are properly acculumated through reduction
	// x- the error on the 1D intensity, is correctly calculated as the standard error of the mean.
	for(ii = 0; ii < nq; ii += 1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii]   = 0
			eBin_qxqy[ii]   = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii]   /= nBin_qxqy[ii]
				eBin_qxqy[ii]    = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				//  -- this is correctly calculating the error as the standard error of the mean, as
				//    was always done for SANS as well.
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq          = iBin_qxqy[ii]^2
				aveisq         = iBin2_qxqy[ii] / nBin_qxqy[ii]
				var            = aveisq - avesq
				if(var <= 0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var / (nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor

	eBin2D_qxqy = sqrt(eBin2D_qxqy) // as equation (3) of John's memo

	// find the last non-zero point, working backwards
	val = nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)

	//	print val, nBin_qxqy[val]
	DeletePoints val, nq - val, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy

	if(val == 0)
		// all the points were deleted, make dummy waves for resolution
		Make/O/D/N=0 $(folderPath + ":" + "sigmaQ_qxqy" + "_" + type)
		Make/O/D/N=0 $(folderPath + ":" + "qBar_qxqy" + "_" + type)
		Make/O/D/N=0 $(folderPath + ":" + "fSubS_qxqy" + "_" + type)
		return (0)
	endif

	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)
	DeletePoints 0, val, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy) - 1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy
		endif
		val -= 1
	while(val > 0)

	// utility function to remove NaN values from the waves
	V_RemoveNaNsQIS(qBin_qxqy, iBin_qxqy, eBin_qxqy)

	// -- This is where I calculate the resolution in SANS (see CircSectAve)
	// -- use the isVCALC flag to exclude VCALC from the resolution calculation if necessary
	// -- from the top of the function, folderStr = work folder, type = "FLRTB" or other type of averaging
	//
	nq = numpnts(qBin_qxqy)
	Make/O/D/N=(nq) $(folderPath + ":" + "sigmaQ_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "qBar_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "fSubS_qxqy" + "_" + type)
	WAVE sigmaq = $(folderPath + ":" + "sigmaQ_qxqy_" + type)
	WAVE qbar   = $(folderPath + ":" + "qBar_qxqy_" + type)
	WAVE fsubs  = $(folderPath + ":" + "fSubS_qxqy_" + type)
	variable ret1, ret2, ret3

	// all of the different collimation conditions are handled within the V_getResolution function
	// which is responsible for switching based on the different collimation types (white beam, slit, Xtal, etc)
	// to calculate the correct resolution, or fill the waves with the correct "flags"
	//

	// For white beam data, the wavelength distribution can't be represented as a gaussian, but all of the other
	//  geometric corrections still apply. Passing zero for the lambdaWidth will return the geometry contribution,
	//  as long as the wavelength can be handled separately. It appears to be correct to do as a double integral,
	//  with the inner(lambda) calculated first, then the outer(geometry).
	//

	// possible values are:
	//
	// pinhole
	// pinhole_whiteBeam
	// convergingPinholes
	//
	// *slit data should be reduced using the slit routine, not here, proceed but warn
	// narrowSlit
	// narrowSlit_whiteBeam
	//
	ii = 0
	do
		V_getResolution(qBin_qxqy[ii], folderStr, type, collimationStr, ret1, ret2, ret3)
		sigmaq[ii] = ret1
		qbar[ii]   = ret2
		fsubs[ii]  = ret3
		ii        += 1
	while(ii < nq)

	SetDataFolder root:

	return (0)
End

