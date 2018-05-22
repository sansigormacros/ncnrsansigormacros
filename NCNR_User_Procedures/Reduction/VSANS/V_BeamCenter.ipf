#pragma rtGlobals=3		// Use modern global access method and strict wave access.


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


Function V_FindBeamCenter()
	DoWindow/F PanelFit
	if(V_flag==0)
	
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:BeamCenter

		Execute "V_DetectorPanelFit()"
	endif
End
//
// TODO - may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
Proc V_DetectorPanelFit() : Panel
	PauseUpdate; Silent 1		// building window...

// plot the default model to be sure some data is present
	if(exists("xwave_PeakPix2D") == 0)
		V_PlotBroadPeak_Pix2D()
	endif

	NewPanel /W=(662,418,1586,960)/N=PanelFit/K=1
//	ShowTools/A
	
	PopupMenu popup_0,pos={20,50},size={109,20},proc=V_SetDetPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;B;\""
	PopupMenu popup_1,pos={200,20},size={157,20},proc=V_DetModelPopMenuProc,title="Model Function"
	PopupMenu popup_1,mode=1,popvalue="BroadPeak",value= #"\"BroadPeak;other;\""
	PopupMenu popup_2,pos={20,20},size={109,20},title="Data Source"//,proc=SetFldrPopMenuProc
	PopupMenu popup_2,mode=1,popvalue="RAW",value= #"\"RAW;SAM;VCALC;\""
		
	Button button_0,pos={486,20},size={80,20},proc=V_DetFitGuessButtonProc,title="Guess"
	Button button_1,pos={615,20},size={80,20},proc=V_DetFitButtonProc,title="Do Fit"
	Button button_2,pos={744,20},size={80,20},proc=V_DetFitHelpButtonProc,title="Help"
	Button button_3,pos={730,400},size={110,20},proc=V_CopyCtrButtonProc,title="Copy Centers"
	Button button_4,pos={615,400},size={110,20},proc=V_CtrTableButtonProc,title="Ctr table"
	Button button_5,pos={730,440},size={110,20},proc=V_WriteCtrTableButtonProc,title="Write table"


	SetDataFolder root:Packages:NIST:VSANS:Globals:BeamCenter

	duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel

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
	RenameWindow #,T0
	SetActiveSubwindow ##

	
EndMacro


//
// function to choose which detector panel to display, and then to actually display it
//
Function V_SetDetPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
						
			// remove the old image (it may not be the right shape)
			// -- but make sure it exists first...
			String childList = ChildWindowList("PanelFit")
			Variable flag
			
			flag = WhichListItem("DetData", ChildList)		//returns -1 if not in list, 0+ otherwise
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
Function V_DrawDetPanel(str)
	String str
	
	// from the selection, find the path to the data


	Variable xDim,yDim
	Variable left,top,right,bottom
	Variable height, width
	Variable left2,top2,right2,bottom2
	Variable nPix_X,nPix_Y,pixSize_X,pixSize_Y


	Wave dispW=root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
	Wave cw = root:coef_PeakPix2D

	Wave xwave_PeakPix2D=root:xwave_PeakPix2D
	Wave ywave_PeakPix2D=root:ywave_PeakPix2D
	Wave zwave_PeakPix2D=root:zwave_PeakPix2D

	//plot it in the subwindow with the proper aspect and positioning
	// for 48x256 (8mm x 4mm), aspect = (256/2)/48 = 2.67 (LR panels)
	// for 128x48 (4mm x 8 mm), aspect = 48/(128/2) = 0.75 (TB panels)
	
	
	// using two switches -- one to set the panel-specific dimensions
	// and the other to set the "common" values, some of which are based on the panel dimensions

// set the source of the data. not always VCALC anymore
	String folder
	ControlInfo popup_2
	folder = S_Value

// error checking -- if the VCALC folder is the target & does not exist, exit now
	if( cmpstr(folder,"VCALC") == 0 && DataFolderExists("root:Packages:NIST:VSANS:VCALC") == 0)
		return(0)
	endif

