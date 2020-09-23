#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00

////////////////////////
//
//
// a bunch of utility procedures to access information from the VCALC panel and to access
// constants based in which of the detectors I'm trying to work with. Saves a lot of repetitive switches
//
// start the function names with VCALC_ to avoid the eventual conflicts with the file loading utilities
// for reduction of real VSANS data
//
//
// -- add more of these procedures as more items are added to the panel
//
////////////////////////


//  Values from the VCALC panel




// returns the panel translation [cm]
Function VCALC_getPanelTranslation(type)
	String type
	
	Variable sep
	
	strswitch(type)	
		case "FL":
			ControlInfo/W=VCALC VCALCCtrl_2a
			sep = V_Value
			break
		case "FR":
			ControlInfo/W=VCALC VCALCCtrl_2aa
			sep = V_Value
			break
		case "FT":
			ControlInfo/W=VCALC VCALCCtrl_2b
			sep = V_Value	
			break
		case "FB":
			ControlInfo/W=VCALC VCALCCtrl_2bb
			sep = V_Value	
			break

		case "ML":
			ControlInfo/W=VCALC VCALCCtrl_3a
			sep = V_Value
			break
		case "MR":
			ControlInfo/W=VCALC VCALCCtrl_3aa
			sep = V_Value
			break
		case "MT":
			ControlInfo/W=VCALC VCALCCtrl_3b
			sep = V_Value
			break	
		case "MB":
			ControlInfo/W=VCALC VCALCCtrl_3bb
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



// returns the (mean) wavelength from the panel -- value is angstroms
Function VCALC_getWavelength()
	
	ControlInfo/W=VCALC VCALCCtrl_0b

	return(V_Value)
end

// returns the wavelength spread from the panel -- value is fraction
Function VCALC_getWavelengthSpread()
	
	ControlInfo/W=VCALC VCALCCtrl_0d

	return(str2num(S_Value))
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

	Variable pixSizeX = V_getDet_x_pixel_size("VCALC",type)

	return(pixSizeX)
end

// return the pixel Y size, in [cm]
Function VCALC_getPixSizeY(type)
	String type

	Variable pixSizeY = V_getDet_y_pixel_size("VCALC",type)
	
	return(pixSizeY)
end


// return the number of pixels in x-dimension
Function VCALC_get_nPix_X(type)
	String type

	Variable nPix = V_getDet_pixel_num_x("VCALC",type)
	
	return(nPix)
end

// return the number of pixels in y-dimension
Function VCALC_get_nPix_Y(type)
	String type

	Variable nPix = V_getDet_pixel_num_y("VCALC",type)

	return(nPix)
end



// SDD offset of the top/bottom panels
// value returned is in [cm] 
//
Function VCALC_getTopBottomSDDSetback(type)
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	strswitch(type)	
		case "FL":
		case "FR":
			SetDataFolder root:
			return(0)		
			break		//already zero, do nothing
		case "FT":
		case "FB":		
			NVAR sdd_setback = gFront_SDDsetback 	//T/B are 41 cm farther back 
			break
			
		case "ML":
		case "MR":
			SetDataFolder root:
			return(0)
			break		//already zero, do nothing
		case "MT":
		case "MB":
			NVAR sdd_setback = gMiddle_SDDsetback 	//T/B are 41 cm farther back
			break	
						
		case "B":
		case "B ":
			SetDataFolder root:
			return(0)
			break		//already zero, do nothing
			
		default:
			Print "Error -- type not found in	 VCALC_getTopBottomSDDSetback(type)"					
			sdd_setback = 0		//no match for type		
	endswitch

	SetDataFolder root:
		
	return(sdd_setback)	
End


Function VC_getNumGuides()

	Variable ng
	ControlInfo/W=VCALC VCALCCtrl_0a
	ng = V_Value
	return(ng)
End
//////////////////////////////////
//
// Actions for the VCALC controls
//
//////////////////////////////////

// get the sourceAperture_to_GateValve distance from the table
//
// correct for the sampleAperture_to_GateValve distance
//
// return the SourceAp to SampleAp Distance in [cm]
Function VC_calcSSD()

	Variable ng,ssd,samAp_to_GV
	ControlInfo/W=VCALC VCALCCtrl_0a
	ng = V_Value

	ControlInfo/W=VCALC VCALCCtrl_1d
	samAp_to_GV = V_Value		// [cm]
	
	switch(ng)
		case 0:
				ssd = 2441
			break
		case 1:
				ssd = 2157
			break
		case 2:
				ssd = 1976
			break
		case 3:
				ssd = 1782
			break			
		case 4:
				ssd = 1582
			break			
		case 5:
				ssd = 1381
			break			
		case 6:
				ssd = 1181
			break			
		case 7:
				ssd = 980
			break			
		case 8:
				ssd = 780
			break			
		case 9:
				ssd = 579
			break			
		default:
			Print "Error - using default SSD value"
			ssd = 2441
	endswitch
	ssd -= samAp_to_GV
	
//	print "SSD (cm) = ",ssd
	return(ssd)
End


// read the number of guides from the slider
// return the Source aperture diameter [cm]
// TODO - needs a case statement since a1 can depend on Ng
Function VC_sourceApertureDiam()

	Variable ng,a1
	ControlInfo/W=VCALC VCALCCtrl_0a
	ng = V_Value

	ControlInfo/W=VCALC VCALCCtrl_0f
	String apStr = S_Value
	

	if(ng > 0)	
		a1 = 6		// 60 mm diameter
	else
		sscanf apStr, "%g cm", a1
	endif

//	Print "Source Ap diam (cm) = ",a1
	return(a1)
End

// reports the value in [cm]
//
// if the aperture is non-circular, report 1.27 cm
// TODO -- work out the math for a better approxiamtion of the shadowing
// -- especially for a rectangular aperture.
//
Function VC_sampleApertureDiam()

	ControlInfo VCALCCtrl_1b
	
	if(cmpstr(S_Value,"circular") == 0)

		ControlInfo/W=VCALC VCALCCtrl_1c
		Variable val = str2num(S_Value)

	else
		//non-circular sample aperture
		// report a dummy value of 1.27 cm
		Print "using a dummy effective diameter of 1.27 cm"
		val = 1.27
		
	endif
	return(val)
