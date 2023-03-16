#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 8.00


//
// May 2021
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



//// passing null file string presents a dialog
//Proc LoadFakeDIVData()
//	LoadRawSANSData("","DIV")
//End

// Moved to V_MaskUtils.ipf
// passing null file string presents a dialog
//Proc LoadFakeMASKData()
//	LoadRawSANSData("","MSK")
//End



// 
// MAIN ENTRY procedure to load a RAW sans data file (not a work file)
//into the RAW dataFolder. It is up to the calling procedure to display the file
//
// called by MainPanel.ipf and ProtocolAsPanel.ipf
//
//
// ALSO - used to read in DIV and MSK data
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

	String nameOnlyStr=N_GetFileNameFromPathNoSemi(file)
	
	
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

	Variable tube_width

// if the data is DIV, then handle the data errors differently since they are already part of the data file
	if(cmpstr(folder,"DIV")==0)
		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above 
		tmpStr = "root:Packages:NIST:DIV:entry:instrument:"
		SetDataFolder $(tmpStr+"detector")
		Wave data=getDetectorDataW(folder)
		Duplicate/O data $(tmpStr+"detector:linear_data")
		Wave linear_data_error=linear_data_error
		Duplicate/O linear_data_error $(tmpStr+"detector:data_error")
		
		// do the nonlinear calculation so that the data can be displayed
		Wave w = getDetectorDataW(folder)
		Wave w_calib = getDetTube_spatialCalib(folder)
		tube_width = getDet_tubeWidth(folder)
		NonLinearCorrection(folder,w,w_calib,tube_width,destPath)
		
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
		//
		// For SANS, don't calculate the distance arrays. The beam center will be on the detector panel,
		// and there is no offset, gap, or vert/horiz tube orientation. Simply use the coefficients
		// to calculate q-values as needed.
		//
		
		NVAR gDoNonLinearCor = root:Packages:NIST:gDoNonLinearCor
		// generate a distance matrix for each of the detectors
		if (gDoNonLinearCor == 1)
			Print "Calculating Non-linear correction at RAW load time"// for "+ detStr
//				
			Wave w = getDetectorDataW(folder)
	//			Wave w_err = V_getDetectorDataErrW(fname,detStr)		//not here, done above w/V_MakeDataError()
			Wave w_calib = getDetTube_spatialCalib(folder)
			tube_width = getDet_tubeWidth(folder)
			NonLinearCorrection(folder,w,w_calib,tube_width,destPath)
//				
				// --The beam center for SANS is defined in PIXELS, kBCTR_CM==0
				
				if(kBCTR_CM)
//					//V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
//					//
//	
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector:beam_center_x_mm")
//					Make/O/D/N=1 $(destPath + ":entry:instrument:detector:beam_center_y_mm")
//					WAVE x_mm = $(destPath + ":entry:instrument:detector:beam_center_x_mm")
//					WAVE y_mm = $(destPath + ":entry:instrument:detector:beam_center_y_mm")
//					x_mm[0] = getDet_beam_center_x(folder) * 10 		// convert cm to mm
//					y_mm[0] = getDet_beam_center_y(folder) * 10 		// convert cm to mm
//					
//					// (DONE):::
//				// now I need to convert the beam center in mm to pixels
//				// and have some rational place to look for it...
//					ConvertBeamCtr_to_pix(folder,destPath)
				else
					// beam center is in pixels, so use the old routine
					ConvertBeamCtrPix_to_mm(folder,destPath)
				endif				
				
				
				// (2.5) Calculate the q-values
				// calculating q-values can't be done unless the non-linear corrections are calculated
				// so go ahead and put it in this loop.
				//
				
				Detector_CalcQVals(folder,destPath)
							
		else
			Print "Non-linear correction not done on RAW data"
		endif			
			
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
// ** as of 3/2023, one block of the DAS_logs is read in, entry/beam_stop/shape
// to get to the /size field, since for (unknown) techincal reasons, this field
// can't be written out to the NExus file. Again, the whole DAS_logs block is NOT
// read in - it simply slows things down way too much.
//
//
// if data destination is RAW, calling function sets DF before passing
// if data is to be sent to rawSANS, calling function sets DF to Packages:NIST level
// -- reset here to make sure
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
	//
	// counterintuitive logic here on my part. If it is trying to load in a work folder (like RAW)
	// - then "0" is returned (it's on the list), the folderStr is set to NULL, and data is loaded into the
	// current data folder (which was set to folderStr before entering this procedure
	// -- so this makes sure to NOT reset the data folder. If the folderStr is actually a raw file
	// name, then it loads into RawSANS and uses the file name for the folder.
	// -- very confused as to why I did this. Possibly some leftovers from the ansto reader 
	// that I copied some ideas from.
	//
	Variable isFolder = WhichListItem(folderStr,ksWorkFolderListShort+"RawSANS;")
	if(isFolder != -1)
		folderStr = ""
	else
		folderStr = StringFromList(0,FName,".")		// just the first part of the name, no .nxs.ngv
	endif
	String base_name = folderStr
	
	// be sure I'm in the right base data folder 