// error checking -- if the RAW folder is the target & does not exist, exit now
	if( cmpstr(folder,"RAW") == 0 && DataFolderExists("root:Packages:NIST:VSANS:RAW:entry") == 0)
		return(0)
	endif

// error checking -- if the SAM folder is the target & does not exist, exit now
	if( cmpstr(folder,"SAM") == 0 && DataFolderExists("root:Packages:NIST:VSANS:SAM:entry") == 0)
		return(0)
	endif
		
	// TODO -- fix all of this mess
	if(cmpstr(folder,"VCALC") == 0)
		// panel-specific values
		Variable VC_nPix_X = VCALC_get_nPix_X(str)
		Variable VC_nPix_Y = VCALC_get_nPix_Y(str)
		Variable VC_pixSize_X = VCALC_getPixSizeX(str)
		Variable VC_pixSize_Y = VCALC_getPixSizeY(str)
//		strswitch(str)
//			case "FL":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gFront_L_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gFront_L_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gFront_L_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gFront_L_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+str+":det_"+str)
//				break
//			case "FR":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gFront_R_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gFront_R_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gFront_R_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gFront_R_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Front:det_"+str)
//				break
//			case "ML":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gMiddle_L_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_L_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gMiddle_L_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_L_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Middle:det_"+str)
//				break
//			case "MR":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gMiddle_R_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_R_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gMiddle_R_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_R_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Middle:det_"+str)
//				break	
//	
//			case "FT":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gFront_T_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gFront_T_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gFront_T_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gFront_T_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Front:det_"+str)
//				break
//			case "FB":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gFront_B_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gFront_B_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gFront_B_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gFront_B_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Front:det_"+str)
//				break
//			case "MT":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gMiddle_T_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_T_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gMiddle_T_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_T_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Middle:det_"+str)
//				break
//			case "MB":
//				NVAR VC_nPix_X = root:Packages:NIST:VSANS:VCALC:gMiddle_B_nPix_X
//				NVAR VC_nPix_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_B_nPix_Y
//				NVAR VC_pixSize_X = root:Packages:NIST:VSANS:VCALC:gMiddle_B_pixelX
//				NVAR VC_pixSize_Y = root:Packages:NIST:VSANS:VCALC:gMiddle_B_pixelY
//	//			wave newW = $("root:Packages:NIST:VSANS:VCALC:Middle:det_"+str)
//				break	
//				
//			case "B":
//				return(0)		//just exit
//				break						
//			default:
//				return(0)		//just exit
//		endswitch
	
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
	

	Variable scale = 5
	
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

	// set from the detector-specific strswitch
	cw[7] = pixSize_X*10
	cw[8] = pixSize_Y*10		

	SetDataFolder root:Packages:NIST:VSANS:Globals:BeamCenter
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
	
	SetDataFolder root:
	
	
		
	// re-dimension the model calculation to be the proper dimensions	
	Redimension/N=(nPix_X*nPix_Y) xwave_PeakPix2D, ywave_PeakPix2D,zwave_PeakPix2D	
	V_FillPixTriplet(xwave_PeakPix2D, ywave_PeakPix2D,zwave_PeakPix2D,nPix_X,nPix_Y)
	Make/O/D/N=(nPix_X,nPix_Y) PeakPix2D_mat		// use the point scaling of the matrix (=pixels)

	Duplicate/O $"PeakPix2D_mat",$"PeakPix2D_lin" 		//keep a linear-scaled version of the data

	//draw the model calculation
	Display/W=(left2,top2,right2,bottom2)/HOST=#
	AppendImage PeakPix2D_mat
	ModifyImage PeakPix2D_mat ctab= {*,*,ColdWarm,0}
	Label left "Y pixels"
	Label bottom "X pixels"	
	RenameWindow #,ModelData
	SetActiveSubwindow ##	
		
	DoUpdate
	
	return(0)
End




