#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// RTI clean

//*********************************************
//		For AVERAGE and for DRAWING
//			DRAWING routines only use a subset of the total list, since saving, naming, etc. don't apply
//		(10) possible keywords, some numerical, some string values
//		AVTYPE=string		string from set {Circular,Annular,Rectangular,Sector,2D_ASCII,QxQy_ASCII,PNG_Graphic}
//		PHI=value			azimuthal angle (-90,90)
//		DPHI=value			+/- angular range around phi for average
//		WIDTH=value		total width of rectangular section, in pixels
//		SIDE=string		string from set {left,right,both} **note NOT capitalized
//		QCENTER=value		q-value (1/A) of center of annulus for annular average
//		QDELTA=value		total width of annulus centered at QCENTER
//		PLOT=string		string from set {Yes,No} = truth of generating plot of averaged data
//		SAVE=string		string from set {Yes,No} = truth of saving averaged data to disk
//		NAME=string		string from set {Auto,Manual} = Automatic name generation or Manual(dialog)
//***********************************************


// this function also does sector averaging 
//the parameters in the global keyword-string must have already been set somewhere
//either directly, from the protocol, or from the Average_Panel
//** the keyword-list has already been "pre-parsed" to send only Circular or Sector
//averages to this routine. Rectangular or annular averages get done elsewhere
// TYPE parameter determines which data folder to work from
//
//annnulus (step) size is currently fixed at 1 (variable dr, below)
//Function CircularAverageTo1D(type)
Function CircularAverageTo1D_old(type)
	String type

	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr		//this is the list that has it all
	Variable isCircular = 0
	
	if( cmpstr("Circular",StringByKey("AVTYPE",keyListStr,"=",";")) ==0)
		isCircular = 1		//set a switch for later
	Endif
	
	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	
	//
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,dtsize,dtdist,dr,ddr
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
	sx = getDet_x_pixel_size(type)		//mm/pixel (x)
	sx3 = 10000		//nonlinear coeff !! HARD-WIRED (10,000 == "off")
	sy = getDet_y_pixel_size(type)	//mm/pixel (y)
	sy3 = 10000		//nonlinear coeff !! HARD-WIRED
	
	dtsize = 10*(pixelsX*sx)		//det size in mm
	dtdist = 10*getDet_Distance(type)		// det distance in [mm] from [cm]
	
	NVAR binWidth=root:Packages:NIST:gBinWidth
	
	dr = binWidth		// ***********annulus width set by user, default is one***********
	ddr = dr*sx		//step size, in mm (this value should be passed to the resolution calculation, not dr 18NOV03)
		
	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,dxbm,dybm,ii
	Variable phi_rad,dphi_rad,phi_x,phi_y
	Variable forward,mirror
	
	String side = StringByKey("SIDE",keyListStr,"=",";")
