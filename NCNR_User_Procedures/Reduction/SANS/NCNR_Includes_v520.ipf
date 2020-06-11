#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.2
#pragma IgorVersion=6.1

// to properly set up the template for other facility reduction templates, 
// function NCNR() must exist here in the Includes file.
//
Function NCNR()
	//does nothing but define NCNR()
	return(0)
End


//*************
// the list of files to include in the SANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//
// these procedure files are those used in version 5.0 of the 
// SANS Reduction macros, August 2006

#include "AvgGraphics"			version>=5.0
#include "Buttons"				version>=5.0
#include "CatVSTable"			version>=5.0
#include "CircSectAve"			version>=5.0
#include "Correct"				version>=5.0
#include "DisplayUtils"			version>=5.0
#include "FIT_Ops"				version>=5.0
#include "Initialize"			version>=5.0
#include "MainPanel"			version>=5.0
#include "Marquee"				version>=5.0
#include "MaskUtils"			version>=5.0
#include "Menu"					version>=5.0
#include "MultipleReduce"		version>=5.0
#include "NSORT"					version>=5.0
#include "PatchFiles"			version>=5.0
//#include "PlotUtils"			version>=5.0
//AJJ October 2008 - switch to shared file loader
#include "PlotUtilsMacro_v40"
#include "NIST_XML_v40"
//#include "cansasXML"
#include "USANS_SlitSmearing_v40"
#include "GaussUtils_v40" // for isSANSResolution - could put this function elsewhere
//
#include "ProDiv"				version>=5.0
#include "ProtocolAsPanel"		version>=5.0
//#include "RawDataReader"		version>=5.0 			//branched 29MAR07
#include "RawWindowHook"		version>=5.0
#include "RectAnnulAvg"			version>=5.0
#include "Schematic"			version>=5.0
#include "Tile_2D"				version>=5.0
#include "Transmission"			version>=5.0
//#include "VAXFileUtils"			version>=5.0		//branched 29MAR07
#include "WorkFileUtils"		version>=5.0
#include "WriteQIS"				version>=5.0 
// removed RT button from main panel AUG2006
// removed RT ipf file in 29MAR07 branch (do not delete, but do not include or maintain)
//Add back Real Time for ICE
#include "RealTimeUpdate_RT"		version>=5.0		
#include "Subtract_1D"				version>=5.0 			//NEW 14MAY03

#include "NCNR_Utils"									//new in the 29MAR07 branch
#include "NCNR_DataReadWrite"							//new in the 29MAR07 branch
#include "SANS_Utilities"								//new in the 29MAR07 branch

// new in Jan 2008
#include "SASCALC"
#include "CheckVersionFTP"				//added June 2008
#include "MultScatter_MonteCarlo_2D"			//Oct 2008 SRK for SASCALC simulation


#include "TISANE"


//AJJ Oct 2008
#include "PlotManager_v40"

// SRK JUN2009
#include "Smear_2D"		//2D resolution calculation and smearing

//AJJ Nov 2009
#include "DataSetHandling"
#include "WriteModelData_v40"

// SRK OCT 2012 - processing of event mode data
#include "EventModeProcessing"

// SRK JAN 2013 - to make simulation easier
// SRK NOV 2014 -- moved to a separate loader to avoid reduction/analysis tangles
//#include "MC_SimulationScripting"

// SRK NOV 2014 -- beta of automated reduction routines
#include "Automated_SANS_Reduction"

// SRK NOV 2014 -- beta of a "run panel" for scripting of simulation
// SRK NOV 2014 -- moved to a separate loader to avoid reduction/analysis tangles
//#include "MC_Script_Panels"

// JRK JUN 2019 -- import NXcanSAS read and write utilities
#include "NIST_NXcanSAS_v709"
#include "Write_SANS_NXcanSAS"


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
	"PatchFileNameInHeader"
	"ReadFileNameInHeader"
	"-"
	"Renumber Run Number"
	"Check File Names"
//	"-"
//	"AddALLToLayout"			//added to tile raw 2d panel
	
End