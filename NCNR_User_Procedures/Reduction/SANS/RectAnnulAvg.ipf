#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//***********************
// Vers. 1.2 092101
//
// functions to perform either ractangular averages (similar to sector averages)
// or annular averages ( fixed Q, I(angle) )
//
// dispatched to this point by ExecuteProtocol()
//
//**************************

////////////////////////////////////
//
//		For AVERAGE and for DRAWING
//			DRAWING routines only use a subset of the total list, since saving, naming, etc. don't apply
//		(10) possible keywords, some numerical, some string values
//		AVTYPE=string		string from set {Circular,Annular,Rectangular,Sector,2D_ASCII,PNG_Graphic}
//		PHI=value			azimuthal angle (-90,90)
//		DPHI=value			+/- angular range around phi for average
//		WIDTH=value		total width of rectangular section, in pixels
//		SIDE=string		string from set {left,right,both} **note NOT capitalized
//		QCENTER=value		q-value (1/A) of center of annulus for annular average
//		QDELTA=value		total width of annulus centered at QCENTER
//		PLOT=string		string from set {Yes,No} = truth of generating plot of averaged data
//		SAVE=string		string from set {Yes,No} = truth of saving averaged data to disk
//		NAME=string		string from set {Auto,Manual} = Automatic name generation or Manual(dialog)
//
//////////////////////////////////


//function to do average of a rectangular swath of the detector
//a sector average seems to be more appropriate, but there may be some
//utility in rectangular averages
//the parameters in the global keyword-string must have already been set somewhere
//either directly or from the protocol
//
// 2-D data in the folder must already be on a linear scale. The calling routine is 
//responsible for this - 
//writes out the averaged waves to the "type" data folder
//data is not written to disk by this routine
//
Function RectangularAverageTo1D(type)
	String type
	
	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr
	
	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	//
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,dtsize,dtdist,dr,ddr
	Variable lambda,trans
	Wave reals = $(destPath + ":RealsRead")
	WAVE/T textread = $(destPath + ":TextRead")
//	String fileStr = textread[3]
	
	// center of detector, for non-linear corrections
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
	
	// beam center, in pixels
	x0 = reals[16]
	y0 = reals[17]
	//detector calibration constants
	sx = reals[10]		//mm/pixel (x)
	sx3 = reals[11]		//nonlinear coeff
	sy = reals[13]		//mm/pixel (y)
	sy3 = reals[14]		//nonlinear coeff

	
	dtsize = 10*reals[20]		//det size in mm
	dtdist = 1000*reals[18]	// det distance in mm
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	NVAR binWidth=root:Packages:NIST:gBinWidth
	dr = binWidth		// annulus width set by user, default is one
	ddr = dr*sx		//step size, in mm (this is the value to pass to the resolution calculation, not dr 18NOV03)
		
	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,dxbm,dybm,ii
	Variable phi_rad,dphi_rad,phi_x,phi_y
	Variable forward,mirror
	
	String side = StringByKey("SIDE",keyListStr,"=",";")
