#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00

//
//
//
// Mask utilities:
// - loader
// - simple editor
// - save mask file
// - assign mask file to data file
//
//


///// LOADING

// DONE 
// x- when mask is loaded, need to be sure to clean up the "extra" waves that may be present
//
// x- the overlay and the currentTube waves since these are not overwritten or killed when new mask 
//  data is read in from HDF. need to manually? check for these and delete then, or the data and
//  mask overlay will be out of sync.
//


// passing null file string presents a dialog
// called from the Main Button " Read Mask"
Proc V_LoadMASKData()
	V_LoadHDF5Data("","MSK")
End



//// DRAWING/SAVING
//
// (DONE)
// x- CHANGE the mask behavior to a more logical choice - and consistent with SANS
//   x- CHANGE to:
// 1 == mask == discard data
// 0 == no Mask == keep data
// x- and then make the corresponding changes in the I(Q) routines
//
// x- move the mask generating utilities from VC_HDF5_Utils into this procedure - to keep
// all of the mask procedures together


// TODO
// -- document the arrow keys moving the tube number and adding/deleting tubes from the mask
//  this is done through a window hook function (LR moves tube number, up/down = add/delete)
//
// (DONE)
// x- (NO)- Igor 7 is necessary for some VSANS functionality, so do not support Igor 6
//    x (no)make the arrow keys Igor 6 compatible - search for specialKeyCode or Keyboard Events in the help file
//     and what needs to be replaced for Igor 6
// DONE
// x- for L/R panels, the maksing of columns should be sufficient. Tubes are vertical. For the T/B panels
//         the L/R panels cast a vertical shadow (=vertical mask) AND the tubes are horizontal, so the individual
//         tubes will likely need to be masked in a horizontal line too, per tube. ADD this in...


//TODO
// x- draw a mask
// x- save a mask (all panels)
// x- move everything into it's own folder, rather than root:
// -- be able to save the mask name to the RAW data file
// -- be able to read a mask based on what name is in the data file
//
// x- biggest thing now is to re-write the DrawDetPanel() routine from the beamCenter.ipf
//    to do what this panel needs
//
// x- add this to the list of includes, move the file to SVN, and add it.
//
// -- for working with VCALC -- maybe have an automatic generator (if val < -2e6, mask = 0)
//    this can be checked column-wise to go faster (1st index)
//
// x- re-write V_OverlayMask to make the "overlay" wave that has the NaNs, and then the drawing
//    routines need to be aware of this



// called from the main button "Draw Mask"
Proc V_Edit_a_Mask()
	V_EditMask()
end

Function V_EditMask()
	DoWindow/F MaskEditPanel
	if(V_flag==0)
	
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Mask

		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gMaskTube = 0
		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gMaskMaxIndex = 47
		
		// check for a mask, if not present, generate a default mask
		String str="FT"
		wave/Z maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")	
		if(!WaveExists(maskW))
			V_GenerateDefaultMask()
		endif
		
		Execute "V_MaskEditorPanel()"
	endif
End

//
// TODO
// -- may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
// DONE
//  need buttons for:
//		x- quit (to exit gracefully) (no, just close the window is fine)
//    x- help (button is there, fill in the content)
//
Proc V_MaskEditorPanel()
	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1		// building window...

	Display /W=(662*sc,218*sc,1300*sc,760*sc)/N=MaskEditPanel	 /K=1

	ShowTools rect
	ControlBar 100*sc
		
	PopupMenu popup_0,pos={sc*18,40*sc},size={sc*109,20*sc},proc=V_SetMaskPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""
	PopupMenu popup_2,pos={sc*18,10*sc},size={sc*109,20*sc},title="Data Source"//,proc=SetFldrPopMenuProc
	PopupMenu popup_2,mode=1,popvalue="RAW",value= #"\"RAW;SAM;ABS;VCALC;\""

	SetVariable setvar0,pos={sc*226,32*sc},size={sc*112,23*sc},title="tube number"
	SetVariable setvar0,limits={0,127,1},value=root:Packages:NIST:VSANS:Globals:Mask:gMaskTube
	Button button_0,pos={sc*226,58*sc},size={sc*50.00,20.00*sc},proc=V_AddToMaskButtonProc,title="Add"
	Button button_1,pos={sc*288,58*sc},size={sc*50.00,20.00*sc},proc=V_RemoveFromMaskButtonProc,title="Del"
	Button button_2,pos={sc*496,41*sc},size={sc*90.00,20.00*sc},proc=V_ToggleMaskButtonProc,title="Toggle"
	Button button_3,pos={sc*506,66*sc},size={sc*80.00,20.00*sc},proc=V_SaveMaskButtonProc,title="Save"
	CheckBox check_0,pos={sc*174,35*sc},size={sc*37.00,15.00*sc},proc=V_DrawMaskRadioCheckProc,title="Row"
	CheckBox check_0,value= 0,mode=1
	CheckBox check_1,pos={sc*174,58*sc},size={sc*32.00,15.00*sc},proc=V_DrawMaskRadioCheckProc,title="Col"
	CheckBox check_1,value= 1,mode=1

	Button button_5,pos={sc*18,70.00*sc},size={sc*70.00,20.00*sc},proc=V_MaskToolsButton,title="Tools"
	Button button_6,pos={sc*380,33*sc},size={sc*90.00,20.00*sc},proc=V_AddShapeToMaskButtonProc,title="Add Shape"
	Button button_7,pos={sc*380,58*sc},size={sc*90.00,20.00*sc},proc=V_AddShapeToMaskButtonProc,title="Del Shape"
	Button button_8,pos={sc*556.00,14.00*sc},size={sc*30.00,20.00*sc},proc=V_DrawMaskHelpButtonProc,title="?"

	GroupBox group0,pos={sc*163.00,5.00*sc},size={sc*188.00,90.00*sc},title="Mask Tubes"
	GroupBox group1,pos={sc*365.00,5.00*sc},size={sc*122.00,90.00*sc},title="Mask Shapes"

	SetWindow MaskEditPanel, hook(MyHook)=V_MaskWindowHook

	// draw the correct images
	//draw the detector panel
	V_DrawPanelToMask("FL")
	
	// overlay the current mask
	V_OverlayMask("FL",1)

	SetDrawLayer/W=MaskEditPanel ProgFront
	SetDrawEnv/W=MaskEditPanel xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode
EndMacro

Function V_DrawMaskHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Drawing a Mask]"
			if(V_flag !=0)
				DoAlert 0,"The VSANS Data Reduction Help file could not be found"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//a simple toggle between the two, so the logic is not done in the cleanest way.
//
// update the limits on the tube nubmer based on row/col and the panel (gMaskMaxIndex global)
//
Function V_DrawMaskRadioCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			String name = cba.ctrlName
			
			//get information to update the limits on the tube number setvar
			ControlInfo popup_0
			String str=S_Value
			wave data = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")
			Variable val
			
			// update the radio button status and the setvar limits			
			if(cmpstr(name,"check_0") == 0)		// ROW is being selected
				CheckBox check_0,value = 1
				CheckBox check_1,value = 0
				val = DimSize(data, 1) -1
			else
				// COL is being selected
				CheckBox check_0,value = 0
				CheckBox check_1,value = 1
				val = DimSize(data, 0) -1
			endif

