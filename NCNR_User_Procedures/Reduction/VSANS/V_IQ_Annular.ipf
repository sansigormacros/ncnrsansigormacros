#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


// JUL 2021 SRK
//
// updated the annular average to use ALL of the data, every time.
// this means that the annulus can span multiple carraiges
// this also means that the detStr/carriage type is now ignored.
//
// be careful that the back panel is set to ignore, or is properly masked
// so that it will not inadvertently contribute to the annulus. (the effect
// will be very noticeable if not on ABS scale.)
//

// (DONE) need to fix the writer so that the "correct" _All waves are saved
// (DONE) add in the ignoreBack global
//
// (DONE)fix the calls to these routines so that they ignore the "type" passed in

// eventually fix the calls so that they "tolerate" type being passed, by change
// the documentation so that the value is not needed - all panels are scanned
// - not limited to a single carriage




// Procedures to do an annular binning of the data
//
// As for SANS, needs a Q-center and Q-delta to define the annular ring,
// and the number of bins to divide the 360 degree circle
//
// qWidth is +/- around the q-center
//
//
// TODO
// x- add error bars to the plot of phi
// x- data writer to export annular data (3-column)
// x- loader to re-read annular data (will the normal loader work?) -- yes
// -- integrate this with the protocol
// -- integrate this with a more general "average panel"
// -- draw the q-center and width on the image (as a contour? - if no, use a draw layer...)
// -- Can I "flag" the pixels that contribute to the annualr average, and overlay them like a 
//    Mask(translucent?), like a "thresholding" operation, but act on the Q-value, not the Z- value.
//
// DONE
// x- none of these procedures are aware of the BACK detector
//

//
//
Proc V_Annular_Binning(folderStr,qCtr_Ann,qWidth)
	String folderStr="SAM"
	Variable qCtr_Ann=0.1,qWidth=0.01  	// +/- in A^-1
	
	String detGroup="F"		//F is passed, but is ignored, all carriages are used
	V_QBinAllPanels_Annular(folderStr,detGroup,qCtr_Ann,qWidth)

	V_Phi_Graph_Proc(folderStr,detGroup)

End

//
// entry procedure for annular averaging
//
// detGroup defines which of the three carriages are used for the annulus
// (defined by qCtr and qWidth)
//
// currently the q-range defined is only checked on a single carriage. No crossing
// of the ring is allowed to spill onto other carriages. Probably not a significant issue
// but may come up in the future.
//
// All of the detector panels for a given carriage are used for the averaging, although
// in practice this cound be specified as say, ML+MR only if the panels were closed together
// and MT and MB were blocked. This would speed up the calculation.
//
Function V_QBinAllPanels_Annular(folderStr,detGroup,qCtr_Ann,qWidth)
	String folderStr,detGroup
	Variable qCtr_Ann,qWidth  	// +/- in A^-1

	Variable ii,delQ
	String detStr
	
	strswitch(detGroup)
		case "F":
			detStr = "FLRTB"
			break
		case "M":
			detStr = "MLRTB"
			break
		case "B":
			detStr = "B"
			break
		default:
			DoAlert 0,"No detGroup match in V_QBinAllPanels_Annular"
			return(0)
	endswitch

	// right now, use all of the detectors. There is a lot of waste in this and it could be 
	// done a lot faster, but...

	// detStr = "FLRTB" or "MLRTB", depending which panel the q-ring is centered on/
	// "_old" routine, no crossing of the rings onto different carriages
	// "_new" routine, allows annulus to cross carriages - detStr is ignored
	
//	V_fDoAnnularBin_QxQy2D_old(folderStr,detStr,qCtr_Ann,qWidth)
	V_fDoAnnularBin_QxQy2D_new(folderStr,detStr,qCtr_Ann,qWidth)


	return(0)
End

