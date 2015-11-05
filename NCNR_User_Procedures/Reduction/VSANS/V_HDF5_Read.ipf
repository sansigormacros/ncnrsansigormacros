#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//////////// READ (GET) FUNCTIONS ////////////////////


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
Function proto_V_get_FP(str)
	String str
	return(0)
end
Function proto_V_get_FP2(str,str2)
	String str,str2
	return(0)
end
//Function/S proto_V_get_STR(str)
//	String str
//	return("")
//end

Function Test_V_get_FP(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_V_get_FP f = $item
		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_V_get_FP2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_V_get_FP2 f = $item
		Print item ," = ", f(fname,detStr)
	endfor
	
	return(0)
end

Function Test_V_get_STR(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_V_get_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\")",item,fname
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_V_get_STR2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_V_get_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\",\"%s\")",item,fname,detStr
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end
///////////////////////////////////////


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
// TODO -- verify the paths, and add more as needed
// TODO -- for all of the String functions -- "num" does nothing right now - 
//         -- if it ever does, or needs to, a lot of locations will need to be corrected
//


//////// TOP LEVEL
//////// TOP LEVEL
//////// TOP LEVEL

// nexus version used for definitions
Function/S V_getNeXus_version(fname)
	String fname
	
	String path = "entry:NeXus_version"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function V_getCollectionTime(fname)
	String fname
	
	String path = "entry:collection_time"	
	return(V_getRealValueFromHDF5(fname,path))
End

// data directory where data files are stored (for user access, not archive)
Function/S V_getData_directory(fname)
	String fname
	
	String path = "entry:data_directory"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// Base class of Nexus definition (=NXsas)
Function/S V_getNexusDefinition(fname)
	String fname
	
	String path = "entry:definition"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function V_getDataDuration(fname)
	String fname
	
	String path = "entry:duration"	
	return(V_getRealValueFromHDF5(fname,path))
End

// TODO -- not mine, added somewhere by Nexus writer?
// data collection end time
Function/S V_getDataEndTime(fname)
	String fname
	
	String path = "entry:end_time"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// experiment description
Function/S V_getExperiment_description(fname)
	String fname
	
	String path = "entry:experiment_description"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// experiment identifier? used only by NICE?
Function/S V_getExperiment_identifier(fname)
	String fname
	
	String path = "entry:experiment_identifier"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// name of facility = NCNR
Function/S V_getFacility(fname)
	String fname
	
	String path = "entry:facility"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End
		
// file write time (what is this??
// TODO - figure out if this is supposed to be an integer or text (ISO)
Function V_getFileWriteTime(fname)
	String fname
	
	String path = "entry:file_time"	
	return(V_getRealValueFromHDF5(fname,path))
End
		
//
Function/S V_getHDF_version(fname)
	String fname
	
	String path = "entry:hdf_version"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- not mine, added somewhere by Nexus writer?
Function/S V_getProgram_name(fname)
	String fname
	
	String path = "entry:program_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- not mine, added somewhere by Nexus writer?
// data collection start time
Function/S V_getDataStartTime(fname)
	String fname
	
	String path = "entry:start_time"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End
		
// title of experiment
Function/S V_getTitle(fname)
	String fname
	
	String path = "entry:title"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
end
	
	
		
////////// USER
////////// USER
////////// USER

// list of user names
// TODO -- currently not written out to data file??
Function/S V_getUserNames(fname)
	String fname
	
	String path = "entry:user:name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
end


//////// CONTROL
//////// CONTROL
//////// CONTROL

// TODO -- for the control section, document each of the fields

Function V_getCount_end(fname)
	String fname
	
	String path = "entry:control:count_end"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getCount_start(fname)
	String fname
	
	String path = "entry:control:count_start"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getCount_time(fname)
	String fname
	
	String path = "entry:control:count_time"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getCount_time_preset(fname)
	String fname
	
	String path = "entry:control:count_time_preset"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getDetector_counts(fname)
	String fname
	
	String path = "entry:control:detector_counts"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getDetector_preset(fname)
	String fname
	
	String path = "entry:control:detector_preset"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getIntegral(fname)
	String fname
	
	String path = "entry:control:integral"	
	return(V_getRealValueFromHDF5(fname,path))
end

// control mode for data acquisition, "timer"
Function/S V_getControlMode(fname)
	String fname
	
	String path = "entry:control:mode"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//monitor count
Function V_getMonitorCount(fname)
	String fname
	
	String path = "entry:control:monitor_counts"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getMonitor_preset(fname)
	String fname
	
	String path = "entry:control:monitor_preset"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getPreset(fname)
	String fname
	
	String path = "entry:control:preset"	
	return(V_getRealValueFromHDF5(fname,path))
end





//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

Function/S V_getLocalContact(fname)
	String fname

	String path = "entry:instrument:local_contact"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getInstrumentName(fname)
	String fname

	String path = "entry:instrument:name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getInstrumentType(fname)
	String fname

	String path = "entry:instrument:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

////// INSTRUMENT/ATTENUATOR
// TODO
// attenuator number -- for VSANS I think I want this to be some "binary" representation 
// of 4 plates in/out - so this may be an integer-> binary, or a text string (4 char)
Function V_getAtten_number(fname)
	String fname
	
	String path = "entry:instrument:attenuator:atten_number"	
	return(V_getRealValueFromHDF5(fname,path))
end


// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_getAttenuator_transmission(fname)
	String fname
	
	String path = "entry:instrument:attenuator:attenuator_transmission"	
	return(V_getRealValueFromHDF5(fname,path))
end


// distance from the attenuator to the sample (units??)
Function V_getAttenDistance(fname)
	String fname
	
	String path = "entry:instrument:attenuator:distance"	
	return(V_getRealValueFromHDF5(fname,path))
end


// attenuator index, to use in the lookup table of transmission values
Function V_getAttenIndex(fname)
	String fname
	
	String path = "entry:instrument:attenuator:index"	
	return(V_getRealValueFromHDF5(fname,path))
end


// table of the attenuation factor
Function V_getAttenIndex_table(fname,outW)
	String fname
	Wave outW
	
	String path = "entry:instrument:attenuator:index_table"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end


// status "in or out"
Function/S V_getAttenStatus(fname)
	String fname

	String path = "entry:instrument:attenuator:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// thickness of the attenuator (PMMA) - units??
Function V_getAttenThickness(fname)
	String fname
	
	String path = "entry:instrument:attenuator:thickness"	
	return(V_getRealValueFromHDF5(fname,path))
end


// type of material for the atteunator
Function/S V_getAttenType(fname)
	String fname

	String path = "entry:instrument:attenuator:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


////// INSTRUMENT/BEAM
// instrument/beam/chopper (data folder)
Function V_getChopperAngular_opening(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:angular_opening"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getChopDistance_from_sample(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:distance_from_sample"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getChopDistance_from_source(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:distance_from_source"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getChopperDuty_cycle(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:duty_cycle"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getChopperRotation_speed(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:rotation_speed"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getChopperSlits(fname)
	String fname
	
	String path = "entry:instrument:beam:chopper:slits"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getChopperstatus(fname)
	String fname

	String path = "entry:instrument:beam:chopper:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getChoppertype(fname)
	String fname

	String path = "entry:instrument:beam:chopper:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


// instrument/beam/flipper (data folder)
Function V_getFlipperDriving_current(fname)
	String fname
	
	String path = "entry:instrument:beam:flipper:driving_current"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getFlipperFrequency(fname)
	String fname
	
	String path = "entry:instrument:beam:flipper:frequency"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getFlipperstatus(fname)
	String fname

	String path = "entry:instrument:beam:flipper:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getFlipperTransmitted_power(fname)
	String fname
	
	String path = "entry:instrument:beam:flipper:transmitted_power"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getFlipperWaveform(fname)
	String fname

	String path = "entry:instrument:beam:flipper:waveform"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// instrument/beam/monochromator (data folder)
Function/S V_getMonochromatorType(fname)
	String fname

	String path = "entry:instrument:beam:monochromator:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getWavelength(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:wavelength"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getWavelength_spread(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:wavelength_spread"	
	return(V_getRealValueFromHDF5(fname,path))
end

// instrument/beam/monochromator/crystal (data folder)
Function V_getCrystalEnergy(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:energy"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalHorizontal_aperture(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:horizontal_aperture"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalHoriz_curvature(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:horizontal_curvature"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalLattice_parameter(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:lattice_parameter"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalnx_distance(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:nx_distance"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalReflection(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:reflection"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalRotation(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:rotation"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getCrystalStatus(fname)
	String fname

	String path = "entry:instrument:beam:monochromator:crystal:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getCrystalVertical_aperture(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:vertical_aperture"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalVertical_curvature(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:vertical_curvature"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalWavelength(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:wavelength"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalWavelength_spread(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:wavelength_spread"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getCrystalWavevector(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:wavevector"	
	return(V_getRealValueFromHDF5(fname,path))
end

// instrument/beam/monochromator/velocity_selector (data folder)
Function V_getVSnx_distance(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:nx_distance"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getVSRotation_speed(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:rotation_speed"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getVelSelStatus(fname)
	String fname

	String path = "entry:instrument:beam:monochromator:velocity_selector:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getVSTable(fname,outW)
	String fname
	Wave outW
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:table"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

Function V_getVSTable_parameters(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:table_parameters"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getVS_tilt(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:vs_tilt"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getVSWavelength(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getVSWavelength_spread(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength_spread"	
	return(V_getRealValueFromHDF5(fname,path))
end

// instrument/beam/monochromator/white_beam (data folder)
Function/S V_getWhiteBeamStatus(fname)
	String fname

	String path = "entry:instrument:beam:monochromator:white_beam:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getWhiteBeamWavelength(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:white_beam:wavelength"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getWhiteBeamWavelength_spread(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:white_beam:wavelength_spread"	
	return(V_getRealValueFromHDF5(fname,path))
end

// instrument/beam/polarizer (data folder)
Function/S V_getPolarizerComposition(fname)
	String fname

	String path = "entry:instrument:beam:polarizer:composition"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getPolarizerEfficiency(fname)
	String fname
	
	String path = "entry:instrument:beam:polarizer:efficiency"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getPolarizerStatus(fname)
	String fname

	String path = "entry:instrument:beam:polarizer:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getPolarizerType(fname)
	String fname

	String path = "entry:instrument:beam:polarizer:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// instrument/beam/polarizer_analyzer (data folder)
Function V_getPolAnaCell_index(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:cell_index"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getPolAnaCell_name(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:cell_name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getPolAnaCell_parameters(fname,outW)
	String fname
	Wave outW

	String path = "entry:instrument:beam:polarizer_analyzer:cell_parameters"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
End

Function V_getPolAnaGuideFieldCur_1(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_1"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getPolAnaGuideFieldCur_2(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_2"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getPolAnaSolenoid_current(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:solenoid_current"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getPolAnaStatus(fname)
	String fname

	String path = "entry:instrument:beam:polarizer_analyzer:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

					
/////// INSTRUMENT/BEAM MONITORS

//beam_monitor_low (data folder)
Function V_getBeamMonLowData(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:data"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonLowEfficiency(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:efficiency"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonLownx_distance(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:nx_distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonLowSaved_count(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:saved_count"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getBeamMonLowType(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//beam_monitor_norm (data folder)
Function V_getBeamMonNormData(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:data"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonNormEfficiency(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:efficiency"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonNormnx_distance(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:nx_distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonNormSaved_count(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:saved_count"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getBeamMonNormType(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//beam_stop (data folder)
Function/S V_getBeamStopDescription(fname)
	String fname

	String path = "entry:instrument:beam_stop:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getBeamStopDist_to_det(fname)
	String fname

	String path = "entry:instrument:beam_stop:distance_to_detector"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStop_x0(fname)
	String fname

	String path = "entry:instrument:beam_stop:x0"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStop_y0(fname)
	String fname

	String path = "entry:instrument:beam_stop:y0"
	return(V_getRealValueFromHDF5(fname,path))
End

//// INSTRUMENT/COLLIMATOR
//collimator (data folder)
Function V_getNumberOfGuides(fname)
	String fname

	String path = "entry:instrument:collimator:number_guides"
	return(V_getRealValueFromHDF5(fname,path))
End

//				geometry (data folder)
//					shape (data folder)
Function/S V_getGuideShape(fname)
	String fname

	String path = "entry:instrument:collimator:geometry:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getGuideSize(fname)
	String fname

	String path = "entry:instrument:collimator:geometry:shape:size"
	return(V_getRealValueFromHDF5(fname,path))
End

//			converging_pinholes (data folder)
Function/S V_getConvPinholeStatus(fname)
	String fname

	String path = "entry:instrument:converging_pinholes:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//			converging_slits (data folder)
Function/S V_getConvSlitStatus(fname)
	String fname

	String path = "entry:instrument:converging_slits:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// TODO -- write to return an ARRAY
Function V_getDet_CALX(fname,detStr,outW)
	String fname,detStr
	Wave outW

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":CALX"
		WAVE w = V_getRealWaveFromHDF5(fname,path)

		outW = w
		return(0)
	else
		return(0)
	endif
End

// only defined for the "B" detector, and may not be necessary?
// TODO -- write to return an ARRAY
Function V_getDet_CALY(fname,detStr,outW)
	String fname,detStr
	Wave outW

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":CALY"
		WAVE w = V_getRealWaveFromHDF5(fname,path)
	
		outW = w
		return(0)
	else
		return(0)
	endif
End

// TODO -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_getDet_PixelFWHM(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":PixelFWHM"

// TODO -- different behavior for "B"
	if(cmpstr(detStr,"B") == 0)
		return(V_getRealValueFromHDF5(fname,path))
	else
		return(V_getRealValueFromHDF5(fname,path))
	endif
End

Function V_getDet_PixelNumX(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":PixelNumX"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_PixelNumY(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":PixelNumY"
	return(V_getRealValueFromHDF5(fname,path))
End

// only defined for the "B" detector, and only to satisfy NXsas
Function V_getDet_azimuthalAngle(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":azimuthal_angle"
		return(V_getRealValueFromHDF5(fname,path))
	else
		return(0)
	endif
End

Function V_getDet_beam_center_x(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":beam_center_x"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_beam_center_y(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":beam_center_y"
	return(V_getRealValueFromHDF5(fname,path))
End

// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_getDetectorData(fname,detStr,outW)
	String fname,detStr
	Wave outW

	String path = "entry:instrument:detector_"+detStr+":data"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
End


// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function V_getDetector_deadtime(fname,detStr,outW)
	String fname,detStr
	Wave outW

	String path = "entry:instrument:detector_"+detStr+":dead_time"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
End


Function/S V_getDetDescription(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getDet_distance(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":distance"
	return(V_getRealValueFromHDF5(fname,path))
End

// only defined for the "B" detector, and only to satisfy NXsas
Function V_getDet_equatorial_angle(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":equatorial_angle"
		return(V_getRealValueFromHDF5(fname,path))
	else
		return(0)
	endif
End

Function/S V_getDetEventFileName(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":event_file_name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getDet_IntegratedCount(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":integrated_count"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_LateralOffset(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":lateral_offset"
	return(V_getRealValueFromHDF5(fname,path))
End

// only defined for the "B" detector, and only to satisfy NXsas
Function V_getDet_polar_angle(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":polar_angle"
		return(V_getRealValueFromHDF5(fname,path))
	else
		return(0)
	endif
End

// only defined for the "B" detector, and only to satisfy NXsas
Function V_getDet_rotational_angle(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":rotational_angle"
		return(V_getRealValueFromHDF5(fname,path))
	else
		return(0)
	endif
End

Function/S V_getDetSettings(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":settings"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// really has no meaning at all 
Function V_getDet_size(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":size"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getDetType(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getDet_x_pixel_size(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":x_pixel_size"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_y_pixel_size(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":y_pixel_size"
	return(V_getRealValueFromHDF5(fname,path))
End

/////////			detector_FB (data folder) + ALL other PANEL DETECTORS

Function V_getDet_numberOfTubes(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		return(V_getRealValueFromHDF5(fname,path))
	endif
End

// TODO -- be clear on how this is defined. Separation as defined from what point? Units?
Function V_getDetPanelSeparation(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":separation"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		return(V_getRealValueFromHDF5(fname,path))
	endif
End

// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_getDetTube_spatialCalib(fname,detStr,outW)
	String fname,detStr
	Wave outW

	String path = "entry:instrument:detector_"+detStr+":spatial_calibration"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		WAVE w = V_getRealWaveFromHDF5(fname,path)
	
		outW = w
		return(0)
	endif
End

// TODO -- be clear on how this is defined.
Function V_getDet_tubeIndex(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":tube_index"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		return(V_getRealValueFromHDF5(fname,path))
	endif
End

Function/S V_getDet_tubeOrientation(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":tube_orientation"
	Variable num=60
	if(cmpstr(detStr,"B") == 0)
		return("")
	else
		return(V_getStringFromHDF5(fname,path,num))
	endif
End

// TODO -- be clear on how this is defined. Units?
Function V_getDet_tubeWidth(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":tube_width"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		return(V_getRealValueFromHDF5(fname,path))
	endif
End

//////////////////////

// INSTRUMENT/LENSES 	/APERTURES
//  lenses (data folder)

Function V_getLensCurvature(fname)
	String fname

	String path = "entry:instrument:lenses:curvature"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getLensesFocusType(fname)
	String fname

	String path = "entry:instrument:lenses:focus_type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getLensDistance(fname)
	String fname

	String path = "entry:instrument:lenses:lens_distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getLensGeometry(fname)
	String fname

	String path = "entry:instrument:lenses:lens_geometry"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getLensMaterial(fname)
	String fname

	String path = "entry:instrument:lenses:lens_material"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getNumber_of_Lenses(fname)
	String fname

	String path = "entry:instrument:lenses:number_of_lenses"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getNumber_of_prisms(fname)
	String fname

	String path = "entry:instrument:lenses:number_of_prisms"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getPrism_distance(fname)
	String fname

	String path = "entry:instrument:lenses:prism_distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getPrismMaterial(fname)
	String fname

	String path = "entry:instrument:lenses:prism_material"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// status of lens/prism = lens | prism | both | out
Function/S V_getLensPrismStatus(fname)
	String fname

	String path = "entry:instrument:lenses:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End
	

///////  sample_aperture (data folder)

Function/S V_getSampleAp_Description(fname)
	String fname

	String path = "entry:instrument:sample_aperture:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getSampleAp_distance(fname)
	String fname

	String path = "entry:instrument:sample_aperture:distance"
	return(V_getRealValueFromHDF5(fname,path))
End
//	shape (data folder)

Function/S V_getSampleAp_shape(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- this needs to return a WAVE, since the shape may be circle, or rectangle
// and will need to return more than a single dimension
// TODO -- be careful of the UNITS
Function V_getSampleAp_size(fname,outW)
	String fname
	Wave outW

	String path = "entry:instrument:sample_aperture:shape:size"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
End		
		
//////  sample_table (data folder)
// location  = "CHAMBER" or HUBER
Function/S V_getSampleTableLocation(fname)
	String fname

	String path = "entry:instrument:sample_table:location"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function V_getSampleTableOffset(fname)
	String fname

	String path = "entry:instrument:sample_table:offset_distance"
	return(V_getRealValueFromHDF5(fname,path))
End	
	
//  source (data folder)
//name "NCNR"
Function/S V_getSourceName(fname)
	String fname

	String path = "entry:instrument:source:name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//	power -- nominal only, not connected to any real number
Function V_getReactorPower(fname)
	String fname

	String path = "entry:instrument:source:power"
	return(V_getRealValueFromHDF5(fname,path))
End	

//probe (wave) "neutron"
Function/S V_getSourceProbe(fname)
	String fname

	String path = "entry:instrument:source:probe"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//type (wave) "Reactor Neutron Source"
Function/S V_getSourceType(fname)
	String fname

	String path = "entry:instrument:source:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

	
///////  source_aperture (data folder)

Function/S V_getSourceAp_Description(fname)
	String fname

	String path = "entry:instrument:source_aperture:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getSourceAp_distance(fname)
	String fname

	String path = "entry:instrument:source_aperture:distance"
	return(V_getRealValueFromHDF5(fname,path))
End
//	shape (data folder)

Function/S V_getSourceAp_shape(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- this needs to return a WAVE, since the shape may be circle, or rectangle
// and will need to return more than a single dimension
// TODO -- be careful of the UNITS
Function V_getSourceAp_size(fname,outW)
	String fname
	Wave outW

	String path = "entry:instrument:source_aperture:shape:size"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
End		




//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//Sample position in changer
// TODO -- in the NexusWriter, this ends up as a STRING -- which is wrong. it needs to be FP
Function V_getSamplePosition(fname)
	String fname
	
	String path = "entry:sample:changer_position"	
	return(V_getRealValueFromHDF5(fname,path))
end

// sample label 
// TODO: value of num is currently not used
Function/S V_getSampleDescription(fname)
	String fname

	String path = "entry:sample:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//no meaning to this...
Function V_getSample_equatorial_ang(fname)
	String fname
	
	String path = "entry:sample:equatorial_angle"	
	return(V_getRealValueFromHDF5(fname,path))
end

// group ID !!! very important for matching up files
Function V_getSample_GroupID(fname)
	String fname
	
	String path = "entry:sample:group_id"	
	return(V_getRealValueFromHDF5(fname,path))
end


Function V_getSample_rotationAngle(fname)
	String fname
	
	String path = "entry:sample:rotation_angle"	
	return(V_getRealValueFromHDF5(fname,path))
end


//Sample Rotation Angle
Function V_getSampleRotationAngle(fname)
	String fname
	
	String path = "entry:sample:rotation_angle"	
	return(V_getRealValueFromHDF5(fname,path))
end

//?? this is huber/chamber??
// TODO -- then where is the description of 10CB, etc...
Function/S V_getSampleHolderDescription(fname)
	String fname

	String path = "entry:sample:sample_holder_description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//Sample Thickness
// TODO -- somehow, this is not set correctly in the acquisition, so NaN results
Function V_getSampleThickness(fname)
	String fname
	
	String path = "entry:sample:thickness"	
	return(V_getRealValueFromHDF5(fname,path))
end

// sample transmission
Function V_getSampleTransmission(fname)
	String fname
	
	String path = "entry:sample:transmission"	
//	String path = "QKK0037737:data:Transmission"	
	return(V_getRealValueFromHDF5(fname,path))
end

//transmission error (one sigma)
Function V_getSampleTransError(fname)
	String fname
	
	String path = "entry:sample:transmission_error"	
	return(V_getRealValueFromHDF5(fname,path))
end





// sample label
//
// TODO
// limit to 60 characters?? do I need to do this with HDF5?
//
// do I need to pad to 60 characters?
//
Function V_WriteSamLabelToHeader(fname,str)
	String fname,str
	
//	if(strlen(str) > 60)
//		str = str[0,59]
//	endif	
	
	Make/O/T/N=1 tmpTW
	String groupName = "/sample"	//	/entry is automatically prepended -- so just explicitly state the group
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	err = V_KillNamedDataFolder(fname)
	if(err)
		Print "DataFolder kill err = ",err
	endif
		
	return(err)
End

// sample transmission
Function V_WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/sample"	//	skip "entry" - /entry/sample becomes groupName /entry/entry/sample
	String varName = "transmission"
//	Make/O/R/N=1 wTmpWrite
//	String groupName = "/data"	//	skip "entry" - /entry/sample becomes groupName /entry/entry/sample
//	String varName = "Transmission"
	wTmpWrite[0] = trans //

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	err = V_KillNamedDataFolder(fname)
	if(err)
		Print "DataFolder kill err = ",err
	endif
	return(err)
End


//// SAMPLE / DATA LOGS
// write this generic , call with the name of the environment log desired
//
// temperature_1
// temperature_2
// shear_field
// pressure
// magnetic_field
// electric_field
//
//////// (for example) electric_field (data folder)

Function/S V_getLog_attachedTo(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":attached_to"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getLog_measurement(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":measurement"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getLog_Name(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


// TODO -- 
Function V_getLog_nomValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value"
	return(V_getRealValueFromHDF5(fname,path))
end

////		value_log (data folder)
Function/S V_getLog_startTime(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":value_log:start"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// TODO -- 
Function V_getLog_avgValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:average_value"
	return(V_getRealValueFromHDF5(fname,path))
end

// TODO -- this needs to be a WAVE reference
Function V_getLog_time(fname,logStr,outW)
	String fname,logStr
	Wave outW
	
	String path = "entry:sample:"+logstr+":value_log:nx_time"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end


// TODO -- this needs to be a WAVE reference
Function V_getLog_Value(fname,logStr,outW)
	String fname,logStr
	Wave outW
	
	String path = "entry:sample:"+logstr+":value_log:value"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end







///////// REDUCTION
///////// REDUCTION
///////// REDUCTION


// TODO -- needs to be a WAVE
Function V_getAbsolute_Scaling(fname,outW)
	String fname
	Wave outW
	
	String path = "entry:reduction:absolute_scaling"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

// TODO -- needs to be a WAVE
Function V_getBoxCoordinates(fname,outW)
	String fname
	Wave outW
	
	String path = "entry:reduction:box_coordinates"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

//box counts
Function V_getBoxCounts(fname)
	String fname
	
	String path = "entry:reduction:box_count"	
	return(V_getRealValueFromHDF5(fname,path))
end

//box counts error
Function V_getBoxCountsError(fname)
	String fname
	
	String path = "entry:reduction:box_count_error"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getReductionComments(fname)
	String fname

	String path = "entry:reduction:comments"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getReductionIntent(fname)
	String fname

	String path = "entry:reduction:intent"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getLogFileName(fname)
	String fname

	String path = "entry:reduction:sans_log_file_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getSensitivityFileName(fname)
	String fname

	String path = "entry:reduction:sensitivity_file_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


//whole detector trasmission
Function V_getSampleTransWholeDetector(fname)
	String fname
	
	String path = "entry:reduction:whole_trans"	
	return(V_getRealValueFromHDF5(fname,path))
end

//whole detector trasmission error
Function V_getSampleTransWholeDetErr(fname)
	String fname
	
	String path = "entry:reduction:whole_trans_error"	
	return(V_getRealValueFromHDF5(fname,path))
end

			
/////			pol_sans (data folder)

Function/S V_getPolSANS_cellName(fname)
	String fname

	String path = "entry:reduction:pol_sans:cell_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


// TODO -- needs to be a WAVE
Function V_getPolSANS_cellParams(fname,outW)
	String fname
	Wave outW
	
	String path = "entry:reduction:pol_sans:cell_parameters"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

Function/S V_getPolSANS_PolSANSPurpose(fname)
	String fname

	String path = "entry:reduction:pol_sans:pol_sans_purpose"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

				
//////// TOP LEVEL DATA REPRESENTATION
//
// note that here the data is (supposed to be) a link, not the actual data
// Igor HDf implementation cannot follow links properly, as far as I know.
// so ignore them here, and focus on the image that may be possible to read
//

//		data_B (data folder)
//			data (wave) 1		//ignore this, it's a link
//			variables (wave) 320
//			thumbnail (data folder)

//data (wave) "binary"
// TODO -- this will need to be completely replaced with a function that can 
// read the binary image data. should be possible, but I don't know the details on either end...
Function/S V_getDataImage(fname,detStr)
	String fname,detStr

	String path = "entry:data_"+detStr+":thumbnail:data"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getDataImageDescription(fname,detStr)
	String fname,detStr

	String path = "entry:data_"+detStr+":thumbnail:description"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End
								
Function/S V_getDataImageType(fname,detStr)
	String fname,detStr

	String path = "entry:data_"+detStr+":thumbnail:type"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End







//////////////////////////////
//////////////////////////////
//////////////////////////////

Function V_KillNamedDataFolder(fname)
	String fname
	
	Variable err=0
	
	String folderStr = V_GetFileNameFromPathNoSemi(fname)
	folderStr = V_RemoveDotExtension(folderStr)
	
	KillDataFolder/Z $("root:"+folderStr)
	err = V_flag
	
	return(err)
end

//given a filename of a SANS data filename of the form
// name.anything
//returns the name as a string without the ".fbdfasga" extension
//
// returns the input string if a"." can't be found (maybe it wasn't there"
Function/S V_RemoveDotExtension(item)
	String item
	String invalid = item	//
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get all of the characters preceeding it
		runStr = item[0,pos-1]
		return (runStr)
	Endif
End

//returns a string containing filename (WITHOUT the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// called by MaskUtils.ipf, ProtocolAsPanel.ipf, WriteQIS.ipf
//
Function/S V_GetFileNameFromPathNoSemi(fullPath)
	String fullPath
	
	Variable offset1,offset2
	String filename=""
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			fileName = FullPath[offset1,strlen(FullPath) ]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	//remove version number from name, if it's there - format should be: filename;N
	filename =  StringFromList(0,filename,";")		//returns null if error
	
	Return filename
End