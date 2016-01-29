#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// Functions used for manipulation of the local Igor "WORK" folder
// structure as raw data is displayed and processed.
//
//



//
//Entry procedure from main panel
//
Proc CopyWorkFolder(oldType,newType)
	String oldType,newType
	Prompt oldType,"Source WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
	Prompt newType,"Destination WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
//	Prompt oldType,"Source WORK data type",popup,"AAA;BBB;CCC;DDD;EEE;FFF;GGG;"
//	Prompt newType,"Destination WORK data type",popup,"AAA;BBB;CCC;DDD;EEE;FFF;GGG;"

	// data folder "old" will be copied to "new" (and will overwrite)
	CopyHDFToWorkFolder(oldtype,newtype)
End

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
// TODO !!! DuplicateDataFolder will FAIL - in the base case of RAW data files, the
//  data is actually in use - so it will fail every time. need an alternate solution. in SANS,
// there are a limited number of waves to carry over, so Dupliate/O is used for rw, tw, data, etc.
//
//
//
// TODO : I also need a list of what is generated during processing that may be hanging around - that I need to
//     be sure to get rid of - like the calibration waves, solidAngle, etc.
//
// hdfDF is the name only of the data in storage. May be full file name with extension (clean as needed)
// type is the destination WORK folder for the copy
//
Function CopyHDFToWorkFolder(fromStr,toStr)
	String fromStr,toStr
	
	String fromDF, toDF
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:VSANS:"+fromStr
	toDF = "root:Packages:NIST:VSANS:"+toStr
	
//	// make a copy of the file name for my own use, since it's not in the file
//	String/G $(toDF+":file_name") = root:
	
	// copy the folders
	KillDataFolder/Z toDF			//DuplicateDataFolder will not overwrite, so Kill
	
	if(V_flag == 0)		// kill DF was OK
		DuplicateDataFolder $fromDF,$toDF
		
		// I can delete these if they came along with RAW
		//   DAS_logs
		//   top-level copies of data (duplicate links)
		KillDataFolder/Z $(toDF+":entry:entry:DAS_logs")
		KillDataFolder/Z $(toDF+":entry:entry:data")
		KillDataFolder/Z $(toDF+":entry:entry:data_B")
		KillDataFolder/Z $(toDF+":entry:entry:data_ML")
		KillDataFolder/Z $(toDF+":entry:entry:data_MR")
		KillDataFolder/Z $(toDF+":entry:entry:data_MT")
		KillDataFolder/Z $(toDF+":entry:entry:data_MB")
		KillDataFolder/Z $(toDF+":entry:entry:data_FL")
		KillDataFolder/Z $(toDF+":entry:entry:data_FR")
		KillDataFolder/Z $(toDF+":entry:entry:data_FT")
		KillDataFolder/Z $(toDF+":entry:entry:data_FB")

		return(0)
	else
		// need to do this the hard way, duplicate/O recursively
		// see V_CopyToWorkFolder()
		
		// everything on the top level
		V_DuplicateDataFolder($(toDF+":entry:entry"),fromStr,toStr,0,"",0)	//no recursion here
		// control
		V_DuplicateDataFolder($(toDF+":entry:entry:control"),fromStr,toStr,0,"",1)	//yes recursion here
		// instrument
		V_DuplicateDataFolder($(toDF+":entry:entry:instrument"),fromStr,toStr,0,"",1)	//yes recursion here
		// reduction
		V_DuplicateDataFolder($(toDF+":entry:entry:reduction"),fromStr,toStr,0,"",1)	//yes recursion here
		// sample
		V_DuplicateDataFolder($(toDF+":entry:entry:sample"),fromStr,toStr,0,"",1)	//yes recursion here

	endif	
	
	return(0)
end


////////
// see the help entry for IndexedDir for help on (possibly) how to do this faster
// -- see the function Function ScanDirectories(pathName, printDirNames)
//


// from IgorExchange On July 17th, 2011 jtigor
// started from "Recursively List Data Folder Contents"
// Posted July 15th, 2011 by hrodstein
//
//
//
Proc V_CopyToWorkFolder(dataFolderStr, fromStr, toStr, level, sNBName, recurse)
	String dataFolderStr="root:Packages:NIST:VSANS:RAW"
	String fromStr = "RAW"
	String toStr="SAM"
	Variable level=0
	String sNBName="DataFolderTree"
	Variable recurse = 1
	
	V_DuplicateDataFolder($dataFolderStr, fromStr, toStr, level, sNBName, recurse)


