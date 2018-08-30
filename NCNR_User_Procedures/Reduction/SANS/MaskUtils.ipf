#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*********************
// Vers. 1.2 092101
//
//entry procedure for reading a mask file
//mask files are currently only acceptable in MCID format, as written out by NIH
//Image, available on the Macs (haven't tested the output of the Java version
//(Image/J)
//
// also contains new drawing routines for drawing a mask within IGOR
// and saving it in the required format
// - uses simpler drawing tools (fill objects, no lines) for speed
//
//*************************



//reads the data (1=mask, 0 = no mask)
//and plots a quickie image to make sure it's ok
//data is always read into root:Packages:NIST:MSK folder
//
Proc ReadMASK()
	
	//SetDataFolder root:Packages:NIST:MSK
	String fname = PromptForPath("Select Mask file")
	if(strlen(fname)==0)
		return
	endif
	ReadMCID_MASK(fname)
	
	//SetDataFolder root:Packages:NIST:MSK
//// 	SRK SEP06 disable plot of mask data, just show the overlay
////	String waveStr = "root:Packages:NIST:MSK:data"
////	NewImage/F/S=2/K=1 $waveStr
////	ModifyImage '' ctab= {*,*,YellowHot,0}
	maskButtonProc("maskButton")
//	OverlayMask(1)

	//back to root folder (redundant)
	SetDataFolder root:
End


//reads the mask data into the root:Packages:NIST:MSK folder
//setDataFolder is required here
//y-values must be flipped to get proper array assignment of the mask
//
// SRK -SEP09 - removed hard-wired 16384 (128x128) from GBLoadWave cmd string
// for general XY compatibility (192x192) = 36864
//
Function ReadMCID_MASK(fname)
	String fname
	// Reads MCID-format mask files written out by SANS IMAGE
	// put data into MSK data folder
	// flip the y-values to correspond to the work file
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	SetDataFolder root:Packages:NIST:MSK
	Killwaves/Z data,data0		//kill the old data, if it exists
	
//	String cmd = "GBLoadWave/N=data/T={72,72}/O/S=4/W=1/U="
//	cmd += num2istr(pixelsX*pixelsY) + " /Q  \"" + fname +"\""

	String GBLoadStr = "GBLoadWave/N=data/T={72,72}/O/S=4/W=1"


	if(cmpstr("\\\\",fname[0,1])==0)	//Windows user going through network neighborhood
		PathInfo catPathName
		if(V_flag==1)
			//catPathName exists, use it
			GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q/P=catPathName  \"" + ParseFilePath(0, fname, ":", 1, 0) +"\""
		else
			// need to create a temporary path
			String tmpPathStr = ParseFilePath(1, fname, ":", 1, 0)
			NewPath/O/Q tmpUNCPath tmpPathStr
			GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q/P=tmpUNCPath  \"" + ParseFilePath(0, fname, ":", 1, 0) +"\""
		endif
	else
	// original case, fname is the full path:name and is Mac (or a mapped drive)
		GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q  \"" + fname +"\""
	endif
	
	Execute GBLoadStr 
	SetDataFolder root:Packages:NIST:MSK						//make sure correct data folder is set
	WAVE data0 = $"root:Packages:NIST:MSK:data0"
	Redimension/N=(pixelsX,pixelsY) data0
	Flip_Y(data0)
	
	SetDataFolder root:Packages:NIST:MSK
	Rename data0,data
	
	Variable/G root:Packages:NIST:MSK:gIsLogScale = 0
	String/G root:Packages:NIST:MSK:fileList = GetFileNameFromPathNoSemi(fname)
	//back to root folder
	SetDataFolder root:
	return(0)
End

