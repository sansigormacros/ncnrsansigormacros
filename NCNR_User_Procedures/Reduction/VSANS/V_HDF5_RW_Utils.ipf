#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// The base functions for R/W from HDF5 files.
// All of the specific "get" and "write" functions call these base functions which are responsible
// for all of the open/close mechanics.
//
// These VSANS file-specific functions are in:
// V_HDF5_Read.ipf
//		 and
// V_HDF5_Write.ipf
//

// data is read into:
// 	NewDataFolder/O/S root:Packages:NIST:VSANS:RawVSANS
// so that the data folders of the raw data won't be lying around on the top level, looking like
// 1D data sets and interfering.


// the base data folder path where the raw data is loaded
Strconstant ksBaseDFPath = "root:Packages:NIST:VSANS:RawVSANS:"



// passing null file string presents a dialog
Proc Read_HDF5_Raw_No_Attributes()
	V_LoadHDF5Data("","RAW")
End

// TODO:
//  x- move the initializtion of the raw data folder to be in the as-yet unwritten initialization routine for
// reduction. be sure that it's duplicated in the VCALC initialization too.
// -- as needed, get rid of the FAKE redimension of the data from 3D->2D and from 128x128 to something else for VSANS
//    This is a fake since I don't have anything close to correct fake data yet. (1/29/16)
//
Function V_LoadHDF5Data(file,folder)
	String file,folder

	String base_name
	SetDataFolder $("root:Packages:NIST:VSANS:"+folder)
//	SetDataFolder root:
	if(cmpstr(folder,"RAW")==0)
		base_name="entry"
	else
		base_name=""
	endif
	
	Variable err= V_LoadHDF5_NoAtt(file,base_name)	// reads into current folder
	
	// if RAW data, then generate the errors and linear data copy
	// do this 9x
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:entry:instrument:" 
	if(cmpstr(folder,"RAW")==0)
		V_MakeDataError(tmpStr+"detector_B")
		V_MakeDataError(tmpStr+"detector_MB")
		V_MakeDataError(tmpStr+"detector_MT")
		V_MakeDataError(tmpStr+"detector_ML")
		V_MakeDataError(tmpStr+"detector_MR")
		V_MakeDataError(tmpStr+"detector_FB")
		V_MakeDataError(tmpStr+"detector_FT")
		V_MakeDataError(tmpStr+"detector_FL")
		V_MakeDataError(tmpStr+"detector_FR")

// TODO -- once I get "real" data, get rid of this call to force the data to be proper dimensions.
		V_RedimFakeData()
		
/// END FAKE DATA CORRECTIONS		
		
	endif
	
	SetDataFolder root:
	return(err)
End

//
// TODO -- this is all FAKED since all the data arrays are (1,128,128)
// I'm intentionally using the wrong number of pixels so I'm more likely to go back and get rid of this later.
//
// the SetScale parts may be useful later.
//
Function V_RedimFakeData()
	
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_B
		Wave det_B=data
		Redimension/N=(300,300)/E=1 det_B
		
		Variable ctr=20,npix=100
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MT
		Wave det_MT=data
		Redimension/N=(npix,48)/E=1 det_MT		
		SetScale/I x -npix/2,npix/2,"",det_MT
		SetScale/I y ctr,ctr+48,"",det_MT

		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MB
		Wave det_MB=data
		Redimension/N=(npix,48)/E=1 det_MB		
		SetScale/I x -npix/2,npix/2,"",det_MB
		SetScale/I y -ctr,-ctr-48,"",det_MB
		
		ctr=30
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_ML
		Wave det_ML=data
		Redimension/N=(48,npix)/E=1 det_ML		
		SetScale/I x -ctr-48,-ctr,"",det_ML
		SetScale/I y -npix/2,npix/2,"",det_ML
		
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MR
		Wave det_MR=data
		Redimension/N=(48,npix)/E=1 det_MR		
		SetScale/I x ctr,ctr+48,"",det_MR
		SetScale/I y -npix/2,npix/2,"",det_MR
		
		ctr=30
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FT
		Wave det_FT=data
		Redimension/N=(npix,48)/E=1 det_FT		
		SetScale/I x -npix/2,npix/2,"",det_FT
		SetScale/I y ctr,ctr+48,"",det_FT

		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FB
		Wave det_FB=data
		Redimension/N=(npix,48)/E=1 det_FB		
		SetScale/I x -npix/2,npix/2,"",det_FB
		SetScale/I y -ctr,-ctr-48,"",det_FB
		
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FL
		Wave det_FL=data
		Redimension/N=(48,npix)/E=1 det_FL		
		SetScale/I x -ctr-48,-ctr,"",det_FL
		SetScale/I y -npix/2,npix/2,"",det_FL
		
		SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FR
		Wave det_FR=data
		Redimension/N=(48,npix)/E=1 det_FR		
		SetScale/I x ctr,ctr+48,"",det_FR
		SetScale/I y -npix/2,npix/2,"",det_FR


	return(0)