End


///////////////////
//
// Presets
//
///////////////////


// for Front+Middle Only
// x F SDD=120
// x (L=-20, R=20) (T=4, B=-4)
//
// x M SDD = 1900
// x (L=0, R=0)
//
// x Velocity selector
// x Ng = 0
// x Lam = 8
// x delLam = 0.12
// source ap = ? (circular)
//
// ignore back detector
// x set plot type to F2-M2xTB-B
//
// 
Function VC_Preset_FrontMiddle_Ng0()

// set preference to ignore back detector
	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gIgnoreB = 1
	
	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:10		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:400		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:-10		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:4			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-4		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1900		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6,disable=0

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",0,1)		//Set Ng=0, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=0

	
// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=3		//set the 3.0 cm aperture
	
// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End


Function VC_Preset_FrontMiddle_Ng2()

	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:10		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:350		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:-10		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:4			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-4		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1600		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6,disable=0

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",2,1)		//Set Ng=2, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=2
	
// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=1		//6.0 cm aperture
	

// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End

Function VC_Preset_FrontMiddle_Ng7()

	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:10		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:230		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:-10		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:4			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-4		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1100		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6,disable=0

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",7,1)		//Set Ng=7, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=7

// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=1		//6.0 cm aperture


// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End

Function VC_Preset_FrontMiddle_Ng9()

	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:10		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:100		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-10		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:-10		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:4			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-4		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:450		//SDD
	
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6,disable=0

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",9,1)		//Set Ng=9, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=9

// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=1		//6.0 cm aperture


// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End




// White beam preset
// - set monochromator (this sets lam, delLam)
// - disregard the back detector (set as front/middle)
//
Function VC_Preset_WhiteBeam()

	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="White Beam"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.40;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40"

// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:5.3,disable=2//	,noedit=0	// allow user editing again

	// adjust the front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-20		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:20		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:8			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-8		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:120		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-15		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:15		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:15			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-15		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1900		//SDD
	
// binning mode
	PopupMenu popup_b,mode=1,popValue="F4-M4-B"

// set preference to USE back detector
	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gIgnoreB = 0
	
			
	return(0)
end



// Super White beam preset
// - set monochromator (this sets lam, delLam)
// - disregard the back detector (set as front/middle)
//
Function VC_Preset_SuperWhiteBeam()

	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Super White Beam"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.60;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.60"

// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6.2,disable=2	// disable=2 is grayed out	,noedit=0	// allow user editing again

	// adjust the front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-20		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:20		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:8			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-8		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:120		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-15		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:15		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:15			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-15		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1900		//SDD
	
// binning mode
	PopupMenu popup_b,mode=1,popValue="F4-M4-B"

// set preference to USE back detector
	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gIgnoreB = 0
	
			
	return(0)
end


// Graphite - high resolution beam preset
// - set monochromator (this sets lam, delLam)
// - uses the back detector (set as front/middle)
//
Function VC_Preset_GraphiteMono()

	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-20		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:20		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:120		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-8		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:08	//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:18			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-18		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1500		//SDD

	// back carriage	
	SetVariable VCALCCtrl_4b,value=_NUM:2300		//SDD
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Graphite"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.01;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.01"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:4.75,disable=2//	,noedit=0	// allow user editing again

	//number of guides
	Slider VCALCCtrl_0a,value= 0


// binning mode
	PopupMenu popup_b,mode=1,popValue="F4-M4-B"

	return(0)
end


//
// 
Function VC_Preset_ConvergingPinholes()

// set preference to NOT ignore back detector
	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gIgnoreB = 0
	
	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-11		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:7		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:11.5			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-12		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:450		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-2.75		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:3.25		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:3.5			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-2.5		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:2136		//SDD
	
	// back detector
	SetVariable VCALCCtrl_4b,value=_NUM:2416		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6.7,disable=2

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",0,1)		//Set Ng=0, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=0

	
// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=3		//set the 3.0 cm aperture
	
// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End



// 
// TODO -- need to define non-circular aperture shape input on the panel
//
Function VC_Preset_NarrowSlit()

// set preference to NOT ignore back detector
	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gIgnoreB = 0
	
	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-11		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:7		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:11.5			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-12		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:450		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:-2.75		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:3.25		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:3.5			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-2.5		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:2136		//SDD
	
	// back detector
	SetVariable VCALCCtrl_4b,value=_NUM:2416		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:6.7,disable=2

	//number of guides
//	Slider VCALCCtrl_0a,value= 0
	V_GuideSliderProc("VCALCCtrl_0a",0,1)		//Set Ng=0, resets the aperture string to the new string
	Slider VCALCCtrl_0a,value=0

	
// source aperture (+new string)
	PopupMenu VCALCCtrl_0f,mode=3		//set the 3.0 cm aperture
	
// binning mode
	PopupMenu popup_b,mode=1,popValue="SLIT-F2-M2-B"


	return(0)
End




// calculates L2, the sample aperture to detector distance
Function VC_calc_L2(detStr)
	String detStr

	Variable a2_to_GV,sam_to_GV,sdd,l2
	sdd = VC_getSDD(detStr)			//sample pos to detector
	sdd += VCALC_getTopBottomSDDSetback(detStr)		//returns zero for L/R
	ControlInfo/W=VCALC VCALCCtrl_1d
	a2_to_GV = V_Value
	ControlInfo/W=VCALC VCALCCtrl_1e
	sam_to_GV = V_Value
	l2 = sdd - sam_to_GV + a2_to_GV
	
	return(l2)
End

//
//direction = one of "vertical;horizontal;maximum;"
// all of this is bypassed if the lenses are in
//
// carrNum = 1,2,3 for F,M,B
//
// returns a value in [cm]
Function VC_beamDiameter(direction,detStr)
	String direction
	String detStr

//	NVAR lens = root:Packages:NIST:SAS:gUsingLenses
//	if(lens)
//		return sourceApertureDiam()
//	endif
	
	Variable l1,l2,l2Diff
	Variable d1,d2,bh,bv,bm,umbra,a1,a2
	Variable lambda,lambda_width,bs_factor
    
