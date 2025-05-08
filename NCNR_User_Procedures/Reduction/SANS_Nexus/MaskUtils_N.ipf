#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma version=5.0
#pragma IgorVersion=6.1

// JAN 2022
// updated to read/write mask file in HDF (Nexus) format
// that is a simplified version of the RAW data file
// -- mimics what is done in VSANS code

//
// (DONE) -- many path references are incorrect, poining to the old data
// location, not the new Nexus location.

// root:Packages:NIST:RAW:entry:instrument:detector:data
//
// (DONE) - delete the MCID file R/W routines. make sure that they are gone
// so they can't inadvertantly be called
//

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
	string fname = PromptForPath("Select Mask file")
	if(strlen(fname) == 0)
		return
	endif

	LoadRawSANSData(fname, "MSK")
	//	ReadMCID_MASK(fname)

	//SetDataFolder root:Packages:NIST:MSK

	maskButtonProc("maskButton")
	//	OverlayMask(1)

	//back to root folder (redundant)
	SetDataFolder root:
EndMacro

//**********************
// for drawing a mask, see GraphWaveDraw (and Edit)
//and for Image progessing demo - look in the examples forder in the
//IGOR Pro folder....possible slider bar, constrast adjustment
//
//the following are macros and functions to overlay a mask on an image
//
//ResetLoop sets all of the zeros in the mask to NaN's so that they are
//not plotted
Function ResetLoop(string tempStr)

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	variable ii   = 0
	variable jj   = 0
	WAVE     junk = $tempStr

	do
		jj = 0
		do
			if(junk[ii][jj] == 0)
				junk[ii][jj] = NaN
			else
				junk[ii][jj] = 1
			endif
			jj += 1
		while(jj < pixelsY)
		ii += 1
	while(ii < pixelsX)
End

//
//toggles a mask on/off of the SANS_Data window
// points directly to window, doesn't need current display type
//
// if state==1, show the mask, if ==0, hide the mask
Function OverlayMask(variable state)

	string maskPath = "root:Packages:NIST:MSK:entry:instrument:detector:data"
	if(WaveExists($maskPath) == 1)
		//duplicate the mask, which is named "data"
		Duplicate/O root:Packages:NIST:MSK:entry:instrument:detector:data, root:Packages:NIST:MSK:overlay
		Redimension/D root:Packages:NIST:MSK:overlay

		string tempStr = "root:Packages:NIST:MSK:overlay"
		ResetLoop(tempStr) //keeps 1's and sets 0's to NaN

		//check to see if mask overlay is currently displayed
		DoWindow SANS_Data
		if(V_flag == 0)
			return (0)
		endif

		CheckDisplayed/W=SANS_Data root:Packages:NIST:MSK:overlay
		//Print "V_flag = ",V_flag

		if(V_Flag == 1) //overlay is present
			if(state == 0)
				RemoveImage overlay
			endif //don't need to do anything if we want to keep the mask
		else //overlay is not present
			if(state == 1)
				//append the new overlay
				AppendImage/L=left/B=bottom root:Packages:NIST:MSK:overlay
				//set the color table to vary from 0 to * (=max data = 1), with blue maximum
				//Nan's will appear transparent (just a general feature of images)
				ModifyImage/W=SANS_Data overlay, ctab={0, *, BlueRedGreen, 0}
			endif //don't do anything if we don't want the overlay
		endif
	endif
End

//checkbox control procedure to toggle to "erase" mode
//where the filled regions will be set to 0=no mask
//
Function EraseCheckProc(string ctrlName, variable checked) : CheckBoxControl

	//SetDrawEnv fillpat=-1		//set the fill to erase
	SetDrawEnv fillpat=1 //keep a solid fill, use DrawMode to decide y/n mask state
	if(checked)
		CheckBox DrawCheck, value=0
	endif
End

//checkbox control procedure to toggle to "draw" mode
//where the filled regions will be set to 1=yes mask
//
Function DrawCheckProc(string ctrlName, variable checked) : CheckBoxControl

	SetDrawEnv fillPat=1 //solid fill
	if(checked)
		CheckBox EraseCheck, value=0
	endif
End

//function that polls the checkboxes to determine whether to add the
//fill regions to the mask or to erase the fill regions from the mask
//
Function DrawMode() //returns 1 if in "Draw" mode, 0 if "Erase" mode

	ControlInfo DrawCheck
	return (V_Value)