//			print "max = ",val
						
			SetVariable setvar0,limits={0,val,1}
			NVAR gVal = root:Packages:NIST:VSANS:Globals:Mask:gMaskTube
			NVAR gMax = root:Packages:NIST:VSANS:Globals:Mask:gMaskMaxIndex
			gMax = val
			if(gVal > val)
				gVal = val
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_MaskWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	
	String message = ""

	switch(s.eventCode)
		case 11:	// Keyboard event
//			String keyCodeInfo
//			sprintf keyCodeInfo, "s.keycode = 0x%04X", s.keycode
//			if (strlen(message) > 0)
//				message += "\r"
//			endif
//			message +=keyCodeInfo
//
//			message += "\r"
//			String specialKeyCodeInfo
//			sprintf specialKeyCodeInfo, "s.specialKeyCode = %d", s.specialKeyCode
//			message +=specialKeyCodeInfo
//			message += "\r"
//
//			String keyTextInfo
//			sprintf keyTextInfo, "s.keyText = \"%s\"", s.keyText
//			message +=keyTextInfo
//
//			String text = "\\Z24" + message
//			Textbox /C/N=Message/W=KeyboardEventsGraph/A=MT/X=0/Y=15 text

		// NOTE:  these special keyCodes are all Igor-7 ONLY

// Note that I need to keep track of the index value since I'm intercepting the 
// SetVariable event here. I need to keep the index in range.		
			STRUCT WMButtonAction ba
			ba.eventCode = 2
			NVAR tubeVal = root:Packages:NIST:VSANS:Globals:Mask:gMaskTube
			if(s.specialKeyCode == 100)
				//left arrow
				tubeVal -= 1
			endif
			if(s.specialKeyCode == 101)
				//right arrow
				tubeVal += 1
			endif
			if(s.specialKeyCode == 102)
				//up arrow
				V_AddToMaskButtonProc(ba)
			endif
			if(s.specialKeyCode == 103)
				//down arrow
				V_RemoveFromMaskButtonProc(ba)
			endif

// enforce the limits on the setvar
			NVAR gMax = root:Packages:NIST:VSANS:Globals:Mask:gMaskMaxIndex
			if(tubeVal > gMax)
				tubeVal = gMax
			endif
			if(tubeVal < 0)
				tubeVal = 0
			endif
			
// draw the "currentTube" every time
			ControlInfo popup_0
			String str=S_Value
			wave currentTube = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":currentTube")

			// update so that the proper row is displayed on the currentTube
			currentTube = 0
			
			ControlInfo check_0		// is it row?
			Variable isRow = V_value
			if(isRow)
				currentTube[][tubeVal] = 1			
			else
				currentTube[tubeVal][] = 1
			endif		


			hookResult = 1	// We handled keystroke
			break
	endswitch
	
	return hookResult		// If non-zero, we handled event and Igor will ignore it.
End

// toggles the view of the mask, either show the mask, or hide it
//
Function V_ToggleMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ControlInfo popup_0
			String str=S_Value

			wave/Z overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			
			CheckDisplayed/W=MaskEditPanel overlay
			Variable state = !(V_flag)		//if V_flag == 0, then set to 1 (and vice versa)
			V_OverlayMask(str,state)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// adds a row (or column) to the mask
//
Function V_AddToMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup_0
			String str=S_Value
			
			wave/Z maskData = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")
			
			Variable val
			ControlInfo setvar0		//get the tube number
			val = V_Value
			
			ControlInfo check_0		// is it row?
			Variable isRow = V_value
			if(isRow)
				maskData[][val] = 1			
			else
				maskData[val][] = 1
			endif
			
			V_OverlayMask(str,1)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//adds or erases the mask, based on which button was clicked
// (only checks for "add shape", otherwise erases mask)
//
Function V_AddShapeToMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup_0
			String str=S_Value
			
			wave/Z data = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")

			SetDrawLayer/W=MaskEditPanel ProgFront
			SetDrawEnv/W=MaskEditPanel xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode

			ImageGenerateROIMask/W=MaskEditPanel curDispPanel		//M_ROIMask is in the root: folder
			
			WAVE M_ROIMask=M_ROIMask
			if(cmpstr("button_6",ba.ctrlName)==0)
				data = (data || M_ROIMask)		// 0=0, 1=1		== "drawing" more mask points			
			else
				data = (M_ROIMask[p][q] == 1 && data[p][q] == 1) ? 0 : data[p][q]		// if the drawn shape = 1, set the mask to 0 (erase)
			endif
			
			V_OverlayMask(str,1)
			
			SetDrawLayer/K ProgFront
			SetDrawLayer/W=MaskEditPanel ProgFront
			SetDrawEnv/W=MaskEditPanel xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// show the tools (they are there by default)
//
Function V_MaskToolsButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ShowTools/A rect			// /A flag added to workaround Igor 9(beta) bug
			
			SetDrawLayer/W=MaskEditPanel ProgFront
			SetDrawEnv/W=MaskEditPanel xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode
			SetDrawEnv/W=MaskEditPanel fillPat=1	,fillfgc= (65535,65535,65535,39000)		//set the draw fill to translucent white
			SetDrawEnv/W=MaskEditPanel save
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// un-mask a row or column
//
Function V_RemoveFromMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup_0
			String str=S_Value
			
			wave/Z maskData = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")
			
			Variable val
			ControlInfo setvar0 // get the tube number
			val = V_Value
			
			ControlInfo check_0		// is it row?
			Variable isRow = V_value
			if(isRow)
				maskData[][val] = 0			
			else
				maskData[val][] = 0
			endif
			
			V_OverlayMask(str,1)	
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// function to choose which detector panel to display, and then to actually display it
//
Function V_SetMaskPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
						
			// remove the old image (it may not be the right shape)
			// -- but make sure it exists first...

			String list = ImageNameList("", ";" )
			Variable num=ItemsInList(list)
			Variable ii
			for(ii=0;ii<num;ii+=1)
