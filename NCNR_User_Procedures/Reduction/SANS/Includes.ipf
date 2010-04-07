#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.2
#pragma IgorVersion=6.1



// SRK 7 APR 2012
// as of version 5.1, this is now a pointer to the current version of the includes
#include "Includes_v520"

// SRK 12 FEB 08
// as of version 5.1, this is now a pointer to the current version of the includes
//#include "Includes_v510"

// as of version 5, this is now a pointer to the current version of the includes
// -- need for back-compatibility so that anyone opening an old template (v4.2 or earlier)
// will get an experiment that actualy compiles, rather than bonks with an error
//
// SRK 19 NOV 07
//#include "Includes_v500"

////*************
//// the list of files to include in the SANS reduction experiment
////  - files must be located somewhere in the User Procedures folder
//// or sub-folders
////
//// these procedure files are those used in version 4.2 of the 
//// SANS Reduction macros, October 2003
//
//#include "AvgGraphics"			version>=1.2
//#include "Buttons"				version>=1.2
//#include "CatVSTable"			version>=1.2
//#include "CircSectAve"			version>=1.2
//#include "Correct"				version>=1.2
//#include "DisplayUtils"			version>=1.2
//#include "FIT_Ops"				version>=1.2
//#include "Initialize"			version>=1.2
//#include "MainPanel"			version>=1.2
//#include "Marquee"				version>=1.2
//#include "MaskUtils"			version>=1.2
//#include "Menu"					version>=1.2
//#include "MultipleReduce"		version>=1.2
//#include "NSORT"					version>=1.2
//#include "PatchFiles"			version>=1.2
//#include "PlotUtils"			version>=1.2
//#include "ProDiv"				version>=1.2
//#include "ProtocolAsPanel"		version>=1.2
//#include "RawDataReader"		version>=1.2
//#include "RawWindowHook"		version>=1.2
//#include "RectAnnulAvg"			version>=1.2
//#include "Schematic"			version>=1.2
//#include "Tile_2D"				version>=1.2
//#include "Transmission"			version>=1.2
//#include "VAXFileUtils"			version>=1.2
//#include "WorkFileUtils"		version>=1.2
//#include "WriteQIS"				version>=1.2 
////single file necessary for RealTime updating, now in the same folder
//#include "RealTimeUpdate_RT"		version>=1.0
//
////NEW 05MAY03
//#include "SANSPreferences"				version>=1.0 
//
////NEW 14MAY03
//#include "Subtract_1D"				version>=1.0 