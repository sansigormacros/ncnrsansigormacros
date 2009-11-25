#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*******************
// Vers 1.2 100901
//
//*******************
// Utility procedures for handling of workfiles (each is housed in a separate datafolder)
//
// - adding data to a workfile
// - copying workfiles to another folder
//
// - absolute scaling
// - DIV detector sensitivity corrections
//
// - the WorkFile Math panel for simple image math
// - 
// - adding work.drk data without normalizing to monitor counts
//***************************


//testing procedure, not called anymore
Proc Add_to_Workfile(type, add)
	String type,add
	Prompt type,"WORK data type",popup,"SAM;EMP;BGD"
	Prompt add,"Add to current WORK contents?",popup,"No;Yes"
	
	//macro will take whatever is in RAW folder and "ADD" it to the folder specified
	//in the popup menu
	
	//"add" = yes/no, don't add to previous runs
	//switch here - two separate functions to avoid (my) confusion
	Variable err
	if(cmpstr(add,"No")==0)
		//don't add to prev work contents, copy RAW contents to work and convert
		err = Raw_to_work(type)
	else
		//yes, add RAW to the current work folder contents
		err = Add_raw_to_work(type)
	endif
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	fRawWindowHook()
	
End

//will "ADD" the current contents of the RAW folder to the newType work folder
//and will ADD the RAW contents to the existing content of the newType folder
// - used when adding multiple runs together
//(the function Raw_to_work(type) makes a fresh workfile)
//
//the current display type is updated to newType (global)
Function Add_raw_to_work(newType)
	String newType
		
	String destPath=""
	
	// if the desired workfile doesn't exist, let the user know, and just make a new one
	destPath = "root:Packages:NIST:"+newType + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no old work file to add to - a new one will be created"
		//call Raw_to_work(), then return from this function
		Raw_to_Work(newType)
		Return(0)		//does not generate an error - a single file was converted to work.newtype
	Endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//now make references to data in newType folder
	DestPath="root:Packages:NIST:"+newType	
	WAVE data=$(destPath +":data")			// these wave references point to the EXISTING work data
	WAVE/T textread=$(destPath + ":textread")
	WAVE integersread=$(destPath + ":integersread")
	WAVE realsread=$(destPath + ":realsread")
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale,wrk_beamx,wrk_beamy,xshift,yshift

// 08/01 detector constants are now returned from a function, based on the detector type and beamline
//	dt_ornl = 3.4e-6		//deadtime of Ordella detectors	as of 30-AUG-99
//	dt_ill=3.0e-6			//Cerca detector deadtime constant as of 30-AUG-99

	defmon=1e8			//default monitor counts
	
	//Yes, add to previous run(s) in work, that does exist
	//use the actual monitor count run.savmon rather than the normalized monitor count
	//in run.moncnt and unscale the work data
	
	total_mon = realsread[1]	//saved monitor count
	uscale = total_mon/defmon		//unscaling factor
	total_det = uscale*realsread[2]		//unscaled detector count
	total_trn = uscale*realsread[39]	//unscaled trans det count
	total_numruns = integersread[3]	//number of runs in workfile
	total_rtime = integersread[2]		//total counting time in workfile
	//retrieve workfile beamcenter
	wrk_beamx = realsread[16]
	wrk_beamy = realsread[17]
	//unscale the workfile data in "newType"
	//
	//check for log-scaling and adjust if necessary
	ConvertFolderToLinearScale(newType)
	//
	//then unscale the data array
	data *= uscale
	
	//DetCorr() has not been applied to the data in RAW , do it now in a local reference to the raw data
	WAVE raw_data = $"root:Packages:NIST:RAW:data"
	WAVE raw_reals =  $"root:Packages:NIST:RAW:realsread"
	WAVE/T raw_text = $"root:Packages:NIST:RAW:textread"
	WAVE raw_ints = $"root:Packages:NIST:RAW:integersread"
	
	//check for log-scaling of the raw data - make sure it's linear
	ConvertFolderToLinearScale("RAW")
	
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR doEfficiency = root:myGlobals:gDoDetectorEffCorr
	NVAR gDoTrans = root:myGlobals:gDoTransmissionCorr
	Variable doTrans = gDoTrans
	if(cmpstr("BGD",newtype) == 0)
		doTrans = 0		//skip the trans correction for the BGD file but don't change the value of the global
	endif	
	
	DetCorr(raw_data,raw_reals,doEfficiency,doTrans)	//applies correction to raw_data, and overwrites it
	
	//if RAW data is ILL type detector, correct raw_data for same counts being written to 4 pixels
	if(cmpstr(raw_text[9], "ILL   ") == 0 )		//text field in header is 6 characters "ILL---"
		raw_data /= 4
	endif
	
	//deadtime corrections to raw data
	deadTime = DetectorDeadtime(raw_text[3],raw_text[9])		//pick the correct detector deadtime
	itim = raw_ints[2]
	cntrate = sum(raw_data,-inf,inf)/itim		//080802 use data sum, rather than scaler value
	dscale = 1/(1-deadTime*cntrate)

#if (exists("ILL_D22")==6)
	Variable tubeSum
	// for D22 detector might need to use cntrate/128 as it is the tube response
	for(ii=0;ii<pixelsX;ii+=1)
		//sum the counts in each tube
		tubeSum = 0
		for(jj=0;jj<pixelsY;jj+=1)
			tubeSum += data[jj][ii]
		endfor
		// countrate in tube ii
		cntrate = tubeSum/itim
		// deadtime scaling in tube ii
		dscale = 1/(1-deadTime*cntrate)
		// multiply data[ii][] by the dead time
		data[][ii] *= dscale
	endfor
#endif

	//update totals by adding RAW values to the local ones (write to work header at end of function)
	total_mon += raw_reals[0]
#if (exists("ILL_D22")==6)
	total_det += sum(data,-inf,inf)			//add the newly scaled detector array
#else
	total_det += dscale*raw_reals[2]