//				Wave w = ImageNameToWaveRef("", StringFromList(ii, list,";"))
//				CheckDisplayed/W=MaskEditPanel w
				
				RemoveImage/W=MaskEditPanel $(StringFromList(ii, list,";"))
			endfor


	
			// draw the correct images
			V_DrawPanelToMask(popStr)

			// fake a "click" on the radio buttons to re-set the row/col limits
			STRUCT WMCheckboxAction cba
			cba.eventCode = 2
			
			ControlInfo check_0
			if(V_flag == 1)		//row is currently selected
				cba.ctrlName = "check_0"
			else
				cba.ctrlName = "check_1"
			endif
			
			V_DrawMaskRadioCheckProc(cba)		//call the radio button action proc	
			
			//overlay the mask (removes the old mask first)
			V_OverlayMask(popStr,1)

			SetDrawLayer/K ProgFront
			SetDrawLayer/W=MaskEditPanel ProgFront
			SetDrawEnv/W=MaskEditPanel xcoord= bottom,ycoord= left,save	//be sure to use axis coordinate mode

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// SEE DrawDetPanel() in the BeamCenter file
//
// TODO
// x- currently is hard-wired for the simulation path!   need to make it more generic, especially for RAW data
//
// -- need to adjust the size of the image subwindows 
//
// x- need to do something for panel "B". currently ignored
//
//
// draw the selected panel and the model calculation, adjusting for the 
// orientation of the panel and the number of pixels, and pixel sizes
Function V_DrawPanelToMask(str)
	String str
	
	// from the selection, find the path to the data

	Variable xDim,yDim
	Variable left,top,right,bottom
	Variable height, width
	Variable left2,top2,right2,bottom2
	Variable nPix_X,nPix_Y,pixSize_X,pixSize_Y

	
//	Wave dispW=root:curDispPanel

	//plot it in the subwindow with the proper aspect and positioning
	// for 48x256 (8mm x 4mm), aspect = (256/2)/48 = 2.67 (LR panels)
	// for 128x48 (4mm x 8 mm), aspect = 48/(128/2) = 0.75 (TB panels)
	
	
	// using two switches -- one to set the panel-specific dimensions
	// and the other to set the "common" values, some of which are based on the panel dimensions

// set the source of the data. not always VCALC anymore
	String folder
	ControlInfo popup_2
	folder = S_Value

	// TODO -- fix all of this mess
	if(cmpstr(folder,"VCALC") == 0)
		// panel-specific values
		Variable VC_nPix_X = VCALC_get_nPix_X(str)
		Variable VC_nPix_Y = VCALC_get_nPix_Y(str)
		Variable VC_pixSize_X = VCALC_getPixSizeX(str)
		Variable VC_pixSize_Y = VCALC_getPixSizeY(str)

	
	// if VCALC declare this way	
		wave newW = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+str+":det_"+str)
		nPix_X = VC_nPix_X
		nPix_Y = VC_nPix_Y
		pixSize_X = VC_pixSize_X
		pixSize_Y = VC_pixSize_Y
	
	else
	// TODO: if real data, need new declaration w/ data as the wave name
		wave newW = $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+str+":data")

		nPix_X = V_getDet_pixel_num_x(folder,str)
		nPix_Y = V_getDet_pixel_num_Y(folder,str)
		pixSize_X = V_getDet_x_pixel_size(folder,str)/10
		pixSize_Y = V_getDet_y_pixel_size(folder,str)/10
	endif
	

	Variable scale = 10
	
	// common values (panel position, etc)
	// TODO -- units are absolute, based on pixels in cm. make sure this is always correct
	strswitch(str)
		case "FL":
		case "FR":
		case "ML":
		case "MR":
			width = trunc(nPix_X*pixSize_X *scale*1.15)			//48 tubes @ 8 mm
			height = trunc(nPix_Y*pixSize_Y *scale*0.8)			//128 pixels @ 8 mm
			
			left = 20
			top = 80
			right = left+width
			bottom = top+height
			
			left2 = right + 20
			right2 = left2 + width
			top2 = top
			bottom2 = bottom
			
			break			
		case "FT":
		case "FB":
		case "MT":
		case "MB":
			width = trunc(nPix_X*pixSize_X *scale*1.)			//128 pix @ 4 mm
			height = trunc(nPix_Y*pixSize_Y *scale)			// 48 tubes @ 8 mm
						
			left = 20
			top = 80
			right = left+width
			bottom = top+height
			
			left2 = left
			right2 = right
			top2 = top + height + 20
			bottom2 = bottom + height + 20
			
			break
		case "B":
			width = trunc(nPix_X/3.2)			//
			height = trunc(nPix_Y/3.2)			// 
			
			left = 20
			top = 80
			right = left+width
			bottom = top+height
			
//			Print left,top,right,bottom

			break						
		default:
			return(0)		//just exit
	endswitch

	SetDataFolder root:Packages:NIST:VSANS:Globals:Mask
	
	// generate the new panel display
	duplicate/O newW curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel
	
	NVAR defaultLogScaling = root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault
	if(defaultLogScaling)
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:logLookupWave
	else
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:linearLookupWave
	endif

	//draw the detector panel
//	Display/W=(left,top,right,bottom)
	AppendImage curDispPanel
	ModifyImage curDispPanel ctab= {*,*,ColdWarm,0}
//	ModifyImage curDispPanel log=1 		// this fails, since there are data values that are zero
	ModifyImage curDispPanel ctabAutoscale=0,lookup= LookupWave
	Label left "Y pixels"
	Label bottom "X pixels"	

	
	DoUpdate
	
	SetDataFolder root:
	return(0)
End

//
// overlay the mask
//
// (DONE)
// x- remove the old mask first
// x- make the mask "toggle" to remove it
// x- go see SANS for color, implementation, etc.
// x- un-comment the (two) calls
//
//
//toggles a mask on/off of the SANS_Data window
// points directly to window, doesn't need current display type
//
// if state==1, show the mask, if ==0, hide the mask
//
//** This assumes that if the overlay is/not present on the image display, then the currentTube is also there/not
// and is not checked
//
Function V_OverlayMask(str,state)
	String str
	Variable state


	String maskPath = "root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data"
	if(WaveExists($maskPath) == 1)
		if(state == 1)
			//duplicate the mask, which is named "data"
			wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")
	
			Duplicate/O maskW $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			Duplicate/O maskW $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":currentTube")
			wave currentTube = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":currentTube")

			Redimension/D overlay,currentTube
			SetScale/P x 0,1, overlay,currentTube
			SetScale/P y 0,1, overlay,currentTube
		
			//		overlay = (maskW == 1) ? 1 : NaN			//no need to do this - simply adjust the coloring

			// update so that the proper row is displayed on the currentTube
			currentTube = 0
						
			Variable val
			ControlInfo setvar0		//get the tube number
			val = V_Value
			
			ControlInfo check_0		// is it row?
			Variable isRow = V_value
			if(isRow)
				currentTube[][val] = 1			
			else
				currentTube[val][] = 1
			endif			
				
			CheckDisplayed/W=MaskEditPanel overlay
			if(V_flag==0)		//so the overlay doesn't get appended more than once
				AppendImage/W=MaskEditPanel overlay
				AppendImage/W=MaskEditPanel currentTube
//				ModifyImage/W=MaskEditPanel#DetData overlay ctab= {0.9,1,BlueRedGreen,0}	,minRGB=NaN,maxRGB=0
				ModifyImage/W=MaskEditPanel overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
				ModifyImage/W=MaskEditPanel currentTube ctab= {0.9,1,CyanMagenta,0}	,minRGB=NaN,maxRGB=0
		//		ModifyImage/W=MaskEditPanel#DetData overlay ctab= {0,*,BlueRedGreen,0}	
			endif
		endif

		if(state == 0)
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			wave currentTube = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":currentTube")

			CheckDisplayed/W=MaskEditPanel overlay
