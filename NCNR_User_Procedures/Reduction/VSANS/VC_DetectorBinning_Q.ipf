#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//////////////////
// 
// Procedures for:
//
//		Gathering information to calculate QxQyQz
//		Filling the panels with Qtot, QxQyQz
//		Filling the "data" with a model function
//		Averaging the panels (independently) into I(Q)
//		Plotting the 9 detector panels in 2D
//		Plotting the 1D I(q) data depending on the panel combinations
//
//
//  There are some things in the current circular averaging that don't make any sense
//  and don't seem to really do anything at all, so i have decided to trim them out.
//  1) subdividing pixels near the beam stop into 9 sub-pixels
//  2) non-linear correction (only applies to Ordela)
//
//
//  Do I separate out the circular, sector, rectangular, annular averaging into
//   separate routines? 
//
//
//
///////////////////


Proc PlotFrontPanels()
	fPlotFrontPanels()
End

//
// Plot the front panels in 2D and 1D
//		calcualate Q
//		fill w/model data
//		"shadow" the T/B detectors
//		bin the data to I(q)
//		draw I(q) graph
//		draw 2D panel graph
//
// *** Call this function when front panels are adjusted, or wavelength, etc. changed
//
Function fPlotFrontPanels()

	// space is allocated for all of the detectors and Q's on initialization
	// calculate Qtot, qxqyqz arrays from geometry
	VC_CalculateQFrontPanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

	String folderStr = "VCALC"
	String detStr = ""

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	detStr = "FL"
	WAVE det_FL = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_FL = $(folderPath+instPath+detStr+":qTot_"+detStr)
	
	detStr = "FR"
	WAVE det_FR = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_FR = $(folderPath+instPath+detStr+":qTot_"+detStr)
	
	detStr = "FT"
	WAVE det_FT = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_FT = $(folderPath+instPath+detStr+":qTot_"+detStr)
	
	detStr = "FB"
	WAVE det_FB = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_FB = $(folderPath+instPath+detStr+":qTot_"+detStr)

	FillPanel_wModelData(det_FL,qTot_FL,"FL")
	FillPanel_wModelData(det_FR,qTot_FR,"FR")
	FillPanel_wModelData(det_FT,qTot_FT,"FT")
	FillPanel_wModelData(det_FB,qTot_FB,"FB")

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
	//TODO - make this a proper shadow - TB extent of the LR panels matters too, not just the LR separation
	VC_SetShadow_TopBottom("VCALC","FT")		// TODO: -- be sure the data folder is properly set (within the function...)
	VC_SetShadow_TopBottom("VCALC","FB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllFrontPanels()"

	// plot the results
	Execute "Front_IQ_Graph()"
	FrontPanels_AsQ()
	
	return(0)
End


// works for Left, works for Right... works for T/B too.
//
// - TODO: be sure that the Q's are calculated correctly even when the beam is off of the 
//     detector, and on different sides of the detector (or T/B) - since it will be in a different
//     relative postion to 0,0 on the detector. If the postions are symmetric, then the Q's should be identical.
//     --- test this...
// TODO -- be sure I'm in the right data folder. nothing is set correctly right now
//
// TODO: make all detector parameters global, not hard-wired
//
//
// --- Panels are all allocated in the initialization. Here, only the q-values are calculated
//     when anything changes
//
// TODO
// NOTE -- this is VCALC ONLY. data is not referenced for hdf here, and data is rescaled based on VCALC assumptions
//
Function VC_CalculateQFrontPanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY,nPix_X,nPix_Y
	Variable F_LR_sep,F_TB_sep,F_offset,F_sdd_offset

	String folderPath = "root:Packages:NIST:VSANS:VCALC"
	String instPath = ":entry:instrument:detector_"
	String detStr=""

// get the values from the panel + constants	
	F_LR_sep = VCALC_getPanelSeparation("FLR")
	F_TB_sep = VCALC_getPanelSeparation("FTB")
	F_offset = VCALC_getLateralOffset("FL")
	
	SDD = VCALC_getSDD("FL")		//nominal SDD - need offset for TB
	lam = VCALC_getWavelength()

//separations are in mm -- need to watch the units, convert to cm
	F_LR_sep /= 10
	F_TB_sep /= 10
// TODO - I'm treating the separation as the TOTAL width - so the difference
//      from the "center" to the edge is 1/2 of the separation

// TODO (make the N along the tube length a variable, since this can be reset @ acquisition)

	F_sdd_offset = VCALC_getTopBottomSDDOffset("FT") 	//T/B are 300 mm farther back  //TODO: make all detector parameters global, not hard-wired

// detector data to bin
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	Wave det_FL = $(folderPath+instPath+"FL"+":det_FL")
	Wave det_FR = $(folderPath+instPath+"FR"+":det_FR")		// these are (48,128)		(nominal, may change)

	Wave det_FT = $(folderPath+instPath+"FT"+":det_FT")
	Wave det_FB = $(folderPath+instPath+"FB"+":det_FB")		// these are (128,48)

//FRONT/LEFT
	detStr = "FL"
	Wave qTot_FL = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_FL = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_FL = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_FL = $(folderPath+instPath+detStr+":qz_"+detStr)	

	qTot_FL = 0
	qx_FL = 0
	qy_FL = 0
	qz_FL = 0	
	
// TODO - these are to be set from globals, not hard-wired. N and pixelSixze will be known (or pre-measured)
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FL")
	pixSizeY = VCALC_getPixSizeY("FL")
//	pixSizeX = 0.8			// 0.8 cm/pixel along width
//	pixSizeY = 0.4			// approx 0.4 cm/pixel along length
	nPix_X = VCALC_get_nPix_X("FL")
	nPix_Y = VCALC_get_nPix_Y("FL")
	
	xCtr = nPix_X+(F_LR_sep/2/pixSizeX)		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	yCtr = nPix_Y/2	
	VC_Detector_2Q(det_FL,qTot_FL,qx_FL,qy_FL,qz_FL,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for FL = ",xCtr,yCtr
	
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// TODO: this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	SetScale/I x WaveMin(qx_FL),WaveMax(qx_FL),"", det_FL		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FL),WaveMax(qy_FL),"", det_FL
//////////////////

//FRONT/RIGHT
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	detStr = "FR"
	Wave qTot_FR = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_FR = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_FR = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_FR = $(folderPath+instPath+detStr+":qz_"+detStr)	
	
	qTot_FR = 0
	qx_FR = 0
	qy_FR = 0
	qz_FR = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FR")
	pixSizeY = VCALC_getPixSizeY("FR")
	nPix_X = VCALC_get_nPix_X("FR")
	nPix_Y = VCALC_get_nPix_Y("FR")
	
	xCtr = -(F_LR_sep/2/pixSizeX)-1		
	yCtr = nPix_Y/2	
	VC_Detector_2Q(det_FR,qTot_FR,qx_FR,qy_FR,qz_FR,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for FR = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FR),WaveMax(qx_FR),"", det_FR		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FR),WaveMax(qy_FR),"", det_FR
/////////////////

//FRONT/TOP
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	detStr = "FT"
	Wave qTot_FT = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_FT = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_FT = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_FT = $(folderPath+instPath+detStr+":qz_"+detStr)	

	qTot_FT = 0
	qx_FT = 0
	qy_FT = 0
	qz_FT = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FT")
	pixSizeY = VCALC_getPixSizeY("FT")
	nPix_X = VCALC_get_nPix_X("FT")
	nPix_Y = VCALC_get_nPix_Y("FT")
	
	xCtr = nPix_X/2
	yCtr = -(F_TB_sep/2/pixSizeY)-1   
	// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	VC_Detector_2Q(det_FT,qTot_FT,qx_FT,qy_FT,qz_FT,xCtr,yCtr,sdd+F_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for FT = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FT),WaveMax(qx_FT),"", det_FT		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FT),WaveMax(qy_FT),"", det_FT
//////////////////

//FRONT/BOTTOM
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	detStr = "FB"
	Wave qTot_FB = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_FB = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_FB = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_FB = $(folderPath+instPath+detStr+":qz_"+detStr)	

	qTot_FB = 0
	qx_FB = 0
	qy_FB = 0
	qz_FB = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FB")
	pixSizeY = VCALC_getPixSizeY("FB")
	nPix_X = VCALC_get_nPix_X("FB")
	nPix_Y = VCALC_get_nPix_Y("FB")
		
	xCtr = nPix_X/2
	yCtr = nPix_Y+(F_TB_sep/2/pixSizeY) 		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	VC_Detector_2Q(det_FB,qTot_FB,qx_FB,qy_FB,qz_FB,xCtr,yCtr,sdd+F_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for FB = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FB),WaveMax(qx_FB),"", det_FB		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FB),WaveMax(qy_FB),"", det_FB
