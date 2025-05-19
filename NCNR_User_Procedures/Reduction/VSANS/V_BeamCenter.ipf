#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// TODO
// -- adjust the guesses to some better starting conditions
// -- multiple fit options with different things held
// x- when selecting the detector, set the x/y pixel sizes
// -- figure out how to re-plot the images when swapping between LR and TB panels
// -- Modify to accept mm (real space dimensions) rather than pixels
//    -- or be able to swap the answer to mm for a more natural definition of the beam center
// -- add method to be able to write the values to the local folder / or better, to file on disk
// -- graphically show the beam center / radius of where it is in relation to the panel
//
// x- error checking, if data is selected from a folder that does not exist (like VCALC). Otherwise
//    the user is caught in a long loop of open file dialogs looking for something...
//
// -- move everything into it's own folder, rather than root:
//
// -- am I working in detector coordinates (1->n) or in array coordinates (0->n-1)??

// FEB 2019 - updated values
//these are values from Dec 2018 data and the CENTROID on FR or MR
Constant kBCtrDelta_FL_x = 0.13
Constant kBCtrDelta_FL_y = 0.35
Constant kBCtrDelta_FB_x = 0.95
Constant kBCtrDelta_FB_y = 0.77
Constant kBCtrDelta_FT_x = 1.59
Constant kBCtrDelta_FT_y = 0.09
Constant kBCtrDelta_ML_x = 0.26
Constant kBCtrDelta_ML_y = -0.16
Constant kBCtrDelta_MB_x = -0.89
Constant kBCtrDelta_MB_y = 0.96
Constant kBCtrDelta_MT_x = -0.28
Constant kBCtrDelta_MT_y = 0.60

////these are values from Dec 2018 data and the FITTED ARC on FR or MR
// don't use these - the values from the centroid are superior)
//Constant kBCtrDelta_FL_x = 0.49
//Constant kBCtrDelta_FL_y = 0.48
//Constant kBCtrDelta_FB_x = 1.31
//Constant kBCtrDelta_FB_y = 0.90
//Constant kBCtrDelta_FT_x = 1.95
//Constant kBCtrDelta_FT_y = 0.22
//Constant kBCtrDelta_ML_x = 0.44
//Constant kBCtrDelta_ML_y = -0.32
//Constant kBCtrDelta_MB_x = -0.71
//Constant kBCtrDelta_MB_y = 0.80
//Constant kBCtrDelta_MT_x = -0.10
//Constant kBCtrDelta_MT_y = 0.44

Function V_FindBeamCenter()

	DoWindow/F PanelFit
	if(V_flag == 0)

		NewDataFolder/O root:Packages:NIST:VSANS:Globals:BeamCenter

		Execute "V_DetectorPanelFit()"
	endif
End
//
// TODO - may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
Proc V_DetectorPanelFit() : Panel
	PauseUpdate; Silent 1 // building window...

	// plot the default model to be sure some data is present
	if(exists("xwave_PeakPix2D") == 0)
		V_PlotBroadPeak_Pix2D()
	endif

	NewPanel/W=(662, 418, 1586, 960)/N=PanelFit/K=1
	//	ShowTools/A

	PopupMenu popup_0, pos={20, 50}, size={109, 20}, proc=V_SetDetPanelPopMenuProc, title="Detector Panel"
	PopupMenu popup_0, mode=1, popvalue="FL", value=#"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""
	PopupMenu popup_1, pos={200, 20}, size={157, 20}, proc=V_DetModelPopMenuProc, title="Model Function"
	PopupMenu popup_1, mode=1, popvalue="BroadPeak", value=#"\"BroadPeak;BroadPeak_constrained;PowerLaw;\""
	PopupMenu popup_2, pos={20, 20}, size={109, 20}, title="Data Source" //,proc=SetFldrPopMenuProc
	PopupMenu popup_2, mode=1, popvalue="RAW", value=#"\"RAW;SAM;VCALC;\""

	Button button_0, pos={486, 20}, size={80, 20}, proc=V_DetFitGuessButtonProc, title="Guess"
	Button button_1, pos={615, 20}, size={80, 20}, proc=V_DetFitButtonProc, title="Do Fit"
	Button button_2, pos={744, 20}, size={80, 20}, proc=V_DetFitHelpButtonProc, title="Help"
	Button button_3, pos={730, 400}, size={110, 20}, proc=V_CopyCtrButtonProc, title="Copy Centers", disable=2
	Button button_4, pos={615, 400}, size={110, 20}, proc=V_CtrTableButtonProc, title="Ctr table"
	Button button_5, pos={730, 440}, size={110, 20}, proc=V_WriteCtrTableButtonProc, title="Write table", disable=2

	Button button_6, pos={615, 470}, size={110, 20}, proc=V_MaskBeforeFitButtonProc, title="Mask Panel"
	Button button_7, pos={730, 470}, size={110, 20}, proc=V_ConvertFitPix2cmButtonProc, title="Convert Pix2Cm"
	Button button_8, pos={615, 500}, size={110, 20}, proc=V_GizmoFitButtonProc, title="Gizmo"

	SetDataFolder root:Packages:NIST:VSANS:Globals:BeamCenter

	duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data, curDispPanel
	SetScale/P x, 0, 1, curDispPanel
	SetScale/P y, 0, 1, curDispPanel

	SetDataFolder root:

	// draw the correct images
	V_DrawDetPanel("FL")

	////draw the detector panel
	//	Display/W=(20,80,200,600)/HOST=#
	//	AppendImage curDispPanel
	//	ModifyImage curDispPanel ctab= {*,*,ColdWarm,0}
	////	ModifyGraph height={Aspect,2.67}
	//	Label left "Y pixels"
	//	Label bottom "X pixels"
	//	RenameWindow #,DetData
	//	SetActiveSubwindow ##
	//
	////draw the model calculation
	//	Display/W=(220,80,400,600)/HOST=#
	//	AppendImage PeakPix2D_mat
	//	ModifyImage PeakPix2D_mat ctab= {*,*,ColdWarm,0}
	////	ModifyGraph height={Aspect,2.67}
	////	ModifyGraph width={Aspect,0.375}
	//	Label left "Y pixels"
	//	Label bottom "X pixels"
	//	RenameWindow #,ModelData
	//	SetActiveSubwindow ##

	// edit the fit coefficients
	Edit/W=(550,80,880,370)/HOST=#  parameters_PeakPix2D,coef_PeakPix2D
	ModifyTable width(Point)=0
	ModifyTable width(parameters_PeakPix2D)=120
	ModifyTable width(coef_PeakPix2D)=100
	RenameWindow #, T0
	SetActiveSubwindow ##

