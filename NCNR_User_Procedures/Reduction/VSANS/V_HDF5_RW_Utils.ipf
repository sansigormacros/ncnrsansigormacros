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
Macro LoadFakeDIVData()
	V_LoadHDF5Data("","DIV")
End

// passing null file string presents a dialog
Proc Read_HDF5_Raw_No_Attributes()
	V_LoadHDF5Data("","RAW")
End


// TODO:
//  x- move the initialization of the raw data folder to be in the as-yet unwritten initialization routine for
// reduction. be sure that it's duplicated in the VCALC initialization too.
// -- as needed, get rid of the FAKE redimension of the data from 3D->2D and from 128x128 to something else for VSANS
//    This is a fake since I don't have anything close to correct fake data yet. (1/29/16)
//
// TODO: -- is there an extra "entry" heading? Am I adding this by mistake by setting base_name="entry" for RAW data?
//			-- as dumb as it is -- do I just leave it now, or break everything. ont the plus side, removing the extra entry
//          layer may catch a lot of the hard-wired junk that is present...
Function V_LoadHDF5Data(file,folder)
	String file,folder

	String base_name,detStr
	String destPath
	Variable ii
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folder)
	destPath = "root:Packages:NIST:VSANS:"+folder

	if(cmpstr(folder,"RAW")==0)
		base_name="entry"
//		base_name="RAW"		// this acts as a flag to remove the duplicate "entry" level
	else
	// null will use the file name as the top level (above entry)
		base_name=""		//TODO -- remove this / change behavior in V_LoadHDF5_NoAtt()
	endif
	
	Variable err= V_LoadHDF5_NoAtt(file,base_name)	// reads into current folder
	
	// if RAW data, then generate the errors and linear data copy
	// do this 9x
	// then do any "massaging" needed to redimension, fake values, etc.
	//
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:entry:instrument:" 

	if(cmpstr(folder,"RAW")==0)
	
		// TODO -- once I get "real" data, get rid of this call to force the data to be proper dimensions.
		V_RedimFakeData()

		// makes data error and linear copy -- DP waves if V_RedimFakeData() called above 
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			V_MakeDataError(tmpStr+"detector_"+detStr)	
		endfor


		// TODO -- for the "real" data, may need a step in here to convert integer detector data to DP, or I'll
		//          get really odd results from the calculations, and may not even notice.
		// !!!! Where do I actually do this? - this is currently done in Raw_to_work()
		// -- is is better to do here, right as the data is loaded?
		// TODO -- some of this is done in V_RedimFakeData() above - which will disappear once I get real data

	
		// TODO
		//  -- get rid of these fake calibration waves as "real" ones are filled in by NICE
		Execute "MakeFakeCalibrationWaves()"
		//		fMakeFakeCalibrationWaves()		//skips the alert


		// TODO -- do I want to calculate the nonlinear x/y arrays and the q-values here?
		// -- otherwise the mouse-over doesn't calculate the correct Q_values
		// the display currently is not shifted or altered at all to account for the non-linearity
		// or for display in q-values -- so why bother with this?
		NVAR gDoNonLinearCor = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
		// generate a distance matrix for each of the detectors
		if (gDoNonLinearCor == 1)
			Print "Calculating Non-linear correction at RAW load time"// for "+ detStr
			for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
				detStr = StringFromList(ii, ksDetectorListNoB, ";")
				Wave w = V_getDetectorDataW(folder,detStr)
	//			Wave w_err = V_getDetectorDataErrW(fname,detStr)
				Wave w_calib = V_getDetTube_spatialCalib(folder,detStr)
				Variable tube_width = V_getDet_tubeWidth(folder,detStr)
				NonLinearCorrection(w,w_calib,tube_width,detStr,destPath)
				
				// (2.5) Calculate the q-values
				// calculating q-values can't be done unless the non-linear corrections are calculated
				// so go ahead and put it in this loop.
				// TODO : 
				// -- make sure that everything is present before the calculation
				// -- beam center must be properly defined in terms of real distance
				// -- distances/zero location/ etc. must be clearly documented for each detector
				//	** this assumes that NonLinearCorrection() has been run to generate data_RealDistX and Y
				// ** this routine Makes the waves QTot, qx, qy, qz in each detector folder.
				//
				V_Detector_CalcQVals(folder,detStr,destPath)
				
			endfor
		else
			Print "Non-linear correction not done"
		endif
					
					
		/// END FAKE DATA CORRECTIONS		
			
	endif
	
	SetDataFolder root:
	return(err)
End

//
// TODO -- this is all FAKED since all the data arrays are written to hdf as (1,128,128)
//  -- try to fill in the bits from VCALC, if it exists (or force it)
//
// the SetScale parts may be useful later.
//
Function V_RedimFakeData()
	
	// check for fake data in VCALC folder...
	wave/Z tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_B:det_B"
	if(WaveExists(tmpw) == 0)
		Execute "VCALC_Panel()"
	endif
	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_B
	Wave det_B=data
	Redimension/N=(320,320)/E=1 det_B	
	Redimension/D det_B
//	det_B = p+q+2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_B:det_B"
	det_B=tmpw
	det_B += 2
			
	Variable ctr=20,npix=128
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MT
	Wave det_MT=data
	Redimension/N=(npix,48)/E=1 det_MT
	Redimension/D det_MT		
	SetScale/I x -npix/2,npix/2,"",det_MT
	SetScale/I y ctr,ctr+48,"",det_MT
