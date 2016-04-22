#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// writes out "perfect" detector calibration constants for all 8 tube banks
Function V_WritePerfectCalibration()

	Make/O/D/N=(3,48) tmpCalib
	// for the "tall" L/R banks
	tmpCalib[0][] = -512
	tmpCalib[1][] = 8
	tmpCalib[2][] = 0
	
	V_writeDetTube_spatialCalib("","FR",tmpCalib)
	V_writeDetTube_spatialCalib("","FL",tmpCalib)
	V_writeDetTube_spatialCalib("","MR",tmpCalib)
	V_writeDetTube_spatialCalib("","ML",tmpCalib)

	// for the "short" T/B banks
	tmpCalib[0][] = -256
	tmpCalib[1][] = 4
	tmpCalib[2][] = 0
	
	V_writeDetTube_spatialCalib("","FT",tmpCalib)
	V_writeDetTube_spatialCalib("","FB",tmpCalib)
	V_writeDetTube_spatialCalib("","MT",tmpCalib)
	V_writeDetTube_spatialCalib("","MB",tmpCalib)
	
	KillWaves tmpCalib
	return(0)
end

// TODO -- need a function to write out "bad" and "perfect" dead time values
// to the HDF file
//V_writeDetector_deadtime(fname,detStr,inW)
//V_writeDetector_deadtime_B(fname,detStr,val)


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