EndMacro

//
// function to choose which detector panel to display, and then to actually display it
//
Function V_SetDetPanelPopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum = pa.popNum
			string   popStr = pa.popStr

			// remove the old image (it may not be the right shape)
			// -- but make sure it exists first...
			string childList = ChildWindowList("PanelFit")
			variable flag

			flag = WhichListItem("DetData", ChildList) //returns -1 if not in list, 0+ otherwise
			if(flag != -1)
				KillWindow PanelFit#DetData
			endif

			flag = WhichListItem("ModelData", ChildList)
			if(flag != -1)
				KillWindow PanelFit#ModelData
			endif

			// draw the correct images
			V_DrawDetPanel(popStr)

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
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
//
// draw the selected panel and the model calculation, adjusting for the
// orientation of the panel and the number of pixels, and pixel sizes
Function V_DrawDetPanel(string str)

	// from the selection, find the path to the data

	variable xDim, yDim
	variable left, top, right, bottom
	variable height, width
	variable left2, top2, right2, bottom2
	variable nPix_X, nPix_Y, pixSize_X, pixSize_Y

	WAVE dispW = root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
	WAVE cw    = root:coef_PeakPix2D

	WAVE xwave_PeakPix2D = root:xwave_PeakPix2D
	WAVE ywave_PeakPix2D = root:ywave_PeakPix2D
	WAVE zwave_PeakPix2D = root:zwave_PeakPix2D

	//plot it in the subwindow with the proper aspect and positioning
	// for 48x256 (8mm x 4mm), aspect = (256/2)/48 = 2.67 (LR panels)
	// for 128x48 (4mm x 8 mm), aspect = 48/(128/2) = 0.75 (TB panels)

	// using two switches -- one to set the panel-specific dimensions
	// and the other to set the "common" values, some of which are based on the panel dimensions

	// set the source of the data. not always VCALC anymore
	string folder
	ControlInfo popup_2
	folder = S_Value

	// error checking -- if the VCALC folder is the target & does not exist, exit now
	if(cmpstr(folder, "VCALC") == 0 && DataFolderExists("root:Packages:NIST:VSANS:VCALC") == 0)
		return (0)
	endif

	// error checking -- if the RAW folder is the target & does not exist, exit now
	if(cmpstr(folder, "RAW") == 0 && DataFolderExists("root:Packages:NIST:VSANS:RAW:entry") == 0)
		return (0)
	endif

	// error checking -- if the SAM folder is the target & does not exist, exit now
	if(cmpstr(folder, "SAM") == 0 && DataFolderExists("root:Packages:NIST:VSANS:SAM:entry") == 0)
		return (0)
	endif

	// TODO -- fix all of this mess
	if(cmpstr(folder, "VCALC") == 0)
		// panel-specific values
		variable VC_nPix_X    = VCALC_get_nPix_X(str)
		variable VC_nPix_Y    = VCALC_get_nPix_Y(str)
		variable VC_pixSize_X = VCALC_getPixSizeX(str)
		variable VC_pixSize_Y = VCALC_getPixSizeY(str)

		// if VCALC declare this way
		WAVE newW = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_" + str + ":det_" + str)
		nPix_X    = VC_nPix_X
		nPix_Y    = VC_nPix_Y
		pixSize_X = VC_pixSize_X
		pixSize_Y = VC_pixSize_Y

	else
		// TODO: if real data, need new declaration w/ data as the wave name
		WAVE newW = $("root:Packages:NIST:VSANS:" + folder + ":entry:instrument:detector_" + str + ":data")

		nPix_X    = V_getDet_pixel_num_x(folder, str)
		nPix_Y    = V_getDet_pixel_num_Y(folder, str)
		pixSize_X = V_getDet_x_pixel_size(folder, str) / 10
		pixSize_Y = V_getDet_y_pixel_size(folder, str) / 10
	endif

	variable scale = 5

	// common values (panel position, etc)
	// TODO -- units are absolute, based on pixels in cm. make sure this is always correct
	strswitch(str)
		case "FL": // fall through by design -- all left and right panels
		case "FR": // fall through by design
		case "ML": // fall through by design
		case "MR":
			width  = trunc(nPix_X * pixSize_X * scale * 1.15) //48 tubes @ 8 mm
			height = trunc(nPix_Y * pixSize_Y * scale * 0.8)  //128 pixels @ 8 mm

			left   = 20
			top    = 80
			right  = left + width
			bottom = top + height

			left2   = right + 20
			right2  = left2 + width
			top2    = top
			bottom2 = bottom

			break
		case "FT": // fall through by design -- all top and bottom panels
		case "FB": // fall through by design
		case "MT": // fall through by design
		case "MB":
			width  = trunc(nPix_X * pixSize_X * scale * 1.) //128 pix @ 4 mm
			height = trunc(nPix_Y * pixSize_Y * scale)      // 48 tubes @ 8 mm

			left   = 20
			top    = 80
			right  = left + width
			bottom = top + height

			left2   = left
			right2  = right
			top2    = top + height + 20
			bottom2 = bottom + height + 20

			break
		case "B":
			return (0) //just exit
			break
		default:
			return (0) //just exit
	endswitch

	// set from the detector-specific strswitch
	cw[7] = pixSize_X * 10
	cw[8] = pixSize_Y * 10

	SetDataFolder root:Packages:NIST:VSANS:Globals:BeamCenter
	// generate the new panel display
	duplicate/O newW, curDispPanel
	SetScale/P x, 0, 1, curDispPanel
	SetScale/P y, 0, 1, curDispPanel

	//draw the detector panel
	Display/W=(left, top, right, bottom)/HOST=#
	AppendImage curDispPanel
	ModifyImage curDispPanel, ctab={*, *, ColdWarm, 0}
	Label left, "Y pixels"
	Label bottom, "X pixels"
	RenameWindow #, DetData
	SetActiveSubwindow ##

	SetDataFolder root:

	// re-dimension the model calculation to be the proper dimensions
	Redimension/N=(nPix_X * nPix_Y) xwave_PeakPix2D, ywave_PeakPix2D, zwave_PeakPix2D

	V_FillPixTriplet(xwave_PeakPix2D, ywave_PeakPix2D, zwave_PeakPix2D, nPix_X, nPix_Y)
	Make/O/D/N=(nPix_X, nPix_Y) PeakPix2D_mat // use the point scaling of the matrix (=pixels)

	Duplicate/O $"PeakPix2D_mat", $"PeakPix2D_lin" //keep a linear-scaled version of the data

	//draw the model calculation
	Display/W=(left2, top2, right2, bottom2)/HOST=#
	AppendImage PeakPix2D_mat
	ModifyImage PeakPix2D_mat, ctab={*, *, ColdWarm, 0}
	Label left, "Y pixels"
	Label bottom, "X pixels"
	RenameWindow #, ModelData
	SetActiveSubwindow ##

	DoUpdate

	return (0)