/////////////////

	SetDataFolder root:
		
	return(0)
End


// TODO - this doesn't quite mask things out as they should be (too much is masked L/R of center)
// and the outer edges of the detector are masked even if the TB panels extend past the TB of the LR panels.
// ? skip the masking? but then I bin the detector data directly to get I(q), skipping the masked NaN values...
//
Function VC_SetShadow_TopBottom(folderStr,type)
	String folderStr,type
	
	Variable LR_sep,nPix,xCtr,ii,jj,numCol,pixSizeX,pixSizeY,nPix_X,nPix_Y

/// !! type passed in will be FT, FB, MT, MB, so I can't ask for the panel separation -- or I'll get the TB separation...
	if(cmpstr(type[0],"F")==0)
		//front
		ControlInfo/W=VCALC VCALCCtrl_2a
		LR_sep = V_Value	
	else
		//middle
		ControlInfo/W=VCALC VCALCCtrl_3a
		LR_sep = V_Value	
	endif		
//separations on panel are in mm -- need to watch the units, convert to cm
	LR_sep /= 10

//detector data
	Wave det = $("root:Packages:NIST:VSANS:"+folderStr+":entry:instrument:detector_"+type+":det_"+type)

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm for T/B detector
// TODO - the "FT" check is hard wired for FRONT -- get rid of this...

	pixSizeX = VCALC_getPixSizeX(type)
	pixSizeY = VCALC_getPixSizeY(type)

	nPix_X = VCALC_get_nPix_X(type)
	nPix_Y = VCALC_get_nPix_Y(type)
	
	//TODO -- get this from a global
	xCtr = nPix_X/2
	nPix = trunc(LR_sep/2/pixSizeX)		// approx # of pixels Left/right of center that are not obscured by L/R panels
	
	numCol = DimSize(det,0)		// x dim (columns)
	for(ii=0;ii<(xCtr-nPix-2);ii+=1)
		det[ii][] = NaN
	endfor
	for(ii=(xCtr+nPix+2);ii<numCol;ii+=1)
		det[ii][] = NaN
	endfor
	
	return(0)
