#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//
// this is the general writer for output of 1D averaged I(q) datasets
//
Function V_Write1DData(pathStr,folderStr,saveName)
	String pathStr,folderStr,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
	Wave sigQ = tmp_sq
	Wave qbar = tmp_qb
	Wave fs = tmp_fs
	
	String dataSetFolderParent,basestr
	
	// ParseFilePath to get path without folder name
//	dataSetFolderParent = ParseFilePath(1,folderStr,":",1,0)
	// ParseFilePath to get basestr
//	basestr = ParseFilePath(0,folderStr,":",1,0)
	
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	
	
	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	
	//make sure the waves exist
	
	if(WaveExists(qw) == 0)
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		Abort "s is missing"
	endif
	if(WaveExists(sigQ) == 0)
		Abort "Resolution information is missing."
	endif
	if(WaveExists(proto) == 0)
		Abort "protocol information is missing."
	endif
	


// TODO -- not sure if I need to implement this. Update to VSANS specs if I do.
//	//strings can be too long to print-- must trim to 255 chars
//	Variable ii,num=8
//	Make/O/T/N=(num) tempShortProto
//	for(ii=0;ii<num;ii+=1)
//		tempShortProto[ii] = (proto[ii])[0,240]
//	endfor

// if the "default" trimming is used, the proto[] values will be null
// fill them in with the default values
	String protoStr7,protoStr8
	if(strlen(proto[7]) == 0)
		protoStr7 = "(Default) "+ ksBinTrimBegDefault
	else
		protoStr7 = proto[7]
	endif
	if(strlen(proto[8]) == 0)
		protoStr8 = "(Default) "+ ksBinTrimEndDefault
	else
		protoStr8 = proto[8]
	endif	

	PathInfo catPathName
	fullPath = S_Path + saveName

	Open refnum as fullpath

	fprintf refnum,"Combined data written from folder %s on %s\r\n",folderStr,(date()+" "+time())

	//insert protocol information here
	//-1 list of sample files
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 - DRK (unused in VSANS)
	//7 - beginning trim points
	//8 - end trim points
	fprintf refnum, "SAM: %s\r\n",samFiles
	fprintf refnum, "BGD: %s\r\n",proto[0]
	fprintf refnum, "EMP: %s\r\n",Proto[1]
	fprintf refnum, "DIV: %s\r\n",Proto[2]
	fprintf refnum, "MASK: %s\r\n",Proto[3]
	fprintf refnum, "ABS Parameters (3-6): %s\r\n",Proto[4]
	fprintf refnum, "Average Choices: %s\r\n",Proto[5]
	fprintf refnum, "Beginning Trim Points: %s\r\n",ProtoStr7
	fprintf refnum, "End Trim Points: %s\r\n",ProtoStr8
	fprintf refnum, "COLLIMATION=%s\r\n",proto[9]

// DONE
// x- make this work for 6-columns (or??)
	formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"	
	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs

	// three column vresion
//	formatStr = "%15.4g %15.4g %15.4g\r\n"	
//	fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//
//	wfprintf refnum,formatStr,qw,iw,sw


	Close refnum
	
//	KillWaves/Z sigQ,qbar,fs
	Print "Data written to: ",fullpath
	
	SetDataFolder root:
	return(0)
End


//
// this is the general writer for output of 1D averaged I(q) datasets
// this version is limited to three column data where there is no
// resolution information present
//
Function V_Write1DData_3Col(pathStr,folderStr,saveName)
	String pathStr,folderStr,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
//	Wave sigQ = tmp_sq
//	Wave qbar = tmp_qb
//	Wave fs = tmp_fs
	
	String dataSetFolderParent,basestr
	
	// ParseFilePath to get path without folder name
//	dataSetFolderParent = ParseFilePath(1,folderStr,":",1,0)
	// ParseFilePath to get basestr
//	basestr = ParseFilePath(0,folderStr,":",1,0)
	
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	
	
	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	
	//make sure the waves exist
	
	if(WaveExists(qw) == 0)
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		Abort "s is missing"
	endif
//	if(WaveExists(sigQ) == 0)
//		Abort "Resolution information is missing."
//	endif
	if(WaveExists(proto) == 0)
		Abort "protocol information is missing."
	endif


