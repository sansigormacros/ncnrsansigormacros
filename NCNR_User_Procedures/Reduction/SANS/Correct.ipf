#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

//****************************
// Vers 1.2 090501
//
//****************************
//
// Procedures to perform the "Correct" step during data reduction
//
// - ther is olny one procedure to perform the subtractions, and a single 
// parameter flags which subtractions are to be done. Different numbers of 
// attenuators during scattering runs are corrected as described in John's memo,
// with the note that ONLY method (3) is used, which assumes that 'diffuse' scattering
// is dominant over 'dark current' (note that 'dark current' = shutter CLOSED)
//
// 
//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction 
	//additional modes 091301
	//11 = emp, bgd, drk
	//12 = bgd and drk
	//13 = emp and drk
	//14 = no subtractions
	//
//********************************

//unused test procedure for Correct() function
//must be updated to include "mode" parameter before re-use
//
Proc CorrectData()

	Variable err
	String type
	
	err = Correct()		
	
	if(err)
		Abort "error in Correct"
	endif
	
	//contents are always dumped to COR
	type = "COR"
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=Type
	
	fRawWindowHook()
	
End


//mode describes the type of subtraction that is to be done
//1 = both emp and bgd subtraction
//2 = only bgd subtraction
//3 = only emp subtraction
//4 = no subtraction
//
// + 10 indicates that WORK.DRK is to be used
//
//091301 version
//now simple dispatches to the correct subtraction - logic was too
//involved to do in one function - unclear and error-prone
//
// 081203 version
// checks for trans==1 in SAM and EMP before dispatching
// and asks for new value if desired
//
Function Correct(mode)
	Variable mode
	
	Variable err=0,trans,newTrans
	
	//switch and dispatch based on the required subtractions
	// always check for SAM data
	err = WorkDataExists("SAM")
	if(err==1)
		return(err)
	endif
	
	
	//check for trans==1
	NVAR doCheck=root:myGlobals:gDoTransCheck
	Wave/Z samR=root:Packages:NIST:SAM:RealsRead
	Wave/Z empR=root:Packages:NIST:EMP:RealsRead
	if(doCheck)
		trans = samR[4]
		newTrans=GetNewTrans(trans,"SAM")		//will change value if necessary
		if(numtype(newTrans)==0)
			samR[4] = newTrans		//avoid user abort assigning NaN
		endif
		if(trans != newTrans)
			print "Using SAM trans = ",samR[4]
		endif
	endif
	
	//copy SAM information to COR, wiping out the old contents of the COR folder first
	//do this even if no correction is dispatched (if incorrect mode)
	err = CopyWorkContents("SAM","COR")	
	if(err==1)
		Abort "No data in SAM, abort from Correct()"
	endif
	
//	Print "dispatching to mode = ",mode
	switch(mode)
		case 1:
			err = WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			if(doCheck)
				trans = empR[4]
				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
				if(numtype(newTrans)==0)
					empR[4] = newTrans
				endif
				if(trans != newTrans)
					print "Using EMP trans = ",empR[4]
				endif
			endif
			err = WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_1()
			break
		case 2:
			err = WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_2()
			break
		case 3:
			err = WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			if(doCheck)
				trans = empR[4]
				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
				if(numtype(newTrans)==0)
					empR[4] = newTrans
				endif
				if(trans != newTrans)
					print "Using EMP trans = ",empR[4]
				endif
			endif
			err = CorrectMode_3()
			break
		case 4:
			err = CorrectMode_4()
			break
		case 11:
			err = WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			if(doCheck)
				trans = empR[4]
				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
				if(numtype(newTrans)==0)
					empR[4] = newTrans
				endif
				if(trans != newTrans)
					print "Using EMP trans = ",empR[4]
				endif
			endif
			err = WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_11()
			break
		case 12:
			err = WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_12()
			break
		case 13:
			err = WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			if(doCheck)
				trans = empR[4]
				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
				if(numtype(newTrans)==0)
					empR[4] = newTrans
				endif
				if(trans != newTrans)
					print "Using EMP trans = ",empR[4]
				endif
			endif
			err = WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_13()
			break
		case 14:
			err = WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = CorrectMode_14()
			break
		default:	//something wrong
			Print "Incorrect mode in Correct()"
			return(1)	//error
	endswitch

	//calculation attempted, return the result
	return(err)	
End

