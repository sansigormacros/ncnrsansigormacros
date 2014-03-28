#pragma rtGlobals=3		// Use modern global access method and strict wave access.



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
	SetDataFolder root:Packages:NIST:VSANS:VCALC

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
	V_SetShadow_TopBottom("","MT")		// TODO: -- be sure the data folder is properly set (within the function...)
	V_SetShadow_TopBottom("","MB")
	
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
	M_sdd_offset = VSANS_getTopBottomSDDOffset("MT") 	//T/B are 30 cm farther back  //TODO: make all detector parameters global, not hard-wired

	SetDataFolder root:Packages:NIST:VSANS:VCALC	
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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

	SetDataFolder root:Packages:NIST:VSANS:VCALC

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

	SetDeltaQ("","ML")
	SetDeltaQ("","MT")

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
		V_fBinDetector_byRows("ML")
		V_fBinDetector_byRows("MR")
		V_fBinDetector_byRows("MT")
		V_fBinDetector_byRows("MB")
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC

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
	SetDataFolder root:Packages:NIST:VSANS:VCALC	
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

	SetDataFolder root:Packages:NIST:VSANS:VCALC

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

	SetDeltaQ("","B")

	Variable binType	
	ControlInfo/W=VCALC popup_b
	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4
	
	V_BinQxQy_to_1D("","B")

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		V_fBinDetector_byRows("B")
	endif	
	
End

////////////to plot the back panel I(q)
Window Back_IQ_Graph() : Graph

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
	
	SetDataFolder root:
EndMacro

