﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 8.00


//
// May 2021 -- starting the process of re-writing to work
// with a new, more complete nexus file definition
//
// I will need to start by removing calls to the gateway, and replace
// with the loader from VSANS
//
// then pieces from VSANS will need to be added to SANS - replacing the old VAX referenced parts
//
// -- SANS reduction will need to be differentiated now - since all three instruments
// will be slightly different in their file contents, and the differences between the 30m,
// instruments and the 10m will be VERY significant. Not a place for a million "if" statements
//
//



//
// The base functions for R/W from HDF5 files.
// All of the specific "get" and "write" functions call these base functions which are responsible
// for all of the open/close mechanics.
//
// These VSANS file-specific functions are in:
// HDF5_Read.ipf
//		 and
// HDF5_Write.ipf
//

// data is read into:
// 	NewDataFolder/O/S root:Packages:NIST:RawSANS
// so that the data folders of the raw data won't be lying around on the top level, looking like
// 1D data sets and interfering.



// passing null file string presents a dialog
Proc LoadFakeDIVData()
	LoadHDF5Data("","DIV")
End

// Moved to V_MaskUtils.ipf
// passing null file string presents a dialog
//Proc LoadFakeMASKData()
//	V_LoadHDF5Data("","MSK")
//End




//simple, main entry procedure that will load a RAW sans data file (not a work file)
//into the RAW dataFolder. It is up to the calling procedure to display the file
//
// called by MainPanel.ipf and ProtocolAsPanel.ipf
//
Function LoadRawSANSData(file,folder)
	String file,folder

	String filename="",destPath="",tmpStr=""

	destPath = "root:Packages:NIST:"+folder
	// before reading in new data, clean out what old data can be cleaned. hopefully new data will overwrite what is in use
	KillWavesFullTree($destPath,folder,0,"",1)			// this will traverse the whole tree, trying to kill what it can

	if(DataFolderExists("root:Packages:NIST:"+folder) == 0)		//if it was just killed?
		NewDataFolder/O $("root:Packages:NIST:"+folder)
	endif
	SetDataFolder $("root:Packages:NIST:"+folder)

	String nameOnlyStr=GetFileNameFromPathNoSemi(file)
	
	
//	// be sure the "temp" load goes into root:
//	SetDataFolder root:
//	Print H5GW_ReadHDF5("", nameOnlyStr)	// reads into current folder

	PathInfo/S catPathName
	if(V_flag == 0)
		DoAlert 0,"Pick the data folder, then the data file"
		PickPath()
	endif


	ReadHeaderAndData(file,folder)	//this is the full Path+file

// make linear copy of data (really don't need this?)
	Wave data=getDetectorDataW(folder)
	tmpStr = "root:Packages:NIST:"+folder+":entry:instrument:"
	Duplicate/O data $(tmpStr+"detector:linear_data")

// if the data is DIV, then handle the data errors differently since they are already part of the data file
// root:Packages:NIST:VSANS:DIV:entry:instrument:detector_B:
	if(cmpstr(folder,"DIV")==0)
		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above 
		tmpStr = "root:Packages:NIST:DIV:entry:instrument:"
		SetDataFolder $(tmpStr+"detector")
		Wave data=getDetectorDataW(folder)
		Duplicate/O data $(tmpStr+"detector:linear_data")
		Wave linear_data_error=linear_data_error
		Duplicate/O linear_data_error $(tmpStr+"detector:data_error")
		SetDataFolder root:
	endif

// pre-processing of RAW data files
//
	if(cmpstr(folder,"RAW")==0)

		MakeDataWaves_DP(folder)

		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above 
		MakeDataError("root:Packages:NIST:RAW:entry:instrument:detector")	
		
		// TODO -- calculate the nonlinear x/y arrays and the q-values here
		// -- otherwise the mouse-over doesn't calculate the correct Q_values
		// the display currently is not shifted or altered at all to account for the non-linearity
		// or for display in q-values -- so why bother with this?
		