// subtraction of bot EMP and BGD from SAM
// data exists, checked by dispatch routine
//
Function CorrectMode_1()
	
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE bgd_data=$"root:Packages:NIST:BGD:data"
	WAVE bgd_reals=$"root:Packages:NIST:BGD:realsread"
	WAVE bgd_ints=$"root:Packages:NIST:BGD:integersread"
	WAVE/T bgd_text=$"root:Packages:NIST:BGD:textread"
	WAVE emp_data=$"root:Packages:NIST:EMP:data"
	WAVE emp_reals=$"root:Packages:NIST:EMP:realsread"
	WAVE emp_ints=$"root:Packages:NIST:EMP:integersread"
	WAVE/T emp_text=$"root:Packages:NIST:EMP:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,bgd_attenFactor,emp_AttenFactor
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = bgd_text[3]
	lambda = bgd_reals[26]
	attenNo = bgd_reals[3]
	bgd_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = emp_text[3]
	lambda = emp_reals[26]
	attenNo = emp_reals[3]
	emp_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonbgd = bgd_reals[0]		//monitor count in BGD
	cbgd = bgd_reals[16]
	rbgd = bgd_reals[17]
	tmonemp = emp_reals[0]		//monitor count in EMP
	temp = emp_reals[4]			//trans emp
	cemp = emp_reals[16]		//beamcenter of EMP
	remp = emp_reals[17]
	
	if(temp==0)
		DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
		temp=1
	Endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//get the shifted data arrays, EMP and BGD, each relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp
	xshift = cbgd-csam
	yshift = rbgd-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp
	
	xshift = cemp-csam
	yshift = remp-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp

	//do the subtraction
	fsam=1
	femp = tmonsam/tmonemp		//this should be ==1 since normalized files
	fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	cor1 = fsam*sam_data/sam_attenFactor - fbgd*bgd_temp/bgd_attenFactor
	cor1 -= (tsam/temp)*(femp*emp_temp/emp_attenFactor - fbgd*bgd_temp/bgd_attenFactor)
	cor1 *= noadd_bgd*noadd_emp		//zero out the array mismatch values
	
	//we're done, get out w/no error
	//set the COR data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp
	SetDataFolder root:
	Return(0)
End

//background only
// existence of data checked by dispatching routine
// data has already been copied to COR folder
Function CorrectMode_2()

	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE bgd_data=$"root:Packages:NIST:BGD:data"
	WAVE bgd_reals=$"root:Packages:NIST:BGD:realsread"
	WAVE bgd_ints=$"root:Packages:NIST:BGD:integersread"
	WAVE/T bgd_text=$"root:Packages:NIST:BGD:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,bgd_attenFactor
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = bgd_text[3]
	lambda = bgd_reals[26]
	attenNo = bgd_reals[3]
	bgd_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//Print "atten = ",sam_attenFactor,bgd_attenFactor
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonbgd = bgd_reals[0]		//monitor count in BGD
	cbgd = bgd_reals[16]
	rbgd = bgd_reals[17]

	// set up beamcenter shift, relative to SAM
	xshift = cbgd-csam
	yshift = rbgd-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//get shifted data arrays, relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,bgd_temp,noadd_bgd		//temp arrays
	GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp is the BGD 
	
	//do the sam-bgd subtraction,  deposit result in cor1
	fsam = 1
	fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	
	//print "fsam,fbgd = ",fsam,fbgd
	
	cor1 = fsam*sam_data/sam_AttenFactor - fbgd*bgd_temp/bgd_AttenFactor
	cor1 *= noadd_bgd		//zeros out regions where arrays do not overlap, one otherwise

	//we're done, get out w/no error
	//set the COR_data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd
	SetDataFolder root:
	Return(0)
End

// empty subtraction only
// data does exist, checked by dispatch routine
//
Function CorrectMode_3()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE emp_data=$"root:Packages:NIST:EMP:data"
	WAVE emp_reals=$"root:Packages:NIST:EMP:realsread"
	WAVE emp_ints=$"root:Packages:NIST:EMP:integersread"
	WAVE/T emp_text=$"root:Packages:NIST:EMP:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,emp_attenFactor
	Variable tmonsam,fsam,femp,xshift,yshift,rsam,csam,remp,cemp,tmonemp
	Variable wcen=0.001,tsam,temp
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = emp_text[3]
	lambda = emp_reals[26]
	attenNo = emp_reals[3]
	emp_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonemp = emp_reals[0]		//monitor count in EMP
	temp = emp_reals[4]			//trans emp
	cemp = emp_reals[16]		//beamcenter of EMP
	remp = emp_reals[17]
	
	if(temp==0)
		DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
		temp=1
	Endif
	
	//Print "rbgd,cbgd = ",rbgd,cbgd
	// set up beamcenter shift, relative to SAM
	xshift = cemp-csam
	yshift = remp-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//get shifted data arrays, relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,emp_temp,noadd_emp		//temp arrays
	GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp is the EMP
	
	//do the sam-bgd subtraction,  deposit result in cor1
	fsam = 1
	femp = tmonsam/tmonemp		//this should be ==1 since normalized files
	
	cor1 = fsam*sam_data/sam_AttenFactor - femp*(tsam/temp)*emp_temp/emp_AttenFactor
	cor1 *= noadd_emp		//zeros out regions where arrays do not overlap, one otherwise

	//we're done, get out w/no error
	//set the COR data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,emp_temp,noadd_emp
	SetDataFolder root:
	Return(0)
