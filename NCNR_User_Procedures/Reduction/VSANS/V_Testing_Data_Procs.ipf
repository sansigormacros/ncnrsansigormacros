#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



//////// function to take VCALC information and 
// fill in the simulated information as needed to make a "fake" data file
//
// TODO:
// -- identify all of the necessary bits to change
// -- maybe want a panel to make it easier to decide what inputs to change in the file
// -- decide if it's better to write wholesale, or as individual waves
//
Proc Copy_VCALC_to_VSANSFile(labelStr,intent,group_id)
	String labelStr = "sample label"
	String intent = "SAMPLE"
	variable group_id = 75
	
	String fileName = V_DoSaveFileDialog("pick the file to write to")
	print fileName
//	
	if(strlen(fileName) > 0)
		writeVCALC_to_file(fileName,labelStr,intent,group_id)
	endif
End

//
// TODO -- fill this in as needed to get fake data that's different
//
Function writeVCALC_to_file(fileName,labelStr,intent,group_id)
	String fileName,labelStr,intent
	Variable group_id


// the detectors, all 9 + the correct SDD (that accounts for the offset of T/B panels
// the data itself (as INT32)
// the front SDD (correct units)
// the middle SDD (correct units)
// the back SDD (correct units)
	Variable ii,val,sumCts=0
	String detStr
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Duplicate/O $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+detStr+":det_"+detStr) tmpData
		Redimension/I tmpData
		//
		// before, NaN became ugly integer -- now it seems to show up as -1?
		// then, the "fake" error becomes NaN
		tmpData	= (tmpData ==   2147483647) ? 0 : tmpData		//the NaN "mask" in the sim data (T/B only)shows up as an ugly integer
		tmpData	= (tmpData ==   -1) ? 0 : tmpData		//the NaN "mask" in the sim data (T/B only)shows up as -1
		V_writeDetectorData(fileName,detStr,tmpData)
		
		val = VCALC_getSDD(detStr)*100		// make sure value is in cm
		print val
		V_writeDet_distance(fileName,detStr,val)
		
		val = VCALC_getTopBottomSDDOffset(detStr)		//val is in mm, as for data file
		if(val != 0)
			V_writeDet_TBSetback(fileName,detStr,val)
		endif
		
		// returns the total separation (assumed symmetric) in mm
		val = VCALC_getPanelSeparation(detStr)		
		val /= 2*10			// to get half of the separation, and convert to cm for the data file
		// it's OK to call both of these. these functions check detStr for the correct value
		V_writeDet_LateralOffset(fileName,detStr,val)
		V_writeDet_VerticalOffset(fileName,detStr,val)

		// x and y pixel sizes for each detector should be correct in the "base" file - but if not...
		//Function VCALC_getPixSizeX(type)		// returns the pixel X size, in [cm]
		//Function VCALC_getPixSizeY(type)
		V_writeDet_x_pixel_size(fileName,detStr,VCALC_getPixSizeX(detStr)*10)		// data file is expecting mm
		V_writeDet_y_pixel_size(fileName,detStr,VCALC_getPixSizeY(detStr)*10)
	
		// write out the xCtr and yCtr (pixels) that was used in the q-calculation, done in VC_CalculateQFrontPanels()
		if(kBCTR_CM)
		//  -- now write out the beam center in cm, not pixels
			V_writeDet_beam_center_x(fileName,detStr,0)
			V_writeDet_beam_center_y(fileName,detStr,0)
		else
			V_writeDet_beam_center_x(fileName,detStr,V_getDet_beam_center_x("VCALC",detStr))
			V_writeDet_beam_center_y(fileName,detStr,V_getDet_beam_center_y("VCALC",detStr))	
		endif

		if(cmpstr(detStr,"B") == 0)
			//always write out the center of the detector since this is dummy data
			V_writeDet_beam_center_x(fileName,detStr,V_getDet_beam_center_x("VCALC",detStr))
			V_writeDet_beam_center_y(fileName,detStr,V_getDet_beam_center_y("VCALC",detStr))				
		endif

		
		
		// the calibration data for each detector (except B) is already correct in the "base" file
		//V_writeDetTube_spatialCalib(fname,detStr,inW)
		// and for "B"
		//V_writeDet_cal_x(fname,detStr,inW)
		//V_writeDet_cal_y(fname,detStr,inW)
		
				
		// the dead time for each detector is already correct in the "base" file
		// V_writeDetector_deadtime(fname,detStr,inW)
		// TODO: need a new, separate function to write the single deadtime value in/out of "B"
		
		// integrated count value on each detector bank
		sumCts += sum(tmpData)
		V_writeDet_IntegratedCount(fileName,detStr,sum(tmpData))

	endfor

	
// writes out "perfect" detector calibration constants for all 8 tube banks
	V_WritePerfectSpatialCalib(filename)
// writes out "perfect" dead time constants for all 8 tube banks + back detector
	V_WritePerfectDeadTime(filename)
	
//? other detector geometry - lateral separation?

// the wavelength
//	Variable lam = V_getWavelength("VCALC")		//doesn't work, the corresponding folder in VCALC has not been defined
	V_writeWavelength(fileName,VCALC_getWavelength())

	
// fake the information about the count setup, so I have different numbers to read
// count time = fake time of 100 s
	V_writeCount_time(fileName,100)

	// monitor count (= imon)
		// returns the number of neutrons on the sample
		//Function VCALC_getImon()
	V_writeMonitorCount(fileName,VCALC_getImon())

	// total detector count (sum of everything)
	V_writeDetector_counts(fileName,sumCts)

	// sample description
	V_writeSampleDescription(fileName,labelStr)
	
	// reduction intent
	V_writeReductionIntent(fileName,intent)
	
	// reduction group_id
	// TODO x- (file has been corected)skip for now. group_id is incorrectly written to the data file as a text value. trac ticket
	//        has been written to fix in the future.
	V_writeSample_GroupID(fileName,group_id)



