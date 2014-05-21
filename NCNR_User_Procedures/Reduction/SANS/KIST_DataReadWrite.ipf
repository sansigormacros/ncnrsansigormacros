#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//**************************
//
// Vers. 1.2 092101
// Vers. 5.0 29MAR07 - branched from main reduction to split out facility
//                     specific calls
//
// functions for reading raw data files from the VAX
// - RAW data files are read into the RAW folder - integer data from the detector
//   is decompressed and given the proper orientation
// - header information is placed into real,integer, or text waves in the order they appear
//   in the file header
//
// Work data (DIV File) is read into the DIV folder
//
//*****************************

//simple, main entry procedure that will load a RAW sans data file (not a work file)
//into the RAW dataFolder. It is up to the calling procedure to display the file
//
// called by MainPanel.ipf and ProtocolAsPanel.ipf
//
Function LoadRawSANSData(msgStr)
	String msgStr

	String filename=""

	//each routine is responsible for checking the current (displayed) data folder
	//selecting it, and returning to root when done
	PathInfo/S catPathName		//should set the next dialog to the proper path...
	//get the filename, then read it in
	filename = PromptForPath(msgStr)		//in SANS_Utils.ipf
	//check for cancel from dialog
	if(strlen(filename)==0)
		//user cancelled, abort
		SetDataFolder root:
		DoAlert 0, "No file selected, action aborted"
		return(1)
	Endif

	ReadHeaderAndData(filename)	//this is the full Path+file
	
	Return(0)
End


//function that does the guts of reading the binary data file
//fname is the full path:name;vers required to open the file
//
// The final root:RAW:data wave is the real
//neutron counts and can be directly operated on
//
// header information is put into three waves: integersRead, realsRead, and textRead
// logicals in the header are currently skipped, since they are no use in the 
// data reduction process.
//
// The output is the three R/T/I waves that are filled at least with minimal values
// and the detector data loaded into an array named "data"
//
// see documentation for the expected information in each element of the R/T/I waves
// and the minimum set of information. These waves can be increased in length so that
// more information can be accessed as needed (propagating changes...)
//
// called by multiple .ipfs (when the file name is known)
//
//
// THIS FUNCTION DOES NOT NEED TO BE MODIFIED. ONLY THE DATA ACCESSORS NEED TO BE CONSTRUCTED
//
Function ReadHeaderAndData(fname)
	String fname
	//this function is for reading in RAW data only, so it will always put data in RAW folder
	String curPath = "root:Packages:NIST:RAW:"
	SetDataFolder curPath		//use the full path, so it will always work
	Variable/G root:Packages:NIST:RAW:gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	
	Variable refNum,integer,realval
	String sansfname,textstr
	
	Make/O/D/N=23 $"root:Packages:NIST:RAW:IntegersRead"
	Make/O/D/N=52 $"root:Packages:NIST:RAW:RealsRead"
	Make/O/T/N=11 $"root:Packages:NIST:RAW:TextRead"
	Make/O/N=7 $"root:Packages:NIST:RAW:LogicalsRead"
	
	Wave intw=$"root:Packages:NIST:RAW:IntegersRead"
	Wave realw=$"root:Packages:NIST:RAW:RealsRead"
	Wave/T textw=$"root:Packages:NIST:RAW:TextRead"
	Wave logw=$"root:Packages:NIST:RAW:LogicalsRead"
	
	// FILL IN 3 ARRAYS WITH HEADER INFORMATION FOR LATER USE
	// THESE ARE JUST THE MINIMALLY NECESSARY VALUES
	
	// filename as stored in the file header
	textw[0]= fname	
	
	// date and time of collection
	textw[1]= getFileCreationDate(fname)
	
	// run type identifier (this is a reader for RAW data)
	textw[2]= "RAW"
	
	// user account identifier (currently used only for NCNR-specific operations)
	textw[3]= ""

	// sample label
	textw[6]= getSampleLabel(fname)
	
	// identifier of detector type, useful for setting detector constants
	//(currently used only for NCNR-specific operations)
	textw[9]= ""

	//total counting time in seconds
	intw[2] = getCountTime(fname)
	
	
	// total monitor count
	realw[0] = getMonitorCount(fname)
	
	// total detector count
	realw[2] = getDetCount(fname)
	
	// attenuator number (NCNR-specific, your stub returns 0)
	// may also be used to hold attenuator transmission (< 1)
	realw[3] = getAttenNumber(fname)
	
	// sample transmission
	realw[4] = getSampleTrans(fname)
	
	//sample thickness (cm)
	realw[5] = getSampleThickness(fname)
	
	// following 6 values are for non-linear spatial corrections to a detector (RC timing)
	// these values are set for a detctor that has a linear correspondence between
	// pixel number and real-space distance
	// 10 and 13 are the X and Y pixel dimensions, respectively (in mm!)
	//(11,12 and 13,14 are set to values for a linear response, as from a new Ordela detector)
	realw[10] = getDetectorPixelXSize(fname)
	realw[11] = 10000
	realw[12] = 0
	realw[13] = getDetectorPixelYSize(fname)
	realw[14] = 10000
	realw[15] = 0
	
	// beam center X,Y on the detector (in units of pixel coordinates (1,N))
	realw[16] = getBeamXPos(fname)
	realw[17] = getBeamYPos(fname)
	
	// sample to detector distance (meters)
	realw[18] = getSDD(fname)

	// detector physical width (right now assumes square...) (in cm)
	realw[20] = 65
	
	// beam stop diameter (assumes circular) (in mm)
	realw[21] = getBSDiameter(fname)
	
	// source aperture diameter (mm)
	realw[23] = getSourceApertureDiam(fname)
	
	// sample aperture diameter (mm)
	realw[24] = getSampleApertureDiam(fname)
	
	// source aperture to sample aperture distance
	realw[25] = getSourceToSampleDist(fname)
	
	// wavelength (A)
	realw[26] = getWavelength(fname)
	
	// wavelength spread (FWHM)
	realw[27] = getWavelengthSpread(fname)
	
	// beam stop X-position (motor reading, approximate cm from zero position)
	// currently NCNR-specific use to identify transmission measurements
	// you return 0
	realw[37] = 0

