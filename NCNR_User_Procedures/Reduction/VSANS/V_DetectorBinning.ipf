#pragma rtGlobals=1		// Use modern global access method.


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
	SetDataFolder root:Packages:NIST:VSANS:VCALC

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
	V_SetShadow_TopBottom("","FT")		// TODO: -- be sure the data folder is properly set (within the function...)
	V_SetShadow_TopBottom("","FB")
	
	// do the q-binning for each of the panels to get I(Q)
	Execute "BinAllFrontPanels()"

	// plot the results
	Execute "Front_IQ_Graph()"
	Execute "FrontPanels_AsQ()"
End

// TODO: hard wired for a sphere - change this to allow minimal selections and altering of coefficients
// TODO: add the "fake" 2D simulation to fill the panels which are then later averaged as I(Q)
Function FillPanel_wModelData(det,qTot,type)
	Wave det,qTot
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	// q-values and detector arrays already allocated and calculated
	Duplicate/O det tmpInten,tmpSig,prob_i
		
	Variable imon,trans,thick,sdd,pixSizeX,pixSizeY,sdd_offset

	//imon = V_BeamIntensity()*CountTime
	imon = VCALC_getImon()		//TODO: currently from the panel, not calculated
	trans = 0.8
	thick = 0.1
	
	// need SDD
	// need pixel dimensions
	// nominal sdd in meters, offset in mm, want result in cm !
	sdd = VCALC_getSDD(type)*100	+  VSANS_getTopBottomSDDOffset(type) / 10		// result is sdd in [cm]

	pixSizeX = VCALC_getPixSizeX(type)		// cm
	pixSizeY = VCALC_getPixSizeY(type)
	
	
	//?? pick the function from a popup on the panel? (bypass the analysis panel, or maybe it's better to 
	//  keep the panel to keep people used to using it.)
	String funcStr = VCALC_getModelFunctionStr()
	strswitch(funcStr)
		case "Big Debye":
			tmpInten = V_Debye(10,3000,0.0001,qTot[p][q])
			break
		case "Big Sphere":
			tmpInten = V_SphereForm(1,900,1e-6,0.01,qTot[p][q])	
			break
		case "Debye":
			tmpInten = V_Debye(10,300,0.0001,qTot[p][q])
			break
		case "Sphere":
			tmpInten = V_SphereForm(1,60,1e-6,0.001,qTot[p][q])	
			break
		default:
			tmpInten = V_Debye(10,300,0.1,qTot[p][q])
	endswitch
//	tmpInten = V_SphereForm(1,100,1e-6,1,qTot[p][q])	
	
//	tmpInten = V_Debye(scale,rg,bkg,x)			
//	tmpInten = V_Debye(10,300,0.1,qTot[p][q])


///////////////
//	// calculate the scattering cross section simply to be able to estimate the transmission
//	Variable sig_sas=0
//	
//	// remember that the random deviate is the coherent portion ONLY - the incoherent background is 
//	// subtracted before the calculation.
//	CalculateRandomDeviate(funcUnsmeared,$coefStr,wavelength,"root:Packages:NIST:SAS:ran_dev",sig_sas)
//
//	if(sig_sas > 100)
//		DoAlert 0,"SAS cross section > 100. Estimates of multiple scattering are unreliable. Choosing a model with a well-defined Rg may help"
//	endif		
//
//	// calculate the multiple scattering fraction for display (10/2009)
//	Variable ii,nMax=10,tau
//	mScat=0
//	tau = thick*sig_sas
//	// this sums the normalized scattering P', so the result is the fraction of multiply coherently scattered
//	// neutrons out of those that were scattered
//	for(ii=2;ii<nMax;ii+=1)
//		mScat += tau^(ii)/factorial(ii)
////		print tau^(ii)/factorial(ii)
//	endfor
//	estTrans = exp(-1*thick*sig_sas)		//thickness and sigma both in units of cm
//	mscat *= (estTrans)/(1-estTrans)
//
////	if(mScat > 0.1)		//  Display warning
//
//	Print "Sig_sas = ",sig_sas
////////////////////
	
	prob_i = trans*thick*pixSizeX*pixSizeY/(sdd)^2*tmpInten			//probability of a neutron in q-bin(i) 
		
	tmpInten = (imon)*prob_i		//tmpInten is not the model calculation anymore!!