#endif
	total_trn += raw_reals[39]
	total_rtime += raw_ints[2]
	total_numruns +=1
	
	//do the beamcenter shifting if there is a mismatch
	//and then add the two data sets together, changing "data" since it is the workfile data
	xshift = raw_reals[16] - wrk_beamx
	yshift = raw_reals[17] - wrk_beamy
	
	If((xshift != 0) || (yshift != 0))
		DoAlert 1,"Do you want to ignore the beam center mismatch?"
		if(V_flag==1)
			xshift=0
			yshift=0
		endif
	endif
	
	If((xshift == 0) && (yshift == 0))		//no shift, just add them
		data += dscale*raw_data		//do the deadtime correction on RAW here
	else
		//shift the beamcenter, then add
		Make/O/N=1 $(destPath + ":noadd")		//needed to get noadd condition back from ShiftSum()
		WAVE noadd = $(destPath + ":noadd")
		Variable sh_sum			//returned value
		Print "BEAM CENTER MISMATCH - - BEAM CENTER WILL BE SHIFTED TO THIS FILE'S VALUE"
		//ii,jj are just indices here, not physical locations - so [0,127] is fine
		ii=0
		do
			jj=0
			do
				//get the contribution of shifted data
				sh_sum = ShiftSum(data,ii,jj,xshift,yshift,noadd)
				if(noadd[0])
					//don't do anything to data[][]
				else
					//add the raw_data + shifted sum (and do the deadtime correction on both)
					data[ii][jj] += dscale*(raw_data[ii][jj]+sh_sum)		//do the deadtime correction on RAW here
				Endif
				jj+=1
			while(jj<pixelsY)
			ii+=1
		while(ii<pixelsX)
	Endif
	
	//scale the data to the default montor counts
	scale = defmon/total_mon
	data *= scale
	
	//all is done, except for the bookkeeping of updating the header info in the work folder
	textread[1] = date() + " " + time()		//date + time stamp
	integersread[3] = total_numruns						//numruns = more than one
	realsread[1] = total_mon			//save the true monitor count
	realsread[0] = defmon					//monitor ct = defmon
	integersread[2] = total_rtime			// total counting time
	realsread[2] = scale*total_det			//scaled detector counts
	realsread[39] = scale*total_trn			//scaled transmission counts
	
	//Add the added raw filename to the list of files in the workfile
	String newfile = ";" + raw_text[0]
	SVAR oldList = $(destPath + ":fileList")
	String/G $(destPath + ":fileList") = oldList + newfile
	
	//reset the current displaytype to "newtype"
	String/G root:myGlobals:gDataDisplayType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End

//will copy the current contents of the RAW folder to the newType work folder
//and do the geometric corrections and normalization to monitor counts
//(the function Add_Raw_to_work(type) adds multiple runs together)
//
//the current display type is updated to newType (global)
//
Function Raw_to_work(newType)
	String newType
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale,wrk_beamx,wrk_beamy
	String destPath
	
// 08/01 detector constants are now returned from a function, based on the detector type and beamline
//	dt_ornl = 3.4e-6		//deadtime of Ordella detectors	as of 30-AUG-99
//	dt_ill=3.0e-6			//Cerca detector deadtime constant as of 30-AUG-99
	defmon=1e8			//default monitor counts
	
	//initialize values before normalization
	total_mon=0
	total_det=0
	total_trn=0
	total_numruns=0
	total_rtime=0
	
	//Not adding multiple runs, so wipe out the old contents of the work folder and 
	// replace with the contents of raw

	destPath = "root:Packages:NIST:" + newType
	
	//check for log-scaling of the RAW data and adjust if necessary
	ConvertFolderToLinearScale("RAW")
	//then continue
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//copy from current dir (RAW) to work, defined by destpath
	DestPath = "root:Packages:NIST:"+newType
	Duplicate/O $"root:Packages:NIST:RAW:data",$(destPath + ":data")
//	Duplicate/O $"root:Packages:NIST:RAW:vlegend",$(destPath + ":vlegend")
	Duplicate/O $"root:Packages:NIST:RAW:textread",$(destPath + ":textread")
	Duplicate/O $"root:Packages:NIST:RAW:integersread",$(destPath + ":integersread")
	Duplicate/O $"root:Packages:NIST:RAW:realsread",$(destPath + ":realsread")
	Variable/G $(destPath + ":gIsLogscale")=0			//overwite flag in newType folder, data converted (above) to linear scale
	
	WAVE data=$(destPath + ":data")				// these wave references point to the data in work
	WAVE/T textread=$(destPath + ":textread")			//that are to be directly operated on
	WAVE integersread=$(destPath + ":integersread")
	WAVE realsread=$(destPath + ":realsread")
	String/G $(destPath + ":fileList") = textread[0]			//a list of names of the files in the work file (1)
	
	//apply nonlinear, Jacobian corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR doEfficiency = root:myGlobals:gDoDetectorEffCorr
	NVAR gDoTrans = root:myGlobals:gDoTransmissionCorr
	Variable doTrans = gDoTrans
	if(cmpstr("BGD",newtype) == 0)
		doTrans = 0		//skip the trans correction for the BGD file but don't change the value of the global
	endif
	
	DetCorr(data,realsread,doEfficiency,doTrans)		//the parameters are waves, and will be changed by the function
	
	//if ILL type detector, correct for same counts being written to 4 pixels
	if(cmpstr(textread[9], "ILL   ") == 0 )		//text field in header is 6 characters "ILL---"
		data /= 4
	endif
	
	//deadtime corrections
	itim = integersread[2]
	cntrate = sum(data,-inf,inf)/itim		//use sum of detector counts rather than scaler value
	deadtime = DetectorDeadtime(textread[3],textread[9])	//pick the correct deadtime
	dscale = 1/(1-deadTime*cntrate)
	