end


// After the panels have been calculated and rescaled in terms of Q, and filled with simulated data
// they can be appended to the subwindow. If they are already there, the axes and coloring
// are rescaled as needed
//
Function FrontPanels_AsQ()

	String frontStr = "root:Packages:NIST:VSANS:VCALC:entry:instrument:"
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	SetDataFolder $(frontStr+"detector_FB")
	Wave det_FB = det_FB
	SetDataFolder $(frontStr+"detector_FT")
	Wave det_FT = det_FT
	SetDataFolder $(frontStr+"detector_FL")
	Wave det_FL = det_FL
	SetDataFolder $(frontStr+"detector_FR")
	Wave det_FR = det_FR
	
	CheckDisplayed /W=VCALC#Panels_Q det_FB
	if(V_flag == 0)
		AppendImage/W=VCALC#Panels_Q det_FB
		ModifyImage/W=VCALC#Panels_Q det_FB ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_FT
		ModifyImage/W=VCALC#Panels_Q det_FT ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_FL
		ModifyImage/W=VCALC#Panels_Q det_FL ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_FR
		ModifyImage/W=VCALC#Panels_Q det_FR ctab= {*,*,ColdWarm,0}
	endif

	Variable dval
	ControlInfo/W=VCALC setVar_b
	dval = V_Value

	SetAxis/W=VCALC#Panels_Q left -dval,dval
	SetAxis/W=VCALC#Panels_Q bottom -dval,dval	

	ControlInfo/W=VCALC check_0a
// V_Value == 1 if checked
	ModifyImage/W=VCALC#Panels_Q det_FB log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_FT log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_FL log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_FR log=V_Value


	SetDataFolder root:
	
EndMacro






//
// these routines bin the 2D q data to 1D I(q). Currently the Qtot is magnitude only, no sign (since
// it's being binned to I(Q), having a sign makes no sense. If you want the sign, work from qxqyqz
//
// first - the DeltaQ step is set as the smaller detector resolution (along tube)
//       which is different for LR / TB geometry. This is not set in stone.
//
// second - each detector is binned separately
//
// -- like the routines in CircSectAve, start with 500 points, and trim after binning is done.
// 	you'l end up with < 200 points.
//
// the results are in iBin_qxqy, qBin_qxqy, and eBin_qxqy, in the folder passed
// 
Proc BinAllFrontPanels()

	SetDeltaQ("VCALC","FL")
	SetDeltaQ("VCALC","FR")
	SetDeltaQ("VCALC","FT")
	SetDeltaQ("VCALC","FB")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	if(binType == 1)
		VC_BinQxQy_to_1D("VCALC","FL")
		VC_BinQxQy_to_1D("VCALC","FR")
		VC_BinQxQy_to_1D("VCALC","FT")
		VC_BinQxQy_to_1D("VCALC","FB")
	endif
	
	if(binType == 2)	
		VC_BinQxQy_to_1D("VCALC","FLR")
		VC_BinQxQy_to_1D("VCALC","FTB")
	endif

	if(binType == 3)
		VC_BinQxQy_to_1D("VCALC","FLRTB")
	endif

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		VC_fBinDetector_byRows("VCALC","FL")
		VC_fBinDetector_byRows("VCALC","FR")
		VC_fBinDetector_byRows("VCALC","FT")
		VC_fBinDetector_byRows("VCALC","FB")
	endif
		
