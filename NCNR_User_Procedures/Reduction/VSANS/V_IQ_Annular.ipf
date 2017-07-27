#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Procedures to do an annular binning of the data
//
// As for SANS, needs a Q-center and Q-delta to define the annular ring,
// and the number of bins to divide the 360 degree circle
//
//
//
// TODO
// x- add error bars to the plot of phi
// x- data writer to export annular data (3-column)
// x- loader to re-read annular data (will the normal loader work?) -- yes
// -- integrate this with the protocol
// -- integrate this with a more general "average panel"
// -- draw the q-center and width on the image (as a contour? - if no, use a draw layer...)
//    Can I "flag" the pixels that contribute to the annualr average, and overlay them like a 
//    Mask(translucent?), like a "thresholding" operation, but act on the Q-value, not the Z- value.

//
//
Proc Annular_Binning(folderStr,detGroup,qCtr_Ann,qWidth)
	String folderStr="SAM",detGroup="F"
	Variable qCtr_Ann=0.1,qWidth=0.01  	// +/- in A^-1
	
	V_QBinAllPanels_Annular(folderStr,detGroup,qCtr_Ann,qWidth)

	V_Phi_Graph_Proc(folderStr,detGroup)

End


// TODO -- binType == 4 (slit mode) should never end up here, as it makes no sense
//
// -- really, the onle binning that makes any sense is "one", treating each panel individually,
// so I may scrap the parameter, or ignore it. so don't count on it in the future.
//
Function V_QBinAllPanels_Annular(folderStr,detGroup,qCtr_Ann,qWidth)
	String folderStr,detGroup
	Variable qCtr_Ann,qWidth  	// +/- in A^-1

	Variable ii,delQ
	String detStr
	
	if(cmpstr(detGroup,"F") == 0)
		detStr = "FLRTB"
	else
		detStr = "MLRTB"
	endif
	
// right now, use all of the detectors. There is a lot of waste in this and it could be 
// done a lot faster, but...

// TODO		
		// detStr = "FLRTB" or "MLRTB", depending which panel the q-ring is centered on/
		// for now, no crossing of the rings onto different panels
		
	V_fDoAnnularBin_QxQy2D(folderStr,detStr,qCtr_Ann,qWidth)


	return(0)
End

Proc V_Phi_Graph_Proc(folderStr,detGroup)
	String folderStr,detGroup
	
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	DoWindow/F V_Phi_Graph
	if(V_flag == 0)
		Display /W=(35,45,572,419)/N=V_Phi_Graph /K=1
	else
		RemoveFromGraph/Z iPhiBin_qxqy_FLRTB
		RemoveFromGraph/Z iPhiBin_qxqy_MLRTB
	endif

	if(cmpstr(detGroup,"F") == 0)
		AppendToGraph iPhiBin_qxqy_FLRTB vs phiBin_qxqy_FLRTB
//		Display /W=(35,45,572,419)/N=V_Phi_Graph /K=1 iPhiBin_qxqy_FLRTB vs phiBin_qxqy_FLRTB
		ModifyGraph mode=4
		ModifyGraph marker=19
		ErrorBars iPhiBin_qxqy_FLRTB Y,wave=(ePhiBin_qxqy_FLRTB,ePhiBin_qxqy_FLRTB)
		Label left "Counts"
		Label bottom "Phi (degrees)"
		Legend
	else
		AppendToGraph iPhiBin_qxqy_MLRTB vs phiBin_qxqy_MLRTB
		ModifyGraph mode=4
		ModifyGraph marker=19
		ErrorBars iPhiBin_qxqy_MLRTB Y,wave=(ePhiBin_qxqy_MLRTB,ePhiBin_qxqy_MLRTB)
		Label left "Counts"
		Label bottom "Phi (degrees)"
		Legend
	endif

	
	SetDataFolder fldrSav0
EndMacro


//////////
//
//
//
// TODO 
// -- "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
// ** Currently, type is being passed in as "" and ignored (looping through all of the detector panels
// to potentially add to the annular bins)
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
//
//	Variable qCtr_Ann = 0.1
//	Variable qWidth = 0.02		// +/- in A^-1
//
Function V_fDoAnnularBin_QxQy2D(folderStr,type,qCtr_Ann,qWidth)
	String folderStr,type
	Variable qCtr_Ann,qWidth
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj
	Variable qVal,nq,var,avesq,aveisq
	Variable binIndex,val,isVCALC=0,maskMissing

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"
	String detStr
		
	if(cmpstr(folderStr,"VCALC") == 0)
		isVCALC = 1
	endif
	