#if (exists("ILL_D22")==6)
	Variable tubeSum
	// for D22 detector might need to use cntrate/128 as it is the tube response
	for(ii=0;ii<pixelsX;ii+=1)
		//sum the counts in each tube
		tubeSum = 0
		for(jj=0;jj<pixelsY;jj+=1)
			tubeSum += data[jj][ii]
		endfor
		// countrate in tube ii
		cntrate = tubeSum/itim
		// deadtime scaling in tube ii
		dscale = 1/(1-deadTime*cntrate)
		// multiply data[ii][] by the dead time
		data[][ii] *= dscale
	endfor
#endif
	
	
	//update totals to put in the work header (at the end of the function)
	total_mon += realsread[0]
#if (exists("ILL_D22")==6)
	total_det += sum(data,-inf,inf)			//add the newly scaled detector array
#else
	total_det += dscale*realsread[2]
#endif
	total_trn += realsread[39]
	total_rtime += integersread[2]
	total_numruns +=1
	
	// NO xcenter,ycenter shifting is done - this is the first (and only) file in the work folder
	
	//only ONE data file- no addition of multiple runs in this function, so data is
	//just simply corrected for deadtime.
#ifndef ILL_D22		//correction done tube-by-tube above
	data *= dscale		//deadtime correction
#endif

	//scale the data to the default montor counts
	scale = defmon/total_mon
	data *= scale
	
	//all is done, except for the bookkeeping, updating the header information in the work folder
	textread[1] = date() + " " + time()		//date + time stamp
	integersread[3] = total_numruns						//numruns = 1
	realsread[1] = total_mon			//save the true monitor count
	realsread[0] = defmon					//monitor ct = defmon
	integersread[2] = total_rtime			// total counting time
	realsread[2] = scale*total_det			//scaled detector counts
	realsread[39] = scale*total_trn			//scaled transmission counts
	
	//reset the current displaytype to "newtype"
	String/G root:myGlobals:gDataDisplayType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":data")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be 1
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	
	return(0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Add_Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	Add_Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":data")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be equal to the number of runs (1 count per run)
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	
	return(0)
End

//performs solid angle and non-linear detector corrections to raw data as it is "added" to a work folder
//function is called by Raw_to_work() and Add_raw_to_work() functions
//works on the actual data array, assumes that is is already on LINEAR scale
//
Function DetCorr(data,realsread,doEfficiency,doTrans)
	Wave data,realsread
	Variable doEfficiency,doTrans
	
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,xx0,yy0
	Variable ii,jj,dtdist,dtdis2
	Variable xi,xd,yd,rad,ratio,domega,xy
	Variable lambda,trans
	
//	Print "...doing jacobian and non-linear corrections"

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//set up values to send to auxiliary trig functions
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela

	x0 = realsread[16]
	y0 = realsread[17]
	sx = realsread[10]
	sx3 = realsread[11]
	sy = realsread[13]
	sy3 = realsread[14]
	
	dtdist = 1000*realsread[18]	//sdd in mm
	dtdis2 = dtdist^2
	
	lambda = realsRead[26]
	trans = RealsRead[4]
	
	xx0 = dc_fx(x0,sx,sx3,xcenter)
	yy0 = dc_fy(y0,sy,sy3,ycenter)
	

	//waves to contain repeated function calls
	Make/O/N=(pixelsX) fyy,xx,yy		//Assumes square detector !!!
	ii=0
	do
		xi = ii
		fyy[ii] = dc_fy(ii+1,sy,sy3,ycenter)
		xx[ii] = dc_fxn(ii+1,sx,sx3,xcenter)
		yy[ii] = dc_fym(ii+1,sy,sy3,ycenter)
		ii+=1
	while(ii<pixelsX)
	
	Make/O/N=(pixelsX,pixelsY) SolidAngle		// testing only
	
	ii=0
	do
		xi = ii
		xd = dc_fx(ii+1,sx,sx3,xcenter)-xx0
		jj=0
		do
			yd = fyy[jj]-yy0
			//rad is the distance of pixel ij from the sample
			//domega is the ratio of the solid angle of pixel ij versus center pixel
			// product xy = 1 for a detector with a linear spatial response (modern Ordela)
			// solid angle calculated, dW^3 >=1, so multiply data to raise measured values to correct values.
			rad = sqrt(dtdis2 + xd^2 + yd^2)
			domega = rad/dtdist
			ratio = domega^3
			xy = xx[ii]*yy[jj]
			data[ii][jj] *= xy*ratio
//			solidAngle[ii][jj] = xy*ratio		//testing only	

			
			// correction factor for detector efficiency JBG memo det_eff_cor2.doc 3/20/07
			// correction inserted 11/2007 SRK
			// large angle detector efficiency is >= 1 and will "bump up" the measured value at the highest angles
			// so divide here to get the correct answer (5/22/08 SRK)
			if(doEfficiency)
#if (exists("ILL_D22")==6)
				data[ii][jj]  /= DetEffCorrILL(lambda,dtdist,xd) 		//tube-by-tube corrections 
	          solidAngle[ii][jj] = DetEffCorrILL(lambda,dtdist,xd)
#else
				data[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)
//				solidAngle[ii][jj] /= DetEffCorr(lambda,dtdist,xd,yd)		//testing only
#endif
			endif
			
			// large angle transmission calculation is <= 1 and will "bump down" the measured value at the highest angles
			// so divide here to get the correct answer
			if(doTrans)
			
				if(trans<0.1 && ii==0 && jj==0)
					Print "***transmission is less than 0.1*** and is a significant correction"
				endif
				
				if(trans==0)
					if(ii==0 && jj==0)
						Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
					endif
					trans = 1
				endif
					
				data[ii][jj] /= LargeAngleTransmissionCorr(trans,dtdist,xd,yd)		//moved from 1D avg SRK 11/2007
//				solidAngle[ii][jj] /= LargeAngleTransmissionCorr(trans,dtdist,xd,yd)		//testing only
			endif
			
			jj+=1
		while(jj<pixelsX)
		ii+=1
	while(ii<pixelsX)
	
	//clean up waves
//	Killwaves/Z fyy,xx,yy
	
	Return(0)
End

//trig function used by DetCorr()
Function dc_fx(x,sx,sx3,xcenter)
	Variable x,sx,sx3,xcenter
	
	Variable result
	
	result = sx3*tan((x-xcenter)*sx/sx3)
	Return(result)