End


// This loads for speed, since loading the attributes takes a LOT of time.
//
// this will load in the whole HDF file all at once.
// Attributes are NOT loaded at all.
//
// TODO: remove the P=home restriction top make this more generic
// -- get rid of bits leftover here that I don't need
// -- be sure I'm using all of the correct flags in the HDF5LoadGroup operation
// -- settle on how the base_name is to be used. "entry" for the RAW, fileName for the "rawVSANS"?
//
// passing in "" for base_name will take the name from the file name as selected
//
Function V_LoadHDF5_NoAtt(fileName,base_name)
	String fileName, base_name
	
//	if ( ParamIsDefault(hdf5Path) )
//		hdf5Path = "/"
//	endif

	String hdf5path = "/"		//always read from the top
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
	fileName=tmpStr		//SRK - in case the file was chosen from a dialog, I'll need access to the name later
	
	//   read the data (too bad that HDF5LoadGroup does not read the attributes)
	if(cmpstr(base_name,"") == 0)
		base_name = StringFromList(0,FileName,".")
	endif
	//base_name = "entry"
	
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
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname,"")
	endif

// this should exist now - if not, I need to see the error
	Wave/Z w = $(ksBaseDFPath+folderStr+":"+path)
	
	if(WaveExists(w))
		return(w[0])
	else
		return(-999999)
	endif	
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
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname,"")
	endif

// this should exist now - if not, I need to see the error
	Wave wOut = $(ksBaseDFPath+folderStr+":"+path)
	
	return wOut
	
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
Function/WAVE V_getTextWaveFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname,"")
	endif

// this should exist now - if not, I need to see the error
	Wave/T wOut = $(ksBaseDFPath+folderStr+":"+path)
	
	return wOut
	
End


//
//   TODO
// depricated? in HDF5 - store all of the values as real?
// Igor sees no difference in real and integer variables (waves are different)
// BUT-- Igor 7 will have integer variables
//
// truncate to integer before returning??
//
//  TODO
// write a "getIntegerWave" function??
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
// TODO -- string could be checked for length, but returned right or wrong
//
Function/S V_getStringFromHDF5(fname,path,num)
	String fname,path
	Variable num

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file
		V_LoadHDF5_NoAtt(fname,"")
	endif

// this should exist now - if not, I need to see the error
	Wave/T/Z tw = $(ksBaseDFPath+folderStr+":"+path)
	
	if(WaveExists(tw))
	
	//	if(strlen(tw[0]) != num)
	//		Print "string is not the specified length"
	//	endif
		
		return(tw[0])
	else
		return("The specified wave does not exist: " + path)
	endif
End



///////////////////////////////

//
//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
//
// TODO:
// -- figure out if this will write in the native format of the 
//     wave as passed in, or if it will only write as DP.
// -- do I need to write separate functions for real, integer, etc.?
//	
// -- change the /P=home to the user-defined data path (which may be home)		
//
Function V_WriteWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave wav
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile/P=home /Z fileID  as fname  //open file read-write
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
		// SRK - NOV2015 - dropped this and require the full group name passed in
//		groupName = "/" + NXentry_name + groupName
		Print "groupName = ",groupName
		HDF5OpenGroup /Z fileID , groupName, groupID

		if(!groupID)
		// don't create the group it the name isn't right -- throw up an error
			//HDF5CreateGroup /Z fileID, groupName, groupID
			err = 1
			HDF5CloseFile /Z fileID
			DoAlert 0, "HDF5 group does not exist "+groupName+varname
			return(err)
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

// it is not necessary to close the group here. HDF5CloseFile will close the group as well	
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
//
// TODO
//
// -- change the /P=home to the user-defined data path (which may be home)		
//
Function V_WriteTextWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave/T wav
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile/P=home /Z fileID  as fname  //open file read-write
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
		// SRK - NOV2015 - dropped this and require the full group name passed in
//		groupName = "/" + NXentry_name + groupName
		Print "groupName = ",groupName

		HDF5OpenGroup /Z fileID , groupName, groupID

		if(!groupID)
		// don't create the group it the name isn't right -- throw up an error
			//HDF5CreateGroup /Z fileID, groupName, groupID
			err = 1
			HDF5CloseFile /Z fileID
			DoAlert 0, "HDF5 group does not exist "+groupName+varname
			return(err)
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

//////////////////////////////
//////////////////////////////
//////////////////////////////

Function V_KillNamedDataFolder(fname)
	String fname
	
	Variable err=0
	
	String folderStr = V_GetFileNameFromPathNoSemi(fname)
	folderStr = V_RemoveDotExtension(folderStr)
	
	KillDataFolder/Z $(ksBaseDFPath+folderStr)
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