End

// function that works on an individual pixel (sel) that is either part of the fill region
// or outside it (= not selected). returns either the on state (=1) or the off state (=0)
// or the current mask state if no change
//** note that the acual numeric values for the on/off state are passed in and back out - so
// the calling routine must send the correct 0/1/curr state
// **UNUSED******
Function MakeMask(variable sel, variable off, variable on, variable mask)

	variable isDrawMode
	isDrawMode = drawmode()

	if(sel)
		if(isDrawMode)
			return on //add point
		endif

		return off //erase
	else
		return mask //don't change it
	endif
End

//tempMask is already a byte wave of 0/1 values
//does the save of the tempMask, which is the current state of the mask
//
Function SaveMaskButtonProc(string ctrlName) : ButtonControl

	// fills in a "default mask" in a separate folder to then write out
	Execute "H_Setup_SANS_MASK_Structure()"

	// copy over what was actually drawn to the temp mask folder
	WAVE mask_drawn = $("root:myGlobals:drawMask:tempMask")

	WAVE mask_to_save = $("root:SANS_MASK_file:entry:instrument:detector:data")
	mask_to_save = mask_drawn

	Execute "Save_SANS_MASK_Nexus()"

	//	WriteMask(root:myGlobals:drawMask:tempMask)

	return (0)
End

//closes the mask drawing window, first asking the user if they have saved their
//mask creation. Although lying is a bad thing, you will have to lie and say that
//you saved your mask if you ever want to close the window
//
Function DoneMaskButtonProc(string ctrlName) : ButtonControl

	DoAlert 1, "Have you saved your mask?"
	if(V_flag == 1) //yes selected
		DoWindow/K drawMaskWin
		KillDataFolder root:myGlobals:drawMask
		KillWaves/Z M_ROIMask
	endif
End

//clears the entire drawing by setting it to NaN, so there is nothing displayed
//
Function ClearMaskButtonProc(string ctrlName) : ButtonControl

	SetDrawLayer/K ProgFront
	WAVE tempOverlay = root:myGlobals:drawMask:tempOverlay
	KillWaves/Z M_ROIMask, root:myGlobals:drawMask:tempMask
	if(WaveExists(tempOverlay))
		tempOverlay = NaN
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
Function DrawMask() //main entry procedure

	//there must be data in root:curDispType:data FIRST
	SVAR curType = root:myGlobals:gDataDisplayType

	//	root:Packages:NIST:RAW:entry:instrument:detector:data

	if(WaveExists($("root:Packages:NIST:" + curType + ":entry:instrument:detector:data")))
		DoWindow/F drawMaskWin
		if(V_flag == 0)
			InitializeDrawMask(curType)
			//draw panel
			Execute "DrawMaskWin()"
		endif
	else
		//no data
		DoAlert 0, "Please display a representative data file using the main control panel"
	endif
End

//initialization of the draw window, creating the necessary data folder and global
//variables if necessary
//
Function InitializeDrawMask(string type)

	//create the global variables needed to run the draw window
	//all are kept in root:myGlobals:drawMask
	if(!(DataFolderExists("root:myGlobals:drawMask")))
		//create the data folder and the globals
		NewDataFolder/O root:myGlobals:drawMask
		Duplicate/O $("root:Packages:NIST:" + type + ":entry:instrument:detector:data"), root:myGlobals:drawMask:data //copy of the data
	endif
	//if the data folder's there , then the globals must also be there so don't do anything
End