//		NVAR gDoNonLinearCor = root:Packages:NIST:Globals:gDoNonLinearCor
//		// generate a distance matrix for each of the detectors
//		if (gDoNonLinearCor == 1)
//			Print "Calculating Non-linear correction at RAW load time"// for "+ detStr
//				
//			Wave w = getDetectorDataW(folder)
//	//			Wave w_err = V_getDetectorDataErrW(fname,detStr)		//not here, done above w/V_MakeDataError()
//			Wave w_calib = V_getDetTube_spatialCalib(folder,detStr)
//			Variable tube_width = V_getDet_tubeWidth(folder,detStr)
//			V_NonLinearCorrection(folder,w,w_calib,tube_width,detStr,destPath)
//				
//				// --The proper definition of beam center is in [cm], so the conversion
//				// is no longer needed (kBCTR_CM==1)
//				
//				if(kBCTR_CM)
//					//V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
//					//
//	
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
//					WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
//					WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
//					x_mm[0] = V_getDet_beam_center_x(folder,detStr) * 10 		// convert cm to mm
//					y_mm[0] = V_getDet_beam_center_y(folder,detStr) * 10 		// convert cm to mm
//					
//					// (DONE):::
//				// now I need to convert the beam center in mm to pixels
//				// and have some rational place to look for it...
//					V_ConvertBeamCtr_to_pix(folder,detStr,destPath)
//				else
//					// beam center is in pixels, so use the old routine
//					V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
//				endif				
//				
//				
//				// (2.5) Calculate the q-values
//				// calculating q-values can't be done unless the non-linear corrections are calculated
//				// so go ahead and put it in this loop.
//				//
//				V_Detector_CalcQVals(folder,detStr,destPath)
//							
//		else
//			Print "Non-linear correction not done on RAW data"
//		endif			
			
	endif		/// END DATA CORRECTIONS FOR RAW	

	
	SetDataFolder root:
	return(0)
	
End




// This loads for speed, since loading the attributes takes a LOT of time.
//
// this will load in the whole Nexus file all at once.
// -- the DAS_Logs are SKIPPED - since they are not needed for reduction
// Attributes are NOT loaded at all.
//
//
Function ReadHeaderAndData(fname,folderStr)
	String fname,folderStr


	Variable/G gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	
	Variable refNum,integer,realval
	String sansfname,textstr

	PathInfo/S catPathName
	if(V_flag == 0)
		DoAlert 0,"Pick the data folder, then the data file"
		PickPath()
	endif

//	Make/O/D/N=23 $"IntegersRead"
//	Make/O/D/N=52 $"RealsRead"
//	Make/O/T/N=11 $"TextRead"
//	Make/O/N=7 $"LogicalsRead"
	
//	Wave intw=$"root:Packages:NIST:RAW:IntegersRead"
//	Wave realw=$"root:Packages:NIST:RAW:RealsRead"
//	Wave/T textw=$"root:Packages:NIST:RAW:TextRead"
//	Wave logw=$"root:Packages:NIST:RAW:LogicalsRead"


//	String nameOnlyStr=GetFileNameFromPathNoSemi(fname)


	String hdf5path = "/"		//always read from the top
	String status = ""

	Variable fileID = 0
//	HDF5OpenFile/R/P=home/Z fileID as fName		//read file from home directory?
	HDF5OpenFile/R/P=catPathName/Z fileID as fName
	if (V_Flag != 0)
		return 1
	endif

	String/G root:file_path = S_path
	String/G root:file_name = S_FileName
	
	if ( fileID == 0 )
		Print fName + ": could not open as HDF5 file"
		return (1)
	endif
		
	SVAR tmpStr=root:file_name
	fName=tmpStr		//SRK - in case the file was chosen from a dialog, I'll need access to the name later


	hdf5path = "/"  //always read from the top
	
	// if base_name is from my list of WORK folders + RawSANS;, then base_name = ""
	// use a stringSwitch? WhichListItem?
	Variable isFolder = WhichListItem(folderStr,ksWorkFolderListShort+"RawSANS;")
	if(isFolder != -1)
		folderStr = ""
	else
		folderStr = StringFromList(0,FName,".")		// just the first part of the name, no .nxs.ngv
	endif

	String curDF = GetDataFolder(1)

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+folderStr)
	endif
	