Function V_Phi_Graph_Proc(folderStr,detGroup)
	String folderStr,detGroup
	
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)

	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif

	DoWindow/F V_Phi_Graph
	if(V_flag == 0)
		Display /W=(35*sc,45*sc,572*sc,419*sc)/N=V_Phi_Graph /K=1
	else
		RemoveFromGraph/Z iPhiBin_qxqy_FLRTB
		RemoveFromGraph/Z iPhiBin_qxqy_MLRTB
		RemoveFromGraph/Z iPhiBin_qxqy_B
		RemoveFromGraph/Z iPhiBin_qxqy_All
	endif


	wave iPhiBin_qxqy_All = iPhiBin_qxqy_All
	wave phiBin_qxqy_All = phiBin_qxqy_All
	wave ePhiBin_qxqy_All = ePhiBin_qxqy_All
	
	AppendToGraph iPhiBin_qxqy_All vs phiBin_qxqy_All
//		Display /W=(35,45,572,419)/N=V_Phi_Graph /K=1 iPhiBin_qxqy_All vs phiBin_qxqy_All
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph rgb(iPhiBin_qxqy_All)=(3,52428,1)
	ErrorBars iPhiBin_qxqy_All Y,wave=(ePhiBin_qxqy_All,ePhiBin_qxqy_All)
	Label left "Counts"
	Label bottom "Phi (degrees)"
	Legend


// comment out these three if-blocks when calculating with ALL carriages
// - un-comment for testing to make sure both methods agree
//	if(cmpstr(detGroup,"F") == 0)
//		wave iPhiBin_qxqy_FLRTB=iPhiBin_qxqy_FLRTB
//		wave phiBin_qxqy_FLRTB=phiBin_qxqy_FLRTB
//		wave ePhiBin_qxqy_FLRTB=ePhiBin_qxqy_FLRTB
//		
//		AppendToGraph iPhiBin_qxqy_FLRTB vs phiBin_qxqy_FLRTB
////		Display /W=(35,45,572,419)/N=V_Phi_Graph /K=1 iPhiBin_qxqy_FLRTB vs phiBin_qxqy_FLRTB
//		ModifyGraph mode=4
//		ModifyGraph marker=19
//		ErrorBars iPhiBin_qxqy_FLRTB Y,wave=(ePhiBin_qxqy_FLRTB,ePhiBin_qxqy_FLRTB)
//		Label left "Counts"
//		Label bottom "Phi (degrees)"
//		Legend
//	endif
//	if(cmpstr(detGroup,"M") == 0)
//		wave iPhiBin_qxqy_MLRTB=iPhiBin_qxqy_MLRTB
//		wave phiBin_qxqy_MLRTB=phiBin_qxqy_MLRTB
//		wave ePhiBin_qxqy_MLRTB=ePhiBin_qxqy_MLRTB
//		
//		AppendToGraph iPhiBin_qxqy_MLRTB vs phiBin_qxqy_MLRTB
//		ModifyGraph mode=4
//		ModifyGraph marker=19
//		ErrorBars iPhiBin_qxqy_MLRTB Y,wave=(ePhiBin_qxqy_MLRTB,ePhiBin_qxqy_MLRTB)
//		Label left "Counts"
//		Label bottom "Phi (degrees)"
//		Legend
//	endif
//	if(cmpstr(detGroup,"B") == 0)
//		wave iPhiBin_qxqy_B=iPhiBin_qxqy_B
//		wave phiBin_qxqy_B=phiBin_qxqy_B
//		wave ePhiBin_qxqy_B=ePhiBin_qxqy_B
//		
//		AppendToGraph iPhiBin_qxqy_B vs phiBin_qxqy_B
//		ModifyGraph mode=4
//		ModifyGraph marker=19
//		ErrorBars iPhiBin_qxqy_B Y,wave=(ePhiBin_qxqy_B,ePhiBin_qxqy_B)
//		Label left "Counts"
//		Label bottom "Phi (degrees)"
//		Legend
//	endif
	
	SetDataFolder fldrSav0
EndMacro