End

//trig function used by DetCorr()
Function dc_fy(y,sy,sy3,ycenter)
	Variable y,sy,sy3,ycenter
	
	Variable result
	
	result = sy3*tan((y-ycenter)*sy/sy3)
	Return(result)
End

//trig function used by DetCorr()
Function dc_fxn(x,sx,sx3,xcenter)
	Variable x,sx,sx3,xcenter
	
	Variable result
	
	result = (cos((x-xcenter)*sx/sx3))^2
	Return(result)
End

//trig function used by DetCorr()
Function dc_fym(y,sy,sy3,ycenter)
	Variable y,sy,sy3,ycenter
	
	Variable result
	
	result = (cos((y-ycenter)*sy/sy3))^2
	Return(result)
End

//distances passed in are in mm
// dtdist is SDD
// xd and yd are distances from the beam center to the current pixel
//
Function DetEffCorr(lambda,dtdist,xd,yd)
	Variable lambda,dtdist,xd,yd
	
	Variable theta,cosT,ff,stAl,stHe
	
	theta = atan( (sqrt(xd^2 + yd^2))/dtdist )
	cosT = cos(theta)
	
	stAl = 0.00967*lambda*0.8		//dimensionless, constants from JGB memo
	stHe = 0.146*lambda*2.5
	
	ff = exp(-stAl/cosT)*(1-exp(-stHe/cosT)) / ( exp(-stAl)*(1-exp(-stHe)) )
		
	return(ff)
End

// DIVIDE the intensity by this correction to get the right answer
Function LargeAngleTransmissionCorr(trans,dtdist,xd,yd)
	Variable trans,dtdist,xd,yd

	//angle dependent transmission correction 
	Variable uval,arg,cos_th,correction,theta
	
	////this section is the trans_correct() VAX routine
//	if(trans<0.1)
//		Print "***transmission is less than 0.1*** and is a significant correction"
//	endif
//	if(trans==0)
//		Print "***transmission is ZERO*** and has been reset to 1.0 for the averaging calculation"
//		trans = 1
//	endif
	
	theta = atan( (sqrt(xd^2 + yd^2))/dtdist )		//theta at the input pixel
	
	//optical thickness
	uval = -ln(trans)		//use natural logarithm

//	theta = 2*asin(lambda*qval/(4*pi))

	cos_th = cos(theta)
	arg = (1-cos_th)/cos_th
	if((uval<0.01) || (cos_th>0.99))		//OR
		//small arg, approx correction
		correction= 1-0.5*uval*arg
	else
		//large arg, exact correction
		correction = (1-exp(-uval*arg))/(uval*arg)
	endif

	//end of transmission/pathlength correction

	return(correction)
end

//******************
//direct port of the FORTRAN code for calculating the weighted
//shifted element to add when beam centers in data headers do not match
//(indices updated to [0,n-1] indexing rather than (1,n) of fortran
//
// as of IGOR 4.0, could be rewritten to pass-by-reference noadd, rather than wave, but the function
// is so little used, it's not worth the time
Function ShiftSum(DATA,ip,jp,XSHIFT,YSHIFT,noadd)
	Wave data
	Variable ip,jp,xshift,yshift
	Wave noadd
//
//       COMPUTE WEIGHTED OFFSET ELEMENT SUM FOR USE IN SANS DATA
//       ANALYSIS MODULES.
//
// "data" wave passed in is the current contents of the work file
// sum_val is the return value of the function
// "noadd" is passed back to the calling function as a one-point wave

	Variable XDELTA,YDELTA,kk,II,JJ,ISHIFT,JSHIFT,sum_val
	Make/O/N=4 iii,jjj,a

//       -----------------------------------------------------------------

	ISHIFT = trunc(XSHIFT)   	// INTEGER PART, trunc gives int closest in dierction of zero
	XDELTA = XSHIFT - ISHIFT   	//FRACTIONAL PART.
	JSHIFT = trunc(YSHIFT)
	YDELTA = YSHIFT - JSHIFT
	II = ip + ISHIFT
	JJ = jp + JSHIFT

//       SHIFT IS DEFINED AS A VECTOR ANCHORED AT THE STATIONARY CENTER
//       AND POINTING TO THE MOVABLE CENTER.  THE MOVABLE FIELD IS THUS
//       ACTUALLY MOVED BY -SHIFT.
//
	IF ((XDELTA>= 0) && (YDELTA >= 0))		// CASE I ---- "%&" is "and"
		III[0] = II
		JJJ[0] = JJ
		III[1] = II + 1
		JJJ[1] = JJ
		III[2] = II + 1
		JJJ[2] = JJ + 1
		III[3] = II
		JJJ[3] = JJ + 1
		A[0] = (1. - XDELTA)*(1. - YDELTA)
		A[1] = XDELTA*(1. - YDELTA)
		A[2] = XDELTA*YDELTA
		A[3] = (1. - XDELTA)*YDELTA
	Endif
	IF ((XDELTA >= 0) && (YDELTA < 0))		// CASE II.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ - 1
		III[2] = II + 1
		JJJ[2] = JJ - 1
		III[3] = II + 1
		JJJ[3] = JJ
		A[0] = (1. - XDELTA)*(1. + YDELTA)
		A[1] = (1. - XDELTA)*(-YDELTA)
		A[2] = XDELTA*(-YDELTA)
		A[3] = XDELTA*(1. + YDELTA)
	Endif
	IF ((XDELTA < 0) && (YDELTA >= 0))	 	// CASE III.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II
		JJJ[1] = JJ + 1
		III[2] = II - 1
		JJJ[2] = JJ + 1
		III[3] = II - 1
		JJJ[3] = JJ
		A[0] = (1. + XDELTA)*(1 - YDELTA)
		A[1] = (1. + XDELTA)*YDELTA
		A[2] = -XDELTA*YDELTA
		A[3] = -XDELTA*(1. - YDELTA)
	Endif
	IF ((XDELTA < 0) && (YDELTA < 0))		//CASE IV.
		III[0] = II
		JJJ[0] = JJ
		III[1] = II - 1
		JJJ[1] = JJ
		III[2] = II - 1
		JJJ[2] = JJ - 1
		III[3] = II
		JJJ[3] = JJ - 1
		A[0] = (1. + XDELTA)*(1. + YDELTA)
		A[1] = -XDELTA*(1. + YDELTA)
		A[2] = (-XDELTA)*(-YDELTA)
		A[3] = (1. + XDELTA)*(-YDELTA)
	Endif

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
//check to see if iii[0],jjj[0] are valid detector elements, in [0,127]
//if not set noadd[0] to 1, to let calling routine know NOT to add
//        CALL TESTIJ(III(1),JJJ(1),OKIJ)
	NOADD[0] = 0
	if( (iii[0]<0) || (iii[0]>(pixelsX-1)) )
		noadd[0] = 1
	endif
	if((jjj[0]<0) || (jjj[0]>(pixelsY-1)) )
		noadd[0] = 1
	endif
	

	
	sum_val = 0.
	kk = 0
	Do
		IF(JJJ[kk] == pixelsX)
			//do nothing
		else
			sum_val += A[kk]*DATA[III[kk]][JJJ[kk]]
		endif
		kk+=1
	while(kk<4)
	
	//clean up waves
	KillWaves/z iii,jjj,a
	
	RETURN (sum_val)
	