// the actual data array, dimensions are set as globals in 
// InitFacilityGlobals()
	NVAR XPix = root:myGlobals:gNPixelsX
	NVAR YPix = root:myGlobals:gNPixelsX
	
	Make/D/O/N=(XPix,YPix) $"root:RAW:data"
	WAVE data=$"root:RAW:data"

	// fill the data array with the detector values
	getDetectorData(fname,data)
	
	Duplicate/O data linear_data			// at this point, the data is still the raw data, and is linear_data
	
	// proper error for counting statistics, good for low count values too
	// rather than just sqrt(n)
	// see N. Gehrels, Astrophys. J., 303 (1986) 336-346, equation (7)
	// for S = 1 in eq (7), this corresponds to one sigma error bars
	Duplicate/O linear_data linear_data_error
	linear_data_error = 1 + sqrt(linear_data + 0.75)				
	//
	
	//keep a string with the filename in the RAW folder
	String/G root:RAW:fileList = textw[0]
	
	Return 0

End

//****************
//main entry procedure for reading a "WORK.DIV" file
//displays a quick image of the  file, to check that it's correct
//data is deposited in root:Packages:NIST:DIV data folder
//
// local, currently unused
//
//
Proc ReadWork_DIV()
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:Packages:NIST:DIV:data"
//	NewImage/F/K=1/S=2 $waveStr		//this is an experimental IGOR operation
//	ModifyImage '' ctab= {*,*,YellowHot,0}
	//Display;AppendImage $waveStr
	
	//change the title string to WORK.DIV, rather than PLEXnnn_TST_asdfa garbage
//	String/G root:Packages:NIST:DIV:fileList = "WORK.DIV"
	ChangeDisplay("DIV")
	
	SetDataFolder root:		//(redundant)
End



