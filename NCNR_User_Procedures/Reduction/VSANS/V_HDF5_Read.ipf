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

Proc Dump_V_getFP(fname)
	String fname
	
	Test_V_get_FP("V_get*",fname)
end

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

Proc Dump_V_getFP_Det(fname,detStr)
	String fname,detStr="FL"
	
	Test_V_get_FP2("V_get*",fname,detStr)
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


Proc Dump_V_getSTR(fname)
	String fname
	
	Test_V_get_STR("V_get*",fname)
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

Proc Dump_V_getSTR_Det(fname,detStr)
	String fname,detStr="FL"
	
	Test_V_get_STR2("V_get*",fname,detStr)
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

//// nexus version used for definitions
//Function/S V_getNeXus_version(fname)
//	String fname
//	
//	String path = "entry:NeXus_version"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

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

// cut in JUNE 2017
//// TODO - should be the file name as saved on disk, currently it's not
//Function/S V_getFile_name(fname)
//	String fname
//	
//	String path = "entry:file_name"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

// cut in JUNE 2017		
////
//Function/S V_getHDF_version(fname)
//	String fname
//	
//	String path = "entry:hdf_version"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

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

// cut in JUNE 2017
//Function/S V_getCount_end(fname)
//	String fname
//	
//	Variable num
//	String path = "entry:control:count_end"	
//	return(V_getStringFromHDF5(fname,path,num))
//end

// cut in JUNE 2017
//
//Function/S V_getCount_start(fname)
//	String fname
//	
//	Variable num
//	String path = "entry:control:count_start"	
//	return(V_getStringFromHDF5(fname,path,num))
//end


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

// cut in JUNE 2017
//
//Function V_getIntegral(fname)
//	String fname
//	
//	String path = "entry:control:integral"	
//	return(V_getRealValueFromHDF5(fname,path))
//end

// control mode for data acquisition, "timer"
// TODO - what are the enumerated types for this?
Function/S V_getControlMode(fname)
	String fname
	
	String path = "entry:control:mode"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//monitor count
// TODO - verify that this is the correct monitor
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

// cut in JUNE 2017
// TODO - what are the enumerated types for this?
//Function/S V_getPreset(fname)
//	String fname
//	
//	Variable num
//	String path = "entry:control:preset"	
//	return(V_getStringFromHDF5(fname,path,num))
//end





//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

// TODO -- this does not appear to be written out
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
// TODO - be sure of the definition of these terms
//

// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_getAttenuator_transmission(fname)
	String fname
	
	String path = "entry:instrument:attenuator:attenuator_transmission"	
	return(V_getRealValueFromHDF5(fname,path))
end

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_getAttenuator_trans_err(fname)
	String fname
	
	String path = "entry:instrument:attenuator:attenuator_transmission_error"	
	return(V_getRealValueFromHDF5(fname,path))
end

// desired thickness
Function V_getAtten_desired_thickness(fname)
	String fname
	
	String path = "entry:instrument:attenuator:desired_thickness"	
	return(V_getRealValueFromHDF5(fname,path))
end


// distance from the attenuator to the sample (units??)
Function V_getAttenDistance(fname)
	String fname
	
	String path = "entry:instrument:attenuator:distance"	
	return(V_getRealValueFromHDF5(fname,path))
end



// table of the attenuation factor error
Function/WAVE V_getAttenIndex_error_table(fname)
	String fname
	
	String path = "entry:instrument:attenuator:index_error_table"
	WAVE w = V_getRealWaveFromHDF5(fname,path)
	
	return w
end

// table of the attenuation factor
Function/WAVE V_getAttenIndex_table(fname)
	String fname
	
	String path = "entry:instrument:attenuator:index_table"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	return w
end

//
//// status "in or out"
//Function/S V_getAttenStatus(fname)
//	String fname
//
//	String path = "entry:instrument:attenuator:status"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

