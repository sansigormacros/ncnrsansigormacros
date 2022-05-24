#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


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
Function proto_write_FP(str)
	String str
	return(0)
end
Function proto_write_FP2(str,str2)
	String str,str2
	return(0)
end
//Function proto_write_STR(str)
//	String str
//	return("")
//end

Function Test_write_FP(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_write_FP f = $item
		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_write_FP2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_write_FP2 f = $item
		Print item ," = ", f(fname,detStr)
	endfor
	
	return(0)
end

Function Test_write_STR(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_write_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\")",item,fname
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_write_STR2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_write_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\",\"%s\")",item,fname,detStr
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end
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
Function writeCollectionTime(fname,val)
	String fname
	Variable val
	
//	String path = "entry:collection_time"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry"	
	String varName = "collection_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putCollectionTime(fname,val)
	String fname
	Variable val

//root:Packages:NIST:RAW:entry:control:count_time
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:control:count_time"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// data directory where data files are stored (for user access, not archive)
Function writeData_directory(fname,str)
	String fname,str
	
//	String path = "entry:data_directory"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "data_directory"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// Base class of Nexus definition (=NXsas)
Function writeNexusDefinition(fname,str)
	String fname,str
	
//	String path = "entry:definition"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "definition"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function writeDataDuration(fname,val)
	String fname
	Variable val
	
	String path = "entry:duration"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry"	
	String varName = "duration"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection end time
Function writeDataEndTime(fname,str)
	String fname,str
	
//	String path = "entry:end_time"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "end_time"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// experiment description
Function writeExperiment_description(fname,str)
	String fname,str
	
//	String path = "entry:experiment_description"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "experiment_description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// experiment identifier? used only by NICE?
Function writeExperiment_identifier(fname,str)
	String fname,str
	
//	String path = "entry:experiment_identifier"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "experiment_identifier"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// name of facility = NCNR
Function writeFacility(fname,str)
	String fname,str
	
//	String path = "entry:facility"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "facility"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

	
//
Function write_facility(fname,str)
	String fname,str
	
//	String path = "entry:hdf_version"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "facility"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
Function writeProgram_name(fname,str)
	String fname,str
	
//	String path = "entry:program_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "program_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// (DONE) -- not mine, added somewhere by Nexus writer?
// data collection start time
Function writeDataStartTime(fname,str)
	String fname,str
	
//	String path = "entry:start_time"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "start_time"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End
		
// title of experiment
Function writeTitle(fname,str)
	String fname,str
	
//	String path = "entry:title"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "title"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end
	
	
		

//////// CONTROL
//////// CONTROL
//////// CONTROL

// (DONE) -- for the control section, document each of the fields
//
Function writeCount_end(fname,str)
	String fname,str
	
//	String path = "entry:control:count_end"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/control"	//	
	String varName = "count_end"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end

Function writeCount_start(fname,str)
	String fname,str
	
//	String path = "entry:control:count_start"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/control"	//	
	String varName = "count_start"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end


Function writeCount_time(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_time"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// fname is a local WORK folder
Function putCount_time(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:control:count_time"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

Function writeCount_time_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_time_preset"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_time_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


Function writeDetector_counts(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:detector_counts"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "detector_counts"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// fname is a local WORK folder
Function putDetector_counts(fname,val)
	String fname
	Variable val

//root:Packages:NIST:RAW:entry:control:detector_counts
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:control:detector_counts"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

Function writeDetector_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:detector_preset"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "detector_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// integer value
Function write_efficiency(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:integral"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// control mode for data acquisition, "timer"
Function writeControlMode(fname,str)
	String fname,str
	
//	String path = "entry:control:mode"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/control"	//	
	String varName = "mode"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

//monitor count
// integer value
Function writeControlMonitorCount(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_counts"	
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "monitor_counts"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// fname is a local WORK folder
Function putControlMonitorCount(fname,val)
	String fname
	Variable val

//root:Packages:NIST:RAW:entry:control:monitor_counts
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:control:monitor_counts"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

//integer value
Function writeControlMonitor_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "monitor_preset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// ?? sampled fraction of the monitor
Function writeControl_sampled_fraction(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "sampled_fraction"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



//////// DATA
//////// DATA
//////// DATA

// THIS IS NOT THE MAIN DETECTOR BLOCK!
// This is a nexus-compliant block. I did not add this, and I don't 
// expect to use this much , but it is here to be complete


//  copy of the data array
Function writeData_areaDetector(fname,inW)
	String fname
	Wave inW
	

	Duplicate/O inW wTmpWrite 	
//
	String groupName = "/entry/dat"	
	String varName = "y0"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeData_configuration(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/data"	
	String varName = "configuration"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeData_sample_description(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/data"	
	String varName = "sample_description"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeData_sample_thickness(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/data"	
	String varName = "sample_thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeData_slotIndex(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/data"	
	String varName = "slotIndex"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeData_x0(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/data"	
	String varName = "x0"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



// table of y-coordinates of the data array?
Function writeData_y0(fname,inW)
	String fname
	Wave inW
	

	Duplicate/O inW wTmpWrite 	
//
	String groupName = "/entry/dat"	
	String varName = "y0"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

// there are a few fields at the top level of INSTRUMENT
// but most fields are in separate blocks
//


Function writeLocalContact(fname,str)
	String fname,str

//	String path = "entry:instrument:local_contact"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "local_contact"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeInstrumentName(fname,str)
	String fname,str

//	String path = "entry:instrument:name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeInstrumentType(fname,str)
	String fname,str

//	String path = "entry:instrument:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End





////// INSTRUMENT/ATTENUATOR
////// INSTRUMENT/ATTENUATOR
////// INSTRUMENT/ATTENUATOR


// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function writeAttenuator_transmission(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:attenuator_transmission"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "attenuator_transmission"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// transmission value (error) for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function writeAttenuator_trans_err(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:attenuator_transmission_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "attenuator_transmission_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// desired thickness of attenuation
Function writeAttenuator_desiredThick(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:attenuator_transmission_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "desired_thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// distance from the attenuator to the sample (units??)
Function writeAttenDistance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// table of the attenuation factor error
Function writeAttenIndex_table_err(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:instrument:attenuator:index_table"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/attenuator"	
	String varName = "index_error_table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// table of the attenuation factor
Function writeAttenIndex_table(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:instrument:attenuator:index_table"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/attenuator"	
	String varName = "index_table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



//// number of attenuators actually dropped in
//// an integer value
Function writeAtten_num_dropped(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:thickness"	
	
	Make/O/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "num_atten_dropped"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// thickness of the attenuator (PMMA) - units??
Function writeAttenThickness(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:thickness"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// type of material for the atteunator
Function writeAttenType(fname,str)
	String fname,str

//	String path = "entry:instrument:attenuator:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/attenuator"	//	
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



//////// INSTRUMENT/BEAM_MONITOR_NORM
//////// INSTRUMENT/BEAM_MONITOR_NORM
//////// INSTRUMENT/BEAM_MONITOR_NORM

Function writeBeamMonNorm_data(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:data"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "data"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



// fname is a local WORK folder
Function putBeamMonNorm_data(fname,val)
	String fname
	Variable val

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:beam_monitor_norm:data"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeBeamMonNormDistance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeBeamMonNormEfficiency(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:efficiency"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "efficiency"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


Function writeBeamMonNormSaved_count(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:saved_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "saved_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putBeamMonNormSaved_count(fname,val)
	String fname
	Variable val

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:beam_monitor_norm:saved_count"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeBeamMonNormType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_monitor_norm:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_monitor_norm"	//	
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



//////// INSTRUMENT/BEAM_STOP
//////// INSTRUMENT/BEAM_STOP
//////// INSTRUMENT/BEAM_STOP

Function writeBeamStop_description(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop"	//	
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeBeamStop_Dist_to_det(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop"	
	String varName = "distance_to_detector"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



Function writeBeamStop_x_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:x0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop"	
	String varName = "x_pos"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


// DONT DELETE THIS - it is new and needed 
//
Function putBeamStop_x_pos(fname,val)
	String fname
	Variable val


	String path = "root:Packages:"+fname+":"
	path += "entry:instrument:beam_stop:x_pos"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeBeamStop_y_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop"	
	String varName = "y_pos"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


// beam stop/shape


Function writeBeamStop_height(fname,val)
	String fname
	Variable val

	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop/shape"	
	String varName = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeBeamStop_shape(fname,str)
	String fname,str


	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop/shape"	//	
	String varName = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// this is diameter if shape=CIRCLE
Function writeBeamStop_size(fname,val)
	String fname
	Variable val

	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop/shape"	
	String varName = "size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// size in [cm]
Function putBeamStop_size(fname,val)
	String fname
	Variable val


	String path = "root:Packages:"+fname+":"
	path += "entry:instrument:beam_stop:shape:size"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeBeamStop_width(fname,val)
	String fname
	Variable val

	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop/shape"	
	String varName = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


//////// INSTRUMENT/COLLIMATOR
//////// INSTRUMENT/COLLIMATOR
//////// INSTRUMENT/COLLIMATOR

//collimator (data folder) -- this is a TEXT field
Function writeNumberOfGuides(fname,str)
	String fname,str

//	String path = "entry:instrument:collimator:number_guides"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/collimator"	
	String varName = "number_guides"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


//				geometry (data folder)
//					shape (data folder)
Function writeGuideShape(fname,str)
	String fname,str

//	String path = "entry:instrument:collimator:geometry:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/collimator/geometry/shape"	//	
	String varName = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// (DONE) -- this may need to be a wave to properly describe the dimensions
Function writeGuideSize(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:collimator:geometry:shape:size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/collimator/geometry/shape"	
	String varName = "size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



//////// INSTRUMENT/DETECTOR
//////// INSTRUMENT/DETECTOR
//////// INSTRUMENT/DETECTOR

Function writeDet_azimuthalAngle(fname,val)
	String fname
	Variable val

//		String path = "entry:instrument:detector:azimuthal_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector"	
		String varName = "azimuthal_angle"
		wTmpWrite[0] = val

		variable err
		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ",err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
		return(err)

End


// these are values in PIXELS
Function writeDet_beam_center_x(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:beam_center_x"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"
	String varName = "beam_center_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_x(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_x"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// these are values in mm
// fname is a local WORK folder
Function putDet_beam_center_x_mm(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_x_mm"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_x_pix(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x_pix
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_x_pix"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


// these are values in PIXELS
Function writeDet_beam_center_y(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:beam_center_y"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"
	String varName = "beam_center_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_y(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_y"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// these are values in mm
// fname is a local WORK folder
Function putDet_beam_center_y_mm(fname,val)
	String fname
	Variable val

//root:Packages:NIST:RAW:entry:instrument:detector:beam_center_y
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_y_mm"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// these are values in PIXELS
// fname is a local WORK folder
Function putDet_beam_center_y_pix(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y_pix
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:beam_center_y_pix"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetectorData(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:detector:data"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector"	
	String varName = "data"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter

//  the tube banks will be 1D arrays of values, one per tube
Function writeDetector_deadtime(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:detector_"+detStr+":dead_time"


	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector"	
	String varName = "dead_time"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
	
End

Function writeDetDescription(fname,str)
	String fname,str

//	String path = "entry:instrument:detector:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector"	//	
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// header stores value in [cm]
// patch panel is asking for value in [m] - so be sure to pass SDD [cm] to this function!
//
Function writeDet_distance(fname,val)
	String fname
	variable val

//	String path = "entry:instrument:detector:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putDet_distance(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:distance"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeDet_IntegratedCount(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:integrated_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "integrated_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putDet_IntegratedCount(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:integrated_count"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// this is only written for B and L/R detectors
Function writeDet_LateralOffset(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:lateral_offset"
		
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "lateral_offset"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putDet_LateralOffset(fname,val)
	String fname
	Variable val

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:detector:lateral_offset"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


// integer value
Function writeDet_numberOfTubes(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"

	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "number_of_tubes"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
	return(err)
End

/ (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function writeDet_pixel_fwhm_x(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:pixel_fwhm_x"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"
	String varName = "pixel_fwhm_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function writeDet_pixel_fwhm_y(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:pixel_fwhm_y"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"
	String varName = "pixel_fwhm_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// integer value
Function writeDet_pixel_num_x(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:pixel_nnum_x"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "pixel_num_x"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// integer value
Function writeDet_pixel_num_y(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:pixel_num_y"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "pixel_num_y"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


Function writeDet_polar_angle(fname,val)
	String fname
	Variable val

//		String path = "entry:instrument:detector:polar_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector"	
		String varName = "polar_angle"
		wTmpWrite[0] = val

		variable err
		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ",err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
		return(err)

End

Function writeDet_rotational_angle(fname,val)
	String fname
	Variable val

//		String path = "entry:instrument:detector:rotational_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector"	
		String varName = "rotational_angle"
		wTmpWrite[0] = val

		variable err
		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
		if(err)
			Print "HDF write err = ",err
		endif
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
		return(err)

End

Function writeDetSettings(fname,str)
	String fname,str

//	String path = "entry:instrument:detector:settings"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector"	//	
	String varName = "settings"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetTube_spatialCalib(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:detector:spatial_calibration"


	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector"
	String varName = "spatial_calibration"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
	return(err)
	
End

// (DONE) -- be clear on how this is defined. Units?
Function writeDet_tubeWidth(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:tube_width"

	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"
	String varName = "tube_width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
	return(err)
	
End


// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
//
// this is nothing that I use -- I use the tube width and spatial calibration
Function writeDetTube_xOffset(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:detector:x_offset"


	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector"
	String varName = "x_offset"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
	return(err)
	
End

Function writeDet_x_pixel_size(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:x_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "x_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End


// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
//
// this is nothing that I use -- I use the tube width and spatial calibration
Function writeDetTube_yOffset(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:detector:y_offset"


	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector"
	String varName = "y_offset"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
	return(err)
	
End



Function writeDet_y_pixel_size(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:detector:y_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector"	
	String varName = "y_pixel_size"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



Function writeDetEventFileName(fname,str)
	String fname,str

//	String path = "entry:instrument:event_file_name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "event_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


//////// INSTRUMENT/LENSES
//////// INSTRUMENT/LENSES
//////// INSTRUMENT/LENSES


Function writeLensCurvature(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:curvature"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "curvature"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeLensesFocusType(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:focus_type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "focus_type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeLensDistance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:lens_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeLensGeometry(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:lens_geometry"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_geometry"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeLensMaterial(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:lens_material"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_material"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// integer value
Function writeNumber_of_Lenses(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:number_of_lenses"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "number_of_lenses"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// integer value
Function writeNumber_of_prisms(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:number_of_prisms"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "number_of_prisms"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writePrism_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:prism_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "prism_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writePrismMaterial(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:prism_material"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "prism_material"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// status of lens/prism = lens | prism | both | out
Function writeLensPrismStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "status"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End
	


//////// INSTRUMENT/MONOCHROMATOR
//////// INSTRUMENT/MONOCHROMATOR
//////// INSTRUMENT/MONOCHROMATOR


// instrument/monochromator (data folder)
Function writeMonochromatorType(fname,str)
	String fname,str

//	String path = "entry:instrument:monochromator:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/monochromator"	//	
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:monochromator:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/monochromator"	
	String varName = "wavelength"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// fname is a local WORK folder
Function putWavelength(fname,val)
	String fname
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:instrument:monochromator:wavelength"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End


Function writeWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/monochromator"	
	String varName = "wavelength_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


////////////
// instrument/beam/monochromator/velocity_selector (data folder)
Function writeVSDistance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:monochromator:velocity_selector:distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/monochromator/velocity_selector"	
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeVSRotation_speed(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:monochromator:velocity_selector:rotation_speed"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/monochromator/velocity_selector"	
	String varName = "rotation_speed"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// not sure what this value actually means...
Function writeVS_table(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:instrument:monochromator:velocity_selector:table"	

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/monochromator/velocity_selector"	
	String varName = "table"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


//////// INSTRUMENT/SAMPLE_APERTURE
//////// INSTRUMENT/SAMPLE_APERTURE
//////// INSTRUMENT/SAMPLE_APERTURE


Function writeSampleAp_Description(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture"
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeSampleAp_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture"
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

//	sample_aperture/shape (data folder)
Function writeSampleAp_height(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture/shape"
	String varName = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeSampleAp_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture/shape"
	String varName = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeSampleAp_size(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture/shape"
	String varName = "size"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


// fname is a local WORK folder
Function putSampleAp_size(fname,str)
	String fname,str

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:sample_aperture:shape:size"
	
	Wave/Z/T w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = str
		return(0)
	endif

End



Function writeSampleAp_width(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture/shape"
	String varName = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End



//////// INSTRUMENT/SAMPLE_TABLE
//////// INSTRUMENT/SAMPLE_TABLE
//////// INSTRUMENT/SAMPLE_TABLE

		
// location  = "CHAMBER" or HUBER
Function writeSampleTableLocation(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_table:location"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_table"
	String varName = "location"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function writeSampleTableOffset(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_table:offset_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_table"
	String varName = "offset_distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End	


//////// INSTRUMENT/SOURCE
//////// INSTRUMENT/SOURCE
//////// INSTRUMENT/SOURCE

//name "NCNR"
Function writeSourceName(fname,str)
	String fname,str

//	String path = "entry:instrument:source:name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

//	power -- nominal only, not connected to any real number
Function writeReactorPower(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:source:power"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source"
	String varName = "power"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End	

//probe (wave) "neutron"
Function writeSourceProbe(fname,str)
	String fname,str

//	String path = "entry:instrument:source:probe"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "probe"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

//type (wave) "Reactor Neutron Source"
Function writeSourceType(fname,str)
	String fname,str

//	String path = "entry:instrument:source:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


//////// INSTRUMENT/SOURCE_APERTURE
//////// INSTRUMENT/SOURCE_APERTURE
//////// INSTRUMENT/SOURCE_APERTURE


Function writeSourceAp_Description(fname,str)
	String fname,str

//	String path = "entry:instrument:source_aperture:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source_aperture"
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// units of [cm]
Function writeSourceAp_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:source_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source_aperture"
	String varName = "distance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

// fname is a local WORK folder
Function putSourceAp_distance(fname,val)
	String fname
	Variable val

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:source_aperture:distance"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

//	shape (data folder)
Function writeSourceAp_height(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source_aperture/shape"
	String varName = "height"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End

Function writeSourceAp_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source_aperture/shape"
	String varName = "shape"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeSourceAp_size(fname,str)
	String fname,str

//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source_aperture/shape"
	String varName = "size"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// fname is a local WORK folder
Function putSourceAp_size(fname,str)
	String fname,str

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:source_aperture:shape:size"
	
	Wave/Z/T w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = str
		return(0)
	endif

End

Function writeSourceAp_width(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source_aperture/shape"
	String varName = "width"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
End




//////// ENTRY/PROGRAM_DATA
//////// ENTRY/PROGRAM_DATA
//////// ENTRY/PROGRAM_DATA

Function write_ProgramData_data(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/program_data"	//	
	String varName = "data"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end

Function write_ProgramData_description(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/program_data"	//	
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end

Function write_ProgramData_fileName(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/program_data"	//	
	String varName = "file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end

Function write_ProgramData_type(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/program_data"	//	
	String varName = "type"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end


//////// ENTRY/REDUCTION
//////// ENTRY/REDUCTION
//////// ENTRY/REDUCTION


// TODO -- needs to be a WAVE, and of the proper size and type!!!
Function writeAbsolute_Scaling(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:reduction:absolute_scaling"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/reduction"	
	String varName = "absolute_scaling"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeBackgroundFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:background_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "background_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


// (DONE) -- needs to be a WAVE
Function writeBoxCoordinates(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:reduction:box_coordinates"
		
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/reduction"	
	String varName = "box_coordinates"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



//box counts
Function writeBoxCounts(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:box_count"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "box_count"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

//box counts error
Function writeBoxCountsError(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:box_count_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "box_count_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeReductionComments(fname,str)
	String fname,str

//	String path = "entry:reduction:comments"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "comments"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeEmptyBeamFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:empty_beam_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "empty_beam_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeEmptyFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:empty_beam_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "empty_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeReduction_purpose(fname,str)
	String fname,str

//	String path = "entry:reduction:file_purpose"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "file_purpose"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



Function writeReductionIntent(fname,str)
	String fname,str

//	String path = "entry:reduction:intent"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "intent"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeMaskFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:empty_beam_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "mask_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



Function writeLogFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:sans_log_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "sans_log_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


Function writeSensitivityFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:sensitivity_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "sensitivity_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeTransmissionFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:transmission_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "transmission_file_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


//whole detector transmission
Function writeSampleTransWholeDetector(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:whole_trans"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "whole_trans"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

//whole detector transmission error
Function writeSampleTransWholeDetErr(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:whole_trans_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "whole_trans_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// TODO
// -- come up with a scheme to write the entire protocol to the data file?
// -- or a scheme to write just the missing bits?

// TODO -- needs to be a Text WAVE, and of the proper size and type!!!
//  -- this is a test where I write a wave to a field that does not exist...
Function writeReductionProtocolWave(fname,inTW)
	String fname
	Wave/T inTW
	
//	String path = "entry:reduction:absolute_scaling"
	
	Duplicate/O inTW wTTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/reduction"	
	String varName = "protocol"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


///// This is an added field, not part of the Nexus definition
//
// this is the associated file for transmission calculation
//
Function writeAssocFileSuffix(fname,str)
	String fname,str

//	String path = "entry:reduction:assoc_file_suffix"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "assoc_file_suffix"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// fname is a local WORK folder
// be sure to generate this if it does not exist since it is not part of the nexus definition
Function putAssocFileSuffix(fname,str)
	String fname,str

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:reduction:assoc_file_suffix"
	
	Wave/Z/T w = $path
	if(waveExists(w) == 0)
		Make/O/T/N=1 $path
		Wave/Z/T tw = $path
		tw[0] = str
		return(1)
	else
		w[0] = str
		return(0)
	endif

End


//////// ENTRY/SAMPLE
//////// ENTRY/SAMPLE
//////// ENTRY/SAMPLE

//no meaning to this field for our instrument
Function writeSample_equatorial_ang(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:equatorial_angle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "aequatorial_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


Function writeSample_changer(fname,str)
	String fname,str

//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "changer"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



//Sample position in changer
Function writeSamplePosition(fname,str)
	String fname,str

//	String path = "entry:sample:changer_position"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "changer_position"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


// sample label 
// (DONE): value of num is currently not used
Function writeSampleDescription(fname,str)
	String fname,str

//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// fname is a local WORK folder
Function putSampleDescription(fname,str)
	String fname,str

	String path = "root:Packages:NIST:"+fname+":"
	path += "entry:sample:description"
	
	Wave/Z/T w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = str
		return(0)
	endif

End



// for a z-stage??
Function writeSample_elevation(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:elevation"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "elevation"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



//
// (DONE) x- I need to make sure that this is an integer in the JSON definition
// 		x- currently a text value in the data file - see trac ticket
// x- this is also a duplicated field in the reduction block (reduction/group_id is no longer used)
//
// group ID !!! very important for matching up files
// integer value
//
Function writeSample_GroupID(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:group_id"	
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "group_id"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


Function writeSample_mass(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:group_id"	
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "mass"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


Function writeSample_name(fname,str)
	String fname,str

//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



//Sample Rotation Angle
Function writeSampleRotationAngle(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:rotation_angle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "rotation_angle"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

//?? this is huber/chamber??
// (DONE) -- then where is the description of 10CB, etc...
Function writeSampleHolderDescription(fname,str)
	String fname,str

//	String path = "entry:sample:sample_holder_description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "sample_holder_description"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End



//Sample Temperature
Function writeSampleTemperature(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:temperature"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "temperature"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


//Sample Temperature set point
Function writeSampleTempSetPoint(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:temperature_setpoint"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "temperature_setpoint"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


//Sample Thickness
// (DONE) -- somehow, this is not set correctly in the acquisition, so NaN results
Function writeSampleThickness(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:thickness"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "thickness"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// fname is a local WORK folder
Function putSampleThickness(fname,val)
	String fname
	Variable val

	String path = "root:Packages:"+fname+":"
	path += "entry:sample:thickness"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

//Sample Translation
Function writeSampleTranslation(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:translation"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "translation"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

// sample transmission
Function writeSampleTransmission(fname,val)
	String fname
	Variable val
	
	String path = "entry:sample:transmission"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "transmission"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// fname is a local WORK folder
Function putSampleTransmission(fname,val)
	String fname
	Variable val

	String path = "root:Packages:"+fname+":"
	path += "entry:sample:transmission"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

//transmission error (one sigma)
Function writeSampleTransError(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:transmission_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "transmission_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



////////// ENTRY/USER
////////// ENTRY/USER
////////// ENTRY/USER

// list of user names
// DONE -- currently not written out to data file??
Function writeUserNames(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/user"	//	
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
end










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

Function writeLog_attachedTo(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "attached_to"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


Function writeLog_measurement(fname,logStr,str)
	String fname,logStr,str

	String path = "entry:sample:"+logstr+":measurement"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "measurement"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


Function writeLog_Name(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
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
Function writeTempLog_ControlSensor(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":control_sensor"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "control_sensor"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

// for temperature only, logStr must be "temperature_env"
Function writeTempLog_MonitorSensor(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":monitor_sensor"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "monitor_sensor"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
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

Function writeTempLog_attachedTo(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:temperature_env:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "attached_to"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End


Function writeTempLog_highTrip(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":high_trip_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "high_trip_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_holdTime(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":hold_time"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "hold_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_lowTrip(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":low_trip_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "low_trip_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_measurement(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:temperature_env:"+logstr+":measurement"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "measurement"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeTempLog_model(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:temperature_env:"+logstr+":model"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "model"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeTempLog_name(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:temperature_env:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeTempLog_runControl(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":run_control"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "run_control"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_setPoint(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":setpoint"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "setpoint"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_shortName(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:temperature_env:"+logstr+":short_name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "short_name"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	if(err)
		Print "HDF write err = ",err
	endif
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
		
	return(err)
End

Function writeTempLog_timeout(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":timeout"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "timeout"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_tolerance(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":tolerance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "tolerance"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_toleranceBand(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":tolerance_band_time"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "tolerance_band_time"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeTempLog_Value(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:temperature_env:"+logstr+":value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/temperature_env/"+logStr
	String varName = "value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
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
//
/////////////////////////////////////
////		value_log (data folder)
//
// (DONE) -- 
Function writeLog_avgValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:average_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "average_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeLog_avgValue_err(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:average_value_error"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "average_value_error"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeLog_maximumValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:maximum_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "maximum_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeLog_medianValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:median_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "median_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end

Function writeLog_minimumValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:minimum_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "minimum_value"
	wTmpWrite[0] = val

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end



// TODO -- this needs to be a WAVE reference
// be sure this gets written as "time", even though it is read in as "time0"
Function writeLog_timeWave(fname,logStr,inW)
	String fname,logStr
	Wave inW
	
//	String path = "entry:sample:"+logstr+":value_log:time"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/sample/"+logStr+"/value_log"	
	String varName = "time"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end


// TODO -- this needs to be a WAVE reference
Function writeLog_ValueWave(fname,logStr,inW)
	String fname,logStr
	Wave inW
	
//	String path = "entry:sample:"+logstr+":value_log:value"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/sample/"+logStr+"/value_log"	
	String varName = "value"

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
	if(err)
		Print "HDF write err = ",err
	endif
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	if(err)
//		Print "DataFolder kill err = ",err
//	endif
	return(err)
end









				
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
