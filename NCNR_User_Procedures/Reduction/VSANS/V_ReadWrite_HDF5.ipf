#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Start to build up and test the r/w accessors for VSANS
// (SANS has a template, VSANS does not, so just start from scratch here, since the 
// file structure will be different)
//
//


// passing null file string presents a dialog
Macro Read_HDF5_Raw_No_Attributes()
	V_LoadHDF5Data("")
End

Proc V_LoadHDF5Data(file)
	String file

	SetDataFolder root:	
	Variable err= V_LoadHDF5_NoAtt(file)	// reads into current folder
	SetDataFolder root:
End


// This loads for speed, since loading the attributes takes a LOT of time.
//
// this will load in the whole HDF file all at once.
// Attributes are NOT loaded at all.
//
// TODO: remove the P=home restriction top make this more generic
// -- get rid of bits leftover here that I don't need
// -- be sure I'm using all of the correct flags in the HDF5LoadGroup operation
//
Function V_LoadHDF5_NoAtt(fileName, [hdf5Path])
	String fileName, hdf5Path
	if ( ParamIsDefault(hdf5Path) )
		hdf5Path = "/"
	endif

	String status = ""

	Variable fileID = 0
	HDF5OpenFile/R/P=home/Z fileID as fileName		//read file from home directory?
//	HDF5OpenFile/R/P=catPathName/Z fileID as fileName
	if (V_Flag != 0)
		return 0
	endif

	String/G root:file_path = S_path
	String/G root:file_name = S_FileName
	
	if ( fileID == 0 )
		Print fileName + ": could not open as HDF5 file"
		return (0)
	endif
	
//s_tic()		//fast 
	
	SVAR tmpStr=root:file_name
	fileName=tmpStr		//SRK - in case the file was chosen from a dialog
	
	//   read the data (too bad that HDF5LoadGroup does not read the attributes)
	String base_name = StringFromList(0,FileName,".")
	HDF5LoadGroup/Z/L=7/O/R/T=$base_name  :, fileID, hdf5Path		//	recursive
	if ( V_Flag != 0 )
		Print fileName + ": could not open as HDF5 file"
		setdatafolder root:
		return (0)
	endif

	HDF5CloseFile fileID
	
//s_toc()
	return(0)
end	 


