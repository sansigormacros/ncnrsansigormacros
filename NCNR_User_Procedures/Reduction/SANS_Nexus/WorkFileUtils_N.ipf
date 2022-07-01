#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


/// cut this file into two files:
// -- one, where the functions are detector-insensitve
// -- a second, where the functions depend on the type of detector (Ordela or Tubes)
//
// -- then the new, detector specific file can be included as appropriate
//
// -- then I can change the "Raw_to_work_Ordela" back to "raw_to_work" and have the correct
// versions of the functions controlled by the includes
//
//

//
//  JULY 2021 -- when using Nexus data, work directly with "data", not linear_data. The data display
//               does not require taking the log of the data array, so there is no 
//              need to have a second linear_data array dragged around. ignore it.





//*******************
// Vers 1.2 100901
//
//*******************
// Utility procedures for handling of workfiles (each is housed in a separate datafolder)
//
// - adding data to a workfile
// - copying workfiles to another folder
//
// - absolute scaling
// - DIV detector sensitivity corrections
//
// - the WorkFile Math panel for simple image math
// - 
// - adding work.drk data without normalizing to monitor counts
//
//***************************


//************************
//unused testing procedure, may not be up-to-date with other procedures
//check before re-implementing
//
Proc DIV_a_Workfile(type)
	String type
	Prompt type,"WORK data type",popup,"COR;SAM;EMP;BGD"
	
	//macro will take whatever is in SELECTED folder and DIVide it by the current
	//contents of the DIV folder - the function will check for existence 
	//before proceeding
	
	Variable err
	err = Divide_work(type)		//returns err = 1 if data doesn't exist in specified folders
	
//	// or do I use this call (based on VSANS, in DetectorCorrections_N.ipf)
//	DIVCorrection(data,data_err,workType)
//	
	
	if(err)
		Abort "error in Divide_work"
	endif
	
	//contents are always dumped to CAL
	type = "CAL"
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=Type
	
	fRawWindowHook()
	
End