End







Proc PlotMiddlePanels()
	fPlotMiddlePanels()
End

// to plot I(q) for the 4 Middle panels
//
// *** Call this function when Middle panels are adjusted, or wavelength, etc. changed
//
Function fPlotMiddlePanels()

	// space is allocated for all of the detectors and Q's on initialization
	// calculate Qtot, qxqyqz arrays from geometry
	VC_CalculateQMiddlePanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle

	String folderStr = "VCALC"
	String detStr = ""

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	detStr = "ML"
	WAVE det_ML = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_ML = $(folderPath+instPath+detStr+":qTot_"+detStr)

	detStr = "MR"
	WAVE det_MR = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_MR = $(folderPath+instPath+detStr+":qTot_"+detStr)

	detStr = "MT"
	WAVE det_MT = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_MT = $(folderPath+instPath+detStr+":qTot_"+detStr)

	detStr = "MB"
	WAVE det_MB = $(folderPath+instPath+detStr+":det_"+detStr)	
	WAVE qTot_MB = $(folderPath+instPath+detStr+":qTot_"+detStr)

	FillPanel_wModelData(det_ML,qTot_ML,"ML")
	FillPanel_wModelData(det_MR,qTot_MR,"MR")
	FillPanel_wModelData(det_MT,qTot_MT,"MT")
	FillPanel_wModelData(det_MB,qTot_MB,"MB")			

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
	VC_SetShadow_TopBottom("VCALC","MT")		// TODO: -- be sure the data folder is properly set (within the function...)
	VC_SetShadow_TopBottom("VCALC","MB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllMiddlePanels()"

	// plot the results
	Execute "Middle_IQ_Graph()"
	MiddlePanels_AsQ()
	
	return(0)
End

// works for Left, works for Right... works for T/B too.
//
// - TODO: be sure that the Q's are calculated correctly even when the beam is off of the 
//     detector, and on different sides of the detector (or T/B) - since it will be in a different
//     relative postion to 0,0 on the detector. If the postions are symmetric, then the Q's should be identical.
//     --- test this...
// TODO -- be sure I'm in the right data folder. nothing is set correctly right now
//
// TODO: make all detector parameters global, not hard-wired
//
//
// --- Panels are all allocated in the initialization. Here, only the q-values are calculated
//     when anything changes
//
Function VC_CalculateQMiddlePanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY,nPix_X,nPix_Y
	Variable M_LR_sep,M_TB_sep,M_offset, M_sdd_offset


	String folderPath = "root:Packages:NIST:VSANS:VCALC"
	String instPath = ":entry:instrument:detector_"
	String detStr=""
	
	M_LR_sep = VCALC_getPanelSeparation("MLR")
	M_TB_sep = VCALC_getPanelSeparation("MTB")
	M_offset = VCALC_getLateralOffset("ML")
	
	SDD = VCALC_getSDD("ML")		//nominal SDD - need offset for TB
	lam = VCALC_getWavelength()

//separations are in mm -- need to watch the units, convert to cm
	M_LR_sep /= 10
	M_TB_sep /= 10
// TODO - I'm treating the separation as the TOTAL width - so the difference
//      from the "center" to the edge is 1/2 of the separation

// TODO (make the N along the tube length a variable, since this can be reset @ acquisition)
	M_sdd_offset = VCALC_getTopBottomSDDOffset("MT") 	//T/B are 30 cm farther back  //TODO: make all detector parameters global, not hard-wired


//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	Wave det_ML = $(folderPath+instPath+"ML"+":det_ML")
	Wave det_MR = $(folderPath+instPath+"MR"+":det_MR")		// these are (48,128)		(nominal, may change)

	Wave det_MT = $(folderPath+instPath+"MT"+":det_MT")
	Wave det_MB = $(folderPath+instPath+"MB"+":det_MB")		// these are (128,48)

//Middle/LEFT
	detStr = "ML"
	Wave qTot_ML = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_ML = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_ML = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_ML = $(folderPath+instPath+detStr+":qz_"+detStr)	
	
	qTot_ML = 0
	qx_ML = 0
	qy_ML = 0
	qz_ML = 0	
	
// TODO - these are to be set from globals, not hard-wired. N and pixelSixze will be known (or pre-measured)
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("ML")
	pixSizeY = VCALC_getPixSizeY("ML")
	nPix_X = VCALC_get_nPix_X("ML")
	nPix_Y = VCALC_get_nPix_Y("ML")
	
	xCtr = nPix_X+(M_LR_sep/2/pixSizeX)		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	yCtr = nPix_Y/2	
	VC_Detector_2Q(det_ML,qTot_ML,qx_ML,qy_ML,qz_ML,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for ML = ",xCtr,yCtr
	
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// TODO: this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	SetScale/I x WaveMin(qx_ML),WaveMax(qx_ML),"", det_ML		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_ML),WaveMax(qy_ML),"", det_ML
	
//////////////////

//Middle/RIGHT
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	detStr = "MR"
	Wave qTot_MR = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_MR = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_MR = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_MR = $(folderPath+instPath+detStr+":qz_"+detStr)
	
	qTot_MR = 0
	qx_MR = 0
	qy_MR = 0
	qz_MR = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MR")
	pixSizeY = VCALC_getPixSizeY("MR")

	nPix_X = VCALC_get_nPix_X("MR")
	nPix_Y = VCALC_get_nPix_Y("MR")
	
	xCtr = -(M_LR_sep/2/pixSizeX)-1		
	yCtr = nPix_Y/2
	VC_Detector_2Q(det_MR,qTot_MR,qx_MR,qy_MR,qz_MR,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for MR = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MR),WaveMax(qx_MR),"", det_MR		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_MR),WaveMax(qy_MR),"", det_MR
/////////////////

//Middle/TOP
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	detStr = "MT"
	Wave qTot_MT = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_MT = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_MT = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_MT = $(folderPath+instPath+detStr+":qz_"+detStr)

	qTot_MT = 0
	qx_MT = 0
	qy_MT = 0
	qz_MT = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MT")
	pixSizeY = VCALC_getPixSizeY("MT")
	nPix_X = VCALC_get_nPix_X("MT")
	nPix_Y = VCALC_get_nPix_Y("MT")
	
	xCtr = nPix_X/2
	yCtr = -(M_TB_sep/2/pixSizeY)-1 
	// global sdd_offset is in (mm), convert to meters here for the Q-calculation  
	VC_Detector_2Q(det_MT,qTot_MT,qx_MT,qy_MT,qz_MT,xCtr,yCtr,sdd+M_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for MT = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MT),WaveMax(qx_MT),"", det_MT		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_MT),WaveMax(qy_MT),"", det_MT
