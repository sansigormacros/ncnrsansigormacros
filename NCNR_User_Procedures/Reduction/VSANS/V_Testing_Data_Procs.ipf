#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//
// function to take VCALC information and 
// fill in the simulated information as needed to make a "fake" data file
//
// - to make fake data:
//
// - **copy** several existing raw VSANS files to a new folder
// - renumber them
// - open a new experiment, get a file catalog (catPathName must be set)
// - then open VCALC and set the desired conditions
// - then use the Macro "Copy_VCALC_to_VSANSFile()
//
//


//
// TODO:
// -- identify any additional fields to enter into the file structure
//




// main procedure to write out the current state of VCALC to an existing data file
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
		
	
		val = VC_getSDD(detStr)		// make sure value is in cm. This does not include the setback
		print val
		V_writeDet_distance(fileName,detStr,val)
		
		val = VCALC_getTopBottomSDDSetback(detStr)		//val is in cm, as for data file
		if(val != 0)
			V_writeDet_TBSetback(fileName,detStr,val)
		endif
		
		// returns the total separation (assumed symmetric) in cm
		val = VCALC_getPanelTranslation(detStr)		
		// it's OK to call both of these. these functions check detStr for the correct value
		if(cmpstr("T",detStr[1]) == 0 || cmpstr("B",detStr[1]) == 0)
			V_writeDet_VerticalOffset(fileName,detStr,val)		// T/B panels
		else
			V_writeDet_LateralOffset(fileName,detStr,val)		//  L/R panels, or back detector
		endif
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
			// the back detector always has its beam center in pixels
			V_writeDet_beam_center_x(fileName,detStr,V_getDet_beam_center_x("VCALC",detStr))
			V_writeDet_beam_center_y(fileName,detStr,V_getDet_beam_center_y("VCALC",detStr))	
			
			// write out the number of pixels x and y
			// patch n_pix_x and y
			V_writeDet_pixel_num_x(fileName,detStr,V_getDet_pixel_num_x("VCALC",detStr))
			V_writeDet_pixel_num_y(fileName,detStr,V_getDet_pixel_num_y("VCALC",detStr))			
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

	
// writes out "perfect" detector calibration constants for all 8 tube banks + back detector
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
		//
		// divide the monitor count by 1e8 to get a number small enough to write in the field.
	V_writeBeamMonNormData(fileName,VCALC_getImon()/1e8)

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
	NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
	Variable tmpPix
	if(gHighResBinning == 1)
		tmpPix = 0.00845		//[cm]
	else
		//binning 4x4 assumed
		tmpPix = 0.034
	endif
	
	Make/O/D/N=3 tmpCalib
	tmpCalib[0] = tmpPix
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




//////

//
// Function Profiling
//
// tests for where the speed bottlenecks are hiding
//
// in the built-in procedure, add the line:
//#include <FunctionProfiling>
// and check out the instructions in that file.
//
// essentially, create a function call with no parameters
// and run that function as below:

// RunFuncWithProfiling(yourFuncHere)


// for recalculation of VCALC results
//
Function V_ProfileVCALC_Recalc()
	VC_Recalculate_AllDetectors()
end
//
// function to profile can have no parameters, so hard-wire the file name
Function V_ProfileFileLoad()
	V_LoadHDF5Data("sans9999.nxs.ngv","RAW")
End


Function V_ProfileReduceOne()
	V_ReduceOneButton("")
End



Proc pV_DetPanelCountReport(fname)
	String fname
	
	V_DetPanelCountReport(fname)
end

// test function to print out the detector counts as reported in the file:
//
// control/detector_counts
//
// integrated_count for each panel
//
// actual sum of the data on each panel
//
Function V_DetPanelCountReport(fname)
	String fname
	
	Variable ctrlCts
	Variable ctFL,ctFR,ctFT,ctFB,ctB
	Variable ctML,ctMR,ctMT,ctMB
	Variable sumFL,sumFR,sumFT,sumFB,sumB
	Variable sumML,sumMR,sumMT,sumMB
	
	
	ctrlCts = V_getDetector_Counts(fname)
	ctFL = V_getDet_IntegratedCount(fname,"FL")
	ctFR = V_getDet_IntegratedCount(fname,"FR")
	ctFT = V_getDet_IntegratedCount(fname,"FT")
	ctFB = V_getDet_IntegratedCount(fname,"FB")
	ctML = V_getDet_IntegratedCount(fname,"ML")
	ctMR = V_getDet_IntegratedCount(fname,"MR")
	ctMT = V_getDet_IntegratedCount(fname,"MT")
	ctMB = V_getDet_IntegratedCount(fname,"MB")	
	ctB = V_getDet_IntegratedCount(fname,"B")	
	
	WAVE w=V_getDetectorDataW(fname,"FL")
	sumFL = sum(w)
	WAVE w=V_getDetectorDataW(fname,"FR")
	sumFR = sum(w)
	WAVE w=V_getDetectorDataW(fname,"FT")
	sumFT = sum(w)
	WAVE w=V_getDetectorDataW(fname,"FB")
	sumFB = sum(w)
	WAVE w=V_getDetectorDataW(fname,"ML")
	sumML = sum(w)
	WAVE w=V_getDetectorDataW(fname,"MR")
	sumMR = sum(w)
	WAVE w=V_getDetectorDataW(fname,"MT")
	sumMT = sum(w)
	WAVE w=V_getDetectorDataW(fname,"MB")
	sumMB = sum(w)
	WAVE/Z w=V_getDetectorDataW(fname,"B")
	sumB = sum(w)		
	
	Print "control/detector_counts = ",ctrlCts
	Printf "Integrated count (FL, FR, FT, FB) = %g\t\t%g\t\t%g\t\t%g\r",ctFL,ctFR,ctFT,ctFB
	Printf "Integrated count (ML, MR, MT, MB) = %g\t\t%g\t\t%g\t\t%g\r",ctML,ctMR,ctMT,ctMB
	Printf "Integrated count (B) = %g\r",ctB
		
	Printf "Summed count (FL, FR, FT, FB) = %g\t\t%g\t\t%g\t\t%g\r",sumFL,sumFR,sumFT,sumFB
	Printf "Summed count (ML, MR, MT, MB) = %g\t\t%g\t\t%g\t\t%g\r",sumML,sumMR,sumMT,sumMB
	Printf "Summed count (B) = %g\r",sumB
	
	
	
	return(0)