//
//flips the y-data of the MCID format array that was read in
//the input array (pixelsX x pixelsY) is overwritten as output
//
// AND MUST BE SQUARE!
//
Function Flip_Y(mat)
	Wave mat
	
	//reverses the order of y-indices in an MCID-style matrix output from SANS IMAGE,
	//so that a mask file will be displayed properly on screen - 
	//"IMAGE" format is (0,0) in top left
	//the (WORK)_data matches the detector, with (0,0) in the bottom left corner
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Variable ii,jj,kk
	Make/O/N=(pixelsX) temp_y
	
	ii=0
	do
		jj=0
		do
			temp_y[jj]=mat[ii][jj]
			jj+=1
		while(jj<pixelsY)
		kk=0
		do
			mat[ii][pixelsX-1-kk]=temp_y[kk]
			kk+=1
		while(kk<pixelsX)
		ii+=1
	while(ii<pixelsX)
	
	KillWaves temp_y
	Return (0)
End


//**********************
// for drawing a mask, see GraphWaveDraw (and Edit)
//and for Image progessing demo - look in the examples forder in the 
//IGOR Pro folder....possible slider bar, constrast adjustment
//
//the following are macros and functions to overlay a mask on an image
//
//ResetLoop sets all of the zeros in the mask to NaN's so that they are
//not plotted
Function ResetLoop(tempStr)
	String tempstr
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable ii=0,jj=0
	Wave junk = $tempStr
	
	do 
		jj=0
		do
			if(junk[ii][jj] == 0)
				junk[ii][jj] = NaN
			else
				junk[ii][jj] = 1
			endif
			jj+=1
		while(jj<pixelsY)
		ii+=1
	while(ii<pixelsX)
End

//
//toggles a mask on/off of the SANS_Data window
// points directly to window, doesn't need current display type
//
// if state==1, show the mask, if ==0, hide the mask
Function OverlayMask(state)
	Variable state
	
	String maskPath = "root:Packages:NIST:MSK:data"
	if(WaveExists($maskPath) == 1)
		//duplicate the mask, which is named "data"
		Duplicate/O root:Packages:NIST:MSK:data root:Packages:NIST:MSK:overlay
		Redimension/D root:Packages:NIST:MSK:overlay
	
		String tempStr = "root:Packages:NIST:MSK:overlay"
		ResetLoop(tempStr)		//keeps 1's and sets 0's to NaN
	
		//check to see if mask overlay is currently displayed
		DoWindow SANS_Data
		if(V_flag==0)
			return(0)
		endif
		
		CheckDisplayed/W=SANS_Data root:Packages:NIST:MSK:overlay
		//Print "V_flag = ",V_flag
	
		If(V_Flag == 1)		//overlay is present
			if(state==0)
				RemoveImage overlay
			endif		//don't need to do anything if we want to keep the mask
		Else		//overlay is not present
			if(state==1)
				//append the new overlay
				AppendImage/L=left/B=bottom root:Packages:NIST:MSK:overlay
				//set the color table to vary from 0 to * (=max data = 1), with blue maximum
				//Nan's will appear transparent (just a general feature of images)
				ModifyImage/W=SANS_Data overlay ctab={0,*,BlueRedGreen,0}
			endif		//don't do anything if we don't want the overlay
		Endif
	Endif
End

//checkbox control procedure to toggle to "erase" mode
//where the filled regions will be set to 0=no mask
//
Function EraseCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	//SetDrawEnv fillpat=-1		//set the fill to erase
	SetDrawEnv fillpat=1			//keep a solid fill, use DrawMode to decide y/n mask state
	if(checked)
		CheckBox DrawCheck value=0
	Endif
End

//checkbox control procedure to toggle to "draw" mode
//where the filled regions will be set to 1=yes mask
//
Function DrawCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SetDrawEnv fillPat=1		//solid fill
	if(checked)
		CheckBox EraseCheck value=0
	Endif
End

//function that polls the checkboxes to determine whether to add the 
//fill regions to the mask or to erase the fill regions from the mask
//
Function DrawMode()		//returns 1 if in "Draw" mode, 0 if "Erase" mode
	ControlInfo DrawCheck
	Return(V_Value)
End