//			Print "V_flag = ",V_flag
	
			If(V_Flag == 1)		//overlay is present
				RemoveImage/W=MaskEditPanel overlay
				RemoveImage/W=MaskEditPanel currentTube
			endif
		endif
	Endif
	
	return(0)
End


Function V_SaveMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// fills in a "default mask" in a separate folder to then write out
			Execute "H_Setup_VSANS_MASK_Structure()"
			
			// fill with current "stuff"
			SetDataFolder root:VSANS_MASK_file:entry	
			Wave/T title	= title
			title = "This is a custom MASK file for VSANS: VSANS_MASK"
			SetDataFolder root:
			
			
		// copy over what was actually drawn for all of the detector panels

			Variable ii
			String str
			for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
				str = StringFromList(ii, ksDetectorListAll, ";")
				Wave det_str = $("root:VSANS_MASK_file:entry:instrument:detector_"+str+":data")	
				wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")			
				det_str = maskW
			endfor

			//save it
//			String fileName = "ThisIsAMASK"

			Execute "Save_VSANS_MASK_Nexus()"
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	return 0
End


////////////// fake MASK file tests
//
//
//	Make/O/T/N=1	file_name	= "VSANS_MASK_test.h5"
//
// simple generation of a fake MASK file. for sans, nothing other than the creation date was written to the 
// file header. nothing more is needed (possibly)
//
//
// TODO
// -- put in the current date, as is done for the DIV file
// -- make the number of pixels GLOBAL to pick up the right numbers for the detector dimensions
//  x- there will be lots of work to do to develop the procedures necessary to actually generate the 
//      9 data sets to become the MASK file contents. More complexity here than for the simple SANS case.
//
//  x- this is currently random 0|1 values, need to write an editor
//
// currently set up to use 1 = YES MASK == exclude the data
//      and 0 = NO MASK == keep the data
//
Proc H_Setup_VSANS_MASK_Structure()
	
	NewDataFolder/O/S root:VSANS_MASK_file		

	NewDataFolder/O/S root:VSANS_MASK_file:entry	
		Make/O/T/N=1	title	= "This is a MASK file for VSANS: VSANS_MASK"
		Make/O/T/N=1	start_date	= "2015-02-28T08:15:30-5:00"
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument		
			Make/O/T/N=1	name	= "NG3_VSANS"
			
			
