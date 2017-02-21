#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#pragma version=5.0
//#pragma IgorVersion=6.1

// Updated for VSANS Jan2017
//
// largely duplication of the SANS subtractions and error propagation.
// Changes: (1) the beam center mismatch is ALWAYS ignored. It is flagged, and alerted, but nothing is shifted
//          (2) the condition of trans == 1 is not flagged, and there is no stopping for user input
// 
// TODO -- verify the operation of all modes
// -- decide if/how to implement/re-implement the trans == 1 check and dialog
// -- decide if the beam center mismatch is ever to be re-implemented
// -- check the monitor count calls and rescaled values (correct monitor? where is rescaling written?)
//




//
// Procedures to perform the "Correct" step during data reduction
//
// - there is only one procedure to perform the subtractions, and a single 
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

//
// test procedure for Correct() function
//must be updated to include "mode" parameter before re-use
//
Proc V_CorrectData(cor_mode)
	Variable cor_mode=4
	
	Variable err
	String cor_type
	
	err = V_Correct(cor_mode)		
	
	if(err)
		Abort "error in V_Correct"
	endif
	
	//contents are always dumped to COR
	cor_type = "COR"
	
	// set the global string	
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=cor_type
	
	//need to update the display with "data" from the correct dataFolder
	UpdateDisplayInformation(cor_type)
	
End

//
// dispatch function to correct data
//
// --determines the mode of subtraction
// --TODO (checks for trans=1 in SAM and EMP) - not currently implemented
// --checks for existence of data in WORK folders
// --clears out the COR folder
// --calls the correct correct
//
//
//mode describes the type of subtraction that is to be done
//1 = both emp and bgd subtraction
//2 = only bgd subtraction
//3 = only emp subtraction
//4 = no subtraction
//
// + 10 indicates that WORK.DRK is to be used
//
//091301 version
//now simply dispatches to the correct subtraction - logic was too
//involved to do in one function - unclear and error-prone
//
// 081203 version
// checks for trans==1 in SAM and EMP before dispatching
// and asks for new value if desired
//
//
//
Function V_Correct(cor_mode)
	Variable cor_mode
	
	Variable err=0,trans,newTrans
	
	//switch and dispatch based on the required subtractions
	// always check for SAM data
	err = V_WorkDataExists("SAM")
	if(err==1)
		return(err)
	endif
	
	// TODO -- this is currently not implemented	
	//check for trans==1
//	NVAR doCheck=root:Packages:NIST:gDoTransCheck
//	Wave/Z samR=root:Packages:NIST:SAM:RealsRead
//	Wave/Z empR=root:Packages:NIST:EMP:RealsRead
//	if(doCheck)
//		trans = samR[4]
//		newTrans=GetNewTrans(trans,"SAM")		//will change value if necessary
//		if(numtype(newTrans)==0)
//			samR[4] = newTrans		//avoid user abort assigning NaN
//		endif
//		if(trans != newTrans)
//			print "Using SAM trans = ",samR[4]
//		endif
//	endif
	
	//copy SAM information to COR, wiping out the old contents of the COR folder first
	//do this even if no correction is dispatched (if incorrect mode)

	V_CopyHDFToWorkFolder("SAM","COR")	

	
//	Print "dispatching to mode = ",mode
	switch(cor_mode)
		case 1:
			err = V_WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			// TODO -- not implemented
//			if(doCheck)
//				trans = empR[4]
//				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
//				if(numtype(newTrans)==0)
//					empR[4] = newTrans
//				endif
//				if(trans != newTrans)
//					print "Using EMP trans = ",empR[4]
//				endif
//			endif
			err = V_WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_1()
			break
		case 2:
			err = V_WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_2()
			break
		case 3:
			err = V_WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			// TODO - not implemented
//			if(doCheck)
//				trans = empR[4]
//				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
//				if(numtype(newTrans)==0)
//					empR[4] = newTrans
//				endif
//				if(trans != newTrans)
//					print "Using EMP trans = ",empR[4]
//				endif
//			endif

			err = V_CorrectMode_3()
			break
		case 4:
			err = V_CorrectMode_4()
			break
		case 11:
			err = V_WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			// TODO -- not implemented