// if the "default" trimming is used, the proto[] values will be null
// fill them in with the default values
	String protoStr7,protoStr8
	if(strlen(proto[7]) == 0)
		protoStr7 = "(Default) "+ ksBinTrimBegDefault
	else
		protoStr7 = proto[7]
	endif
	if(strlen(proto[8]) == 0)
		protoStr8 = "(Default) "+ ksBinTrimEndDefault
	else
		protoStr8 = proto[8]
	endif	

	PathInfo catPathName
	fullPath = S_Path + saveName

	Open refnum as fullpath

	fprintf refnum,"Combined data written from folder %s on %s\r\n",folderStr,(date()+" "+time())

	//insert protocol information here
	//-1 list of sample files
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 - DRK (unused in VSANS)
	//7 - beginning trim points
	//8 - end trim points
	fprintf refnum, "SAM: %s\r\n",samFiles
	fprintf refnum, "BGD: %s\r\n",proto[0]
	fprintf refnum, "EMP: %s\r\n",Proto[1]
	fprintf refnum, "DIV: %s\r\n",Proto[2]
	fprintf refnum, "MASK: %s\r\n",Proto[3]
	fprintf refnum, "ABS Parameters (3-6): %s\r\n",Proto[4]
	fprintf refnum, "Average Choices: %s\r\n",Proto[5]
	fprintf refnum, "Beginning Trim Points: %s\r\n",ProtoStr7
	fprintf refnum, "End Trim Points: %s\r\n",ProtoStr8
	fprintf refnum, "COLLIMATION=%s\r\n",proto[9]


	// three column version
	formatStr = "%15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//
	wfprintf refnum,formatStr,qw,iw,sw

	Close refnum
	
//	KillWaves/Z sigQ,qbar,fs
	Print "Data written to: ",fullpath
	
	SetDataFolder root:
	return(0)
End


//
// This saves the data in individual files for each detector panel. They are meant only for
// troubleshooting, but the files are in the general ascii format (without resolution)
// so only three columns are written out
//
// this will bypass save dialogs
// -- AND WILL OVERWRITE DATA WITH THE SAME NAME
//
Function V_Write1DData_Individual(pathStr,folderStr,saveName,exten,binType)
	String pathStr,folderStr,saveName,exten
	Variable binType
	
	String formatStr="",fullpath="",item,fileName,detList
	Variable refnum,num,ii

	SetDataFolder $(pathStr+folderStr)

	NVAR gIgnoreB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	// while in the proper data folder, loop through the detector files
	// and write out each individual panel (or sets of panels) as specified 
	// by the binning type.
	//
	// copy the desired files over to tmp_q, tmp_i, and tmp_s, then 
	// pass to a worker Function
	//
	
	//
	//  ksBinType1 = "FT;FB;FL;FR;MT;MB;ML;MR;B;"		//these are the "active" extensions
	//  ksBinType2 = "FTB;FLR;MTB;MLR;B;"
	//  ksBinType3 = "FLRTB;MLRTB;B;"
	//  ksBinType4 = "FL;FR;ML;MR;B;"		//in SLIT mode, disregard the T/B panels
	
	
	switch(binType)
		case 1:		// 9 sets 
			detList = ksBinType1
			break
		case 2:		// 5 sets
			detList = ksBinType2
			break
		case 3:		// 3 sets
			detList = ksBinType3
			break
		case 4:		// 5 sets
			detList = ksBinType4
			break
		case 5:		// 4 sets
			detList = ksBinType5
			break
		case 6:		// 3 sets
			detList = ksBinType6
			break
		case 7:		// 4 sets
			detList = ksBinType7
			break
								
		default:
		// do nothing, just close

	endswitch

	num=ItemsInList(detList)
	for(ii=0;ii<num;ii+=1)
		SetDataFolder $(pathStr+folderStr)

		item=StringFromList(ii, detList)
		
		if(gIgnoreB && cmpstr(item,"B") == 0)
			//do nothing
		else
			fileName = saveName + "_"+item+"."+exten
			Wave qWave = $("qBin_qxqy_"+item)
			Wave iWave = $("iBin_qxqy_"+item)
			Wave eWave = $("eBin_qxqy_"+item)
			KillWaves/Z tmp_q, tmp_i, tmp_s
			Duplicate/O qWave tmp_q
			Duplicate/O iWave tmp_i
			Duplicate/O eWave tmp_s
			V_Write1DData_3Col(pathStr,folderStr,fileName)
		endif
		
	endfor
	
	SetDataFolder root:
	return(0)
