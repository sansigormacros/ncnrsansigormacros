#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.1


// to properly set up the template for other facility reduction templates, 
// function KIST_USANS() must exist here in the Includes file.
//
Function KIST_USANS()
	//does nothing but define KIST_USANS()
	return(0)
End




//*************
// the list of files to include in the USANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//

#include "BT5_Loader",version >= 2.20	
#include "COR_Graph",version >= 2.20			
#include "Main_USANS",version >= 2.20	
#include "PlotUtilsMacro_v40",version >= 2.20
#include "NIST_XML_v40"						//cansas file writer
#include "USANS_SlitSmearing_v40"	
#include "WriteUSANSData",version >= 2.20	
#include "LakeDesmearing_JB",version >= 2.20	
#include "USANSCatNotebook",version >= 2.20	
#include "CheckVersionFTP"				//added June 2008
#include "GaussUtils_v40"				//added Oct 2008 for unified file loading
#include "BT5_AddFiles"					//Oct 2009 to add raw data files
#include "KIST_USANS_Utils"					//USANS-specific initialization
#include "KIST_Utils"					// from the SANS reduction, needed only for XML to compile


// USANS simulation and required procedures
#include "U_CALC"
#include "USANS_EmptyWaves"
#include "MultScatter_MonteCarlo_2D"
#include "SASCALC"
#include "KIST_DataReadWrite"				// needed in part for USANS simulator
#include "SANS_Utilities"
#include "MultipleReduce"
#include "WriteQIS"

//AJJ for data set output
#include "DataSetHandling"
#Include "WriteModelData_v40"
#include "PlotManager_v40"

#include "NIST_NXcanSAS_v709"
#include "WriteUSANSNXcanSAS"          //NXcanSAS file writer


// new utility MAR 2023
#include "Rescale_RAW_USANS"