End		//function ShiftSum

//************************
//unused testing procedure, may not be up-to-date with other procedures
//check before re-implementing
//
Proc DIV_a_Workfile(type)
	String type
	Prompt type,"WORK data type",popup,"COR;SAM;EMP;BGD"
	
	//macro will take whatever is in SELECTED folder and DIVide it by the current
	//contents of the DIV folder - the function will check for existence 
	//before proceeding
	
	Variable err
	err = Divide_work(type)		//returns err = 1 if data doesn't exist in specified folders
	
	if(err)
		Abort "error in Divide_work"
	endif
	
	//contents are always dumped to CAL
	type = "CAL"
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=Type
	
	fRawWindowHook()
	
End

//function will divide the contents of "type" folder with the contents of 
//the DIV folder
// all data is converted to linear scale for the calculation
//
Function Divide_work(type)
	String type
	
	//check for existence of data in type and DIV
	// if the desired workfile doesn't exist, let the user know, and abort
	String destPath=""
	destPath = "root:Packages:NIST:"+Type + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	Endif
	//check for DIV
	// if the DIV workfile doesn't exist, let the user know,and abort
	destPath = "root:Packages:NIST:DIV:data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in DIV --Aborting"
		Return(1)		//error condition
	Endif
	//files exist, proceed
	
	//check for log-scaling of the "DIV" data and adjust if necessary
	ConvertFolderToLinearScale("DIV")
	
	//copy type information to CAL, wiping out the old contents of the CAL folder first
	
	//destPath = "root:Packages:NIST:CAL"
	//SetDataFolder destPath
	//KillWaves/A/Z			//get rid of the old data in CAL folder

	//check for log-scaling of the "type" data and adjust if necessary
	ConvertFolderToLinearScale(type)
	//then continue

	//copy from current dir (type)=destPath to CAL, overwriting CAL contents
	destPath = "root:Packages:NIST:" + type
	Duplicate/O $(destPath + ":data"),$"root:Packages:NIST:CAL:data"
//	Duplicate/O $(destPath + ":vlegend"),$"root:Packages:NIST:CAL:vlegend"
	Duplicate/O $(destPath + ":textread"),$"root:Packages:NIST:CAL:textread"
	Duplicate/O $(destPath + ":integersread"),$"root:Packages:NIST:CAL:integersread"
	Duplicate/O $(destPath + ":realsread"),$"root:Packages:NIST:CAL:realsread"
	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(destPath + ":fileList")

	//now switch to reference waves in CAL folder
	destPath = "root:Packages:NIST:CAL"
	//make appropriate wave references
	Wave data=$(destPath + ":data")					// these wave references point to the data in CAL
	Wave/t textread=$(destPath + ":textread")			//that are to be directly operated on
	Wave integersread=$(destPath + ":integersread")
	Wave realsread=$(destPath + ":realsread")
	Variable/G $(destPath + ":gIsLogScale")=0			//make new flag in CAL folder, data is linear scale
	//need to copy filelist string too
	String/G $(destPath + ":fileList") = oldFileList

	Wave div_data = $"root:Packages:NIST:DIV:data"		//hard-wired in....
	//do the division, changing data in CAL
	data /= div_data
	
	//update CAL header
	textread[1] = date() + " " + time()		//date + time stamp
	
	Return(0)
End

//test procedure, not called anymore
Proc AbsoluteScaling(type,c0,c1,c2,c3,c4,c5)
	String type
	Variable c0=1,c1=0.1,c2=0.95,c3=0.1,c4=1,c5=32.0
	Prompt type,"WORK data type",popup,"CAL;COR;SAM"
	Prompt c0, "Sample Transmission"
	Prompt c1, "Sample Thickness (cm)"
	Prompt c2, "Standard Transmission"
	Prompt c3, "Standard Thickness (cm)"
	Prompt c4, "I(0) from standard fit (normalized to 1E8 monitor cts)"
	Prompt c5, "Standard Cross-Section (cm-1)"

	Variable err
	//call the function to do the math
	//data from "type" will be scaled and deposited in ABS
	err = Absolute_Scale(type,c0,c1,c2,c3,c4,c5)
	
	if(err)
		Abort "Error in Absolute_Scale()"
	endif
	
	//contents are always dumped to ABS
	type = "ABS"
	
	String newTitle = "WORK_"+type
	DoWindow/F SANS_Data
	DoWindow/T SANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=Type
	
	fRawWindowHook()
	
End