//	SetDataFolder ksBaseDFPath
	String curDF = GetDataFolder(1)

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+folderStr)
//		NewDataFolder/O/S $(ksBaseDFPath+":"+folderStr)
	endif
	
//////// loads everything with one line	 (includes /DAS_logs)
//////	HDF5LoadGroup/Z/L=7/O/R/T=$base_name  :, fileID, hdf5Path		//	recursive
////// /L=7 flag loads all data types, no /L acts as /L=7
////
//////		HDF5LoadGroup /O /R=2 /T /IMAG=1 :, fileID, hdf5Path		// Requires HDF5 XOP 1.24 or later
////		HDF5LoadGroup /O /R=2 /IMAG=1 :, fileID, hdf5Path		// Requires HDF5 XOP 1.24 or later



// load root/entry
	hdf5path = "/entry"
//	NewDataFolder/O $(curDF)
	if(isFolder == -1)
		NewDataFolder/O $(curDF+base_name)
	endif
	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry")
	else
		// base_name is "", so get rid of the leading ":" on ":entry"
		NewDataFolder/O/S $(curDF+base_name+"entry")
	endif
	HDF5LoadGroup/Z/L=7/O :, fileID, hdf5Path		//	NOT recursive


	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:control")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:control")
	endif
	hdf5path = "/entry/control"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:instrument")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:instrument")
	endif
	hdf5path = "/entry/instrument"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:reduction")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:reduction")
	endif	
	hdf5path = "/entry/reduction"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:sample")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:sample")
	endif	
	hdf5path = "/entry/sample"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive (This is the only one that may have duplicated groups)

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:user")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:user")
	endif	
	hdf5path = "/entry/user"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive


// not sure there's anything useful in this block
//
//
	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:program_data")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:program_data")
	endif	
	hdf5path = "/entry/program_data"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive


// for the 30m SANS, as of 3/2023, the size of the beam stop is not
// written out to the Nexus block, only to the DAS_logs in the location:
//
// entry:DAS_logs:beamStop:size
//
// -- do I read in just the beamStop block, or the whole DAS_log?
//
// -- reading in the whole DAS_logs is (2-4)x slower than skipping them, while just reading the 
//  single beamStop block makes no difference in the read time. so read whatI need, no more.
//
//	if(isFolder == -1)
//		NewDataFolder/O/S $(curDF+base_name+":entry:DAS_logs")
//	else
//		NewDataFolder/O/S $(curDF+base_name+"entry:DAS_logs")
//	endif
//	hdf5path = "/entry/DAS_logs"
//	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:DAS_logs")
		NewDataFolder/O/S $(curDF+base_name+":entry:DAS_logs:beamStop")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:DAS_logs")
		NewDataFolder/O/S $(curDF+base_name+"entry:DAS_logs:beamStop")
	endif
	hdf5path = "/entry/DAS_logs/beamStop"
	HDF5LoadGroup/Z/L=7/O/R=2  :, fileID, hdf5Path		//	YES recursive

	
//
	HDF5CloseFile/Z fileID


	//keep a string with the filename in the folder where the data was loaded
	SetDataFolder $(curDF)
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
	
	LoadRawSANSData(fname, "DIV")
	
