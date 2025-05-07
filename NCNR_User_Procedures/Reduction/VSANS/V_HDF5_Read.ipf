#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

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
Function proto_V_get_FP(string str)

	return (0)
End

Function proto_V_get_FP2(string str, string str2)

	return (0)
End

Function/S proto_V_get_STR(string str)

	return ("")
End

Proc Dump_V_getFP(fname)
	string fname

	Test_V_get_FP("V_get*", fname)
EndMacro

Function Test_V_get_FP(string str, string fname)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_V_get_FP f = $item
		Print item, " = ", f(fname)
	endfor

	return (0)
End

Proc Dump_V_getFP_Det(fname, detStr)
	string fname
	string detStr = "FL"

	Test_V_get_FP2("V_get*", fname, detStr)
EndMacro

Function Test_V_get_FP2(string str, string fname, string detStr)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_V_get_FP2 f = $item
		Print item, " = ", f(fname, detStr)
	endfor

	return (0)
End

Proc Dump_V_getSTR(fname)
	string fname

	Test_V_get_STR("V_get*", fname)
EndMacro

Function Test_V_get_STR(string str, string fname)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_V_get_STR f = $item
		printf "%s = ", item
		sprintf strToEx, "Print %s(\"%s\")", item, fname
		Execute strToEx
		//		print strToEx
		//		Print item ," = ", f(fname)
	endfor

	return (0)
End

Proc Dump_V_getSTR_Det(fname, detStr)
	string fname
	string detStr = "FL"

	Test_V_get_STR2("V_get*", fname, detStr)
EndMacro

Function Test_V_get_STR2(string str, string fname, string detStr)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_V_get_STR f = $item
		printf "%s = ", item
		sprintf strToEx, "Print %s(\"%s\",\"%s\")", item, fname, detStr
		Execute strToEx
		//		print strToEx
		//		Print item ," = ", f(fname)
	endfor

	return (0)
End
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
// (DONE) -- verify the paths, and add more as needed
//  -- for all of the String functions -- "num" does nothing right now -
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

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function V_getCollectionTime(string fname)

	string path = "entry:collection_time"
	return (V_getRealValueFromHDF5(fname, path))
End

// data directory where data files are stored (for user access, not archive)
Function/S V_getData_directory(string fname)

	string   path = "entry:data_directory"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// Base class of Nexus definition (=NXsas)
Function/S V_getNexusDefinition(string fname)

	string   path = "entry:definition"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function V_getDataDuration(string fname)

	string path = "entry:duration"
	return (V_getRealValueFromHDF5(fname, path))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection end time
Function/S V_getDataEndTime(string fname)

	string   path = "entry:end_time"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// experiment description
Function/S V_getExperiment_description(string fname)

	string   path = "entry:experiment_description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// experiment identifier? used only by NICE?
Function/S V_getExperiment_identifier(string fname)

	string   path = "entry:experiment_identifier"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// name of facility = NCNR
Function/S V_getFacility(string fname)

	string   path = "entry:facility"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// **cut in JUNE 2017
////  x- should be the file name as saved on disk, currently it's not
//Function/S V_getFile_name(fname)
//	String fname
//
//	String path = "entry:file_name"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

// **cut in JUNE 2017
////
//Function/S V_getHDF_version(fname)
//	String fname
//
//	String path = "entry:hdf_version"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

// (DONE) -- not mine, added somewhere by Nexus writer?
Function/S V_getProgram_name(string fname)

	string   path = "entry:program_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection start time
Function/S V_getDataStartTime(string fname)

	string   path = "entry:start_time"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// title of experiment
Function/S V_getTitle(string fname)

	string   path = "entry:title"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

////////// USER
////////// USER
////////// USER

// list of user names
//  x- currently not written out to data file??
Function/S V_getUserNames(string fname)

	string   path = "entry:user:name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//////// CONTROL
//////// CONTROL
//////// CONTROL

// (DONE) -- for the control section, document each of the fields

// **cut in JUNE 2017
//Function/S V_getCount_end(fname)
//	String fname
//
//	Variable num
//	String path = "entry:control:count_end"
//	return(V_getStringFromHDF5(fname,path,num))
//end

// **cut in JUNE 2017
//
//Function/S V_getCount_start(fname)
//	String fname
//
//	Variable num
//	String path = "entry:control:count_start"
//	return(V_getStringFromHDF5(fname,path,num))
//end

Function V_getCount_time(string fname)

	string path = "entry:control:count_time"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCount_time_preset(string fname)

	string path = "entry:control:count_time_preset"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDetector_counts(string fname)

	string path = "entry:control:detector_counts"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDetector_preset(string fname)

	string path = "entry:control:detector_preset"
	return (V_getRealValueFromHDF5(fname, path))
End

// **cut in JUNE 2017
//
//Function V_getIntegral(fname)
//	String fname
//
//	String path = "entry:control:integral"
//	return(V_getRealValueFromHDF5(fname,path))
//end

// control mode for data acquisition, "timer"
//  - what are the enumerated types for this?
Function/S V_getControlMode(string fname)

	string   path = "entry:control:mode"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//monitor count
// TODO - verify that this is the correct monitor
Function V_getControlMonitorCount(string fname)

	string path = "entry:control:monitor_counts"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getControlMonitor_preset(string fname)

	string path = "entry:control:monitor_preset"
	return (V_getRealValueFromHDF5(fname, path))
End

// **cut in JUNE 2017
//  - what are the enumerated types for this?
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

// x- this does not appear to be written out
Function/S V_getLocalContact(string fname)

	string   path = "entry:instrument:local_contact"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getInstrumentName(string fname)

	string   path = "entry:instrument:name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getInstrumentType(string fname)

	string   path = "entry:instrument:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