// now switch on the type to determine which waves to declare and create
// since there may be more than one panel to step through. There may be two, there may be four
//

// TODO:
// -- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
//
// assume that the mask files are missing unless we can find them. If VCALC data, 
//  then the Mask is missing by definition
	maskMissing = 1

	strswitch(type)	// string switch

		
		case "FLRTB":
			if(isVCALC)
				WAVE inten = $(folderPath+instPath+"FL"+":det_"+"FL")
				WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation		
				WAVE inten2 = $(folderPath+instPath+"FR"+":det_"+"FR")
				WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation	
				WAVE inten3 = $(folderPath+instPath+"FT"+":det_"+"FT")
				WAVE/Z iErr3 = $("iErr_"+"FT")			// 2D errors -- may not exist, especially for simulation		
				WAVE inten4 = $(folderPath+instPath+"FB"+":det_"+"FB")
				WAVE/Z iErr4 = $("iErr_"+"FB")			// 2D errors -- may not exist, especially for simulation	
			else
				Wave inten = V_getDetectorDataW(folderStr,"FL")
				Wave iErr = V_getDetectorDataErrW(folderStr,"FL")
				Wave inten2 = V_getDetectorDataW(folderStr,"FR")
				Wave iErr2 = V_getDetectorDataErrW(folderStr,"FR")
				Wave inten3 = V_getDetectorDataW(folderStr,"FT")
				Wave iErr3 = V_getDetectorDataErrW(folderStr,"FT")
				Wave inten4 = V_getDetectorDataW(folderStr,"FB")
				Wave iErr4 = V_getDetectorDataErrW(folderStr,"FB")
				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FL"+":data")
				Wave/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FR"+":data")
				Wave/Z mask3 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FT"+":data")
				Wave/Z mask4 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FB"+":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
					maskMissing = 0
				endif
			endif	
//			NVAR delQ = $(folderPath+instPath+"FL"+":gDelQ_FL")
			
			Wave qTotal = $(folderPath+instPath+"FL"+":qTot_"+"FL")			// 2D q-values	
			Wave qTotal2 = $(folderPath+instPath+"FR"+":qTot_"+"FR")			// 2D q-values	
			Wave qTotal3 = $(folderPath+instPath+"FT"+":qTot_"+"FT")			// 2D q-values	
			Wave qTotal4 = $(folderPath+instPath+"FB"+":qTot_"+"FB")			// 2D q-values	

			Wave qx = $(folderPath+instPath+"FL"+":qx_"+"FL")			// 2D qx-values	
			Wave qx2 = $(folderPath+instPath+"FR"+":qx_"+"FR")			// 2D qx-values	
			Wave qx3 = $(folderPath+instPath+"FT"+":qx_"+"FT")			// 2D qx-values	
			Wave qx4 = $(folderPath+instPath+"FB"+":qx_"+"FB")			// 2D qx-values	

			Wave qy = $(folderPath+instPath+"FL"+":qy_"+"FL")			// 2D qy-values	
			Wave qy2 = $(folderPath+instPath+"FR"+":qy_"+"FR")			// 2D qy-values	
			Wave qy3 = $(folderPath+instPath+"FT"+":qy_"+"FT")			// 2D qy-values	
			Wave qy4 = $(folderPath+instPath+"FB"+":qy_"+"FB")			// 2D qy-values	
								
			nSets = 4
			break		
			
	
		
		case "MLRTB":
			if(isVCALC)
				WAVE inten = $(folderPath+instPath+"ML"+":det_"+"ML")
				WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation		
				WAVE inten2 = $(folderPath+instPath+"MR"+":det_"+"MR")
				WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation	
				WAVE inten3 = $(folderPath+instPath+"MT"+":det_"+"MT")
				WAVE/Z iErr3 = $("iErr_"+"MT")			// 2D errors -- may not exist, especially for simulation		
				WAVE inten4 = $(folderPath+instPath+"MB"+":det_"+"MB")
				WAVE/Z iErr4 = $("iErr_"+"MB")			// 2D errors -- may not exist, especially for simulation	
			else
				Wave inten = V_getDetectorDataW(folderStr,"ML")
				Wave iErr = V_getDetectorDataErrW(folderStr,"ML")
				Wave inten2 = V_getDetectorDataW(folderStr,"MR")
				Wave iErr2 = V_getDetectorDataErrW(folderStr,"MR")
				Wave inten3 = V_getDetectorDataW(folderStr,"MT")
				Wave iErr3 = V_getDetectorDataErrW(folderStr,"MT")
				Wave inten4 = V_getDetectorDataW(folderStr,"MB")
				Wave iErr4 = V_getDetectorDataErrW(folderStr,"MB")
				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"ML"+":data")
				Wave/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"MR"+":data")
				Wave/Z mask3 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"MT"+":data")
				Wave/Z mask4 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"MB"+":data")
				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1 && WaveExists(mask3) == 1 && WaveExists(mask4) == 1)
					maskMissing = 0
				endif
			endif	