End

// TODO:
// -- allow other model functions as needed.
//
// Function to plot the specified 2D model for the detector
//
Function V_DetModelPopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum = pa.popNum
			string   popStr = pa.popStr

			Execute "V_PlotBroadPeak_Pix2D()"

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

//
// TODO - make a better guess (how?)
// TODO - make the guess appropriate for the fitted model
//
Function V_DetFitGuessButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			WAVE dispW = root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
			WAVE coefW = root:coef_PeakPix2D

			WaveStats/Q dispW
			coefW[2] = V_max //approx peak height
			coefW[6] = V_avg //approx background
			coefW[0] = 0     // remove the porod scale
			coefW[3] = 0.9   //peak width, first guess

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

Function V_GizmoFitButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			Execute "V_Gizmo_PeakFit()"

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

Function V_MaskBeforeFitButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			Execute "V_NaN_BeforeFit()"

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

// TODO - read from the popup for the panel string
// TODO - read the appropriate coeffients for xy, depending on the model selected
//
Function V_ConvertFitPix2cmButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			string detStr
			variable xPix, yPix
			//			Prompt detStr, "enter the panel string"
			//			Prompt xPix, "enter the x pixel center"
			//			Prompt yPix, "enter the y pixel center"
			//			DoPrompt "enter the values",detStr,xPix,yPix

			ControlInfo popup_0
			detStr = S_Value
			WAVE coefW = root:coef_PeakPix2D

			xPix = coefW[9]
			yPix = coefW[10]

			V_Convert_FittedPix_2_cm(detStr, xPix, yPix)

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

//
// TODO -- currently hard-wired for coefficients from the only fit function
//
// only copies the center values to the local folder (then read back in by clicking  "Ctr Table")
//
// -- will need to recalc mm center AND q-values
Function V_CopyCtrButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			string detStr, fname
			WAVE coefW = root:coef_PeakPix2D

			ControlInfo popup_0
			detStr = S_Value
			ControlInfo popup_2
			fname = S_Value

			V_putDet_beam_center_x(fname, detStr, coefW[9])
			V_putDet_beam_center_y(fname, detStr, coefW[10])

			//			DoAlert 0, "-- will need to recalc mm center AND q-values"

			V_BCtrTable() //reads the values back in

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