//	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_B	
		if(root:Packages:NIST:VSANS:Globals:gHighResBinning == 1)
				// TODOHIGHRES - the pixel values are hard-wired
				Make/O/I/N=(2720,6624)	data	= 0		

			// TODOHIGHRES -- these values are simply the 4x4 values x4
			// these will need to be updated
				data[][0,20] = 1
				data[][6603,6623] = 1		// 
				data[0,20][] = 1
				data[2599,2719][] = 1		// 
				
			else
			// binning will always be 4, even if Denex, so it will drop here
				Variable isDenex=0
				if( cmpstr("Denex",V_getDetDescription("RAW","B")) == 0)
					isDenex = 1
				endif
				
				// fill the same description string in the MSK file so that the (B) panel will display correctly
				String detType=V_getDetDescription("RAW","B")
	
				if (isDenex)
					Variable nx = V_getDet_pixel_num_x("RAW","B")
					Variable ny = V_getDet_pixel_num_y("RAW","B")	
				
					Make/O/I/N=(nx,ny)	data	= 0		
	
					data[][0,10] = 1
					data[][ny-11,ny-1] = 1
					data[0,10][] = 1
					data[nx-11,nx-1][] = 1
				
				else
					// the normal HighRes CCD detector
					Make/O/I/N=(kNum_x_HighRes_CCD,kNum_y_HighRes_CCD)	data	= 0		
	
					data[][0,5] = 1
					data[][1650,1655] = 1
					data[0,5][] = 1
					data[675,679][] = 1
				endif

				Make/O/T/N=1 description
				description = detType
				
		endif
				
			
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MR		
			Make/O/I/N=(48,128)	data	= 0
			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_ML		
			Make/O/I/N=(48,128)	data	= 0
			data[0,3][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FR		
			Make/O/I/N=(48,128)	data	= 0
			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FL		
			Make/O/I/N=(48,128)	data	= 0
			data[0,3][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0

		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0


		// fake, empty folders so that the generic loaders can be used
		NewDataFolder/O root:VSANS_MASK_file:entry:DAS_logs
		NewDataFolder/O root:VSANS_MASK_file:entry:control
		NewDataFolder/O root:VSANS_MASK_file:entry:reduction
		NewDataFolder/O root:VSANS_MASK_file:entry:sample
		NewDataFolder/O root:VSANS_MASK_file:entry:user			
	SetDataFolder root:

End


// this default mask is only generated on startup of the panel, if a mask
// has not been previously loaded. If any mask is present ("FT" is tested) then
// this function is skipped and the existing mask is not overwritten
Function V_GenerateDefaultMask()

	NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry	
		Make/O/T/N=1	title	= "This is a MASK file for VSANS: VSANS_MASK"
		Make/O/T/N=1	start_date	= "2015-02-28T08:15:30-5:00"
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument		
			Make/O/T/N=1	name	= "NG3_VSANS"
	
	// if a mask exists, don't create another, and don't overwrite what's there
	if(exists("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FT:data") ==  1)
		return(0)
	endif		
	
	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_B	
		switch(gHighResBinning)
			case 1:
			// TODOHIGHRES - the pix values are hard-wired
				Make/O/I/N=(2720,6624)	data	= 0		

			// TODOHIGHRES -- these values are simply the 4x4 values x4
			// these will need to be updated
				data[][0,152] = 1
				data[][6195,6623] = 1		// 107 pix *4 =428
				data[0,40][] = 1
				data[2679,2719][] = 1		// 10 pix (*4)
				
				break
			case 4:
			// binning will still be the defult value of 4 even if it's the Denex detector
				Variable isDenex=0
				if( cmpstr("Denex",V_getDetDescription("RAW","B")) == 0)
					isDenex = 1
				endif

				if(isDenex)
			
					Variable nx = V_getDet_pixel_num_x("RAW","B")
					Variable ny = V_getDet_pixel_num_y("RAW","B")
					Print "MSK setup nx,ny = ",nx,ny
				
					Make/O/I/N=(nx,ny)	data	= 0		
	
					data[][0,10] = 1
					data[][ny-11,ny-1] = 1
	//				data[0,10][] = 1
					data[0,10][] = 1		//with the beam stop stuck on the detector
					data[nx-11,nx-1][] = 1
				else
					// HighRes CCD detector w/ normal 4x4 binning
					Make/O/I/N=(kNum_x_HighRes_CCD,kNum_y_HighRes_CCD)	data	= 0		
	
					data[][0,38] = 1
					data[][1535,1655] = 1
	//				data[0,10][] = 1
					data[0,190][] = 1		//with the beam stop stuck on the detector
					data[669,679][] = 1
				
				endif
				break
			default:
				Abort "No binning case matches in V_GenerateDefaultMask"
		endswitch
	
			
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MR		
			Make/O/I/N=(48,128)	data	= 0
//			data[][0,3] = 1
			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_ML		
			Make/O/I/N=(48,128)	data	= 0
			data[0,3][] = 1
//			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FR		
			Make/O/I/N=(48,128)	data	= 0
//			data[][0,3] = 1
			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FL		
			Make/O/I/N=(48,128)	data	= 0
			data[0,3][] = 1
//			data[44,47][] = 1
			data[][0,4] = 1
			data[][123,127] = 1
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0

		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
	SetDataFolder root:

end

////////////////////// MASK FILE


// (DONE)
// x- currently, there are no dummy fill values or attributes for the fake MASK file
//
Proc Setup_VSANS_MASK_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_VSANS_MASK_Structure()
	
	// writes in the attributes
//	H_Fill_VSANS_Attributes()
	

End

Proc Save_VSANS_MASK_Nexus(fileName)
	String fileName="Test_VSANS_MASK_file"

	// save as HDF5 (no attributes saved yet)
	Save_VSANS_file("root:VSANS_MASK_file", fileName+".MASK.h5")
	
//	// read in a data file using the gateway-- reads from the home path
//	H_HDF5Gate_Read_Raw(fileName+".h5")
//	
//	// after reading in a "partial" file using the gateway (to generate the xref)
//	// Save the xref to disk (for later use)
//	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
//	
//	// after you've generated the HDF5___xref, load it in and copy it
//	// to the necessary folder location.
//	Copy_HDF5___xref("root:VSANS_MASK_file", "HDF5___xref")
//	
//	// writes out the contents of a data folder using the gateway
//	H_HDF5Gate_Write_Raw("root:VSANS_MASK_file", fileName+".h5")
//
//	// re-load the data file using the gateway-- reads from the home path
//	// now with attributes
//	H_HDF5Gate_Read_Raw(fileName+".h5")
	
End




//////////////////
// procedures for an integrated panel to show the masks for all panels on a carriage
//
// also can be used to show the annular or sector ranges selected for averaging
// (so this block may be better located in one of the averaging procedure files)
// viewing the standard mask files may be a side benefit
//
//
// generally:
// - show the 4 panels on a carriage
// - allow selection of the averaging options
// - buttons for toggling of the mask, do average
//
// copy the general panel structure from DIVUtils, and add a larger control area for input
// - use the averaging routines from the main data display
//


Proc V_Display_Four_Panels()
	V_SetupPanelDisplay()
end

Function V_SetupPanelDisplay()
	DoWindow/F VSANS_Det_Panels
	if(V_flag==0)
	
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Mask

		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gAnnularQCtr = 0.1
		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gAnnularDQ = 0.01

		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gSectorAngle = 30
		Variable/G root:Packages:NIST:VSANS:Globals:Mask:gSectorDQ = 10
		
		// check for a mask, if not present, generate a default mask
		String str="FT"
		wave/Z maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")	
		if(!WaveExists(maskW))
			V_GenerateDefaultMask()
		endif
			
		Execute "V_Display_Det_Panels()"
	endif
End


//
// simple panel to display the 4 detector panels
//
// TODO:
// -- label panels, axes
// x- add in display of "B"

Proc V_Display_Det_Panels()

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(720*sc,45*sc,1500*sc,570*sc)/N=VSANS_Det_Panels/K=1
	DoWindow/C VSANS_Det_Panels
//	ModifyPanel fixedSize=1,noEdit =1


	PopupMenu popup0,pos={sc*15.00,10.00*sc},size={sc*77.00,23.00*sc},proc=V_PickCarriagePopMenuProc,title="Carriage"
	PopupMenu popup0,mode=1,value= #"\"F;M;B;\""
	PopupMenu popup1,pos={sc*100.00,10.00*sc},size={sc*68.00,23.00*sc},proc=V_PickFolderPopMenuProc,title="Folder"
	PopupMenu popup1,mode=1,popvalue="RAW",value= #"\"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;MSK;ADJ;VCALC;\""
//	PopupMenu popup1,mode=1,popvalue="RAW",value= #"\"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;MSK;ADJ;VCALC;\""
	PopupMenu popup2,pos={sc*200.00,10.00*sc},size={sc*83.00,23.00*sc},title="Bin Type"//,proc=V_DummyPopMenuProc
	PopupMenu popup2,mode=1,value= ksBinTypeStr
	PopupMenu popup3,pos={sc*350,10.00*sc},size={sc*83.00,23.00*sc},title="Average Type"//,proc=V_DummyPopMenuProc
	PopupMenu popup3,mode=1,value= #"\"Circular;Sector;Annular;\""
//	Button button0,pos={sc*520.00,10.00*sc},size={sc*110.00,20.00*sc},proc=V_UpdatePanelsButtonProc,title="Update Display"
	Button button1,pos={sc*380.00,40.00*sc},size={sc*140.00,20.00*sc},proc=V_ToggleFourMaskButtonProc,title="Regular Mask"
	Button button2,pos={sc*380.00,70.00*sc},size={sc*140.00,20.00*sc},proc=V_ShowAvgRangeButtonProc,title="Special+Reg Mask"
	Button button3,pos={sc*530.00,40.00*sc},size={sc*100.00,20.00*sc},proc=V_DoPanelAvgButtonProc,title="Do Average"
	Button button4,pos={sc*720.00,10.00*sc},size={sc*25.00,20.00*sc},proc=V_AvgPanelHelpButtonProc,title="?"

	SetVariable setvar0,pos={sc*20,40*sc},size={sc*180,23*sc},title="Annulus q-ctr (A)"
	SetVariable setvar0,limits={0,1,0.001},value=root:Packages:NIST:VSANS:Globals:Mask:gAnnularQCtr
	SetVariable setvar1,pos={sc*20,70*sc},size={sc*180,23*sc},title="Annulus (+/-) q (A)"
	SetVariable setvar1,limits={0,1,0.001},value=root:Packages:NIST:VSANS:Globals:Mask:gAnnularDQ
	SetVariable setvar2,pos={sc*210,40*sc},size={sc*160,23*sc},title="Sector Angle (deg)"
	SetVariable setvar2,limits={-90,90,1},value=root:Packages:NIST:VSANS:Globals:Mask:gSectorAngle
	SetVariable setvar3,pos={sc*210,70*sc},size={sc*160,23*sc},title="Sector (+/-) (deg)"
	SetVariable setvar3,limits={0,90,1},value=root:Packages:NIST:VSANS:Globals:Mask:gSectorDQ

	PopupMenu popup4,pos={sc*200,100*sc},size={sc*90,23.00*sc},title="Sector Side(s)"//,proc=V_DummyPopMenuProc
	PopupMenu popup4,mode=1,value= #"\"both;left;right;\""

	Make/O/B/N=(48,128) tmpLR
	Make/O/B/N=(128,48) tmpTB
	//MSK will exist (at least a default based on RAW dimensions)
//	Variable nx = V_getDet_pixel_num_x("MSK","B")		//this fails, since these fields are not in MSK data
//	Variable ny = V_getDet_pixel_num_y("MSK","B")
	Variable nx = V_getDet_pixel_num_x("RAW","B")		// call RAW, since I already trust it's there
	Variable ny = V_getDet_pixel_num_y("RAW","B")
	
	Make/O/B/N=(nx,ny) tmpB
//	Make/O/B/N=(kNum_x_HighRes_CCD,kNum_y_HighRes_CCD) tmpB
	
	tmpLR = 1
	tmpTB = 1
	tmpB = 1
	
//	Display/W=(745,45,945,425)/HOST=# 
	Display/W=(10*sc,(45+80)*sc,210*sc,(425+80)*sc)/HOST=# 
	//  root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data
	AppendImage/T/G=1 tmpLR		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly

	ModifyImage tmpLR ctab= {*,*,ColdWarm,0}
	ModifyImage tmpLR ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_L
	SetActiveSubwindow ##

//	Display/W=(1300,45,1500,425)/HOST=# 
	Display/W=(565*sc,(45+80)*sc,765*sc,(425+80)*sc)/HOST=# 
	AppendImage/T/G=1 tmpLR		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage tmpLR ctab= {*,*,ColdWarm,0}
	ModifyImage tmpLR ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_R
	SetActiveSubwindow ##

//	Display/W=(945,45,1300,235)/HOST=# 
	Display/W=(210*sc,(45+80)*sc,565*sc,(235+80)*sc)/HOST=# 
	AppendImage/T/G=1 tmpTB		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage tmpTB ctab= {*,*,ColdWarm,0}
	ModifyImage tmpTB ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_T
	SetActiveSubwindow ##

//	Display/W=(945,235,1300,425)/HOST=# 
	Display/W=(210*sc,(235+80)*sc,565*sc,(425+80)*sc)/HOST=# 
	AppendImage/T/G=1 tmpTB		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage tmpTB ctab= {*,*,ColdWarm,0}
	ModifyImage tmpTB ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_B
	SetActiveSubwindow ##
//

End


// called by the "update" button
//
// must check for overlay of mask and of avgMask
//
Function V_UpdateFourPanelDisp()


	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif

	ControlInfo/W=VSANS_Det_Panels popup0
	String carrStr = S_value

//	if(cmpstr("B",carrStr)==0)
//		DoAlert 0, "Detector B plotting not supported yet"
//		return(0)
//	endif
	
	ControlInfo/W=VSANS_Det_Panels popup1
	String folder = S_Value

	Variable isVCALC=0
	if(cmpstr("VCALC",folder)==0)
		isVCALC=1
	endif

	String tmpStr=""
//

	
	// remove everything from each of the 4 panels
	tmpStr = ImageNameList("VSANS_Det_Panels#Panel_L",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_Det_Panels#Panel_L $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_Det_Panels#Panel_L",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_Det_Panels#Panel_R",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_Det_Panels#Panel_R $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_Det_Panels#Panel_R",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_Det_Panels#Panel_T",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_Det_Panels#Panel_T $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_Det_Panels#Panel_T",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_Det_Panels#Panel_B",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_Det_Panels#Panel_B $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_Det_Panels#Panel_B",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	

	// append the new image
	// if back, put this in the "left" postion, and nothing else
	if(cmpstr("B",carrStr)==0)
		if(isVCALC)
			AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+":det_"+carrStr)		
			SetActiveSubwindow VSANS_Det_Panels#Panel_L
			ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage ''#0 ctabAutoscale=3
		else
			AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+":data")		
			SetActiveSubwindow VSANS_Det_Panels#Panel_L
			ModifyImage data ctab= {*,*,ColdWarm,0}
			ModifyImage data ctabAutoscale=3	
		endif
		ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
		ModifyGraph mirror=2
		ModifyGraph nticks=4
		ModifyGraph minor=1
		ModifyGraph fSize=9
		ModifyGraph standoff=0
		ModifyGraph tkLblRot(left)=90
		ModifyGraph btLen=3
		ModifyGraph tlOffset=-2

		if( cmpstr("Denex",V_getDetDescription(folder,"B")) == 0)
			ModifyGraph height={Aspect,1}
		endif		


		SetActiveSubwindow ##
		return(0)
	endif
	
//	RemoveImage/Z/W=VSANS_Det_Panels#Panel_L data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"L:det_"+carrStr+"L")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_L
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"L:data")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_L
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3	
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##


