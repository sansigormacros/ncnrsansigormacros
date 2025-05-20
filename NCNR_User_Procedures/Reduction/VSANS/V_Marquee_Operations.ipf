#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// TODO:
// x- get BoxSum Operational, for rudimentary Transmission calculations and ABS scale
// x- need to be able to identify the detector panel from the Marquee selection
// x- then do the count in (unscaled) coordinates of the actual data array
//
//
// -- still many operations in (SANS)Marquee.ipf that will be useful to implement:
//
// -- writing the box coordinates and the counts (and error) to the data file
// x- determining the beam center (centroid) of the selection
//  -- writing beam center (centroid) to the file?
//  -- a box sum over a range of files (with a plot)
// -- box sum over annular regions
// -- box sum over arcs
// --  saving Graphics image
// -- histogram of the counts
//
//
//

//
//function will print marquee coordinates in axis terms, not detector terms
//
// will also calculate the sum in the box, and the error, and print it out
//
Function V_PrintMarqueeCoords() : GraphMarquee

	GetMarquee left, bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		variable count, x1, x2, y1, y2, ct_err
		x1 = V_left
		x2 = V_right
		y1 = V_bottom
		y2 = V_top
		printf "marquee left in bottom axis terms: %g\r", round(V_left)
		printf "marquee right in bottom axis terms: %g\r", round(V_right)
		printf "marquee bottom in left axis terms: %g\r", round(V_bottom)
		printf "marquee top in left axis terms: %g\r", round(V_top)
		//		printf "**note that you must add 1 to each axis coordinate to get detector coordinates\r"

		// NOTE:
		// this function MODIFIES x and y values on return, converting them to panel coordinates
		// detector panel is identified from the (left,top) coordinate (x1,y2)
		string detStr = V_FindDetStrFromLoc(x1, x2, y1, y2)
		//		Printf "Detector = %s\r",detStr

		//
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(x1, x2, y1, y2, detStr, gCurDispType)
		Printf "%d;%d;%d;%d;\r", x1, x2, y1, y2

		count = V_SumCountsInBox(x1, x2, y1, y2, ct_err, gCurDispType, detStr)

		Print "total counts = ", count
		Print "err/counts = ", ct_err / count
		print "average counts per pixel = ", count / (x2 - x1) / (y2 - y1)
	endif
End

// NOTE:
// this function MODIFIES x and y values on return, converting them to panel coordinates
// detector panel is identified from the (left,top) coordinate (x1,y2)
Function/S V_FindDetStrFromLoc(variable &x1, variable &x2, variable &y1, variable &y2)

	// which images are here?
	string imStr, carriageStr
	string detStr = ""
	string currentImageRef, activeSubwindow, imageList
	variable ii, nIm, testX, testY, tab

	// which tab is selected? -this is the main graph panel (subwindow may not be the active one!)
	ControlInfo/W=VSANS_Data tab0
	tab = V_Value
	if(tab == 0)
		activeSubwindow = "VSANS_Data#det_panelsF"
	elseif(tab == 1)
		activeSubwindow = "VSANS_Data#det_panelsM"
	else
		activeSubwindow = "VSANS_Data#det_panelsB"
	endif

	imageList = ImageNameList(activeSubwindow, ";")

	nIm = ItemsInList(imageList, ";")
	if(nIm == 0)
		return ("") //problem, get out
	endif

	// images were added in the order TBLR, so look back through in the order RLBT, checking each to see if
	// the xy value is found on that (scaled) array

	// loop backwards through the list of panels (may only be one if on the back)
	for(ii = nIm - 1; ii >= 0; ii -= 1)
		WAVE w = ImageNameToWaveRef(activeSubwindow, StringFromList(ii, imageList, ";"))

		// which, if any image is the mouse xy location on?
		// use a multidemensional equivalent to x2pnt: (ScaledDimPos - DimOffset(waveName, dim))/DimDelta(waveName,dim)

		testX = ScaleToIndex(w, x1, 0)
		testY = ScaleToIndex(w, y2, 1)

		if((testX >= 0 && testX < DimSize(w, 0)) && (testY >= 0 && testY < DimSize(w, 1)))
			// we're in-bounds on this wave

			// deduce the detector panel
			currentImageRef = StringFromList(ii, imageList, ";") //the image instance ##
			// string is "data", or "data#2" etc. - so this returns "", "1", "2", or "3"
			imStr       = StringFromList(1, currentImageRef, "#")
			carriageStr = activeSubWindow[strlen(activeSubWindow) - 1]

			if(cmpstr(carriageStr, "B") == 0)
				detStr = carriageStr
			else
				if(strlen(imStr) == 0)
					imStr = "9" // a dummy value so I can replace it later
				endif
				detStr = carriageStr + imStr             // "F2" or something similar
				detStr = ReplaceString("9", detStr, "T") // ASSUMPTION :::: instances 0123 correspond to TBLR
				detStr = ReplaceString("1", detStr, "B") // ASSUMPTION :::: this is the order that the panels
				detStr = ReplaceString("2", detStr, "L") // ASSUMPTION :::: are ALWAYS added to the graph
				detStr = ReplaceString("3", detStr, "R") // ASSUMPTION ::::
			endif

			Printf "Detector panel %s=(%d,%d)\r", detStr, testX, testY

			x1 = ScaleToIndex(w, x1, 0) // get all four marquee values to pass back to the calling function
			x2 = ScaleToIndex(w, x2, 0) // converted into detector coordinates
			y1 = ScaleToIndex(w, y1, 1)
			y2 = ScaleToIndex(w, y2, 1)

			ii = -1 //look no further, set ii to bad value to exit the for loop

		endif

	endfor

	return (detStr)

