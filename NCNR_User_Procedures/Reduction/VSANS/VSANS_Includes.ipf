#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// to properly set up the template for other facility reduction templates,
// function NCNR_VSANS() must exist here in the Includes file.
//
Function NCNR_VSANS()

	//does nothing but define NCNR()
	return (0)
End

// These files are COMMON NCNR FILES
// the first three are necessary for loading and plotting of 1D data sets
// using the PlotManager, including loading of slit-smeared VSANS data
#include "PlotUtilsMacro_v40"
#include "PlotManager_v40"
#include "GaussUtils_v40"
#include "NIST_XML_v40"
#include "NIST_NXcanSAS_v709"
#include "USANS_SlitSmearing_v40"

#include "V_PlotUtils2D_VSANS" // basic loaders for the QxQyASCII exported VSANS data

//
//#include "NCNR_Utils"		//needed to load linear fits, mostly VAX file name junk
//#include "LinearizedFits_v40"		//won't compile - needs NCNR_Utils (then starts a chain of dependencies...)

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
#include "Vx_NexusFromIgor" //AUG2015 - depricated, but keep for now

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
#include "V_Write_VSANS_NXcanSAS"
#include "V_2DLoader_NXcanSAS" //JUL 2020 load/plot 2D--NXcanSAS

// start of VSANS reduction procedures
#include "V_Initialize"
#include "V_MainPanel"
#include "V_Menu"
#include "V_VSANS_Preferences"
#include "V_WorkFolderUtils"

// start of raw data display panel
#include "V_RAW_Data_Panel" // rename this later when it's done
#include "V_Utilities_General" //
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
#include "V_Combine_1D"
#include "V_Transmission"

#include "V_MultipleReduce"
#include "V_EventMode_Utils"
#include "V_EventModeProcessing"

//
#include "V_Instrument_Resolution"
#include "V_IQ_Annular"
#include "V_Write_VSANS_QIS"

//
#include "V_Attenuation"

// for loading of slit-smeared VSANS data
// and generating the smearing matrix
// as of MAY 2018, this has been merged with USANS_SlitSmearing_v40.ipf
//#include "V_USANS_SlitSmearing_v40"

// for smearing of White beam data
//
#include "V_WhiteBeamSmear"
#include "V_WhiteBeamDistribution"
#include "V_DummyFunctions"
// VSANS Analysis functions (under Analysis trunk, not Reduction)
#include "V_WB_BroadPeak"
#include "V_SWB_BroadPeak"
#include "V_WB_GaussSpheres"
#include "V_SWB_GaussSpheres"
#include "V_WB_Beaucage"
#include "V_SWB_Beaucage"

#include "V_Utilities_Comparisons"
#include "V_Sector_Average"
#include "V_TemperatureSensor"

// new utility to recalculate the smearing matrix for VSANS files
#include "V_VSANS_ResMatrix"