//s_ is the standard
//w_ is the "work" file
//both are work files and should already be normalized to 10^8 monitor counts
Function Absolute_Scale(type,w_trans,w_thick,s_trans,s_thick,s_izero,s_cross)
	String type
	Variable w_trans,w_thick,s_trans,s_thick,s_izero,s_cross
	
	//convert the "type" data to absolute scale using the given standard information
	//copying the "type" waves to ABS
	
	//check for existence of data, rescale to linear if needed
	String destPath
	//check for "type"
	destPath = "root:Packages:NIST:"+Type + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	Endif
	//check for log-scaling of the "type" data and adjust if necessary
	destPath = "root:Packages:NIST:"+Type
	NVAR gIsLogScale = $(destPath + ":gIsLogScale")
	if(gIsLogScale)
		Duplicate/O $(destPath + ":linear_data") $(destPath + ":data")//back to linear scale
		Variable/G $(destPath + ":gIsLogScale")=0	//the "type" data is not logscale anymore
	endif
	
	//copy "oldtype" information to ABS
	//overwriting out the old contents of the ABS folder (/O option in Duplicate)
	//copy over the waves data,vlegend,text,integers,reals(read)

	String oldType= "root:Packages:NIST:"+type  		//this is where the data to be absoluted is 
	//copy from current dir (type) to ABS, defined by destPath
	Duplicate/O $(oldType + ":data"),$"root:Packages:NIST:ABS:data"
//	Duplicate/O $(oldType + ":vlegend"),$"root:Packages:NIST:ABS:vlegend"
	Duplicate/O $(oldType + ":textread"),$"root:Packages:NIST:ABS:textread"
	Duplicate/O $(oldType + ":integersread"),$"root:Packages:NIST:ABS:integersread"
	Duplicate/O $(oldType + ":realsread"),$"root:Packages:NIST:ABS:realsread"
	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(oldType + ":fileList")
	//need to copy filelist string too
	String/G $"root:Packages:NIST:ABS:fileList" = oldFileList
	
	//now switch to ABS folder
	//make appropriate wave references
	WAVE data=$"root:Packages:NIST:ABS:data"					// these wave references point to the "type" data in ABS
	WAVE/T textread=$"root:Packages:NIST:ABS:textread"			//that are to be directly operated on
	WAVE integersread=$"root:Packages:NIST:ABS:integersread"
	WAVE realsread=$"root:Packages:NIST:ABS:realsread"
	Variable/G $"root:Packages:NIST:ABS:gIsLogscale"=0			//make new flag in ABS folder, data is linear scale
	
	//do the actual absolute scaling here, modifying the data in ABS
	Variable defmon = 1e8,w_moncount,s1,s2,s3,s4
	
	w_moncount = realsread[0]		//monitor count in "type"
	if(w_moncount == 0)
		//zero monitor counts will give divide by zero ---
		DoAlert 0,"Total monitor count in data file is zero. No rescaling of data"
		Return(1)		//report error
	Endif
	
	//calculate scale factor
	s1 = defmon/realsread[0]		//[0] is monitor count (s1 should be 1)
	s2 = s_thick/w_thick
	s3 = s_trans/w_trans
	s4 = s_cross/s_izero
	
	data *= s1*s2*s3*s4
	
	//********* 15APR02
	// DO NOt correct for atenuators here - the COR step already does this, putting all of the data one equal
	// footing (zero atten) before doing the subtraction.
	//
	//Print "ABS data multiplied by  ",s1*s2*s3*s4/attenFactor
	
	//update the ABS header information
	textread[1] = date() + " " + time()		//date + time stamp
	
	Return (0) //no error
End

//*************
// start of section of functions used for workfile math panel
//*************


//function will copy the contents of oldtype folder to newtype folder
//converted to linear scale before copying
//******data in newtype is overwritten********
//
Function CopyWorkContents(oldtype,newtype)
	String oldtype,newtype
	
	//check for existence of data in oldtype
	// if the desired workfile doesn't exist, let the user know, and abort
	String destPath=""
	destPath = "root:Packages:NIST:"+oldType + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+oldtype+"--Aborting"
		Return(1) 		//error condition
	Endif
	
	//check for log-scaling of the "type" data and adjust if necessary
	ConvertFolderToLinearScale(oldtype)
	Fix_LogLinButtonState(0)		//make sure the button reflects the new linear scaling
	//then continue

	//copy from current dir (type)=destPath to newtype, overwriting newtype contents
	destPath = "root:Packages:NIST:" + oldtype
	Duplicate/O $(destPath + ":data"),$("root:Packages:NIST:"+newtype+":data")
	Duplicate/O $(destPath + ":textread"),$("root:Packages:NIST:"+newtype+":textread")
	Duplicate/O $(destPath + ":integersread"),$("root:Packages:NIST:"+newtype+":integersread")
	Duplicate/O $(destPath + ":realsread"),$("root:Packages:NIST:"+newtype+":realsread")
	//need to save a copy of filelist string too (from the current type folder)
	SVAR oldFileList = $(destPath + ":fileList")

	//now switch to reference waves in newtype folder
	destPath = "root:Packages:NIST:"+newtype
	Variable/G $(destPath + ":gIsLogScale")=0			//make new flag in newtype folder, data is linear scale
	//need to copy filelist string too
	String/G $(destPath + ":fileList") = oldFileList

	Return(0)
End

//Entry procedure from main panel
//
Proc CopyWorkFolder(oldType,newType)
	String oldType,newType
	Prompt oldType,"Source WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
	Prompt newType,"Destination WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
//	Prompt oldType,"Source WORK data type",popup,"AAA;BBB;CCC;DDD;EEE;FFF;GGG;"
//	Prompt newType,"Destination WORK data type",popup,"AAA;BBB;CCC;DDD;EEE;FFF;GGG;"

	// data folder "old" will be copied to "new" (and will overwrite)
	CopyWorkContents(oldtype,newtype)
End

