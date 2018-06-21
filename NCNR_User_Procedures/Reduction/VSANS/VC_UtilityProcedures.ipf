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


// returns the nominal SDD from the panel -- value is [cm]
// Does NOT include the setback of the T/B panels. This is a separate value
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

//	SetDataFolder root:Packages:NIST:VSANS:VCALC
//			
//	strswitch(type)	
//		case "FL":
//			NVAR pixSizeX = gFront_L_pixelX
//			break
//		case "FR":		
//			NVAR pixSizeX = gFront_R_pixelX
//			break
//		case "FT":
//			NVAR pixSizeX = gFront_T_pixelX
//			break	
//		case "FB":		
//			NVAR pixSizeX = gFront_B_pixelX
//			break
//			
//		case "ML":
//			NVAR pixSizeX = gMiddle_L_pixelX
//			break
//		case "MR":		
//			NVAR pixSizeX = gMiddle_R_pixelX
//			break
//		case "MT":
//			NVAR pixSizeX = gMiddle_T_pixelX
//			break	
//		case "MB":		
//			NVAR pixSizeX = gMiddle_B_pixelX
//			break
//						
//		case "B":		
//			NVAR pixSizeX = gBack_pixelX
//			break
//			
//		default:							
//			Print "Detector type mismatch in 	V_getPixSizeX(type)"
//			setDataFolder root:
//			return(NaN)
//	endswitch
//
//	setDataFolder root:
		
	return(pixSizeX)
end

// return the pixel Y size, in [cm]
Function VCALC_getPixSizeY(type)
	String type

	Variable pixSizeY = V_getDet_y_pixel_size("VCALC",type)
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC
//			
//	strswitch(type)	
//		case "FL":
//			NVAR pixSizeY = gFront_L_pixelY
//			break
//		case "FR":		
//			NVAR pixSizeY = gFront_R_pixelY
//			break
//		case "FT":
//			NVAR pixSizeY = gFront_T_pixelY
//			break	
//		case "FB":		
//			NVAR pixSizeY = gFront_B_pixelY
//			break
//			
//		case "ML":
//			NVAR pixSizeY = gMiddle_L_pixelY
//			break
//		case "MR":		
//			NVAR pixSizeY = gMiddle_R_pixelY
//			break
//		case "MT":
//			NVAR pixSizeY = gMiddle_T_pixelY
//			break	
//		case "MB":		
//			NVAR pixSizeY = gMiddle_B_pixelY
//			break
//						
//		case "B":		
//			NVAR pixSizeY = gBack_pixelY
//			break
//			
//		default:							
//			Print "Detector type mismatch in 	V_getPixSizeY(type)"
//			SetDataFolder root:
//			return(NaN)
//	endswitch
//
//	setDatafolder root:
		
	return(pixSizeY)
end


// return the number of pixels in x-dimension
Function VCALC_get_nPix_X(type)
	String type

	Variable nPix = V_getDet_pixel_num_x("VCALC",type)
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC
//			
//	strswitch(type)	
//		case "FL":
//			NVAR nPix = gFront_L_nPix_X
//			break
//		case "FR":		
//			NVAR nPix = gFront_R_nPix_X
//			break
//		case "FT":
//			NVAR nPix = gFront_T_nPix_X
//			break	
//		case "FB":		
//			NVAR nPix = gFront_B_nPix_X
//			break
//			
//		case "ML":
//			NVAR nPix = gMiddle_L_nPix_X
//			break
//		case "MR":		
//			NVAR nPix = gMiddle_R_nPix_X
//			break
//		case "MT":
//			NVAR nPix = gMiddle_T_nPix_X
//			break	
//		case "MB":		
//			NVAR nPix = gMiddle_B_nPix_X
//			break
//						
//		case "B":		
//			NVAR nPix = gBack_nPix_X
//			break
//			
//		default:							
//			Print "Detector type mismatch in 	VCALC_get_nPix_X(type)"
//			SetDataFolder root:
//			return(NaN)
//	endswitch
//
//	setDataFolder root:
		
	return(nPix)
end

