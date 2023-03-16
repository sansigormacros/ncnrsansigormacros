#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//////////// READ (GET) FUNCTIONS ////////////////////

//
// -- JULY 2021
//
// ** look for the TODO statements -- some of these are noting HARD-WIRED
// values or other values that are currently faked since they are not currently
// part of the Nexus file definition
//
//

// TODO --- what can  getExperiment_identifier  be used for?


//////////////////////////////////////////////
//////////////////////////////////
// for TESTING of the get functions - to quickly access and se if there are errors
//
// -- not sure how to test the string functions -- can't seem to get a FUNCREF to a string function
// to work -- maybe it's not alllowed?
//
// -- also, now I have get_functions that take a detStr input with the detector information, so that the 
//    functions didn't need to be repeated
//
//	-- Not sure how to test the "write" functions. writing the wrong data type to the wrong data field will be a disaster
//    Writing odd, dummy values will also be a mess - no way to know if I'm doing anything correctly
//
Function proto_get_FP(str)
	String str
	return(0)
end

Function proto_get_FP2(str,str2)
	String str,str2
	return(0)
end

Function/S proto_get_STR(str)
	String str
	return("")
end

Proc Dump_getFP(fname)
	String fname
	
	Test_get_FP("get*",fname)
end

Function Test_get_FP(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_get_FP f = $item
		Print item ," = ", f(fname)
	endfor
	
	return(0)
end




Proc Dump_getSTR(fname)
	String fname
	
	Test_get_STR("get*",fname)
end

Function Test_get_STR(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	list = RemoveFromList("getFunctionCoef;getFunctionParams;getModelSuffix;", list)
	list = RemoveFromList("GetAList;", list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_get_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\")",item,fname
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end



//////////////////////////////////////////////


///////////////////////
//
// *These are the specific bits of information to retrieve (or write) to the data file
// *These functions use the path to the file as input, and each has the specific
//   path to the variable srting, or wave hard-coded into the access function
// *They call the generic worker functions to get the values, either from the local copy if present,
//   or the full file is loaded.
//
// *Since the path is the important bit, these are written as get/write pairs to make it easier to 
//   keep up with any changes in path
//
//
// (DONE) -- verify the paths, and add more as needed
//  -- for all of the String functions -- "num" does nothing right now - 
//         -- if it ever does, or needs to, a lot of locations will need to be corrected
//


//////// TOP LEVEL
//////// TOP LEVEL
//////// TOP LEVEL

//// nexus version used for definitions
//Function/S getNeXus_version(fname)
//	String fname
//	
//	String path = "entry:NeXus_version"	
//	Variable num=60
//	return(getStringFromHDF5(fname,path,num))
//End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function getCollectionTime(fname)
	String fname
	
	String path = "entry:collection_time"	
	return(getRealValueFromHDF5(fname,path))
End

// data directory where data files are stored (for user access, not archive)
Function/S getData_directory(fname)
	String fname
	
	String path = "entry:data_directory"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// Base class of Nexus definition (=NXsas)
Function/S getNexusDefinition(fname)
	String fname
	
	String path = "entry:definition"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function getDataDuration(fname)
	String fname
	
	String path = "entry:duration"	
	return(getRealValueFromHDF5(fname,path))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection end time
Function/S getDataEndTime(fname)
	String fname
	
	String path = "entry:end_time"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// experiment description
Function/S getExperiment_description(fname)
	String fname
	
	String path = "entry:experiment_description"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// experiment identifier? used only by NICE?
Function/S getExperiment_identifier(fname)
	String fname
	
	String path = "entry:experiment_identifier"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// name of facility = NCNR
Function/S getFacility(fname)
	String fname
	
	String path = "entry:facility"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


// (DONE) -- not mine, added somewhere by Nexus writer?
Function/S getProgram_name(fname)
	String fname
	
	String path = "entry:program_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection start time
Function/S getDataStartTime(fname)
	String fname
	
	String path = "entry:start_time"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End
		
// title of experiment
Function/S getTitle(fname)
	String fname
	
	String path = "entry:title"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
end
	
	
		
////////// USER
////////// USER
////////// USER

// list of user names
//  x- currently not written out to data file??
Function/S getUserNames(fname)
	String fname
	
	String path = "entry:user:name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
end


//////// CONTROL
//////// CONTROL
//////// CONTROL

// (DONE) -- for the control section, document each of the fields


Function getCount_end(fname)
	String fname
	
	String path = "entry:control:count_end"	
	return(getRealValueFromHDF5(fname,path))
end

Function getCount_start(fname)
	String fname
	
	String path = "entry:control:count_start"	
	return(getRealValueFromHDF5(fname,path))
end


Function getCount_time(fname)
	String fname
	
	String path = "entry:control:count_time"	
	return(getRealValueFromHDF5(fname,path))
end


Function getCount_time_preset(fname)
	String fname
	
	String path = "entry:control:count_time_preset"	
	return(getRealValueFromHDF5(fname,path))
end


Function getDetector_counts(fname)
	String fname
	
	String path = "entry:control:detector_counts"	
	return(getRealValueFromHDF5(fname,path))
end


Function getDetector_preset(fname)
	String fname
	
	String path = "entry:control:detector_preset"	
	return(getRealValueFromHDF5(fname,path))
end

// this is efficiency of what?? monitor or detector?
Function getEfficiency(fname)
	String fname
	
	String path = "entry:control:efficiency"	
	return(getRealValueFromHDF5(fname,path))
end


// control mode for data acquisition, "timer"
//  - what are the enumerated types for this?
Function/S getControlMode(fname)
	String fname
	
	String path = "entry:control:mode"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//monitor count
// TODO - verify that this is the correct monitor
Function getControlMonitorCount(fname)
	String fname
	
	String path = "entry:control:monitor_counts"	
	return(getRealValueFromHDF5(fname,path))
end

Function getControlMonitor_preset(fname)
	String fname
	
	String path = "entry:control:monitor_preset"	
	return(getRealValueFromHDF5(fname,path))
end

Function getControlMonitor_sampled_fraction(fname)
	String fname
	
	String path = "entry:control:sampled_fraction"	
	return(getRealValueFromHDF5(fname,path))
end


//
// this is not a block that I added, and I will not 
// call from this block. These values are elsewhere in the Nexus
// file. This data block is for Nexus compliance and here presumably so that
// other programs that read this file have easy access to plotting the data
//
// I added calls simply for completeness
//
//////// DATA
//////// DATA
//////// DATA


Function/WAVE getData_areaDetector(fname)
	String fname
	
	String path = "entry:data:areaDetector"
	WAVE w = getRealWaveFromHDF5(fname,path)
	
	return w
end

Function/S getData_configuration(fname)
	String fname
	
	String path = "entry:data:configuration"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End			

Function/S getData_sample_description(fname)
	String fname
	
	String path = "entry:data:sample_description"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getData_Sample_thickness(fname)
	String fname
	
	String path = "entry:data:sample_thickness"	
	return(getRealValueFromHDF5(fname,path))
end			

Function/S getData_slotIndex(fname)
	String fname
	
	String path = "entry:data:slotIndex"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getData_X0(fname)
	String fname
	
	String path = "entry:data:x0"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/WAVE getData_y0(fname)
	String fname
	
	String path = "entry:data:y0"
	WAVE w = getRealWaveFromHDF5(fname,path)
	
	return w
end

//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

// x- this does not appear to be written out
Function/S getLocalContact(fname)
	String fname

	String path = "entry:instrument:local_contact"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getInstrumentName(fname)
	String fname

	String path = "entry:instrument:name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getInstrumentType(fname)
	String fname

	String path = "entry:instrument:type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

////// INSTRUMENT/ATTENUATOR
//  - be sure of the definition of these terms
//

// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
// (and something is wrong -- NICE always writes out "1" for the atten factor (and error)
//-- so I am forced to use the tables every time
//
Function getAttenuator_transmission(fname)
	String fname
	
	Print "Atten read - diverted to calculation"

//	return(1)
	return(N_CalculateAttenuationFactor(fname))
	
//	String path = "entry:instrument:attenuator:attenuator_transmission"	
//	return(getRealValueFromHDF5(fname,path))

end

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
//
//
// for the SANS instruments, the error table is presented in % ERROR
// -- this correction is accounted for here in N_CalculateAttenuationError()
//
Function getAttenuator_trans_err(fname)
	String fname
	
	Print "Atten_err read - diverted to calculation"

//	return(0)
	return(N_CalculateAttenuationError(fname))
	
//	String path = "entry:instrument:attenuator:attenuator_transmission_error"	
//	return(getRealValueFromHDF5(fname,path))
	
end

// desired number of attenuators
Function getAtten_desired_num_atten_dropped(fname)
	String fname
	
	String path = "entry:instrument:attenuator:desired_num_atten_dropped"	
	return(getRealValueFromHDF5(fname,path))
end


// distance from the attenuator to the sample (units??)
Function getAttenDistance(fname)
	String fname
	
	String path = "entry:instrument:attenuator:distance"	
	return(getRealValueFromHDF5(fname,path))
end



// table of the attenuation factor error
Function/WAVE getAttenIndex_error_table(fname)
	String fname
	
	String path = "entry:instrument:attenuator:index_error_table"
	WAVE w = getRealWaveFromHDF5(fname,path)
	
	return w
end

// table of the attenuation factor
Function/WAVE getAttenIndex_table(fname)
	String fname
	
	String path = "entry:instrument:attenuator:index_table"
	WAVE w = getRealWaveFromHDF5(fname,path)

	return w
end



//// this is the actual "number" of attenuators dropped in the beam - and should be 
// what I can use to lookup the actual attenuator transmission
Function getAtten_number(fname)
	String fname
	
	String path = "entry:instrument:attenuator:num_atten_dropped"	
	return(getRealValueFromHDF5(fname,path))
end

// thickness of the attenuator (PMMA) - units??
Function getAttenThickness(fname)
	String fname
	
	String path = "entry:instrument:attenuator:thickness"	
	return(getRealValueFromHDF5(fname,path))
end


// type of material for the atteunator
Function/S getAttenType(fname)
	String fname

	String path = "entry:instrument:attenuator:type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End



					
/////// INSTRUMENT/BEAM MONITORS



//beam_monitor_norm (data folder)
Function getBeamMonNormData(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:data"
	return(getRealValueFromHDF5(fname,path))
End

Function getBeamMonNormDistance(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:distance"
	return(getRealValueFromHDF5(fname,path))
End

Function getBeamMonNormEfficiency(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:efficiency"
	return(getRealValueFromHDF5(fname,path))
End

Function getBeamMonNormSaved_count(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:saved_count"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getBeamMonNormType(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End



//beam_stop (data folder)
Function/S getBeamStopDescription(fname)
	String fname

	String path = "entry:instrument:beam_stop:description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getBeamStopDist_to_det(fname)
	String fname

	String path = "entry:instrument:beam_stop:distance_to_detector"
	return(getRealValueFromHDF5(fname,path))
End



Function getBeamStop_x_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop:x_pos"
	return(getRealValueFromHDF5(fname,path))
End

Function getBeamStop_y_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop:y_pos"
	return(getRealValueFromHDF5(fname,path))
End


////TODO -- not sure what this really means
//Function getBeamStopNum_beamstops(fname)
//	String fname
//
//	String path = "entry:instrument:beam_stop:num_beamstops"
//	return(getRealValueFromHDF5(fname,path))
//End

// beam stop shape parameters
Function getBeamStop_height(fname)
	String fname

	String path = "entry:instrument:beam_stop:shape:height"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getBeamStop_shape(fname)
	String fname

	Variable num=60
	String path = "entry:instrument:beam_stop:shape:shape"
	return(getStringFromHDF5(fname,path,num))
End

// == diameter if shape = CIRCLE
// value is stored in [cm] diameter in Nexus
// (was stored on VAX as [mm] - be careful)
//
//  as of 3/2023, size is not stored for 30m instruments
// but is stored in: root:sans118676:entry:DAS_logs:beamStop:size
//
// so if -999999 is returned, look in the second place...
//
//
//
Function getBeamStop_size(fname)
	String fname

	variable val
	String path = "entry:instrument:beam_stop:shape:size"
	
	val = getRealValueFromHDF5(fname,path)
	
	if(val < -999)
		path = "entry:DAS_logs:beamStop:size"
		val = getRealValueFromHDF5(fname,path)
	endif
	
	return(val)
End

Function getBeamStop_width(fname)
	String fname

	String path = "entry:instrument:beam_stop:shape:width"
	return(getRealValueFromHDF5(fname,path))
End



//// INSTRUMENT/COLLIMATOR
//collimator (data folder)

// this is now defined as text, due to selections from GUI
Function/S getNumberOfGuides(fname)
	String fname

	Variable num=60
	String path = "entry:instrument:collimator:number_guides"
	return(getStringFromHDF5(fname,path,num))
End

//				geometry (data folder)
//					shape (data folder)
Function/S getGuideShape(fname)
	String fname

	String path = "entry:instrument:collimator:geometry:shape:shape"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getGuideSize(fname)
	String fname

	String path = "entry:instrument:collimator:geometry:shape:size"
	return(getRealValueFromHDF5(fname,path))
End


////// INSTRUMENT/DETECTOR

//
// CAL_X and CAL_Y are dummy values that are used to "inactivate" the 
// non-linear corrections for the Ordela detectors. These coefficients were used for
// much older-style Ordela detectors, aren't used for the current ones, and
// won't be used for the tube detctors...

//// DONE -- write to return an ARRAY
//Function/WAVE getDet_cal_x(fname)
//	String fname
//
////	String path = "entry:instrument:detector:cal_x"
////	WAVE w = getRealWaveFromHDF5(fname,path)
////	return w
//	
//	Make/O/D/N=3 tmp
//	tmp[0] = getDet_x_pixel_size(fname)
//	tmp[1] = 10000
//	tmp[2] = 0
//	return tmp
//
//End

//// only defined for the "B" detector, and may not be necessary?
//// (DONE) -- write to return an ARRAY
//Function/WAVE getDet_cal_y(fname)
//	String fname
//
////	String path = "entry:instrument:detector:cal_y"
////	WAVE w = getRealWaveFromHDF5(fname,path)
////	return w
//
//	Make/O/D/N=3 tmp
//	tmp[0] = getDet_y_pixel_size(fname)
//	tmp[1] = 10000
//	tmp[2] = 0
//	return tmp
//End

//// returns a hard-wired value for all Ordela detectors
////
//Function getDet_OrdelaNonLinCoef(fname)
//	String fname
//	
//	return(10000)
//end




Function getDet_azimuthal_angle(fname)
	String fname

	String path = "entry:instrument:detector:azimuthal_angle"
	return(getRealValueFromHDF5(fname,path))
End

// for the 10m SANS, this will be in PIXELS
Function getDet_beam_center_x(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_x"
	return(getRealValueFromHDF5(fname,path))
End

// for the 10m SANS, this will be in PIXELS
Function getDet_beam_center_y(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_y"
	return(getRealValueFromHDF5(fname,path))
End

//
Function/WAVE getDetectorDataW(fname)
	String fname

	String path = "entry:instrument:detector:data"
	WAVE/Z w = getRealWaveFromHDF5(fname,path)

	return w
End

//
// (DONE) -- this does not exist in the raw data, but does in the processed data
// !!! how to handle this?? Binning routines need the error wave
// -- be sure that I generate a local copy of this wave at load time
//

Function/WAVE getDetectorDataErrW(fname)
	String fname

	String path = "entry:instrument:detector:data_error"
	WAVE w = getRealWaveFromHDF5(fname,path)

	return w
End

//// NOTE - this is not part of the file as written
//// it is generated when the RAW data is loaded (when the error wave is generated)
//Function/WAVE getDetectorLinearDataW(fname)
//	String fname
//
//	String path = "entry:instrument:detector:linear_data"
//	WAVE w = getRealWaveFromHDF5(fname,path)
//
//	return w
//End

////
//// (DONE) -- this does not exist in the raw data, but does in the processed data
//// !!! how to handle this?? Binning routines need the error wave
//// -- be sure that I generate a local copy of this wave at load time
////
//Function/WAVE getDetectorLinearDataErrW(fname)
//	String fname
//
//	String path = "entry:instrument:detector:linear_data_error"
//	WAVE w = getRealWaveFromHDF5(fname,path)
//
//	return w
//End




// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function/WAVE getDetector_deadtime(fname)
	String fname

	String path = "entry:instrument:detector:dead_time"

	WAVE w = getRealWaveFromHDF5(fname,path)
	return w
	
End


// TODO -- REMOVE calls to this function - only good for Ordela
// returns fake dead time [s]
Function getDetectorDeadtime_Value(fname)
	String fname
	
	return(1e-6)
End

Function/S getDetDescription(fname)
	String fname

	String path = "entry:instrument:detector:description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// header reports value in [cm], so [cm] is returned here
// IF reduction is expecting distance in [m] it is up to calling function to convert
Function getDet_Distance(fname)
	String fname

	String path = "entry:instrument:detector:distance"
	
	Variable sdd = getRealValueFromHDF5(fname,path)
	return(sdd)
End


Function getDet_IntegratedCount(fname)
	String fname

	String path = "entry:instrument:detector:integrated_count"
	return(getRealValueFromHDF5(fname,path))
End

// not currently defined in the SANS file
Function getDet_LateralOffset(fname)
	String fname

	String path = "entry:instrument:detector:lateral_offset"
	return(getRealValueFromHDF5(fname,path))
End


Function getDet_numberOfTubes(fname)
	String fname

	String path = "entry:instrument:detector:number_of_tubes"
	return(getRealValueFromHDF5(fname,path))
End


//  Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function getDet_pixel_fwhm_x(fname)
	String fname

	String path = "entry:instrument:detector:pixel_fwhm_x"

	return(getRealValueFromHDF5(fname,path))
End

// Pixels are not square
// so the FHWM will be different in each direction
Function getDet_pixel_fwhm_y(fname)
	String fname

	String path = "entry:instrument:detector:pixel_fwhm_y"

	return(getRealValueFromHDF5(fname,path))
End

Function getDet_pixel_num_x(fname)
	String fname

	String path = "entry:instrument:detector:pixel_num_x"
	return(getRealValueFromHDF5(fname,path))
End

Function getDet_pixel_num_y(fname)
	String fname

	String path = "entry:instrument:detector:pixel_num_y"
	return(getRealValueFromHDF5(fname,path))
End


Function getDet_polar_angle(fname)
	String fname

	String path = "entry:instrument:detector:polar_angle"
	return(getRealValueFromHDF5(fname,path))
End


Function getDet_rotation_angle(fname)
	String fname

	String path = "entry:instrument:detector:rotation_angle"
	return(getRealValueFromHDF5(fname,path))
End


Function/S getDetSettings(fname)
	String fname

	String path = "entry:instrument:detector:settings"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// DONE -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function/WAVE getDetTube_spatialCalib(fname)
	String fname

	String path = "entry:instrument:detector:spatial_calibration"

	WAVE w = getRealWaveFromHDF5(fname,path)
	return w
End


// (DONE) -- be clear on how this is defined. Units are in [mm]
Function getDet_tubeWidth(fname)
	String fname

	String path = "entry:instrument:detector:tube_width"

	return(getRealValueFromHDF5(fname,path))
End

// not used - I calculate the cprrect values from the nonlinear corretions
Function/WAVE getDet_x_offset(fname)
	String fname

	String path = "entry:instrument:detector:x_offset"

	WAVE w = getRealWaveFromHDF5(fname,path)
	return w
End

// header lists size in [mm]
Function getDet_x_pixel_size(fname)
	String fname

	String path = "entry:instrument:detector:x_pixel_size"
	return(getRealValueFromHDF5(fname,path))
End


// not used - I calculate the cprrect values from the nonlinear corretions
Function/WAVE getDet_y_offset(fname)
	String fname

	String path = "entry:instrument:detector:y_offset"

	WAVE w = getRealWaveFromHDF5(fname,path)
	return w
End


// header lists size in [mm]
Function getDet_y_pixel_size(fname)
	String fname

	String path = "entry:instrument:detector:y_pixel_size"
	return(getRealValueFromHDF5(fname,path))
End



// following subset of functions is for detector, but non-standard
// values, some not initially stored in file

//
//  root:Packages:NIST:RAW:entry:instrument:event_file_name
//
Function/S getDetEventFileName(fname)
	String fname

	String path = "entry:instrument:event_file_name"
	Variable num=60

	return(getStringFromHDF5(fname,path,num))
End


//(DONE)
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function getDet_beam_center_x_mm(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_x_mm"
	return(getRealValueFromHDF5(fname,path))
End

//(DONE)
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function getDet_beam_center_y_mm(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_y_mm"
	return(getRealValueFromHDF5(fname,path))
End

//(DONE)
//
// x and y center in pix is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function getDet_beam_center_x_pix(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_x_pix"
	return(getRealValueFromHDF5(fname,path))
End

//(DONE)
//
// x and y center in pix is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function getDet_beam_center_y_pix(fname)
	String fname

	String path = "entry:instrument:detector:beam_center_y_pix"
	return(getRealValueFromHDF5(fname,path))
End




//////////////////////

// INSTRUMENT/LENSES 
//  lenses (data folder)

Function getLensCurvature(fname)
	String fname

	String path = "entry:instrument:lenses:curvature"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getLensesFocusType(fname)
	String fname

	String path = "entry:instrument:lenses:focus_type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getLensDistance(fname)
	String fname

	String path = "entry:instrument:lenses:lens_distance"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getLensGeometry(fname)
	String fname

	String path = "entry:instrument:lenses:lens_geometry"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getLensMaterial(fname)
	String fname

	String path = "entry:instrument:lenses:lens_material"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getNumber_of_Lenses(fname)
	String fname

	String path = "entry:instrument:lenses:number_of_lenses"
	return(getRealValueFromHDF5(fname,path))
End

Function getNumber_of_prisms(fname)
	String fname

	String path = "entry:instrument:lenses:number_of_prisms"
	return(getRealValueFromHDF5(fname,path))
End

Function getPrism_distance(fname)
	String fname

	String path = "entry:instrument:lenses:prism_distance"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getPrismMaterial(fname)
	String fname

	String path = "entry:instrument:lenses:prism_material"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//
// status of lens/prism = lens | prism | both | out
Function/S getLensPrismStatus(fname)
	String fname

	String path = "entry:instrument:lenses:status"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// not a header value - derived from header value
//
// returns the "truth" if the lenses are IN
// fails otherwise
//
Function getAreLensesIn(fname)
	String fname
	
	if(cmpstr("lens",getLensPrismStatus(fname)) == 0)
		return(1)
	else
		return(0)
	endif
end


///////////MONOCHROMATOR

// instrument/beam/monochromator (data folder)
Function/S getMonochromatorType(fname)
	String fname

	String path = "entry:instrument:monochromator:type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// entry:instrument:monochromator:wavelength
Function getWavelength(fname)
	String fname
	
	String path = "entry:instrument:monochromator:wavelength"	
	return(getRealValueFromHDF5(fname,path))
end

Function getWavelength_spread(fname)
	String fname
	
	String path = "entry:instrument:monochromator:wavelength_error"	
	return(getRealValueFromHDF5(fname,path))
end

Function getVelocitySel_distance(fname)
	String fname
	
	String path = "entry:instrument:monochromator:velocity_selector:distance"	
	return(getRealValueFromHDF5(fname,path))
end

Function getVelocitySel_rotation_speed(fname)
	String fname
	
	String path = "entry:instrument:monochromator:velocity_selector:rotation_speed"	
	return(getRealValueFromHDF5(fname,path))
end

// not sure what this is
Function getVelocitySel_table(fname)
	String fname
	
	String path = "entry:instrument:monochromator:velocity_selector:table"	
	return(getRealValueFromHDF5(fname,path))
end








///////  sample_aperture (1) (data folder)
// this is the INTERNAL sample aperture
//
Function/S getSampleAp_Description(fname)
	String fname

	String path = "entry:instrument:sample_aperture:description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


//expecting units of [cm]
Function getSampleAp_distance(fname)
	String fname

	String path = "entry:instrument:sample_aperture:distance"
	return(getRealValueFromHDF5(fname,path))
End

//	shape (data folder)
Function getSampleAp_height(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:height"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getSampleAp_shape(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:shape"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// as of 6/2022 - the first files tested with the bucket
// and the new tube detectors -- this field is a real value, not text
// 
// units are [mm]
//
Function getSampleAp_size(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:size"
	return(getRealValueFromHDF5(fname,path))
End


//// this returns REAL - but input is TEXT, due to GUI input, == to diameter if CIRCLE
////
//// TODO -- what are the units?? [mm] or [cm]
////
//Function getSampleAp_size(fname)
//	String fname
//
//	String path = "entry:instrument:sample_aperture:shape:size"
//	Variable num=60
//	variable val
//	String str2=""
//	String str = getStringFromHDF5(fname,path,num)
//	sscanf str, "%g %s\r", val,str2
//	return(val)
//End


Function getSampleAp_width(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:width"
	return(getRealValueFromHDF5(fname,path))
End





	
//////  sample_table (data folder)
// location  = "CHAMBER" or HUBER
Function/S getSampleTableLocation(fname)
	String fname

	String path = "entry:instrument:sample_table:location"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function getSampleTableOffset(fname)
	String fname

	String path = "entry:instrument:sample_table:offset_distance"
	return(getRealValueFromHDF5(fname,path))
End	


	
//  source (data folder)
//name "NCNR"
Function/S getSourceName(fname)
	String fname

	String path = "entry:instrument:source:name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//	power -- nominal only, not connected to any real number
Function getReactorPower(fname)
	String fname

	String path = "entry:instrument:source:power"
	return(getRealValueFromHDF5(fname,path))
End	

//probe (wave) "neutron"
Function/S getSourceProbe(fname)
	String fname

	String path = "entry:instrument:source:probe"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//type (wave) "Reactor Neutron Source"
Function/S getSourceType(fname)
	String fname

	String path = "entry:instrument:source:type"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

	
///////  source_aperture (data folder)

Function/S getSourceAp_Description(fname)
	String fname

	String path = "entry:instrument:source_aperture:description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//
// this value is stored in [cm], so [cm] is returned
//
//
Function getSourceAp_distance(fname)
	String fname

	String path = "entry:instrument:source_aperture:distance"
	return(getRealValueFromHDF5(fname,path))
End

//	shape (data folder)
Function getSourceAp_height(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:height"
	return(getRealValueFromHDF5(fname,path))
End

Function/S getSourceAp_shape(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:shape"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// this returns REAL, but comes from TEXT, due to GUI input, == to diameter if CIRCLE
Function getSourceAp_size(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:size"
	
	Variable num=60
	variable val
	String str2=""
	String str = getStringFromHDF5(fname,path,num)
	sscanf str, "%g %s\r", val,str2
	return(val)
End

Function getSourceAp_width(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:width"
	return(getRealValueFromHDF5(fname,path))
End









//
// TODO -- this is all a big mess with the changes in the data file structure
//  in JUNE 2017, which completely wrecks what was decided in 2016.
// Now, I'm not sure at all what I'll get...or what the field will be called... or what they mean...
//
//
//// SAMPLE / DATA LOGS
// write this generic , call with the name of the environment log desired
//
//
// shear_field
// pressure
// magnetic_field
// electric_field
//
//////// (for example) electric_field (data folder)

Function/S getLog_attachedTo(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":attached_to"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


Function/S getLog_measurement(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":measurement"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


Function/S getLog_Name(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End



// for temperature only, logStr = "temperature_env"
Function/S getTemp_ControlSensor(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":control_sensor"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// for temperature only, logStr = "temperature_env"
Function/S getTemp_MonitorSensor(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":monitor_sensor"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

	

//// TODO -- this may not exist if it is not a "controlling" sensor, but there still may be logged data present
//// TODO -- it may also have different names for each sensor (setpoint_1, setpoint_2, etc. which will be a big hassle)
//Function getLog_setPoint(fname,logStr)
//	String fname,logStr
//	
//	String path = "entry:sample:"+logstr+":setpoint_1"
//	return(getRealValueFromHDF5(fname,path))
//end
//
//Function/S getLog_startTime(fname,logStr)
//	String fname,logStr
//
//	String path = "entry:sample:"+logstr+":start"
//	Variable num=60
//	return(getStringFromHDF5(fname,path,num))
//End
//
//
//// TODO -- this may only exist for electric field and magnetic field...
//// or may be eliminated altogether
//Function getLog_nomValue(fname,logStr)
//	String fname,logStr
//	
//	String path = "entry:sample:"+logstr+":value"
//	return(getRealValueFromHDF5(fname,path))
//end



///////////
// for temperature, the "attached_to", "measurement", and "name" fields
// are one level down farther than before, and down deeper than for other sensors
//
//
// read the value of getTemp_MonitorSensor/ControlSensor to get the name of the sensor level .
//

Function/S getTempLog_attachedTo(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":attached_to"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getTempLog_highTrip(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":high_trip_value"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_holdTime(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":hold_time"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_lowTrip(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":low_trip_value"
	return(getRealValueFromHDF5(fname,path))
end

Function/S getTempLog_measurement(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":measurement"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


Function/S getTempLog_Model(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":model"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getTempLog_Name(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getTempLog_runControl(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":run_control"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_Setpoint(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":setpoint"
	return(getRealValueFromHDF5(fname,path))
end

Function/S getTempLog_ShortName(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":short_name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function getTempLog_Timeout(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":timeout"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_Tolerance(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":tolerance"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_ToleranceBand(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":tolerance_band_time"
	return(getRealValueFromHDF5(fname,path))
end

Function getTempLog_Value(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":value"
	return(getRealValueFromHDF5(fname,path))
end






//
// temperature_env:temp_Internal_1:value_log
//
////		value_log (data folder)
//
// TODO:
// -- be sure that the calling function properly calls for temperture
// logs which are down an extra layer:
//  	for example, logStr = "temperature_env:temp_Internal_1"
//
// read the value of getTemp_MonitorSensor to get the name of the sensor the next level down.
//
Function getLog_avgValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:average_value"
	return(getRealValueFromHDF5(fname,path))
end

Function getLog_avgValue_err(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:average_value_error"
	return(getRealValueFromHDF5(fname,path))
end

Function getLog_maximumValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:maximum_value"
	return(getRealValueFromHDF5(fname,path))
end

Function getLog_medianValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:median_value"
	return(getRealValueFromHDF5(fname,path))
end

Function getLog_minimumValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:minimum_value"
	return(getRealValueFromHDF5(fname,path))
end

// DONE -- this needs to be a WAVE reference
// DONE -- verify that the field is really read in as "time0"
Function getLog_timeWave(fname,logStr,outW)
	String fname,logStr
	Wave outW
	
	String path = "entry:sample:"+logstr+":value_log:time0"
	WAVE w = getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

// DONE -- this needs to be a WAVE reference
Function getLog_ValueWave(fname,logStr,outW)
	String fname,logStr
	Wave outW
	
	String path = "entry:sample:"+logstr+":value_log:value"
	WAVE w = getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end


///////// REDUCTION
///////// REDUCTION
///////// REDUCTION


Function/WAVE getAbsolute_Scaling(fname)
	String fname
	
	String path = "entry:reduction:absolute_scaling"	
	WAVE w = getRealWaveFromHDF5(fname,path)
	
	return w
end

Function/S getBackgroundFileName(fname)
	String fname

	String path = "entry:reduction:background_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End



Function/WAVE getBoxCoordinates(fname)
	String fname
	
	String path = "entry:reduction:box_coordinates"	
	WAVE w = getRealWaveFromHDF5(fname,path)

	return w
end

//box counts
Function getBoxCounts(fname)
	String fname
	
	String path = "entry:reduction:box_count"	
	return(getRealValueFromHDF5(fname,path))
end

//box counts error
Function getBoxCountsError(fname)
	String fname
	
	String path = "entry:reduction:box_count_error"	
	return(getRealValueFromHDF5(fname,path))
end

Function/S getReductionComments(fname)
	String fname

	String path = "entry:reduction:comments"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


Function/S getEmptyBeamFileName(fname)
	String fname

	String path = "entry:reduction:empty_beam_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getEmptyFileName(fname)
	String fname

	String path = "entry:reduction:empty_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End



//
//INTENT:
//
//1. “Transmission”
//2. “Scattering”
//3. “He3”
//
//PURPOSE:
//a. “Sample” (Default value for new rows)
//b. “Empty Cell”
//c. “Blocked Beam”
//d. “Open Beam”
//e. “Standard”
//


// this is purpose is used for all files, and has different meaning
// if polarization is used. need the "intent" also to be able to fully decipher what a file
//  is really being used for. GUI controls this, not me.
Function/S getReduction_purpose(fname)
	String fname

	String path = "entry:reduction:file_purpose"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


Function/S getReduction_intent(fname)
	String fname

	String path = "entry:reduction:intent"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

////group ID
//// DONE
//// x- is this duplicated?
//// x- yes, this is a duplicated field in the /entry/sample block (and is probably more appropriate there)
//// x- so pick a single location, rather than needing to duplicate.
//// x- REPLACE with a single function getSample_GroupID()
////
//Function getSample_group_ID(fname)
//	String fname
//
//// do not use the entry/reduction location
////	String path = "entry:reduction:group_id" 
//	String path = "entry:sample:group_id"	
//
//	return(getRealValueFromHDF5(fname,path))
//end


Function/S getMaskFileName(fname)
	String fname

	String path = "entry:reduction:mask_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getLogFileName(fname)
	String fname

	String path = "entry:reduction:sans_log_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getSensitivityFileName(fname)
	String fname

	String path = "entry:reduction:sensitivity_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

Function/S getTransmissionFileName(fname)
	String fname

	String path = "entry:reduction:transmission_file_name"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//whole detector trasmission
Function getSampleTransWholeDetector(fname)
	String fname
	
	String path = "entry:reduction:whole_trans"	
	return(getRealValueFromHDF5(fname,path))
end

//whole detector trasmission error
Function getSampleTransWholeDetErr(fname)
	String fname
	
	String path = "entry:reduction:whole_trans_error"	
	return(getRealValueFromHDF5(fname,path))
end

// this is a NON NICE entered field
// so I need to catch the error if it's not there
Function/WAVE getReductionProtocolWave(fname)
	String fname
	
	String path = "entry:reduction:protocol"	
	WAVE/T/Z tw = getTextWaveFromHDF5(fname,path)
	
	if(waveExists(tw))
		return tw
	else
		Make/O/T/N=0 nullTextWave
		return nullTextWave
	endif
	
end


//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//no meaning to this...
Function getSample_equatorial_ang(fname)
	String fname
	
	String path = "entry:sample:aequatorial_angle"	
	return(getRealValueFromHDF5(fname,path))
end

// this is huber/chamber?? or description of sample block
//
Function/S getSampleChanger(fname)
	String fname

	String path = "entry:sample:changer"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//Sample position in changer (returned as TEXT)f
Function/S getSamplePosition(fname)
	String fname
	
	String path = "entry:sample:changer_position"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
end

// sample label 
Function/S getSampleDescription(fname)
	String fname

	String path = "entry:sample:description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// for a z-stage??
Function getSampleElevation(fname)
	String fname
	
	String path = "entry:sample:elevation"	
	return(getRealValueFromHDF5(fname,path))
end


// group ID !!! very important for matching up files
Function getSample_GroupID(fname)
	String fname
	
	String path = "entry:sample:group_id"	
	return(getRealValueFromHDF5(fname,path))
end


// sample mass
Function getSample_mass(fname)
	String fname
	
	String path = "entry:sample:mass"	
	return(getRealValueFromHDF5(fname,path))
end

// sample name
Function/S getSample_Name(fname)
	String fname

	String path = "entry:sample:name"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


//Sample Rotation Angle
Function getSampleRotationAngle(fname)
	String fname
	
	String path = "entry:sample:rotation_angle"	
	return(getRealValueFromHDF5(fname,path))
end

//?? this is huber/chamber??
// TODO -- then where is the description of 10CB, etc...
Function/S getSampleHolderDescription(fname)
	String fname

	String path = "entry:sample:sample_holder_description"
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//// this field is apparently the "average" temperature reading 
//// and can be adversely affected by random faulty readings from the sensor
//// to give an average that is far from the expected value
//
//
// -- TODO - these are not currently in the Nexus file. Not sure where the
// temperature ends up!?
// 
Function getSampleTemperature(fname)
	String fname
	
	String path = "entry:sample:temperature"	
	return(getRealValueFromHDF5(fname,path))
end

Function getSampleTempSetPoint(fname)
	String fname
	
	String path = "entry:sample:temperature_setpoint"	
	return(getRealValueFromHDF5(fname,path))
end


//Sample Thickness
// (DONE) -- somehow, this is not set correctly in the acquisition, so NaN results
// -- this has been corrected in NICE (when??)
Function getSampleThickness(fname)
	String fname
	
	String path = "entry:sample:thickness"	
	return(getRealValueFromHDF5(fname,path))
end

Function getSampleTranslation(fname)
	String fname
	
	String path = "entry:sample:translation"	
	return(getRealValueFromHDF5(fname,path))
end

// sample transmission
Function getSampleTransmission(fname)
	String fname
	
//	Print "FAKE TRANSMISSION OF 0.8 USED"
//	
//	return(0.8)
	
	String path = "entry:sample:transmission"	
	return(getRealValueFromHDF5(fname,path))
end

//transmission error (one sigma)
Function getSampleTransError(fname)
	String fname

//	Print "FAKE TRANSMISSION ERROR OF 0.1 USED"
//	
//	return(0.1)
		
	String path = "entry:sample:transmission_error"	
	return(getRealValueFromHDF5(fname,path))
end



				

///////////////////////////////////////////////////////////////
//
//
// UTILITY READERS, AS YET UNDEFINED VALUES AND FIELDS


// acct name is "[NGxSANSxx]" -- [1,3] is the instrument "name" "NGx"
//so that Ng can be correctly calculated
//
// now with the nexus files, return the final suffix of the file name to identify the instrument
// = ngv, ngb, ngb30,ng7
//
// this returns tha last three characters from the file name to be able to idnetify the instrument
// as was done with the VAX account
//
Function/S getInstrName(fname)
	String fname
	
	String str = StringFromList(2,fname,".")
	return(str)
End

// now with the nexus files, return the final suffix of the file name to identify the instrument
// = ngv, ngb, ngb30,ng7
//
// if the full path is passed, not a problem since it's delimited with colons, and this is
// keying on the "."s in the name
//
Function/S getInstrumentNameFromFile(fname)
	String fname
	
	String str = StringFromList(2,fname,".")
	return(str)
End


// not in the SANS definition
//
// get the loaded file name from the specified work folder
// will return null string if there is no folder by that name
Function/S getFileNameFromFolder(folder)
	String folder
	
	SVAR fname=$("root:Packages:NIST:"+folder+":fileList")
	
	
	return(fname)	
End

// not in the SANS definition
Function/S getFileName(fullPath)
	String fullPath
	
	String fname = N_GetFileNameFromPathNoSemi(fullPath)
	return(fname)	
End



// file suffix
// this is not part of the Nexus definition, but have this return the file name instead
//
Function/S getSuffix(fname)
	String fname
	
	String str=getFileName(fname)
	Return(str) 
End

// associated file suffix (for transmission)
Function/S getAssociatedFileSuffix(fname)
	String fname

	String path = "entry:reduction:assoc_file_suffix"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


// TODO - field strength not defined
//
Function getFieldStrength(fname)
	String fname
	
//	return(getRealValueFromHeader(fname,190))
//	return(getRealValueFromHeader(fname,348))

//	Print "field strength not defined"
	return(0)
end


/////   TRANSMISSION RELATED FUNCTIONS    ////////
//box coordinate are returned by reference
// filename is the full path:name 
Function getXYBoxFromFile(fname,x1,x2,y1,y2)
	String fname
	Variable &x1,&x2,&y1,&y2


	WAVE cw=getBoxCoordinates(fname)
	

	x1 = cw[0]
	x2 = cw[1]
	y1 = cw[2]
	y2 = cw[3]
	

	return(0)
End


//
// polarized beam functions added for NG7 SANS
// (write functions also added)
//
// -- as of 3/2023
// (locations may change in the future...)
//
// ** NOTE: more is needed to include the cell information for the back polarizer (analyzer)
// -- see VSANS cor how this is handled...
//
//
// root:Packages:NIST:RawSANS:sans118664:entry:instrument:He3BackPolarizer:type (var)
//
Function get_He3BackPolarizer_type(fname)
	String fname
	
	String path = "entry:instrument:He3BackPolarizer:type"	
	return(getRealValueFromHDF5(fname,path))
end

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:He3FrontPolarizer:type (var)
//
Function get_He3FrontPolarizer_type(fname)
	String fname
	
	String path = "entry:instrument:He3FrontPolarizer:type"	
	return(getRealValueFromHDF5(fname,path))
end

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:direction (text)
//
Function/S get_rfFrontFlipper_direction(fname)
	String fname

	String path = "entry:instrument:rfFrontFlipper:direction"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:flip (text)
//
Function/S get_rfFrontFlipper_flip(fname)
	String fname

	String path = "entry:instrument:rfFrontFlipper:flip"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:transmitted_power (var)
//
Function get_rfFrontFlipper_transmitted_power(fname)
	String fname
	
	String path = "entry:instrument:rfFrontFlipper:transmitted_power"	
	return(getRealValueFromHDF5(fname,path))
end

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:type (text)
//
Function/S get_rfFrontFlipper_type(fname)
	String fname

	String path = "entry:instrument:rfFrontFlipper:type"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

//
// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:composition (text)
Function/S get_superMirror_composition(fname)
	String fname

	String path = "entry:instrument:superMirror:composition"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:efficiency (var)
//
Function get_superMirror_efficiency(fname)
	String fname
	
	String path = "entry:instrument:superMirror:efficiency"	
	return(getRealValueFromHDF5(fname,path))
end

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:type (text)
//
Function/S get_superMirror_type(fname)
	String fname

	String path = "entry:instrument:superMirror:type"	
	Variable num=60
	return(getStringFromHDF5(fname,path,num))
End


//////////////////////////////