// TODO: proper value for bs_factor
	bs_factor = 1.05
	
	l1 = VC_calcSSD()
	lambda = VCALC_getWavelength()
	lambda_width = VCALC_getWavelengthSpread()
	
	
	Variable a2_to_GV,sam_to_GV,sdd
	sdd = VC_getSDD(detStr)			//sample pos to detector
	sdd += VCALC_getTopBottomSDDSetback(detStr)		//returns zero for L/R
	ControlInfo/W=VCALC VCALCCtrl_1d
	a2_to_GV = V_Value
	ControlInfo/W=VCALC VCALCCtrl_1e
	sam_to_GV = V_Value
	l2 = sdd - sam_to_GV + a2_to_GV
   
   
    // TODO verify that these values are in cm
	a1 = VC_sourceApertureDiam()
    
	// sample aperture diam [cm]
	ControlInfo/W=VCALC VCALCCtrl_1c
	a2 = V_Value
    
    d1 = a1*l2/l1
    d2 = a2*(l1+l2)/l1
    bh = d1+d2		//beam size in horizontal direction
    umbra = abs(d1-d2)
    //vertical spreading due to gravity
    bv = bh + 1.25e-8*(l1+l2)*l2*lambda*lambda*lambda_width
    bm = (bs_factor*bh > bv) ? bs_factor*bh : bv //use the larger of horiz*safety or vertical
    
    strswitch(direction)	// string switch
    	case "vertical":		// execute if case matches expression
    		return(bv)
    		break						// exit from switch
    	case "horizontal":		// execute if case matches expression
    		return(bh)
    		break
    	case "maximum":		// execute if case matches expression
    		return(bm)
    		break
    	default:							// optional default expression executed
    		return(bm)						// when no case matches
    endswitch
    
    return(0)
    
End

// 1=front
// 2=middle
// 3=back
// return value is in cm
// actual Sample position to detector distance is reported
// Top/Bottom setback is included
Function VC_getSDD(detStr)
	String detStr
	
	Variable sdd

	strswitch(detstr)
		case "B":
		case "B ":
			ControlInfo/W=VCALC VCALCCtrl_4b
			break
		case "ML":
		case "MR":
		case "MT":
		case "MB":
			ControlInfo/W=VCALC VCALCCtrl_3d
			break
		case "FL":
		case "FR":
		case "FT":
		case "FB":
			ControlInfo/W=VCALC VCALCCtrl_2d
			break		
		default:
			Print "no case matched in VC_getSDD()"
	endswitch

	// this is gate valve to detector distance
	sdd = V_Value
	
	// MAR 2020 -- don't add in the setback, ask for it when needed
//	sdd += VCALC_getTopBottomSDDSetback(detStr)
	
	// VCALCCtrl_1e is Sample Pos to Gate Valve (cm)
	ControlInfo/W=VCALC VCALCCtrl_1e
	sdd += V_Value
	
	return(sdd)
end



Function V_sampleToGateValve()
	// VCALCCtrl_1e is Sample Pos to Gate Valve (cm)
	ControlInfo/W=VCALC VCALCCtrl_1e
	return(V_Value)	
end


Function V_sampleApertureToGateValve()
	// VCALCCtrl_1d is Sample Aperture to Gate Valve (cm)
	ControlInfo/W=VCALC VCALCCtrl_1d
	return(V_Value)	
end



// 1=front
// 2=middle
// 3=back
// return value is in cm
// gate valve to detector (= nominal distance) is reported
// Top/Bottom setback is NOT included
Function VC_getGateValveToDetDist(detStr)
	String detStr
	
	Variable sdd

	strswitch(detstr)
		case "B":
		case "B ":
			ControlInfo/W=VCALC VCALCCtrl_4b
			break
		case "ML":
		case "MR":
		case "MT":
		case "MB":
			ControlInfo/W=VCALC VCALCCtrl_3d
			break
		case "FL":
		case "FR":
		case "FT":
		case "FB":
			ControlInfo/W=VCALC VCALCCtrl_2d
			break		
		default:
			Print "no case matched in VC_getGateValveToDetDistance()"
	endswitch

	// this is gate valve to detector distance
	sdd = V_Value
	
	return(sdd)
end	

// TODO
// -- verify all of the numbers, constants, and "empirical" transmission corrections
// --
//
Function V_beamIntensity()

	Variable as,solid_angle,l1,d2_phi
	Variable a1,a2,retVal
	Variable ng
	Variable lambda_t
	Variable lambda,phi_0
	Variable lambda_width
	Variable guide_loss,t_guide,t_filter,t_total,t_special
	Variable a1Area,a2Area
	
	NVAR gBeamInten = root:Packages:NIST:VSANS:VCALC:gBeamIntensity
 
// TODO
// -- verify these numbers
	lambda_t = 6.20
	phi_0 = 1.82e13
	guide_loss = 0.97
	t_special = 1

 	ControlInfo/W=VCALC VCALCCtrl_0a
	ng = V_Value
 
 	lambda = VCALC_getWavelength()
 	lambda_width = VCALC_getWavelengthSpread()
	l1 = VC_calcSSD()
    
    
   a1Area = VC_SourceApArea()
   a2Area = VC_SampleApArea()
   
    // TODO verify that these values are in cm
//	a1 = VC_sourceApertureDiam()
    
	// sample aperture diam [cm]
//	a2 = VC_sampleApertureDiam()
    
//	alpha = (a1+a2)/(2*l1)	//angular divergence of beam
//	f = l_gap*alpha/(2*guide_width)
//	t4 = (1-f)*(1-f)
//	t6 = 1 - lambda*(b-(ng/8)*(b-c))		//experimental correction factor

	t_guide = exp(ng*ln(guide_loss))	// trans losses of guides in pre-sample flight
	t_filter = exp(-0.371 - 0.0305*lambda - 0.00352*lambda*lambda)
	t_total = t_special*t_guide*t_filter

    