// return the number of pixels in y-dimension
Function VCALC_get_nPix_Y(type)
	String type

	Variable nPix = V_getDet_pixel_num_y("VCALC",type)

//	SetDataFolder root:Packages:NIST:VSANS:VCALC
//			
//	strswitch(type)	
//		case "FL":
//			NVAR nPix = gFront_L_nPix_Y
//			break
//		case "FR":		
//			NVAR nPix = gFront_R_nPix_Y
//			break
//		case "FT":
//			NVAR nPix = gFront_T_nPix_Y
//			break	
//		case "FB":		
//			NVAR nPix = gFront_B_nPix_Y
//			break
//			
//		case "ML":
//			NVAR nPix = gMiddle_L_nPix_Y
//			break
//		case "MR":		
//			NVAR nPix = gMiddle_R_nPix_Y
//			break
//		case "MT":
//			NVAR nPix = gMiddle_T_nPix_Y
//			break	
//		case "MB":		
//			NVAR nPix = gMiddle_B_nPix_Y
//			break
//						
//		case "B":		
//			NVAR nPix = gBack_nPix_Y
//			break
//			
//		default:							
//			Print "Detector type mismatch in 	VCALC_get_nPix_Y(type)"
//			SetDataFolder root:
//			return(NaN)
//	endswitch
//
//	SetDataFolder root:
		
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

// read the number of guides from the slider
// return the Source to Sample Distance in [cm]
Function VC_calcSSD()

	Variable ng,ssd
	ControlInfo VCALCCtrl_0a
	ng = V_Value
	
	ssd = 2388 - ng*200
	print "SSD (cm) = ",ssd
	return(ssd)
End


// read the number of guides from the slider
// return the Source aperture diameter [cm]
// TODO - needs a case statement since a1 can depend on Ng
Function VC_sourceApertureDiam()

	Variable ng,a1
	ControlInfo VCALCCtrl_0a
	ng = V_Value
	
	a1 = 6		// 60 mm diameter

	Print "Source Ap diam (cm) = ",a1
	return(a1)
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
Function VC_FrontMiddlePreset()

	// front carriage
	SetVariable VCALCCtrl_2a,value=_NUM:-20		//Left offset
	SetVariable VCALCCtrl_2aa,value=_NUM:20		//Right offset
	SetVariable VCALCCtrl_2b,value=_NUM:4			//Top offset
	SetVariable VCALCCtrl_2bb,value=_NUM:-4		//Bottom offset

	SetVariable VCALCCtrl_2d,value=_NUM:120		//SDD

	// middle carriage
	SetVariable VCALCCtrl_3a,value=_NUM:0		//Left offset
	SetVariable VCALCCtrl_3aa,value=_NUM:0		//Right offset
	SetVariable VCALCCtrl_3b,value=_NUM:4			//Top offset (doesn't matter)
	SetVariable VCALCCtrl_3bb,value=_NUM:-4		//Bottom offset (doesn't matter)

	SetVariable VCALCCtrl_3d,value=_NUM:1900		//SDD
	
	
	// monochromator
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector"
	
	// wavelength spread
	SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	DLStr = "0.12;"
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	
	// wavelength
	SetVariable VCALCCtrl_0b,value=_NUM:8,disable=0	,noedit=0	// allow user editing again

	//number of guides
	Slider VCALCCtrl_0a,value= 0


// binning mode
	PopupMenu popup_b,mode=1,popValue="F2-M2xTB-B"


	return(0)
End

//
//direction = one of "vertical;horizontal;maximum;"
// all of this is bypassed if the lenses are in
//
// carrNum = 1,2,3 for F,M,B
//
// returns a value in [cm]
Function VC_beamDiameter(direction,carrNum)
	String direction
	Variable carrNum

//	NVAR lens = root:Packages:NIST:SAS:gUsingLenses
//	if(lens)
//		return sourceApertureDiam()
//	endif
	
	Variable l1,l2,l2Diff
	Variable d1,d2,bh,bv,bm,umbra,a1,a2
	Variable lambda,lambda_width,bs_factor
    
//    NVAR L2diff = root:Packages:NIST:SAS:L2diff

