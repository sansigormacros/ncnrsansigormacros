#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.2
#pragma IgorVersion=6.1

// to properly set up the template for other facility reduction templates, 
// function NCNR() must exist here in the Includes file.
//
Function NCNR_Nexus()
	//does nothing but define NCNR()
	return(0)
End

Menu "NEXUS 10m-SANS MODE"
End

// for the 10m instrument detType is "Tubes" and flags parts of the code to use Tube corrections and
// --if the data is Ordela data "faked" to be tubes then ksDetType = "Ordela" and the proper switches
// can be made to use Ordela corrections (non-linear, dead time, etc.)
StrConstant ksDetType = "Tubes"


#include "NCNR_Includes_Nexus"