//// loads everything with one line	 (includes /DAS_logs)
//	HDF5LoadGroup/Z/L=7/O/R/T=$base_name  :, fileID, hdf5Path		//	recursive
// /L=7 flag loads all data types, no /L acts as /L=7

//		HDF5LoadGroup /O /R=2 /T /IMAG=1 :, fileID, hdf5Path		// Requires HDF5 XOP 1.24 or later
		HDF5LoadGroup /O /R=2 /IMAG=1 :, fileID, hdf5Path		// Requires HDF5 XOP 1.24 or later

//
	HDF5CloseFile/Z fileID


	//keep a string with the filename in the folder where the data was loaded
	String/G fileList = fname

	SetDataFolder root:	
	Return 0
End









//****************
//main entry procedure for reading a "WORK.DIV" file
//displays a quick image of the  file, to check that it's correct
//data is deposited in root:Packages:NIST:DIV data folder
//
// local, currently unused
//
//
Proc ReadWork_DIV()
//	Silent 1
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:Packages:NIST:DIV:data"
//	NewImage/F/K=1/S=2 $waveStr		//this is an experimental IGOR operation
//	ModifyImage '' ctab= {*,*,YellowHot,0}
	//Display;AppendImage $waveStr
	
	//change the title string to WORK.DIV, rather than PLEXnnn_TST_asdfa garbage
//	String/G root:Packages:NIST:DIV:fileList = "WORK.DIV"
	ChangeDisplay("DIV")
	
	SetDataFolder root:		//(redundant)
//	Silent 0
End


//this function is the guts of reading a binary VAX file of real (4-byte) values
// (i.e. a WORK.aaa file) 
// work files have the same header structure as RAW SANS data, just with
//different data (real, rather than compressed integer data)
//
//
// called from ProtocolAsPanel.ipf
//
//
Function ReadHeaderAndWork(type,fname)
	String type,fname
	
	//type is the desired folder to read the workfile to
	//this data will NOT be automatically displayed gDataDisplayType is unchanged


	DoAlert 0, "ReadHeaderAndWork is still using old VAX code"
	
	
//	SVAR cur_folder=root:myGlobals:gDataDisplayType
	String cur_folder = type
	String curPath = "root:Packages:NIST:"+cur_folder
	SetDataFolder curPath		//use the full path, so it will always work
	
	Variable refNum,integer,realval
	String sansfname,textstr
	Variable/G $(curPath + ":gIsLogScale") = 0		//initial state is linear, keep this in DIV folder
	
	Make/O/D/N=23 $(curPath + ":IntegersRead")
	Make/O/D/N=52 $(curPath + ":RealsRead")
	Make/O/T/N=11 $(curPath + ":TextRead")
	
	WAVE intw=$(curPath + ":IntegersRead")
	WAVE realw=$(curPath + ":RealsRead")
	WAVE/T textw=$(curPath + ":TextRead")
	
//
/// done reading in raw data
//


	//keep a string with the filename in the DIV folder
	String/G $(curPath + ":fileList") = textw[0]
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End


// fname is the folder = "RAW"
Function MakeDataWaves_DP(fname)
	String fname
	

	Wave w = getDetectorDataW(fname)
	Redimension/D w
	
	return(0)
End






// read a single real value 
// - fname passed in is the full path to the file on disk --OR-- a WORK folder
// - path is the path to the value in the HDF tree
//
/// -- if data requested from a WORK or VCALC folder:
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local WORK folder
//		if it does not exist, return DUMMY value
//
//// -- if data requested from a file:
// check to see if the value exists locally in RawVSANS (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
//
Function getRealValueFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	Variable errorValue = -999999
	
	folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it, or report error
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+"VCALC;RealTime;")
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawVSANS)
	// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:"+folderStr+":"+path))
			Wave/Z w = $("root:Packages:NIST:"+folderStr+":"+path)
			return(w[0])
		else
			return(errorValue)
		endif
	endif


	// (2) requesting from a file.
	// look locally in RawVSANS if possible, or if not, load in the data from disk
	// - if thee both fail, report an error
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		ReadHeaderAndData(fname,"")
		SetDataFolder root:
	endif

