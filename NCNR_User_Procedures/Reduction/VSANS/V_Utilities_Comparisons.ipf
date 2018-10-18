#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
//
// utility procedures for comparing values in files to ensure that certain operations
// such as transmssion, adding raw files, etc. can be properly completed
//
//
// basic results are that:
//  matching = 1 = true = OK
//  no match = 0 = false = NOT OK
//
// V_CloseEnough tolerance is an absolute value
// so passing 0.01*val_1 = 1% tolerance, as long as val_1 can't be zero
//
// SEP 2018 -- increased the tolerance to 2%, since I was getting false differences
// especially for the lateral offset after switching from trans->scatter configs. Panel
// was returning to postion, but within 2% (since the value was near zero)
//


// Function to test if two raw data files were collected at identical conditions.
// this function does as many test as I can think of to compare the conditions.
//
// A test like this is to be used before two raw data files can be added together.
//
// TODO:
// long list of points that need to match up to be sure that the conditions are all the same
//
//
// depending on how long these checks take, may want a way to bypass this with a flag
//
// if any of the match conditions fail, exit immediately
//
//
Function V_RawFilesMatchConfig(fname1,fname2)
	String fname1,fname2

	Variable ii
	String detStr
	
// collimation conditions	
// wavelength	
	if(!V_FP_Value_Match(V_getWavelength,fname1,fname2))
		return(0)	//no match
	endif
	
// wavelength spread
	if(!V_FP_Value_Match(V_getWavelength_spread,fname1,fname2))
		return(0)	//no match
	endif

// monochromator type	
	if(!V_String_Value_Match(V_getMonochromatorType,fname1,fname2))
		return(0)
	endif
	
// number of guides	(or narrow_slit, etc.)
	if(!V_String_Value_Match(V_getNumberOfGuides,fname1,fname2))
		return(0)
	endif
	
	
//// detector conditions
//// loop over all of the detectors

// detector distance and offset
// I DON'T need to check all of the distances, just three will do
	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"FL"))
		return(0)	//no match
	endif

	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"ML"))
		return(0)	//no match
	endif
	
	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"B"))
		return(0)	//no match
	endif
	
	
// I DO need to check all of the offset values
	//// only return value for B and L/R detectors. everything else returns zero
	//Function V_getDet_LateralOffset(fname,detStr)
	//
	//// only return values for T/B. everything else returns zero
	//Function V_getDet_VerticalOffset(fname,detStr)
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		if(!V_FP2_Value_Match(V_getDet_LateralOffset,fname1,fname2,detStr))
			return(0)	//no match
		endif
		if(!V_FP2_Value_Match(V_getDet_VerticalOffset,fname1,fname2,detStr))
			return(0)	//no match
		endif
	endfor
	

// messy - if the shape=circle, then look at size
// but if shape=rectangle, look at height and width
// source aperture shape, size
	if(!V_String_Value_Match(V_getSourceAp_shape,fname1,fname2))
		return(0)
	endif
// sample aperture shape, size
	if(!V_String_Value_Match(V_getSampleAp2_shape,fname1,fname2))
		return(0)
	endif

	return(1)		// passed all of the tests, OK, it's a match
End


// given an open beam file, to identify the allowable transmission measurements,
// the conditions to meet are:
//
// wavelength
// wavelength spread
// detector distance(s)
// detector offset(s) (this ensures that the same panel is catching the direct beam)
//
// ? do I need to check beam stop locations ?
//
Function V_Trans_Match_Open(fname1,fname2)
	String fname1,fname2

	Variable ii
	String detStr
	
// collimation conditions	
// wavelength	
	if(!V_FP_Value_Match(V_getWavelength,fname1,fname2))
		return(0)	//no match
	endif
	
// wavelength spread
	if(!V_FP_Value_Match(V_getWavelength_spread,fname1,fname2))
		return(0)	//no match
	endif

//// monochromator type	
//	if(!V_String_Value_Match(V_getMonochromatorType,fname1,fname2))
//		return(0)
//	endif
//	
//// number of guides	(or narrow_slit, etc.)
//	if(!V_String_Value_Match(V_getNumberOfGuides,fname1,fname2))
//		return(0)
//	endif
	
	
//// detector conditions
//// loop over all of the detectors

// detector distance and offset
// I DON'T need to check all of the distances, just three will do
	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"FL"))
		return(0)	//no match
	endif

	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"ML"))
		return(0)	//no match
	endif
	
	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"B"))
		return(0)	//no match
	endif
	
	