End

// NO subtraction - simply rescales for attenuators
// SAM data does exist, checked by dispatch routine
//
// !! moves data to COR folder, since the data has been corrected, by rescaling
//
Function CorrectMode_4()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"

	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	Make/D/O/N=(pixelsX,pixelsY) cor1
	
	cor1 = sam_data/sam_AttenFactor		//simply rescale the data

	//we're done, get out w/no error
	//set the COR data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1
	SetDataFolder root:
	Return(0)
End

Function CorrectMode_11()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE bgd_data=$"root:Packages:NIST:BGD:data"
	WAVE bgd_reals=$"root:Packages:NIST:BGD:realsread"
	WAVE bgd_ints=$"root:Packages:NIST:BGD:integersread"
	WAVE/T bgd_text=$"root:Packages:NIST:BGD:textread"
	WAVE emp_data=$"root:Packages:NIST:EMP:data"
	WAVE emp_reals=$"root:Packages:NIST:EMP:realsread"
	WAVE emp_ints=$"root:Packages:NIST:EMP:integersread"
	WAVE/T emp_text=$"root:Packages:NIST:EMP:textread"
	WAVE drk_data=$"root:Packages:NIST:DRK:data"
	WAVE drk_reals=$"root:Packages:NIST:DRK:realsread"
	WAVE drk_ints=$"root:Packages:NIST:DRK:integersread"
	WAVE/T drk_text=$"root:Packages:NIST:DRK:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,bgd_attenFactor,emp_AttenFactor
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp,time_sam,time_drk,savmon_sam
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = bgd_text[3]
	lambda = bgd_reals[26]
	attenNo = bgd_reals[3]
	bgd_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = emp_text[3]
	lambda = emp_reals[26]
	attenNo = emp_reals[3]
	emp_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonbgd = bgd_reals[0]		//monitor count in BGD
	cbgd = bgd_reals[16]
	rbgd = bgd_reals[17]
	tmonemp = emp_reals[0]		//monitor count in EMP
	temp = emp_reals[4]			//trans emp
	cemp = emp_reals[16]		//beamcenter of EMP
	remp = emp_reals[17]
	savmon_sam=sam_reals[1]		//true monitor count in SAM
	time_sam = sam_ints[2]		//count time SAM
	time_drk = drk_ints[2]		//drk count time
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
	Make/D/O/N=(pixelsX,pixelsY) drk_temp
	drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
	
	if(temp==0)
		DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
		temp=1
	Endif
	
	//get the shifted data arrays, EMP and BGD, each relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp
	xshift = cbgd-csam
	yshift = rbgd-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp
	
	xshift = cemp-csam
	yshift = remp-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp
	//always ignore the DRK center shift
	
	//do the subtraction
	fsam=1
	femp = tmonsam/tmonemp		//this should be ==1 since normalized files
	fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	cor1 = fsam*sam_data/sam_attenFactor
	cor1 -= (tsam/temp)*(femp*emp_temp/emp_attenFactor - fbgd*bgd_temp/bgd_attenFactor)
	cor1 -= (fbgd*bgd_temp/bgd_attenFactor - drk_temp)
	cor1 -= drk_temp/sam_attenFactor
	cor1 *= noadd_bgd*noadd_emp		//zero out the array mismatch values
	
	//we're done, get out w/no error
	//set the COR data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp,drk_temp
	SetDataFolder root:
	Return(0)
End

