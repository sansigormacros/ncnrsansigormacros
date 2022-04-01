#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


// RTI clean


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
//	String fileStr = textread[3]
	
	// center of detector, for non-linear corrections
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY

	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
	
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
	
	// beam center, in pixels
	x0 = getDet_beam_center_x(type)
	y0 = getDet_beam_center_y(type)
	//detector calibration constants
	
//	WAVE calX=getDet_cal_x(type)
//	WAVE calY=getDet_cal_y(type)
	sx = getDet_x_pixel_size(type)		//mm/pixel (x)
	sx3 = 10000		//nonlinear coeff (10,000 turns correction "off"
	sy = getDet_y_pixel_size(type)		//mm/pixel (y)
	sy3 = 10000		//nonlinear coeff

	
	dtdist = 10*getDet_Distance(type)	// det distance in [mm] from [cm]
	
	
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
	Wave data = getDetectorDataW(type)		//this will be the linear data
	
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
						forward = s_distance(dxx,dyy,phi_x,phi_y,par)
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
	
	lambda = getWavelength(type)
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
	lambda = getWavelength(type)
	trans = getSampleTransmission(type)
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

	Variable L2 = getDet_Distance(type) / 100		// convert [cm] to [m] for N_getResolution
	Variable BS = getBeamStop_size(type)
	Variable S1 = getSourceAp_size(type)
	Variable S2 = getSampleAp_size(type)
	Variable L1 = getSourceAp_distance(type) / 100		// convert [cm] to [m] for N_getResolution
	lambda = getWavelength(type)
	Variable lambdaWidth = getWavelength_spread(type)
	
	// TODO -- this is HARD WIRED - not yet in header, always returns FALSE (0)
	Variable usingLenses=getAreLensesIn(type)

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current
	//good values

	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	