//initializes datafolder and constants necessary for the workfilemath panel
//
Proc Init_WorkMath()
	//create the data folder
	//String str = "AAA;BBB;CCC;DDD;EEE;FFF;GGG;"
	String str = "File_1;File_2;Result;"
	NewDataFolder/O/S root:Packages:NIST:WorkMath
	String/G gFolderList=str
	Variable ii=0,num=itemsinlist(str)
	do
		Execute "NewDataFolder/O "+StringFromList(ii, str ,";")
		ii+=1
	while(ii<num)
	Variable/G const1=1,const2=1
	
	SetDataFolder root:
End

//entry procedure to invoke the workfilemath panel, initializes if needed
//
Proc Show_WorkMath_Panel()
	DoWindow/F WorkFileMath
	if(V_flag==0)
		Init_WorkMath()
		WorkFileMath()
	Endif
End

//attempts to perform the selected math operation based on the selections in the panel
// aborts with an error condition if operation can't be completed
// or puts the final answer in the Result folder, and displays the selected data
//
Function WorkMath_DoIt_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String str1,str2,oper,dest = "Result"
	String pathStr,workMathStr="WorkMath:"
	
	//get the panel selections (these are the names of the files on disk)
	PathInfo catPathName
	pathStr=S_Path
	ControlInfo popup0
	str1=S_Value
	ControlInfo popup1
	str2=S_Value
	ControlInfo popup2
	oper=S_Value
	
	//check that something has been selected for operation and destination
	if(cmpstr(oper,"Operation")==0)
		Abort "Select a math operand from the popup"
	Endif

	//constants from globals
	NVAR const1=root:Packages:NIST:WorkMath:const1
	NVAR const2=root:Packages:NIST:WorkMath:const2
	Printf "(%g)%s %s (%g)%s = %s\r", const1,str1,oper,const2,str2,dest
	//check for proper folders (all 3 must be different)
	
	//load the data in here...
	//set #1
	Load_NamedASC_File(pathStr+str1,workMathStr+"File_1")
	
	NVAR pixelsX = root:myGlobals:gNPixelsX		//OK, location is correct
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	WAVE/Z data1=$("root:Packages:NIST:"+workMathStr+"File_1:data")
	If(cmpstr(str2,"UNIT MATRIX")==0)
		Make/O/N=(pixelsX,pixelsY) root:Packages:NIST:WorkMath:data		//don't put in File_2 folder
		Wave/Z data2 =  root:Packages:NIST:WorkMath:data			//it's not real data!
		data2=1
	else
		//Load set #2
		Load_NamedASC_File(pathStr+str2,workMathStr+"File_2")
		WAVE/Z data2=$("root:Packages:NIST:"+workMathStr+"File_2:data")
	Endif

	///////
	
	//now that we know that data exists, convert each of the operands to linear scale
	ConvertFolderToLinearScale(workMathStr+"File_1")
	If(cmpstr(str2,"UNIT MATRIX")!=0)
		ConvertFolderToLinearScale(workMathStr+"File_2")		//don't need to convert unit matrix to linear
	endif
	//copy contents of str1 folder to dest and create the wave ref (it will exist)
	CopyWorkContents(workMathStr+"File_1",workMathStr+dest)
	WAVE/Z destData=$("root:Packages:NIST:"+workMathStr+dest+":data")
	
	//dispatch
	strswitch(oper)	
		case "*":		//multiplication
			destData = const1*data1 * const2*data2
			break	
		case "_":		//subtraction
			destData = const1*data1 - const2*data2
			break
		case "/":		//division
			destData = (const1*data1) / (const2*data2)
			break
		case "+":		//addition
			destData = const1*data1 + const2*data2
			break			
	endswitch
	
	//show the result
	WorkMath_Display_PopMenuProc("",0,"Result")
End

// closes the panel and kills the data folder when done
//
Function WorkMath_Done_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoAlert 1,"Closing the panel will kill all of the data you have loaded into memory. Do you want to continue?"
	If(V_Flag==2)
		return(0)		//don't do anything
	Endif
	//kill the panel
	DoWindow/K WorkFileMath
	//wipe out the data folder of globals
	SVAR dataType=root:myGlobals:gDataDisplayType
	if(strsearch(dataType, "WorkMath", 0 ) != -1)		//kill the SANS_Data graph if needed
		DoWindow/K SANS_Data
	Endif
	KillDataFolder root:Packages:NIST:WorkMath
End

// loads data into the specified folder
//
// currently unused since button has been removed from panel
//
Function WorkMath_Load_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String destStr=""
	SVAR folderList=root:Packages:NIST:WorkMath:gFolderList
	Prompt destStr,"Select the destination folder",popup,folderList
	DoPrompt "Folder for ASC Load",destStr
	
	if(V_flag==1)
		return(1)		//user abort, do nothing
	Endif
	
	String destFolder = "WorkMath:"+destStr
	
	Load_ASC_File("Pick the ASC file",destFolder)
End

// changes the display of the SANS_Data window based on popped data type
// first loads in the data from the File1 or File2 popup as needed
// then displays the selcted dataset, if it exists
// makes use of procedure from DisplayUtils
//
// - Always replaces File1 or File2 with fresh data from disk
//
Function WorkMath_Display_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String folder="WorkMath:",pathStr,str1

	PathInfo catPathName
	pathStr=S_Path
	
	//if display result, just do it and return
	if(cmpstr(popStr,"Result")==0)
		Execute "ChangeDisplay(\""+folder+popstr+"\")"
		return(0)
	endif
	// if file1 or file2, load in the data and display
	if(cmpstr(popStr,"File_1")==0)
		ControlInfo popup0
		str1 = S_Value
	Endif
	if(cmpstr(popStr,"File_2")==0)
		ControlInfo popup1
		str1 = S_Value
	Endif
	//don't load or display the unit matrix
	Print str1
	if(cmpstr(str1,"UNIT MATRIX")!=0)
		Load_NamedASC_File(pathStr+str1,folder+popStr)
		//change the display
		Execute "ChangeDisplay(\""+folder+popstr+"\")"
	endif
	return(0)	
End

