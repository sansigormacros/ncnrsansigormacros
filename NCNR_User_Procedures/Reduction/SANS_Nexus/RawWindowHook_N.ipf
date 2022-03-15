#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*****************************
// Vers. 1.2 092101
//
// hook function and associated procedures that interact with the user
// and the SANS_Data window
// -displays pixel counts
// - displays Q, qx, qy values
// - displays q axes and pixel axes
//
// - of course, displays the detector image, w/ nice colors, legend, sliders to adjust color mapping
// and a control bar to let the user adjust scaling, do averaging...
//
// allows the display default to be set to log scaling
//*****************************


//main procedure for display of SANS data files
//uses "hook" functions to interact witht the user to get live cursor readout
//based on the IGOR Pro Demo experiment- "SimpleDemoHook" - see the original
//demo for more details of implementation
//
Function fRawWindowHook()
	//globals for the main data display window are kept in root:myGlobals
	Variable/G root:myGlobals:gXPos=0
	Variable/G root:myGlobals:gYPos=0
	Variable/G root:myGlobals:gQX=0
	Variable/G root:myGlobals:gQY=0
	Variable/G root:myGlobals:gQQ=0
	Variable/G root:myGlobals:gNCounts=0
	String/G root:myGlobals:gCurDispFile = "default string"
	String/G root:myGlobals:gCurTitle = ""
	Make/O/N=2 root:myGlobals:q_x_axis,root:myGlobals:q_y_axis
	
	
	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	SVAR cur_title = root:myGlobals:gCurTitle
	String curPath = "root:Packages:NIST:"+cur_folder
	String fname=cur_folder		//for get functions
