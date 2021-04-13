#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


// Isolation of a single detector panel for inspection, verifying the corrections, troubleshooting, etc.

////////////////////////////////
// As of 2021 - this isolation mode has never been fully worked out or used as I 
// had originally intended - it's really never been used, At his point I need to see
// if there is anything salvageable in this procedure file - and scrap the rest.
////////////////////////////////

// show:
// graph (raw + corrected?)
// all the fields pertinent to the detector
// all of the tables of parameters (one at a time?)
// + a way to edit them if possible? or leave this to patch?
// way to toggle corrections on/off
// draw arcs to show concentric rings around the beam center


// TODO
// -- verify the flow of operations - that is, what is the state of what is displayed? After doing
//    the corrections, popping the detector panel will display from RAW, but really should display from ADJ
// -- need labels on images to know what they are
// -- does it mean anything to "not" do the non-linear correction. I think I always calculate it in the background
//    when the RAW data is loaded, and always use the corrected real-space distances for the calculation of q-values
//    (so there is no visible effect on pixels)...
// -- interaction with the main data display will allow seeing the whole set of detectors. What is the benefit of
//    this isolation? Should I make a bigger, more visible detector image?
// x- link the function to the Isolate button on the main panel
//
// -- figure out how to (better?) re-plot the images when swapping between LR and TB panels
// -- graphically show the beam center / radius of where it is in relation to the panel
//
// -- when selecting the detector, set the x/y pixel sizes -- un-do this?
// -- The xPixels, yPixels axis labels are not correct. The axes are scaled to the beam center, through
//    a call to V_RestorePanels() when the raw data is loaded. The BeamCenter panel removes this wave scaling
//    so that the data can be presented (and fit) purely as pixels. On the isolate panel, the scaling has not
//    been removed and is confusing, especially on T/B panels.
// -- add a checkbox or button to remove/replace the wave scaling to the beam center. this is in a sense, 
//    a correction to toggle.
//
//


Function V_DetectorIsolate()
	DoWindow/F IsolateDetector
	if(V_flag==0)
	
		Execute "VC_Initialize_Space()"		// initializes VCALC space, so that dummy values are present for MSK and DIV
	
		Execute "V_IsolateDetectorPanel()"
	endif
End


//
// TODO - may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
Proc V_IsolateDetectorPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel /W=(662*sc,418*sc,1586*sc,960*sc)/N=IsolateDetector /K=1
//	ShowTools/A
	
	PopupMenu popup_0,pos={sc*169,18*sc},size={sc*109,20*sc},proc=V_isoSetDetPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""
//	PopupMenu popup_1,pos={sc*200,20*sc},size={sc*157,20*sc},proc=DetModelPopMenuProc,title="Model Function"
//	PopupMenu popup_1,mode=1,popvalue="BroadPeak",value= #"\"BroadPeak;other;\""
	PopupMenu popup_2,pos={sc*20,18*sc},size={sc*109,20*sc},title="Data Source",proc=V_SetFldrPopMenuProc
	PopupMenu popup_2,mode=1,popvalue="RAW",value= #"\"RAW;SAM;EMP;BGD;DIV;MSK;\""
		
	Button button_0,pos={sc*541,79*sc},size={sc*130,20*sc},proc=V_isoCorrectButtonProc,title="Apply Corrections"
//	Button button_1,pos={sc*651,79*sc},size={sc*80,20*sc},proc=V_isoDetFitGuessButtonProc,title="Guess"
	Button button_2,pos={sc*821,20*sc},size={sc*80,20*sc},proc=V_isoHelpButtonProc,title="Help"



	CheckBox check_0,pos={sc*542.00,131.00*sc},size={sc*110.00,16.00*sc},title="non-linear correction"
	CheckBox check_0,value= 0
	CheckBox check_1,pos={sc*542.00,159.00*sc},size={sc*110.00,16.00*sc},title="dead time correction"
	CheckBox check_1,value= 0
	CheckBox check_2,pos={sc*542.00,187.00*sc},size={sc*110.00,16.00*sc},title="solid angle correction"
	CheckBox check_2,value= 0
	CheckBox check_3,pos={sc*542.00,215.00*sc},size={sc*110.00,16.00*sc},title="sensitivity (DIV) correction"
	CheckBox check_3,value= 0
	CheckBox check_4,pos={sc*542.00,243.00*sc},size={sc*110.00,16.00*sc},title="transmission correction"
	CheckBox check_4,value= 0
	CheckBox check_5,pos={sc*542.00,271.00*sc},size={sc*110.00,16.00*sc},title="tube shadow correction"
	CheckBox check_5,value= 0
	CheckBox check_6,pos={sc*542.00,300.00*sc},size={sc*110.00,16.00*sc},title="monitor normalization"
	CheckBox check_6,value= 0



//	SetDataFolder root:Packages:NIST:VSANS:Globals:Isolate