// function that works on an individual pixel (sel) that is either part of the fill region
// or outside it (= not selected). returns either the on state (=1) or the off state (=0)
// or the current mask state if no change
//** note that the acual numeric values for the on/off state are passed in and back out - so
// the calling routine must send the correct 0/1/curr state
// **UNUSED******
Function MakeMask(sel,off,on,mask)
	Variable sel,off,on,mask
	
	variable isDrawMode
	isDrawMode = drawmode()
	
	if( sel )
		if(isDrawMode)
			return on		//add point
		else
			return off		//erase
		endif
	else
		return mask		//don't change it
	endif
end


//tempMask is already a byte wave of 0/1 values
//does the save of the tempMask, which is the current state of the mask
//
Function SaveMaskButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	WriteMask(root:myGlobals:drawMask:tempMask)
	
End

//closes the mask drawing window, first asking the user if they have saved their
//mask creation. Although lying is a bad thing, you will have to lie and say that
//you saved your mask if you ever want to close the window
//
Function DoneMaskButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoAlert 1,"Have you saved your mask?"
	if(V_flag==1) //yes selected
		DoWindow/K drawMaskWin
		KillDataFolder root:myGlobals:drawMask
		KillWaves/Z M_ROIMask
	Endif
End

//clears the entire drawing by setting it to NaN, so there is nothing displayed
//
Function ClearMaskButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SetDrawLayer/K ProgFront
	WAVE tempOverlay=root:myGlobals:drawMask:tempOverlay
	KillWaves/Z M_ROIMask,root:myGlobals:drawMask:tempMask
	if(WaveExists(tempOverlay))
		tempOverlay=NaN
	endif
End

//Macro DrawMaskMacro()
//	DrawMask()
//End

//main entry procedure for drawing a mask
//needs to have a dataset in curDispType folder to use as the background image
// for the user to draw on top of. Does not need data in the RAW folder anymore
// - initializes the necessary folder and globals, and draws the graph/control bar
//
Function DrawMask()		//main entry procedure
	//there must be data in root:curDispType:data FIRST
	SVAR curType=root:myGlobals:gDataDisplayType
	if(WaveExists($("root:Packages:NIST:"+curType+":data") ))
		DoWindow/F drawMaskWin
		If(V_flag == 0)
			InitializeDrawMask(curType)
			//draw panel
			Execute "DrawMaskWin()"
		Endif
	else
		//no data
		DoAlert 0,"Please display a representative data file using the main control panel"
	Endif
End

//initialization of the draw window, creating the necessary data folder and global
//variables if necessary
//
Function InitializeDrawMask(type)
	String type
	//create the global variables needed to run the draw window
	//all are kept in root:myGlobals:drawMask
	If( ! (DataFolderExists("root:myGlobals:drawMask"))  )
		//create the data folder and the globals
				NewDataFolder/O root:myGlobals:drawMask
				Duplicate/O $("root:Packages:NIST:"+type+":data") root:myGlobals:drawMask:data		//copy of the data
		Endif
		//if the data folder's there , then the globals must also be there so don't do anything
End

