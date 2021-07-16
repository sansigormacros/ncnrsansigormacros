#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


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
//Function writeNeXus_version(fname,str)
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


// file name
Function writeFile_name(fname,str)
	String fname,str
	
//	String path = "entry:file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
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
End

	
//// file write time (what is this??)
//// TODO - figure out if this is supposed to be an integer or text (ISO)
//Function writeFileWriteTime(fname,val)
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
//End
		
//
Function writeHDF_version(fname,str)
	String fname,str
	
//	String path = "entry:hdf_version"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "hdf_version"
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
	
	
		
////////// USER
////////// USER
////////// USER

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
	String path = "root:Packages:NIST:VSANS:"+fname+":"
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
Function writeIntegral(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:integral"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "integral"
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

Function writeControlPreset(fname,str)
	String fname,str
	
//	String path = "entry:control:preset"
		
	Make/O/T/N=1 tmpTW
	String groupName = "/entry/control"	
	String varName = "preset"
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





//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

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
// (DONE) - verify the format of how these are written out to the file
//

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


//// status "in or out"
//Function writeAttenStatus(fname,str)
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

//// number of attenuators actually dropped in
//// an integer value
Function writeAtten_num_dropped(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:thickness"	
	
	Make/O/I/N=1 wTmpWrite
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


////////////
// new back polarizer calls
// JUN 2020
// since the location of the original ones that were decided on have changed
// wihtout my knowledge
//

////// INSTRUMENT
//
Function writeBackPolarizer_depth(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:depth"

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "depth"
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

Function writeBackPolarizer_direction(fname,str)
	String fname,str

//	String path = "entry:instrument:backPolarizer:direction"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/backPolarizer"	//	
	String varName = "direction"
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

Function writeBackPolarizer_height(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:height"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
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
end

// ?? TODO is this equivalent to "status" -- is this 0|1 ??
Function writeBackPolarizer_inBeam(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:inBeam"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "inBeam"
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

Function writeBackPolarizer_innerRad(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:innerRadius"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "innerRadius"
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

// one of the most important
Function writeBackPolarizer_name(fname,str)
	String fname,str

//	String path = "entry:instrument:backPolarizer:name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/backPolarizer"	//	
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

Function writeBackPolarizer_opac1A(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:opacityAt1Ang"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "opacityAt1Ang"
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

Function writeBackPolarizer_opac1A_err(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:opacityAt1AngStd"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "opacityAt1AngStd"
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

Function writeBackPolarizer_outerRad(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:outerRadius"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "outerRadius"
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

Function writeBackPolarizer_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:backPolarizer:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/backPolarizer"	//	
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

Function writeBackPolarizer_tE(fname,val)
	String fname
	Variable val
		
//	String path = "entry:instrument:backPolarizer:tE"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "tE"
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

Function writeBackPolarizer_tE_err(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:tEStd"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "tEStd"
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

Function writeBackPolarizer_type(fname,str)
	String fname,str

//	String path = "entry:instrument:backPolarizer:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/backPolarizer"	//	
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


Function writeBackPolarizer_timestamp(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:timestamp"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
	String varName = "timestamp"
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


Function writeBackPolarizer_width(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:backPolarizer:width"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/backPolarizer"	
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
end




////////////////////////////////////////////////////////////////////////////////



//////// INSTRUMENT/BEAM
////
//Function writeAnalyzer_depth(fname,val)
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
//Function writeAnalyzer_direction(fname,str)
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
//Function writeAnalyzer_height(fname,val)
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
//// ?? TODO is this equivalent to "status" -- is this 0|1 ??
//Function writeAnalyzer_inBeam(fname,val)
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
//Function writeAnalyzer_innerDiameter(fname,val)
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
//// one of the most important
//Function writeAnalyzer_name(fname,str)
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
//Function writeAnalyzer_opacityAt1Ang(fname,val)
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
//Function writeAna_opacityAt1Ang_err(fname,val)
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
//Function writeAnalyzer_outerDiameter(fname,val)
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
//Function writeAnalyzer_shape(fname,str)
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
//Function writeAnalyzer_tE(fname,val)
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
//Function writeAnalyzer_tE_err(fname,val)
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
//Function writeAnalyzer_type(fname,str)
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
//Function writeAnalyzer_width(fname,val)
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





// instrument/beam/chopper (data folder)
Function writeChopperAngular_opening(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:angular_opening"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "angular_opening"
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

Function writeChopDistance_from_sample(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:distance_from_sample"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "distance_from_sample"
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

Function writeChopDistance_from_source(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:distance_from_source"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "distance_from_source"
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

Function writeChopperDuty_cycle(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:duty_cycle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "duty_cycle"
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

Function writeChopperRotation_speed(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:rotation_speed"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
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

// integer value
Function writeChopperSlits(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:slits"	
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "slits"
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

Function writeChopperstatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:chopper:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/chopper"	//	
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

Function writeChoppertype(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:chopper:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/chopper"	//	
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



// are these the correct locations in the header for polarization?
// they are what is in the example polarized beam data I was given in 2019
// but don't match what was decided for the data file. Nobody ever
// told me of any changes, so I guess I'm out of the loop as usual.

// the FRONT FLIPPER
// JUN 2020 -- added these calls


Function writeFrontFlipper_Direction(fname,str)
	String fname,str

//	String path = "entry:instrument:frontFlipper:direction"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/frontFlipper"	//	
	String varName = "direction"
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

Function writeFrontFlipper_flip(fname,str)
	String fname,str

//	String path = "entry:instrument:frontFlipper:flip"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/frontFlipper"	//	
	String varName = "flip"
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

Function writeFrontFlipper_Power(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:frontFlipper:power"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/frontFlipper"	
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
end


Function writeFrontFlipper_type(fname,str)
	String fname,str

//	String path = "entry:instrument:frontFlipper:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/frontFlipper"	//	
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






///////////////
// instrument/beam/flipperPolarizer (data folder)
// this is upstream, after the supermirror but before the sample
//
//Function writeflipperPol_Direction(fname,str)
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
//Function writeflipperPolarizer_inBeam(fname,val)
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
//Function writeflipperPolarizer_Type(fname,str)
//	String fname,str
//
////	String path = "entry:instrument:beam:flipperPolarizer:type"
//	Make/O/T/N=1 tmpTW
//	String groupName = "/entry/instrument/beam/flipperPolarizer"	//	
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



//////////
//// instrument/beam/flipper (data folder)
//Function writeFlipperDriving_current(fname,val)
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
//Function writeFlipperFrequency(fname,val)
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
//Function writeFlipperstatus(fname,str)
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
//Function writeFlipperTransmitted_power(fname,val)
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
//Function writeFlipperWaveform(fname,str)
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



// instrument/beam/monochromator (data folder)
Function writeMonochromatorType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator"	//	
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
	
//	String path = "entry:instrument:beam:monochromator:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator"	
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

Function writeWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator"	
	String varName = "wavelength_spread"
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






// instrument/beam/monochromator/crystal (data folder)
//
Function writeCrystalDistance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
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

Function writeCrystalEnergy(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:energy"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "energy"
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

Function writeCrystalHoriz_apert(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_aperture"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "horizontal_aperture"
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

Function writeCrystalHoriz_curvature(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_curvature"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "horizontal_curvature"
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

Function writeCrystalLattice_parameter(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:lattice_parameter"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "lattice_parameter"
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


Function writeCrystalReflection(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:reflection"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "reflection"
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

Function writeCrystalRotation(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:rotation"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "rotation"
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

Function writeCrystalStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:crystal:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/crystal"	//	
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

Function writeCrystalVertical_aperture(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:vertical_aperture"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "vertical_aperture"
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

Function writeCrystalVertical_curv(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:vertical_curvature"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "vertical_curvature"
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

Function writeCrystalWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
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

Function writeCrystalWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "wavelength_spread"
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

Function writeCrystalWavevector(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavevector"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "wavevector"
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
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
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
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:rotation_speed"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
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

Function writeVelSelStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:velocity_selector:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	//	
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

Function writeVSTable_parameters(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:table"	

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "table_parameters"

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

//// DONE - this does not exist for VSANS - per JGB 4/2016
//Function writeVS_tilt(fname,val)
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

Function writeVSWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
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

Function writeVSWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "wavelength_spread"
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

// instrument/beam/monochromator/white_beam (data folder)
Function writeWhiteBeamStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:white_beam:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	//	
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

Function writeWhiteBeamWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	
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

Function writeWhiteBeamWavel_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	
	String varName = "wavelength_spread"
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

// instrument/beam/superMirror (data folder)
// This is the upstream polarizer. There are no other choices for polarizer on VSANS
Function writePolarizerComposition(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:superMirror:composition"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/superMirror"	//	
	String varName = "composition"
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

Function writePolarizerEfficiency(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:superMirror:efficiency"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/superMirror"	
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

Function writePolarizerState(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:superMirror:state"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/superMirror"	//	
	String varName = "state"
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

//Function writePolarizerType(fname,str)
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
//// instrument/beam/polarizer_analyzer (data folder)
//// integer value
//Function writePolAnaCell_index(fname,val)
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
//End
//
//Function writePolAnaCell_name(fname,str)
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
//Function writePolAnaCell_parameters(fname,inW)
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
//End
//
//Function writePolAnaGuideFieldCur_1(fname,val)
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
//End
//
//Function writePolAnaGuideFieldCur_2(fname,val)
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
//End
//
//Function writePolAnaSolenoid_current(fname,val)
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
//End
//
//Function writePolAnaStatus(fname,str)
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




					
/////// INSTRUMENT/BEAM MONITORS

//beam_monitor_low (data folder)
// integer value
Function writeBeamMonLowData(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:data"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
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

Function writeBeamMonLowDistance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
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

Function writeBeamMonLowEfficiency(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:efficiency"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
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

Function writeBeamMonLowSaved_count(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:saved_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
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

Function writeBeamMonLowType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_monitor_low:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_monitor_low"	//	
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

//beam_monitor_norm (data folder)
// integer value
Function writeBeamMonNormData(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:data"
	
	Make/O/I/N=1 wTmpWrite
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
Function putBeamMonNormData(fname,val)
	String fname
	Variable val

	String path = "root:Packages:NIST:VSANS:"+fname+":"
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


//beam_stop C2 (data folder)
Function writeBeamStopC2Description(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop_C2"	//	
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

Function writeBeamStopC2Dist_to_det(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2"	
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

// is this the index of which size beam stop is in position?
// integer value
Function writeBeamStopC2num_stop(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2"	
	String varName = "num_beamstops"
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

Function writeBeamStopC2_x_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:x0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2"	
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

Function writeBeamStopC2_y_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2"	
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


// beam stop C2 (shape)
Function writeBeamStopC2_height(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2/shape"	
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

Function writeBeamStopC2_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop_C2/shape"	//	
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
Function writeBeamStopC2_size(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2/shape"	
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

Function writeBeamStopC2_width(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C2/shape"	
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

// beam stop C3 (data folder)
Function writeBeamStopC3Description(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop_C3"	//	
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

Function writeBeamStopC3Dist_to_det(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3"	
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

// integer value
Function writeBeamStopC3num_stop(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3"	
	String varName = "num_beamstops"
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

Function writeBeamStopC3_x_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:x0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3"	
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

Function writeBeamStopC3_y_pos(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3"	
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


// beam stop C3 (shape)
Function writeBeamStopC3_height(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3/shape"	
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

Function writeBeamStopC3_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop_C3/shape"	//	
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
Function writeBeamStopC3_size(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3/shape"	
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

Function writeBeamStopC3_width(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop_C3/shape"	
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



//// INSTRUMENT/COLLIMATOR
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

//			converging_pinholes (data folder)
Function writeConvPinholeStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:converging_pinholes:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/converging_pinholes"	//	
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

//			converging_slits (not used)






////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// (DONE) -- write to return an ARRAY
Function writeDet_cal_x(fname,detStr,inW)
	String fname,detStr
	Wave inW

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":CALX"
		
		Duplicate/O inW wTmpWrite 	
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes 
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "cal_x"

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
	else
		return(0)
	endif
End

// only defined for the "B" detector, and may not be necessary?
// (DONE) -- write to return an ARRAY
Function writeDet_cal_y(fname,detStr,inW)
	String fname,detStr
	Wave inW

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":CALY"

		Duplicate/O inW wTmpWrite 	
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes 
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "cal_y"

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
	else
		return(0)
	endif
End

// (DONE) -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function writeDet_pixel_fwhm_x(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_x"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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
Function writeDet_pixel_fwhm_y(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":pixel_fwhm_y"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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
Function writeDet_pixel_num_x(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":pixel_nnum_x"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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
Function writeDet_pixel_num_y(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":pixel_num_y"
	
	Make/O/I/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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

//// only defined for the "B" detector, and only to satisfy NXsas
//Function writeDet_azimuthalAngle(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function writeDet_beam_center_x(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":beam_center_x"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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

// fname is a local WORK folder
Function putDet_beam_center_x(fname,detStr,val)
	String fname,detStr
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:VSANS:"+fname+":"
	path += "entry:instrument:detector_"+detStr+":beam_center_x"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// fname is a local WORK folder
Function putDet_beam_center_x_pix(fname,detStr,val)
	String fname,detStr
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x_pix
	String path = "root:Packages:NIST:VSANS:"+fname+":"
	path += "entry:instrument:detector_"+detStr+":beam_center_x_pix"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

Function writeDet_beam_center_y(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":beam_center_y"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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


// fname is a local WORK folder
Function putDet_beam_center_y(fname,detStr,val)
	String fname,detStr
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y
	String path = "root:Packages:NIST:VSANS:"+fname+":"
	path += "entry:instrument:detector_"+detStr+":beam_center_y"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// fname is a local WORK folder
Function putDet_beam_center_y_pix(fname,detStr,val)
	String fname,detStr
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_y_pix
	String path = "root:Packages:NIST:VSANS:"+fname+":"
	path += "entry:instrument:detector_"+detStr+":beam_center_y_pix"
	
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
Function writeDetectorData(fname,detStr,inW)
	String fname,detStr
	Wave inW

//	String path = "entry:instrument:detector_"+detStr+":data"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector_"+detStr	
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



/////////////////////////


// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function writeDetector_deadtime(fname,detStr,inW)
	String fname,detStr
	Wave inW

//	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr,"B") == 0)
		DoAlert 0,"Bad call to writeDetector_deadtime"
		return(0)
	else

		Duplicate/O inW wTmpWrite 	
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes 
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
		String groupName = "/entry/instrument/detector_"+detStr	
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
	endif
End

// dead time, a single value, only for detB
Function writeDetector_deadtime_B(fname,detStr,val)
	String fname,detStr
	variable val

//	String path = "entry:instrument:detector_"+detStr+":dead_time"
	if(cmpstr(detStr,"B") == 0)
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "dead_time"
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
	else
		DoAlert 0,"Bad call to writeDetector_deadtime_B"
		return(0)
	endif
End

// high res detector gain, a single value, only for detB
Function writeDetector_highResGain(fname,detStr,val)
	String fname,detStr
	variable val

//	String path = "entry:instrument:detector_"+detStr+":highResGain"
	if(cmpstr(detStr,"B") == 0)
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "highResGain"
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
	else
		DoAlert 0,"Bad call to writeDetector_highResGain"
		return(0)
	endif
End


Function writeDetDescription(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
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

Function writeDet_distance(fname,detStr,val)
	String fname,detStr
	variable val

//	String path = "entry:instrument:detector_"+detStr+":distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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

//// only defined for the "B" detector, and only to satisfy NXsas
//Function writeDet_equatorial_angle(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function writeDetEventFileName(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":event_file_name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
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

Function writeDet_IntegratedCount(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":integrated_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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
Function putDet_IntegratedCount(fname,detStr,val)
	String fname,detStr
	Variable val

//root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:beam_center_x
	String path = "root:Packages:NIST:VSANS:"+fname+":"
	path += "entry:instrument:detector_"+detStr+":integrated_count"
	
	Wave/Z w = $path
	if(waveExists(w) == 0)
		return(1)
	else
	w[0] = val
		return(0)
	endif

End

// this is only written for B and L/R detectors
Function writeDet_LateralOffset(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":lateral_offset"

	if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
		return(0)
	endif	
		
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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


// this is only written for T/B detectors
Function writeDet_VerticalOffset(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":vertical_offset"

	if(cmpstr(detStr,"B") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		return(0)
	endif	
		
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "vertical_offset"
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


// (DONE) - be sure that this is defined correctly
// -- it needs to exist in the data file, and only for TB detector panels
Function writeDet_TBSetback(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":setback"
	
	if(cmpstr(detStr,"B") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"FR") == 0 || cmpstr(detStr,"FL") == 0)
		return(0)
	endif
	if(cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"ML") == 0)
		return(0)
	endif	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "setback"
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

// gap when panels are "touching"
// units are mm
// writes panel gap for detector panel specified
// does not write anything if "B" is passed (no such field for this detector)
//
Function writeDet_panel_gap(fname,detStr,val)
	String fname,detStr
	Variable val

	if(cmpstr(detStr,"B") == 0)
		return(0)
	endif
	
//	String path = "entry:instrument:detector_"+detStr+":panel_gap"

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "panel_gap"
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



//// only defined for the "B" detector, and only to satisfy NXsas
//Function writeDet_polar_angle(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

//// only defined for the "B" detector, and only to satisfy NXsas
//Function writeDet_rotational_angle(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	else
//		return(0)
//	endif
//End

Function writeDetSettings(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":settings"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
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

//// really has no meaning at all 
//Function writeDet_size(fname,detStr,val)
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
//End

//Function writeDetType(fname,detStr,str)
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

Function writeDet_x_pixel_size(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":x_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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

Function writeDet_y_pixel_size(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":y_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
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

/////////			detector_FB (data folder) + ALL other PANEL DETECTORS

// integer value
Function writeDet_numberOfTubes(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
	
		Make/O/I/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
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
	endif
End

// deleted from definition
//Function writeDetPanelSeparation(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	endif
//End

// (DONE) -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function writeDetTube_spatialCalib(fname,detStr,inW)
	String fname,detStr
	Wave inW

//	String path = "entry:instrument:detector_"+detStr+":spatial_calibration"

	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		Duplicate/O inW wTmpWrite 	
	// then use redimension as needed to cast the wave to write to the specified type
	// see WaveType for the proper codes 
	//	Redimension/T=() wTmpWrite
	// -- May also need to check the dimension(s) before writing (don't trust the input)
		String groupName = "/entry/instrument/detector_"+detStr	
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
	endif
End

//// (DONE) -- be clear on how this is defined.
//Function writeDet_tubeIndex(fname,detStr,val)
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
//		err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//		if(err)
//			Print "HDF write err = ",err
//		endif
//		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
////		err = KillNamedDataFolder(fname)
////		if(err)
////			Print "DataFolder kill err = ",err
////		endif
//		return(err)
//	endif
//End

Function writeDet_tubeOrientation(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":tube_orientation"

	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
		Make/O/T/N=1 tmpTW
		String groupName = "/entry/instrument/detector_"+detStr	//	
		String varName = "tube_orientation"
		tmpTW[0] = str //

		variable err
		err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
		if(err)
			Print "HDF write err = ",err
		endif
	
		// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//		err = KillNamedDataFolder(fname)
//		if(err)
//			Print "DataFolder kill err = ",err
//		endif
		
		return(err)

	endif
End

// (DONE) -- be clear on how this is defined. Units?
Function writeDet_tubeWidth(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":tube_width"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
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
	endif
End

//////////////////////

// INSTRUMENT/LENSES 	/APERTURES
//  lenses (data folder)

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
	

///////  sample_aperture (1) (data folder)
// this is the INTERNAL sample aperture
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

//	sample_apertuer/shape (data folder)
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

///////  sample_aperture_2 (data folder)
// sample aperture (2) is the external aperture, which may or may not be present

Function writeSampleAp2_Description(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture_2:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture_2"
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

Function writeSampleAp2_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture_2:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture_2"
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


//	shape (data folder)
Function writeSampleAp2_height(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture_2/shape"
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

Function writeSampleAp2_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture_2:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture_2/shape"
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

Function writeSampleAp2_size(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture_2/shape"
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

Function writeSampleAp2_width(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture_2/shape"
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

		
//////  sample_table (data folder)
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
	
//  source (data folder)
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

	
///////  source_aperture (data folder)

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


//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

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

	String path = "root:Packages:NIST:VSANS:"+fname+":"
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

//no meaning to this...
Function writeSample_equatorial_ang(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:equatorial_angle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "equatorial_angle"
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








///////// REDUCTION
///////// REDUCTION
///////// REDUCTION


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


// this is a NON NICE entered field
//
// this is a flag to mark the file as "flipped" so it prevents a 2nd flip
// if the flip has been done, the field is written with a value of 1 (= true)
//
// to "un-mark" the file and allow the flip to be re-done, write -999999
Function writeLeftRightFlipDone(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:left_right_flip"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "left_right_flip"
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

// THIS IS A NON-NICE ENTERED FIELD
// -- this is the panel string where the box coordinates refer to (for the open beam and transmission)
Function writeReduction_BoxPanel(fname,str)
	String fname,str

//	String path = "entry:reduction:comments"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "box_panel"
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

// DONE x- commented out, not to be used
//  x- is this duplicated? - yes - this is duplicated in /entry/sample
//  x- so I need to pick a location, or be sure to fix it in both places
//Function writeReduction_group_ID(fname,val)
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

			
///////			pol_sans (data folder)
//
//Function writePolSANS_cellName(fname,str)
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
//// TODO -- needs to be a WAVE
//// is this a text wave?? if it's mixed names + values, then what?
//Function writePolSANS_cellParams(fname,inW)
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
//Function writePolSANS_PolSANSPurpose(fname,str)
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
