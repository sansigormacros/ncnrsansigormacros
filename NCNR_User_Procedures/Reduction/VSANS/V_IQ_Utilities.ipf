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



Strconstant ksPanelBinTypeList = "B;FT;FB;FL;FR;MT;MB;ML;MR;FTB;FLR;MTB;MLR;FLRTB;MLRTB;"
Strconstant ksBinTrimBegDefault = "B=5;FT=6;FB=6;FL=6;FR=6;MT=6;MB=6;ML=6;MR=6;FTB=7;FLR=7;MTB=7;MLR=7;FLRTB=8;MLRTB=8;"
Strconstant ksBinTrimEndDefault = "B=10;FT=9;FB=9;FL=9;FR=9;MT=9;MB=9;ML=9;MR=9;FTB=8;FLR=8;MTB=8;MLR=8;FLRTB=7;MLRTB=7;"


//////////////////
Strconstant ksBinTypeStr = "One;Two;Four;Slit Mode;"
Strconstant ksBinType1 = "B;FT;FB;FL;FR;MT;MB;ML;MR;"		//these are the "active" extensions
Strconstant ksBinType2 = "B;FTB;FLR;MTB;MLR;"
Strconstant ksBinType3 = "B;FLRTB;MLRTB;"
Strconstant ksBinType4 = "B;FT;FB;FL;FR;MT;MB;ML;MR;"
///////////////////
//
// NOTE
// this is the master conversion function
// ***Use no others
// *** When other bin types are developed, DO NOT reassign these numbers.
//  instead, skip the old numbers and assign new ones.
// old modes can be removed from the string constant ksBinTypeStr (above), but the 
// mode numbers are what many different binning, plotting, and reduction functions are
// switching on. In the future, it may be necessary to change the key (everywhere) to a string
// switch, but for now, stick with the numbers.
Function V_BinTypeStr2Num(binStr)
	String binStr
	
	Variable binType
	strswitch(binStr)	// string switch
		case "One":
			binType = 1
			break		// exit from switch
		case "Two":
			binType = 2
			break		// exit from switch
		case "Four":
			binType = 3
			break		// exit from switch
		case "Slit Mode":
			binType = 4
			break		// exit from switch

		default:			// optional default expression executed
			binType = 0
			Abort "Binning mode not found"// when no case matches
	endswitch	
	return(binType)
end

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
//	Back detector is handled spearately since there is nothing to combine
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
	V_RemoveQ0_B(type)

// concatenate the data sets
// TODO x- figure out which binning was used (this is done in V_1DConcatenate())
	// clear the old tmp waves first, if they still exist
//	SetDataFolder $("root:Packages:NIST:VSANS:"+type)
	SetDataFolder $(pathStr+type)
	Killwaves/Z tmp_q,tmp_i,tmp_s
	setDataFolder root:
	V_1DConcatenate(pathStr,type,tagStr,binType)
	
// sort the data set
	V_TmpSort1D(pathStr,type)
	
	return(0)
End

//
// this is only called from the button on the data panel
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
// binType = 1 = one
// binType = 2 = two
// binType = 3 = four
// binType = 4 = Slit Mode
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
	
//	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)
	SetDataFolder $(pathStr+folderStr)

	//kill these waves before starting, or the new concatenation will be added to the old
	KillWaves/Z tmp_q,tmp_i,tmp_s
	
	String waveListStr=""
	if(binType == 1)
		// q-values
		waveListStr =  "qBin_qxqy_B" + tagStr + ";"
		waveListStr += "qBin_qxqy_MB" + tagStr + ";"
		waveListStr += "qBin_qxqy_MT" + tagStr + ";"
		waveListStr += "qBin_qxqy_ML" + tagStr + ";"
		waveListStr += "qBin_qxqy_MR" + tagStr + ";"
		waveListStr += "qBin_qxqy_FB" + tagStr + ";"
		waveListStr += "qBin_qxqy_FT" + tagStr + ";"
		waveListStr += "qBin_qxqy_FL" + tagStr + ";"
		waveListStr += "qBin_qxqy_FR" + tagStr + ";"

		Concatenate/NP/O waveListStr, tmp_q

		//intensity
		waveListStr =  "iBin_qxqy_B" + tagStr + ";"
		waveListStr += "iBin_qxqy_MB" + tagStr + ";"
		waveListStr += "iBin_qxqy_MT" + tagStr + ";"
		waveListStr += "iBin_qxqy_ML" + tagStr + ";"
		waveListStr += "iBin_qxqy_MR" + tagStr + ";"
		waveListStr += "iBin_qxqy_FB" + tagStr + ";"
		waveListStr += "iBin_qxqy_FT" + tagStr + ";"
		waveListStr += "iBin_qxqy_FL" + tagStr + ";"
		waveListStr += "iBin_qxqy_FR" + tagStr + ";"