//	det_MT *= 10
//	det_MT += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_MT:det_MT"
	det_MT=tmpw
	det_MT += 2
	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MB
	Wave det_MB=data
	Redimension/N=(npix,48)/E=1 det_MB		
	Redimension/D det_MB
	SetScale/I x -npix/2,npix/2,"",det_MB
	SetScale/I y -ctr-48,-ctr,"",det_MB
//	det_MB *= 5
//	det_MB += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_MB:det_MB"
	det_MB=tmpw
	det_MB += 2
	
	ctr=30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_ML
	Wave det_ML=data
	Redimension/N=(48,npix)/E=1 det_ML		
	Redimension/D det_ML
	SetScale/I x -ctr-48,-ctr,"",det_ML
	SetScale/I y -npix/2,npix/2,"",det_ML
//	det_ML *= 2
//	det_ML += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_ML:det_ML"
	det_ML=tmpw
	det_ML += 2
		
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MR
	Wave det_MR=data
	Redimension/N=(48,npix)/E=1 det_MR		
	Redimension/D det_MR
	SetScale/I x ctr,ctr+48,"",det_MR
	SetScale/I y -npix/2,npix/2,"",det_MR
//	det_MR +=2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_MR:det_MR"
	det_MR=tmpw
	det_MR += 2
	
	ctr=30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FT
	Wave det_FT=data
	Redimension/N=(npix,48)/E=1 det_FT		
	Redimension/D det_FT
	SetScale/I x -npix/2,npix/2,"",det_FT
	SetScale/I y ctr,ctr+48,"",det_FT
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_FT:det_FT"
	det_FT=tmpw

	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FB
	Wave det_FB=data
	Redimension/N=(npix,48)/E=1 det_FB		
	Redimension/D det_FB
	SetScale/I x -npix/2,npix/2,"",det_FB
	SetScale/I y -ctr-48,-ctr,"",det_FB
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_FB:det_FB"
	det_FB=tmpw
			
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FL
	Wave det_FL=data
	Redimension/N=(48,npix)/E=1 det_FL		
	Redimension/D det_FL
	SetScale/I x -ctr-48,-ctr,"",det_FL
	SetScale/I y -npix/2,npix/2,"",det_FL
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_FL:det_FL"
	det_FL=tmpw
	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FR
	Wave det_FR=data
	Redimension/N=(48,npix)/E=1 det_FR		
	Redimension/D det_FR
	SetScale/I x ctr,ctr+48,"",det_FR
	SetScale/I y -npix/2,npix/2,"",det_FR
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:entry:instrument:detector_FR:det_FR"
	det_FR=tmpw
	
// get rid of zeros
	det_FL += 2
	det_FR += 2
	det_FT += 2
	det_FB += 2

V_RescaleToBeamCenter("RAW","MB",64,55)
V_RescaleToBeamCenter("RAW","MT",64,-8.7)
V_RescaleToBeamCenter("RAW","MR",-8.1,64)
V_RescaleToBeamCenter("RAW","ML",55,64)
V_RescaleToBeamCenter("RAW","FL",55,64)
V_RescaleToBeamCenter("RAW","FR",-8.1,64)
V_RescaleToBeamCenter("RAW","FT",64,-8.7)
V_RescaleToBeamCenter("RAW","FB",64,55)



	return(0)
End


// This loads for speed, since loading the attributes takes a LOT of time.
//
// this will load in the whole HDF file all at once.
// Attributes are NOT loaded at all.
//
// TODO: 
// -x remove the P=home restriction top make this more generic (replaced with catPathName from PickPath)
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
//	HDF5OpenFile/R/P=home/Z fileID as fileName		//read file from home directory?
	HDF5OpenFile/R/P=catPathName/Z fileID as fileName
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
	if(cmpstr(base_name,"RAW") == 0)
		base_name = ""
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
// TODO:
// currently, the work folders have the following path - so passing in "RAW" as fname
// will take some re-configuring. 
//  root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FL:distance
// -- be sure this read from work folders is not broken in the future, and is passed to ALL of the
//    top-level R/W routines. (Write is necessary ONLY for SIM data files. Patch is direct to disk.)
Function V_getRealValueFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

// check for a work folder first (note that "entry" is doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path))
		Wave/Z w = $("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path)
		return(w[0])
	endif
	
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

// check for a work folder first (note that "entry" is doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path))
		Wave wOut = $("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path)
		return wOut
	endif
		
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

// check for a work folder first (note that "entry" is doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path))
		Wave/T wOut = $("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path)
		return wOut
	endif
	
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

// check for a work folder first (note that "entry" is doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path))
		Wave/Z/T tw = $("root:Packages:NIST:VSANS:"+folderStr+":entry:"+path)
		return(tw[0])
	endif
	
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
// -- the lines to create a missing group have been commented out to avoid filling
//    in missing fields that should have been generated by the data writer. Need to make
//    a separate function that will write and generate if needed, and use this in specific cases
//    only if I really have to force it.
//	
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function V_WriteWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave wav
	
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
// TODO
//
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function V_WriteTextWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave/T wav
	
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

// TODO:
// -- this must be called as needed to force a re-read of the data from disk
//    "as needed" means that when an operation is done that needs to ensure
//     a fresh read from disk, it must take care of the kill.
// -- the ksBaseDFPath needs to be removed. It's currently pointing to RawVSANS, which is
//    really not used as intended anymore.
//
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
// returns the input string if a "." can't be found (maybe it wasn't there)
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