// Detector sensitivity files have the same header structure as RAW SANS data
// as NCNR, just with a different data array (real, rather than integer data)
//
// So for your facility, make this reader specific to the format of whatever
// file you use for a pixel-by-pixel division of the raw detector data
// to correct for non-uniform sensitivities of the detector. This is typically a
// measurement of water, plexiglas, or another uniform scattering sample.
//
// The data must be normalized to a mean value of 1
//
// called from ProtocolAsPanel.ipf
//
// type is "DIV" on input
Function ReadHeaderAndWork(type,fname)
	String type,fname
	
	//type is the desired folder to read the workfile to
	//this data will NOT be automatically displayed
	// gDataDisplayType is unchanged

	String cur_folder = type
	String curPath = "root:Packages:NIST:"+cur_folder
	SetDataFolder curPath		//use the full path, so it will always work
	
	Variable refNum,integer,realval
	String sansfname,textstr
	Variable/G $(curPath + ":gIsLogScale") = 0		//initial state is linear, keep this in DIV folder
	
	Make/O/D/N=23 $(curPath + ":IntegersRead")
	Make/O/D/N=52 $(curPath + ":RealsRead")
	Make/O/T/N=11 $(curPath + ":TextRead")
	
	WAVE intw=$(curPath + ":IntegersRead")
	WAVE realw=$(curPath + ":RealsRead")
	WAVE/T textw=$(curPath + ":TextRead")
	
	// the actual data array, dimensions are set as globals in 
	// InitFacilityGlobals()
	NVAR XPix = root:myGlobals:gNPixelsX
	NVAR YPix = root:myGlobals:gNPixelsX
	
	Make/O/D/N=(XPix,YPix) $(curPath + ":data")
	WAVE data = $(curPath + ":data")
	
	
	// (1)
	// fill in your reader for the header here so that intw, realw, and textW are filled in
	// ? possibly a duplication of the raw data reader
	
	
	
	//(2)
	// then fill in a reader for the data array that will DIVIDE your data
	// to get the corrected values.
	

	

	//keep a string with the filename in the DIV folder
	String/G $(curPath + ":fileList") = textw[0]
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End



/////   ASC FORMAT READER  //////
/////   FOR WORKFILE MATH PANEL //////
//
//function to read in the ASC output of SANS reduction
// currently the file has 20 header lines, followed by a single column
// of 16384 values, Data is written by row, starting with Y=1 and X=(1->128)
//
//returns 0 if read was ok
//returns 1 if there was an error
//
// called by WorkFileUtils.ipf
//
//
// If the ASC data was generated by the NCNR data writer, then 
// NOTHING NEEDS TO BE CHANGED HERE
//
Function ReadASCData(fname,destPath)
	String fname, destPath
	//this function is for reading in ASCII data so put data in user-specified folder
	SetDataFolder "root:Packages:NIST:"+destPath

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable refNum=0,ii,p1,p2,tot,num=pixelsX,numHdrLines=20
	String str=""
	//data is initially linear scale
	Variable/G :gIsLogScale=0
	Make/O/T/N=(numHdrLines) hdrLines
	Make/O/D/N=(pixelsX*pixelsY) data			//,linear_data
	
	//full filename and path is now passed in...
	//actually open the file
//	SetDataFolder destPath
	Open/R/Z refNum as fname		// /Z flag means I must handle open errors
	if(refnum==0)		//FNF error, get out
		DoAlert 0,"Could not find file: "+fname
		Close/A
		SetDataFolder root:
		return(1)
	endif
	if(V_flag!=0)
		DoAlert 0,"File open error: V_flag="+num2Str(V_Flag)
		Close/A
		SetDataFolder root:
		return(1)
	Endif
	// 
	for(ii=0;ii<numHdrLines;ii+=1)		//read (or skip) 18 header lines
		FReadLine refnum,str
		hdrLines[ii]=str
	endfor
	//	
	Close refnum
	
//	SetDataFolder destPath
	LoadWave/Q/G/D/N=temp fName
	Wave/Z temp0=temp0
	data=temp0
	Redimension/N=(pixelsX,pixelsY) data		//,linear_data

	Duplicate/O data linear_data_error
	linear_data_error = 1 + sqrt(data + 0.75)
	
	//just in case there are odd inputs to this, like negative intensities
	WaveStats/Q linear_data_error
	linear_data_error = numtype(linear_data_error[p]) == 0 ? linear_data_error[p] : V_avg
	linear_data_error = linear_data_error[p] != 0 ? linear_data_error[p] : V_avg
	
	//linear_data = data
	
	KillWaves/Z temp0 
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End