End





// DONE:
// - this is a temporary solution before a real writer is created
// -- it has been replaced with V_Write1DData_Individual
// - resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// - but a real writer will need to be aware of resolution, and there may be different forms
//
// This saves the data in Igor Text format, an ASCII format, but NOT standard SANS columns
// No concatenation is done. This is meant to be used for input to TRIM, or for general troubleshooting
//
//
// this will bypass save dialogs
// -- AND WILL OVERWRITE DATA WITH THE SAME NAME
//
Function V_Write1DData_ITX(pathStr,folderStr,saveName,binType)
	String pathStr,folderStr,saveName
	Variable binType
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)



	//-- make sure the waves exist
	
//	if(WaveExists(qw) == 0)
//		Abort "q is missing"
//	endif
//	if(WaveExists(iw) == 0)
//		Abort "i is missing"
//	endif
//	if(WaveExists(sw) == 0)
//		Abort "s is missing"
//	endif
//	if(WaveExists(resw) == 0)
//		Abort "Resolution information is missing."
//	endif
	
//	Duplicate/O qw qbar,sigQ,fs
//	if(dimsize(resW,1) > 4)
//		//it's USANS put -dQv back in the last 3 columns
//		NVAR/Z dQv = USANS_dQv
//		if(NVAR_Exists(dQv) == 0)
//			SetDataFolder root:
//			Abort "It's USANS data, and I don't know what the slit height is."
//		endif
//		sigQ = -dQv
//		qbar = -dQv
//		fs = -dQv
//	else
//		//it's SANS
//		sigQ = resw[p][0]
//		qbar = resw[p][1]
//		fs = resw[p][2]
//	endif
//	




	// -- currently I'm using the Save comand and the /B flag
	//    to save the data as Igor Text format, since otherwise the command string would be
	//    too long. Need to come up with an Igor-demo friendly save here
	//
	// -- see V_ExportProtocol() for a quick example of how to generate the .ITX format
	//
	// -- need a reader/plotter capable of handling this data. The regular data loader won't handle
	//    all the different number of columns present, or the ITX format. See V_DataPlotting and duplicate these routines
	//    Most of these routines take "winNameStr" as an argument, so I may be able to use them
	//
	// -- do I want to add the /O flag to force an overwrite if there is a name conflict?

	PathInfo catPathName
	fullPath = S_Path + saveName + ".itx"

//	Open refnum as fullpath
//	fprintf refnum,"Individual data sets written from folder %s on %s\r\n",folderStr,(date()+" "+time())

	String waveStr=""
	// can be a multiple number of columns
		
	switch(binType)
		case 1:		// 9 sets = 27 waves!
			waveStr = "qBin_qxqy_B;iBin_qxqy_B;eBin_qxqy_B;"
			waveStr += "qBin_qxqy_ML;iBin_qxqy_ML;eBin_qxqy_ML;"
			waveStr += "qBin_qxqy_MR;iBin_qxqy_MR;eBin_qxqy_MR;"
			waveStr += "qBin_qxqy_MT;iBin_qxqy_MT;eBin_qxqy_MT;"
			waveStr += "qBin_qxqy_MB;iBin_qxqy_MB;eBin_qxqy_MB;"
			waveStr += "qBin_qxqy_FL;iBin_qxqy_FL;eBin_qxqy_FL;"
			waveStr += "qBin_qxqy_FR;iBin_qxqy_FR;eBin_qxqy_FR;"
			waveStr += "qBin_qxqy_FT;iBin_qxqy_FT;eBin_qxqy_FT;"
			waveStr += "qBin_qxqy_FB;iBin_qxqy_FB;eBin_qxqy_FB;"
			
			
			Save/T/M="\r\n"/B waveStr as fullPath

						
