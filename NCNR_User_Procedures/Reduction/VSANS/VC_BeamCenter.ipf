#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// TODO
// -- adjust the guesses to some better starting conditions
// -- multiple fit options with different things held
// x- when selecting the detector, set the x/y pixel sizes
// x- figure out how to re-plot the images when swapping between LR and TB panels
//


//
// TODO - may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
Window DetectorPanelFit() : Panel
	PauseUpdate; Silent 1		// building window...

// plot the default model to be sure some data is present
	if(exists("xwave_PeakPix2D") == 0)
		PlotBroadPeak_Pix2D()
	endif

	NewPanel /W=(662,418,1586,1108)/N=PanelFit/K=1
//	ShowTools/A
		
	PopupMenu popup_0,pos={20,20},size={109,20},proc=SetDetPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;MR;ML;MT;MB;B;\""
	PopupMenu popup_1,pos={200,20},size={157,20},proc=DetModelPopMenuProc,title="Model Function"
	PopupMenu popup_1,mode=1,popvalue="BroadPeak",value= #"\"BroadPeak;other;\""
	
	Button button_0,pos={486,20},size={80,20},proc=DetFitGuessButtonProc,title="Guess"
	Button button_1,pos={615,20},size={80,20},proc=DetFitButtonProc,title="Do Fit"
	Button button_2,pos={744,20},size={80,20},proc=DetFitHelpButtonProc,title="Help"


	duplicate/O root:Packages:NIST:VSANS:VCALC:Front:det_FL curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel
	
//draw the detector panel
	Display/W=(20,80,180,600)/HOST=# 
	AppendImage curDispPanel
	ModifyImage curDispPanel ctab= {*,*,ColdWarm,0}
//	ModifyGraph width={Plan,1,bottom,left}
	Label left "Y pixels"
	Label bottom "X pixels"	
	RenameWindow #,DetData
	SetActiveSubwindow ##	
	
//draw the model calculation
	Display/W=(200,80,360,600)/HOST=#
	AppendImage PeakPix2D_mat
	ModifyImage PeakPix2D_mat ctab= {*,*,ColdWarm,0}
//	ModifyGraph width={Plan,1,bottom,left}
	Label left "Y pixels"
	Label bottom "X pixels"	
	RenameWindow #,ModelData
	SetActiveSubwindow ##		

// edit the fit coefficients	
	Edit/W=(500,80,880,350)/HOST=#  parameters_PeakPix2D,coef_PeakPix2D
	ModifyTable width(Point)=0
	ModifyTable width(parameters_PeakPix2D)=120
	ModifyTable width(coef_PeakPix2D)=100
	RenameWindow #,T0
	SetActiveSubwindow ##


	
EndMacro




Function SetDetPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			DrawDetPanel(popStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//	duplicate/O root:Packages:NIST:VSANS:VCALC:Front:det_FL curDispPanel
//	SetScale/P x 0,1, curDispPanel
//	SetScale/P y 0,1, curDispPanel
	
// draws a single panel from the set of detectors
Function DrawDetPanel(str)
	String str
	
	// from the selection, find the path to the data
	// TODO - currently is hard-wired for the simulation path!
	//     need to make it more generic, especially for RAW data

	Variable xDim,yDim
	Wave dispW=root:curDispPanel
	Wave cw = root:coef_PeakPix2D

	cw[7] = 4
	cw[8] = 8
	
	Wave xwave_PeakPix2D=root:xwave_PeakPix2D
	Wave ywave_PeakPix2D=root:ywave_PeakPix2D
	Wave zwave_PeakPix2D=root:zwave_PeakPix2D

	//plot it in the subwindow with the proper aspect and positioning	
	strswitch(str)
		case "FL":
			xDim=48
			yDim=256
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,180,600)
			MoveSubWindow/W=PanelFit#ModelData fnum=(200,80,360,600)			
			cw[7] = 8
			cw[8] = 4
			wave newW = root:Packages:NIST:VSANS:VCALC:Front:det_FL
			break
		case "FR":
			xDim=48
			yDim=256
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,180,600)
			MoveSubWindow/W=PanelFit#ModelData fnum=(200,80,360,600)	
			cw[7] = 8
			cw[8] = 4						
			wave newW = root:Packages:NIST:VSANS:VCALC:Front:det_FR
			break
		case "FT":
			xDim=128
			yDim=48
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,464,235)
			MoveSubWindow/W=PanelFit#ModelData fnum=(20,280,464,435)
			cw[7] = 4
			cw[8] = 8			
			wave newW = root:Packages:NIST:VSANS:VCALC:Front:det_FT
			break
		case "FB":
			xDim=128
			yDim=48
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,464,235)
			MoveSubWindow/W=PanelFit#ModelData fnum=(20,280,464,435)
			cw[7] = 4
			cw[8] = 8			
			wave newW = root:Packages:NIST:VSANS:VCALC:Front:det_FB
			break
		case "ML":
			xDim=48
			yDim=256
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,180,600)
			MoveSubWindow/W=PanelFit#ModelData fnum=(200,80,360,600)	
			cw[7] = 8
			cw[8] = 4						
			wave newW = root:Packages:NIST:VSANS:VCALC:Middle:det_ML
			break
		case "MR":
			xDim=48
			yDim=256
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,180,600)
			MoveSubWindow/W=PanelFit#ModelData fnum=(200,80,360,600)	
			cw[7] = 8
			cw[8] = 4						
			wave newW = root:Packages:NIST:VSANS:VCALC:Middle:det_MR
			break
		case "MT":
			xDim=128
			yDim=48
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,464,235)
			MoveSubWindow/W=PanelFit#ModelData fnum=(20,280,464,435)
			cw[7] = 4
			cw[8] = 8			
			wave newW = root:Packages:NIST:VSANS:VCALC:Middle:det_MT
			break
		case "MB":
			xDim=128
			yDim=48
			MoveSubWindow/W=PanelFit#DetData fnum=(20,80,464,235)
			MoveSubWindow/W=PanelFit#ModelData fnum=(20,280,464,435)
			cw[7] = 4
			cw[8] = 8			
			wave newW = root:Packages:NIST:VSANS:VCALC:Middle:det_MB
			break
		case "B":
		
			return(0)		//just exit
			break						
		default:
			return(0)		//just exit
	endswitch

// set the simulated detector data to be point-scaling for display and fitting, not q-scaling	
	duplicate/O newW dispW
	SetScale/P x 0,1, dispW
	SetScale/P y 0,1, dispW	
		

	// re-dimension the model calculation to be the proper dimensions	
	Redimension/N=(xDim*yDim) xwave_PeakPix2D, ywave_PeakPix2D,zwave_PeakPix2D	
	FillPixTriplet(xwave_PeakPix2D, ywave_PeakPix2D,zwave_PeakPix2D,xDim,yDim)	
	Make/O/D/N=(xDim,yDim) PeakPix2D_mat		// use the point scaling of the matrix (=pixels)
	Duplicate/O $"PeakPix2D_mat",$"PeakPix2D_lin" 		//keep a linear-scaled version of the data
	
	return(0)
End





Function DetModelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			Execute "PlotBroadPeak_Pix2D()"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




Function DetFitGuessButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Wave dispW=root:curDispPanel
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





Function DetFitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Wave dispW=root:curDispPanel
			Wave coefW=root:coef_PeakPix2D
			
			FuncFitMD/H="11000111100"/NTHR=0 BroadPeak_Pix2D coefW  dispW /D			
			
			Wave ws=W_sigma
			AppendtoTable/W=PanelFit#T0 ws
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DetFitHelpButtonProc(ba) : ButtonControl
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