//	RemoveImage/Z/W=VSANS_Det_Panels#Panel_T data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_T $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"T:det_"+carrStr+"T")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_T
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_T $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"T:data")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_T
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##
	
//	RemoveImage/Z/W=VSANS_Det_Panels#Panel_B data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_B $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"B:det_"+carrStr+"B")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_B
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_B $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"B:data")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_B
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##

//	RemoveImage/Z/W=VSANS_Det_Panels#Panel_R data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_R $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"R:det_"+carrStr+"R")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_R
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_Det_Panels#Panel_R $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"R:data")		
		SetActiveSubwindow VSANS_Det_Panels#Panel_R
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##

	return(0)
End




Function V_PickFolderPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_PickCarriagePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			// update the data that is displayed
			V_UpdateFourPanelDisp()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function V_UpdatePanelsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// do nothing
			
			
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// toggle the mask overlay(s) on/off of the detector panels.
//
Function V_ToggleFourMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			String detStr
			Variable state,isVCALC
			
			ControlInfo/W=VSANS_Det_Panels popup1
			String folderStr = S_Value
			
			ControlInfo/W=VSANS_Det_Panels popup0
			String carrStr = S_Value

			if(cmpstr(folderStr,"VCALC") == 0)
				isVCALC = 1
			else
				isVCALC = 0
			endif

// handle "B" separately
			if(cmpstr(carrStr,"B") == 0)
				detStr = carrStr
				// is the mask already there?
				wave/Z overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
				CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
				if(V_Flag == 1)		//overlay is present, set state = 0 to remove overlay
					state = 0
				else
					state = 1
				endif
				
				if(state == 1)
					//duplicate the mask, which is named "data"
					wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
					// for the wave scaling
					if(isVCALC)
						wave data = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":det_"+detStr)	
					else
						wave data = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":data")	
					endif
					Duplicate/O data $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
					wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
					overlay = maskW		//this copies the data into the properly scaled wave
		
					//"B" uses the L side display			
			//	Print ImageNameList("VSANS_Det_Panels#Panel_L", ";" )
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_L overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_L overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_L ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
		
				endif		//state == 1
		
				if(state == 0)
					wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
		
					//"B" uses the L side display			
		
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_L overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_L ''#1
					endif
				endif		//state == 0
								
				return(0)
			endif		//handle carriage B


