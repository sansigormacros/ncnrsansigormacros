#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.2

// load/unload courtesy of Jan Ilavsky
// June 2008
//
// - SRK Oct 2008
// rather than deleting the macros, it is preferable to simply hide the appropriate panels. 
// deleting the ipf files will break dependencies, leave panels hanging open without
// their associated procedures, etc.
//
// names of everything have been changed so I won't clash with Jan's code
// - make this an independent module in case of bad compilation...?
//
//
// a "(" anywhere in the menuItemString will disable that menu item
// <U underlines, <U bolds (?? maybe use these to show which is actually loaded)

// SRK OCT 2019
// -- removed HFIR SANS Reduction loader. HFIR data uses XML, but the XML XOP is no longer supported.
//  the XML XOP is not available on Igor 8 (or 7), and is not worth the effort to maintain - especially
//  since Andy Nelson can't do it any longer. Comment out the loader, and see if anyone notices.
//
// HANARO SANS loader is also commented out - they made their own revisions of the code,
//  and did not share them back with me (I'm OK with that), but they aren't on the list any more
// since my code is out-of-date with theirs.
//
//  SRK JUNE 2021
// 	With the upcoming change to the NCNR raw data format to Nexus (driven by the detector change
//		on the 10m SANS), each of the SANS instruments will require different processing - to some
//		extent - since the detectors will be different, and the Nexus format will allow for, and require
//		some different processing possibilities. The different loaders must be mutually exclusive,
//			such that multiple SANS reduction packages can't be loaded at the same time
//
//


Menu "Macros"
	"-"
	StrVarOrDefault("root:Packages:NCNRItemStr1a","Load NCNR Analysis Macros"), NCNR_AnalysisLoader(StrVarOrDefault("root:Packages:NCNRItemStr1a","Load NCNR Analysis Macros"))
//	StrVarOrDefault("root:Packages:NCNRItemStr1b","-"), NCNR_AnalysisLoader(StrVarOrDefault("root:Packages:NCNRItemStr1b","-"))

	Submenu	"Load SANS Reduction Macros"
		StrVarOrDefault("root:Packages:NCNRItemStr2a","Load NCNR SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2a","Load NCNR SANS Reduction Macros"))
		StrVarOrDefault("root:Packages:NCNRItemStr2b","Load QUOKKA SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2b","Load QUOKKA SANS Reduction Macros"))
		StrVarOrDefault("root:Packages:NCNRItemStr2c","Load ILL SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2c","Load ILL SANS Reduction Macros"))
//		StrVarOrDefault("root:Packages:NCNRItemStr2d","Load HFIR SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2d","Load HFIR SANS Reduction Macros"))
//		StrVarOrDefault("root:Packages:NCNRItemStr2e","Load HANARO SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2e","Load HANARO SANS Reduction Macros"))
//		StrVarOrDefault("root:Packages:NCNRItemStr2b","-"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2b","-"))	
	End
	
	Submenu	"Load USANS Reduction Macros"
		StrVarOrDefault("root:Packages:NCNRItemStr3a","Load NCNR USANS Reduction Macros"), NCNR_USANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr3a","Load NCNR USANS Reduction Macros"))
		StrVarOrDefault("root:Packages:NCNRItemStr3b","Load HANARO USANS Reduction Macros"), NCNR_USANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr3b","Load HANARO USANS Reduction Macros"))
//		StrVarOrDefault("root:Packages:NCNRItemStr3b","-"), NCNR_USANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr3b","-"))
	End
	
	StrVarOrDefault("root:Packages:NCNRItemStr4a","Load NCNR SANS Live Data"), NCNR_SANSLiveLoader(StrVarOrDefault("root:Packages:NCNRItemStr4a","Load NCNR SANS Live Data"))