//bgd and drk subtraction
//
Function CorrectMode_12()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE bgd_data=$"root:Packages:NIST:BGD:data"
	WAVE bgd_reals=$"root:Packages:NIST:BGD:realsread"
	WAVE bgd_ints=$"root:Packages:NIST:BGD:integersread"
	WAVE/T bgd_text=$"root:Packages:NIST:BGD:textread"
	WAVE drk_data=$"root:Packages:NIST:DRK:data"
	WAVE drk_reals=$"root:Packages:NIST:DRK:realsread"
	WAVE drk_ints=$"root:Packages:NIST:DRK:integersread"
	WAVE/T drk_text=$"root:Packages:NIST:DRK:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,bgd_attenFactor
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,time_drk,time_sam,savmon_sam,tsam
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = bgd_text[3]
	lambda = bgd_reals[26]
	attenNo = bgd_reals[3]
	bgd_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonbgd = bgd_reals[0]		//monitor count in BGD
	cbgd = bgd_reals[16]
	rbgd = bgd_reals[17]
	savmon_sam=sam_reals[1]		//true monitor count in SAM
	time_sam = sam_ints[2]		//count time SAM
	time_drk = drk_ints[2]		//drk count time
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
	Make/D/O/N=(pixelsX,pixelsY) drk_temp
	drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
	
	// set up beamcenter shift, relative to SAM
	xshift = cbgd-csam
	yshift = rbgd-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	//get shifted data arrays, relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,bgd_temp,noadd_bgd		//temp arrays
	GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp is the BGD 
	//always ignore the DRK center shift
	
	//do the sam-bgd subtraction,  deposit result in cor1
	fsam = 1
	fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	
	cor1 = fsam*sam_data/sam_AttenFactor + fbgd*tsam*bgd_temp/bgd_AttenFactor
	cor1 += -1*(fbgd*bgd_temp/bgd_attenFactor - drk_temp) - drk_temp/sam_attenFactor
	cor1 *= noadd_bgd		//zeros out regions where arrays do not overlap, one otherwise

	//we're done, get out w/no error
	//set the COR_data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

//	KillWaves/Z cor1,bgd_temp,noadd_bgd,drk_temp
	SetDataFolder root:
	Return(0)
End

//EMP and DRK subtractions
// all data exists, DRK is on a time basis (noNorm)
//scale DRK by monitor count scaling factor and the ratio of couting times
//to place the DRK file on equal footing
Function CorrectMode_13()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"
	WAVE emp_data=$"root:Packages:NIST:EMP:data"
	WAVE emp_reals=$"root:Packages:NIST:EMP:realsread"
	WAVE emp_ints=$"root:Packages:NIST:EMP:integersread"
	WAVE/T emp_text=$"root:Packages:NIST:EMP:textread"
	WAVE drk_data=$"root:DRK:data"
	WAVE drk_reals=$"root:DRK:realsread"
	WAVE drk_ints=$"root:DRK:integersread"
	WAVE/T drk_text=$"root:DRK:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors (DRK irrelevant)
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,emp_attenFactor
	Variable tmonsam,fsam,femp,xshift,yshift,rsam,csam,remp,cemp,tmonemp
	Variable wcen=0.001,tsam,temp,savmon_sam,time_sam,time_drk
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	fileStr = emp_text[3]
	lambda = emp_reals[26]
	attenNo = emp_reals[3]
	emp_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	tmonemp = emp_reals[0]		//monitor count in EMP
	temp = emp_reals[4]			//trans emp
	cemp = emp_reals[16]		//beamcenter of EMP
	remp = emp_reals[17]
	savmon_sam=sam_reals[1]		//true monitor count in SAM
	time_sam = sam_ints[2]		//count time SAM
	time_drk = drk_ints[2]		//drk count time
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
	Make/D/O/N=(pixelsX,pixelsY) drk_temp
	drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
	
	if(temp==0)
		DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
		temp=1
	Endif
	
	//Print "rbgd,cbgd = ",rbgd,cbgd
	// set up beamcenter shift, relative to SAM
	xshift = cemp-csam
	yshift = remp-rsam
	if(abs(xshift) <= wcen)
		xshift = 0
	Endif
	if(abs(yshift) <= wcen)
		yshift = 0
	Endif
	//get shifted data arrays, relative to SAM
	Make/D/O/N=(pixelsX,pixelsY) cor1,emp_temp,noadd_emp		//temp arrays
	GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp is the EMP
	//always ignore beamcenter shift for DRK
	
	//do the sam-bgd subtraction,  deposit result in cor1
	fsam = 1
	femp = tmonsam/tmonemp		//this should be ==1 since normalized files
	
	cor1 = fsam*sam_data/sam_AttenFactor - femp*(tsam/temp)*emp_temp/emp_AttenFactor
	cor1 += drk_temp - drk_temp/sam_attenFactor
	cor1 *= noadd_emp		//zeros out regions where arrays do not overlap, one otherwise

	//we're done, get out w/no error
	//set the COR data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,emp_temp,noadd_emp,drk_temp
	SetDataFolder root:
	Return(0)
End

