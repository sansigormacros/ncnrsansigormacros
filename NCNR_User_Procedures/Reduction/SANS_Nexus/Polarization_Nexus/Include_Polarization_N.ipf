#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

//
// files to include after the SANS reduction has been loaded to
// load in the procedures necessary for reduction of polarized
// beam data

// JUN 2011 SRK

//#include "Pol_PolCorr"
#include "Pol_PolarizationPanels_N"
#include "Pol_PolarizationCorrection_N"
#include "Pol_FlipperPanel_N"