End

//testing function only, not called anywhere
Function V_testKeepInBounds(variable x1, variable x2, variable y1, variable y2, string detStr, string folderStr)

	V_KeepSelectionInBounds(x1, x2, y1, y2, detStr, folderStr)
	Print x1, x2, y1, y2
	return (0)
End

// for the given detector
Function V_KeepSelectionInBounds(variable &x1, variable &x2, variable &y1, variable &y2, string detStr, string folderStr)

	variable pixelsX = V_getDet_pixel_num_x(folderStr, detStr)
	variable pixelsY = V_getDet_pixel_num_y(folderStr, detStr)

	//keep selection in-bounds
	x1 = (round(x1) >= 0) ? round(x1) : 0
	x2 = (round(x2) <= (pixelsX - 1)) ? round(x2) : (pixelsX - 1)
	y1 = (round(y1) >= 0) ? round(y1) : 0
	y2 = (round(y2) <= (pixelsY - 1)) ? round(y2) : (pixelsY - 1)

	return (0)
End

//sums the data counts in the box specified by (x1,y1) to (x2,y2)
//assuming that x1<x2, and y1<y2
//the x,y values must also be in array coordinates[0] NOT scaled detector coords.
//
// accepts arbitrary detector coordinates. calling function is responsible for
// keeping selection in bounds
//
Function V_SumCountsInBox(variable x1, variable x2, variable y1, variable y2, variable &ct_err, string type, string detStr)

	variable ii, jj, err2_sum
	variable counts = 0

	// get the waves of the data and the data_err
	WAVE w        = V_getDetectorDataW(type, detStr)
	WAVE data_err = V_getDetectorDataErrW(type, detStr)

	err2_sum = 0 // running total of the squared error
	ii       = x1
	jj       = y1
	do
		do
			counts   += w[ii][jj]
			err2_sum += data_err[ii][jj] * data_err[ii][jj]
			jj       += 1
		while(jj <= y2)
		jj  = y1
		ii += 1
	while(ii <= x2)

	err2_sum = sqrt(err2_sum)
	ct_err   = err2_sum

	//	Print "error = ",ct_err
	//	Print "error/counts = ",ct_err/counts

	return (counts)
End

//sums the data counts in the box specified by (x1,y1) to (x2,y2)
//assuming that x1<x2, and y1<y2
//the x,y values must also be in array coordinates[0] NOT scaled detector coords.
//
// accepts arbitrary detector coordinates. calling function is responsible for
// keeping selection in bounds
//
// basically the same as V_SumCountsInBox, except the PBR value has been removed so that the
// function can be used from the command line
//
Function V_SumCountsInBox_Cmd(variable x1, variable x2, variable y1, variable y2, string type, string detStr)

	variable ii, jj, err2_sum, ct_err
	variable counts = 0

	// get the waves of the data and the data_err
	WAVE w        = V_getDetectorDataW(type, detStr)
	WAVE data_err = V_getDetectorDataErrW(type, detStr)

	err2_sum = 0 // running total of the squared error
	ii       = x1
	jj       = y1
	do
		do
			counts   += w[ii][jj]
			err2_sum += data_err[ii][jj] * data_err[ii][jj]
			jj       += 1
		while(jj <= y2)
		jj  = y1
		ii += 1
	while(ii <= x2)

	err2_sum = sqrt(err2_sum)
	ct_err   = err2_sum

	Print "sum of counts = ", counts
	Print "error = ", ct_err
	Print "error/counts = ", ct_err / counts

	return (counts)