//			if(doCheck)
//				trans = empR[4]
//				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
//				if(numtype(newTrans)==0)
//					empR[4] = newTrans
//				endif
//				if(trans != newTrans)
//					print "Using EMP trans = ",empR[4]
//				endif
//			endif
			err = V_WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = V_WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_11()
			break
		case 12:
			err = V_WorkDataExists("BGD")
			if(err==1)
				return(err)
			Endif
			err = V_WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_12()
			break
		case 13:
			err = V_WorkDataExists("EMP")
			if(err==1)
				return(err)
			Endif
			// TODO -- not implemented
//			if(doCheck)
//				trans = empR[4]
//				newTrans=GetNewTrans(trans,"EMP")		//will change value if necessary
//				if(numtype(newTrans)==0)
//					empR[4] = newTrans
//				endif
//				if(trans != newTrans)
//					print "Using EMP trans = ",empR[4]
//				endif
//			endif
			err = V_WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_13()
			break
		case 14:
			err = V_WorkDataExists("DRK")
			if(err==1)
				return(err)
			Endif
			err = V_CorrectMode_14()
			break
		default:	//something wrong
			Print "Incorrect mode in V_Correct()"
			return(1)	//error
	endswitch

	//calculation attempted, return the result
	return(err)	
End

// subtraction of both EMP and BGD from SAM
// data exists, checked by dispatch routine
//
// this is the most common use
// March 2011 added error propagation
//					added explicit reference to use linear_data, instead of trusting that data
//					was freshly loaded. added final copy of cor result to cor:data and cor:linear_data
//
// TODO -- verify the operation
//  -- check that all "get" reads are returning proper values (+units)
//
Function V_CorrectMode_1()

	//get SAM, BGD, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	bgd_AttenFactor = V_getAttenuator_transmission("BGD")
	bgd_atten_err = V_getAttenuator_trans_err("BGD")
	emp_AttenFactor = V_getAttenuator_transmission("EMP")
	emp_atten_err = V_getAttenuator_trans_err("EMP")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count

	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonemp = V_getMonitorCount("EMP")		//monitor count in EMP
	temp = V_getSampleTransmission("EMP")			//trans emp
	emp_trans_err = V_getSampleTransError("EMP")
	
	tmonbgd = V_getMonitorCount("BGD")		//monitor count in BGD


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave bgd_data = V_getDetectorDataW("BGD",detStr)
		Wave bgd_err = V_getDetectorDataErrW("BGD",detStr)
		Wave emp_data = V_getDetectorDataW("EMP",detStr)
		Wave emp_err = V_getDetectorDataErrW("EMP",detStr)
		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cbgd = V_getDet_beam_center_x("BGD",detStr)
		rbgd = V_getDet_beam_center_y("BGD",detStr)
	
		cemp = V_getDet_beam_center_x("EMP",detStr)		//beamcenter of EMP
		remp = V_getDet_beam_center_y("EMP",detStr)
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
	
		Duplicate/O cor_data cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data arrays, EMP and BGD, each relative to SAM
	
		xshift = cbgd-csam
		yshift = rbgd-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the BGD file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for BGD file. Data has NOT been corrected."
		endif
		bgd_temp = bgd_data		// no shift, no effect
		noadd_bgd = 1
		//GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp
	
		xshift = cemp-csam
		yshift = remp-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the EMP file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for EMP file. Data has NOT been corrected."
		endif
		emp_temp = emp_data // no shift, no effect
		noadd_emp = 1
		//GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp


		// *******
		//do the subtraction
		fsam=1
		femp = tmonsam/tmonemp		//this should be ==1 since normalized files
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
		cor1 = fsam*sam_data/sam_attenFactor - fbgd*bgd_temp/bgd_attenFactor
		cor1 -= (tsam/temp)*(femp*emp_temp/emp_attenFactor - fbgd*bgd_temp/bgd_attenFactor)
		cor1 *= noadd_bgd*noadd_emp		//zero out the array mismatch values
	
		cor_data = cor1		//the final result
		
		// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_b, tmp_c, tmp_d,c_val,d_val
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_b = (bgd_err/bgd_attenFactor)^2*(tsam/temp - 1)^2 + (bgd_atten_err*bgd_data/bgd_attenFactor^2)^2*(1-tsam/temp)^2		//sig b ^2
	
		tmp_c = (sam_trans_err/temp)^2*(emp_data/emp_attenFactor-bgd_data/bgd_attenFactor)^2
		tmp_c += (tsam/temp^2)^2*emp_trans_err^2*(emp_data/emp_attenFactor-bgd_data/bgd_attenFactor)^2
		
		tmp_d = (tsam/(temp*emp_attenFactor))^2*(emp_err)^2 + (tsam*emp_data/(temp*emp_attenFactor^2))^2*(emp_atten_err)^2
	
		cor_err = sqrt(tmp_a + tmp_b + tmp_c + tmp_d)
	
	endfor
	
	//we're done, get out w/no error

	
	//TODO -- do I update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp
	Killwaves/Z tmp_a,tmp_b,tmp_c,tmp_d,c_val,d_val
	
	SetDataFolder root:
	Return(0)