//////////////////

//Middle/BOTTOM
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	detStr = "MB"
	Wave qTot_MB = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_MB = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_MB = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_MB = $(folderPath+instPath+detStr+":qz_"+detStr)

	qTot_MB = 0
	qx_MB = 0
	qy_MB = 0
	qz_MB = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MB")
	pixSizeY = VCALC_getPixSizeY("MB")
	nPix_X = VCALC_get_nPix_X("MB")
	nPix_Y = VCALC_get_nPix_Y("MB")
		
	xCtr = nPix_X/2
	yCtr = nPix_Y+(M_TB_sep/2/pixSizeY) 		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
		// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	VC_Detector_2Q(det_MB,qTot_MB,qx_MB,qy_MB,qz_MB,xCtr,yCtr,sdd+M_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for MB = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MB),WaveMax(qx_MB),"", det_MB		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_MB),WaveMax(qy_MB),"", det_MB
/////////////////

	SetDataFolder root:
		
	return(0)
End


Function MiddlePanels_AsQ()
//	DoWindow/F MiddlePanels_AsQ
//	if(V_flag == 0)
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(1477,44,1978,517)

	String midStr = "root:Packages:NIST:VSANS:VCALC:entry:instrument:"
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	SetDataFolder $(midStr+"detector_MB")
	Wave det_MB = det_MB
	SetDataFolder $(midStr+"detector_MT")
	Wave det_MT = det_MT
	SetDataFolder $(midStr+"detector_ML")
	Wave det_ML = det_ML
	SetDataFolder $(midStr+"detector_MR")
	Wave det_MR = det_MR

	CheckDisplayed /W=VCALC#Panels_Q det_MB
	
	if(V_flag == 0)
		AppendImage/W=VCALC#Panels_Q det_MB
		ModifyImage/W=VCALC#Panels_Q det_MB ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_MT
		ModifyImage/W=VCALC#Panels_Q det_MT ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_ML
		ModifyImage/W=VCALC#Panels_Q det_ML ctab= {*,*,ColdWarm,0}
		AppendImage/W=VCALC#Panels_Q det_MR
		ModifyImage/W=VCALC#Panels_Q det_MR ctab= {*,*,ColdWarm,0}
	endif

	Variable dval
	ControlInfo/W=VCALC setVar_b
	dval = V_Value

	SetAxis/W=VCALC#Panels_Q left -dval,dval
	SetAxis/W=VCALC#Panels_Q bottom -dval,dval	

	ControlInfo/W=VCALC check_0a
