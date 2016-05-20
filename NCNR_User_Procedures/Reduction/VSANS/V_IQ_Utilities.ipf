#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
//
// does no scaling, only the basic (default) trim of the ends, concatenate, sort, and save
//
// TODO:
// -- fill in all of the details...
//


//
// see the VCALC BinAllMiddlePanels() for an example of this
// see the binning routines in VC_DetectorBinning_Utils.ipf for the details
//
// TODO 
// x- detector "B" is currently skipped since the calibration waves are not faked
//    when the raw data is loaded. Then the qxqyqz waves are not generated.
//
// -- REDO the logic here. It's a mess, and will get the calculation wrong 
//
// -- figure out the binning type (where is it set for VSANS?)
// -- don't know, so currently VSANS binning type is HARD-WIRED
// -- figure out when this needs to be called to (force) re-calculate I vs Q
//
Function V_QBinAllPanels(folderStr)
	String folderStr

	// do the back, middle, and front separately
	
//	figure out the binning type (where is it set?)
	Variable binType,ii,delQ
	String detStr
	binType = 1
	
	

//// TODO:
// x- currently the "B" detector is skipped - it was skipped in 
//       previous functions where q values are calculated	
//	
	delQ = SetDeltaQ(folderStr,"B")
	
	// dispatch based on binning type
	if(binType == 1)
		VC_fDoBinning_QxQy2D(folderStr, "B")		//normal binning, nothing to combine
	endif

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		VC_fBinDetector_byRows(folderStr,"B")
	endif	



// these are the binning types where detectors are not combined
// other combined binning is below the loop
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		
		// set delta Q for binning
		delQ = SetDeltaQ(folderStr,detStr)
		
		// dispatch based on binning type
		if(binType==1)
			VC_fDoBinning_QxQy2D(folderStr,detStr)
		endif
		
		// TODO -- this is only a temporary fix for slit mode	
		if(binType == 4)
			/// this is for a tall, narrow slit mode	
			VC_fBinDetector_byRows(folderStr,detStr)
		endif	
		
	endfor
	
	// bin in pairs
	if(binType == 2)
		VC_fDoBinning_QxQy2D(folderStr,"MLR")
		VC_fDoBinning_QxQy2D(folderStr,"MTB")
		VC_fDoBinning_QxQy2D(folderStr,"FLR")
		VC_fDoBinning_QxQy2D(folderStr,"FTB")	
	endif
	
	// bin everything on front or middle together
	if(binType == 3)
		VC_fDoBinning_QxQy2D(folderStr,"MLRTB")
		VC_fDoBinning_QxQy2D(folderStr,"FLRTB")
	endif

	return(0)
End





Macro V_Combine1DData()

// get the current display type
	String type = root:Packages:NIST:VSANS:Globals:gCurDispType

// figure out which binning was used

// trim the data if needed

// concatenate the data sets
	V_1DConcatenate(type)
	
// sort the data set
	V_TmpSort1D(type)
	
// write out the data set to a file
	String/G saveName=""
	V_GetNameForSave("")
	V_Write1DData(type,saveName)

End

Proc V_GetNameForSave(str)
	String str
	String/G saveName=str
End


// concatentate data in folderStr
//
// TODO:
// -- this currently assumes that all of the waves exist
// -- need robust error checking for wave existence
// -- wave names are hard-wired and their name and location may be different in the future
// -- if different averaging options were chosen (bin type of 2, 4 etc) then
//    although waves may exist, they may not be the right ones to use. There
//    will be a somewhat complex selection process
// -- detector B is currently skipped
//
// this seems like a lot of extra work to do something so simple...
//
//  root:Packages:NIST:VSANS:RAW:iBin_qxqy_FB
Function V_1DConcatenate(folderStr)
	String folderStr
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)
	
	Wave/Z q_fb = qBin_qxqy_FB
	Wave/Z q_ft = qBin_qxqy_FT
	Wave/Z q_fl = qBin_qxqy_FL
	Wave/Z q_fr = qBin_qxqy_FR
	Wave/Z q_mb = qBin_qxqy_MB
	Wave/Z q_mt = qBin_qxqy_MT
	Wave/Z q_ml = qBin_qxqy_ML
	Wave/Z q_mr = qBin_qxqy_MR
	Wave/Z q_b = qBin_qxqy_B

	Concatenate/NP {q_fb,q_ft,q_fl,q_fr,q_mb,q_mt,q_ml,q_mr,q_b}, tmp_q
	
	Wave/Z i_fb = iBin_qxqy_FB
	Wave/Z i_ft = iBin_qxqy_FT
	Wave/Z i_fl = iBin_qxqy_FL
	Wave/Z i_fr = iBin_qxqy_FR
	Wave/Z i_mb = iBin_qxqy_MB
	Wave/Z i_mt = iBin_qxqy_MT
	Wave/Z i_ml = iBin_qxqy_ML
	Wave/Z i_mr = iBin_qxqy_MR
	Wave/Z i_b = iBin_qxqy_B
	
	Concatenate/NP {i_fb,i_ft,i_fl,i_fr,i_mb,i_mt,i_ml,i_mr,i_b}, tmp_i

	Wave/Z s_fb = eBin_qxqy_FB
	Wave/Z s_ft = eBin_qxqy_FT
	Wave/Z s_fl = eBin_qxqy_FL
	Wave/Z s_fr = eBin_qxqy_FR
	Wave/Z s_mb = eBin_qxqy_MB
	Wave/Z s_mt = eBin_qxqy_MT
	Wave/Z s_ml = eBin_qxqy_ML
	Wave/Z s_mr = eBin_qxqy_MR
	Wave/Z s_b = eBin_qxqy_B
	
	Concatenate/NP {s_fb,s_ft,s_fl,s_fr,s_mb,s_mt,s_ml,s_mr,s_b}, tmp_s
		