// fills the "default" fake header so that the SANS Reduction machinery does not have to be altered
// pay attention to what is/not to be trusted due to "fake" information.
// uses what it can from the header lines from the ASC file (hdrLines wave)
//
// destFolder is of the form "myGlobals:WorkMath:AAA"
//
//
// called by WorkFileUtils.ipf
//
// If the ASC data was generated by the NCNR data writer, then 
// NOTHING NEEDS TO BE CHANGED HERE
//
Function FillFakeHeader_ASC(destFolder)
	String destFolder
	Make/O/D/N=23 $("root:Packages:NIST:"+destFolder+":IntegersRead")
	Make/O/D/N=52 $("root:Packages:NIST:"+destFolder+":RealsRead")
	Make/O/T/N=11 $("root:Packages:NIST:"+destFolder+":TextRead")
	
	Wave intw=$("root:Packages:NIST:"+destFolder+":IntegersRead")
	Wave realw=$("root:Packages:NIST:"+destFolder+":RealsRead")
	Wave/T textw=$("root:Packages:NIST:"+destFolder+":TextRead")
	
	//Put in appropriate "fake" values
	//parse values as needed from headerLines
	Wave/T hdr=$("root:Packages:NIST:"+destFolder+":hdrLines")
	Variable monCt,lam,offset,sdd,trans,thick
	Variable xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam
	String detTyp=""
	String tempStr="",formatStr="",junkStr=""
	formatStr = "%g %g %g %g %g %g"
	tempStr=hdr[3]
	sscanf tempStr, formatStr, monCt,lam,offset,sdd,trans,thick
//	Print monCt,lam,offset,sdd,trans,thick,avStr,step
	formatStr = "%g %g %g %g %g %g %g %s"
	tempStr=hdr[5]
	sscanf tempStr,formatStr,xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam,detTyp
//	Print xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam,detTyp
	
	realw[16]=xCtr		//xCtr(pixels)
	realw[17]=yCtr	//yCtr (pixels)
	realw[18]=sdd		//SDD (m)
	realw[26]=lam		//wavelength (A)
	//
	// necessary values
	realw[10]=5			//detector calibration constants, needed for averaging
	realw[11]=10000
	realw[12]=0
	realw[13]=5
	realw[14]=10000
	realw[15]=0
	//
	// used in the resolution calculation, ONLY here to keep the routine from crashing
	realw[20]=65		//det size
	realw[27]=dlam	//delta lambda
	realw[21]=bsDiam	//BS size
	realw[23]=a1		//A1
	realw[24]=a2	//A2
	realw[25]=a1a2Dist	//A1A2 distance
	realw[4]=trans		//trans
	realw[3]=0		//atten
	realw[5]=thick		//thick
	//
	//
	realw[0]=monCt		//def mon cts

	// fake values to get valid deadtime and detector constants
	//
	textw[9]=detTyp+"  "		//6 characters 4+2 spaces
	textw[3]="[NGxSANS00]"	//11 chars, NGx will return default values for atten trans, deadtime... 
	
	//set the string values
	formatStr="FILE: %s CREATED: %s"
	sscanf hdr[0],formatStr,tempStr,junkStr
//	Print tempStr
//	Print junkStr
	String/G $("root:Packages:NIST:"+destFolder+":fileList") = tempStr
	textw[0] = tempStr		//filename
	textw[1] = junkStr		//run date-time
	
	//file label = hdr[1]
	tempStr = hdr[1]
	tempStr = tempStr[0,strlen(tempStr)-2]		//clean off the last LF
//	Print tempStr
	textW[6] = tempStr	//sample label
	
	return(0)
End


///////// ACCESSORS FOR WRITING DATA TO HEADER  /////////
/////

// Write* routines all must:
// (1) open file "fname". fname is a full file path and name to the file on disk
// (2) write the specified value to the header at the correct location in the file
// (3) close the file

// new, April 2011 for error propagation. fill these in with the facility-
// specific versions, if desired.
Function WriteTransmissionErrorToHeader(fname,transErr)
	String fname
	Variable transErr
	

	return(0)
End

Function WriteBoxCountsErrorToHeader(fname,rel_err)
	String fname
	Variable rel_err
	
	return(0)
End

Function getSampleTransError(fname)
	String fname
	
	return(0)
end

Function getBoxCountsError(fname)
	String fname
	
	return(0)
end


// end April 2011 additions

//sample transmission (0<T<=1)
Function WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	// your writer here
	
	return(0)
End

//whole transmission is NCNR-specific right now
// leave this stub empty
Function WriteWholeTransToHeader(fname,trans)
	String fname
	Variable trans
	
	// do nothing for now
	
	return(0)