End

Proc pV_SumCountsInBox_Cmd(x1, x2, y1, y2, type, detStr)
	variable x1     = 280
	variable x2     = 430
	variable y1     = 350
	variable y2     = 1020
	string   type   = "RAW"
	string   detStr = "B"

	V_SumCountsInBox_Cmd(x1, x2, y1, y2, type, detStr)
EndMacro

Function V_Find_BeamCentroid() : GraphMarquee

	//	//get the current displayed data (so the correct folder is used)
	//	SVAR cur_folder=root:myGlobals:gDataDisplayType
	//	String dest = "root:Packages:NIST:" + cur_folder

	variable xzsum, yzsum, zsum, xctr, yctr
	variable left, right, bottom, top, ii, jj, counts
	variable x_mm_sum, y_mm_sum, x_mm, y_mm
	variable xRef, yRef

	GetMarquee left, bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		left   = round(V_left) //get integer values for selection limits
		right  = round(V_right)
		top    = round(V_top)
		bottom = round(V_bottom)

		// detector panel is identified from the (left,top) coordinate (x1,y2)
		string detStr = V_FindDetStrFromLoc(left, right, bottom, top)
		//	Printf "Detector = %s\r",detStr

		//
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(left, right, bottom, top, detStr, gCurDispType)

		Print left, right, bottom, top

		// selection valid now, calculate beamcenter
		// get the waves of the data and the data_err
		WAVE data     = V_getDetectorDataW(gCurDispType, detStr)
		WAVE data_err = V_getDetectorDataErrW(gCurDispType, detStr)

		// get the real-space information
		string destPath       = "root:Packages:NIST:VSANS:" + gCurDispType
		WAVE   data_realDistX = $(destPath + ":entry:instrument:detector_" + detStr + ":data_realDistX")
		WAVE   data_realDistY = $(destPath + ":entry:instrument:detector_" + detStr + ":data_realDistY")

		xzsum    = 0
		yzsum    = 0
		zsum     = 0
		x_mm_sum = 0
		y_mm_sum = 0

		//
		// NOTE: SEP 2020. The ii,jj indices for this loop can start at zero if using the
		//  original definition and tube values, Then the index*count would be weighted as zero.
		//
		// re-wrote the multiplier in the loop to add one to the index before multiplying,
		// then subtract 1 from the final centroid to get back to the basis of 0->(n-1). The
		// ii,jj index values don't need to be changed.
		//

		// count over rectangular selection, doing each row, L-R, bottom to top
		ii = bottom - 1
		do
			ii += 1
			jj  = left - 1
			do
				jj    += 1
				counts = data[jj][ii]
				xzsum += (jj + 1) * counts
				yzsum += (ii + 1) * counts
				zsum  += counts

				x_mm_sum += data_realDistX[jj][ii] * counts
				y_mm_sum += data_realDistY[jj][ii] * counts
			while(jj < right)
		while(ii < top)
		//		Print "xzsum = ",xzsum
		//		Print "yzsum = ",yzsum
		//		Print "zsum = ",zsum

		xctr = xzsum / zsum - 1
		yctr = yzsum / zsum - 1

		x_mm = x_mm_sum / zsum
		y_mm = y_mm_sum / zsum
		// add 1 to each to get to detector coordinates (1,128)
		// rather than the data array which is [0,127]
		//		xctr+=1
		//		yctr+=1

		Print "X-center (in array coordinates 0->n-1 ) = ", xctr
		Print "Y-center (in array coordinates 0->n-1 ) = ", yctr

		Print "X-center (cm) = ", x_mm / 10
		Print "Y-center (cm) = ", y_mm / 10



		// correct for the zero position (y-position) on the L/R panels not being exactly equal
		// the lateral scan data from Dec 2018 is used to correct this. The span of zero points
		// is relatively small (+- 0.5 pixel) but is significant for data using graphite monochromator
		//
		//
		// March 2025: I have updated the calculation to use the real-space postion as calculated from the non-linear
		// corrections. up until now, they have been treated as "perfect" values.
		//
		// the "manual" correction here is still done, but with "perfect" zero point values so that the calculation
		// is not altered. If someone needs to do a maual calculation, it can be done by switching to the
		// correct zero point tables.
		//
		// constants have also been defined for the tube reference values so that they are no longer hard-coded
		// constants are defined in V_TubeAdjustments.ipf
		//
		if(cmpstr(detStr,"B") != 0 )
			// then we're on F or M, so check for the tube correction
			
			// check that the correction waves exist, if not, generate them V_TubeZeroPointTables()
	
			// overwrite the correction waves every time since I have introduced the perfect table
			// -- Look at the global to see if tables are to be used (change with VSANS menu option)
			NVAR gUseTables = root:Packages:NIST:VSANS:Globals:gUseZeroPointTables
	
			// --OR--
			// Programmatically determine if the zero point tables are needed
			//	by checking the average value of the first row of the calibration table. for FR, this
			// is  == -521 if "perfect"
			WaveStats/RMD=[0, 0]/Q root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FR:spatial_calibration
	
			//	Print V_avg
			if(V_avg != -521)
				gUseTables = 0
			else
				gUseTables = 1
			endif
	
			//		if(!WaveExists(tube_num))
			if(gUseTables == 1)
				Execute "V_TubeZeroPointTables()"
				Print "Using the built-in zero point tables"
			else
				Execute "V_TubeZeroPointTables_Perfect()"
				Print "NOT using the built-in zero-point tables. Calibration tables used instead"
			endif
	
			WAVE/Z tube_num  = $("root:Packages:NIST:VSANS:Globals:tube_" + detStr)
			WAVE/Z yCtr_tube = $("root:Packages:NIST:VSANS:Globals:yCtr_" + detStr)
			//		endif
	
			variable yCorrection = interp(xCtr, tube_num, yCtr_tube)
			variable yPixSize    = V_getDet_y_pixel_size(gCurDispType, detStr)
			yPixSize /= 10 // convert mm to cm
			// Zero point offsets were determined in Dec 2018 using:
			// FR tube # 7 = 61.70 pix = k_FR_tube_ZeroPoint
			// MR tube # 10 = 61.94 pix = k_MR_tube_ZeroPoint
	
	
			if(cmpstr(detStr, "FR") == 0)
				Print "Reference Y-Center is corrected for FR tube #7 zero position"
	
				yCorrection = k_FR_tube_ZeroPoint - yCorrection
				Print "yCorrection (pix) = ", yCorrection
				Print "yCorrection (cm) = ", yCorrection * yPixSize
				xRef = x_mm / 10
				yRef = y_mm / 10 + yCorrection * yPixSize
				Print "FRONT Reference X-center (cm) = ", xRef
				Print "FRONT Reference Y-center (cm) = ", yRef
	
			endif
	
			if(cmpstr(detStr, "MR") == 0)
				Print "Reference Y-Center is corrected for MR tube #10 zero position"
	
				yCorrection = k_MR_tube_ZeroPoint - yCorrection
				Print "yCorrection (pix) = ", yCorrection
				Print "yCorrection (cm) = ", yCorrection * yPixSize
				xRef = x_mm / 10
				yRef = y_mm / 10 + yCorrection * yPixSize
				Print "MIDDLE Reference X-center (cm) = ", xRef
				Print "MIDDLE Reference Y-center (cm) = ", yRef
	
			endif
	
			// if measured on the LEFT panel, convert to the RIGHT coordinates for the reference value
			// these corrections are exactly the opposite (subtract, not add) of what is done in V_fDeriveBeamCenters(xFR,yFR,xMR,yMR)
			// since we're "un"-correcting the delta
			
			// since the lateral scans to determine the relative centers were done at the same time
			// the pixel values for the zero are on the same y-level, set by the beam height
			//
			
			// MAY 2025
			// add in condition to use delta value for Narrow Slits if that is the crrent collimation
			//
			Variable delta_ML_x
			Variable delta_FL_x
			if(cmpstr(V_getNumberOfGuides(gCurDispType),"NARROW_SLITS") == 0)
				// returns NARROW_SLITS if in beam - other returns all use pinhole deltas
				delta_ML_x = kBCtrDelta_ML_x_NS
				delta_FL_x = kBCtrDelta_FL_x_NS
			else
				delta_ML_x = kBCtrDelta_ML_x
				delta_FL_x = kBCtrDelta_FL_x
			endif
			
			if(cmpstr(detStr, "FL") == 0)
				Print "Reference Y-Center is corrected for FR tube #7 zero position"
	
				yCorrection = k_FR_tube_ZeroPoint - yCorrection
				Print "yCorrection (pix) = ", yCorrection
				Print "yCorrection (cm) = ", yCorrection * yPixSize
				xRef = x_mm / 10 - delta_FL_x
				yRef = y_mm / 10 - kBCtrDelta_FL_y + yCorrection * yPixSize
				Print "FRONT Reference X-center (cm) = ", xRef // NEW Dec 2018 values
				Print "FRONT Reference Y-center (cm) = ", yRef
	
			endif
	
			if(cmpstr(detStr, "ML") == 0)
				Print "Reference Y-Center is corrected for MR tube #10 zero position"
	
				yCorrection = k_MR_tube_ZeroPoint - yCorrection
				Print "yCorrection (pix) = ", yCorrection
				Print "yCorrection (cm) = ", yCorrection * yPixSize
				xRef = x_mm / 10 - delta_ML_x
				yRef = y_mm / 10 - kBCtrDelta_ML_y + yCorrection * yPixSize
				Print "MIDDLE Reference X-center (cm) = ", xRef
				Print "MIDDLE Reference Y-center (cm) = ", yRef
	
			endif
		endif // specific to F and M carriages

	endif		


	// TODO
	// ?? store the xy reference values somewhere so that the conversion to proper
	// beam center values can be done automatically, rather than copying numbers into a procedure
	//
	// - either I need 6 globals for the three panels, or I need to store the values in the
	// reduction block of the file (comment?) - but I don't have the fileName here - could I find it
	// somewhere? gFileList in the current data folder?
	//
	string ctrStr = ""
	if(cmpstr(detStr, "B") == 0)
		xRef = xCtr
		yRef = yCtr //these are in pixels
	endif
	sprintf ctrStr, "XREF=%g;YREF=%g;PANEL=%s;", xRef, yRef, detStr
	SVAR gFileList = $("root:Packages:NIST:VSANS:" + gCurDispType + ":gFileList")

	V_writeReductionComments(gFileList, ctrStr)

	V_UpdateBoxCoords()

	//back to root folder (redundant)
	SetDataFolder root:

End

//
//function writes new box coordinates to the data file
//
// also writes the panel where the coordinates were set (non-nice field in /reduction)
//
Function V_UpdateBoxCoords() : GraphMarquee

	GetMarquee left, bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		variable count, x1, x2, y1, y2, ct_err
		x1 = V_left
		x2 = V_right
		y1 = V_bottom
		y2 = V_top

		//		Print x1,x2,y1,y2

		// NOTE:
		// this function MODIFIES x and y values on return, converting them to panel coordinates
		// detector panel is identified from the (left,top) coordinate (x1,y2)
		string detStr = V_FindDetStrFromLoc(x1, x2, y1, y2)
		//
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
		string boxStr
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(x1, x2, y1, y2, detStr, gCurDispType)
		sprintf boxStr, "%d;%d;%d;%d;", x1, x2, y1, y2

		//		Print x1,x2,y1,y2

		SVAR gCurrentFile = root:Packages:NIST:VSANS:Globals:gLastLoadedFile //for the status of the display

		V_writeBoxCoordinates(gCurrentFile, V_List2NumWave(boxStr, ";", "inW"))

		V_writeReduction_BoxPanel(gCurrentFile, detStr)

		//		count = V_SumCountsInBox(x1,x2,y1,y2,ct_err,gCurDispType,detStr)
		//		Print "counts = ",count
		//		Print "err/counts = ",ct_err/count

		// kill the file from RawVSANS so that the updated box coordinates will be re-read in
		//
		V_KillNamedDataFolder(gCurrentFile)
	endif
End
