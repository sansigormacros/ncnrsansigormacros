#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// Jan 2022
//
// These are the write functions corresponding to the current (simulated) Nexus file
// for the 10m SANS. The R/W format has been duplicated from VSANS.

//
// There are a few missing fields (as of Jan 2022):
//
// - instrument/sample_aperture/shape/size  	(exists, should be a text field, currently NULL)
// - instrument/detector/event_file_name		(does not exist)
// - entry/sample/temperature						(does not exist)

//	-- the whole temperature block
//
//
// some of these mising fields may be a limitation of the simulation.
//
//

//////////// WRITE FUNCTIONS ////////////////////
//
// Each of the individual write functions have both the "write" and "kill" function
// calls explicitly in each named function to allow flexibility during real implementation.
// The calls could be streamlined, but writing this way allows for individualized kill/nokill, depending
// on the details of what is actually being written out, and the possibility of changing the
// particular "Write" routine, if specific changes need to be made to match the data type (int, fp, etc).
// Currently, I don't know all of the data types, or what is important in the HDF structure.
// NOV 2015
//
// NOTE: the "kill" after each write has been commented out because it is WAY too slow. It is easier
// to recommend that the user refreshes the file catalog, or force a refresh by doing a stale file
// cleanup whenever the experiment is saved. Not foolproof, but it works well enough.

//
// For some "WRITE" functions there are corresponding "PUT" functions.
// The purpose of these functions is to "put" a value into a local WORK folder rather than
// write some value permanently to the raw data file. This is meant for values that are used
// during reduction, but are not necessary (or good) to save to the file.
//
//

//////////////////////////////////////////////
//////////////////////////////////
// for TESTING of the get functions - to quickly access and see if there are errors
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
Function proto_write_FP(string str)

	return (0)
End

Function proto_write_FP2(string str, string str2)

	return (0)
End
//Function proto_write_STR(str)
//	String str
//	return("")
//end

Function Test_write_FP(string str, string fname)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_write_FP f = $item
		Print item, " = ", f(fname)
	endfor

	return (0)
End

Function Test_write_FP2(string str, string fname, string detStr)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_write_FP2 f = $item
		Print item, " = ", f(fname, detStr)
	endfor

	return (0)
End

Function Test_write_STR(string str, string fname)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_write_STR f = $item
		printf "%s = ", item
		sprintf strToEx, "Print %s(\"%s\")", item, fname
		Execute strToEx
		//		print strToEx
		//		Print item ," = ", f(fname)
	endfor

	return (0)
End

Function Test_write_STR2(string str, string fname, string detStr)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_write_STR f = $item
		printf "%s = ", item
		sprintf strToEx, "Print %s(\"%s\",\"%s\")", item, fname, detStr
		Execute strToEx
		//		print strToEx
		//		Print item ," = ", f(fname)
	endfor

	return (0)
End
///////////////////////////////////////

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
// (DONE) -- for all of the String functions -- "num" does nothing right now -
//         -- if it ever does, or needs to, a lot of locations will need to be corrected
//

///// TOP LEVEL (ENTRY)
///// TOP LEVEL (ENTRY)
///// TOP LEVEL (ENTRY)

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function writeCollectionTime(string fname, variable val)

	//	String path = "entry:collection_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry"
	string varName   = "collection_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putCollectionTime(string fname, variable val)

	//root:Packages:NIST:RAW:entry:control:count_time
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:control:count_time"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// data directory where data files are stored (for user access, not archive)
Function writeData_directory(string fname, string str)

	//	String path = "entry:data_directory"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "data_directory"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// Base class of Nexus definition (=NXsas)
Function writeNexusDefinition(string fname, string str)

	//	String path = "entry:definition"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "definition"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function writeDataDuration(string fname, variable val)

	string path = "entry:duration"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry"
	string varName   = "duration"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection end time
Function writeDataEndTime(string fname, string str)

	//	String path = "entry:end_time"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "end_time"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// experiment description
Function writeExperiment_description(string fname, string str)

	//	String path = "entry:experiment_description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "experiment_description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// experiment identifier? used only by NICE?
Function writeExperiment_identifier(string fname, string str)

	//	String path = "entry:experiment_identifier"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "experiment_identifier"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// name of facility = NCNR
Function writeFacility(string fname, string str)

	//	String path = "entry:facility"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "facility"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//
Function write_facility(string fname, string str)

	//	String path = "entry:hdf_version"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "facility"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