//	as = pi/4*a2*a2		//area of sample in the beam
	as = a2Area			//area of sample in the beam
	d2_phi = phi_0/(2*pi)
	d2_phi *= exp(4*ln(lambda_t/lambda))
	d2_phi *= exp(-1*(lambda_t*lambda_t/lambda/lambda))

//	solid_angle = pi/4* (a1/l1)*(a1/l1)
	solid_angle = a1Area/(l1*l1)

	retVal = as * d2_phi * lambda_width * solid_angle * t_total

	// set the global for display
	gBeamInten = retVal
	
	return (retVal)
end


// return the area (cm)^2 of the source aperture
//
Function VC_SourceApArea()

	Variable apArea,diam,ht,wid
	
	
	ControlInfo VCALCCtrl_0e
	String popStr = S_Value

	strswitch(popStr)
		case "circular":
			ControlInfo VCALCCtrl_0f
			sscanf S_Value,"%g cm",diam
			
			apArea = pi/4*diam*diam
						
			break
		case "rectangular":
			ControlInfo VCALCCtrl_0f
			sscanf S_Value,"%g mm",ht
			
			ControlInfo VCALCCtrl_0g
			sscanf S_Value,"%g mm",wid
			
			apArea = ht*wid/100		//convert mm^2 to cm^2
		
			break
		case "converging pinholes":
			ControlInfo VCALCCtrl_0f
			sscanf S_Value,"%g cm",diam
			
			apArea = pi/4*diam*diam
			
			break
			
	endswitch	
	
	
	return(apArea)
End

// return the area (cm)^2 of the sample aperture
//
Function VC_SampleApArea()

	Variable apArea,diam,ht,wid
	
	ControlInfo VCALCCtrl_1b
	String popStr = S_Value


	strswitch(popStr)
		case "circular":
			ControlInfo VCALCCtrl_1c
			diam = str2num(S_Value)
			
			apArea = pi/4*diam*diam
			
			break
		case "rectangular":
			ControlInfo VCALCCtrl_1c
			sscanf S_Value,"%g mm",ht

			ControlInfo VCALCCtrl_1f
			sscanf S_Value,"%g mm",wid

			apArea = ht*wid/100		//convert mm^2 to cm^2			


			break
		case "converging pinholes":
			ControlInfo VCALCCtrl_1c
			diam = str2num(S_Value)
			
			apArea = pi/4*diam*diam

			break
			
	endswitch	
	
	return(apArea)
End



//
Function VC_figureOfMerit()

	Variable bi = V_beamIntensity()
	Variable lambda = VCALC_getWavelength()
	
   return (lambda*lambda*bi)
End

// return a beamstop diameter (cm) larger than maximum beam dimension
Function VC_beamstopDiam(detStr)
	String detStr
	
	Variable bm=0
	Variable bs=0.0
   Variable yesLens=0
   
	if(yesLens)
		//bm = sourceApertureDiam()		//ideal result, not needed
		bs = 1								//force the diameter to 1"
	else
		bm = VC_beamDiameter("maximum",detStr)
		do
	    	bs += 1
	   while ( (bs*2.54 < bm) || (bs > 30.0)) 			//30 = ridiculous limit to avoid inf loop
	endif

	return (bs*2.54)		//return diameter in cm, not inches for txt
End

// multiply the appropriate IQ data by the beamstop shadow factor for display
//
Function V_IQ_BeamstopShadow()

	String popStr
	Variable binType
	
	ControlInfo/W=VCALC popup_b
	popStr = S_Value	

	binType = V_BinTypeStr2Num(popStr)	
	
	String folderStr = "root:Packages:NIST:VSANS:VCALC:"
	

	String extStr =""
	
	switch(binType)
		case 1:
			extStr = ksBinType1		

			break
		case 2:
			extStr = ksBinType2		

			break
		case 3:
			extStr = ksBinType3	
			
			break
		case 4:				/// this is for a tall, narrow slit mode	
			extStr = ksBinType4

			break
		case 5:
			extStr = ksBinType5	
		
			break
		case 6:
			extStr = ksBinType6	
		
			break
		case 7:
			extStr = ksBinType7	
		
			break
			
		default:
			Abort "Binning mode not found in V_IQ_BeamstopShadow"// when no case matches	
	endswitch

// TODO:
// -- I had to put a lot of conditions on when not to try to apply the shadow factor
// to avoid errors when iq had no points in the wave, or incorrectly applying the beamstop to the back panel.
	
	Variable ii
	String ext
//	loop over all of the types of data
	for(ii=0;ii<ItemsInList(extStr);ii+=1)
		ext = StringFromList(ii, extStr, ";")
		Wave iq = $(folderStr+"iBin_qxqy_"+ext)
		Wave/Z fs = $(folderStr+"fSubS_qxqy_"+ext)
		if(WaveExists(fs) && numpnts(iq) > 0 && cmpstr(ext,"B") != 0)
			iq = (fs < 0.1) ? iq*0.1 : iq*fs
		endif
	endfor	
	
	return(0)
end



//
// instead of setting some of the data to NaN to exclude it, draw a proper mask to be used
// during the I(q) averaging
//
// use both the "hard" and "soft" shadowing
// -- chooses the more "conservative" of the shadowing values (soft value at short SDD + T/B)
//
// the MSK data will be in its ususal location from the initialization.
//
// FL shadows FT, FB, ML
// FR shadows FT, FB, MR
// FT shadows ML, MR, MT
// FB shadows ML, MR, MB
// ML shadows MT, MB, B
// MR shadows MT, MB, B
// MT shadows B
// MB shadows B
//
Function VC_DrawVCALCMask()

	VC_DrawVCALCMask_FL()
	VC_DrawVCALCMask_FR()
	VC_DrawVCALCMask_FT()
	VC_DrawVCALCMask_FB()
	
	VC_DrawVCALCMask_ML()
	VC_DrawVCALCMask_MR()
	VC_DrawVCALCMask_MT()
	VC_DrawVCALCMask_MB()
	
	return(0)
end

// FL shadows FT, FB, ML
Function VC_DrawVCALCMask_FL()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_ML,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_X_pix,delta
	String type,target

// FL shadows FT,FB,ML
	type = "FL"

	// lateral offset of FL
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (L/R panels)
	delta_L = 33		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of FT, or FB, or ML
