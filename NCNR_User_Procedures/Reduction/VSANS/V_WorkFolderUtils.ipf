#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion = 7.00

//*******************
// Vers 1.0 JAN2016
//
//*******************
//  VSANS Utility procedures for handling of workfiles (each is housed in a separate datafolder)
//
// - adding RAW data to a workfile
// -- **this conversion applies the detector corrections**
// -- Raw_to_work(newType) IS THE MAJOR ROUTINE TO APPLY DETECTOR CORRECTIONS
//
//
// - copying workfiles to another folder
//
// - absolute scaling
//
// - (no) the WorkFile Math panel for simple image math (not done - maybe in the future?)
// - 
// - (no) adding work.drk data without normalizing to monitor counts (the case not currently handled)
//***************************

//
// Functions used for manipulation of the local Igor "WORK" folder
// structure as raw data is displayed and processed.
//
//


//
//Entry procedure from main panel
//
Proc V_CopyWorkFolder(oldType,newType)
	String oldType,newType
	Prompt oldType,"Source WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
	Prompt newType,"Destination WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"

	// data folder "old" will be copied to "new" (either kills/copies or will overwrite)
	V_CopyHDFToWorkFolder(oldtype,newtype)
End

//
// copy what is needed for data processing (not the DAS_logs)
// from the RawVSANS storage folder to the local WORK folder as needed
//
//
// (DONE) - decide what exactly I need to copy over. May be best to copy all, and delete
//       what I know that I don't need
//
// (DONE) !!! DuplicateDataFolder will FAIL - in the base case of RAW data files, the
//  data is actually in use - so it will fail every time. need an alternate solution. in SANS,
// there are a limited number of waves to carry over, so Duplicate/O is used for rw, tw, data, etc.
//
// (DONE) : I also need a list of what is generated during processing that may be hanging around - that I need to
//     be sure to get rid of - like the calibration waves, solidAngle, etc.
//
// hdfDF is the name only of the data in storage. May be full file name with extension (clean as needed)
// type is the destination WORK folder for the copy
//
Function V_CopyHDFToWorkFolder(fromStr,toStr)
	String fromStr,toStr
	
	String fromDF, toDF
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:VSANS:"+fromStr
	toDF = "root:Packages:NIST:VSANS:"+toStr
	
//	// make a copy of the file name for my own use, since it's not in the file
//	String/G $(toDF+":file_name") = root:
	
	// check to see if the data folder exists, if so, try to kill
	// if it deosn't exist then do nothing (as for duplication for polarized beam)
	if(DataFolderExists(toDF))
		KillDataFolder/Z $toDF			//DuplicateDataFolder will not overwrite, so Kill
	endif
	
	if(V_flag == 0)		// kill DF was OK
		DuplicateDataFolder $("root:Packages:NIST:VSANS:"+fromStr),$("root:Packages:NIST:VSANS:"+toStr)
		
		// I can delete these if they came along with RAW
		//   DAS_logs
		//   top-level copies of data (duplicate links, these should not be present in a proper NICE file)
		KillDataFolder/Z $(toDF+":entry:DAS_logs")
		KillDataFolder/Z $(toDF+":entry:data")
		KillDataFolder/Z $(toDF+":entry:data_B")
		KillDataFolder/Z $(toDF+":entry:data_ML")
		KillDataFolder/Z $(toDF+":entry:data_MR")
		KillDataFolder/Z $(toDF+":entry:data_MT")
		KillDataFolder/Z $(toDF+":entry:data_MB")
		KillDataFolder/Z $(toDF+":entry:data_FL")
		KillDataFolder/Z $(toDF+":entry:data_FR")
		KillDataFolder/Z $(toDF+":entry:data_FT")
		KillDataFolder/Z $(toDF+":entry:data_FB")

		return(0)
	else
	
		V_KillWavesFullTree($toDF,toStr,0,"",1)			// this will traverse the whole tree, trying to kill what it can

		if(DataFolderExists("root:Packages:NIST:VSANS:"+toStr) == 0)		//if the data folder (RAW, SAM, etc.) was just killed?
			NewDataFolder/O $("root:Packages:NIST:VSANS:"+toStr)
		endif	
			
		// need to do this the hard way, duplicate/O recursively
		// see V_CopyToWorkFolder()

		// gFileList is above "entry" which is my additions
		SVAR fileList_dest = $("root:Packages:NIST:VSANS:"+toStr+":gFileList")
		SVAR fileList_tmp = $("root:Packages:NIST:VSANS:"+fromStr+":gFileList")
		fileList_dest = fileList_tmp
	
		// everything on the top level
		V_DuplicateDataFolder($(fromDF+":entry"),fromStr,toStr,0,"",0)	//no recursion here
		// control
		V_DuplicateDataFolder($(fromDF+":entry:control"),fromStr,toStr,0,"",1)	//yes recursion here
		// instrument
		V_DuplicateDataFolder($(fromDF+":entry:instrument"),fromStr,toStr,0,"",1)	//yes recursion here
		// reduction
		V_DuplicateDataFolder($(fromDF+":entry:reduction"),fromStr,toStr,0,"",1)	//yes recursion here
		// sample
		V_DuplicateDataFolder($(fromDF+":entry:sample"),fromStr,toStr,0,"",1)	//yes recursion here
		// user
		V_DuplicateDataFolder($(fromDF+":entry:user"),fromStr,toStr,0,"",1)	//yes recursion here
		
	endif	
	
	return(0)