//	StrVarOrDefault("root:Packages:NCNRItemStr4b","-"), NCNR_SANSLiveLoader(StrVarOrDefault("root:Packages:NCNRItemStr4b","-"))

	// for testing ONLY
	"-"
	"Load SANS Polarization Reduction",PolarizationLoader()
	"Load Real Space Modeling",RealSpaceLoader()
	"Event Mode Processing",EventModeLoader()
	"Load Batch Fitting - Beta",BatchFitLoader()
	"Load Simulation Run Builder",SimSANSRunListLoader()
	"Automated SANS Reduction - Beta",AutomateSANSLoader()
	"-"
	"Load VSANS Procedures",VSANSLoader()
	"-"
	"Load HDF5 SANS Testing",LoadHDF5SANS()


end

//
// returns 1==true if any conflicting package is about to be loaded
//
//
// loaded is the currently loaded package that you are testing against everything else
//
Function ConflictingPackage(loaded)
	String loaded

	String possible
	possible = "ILL_D22;NCNR;QUOKKA;NCNR_USANS;NCNR_Nexus;NCNR_VSANS;"
	
	Variable conflict=0,num,ii
	possible = RemoveFromList(loaded,possible)
	
	num = ItemsInList(possible)
	for(ii=0;ii<num;ii+=1)
		if(exists(stringFromList(ii,possible))==6)
			conflict +=1
		endif
	endfor
	
	if(conflict > 0)
		return(1)
	else
		return(0)
	endif

End


Proc LoadHDF5SANS()

	if(ConflictingPackage("NCNR_Nexus"))
		DoAlert 0,"A SANS or USANS reduction package is already loaded. Please open a new experiment if you want to switch instruments."	
	else

		Execute/P "INSERTINCLUDE \"NCNR_Includes_v520_HDF5_N\""
		Execute/P "COMPILEPROCEDURES "
		Execute/P ("Initialize()")
	//			Execute/P ("PickPath()")
		Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")
	endif
End


Function NCNR_AnalysisLoader(itemStr)
	String itemStr
		
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.2)
		Abort "Your version of Igor is lower than 6.2, these macros need version 6.2 or higher.... "
	endif
	
	NewDataFolder/O root:Packages 		//create the folder for string variable
	String/G root:Packages:NCNRItemStr1a = itemStr
	String/G root:Packages:NCNRItemStr1b = itemStr
	SVAR gMenuStr1a = root:Packages:NCNRItemStr1a
	SVAR gMenuStr1b = root:Packages:NCNRItemStr1b
	
	String SANSAna_WinList = "wrapperPanel;Procedure_List;Report;Plot_Manager;A_FitPanel;A_FitWindow;Sum_Model_Panel;"
	SANSAna_WinList += "NewGlobalFitPanel;SimpGFPanel;Invariant_Panel;invariant_graph;"
	strswitch(itemStr)	// string switch
		case "Load NCNR Analysis Macros":	
			Execute/P "INSERTINCLUDE \"SA_Includes_v410\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Init_WrapperPanel()")
			Execute/P ("ModelPicker_Panel()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")
		
			gMenuStr1a = "Hide NCNR Analysis Macros"
//			gMenuStr1b = "Unload NCNR Analysis Macros"
			gMenuStr1b = "-"
			BuildMenu "Macros"
			
			break						
		case "Unload NCNR Analysis Macros":	
		// very dangerous - don't really want to implement this because it will surely crash
			Execute/P "DELETEINCLUDE \"SA_Includes_v410\""
			Execute/P "COMPILEPROCEDURES "
			DoWindow wrapperPanel
			if(V_Flag)
				DoWindow/K wrapperPanel
			endif
			DoWindow Procedure_List
			If(V_Flag)
				DoWindow/K Procedure_List
			endif

			gMenuStr1a = "Load NCNR Analysis Macros"
			gMenuStr1b = "-"
			
			BuildMenu "Macros"
			
			break
		case "Hide NCNR Analysis Macros":	
			HideShowWindowsInList(SANSAna_WinList,1)	
		
			gMenuStr1a = "Show NCNR Analysis Macros"