//////////
//
//
//
// (DONE) 
// x- "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
// ** Currently, type is being passed in as "" and ignored (looping through all of the detector panels
// to potentially add to the annular bins) - only a single carriage is used
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
//
//	Variable qCtr_Ann = 0.1
//	Variable qWidth = 0.02		// +/- in A^-1
//
Function V_fDoAnnularBin_QxQy2D_old(folderStr,type,qCtr_Ann,qWidth)
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

// (DONE):
// x- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
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
					
		case "B":
			if(isVCALC)
				WAVE inten = $(folderPath+instPath+"B"+":det_"+"B")
				WAVE/Z iErr = $("iErr_"+"B")			// 2D errors -- may not exist, especially for simulation		
			else
				Wave inten = V_getDetectorDataW(folderStr,"B")
				Wave iErr = V_getDetectorDataErrW(folderStr,"B")

				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"B"+":data")
				
				if(WaveExists(mask) == 1)
					maskMissing = 0
				endif
			endif	
//			NVAR delQ = $(folderPath+instPath+"ML"+":gDelQ_ML")
			
			Wave qTotal = $(folderPath+instPath+"B"+":qTot_"+"B")			// 2D q-values	
	
			Wave qx = $(folderPath+instPath+"B"+":qx_"+"B")			// 2D qx-values	

			Wave qy = $(folderPath+instPath+"B"+":qy_"+"B")			// 2D qy-values	
					
			nSets = 1
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


//(DONE): properly define the 2D errors here - I'll have this if I do the simulation
// x- need to propagate the 2D errors up to this point
//
	if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// if the error not properly defined, using some fictional value
	endif
	if(WaveExists(iErr2)==0 && WaveExists(inten2) != 0)
		Duplicate/O inten2,iErr2
		Wave iErr2=iErr2
//		iErr2 = 1+sqrt(inten2+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr2 = sqrt(inten2+0.75)			// if the error not properly defined, using some fictional value
	endif
	if(WaveExists(iErr3)==0  && WaveExists(inten3) != 0)
		Duplicate/O inten3,iErr3
		Wave iErr3=iErr3
//		iErr3 = 1+sqrt(inten3+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr3 = sqrt(inten3+0.75)			// if the error not properly defined, using some fictional value
	endif
	if(WaveExists(iErr4)==0  && WaveExists(inten4) != 0)
		Duplicate/O inten4,iErr4
		Wave iErr4=iErr4
//		iErr4 = 1+sqrt(inten4+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr4 = sqrt(inten4+0.75)			// if the error not properly defined, using some fictional value
	endif

	// -- nq may need to be larger, if annular averaging on the back detector, but n=600 seems to be OK

	nq = 600

// -- where to put the averaged data -- right now, folderStr is forced to ""	
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
	
	
	Variable nphi,dphi,isIn,phiij,iphi

// DONE: define nphi (this is now set as a preference)
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
// DONE:
// x- the iErr (=2D) wave and accumulation of error is correctly propagated through all steps
// x- the solid angle per pixel is completely implemented.
//    -Solid angle will be present for WORK data other than RAW, but not for RAW

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
// DONE:
// x- 2D Errors ARE properly acculumated through reduction, so this loop of calculations is correct
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



//////////
//
//
//
// (DONE) 
// x- "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
// ** Currently, type is being passed in as "" and ignored (looping through all of the detector panels
// to potentially add to the annular bins)
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
//
//	Variable qCtr_Ann = 0.1
//	Variable qWidth = 0.02		// +/- in A^-1
//
//
Function V_fDoAnnularBin_QxQy2D_New(folderStr,type,qCtr_Ann,qWidth)
	String folderStr,type
	Variable qCtr_Ann,qWidth
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj,kk
	Variable qVal,nq,var,avesq,aveisq
	Variable binIndex,val,isVCALC=0,maskMissing

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"
	String detStr
		
	if(cmpstr(folderStr,"VCALC") == 0)
		isVCALC = 1
	endif


// set up the waves for the output
//
// !! type now == "All", not FLRTB, MLRTB, or B
//

	type="All"

	// -- nq may need to be larger, if annular averaging on the back detector, but n=600 seems to be OK

	nq = 600

