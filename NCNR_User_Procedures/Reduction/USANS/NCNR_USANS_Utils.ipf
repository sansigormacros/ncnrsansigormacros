#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.1

// utilities and constants that are specific to the NCNR USANS

// updated in AUG 2024
// -- added functionality to allow the user to enter a calibration factor for conversion
//   of angle->q. This was added to KIST macros, but is currently commented out here
// --added analysis preference to switch to qTrap for slit-smearing rather than the default
//   matrix smearing. Sometimes the matrix fails, but the trapezoidal integration works.
// -- updated the BT5 loader to account for an extra column of temperature data being inserted
//   as the 2nd column (where count time is expected). Now checks header labels to locate time.
//

// Constant

//facility-specific constants
Function Init_USANS_Facility()

	//INSTRUMENTAL CONSTANTS
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gTheta_H = 3.9e-6 //Darwin FWHM	(pre- NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gTheta_V = 0.014  //Vertical divergence	(pre- NOV 2004)
	//Variable/G  root:Globals:MainPanel:gDomega = 2.7e-7		//Solid angle of detector (pre- NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDomega     = 7.1e-7 //Solid angle of detector (NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDefaultMCR = 1e6    //factor for normalization

	//Variable/G  root:Globals:MainPanel:gDQv = 0.037		//divergence, in terms of Q (1/A) (pre- NOV 2004)
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gDQv = 0.117 //divergence, in terms of Q (1/A)  (NOV 2004)

	string/G root:Packages:NIST:gXMLLoader_Title = ""

	//November 2010 - deadtime corrections -- see USANS_DetectorDeadtime() below
	//Only used in BT5_Loader.ipf and dependent on date, so defined there on each file load.

	// is the data file from NICE and in terms of QValues rather than angle?
	variable/G root:Packages:NIST:gRawUSANSisQvalues = 1 //== 1 means raw data is in Q, not angle
	DoAlert 0, "The data loader is set to interpret raw data in Q-values (from NICE), not angle (from ICP). If your raw data was collected from ICP, change this setting using the menu item USANS->NCNR Preferences"

	//	 Ask the user to set an empirical calibration correction factor -- MULTIPLICATIVE --
	//	 SRK AUG 6 2024 -- NOT used for NCNR data, this is from KIST macros
	// currently the correction == 1, and the data is in q-values already, so the net correction = 1*1 = 1
	//
	variable gCalibration = NumVarOrDefault("gCalibration", 1.0) //this is the default value for the calibration
	//	Prompt gCalibration, "Enter the Multiplicative calibration correction"
	//	DoPrompt "Calibration",gCalibration

	variable/G root:Packages:NIST:gCalibration = gCalibration // Save for later use
	// it doesn't matter if the user cancelled -- we need a value for this. so if they cancel,
	// then the value is the default of 1
	//	Print "Calibration correction is = ",gCalibration

	// to convert from angle (in degrees) to Q (in 1/Angstrom)
	// -- or to disable the conversion if the data is "new NICE" (approx Mar 2019)
	NVAR gRawUSANSisQvalues = root:Packages:NIST:gRawUSANSisQvalues
	if(gRawUSANSisQvalues == 1)
		variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv_base = 1 //so that the q-values are unchanged
	else
		variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv_base = 5.55e-5 //JGB -- 2/24/01
	endif
	NVAR gdeg2QConv_base = root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv_base
	//final value used for conversion
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv = gDeg2QConv_base * gCalibration

	// extension string for the raw data files
	// -- not that the extension as specified here starts with "."
	string/G root:Packages:NIST:USANS:Globals:MainPanel:gUExt = ".bt5"

	// on Feb 7 2019 @ 11:00 AM, the order of the columns in the raw BT5 data file was swapped to
	// put the 5 detectors in positions 2-6, moving the transmission detector from postion 4 to positon 7
	// this was the only change made to the data file (done in expectation of NICE being ready soon)
	// --to switch between the two different read routines, key on the time of data collection in the data file
	//
	variable/G root:Packages:NIST:USANS:Globals:MainPanel:gFileSwitchSecs = date2secs(2019, 2, 7) + 3600 * 11 // the seconds of the switch

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

	if(BT5Date2Secs(filedt) < date2secs(2010, 11, 7))
		MainDeadTime  = 4e-5
		TransDeadTime = 1.26e-5
		//print "Old Dead Times"
		//MainDeadTime = 0
		//TransDeadTime = 0
	else
		MainDeadTime  = 7e-6
		TransDeadTime = 1.26e-5
		//print "New Dead Times"
	endif

	return (0)
End

//// add a menu item so that this can be accessed
//Menu "USANS"
//
//	"-"
//	"Enter Calibration Value", fEnterCalibrationValue()
//	"-"
//
//End

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