// V_Value == 1 if checked
	ModifyImage/W=VCALC#Panels_Q det_MB log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_MT log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_ML log=V_Value
	ModifyImage/W=VCALC#Panels_Q det_MR log=V_Value


	SetDataFolder root:
	
//	ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
//	ModifyGraph grid=2
//	ModifyGraph mirror=2
//	SetAxis left -0.2,0.2
//	SetAxis bottom -0.2,0.2
//	endif
EndMacro

//
// these routines bin the 2D q data to 1D I(q). Currently the Qtot is magnitude only, no sign (since
// it's being binned to I(Q), having a sign makes no sense. If you want the sign, work from qxqyqz
//
// first - the DeltaQ step is set as the smaller detector resolution (along tube)
//       which is different for LR / TB geometry. This is not set in stone.
//
// second - each detector is binned separately
//
// -- like the routines in CircSectAve, start with 500 points, and trim after binning is done.
// 	you'l end up with < 200 points.
//
// the results are in iBin_qxqy, qBin_qxqy, and eBin_qxqy, in the folder passed
// 
Proc BinAllMiddlePanels()

	SetDeltaQ("VCALC","ML")
	SetDeltaQ("VCALC","MR")
	SetDeltaQ("VCALC","MT")
	SetDeltaQ("VCALC","MB")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	if(binType == 1)
		VC_BinQxQy_to_1D("VCALC","ML")
		VC_BinQxQy_to_1D("VCALC","MR")
		VC_BinQxQy_to_1D("VCALC","MT")
		VC_BinQxQy_to_1D("VCALC","MB")
	endif
	
	if(binType == 2)	
		VC_BinQxQy_to_1D("VCALC","MLR")
		VC_BinQxQy_to_1D("VCALC","MTB")
	endif

	if(binType == 3)
		VC_BinQxQy_to_1D("VCALC","MLRTB")
	endif
	
	// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		VC_fBinDetector_byRows("VCALC","ML")
		VC_fBinDetector_byRows("VCALC","MR")
		VC_fBinDetector_byRows("VCALC","MT")
		VC_fBinDetector_byRows("VCALC","MB")
	endif
End

////////////to plot the (4) 2D panels and to plot the I(Q) data on the same plot
Window Middle_IQ_Graph() : Graph

	Variable binType
	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	if(binType==1)
		ClearIQIfDisplayed("VCALC","MLRTB")
		ClearIQIfDisplayed("VCALC","MLR")
		ClearIQIfDisplayed("VCALC","MTB")
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
		endif		
	endif
	
	if(binType==2)
		ClearIQIfDisplayed("VCALC","MLRTB")
		ClearIQIfDisplayed("VCALC","MT")	
		ClearIQIfDisplayed("VCALC","ML")	
		ClearIQIfDisplayed("VCALC","MR")	
		ClearIQIfDisplayed("VCALC","MB")
	

		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_MLR vs qBin_qxqy_MLR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MTB vs qBin_qxqy_MTB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_MLR)=(65535,0,0),rgb(iBin_qxqy_MTB)=(1,16019,65535)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_MLR)={0,2}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearIQIfDisplayed("VCALC","MLR")
		ClearIQIfDisplayed("VCALC","MTB")	
		ClearIQIfDisplayed("VCALC","MT")	
		ClearIQIfDisplayed("VCALC","ML")	
		ClearIQIfDisplayed("VCALC","MR")	
		ClearIQIfDisplayed("VCALC","MB")	
	
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_MLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_MLRTB vs qBin_qxqy_MLRTB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_MLRTB)=(65535,0,0)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - Mt, ML, MR, MB are averaged
		ClearIQIfDisplayed("VCALC","MLRTB")
		ClearIQIfDisplayed("VCALC","MLR")
		ClearIQIfDisplayed("VCALC","MTB")
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
		endif		
			
	endif
	SetDataFolder root:
EndMacro


////////// and for the BACK detector
Proc PlotBackPanels()
	fPlotBackPanels()
