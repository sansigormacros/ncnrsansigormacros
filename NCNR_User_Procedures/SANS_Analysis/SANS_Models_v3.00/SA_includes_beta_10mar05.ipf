#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.2
#pragma IgorVersion=4.0

//*************
// the list of files to include in the SANS reduction experiment
//  - files must be located somewhere in the User Procedures folder
// or sub-folders
//

//always include the picker
#include "SANSModelPicker"	
//utility procedures
#include "GaussUtils"			
#include "PlotUtilsMacro"	


Menu "Macros"
	Submenu "Packages"
		"Model Picker",Execute/P "INSERTINCLUDE \"SANSModelPicker\"";Execute/P "COMPILEPROCEDURES ";Execute/P "ModelPicker_Panel()"
		"-"
		"Sum Two Models",Execute/P "INSERTINCLUDE \"SumSANSModels\"";Execute/P "COMPILEPROCEDURES ";Execute/P "Init_SumModelPanel()"
		"Global Fitting",Execute/P "INSERTINCLUDE \"GlobalFit4_NCNR\"";Execute/P "COMPILEPROCEDURES ";Execute/P "InitGlobalFitPanel()"
		"Determine Invariant",Execute/P "INSERTINCLUDE \"Invariant\"";Execute/P "COMPILEPROCEDURES ";Execute/P "Make_Invariant_Panel()"
		"Do Linear Fits",Execute/P "INSERTINCLUDE \"LinearizedFits\"";Execute/P "COMPILEPROCEDURES ";Execute/P "A_OpenFitPanel()"
	End
End