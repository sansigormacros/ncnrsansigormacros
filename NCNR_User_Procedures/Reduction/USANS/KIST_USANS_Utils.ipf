#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.1

// utilities and constants that are specific to the KIST USANS
//
// contains updated instrument constants (MHK) 2014-06-20
// added to NCNR SVN 9/2015 (SRK)

// updated in AUG 2024 to properly bypass the (NCNR) default of raw data in q-values
// --also added functionality to allow the user to enter a calibration factor for conversion
//   of angle->q
// --added analysis preference to switch to qTrap for slit-smearing rather than the default
//   matrix smearing. Sometimes the matrix fails, but the trapezoidal integration works.
//

//facility-specific constants
Function Init_USANS_Facility()

	//INSTRUMENTAL CONSTANTS
	//Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_H = 3.9e-6		//Darwin FWHM	(pre- NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gTheta_H = 7.59e-6 //Horizontal divergence of kist-usans,  mhk--08/2102012
	//Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_V = 0.014		//Vertical divergence	(pre- NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gTheta_V = 0.057 // KIST-USANS Vertical divergence =0.057 radian (2013) * («—ºˆ∞Ê ≥Î∆Æ∫œø°ø° 2014-06-20  ¿˚øÎ)
	//Variable/G  root:Globals:MainPanel:gDomega = 2.7e-7		//Solid angle of detector (pre- NOV 2004)
	//Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDomega = 7.1e-7		//Solid angle of detector (NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDomega     = 1.73e-6 //KIST-USANS Solid angle of detector (mhk----07/18/2013) **(2014-06-20  ¿˚øÎ)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDefaultMCR = 1e6     //factor for normalization

	//Variable/G  root:Globals:MainPanel:gDQv = 0.037		//divergence, in terms of Q (1/A) (pre- NOV 2004)
	//Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDQv = 0.117		//divergence, in terms of Q (1/A)  (NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDQv = 0.09 //detector divergence, in terms of Q (1/A), mhk --09-12-2012

	string/G root:Packages:NIST:gXMLLoader_Title = ""

	//November 2010 - deadtime corrections -- see USANS_DetectorDeadtime() below
	//Only used in BT5_Loader.ipf and dependent on date, so defined there on each file load.

	// is the data file in terms of QValues rather than angle?
	variable/G root:Packages:NIST:gRawUSANSisQvalues = 0 //== 1 means raw data is in Q, 0 means angle

	DoAlert 0, "The data loader is set to interpret raw data in ANGLE not Q-Values. If your raw data is different, change this setting using the menu item USANS->NCNR Preferences"

	// this variable should never be defined for HANARO data
	//	Variable/G root:Packages:NIST:USANS:Globals:MainPanel:gFileSwitchSecs=0

	// Ask the user to set the calibration factor -- MULTIPLICATIVE --
	// SRK AUG 6 2024
	variable gCalibration = NumVarOrDefault("gCalibration", 1.418) //this is the default value for the calibration
	Prompt gCalibration, "Enter the Multiplicative calibration correction"
	DoPrompt "Calibration", gCalibration

	variable/G root:Packages:NIST:gCalibration = gCalibration // Save for later use
	// it doesn't matter if the user cancelled -- we need a value for this. so if they cancel,
	// then the value is the default of 1
	Print "Calibration correction is = ", gCalibration

	// to convert from angle (in degrees) to Q (in 1/Angstrom)
	// Variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv=5.55e-5		//JGB -- 2/24/01
	// Variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv=2.741557e-2		//motor position in degree unit MHK for KIST ---08/15/2012
	// Variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv=1.5707963e-2	// motor position in mm  MHK for KIST ---07/19/2013

	variable/G root:Packages:NIST:gDeg2QConv_base = 1.5707963e-4                       // motor position in mm (x100) MHK for KIST ---07/19/2013
	NVAR       gDeg2QConv_base                    = root:Packages:NIST:gDeg2QConv_base //base calibration before corrections

	variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv = gDeg2QConv_base * gCalibration //final value used for conversion

	// extension string for the raw data files
	// -- not that the extension as specified here starts with "."
	// String/G  	root:Packages:NIST:USANS:Globals:MainPanel:gUExt = ".bt5"
	string/G root:Packages:NIST:USANS:Globals:MainPanel:gUExt = ".kusan" //mhk--08/15/2012

	return (0)
End

// returns the detector dead time for the main detectors, and the transmission detector
//
// NCNR values switch based on a date when hardware was swapped out. other facilities can ignore the date
//
// also, if dead time is not known, zero can be returned to inactivate the dead time correction
//
//
//Discovered significant deadtime on detectors in Oct 2010
//JGB and AJJ changed pre-amps during shutdown Oct 27 - Nov 7 2010
//Need different deadtime before and after 8th November 2010
//
Function USANS_DetectorDeadtime(string filedt, variable &MainDeadTime, variable &TransDeadTime)

	//	if (BT5Date2Secs(filedt) < date2secs(2010,11,7))
	//			MainDeadTime = 4e-5
	//			TransDeadTime = 1.26e-5
	//			//print "Old Dead Times"
	//			//MainDeadTime = 0
	//			//TransDeadTime = 0
	//	else
	//			MainDeadTime = 7e-6
	//			TransDeadTime = 1.26e-5
	//			//print "New Dead Times"
	//	endif

	MainDeadTime  = 0
	TransDeadTime = 0

	return (0)
End

// add a menu item so that this can be accessed
Menu "USANS"

	"-"
	"Enter Calibration Value", fEnterCalibrationValue()
	"-"

End

// SRK 2024 -- to allow adjustment of the calibration factor for ang->Q
//
// Ask the user to set the calibration factor -- MULTIPLICATIVE --
// prints out the new (or unchanged) value
//
Function fEnterCalibrationValue()

	NVAR gCalibration = root:Packages:NIST:gCalibration // current value

	variable newCalibration = gCalibration
	Prompt newCalibration, "Enter the Multiplicative calibration correction"
	DoPrompt "Calibration", newCalibration

	if(V_Flag == 1) //user cancelled

		Print "Calibration correction is (unchanged) = ", gCalibration

		return (0)
	endif

	variable/G root:Packages:NIST:gCalibration = newCalibration // update and Save for later use

	NVAR gDeg2QConv_base = root:Packages:NIST:gDeg2QConv_base

	variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv = gDeg2QConv_base * newCalibration

	Print "New calibration correction is = ", newCalibration

	return (0)
End