// ONLY drk subtraction
//
Function CorrectMode_14()
	//create the necessary wave references
	WAVE sam_data=$"root:Packages:NIST:SAM:data"
	WAVE sam_reals=$"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints=$"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text=$"root:Packages:NIST:SAM:textread"

	WAVE drk_data=$"root:DRK:data"
	WAVE drk_reals=$"root:DRK:realsread"
	WAVE drk_ints=$"root:DRK:integersread"
	WAVE/T drk_text=$"root:DRK:textread"
	WAVE cor_data=$"root:Packages:NIST:COR:data"
	WAVE/T cor_text=$"root:Packages:NIST:COR:textread"
	
	//get sam and bgd attenuation factors
	String fileStr=""
	Variable lambda,attenNo,sam_AttenFactor,bgd_attenFactor
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,time_drk,time_sam,savmon_sam,tsam
	fileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	sam_AttenFactor = AttenuationFactor(fileStr,lambda,AttenNo)
	
	//get relative monitor counts (should all be 10^8, since normalized in add step)
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field

	savmon_sam=sam_reals[1]		//true monitor count in SAM
	time_sam = sam_ints[2]		//count time SAM
	time_drk = drk_ints[2]		//drk count time
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
	Make/D/O/N=(pixelsX,pixelsY) drk_temp
	drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
	
	Make/D/O/N=(pixelsX,pixelsY) cor1	//temp arrays
	//always ignore the DRK center shift
	
	//do the subtraction,  deposit result in cor1
	fsam = 1
	fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	
	//correct sam for attenuators, and do the same to drk, since it was scaled to sam count time
	cor1 = fsam*sam_data/sam_AttenFactor  - drk_temp/sam_attenFactor

	//we're done, get out w/no error
	//set the COR_data to the result
	cor_data = cor1
	//update COR header
	cor_text[1] = date() + " " + time()		//date + time stamp

//	KillWaves/Z cor1,bgd_temp,noadd_bgd,drk_temp
	SetDataFolder root:
	Return(0)
End


//function to return the shifted contents of a data array for subtraction
//(SLOW) if ShiftSum is called
//data_in is input
//data_out is shifted matrix
//noadd_mat =1 if shift matrix is valid, =0 if no data
//
//if no shift is required, data_in is returned and noadd_mat =1 (all valid)
//
Function GetShiftedArray(data_in,data_out,noadd_mat,xshift,yshift)
	WAVE data_in,data_out,noadd_mat
	Variable xshift,yshift

	Variable ii=0,jj=0
	noadd_mat = 1		//initialize to 1
	
	If((xshift != 0) || (yshift != 0))
		DoAlert 1,"Do you want to ignore the beam center mismatch?"
		if(V_flag==1)		//yes -> just go on
			xshift=0
			yshift=0
		endif
	endif
	
	If((xshift == 0) && (yshift == 0))
		data_out=data_in		//no change
		noadd_mat = 1			//use all of the data
		return(0)
	endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Print "beamcenter shift x,y = ",xshift,yshift
	Make/O/N=1 noadd
	for(ii=0;ii<pixelsX;ii+=1)
		for(jj=0;jj<pixelsY;jj+=1)
			//get the contribution of the shifted data
			data_out[ii][jj] = ShiftSum(data_in,ii,jj,xshift,yshift,noadd)
			if(noadd[0])
				noadd_mat[ii][jj] = 0	//shift is off the detector
			endif
		endfor
	endfor
	return(0)
End

//utility function that checks if data exists in a data folder
//checks only for the existence of DATA - no other waves
//
Function WorkDataExists(type)
	String type
	
	String destPath=""
	destPath =  "root:Packages:NIST:"+Type + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+type
		Return(1)		//error condition
	else
		//check for log-scaling of the data and adjust if necessary
		ConvertFolderToLinearScale(type)
		return(0)
	Endif
End

//////////////////
// bunch of utility junk to catch
// sample transmission = 1
// and handle (too many) options
//
Function GetNewTrans(oldTrans,type)
	Variable oldTrans
	String type
	
	Variable newTrans,newCode
	if (oldTrans!=1)
		return(oldTrans)		//get out now if trans != 1, don't change anything
	endif
	//get input from the user
	NewDataFolder/O root:myGlobals:tmp_trans
	Variable/G root:myGlobals:tmp_trans:inputTrans=0.92
	Variable/G root:myGlobals:tmp_trans:returnCode=0
	DoTransInput(type)
	NVAR inputTrans=root:myGlobals:tmp_trans:inputTrans
	NVAR code=root:myGlobals:tmp_trans:returnCode
	newTrans=inputTrans		//keep a copy before deleting everything
	newCode=code
	if(newCode==4)
		Abort "Aborting correction. Use the Transmission Panel to calculate transmissions"
	Endif
//	printf "You entered %g and the code is %g\r",newTrans,newCode
//	KillDataFolder root:tmp_trans
	
	if(newCode==1)
		Variable/G root:myGlobals:gDoTransCheck=0	//turn off checking
	endif
	
	if(newcode==2)		//user changed trans value
		return(newTrans)
	else
		return(oldTrans)	//All other cases, user did not change value
	endif
end

Function IgnoreNowButton(ctrlName) : ButtonControl
	String ctrlName
	
//	Print "ignore now"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=0		//code for ignore once
	
	DoWindow/K tmp_GetInputPanel		// Kill self
