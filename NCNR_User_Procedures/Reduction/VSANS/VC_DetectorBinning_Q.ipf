#pragma rtGlobals=3		// Use modern global access method and strict wave access.


///// Procedures for:
//	Generating the detector panels
//	Filling the panels with Qtot, QxQyQz
// Filling the "data" with a model function
// Averaging the panels (independently) into I(Q)
//
//
//There are some things in the current circular averaging that don't make any sense
//and don't seem to really do anything at all, so trim them out.
//1) subdividing pixels near the beam stop into 9 sub-pixels
//2) non-linear correction (maybe keep this as a dummy). I may need to put some sort
//of correction here for the offset, or it may already be done as I receive it.
//
//
//
//Do I separate out the circular, sector, rectangular, annular averaging into
//separate routines? 
//
//
//


Proc PlotFrontPanels()
	fPlotFrontPanels()
End

// to plot I(q) for the 4 front panels
//
// *** Call this function when front panels are adjusted, or wavelength, etc. changed
//
Function fPlotFrontPanels()

	// space is allocated for all of the detectors and Q's on initialization
	// calculate Qtot, qxqyqz arrays from geometry
	V_CalculateQFrontPanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

	WAVE det_FL = det_FL
	WAVE det_FR = det_FR
	WAVE det_FT = det_FT
	WAVE det_FB = det_FB
	
	WAVE qTot_FL = qTot_FL
	WAVE qTot_FR = qTot_FR
	WAVE qTot_FT = qTot_FT
	WAVE qTot_FB = qTot_FB

	FillPanel_wModelData(det_FL,qTot_FL,"FL")
	FillPanel_wModelData(det_FR,qTot_FR,"FR")
	FillPanel_wModelData(det_FT,qTot_FT,"FT")
	FillPanel_wModelData(det_FB,qTot_FB,"FB")
//	det_FL = V_SphereForm(1,60,1e-6,1,qTot_FL[p][q])				
//	det_FR = V_SphereForm(1,60,1e-6,1,qTot_FR[p][q])				
//	det_FT = V_SphereForm(1,60,1e-6,1,qTot_FT[p][q])				
//	det_FB = V_SphereForm(1,60,1e-6,1,qTot_FB[p][q])			

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
	//TODO - make this a proper shadow - TB extent of the LR panels matters too, not just the LR separation
	V_SetShadow_TopBottom("Front","FT")		// TODO: -- be sure the data folder is properly set (within the function...)
	V_SetShadow_TopBottom("Front","FB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllFrontPanels()"

	// plot the results
	Execute "Front_IQ_Graph()"
	Execute "FrontPanels_AsQ()"
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
Function V_CalculateQFrontPanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
	Variable F_LR_sep,F_TB_sep,F_offset,F_sdd_offset

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

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	Wave det_FL,det_FR			// these are (48,256)
	Wave det_FT,det_FB			// these are (128,48)

//FRONT/LEFT	
	WAVE qTot_FL,qx_FL,qy_FL,qz_FL
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
	
	xCtr = 48+(F_LR_sep/2/pixSizeX)		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	yCtr = 127	
	V_Detector_2Q(det_FL,qTot_FL,qx_FL,qy_FL,qz_FL,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for FL = ",xCtr,yCtr
	
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// TODO: this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	SetScale/I x WaveMin(qx_FL),WaveMax(qx_FL),"", det_FL		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FL),WaveMax(qy_FL),"", det_FL
//////////////////

//FRONT/RIGHT
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	WAVE qTot_FR,qx_FR,qy_FR,qz_FR
	qTot_FR = 0
	qx_FR = 0
	qy_FR = 0
	qz_FR = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FR")
	pixSizeY = VCALC_getPixSizeY("FR")
	
	xCtr = -(F_LR_sep/2/pixSizeX)-1		
	yCtr = 127
	V_Detector_2Q(det_FR,qTot_FR,qx_FR,qy_FR,qz_FR,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for FR = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FR),WaveMax(qx_FR),"", det_FR		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FR),WaveMax(qy_FR),"", det_FR
/////////////////

//FRONT/TOP
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	WAVE qTot_FT,qx_FT,qy_FT,qz_FT
	qTot_FT = 0
	qx_FT = 0
	qy_FT = 0
	qz_FT = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FT")
	pixSizeY = VCALC_getPixSizeY("FT")

	xCtr = 64
	yCtr = -(F_TB_sep/2/pixSizeY)-1   
	// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	V_Detector_2Q(det_FT,qTot_FT,qx_FT,qy_FT,qz_FT,xCtr,yCtr,sdd+F_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for FT = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FT),WaveMax(qx_FT),"", det_FT		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FT),WaveMax(qy_FT),"", det_FT
//////////////////

//FRONT/BOTTOM
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
	WAVE qTot_FB,qx_FB,qy_FB,qz_FB
	qTot_FB = 0
	qx_FB = 0
	qy_FB = 0
	qz_FB = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("FB")
	pixSizeY = VCALC_getPixSizeY("FB")
	
	xCtr = 64
	yCtr = 48+(F_TB_sep/2/pixSizeY) 		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	V_Detector_2Q(det_FB,qTot_FB,qx_FB,qy_FB,qz_FB,xCtr,yCtr,sdd+F_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for FB = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_FB),WaveMax(qx_FB),"", det_FB		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_FB),WaveMax(qy_FB),"", det_FB