// TODO: 
// -- allow other model functions as needed.
//
// Function to plot the specified 2D model for the detector
//
Function V_DetModelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			Execute "V_PlotBroadPeak_Pix2D()"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// TODO - make a better guess (how?)
//
Function V_DetFitGuessButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Wave dispW=root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
			Wave coefW=root:coef_PeakPix2D
			
			WaveStats/Q dispW
			coefW[2] = V_max
			coefW[0] = 1			
			
			break
		case -1: // control being killed
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
Function V_CopyCtrButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String detStr,fname
			Wave coefW=root:coef_PeakPix2D
			
			ControlInfo popup_0
			detStr = S_Value
			ControlInfo popup_2
			fname = S_Value
			
			V_putDet_beam_center_x(fname,detStr,coefW[9])
			V_putDet_beam_center_y(fname,detStr,coefW[10])

//			DoAlert 0, "-- will need to recalc mm center AND q-values"
			
			V_BCtrTable()		//reads the values back in
			
			break
		case -1: // control being killed
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
Function V_DetFitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Wave dispW=root:Packages:NIST:VSANS:Globals:BeamCenter:curDispPanel
			Wave coefW=root:coef_PeakPix2D
			
			FuncFitMD/H="11000111100"/NTHR=0 V_BroadPeak_Pix2D coefW  dispW /D			
			
			Wave ws=W_sigma
			AppendtoTable/W=PanelFit#T0 ws
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DetFitHelpButtonProc(ba) : ButtonControl
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

Function V_CtrTableButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_BCtrTable()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_WriteCtrTableButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_BeamCtr_WriteTable()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// This sets the scale of the data panels to an approximate detector coordinate system with 
// zero at the center, only for display purposes. It is not exact, and has nothing to do with
// the calculation of q-values.
//
//
// TODO
// -- some of this is hard-wired in
// -- this is still all in terms of pixels, which still may not be what I want
// -- the x-scale of the T/B panels is artificially compressed to "fake" 4mm per pixel in x-direction
//
Function V_RescaleToBeamCenter(folderStr,detStr,xCtr,yCtr)
	String folderStr,detStr
	Variable xCtr,yCtr
	
	Wave w = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":data")
	
	Variable nPix = 128
	Variable nTubes = 48
	
	strswitch(detStr)	// string switch
		case "MT":		// top panels
		case "FT":
//			SetScale/I x -xCtr,npix-xCtr,"",w
			SetScale/I x -xCtr/2,(npix-xCtr)/2,"",w		// fake 4mm by compressing the scale
			SetScale/I y -yCtr,nTubes-yCtr,"",w
			break						// exit from switch
		case "MB":		// bottom panels
		case "FB":
//			SetScale/I x -xCtr,npix-xCtr,"",w
			SetScale/I x -xCtr/2,(npix-xCtr)/2,"",w
			SetScale/I y -yCtr,nTubes-yCtr,"",w
			break						// exit from switch
		case "ML":		// left panels
		case "FL":
			SetScale/I x -xCtr,nTubes-xCtr,"",w
			SetScale/I y -yCtr,npix-yCtr,"",w
			break						// exit from switch
		case "MR":		// Right panels
		case "FR":
			SetScale/I x -xCtr,nTubes-xCtr,"",w
			SetScale/I y -yCtr,npix-yCtr,"",w
			break						// exit from switch
					
		default:							// optional default expression executed
			Print "Error in V_RescaleToBeamCenter()"
	endswitch
	
	return(0)
end

// This sets the scale of the data panels to an approximate detector coordinate system with 
// zero at the center, only for display purposes. It is not exact, and has nothing to do with
// the calculation of q-values.
//
// ****For the panel display, the scaling MUST be in PIXELS for the readout and calculations to be correct.
// the read out needs pixels, and the calculations use the pixels as the indexes for the real-space (mm) values
//
//  Since I'll only know the beam center in mm, and I'll need the relative panel positions to convert to pixels,
// can I display the panels in their pixel locations relative to each other, based on a zero center and 
// the panel offset values?
//
//
// TODO
// -- some of this is hard-wired in
// -- this is still all in terms of pixels, which still may not be what I want
// -- the x-scale of the T/B panels is artificially compressed to "fake" 4mm per pixel in x-direction
//
// Nominal center is 0,0
//
Function V_RescaleToNominalCenter(folderStr,detStr,xCtr,yCtr)
	String folderStr,detStr
	Variable xCtr,yCtr
	