//function will divide the contents of "type" folder with the contents of 
//the DIV folder
// all data is converted to linear scale for the calculation
//
// result is in CAL folder
//
Function Divide_work(type)
	String type
	
	//check for existence of data in type and DIV
	// if the desired workfile doesn't exist, let the user know, and abort
	String destPath=""


	Wave/Z div_data = getDetectorDataW("DIV")		//hard-wired in....

	if(WaveExists(data) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	Endif
	//check for DIV
	// if the DIV workfile doesn't exist, let the user know,and abort

	if(WaveExists(div_data) == 0)
		Print "There is no work file in DIV --Aborting"
		Return(1)		//error condition
	Endif
	//files exist, proceed
	
	//copy from current dir (type)=destPath to CAL, overwriting CAL contents
	CopyHDFToWorkFolder(type,"CAL")
	
	
	destPath = "root:Packages:NIST:" + type

	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(destPath + ":fileList")

	//now switch to reference waves in CAL folder
	destPath = "root:Packages:NIST:CAL"	

	Variable/G $(destPath + ":gIsLogScale")=0			//make new flag in CAL folder, data is linear scale
	//need to copy filelist string too
	String/G $(destPath + ":fileList") = oldFileList


	Wave/Z data = getDetectorDataW("CAL")
	//do the division, changing data in CAL
	data /= div_data

	// statistics of the DIV data are very good (much better than the data)
	Wave data_err = getDetectorDataErrW("CAL")
	// so for simplicity, assume no error in the DIV, so this simplifies to:
	data_err /= div_data
	
	
	Return(0)
End


//s_ is the standard
//w_ is the "work" file
//both are work files and should already be normalized to 10^8 monitor counts
Function Absolute_Scale(type,w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err)
	String type
	Variable w_trans,w_thick,s_trans,s_thick,s_izero,s_cross,kappa_err
	
	//convert the "type" data to absolute scale using the given standard information
	//copying the "type" waves to ABS
	
	//check for existence of data, rescale to linear if needed
	String destPath
	//check for "type"
	Wave/Z data_check=getDetectorDataW(type)
	
	if(WaveExists(data_check) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	Endif
	
	//copy "oldtype" information to ABS
	//overwriting out the old contents of the ABS folder (or killing first)
	CopyHDFToWorkFolder(type,"ABS")

	String oldType= "root:Packages:NIST:"+type  		//this is where the data to be absoluted is 
	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(oldType + ":fileList")
	//need to copy filelist string too
	String/G $"root:Packages:NIST:ABS:fileList" = oldFileList
	
	//now switch to ABS folder
	//make appropriate wave references
	Wave data=getDetectorDataW("ABS")
	Wave data_err=getDetectorDataErrW("RAW")
	
	Variable/G $"root:Packages:NIST:ABS:gIsLogscale"=0			//make new flag in ABS folder, data is linear scale
	
	//do the actual absolute scaling here, modifying the data in ABS
	Variable defmon = 1e8,w_moncount,s1,s2,s3,s4
	
	w_moncount = getControlMonitorCount("ABS")		//monitor count in "ABS"
	if(w_moncount == 0)
		//zero monitor counts will give divide by zero ---
		DoAlert 0,"Total monitor count in data file is zero. No rescaling of data"
		Return(1)		//report error
	Endif
	
	//calculate scale factor
	Variable scale,trans_err
	s1 = defmon/getControlMonitorCount("ABS")		//[0] is monitor count (s1 should be 1)
	s2 = s_thick/w_thick
	s3 = s_trans/w_trans
	s4 = s_cross/s_izero
	
	// kappa comes in as s_izero, so be sure to use 1/kappa_err
	
	data *= s1*s2*s3*s4
	
	scale = s1*s2*s3*s4
	trans_err = getSampleTransError("ABS")
	
//	print scale
//	print data[0][0]
	
	data_err = sqrt(scale^2*data_err^2 + scale^2*data^2*(kappa_err^2/s_izero^2 +trans_err^2/w_trans^2))

//	print data_err[0][0]
	
	
	//********* 15APR02
	// DO NOt correct for atenuators here - the COR step already does this, putting all of the data one equal
	// footing (zero atten) before doing the subtraction.
	//
	//Print "ABS data multiplied by  ",s1*s2*s3*s4/attenFactor
	
	//update the ABS header information
//	textread[1] = date() + " " + time()		//date + time stamp
//	textread[1] = date() + " " + time()		//date + time stamp
	// putDataStartTime(fname) doesn't exist
	
	Return (0) //no error
End



//function will copy the contents of oldtype folder to newtype folder
//converted to linear scale before copying
//******data in newtype is overwritten********
//
// a duplicated copy routine that is used in some locations, this points to the
// single routine that does the copy
//
Function CopyWorkContents(oldtype,newtype)
	String oldtype,newtype
	
	
	CopyHDFToWorkFolder(oldtype,newtype)
	
	return(0)

End

//Entry procedure from main panel
//
Proc CopyWorkFolder(oldType,newType)
	String oldType,newType
	Prompt oldType,"Source WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
	Prompt newType,"Destination WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"


	// data folder "old" will be copied to "new" (either kills/copies or will overwrite)
	CopyHDFToWorkFolder(oldtype,newtype)
End



//
// tests if two values are close enough to each other
// very useful since ICE came to be
//
// tol is an absolute value (since input v1 or v2 may be zero, can't reliably
// use a percentage
Function CloseEnough(v1,v2,tol)
	Variable v1, v2, tol

	if(abs(v1-v2) < tol)
		return(1)
	else
		return(0)
	endif
End

//
//
// match the attenuation of the RAW data to the "type" data
// so that they can be properly added
//
// are the attenuator numbers the same? if so exit
//
// if not, find the attenuator number for type
// - find both attenuation factors
//
// rescale the raw data to match the ratio of the two attenuation factors
// -- adjust the detector count (rw)
// -- the linear data
// -- the data error
//
Function Adjust_RAW_Attenuation(type)
	String type
	
	WAVE data=getDetectorDataW("RAW")
	WAVE data_err=getDetectorDataErrW("RAW")	

	Variable dest_atten,raw_atten,tol,val
	Variable lambda,raw_atten_err,raw_AttenFactor,dest_attenFactor,dest_atten_err
	String fileStr

	dest_atten = getAtten_number(type)
	raw_atten = getAtten_number("RAW")
	
	tol = 0.1		// within 0.1 atten units is OK
	if(abs(dest_atten - raw_atten) < tol )
		return(0)
	endif

//	lambda = getWavelength("RAW")
	raw_AttenFactor = getAttenuator_transmission("RAW")
	dest_AttenFactor = getAttenuator_transmission(type)
		
	val = getDetector_counts("RAW")
	val *= dest_AttenFactor/raw_AttenFactor
	putDetector_counts("RAW", val)
	
	data *= dest_AttenFactor/raw_AttenFactor
	data_err *= dest_AttenFactor/raw_AttenFactor
	

	
	return(0)
End



Proc KillWorkFolder(type)
	String type
	Prompt type,"Kill WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;SAS;ADJ;"
	
	KillDataFolder/Z $("root:Packages:NIST:"+type)
	
	if(V_flag == 0)
		DoAlert 0, "Success - the work folder was killed"
	else
		DoAlert 0, "The work folder was not killed, something is in use"
	endif
	
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
Function KillWavesFullTree(dfr, fromStr, level, sNBName,recurse)
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
		
		WriteBrowserInfo_test(sString, 1, sNBName)
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
		
		WriteBrowserInfo_test(sString, 2, sNBName)
	endfor	
 
 // now kill the data folder if possible
 	KillDataFolder/Z $dfName
 	
 	
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		WriteBrowserInfo_test(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		WriteBrowserInfo_test(sString, 4, sNBName)
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
			
			
			WriteBrowserInfo_test(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			KillWavesFullTree(childDFR, fromStr, level+1, sNBName, recurse)
		endfor	
	endif
	 

End


Function WriteBrowserInfo_test(sString, vType, sNBName)
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







//
// given the folder, duplicate the data -> linear_data and generate the error
//
// x- do I want to use different names here? If it turns out that I don't need to drag a copy of
//    the data around as "linear_data", then I can eliminate that, and rename the error wave
// x- be sure the data is either properly written as 2D in the file, or converted to 2D before
//    duplicating here
// x- ? do I recast to DP here? No- V_MakeDataWaves_DP() is called directly prior to this call, so data
//     coming in is already DP
Function MakeDataError(folderStr)
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


//
// copy what is needed for data processing (not the DAS_logs)
// from one SANS storage folder to the local WORK folder as needed
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
Function CopyHDFToWorkFolder(fromStr,toStr)
	String fromStr,toStr
	
	String fromDF, toDF
	
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:"+fromStr
	toDF = "root:Packages:NIST:"+toStr
	
//	// make a copy of the file name for my own use, since it's not in the file
//	String/G $(toDF+":file_name") = root:
	
	// check to see if the data folder exists, if so, try to kill
	// if it deosn't exist then do nothing (as for duplication for polarized beam)
	if(DataFolderExists(toDF))
		KillDataFolder/Z $toDF			//DuplicateDataFolder will not overwrite, so Kill

//		KillWavesFullTree($toDF,toStr,0,"",1)			// this will traverse the whole tree, trying to kill what it can

	endif
	
	if(V_flag == 0)		// kill DF was OK
		DuplicateDataFolder $("root:Packages:NIST:"+fromStr),$("root:Packages:NIST:"+toStr)
		
		// I can delete these if they came along with RAW
		//   DAS_logs
		//   top-level copies of data (duplicate links, these should not be present in a proper Nexus file)
		// and I have no need of them during reduction
		KillDataFolder/Z $(toDF+":entry:DAS_logs")
//		KillDataFolder/Z $(toDF+":entry:data")

		return(0)
	else
	
		KillWavesFullTree($toDF,toStr,0,"",1)			// this will traverse the whole tree, trying to kill what it can

		if(DataFolderExists("root:Packages:NIST:"+toStr) == 0)		//if the data folder (RAW, SAM, etc.) was just killed?
			NewDataFolder/O $("root:Packages:NIST:"+toStr)
		endif	
			
		// need to do this the hard way, duplicate/O recursively
		// see V_CopyToWorkFolder()

		// FileList is above "entry" which is my additions
		SVAR fileList_dest = $("root:Packages:NIST:"+toStr+":FileList")
		SVAR fileList_tmp = $("root:Packages:NIST:"+fromStr+":FileList")
		fileList_dest = fileList_tmp
	
		// everything on the top level
		DuplicateHDFDataFolder($(fromDF+":entry"),fromStr,toStr,0,"",0)	//no recursion here
		// control
		DuplicateHDFDataFolder($(fromDF+":entry:control"),fromStr,toStr,0,"",1)	//yes recursion here
		// instrument
		DuplicateHDFDataFolder($(fromDF+":entry:instrument"),fromStr,toStr,0,"",1)	//yes recursion here
		// reduction
		DuplicateHDFDataFolder($(fromDF+":entry:reduction"),fromStr,toStr,0,"",1)	//yes recursion here
		// sample
		DuplicateHDFDataFolder($(fromDF+":entry:sample"),fromStr,toStr,0,"",1)	//yes recursion here
		// user
		DuplicateHDFDataFolder($(fromDF+":entry:user"),fromStr,toStr,0,"",1)	//yes recursion here
		
	endif	
	
	return(0)
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
Function DuplicateHDFDataFolder(dfr, fromStr, toStr, level, sNBName,recurse)
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
		
		WriteBrowserInfo_test(sString, 1, sNBName)
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
		
		WriteBrowserInfo_test(sString, 2, sNBName)
	endfor	
 
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		WriteBrowserInfo_test(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		WriteBrowserInfo_test(sString, 4, sNBName)
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
			
			
			WriteBrowserInfo_test(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			DuplicateHDFDataFolder(childDFR, fromStr, toStr, level+1, sNBName, recurse)
		endfor	
	endif
	 

End










//*************
// start of section of functions used for workfile math panel
//*************


//initializes datafolder and constants necessary for the workfilemath panel
//
Proc Init_WorkMath()
	//create the data folder
	//String str = "AAA;BBB;CCC;DDD;EEE;FFF;GGG;"
	String str = "File_1;File_2;Result;"
	NewDataFolder/O/S root:Packages:NIST:WorkMath
	String/G gFolderList=str
	Variable ii=0,num=itemsinlist(str)
	do
		Execute "NewDataFolder/O "+StringFromList(ii, str ,";")
		ii+=1
	while(ii<num)
	Variable/G const1=1,const2=1
	
	SetDataFolder root:
End

//entry procedure to invoke the workfilemath panel, initializes if needed
//
Proc Show_WorkMath_Panel()
	DoWindow/F WorkFileMath
	if(V_flag==0)
		Init_WorkMath()
		WorkFileMath()
	Endif
End

//attempts to perform the selected math operation based on the selections in the panel
// aborts with an error condition if operation can't be completed
// or puts the final answer in the Result folder, and displays the selected data
//
Function WorkMath_DoIt_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String str1,str2,oper,dest = "Result"
	String pathStr,workMathStr="WorkMath:"
	
	//get the panel selections (these are the names of the files on disk)
	PathInfo catPathName
	pathStr=S_Path
	ControlInfo popup0
	str1=S_Value
	ControlInfo popup1
	str2=S_Value
	ControlInfo popup2
	oper=S_Value
	
	//check that something has been selected for operation and destination
	if(cmpstr(oper,"Operation")==0)
		Abort "Select a math operand from the popup"
	Endif

	//constants from globals
	NVAR const1=root:Packages:NIST:WorkMath:const1
	NVAR const2=root:Packages:NIST:WorkMath:const2
	Printf "(%g)%s %s (%g)%s = %s\r", const1,str1,oper,const2,str2,dest
	//check for proper folders (all 3 must be different)
	
	//load the data in here...
	//set #1
	Load_NamedASC_File(pathStr+str1,workMathStr+"File_1")
	
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR type = root:myGlobals:gDataDisplayType
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
		
	WAVE/Z data1=$("root:Packages:NIST:"+workMathStr+"File_1:linear_data")
	WAVE/Z err1=$("root:Packages:NIST:"+workMathStr+"File_1:linear_data_error")
	
	// set # 2
	If(cmpstr(str2,"UNIT MATRIX")==0)
		Make/O/N=(pixelsX,pixelsY) root:Packages:NIST:WorkMath:data		//don't put in File_2 folder
		Wave/Z data2 =  root:Packages:NIST:WorkMath:data			//it's not real data!
		data2=1
		Duplicate/O data2 err2
		err2 = 0
	else
		//Load set #2
		Load_NamedASC_File(pathStr+str2,workMathStr+"File_2")
		WAVE/Z data2=$("root:Packages:NIST:"+workMathStr+"File_2:linear_data")
		WAVE/Z err2=$("root:Packages:NIST:"+workMathStr+"File_2:linear_data_error")
	Endif

	///////
	
	//now that we know that data exists, convert each of the operands to linear scale
//	ConvertFolderToLinearScale(workMathStr+"File_1")
//	If(cmpstr(str2,"UNIT MATRIX")!=0)
//		ConvertFolderToLinearScale(workMathStr+"File_2")		//don't need to convert unit matrix to linear
//	endif

	//copy contents of str1 folder to dest and create the wave ref (it will exist)
	CopyWorkContents(workMathStr+"File_1",workMathStr+dest)
	WAVE/Z destData=$("root:Packages:NIST:"+workMathStr+dest+":linear_data")
	WAVE/Z destData_log=$("root:Packages:NIST:"+workMathStr+dest+":data")
	WAVE/Z destErr=$("root:Packages:NIST:"+workMathStr+dest+":linear_data_error")
	
	//dispatch
	strswitch(oper)	
		case "*":		//multiplication
			destData = const1*data1 * const2*data2
			destErr = const1^2*const2^2*(err1^2*data2^2 + err2^2*data1^2)
			destErr = sqrt(destErr)
			break	
		case "_":		//subtraction
			destData = const1*data1 - const2*data2
			destErr = const1^2*err1^2 + const2^2*err2^2
			destErr = sqrt(destErr)
			break
		case "/":		//division
			destData = (const1*data1) / (const2*data2)
			destErr = const1^2/const2^2*(err1^2/data2^2 + err2^2*data1^2/data2^4)
			destErr = sqrt(destErr)
			break
		case "+":		//addition
			destData = const1*data1 + const2*data2
			destErr = const1^2*err1^2 + const2^2*err2^2
			destErr = sqrt(destErr)
			break			
	endswitch
	
	destData_log = log(destData)		//for display
	//show the result
	WorkMath_Display_PopMenuProc("",0,"Result")
	
	PopupMenu popup4 win=WorkFileMath,mode=3		//3rd item selected == Result
End

// closes the panel and kills the data folder when done
//
Function WorkMath_Done_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoAlert 1,"Closing the panel will kill all of the data you have loaded into memory. Do you want to continue?"
	If(V_Flag==2)
		return(0)		//don't do anything
	Endif
	//kill the panel
	DoWindow/K WorkFileMath
	//wipe out the data folder of globals
	SVAR dataType=root:myGlobals:gDataDisplayType
	if(strsearch(dataType, "WorkMath", 0 ) != -1)		//kill the SANS_Data graph if needed
		DoWindow/K SANS_Data
	Endif
	KillDataFolder root:Packages:NIST:WorkMath
End

// loads data into the specified folder
//
// currently unused since button has been removed from panel
//
Function WorkMath_Load_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String destStr=""
	SVAR folderList=root:Packages:NIST:WorkMath:gFolderList
	Prompt destStr,"Select the destination folder",popup,folderList
	DoPrompt "Folder for ASC Load",destStr
	
	if(V_flag==1)
		return(1)		//user abort, do nothing
	Endif
	
	String destFolder = "WorkMath:"+destStr
	
	Load_ASC_File("Pick the ASC file",destFolder)
End

// changes the display of the SANS_Data window based on popped data type
// first loads in the data from the File1 or File2 popup as needed
// then displays the selcted dataset, if it exists
// makes use of procedure from DisplayUtils
//
// - Always replaces File1 or File2 with fresh data from disk
//
Function WorkMath_Display_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String folder="WorkMath:",pathStr,str1

	PathInfo catPathName
	pathStr=S_Path
	
	//if display result, just do it and return
	if(cmpstr(popStr,"Result")==0)
		Execute "ChangeDisplay(\""+folder+popstr+"\")"
		return(0)
	endif
	// if file1 or file2, load in the data and display
	if(cmpstr(popStr,"File_1")==0)
		ControlInfo/W=WorkFileMath popup0
		str1 = S_Value
	Endif
	if(cmpstr(popStr,"File_2")==0)
		ControlInfo/W=WorkFileMath popup1
		str1 = S_Value
	Endif
	//don't load or display the unit matrix
	Print str1
	if(cmpstr(str1,"UNIT MATRIX")!=0)
		Load_NamedASC_File(pathStr+str1,folder+popStr)
		//change the display
		Execute "ChangeDisplay(\""+folder+popstr+"\")"
	endif
	return(0)	
End

//simple panel to do workfile arithmetic
//
Proc WorkFileMath()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(610,211,880,490)/K=2 as "Work File Math"		// replace /K=2 flag
	DoWindow/C WorkFileMath
	ModifyPanel cbRGB=(47802,54484,6682)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 6,166,214,166
	SetDrawEnv fstyle= 4
	DrawText 10,34,"File #1:"
	SetDrawEnv fstyle= 4
	DrawText 13,129,"File #2:"
	DrawText 78,186,"= Result"
	Button button0,pos={28,245},size={50,20},proc=WorkMath_DoIt_ButtonProc,title="Do It"
	Button button0,help={"Performs the specified arithmetic"}
	Button button1,pos={183,245},size={50,20},proc=WorkMath_Done_ButtonProc,title="Done"
	Button button1,help={"Closes the panel"}
//	Button button2,pos={30,8},size={110,20},proc=WorkMath_Load_ButtonProc,title="Load ASC Data"
//	Button button2,help={"Loads ASC data files into the specified folder"}
	Button button3,pos={205,8},size={25,20},proc=ShowWorkMathHelp,title="?"
	Button button3,help={"Show help file for math operations on 2-D data sets"}
	SetVariable setvar0,pos={9,46},size={70,15},title=" "
	SetVariable setvar0,limits={-Inf,Inf,0},value= root:Packages:NIST:WorkMath:const1
	SetVariable setvar0,help={"Multiplicative constant for the first dataset"}
	PopupMenu popup0,pos={89,44},size={84,20},title="X  "
	PopupMenu popup0,mode=1,popvalue="1st Set",value= ASC_FileList()
	PopupMenu popup0,help={"Selects the first dataset for the operation"}
	PopupMenu popup1,pos={93,136},size={89,20},title="X  "
	PopupMenu popup1,mode=1,popvalue="2nd Set",value= "UNIT MATRIX;"+ASC_FileList()
	PopupMenu popup1,help={"Selects the second dataset for the operation"}
	PopupMenu popup2,pos={50,82},size={70,20},title="Operator  "
	PopupMenu popup2,mode=3,popvalue="Operation",value= #"\"+;_;*;/;\""
	PopupMenu popup2,help={"Selects the mathematical operator"}
	SetVariable setvar1,pos={13,139},size={70,15},title=" "
	SetVariable setvar1,limits={-Inf,Inf,0},value= root:Packages:NIST:WorkMath:const2
	SetVariable setvar1,help={"Multiplicative constant for the second dataset"}
//	PopupMenu popup3,pos={27,167},size={124,20},title=" = Destination"
//	PopupMenu popup3,mode=1,popvalue="Destination",value= root:Packages:NIST:WorkMath:gFolderList
//	PopupMenu popup3,help={"Selects the destination folder"}
	PopupMenu popup4,pos={55,204},size={103,20},proc=WorkMath_Display_PopMenuProc,title="Display"
	PopupMenu popup4,mode=3,value= "File_1;File_2;Result;"
	PopupMenu popup4,help={"Displays the data in the specified folder"}
EndMacro

//jump to the help topic
Function ShowWorkMathHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[2-D Work File Arithmetic]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//utility function to clear the contents of a data folder
//won't clear data that is in use - 
//
Function ClearDataFolder(type)
	String type
	
	SetDataFolder $("root:Packages:NIST:"+type)
	KillWaves/a/z
	KillStrings/a/z
	KillVariables/a/z
	SetDataFolder root:
End



//fileStr must be the FULL path and filename on disk
//destFolder is the path to the Igor folder where the data is to be deposited
// - "Packages:NIST:WorkMath:File_1" for example, compatible with SANS_Data display type
//
Function Load_NamedASC_File(fileStr,destFolder)
	String fileStr,destFolder

	Variable refnum
	
	//read in the data
	ReadASCData(fileStr,destFolder)

	//the calling macro must change the display type
	String/G root:myGlobals:gDataDisplayType=destFolder
	
	FillFakeHeader_ASC(destFolder) 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	
	fRawWindowHook()
	
	return(0)
End


//function called by the main entry procedure (the load button)
//loads data into the specified folder, and wipes out what was there
//
//aborts if no file was selected
//
// reads the data in if all is OK
//
// currently unused, as load button has been replaced
//
Function Load_ASC_File(msgStr,destFolder)
	String msgStr,destFolder

	String filename="",pathStr=""
	Variable refnum

	//check for the path
	PathInfo catPathName
	If(V_Flag==1)		//	/D does not open the file
		Open/D/R/T="????"/M=(msgStr)/P=catPathName refNum
	else
		Open/D/R/T="????"/M=(msgStr) refNum
	endif
	filename = S_FileName		//get the filename, or null if canceled from dialog
	if(strlen(filename)==0)
		//user cancelled, abort
		SetDataFolder root:
		Abort "No file selected, action aborted"
	Endif
	
	//read in the data
	ReadASCData(filename,destFolder)

	//the calling macro must change the display type
	String/G root:myGlobals:gDataDisplayType=destFolder
	
	FillFakeHeader_ASC(destFolder) 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	
	fRawWindowHook()
	
	return(0)
End



//function called by the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// -- simplified to do in a single call -- extension must be .ASC
// - so far, only used in WorkFileMath popups, which require .ASC
//
Function/S ASC_FileList()

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		Return("")
	Endif

	list = IndexedFile(catpathName,-1,".ASC")


//	list = IndexedFile(catpathName,-1,"????")
//	
//	list = RemoveFromList(ListMatch(list,"*.SA1*",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.SA2*",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.SA3*",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,".*",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.pxp",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.DIV",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.GSP",";"), list, ";", 0)
//	list = RemoveFromList(ListMatch(list,"*.MASK",";"), list, ";", 0)
//
//	//remove VAX version numbers
//	list = RemoveVersNumsFromList(List)
	//sort
	newList = SortList(List,";",0)

	return newlist
End



//*************
// end of section of functions used for workfile math panel
//*************