end



Function V_KillWavesInFolder(folderStr)
	String folderStr
	
	if(DataFolderExists(folderStr) && strlen(folderStr) != 0)
		SetDataFolder $folderStr
		KillWaves/A/Z
	endif
	
	SetDataFolder root:
	return(0)
end

////////
// see the help entry for IndexedDir for help on (possibly) how to do this faster
// -- see  Function ScanDirectories(pathName, printDirNames)
//


// from IgorExchange On July 17th, 2011 jtigor
// started from "Recursively List Data Folder Contents"
// Posted July 15th, 2011 by hrodstein
//
//
//
Proc V_CopyWorkFolderProc(dataFolderStr, fromStr, toStr, level, sNBName, recurse)
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
		
		V_WriteBrowserInfo_test(sString, 1, sNBName)
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
		
		V_WriteBrowserInfo_test(sString, 2, sNBName)
	endfor	
 
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		V_WriteBrowserInfo_test(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		V_WriteBrowserInfo_test(sString, 4, sNBName)
	endfor	

	if(recurse) 
		Variable numDataFolders = CountObjectsDFR(dfr, 4)	
		for(i=0; i<numDataFolders; i+=1)
			name = GetIndexedObjNameDFR(dfr, 4, i)
//			sPrintf sString, "%s%s (data folder)\r", indentStr, name
			 dfName = GetDataFolder(1, dfr)
			 
			toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
			
			name = CleanupName(name,0)			// added April 2019 SRK to handle names of temperature controllers with spaces
			sprintf sString, "NewDataFolder/O %s\r",toDF+name
			NewDataFolder/O $(toDF+name)
			
			
			V_WriteBrowserInfo_test(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			V_DuplicateDataFolder(childDFR, fromStr, toStr, level+1, sNBName, recurse)
		endfor	
	endif
	 

End


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
Function V_KillWavesFullTree(dfr, fromStr, level, sNBName,recurse)
	DFREF dfr
	String fromStr
//	String toStr
	Variable level			// Pass 0 to start
 	String sNBName
 	Variable recurse
 
	String name
	String dfName
 	String sString
 	
 	String toDF = ""
 
	if (level == 0)		// this is the data folder, generate if needed in the destination
		name = GetDataFolder(1, dfr)
		sPrintf sString, "%s (data folder)\r", name
//		toDF = ReplaceString(fromStr,name,toStr,1)		// case-sensitive replace
//		sprintf sString, "NewDataFolder/O %s\r",toDF
//		NewDataFolder/O $(RemoveEnding(toDF,":"))			// remove trailing semicolon if it's there
		
		V_WriteBrowserInfo_test(sString, 1, sNBName)
	endif
 
 	dfName = GetDataFolder(1, dfr)
// 	toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
	Variable i
 
	String indentStr = "\t"
	for(i=0; i<level; i+=1)
		indentStr += "\t"
	endfor
 
	Variable numWaves = CountObjectsDFR(dfr, 1)
	for(i=0; i<numWaves; i+=1)
		name = GetIndexedObjNameDFR(dfr, 1, i)
		//
		// wave type does not matter now. Kill does not care
		//
		sPrintf sString, "Killing  %s\r",dfName+name
		KillWaves/Z $(dfName+name)
		
		V_WriteBrowserInfo_test(sString, 2, sNBName)
	endfor	
 
 // now kill the data folder if possible
 	KillDataFolder/Z $dfName
 	
 	
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		V_WriteBrowserInfo_test(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		V_WriteBrowserInfo_test(sString, 4, sNBName)
	endfor	

	if(recurse) 
		Variable numDataFolders = CountObjectsDFR(dfr, 4)	
		for(i=0; i<numDataFolders; i+=1)
			name = GetIndexedObjNameDFR(dfr, 4, i)
			sPrintf sString, "%s%s (data folder)\r", indentStr, name
			 dfName = GetDataFolder(1, dfr)
			 
//			toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
//			sprintf sString, "NewDataFolder/O %s\r",toDF+name
//			NewDataFolder/O $(toDF+name)
			
			
			V_WriteBrowserInfo_test(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			V_KillWavesFullTree(childDFR, fromStr, level+1, sNBName, recurse)
		endfor	
	endif
	 

End
 


Function V_WriteBrowserInfo_test(sString, vType, sNBName)
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


//
// given the folder, duplicate the data -> linear_data and generate the error
//
// x- do I want to use different names here? If it turns out that I don't need to drag a copy of
//    the data around as "linear_data", then I can eliminate that, and rename the error wave
// x- be sure the data is either properly written as 2D in the file, or converted to 2D before
//    duplicating here
// x- ? do I recast to DP here? No- V_MakeDataWaves_DP() is called directly prior to this call, so data
//     coming in is already DP
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
	
	Duplicate/O linear_data_error data_error			
	//
	
	SetDataFolder root:
	return(0)
End


/////////////////////



//testing procedure
// (DONE) -- can't duplicate this with another proceudre, but if I change the name of the variable
//   "newType" to "type", then when Raw_to_work() gets to CopyHDFToWorkFolder(), the KillDataFolder/Z
//   line fails (but reports no error), then DuplicateDataFolder fails, and reports an error. Trying
//   to simplify this condition, I can't reproduce the bug for WM...
Proc V_Convert_to_Workfile(newtype, doadd)
	String newtype,doadd
	Prompt newtype,"WORK data type",popup,"SAM;EMP;BGD;ADJ;"
	Prompt doadd,"Add to current WORK contents?",popup,"No;Yes;"
	
	//macro will take whatever is in RAW folder and "ADD" it to the folder specified
	//in the popup menu
	
	//"add" = yes/no, don't add to previous runs
	//switch here - two separate functions to avoid (my) confusion
	Variable err// = Raw_to_work(newtype)
	if(cmpstr(doadd,"No")==0)
		//don't add to prev work contents, copy RAW contents to work and convert
		err = V_Raw_to_work(newtype)
	else
		//yes, add RAW to the current work folder contents
		//Abort "Adding RAW data files is currently unsupported"
		err = V_Add_raw_to_work(newtype)
	endif
	
	String newTitle = "WORK_"+newtype
	DoWindow/F VSANS_Data
	DoWindow/T VSANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	V_UpdateDisplayInformation(newtype)
	
End


//
// THIS IS THE MAJOR ROUTINE TO APPLY DATA CORRECTIONS
// 
//will copy the current contents of the RAW folder to the newType work folder
//and do the geometric corrections and normalization to monitor counts
//(the function Add_Raw_to_work(type) adds multiple runs together - and is LOW priority)
//
// JUL 2018
// now removes a constant kReadNoiseLevel from the back detector (this is a constant value, not time
//  or count dependent). It does not appear to be dependent on gain, and is hoepfully stable over time.
//
// May 2019
// If present, a detector image of the back detector containing the read noise (non-uniform values)
//  is subtracted rather than a single constant value.
//
//the current display type is updated to newType (global)
//
Function V_Raw_to_work(newType)
	String newType
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale
	String destPath
	
	String fname = newType
	String detStr
	Variable ctTime

	//initialize values before normalization
	total_mon=0
	total_det=0
	total_trn=0
	total_numruns=0
	total_rtime=0
	
	//Not adding multiple runs, so wipe out the old contents of the work folder and 
	// replace with the contents of raw

	destPath = "root:Packages:NIST:VSANS:" + newType
	
	//copy from current dir (RAW) to work, defined by newType
	V_CopyHDFToWorkFolder("RAW",newType)
	
	// now work with the waves from the destination folder.	
	
	// apply corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	// start with the DIV correction, before conversion to mm
	// then do all of the other corrections, order doesn't matter.
	// rescaling to default monitor counts however, must be LAST.

// each correction must loop over each detector. tedious.

	//except for removing the read noise of the back detector
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	if(gIgnoreDetB == 0)
		Wave w = V_getDetectorDataW(fname,"B")
		// I hate to hard-wire this, but the data must be in this specific location...
		Wave/Z w_ReadNoise = $("root:Packages:NIST:VSANS:ReadNoise:entry:instrument:detector_B:data")
//		Wave/Z w_ReadNoise = V_getDetectorDataW("ReadNoise","B")
		
		if(WaveExists(w_ReadNoise))
			w -= w_ReadNoise
			Print "Subtracting ReadNoise Array"
		else
			NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
			
			switch(gHighResBinning)
				case 1:
					w -= kReadNoiseLevel_bin1		// a constant value
					
	//				MatrixFilter /N=11 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)			
	//				Print "*** median noise filter 11x11 applied to the back detector (1 pass) ***"
					Print "*** 1x1 binning - subtracted ReadNoise Constant - No Filter ***"
					break
				case 4:
					w -= kReadNoiseLevel_bin4		// a constant value
					
	//				MatrixFilter /N=3 /P=3 median w			//		/P=n flag sets the number of passes (default is 1 pass)				
	//				Print "*** median noise filter 3x3 applied to the back detector (3 passes) ***"
					Print "*** 4x4 binning - subtracted ReadNoise Constant - No Filter ***"
					break
				default:
					Abort "No binning case matches in V_Raw_to_Work"
			endswitch	
		endif		//waveExists
	endif		// using det B
	
	
	// (0) Redimension the data waves in the destination folder
	//     so that they are DP, not integer
	// (DONE)
	// x- currently only redimensioning the data and linear_data_error - anything else???
	// x- ?? some of this is done at load time for RAW data. Not a problem to re-do the redimension
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave w = V_getDetectorDataW(fname,detStr)
		Wave w_err = V_getDetectorDataErrW(fname,detStr)
		Redimension/D w,w_err
	endfor
	
	
	// (1) DIV correction
	// do this in terms of pixels. 
	// (DONE) : This must also exist at the time the first work folder is generated.
	//   So it must be in the user folder at the start of the experiment, and defined.
	NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	if (gDoDIVCor == 1)
		// need extra check here for file existence
		// if not in DIV folder, load.
		// if unable to load, skip correction and report error (Alert?) (Ask to Load?)
		Print "Doing DIV correction"// for "+ detStr
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			
			if(cmpstr(detStr,"B") == 0  && gIgnoreDetB == 1)
				// do nothing
			else
				Wave w = V_getDetectorDataW(fname,detStr)
				Wave w_err = V_getDetectorDataErrW(fname,detStr)
				
				V_DIVCorrection(w,w_err,detStr,newType)
			endif
		endfor
	else
		Print "DIV correction NOT DONE"		// not an error since correction was unchecked
	endif
	
	// (2) non-linear correction	
	// (DONE):
	// x-  the "B" detector is calculated in its own routines
	// x- document what is generated here:
	//    **in each detector folder: data_realDistX and data_realDistY (2D waves of the [mm] position of each pixel)
	// x- these spatial calculations ARE DONE as the RAW data is loaded. It allows the RAW
	//    data to be properly displayed, but without all of the (complete) set of detector corrections
	// * the corrected distances are calculated into arrays, but nothing is done with them yet
	// * there is enough information now to calculate the q-arrays, so it is done now
	// - other corrections may modify the data, this calculation does NOT modify the data
	NVAR gDoNonLinearCor = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
	// generate a distance matrix for each of the detectors
	if (gDoNonLinearCor == 1)
		Print "Doing Non-linear correction"// for "+ detStr
		for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
			detStr = StringFromList(ii, ksDetectorListNoB, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
//			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_calib = V_getDetTube_spatialCalib(fname,detStr)
			Variable tube_width = V_getDet_tubeWidth(fname,detStr)
			V_NonLinearCorrection(fname,w,w_calib,tube_width,detStr,destPath)

			//(2.4) Convert the beam center values from pixels to mm
			// beam center is always defined in [cm] now
			//
				// (DONE)
				// x- the beam center value in mm needs to be present - it is used in calculation of Qvalues
				// x- but having both the same is wrong...
				// x- the pixel value is needed for display of the panels
				if(kBCTR_CM)
					//V_ConvertBeamCtrPix_to_mm(folder,detStr,destPath)
					//
	
					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
					Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
					WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
					WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
					x_mm[0] = V_getDet_beam_center_x(fname,detStr) * 10 		// convert cm to mm
					y_mm[0] = V_getDet_beam_center_y(fname,detStr) * 10 		// convert cm to mm
					
					// (DONE):::
				// now I need to convert the beam center in mm to pixels
				// and have some rational place to look for it...
					V_ConvertBeamCtr_to_pix(fname,detStr,destPath)
				else
					// beam center is in pixels, so use the old routine
					V_ConvertBeamCtrPix_to_mm(fname,detStr,destPath)
				endif		
							
			// (2.5) Calculate the q-values
			// calculating q-values can't be done unless the non-linear corrections are calculated
			// so go ahead and put it in this loop.
			// (DONE) : 
			// x- make sure that everything is present before the calculation
			// x- beam center must be properly defined in terms of real distance
			// x- distances/zero location/ etc. must be clearly documented for each detector
			//	** this assumes that NonLinearCorrection() has been run to generate data_RealDistX and Y
			// ** this routine Makes the waves QTot, qx, qy, qz in each detector folder.
			//
			V_Detector_CalcQVals(fname,detStr,destPath)
			
		endfor

		if(gIgnoreDetB==0)		
			//"B" is separate
			detStr = "B"
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave cal_x = V_getDet_cal_x(fname,detStr)
			Wave cal_y = V_getDet_cal_y(fname,detStr)
			
			V_NonLinearCorrection_B(fname,w,cal_x,cal_y,detStr,destPath)
	
	// "B" is always naturally defined in terms of a pixel center. This can be converted to mm, 
	// but the experiment will measure pixel x,y - just like ordela detectors.
			
	//		if(kBCTR_CM)
	//
	//			Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	//			Make/O/D/N=1 $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
	//			WAVE x_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_x_mm")
	//			WAVE y_mm = $(destPath + ":entry:instrument:detector_"+detStr+":beam_center_y_mm")
	//			x_mm[0] = V_getDet_beam_center_x(fname,detStr) * 10 		// convert cm to mm
	//			y_mm[0] = V_getDet_beam_center_y(fname,detStr) * 10 		// convert cm to mm
	//			
	//			// now I need to convert the beam center in mm to pixels
	//			// and have some rational place to look for it...
	//			V_ConvertBeamCtr_to_pixB(fname,detStr,destPath)
	//		else
				// beam center is in pixels, so use the old routine
				V_ConvertBeamCtrPix_to_mmB(fname,detStr,destPath)
	
	//		endif
			V_Detector_CalcQVals(fname,detStr,destPath)
		
		endif
		
	else
		Print "Non-linear correction NOT DONE"
	endif


	// (3) dead time correction
	// DONE:
	// x- test for correct operation
	// x- loop over all of the detectors
	// x- B detector is a special case (do separately, then loop over NoB)
	// x- this DOES alter the data
	// x- verify the error propagation (not done yet)
	//
	Variable countRate
	NVAR gDoDeadTimeCor = root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor
	if (gDoDeadTimeCor == 1)
		Print "Doing DeadTime correction"// for "+ detStr
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			ctTime = V_getCount_time(fname)

			if(cmpstr(detStr,"B") == 0 )
				if(gIgnoreDetB == 0)
					Variable b_dt = V_getDetector_deadtime_B(fname,detStr)
					// do the correction for the back panel
					countRate = sum(w,-inf,inf)/ctTime		//use sum of detector counts
	
					w = w/(1-countRate*b_dt)
					w_err = w_err/(1-countRate*b_dt)
				endif			
			else
				// do the corrections for 8 tube panels
				Wave w_dt = V_getDetector_deadtime(fname,detStr)
				V_DeadTimeCorrectionTubes(w,w_err,w_dt,ctTime)
				
			endif
		endfor
		
	else
		Print "Dead Time correction NOT DONE"
	endif	
	

	// (4) solid angle correction
	//  -- this currently calculates the correction factor AND applys it to the data
	//  -- as a result, the data values are very large since they are divided by a very small
	//     solid angle per pixel. But all of the count values are now on the basis of 
	//    counts/(solid angle) --- meaning that they can all be binned together for I(q)
	//    -and- - this is taken into account for absolute scaling (this part is already done)
	//
	// the solid angle correction is calculated for ALL detector panels.
	NVAR gDoSolidAngleCor = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
	NVAR/Z gDo_OLD_SolidAngleCor = root:Packages:NIST:VSANS:Globals:gDo_OLD_SolidAngleCor
	// for older experiments, this won't exist, so generate it and default to zero
	// so the old calculation is not done
	if(NVAR_Exists(gDo_OLD_SolidAngleCor)==0)
		Variable/G root:Packages:NIST:VSANS:Globals:gDo_OLD_SolidAngleCor=0
	endif
	if (gDoSolidAngleCor == 1)
		Print "Doing Solid Angle correction"// for "+ detStr
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			
			if(cmpstr(detStr,"B") == 0  && gIgnoreDetB == 1)
				// do nothing if the back is ignored
			else
				Wave w = V_getDetectorDataW(fname,detStr)
				Wave w_err = V_getDetectorDataErrW(fname,detStr)
				// any other dimensions to pass in?
				
				if(gDo_OLD_SolidAngleCor == 0)
					V_SolidAngleCorrection(w,w_err,fname,detStr,destPath)
				else
					// for testing ONLY -- the cos^3 correction is incorrect for tubes, and the normal
					// function call above	 correctly handles either high-res grid or tubes. This COS3 function
					// will incorrectly treat tubes as a grid	
					//				Print "TESTING -- using incorrect COS^3 solid angle !"		
					V_SolidAngleCorrection_COS3(w,w_err,fname,detStr,destPath)
				endif
				
			endif
			
		endfor
		if(gDo_OLD_SolidAngleCor == 1)
			DoAlert 0,"TESTING -- using incorrect COS^3 solid angle !"		
		endif

	else
		Print "Solid Angle correction NOT DONE"
	endif	
	
		
	// (5) angle-dependent tube shadowing + detection efficiency
	//  done together as one correction
	//
	// (DONE):
	// x- this correction accounts for the efficiency of the tubes
	//		(depends on angle and wavelength)
	//    and the shadowing, only happens at large angles (> 23.7 deg, lateral to tubes)
	//
	// V_TubeEfficiencyShadowCorr(w,w_err,fname,detStr,destPath)
	//
	NVAR gDoTubeShadowCor = root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor
	if (gDoTubeShadowCor == 1)
		Print "Doing Tube Efficiency+Shadow correction"
		
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			
			if(cmpstr(detStr,"B") == 0)
				// always ignore "B"
			else
				Wave w = V_getDetectorDataW(fname,detStr)
				Wave w_err = V_getDetectorDataErrW(fname,detStr)
				
				V_TubeEfficiencyShadowCorr(w,w_err,fname,detStr,destPath)
			endif

//			Print "Eff for panel ",detStr
		endfor

	else
		Print "Tube efficiency+shadowing correction NOT DONE"
	endif	

	// (6) Downstream window angle dependent transmission correction
	// TODO:
	// -- HARD WIRED value
	// x- find a temporary way to pass this value into the function (global?)
	//
	// -- currently the transmission is set as a global (in V_VSANS_Preferences.ipf)
	// -- need a permanent location in the file header to store the transmission value
	//
	NVAR/Z gDoWinTrans = root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor
	if(NVAR_Exists(gDoWinTrans) != 1)
		V_InitializeWindowTrans()		//set up the globals (need to check in multiple places)
	endif
		
	if (gDoWinTrans == 1)
		Print "Doing Large-angle Downstream window transmission correction"// for "+ detStr
	
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			
			if(cmpstr(detStr,"B") == 0  && gIgnoreDetB == 1)
				// do nothing
			else
				Wave w = V_getDetectorDataW(fname,detStr)
				Wave w_err = V_getDetectorDataErrW(fname,detStr)
				
				V_DownstreamWindowTransmission(w,w_err,fname,detStr,destPath)
			endif
		endfor
	else
		Print "Downstream Window Transmission correction NOT DONE"
	endif	
		
	// (7) angle dependent transmission correction
	// (DONE):
	// x- this still needs to be filled in
	// x- still some debate of when/where in the corrections that this is best applied
	//    - do it here, and it's done whether the output is 1D or 2D
	//    - do it later (where SAMPLE information is used) since this section is ONLY instrument-specific
	// x- verify that the calculation is correct
	// x- verify that the error propagation (in 2D) is correct
	//
	NVAR gDoTrans = root:Packages:NIST:VSANS:Globals:gDoTransmissionCor
	if (gDoTrans == 1)
		Print "Doing Large-angle sample transmission correction"// for "+ detStr
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			
			if(cmpstr(detStr,"B") == 0  && gIgnoreDetB == 1)
				// do nothing
			else
				Wave w = V_getDetectorDataW(fname,detStr)
				Wave w_err = V_getDetectorDataErrW(fname,detStr)
				
				V_LargeAngleTransmissionCorr(w,w_err,fname,detStr,destPath)
			endif
		endfor
	else
		Print "Sample Transmission correction NOT DONE"
	endif	
	
	
	// (8) normalize to default monitor counts
	// (DONE) x- each detector is rescaled separately, but the rescaling factor is global (only one monitor!)
	// TODO -- but there are TWO monitors - so how to switch?
	//  --- AND, there is also /entry/control/monitor_counts !!! Which one is the correct value? Which will NICE write
	// TODO -- what do I really need to save?
	
	NVAR gDoMonitorNormalization = root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization
	if (gDoMonitorNormalization == 1)
		
		Variable monCount,savedMonCount
		defmon=1e8			//default monitor counts
//		monCount = V_getControlMonitorCount(fname)			// TODO -- this is read in since VCALC fakes this on output
		monCount = V_getBeamMonNormData(fname)		// TODO -- I think this is the *real* one to read
		savedMonCount	= monCount
		scale = defMon/monCount		// scale factor to MULTIPLY data by to rescale to defmon

		// write to newType=fname will put new values in the destination WORK folder
		V_writeBeamMonNormSaved_count(fname,savedMonCount)			// save the true count
		V_writeBeamMonNormData(fname,defMon)		// mon ct is now 10^8
					
//			// TODO
//			// the low efficiency monitor, expect to use this for white beam mode
//				-- need code switch here to determine which monitor to use.
//
//			V_getBeamMonLowData(fname)
//			V_getBeamMonLowSaved_count(fname)	
			
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)

			// do the calculation right here. It's a simple scaling and not worth sending to another function.	
			//scale the data and error to the default monitor counts
		
//
			w *= scale
			w_err *= scale		//assumes total monitor count is so large there is essentially no error

			// TODO
			// -- do I want to update and save the integrated detector count?
			// I can't trust the integrated count for the back detector (ever) - since the 
			// data is shifted for registry and some (~ 10% of the detector) is lost
			// also, ML panel has the wrong value (Oct-nov 2019) and I don't know why. so sum the data
			//
			Variable integratedCount = sum(w)
			V_writeDet_IntegratedCount(fname,detStr,integratedCount)		//already the scaled value for counts
//			Variable integratedCount = V_getDet_IntegratedCount(fname,detStr)
//			V_writeDet_IntegratedCount(fname,detStr,integratedCount*scale)

		endfor
	else
		Print "Monitor Normalization correction NOT DONE"
	endif


// flag to allow adding raw data files with different attenuation (normally not done)	
// -- yet to be implemented as a prefrence panel item
//	NVAR gAdjustRawAtten = root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten	
	
	
//	// (not done) angle dependent efficiency correction
//	// -- efficiency and shadowing are now done together (step 5)
//	NVAR doEfficiency = root:Packages:NIST:VSANS:Globals:gDoDetectorEffCor

//	
	//reset the current displaytype to "newtype"
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End

//
//will "ADD" the current contents of the RAW folder to the newType work folder
//
// - used when adding multiple runs together
//(the function V_Raw_to_work(type) makes a fresh workfile)
//
//the current display type is updated to newType (global)
Function V_Add_raw_to_work(newType)
	String newType
	
	String destPath=""
	// if the desired workfile doesn't exist, let the user know, and just make a new one
	if(WaveExists($("root:Packages:NIST:VSANS:"+newType + ":entry:instrument:detector_FL:data")) == 0)
		Print "There is no old work file to add to - a new one will be created"
		//call V_Raw_to_work(), then return from this function
		V_Raw_to_Work(newType)
		Return(0)		//does not generate an error - a single file was converted to work.newtype
	Endif


	// convert the RAW data to a WORK file.
	// this will do all of the necessary corrections to the data
	// put this in some separate work folder that can be cleaned out at the end (ADJ)
	String tmpType="ADJ"
	
	//this step removes the read noise from the back so that neither added file will have this constant
	V_Raw_to_Work(tmpType)		
			
	//now make references to data in newType folder
	DestPath="root:Packages:NIST:VSANS:"+newType	


/////////////////
//fields that need to be added together
// entry block
	// collection_time  		V_getCollectionTime(fname)		V_putCollectionTime(fname,val)

// instrument block
	// beam_monitor_norm
		// data (this will be 1e8)				V_getBeamMonNormData(fname)		V_putBeamMonNormData(fname,val)
		// saved_count (this is the original monitor count)  V_getBeamMonNormSaved_count(fname)		V_putBeamMonNormSaved_count(fname,val)

	// for each detector
	// data		V_getDetectorDataW(fname,detStr)
	// integrated_count		V_getDet_IntegratedCount(fname,detStr)   V_putDet_IntegratedCount(fname,detStr,val)
	// linear_data		 V_getDetectorLinearDataW(fname,detStr)
	// RECALCULATE (or add properly) linear_data_error		V_getDetectorDataErrW(fname,detStr)


// control block (these may not actually be used?)
	// count_time				V_getCount_time(fname)						V_putCount_time(fname,val)
	// detector_counts		V_getDetector_counts(fname)				V_putDetector_counts(fname,val)
	// monitor_counts		V_getControlMonitorCount(fname)		V_putControlMonitorCount(fname,val)

// sample block - nothing
// reduction block - nothing
// user block - nothing

// ?? need to add the file name to a list of what was actually added - so it will be saved with I(q)
//
////////////////////

//	total_mon = realsread[1]	//saved monitor count
//	uscale = total_mon/defmon		//unscaling factor
//	total_det = uscale*realsread[2]		//unscaled detector count
//	total_trn = uscale*realsread[39]	//unscaled trans det count
//	total_numruns = integersread[3]	//number of runs in workfile
//	total_rtime = integersread[2]		//total counting time in workfile
	

	String detStr
	
	Variable saved_mon_dest,scale_dest,saved_mon_tmp,scale_tmp
	Variable collection_time_dest,collection_time_tmp,count_time_dest,count_time_tmp
	Variable detCount_dest,detCount_tmp,det_integrated_ct_dest,det_integrated_ct_tmp
	Variable ii,new_scale,defMon
	
	defMon=1e8			//default monitor counts

	// find the scaling factors, one for each folder
	saved_mon_dest = V_getBeamMonNormSaved_count(newType)
	scale_dest = saved_mon_dest/defMon		//un-scaling factor
	
	saved_mon_tmp = V_getBeamMonNormSaved_count(tmpType)
	scale_tmp = saved_mon_tmp/defMon			//un-scaling factor

	new_scale = defMon / (saved_mon_dest+saved_mon_tmp)
	
	
	// get the count time for each (two locations)
	collection_time_dest = V_getCollectionTime(newType)
	collection_time_tmp = V_getCollectionTime(tmpType)
	
	count_time_dest = V_getCount_time(newType)
	count_time_tmp = V_getCount_time(tmpType)
	
	detCount_dest = V_getDetector_counts(newType)
	detCount_tmp = V_getDetector_counts(tmpType)

// update the fields that are not in the detector blocks
// in entry
	V_putCollectionTime(newType,collection_time_dest+collection_time_tmp)

// in control block
	V_putCount_time(newType,count_time_dest+count_time_tmp)
	V_putDetector_counts(newType,detCount_dest+detCount_tmp)
	V_putControlMonitorCount(newType,saved_mon_dest+saved_mon_tmp)

// (DONE)
// the new, unscaled monitor count was written to the control block, but it needs to be 
// written to the BeamMonNormSaved_count field instead, since this is where I read it from.
// - so this worked in the past for adding two files, but fails on 3+
// x- write to the NormSaved_count field...
	V_writeBeamMonNormSaved_count(newType,saved_mon_dest+saved_mon_tmp)			// save the true count


// now loop over all of the detector panels
	// data
	// data_err
	// integrated count
	// linear_data
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		
		Wave data_dest = V_getDetectorDataW(newType,detStr)
		Wave data_err_dest = V_getDetectorDataErrW(newType,detStr)
		Wave linear_data_dest = V_getDetectorLinearDataW(newType,detStr)
		det_integrated_ct_dest = V_getDet_IntegratedCount(newType,detStr)

		Wave data_tmp = V_getDetectorDataW(tmpType,detStr)
		Wave data_err_tmp = V_getDetectorDataErrW(tmpType,detStr)
		Wave linear_data_tmp = V_getDetectorLinearDataW(tmpType,detStr)
		det_integrated_ct_tmp = V_getDet_IntegratedCount(tmpType,detStr)
		
		// unscale the data arrays
		data_dest *= scale_dest
		data_err_dest *= scale_dest
		linear_data_dest *= scale_dest
		
		data_tmp *= scale_tmp
		data_err_tmp *= scale_tmp
		linear_data_tmp *= scale_tmp

// TODO SRK-ERROR?
// the integrated count may not be correct (ML error Oct/Nov 2019)
// and is not correct for the back detector since some pixels were lost due to shifting the image registration
//				
		// add them together, the dest is a wave so it is automatically changed in the "dest" folder
		V_putDet_IntegratedCount(tmpType,detStr,sum(data_dest)+sum(data_tmp))		// adds the unscaled data sums
//		V_putDet_IntegratedCount(tmpType,detStr,det_integrated_ct_dest+det_integrated_ct_tmp)		// wrong for "B", may be wrong for ML
		data_dest += data_tmp
		data_err_dest = sqrt(data_err_dest^2 + data_err_tmp^2)		// add in quadrature
		linear_data_dest += linear_data_tmp
		
		// now rescale the data_dest to the monitor counts
		data_dest *= new_scale
		data_err_dest *= new_scale
		linear_data_dest *= new_scale
		
	endfor

	
	//Add the added raw filename to the list of files in the workfile
	SVAR fileList_dest = $("root:Packages:NIST:VSANS:"+newType+":gFileList")
	SVAR fileList_tmp = $("root:Packages:NIST:VSANS:"+tmpType+":gFileList")
	
	fileList_dest += ";" + fileList_tmp
	
	//reset the current display type to "newtype"
	SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
	gCurDispType = newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End


//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function V_Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	V_Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_copy=$("root:Packages:NIST:"+type+":data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be 1
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	// to keep "data" and linear_data in sync
	data_copy = data
	
	return(0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function V_Add_Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	V_Add_Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_copy=$("root:Packages:NIST:"+type+":data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be equal to the number of runs (1 count per run)
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	// to keep "data" and linear_data in sync
	data_copy = data
	
	return(0)
End