// TODO
// -- there is only a single fitting function available, and it's hard-wired
// -- what values are held during the fitting are hard-wired
//
//
// function to call the fit function (2D)
//
Function V_DetFitButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			WAVE dispW = root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
			WAVE coefW = root:coef_PeakPix2D

			FuncFitMD/H="11000101100"/NTHR=0/M=2 V_BroadPeak_Pix2D, coefW, dispW/D

			WAVE ws = W_sigma
			AppendtoTable/W=PanelFit#T0 ws

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

Function V_DetFitHelpButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			DoAlert 0, "Help file not written yet..."

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

Function V_CtrTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			V_BCtrTable()

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

Function V_WriteCtrTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			V_BeamCtr_WriteTable()

			break
		case -1: // control being killed
			break
		default:
			// do nothing - mouse up is all I respond to
			break
	endswitch

	return 0
End

//
// This sets the scale of the data panels to an approximate detector coordinate system with
// zero at the center, only for display purposes. It is not exact, and has nothing to do with
// the calculation of q-values.
//
// (DONE)
// x- some of this is hard-wired in (numPix and nTubes per panel), but this is OK
// x- the x-scale of the T/B panels is artificially compressed to "fake" 4mm per pixel in x-direction
//
Function V_RescaleToBeamCenter(string folderStr, string detStr, variable xCtr, variable yCtr)

	WAVE w = $("root:Packages:NIST:VSANS:" + folderStr + ":entry:instrument:detector_" + detStr + ":data")

	variable nPix   = 128
	variable nTubes = 48

	strswitch(detStr) // string switch
		case "MT": // top panels, fall through by design
		case "FT":
			//			SetScale/I x -xCtr,npix-xCtr,"",w
			SetScale/I x - xCtr / 2, (npix - xCtr) / 2, "", w // fake 4mm by compressing the scale
			SetScale/I y - yCtr, nTubes - yCtr, "", w
			break // exit from switch
		case "MB": // bottom panels, fall through by design
		case "FB":
			//			SetScale/I x -xCtr,npix-xCtr,"",w
			SetScale/I x - xCtr / 2, (npix - xCtr) / 2, "", w
			SetScale/I y - yCtr, nTubes - yCtr, "", w
			break // exit from switch
		case "ML": // left panels, fall through by design
		case "FL":
			SetScale/I x - xCtr, nTubes - xCtr, "", w
			SetScale/I y - yCtr, npix - yCtr, "", w
			break // exit from switch
		case "MR": // Right panels, fall through by design
		case "FR":
			SetScale/I x - xCtr, nTubes - xCtr, "", w
			SetScale/I y - yCtr, npix - yCtr, "", w
			break // exit from switch
		default: // optional default expression executed
			Print "Error in V_RescaleToBeamCenter()"
	endswitch

	return (0)
End