End

// to plot I(q) for the Back panel
//
// *** Call this function when Back panel is adjusted, or wavelength, etc. changed
//
Function fPlotBackPanels()

	// space is allocated for all of the detectors and Q's on initialization
	// calculate Qtot, qxqyqz arrays from geometry
	VC_CalculateQBackPanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

	WAVE det_B = det_B
	WAVE qTot_B = qTot_B

	FillPanel_wModelData(det_B,qTot_B,"B")		

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
//	VC_SetShadow_TopBottom("","MT")		// TODO: -- be sure the data folder is properly set (within the function...)
//	VC_SetShadow_TopBottom("","MB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllBackPanels()"

	// plot the results
	Execute "Back_IQ_Graph()"
	Execute "BackPanels_AsQ()"

	return(0)

End

// works for Left, works for Right... works for T/B too.
//
// - TODO: be sure that the Q's are calculated correctly even when the beam is off of the 
//     detector, and on different sides of the detector (or T/B) - since it will be in a different
//     relative postion to 0,0 on the detector. If the postions are symmetric, then the Q's should be identical.
//     --- test this...
// TODO -- be sure I'm in the right data folder. nothing is set correctly right now
//
// TODO: make all detector parameters global, not hard-wired
//
//
// --- Panels are all allocated in the initialization. Here, only the q-values are calculated
//     when anything changes
//
Function VC_CalculateQBackPanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
	Variable B_offset

	String folderPath = "root:Packages:NIST:VSANS:VCALC"
	String instPath = ":entry:instrument:detector_"
	String detStr = ""
	
	B_offset = VCALC_getLateralOffset("B")
	
	SDD = VCALC_getSDD("B")		//nominal SDD - need offset for TB
	lam = VCALC_getWavelength()

// TODO (make the N along the tube length a variable, since this can be reset @ acquisition)
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Back
	WAVE det_B = $(folderPath+instPath+"B"+":det_B")			// this is nominally (150,150)

//Back detector
//root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B:qTot_B
	detStr = "B"
	Wave qTot_B = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx_B = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy_B = $(folderPath+instPath+detStr+":qy_"+detStr)	
	Wave qz_B = $(folderPath+instPath+detStr+":qz_"+detStr)

	qTot_B = 0
	qx_B = 0
	qy_B = 0
	qz_B = 0	
	