//	Print "side = ",side
	
	if(!isCircular)		//must be sector avg (rectangular not sent to this function)
		//convert from degrees to radians
		phi_rad = (Pi/180)*NumberByKey("PHI",keyListStr,"=",";")
		dphi_rad = (Pi/180)*NumberByKey("DPHI",keyListStr,"=",";")
		//create cartesian values for unit vector in phi direction
		phi_x = cos(phi_rad)
		phi_y = sin(phi_rad)
	Endif
	
	/// data wave is data in the current folder which was set at the top of the function
	WAVE data=getDetectorDataW(type)
	//Check for the existence of the mask, if not, make one (local to this folder) that is null

	WAVE/Z mask = getDetectorDataW("MSK")
	if(WaveExists(mask) == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
		Wave mask = $(destPath + ":mask")
		mask = 0
	Endif
	
	//
	//pixels within rcentr of beam center are broken into 9 parts (units of mm)
	rcentr = 100		//original
//	rcentr = 0
	// values for error if unable to estimate value
	//large_num = 1e10
	large_num = 1		//1e10 value (typically sig of last data point) plots poorly, arb set to 1
	small_num = 1e-10
	
	// output wave are expected to exist (?) initialized to zero, what length?
	// 200 points on VAX --- use 300 here, or more if SAXS data is used with 1024x1024 detector (1000 pts seems good)
	Variable defWavePts=500
	Make/O/N=(defWavePts) $(destPath + ":qval"),$(destPath + ":aveint")
	Make/O/N=(defWavePts) $(destPath + ":ncells"),$(destPath + ":dsq"),$(destPath + ":sigave")
	Make/O/N=(defWavePts) $(destPath + ":SigmaQ"),$(destPath + ":fSubS"),$(destPath + ":QBar")

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
	Variable dr2,nd,fd,nd2,ll,kk,dxx,dyy,ir,dphi_p
	
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
			if(!(mask[ii-1][jj-1]))			//masked pixels = 1, skip if masked (this way works...)
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
						if(isCircular)
							//circular average, use all pixels
							//(increment) 
							nq = IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
						else
							//a sector average - determine azimuthal angle
							dphi_p = dphi_pixel(dxx,dyy,phi_x,phi_y)
							if(dphi_p < dphi_rad)
								forward = 1			//within forward sector
							else
								forward = 0
							Endif
							if((Pi - dphi_p) < dphi_rad)
								mirror = 1		//within mirror sector
							else
								mirror = 0
							Endif
							//check if pixel lies within allowed sector(s)
							if(cmpstr(side,"both")==0)		//both sectors
								if ( mirror || forward)
									//increment
									nq = IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
								Endif
							else
								if(cmpstr(side,"right")==0)		//forward sector only
									if(forward)
										//increment
										nq = IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
									Endif
								else			//mirror sector only
									if(mirror)
										//increment
										nq = IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
									Endif
								Endif
							Endif		//allowable sectors
						Endif	//circular or sector check
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
	// data waves were defined as 300 points (=defWavePts), but now have less than that (nq) points
	// use DeletePoints to remove junk from end of waves
	//WaveStats would be a more foolproof implementation, to get the # points in the wave
	Variable startElement,numElements
	startElement = nq
	numElements = defWavePts - startElement
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
//	uval = -ln(trans)		//use natural logarithm
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

// ***************************************************************
//
// Do the extra 3 columns of resolution calculations starting here.
//
// ***************************************************************

	Variable L2 = getDet_Distance(type) / 100		// N_getResolution is expecting [m]
	Variable BS = getBeamStop_size(type)
	Variable S1 = getSourceAp_size(type)
	Variable S2 = getSampleAp_size(type)
	Variable L1 = getSourceAp_distance(type) / 100 // N_getResolution is expecting [m]
	lambda = getWavelength(type)
	Variable lambdaWidth = getWavelength_spread(type)
	String detStr=getDetDescription(type)
	
	Variable usingLenses = 0		//

	if(cmpstr(getLensPrismStatus(type),"out") == 0 )		// TODO -- this read function is HARD-WIRED
		// lenses and prisms are out
		usingLenses = 0
	else
		usingLenses = 1
	endif
	
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
	//input dialog before.  This also must be passed to the resolution
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

// End of resolution calculations
// ***************************************************************
	
	//Plot the data in the Plot_1d window
	Avg_1D_Graph(aveint,qval,sigave)

	//get rid of the default mask, if one was created (it is in the current folder)
	//don't just kill "mask" since it might be pointing to the one in the MSK folder
	Killwaves/Z $(destPath+":mask")
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return 0
End

//returns nq, new number of q-values
//arrays aveint,dsq,ncells are also changed by this function
//
Function IncrementPixel(dataPixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
	Variable dataPixel,ddr,dxx,dyy
	Wave aveint,dsq,ncells
	Variable nq,nd2
	
	Variable ir
	
	ir = trunc(sqrt(dxx*dxx+dyy*dyy)/ddr)+1
	if (ir>nq)
		nq = ir		//resets maximum number of q-values
	endif
	aveint[ir-1] += dataPixel/nd2		//ir-1 must be used, since ir is physical
	dsq[ir-1] += dataPixel*dataPixel/nd2
	ncells[ir-1] += 1/nd2
	
	Return nq
End

//function determines azimuthal angle dphi that a vector connecting
//center of detector to pixel makes with respect to vector
//at chosen azimuthal angle phi -> [cos(phi),sin(phi)] = [phi_x,phi_y]
//dphi is always positive, varying from 0 to Pi
//
Function dphi_pixel(dxx,dyy,phi_x,phi_y)
	Variable dxx,dyy,phi_x,phi_y
	
	Variable val,rr,dot_prod
	
	rr = sqrt(dxx^2 + dyy^2)
	dot_prod = (dxx*phi_x + dyy*phi_y)/rr
	//? correct for roundoff error? - is this necessary in IGOR, w/ double precision?
	if(dot_prod > 1)
		dot_prod =1
	Endif
	if(dot_prod < -1)
		dot_prod = -1
	Endif
	
	val = acos(dot_prod)
	
	return val

End

//calculates the x distance from the center of the detector, w/nonlinear corrections
//
Function FX(xx,sx3,xcenter,sx)		
	Variable xx,sx3,xcenter,sx
	
	Variable retval
	
	retval = sx3*tan((xx-xcenter)*sx/sx3)
	Return retval
End

//calculates the y distance from the center of the detector, w/nonlinear corrections
//
Function FY(yy,sy3,ycenter,sy)		
	Variable yy,sy3,ycenter,sy
	
	Variable retval
	
	retval = sy3*tan((yy-ycenter)*sy/sy3)
	Return retval
End

//old function not called anymore, now "ave" button calls routine from AvgGraphics.ipf
//to get input from panel rather than large prompt for missing parameters
Function Ave_button(button0) : ButtonControl
	String button0

	// the button on the graph will average the currently displayed data
	SVAR type=root:myGlobals:gDataDisplayType
	
	//Check for logscale data in "type" folder
	SetDataFolder "root:Packages:NIST:"+type		//use the full path, so it will always work
	String dest = "root:Packages:NIST:" + type
	
	NVAR isLogScale = $(dest + ":gIsLogScale")
	if(isLogScale == 1)
		//data is logscale, convert it back and reset the global
		Duplicate/O $(dest + ":linear_data") $(dest + ":data")
//		WAVE vlegend=$(dest + ":vlegend")
	//  Make the color table linear scale
//		vlegend = y
		Variable/G $(dest + ":gIsLogScale") = 0		//copy to keep with the current data folder
		SetDataFolder root:
		//rename the button to reflect "isLin" - the displayed name must have been isLog
		Button bisLog,title="isLin",rename=bisLin
	Endif

	//set data folder back to root
	SetDataFolder root:
	
	//do the average - ask the user for what type of average
	//ask the user for averaging paramters
	Execute "GetAvgInfo()"
	
	//dispatch to correct averaging routine
	//if you want to save the files, see Panel_DoAverageButtonProc(ctrlName) function
	//for making a fake protocol (needed to write out data)
	SVAR tempStr = root:myGlobals:Protocols:gAvgInfoStr
	String choice = StringByKey("AVTYPE",tempStr,"=",";")
	if(cmpstr("Rectangular",choice)==0)
		//dispatch to rectangular average
		RectangularAverageTo1D(type)
	else
		if(cmpstr("Annular",choice)==0)
			AnnularAverageTo1D(type)
		else
			//circular or sector
			CircularAverageTo1D(type)
		Endif
	Endif
	
	Return 0
End



// -- seems to work, now I need to give it a name, add it to the list, and 
// make sure I've thought of all of the cases - then the average can be passed as case "Sector_PlusMinus"
// and run through the normal average and writing routines.
//
//
// -- depending on what value PHI has - it's [-90,90] "left" and "right" may not be what
// you expect. so sorting the concatenated values may be necessary (always)
//
// -- need documentation of the definition of PHI, left, and right so that it can make better sense
//		which quadrants of the detector become "negative" depending on the choice of phi. may need a 
//		switch after a little thinking.
//
// may want a variation of this where both sides are done, in separate files. but I think that's already
// called a "sector" average. save them. load them. plot them.
//
//
Function Sector_PlusMinus1D(type)
	String type

//	do the left side (-)
// then hold that data in tmp_ waves
// then do the right (+)
// then concatenate the data

// the button on the pink panel copies the two strings so they're the same
	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr		//this is the list that has it all

	String oldStr = ""
	String	CurPath="root:myGlobals:Plot_1D:"
	String destPath = "root:Packages:NIST:"+type+":"

	oldStr = StringByKey("SIDE",keyListStr,"=",";")

// do the left first, and call it negative
	keyListStr = ReplaceStringByKey("SIDE",keyListStr,"left","=",";")

	CircularAverageTo1D(type)
	
	WAVE qval = $(destPath + "qval")
	WAVE aveint = $(destPath + "aveint")
	WAVE sigave = $(destPath + "sigave")
	WAVE qbar = $(destPath + "QBar")
	WAVE sigmaq = $(destPath + "SigmaQ")
	WAVE fsubs = $(destPath + "fSubS")

	// copy the average, set the q's negative
	qval *= -1
	Duplicate/O qval $(destPath+"tmp_q")
	Duplicate/O aveint $(destPath+"tmp_i")
	Duplicate/O sigave $(destPath+"tmp_s")
	Duplicate/O qbar $(destPath+"tmp_qb")
	Duplicate/O sigmaq $(destPath+"tmp_sq")
	Duplicate/O fsubs $(destPath+"tmp_fs")
	
	
// do the right side
	keyListStr = ReplaceStringByKey("SIDE",keyListStr,"right","=",";")

	CircularAverageTo1D(type)
	
	// concatenate
	WAVE tmp_q = $(destPath + "tmp_q")
	WAVE tmp_i = $(destPath + "tmp_i")
	WAVE tmp_s = $(destPath + "tmp_s")
	WAVE tmp_qb = $(destPath + "tmp_qb")
	WAVE tmp_sq = $(destPath + "tmp_sq")
	WAVE tmp_fs = $(destPath + "tmp_fs")

	SetDataFolder destPath		//to get the concatenation in the right folder
	Concatenate/NP/O {tmp_q,qval},tmp_cat
	Duplicate/O tmp_cat qval
	Concatenate/NP/O {tmp_i,aveint},tmp_cat
	Duplicate/O tmp_cat aveint
	Concatenate/NP/O {tmp_s,sigave},tmp_cat
	Duplicate/O tmp_cat sigave
	Concatenate/NP/O {tmp_qb,qbar},tmp_cat
	Duplicate/O tmp_cat qbar
	Concatenate/NP/O {tmp_sq,sigmaq},tmp_cat
	Duplicate/O tmp_cat sigmaq
	Concatenate/NP/O {tmp_fs,fsubs},tmp_cat
	Duplicate/O tmp_cat fsubs

// then sort
	Sort qval, qval,aveint,sigave,qbar,sigmaq,fsubs

// move these to the Plot_1D folder for plotting
	Duplicate/O qval $(curPath+"xAxisWave")
	Duplicate/O aveint $(curPath+"yAxisWave")
	Duplicate/O sigave $(curPath+"yErrWave")
	
	keyListStr = ReplaceStringByKey("SIDE",keyListStr,oldStr,"=",";")

	DoUpdate/W=Plot_1d
	
	// clean up
	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_qb,tmp_sq,tmp_fs,tmp_cat
	
	SetDataFolder root:
	
	return(0)
End



//////////////// new averaging for TUBES on 10m SANS
// since they are referenced as mm positions, not strictly pixels
//


//////////
//
//		Function that bins a 2D detctor panel into I(q) based on the q-value of the pixel
//		- each pixel QxQyQz has been calculated beforehand
//
// this replaces the older version of CircularAverageTo1D() which was pixel-based.
// -- the tube detctectors are properly described in real-space, so the old methods
//   of IncrementPixels() did not make sense.
//
//Function CircularAverageTo1D_new(type)
Function CircularAverageTo1D(type)
	String type
	
	Variable xDim,yDim
	Variable ii,jj
	Variable qVal_i,nq,var,avesq,aveisq
	Variable binIndex,val,maskMissing

	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	String instrPath = ":entry:instrument:detector:"

	NVAR binWidth=root:Packages:NIST:gBinWidth

	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr		//this is the list that has it all
	Variable isCircular = 0
	
	if( cmpstr("Circular",StringByKey("AVTYPE",keyListStr,"=",";")) ==0)
		isCircular = 1		//set a switch for later
	Endif
	
//
// assume that the mask files are missing unless we can find them. If VCALC data, 
//  then the Mask is missing by definition
	maskMissing = 1

//	if(isVCALC)
//		WAVE inten = $(folderPath+instPath+detStr+":det_"+detStr)
//		WAVE/Z iErr = $("iErr_"+detStr)			// 2D errors -- may not exist, especially for simulation		
//	else
		Wave inten = getDetectorDataW(type)
		Wave iErr = getDetectorDataErrW(type)
//	endif
	WAVE/Z mask = getDetectorDataW("MSK")
	if(WaveExists(mask) == 1)
		maskMissing = 0
	endif
	
	SetDeltaQ(type)

	NVAR delQ = $(destPath+instrPath+"gDelQ")
	Wave qTotal = $(destPath+instrPath+"qTot")			// 2D q-values	
			
//	Print "delQ = ",delQ," for ",type


// RAW data is currently read in and the 2D error wave is correctly generated
// 2D error is propagated through all reduction steps, but I have not 
// verified that it is an exact duplication of the 1D error
//
//
//
// IF there is no 2D error wave present for some reason, make a fake one
	if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// (DONE) -- here I'm just using some fictional value
	endif

	Variable defWavePts=500
	nq=defWavePts
	

//******(DONE) averaged data stored in the (type) data folder-- right now, folderStr is forced to ""	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $(destPath+":"+"iBin_qxqy")
	Make/O/D/N=(nq)  $(destPath+":"+"qBin_qxqy")
	Make/O/D/N=(nq)  $(destPath+":"+"nBin_qxqy")
	Make/O/D/N=(nq)  $(destPath+":"+"iBin2_qxqy")
	Make/O/D/N=(nq)  $(destPath+":"+"eBin_qxqy")
	Make/O/D/N=(nq)  $(destPath+":"+"eBin2D_qxqy")
	
	Wave iBin_qxqy = $(destPath+":"+"iBin_qxqy")
	Wave qBin_qxqy = $(destPath+":"+"qBin_qxqy")
	Wave nBin_qxqy = $(destPath+":"+"nBin_qxqy")
	Wave iBin2_qxqy = $(destPath+":"+"iBin2_qxqy")
	Wave eBin_qxqy = $(destPath+":"+"eBin_qxqy")
	Wave eBin2D_qxqy = $(destPath+":"+"eBin2D_qxqy")
	
	
//
// (DONE): not sure if I want to set dQ in x or y direction..
// -- delQ is set from a global value for each panel. delQ is found as the q-Width of the 
// lateral direction of the innermost tube on the panel.
//
// delQ can further be modified by the global preference of step size (default is 1.2)
//
	qBin_qxqy[] =  p*delQ	
	SetScale/P x,0,delQ,"",qBin_qxqy		//allows easy binning

	iBin_qxqy = 0
	iBin2_qxqy = 0
	eBin_qxqy = 0
	eBin2D_qxqy = 0
	nBin_qxqy = 0	//number of intensities added to each bin

//
// The 1D error does not use iErr, and IS CALCULATED CORRECTLY
//
// x- the solid angle per pixel will be present for WORK data other than RAW, but not for RAW

//
// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
	if(maskMissing == 1)
		Print "Mask file not found - so all data is used"
	endif
	
	Variable mask_val

	xDim=DimSize(inten,0)
	yDim=DimSize(inten,1)

	for(ii=0;ii<xDim;ii+=1)
		for(jj=0;jj<yDim;jj+=1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			qVal_i = qTotal[ii][jj]
			binIndex = trunc(x2pnt(qBin_qxqy, qVal_i))
			val = inten[ii][jj]
			
//				if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
			if(maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
				mask_val = 0
			else
				mask_val = mask[ii][jj]
			endif
			if (numType(val)==0 && mask_val == 0)		//count only the good points, ignore Nan or Inf
				iBin_qxqy[binIndex] += val
				iBin2_qxqy[binIndex] += val*val
				eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
				nBin_qxqy[binIndex] += 1
			endif
		endfor
	endfor
		

// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf
// TODO:
// -- 2D Errors were (maybe) properly acculumated through reduction, so this loop of calculations is NOT VERIFIED (yet)
// x- the error on the 1D intensity, is correctly calculated as the standard error of the mean.
	for(ii=0;ii<nq;ii+=1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii] = 0
			eBin_qxqy[ii] = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				eBin_qxqy[ii] = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				//  -- this is correctly calculating the error as the standard error of the mean, as
				//    was always done for SANS as well.
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq = iBin_qxqy[ii]^2
				aveisq = iBin2_qxqy[ii]/nBin_qxqy[ii]
				var = aveisq-avesq
				if(var<=0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var/(nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor
	
	eBin2D_qxqy = sqrt(eBin2D_qxqy)		// as equation (3) of John's memo
	
	// find the last non-zero point, working backwards
	val=nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)
	
//	print val, nBin_qxqy[val]
	DeletePoints val, nq-val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	if(val == 0)
		// all the points were deleted
		return(0)
	endif
	
	
	// just in case, find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)	
	DeletePoints 0, val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy)-1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy
		endif
		val -= 1
	while(val>0)

// utility function to remove NaN values from the waves
//	V_RemoveNaNsQIS(qBin_qxqy, iBin_qxqy, eBin_qxqy)

	
	// TODO:
	// -- This is where I calculate the resolution in SANS (see CircSectAve)
	// -- from the top of the function, type = work folder
	//
	nq = numpnts(qBin_qxqy)
	Make/O/D/N=(nq)  $(destPath+":"+"sigmaQ")
	Make/O/D/N=(nq)  $(destPath+":"+"qBar")
	Make/O/D/N=(nq)  $(destPath+":"+"fSubS")
	Wave sigmaq = $(destPath+":"+"sigmaQ")
	Wave qbar = $(destPath+":"+"qBar")
	Wave fsubs = $(destPath+":"+"fSubS")

// ***************************************************************
//
// Do the extra 3 columns of resolution calculations starting here.
//
// ***************************************************************

	//angle dependent transmission correction 
	Variable uval,arg,cos_th
	Variable lambda,trans
	trans = getSampleTransmission(type)
	
	
	Variable L2 = getDet_Distance(type) / 100		// N_getResolution is expecting [m]
	Variable BS = getBeamStop_size(type)
	Variable S1 = getSourceAp_size(type)
	Variable S2 = getSampleAp_size(type)
	Variable L1 = getSourceAp_distance(type) / 100 // N_getResolution is expecting [m]
	lambda = getWavelength(type)
	Variable lambdaWidth = getWavelength_spread(type)
	String detStr=getDetDescription(type)
	
	Variable usingLenses = 0		//

	if(cmpstr(getLensPrismStatus(type),"out") == 0 )		// TODO -- this read function is HARD-WIRED
		// lenses and prisms are out
		usingLenses = 0
	else
		usingLenses = 1
	endif
	
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
	//input dialog before.  This also must be passed to the resolution
	//calculator. Currently the default is dr=1 so just keeping that.

	//Go from 0 to nq doing the calc for all three values at
	//every Q value

	ii=0

	Variable ret1,ret2,ret3,ddr
	
	ddr = binWidth*getDet_x_pixel_size(type)		// step size, in [mm]
	do
		N_getResolution(qBin_qxqy[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,usingLenses,ret1,ret2,ret3)
		sigmaq[ii] = ret1	
		qbar[ii] = ret2	
		fsubs[ii] = ret3	
		ii+=1
	while(ii<nq)

// End of resolution calculations
// ***************************************************************

// now -- rename all of the waves to names that SANS is expecting, since this calculation was
// taken from VSANS
// -- resolution waves were named correctly as they were generated above
//

// can't rename if they exist, duplicate/kill steps work

	SetDataFolder destPath
	
	Duplicate/O iBin_qxqy,aveint
	Duplicate/O qBin_qxqy,qval
	Duplicate/O nBin_qxqy,ncells
	Duplicate/O eBin_qxqy,sigave
	Duplicate/O iBin2_qxqy,dsq

	WAVE qval = $(destPath + ":qval")
	WAVE aveint = $(destPath + ":aveint")
	WAVE sigave = $(destPath + ":sigave")	
	
	//Plot the data in the Plot_1d window
	Avg_1D_Graph(aveint,qval,sigave)
	
	KillWaves/Z iBin_qxqy,iBin_qxqy,qBin_qxqy,nBin_qxqy,eBin_qxqy,iBin2_qxqy
	

	SetDataFolder root:
	
	return(0)
End




//
// updated to new folder structure Feb 2016
// folderStr = RAW,SAM, VCALC or other
//
Function SetDeltaQ(folderStr)
	String folderStr

	NVAR binWidth=root:Packages:NIST:gBinWidth

	
	String folderPath = "root:Packages:NIST:"+folderStr
	String instPath = ":entry:instrument:detector:"

// root:Packages:NIST:RAW:entry:instrument:detector:qx
		
	Wave qx = $(folderPath+instPath+"qx")
	Wave qy = $(folderPath+instPath+"qy")
	
	Variable xDim,yDim,delQ
	
	// q-step laterally across the vertical tubes
		delQ = abs(qx[0][0] - qx[1][0])/2

	// multiply the deltaQ by the binWidth (=multiple of pixels)
	// this defaults to 1.2, and is set in VSANS preferences
	delQ *= binWidth
	
	// set the global
	Variable/G $(folderPath+instPath+"gDelQ") = delQ
//	Print "SET delQ = ",delQ," for ",type
	
	return(delQ)
end


/////
//////////SECTOR AVERAGING
//////////////////////////////////////////////////////////////

//
// routines to do a sector average
//


// Sector definition is passed in through a global string
//
// side = one of "left;right;both;"
// phi_rad = center of sector in radians
// dphi_rad = half-width of sector, also in radians
//
Function SectorAverageTo1D(folderStr)
	String folderStr

	String side
	Variable phi_rad,dphi_rad
	Variable delQ

	// set delta Q for binning (used later inside VC_fDoBinning_QxQy2D)
		
	delQ = SetDeltaQ(folderStr)		// this sets (overwrites) the global value
	

	SVAR keyListStr = root:myGlobals:Protocols:gAvgInfoStr		//this is the list that has it all

//	Variable phi_x,phi_y
	
	side = StringByKey("SIDE",keyListStr,"=",";")
	
	//convert from degrees to radians
	phi_rad = (Pi/180)*NumberByKey("PHI",keyListStr,"=",";")
	dphi_rad = (Pi/180)*NumberByKey("DPHI",keyListStr,"=",";")
	
//	//create cartesian values for unit vector in phi direction
//	phi_x = cos(phi_rad)
//	phi_y = sin(phi_rad)

	fDoSectorBin_QxQy2D(folderStr,side,phi_rad,dphi_rad)

	return(0)
End


//////////
//
//		Function that bins a 2D detctor panel into I(q) based on the q-value of the pixel
//		- each pixel QxQyQz has been calculated beforehand
//		- if multiple panels are selected to be combined, it is done here during the binning
//		- the setting of deltaQ step is still a little suspect (TODO)
//
//
// see the equivalent function in PlotUtils2D_v40.ipf
//
//Function fDoBinning_QxQy2D(inten,qx,qy,qz)
//
//
//  "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
//
// updated Feb2016 to take new folder structure
// (DONE)
// x- VERIFY
// x- figure out what the best location is to put the averaged data? currently @ top level of WORK folder
//    but this is a lousy choice.
// x- binning is now Mask-aware. If mask is not present, all data is used. If data is from VCALC, all data is used
// x- Where do I put the solid angle correction? In here as a weight for each point, or later on as 
//    a blanket correction (matrix multiply) for an entire panel? (Solid Angle correction is done in the
//    step where data is added to a WORK file (see Raw_to_Work())
//
//
// TODO:
// -- some of the input parameters for the resolution calcuation are either assumed (apOff) or are currently
//    hard-wired. these need to be corrected before even the pinhole resolution is correct
// x- resolution calculation is in the correct place. The calculation is done per-panel (specified by TYPE),
//    and then the unwanted points can be discarded (all 6 columns) as the data is trimmed and concatenated
//    is separate functions that are resolution-aware.
//
//
// folderStr = WORK folder, type = the binning type (may include multiple detectors)
//
// side = one of "left;right;both;"
// phi_rad = center of sector in radians
// dphi_rad = half-width of sector, also in radians
//
Function fDoSectorBin_QxQy2D(folderStr,side,phi_rad,dphi_rad)
	String folderStr,side
	Variable phi_rad,dphi_rad
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj
	Variable qVal_i,nq,var,avesq,aveisq
	Variable binIndex,val,isVCALC=0,maskMissing

	String folderPath = "root:Packages:NIST:"+folderStr
	String instPath = ":entry:instrument:detector"
	String detStr
		

// assume that the mask files are missing unless we can find them. If VCALC data, 
//  then the Mask is missing by definition
	maskMissing = 1

	
//	if(isVCALC)
//		WAVE inten = $(folderPath+instPath+detStr+":det_"+detStr)
//		WAVE/Z iErr = $("iErr_"+detStr)			// 2D errors -- may not exist, especially for simulation		
//	else
		Wave inten = getDetectorDataW(folderStr)
		Wave iErr = getDetectorDataErrW(folderStr)
		Wave/Z mask = $("root:Packages:NIST::MSK:entry:instrument:detector:data")
		if(WaveExists(mask) == 1)
			maskMissing = 0
		endif
//	endif	
	NVAR delQ = $(folderPath+instPath+":gDelQ")
	Wave qTotal = $(folderPath+instPath+":qTot")			// 2D q-values	
	Wave phi = MakePhiMatrix(qTotal,folderStr,folderPath+instPath)
//	nSets = 1
//	break	
			



// RAW data is currently read in and the 2D error wave is correctly generated
// 2D error is propagated through all reduction steps, 
//
//
// IF ther is no 2D error wave present for some reason, make a fake one
	if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// -- here I'm just using some fictional value
	endif


	nq=500

// -- where to put the averaged data -- right now, folderStr is forced to ""	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $(folderPath+":"+"iBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"qBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"nBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"iBin2_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"eBin_qxqy")
	Make/O/D/N=(nq)  $(folderPath+":"+"eBin2D_qxqy")
	
	Wave iBin_qxqy = $(folderPath+":"+"iBin_qxqy")
	Wave qBin_qxqy = $(folderPath+":"+"qBin_qxqy")
	Wave nBin_qxqy = $(folderPath+":"+"nBin_qxqy")
	Wave iBin2_qxqy = $(folderPath+":"+"iBin2_qxqy")
	Wave eBin_qxqy = $(folderPath+":"+"eBin_qxqy")
	Wave eBin2D_qxqy = $(folderPath+":"+"eBin2D_qxqy")
	
	
	qBin_qxqy[] =  p*delQ	
	SetScale/P x,0,delQ,"",qBin_qxqy		//allows easy binning

	iBin_qxqy = 0
	iBin2_qxqy = 0
	eBin_qxqy = 0
	eBin2D_qxqy = 0
	nBin_qxqy = 0	//number of intensities added to each bin

//
//
// The 1D error does not use iErr, and IS CALCULATED CORRECTLY
//
// x- the solid angle per pixel will be present for WORK data other than RAW, but not for RAW

//
// if any of the masks don't exist, display the error, and proceed with the averaging, using all data
	if(maskMissing == 1)
		Print "Mask file not found for at least one detector - so all data is used"
	endif
	


	Variable mask_val,phiVal,isIn

	xDim=DimSize(inten,0)
	yDim=DimSize(inten,1)

	for(ii=0;ii<xDim;ii+=1)
		for(jj=0;jj<yDim;jj+=1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			qVal_i = qTotal[ii][jj]
			binIndex = trunc(x2pnt(qBin_qxqy, qVal_i))
			val = inten[ii][jj]
			
			if(isVCALC || maskMissing)		// mask_val == 0 == keep, mask_val == 1 = YES, mask out the point
				mask_val = 0
			else
				mask_val = mask[ii][jj]
			endif
			
			phiVal = phi[ii][jj]
			isIn = 0			// start with exclude, now see if it's a keeper
					
			// if within the right or left, flag to keep the pixel
			if(cmpstr(side,"right")==0)
				//right, when 0->pi/2
				if(CloseEnough(phiVal,phi_rad,dphi_rad))
					isIn = 1
				endif
				// condition here to get the 3pi/2 -> 2pi region
				if(CloseEnough(phiVal,phi_rad+2*pi,dphi_rad))
					isIn = 1
				endif
			endif
			
			if(cmpstr(side,"left")==0)
				if(CloseEnough(phiVal,phi_rad+pi,dphi_rad))
					isIn = 1
				endif
			endif
						
		//	both sides, duplicates the conditions above
			if(cmpstr(side,"both")==0)	
				//right, when 0->pi/2
				if(CloseEnough(phiVal,phi_rad,dphi_rad))
					isIn = 1
				endif
				// right, when 3pi/2 -> 2pi
				if(CloseEnough(phiVal,phi_rad+2*pi,dphi_rad))
					isIn = 1
				endif				
				
				//left
				if(CloseEnough(phiVal,phi_rad+pi,dphi_rad))
					isIn = 1
				endif
				
			endif		//end the check of phiVal within sector and side
			
	
			if (numType(val)==0 && mask_val == 0 && isIn > 0)		//count only the good points, in the sector, and ignore Nan or Inf
				iBin_qxqy[binIndex] += val
				iBin2_qxqy[binIndex] += val*val
				eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
				nBin_qxqy[binIndex] += 1
			endif
			
			
		endfor
	endfor
		

// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf

// x- 2D Errors are properly acculumated through reduction
// x- the error on the 1D intensity, is correctly calculated as the standard error of the mean.
	for(ii=0;ii<nq;ii+=1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii] = 0
			eBin_qxqy[ii] = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				eBin_qxqy[ii] = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				//  -- this is correctly calculating the error as the standard error of the mean, as
				//    was always done for SANS as well.
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq = iBin_qxqy[ii]^2
				aveisq = iBin2_qxqy[ii]/nBin_qxqy[ii]
				var = aveisq-avesq
				if(var<=0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var/(nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor
	
	eBin2D_qxqy = sqrt(eBin2D_qxqy)		// as equation (3) of John's memo
	
	// find the last non-zero point, working backwards
	val=nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)
	
//	print val, nBin_qxqy[val]
	DeletePoints val, nq-val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	if(val == 0)
		// all the points were deleted, make dummy waves for resolution
		Make/O/D/N=0  $(folderPath+":"+"sigmaQ")
		Make/O/D/N=0  $(folderPath+":"+"qBar")
		Make/O/D/N=0  $(folderPath+":"+"fSubS")
		return(0)
	endif
	
	
	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)	
	DeletePoints 0, val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy)-1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy
		endif
		val -= 1
	while(val>0)

// utility function to remove NaN values from the waves
//
//	V_RemoveNaNsQIS(qBin_qxqy, iBin_qxqy, eBin_qxqy)
//
	
	// -- This is where I calculate the resolution in SANS (see CircSectAve)
	// -- use the isVCALC flag to exclude VCALC from the resolution calculation if necessary
	// -- from the top of the function, folderStr = work folder, type = "FLRTB" or other type of averaging
	//
	nq = numpnts(qBin_qxqy)
	Make/O/D/N=(nq)  $(folderPath+":"+"sigmaQ")
	Make/O/D/N=(nq)  $(folderPath+":"+"qBar")
	Make/O/D/N=(nq)  $(folderPath+":"+"fSubS")
	Wave sigmaq = $(folderPath+":"+"sigmaQ")
	Wave qbar = $(folderPath+":"+"qBar")
	Wave fsubs = $(folderPath+":"+"fSubS")


// ***************************************************************
//
// Do the extra 3 columns of resolution calculations starting here.
//
// ***************************************************************

	//angle dependent transmission correction 
	Variable uval,arg,cos_th
	Variable lambda,trans
	trans = getSampleTransmission(folderStr)
	
	
	Variable L2 = getDet_Distance(folderStr) / 100		// N_getResolution is expecting [m]
	Variable BS = getBeamStop_size(folderStr)
	Variable S1 = getSourceAp_size(folderStr)
	Variable S2 = getSampleAp_size(folderStr)
	Variable L1 = getSourceAp_distance(folderStr) / 100 // N_getResolution is expecting [m]
	lambda = getWavelength(folderStr)
	Variable lambdaWidth = getWavelength_spread(folderStr)
	
	Variable usingLenses = 0		//

	if(cmpstr(getLensPrismStatus(folderStr),"out") == 0 )		// TODO -- this read function is HARD-WIRED
		// lenses and prisms are out
		usingLenses = 0
	else
		usingLenses = 1
	endif



	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current
	//good values

	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	
//	DDet = DetectorPixelResolution(fileStr,detStr)		//needs detector type and beamline
	//note that reading the detector pixel size from the header ASSUMES SQUARE PIXELS! - Jan2008
	DDet = getDet_x_pixel_size(folderStr)/10			// header value (X) is in mm, want cm here
	


//
//
	ii=0
	Variable ret1,ret2,ret3,ddr,binWidth
	
	ddr = binWidth*getDet_x_pixel_size(folderStr)		// step size, in [mm]
	do
		N_getResolution(qBin_qxqy[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,usingLenses,ret1,ret2,ret3)
		sigmaq[ii] = ret1	
		qbar[ii] = ret2	
		fsubs[ii] = ret3	
		ii+=1
	while(ii<nq)
	
	
// now -- rename all of the waves to names that SANS is expecting, since this calculation was
// taken from VSANS
// -- resolution waves were named correctly as they were generated above
//

// can't rename if they exist, duplicate/kill steps work

	SetDataFolder folderPath
	
	Duplicate/O iBin_qxqy,aveint
	Duplicate/O qBin_qxqy,qval
	Duplicate/O nBin_qxqy,ncells
	Duplicate/O eBin_qxqy,sigave
	Duplicate/O iBin2_qxqy,dsq

	WAVE qval = $(folderPath + ":qval")
	WAVE aveint = $(folderPath + ":aveint")
	WAVE sigave = $(folderPath + ":sigave")	
	
	//Plot the data in the Plot_1d window
	Avg_1D_Graph(aveint,qval,sigave)
	
	KillWaves/Z iBin_qxqy,iBin_qxqy,qBin_qxqy,nBin_qxqy,eBin_qxqy,iBin2_qxqy
	
	

	SetDataFolder root:
	
	return(0)
End





Function/WAVE MakePhiMatrix(qTotal,folderStr,folderPath)
	Wave qTotal
	String folderStr,folderPath

	Variable xctr,yctr
	
	xctr = getDet_beam_center_x(folderStr)
	yctr = getDet_beam_center_y(folderStr)


	Duplicate/O qTotal,$(folderPath+":phi")
	Wave phi = $(folderPath+":phi")
	Variable pixSizeX,pixSizeY
	pixSizeX = getDet_x_pixel_size(folderStr)
	pixSizeY = getDet_y_pixel_size(folderStr)
	MultiThread phi = FindPhi( pixSizeX*((p+1)-xctr) , pixSizeY*((q+1)-yctr))		//(dx,dy)
	
	return phi	
End


// 
// x- I want to mask out everything that is "out" of the sector
//
// 0 = keep the point
// 1 = yes, mask the point
//
//
// phiCtr is in the range (-90,90) degrees
// delta is in the range (0,90) for a total width of 2*delta = 180 degrees
//
Function MarkSectorOverlayPixels(phi,overlay,phiCtr,delta,side)
	Wave phi,overlay
	Variable phiCtr,delta
	String side
	
	Variable phiVal

// convert the imput from degrees to radians	, since phi is in radians
	phiCtr *= pi/180
	delta *= pi/180		
	
	Variable xDim=DimSize(phi, 0)
	Variable yDim=DimSize(phi, 1)

	Variable ii,jj,exclude,mirror_phiCtr,crossZero,keepPix
	
// initialize the mask to == 1 == exclude everything
	overlay = 1

// now give every opportunity to keep pixel in
// comparisons use a modified phiCtr to match the definition of the phi field (0= +x-axis)
//
	for(ii=0;ii<xDim;ii+=1)
		for(jj=0;jj<yDim;jj+=1)
			//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
			phiVal = phi[ii][jj]
			keepPix = 0		//start with not keeping

			// if within the right or left, flag to keep the pixel
			if(cmpstr(side,"right")==0)
				//right, when 0->pi/2
				if(CloseEnough(phiVal,phiCtr,delta))
					keepPix = 1
				endif
				// condition here to get the 3pi/2 -> 2pi region
				if(CloseEnough(phiVal,phiCtr+2*pi,delta))
					keepPix = 1
				endif
			endif
			
			if(cmpstr(side,"left")==0)
				if(CloseEnough(phiVal,phiCtr+pi,delta))
					keepPix = 1
				endif
			endif
						
		//	both sides, duplicates the conditions above
			if(cmpstr(side,"both")==0)	
				//right, when 0->pi/2
				if(CloseEnough(phiVal,phiCtr,delta))
					keepPix = 1
				endif
				// right, when 3pi/2 -> 2pi
				if(CloseEnough(phiVal,phiCtr+2*pi,delta))
					keepPix = 1
				endif				
				
				//left
				if(CloseEnough(phiVal,phiCtr+pi,delta))
					keepPix = 1
				endif
				
			endif
				
			// set the mask value (entire overlay initialized to 1 to start)
			if(keepPix > 0)
				overlay[ii][jj] = 0
			endif
			
		endfor
	endfor


	return(0)
End

	