//the macro for the graph window and control bar
//
Proc DrawMaskWin()
	PauseUpdate; Silent 1 // building window...
	Display/W=(178, 84, 605, 513)/K=2 as "Draw A Mask"
	DoWindow/C drawMaskWin
	AppendImage root:myGlobals:drawMask:data
	ModifyImage data, cindex=:myGlobals:NIHColors
	ModifyGraph width={Aspect, 1}, height={Aspect, 1}, cbRGB=(32768, 54615, 65535)
	ModifyGraph mirror=2
	ShowTools rect
	ControlBar 70
	CheckBox drawCheck, pos={40, 24}, size={44, 14}, proc=DrawCheckProc, title="Draw"
	CheckBox drawCheck, help={"Check to add drawn regions to the mask"}
	CheckBox drawCheck, value=1, mode=1
	CheckBox EraseCheck, pos={40, 43}, size={45, 14}, proc=EraseCheckProc, title="Erase"
	CheckBox EraseCheck, help={"Check to erase drawn regions from the mask"}
	CheckBox EraseCheck, value=0, mode=1
	Button button1, pos={146, 3}, size={90, 20}, title="Load MASK", help={"Loads an old mask in to the draw layer"}
	Button button1, proc=LoadOldMaskButtonProc
	Button button4, pos={146, 25}, size={90, 20}, proc=ClearMaskButtonProc, title="Clear MASK"
	Button button4, help={"Clears the entire mask"}
	Button button5, pos={290, 7}, size={50, 20}, proc=SaveMaskButtonProc, title="Save"
	Button button5, help={"Saves the currently drawn mask to disk. The new mask MUST be re-read into the experiment for it to apply to data"}
	Button button6, pos={290, 40}, size={50, 20}, proc=DoneMaskButtonProc, title="Done"
	Button button6, help={"Closes the window. Reminds you to save your mask before quitting"}
	Button button0, pos={130, 47}, size={120, 20}, proc=toMASKButtonProc, title="Convert to MASK"
	Button button0, help={"Converts drawing objects to the mask layer (green)\rDoes not save the mask"}
	Button button7, pos={360, 25}, size={25, 20}, proc=ShowMaskHelp, title="?"
	Button button7, help={"Show the help file for drawing a mask"}
	GroupBox drMode, pos={26, 5}, size={85, 61}, title="Draw Mode"

	SetDrawLayer ProgFront
	SetDrawEnv xcoord=bottom, ycoord=left, save //be sure to use axis coordinate mode
EndMacro

Function ShowMaskHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Draw a Mask]"
	if(V_flag != 0)
		DoAlert 0, "The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//loads a previously saved mask in the the draw layer
// previous behavior for SANS was that this operation did
// not affect the state of the current mask used for data reduction
//  BUT - now it wipes the current MSK data out
//

// loads MASK file into MSK, then copies data over
// to the tmp storage for drawing
// - then overlays the mask on the data
//
Function LoadOldMaskButtonProc(string ctrlName) : ButtonControl

	//load into temp--- root:myGlobals:drawMask:tempMask
	string fname = PromptForPath("Select Mask file")

	LoadRawSANSData(fname, "MSK")

	SetDataFolder root:myGlobals:DrawMask
	Killwaves/Z data, data0, tempMask //kill the old data, if it exists

	// copy over the loaded mask into the draw layer
	WAVE mask_loaded = $("root:Packages:NIST:MSK:entry:instrument:detector:data")
	Duplicate/O mask_loaded, $("root:myGlobals:drawMask:tempMask")

	SetDataFolder root:

	OverlayTempMask() //put the new mask on the image
End

//button control that commits the drawn objects to the current mask drawing
// and refreshes the drawing
//
Function toMASKButtonProc(string ctrlName) : ButtonControl

	ImageGenerateROIMask data //M_ROIMask is in the root: folder

	CumulativeMask() //update the new mask (cumulative)
	OverlayTempMask() //put the new mask on the image
End

//update the current mask - either adding to the drawing or erasing it
//
//current mask is "tempMask", and is byte
//overlay is "tempOverlay" and is SP
//
Function CumulativeMask()

	WAVE M_ROIMask = M_ROIMask
	//if M_ROIMask does not exist, make a quick exit
	if(!(WaveExists(M_ROIMask)))
		return (0)
	endif
	if(!waveExists(root:myGlobals:drawMask:tempMask))
		//make new waves
		Duplicate/O M_ROIMask, root:myGlobals:drawMask:tempMask
		WAVE tempM = root:myGlobals:drawMask:tempMask
		tempM = 0
	else
		WAVE tempM = root:myGlobals:drawMask:tempMask
	endif
	//toggle(M_ROIMask,root:myGlobals:drawMask:tempMask)

	WAVE M_ROIMask = M_ROIMask
	variable isDrawMode
	isDrawMode = drawmode() //=1 if draw, 0 if erase
	if(isDrawMode)
		tempM = (tempM || M_ROIMask) //0=0, any 1 =1
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
	if(!(WaveExists(root:myGlobals:drawMask:tempMask)))
		return (0)
	endif
	//clear the draw layer
	SetDrawLayer/K ProgFront
	//append the overlay if necessary, otherwise the mask is already updated
	Duplicate/O root:myGlobals:drawMask:tempMask, root:myGlobals:drawMask:tempOverlay
	WAVE tempOverlay = root:myGlobals:drawMask:tempOverlay
	Redimension/S tempOverlay
	tempOverlay = tempOverlay / tempOverlay * tempOverlay

	CheckDisplayed/W=DrawMaskWin tempOverlay
	//Print "V_flag = ",V_flag
	if(V_Flag == 1)
		//do nothing, already on graph
	else
		//append the new overlay
		AppendImage tempOverlay
		ModifyImage tempOverlay, ctab={0, *, BlueRedGreen, 0}
	endif
