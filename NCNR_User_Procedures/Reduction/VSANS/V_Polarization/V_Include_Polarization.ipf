#pragma rtGlobals=1		// Use modern global access method.

//
// files to include after the VSANS reduction has been loaded to 
// load in the procedures necessary for reduction of polarized
// beam data

// JUN 2020 SRK
	
//#include "Pol_PolCorr"
#include "V_Pol_PolarizationPanels"
#include "V_Pol_PolarizationCorrection"
#include "V_Pol_FlipperPanel"
#include "V_Pol_Utils"


// these don't work - since they are loaded later than the protocol panel...
//
// may need to force a switch in the V_ReduceOneButton() to switch to the Polarization
// function if one of the polarization functions exists. I don't have any other flag to 
// signify that the package is loaded and active
//
//Override Function V_ExecuteProtocol(temp,tempStr)
//	string temp,tempStr
//	
//	DoAlert 0,"In Override function"
//	return(0)
//End
//
//Override function V_ReduceOneButton(ctrlName)
//	String ctrlname
//	
//		DoAlert 0,"In Override function"
//	return(0)
//end