//	xCtr = 0
//	yCtr = 0
	
	Wave w = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+detStr+":data")
	
	Variable nPix = 128
	Variable nTubes = 48
	Variable offset = 0
	Variable pixSizeX,pixSizeY
	
	strswitch(detStr)	// string switch
		case "MT":		// top panels
		case "FT":
//			SetScale/I x -xCtr,npix-xCtr,"",w
			offset = V_getDet_VerticalOffset(folderStr,detStr)		//in cm
			pixSizeY = 0.84
			yCtr = -(offset/pixSizeY) 
			
			SetScale/I x -xCtr/2,(npix-xCtr)/2,"",w		// fake 4mm by compressing the scale
			SetScale/I y -yCtr,nTubes-yCtr,"",w
			break						// exit from switch
		case "MB":		// bottom panels
		case "FB":
//			SetScale/I x -xCtr,npix-xCtr,"",w

			offset = V_getDet_VerticalOffset(folderStr,detStr)		//in cm
			pixSizeY = 0.84
			yCtr = nTubes-(offset/pixSizeY) 
			
			SetScale/I x -xCtr/2,(npix-xCtr)/2,"",w
			SetScale/I y -yCtr,nTubes-yCtr,"",w
			break						// exit from switch
			
		case "ML":		// left panels
		case "FL":
			offset = V_getDet_LateralOffset(folderStr,detStr)		//in cm
			pixSizeX = 0.84
			xCtr = nTubes-(offset/pixSizeX)
			
			SetScale/I x -xCtr,nTubes-xCtr,"",w
			SetScale/I y -yCtr,npix-yCtr,"",w
			break						// exit from switch
		case "MR":		// Right panels
		case "FR":
			offset = V_getDet_LateralOffset(folderStr,detStr)		//in cm
			pixSizeX = 0.84
			xCtr = -(offset/pixSizeX)
		
			SetScale/I x -xCtr,nTubes-xCtr,"",w
			SetScale/I y -yCtr,npix-yCtr,"",w
			break						// exit from switch
					
		default:							// optional default expression executed
			Print "Error in V_RescaleToBeamCenter()"
	endswitch
	
	return(0)
end


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

	String fname=""
	String detStr=""
	Variable ii,xCtr,yCtr

// this works if the proper centers are in the file - otherwise, it's a mess	
// "B" is skipped here, as it should be...

// TODO --?? is this a problem??
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	fname = type
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		xCtr = V_getDet_beam_center_x_pix(fname,detStr)
		yCtr = V_getDet_beam_center_y_pix(fname,detStr)
//		V_RescaleToBeamCenter(type,detStr,xCtr,yCtr)
		V_RescaleToNominalCenter(type,detStr,xCtr,yCtr)		// xCtr or yCtr value in direction of offset are dummy values here
	endfor
		

	return(0)
end

// TODO
// these are "spread out" values for the data panels
// This view is meant to spread out the panels so there is (?Less) overlap so the panels can be 
// viewed a bit easier. Isolation may still be preferred for detailed work.
//
// -- this is currently linked to the Vdata panel
// -- will need to remove the hard-wired values and get the proper values from the data
// -- ?? will the "proper" values be in pixels or distance? All depends on how I display the data...
//
Function V_SpreadOutPanels()

// TODO ?? is this a problem??
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	V_RescaleToBeamCenter(type,"MB",64,78)
	V_RescaleToBeamCenter(type,"MT",64,-30)
	V_RescaleToBeamCenter(type,"MR",-30,64)
	V_RescaleToBeamCenter(type,"ML",78,64)
	V_RescaleToBeamCenter(type,"FB",64,78)
	V_RescaleToBeamCenter(type,"FT",64,-30)
	V_RescaleToBeamCenter(type,"FR",-30,64)
	V_RescaleToBeamCenter(type,"FL",78,64)
	return(0)