/////
	target = "FT"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FT, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)		//pixels from the center
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the left side of the FT panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[0,nt][] = 1
	endif
	
/////
	target = "FB"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FB, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the left side of the FB panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[0,nt][] = 1
	endif

///
// for ML, there can also be lateral offset of the ML panel
	target = "ML"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
//	delta = delta_Xh
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of ML, in "pixels"
	offset_ML = VCALC_getPanelTranslation(target)/pixSizeX		//[cm]
	offset_ML = -trunc(offset_ML)
	//since "target" is ML, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)
	
	//is the delta_x_pix still on the left edge of ML?
	if(delta_x_pix < 0)		//entire panel is shadowed
		nt = nPix-1
		mask[0,nt][] = 1
	else
		if(delta_X_pix < nPix + offset_ML)
			nt = nPix + offset_ML - delta_x_pix
			mask[0,nt][] = 1
		endif
	endif
	
	return(0)
end

// FR shadows FT, FB, MR
Function VC_DrawVCALCMask_FR()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_MR,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_X_pix,delta
	String type,target

// FR shadows FT, FB, MR
	type = "FR"

	// lateral offset of FR
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (L/R panels)
	delta_L = 33		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of FT, or FB, or MR
/////
	target = "FT"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FT, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the right side of the FT panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[nPix-nt,nPix-1][] = 1
	endif
	
/////
	target = "FB"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FB, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the right side of the FB panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[nPix-nt,nPix-1][] = 1
	endif

///
// for MR, there can also be lateral offset of the panel
	target = "MR"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of MR, in "pixels"
	offset_MR = VCALC_getPanelTranslation(target)/pixSizeX		//[cm]
	offset_MR = trunc(offset_MR)
	//since "target" is ML, use x-position
	// at what "pixel" does the shadow start?
	nPix = VCALC_get_nPix_X(target)
	
	delta_X_pix = trunc(delta/pixSizeX)
	
	//is the delta_x_pix still on the right edge of MR?
	if(delta_x_pix < 0)		//entire panel is shadowed
		nt = nPix-1
		mask[0,nt][] = 1
	else
		if(delta_X_pix < nPix + offset_MR)
			nt = nPix + offset_MR - delta_x_pix
			mask[nPix-nt,nPix-1][] = 1
		endif
	endif
		
	return(0)
end

// FT shadows ML, MR, MT
Function VC_DrawVCALCMask_FT()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_MT,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_Y_pix,delta
	String type,target

// FT shadows ML, MR, MT
	type = "FT"

	//  offset of FT
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (T/B panels)
	delta_L = 61		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of ML, or MR, or MT
/////
	target = "ML"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is ML, use Y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][nPix-nt,nPix-1] = 1
	endif

/////
	target = "MR"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)

	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is MR, use y-position
	// at what "pixel" does the shadow start?
	delta_y_pix = trunc(delta/pixSizey)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][nPix-nt,nPix-1] = 1
	endif
	
///
// for MT, there can also be lateral offset of the MT panel
	target = "MT"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of MT, in "pixels" -in Y-direction
	offset_MT = VCALC_getPanelTranslation(target)/pixSizeY		//[cm]
	offset_MT = trunc(offset_MT) 
	//since "target" is MT, use y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_Y_pix < nPix + offset_MT)
		nt = nPix + offset_MT - delta_y_pix
		mask[][nPix-nt,nPix-1] = 1
	endif
	
	
	return(0)
end

// FB shadows ML, MR, MB
Function VC_DrawVCALCMask_FB()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_MB,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_Y_pix,delta
	String type,target

// FB shadows ML, MR, MB
	type = "FB"

	//  offset of FB
	offset = VCALC_getPanelTranslation(type)
	
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (T/B panels)
	delta_L = 61		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of ML, or MR, or MB
/////
	target = "ML"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is ML, use Y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][0,nt] = 1
	endif
	
/////
	target = "MR"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is MR, use y-position
	// at what "pixel" does the shadow start?
	delta_y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][0,nt] = 1
	endif
	
///
// for MB, there can also be lateral offset of the MT panel
	target = "MB"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of MT, in "pixels" -in Y-direction
	offset_MB = VCALC_getPanelTranslation(target)/pixSizeY		//[cm]
	offset_MB = -trunc(offset_MB)
	//since "target" is MT, use y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_Y_pix < nPix + offset_MB)
		nt = nPix + offset_MB - delta_y_pix
		mask[][0,nt] = 1
	endif
	

	return(0)
end

// ML shadows MT, MB, B
Function VC_DrawVCALCMask_ML()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_B,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_X_pix,delta
	String type,target

// ML shadows MT, MB, B
	type = "ML"

	// lateral offset of ML
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (L/R panels)
	delta_L = 33		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of MT, or MB, or B
/////
	target = "MT"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FT, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)		//pixels from the center
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the left side of the FT panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[0,nt][] = 1
	endif
	
/////
	target = "MB"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is MB, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the left side of the MB panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[0,nt][] = 1
	endif

///
// for B, there can also be lateral offset of the B panel
	target = "B"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
//	delta = delta_Xh
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of B, in "pixels"
	offset_B = VCALC_getPanelTranslation(target)/pixSizeX		//[cm]
	offset_B = -trunc(offset_B)
	//since "target" is B, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)
	
	//is the delta_x_pix still on the left edge of B?
	if(delta_x_pix < 0)		//entire panel is shadowed
		nt = nPix-1
		mask[0,nt][] = 1
	else
		if(delta_X_pix < nPix + offset_B)
			nt = nPix + offset_B - delta_x_pix
			mask[0,nt][] = 1
		endif
	endif
	
	return(0)
end

// MR shadows MT, MB, B
Function VC_DrawVCALCMask_MR()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_B,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_X_pix,delta
	String type,target

// MR shadows MT, MB, B
	type = "MR"

	// lateral offset of FR
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (L/R panels)
	delta_L = 33		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of MT, or MB, or B
/////
	target = "MT"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value (this means closer to the center, a larger shadow)
	delta = min(delta_Xh,delta_Xs)

// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is MT, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the right side of the MT panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[nPix-nt,nPix-1][] = 1
	endif
	
/////
	target = "MB"
	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

	//since "target" is FB, use x-position
	// at what "pixel" does the shadow start?
	delta_X_pix = trunc(delta/pixSizeX)
	nPix = VCALC_get_nPix_X(target)

	if(delta_x_pix < trunc(nPix/2) )			//still on the right side of the MB panel
		nt = trunc(nPix/2) - delta_x_pix
		mask[nPix-nt,nPix-1][] = 1
	endif

///
// for B, there can also be lateral offset of the panel
	target = "B"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of B, in "pixels"
	offset_B = VCALC_getPanelTranslation(target)/pixSizeX		//[cm]
	offset_B = trunc(offset_B)
	//since "target" is B, use x-position
	// at what "pixel" does the shadow start?
	nPix = VCALC_get_nPix_X(target)
	
	delta_X_pix = trunc(delta/pixSizeX)
	
	//is the delta_x_pix still on the right edge of B?
	if(delta_x_pix < 0)		//entire panel is shadowed
		nt = nPix-1
		mask[0,nt][] = 1
	else
		if(delta_X_pix < nPix + offset_B)
			nt = nPix + offset_B - delta_x_pix
			mask[nPix-nt,nPix-1][] = 1
		endif
	endif
	
	return(0)
end


// MT shadows B
Function VC_DrawVCALCMask_MT()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_B,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_Y_pix,delta
	String type,target

// MT shadows B
	type = "MT"

	//  offset of MT
	offset = VCALC_getPanelTranslation(type)
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (T/B panels)
	delta_L = 61		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of ML, or MR, or MT
///////
//	target = "ML"
//	L2_M = VC_calc_L2(target)
//	// mask data
//	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")
//
//// extent of shadow in [cm] (starting point of shadow from center of beam)
//// hard
//	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
//// soft
//	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))
//
//	//use the smaller shadow value (this means closer to the center, a larger shadow)
//	delta = min(delta_Xh,delta_Xs)
//
//// how many detector tubes to mask?
//	pixSizeX = VCALC_getPixSizeX(target)
//	pixSizeY = VCALC_getPixSizeY(target)
//
//	//since "target" is ML, use Y-position
//	// at what "pixel" does the shadow start?
//	delta_Y_pix = trunc(delta/pixSizeY)
//	nPix = VCALC_get_nPix_Y(target)
//
//	if(delta_y_pix < trunc(nPix/2))
//		nt = trunc(nPix/2) - delta_y_pix
//		mask[][nPix-nt,nPix-1] = 1
//	endif

/////
//	target = "MR"
//	L2_M = VC_calc_L2(target)
//	// mask data
//	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")
//
//// extent of shadow in [cm] (starting point of shadow from center of beam)
//// hard
//	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
//// soft
//	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))
//
//	//use the smaller shadow value
//	delta = min(delta_Xh,delta_Xs)
//
//	
//// how many detector tubes to mask?
//	pixSizeX = VCALC_getPixSizeX(target)
//	pixSizeY = VCALC_getPixSizeY(target)
//
//	//since "target" is MR, use y-position
//	// at what "pixel" does the shadow start?
//	delta_y_pix = trunc(delta/pixSizey)
//	nPix = VCALC_get_nPix_Y(target)
//
//	if(delta_y_pix < trunc(nPix/2))
//		nt = trunc(nPix/2) - delta_y_pix
//		mask[][nPix-nt,nPix-1] = 1
//	endif
	
///
// for B, there can also be lateral offset of the B panel
	target = "B"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of B, in "pixels" -in Y-direction
	offset_B = VCALC_getPanelTranslation(target)/pixSizeY		//[cm]
	offset_B = trunc(offset_B) 
	//since "target" is B, use y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][nPix-nt,nPix-1] = 1
	endif
	
	return(0)
end

// MB shadows B
Function VC_DrawVCALCMask_MB()
	
	Variable pixSizeX,pixSizeY,nPix,nt

	Variable offset,offset_B,L2_F,L2_M,delta_L,delta_S,D2
	Variable delta_Xh,delta_Xs,delta_Y_pix,delta
	String type,target

// MB shadows B
	type = "MB"

	//  offset of MB
	offset = VCALC_getPanelTranslation(type)
	
	// sample aperture diam [cm]
	D2 = VC_sampleApertureDiam()
	// sdd F	 [cm] = sample aperture to detector
	L2_F = VC_calc_L2(type)
	// depth of electronics (T/B panels)
	delta_L = 61		//[cm]
	// offset of 80/20 frame
	delta_S = 2.5		//[cm]
	
	
	// sdd of ML, or MR, or MB
/////
//	target = "ML"
//	L2_M = VC_calc_L2(target)
//	// mask data
//	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")
//
//// extent of shadow in [cm] (starting point of shadow from center of beam)
//// hard
//	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
//// soft
//	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))
//
//	//use the smaller shadow value (this means closer to the center, a larger shadow)
//	delta = min(delta_Xh,delta_Xs)
//
//	
//// how many detector tubes to mask?
//	pixSizeX = VCALC_getPixSizeX(target)
//	pixSizeY = VCALC_getPixSizeY(target)
//
//	//since "target" is ML, use Y-position
//	// at what "pixel" does the shadow start?
//	delta_Y_pix = trunc(delta/pixSizeY)
//	nPix = VCALC_get_nPix_Y(target)
//
//	if(delta_y_pix < trunc(nPix/2))
//		nt = trunc(nPix/2) - delta_y_pix
//		mask[][0,nt] = 1
//	endif
	
/////
//	target = "MR"
//	L2_M = VC_calc_L2(target)
//	// mask data
//	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")
//
//// extent of shadow in [cm] (starting point of shadow from center of beam)
//// hard
//	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
//// soft
//	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))
//
//	//use the smaller shadow value
//	delta = min(delta_Xh,delta_Xs)
//	
//// how many detector tubes to mask?
//	pixSizeX = VCALC_getPixSizeX(target)
//	pixSizeY = VCALC_getPixSizeY(target)
//
//	//since "target" is MR, use y-position
//	// at what "pixel" does the shadow start?
//	delta_y_pix = trunc(delta/pixSizeY)
//	nPix = VCALC_get_nPix_Y(target)
//
//	if(delta_y_pix < trunc(nPix/2))
//		nt = trunc(nPix/2) - delta_y_pix
//		mask[][0,nt] = 1
//	endif
	
