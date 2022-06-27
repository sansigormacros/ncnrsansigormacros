#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


// RTI clean
//


//*********************
// Vers 1.2 090501
//
//*********************
//
// Utility procedures for displaying workfiles from data folders and 
// conversion utilities for log/linear scaling of data
// NIH color index is also defined here
//


// plots the data in the "type" folder as a wireframe 3D surface.
// uses (dynamically) the log/lin scaling of data in the folder
//
//
// -- as of 2022 - not functioning --
// ModifySurfer operation has not worked for years...
// -- would need to rewrite in terms of Gizmo operations
//
//
Proc Plot3DSurface(type)
	String type
	Prompt type,"Display 2-D data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;MSK;STO;SUB;DRK;RealTime"
	
	//macro will take whatever is in "type" folder
	//check the contents of "type" to make sure that data exists
	String wavePath = "root:Packages:NIST:"+type+":data"
	if(WaveExists($wavePath) == 0)
		String errString="There is no data in "+type
		Abort errString
	Endif
	
	PauseUpdate; Silent 1	// Building window...

	// Do nothing if the Surface Plotter XOP is not available.
	if (exists("CreateSurfer") !=4)
		DoAlert 0, "Surface Plotter XOP must be installed"
		return
	endif

	//creates a default-styled surface plot of the specified data
	DoWindow/F Surface_3D
	if(V_flag==0)
		CreateSurfer
	Endif
	MoveWindow 4,44,517,382 
	ModifySurfer  FactoryDefaults, Update=0
	ModifySurfer/K=1
	ModifySurfer/N=Surface_3D
	ModifySurfer/T=wavePath
	ModifySurfer srcWave=$wavePath	
	ModifySurfer  srcType=1,plotType=3
	ModifySurfer  setControlView=3
	ModifySurfer  theta=37.5,  phi=308.9,  zScale=1,  xStep=4,  yStep=2
	ModifySurfer  frame=895,  drawFrame=1
	ModifySurfer  drawBox=1
	ModifySurfer  drawTicks=5
	ModifySurfer topRGB={0,0,0},  bottomRGB={30583,30583,30583},  backRGB={65535,65535,65535}
	ModifySurfer palette=YellowHot
	ModifySurfer fillFrameRGB={21845,21845,21845}
	ModifySurfer topContourRGB={0,26214,26214}
	ModifySurfer gridRGB={0,0,0}
	ModifySurfer  grids=1
	ModifySurfer  numContourLevels=15
	ModifySurfer  marker=19,  markerSize=1,  markerColorType=2
	ModifySurfer  scatterDepthCue=1
	ModifySurfer  rotationType=0
	ModifySurfer  Update=1
End

//***************
//a 'fake' version of the NIH "Fire 2" color table, preferable to IGOR's built-in 
//color tables - used by an image plot as a colorIndex wave
//
Function NIHColorIndex()
	
	Variable numberofColors=8,hi=65535,mid=35000,lo=0,step=16,ii=0,incr=0
	Make/O/N=((numberOfColors-1)*step,3) $"root:myGlobals:NIHColors"
	WAVE NIHColors = $"root:myGlobals:NIHColors"
	
	ii=0
	incr = 0
	do
		NIHColors[ii+incr][0] = lo		//black to blue
		NIHColors[ii+incr][1] = lo
		NIHColors[ii+incr][2] = lo + (hi-lo)/step*ii
		ii+=1
	while(ii<step)
	
	ii=0
	incr = step
	do
		NIHColors[ii+incr][0] = lo	+ (mid-lo)/step*ii	//blue to purple
		NIHColors[ii+incr][1] = lo
		NIHColors[ii+incr][2] = hi
		ii+=1
	while(ii<step)	
	
	ii=0
	incr = 2*step
	do
		NIHColors[ii+incr][0] = mid		//purple to magenta
		NIHColors[ii+incr][1] = lo
		NIHColors[ii+incr][2] = hi - (hi-mid)/step*ii
		ii+=1
	while(ii<step)
		
	ii=0
	incr = 3*step
	do
		NIHColors[ii+incr][0] = mid + (hi-mid)/step*ii		//magenta to red
		NIHColors[ii+incr][1] = lo
		NIHColors[ii+incr][2] = mid - (mid-lo)/step*ii
		ii+=1
	while(ii<step)
		
	ii=0
	incr = 4*step
	do
		NIHColors[ii+incr][0] = hi		//red to orange
		NIHColors[ii+incr][1] = lo + (mid-lo)/step*ii
		NIHColors[ii+incr][2] = lo
		ii+=1
	while(ii<step)
		
	ii=0
	incr = 5*step
	do
		NIHColors[ii+incr][0] = hi		//orange to yellow
		NIHColors[ii+incr][1] = mid + (hi-mid)/step*ii
		NIHColors[ii+incr][2] = lo
		ii+=1
	while(ii<step)
		
	ii=0
	incr = 6*step
	do
		NIHColors[ii+incr][0] = hi		//yellow to white
		NIHColors[ii+incr][1] = hi
		NIHColors[ii+incr][2] = lo + (hi-lo)/step*ii
		ii+=1
	while(ii<step)
		
	return(0)