//	Print "side = ",side

	//convert from degrees to radians
	phi_rad = (Pi/180)*NumberByKey("PHI",keyListStr,"=",";")
	dphi_rad = (Pi/180)*NumberByKey("DPHI",keyListStr,"=",";")
	//create cartesian values for unit vector in phi direction
	phi_x = cos(phi_rad)
	phi_y = sin(phi_rad)
	
	//get (total) width of band
	Variable width = NumberByKey("WIDTH",keyListStr,"=",";")

	/// data wave is data in the current folder which was set at the top of the function
	Wave data=$(destPath + ":data")
	//Check for the existence of the mask, if not, make one (local to this folder) that is null
	
	if(WaveExists($"root:Packages:NIST:MSK:data") == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
		WAVE mask = $(destPath + ":mask")
		mask = 0
	else
		Wave mask=$"root:Packages:NIST:MSK:data"
	Endif
	
	rcentr = 100		//pixels within rcentr of beam center are broken into 9 parts
	// values for error if unable to estimate value
	//large_num = 1e10
	large_num = 1		//1e10 value (typically sig of last data point) plots poorly, arb set to 1
	small_num = 1e-10
	
	// output wave are expected to exist (?) initialized to zero, what length?
	// 300 points on VAX ---
	Variable wavePts=500
	Make/O/N=(wavePts) $(destPath + ":qval"),$(destPath + ":aveint")
	Make/O/N=(wavePts) $(destPath + ":ncells"),$(destPath + ":dsq"),$(destPath + ":sigave")
	Make/O/N=(wavePts) $(destPath + ":SigmaQ"),$(destPath + ":fSubS"),$(destPath + ":QBar")
	WAVE qval = $(destPath + ":qval")
	WAVE aveint = $(destPath + ":aveint")
	WAVE ncells = $(destPath + ":ncells")
	WAVE dsq = $(destPath + ":dsq")
	WAVE sigave = $(destPath + ":sigave")
	WAVE qbar = $(destPath + ":QBar")
	WAVE sigmaq = $(destPath + ":SigmaQ")
	WAVE fsubs = $(destPath + ":fSubS")

	qval = 0
	aveint = 0
	ncells = 0
	dsq = 0
	sigave = 0
	qbar = 0
	sigmaq = 0
	fsubs = 0

	dtdis2 = dtdist^2
	nq = 1
	xoffst=0
	//distance of beam center from detector center
	dxbm = FX(x0,sx3,xcenter,sx)
	dybm = FY(y0,sy3,ycenter,sy)
		
	//BEGIN AVERAGE **********
	Variable xi,dxi,dx,jj,data_pixel,yj,dyj,dy,mask_val=0.1
	Variable dr2,nd,fd,nd2,ll,kk,dxx,dyy,ir,dphi_p,d_per,d_pll
	Make/O/N=2 $(destPath + ":par")
	WAVE par = $(destPath + ":par")
	
	// IGOR arrays are indexed from [0][0], FORTAN from (1,1) (and the detector too)
	// loop index corresponds to FORTRAN (old code) 
	// and the IGOR array indices must be adjusted (-1) to the correct address
	ii=1
	do
		xi = ii
		dxi = FX(xi,sx3,xcenter,sx)
		dx = dxi-dxbm		//dx and dy are in mm
		
		jj = 1
		do
			data_pixel = data[ii-1][jj-1]		//assign to local variable
			yj = jj
			dyj = FY(yj,sy3,ycenter,sy)
			dy = dyj - dybm
			if(!(mask[ii][jj]))			//masked pixels = 1, skip if masked (this way works...)
				dr2 = (dx^2 + dy^2)^(0.5)		//distance from beam center NOTE dr2 used here - dr used above
				if(dr2>rcentr)		//keep pixel whole
					nd = 1
					fd = 1
				else				//break pixel into 9 equal parts
					nd = 3
					fd = 2
				endif
				nd2 = nd^2
				ll = 1		//"el-el" loop index
				do
					dxx = dx + (ll - fd)*sx/3
					kk = 1
					do
						dyy = dy + (kk - fd)*sy/3
						//determine distance pixel is from beam center (d_pll)
						//and distance off-line (d_per) and if in forward direction
						par = 0			//initialize the wave
						forward = distance(dxx,dyy,phi_x,phi_y,par)
						d_per = par[0]
						d_pll = par[1]
						//check whether pixel lies within width band
						if(d_per <= (0.5*width*ddr))
							//check if pixel lies within allowed sector(s)
							if(cmpstr(side,"both")==0)		//both sectors
									//increment
									nq = IncrementPixel_Rec(data_pixel,ddr,d_pll,aveint,dsq,ncells,nq,nd2)
							else
								if(cmpstr(side,"right")==0)		//forward sector only
									if(forward)
										//increment
										nq = IncrementPixel_Rec(data_pixel,ddr,d_pll,aveint,dsq,ncells,nq,nd2)
									Endif
								else			//mirror sector only
									if(!forward)
										//increment
										nq = IncrementPixel_Rec(data_pixel,ddr,d_pll,aveint,dsq,ncells,nq,nd2)
									Endif
								Endif
							Endif		//allowable sectors
						Endif		//check if in band
						kk+=1
					while(kk<=nd)
					ll += 1
				while(ll<=nd)
			Endif		//masked pixel check
			jj += 1
		while (jj<=pixelsY)
		ii += 1
	while(ii<=pixelsX)		//end of the averaging
		
	//compute q-values and errors
	Variable ntotal,rr,theta,avesq,aveisq,var
	
	lambda = reals[26]
	ntotal = 0
	kk = 1
	do
		rr = (2*kk-1)*ddr/2
		theta = 0.5*atan(rr/dtdist)
		qval[kk-1] = (4*Pi/lambda)*sin(theta)
		if(ncells[kk-1] == 0)
			//no pixels in annuli, data unknown
			aveint[kk-1] = 0
			sigave[kk-1] = large_num
		else
			if(ncells[kk-1] <= 1)
				//need more than one pixel to determine error
				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
				sigave[kk-1] = large_num
			else
				//assume that the intensity in each pixel in annuli is normally
				// distributed about mean...
				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
				avesq = aveint[kk-1]^2
				aveisq = dsq[kk-1]/ncells[kk-1]
				var = aveisq-avesq
				if(var<=0)
//					sigave[kk-1] = small_num
					sigave[kk-1] = large_num		//if there are zero counts, make error large_num to be a warning flag
				else
					sigave[kk-1] = sqrt(var/(ncells[kk-1] - 1))
				endif
			endif
		endif
		ntotal += ncells[kk-1]
		kk+=1
	while(kk<=nq)
	
	//Print "NQ = ",nq
	// data waves were defined as 200 points (=wavePts), but now have less than that (nq) points
	// use DeletePoints to remove junk from end of waves
	//WaveStats would be a more foolproof implementation, to get the # points in the wave
	Variable startElement,numElements
	startElement = nq
	numElements = wavePts - startElement
	DeletePoints startElement,numElements, qval,aveint,ncells,dsq,sigave
	
	//////////////end of VAX sector_ave()
		
	//angle dependent transmission correction 
	Variable uval,arg,cos_th
	lambda = reals[26]
	trans = reals[4]
//
//  The transmission correction is now done at the ADD step, in DetCorr()
//		
//	////this section is the trans_correct() VAX routine
//	if(trans<0.1)
//		Print "***transmission is less than 0.1*** and is a significant correction"
//	endif
//	if(trans==0)
//		Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
//		trans = 1
//	endif
//	//optical thickness
//	uval = -ln(trans)
//	//apply correction to aveint[]
//	//index from zero here, since only working with IGOR waves
//	ii=0
//	do
//		theta = 2*asin(lambda*qval[ii]/(4*pi))
//		cos_th = cos(theta)
//		arg = (1-cos_th)/cos_th
//		if((uval<0.01) || (cos_th>0.99))		//OR
//			//small arg, approx correction
//			aveint[ii] /= 1-0.5*uval*arg
//		else
//			//large arg, exact correction
//			aveint[ii] /= (1-exp(-uval*arg))/(uval*arg)
//		endif
//		ii+=1
//	while(ii<nq)
//	//end of transmission/pathlength correction
//	
// ***************************************************************
//
// Do the extra 3 columns of resolution calculations starting here.
//
// ***************************************************************

	Variable L2 = reals[18]
	Variable BS = reals[21]
	Variable S1 = reals[23]
	Variable S2 = reals[24]
	Variable L1 = reals[25]
	lambda = reals[26]
	Variable lambdaWidth = reals[27]
	String detStr=textRead[9]
	
	Variable usingLenses = reals[28]		//new 2007

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current
	//good values

	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	
//	DDet = DetectorPixelResolution(fileStr,detStr)		//needs detector type and beamline
	//note that reading the detector pixel size from the header ASSUMES SQUARE PIXELS! - Jan2008
	DDet = reals[10]/10			// header value (X) is in mm, want cm here
	
	//Width of annulus used for the average is gotten from the 
	//input dialog before.  This also must be passed to the resol
	//calculator. Currently the default is dr=1 so just keeping that.

	//Go from 0 to nq doing the calc for all three values at
	//every Q value

	ii=0

	Variable ret1,ret2,ret3
	do
		getResolution(qval[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,usingLenses,ret1,ret2,ret3)
		sigmaq[ii] = ret1
		qbar[ii] = ret2	
		fsubs[ii] = ret3
		ii+=1
	while(ii<nq)

	DeletePoints startElement,numElements, sigmaq, qbar, fsubs

// ***************************************************************
//
// End of resolution calculations
//
// ***************************************************************

	Avg_1D_Graph(aveint,qval,sigave)

	//get rid of the default mask, if one was created (it is in the current folder)
	//don't just kill "mask" since it might be pointing to the one in the MSK folder
	Killwaves/Z $(destPath+":mask")
	
	KillWaves/Z $(destPath+":par")		//parameter wave used in function distance()
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return 0
End

//returns nq, new number of q-values
//arrays aveint,dsq,ncells are also changed by this function
//
Function IncrementPixel_Rec(dataPixel,ddr,d_pll,aveint,dsq,ncells,nq,nd2)
	Variable dataPixel,ddr,d_pll
	Wave aveint,dsq,ncells
	Variable nq,nd2
	
	Variable ir
	
	ir = trunc(abs(d_pll)/ddr)+1
	if (ir>nq)
		nq = ir		//resets maximum number of q-values
	endif
	aveint[ir-1] += dataPixel/nd2		//ir-1 must be used, since ir is physical
	dsq[ir-1] += dataPixel*dataPixel/nd2
	ncells[ir-1] += 1/nd2
	
	Return nq
End

//function determines disatnce in mm  that pixel is from line
//intersecting cetner of detector and direction phi
//at chosen azimuthal angle phi -> [cos(phi),sin(phi0] = [phi_x,phi_y]
//distance is always positive
//
// distances are returned in  a wave
// forward (truth) is the function return value
//
Function distance(dxx,dyy,phi_x,phi_y,par)
	Variable dxx,dyy,phi_x,phi_y
	Wave par		//par[0] = d_per
					//par[1] = d_pll	, both are returned values
	
	Variable val,rr,dot_prod,forward,d_per,d_pll,dphi_pixel
	
	rr = sqrt(dxx^2 + dyy^2)
	dot_prod = (dxx*phi_x + dyy*phi_y)/rr
	if(dot_prod >= 0)
		forward = 1
	else
		forward = 0
	Endif
	//? correct for roundoff error? - is this necessary in IGOR, w/ double precision?
	if(dot_prod > 1)
		dot_prod =1
	Endif
	if(dot_prod < -1)
		dot_prod = -1
	Endif
	dphi_pixel = acos(dot_prod)
	
	//distance (in mm) that pixel is from  line (perpendicular)
	d_per = sin(dphi_pixel)*rr
	//distance (in mm) that pixel projected onto line is from beam center (parallel)
	d_pll = cos(dphi_pixel)*rr
	
	//assign to wave for return
	par[0] = d_per
	par[1] = d_pll
	
	return (forward)

End

//performs an average around an annulus of specified width, centered on a 
//specified q-value (Intensity vs. angle)
//the parameters in the global keyword-string must have already been set somewhere
//either directly or from the protocol
//
//the input (data in the "type" folder) must be on linear scale - the calling routine is
//responsible for this
//averaged data is written to the data folder and plotted. data is not written
//to disk from this routine.
//
Function AnnularAverageTo1D(type)
	String type
	
	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr
	
	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,dtsize,dtdist
	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,xbm,ybm,ii
	Variable rc,delr,rlo,rhi,dphi,nphi,dr
	Variable lambda,trans
	Wave reals = $(destPath + ":RealsRead")

	// center of detector, for non-linear corrections
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
	
	// beam center, in pixels
	x0 = reals[16]
	y0 = reals[17]
	//detector calibration constants
	sx = reals[10]		//mm/pixel (x)
	sx3 = reals[11]		//nonlinear coeff
	sy = reals[13]		//mm/pixel (y)
	sy3 = reals[14]		//nonlinear coeff
	
	dtsize = 10*reals[20]		//det size in mm
	dtdist = 1000*reals[18]	// det distance in mm
	lambda = reals[26]
	
	Variable qc = NumberByKey("QCENTER",keyListStr,"=",";")
	Variable nw = NumberByKey("QDELTA",keyListStr,"=",";")
	
	dr = 1 			//minimum annulus width, keep this fixed at one
	NVAR numPhiSteps = root:Packages:NIST:gNPhiSteps
	nphi = numPhiSteps		//number of anular sectors is set by users
	
	rc = 2*dtdist*asin(qc*lambda/4/Pi)		//in mm
	delr = nw*sx/2
	rlo = rc-delr
	rhi = rc + delr
	dphi = 360/nphi

	/// data wave is data in the current folder which was set at the top of the function
	Wave data=$(destPath + ":data")
	//Check for the existence of the mask, if not, make one (local to this folder) that is null
	
	if(WaveExists($"root:Packages:NIST:MSK:data") == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
		WAVE mask = $(destPath + ":mask")
		mask = 0
	else
		Wave mask=$"root:Packages:NIST:MSK:data"
	Endif
	
	rcentr = 150		//pixels within rcentr of beam center are broken into 9 parts
	// values for error if unable to estimate value
	//large_num = 1e10
	large_num = 1		//1e10 value (typically sig of last data point) plots poorly, arb set to 1
	small_num = 1e-10
	
	// output wave are expected to exist (?) initialized to zero, what length?
	// 300 points on VAX ---
	Variable wavePts=500
	Make/O/N=(wavePts) $(destPath + ":phival"),$(destPath + ":aveint")
	Make/O/N=(wavePts) $(destPath + ":ncells"),$(destPath + ":sig"),$(destPath + ":sigave")
	WAVE phival = $(destPath + ":phival")
	WAVE aveint = $(destPath + ":aveint")
	WAVE ncells = $(destPath + ":ncells")
	WAVE sig = $(destPath + ":sig")
	WAVE sigave = $(destPath + ":sigave")

	phival = 0
	aveint = 0
	ncells = 0
	sig = 0
	sigave = 0

	dtdis2 = dtdist^2
	nq = 1
	xoffst=0
	//distance of beam center from detector center
	xbm = FX(x0,sx3,xcenter,sx)
	ybm = FY(y0,sy3,ycenter,sy)
		
	//BEGIN AVERAGE **********
	Variable xi,xd,x,y,yd,yj,nd,fd,nd2,iphi,ntotal,var
	Variable jj,data_pixel,xx,yy,ll,kk,rij,phiij,avesq,aveisq

	// IGOR arrays are indexed from [0][0], FORTAN from (1,1) (and the detector too)
	// loop index corresponds to FORTRAN (old code) 
	// and the IGOR array indices must be adjusted (-1) to the correct address
	ntotal = 0
	ii=1
	do
		xi = ii
		xd = FX(xi,sx3,xcenter,sx)
		x = xoffst + xd -xbm		//x and y are in mm
		
		jj = 1
		do
			data_pixel = data[ii-1][jj-1]		//assign to local variable
			yj = jj
			yd = FY(yj,sy3,ycenter,sy)
			y = yd - ybm
			if(!(mask[ii-1][jj-1]))			//masked pixels = 1, skip if masked (this way works...)
				nd = 1
				fd = 1
				if( (abs(x) > rcentr) || (abs(y) > rcentr))	//break pixel into 9 equal parts
					nd = 3
					fd = 2
				Endif
				nd2 = nd^2
				ll = 1		//"el-el" loop index
				do
					xx = x + (ll - fd)*sx/3
					kk = 1
					do
						yy = y + (kk - fd)*sy/3
						//test to see if center of pixel (i,j) lies in annulus
						rij = sqrt(x*x + y*y)/dr + 1.001
						//check whether pixel lies within width band
						if((rij > rlo) && (rij < rhi))
							//in the annulus, do something
							if (yy >= 0)
								//phiij is in degrees
								phiij = atan2(yy,xx)*180/Pi		//0 to 180 deg
							else
								phiij = 360 + atan2(yy,xx)*180/Pi		//180 to 360 deg
							Endif
							if (phiij > (360-0.5*dphi))
								phiij -= 360
							Endif
							iphi = trunc(phiij/dphi + 1.501)
							aveint[iphi-1] += 9*data_pixel/nd2
							sig[iphi-1] += 9*data_pixel*data_pixel/nd2
							ncells[iphi-1] += 9/nd2
							ntotal += 9/nd2
						Endif		//check if in annulus
						kk+=1
					while(kk<=nd)
					ll += 1
				while(ll<=nd)
			Endif		//masked pixel check
			jj += 1
		while (jj<=pixelsY)
		ii += 1
	while(ii<=pixelsX)		//end of the averaging
		
	//compute phi-values and errors
	
	ntotal /=9
	
	kk = 1
	do
		phival[kk-1] = dphi*(kk-1)
		if(ncells[kk-1] != 0)
			aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
			avesq = aveint[kk-1]*aveint[kk-1]
			aveisq = sig[kk-1]/ncells[kk-1]
			var = aveisq - avesq
			if (var <=0 )
				sig[kk-1] = 0
				sigave[kk-1] = 0
				ncells[kk-1] /=9
			else
				if(ncells[kk-1] > 9)
					sigave[kk-1] = sqrt(9*var/(ncells[kk-1]-9))
					sig[kk-1] = sqrt( abs(aveint[kk-1])/(ncells[kk-1]/9) )
					ncells[kk-1] /=9
				else
					sig[kk-1] = 0
					sigave[kk-1] = 0
					ncells[kk-1] /=9
				Endif
			Endif
		Endif
		kk+=1
	while(kk<=nphi)
	
	// data waves were defined as 200 points (=wavePts), but now have less than that (nphi) points
	// use DeletePoints to remove junk from end of waves
	Variable startElement,numElements
	startElement = nphi
	numElements = wavePts - startElement
	DeletePoints startElement,numElements, phival,aveint,ncells,sig,sigave
	
	//////////////end of VAX Phibin.for
		
	//angle dependent transmission correction is not done in phiave
	Ann_1D_Graph(aveint,phival,sigave)
	
	//get rid of the default mask, if one was created (it is in the current folder)
	//don't just kill "mask" since it might be pointing to the one in the MSK folder
	Killwaves/z $(destPath+":mask")
		
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return 0
End