//			gMenuStr1b = "Unload NCNR Analysis Macros"
			gMenuStr1b = "-"
			BuildMenu "Macros"
			
			break
		case "Show NCNR Analysis Macros":
			HideShowWindowsInList(SANSAna_WinList,0)	
		
			gMenuStr1a = "Hide NCNR Analysis Macros"
//			gMenuStr1b = "Unload NCNR Analysis Macros"
			gMenuStr1b = "-"
			BuildMenu "Macros"
			
			break
		default:
			Abort "Invalid Menu Selection"
	endswitch

end


// now add for the SANS Reduction
// a = NCNR
// b = QUOKKA
// c = ILL
// d = HFIR
// e = HANARO
//
Function NCNR_SANSReductionLoader(itemStr)
	String itemStr
	
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.2)
		Abort "Your version of Igor is lower than 6.2, these macros need version 6.2 or higher.... "
	endif
	
	// check for ANY SANS package being loaded. if any one is loaded, nothing else can be loaded
	//
	if(ConflictingPackage(""))
//	if( exists("ILL_D22")==6 || exists("NCNR")==6 || exists("QUOKKA")==6 )
		DoAlert 0,"A SANS or USANS reduction package is already loaded. Please open a new experiment if you want to switch instruments."
		return(0)
	endif
	
	
	
	NewDataFolder/O root:Packages 		//create the folder for string variable

	String/G root:Packages:NCNRItemStr2a = "Load NCNR SANS Reduction Macros"
	String/G root:Packages:NCNRItemStr2b = "Load QUOKKA SANS Reduction Macros"
	String/G root:Packages:NCNRItemStr2c = "Load ILL SANS Reduction Macros"
	String/G root:Packages:NCNRItemStr2d = "Load HFIR SANS Reduction Macros"
	String/G root:Packages:NCNRItemStr2e = "Load HANARO SANS Reduction Macros"
	SVAR gMenuStr2a = root:Packages:NCNRItemStr2a
	SVAR gMenuStr2b = root:Packages:NCNRItemStr2b
	SVAR gMenuStr2c = root:Packages:NCNRItemStr2c
	SVAR gMenuStr2d = root:Packages:NCNRItemStr2d
	SVAR gMenuStr2e = root:Packages:NCNRItemStr2e
	
	String SANSRed_WinList = "Main_Panel;CatVSTable;SANS_Data;Plot_Manager;Average_Panel;Plot_1d;CatWin;Surface_3D;FitPanel;FitWindow;"
	SANSRed_WinList += "FitRPAPanel;SANS_Histo;drawMaskWin;Multiple_Reduce_Panel;NSORT_Panel;NSORT_Graph;CombineTable;ToCombine;Patch_Panel;"
	SANSRed_WinList += "ProtocolPanel;Schematic_Layout;Tile_2D;RAW_to_ASCII;Trans_Panel;TransFileTable;ScatterFileTable;Convert_to_Trans;"
	SANSRed_WinList += "WorkFileMath;Pref_Panel;Subtract_1D_Panel;Plot_Sub1D;SASCALC;MC_SASCALC;Saved_Configurations;TISANE;Sim_1D_Panel;"
	SANSRed_WinList += "Trial_Configuration;Saved_Configurations;DataArithmeticPanel;DAPlotPanel;"
	strswitch(itemStr)	// string switch
	
		case "Load NCNR SANS Reduction Macros":
			Execute/P "INSERTINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
//			Execute/P ("PickPath()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others		
			gMenuStr2a = "Hide NCNR SANS Reduction Macros"
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"
			break		
			
		case "Load QUOKKA SANS Reduction Macros":