End




Proc V_PlotDeadTime()

	//will ask for a file name or data foldr name
	//
	pV_DeadTime_Report()
	
	DoWindow/F DeadTimeReport
	
	if(V_flag == 0)
		SetDataFolder root:
		PauseUpdate; Silent 1		// building window...
		Display /W=(747,235.4,1142.4,443) /K=1 DeadTimeCorrection_FB,DeadTimeCorrection_FL,DeadTimeCorrection_FR
		DoWindow/C DeadTimeReport
		AppendToGraph DeadTimeCorrection_FT,DeadTimeCorrection_MB,DeadTimeCorrection_ML,DeadTimeCorrection_MR
		AppendToGraph DeadTimeCorrection_MT
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb(DeadTimeCorrection_FB)=(0,0,0),rgb(DeadTimeCorrection_FL)=(65535,16385,16385)
		ModifyGraph rgb(DeadTimeCorrection_FR)=(2,39321,1),rgb(DeadTimeCorrection_FT)=(0,0,65535)
		ModifyGraph rgb(DeadTimeCorrection_MB)=(39321,1,31457),rgb(DeadTimeCorrection_ML)=(48059,48059,48059)
		ModifyGraph rgb(DeadTimeCorrection_MR)=(65535,32768,32768),rgb(DeadTimeCorrection_MT)=(0,65535,0)
		ModifyGraph msize=2
		ModifyGraph grid=1
		ModifyGraph log(left)=1
		ModifyGraph mirror=2
		Legend/C/N=text0/J "\\s(DeadTimeCorrection_FB) DeadTimeCorrection_FB\r\\s(DeadTimeCorrection_FL) DeadTimeCorrection_FL"
		AppendText "\\s(DeadTimeCorrection_FR) DeadTimeCorrection_FR\r\\s(DeadTimeCorrection_FT) DeadTimeCorrection_FT\r\\s(DeadTimeCorrection_MB) DeadTimeCorrection_MB"
		AppendText "\\s(DeadTimeCorrection_ML) DeadTimeCorrection_ML\r\\s(DeadTimeCorrection_MR) DeadTimeCorrection_MR\r\\s(DeadTimeCorrection_MT) DeadTimeCorrection_MT"
		Label left "Dead Time Correction (multiplicative)";DelayUpdate
		Label bottom "Tube Number"

	endif
End

Proc pV_DeadTime_Report(fname)
	String fname
	
	V_DeadTime_Report(fname)
end


Function V_DeadTime_Report(fname)
	String fname
	
	Variable ii
	Variable ctTime
	String detStr


	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		Wave dataW = V_getDetectorDataW(fname,detStr)
		ctTime = V_getCount_time(fname)

		
		// do the corrections for 8 tube panels
		String orientation = V_getDet_tubeOrientation(fname,detStr)
		Wave w_dt = V_getDetector_deadtime(fname,detStr)

		Make/O/D/N=48 $("root:DeadTimeCorrection_"+detStr)
		Wave dtc = $("root:DeadTimeCorrection_"+detStr)
		
		if(cmpstr(orientation,"vertical")==0)
			//	this is data dimensioned as (Ntubes,Npix)
			
			MatrixOp/O sumTubes = sumRows(dataW)		// n x 1 result
			sumTubes /= ctTime		//now count rate per tube
			
			dtc = 1/(1-sumTubes*w_dt)		//correction to the data (multiplicative factor)
	
		elseif(cmpstr(orientation,"horizontal")==0)
		//	this is data (horizontal) dimensioned as (Npix,Ntubes)
	
			MatrixOp/O sumTubes = sumCols(dataW)		// 1 x m result
			sumTubes /= ctTime
			
			dtc = 1/(1-sumTubes*w_dt)		//correction to the data (multiplicative factor)
		
		else		
			DoAlert 0,"Orientation not correctly passed in DeadTimeCorrectionTubes(). No correction done."
		endif
		
	endfor

		
	return(0)
end
		
		