//	Wave/T tw=$(curPath+":TextRead")
	cur_title = getSampleDescription(fname)			//always update the title string

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY

	Variable pixelsX = getDet_pixel_num_x(cur_folder)
	Variable pixelsY = getDet_pixel_num_y(cur_folder)
	
	DoWindow/F SANS_Data
	if( V_Flag==0 )
		//no SANS_Data window - make one

		//Create NIH colors if needed
		if(!WaveExists($"root:myGlobals:NIHColors"))
			NIHColorIndex()
		Endif
		
		//window creation stuff
		Display /W=(10,50,400,490) /K=1 //K=1 flag suppresses saveMacro dialog
		DoWindow/C SANS_Data
		DoWindow/T SANS_Data,cur_folder
		SetWindow SANS_Data,hook=RawWindowHook,hookevents=2
		ControlBar 100

		SetVariable xpos,pos={7,5},size={50,17},title="X"
		SetVariable xpos,limits={-Inf,Inf,0},value= root:myGlobals:gXPos
		SetVariable xpos,help={"x-position on the detector"},frame=0,noedit=1
		SetVariable ypos,pos={7,29},size={50,17},title="Y"
		SetVariable ypos,limits={-Inf,Inf,0},value= root:myGlobals:gYPos
		SetVariable ypos,help={"y-position on the detector"},frame=0,noedit=1
		SetVariable counts,pos={7,59},size={150,17},title="Counts"
		SetVariable counts,limits={-Inf,Inf,0},value= root:myGlobals:gNCounts
		SetVariable counts,help={"Neutron counts"},frame=0,noedit=1
		Button bisLin,pos={230,23},size={50,20},proc=Log_Lin,title="isLin"
		Button bisLin,help={"\"isLin\" means the counts displayed are on linear scale. \"isLog\" means the counts displayed are on log(base10) scale."}
		SetVariable qxval,pos={68,2},size={85,17},title="qX"
		SetVariable qxval,help={"q value in the x-direction on the detector"},frame=0,noedit=1
		SetVariable qxval,format="%+7.5f",limits={-Inf,Inf,0},value= root:myGlobals:gQX
		SetVariable qyval,pos={68,21},size={85,17},title="qY"
		SetVariable qyval,help={"q value in the y-direction on the detector"},frame=0,noedit=1
		SetVariable qyval,format="%+7.5f",limits={-Inf,Inf,0},value= root:myGlobals:gQY
		SetVariable q_pos,pos={68,40},size={85,17},title="q "
		SetVariable q_pos,help={"q-value on the detector at (x,y)"},format="%+7.5f"
		SetVariable q_pos,limits={-Inf,Inf,0},value= root:myGlobals:gQQ,frame=0,noedit=1
		SetVariable CurFile,pos={170,4},size={210,17},title="File"
		SetVariable CurFile,help={"Currently displayed file"},frame=0,noedit=1
		SetVariable CurFile,limits={-Inf,Inf,0},value= root:myGlobals:gCurDispFile
		
		SetVariable CurTitle,pos={4,81},size={360,17},title=" "//,title="LABEL:"
		SetVariable CurTitle,help={"Title string for currently displayed file"},frame=0,noedit=1
		SetVariable CurTitle,fstyle=1,limits={-Inf,Inf,0},value= root:myGlobals:gCurTitle
		Button Print_status,pos={170,23},size={50,20},proc=StatusButton,title="Status"
		Button Print_status,help={"Print out information about the currently displayed file into the history window"}
		Button maskButton size={84,20}, pos={170,53}, proc=maskButtonProc,title="Show Mask"
		Button maskButton help={"If a mask has been loaded this will overlay it on the current plot"}
		
		GroupBox slideGrp,pos={268,46},size={124,48},title="Color Map"
		//draw after the group box so these are on "top" of the group box
		Button doAve,pos={290,23},size={50,20},proc=ShowAvgPanel_SANSData,title="I vs. Q"
		Button doAve,help={"This will circularly average the data to I vs. Q"}
		Slider loSlide,pos={280,77},size={100,16},proc=MapSliderProc
		Slider loSlide,limits={0,1,0.01},value= 0,vert= 0,ticks= 0
		Slider loSlide,help={"Adjust the low threshold of the color map"}
		Slider hiSlide,pos={280,60},size={100,16},proc=MapSliderProc
		Slider hiSlide,limits={0,1,0.01},value= 1,vert= 0,ticks= 0
		Slider hiSlide,help={"Adjust the high threshold of the color map"}

	endif
	
	//window was already open, or has just been created, add (or remove)
	//controls specific for RAW data (specified by the current folder)
	if(cmpstr(cur_folder,"RAW")==0)
		//show the "next" buttons
		//these buttons should only be available in RAW data type
		Button backOne win=SANS_Data,size={20,20},pos={350,23},proc=BackOneFileButtonProc,title="<"
		Button backOne help={"Display the previous RAW data file run number"}
		Button forwardOne win=SANS_Data,size={20,20},pos={375,23},proc=ForwardOneFileButtonProc,title=">"
		Button forwardOne help={"Display the next RAW data file run number"}
		//
	else
		//kill them
		KillControl/W=SANS_Data backOne
		KillControl/W=SANS_Data forwardOne
	Endif
	
	//reset the slider values to 0,1
	Slider loSlide win=SANS_Data,value=0
	Slider hiSlide win=SANS_Data,value=1
	
	//remove old data and add new data to it
	//data display/modification stuff
	RemoveImage/Z data
	WAVE data = getDetectorDataW(fname)
//	WAVE NIHColors = $"root:myGlobals:NIHColors"		//use built-in ColdWarm instead
	AppendImage/W=SANS_Data data

//	lo_B = lo*(WaveMax(det_B) - WaveMin(det_B)) + WaveMin(det_B)
//	hi_B = hi*(WaveMax(det_B) - WaveMin(det_B)) + WaveMin(det_B)
//	ModifyImage/W=SANS_Data data ctab={lo_B,hi_B,ColdWarm,0}
	ModifyImage/W=SANS_Data data ctab={*,*,ColdWarm,0}
	

   WaveStats/Q data
   if(cmpstr(cur_folder,"MSK")==0)
		ModifyImage/W=SANS_Data data ctab={0,1,BlueRedGreen,0}
   else
   	//Call the procedure that would normally be called if the sliders were moved