//			DoAlert 0, "QUOKKA macros not in SVN yet - NCNR macros loaded instead"
//			Execute/P "INSERTINCLUDE \"Includes_v520\""
			Execute/P "INSERTINCLUDE \"QKK_Includes_ANSTO\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
			Execute/P ("Init_MainUSANS()")					 
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b = "Hide QUOKKA SANS Reduction Macros"
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Load ILL SANS Reduction Macros":
			Execute/P "INSERTINCLUDE \"ILL_Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c = "Hide ILL SANS Reduction Macros"
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"	
			break
			
		case "Load HFIR SANS Reduction Macros":	
			Execute/P "INSERTINCLUDE \"HFIR_Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d = "Hide HFIR SANS Reduction Macros"
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Load HANARO SANS Reduction Macros":	
		Print "HANARO not loaded into SVN yet. NCNR is loaded"
			Execute/P "INSERTINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "Hide HANARO SANS Reduction Macros"

			BuildMenu "Macros"
			break
						
////////////
		case "Hide NCNR SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)

			// change the facility label, disable the others		
			gMenuStr2a = "Show NCNR SANS Reduction Macros"			
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("			
			
			BuildMenu "Macros"
			break
			
		case "Hide QUOKKA SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)

			// change the facility label, disable the others		
			gMenuStr2a += "("			
			gMenuStr2b = "Show QUOKKA SANS Reduction Macros"
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("			
			
			BuildMenu "Macros"
			break			

		case "Hide ILL SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)

			// change the facility label, disable the others		
			gMenuStr2a += "("			
			gMenuStr2b += "("
			gMenuStr2c = "Show ILL SANS Reduction Macros"
			gMenuStr2d += "("
			gMenuStr2e += "("			
			
			BuildMenu "Macros"
			break

		case "Hide HFIR SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)

			// change the facility label, disable the others		
			gMenuStr2a += "("			
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d = "Show HFIR SANS Reduction Macros"
			gMenuStr2e += "("			
			
			BuildMenu "Macros"
			break

		case "Hide HANARO SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)

			// change the facility label, disable the others		
			gMenuStr2a += "("			
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e = "Show HANARO SANS Reduction Macros"			
			
			BuildMenu "Macros"
			break

///////////////			
		case "Show NCNR SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)

			// change the facility label, disable the others		
			gMenuStr2a = "Hide NCNR SANS Reduction Macros"
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Show QUOKKA SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b = "Hide QUOKKA SANS Reduction Macros"
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Show ILL SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c = "Hide ILL SANS Reduction Macros"
			gMenuStr2d += "("
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Show HFIR SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d = "Hide HFIR SANS Reduction Macros"
			gMenuStr2e += "("

			BuildMenu "Macros"
			break
			
		case "Show HANARO SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)

			// change the facility label, disable the others		
			gMenuStr2a += "("
			gMenuStr2b += "("
			gMenuStr2c += "("
			gMenuStr2d += "("
			gMenuStr2e = "Hide HANARO SANS Reduction Macros"

			BuildMenu "Macros"
			break
			
			
//		case "Unload NCNR SANS Reduction Macros":	
//		// very dangerous - don't really want to implement this because it will surely crash
//			Execute/P "DELETEINCLUDE \"Includes_v520\""
//			Execute/P "COMPILEPROCEDURES "
//			DoWindow Main_Panel
//			if(V_Flag)
//				DoWindow/K Main_Panel
//			endif
//
//			gMenuStr2a = "Load NCNR SANS Reduction Macros"
//			gMenuStr2b = "-"
//			
//			BuildMenu "Macros"
//			
//			break			
			
		default:
			Abort "Invalid Menu Selection"
	endswitch

end

// now add for the USANS Reduction
// a = NCNR
// b = HANARO
Function NCNR_USANSReductionLoader(itemStr)
	String itemStr
	
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.2)
		Abort "Your version of Igor is lower than 6.2, these macros need version 6.2 or higher.... "
	endif


// if the SANS_Nexus package is loaded, don't load in USANS
	// check for ANY SANS package being loaded. if any one is loaded, nothing else can be loaded
	//
	if(ConflictingPackage("NCNR_USANS"))
		DoAlert 0,"A SANS or USANS reduction package is already loaded. Please open a new experiment if you want to switch instruments."
		return(0)
	endif


	
	NewDataFolder/O root:Packages 		//create the folder for string variable
	String/G root:Packages:NCNRItemStr3a = "Load NCNR USANS Reduction Macros"
	String/G root:Packages:NCNRItemStr3b = "Load HANARO USANS Reduction Macros"
	SVAR gMenuStr3a = root:Packages:NCNRItemStr3a
	SVAR gMenuStr3b = root:Packages:NCNRItemStr3b
	
	String USANS_WinList = "USANS_Panel;COR_Graph;RawDataWin;Desmear_Graph;USANS_Slope;UCALC;"
	
	strswitch(itemStr)	// string switch
		case "Load NCNR USANS Reduction Macros":	
			Execute/P "INSERTINCLUDE \"NCNR_USANS_Includes_v230\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("ShowUSANSPanel()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

//			Execute/P ("Show_Preferences_Panel()")
//			Execute/P ("PrefTabProc(\"PrefTab\",  2)")		//show the USANS tab
			
			// change the facility label, disable the others		
			gMenuStr3a = "Hide NCNR USANS Reduction Macros"
			gMenuStr3b += "("
			
			BuildMenu "Macros"
			break	
			
		case "Load HANARO USANS Reduction Macros":	
			Execute/P "INSERTINCLUDE \"KIST_USANS_Includes_v230\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("ShowUSANSPanel()")
			Execute/P ("DoIgorMenu \"Control\" \"Retrieve All Windows\"")

			// change the facility label, disable the others
			gMenuStr3a += "("
			gMenuStr3b = "Hide HANARO USANS Reduction Macros"
			
			BuildMenu "Macros"
			break	
							
///////////////////

		case "Hide NCNR USANS Reduction Macros":	
			HideShowWindowsInList(USANS_WinList,1)	

			// change the facility label, disable the others		
			gMenuStr3a = "Show NCNR USANS Reduction Macros"
			gMenuStr3b += "("
					
			BuildMenu "Macros"
			break
			
		case "Hide HANARO USANS Reduction Macros":	
			HideShowWindowsInList(USANS_WinList,1)	

			// change the facility label, disable the others
			gMenuStr3a += "("
			gMenuStr3b = "Show HANARO USANS Reduction Macros"
					
			BuildMenu "Macros"
			break

///////////////////
		case "Show NCNR USANS Reduction Macros":
			HideShowWindowsInList(USANS_WinList,0)	

			// change the facility label, disable the others		
			gMenuStr3a = "Hide NCNR USANS Reduction Macros"
			gMenuStr3b += "("
						
			BuildMenu "Macros"
			break
			
		case "Show HANARO USANS Reduction Macros":
			HideShowWindowsInList(USANS_WinList,0)	

			// change the facility label, disable the others	
			gMenuStr3a += "("
			gMenuStr3b = "Hide HANARO USANS Reduction Macros"
						
			BuildMenu "Macros"
			break
			
			
//		case "Unload NCNR USANS Reduction Macros":	
//		// very dangerous - don't really want to implement this because it will surely crash
//			Execute/P "DELETEINCLUDE \"USANS_Includes_v230\""
//			Execute/P "COMPILEPROCEDURES "
//			DoWindow USANS_Panel
//			if(V_Flag)
//				DoWindow/K USANS_Panel
//			endif
//
//			gMenuStr3a = "Load NCNR USANS Reduction Macros"
//			gMenuStr3b = "-"
//			
//			BuildMenu "Macros"
//			
//			break			
		default:
			Abort "Invalid Menu Selection"
	endswitch
	
end

// 1 = hide, 0 = show
Function HideShowWindowsInList(list,hide)
	String list
	Variable hide
	
	String item
	Variable ii,num=ItemsinList(list)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		DoWindow $item
		if(V_Flag)
			DoWindow/HIDE=(hide) $item
		endif
	endfor
	return(0)
End

// now add for the SANS Live
Function NCNR_SANSLiveLoader(itemStr)
	String itemStr
	
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.2)
		Abort "Your version of Igor is lower than 6.2, these macros need version 6.2 or higher.... "
	endif
	
	NewDataFolder/O root:Packages 		//create the folder for string variable
	String/G root:Packages:NCNRItemStr4a = itemStr
	String/G root:Packages:NCNRItemStr4b = itemStr
	SVAR gMenuStr4a = root:Packages:NCNRItemStr4a
	SVAR gMenuStr4b = root:Packages:NCNRItemStr4b
	
	String SANSLive_WinList = "RT_Panel;SANS_Data;"
	//SANSLive_WinList += "FitRPAPanel;SANS_Histo;drawMaskWin;Multiple_Reduce_Panel;NSORT_Panel;NSORT_Graph;CombineTable;ToCombine;Patch_Panel;"
	//SANSLive_WinList += "ProtocolPanel;Schematic_Layout;Tile_2D;RAW_to_ASCII;Trans_Panel;TransFileTable;ScatterFileTable;Convert_to_Trans;"
	//SANSLive_WinList += "WorkFileMath;Pref_Panel;Subtract_1D_Panel;Plot_Sub1D;SASCALC;MC_SASCALC;Saved_Configurations;TISANE;"
	strswitch(itemStr)	// string switch
		case "Load NCNR SANS Live Data":	
			Execute/P "INSERTINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Init_for_RealTime()")
		
			gMenuStr4a = "Hide NCNR SANS Live Data"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr4b = "-"
			BuildMenu "Macros"
			
			break						
		case "Unload NCNR SANS Live Data":	
		// very dangerous - don't really want to implement this because it will surely crash
			Execute/P "DELETEINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			DoWindow Main_Panel
			if(V_Flag)
				DoWindow/K Main_Panel
			endif

			gMenuStr4a = "Load NCNR SANS Live Data"
			gMenuStr4b = "-"
			
			BuildMenu "Macros"
			
			break
		case "Hide NCNR SANS Live Data":
			HideShowWindowsInList(SANSLive_WinList,1)
		
			gMenuStr4a = "Show NCNR SANS Reduction Macros"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr4b = "-"
			BuildMenu "Macros"
			
			break
		case "Show NCNR SANS Reduction Macros":	
			HideShowWindowsInList(SANSLive_WinList,0)
		
			gMenuStr4a = "Hide NCNR SANS Reduction Macros"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr4b = "-"
			BuildMenu "Macros"
			
			break
		default:
			Abort "Invalid Menu Selection"
	endswitch