End

//background only
// existence of data checked by dispatching routine
// data has already been copied to COR folder
Function V_CorrectMode_2()

	//get SAM, BGD attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	bgd_AttenFactor = V_getAttenuator_transmission("BGD")
	bgd_atten_err = V_getAttenuator_trans_err("BGD")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count

	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonbgd = V_getMonitorCount("BGD")		//monitor count in BGD


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave bgd_data = V_getDetectorDataW("BGD",detStr)
		Wave bgd_err = V_getDetectorDataErrW("BGD",detStr)

		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cbgd = V_getDet_beam_center_x("BGD",detStr)
		rbgd = V_getDet_beam_center_y("BGD",detStr)

	
		Duplicate/O cor_data cor1,bgd_temp,noadd_bgd

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data array BGD, relative to SAM
	
		xshift = cbgd-csam
		yshift = rbgd-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the BGD file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for BGD file. Data has NOT been corrected."
		endif
		bgd_temp = bgd_data		// no shift, no effect
		noadd_bgd = 1
		//GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp
	

		// **********	
		//do the sam-bgd subtraction,  deposit result in cor1
		fsam = 1
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
		
		//print "fsam,fbgd = ",fsam,fbgd
		
		cor1 = fsam*sam_data/sam_AttenFactor - fbgd*bgd_temp/bgd_AttenFactor
		cor1 *= noadd_bgd		//zeros out regions where arrays do not overlap, one otherwise
	
		cor_data = cor1		//the final result

	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_b
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_b = (bgd_err/bgd_attenFactor)^2 + (bgd_atten_err*bgd_data/bgd_attenFactor^2)^2		//sig b ^2
	
		cor_err = sqrt(tmp_a + tmp_b)

	endfor

	//we're done, get out w/no error

	// TODO -- do I update COR header?
	//cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd
	Killwaves/Z tmp_a,tmp_b

	SetDataFolder root:
	Return(0)
End