//	duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data curDispPanel
//	SetScale/P x 0,1, curDispPanel
//	SetScale/P y 0,1, curDispPanel
//	Duplicate/O curDispPanel correctedPanel

//	SetDataFolder root:
	
	V_CopyHDFToWorkFolder("RAW","ADJ")
	
	// draw the correct images
	V_isoDrawDetPanel("FL")

	

EndMacro


//
// function to choose which detector panel to display, and then to actually display it
//
Function V_isoSetDetPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
						
			// remove the old image (it may not be the right shape)
			// -- but make sure it exists first...
			String childList = ChildWindowList("IsolateDetector")
			Variable flag
			
			flag = WhichListItem("DetData", ChildList)		//returns -1 if not in list, 0+ otherwise
			if(flag != -1)
				KillWindow IsolateDetector#DetData
			endif
			
			flag = WhichListItem("ModelData", ChildList)
			if(flag != -1)
				KillWindow IsolateDetector#ModelData
			endif
	
			// draw the correct images
			V_isoDrawDetPanel(popStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// TODO - currently is hard-wired for the simulation path!
//     need to make it more generic, especially for RAW data
//
// -- need to adjust the size of the image subwindows to keep the model
//    calculation from spilling over onto the table (maybe just move the table)
// -- need to do something for panel "B". currently ignored
// -- currently the pixel sizes for "real" data is incorrect in the file
//     and this is why the plots are incorrectly sized
// -- need to be able to display MASK and DIV data (or any data without a full set of metadata)
//
//
// draw the selected panel and the model calculation, adjusting for the 
// orientation of the panel and the number of pixels, and pixel sizes
//
// str input is the panelStr ("FL" for example)
Function V_isoDrawDetPanel(str)
	String str
	
	// from the selection, find the path to the data


	Variable xDim,yDim
	Variable left,top,right,bottom
	Variable height, width
	Variable left2,top2,right2,bottom2
	Variable nPix_X,nPix_Y,pixSize_X,pixSize_Y


//	Wave dispW=root:Packages:NIST:VSANS:Globals:Isolate:curDispPanel
//	Wave corrW=root:Packages:NIST:VSANS:Globals:Isolate:correctedPanel

	//plot it in the subwindow with the proper aspect and positioning
	// for 48x256 (8mm x 4mm), aspect = (256/2)/48 = 2.67 (LR panels)
	// for 128x48 (4mm x 8 mm), aspect = 48/(128/2) = 0.75 (TB panels)
	
	
	// using two switches -- one to set the panel-specific dimensions
	// and the other to set the "common" values, some of which are based on the panel dimensions

// set the source of the data. not always VCALC anymore
	String folder
	ControlInfo popup_2
	folder = S_Value

	Variable VC_nPix_X,VC_nPix_Y,VC_pixSize_X,VC_pixSize_Y
	// TODO -- fix all of this mess
	strswitch(folder)
		case "VCALC":
//			VC_nPix_X = VCALC_get_nPix_X(str)
//			VC_nPix_Y = VCALC_get_nPix_Y(str)
//			VC_pixSize_X = VCALC_getPixSizeX(str)
//			VC_pixSize_Y = VCALC_getPixSizeY(str)
//			wave dispW = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+str+":det_"+str)
//			nPix_X = VC_nPix_X
//			nPix_Y = VC_nPix_Y
//			pixSize_X = VC_pixSize_X
//			pixSize_Y = VC_pixSize_Y
	
			break
			
		case "DIV":
		case "MSK":
		// TODO
		// -- this takes fake data from VCALC, which is very likely wrong for DIV data
			VC_nPix_X = VCALC_get_nPix_X(str)
			VC_nPix_Y = VCALC_get_nPix_Y(str)
			VC_pixSize_X = VCALC_getPixSizeX(str)
			VC_pixSize_Y = VCALC_getPixSizeY(str)
			wave dispW = $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+str+":data")
			nPix_X = VC_nPix_X
			nPix_Y = VC_nPix_Y
			pixSize_X = VC_pixSize_X
			pixSize_Y = VC_pixSize_Y
			break

		case "RAW":
		case "ADJ":
		case "SAM":
		case "EMP":
		case "BGD":
			wave dispW = $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+str+":data")
	
			nPix_X = V_getDet_pixel_num_x(folder,str)
			nPix_Y = V_getDet_pixel_num_Y(folder,str)
			pixSize_X = V_getDet_x_pixel_size(folder,str)/10
			pixSize_Y = V_getDet_y_pixel_size(folder,str)/10
			break
				
		default:
			return(0)
	endswitch


	// and the ADJusted wave to display	
	wave corrW = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+str+":data")

	Variable scale = 5
	
	// common values (panel position, etc)
	//  -- units are absolute, based on pixels in cm. make sure this is always correct
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