// -- where to put the averaged data -- right now, folderStr is forced to ""	
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
	
	
	Variable nphi,dphi,isIn,phiij,iphi

// DONE: define nphi (this is now set as a preference)
//	dr = 1 			//minimum annulus width, keep this fixed at one
	NVAR numPhiSteps = root:Packages:NIST:VSANS:Globals:gNPhiSteps
	nphi = numPhiSteps		//number of anular sectors is set by users
	dphi = 360/nphi
	

	iPhiBin_qxqy = 0
	iPhiBin2_qxqy = 0
	ePhiBin_qxqy = 0
	ePhiBin2D_qxqy = 0
	nPhiBin_qxqy = 0	//number of intensities added to each bin


	
// now switch on the type to determine which waves to declare and create
// since there may be more than one panel to step through. There may be two, there may be four
//

// (DONE):
// x- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
//
// assume that the mask files are missing unless we can find them. If VCALC data, 
//  then the Mask is missing by definition

	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	String panelList=""
	if(gIgnoreDetB)
		panelList = ksDetectorListNoB
	else	
		panelList = ksDetectorListAll
	endif

	for(kk=0;kk<ItemsInList(panelList);kk+=1)		// loop over all of the 9(or 8) panels
		detStr = StringFromList(kk, panelList, ";")	
		maskMissing=1

		if(isVCALC)
			WAVE inten = $(folderPath+instPath+"FL"+":det_"+detStr)
			WAVE/Z iErr = $("iErr_"+detStr)			// 2D errors -- may not exist, especially for simulation			
		else
			Wave inten = V_getDetectorDataW(folderStr,detStr)
			Wave iErr = V_getDetectorDataErrW(folderStr,detStr)
			Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
			if(WaveExists(mask) == 1)
				maskMissing = 0
			endif
		endif	
		Wave qTotal = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values	
		Wave qx = $(folderPath+instPath+detStr+":qx_"+detStr)			// 2D qx-values	
		Wave qy = $(folderPath+instPath+detStr+":qy_"+detStr)			// 2D qy-values	

//(DONE): properly define the 2D errors here - I'll have this if I do the simulation
// x- need to propagate the 2D errors up to this point
//
		if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
			Duplicate/O inten,iErr
			Wave iErr=iErr
	//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
			iErr = sqrt(inten+0.75)			// if the error not properly defined, using some fictional value
		endif

// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
		if(maskMissing == 1)
			Print "Mask file not found for at least one detector - so all data is used"
		endif


// this needs to be a double loop now...
// DONE:
// x- the iErr (=2D) wave and accumulation of error is correctly propagated through all steps
// x- the solid angle per pixel is completely implemented.
//    -Solid angle will be present for WORK data other than RAW, but not for RAW






	Variable mask_val
// use set 1 (no number) only
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
		

	endfor	// end main for loop over all detector panels



// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf
// DONE:
// x- 2D Errors ARE properly acculumated through reduction, so this loop of calculations is correct
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
	
	
//	V_fWrite1DAnnular_old(pathStr,folderStr,detGroup,saveName)
	V_fWrite1DAnnular_new(pathStr,folderStr,detGroup,saveName)
	
end

