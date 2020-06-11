#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


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
Function V_PrintMarqueeCoords() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		Variable count,x1,x2,y1,y2,ct_err
		x1 = V_left
		x2 = V_right
		y1 = V_bottom
		y2 = V_top
		printf "marquee left in bottom axis terms: %g\r",round(V_left)
		printf "marquee right in bottom axis terms: %g\r",round(V_right)
		printf "marquee bottom in left axis terms: %g\r",round(V_bottom)
		printf "marquee top in left axis terms: %g\r",round(V_top)
//		printf "**note that you must add 1 to each axis coordinate to get detector coordinates\r"
		
		// NOTE:
		// this function MODIFIES x and y values on return, converting them to panel coordinates
		// detector panel is identified from the (left,top) coordinate (x1,y2)
		String detStr = V_FindDetStrFromLoc(x1,x2,y1,y2)		
//		Printf "Detector = %s\r",detStr

// 
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType	
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(x1,x2,y1,y2,detStr,gCurDispType)
		Printf "%d;%d;%d;%d;\r",x1,x2,y1,y2


		count = V_SumCountsInBox(x1,x2,y1,y2,ct_err,gCurDispType,detStr)

		
		Print "total counts = ",count
		Print "err/counts = ",ct_err/count
		print "average counts per pixel = ",count/(x2-x1)/(y2-y1)
	endif
End


// NOTE:
// this function MODIFIES x and y values on return, converting them to panel coordinates
// detector panel is identified from the (left,top) coordinate (x1,y2)
Function/S V_FindDetStrFromLoc(x1,x2,y1,y2)
	Variable &x1,&x2,&y1,&y2
	
	// which images are here?
	String detStr="",imStr,carriageStr
	String currentImageRef,activeSubwindow,imageList
	Variable ii,nIm,testX,testY,tab
	
	// which tab is selected? -this is the main graph panel (subwindow may not be the active one!)
	ControlInfo/W=VSANS_Data tab0
	tab = V_Value
	if(tab == 0)
		activeSubwindow = "VSANS_Data#det_panelsF"
	elseif (tab == 1)
		activeSubwindow = "VSANS_Data#det_panelsM"
	else
		activeSubwindow = "VSANS_Data#det_panelsB"
	endif
	
	imageList = ImageNameList(activeSubwindow,";")	

	nIm = ItemsInList(imageList,";")
	if(nIm==0)
		return("")		//problem, get out
	endif

	// images were added in the order TBLR, so look back through in the order RLBT, checking each to see if
	// the xy value is found on that (scaled) array
				
	// loop backwards through the list of panels (may only be one if on the back)
	for(ii=nIm-1;ii>=0;ii-=1)
		Wave w = ImageNameToWaveRef(activeSubwindow,StringFromList(ii, imageList,";"))
		
		// which, if any image is the mouse xy location on?
		// use a multidemensional equivalent to x2pnt: (ScaledDimPos - DimOffset(waveName, dim))/DimDelta(waveName,dim)

		
		testX = ScaleToIndex(w,x1,0)
		testY = ScaleToIndex(w,y2,1)
		
		if( (testX >= 0 && testX < DimSize(w,0)) && (testY >= 0 && testY < DimSize(w,1)) )
			// we're in-bounds on this wave
			
			// deduce the detector panel
			currentImageRef = StringFromList(ii, imageList,";")	//the image instance ##
			// string is "data", or "data#2" etc. - so this returns "", "1", "2", or "3"
			imStr = StringFromList(1, currentImageRef,"#")		
			carriageStr = activeSubWindow[strlen(activeSubWindow)-1]
			
			if(cmpstr(carriageStr,"B")==0)
				detStr = carriageStr
			else
				if(strlen(imStr)==0)
					imStr = "9"			// a dummy value so I can replace it later
				endif
				detStr = carriageStr+imStr		// "F2" or something similar
				detStr = ReplaceString("9", detStr, "T") 	// ASSUMPTION :::: instances 0123 correspond to TBLR
				detStr = ReplaceString("1", detStr, "B") 	// ASSUMPTION :::: this is the order that the panels
				detStr = ReplaceString("2", detStr, "L") 	// ASSUMPTION :::: are ALWAYS added to the graph
				detStr = ReplaceString("3", detStr, "R") 	// ASSUMPTION :::: 
			endif
			
			Printf "Detector panel %s=(%d,%d)\r",detStr,testX,testY
			
			x1 = ScaleToIndex(w,x1,0)		// get all four marquee values to pass back to the calling function
			x2 = ScaleToIndex(w,x2,0)		// converted into detector coordinates
			y1 = ScaleToIndex(w,y1,1)
			y2 = ScaleToIndex(w,y2,1)
			
			
			ii = -1		//look no further, set ii to bad value to exit the for loop

		endif
		
	endfor
	
	return(detStr)
	