end

Function WhatSymbolsAreDefined()

#if (exists("QUOKKA")==6)
		print "yes function QUOKKA defined"
#else
		print "function QUOKKA NOT defined"
#endif
	
#if(exists("HFIR")==6)
		print "yes function HFIR defined"
#else
		print "function HFIR NOT defined"
#endif
	
#if(exists("ILL_D22")==6)
		print "yes function ILL_D22 defined"
#else
		print "function ILL_D22 NOT defined"
#endif

#if(exists("NCNR")==6)
		print "yes function NCNR defined"
#else
		print "function NCNR NOT defined"
#endif

#if(exists("NCNR_USANS")==6)
		print "yes function NCNR_USANS defined"
#else
		print "function NCNR_USANS NOT defined"
#endif

#if(exists("NCNR_Nexus")==6)
		print "yes function NCNR_Nexus defined"
#else
		print "function NCNR_Nexus NOT defined"
#endif



// for a lot of reasons, defined symbols do not work
// mostly, the procedures are compiled before the symbols are
// defined (or re-defined)
// another issues is that they are persistent, and  don't disappear
// until Igor is quit. 
	
//	SetIgorOption poundDefine=QUOKKA?
//	if(V_flag)
//		print "QUOKKA defined"
//	else
//		print "QUOKKA NOT defined"
//	endif
//	
//	SetIgorOption poundDefine=HFIR?
//	if(V_flag)
//		print "HFIR defined"
//	else
//		print "HFIR NOT defined"
//	endif
//	
//	SetIgorOption poundDefine=ILL_D22?
//	if(V_flag)
//		print "ILL_D22 defined"
//	else
//		print "ILL_D22 NOT defined"
//	endif

	return(0)
