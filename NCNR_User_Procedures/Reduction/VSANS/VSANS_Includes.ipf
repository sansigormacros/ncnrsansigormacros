#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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

// for possible peak fitting
#include "BroadPeak_Pix_2D"