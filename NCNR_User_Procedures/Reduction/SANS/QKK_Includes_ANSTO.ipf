#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

//*************
// the list of files to include in the SANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//
// nha. Edited for Quokka. 5/2/09
//


// to properly set up the template for QUOKKA Data Reduction, the dummy
// function must exist in the Includes file.
//
Function QUOKKA()
	//does nothing but declare QUOKKA
	return(0)
End

#include "QKK_AvgGraphics"			version>=5.0
#include "QKK_Buttons"				version>=5.0
#include "QKK_CatVSTable"			version>=5.0
#include "QKK_CircSectAve"			version>=5.0
#include "QKK_Correct"				version>=5.0
#include "QKK_DisplayUtils"			version>=5.0
#include "QKK_FIT_Ops"				version>=5.0
#include "QKK_Initialize"			version>=5.0
#include "QKK_MainPanel"			version>=5.0
#include "QKK_Marquee"				version>=5.0
#include "QKK_MaskUtils"			version>=5.0
#include "QKK_Menu"					version>=5.0
#include "QKK_MultipleReduce"		version>=5.0
#include "QKK_NSORT"				version>=5.0
#include "QKK_PatchFiles"			version>=5.0
//#include "PlotUtils"			version>=5.0
//AJJ October 2008 - switch to shared file loader

#include "PlotUtilsMacro_v40"
#include "NIST_XML_v40"
//#include "cansasXML"
#include "USANS_SlitSmearing_v40"
#include "GaussUtils_v40" // for isSANSResolution - could put this function elsewhere
//
#include "QKK_ProDiv"					version>=5.0
#include "QKK_ProtocolAsPanel"		version>=5.0
//#include "RawDataReader"		version>=5.0 			//branched 29MAR07
#include "QKK_RawWindowHook"		version>=5.0
#include "QKK_RectAnnulAvg"			version>=5.0
#include "QKK_Schematic"			version>=5.0
#include "QKK_Tile_2D"				version>=5.0
#include "QKK_ANSTO_Transmission"	version>=5.0	//davidm for Quokka
#include "QKK_WorkFileUtils"		version>=5.0
#include "QKK_WriteQIS"				version>=5.0 
// removed RT button from main panel AUG2006
// removed RT ipf file in 29MAR07 branch (do not delete, but do not include or maintain)
//#include "RealTimeUpdate_RT"		version>=5.0		
#include "QKK_ANSTO_OnlineReduction"	version>=5.0				// davidm 16May11
#include "QKK_Subtract_1D"				version>=5.0 			//NEW 14MAY03

#include "SANS_Utilities"								//new in the 29MAR07 branch
#include "QKK_ANSTO_DataReadWrite"	//nha for Quokka
#include "QKK_ANSTO_Utils"			//nha for Quokka

// new in Jan 2008
#include "QKK_SASCALC"
//#include "CheckVersionFTP"				//added June 2008
#include "QKK_MultScatter_MonteCarlo_2D"			//Oct 2008 SRK for SASCALC simulation

//#include "TISANE"


//AJJ Oct 2008
#include "PlotManager_v40"

// SRK JUN2009
#include "Smear_2D"		//2D resolution calculation and smearing

//AJJ Nov 2009
#include "DataSetHandling"
#include "WriteModelData_v40"

// Added Desmearing functionality 
#include "QKK_DesmearingUtils"
#include "QKK_LakeDesmearing_JB"						  

// a simple list of items to add to the Beta menu
// to allow testing of these features
//
// To activate the SANSBeta menu, change "xMenu" to "Menu"
// and click "compile" at the bottom of this window. The SANSBeta
// menu will appear in the menubar.
////
//Menu "SANSBeta"
//	"Help for Beta Operations",DisplayHelpTopic/Z/K=1 "Beta SANS Tools"
//	"-"
//	"FillEMPUsingSelection"
////	"GuessEveryTransFile"
////	"GuessSelectedTransFiles"
//	"ClearSelectedTransAssignments"
//	"-"
//////	"CreateRunNumList"
//////	"TransList"
//	"ScatteringAtSDDList"
//////	"RemoveRunFromList"
//	"FillMREDList"
//	"-"
//////	"Set3NSORTFiles"
//	"CreateTableToCombine"
//	"DoCombineFiles"
//	"-"
//	"Convert To Lens"
//	"Convert To Pinhole"
//	"Patch Detector Pixel Size"
//	"Read Detector Pixel Size"
//	"-"
//	"AddALLToLayout"
//	
//End