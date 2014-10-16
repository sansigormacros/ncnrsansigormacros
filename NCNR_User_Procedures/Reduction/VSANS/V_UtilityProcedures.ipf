#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// a bunch of utility procedures to get information from the VCALC panel and to access
// constants based in which of the detectors I'm trying to work with. Saves a lot of repetitive switches
//
// start the function names with VCALC_ to avoid the eventual conflicts with the file loading utilities
// for reduction of real VSANS data


///  Values from the VCALC panel


// returns the nominal SDD from the panel -- value is METERS
// Does NOT include the set back (offset) of the T/B panels. This is a separate value
Function VCALC_getSDD(type)
	String type
	
	Variable sdd
	
	strswitch(type)	
		case "FL":
		case "FR":		
			ControlInfo/W=VCALC VCALCCtrl_2d
			SDD = V_Value
			break
		case "FT":
		case "FB":		
			ControlInfo/W=VCALC VCALCCtrl_2d
			SDD = V_Value	
			break

		case "ML":
		case "MR":		
			ControlInfo/W=VCALC VCALCCtrl_3d
			SDD = V_Value
			break
		case "MT":
		case "MB":
			ControlInfo/W=VCALC VCALCCtrl_3d
			SDD = V_Value
			break	
						
		case "B":		
			ControlInfo/W=VCALC VCALCCtrl_4b
			SDD = V_Value
			break
			
		default:
			Print "Error -- type not found in	 V_getSDD(type)"					
			sdd = NaN		//no match for type		
	endswitch
	
	return(sdd)
end

// returns the panel separation [mm]
Function VCALC_getPanelSeparation(type)
	String type
	
	Variable sep
	
	strswitch(type)	
		case "FL":
		case "FR":
		case "FLR":		
			ControlInfo/W=VCALC VCALCCtrl_2a
			sep = V_Value
			break
		case "FT":
		case "FB":
		case "FTB":		
			ControlInfo/W=VCALC VCALCCtrl_2b
			sep = V_Value	
			break

		case "ML":
		case "MR":
		case "MLR":		
			ControlInfo/W=VCALC VCALCCtrl_3a
			sep = V_Value
			break
		case "MT":
		case "MB":
		case "MTB":
			ControlInfo/W=VCALC VCALCCtrl_3b
			sep = V_Value
			break	
						
		case "B":		
			sep = 0
			break
			
		default:
			Print "Error -- type not found in	 VCALC_getPanelSeparation(type)"					
			sep = NaN		//no match for type		
	endswitch
	
	return(sep)
end

// returns the lateral panel offset [mm]
Function VCALC_getLateralOffset(type)
	String type
	
	Variable offset
	
	strswitch(type)	
		case "FL":
		case "FR":
		case "FLR":
		case "FT":
		case "FB":
		case "FTB":		
			ControlInfo/W=VCALC VCALCCtrl_2c
			offset = V_Value	
			break

		case "ML":
		case "MR":
		case "MLR":
		case "MT":
		case "MB":
		case "MTB":
			ControlInfo/W=VCALC VCALCCtrl_3c
			offset = V_Value
			break	
						
		case "B":		
			ControlInfo/W=VCALC VCALCCtrl_4a
			offset = V_Value
			break
			
		default:
			Print "Error -- type not found in	 VCALC_getLateralOffset(type)"					
			offset = NaN		//no match for type		
	endswitch
	
	return(offset)
end

// returns the (mean) wavelength from the panel -- value is angstroms
Function VCALC_getWavelength()
	
	ControlInfo/W=VCALC VCALCCtrl_0b

	return(V_Value)
end

// returns the number of neutrons on the sample
Function VCALC_getImon()
	
	ControlInfo/W=VCALC VCALCCtrl_5a

	return(V_Value)
end

// returns the model function to use
Function/S VCALC_getModelFunctionStr()
	
	ControlInfo/W=VCALC VCALCCtrl_5b

	return(S_Value)
end



/// NVARs set in VCALC space (not necessarily matching the true instrument values)
// -- these all set to the proper data folder, then BACK TO ROOT:


// return the pixel X size, in [cm]
Function VCALC_getPixSizeX(type)
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC
			
	strswitch(type)	
		case "FL":
			NVAR pixSizeX = gFront_L_pixelX
			break
		case "FR":		
			NVAR pixSizeX = gFront_R_pixelX
			break
		case "FT":
			NVAR pixSizeX = gFront_T_pixelX
			break	
		case "FB":		
			NVAR pixSizeX = gFront_B_pixelX
			break
			
		case "ML":
			NVAR pixSizeX = gMiddle_L_pixelX
			break
		case "MR":		
			NVAR pixSizeX = gMiddle_R_pixelX
			break
		case "MT":
			NVAR pixSizeX = gMiddle_T_pixelX
			break	
		case "MB":		
			NVAR pixSizeX = gMiddle_B_pixelX
			break
						
		case "B":		
			NVAR pixSizeX = gBack_pixelX
			break
			
		default:							
			Print "Detector type mismatch in 	V_getPixSizeX(type)"
			return(NaN)
	endswitch

	setDataFolder root:
		
	return(pixSizeX)
end

// return the pixel Y size, in [cm]
Function VCALC_getPixSizeY(type)
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC
			
	strswitch(type)	
		case "FL":
			NVAR pixSizeY = gFront_L_pixelY
			break
		case "FR":		
			NVAR pixSizeY = gFront_R_pixelY
			break
		case "FT":
			NVAR pixSizeY = gFront_T_pixelY
			break	
		case "FB":		
			NVAR pixSizeY = gFront_B_pixelY
			break
			
		case "ML":
			NVAR pixSizeY = gMiddle_L_pixelY
			break
		case "MR":		
			NVAR pixSizeY = gMiddle_R_pixelY
			break
		case "MT":
			NVAR pixSizeY = gMiddle_T_pixelY
			break	
		case "MB":		
			NVAR pixSizeY = gMiddle_B_pixelY
			break
						
		case "B":		
			NVAR pixSizeY = gBack_pixelY
			break
			
		default:							
			Print "Detector type mismatch in 	V_getPixSizeY(type)"
			return(NaN)
	endswitch

	setDatafolder root:
		
	return(pixSizeY)
end

// SDD offset of the top/bottom panels
// value returned is in mm (so beware)
//
Function VSANS_getTopBottomSDDOffset(type)
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	strswitch(type)	
		case "FL":
		case "FR":
			return(0)		
			break		//already zero, do nothing
		case "FT":
		case "FB":		
			NVAR sdd_offset = gFront_SDDOffset 	//T/B are 300 mm farther back 
			break
			
		case "ML":
		case "MR":
			return(0)
			break		//already zero, do nothing
		case "MT":
		case "MB":
			NVAR sdd_offset = gMiddle_SDDOffset 	//T/B are 30 cm farther back
			break	
						
		case "B":
			return(0)
			break		//already zero, do nothing
			
		default:
			Print "Error -- type not found in	 VSANS_getTopBottomSDDOffset(type)"					
			sdd_offset = NaN		//no match for type		
	endswitch

	SetDataFolder root:
		
	return(sdd_offset)	
End


/////////// procedure to concatenate I(q) files into a single file
//
// currently, no rescaling is done, just simple concatentate and sort
//