//// ???Do I need to check all of the offset values
//	//// only return value for B and L/R detectors. everything else returns zero
//	//Function V_getDet_LateralOffset(fname,detStr)
//	//
//	//// only return values for T/B. everything else returns zero
//	//Function V_getDet_VerticalOffset(fname,detStr)
//	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
//		detStr = StringFromList(ii, ksDetectorListAll, ";")
//		if(!V_FP2_Value_Match(V_getDet_LateralOffset,fname1,fname2,detStr))
//			return(0)	//no match
//		endif
//		if(!V_FP2_Value_Match(V_getDet_VerticalOffset,fname1,fname2,detStr))
//			return(0)	//no match
//		endif
//	endfor

// only check the panel position for the actual panel used for the open beam measurement
	detStr = V_getReduction_BoxPanel(fname1)
	if(!V_FP2_Value_Match(V_getDet_LateralOffset,fname1,fname2,detStr))
		return(0)	//no match
	endif

	return(1)		// passed all of the tests, OK, it's a match
End


// given a transmission file, identify the possible scattering files:
//
// first, the group ID must match
// then, as far as configurations:
//
// need to match
// wavelength
// wavelength spread
// (I think that is all - since the transmission is only dependent on these values)
//
Function V_Scatter_Match_Trans(fname1,fname2)
	String fname1,fname2

	Variable ii
	String detStr
	
// collimation conditions	
// wavelength	
	if(!V_FP_Value_Match(V_getWavelength,fname1,fname2))
		return(0)	//no match
	endif
	
// wavelength spread
	if(!V_FP_Value_Match(V_getWavelength_spread,fname1,fname2))
		return(0)	//no match
	endif

//// monochromator type	
//	if(!V_String_Value_Match(V_getMonochromatorType,fname1,fname2))
//		return(0)
//	endif
//	
//// number of guides	(or narrow_slit, etc.)
//	if(!V_String_Value_Match(V_getNumberOfGuides,fname1,fname2))
//		return(0)
//	endif
	
	
////// detector conditions
////// loop over all of the detectors
//
//// detector distance and offset
//// I DON'T need to check all of the distances, just three will do
//	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"FL"))
//		return(0)	//no match
//	endif
//
//	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"ML"))
//		return(0)	//no match
//	endif
//	
//	if(!V_FP2_Value_Match(V_getDet_NominalDistance,fname1,fname2,"B"))
//		return(0)	//no match
//	endif
//	
//	
//// I DO need to check all of the offset values
//	//// only return value for B and L/R detectors. everything else returns zero
//	//Function V_getDet_LateralOffset(fname,detStr)
//	//
//	//// only return values for T/B. everything else returns zero
//	//Function V_getDet_VerticalOffset(fname,detStr)
//	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
//		detStr = StringFromList(ii, ksDetectorListAll, ";")
//		if(!V_FP2_Value_Match(V_getDet_LateralOffset,fname1,fname2,detStr))
//			return(0)	//no match
//		endif
//		if(!V_FP2_Value_Match(V_getDet_VerticalOffset,fname1,fname2,detStr))
//			return(0)	//no match
//		endif
//	endfor

	return(1)		// passed all of the tests, OK, it's a match
End





Function V_String_Value_Match(func,fname1,fname2)
	FUNCREF proto_V_get_STR func
	String fname1,fname2
	
	Variable match=0
	String val1,val2
	val1 = func(fname1)
	val2 = func(fname2)
	
//	Print val1
	match = (cmpstr(val1,val2) == 0)		// match = 1 if the strings match, 0 if they don't match
//	print match
	
	return(match)
End


Function V_FP_Value_Match(func,fname1,fname2)
	FUNCREF proto_V_get_FP func
	String fname1,fname2
	
	Variable match=0
	Variable val1,val2,tol
	val1 = func(fname1)
	val2 = func(fname2)
	
	if(val1 == 0 && val2 == 0)
		return(1)		// a match
	endif

	if(val1 != 0)
		tol = abs(0.02 * val1)
	else
		tol = abs(0.02 * val2)
	endif
	
//	match = V_CloseEnough(val1,val2,0.01*val1)
	match = V_CloseEnough(val1,val2,tol)
	
	return(match)
End