End

//box sum counts is a real value
// used for transmission calculation module
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts
	
	// do nothing if not using NCNR Transmission module
	
	return(0)
End

//beam stop X-position
// used for transmission module to manually tag transmission files
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos
	
	// do nothing if not using NCNR Transmission module
	
	return(0)
End

//sample thickness in cm
Function WriteThicknessToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//beam center X pixel location (detector coordinates)
Function WriteBeamCenterXToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//beam center Y pixel location (detector coordinates)
Function WriteBeamCenterYToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//attenuator number (not its transmission)
// if your beam attenuation is indexed in some way, use that number here
// if not, write a 1 to the file here as a default
//
Function WriteAttenNumberToHeader(fname,num)
	String fname
	Variable num
	
	// your code here, default of 1
	
	return(0)
End

// total monitor count during data collection
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//total detector count
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//transmission detector count
// (currently unused in data reduction)
Function WriteTransDetCountToHeader(fname,num)
	String fname
	Variable num
	
	// do nothing for now
	
	return(0)
End

//wavelength (Angstroms)
Function WriteWavelengthToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//wavelength spread (FWHM)
Function WriteWavelengthDistrToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//temperature of the sample (C)
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num
	
	//  your code here
	
	return(0)
End

//magnetic field (Oe)
Function WriteMagnFieldToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//Source Aperture diameter (millimeters)
Function WriteSourceApDiamToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//Sample Aperture diameter (millimeters)
Function WriteSampleApDiamToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	return(0)
End

//Source aperture to sample aperture distance (meters)
Function WriteSrcToSamDistToHeader(fname,num)
	String fname
	Variable num
	
	//	your code here
	
	return(0)
End

//lateral detector offset (centimeters)
Function WriteDetectorOffsetToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	return(0)
End

//beam stop diameter (millimeters)
Function WriteBeamStopDiamToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

//sample to detector distance (meters)
Function WriteSDDToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	return(0)
End

// physical dimension of detector x-pixel (mm)
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	return(0)
end

// physical dimension of detector y-pixel (mm)
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	return(0)
end

// sample label string
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	// your code here

	return(0)
End

// total counting time (seconds)
Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	return(0)
End

// Write the detector deadtime to the file header (in seconds)
Function WriteDeadtimeToHeader(fname,num)
	String fname
	Variable num
	
	return(0)
End

//////// ACCESSORS FOR READING DATA FROM THE HEADER  //////////////
//
// read specific bits of information from the header
// each of these operations MUST take care of open/close on their own
//
// fname is the full path and filname to the file on disk
// return values are either strings or real values as appropriate
//
//////


// function that reads in the 2D detector data and fills the array
// data[nx][ny] with the data values
// fname is the full name and path to the data file for opening and closing
//
//
Function getDetectorData(fname,data)
	String fname
	Wave data
	
	
	// your reader here
	
	return(0)
End

// file suffix (NCNR data file name specific)
// return null string
Function/S getSuffix(fname)
	String fname
	
	return("")
End

// associated file suffix (for transmission)
// NCNR Transmission calculation specific
// return null string
Function/S getAssociatedFileSuffix(fname)
	String fname
	
	return("")
End

// sample label
Function/S getSampleLabel(fname)
	String fname
	
	String str
	
	// your code, returning str
	
	return(str)
End

// file creation date
Function/S getFileCreationDate(fname)
	String fname
	
	String str
	
	// your code, returning str
	
	return(str)
End