// DONE:
// - this is a basic solution before a more complete writer is created
// - resolution is not generated here and is generally not reported for annualr data
// (although it could be)
//
// this will bypass save dialogs
// - AND WILL OVERWITE DATA WITH THE SAME NAME
//
//
Function V_fWrite1DAnnular_old(pathStr,folderStr,detGroup,saveName)
	String pathStr,folderStr,detGroup,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)

	if(cmpstr(detGroup,"F") == 0)
		Wave/Z pw = phiBin_qxqy_FLRTB
		Wave/Z iw = iPhiBin_qxqy_FLRTB
		Wave/Z sw = ePhiBin_qxqy_FLRTB
	endif
	if(cmpstr(detGroup,"M") == 0)
		Wave/Z pw = phiBin_qxqy_MLRTB
		Wave/Z iw = iPhiBin_qxqy_MLRTB
		Wave/Z sw = ePhiBin_qxqy_MLRTB
	endif
	if(cmpstr(detGroup,"B") == 0)
		Wave/Z pw = phiBin_qxqy_B
		Wave/Z iw = iPhiBin_qxqy_B
		Wave/Z sw = ePhiBin_qxqy_B
	endif
	
	String dataSetFolderParent,basestr
	
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	

	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	
	//make sure the waves exist
	
	if(WaveExists(pw) == 0)
		SetDataFolder root:
		Abort "phi is missing"
	endif
	if(WaveExists(iw) == 0)
		SetDataFolder root:
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		SetDataFolder root:
		Abort "s is missing"
	endif
	if(WaveExists(proto) == 0)
		SetDataFolder root:
		Abort "protocol information is missing."
	endif


// no beg/end trimming is used for annular data



	PathInfo catPathName
	fullPath = S_Path + saveName

	Open refnum as fullpath

	fprintf refnum,"Annular data written from folder %s on %s\r\n",folderStr,(date()+" "+time())


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
//	fprintf refnum, "Beginning Trim Points: %s\r\n",ProtoStr7
//	fprintf refnum, "End Trim Points: %s\r\n",ProtoStr8


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


// DONE:
// - this is a basic solution before a more complete writer is created
// - resolution is not generated here and is generally not reported for annular data
// (although it could be)
//
// JUL 2021 SRK
// updated to write out data generated over all carriages, not just one
//
// this will bypass save dialogs
// - AND WILL OVERWITE DATA WITH THE SAME NAME
//
//
Function V_fWrite1DAnnular_new(pathStr,folderStr,detGroup,saveName)
	String pathStr,folderStr,detGroup,saveName
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1

	SetDataFolder $(pathStr+folderStr)

	
	Wave/Z pw = phiBin_qxqy_All
	Wave/Z iw = iPhiBin_qxqy_All
	Wave/Z sw = ePhiBin_qxqy_All
	
	
	String dataSetFolderParent,basestr
	
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	

	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	
	//make sure the waves exist
	
	if(WaveExists(pw) == 0)
		SetDataFolder root:
		Abort "phi is missing"
	endif
	if(WaveExists(iw) == 0)
		SetDataFolder root:
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		SetDataFolder root:
		Abort "s is missing"
	endif
	if(WaveExists(proto) == 0)
		SetDataFolder root:
		Abort "protocol information is missing."
	endif

// no beg/end trimming is used for annular data




	PathInfo catPathName
	fullPath = S_Path + saveName

	Open refnum as fullpath

	fprintf refnum,"Annular data written from folder %s on %s\r\n",folderStr,(date()+" "+time())


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
//	fprintf refnum, "Beginning Trim Points: %s\r\n",ProtoStr7
//	fprintf refnum, "End Trim Points: %s\r\n",ProtoStr8


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



// 
// x- I want to mask out everything that is "out" of the annulus
//
// 0 = keep the point
// 1 = yes, mask the point
Function V_MarkAnnularOverlayPixels(qTotal,overlay,qCtr_ann,qWidth)
	Wave qTotal,overlay
	Variable qCtr_ann,qWidth
		
	
	Variable xDim=DimSize(qTotal, 0)
	Variable yDim=DimSize(qTotal, 1)

	Variable ii,jj,exclude,qVal
	
	// initialize the mask to == 1 == exclude everything
	overlay = 1

// now give every opportunity to keep pixel in
	for(ii=0;ii<xDim;ii+=1)
		for(jj=0;jj<yDim;jj+=1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			qval = qTotal[ii][jj]
			exclude = 1
		
			// annulus as defined
			if(V_CloseEnough(qval,qCtr_ann,qWidth))
				exclude = 0
			endif
			
			// set the mask value
			overlay[ii][jj] = exclude
		endfor
	endfor


	return(0)
End