// now toggle the mask for the F or M carriages			
// test the L image to see if I need to remove the mask
			if(cmpstr(carrStr,"F")==0)
				detStr = "FL"
			else
				detStr = "ML"
			endif
			
			wave/Z overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
			CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
			if(V_Flag == 1)		//overlay is present, set state = 0 to remove overlay
				state = 0
			else
				state = 1
			endif
			
			if(cmpstr(carrStr,"F") == 0)
				V_OverlayFourMask(folderStr,"FL",state)
				V_OverlayFourMask(folderStr,"FR",state)
				V_OverlayFourMask(folderStr,"FT",state)
				V_OverlayFourMask(folderStr,"FB",state)
			else
				V_OverlayFourMask(folderStr,"ML",state)
				V_OverlayFourMask(folderStr,"MR",state)
				V_OverlayFourMask(folderStr,"MT",state)
				V_OverlayFourMask(folderStr,"MB",state)						
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_ShowAvgRangeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			ControlInfo/W=VSANS_Det_Panels popup3
			String av_type = S_Value
			
			ControlInfo/W=VSANS_Det_Panels popup1
			String folderStr = S_Value
			
			ControlInfo/W=VSANS_Det_Panels popup0
			String detGroup = S_Value
			
			Variable isVCALC
			if(cmpstr(folderStr,"VCALC")==0)
				isVCALC = 1
			else
				isVCALC = 0
			endif
			
			// calculate the "mask" to add
			
			// if circular, do nothing
			// if annular
			// if sector		
			// display the mask on the current data
			
			Variable ii
			String detStr
			String str1 = "root:Packages:NIST:VSANS:"+folderStr
			String str2 = ":entry:instrument:detector_"

			strswitch(av_type)	//dispatch to the proper routine to calculate mask

				case "Circular":	
					//do nothing
					break			
		
				case "Sector":
					ControlInfo/W=VSANS_Det_Panels popup4
					String side = S_Value
					NVAR phi_rad = root:Packages:NIST:VSANS:Globals:Mask:gSectorAngle
					NVAR dphi_rad = root:Packages:NIST:VSANS:Globals:Mask:gSectorDQ
					
					// loop over all of the panels
					// calculate phi matrix
					// fill in the mask
					for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
						detStr = StringFromList(ii, ksDetectorListAll, ";")
						Wave qTotal = $(str1+str2+detStr+":qTot_"+detStr)
						Wave phi = 	V_MakePhiMatrix(qTotal,folderStr,detStr,str1+str2+detStr)
						if(isVCALC)
							Wave w = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+detStr+":det_"+detStr)
						else
							Wave w = V_getDetectorDataW(folderStr,detStr)	//this is simply to get the correct wave scaling on the overlay
						endif
						Duplicate/O w $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
						Wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
						V_MarkSectorOverlayPixels(phi,overlay,phi_rad,dphi_rad,side)
					endfor
					
					break
				case "Sector_PlusMinus":
					break
				case "Rectangular":
					break
		
				case "Annular":

					NVAR qCtr_Ann = root:Packages:NIST:VSANS:Globals:Mask:gAnnularQCtr
					NVAR qWidth = root:Packages:NIST:VSANS:Globals:Mask:gAnnularDQ				

					// loop over all of the panels
					// fill in the mask
					for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
						detStr = StringFromList(ii, ksDetectorListAll, ";")
						Wave qTotal = $(str1+str2+detStr+":qTot_"+detStr)
						if(isVCALC)
							Wave w = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+detStr+":det_"+detStr)
						else						
							Wave w = V_getDetectorDataW(folderStr,detStr)	//this is simply to get the correct wave scaling on the overlay
						endif
						Duplicate/O w $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
						Wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
						V_MarkAnnularOverlayPixels(qTotal,overlay,qCtr_ann,qWidth)
					endfor

					break
				default:	
					//do nothing
			endswitch
				
			
			
			// switch for the overlay
			strswitch(av_type)
				case "Sector":
				case "Annular":	
				case "Sector_PlusMinus":
				case "Rectangular":
										
					Variable state = 1
		
					ControlInfo/W=VSANS_Det_Panels popup0
					String carrStr = S_Value

// handle "B" separately
				if(cmpstr(carrStr,"B") == 0)
					detStr = carrStr
					// is the mask already there?
					wave/Z overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_Flag == 1)		//overlay is present, set state = 0 to remove overlay
						state = 0
					else
						state = 1
					endif
					
					V_OverlayFourAvgMask(folderStr,"B",state)
					return(0)
				endif		//carriage "B"
					
		// test the L image to see if I need to remove the mask
					if(cmpstr(carrStr,"F")==0)
						detStr = "FL"
					else
						detStr = "ML"
					endif
					
					wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_Flag == 1)		//overlay is present
						state = 0
					else
						state = 1
					endif

// SRK 110420					
					// get the combination of the two masks
					if(cmpstr(carrStr,"F") == 0)
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FL:Overlay_FL")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FL:AvgOverlay_FL")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FR:Overlay_FR")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FR:AvgOverlay_FR")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FT:Overlay_FT")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FT:AvgOverlay_FT")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FB:Overlay_FB")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FB:AvgOverlay_FB")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						V_OverlayFourAvgMask(folderStr,"FL",state)
						V_OverlayFourAvgMask(folderStr,"FR",state)
						V_OverlayFourAvgMask(folderStr,"FT",state)
						V_OverlayFourAvgMask(folderStr,"FB",state)
					else
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_ML:Overlay_ML")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_ML:AvgOverlay_ML")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MR:Overlay_MR")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MR:AvgOverlay_MR")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MT:Overlay_MT")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MT:AvgOverlay_MT")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
						wave reg_mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MB:Overlay_MB")
						wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MB:AvgOverlay_MB")
						overlay = (reg_mask == 1 || overlay == 1) ? 1 : 0
					
					
					
						V_OverlayFourAvgMask(folderStr,"ML",state)
						V_OverlayFourAvgMask(folderStr,"MR",state)
						V_OverlayFourAvgMask(folderStr,"MT",state)
						V_OverlayFourAvgMask(folderStr,"MB",state)						
					endif
					
					break

				default:	
					//do nothing
			endswitch
			
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// see V_Proto_doAverage() and V_Proto_doPlot()
// this duplicates the switch and functionality from these operations
//
Function V_DoPanelAvgButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
	
			ControlInfo/W=VSANS_Det_Panels popup2
			Variable binType = V_BinTypeStr2Num(S_Value)