//   	MapSliderProc("both", 0, 1)
   	MapSliderProc("reset", 0, 1)
    //  ScaleColorsToData(V_min, V_max, NIHColors)
	 //  ModifyImage data cindex=NIHColors
  	endif
	//make the pixels square, color the backgrounds
	ModifyGraph/W=SANS_Data width={plan,1,bottom,left},mirror=0
	ModifyGraph/W=SANS_Data axisenab(bottom)={0,0.7}
	ModifyGraph/W=SANS_Data axOffset(left)=-3
	ModifyGraph/W=SANS_Data standoff=0
	ModifyGraph/W=SANS_Data wbRGB=(65535,54611,49151),gbRGB=(65535,54611,49151),cbRGB=(1,52428,52428)
	
	//add the qx and qy axes
	Wave q_x_axis=$"root:myGlobals:q_x_axis"
	Wave q_y_axis=$"root:myGlobals:q_y_axis"
	Set_Q_Axes(q_x_axis,q_y_axis,cur_folder)
	RemoveFromGraph/Z q_x_axis,q_y_axis
	AppendToGraph/W=SANS_Data/T q_x_axis
	AppendToGraph/W=SANS_Data/R=Right_Q q_y_axis				//plot on a free axis, crossing at x=127 (pixelsX)
	ModifyGraph/W=SANS_Data freePos(Right_q)={pixelsX-1,bottom}
	ModifyGraph/W=SANS_Data minor(top)=1,minor(Right_Q)=1,lowTrip(top)=1e-05,lowTrip(Right_Q)=1e-05
	ModifyGraph/W=SANS_Data mode(q_x_axis)=2,mode(q_y_axis)=2		//dots
	ModifyGraph/W=SANS_Data axisEnab(top)={0,0.7}

	//add the color bar
	ColorScale/W=SANS_Data/N=colBar/A=RT/X=-3/Y=-1.5/Z=1 image=data, heightPct=100, widthPct=4,notation=1
	ColorScale/W=SANS_Data/C/N=colBar/B=(65535,60076,49151)
	
	//update the displayed filename, using FileList in the current data folder
	SVAR FileList = $(curPath + ":FileList")
	String/G root:myGlobals:gCurDispFile = FileList
	
	//update the window title
	DoWindow/T SANS_Data,cur_folder
	
	// reset the initial state of the "isLin" button if it is reading "isLog", since the initial data state is
	//always set to linear
	//re-draw the data on the graph to make sure "data" from the current folder is being used
	ControlInfo/W=SANS_Data bisLog
	if(V_flag ==1)	//if bisLog exists, this will return true
		Button bisLog,win=SANS_Data,title="isLin",rename=bisLin
	endif
	//now that button state and data are sure to match (both are linear)
	// set the display to log scale, if the global has been set
	NVAR gLogScalingAsDefault=root:Packages:NIST:gLogScalingAsDefault
	if(gLogScalingAsDefault)
		Log_lin("bisLin")
	endif
	
	//force an update of everything in the window
	DoUpdate
	
	//return data folder to root before exiting (redundant)
	SetDataFolder root:	
End

//this is the hook function that is associated with the SANS_Data graph window
//only mouse moved events are processed, although much more could be done
//for more elaborate interaction with the user.
//- sets globals (that are displayed in the control bar of the graph) for the 
//x and y positions (in Detector coordinates (1,128))
//qx, qy, and q (in Angstroms)
//and the actual neutron counts (if raw)
//or the data array value
// 
Function RawWindowHook(s)
	String s
	
	//get the current displayed data (so the correct folder is used)
	SVAR cur_folder=root:myGlobals:gDataDisplayType
	String fname=cur_folder		// for ease in calling get functions
	
	SetDataFolder "root:Packages:NIST:"+cur_folder		//use the full path, so it will always work
	String curPath = "root:Packages:NIST:" + cur_folder
	NVAR/Z dataIsLog=$("root:gIsLogScale")		//now a global variable in the current folder, not the globals folder

	wave w=getDetectorDataW(fname)		// the "regular data"
	
	String/G root:myGlobals:gHookStr= s
	Variable xpix,ypix,xaxval,yaxval,xint,yint,rawval
	String msg
	
	Wave data_realDistX = $(curPath + ":entry:instrument:detector:data_realDistX")
	Wave data_realDistY = $(curPath + ":entry:instrument:detector:data_realDistY")

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY

	Variable pixelsX = getDet_pixel_num_x(cur_folder)
	Variable pixelsY = getDet_pixel_num_y(cur_folder)
	
	//only do something for mousemoved events
	if( StrSearch(s,"EVENT:mousemoved;",0) > 0 )
		xpix= NumberByKey("MOUSEX",s)
		ypix= NumberByKey("MOUSEY",s)
		xaxval= AxisValFromPixel("","bottom",xpix)
		yaxval= AxisValFromPixel("","left",ypix)
		xint = round(xaxval)
		yint = round(yaxval)
		
		if((xint<0) || (xint>pixelsX-1) || (yint<0) || (yint>pixelsY-1))	//make sure cursor is on the image
			rawval = 0
		else
			rawval = w[xint][yint]	
			//update q, qX, and qY
			if(cmpstr(cur_folder,"MSK")!=0)
				Variable xctr=getDet_beam_center_x(fname)		//these values are currently in pixels
				Variable yctr=getDet_beam_center_y(fname)
