#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

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
	if (gIsLogScale)
		wave w=$(dest + ":linear_data")
	else
		wave w=$(dest + ":data")
	endif
	wave data_err = $(dest + ":linear_data_error")
	
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
//which now bothe work from the same folder (:Patch)
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
	String tempName = FindValidFilename(partialName)
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
	
	WriteXYBoxToHeader(filename,x1,x2,y1,y2)
	
	Print counts, " counts in XY box"
	WriteBoxCountsToHeader(filename,counts)
	
	WriteBoxCountsErrorToHeader(filename,ct_err)
	
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
	
	// data wave is hard-wired in as the displayed data
	NVAR dataIsLog=$(dest + ":gIsLogScale")		//check for log-scaling in current data folder
	if (dataIsLog)
		wave data=$(dest + ":linear_data")
	else
		wave data=$(dest + ":data")
	endif
	
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
			while(jj<right)
		while(ii<top)
		
		xctr = xzsum/zsum
		yctr = yzsum/zsum
		
		// add 1 to each to get to detector coordinates (1,128)
		// rather than the data array which is [0,127]
		xctr+=1
		yctr+=1
		
		Print "X-center (in detector coordinates) = ",xctr
		Print "Y-center (in detector coordinates) = ",yctr
	endif
	
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
	
	fileList=ParseRunNumberList(fileStr)
	num=ItemsInList(fileList,",")
	
	//loop over the list
	//add each file to SAM (to normalize to monitor counts)
	//sum over the box
	//print the results
	Make/O/N=(num) FileID,BoxCounts,BoxCount_err
	Print "Results are stored in root:FileID and root:BoxCounts waves"
	for(ii=0;ii<num;ii+=1)
		item=StringFromList(ii,fileList,",")
		FileID[ii] = GetRunNumFromFile(item)		//do this here, since the list is now valid
		fullPath = pathStr+item
		ReadHeaderAndData(fullPath)
//		String/G root:myGlobals:gDataDisplayType="RAW"
//		fRawWindowHook()
		if(cmpstr(type,"SAM")==0)
			err = Raw_to_work("SAM")
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
	
	Display /W=(5,44,383,306) BoxCounts vs FileID
	ModifyGraph mode=4
	ModifyGraph marker=8
	ModifyGraph grid=2
	ModifyGraph mirror=2
	ErrorBars/T=0 BoxCounts Y,wave=(BoxCount_err,BoxCount_err)
	Label left "Counts (per 10^8 monitor counts)"
	Label bottom "Run Number"
	
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
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
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
	WAVE data=$("root:Packages:NIST:"+cur_folder+":data")		//don't care if it's log or linear scale
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
	WAVE data=$("root:Packages:NIST:"+cur_folder+":data")		//don't care if it's log or linear scale
	

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

	Wave w=root:Packages:NIST:RAW:RealsRead
	
	Cursor/W=SANS_Data/F/I A data w[16],w[17]
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