/// **** can I safely assume a Gaussian error in the count rate??
	tmpSig = sqrt(tmpInten)		// corrected based on John's memo, from 8/9/99

	tmpInten += gnoise(tmpSig)
	tmpInten = (tmpInten[p][q] < 0) ? 0 : tmpInten[p][q]			// MAR 2013 -- is this the right thing to do
	tmpInten = trunc(tmpInten)
		
	
	det = tmpInten

// if I want "absolute" scale -- then I lose the integer nature of the detector (but keep the random)
	det /= trans*thick*pixSizeX*pixSizeY/(sdd)^2*imon
	
	KillWaves/Z tmpInten,tmpSig,prob_i	
	SetDataFolder root:

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

	F_sdd_offset = VSANS_getTopBottomSDDOffset("FT") 	//T/B are 300 mm farther back  //TODO: make all detector parameters global, not hard-wired

	SetDataFolder root:Packages:NIST:VSANS:VCALC	
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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
	SetDataFolder root:Packages:NIST:VSANS:VCALC
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
	Wave det = $("root:Packages:NIST:VSANS:VCALC:"+"det_"+type)

// TODO - these are to be set from globals, not hard-wired
// pixel sizes are in cm for T/B detector
// TODO: the "FT" check is hard wired for FRONT -- get rid of this...

	pixSizeX = VCALC_getPixSizeX(type)
	pixSizeY = VCALC_getPixSizeY(type)

	//TODO -- get this from a global
	xCtr = 64
	nPix = (LR_sep/2/pixSizeX)		// # of pixels Left/right of center that are not obscured by L/R panels
	
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

	SetDataFolder root:Packages:NIST:VSANS:VCALC

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