End

// given a max and min Z-value (intensity), rescales the color wave to match the scale
// - used every time a new image is plotted or for every scale change (sliders, log/lin...)
Function ScaleColorsToData(zmin,zmax,colorWave)
	Variable zmin,zmax
	Wave colorWave
	
	SetScale/I x,zmin,zmax,colorWave
	
	return(0)
End

//*****************
//unused procedure
//
Proc QuickViewFile(type)
	String type
	Prompt type,"Display 2-D data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;MSK;"
	
	//macro will take whatever is in "type" folder
	//check for data existence
	//and set it to the current display, in a separate image window
	
	if(cmpstr(type,"file") == 0)
		//ask for a file
		//?how do I know what type of data it is? - there are 3 choices - RAW,DIV,MASK
		//that all must be read in differently
		
		//String fname = PromptForPath("Select file")
		Print "file option currently not operational"
	else
		//check the contents of "type" to make sure that data exists
		String wavePath = "root:Packages:NIST:"+type+":data"
		if(WaveExists($wavePath) == 0)
			String errString="There is no data in "+type
			Abort errString
		Endif
		
		NewImage/F/S=2/K=1 $wavePath
		ModifyImage '' ctab= {*,*,YellowHot,0}		// '' will modify the first (only) image instance
	Endif
	
	//back to root folder (redundant)
	SetDataFolder root:
	
End
//above is unused
//*****************


Proc ChangeDisplay(type)
	String type
	Prompt type,"Display WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;ADJ;"
	
	fChangeDisplay(type)
end
	

// changes the SANS_Data graph window to the selected work (folder), if the data exists
//
Function fChangeDisplay(type)
	String type
	
	//macro will take whatever is in "type" folder
	//check for data existence
	//and set it to the current display
	
	//check the contents of "type" to make sure that data exists
	WAVE w=getDetectorDataW(type)
//	String wavePath = "root:Packages:NIST:"+type+":data"
	if(WaveExists(w) == 0)
		Abort "There is no data in "+type
	Endif
	
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=type
	
//	ConvertFolderToLinearScale(type)
	//need to update the display with "data" from the correct dataFolder
	fRawWindowHook()
End



//make sure that the displayed state matches the button
//text. This should be called separate from ConvertDataFolder...
Function Fix_LogLinButtonState(state)
	Variable state
	//check for existence of SANS_Data window
	//but don't bring to front
	if(cmpstr(WinList("SANS_Data",";","WIN:1"),"")==0)
		return(0)		//SANS_Data display not open, do nothing
	endif
	// fix the button if needed
	//
	ControlInfo/W=SANS_Data bisLin
	if(V_flag==0)
		//button must read "log"
		if(state==0)
			//date is really linear scale
			Button $"bisLog",title="isLin",rename=bisLin,win=SANS_Data
		endif
	else
		//button must read "lin"
		if(state==1)
			//data is really log scale
			Button $"bisLin",title="isLog",rename=bisLog,win=SANS_Data
		endif
	endif
	return(0)
End
