#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// RTI clean


/// NOV 2014 SRK -----
//
//  added procedures (to the end of this file) that are extensions of the "BoxSum" functionality
// -- instead of a rectangular box, these will sum over a series of files, using a defined region that 
// is a q-annulus (+/-), or sectors, or arcs. This is expected to be useful for event mode data
//
//
//
//


////////////
// vers 1.21 3 may 06 total transmission incorporated (BSG)
//
//**************************
// Vers 1.2 091901
//
// marquee functions are used to:
//
// locate the beamcenter
// set the (x,y) box coordinates for the sum for transmission calculation
// read out coordinates
// do a "box sum" of the same box over a range of files
// do a 2D Gaussian fit over a selected range
// do a save of the current image (with colorBar) - as a graphics image
//
//***************************

//sums the data counts in the box specified by (x1,y1) to (x2,y2)
//assuming that x1<x2, and y1<y2 
//the x,y values must also be in axis coordinates[0,127] NOT (1,128) detector coords.
//
// accepts arbitrary detector coordinates. calling function is responsible for 
// keeping selection in bounds
Function SumCountsInBox(x1,x2,y1,y2,ct_err,type)
	Variable x1,x2,y1,y2,&ct_err
	String type
	
	Variable counts = 0,ii,jj,err2_sum
	
	String dest =  "root:Packages:NIST:"+type
	
	//check for logscale data, but don't change the data
	NVAR gIsLogScale = $(dest + ":gIsLogScale")

		wave data=getDetectorDataW(type)

	wave data_err = getDetectorDataErrW(type)
	
	err2_sum = 0		// running total of the squared error
	ii=x1
	jj=y1
	do
		do
			counts += data[ii][jj]
			err2_sum += data_err[ii][jj]*data_err[ii][jj]
			jj+=1
		while(jj<=y2)
		jj=y1
		ii+=1
	while(ii<=x2)
	
	err2_sum = sqrt(err2_sum)
	ct_err = err2_sum
	
//	Print "error = ",err2_sum
//	Print "error/counts = ",err2_sum/counts
	
	
	Return (counts)
End


//from a marquee selection:
//calculates the sum of counts in the box, and records this count value in 
//globals for both patch and Trans routines, then records the box coordinates
//and the count value for the box in the header of the (currently displayed)
//empty beam file for use later when calculating transmissions of samples
//these values are written to unused (analysis) fields in the data header
//4 integers and one real value are written
//
//re-written to work with Transmission panel as well as PatchPanel
//which now both work from the same folder (:Patch)
//
Function SetXYBoxCoords() :  GraphMarquee

	GetMarquee left,bottom
	if(V_flag == 0)
		Abort "There is no Marquee"
	Endif
	SVAR dispType=root:myGlobals:gDataDisplayType
	if(cmpstr(dispType,"SAM")!=0)
		DoAlert 0, "You can only use SetXYBox on SAM data files"
		return(1)
	endif
	//printf "marquee left in bottom axis terms: %g\r",round(V_left)
	//printf "marquee right in bottom axis terms: %g\r",round(V_right)
	//printf "marquee top in left axis terms: %g\r",round(V_top)
	//printf "marquee bottom in left axis terms: %g\r",round(V_bottom)
	Variable x1,x2,y1,y2
	x1 = round(V_left)
	x2 = round(V_right)
	y1 = round(V_bottom)
	y2 = round(V_top)
	
	KeepSelectionInBounds(x1,x2,y1,y2)
	
	//check to make sure that Patch and Trans data folders exist for writing of global variables
	If( ! (DataFolderExists("root:myGlobals:Patch"))  )
		Execute "InitializePatchPanel()"
	Endif
	//check to make sure that Patch and Trans data folders exist for writing of global variables
	If( ! (DataFolderExists("root:myGlobals:TransHeaderInfo"))  )
		Execute "InitializeTransPanel()"
	Endif
	
	//write string as keyword-packed string, to use IGOR parsing functions
	String msgStr = "X1="+num2str(x1)+";"
	msgStr += "X2="+num2str(x2)+";"
	msgStr += "Y1="+num2str(y1)+";"
	msgStr += "Y2="+num2str(y2)+";"
	String/G root:myGlobals:Patch:gPS3 = msgStr
	String/G root:myGlobals:Patch:gEmpBox = msgStr
	//changing this global wil update the display variable on the TransPanel
	String/G root:myGlobals:TransHeaderInfo:gBox = msgStr
	
	//sum the counts in the patch - working on the SAM data, to be sure that it's normalized
	//to the same monitor counts and corrected for detector deadtime
	String type = "SAM"
	Variable counts,ct_err
	counts = SumCountsInBox(x1,x2,y1,y2,ct_err,type)
//	Print "marquee counts =",counts
//	Print "relative error = ",ct_err/counts
	
	//Set the global gTransCts
	Variable/G root:myGlobals:Patch:gTransCts = counts
	
	//now change the extra variables in the empty beam file
	//get the filename from the SAM folder (there will only be one file)
	SVAR partialName = root:Packages:NIST:SAM:FileList
	//construct valid filename, then prepend path
	String tempName = N_FindValidFilename(partialName)
	Print "in marquee",partialName
	//Print tempName
	if(cmpstr(tempName,"")==0)
		//file not found, get out
		Abort "file not found, marquee"
	Endif
	//name is ok, prepend path to tempName for read routine 
	PathInfo catPathName
	if (V_flag == 0)
		//path does not exist - no folder selected
		Abort "no path selected"
	else
		String filename = S_path + tempName
	endif
	
	if(cmpstr(filename,"no file selected")==0)
		Abort "no file selected"
	Endif

//
// see the new (VSANS derived) function writeBoxCoordinates(fname,inW)
//
// and the counts, error functions too, to be sure that these are written correctly
//
// -- these write statements occur in multiple locations in this file
//
	Make/O/D/N=4 tmpW
	tmpW[0] = x1
	tmpW[1] = x2
	tmpW[2] = y1
	tmpW[3] = y2
	
	writeBoxCoordinates(filename,tmpW)
		
	Print counts, " counts in XY box"
	writeBoxCounts(filename,counts)
	
	writeBoxCountsError(filename,ct_err)
	
	KillWaves/Z tmpW
	return(0)
