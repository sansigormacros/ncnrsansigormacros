#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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




// returns the panel separation [cm]
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

// reports tha value in [cm]
Function VC_sampleApertureDiam()

	ControlInfo/W=VCALC VCALCCtrl_1c
	Variable val = str2num(S_Value)

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
	SetVariable VCALCCtrl_0b,value=_NUM:6

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
	SetVariable VCALCCtrl_0b,value=_NUM:6

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
	SetVariable VCALCCtrl_0b,value=_NUM:6

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
	SetVariable VCALCCtrl_0b,value=_NUM:6

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

	VC_Preset_FrontMiddle_Ng0()		// moves Middle into contact (but w/ wrong lambda)
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="White Beam"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.40;"
//	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40"

// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:5.3,disable=0	,noedit=0	// allow user editing again
	
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
	SetVariable VCALCCtrl_0b,value=_NUM:4.75,disable=0	,noedit=0	// allow user editing again

	//number of guides
	Slider VCALCCtrl_0a,value= 0


// binning mode
	PopupMenu popup_b,mode=1,popValue="F4-M4-B"

	return(0)
end

// calculates L2, the sample aperture to detector distance
Function VC_calc_L2(detStr)
	String detStr

	Variable a2_to_GV,sam_to_GV,sdd,l2
	sdd = VC_getSDD(detStr)			//sample pos to detector
	ControlInfo VCALCCtrl_1d
	a2_to_GV = V_Value
	ControlInfo VCALCCtrl_1e
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
	ControlInfo VCALCCtrl_1d
	a2_to_GV = V_Value
	ControlInfo VCALCCtrl_1e
	sam_to_GV = V_Value
	l2 = sdd - sam_to_GV + a2_to_GV
   
   
    // TODO verify that these values are in cm
	a1 = VC_sourceApertureDiam()
    
	// sample aperture diam [cm]
	ControlInfo VCALCCtrl_1c
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
			ControlInfo VCALCCtrl_4b
			break
		case "ML":
		case "MR":
		case "MT":
		case "MB":
			ControlInfo VCALCCtrl_3d
			break
		case "FL":
		case "FR":
		case "FT":
		case "FB":
			ControlInfo VCALCCtrl_2d
			break		
		default:
			Print "no case matched in VC_getSDD()"
	endswitch

	// this is gate valve to detector distance
	sdd = V_Value
	
	sdd += VCALC_getTopBottomSDDSetback(detStr)
	
	// VCALCCtrl_1e is Sample Pos to Gate Valve (cm)
	ControlInfo VCALCCtrl_1e
	sdd += V_Value
	
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

	NVAR gBeamInten = root:Packages:NIST:VSANS:VCALC:gBeamIntensity
 
// TODO
// -- verify these numbers
	lambda_t = 6.20
	phi_0 = 1.82e13
	guide_loss = 0.97
	t_special = 1

 	ControlInfo VCALCCtrl_0a
	ng = V_Value
 
 	lambda = VCALC_getWavelength()
 	lambda_width = VCALC_getWavelengthSpread()
	l1 = VC_calcSSD()
    
    // TODO verify that these values are in cm
	a1 = VC_sourceApertureDiam()
    
	// sample aperture diam [cm]
	a2 = VC_sampleApertureDiam()
    
//	alpha = (a1+a2)/(2*l1)	//angular divergence of beam
//	f = l_gap*alpha/(2*guide_width)
//	t4 = (1-f)*(1-f)
//	t6 = 1 - lambda*(b-(ng/8)*(b-c))		//experimental correction factor

	t_guide = exp(ng*ln(guide_loss))	// trans losses of guides in pre-sample flight
	t_filter = exp(-0.371 - 0.0305*lambda - 0.00352*lambda*lambda)
	t_total = t_special*t_guide*t_filter

    
	as = pi/4*a2*a2		//area of sample in the beam
	d2_phi = phi_0/(2*pi)
	d2_phi *= exp(4*ln(lambda_t/lambda))
	d2_phi *= exp(-1*(lambda_t*lambda_t/lambda/lambda))

	solid_angle = pi/4* (a1/l1)*(a1/l1)

	retVal = as * d2_phi * lambda_width * solid_angle * t_total

	// set the global for display
	gBeamInten = retVal
	
	return (retVal)
end

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


//	root:Packages:NIST:VSANS:VCALC:fSubS_qxqy_MLR
//	root:Packages:NIST:VSANS:VCALC:iBin_qxqy_MLR
	
	Variable ii
	String ext
//	loop over all of the types of data
	for(ii=0;ii<ItemsInList(extStr);ii+=1)
		ext = StringFromList(ii, extStr, ";")
		Wave iq = $(folderStr+"iBin_qxqy_"+ext)
		Wave fs = $(folderStr+"fSubS_qxqy_"+ext)
		iq = (fs < 0.1) ? iq*0.1 : iq*fs
//		iq *= fs
	endfor	
	
	return(0)
end