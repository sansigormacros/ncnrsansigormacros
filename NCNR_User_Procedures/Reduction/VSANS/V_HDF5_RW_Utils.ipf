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

// the list of WORK Folders
Strconstant ksWorkFolderList = "RAW;SAM;EMP;BGD;COR;DIV;ABS;MSK;CAL;STO;SUB;DRK;ADJ;VCALC;RawVSANS;"
Strconstant ksWorkFolderListShort = "RAW;SAM;EMP;BGD;COR;DIV;ABS;MSK;CAL;STO;SUB;DRK;ADJ;"


// passing null file string presents a dialog
Proc LoadFakeDIVData()
	V_LoadHDF5Data("","DIV")
End

// Moved to V_MaskUtils.ipf
// passing null file string presents a dialog
//Proc LoadFakeMASKData()
//	V_LoadHDF5Data("","MSK")
//End

// passing null file string presents a dialog
Proc Read_HDF5_Raw_No_Attributes()
	V_LoadHDF5Data("","RAW")
End


// TODO:
//  x- move the initialization of the raw data folder to be in the as-yet unwritten initialization routine for
// reduction. be sure that it's duplicated in the VCALC initialization too.
// x- as needed, get rid of the FAKE redimension of the data from 3D->2D and from 128x128 to something else for VSANS
//    This is a fake since I don't have anything close to correct fake data yet. (1/29/16)
//
// DONE: x- is there an extra "entry" heading? Am I adding this by mistake by setting base_name="entry" for RAW data?
//			x- as dumb as it is -- do I just leave it now, or break everything. On the plus side, removing the extra "entry"
//          layer may catch a lot of the hard-wired junk that is present...
//      extra entry layer is no longer generated for any WORK folders
//
Function V_LoadHDF5Data(file,folder)
	String file,folder

	String base_name,detStr
	String destPath
	Variable ii
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folder)
	destPath = "root:Packages:NIST:VSANS:"+folder

	Variable err= V_LoadHDF5_NoAtt(file,folder)	// reads into current folder
	
	// if RAW data, then generate the errors and linear data copy
	// do this 9x
	// then do any "massaging" needed to redimension, fake values, etc.
	//
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:" 

	if(cmpstr(folder,"RAW")==0)
	
		// TODO -- once I get "real" data, get rid of this call to force the data to be proper dimensions.
//		V_RedimFakeData()
		
		V_MakeDataWaves_DP(folder)
//		V_FakeBeamCenters()
//		V_FakeScaleToCenter()
		

		// makes data error and linear copy -- DP waves if V_MakeDataWaves_DP() called above 
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			V_MakeDataError(tmpStr+"detector_"+detStr)	
		endfor

		// TODO
		//  -- get rid of these fake calibration waves as "real" ones are filled in by NICE
//		(currently does nothing)
//		Execute "MakeFakeCalibrationWaves()"
		
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
	//			Wave w_err = V_getDetectorDataErrW(fname,detStr)		//not here, done above w/V_MakeDataError()
				Wave w_calib = V_getDetTube_spatialCalib(folder,detStr)
				Variable tube_width = V_getDet_tubeWidth(folder,detStr)
				V_NonLinearCorrection(w,w_calib,tube_width,detStr,destPath)
				
				
				//(2.4) Convert the beam center values from pixels to mm
				// TODO -- there needs to be a permanent location for these values??
				//
				V_ConvertBeamCtr_to_mm(folder,detStr,destPath)
				
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
			
			//"B" is separate
			V_NonLinearCorrection_B(folder,"B",destPath)
			V_ConvertBeamCtr_to_mmB(folder,"B",destPath)
			V_Detector_CalcQVals(folder,"B",destPath)
			
		else
			Print "Non-linear correction not done"
		endif
					
					
		/// END FAKE DATA CORRECTIONS		
			
	endif
	
	SetDataFolder root:
	return(err)
End

// fname is the folder = "RAW"
Function V_MakeDataWaves_DP(fname)
	String fname
	
	Variable ii
	String detStr
	
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave w = V_getDetectorDataW(fname,detStr)
//		Wave w_err = V_getDetectorDataErrW(fname,detStr)  //not here, done above w/V_MakeDataError()
		Redimension/D w
//		Redimension/D w_err
	endfor
	
	return(0)