// For a given detector panel, calculate the q-values
// -work with everything as arrays
// Input needed:
// detector data
// detector type (LRTB?)
// beam center (may be off the detector)
// SDD
// lambda
// 
// pixel dimensions for detector type (global constants)
// - data dimensions read directly from array
//
// --What is calculated:
// array of Q
// array of qx,qy,qz
// array of error already exists
//
//
// -- sdd in meters
// -- lambda in Angstroms
Function V_Detector_2Q(data,qTot,qx,qy,qz,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
	Wave data,qTot,qx,qy,qz
	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
		
	// loop over the array and calculate the values - this is done as a wave assignment
// TODO -- be sure that it's p,q -- or maybe p+1,q+1 as used in WriteQIS.ipf	
	qTot = V_CalcQval(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qx = V_CalcQX(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qy = V_CalcQY(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qz = V_CalcQZ(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	return(0)
End


//////////////////////
// NOTE: The Q calculations are different than what is in GaussUtils in that they take into 
// accout the different x/y pixel sizes and the beam center not being on the detector - 
// off a different edge for each LRTB type
/////////////////////

//function to calculate the overall q-value, given all of the necesary trig inputs
//NOTE: detector locations passed in are pixels = 0.5cm real space on the detector
//and are in detector coordinates (1,128) rather than axis values
//the pixel locations need not be integers, reals are ok inputs
//sdd is in meters
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
Function V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dx,dy,qval,two_theta,dist
		
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	
	two_theta = atan(dist/sdd)

	qval = 4*Pi/lam*sin(two_theta/2)
	
	return qval
End

//calculates just the q-value in the x-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function V_CalcQX(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY

	Variable qx,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)

	qx = qval*cos(two_theta/2)*cos(phi)
	
	return qx
End

//calculates just the q-value in the y-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function V_CalcQY(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dy,qval,dx,phi,qy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qy = qval*cos(two_theta/2)*sin(phi)
	
	return qy
End

//calculates just the z-component of the q-vector, not measured on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// not actually used, but here for completeness if anyone asks
//
Function V_CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dy,qval,dx,phi,qz,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qz = qval*sin(two_theta/2)
	
	return qz
End

//phi is defined from +x axis, proceeding CCW around [0,2Pi]
Threadsafe Function V_FindPhi(vx,vy)
	variable vx,vy
	
	variable phi
	
	phi = atan(vy/vx)		//returns a value from -pi/2 to pi/2
	
	// special cases
	if(vx==0 && vy > 0)
		return(pi/2)
	endif
	if(vx==0 && vy < 0)
		return(3*pi/2)
	endif
	if(vx >= 0 && vy == 0)
		return(0)
	endif
	if(vx < 0 && vy == 0)
		return(pi)
	endif
	
	
	if(vx > 0 && vy > 0)
		return(phi)
	endif
	if(vx < 0 && vy > 0)
		return(phi + pi)
	endif
	if(vx < 0 && vy < 0)
		return(phi + pi)
	endif
	if( vx > 0 && vy < 0)
		return(phi + 2*pi)
	endif
	
	return(phi)
end

Function V_SphereForm(scale,radius,delrho,bkg,x)				
	Variable scale,radius,delrho,bkg
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (A)
	//[2] delrho (A-2)
	//[3] background (cm-1)
	
//	Variable scale,radius,delrho,bkg				
//	scale = w[0]
//	radius = w[1]
//	delrho = w[2]
//	bkg = w[3]
	
	
	// calculates scale * f^2/Vol where f=Vol*3*delrho*((sin(qr)-qrcos(qr))/qr^3
	// and is rescaled to give [=] cm^-1
	
	Variable bes,f,vol,f2
	//
	//handle q==0 separately
	If(x==0)
		f = 4/3*pi*radius^3*delrho*delrho*scale*1e8 + bkg
		return(f)
	Endif
	
//	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3
	
	bes = 3*sqrt(pi/(2*x*radius))*BesselJ(1.5,x*radius)/(x*radius)
	
	vol = 4*pi/3*radius^3
	f = vol*bes*delrho		// [=] A
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8		// [=] 1/cm
	
	return (scale*f2+bkg)	// Scale, then add in the background
	
End

Function V_Debye(scale,rg,bkg,x)
	Variable scale,rg,bkg
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of gyration [A]
	//[2] background	[cm-1]
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add in the background
	return (Pq+bkg)
End









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

	SetDeltaQ("","FL")
	SetDeltaQ("","FT")

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
		V_fBinDetector_byRows("FL")
		V_fBinDetector_byRows("FR")
		V_fBinDetector_byRows("FT")
		V_fBinDetector_byRows("FB")
	endif
		
End


//TODO -- folderStr is ignored in this function
Function SetDeltaQ(folderStr,type)
	String folderStr,type
	
	WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "det_"+type)		// 2D detector data
	
	Variable xDim,yDim,delQ
	
	xDim=DimSize(inten,0)
	yDim=DimSize(inten,1)
	
	if(xDim<yDim)
		WAVE qx = $("root:Packages:NIST:VSANS:VCALC:" + "qx_"+type)
		delQ = abs(qx[0][0] - qx[1][0])/2
	else
		WAVE qy = $("root:Packages:NIST:VSANS:VCALC:" + "qy_"+type)
		delQ = abs(qy[0][1] - qy[0][0])/2
	endif
	
	// set the global
	Variable/G $("root:Packages:NIST:VSANS:VCALC:" + "delQ_"+type) = delQ
//	Print "SET delQ = ",delQ," for ",type
	
	return(0)
end


//TODO -- need a switch here to dispatch to the averaging type
Proc V_BinQxQy_to_1D(folderStr,type)
	String folderStr
	String type
//	Prompt folderStr,"Pick the data folder containing 2D data",popup,getAList(4)
//	Prompt type,"detector identifier"


	V_fDoBinning_QxQy2D("", type)


/// this is for a tall, narrow slit mode	
//	V_fBinDetector_byRows(type)
	
End

Proc V_Graph_1D_detType(folderStr,type)
	String folderStr,type
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	Display $("iBin_qxqy"+"_"+type) vs $("qBin_qxqy"+"_"+type)
	ModifyGraph mirror=2,grid=1,log=1
	ModifyGraph mode=4,marker=19,msize=2
//	ErrorBars/T=0 iBin_qxqy Y,wave=(eBin2D_qxqy,eBin2D_qxqy)		// for simulations, I don't have 2D uncertainty
	ErrorBars/T=0 $("iBin_qxqy"+"_"+type) Y,wave=($("eBin_qxqy"+"_"+type),$("eBin_qxqy"+"_"+type))
	legend
	
	SetDataFolder root:

End


// see the equivalent function in PlotUtils2D_v40.ipf
//
//Function fDoBinning_QxQy2D(inten,qx,qy,qz)
//
// this has been modeified to accept different detector panels and to take arrays
// -- type = FL or FR or...other panel identifiers
//
// TODO "iErr" is all messed up since it doesn't really apply here for data that is not 2D simulation
//
//
Function V_fDoBinning_QxQy2D(folderStr,type)
	String folderStr,type

	// TODO: folderStr is ignored here
	folderStr = ""
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj
	Variable qVal,nq,var,avesq,aveisq
	Variable binIndex,val
	
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
// now switch on the type to determine which waves to declare and create
// since there may be more than one panel to step through. There may be two, there may be four
//

	strswitch(type)	// string switch
		case "FL":		// execute if case matches expression
		case "FR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_FL")
			WAVE inten = $("det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+type)			// 2D q-values
			nSets = 1
			break	
								
		case "FT":		
		case "FB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_FT")
			WAVE inten = $("det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+type)			// 2D q-values
			nSets = 1
			break
			
		case "ML":		
		case "MR":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_ML")
			WAVE inten = $("det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+type)			// 2D q-values
			nSets = 1
			break	
					
		case "MT":		
		case "MB":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_MT")
			WAVE inten = $("det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+type)			// 2D q-values
			nSets = 1
			break	
					
		case "B":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_B")
			WAVE inten = $("det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+type)			// 2D q-values
			nSets = 1
			break	
			
		case "FLR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_FL")
			WAVE inten = $("det_"+"FL")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"FL")			// 2D q-values
			WAVE inten2 = $("det_"+"FR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"FR")			// 2D q-values
			nSets = 2
			break			
		
		case "FTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_FT")
			WAVE inten = $("det_"+"FT")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"FT")			// 2D q-values
			WAVE inten2 = $("det_"+"FB")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"FB")			// 2D q-values
			nSets = 2
			break		
		
		case "FLRTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_FL")
			WAVE inten = $("det_"+"FL")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"FL")			// 2D q-values
			WAVE inten2 = $("det_"+"FR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"FR")			// 2D q-values
			WAVE inten3 = $("det_"+"FT")		// 2D detector data
			WAVE/Z iErr3 = $("iErr_"+"FT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal3 = $("qTot_"+"FT")			// 2D q-values
			WAVE inten4 = $("det_"+"FB")		// 2D detector data
			WAVE/Z iErr4 = $("iErr_"+"FB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal4 = $("qTot_"+"FB")			// 2D q-values
			nSets = 4
			break		
			

		case "MLR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_ML")
			WAVE inten = $("det_"+"ML")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"ML")			// 2D q-values
			WAVE inten2 = $("det_"+"MR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"MR")			// 2D q-values
			nSets = 2
			break			
		
		case "MTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_MT")
			WAVE inten = $("det_"+"MT")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"MT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"MT")			// 2D q-values
			WAVE inten2 = $("det_"+"MB")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"MB")			// 2D q-values
			nSets = 2
			break				
		
		case "MLRTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "delQ_ML")
			WAVE inten = $("det_"+"ML")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("qTot_"+"ML")			// 2D q-values
			WAVE inten2 = $("det_"+"MR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("qTot_"+"MR")			// 2D q-values
			WAVE inten3 = $("det_"+"MT")		// 2D detector data
			WAVE/Z iErr3 = $("iErr_"+"MT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal3 = $("qTot_"+"MT")			// 2D q-values
			WAVE inten4 = $("det_"+"MB")		// 2D detector data
			WAVE/Z iErr4 = $("iErr_"+"MB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal4 = $("qTot_"+"MB")			// 2D q-values
			nSets = 4
			break									
					
		default:
			nSets = 0							// optional default expression executed
			Print "ERROR   ---- type is not recognized "
	endswitch

//	Print "delQ = ",delQ," for ",type

	if(nSets == 0)
		return(0)
	endif


//TODO: properly define the errors here - I'll have this if I do the simulation
	if(WaveExists(iErr)==0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// TODO -- here I'm just using some fictional value
	endif

	nq = 600

	// note that the back panel of 320x320 (1mm res) results in 447 data points!
	// - so I upped nq to 600
	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"qBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"nBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin2_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin2D_qxqy"+"_"+type)
	
	Wave iBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin_qxqy_"+type)
	Wave qBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"qBin_qxqy"+"_"+type)
	Wave nBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"nBin_qxqy"+"_"+type)
	Wave iBin2_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin2_qxqy"+"_"+type)
	Wave eBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin_qxqy"+"_"+type)
	Wave eBin2D_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin2D_qxqy"+"_"+type)
	
	
//	delQ = abs(sqrt(qx[2]^2+qy[2]^2+qz[2]^2) - sqrt(qx[1]^2+qy[1]^2+qz[1]^2))		//use bins of 1 pixel width 
// TODO: not sure if I want to so dQ in x or y direction...
	// the short dimension is the 8mm tubes, use this direction as dQ?
	// but don't use the corner of the detector, since dQ will be very different on T/B or L/R due to the location of [0,0]
	// WRT the beam center. use qx or qy directly. Still not happy with this way...


	qBin_qxqy[] =  p*delQ	
	SetScale/P x,0,delQ,"",qBin_qxqy		//allows easy binning

	iBin_qxqy = 0
	iBin2_qxqy = 0
	eBin_qxqy = 0
	eBin2D_qxqy = 0
	nBin_qxqy = 0	//number of intensities added to each bin

// now there are situations of:
// 1 panel
// 2 panels
// 4 panels
//
// this needs to be a double loop now...

// use set 1 (no number) only
	if(nSets >= 1)
		xDim=DimSize(inten,0)
		yDim=DimSize(inten,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif

// add in set 2 (set 1 already done)
	if(nSets >= 2)
		xDim=DimSize(inten2,0)
		yDim=DimSize(inten2,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal2[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten2[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif

// add in set 3 and 4 (set 1 and 2already done)
	if(nSets == 4)
		xDim=DimSize(inten3,0)
		yDim=DimSize(inten3,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal3[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten3[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
		
		xDim=DimSize(inten4,0)
		yDim=DimSize(inten4,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal4[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten4[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif


// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf
	for(ii=0;ii<nq;ii+=1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii] = 0
			eBin_qxqy[ii] = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				eBin_qxqy[ii] = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq = iBin_qxqy[ii]^2
				aveisq = iBin2_qxqy[ii]/nBin_qxqy[ii]
				var = aveisq-avesq
				if(var<=0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var/(nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor
	
	eBin2D_qxqy = sqrt(eBin2D_qxqy)		// as equation (3) of John's memo
	
	// find the last non-zero point, working backwards
	val=nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)
	
//	print val, nBin_qxqy[val]
	DeletePoints val, nq-val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	if(val == 0)
		// all the points were deleted
		return(0)
	endif
	
	
	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)	
	DeletePoints 0, val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy)-1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy
		endif
		val -= 1
	while(val>0)
	
	SetDataFolder root:
	
	return(0)
End

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







//////NOTE///
//// some chunks of the code here have been trimmed out for fun
//Function V_CircularAverageTo1D(type)
//	String type
//		
//////// get information about the detector (in type folder) that is needed for reduction
//// pixel dimensions
//// beam center
//// distances
//// wavelength
//// wavelength spread
////
//
//	String destPath = "root:"
//
////	NVAR pixelsX = root:myGlobals:gNPixelsX
////	NVAR pixelsY = root:myGlobals:gNPixelsY
//	
////	pixelsX = 48
////	pixelsY = 250
//	
//	// this is for non-linear corrections not applicable?
////	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
////	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
//	
//	// beam center, in pixels
//	x0 = 60		//reals[16]
//	y0 = 125		//reals[17]
////	//detector calibration constants
////	sx = reals[10]		//mm/pixel (x)
////	sx3 = reals[11]		//nonlinear coeff
////	sy = reals[13]		//mm/pixel (y)
////	sy3 = reals[14]		//nonlinear coeff
//	
////	dtsize = 10*reals[20]		//det size in mm
//	dtdist = 1000		//1000*reals[18]		// det distance in mm
//
//
/////// decide how the binning width is to be determined
//	
////	NVAR binWidth=root:Packages:NIST:gBinWidth
//	
//	dr = 1		//binWidth		// ***********annulus width set by user, default is one***********
//	ddr = 4		//dr*sx		//step size, in mm (this value should be passed to the resolution calculation, not dr 18NOV03)
//		
//	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,dxbm,dybm,ii
//	Variable phi_rad,dphi_rad,phi_x,phi_y
//	Variable forward,mirror
//	
////// do I need to pick sides?? probably, for consistency, but confusing nomenclature now
////	String side = StringByKey("SIDE",keyListStr,"=",";")
//
///////// keep the sector calculations, I'll want to do this...
////// 	
////	if(!isCircular)		//must be sector avg (rectangular not sent to this function)
////		//convert from degrees to radians
////		phi_rad = (Pi/180)*NumberByKey("PHI",keyListStr,"=",";")
////		dphi_rad = (Pi/180)*NumberByKey("DPHI",keyListStr,"=",";")
////		//create cartesian values for unit vector in phi direction
////		phi_x = cos(phi_rad)
////		phi_y = sin(phi_rad)
////	Endif
//	
//	/// data wave is data in the current folder which was set at the top of the function
////	WAVE data=$(destPath + ":data")
//	Make/O/N=(pixelsX,pixelsY)  $(destPath + ":data")
//	Wave data = $(destPath + ":data")
//	data = 1
//
//	//Check for the existence of the mask, if not, make one (local to this folder) that is null
//	
//	if(WaveExists($"root:Packages:NIST:MSK:data") == 0)
//		Print "There is no mask file loaded (WaveExists)- the data is not masked"
//		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
//		Wave mask = $(destPath + ":mask")
//		mask = 0
//	else
//		Wave mask=$"root:Packages:NIST:MSK:data"
//	Endif
//	
//	//
//	//pixels within rcentr of beam center are broken into 9 parts (units of mm)
//	rcentr = 100		//original
////	rcentr = 0
//	// values for error if unable to estimate value
//	//large_num = 1e10
//	large_num = 1		//1e10 value (typically sig of last data point) plots poorly, arb set to 1
//	small_num = 1e-10
//	
//	// output wave are expected to exist (?) initialized to zero, what length?
//	// 200 points on VAX --- use 300 here, or more if SAXS data is used with 1024x1024 detector (1000 pts seems good)
//	Variable defWavePts=500
//	Make/O/N=(defWavePts) $(destPath + ":qval"),$(destPath + ":aveint")
//	Make/O/N=(defWavePts) $(destPath + ":ncells"),$(destPath + ":dsq"),$(destPath + ":sigave")
//	Make/O/N=(defWavePts) $(destPath + ":SigmaQ"),$(destPath + ":fSubS"),$(destPath + ":QBar")
//
//	WAVE qval = $(destPath + ":qval")
//	WAVE aveint = $(destPath + ":aveint")
//	WAVE ncells = $(destPath + ":ncells")
//	WAVE dsq = $(destPath + ":dsq")
//	WAVE sigave = $(destPath + ":sigave")
//	WAVE qbar = $(destPath + ":QBar")
//	WAVE sigmaq = $(destPath + ":SigmaQ")
//	WAVE fsubs = $(destPath + ":fSubS")
//	
//	qval = 0
//	aveint = 0
//	ncells = 0
//	dsq = 0
//	sigave = 0
//	qbar = 0
//	sigmaq = 0
//	fsubs = 0
//
//	dtdis2 = dtdist^2
//	nq = 1
//	xoffst=0
//	//distance of beam center from detector center
//////	// the linearity corrections for the 2D Ordela detectors are applied from the center of the detector,
//	// so figure where that is, relative to the beam center. 
////	dxbm = V_FX(x0,sx3,xcenter,sx)
////	dybm = V_FY(y0,sy3,ycenter,sy)
//		
//	//BEGIN AVERAGE **********
//	Variable xi,dxi,dx,jj,data_pixel,yj,dyj,dy,mask_val=0.1
//	Variable dr2,nd,fd,nd2,ll,kk,dxx,dyy,ir,dphi_p
//	
//	// IGOR arrays are indexed from [0][0], FORTAN from (1,1) (and the detector too)
//	// loop index corresponds to FORTRAN (old code) 
//	// and the IGOR array indices must be adjusted (-1) to the correct address
//	
//	/////
//	//// need to add in here a step that calculates the q-values, and bins based on q-value
//	//// since the 4 panels are not in the same plane (but relatively close)
//	//
//	//    if we're always using pairs in the same plane, then binning in r is OK
//	////
//	
//	ii=1
//	do
//		xi = ii
//		dxi = V_FX(xi,sx3,xcenter,sx)
//		dx = dxi-dxbm		//dx and dy are in mm
//		
//		jj = 1
//		do
//			data_pixel = data[ii-1][jj-1]		//assign to local variable
//			yj = jj
//			dyj = V_FY(yj,sy3,ycenter,sy)
//			dy = dyj - dybm
//			if(!(mask[ii-1][jj-1]))			//masked pixels = 1, skip if masked (this way works...)
//				dr2 = (dx^2 + dy^2)^(0.5)		//distance from beam center NOTE dr2 used here - dr used above
//				if(dr2>rcentr)		//keep pixel whole
//					nd = 1
//					fd = 1
//				else				//break pixel into 9 equal parts
//					nd = 3
//					fd = 2
//				endif
//				nd2 = nd^2
//				ll = 1		//"el-el" loop index
//				do
//					dxx = dx + (ll - fd)*sx/3
//					kk = 1
//					do
//						dyy = dy + (kk - fd)*sy/3
//						if(isCircular)
//							//circular average, use all pixels
//							//(increment) 
//							nq = V_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
////						else
////							//a sector average - determine azimuthal angle
////							dphi_p = V_dphi_pixel(dxx,dyy,phi_x,phi_y)
////							if(dphi_p < dphi_rad)
////								forward = 1			//within forward sector
////							else
////								forward = 0
////							Endif
////							if((Pi - dphi_p) < dphi_rad)
////								mirror = 1		//within mirror sector
////							else
////								mirror = 0
////							Endif
////							//check if pixel lies within allowed sector(s)
////							if(cmpstr(side,"both")==0)		//both sectors
////								if ( mirror || forward)
////									//increment
////									nq = V_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
////								Endif
////							else
////								if(cmpstr(side,"right")==0)		//forward sector only
////									if(forward)
////										//increment
////										nq = V_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
////									Endif
////								else			//mirror sector only
////									if(mirror)
////										//increment
////										nq = V_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
////									Endif
////								Endif
////							Endif		//allowable sectors
//						Endif	//circular or sector check
//						kk+=1
//					while(kk<=nd)
//					ll += 1
//				while(ll<=nd)
//			Endif		//masked pixel check
//			jj += 1
//		while (jj<=pixelsY)
//		ii += 1
//	while(ii<=pixelsX)		//end of the averaging
//		
//	//compute q-values and errors
//	Variable ntotal,rr,theta,avesq,aveisq,var
//	
//	lambda = reals[26]
//	ntotal = 0
//	kk = 1
//	do
//		rr = (2*kk-1)*ddr/2
//		theta = 0.5*atan(rr/dtdist)
//		qval[kk-1] = (4*Pi/lambda)*sin(theta)
//		if(ncells[kk-1] == 0)
//			//no pixels in annuli, data unknown
//			aveint[kk-1] = 0
//			sigave[kk-1] = large_num
//		else
//			if(ncells[kk-1] <= 1)
//				//need more than one pixel to determine error
//				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
//				sigave[kk-1] = large_num
//			else
//				//assume that the intensity in each pixel in annuli is normally
//				// distributed about mean...
//				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
//				avesq = aveint[kk-1]^2
//				aveisq = dsq[kk-1]/ncells[kk-1]
//				var = aveisq-avesq
//				if(var<=0)
//					sigave[kk-1] = small_num
//				else
//					sigave[kk-1] = sqrt(var/(ncells[kk-1] - 1))
//				endif
//			endif
//		endif
//		ntotal += ncells[kk-1]
//		kk+=1
//	while(kk<=nq)
//	
//	//Print "NQ = ",nq
//	// data waves were defined as 300 points (=defWavePts), but now have less than that (nq) points
//	// use DeletePoints to remove junk from end of waves
//	//WaveStats would be a more foolproof implementation, to get the # points in the wave
//	Variable startElement,numElements
//	startElement = nq
//	numElements = defWavePts - startElement
//	DeletePoints startElement,numElements, qval,aveint,ncells,dsq,sigave
//	
//	//////////////end of VAX sector_ave()
//		
//	//angle dependent transmission correction 
//	Variable uval,arg,cos_th
//	lambda = reals[26]
//	trans = reals[4]
//
////
////  The transmission correction is now done at the ADD step, in DetCorr()
////	
////	////this section is the trans_correct() VAX routine
////	if(trans<0.1)
////		Print "***transmission is less than 0.1*** and is a significant correction"
////	endif
////	if(trans==0)
////		Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
////		trans = 1
////	endif
////	//optical thickness
////	uval = -ln(trans)		//use natural logarithm
////	//apply correction to aveint[]
////	//index from zero here, since only working with IGOR waves
////	ii=0
////	do
////		theta = 2*asin(lambda*qval[ii]/(4*pi))
////		cos_th = cos(theta)
////		arg = (1-cos_th)/cos_th
////		if((uval<0.01) || (cos_th>0.99))		//OR
////			//small arg, approx correction
////			aveint[ii] /= 1-0.5*uval*arg
////		else
////			//large arg, exact correction
////			aveint[ii] /= (1-exp(-uval*arg))/(uval*arg)
////		endif
////		ii+=1
////	while(ii<nq)
////	//end of transmission/pathlength correction
//
//// ***************************************************************
////
//// Do the extra 3 columns of resolution calculations starting here.
////
//// ***************************************************************
//
//	Variable L2 = reals[18]
//	Variable BS = reals[21]
//	Variable S1 = reals[23]
//	Variable S2 = reals[24]
//	Variable L1 = reals[25]
//	lambda = reals[26]
//	Variable lambdaWidth = reals[27]
//	String detStr=textRead[9]
//	
//	Variable usingLenses = reals[28]		//new 2007
//
//	//Two parameters DDET and APOFF are instrument dependent.  Determine
//	//these from the instrument name in the header.
//	//From conversation with JB on 01.06.99 these are the current
//	//good values
//
//	Variable DDet
//	NVAR apOff = root:myGlobals:apOff		//in cm
//	
////	DDet = DetectorPixelResolution(fileStr,detStr)		//needs detector type and beamline
//	//note that reading the detector pixel size from the header ASSUMES SQUARE PIXELS! - Jan2008
//	DDet = reals[10]/10			// header value (X) is in mm, want cm here
//	
//	
//	//Width of annulus used for the average is gotten from the
//	//input dialog before.  This also must be passed to the resolution
//	//calculator. Currently the default is dr=1 so just keeping that.
//
//	//Go from 0 to nq doing the calc for all three values at
//	//every Q value
//
//	ii=0
//
//	Variable ret1,ret2,ret3
//	do
//	// commented out for compiler
////		getResolution(qval[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,usingLenses,ret1,ret2,ret3)
//		sigmaq[ii] = ret1	
//		qbar[ii] = ret2	
//		fsubs[ii] = ret3	
//		ii+=1
//	while(ii<nq)
//	DeletePoints startElement,numElements, sigmaq, qbar, fsubs
//
//// End of resolution calculations
//// ***************************************************************
//	
//	//Plot the data in the Plot_1d window
////	Avg_1D_Graph(aveint,qval,sigave)		//commented out for compiler
//
//	//get rid of the default mask, if one was created (it is in the current folder)
//	//don't just kill "mask" since it might be pointing to the one in the MSK folder
//	Killwaves/Z $(destPath+":mask")
//	
//	//return to root folder (redundant)
//	SetDataFolder root:
//	
//	Return 0
//End

////returns nq, new number of q-values
////arrays aveint,dsq,ncells are also changed by this function
////
//Function V_IncrementPixel(dataPixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
//	Variable dataPixel,ddr,dxx,dyy
//	Wave aveint,dsq,ncells
//	Variable nq,nd2
//	
//	Variable ir
//	
//	ir = trunc(sqrt(dxx*dxx+dyy*dyy)/ddr)+1
//	if (ir>nq)
//		nq = ir		//resets maximum number of q-values
//	endif
//	aveint[ir-1] += dataPixel/nd2		//ir-1 must be used, since ir is physical
//	dsq[ir-1] += dataPixel*dataPixel/nd2
//	ncells[ir-1] += 1/nd2
//	
//	Return nq
//End
//
////function determines azimuthal angle dphi that a vector connecting
////center of detector to pixel makes with respect to vector
////at chosen azimuthal angle phi -> [cos(phi),sin(phi)] = [phi_x,phi_y]
////dphi is always positive, varying from 0 to Pi
////
//Function V_dphi_pixel(dxx,dyy,phi_x,phi_y)
//	Variable dxx,dyy,phi_x,phi_y
//	
//	Variable val,rr,dot_prod
//	
//	rr = sqrt(dxx^2 + dyy^2)
//	dot_prod = (dxx*phi_x + dyy*phi_y)/rr
//	//? correct for roundoff error? - is this necessary in IGOR, w/ double precision?
//	if(dot_prod > 1)
//		dot_prod =1
//	Endif
//	if(dot_prod < -1)
//		dot_prod = -1
//	Endif
//	
//	val = acos(dot_prod)
//	
//	return val
//
//End
//
////calculates the x distance from the center of the detector, w/nonlinear corrections
////
//Function V_FX(xx,sx3,xcenter,sx)		
//	Variable xx,sx3,xcenter,sx
//	
//	Variable retval
//	
//	retval = sx3*tan((xx-xcenter)*sx/sx3)
//	Return retval
//End
//
////calculates the y distance from the center of the detector, w/nonlinear corrections
////
//Function V_FY(yy,sy3,ycenter,sy)		
//	Variable yy,sy3,ycenter,sy
//	
//	Variable retval
//	
//	retval = sy3*tan((yy-ycenter)*sy/sy3)
//	Return retval
//End