End

//finds the beam center (the centroid) of the selected region
//and simply prints out the results to the history window
//values are printed out in detector coordinates, not IGOR coords.
//
Function FindBeamCenter() :  GraphMarquee

	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	String dest = "root:Packages:NIST:" + cur_folder
	
	Variable xzsum,yzsum,zsum,xctr,yctr
	Variable left,right,bottom,top,ii,jj,counts
	Variable x_mm_sum,y_mm_sum,x_mm,y_mm,yRef,xRef
	
	// data wave is hard-wired in as the displayed data
	NVAR dataIsLog=$(dest + ":gIsLogScale")		//check for log-scaling in current data folder
	wave data=getDetectorDataW(cur_folder)
	
	// get the real-space information
	Wave data_realDistX = $(dest + ":entry:instrument:detector:data_realDistX")
	Wave data_realDistY = $(dest + ":entry:instrument:detector:data_realDistY")
	
	
	
	GetMarquee left,bottom
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		left = round(V_left)		//get integer values for selection limits
		right = round(V_right)
		top = round(V_top)
		bottom = round(V_bottom)
		
		KeepSelectionInBounds(left,right,bottom,top)
		
		// selection valid now, calculate beamcenter
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
				
				x_mm_sum += data_realDistX[jj][ii]*counts
				y_mm_sum += data_realDistY[jj][ii]*counts
				
				zsum += counts
			while(jj<right)
		while(ii<top)
		
		xctr = xzsum/zsum
		yctr = yzsum/zsum
		
		x_mm = x_mm_sum/zsum
		y_mm = y_mm_sum/zsum
		
		// add 1 to each to get to detector coordinates (1,128)
		// rather than the data array which is [0,127]
		xctr+=1
		yctr+=1
		
//		Print "X-center (cm) = ",x_mm/10
//		Print "Y-center (cm) = ",y_mm/10
		
		Print "X-center (in detector coordinates) = ",xctr
		Print "Y-center (in detector coordinates) = ",yctr
		
		
//******* TODO -- zero postions have not yet been measured
// correct for the zero position (y-position) on each tube not being exactly equal
// the lateral scan data (yet to be taken) is used to correct this. The span of zero points
// is relatively small (+- 0.5 pixel) but is significant for certain conditions
//	

// March 2025: I have updated the calculation to use the real-space postion as calculated from the non-linear
// corrections. up until now, they have been treated as "perfect" values.
//
// the "manual" correction here is still done, but with "perfect" zero point values so that the calculation
// is not altered. If someone needs to do a maual calculation, it can be done by switching to the
// correct zero point tables.
//
// constant has also been defined for the tube reference value so that it is not hard-coded
// constant is defined in DetectorCorrections_N.ipf

// overwrite correction waves every time since I have allowed for different tables to be used

// check the global to see if the tables are to be used
		NVAR gUseTables = root:Packages:NIST:gUseZeroPointTables

// -- OR --
// Programmatically determine if the zero point tables are needed
//	by checking the average value of the first row of the calibration table. for tubes at 10m, this
// is  == -521 if "perfect"
		WaveStats/RMD=[0,0]/Q root:Packages:NIST:RAW:entry:instrument:detector:spatial_calibration
	
	//	Print V_avg
		if(V_avg != -521)
			gUseTables = 0
		else
			gUseTables = 1
		endif

		
//		if(!WaveExists(tube_num))
		if(gUseTables == 1)
			Execute "TubeZeroPointTables()"
		else
			Execute "TubeZeroPointTables_perfect()"
		endif
		Wave/Z tube_num = $("root:myGlobals:tube_zeroPt")
		Wave/Z yCtr_tube = $("root:myGlobals:yCtr_zeroPt")
//		endif
//		
		Variable yCorrection = interp(xCtr,tube_num,yCtr_tube)
		Variable yPixSize = getDet_y_pixel_size(cur_folder)
		yPixSize /= 10		// convert mm to cm
//

//		
		Print "X-center (cm) = ",x_mm/10
		Print "Y-center (cm) = ",y_mm/10
//
//// TODO -- need to select a "zero" tube and make all of the other zero values relative to this one
//		Print "Reference Y-Center is corrected for tube #??? zero position"		
//
		yCorrection = k_tube_ZeroPoint - yCorrection
		Print "yCorrection (pix) = ",yCorrection
		Print "yCorrection (cm) = ",yCorrection*yPixSize
		xRef = x_mm/10
		yRef = y_mm/10 + yCorrection*yPixSize
		Print "Reference X-center (cm) = ",xRef
		Print "Reference Y-center (cm) = ",yRef

	
	endif
	
	//
	// TODO
	// -- do I automatically write out the beam center to the file? as pixels or as cm?
	//
	
	//back to root folder (redundant)
	SetDataFolder root:
	
End

//still need to error check - out-of-bounds...waves exist.
// allows a 2D Gaussian fit to a selected region of data in a SANS_Data window
//puts up a new graph with the fitted contour
Function Do_2D_Gaussian_Fit() :  GraphMarquee
	String topWin=WinName(0,1)		//top *graph* window
	//exit nicely if not in the Data display window
	if(cmpstr(topWin,"SANS_Data") != 0)
		DoAlert 0,"2D Gaussian fitting is only available from the Data Display Window"
		return(1)
	Endif
	
	GetMarquee/K left,bottom
	Variable x1,x2,y1,y2,qxlo,qxhi,qylo,qyhi
	if(V_flag == 0)
		Print "There is no Marquee"
	else
		String junk="",df=""
		
		//**hard-wired info about the x-y q-scales
		qxlo = DimOffset(root:myGlobals:q_x_axis,0)
		qxhi = DimDelta(root:myGlobals:q_x_axis,0) + qxlo