///
// for B, there can also be lateral offset of the B panel
	target = "B"

	L2_M = VC_calc_L2(target)
	// mask data
	Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+target+":data")

// extent of shadow in [cm] (starting point of shadow from center of beam)
// hard
	delta_Xh = D2/2 + (-offset - D2/2)*(L2_M/L2_F)
// soft
	delta_Xs = D2/2 + (-offset + delta_S - D2/2)*(L2_M/(L2_F+delta_L))

	//use the smaller shadow value
	delta = min(delta_Xh,delta_Xs)
	
// how many detector tubes to mask?
	pixSizeX = VCALC_getPixSizeX(target)
	pixSizeY = VCALC_getPixSizeY(target)

// offset of B, in "pixels" -in Y-direction
	offset_B = VCALC_getPanelTranslation(target)/pixSizeY		//[cm]
	offset_B = -trunc(offset_B)
	//since "target" is MT, use y-position
	// at what "pixel" does the shadow start?
	delta_Y_pix = trunc(delta/pixSizeY)
	nPix = VCALC_get_nPix_Y(target)

	if(delta_y_pix < trunc(nPix/2))
		nt = trunc(nPix/2) - delta_y_pix
		mask[][0,nt] = 1
	endif

	return(0)
end




//
// resets the mask to 0 = (use all)
//
Function VC_ResetVCALCMask()

	Variable ii
	String detStr
	
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
		mask = 0	
	endfor
	
	return(0)
end

Function/S V_SetConfigurationText()

	String str="",temp

//	SetDataFolder root:Packages:NIST:SAS
//	
//	NVAR numberOfGuides=gNg
//	NVAR gTable=gTable		//2=chamber, 1=table
//	NVAR wavelength=gLambda
//	NVAR lambdaWidth=gDeltaLambda
////	NVAR instrument = instrument
//	NVAR L2diff = L2diff
//   NVAR lens = root:Packages:NIST:SAS:gUsingLenses
//	SVAR/Z aStr = root:Packages:NIST:gAngstStr
//	SVAR selInstr = root:Packages:NIST:SAS:gInstStr

	NVAR min_f = root:Packages:NIST:VSANS:VCALC:gQmin_F
	NVAR max_f = root:Packages:NIST:VSANS:VCALC:gQmax_F
	NVAR min_m = root:Packages:NIST:VSANS:VCALC:gQmin_M
	NVAR max_m = root:Packages:NIST:VSANS:VCALC:gQmax_M
	NVAR min_b = root:Packages:NIST:VSANS:VCALC:gQmin_B
	NVAR max_b = root:Packages:NIST:VSANS:VCALC:gQmax_B
	
	String aStr = "A"
	
	sprintf temp,"Source Aperture Diameter =\t\t%6.2f cm\r",VC_sourceApertureDiam()
	str += temp
	sprintf temp,"Source to Sample =\t\t\t\t%6.0f cm\r",VC_calcSSD()
	str += temp
//	sprintf temp,"Sample Position to Detector =\t%6.0f cm\r",VC_getSDD("ML")
//	str += temp
	sprintf temp,"Beam diameter (Mid) =\t\t\t%6.2f cm\r",VC_beamDiameter("maximum","ML")
	str += temp
	sprintf temp,"Beamstop diameter =\t\t\t\t%6.2f inches\r",VC_beamstopDiam("ML")/2.54
	str += temp
	sprintf temp,"Back: Min -> Max Q-value =\t\t\t%6.4f -> %6.4f 1/%s \r",min_b,max_b,aStr
	str += temp
	sprintf temp,"Middle: Min -> Max Q-value =\t\t%6.4f -> %6.4f 1/%s \r",min_m,max_m,aStr
	str += temp
	sprintf temp,"Front: Min -> Max Q-value =\t\t%6.4f -> %6.4f 1/%s \r",min_f,max_f,aStr
	str += temp
	sprintf temp,"Beam Intensity =\t\t\t\t%.0f counts/s\r",V_beamIntensity()
	str += temp
	sprintf temp,"Figure of Merit =\t\t\t\t%3.3g %s^2/s\r",VC_figureOfMerit(),aStr
	str += temp
//	sprintf temp,"Attenuator transmission =\t\t%3.3g = Atten # %d\r"//,attenuatorTransmission(),attenuatorNumber()
//	str += temp
////	
//	// add text of the user-edited values
//	//
	sprintf temp,"***************** %s *** %s *****************\r","VSANS","VSANS"
	str += temp
	sprintf temp,"Sample Aperture Diameter =\t\t\t\t%.2f cm\r",VC_sampleApertureDiam()
	str += temp
	sprintf temp,"Number of Guides =\t\t\t\t\t\t%d \r", VC_getNumGuides()
	str += temp
	sprintf temp,"Back: Sample Position to Detector =\t\t\t%.1f cm\r", VC_getSDD("B")
	str += temp
	sprintf temp,"Middle: Sample Position to Detector =\t\t%.1f cm\r", VC_getSDD("ML")
	str += temp
	sprintf temp,"\tOffsets (L,R) (T,B) = (%.2f, %.2f) (%.2f, %.2f) cm\r", VCALC_getPanelTranslation("ML"),VCALC_getPanelTranslation("MR"),VCALC_getPanelTranslation("MT"),VCALC_getPanelTranslation("MB")
	str += temp
	sprintf temp,"Front: Sample Position to Detector =\t\t\t%.1f cm\r", VC_getSDD("FL")
	str += temp
	sprintf temp,"\tOffsets (L,R) (T,B) = (%.2f, %.2f) (%.2f, %.2f) cm\r", VCALC_getPanelTranslation("FL"),VCALC_getPanelTranslation("FR"),VCALC_getPanelTranslation("FT"),VCALC_getPanelTranslation("FB")
	str += temp