// TODO: proper value for l2Diff, bs_factor
	l2Diff = 0
	bs_factor = 1.05
	
	l1 = VC_calcSSD()
	lambda = VCALC_getWavelength()
	ControlInfo VCALCCtrl_0d
	lambda_width = str2num(S_Value)
	
	
	l2 = VC_getSDD(carrNum) + L2diff
    
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
Function VC_getSDD(carrNum)
	Variable carrNum
	
	if(carrNum == 1)
		ControlInfo VCALCCtrl_2d
	endif
	if(carrNum == 2)
		ControlInfo VCALCCtrl_3d
	endif
	if(carrNum == 3)
		ControlInfo VCALCCtrl_4b
	endif
	
	return(V_Value)
end
	

// these are numbers from NG3, when it was a SANS instrument
//	
// updated with new flux numbers from John Barker
// NG3 - Feb 2009
// NG7 - July 2009
//
// guide loss has been changed to 0.95 rather than the old value of 0.95
//
// other values are changed in the initialization routines
//
Function beamIntensity()

	Variable alpha,f,t,t4,t5,t6,as,solid_angle,l1,d2_phi
	Variable a1,a2,retVal
	Variable l_gap,guide_width,ng
	Variable lambda_t,b,c
	Variable lambda,t1,t2,t3,phi_0
	Variable lambda_width
	Variable guide_loss

	NVAR gBeamInten = root:Packages:NIST:VSANS:VCALC:gBeamIntensity

 
// TODO
// these are numbers from NG3, when it was a SANS instrument
	
	lambda_t = 5.50

 	t1 = 0.63
	t2 = 1.0
	t3 = 0.75
	l_gap = 100.0
	guide_width = 6.0
 
	//new values, from 11/2009 --- BeamFluxReport_2009.ifn
	phi_0 = 2.42e13
	b = 0.0
	c = -0.0243
	guide_loss = 0.924
	 
	 
	 
 	ControlInfo VCALCCtrl_0a
	ng = V_Value
 
 	lambda = VCALC_getWavelength()
 	ControlInfo VCALCCtrl_0d
 	lambda_width = str2num(S_Value)
 
    
	l1 = VC_calcSSD()
    
    // TODO verify that these values are in cm
	a1 = VC_sourceApertureDiam()
    
	// sample aperture diam [cm]
	ControlInfo VCALCCtrl_1c
	a2 = V_Value
    
    
	alpha = (a1+a2)/(2*l1)	//angular divergence of beam
	f = l_gap*alpha/(2*guide_width)
	t4 = (1-f)*(1-f)
	t5 = exp(ng*ln(guide_loss))	// trans losses of guides in pre-sample flight
	t6 = 1 - lambda*(b-(ng/8)*(b-c))		//experimental correction factor
	t = t1*t2*t3*t4*t5*t6
    
	as = pi/4*a2*a2		//area of sample in the beam
	d2_phi = phi_0/(2*pi)
	d2_phi *= exp(4*ln(lambda_t/lambda))
	d2_phi *= exp(-1*(lambda_t*lambda_t/lambda/lambda))

	solid_angle = pi/4* (a1/l1)*(a1/l1)

	retVal = as * d2_phi * lambda_width * solid_angle * t

	// set the global for display
	gBeamInten = retVal
	return (retVal)
end

//
Function VC_figureOfMerit()

	Variable bi = beamIntensity()
	Variable lambda = VCALC_getWavelength()
	
   return (lambda*lambda*bi)
End

// return a beamstop diameter (cm) larger than maximum beam dimension
Function VC_beamstopDiam(carrNum)
	Variable carrNum
	
	Variable bm=0
	Variable bs=0.0
   Variable yesLens=0
   
	if(yesLens)
		//bm = sourceApertureDiam()		//ideal result, not needed
		bs = 1								//force the diameter to 1"
	else
		bm = VC_beamDiameter("maximum",carrNum)
		do
	    	bs += 1
	   while ( (bs*2.54 < bm) || (bs > 30.0)) 			//30 = ridiculous limit to avoid inf loop
	endif

	return (bs*2.54)		//return diameter in cm, not inches for txt
End