End



//
// TODO -- this is all FAKED since all the data arrays are written to hdf as (1,128,128)
//  -- try to fill in the bits from VCALC, if it exists (or force it)
//
// the SetScale parts may be useful later.
//
// This is NOT CALLED anymore.
// the rescaling (SetScale) of the data sets is still done separately to a "fake" beam center
Function xV_RedimFakeData()
	
	// check for fake data in VCALC folder...
	wave/Z tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B:det_B"
	if(WaveExists(tmpw) == 0)
		Execute "VCALC_Panel()"
	endif
	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B
	Wave det_B=data
//	Redimension/N=(150,150)/E=1 det_B	
	Redimension/D det_B
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B:det_B"
//	det_B=tmpw
//	det_B += 2
	Wave distance=distance
	distance = VCALC_getSDD("B")*100		// to convert m to cm

			
	Variable ctr=20,npix=128
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MT
	Wave det_MT=data
//	Redimension/N=(npix,48)/E=1 det_MT
	Redimension/D det_MT		
	SetScale/I x -npix/2,npix/2,"",det_MT
	SetScale/I y ctr,ctr+48,"",det_MT
//	det_MT *= 10
//	det_MT += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MT:det_MT"
//	det_MT=tmpw
//	det_MT += 2
	Wave distance=distance
	distance = VCALC_getSDD("MT")*100		// to convert m to cm

	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MB
	Wave det_MB=data
//	Redimension/N=(npix,48)/E=1 det_MB		
	Redimension/D det_MB
	SetScale/I x -npix/2,npix/2,"",det_MB
	SetScale/I y -ctr-48,-ctr,"",det_MB
//	det_MB *= 5
//	det_MB += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MB:det_MB"
//	det_MB=tmpw
//	det_MB += 2
	Wave distance=distance
	distance = VCALC_getSDD("MB")*100		// to convert m to cm

	
	ctr=30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_ML
	Wave det_ML=data
//	Redimension/N=(48,npix)/E=1 det_ML		
	Redimension/D det_ML
	SetScale/I x -ctr-48,-ctr,"",det_ML
	SetScale/I y -npix/2,npix/2,"",det_ML
//	det_ML *= 2
//	det_ML += 2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_ML:det_ML"
//	det_ML=tmpw
//	det_ML += 2
	Wave distance=distance
	distance = VCALC_getSDD("ML")*100		// to convert m to cm

		
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MR
	Wave det_MR=data
//	Redimension/N=(48,npix)/E=1 det_MR		
	Redimension/D det_MR
	SetScale/I x ctr,ctr+48,"",det_MR
	SetScale/I y -npix/2,npix/2,"",det_MR
//	det_MR +=2
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MR:det_MR"
//	det_MR=tmpw
//	det_MR += 2
	Wave distance=distance
	distance = VCALC_getSDD("MR")*100		// to convert m to cm
	
	
	ctr=30
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FT
	Wave det_FT=data
//	Redimension/N=(npix,48)/E=1 det_FT		
	Redimension/D det_FT
	SetScale/I x -npix/2,npix/2,"",det_FT
	SetScale/I y ctr,ctr+48,"",det_FT
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FT:det_FT"
//	det_FT=tmpw
	Wave distance=distance
	distance = VCALC_getSDD("FT")*100		// to convert m to cm


	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB
	Wave det_FB=data
//	Redimension/N=(npix,48)/E=1 det_FB		
	Redimension/D det_FB
	SetScale/I x -npix/2,npix/2,"",det_FB
	SetScale/I y -ctr-48,-ctr,"",det_FB
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FB:det_FB"
//	det_FB=tmpw
	Wave distance=distance
	distance = VCALC_getSDD("FB")*100		// to convert m to cm

			
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL
	Wave det_FL=data
//	Redimension/N=(48,npix)/E=1 det_FL		
	Redimension/D det_FL
	SetScale/I x -ctr-48,-ctr,"",det_FL
	SetScale/I y -npix/2,npix/2,"",det_FL
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FL:det_FL"
//	det_FL=tmpw
	Wave distance=distance
	distance = VCALC_getSDD("FL")*100		// to convert m to cm

	
	SetDataFolder root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FR
	Wave det_FR=data