// TODO - these are to be set from globals, not hard-wired. N and pixelSixze will be known (or pre-measured)
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("B")
	pixSizeY = VCALC_getPixSizeY("B")
	
	xCtr = trunc( DimSize(det_B,0)/2 )		//should be 150/2=75
	yCtr = trunc( DimSize(det_B,1)/2 )		//should be 150/2=75
	VC_Detector_2Q(det_B,qTot_B,qx_B,qy_B,qz_B,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
	
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// TODO: this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	SetScale/I x WaveMin(qx_B),WaveMax(qx_B),"", det_B		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_B),WaveMax(qy_B),"", det_B

	SetDataFolder root:
		
	return(0)
End


Window BackPanels_AsQ() : Graph
//	DoWindow/F BackPanels_AsQ
//	if(V_flag == 0)
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(1477,44,1978,517)

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

	CheckDisplayed /W=VCALC#Panels_Q det_B
	if(V_flag == 0)
		AppendImage/W=VCALC#Panels_Q det_B
		ModifyImage/W=VCALC#Panels_Q det_B ctab= {*,*,ColdWarm,0}
	endif

	Variable dval
	ControlInfo/W=VCALC setVar_b
	dval = V_Value

	SetAxis/W=VCALC#Panels_Q left -dval,dval
	SetAxis/W=VCALC#Panels_Q bottom -dval,dval	

	ControlInfo/W=VCALC check_0a
// V_Value == 1 if checked
	ModifyImage/W=VCALC#Panels_Q det_B log=V_Value

	SetDataFolder root:
	
//	ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
//	ModifyGraph grid=2
//	ModifyGraph mirror=2
//	SetAxis left -0.2,0.2
//	SetAxis bottom -0.2,0.2
//	endif
EndMacro

//
// these routines bin the 2D q data to 1D I(q). Currently the Qtot is magnitude only, no sign (since
// it's being binned to I(Q), having a sign makes no sense. If you want the sign, work from qxqyqz
//
// first - the DeltaQ step is set as the smaller detector resolution (along tube)
//       which is different for LR / TB geometry. This is not set in stone.
//
// second - each detector is binned separately
//
// -- like the routines in CircSectAve, start with 500 points, and trim after binning is done.
// 	you'l end up with < 200 points.
//
// the results are in iBin_qxqy, qBin_qxqy, and eBin_qxqy, in the folder passed
// 
Proc BinAllBackPanels()

	SetDeltaQ("VCALC","B")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4
	
	VC_BinQxQy_to_1D("VCALC","B")

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		VC_fBinDetector_byRows("VCALC","B")
	endif	
	
End

////////////to plot the back panel I(q)
Window Back_IQ_Graph() : Graph

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

	Variable binType
	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4
	

	if(binType==1 || binType==2 || binType==3)
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
		endif
	endif

	//nothing different here since there is ony a single detector to display, but for the future...
	if(binType==4)
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
		endif
	endif

	
	SetDataFolder root:
EndMacro


////////////to plot the (4) 2D panels and to plot the I(Q) data on the same plot
//
// ** but now I need to check and see if these waves exist before trying to append them
// since the panels may bave been combined when binned - rather than all separate.
//
// TODO
// -- so maybe I want to clear the traces from the graph?
// -- set a flag on the panel to know how the binning is applied?
//
Window Front_IQ_Graph() : Graph

	Variable binType
	String fldr = "VCALC"
	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	if(binType==1)
		ClearIQIfDisplayed("VCALC","FLRTB")
		ClearIQIfDisplayed("VCALC","FLR")
		ClearIQIfDisplayed("VCALC","FTB")
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
				
	endif

	if(binType==2)
		ClearIQIfDisplayed("VCALC","FLRTB")
		ClearIQIfDisplayed("VCALC","FT")	
		ClearIQIfDisplayed("VCALC","FL")	
		ClearIQIfDisplayed("VCALC","FR")	
		ClearIQIfDisplayed("VCALC","FB")
	

		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FTB vs qBin_qxqy_FTB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearIQIfDisplayed("VCALC","FLR")
		ClearIQIfDisplayed("VCALC","FTB")	
		ClearIQIfDisplayed("VCALC","FT")	
		ClearIQIfDisplayed("VCALC","FL")	
		ClearIQIfDisplayed("VCALC","FR")	
		ClearIQIfDisplayed("VCALC","FB")	
	
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_FLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_FLRTB vs qBin_qxqy_FLRTB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_FLRTB)=(39321,26208,1)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
			
	endif


	if(binType==4)		//slit mode
		ClearIQIfDisplayed("VCALC","FLRTB")
		ClearIQIfDisplayed("VCALC","FLR")
		ClearIQIfDisplayed("VCALC","FTB")
		
		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=VCALC#Panels_IQ iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=VCALC#Panels_IQ iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=VCALC#Panels_IQ iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=VCALC#Panels_IQ mode=4
			ModifyGraph/W=VCALC#Panels_IQ marker=19
			ModifyGraph/W=VCALC#Panels_IQ rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=VCALC#Panels_IQ msize=2
			ModifyGraph/W=VCALC#Panels_IQ muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=VCALC#Panels_IQ grid=1
			ModifyGraph/W=VCALC#Panels_IQ log=1
			ModifyGraph/W=VCALC#Panels_IQ mirror=2
			Label/W=VCALC#Panels_IQ left "Intensity (1/cm)"
			Label/W=VCALC#Panels_IQ bottom "Q (1/A)"
		endif	
				
	endif

	
	SetDataFolder root:
	
EndMacro


Function ClearIQIfDisplayed(fldr,type)
	String fldr,type

	SetDataFolder $("root:Packages:NIST:VSANS:"+fldr)

	if(cmpstr(fldr,"VCALC") == 0)
		CheckDisplayed/W=VCALC#Panels_IQ $("iBin_qxqy_"+type)
		if(V_flag==1)
			RemoveFromGraph/W=VCALC#Panels_IQ $("iBin_qxqy_"+type)
		endif
	else
		CheckDisplayed/W=V_1D_Data $("iBin_qxqy_"+type)
		if(V_flag==1)
			RemoveFromGraph/W=V_1D_Data $("iBin_qxqy_"+type)
		endif
	endif

	SetDataFolder root:
	
	return(0)
end

Window Table_of_QBins() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:VSANS:VCALC:
	Edit/W=(5,44,771,898) qBin_qxqy_FL,qBin_qxqy_FR,qBin_qxqy_FT,qBin_qxqy_FB,qBin_qxqy_FLR
	AppendToTable qBin_qxqy_FTB,qBin_qxqy_FLRTB
	ModifyTable format(Point)=1,width(qBin_qxqy_FLR)=136,width(qBin_qxqy_FLRTB)=120
	SetDataFolder fldrSav0
EndMacro




