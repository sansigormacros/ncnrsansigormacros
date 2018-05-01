#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
// Operation does no scaling, only the basic (default) trim of the ends, concatenate, sort, and save
// -- if data has been converted to WORK and the solid angle correction was done, then the data
//   is per unit solid angle, and matches up - at least the simulated data does...
//   It should match up in real VSANS data since the flux conditions are identical for
//   all panels, only the geometry is different.
//
//
// V_DataPlotting.ipf is where the I(q) panel is drawn and the binning is set
//
// see the VCALC BinAllMiddlePanels() for an example of this
// see the binning routines in VC_DetectorBinning_Utils.ipf for the details
//

// TODO 
//
// -- verify the binning for slit mode. Looks correct, but verify
// -- DOCUMENT
//
// x- detector "B" is currently skipped since the calibration waves are not faked
//    when the raw data is loaded. Then the qxqyqz waves are not generated.
//
// x- REDO the logic here. It's a mess, and will get the calculation wrong 
//
// x- figure out the binning type (where is it set for VSANS?)
// x- don't know, so currently VSANS binning type is HARD-WIRED
// x- figure out when this needs to be called to (force) re-calculate I vs Q
//



//
// NOTE
// this is the master conversion function
// ***Use no others
// *** When other bin types are developed, DO NOT reassign these numbers.
//  instead, skip the old numbers and assign new ones.
//
// - the numbers here in the switch can be out of order - it's fine
//
// old modes can be removed from the string constant ksBinTypeStr(n) (in V_Initialize.ipf), but the 
// mode numbers are what many different binning, plotting, and reduction functions are
// switching on. In the future, it may be necessary to change the key (everywhere) to a string
// switch, but for now, stick with the numbers.
//
// Strconstant ksBinTypeStr = "F4-M4-B;F2-M2-B;F1-M1-B;F2-M1-B;F1-M2xTB-B;F2-M2xTB-B;SLIT-F2-M2-B;"
//
//
Function V_BinTypeStr2Num(binStr)
	String binStr
	
	Variable binType
	strswitch(binStr)	// string switch
		case "F4-M4-B":
			binType = 1
			break		// exit from switch
		case "F2-M2-B":
			binType = 2
			break		// exit from switch
		case "F1-M1-B":
			binType = 3
			break		// exit from switch
		case "SLIT-F2-M2-B":
			binType = 4
			break		// exit from switch

		case "F2-M1-B":
			binType = 5
			break
		case "F1-M2xTB-B":
			binType = 6
			break
		case "F2-M2xTB-B":
			binType = 7
			break
			
		default:			// optional default expression executed
			binType = 0
			Abort "Binning mode not found"// when no case matches
	endswitch	
	
	return(binType)
end

//
// TODO -- binType == 4 (slit mode) should never end up here
// -- new logic in calling routines to dispatch to proper routine
// -- AND need to write the routine for binning_SlitMode
//
Function V_QBinAllPanels_Circular(folderStr,binType,collimationStr)
	String folderStr
	Variable binType
	String collimationStr

	// do the back, middle, and front separately
	
//	figure out the binning type (where is it set?)
	Variable ii,delQ
	String detStr