//			formatStr = "%15.4g %15.4g %15.4g\r\n"
//			
//			fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//	
//			wfprintf refnum,formatStr,qw,iw,sw
			break
		case 2:		// 5 sets

			waveStr = "qBin_qxqy_B;iBin_qxqy_B;eBin_qxqy_B;"
			waveStr += "qBin_qxqy_MLR;iBin_qxqy_MLR;eBin_qxqy_MLR;qBin_qxqy_MTB;iBin_qxqy_MTB;eBin_qxqy_MTB;"
			waveStr += "qBin_qxqy_FLR;iBin_qxqy_FLR;eBin_qxqy_FLR;qBin_qxqy_FTB;iBin_qxqy_FTB;eBin_qxqy_FTB;"

			Save/T/M="\r\n"/B waveStr as fullPath
			
//			formatStr = "%15.4g %15.4g %15.4g\r\n"
//			
//			fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//	
//			wfprintf refnum,formatStr,qw,iw,sw
			break
		case 3:		// 3 sets
//			WAVE q1 = qBin_qxqy_B
//			WAVE i1 = iBin_qxqy_B
//			WAVE s1 = eBin_qxqy_B
//			WAVE q2 = qBin_qxqy_MLRTB
//			WAVE i2 = iBin_qxqy_MLRTB
//			WAVE s2 = eBin_qxqy_MLRTB
//			WAVE q3 = qBin_qxqy_FLRTB
//			WAVE i3 = iBin_qxqy_FLRTB
//			WAVE s3 = eBin_qxqy_FLRTB
//
//				
//			Save/T/M="\r\n" q1,i1,s1,q2,i2,s2,q3,i3,s3 as fullPath
			
			waveStr = "qBin_qxqy_B;iBin_qxqy_B;eBin_qxqy_B;"
			waveStr += "qBin_qxqy_MLRTB;iBin_qxqy_MLRTB;eBin_qxqy_MLRTB;qBin_qxqy_FLRTB;iBin_qxqy_FLRTB;eBin_qxqy_FLRTB;"

			Save/T/M="\r\n"/B waveStr as fullPath			
			
			
//			formatStr = "%15.4g %15.4g %15.4g\r\n"
//			
//			fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//	
//			wfprintf refnum,formatStr,qw,iw,sw
			break
		case 4:		// 9 sets
			waveStr = "qBin_qxqy_B;iBin_qxqy_B;eBin_qxqy_B;"
			waveStr += "qBin_qxqy_ML;iBin_qxqy_ML;eBin_qxqy_ML;"
			waveStr += "qBin_qxqy_MR;iBin_qxqy_MR;eBin_qxqy_MR;"
			waveStr += "qBin_qxqy_MT;iBin_qxqy_MT;eBin_qxqy_MT;"
			waveStr += "qBin_qxqy_MB;iBin_qxqy_MB;eBin_qxqy_MB;"
			waveStr += "qBin_qxqy_FL;iBin_qxqy_FL;eBin_qxqy_FL;"
			waveStr += "qBin_qxqy_FR;iBin_qxqy_FR;eBin_qxqy_FR;"
			waveStr += "qBin_qxqy_FT;iBin_qxqy_FT;eBin_qxqy_FT;"
			waveStr += "qBin_qxqy_FB;iBin_qxqy_FB;eBin_qxqy_FB;"
			
			
			Save/T/M="\r\n"/B waveStr as fullPath

//			formatStr = "%15.4g %15.4g %15.4g\r\n"
//			
//			fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	
//	
//			wfprintf refnum,formatStr,qw,iw,sw
			break
					
		default:
		// do nothing, just close

	endswitch

//	Close refnum

// 
// -- clean up any waves on exit?	 Only if I generate extra waves
//	KillWaves/Z sigQ,qbar,fs
	
	SetDataFolder root:
	return(0)
End

// awkward, but can't call STRUCT from Proc
Proc Vm_Write1DData_ITX()
	Vf_FakeSaveIQITXClick()	
End

Function Vf_FakeSaveIQITXClick()
	STRUCT WMButtonAction ba
	ba.eventCode=2
	V_SaveIQ_ButtonProc(ba)
end