//		Print "qxlo,qxhi = ",qxlo,qxhi
		Wave w=$"root:myGlobals:q_y_axis"
		qylo=w[0]
		qyhi=w[1]
//		print "qylo,qyhi = ",qylo,qyhi
		
		junk=ImageInfo("SANS_Data","data",0)
		df=StringByKey("ZWAVEDF", junk,":",";")
//		print df
		Duplicate/O $(df+"data") data,data_err
		data_err=sqrt(data)		//for weighting
		
// comment out the SetScale lines if you want the result in terms of pixels as a way of
// measuring the beam center. Note that you need to ADD ONE to fitted x0 and y0 to get detector
// coordinates rather than the zero-indexed array. 2D fitting does have the benefit of 
// reporting error bars on the xy (if you believe that 2D gaussian is correct)		
		SetScale/I x qxlo,qxhi,"",data
		SetScale/I y qylo,qyhi,"",data
		
		Display /W=(10,50,361,351) /K=1
		AppendImage data
		ModifyImage data ctab= {*,*,Grays,0}
		ModifyGraph width={Plan,1,bottom,left}
		ModifyGraph mirror=2
		ModifyGraph lowTrip=1e-04
		ModifyImage data cindex=$"root:myGlobals:NIHColors"
		SVAR/Z angst = root:Packages:NIST:gAngstStr
		Label bottom "Qx ("+angst+"\\S-1\\M)"
		Label left "Qy ("+angst+"\\S-1\\M)"

		//keep selection in-bounds
		x1=V_left
		x2=V_right
		y1=V_bottom
		y2=V_top
		KeepSelectionInBounds(x1,x2,y1,y2)

		//cross correlation coefficent (K6) must be between 0 and 1, need constraints
		Make/O/T/N=2 temp_constr
		temp_constr = {"K6>0","K6<1"}
		
		CurveFit/N Gauss2D data[x1,x2][y1,y2] /I=1 /W=data_err /D /R /A=0 /C=temp_constr
		
		Killwaves/Z temp_constr
	endif
End

// to save the image, simply invoke the IGOR menu item for saving graphics
//
Function SaveSANSGraphic() : GraphMarquee
	
	NVAR isDemoVersion=root:myGlobals:isDemoVersion
	if(isDemoVersion==1)
		//	comment out in DEMO_MODIFIED version, and show the alert
		DoAlert 0,"This operation is not available in the Demo version of IGOR"
	else
		DoAlert 1,"Do you want the controls too?"
		if(V_flag==1)
			GetMarquee/K/Z
			SavePICT /E=-5/SNAP=1
		else
			DoIGORMenu "File","Save Graphics"
		endif
	endif
End

//does a sum over each of the files in the list over the specified range
// x,y are assumed to already be in-bounds of the data array
// output is dumped to the command window
//
Function DoBoxSum(fileStr,x1,x2,y1,y2,type)
	String fileStr
	Variable x1,x2,y1,y2
	String type
	
	//parse the list of file numbers
	String fileList="",item="",pathStr="",fullPath=""
	Variable ii,num,err,cts,ct_err
	
	PathInfo catPathName
	If(V_Flag==0)
		Abort "no path selected"
	Endif
	pathStr = S_Path
	
	fileList=N_ParseRunNumberList(fileStr)
	num=ItemsInList(fileList,",")
	
	//loop over the list
	//add each file to SAM (to normalize to monitor counts)
	//sum over the box
	//print the results
	Make/O/N=(num) FileID,BoxCounts,BoxCount_err
	Print "Results are stored in root:FileID and root:BoxCounts waves"
	for(ii=0;ii<num;ii+=1)
		item=StringFromList(ii,fileList,",")
		FileID[ii] = N_GetRunNumFromFile(item)		//do this here, since the list is now valid
		fullPath = pathStr+item
		LoadRawSANSData(fullPath,"RAW")
//		String/G root:myGlobals:gDataDisplayType="RAW"
//		fRawWindowHook()
		if(cmpstr(type,"SAM")==0)
			err = Raw_to_Work_for_Tubes("SAM")
		endif
		String/G root:myGlobals:gDataDisplayType=type
		fRawWindowHook()
		cts=SumCountsInBox(x1,x2,y1,y2,ct_err,type)
		BoxCounts[ii]=cts
		BoxCount_err[ii]=ct_err
		Print item+" counts = ",cts
	endfor
	
	DoBoxGraph(FileID,BoxCounts,BoxCount_err)
	
	return(0)
End

Function DoBoxGraph(FileID,BoxCounts,BoxCount_err)
	Wave FileID,BoxCounts,BoxCount_err
	
	Sort FileID BoxCounts,FileID		//sort the waves, in case the run numbers were entered out of numerical order
	
	DoWindow BoxCountGraph
	if(V_flag == 0)
		Display /W=(5,44,383,306) BoxCounts vs FileID
		DoWindow/C BoxCountGraph
		ModifyGraph mode=4
		ModifyGraph marker=8
		ModifyGraph grid=2
		ModifyGraph mirror=2
		ErrorBars/T=0 BoxCounts Y,wave=(BoxCount_err,BoxCount_err)
		Label left "Counts (per 10^8 monitor counts)"
		Label bottom "Run Number"
	endif
	return(0)
End

//
// promts the user for a range of file numbers to perform the sum over
// list must be comma delimited numbers (or dashes) just as in the BuildProtocol panel
// the (x,y) range is already selected from the marquee
//
Function BoxSum() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Abort "There is no Marquee"
	Endif
	SVAR dispType=root:myGlobals:gDataDisplayType
	if(cmpstr(dispType,"RealTime")==0)
		Print "Can't do a BoxSum for a RealTime file"
		return(1)
	endif
	Variable x1,x2,y1,y2
	x1 = V_left
	x2 = V_right
	y1 = V_bottom
	y2 = V_top
	KeepSelectionInBounds(x1,x2,y1,y2)
	
	String fileStr="",msgStr="Enter a comma-delimited list of run numbers, use dashes for ranges"
	String type="RAW"
	Prompt fileStr,msgStr
	Prompt type,"RAW or Normalized (SAM)",popup,"RAW;SAM;"
	DoPrompt "Pick the file range",fileStr,type
	Print "fileStr = ",fileStr
	printf "(x1,x2) (y1,y2) = (%d,%d) (%d,%d)\r",x1,x2,y1,y2
	
	DoBoxSum(fileStr,x1,x2,y1,y2,type)
	
	return(0)