//the macro for the graph window and control bar
//
Proc DrawMaskWin()
	PauseUpdate; Silent 1		// building window...
	Display /W=(178,84,605,513) /K=2 as "Draw A Mask"
	DoWindow/C drawMaskWin
	AppendImage root:myGlobals:drawMask:data
	ModifyImage data cindex= :myGlobals:NIHColors
	ModifyGraph width={Aspect,1},height={Aspect,1},cbRGB=(32768,54615,65535)
	ModifyGraph mirror=2
	ShowTools rect
	ControlBar 70
	CheckBox drawCheck,pos={40,24},size={44,14},proc=DrawCheckProc,title="Draw"
	CheckBox drawCheck,help={"Check to add drawn regions to the mask"}
	CheckBox drawCheck,value= 1,mode=1
	CheckBox EraseCheck,pos={40,43},size={45,14},proc=EraseCheckProc,title="Erase"
	CheckBox EraseCheck,help={"Check to erase drawn regions from the mask"}
	CheckBox EraseCheck,value= 0,mode=1
	Button button1,pos={146,3},size={90,20},title="Load MASK",help={"Loads an old mask in to the draw layer"}
	Button button1,proc=LoadOldMaskButtonProc
	Button button4,pos={146,25},size={90,20},proc=ClearMaskButtonProc,title="Clear MASK"
	Button button4,help={"Clears the entire mask"}
	Button button5,pos={290,7},size={50,20},proc=SaveMaskButtonProc,title="Save"
	Button button5,help={"Saves the currently drawn mask to disk. The new mask MUST be re-read into the experiment for it to apply to data"}
	Button button6,pos={290,40},size={50,20},proc=DoneMaskButtonProc,title="Done"
	Button button6,help={"Closes the window. Reminds you to save your mask before quitting"}
	Button button0,pos={130,47},size={120,20},proc=toMASKButtonProc,title="Convert to MASK"
	Button button0,help={"Converts drawing objects to the mask layer (green)\rDoes not save the mask"}
	Button button7,pos={360,25},size={25,20},proc=ShowMaskHelp,title="?"
	Button button7,help={"Show the help file for drawing a mask"}
	GroupBox drMode,pos={26,5},size={85,61},title="Draw Mode"
	
	SetDrawLayer ProgFront
	SetDrawEnv xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode
EndMacro

Function ShowMaskHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Draw a Mask]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//loads a previously saved mask in the the draw layer
// - does not affect the state of the current mask used for data reduction
//
// SRK -SEP09 - removed hard-wired 16384 (128x128) from GBLoadWave cmd string
// for general XY compatibility (192x192) = 36864
//
Function LoadOldMaskButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	//load into temp--- root:myGlobals:drawMask:tempMask
	String fname = PromptForPath("Select Mask file")
//	ReadMCID_MASK(fname)

	// Reads MCID-format mask files written out by SANS IMAGE
	// put data into MSK data folder
	// flip the y-values to correspond to the work file
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	SetDataFolder root:myGlobals:DrawMask
	Killwaves/Z data,data0,tempMask		//kill the old data, if it exists

//	String cmd = "GBLoadWave/N=data/T={72,72}/O/S=4/W=1/U="
//	cmd += num2istr(pixelsX*pixelsY) + " /Q  \"" + fname +"\""

	String GBLoadStr = "GBLoadWave/N=data/T={72,72}/O/S=4/W=1/P=catPathName"

	if(cmpstr("\\\\",fname[0,1])==0)	//Windows user going through network neighborhood
		PathInfo catPathName
		if(V_flag==1)
			//catPathName exists, use it
			GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q/P=catPathName  \"" + ParseFilePath(0, fname, ":", 1, 0) +"\""
		else
			// need to create a temporary path
			String tmpPathStr = ParseFilePath(1, fname, ":", 1, 0)
			NewPath/O/Q tmpUNCPath tmpPathStr
			GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q/P=tmpUNCPath  \"" + ParseFilePath(0, fname, ":", 1, 0) +"\""
		endif
	else
	// original case, fname is the full path:name and is Mac (or a mapped drive)
		GBLoadStr += "/U="+num2istr(pixelsX*pixelsY) + " /Q  \"" + ParseFilePath(0, fname, ":", 1, 0) +"\""
	endif

		
	Execute GBLoadStr 
	SetDataFolder root:myGlobals:DrawMask					//make sure correct data folder is set
	WAVE data0 = $"root:myGlobals:DrawMask:data0"
	Redimension/B/N=(pixelsX,pixelsY) data0
	Flip_Y(data0)
	
	SetDataFolder root:myGlobals:DrawMask
	Rename data0,tempMask		//tempMask can be killed and re-named, since it's not on a graph
	
	SetDataFolder root:
	
	OverlayTempMask() 		//put the new mask on the image
End

//button control that commits the drawn objects to the current mask drawing
// and refreshes the drawing
//
Function toMASKButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	ImageGenerateROIMask data		//M_ROIMask is in the root: folder
	
	CumulativeMask()			//update the new mask (cumulative)
	OverlayTempMask() 		//put the new mask on the image
End