end

// ListDataFolder(dfr, level)
// Recursively lists objects in data folder.
// Pass data folder path for dfr and 0 for level.
// pass level == 0 for the first call
//  sNBName = "" prints nothing. any name will generate a notebook
//
// recurse == 0 will do only the specified folder, anything else will recurse all levels
// toStr is the string name of the top-level folder only, not the full path
//
//
Function V_DuplicateDataFolder(dfr, fromStr, toStr, level, sNBName,recurse)
	DFREF dfr
	String fromStr
	String toStr
	Variable level			// Pass 0 to start
 	String sNBName
 	Variable recurse
 
	String name
	String dfName
 	String sString
 	
 	String toDF = ""
 
	if (level == 0)		// this is the data folder, generate if needed in the destination
		name = GetDataFolder(1, dfr)
//		sPrintf sString, "%s (data folder)\r", name
		toDF = ReplaceString(fromStr,name,toStr,1)		// case-sensitive replace
		sprintf sString, "NewDataFolder/O %s\r",toDF
		NewDataFolder/O $(RemoveEnding(toDF,":"))			// remove trailing semicolon if it's there
		
		V_WriteBrowserInfo(sString, 1, sNBName)
	endif
 
 	dfName = GetDataFolder(1, dfr)
 	toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
	Variable i
 
	String indentStr = "\t"
	for(i=0; i<level; i+=1)
		indentStr += "\t"
	endfor
 
	Variable numWaves = CountObjectsDFR(dfr, 1)
	for(i=0; i<numWaves; i+=1)
		name = GetIndexedObjNameDFR(dfr, 1, i)
		//
		// wave type does not matter now. Duplicate does not care
		//
		sPrintf sString, "Duplicate/O  %s,  %s\r",dfName+name,toDF+name
		Duplicate/O $(dfName+name),$(toDF+name)
		
		V_WriteBrowserInfo(sString, 2, sNBName)
	endfor	
 
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 4, sNBName)
	endfor	

	if(recurse) 
		Variable numDataFolders = CountObjectsDFR(dfr, 4)	
		for(i=0; i<numDataFolders; i+=1)
			name = GetIndexedObjNameDFR(dfr, 4, i)
//			sPrintf sString, "%s%s (data folder)\r", indentStr, name
			 dfName = GetDataFolder(1, dfr)
			 
			toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
			sprintf sString, "NewDataFolder/O %s\r",toDF+name
			NewDataFolder/O $(toDF+name)
			
			
			V_WriteBrowserInfo(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			V_DuplicateDataFolder(childDFR, fromStr, toStr, level+1, sNBName, recurse)
		endfor	
	endif
	 
//when finished walking tree, save as RTF with dialog	
//	if(level == 0 && strlen(sNBName) != 0)
//		SaveNotebook /I /S=4  $sNBName
//	endif
End
 
Function V_WriteBrowserInfo(sString, vType, sNBName)
	String sString
	Variable vType
	String sNBName
 
	if(strlen(sNBName) == 0)
//		print sString
		return 0
	endif
	DoWindow $sNBName
	if(V_flag != 1)
		NewNoteBook/F=0 /N=$sNBName /V=1 as sNBName
	else
		DoWindow/F $sNBName
	endif
	Notebook $sNBName selection={endOfFile, endOfFile}
	if(vType == 1)		// a data folder
//		Notebook $sNBName fstyle=1
		Notebook $sNBName text=sString
//		Notebook $sNBName fstyle=-1
	else
		Notebook $sNBName text=sString	
	endif
 
End

///////////////////////////////


// given the folder, duplicate the data -> linear_data and generate the error
Function V_MakeDataError(folderStr)
	String folderStr
	
	SetDataFolder $folderStr
	Wave data=data
	Duplicate/O data linear_data			// at this point, the data is still the raw data, and is linear_data
	
	// proper error for counting statistics, good for low count values too
	// rather than just sqrt(n)
	// see N. Gehrels, Astrophys. J., 303 (1986) 336-346, equation (7)
	// for S = 1 in eq (7), this corresponds to one sigma error bars
	Duplicate/O linear_data linear_data_error
	linear_data_error = 1 + sqrt(linear_data + 0.75)				
	//
	
	SetDataFolder root:
	return(0)
End