//	binType = V_GetBinningPopMode()

	// set delta Q for binning (used later inside VC_fDoBinning_QxQy2D)
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		
		delQ = V_SetDeltaQ(folderStr,detStr)		// this sets (overwrites) the global value for each panel type
	endfor
	

	switch(binType)
		case 1:
			VC_fDoBinning_QxQy2D(folderStr,"FL",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FT",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"ML",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MT",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MB",collimationStr)			
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		

			break
		case 2:
			VC_fDoBinning_QxQy2D(folderStr,"FLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		

			break
		case 3:
			VC_fDoBinning_QxQy2D(folderStr,"MLRTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FLRTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		
			
			break
		case 4:				/// this is for a tall, narrow slit mode	
			VC_fBinDetector_byRows(folderStr,"FL")
			VC_fBinDetector_byRows(folderStr,"FR")
			VC_fBinDetector_byRows(folderStr,"ML")
			VC_fBinDetector_byRows(folderStr,"MR")
			VC_fBinDetector_byRows(folderStr,"B")

			break
		case 5:
			VC_fDoBinning_QxQy2D(folderStr,"FTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MLRTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		
		
			break
		case 6:
			VC_fDoBinning_QxQy2D(folderStr,"FLRTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		
		
			break
		case 7:
			VC_fDoBinning_QxQy2D(folderStr,"FTB",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"FLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr,"MLR",collimationStr)
			VC_fDoBinning_QxQy2D(folderStr, "B",collimationStr)		
		
			break
			
		default:
			Abort "Binning mode not found in V_QBinAllPanels_Circular"// when no case matches	
	endswitch
	

	return(0)
End


//
// TODO -- binType == 4 (slit mode) should be the only case to end up here
// -- new logic in calling routines to dispatch to proper routine
// -- AND need to write the routine for binning_SlitMode
//
Function V_QBinAllPanels_Slit(folderStr,binType)
	String folderStr
	Variable binType

	// do the back, middle, and front separately
	
//	figure out the binning type (where is it set?)
	Variable ii,delQ
	String detStr

//	binType = V_GetBinningPopMode()

	// set delta Q for binning (used later inside VC_fDoBinning_QxQy2D)
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		
		delQ = V_SetDeltaQ(folderStr,detStr)		// this sets (overwrites) the global value for each panel type
	endfor
	

	switch(binType)
		case 1:

			break
		case 2:

			break
		case 3:

			break
		case 4:				/// this is for a tall, narrow slit mode	
			VC_fBinDetector_byRows(folderStr,"FL")
			VC_fBinDetector_byRows(folderStr,"FR")
			VC_fBinDetector_byRows(folderStr,"ML")
			VC_fBinDetector_byRows(folderStr,"MR")
			VC_fBinDetector_byRows(folderStr,"B")

			break
		case 5:
		
			break
		case 6:
		
			break
		case 7:
	
			break
			
		default:
			Abort "Binning mode not found in V_QBinAllPanels_Slit"// when no case matches	
	endswitch
	

	return(0)
End



// concatenates and sorts the 1D data in "type" WORK folder
// uses the current display if type==""
//
Function V_ConcatenateForSave(pathStr,type,tagStr,binType)
	String pathStr,type,tagStr
	Variable binType
	
// get the current display type, if null string passed in
	SVAR curtype = root:Packages:NIST:VSANS:Globals:gCurDispType
	
	if(strlen(type)==0)
		type = curType
	endif

// trim the data if needed
	// remove the q=0 point from the back detector, if it's there
	// does not need to know binType
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(!gIgnoreDetB)
		V_RemoveQ0_B(type)
	endif

// concatenate the data sets
// TODO x- figure out which binning was used (this is done in V_1DConcatenate())
	// clear the old tmp waves first, if they still exist
//	SetDataFolder $("root:Packages:NIST:VSANS:"+type)
	SetDataFolder $(pathStr+type)
	Killwaves/Z tmp_q,tmp_i,tmp_s,tmp_sq,tmp_qb,tmp_fs
	setDataFolder root:
	V_1DConcatenate(pathStr,type,tagStr,binType)
	
// sort the data set
	V_TmpSort1D(pathStr,type)
	
	return(0)
End

//
// this is only called from the button on the data panel (**not anymore**)
// so the type is the currently displayed type, and the binning is from the panel
//
Function V_SimpleSave1DData(pathStr,type,tagStr,saveName)
	String pathStr,type,tagStr,saveName

// 
// get the current display type, if null string passed in
	SVAR curtype = root:Packages:NIST:VSANS:Globals:gCurDispType
	Variable binType = V_GetBinningPopMode()
	
	V_ConcatenateForSave(pathStr,curType,tagStr,binType)
	
// write out the data set to a file
	if(strlen(saveName)==0)
		Execute "V_GetNameForSave()"
		SVAR newName = root:saveName
		saveName = newName
	endif
	
	V_Write1DData(pathStr,curtype,saveName)

End


Proc V_GetNameForSave(str)
	String str
	String/G root:saveName=str
End


// blindly assumes that there is only one zero at the top of the wave
// could be more sophisticated in the future...
Function V_RemoveQ0_B(type)
	String type
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)

	WAVE/Z qBin = qBin_qxqy_B
	WAVE/Z iBin = iBin_qxqy_B
	WAVE/Z eBin = eBin_qxqy_B
	WAVE/Z nBin = nBin_qxqy_B
	WAVE/Z iBin2 = iBin2_qxqy_B

	// resolution waves
	Wave/Z sigQ = sigmaQ_qxqy_B
	Wave/Z qBar = qBar_qxqy_B
	Wave/Z fSubS = fSubS_qxqy_B

	if(qBin[0] == 0)
		DeletePoints 0, 1, qBin,iBin,eBin,nBin,iBin2,sigQ,qBar,fSubS
	endif
	
	SetDataFolder root:
	return(0)
end


// concatentate data in folderStr
//
// TODO:
// x- !!! Resolution waves are currently skipped - these must be added
//
// x- this currently ignores the binning type (one, two, etc. )
// x- change the Concatenate call to use the waveList, to eliminate the need to declare all of the waves
// -- this currently assumes that all of the waves exist
// -- need robust error checking for wave existence
// -- wave names are hard-wired and their name and location may be different in the future
// x- if different averaging options were chosen (bin type of 2, 4 etc) then
//    although waves may exist, they may not be the right ones to use. There
//    will be a somewhat complex selection process
// x- detector B is currently skipped
//
// this seems like a lot of extra work to do something so simple...but it's better than a loop
//
//  root:Packages:NIST:VSANS:RAW:iBin_qxqy_FB
//
// Now, the extensions needed for each binType are handled in a loop using the strings
// defined globally for each of the numbered binTypes
//
// binType = 1 = one
// binType = 2 = two
// binType = 3 = four
// binType = 4 = Slit Mode
// binType = 5...
//
// if binType is passed in as -9999, get the binning mode from the popup
// otherwise the value is assumed good (from a protocol)
//
// pathStr must have the trailing colon
// tagStr is normally null, but is "_trim" for data to be trimmed
//
Function V_1DConcatenate(pathStr,folderStr,tagStr,binType)
	String pathStr,folderStr,tagStr
	Variable binType
	

	if(binType==-9999)
		binType = V_GetBinningPopMode()
	endif	
	
	String binTypeString = V_getBinTypeString(binType)
	if(strlen(binTypeString) == 0)
		DoAlert 0,"binTypeString is null in V_1DConcatenate"
		return(0)
	endif
	
//	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)
	SetDataFolder $(pathStr+folderStr)

	//kill these waves before starting, or the new concatenation will be added to the old
	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_qb,tmp_sq,tmp_fs

	String q_waveListStr=""
	String i_waveListStr=""
	String s_waveListStr=""
	String sq_waveListStr=""
	String qb_waveListStr=""
	String fs_waveListStr=""
	
	Variable num,ii
	String item=""
	
	//Generate string lists of the waves to be concatenated based on the 
	// binTypeString (a global string constant with the extensions)
	//
	
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(!gIgnoreDetB)
		q_waveListStr =  "qBin_qxqy_B" + tagStr + ";"
		i_waveListStr =  "iBin_qxqy_B" + tagStr + ";"
		s_waveListStr =  "eBin_qxqy_B" + tagStr + ";"
		sq_waveListStr =  "sigmaQ_qxqy_B" + tagStr + ";"
		qb_waveListStr =  "qBar_qxqy_B" + tagStr + ";"
		fs_waveListStr =  "fSubS_qxqy_B" + tagStr + ";"	
	endif

	num = ItemsInList(binTypeString, ";")
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, binTypeString  ,";")	
	
	// "B" was handled outside the loop, be sure to skip here
		if(cmpstr(item,"B") != 0)
			q_waveListStr +=  "qBin_qxqy_" + item + tagStr + ";"
			i_waveListStr +=  "iBin_qxqy_" + item + tagStr + ";"
			s_waveListStr +=  "eBin_qxqy_" + item + tagStr + ";"
			sq_waveListStr +=  "sigmaQ_qxqy_" + item + tagStr + ";"
			qb_waveListStr +=  "qBar_qxqy_" + item + tagStr + ";"
			fs_waveListStr +=  "fSubS_qxqy_" + item + tagStr + ";"	
		endif
	endfor
	
	// concatenate each of the sets

	Concatenate/NP/O q_waveListStr, tmp_q
	
	Concatenate/NP/O i_waveListStr, tmp_i
		
	Concatenate/NP/O s_waveListStr, tmp_s
		
	Concatenate/NP/O sq_waveListStr, tmp_sq

	Concatenate/NP/O qb_waveListStr, tmp_qb
		
	Concatenate/NP/O fs_waveListStr, tmp_fs
										


// Can't kill here, since they are still needed to sort and write out!
//	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_res0,tmp_res1,tmp_res2,tmp_res3	
	
	SetDataFolder root:
	
	return(0)		
End

// TODO:
// -- resolution waves are ignored, since they don't exist (yet)
// -- only a sort is done, no rescaling of data sets
//    (it's too late now anyways, since the data was concatenated)
//
// see Auto_Sort() in the SANS Automation ipf for the rest of the details of
// how to combine the resolution waves (they also need to be concatenated, which is currently not done)
// 
Function V_TmpSort1D(pathStr,folderStr)
	String pathStr,folderStr
	
	SetDataFolder $(pathStr+folderStr)

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
	Wave sq = tmp_sq
	Wave qb = tmp_qb
	Wave fs = tmp_fs
	

	Sort qw, qw,iw,sw,sq,qb,fs


	SetDataFolder root:
	return(0)
End


//
Proc V_Load_Data_ITX()
	V_Load_itx("","",0,0)
end

// TODO
// -- fill in
// -- link somewhere?
//
// a function to load in the individual I(q) sets which were written out to a single
// file, in itx format.
//
// The data, like other 1D data sets, is to be loaded to its own folder under root
//
// Then, the data sets can be plotted as VSANS data sets, depending on which data extensions are present.
// (and color coded)
// (and used for setting the trimming)
// (and...)
//
//
// see A_LoadOneDDataToName(fileStr,outStr,doPlot,forceOverwrite)
//
Function V_Load_itx(fileStr,outStr,doPlot,forceOverwrite)
	String fileStr, outstr
	Variable doPlot,forceOverwrite

	SetDataFolder root:		//build sub-folders for each data set under root

	// if no fileStr passed in, display dialog now
	if (cmpStr(fileStr,"") == 0)
		fileStr = DoOpenFileDialog("Select a data file to load")
		if (cmpstr(fileStr,"") == 0)
			String/G root:Packages:NIST:gLastFileName = ""
			return(0)		//get out if no file selected
		endif
	endif

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/O/T fileStr
//	LoadWave/G/D/A/Q fileStr
	String fileNamePath = S_Path+S_fileName
//		String basestr = ParseFilePath(3,ParseFilePath(5,fileNamePath,":",0,0),":",0,0)

	String basestr
	if (!cmpstr(outstr, ""))		//Outstr = "", cmpstr returns 0
//			enforce a short enough name here to keep Igor objects < 31 chars
		baseStr = ShortFileNameString(CleanupName(S_fileName,0))
		baseStr = CleanupName(baseStr,0)		//in case the user added odd characters
		//baseStr = CleanupName(S_fileName,0)
	else
		baseStr = outstr			//for output, hopefully correct length as passed in
	endif

//		print "basestr :"+basestr
	String fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
//		print "filename :"+filename
	
	Variable ii,num=ItemsinList(S_waveNames)
	
	if(DataFolderExists("root:"+baseStr))
		if (!forceOverwrite)
			DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No, don't load the data
				SetDataFolder root:
				for(ii=0;ii<num;ii+=1)		
					KillWaves $(StringFromList(ii, S_waveNames))	// kill the waves that were loaded
				endfor
				if(DataFolderExists("root:Packages:NIST"))
					String/G root:Packages:NIST:gLastFileName = filename
				endif
				return(0)	//quits the macro
			endif
		endif
		SetDataFolder $("root:"+baseStr)
	else
		NewDataFolder/S $("root:"+baseStr)
	endif
	
//			////overwrite the existing data, if it exists

// a semicolon-delimited list of wave names loaded
//S_waveNames
	for(ii=0;ii<num;ii+=1)		
		Duplicate/O $("root:"+StringFromList(ii, S_waveNames)), $(StringFromList(ii, S_waveNames))
	endfor


// clean up
	SetDataFolder root:

	for(ii=0;ii<num;ii+=1)		
		KillWaves $(StringFromList(ii, S_waveNames))	// kill the waves that were loaded
	endfor
//			Duplicate/O $("root:"+n0), $w0
//			Duplicate/O $("root:"+n1), $w1
//			Duplicate/O $("root:"+n2), $w2
	
	// no resolution matrix to make

	
	return(0)
End



// string function to select the correct string constant
// that corresponds to the selected binType. This string constant
// contains the list of extensions to be used for plotting, saving, etc.
//
// returns null string if no match
//
Function/S V_getBinTypeString(binType)
	Variable binType
	
	String detListStr=""
	if(binType == 1)
		detListStr = ksBinType1
	endif
	if(binType == 2)
		detListStr = ksBinType2
	endif
	if(binType == 3)
		detListStr = ksBinType3
	endif
	if(binType == 4)
		detListStr = ksBinType4
	endif
	if(binType == 5)
		detListStr = ksBinType5
	endif
	if(binType == 6)
		detListStr = ksBinType6
	endif
	if(binType == 7)
		detListStr = ksBinType7
	endif
	
	
	return(detListStr)
End

// given strings of the number of points to remove, loop over the detectors
//
// TODO
// -- currently uses global strings or default strings
// -- if proper strings (non-null) are passed in, they are used, otherwise global, then default
Function V_Trim1DDataStr(folderStr,binType,nBegStr,nEndStr)
	String folderStr
	Variable binType
	String nBegStr,nEndStr
	
	String detListStr=""

	detListStr = V_getBinTypeString(binType)		//the list of extensions
	if(strlen(detListStr)==0)
		return(0)
	endif

	
	//use global, then default values if null string passed in
	if(strlen(nBegStr)==0)
		SVAR/Z gBegPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
		SVAR/Z gEndPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr
	
		if(!SVAR_exists(gBegPtsStr) || !SVAR_exists(gEndPtsStr) || strlen(gBegPtsStr)==0 || strlen(gEndPtsStr)==0)
			nBegStr = ksBinTrimBegDefault
			nEndStr = ksBinTrimEndDefault
		else
			nBegStr = gBegPtsStr
			nEndStr = gEndPtsStr
		endif
	endif	

	Variable num, ii,nBeg,nEnd
	String item,detstr

	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	
	num = ItemsInList(detListStr)
	for(ii=0;ii<num;ii+=1)
		detStr = StringFromList(ii, detListStr)
		if(cmpstr(detStr,"B")==0 && gIgnoreDetB)
				//skip det B, do nothing
		else
			nBeg = NumberByKey(detStr, nBegStr,"=",";")
			nEnd = NumberByKey(detStr, nEndStr,"=",";")

			V_TrimOneSet(folderStr,detStr,nBeg,nEnd)
		endif
	endfor

	return(0)
End

// TODO
// x- make this resolution-aware
//
Function V_TrimOneSet(folderStr,detStr,nBeg,nEnd)
	String folderStr,detStr
	Variable nBeg,nEnd
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	Printf "%d points removed from beginning, %d points from the end  of %s \r",nbeg,nend,detStr

// TODO	
// for each binType block:
// --declare the waves
// --make a copy of the waves??
//	//--Break out resolution wave into separate waves
// --delete the beginning points from everything
	// --trim off the last nEnd points from everything
//	--DeletePoints num-nEnd,nEnd, qw,iw,sw
//	// --delete all points where the shadow is < 0.98
////--Put resolution contents back???

		Wave/Z qw = $("qBin_qxqy_"+detStr)
		Wave/Z iw = $("iBin_qxqy_"+detStr)
		Wave/Z ew = $("eBin_qxqy_"+detStr)
		// resolution waves
		Wave/Z sigQ = $("sigmaQ_qxqy_"+detStr)
		Wave/Z qBar = $("qBar_qxqy_"+detStr)
		Wave/Z fSubS = $("fSubS_qxqy_"+detStr)
			
		DeletePoints 0,nBeg, qw,iw,ew,sigQ,qBar,fSubS

		Variable npt
		npt = numpnts(qw) 
		DeletePoints npt-nEnd,nEnd, qw,iw,ew,sigQ,qBar,fSubS
	
	return(0)
End


////
//// returns 1 if the val is non-negative, other value
//// indicates that the resoution data is USANS data.
////
//// TODO:
//// -- this DUPLICATES a same-named SANS procedure, so there could be a clash at some point
//// -- bigger issue - I'll need a better way to identify and load the different resolution 
//// 		conditions with VSANS
////
////
//xFunction isSANSResolution(val)
//	Variable val
//	
//	if(val >= 0)
//		return(1)
//	else
//		return(0)
//	endif
//End