End

Proc ClearDefinedSymbols()
	SetIgorOption poundUnDefine=QUOKKA
	SetIgorOption poundUnDefine=HFIR
	SetIgorOption poundUnDefine=ILL_D22
End

Function PolarizationLoader()

	// be sure that the SANS reduction is loaded and compiles
	NCNR_SANSReductionLoader("Load NCNR SANS Reduction Macros")
	
	// then the polarization
	Execute/P "INSERTINCLUDE \"Include_Polarization\"";Execute/P "COMPILEPROCEDURES "
	BuildMenu "Macros"

	return(0)
End

// loads all of the FFT procedures and the fit functions too
Function RealSpaceLoader()

	// be sure that the SANS Analysis is loaded and compiles
	NCNR_AnalysisLoader("Load NCNR Analysis Macros")
	
	// then the FFT files
	Execute/P "INSERTINCLUDE \"FFT_Cubes_Includes\""
	Execute/P "INSERTINCLUDE \"FFT_Fit_Includes\""
	Execute/P "COMPILEPROCEDURES "
	Execute/P "Init_FFT()"
	
	BuildMenu "Macros"

	return(0)
End

Function EventModeLoader()

	// be sure that the SANS reduction is loaded and compiles
	NCNR_SANSReductionLoader("Load NCNR SANS Reduction Macros")
	
	// then bring up the Event Mode panel
	Execute/P "Show_Event_Panel()"