//monitor count
Function getMonitorCount(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//saved monitor count
// NCNR specific for pre-processed data, never used
// return 0
Function getSavMon(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(0)
end

//total detector count
Function getDetCount(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//Attenuator number, return 1 if your attenuators are not
// indexed by number
Function getAttenNumber(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//transmission
Function getSampleTrans(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//box counts from stored transmission calculation
// return 0 if not using NCNR transmission module
Function getBoxCounts(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//whole detector trasmission
// return 0 if not using NCNR transmission module
Function getSampleTransWholeDetector(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//SampleThickness in centimeters
Function getSampleThickness(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//Sample Rotation Angle (degrees)
Function getSampleRotationAngle(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//temperature (C)
Function getTemperature(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//field strength (Oe)
Function getFieldStrength(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//center of beam xPos in pixel coordinates
Function getBeamXPos(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//center of beam Y pos in pixel coordinates
Function getBeamYPos(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//sample to detector distance (meters)
Function getSDD(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//lateral detector offset (centimeters)
Function getDetectorOffset(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//Beamstop diameter (millimeters)
Function getBSDiameter(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//source aperture diameter (millimeters)
Function getSourceApertureDiam(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//sample aperture diameter (millimeters)
Function getSampleApertureDiam(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//source AP to Sample AP distance (meters)
Function getSourceToSampleDist(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//wavelength (Angstroms)
Function getWavelength(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

//wavelength spread (FWHM)
Function getWavelengthSpread(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

// physical x-dimension of a detector pixel, in mm
Function getDetectorPixelXSize(fname)
	String fname
	
	Variable value
	
	// your code here returning value
	
	return(value)
end

// physical y-dimension of a detector pixel, in mm
Function getDetectorPixelYSize(fname)
	String fname
	
	Variable value
	
	// your code here returning value
	
	return(value)
end

//transmission detector count (unused, return 0)
//
Function getTransDetectorCounts(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(0)
end


//total count time (seconds)
Function getCountTime(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	return(value)
end

// read the detector deadtime (in seconds)
Function getDetectorDeadtime(fname)
	String fname
	
	return(0)
end


//reads the wavelength from a reduced data file (not very reliable)
// - does not work with NSORTed files
// - only used in FIT/RPA (which itself is almost NEVER used...)
//
// DOES NOT NEED TO BE CHANGED IF USING NCNR DATA WRITER
Function GetLambdaFromReducedData(tempName)
	String tempName
	
	String junkString
	Variable lambdaFromFile, fileVar
	lambdaFromFile = 6.0
	Open/R/P=catPathName fileVar as tempName
	FReadLine fileVar, junkString
	FReadLine fileVar, junkString
	FReadLine fileVar, junkString
	if(strsearch(LowerStr(junkString),"lambda",0) != -1)
		FReadLine/N=11 fileVar, junkString
		FReadLine/N=10 fileVar, junkString
		lambdaFromFile = str2num(junkString)
	endif
	Close fileVar
	
	return(lambdaFromFile)
End

/////   TRANSMISSION RELATED FUNCTIONS    ////////
//box coordinate are returned by reference
//
// box to sum over is bounded (x1,y1) to (x2,y2)
//
// this function returns the bounding coordinates as stored in
// the header
//
// if not using the NCNR Transmission module, this function default to 
// returning 0000, and no changes needed
Function getXYBoxFromFile(filename,x1,x2,y1,y2)
	String filename
	Variable &x1,&x2,&y1,&y2
	
	Variable refnum
	String tmpFile = FindValidFilename(filename)
	// tmpFile is only a parital path

	// return your bounding box coordinates or default values of 0
	x1=0
	y1=0
	x2=0
	y2=0
	
	return(0)
End

// Writes the coordinates of the box to the header after user input
//
// box to sum over bounded (x1,y1) to (x2,y2)
//
// if not using the NCNR Transmission module, this function is null
Function WriteXYBoxToHeader(filename,x1,x2,y1,y2)
	String filename
	Variable x1,x2,y1,y2
	
	// your code to write bounding box to the header, or nothing
	
	return(0)
End

// for transmission calculation, writes an NCNR-specific alphanumeric identifier
// (suffix of the data file)
//
// if not using the NCNR Transmission module, this function is null
Function WriteAssocFileSuffixToHeader(fname,suffix)
	String fname,suffix
		
	// your code to write bounding box to the header, or nothing
	
	return(0)
end

////// OCT 2009, facility specific bits from ProDiv()
//"type" is the data folder that has the corrected, patched, and normalized DIV data array
//
// the header of this file is rather unimportant. Filling in a title at least would be helpful/
//
Function Write_DIV_File(type)
	String type
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	Print "Write_DIV_File stub"
	
	return(0)
End

////// OCT 2009, facility specific bits from MonteCarlo functions()
//"type" is the data folder that has the data array that is to be (re)written as a full
// data file, as if it was a raw data file
//
// not really necessary
//
Function/S Write_RawData_File(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	Print "Write_RawData_File stub"
	
	return("")
End