Function writeProgram_name(string fname, string str)

	//	String path = "entry:program_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "program_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection start time
Function writeDataStartTime(string fname, string str)

	//	String path = "entry:start_time"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "start_time"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// title of experiment
Function writeTitle(string fname, string str)

	//	String path = "entry:title"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "title"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// CONTROL
//////// CONTROL
//////// CONTROL

// (DONE) -- for the control section, document each of the fields
//
Function writeCount_end(string fname, string str)

	//	String path = "entry:control:count_end"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "count_end"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeCount_start(string fname, string str)

	//	String path = "entry:control:count_start"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "count_start"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeCount_time(string fname, variable val)

	//	String path = "entry:control:count_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "count_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putCount_time(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:control:count_time"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeCount_time_preset(string fname, variable val)

	//	String path = "entry:control:count_time_preset"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "count_time_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeDetector_counts(string fname, variable val)

	//	String path = "entry:control:detector_counts"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "detector_counts"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDetector_counts(string fname, variable val)

	//root:Packages:NIST:RAW:entry:control:detector_counts
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:control:detector_counts"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeDetector_preset(string fname, variable val)

	//	String path = "entry:control:detector_preset"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "detector_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function write_efficiency(string fname, variable val)

	//	String path = "entry:control:integral"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// control mode for data acquisition, "timer"
Function writeControlMode(string fname, string str)

	//	String path = "entry:control:mode"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "mode"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//monitor count