// TODO
// these are "nominal" beam center values in pixels for the default VCALC configuration
// This function "restores" the data display to the "instrument" conditions where the panels overlap
// and is intended to be a TRUE view of what the detectors see - that is - the peaks should appear as rings,
// the view should be symmetric (if the real data is symmetric)
//
// -- this is currently linked to the Vdata panel
// -- will need to remove the hard-wired values and get the proper values from the data
// -- ?? will the "proper" values be in pixels or distance? All depends on how I display the data...
// -- may want to keep the nominal scaling values around in case the proper values aren't in the file
//
//
//
//•print xCtr_pix
//  xCtr_pix[0]= {64,64,55,-8.1,64,64,55,-8.1,63.4}
//•print yCtr_pix
//  yCtr_pix[0]= {-8.7,55,64,64,-8.7,55,64,64,62.7}
//
Function V_RestorePanels()

	string fname  = ""
	string detStr = ""
	variable ii, xCtr, yCtr

	// this works if the proper centers are in the file - otherwise, it's a mess
	// "B" is skipped here, as it should be...

	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	fname = type
	for(ii = 0; ii < ItemsInList(ksDetectorListNoB); ii += 1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		xCtr   = V_getDet_beam_center_x_pix(fname, detStr)
		yCtr   = V_getDet_beam_center_y_pix(fname, detStr)
		V_RescaleToBeamCenter(type, detStr, xCtr, yCtr)
	endfor

	return (0)
End

// these are "spread out" (pixel) values for the data panels
// This view is meant to spread out the panels so there is (?Less) overlap so the panels can be
// viewed a bit easier. Isolation may still be preferred for detailed work.
//
//
Function V_SpreadOutPanels()

	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	V_RescaleToBeamCenter(type, "MB", 64, 78)
	V_RescaleToBeamCenter(type, "MT", 64, -30)
	V_RescaleToBeamCenter(type, "MR", -30, 64)
	V_RescaleToBeamCenter(type, "ML", 78, 64)
	V_RescaleToBeamCenter(type, "FB", 64, 78)
	V_RescaleToBeamCenter(type, "FT", 64, -30)
	V_RescaleToBeamCenter(type, "FR", -30, 64)
	V_RescaleToBeamCenter(type, "FL", 78, 64)
	return (0)
End

// function to display the beam center values for all of the detectors
// opens a separate table with the detector label, and the XY values
// ? Maybe list the XY pair in pixels and in real distance in the table
//
// TODO:
// -- need a way to use this or another table? as input to put the new/fitted/derived
//    beam center values into the data folders, and ultimately into the data files on disk
// -- need read/Write for the XY in pixels, and in real-distance
// -- where are the temporary waves to be located? root?
// -- need way to access the Ctr_mm values
Function V_BCtrTable()

	// order of the panel names will match the constant string
	//FT;FB;FL;FR;MT;MB;ML;MR;B;
	Make/O/T/N=9 panelW
	Make/O/D/N=9 xCtr_pix, yCtr_pix, xCtr_cm, yCtr_cm
	DoWindow/F BCtrTable
	if(V_flag == 0)
		Edit/W=(547, 621, 1076, 943)/N=BCtrTable panelW, xCtr_pix, yCtr_pix, xCtr_cm, yCtr_cm
	endif

	variable ii
	string detStr, fname

	fname = "RAW"
	for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
		detStr     = StringFromList(ii, ksDetectorListAll, ";")
		panelW[ii] = detStr

	endfor

	//		xCtr_pix[ii] = V_getDet_beam_center_x_pix(fname,detStr)
	//		yCtr_pix[ii] = V_getDet_beam_center_y_pix(fname,detStr)
	//		// TODO
	//		// and now the mm values
	//		xCtr_mm[ii] = V_getDet_beam_center_x_mm(fname,detStr)
	//		yCtr_mm[ii] = V_getDet_beam_center_y_mm(fname,detStr)
	return (0)
End

//
// to write the new beam center values to a file on disk:
// V_writeDet_beam_center_x(fname,detStr,val)
//
// to write to a local WORK folder
// V_putDet_beam_center_x(fname,detStr,val)
//
Function V_BeamCtr_WriteTable()

	variable runNumber
	Prompt runNumber, "enter the run number:"
	DoPrompt "Pick file to write to", runNumber
	if(V_flag == 1)
		return (0)
	endif

	string folder

	variable ii
	string detStr, fname

	WAVE   xCtr_pix = root:xCtr_pix
	WAVE   yCtr_pix = root:yCtr_pix
	WAVE/T panelW   = root:PanelW

	fname = V_FindFileFromRunNumber(runNumber)

	for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
		//		detStr = StringFromList(ii, ksDetectorListAll, ";")
		detStr = panelW[ii]
		V_writeDet_beam_center_x(fname, detStr, xCtr_pix[ii])
		V_writeDet_beam_center_y(fname, detStr, yCtr_pix[ii])

		// TODO
		// and now the mm values

	endfor
	return (0)

End

//////////////////
//
// Simple utility to calculate beam centers [cm] based on a single measurement
//  and empirical relations between the panel zero positions
//
// Empirical relations are derived from beam center measurements using 6A data and WB data (9/10/17)
// only measurements on L, R, and x-coordinate of B were used. T panel cannot be translated down far enough
// to reach the direct beam.
//
// Start with the (default) case of a beam center measured on R (MR or FR)
//
// Empirical values are averaged as noted
//

Proc V_DeriveBeamCenters()

	Make/O/T panelWave = {"FL", "FR", "FT", "FB", "ML", "MR", "MT", "MB", "B"}
	Make/O/D/N=9 newXCtr_cm, newYCtr_cm

	Edit panelWave, newXCtr_cm, newYCtr_cm

	DoAlert 0, "enter the measured beam center reference for Front and Middle panels"
	V_fDeriveBeamCenters()

EndMacro

// (DONE):
// as of FEB 2019, Delta values are defined as constants
// and used here and in the centroid caculation in the Marquee operations
//
// ** updated these values with fitted arcs of AgBeh (Dec 2018 data, multiple runs)
//
Proc V_fDeriveBeamCenters(x_FrontReference, y_FrontReference, x_MiddleReference, y_MiddleReference)
	variable x_FrontReference, y_FrontReference, x_MiddleReference, y_MiddleReference

	// start with the front
	// FR
	newXCtr_cm[1] = x_FrontReference
	newYCtr_cm[1] = y_FrontReference
	// FL
	//	newXCtr_cm[0] = x_FrontReference - (0.03 + 0.03)/2		//OLD, pre Dec 2018
	//	newYCtr_cm[0] = y_FrontReference + (0.34 + 0.32)/2
	newXCtr_cm[0] = x_FrontReference + kBCtrDelta_FL_x //NEW Dec 2018
	newYCtr_cm[0] = y_FrontReference + kBCtrDelta_FL_y
	// FB
	//	newXCtr_cm[3] = x_FrontReference - (2.02 + 2.06)/2		// OLD, pre Dec 2018
	//	newYCtr_cm[3] = y_FrontReference - (0.12 + 0.19)/2		// (-) is correct here
	newXCtr_cm[3] = x_FrontReference + kBCtrDelta_FB_x // NEW Dec 2018
	newYCtr_cm[3] = y_FrontReference + kBCtrDelta_FB_y
	// FT
	//	newXCtr_cm[2] = newXCtr_cm[3]				// OLD, pre Dec 2018
	//	newYCtr_cm[2] = newYCtr_cm[3]
	newXCtr_cm[2] = x_FrontReference + kBCtrDelta_FT_x // NEW Dec 2018 (not a duplicate of FB anymore)
	newYCtr_cm[2] = y_FrontReference + kBCtrDelta_FT_y

	// MR
	newXCtr_cm[5] = x_MiddleReference
	newYCtr_cm[5] = y_MiddleReference
	// ML
	//	newXCtr_cm[4] = x_MiddleReference - (0.06 + 0.05)/2
	//	newYCtr_cm[4] = y_MiddleReference + (0.14 + 0.01)/2
	newXCtr_cm[4] = x_MiddleReference + kBCtrDelta_ML_x
	newYCtr_cm[4] = y_MiddleReference + kBCtrDelta_ML_y
	// MB
	//	newXCtr_cm[7] = x_MiddleReference - (0.51 + 0.62)/2
	//	newYCtr_cm[7] = y_MiddleReference + (0.79 + 0.74)/2
	newXCtr_cm[7] = x_MiddleReference + kBCtrDelta_MB_x
	newYCtr_cm[7] = y_MiddleReference + kBCtrDelta_MB_y
	// MT
	newXCtr_cm[6] = x_MiddleReference + kBCtrDelta_MT_x
	newYCtr_cm[6] = y_MiddleReference + kBCtrDelta_MT_y

	// default value for B (approx center) in pixels
	newXCtr_cm[8] = 340
	newYCtr_cm[8] = 828

	return
EndMacro

Window V_Gizmo_PeakFit() : GizmoPlot
	PauseUpdate; Silent 1 // building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(35, 45, 550, 505)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo Surface=root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel, name=surface0
	ModifyGizmo ModifyObject=surface0, objectType=surface, property={srcMode, 0}
	ModifyGizmo ModifyObject=surface0, objectType=surface, property={surfaceCTab, Rainbow}
	AppendToGizmo Axes=boxAxes, name=axes0
	ModifyGizmo ModifyObject=axes0, objectType=Axes, property={-1, axisScalingMode, 1}
	ModifyGizmo ModifyObject=axes0, objectType=Axes, property={-1, axisColor, 0, 0, 0, 1}
	ModifyGizmo ModifyObject=axes0, objectType=Axes, property={0, ticks, 3}
	ModifyGizmo ModifyObject=axes0, objectType=Axes, property={1, ticks, 3}
	ModifyGizmo ModifyObject=axes0, objectType=Axes, property={2, ticks, 3}
	ModifyGizmo modifyObject=axes0, objectType=Axes, property={-1, Clipped, 0}
	AppendToGizmo Surface=root:PeakPix2D_mat, name=surface1
	ModifyGizmo ModifyObject=surface1, objectType=surface, property={srcMode, 0}
	ModifyGizmo ModifyObject=surface1, objectType=surface, property={surfaceCTab, Grays}
	ModifyGizmo setDisplayList=0, object=surface0
	ModifyGizmo setDisplayList=1, object=axes0
	ModifyGizmo setDisplayList=2, object=surface1
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={551, 23, 1368, 322}
	ModifyGizmo endRecMacro
	ModifyGizmo idleEventQuaternion={1.38005e-05, -1.48789e-05, -6.11841e-06, 1}
EndMacro

Proc V_NaN_BeforeFit(x1, x2, y1, y2)
	variable x1, x2, y1, y2

	root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel[x1, x2][y1, y2]=NaN
EndMacro

Function V_Convert_FittedPix_2_cm(string panel, variable xPix, variable yPix)

	Make/O/D/N=128 tmpTube

	string pathStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:detector_"
	variable x_cm, y_cm

	WAVE xW = $(pathStr + panel + ":data_realDistX")
	WAVE yW = $(pathStr + panel + ":data_realDistY")

	strswitch(panel) // string switch
		case "FL": // fall through by design
		case "ML":
			// for Left/Right
			tmpTube = yW[0][p]
			// for left
			x_cm = (xW[47][0] + (xPix - 47) * 8.4) / 10
			y_cm = tmpTube[yPix] / 10

			break
		case "FR": // fall through by design
		case "MR":
			// for Left/Right
			tmpTube = yW[0][p]
			// for right
			x_cm = (xW[0][0] + xPix * 8.4) / 10
			y_cm = tmpTube[yPix] / 10

			break
		case "FT": // fall through by design
		case "MT":
			// for Top/Bottom
			tmpTube = xW[p][0]

			x_cm = tmpTube[xPix] / 10
			y_cm = (yW[0][0] + yPix * 8.4) / 10

			break
		case "FB": // fall through by design
		case "MB":
			// for Top/Bottom
			tmpTube = xW[p][0]

			x_cm = tmpTube[xPix] / 10
			y_cm = (yW[0][47] + (yPix - 47) * 8.4) / 10

			break
		default: // optional default expression executed
			Print "No case matched in V_Convert_FittedPix_2_cm"
			return (1)
	endswitch

	Print "Converted Center = ", x_cm, y_cm
	return (0)
End

Function V_MakeCorrelationMatrix()

	WAVE M_Covar = M_Covar
	Duplicate M_Covar, CorMat // You can use any name instead of CorMat
	CorMat = M_Covar[p][q] / sqrt(M_Covar[p][p] * M_Covar[q][q])
	Edit/K=0 root:CorMat

	return (0)
End

Function V_AutoBeamCenter()

	NVAR gIgnoreBack = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	V_PickOpenForBeamCenter("F")
	V_PickOpenForBeamCenter("M")

	if(!gIgnoreBack)
		V_PickOpenForBeamCenter("B")
	endif

End

//////////////////////
// different way to get the corrected beam centers
//
// find the centroid for each file with the marquee as usual
// then run the macro (to pick each open beam file name)
// - values for centroid are read from the file
//
// - patch xy panel is filled in
//
////
//		Call multiple times, one time for each panel in use.
//	carrStr = "F" | "M" | "B"
//
//
Function V_PickOpenForBeamCenter(string carrStr)

	string emptyFileName_F = ""
	string emptyFileName_M = ""
	string emptyFileName_B = ""
	string folder          = ""

	NVAR gIgnoreBack = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	variable isF = 0
	variable isM = 0
	variable isB = 0
	variable err = 0

	if(cmpstr(carrStr, "F") == 0)
		isF = 1
	endif
	if(cmpStr(carrStr, "M") == 0)
		isM = 1
	endif
	if(cmpStr(carrStr, "B") == 0)
		isB = 1
	endif
	if((isF + isM + isB) == 0) //if nothing set
		return (0)
	endif

	// TODO -- can I auto-identify which is the F, M, B?
	// -- can I determine whether the reference beam center has been found already?
	// -- since the centroid was already picked, can the file be flagged at this time?
	// -- is it easier to have a single panel with three popups? or just two??
	//

	//
	// - to figure out which is F, M, B
	// try WaveMax(root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MR:data)
	// and pick the panel with the largest value
	//
	// or display the file label along with the file name
	//
	//

	// get the file names
	if(isF)
		Prompt emptyFileName_F, "Empty Beam File, Front Carriage", popup, V_PickEMPBeamButton("")
		DoPrompt "Select File", emptyFileName_F
		if(V_Flag)
			return 0 // user canceled
		endif
	endif

	if(isM)
		Prompt emptyFileName_M, "Empty Beam File, Middle Carriage", popup, V_PickEMPBeamButton("")
		DoPrompt "Select File", emptyFileName_M
		if(V_Flag)
			return 0 // user canceled
		endif
	endif

	if(isB)
		if(!gIgnoreBack)
			Prompt emptyFileName_B, "Empty Beam File, Back Carriage", popup, V_PickEMPBeamButton("")
			DoPrompt "Select File", emptyFileName_B
			if(V_Flag)
				return 0 // user canceled
			endif
		endif
	endif

	// read the values from the Reduction/comment block
	// "XREF=%g;YREF=%g;PANEL=%s;"
	string refStr = ""
	variable xRef_F, xRef_M, xRef_B
	variable yRef_F, yRef_M, yRef_B

	//force a cleanup of these three data sets so they are read from disk
	if(isF)
		KillDataFolder/Z $("root:Packages:NIST:VSANS:RawVSANS:" + ParseFilePath(0, emptyFileName_F, ".", 0, 0))
	endif
	if(isM)
		KillDataFolder/Z $("root:Packages:NIST:VSANS:RawVSANS:" + ParseFilePath(0, emptyFileName_M, ".", 0, 0))
	endif
	if(isB)
		if(strlen(emptyFileName_B) > 0) //to avoid killing RawVSANS!!
			KillDataFolder/Z $("root:Packages:NIST:VSANS:RawVSANS:" + ParseFilePath(0, emptyFileName_B, ".", 0, 0))
		endif
	endif

	//
	// check for the reference values stored in the Reduction block
	// if they aren't there, warn the user, open the raw data file, and exit now
	//
	//

	if(isF)
		refStr = V_getReductionComments(emptyFileName_F)
		xRef_F = NumberByKey("XREF", refStr, "=", ";")
		yRef_F = NumberByKey("YREF", refStr, "=", ";")

		if(numtype(xRef_F) != 0 || numtype(yRef_F) != 0) //not a normal number
			DoAlert 0, "Centroid has not been set for the Front carriage. Use the Marquee to find the centroid and re-set the file."

			err = V_LoadHDF5Data(emptyFileName_F, "RAW")
			if(!err) //directly from, and the same steps as DisplayMainButtonProc(ctrlName)
				SVAR hdfDF = root:file_name // last file loaded, may not be the safest way to pass
				folder = StringFromList(0, hdfDF, ".")

				// this (in SANS) just passes directly to fRawWindowHook()
				V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

				// set the global to display ONLY if the load was called from here, not from the
				// other routines that load data (to read in values)
				SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
				gLast = hdfDF

			endif

			return (0) //exit

		endif
	endif

	if(isM)
		refStr = V_getReductionComments(emptyFileName_M)
		xRef_M = NumberByKey("XREF", refStr, "=", ";")
		yRef_M = NumberByKey("YREF", refStr, "=", ";")

		if(numtype(xRef_M) != 0 || numtype(yRef_M) != 0) //not a normal number
			DoAlert 0, "Centroid has not been set for the Middle carriage. Use the Marquee to find the centroid and re-set the file."

			err = V_LoadHDF5Data(emptyFileName_M, "RAW")
			if(!err) //directly from, and the same steps as DisplayMainButtonProc(ctrlName)
				SVAR hdfDF = root:file_name // last file loaded, may not be the safest way to pass
				folder = StringFromList(0, hdfDF, ".")

				// this (in SANS) just passes directly to fRawWindowHook()
				V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

				// set the global to display ONLY if the load was called from here, not from the
				// other routines that load data (to read in values)
				SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
				gLast = hdfDF

			endif

			return (0) //exit

		endif
	endif
	//
	//	either read the values or set default values
	if(isB)
		if(!gIgnoreBack)
			refStr = V_getReductionComments(emptyFileName_B)
			xRef_B = NumberByKey("XREF", refStr, "=", ";")
			yRef_B = NumberByKey("YREF", refStr, "=", ";")

			if(numtype(xRef_B) != 0 || numtype(yRef_B) != 0) //not a normal number
				DoAlert 0, "Centroid has not been set for the Back carriage. Use the Marquee to find the centroid and re-set the file."

				err = V_LoadHDF5Data(emptyFileName_B, "RAW")
				if(!err) //directly from, and the same steps as DisplayMainButtonProc(ctrlName)
					SVAR hdfDF = root:file_name // last file loaded, may not be the safest way to pass
					folder = StringFromList(0, hdfDF, ".")

					// this (in SANS) just passes directly to fRawWindowHook()
					V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

					// set the global to display ONLY if the load was called from here, not from the
					// other routines that load data (to read in values)
					SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
					gLast = hdfDF

				endif

				return (0) //exit

			endif
		else
			//default values
			xref_B = 340
			yRef_B = 828
		endif
	endif

	Print xRef_F, xRef_M, xRef_B
	Print yRef_F, yRef_M, yRef_B

	///////////////////////////////////////////

	// pass these values to the procedure
	// but what if some of the values are bad?
	// these are both procedures, not functions...
	//	V_DeriveBeamCenters()

	// the waves for the panel will already exist, but I can make these temp waves
	Make/O/T newPanelWave = {"FL", "FR", "FT", "FB", "ML", "MR", "MT", "MB", "B"}
	Make/O/D/N=9 newXCtr_cm, newYCtr_cm

	WAVE/T newPanelWave
	WAVE newXCtr_cm, newYCtr_cm

	//	Edit newPanelWave,newXCtr_cm,newYCtr_cm

	//	V_fDeriveBeamCenters(x_FrontReference,y_FrontReference,x_MiddleReference,y_MiddleReference)

	if(isF)
		// start with the front
		// FR
		newXCtr_cm[1] = xRef_F
		newYCtr_cm[1] = yRef_F
		// FL
		newXCtr_cm[0] = xRef_F + kBCtrDelta_FL_x //NEW Dec 2018
		newYCtr_cm[0] = yRef_F + kBCtrDelta_FL_y
		// FB
		newXCtr_cm[3] = xRef_F + kBCtrDelta_FB_x // NEW Dec 2018
		newYCtr_cm[3] = yRef_F + kBCtrDelta_FB_y
		// FT
		newXCtr_cm[2] = xRef_F + kBCtrDelta_FT_x // NEW Dec 2018 (not a duplicate of FB anymore)
		newYCtr_cm[2] = yRef_F + kBCtrDelta_FT_y
	endif

	if(isM)
		// MR
		newXCtr_cm[5] = xRef_M
		newYCtr_cm[5] = yRef_M
		// ML
		newXCtr_cm[4] = xRef_M + kBCtrDelta_ML_x
		newYCtr_cm[4] = yRef_M + kBCtrDelta_ML_y
		// MB
		newXCtr_cm[7] = xRef_M + kBCtrDelta_MB_x
		newYCtr_cm[7] = yRef_M + kBCtrDelta_MB_y
		// MT
		newXCtr_cm[6] = xRef_M + kBCtrDelta_MT_x
		newYCtr_cm[6] = yRef_M + kBCtrDelta_MT_y
	endif

	if(isB)
		// default value for B (approx center) in pixels
		newXCtr_cm[8] = xref_B
		newYCtr_cm[8] = yref_B
	endif

	// XY patch panel values are located at:
	//	SetVariable setvar0,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo
	//	SetVariable setvar1,value= root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi

	//	SetDataFolder root:Packages:NIST:VSANS:Globals:Patch
	// display the wave
	//	Edit/W=(180,40,500,370)/HOST=#  panelW,xCtr_cm,yCtr_cm

	// and the panel   Proc V_Patch_xyCtr_Panel() : Panel

	// TODO -- figure out why I'm doing this ?? set the globals
	//	Variable lo,hi
	//	V_Find_LoHi_RunNum(lo,hi)
	//
	//	NVAR gLo = root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo_xy
	//	NVAR gHi = root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi_xy
	//	gLo = lo
	//	gHi = hi

	// these waves will exist since the panel is up
	//	wave/T panelW = root:Packages:NIST:VSANS:Globals:Patch:panelW
	//	Make/O/D/N=9 root:Packages:NIST:VSANS:Globals:Patch:xCtr_cm
	//	Make/O/D/N=9 root:Packages:NIST:VSANS:Globals:Patch:yCtr_cm

	WAVE xCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:xCtr_cm
	WAVE yCtr_cm = root:Packages:NIST:VSANS:Globals:Patch:yCtr_cm

	//	panelW = newPanelW
	if(isF)
		xCtr_cm[0, 3] = newXCtr_cm[p]
		yCtr_cm[0, 3] = newYCtr_cm[p]
	endif
	if(isM)
		xCtr_cm[4, 7] = newXCtr_cm[p]
		yCtr_cm[4, 7] = newYCtr_cm[p]
	endif
	if(isB)
		xCtr_cm[8] = newXCtr_cm[8]
		yCtr_cm[8] = newYCtr_cm[8]
	endif

	// open the panel
	//	Execute "V_PatchDet_xyCenters_Panel()"

	//	DoAlert 0,"These are the new beam centers. Nothing has been written to files. You need to check the file numbers and click Write."

	return (0)
End