//update the current mask - either adding to the drawing or erasing it
//
//current mask is "tempMask", and is byte
//overlay is "tempOverlay" and is SP
//
Function CumulativeMask()

	//if M_ROIMask does not exist, make a quick exit
	if( ! (WaveExists(M_ROIMask)) )
		return(0)
	endif
	if(!waveExists(root:myGlobals:drawMask:tempMask))
		//make new waves
		Duplicate/O M_ROIMask root:myGlobals:drawMask:tempMask
		Wave tempM=root:myGlobals:drawMask:tempMask
		tempM=0
	else
		Wave tempM=root:myGlobals:drawMask:tempMask
	endif
	//toggle(M_ROIMask,root:myGlobals:drawMask:tempMask)
	
	WAVE M_ROIMask=M_ROIMask
	Variable isDrawMode
	isDrawMode = drawmode()		//=1 if draw, 0 if erase
	if(isDrawMode)
		tempM = (tempM || M_ROIMask)		//0=0, any 1 =1
	else
		// set all 1's in ROI to 0's in temp
		tempM = M_ROIMask ? 0 : tempM
	endif
End

//overlays the current mask (as drawn) on the base image of the drawMaskWin
// mask is drawn in the typical green, not part of the NIHColorIndex
//
// same overlay technique as for the SANS_Data window, NaN does not plot
// on an image, and is "transparent"
//
Function OverlayTempMask()

	//if tempMask does not exist, make a quick exit
	if( ! (WaveExists(root:myGlobals:drawMask:tempMask)) )
		return(0)
	endif
	//clear the draw layer
	SetDrawLayer/K ProgFront
	//append the overlay if necessary, otherwise the mask is already updated
	Duplicate/O root:myGlobals:drawMask:tempMask root:myGlobals:drawMask:tempOverlay
	WAVE tempOverlay=root:myGlobals:drawMask:tempOverlay
	Redimension/S tempOverlay
	tempOverlay=tempOverlay/tempOverlay*tempOverlay
	
	CheckDisplayed/W=DrawMaskWin tempOverlay
	//Print "V_flag = ",V_flag
	If(V_Flag == 1)
		//do nothing, already on graph
	else
		//append the new overlay
		AppendImage tempOverlay
		ModifyImage tempOverlay ctab= {0,*,BlueRedGreen,0}
	Endif
End


//********************
//writes an MCID-style MASK file, exactly as it would be output from NIH Image
//file is:
//	4 bytes
// 128x128=16384 bytes (mask) 	(in the general case, pixelsX x pixelsX = SQUARE)
// 508 bytes
// = 16896 bytes
// incoming data is a 2-D wave of any precision data, 0's and 1's
//
// tested with 192x192 data, and it works correctly (once the reader was corrected)
// - should work with generic XY dimensions
//
Function WriteMask(data)
	Wave data
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Variable refnum,ii=0,jj=0,dummy,num=pixelsX
	String fullpath=""
	
	PathInfo/S catPathName
	fullPath = DoSaveFileDialog("Save Mask file as",fname="",suffix=".MASK")		//won't actually open the file
	If(cmpstr(fullPath,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	
	Make /B/O/N=(pixelsX) byteWave
	
	//actually open the file
	Open/C="SANS"/T="MASK" refNum as fullpath
	FSetPos refNum, 0
	//write 4 bytes (to be skipped when reading the file)
	FBinWrite /F=1 refnum,ii
	FBinWrite /F=1 refnum,ii
	FBinWrite /F=1 refnum,ii
	FBinWrite /F=1 refnum,ii
	
	ii=num-1
	jj=0
	do
		byteWave=data[p][ii]
		FBinWrite /F=1 refnum,byteWave
		ii-=1
	while(ii>=0)
	
	//pad the rest of the file
	ii=0
	jj=0
	do
		FBinWrite /F=1 refnum,jj
		ii+=1
	while(ii<508)
	
	//close the file
	Close refnum
	ReadMCID_MASK(fullpath)
	Killwaves/Z byteWave
End