End	

//function that keeps the marquee selection in the range [0,127] inclusive
// (igor coordinate system)
// uses pass-by reference!
//
// x1 = left
// x2 = right
// y1 = bottom
// y2 = top
//
// accepts any detector size
Function KeepSelectionInBounds(x1,x2,y1,y2)
	Variable &x1,&x2,&y1,&y2
	
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR type = root:myGlobals:gDataDisplayType
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
		
	//keep selection in-bounds
	x1 = (round(x1) >= 0) ? round(x1) : 0
	x2 = (round(x2) <= (pixelsX-1)) ? round(x2) : (pixelsX-1)
	y1 = (round(y1) >= 0) ? round(y1) : 0
	y2 = (round(y2) <= (pixelsY-1)) ? round(y2) : (pixelsY-1)
	return(0)
End

//testing function, not used
Function testKeepInBounds(x1,x2,y1,y2)
	Variable x1,x2,y1,y2
	
	KeepSelectionInBounds(x1,x2,y1,y2)
	Print x1,x2,y1,y2
	return(0)
End

Function SANS_Histogram_Pair() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Abort "There is no Marquee"
	endif
	
	Cursor/W=SANS_Data/F/I A data 64,64
	Cursor/M/S=2/H=1/L=0/C=(3,52428,1) A
				
	// if cursor A on graph
	// Do histogram pair
	Variable aExists= strlen(CsrInfo(A)) > 0	// A is a name, not a string
	if(aExists)
		DoHistogramPair(hcsr(A),vcsr(A))
	else
		DoHistogramPair(64,64)
	endif
	return(0)
	
	//
End
// generates a histogram of the data as defined by the marquee. The longer dimension of the marquee
// becomes the x-axis of the histogram (this may need to be changed for some odd case). Pixel range specified
// by the marquee is inclusive, and is automatically kept in-bounds
// 
// The counts over the (short) dimension are averaged, and plotted vs. the pixel position.
// Pixel position is reported as Detector coordinates (1,128). Counts are whatever the current display
// happens to be.
//
Function SANS_Histogram() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Abort "There is no Marquee"
	endif
//	// if cursor A on graph
//	// Do histogram pair
//	Variable aExists= strlen(CsrInfo(A)) > 0	// A is a name, not a string
//	if(aExists)
//		DoHistogramPair(hcsr(A),vcsr(A))
//		return(0)
//	endif
	//
	Variable count,x1,x2,y1,y2,xwidth,ywidth,vsX=1,xx,yy
	x1 = V_left
	x2 = V_right
	y1 = V_bottom
	y2 = V_top
	KeepSelectionInBounds(x1,x2,y1,y2)
	Print "x1,x2,y1,y2 (det) =",x1+1,x2+1,y1+1,y2+1
	//determine whether to do x vs y or y vs x
	xwidth=x2-x1
	ywidth=y2-y1
	if(xwidth < ywidth)
		vsX=0		//sum and graph vs Y
	endif
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	Wave data = getDetectorDataW(cur_folder)		//this will be the linear data
	Make/O/N=(max(xwidth,ywidth)+1) Position,AvgCounts
	AvgCounts=0
	//set position wave 
	if(vsX)
		position=p+x1
	else
		position=p+y1
	endif
	//convert the position to Detector coordinates
	position += 1
	
	//Compute the histogram (manually)
	if(vsX)
		for(xx=x1;xx<=x2;xx+=1)		//outer loop is the "x-axis"
			for(yy=y1;yy<=y2;yy+=1)
				AvgCounts[xx-x1] += data[xx][yy]
			endfor
		endfor
		AvgCounts /= (ywidth+1)
	else
		for(yy=y1;yy<=y2;yy+=1)
			for(xx=x1;xx<=x2;xx+=1)
				AvgCounts[yy-y1] += data[xx][yy]
			endfor
		endfor
		AvgCounts /= (xwidth+1)
	endif
	GetMarquee/K		//to keep from drawing the marquee on the new histo graph
	//draw the graph, or just bring to the front with the new data
	DoWindow/F SANS_Histo
	if(V_Flag != 1)
		Draw_Histo()
	endif
	
	return(0)
End

//draws the histogram of the 2d data as specified by AvgCounts and Position
//both wave are assumed to exist in the data folder. The SANS_Histogram() marquee
//operation is responsible for creating them.
//
Function Draw_Histo()
	Display /W=(197,329,567,461)/K=1 AvgCounts vs Position
	DoWindow/C SANS_Histo
	DoWindow/T SANS_Histo,"Histogram"
	ModifyGraph mode=0,grid=1,mirror=2
	ModifyGraph rgb=(21845,21845,21845)
	ModifyGraph standoff=0
	ModifyGraph hbFill=2
	ModifyGraph useNegPat=1
	ModifyGraph usePlusRGB=1
	ModifyGraph useNegRGB=1
	ModifyGraph hBarNegFill=2
	ModifyGraph negRGB=(0,0,65535)
	SetAxis/A/N=2 left
	Label left "Counts"
	Label bottom "Pixel (detector coordinates)"
End

//function will print marquee coordinates in axis terms, not detector terms
//since IGOR is [0][127] and detector is (1,128)
Function PrintMarqueeCoords() :  GraphMarquee
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
		printf "**note that you must add 1 to each axis coordinate to get detector coordinates\r"
		
		KeepSelectionInBounds(x1,x2,y1,y2)
		SVAR cur_folder=root:myGlobals:gDataDisplayType
		count = SumCountsInBox(x1,x2,y1,y2,ct_err,cur_folder)
		Print "counts = ",count
		Print "err/counts = ",ct_err/count
	endif