// empty subtraction only
// data does exist, checked by dispatch routine
//
Function V_CorrectMode_3()

	//get SAM, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	emp_AttenFactor = V_getAttenuator_transmission("EMP")
	emp_atten_err = V_getAttenuator_trans_err("EMP")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count

	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonemp = V_getMonitorCount("EMP")		//monitor count in EMP
	temp = V_getSampleTransmission("EMP")			//trans emp
	emp_trans_err = V_getSampleTransError("EMP")
	

	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave emp_data = V_getDetectorDataW("EMP",detStr)
		Wave emp_err = V_getDetectorDataErrW("EMP",detStr)
		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cemp = V_getDet_beam_center_x("EMP",detStr)		//beamcenter of EMP
		remp = V_getDet_beam_center_y("EMP",detStr)
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
	
		Duplicate/O cor_data cor1,emp_temp,noadd_emp

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data array EMP, each relative to SAM
	
		xshift = cemp-csam
		yshift = remp-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the EMP file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for EMP file. Data has NOT been corrected."
		endif
		emp_temp = emp_data // no shift, no effect
		noadd_emp = 1
		//GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp

		// **********
	
		//do the sam-bgd subtraction,  deposit result in cor1
		fsam = 1
		femp = tmonsam/tmonemp		//this should be ==1 since normalized files
		
		cor1 = fsam*sam_data/sam_AttenFactor - femp*(tsam/temp)*emp_temp/emp_AttenFactor
		cor1 *= noadd_emp		//zeros out regions where arrays do not overlap, one otherwise

		cor_data = cor1		//the final result
	
	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_c ,c_val
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_c = (sam_trans_err*emp_data/(temp*emp_attenFactor))^2 + (emp_err*tsam/(temp*emp_attenFactor))^2
		tmp_c += (tsam*emp_data*emp_trans_err/(temp*temp*emp_attenFactor))^2 + (tsam*emp_data*emp_atten_err/(temp*emp_attenFactor^2))^2//total of 6 terms
	
		cor_err = sqrt(tmp_a + tmp_c)
	
	endfor
	
	//we're done, get out w/no error

	// TODO -- do I update COR header?
	//cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,emp_temp,noadd_emp
	Killwaves/Z tmp_a,tmp_c,c_val

	SetDataFolder root:
	Return(0)
End

// NO subtraction - simply rescales for attenuators
// SAM data does exist, checked by dispatch routine
// SAM data has already been copied to COR (both are the same at the start of the function)
//
//  TODO -- do I need to rescale to sam_trans here ??
//
//
Function V_CorrectMode_4()

	//get SAM attenuation factor
	Variable sam_AttenFactor,sam_atten_err,ii
	String detStr
	
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")


	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
	
	
		cor_data = sam_data/sam_AttenFactor		//simply rescale the data
	
	// do the error propagation piecewise
		cor_err = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		cor_err = sqrt(cor_err)

	endfor
	
	//TODO -- do I want to update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	SetDataFolder root:
	Return(0)
End



