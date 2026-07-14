#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma version=5.0
#pragma IgorVersion=6.1

// removing this to avoid RT errors when str2num gets an invalid input
// (doing this on purpose to test for a valid run number)
// #pragma rtFunctionErrors=1


// RTI clean

//
// *** modified JUNL2014 to work with HDF5 raw data files.
//    when finally implemented, be sure to compare with NCNR_Utils.ipf
//    to pick up any changes there, especially those related to CGB
//
//

// this file contains globals and functions that are specific to a
// particular facility or data file format
// branched out 29MAR07 - SRK
//
// functions are either labeled with the procedure file that calls them,
// or noted that they are local to this file

// initializes globals that are specific to a particular facility
// - number of XY pixels
// - pixexl resolution [cm]
// - detector deadtime constant [s]
//
// called by Initialize.ipf
//
// 2025
//  most of these constants are --no longer used, use values in file instead
//  or values are set by constants when switching on "Ordela" or "Tubes"
//
Function N_InitFacilityGlobals()

	//Detector -specific globals
	//	Variable/G root:myGlobals:gNPixelsX=128
	//	Variable/G root:myGlobals:gNPixelsY=128

	// as of Jan2008, detector pixel sizes are read directly from the file header, so they MUST
	// be set correctly in instr.cfg - these values are not used, but declared to avoid errors
	variable/G root:myGlobals:PixelResNG3_ILL  = 1.0 //pixel resolution in cm
	variable/G root:myGlobals:PixelResNG5_ILL  = 1.0
	variable/G root:myGlobals:PixelResNG7_ILL  = 1.0
	variable/G root:myGlobals:PixelResNG3_ORNL = 0.5
	variable/G root:myGlobals:PixelResNG5_ORNL = 0.5
	variable/G root:myGlobals:PixelResNG7_ORNL = 0.5
	variable/G root:myGlobals:PixelResNGB_ORNL = 0.5
	//	Variable/G root:myGlobals:PixelResCGB_ORNL = 0.5		// fiction

	variable/G root:myGlobals:PixelResDefault = 0.5

	variable/G root:myGlobals:DeadtimeNG3_ILL      = 3.0e-6 //deadtime in seconds
	variable/G root:myGlobals:DeadtimeNG5_ILL      = 3.0e-6
	variable/G root:myGlobals:DeadtimeNG7_ILL      = 3.0e-6
	variable/G root:myGlobals:DeadtimeNGB_ILL      = 4.0e-6 // fictional
	variable/G root:myGlobals:DeadtimeNG3_ORNL_VAX = 3.4e-6 //pre - 23-JUL-2009 used VAX
	variable/G root:myGlobals:DeadtimeNG3_ORNL_ICE = 1.5e-6 //post - 23-JUL-2009 used ICE
	variable/G root:myGlobals:DeadtimeNG5_ORNL     = 0.6e-6 //as of 9 MAY 2002
	variable/G root:myGlobals:DeadtimeNG7_ORNL_VAX = 3.4e-6 //pre 25-FEB-2010 used VAX
	variable/G root:myGlobals:DeadtimeNG7_ORNL_ICE = 2.3e-6 //post 25-FEB-2010 used ICE
	variable/G root:myGlobals:DeadtimeNGB_ORNL_ICE = 4.0e-6 //per JGB 16-JAN-2013, best value we have for the oscillating data

	//	Variable/G root:myGlobals:DeadtimeCGB_ORNL_ICE = 1.5e-6		// fiction

	variable/G root:myGlobals:DeadtimeDefault = 3.4e-6

	//new 11APR07
	variable/G root:myGlobals:BeamstopXTol = -8 // (cm) is BS Xpos is -5 cm or less, it's a trans measurement
	// sample aperture offset is NOT stored in the VAX header, but it should be
	// - when it is, remove the global and write an accessor AND make a place for
	variable/G root:myGlobals:apOff = 5.0 // (cm) distance from sample aperture to sample position

End