// this should exist now - if not, I need to see the error
	Wave/Z w = $(ksBaseDFPath+folderStr+":"+path)
	
	if(WaveExists(w))
		return(w[0])
	else
		return(errorValue)
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
// if the wave is null, then that is returned, and the calling function is responsible
//
Function/WAVE getRealWaveFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it
// no need to check for any existence, null return is OK
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+"SASCALC;RealTime;")
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawVSANS)
//	// check for a work folder first (note that "entry" is now NOT doubled)
//		if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
			Wave/Z wOut = $("root:Packages:NIST:"+folderStr+":"+path)
			return wOut
	endif

//// check for a work folder first (note that "entry" is NOT doubled)
//	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
//		Wave wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
//		return wOut
//	endif
	
// (2) requesting from a file
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		ReadHeaderAndData(fname,"")
		SetDataFolder root:
	endif
		
// this should exist now - if not, I need to see the error
	Wave/Z wOut = $(ksBaseDFPath+folderStr+":"+path)
	
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
// if the wave is null, then that is returned, and the calling function is responsible
//
Function/WAVE getTextWaveFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it
// no need to check for any existence, null return is OK
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+"SASCALC;RealTime;")
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawVSANS)
//	// check for a work folder first (note that "entry" is now NOT doubled)
//		if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
			Wave/Z/T wOut = $("root:Packages:NIST:"+folderStr+":"+path)
			return wOut
	endif
	
//// check for a work folder first (note that "entry" is NOT doubled)
//	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
//		Wave/T wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
//		return wOut
//	endif

// (2) requesting from a file	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		ReadHeaderAndData(fname,"")
		SetDataFolder root:
	endif

// this should exist now - if not, I will see the error in the calling function
	Wave/T/Z wOut = $(ksBaseDFPath+folderStr+":"+path)
	
	return wOut
	
End


//
//   (DONE)
// depricated? in HDF5 - store all of the values as real?
// Igor sees no difference in real and integer variables (waves are different)
// BUT-- Igor 7 will have integer variables
//
// truncate to integer before returning??
//
//  (DONE)
// write a "getIntegerWave" function??
//
//////  integer values
// reads 32 bit integer
Function getIntegerFromHDF5(fname,path)
	String fname				//full path+name
	String path				//path to the hdf5 location
	
	Variable val = getRealValueFromHDF5(fname,path)
	
	val = round(val)
	return(val)
End


// read a single string
// - fname passed in is the full path to the file on disk --OR-- a WORK folder
// - path is the path to the value in the HDF tree
// - num is the number of characters in the VAX string
//
/// -- if data requested from a WORK or VCALC folder:
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local WORK folder
//		if it does not exist, return DUMMY value
//
//// -- if data requested from a file:
// check to see if the value exists locally in RawVSANS (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
// (DONE) -- string could be checked for length, but returned right or wrong
//
// -- currently num is completely ignored
//
Function/S getStringFromHDF5(fname,path,num)
	String fname,path
	Variable num

	String folderStr=""
	Variable valExists=0
	String errorString = "The specified wave does not exist: " + path
	
	folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it, or report error
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+"SASCALC;RealTime;")
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawVSANS)
	// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:"+folderStr+":"+path))
			Wave/Z/T tw = $("root:Packages:NIST:"+folderStr+":"+path)
			return(tw[0])
		else
			return(errorSTring)
		endif
	endif

// (2) requesting from a file.
// look locally in RawVSANS if possible, or if not, load in the data from disk
// - if thee both fail, report an error	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		ReadHeaderAndData(fname,"")
		SetDataFolder root:
	endif