////// INSTRUMENT/ATTENUATOR
//  - be sure of the definition of these terms
//

// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
// (and something is wrong -- NICE always writes out "1" for the atten factor (and error)
//-- so I am forced to use the tables every time
//
Function V_getAttenuator_transmission(string fname)

	Print "Atten read - diverted to calculation"
	return (V_CalculateAttenuationFactor(fname))

	//	String path = "entry:instrument:attenuator:attenuator_transmission"
	//	return(V_getRealValueFromHDF5(fname,path))

End

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_getAttenuator_trans_err(string fname)

	Print "Atten_err read - diverted to calculation"
	return (V_CalculateAttenuationError(fname))

	//	String path = "entry:instrument:attenuator:attenuator_transmission_error"
	//	return(V_getRealValueFromHDF5(fname,path))

End

// desired thickness
Function V_getAtten_desired_thickness(string fname)

	string path = "entry:instrument:attenuator:desired_thickness"
	return (V_getRealValueFromHDF5(fname, path))
End

// distance from the attenuator to the sample (units??)
Function V_getAttenDistance(string fname)

	string path = "entry:instrument:attenuator:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

// table of the attenuation factor error
Function/WAVE V_getAttenIndex_error_table(string fname)

	string path = "entry:instrument:attenuator:index_error_table"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

// table of the attenuation factor
Function/WAVE V_getAttenIndex_table(string fname)

	string path = "entry:instrument:attenuator:index_table"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

//
//// status "in or out"
//Function/S V_getAttenStatus(fname)
//	String fname
//
//	String path = "entry:instrument:attenuator:status"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End

//// this is the "number" of attenuators dropped in the beam - and should be
// what I can use to lookup the actual attenuator transmission
Function V_getAtten_number(string fname)

	string path = "entry:instrument:attenuator:num_atten_dropped"
	return (V_getRealValueFromHDF5(fname, path))
End

// thickness of the attenuator (PMMA) - units??
Function V_getAttenThickness(string fname)

	string path = "entry:instrument:attenuator:thickness"
	return (V_getRealValueFromHDF5(fname, path))
End

// type of material for the atteunator
Function/S V_getAttenType(string fname)

	string   path = "entry:instrument:attenuator:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// new back polarizer calls
// JUN 2020
// since the location of the original ones that were decided on have changed
// wihtout my knowledge
//
//
Function V_getBackPolarizer_depth(string fname)

	string path = "entry:instrument:backPolarizer:depth"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBackPolarizer_direction(string fname)

	string   path = "entry:instrument:backPolarizer:direction"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getBackPolarizer_height(string fname)

	string path = "entry:instrument:backPolarizer:height"
	return (V_getRealValueFromHDF5(fname, path))
End

// ?? is this equivalent to "status" -- ?? 0|1
Function V_getBackPolarizer_inBeam(string fname)

	string path = "entry:instrument:backPolarizer:inBeam"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBackPolarizer_innerRadius(string fname)

	string path = "entry:instrument:backPolarizer:innerRadius"
	return (V_getRealValueFromHDF5(fname, path))
End

// one of the most important
Function/S V_getBackPolarizer_name(string fname)

	string   path = "entry:instrument:backPolarizer:name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getBackPolarizer_opac1A(string fname)

	string path = "entry:instrument:backPolarizer:opacityAt1Ang"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBackPolarizer_opac1A_err(string fname)

	string path = "entry:instrument:backPolarizer:opacityAt1AngStd"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBackPolarizer_outerRadius(string fname)

	string path = "entry:instrument:backPolarizer:outerRadius"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBackPolarizer_shape(string fname)

	string   path = "entry:instrument:backPolarizer:shape"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getBackPolarizer_tE(string fname)

	string path = "entry:instrument:backPolarizer:tE"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBackPolarizer_tE_err(string fname)

	string path = "entry:instrument:backPolarizer:tEStd"
	return (V_getRealValueFromHDF5(fname, path))
End

// TODO -- what units, zero, etc is the time stamp??
Function V_getBackPolarizer_timestamp(string fname)

	string path = "entry:instrument:backPolarizer:timestamp"
	return (V_getRealValueFromHDF5(fname, path))
End

//TODO-- this returns a number now -- what does it mean?
Function V_getBackPolarizer_type(string fname)

	string path = "entry:instrument:backPolarizer:type"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBackPolarizer_width(string fname)

	string path = "entry:instrument:backPolarizer:width"
	return (V_getRealValueFromHDF5(fname, path))
End
//////////////////

////// INSTRUMENT/BEAM
// instrument/beam/analyzer (data folder)
// this is the He3 analyzer, after the sample (but first alphabetically)
// NO -- document what all of the fields represent, and what are the most important to "key" on to read
//
// like the flipper fields, all of these have changed location wihtout consulting me
// JUN 2020
//
//Function V_getAnalyzer_depth(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:depth"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getAnalyzer_direction(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:direction"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function V_getAnalyzer_height(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:height"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//// ?? TODO is this equivalent to "status" -- ?? 0|1
//Function V_getAnalyzer_inBeam(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:inBeam"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function V_getAnalyzer_innerDiameter(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:innerDiameter"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//// one of the most important
//Function/S V_getAnalyzer_name(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:name"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function V_getAnalyzer_opacityAt1Ang(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:opacityAt1Ang"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function V_getAnalyzer_opacityAt1Ang_err(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:opacityAt1AngStd"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function V_getAnalyzer_outerDiameter(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:outerDiameter"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getAnalyzer_shape(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:shape"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function V_getAnalyzer_tE(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:tE"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function V_getAnalyzer_tE_err(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:tEStd"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getAnalyzer_type(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:type"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//
//Function V_getAnalyzer_width(fname)
//	String fname
//
//	String path = "entry:instrument:beam:analyzer:width"
//	return(V_getRealValueFromHDF5(fname,path))
//end

