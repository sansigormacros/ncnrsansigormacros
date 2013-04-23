#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 6.1 //required to read and write files created with HDF 1.8 library

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
// The final root:Packages:NIST:RAW:data wave is the real
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
	String curPath = "root:Packages:NIST:RAW"
	SetDataFolder curPath		//use the full path, so it will always work
	variable/g root:Packages:NIST:RAW:gIsLogScale = 0 		//initial state is linear, keep this in RAW folder
	
	Variable refNum,integer,realval
	String sansfname,textstr
	
	Make/D/O/N=23 $"root:Packages:NIST:RAW:IntegersRead"
	Make/D/O/N=52 $"root:Packages:NIST:RAW:RealsRead"
	Make/O/T/N=11 $"root:Packages:NIST:RAW:TextRead"
	Make/O/N=7 $"root:Packages:NIST:RAW:LogicalsRead"

	Wave intw=$"root:Packages:NIST:RAW:IntegersRead"
	Wave realw=$"root:Packages:NIST:RAW:RealsRead"
	Wave/T textw=$"root:Packages:NIST:RAW:TextRead"
	Wave logw=$"root:Packages:NIST:RAW:LogicalsRead"
	
	// FILL IN 3 ARRAYS WITH HEADER INFORMATION FOR LATER USE
	// THESE ARE JUST THE MINIMALLY NECESSARY VALUES
	
	// filename as stored in the file header
	textw[0]= ParseFilePath(0, fname, ":", 1, 0)	
	
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
	
//	realw[1] = 0
//	realw[6] = 0
//	realw[7] = 0
//	realw[8] = 0
//	realw[9] = 0
//	realw[19] = 0
//	realw[22] = 0

	// total monitor count
	realw[0] = getMonitorCount(fname)

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
	//realw[20] = 65
	realw[20] = getPhysicalWidth(fname)
	
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
	
	Make/D/O/N=(XPix,YPix) $"root:Packages:NIST:RAW:data"
	WAVE data=$"root:Packages:NIST:RAW:data"

	// fill the data array with the detector values
	getDetectorData(fname,data)
	
	// total detector count
	//nha 21/5/10 moved here because it requires the detector data to already be written
	//Result of issue with 0 counts being written for a while in metadata.
	realw[2] = getDetCount(fname)
	
	//keep a string with the filename in the RAW folder
	String/G root:Packages:NIST:RAW:fileList = textw[0]
	
	Return 0

End

//****************
//main entry procedure for reading a "WORK.DIV" file
//displays a quick image of the  file, to check that it's correct
//data is deposited in root:Packages:NIST:DIV data folder
//
// local, just for testing
//
Proc ReadWork_DIV()
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:Packages:NIST:DIV:data"
	NewImage/F/K=1/S=2 $waveStr
	ModifyImage '' ctab= {*,*,YellowHot,0}
	
	String/G root:Packages:NIST:DIV:fileList = "WORK.DIV"
	
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
	String dfName=""
	variable err
	err = hdfRead(fname, dfName)
	
	// [davidm]
	if (exists(dfName+":reduce:div"))
		Wave tempData = $dfName+":reduce:div"
	else
		Wave tempData = $dfName+":data:div"
	endif

	data = tempData
	
	//funky edge correction bodgy ???
	//copy second column to first column
	data[][0] = data[p][1]
	//copy second last column to last column
	data[][191] = data[p][190]
	//copy second row to first row
	data[0][] = data[1][q]
	//copy second last row to last row
	data[191][] = data[190][q]
	//keep a string with the filename in the DIV folder
	String/G $(curPath + ":fileList") = textw[0]
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End

Function WriteHeaderAndWork(type)
	String type
	
	// your writer here
	NVAR XPix = root:myGlobals:gNPixelsX
	NVAR YPix = root:myGlobals:gNPixelsX	
	
	Wave wData=$("root:Packages:NIST:"+type+":data")
	
//	Variable refnum,ii=0,hdrBytes=516,a,b,offset
	String fname=""
//	Duplicate/O wData,tempData
	
	//changed for Quokka
//	Redimension/S/N=(XPix*YPix) tempData
//	tempData *= 4
	
	PathInfo/S catPathName
	fname = DoSaveFileDialog("Save data as")	  //won't actually open the file
	If(cmpstr(fname,"")==0)
		//user cancel, don't write out a file
	  Close/A
	  Abort "no data file was written"
	Endif
	
	variable fileID 
	HDF5CreateFile /O fileID as fname
	
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	//Make /N=(1,1) wTransmission
	String groupName = "/reduce"
	String varName = "div"
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wData)

	// KillWaves wData, tempData
	return(0)
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



//whole transmission is NCNR-specific right now
// leave this stub empty
Function WriteWholeTransToHeader(fname,wholeTrans)
	String fname
	Variable wholeTrans
	
	String groupName = "/reduce"
	variable err
	
	Wave wCounts
	Make /N=(1,1) wWholeTrans
		
	wWholeTrans[0] = wholeTrans
	
	String varName = "wholeTransmission"	
	err = hdfWrite(fname, groupName, varName,wWholeTrans)

	KillWaves wWholeTrans
	
	//err not handled here
	return(0)	
End

//box sum counts is a real value
// used for transmission calculation module
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts
	
	// do nothing if not using NCNR Transmission module
	
	String groupName = "/reduce"
	variable err
	
	Wave wCounts
	Make /N=(1,1) wCounts
		
	wCounts[0] = counts
	
	String varName = "boxCounts"	
	err = hdfWrite(fname, groupName, varName,wCounts)

	KillWaves wCounts
	
	//err not handled here
	return(0)	
End

//beam stop X-position
// used for transmission module to manually tag transmission files
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos
	
	// do nothing if not using NCNR Transmission module
	//print "not implemented: WriteBSXPosToHeader"
	
	return(0)
End





//attenuator number (not its transmission)
// if your beam attenuation is indexed in some way, use that number here
// if not, write a 1 to the file here as a default
//
Function WriteAttenNumberToHeader(fname,attenNumber)
	String fname
	Variable attenNumber
	
	// your writer here
	Wave wAttenNumber
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wAttenNumber
	String groupName = "/instrument/collimator"
	String varName = "att"
	//convert number to a rotation angle
	attenNumber = attenNumber * 30
	wAttenNumber[0] = attenNumber //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wAttenNumber)
	KillWaves wAttenNumber
	//err not handled here
		
	return(0)

End


// total monitor count during data collection
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	//print "not implemented: WriteMonitorCountToHeader"
	
	return(0)
End

//total detector count
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	//print "not implemented: WriteDetectorCountToHeader"
	
	return(0)
End

//transmission detector count
// (currently unused in data reduction)
Function WriteTransDetCountToHeader(fname,num)
	String fname
	Variable num
	
	// do nothing for now
	//print "not implemented: WriteTransDetCountToHeader"
	
	return(0)
End



//temperature of the sample (C)
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num
	
	//  your code here
	//print "not implemented: WriteTemperatureToHeader"
	
	return(0)