//				Variable xctr=getDet_beam_center_x_mm(fname)
//				Variable yctr=getDet_beam_center_y_mm(fname)
				Variable sdd=getDet_Distance(fname) 		// written in [cm]
				Variable lam=getWavelength(fname)
				Variable tube_width=getDet_tubeWidth(fname)
				WAVE coefW = getDetTube_spatialCalib(fname)

//				Variable/G root:myGlobals:gQQ = T_CalcQval(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)
//				Variable/G root:myGlobals:gQX = T_CalcQX(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)
//				Variable/G root:myGlobals:gQY = T_CalcQY(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)
				Variable/G root:myGlobals:gQQ = T_CalcQval(xaxval,yaxval,xctr,yctr,tube_width,sdd,lam,coefW)
				Variable/G root:myGlobals:gQX = T_CalcQX(xaxval,yaxval,xctr,yctr,tube_width,sdd,lam,coefW)
				Variable/G root:myGlobals:gQY = T_CalcQY(xaxval,yaxval,xctr,yctr,tube_width,sdd,lam,coefW)
			else
				Variable/G root:myGlobals:gQQ = 0
				Variable/G root:myGlobals:gQX = 0
				Variable/G root:myGlobals:gQY = 0
			endif
			//add one to the x and y values to get from IGOR array indexing 0->127 to 1->128 detector
			Variable/G root:myGlobals:gXPos=xint+1
			Variable/G root:myGlobals:gYPos=yint+1
			Variable/G root:myGlobals:gNCounts=rawval
		endif
	endif
	
	//set data folder back to root
	SetDataFolder root:
	
	return 0
end

//function to set the q-axis scaling after the data has been read in
// - needs the location of the currently displayed data to get the header information
// to be able to calculate q-values at the edges of the detector
//** assumes a linear correspondence between pixel->q-values (which should bea a really
// safe bet, since we're using the small -angle approximation...)
//
// actually re-scales the qy wave that is on the SANS_Data image
// the qy dataset is 2 values, plotted as "dots", nearly invisible...
// but does an adequate job of getting ticks on the right and top axes
//
Function Set_Q_Axes(qx,qy,curPath)
	Wave qx,qy
	String curPath

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable pixelsX = getDet_pixel_num_x(curPath)
	Variable pixelsY = getDet_pixel_num_y(curPath)


	Variable xctr=getDet_beam_center_x(curPath)
	Variable yctr=getDet_beam_center_y(curPath)
	Variable sdd=getDet_Distance(curPath) / 100 		// convert [cm] to [m] for CalcQx,y
	Variable lam=getWavelength(curPath)
	Variable pixSize=getDet_x_pixel_size(curPath)/10			//TODO -- verify the units!! (need [cm])
		
	Variable maxX,minX,maxY,minY
	
	minX = CalcQX(1,yctr,xctr,yctr,sdd,lam,pixSize)
	maxX = CalcQX(pixelsX,yctr,xctr,yctr,sdd,lam,pixSize)
	SetScale/I x minX,maxX,"",qx
	
	minY = CalcQY(xctr,1,xctr,yctr,sdd,lam,pixSize)
	maxY = CalcQY(xctr,pixelsY,xctr,yctr,sdd,lam,pixSize)
	qy[0] = minY
	qy[1] = maxY
	
	return(0)
End

Function ToggleDefaultMapping()
	NVAR value = root:Packages:NIST:gLogScalingAsDefault
	value = !(value)
End