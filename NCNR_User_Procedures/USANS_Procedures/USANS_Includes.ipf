#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.0

//*************
// the list of files to include in the USANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//

#include "BT5_Loader",version >= 2.20	
#include "COR_Graph",version >= 2.20			
#include "Main_USANS",version >= 2.20	
#include "PlotUtils_USANS",version >= 2.20	
#include "WriteUSANSData",version >= 2.20	
#include "LakeDesmearing_JB",version >= 2.20	
#include "USANSCatNotebook",version >= 2.20	