/////////////////

	SetDataFolder root:
		
	return(0)
End


// TODO" - this doesn't quite mask things out as they should be (too much is masked L/R of center)
// and the outer edges of the detector are masked even if the TB panels extend past the TB of the LR panels.
// ? skip the masking? but then I bin the detector data directly to get I(q), skipping the masked NaN values...
//
Function V_SetShadow_TopBottom(folderStr,type)
	String folderStr,type
	
	Variable LR_sep,nPix,xCtr,ii,jj,numCol,pixSizeX,pixSizeY

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
	Wave det = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+":det_"+type)

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm for T/B detector
// TODO: the "FT" check is hard wired for FRONT -- get rid of this...

	pixSizeX = VCALC_getPixSizeX(type)
	pixSizeY = VCALC_getPixSizeY(type)

	//TODO -- get this from a global
	xCtr = 64
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


Window FrontPanels_AsQ() : Graph
//	DoWindow/F FrontPanels_AsQ
//	if(V_flag == 0)
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(1477,44,1978,517)

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

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
Proc BinAllFrontPanels()

	SetDeltaQ("Front","FL")
	SetDeltaQ("Front","FT")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	if(binType == 1)
		V_BinQxQy_to_1D("","FL")
		V_BinQxQy_to_1D("","FR")
		V_BinQxQy_to_1D("","FT")
		V_BinQxQy_to_1D("","FB")
	endif
	
	if(binType == 2)	
		V_BinQxQy_to_1D("","FLR")
		V_BinQxQy_to_1D("","FTB")
	endif

	if(binType == 3)
		V_BinQxQy_to_1D("","FLRTB")
	endif

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		V_fBinDetector_byRows("Front","FL")
		V_fBinDetector_byRows("Front","FR")
		V_fBinDetector_byRows("Front","FT")
		V_fBinDetector_byRows("Front","FB")
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
	V_CalculateQMiddlePanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle

	WAVE det_ML = det_ML
	WAVE det_MR = det_MR
	WAVE det_MT = det_MT
	WAVE det_MB = det_MB
	
	WAVE qTot_ML = qTot_ML
	WAVE qTot_MR = qTot_MR
	WAVE qTot_MT = qTot_MT
	WAVE qTot_MB = qTot_MB

	FillPanel_wModelData(det_ML,qTot_ML,"ML")
	FillPanel_wModelData(det_MR,qTot_MR,"MR")
	FillPanel_wModelData(det_MT,qTot_MT,"MT")
	FillPanel_wModelData(det_MB,qTot_MB,"MB")			

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
	V_SetShadow_TopBottom("Middle","MT")		// TODO: -- be sure the data folder is properly set (within the function...)
	V_SetShadow_TopBottom("Middle","MB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllMiddlePanels()"

	// plot the results
	Execute "Middle_IQ_Graph()"
	Execute "MiddlePanels_AsQ()"
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
Function V_CalculateQMiddlePanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
	Variable M_LR_sep,M_TB_sep,M_offset, M_sdd_offset

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

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	Wave det_ML,det_MR			// these are (48,256)
	Wave det_MT,det_MB			// these are (128,48)

//Middle/LEFT	
	WAVE qTot_ML,qx_ML,qy_ML,qz_ML
	qTot_ML = 0
	qx_ML = 0
	qy_ML = 0
	qz_ML = 0	
	
// TODO - these are to be set from globals, not hard-wired. N and pixelSixze will be known (or pre-measured)
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("ML")
	pixSizeY = VCALC_getPixSizeY("ML")
	
	xCtr = 48+(M_LR_sep/2/pixSizeX)		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
	yCtr = 127	
	V_Detector_2Q(det_ML,qTot_ML,qx_ML,qy_ML,qz_ML,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for ML = ",xCtr,yCtr
	
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// TODO: this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	SetScale/I x WaveMin(qx_ML),WaveMax(qx_ML),"", det_ML		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_ML),WaveMax(qy_ML),"", det_ML
	
//////////////////

//Middle/RIGHT
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	WAVE qTot_MR,qx_MR,qy_MR,qz_MR
	qTot_MR = 0
	qx_MR = 0
	qy_MR = 0
	qz_MR = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MR")
	pixSizeY = VCALC_getPixSizeY("MR")
	
	xCtr = -(M_LR_sep/2/pixSizeX)-1		
	yCtr = 127
	V_Detector_2Q(det_MR,qTot_MR,qx_MR,qy_MR,qz_MR,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
//	Print "xy for MR = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MR),WaveMax(qx_MR),"", det_MR		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_MR),WaveMax(qy_MR),"", det_MR
/////////////////

//Middle/TOP
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	WAVE qTot_MT,qx_MT,qy_MT,qz_MT
	qTot_MT = 0
	qx_MT = 0
	qy_MT = 0
	qz_MT = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MT")
	pixSizeY = VCALC_getPixSizeY("MT")

	xCtr = 64
	yCtr = -(M_TB_sep/2/pixSizeY)-1 
		// global sdd_offset is in (mm), convert to meters here for the Q-calculation  
	V_Detector_2Q(det_MT,qTot_MT,qx_MT,qy_MT,qz_MT,xCtr,yCtr,sdd+M_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for MT = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MT),WaveMax(qx_MT),"", det_MT		//this sets the leMT and right ends of the data scaling
	SetScale/I y WaveMin(qy_MT),WaveMax(qy_MT),"", det_MT
//////////////////

//Middle/BOTTOM
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
	WAVE qTot_MB,qx_MB,qy_MB,qz_MB
	qTot_MB = 0
	qx_MB = 0
	qy_MB = 0
	qz_MB = 0

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("MB")
	pixSizeY = VCALC_getPixSizeY("MB")
	
	xCtr = 64
	yCtr = 48+(M_TB_sep/2/pixSizeY) 		// TODO  -- check -- starting from 47 rather than 48 (but I'm in pixel units for centers)??
		// global sdd_offset is in (mm), convert to meters here for the Q-calculation
	V_Detector_2Q(det_MB,qTot_MB,qx_MB,qy_MB,qz_MB,xCtr,yCtr,sdd+M_sdd_offset/1000,lam,pixSizeX,pixSizeY)
//	Print "xy for MB = ",xCtr,yCtr
	SetScale/I x WaveMin(qx_MB),WaveMax(qx_MB),"", det_MB		//this sets the left and right ends of the data scaling
	SetScale/I y WaveMin(qy_MB),WaveMax(qy_MB),"", det_MB
/////////////////

	SetDataFolder root:
		
	return(0)
End


Window MiddlePanels_AsQ() : Graph
//	DoWindow/F MiddlePanels_AsQ
//	if(V_flag == 0)
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(1477,44,1978,517)

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle

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

	SetDeltaQ("Middle","ML")
	SetDeltaQ("Middle","MT")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	if(binType == 1)
		V_BinQxQy_to_1D("","ML")
		V_BinQxQy_to_1D("","MR")
		V_BinQxQy_to_1D("","MT")
		V_BinQxQy_to_1D("","MB")
	endif
	
	if(binType == 2)	
		V_BinQxQy_to_1D("","MLR")
		V_BinQxQy_to_1D("","MTB")
	endif

	if(binType == 3)
		V_BinQxQy_to_1D("","MLRTB")
	endif
	
	// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		V_fBinDetector_byRows("Middle","ML")
		V_fBinDetector_byRows("Middle","MR")
		V_fBinDetector_byRows("Middle","MT")
		V_fBinDetector_byRows("Middle","MB")
	endif
End

////////////to plot the (4) 2D panels and to plot the I(Q) data on the same plot
Window Middle_IQ_Graph() : Graph

	Variable binType
	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	if(binType==1)
		ClearIQIfDisplayed("MLRTB")
		ClearIQIfDisplayed("MLR")
		ClearIQIfDisplayed("MTB")
		
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
		ClearIQIfDisplayed("MLRTB")
		ClearIQIfDisplayed("MT")	
		ClearIQIfDisplayed("ML")	
		ClearIQIfDisplayed("MR")	
		ClearIQIfDisplayed("MB")
	

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
		ClearIQIfDisplayed("MLR")
		ClearIQIfDisplayed("MTB")	
		ClearIQIfDisplayed("MT")	
		ClearIQIfDisplayed("ML")	
		ClearIQIfDisplayed("MR")	
		ClearIQIfDisplayed("MB")	
	
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
		ClearIQIfDisplayed("MLRTB")
		ClearIQIfDisplayed("MLR")
		ClearIQIfDisplayed("MTB")
		
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
	V_CalculateQBackPanels()
	
	// fill the panels with fake sphere scattering data
	// TODO: am I in the right data folder??
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Back

	WAVE det_B = det_B
	WAVE qTot_B = qTot_B

	FillPanel_wModelData(det_B,qTot_B,"B")		

	SetDataFolder root:
		
	// set any "shadowed" area of the T/B detectors to NaN to get a realitic
	// view of how much of the detectors are actually collecting data
	// -- I can get the separation L/R from the panel - only this "open" width is visible.
//	V_SetShadow_TopBottom("","MT")		// TODO: -- be sure the data folder is properly set (within the function...)
//	V_SetShadow_TopBottom("","MB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllBackPanels()"

	// plot the results
	Execute "Back_IQ_Graph()"
	Execute "BackPanels_AsQ()"
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
Function V_CalculateQBackPanels()

	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
	Variable B_offset

	B_offset = VCALC_getLateralOffset("B")
	
	SDD = VCALC_getSDD("B")		//nominal SDD - need offset for TB
	lam = VCALC_getWavelength()

// TODO (make the N along the tube length a variable, since this can be reset @ acquisition)
	SetDataFolder root:Packages:NIST:VSANS:VCALC:Back
	Wave det_B			// this is (320,320)

//Back detector
	WAVE qTot_B,qx_B,qy_B,qz_B
	qTot_B = 0
	qx_B = 0
	qy_B = 0
	qz_B = 0	
	
// TODO - these are to be set from globals, not hard-wired. N and pixelSixze will be known (or pre-measured)
// pixel sizes are in cm
	pixSizeX = VCALC_getPixSizeX("B")
	pixSizeY = VCALC_getPixSizeY("B")
	
	xCtr = trunc( DimSize(det_B,0)/2 )		//should be 160
	yCtr = trunc( DimSize(det_B,1)/2 )		//should be 160	
	V_Detector_2Q(det_B,qTot_B,qx_B,qy_B,qz_B,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
	
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

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Back

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

	SetDeltaQ("Back","B")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4
	
	V_BinQxQy_to_1D("","B")

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		V_fBinDetector_byRows("Back","B")
	endif	
	
End

////////////to plot the back panel I(q)
Window Back_IQ_Graph() : Graph

	SetDataFolder root:Packages:NIST:VSANS:VCALC

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
	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	if(binType==1)
		ClearIQIfDisplayed("FLRTB")
		ClearIQIfDisplayed("FLR")
		ClearIQIfDisplayed("FTB")
		
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
		ClearIQIfDisplayed("FLRTB")
		ClearIQIfDisplayed("FT")	
		ClearIQIfDisplayed("FL")	
		ClearIQIfDisplayed("FR")	
		ClearIQIfDisplayed("FB")
	

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
		ClearIQIfDisplayed("FLR")
		ClearIQIfDisplayed("FTB")	
		ClearIQIfDisplayed("FT")	
		ClearIQIfDisplayed("FL")	
		ClearIQIfDisplayed("FR")	
		ClearIQIfDisplayed("FB")	
	
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
		ClearIQIfDisplayed("FLRTB")
		ClearIQIfDisplayed("FLR")
		ClearIQIfDisplayed("FTB")
		
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

Function 	ClearIQIfDisplayed(type)
	String type
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	CheckDisplayed/W=VCALC#Panels_IQ $("iBin_qxqy_"+type)
	if(V_flag==1)
		RemoveFromGraph/W=VCALC#Panels_IQ $("iBin_qxqy_"+type)
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