//			V_BinningModePopup("",binType,S_Value)		// does binning of current popString and updates the graph

			ControlInfo/W=VSANS_Det_Panels popup3
			String av_type = S_Value
			
			ControlInfo/W=VSANS_Det_Panels popup1
			String activeType = S_Value

			String collimationStr="pinhole"


			strswitch(av_type)	//dispatch to the proper routine to average to 1D data
				case "none":		
					//still do nothing
					// set binType and binTypeStr to bad flags
					String binTypeStr = "none"
					binType = -999999
					break			
		
				case "Circular":
					V_QBinAllPanels_Circular(activeType,binType,collimationStr)		// this does a default circular average
					V_PlotData_Panel()		//this brings the plot window to the front, or draws it (ONLY)
					V_Update1D_Graph(activeType,binType)		//update the graph, data was already binned		
					break
					
				case "Sector":
					ControlInfo/W=VSANS_Det_Panels popup4
					String side = S_Value
					NVAR phi = root:Packages:NIST:VSANS:Globals:Mask:gSectorAngle
					NVAR delta = root:Packages:NIST:VSANS:Globals:Mask:gSectorDQ
								
				// convert the angles to radians before passing					
					V_QBinAllPanels_Sector(activeType,binType,collimationStr,side,phi*pi/180,delta*pi/180)
					V_PlotData_Panel()		//this brings the plot window to the front, or draws it (ONLY)
					V_Update1D_Graph(activeType,binType)		//update the graph, data was already binned		
					break
				case "Sector_PlusMinus":
		//			Sector_PlusMinus1D(activeType)
					break
				case "Rectangular":
		//			RectangularAverageTo1D(activeType)
					break
		
				case "Annular":
					ControlInfo/W=VSANS_Det_Panels popup0
					String detGroup = S_Value
					NVAR qCtr_Ann = root:Packages:NIST:VSANS:Globals:Mask:gAnnularQCtr
					NVAR qWidth = root:Packages:NIST:VSANS:Globals:Mask:gAnnularDQ				
					//String detGroup = StringByKey("DETGROUP",avgStr,"=",";")
					//Variable qCtr_Ann = NumberByKey("QCENTER",avgStr,"=",";")
					//Variable qWidth = NumberByKey("QDELTA",avgStr,"=",";")
					V_QBinAllPanels_Annular(activeType,detGroup,qCtr_Ann,qWidth)
					V_Phi_Graph_Proc(activeType,detGroup)
					break
		
				case "Narrow_Slit":
					V_QBinAllPanels_Slit(activeType,binType)		// this does a tall, narrow slit average
					V_PlotData_Panel()		//this brings the plot window to the front, or draws it (ONLY)
					V_Update1D_Graph(activeType,binType)		//update the graph, data was already binned		
					
					break
					
				case "2D_ASCII":	
					//do nothing
					break
				case "QxQy_ASCII":
					//do nothing
					break
				case "PNG_Graphic":
					//do nothing
					break
				default:	
					//do nothing
			endswitch

				
			break
		case -1: // control being killed
			break
	endswitch



	return 0
End

Function V_AvgPanelHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Show Mask for Averaging]"
			if(V_flag !=0)
				DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
			endif	
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



//
// overlay the mask
//
//
// if state==1, show the mask, if ==0, hide the mask
//
//
Function V_OverlayFourMask(folderStr,detStr,state)
	String folderStr,detStr
	Variable state


	Variable isVCALC=0
	if(cmpstr("VCALC",folderStr)==0)
		isVCALC=1
	endif
	
	String maskPath = "root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data"
	if(WaveExists($maskPath) == 1)
		
		
		if(state == 1)
			//duplicate the mask, which is named "data"
			wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
			// for the wave scaling
			if(isVCALC)
				wave data = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":det_"+detStr)	
			else
				wave data = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":data")	
			endif
			Duplicate/O data $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)
			overlay = maskW		//this copies the data into the properly scaled wave
			
			strswitch(detStr)
				case "ML":
				case "FL":
//					Print ImageNameList("VSANS_Det_Panels#Panel_L", ";" )
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_L overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_L overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_L ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break
				case "MR":
				case "FR":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_R overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_R overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_R overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_R ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break
				case "MT":
				case "FT":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_T overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_T overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_T overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_T ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break					
				case "MB":
				case "FB":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_B overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_B overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_B overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_B ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break					
				default:			
					//
					Print "off bottom of switch"
			endswitch
		endif		//state == 1

		if(state == 0)
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)

			strswitch(detStr)
				case "ML":
				case "FL":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_L overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_L ''#1
					endif
					break
				case "MR":
				case "FR":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_R overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_R overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_R ''#1
					endif
					break
				case "MT":
				case "FT":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_T overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_T overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_T ''#1
					endif
					break					
				case "MB":
				case "FB":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_B overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_B overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_B ''#1
					endif
					break					
				default:			
					//
					Print "off bottom of switch"
			endswitch
		endif		//state == 0
		
	Endif
	
	return(0)
End


//
// overlay the mask
//
//
// if state==1, show the mask, if ==0, hide the mask
//
//
Function V_OverlayFourAvgMask(folderStr,detStr,state)
	String folderStr,detStr
	Variable state

//	Variable isVCALC=0
//	if(cmpstr("VCALC",folderStr)==0)
//		isVCALC=1
//	endif
	
	String maskPath = "root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data"
	if(WaveExists($maskPath) == 1)
		
		
		if(state == 1)
			//duplicate the mask, which is named "AvgOverlay_"
//			wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
//			// for the wave scaling
//			wave data = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":data")	
//			Duplicate/O data $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":overlay_"+detStr)

//			if(isVCALC)
//				wave overlay = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)	
//			else
				wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)
//			endif
//			overlay = maskW		//this copies the data into the properly scaled wave
			
			strswitch(detStr)
				case "ML":
				case "FL":
				case "B":
//					Print ImageNameList("VSANS_Det_Panels#Panel_L", ";" )
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_L overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_L overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_L ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break
				case "MR":
				case "FR":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_R overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_R overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_R overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_R ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break
				case "MT":
				case "FT":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_T overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_T overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_T overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_T ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break					
				case "MB":
				case "FB":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_B overlay
					if(V_flag==0)		//so the overlay doesn't get appended more than once
						AppendImage/T/W=VSANS_Det_Panels#Panel_B overlay
		//				ModifyImage/W=VSANS_Det_Panels#Panel_B overlay ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
						ModifyImage/W=VSANS_Det_Panels#Panel_B ''#1 ctab= {0.9,0.95,BlueRedGreen,0}	,minRGB=NaN,maxRGB=(0,65000,0,35000)
					endif
					break					
				default:			
					//
					Print "off bottom of switch"
			endswitch
		endif		//state == 1

		if(state == 0)
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":AvgOverlay_"+detStr)

			strswitch(detStr)
				case "ML":
				case "FL":
				case "B":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_L overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_L overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_L ''#1
					endif
					break
				case "MR":
				case "FR":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_R overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_R overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_R ''#1
					endif
					break
				case "MT":
				case "FT":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_T overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_T overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_T ''#1
					endif
					break					
				case "MB":
				case "FB":
					CheckDisplayed/W=VSANS_Det_Panels#Panel_B overlay
					if(V_Flag == 1)		//overlay is present
		//				RemoveImage/W=VSANS_Det_Panels#Panel_B overlay
						RemoveImage/W=VSANS_Det_Panels#Panel_B ''#1
					endif
					break					
				default:			
					//
					Print "off bottom of switch"
			endswitch
		endif		//state == 0
		
	Endif
	
	return(0)
End