//		waveListStr = "iBin_qxqy_B;iBin_qxqy_MB;iBin_qxqy_MT;iBin_qxqy_ML;iBin_qxqy_MR;"
//		waveListStr += "iBin_qxqy_FB;iBin_qxqy_FT;iBin_qxqy_FL;iBin_qxqy_FR;"
		
		Concatenate/NP/O waveListStr, tmp_i

		//error
		waveListStr =  "eBin_qxqy_B" + tagStr + ";"
		waveListStr += "eBin_qxqy_MB" + tagStr + ";"
		waveListStr += "eBin_qxqy_MT" + tagStr + ";"
		waveListStr += "eBin_qxqy_ML" + tagStr + ";"
		waveListStr += "eBin_qxqy_MR" + tagStr + ";"
		waveListStr += "eBin_qxqy_FB" + tagStr + ";"
		waveListStr += "eBin_qxqy_FT" + tagStr + ";"
		waveListStr += "eBin_qxqy_FL" + tagStr + ";"
		waveListStr += "eBin_qxqy_FR" + tagStr + ";"
//		waveListStr = "eBin_qxqy_B;eBin_qxqy_MB;eBin_qxqy_MT;eBin_qxqy_ML;eBin_qxqy_MR;"
//		waveListStr += "eBin_qxqy_FB;eBin_qxqy_FT;eBin_qxqy_FL;eBin_qxqy_FR;"
			
		Concatenate/NP/O waveListStr, tmp_s
	endif

	if(binType == 2)	
		// q-values
		waveListStr =  "qBin_qxqy_B" + tagStr + ";"
		waveListStr += "qBin_qxqy_MTB" + tagStr + ";"
		waveListStr += "qBin_qxqy_MLR" + tagStr + ";"
		waveListStr += "qBin_qxqy_FTB" + tagStr + ";"
		waveListStr += "qBin_qxqy_FLR" + tagStr + ";"

//		waveListStr = "qBin_qxqy_B;qBin_qxqy_MTB;qBin_qxqy_MLR;"
//		waveListStr += "qBin_qxqy_FTB;qBin_qxqy_FLR;"

		Concatenate/NP/O waveListStr, tmp_q

		//intensity
		waveListStr =  "iBin_qxqy_B" + tagStr + ";"
		waveListStr += "iBin_qxqy_MTB" + tagStr + ";"
		waveListStr += "iBin_qxqy_MLR" + tagStr + ";"
		waveListStr += "iBin_qxqy_FTB" + tagStr + ";"
		waveListStr += "iBin_qxqy_FLR" + tagStr + ";"
		
//		waveListStr = "iBin_qxqy_B;iBin_qxqy_MTB;iBin_qxqy_MLR;"
//		waveListStr += "iBin_qxqy_FTB;iBin_qxqy_FLR;"
		
		Concatenate/NP/O waveListStr, tmp_i

		//error
		waveListStr =  "eBin_qxqy_B" + tagStr + ";"
		waveListStr += "eBin_qxqy_MTB" + tagStr + ";"
		waveListStr += "eBin_qxqy_MLR" + tagStr + ";"
		waveListStr += "eBin_qxqy_FTB" + tagStr + ";"
		waveListStr += "eBin_qxqy_FLR" + tagStr + ";"
		