//			NVAR delQ = $(folderPath+instPath+"ML"+":gDelQ_ML")
			
			Wave qTotal = $(folderPath+instPath+"ML"+":qTot_"+"ML")			// 2D q-values	
			Wave qTotal2 = $(folderPath+instPath+"MR"+":qTot_"+"MR")			// 2D q-values	
			Wave qTotal3 = $(folderPath+instPath+"MT"+":qTot_"+"MT")			// 2D q-values	
			Wave qTotal4 = $(folderPath+instPath+"MB"+":qTot_"+"MB")			// 2D q-values	

			Wave qx = $(folderPath+instPath+"ML"+":qx_"+"ML")			// 2D qx-values	
			Wave qx2 = $(folderPath+instPath+"MR"+":qx_"+"MR")			// 2D qx-values	
			Wave qx3 = $(folderPath+instPath+"MT"+":qx_"+"MT")			// 2D qx-values	
			Wave qx4 = $(folderPath+instPath+"MB"+":qx_"+"MB")			// 2D qx-values	

			Wave qy = $(folderPath+instPath+"ML"+":qy_"+"ML")			// 2D qy-values	
			Wave qy2 = $(folderPath+instPath+"MR"+":qy_"+"MR")			// 2D qy-values	
			Wave qy3 = $(folderPath+instPath+"MT"+":qy_"+"MT")			// 2D qy-values	
			Wave qy4 = $(folderPath+instPath+"MB"+":qy_"+"MB")			// 2D qy-values	
					
			nSets = 4
			break									
					
		default:
			nSets = 0							// optional default expression executed
			Print "ERROR   ---- type is not recognized "
	endswitch

//	Print "delQ = ",delQ," for ",type

	if(nSets == 0)
		SetDataFolder root:
		return(0)
	endif


//TODO: properly define the 2D errors here - I'll have this if I do the simulation
// -- need to propagate the 2D errors up to this point
//
	if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr2)==0 && WaveExists(inten2) != 0)
		Duplicate/O inten2,iErr2
		Wave iErr2=iErr2
//		iErr2 = 1+sqrt(inten2+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr2 = sqrt(inten2+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr3)==0  && WaveExists(inten3) != 0)
		Duplicate/O inten3,iErr3
		Wave iErr3=iErr3
//		iErr3 = 1+sqrt(inten3+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr3 = sqrt(inten3+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr4)==0  && WaveExists(inten4) != 0)
		Duplicate/O inten4,iErr4
		Wave iErr4=iErr4
//		iErr4 = 1+sqrt(inten4+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr4 = sqrt(inten4+0.75)			// TODO -- here I'm just using some fictional value
	endif

	// TODO -- nq will need to be larger, once the back detector is installed
	//
	// note that the back panel of 320x320 (1mm res) results in 447 data points!
	// - so I upped nq to 600

	nq = 600

//******TODO****** -- where to put the averaged data -- right now, folderStr is forced to ""	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $(folderPath+":"+"iPhiBin_qxqy"+"_"+type)
//	Make/O/D/N=(nq)  $(folderPath+":"+"qBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"phiBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"nPhiBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"iPhiBin2_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"ePhiBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"ePhiBin2D_qxqy"+"_"+type)
	
	Wave iPhiBin_qxqy = $(folderPath+":"+"iPhiBin_qxqy_"+type)
