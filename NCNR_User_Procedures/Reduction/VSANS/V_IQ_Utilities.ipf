#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
// Operation does no scaling, only the basic (default) trim of the ends, concatenate, sort, and save
// -- if data has been converted to WORK and hte solid angle correction was done, then the data
//   is per unit solid angle, and matches up - at least the simulated data does...
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


Function V_QBinAllPanels(folderStr,binType)
	String folderStr
	Variable binType

	// do the back, middle, and front separately
	
//	figure out the binning type (where is it set?)
	Variable ii,delQ
	String detStr

//	binType = V_GetBinningPopMode()

//// TODO:
//
//	
	delQ = SetDeltaQ(folderStr,"B")
	
	// dispatch based on binning type
	if(binType == 1 || binType == 2 || binType == 3)
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

// concatenates and sorts the 1D data in "type" WORK folder
// uses the current display if type==""
//
Function V_ConcatenateForSave(type,binType)
	String type
	Variable binType
	
// get the current display type, if null string passed in
	SVAR curtype = root:Packages:NIST:VSANS:Globals:gCurDispType
	
	if(strlen(type)==0)
		type = curType
	endif

// trim the data if needed
	// remove the q=0 point from the back detector, if it's there
	// does not need to know binType
	V_RemoveQ0_B(type)

// concatenate the data sets
// TODO x- figure out which binning was used (this is done in V_1DConcatenate())
	// clear the old tmp waves first, if they still exist
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)
	Killwaves/Z tmp_q,tmp_i,tmp_s
	setDataFolder root:
	V_1DConcatenate(type,binType)
	
// sort the data set
	V_TmpSort1D(type)
	
	return(0)
End

//
// this is only called from the button on the data panel
// so the type is the currently displayed type, and the binning is from the panel
//
Function V_SimpleSave1DData(type,saveName)
	String type,saveName

// 
// get the current display type, if null string passed in
	SVAR curtype = root:Packages:NIST:VSANS:Globals:gCurDispType
	Variable binType = V_GetBinningPopMode()
	
	V_ConcatenateForSave(curType,binType)
	
// write out the data set to a file
	if(strlen(saveName)==0)
		Execute "V_GetNameForSave()"
		SVAR newName = root:saveName
		saveName = newName
	endif
	
	V_Write1DData(type,saveName)

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

	if(qBin[0] == 0)
		DeletePoints 0, 1, qBin,iBin,eBin,nBin,iBin2
	endif
	
	SetDataFolder root:
	return(0)
end


// concatentate data in folderStr
//
// TODO:
// x- this currently ignores the binning type (one, two, etc. )
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
// binType = 1 = one
// binType = 2 = two
// binType = 3 = four
// binType = 4 = Slit Mode
//
// if binType is passed in as -9999, get the binning mode from the popup
// otherwise the value is assumed good (from a protocol)
//
Function V_1DConcatenate(folderStr,binType)
	String folderStr
	Variable binType
	
	if(binType==-9999)
		binType = V_GetBinningPopMode()
	endif	
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	if(binType == 1)	
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
	endif

	if(binType == 2)	
		Wave/Z q_ftb = qBin_qxqy_FTB
		Wave/Z q_flr = qBin_qxqy_FLR
		Wave/Z q_mtb = qBin_qxqy_MTB
		Wave/Z q_mlr = qBin_qxqy_MLR
		Wave/Z q_b = qBin_qxqy_B
	
		Concatenate/NP {q_ftb,q_flr,q_mtb,q_mlr,q_b}, tmp_q
		
		Wave/Z i_ftb = iBin_qxqy_FTB
		Wave/Z i_flr = iBin_qxqy_FLR
		Wave/Z i_mtb = iBin_qxqy_MTB
		Wave/Z i_mlr = iBin_qxqy_MLR
		Wave/Z i_b = iBin_qxqy_B
		
		Concatenate/NP {i_ftb,i_flr,i_mtb,i_mlr,i_b}, tmp_i
	
		Wave/Z s_ftb = eBin_qxqy_FTB
		Wave/Z s_flr = eBin_qxqy_FLR
		Wave/Z s_mtb = eBin_qxqy_MTB
		Wave/Z s_mlr = eBin_qxqy_MLR
		Wave/Z s_b = eBin_qxqy_B
		
		Concatenate/NP {s_ftb,s_flr,s_mtb,s_mlr,s_b}, tmp_s
	endif

	if(binType == 3)	
		Wave/Z q_flrtb = qBin_qxqy_FLRTB
		Wave/Z q_mlrtb = qBin_qxqy_MLRTB
		Wave/Z q_b = qBin_qxqy_B
	
		Concatenate/NP {q_flrtb,q_mlrtb,q_b}, tmp_q
		
		Wave/Z i_flrtb = iBin_qxqy_FLRTB
		Wave/Z i_mlrtb = iBin_qxqy_MLRTB
		Wave/Z i_b = iBin_qxqy_B
		
		Concatenate/NP {i_flrtb,i_mlrtb,i_b}, tmp_i
	
		Wave/Z s_flrtb = eBin_qxqy_FLRTB
		Wave/Z s_mlrtb = eBin_qxqy_MLRTB
		Wave/Z s_b = eBin_qxqy_B
		
		Concatenate/NP {s_flrtb,s_mlrtb,s_b}, tmp_s
	endif

// TODO - This is the identical set of waves as for the case of binType = 1.
// they have the same names, but are averaged differently since it's slit mode.
// I have separated this, since in practice the TB panels are probably best to ignore
// and NOT include in the averaging since the Qy range is so limited.
	if(binType == 4)	
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
	endif




// Can't kill here, since they are still needed to sort and write out!
//	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_res0,tmp_res1,tmp_res2,tmp_res3	
	
	SetDataFolder root:
	
	return(0)		
End

// TODO:
// -- resolution waves are ignored, since they don't exist (yet)
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


// TODO
// -- currently, this function is NOT called by anything
// needs:
// -- trim the beamstop out (based on shadow)
// -- trim out zero q from the file (bad actor in analysis functions)
// -- trim num from the highQ end or lowQ end?
// -- splits the res wave into individual waves in anticipation of concatenation
//   -- or -- deal with the res wave after?
//
//
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