// instrument/beam/chopper (data folder)
Function V_getChopperAngular_opening(string fname)

	string path = "entry:instrument:beam:chopper:angular_opening"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getChopDistance_from_sample(string fname)

	string path = "entry:instrument:beam:chopper:distance_from_sample"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getChopDistance_from_source(string fname)

	string path = "entry:instrument:beam:chopper:distance_from_source"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getChopperDuty_cycle(string fname)

	string path = "entry:instrument:beam:chopper:duty_cycle"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getChopperRotation_speed(string fname)

	string path = "entry:instrument:beam:chopper:rotation_speed"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getChopperSlits(string fname)

	string path = "entry:instrument:beam:chopper:slits"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getChopperStatus(string fname)

	string   path = "entry:instrument:beam:chopper:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getChopperType(string fname)

	string   path = "entry:instrument:beam:chopper:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// are these the correct locations in the header for polarization?
// they are what is in the example polarized beam data I was given in 2019
// but don't match what was decided for the data file. Nobody ever
// told me of any changes, so I guess I'm out of the loop as usual.

// the FRONT FLIPPER
// JUN 2020 -- added these calls

Function/S V_getFrontFlipper_Direction(string fname)

	string   path = "entry:instrument:frontFlipper:direction"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getFrontFlipper_flip(string fname)

	string   path = "entry:instrument:frontFlipper:flip"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getFrontFlipper_power(string fname)

	string path = "entry:instrument:frontFlipper:transmitted_power"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getFrontFlipper_type(string fname)

	string   path = "entry:instrument:frontFlipper:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//
// these apparently have all been changed without telling me...
//
// instrument/beam/flipperPolarizer (data folder)
// this is upstream, after the supermirror but before the sample
//
//Function/S V_getflipperPolarizer_Direction(fname)
//	String fname
//
//	String path = "entry:instrument:beam:flipperPolarizer:direction"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//Function V_getflipperPolarizer_inBeam(fname)
//	String fname
//
//	String path = "entry:instrument:beam:flipperPolarizer:inBeam"
//	return(V_getRealValueFromHDF5(fname,path))
//end
//
//Function/S V_getflipperPolarizer_Type(fname)
//	String fname
//
//	String path = "entry:instrument:beam:flipperPolarizer:type"
//	Variable num=60
//	return(V_getStringFromHDF5(fname,path,num))
//End
//
//
//
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
//

// instrument/beam/monochromator (data folder)
Function/S V_getMonochromatorType(string fname)

	string   path = "entry:instrument:beam:monochromator:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getWavelength(string fname)

	string path = "entry:instrument:beam:monochromator:wavelength"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getWavelength_spread(string fname)

	string path = "entry:instrument:beam:monochromator:wavelength_spread"
	return (V_getRealValueFromHDF5(fname, path))
End