///////// QxQy Export  //////////
//
// (see the similar-named SANS routine for additonal steps - like resolution, etc.)
//ASCII export of data as 9-columns qx-qy-Intensity-err-qz-sigmaQ_parall-sigmaQ_perp-fShad-mask
//
// + limited header information
//
//	Jan 2019 -- first version, simply exports the basic matrix of data with no resolution information
//
//
Function V_QxQy_Export(type,fullpath,newFileName,dialog)
	String type,fullpath,newFileName
	Variable dialog		//=1 will present dialog for name
	
	String typeStr=""
	Variable refnum
	String detStr="",detSavePath

	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	
	// declare, or make a fake protocol if needed (if the export type is RAW)
	String rawTag=""
	if(cmpstr(type,"RAW")==0)
		Make/O/T/N=(kNumProtocolSteps) proto
		RawTag = "RAW Data File: "	
	else
		Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	
	endif
	
	SVAR samFiles = $("root:Packages:NIST:VSANS:"+type+":gFileList")
	
	//check each wave - MUST exist, or will cause a crash
//	If(!(WaveExists(data)))
//		Abort "data DNExist QxQy_Export()"
//	Endif

	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif

	// data values to populate the file header
	String fileName,fileDate,fileLabel
	Variable monCt,lambda,offset,dist,trans,thick
	Variable bCentX,bCentY,a2,a1a2_dist,deltaLam,bstop
	String a1Str
	Variable pixX,pixY
	Variable numTextLines,ii,jj,kk
	Variable pixSizeX,pixSizeY
	Variable duration

	numTextLines = 30
	Make/O/T/N=(numTextLines) labelWave

	//
	
	//loop over all of the detector panels
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	String detList
	if(gIgnoreDetB)
		detList = ksDetectorListNoB
	else
		detList = ksDetectorListAll
	endif
	
	String combinedSavePath = fullPath + "_COMBINED.DAT"
	
//	for(kk=0;kk<ItemsInList(detList);kk+=1)
// be sure to write out "B" first, so it ends up in the "back" in the graph
// so work through the list backwards
	for(kk=ItemsInList(detList)-1;kk>=0;kk-=1)

		detStr = StringFromList(kk, detList, ";")
		detSavePath = fullPath + "_" + detStr + ".DAT"
		
		pixX = V_getDet_pixel_num_x(type,detStr)
		pixY = V_getDet_pixel_num_y(type,detStr)
		
		fileName = newFileName
		fileDate = V_getDataStartTime(type)		// already a string
		fileLabel = V_getSampleDescription(type)
		
		monCt = V_getBeamMonNormData(type)
		lambda = V_getWavelength(type)
	
	// messy - switch based on panel type to get the correct offset
		if(cmpstr(detStr,"FT") == 0 || cmpstr(detStr,"FB") == 0)
			offset = V_getDet_VerticalOffset(type,detStr)
		endif
		if(cmpstr(detStr,"MT") == 0 || cmpstr(detStr,"MB") == 0)
			offset = V_getDet_VerticalOffset(type,detStr)
		endif	
		
		if(cmpstr(detStr,"FL") == 0 || cmpstr(detStr,"FR") == 0)
			offset = V_getDet_LateralOffset(type,detStr)
		endif
		if(cmpstr(detStr,"ML") == 0 || cmpstr(detStr,"MR") == 0 || cmpstr(detStr,"B") == 0)
			offset = V_getDet_LateralOffset(type,detStr)
		endif	

	
		dist = V_getDet_ActualDistance(type,detStr)
		trans = V_getSampleTransmission(type)
		thick = V_getSampleThickness(type)
		
		bCentX = V_getDet_beam_center_x(type,detStr)
		bCentY = V_getDet_beam_center_y(type,detStr)
		a1Str = V_getSourceAp_size(type)		//already a string
		a2 = V_getSampleAp2_size(type)
		a1a2_dist = V_getSourceAp_distance(type)
		deltaLam = V_getWavelength_spread(type)
		// TODO -- decipher which beamstop, if any is actually in place
	// or -- V_getBeamStopC3_size(type)
		bstop = V_getBeamStopC2_size(type)

		pixSizeX = V_getDet_x_pixel_size(type,detStr)
		pixSizeY = V_getDet_y_pixel_size(type,detStr)
		
		duration = V_getCount_time(type)
		
	/////////
		labelWave[0] = "FILE: "+fileName+"   CREATED: "+fileDate
		labelWave[1] = "LABEL: "+fileLabel
		labelWave[2] = "MON CNT   LAMBDA (A)  DET_OFF(cm)   DET_DIST(cm)   TRANS   THICK(cm)"
		labelWave[3] = num2str(monCt)+"  "+num2str(lambda)+"       "+num2str(offset)+"     "+num2str(dist)
		labelWave[3] += "     "+num2str(trans)+"     "+num2str(thick)
		labelWave[4] = "BCENT(X,Y)(cm)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)"
		labelWave[5] = num2str(bCentX)+"  "+num2str(bCentY)+"  "+a1Str+"    "+num2str(a2)+"    "
		labelWave[5] += num2str(a1a2_dist)+"    "+num2str(deltaLam)+"    "+num2str(bstop)
		labelWave[6] =  "SAM: "+rawTag+samFiles
		labelWave[7] =  "BGD: "+proto[0]
		labelWave[8] =  "EMP: "+proto[1]
		labelWave[9] =  "DIV: "+proto[2]
		labelWave[10] =  "MASK: "+proto[3]
		labelWave[11] =  "ABS Parameters (3-6): "+proto[4]
		labelWave[12] = "Average Choices: "+proto[5]
		labelWave[13] = "Collimation type: "+proto[9]
		labelWave[14] = "Panel="+detStr
		labelWave[15] = "NumXPixels="+num2str(pixX)
		labelWave[16] = "XPixelSize_mm="+num2str(pixSizeX)
		labelWave[17] = "NumYPixels="+num2str(pixY)
		labelWave[18] = "YPixelSize_mm="+num2str(pixSizeY)
		labelWave[19] = "Duration (s)="+num2str(duration)
		labelWave[20] = "reserved for future file definition changes"
		labelWave[21] = "reserved for future file definition changes"
		labelWave[22] = "reserved for future file definition changes"
		labelWave[23] = "reserved for future file definition changes"
		labelWave[24] = "reserved for future file definition changes"
		labelWave[25] = "reserved for future file definition changes"

		labelWave[26] = "*** Data written from "+type+" folder and may not be a fully corrected data file ***"
		labelWave[27] = "Data columns are Qx - Qy - I(Qx,Qy) - err(I) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow) - Mask"
		labelWave[28] = "The 2D error is fully propagated through all correction steps"
		labelWave[29] = "ASCII data created " +date()+" "+time()
		//strings can be too long to print-- must trim to 255 chars
		for(jj=0;jj<numTextLines;jj+=1)
			labelWave[jj] = (labelWave[jj])[0,240]
		endfor
	
	
	// get the data waves for output
	// QxQyQz have already been calculated for VSANS data
		
		WAVE data = V_getDetectorDataW(type,detStr)
		WAVE data_err = V_getDetectorDataErrW(type,detStr)

