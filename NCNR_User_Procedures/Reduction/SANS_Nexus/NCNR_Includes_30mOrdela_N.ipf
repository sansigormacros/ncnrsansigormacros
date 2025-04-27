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

Menu "NEXUS Ordela SANS MODE"
End

// In the Nexus file, the Ordela detector is treated as if it was tubes
// with nonlinear corrections (=linear), but this flag chooses the corrections
// that are specific to the Ordela detetor rather than tubes
// -- for the 10m instrument, ksDetType = "Tubes"
StrConstant ksDetType = "Ordela"



#include "NCNR_Includes_Nexus"