Function V_CorrectMode_11()

	//get SAM, BGD, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	Variable savmon_sam,time_sam,time_drk
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	bgd_AttenFactor = V_getAttenuator_transmission("BGD")
	bgd_atten_err = V_getAttenuator_trans_err("BGD")
	emp_AttenFactor = V_getAttenuator_transmission("EMP")
	emp_atten_err = V_getAttenuator_trans_err("EMP")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count
	
	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonemp = V_getMonitorCount("EMP")		//monitor count in EMP
	temp = V_getSampleTransmission("EMP")			//trans emp
	emp_trans_err = V_getSampleTransError("EMP")
	
	tmonbgd = V_getMonitorCount("BGD")		//monitor count in BGD

	// for proper scaling, get the time and actual monitor counts
	// TODO -- make sure that these calls are reading the proper values
	savmon_sam = V_getBeamMonNormSaved_count("SAM")		//true monitor count in SAM
	time_sam = V_getCount_time("SAM")		//count time SAM
	time_drk = V_getCount_time("DRK")	//drk count time


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave bgd_data = V_getDetectorDataW("BGD",detStr)
		Wave bgd_err = V_getDetectorDataErrW("BGD",detStr)
		Wave emp_data = V_getDetectorDataW("EMP",detStr)
		Wave emp_err = V_getDetectorDataErrW("EMP",detStr)
		Wave drk_data = V_getDetectorDataW("DRK",detStr)
		Wave drk_err = V_getDetectorDataErrW("DRK",detStr)
		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cbgd = V_getDet_beam_center_x("BGD",detStr)
		rbgd = V_getDet_beam_center_y("BGD",detStr)
	
		cemp = V_getDet_beam_center_x("EMP",detStr)		//beamcenter of EMP
		remp = V_getDet_beam_center_y("EMP",detStr)
		
		//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
		Duplicate/O drk_data drk_temp, drk_tmp_err
		drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
		drk_tmp_err *= drk_err*(time_sam/time_drk)*(tmonsam/savmon_sam)			//temporarily rescale the error of DRK	
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
		Duplicate/O cor_data cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data arrays, EMP and BGD, each relative to SAM
	
		xshift = cbgd-csam
		yshift = rbgd-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the BGD file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for BGD file. Data has NOT been corrected."
		endif
		bgd_temp = bgd_data		// no shift, no effect
		noadd_bgd = 1
		//GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp
	
		xshift = cemp-csam
		yshift = remp-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the EMP file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for EMP file. Data has NOT been corrected."
		endif
		emp_temp = emp_data // no shift, no effect
		noadd_emp = 1
		//GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp


		//always ignore the DRK center shift
	
		// ************	
		//do the subtraction
		fsam=1
		femp = tmonsam/tmonemp		//this should be ==1 since normalized files
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
		cor1 = fsam*sam_data/sam_attenFactor
		cor1 -= (tsam/temp)*(femp*emp_temp/emp_attenFactor - fbgd*bgd_temp/bgd_attenFactor)
		cor1 -= (fbgd*bgd_temp/bgd_attenFactor - drk_temp)
		cor1 -= drk_temp/sam_attenFactor
		cor1 *= noadd_bgd*noadd_emp		//zero out the array mismatch values

		cor_data = cor1		//the final result
		
	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_b, tmp_c, tmp_d,c_val,d_val
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_b = (bgd_err/bgd_attenFactor)^2*(tsam/temp - 1)^2 + (bgd_atten_err*bgd_data/bgd_attenFactor^2)^2*(1-tsam/temp)^2		//sig b ^2
	
		tmp_c = (sam_trans_err/temp)^2*(emp_data/emp_attenFactor-bgd_data/bgd_attenFactor)^2
		tmp_c += (tsam/temp^2)^2*emp_trans_err^2*(emp_data/emp_attenFactor-bgd_data/bgd_attenFactor)^2
		
		tmp_d = (tsam/(temp*emp_attenFactor))^2*(emp_err)^2 + (tsam*emp_data/(temp*emp_attenFactor^2))^2*(emp_atten_err)^2
	
		cor_err = sqrt(tmp_a + tmp_b + tmp_c + tmp_d + drk_tmp_err^2)
	
	endfor
	
	//we're done, get out w/no error


	//TODO -- do I update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,emp_temp,noadd_emp,drk_temp
	Killwaves/Z tmp_a,tmp_b,tmp_c,tmp_d,c_val,d_val,drk_tmp_err

	SetDataFolder root:
	Return(0)
End

//bgd and drk subtraction
//
Function V_CorrectMode_12()

	//get SAM, BGD, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	Variable savmon_sam,time_sam,time_drk
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	bgd_AttenFactor = V_getAttenuator_transmission("BGD")
	bgd_atten_err = V_getAttenuator_trans_err("BGD")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count
	
	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonbgd = V_getMonitorCount("BGD")		//monitor count in BGD

	// for proper scaling, get the time and actual monitor counts
	// TODO -- make sure that these calls are reading the proper values
	savmon_sam = V_getBeamMonNormSaved_count("SAM")		//true monitor count in SAM
	time_sam = V_getCount_time("SAM")		//count time SAM
	time_drk = V_getCount_time("DRK")	//drk count time


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave bgd_data = V_getDetectorDataW("BGD",detStr)
		Wave bgd_err = V_getDetectorDataErrW("BGD",detStr)
		Wave drk_data = V_getDetectorDataW("DRK",detStr)
		Wave drk_err = V_getDetectorDataErrW("DRK",detStr)
		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cbgd = V_getDet_beam_center_x("BGD",detStr)
		rbgd = V_getDet_beam_center_y("BGD",detStr)
		
		//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
		Duplicate/O drk_data drk_temp, drk_tmp_err
		drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
		drk_tmp_err *= drk_err*(time_sam/time_drk)*(tmonsam/savmon_sam)			//temporarily rescale the error of DRK	
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
		Duplicate/O cor_data cor1,bgd_temp,noadd_bgd

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data arrays, EMP and BGD, each relative to SAM
	
		xshift = cbgd-csam
		yshift = rbgd-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the BGD file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for BGD file. Data has NOT been corrected."
		endif
		bgd_temp = bgd_data		// no shift, no effect
		noadd_bgd = 1
		//GetShiftedArray(bgd_data,bgd_temp,noadd_bgd,xshift,yshift)		//bgd_temp


		//always ignore the DRK center shift

		// ************	
		//do the sam-bgd subtraction,  deposit result in cor1
		fsam = 1
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
		
		cor1 = fsam*sam_data/sam_AttenFactor + fbgd*tsam*bgd_temp/bgd_AttenFactor
		cor1 += -1*(fbgd*bgd_temp/bgd_attenFactor - drk_temp) - drk_temp/sam_attenFactor
		cor1 *= noadd_bgd		//zeros out regions where arrays do not overlap, one otherwise

		cor_data = cor1		//the final result
	
	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_b
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_b = (bgd_err/bgd_attenFactor)^2 + (bgd_atten_err*bgd_data/bgd_attenFactor^2)^2		//sig b ^2
	
		cor_err = sqrt(tmp_a + tmp_b + drk_tmp_err^2)

	endfor
	
	//we're done, get out w/no error
	
	// TODO -- do I update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,drk_temp
	Killwaves/Z tmp_a,tmp_b,drk_tmp_err

	SetDataFolder root:
	Return(0)
