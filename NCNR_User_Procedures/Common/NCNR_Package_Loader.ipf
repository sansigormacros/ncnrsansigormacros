#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0
//#pragma IndependentModule=NCNRLoader		//can't seem to get this to work properly...

// load/unload courtesy of Jan Ilavsky
// June 2008

// - SRK Oct 2008
// rather than deleting the macros, it is preferable to simply hide the appropriate panels. 
// deleting the ipf files will break dependencies, leave panels hanging open without
// their associated procedures, etc.

// names of everything have been changed so I won't clash with Jan's code
//
//
// - make this an independent module in case of bad compilation...


Menu "Macros"
	StrVarOrDefault("root:Packages:NCNRItemStr1a","Load NCNR Analysis Macros"), NCNR_AnalysisLoader(StrVarOrDefault("root:Packages:NCNRItemStr1a","Load NCNR Analysis Macros"))
	StrVarOrDefault("root:Packages:NCNRItemStr1b","-"), NCNR_AnalysisLoader(StrVarOrDefault("root:Packages:NCNRItemStr1b","-"))

	StrVarOrDefault("root:Packages:NCNRItemStr2a","Load NCNR SANS Reduction Macros"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2a","Load NCNR SANS Reduction Macros"))
	StrVarOrDefault("root:Packages:NCNRItemStr2b","-"), NCNR_SANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr2b","-"))

	StrVarOrDefault("root:Packages:NCNRItemStr3a","Load NCNR USANS Reduction Macros"), NCNR_USANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr3a","Load NCNR USANS Reduction Macros"))
	StrVarOrDefault("root:Packages:NCNRItemStr3b","-"), NCNR_USANSReductionLoader(StrVarOrDefault("root:Packages:NCNRItemStr3b","-"))
end

Function NCNR_AnalysisLoader(itemStr)
	String itemStr
		
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.02)
		Abort "Your version of Igor is lower than 6.02, these macros need version 6.02 or higher.... "
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
			Execute/P "INSERTINCLUDE \"SA_Includes_v400\""
			Execute/P "INSERTINCLUDE \"PlotUtilsMacro_v40\""
			Execute/P "INSERTINCLUDE \"GaussUtils_v40\""
			Execute/P "INSERTINCLUDE \"WriteModelData_v40\""
			Execute/P "INSERTINCLUDE \"USANS_SlitSmearing_v40\""
			Execute/P "INSERTINCLUDE \"SANSModelPicker_v40\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Init_WrapperPanel()")
			Execute/P ("ModelPicker_Panel()")
		
			gMenuStr1a = "Hide NCNR Analysis Macros"
//			gMenuStr1b = "Unload NCNR Analysis Macros"
			gMenuStr1b = "-"
			BuildMenu "Macros"
			
			break						
		case "Unload NCNR Analysis Macros":	
		// very dangerous - don't really want to implement this because it will surely crash
			Execute/P "DELETEINCLUDE \"SA_Includes_v400\""
			Execute/P "DELETEINCLUDE \"PlotUtilsMacro_v40\""
			Execute/P "DELETEINCLUDE \"GaussUtils_v40\""
			Execute/P "DELETEINCLUDE \"WriteModelData_v40\""
			Execute/P "DELETEINCLUDE \"USANS_SlitSmearing_v40\""
			Execute/P "DELETEINCLUDE \"SANSModelPicker_v40\""
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
Function NCNR_SANSReductionLoader(itemStr)
	String itemStr
	
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.02)
		Abort "Your version of Igor is lower than 6.02, these macros need version 6.02 or higher.... "
	endif
	
	NewDataFolder/O root:Packages 		//create the folder for string variable
	String/G root:Packages:NCNRItemStr2a = itemStr
	String/G root:Packages:NCNRItemStr2b = itemStr
	SVAR gMenuStr2a = root:Packages:NCNRItemStr2a
	SVAR gMenuStr2b = root:Packages:NCNRItemStr2b
	
	String SANSRed_WinList = "Main_Panel;CatVSTable;SANS_Data;Plot_Manager;Average_Panel;Plot_1d;CatWin;Surface_3D;FitPanel;FitWindow;"
	SANSRed_WinList += "FitRPAPanel;SANS_Histo;drawMaskWin;Multiple_Reduce_Panel;NSORT_Panel;NSORT_Graph;CombineTable;ToCombine;Patch_Panel;"
	SANSRed_WinList += "ProtocolPanel;Schematic_Layout;Tile_2D;RAW_to_ASCII;Trans_Panel;TransFileTable;ScatterFileTable;Convert_to_Trans;"
	SANSRed_WinList += "WorkFileMath;Pref_Panel;Subtract_1D_Panel;Plot_Sub1D;SASCALC;MC_SASCALC;Saved_Configurations;TISANE;"
	strswitch(itemStr)	// string switch
		case "Load NCNR SANS Reduction Macros":	
			Execute/P "INSERTINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("Initialize()")
		
			gMenuStr2a = "Hide NCNR SANS Reduction Macros"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr2b = "-"
			BuildMenu "Macros"
			
			break						
		case "Unload NCNR SANS Reduction Macros":	
		// very dangerous - don't really want to implement this because it will surely crash
			Execute/P "DELETEINCLUDE \"Includes_v520\""
			Execute/P "COMPILEPROCEDURES "
			DoWindow Main_Panel
			if(V_Flag)
				DoWindow/K Main_Panel
			endif

			gMenuStr2a = "Load NCNR SANS Reduction Macros"
			gMenuStr2b = "-"
			
			BuildMenu "Macros"
			
			break
		case "Hide NCNR SANS Reduction Macros":
			HideShowWindowsInList(SANSRed_WinList,1)
		
			gMenuStr2a = "Show NCNR SANS Reduction Macros"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr2b = "-"
			BuildMenu "Macros"
			
			break
		case "Show NCNR SANS Reduction Macros":	
			HideShowWindowsInList(SANSRed_WinList,0)
		
			gMenuStr2a = "Hide NCNR SANS Reduction Macros"
