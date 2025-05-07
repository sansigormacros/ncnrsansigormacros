#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

/////////////////////////
//
// Utility functions to:
//		calculate Q, Qx, Qy, Qz
//		fill the detector panels with simulated data (the model functions are here)
//		bin the 2D detector to 1D I(Q) based on Q and deltaQ (bin width)
//
/////////////////////////

// TODO:
// -- hard wired values for transmission and thickness
//
// x- hard wired for a sphere - change this to allow minimal selections and altering of coefficients
// x- add the "fake" 2D simulation to fill the panels which are then later averaged as I(Q)
//
// NOTE - this is a VCALC only routine, so it's not been made completely generic
//
Function FillPanel_wModelData(WAVE det, WAVE qTot, string type)

	//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

	// q-values and detector arrays already allocated and calculated
	Duplicate/O det, tmpInten, tmpSig, prob_i

	variable imon, trans, thick, sdd, pixSizeX, pixSizeY, sdd_offset

	//imon = VC_BeamIntensity()*CountTime
	imon  = VCALC_getImon() //TODO: currently from the panel, not calculated
	trans = 0.8
	thick = 0.1

	// need SDD
	// need pixel dimensions
	// nominal sdd in cm, offset in cm, want result in cm !

	sdd  = VC_getSDD(type) // setback is NOT included  VCALC_getTopBottomSDDSetback(type)		// result is sdd in [cm]
	sdd += VCALC_getTopBottomSDDSetback(type)

	pixSizeX = VCALC_getPixSizeX(type) // cm
	pixSizeY = VCALC_getPixSizeY(type)

	//?? pick the function from a popup on the panel? (bypass the analysis panel, or maybe it's better to
	//  keep the panel to keep people used to using it.)
	// peak @ 0.1 ~ AgBeh
	//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 100.0, 0.1,3,0.1}
	//
	// peak @ 0.015 in middle of middle detector, maybe not "real" vycor, but that is to be resolved
	//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 500.0, 0.015,3,0.1}
	//
	//
	variable addEmpBgd = 0

	// TODOHIGHRES
	// this is a slow step - try to figure out how to multithread this efficiently. simply adding the
	//  keyword has little effect. maybe only do this for "B", maybe rewrite the calculation to not use pq indexing
	//
	string funcStr = VCALC_getModelFunctionStr()
	strswitch(funcStr)
		case "Big Debye":
			tmpInten = VC_Debye(100, 3000, 0.0001, qTot[p][q])
			break
		case "Big Sphere":
			tmpInten = VC_SphereForm(1, 2000, 1e-6, 0.01, qTot[p][q])
			break
		case "Debye":
			MultiThread tmpInten = VC_Debye(10, 300, 0.0001, qTot[p][q])
			break
		case "Sphere":
			tmpInten = VC_SphereForm(1, 60, 1e-6, 0.001, qTot[p][q])
			break
		case "AgBeh":
			tmpInten = VC_BroadPeak(1e-11, 3, 20, 100.0, 0.1, 3, 0.1, qTot[p][q])
			break
		case "Vycor":
			tmpInten = VC_BroadPeak(1e-9, 3, 20, 500.0, 0.015, 3, 0.1, qTot[p][q])
			break
		case "Empty Cell":
			tmpInten = VC_EC_Empirical(2.2e-12, 3.346, 0.0065, 9.0, 0.016, qTot[p][q])
			break
		case "Blocked Beam":
			tmpInten = VC_BlockedBeam(0.01, qTot[p][q])
			break
		case "Debye +":
			tmpInten  = VC_Debye(10, 300, 0.0001, qTot[p][q])
			addEmpBgd = 1
			break
		case "AgBeh +":
			tmpInten  = VC_BroadPeak(1e-11, 3, 20, 100.0, 0.1, 3, 0.1, qTot[p][q])
			addEmpBgd = 1
			break
		case "Empty Cell +":
			tmpInten  = VC_EC_Empirical(2.2e-12, 3.346, 0.0065, 9.0, 0.016, qTot[p][q])
			tmpInten += VC_BlockedBeam(0.01, qTot[p][q])
			break
		default: // FIXME(CodeStyleFallthroughCaseRequireComment)
			tmpInten = VC_Debye(10, 300, 0.1, qTot[p][q])
	endswitch

	if(addEmpBgd == 1)
		tmpInten += VC_EC_Empirical(2.2e-12, 3.346, 0.0065, 9.0, 0.016, qTot[p][q])
		tmpInten += VC_BlockedBeam(0.01, qTot[p][q])
	endif

	// x- this is faked to get around the singularity at the center of the back detector
	//
	//
	if(cmpstr(type, "B") == 0)
		variable nx, ny, px, py
		nx = VCALC_get_nPix_X(type)
		ny = VCALC_get_nPix_Y(type)
		px = trunc(nx / 2)
		py = trunc(ny / 2)

		tmpInten[px][py] = (tmpInten[px][py + 1] + tmpInten[px][py - 1]) / 2
	endif

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

	MultiThread prob_i = trans * thick * pixSizeX * pixSizeY / (sdd)^2 * tmpInten //probability of a neutron in q-bin(i)

	tmpInten = (imon) * prob_i //tmpInten is not the model calculation anymore!!

	/// **** can I safely assume a Gaussian error in the count rate??
	MultiThread tmpSig = sqrt(tmpInten) // corrected based on John's memo, from 8/9/99

	MultiThread tmpInten += gnoise(tmpSig)
	MultiThread tmpInten = (tmpInten[p][q] < 0) ? 0 : tmpInten[p][q] // MAR 2013 -- is this the right thing to do
	tmpInten = trunc(tmpInten)

	det = tmpInten

	// if I want "absolute" scale -- then I lose the integer nature of the detector (but keep the random)
	det /= trans * thick * pixSizeX * pixSizeY / (sdd)^2 * imon

	KillWaves/Z tmpInten, tmpSig, prob_i
	SetDataFolder root:

	return (0)