End

Function DoTransInput(str)
	String str
	
	NewPanel /W=(150,50,361,294)
	DoWindow/C tmp_GetInputPanel		// Set to an unlikely name
	DrawText 15,23,"The "+str+" Transmission = 1"
	DrawText 15,43,"What do you want to do?"
	DrawText 15,125,"(Reset this in Preferences)"
	SetVariable setvar0,pos={20,170},size={160,17},limits={0,1,0.01}
	SetVariable setvar0,value= root:myGlobals:tmp_trans:inputTrans,title="New Transmission"

	Button button0,pos={36,56},size={120,20},proc=IgnoreNowButton,title="Ignore This Time"
	Button button1,pos={36,86},size={120,20},proc=IgnoreAlwaysButtonProc,title="Ignore Always"
	Button button2,pos={36,143},size={120,20},proc=UseNewValueButtonProc,title="Use New Value"
	Button button3,pos={36,213},size={120,20},proc=AbortCorrectionButtonProc,title="Abort Correction"
	PauseForUser tmp_GetInputPanel
End

Function IgnoreAlwaysButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "ignore always"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=1		//code for ignore always
	DoWindow/K tmp_GetInputPanel		// Kill self
End

Function UseNewValueButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "use new Value"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=2		//code for use new Value
	DoWindow/K tmp_GetInputPanel		// Kill self
End

Function AbortCorrectionButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "Abort"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=4		//code for abort
	DoWindow/K tmp_GetInputPanel		// Kill self
End