// this should exist now - if not, I need to see the error
	Wave/T/Z tw = $(ksBaseDFPath+folderStr+":"+path)
	
	if(WaveExists(tw))
	
	//	if(strlen(tw[0]) != num)
	//		Print "string is not the specified length"
	//	endif
		
		return(tw[0])
	else
		return(errorString)
	endif
End



///////////////////////////////

//
//Write Wave 'wav' to hdf5 file 'fname'
//Based on code from ANSTO (N. Hauser. nha 8/1/09)
//
// (DONE):
// x- figure out if this will write in the native format of the 
//     wave as passed in, or if it will only write as DP.
// x-(NO) do I need to write separate functions for real, integer, etc.?
// x- the lines to create a missing group have been commented out to avoid filling
//    in missing fields that should have been generated by the data writer. Need to make
//    a separate function that will write and generate if needed, and use this in specific cases
//    only if I really have to force it.
//
// x-Attributes are not currently saved. Fix this, maybe make it optional? See the help file for
//  DemoAttributes(w) example under the HDF5SaveData operation
//	
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function WriteWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave wav
	
	
	// try a local folder first, then try to save to disk
	//
//	String folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))
//	
//	String localPath = "root:Packages:NIST:"+folderStr//+":entry"
//	localPath += groupName + "/" + varName
//	// make everything colons for local data folders
//	localPath = ReplaceString("/", localPath, ":")
//	
//	Wave/Z w = $localPath
//	if(waveExists(w) == 1)
//		w = wav
////		Print "write to local folder done"
//		return(0)		//we're done, get out
//	endif
	
	
	// if the local wave did not exist, then we proceed to write to disk

	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile/P=catPathName /Z fileID  as fname  //open file read-write
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
		// don't create the group if the name isn't right -- throw up an error
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
// (DONE)
//
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function WriteTextWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave/T wav

	// try a local folder first, then try to save to disk
	//
//	String folderStr = RemoveDotExtension(GetFileNameFromPathNoSemi(fname))
//	
//	String localPath = "root:Packages:NIST:"+folderStr//+":entry"
//	localPath += groupName + "/" + varName
//	// make everything colons for local data folders
//	localPath = ReplaceString("/", localPath, ":")
//	
//	Wave/Z/T w = $localPath
//	if(waveExists(w) == 1)
//		w = wav
//		Print "write to local folder done"
//		return(0)		//we're done, get out
//	endif
	
	
	// if the local wave did not exist, then we proceed to write to disk


	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name
	
	try	
		HDF5OpenFile/P=catPathName /Z fileID  as fname  //open file read-write
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






//////////
//
// These procedures are needed to write out MASK and DIV files
//
////////


//
// saves a specified folder, with a given filename.
// saves to the home path
//
Proc Save_SANS_file(dfPath, filename)
	String dfPath	="root:SANS_file"		// e.g., "root:FolderA" or ":"
	String filename = "Test_SANS_file.h5"
	
	HDF_NXSANS_SaveGroupAsHDF5(dfPath, filename)
End


//	
// this is my procedure to save the folders to HDF5, once I've filled the folder tree
//
// this does NOT save attributes, but gets the folder structure correct
//
Function HDF_NXSANS_SaveGroupAsHDF5(dfPath, filename)
	String dfPath	// e.g., "root:FolderA" or ":"
	String filename

	Variable result = 0	// 0 means no error
	
	Variable fileID
	PathInfo home
	if(V_flag == 1)
		HDF5CreateFile/P=home /O /Z fileID as filename
	else
		HDF5CreateFile /O/I /Z fileID as filename
	endif
	if (V_flag != 0)
		Print "HDF5CreateFile failed"
		return -1
	endif

	HDF5SaveGroup /IGOR=0 /O /R /Z $dfPath, fileID, "."
//	HDF5SaveGroup /O /R /Z $dfPath, fileID, "."
	if (V_flag != 0)
		Print "HDF5SaveGroup failed"
		result = -1
	endif
	
	HDF5CloseFile fileID

	return result
End
