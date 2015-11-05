#pragma rtGlobals=3		// Use modern global access method and strict wave access.


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
Function proto_V_write_FP(str)
	String str
	return(0)
end
Function proto_V_write_FP2(str,str2)
	String str,str2
	return(0)
end
//Function proto_V_write_STR(str)
//	String str
//	return("")
//end

Function Test_V_write_FP(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_V_write_FP f = $item
		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_V_write_FP2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:1") //,VALTYPE:1 gives real return values, not strings
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
		FUNCREF proto_V_write_FP2 f = $item
		Print item ," = ", f(fname,detStr)
	endfor
	
	return(0)
end

Function Test_V_write_STR(str,fname)
	String str,fname
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:1,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_V_write_STR f = $item
		printf "%s = ",item
		sprintf strToEx,"Print %s(\"%s\")",item,fname
		Execute strToEx
//		print strToEx
//		Print item ," = ", f(fname)
	endfor
	
	return(0)
end

Function Test_V_write_STR2(str,fname,detStr)
	String str,fname,detStr
	
	Variable ii,num
	String list,item,strToEx
	
	
	list=FunctionList(str,";","NPARAMS:2,VALTYPE:4")
//	Print list
	num = ItemsInlist(list)
	
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list , ";")
	//	FUNCREF proto_V_write_STR f = $item
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
Function V_writeNeXus_version(fname,str)
	String fname,str
	
//	String path = "entry:NeXus_version"	
	
	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "NeXus_version"
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

// TODO -- not mine, added somewhere by Nexus writer?
// data collection time (! this is the true counting time??)
Function V_writeCollectionTime(fname,val)
	String fname
	Variable val
	
//	String path = "entry:collection_time"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry"	
	String varName = "collection_time"
	wTmpWrite[0] = val

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

// data directory where data files are stored (for user access, not archive)
Function V_writeData_directory(fname,str)
	String fname,str
	
//	String path = "entry:data_directory"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "data_directory"
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

// Base class of Nexus definition (=NXsas)
Function V_writeNexusDefinition(fname,str)
	String fname,str
	
//	String path = "entry:definition"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "definition"
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

// TODO -- not mine, added somewhere by Nexus writer?
// data collection duration (may include pauses, other "dead" time)
Function V_writeDataDuration(fname,val)
	String fname
	Variable val
	
	String path = "entry:duration"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry"	
	String varName = "duration"
	wTmpWrite[0] = val

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

// TODO -- not mine, added somewhere by Nexus writer?
// data collection end time
Function V_writeDataEndTime(fname,str)
	String fname,str
	
//	String path = "entry:end_time"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "end_time"
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

// experiment description
Function V_writeExperiment_description(fname,str)
	String fname,str
	
//	String path = "entry:experiment_description"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "experiment_description"
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

// experiment identifier? used only by NICE?
Function V_writeExperiment_identifier(fname,str)
	String fname,str
	
//	String path = "entry:experiment_identifier"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "experiment_identifier"
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

// name of facility = NCNR
Function V_writeFacility(fname,str)
	String fname,str
	
//	String path = "entry:facility"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "facility"
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
		
// file write time (what is this??)
// TODO - figure out if this is supposed to be an integer or text (ISO)
Function V_writeFileWriteTime(fname,val)
	String fname
	Variable val
	
	String path = "entry:file_time"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry"	
	String varName = "file_time"
	wTmpWrite[0] = val

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
		
//
Function V_writeHDF_version(fname,str)
	String fname,str
	
//	String path = "entry:hdf_version"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "hdf_version"
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

// TODO -- not mine, added somewhere by Nexus writer?
Function V_writeProgram_name(fname,str)
	String fname,str
	
//	String path = "entry:program_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "program_name"
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

// TODO -- not mine, added somewhere by Nexus writer?
// data collection start time
Function V_writeDataStartTime(fname,str)
	String fname,str
	
//	String path = "entry:start_time"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "start_time"
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
		
// title of experiment
Function V_writeTitle(fname,str)
	String fname,str
	
//	String path = "entry:title"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry"	//	
	String varName = "title"
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
end
	
	
		
////////// USER
////////// USER
////////// USER

// list of user names
// TODO -- currently not written out to data file??
Function V_writeUserNames(fname,str)
	String fname,str
	