End

//magnetic field (Oe)
Function WriteMagnFieldToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	//print "not implemented: WriteMagnFieldToHeader"
	
	return(0)
End

//lateral detector offset (centimeters)
Function WriteDetectorOffsetToHeader(fname,DetectorOffset)
	String fname
	Variable DetectorOffset
	
	// your writer here
	Wave wDetectorOffset
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wDetectorOffset
	String groupName = "/instrument/detector"
	String varName = "detector_x"
	//convert from cm (NIST standard) to mm (NeXus standard)
	DetectorOffset = DetectorOffset * 10
	wDetectorOffset[0] = DetectorOffset //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wDetectorOffset)
	KillWaves wDetectorOffset
	//err not handled here
	
	return(0)
End




// physical dimension of detector x-pixel (mm)
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	//print "not implemented: WriteDetPixelXToHeader"
	
	return(0)
end

// physical dimension of detector y-pixel (mm)
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	//print "not implemented: WriteDetPixelYToHeader"
	
	return(0)
end

// sample label string
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	String groupName = "/sample"
	//String varName = "name"

	//your code here
	//print "not implemented: WriteSamLabelToHeader"

	return(0)
End

// total counting time (seconds)
Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	//print "not implemented: WriteCountTimeToHeader"
	
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
	NVAR XPix = root:myGlobals:gNPixelsX
	
	// your reader here
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	if(err)
		return 0
	endif

	Wave hmm_xy = $(dfName+":data:hmm_xy")
	
	//redimension /I /N = (dimsize(hmm_xy, 2), dimsize(hmm_xy, 1)), data
	//nha. Count arrays need to be floating point, since the data will be divided, normalised etc. 
	redimension /N = (dimsize(hmm_xy, 2), dimsize(hmm_xy, 1)), data
	data[][] = hmm_xy[0][q][p]
	
	//nha workaround. for wrongly dimensioned Quokka data 191x192
	variable x_dim = dimsize(data,0)
	if (x_dim!=XPix)
		//redimension to add an extra row(s) to the data
		redimension /I /N = (XPix,-1) data
		//copy row 190 to row 191
		data[191][] = data[190][q]
	endif	
	// end workaround
	
	//funky edge correction bodgy ???
	//copy second column to first column
	data[][0] = data[p][1]
	//copy second last column to last column
	data[][191] = data[p][190]
	//copy second row to first row
	data[0][] = data[1][q]
	//copy second last row to last row
	data[191][] = data[190][q]
			
	KillWaves hmm_xy
	
	
	return(0)
End

// file suffix (NCNR data file name specific)
// return filename as suffix
Function/S getSuffix(fname)
	String fname
	
	return(ParseFilePath(0, fname, ":", 1, 0))
End

// associated file suffix (for transmission)
// NCNR Transmission calculation specific
// return null string
Function/S getAssociatedFileSuffix(fname)
	String fname
	
	return(getFileAssoc(fname))
End

// sample label
Function/S getSampleLabel(fname)
	String fname
	String str
	
	string dfName = ""
	hdfReadSimulated(fname, dfName)
	
	if (exists(dfName+":sample:name") != 1)
		// your code, returning str
		variable err
		err = hdfRead(fname, dfName)
		//err not handled here
	endif
	
	Wave/T wSampleName = $dfname+":sample:name"
	
	if (waveexists(wSampleName))
		str = wSampleName[0]
	else
		print "Can't find Sample Label in " + fname
		str = ""
	endif
	
	//KillWaves wSampleName
	

//	// your code, returning str
//	variable err
//	string dfName = ""
//	err = hdfRead(fname, dfName)
//	//err not handled here
//	
//	Wave/T wSampleName = $dfname+":sample:name"
//	str = wSampleName[0]
//	KillWaves wSampleName
	
	return(str)
End

// file creation date
Function/S getFileCreationDate(fname)
	String fname
	String str
	
	string dfName = ""
	hdfReadSimulated(fname, dfName)
	
	if (exists(dfName+":start_time") != 1)
		// your code, returning str
		variable err
		err = hdfRead(fname, dfName)
		//err not handled here
	endif
	
	Wave/T wStartTime = $dfName+":start_time"
	
	if (WaveExists(wStartTime))
		str = wStartTime[0]
	else
		print "Can't find File Creation Date in " + fname
		str = ""
	endif
	
	//KillWaves wSampleName
	
//	// your code, returning str
//	variable err
//	string dfName = ""
//	err = hdfRead(fname, dfName)
//	//err not handled here
//	
//	Wave/T wStartTime = $dfName+":start_time"
//	str = wStartTime[0]
//	KillWaves wStartTime
	
	return(str)
End


//monitor count
Function getMonitorCount(fname)
	String fname
	Variable value
	Variable att, err
	string dfName = ""
		
	//err = hdfRead(fname, dfName)
	//err not handled here
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	if(!WaveExists($(dfName+":monitor:bm1_counts")))
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave wMonCnts = $(dfName+":monitor:bm1_counts")
	if(WaveExists(wMonCnts))
		value = wMonCnts[0]
	else
		print "Can't find Monitor Count in " + fname
	endif	

	// davidm
	if (value == 0)
		print "***monitor count is ZERO*** and has been reset to 1.0"
		value = 1
	endif
	
	// [davidm]
	//KillWaves wAttrotdeg
	return(value)
end

//saved monitor count
// NCNR specific for pre-processed data, never used
// return 0
Function getSavMon(fname)
	String fname
	
	Variable value
	
	// your code returning value
	//??? to do. Is this required if 'never used'? nha
	
	return(0)
end

//total detector count
Function getDetCount(fname)
//not patched, but could be
	String fname
	Variable value
	
//	// your code returning value
//	variable err
//	string dfName = ""
//	err = hdfRead(fname, dfName)
	//err not handled here
	
	// [davidm]
	string dfName = ""
	hdfReadSimulated(fname, dfName)
	
	if(!WaveExists($(dfName+":data:total_counts")) && !WaveExists($(dfName+":instrument:detector:total_counts")))
		// your code, returning str
		variable err
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	//	Wave wCounts = $(dfName+":data:total_counts")
	// changed 22/12/09 nha
	if(WaveExists($(dfName+":data:total_counts")))
		Wave wCounts = $(dfName+":data:total_counts")
		value = wCounts[0]
	elseif(WaveExists($(dfName+":instrument:detector:total_counts")))
       	Wave wCounts = $(dfName+":instrument:detector:total_counts")
		value = wCounts[0]
       else
       	print "Can't find Total Detector Count in " + fname
       endif

	// davidm
	if (value < 1)
		print "Warning: Total Detector Count smaller than 1!"
	endif
	
	//nha 21/5/10 temporary glitch wrote detector count to file as 0	