End

//EMP and DRK subtractions
// all data exists, DRK is on a time basis (noNorm)
//scale DRK by monitor count scaling factor and the ratio of couting times
//to place the DRK file on equal footing
Function V_CorrectMode_13()

	//get SAM, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	Variable savmon_sam,time_sam,time_drk
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")
	emp_AttenFactor = V_getAttenuator_transmission("EMP")
	emp_atten_err = V_getAttenuator_trans_err("EMP")

	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count
	
	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	
	tmonemp = V_getMonitorCount("EMP")		//monitor count in EMP
	temp = V_getSampleTransmission("EMP")			//trans emp
	emp_trans_err = V_getSampleTransError("EMP")

	// for proper scaling, get the time and actual monitor counts
	// TODO -- make sure that these calls are reading the proper values
	savmon_sam = V_getBeamMonNormSaved_count("SAM")		//true monitor count in SAM
	time_sam = V_getCount_time("SAM")		//count time SAM
	time_drk = V_getCount_time("DRK")	//drk count time


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave emp_data = V_getDetectorDataW("EMP",detStr)
		Wave emp_err = V_getDetectorDataErrW("EMP",detStr)
		Wave drk_data = V_getDetectorDataW("DRK",detStr)
		Wave drk_err = V_getDetectorDataErrW("DRK",detStr)
		
	// to check for beam center mismatch -- simply warn, but do no shift
	//

		csam = V_getDet_beam_center_x("SAM",detStr)		//x center
		rsam = V_getDet_beam_center_y("SAM",detStr)		//beam (x,y) define center of corrected field
	
		cemp = V_getDet_beam_center_x("EMP",detStr)		//beamcenter of EMP
		remp = V_getDet_beam_center_y("EMP",detStr)
		
		//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
		Duplicate/O drk_data drk_temp, drk_tmp_err
		drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
		drk_tmp_err *= drk_err*(time_sam/time_drk)*(tmonsam/savmon_sam)			//temporarily rescale the error of DRK	
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
		Duplicate/O cor_data cor1,emp_temp,noadd_emp

		// TODO -- document this, make a note, so everyone knows this is not done
		// skip this part, but duplicate the results of no shift condition
		//  where bgd_temp = input data, and noadd_bgd = 1 (so no data is zeroed out)
		
			//get the shifted data arrays, EMP , each relative to SAM
	
		xshift = cemp-csam
		yshift = remp-rsam
		if(abs(xshift) <= wcen)
			xshift = 0
		Endif
		if(abs(yshift) <= wcen)
			yshift = 0
		Endif
		// for the EMP file - alert if needed, generate dummy "pass-through" values
		//
		if(xshift != 0 || yshift != 0)
			DoAlert 0, "Beam center mismatch for EMP file. Data has NOT been corrected."
		endif
		emp_temp = emp_data // no shift, no effect
		noadd_emp = 1
		//GetShiftedArray(emp_data,emp_temp,noadd_emp,xshift,yshift)		//emp_temp


		//always ignore the DRK center shift
		
		// ***************	
		//do the sam-bgd subtraction,  deposit result in cor1
		fsam = 1
		femp = tmonsam/tmonemp		//this should be ==1 since normalized files
		
		cor1 = fsam*sam_data/sam_AttenFactor - femp*(tsam/temp)*emp_temp/emp_AttenFactor
		cor1 += drk_temp - drk_temp/sam_attenFactor
		cor1 *= noadd_emp		//zeros out regions where arrays do not overlap, one otherwise

		cor_data = cor1		//the final result
	
	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a, tmp_c, c_val
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
		
		tmp_c = (sam_trans_err*emp_data/(temp*emp_attenFactor))^2 + (emp_err*tsam/(temp*emp_attenFactor))^2
		tmp_c += (tsam*emp_data*emp_trans_err/(temp*temp*emp_attenFactor))^2 + (tsam*emp_data*emp_atten_err/(temp*emp_attenFactor^2))^2//total of 6 terms
		
		cor_err = sqrt(tmp_a + tmp_c + drk_tmp_err^2)

	endfor
		
	//we're done, get out w/no error

	// TODO -- do I update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,emp_temp,noadd_emp,drk_temp
	Killwaves/Z tmp_a,tmp_c,c_val,drk_tmp_err

	SetDataFolder root:
	Return(0)