//	String path = "entry:user:name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/user"	//	
	String varName = "name"
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
end


//////// CONTROL
//////// CONTROL
//////// CONTROL

// TODO -- for the control section, document each of the fields
//
Function V_writeCount_end(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_end"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_end"
	wTmpWrite[0] = val

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
end


Function V_writeCount_start(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_start"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_start"
	wTmpWrite[0] = val

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
end


Function V_writeCount_time(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_time"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_time"
	wTmpWrite[0] = val

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
end


Function V_writeCount_time_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:count_time_preset"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "count_time_preset"
	wTmpWrite[0] = val

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
end


Function V_writeDetector_counts(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:detector_counts"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "detector_counts"
	wTmpWrite[0] = val

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
end


Function V_writeDetector_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:detector_preset"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "detector_preset"
	wTmpWrite[0] = val

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
end


Function V_writeIntegral(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:integral"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "integral"
	wTmpWrite[0] = val

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
end

// control mode for data acquisition, "timer"
Function V_writeControlMode(fname,str)
	String fname,str
	
//	String path = "entry:control:mode"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/control"	//	
	String varName = "mode"
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

//monitor count
Function V_writeMonitorCount(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_counts"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "monitor_counts"
	wTmpWrite[0] = val

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
end

Function V_writeMonitor_preset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:monitor_preset"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "monitor_preset"
	wTmpWrite[0] = val

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
end

Function V_writePreset(fname,val)
	String fname
	Variable val
	
//	String path = "entry:control:preset"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/control"	
	String varName = "preset"
	wTmpWrite[0] = val

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
end





//////// INSTRUMENT
//////// INSTRUMENT
//////// INSTRUMENT

Function V_writeLocalContact(fname,str)
	String fname,str

//	String path = "entry:instrument:local_contact"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "local_contact"
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

Function V_writeInstrumentName(fname,str)
	String fname,str

//	String path = "entry:instrument:name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "name"
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

Function V_writeInstrumentType(fname,str)
	String fname,str

//	String path = "entry:instrument:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument"	//	
	String varName = "type"
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

////// INSTRUMENT/ATTENUATOR
// TODO
// attenuator number -- for VSANS I think I want this to be some "binary" representation 
// of 4 plates in/out - so this may be an integer-> binary, or a text string (4 char)
Function V_writeAtten_number(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:atten_number"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "atten_number"
	wTmpWrite[0] = val

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
end


// transmission value for the attenuator in the beam
// use this, but if something wrong, the tables are present
Function V_writeAttenuator_transmission(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:attenuator_transmission"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "attenuator_transmission"
	wTmpWrite[0] = val

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
end


// distance from the attenuator to the sample (units??)
Function V_writeAttenDistance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "distance"
	wTmpWrite[0] = val

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
end


// attenuator index, to use in the lookup table of transmission values
Function V_writeAttenIndex(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:index"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "index"
	wTmpWrite[0] = val

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
end


// table of the attenuation factor
Function V_writeAttenIndex_table(fname,inW)
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
end


// status "in or out"
Function V_writeAttenStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:attenuator:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/attenuator"	//	
	String varName = "status"
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

// thickness of the attenuator (PMMA) - units??
Function V_writeAttenThickness(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:attenuator:thickness"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/attenuator"	
	String varName = "thickness"
	wTmpWrite[0] = val

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
end


// type of material for the atteunator
Function V_writeAttenType(fname,str)
	String fname,str

//	String path = "entry:instrument:attenuator:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/attenuator"	//	
	String varName = "type"
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


////// INSTRUMENT/BEAM
// instrument/beam/chopper (data folder)
Function V_writeChopperAngular_opening(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:angular_opening"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "angular_opening"
	wTmpWrite[0] = val

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
end

Function V_writeChopDistance_from_sample(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:distance_from_sample"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "distance_from_sample"
	wTmpWrite[0] = val

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
end

Function V_writeChopDistance_from_source(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:distance_from_source"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "distance_from_source"
	wTmpWrite[0] = val

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
end

Function V_writeChopperDuty_cycle(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:duty_cycle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "duty_cycle"
	wTmpWrite[0] = val

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
end

Function V_writeChopperRotation_speed(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:rotation_speed"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "rotation_speed"
	wTmpWrite[0] = val

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
end

Function V_writeChopperSlits(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:chopper:slits"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/chopper"	
	String varName = "slits"
	wTmpWrite[0] = val

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
end

Function V_writeChopperstatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:chopper:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/chopper"	//	
	String varName = "status"
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

Function V_writeChoppertype(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:chopper:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/chopper"	//	
	String varName = "type"
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


// instrument/beam/flipper (data folder)
Function V_writeFlipperDriving_current(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:flipper:driving_current"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/flipper"	
	String varName = "driving_current"
	wTmpWrite[0] = val

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
end

Function V_writeFlipperFrequency(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:flipper:frequency"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/flipper"	
	String varName = "frequency"
	wTmpWrite[0] = val

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
end

Function V_writeFlipperstatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:flipper:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/flipper"	//	
	String varName = "status"
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

Function V_writeFlipperTransmitted_power(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:flipper:transmitted_power"	

	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/flipper"	
	String varName = "transmitted_power"
	wTmpWrite[0] = val

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
end

Function V_writeFlipperWaveform(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:flipper:waveform"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/flipper"	//	
	String varName = "waveform"
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

// instrument/beam/monochromator (data folder)
Function V_writeMonochromatorType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator"	//	
	String varName = "type"
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

Function V_writeWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator"	
	String varName = "wavelength"
	wTmpWrite[0] = val

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
end

Function V_writeWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator"	
	String varName = "wavelength_spread"
	wTmpWrite[0] = val

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
end

// instrument/beam/monochromator/crystal (data folder)
Function V_writeCrystalEnergy(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:energy"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "energy"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalHoriz_apert(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_aperture"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "horizontal_aperture"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalHoriz_curvature(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:horizontal_curvature"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "horizontal_curvature"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalLattice_parameter(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:lattice_parameter"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "lattice_parameter"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalnx_distance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:nx_distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "nx_distance"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalReflection(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:reflection"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "reflection"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalRotation(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:rotation"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "rotation"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:crystal:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/crystal"	//	
	String varName = "status"
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

Function V_writeCrystalVertical_aperture(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:vertical_aperture"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "vertical_aperture"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalVertical_curv(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:vertical_curvature"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "vertical_curvature"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "wavelength"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "wavelength_spread"
	wTmpWrite[0] = val

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
end

Function V_writeCrystalWavevector(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:crystal:wavevector"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/crystal"	
	String varName = "wavevector"
	wTmpWrite[0] = val

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
end

// instrument/beam/monochromator/velocity_selector (data folder)
Function V_writeVSnx_distance(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:nx_distance"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "nx_distance"
	wTmpWrite[0] = val

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
end

Function V_writeVSRotation_speed(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:rotation_speed"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "rotation_speed"
	wTmpWrite[0] = val

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
end

Function V_writeVelSelStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:velocity_selector:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	//	
	String varName = "status"
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

Function V_writeVSTable(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:table"	

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "table"

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
end

// TODO -- this is not the correct data type??? what does this mean??
Function V_writeVSTable_parameters(fname,val)
	String fname
	Variable val
	
	String path = "entry:instrument:beam:monochromator:velocity_selector:table_parameters"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "table_parameters"
	wTmpWrite[0] = val

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
end

Function V_writeVS_tilt(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:vs_tilt"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "vs_tilt"
	wTmpWrite[0] = val

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
end

Function V_writeVSWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "wavelength"
	wTmpWrite[0] = val

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
end

Function V_writeVSWavelength_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:velocity_selector:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/velocity_selector"	
	String varName = "wavelength_spread"
	wTmpWrite[0] = val

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
end

// instrument/beam/monochromator/white_beam (data folder)
Function V_writeWhiteBeamStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:monochromator:white_beam:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	//	
	String varName = "status"
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

Function V_writeWhiteBeamWavelength(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	
	String varName = "wavelength"
	wTmpWrite[0] = val

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
end

Function V_writeWhiteBeamWavel_spread(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:monochromator:white_beam:wavelength_spread"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/monochromator/white_beam"	
	String varName = "wavelength_spread"
	wTmpWrite[0] = val

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
end

// instrument/beam/polarizer (data folder)
Function V_writePolarizerComposition(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:polarizer:composition"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/polarizer"	//	
	String varName = "composition"
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

Function V_writePolarizerEfficiency(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:beam:polarizer:efficiency"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/polarizer"	
	String varName = "efficiency"
	wTmpWrite[0] = val

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
end

Function V_writePolarizerStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:polarizer:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/polarizer"	//	
	String varName = "status"
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

Function V_writePolarizerType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:polarizer:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/polarizer"	//	
	String varName = "type"
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

// instrument/beam/polarizer_analyzer (data folder)
Function V_writePolAnaCell_index(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam:polarizer_analyzer:cell_index"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	
	String varName = "cell_index"
	wTmpWrite[0] = val

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

Function V_writePolAnaCell_name(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:polarizer_analyzer:cell_name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	//	
	String varName = "cell_name"
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

Function V_writePolAnaCell_parameters(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:beam:polarizer_analyzer:cell_parameters"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument//beam/polarizer_analyzer"	
	String varName = "cell_parameters"

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

Function V_writePolAnaGuideFieldCur_1(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_1"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	
	String varName = "guide_field_current_1"
	wTmpWrite[0] = val

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

Function V_writePolAnaGuideFieldCur_2(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam:polarizer_analyzer:guide_field_current_2"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	
	String varName = "guide_field_current_2"
	wTmpWrite[0] = val

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

Function V_writePolAnaSolenoid_current(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam:polarizer_analyzer:solenoid_current"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	
	String varName = "solenoid_current"
	wTmpWrite[0] = val

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

Function V_writePolAnaStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:beam:polarizer_analyzer:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam/polarizer_analyzer"	//	
	String varName = "status"
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

					
/////// INSTRUMENT/BEAM MONITORS

//beam_monitor_low (data folder)
Function V_writeBeamMonLowData(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:data"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
	String varName = "data"
	wTmpWrite[0] = val

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

Function V_writeBeamMonLowEfficiency(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:efficiency"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
	String varName = "efficiency"
	wTmpWrite[0] = val

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

Function V_writeBeamMonLownx_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:nx_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
	String varName = "nx_distance"
	wTmpWrite[0] = val

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

Function V_writeBeamMonLowSaved_count(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_low:saved_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_low"	
	String varName = "saved_count"
	wTmpWrite[0] = val

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

Function V_writeBeamMonLowType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_monitor_low:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_monitor_low"	//	
	String varName = "type"
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

//beam_monitor_norm (data folder)
Function V_writeBeamMonNormData(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:data"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "data"
	wTmpWrite[0] = val

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

Function V_writeBeamMonNormEfficiency(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:efficiency"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "efficiency"
	wTmpWrite[0] = val

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

Function V_writeBeamMonNormnx_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:nx_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "nx_distance"
	wTmpWrite[0] = val

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

Function V_writeBeamMonNormSaved_count(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_monitor_norm:saved_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "saved_count"
	wTmpWrite[0] = val

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

Function V_writeBeamMonNormType(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_monitor_norm:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_monitor_norm"	//	
	String varName = "type"
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

//beam_stop (data folder)
Function V_writeBeamStopDescription(fname,str)
	String fname,str

//	String path = "entry:instrument:beam_stop:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/beam_stop"	//	
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

Function V_writeBeamStopDist_to_det(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:distance_to_detector"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_monitor_norm"	
	String varName = "distance_to_detector"
	wTmpWrite[0] = val

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

Function V_writeBeamStop_x0(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:x0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop"	
	String varName = "x0"
	wTmpWrite[0] = val

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

Function V_writeBeamStop_y0(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:beam_stop:y0"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/beam_stop"	
	String varName = "y0"
	wTmpWrite[0] = val

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

//// INSTRUMENT/COLLIMATOR
//collimator (data folder)
Function V_writeNumberOfGuides(fname,val)
	String fname
	Variable val
	
//	String path = "entry:instrument:collimator:number_guides"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/collimator"	
	String varName = "number_guides"
	wTmpWrite[0] = val

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

//				geometry (data folder)
//					shape (data folder)
Function V_writeGuideShape(fname,str)
	String fname,str

//	String path = "entry:instrument:collimator:geometry:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/collimator/geometry/shape"	//	
	String varName = "shape"
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

// TODO -- this may need to be a wave to properly describe the dimensions
Function V_writeGuideSize(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:collimator:geometry:shape:size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/collimator/geometry/shape"	
	String varName = "size"
	wTmpWrite[0] = val

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

//			converging_pinholes (data folder)
Function V_writeConvPinholeStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:converging_pinholes:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/converging_pinholes"	//	
	String varName = "status"
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

//			converging_slits (data folder)
Function V_writeConvSlitStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:converging_slits:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/converging_slits"	//	
	String varName = "status"
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


////// INSTRUMENT/DETECTORS
//			detector_B (data folder)
//
// only defined for the "B" detector, and may not be necessary?
// TODO -- write to return an ARRAY
Function V_writeDet_CALX(fname,detStr,inW)
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
		String varName = "CALX"

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
	else
		return(0)
	endif
End

// only defined for the "B" detector, and may not be necessary?
// TODO -- write to return an ARRAY
Function V_writeDet_CALY(fname,detStr,inW)
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
		String varName = "CALY"

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
	else
		return(0)
	endif
End

// TODO -- write and X and Y version of this. Pixels are not square
// so the FHWM will be different in each direction. May need to return
// "dummy" value for "B" detector if pixels there are square
Function V_writeDet_PixelFWHM(fname,detStr)
	String fname,detStr

	String path = "entry:instrument:detector_"+detStr+":PixelFWHM"

// TODO -- different behavior for "B"
	if(cmpstr(detStr,"B") == 0)
//		return(V_writeRealValueFromHDF5(fname,path))
		return(-99999)
	else
//		return(V_writeRealValueFromHDF5(fname,path))
		return(-99999)
	endif
End

Function V_writeDet_PixelNumX(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":PixelNumX"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "PixelNumX"
	wTmpWrite[0] = val

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

Function V_writeDet_PixelNumY(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":PixelNumY"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "PixelNumY"
	wTmpWrite[0] = val

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

// only defined for the "B" detector, and only to satisfy NXsas
Function V_writeDet_azimuthalAngle(fname,detStr,val)
	String fname,detStr
	Variable val

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":azimuthal_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "azimuthal_angle"
		wTmpWrite[0] = val

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
	else
		return(0)
	endif
End

Function V_writeDet_beam_center_x(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":beam_center_x"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "beam_center_x"
	wTmpWrite[0] = val

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

Function V_writeDet_beam_center_y(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":beam_center_y"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "beam_center_y"
	wTmpWrite[0] = val

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

// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_writeDetectorData(fname,detStr,inW)
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


// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
// ALSO -- the "B" deadtime will be a single value (probably)
//  but the tube banks will be 1D arrays of values, one per tube
Function V_writeDetector_deadtime(fname,detStr,inW)
	String fname,detStr
	Wave inW

//	String path = "entry:instrument:detector_"+detStr+":dead_time"
	
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "dead_time"

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


Function V_writeDetDescription(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
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

Function V_writeDet_distance(fname,detStr,val)
	String fname,detStr
	variable val

//	String path = "entry:instrument:detector_"+detStr+":distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "distance"
	wTmpWrite[0] = val

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

// only defined for the "B" detector, and only to satisfy NXsas
Function V_writeDet_equatorial_angle(fname,detStr,val)
	String fname,detStr
	variable val

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":equatorial_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "equatorial_angle"
		wTmpWrite[0] = val

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
	else
		return(0)
	endif
End

Function V_writeDetEventFileName(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":event_file_name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
	String varName = "event_file_name"
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

Function V_writeDet_IntegratedCount(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":integrated_count"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "integrated_count"
	wTmpWrite[0] = val

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

Function V_writeDet_LateralOffset(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":lateral_offset"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "lateral_offset"
	wTmpWrite[0] = val

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

// only defined for the "B" detector, and only to satisfy NXsas
Function V_writeDet_polar_angle(fname,detStr,val)
	String fname,detStr
	Variable val

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":polar_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "polar_angle"
		wTmpWrite[0] = val

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
	else
		return(0)
	endif
End

// only defined for the "B" detector, and only to satisfy NXsas
Function V_writeDet_rotational_angle(fname,detStr,val)
	String fname,detStr
	Variable val

	if(cmpstr(detStr,"B") == 0)
//		String path = "entry:instrument:detector_"+detStr+":rotational_angle"
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "rotational_angle"
		wTmpWrite[0] = val

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
	else
		return(0)
	endif
End

Function V_writeDetSettings(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":settings"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
	String varName = "settings"
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

// really has no meaning at all 
Function V_writeDet_size(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "size"
	wTmpWrite[0] = val

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

Function V_writeDetType(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:instrument:detector_"+detStr+":type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/detector_"+detStr	//	
	String varName = "type"
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

Function V_writeDet_x_pixel_size(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":x_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "x_pixel_size"
	wTmpWrite[0] = val

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

Function V_writeDet_y_pixel_size(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":y_pixel_size"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/detector_"+detStr	
	String varName = "y_pixel_size"
	wTmpWrite[0] = val

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

/////////			detector_FB (data folder) + ALL other PANEL DETECTORS

Function V_writeDet_numberOfTubes(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":number_of_tubes"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "number_of_tubes"
		wTmpWrite[0] = val

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
	endif
End

// TODO -- be clear on how this is defined. Separation as defined from what point? Units?
Function V_writeDetPanelSeparation(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":separation"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "separation"
		wTmpWrite[0] = val

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
	endif
End

// TODO -- write this function to return a WAVE with the data
// either as a wave reference, or as an input parameter
Function V_writeDetTube_spatialCalib(fname,detStr,inW)
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
	endif
End

// TODO -- be clear on how this is defined.
Function V_writeDet_tubeIndex(fname,detStr,val)
	String fname,detStr
	Variable val

//	String path = "entry:instrument:detector_"+detStr+":tube_index"
	if(cmpstr(detStr,"B") == 0)
		return(0)
	else
	
		Make/O/D/N=1 wTmpWrite
	//	Make/O/R/N=1 wTmpWrite
		String groupName = "/entry/instrument/detector_"+detStr	
		String varName = "tube_index"
		wTmpWrite[0] = val

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
	endif
End

Function V_writeDet_tubeOrientation(fname,detStr,str)
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

	endif
End

// TODO -- be clear on how this is defined. Units?
Function V_writeDet_tubeWidth(fname,detStr,val)
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
	endif
End

//////////////////////

// INSTRUMENT/LENSES 	/APERTURES
//  lenses (data folder)

Function V_writeLensCurvature(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:curvature"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "curvature"
	wTmpWrite[0] = val

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

Function V_writeLensesFocusType(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:focus_type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "focus_type"
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

Function V_writeLensDistance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:lens_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_distance"
	wTmpWrite[0] = val

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

Function V_writeLensGeometry(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:lens_geometry"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_geometry"
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

Function V_writeLensMaterial(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:lens_material"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "lens_material"
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

Function V_writeNumber_of_Lenses(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:number_of_lenses"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "number_of_lenses"
	wTmpWrite[0] = val

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

Function V_writeNumber_of_prisms(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:number_of_prisms"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "number_of_prisms"
	wTmpWrite[0] = val

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

Function V_writePrism_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:lenses:prism_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/lenses"
	String varName = "prism_distance"
	wTmpWrite[0] = val

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

Function V_writePrismMaterial(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:prism_material"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "prism_material"
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

// status of lens/prism = lens | prism | both | out
Function V_writeLensPrismStatus(fname,str)
	String fname,str

//	String path = "entry:instrument:lenses:status"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/lenses"
	String varName = "status"
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
	

///////  sample_aperture (data folder)

Function V_writeSampleAp_Description(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture"
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

Function V_writeSampleAp_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_aperture"
	String varName = "distance"
	wTmpWrite[0] = val

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
//	shape (data folder)

Function V_writeSampleAp_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_aperture/shape"
	String varName = "shape"
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

// TODO -- this needs to return a WAVE, since the shape may be circle, or rectangle
// and will need to return more than a single dimension
// TODO -- be careful of the UNITS
Function V_writeSampleAp_size(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:sample_aperture:shape:size"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/sample_aperture/shape"	
	String varName = "size"

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
		
//////  sample_table (data folder)
// location  = "CHAMBER" or HUBER
Function V_writeSampleTableLocation(fname,str)
	String fname,str

//	String path = "entry:instrument:sample_table:location"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/sample_table"
	String varName = "location"
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

// TODO - verify the meaning
//	offset_distance (?? for center of sample table vs. sample position)
Function V_writeSampleTableOffset(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:sample_table:offset_distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/sample_table"
	String varName = "offset_distance"
	wTmpWrite[0] = val

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
	
//  source (data folder)
//name "NCNR"
Function V_writeSourceName(fname,str)
	String fname,str

//	String path = "entry:instrument:source:name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "name"
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

//	power -- nominal only, not connected to any real number
Function V_writeReactorPower(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:source:power"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source"
	String varName = "power"
	wTmpWrite[0] = val

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

//probe (wave) "neutron"
Function V_writeSourceProbe(fname,str)
	String fname,str

//	String path = "entry:instrument:source:probe"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "probe"
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

//type (wave) "Reactor Neutron Source"
Function V_writeSourceType(fname,str)
	String fname,str

//	String path = "entry:instrument:source:type"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source"
	String varName = "type"
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

	
///////  source_aperture (data folder)

Function V_writeSourceAp_Description(fname,str)
	String fname,str

//	String path = "entry:instrument:source_aperture:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source_aperture"
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

Function V_writeSourceAp_distance(fname,val)
	String fname
	Variable val

//	String path = "entry:instrument:source_aperture:distance"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/instrument/source_aperture"
	String varName = "distance"
	wTmpWrite[0] = val

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
//	shape (data folder)

Function V_writeSourceAp_shape(fname,str)
	String fname,str

//	String path = "entry:instrument:source_aperture:shape:shape"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/instrument/source_aperture/shape"
	String varName = "shape"
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

// TODO -- this needs to return a WAVE, since the shape may be circle, or rectangle
// and will need to return more than a single dimension
// TODO -- be careful of the UNITS
Function V_writeSourceAp_size(fname,inW)
	String fname
	Wave inW

//	String path = "entry:instrument:source_aperture:shape:size"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/instrument/source_aperture/shape"	
	String varName = "size"

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




//////// SAMPLE
//////// SAMPLE
//////// SAMPLE

//Sample position in changer
// TODO -- in the NexusWriter, this ends up as a STRING -- which is wrong. it needs to be FP
Function V_writeSamplePosition(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:changer_position"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "changer_position"
	wTmpWrite[0] = val

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
end

// sample label 
// TODO: value of num is currently not used
Function V_writeSampleDescription(fname,str)
	String fname,str

//	String path = "entry:sample:description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
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

//no meaning to this...
Function V_writeSample_equatorial_ang(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:equatorial_angle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "equatorial_angle"
	wTmpWrite[0] = val

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
end

// TODO -- do  I need to make sure that this is an integer?
// group ID !!! very important for matching up files
Function V_writeSample_GroupID(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:group_id"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "group_id"
	wTmpWrite[0] = val

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
end


//Sample Rotation Angle
Function V_writeSampleRotationAngle(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:rotation_angle"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "rotation_angle"
	wTmpWrite[0] = val

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
end

//?? this is huber/chamber??
// TODO -- then where is the description of 10CB, etc...
Function V_writeSampleHolderDescription(fname,str)
	String fname,str

//	String path = "entry:sample:sample_holder_description"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample"
	String varName = "sample_holder_description"
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

//Sample Thickness
// TODO -- somehow, this is not set correctly in the acquisition, so NaN results
Function V_writeSampleThickness(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:thickness"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "thickness"
	wTmpWrite[0] = val

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
end

// sample transmission
Function V_writeSampleTransmission(fname,val)
	String fname
	Variable val
	
	String path = "entry:sample:transmission"	
//	String path = "QKK0037737:data:Transmission"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "transmission"
	wTmpWrite[0] = val

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
end

//transmission error (one sigma)
Function V_writeSampleTransError(fname,val)
	String fname
	Variable val
	
//	String path = "entry:sample:transmission_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample"
	String varName = "transmission_error"
	wTmpWrite[0] = val

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
end



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

Function V_writeLog_attachedTo(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":attached_to"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "attached_to"
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


Function V_writeLog_measurement(fname,logStr,str)
	String fname,logStr,str

	String path = "entry:sample:"+logstr+":measurement"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "measurement"
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


Function V_writeLog_Name(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":name"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr
	String varName = "name"
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


// TODO -- 
Function V_writeLog_nomValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr
	String varName = "value"
	wTmpWrite[0] = val

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
end

////		value_log (data folder)
Function V_writeLog_startTime(fname,logStr,str)
	String fname,logStr,str

//	String path = "entry:sample:"+logstr+":value_log:start"

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "start"
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

// TODO -- 
Function V_writeLog_avgValue(fname,logStr,val)
	String fname,logStr
	Variable val
	
//	String path = "entry:sample:"+logstr+":value_log:average_value"
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/sample/"+logStr+"/value_log"
	String varName = "average_value"
	wTmpWrite[0] = val

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
end

// TODO -- this needs to be a WAVE reference
Function V_writeLog_time(fname,logStr,inW)
	String fname,logStr
	Wave inW
	
//	String path = "entry:sample:"+logstr+":value_log:nx_time"

	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/sample/"+logStr+"/value_log"	
	String varName = "nx_time"

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
end


// TODO -- this needs to be a WAVE reference
Function V_writeLog_Value(fname,logStr,inW)
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
end



///////// REDUCTION
///////// REDUCTION
///////// REDUCTION


// TODO -- needs to be a WAVE, and of the proper size and type!!!
Function V_writeAbsolute_Scaling(fname,inW)
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
end

// TODO -- needs to be a WAVE
Function V_writeBoxCoordinates(fname,inW)
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
end

//box counts
Function V_writeBoxCounts(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:box_count"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "box_count"
	wTmpWrite[0] = val

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
end

//box counts error
Function V_writeBoxCountsError(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:box_count_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "box_count_error"
	wTmpWrite[0] = val

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
end

Function V_writeReductionComments(fname,str)
	String fname,str

//	String path = "entry:reduction:comments"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "comments"
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


Function V_writeReductionIntent(fname,str)
	String fname,str

//	String path = "entry:reduction:intent"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "intent"
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


Function V_writeLogFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:sans_log_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "sans_log_file_name"
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


Function V_writeSensitivityFileName(fname,str)
	String fname,str

//	String path = "entry:reduction:sensitivity_file_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction"
	String varName = "sensitivity_file_name"
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


//whole detector transmission
Function V_writeSampleTransWholeDetector(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:whole_trans"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "whole_trans"
	wTmpWrite[0] = val

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
end

//whole detector transmission error
Function V_writeSampleTransWholeDetErr(fname,val)
	String fname
	Variable val
	
//	String path = "entry:reduction:whole_trans_error"	
	
	Make/O/D/N=1 wTmpWrite
//	Make/O/R/N=1 wTmpWrite
	String groupName = "/entry/reduction"
	String varName = "whole_trans_error"
	wTmpWrite[0] = val

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
end

			
/////			pol_sans (data folder)

Function V_writePolSANS_cellName(fname,str)
	String fname,str

//	String path = "entry:reduction:pol_sans:cell_name"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction/pol_sans"
	String varName = "cell_name"
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


// TODO -- needs to be a WAVE
// is this a text wave?? if it's mixed names + values, then what?
Function V_writePolSANS_cellParams(fname,inW)
	String fname
	Wave inW
	
//	String path = "entry:reduction:pol_sans:cell_parameters"
		
	Duplicate/O inW wTmpWrite 	
// then use redimension as needed to cast the wave to write to the specified type
// see WaveType for the proper codes 
//	Redimension/T=() wTmpWrite
// -- May also need to check the dimension(s) before writing (don't trust the input)
	String groupName = "/entry/reduction/pol_sans"	
	String varName = "cell_parameters"

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
end

Function V_writePolSANS_PolSANSPurpose(fname,str)
	String fname,str

//	String path = "entry:reduction:pol_sans:pol_sans_purpose"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/reduction/pol_sans"
	String varName = "pol_sans_purpose"
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
Function V_writeDataImage(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:data_"+detStr+":thumbnail:data"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/data_"+detStr+"/thumbnail"
	String varName = "data"
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

Function V_writeDataImageDescription(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:data_"+detStr+":thumbnail:description"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/data_"+detStr+"/thumbnail"
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
								
Function V_writeDataImageType(fname,detStr,str)
	String fname,detStr,str

//	String path = "entry:data_"+detStr+":thumbnail:type"	

	Make/O/T/N=1 tmpTW
	String groupName = "/entry/data_"+detStr+"/thumbnail"
	String varName = "type"
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