//	DDet = DetectorPixelResolution(fileStr,detStr)		//needs detector type and beamline
	//note that reading the detector pixel size from the header ASSUMES SQUARE PIXELS! - Jan2008
	DDet = getDet_x_pixel_size(type)/10			// header value (X) is in mm, want cm here
	
	//Width of annulus used for the average is gotten from the 
	//input dialog before.  This also must be passed to the resol
	//calculator. Currently the default is dr=1 so just keeping that.

	//Go from 0 to nq doing the calc for all three values at
	//every Q value

	ii=0

	Variable ret1,ret2,ret3
	do
		N_getResolution(qval[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,usingLenses,ret1,ret2,ret3)
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
Function s_distance(dxx,dyy,phi_x,phi_y,par)
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
Function AnnularAverageTo1D_old(type)
	String type
	
	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr
	
	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,dtsize,dtdist
	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,xbm,ybm,ii
	Variable rc,delr,rlo,rhi,dphi,nphi,dr
	Variable lambda,trans

	// center of detector, for non-linear corrections
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY

	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
		
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
	
	// beam center, in pixels
	x0 = getDet_beam_center_x(type)
	y0 = getDet_beam_center_y(type)
	//detector calibration constants
//	WAVE calX=getDet_cal_x(type)
//	WAVE calY=getDet_cal_y(type)
	sx = getDet_x_pixel_size(type)		//mm/pixel (x)
	sx3 = 10000		//nonlinear coeff (10,000 turns correction "off")
	sy = getDet_y_pixel_size(type)		//mm/pixel (y)
	sy3 = 10000		//nonlinear coeff
	
	dtdist = 10*getDet_Distance(type)	// det distance converted from [cm] to [mm]
	lambda = getWavelength(type)


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
	WAVE data = getDetectorDataW(type)

	//Check for the existence of the mask, if not, make one (local to this folder) that is null
	
	WAVE/Z mask = getDetectorDataW("MSK")
	if(WaveExists(mask) == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
		WAVE mask = $(destPath + ":mask")
		mask = 0
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



////////////////// NEW ANNULAR AVERAGE FOR TUBES
//



// TODO
// x- fix NVAR reference to step size
// x- duplicate/kill to rename waves at the end
// x- fix the panel to get input in delta Q, not delta pixels
// x- TEST



// JUL 2021 SRK
//
//
// x- fixed bug where for certain nPhi values, the last phi step would be deleted and n-1 steps
// were written to the file (JUL 2021)
//


// Procedures to do an annular binning of the data
//
// As for SANS, needs a Q-center and Q-delta to define the annular ring,
// and the number of bins to divide the 360 degree circle
//
// qWidth is +/- around the q-center
//
//
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
//Function AnnularAverageTo1D(folderStr,qCtr_Ann,qWidth)
Function AnnularAverageTo1D(folderStr)
	String folderStr
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj,kk
	Variable qVal,nq,var,avesq,aveisq
	Variable binIndex,val,isVCALC=0,maskMissing

	String folderPath = "root:Packages:NIST:"+folderStr
	String instPath = ":entry:instrument:detector"

	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr

	Variable qCtr_Ann = NumberByKey("QCENTER",keyListStr,"=",";")
	Variable qWidth = NumberByKey("QDELTA",keyListStr,"=",";")
	

// set up the waves for the output
//

	// -- nq may need to be larger, if annular averaging on the back detector, but n=600 seems to be OK

	nq = 600

// -- where to put the averaged data -- right now, folderStr is forced to ""	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $(folderPath+":"+"iPhiBin_qxqy")
//	Make/O/D/N=(nq)  $(folderPath+":"+"qBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $(folderPath+":"+"phiBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"nPhiBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"iPhiBin2_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"ePhiBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"ePhiBin2D_qxqy")
	
	Wave iPhiBin_qxqy = $(folderPath+":"+"iPhiBin_qxqy")
//	Wave qBin_qxqy = $(folderPath+":"+"qBin_qxqy"+"_"+type)
	Wave phiBin_qxqy = $(folderPath+":"+"phiBin_qxqy")
	Wave nPhiBin_qxqy = $(folderPath+":"+"nPhiBin_qxqy")
	Wave iPhiBin2_qxqy = $(folderPath+":"+"iPhiBin2_qxqy")
	Wave ePhiBin_qxqy = $(folderPath+":"+"ePhiBin_qxqy")
	Wave ePhiBin2D_qxqy = $(folderPath+":"+"ePhiBin2D_qxqy")
	
	
	Variable nphi,dphi,isIn,phiij,iphi

// DONE: define nphi (this is now set as a preference)
//	dr = 1 			//minimum annulus width, keep this fixed at one
	NVAR numPhiSteps = root:Packages:NIST:gNPhiSteps
	nphi = numPhiSteps		//number of anular sectors is set by users
	dphi = 360/nphi
	

	iPhiBin_qxqy = 0
	iPhiBin2_qxqy = 0
	ePhiBin_qxqy = 0
	ePhiBin2D_qxqy = 0
	nPhiBin_qxqy = 0	//number of intensities added to each bin


// (DONE):
// x- Solid_Angle -- waves will be present for WORK data other than RAW, but not for RAW
//
// assume that the mask files are missing unless we can find them. If VCALC data, 
//  then the Mask is missing by definition



	maskMissing=1

//	if(isVCALC)
//		WAVE inten = $(folderPath+instPath+"FL"+":det_"+detStr)
//		WAVE/Z iErr = $("iErr_"+detStr)			// 2D errors -- may not exist, especially for simulation			
//	else
		Wave inten = getDetectorDataW(folderStr)
		Wave iErr = getDetectorDataErrW(folderStr)
		Wave/Z mask = $("root:Packages:NIST:MSK:entry:instrument:detector:data")
		if(WaveExists(mask) == 1)
			maskMissing = 0
		endif
//	endif	
	Wave qTotal = $(folderPath+instPath+":qTot")			// 2D q-values	
	Wave qx = $(folderPath+instPath+":qx")			// 2D qx-values	
	Wave qy = $(folderPath+instPath+":qy")			// 2D qy-values	

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

	xDim=DimSize(inten,0)
	yDim=DimSize(inten,1)

	for(ii=0;ii<xDim;ii+=1)
		for(jj=0;jj<yDim;jj+=1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			qVal = qTotal[ii][jj]
			
			isIn = CloseEnough(qVal,qCtr_Ann,qWidth)
			
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



// I have more than nPhi points, so delete the rest
//
	Variable startElement,numElements
	startElement = nphi
	numElements = nq - startElement
	DeletePoints startElement,numElements, iPhiBin_qxqy,phiBin_qxqy,nPhiBin_qxqy,iPhiBin2_qxqy,ePhiBin_qxqy,ePhiBin2D_qxqy


	SetDataFolder folderPath
	
	Duplicate/O iPhiBin_qxqy, aveint
	Duplicate/O phiBin_qxqy, phival
	Duplicate/O ePhiBin_qxqy, sigave
	Duplicate/O nPhiBin_qxqy, nCells
	
	Killwaves/Z iPhiBin_qxqy,phiBin_qxqy,ePhiBin_qxqy
	//
	WAVE phival = $(folderPath + ":phival")
	WAVE aveint = $(folderPath + ":aveint")
	WAVE sigave = $(folderPath + ":sigave")


	//angle dependent transmission correction is not done in phiave
	Ann_1D_Graph(aveint,phival,sigave)
	
	SetDataFolder root:
	
	return(0)
End




// 
// x- I want to mask out everything that is "out" of the annulus
//
// 0 = keep the point
// 1 = yes, mask the point
Function MarkAnnularOverlayPixels(qTotal,overlay,qCtr_ann,qWidth)
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
			if(CloseEnough(qval,qCtr_ann,qWidth))
				exclude = 0
			endif
			
			// set the mask value
			overlay[ii][jj] = exclude
		endfor
	endfor


	return(0)
End