//	BuildMenu "Macros"

	return(0)
End


// loads the Analysis package, then the AutoFit procedure
Function BatchFitLoader()

	// be sure that the SANS Analysis is loaded and compiles
	NCNR_AnalysisLoader("Load NCNR Analysis Macros")
	
	// then the AutoFit files
	Execute/P "INSERTINCLUDE \"Auto_Fit\""
	Execute/P "COMPILEPROCEDURES "
	Execute/P "InitializeAutoFitPanel()"
	
	BuildMenu "Macros"

	return(0)
End

// loads the Reduction package, then the Auto_Reduction panel
Function AutomateSANSLoader()

	// be sure that the SANS reduction is loaded and compiles
	NCNR_SANSReductionLoader("Load NCNR SANS Reduction Macros")
	
	// then bring up the Auto_reduction panel
	Execute/P "Auto_Reduce_Panel()"
	
	return(0)
End



// for SANS simulation scripting, need to load the reduction, analysis, 
// then the two scripting procedures
//
// -- this is to avoid the entanglement betwen analysis models and SASCALC (in reduction)
//
Function SimSANSRunListLoader()

	// be sure that the SANS reduction is loaded and compiles
	NCNR_SANSReductionLoader("Load NCNR SANS Reduction Macros")
	
	// be sure that the SANS Analysis is loaded and compiles
	NCNR_AnalysisLoader("Load NCNR Analysis Macros")
	
	// then the Scripting files
	Execute/P "INSERTINCLUDE \"MC_SimulationScripting\""
	Execute/P "INSERTINCLUDE \"MC_Script_Panels\""
	Execute/P "COMPILEPROCEDURES "
//	Execute/P "InitializeAutoFitPanel()"
	
	BuildMenu "Macros"
	return(0)
End


// loads the VSANS package and initializes
Function VSANSLoader()
	
	
	if(ConflictingPackage("NCNR_USANS"))
		DoAlert 0,"A SANS reduction package is already loaded. Please open a new experiment if you want to switch instruments."	
		return(0)
	else
	
		Execute/P "INSERTINCLUDE \"VSANS_Includes\""
		Execute/P "COMPILEPROCEDURES "
		Execute/P "Initialize_VSANS()"
		
		BuildMenu "Macros"

		return(0)
	endif
End