//		if (value<1)
//			NVAR XPix = root:myGlobals:gNPixelsX
//			NVAR YPix = root:myGlobals:gNPixelsX
//			Make/D/O/N=(XPix,YPix) $"root:RAW:data"
//			WAVE data=$"root:RAW:data"
//			getDetectorData(fname,data)
//			value = sum(data)
//		endif
	
	// davidm
	if (value == 0)
		print "***total detector count is ZERO*** and has been reset to 1.0"
		value = 1
	endif
	
	// [davidm]
	//KillWaves wCounts
	
	return(value)
end

//Attenuator number, return 1 if your attenuators are not
// indexed by number
Function getAttenNumber(fname)
	String fname
	Variable value
	Variable att, err
	string dfName = ""
		
	//err = hdfRead(fname, dfName)
	//err not handled here
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	if(!WaveExists($(dfName+":instrument:collimator:att")) && !WaveExists($(dfName+":instrument:parameters:derived_parameters:AttRotDeg")))
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	if(WaveExists($(dfName+":instrument:collimator:att")))
		Wave wAttrotdeg = $(dfName+":instrument:collimator:att")
		value = wAttrotdeg[0]
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:AttRotDeg")))
		Wave wAttrotdeg = $(dfName+":instrument:parameters:derived_parameters:AttRotDeg")
		value = wAttrotdeg[0]
	else
		print "Can't find Attenuator in " + fname
	endif	
	
	att = round(value)/30
	
	// [davidm]
	//KillWaves wAttrotdeg
	return(att)
end


//transmission
Function getSampleTrans(fname)
	String fname
	
	Variable value
	
	// your code returning value
	variable err
	string dfName = ""
	
	//err = hdfRead(fname, dfName)
	//err not handled here
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	if(!WaveExists($(dfName+":reduce:Transmission")) && !WaveExists($(dfName+":instrument:parameters:Transmission")))
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	if(WaveExists($(dfName+":reduce:Transmission"))) //canonical location
		Wave wTransmission = $(dfName+":reduce:Transmission")
		value = wTransmission[0]
	elseif(WaveExists($(dfName+":instrument:parameters:Transmission"))) 
		Wave wTransmission = $(dfName+":instrument:parameters:Transmission")
		value = wTransmission[0]
	else 
		print "Can't find Transmission in " + fname
	endif
	
	// [davidm]
	//KillWaves wTransmission
		
	return(value)
end

//sample transmission (0<T<=1)
Function WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	// your writer here
	Wave wTransmission
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wTransmission
	String groupName = "/instrument/parameters"
	String varName = "Transmission"
	wTransmission[0] = trans //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wTransmission)
	KillWaves wTransmission
	//err not handled here
		
	return(0)
End

//box counts from stored transmission calculation
// return 0 if not using NCNR transmission module
Function getBoxCounts(fname)
	String fname
	Variable value
	
	// do nothing if not using NCNR Transmission module
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	Wave wBoxCounts = $(dfName+":reduce:boxCounts") 
	if (waveexists(wBoxCounts) == 0)
		//boxcounts not yet set in  reduce group
		print "No box counts in " + fname + ":reduce:boxCounts"
		value = 0
	else
		value = wBoxCounts[0]
	endif

	KillWaves/Z wBoxCounts
	
	return(value)
end

//whole detector transmission
// return 0 if not using NCNR transmission module
Function getSampleTransWholeDetector(fname)
	String fname
	Variable value
	
	//print "not implemented: getSampleTransWholeDetector"
	
	// your code returning value
	// ??? don't know what to put here. nha
	value=0
	return(value)
end

