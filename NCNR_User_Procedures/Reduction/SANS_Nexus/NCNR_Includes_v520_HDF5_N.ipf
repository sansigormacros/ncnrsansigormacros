#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.2
#pragma IgorVersion=6.1

// to properly set up the template for other facility reduction templates, 
// function NCNR() must exist here in the Includes file.
//
Function NCNR_Nexus()
	//does nothing but define NCNR()
	return(0)
End

Menu "NEXUS 10m-SANS MODE"
End

// for the 10m instrument detType is "Tubes" and flags parts of the code to use Tube corrections and
// --if the data is Ordela data "faked" to be tubes then ksDetType = "Ordela" and the proper switches
// can be made to use Ordela corrections (non-linear, dead time, etc.)
StrConstant ksDetType = "Tubes"

//*************
// the list of files to include in the SANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//
// these procedure files are those used in version 5.0 of the 
// SANS Reduction macros, August 2006

#include "AvgGraphics_N"			version>=5.0
#include "Buttons_N"				version>=5.0
#include "CatVSTable_N"			version>=5.0
#include "CircSectAve_N"			version>=5.0
#include "Correct_N"				version>=5.0
#include "DisplayUtils_N"			version>=5.0
#include "LinearizedFits_v40"
#include "Initialize_N"			version>=5.0
#include "MainPanel_N"			version>=5.0
#include "Marquee_N"				version>=5.0
#include "MaskUtils_N"			version>=5.0
#include "Menu_N"					version>=5.0
#include "MultipleReduce_N"		version>=5.0
#include "NSORT_N"					version>=5.0
#include "PatchFiles_N"			version>=5.0
//#include "PlotUtils"			version>=5.0

// these common files are necessary to load/plot 1D reduced data
//AJJ October 2008 - switch to shared file loader
#include "PlotUtilsMacro_v40"
#include "NIST_XML_v40"
//#include "cansasXML"
#include "USANS_SlitSmearing_v40"
#include "GaussUtils_v40" // for isSANSResolution - could put this function elsewhere
//
//
#include "ProDiv_N"				version>=5.0
#include "ProtocolAsPanel_N"		version>=5.0
//#include "RawDataReader"		version>=5.0 			//branched 29MAR07
#include "RawWindowHook_N"		version>=5.0
#include "RectAnnulAvg_N"			version>=5.0
#include "Schematic_N"			version>=5.0
#include "Tile_2D_N"				version>=5.0
#include "Transmission_N"			version>=5.0
//#include "VAXFileUtils"			version>=5.0		//branched 29MAR07
#include "WorkFileUtils_N"		version>=5.0

#include "WriteQIS_N"				version>=5.0 
#include "RealTimeUpdate_RT_N"		version>=5.0		
#include "Subtract_1D_N"				version>=5.0 			//NEW 14MAY03

//#include "NCNR_Utils"									//new in the 29MAR07 branch
#include "NCNR_Utils_HDF5_N"									//new for July 2021
#include "NCNR_HDF5_Read_N"									//new for July 2021
#include "NCNR_HDF5_Write_N"									//new for July 2021
//#include "NCNR_DataReadWrite"							//new in the 29MAR07 branch
#include "NCNR_DataReadWrite_HDF5_N"							//new for July 2014
#include "NCNR_DataReadWriteUtils_N"							//new for July 2014
#include "SANS_Utilities_N"								//new in the 29MAR07 branch

// new in Jan 2008
#include "SASCALC_N"
#include "CheckVersionFTP"				//added June 2008
#include "MultScatter_MonteCarlo_2D_N"			//Oct 2008 SRK for SASCALC simulation


#include "TISANE_N"


//AJJ Oct 2008
#include "PlotManager_v40"

// SRK JUN2009
#include "Smear_2D"		//2D resolution calculation and smearing

//AJJ Nov 2009
#include "DataSetHandling"
#include "WriteModelData_v40"

// SRK OCT 2012 - processing of event mode data
//#include "EventModeProcessing_N"			//old VAX version + Ordela event file, eventually remove
#include "EventModeProcessing_Tubes_N"		// 
#include "EventMode_Utils_Tubes_N"

// SRK JAN 2013 - to make simulation easier
// SRK NOV 2014 -- moved to a separate loader to avoid reduction/analysis tangles
//#include "MC_SimulationScripting"

// SRK JUL 2014 -- testing of HDF5 read/write as a raw data format
// SRK JAN 2022 -- remove these VAX->HDF converters. They are out-of-date
//  keep with the old VAX package where they can be updated to write 2022 version Nexus
//#include "HDF5_ConvertVAX_to_HDF5"
//#include "HDF5gateway_NCNR"

// SRK NOV 2014 -- beta of automated reduction routines
#include "Automated_SANS_Reduction_N"

// SRK NOV 2014 -- beta of a "run panel" for scripting of simulation
// SRK NOV 2014 -- moved to a separate loader to avoid reduction/analysis tangles
//#include "MC_Script_Panels"

// JRK JUN 2019 -- import NXcanSAS read and write utilities
#include "NIST_NXcanSAS_v709"		// JAN 2022 "_N" tagged file is not needed
#include "Write_SANS_NXcanSAS_N"

// SRK JUL 2021 -- additions for Nexus handling
#include "Utilities_General_N"

// SRK FEB 2022 -- split out corrections to specific detector types
#include "WorkFileUtils_Tubes_N"
//#include "WorkFileUtils_Ordela_N"

#include "DetectorCorrections_N"		//for tube detectors

#include "ShowDataTree_N"			// to display the Nexus structure







// a simple list of items to add to the Beta menu
// to allow testing of these features
//
// To activate the SANSBeta menu, change "xMenu" to "Menu"
// and click "compile" at the bottom of this window. The SANSBeta
// menu will appear in the menubar.
//
xMenu "SANSBeta"
//	"Help for Beta Operations",DisplayHelpTopic/Z/K=1 "Beta SANS Tools"
//	"-"
//	"FillEMPUsingSelection"		// Transmission utilities have been added directly to the panel
//	"GuessEveryTransFile"
//	"GuessSelectedTransFiles"
//	"ClearSelectedTransAssignments"
//	"-"
////	"CreateRunNumList"
////	"TransList"
//	"ScatteringAtSDDList"			// MRED utilities have been added directly to the panel
////	"RemoveRunFromList"
//	"FillMREDList"
//	"-"
////	"Set3NSORTFiles"
//	"CreateTableToCombine"			//moved to a separate panel available from the 1D Ops tab
//	"DoCombineFiles"
//	"-"
	"Convert To Lens"
	"Convert To Pinhole"
	"Patch Detector Pixel Size"
	"Read Detector Pixel Size"
	"Patch User Account Name"
	"Read User Account Name"
	"Patch Monitor Count"
	"Read Monitor Count"
	"Read Detector Count"
	"-"
	"Renumber Run Number"
	"Check File Names"
//	"-"
//	"AddALLToLayout"			//added to tile raw 2d panel
	
End