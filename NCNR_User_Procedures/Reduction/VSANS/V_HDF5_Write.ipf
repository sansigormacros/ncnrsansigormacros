#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// Start to build up and test the r/w accessors for VSANS
// (SANS has a template, VSANS does not, so just start from scratch here, since the
// file structure will be different)
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
Function proto_V_write_FP(string str)

	return (0)
End
Function proto_V_write_FP2(string str, string str2)

	return (0)
End
//Function proto_V_write_STR(str)
//	String str
//	return("")
//end

Function Test_V_write_FP(string str, string fname)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_V_write_FP f = $item
		Print item, " = ", f(fname)
	endfor

	return (0)
End

Function Test_V_write_FP2(string str, string fname, string detStr)

	variable ii, num
	string list, item

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		FUNCREF proto_V_write_FP2 f = $item
		Print item, " = ", f(fname, detStr)
	endfor

	return (0)
End

Function Test_V_write_STR(string str, string fname)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:1,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_V_write_STR f = $item
		printf "%s = ", item
		sprintf strToEx, "Print %s(\"%s\")", item, fname
		Execute strToEx
		//		print strToEx
		//		Print item ," = ", f(fname)
	endfor

	return (0)
End

Function Test_V_write_STR2(string str, string fname, string detStr)

	variable ii, num
	string list, item, strToEx

	list = FunctionList(str, ";", "NPARAMS:2,VALTYPE:4")
	//	Print list
	num = ItemsInlist(list)

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")
		//	FUNCREF proto_V_write_STR f = $item
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
// (DONE) -- for all of the String functions -- "num" does nothing right now -
//         -- if it ever does, or needs to, a lot of locations will need to be corrected
//

//////// TOP LEVEL
//////// TOP LEVEL
//////// TOP LEVEL