End

//
//
// The histogram could potentially be done with the Igor ImageLineProfile operation
// but this seems to be just as efficient to do.
//
Function DoHistogramPair(xin,yin)
	Variable xin,yin
	
	Variable count,x1,x2,y1,y2,xwidth,ywidth,pt1,pt2,xx,yy
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	WAVE data=getDetectorDataW(cur_folder)		//don't care if it's log or linear scale
	

	pt1 = 1		// extent along the "long" direction of the swath
	pt2 = 128
		
	Make/O/D/N=(pt2-pt1+1) PositionX,AvgCountsX
	Make/O/D/N=(pt2-pt1+1) PositionY,AvgCountsY
	AvgCountsX=0
	AvgCountsY=0
	
	//set position wave, in detector coordinates
	positionX=p+pt1
	positionY=p+pt1
	
	//do the vertical, then the horizontal
	ControlInfo/W=HistoPair setvar0
//	Print "width = ",V_Value
	xwidth = V_Value		//+ -
	ywidth = V_Value
	x1 = xin - xwidth
	x2 = xin + xwidth
	y1 = pt1
	y2 = pt2
	
	KeepSelectionInBounds(x1,x2,y1,y2)
//	Print "x1,x2,y1,y2 (det) =",x1+1,x2+1,y1+1,y2+1
	
	//Compute the histogram (manually)
	for(yy=y1;yy<=y2;yy+=1)
		for(xx=x1;xx<=x2;xx+=1)
			AvgCountsY[yy-y1] += data[xx][yy]
		endfor
	endfor
	AvgCountsY /= (xwidth+1)

	// now do the Y
	y1 = yin - ywidth
	y2 = yin + ywidth
	x1 = pt1
	x2 = pt2
		
	KeepSelectionInBounds(x1,x2,y1,y2)
//	Print "x1,x2,y1,y2 (det) =",x1+1,x2+1,y2+1,y2+1	
	for(xx=x1;xx<=x2;xx+=1)		//outer loop is the "x-axis"
		for(yy=y1;yy<=y2;yy+=1)
			AvgCountsX[xx-x1] += data[xx][yy]
		endfor
	endfor
	AvgCountsX /= (ywidth+1)
	
	GetMarquee/K		//to keep from drawing the marquee on the new histo graph
	//draw the graph, or just bring to the front with the new data
	Variable step = 30
	DoWindow/F HistoPair
	if(V_Flag != 1)
		Draw_HistoPair()
	else
		SetAxis bottom (xin-step),(xin+step)
		SetAxis bottomY (yin-step),(yin+step)
	endif
		
	// so use a pair of cursors instead (how do I easily get rid of them?) - a "done" button
	DoWindow SANS_Data
	if(V_flag)
		Cursor/W=SANS_Data/K B
		Cursor/W=SANS_Data/K C
	
		Cursor/W=SANS_Data/F/I B data (xin-xwidth), (yin-yWidth)
		Cursor/W=SANS_Data/M/S=2/H=1/L=1/C=(3,52428,1) B
	//	Cursor/W=SANS_Data/M/A=0 B
		
		Cursor/W=SANS_Data/F/I C data (xin+xwidth), (yin+yWidth)
		Cursor/W=SANS_Data/M/S=2/H=1/L=1/C=(3,52428,1) C
	//	Cursor/W=SANS_Data/M/A=0 C
	endif	
	return(0)
end


Function Draw_HistoPair()
	PauseUpdate; Silent 1		// building window...
	Display /W=(432.75,431.75,903,698.75)/K=2 AvgCountsX vs PositionX as "Histogram Pair"
	AppendToGraph/L=leftY/B=bottomY AvgCountsY vs PositionY
	DoWindow/C HistoPair
	
	ModifyGraph rgb(AvgCountsX)=(21845,21845,21845)
	ModifyGraph hbFill(AvgCountsX)=2
	ModifyGraph useNegPat(AvgCountsX)=1
	ModifyGraph usePlusRGB(AvgCountsX)=1
	ModifyGraph useNegRGB(AvgCountsX)=1
	ModifyGraph hBarNegFill(AvgCountsX)=2
	ModifyGraph negRGB(AvgCountsX)=(0,0,65535)
	ModifyGraph grid(left)=1,grid(bottom)=1,grid(leftY)=1
	ModifyGraph mirror(left)=2,mirror(bottom)=2,mirror(leftY)=2
	ModifyGraph standoff(left)=0,standoff(bottom)=0,standoff(leftY)=0
	ModifyGraph lblPos(left)=62,lblPos(bottom)=39
	ModifyGraph freePos(leftY)=0
	ModifyGraph freePos(bottomY)={0,leftY}
	ModifyGraph axisEnab(left)={0,0.4}
	ModifyGraph axisEnab(leftY)={0.6,1}
	Label left "Counts"
	Label bottom "Pixel (detector coordinates)"
	SetAxis/A/N=0 left
	TextBox/C/N=text0/X=5.0/Y=5.0 "TOP"
	TextBox/C/N=text0_1/X=5.0/Y=67.0 "RIGHT"
	TextBox/C/N=text0_2/X=84.0/Y=67.0 "LEFT"
	TextBox/C/N=text0_3/X=84.0/Y=5.0 "BOTTOM"
	
	ControlBar 40
//	CheckBox check0,pos={300,11},size={72,14},proc=SH_FreeCursorCheck,title="Free Cursor"
//	CheckBox check0,value= 0
	Button button0 title="Update",size={70,20},pos={200,9},proc=SH_RecalcButton
	SetVariable setvar0,pos={20,11},size={120,16},title="Width (pixels)"
	SetVariable setvar0,limits={0,64,1},value= _NUM:5,proc=SH_WidthSetVarProc
	
	Button button1 title="Done",size={70,20},pos={300,9},proc=SH_DoneButton

EndMacro