//	Wave qBin_qxqy = $(folderPath+":"+"qBin_qxqy"+"_"+type)
	Wave phiBin_qxqy = $(folderPath+":"+"phiBin_qxqy"+"_"+type)
	Wave nPhiBin_qxqy = $(folderPath+":"+"nPhiBin_qxqy"+"_"+type)
	Wave iPhiBin2_qxqy = $(folderPath+":"+"iPhiBin2_qxqy"+"_"+type)
	Wave ePhiBin_qxqy = $(folderPath+":"+"ePhiBin_qxqy"+"_"+type)
	Wave ePhiBin2D_qxqy = $(folderPath+":"+"ePhiBin2D_qxqy"+"_"+type)
	
	
// TODO:
// -- get the q-binning values from the VSANS equivalent
//	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr	
//	Variable qc = NumberByKey("QCENTER",keyListStr,"=",";")		// q-center
//	Variable nw = NumberByKey("QDELTA",keyListStr,"=",";")		// (in SANS - number of pixels wide)


	Variable nphi,dphi,isIn,phiij,iphi

// TODO: define nphi
//	dr = 1 			//minimum annulus width, keep this fixed at one
	NVAR numPhiSteps = root:Packages:NIST:VSANS:Globals:gNPhiSteps
	nphi = numPhiSteps		//number of anular sectors is set by users
	dphi = 360/nphi
	

	iPhiBin_qxqy = 0
	iPhiBin2_qxqy = 0
	ePhiBin_qxqy = 0
	ePhiBin2D_qxqy = 0
	nPhiBin_qxqy = 0	//number of intensities added to each bin


// 4 panels	 is currently the only situation
//
// this needs to be a double loop now...
// TODO:
// -- the iErr (=2D) wave and accumulation of error is NOT CALCULATED CORRECTLY YET
// -- the solid angle per pixel is not completely implemented.
//    it will be present for WORK data other than RAW, but not for RAW

// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
	if(maskMissing == 1)
		Print "Mask file not found for at least one detector - so all data is used"
	endif

	Variable mask_val