//////////////////////////
//**********unused***********
//mode describes the type of subtraction that is to be done
//1 = both emp and bgd subtraction
//2 = only bgd subtraction
//3 = only emp subtraction
//4 = no subtraction (handled by ExecuteProtocol(), but implemented here as well)
//
// + 10 indicates that WORK.DRK is to be used
//**********unused***********
//**worse yet, only partially converted to use DRK files!***********
//
Function OLD_Correct(mode)
	Variable mode
	
	//Print "mode = ",mode
	if(mode==4)
		Print "no subtraction required - Correct(mode) should not have been called"
		return(1)		//error - correct should not have been called
	Endif
	
	// always check for existence of data in SAM
	// if the desired workfile doesn't exist, let the user know, and abort
	String destPath
	String type = "SAM"
	//check for SAM
	destPath = "root:Packages:NIST:"+Type + ":data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+type+"--Aborting"
		Return(1) 		//error condition
	else
		//check for log-scaling of the "SAM" data and adjust if necessary
		ConvertFolderToLinearScale(type)
		Wave sam_data = $"root:Packages:NIST:SAM:data"
	Endif
	
	//check for BGD if mode = 1 or 2 or 11 or 12
	if( (mode ==1) || (mode==2) || (mode==11) || (mode==12) )
		type = "BGD"
		destPath =  "root:Packages:NIST:"+Type + ":data"
		if(WaveExists($destpath) == 0)
			Print "There is no work file in "+type+"--Aborting"
			Return(1)		//error condition
		else
			//check for log-scaling of the "BGD" data and adjust if necessary
			ConvertFolderToLinearScale(type)
			Wave bgd_data = $"root:Packages:NIST:BGD:data"
		Endif
	Endif
	
	// check for EMP data if type 3 or 1 or 13 or 11
	if( (mode==1) || (mode==3) || (mode==11) || (mode==13) )
		type = "EMP"
		destPath =  "root:Packages:NIST:"+Type + ":data"
		if(WaveExists($destpath) == 0)
			Print "There is no work file in "+type+"--Aborting"
			Return(1)		//error condition
		else
			//check for log-scaling of the "EMP" data and adjust if necessary
			ConvertFolderToLinearScale(type)
			Wave emp_data = $"root:Packages:NIST:EMP:data"
		Endif
	Endif
	
	// check for DRK data if type 11,12,13, or 14
	if( (mode==11) || (mode==12) || (mode==13) || (mode==14) )
		type = "DRK"
		destPath =  "root:Packages:NIST:"+Type + ":data"
		if(WaveExists($destpath) == 0)
			Print "There is no work file in "+type+"--Aborting"
			Return(1)		//error condition
		else
			//check for log-scaling of the "EMP" data and adjust if necessary
			ConvertFolderToLinearScale(type)
			Wave drk_data = $"root:DRK:data"
		Endif
	Endif
	
	//necessary files exist, proceed

	//make needed wave references to other folders
	//NOTE that these references MAY NOT EXIST, depending on the mode
	WAVE sam_reals = $"root:Packages:NIST:SAM:realsread"
	WAVE sam_ints = $"root:Packages:NIST:SAM:integersread"
	WAVE/T sam_text = $"root:Packages:NIST:SAM:textread"
	WAVE/Z emp_reals = $"root:Packages:NIST:EMP:realsread"
	WAVE/Z emp_ints = $"root:Packages:NIST:EMP:integersread"
	WAVE/T/Z emp_text = $"root:Packages:NIST:EMP:textread"
	WAVE/Z bgd_reals = $"root:Packages:NIST:BGD:realsread"
	WAVE/Z bgd_ints = $"root:Packages:NIST:BGD:integersread"
	WAVE/T/Z bgd_text = $"root:Packages:NIST:BGD:textread"
	
	//find the attenuation of the sample (if any)
	Variable SamAttenFactor,lambda,attenNo,err=0
	String samfileStr=""
	samfileStr = sam_text[3]
	lambda = sam_reals[26]
	attenNo = sam_reals[3]
	SamAttenFactor = AttenuationFactor(samFileStr,lambda,AttenNo)
	//if sample trans is zero, do only SAM-BGD subtraction (notify the user)
	Variable sam_trans = sam_reals[4]
	
	//copy SAM information to COR, wiping out the old contents of the COR folder first
	err = CopyWorkContents("SAM","COR")	
	if(err==1)
		Abort "No data in SAM, abort from Correct()"
	endif
	
	//now switch to COR folder
	DestPath="root:Packages:NIST:COR"
	//make appropriate wave references
	WAVE data=$(destPath + ":data")					// these wave references point to the SAM data in COR
	WAVE/T textread=$(destPath + ":textread")			//that are to be directly operated on
	WAVE integersread=$(destPath + ":integersread")
	WAVE realsread=$(destPath + ":realsRead")

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//Print "done copying data, starting the correct calculations"
	
	// Start the actual "correct" step here
	Variable wcen=0.001,numsam,tmonsam,tsam,rsam,csam,fsam
	Variable tmonbgd,fbgd,xshift,yshift,rbgd,cbgd,sh_sum,ii,jj,trans,tmonemp,temp,femp
	Variable cemp,remp
	//make temporary waves to hold the intermediate results and the shifted arrays
	Duplicate/O data cor1,cor2
	cor1 = 0		//initialize to zero
	cor2 = 0
	
	//make needed wave references to other folders
	Wave sam_reals = $"root:Packages:NIST:SAM:realsread"
	Wave bgd_reals = $"root:Packages:NIST:BGD:realsread"
	Wave emp_reals = $"root:Packages:NIST:EMP:realsread"
	
	//get counts, trans, etc. from file headers
	numsam = sam_ints[3]		//number of runs in SAM file
	tmonsam = sam_reals[0]		//monitor count in SAM
	tsam = sam_reals[4]		//SAM transmission
	csam = sam_reals[16]		//x center
	rsam = sam_reals[17]		//beam (x,y) define center of corrected field
	//Print "rsam,csam = ",rsam,csam
	
	//
	//do sam-bgd subtraction if mode (1) or (2)
	//else (mode 3), set cor1 = sam_data
	if( (mode==1) || (mode==2) )
		fsam = 1
		tmonbgd = bgd_reals[0]		//monitor count in BGD
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
	
		//set up  center shift, relative to SAM
		cbgd = bgd_reals[16]
		rbgd = bgd_reals[17]
		//Print "rbgd,cbgd = ",rbgd,cbgd
		xshift = cbgd-csam
		yshift = rbgd-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		
		If((xshift != 0) || (yshift != 0))
			DoAlert 1,"Do you want to ignore the beam center mismatch?"
			if(V_flag==1)		//yes -> just go on
				xshift=0
				yshift=0
			endif
		endif
		//do the sam-bgd subtraction,  deposit result in cor1[][]
		If((xshift == 0) && (yshift == 0))
			//great, no shift required
			cor1 = fsam*sam_data - fbgd*bgd_data*SamAttenFactor
		else
			//shift required, very time-consuming
			Print "sam-bgd shift x,y = ",xshift,yshift
			Make/O/N=1 noadd		//needed to get noadd condition back from ShiftSum()
			ii=0
			do
				jj=0
				do
					//get the contribution of shifted data
					sh_sum = ShiftSum(bgd_data,ii,jj,xshift,yshift,noadd)
					if(noadd[0])
						cor1[ii][jj]=0
					else
						//add the sam_data + shifted sum 
						cor1[ii][jj] = fsam*sam_data[ii][jj] - fbgd*sh_sum*SamAttenFactor
					Endif
					jj+=1
				while(jj<pixelsY)
				ii+=1
			while(ii<pixelsX)
		Endif
	else			//switch on mode
		cor1 = sam_data		//setup for just EMP subtraction
	Endif
	
	//Print "sam-bgd done"
	
	if(mode == 2)		//just a BGD subtraction
		//we're done, get out w/no error
		//set the COR data to the result
		data = cor1
		//update COR header
		textread[1] = date() + " " + time()		//date + time stamp
		SetDataFolder root:
		KillWaves/Z cor1,cor2
		Return(0)
	Endif
	
	//if mode ==1 (ONLY choice left) do the empty-background subtraction
	//else mode = 3, set cor2 to emp_data
	if(mode==1)		//full subtraction
		trans = emp_reals[4]		//EMP transmission
		if(trans == 0)
			trans = 1
			DoAlert 0,"Empty cell transmission was zero. It has been reset to one for the calculation"
		endif
		tmonemp = emp_reals[0]
		femp = tmonsam/tmonemp
		temp = trans
	
		//set up center shift, relative to EMP
		cemp = emp_reals[16]
		remp = emp_reals[17]
		//Print "remp,cemp ",remp,cemp
		xshift = cbgd - cemp
		yshift = rbgd - remp
		if(abs(xshift) <= wcen )
			xshift = 0
		endif
		if(abs(yshift) <= wcen)
			yshift = 0
		endif
		
		If((xshift != 0) || (yshift != 0))
			DoAlert 1,"Do you want to ignore the beam center mismatch?"
			if(V_flag==1)
				xshift=0
				yshift=0
			endif
		endif
		//do the emp-bgd subtraction,  deposit result in cor2[][]
		If((xshift == 0) && (yshift == 0))
			//great, no shift required, DON'T scale this by the attenuation gfactor
			cor2 = femp*emp_data - fbgd*bgd_data
		else
			//shift required, very time-consuming
			Print "emp-bgd shift x,y = ",xshift,yshift
			Make/O/N=1 noadd		//needed to get noadd condition back from ShiftSum()
			ii=0
			do
				jj=0
				do
					//get the contribution of shifted data
					sh_sum = ShiftSum(bgd_data,ii,jj,xshift,yshift,noadd)
					if(noadd[0])
						cor2[ii][jj]=0
					else
						//add the sam_data + shifted sum 
						cor2[ii][jj] = femp*emp_data[ii][jj] - fbgd*sh_sum
					Endif
					jj+=1
				while(jj<pixelsY)
				ii+=1
			while(ii<pixelsX)
		Endif
	else		//switch on mode==1 for full subtraction
		cor2 = emp_data
		//be sure to set the empty center location... for the shift
		trans = emp_reals[4]		//EMP transmission
		if(trans == 0)
			trans = 1
			DoAlert 0,"Empty cell transmission was zero. It has been reset to one for the calculation"
		endif
		tmonemp = emp_reals[0]
		femp = tmonsam/tmonemp
		temp = trans
	
		//set up center shift, relative to EMP
		cemp = emp_reals[16]
		remp = emp_reals[17]
	Endif
	
	//Print "emp-bgd done"
	
	//mode 2 exited, either 1 or 3 apply from here, and are setup properly.
	
	//set up for final step, data(COR) = cor1 - Tsam/Temp*cor2
	//set up shift, relative to SAM
	xshift = cemp - csam
	yshift = remp - rsam
	if(abs(xshift) <= wcen )
		xshift = 0
	endif
	if(abs(yshift) <= wcen)
		yshift = 0
	endif
	
	If((xshift != 0) || (yshift != 0))
		DoAlert 1,"Do you want to ignore the beam center mismatch?"
		if(V_flag==1)
			xshift=0
			yshift=0
		endif
	endif
	//do the cor1-a*cor2 subtraction,  deposit result in data[][] (in the COR folder)
	If((xshift == 0) && (yshift == 0))
		//great, no shift required
		data = cor1 - (tsam/temp)*cor2*SamAttenFactor
	else
		//shift required, very time-consuming
		Print "sam-emp shift x,y = ",xshift,yshift
		Make/O/N=1 noadd		//needed to get noadd condition back from ShiftSum()
		ii=0
		do
			jj=0
			do
				//get the contribution of shifted data
				sh_sum = ShiftSum(cor2,ii,jj,xshift,yshift,noadd)
				if(noadd[0])
					data[ii][jj]=0
				else
					//add the sam_data + shifted sum 
					data[ii][jj] = cor1[ii][jj] - (tsam/temp)*sh_sum*SamAttenFactor
				Endif
				jj+=1
			while(jj<pixelsY)
			ii+=1
		while(ii<pixelsX)
	Endif
	
	//Print "all done"
	
	//update COR header
	textread[1] = date() + " " + time()		//date + time stamp
	
	//clean up
	SetDataFolder root:Packages:NIST:COR
	SetDataFolder root:
	KillWaves/Z cor1,cor2,noadd

	Return(0)		//all is ok, if you made it to this point
End