//		waveListStr = "eBin_qxqy_B;eBin_qxqy_MTB;eBin_qxqy_MLR;"
//		waveListStr += "eBin_qxqy_FTB;eBin_qxqy_FLR;"
			
		Concatenate/NP/O waveListStr, tmp_s
	endif

	if(binType == 3)	
		// q-values
		waveListStr =  "qBin_qxqy_B" + tagStr + ";"
		waveListStr += "qBin_qxqy_MLRTB" + tagStr + ";"
		waveListStr += "qBin_qxqy_FLRTB" + tagStr + ";"
		
//		waveListStr = "qBin_qxqy_B;qBin_qxqy_MLRTB;qBin_qxqy_FLRTB;"

		Concatenate/NP/O waveListStr, tmp_q

		//intensity
		waveListStr =  "iBin_qxqy_B" + tagStr + ";"
		waveListStr += "iBin_qxqy_MLRTB" + tagStr + ";"
		waveListStr += "iBin_qxqy_FLRTB" + tagStr + ";"
		
//		waveListStr = "iBin_qxqy_B;iBin_qxqy_MLRTB;iBin_qxqy_FLRTB;"
		
		Concatenate/NP/O waveListStr, tmp_i

		//error
		waveListStr =  "eBin_qxqy_B" + tagStr + ";"
		waveListStr += "eBin_qxqy_MLRTB" + tagStr + ";"
		waveListStr += "eBin_qxqy_FLRTB" + tagStr + ";"
		
//		waveListStr = "eBin_qxqy_B;eBin_qxqy_MLRTB;eBin_qxqy_FLRTB;"
			
		Concatenate/NP/O waveListStr, tmp_s
	endif

// TODO - This is the identical set of waves as for the case of binType = 1.
// they have the same names, but are averaged differently since it's slit mode.
// I have separated this, since in practice the TB panels are probably best to ignore
// and NOT include in the averaging since the Qy range is so limited.
	if(binType == 4)	
		// q-values
		waveListStr =  "qBin_qxqy_B" + tagStr + ";"
		waveListStr += "qBin_qxqy_MB" + tagStr + ";"
		waveListStr += "qBin_qxqy_MT" + tagStr + ";"
		waveListStr += "qBin_qxqy_ML" + tagStr + ";"
		waveListStr += "qBin_qxqy_MR" + tagStr + ";"
		waveListStr += "qBin_qxqy_FB" + tagStr + ";"
		waveListStr += "qBin_qxqy_FT" + tagStr + ";"
		waveListStr += "qBin_qxqy_FL" + tagStr + ";"
		waveListStr += "qBin_qxqy_FR" + tagStr + ";"
//		waveListStr = "qBin_qxqy_B;qBin_qxqy_MB;qBin_qxqy_MT;qBin_qxqy_ML;qBin_qxqy_MR;"
//		waveListStr += "qBin_qxqy_FB;qBin_qxqy_FT;qBin_qxqy_FL;qBin_qxqy_FR;"

		Concatenate/NP/O waveListStr, tmp_q

		//intensity
		waveListStr =  "iBin_qxqy_B" + tagStr + ";"
		waveListStr += "iBin_qxqy_MB" + tagStr + ";"
		waveListStr += "iBin_qxqy_MT" + tagStr + ";"
		waveListStr += "iBin_qxqy_ML" + tagStr + ";"
		waveListStr += "iBin_qxqy_MR" + tagStr + ";"
		waveListStr += "iBin_qxqy_FB" + tagStr + ";"
		waveListStr += "iBin_qxqy_FT" + tagStr + ";"
		waveListStr += "iBin_qxqy_FL" + tagStr + ";"
		waveListStr += "iBin_qxqy_FR" + tagStr + ";"
//		waveListStr = "iBin_qxqy_B;iBin_qxqy_MB;iBin_qxqy_MT;iBin_qxqy_ML;iBin_qxqy_MR;"
//		waveListStr += "iBin_qxqy_FB;iBin_qxqy_FT;iBin_qxqy_FL;iBin_qxqy_FR;"
		
		Concatenate/NP/O waveListStr, tmp_i

		//error
		waveListStr =  "eBin_qxqy_B" + tagStr + ";"
		waveListStr += "eBin_qxqy_MB" + tagStr + ";"
		waveListStr += "eBin_qxqy_MT" + tagStr + ";"
		waveListStr += "eBin_qxqy_ML" + tagStr + ";"
		waveListStr += "eBin_qxqy_MR" + tagStr + ";"
		waveListStr += "eBin_qxqy_FB" + tagStr + ";"
		waveListStr += "eBin_qxqy_FT" + tagStr + ";"
		waveListStr += "eBin_qxqy_FL" + tagStr + ";"
		waveListStr += "eBin_qxqy_FR" + tagStr + ";"