// JUN 2019 get the mask data
// there can be cases where the mask is not used and does not exist -- so generate it and set it == 0
// to keep all of the data
		WAVE/Z MaskData = V_getDetectorDataW("MSK",detStr)

		if(WaveExists(MaskData) == 0)
			Duplicate/O data,MaskData
			MaskData = 0
		endif
		
		// TOOD - replace hard wired paths with Read functions
		// hard-wired
		Wave qx_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qx_"+detStr)
		Wave qy_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qy_"+detStr)
		Wave qz_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qz_"+detStr)
		Wave qTot = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qTot_"+detStr)
		
	///// calculation of the resolution function (2D)

	//
		Variable acc,ssd,lambda0,yg_d,qstar,g,L1,L2,vz_1,sdd
		// L1 = source to sample distance [cm] 
		L1 = V_getSourceAp_distance(type)
	
	// L2 = sample to detector distance [cm]
		L2 = V_getDet_ActualDistance(type,detStr)		//cm

	//		
		G = 981.  //!	ACCELERATION OF GRAVITY, CM/SEC^2
		vz_1 =	3.956E5	//	3.956E5 //!	CONVERT WAVELENGTH TO VELOCITY CM/SEC
		acc = vz_1
		SDD = L2		//1317
		SSD = L1		//1627 		//cm
		lambda0 = lambda		//		15
		YG_d = -0.5*G*SDD*(SSD+SDD)*(LAMBDA0/acc)^2
		Print "DISTANCE BEAM FALLS DUE TO GRAVITY (CM) = ",YG_d
	////		Print "Gravity q* = ",-2*pi/lambda0*2*yg_d/sdd
		qstar = -2*pi/lambda0*2*yg_d/sdd
	//	
	//
	//// the gravity center is not the resolution center
	//// gravity center = beam center
	//// resolution center = offset y = dy + (2)*yg_d
	/////************
	//// do everything to write out the resolution too
	//	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	//	qval = CalcQval(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
		Duplicate/O qTot,phi,r_dist
		Variable xctr,yctr


		xctr = V_getDet_beam_center_x_pix(type,detStr)
		yctr = V_getDet_beam_center_y_pix(type,detStr)
		phi = V_FindPhi( pixSizeX*((p+1)-xctr) , pixSizeY*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
		r_dist = sqrt(  (pixSizeX*((p+1)-xctr))^2 +  (pixSizeY*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt
	
		//make everything in 1D now
		Duplicate/O qTot SigmaQX,SigmaQY,fsubS,qval	
		Redimension/N=(pixX*pixY) SigmaQX,SigmaQY,fsubS,qval,phi,r_dist

		Variable ret1,ret2,ret3,nq
		String collimationStr
		
		
		collimationStr = proto[9]
		
		nq = pixX*pixY
		ii=0

// TODO
// this loop is the slow step. it takes ? 0.7 s for F or M panels, and ? 120 s for the Back panel (6144 pts vs. 1.12e6 pts)
// find some way to speed this up!
// MultiThreading will be difficult as it requires all the dependent functions (HDF5 reads, etc.) to be threadsafe as well
// and there are a lot of them... and I don't know if opening a file multiple times is a threadsafe operation? 
//  -- multiple open attempts seems like a bad idea.
		//type = work folder
		
//		(this doesn't work...and isn't any faster)
//		Duplicate/O qval dum
//		dum = V_get2DResolution(qval,phi,r_dist,type,detStr,collimationStr,SigmaQX,SigmaQY,fsubS)

v_tic()
		do
			V_get2DResolution(qval[ii],phi[ii],r_dist[ii],type,detStr,collimationStr,ret1,ret2,ret3)
			SigmaQX[ii] = ret1	
			SigmaQY[ii] = ret2	
			fsubs[ii] = ret3	
			ii+=1
		while(ii<nq)	
v_toc()	
	////*********************	
		Duplicate/O qx_val,qx_val_s
		Duplicate/O qy_val,qy_val_s
		Duplicate/O qz_val,qz_val_s
		Duplicate/O data,z_val_s
		Duplicate/O SigmaQx,sigmaQx_s
		Duplicate/O SigmaQy,sigmaQy_s
		Duplicate/O fSubS,fSubS_s
		Duplicate/O data_err,sw_s
		Duplicate/O MaskData,MaskData_s
		
		//so that double precision data is not written out
		Redimension/S qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		Redimension/S SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s
	
		Redimension/N=(pixX*pixY) qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s,MaskData_s
		
		//not demo-compatible, but approx 8x faster!!	
#if(strsearch(stringbykey("IGORKIND",IgorInfo(0),":",";"), "demo", 0 ) == -1)
		
//		Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s as detSavePath	// without resolution
		Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s as detSavePath	// write out the resolution information
//		if (kk==00)	//wrong - used when looping in order
		if (kk==ItemsInList(detList)-1) // use when looping backwards
			Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s as combinedSavePath	// write out the resolution information
		Else
			Save/A=2/G/M="\r\n" qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s as combinedSavePath	// write out the resolution information
		EndIf
#else
		Open refNum as detSavePath
		wfprintf refNum,"%s\r\n",labelWave
		fprintf refnum,"\r\n"
//		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s
		Close refNum
		// Combined file
		Open refNum as combinedSavePath
//		if (kk==00)	//wrong - used when looping in order
		if (kk==ItemsInList(detList)-1) // use when looping backwards
			wfprintf refNum,"%s\r\n",labelWave
			fprintf refnum,"\r\n"
		EndIf
		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s
//		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		Close refNum
#endif
		
		KillWaves/Z qx_val_s,qy_val_s,z_val_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,sw,sw_s,MaskData_s
		
		Killwaves/Z qval,sigmaQx,SigmaQy,fSubS,phi,r_dist	//,MaskData
		
		Print "QxQy_Export File written: ", V_GetFileNameFromPathNoSemi(detSavePath)
	
	endfor
	
	KillWaves/Z labelWave,dum
	return(0)
End