//	if(gTable==1)
//		sprintf temp,"Sample Position is \t\t\t\t\t\tHuber\r"
//	else
//		sprintf temp,"Sample Position is \t\t\t\t\t\tChamber\r"
//	endif 
//	str += temp
//	sprintf temp,"Detector Offset =\t\t\t\t\t\t%.1f cm\r", detectorOffset()
//	str += temp
	sprintf temp,"Neutron Wavelength =\t\t\t\t\t%.2f %s\r", VCALC_getWavelength(),aStr
	str += temp
	sprintf temp,"Wavelength Spread, FWHM =\t\t\t\t%.3f\r", VCALC_getWavelengthSpread()
	str += temp
//	sprintf temp,"Sample Aperture to Sample Position =\t%.2f cm\r", L2Diff
//  	str += temp
//  	if(lens==1)
//		sprintf temp,"Lenses are IN\r"
//	else
//		sprintf temp,"Lenses are OUT\r"
//	endif
//	str += temp 
   	
   setDataFolder root:
   return str			 
End

//Write String representing NICE VSANS configuration
Function/S V_SetNICEConfigText()
	
	string temp_s

	String titleStr
	String keyStr,keyStrEnd
	String valueStr,valueStrEnd
	String closingStr
	String nameStr,valStr,str

	keyStr = "        {\r          \"key\": {\r            \"class\": \"java.lang.String\",\r            \"value\": \""
	keyStrEnd = "\"\r          },\r"

	valueStr = "          \"value\": {\r            \"class\": \"java.lang.String\",\r            \"value\": \""
	valueStrEnd = "\"\r          }\r        },\r"

	closingStr = "\"\r          }\r        }\r      ]\r    }\r  }\r]\r"

	str = "Dummy filler"

	titleStr = "VCALC Configuration"

	temp_s = ""

	temp_s = "[\r  {\r    \"key\": {\r      \"class\": \"java.lang.String\",\r"
	temp_s += "      \"value\": \""+titleStr+"\"\r    },\r"
	temp_s += "    \"value\": {\r      \"class\": \"java.util.HashMap\",\r      \"value\": [\r"
	
//front
	nameStr = "frontTrans.primaryNode"
	valStr = num2Str(VC_getGateValveToDetDist("FL")) + "cm"		//nominal distance, any panel will do
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "carriage.frontRight"
	valStr = num2Str(VCALC_getPanelTranslation("FR")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "carriage.frontLeft"
	valStr = num2Str(VCALC_getPanelTranslation("FL")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd	
		
	nameStr = "carriage.frontTop"
	valStr = num2Str(VCALC_getPanelTranslation("FT")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "carriage.frontBottom"
	valStr = num2Str(VCALC_getPanelTranslation("FB")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontRightAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","FR")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
		
	nameStr = "frontRightAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","FR")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontLeftAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","FL")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "frontLeftAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","FL")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontTopAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","FT")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontTopAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","FT")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontBottomAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","FB")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "frontBottomAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","FB")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	

	
// middle		
	nameStr = "middleTrans.primaryNode"
	valStr = num2Str(VC_getGateValveToDetDist("ML")) + "cm"		//nominal distance, any panel will do
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "carriage.middleRight"
	valStr = num2Str(VCALC_getPanelTranslation("MR")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "carriage.middleLeft"
	valStr = num2Str(VCALC_getPanelTranslation("ML")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "carriage.middleTop"
	valStr = num2Str(VCALC_getPanelTranslation("MT")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "carriage.middleBottom"
	valStr = num2Str(VCALC_getPanelTranslation("MB")) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "middleRightAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","MR")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "middleRightAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","MR")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "middleLeftAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","ML")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd		

	nameStr = "middleLeftAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","ML")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
		
	nameStr = "middleTopAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","MT")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "middleTopAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","MT")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "middleBottomAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x("VCALC","MB")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "middleBottomAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y("VCALC","MB")) + "cm"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "C2BeamStop.beamStop"
	valStr = num2Str(1) 
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "C2BeamStopY.softPosition"
	valStr = num2Str(0) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "C2BeamStopX.X"
	valStr = num2Str(0) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd


// back
	nameStr = "rearTrans.primaryNode"
	valStr = num2Str(VC_getGateValveToDetDist("B")) + "cm"		//nominal distance, any panel will do
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "C3DetectorOffset.softPosition"
	valStr = num2Str(0) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "rearAreaDetector.beamCenterX"
	valStr = num2Str(V_getDet_beam_center_x_pix("VCALC","B"))
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "rearAreaDetector.beamCenterY"
	valStr = num2Str(V_getDet_beam_center_y_pix("VCALC","B"))
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "C3BeamStop.beamStop"
	valStr = num2Str(0)
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "C3BeamStopY.softPosition"
	valStr = num2Str(0) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "C3BeamStopX.X"
	valStr = num2Str(0) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd



//geometry, guides, beam...

	nameStr = "guide.guide"
	valStr = num2Str(VC_getNumGuides())
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "guide.sampleAperture"
	valStr = num2Str(VC_sampleApertureDiam()) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "guide.sourceAperture"
	valStr = num2Str(VC_sourceApertureDiam()) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "geometry.externalSampleApertureShape"
	valStr = "CIRCLE"
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "geometry.externalSampleAperture"
	valStr = num2Str(VC_sampleApertureDiam()) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "geometry.samplePositionOffset"
	valStr = num2Str(V_sampleToGateValve()) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "geometry.sampleApertureOffset"
	valStr = num2Str(V_sampleApertureToGateValve()) + "cm"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "attenuator.attenuator"
	valStr = num2Str(0)
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd

	nameStr = "wavelength.wavelength"
	valStr = num2Str(VCALC_getWavelength()) + "A"		//no space before unit
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + valueStrEnd
	
	nameStr = "wavelengthSpread.wavelengthSpread"
	valStr = num2Str(VCALC_getWavelengthSpread())
// last one has a different ending sequence	
	temp_s += keyStr + nameStr + keyStrEnd
	temp_s += valueStr + valStr + closingStr
		
	return temp_s
end