End

//// NEW UTILS to save MASK files as HDF5/NEXUS
// JAN 2022

//
// simple generation of a fake MASK file. for sans, nothing other than the creation date was written to the
// file header. nothing more is needed (possibly)
//
//
//  set up to use 1 = YES MASK == exclude the data
//      and 0 = NO MASK == keep the data
//
Proc H_Setup_SANS_MASK_Structure()

	variable nx, ny
	if(cmpstr(ksDetType, "Tubes") == 0)
		// tube values
		nx = 112
		ny = 128

	else
		//Ordela values
		nx = 128
		ny = 128

	endif

	NewDataFolder/O/S root:SANS_MASK_file

	NewDataFolder/O/S root:SANS_MASK_file:entry
	Make/O/T/N=1 title = "This is a MASK file for NGB 10m SANS: SANS_MASK"
	Make/O/T/N=1 start_date = "2022-01-16T06:15:30-5:00"
	NewDataFolder/O/S root:SANS_MASK_file:entry:instrument
	Make/O/T/N=1 name = "SANS_NGB"

	NewDataFolder/O/S root:SANS_MASK_file:entry:instrument:detector
	Make/O/I/N=(nx, ny) data = 0
	data[0, 2][]           = 1
	data[nx - 3, nx - 1][] = 1
	data[][0, 2]           = 1
	data[][ny - 3, ny - 1] = 1

	// fake, empty folders so that the generic loaders can be used
	NewDataFolder/O root:SANS_MASK_file:entry:DAS_logs
	NewDataFolder/O root:SANS_MASK_file:entry:control
	NewDataFolder/O root:SANS_MASK_file:entry:reduction
	NewDataFolder/O root:SANS_MASK_file:entry:sample
	NewDataFolder/O root:SANS_MASK_file:entry:user
	SetDataFolder root:

EndMacro

// this default mask is only generated on startup of the panel, if a mask
// has not been previously loaded. If a mask is present then
// this function is skipped and the existing mask is not overwritten
Function V_GenerateDefaultMask()

	NewDataFolder/O/S root:Packages:NIST:MSK:entry
	Make/O/T/N=1 title = "This is a MASK file for SANS: SANS_MASK"
	Make/O/T/N=1 start_date = "2022-01-16T06:15:30-5:00"
	NewDataFolder/O/S root:Packages:NIST:MSK:entry:instrument
	Make/O/T/N=1 name = "SANS_NGx"

	// if a mask exists, don't create another, and don't overwrite what's there
	if(exists("root:Packages:NIST:MSK:entry:instrument:detector:data") == 1)
		return (0)
	endif

	if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
		NewDataFolder/O/S root:Packages:NIST:MSK:entry:instrument:detector
		Make/O/I/N=(128, 128) data = 0
		data[0, 2][]     = 1
		data[125, 127][] = 1
		data[][0, 2]     = 1
		data[][125, 127] = 1
	else
		NewDataFolder/O/S root:Packages:NIST:MSK:entry:instrument:detector
		Make/O/I/N=(112, 128) data = 0
		data[0, 2][]     = 1
		data[109, 111][] = 1
		data[][0, 2]     = 1
		data[][125, 127] = 1
	endif

	SetDataFolder root:

End

////////////////////// MASK FILE

// (DONE)
// x- currently, there are no dummy fill values or attributes for the fake MASK file
//
Proc Setup_SANS_MASK_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_SANS_MASK_Structure()

EndMacro

Proc Save_SANS_MASK_Nexus(fileName)
	string fileName = "Test_SANS_MASK_file"

	// save as HDF5 (no attributes saved yet)
	Save_SANS_file("root:SANS_MASK_file", fileName + ".MASK.h5")

EndMacro