End

//testing function only, not called anywhere
Function V_testKeepInBounds(x1,x2,y1,y2,detStr,folderStr)
	Variable x1,x2,y1,y2
	String detStr,folderStr
	
	V_KeepSelectionInBounds(x1,x2,y1,y2,detStr,folderStr)
	Print x1,x2,y1,y2
	return(0)
End

// for the given detector
Function V_KeepSelectionInBounds(x1,x2,y1,y2,detStr,folderStr)
	Variable &x1,&x2,&y1,&y2
	String detStr,folderStr
	
	Variable pixelsX = V_getDet_pixel_num_x(folderStr,detStr)
	Variable pixelsY = V_getDet_pixel_num_y(folderStr,detStr)

	//keep selection in-bounds
	x1 = (round(x1) >= 0) ? round(x1) : 0
	x2 = (round(x2) <= (pixelsX-1)) ? round(x2) : (pixelsX-1)
	y1 = (round(y1) >= 0) ? round(y1) : 0
	y2 = (round(y2) <= (pixelsY-1)) ? round(y2) : (pixelsY-1)
	
	return(0)
End



//sums the data counts in the box specified by (x1,y1) to (x2,y2)
//assuming that x1<x2, and y1<y2 
//the x,y values must also be in array coordinates[0] NOT scaled detector coords.
//
// accepts arbitrary detector coordinates. calling function is responsible for 
// keeping selection in bounds
//
Function V_SumCountsInBox(x1,x2,y1,y2,ct_err,type,detStr)
	Variable x1,x2,y1,y2,&ct_err
	String type,detStr
	
	Variable counts = 0,ii,jj,err2_sum
	
// get the waves of the data and the data_err
	Wave w = V_getDetectorDataW(type,detStr)
	Wave data_err = V_getDetectorDataErrW(type,detStr)

	
	err2_sum = 0		// running total of the squared error
	ii=x1
	jj=y1
	do
		do
			counts += w[ii][jj]
			err2_sum += data_err[ii][jj]*data_err[ii][jj]
			jj+=1
		while(jj<=y2)
		jj=y1
		ii+=1
	while(ii<=x2)
	
	err2_sum = sqrt(err2_sum)
	ct_err = err2_sum
	
//	Print "error = ",ct_err
//	Print "error/counts = ",ct_err/counts
	
	Return (counts)
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
Function V_SumCountsInBox_Cmd(x1,x2,y1,y2,type,detStr)
	Variable x1,x2,y1,y2
	String type,detStr
	
	Variable counts = 0,ii,jj,err2_sum,ct_err
	
// get the waves of the data and the data_err
	Wave w = V_getDetectorDataW(type,detStr)
	Wave data_err = V_getDetectorDataErrW(type,detStr)

			
	err2_sum = 0		// running total of the squared error
	ii=x1
	jj=y1
	do
		do
			counts += w[ii][jj]
			err2_sum += data_err[ii][jj]*data_err[ii][jj]
			jj+=1
		while(jj<=y2)
		jj=y1
		ii+=1
	while(ii<=x2)
	
	err2_sum = sqrt(err2_sum)
	ct_err = err2_sum

	Print "sum of counts = ",counts	
	Print "error = ",ct_err
	Print "error/counts = ",ct_err/counts
	
	Return (counts)
End

Proc pV_SumCountsInBox_Cmd(x1,x2,y1,y2,type,detStr) 
	Variable x1=280,x2=430,y1=350,y2=1020
	String type="RAW",detStr="B"
	
	V_SumCountsInBox_Cmd(x1,x2,y1,y2,type,detStr)
End



Function V_Find_BeamCentroid() :  GraphMarquee