// use set 1 (no number) only
	if(nSets >= 1)
		xDim=DimSize(inten,0)
		yDim=DimSize(inten,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal[ii][jj]
				
				isIn = V_CloseEnough(qVal,qCtr_Ann,qWidth)
				
				if(isIn)		// it's in the annulus somewhere, do something
					// now I need the qx and qy to find phi
					if (qy[ii][jj] >= 0)
						//phiij is in degrees
						phiij = atan2(qy[ii][jj],qx[ii][jj])*180/Pi		//0 to 180 deg
					else
						phiij = 360 + atan2(qy[ii][jj],qx[ii][jj])*180/Pi		//180 to 360 deg
					Endif
					if (phiij > (360-0.5*dphi))
						phiij -= 360
					Endif
					iphi = trunc(phiij/dphi + 1.501)			// TODO: why the value of 1.501????
							
					val = inten[ii][jj]
					
					if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
						mask_val = 0
					else
						mask_val = mask[ii][jj]
					endif
					if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
						iPhiBin_qxqy[iphi-1] += val
						iPhiBin2_qxqy[iphi-1] += val*val
						ePhiBin2D_qxqy[iphi-1] += iErr[ii][jj]*iErr[ii][jj]
						nPhiBin_qxqy[iphi-1] += 1
					endif
				
				endif // isIn
				
			endfor
		endfor
		
	endif

// add in set 2 (set 1 already done)
	if(nSets >= 2)
		xDim=DimSize(inten2,0)
		yDim=DimSize(inten2,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal2[ii][jj]
				
				isIn = V_CloseEnough(qVal,qCtr_Ann,qWidth)
				
				if(isIn)		// it's in the annulus somewhere, do something
					// now I need the qx and qy to find phi
					if (qy2[ii][jj] >= 0)
						//phiij is in degrees
						phiij = atan2(qy2[ii][jj],qx2[ii][jj])*180/Pi		//0 to 180 deg
					else
						phiij = 360 + atan2(qy2[ii][jj],qx2[ii][jj])*180/Pi		//180 to 360 deg
					Endif
					if (phiij > (360-0.5*dphi))
						phiij -= 360
					Endif
					iphi = trunc(phiij/dphi + 1.501)			// TODO: why the value of 1.501????
							
					val = inten2[ii][jj]
					
					if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
						mask_val = 0
					else
						mask_val = mask2[ii][jj]
					endif
					if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
						iPhiBin_qxqy[iphi-1] += val
						iPhiBin2_qxqy[iphi-1] += val*val
						ePhiBin2D_qxqy[iphi-1] += iErr2[ii][jj]*iErr2[ii][jj]
						nPhiBin_qxqy[iphi-1] += 1
					endif
				
				endif // isIn

			endfor		//jj
		endfor		//ii
		
	endif		// set 2


// add in set 3 and 4 (set 1 and 2 already done)
	if(nSets == 4)
		xDim=DimSize(inten3,0)
		yDim=DimSize(inten3,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal3[ii][jj]
				
				isIn = V_CloseEnough(qVal,qCtr_Ann,qWidth)
				
				if(isIn)		// it's in the annulus somewhere, do something
					// now I need the qx and qy to find phi
					if (qy3[ii][jj] >= 0)
						//phiij is in degrees
						phiij = atan2(qy3[ii][jj],qx3[ii][jj])*180/Pi		//0 to 180 deg
					else
						phiij = 360 + atan2(qy3[ii][jj],qx3[ii][jj])*180/Pi		//180 to 360 deg
					Endif
					if (phiij > (360-0.5*dphi))
						phiij -= 360
					Endif
					iphi = trunc(phiij/dphi + 1.501)			// TODO: why the value of 1.501????
							
					val = inten3[ii][jj]
					
					if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
						mask_val = 0
					else
						mask_val = mask3[ii][jj]
					endif
					if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
						iPhiBin_qxqy[iphi-1] += val
						iPhiBin2_qxqy[iphi-1] += val*val
						ePhiBin2D_qxqy[iphi-1] += iErr3[ii][jj]*iErr3[ii][jj]
						nPhiBin_qxqy[iphi-1] += 1
					endif
				
				endif // isIn
				
			
			endfor
		endfor		// end of ij loop over set 3
		
		
		xDim=DimSize(inten4,0)
		yDim=DimSize(inten4,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal4[ii][jj]
				
				isIn = V_CloseEnough(qVal,qCtr_Ann,qWidth)
				
				if(isIn)		// it's in the annulus somewhere, do something
					// now I need the qx and qy to find phi
					if (qy4[ii][jj] >= 0)
						//phiij is in degrees
						phiij = atan2(qy4[ii][jj],qx4[ii][jj])*180/Pi		//0 to 180 deg
					else
						phiij = 360 + atan2(qy4[ii][jj],qx4[ii][jj])*180/Pi		//180 to 360 deg
					Endif
					if (phiij > (360-0.5*dphi))
						phiij -= 360
					Endif
					iphi = trunc(phiij/dphi + 1.501)			// TODO: why the value of 1.501????
							
					val = inten4[ii][jj]
					
					if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
						mask_val = 0
					else
						mask_val = mask4[ii][jj]
					endif
					if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
						iPhiBin_qxqy[iphi-1] += val
						iPhiBin2_qxqy[iphi-1] += val*val
						ePhiBin2D_qxqy[iphi-1] += iErr4[ii][jj]*iErr4[ii][jj]
						nPhiBin_qxqy[iphi-1] += 1
					endif
				
				endif // isIn				
				
				
			endfor
		endfor		// end ij loop over set 4
		
	endif	// adding sets 3 and 4


// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf
// TODO:
// -- 2D Errors were NOT properly acculumated through reduction, so this loop of calculations is NOT MEANINGFUL (yet)
// x- the error on the 1D intensity, is correctly calculated as the standard error of the mean.
	for(ii=0;ii<nphi;ii+=1)
	
		phiBin_qxqy[ii] = dphi*ii
		
		if(nPhiBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iPhiBin_qxqy[ii] = 0
			ePhiBin_qxqy[ii] = 1
			ePhiBin2D_qxqy[ii] = NaN
		else
			if(nPhiBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iPhiBin_qxqy[ii] /= nPhiBin_qxqy[ii]
				ePhiBin_qxqy[ii] = 1
				ePhiBin2D_qxqy[ii] /= (nPhiBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				//  -- this is correctly calculating the error as the standard error of the mean, as
				//    was always done for SANS as well.
				iPhiBin_qxqy[ii] /= nPhiBin_qxqy[ii]
				avesq = iPhiBin_qxqy[ii]^2
				aveisq = iPhiBin2_qxqy[ii]/nPhiBin_qxqy[ii]
				var = aveisq-avesq
				if(var<=0)
					ePhiBin_qxqy[ii] = 1e-6
				else
					ePhiBin_qxqy[ii] = sqrt(var/(nPhiBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				ePhiBin2D_qxqy[ii] /= (nPhiBin_qxqy[ii])^2
			endif
		endif
	endfor
	
	ePhiBin2D_qxqy = sqrt(ePhiBin2D_qxqy)		// as equation (3) of John's memo
	
	// find the last non-zero point, working backwards
	val=nq
	do
		val -= 1
	while((nPhiBin_qxqy[val] == 0) && val > 0)
	
//	print val, nPhiBin_qxqy[val]
	DeletePoints val, nq-val, iPhiBin_qxqy,phiBin_qxqy,nPhiBin_qxqy,iPhiBin2_qxqy,ePhiBin_qxqy,ePhiBin2D_qxqy

	if(val == 0)
		// all the points were deleted
		return(0)
	endif
	
	
	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nPhiBin_qxqy[val] == 0)	
	DeletePoints 0, val, iPhiBin_qxqy,phiBin_qxqy,nPhiBin_qxqy,iPhiBin2_qxqy,ePhiBin_qxqy,ePhiBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nPhiBin_qxqy)-1
	do
		if(nPhiBin_qxqy[val] == 0)
			DeletePoints val, 1, iPhiBin_qxqy,phiBin_qxqy,nPhiBin_qxqy,iPhiBin2_qxqy,ePhiBin_qxqy,ePhiBin2D_qxqy
		endif
		val -= 1
	while(val>0)
	
	// TODO:
	// -- is this where I do the resolution calculation? This is where I calculate the resolution in SANS (see CircSectAve)
	// -- or do I do it as a separate call?
	// -- use the isVCALC flag to exclude VCALC from the resolution calculation if necessary
	//
	
	SetDataFolder root:
	
	return(0)
End


Proc V_Write1DAnnular(pathStr,folderStr,detGroup,saveName)
	String pathStr="root:Packages:NIST:VSANS:"
	String folderStr="SAM"
	String detGroup = "F"
	String saveName = "Annular_Data.dat"
	
	
	V_fWrite1DAnnular(pathStr,folderStr,detGroup,saveName)
	
end

// TODO:
// -- this is a temporary solution before a real writer is created
// -- resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// -- but a real writer will need to be aware of resolution, and there may be different forms
//
// this will bypass save dialogs
// -- AND WILL OVERWITE DATA WITH THE SAME NAME
//
//			V_Write1DData_ITX("root:Packages:NIST:VSANS:",type,saveName,binType)
//
Function V_fWrite1DAnnular(pathStr,folderStr,detGroup,saveName)
	String pathStr,folderStr,detGroup,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)

	if(cmpstr(detGroup,"F") == 0)
		Wave/Z pw = phiBin_qxqy_FLRTB
		Wave/Z iw = iPhiBin_qxqy_FLRTB
		Wave/Z sw = ePhiBin_qxqy_FLRTB
	else
		Wave/Z pw = phiBin_qxqy_MLRTB
		Wave/Z iw = iPhiBin_qxqy_MLRTB
		Wave/Z sw = ePhiBin_qxqy_MLRTB
	endif

	
	String dataSetFolderParent,basestr
	
	//make sure the waves exist
	
	if(WaveExists(pw) == 0)
		SetDataFolder root:
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		SetDataFolder root:
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		SetDataFolder root:
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

	fprintf refnum,"Annular data written from folder %s on %s\r\n",folderStr,(date()+" "+time())

// TODO -- make this work for 6-columns (or??)
//	formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
//	fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"	
//	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs

	//currently, only three columns
	formatStr = "%15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 3 columns are | Phi (degrees) | I(phi) (1/cm) | std. dev. I(phi) (1/cm)\r\n"	

	wfprintf refnum,formatStr,pw,iw,sw
	Close refnum
	
//	KillWaves/Z sigQ,qbar,fs
	Print "Data written to: ",fullpath
	
	SetDataFolder root:
	return(0)
End