//SampleThickness in centimeters
Function getSampleThickness(fname)
	String fname
	Variable value

	// your code returning value
	
	variable err
	string dfName = ""
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	variable flag = 0
	if(WaveExists($(dfName+":sample:SampleThickness"))) //canonical location - a bit ugly and verbose, but that's just my opinion
		flag = 1
	elseif(WaveExists($(dfName+":sample:thickness")))
		flag = 1
	endif
	
	if (flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	if(WaveExists($(dfName+":sample:SampleThickness"))) //canonical location - a bit ugly and verbose, but that's just my opinion
		Wave wThickness = $(dfName+":sample:SampleThickness")
		value = wThickness[0]/10
	elseif(WaveExists($(dfName+":sample:thickness")))
		Wave wThickness = $(dfName+":sample:thickness")
		value = wThickness[0]/10
	else
		print "Can't find Sample Thickness in " + fname
	endif
			
	//value = 1 //??? temporary fix. nha
	// [davidm]
	//KillWaves wThickness
	
	return(value)
end

//sample thickness in cm
Function WriteThicknessToHeader(fname,thickness)
	String fname
	Variable thickness
	
	// your writer here
	Wave wThickness
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wThickness
	String groupName = "/sample"
	String varName = "SampleThickness"
	wThickness[0] = thickness*10 //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wThickness) //does not exist ???
	KillWaves wThickness
	//err not handled here
		
	return(0)
End

//Sample Rotation Angle (degrees)
Function getSampleRotationAngle(fname)
	String fname
	Variable value
	
	// your code returning value
	variable err
	string dfName = ""
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	if (exists(dfName+":sample:sample_theta") != 1)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave wSample_rotation_angle = $(dfName+":sample:sample_theta") //is this correct
	if (WaveExists(wSample_rotation_angle))
		value = wSample_rotation_angle[0]
	else
		print "Can't find Sample Rotation Angle in " + fname
	endif
	
	// [davidm]
	//KillWaves wSample_rotation_angle
		
	return(value)
end

//temperature (C)
Function getTemperature(fname)
	String fname
	Variable value
	
	// your code returning value
	variable err
	string dfName = ""
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	if (exists(dfName+":sample:tc1:sensor:value") != 1)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave wSample_tc1_value = $(dfName+":sample:tc1:sensor:value")
	if (WaveExists(wSample_tc1_value))
		value = wSample_tc1_value[0]
	else
		print "Can't find Sample Rotation Angle in " + fname
	endif
	
	// [davidm]
	//KillWaves wSample_tc1_value
	
	return(value)
end

//field strength (Oe)
Function getFieldStrength(fname)
	String fname
	
	Variable value
	
	// your code returning value
	//print "not implemented: getFieldStrength"
	
	return(value)
end

//center of beam xPos in pixel coordinates
Function getBeamXPos(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	variable flag = 0	
	if(WaveExists($(dfName+":instrument:parameters:BeamCenterX"))) //canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:reduce:BeamCenterX")))
		flag = 1
	endif
	
	if (flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif
	
	if(WaveExists($(dfName+":instrument:parameters:BeamCenterX"))) //canonical location
		Wave wBeamXPos = $(dfName+":instrument:parameters:BeamCenterX")
		value = wBeamXPos[0]
	elseif(WaveExists($(dfName+":instrument:reduce:BeamCenterX"))) // check if its an old file
		Wave wBeamXPos = $(dfName+":instrument:reduce:BeamCenterX")
		value = wBeamXPos[0]
	else
		print "Can't find BeamCenterX in" + fname
	endif

	// if BeamCenterX was not found then wBeamXPos doesn't exist [dmaennic]
	// value = wBeamXPos[0]	
	// KillWaves wBeamXPos
		
	return(value)	
end

//beam center X pixel location (detector coordinates)
Function WriteBeamCenterXToHeader(fname,beamCenterX)
	String fname
	Variable beamCenterX
	
	// your writer here
	Wave wBeamCenterX
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wBeamCenterX
	String groupName = "/instrument/parameters"
	String varName = "BeamCenterX"
	wBeamCenterX[0] = beamCenterX //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wBeamCenterX)
	KillWaves wBeamCenterX
	//err not handled here
	
	return(0)
End

//center of beam Y pos in pixel coordinates
Function getBeamYPos(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""

	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	variable flag = 0	
	if(WaveExists($(dfName+":instrument:parameters:BeamCenterZ"))) //canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:reduce:BeamCenterZ")))
		flag = 1
	endif
	
	if (flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	if(WaveExists($(dfName+":instrument:parameters:BeamCenterZ"))) //canonical location
		Wave wBeamYPos = $(dfName+":instrument:parameters:BeamCenterZ")
		value = wBeamYPos[0]			
	elseif(WaveExists($(dfName+":instrument:reduce:BeamCenterZ")))
		Wave wBeamYPos = $(dfName+":instrument:reduce:BeamCenterZ")
		value = wBeamYPos[0]
	else
		print "Can't find BeamCenterZ in" + fname
	endif
		
	// if BeamCenterY was not found then wBeamYPos doesn't exist [dmaennic]
	// value = wBeamYPos[0]	
	// KillWaves wBeamYPos
		
	return(value)
end

//beam center Y pixel location (detector coordinates)
Function WriteBeamCenterYToHeader(fname,beamCenterY)
	String fname
	Variable beamCenterY
	
	// your writer here
	Wave wBeamCenterY
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wBeamCenterY
	String groupName = "/instrument/parameters"
	String varName = "BeamCenterZ"
	wBeamCenterY[0] = beamCenterY //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wBeamCenterY)
	KillWaves wBeamCenterY
	//err not handled here

	return(0)
End

//sample to detector distance (meters)
Function getSSD(fname) // added by [davidm]
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	
	// [davidm]
	//err = hdfRead(fname, dfName)
	//err not handled here

	hdfReadSimulated(fname, dfName)
	
	variable flag = 0
	if(WaveExists($(dfName+":instrument:parameters:L1"))) //canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:parameters:L1mm")))
		flag = 1
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:L1mm")))
		flag = 1
	endif
	
	if(flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	//workaround for bad HDF5 dataset
	if(WaveExists($(dfName+":instrument:parameters:L1"))) //canonical location
		Wave wSampleToSourceDist = $(dfName+":instrument:parameters:L1")
		value = wSampleToSourceDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:L1mm")))
		Wave wSampleToSourceDist = $(dfName+":instrument:parameters:L1mm")
		value = wSampleToSourceDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:L1mm")))	
		Wave wSampleToSourceDist = $(dfName+":instrument:parameters:derived_parameters:L1mm")
		value = wSampleToSourceDist[0]/1000
	else
		print "Can't find L1 in " + fname
	endif
	
	// [davidm]
	//KillWaves wSourceToDetectorDist
		
	return(value)
end

//sample to detector distance (meters)
Function getSDD(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	
	// [davidm]
	//err = hdfRead(fname, dfName)
	//err not handled here

	hdfReadSimulated(fname, dfName)
	
	variable flag = 0
	if(WaveExists($(dfName+":instrument:parameters:L2"))) //canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:parameters:L2mm")))
		flag = 1
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:L2mm")))
		flag = 1
	endif
	
	if(flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	//workaround for bad HDF5 dataset
	if(WaveExists($(dfName+":instrument:parameters:L2"))) //canonical location
		Wave wSourceToDetectorDist = $(dfName+":instrument:parameters:L2")
		value = wSourceToDetectorDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:L2mm")))
		Wave wSourceToDetectorDist = $(dfName+":instrument:parameters:L2mm")
		value = wSourceToDetectorDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:L2mm")))	
		Wave wSourceToDetectorDist = $(dfName+":instrument:parameters:derived_parameters:L2mm")
		value = wSourceToDetectorDist[0]/1000
	else
		print "Can't find L2 in " + fname
	endif
	
	// [davidm]
	//KillWaves wSourceToDetectorDist
		
	return(value)
end

//sample to detector distance (meters)
Function WriteSDDToHeader(fname,sdd)
	String fname
	Variable sdd
	
// your writer here
	Wave wSDD
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wSDD
	String groupName = "/instrument/parameters"
	String varName = "L2"
	wSDD[0] = sdd * 1000 //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wSDD)
	KillWaves wSDD
	//err not handled here
	
	return(0)
End

//lateral detector offset (centimeters)
Function getDetectorOffset(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	Wave wDetectorOffset = $(dfName+":instrument:detector:detector_x") //is this correct
	value = wDetectorOffset[0]/10
	KillWaves wDetectorOffset
	
	return(value)
end

//Beamstop diameter (millimeters)
Function getBSDiameter(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	if(WaveExists($(dfName+":instrument:parameters:BSdiam"))) //canonical location
		Wave wBSdiameter = $(dfName+":instrument:parameters:BSdiam")
		value = wBSdiameter[0]
	elseif(WaveExists($(dfName+":instrument:parameters:BSXmm")))
		Wave wBSdiameter = $(dfName+":instrument:parameters:BSXmm") 
		value = wBSdiameter[0]
	else
		print "Can't find Beamstop Diameter in " + fname
	endif
	
	KillWaves wBSdiameter
	
	return(value)	
end

//beam stop diameter (millimeters)
Function WriteBeamStopDiamToHeader(fname,bs)
	String fname
	Variable bs	
	
	// your writer here
	Wave wBS
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wBS
	String groupName = "/instrument/parameters"
	String varName = "BSdiam"
	wBS[0] = bs //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wBS)
	KillWaves wBS
	//err not handled here
	return(0)
End

//source aperture diameter (millimeters)
Function getSourceApertureDiam(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	if(WaveExists($(dfName+":instrument:parameters:EApX")))
		Wave wSourceApertureDiam = $(dfName+":instrument:parameters:EApX") // canonical location
		value = wSourceApertureDiam[0]
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:EApXmm")))
		Wave wSourceApertureDiam = $(dfName+":instrument:parameters:derived_parameters:EApXmm") 
		value = wSourceApertureDiam[0]
	else
		print "Can't find Source Aperture Diameter in " + fname
	endif
	
	KillWaves wSourceApertureDiam
	
	return(value)
end

//Source Aperture diameter (millimeters)
Function WriteSourceApDiamToHeader(fname,source)
	String fname
	Variable source
	
	// your writer here
	Wave wsource
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wsource
	String groupName = "/instrument/parameters"
	String varName = "EApX"
	wsource[0] = source //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wsource)
	KillWaves wsource
	//err not handled here
	return(0)
End

//sample aperture diameter (millimeters)
Function getSampleApertureDiam(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	if(WaveExists($(dfName+":sample:diameter"))) //canonical location
		Wave wSampleApertureDiam = $(dfName+":sample:diameter")
		value = wSampleApertureDiam[0]
	elseif(WaveExists($(dfName+":instrument:parameters:autoSampleAp:diameter"))) //canonical location
		Wave wSampleApertureDiam = $(dfName+":instrument:parameters:autoSampleAp:diameter")
		value = wSampleApertureDiam[0]
	elseif (WaveExists($(dfName+":instrument:sample_aperture:geometry:shape:SApXmm")))
		Wave wSampleApertureDiam = $(dfName+":instrument:sample_aperture:geometry:shape:SApXmm") 
		value = wSampleApertureDiam[0]
	else
		print "Can't find Sample Aperture Diameter in " + fname
	endif
	
	KillWaves wSampleApertureDiam

	return(value)	
end

//Sample Aperture diameter (millimeters)
Function WriteSampleApDiamToHeader(fname,source)
	String fname
	Variable source
	
	// your writer here
	Wave wsource
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wsource
	String groupName = "/sample"
	String varName = "diameter"
	wsource[0] = source //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wsource)
	KillWaves wsource
	//err not handled here
	return(0)
End

//source AP to Sample AP distance (meters)
Function getSourceToSampleDist(fname)
	String fname
	
	Variable value
	
	// your code returning value
	variable err
	string dfName = ""
		
	err = hdfRead(fname, dfName)
	//err not handled here
	
	if(WaveExists($(dfName+":instrument:parameters:L1"))) //canonical location
		Wave wSourceToSampleDist = $(dfName+":instrument:parameters:L1") 	
		value = wSourceToSampleDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:L1mm")))
		Wave wSourceToSampleDist = $(dfName+":instrument:parameters:L1mm") 
		value = wSourceToSampleDist[0]/1000
	elseif(WaveExists($(dfName+":instrument:parameters:derived_parameters:L1mm")))
		Wave wSourceToSampleDist = $(dfName+":instrument:parameters:derived_parameters:L1mm")
		value = wSourceToSampleDist[0]/1000
	else
		print "Can't find L1 in " + fname
	endif
	
	KillWaves wSourceToSampleDist	
		
	return(value)
end

//Source aperture to sample aperture distance (meters)
Function WriteSrcToSamDistToHeader(fname,SSD)
	String fname
	Variable SSD
	
// your writer here
	Wave wSSD
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wSSD
	String groupName = "/instrument/parameters"
	String varName = "L1"
	wSSD[0] = SSD * 1000 //input in metres, converted to mm for saving to file.
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wSSD)
	KillWaves wSSD
	//err not handled here
	
	return(0)
End

//wavelength (Angstroms)
Function getWavelength(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	//err = hdfRead(fname, dfName)
	//err not handled here

	// [davidm]
	hdfReadSimulated(fname, dfName)

	variable flag = 0
	if(WaveExists($(dfName+":instrument:velocity_selector:wavelength")))  // canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:velocity_selector:Lambda"))) 
		flag = 1
	elseif(WaveExists($(dfName+":data:Lambda")))
		flag = 1
	elseif(WaveExists($(dfName+":data:LambdaA")))
		flag = 1
	elseif(WaveExists($(dfName+":instrument:velocity_selector:LambdaA")))
		flag = 1
	endif 

	if(flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif	

	//	Wave wWavelength = $(dfName+":data:LambdaA") 
	//change 22/12/09 nha
	// all these locations to be deprecated 
	if(WaveExists($(dfName+":instrument:velocity_selector:wavelength")))  // canonical location
		Wave wWavelength = $(dfName+":instrument:velocity_selector:wavelength") 
		value = wWavelength[0]
	elseif(WaveExists($(dfName+":instrument:velocity_selector:Lambda"))) 
		Wave wWavelength = $(dfName+":instrument:velocity_selector:Lambda") 
		value = wWavelength[0]
	elseif(WaveExists($(dfName+":data:Lambda")))
		Wave wWavelength = $(dfName+":data:Lambda") 
		value = wWavelength[0]
	elseif(WaveExists($(dfName+":data:LambdaA")))
		Wave wWavelength = $(dfName+":data:LambdaA") 
		value = wWavelength[0]
	elseif(WaveExists($(dfName+":instrument:velocity_selector:LambdaA")))
		Wave wWavelength = $(dfName+":instrument:velocity_selector:LambdaA") 
		value = wWavelength[0]
	else
		print "Can't find Lambda in " + fname
	endif 
	
	// [davidm]
	//KillWaves wWavelength
	
	return(value)
end

//wavelength (Angstroms)
Function WriteWavelengthToHeader(fname,wavelength)
	String fname
	Variable wavelength
	
	// your writer here
	Wave wWavelength
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wWavelength
	String groupName = "/instrument/velocity_selector"
	String varName = "wavelength"
	wWavelength[0] = wavelength //
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wWavelength)
	
	//and because Bill Hamilton is not happy with the NeXus naming, we write it to 3 other places
	//groupName = "/instrument/parameters"
	//err = hdfWrite(fname, groupName, varName, wWavelength)
	//velocity_selector group causes Igor crash in some cases
	//groupName = "/instrument/velocity_selector"
	//err = hdfWrite(fname, groupName, varName, wWavelength)
	//
	//groupName = "/data"
	//varName = "lambda"
	//err = hdfWrite(fname, groupName, varName, wWavelength)
	
	KillWaves wWavelength
	//err not handled here

	return(0)
End



//wavelength spread (FWHM)
Function getWavelengthSpread(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	//err = hdfRead(fname, dfName)
	//err not handled here

	// [davidm]
	hdfReadSimulated(fname, dfName)

	variable flag = 0
	if(WaveExists($(dfName+":instrument:velocity_selector:wavelength_spread")))  //canonical location
		flag = 1
	elseif(WaveExists($(dfName+":instrument:velocity_selector:LambdaResFWHM_percent"))) 
		flag = 1
	elseif(WaveExists($(dfName+":instrument:parameters:LambdaResFWHM_percent"))) 
		flag = 1
	endif

	if(flag == 0)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif	

	//velocity_selector group causes Igor crash
	if(WaveExists($(dfName+":instrument:velocity_selector:wavelength_spread")))  //canonical location
		Wave wWavelengthSpread = $(dfName+":instrument:velocity_selector:wavelength_spread")
		value = wWavelengthSpread[0]	
	elseif(WaveExists($(dfName+":instrument:velocity_selector:LambdaResFWHM_percent"))) 
		Wave wWavelengthSpread = $(dfName+":instrument:velocity_selector:LambdaResFWHM_percent")
		value = wWavelengthSpread[0]	
	elseif(WaveExists($(dfName+":instrument:parameters:LambdaResFWHM_percent"))) 
		Wave wWavelengthSpread = $(dfName+":instrument:parameters:LambdaResFWHM_percent")
		value = wWavelengthSpread[0]	
	else
		print "Can't find Wavelength Spread in " + fname
	endif
	
	KillWaves wWavelengthSpread
	
	return(value)
end

//wavelength spread (FWHM)
Function WriteWavelengthDistrToHeader(fname,wavelengthSpread)
	String fname
	Variable wavelengthSpread
	
	// your writer here
	Wave wWavelengthSpread
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make /N=(1,1) wWavelengthSpread
	//velocity_selector group causes Igor crash
	String groupName = "/instrument/velocity_selector"
	String varName = "wavelength_spread"

	wWavelengthSpread[0] = wavelengthSpread 
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wWavelengthSpread)
	KillWaves wWavelengthSpread
	//err not handled here
		
	return(0)
End

// physical x-dimension of a detector pixel, in mm
Function getDetectorPixelXSize(fname)
	String fname
	Variable value
	
	// your code here returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	Wave wActiveArea = $(dfName+":instrument:detector:active_height") 
	Wave w_x_bin = $(dfName+":instrument:detector:x_bin")
	Variable numPixels = dimsize(w_x_bin, 0) - 1 // davidm: detector has 192 bins! not 193
	value = wActiveArea[0]/numPixels
	KillWaves wActiveArea
	KillWaves w_x_bin
	
	return(value)
end

// physical y-dimension of a detector pixel, in mm
Function getDetectorPixelYSize(fname)
	String fname
	Variable value
	
	// your code here returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here

	Wave wActiveArea = $(dfName+":instrument:detector:active_width") 
	Wave w_y_bin = $(dfName+":instrument:detector:y_bin")
	Variable numPixels = dimsize(w_y_bin, 0) - 1 // davidm: detector has 192 bins! not 193
	value = wActiveArea[0]/numPixels
	KillWaves wActiveArea
	KillWaves w_y_bin
			
	return(value)
end

//transmission detector count (unused, return 0)
//
Function getTransDetectorCounts(fname)
	String fname
	
	Variable value
	
	// your code returning value
	//print "not implemented: getTransDetectorCounts"
	
	return(0)
end


//total count time (seconds)
Function getCountTime(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	//err = hdfRead(fname, dfName)
	//err not handled here
	
	// [davidm]
	hdfReadSimulated(fname, dfName)
	if (exists(dfName+":monitor:bm1_time")!= 1)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave wTime1 = $(dfName+":monitor:bm1_time") 
	
	if (WaveExists(wTime1))
		value = wTime1[0]
	else
		print "Can't find Total Count Time in " + fname
	endif
	
	// [davidm]
	//KillWaves wTime1
	
	if (value == 0)
		print "***total count time is ZERO*** and has been reset to 1.0"
		value = 1
	endif
	
	return(value)
end


Function getPhysicalWidth(fname)
	String fname
	Variable value
	// your code returning value
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here 

	Wave wPhysicalWidth = $(dfName+":instrument:detector:active_width") 

	if (WaveExists(wPhysicalWidth))
		value = wPhysicalWidth[0]/10
	else
		print "Can't find Physical Width in " + fname
	endif
	
	KillWaves wPhysicalWidth
		
	return(value)
end

Function/S getSICSVersion(fname)
	String fname
	String str
	// your code returning value
	variable err
	string dfName = ""
	//err = hdfRead(fname, dfName)
	//err not handled here
	
	hdfReadSimulated(fname, dfName)
	if (exists(dfName+":sics_release") != 1)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave/T wSICSVersion = $(dfName+":sics_release") 
	
	if (WaveExists(wSICSVersion))
		str = wSICSVersion[0]
	else
		print "Can't find SICS Version in " + fname
		str = ""
	endif
	
	// [davidm]
	// KillWaves wSICSVersion
	
	return(str)
end

Function/S getHDFversion(fname)
	String fname
	String str
	// your code returning value
	variable err
	string dfName = ""
	string attribute = "HDF5_Version"
	
	// [davidm]
	hdfReadAttributeSimulated(fname, dfName, "/", 1, attribute)
	if (exists(dfName+":"+attribute) != 1)
		err = hdfReadAttribute(fname, dfName, "/", 1, attribute)
		//err not handled here
	endif

//	string attribute ="signal"
//	err = hdfReadAttribute(fname, dfName, "/entry/data/hmm_xy", 2, attribute)
	//err not handled here 

	Wave/T wHDF5_Version = $(dfName+":"+attribute) 
	
	if (WaveExists(wHDF5_Version))
		str = wHDF5_Version[0]	
	else
		print "Can't find HDF Version in " + fname
		str = ""
	endif
	
//	KillWaves wHDF5_Version

	return(str)
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
Function getXYBoxFromFile(fname,x1,x2,y1,y2)
	String fname
	Variable &x1,&x2,&y1,&y2
	
	// return your bounding box coordinates or default values of 0
	x1=0
	y1=0
	x2=0
	y2=0

	// your code returning value
	variable err
	string dfName = ""
	//err = hdfRead(fname, dfName)
	//err not handled here 

	// [davidm]
	hdfReadSimulated(fname, dfName)
	
	if(!WaveExists($(dfName+":reduce:x1")))
		err = hdfRead(fname, dfName)
		//err not handled here
	endif
	
	Wave wX1 = $(dfName+":reduce:x1") 
	if (waveexists(wX1) == 0)
		//Waves don't exists which means an XY box has not been set for this file.
		//Hence return 0 bounding boxes (default)
	else
		x1 = wX1[0]
		Wave wX2 = $(dfName+":reduce:x2") 
		x2 = wX2[0]
		Wave wY1 = $(dfName+":reduce:y1") 
		y1 = wY1[0]
		Wave wY2 = $(dfName+":reduce:y2") 
		y2 = wY2[0]
	endif
	
	// [davidm]
	//KillWaves/Z wX1, wX2, wY1, wY2
	return(0)

End

// Writes the coordinates of the box to the header after user input
//
// box to sum over bounded (x1,y1) to (x2,y2)
//
// if not using the NCNR Transmission module, this function is null
Function WriteXYBoxToHeader(fname,x1,x2,y1,y2)
	String fname
	Variable x1,x2,y1,y2

	String groupName = "/reduce"
	variable err
		
	Wave wX1
	Make/O/N=(1,1) wX1
	Wave wX2
	Make/O/N=(1,1) wX2
	Wave wY1
	Make/O/N=(1,1) wY1
	Wave wY2
	Make/O/N=(1,1) wY2
		
	wX1[0] = x1
	wX2[0] = x2
	wY1[0] = y1
	wY2[0] = y2	
	
	String varName = "x1"	
	err = hdfWrite(fname, groupName, varName,wX1)
	varName = "x2"
	err = hdfWrite(fname, groupName, varName,wX2)
	varName = "y1"
	err = hdfWrite(fname, groupName, varName,wY1)
	varName = "y2"
	err = hdfWrite(fname, groupName, varName,wY2)	
	
	KillWaves wX1,wX2,wY1,wY2
	
	//err not handled here
	return(0)	

End

// for transmission calculation, writes an NCNR-specific alphanumeric identifier
// (suffix of the data file)
//
//AJJ June 3 2010 - Note!! For ANSTO data the "suffix" is just the filename.
Function WriteAssocFileSuffixToHeader(fname,assoc_fname)
	String fname,assoc_fname
		
// your writer here
	Wave/T wAssoc_fname
	//nha ??? Should make this wave in our own DataFolder to avoid clashing names. 
	Make/T /N=(1,1) wAssoc_fname
	
	String varName =""
	String groupName = "/reduce"
	if(isTransFile(fname))
		varName = "empty_beam_file_name"
	elseif(isScatFile(fname))
		varName = "transmission_file_name"
	endif

	wAssoc_fname[0] = assoc_fname 
	// your code returning value
	variable err
	err = hdfWrite(fname, groupName, varName, wAssoc_fname)
	KillWaves wAssoc_fname
	//err not handled here
	return(0)
end

Function/S GetFileAssoc(fname)
	String fname
	
	String assoc_fname
	String groupName = ":reduce:"
	
	String varName = ""
	if(isTransFile(fname))
		varName = "empty_beam_file_name"
	elseif(isScatFile(fname))
		varName = "transmission_file_name"
	endif
	
	variable err
	string dfName = ""
	err = hdfRead(fname, dfName)
	//err not handled here 

	Wave/T wAssoc_fname = $(dfName+groupName+varName) 
	if (waveexists(wAssoc_fname) == 1)
		assoc_fname =wAssoc_fname[0]	
	else
		assoc_fname = ""
	endif
	KillWaves/Z wAssoc_fname
	
	return(assoc_fname)
end

Function hdfReadAttribute(fname, dfName, nodeName, nodeType, attributeStr)
// this is a copy of hdfRead, and could be incorporated back into hdfRead.
	
	String fname, &dfName, nodeName, attributeStr
	variable nodeType
	String nxentryName
	variable err=0,fileID	
	String cDF = getDataFolder(1), temp
	String fname_temp = ParseFilePath(0, fname, ":", 1, 0)

	
	String fileSuffix
	
	if(strsearch(fname_temp,".nx.hdf",0,2)>=0)
		fileSuffix=".nx.hdf"
	else
		err = 1
		abort "unrecognised file suffix. Not .nx.hdf"
	endif
	
	dfName = "root:packages:quokka:"+removeending(fname_temp,fileSuffix)
	
	//folder must already exist i.e. hdfRead must have already been called
	if(!DataFolderExists(dfName)) 
		// possibly call an hdfRead from here
		return err
	endif
	
	//test for the name of nxentry
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		nxentryName = removeending(fname_temp,fileSuffix)
	elseif(DataFolderExists(dfName+":"+"entry1"))
		nxentryName = "entry1"
	else
		print "NXentry not found"
		return err
	endif
	
	//this is the stupid bit.
	// If you're looking for attributes of the root node, then nodename = "/"
	// If you're looking for attributes 	of the nxentry node, then e.g. nodename ="/entry/instrument"
	// /entry is replaced with nxentryName
	nodeName = ReplaceString("entry", nodeName, nxentryName)	
	
	//convert nodeName to data folder string
	String dfNodeName = nodeName
	dfNodeName = ReplaceString( "/", nodeName, ":")
	dfName = dfName + dfNodeName
	if(nodeType == 2) //data item (dataset)
		//remove the end of dfName so that it points to a folder and not a dataset
		variable length = strlen(dfName) 
		variable position = strsearch(dfName, ":", length, 1) // search backwards to find last :
		// to do - truncate string to remove dataset
		string truncate = "\"%0." + num2str(position) + "s\""
		sprintf dfName, truncate, dfName
	endif
	
	setDataFolder dfName
	
	try	
		HDF5OpenFile /R /Z fileID  as fname
		if(!fileID)
			err = 1
			abort "couldn't load HDF5 file"
		endif

		HDF5LoadData /O /Q /Z /TYPE=(nodeType) /A=attributeStr, fileID, nodeName

		if (V_flag!=0)
			print "couldn't load attribute " + attributeStr
		endif
	catch

	endtry
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

// add the name of the root node to dfName 
// in the case of sensitivity files aka DIV files, don't append a root node to dfName
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		dfName = dfName+":"+removeending(fname_temp,fileSuffix)  //for files written Dec 2009 and after
	elseif(DataFolderExists(dfName+":"+"entry1"))
		dfName = dfName+":entry1" //for files written before Dec 2009
	endif

	setDataFolder $cDF
	return err
end
Function hdfReadAttributeSimulated(fname, dfName, nodeName, nodeType, attributeStr)
// this is a copy of hdfRead, and could be incorporated back into hdfRead.
	
	String fname, &dfName, nodeName, attributeStr
	variable nodeType
	String nxentryName
	variable err=0,fileID	
	String cDF = getDataFolder(1), temp
	String fname_temp = ParseFilePath(0, fname, ":", 1, 0)

	
	String fileSuffix
	
	if(strsearch(fname_temp,".nx.hdf",0,2)>=0)
		fileSuffix=".nx.hdf"
	else
		err = 1
		abort "unrecognised file suffix. Not .nx.hdf"
	endif
	
	dfName = "root:packages:quokka:"+removeending(fname_temp,fileSuffix)
	
	//folder must already exist i.e. hdfRead must have already been called
	if(!DataFolderExists(dfName)) 
		// possibly call an hdfRead from here
		return err
	endif
	
	//test for the name of nxentry
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		nxentryName = removeending(fname_temp,fileSuffix)
	elseif(DataFolderExists(dfName+":"+"entry1"))
		nxentryName = "entry1"
	else
		print "NXentry not found"
		return err
	endif
	
	//this is the stupid bit.
	// If you're looking for attributes of the root node, then nodename = "/"
	// If you're looking for attributes 	of the nxentry node, then e.g. nodename ="/entry/instrument"
	// /entry is replaced with nxentryName
	nodeName = ReplaceString("entry", nodeName, nxentryName)	
	
	//convert nodeName to data folder string
	String dfNodeName = nodeName
	dfNodeName = ReplaceString( "/", nodeName, ":")
	dfName = dfName + dfNodeName
	if(nodeType == 2) //data item (dataset)
		//remove the end of dfName so that it points to a folder and not a dataset
		variable length = strlen(dfName) 
		variable position = strsearch(dfName, ":", length, 1) // search backwards to find last :
		// to do - truncate string to remove dataset
		string truncate = "\"%0." + num2str(position) + "s\""
		sprintf dfName, truncate, dfName
	endif
	
	setDataFolder dfName
	
//	try	
//		HDF5OpenFile /R /Z fileID  as fname
//		if(!fileID)
//			err = 1
//			abort "couldn't load HDF5 file"
//		endif
//
//		HDF5LoadData /O /Q /Z /TYPE=(nodeType) /A=attributeStr, fileID, nodeName
//
//		if (V_flag!=0)
//			print "couldn't load attribute " + attributeStr
//		endif
//	catch
//
//	endtry
//	if(fileID)
//		HDF5CloseFile /Z fileID 
//	endif

// add the name of the root node to dfName 
// in the case of sensitivity files aka DIV files, don't append a root node to dfName
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		dfName = dfName+":"+removeending(fname_temp,fileSuffix)  //for files written Dec 2009 and after
	elseif(DataFolderExists(dfName+":"+"entry1"))
		dfName = dfName+":entry1" //for files written before Dec 2009
	endif

	setDataFolder $cDF
	return err
end

Function hdfRead(fname, dfName)
	//Reads hdf5 file into root:packages:quokka:fname
	//N. Hauser. 16/12/08
	// 29/1/09 - hdf file must have .nx.hdf or .div suffix 
	
	String fname, &dfName
	variable err=0,fileID
	String cDF = getDataFolder(1), temp
	String fname_temp = ParseFilePath(0, fname, ":", 1, 0)
		
	String fileSuffix
	if(strsearch(fname_temp,".nx.hdf",0,2)>=0)
		fileSuffix=".nx.hdf"
	//elseif(strsearch(fname_temp,".div",0,2)>=0)
	//	fileSuffix=".div"
	else
		err = 1
		abort "unrecognised file suffix. Not .nx.hdf"
	endif
	
	dfName = "root:packages:quokka:"+removeending(fname_temp,fileSuffix)
	
	//if(!DataFolderExists(dfName))
	//	return err
	//else		
		newDataFolder /O root:packages
		newDataFolder /O /S root:packages:quokka
		newDataFolder /O /S $dfName
	//endif 
	
	try	
		HDF5OpenFile /R /Z fileID  as fname
		if(!fileID)
			err = 1
			abort "couldn't load HDF5 file"
		endif
		HDF5LoadGroup /O /R /Z  :, fileID, "."
	catch

	endtry
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	// add the name of the root node to dfName 
	// in the case of sensitivity files aka DIV files, don't append a root node to dfName
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		dfName = dfName+":"+removeending(fname_temp,fileSuffix)  //for files written Dec 2009 and after
	elseif(DataFolderExists(dfName+":"+"entry1"))
		dfName = dfName+":entry1" //for files written before Dec 2009
	endif

	setDataFolder $cDF
	return err
end
Function hdfReadSimulated(fname, dfName)
	//Reads hdf5 file into root:packages:quokka:fname
	//N. Hauser. 16/12/08
	// 29/1/09 - hdf file must have .nx.hdf or .div suffix 
	
	String fname, &dfName
	variable err=0,fileID
	String cDF = getDataFolder(1), temp
	String fname_temp = ParseFilePath(0, fname, ":", 1, 0)
		
	String fileSuffix
	if(strsearch(fname_temp,".nx.hdf",0,2)>=0)
		fileSuffix=".nx.hdf"
	//elseif(strsearch(fname_temp,".div",0,2)>=0)
	//	fileSuffix=".div"
	else
		err = 1
		abort "unrecognised file suffix. Not .nx.hdf"
	endif
	
	dfName = "root:packages:quokka:"+removeending(fname_temp,fileSuffix)
	
	//if(!DataFolderExists(dfName))
	//	return err
	//else		
		newDataFolder /O root:packages
		newDataFolder /O /S root:packages:quokka
		newDataFolder /O /S $dfName
	//endif 
	
//	try	
//		HDF5OpenFile /R /Z fileID  as fname
//		if(!fileID)
//			err = 1
//			abort "couldn't load HDF5 file"
//		endif
//		HDF5LoadGroup /O /R /Z  :, fileID, "."
//	catch
//
//	endtry
//	if(fileID)
//		HDF5CloseFile /Z fileID 
//	endif

	// add the name of the root node to dfName 
	// in the case of sensitivity files aka DIV files, don't append a root node to dfName
	if(DataFolderExists(dfName+":"+removeending(fname_temp,fileSuffix)))
		dfName = dfName+":"+removeending(fname_temp,fileSuffix)  //for files written Dec 2009 and after
	elseif(DataFolderExists(dfName+":"+"entry1"))
		dfName = dfName+":entry1" //for files written before Dec 2009
	endif

	setDataFolder $cDF
	return err
end

Function hdfWrite(fname, groupName, varName, wav)
	//Write Wave 'wav' to hdf5 file 'fname'
	//N. Hauser. nha 8/1/09
		
	String fname, groupName, varName
	Wave wav
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String fname_temp = ParseFilePath(0, fname, ":", 1, 0)
	String NXentry_name
			
	try	
		HDF5OpenFile/Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		//get the NXentry node name
		HDF5ListGroup /TYPE=1 fileID, "/"
		//remove trailing ; from S_HDF5ListGroup
		NXentry_name = S_HDF5ListGroup
		NXentry_name = ReplaceString(";",NXentry_name,"")
		if(strsearch(NXentry_name,":",0)!=-1) //more than one entry under the root node
			err = 1
			abort "More than one entry under the root node. Ambiguous"
		endif 
		//concatenate NXentry node name and groupName	
		groupName = "/" + NXentry_name + groupName
		HDF5OpenGroup /Z fileID , groupName, groupID

	//	!! At the moment, there is no entry for sample thickness in our data file
	//	therefore create new HDF5 group to enable write / patch command
	//	comment out the following group creation once thickness appears in revised file
	
		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else
			// get attributes and save them
			//HDF5ListAttributes /Z fileID, groupName    this is returning null. expect it to return semicolon delimited list of attributes 
			//Wave attributes = S_HDF5ListAttributes
		endif
	
		HDF5SaveData /O /Z /IGOR=0  wav, groupID, varName
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset" + varName
		endif	
		
		//HDF5SaveData /O /Z /IGOR=0 /A=attributes groupID, varName
		//if (V_flag != 0)
		////	err = 1
		//	abort "Cannot save attributes to HDF5 dataset"
		//endif	
	catch

	endtry
	
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif
	
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	setDataFolder $cDF
	return err
end

Function DoEdgeCorrection(type)
	String type
	variable err = 0
	
	WAVE typeData=$("root:Packages:NIST:"+type+":data")
	
	//nha workaround for high counts on edges
	//copy second column to first column
	typeData[][0] = typeData[p][1]
	//copy second last column to last column
	typeData[][191] = typeData[p][190]
	//copy second row to first row
	typeData[0][] = typeData[1][q]
	//copy second last row to last row
	typeData[191][] = typeData[190][q]
	
	return err	
end

////// OCT 2009, facility specific bits from ProDiv()
//"type" is the data folder that has the corrected, patched, and normalized DIV data array
//
// the header of this file is rather unimportant. Filling in a title at least would be helpful/
//
Function Write_DIV_File(type)
	String type
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	WriteHeaderAndWork(type)
	
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
	//print "not implemented: Write_RawData_File"
	
	return(fullpath)
End