end

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
	Make/O/D/N=9 xCtr_pix,yCtr_pix,xCtr_mm,yCtr_mm
	DoWindow/F BCtrTable
	if(V_flag == 0)
		Edit/W=(547,621,1076,943)/N=BCtrTable panelW,xCtr_pix,yCtr_pix,xCtr_mm,yCtr_mm
	endif
	
	Variable ii
	String detStr,fname
	
	fname = "RAW"
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		panelW[ii] = detStr
		xCtr_pix[ii] = V_getDet_beam_center_x_pix(fname,detStr)
		yCtr_pix[ii] = V_getDet_beam_center_y_pix(fname,detStr)
		// TODO
		// and now the mm values
		xCtr_mm[ii] = V_getDet_beam_center_x_mm(fname,detStr)
		yCtr_mm[ii] = V_getDet_beam_center_y_mm(fname,detStr)
		
	endfor
	return(0)
End

//
// to write the new beam center values to a file on disk:
// V_writeDet_beam_center_x(fname,detStr,val)
//
// to write to a local WORK folder
// V_putDet_beam_center_x(fname,detStr,val)
//
Function V_BeamCtr_WriteTable()

	Variable runNumber
	Prompt runNumber, "enter the run number:"
	DoPrompt "Pick file to write to",runNumber
	If(V_flag==1)
		return(0)
	endif	
	
	String folder
	
	Variable ii
	String detStr,fname
	
	Wave xCtr_pix = root:xCtr_pix
	Wave yCtr_pix = root:yCtr_pix
	Wave/T panelW = root:PanelW
	

	fname = V_FindFileFromRunNumber(runNumber)

	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
//		detStr = StringFromList(ii, ksDetectorListAll, ";")
		detStr = panelW[ii]
		V_writeDet_beam_center_x(fname,detStr,xCtr_pix[ii])
		V_writeDet_beam_center_y(fname,detStr,yCtr_pix[ii])
		
		// TODO
		// and now the mm values
		
	endfor
	return(0)
	
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

	Make/O/T panelWave = {"FL","FR","FT","FB","ML","MR","MT","MB","B"}
	Make/O/D/N=9 newXCtr_cm,newYCtr_cm
	
	Edit panelWave,newXCtr_cm,newYCtr_cm
	
	DoAlert 0, "enter the measured beam center reference for Front and Middle panels"
	V_fDeriveBeamCenters()
	
End


Proc V_fDeriveBeamCenters(xFR,yFR,xMR,yMR)
	Variable xFR,yFR,xMR,yMR
	
	// start with the front
	// FR
	newXCtr_cm[1] = xFR
	newYCtr_cm[1] = yFR
	// FL
	newXCtr_cm[0] = xFR - (0.03 + 0.03)/2
	newYCtr_cm[0] = yFR + (0.34 + 0.32)/2
	// FB
	newXCtr_cm[3] = xFR - (2.02 + 2.06)/2
	newYCtr_cm[3] = yFR - (0.12 + 0.19)/2		// (-) is correct here
	// FT (duplicate FB)
	newXCtr_cm[2] = newXCtr_cm[3]
	newYCtr_cm[2] = newYCtr_cm[3]
	
	// MR
	newXCtr_cm[5] = xMR
	newYCtr_cm[5] = yMR
	// ML
	newXCtr_cm[4] = xMR - (0.06 + 0.05)/2
	newYCtr_cm[4] = yMR + (0.14 + 0.01)/2
	// MB
	newXCtr_cm[7] = xMR - (0.51 + 0.62)/2
	newYCtr_cm[7] = yMR + (0.79 + 0.74)/2
	// MT (duplicate MB)
	newXCtr_cm[6] = newXCtr_cm[7]
	newYCtr_cm[6] = newYCtr_cm[7]	
	
	
	// default value for B
	newXCtr_cm[8] = 0
	newYCtr_cm[8] = 0

		
	return
End