//	//get the current displayed data (so the correct folder is used)
//	SVAR cur_folder=root:myGlobals:gDataDisplayType
//	String dest = "root:Packages:NIST:" + cur_folder
	
	Variable xzsum,yzsum,zsum,xctr,yctr
	Variable left,right,bottom,top,ii,jj,counts
	Variable x_mm_sum,y_mm_sum,x_mm,y_mm
	Variable xRef,yRef

	
	GetMarquee left,bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		left = round(V_left)		//get integer values for selection limits
		right = round(V_right)
		top = round(V_top)
		bottom = round(V_bottom)

		// detector panel is identified from the (left,top) coordinate (x1,y2)
		String detStr = V_FindDetStrFromLoc(left,right,bottom,top)		
	//	Printf "Detector = %s\r",detStr
	
	// 
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType	
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(left,right,bottom,top,detStr,gCurDispType)
		Print left,right,bottom,top
			
		
		// selection valid now, calculate beamcenter
		// get the waves of the data and the data_err
		Wave data = V_getDetectorDataW(gCurDispType,detStr)
		Wave data_err = V_getDetectorDataErrW(gCurDispType,detStr)
		
		// get the real-space information
		String destPath = "root:Packages:NIST:VSANS:"+gCurDispType
		Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
		Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")
	
		xzsum = 0
		yzsum = 0
		zsum = 0
		x_mm_sum = 0
		y_mm_sum = 0
		
		// count over rectangular selection, doing each row, L-R, bottom to top
		ii = bottom -1
		do
			ii +=1
			jj = left-1
			do
				jj += 1
				counts = data[jj][ii]
				xzsum += jj*counts
				yzsum += ii*counts
				zsum += counts
				
				x_mm_sum += data_realDistX[jj][ii]*counts
				y_mm_sum += data_realDistY[jj][ii]*counts
			while(jj<right)
		while(ii<top)
		
		xctr = xzsum/zsum
		yctr = yzsum/zsum
		
		x_mm = x_mm_sum/zsum
		y_mm = y_mm_sum/zsum
		// add 1 to each to get to detector coordinates (1,128)
		// rather than the data array which is [0,127]
//		xctr+=1
//		yctr+=1

// correct for the zero position (y-position) on the L/R panels not being exactly equal
// the lateral scan data from Dec 2018 is used to correct this. The span of zero points
// is relatively small (+- 0.5 pixel) but is significant for data using graphite monochromator
//	
	// check that the correction waves exist, if not, generate them V_TubeZeroPointTables()
		Wave/Z tube_num = $("root:Packages:NIST:VSANS:Globals:tube_" + detStr)
		Wave/Z yCtr_tube = $("root:Packages:NIST:VSANS:Globals:yCtr_" + detStr)
		if(!WaveExists(tube_num))
			Execute "V_TubeZeroPointTables()"
			Wave/Z tube_num = $("root:Packages:NIST:VSANS:Globals:tube_" + detStr)
			Wave/Z yCtr_tube = $("root:Packages:NIST:VSANS:Globals:yCtr_" + detStr)
		endif
		
		Variable yCorrection = interp(xCtr,tube_num,yCtr_tube)
		Variable yPixSize = V_getDet_y_pixel_size(gCurDispType,detStr)
		yPixSize /= 10		// convert mm to cm
		// offsets were determined in Dec 2018 using:
		// FR tube # 7 = 61.70 pix
		// MR tube # 10 = 61.94 pix
		
		Print "X-center (in array coordinates 0->n-1 ) = ",xctr
		Print "Y-center (in array coordinates 0->n-1 ) = ",yctr
		
		Print "X-center (cm) = ",x_mm/10
		Print "Y-center (cm) = ",y_mm/10

		if(cmpstr(detStr,"FR") == 0)
			Print "Reference Y-Center is corrected for FR tube #7 zero position"		

			yCorrection = 61.70 - yCorrection
			Print "yCorrection (pix) = ",yCorrection
			Print "yCorrection (cm) = ",yCorrection*yPixSize
			xRef = x_mm/10
			yRef = y_mm/10 + yCorrection*yPixSize
			Print "FRONT Reference X-center (cm) = ",xRef
			Print "FRONT Reference Y-center (cm) = ",yRef

		endif

		if(cmpstr(detStr,"MR") == 0)
			Print "Reference Y-Center is corrected for MR tube #10 zero position"		

			yCorrection = 61.94 - yCorrection
			Print "yCorrection (pix) = ",yCorrection
			Print "yCorrection (cm) = ",yCorrection*yPixSize
			xRef = x_mm/10
			yRef = y_mm/10 + yCorrection*yPixSize
			Print "MIDDLE Reference X-center (cm) = ",xRef
			Print "MIDDLE Reference Y-center (cm) = ",yRef

		endif
		