// instrument/beam/monochromator/crystal (data folder)
Function V_getCrystalDistance(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalEnergy(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:energy"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalHorizontal_aperture(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:horizontal_aperture"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalHoriz_curvature(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:horizontal_curvature"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalLattice_parameter(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:lattice_parameter"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalReflection(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:reflection"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalRotation(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:rotation"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getCrystalStatus(string fname)

	string   path = "entry:instrument:beam:monochromator:crystal:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getCrystalVertical_aperture(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:vertical_aperture"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalVertical_curvature(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:vertical_curvature"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalWavelength(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:wavelength"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalWavelength_spread(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:wavelength_spread"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getCrystalWavevector(string fname)

	string path = "entry:instrument:beam:monochromator:crystal:wavevector"
	return (V_getRealValueFromHDF5(fname, path))
End

// instrument/beam/monochromator/velocity_selector (data folder)
Function V_getVSDistance(string fname)

	string path = "entry:instrument:beam:monochromator:velocity_selector:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getVSRotation_speed(string fname)

	string path = "entry:instrument:beam:monochromator:velocity_selector:rotation_speed"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getVelSelStatus(string fname)

	string   path = "entry:instrument:beam:monochromator:velocity_selector:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/WAVE V_getVSTable_parameters(string fname)

	string path = "entry:instrument:beam:monochromator:velocity_selector:table_parameters"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

//// DONE - this does not exist for VSANS - per JGB 4/2016
//Function V_getVS_tilt(fname)
//	String fname
//
//	String path = "entry:instrument:beam:monochromator:velocity_selector:vs_tilt"
//	return(V_getRealValueFromHDF5(fname,path))
//end

Function V_getVSWavelength(string fname)

	string path = "entry:instrument:beam:monochromator:velocity_selector:wavelength"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getVSWavelength_spread(string fname)

	string path = "entry:instrument:beam:monochromator:velocity_selector:wavelength_spread"
	return (V_getRealValueFromHDF5(fname, path))
End

// instrument/beam/monochromator/white_beam (data folder)
Function/S V_getWhiteBeamStatus(string fname)

	string   path = "entry:instrument:beam:monochromator:white_beam:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getWhiteBeamWavelength(string fname)

	string path = "entry:instrument:beam:monochromator:white_beam:wavelength"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getWhiteBeamWavelength_spread(string fname)

	string path = "entry:instrument:beam:monochromator:white_beam:wavelength_spread"
	return (V_getRealValueFromHDF5(fname, path))
End

// instrument/beam/superMirror (data folder)
// This is the upstream polarizer. There are no other choices for polarizer on VSANS
Function/S V_getPolarizerComposition(string fname)

	string   path = "entry:instrument:beam:superMirror:composition"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getPolarizerEfficiency(string fname)

	string path = "entry:instrument:beam:superMirror:efficiency"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getPolarizerState(string fname)

	string   path = "entry:instrument:beam:superMirror:state"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
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
Function V_getBeamMonLowData(string fname)

	string path = "entry:instrument:beam_monitor_low:data"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonLowDistance(string fname)

	string path = "entry:instrument:beam_monitor_low:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonLowEfficiency(string fname)

	string path = "entry:instrument:beam_monitor_low:efficiency"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonLowSaved_count(string fname)

	string path = "entry:instrument:beam_monitor_low:saved_count"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBeamMonLowType(string fname)

	string   path = "entry:instrument:beam_monitor_low:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//beam_monitor_norm (data folder)
Function V_getBeamMonNormData(string fname)

	string path = "entry:instrument:beam_monitor_norm:data"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonNormDistance(string fname)

	string path = "entry:instrument:beam_monitor_norm:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonNormEfficiency(string fname)

	string path = "entry:instrument:beam_monitor_norm:efficiency"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamMonNormSaved_count(string fname)

	string path = "entry:instrument:beam_monitor_norm:saved_count"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBeamMonNormType(string fname)

	string   path = "entry:instrument:beam_monitor_norm:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//beam_stop C2 (data folder)
Function/S V_getBeamStopC2Description(string fname)

	string   path = "entry:instrument:beam_stop_C2:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getBeamStopC2Dist_to_det(string fname)

	string path = "entry:instrument:beam_stop_C2:distance_to_detector"
	return (V_getRealValueFromHDF5(fname, path))
End

//TODO -- not sure what this really means
Function V_getBeamStopC2num_beamstops(string fname)

	string path = "entry:instrument:beam_stop_C2:num_beamstops"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC2_x_pos(string fname)

	string path = "entry:instrument:beam_stop_C2:x_pos"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC2_y_pos(string fname)

	string path = "entry:instrument:beam_stop_C2:y_pos"
	return (V_getRealValueFromHDF5(fname, path))
End

// beam stop shape parameters
Function V_getBeamStopC2_height(string fname)

	string path = "entry:instrument:beam_stop_C2:shape:height"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBeamStopC2_shape(string fname)

	variable num  = 60
	string   path = "entry:instrument:beam_stop_C2:shape:shape"
	return (V_getStringFromHDF5(fname, path, num))
End

// == diameter if shape = CIRCLE
// value is expected in [mm] diameter
Function V_getBeamStopC2_size(string fname)

	string path = "entry:instrument:beam_stop_C2:shape:size"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC2_width(string fname)

	string path = "entry:instrument:beam_stop_C2:shape:width"
	return (V_getRealValueFromHDF5(fname, path))
End

//beam_stop C3 (data folder)
Function/S V_getBeamStopC3Description(string fname)

	string   path = "entry:instrument:beam_stop_C3:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getBeamStopC3Dist_to_det(string fname)

	string path = "entry:instrument:beam_stop_C3:distance_to_detector"
	return (V_getRealValueFromHDF5(fname, path))
End

//TODO -- not sure what this really means
Function V_getBeamStopC3num_beamstops(string fname)

	string path = "entry:instrument:beam_stop_C3:num_beamstops"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC3_x_pos(string fname)

	string path = "entry:instrument:beam_stop_C3:x_pos"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC3_y_pos(string fname)

	string path = "entry:instrument:beam_stop_C3:y_pos"
	return (V_getRealValueFromHDF5(fname, path))
End

// beam stop shape parameters
Function V_getBeamStopC3_height(string fname)

	string path = "entry:instrument:beam_stop_C3:shape:height"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getBeamStopC3_shape(string fname)

	variable num  = 60
	string   path = "entry:instrument:beam_stop_C3:shape:shape"
	return (V_getStringFromHDF5(fname, path, num))
End

// == diameter if shape = CIRCLE
Function V_getBeamStopC3_size(string fname)

	string path = "entry:instrument:beam_stop_C3:shape:size"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getBeamStopC3_width(string fname)

	string path = "entry:instrument:beam_stop_C3:shape:width"
	return (V_getRealValueFromHDF5(fname, path))
End

//// INSTRUMENT/COLLIMATOR
//collimator (data folder)

// this is now defined as text, due to selections from GUI
Function/S V_getNumberOfGuides(string fname)

	variable num  = 60
	string   path = "entry:instrument:collimator:number_guides"
	return (V_getStringFromHDF5(fname, path, num))
End

//				geometry (data folder)
//					shape (data folder)
Function/S V_getGuideShape(string fname)

	string   path = "entry:instrument:collimator:geometry:shape:shape"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getGuideSize(string fname)

	string path = "entry:instrument:collimator:geometry:shape:size"
	return (V_getRealValueFromHDF5(fname, path))
End

//			converging_pinholes (data folder)
Function/S V_getConvPinholeStatus(string fname)

	string   path = "entry:instrument:converging_pinholes:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//			converging_slits (not used)

////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// DONE -- write to return an ARRAY
Function/WAVE V_getDet_cal_x(string fname, string detStr)

	if(cmpstr(detStr, "B") == 0)
		string path = "entry:instrument:detector_" + detStr + ":cal_x"
		WAVE   w    = V_getRealWaveFromHDF5(fname, path)

		return w
	endif

	return $""
End

// only defined for the "B" detector, and may not be necessary?
// (DONE) -- write to return an ARRAY
Function/WAVE V_getDet_cal_y(string fname, string detStr)

	if(cmpstr(detStr, "B") == 0)
		string path = "entry:instrument:detector_" + detStr + ":cal_y"
		WAVE   w    = V_getRealWaveFromHDF5(fname, path)

		return w
	endif

	return $""
End

//  Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_getDet_pixel_fwhm_x(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":pixel_fwhm_x"

	return (V_getRealValueFromHDF5(fname, path))
End

// Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_getDet_pixel_fwhm_y(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":pixel_fwhm_y"

	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDet_pixel_num_x(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":pixel_num_x"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDet_pixel_num_y(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":pixel_num_y"
	return (V_getRealValueFromHDF5(fname, path))
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

Function V_getDet_beam_center_x(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_x"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDet_beam_center_y(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_y"
	return (V_getRealValueFromHDF5(fname, path))
End

//(DONE)
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_x_mm(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_x_mm"
	return (V_getRealValueFromHDF5(fname, path))
End

//(DONE)
//
// x and y center in mm is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_y_mm(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_y_mm"
	return (V_getRealValueFromHDF5(fname, path))
End

//(DONE)
//
// x and y center in pix is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_x_pix(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_x_pix"
	return (V_getRealValueFromHDF5(fname, path))
End

//(DONE)
//
// x and y center in pix is currently not part of the Nexus definition
//  does it need to be?
// these lookups will fail if they have not been generated locally!
Function V_getDet_beam_center_y_pix(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":beam_center_y_pix"
	return (V_getRealValueFromHDF5(fname, path))
End

// changed behavior 15 SEP 2020
// added /Z flag to not generate error if data (highRes) is missing, but
// to return a null wave as a flag that the data is missing (as designed by NICE)
Function/WAVE V_getDetectorDataW(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":data"
	WAVE/Z w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

// NOTE - this is not part of the file as written
// it is generated when the RAW data is loaded (when the error wave is generated)
Function/WAVE V_getDetectorLinearDataW(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":linear_data"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

//
// (DONE) -- this does not exist in the raw data, but does in the processed data
// !!! how to handle this?? Binning routines need the error wave
// -- be sure that I generate a local copy of this wave at load time
//
Function/WAVE V_getDetectorLinearDataErrW(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":linear_data_error"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

//
// (DONE) -- this does not exist in the raw data, but does in the processed data
// !!! how to handle this?? Binning routines need the error wave
// -- be sure that I generate a local copy of this wave at load time
//

Function/WAVE V_getDetectorDataErrW(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":data_error"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function/WAVE V_getDetector_deadtime(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":dead_time"
	if(cmpstr(detStr, "B") == 0)
		return $""
	endif

	WAVE w = V_getRealWaveFromHDF5(fname, path)
	return w
End

// for "B" only
Function V_getDetector_deadtime_B(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":dead_time"
	if(cmpstr(detStr, "B") == 0)
		return (V_getRealValueFromHDF5(fname, path))
	endif

	return (0)
End

// for "B" only
Function V_getDetector_highResGain(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":highResGain"
	if(cmpstr(detStr, "B") == 0)
		return (V_getRealValueFromHDF5(fname, path))
	endif

	return (0)
End

Function/S V_getDetDescription(string fname, string detStr)

	string   path = "entry:instrument:detector_" + detStr + ":description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// return value in [cm]
Function V_getDet_NominalDistance(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":distance"
	return (V_getRealValueFromHDF5(fname, path))
End

//this is a DERIVED distance, since the nominal sdd is for the carriage (=LR panels)
// return value in [cm]
Function V_getDet_ActualDistance(string fname, string detStr)

	variable sdd
	sdd  = V_getDet_NominalDistance(fname, detStr) //[cm]
	sdd += V_getDet_TBSetback(fname, detStr)       // written [cm], returns 0 for L/R/B panels

	return (sdd)
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

Function/S V_getDetEventFileName(string fname, string detStr)

	string   path = "entry:instrument:detector_" + detStr + ":event_file_name"
	variable num  = 60
	if(cmpstr(detStr, "B") == 0) //return null string for B
		return ("")
	endif
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getDet_IntegratedCount(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":integrated_count"
	return (V_getRealValueFromHDF5(fname, path))
End

// only return value for B and L/R detectors. everything else returns zero
Function V_getDet_LateralOffset(string fname, string detStr)

	if(cmpstr(detStr, "FT") == 0 || cmpstr(detStr, "FB") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MT") == 0 || cmpstr(detStr, "MB") == 0)
		return (0)
	endif

	string path = "entry:instrument:detector_" + detStr + ":lateral_offset"
	return (V_getRealValueFromHDF5(fname, path))
End

// only return values for T/B. everything else returns zero
Function V_getDet_VerticalOffset(string fname, string detStr)

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "FR") == 0 || cmpstr(detStr, "FL") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MR") == 0 || cmpstr(detStr, "ML") == 0)
		return (0)
	endif

	string path = "entry:instrument:detector_" + detStr + ":vertical_offset"
	return (V_getRealValueFromHDF5(fname, path))
End

// -DONE be sure this is defined correctly (with correct units-- this is now 41.0 cm)
// -- only returns for T/B detectors
Function V_getDet_TBSetback(string fname, string detStr)

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "FR") == 0 || cmpstr(detStr, "FL") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MR") == 0 || cmpstr(detStr, "ML") == 0)
		return (0)
	endif

	string path = "entry:instrument:detector_" + detStr + ":setback"
	return (V_getRealValueFromHDF5(fname, path))

End

// gap when panels are "touching"
// units are mm
// returns gap value for RIGHT and LEFT (they are the same)
// returns gap value for TOP and BOTTOM (they are the same)
// returns 0 for BACK, (no such field for this detector)
//
Function V_getDet_panel_gap(string fname, string detStr)

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif
	//	if(cmpstr(detStr,"FB") == 0 || cmpstr(detStr,"FL") == 0)
	//		return(0)
	//	endif
	//	if(cmpstr(detStr,"MB") == 0 || cmpstr(detStr,"ML") == 0)
	//		return(0)
	//	endif

	string path = "entry:instrument:detector_" + detStr + ":panel_gap"
	return (V_getRealValueFromHDF5(fname, path))

End

Function/S V_getDetSettings(string fname, string detStr)

	string   path = "entry:instrument:detector_" + detStr + ":settings"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// returns [mm]
Function V_getDet_x_pixel_size(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":x_pixel_size"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getDet_y_pixel_size(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":y_pixel_size"
	return (V_getRealValueFromHDF5(fname, path))
End

/////////			detector_FB (data folder) + ALL other PANEL DETECTORS

Function V_getDet_numberOfTubes(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":number_of_tubes"
	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	return (V_getRealValueFromHDF5(fname, path))
End

// DONE -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function/WAVE V_getDetTube_spatialCalib(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":spatial_calibration"
	if(cmpstr(detStr, "B") == 0)
		return $("") // return should be null
	endif

	WAVE w = V_getRealWaveFromHDF5(fname, path)
	return w
End

Function/S V_getDet_tubeOrientation(string fname, string detStr)

	string   path = "entry:instrument:detector_" + detStr + ":tube_orientation"
	variable num  = 60
	if(cmpstr(detStr, "B") == 0)
		return ("")
	endif

	return (V_getStringFromHDF5(fname, path, num))
End

// (DONE) -- be clear on how this is defined. Units are in [mm]
Function V_getDet_tubeWidth(string fname, string detStr)

	string path = "entry:instrument:detector_" + detStr + ":tube_width"
	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	return (V_getRealValueFromHDF5(fname, path))
End

//////////////////////

// INSTRUMENT/LENSES
//  lenses (data folder)

Function V_getLensCurvature(string fname)

	string path = "entry:instrument:lenses:curvature"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getLensesFocusType(string fname)

	string   path = "entry:instrument:lenses:focus_type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getLensDistance(string fname)

	string path = "entry:instrument:lenses:lens_distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getLensGeometry(string fname)

	string   path = "entry:instrument:lenses:lens_geometry"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getLensMaterial(string fname)

	string   path = "entry:instrument:lenses:lens_material"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getNumber_of_Lenses(string fname)

	string path = "entry:instrument:lenses:number_of_lenses"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getNumber_of_prisms(string fname)

	string path = "entry:instrument:lenses:number_of_prisms"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getPrism_distance(string fname)

	string path = "entry:instrument:lenses:prism_distance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getPrismMaterial(string fname)

	string   path = "entry:instrument:lenses:prism_material"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// status of lens/prism = lens | prism | both | out
Function/S V_getLensPrismStatus(string fname)

	string   path = "entry:instrument:lenses:status"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

///////  sample_aperture (1) (data folder)
// this is the INTERNAL sample aperture
//
Function/S V_getSampleAp_Description(string fname)

	string   path = "entry:instrument:sample_aperture:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getSampleAp_distance(string fname)

	string path = "entry:instrument:sample_aperture:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

//	shape (data folder)
Function V_getSampleAp_height(string fname)

	string path = "entry:instrument:sample_aperture:shape:height"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getSampleAp_shape(string fname)

	string   path = "entry:instrument:sample_aperture:shape:shape"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// this returns TEXT, due to GUI input, == to diameter if CIRCLE
Function/S V_getSampleAp_size(string fname)

	string   path = "entry:instrument:sample_aperture:shape:size"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getSampleAp_width(string fname)

	string path = "entry:instrument:sample_aperture:shape:width"
	return (V_getRealValueFromHDF5(fname, path))
End

// MAY 2019 SRK
//
// there was a change in the GUI and NICE behavior during the shutdown, before startup
// on 05/22/19 where the units of the sample Ap2 dimensions are changed. supposedly this
// will ensure consistency of all units as [cm]. From what I found in the code, all the units
// were already [cm], so I'm not sure what will happen.
//
// if I flag things here to switch on the date, I can force the output to always be [cm]
// V_Compare_ISO_Dates("2019-05-10T13:36:54.200-04:00",fileDate)
//
// here the first date is a generic date during the shutdown, but before startup.
// fileDate is the actual date of file collection
// if fileDate is more recent (and thus affected by the change), then the function
// will return a value == 2 (2nd date greater) and I can act on that
//
// this change only affects sampleAp2, and this value only affects the resolution calculation
//
//  V_Compare_ISO_Dates("2019-05-10T13:36:54.200-04:00",V_getDataStartTime(fname))
//

///////  sample_aperture_2 (data folder)
// sample aperture (2) is the external aperture, which may or may not be present
Function/S V_getSampleAp2_Description(string fname)

	string   path = "entry:instrument:sample_aperture_2:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getSampleAp2_distance(string fname)

	string path = "entry:instrument:sample_aperture_2:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

//	shape (data folder)
// height and width are reported in [cm]
Function V_getSampleAp2_height(string fname)

	string path = "entry:instrument:sample_aperture_2:shape:height"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getSampleAp2_shape(string fname)

	string   path = "entry:instrument:sample_aperture_2:shape:shape"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//
// this returns REAL, DIFFERENT than SampleAp1
// see the note above. after the hard-coded date, the values in the header
// are values appear to be in [mm]. before that date, the values are in [cm]
//
// This function returns a value in [cm]
//
Function V_getSampleAp2_size(string fname)

	string path = "entry:instrument:sample_aperture_2:shape:size"

	variable val = V_Compare_ISO_Dates("2019-05-10T13:36:54.200-04:00", V_getDataStartTime(fname))

	if(val == 2) // more "current" data, mm in the header
		return (V_getRealValueFromHDF5(fname, path) / 10)
	endif

	// "older" data, cm in the header
	return (V_getRealValueFromHDF5(fname, path))

	//	return(V_getRealValueFromHDF5(fname,path))

End

Function V_getSampleAp2_width(string fname)

	string path = "entry:instrument:sample_aperture_2:shape:width"
	return (V_getRealValueFromHDF5(fname, path))
End

//////  sample_table (data folder)
// location  = "CHAMBER" or HUBER
Function/S V_getSampleTableLocation(string fname)

	string   path = "entry:instrument:sample_table:location"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function V_getSampleTableOffset(string fname)

	string path = "entry:instrument:sample_table:offset_distance"
	return (V_getRealValueFromHDF5(fname, path))
End

//  source (data folder)
//name "NCNR"
Function/S V_getSourceName(string fname)

	string   path = "entry:instrument:source:name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//	power -- nominal only, not connected to any real number
Function V_getReactorPower(string fname)

	string path = "entry:instrument:source:power"
	return (V_getRealValueFromHDF5(fname, path))
End

//probe (wave) "neutron"
Function/S V_getSourceProbe(string fname)

	string   path = "entry:instrument:source:probe"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//type (wave) "Reactor Neutron Source"
Function/S V_getSourceType(string fname)

	string   path = "entry:instrument:source:type"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

///////  source_aperture (data folder)

Function/S V_getSourceAp_Description(string fname)

	string   path = "entry:instrument:source_aperture:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getSourceAp_distance(string fname)

	string path = "entry:instrument:source_aperture:distance"
	return (V_getRealValueFromHDF5(fname, path))
End

//	shape (data folder)
Function V_getSourceAp_height(string fname)

	string path = "entry:instrument:source_aperture:shape:height"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getSourceAp_shape(string fname)

	string   path = "entry:instrument:source_aperture:shape:shape"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// this returns TEXT, due to GUI input, == to diameter if CIRCLE
Function/S V_getSourceAp_size(string fname)

	string   path = "entry:instrument:source_aperture:shape:size"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getSourceAp_width(string fname)

	string path = "entry:instrument:source_aperture:shape:width"
	return (V_getRealValueFromHDF5(fname, path))
End

//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//Sample position in changer (returned as TEXT)
Function/S V_getSamplePosition(string fname)

	string   path = "entry:sample:changer_position"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// sample label
Function/S V_getSampleDescription(string fname)

	string   path = "entry:sample:description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// for a z-stage??
Function V_getSampleElevation(string fname)

	string path = "entry:sample:elevation"
	return (V_getRealValueFromHDF5(fname, path))
End

//no meaning to this...
Function V_getSample_equatorial_ang(string fname)

	string path = "entry:sample:equatorial_angle"
	return (V_getRealValueFromHDF5(fname, path))
End

// group ID !!! very important for matching up files
Function V_getSample_GroupID(string fname)

	string path = "entry:sample:group_id"
	return (V_getRealValueFromHDF5(fname, path))
End

//Sample Rotation Angle
Function V_getSampleRotationAngle(string fname)

	string path = "entry:sample:rotation_angle"
	return (V_getRealValueFromHDF5(fname, path))
End

//?? this is huber/chamber??
// TODO -- then where is the description of 10CB, etc...
Function/S V_getSampleHolderDescription(string fname)

	string   path = "entry:sample:sample_holder_description"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// this field is apparently the "average" temperature reading
// and can be adversely affected by random faulty readings from the sensor
// to give an average that is far from the expected value
Function V_getSampleTemperature(string fname)

	string path = "entry:sample:temperature"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getSampleTempSetPoint(string fname)

	string path = "entry:sample:temperature_setpoint"
	return (V_getRealValueFromHDF5(fname, path))
End

//Sample Thickness
// (DONE) -- somehow, this is not set correctly in the acquisition, so NaN results
// -- this has been corrected in NICE (when??)
Function V_getSampleThickness(string fname)

	string path = "entry:sample:thickness"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getSampleTranslation(string fname)

	string path = "entry:sample:translation"
	return (V_getRealValueFromHDF5(fname, path))
End

// sample transmission
Function V_getSampleTransmission(string fname)

	string path = "entry:sample:transmission"
	return (V_getRealValueFromHDF5(fname, path))
End

//transmission error (one sigma)
Function V_getSampleTransError(string fname)

	string path = "entry:sample:transmission_error"
	return (V_getRealValueFromHDF5(fname, path))
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

Function/S V_getLog_attachedTo(string fname, string logStr)

	string   path = "entry:sample:" + logstr + ":attached_to"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getLog_measurement(string fname, string logStr)

	string   path = "entry:sample:" + logstr + ":measurement"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getLog_Name(string fname, string logStr)

	string   path = "entry:sample:" + logstr + ":name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// for temperature only, logStr = "temperature_env"
Function/S V_getTemp_ControlSensor(string fname, string logStr)

	string   path = "entry:sample:" + logstr + ":control_sensor"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// for temperature only, logStr = "temperature_env"
Function/S V_getTemp_MonitorSensor(string fname, string logStr)

	string   path = "entry:sample:" + logstr + ":monitor_sensor"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
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

Function/S V_getTempLog_attachedTo(string fname, string logStr)

	string   path = "entry:sample:temperature_env:" + logstr + ":attached_to"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getTempLog_highTrip(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":high_trip_value"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_holdTime(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":hold_time"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_lowTrip(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":low_trip_value"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getTempLog_measurement(string fname, string logStr)

	string   path = "entry:sample:temperature_env:" + logstr + ":measurement"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getTempLog_Model(string fname, string logStr)

	string   path = "entry:sample:temperature_env:" + logstr + ":model"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getTempLog_Name(string fname, string logStr)

	string   path = "entry:sample:temperature_env:" + logstr + ":name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getTempLog_runControl(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":run_control"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_Setpoint(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":setpoint"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getTempLog_ShortName(string fname, string logStr)

	string   path = "entry:sample:temperature_env:" + logstr + ":short_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function V_getTempLog_Timeout(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":timeout"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_Tolerance(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":tolerance"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_ToleranceBand(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":tolerance_band_time"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getTempLog_Value(string fname, string logStr)

	string path = "entry:sample:temperature_env:" + logstr + ":value"
	return (V_getRealValueFromHDF5(fname, path))
End

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
Function V_getLog_avgValue(string fname, string logStr)

	string path = "entry:sample:" + logstr + ":value_log:average_value"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getLog_avgValue_err(string fname, string logStr)

	string path = "entry:sample:" + logstr + ":value_log:average_value_error"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getLog_maximumValue(string fname, string logStr)

	string path = "entry:sample:" + logstr + ":value_log:maximum_value"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getLog_medianValue(string fname, string logStr)

	string path = "entry:sample:" + logstr + ":value_log:median_value"
	return (V_getRealValueFromHDF5(fname, path))
End

Function V_getLog_minimumValue(string fname, string logStr)

	string path = "entry:sample:" + logstr + ":value_log:minimum_value"
	return (V_getRealValueFromHDF5(fname, path))
End

// DONE -- this needs to be a WAVE reference
// DONE -- verify that the field is really read in as "time0"
Function V_getLog_timeWave(string fname, string logStr, WAVE outW)

	string path = "entry:sample:" + logstr + ":value_log:time0"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	outW = w
	return (0)
End

// DONE -- this needs to be a WAVE reference
Function V_getLog_ValueWave(string fname, string logStr, WAVE outW)

	string path = "entry:sample:" + logstr + ":value_log:value"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	outW = w
	return (0)
End

///////// REDUCTION
///////// REDUCTION
///////// REDUCTION

Function/WAVE V_getAbsolute_Scaling(string fname)

	string path = "entry:reduction:absolute_scaling"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

Function/S V_getBackgroundFileName(string fname)

	string   path = "entry:reduction:background_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// THIS IS A NON-NICE ENTERED FIELD
// -- this is the panel string where the box coordinates refer to (for the open beam and transmission)
Function/S V_getReduction_BoxPanel(string fname)

	string   path = "entry:reduction:box_panel"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/WAVE V_getBoxCoordinates(string fname)

	string path = "entry:reduction:box_coordinates"
	WAVE   w    = V_getRealWaveFromHDF5(fname, path)

	return w
End

//box counts
Function V_getBoxCounts(string fname)

	string path = "entry:reduction:box_count"
	return (V_getRealValueFromHDF5(fname, path))
End

//box counts error
Function V_getBoxCountsError(string fname)

	string path = "entry:reduction:box_count_error"
	return (V_getRealValueFromHDF5(fname, path))
End

Function/S V_getReductionComments(string fname)

	string   path = "entry:reduction:comments"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getEmptyBeamFileName(string fname)

	string   path = "entry:reduction:empty_beam_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getEmptyFileName(string fname)

	string   path = "entry:reduction:empty_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

// this is purpose is used for all files, and has different meaning
// if polarization is used. need the "intent" also to be able to fully decipher what a file
//  is really being used for. GUI controls this, not me.
Function/S V_getReduction_purpose(string fname)

	string   path = "entry:reduction:file_purpose"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
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

Function/S V_getReduction_intent(string fname)

	string   path = "entry:reduction:intent"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getMaskFileName(string fname)

	string   path = "entry:reduction:mask_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getLogFileName(string fname)

	string   path = "entry:reduction:sans_log_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getSensitivityFileName(string fname)

	string   path = "entry:reduction:sensitivity_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

Function/S V_getTransmissionFileName(string fname)

	string   path = "entry:reduction:transmission_file_name"
	variable num  = 60
	return (V_getStringFromHDF5(fname, path, num))
End

//whole detector trasmission
Function V_getSampleTransWholeDetector(string fname)

	string path = "entry:reduction:whole_trans"
	return (V_getRealValueFromHDF5(fname, path))
End

//whole detector trasmission error
Function V_getSampleTransWholeDetErr(string fname)

	string path = "entry:reduction:whole_trans_error"
	return (V_getRealValueFromHDF5(fname, path))
End

// this is a NON NICE entered field
// so I need to catch the error if it's not there
Function/WAVE V_getReductionProtocolWave(string fname)

	string   path = "entry:reduction:protocol"
	WAVE/Z/T tw   = V_getTextWaveFromHDF5(fname, path)

	if(waveExists(tw))
		return tw
	endif

	Make/O/T/N=0 nullTextWave
	return nullTextWave

End

// this is a NON NICE entered field
// so if it's not there, it returns -999999
//
// this is a flag to mark the file as "flipped" so it prevents a 2nd flip
// if the flip has been done, the field is written with a value of 1 (= true)
//
Function V_getLeftRightFlipDone(string fname)

	string path = "entry:reduction:left_right_flip"
	return (V_getRealValueFromHDF5(fname, path))
End

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
////  -- this will need to be completely replaced with a function that can
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