// not used, just for testing
Function CursorForHistogram()

	Variable xx,yy
	xx = getDet_beam_center_x("RAW")
	yy = getDet_beam_center_y("RAW")
	
	Cursor/W=SANS_Data/F/I A data xx,yy
	Cursor/M/S=2/H=1/L=0/C=(3,52428,1) A
	
End


Function SH_FreeCursorCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
				//don't move the cursor
				//Cursor/W=SANS_Data/F/M/S=2/H=1/L=0/C=(3,52428,1) A data
			
				Cursor/W=SANS_Data/F/I A data 64,64
				Cursor/M/S=2/H=1/L=0/C=(3,52428,1) A
				
			break
	endswitch

	return 0
End

Function SH_RecalcButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
//			Print "at = ",hcsr(A,"SANS_Data"),vcsr(A,"SANS_Data")
			DoHistogramPair(hcsr(A,"SANS_Data"),vcsr(A,"SANS_Data"))
			break
	endswitch

	return 0
End

Function SH_DoneButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K HistoPair
			
			DoWindow SANS_Data
			if(V_flag)
				Cursor/W=SANS_Data/K A
				Cursor/W=SANS_Data/K B
				Cursor/W=SANS_Data/K C
			endif
			break
	endswitch

	return 0
End
Function SH_WidthSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			DoHistogramPair(hcsr(A,"SANS_Data"),vcsr(A,"SANS_Data"))
			
			break
	endswitch

	return 0
End


//////////////////
//
// -- Extensions of "Box Sum"
//
// some of these are duplicated procedures - these could be more smartly written as a single set of fucntions
// since the annulus sum is a sepcial case of the arc sum - but I'm just trying to get this to work
// first, then figure out if it's really worth figuring out a new way to present this to users
// either though the average panel, or through the event mode panel
//
// right now, these items are presented through the (awkward) marquee menu, as the box sum was.
// these would be much better served with a panel presentation - like the average panel where these
// input values are already (almost) collected.
//
// -- some tricks:
//   when the last file is done processing, toggle from log/lin scale. The region that was summed has been set
// to NaN, so it will be visible after toggling the display.
// -- if there is a binTimes wave, be sure to grab that and save it elsewhere, or it will be lost, and all you'll
//   have is cts vs. run number.
//
//
// -- what's missing?
//  -- automatically picking up the time wave. currently only the file ID is collected, since that's
//      the run number list. But the clock time is a function of binning, if event mode is used. this
//      can be copied directly from the bin results (wave = BinEndTime, skipping the first 0 time point).
//      But it's a manual step. If any run numbers are skipped, it's a mess.
//  -- if added to the average panel, the "arc" option isn't there, and someone will surely ask for it
//  -- a quick way of displaying what was actually used in the sum -- the NaN trick is good, but it
//      requires recompiling. Can I set a flag somewhere?
//
//
//
// Oct 2014 SRK
//


//
// promts the user for a range of file numbers to perform the sum over
// list must be comma delimited numbers (or dashes) just as in the BuildProtocol panel
// q-Center and delta-Q is entered by the user
//
Function AnnulusSum() :  GraphMarquee
	GetMarquee left,bottom
	if(V_flag == 0)
		Abort "There is no Marquee"
	Endif
	SVAR dispType=root:myGlobals:gDataDisplayType
	if(cmpstr(dispType,"RealTime")==0)
		Print "Can't do an AnnulusSum for a RealTime file"
		return(1)
	endif
	
	String fileStr="",msgStr="Enter a comma-delimited list of run numbers, use dashes for ranges"
	String type="RAW"
	Variable qCenter,deltaQ
	Prompt fileStr,msgStr
	Prompt qCenter, "Enter the q-center (A)"
	Prompt deltaQ, "Enter the delta Q +/- (A)"
	Prompt type,"RAW or Normalized (SAM)",popup,"RAW;SAM;"
	DoPrompt "Pick the file range",fileStr,type,qCenter,deltaQ
	Print "fileStr = ",fileStr
	printf "QCenter +/- deltaQ = %g +/- %g\r",qCenter,deltaQ
	
	DoAnnulusSum(fileStr,qCenter,deltaQ,type)
	
	return(0)
End	
				
//does a sum over each of the files in the list over the specified range
// x,y are assumed to already be in-bounds of the data array
// output is to AnnulusCounts waves
//
Function DoAnnulusSum(fileStr,qCtr,delta,type)
	String fileStr
	Variable qCtr,delta
	String type
	
	//parse the list of file numbers
	String fileList="",item="",pathStr="",fullPath=""
	Variable ii,num,err,cts,ct_err
	
	PathInfo catPathName
	If(V_Flag==0)
		Abort "no path selected"
	Endif
	pathStr = S_Path
	
	fileList=N_ParseRunNumberList(fileStr)
	num=ItemsInList(fileList,",")
	
	//loop over the list
	//add each file to SAM (to normalize to monitor counts)
	//sum over the annulus
	//print the results
	Make/O/N=(num) FileID,AnnulusCounts,AnnulusCount_err
	Print "Results are stored in root:FileID and root:AnnulusCounts waves"
	for(ii=0;ii<num;ii+=1)
		item=StringFromList(ii,fileList,",")
		FileID[ii] = N_GetRunNumFromFile(item)		//do this here, since the list is now valid
		fullPath = pathStr+item
		LoadRawSANSData(fullPath,"RAW")
//		String/G root:myGlobals:gDataDisplayType="RAW"
//		fRawWindowHook()
		if(cmpstr(type,"SAM")==0)
			err = Raw_to_Work_for_Tubes("SAM")
		endif
		String/G root:myGlobals:gDataDisplayType=type
		fRawWindowHook()
		cts=SumCountsInAnnulus(qCtr,delta,ct_err,type)
		AnnulusCounts[ii]=cts
		AnnulusCount_err[ii]=ct_err
		Print item+" counts = ",cts
	endfor
	
	DoAnnulusGraph(FileID,AnnulusCounts,AnnulusCount_err)
	
	return(0)
