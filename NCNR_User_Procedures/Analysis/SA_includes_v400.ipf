#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.0
#pragma IgorVersion=6.1


// now simply point to the current version of the includes v410
// -- then if this file is open, I'll know the experiment is "old"
#include "SA_includes_v410"

////*************
//// the list of files to include in the SANS reduction experiment
////  - files must be located somewhere in the User Procedures folder
//// or sub-folders
////
//
////always include the picker
//#include "SANSModelPicker_v40"			version>=4.00
////utility procedures
//#include "GaussUtils_v40"				version>=4.00
//#include "NIST_XML_V40"					//added September 2008
//#include "PlotUtilsMacro_v40"			version>=4.00
//#include "PlotManager_v40"				version>=4.00
//#include "NCNR_GenFitUtils"			// April 2009, compiles OK if XOP not present
//#include "NCNR_Utils"
//
//#include "USANS_SlitSmearing_v40"
//#include "WriteModelData_v40"
//#include "Wrapper_v40"
//#include "PlotUtils2D_v40"
//#include "GizmoCylinder_v40"
//
//#include "CheckVersionFTP"				//added June 2008
//
//#include "DataSetHandling"					//added Nov 2009 AJJ
//
//Menu "SANS Models"
//	"Fit Manager", Init_WrapperPanel()
//	"Load Model Functions",Execute/P "INSERTINCLUDE \"SANSModelPicker_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "ModelPicker_Panel()"
//	"Load and Plot Manager", Show_Plot_Manager()
//	"Freeze Model"
//	"Write Model Data"
//	"ReWrite Experimental Data",ReWrite1DData()
//	"1D Arithmetic Panel",MakeDAPanel()
//	"-"
//	Submenu "Packages"
//		"Sum Two Models",Execute/P "INSERTINCLUDE \"SumSANSModels_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "Init_SumModelPanel()"
//		"Global Fitting",Execute/P "INSERTINCLUDE \"GlobalFit2_NCNR_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "WM_NewGlobalFit1#InitNewGlobalFitPanel()"
//		"Simple Global Fitting",Execute/P "INSERTINCLUDE \"GlobalFit2_NCNR_v40\"";Execute/P "INSERTINCLUDE \"SimpleGlobalFit_NCNR_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "Init_SimpleGlobalFit()"
//		"Determine Invariant",Execute/P "INSERTINCLUDE \"Invariant_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "Make_Invariant_Panel()"
//		"Do Linear Fits",Execute/P "INSERTINCLUDE \"LinearizedFits_v40\"";Execute/P "COMPILEPROCEDURES ";Execute/P "A_OpenFitPanel()"
//		GenOpFlagEnable()+"Genetic Optimization Enabled", Init_GenOp()
//		GenOpFlagDisable()+"Genetic Optimization Disabled", UnSet_GenOp()
//	End
//	"-"
//	Submenu "2D Utilities"
//		"Generate Fake QxQy Data",FakeQxQy()
//		"Show Cylinder Orientation"
//		"Change Angle"
//	end
//	"-"
//	"NCNR Preferences",Show_Preferences_Panel()
//	"Feedback or Bug Report",OpenTracTicketPage()
//	"Open Help Movie Page",OpenHelpMoviePage()
//	"Check for Updates",CheckForLatestVersion()
//End
//
