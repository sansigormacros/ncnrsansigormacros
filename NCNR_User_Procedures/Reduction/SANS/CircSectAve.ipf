#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

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
Function CircularAverageTo1D(type)
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
	WAVE reals = $(destPath + ":RealsRead")
	WAVE/T textread = $(destPath + ":TextRead")
	String fileStr = textread[3]
	
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
	dtdist = 1000*reals[18]		// det distance in mm
	
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
	WAVE data=$(destPath + ":data")
	//Check for the existence of the mask, if not, make one (local to this folder) that is null
	
	if(WaveExists($"root:Packages:NIST:MSK:data") == 0)
		Print "There is no mask file loaded (WaveExists)- the data is not masked"
		Make/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
		Wave mask = $(destPath + ":mask")
		mask = 0
	else
		Wave mask=$"root:Packages:NIST:MSK:data"
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
					sigave[kk-1] = small_num
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
	//input dialog before.  This also must be passed to the resolution
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