//		waveListStr = "eBin_qxqy_B;eBin_qxqy_MB;eBin_qxqy_MT;eBin_qxqy_ML;eBin_qxqy_MR;"
//		waveListStr += "eBin_qxqy_FB;eBin_qxqy_FT;eBin_qxqy_FL;eBin_qxqy_FR;"
			
		Concatenate/NP/O waveListStr, tmp_s
	endif

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
	
//	Sort qw, qw,iw,sw,res0,res1,res2,res3

	Sort qw, qw,iw,sw


	SetDataFolder root:
	return(0)
End


// TODO
// (appears to be unused, in favor of the version that uses the global strings)
// needs:
// -- trim the beamstop out (based on shadow?)
// -- trim out zero q from the file (bad actor in analysis functions)
// -- trim num from the highQ end or lowQ end?
// -- splits the res wave into individual waves in anticipation of concatenation
//   -- or -- deal with the res wave after?
//
// -- make a copy of the waves?
// -- then, what is the concatenate function looking for??
//
Function V_Trim1DData(dataFolder,binType,nBeg,nEnd)
	String dataFolder
	Variable binType,nBeg,nEnd

	Variable npt,ii
   SetDataFolder $("root:Packages:NIST:VSANS:"+dataFolder)

	Printf "%d points removed from beginning, %d points from the end (of each set) before concatenating\r",nbeg,nend
	
// for each binType block:
// declare the waves
// make a copy of the waves??
//	//Break out resolution wave into separate waves
// delete the beginning points from everything
	// trim off the last nEnd points from everything