//// this is equivalent to "status" - if anything is dropped in the beam
//Function V_getAtten_number(fname)
//	String fname
//	
//	String path = "entry:instrument:attenuator:num_atten_dropped"	
//	return(V_getRealValueFromHDF5(fname,path))
//end

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
// instrument/beam/analyzer (data folder)
// this is the He3 analyzer, after the sample (but first alphabetically)
// TODO -- document what all of the fields represent, and what are the most important to "key" on to read
//
Function V_getAnalyzer_depth(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:depth"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getAnalyzer_direction(fname)
	String fname

	String path = "entry:instrument:beam:analyzer:direction"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getAnalyzer_height(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:height"	
	return(V_getRealValueFromHDF5(fname,path))
end

// ?? TODO is this equivalent to "status" -- ?? 0|1
Function V_getAnalyzer_inBeam(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:inBeam"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getAnalyzer_innerDiameter(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:innerDiameter"	
	return(V_getRealValueFromHDF5(fname,path))
end

// one of the most important
Function/S V_getAnalyzer_name(fname)
	String fname

	String path = "entry:instrument:beam:analyzer:name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getAnalyzer_opacityAt1Ang(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:opacityAt1Ang"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getAnalyzer_opacityAt1Ang_err(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:opacityAt1AngStd"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getAnalyzer_outerDiameter(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:outerDiameter"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getAnalyzer_shape(fname)
	String fname

	String path = "entry:instrument:beam:analyzer:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getAnalyzer_tE(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:tE"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getAnalyzer_tE_err(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:tEStd"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getAnalyzer_type(fname)
	String fname

	String path = "entry:instrument:beam:analyzer:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function V_getAnalyzer_width(fname)
	String fname
	
	String path = "entry:instrument:beam:analyzer:width"	
	return(V_getRealValueFromHDF5(fname,path))
end


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

Function/S V_getChopperStatus(fname)
	String fname

	String path = "entry:instrument:beam:chopper:status"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getChopperType(fname)
	String fname

	String path = "entry:instrument:beam:chopper:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


// instrument/beam/flipperPolarizer (data folder)
// this is upstream, after the supermirror but before the sample

Function/S V_getflipperPolarizer_Direction(fname)
	String fname

	String path = "entry:instrument:beam:flipperPolarizer:direction"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getflipperPolarizer_inBeam(fname)
	String fname
	
	String path = "entry:instrument:beam:flipperPolarizer:inBeam"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getflipperPolarizer_Type(fname)
	String fname

	String path = "entry:instrument:beam:flipperPolarizer:type"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End



//Function V_getFlipperDriving_current(fname)
//	String fname
//	
//	String path = "entry:instrument:beam:flipper:driving_current"	
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function V_getFlipperFrequency(fname)
//	String fname
//	
//	String path = "entry:instrument:beam:flipper:frequency"	
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getFlipperstatus(fname)
//	String fname
//
//	String path = "entry:instrument:beam:flipper:status"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function V_getFlipperTransmitted_power(fname)
//	String fname
//	
//	String path = "entry:instrument:beam:flipper:transmitted_power"	
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getFlipperWaveform(fname)
//	String fname
//
//	String path = "entry:instrument:beam:flipper:waveform"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End



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
Function V_getCrystalDistance(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:crystal:distance"	
	return(V_getRealValueFromHDF5(fname,path))
end

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
Function V_getVSDistance(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:distance"	
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

Function/WAVE V_getVSTable_parameters(fname)
	String fname
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:table_parameters"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	return w
end

//// DONE - this does not exist for VSANS - per JGB 4/2016
//Function V_getVS_tilt(fname)
//	String fname
//	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:vs_tilt"	
//	return(V_getRealValueFromHDF5(fname,path))
//end

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

// instrument/beam/superMirror (data folder)
// This is the upstream polarizer. There are no other choices for polarizer on VSANS
Function/S V_getPolarizerComposition(fname)
	String fname

	String path = "entry:instrument:beam:superMirror:composition"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getPolarizerEfficiency(fname)
	String fname
	
	String path = "entry:instrument:beam:superMirror:efficiency"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getPolarizerState(fname)
	String fname

	String path = "entry:instrument:beam:superMirror:state"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

//Function/S V_getPolarizerType(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer:type"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

//// instrument/beam/polarizer_analyzer (data folder)
//Function V_getPolAnaCell_index(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:cell_index"
//	return(V_getRealValueFromHDF5(fname,path))
//End
//
//Function/S V_getPolAnaCell_name(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:cell_name"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function/WAVE V_getPolAnaCell_parameters(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:cell_parameters"
//	WAVE w = V_getRealWaveFromHDF5(fname,path)
//
//	return w
//End
//
//Function V_getPolAnaGuideFieldCur_1(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_1"
//	return(V_getRealValueFromHDF5(fname,path))
//End
//
//Function V_getPolAnaGuideFieldCur_2(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_2"
//	return(V_getRealValueFromHDF5(fname,path))
//End
//
//Function V_getPolAnaSolenoid_current(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:solenoid_current"
//	return(V_getRealValueFromHDF5(fname,path))
//End
//
//Function/S V_getPolAnaStatus(fname)
//	String fname
//
//	String path = "entry:instrument:beam:polarizer_analyzer:status"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

					
/////// INSTRUMENT/BEAM MONITORS

//beam_monitor_low (data folder)
Function V_getBeamMonLowData(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:data"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonLowDistance(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonLowEfficiency(fname)
	String fname

	String path = "entry:instrument:beam_monitor_low:efficiency"
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

Function V_getBeamMonNormDistance(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:distance"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamMonNormEfficiency(fname)
	String fname

	String path = "entry:instrument:beam_monitor_norm:efficiency"
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

//beam_stop C2 (data folder)
Function/S V_getBeamStopC2Description(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getBeamStopC2Dist_to_det(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:distance_to_detector"
	return(V_getRealValueFromHDF5(fname,path))
End

//TODO -- not sure what this really means
Function V_getBeamStopC2num_beamstops(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:num_beamstops"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC2_x_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:x_pos"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC2_y_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:y_pos"
	return(V_getRealValueFromHDF5(fname,path))
End

// beam stop shape parameters
Function V_getBeamStopC2_height(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:shape:height"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getBeamStopC2_shape(fname)
	String fname

	Variable num=60
	String path = "entry:instrument:beam_stop_C2:shape:shape"
	return(V_getStringFromHDF5(fname,path,num))
End

// == diameter if shape = CIRCLE
Function V_getBeamStopC2_size(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:shape:size"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC2_width(fname)
	String fname

	String path = "entry:instrument:beam_stop_C2:shape:width"
	return(V_getRealValueFromHDF5(fname,path))
End



//beam_stop C3 (data folder)
Function/S V_getBeamStopC3Description(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getBeamStopC3Dist_to_det(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:distance_to_detector"
	return(V_getRealValueFromHDF5(fname,path))
End

//TODO -- not sure what this really means
Function V_getBeamStopC3num_beamstops(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:num_beamstops"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC3_x_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:x_pos"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC3_y_pos(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:y_pos"
	return(V_getRealValueFromHDF5(fname,path))
End

// beam stop shape parameters
Function V_getBeamStopC3_height(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:shape:height"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getBeamStopC3_shape(fname)
	String fname

	Variable num=60
	String path = "entry:instrument:beam_stop_C3:shape:shape"
	return(V_getStringFromHDF5(fname,path,num))
End

// == diameter if shape = CIRCLE
Function V_getBeamStopC3_size(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:shape:size"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getBeamStopC3_width(fname)
	String fname

	String path = "entry:instrument:beam_stop_C3:shape:width"
	return(V_getRealValueFromHDF5(fname,path))
End




//// INSTRUMENT/COLLIMATOR
//collimator (data folder)

// this is now defined as text, due to selections from GUI
Function/S V_getNumberOfGuides(fname)
	String fname

	Variable num=60
	String path = "entry:instrument:collimator:number_guides"
	return(V_getStringFromHDF5(fname,path,num))
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

//			converging_slits (not used)

////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// DONE -- write to return an ARRAY
Function/WAVE V_getDet_cal_x(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":cal_x"
		WAVE w = V_getRealWaveFromHDF5(fname,path)

		return w
	else
		return $""
	endif
End

// only defined for the "B" detector, and may not be necessary?
// TODO -- write to return an ARRAY
Function/WAVE V_getDet_cal_y(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		String path = "entry:instrument:detector_"+detStr+":cal_y"
		WAVE w = V_getRealWaveFromHDF5(fname,path)
	
		return w
	else
		return $""
	endif
End

//  Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_getDet_pixel_fwhm_x(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_x"

	return(V_getRealValueFromHDF5(fname,path))
End

// Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_getDet_pixel_fwhm_y(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_y"

	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_pixel_num_x(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":pixel_num_x"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getDet_pixel_num_y(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":pixel_num_y"
	return(V_getRealValueFromHDF5(fname,path))
End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_getDet_azimuthalAngle(fname,detStr)
//	String fname,detStr
//
//	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":azimuthal_angle"
//		return(V_getRealValueFromHDF5(fname,path))
//	else
//		return(0)
//	endif
//End

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


//TODO
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_x_mm(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":beam_center_x_mm"
	return(V_getRealValueFromHDF5(fname,path))
End

//TODO
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_y_mm(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":beam_center_y_mm"
	return(V_getRealValueFromHDF5(fname,path))
End



Function/WAVE V_getDetectorDataW(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":data"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	return w
End

//
// TODO -- this does not exist in the raw data, but does in the processed data
// !!! how to handle this?? Binning routines need the error wave
//
Function/WAVE V_getDetectorDataErrW(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":linear_data_error"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	return w
End

// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function/WAVE V_getDetector_deadtime(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr,"B") == 0)
		return $""
	else	
		WAVE w = V_getRealWaveFromHDF5(fname,path)
		return w
	endif
End

// for "B" only
Function V_getDetector_deadtime_B(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr,"B") == 0)
		return(V_getRealValueFromHDF5(fname,path))
	else	
		return(0)
	endif
End

Function/S V_getDetDescription(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getDet_NominalDistance(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":distance"
	return(V_getRealValueFromHDF5(fname,path))
End

//this is a DERIVED distance, since the nominal sdd is for the carriage (=LR panels)
Function V_getDet_ActualDistance(fname,detStr)
	String fname,detStr

	Variable sdd
	sdd = V_getDet_NominalDistance(fname,detStr)		//[cm]
	sdd += V_getDet_TBSetback(fname,detStr)/10		// written in [mm], convert to [cm], returns 0 for L/R/B panels
		
	return(sdd)
End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_getDet_equatorial_angle(fname,detStr)
//	String fname,detStr
//
//	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":equatorial_angle"
//		return(V_getRealValueFromHDF5(fname,path))
//	else
//		return(0)
//	endif
//End

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

// only return value for B and L/R detectors. everything else returns zero
Function V_getDet_LateralOffset(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
		return(0)
	endif	
	
	String path = "entry:instrument:detector_"+detStr+":lateral_offset"
	return(V_getRealValueFromHDF5(fname,path))
End

// only return values for T/B. everything else returns zero
Function V_getDet_VerticalOffset(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		return(0)
	endif	
	
	String path = "entry:instrument:detector_"+detStr+":vertical_offset"
	return(V_getRealValueFromHDF5(fname,path))
End

// TODO - be sure this is defined correctly (with correct units!)
// -- only returns for T/B detectors
Function V_getDet_TBSetback(fname,detStr)
	String fname,detStr

	if(cmpstr(detStr,"B") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		return(0)
	endif	
	
	String path = "entry:instrument:detector_"+detStr+":setback"
	return(V_getRealValueFromHDF5(fname,path))
	
	
End


Function/S V_getDetSettings(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":settings"
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


// DONE -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function/WAVE V_getDetTube_spatialCalib(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":spatial_calibration"
	if(cmpstr(detStr,"B") == 0)
		return $("")	// return should be null
	else
		WAVE w = V_getRealWaveFromHDF5(fname,path)
		return w
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

// INSTRUMENT/LENSES 
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
	



///////  sample_aperture (1) (data folder)
// this is the INTERNAL sample aperture
//
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
Function V_getSampleAp_height(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:height"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getSampleAp_shape(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// this returns TEXT, due to GUI input, == to diameter if CIRCLE
Function/S V_getSampleAp_size(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:size"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getSampleAp_width(fname)
	String fname

	String path = "entry:instrument:sample_aperture:shape:width"
	return(V_getRealValueFromHDF5(fname,path))
End



///////  sample_aperture_2 (data folder)
// sample aperture (2) is the external aperture, which may or may not be present

Function/S V_getSampleAp2_Description(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getSampleAp2_distance(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:distance"
	return(V_getRealValueFromHDF5(fname,path))
End

//	shape (data folder)
Function V_getSampleAp2_height(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:shape:height"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getSampleAp2_shape(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// this returns REAL, DIFFERENT than SampleAp1
Function V_getSampleAp2_size(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:shape:size"
	return(V_getRealValueFromHDF5(fname,path))
End

Function V_getSampleAp2_width(fname)
	String fname

	String path = "entry:instrument:sample_aperture_2:shape:width"
	return(V_getRealValueFromHDF5(fname,path))
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
Function V_getSourceAp_height(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:height"
	return(V_getRealValueFromHDF5(fname,path))
End

Function/S V_getSourceAp_shape(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:shape"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// this returns TEXT, due to GUI input, == to diameter if CIRCLE
Function/S V_getSourceAp_size(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:size"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getSourceAp_width(fname)
	String fname

	String path = "entry:instrument:source_aperture:shape:width"
	return(V_getRealValueFromHDF5(fname,path))
End


//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//Sample position in changer (returned as TEXT)
Function/S V_getSamplePosition(fname)
	String fname
	
	String path = "entry:sample:changer_position"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
end

// sample label 
Function/S V_getSampleDescription(fname)
	String fname

	String path = "entry:sample:description"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// for a z-stage??
Function V_getSampleElevation(fname)
	String fname
	
	String path = "entry:sample:elevation"	
	return(V_getRealValueFromHDF5(fname,path))
end

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

Function V_getSampleTemperature(fname)
	String fname
	
	String path = "entry:sample:temperature"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getSampleTempSetPoint(fname)
	String fname
	
	String path = "entry:sample:temperature_setpoint"	
	return(V_getRealValueFromHDF5(fname,path))
end


//Sample Thickness
// TODO -- somehow, this is not set correctly in the acquisition, so NaN results
Function V_getSampleThickness(fname)
	String fname
	
	String path = "entry:sample:thickness"	
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getSampleTranslation(fname)
	String fname
	
	String path = "entry:sample:translation"	
	return(V_getRealValueFromHDF5(fname,path))
end

// sample transmission
Function V_getSampleTransmission(fname)
	String fname
	
	String path = "entry:sample:transmission"	
	return(V_getRealValueFromHDF5(fname,path))
end

//transmission error (one sigma)
Function V_getSampleTransError(fname)
	String fname
	
	String path = "entry:sample:transmission_error"	
	return(V_getRealValueFromHDF5(fname,path))
end



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



// for temperature only, logStr = "temperature_env"
Function/S V_getTemp_ControlSensor(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":control_sensor"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// for temperature only, logStr = "temperature_env"
Function/S V_getTemp_MonitorSensor(fname,logStr)
	String fname,logStr

	String path = "entry:sample:"+logstr+":monitor_sensor"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

	

//// TODO -- this may not exist if it is not a "controlling" sensor, but there still may be logged data present
//// TODO -- it may also have different names for each sensor (setpoint_1, setpoint_2, etc. which will be a big hassle)
//Function V_getLog_setPoint(fname,logStr)
//	String fname,logStr
//	
//	String path = "entry:sample:"+logstr+":setpoint_1"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getLog_startTime(fname,logStr)
//	String fname,logStr
//
//	String path = "entry:sample:"+logstr+":start"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//
//// TODO -- this may only exist for electric field and magnetic field...
//// or may be eliminated altogether
//Function V_getLog_nomValue(fname,logStr)
//	String fname,logStr
//	
//	String path = "entry:sample:"+logstr+":value"
//	return(V_getRealValueFromHDF5(fname,path))
//end



///////////
// for temperature, the "attached_to", "measurement", and "name" fields
// are one level down farther than before, and down deeper than for other sensors
//
//
// read the value of V_getTemp_MonitorSensor/ControlSensor to get the name of the sensor level .
//

Function/S V_getTempLog_attachedTo(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":attached_to"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getTempLog_highTrip(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":high_trip_value"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_holdTime(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":hold_time"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_lowTrip(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":low_trip_value"
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getTempLog_measurement(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":measurement"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


Function/S V_getTempLog_Model(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":model"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getTempLog_Name(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getTempLog_runControl(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":run_control"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_Setpoint(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":setpoint"
	return(V_getRealValueFromHDF5(fname,path))
end

Function/S V_getTempLog_ShortName(fname,logStr)
	String fname,logStr

	String path = "entry:sample:temperature_env:"+logstr+":short_name"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function V_getTempLog_Timeout(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":timeout"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_Tolerance(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":tolerance"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_ToleranceBand(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":tolerance_band_time"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getTempLog_Value(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:temperature_env:"+logstr+":value"
	return(V_getRealValueFromHDF5(fname,path))
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
// read the value of V_getTemp_MonitorSensor to get the name of the sensor the next level down.
//
Function V_getLog_avgValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:average_value"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getLog_avgValue_err(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:average_value_error"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getLog_maximumValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:maximum_value"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getLog_medianValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:median_value"
	return(V_getRealValueFromHDF5(fname,path))
end

Function V_getLog_minimumValue(fname,logStr)
	String fname,logStr
	
	String path = "entry:sample:"+logstr+":value_log:minimum_value"
	return(V_getRealValueFromHDF5(fname,path))
end

// DONE -- this needs to be a WAVE reference
// DONE -- verify that the field is really read in as "time0"
Function V_getLog_timeWave(fname,logStr,outW)
	String fname,logStr
	Wave outW
	
	String path = "entry:sample:"+logstr+":value_log:time0"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	outW = w
	return(0)
end

// DONE -- this needs to be a WAVE reference
Function V_getLog_ValueWave(fname,logStr,outW)
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


Function/WAVE V_getAbsolute_Scaling(fname)
	String fname
	
	String path = "entry:reduction:absolute_scaling"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)
	
	return w
end

Function/S V_getBackgroundFileName(fname)
	String fname

	String path = "entry:reduction:background_file_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/WAVE V_getBoxCoordinates(fname)
	String fname
	
	String path = "entry:reduction:box_coordinates"	
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	return w
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


Function/S V_getEmptyBeamFileName(fname)
	String fname

	String path = "entry:reduction:empty_beam_file_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getEmptyFileName(fname)
	String fname

	String path = "entry:reduction:empty_file_name"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

// this is (presumably) the polarization "intent"
Function/S V_getReduction_polSANSPurpose(fname)
	String fname

	String path = "entry:reduction:file_purpose"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

////group ID
//// DONE
//// x- is this duplicated?
//// x- yes, this is a duplicated field in the /entry/sample block (and is probably more appropriate there)
//// x- so pick a single location, rather than needing to duplicate.
//// x- REPLACE with a single function V_getSample_GroupID()
////
//Function V_getSample_group_ID(fname)
//	String fname
//
//// do not use the entry/reduction location
////	String path = "entry:reduction:group_id" 
//	String path = "entry:sample:group_id"	
//
//	return(V_getRealValueFromHDF5(fname,path))
//end

Function/S V_getReduction_intent(fname)
	String fname

	String path = "entry:reduction:intent"	
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End

Function/S V_getMaskFileName(fname)
	String fname

	String path = "entry:reduction:mask_file_name"	
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

Function/S V_getTransmissionFileName(fname)
	String fname

	String path = "entry:reduction:transmission_file_name"	
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

// this is a NON NICE entered field
// so I need to catch the error if it's not there
Function/WAVE V_getReductionProtocolWave(fname)
	String fname
	
	String path = "entry:reduction:protocol"	
	WAVE/T/Z tw = V_getTextWaveFromHDF5(fname,path)
	
	if(waveExists(tw))
		return tw
	else
		Make/O/T/N=0 nullTextWave
		return nullTextWave
	endif
	
end
	



// these have all been moved elsewhere			
///////			pol_sans (data folder)
//
//Function/S V_getPolSANS_cellName(fname)
//	String fname
//
//	String path = "entry:reduction:pol_sans:cell_name"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//
//Function/WAVE V_getPolSANS_cellParams(fname)
//	String fname
//	
//	String path = "entry:reduction:pol_sans:cell_parameters"	
//	WAVE w = V_getRealWaveFromHDF5(fname,path)
//
//	return w
//end
//
//Function/S V_getPolSANS_PolSANSPurpose(fname)
//	String fname
//
//	String path = "entry:reduction:pol_sans:pol_sans_purpose"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

				
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

////data (wave) "binary"
//// TODO -- this will need to be completely replaced with a function that can 
//// read the binary image data. should be possible, but I don't know the details on either end...
//Function/S V_getDataImage(fname,detStr)
//	String fname,detStr
//
//	String path = "entry:data_"+detStr+":thumbnail:data"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function/S V_getDataImageDescription(fname,detStr)
//	String fname,detStr
//
//	String path = "entry:data_"+detStr+":thumbnail:description"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//								
//Function/S V_getDataImageType(fname,detStr)
//	String fname,detStr
//
//	String path = "entry:data_"+detStr+":thumbnail:type"	
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//