//			gMenuStr2b = "Unload NCNR SANS Reduction Macros"
			gMenuStr2b = "-"
			BuildMenu "Macros"
			
			break
		default:
			Abort "Invalid Menu Selection"
	endswitch

end

// now add for the SANS Reduction
Function NCNR_USANSReductionLoader(itemStr)
	String itemStr
	
	if (str2num(stringByKey("IGORVERS",IgorInfo(0))) < 6.02)
		Abort "Your version of Igor is lower than 6.02, these macros need version 6.02 or higher.... "
	endif
	
	NewDataFolder/O root:Packages 		//create the folder for string variable
	String/G root:Packages:NCNRItemStr3a = itemStr
	String/G root:Packages:NCNRItemStr3b = itemStr
	SVAR gMenuStr3a = root:Packages:NCNRItemStr3a
	SVAR gMenuStr3b = root:Packages:NCNRItemStr3b
	
	String USANS_WinList = "USANS_Panel;COR_Graph;RawDataWin;Desmear_Graph;USANS_Slope;"
	
	strswitch(itemStr)	// string switch
		case "Load NCNR USANS Reduction Macros":	
			Execute/P "INSERTINCLUDE \"USANS_Includes\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P ("ShowUSANSPanel()")
		
			gMenuStr3a = "Hide NCNR USANS Reduction Macros"
//			gMenuStr3b = "Unload NCNR USANS Reduction Macros"
			gMenuStr3b = "-"
			BuildMenu "Macros"
			
			break						
		case "Unload NCNR USANS Reduction Macros":	
		// very dangerous - don't really want to implement this because it will surely crash
			Execute/P "DELETEINCLUDE \"USANS_Includes\""
			Execute/P "COMPILEPROCEDURES "
			DoWindow USANS_Panel
			if(V_Flag)
				DoWindow/K USANS_Panel
			endif

			gMenuStr3a = "Load NCNR USANS Reduction Macros"
			gMenuStr3b = "-"
			
			BuildMenu "Macros"
			
			break
		case "Hide NCNR USANS Reduction Macros":	
			HideShowWindowsInList(USANS_WinList,1)	
		
			gMenuStr3a = "Show NCNR USANS Reduction Macros"
//			gMenuStr3b = "Unload NCNR USANS Reduction Macros"
			gMenuStr3b = "-"
			BuildMenu "Macros"
			
			break
		case "Show NCNR USANS Reduction Macros":
			HideShowWindowsInList(USANS_WinList,0)	
			
			gMenuStr3a = "Hide NCNR USANS Reduction Macros"
//			gMenuStr3b = "Unload NCNR USANS Reduction Macros"
			gMenuStr3b = "-"
			BuildMenu "Macros"
			
			break
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