//	DeletePoints num-nEnd,nEnd, qw,iw,sw
//	// delete all points where the shadow is < 0.98
////Put resolution contents back???

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
	
		Wave/Z i_fb = iBin_qxqy_FB
		Wave/Z i_ft = iBin_qxqy_FT
		Wave/Z i_fl = iBin_qxqy_FL
		Wave/Z i_fr = iBin_qxqy_FR
		Wave/Z i_mb = iBin_qxqy_MB
		Wave/Z i_mt = iBin_qxqy_MT
		Wave/Z i_ml = iBin_qxqy_ML
		Wave/Z i_mr = iBin_qxqy_MR
		Wave/Z i_b = iBin_qxqy_B
		
		Wave/Z s_fb = eBin_qxqy_FB
		Wave/Z s_ft = eBin_qxqy_FT
		Wave/Z s_fl = eBin_qxqy_FL
		Wave/Z s_fr = eBin_qxqy_FR
		Wave/Z s_mb = eBin_qxqy_MB
		Wave/Z s_mt = eBin_qxqy_MT
		Wave/Z s_ml = eBin_qxqy_ML
		Wave/Z s_mr = eBin_qxqy_MR
		Wave/Z s_b = eBin_qxqy_B


				
		DeletePoints 0,nBeg, q_fb,q_ft,q_fl,q_fr,q_mb,q_mt,q_ml,q_mr,q_b
		DeletePoints 0,nBeg, i_fb,i_ft,i_fl,i_fr,i_mb,i_mt,i_ml,i_mr,i_b
		DeletePoints 0,nBeg, s_fb,s_ft,s_fl,s_fr,s_mb,s_mt,s_ml,s_mr,s_b
		//since each set may have a different number of points
		npt = numpnts(q_fb) 
		DeletePoints npt-nEnd,nEnd, q_fb,i_fb,s_fb

		npt = numpnts(q_ft) 
		DeletePoints npt-nEnd,nEnd, q_ft,i_ft,s_ft

		npt = numpnts(q_fl) 
		DeletePoints npt-nEnd,nEnd, q_fl,i_fl,s_fl

		npt = numpnts(q_fr) 
		DeletePoints npt-nEnd,nEnd, q_fr,i_fr,s_fr

		npt = numpnts(q_mb) 
		DeletePoints npt-nEnd,nEnd, q_mb,i_mb,s_mb

		npt = numpnts(q_mt) 
		DeletePoints npt-nEnd,nEnd, q_mt,i_mt,s_mt

		npt = numpnts(q_ml) 
		DeletePoints npt-nEnd,nEnd, q_ml,i_ml,s_ml

		npt = numpnts(q_mr) 
		DeletePoints npt-nEnd,nEnd, q_mr,i_mr,s_mr

		npt = numpnts(q_b) 
		DeletePoints npt-nEnd,nEnd, q_b,i_b,s_b
		
	endif

	if(binType == 2)	
		Wave/Z q_ftb = qBin_qxqy_FTB
		Wave/Z q_flr = qBin_qxqy_FLR
		Wave/Z q_mtb = qBin_qxqy_MTB
		Wave/Z q_mlr = qBin_qxqy_MLR
		Wave/Z q_b = qBin_qxqy_B
		
		Wave/Z i_ftb = iBin_qxqy_FTB
		Wave/Z i_flr = iBin_qxqy_FLR
		Wave/Z i_mtb = iBin_qxqy_MTB
		Wave/Z i_mlr = iBin_qxqy_MLR
		Wave/Z i_b = iBin_qxqy_B
				
		Wave/Z s_ftb = eBin_qxqy_FTB
		Wave/Z s_flr = eBin_qxqy_FLR
		Wave/Z s_mtb = eBin_qxqy_MTB
		Wave/Z s_mlr = eBin_qxqy_MLR
		Wave/Z s_b = eBin_qxqy_B
		

		DeletePoints 0,nBeg, q_ftb,q_flr,q_mtb,q_mlr,q_b
		DeletePoints 0,nBeg, i_ftb,i_flr,i_mtb,i_mlr,i_b
		DeletePoints 0,nBeg, s_ftb,s_flr,s_mtb,s_mlr,s_b
		//since each set may have a different number of points
		npt = numpnts(q_ftb) 
		DeletePoints npt-nEnd,nEnd, q_ftb,i_ftb,s_ftb		
		
		npt = numpnts(q_flr) 
		DeletePoints npt-nEnd,nEnd, q_flr,i_flr,s_flr		
		
		npt = numpnts(q_mtb) 
		DeletePoints npt-nEnd,nEnd, q_mtb,i_mtb,s_mtb		
		
		npt = numpnts(q_mlr) 
		DeletePoints npt-nEnd,nEnd, q_mlr,i_mlr,s_mlr		
		
		npt = numpnts(q_b) 
		DeletePoints npt-nEnd,nEnd, q_b,i_b,s_b		
		

	endif

	if(binType == 3)	
		Wave/Z q_flrtb = qBin_qxqy_FLRTB
		Wave/Z q_mlrtb = qBin_qxqy_MLRTB
		Wave/Z q_b = qBin_qxqy_B
		
		Wave/Z i_flrtb = iBin_qxqy_FLRTB
		Wave/Z i_mlrtb = iBin_qxqy_MLRTB
		Wave/Z i_b = iBin_qxqy_B	
		
		Wave/Z s_flrtb = eBin_qxqy_FLRTB
		Wave/Z s_mlrtb = eBin_qxqy_MLRTB
		Wave/Z s_b = eBin_qxqy_B
		
		DeletePoints 0,nBeg, q_flrtb,q_mlrtb,q_b
		DeletePoints 0,nBeg, i_flrtb,i_mlrtb,i_b
		DeletePoints 0,nBeg, s_flrtb,s_mlrtb,s_b
		//since each set may have a different number of points
		npt = numpnts(q_flrtb) 
		DeletePoints npt-nEnd,nEnd, q_flrtb,i_flrtb,s_flrtb		
		
		npt = numpnts(q_mlrtb) 
		DeletePoints npt-nEnd,nEnd, q_mlrtb,i_mlrtb,s_mlrtb		
		
		npt = numpnts(q_b) 
		DeletePoints npt-nEnd,nEnd, q_b,i_b,s_b		

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
	
		Wave/Z i_fb = iBin_qxqy_FB
		Wave/Z i_ft = iBin_qxqy_FT
		Wave/Z i_fl = iBin_qxqy_FL
		Wave/Z i_fr = iBin_qxqy_FR
		Wave/Z i_mb = iBin_qxqy_MB
		Wave/Z i_mt = iBin_qxqy_MT
		Wave/Z i_ml = iBin_qxqy_ML
		Wave/Z i_mr = iBin_qxqy_MR
		Wave/Z i_b = iBin_qxqy_B
		
		Wave/Z s_fb = eBin_qxqy_FB
		Wave/Z s_ft = eBin_qxqy_FT
		Wave/Z s_fl = eBin_qxqy_FL
		Wave/Z s_fr = eBin_qxqy_FR
		Wave/Z s_mb = eBin_qxqy_MB
		Wave/Z s_mt = eBin_qxqy_MT
		Wave/Z s_ml = eBin_qxqy_ML
		Wave/Z s_mr = eBin_qxqy_MR
		Wave/Z s_b = eBin_qxqy_B
				
		DeletePoints 0,nBeg, q_fb,q_ft,q_fl,q_fr,q_mb,q_mt,q_ml,q_mr,q_b
		DeletePoints 0,nBeg, i_fb,i_ft,i_fl,i_fr,i_mb,i_mt,i_ml,i_mr,i_b
		DeletePoints 0,nBeg, s_fb,s_ft,s_fl,s_fr,s_mb,s_mt,s_ml,s_mr,s_b
		//since each set may have a different number of points
		npt = numpnts(q_fb) 
		DeletePoints npt-nEnd,nEnd, q_fb,i_fb,s_fb

		npt = numpnts(q_ft) 
		DeletePoints npt-nEnd,nEnd, q_ft,i_ft,s_ft

		npt = numpnts(q_fl) 
		DeletePoints npt-nEnd,nEnd, q_fl,i_fl,s_fl

		npt = numpnts(q_fr) 
		DeletePoints npt-nEnd,nEnd, q_fr,i_fr,s_fr

		npt = numpnts(q_mb) 
		DeletePoints npt-nEnd,nEnd, q_mb,i_mb,s_mb

		npt = numpnts(q_mt) 
		DeletePoints npt-nEnd,nEnd, q_mt,i_mt,s_mt

		npt = numpnts(q_ml) 
		DeletePoints npt-nEnd,nEnd, q_ml,i_ml,s_ml

		npt = numpnts(q_mr) 
		DeletePoints npt-nEnd,nEnd, q_mr,i_mr,s_mr

		npt = numpnts(q_b) 
		DeletePoints npt-nEnd,nEnd, q_b,i_b,s_b
		
	endif
			
	SetDataFolder root:
	return(0)
end



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

// TODO -- make this work for 6-columns (or??)
//	formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
//	fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"	
//	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs

	//currently, only three columns
	formatStr = "%15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm)\r\n"	

	wfprintf refnum,formatStr,qw,iw,sw
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


// given strings of the number of points to remove, loop over the detectors
//
// TODO
// -- currently uses global strings or default strings
// -- if proper strings (non-null) are passed in, they are used, otherwise global, then default
Function V_Trim1DDataStr(folderStr,binType,nBegStr,nEndStr)
	String folderStr
	Variable binType
	String nBegStr,nEndStr
	
	String detListStr
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
	
	num = ItemsInList(detListStr)
	for(ii=0;ii<num;ii+=1)
		detStr = StringFromList(ii, detListStr)
		nBeg = NumberByKey(detStr, nBegStr,"=",";")
		nEnd = NumberByKey(detStr, nEndStr,"=",";")
		V_TrimOneSet(folderStr,detStr,nBeg,nEnd)
	endfor

	return(0)
End

// TODO
// -- make this resolution-aware
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

			
		DeletePoints 0,nBeg, qw,iw,ew

		Variable npt
		npt = numpnts(qw) 
		DeletePoints npt-nEnd,nEnd, qw,iw,ew
	
	return(0)
End