End


//sums the data counts in the annulus specified by qCtr and delta (units of Q, not pixels)
//
Function SumCountsInAnnulus(qCtr,delta,ct_err,type)
	Variable qCtr,delta,&ct_err
	String type
	
	Variable counts = 0,ii,jj,err2_sum,testQ
	
	String dest =  "root:Packages:NIST:"+type
	
// destPath = path to destination WORK folder ("root:Packages:NIST:"+folder)
	Wave data_realDistX = $(dest + ":entry:instrument:detector:data_realDistX")
	Wave data_realDistY = $(dest + ":entry:instrument:detector:data_realDistY")
	
	//check for logscale data, but don't change the data
	NVAR gIsLogScale = $(dest + ":gIsLogScale")
	if (gIsLogScale)
		wave w=getDetectorDataW(type)		//this will be linear too
	else
		wave w=getDetectorDataW(type)
	endif
	wave data_err = getDetectorDataErrW(type)
	Variable xctr=getDet_beam_center_x(type)
	Variable yctr=getDet_beam_center_y(type)
	Variable sdd=getDet_Distance(type) / 100   // CalcQval is expecting [m]
	Variable lam=getWavelength(type)
	Variable pixSize=getDet_y_pixel_size(type)/10

	Variable tube_width=getDet_tubeWidth(type)
	WAVE coefW = getDetTube_spatialCalib(type)


	err2_sum = 0		// running total of the squared error
	
	for(ii=0;ii<128;ii+=1)
		for(jj=0;jj<128;jj+=1)
			//test each q-value, sum if within range of annulus
			testQ = T_CalcQval(ii+1,jj+1,xctr,yctr,tube_width,sdd,lam,coefW)
			
			if(testQ > (qCtr - delta) && testQ < (qCtr + delta))
				counts += w[ii][jj]
				
				w[ii][jj] = NaN		//for testing -- sets included pixels to NaN (in linear_data)
				
				err2_sum += data_err[ii][jj]*data_err[ii][jj]
			endif
		endfor
	endfor
	
	
	err2_sum = sqrt(err2_sum)
	ct_err = err2_sum
	
//	Print "error = ",err2_sum
//	Print "error/counts = ",err2_sum/counts
	
	
	Return (counts)
End



Function DoAnnulusGraph(FileID,AnnulusCounts,AnnulusCount_err)
	Wave FileID,AnnulusCounts,AnnulusCount_err
	
	Sort FileID AnnulusCounts,FileID		//sort the waves, in case the run numbers were entered out of numerical order
	
	DoWindow AnnulusCountsGraph
	if(V_flag == 0)
		Display /W=(5,44,383,306) AnnulusCounts vs FileID
		DoWindow/C AnnulusCountsGraph
		ModifyGraph mode=4
		ModifyGraph marker=8
		ModifyGraph grid=2
		ModifyGraph mirror=2
		ErrorBars/T=0 AnnulusCounts Y,wave=(AnnulusCount_err,AnnulusCount_err)
		Label left "Counts (per 10^8 monitor counts)"
		Label bottom "Run Number"
	endif	
	return(0)
End



/////////////////////////
// Duplicate of the procedures - this time for arcs, which are identical to the annulus, but not full circles.
//

//////////////////
//
// promts the user for a range of file numbers to perform the sum over
// list must be comma delimited numbers (or dashes) just as in the BuildProtocol panel
// q-Center and delta-Q is entered by the user
// phi and delta phi are entered
// left, right, or both sides are selected too
//
// set deltaQ huge to get the full sector
//
Function ArcSum() :  GraphMarquee

	SVAR dispType=root:myGlobals:gDataDisplayType
	if(cmpstr(dispType,"RealTime")==0)
		Print "Can't do an ArcSum for a RealTime file"
		return(1)
	endif
	
	String fileStr="",msgStr="Enter a comma-delimited list of run numbers, use dashes for ranges"
	String type="RAW",sideStr=""
	Variable qCenter,deltaQ,phi,deltaPhi
	Prompt fileStr,msgStr
	Prompt qCenter, "Enter the q-center (A)"
	Prompt deltaQ, "Enter the delta Q +/- (A)"
	Prompt type,"RAW or Normalized (SAM)",popup,"RAW;SAM;"
	Prompt sideStr,"One, or both sides",popup,"both;one;"
	Prompt phi, "Enter the angle phi (0,360)"
	Prompt deltaPhi, "Enter the delta phi angle (degrees)"

	DoPrompt "Pick the file range",fileStr,type,qCenter,deltaQ,sideStr,phi,deltaPhi
	Print "fileStr = ",fileStr
	printf "QCenter +/- deltaQ = %g +/- %g\r",qCenter,deltaQ
	Print "sideStr = ",sideStr
	printf "phi +/- deltaPhi = %g +/- %g\r",phi,deltaPhi
		
	DoArcSum(fileStr,qCenter,deltaQ,type,sideStr,phi,deltaPhi)
	
	return(0)
End	
				
//does a sum over each of the files in the list over the specified range
// x,y are assumed to already be in-bounds of the data array
// output is to ArcCounts waves
//
Function DoArcSum(fileStr,qCtr,delta,type,sideStr,phi,deltaPhi)
	String fileStr
	Variable qCtr,delta
	String type,sideStr
	Variable phi,deltaPhi
	
	//parse the list of file numbers
	String fileList="",item="",pathStr="",fullPath=""
	Variable ii,num,err,cts,ct_err
	
	PathInfo catPathName
	If(V_Flag==0)
		Abort "no path selected"
	Endif
	pathStr = S_Path
	
	fileList=N_ParseRunNumberList(fileStr)
	num=ItemsInList(fileList,",")
	
	//loop over the list
	//add each file to SAM (to normalize to monitor counts)
	//sum over the annulus
	//print the results
	Make/O/N=(num) FileID,ArcCounts,ArcCount_err
	Print "Results are stored in root:FileID and root:AnnulusCounts waves"
	for(ii=0;ii<num;ii+=1)
		item=StringFromList(ii,fileList,",")
		FileID[ii] = N_GetRunNumFromFile(item)		//do this here, since the list is now valid
		fullPath = pathStr+item
		LoadRawSANSData(fullPath,"RAW")
