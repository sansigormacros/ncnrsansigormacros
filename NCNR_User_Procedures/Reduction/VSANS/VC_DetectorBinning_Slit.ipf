#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//////////////////
//
// Procedures to average data taken in "slit" apertuere geometry. The fake data on the detector panels
//  is as would be collected in PINHOLE geometry - I do not currently have a simulation for slit
//  apertures (this would need to be MonteCarlo) - the I(q) averaging here gives the I(q) that you
//  would measure in 1D using slit geometry. It is done by simply summing the columns of data on each detector.
//
//////////////////
//
//
// TODO - big question about averaging in this way...
// can the T/B panels really be used at all for slit mode? - since there's a big "hole" in the scattering data
// collected -- you're not getting the full column of data covering a wide range of Qy. L/R panels should be fine.
//
// - best answer so far is to skip the T/B panels, and simply not use them
//
// TODO -- be sure that the absolute scaling of this is correct. I have no guarantee that 
//			it'll be correct.
//
/////////////////


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
	
	Variable pixSizeX,pixSizeY,delQx, delQy
	Variable isVCALC=0
	
	if(cmpstr(folderStr,"VCALC") == 0)
		isVCALC = 1
	endif

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:entry:instrument:detector_"	
	
	if(isVCALC)
		WAVE inten = $(folderPath+instPath+detStr+":det_"+detStr)		// 2D detector data
		WAVE/Z iErr = $("asdf_iErr_"+detStr)			// TODO: 2D errors -- may not exist, especially for simulation
	else
		Wave inten = V_getDetectorDataW(folderStr,detStr)
		Wave iErr = V_getDetectorDataErrW(folderStr,detStr)
	endif

	Wave qTotal = $(folderPath+instPath+detStr+":qTot_"+detStr)			// 2D q-values
	Wave qx = $(folderPath+instPath+detStr+":qx_"+detStr)
	Wave qy = $(folderPath+instPath+detStr+":qy_"+detStr)

// ?? TODO not needed here?	
//	pixSizeX = VCALC_getPixSizeX(detStr)
//	pixSizeY = VCALC_getPixSizeY(detStr)
	
	delQx = abs(qx[0][0] - qx[1][0])
	delQy = abs(qy[0][1] - qy[0][0])
	
	// delta Qx is set by the pixel X dimension of the detector, which is the limiting resolution

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

// sum the rows	
	MatrixOp/O iBin_qxqy = sumRows(inten)	//automatically generates the destination

// if the detectors are "L", then the values are all negative...
// if the detectors are T/B, then half is negative, and there's a very nearly zero point in the middle...	
// and it may make no sense to use T/B anyways...
	qBin_qxqy = abs(qx[p][0])

	
	//now get the scaling correct
	// q-integration (rectangular), matrixOp simply summed, so I need to multiply by dy (pixelSizeY -> as Qy?)
	
	iBin_qxqy *= delQy
	
// TODO
//	iBin_qxqy *= 4		//why the factor of 4??? -- this is what I needed to do with FFT->USANS. Do I need it here?


/// TODO -- this is not correct, but just for getting the I(Q) display to look "pretty"
	qBin_qxqy = (abs(qBin_qxqy[p][q]) < 1e-5) ? NaN : qBin_qxqy[p][q]			// clean out the near-zero Q point in the T/B  and Back detectors


	SetDataFolder root:
	
	return(0)
End


// TODO -- update to new folder structure
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

// TODO -- update to new folder structure
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