#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.1


// to properly set up the template for other facility reduction templates, 
// function NCNR_USANS() must exist here in the Includes file.
//
Function NCNR_USANS()
	//does nothing but define NCNR_USANS()
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
#include "NIST_XML_v40"					//cansas file writer
#include "WriteUSANSNXcanSAS"          //NXcanSAS file writer
#include "USANS_SlitSmearing_v40"	
#include "WriteUSANSData",version >= 2.20	
#include "LakeDesmearing_JB",version >= 2.20	
#include "USANSCatNotebook",version >= 2.20	
#include "CheckVersionFTP"				//added June 2008
#include "GaussUtils_v40"				//added Oct 2008 for unified file loading
#include "BT5_AddFiles"					//Oct 2009 to add raw data files
#include "NCNR_Utils"					//needed for NIST_XML
#include "NCNR_USANS_Utils"					//USANS-specific initialization


// USANS simulation and required procedures
#include "U_CALC"
#include "USANS_EmptyWaves"
#include "MultScatter_MonteCarlo_2D"
#include "SASCALC"
#include "NCNR_DataReadWrite"
#include "SANS_Utilities"
#include "MultipleReduce"
#include "WriteQIS"

//AJJ for data set output
#include "DataSetHandling"
#Include "WriteModelData_v40"
#include "PlotManager_v40"