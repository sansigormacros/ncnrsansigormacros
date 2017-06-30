#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// Mask utilities:
// - loader
// - simple editor
// - save mask file
// - assign mask file to data file
//
//
//  this is (at first) to be a very simple editor to generate masks row/column wise, not drawing
//  masks with arbitrary shape. 
//
//
//
//
// 
//

///// LOADING

// TODO 
// -- when mask is loaded, need to be sure to clean up the "extra" waves that may be present
//
// -- the overlay and the currentTube waves since these are not overwritten or killed when new mask 
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
// TODO:
// x- CHANGE the mask behavior to a more logical choice - and consistent with SANS
//   x- CHANGE to:
// 1 == mask == discard data
// 0 == no Mask == keep data
// x- and then make the corresponding changes in the I(Q) routines


// x- move the mask generating utilities from VC_HDF5_Utils into this procedure - to keep
// all of the mask procedures together


// TODO
// -- document the arrow keys moving the tube number and adding/deleting tubes from the mask
//  this is done through a window hook function (LR moves tube number, up/down = add/delete)
//
// TODO
// -- make the arrow keys Igor 6 compatible - search for specialKeyCode or Keyboard Events in the help file
//     and what needs to be replaced for Igor 6
// TODO
// -- for L/R panels, the maksing of columns should be sufficient. Tubes are vertical. For the T/B panels
//         the L/R panels cast a vertical shadow (=vertical mask) AND the tubes are horizontal, so the individual
//         tubes will likely need to be masked in a horizontal line too, per tube. ADD this in...


//TODO
// x- draw a mask
// x- save a mask (all panels)
// -- move everything into it's own folder, rather than root:
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
// TODO
//  need buttons for:
//		-- quit (to exit gracefully)
//    -- help (button is there, fill in the content)
//
Proc V_MaskEditorPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	NewPanel /W=(662,418,1300,960)/N=MaskEditPanel	 /K=1
//	ShowTools/A
	
	PopupMenu popup_0,pos={20,50},size={109,20},proc=V_SetMaskPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FT",value= #"\"FL;FR;FT;FB;MR;ML;MT;MB;B;\""
	PopupMenu popup_2,pos={20,20},size={109,20},title="Data Source"//,proc=SetFldrPopMenuProc
	PopupMenu popup_2,mode=1,popvalue="RAW",value= #"\"RAW;SAM;VCALC;\""

	SetVariable setvar0,pos={257.00,20.00},size={150.00,14.00},title="tube number"
	SetVariable setvar0,limits={0,127,1},value=root:Packages:NIST:VSANS:Globals:Mask:gMaskTube
	Button button_0,pos={257,46.00},size={50.00,20.00},proc=V_AddToMaskButtonProc,title="Add"
	Button button_1,pos={319.00,46.00},size={50.00,20.00},proc=V_RemoveFromMaskButtonProc,title="Del"
	Button button_2,pos={409.00,46.00},size={90.00,20.00},proc=V_ToggleMaskButtonProc,title="Toggle"
	Button button_3,pos={509.00,46.00},size={80.00,20.00},proc=V_SaveMaskButtonProc,title="Save"
	Button button_4,pos={603.00,10.00},size={20.00,20.00},proc=V_DrawMaskHelpButtonProc,title="?"
	CheckBox check_0,pos={190.00,23.00},size={37.00,15.00},proc=V_DrawMaskRadioCheckProc,title="Row"
	CheckBox check_0,value= 0,mode=1
	CheckBox check_1,pos={190.00,46.00},size={32.00,15.00},proc=V_DrawMaskRadioCheckProc,title="Col"
	CheckBox check_1,value= 1,mode=1

	SetWindow MaskEditPanel, hook(MyHook)=V_MaskWindowHook

	// draw the correct images
	//draw the detector panel
	V_DrawPanelToMask("FT")
	
	// overlay the current mask
	V_OverlayMask("FT",1)

EndMacro

Function V_DrawMaskHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0, "Draw Mask Help not written yet..."
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


Function V_ToggleMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			ControlInfo popup_0
			String str=S_Value

			wave/Z overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			
			CheckDisplayed/W=MaskEditPanel#DetData overlay
			Variable state = !(V_flag)		//if V_flag == 0, then set to 1 (and vice versa)
			V_OverlayMask(str,state)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


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
			String childList = ChildWindowList("MaskEditPanel")
			Variable flag
			
			flag = WhichListItem("DetData", ChildList)		//returns -1 if not in list, 0+ otherwise
			if(flag != -1)
				KillWindow MaskEditPanel#DetData
			endif
			
			flag = WhichListItem("ModelData", ChildList)
			if(flag != -1)
				KillWindow MaskEditPanel#ModelData
			endif
	
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
			
			//overlay the mask
			V_OverlayMask(popStr,1)

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
// -- need to adjust the size of the image subwindows to keep the model
//    calculation from spilling over onto the table (maybe just move the table)
// -- need to do something for panel "B". currently ignored
// -- currently the pixel sizes for "real" data is incorrect in the file
//     and this is why the plots are incorrectly sized
// -- error checking if the data does not exist in selected work folder
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
			return(0)		//just exit
			break						
		default:
			return(0)		//just exit
	endswitch

	SetDataFolder root:Packages:NIST:VSANS:Globals:Mask
	
	// generate the new panel display
	duplicate/O newW curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel
	
	//draw the detector panel
	Display/W=(left,top,right,bottom)/HOST=# 
	AppendImage curDispPanel
	ModifyImage curDispPanel ctab= {*,*,ColdWarm,0}
	Label left "Y pixels"
	Label bottom "X pixels"	
	RenameWindow #,DetData
	SetActiveSubwindow ##	
	
	DoUpdate
	
	SetDataFolder root:
	return(0)
End

//
// overlay the mask
//
// 
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
				
			CheckDisplayed/W=MaskEditPanel#DetData overlay
			if(V_flag==0)		//so the overlay doesn't get appended more than once
				AppendImage/W=MaskEditPanel#DetData overlay
				AppendImage/W=MaskEditPanel#DetData currentTube
				ModifyImage/W=MaskEditPanel#DetData overlay ctab= {0.9,1,BlueRedGreen,0}	,minRGB=NaN,maxRGB=0
				ModifyImage/W=MaskEditPanel#DetData currentTube ctab= {0.9,1,CyanMagenta,0}	,minRGB=NaN,maxRGB=0
		//		ModifyImage/W=MaskEditPanel#DetData overlay ctab= {0,*,BlueRedGreen,0}	
			endif
		endif

		if(state == 0)
			wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
			wave currentTube = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":currentTube")

			CheckDisplayed/W=MaskEditPanel#DetData overlay
//			Print "V_flag = ",V_flag
	
			If(V_Flag == 1)		//overlay is present
				RemoveImage/W=MaskEditPanel#DetData overlay
				RemoveImage/W=MaskEditPanel#DetData currentTube
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
// -- make the number of pixels GLOBAL
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
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_B	
			Make/O/I/N=(150,150)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MR		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_ML		
			Make/O/I/N=(48,128)	data	= 0
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
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FL		
			Make/O/I/N=(48,128)	data	= 0
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
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_B	
			Make/O/I/N=(150,150)	data	= 0
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_MR		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_ML		
			Make/O/I/N=(48,128)	data	= 0
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
		NewDataFolder/O/S root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FL		
			Make/O/I/N=(48,128)	data	= 0
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


// TODO
// -- currently, there are no dummy fill values or attributes for the fake MASK file
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
	Save_VSANS_file("root:VSANS_MASK_file", fileName+".h5")
	
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