//	String waveStr = "root:Packages:NIST:DIV:data"
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
xFunction ReadHeaderAndWork(type,fname)
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
/// -- if data requested from a WORK or SAS folder (for SASCALC):
// check to see if the value exists (It will be a wave)
// -- if it does, return the value from the local WORK folder
//		if it does not exist, return DUMMY value
//
//// -- if data requested from a file:
// check to see if the value exists locally in RawSANS (It will be a wave)
// -- if it does, return the value from the local folder
// -- if not, read the file in, then return the value
//
//
Function getRealValueFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	Variable errorValue = -999999
	
	folderStr = RemoveDotExtension(N_GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it, or report error
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+ksWorkFolderListExtra)
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawSANS)
	// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:"+folderStr+":"+path))
			Wave/Z w = $("root:Packages:NIST:"+folderStr+":"+path)
			return(w[0])
		else
			return(errorValue)
		endif
	endif


	// (2) requesting from a file.
	// look locally in RawSANS if possible, or if not, load in the data from disk
	// - if thee both fail, report an error
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file, putting the data in RawSANS
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
	
	folderStr = RemoveDotExtension(N_GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it
// no need to check for any existence, null return is OK
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+ksWorkFolderListExtra)
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawSANS)
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
		//then read in the file, putting the data in RawSANS
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
	
	folderStr = RemoveDotExtension(N_GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it
// no need to check for any existence, null return is OK
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+ksWorkFolderListExtra)
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawSANS)
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
		//then read in the file, putting the data in RawSANS
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
// check to see if the value exists locally in RawSANS (It will be a wave)
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
	
	folderStr = RemoveDotExtension(N_GetFileNameFromPathNoSemi(fname))

// (1) if requesting data from a WORK folder, get it, or report error
	Variable isWORKFolder = WhichListItem(fname,ksWorkFolderListShort+ksWorkFolderListExtra)
	if(isWORKFolder != -1)		//requesting value from a WORK folder (not RawSANS)
	// check for a work folder first (note that "entry" is now NOT doubled)
		if(Exists("root:Packages:NIST:"+folderStr+":"+path))
			Wave/Z/T tw = $("root:Packages:NIST:"+folderStr+":"+path)
			return(tw[0])
		else
			return(errorSTring)
		endif
	endif

// (2) requesting from a file.
// look locally in RawSANS if possible, or if not, load in the data from disk
// - if thee both fail, report an error	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawSANS
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



// function to list selected contents of a file to verify that the values
// have been stored (and are read in) with the expected units
//
// -- more items can be added in the future as needed
//
Proc VerifyImportantUnits(fname)
	String fname
	
	fVerifyImportantUnits(fname)
end

Function fVerifyImportantUnits(fname)
	String fname
	
	Variable val,val2
	String str
	
	Print "*** units listed are the EXPECTED units ****"
	Print "*** verify that the value makes sense with the listed units ***"
	
	// detector distance [cm]
	val = getDet_distance(fname)
	printf "Detector distance = %g [cm]\r",val
	
	// number of (x,y) pixels
	val = getDet_pixel_num_x(fname)
	val2 = getDet_pixel_num_y(fname)
	printf "Number of pixels (x,y) = (%d,%d)\r",val,val2
	
	// beam center (x,y) in pixels
	val = getDet_beam_center_x(fname)
	val2 = getDet_beam_center_y(fname)
	printf "Beam center in pixels (x,y) = (%g,%g)\r",val,val2

	// lateral offset in [cm]
	val = getDet_LateralOffset(fname)
	printf "Lateral offset = %g [cm]\r",val
	
	// pixel fwhm (x,y) in [cm]
	val = getDet_pixel_fwhm_x(fname)
	val2 = getDet_pixel_fwhm_y(fname)
	printf "Pixel FWHM (x,y) = (%g,%g) [cm]\r",val,val2

	// tube width [mm]
	val = getDet_tubeWidth(fname)
	printf "Tube width = %g [mm]\r",val
	
	// pixel size (x,y) in [mm]
	val = getDet_x_pixel_size(fname)
	val2 = getDet_y_pixel_size(fname)
	printf "Pixel size (x,y) = (%g,%g) [mm]\r",val,val2
	
	
	
	// beam stop size, diameter in [cm]
	val = getBeamStop_size(fname)
	printf "Beam stop diameter = %g [cm]\r",val
	
	
	// sample aperture diameter [mm]
	val = getSampleAp_size(fname)
	printf "Sample aperture diameter = %g [mm]\r",val

	// sample aperture distance (to sample, only a few cm) = [cm]
	val = getSampleAp_distance(fname)
	printf "Sample aperture distance (short) = %g [cm]\r",val
	
	
	// source aperture diameter [mm] (derived a text value!)
	val = getSourceAp_size(fname)
	printf "Source aperture diameter = %g [mm]\r",val

	// source aperture distance [cm]
	val = getSourceAp_distance(fname)
	printf "Source aperture distance = %g [cm]\r",val

	
	
	return(0)
End