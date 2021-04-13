#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//////////////////
//
// Procedures to average data taken in "slit" aperture geometry. The fake data on the detector panels
//  is as would be collected in PINHOLE geometry - I do not currently have a simulation for slit
//  apertures (this would need to be MonteCarlo) - the I(q) averaging here gives the I(q) that you
//  would measure in 1D using slit geometry. It is done by simply summing the columns of data on each detector.
//
//////////////////
//
//
// NOTE - there was a big question about averaging in this way...
// can the T/B panels really be used at all for slit mode? - since there's a big "hole" in the scattering data
// collected -- you're not getting the full column of data covering a wide range of Qy.
// - best answer so far is to skip the T/B panels, and simply not use them
//
//
// L/R panels appear to be fine, covering a significnat range of Qy
//  although it is important to note that the different carriages (B,M,F) cover very different "chunks" of Qy
//
// (DONE)
//  x- be sure that the absolute scaling of this is correct. Right now, something is off.
//
//
/////////////////


// (DONE):
// x- verify the error calculation
// x- ? add in functionality to handle FLR and MLR cases (2 panels of data)
//
// seems backwards to call this "byRows", but this is the way that Igor indexes
// LR banks are defined as (48,256) (n,m), sumRows gives sum w/ dimension (n x 1)
//
// updated to new folder structure Feb 2016
// folderStr = RAW,SAM, VCALC or other
// detStr is the panel identifer "ML", etc.
Function VC_fBinDetector_byRows(folderStr,detStr)
	String folderStr,detStr
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC	
	
	Variable pixSizeX,pixSizeY,delQy
	Variable isVCALC=0,maskMissing,nsets=0
	
	maskMissing = 1		// set to zero if a mask is actually present
	
	if(cmpstr(folderStr,"VCALC") == 0)
		isVCALC = 1
	endif

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	strswitch(detStr)	// string switch	
// only one panel, simply pick that panel and move on out of the switch
		case "FL":
		case "FR":
		case "ML":
		case "MR":
		case "B":
			if(isVCALC)
				WAVE inten = $(folderPath+instPath+detStr+":det_"+detStr)		// 2D detector data
				WAVE/Z iErr = $("asdf_iErr_"+detStr)			// 2D errors -- may not exist, especially for simulation
			else
				Wave inten = V_getDetectorDataW(folderStr,detStr)
				Wave iErr = V_getDetectorDataErrW(folderStr,detStr)
				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
				if(WaveExists(mask) == 1)
					maskMissing = 0
				endif
			endif
			
			nsets = 1
			break

//		case "FLR":
//		// detStr has multiple values now, so unfortuntely, I'm hard-wiring things...
//			if(isVCALC)
//				WAVE inten = $(folderPath+instPath+"FL"+":det_"+"FL")
//				WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation		
//				WAVE inten2 = $(folderPath+instPath+"FR"+":det_"+"FR")
//				WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation	
//			else
//				Wave inten = V_getDetectorDataW(folderStr,"FL")
//				Wave iErr = V_getDetectorDataErrW(folderStr,"FL")
//				Wave inten2 = V_getDetectorDataW(folderStr,"FR")
//				Wave iErr2 = V_getDetectorDataErrW(folderStr,"FR")
//				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FL"+":data")
//				Wave/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"FR"+":data")
//				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
//					maskMissing = 0
//				endif
//			endif	
//
//			nsets = 2
//			break
//			
//		case "MLR":
//			if(isVCALC)
//				WAVE inten = $(folderPath+instPath+"ML"+":det_"+"ML")
//				WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation		
//				WAVE inten2 = $(folderPath+instPath+"MR"+":det_"+"MR")
//				WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation	
//			else
//				Wave inten = V_getDetectorDataW(folderStr,"ML")
//				Wave iErr = V_getDetectorDataErrW(folderStr,"ML")
//				Wave inten2 = V_getDetectorDataW(folderStr,"MR")
//				Wave iErr2 = V_getDetectorDataErrW(folderStr,"MR")
//				Wave/Z mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"ML"+":data")
//				Wave/Z mask2 = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+"MR"+":data")
//				if(WaveExists(mask) == 1 && WaveExists(mask2) == 1)
//					maskMissing = 0
//				endif
//			endif	
//		
//			nSets = 2
//			break			

		default:
			nSets = 0							
			Print "ERROR   ---- type is not recognized "
	endswitch

	if(nSets == 0)
		SetDataFolder root:
		return(0)
	endif


	Wave qTotal = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy = $(folderPath+instPath+detStr+":qy_"+detStr)