//		String/G root:myGlobals:gDataDisplayType="RAW"
//		fRawWindowHook()
		if(cmpstr(type,"SAM")==0)
			err = Raw_to_Work_for_Tubes("SAM")
		endif
		String/G root:myGlobals:gDataDisplayType=type
		fRawWindowHook()
		cts=SumCountsInArc(qCtr,delta,ct_err,type,sideStr,phi,deltaPhi)
		ArcCounts[ii]=cts
		ArcCount_err[ii]=ct_err
		Print item+" counts = ",cts
	endfor
	
	DoArcGraph(FileID,ArcCounts,ArcCount_err)
	
	return(0)
End


//sums the data counts in the annulus specified by qCtr and delta (units of Q, not pixels)
//
Function SumCountsInArc(qCtr,delta,ct_err,type,sideStr,phi,deltaPhi)
	Variable qCtr,delta,&ct_err
	String type,sideStr
	Variable phi,deltaPhi
	
	Variable counts = 0,ii,jj,err2_sum,testQ,testPhi
	
	String dest =  "root:Packages:NIST:"+type
	
	Wave data_realDistX = $(dest + ":entry:instrument:detector:data_realDistX")
	Wave data_realDistY = $(dest + ":entry:instrument:detector:data_realDistY")

	//check for logscale data, but don't change the data
	NVAR gIsLogScale = $(dest + ":gIsLogScale")
	if (gIsLogScale)
		wave w=getDetectorDataW(type)
	else
		wave w=getDetectorDataW(type)
	endif
	wave data_err = getDetectorDataErrW(type)
	Variable xctr=getDet_beam_center_x(type)
	Variable yctr=getDet_beam_center_y(type)
	Variable sdd=getDet_Distance(type) / 100		// CalcQval is expecting [m]
	Variable lam=getWavelength(type)
	Variable pixSize=getDet_y_pixel_size(type)/10

	Variable tube_width=getDet_tubeWidth(type)
	WAVE coefW = getDetTube_spatialCalib(type)
	

	err2_sum = 0		// running total of the squared error
	
	for(ii=0;ii<128;ii+=1)
		for(jj=0;jj<128;jj+=1)
			//test each q-value, sum if within range of annulus
			testQ = T_CalcQval(ii+1,jj+1,xctr,yctr,tube_width,sdd,lam,coefW)			
			if(testQ > (qCtr - delta) && testQ < (qCtr + delta))
				//then test the arc
				testPhi = FindPhi(ii+1-xCtr, jj+1-yctr)			//does not need to be in cm, pixels is fine
				testPhi = testPhi*360/2/pi		//convert to degrees
				if(phiTestArcSum(testPhi,phi,deltaPhi,sideStr))
							
						counts += w[ii][jj]
						
						w[ii][jj] = NaN		//for testing -- sets included pixels to NaN (in linear_data)
						
						err2_sum += data_err[ii][jj]*data_err[ii][jj]	
				endif
			endif
		endfor
	endfor
	
	
	err2_sum = sqrt(err2_sum)
	ct_err = err2_sum
	
//	Print "error = ",err2_sum
//	Print "error/counts = ",err2_sum/counts
	
	Return (counts)
End

// since the test for arcs is more complex, send it out...
//
// NOTE these definitions of angles are NOT the same as the average panel
//
// testPhi is in the range (0,360)
// phi is (0,360)
// side is either one or both (mirror it 180 degrees)
//
Function phiTestArcSum(testPhi,phi,dPhi,side)
	Variable testPhi,phi,dPhi
	String side
	
	Variable pass = 0
	variable low,hi, range
	
	if( (cmpstr(side,"one")==0) || (cmpstr(side,"both")==0) )
		low = phi - dphi
		hi = phi + dphi		
		if(testPhi > low && testPhi < hi)
			return(1)
			
		else
	
			if(low < 0)	//get the gap between low+360 and 360
				low += 360
				if(testPhi > low && testPhi < 360)
					return(1)
				endif
			endif
			
			if(hi > 360)		//get the gap between 0 and (hi-360)
				hi -= 360
				if(testPhi > 0 && testPhi < hi)
					return(1)
				endif
			endif
			
		endif		
	Endif		//one side or both
	
	if((cmpstr(side,"both")==0) )		//now catch the 180 deg mirror

		if(phi + 180 > 360)
			phi = phi - 180
		else
			phi = phi + 180
		endif

		low = phi - dphi
		hi = phi + dphi

		if(testPhi > low && testPhi < hi)
			return(1)
		else
			if(low < 0)	//get the gap between low+360 and 360
				low += 360
				if(testPhi > low && testPhi < 360)
					return(1)
				endif
			endif
			
			if(hi > 360)		//get the gap between 0 and (hi-360)
				hi -= 360
				if(testPhi > 0 && testPhi < hi)
					return(1)
				endif
			endif
	
		endif
			
	Endif		//both

	
	return(pass)
end

Function DoArcGraph(FileID,ArcCounts,ArcCount_err)
	Wave FileID,ArcCounts,ArcCount_err
	
	Sort FileID ArcCounts,FileID		//sort the waves, in case the run numbers were entered out of numerical order
	
	DoWindow ArcCountsGraph
	if(V_flag == 0)
		Display /W=(5,44,383,306) ArcCounts vs FileID
		DoWindow/C ArcCountsGraph
		ModifyGraph mode=4
		ModifyGraph marker=8
		ModifyGraph grid=2
		ModifyGraph mirror=2
		ErrorBars/T=0 ArcCounts Y,wave=(ArcCount_err,ArcCount_err)
		Label left "Counts (per 10^8 monitor counts)"
		Label bottom "Run Number"
	endif	
	return(0)
End

//////////////////////////////