End

// ONLY drk subtraction
//
Function V_CorrectMode_14()

	//get SAM, EMP attenuation factor
	Variable sam_AttenFactor,sam_atten_err,sam_trans_err
	Variable bgd_AttenFactor,bgd_atten_err
	Variable emp_AttenFactor,emp_atten_err,emp_trans_err
	Variable ii
	String detStr
	Variable tmonsam,fsam,fbgd,xshift,yshift,rsam,csam,rbgd,cbgd,tmonbgd
	Variable wcen=0.001,tsam,temp,remp,cemp,tmonemp,femp
	Variable savmon_sam,time_sam,time_drk
	
	// these values apply to all of the detectors
	sam_AttenFactor = V_getAttenuator_transmission("SAM")
	sam_atten_err = V_getAttenuator_trans_err("SAM")


	//get relative monitor counts (should all be 10^8, since normalized in add step)
	// get transmission and trans error for SAM, EMP
	// TODO -- verify that the  call to V_getMonitorCount() is really rescaled to 10^8, and saved is the "true" count
	
	tmonsam = V_getMonitorCount("SAM")		//monitor count in SAM
	tsam = V_getSampleTransmission("SAM")		//SAM transmission
	sam_trans_err = V_getSampleTransError("SAM")
	

	// for proper scaling, get the time and actual monitor counts
	// TODO -- make sure that these calls are reading the proper values
	savmon_sam = V_getBeamMonNormSaved_count("SAM")		//true monitor count in SAM
	time_sam = V_getCount_time("SAM")		//count time SAM
	time_drk = V_getCount_time("DRK")	//drk count time


	// and now loop through all of the detectors
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave cor_data = V_getDetectorDataW("COR",detStr)
		Wave cor_err = V_getDetectorDataErrW("COR",detStr)
		Wave sam_data = V_getDetectorDataW("SAM",detStr)
		Wave sam_err = V_getDetectorDataErrW("SAM",detStr)
		Wave drk_data = V_getDetectorDataW("DRK",detStr)
		Wave drk_err = V_getDetectorDataErrW("DRK",detStr)
		
		
		//rescale drk to sam cnt time and then multiply by the same monitor scaling as SAM
		Duplicate/O drk_data drk_temp, drk_tmp_err
		drk_temp = drk_data*(time_sam/time_drk)*(tmonsam/savmon_sam)
		drk_tmp_err *= drk_err*(time_sam/time_drk)*(tmonsam/savmon_sam)			//temporarily rescale the error of DRK	
		
		if(temp==0)
			DoAlert 0,"Empty Cell transmission was zero. It has been reset to one for the subtraction"
			temp=1
		Endif
	
		Duplicate/O cor_data cor1

		//always ignore the DRK center shift

		// ************
		//do the subtraction,  deposit result in cor1
		fsam = 1
		fbgd = tmonsam/tmonbgd	//this should be ==1 since normalized files
		
		//correct sam for attenuators, and do the same to drk, since it was scaled to sam count time
		cor1 = fsam*sam_data/sam_AttenFactor  - drk_temp/sam_attenFactor

		cor_data = cor1		//the final result
	
	// do the error propagation piecewise	
		Duplicate/O sam_err, tmp_a
		tmp_a = (sam_err/sam_attenFactor)^2 + (sam_atten_err*sam_data/sam_attenFactor^2)^2		//sig a ^2
	
		cor_err = sqrt(tmp_a + drk_tmp_err^2)

	endfor
		
	//we're done, get out w/no error
	
	//TODO -- do I update COR header?