// delta Qx is set by the pixel X dimension of the detector, which is the limiting resolution
//	delQx = abs(qx[0][0] - qx[1][0])
	
	Variable nq,val
	nq = DimSize(inten,0)		//nq == the number of columns (x dimension)
	
//	SetDataFolder $(folderPath+instPath+detStr)	

	Make/O/D/N=(nq)  $(folderPath+":"+"iBin_qxqy_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"qBin_qxqy_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"nBin_qxqy_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"iBin2_qxqy_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"eBin_qxqy_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"eBin2D_qxqy_"+detStr)
	
	Wave iBin_qxqy = $(folderPath+":"+"iBin_qxqy_"+detStr)
	Wave qBin_qxqy = $(folderPath+":"+"qBin_qxqy_"+detStr)
	Wave nBin_qxqy = $(folderPath+":"+"nBin_qxqy_"+detStr)
	Wave iBin2_qxqy = $(folderPath+":"+"iBin2_qxqy_"+detStr)
	Wave eBin_qxqy = $(folderPath+":"+"eBin_qxqy_"+detStr)
	Wave eBin2D_qxqy = $(folderPath+":"+"eBin2D_qxqy_"+detStr)


	iBin_qxqy = 0
	iBin2_qxqy = 0
	eBin_qxqy = 0
	eBin2D_qxqy = 0
	nBin_qxqy = 0	


// sum the rows	

// MatrixOp would be fast, but I can't figure out how to apply the mask with sumRows???
//	MatrixOp/O iBin_qxqy = sumRows(inten)	//automatically generates the destination
//		
//// how to properly calculate the error?
//// This MatrixOp gives values way too large -- larger than the intensity (be sure to correct *delQy below...
//
//	MatrixOp/O tmp = sqrt(varCols(inten^t))		// variance: no varRows operation, so use the transpose of the matrix
//	eBin_qxqy = tmp[0][p]

	Variable ii,jj,ntube,nYpix,sum_inten, sum_n, sum_inten2,avesq,aveisq,var,mask_val
	ntube = DimSize(inten,0)
	nYpix = DimSize(inten,1)
	
	for(ii=0;ii<ntube;ii+=1)		//for each tube...
		sum_inten = 0			// initialize the sum
		sum_n = 0
		sum_inten2 = 0
		
		for(jj=0;jj<nYpix;jj+=1)			//sum along y...
				val = inten[ii][jj]
				if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
					mask_val = 0
				else
					mask_val = mask[ii][jj]
				endif
				if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
					sum_inten += val
					sum_n += 1
					sum_inten2 += val*val
				endif
		endfor
		iBin_qxqy[ii] = sum_inten/sum_n		//the average value
		

		avesq = (sum_inten/sum_n)^2
		aveisq = sum_inten2/sum_n
		var = aveisq-avesq
		if(var<=0)
			eBin_qxqy[ii] = 1e-6
		else
			eBin_qxqy[ii] = sqrt(var/(sum_n - 1))
		endif

	endfor

// x- use only the Qx component in the y-center of the detector, not Qtotal
// if the detectors are "L", then the values are all negative, so take the absolute value here
	qBin_qxqy =  abs(qx[p][nYpix/2])		


// for the L panels, sort the q-values (and data) after the abs() step, otherwise the data is reversed
// won't hurt to sort the R panel data
	Sort qBin_qxqy, qBin_qxqy,iBin_qxqy,eBin_qxqy

// average and get rid of the duplicate q-values from the L and R sides
	Variable q1,q2,tol
	tol = 0.001 		// 0.1 %
	q1 = qBin_qxqy[0]
	ii=0
	do
		q2 = qBin_qxqy[ii+1]
		if(V_CloseEnough(q1,q2,q1*tol))
			// check to be sure that both values are actually real numbers before trying to average
			if(numtype(iBin_qxqy[ii])==0 && numtype(iBin_qxqy[ii+1])==0)		//==0 => real number
				iBin_qxqy[ii] = (iBin_qxqy[ii] + iBin_qxqy[ii+1])/2		//both OK
			endif
			if(numtype(iBin_qxqy[ii])==0 && numtype(iBin_qxqy[ii+1])!=0)		//==0 => real number
				iBin_qxqy[ii] = iBin_qxqy[ii]		//one OK
			endif
			if(numtype(iBin_qxqy[ii])!=0 && numtype(iBin_qxqy[ii+1])==0)		//==0 => real number
				iBin_qxqy[ii] = iBin_qxqy[ii+1]		//other OK
			endif
			if(numtype(iBin_qxqy[ii])!=0 && numtype(iBin_qxqy[ii+1])!=0)		//==0 => real number
				iBin_qxqy[ii] = (iBin_qxqy[ii])		// both NaN, get rid of it later
			endif
		
			if(numtype(eBin_qxqy[ii])==0 && numtype(eBin_qxqy[ii+1])==0)		//==0 => real number
				eBin_qxqy[ii] = sqrt(eBin_qxqy[ii]^2 + eBin_qxqy[ii+1]^2)		//both OK
			endif
			if(numtype(eBin_qxqy[ii])==0 && numtype(eBin_qxqy[ii+1])!=0)		//==0 => real number
				eBin_qxqy[ii] = eBin_qxqy[ii]		//one OK
			endif
			if(numtype(eBin_qxqy[ii])!=0 && numtype(eBin_qxqy[ii+1])==0)		//==0 => real number
				eBin_qxqy[ii] = eBin_qxqy[ii+1]		//other OK
			endif
			if(numtype(eBin_qxqy[ii])!=0 && numtype(eBin_qxqy[ii+1])!=0)		//==0 => real number
				eBin_qxqy[ii] = (eBin_qxqy[ii])		// both NaN, get rid of it later
			endif
			
			DeletePoints ii+1, 1, qBin_qxqy,iBin_qxqy,eBin_qxqy,iBin2_qxqy,nBin_qxqy,eBin2D_qxqy
		else
			ii+=1
			q1 = q2
		endif
	while(ii<numpnts(qBin_qxqy)-2)



// DONE: use only dQy for the portion of the detector that was not masked!

// get delQy from the portion of the detector that is not masked out
// this is the full Qy extent of the panel
	delQy = V_setDeltaQy_Slit(folderStr,detStr)
	

///  DONE(commented out) x- this is not necessary, but just for getting the I(Q) display to look "pretty"
// clean out the near-zero Q point in the T/B  and Back detectors
// (but the T/B panels not used for slit mode)
//	qBin_qxqy = (abs(qBin_qxqy[p][q]) < 1e-5) ? NaN : qBin_qxqy[p][q]			


// clear out zero data values before exiting...
	// find the last non-zero point, working backwards
	val = numpnts(iBin_qxqy)
	do
		val -= 1
	while((iBin_qxqy[val] == 0) && val > 0)
	
	DeletePoints val, nq-val, iBin_qxqy,qBin_qxqy,eBin_qxqy


// utility function to remove NaN values from the waves
	V_RemoveNaNsQIS(qBin_qxqy, iBin_qxqy, eBin_qxqy)

// work forwards? this doesn't work...
//	val = -1
//	do
//		val += 1
//	while(nBin_qxqy[val] == 0 && val < numpnts(iBin_qxqy)-1)	
//	DeletePoints 0, val, iBin_qxqy,qBin_qxqy,eBin_qxqy


	// -- This is where I calculate the resolution waves
	// -- use the isVCALC flag to exclude VCALC from the resolution calculation if necessary
	//
	// for slit data, fill in the slit height

	nq = numpnts(qBin_qxqy)
	Make/O/D/N=(nq)  $(folderPath+":"+"sigmaQ_qxqy"+"_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"qBar_qxqy"+"_"+detStr)
	Make/O/D/N=(nq)  $(folderPath+":"+"fSubS_qxqy"+"_"+detStr)
	Wave sigmaq = $(folderPath+":"+"sigmaQ_qxqy_"+detStr)
	Wave qbar = $(folderPath+":"+"qBar_qxqy_"+detStr)
	Wave fsubs = $(folderPath+":"+"fSubS_qxqy_"+detStr)




// ASSUMPTION: As a first approximation, ignore the wavelength smearing component
// -- if the data is from white beam or super white beam, then the wavelength smearing can
// (and should) be done numerically (using the empirical distribution) 	

// Do I use the full DQy for the panel or 1/2(DQy) due to the symmetry of the smearing calculation
// -- ANSWER = use 1/2 of the full Qy range of the panel for the smearing calculation (as infinite slit)!!

	sigmaq = -delQy/2
	qbar = -delQy/2
	fsubs = -delQy/2


	SetDataFolder root:
	
	return(0)
End


// unused -- update if necessary
Proc CopyIQWaves()

	SetDataFolder root:Packages:NIST:VSANS:VCALC	

	duplicate/O iBin_qxqy_B iBin_qxqy_B_pin
	duplicate/O qBin_qxqy_B qBin_qxqy_B_pin
	
	duplicate/O iBin_qxqy_MR iBin_qxqy_MR_pin
	duplicate/O qBin_qxqy_MR qBin_qxqy_MR_pin
	duplicate/O iBin_qxqy_MT iBin_qxqy_MT_pin
	duplicate/O qBin_qxqy_MT qBin_qxqy_MT_pin
	duplicate/O iBin_qxqy_ML iBin_qxqy_ML_pin
	duplicate/O qBin_qxqy_ML qBin_qxqy_ML_pin
	duplicate/O iBin_qxqy_MB iBin_qxqy_MB_pin
	duplicate/O qBin_qxqy_MB qBin_qxqy_MB_pin

	duplicate/O iBin_qxqy_FR iBin_qxqy_FR_pin
	duplicate/O qBin_qxqy_FR qBin_qxqy_FR_pin
	duplicate/O iBin_qxqy_FT iBin_qxqy_FT_pin
	duplicate/O qBin_qxqy_FT qBin_qxqy_FT_pin
	duplicate/O iBin_qxqy_FL iBin_qxqy_FL_pin
	duplicate/O qBin_qxqy_FL qBin_qxqy_FL_pin
	duplicate/O iBin_qxqy_FB iBin_qxqy_FB_pin
	duplicate/O qBin_qxqy_FB qBin_qxqy_FB_pin

	SetDataFolder root:
End

// unused -- update if necessary
Window slit_vs_pin_graph() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:VSANS:VCALC:
	Display /W=(1296,44,1976,696) iBin_qxqy_B vs qBin_qxqy_B
	AppendToGraph iBin_qxqy_B_pin vs qBin_qxqy_B_pin
	AppendToGraph iBin_qxqy_MR vs qBin_qxqy_MR
	AppendToGraph iBin_qxqy_MR_pin vs qBin_qxqy_MR_pin
	AppendToGraph iBin_qxqy_MT vs qBin_qxqy_MT
	AppendToGraph iBin_qxqy_MT_pin vs qBin_qxqy_MT_pin
	AppendToGraph iBin_qxqy_FR vs qBin_qxqy_FR
	AppendToGraph iBin_qxqy_FR_pin vs qBin_qxqy_FR_pin
	AppendToGraph iBin_qxqy_FT vs qBin_qxqy_FT
	AppendToGraph iBin_qxqy_FT_pin vs qBin_qxqy_FT_pin
	SetDataFolder fldrSav0
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph lSize=2
	ModifyGraph rgb(iBin_qxqy_B)=(0,0,0),rgb(iBin_qxqy_B_pin)=(65535,16385,16385),rgb(iBin_qxqy_MR)=(2,39321,1)
	ModifyGraph rgb(iBin_qxqy_MR_pin)=(0,0,65535),rgb(iBin_qxqy_MT)=(39321,1,31457)
	ModifyGraph rgb(iBin_qxqy_MT_pin)=(48059,48059,48059),rgb(iBin_qxqy_FR)=(65535,32768,32768)
	ModifyGraph rgb(iBin_qxqy_FR_pin)=(0,65535,0),rgb(iBin_qxqy_FT)=(16385,65535,65535)
	ModifyGraph rgb(iBin_qxqy_FT_pin)=(65535,32768,58981)
	ModifyGraph msize=2
	ModifyGraph grid=1
	ModifyGraph log=1
	ModifyGraph mirror=1
	SetAxis bottom 1e-05,0.05287132
	Legend/C/N=text0/J/X=64.73/Y=7.25 "\\Z12\\s(iBin_qxqy_B) iBin_qxqy_B\r\\s(iBin_qxqy_B_pin) iBin_qxqy_B_pin\r\\s(iBin_qxqy_MR) iBin_qxqy_MR"
	AppendText "\\s(iBin_qxqy_MR_pin) iBin_qxqy_MR_pin\r\\s(iBin_qxqy_MT) iBin_qxqy_MT\r\\s(iBin_qxqy_MT_pin) iBin_qxqy_MT_pin\r\\s(iBin_qxqy_FR) iBin_qxqy_FR"
	AppendText "\\s(iBin_qxqy_FR_pin) iBin_qxqy_FR_pin\r\\s(iBin_qxqy_FT) iBin_qxqy_FT\r\\s(iBin_qxqy_FT_pin) iBin_qxqy_FT_pin"
EndMacro


// finds the delta Qy for the slit height from the data that is not masked
//
// this is the full delta Qy of the panel, not just 1/2
//
Function V_setDeltaQy_Slit(folderStr,detStr)
	String folderStr,detStr
	
	Variable delQy,min_qy,max_qy

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	WAVE qy = $(folderPath+instPath+detStr+":qy_"+detStr)
	WAVE mask = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	Duplicate/O qy tmp_qy
	// for the minimum
	tmp_qy = (mask == 0) ? qY : 1e6
	min_qy = WaveMin(tmp_qy)

	// for the maximum
	tmp_qy = (mask == 0) ? qY : -1e6
	max_qy = WaveMax(tmp_qy)

	KillWaves/Z tmp_qy	
	
	delQy = max_qy-min_qy
	
	return(delQy)
end