//	Redimension/N=(48,npix)/E=1 det_FR		
	Redimension/D det_FR
	SetScale/I x ctr,ctr+48,"",det_FR
	SetScale/I y -npix/2,npix/2,"",det_FR
	wave tmpw=$"root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FR:det_FR"
//	det_FR=tmpw
	Wave distance=distance
	distance = VCALC_getSDD("FR")*100		// to convert m to cm

	
// get rid of zeros
//	det_FL += 2
//	det_FR += 2
//	det_FT += 2
//	det_FB += 2


// fake beam center values
	V_putDet_beam_center_x("RAW","B",75)
	V_putDet_beam_center_y("RAW","B",75)

	V_putDet_beam_center_x("RAW","MB",64)
	V_putDet_beam_center_y("RAW","MB",55)
	V_putDet_beam_center_x("RAW","MT",64)
	V_putDet_beam_center_y("RAW","MT",-8.7)
	V_putDet_beam_center_x("RAW","MR",-8.1)
	V_putDet_beam_center_y("RAW","MR",64)
	V_putDet_beam_center_x("RAW","ML",55)
	V_putDet_beam_center_y("RAW","ML",64)

	V_putDet_beam_center_x("RAW","FB",64)
	V_putDet_beam_center_y("RAW","FB",55)
	V_putDet_beam_center_x("RAW","FT",64)
	V_putDet_beam_center_y("RAW","FT",-8.7)
	V_putDet_beam_center_x("RAW","FR",-8.1)
	V_putDet_beam_center_y("RAW","FR",64)
	V_putDet_beam_center_x("RAW","FL",55)
	V_putDet_beam_center_y("RAW","FL",64)


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
// -- the Gateway function H5GW_ReadHDF5(parentFolder, fileName, [hdf5Path])
//    reads in the attributes too, but is very slow
//   -- the H5GW function is called by: H_HDF5Gate_Read_Raw(file)
//
// TODO: 
// -x remove the P=home restriction top make this more generic (replaced with catPathName from PickPath)
// -- get rid of bits leftover here that I don't need
// -- be sure I'm using all of the correct flags in the HDF5LoadGroup operation
// -- settle on how the base_name is to be used. "entry" for the RAW, fileName for the "rawVSANS"?
// x- error check for path existence
//
// passing in "" for base_name will take the name from the file name as selected
//
Function V_LoadHDF5_NoAtt(fileName,base_name)
	String fileName, base_name
	
//	if ( ParamIsDefault(hdf5Path) )
//		hdf5Path = "/"
//	endif

	PathInfo/S catPathName
	if(V_flag == 0)
		V_PickPath()
	endif

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
//	if(cmpstr(base_name,"") == 0)
//		base_name = StringFromList(0,FileName,".")
//	endif
	
	// if base_name is from my list of WORK folders, then base_name = ""
	// use a stringSwitch? WhichListItem?
	Variable isFolder = WhichListItem(base_name,ksWorkFolderList)
	if(isFolder != -1)
		base_name = ""
	else
		base_name = StringFromList(0,FileName,".")		// just the first part of the name, no .nxs.ngv
	endif


// TODO
// -- write a separate function or add a flag to this one that will read everything, including the DAS_logs
//   -- the DAS_logs are not needed for reduction, and slow everything down a LOT (0.6 s per file vs 0.04 s per file!)

//
//// loads everything with one line	 (includes /DAS_logs)
//	HDF5LoadGroup/Z/L=7/O/R/T=$base_name  :, fileID, hdf5Path		//	recursive
//



//// to skip DAS_logs. I need to generate all of the data folders myself
//// must be an easier way to handle the different path syntax, but at least this works

	String curDF = GetDataFolder(1)

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
	HDF5LoadGroup/Z/L=7/O/R  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:instrument")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:instrument")
	endif
	hdf5path = "/entry/instrument"
	HDF5LoadGroup/Z/L=7/O/R  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:reduction")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:reduction")
	endif	
	hdf5path = "/entry/reduction"
	HDF5LoadGroup/Z/L=7/O/R  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:sample")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:sample")
	endif	
	hdf5path = "/entry/sample"
	HDF5LoadGroup/Z/L=7/O/R  :, fileID, hdf5Path		//	YES recursive

	if(isFolder == -1)
		NewDataFolder/O/S $(curDF+base_name+":entry:user")
	else
		NewDataFolder/O/S $(curDF+base_name+"entry:user")
	endif	
	hdf5path = "/entry/user"
	HDF5LoadGroup/Z/L=7/O/R  :, fileID, hdf5Path		//	YES recursive


	
	if ( V_Flag != 0 )
		Print fileName + ": could not open as HDF5 file"
		setdatafolder root:
		return (0)
	endif

	HDF5CloseFile fileID
	