//simple panel to do workfile arithmetic
//
Proc WorkFileMath()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(610,211,880,490)/K=2 as "Work File Math"		// replace /K=2 flag
	DoWindow/C WorkFileMath
	ModifyPanel cbRGB=(47802,54484,6682)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 6,166,214,166
	SetDrawEnv fstyle= 4
	DrawText 10,34,"File #1:"
	SetDrawEnv fstyle= 4
	DrawText 13,129,"File #2:"
	DrawText 78,186,"= Result"
	Button button0,pos={28,245},size={50,20},proc=WorkMath_DoIt_ButtonProc,title="Do It"
	Button button0,help={"Performs the specified arithmetic"}
	Button button1,pos={183,245},size={50,20},proc=WorkMath_Done_ButtonProc,title="Done"
	Button button1,help={"Closes the panel"}
//	Button button2,pos={30,8},size={110,20},proc=WorkMath_Load_ButtonProc,title="Load ASC Data"
//	Button button2,help={"Loads ASC data files into the specified folder"}
	Button button3,pos={205,8},size={25,20},proc=ShowWorkMathHelp,title="?"
	Button button3,help={"Show help file for math operations on 2-D data sets"}
	SetVariable setvar0,pos={9,46},size={70,15},title=" "
	SetVariable setvar0,limits={-Inf,Inf,0},value= root:Packages:NIST:WorkMath:const1
	SetVariable setvar0,help={"Multiplicative constant for the first dataset"}
	PopupMenu popup0,pos={89,44},size={84,20},title="X  "
	PopupMenu popup0,mode=1,popvalue="1st Set",value= ASC_FileList()
	PopupMenu popup0,help={"Selects the first dataset for the operation"}
	PopupMenu popup1,pos={93,136},size={89,20},title="X  "
	PopupMenu popup1,mode=1,popvalue="2nd Set",value= "UNIT MATRIX;"+ASC_FileList()
	PopupMenu popup1,help={"Selects the second dataset for the operation"}
	PopupMenu popup2,pos={50,82},size={70,20},title="Operator  "
	PopupMenu popup2,mode=3,popvalue="Operation",value= #"\"+;_;*;/;\""
	PopupMenu popup2,help={"Selects the mathematical operator"}
	SetVariable setvar1,pos={13,139},size={70,15},title=" "
	SetVariable setvar1,limits={-Inf,Inf,0},value= root:Packages:NIST:WorkMath:const2
	SetVariable setvar1,help={"Multiplicative constant for the second dataset"}
//	PopupMenu popup3,pos={27,167},size={124,20},title=" = Destination"
//	PopupMenu popup3,mode=1,popvalue="Destination",value= root:Packages:NIST:WorkMath:gFolderList
//	PopupMenu popup3,help={"Selects the destination folder"}
	PopupMenu popup4,pos={55,204},size={103,20},proc=WorkMath_Display_PopMenuProc,title="Display"
	PopupMenu popup4,mode=3,value= "File_1;File_2;Result;"
	PopupMenu popup4,help={"Displays the data in the specified folder"}
EndMacro

//jump to the help topic
Function ShowWorkMathHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[2-D Work File Arithmetic]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//utility function to clear the contents of a data folder
//won't clear data that is in use - 
//
Function ClearDataFolder(type)
	String type
	
	SetDataFolder $("root:Packages:NIST:"+type)
	KillWaves/a/z
	KillStrings/a/z
	KillVariables/a/z
	SetDataFolder root:
End



//fileStr must be the FULL path and filename on disk
//destFolder is the path to the Igor folder where the data is to be deposited
// - "Packages:NIST:WorkMath:File_1" for example, compatible with SANS_Data display type
//
Function Load_NamedASC_File(fileStr,destFolder)
	String fileStr,destFolder

	Variable refnum
	
	//read in the data
	ReadASCData(fileStr,destFolder)

	//the calling macro must change the display type
	String/G root:myGlobals:gDataDisplayType=destFolder
	
	FillFakeHeader_ASC(destFolder) 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	
	fRawWindowHook()
	
	return(0)
End


//function called by the main entry procedure (the load button)
//loads data into the specified folder, and wipes out what was there
//
//aborts if no file was selected
//
// reads the data in if all is OK
//
// currently unused, as load button has been replaced
//
Function Load_ASC_File(msgStr,destFolder)
	String msgStr,destFolder

	String filename="",pathStr=""
	Variable refnum

	//check for the path
	PathInfo catPathName
	If(V_Flag==1)		//	/D does not open the file
		Open/D/R/T="????"/M=(msgStr)/P=catPathName refNum
	else
		Open/D/R/T="????"/M=(msgStr) refNum
	endif
	filename = S_FileName		//get the filename, or null if canceled from dialog
	if(strlen(filename)==0)
		//user cancelled, abort
		SetDataFolder root:
		Abort "No file selected, action aborted"
	Endif
	
	//read in the data
	ReadASCData(filename,destFolder)

	//the calling macro must change the display type
	String/G root:myGlobals:gDataDisplayType=destFolder
	
	FillFakeHeader_ASC(destFolder) 		//uses info on the panel, if available

	//data is displayed here, and needs header info
	
	fRawWindowHook()
	
	return(0)
End



//function called by the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
Function/S ASC_FileList()

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		Return("")
	Endif
	
	list = IndexedFile(catpathName,-1,"????")
	num=ItemsInList(list,";")
	//print "num = ",num
	for(ii=(num-1);ii>=0;ii-=1)
		item = StringFromList(ii, list  ,";")
		//simply remove all that are not raw data files (SA1 SA2 SA3)
		if( !stringmatch(item,"*.SA1*") && !stringmatch(item,"*.SA2*") && !stringmatch(item,"*.SA3*") )
			if( !stringmatch(item,".*") && !stringmatch(item,"*.pxp") && !stringmatch(item,"*.DIV"))		//eliminate mac "hidden" files, pxp, and div files
				if(!stringmatch(item,"*.AVE") && !stringmatch(item,"*.ABS"))
					newlist += item + ";"
				endif
			endif
		endif
	endfor
	//remove VAX version numbers
	newList = RemoveVersNumsFromList(newList)
	//sort
	newList = SortList(newList,";",0)

	return newlist
End