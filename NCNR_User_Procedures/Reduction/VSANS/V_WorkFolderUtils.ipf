#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// Functions used for manipulation of the local Igor "WORK" folder
// structure as raw data is displayed and processed.
//
//




//
// copy what is needed for data processing (not the DAS_logs)
// from the RawVSANS storage folder to the local WORK folder as needed
//
// TODO -- at what stage do I make copies of data in linear/log forms for data display?
//			-- when do I make the 2D error waves?
//
// TODO - decide what exactly I need to copy over. May be best to copy all, and delete
//       what I know that I don't need
//
//
// hdfDF is the name only of the data in storage. May be full file name with extension (clean as needed)
// type is the destination WORK folder for the copy
//
Function CopyHDFToWorkFolder(hdfDF,type)
	String hdfDF,type
	
//	Printf "CopyHDFToWorkFolder(%s,%s) stub\r",hdfDF,type
	
	String loadedDF,fromDF, toDF
	// clean up the hdfDF to get a proper DF (same method as in file loader)
	loadedDF = StringFromList(0,hdfDF,".")
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:VSANS:RawVSANS:"+loadedDF+":entry"
	toDF = "root:Packages:NIST:VSANS:"+type+":entry"
	// copy the folders
	KillDataFolder/Z toDF			//DuplicateDataFolder will not overwrite, so Kill
	DuplicateDataFolder $fromDF,$toDF
	
	// make a copy of the file name for my own use, since it's not in the file
	String/G $(toDF+":file_name") = hdfDF
	
	// ***need to copy folders:
	// control
	// instrument
	// reduction
	// sample
	
	// ***what about the variables @ the top level?
	// data directory, identifiers, etc.?
	
	// ***I can skip (or delete)
	// DAS_logs
	// top-level copies of data (duplicate links)
	KillDataFolder/Z $(toDF+":DAS_logs")
	KillDataFolder/Z $(toDF+":data")
	KillDataFolder/Z $(toDF+":data_B")
	KillDataFolder/Z $(toDF+":data_ML")
	KillDataFolder/Z $(toDF+":data_MR")
	KillDataFolder/Z $(toDF+":data_MT")
	KillDataFolder/Z $(toDF+":data_MB")
	KillDataFolder/Z $(toDF+":data_FL")
	KillDataFolder/Z $(toDF+":data_FR")
	KillDataFolder/Z $(toDF+":data_FT")
	KillDataFolder/Z $(toDF+":data_FB")

	
	return(0)
end



//
// copy from one local WORK folder to another
// does NO rescaling of the data or any other modifications to data
//
// TODO -- do I need to do more to clean out the destination folder first?
//
//  CopyWorkToWorkFolder("RAW","EMP")
//
Function CopyWorkToWorkFolder(fromDF,toDF)
	String fromDF,toDF
	
//	Printf "CopyWorkToWorkFolder(%s,%s) stub\r",fromDF,toDF
	
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:VSANS:"+fromDF+":entry"
	toDF = "root:Packages:NIST:VSANS:"+toDF+":entry"
	// copy the folders
	KillDataFolder/Z toDF			//DuplicateDataFolder will not overwrite, so Kill
	DuplicateDataFolder $fromDF,$toDF
	
	return(0)
end
