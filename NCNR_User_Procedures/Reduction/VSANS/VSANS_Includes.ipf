#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// to properly set up the template for other facility reduction templates, 
// function NCNR_VSANS() must exist here in the Includes file.
//
Function NCNR_VSANS()
	//does nothing but define NCNR()
	return(0)
End


// These files are COMMON NCNR FILES
// the first three are necessary for loading and plotting of 1D data sets
// using the PlotManager
#include "PlotUtilsMacro_v40"
#include "PlotManager_v40"
#include "NIST_XML_v40"



// VC designation is for VCALC (mostly)
// and V designation is for VSANS
// no prefix = COMMON procedure files
//  note that the common files are not in the VSANS procedure folder and
//  are not included in the line count


#include "VC_DetectorBinning_Q"
#include "VC_DetectorBinning_Slit"
#include "VC_DetectorBinning_Utils"
#include "VC_FrontView_Deg"	
#include "VC_HDF5_VSANS_Utils"
#include "VC_SideView"
#include "VC_UtilityProcedures"
#include "VC_VCALCPanel_MockUp"

#include "HDF5gateway_NCNR"
#include "Vx_Nexus_SANS_Write"
#include "Vx_Nexus_VSANS_Write"
//#include "V_ReadWrite_HDF5"		//AUG2015 beginning of read/write, renamed Nov2015
#include "Vx_NexusFromIgor"			//AUG2015 - depricated, but keep for now

// for possible peak fitting
#include "V_BroadPeak_Pix_2D"
#include "V_BeamCenter"

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
#include "V_DataPlotting"

// 1D binning, combining 1D sets
#include "V_IQ_Utilities"

// testing procedures, to fill fake data from VCALC simulations
#include "V_Testing_Data_Procs"

// mask files
#include "V_MaskUtils"

// DIV files
#include "V_DIVUtils"

// more functionality
#include "V_FileCatalog"
#include "V_PatchFiles"
#include "V_ShowDataTree"

#include "V_Correct"
#include "V_Detector_Isolate"
#include "V_Protocol_Reduction"
#include "V_Marquee_Operations"
#include "V_RealTimeUpdate"