//	cor_text[1] = date() + " " + time()		//date + time stamp

	KillWaves/Z cor1,bgd_temp,noadd_bgd,drk_temp
	Killwaves/Z tmp_a,tmp_b,tmp_c,tmp_d,c_val,d_val,drk_tmp_err

	SetDataFolder root:
	Return(0)
End


//
// For VSANS - this should go away. if there is a mismatch, don't try to fudge it.
//
//
//function to return the shifted contents of a data array for subtraction
//(SLOW) if ShiftSum is called
//data_in is input
//data_out is shifted matrix
//noadd_mat =1 if shift matrix is valid, =0 if no data
//
//if no shift is required, data_in is returned and noadd_mat =1 (all valid)
//
xFunction V_GetShiftedArray(data_in,data_out,noadd_mat,xshift,yshift)
	WAVE data_in,data_out,noadd_mat
	Variable xshift,yshift

	Variable ii=0,jj=0
	noadd_mat = 1		//initialize to 1
	
	If((xshift != 0) || (yshift != 0))
//	If((abs(xshift) >= 0.01) || (abs(yshift) >= 0.01))			//APR09 - loosen tolerance to handle ICE "precision"
		DoAlert 1,"Do you want to ignore the beam center mismatch?"
		if(V_flag==1)		//yes -> just go on
			xshift=0
			yshift=0
		endif
	else
		// "mismatch" is simply a python type conversion error
		xshift=0
		yshift=0
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

//
//utility function that checks if data exists in a data folder
//checks only for the existence of data in detector FL - no other waves
//
Function V_WorkDataExists(type)
	String type
	
	String destPath=""
	destPath = "root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_FL:data"
	if(WaveExists($destpath) == 0)
		Print "There is no work file in "+type
		Return(1)		//error condition
	else
		// data exists, assume everything else is OK and proceed.
		return(0)
	Endif
End

//////////////////
// bunch of utility junk to catch
// sample transmission = 1
// and handle (too many) options
//
xFunction V_GetNewTrans(oldTrans,type)
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
		Variable/G root:Packages:NIST:gDoTransCheck=0	//turn off checking
	endif
	
	if(newcode==2)		//user changed trans value
		return(newTrans)
	else
		return(oldTrans)	//All other cases, user did not change value
	endif
end

xFunction V_IgnoreNowButton(ctrlName) : ButtonControl
	String ctrlName
	
//	Print "ignore now"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=0		//code for ignore once
	
	DoWindow/K tmp_GetInputPanel		// Kill self
End

xFunction V_DoTransInput(str)
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

xFunction V_IgnoreAlwaysButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "ignore always"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=1		//code for ignore always
	DoWindow/K tmp_GetInputPanel		// Kill self
End

xFunction V_UseNewValueButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "use new Value"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=2		//code for use new Value
	DoWindow/K tmp_GetInputPanel		// Kill self
End

xFunction V_AbortCorrectionButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	Print "Abort"
	NVAR val=root:myGlobals:tmp_trans:returnCode
	val=4		//code for abort
	DoWindow/K tmp_GetInputPanel		// Kill self
End