//s_toc()

	SetDataFolder root:
	
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
//  root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:distance
// -- be sure this read from work folders is not broken in the future, and is passed to ALL of the
//    top-level R/W routines. (Write is necessary ONLY for SIM data files. Patch is direct to disk.)
Function V_getRealValueFromHDF5(fname,path)
	String fname,path

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

// check for a work folder first (note that "entry" is now NOT doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		Wave/Z w = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
		return(w[0])
	endif
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname,"")
		SetDataFolder root:
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

// check for a work folder first (note that "entry" is NOT doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		Wave wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
		return wOut
	endif
		
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname,"")
		SetDataFolder root:
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

// check for a work folder first (note that "entry" is NOT doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		Wave/T wOut = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
		return wOut
	endif
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif
	
	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname,"")
		SetDataFolder root:
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
// -- currently num is completely ignored
//
Function/S V_getStringFromHDF5(fname,path,num)
	String fname,path
	Variable num

	String folderStr=""
	Variable valExists=0
	
	folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))

// check for a work folder first (note that "entry" is NOT doubled)
	if(Exists("root:Packages:NIST:VSANS:"+folderStr+":"+path))
		Wave/Z/T tw = $("root:Packages:NIST:VSANS:"+folderStr+":"+path)
		return(tw[0])
	endif
	
	if(Exists(ksBaseDFPath+folderStr+":"+path))
		valExists=1
	endif

	if(!valExists)
		//then read in the file, putting the data in RawVSANS
		SetDataFolder ksBaseDFPath
		V_LoadHDF5_NoAtt(fname,"")
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
// --Attributes are not currently saved. Fix this, maybe make it optional? See the help file for
//  DemoAttributes(w) example under the HDF5SaveData operation
//	
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function V_WriteWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave wav
	
	
	// try a local folder first, then try to save to disk
	//
	String folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	String localPath = "root:Packages:NIST:VSANS:"+folderStr//+":entry"
	localPath += groupName + "/" + varName
	// make everything colons for local data folders
	localPath = ReplaceString("/", localPath, ":")
	
	Wave/Z w = $localPath
	if(waveExists(w) == 1)
		w = wav
//		Print "write to local folder done"
		return(0)		//we're done, get out
	endif
	
	
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
// TODO
//
// -x change the /P=home to the user-defined data path (catPathName)		
//
Function V_WriteTextWaveToHDF(fname, groupName, varName, wav)
	String fname, groupName, varName
	Wave/T wav

	// try a local folder first, then try to save to disk
	//
	String folderStr = V_RemoveDotExtension(V_GetFileNameFromPathNoSemi(fname))
	
	String localPath = "root:Packages:NIST:VSANS:"+folderStr//+":entry"
	localPath += groupName + "/" + varName
	// make everything colons for local data folders
	localPath = ReplaceString("/", localPath, ":")
	
	Wave/Z/T w = $localPath
	if(waveExists(w) == 1)
		w = wav
		Print "write to local folder done"
		return(0)		//we're done, get out
	endif
	
	
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
Proc Save_VSANS_file(dfPath, filename)
	String dfPath	="root:VSANS_file"		// e.g., "root:FolderA" or ":"
	String filename = "Test_VSANS_file.h5"
	
	H_NXSANS_SaveGroupAsHDF5(dfPath, filename)
End


//	
// this is my procedure to save the folders to HDF5, once I've filled the folder tree
//
// this does NOT save attributes, but gets the folder structure correct
//
Function H_NXSANS_SaveGroupAsHDF5(dfPath, filename)
	String dfPath	// e.g., "root:FolderA" or ":"
	String filename

	Variable result = 0	// 0 means no error
	
	Variable fileID
	HDF5CreateFile/P=home /O /Z fileID as filename
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

