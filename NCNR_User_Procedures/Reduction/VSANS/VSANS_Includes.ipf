#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// to properly set up the template for other facility reduction templates, 
// function NCNR_VSANS() must exist here in the Includes file.
//
Function NCNR_VSANS()
	//does nothing but define NCNR()
	return(0)
End


#include "VC_DetectorBinning_Q"
#include "VC_DetectorBinning_Slit"
#include "VC_DetectorBinning_Utils"
#include "VC_FrontView_Deg"	
#include "VC_HDF5_VSANS_Utils"
#include "VC_SideView"
#include "VC_UtilityProcedures"
#include "VC_VCALCPanel_MockUp"

#include "HDF5gateway_NCNR"
#include "Nexus_SANS_Write"
#include "Nexus_VSANS_Write"
//#include "V_ReadWrite_HDF5"		//AUG2015 beginning of read/write, renamed Nov2015
#include "V_NexusFromIgor"			//AUG2015 - depricated, but keep for now

// for possible peak fitting
#include "V_BroadPeak_Pix_2D"
#include "VC_BeamCenter"

// for fitting data to generate tube corrections
#include "V_TubeAdjustments"
#include "V_DetectorCorrections"

// for ISO time in Nexus files
#include "V_ISO8601_Util"

// HDF R/W Nov 2015
#include "V_HDF5_Read"
#include "V_HDF5_Write"
#include "V_HDF5_RW_Utils"

// start of VSANS reduction procedures
#include "V_Initialize"
#include "V_MainPanel"
#include "V_Menu"
#include "V_VSANS_Preferences"
#include "V_WorkFolderUtils"

// start of raw data display panel
#include "V_Test_RAW_Panel"		// rename this later when it's done
#include "V_Utilities_General"		//