// ?? anything else that I'd like to see on the catalog - I could change them here to see different values
// different collimation types?
//



	return(0)
end



// writes out "perfect" detector calibration constants for all 8 tube banks + back detector
Function V_WritePerfectSpatialCalib(filename)
	String filename
	
//	String fileName = V_DoSaveFileDialog("pick the file to write to")
	
	Make/O/D/N=(3,48) tmpCalib
	// for the "tall" L/R banks
	tmpCalib[0][] = -512
	tmpCalib[1][] = 8
	tmpCalib[2][] = 0
	
	V_writeDetTube_spatialCalib(filename,"FR",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"FL",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"MR",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"ML",tmpCalib)

	// for the "short" T/B banks
	tmpCalib[0][] = -256
	tmpCalib[1][] = 4
	tmpCalib[2][] = 0
	
	V_writeDetTube_spatialCalib(filename,"FT",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"FB",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"MT",tmpCalib)
	V_writeDetTube_spatialCalib(filename,"MB",tmpCalib)
	
	KillWaves tmpCalib
	
	// and for the back detector "B"
	Make/O/D/N=3 tmpCalib
	tmpCalib[0] = 1
	tmpCalib[1] = 1
	tmpcalib[2] = 10000
	V_writeDet_cal_x(filename,"B",tmpCalib)
	V_writeDet_cal_y(filename,"B",tmpCalib)

	KillWaves tmpCalib

	return(0)
end

// TODO -- need a function to write out "bad" and "perfect" dead time values
// to the HDF file
//V_writeDetector_deadtime(fname,detStr,inW)
//V_writeDetector_deadtime_B(fname,detStr,val)
// simulated count rate per tube can be Å 10^8, so I need dt >> 10^-15 to completely cancel this out
// (partly due to fake I(q), fake count time in file...)

// writes out "perfect" dead time constants for all 8 tube banks + back detector
Function V_WritePerfectDeadTime(filename)
	String filename
		
	Make/O/D/N=(48) tmpDT
	tmpDT = 1e-18
	V_writeDetector_deadtime(filename,"FT",tmpDT)
	V_writeDetector_deadtime(filename,"FB",tmpDT)
	V_writeDetector_deadtime(filename,"FL",tmpDT)
	V_writeDetector_deadtime(filename,"FR",tmpDT)
	V_writeDetector_deadtime(filename,"MT",tmpDT)
	V_writeDetector_deadtime(filename,"MB",tmpDT)
	V_writeDetector_deadtime(filename,"ML",tmpDT)
	V_writeDetector_deadtime(filename,"MR",tmpDT)


	// and for the back detector "B", a single value, not a wave
	V_writeDetector_deadtime_B(filename,"B",1e-20)

	KillWaves tmpDT

	return(0)
end


Function V_FakeBeamCenters()
// fake beam center values
	V_putDet_beam_center_x("RAW","B",75)
	V_putDet_beam_center_y("RAW","B",75)

	V_putDet_beam_center_x("RAW","MB",64)
	V_putDet_beam_center_y("RAW","MB",55)
	V_putDet_beam_center_x("RAW","MT",64)
	V_putDet_beam_center_y("RAW","MT",-8.1)
	V_putDet_beam_center_x("RAW","MR",-8.1)
	V_putDet_beam_center_y("RAW","MR",64)
	V_putDet_beam_center_x("RAW","ML",55)
	V_putDet_beam_center_y("RAW","ML",64)

	V_putDet_beam_center_x("RAW","FB",64)
	V_putDet_beam_center_y("RAW","FB",55)
	V_putDet_beam_center_x("RAW","FT",64)
	V_putDet_beam_center_y("RAW","FT",-8.7)
	V_putDet_beam_center_x("RAW","FR",-8.1)
	V_putDet_beam_center_y("RAW","FR",64)
	V_putDet_beam_center_x("RAW","FL",55)
	V_putDet_beam_center_y("RAW","FL",64)
	
	return(0)
end

Function V_FakeScaleToCenter()

	V_RescaleToBeamCenter("RAW","MB",64,55)
	V_RescaleToBeamCenter("RAW","MT",64,-8.7)
	V_RescaleToBeamCenter("RAW","MR",-8.1,64)
	V_RescaleToBeamCenter("RAW","ML",55,64)
	V_RescaleToBeamCenter("RAW","FL",55,64)
	V_RescaleToBeamCenter("RAW","FR",-8.1,64)
	V_RescaleToBeamCenter("RAW","FT",64,-8.7)
	V_RescaleToBeamCenter("RAW","FB",64,55)
	
	return(0)
End

//
// a few utilities to patch up the data files so that they are useable
// even without the Back detector containing real data
//
// TODO
//
// Hopefully, the data files as generated from NICE will have a dummy for the back detector
// if not, there's going to be a big mess
//
// 		V_writeDetectorData(fileName,detStr,tmpData)
//
Function V_Write_BackDet_to_VSANSFile()
	
	String fileName = V_DoSaveFileDialog("pick the file to write to")
	print fileName
//	
	String detStr = "B"
	
	if(strlen(fileName) > 0)
		Wave detW = V_getDetectorDataW(filename,detStr)
		detW = 1
		V_writeDetectorData(fileName,detStr,detW)
	endif
End