// read a single real value 
// - fname passed in is the full path to the file on disk
// - path is the path to the value in the HDF tree
//
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
Function V_getRealValueFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	if(Exists("root:"+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname)
	endif

// this should exist now - if not, I need to see the error
	Wave w = $("root:"+folderStr+":"+path)
	
	return(w[0])
End

// Returns a wave reference, not just a single value
// ---then you pick what you need from the wave
// 
// - fname passed in is the full path to the file on disk
// - path is the path to the value in the HDF tree
//
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
Function/WAVE V_getRealWaveFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	if(Exists("root:"+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname)
	endif

// this should exist now - if not, I need to see the error
	Wave wOut = $("root:"+folderStr+":"+path)
	
	return wOut
	
End

//
//   TODO
// depricated? in HDF5 - store all of the values as real?
// Igor sees no difference in real and integer variables (waves are different)
//
// truncate to integer before returning??
//
//////  integer values
// reads 32 bit integer
Function V_getIntegerFromHDF5(fname,path)
	String fname				//full path+name
	String path				//path to the hdf5 location
	
	Variable val = V_getRealValueFromHDF5(fname,path)
	
	val = round(val)
	return(val)
End


// read a single string
// - fname passed in is the full path to the file on disk
// - path is the path to the value in the HDF tree
// - num is the number of characters in the VAX string
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
// TODO -- string is checked for length, but returned right or wrong
//
Function/S V_getStringFromHDF5(fname,path,num)
	String fname,path
	Variable num

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	if(Exists("root:"+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname)
	endif

// this should exist now - if not, I need to see the error
	Wave/T tw = $("root:"+folderStr+":"+path)
	
//	if(strlen(tw[0]) != num)
//		Print "string is not the specified length"
//	endif
	
	return(tw[0])
End


//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
Function V_WriteWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave wav
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile /Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		//get the NXentry node name
		HDF5ListGroup /TYPE=1 fileID, "/"
		//remove trailing ; from S_HDF5ListGroup
		
		Print "S_HDF5ListGroup = ",S_HDF5ListGroup
		
		NXentry_name = S_HDF5ListGroup
		NXentry_name = ReplaceString(";",NXentry_name,"")
		if(strsearch(NXentry_name,":",0)!=-1) //more than one entry under the root node
			err = 1
			abort "More than one entry under the root node. Ambiguous"
		endif 
		//concatenate NXentry node name and groupName	
		groupName = "/" + NXentry_name + groupName
		Print "groupName = ",groupName
		HDF5OpenGroup /Z fileID , groupName, groupID

		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else
			// get attributes and save them
			//HDF5ListAttributes /Z fileID, groupName    this is returning null. expect it to return semicolon delimited list of attributes 
			//Wave attributes = S_HDF5ListAttributes
		endif
	
		HDF5SaveData /O /Z /IGOR=0 wav, groupID, varName
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + varName
		endif	
		
		
		//attributes - something could be added here as optional parameters and flagged
//		String attributes = "units"
//		Make/O/T/N=1 tmp
//		tmp[0] = "dimensionless"
//		HDF5SaveData /O /Z /IGOR=0 /A=attributes tmp, groupID, varName
//		if (V_flag != 0)
//			err = 1
//			abort "Cannot save attributes to HDF5 dataset"
//		endif	
	catch

	endtry
	
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif
	
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	setDataFolder $cDF
	return err
end

//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
Function V_WriteTextWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave/T wav
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile /Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		//get the NXentry node name
		HDF5ListGroup /TYPE=1 fileID, "/"
		//remove trailing ; from S_HDF5ListGroup
		
		Print "S_HDF5ListGroup = ",S_HDF5ListGroup
		
		NXentry_name = S_HDF5ListGroup
		NXentry_name = ReplaceString(";",NXentry_name,"")
		if(strsearch(NXentry_name,":",0)!=-1) //more than one entry under the root node
			err = 1
			abort "More than one entry under the root node. Ambiguous"
		endif 

// TODO SRK -- skipping the concatenation of the NXentry_name - may add back in the future, but this
//   prevents me from accessing the file name which I put on the top node (which may be incorrect style)
//
//		NOTE this is only for the texWaves - the writer for real waves does the concatenation , since everything is 
//     under the "entry" group (/Run1)
//
		//concatenate NXentry node name and groupName	
//		groupName = "/" + NXentry_name + groupName
		Print "groupName = ",groupName

		HDF5OpenGroup /Z fileID , groupName, groupID

		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else
			// get attributes and save them
			//HDF5ListAttributes /Z fileID, groupName    this is returning null. expect it to return semicolon delimited list of attributes 
			//Wave attributes = S_HDF5ListAttributes
		endif
	
		HDF5SaveData /O /Z /IGOR=0 wav, groupID, varName
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + varName
		endif	
		
		
		//attributes - something could be added here as optional parameters and flagged
//		String attributes = "units"
//		Make/O/T/N=1 tmp
//		tmp[0] = "dimensionless"
//		HDF5SaveData /O /Z /IGOR=0 /A=attributes tmp, groupID, varName
//		if (V_flag != 0)
//			err = 1
//			abort "Cannot save attributes to HDF5 dataset"
//		endif	
	catch

	endtry
	
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif
	
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	setDataFolder $cDF
	return err
end






//transmission is at byte 158
Function V_getSampleTrans(fname)
	String fname
	
	String path = "Run1:Sample:TRNS"	
	return(V_getRealValueFromHDF5(fname,path))
end

//sample transmission is a real value at byte 158
Function V_WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "TRNS"
	wTmpWrite[0] = trans //

	variable err
	err = V_WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	err = V_KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
		
	return(0)
End

// sample label (60 characters @ byte 98)
Function/S V_getSampleLabel(fname)
	String fname

	String path = "Run1:runLabel"
	Variable num=60
	return(V_getStringFromHDF5(fname,path,num))
End


// sample label, starts at byte 98
//
// TODO
// limit to 60 characters?? do I need to do this with HDF5?
//
// do I need to pad to 60 characters?
//
Function V_WriteSamLabelToHeader(fname,str)
	String fname,str
	
	if(strlen(str) > 60)
		str = str[0,59]
	endif
//	WriteTextToHeader(fname,str,98)
	
	
	Make/O/T/N=1 tmpTW
	String groupName = "/Run1"	//	explicitly state the group
	String varName = "runLabel"
	tmpTW[0] = str //

	variable err
	err = V_WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
	err = V_KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	
	return(0)
End


// fname is the full path to the file
// data is an empty 2D wave in RAW to hold the data
//
Function V_getDetectorData(fname,data)
	String fname
	Wave data
	
	// get a wave reference to the data
	String path = "Run1:Detector:data"
	WAVE w = V_getRealWaveFromHDF5(fname,path)

	data = w

	return(0)
End



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