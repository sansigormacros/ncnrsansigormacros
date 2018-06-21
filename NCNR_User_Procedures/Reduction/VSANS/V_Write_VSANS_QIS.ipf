#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



// TODO:
// -- this is a temporary solution before a real writer is created
// -- resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// -- but a real writer will need to be aware of resolution, and there may be different forms
//
// this will bypass save dialogs
// -- AND WILL OVERWITE DATA WITH THE SAME NAME
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

// TODO
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



// TODO:
// -- this is a temporary solution before a real writer is created
// -- resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// -- but a real writer will need to be aware of resolution, and there may be different forms
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


	//TODO
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



	// TODO:
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

// TODO
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