//	SetDataFolder root:Packages:NIST:VSANS:Globals:Isolate
	// generate the new panel display and corrected panel (just a copy right now)
//	duplicate/O newW curDispPanel
//	SetScale/P x 0,1, curDispPanel
//	SetScale/P y 0,1, curDispPanel
//	Duplicate/O curDispPanel correctedPanel
	
	// need to be in the same folder as the data
	SetDataFolder $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+str)
	Wave data1 = data


	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	left *= sc
	top *= sc
	right *= sc
	bottom *= sc
	
	left2 *= sc
	top2 *= sc
	right2 *= sc
	bottom2 *= sc
	
	
	//draw the detector panel
	Display/W=(left,top,right,bottom)/HOST=# 
	RenameWindow #,DetData
	AppendImage/W=IsolateDetector#DetData data1
	ModifyImage/W=IsolateDetector#DetData '' ctab= {*,*,ColdWarm,0}
	Label left "Y pixels"
	Label bottom "X pixels"	
	SetActiveSubwindow ##	
	
	
	SetDataFolder $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+str)
	Wave data2 = data
	
	//draw the corrected detector panel
	// see the main display of RAW data for example of multiple 'data' images
	Display/W=(left2,top2,right2,bottom2)/HOST=#
	RenameWindow #,ModelData
	AppendImage/W=IsolateDetector#ModelData data2
	ModifyImage/W=IsolateDetector#ModelData '' ctab= {*,*,ColdWarm,0}		// the image is called '' even though the local ref is data2
	Label left "Y pixels"
	Label bottom "X pixels"	

	SetActiveSubwindow ##	


	SetDataFolder root:
		
	DoUpdate
	
	return(0)
End



//
Function V_isoCorrectButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable sav0,sav1,sav2,sav3,sav4,sav5,sav6
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// save the state of the global flags
			// poll the state of the checkboxes
			// temporarily set the global (preference) flags

//			CheckBox check_0,pos={sc*542.00,131.00*sc},size={sc*110.00,16.00*sc},title="non-linear correction"
			NVAR gDoNonLinearCor = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
			sav0 = gDoNonLinearCor
			ControlInfo check_0
			gDoNonLinearCor = V_Value
			
//			CheckBox check_1,pos={sc*542.00,159.00*sc},size={sc*110.00,16.00*sc},title="dead time correction"
			NVAR gDoDeadTimeCor = root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor
			sav1 = gDoDeadTimeCor
			ControlInfo check_1
			gDoDeadTimeCor = V_Value
			
//			CheckBox check_2,pos={sc*542.00,187.00*sc},size={sc*110.00,16.00*sc},title="solid angle correction"
			NVAR gDoSolidAngleCor = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
			sav2 = gDoSolidAngleCor
			ControlInfo check_2
			gDoSolidAngleCor = V_Value
			
//			CheckBox check_3,pos={sc*542.00,215.00*sc},size={sc*110.00,16.00*sc},title="sensitivity (DIV) correction"
			NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
			sav3 = gDoDIVCor
			ControlInfo check_3
			gDoDIVCor = V_Value
			
//			CheckBox check_4,pos={sc*542.00,243.00*sc},size={sc*110.00,16.00*sc},title="transmission correction"
			NVAR gDoTrans = root:Packages:NIST:VSANS:Globals:gDoTransmissionCor
			sav4 = gDoTrans
			ControlInfo check_4
			gDoTrans = V_Value
			
//			CheckBox check_5,pos={sc*542.00,271.00*sc},size={sc*110.00,16.00*sc},title="tube shadow correction"
			NVAR gDoTubeShadowCor = root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor
			sav5 = gDoTubeShadowCor
			ControlInfo check_5
			gDoTubeShadowCor = V_Value
			
//			CheckBox check_6,pos={sc*542.00,300.00*sc},size={sc*110.00,16.00*sc},title="monitor normalization"
			NVAR gDoMonitorNormalization = root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization
			sav6 = gDoMonitorNormalization
			ControlInfo check_6
			gDoMonitorNormalization = V_Value
			
	
			
			// raw_to_work to apply the selected corrections
			// TODO -- verify that this works correctly, since ADJ has waves in use and the folder
			//         can't be directly killed. Copy is the first step - so verify.
			V_Raw_to_work("ADJ")
			
			
			
			// set the globals back the the prior state
			gDoNonlinearCor = sav0
			gDoDeadTimeCor = sav1
			gDoSolidAngleCor = sav2
			gDoDIVCor = sav3
			gDoTrans = sav4
			gDoTubeShadowCor = sav5
			gDoMonitorNormalization = sav6
			
			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




////
// copies the data from the popped folder (either RAW or VCALC) to ADJ
//
Function V_SetFldrPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			V_CopyHDFToWorkFolder(popStr,"ADJ")
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_isoHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DoAlert 0,"Help file not written yet..."
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