End

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
// -- sdd in cm
// -- lambda in Angstroms
Function VC_Detector_2Q(WAVE data, WAVE qTot, WAVE qx, WAVE qy, WAVE qz, variable xCtr, variable yCtr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY)

	// loop over the array and calculate the values - this is done as a wave assignment
	// TODO -- be sure that it's p,q -- or maybe p+1,q+1 as used in WriteQIS.ipf
	MultiThread qTot = VC_CalcQval(p, q, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)
	MultiThread qx = VC_CalcQX(p, q, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)
	MultiThread qy = VC_CalcQY(p, q, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)
	MultiThread qz = VC_CalcQZ(p, q, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)

	return (0)
End

// for testing, a version that will calculate the q-arrays for VCALC based on whatever nonlinear coefficients
// exist in the RAW data folder
//
// reverts to the "regular" linear detector if waves not found or a flag is set
//
// need to call the VSANS V_CalcQval routines (these use the real-space distance, not pixel dims)
//
// ***** everything passed in is [cm], except for wavelength [A]
//
// ****  TODO :: calibration constants are still in [mm]
//
//
// TODO:
// -- tube width is hard-wired in
//
//
Function VC_Detector_2Q_NonLin(WAVE data, WAVE qTot, WAVE qx, WAVE qy, WAVE qz, variable xCtr, variable yCtr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY, string detStr)

	string destPath = "root:Packages:NIST:VSANS:VCALC"

	// be sure that the real distance waves exist
	// TODO -- this may not be the best location?

	variable tube_width = 8.4 // TODO: UNITS!!! Hard-wired value in [mm]

	string orientation
	variable dimX, dimY
	dimX = DimSize(data, 0)
	dimY = DimSize(data, 1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif

	WAVE/Z data_realDistX   = $(destPath + ":entry:instrument:detector_" + detStr + ":data_realDistX")
	WAVE/Z data_realDistY   = $(destPath + ":entry:instrument:detector_" + detStr + ":data_realDistY")
	NVAR   gUseNonLinearDet = root:Packages:NIST:VSANS:VCALC:gUseNonLinearDet

	if(kBCTR_CM && cmpstr(detStr, "B") != 0)
		if(gUseNonLinearDet && WaveExists(data_realDistX) && WaveExists(data_realDistY))
			// beam ctr is in cm already

			// calculate all of the q-values
			qTot = V_CalcQval(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qx   = V_CalcQX(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qy   = V_CalcQY(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qz   = V_CalcQZ(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)

			//		Print "det, x_mm, y_mm ",detStr,num2str(newX),num2str(newY)
			//		Print "det, x_pix, y_pix ",detStr,num2str(xCtr),num2str(yCtr)
		else
			// do the q-calculation using linear detector
			//VC_Detector_2Q(data,qTot,qx,qy,qz,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
			qTot = V_CalcQval(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qx   = V_CalcQX(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qy   = V_CalcQY(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
			qz   = V_CalcQZ(p, q, xCtr, yCtr, sdd, lam, data_realDistX, data_realDistY)
		endif

	else
		// using the old calculation with beam center in pixels
		if(gUseNonLinearDet && WaveExists(data_realDistX) && WaveExists(data_realDistY))
			// convert the beam centers to mm
			//			String orientation
			variable newX, newY
			dimX = DimSize(data_realDistX, 0)
			dimY = DimSize(data_realDistX, 1)
			if(dimX > dimY)
				orientation = "horizontal"
			else
				orientation = "vertical"
			endif

			//
			if(cmpstr(orientation, "vertical") == 0)
				//	this is data dimensioned as (Ntubes,Npix)
				newX = tube_width * xCtr
				newY = data_realDistY[0][yCtr]
			else
				//	this is data (horizontal) dimensioned as (Npix,Ntubes)
				newX = data_realDistX[xCtr][0]
				newY = tube_width * yCtr
			endif

			//if detector "B", different calculation for the centers (not tubes)
			if(cmpstr(detStr, "B") == 0)
				newX = data_realDistX[xCtr][0]
				newY = data_realDistY[0][yCtr]
				//newX = xCtr
				//newY = yCtr
			endif

			// calculate all of the q-values
			qTot = V_CalcQval(p, q, newX, newY, sdd, lam, data_realDistX, data_realDistY)
			qx   = V_CalcQX(p, q, newX, newY, sdd, lam, data_realDistX, data_realDistY)
			qy   = V_CalcQY(p, q, newX, newY, sdd, lam, data_realDistX, data_realDistY)
			qz   = V_CalcQZ(p, q, newX, newY, sdd, lam, data_realDistX, data_realDistY)

			//		Print "det, x_mm, y_mm ",detStr,num2str(newX),num2str(newY)
			//		Print "det, x_pix, y_pix ",detStr,num2str(xCtr),num2str(yCtr)
		else
			// do the q-calculation using linear detector
			VC_Detector_2Q(data, qTot, qx, qy, qz, xCtr, yCtr, sdd, lam, pixSizeX, pixSizeY)
		endif

	endif

	KillWaves/Z tmpCalib, tmpCalibX, tmpCalibY

	return (0)
End

// make the data_realDistX,Y Waves that are needed for the calculation of q
Function VC_MakeRealDistXYWaves(WAVE data, string detStr)

	string destPath = "root:Packages:NIST:VSANS:VCALC"

	// calibration waves do not exist yet, so make some fake ones	'
	// do I count on the orientation as an input, or do I just figure it out on my own?
	string orientation
	variable dimX, dimY
	dimX = DimSize(data, 0)
	dimY = DimSize(data, 1)
	if(dimX > dimY)
		orientation = "horizontal"
	else
		orientation = "vertical"
	endif

	if(cmpstr(orientation, "vertical") == 0)
		Make/O/D/N=(3, 48) tmpCalib
		// for the "tall" L/R banks
		tmpCalib[0][] = -512
		tmpCalib[1][] = 8
		tmpCalib[2][] = 0
	else
		Make/O/D/N=(3, 48) tmpCalib
		// for the "short" T/B banks
		tmpCalib[0][] = -256
		tmpCalib[1][] = 4
		tmpCalib[2][] = 0
	endif
	// override if back panel
	if(cmpstr(detStr, "B") == 0)
		// and for the back detector "B"
		Make/O/D/N=3 tmpCalibX, tmpCalibY
		tmpCalibX[0] = VCALC_getPixSizeX(detStr) // pixel size in [cm]  VCALC_getPixSizeX(detStr) is [cm]
		tmpCalibX[1] = 1
		tmpcalibX[2] = 10000
		tmpCalibY[0] = VCALC_getPixSizeY(detStr) // pixel size in [cm]  VCALC_getPixSizeX(detStr) is [cm]
		tmpCalibY[1] = 1
		tmpcalibY[2] = 10000
	endif

	//	Wave w_calib = V_getDetTube_spatialCalib("VCALC",detStr)
	variable tube_width = 8.4 // TODO: UNITS!!! Hard-wired value in [mm]
	if(cmpstr(detStr, "B") == 0)
		V_NonLinearCorrection_B("VCALC", data, tmpCalibX, tmpCalibY, detStr, destPath)
		// beam center is in pixels, so use the old routine
		V_ConvertBeamCtrPix_to_mmB("VCALC", "B", destPath)
	else
		V_NonLinearCorrection("VCALC", data, tmpCalib, tube_width, detStr, destPath)
	endif

	return (0)
End

//////////////////////
// NOTE: The Q calculations are different than what is in GaussUtils in that they take into
// accout the different x/y pixel sizes and the beam center not being on the detector -
// off a different edge for each LRTB type
/////////////////////

//function to calculate the overall q-value, given all of the necesary trig inputs
//and are in detector coordinates (1,128) rather than axis values
//the pixel locations need not be integers, reals are ok inputs
//sdd is in [cm]
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
//
threadsafe Function VC_CalcQval(variable xaxval, variable yaxval, variable xctr, variable yctr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY)

	variable dx, dy, qval, two_theta, dist

	dx   = (xaxval - xctr) * pixSizeX //delta x in cm
	dy   = (yaxval - yctr) * pixSizeY //delta y in cm
	dist = sqrt(dx^2 + dy^2)

	two_theta = atan(dist / sdd)

	qval = 4 * Pi / lam * sin(two_theta / 2)

	return qval
End

//calculates just the q-value in the x-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//
//sdd is in [cm]
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
threadsafe Function VC_CalcQX(variable xaxval, variable yaxval, variable xctr, variable yctr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY)

	variable qx, qval, phi, dx, dy, dist, two_theta

	qval = VC_CalcQval(xaxval, yaxval, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)

	//	sdd *=100		//convert to cm
	dx  = (xaxval - xctr) * pixSizeX //delta x in cm
	dy  = (yaxval - yctr) * pixSizeY //delta y in cm
	phi = V_FindPhi(dx, dy)

	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist      = sqrt(dx^2 + dy^2)
	two_theta = atan(dist / sdd)

	qx = qval * cos(two_theta / 2) * cos(phi)

	return qx
End

//calculates just the q-value in the y-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//sdd is in [cm]
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
threadsafe Function VC_CalcQY(variable xaxval, variable yaxval, variable xctr, variable yctr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY)

	variable dy, qval, dx, phi, qy, dist, two_theta

	qval = VC_CalcQval(xaxval, yaxval, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)

	//	sdd *=100		//convert to cm
	dx  = (xaxval - xctr) * pixSizeX //delta x in cm
	dy  = (yaxval - yctr) * pixSizeY //delta y in cm
	phi = V_FindPhi(dx, dy)

	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist      = sqrt(dx^2 + dy^2)
	two_theta = atan(dist / sdd)

	qy = qval * cos(two_theta / 2) * sin(phi)

	return qy
End

//calculates just the z-component of the q-vector, not measured on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//sdd is in [cm]
//wavelength is in Angstroms
//
// not actually used, but here for completeness if anyone asks
//
threadsafe Function VC_CalcQZ(variable xaxval, variable yaxval, variable xctr, variable yctr, variable sdd, variable lam, variable pixSizeX, variable pixSizeY)

	variable dy, qval, dx, phi, qz, dist, two_theta

	qval = VC_CalcQval(xaxval, yaxval, xctr, yctr, sdd, lam, pixSizeX, pixSizeY)

	//	sdd *=100		//convert to cm

	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dx        = (xaxval - xctr) * pixSizeX //delta x in cm
	dy        = (yaxval - yctr) * pixSizeY //delta y in cm
	dist      = sqrt(dx^2 + dy^2)
	two_theta = atan(dist / sdd)

	qz = qval * sin(two_theta / 2)

	return qz
End

//phi is defined from +x axis, proceeding CCW around [0,2Pi]
threadsafe Function V_FindPhi(variable vx, variable vy)

	variable phi

	phi = atan(vy / vx) //returns a value from -pi/2 to pi/2

	// special cases
	if(vx == 0 && vy > 0)
		return (pi / 2)
	endif
	if(vx == 0 && vy < 0)
		return (3 * pi / 2)
	endif
	if(vx >= 0 && vy == 0)
		return (0)
	endif
	if(vx < 0 && vy == 0)
		return (pi)
	endif

	if(vx > 0 && vy > 0)
		return (phi)
	endif
	if(vx < 0 && vy > 0)
		return (phi + pi)
	endif
	if(vx < 0 && vy < 0)
		return (phi + pi)
	endif
	if(vx > 0 && vy < 0)
		return (phi + 2 * pi)
	endif

	return (phi)
End

Function VC_SphereForm(variable scale, variable radius, variable delrho, variable bkg, variable x)

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

	variable bes, f, vol, f2
	//
	//handle q==0 separately
	if(x == 0)
		f = 4 / 3 * pi * radius^3 * delrho * delrho * scale * 1e8 + bkg
		return (f)
	endif

	//	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3

	bes = 3 * sqrt(pi / (2 * x * radius)) * BesselJ(1.5, x * radius) / (x * radius)

	vol = 4 * pi / 3 * radius^3
	f   = vol * bes * delrho // [=] A
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8 // [=] 1/cm

	return (scale * f2 + bkg) // Scale, then add in the background

End

threadsafe Function VC_Debye(variable scale, variable rg, variable bkg, variable x)

	// variables are:
	//[0] scale factor
	//[1] radius of gyration [A]
	//[2] background	[cm-1]

	// calculates (scale*debye)+bkg
	variable Pq, qr2

	qr2 = (x * rg)^2
	Pq  = 2 * (exp(-(qr2)) - 1 + qr2) / qr2^2

	//scale
	Pq *= scale
	// then add in the background
	return (Pq + bkg)
End

// a sum of a power law and debye to approximate the scattering from a real empty cell
//
// 	make/O/D coef_ECEmp = {2.2e-8,3.346,0.0065,9.0,0.016}
//
Function VC_EC_Empirical(variable aa, variable mm, variable scale, variable rg, variable bkg, variable x)

	// variables are:
	//[0] = A
	//[1] = power m
	//[2] scale factor
	//[3] radius of gyration [A]
	//[4] background	[cm-1]

	variable Iq

	// calculates (scale*debye)+bkg
	variable Pq, qr2

	//	if(x*Rg < 1e-3)		//added Oct 2008 to avoid numerical errors at low arg values
	//		return(scale+bkg)
	//	endif

	Iq = aa * x^-mm

	qr2 = (x * rg)^2
	Pq  = 2 * (exp(-(qr2)) - 1 + qr2) / qr2^2

	//scale
	Pq *= scale
	// then add the terms up
	return (Iq + Pq + bkg)
End

// blocked beam
//
Function VC_BlockedBeam(variable bkg, variable x)

	return (bkg)
End

//
// a broad peak to simulate silver behenate or vycor
//
// peak @ 0.1 ~ AgBeh
//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 100.0, 0.1,3,0.1}
//
//
// peak @ 0.015 in middle of middle detector, maybe not "real" vycor, but that is to be resolved
//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 500.0, 0.015,3,0.1}
//
//
Function VC_BroadPeak(variable aa, variable nn, variable cc, variable LL, variable Qzero, variable mm, variable bgd, variable x)

	// variables are:
	//[0] Porod term scaling
	//[1] Porod exponent
	//[2] Lorentzian term scaling
	//[3] Lorentzian screening length [A]
	//[4] peak location [1/A]
	//[5] Lorentzian exponent
	//[6] background

	//	local variables
	variable inten, qval
	//	x is the q-value for the calculation
	qval = x
	//	do the calculation and return the function value

	inten = aa / (qval)^nn + cc / (1 + (abs(qval - Qzero) * LL)^mm) + bgd

	return (inten)

End

//
// updated to new folder structure Feb 2016
// folderStr = RAW,SAM, VCALC or other
// detStr is the panel identifer "ML", etc.
//
Function V_SetDeltaQ(string folderStr, string detStr)

	NVAR binWidth = root:Packages:NIST:VSANS:Globals:gBinWidth

	variable isVCALC
	if(cmpstr(folderStr, "VCALC") == 0)
		isVCALC = 1
	endif

	string folderPath = "root:Packages:NIST:VSANS:" + folderStr
	string instPath   = ":entry:instrument:detector_"

	if(isVCALC)
		WAVE inten = $(folderPath + instPath + detStr + ":det_" + detStr) // 2D detector data
	else
		WAVE inten = V_getDetectorDataW(folderStr, detStr)
	endif

	WAVE qx = $(folderPath + instPath + detStr + ":qx_" + detStr)
	WAVE qy = $(folderPath + instPath + detStr + ":qy_" + detStr)

	variable xDim, yDim, delQ

	xDim = DimSize(inten, 0)
	yDim = DimSize(inten, 1)

	if(xDim < yDim)
		delQ = abs(qx[0][0] - qx[1][0]) / 2
	else
		delQ = abs(qy[0][1] - qy[0][0]) / 2
	endif

	// (DONE)_HIGHRES
	// -- this will handle the too-fine resolution of 1x1 binning?
	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning

	if(cmpstr(detStr, "B") == 0 && gHighResBinning == 1)
		delQ = 4 * delQ
		Print "Reset delta Q for binning the back detector to 4x pix = ", delQ
	endif

	// multiply the deltaQ by the binWidth (=multiple of pixels)
	// this defaults to 1.2, and is set in VSANS preferences
	delQ *= binWidth

	// set the global
	variable/G $(folderPath + instPath + detStr + ":gDelQ_" + detStr) = delQ
	//	Print "SET delQ = ",delQ," for ",type

	return (delQ)
End

//TODO -- need a switch here to dispatch to the averaging type
Proc VC_BinQxQy_to_1D(folderStr, type)
	string folderStr
	string type
	//	Prompt folderStr,"Pick the data folder containing 2D data",popup,getAList(4)
	//	Prompt type,"detector identifier"

	VC_fDoBinning_QxQy2D(folderStr, type)

	/// this is for a tall, narrow slit mode
	//	VC_fBinDetector_byRows(folderStr,type)

EndMacro

// folderStr is RAW, VCALC, SAM, etc.
// type is "B", "FL" for single binning, "FLR", or "MLRTB" or similar if multiple panels are combined
//
Proc VC_Graph_1D_detType(folderStr, type)
	string folderStr, type

	SetDataFolder $("root:Packages:NIST:VSANS:" + folderStr)

	Display $("iBin_qxqy" + "_" + type) vs $("qBin_qxqy" + "_" + type)
	ModifyGraph mirror=2, grid=1, log=1
	ModifyGraph mode=4, marker=19, msize=2
	//	ErrorBars/T=0 iBin_qxqy Y,wave=(eBin2D_qxqy,eBin2D_qxqy)		// for simulations, I don't have 2D uncertainty
	ErrorBars/T=0 $("iBin_qxqy" + "_" + type), Y, wave=($("eBin_qxqy" + "_" + type), $("eBin_qxqy" + "_" + type))
	legend

	SetDataFolder root:

EndMacro

//////////
//
//		Function that bins a 2D detctor panel into I(q) based on the q-value of the pixel
//		- each pixel QxQyQz has been calculated beforehand
//		- if multiple panels are selected to be combined, it is done here during the binning
//		- the setting of deltaQ step is still a little suspect in that it can be the
//      cause of "sawtooth" in the I(q) - if the step is too fine. There is now a preference
//      set so that the deltaQ is by default 1.2 * the minumum q from the first tube.
//
//
// see the equivalent function in PlotUtils2D_v40.ipf
//
//Function fDoBinning_QxQy2D(inten,qx,qy,qz)
//
// this has been modified to accept different detector panels and to take arrays
// -- type = FL or FR or...other panel identifiers
//
// TODO "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
//
// updated Feb2016 to take new folder structure
// TODO
// -- VERIFY
// -- figure out what the best location is to put the averaged data? currently @ top level of WORK folder
//    but this is a lousy choice.
// x- binning is now Mask-aware. If mask is not present, all data is used. If data is from VCALC, all data is used
// x- Where do I put the solid angle correction? In here as a weight for each point, or later on as
//    a blanket correction (matrix multiply) for an entire panel? (Solid Angle correction is done in the
//    step where data is added to a WORK file (see Raw_to_Work())
//
//
// TODO:
// -- some of the input parameters for the resolution calcuation are either assumed (apOff) or are currently
//    hard-wired. these need to be corrected before even the pinhole resolution is correct
// x- resolution calculation is in the correct place. The calculation is done per-panel (specified by TYPE),
//    and then the unwanted points can be discarded (all 6 columns) as the data is trimmed and concatenated
//    is separate functions that are resolution-aware.
//
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
Function VC_fDoBinning_QxQy2D(string folderStr, string type, string collimationStr)

	variable nSets = 0
	variable xDim, yDim
	variable ii, jj
	variable qVal, nq, var, avesq, aveisq
	variable binIndex, val, maskMissing
	variable isVCALC = 0

	string folderPath = "root:Packages:NIST:VSANS:" + folderStr
	string instPath   = ":entry:instrument:detector_"
	string detStr

	if(cmpstr(folderStr, "VCALC") == 0)
		isVCALC = 1
	endif

	detStr = type

	// now switch on the type to determine which waves to declare and create
	// since there may be more than one panel to step through. There may be two, there may be four
	//

	// TODO:
	// -- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
	//
	// assume that the mask files are missing unless we can find them. If VCALC data,
	//  then the Mask is missing by definition
	maskMissing = 1

	strswitch(type) // string switch

		// only one panel, simply pick that panel and move on out of the switch
		case "FL": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FR": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FT": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "FB": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "ML": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MR": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MT": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "MB": // FIXME(CodeStyleFallthroughCaseRequireComment)
		case "B":
			if(isVCALC)
				WAVE   inten = $(folderPath + instPath + detStr + ":det_" + detStr)
				WAVE/Z iErr  = $("iErr_" + detStr) // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten = V_getDetectorDataW(folderStr, detStr)
				WAVE iErr  = V_getDetectorDataErrW(folderStr, detStr)
			endif
			WAVE/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + detStr + ":data")
			if(WaveExists(mask) == 1)
				maskMissing = 0
			endif
			NVAR delQ   = $(folderPath + instPath + detStr + ":gDelQ_" + detStr)
			WAVE qTotal = $(folderPath + instPath + detStr + ":qTot_" + detStr) // 2D q-values
			nSets = 1
			break

		case "FLR":
			// detStr has multiple values now, so unfortuntely, I'm hard-wiring things...
			// -but what I'm hard-wiring is only the definition of FLR
			// -- see if I can un-hard-wire some of this below when more than one panel is combined
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FL" + ":det_" + "FL")
				WAVE/Z iErr   = $("iErr_" + "FL") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FR" + ":det_" + "FR")
				WAVE/Z iErr2  = $("iErr_" + "FR") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "FL")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "FL")
				WAVE inten2 = V_getDetectorDataW(folderStr, "FR")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "FR")
			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FL" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FR" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "FL" + ":gDelQ_FL")

			WAVE qTotal  = $(folderPath + instPath + "FL" + ":qTot_" + "FL") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FR" + ":qTot_" + "FR") // 2D q-values

			nSets = 2
			break

		case "FTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FT" + ":det_" + "FT")
				WAVE/Z iErr   = $("iErr_" + "FT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FB" + ":det_" + "FB")
				WAVE/Z iErr2  = $("iErr_" + "FB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "FT")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "FT")
				WAVE inten2 = V_getDetectorDataW(folderStr, "FB")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "FB")
			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FT" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FB" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "FT" + ":gDelQ_FT")

			WAVE qTotal  = $(folderPath + instPath + "FT" + ":qTot_" + "FT") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FB" + ":qTot_" + "FB") // 2D q-values

			nSets = 2
			break

		case "FLRTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "FL" + ":det_" + "FL")
				WAVE/Z iErr   = $("iErr_" + "FL") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "FR" + ":det_" + "FR")
				WAVE/Z iErr2  = $("iErr_" + "FR") // 2D errors -- may not exist, especially for simulation
				WAVE   inten3 = $(folderPath + instPath + "FT" + ":det_" + "FT")
				WAVE/Z iErr3  = $("iErr_" + "FT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten4 = $(folderPath + instPath + "FB" + ":det_" + "FB")
				WAVE/Z iErr4  = $("iErr_" + "FB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "FL")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "FL")
				WAVE inten2 = V_getDetectorDataW(folderStr, "FR")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "FR")
				WAVE inten3 = V_getDetectorDataW(folderStr, "FT")
				WAVE iErr3  = V_getDetectorDataErrW(folderStr, "FT")
				WAVE inten4 = V_getDetectorDataW(folderStr, "FB")
				WAVE iErr4  = V_getDetectorDataErrW(folderStr, "FB")

			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FL" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FR" + ":data")
			WAVE/Z mask3 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FT" + ":data")
			WAVE/Z mask4 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "FB" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "FL" + ":gDelQ_FL")

			WAVE qTotal  = $(folderPath + instPath + "FL" + ":qTot_" + "FL") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "FR" + ":qTot_" + "FR") // 2D q-values
			WAVE qTotal3 = $(folderPath + instPath + "FT" + ":qTot_" + "FT") // 2D q-values
			WAVE qTotal4 = $(folderPath + instPath + "FB" + ":qTot_" + "FB") // 2D q-values

			nSets = 4
			break

		case "MLR":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "ML" + ":det_" + "ML")
				WAVE/Z iErr   = $("iErr_" + "ML") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MR" + ":det_" + "MR")
				WAVE/Z iErr2  = $("iErr_" + "MR") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "ML")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "ML")
				WAVE inten2 = V_getDetectorDataW(folderStr, "MR")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "MR")

			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "ML" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MR" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "ML" + ":gDelQ_ML")

			WAVE qTotal  = $(folderPath + instPath + "ML" + ":qTot_" + "ML") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MR" + ":qTot_" + "MR") // 2D q-values

			nSets = 2
			break

		case "MTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "MT" + ":det_" + "MT")
				WAVE/Z iErr   = $("iErr_" + "MT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MB" + ":det_" + "MB")
				WAVE/Z iErr2  = $("iErr_" + "MB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "MT")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "MT")
				WAVE inten2 = V_getDetectorDataW(folderStr, "MB")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "MB")

			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MT" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MB" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "MT" + ":gDelQ_MT")

			WAVE qTotal  = $(folderPath + instPath + "MT" + ":qTot_" + "MT") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MB" + ":qTot_" + "MB") // 2D q-values

			nSets = 2
			break

		case "MLRTB":
			if(isVCALC)
				WAVE   inten  = $(folderPath + instPath + "ML" + ":det_" + "ML")
				WAVE/Z iErr   = $("iErr_" + "ML") // 2D errors -- may not exist, especially for simulation
				WAVE   inten2 = $(folderPath + instPath + "MR" + ":det_" + "MR")
				WAVE/Z iErr2  = $("iErr_" + "MR") // 2D errors -- may not exist, especially for simulation
				WAVE   inten3 = $(folderPath + instPath + "MT" + ":det_" + "MT")
				WAVE/Z iErr3  = $("iErr_" + "MT") // 2D errors -- may not exist, especially for simulation
				WAVE   inten4 = $(folderPath + instPath + "MB" + ":det_" + "MB")
				WAVE/Z iErr4  = $("iErr_" + "MB") // 2D errors -- may not exist, especially for simulation
			else
				WAVE inten  = V_getDetectorDataW(folderStr, "ML")
				WAVE iErr   = V_getDetectorDataErrW(folderStr, "ML")
				WAVE inten2 = V_getDetectorDataW(folderStr, "MR")
				WAVE iErr2  = V_getDetectorDataErrW(folderStr, "MR")
				WAVE inten3 = V_getDetectorDataW(folderStr, "MT")
				WAVE iErr3  = V_getDetectorDataErrW(folderStr, "MT")
				WAVE inten4 = V_getDetectorDataW(folderStr, "MB")
				WAVE iErr4  = V_getDetectorDataErrW(folderStr, "MB")

			endif
			WAVE/Z mask  = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "ML" + ":data")
			WAVE/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MR" + ":data")
			WAVE/Z mask3 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MT" + ":data")
			WAVE/Z mask4 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_" + "MB" + ":data")
			if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
				maskMissing = 0
			endif

			NVAR delQ = $(folderPath + instPath + "ML" + ":gDelQ_ML")

			WAVE qTotal  = $(folderPath + instPath + "ML" + ":qTot_" + "ML") // 2D q-values
			WAVE qTotal2 = $(folderPath + instPath + "MR" + ":qTot_" + "MR") // 2D q-values
			WAVE qTotal3 = $(folderPath + instPath + "MT" + ":qTot_" + "MT") // 2D q-values
			WAVE qTotal4 = $(folderPath + instPath + "MB" + ":qTot_" + "MB") // 2D q-values

			nSets = 4
			break

		default: // FIXME(CodeStyleFallthroughCaseRequireComment)
			nSets = 0
			Print "ERROR   ---- type is not recognized "
	endswitch

	//	Print "delQ = ",delQ," for ",type

	if(nSets == 0)
		SetDataFolder root:
		return (0)
	endif

	// RAW data is currently read in and the 2D error wave is correctly generated
	// 2D error is propagated through all reduction steps, but I have not
	// verified that it is an exact duplication of the 1D error
	//
	//
	//
	// IF ther is no 2D error wave present for some reason, make a fake one
	if(WaveExists(iErr) == 0 && WaveExists(inten) != 0)
		Duplicate/O inten, iErr
		WAVE iErr = iErr
		//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten + 0.75) // (DONE) -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr2) == 0 && WaveExists(inten2) != 0)
		Duplicate/O inten2, iErr2
		WAVE iErr2 = iErr2
		//		iErr2 = 1+sqrt(inten2+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr2 = sqrt(inten2 + 0.75) // (DONE) -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr3) == 0 && WaveExists(inten3) != 0)
		Duplicate/O inten3, iErr3
		WAVE iErr3 = iErr3
		//		iErr3 = 1+sqrt(inten3+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr3 = sqrt(inten3 + 0.75) // (DONE) -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr4) == 0 && WaveExists(inten4) != 0)
		Duplicate/O inten4, iErr4
		WAVE iErr4 = iErr4
		//		iErr4 = 1+sqrt(inten4+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr4 = sqrt(inten4 + 0.75) // (DONE) -- here I'm just using some fictional value
	endif

	// (DONE) -- nq is larger for the back detector
	//
	// - the needs for the back detector keep shrinkng as the CCDs die...
	//

	if(cmpstr(type, "B") == 0)
		nq = 8000
	else
		nq = 600
	endif

	//******(DONE) averaged data stored in the (type) data folder-- right now, folderStr is forced to ""
	//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...
	Make/O/D/N=(nq) $(folderPath + ":" + "iBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "qBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "nBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "iBin2_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "eBin_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "eBin2D_qxqy" + "_" + type)

	WAVE iBin_qxqy   = $(folderPath + ":" + "iBin_qxqy_" + type)
	WAVE qBin_qxqy   = $(folderPath + ":" + "qBin_qxqy" + "_" + type)
	WAVE nBin_qxqy   = $(folderPath + ":" + "nBin_qxqy" + "_" + type)
	WAVE iBin2_qxqy  = $(folderPath + ":" + "iBin2_qxqy" + "_" + type)
	WAVE eBin_qxqy   = $(folderPath + ":" + "eBin_qxqy" + "_" + type)
	WAVE eBin2D_qxqy = $(folderPath + ":" + "eBin2D_qxqy" + "_" + type)

	//
	// (DONE): not sure if I want to set dQ in x or y direction..
	// -- delQ is set from a global value for each panel. delQ is found as the q-Width of the
	// lateral direction of the innermost tube on the panel.
	//
	// delQ can further be modified by the global preference of step size (default is 1.2)
	//
	qBin_qxqy[] = p * delQ
	SetScale/P x, 0, delQ, "", qBin_qxqy //allows easy binning

	iBin_qxqy   = 0
	iBin2_qxqy  = 0
	eBin_qxqy   = 0
	eBin2D_qxqy = 0
	nBin_qxqy   = 0 //number of intensities added to each bin

	// now there are situations of:
	// 1 panel
	// 2 panels
	// 4 panels
	//
	// this needs to be a double loop now...
	//
	//
	// The 1D error does not use iErr, and IS CALCULATED CORRECTLY
	//
	// x- the solid angle per pixel will be present for WORK data other than RAW, but not for RAW

	//
	// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
	if(maskMissing == 1)
		Print "Mask file not found for at least one detector - so all data is used"
	endif

	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(gIgnoreDetB && cmpstr(type, "B") == 0)
		maskMissing = 1
		Print "Mask skipped for B due to possible mismatch (Panel B ignored in preferences)"
	endif

	variable mask_val
	// use set 1 (no number) only
	if(nSets >= 1)
		xDim = DimSize(inten, 0)
		yDim = DimSize(inten, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten[ii][jj]

				//				if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
				if(maskMissing) // mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
					mask_val = 0
				else
					mask_val = mask[ii][jj]
				endif
				if(numType(val) == 0 && mask_val == 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr[ii][jj] * iErr[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

	endif

	// add in set 2 (set 1 already done)
	if(nSets >= 2)
		xDim = DimSize(inten2, 0)
		yDim = DimSize(inten2, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal2[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten2[ii][jj]

				//				if(isVCALC || maskMissing)
				if(maskMissing)
					mask_val = 0
				else
					mask_val = mask2[ii][jj]
				endif
				if(numType(val) == 0 && mask_val == 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr2[ii][jj] * iErr2[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

	endif

	// add in set 3 and 4 (set 1 and 2 already done)
	if(nSets == 4)
		xDim = DimSize(inten3, 0)
		yDim = DimSize(inten3, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal3[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten3[ii][jj]

				//				if(isVCALC || maskMissing)
				if(maskMissing)
					mask_val = 0
				else
					mask_val = mask3[ii][jj]
				endif
				if(numType(val) == 0 && mask_val == 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr3[ii][jj] * iErr3[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

		xDim = DimSize(inten4, 0)
		yDim = DimSize(inten4, 1)

		for(ii = 0; ii < xDim; ii += 1)
			for(jj = 0; jj < yDim; jj += 1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal     = qTotal4[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val      = inten4[ii][jj]

				//				if(isVCALC || maskMissing)
				if(maskMissing)
					mask_val = 0
				else
					mask_val = mask4[ii][jj]
				endif
				if(numType(val) == 0 && mask_val == 0) //count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex]   += val
					iBin2_qxqy[binIndex]  += val * val
					eBin2D_qxqy[binIndex] += iErr4[ii][jj] * iErr4[ii][jj]
					nBin_qxqy[binIndex]   += 1
				endif
			endfor
		endfor

	endif

	// after looping through all of the data on the panels, calculate errors on I(q),
	// just like in CircSectAve.ipf
	// TODO:
	// -- 2D Errors were (maybe) properly acculumated through reduction, so this loop of calculations is NOT VERIFIED (yet)
	// x- the error on the 1D intensity, is correctly calculated as the standard error of the mean.
	for(ii = 0; ii < nq; ii += 1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii]   = 0
			eBin_qxqy[ii]   = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii]   /= nBin_qxqy[ii]
				eBin_qxqy[ii]    = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				//  -- this is correctly calculating the error as the standard error of the mean, as
				//    was always done for SANS as well.
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq          = iBin_qxqy[ii]^2
				aveisq         = iBin2_qxqy[ii] / nBin_qxqy[ii]
				var            = aveisq - avesq
				if(var <= 0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var / (nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor

	eBin2D_qxqy = sqrt(eBin2D_qxqy) // as equation (3) of John's memo

	// find the last non-zero point, working backwards
	val = nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)

	//	print val, nBin_qxqy[val]
	DeletePoints val, nq - val, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy

	if(val == 0)
		// all the points were deleted
		return (0)
	endif

	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)
	DeletePoints 0, val, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy) - 1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy, qBin_qxqy, nBin_qxqy, iBin2_qxqy, eBin_qxqy, eBin2D_qxqy
		endif
		val -= 1
	while(val > 0)

	// utility function to remove NaN values from the waves
	V_RemoveNaNsQIS(qBin_qxqy, iBin_qxqy, eBin_qxqy)

	// TODO:
	// -- This is where I calculate the resolution in SANS (see CircSectAve)
	// -- use the isVCALC flag to exclude VCALC from the resolution calculation if necessary
	// -- from the top of the function, folderStr = work folder, type = "FLRTB" or other type of averaging
	//
	nq = numpnts(qBin_qxqy)
	Make/O/D/N=(nq) $(folderPath + ":" + "sigmaQ_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "qBar_qxqy" + "_" + type)
	Make/O/D/N=(nq) $(folderPath + ":" + "fSubS_qxqy" + "_" + type)
	WAVE sigmaq = $(folderPath + ":" + "sigmaQ_qxqy_" + type)
	WAVE qbar   = $(folderPath + ":" + "qBar_qxqy_" + type)
	WAVE fsubs  = $(folderPath + ":" + "fSubS_qxqy_" + type)
	variable ret1, ret2, ret3

	// all of the different collimation conditions are handled within the V_getResolution function
	// which is responsible for switching based on the different collimation types (white beam, slit, Xtal, etc)
	// to calculate the correct resolution, or fill the waves with the correct "flags"
	//

	// For white beam data, the wavelength distribution can't be represented as a gaussian, but all of the other
	//  geometric corrections still apply. Passing zero for the lambdaWidth will return the geometry contribution,
	//  as long as the wavelength can be handled separately. It appears to be correct to do as a double integral,
	//  with the inner(lambda) calculated first, then the outer(geometry).
	//

	// possible values are:
	//
	// pinhole
	// pinhole_whiteBeam
	// convergingPinholes
	//
	// *slit data should be reduced using the slit routine, not here, proceed but warn
	// narrowSlit
	// narrowSlit_whiteBeam
	//
	ii = 0
	do
		V_getResolution(qBin_qxqy[ii], folderStr, type, collimationStr, ret1, ret2, ret3)
		sigmaq[ii] = ret1
		qbar[ii]   = ret2
		fsubs[ii]  = ret3
		ii        += 1
	while(ii < nq)

	SetDataFolder root:

	return (0)
End