// if measured on the LEFT panel, convert to the RIGHT coordinates for the reference value	
// these corrections are exactly the opposite (subtract, not add) of what is done in V_fDeriveBeamCenters(xFR,yFR,xMR,yMR)
// since the lateral scans to determine the relative centers were done at the same time
// the pixel values for the zero are on the same y-level, set by the beam height
//
		if(cmpstr(detStr,"FL") == 0)
			Print "Reference Y-Center is corrected for FR tube #7 zero position"		

			yCorrection = 61.70 - yCorrection
			Print "yCorrection (pix) = ",yCorrection
			Print "yCorrection (cm) = ",yCorrection*yPixSize		
			xRef = x_mm/10 - kBCtrOffset_FL_x
			yRef = y_mm/10 - kBCtrOffset_FL_y + yCorrection*yPixSize		
			Print "FRONT Reference X-center (cm) = ",xRef	// NEW Dec 2018 values
			Print "FRONT Reference Y-center (cm) = ",yRef

		endif
		
		if(cmpstr(detStr,"ML") == 0)
			Print "Reference Y-Center is corrected for MR tube #10 zero position"		

			yCorrection = 61.94 - yCorrection
			Print "yCorrection (pix) = ",yCorrection
			Print "yCorrection (cm) = ",yCorrection*yPixSize
			xRef = x_mm/10 - kBCtrOffset_ML_x
			yRef = y_mm/10 - kBCtrOffset_ML_y + yCorrection*yPixSize			
			Print "MIDDLE Reference X-center (cm) = ",xRef
			Print "MIDDLE Reference Y-center (cm) = ",yRef

		endif
	endif

// TODO
// ?? store the xy reference values somewhere so that the conversion to proper
// beam center values can be done automatically, rather than copying numbers into a procedure
//
// - either I need 6 globals for the three panels, or I need to store the values in the 
// reduction block of the file (comment?) - but I don't have the fileName here - could I find it
// somewhere? gFileList in the current data folder?
//
	String ctrStr=""
	if(cmpstr(detStr,"B") == 0)
		xRef = xCtr
		yRef = yCtr			//these are in pixels
	endif
	sprintf ctrStr,"XREF=%g;YREF=%g;PANEL=%s;",xRef,yRef,detStr
	SVAR gFileList = $("root:Packages:NIST:VSANS:"+gCurDispType+":gFileList")
	
	V_writeReductionComments(gFileList,ctrStr)
	
	
	
	//back to root folder (redundant)
	SetDataFolder root:
	
End



//
//function writes new box coordinates to the data file
//
// also writes the panel where the coordinates were set (non-nice field in /reduction)
//
Function V_UpdateBoxCoords() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		Variable count,x1,x2,y1,y2,ct_err
		x1 = V_left
		x2 = V_right
		y1 = V_bottom
		y2 = V_top

//		Print x1,x2,y1,y2

		// NOTE:
		// this function MODIFIES x and y values on return, converting them to panel coordinates
		// detector panel is identified from the (left,top) coordinate (x1,y2)
		String detStr = V_FindDetStrFromLoc(x1,x2,y1,y2)		
// 
		SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
		string boxStr
		// this function will modify the x and y values (passed by reference) as needed to keep on the panel
		V_KeepSelectionInBounds(x1,x2,y1,y2,detStr,gCurDispType)
		sprintf boxStr,"%d;%d;%d;%d;",x1,x2,y1,y2

//		Print x1,x2,y1,y2
		
		SVAR gCurrentFile = root:Packages:NIST:VSANS:Globals:gLastLoadedFile		//for the status of the display

		V_writeBoxCoordinates(gCurrentFile,V_List2NumWave(boxStr,";","inW"))
	
		V_writeReduction_BoxPanel(gCurrentFile,detStr)

//		count = V_SumCountsInBox(x1,x2,y1,y2,ct_err,gCurDispType,detStr)		
//		Print "counts = ",count
//		Print "err/counts = ",ct_err/count

		// kill the file from RawVSANS so that the updated box coordinates will be re-read in
		//
		V_KillNamedDataFolder(gCurrentFile)
	endif
End