// when a detector string is needed
Function V_FP2_Value_Match(func,fname1,fname2,detStr)
	FUNCREF proto_V_get_FP2 func
	String fname1,fname2,detStr
	
	Variable match=0
	Variable val1,val2,tol
	val1 = func(fname1,detStr)
	val2 = func(fname2,detStr)
	
	if(val1 == 0 && val2 == 0)
		return(1)		// a match
	endif
	
	if(val1 != 0)
		tol = abs(0.02 * val1)
	else
		tol = abs(0.02 * val2)
	endif
	
	match = V_CloseEnough(val1,val2,tol)
	
	return(match)
End


// parse through conditions in the data file to generate a string
// that represents the collimation condition so that the proper resolution
// can be calculated during the averaging step
//
// possible values are:
//
// pinhole
// pinhole_whiteBeam
// narrowSlit
// narrowSlit_whiteBeam
// convergingPinholes
//
// graphite at this point is treated as pinhole, until I find evidence otherwise.
//
//
Function/S V_IdentifyCollimation(fname)
	String fname
	
	String collimationStr=""
	String status="",guides=""
	variable wb_in=0,slit=0
	
	guides = V_getNumberOfGuides(fname)
	if(cmpstr(guides,"CONV_BEAMS") == 0)
		return("convergingPinholes")
	endif

// TODO: as of 6/2018 with the converging pinholes IN, status is "out"
//	status = V_getConvPinholeStatus(fname)
//	if(cmpstr(status,"IN") == 0)
//		return("convergingPinholes")
//	endif

	status = V_getWhiteBeamStatus(fname)
	if(cmpstr(status,"IN") == 0)
		wb_in = 1
	endif	
	
	guides = V_getNumberOfGuides(fname)
	if(cmpstr(guides,"NARROW_SLITS") == 0)
		slit = 1
	endif
	
	if(wb_in == 1 && slit == 1)
		return("narrowSlit_whiteBeam")
	endif
	
	if(wb_in == 1 && slit == 0)
		return("pinhole_whiteBeam")
	endif
	
	if(wb_in == 0 && slit == 1)
		return("narrowSlit")
	endif
	
	if(wb_in == 0 && slit == 0)
		return("pinhole")
	endif
	
	// this is an error condition = null string	
	return(collimationStr)
End


// TODO -- this may not correctly mimic the enumerated type of the file
//  but I need to fudge this somehow
//
// returns null string if the type cannot be deduced, calling procedure is responsible
//  for properly handling this error condition
//
Function/S V_DeduceMonochromatorType(fname)
	String fname
	
	String typeStr=""

	if(cmpstr(V_getVelSelStatus(fname),"IN") == 0)
		typeStr = "velocity_selector"
	endif
	
	if(cmpstr(V_getWhiteBeamStatus(fname),"IN") == 0)
		typeStr = "white_beam"
	endif
	
	if(cmpstr(V_getCrystalStatus(fname),"IN") == 0)
		typeStr = "crystal"
	endif	
	
	return(typeStr)
End


// returns the beamstop diameter [mm]
// if there is no beamtop in front of the specified detector, return 0.01mm
//
Function V_DeduceBeamstopDiameter(folderStr,detStr)
	String folderStr,detStr
	
	Variable BS, dummyVal,num
	dummyVal = 0.01		//[mm]
	
	if(cmpstr("F",detStr[0]) == 0)
		// front carriage has no beamstops
		return(dummyVal)
	endif
	
	if(cmpstr("M",detStr[0]) == 0)
		// middle carriage (2)
		num = V_getBeamStopC2num_beamstops(folderStr)
		if(num)
			BS = V_getBeamStopC2_size(folderStr)
		else
			//num = 0, no beamstops in the middle.
			return(dummyVal)
		endif
	endif

	if(cmpstr("B",detStr[0]) == 0)
		// back (3)
		num = V_getBeamStopC3num_beamstops(folderStr)
		if(num)
			BS = V_getBeamStopC3_size(folderStr)
		else
			//num = 0, no beamstops on the back
			return(dummyVal)
		endif
	endif	
	
	return(BS)
end



//
// tests if two values are close enough to each other
// very useful since ICE came to be
//
// tol is an absolute value (since input v1 or v2 may be zero, can't reliably
// use a percentage
Function V_CloseEnough(v1,v2,tol)
	Variable v1, v2, tol

	if(abs(v1-v2) < tol)
		return(1)
	else
		return(0)
	endif
End