// integer value
Function writeControlMonitorCount(string fname, variable val)

	//	String path = "entry:control:monitor_counts"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "monitor_counts"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putControlMonitorCount(string fname, variable val)

	//root:Packages:NIST:RAW:entry:control:monitor_counts
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:control:monitor_counts"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//integer value
Function writeControlMonitor_preset(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "monitor_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// ?? sampled fraction of the monitor
Function writeControl_sampled_fraction(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "sampled_fraction"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// DATA
//////// DATA
//////// DATA

// THIS IS NOT THE MAIN DETECTOR BLOCK!
// This is a nexus-compliant block. I did not add this, and I don't
// expect to use this much , but it is here to be complete

//  copy of the data array
Function writeData_areaDetector(string fname, WAVE inW)

	Duplicate/O inW, wTmpWrite
	//
	string groupName = "/entry/dat"
	string varName   = "y0"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeData_configuration(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/data"
	string varName   = "configuration"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeData_sample_description(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/data"
	string varName   = "sample_description"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeData_sample_thickness(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/data"
	string varName   = "sample_thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeData_slotIndex(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/data"
	string varName   = "slotIndex"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeData_x0(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/data"
	string varName   = "x0"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// table of y-coordinates of the data array?
Function writeData_y0(string fname, WAVE inW)

	Duplicate/O inW, wTmpWrite
	//
	string groupName = "/entry/dat"
	string varName   = "y0"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

// there are a few fields at the top level of INSTRUMENT
// but most fields are in separate blocks
//

Function writeLocalContact(string fname, string str)

	//	String path = "entry:instrument:local_contact"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "local_contact"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeInstrumentName(string fname, string str)

	//	String path = "entry:instrument:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeInstrumentType(string fname, string str)

	//	String path = "entry:instrument:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////// INSTRUMENT/ATTENUATOR
////// INSTRUMENT/ATTENUATOR
////// INSTRUMENT/ATTENUATOR

// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function writeAttenuator_transmission(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "attenuator_transmission"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function writeAttenuator_trans_err(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "attenuator_transmission_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// desired thickness of attenuation
Function writeAttenuator_desiredThick(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "desired_thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// distance from the attenuator to the sample (units??)
Function writeAttenDistance(string fname, variable val)

	//	String path = "entry:instrument:attenuator:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// table of the attenuation factor error
Function writeAttenIndex_table_err(string fname, WAVE inW)

	//	String path = "entry:instrument:attenuator:index_table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/attenuator"
	string varName   = "index_error_table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// table of the attenuation factor
Function writeAttenIndex_table(string fname, WAVE inW)

	//	String path = "entry:instrument:attenuator:index_table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/attenuator"
	string varName   = "index_table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// number of attenuators actually dropped in
//// an integer value
Function writeAtten_num_dropped(string fname, variable val)

	//	String path = "entry:instrument:attenuator:thickness"

	Make/O/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "num_atten_dropped"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// thickness of the attenuator (PMMA) - units??
Function writeAttenThickness(string fname, variable val)

	//	String path = "entry:instrument:attenuator:thickness"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// type of material for the atteunator
Function writeAttenType(string fname, string str)

	//	String path = "entry:instrument:attenuator:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/attenuator" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// INSTRUMENT/BEAM_MONITOR_NORM
//////// INSTRUMENT/BEAM_MONITOR_NORM
//////// INSTRUMENT/BEAM_MONITOR_NORM

Function writeBeamMonNorm_data(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:data"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "data"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putBeamMonNorm_data(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:beam_monitor_norm:data"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeBeamMonNormDistance(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeBeamMonNormEfficiency(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:efficiency"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeBeamMonNormSaved_count(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:saved_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "saved_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putBeamMonNormSaved_count(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:beam_monitor_norm:saved_count"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeBeamMonNormType(string fname, string str)

	//	String path = "entry:instrument:beam_monitor_norm:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_monitor_norm" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// INSTRUMENT/BEAM_STOP
//////// INSTRUMENT/BEAM_STOP
//////// INSTRUMENT/BEAM_STOP

Function writeBeamStop_description(string fname, string str)

	//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop" //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeBeamStop_Dist_to_det(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:distance_to_detector"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop"
	string varName   = "distance_to_detector"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeBeamStop_x_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:x0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop"
	string varName   = "x_pos"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// DONT DELETE THIS - it is new and needed
//
Function putBeamStop_x_pos(string fname, variable val)

	string path = "root:Packages:" + fname + ":"
	path += "entry:instrument:beam_stop:x_pos"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeBeamStop_y_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop"
	string varName   = "y_pos"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// beam stop/shape

Function writeBeamStop_height(string fname, variable val)

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeBeamStop_shape(string fname, string str)

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop/shape" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// this is diameter if shape=CIRCLE
Function writeBeamStop_size(string fname, variable val)

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// size in [cm]
Function putBeamStop_size(string fname, variable val)

	string path = "root:Packages:" + fname + ":"
	path += "entry:instrument:beam_stop:shape:size"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeBeamStop_width(string fname, variable val)

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT/COLLIMATOR
//////// INSTRUMENT/COLLIMATOR
//////// INSTRUMENT/COLLIMATOR

//collimator (data folder) -- this is a TEXT field
Function writeNumberOfGuides(string fname, string str)

	//	String path = "entry:instrument:collimator:number_guides"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/collimator"
	string varName   = "number_guides"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//				geometry (data folder)
//					shape (data folder)
Function writeGuideShape(string fname, string str)

	//	String path = "entry:instrument:collimator:geometry:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/collimator/geometry/shape" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- this may need to be a wave to properly describe the dimensions
Function writeGuideSize(string fname, variable val)

	//	String path = "entry:instrument:collimator:geometry:shape:size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/collimator/geometry/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT/DETECTOR
//////// INSTRUMENT/DETECTOR
//////// INSTRUMENT/DETECTOR

Function writeDet_azimuthalAngle(string fname, variable val)

	//		String path = "entry:instrument:detector:azimuthal_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "azimuthal_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

// these are values in PIXELS
Function writeDet_beam_center_x(string fname, variable val)

	//	String path = "entry:instrument:detector:beam_center_x"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "beam_center_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_x(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_x"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// these are values in mm
// fname is a local WORK folder
Function putDet_beam_center_x_mm(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_x_mm"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_x_pix(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x_pix
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_x_pix"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// these are values in PIXELS
Function writeDet_beam_center_y(string fname, variable val)

	//	String path = "entry:instrument:detector:beam_center_y"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "beam_center_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_y(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_y"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// these are values in mm
// fname is a local WORK folder
Function putDet_beam_center_y_mm(string fname, variable val)

	//root:Packages:NIST:RAW:entry:instrument:detector:beam_center_y
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_y_mm"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_y_pix(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y_pix
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:beam_center_y_pix"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// replaces the detector data in the LOCAL folder, not on disk
Function putDetectorData(string fname, WAVE inW)

	//root:Packages:NIST:RAW:entry:instrument:detector:data
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:data"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w = inW
	return (0)

End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetectorData(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:data"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "data"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// replaces the detector data error in the LOCAL folder, not on disk
Function putDetectorData_error(string fname, WAVE inW)

	//root:Packages:NIST:RAW:entry:instrument:detector:data_error
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:data_error"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w = inW
	return (0)

End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetectorData_error(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:data"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "data_error"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetectorData_Lin_error(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:data"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "linear_data_error"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter

//  the tube banks will be 1D arrays of values, one per tube
Function writeDetector_deadtime(string fname, WAVE inW)

	//	String path = "entry:instrument:detector_"+detStr+":dead_time"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "dead_time"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)

End

Function writeDetDescription(string fname, string str)

	//	String path = "entry:instrument:detector:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector" //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// header stores value in [cm]
// patch panel is asking for value in [m] - so be sure to pass SDD [cm] to this function!
//
Function writeDet_distance(string fname, variable val)

	//	String path = "entry:instrument:detector:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDet_distance(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:distance"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeDet_IntegratedCount(string fname, variable val)

	//	String path = "entry:instrument:detector:integrated_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "integrated_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDet_IntegratedCount(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:integrated_count"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// this is only written for B and L/R detectors
Function writeDet_LateralOffset(string fname, variable val)

	//	String path = "entry:instrument:detector:lateral_offset"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "lateral_offset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDet_LateralOffset(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:lateral_offset"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// integer value
Function writeDet_numberOfTubes(string fname, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "number_of_tubes"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)
End

// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function writeDet_pixel_fwhm_x(string fname, variable val)

	//	String path = "entry:instrument:detector:pixel_fwhm_x"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "pixel_fwhm_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function writeDet_pixel_fwhm_y(string fname, variable val)

	//	String path = "entry:instrument:detector:pixel_fwhm_y"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "pixel_fwhm_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function writeDet_pixel_num_x(string fname, variable val)

	//	String path = "entry:instrument:detector:pixel_nnum_x"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "pixel_num_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDet_pixel_num_x(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:pixel_num_x"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// integer value
Function writeDet_pixel_num_y(string fname, variable val)

	//	String path = "entry:instrument:detector:pixel_num_y"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "pixel_num_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putDet_pixel_num_y(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:detector:pixel_num_y"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeDet_polar_angle(string fname, variable val)

	//		String path = "entry:instrument:detector:polar_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "polar_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

Function writeDet_rotational_angle(string fname, variable val)

	//		String path = "entry:instrument:detector:rotational_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "rotational_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

Function writeDetSettings(string fname, string str)

	//	String path = "entry:instrument:detector:settings"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector" //
	string varName   = "settings"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetTube_spatialCalib(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:spatial_calibration"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "spatial_calibration"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

// (DONE) -- be clear on how this is defined. Units?
Function writeDet_tubeWidth(string fname, variable val)

	//	String path = "entry:instrument:detector:tube_width"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "tube_width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
//
// this is nothing that I use -- I use the tube width and spatial calibration
Function writeDetTube_xOffset(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:x_offset"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "x_offset"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

Function writeDet_x_pixel_size(string fname, variable val)

	//	String path = "entry:instrument:detector:x_pixel_size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "x_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
//
// this is nothing that I use -- I use the tube width and spatial calibration
Function writeDetTube_yOffset(string fname, WAVE inW)

	//	String path = "entry:instrument:detector:y_offset"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector"
	string varName   = "y_offset"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)

End

Function writeDet_y_pixel_size(string fname, variable val)

	//	String path = "entry:instrument:detector:y_pixel_size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector"
	string varName   = "y_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeDetEventFileName(string fname, string str)

	//	String path = "entry:instrument:event_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "event_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// INSTRUMENT/LENSES
//////// INSTRUMENT/LENSES
//////// INSTRUMENT/LENSES

Function writeLensCurvature(string fname, variable val)

	//	String path = "entry:instrument:lenses:curvature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "curvature"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLensesFocusType(string fname, string str)

	//	String path = "entry:instrument:lenses:focus_type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "focus_type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeLensDistance(string fname, variable val)

	//	String path = "entry:instrument:lenses:lens_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLensGeometry(string fname, string str)

	//	String path = "entry:instrument:lenses:lens_geometry"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_geometry"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeLensMaterial(string fname, string str)

	//	String path = "entry:instrument:lenses:lens_material"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_material"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// integer value
Function writeNumber_of_Lenses(string fname, variable val)

	//	String path = "entry:instrument:lenses:number_of_lenses"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "number_of_lenses"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function writeNumber_of_prisms(string fname, variable val)

	//	String path = "entry:instrument:lenses:number_of_prisms"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "number_of_prisms"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writePrism_distance(string fname, variable val)

	//	String path = "entry:instrument:lenses:prism_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "prism_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writePrismMaterial(string fname, string str)

	//	String path = "entry:instrument:lenses:prism_material"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "prism_material"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// status of lens/prism = lens | prism | both | out
Function writeLensPrismStatus(string fname, string str)

	//	String path = "entry:instrument:lenses:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// INSTRUMENT/MONOCHROMATOR
//////// INSTRUMENT/MONOCHROMATOR
//////// INSTRUMENT/MONOCHROMATOR

// instrument/monochromator (data folder)
Function writeMonochromatorType(string fname, string str)

	//	String path = "entry:instrument:monochromator:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/monochromator" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeWavelength(string fname, variable val)

	//	String path = "entry:instrument:monochromator:wavelength"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/monochromator"
	string varName   = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putWavelength(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:monochromator:wavelength"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeWavelength_spread(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:wavelength_spread"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/monochromator"
	string varName   = "wavelength_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putWavelength_spread(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:instrument:monochromator:wavelength_error"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

////////////
// instrument/beam/monochromator/velocity_selector (data folder)
Function writeVSDistance(string fname, variable val)

	//	String path = "entry:instrument:monochromator:velocity_selector:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/monochromator/velocity_selector"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeVSRotation_speed(string fname, variable val)

	//	String path = "entry:instrument:monochromator:velocity_selector:rotation_speed"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/monochromator/velocity_selector"
	string varName   = "rotation_speed"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// not sure what this value actually means...
Function writeVS_table(string fname, WAVE inW)

	//	String path = "entry:instrument:monochromator:velocity_selector:table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/monochromator/velocity_selector"
	string varName   = "table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT/SAMPLE_APERTURE
//////// INSTRUMENT/SAMPLE_APERTURE
//////// INSTRUMENT/SAMPLE_APERTURE

Function writeSampleAp_Description(string fname, string str)

	//	String path = "entry:instrument:sample_aperture:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeSampleAp_distance(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//	sample_aperture/shape (data folder)
Function writeSampleAp_height(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeSampleAp_shape(string fname, string str)

	//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// in the Nexus files, this field is now a real FP value, not a string
Function writeSampleAp_size(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "size"
	wTmpWrite[0] = val //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// fname is a local WORK folder
Function putSampleAp_size(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:sample_aperture:shape:size"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function writeSampleAp_width(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT/SAMPLE_TABLE
//////// INSTRUMENT/SAMPLE_TABLE
//////// INSTRUMENT/SAMPLE_TABLE

// location  = "CHAMBER" or HUBER
Function writeSampleTableLocation(string fname, string str)

	//	String path = "entry:instrument:sample_table:location"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_table"
	string varName   = "location"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function writeSampleTableOffset(string fname, variable val)

	//	String path = "entry:instrument:sample_table:offset_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_table"
	string varName   = "offset_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT/SOURCE
//////// INSTRUMENT/SOURCE
//////// INSTRUMENT/SOURCE

//name "NCNR"
Function writeSourceName(string fname, string str)

	//	String path = "entry:instrument:source:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//	power -- nominal only, not connected to any real number
Function writeReactorPower(string fname, variable val)

	//	String path = "entry:instrument:source:power"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source"
	string varName   = "power"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//probe (wave) "neutron"
Function writeSourceProbe(string fname, string str)

	//	String path = "entry:instrument:source:probe"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "probe"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//type (wave) "Reactor Neutron Source"
Function writeSourceType(string fname, string str)

	//	String path = "entry:instrument:source:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// INSTRUMENT/SOURCE_APERTURE
//////// INSTRUMENT/SOURCE_APERTURE
//////// INSTRUMENT/SOURCE_APERTURE

Function writeSourceAp_Description(string fname, string str)

	//	String path = "entry:instrument:source_aperture:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// units of [cm]
Function writeSourceAp_distance(string fname, variable val)

	//	String path = "entry:instrument:source_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putSourceAp_distance(string fname, variable val)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:source_aperture:distance"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//	shape (data folder)
Function writeSourceAp_height(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeSourceAp_shape(string fname, string str)

	//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeSourceAp_size(string fname, string str)

	//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "size"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// fname is a local WORK folder
Function putSourceAp_size(string fname, string str)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:source_aperture:shape:size"

	WAVE/Z/T w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = str
	return (0)

End

Function writeSourceAp_width(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// ENTRY/PROGRAM_DATA
//////// ENTRY/PROGRAM_DATA
//////// ENTRY/PROGRAM_DATA

Function write_ProgramData_data(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/program_data" //
	string varName   = "data"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function write_ProgramData_description(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/program_data" //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function write_ProgramData_fileName(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/program_data" //
	string varName   = "file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function write_ProgramData_type(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/program_data" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//////// ENTRY/REDUCTION
//////// ENTRY/REDUCTION
//////// ENTRY/REDUCTION

// TODO -- needs to be a WAVE, and of the proper size and type!!!
Function writeAbsolute_Scaling(string fname, WAVE inW)

	//	String path = "entry:reduction:absolute_scaling"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "absolute_scaling"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeBackgroundFileName(string fname, string str)

	//	String path = "entry:reduction:background_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "background_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- needs to be a WAVE
Function writeBoxCoordinates(string fname, WAVE inW)

	//	String path = "entry:reduction:box_coordinates"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "box_coordinates"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//box counts
Function writeBoxCounts(string fname, variable val)

	//	String path = "entry:reduction:box_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "box_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//box counts error
Function writeBoxCountsError(string fname, variable val)

	//	String path = "entry:reduction:box_count_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "box_count_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeReductionComments(string fname, string str)

	//	String path = "entry:reduction:comments"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "comments"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeEmptyBeamFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "empty_beam_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeEmptyFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "empty_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeReduction_purpose(string fname, string str)

	//	String path = "entry:reduction:file_purpose"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "file_purpose"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeReductionIntent(string fname, string str)

	//	String path = "entry:reduction:intent"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "intent"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeMaskFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "mask_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeLogFileName(string fname, string str)

	//	String path = "entry:reduction:sans_log_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "sans_log_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeSensitivityFileName(string fname, string str)

	//	String path = "entry:reduction:sensitivity_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "sensitivity_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTransmissionFileName(string fname, string str)

	//	String path = "entry:reduction:transmission_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "transmission_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//whole detector transmission
Function writeSampleTransWholeDetector(string fname, variable val)

	//	String path = "entry:reduction:whole_trans"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "whole_trans"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//whole detector transmission error
Function writeSampleTransWholeDetErr(string fname, variable val)

	//	String path = "entry:reduction:whole_trans_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "whole_trans_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO
// -- come up with a scheme to write the entire protocol to the data file?
// -- or a scheme to write just the missing bits?

// TODO -- needs to be a Text WAVE, and of the proper size and type!!!
//  -- this is a test where I write a wave to a field that does not exist...
Function writeReductionProtocolWave(string fname, WAVE/T inTW)

	//	String path = "entry:reduction:absolute_scaling"

	Duplicate/O inTW, wTTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "protocol"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

///// This is an added field, not part of the Nexus definition
//
// this is the associated file for transmission calculation
//
Function writeAssocFileSuffix(string fname, string str)

	//	String path = "entry:reduction:assoc_file_suffix"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "assoc_file_suffix"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// fname is a local WORK folder
// be sure to generate this if it does not exist since it is not part of the nexus definition
Function putAssocFileSuffix(string fname, string str)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:reduction:assoc_file_suffix"

	WAVE/Z/T w = $path
	if(waveExists(w) == 0)
		Make/O/T/N=1 $path
		WAVE/Z/T tw = $path
		tw[0] = str
		return (1)
	endif

	w[0] = str
	return (0)

End

//////// ENTRY/SAMPLE
//////// ENTRY/SAMPLE
//////// ENTRY/SAMPLE

//no meaning to this field for our instrument
Function writeSample_equatorial_ang(string fname, variable val)

	//	String path = "entry:sample:equatorial_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "aequatorial_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeSample_changer(string fname, string str)

	//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "changer"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//Sample position in changer
Function writeSamplePosition(string fname, string str)

	//	String path = "entry:sample:changer_position"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "changer_position"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// sample label
// (DONE): value of num is currently not used
Function writeSampleDescription(string fname, string str)

	//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// fname is a local WORK folder
Function putSampleDescription(string fname, string str)

	string path = "root:Packages:NIST:" + fname + ":"
	path += "entry:sample:description"

	WAVE/Z/T w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = str
	return (0)

End

// for a z-stage??
Function writeSample_elevation(string fname, variable val)

	//	String path = "entry:sample:elevation"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "elevation"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//
// (DONE) x- I need to make sure that this is an integer in the JSON definition
// 		x- currently a text value in the data file - see trac ticket
// x- this is also a duplicated field in the reduction block (reduction/group_id is no longer used)
//
// group ID !!! very important for matching up files
// integer value
//
Function writeSample_GroupID(string fname, variable val)

	//	String path = "entry:sample:group_id"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "group_id"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeSample_mass(string fname, variable val)

	//	String path = "entry:sample:group_id"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "mass"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeSample_name(string fname, string str)

	//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//Sample Rotation Angle
Function writeSampleRotationAngle(string fname, variable val)

	//	String path = "entry:sample:rotation_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "rotation_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//?? this is huber/chamber??
// (DONE) -- then where is the description of 10CB, etc...
Function writeSampleHolderDescription(string fname, string str)

	//	String path = "entry:sample:sample_holder_description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "sample_holder_description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//Sample Temperature
Function writeSampleTemperature(string fname, variable val)

	//	String path = "entry:sample:temperature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "temperature"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Temperature set point
Function writeSampleTempSetPoint(string fname, variable val)

	//	String path = "entry:sample:temperature_setpoint"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "temperature_setpoint"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Thickness
// (DONE) -- somehow, this is not set correctly in the acquisition, so NaN results
Function writeSampleThickness(string fname, variable val)

	//	String path = "entry:sample:thickness"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putSampleThickness(string fname, variable val)

	string path = "root:Packages:" + fname + ":"
	path += "entry:sample:thickness"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//Sample Translation
Function writeSampleTranslation(string fname, variable val)

	//	String path = "entry:sample:translation"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "translation"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// sample transmission
Function writeSampleTransmission(string fname, variable val)

	string path = "entry:sample:transmission"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "transmission"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function putSampleTransmission(string fname, variable val)

	string path = "root:Packages:" + fname + ":"
	path += "entry:sample:transmission"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//transmission error (one sigma)
Function writeSampleTransError(string fname, variable val)

	//	String path = "entry:sample:transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "transmission_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

////////// ENTRY/USER
////////// ENTRY/USER
////////// ENTRY/USER

// list of user names
// DONE -- currently not written out to data file??
Function writeUserNames(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/user" //
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//
// These data logs are not currently part of the SANS Nexus files (Jan 2022)
//

// the temperature logs are expected to be part of the Nexus file, but it is not clear
// how they are written out (not part of config.js) and they do not appear to be
// easily simulated for testing. (Jan 2022)
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

Function writeLog_attachedTo(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "attached_to"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeLog_measurement(string fname, string logStr, string str)

	string path = "entry:sample:" + logstr + ":measurement"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "measurement"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeLog_Name(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//// TODO -- this may require multiple entries, for each sensor _1, _2, etc.
//Function writeLog_setPoint(fname,logStr,val)
//	String fname,logStr
//	Variable val
//
////	String path = "entry:sample:"+logstr+":setpoint_1"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/sample/"+logStr
//	String varName = "setpoint_1"
//	wTmpWrite[0] = val
//
//	variable err
//	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function writeLog_startTime(fname,logStr,str)
//	String fname,logStr,str
//
////	String path = "entry:sample:"+logstr+":start"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/sample/"+logStr
//	String varName = "start"
//	tmpTW[0] = str //
//
//	variable err
//	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//
//// TODO -- this may only exist for electric and magnetic field, or be removed
//Function writeLog_nomValue(fname,logStr,val)
//	String fname,logStr
//	Variable val
//
////	String path = "entry:sample:"+logstr+":value"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/sample/"+logStr
//	String varName = "value"
//	wTmpWrite[0] = val
//
//	variable err
//	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end

// for temperature only, logStr must be "temperature_env"
Function writeTempLog_ControlSensor(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":control_sensor"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "control_sensor"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// for temperature only, logStr must be "temperature_env"
Function writeTempLog_MonitorSensor(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":monitor_sensor"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "monitor_sensor"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////////////////////
//
///////////
// NOTE
//
// for temperature, the "attached_to", "measurement", and "name" fields
// are one level down farther than before, and down deeper than for other sensors
//
//
// read the value of getTemp_MonitorSensor/ControlSensor to get the name of the sensor level .
//

Function writeTempLog_attachedTo(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "attached_to"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTempLog_highTrip(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":high_trip_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "high_trip_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_holdTime(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":hold_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "hold_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_lowTrip(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":low_trip_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "low_trip_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_measurement(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":measurement"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "measurement"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTempLog_model(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":model"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "model"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTempLog_name(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTempLog_runControl(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":run_control"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "run_control"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_setPoint(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":setpoint"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "setpoint"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_shortName(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":short_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "short_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function writeTempLog_timeout(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":timeout"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "timeout"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_tolerance(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":tolerance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "tolerance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_toleranceBand(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":tolerance_band_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "tolerance_band_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeTempLog_Value(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
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
// read the value of getTemp_MonitorSensor to get the name of the sensor the next level down.
//
//
/////////////////////////////////////
////		value_log (data folder)
//
// (DONE) --
Function writeLog_avgValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:average_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "average_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLog_avgValue_err(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:average_value_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "average_value_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLog_maximumValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:maximum_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "maximum_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLog_medianValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:median_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "median_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function writeLog_minimumValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:minimum_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "minimum_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO -- this needs to be a WAVE reference
// be sure this gets written as "time", even though it is read in as "time0"
Function writeLog_timeWave(string fname, string logStr, WAVE inW)

	//	String path = "entry:sample:"+logstr+":value_log:time"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "time"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO -- this needs to be a WAVE reference
Function writeLog_ValueWave(string fname, string logStr, WAVE inW)

	//	String path = "entry:sample:"+logstr+":value_log:value"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "value"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//
// polarized beam functions added for NG7 SANS
//
// -- as of 3/2023
// (locations may change in the future...)
//
// ** NOTE: more is needed to include the cell information for the back polarizer (analyzer)
// -- see VSANS cor how this is handled...

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:He3BackPolarizer:type (var)
//
Function write_He3BackPolarizer_type(string fname, variable val)

	//	String path = "entry:instrument:He3BackPolarizer:type"
	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/He3BackPolarizer"
	string varName   = "type"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:He3FrontPolarizer:type (var)
//
Function write_He3FrontPolarizer_type(string fname, variable val)

	//	String path = "entry:instrument:He3FrontPolarizer:type"
	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/He3FrontPolarizer"
	string varName   = "type"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:direction (text)
//
Function write_rfFrontFlipper_direction(string fname, string str)

	//	String path = "entry:instrument:rfFrontFlipper:direction"
	Make/O/T/N=1 tmpTW
	string groupName = "/instrument/rfFrontFlipper" //
	string varName   = "direction"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:flip (text)
//
Function write_rfFrontFlipper_flip(string fname, string str)

	//	String path = "entry:instrument:rfFrontFlipper:flip"
	Make/O/T/N=1 tmpTW
	string groupName = "/instrument/rfFrontFlipper" //
	string varName   = "flip"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:transmitted_power (var)
//
Function write_rfFrontFlipper_transmitted_power(string fname, variable val)

	//	String path = "entry:instrument:rfFrontFlipper:transmitted_power"
	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/rfFrontFlipper"
	string varName   = "transmitted_power"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:rfFrontFlipper:type (text)
//
Function write_rfFrontFlipper_type(string fname, string str)

	//	String path = "entry:instrument:rfFrontFlipper:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/instrument/rfFrontFlipper" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//
// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:composition (text)
//
Function write_superMirror_composition(string fname, string str)

	//	String path = "entry:instrument:superMirror:composition"
	Make/O/T/N=1 tmpTW
	string groupName = "/instrument/superMirror" //
	string varName   = "composition"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:efficiency (var)
//
Function write_superMirror_efficiency(string fname, variable val)

	//	String path = "entry:instrument:superMirror:efficiency"
	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/superMirror"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// root:Packages:NIST:RawSANS:sans118664:entry:instrument:superMirror:type (text)
//
Function write_superMirror_type(string fname, string str)

	//	String path = "entry:instrument:superMirror:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/instrument/superMirror" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////////////////////////////////

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
//// (DONE) -- this will need to be completely replaced with a function that can
//// read the binary image data. should be possible, but I don't know the details on either end...
//Function writeDataImage(fname,detStr,str)
//	String fname,detStr,str
//
////	String path = "entry:data_"+detStr+":thumbnail:data"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/data_"+detStr+"/thumbnail"
//	String varName = "data"
//	tmpTW[0] = str //
//
//	variable err
//	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function writeDataImageDescription(fname,detStr,str)
//	String fname,detStr,str
//
////	String path = "entry:data_"+detStr+":thumbnail:description"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/data_"+detStr+"/thumbnail"
//	String varName = "description"
//	tmpTW[0] = str //
//
//	variable err
//	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function writeDataImageType(fname,detStr,str)
//	String fname,detStr,str
//
////	String path = "entry:data_"+detStr+":thumbnail:type"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/data_"+detStr+"/thumbnail"
//	String varName = "type"
//	tmpTW[0] = str //
//
//	variable err
//	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//