//// nexus version used for definitions
//Function V_writeNeXus_version(fname,str)
//	String fname,str
//
////	String path = "entry:NeXus_version"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry"	//
//	String varName = "NeXus_version"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function V_writeCollectionTime(string fname, variable val)

	//	String path = "entry:collection_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry"
	string varName   = "collection_time"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putCollectionTime(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:collection_time"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// data directory where data files are stored (for user access, not archive)
Function V_writeData_directory(string fname, string str)

	//	String path = "entry:data_directory"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "data_directory"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// Base class of Nexus definition (=NXsas)
Function V_writeNexusDefinition(string fname, string str)

	//	String path = "entry:definition"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "definition"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function V_writeDataDuration(string fname, variable val)

	string path = "entry:duration"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry"
	string varName   = "duration"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection end time
Function V_writeDataEndTime(string fname, string str)

	//	String path = "entry:end_time"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "end_time"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// experiment description
Function V_writeExperiment_description(string fname, string str)

	//	String path = "entry:experiment_description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "experiment_description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// experiment identifier? used only by NICE?
Function V_writeExperiment_identifier(string fname, string str)

	//	String path = "entry:experiment_identifier"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "experiment_identifier"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// name of facility = NCNR
Function V_writeFacility(string fname, string str)

	//	String path = "entry:facility"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "facility"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// file name
Function V_writeFile_name(string fname, string str)

	//	String path = "entry:file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//// file write time (what is this??)
//// TODO - figure out if this is supposed to be an integer or text (ISO)
//Function V_writeFileWriteTime(fname,val)
//	String fname
//	Variable val
//
//	String path = "entry:file_time"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry"
//	String varName = "file_time"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End

//
Function V_writeHDF_version(string fname, string str)

	//	String path = "entry:hdf_version"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "hdf_version"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
Function V_writeProgram_name(string fname, string str)

	//	String path = "entry:program_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "program_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection start time
Function V_writeDataStartTime(string fname, string str)

	//	String path = "entry:start_time"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "start_time"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// title of experiment
Function V_writeTitle(string fname, string str)

	//	String path = "entry:title"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry" //
	string varName   = "title"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////////// USER
////////// USER
////////// USER

// list of user names
// DONE -- currently not written out to data file??
Function V_writeUserNames(string fname, string str)

	//	String path = "entry:user:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/user" //
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
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
Function V_writeCount_end(string fname, string str)

	//	String path = "entry:control:count_end"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "count_end"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeCount_start(string fname, string str)

	//	String path = "entry:control:count_start"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "count_start"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeCount_time(string fname, variable val)

	//	String path = "entry:control:count_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "count_time"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putCount_time(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:control:count_time"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function V_writeCount_time_preset(string fname, variable val)

	//	String path = "entry:control:count_time_preset"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "count_time_preset"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeDetector_counts(string fname, variable val)

	//	String path = "entry:control:detector_counts"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "detector_counts"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putDetector_counts(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:control:detector_counts"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function V_writeDetector_preset(string fname, variable val)

	//	String path = "entry:control:detector_preset"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "detector_preset"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeIntegral(string fname, variable val)

	//	String path = "entry:control:integral"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "integral"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// control mode for data acquisition, "timer"
Function V_writeControlMode(string fname, string str)

	//	String path = "entry:control:mode"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control" //
	string varName   = "mode"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//monitor count
// integer value
Function V_writeControlMonitorCount(string fname, variable val)

	//	String path = "entry:control:monitor_counts"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "monitor_counts"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putControlMonitorCount(string fname, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:control:monitor_counts"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//integer value
Function V_writeControlMonitor_preset(string fname, variable val)

	//	String path = "entry:control:monitor_preset"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/control"
	string varName   = "monitor_preset"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeControlPreset(string fname, string str)

	//	String path = "entry:control:preset"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/control"
	string varName   = "preset"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

Function V_writeLocalContact(string fname, string str)

	//	String path = "entry:instrument:local_contact"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "local_contact"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeInstrumentName(string fname, string str)

	//	String path = "entry:instrument:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeInstrumentType(string fname, string str)

	//	String path = "entry:instrument:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////// INSTRUMENT/ATTENUATOR
// (DONE) - verify the format of how these are written out to the file
//

// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_writeAttenuator_transmission(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "attenuator_transmission"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_writeAttenuator_trans_err(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "attenuator_transmission_error"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// desired thickness of attenuation
Function V_writeAttenuator_desiredThick(string fname, variable val)

	//	String path = "entry:instrument:attenuator:attenuator_transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "desired_thickness"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// distance from the attenuator to the sample (units??)
Function V_writeAttenDistance(string fname, variable val)

	//	String path = "entry:instrument:attenuator:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// table of the attenuation factor error
Function V_writeAttenIndex_table_err(string fname, WAVE inW)

	//	String path = "entry:instrument:attenuator:index_table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/attenuator"
	string varName   = "index_error_table"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// table of the attenuation factor
Function V_writeAttenIndex_table(string fname, WAVE inW)

	//	String path = "entry:instrument:attenuator:index_table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/attenuator"
	string varName   = "index_table"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// status "in or out"
//Function V_writeAttenStatus(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:attenuator:status"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/attenuator"	//
//	String varName = "status"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End

//// number of attenuators actually dropped in
//// an integer value
Function V_writeAtten_num_dropped(string fname, variable val)

	//	String path = "entry:instrument:attenuator:thickness"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "num_atten_dropped"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// thickness of the attenuator (PMMA) - units??
Function V_writeAttenThickness(string fname, variable val)

	//	String path = "entry:instrument:attenuator:thickness"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/attenuator"
	string varName   = "thickness"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// type of material for the atteunator
Function V_writeAttenType(string fname, string str)

	//	String path = "entry:instrument:attenuator:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/attenuator" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

////////////
// new back polarizer calls
// JUN 2020
// since the location of the original ones that were decided on have changed
// wihtout my knowledge
//

////// INSTRUMENT
//
Function V_writeBackPolarizer_depth(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:depth"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "depth"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_direction(string fname, string str)

	//	String path = "entry:instrument:backPolarizer:direction"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/backPolarizer" //
	string varName   = "direction"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBackPolarizer_height(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:height"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// ?? TODO is this equivalent to "status" -- is this 0|1 ??
Function V_writeBackPolarizer_inBeam(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:inBeam"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "inBeam"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_innerRad(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:innerRadius"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "innerRadius"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// one of the most important
Function V_writeBackPolarizer_name(string fname, string str)

	//	String path = "entry:instrument:backPolarizer:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/backPolarizer" //
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBackPolarizer_opac1A(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:opacityAt1Ang"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "opacityAt1Ang"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_opac1A_err(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:opacityAt1AngStd"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "opacityAt1AngStd"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_outerRad(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:outerRadius"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "outerRadius"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_shape(string fname, string str)

	//	String path = "entry:instrument:backPolarizer:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/backPolarizer" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBackPolarizer_tE(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:tE"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "tE"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_tE_err(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:tEStd"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "tEStd"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_type(string fname, string str)

	//	String path = "entry:instrument:backPolarizer:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/backPolarizer" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBackPolarizer_timestamp(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:timestamp"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "timestamp"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackPolarizer_width(string fname, variable val)

	//	String path = "entry:instrument:backPolarizer:width"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/backPolarizer"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

////////////////////////////////////////////////////////////////////////////////

//////// INSTRUMENT/BEAM
////
//Function V_writeAnalyzer_depth(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:depth"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "depth"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_direction(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:analyzer:direction"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/analyzer"	//
//	String varName = "direction"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeAnalyzer_height(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:height"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "height"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//// ?? TODO is this equivalent to "status" -- is this 0|1 ??
//Function V_writeAnalyzer_inBeam(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:inBeam"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "inBeam"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_innerDiameter(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:innerDiameter"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "innerDiameter"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//// one of the most important
//Function V_writeAnalyzer_name(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:analyzer:name"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/analyzer"	//
//	String varName = "name"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeAnalyzer_opacityAt1Ang(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:opacityAt1Ang"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "opacityAt1Ang"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAna_opacityAt1Ang_err(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:opacityAt1AngStd"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "opacityAt1AngStd"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_outerDiameter(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:outerDiameter"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "outerDiameter"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_shape(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:analyzer:shape"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/analyzer"	//
//	String varName = "shape"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeAnalyzer_tE(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:tE"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "tE"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_tE_err(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:tEStd"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "tEStd"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeAnalyzer_type(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:analyzer:type"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/analyzer"	//
//	String varName = "type"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//
//Function V_writeAnalyzer_width(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:analyzer:width"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/analyzer"
//	String varName = "width"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end

// instrument/beam/chopper (data folder)
Function V_writeChopperAngular_opening(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:angular_opening"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "angular_opening"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeChopDistance_from_sample(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:distance_from_sample"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "distance_from_sample"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeChopDistance_from_source(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:distance_from_source"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "distance_from_source"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeChopperDuty_cycle(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:duty_cycle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "duty_cycle"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeChopperRotation_speed(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:rotation_speed"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "rotation_speed"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeChopperSlits(string fname, variable val)

	//	String path = "entry:instrument:beam:chopper:slits"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/chopper"
	string varName   = "slits"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeChopperstatus(string fname, string str)

	//	String path = "entry:instrument:beam:chopper:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/chopper" //
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeChoppertype(string fname, string str)

	//	String path = "entry:instrument:beam:chopper:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/chopper" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// are these the correct locations in the header for polarization?
// they are what is in the example polarized beam data I was given in 2019
// but don't match what was decided for the data file. Nobody ever
// told me of any changes, so I guess I'm out of the loop as usual.

// the FRONT FLIPPER
// JUN 2020 -- added these calls

Function V_writeFrontFlipper_Direction(string fname, string str)

	//	String path = "entry:instrument:frontFlipper:direction"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/frontFlipper" //
	string varName   = "direction"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeFrontFlipper_flip(string fname, string str)

	//	String path = "entry:instrument:frontFlipper:flip"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/frontFlipper" //
	string varName   = "flip"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeFrontFlipper_Power(string fname, variable val)

	//	String path = "entry:instrument:frontFlipper:power"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/frontFlipper"
	string varName   = "power"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeFrontFlipper_type(string fname, string str)

	//	String path = "entry:instrument:frontFlipper:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/frontFlipper" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

///////////////
// instrument/beam/flipperPolarizer (data folder)
// this is upstream, after the supermirror but before the sample
//
//Function V_writeflipperPol_Direction(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:flipperPolarizer:direction"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/flipperPolarizer"	//
//	String varName = "direction"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeflipperPolarizer_inBeam(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:flipperPolarizer:inBeam"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/flipperPolarizer"
//	String varName = "inBeam"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeflipperPolarizer_Type(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:flipperPolarizer:type"
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/flipperPolarizer"	//
//	String varName = "type"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//

//////////
//// instrument/beam/flipper (data folder)
//Function V_writeFlipperDriving_current(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:flipper:driving_current"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/flipper"
//	String varName = "driving_current"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeFlipperFrequency(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:flipper:frequency"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/flipper"
//	String varName = "frequency"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeFlipperstatus(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:flipper:status"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/flipper"	//
//	String varName = "status"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeFlipperTransmitted_power(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:flipper:transmitted_power"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/flipper"
//	String varName = "transmitted_power"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeFlipperWaveform(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:flipper:waveform"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/flipper"	//
//	String varName = "waveform"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End

// instrument/beam/monochromator (data folder)
Function V_writeMonochromatorType(string fname, string str)

	//	String path = "entry:instrument:beam:monochromator:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/monochromator" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeWavelength(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:wavelength"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator"
	string varName   = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeWavelength_spread(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:wavelength_spread"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator"
	string varName   = "wavelength_spread"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// instrument/beam/monochromator/crystal (data folder)
//
Function V_writeCrystalDistance(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalEnergy(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:energy"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "energy"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalHoriz_apert(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_aperture"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "horizontal_aperture"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalHoriz_curvature(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_curvature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "horizontal_curvature"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalLattice_parameter(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:lattice_parameter"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "lattice_parameter"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalReflection(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:reflection"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "reflection"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalRotation(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:rotation"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "rotation"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalStatus(string fname, string str)

	//	String path = "entry:instrument:beam:monochromator:crystal:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/monochromator/crystal" //
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeCrystalVertical_aperture(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:vertical_aperture"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "vertical_aperture"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalVertical_curv(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:vertical_curvature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "vertical_curvature"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalWavelength(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:wavelength"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalWavelength_spread(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:wavelength_spread"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "wavelength_spread"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeCrystalWavevector(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:crystal:wavevector"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/crystal"
	string varName   = "wavevector"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

////////////
// instrument/beam/monochromator/velocity_selector (data folder)
Function V_writeVSDistance(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeVSRotation_speed(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:rotation_speed"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector"
	string varName   = "rotation_speed"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeVelSelStatus(string fname, string str)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector" //
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeVSTable_parameters(string fname, WAVE inW)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:table"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector"
	string varName   = "table_parameters"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// DONE - this does not exist for VSANS - per JGB 4/2016
//Function V_writeVS_tilt(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:monochromator:velocity_selector:vs_tilt"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"
//	String varName = "vs_tilt"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end

Function V_writeVSWavelength(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector"
	string varName   = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeVSWavelength_spread(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength_spread"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/velocity_selector"
	string varName   = "wavelength_spread"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// instrument/beam/monochromator/white_beam (data folder)
Function V_writeWhiteBeamStatus(string fname, string str)

	//	String path = "entry:instrument:beam:monochromator:white_beam:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/monochromator/white_beam" //
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeWhiteBeamWavelength(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/white_beam"
	string varName   = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeWhiteBeamWavel_spread(string fname, variable val)

	//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength_spread"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/monochromator/white_beam"
	string varName   = "wavelength_spread"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// instrument/beam/superMirror (data folder)
// This is the upstream polarizer. There are no other choices for polarizer on VSANS
Function V_writePolarizerComposition(string fname, string str)

	//	String path = "entry:instrument:beam:superMirror:composition"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/superMirror" //
	string varName   = "composition"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writePolarizerEfficiency(string fname, variable val)

	//	String path = "entry:instrument:beam:superMirror:efficiency"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam/superMirror"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writePolarizerState(string fname, string str)

	//	String path = "entry:instrument:beam:superMirror:state"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam/superMirror" //
	string varName   = "state"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//Function V_writePolarizerType(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:polarizer:type"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/polarizer"	//
//	String varName = "type"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//// instrument/beam/polarizer_analyzer (data folder)
//// integer value
//Function V_writePolAnaCell_index(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:polarizer_analyzer:cell_index"
//
//	Make/O/I/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"
//	String varName = "cell_index"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End
//
//Function V_writePolAnaCell_name(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:polarizer_analyzer:cell_name"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"	//
//	String varName = "cell_name"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writePolAnaCell_parameters(fname,inW)
//	String fname
//	Wave inW
//
////	String path = "entry:instrument:beam:polarizer_analyzer:cell_parameters"
//
//	Duplicate/O inW wTmpWrite
//// then use redimension as needed to cast the wave to write to the specified type
//// see WaveType for the proper codes
////	Redimension/T=() wTmpWrite
//// -- May also need to check the dimension(s) before writing (don't trust the input)
//	String groupName = "/entry/instrument//beam/polarizer_analyzer"
//	String varName = "cell_parameters"
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End
//
//Function V_writePolAnaGuideFieldCur_1(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_1"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"
//	String varName = "guide_field_current_1"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End
//
//Function V_writePolAnaGuideFieldCur_2(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_2"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"
//	String varName = "guide_field_current_2"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End
//
//Function V_writePolAnaSolenoid_current(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:instrument:beam:polarizer_analyzer:solenoid_current"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"
//	String varName = "solenoid_current"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End
//
//Function V_writePolAnaStatus(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:polarizer_analyzer:status"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/polarizer_analyzer"	//
//	String varName = "status"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End

/////// INSTRUMENT/BEAM MONITORS

//beam_monitor_low (data folder)
// integer value
Function V_writeBeamMonLowData(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_low:data"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_low"
	string varName   = "data"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonLowDistance(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_low:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_low"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonLowEfficiency(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_low:efficiency"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_low"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonLowSaved_count(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_low:saved_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_low"
	string varName   = "saved_count"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonLowType(string fname, string str)

	//	String path = "entry:instrument:beam_monitor_low:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_monitor_low" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//beam_monitor_norm (data folder)
// integer value
Function V_writeBeamMonNormData(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:data"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "data"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putBeamMonNormData(string fname, variable val)

	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:beam_monitor_norm:data"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function V_writeBeamMonNormDistance(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonNormEfficiency(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:efficiency"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamMonNormSaved_count(string fname, variable val)

	//	String path = "entry:instrument:beam_monitor_norm:saved_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_monitor_norm"
	string varName   = "saved_count"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putBeamMonNormSaved_count(string fname, variable val)

	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:beam_monitor_norm:saved_count"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function V_writeBeamMonNormType(string fname, string str)

	//	String path = "entry:instrument:beam_monitor_norm:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_monitor_norm" //
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//beam_stop C2 (data folder)
Function V_writeBeamStopC2Description(string fname, string str)

	//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop_C2" //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBeamStopC2Dist_to_det(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:distance_to_detector"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2"
	string varName   = "distance_to_detector"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// is this the index of which size beam stop is in position?
// integer value
Function V_writeBeamStopC2num_stop(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:distance_to_detector"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2"
	string varName   = "num_beamstops"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC2_x_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:x0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2"
	string varName   = "x_pos"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC2_y_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2"
	string varName   = "y_pos"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// beam stop C2 (shape)
Function V_writeBeamStopC2_height(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC2_shape(string fname, string str)

	//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop_C2/shape" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// this is diameter if shape=CIRCLE
Function V_writeBeamStopC2_size(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC2_width(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C2/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// beam stop C3 (data folder)
Function V_writeBeamStopC3Description(string fname, string str)

	//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop_C3" //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeBeamStopC3Dist_to_det(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:distance_to_detector"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3"
	string varName   = "distance_to_detector"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeBeamStopC3num_stop(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:distance_to_detector"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3"
	string varName   = "num_beamstops"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC3_x_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:x0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3"
	string varName   = "x_pos"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC3_y_pos(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3"
	string varName   = "y_pos"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// beam stop C3 (shape)
Function V_writeBeamStopC3_height(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC3_shape(string fname, string str)

	//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/beam_stop_C3/shape" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// this is diameter if shape=CIRCLE
Function V_writeBeamStopC3_size(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBeamStopC3_width(string fname, variable val)

	//	String path = "entry:instrument:beam_stop:y0"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/beam_stop_C3/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// INSTRUMENT/COLLIMATOR
//collimator (data folder) -- this is a TEXT field
Function V_writeNumberOfGuides(string fname, string str)

	//	String path = "entry:instrument:collimator:number_guides"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/collimator"
	string varName   = "number_guides"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//				geometry (data folder)
//					shape (data folder)
Function V_writeGuideShape(string fname, string str)

	//	String path = "entry:instrument:collimator:geometry:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/collimator/geometry/shape" //
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- this may need to be a wave to properly describe the dimensions
Function V_writeGuideSize(string fname, variable val)

	//	String path = "entry:instrument:collimator:geometry:shape:size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/collimator/geometry/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//			converging_pinholes (data folder)
Function V_writeConvPinholeStatus(string fname, string str)

	//	String path = "entry:instrument:converging_pinholes:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/converging_pinholes" //
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//			converging_slits (not used)

////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// (DONE) -- write to return an ARRAY
Function V_writeDet_cal_x(string fname, string detStr, WAVE inW)

	if(cmpstr(detStr, "B") == 0)
		//		String path = "entry:instrument:detector_"+detStr+":CALX"

		Duplicate/O inW, wTmpWrite
		// then use redimension as needed to cast the wave to write to the specified type
		// see WaveType for the proper codes
		//	Redimension/T=() wTmpWrite
		// -- May also need to check the dimension(s) before writing (don't trust the input)
		string groupName = "/entry/instrument/detector_" + detStr
		string varName   = "cal_x"

		variable err
		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ", err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
		//		err = V_KillNamedDataFolder(fname)
		//		if(err)
		//			Print "DataFolder kill err = ",err
		//		endif
		return (err)
	endif

	return (0)
End

// only defined for the "B" detector, and may not be necessary?
// (DONE) -- write to return an ARRAY
Function V_writeDet_cal_y(string fname, string detStr, WAVE inW)

	if(cmpstr(detStr, "B") == 0)
		//		String path = "entry:instrument:detector_"+detStr+":CALY"

		Duplicate/O inW, wTmpWrite
		// then use redimension as needed to cast the wave to write to the specified type
		// see WaveType for the proper codes
		//	Redimension/T=() wTmpWrite
		// -- May also need to check the dimension(s) before writing (don't trust the input)
		string groupName = "/entry/instrument/detector_" + detStr
		string varName   = "cal_y"

		variable err
		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ", err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
		//		err = V_KillNamedDataFolder(fname)
		//		if(err)
		//			Print "DataFolder kill err = ",err
		//		endif
		return (err)
	endif

	return (0)
End

// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_writeDet_pixel_fwhm_x(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_x"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "pixel_fwhm_x"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_writeDet_pixel_fwhm_y(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_y"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "pixel_fwhm_y"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeDet_pixel_num_x(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":pixel_nnum_x"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "pixel_num_x"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeDet_pixel_num_y(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":pixel_num_y"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "pixel_num_y"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_writeDet_azimuthalAngle(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
//	if(cmpstr(detStr,"B") == 0)
////		String path = "entry:instrument:detector_"+detStr+":azimuthal_angle"
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "azimuthal_angle"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function V_writeDet_beam_center_x(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":beam_center_x"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "beam_center_x"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putDet_beam_center_x(string fname, string detStr, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:detector_" + detStr + ":beam_center_x"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// fname is a local WORK folder
Function V_putDet_beam_center_x_pix(string fname, string detStr, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x_pix
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:detector_" + detStr + ":beam_center_x_pix"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

Function V_writeDet_beam_center_y(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":beam_center_y"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "beam_center_y"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putDet_beam_center_y(string fname, string detStr, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:detector_" + detStr + ":beam_center_y"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// fname is a local WORK folder
Function V_putDet_beam_center_y_pix(string fname, string detStr, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y_pix
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:detector_" + detStr + ":beam_center_y_pix"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_writeDetectorData(string fname, string detStr, WAVE inW)

	//	String path = "entry:instrument:detector_"+detStr+":data"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "data"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

/////////////////////////

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function V_writeDetector_deadtime(string fname, string detStr, WAVE inW)

	//	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr, "B") == 0)
		DoAlert 0, "Bad call to V_writeDetector_deadtime"
		return (0)
	endif

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "dead_time"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// dead time, a single value, only for detB
Function V_writeDetector_deadtime_B(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr, "B") == 0)

		Make/O/D/N=1 wTmpWrite
		//	Make/O/R/N=1 wTmpWrite
		string groupName = "/entry/instrument/detector_" + detStr
		string varName   = "dead_time"
		wTmpWrite[0] = val

		variable err
		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ", err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
		//	err = V_KillNamedDataFolder(fname)
		//	if(err)
		//		Print "DataFolder kill err = ",err
		//	endif

		return (err)
	endif

	DoAlert 0, "Bad call to V_writeDetector_deadtime_B"
	return (0)
End

// high res detector gain, a single value, only for detB
Function V_writeDetector_highResGain(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":highResGain"
	if(cmpstr(detStr, "B") == 0)

		Make/O/D/N=1 wTmpWrite
		//	Make/O/R/N=1 wTmpWrite
		string groupName = "/entry/instrument/detector_" + detStr
		string varName   = "highResGain"
		wTmpWrite[0] = val

		variable err
		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ", err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
		//	err = V_KillNamedDataFolder(fname)
		//	if(err)
		//		Print "DataFolder kill err = ",err
		//	endif

		return (err)
	endif

	DoAlert 0, "Bad call to V_writeDetector_highResGain"
	return (0)
End

Function V_writeDetDescription(string fname, string detStr, string str)

	//	String path = "entry:instrument:detector_"+detStr+":description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector_" + detStr //
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeDet_distance(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_writeDet_equatorial_angle(fname,detStr,val)
//	String fname,detStr
//	variable val
//
//	if(cmpstr(detStr,"B") == 0)
////		String path = "entry:instrument:detector_"+detStr+":equatorial_angle"
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "equatorial_angle"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function V_writeDetEventFileName(string fname, string detStr, string str)

	//	String path = "entry:instrument:detector_"+detStr+":event_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector_" + detStr //
	string varName   = "event_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeDet_IntegratedCount(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":integrated_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "integrated_count"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putDet_IntegratedCount(string fname, string detStr, variable val)

	//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:instrument:detector_" + detStr + ":integrated_count"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

// this is only written for B and L/R detectors
Function V_writeDet_LateralOffset(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":lateral_offset"

	if(cmpstr(detStr, "FT") == 0 || cmpstr(detStr, "FB") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MT") == 0 || cmpstr(detStr, "MB") == 0)
		return (0)
	endif

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "lateral_offset"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// this is only written for T/B detectors
Function V_writeDet_VerticalOffset(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":vertical_offset"

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "FR") == 0 || cmpstr(detStr, "FL") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MR") == 0 || cmpstr(detStr, "ML") == 0)
		return (0)
	endif

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "vertical_offset"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// (DONE) - be sure that this is defined correctly
// -- it needs to exist in the data file, and only for TB detector panels
Function V_writeDet_TBSetback(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":setback"

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "FR") == 0 || cmpstr(detStr, "FL") == 0)
		return (0)
	endif
	if(cmpstr(detStr, "MR") == 0 || cmpstr(detStr, "ML") == 0)
		return (0)
	endif

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "setback"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// gap when panels are "touching"
// units are mm
// writes panel gap for detector panel specified
// does not write anything if "B" is passed (no such field for this detector)
//
Function V_writeDet_panel_gap(string fname, string detStr, variable val)

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	//	String path = "entry:instrument:detector_"+detStr+":panel_gap"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "panel_gap"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_writeDet_polar_angle(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
//	if(cmpstr(detStr,"B") == 0)
////		String path = "entry:instrument:detector_"+detStr+":polar_angle"
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "polar_angle"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function V_writeDet_rotational_angle(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
//	if(cmpstr(detStr,"B") == 0)
////		String path = "entry:instrument:detector_"+detStr+":rotational_angle"
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "rotational_angle"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function V_writeDetSettings(string fname, string detStr, string str)

	//	String path = "entry:instrument:detector_"+detStr+":settings"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector_" + detStr //
	string varName   = "settings"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//// really has no meaning at all
//Function V_writeDet_size(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
////	String path = "entry:instrument:detector_"+detStr+":size"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/instrument/detector_"+detStr
//	String varName = "size"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//End

//Function V_writeDetType(fname,detStr,str)
//	String fname,detStr,str
//
////	String path = "entry:instrument:detector_"+detStr+":type"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/detector_"+detStr	//
//	String varName = "type"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End

Function V_writeDet_x_pixel_size(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":x_pixel_size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "x_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeDet_y_pixel_size(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":y_pixel_size"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "y_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

/////////			detector_FB (data folder) + ALL other PANEL DETECTORS

// integer value
Function V_writeDet_numberOfTubes(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"
	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "number_of_tubes"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = V_KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)
End

// deleted from definition
//Function V_writeDetPanelSeparation(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
////	String path = "entry:instrument:detector_"+detStr+":separation"
//	if(cmpstr(detStr,"B") == 0)
//		return(0)
//	else
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "separation"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	endif
//End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_writeDetTube_spatialCalib(string fname, string detStr, WAVE inW)

	//	String path = "entry:instrument:detector_"+detStr+":spatial_calibration"

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "spatial_calibration"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = V_KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)
End

//// (DONE) -- be clear on how this is defined.
//Function V_writeDet_tubeIndex(fname,detStr,val)
//	String fname,detStr
//	Variable val
//
////	String path = "entry:instrument:detector_"+detStr+":tube_index"
//	if(cmpstr(detStr,"B") == 0)
//		return(0)
//	else
//
//		Make/O/D/N=1 wTmpWrite
//	//	Make/O/R/N=1 wTmpWrite
//		String groupName = "/entry/instrument/detector_"+detStr
//		String varName = "tube_index"
//		wTmpWrite[0] = val
//
//		variable err
//		err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = V_KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	endif
//End

Function V_writeDet_tubeOrientation(string fname, string detStr, string str)

	//	String path = "entry:instrument:detector_"+detStr+":tube_orientation"

	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/detector_" + detStr //
	string varName   = "tube_orientation"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = V_KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif

	return (err)

End

// (DONE) -- be clear on how this is defined. Units?
Function V_writeDet_tubeWidth(string fname, string detStr, variable val)

	//	String path = "entry:instrument:detector_"+detStr+":tube_width"
	if(cmpstr(detStr, "B") == 0)
		return (0)
	endif

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/detector_" + detStr
	string varName   = "tube_width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//		err = V_KillNamedDataFolder(fname)
	//		if(err)
	//			Print "DataFolder kill err = ",err
	//		endif
	return (err)
End

//////////////////////

// INSTRUMENT/LENSES 	/APERTURES
//  lenses (data folder)

Function V_writeLensCurvature(string fname, variable val)

	//	String path = "entry:instrument:lenses:curvature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "curvature"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLensesFocusType(string fname, string str)

	//	String path = "entry:instrument:lenses:focus_type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "focus_type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeLensDistance(string fname, variable val)

	//	String path = "entry:instrument:lenses:lens_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLensGeometry(string fname, string str)

	//	String path = "entry:instrument:lenses:lens_geometry"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_geometry"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeLensMaterial(string fname, string str)

	//	String path = "entry:instrument:lenses:lens_material"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "lens_material"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// integer value
Function V_writeNumber_of_Lenses(string fname, variable val)

	//	String path = "entry:instrument:lenses:number_of_lenses"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "number_of_lenses"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// integer value
Function V_writeNumber_of_prisms(string fname, variable val)

	//	String path = "entry:instrument:lenses:number_of_prisms"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "number_of_prisms"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writePrism_distance(string fname, variable val)

	//	String path = "entry:instrument:lenses:prism_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/lenses"
	string varName   = "prism_distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writePrismMaterial(string fname, string str)

	//	String path = "entry:instrument:lenses:prism_material"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "prism_material"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// status of lens/prism = lens | prism | both | out
Function V_writeLensPrismStatus(string fname, string str)

	//	String path = "entry:instrument:lenses:status"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/lenses"
	string varName   = "status"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

///////  sample_aperture (1) (data folder)
// this is the INTERNAL sample aperture
Function V_writeSampleAp_Description(string fname, string str)

	//	String path = "entry:instrument:sample_aperture:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSampleAp_distance(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//	sample_apertuer/shape (data folder)
Function V_writeSampleAp_height(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeSampleAp_shape(string fname, string str)

	//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSampleAp_size(string fname, string str)

	//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "size"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSampleAp_width(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

///////  sample_aperture_2 (data folder)
// sample aperture (2) is the external aperture, which may or may not be present

Function V_writeSampleAp2_Description(string fname, string str)

	//	String path = "entry:instrument:sample_aperture_2:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture_2"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSampleAp2_distance(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture_2:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture_2"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//	shape (data folder)
Function V_writeSampleAp2_height(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture_2/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeSampleAp2_shape(string fname, string str)

	//	String path = "entry:instrument:sample_aperture_2:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_aperture_2/shape"
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSampleAp2_size(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture_2/shape"
	string varName   = "size"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeSampleAp2_width(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_aperture_2/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////  sample_table (data folder)
// location  = "CHAMBER" or HUBER
Function V_writeSampleTableLocation(string fname, string str)

	//	String path = "entry:instrument:sample_table:location"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/sample_table"
	string varName   = "location"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function V_writeSampleTableOffset(string fname, variable val)

	//	String path = "entry:instrument:sample_table:offset_distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/sample_table"
	string varName   = "offset_distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//  source (data folder)
//name "NCNR"
Function V_writeSourceName(string fname, string str)

	//	String path = "entry:instrument:source:name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//	power -- nominal only, not connected to any real number
Function V_writeReactorPower(string fname, variable val)

	//	String path = "entry:instrument:source:power"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source"
	string varName   = "power"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//probe (wave) "neutron"
Function V_writeSourceProbe(string fname, string str)

	//	String path = "entry:instrument:source:probe"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "probe"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//type (wave) "Reactor Neutron Source"
Function V_writeSourceType(string fname, string str)

	//	String path = "entry:instrument:source:type"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source"
	string varName   = "type"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

///////  source_aperture (data folder)

Function V_writeSourceAp_Description(string fname, string str)

	//	String path = "entry:instrument:source_aperture:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSourceAp_distance(string fname, variable val)

	//	String path = "entry:instrument:source_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture"
	string varName   = "distance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//	shape (data folder)
Function V_writeSourceAp_height(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "height"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeSourceAp_shape(string fname, string str)

	//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "shape"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSourceAp_size(string fname, string str)

	//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "size"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSourceAp_width(string fname, variable val)

	//	String path = "entry:instrument:sample_aperture:distance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/instrument/source_aperture/shape"
	string varName   = "width"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//Sample position in changer
Function V_writeSamplePosition(string fname, string str)

	//	String path = "entry:sample:changer_position"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "changer_position"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// sample label
// (DONE): value of num is currently not used
Function V_writeSampleDescription(string fname, string str)

	//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// fname is a local WORK folder
Function V_putSampleDescription(string fname, string str)

	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:sample:description"

	WAVE/Z/T w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = str
	return (0)

End

// for a z-stage??
Function V_writeSample_elevation(string fname, variable val)

	//	String path = "entry:sample:elevation"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "elevation"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//no meaning to this...
Function V_writeSample_equatorial_ang(string fname, variable val)

	//	String path = "entry:sample:equatorial_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "equatorial_angle"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
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
Function V_writeSample_GroupID(string fname, variable val)

	//	String path = "entry:sample:group_id"

	Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "group_id"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Rotation Angle
Function V_writeSampleRotationAngle(string fname, variable val)

	//	String path = "entry:sample:rotation_angle"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "rotation_angle"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//?? this is huber/chamber??
// (DONE) -- then where is the description of 10CB, etc...
Function V_writeSampleHolderDescription(string fname, string str)

	//	String path = "entry:sample:sample_holder_description"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample"
	string varName   = "sample_holder_description"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//Sample Temperature
Function V_writeSampleTemperature(string fname, variable val)

	//	String path = "entry:sample:temperature"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "temperature"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Temperature set point
Function V_writeSampleTempSetPoint(string fname, variable val)

	//	String path = "entry:sample:temperature_setpoint"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "temperature_setpoint"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Thickness
// (DONE) -- somehow, this is not set correctly in the acquisition, so NaN results
Function V_writeSampleThickness(string fname, variable val)

	//	String path = "entry:sample:thickness"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "thickness"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//Sample Translation
Function V_writeSampleTranslation(string fname, variable val)

	//	String path = "entry:sample:translation"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "translation"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// sample transmission
Function V_writeSampleTransmission(string fname, variable val)

	string path = "entry:sample:transmission"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "transmission"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// fname is a local WORK folder
Function V_putSampleTransmission(string fname, variable val)

	string path = "root:Packages:NIST:VSANS:" + fname + ":"
	path += "entry:sample:transmission"

	WAVE/Z w = $path
	if(waveExists(w) == 0)
		return (1)
	endif

	w[0] = val
	return (0)

End

//transmission error (one sigma)
Function V_writeSampleTransError(string fname, variable val)

	//	String path = "entry:sample:transmission_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample"
	string varName   = "transmission_error"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

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

Function V_writeLog_attachedTo(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "attached_to"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeLog_measurement(string fname, string logStr, string str)

	string path = "entry:sample:" + logstr + ":measurement"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "measurement"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeLog_Name(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//// TODO -- this may require multiple entries, for each sensor _1, _2, etc.
//Function V_writeLog_setPoint(fname,logStr,val)
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
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writeLog_startTime(fname,logStr,str)
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
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//
//// TODO -- this may only exist for electric and magnetic field, or be removed
//Function V_writeLog_nomValue(fname,logStr,val)
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
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end

// for temperature only, logStr must be "temperature_env"
Function V_writeTempLog_ControlSensor(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":control_sensor"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "control_sensor"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// for temperature only, logStr must be "temperature_env"
Function V_writeTempLog_MonitorSensor(string fname, string logStr, string str)

	//	String path = "entry:sample:"+logstr+":monitor_sensor"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/" + logStr
	string varName   = "monitor_sensor"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
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
// read the value of V_getTemp_MonitorSensor/ControlSensor to get the name of the sensor level .
//

Function V_writeTempLog_attachedTo(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "attached_to"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTempLog_highTrip(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":high_trip_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "high_trip_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_holdTime(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":hold_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "hold_time"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_lowTrip(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":low_trip_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "low_trip_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_measurement(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":measurement"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "measurement"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTempLog_model(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":model"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "model"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTempLog_name(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTempLog_runControl(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":run_control"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "run_control"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_setPoint(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":setpoint"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "setpoint"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_shortName(string fname, string logStr, string str)

	//	String path = "entry:sample:temperature_env:"+logstr+":short_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "short_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTempLog_timeout(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":timeout"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "timeout"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_tolerance(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":tolerance"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "tolerance"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_toleranceBand(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":tolerance_band_time"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "tolerance_band_time"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeTempLog_Value(string fname, string logStr, variable val)

	//	String path = "entry:sample:temperature_env:"+logstr+":value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/temperature_env/" + logStr
	string varName   = "value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
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
// read the value of V_getTemp_MonitorSensor to get the name of the sensor the next level down.
//
//
/////////////////////////////////////
////		value_log (data folder)
//
// (DONE) --
Function V_writeLog_avgValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:average_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "average_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLog_avgValue_err(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:average_value_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "average_value_error"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLog_maximumValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:maximum_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "maximum_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLog_medianValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:median_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "median_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeLog_minimumValue(string fname, string logStr, variable val)

	//	String path = "entry:sample:"+logstr+":value_log:minimum_value"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "minimum_value"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO -- this needs to be a WAVE reference
// be sure this gets written as "time", even though it is read in as "time0"
Function V_writeLog_timeWave(string fname, string logStr, WAVE inW)

	//	String path = "entry:sample:"+logstr+":value_log:time"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "time"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO -- this needs to be a WAVE reference
Function V_writeLog_ValueWave(string fname, string logStr, WAVE inW)

	//	String path = "entry:sample:"+logstr+":value_log:value"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/sample/" + logStr + "/value_log"
	string varName   = "value"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

///////// REDUCTION
///////// REDUCTION
///////// REDUCTION

// TODO
// -- come up with a scheme to write the entire protocol to the data file?
// -- or a scheme to write just the missing bits?

// TODO -- needs to be a Text WAVE, and of the proper size and type!!!
//  -- this is a test where I write a wave to a field that does not exist...
Function V_writeReductionProtocolWave(string fname, WAVE/T inTW)

	//	String path = "entry:reduction:absolute_scaling"

	Duplicate/O inTW, wTTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "protocol"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// this is a NON NICE entered field
//
// this is a flag to mark the file as "flipped" so it prevents a 2nd flip
// if the flip has been done, the field is written with a value of 1 (= true)
//
// to "un-mark" the file and allow the flip to be re-done, write -999999
Function V_writeLeftRightFlipDone(string fname, variable val)

	//	String path = "entry:reduction:left_right_flip"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "left_right_flip"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// TODO -- needs to be a WAVE, and of the proper size and type!!!
Function V_writeAbsolute_Scaling(string fname, WAVE inW)

	//	String path = "entry:reduction:absolute_scaling"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "absolute_scaling"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeBackgroundFileName(string fname, string str)

	//	String path = "entry:reduction:background_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "background_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// (DONE) -- needs to be a WAVE
Function V_writeBoxCoordinates(string fname, WAVE inW)

	//	String path = "entry:reduction:box_coordinates"

	Duplicate/O inW, wTmpWrite
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
	string groupName = "/entry/reduction"
	string varName   = "box_coordinates"

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

// THIS IS A NON-NICE ENTERED FIELD
// -- this is the panel string where the box coordinates refer to (for the open beam and transmission)
Function V_writeReduction_BoxPanel(string fname, string str)

	//	String path = "entry:reduction:comments"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "box_panel"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//box counts
Function V_writeBoxCounts(string fname, variable val)

	//	String path = "entry:reduction:box_count"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "box_count"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//box counts error
Function V_writeBoxCountsError(string fname, variable val)

	//	String path = "entry:reduction:box_count_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "box_count_error"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

Function V_writeReductionComments(string fname, string str)

	//	String path = "entry:reduction:comments"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "comments"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeEmptyBeamFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "empty_beam_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeEmptyFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "empty_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeReduction_purpose(string fname, string str)

	//	String path = "entry:reduction:file_purpose"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "file_purpose"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

// DONE x- commented out, not to be used
//  x- is this duplicated? - yes - this is duplicated in /entry/sample
//  x- so I need to pick a location, or be sure to fix it in both places
//Function V_writeReduction_group_ID(fname,val)
//	String fname
//	Variable val
//
////	String path = "entry:reduction:group_id"
//
//	Make/O/D/N=1 wTmpWrite
////	Make/O/R/N=1 wTmpWrite
//	String groupName = "/entry/reduction"
//	String varName = "group_id"
//	wTmpWrite[0] = val
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end

Function V_writeReductionIntent(string fname, string str)

	//	String path = "entry:reduction:intent"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "intent"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeMaskFileName(string fname, string str)

	//	String path = "entry:reduction:empty_beam_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "mask_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeLogFileName(string fname, string str)

	//	String path = "entry:reduction:sans_log_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "sans_log_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeSensitivityFileName(string fname, string str)

	//	String path = "entry:reduction:sensitivity_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "sensitivity_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

Function V_writeTransmissionFileName(string fname, string str)

	//	String path = "entry:reduction:transmission_file_name"

	Make/O/T/N=1 tmpTW
	string groupName = "/entry/reduction"
	string varName   = "transmission_file_name"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ", err
	endif

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif

	return (err)
End

//whole detector transmission
Function V_writeSampleTransWholeDetector(string fname, variable val)

	//	String path = "entry:reduction:whole_trans"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "whole_trans"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

//whole detector transmission error
Function V_writeSampleTransWholeDetErr(string fname, variable val)

	//	String path = "entry:reduction:whole_trans_error"

	Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
	string groupName = "/entry/reduction"
	string varName   = "whole_trans_error"
	wTmpWrite[0] = val

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ", err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	//	err = V_KillNamedDataFolder(fname)
	//	if(err)
	//		Print "DataFolder kill err = ",err
	//	endif
	return (err)
End

///////			pol_sans (data folder)
//
//Function V_writePolSANS_cellName(fname,str)
//	String fname,str
//
////	String path = "entry:reduction:pol_sans:cell_name"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/reduction/pol_sans"
//	String varName = "cell_name"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//
//// TODO -- needs to be a WAVE
//// is this a text wave?? if it's mixed names + values, then what?
//Function V_writePolSANS_cellParams(fname,inW)
//	String fname
//	Wave inW
//
////	String path = "entry:reduction:pol_sans:cell_parameters"
//
//	Duplicate/O inW wTmpWrite
//// then use redimension as needed to cast the wave to write to the specified type
//// see WaveType for the proper codes
////	Redimension/T=() wTmpWrite
//// -- May also need to check the dimension(s) before writing (don't trust the input)
//	String groupName = "/entry/reduction/pol_sans"
//	String varName = "cell_parameters"
//
//	variable err
//	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//	return(err)
//end
//
//Function V_writePolSANS_PolSANSPurpose(fname,str)
//	String fname,str
//
////	String path = "entry:reduction:pol_sans:pol_sans_purpose"
//
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/reduction/pol_sans"
//	String varName = "pol_sans_purpose"
//	tmpTW[0] = str //
//
//	variable err
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
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
//// (DONE) -- this will need to be completely replaced with a function that can
//// read the binary image data. should be possible, but I don't know the details on either end...
//Function V_writeDataImage(fname,detStr,str)
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
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeDataImageDescription(fname,detStr,str)
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
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
//Function V_writeDataImageType(fname,detStr,str)
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
//	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	if(err)
//		Print "HDF write err = ",err
//	endif
//
//	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////	err = V_KillNamedDataFolder(fname)
////	if(err)
////		Print "DataFolder kill err = ",err
////	endif
//
//	return(err)
//End
//