//	Concatenate/NP {$("root:"+folder1+":"+folder1+"_q"),$("root:"+folder2+":"+folder2+"_q")},tmp_q
//	Concatenate/NP {$("root:"+folder1+":"+folder1+"_i"),$("root:"+folder2+":"+folder2+"_i")},tmp_i
//	Concatenate/NP {$("root:"+folder1+":"+folder1+"_s"),$("root:"+folder2+":"+folder2+"_s")},tmp_s
//	Concatenate/NP {$("root:"+folder1+":res0"),$("root:"+folder2+":res0")},tmp_res0
//	Concatenate/NP {$("root:"+folder1+":res1"),$("root:"+folder2+":res1")},tmp_res1
//	Concatenate/NP {$("root:"+folder1+":res2"),$("root:"+folder2+":res2")},tmp_res2
//	Concatenate/NP {$("root:"+folder1+":res3"),$("root:"+folder2+":res3")},tmp_res3
	
//// move the concatenated result into the destination folder (killing the old stuff first)
//	KillWaves/Z $("root:"+folder2+":"+folder2+"_q")
//	KillWaves/Z $("root:"+folder2+":"+folder2+"_i")
//	KillWaves/Z $("root:"+folder2+":"+folder2+"_s")
//	KillWaves/Z $("root:"+folder2+":res0")
//	KillWaves/Z $("root:"+folder2+":res1")
//	KillWaves/Z $("root:"+folder2+":res2")
//	KillWaves/Z $("root:"+folder2+":res3")
	
//	Duplicate/O tmp_q $("root:"+folder2+":"+folder2+"_q")
//	Duplicate/O tmp_i $("root:"+folder2+":"+folder2+"_i")
//	Duplicate/O tmp_s $("root:"+folder2+":"+folder2+"_s")
//	Duplicate/O tmp_res0 $("root:"+folder2+":res0")
//	Duplicate/O tmp_res1 $("root:"+folder2+":res1")
//	Duplicate/O tmp_res2 $("root:"+folder2+":res2")
//	Duplicate/O tmp_res3 $("root:"+folder2+":res3")

//	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_res0,tmp_res1,tmp_res2,tmp_res3	
	
	SetDataFolder root:
	
	return(0)		
End

// TODO:
// -- resolution waves are ignored
// -- only a sort is done, no rescaling of data sets
//    (it's too late now anyways, since the data was concatenated
//
// see Auto_Sort() in the SANS Automation ipf for the rest of the details of
// how to combine the resolution waves (they also need to be concatenated, which is currently not done)
// 
Function V_TmpSort1D(folderStr)
	String folderStr
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
	
//	Sort qw, qw,iw,sw,res0,res1,res2,res3

	Sort qw, qw,iw,sw


	SetDataFolder root:
	return(0)
End


// trims the beamstop out (based on shadow)
// trims num from the highQ end
// splits the res wave into individual waves in anticipation of concatenation
//
Function V_Trim1DData(folderStr,nEnd)
	String folderStr
	Variable nEnd

	if(DataFolderExists("root:"+folderStr)	== 0)
		return(0)
	endif
		
	SetDataFolder $("root:"+folderStr)
	
	Wave qw = $(folderStr + "_q")
	Wave iw = $(folderStr + "_i")
	Wave sw = $(folderStr + "_s")
	Wave res = $(folderStr + "_res")
	
	variable num,ii
	
	num=numpnts(qw)
	//Break out resolution wave into separate waves
	Make/O/D/N=(num) res0 = res[p][0]		// sigQ
	Make/O/D/N=(num) res1 = res[p][1]		// qBar
	Make/O/D/N=(num) res2 = res[p][2]		// fshad
	Make/O/D/N=(num) res3 = res[p][3]		// qvals
	
	// trim off the last nEnd points from everything
	DeletePoints num-nEnd,nEnd, qw,iw,sw,res0,res1,res2,res3
	
	// delete all points where the shadow is < 0.98
	num=numpnts(qw)
	for(ii=0;ii<num;ii+=1)
		if(res2[ii] < 0.98)
			DeletePoints ii,1, qw,iw,sw,res0,res1,res2,res3
			num -= 1
			ii -= 1
		endif
	endfor
	
////Put resolution contents back???
//		reswave[][0] = res0[p]
//		reswave[][1] = res1[p]
//		reswave[][2] = res2[p]
//		reswave[][3] = res3[p]
//		
			
	SetDataFolder root:
	return(0)
end



// TODO:
// -- this is a temporary solution before a real writer is created
// -- resolution is not handled here (and it shouldn't be) since resolution is not known yet.
//
// this will bypass save dialogs
// -- AND WILL OVERWITE DATA WITH THE SAME NAME
//
Function V_Write1DData(folderStr,saveName)
	String folderStr,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
	
	String dataSetFolderParent,basestr
	
	// ParseFilePath to get path without folder name
//	dataSetFolderParent = ParseFilePath(1,folderStr,":",1,0)
	// ParseFilePath to get basestr
//	basestr = ParseFilePath(0,folderStr,":",1,0)
	
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

	PathInfo catPathName
	fullPath = S_Path + saveName

	Open refnum as fullpath

	fprintf refnum,"Combined data written from folder %s on %s\r\n",folderStr,(date()+" "+time())

// TODO -- make this work for 6-columns
//	formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
//	fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"	
//	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs

	//currently, only three columns
	formatStr = "%15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	

	wfprintf refnum,formatStr,qw,iw,sw
	Close refnum
	
//	KillWaves/Z sigQ,qbar,fs
	
	SetDataFolder root:
	return(0)
End