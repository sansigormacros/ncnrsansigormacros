#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 6.0

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
	String curPath = "root:RAW"
	SetDataFolder curPath		//use the full path, so it will always work
	Variable/G root:RAW:gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	
	Variable refNum,integer,realval,ii
	String sansfname,textstr,v0
	
	Make/D/O/N=23 $"root:RAW:IntegersRead"
	Make/D/O/N=52 $"root:RAW:RealsRead"
	Make/O/T/N=11 $"root:RAW:TextRead"
	
	Wave intw=$"root:RAW:IntegersRead"
	Wave realw=$"root:RAW:RealsRead"
	Wave/T textw=$"root:RAW:TextRead"
	
	// FILL IN 3 ARRAYS WITH HEADER INFORMATION FOR LATER USE
	// THESE ARE JUST THE MINIMALLY NECESSARY VALUES
	
	// filename as stored in the file header
	Open/R refNum as fname
	//skip first two bytes (VAX record length markers, not needed here)
//	FSetPos refNum, 2
	//read the next 21 bytes as characters (fname)
	
	
	
	for (ii=0;ii<2;ii+=1)
		FReadLine refNum,textstr
		sscanf textstr,"%s",v0
	
	endfor
	
	Close refnum
	
	textw[0]= v0
	
//	print "function read raw used"
	
	// date and time of collection
	textw[1]= getFileCreationDate(fname)
	
	// run type identifier (this is a reader for RAW data)
	textw[2]= "RAW"
	
	// user account identifier (currently used only for NCNR-specific operations)
	textw[3]= getFileInstrument(fname) 

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
	realw[20] = 102
	
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
	
	realw[52] = getreactorpower(fname)
	
	// beam stop X-position (motor reading, approximate cm from zero position)
	// currently NCNR-specific use to identify transmission measurements
	// you return 0
	realw[37] = 0
	
	
// the actual data array, dimensions are set as globals in 
// InitFacilityGlobals()
	NVAR XPix = root:myGlobals:gNPixelsX
	NVAR YPix = root:myGlobals:gNPixelsX
	
	SetDataFolder curPath
	
	Make/D/O/N=(XPix,YPix) $"root:RAW:data"
	WAVE data=$"root:RAW:data"

	// fill the data array with the detector values
	getDetectorData(fname,data)
	
	Setdatafolder curpath
	
	
	//keep a string with the filename in the RAW folder
	String/G root:RAW:fileList = textw[0]
	
	Setdatafolder root:

	
	Return 0

End

//****************
//main entry procedure for reading a "WORK.DIV" file
//displays a quick image of the  file, to check that it's correct
//data is deposited in root:DIV data folder
//
// local, just for testing
//
Proc ReadWork_DIV()
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:DIV:data"
	NewImage/F/K=1/S=2 $waveStr
	ModifyImage '' ctab= {*,*,YellowHot,0}
	
	String/G root:DIV:fileList = "WORK.DIV"
	
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
Function ReadHeaderAndWork1(type,fname)
	String type,fname
	
	//type is the desired folder to read the workfile to
	//this data will NOT be automatically displayed
	// gDataDisplayType is unchanged

	String cur_folder = type
	String curPath = "root:"+cur_folder
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
	
	
//	print "function used"
	

		// (1)
	// fill in your reader for the header here so that intw, realw, and textW are filled in
	// ? possibly a duplication of the raw data reader
	Duplicate/O $("root:raw:realsread"),$("curPath"+ ":realsread")
	Duplicate/O $("root:raw:integersread"),$("curPath"+ ":integersread")
	Duplicate/T $("root:raw:Textread"),$("curPath"+ ":Textread")
	

	//(2)
	// then fill in a reader for the data array that will DIVIDE your data
	// to get the corrected values.
	// fill the data array with the detector values

	duplicate/O $("root:raw:data"),$("curPath"+ ":data")
	
	
	//keep a string with the filename in the DIV folder
	String/G $(curPath + ":fileList") = textw[0]
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End


/////////DIV file created with NIST reduction so has the VAX format.... painful

Function ReadHeaderAndWork(type,fname)
	String type,fname
	
	//type is the desired folder to read the workfile to
	//this data will NOT be automatically displayed gDataDisplayType is unchanged

//	SVAR cur_folder=root:myGlobals:gDataDisplayType
	String cur_folder = type
	String curPath = "root:"+cur_folder
	SetDataFolder curPath		//use the full path, so it will always work
	
	Variable refNum,integer,realval
	String sansfname,textstr
	Variable/G $(curPath + ":gIsLogScale") = 0		//initial state is linear, keep this in DIV folder
	
	Make/O/N=23 $(curPath + ":IntegersRead")
	Make/O/N=52 $(curPath + ":RealsRead")
	Make/O/T/N=11 $(curPath + ":TextRead")
	
	WAVE intw=$(curPath + ":IntegersRead")
	WAVE realw=$(curPath + ":RealsRead")
	WAVE/T textw=$(curPath + ":TextRead")
	
	//***NOTE ****
	// the "current path" gets mysteriously reset to "root:" after the SECOND pass through
	// this read routine, after the open dialog is presented
	// the "--read" waves end up in the correct folder, but the data does not! Why?
	//must re-set data folder before writing data array (done below)
	
	SetDataFolder curPath
	
	//actually open the file
	Open/R refNum as fname
	//skip first two bytes
	FSetPos refNum, 2
	//read the next 21 bytes as characters (fname)
	FReadLine/N=21 refNum,textstr
	textw[0]= textstr
	//read four i*4 values	/F=3 flag, B=3 flag
	FBinRead/F=3/B=3 refNum, integer
	intw[0] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[1] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[2] = integer
	//
	FBinRead/F=3/B=3 refNum, integer
	intw[3] = integer
	// 6 text fields
	FSetPos refNum,55		//will start reading at byte 56
	FReadLine/N=20 refNum,textstr
	textw[1]= textstr
	FReadLine/N=3 refNum,textstr
	textw[2]= textstr
	FReadLine/N=11 refNum,textstr
	textw[3]= textstr
	FReadLine/N=1 refNum,textstr
	textw[4]= textstr
	FReadLine/N=8 refNum,textstr
	textw[5]= textstr
	FReadLine/N=60 refNum,textstr
	textw[6]= textstr
	
	//3 integers
	FSetPos refNum,174
	FBinRead/F=3/B=3 refNum, integer
	intw[4] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[5] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[6] = integer
	
	//2 integers, 3 text fields
	FSetPos refNum,194
	FBinRead/F=3/B=3 refNum, integer
	intw[7] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[8] = integer
	FReadLine/N=6 refNum,textstr
	textw[7]= textstr
	FReadLine/N=6 refNum,textstr
	textw[8]= textstr
	FReadLine/N=6 refNum,textstr
	textw[9]= textstr
	
	//2 integers
	FSetPos refNum,244
	FBinRead/F=3/B=3 refNum, integer
	intw[9] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[10] = integer
	
	//2 integers
	FSetPos refNum,308
	FBinRead/F=3/B=3 refNum, integer
	intw[11] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[12] = integer
	
	//2 integers
	FSetPos refNum,332
	FBinRead/F=3/B=3 refNum, integer
	intw[13] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[14] = integer
	
	//3 integers
	FSetPos refNum,376
	FBinRead/F=3/B=3 refNum, integer
	intw[15] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[16] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[17] = integer
	
	//1 text field - the file association for transmission are the first 4 bytes
	FSetPos refNum,404
	FReadLine/N=42 refNum,textstr
	textw[10]= textstr
	
	//1 integer
	FSetPos refNum,458
	FBinRead/F=3/B=3 refNum, integer
	intw[18] = integer
	
	//4 integers
	FSetPos refNum,478
	FBinRead/F=3/B=3 refNum, integer
	intw[19] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[20] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[21] = integer
	FBinRead/F=3/B=3 refNum, integer
	intw[22] = integer
	
	Close refNum
	
	//now get all of the reals
	//
	//Do all the GBLoadWaves at the end
	//
	//FBinRead Cannot handle 32 bit VAX floating point
	//GBLoadWave, however, can properly read it
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	String strToExecute
	//append "/S=offset/U=numofreals" to control the read
	// then append fname to give the full file path
	// then execute
	
	Variable a=0,b=0
	
	SetDataFolder curPath
	// 4 R*4 values
	strToExecute = GBLoadStr + "/S=39/U=4" + "\"" + fname + "\""
	Execute strToExecute
	
	SetDataFolder curPath
	Wave w=$(curPath + ":tempGBWave0")
	b=4	//num of reals read
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 4 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=158/U=4" + "\"" + fname + "\""
	Execute strToExecute
	b=4	
	realw[a,a+b-1] = w[p-a]
	a+=b

///////////
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=186/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2	
	realw[a,a+b-1] = w[p-a]
	a+=b

	// 6 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=220/U=6" + "\"" + fname + "\""
	Execute strToExecute
	b=6	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 13 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=252/U=13" + "\"" + fname + "\""
	Execute strToExecute
	b=13
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 3 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=320/U=3" + "\"" + fname + "\""
	Execute strToExecute
	b=3	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 7 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=348/U=7" + "\"" + fname + "\""
	Execute strToExecute
	b=7
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 4 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=388/U=4" + "\"" + fname + "\""
	Execute strToExecute
	b=4	
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=450/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 2 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=470/U=2" + "\"" + fname + "\""
	Execute strToExecute
	b=2
	realw[a,a+b-1] = w[p-a]
	a+=b
	
	// 5 R*4 values
	SetDataFolder curPath
	strToExecute = GBLoadStr + "/S=494/U=5" + "\"" + fname + "\""
	Execute strToExecute
	b=5	
	realw[a,a+b-1] = w[p-a]
	
	//if the binary VAX data ws transferred to a MAC, all is OK
	//if the data was trasnferred to an Intel machine (IBM), all the real values must be
	//divided by 4 to get the correct floating point values
	// I can't find any combination of settings in GBLoadWave or FBinRead to read data in correctly
	// on an Intel machine.
	//With the corrected version of GBLoadWave XOP (v. 1.43 or higher) Mac and PC both read
	//VAX reals correctly, and no checking is necessary 12 APR 99
	//if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		//do nothing
	//else
		//either Windows or Windows NT
		//realw /= 4
	//endif
	
	//read in the data
	 GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"

	curPath = "root:"+cur_folder
	SetDataFolder curPath		//use the full path, so it will always work
	
	Make/O/N=16384 $(curPath + ":data")
	WAVE data = $(curPath + ":data")
	
	Variable skip,ii,offset
	
	//read in a total of 16384 values (ii) 
	//as follows :
	// skip first 2 bytes
	// skip 512 byte header
	// skip first 2 bytes of data
	//(read 511 reals, skip 2b, 510 reals, skip 2b) -16 times = 16336 values
	// read the final 48 values in seperately to avoid EOF error
	
	/////////////
	SetDataFolder curPath
	skip = 0
	ii=0
	offset = 514 +2
	a=0
	do
		SetDataFolder curPath
		
		strToExecute = GBLoadStr + "/S="+num2str(offset)+"/U=511" + "\"" + fname + "\""
		Execute strToExecute
		//Print strToExecute
		b=511
		data[a,a+b-1] = w[p-a]
		a+=b
		
		offset += 511*4 +2
		
		strToExecute = GBLoadStr + "/S="+num2str(offset)+"/U=510" + "\"" + fname + "\""
		SetDataFolder curPath
		Execute strToExecute
		//Print strToExecute
		b=510
		data[a,a+b-1] = w[p-a]
		a+=b
		
		offset += 510*4 +2
		
		ii+=1
		//Print "inside do, data[2] =",data[2]
		//Print "inside do, tempGBwave0[0] = ",w[0]
	while(ii<16)
	
	// 16336 values have been read in --
	//read in last 64 values
	strToExecute = GBLoadStr + "/S="+num2str(offset)+"/U=48" + "\"" + fname + "\""
	
	SetDataFolder curPath
	Execute strToExecute
	b=48
	data[a,a+b-1] = w[p-a]
	a+=b
//
/// done reading in raw data
//
	//Print "in workdatareader , data = ", data[1][1]

	Redimension/n=(128,128) data
	
	//clean up - get rid of w = $"tempGBWave0"
	KillWaves w
	
	//divide the FP data by 4 if read from a PC (not since GBLoadWave update)
	//if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		//do nothing
	//else
		//either Windows or Windows NT
		//data /= 4
	//endif
	
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
	SetDataFolder "root:"+destPath

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable refNum=0,ii,p1,p2,tot,num=pixelsX,numHdrLines=220   ///waas 20 for NIST
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

//loadwave  /A=tempGBwave/L={0, start, numrow, 0, numcol}/N/G/D/O/E=1/K=1


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
	Make/O/N=23 $("root:"+destFolder+":IntegersRead")
	Make/O/N=52 $("root:"+destFolder+":RealsRead")
	Make/O/T/N=11 $("root:"+destFolder+":TextRead")
	
	Wave intw=$("root:"+destFolder+":IntegersRead")
	Wave realw=$("root:"+destFolder+":RealsRead")
	Wave/T textw=$("root:"+destFolder+":TextRead")
	
	//Put in appropriate "fake" values
	//parse values as needed from headerLines
	Wave/T hdr=$("root:"+destFolder+":hdrLines")
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
	String/G $("root:"+destFolder+":fileList") = tempStr
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

//sample transmission (0<T<=1)
Function WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	// your writer here
	
	WriteReal(fname,trans,5589)     //I will define at position 10 lines position 1  by myself
	
	// 16 bites between numbers and 81 per line
	
	return(0)
End

//whole transmission is NCNR-specific right now
// leave this stub empty
Function WriteWholeTransToHeader(fname,trans)
	String fname
	Variable trans
	
	// do nothing for now
	WriteReal(fname,trans,6885)   /// //I will define at position last  lines  position 1  by myself
	
	return(0)
End

//box sum counts is a real value
// used for transmission calculation module
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts
	
	// do nothing if not using NCNR Transmission module
	
	WriteReal(fname,counts,6868)
	
	////I will define at position 2   lines before the end and  last position   by myself
	
	
	return(0)
End

//beam stop X-position
// used for transmission module to manually tag transmission files
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos
	
	// do nothing if not using NCNR Transmission module
	
	WriteReal(fname,xpos,5119)    ////should do it for ypos for ILL ....NEED TO REMEMBER HERE
	/// line 4 column 2    
	
	return(0)
End

//sample thickness in cm
Function WriteThicknessToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	WriteReal(fname,num,5508)  //define at 9 lines  column 1 just above transmission by myself
	
	return(0)
End

//beam center X pixel location (detector coordinates)
Function WriteBeamCenterXToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	// pos (1) on line 71 => 70 lines x 81 char
	WriteReal(fname,num*10,5670) 
	
	///   line 11 column 1
	
	return(0)
End

//beam center Y pixel location (detector coordinates)
Function WriteBeamCenterYToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	WriteReal(fname,num*10,5686)
	
	///   line 11 column 2
	
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
	WriteReal(fname,num,5799)
	
	///   line 12 column 4
	
	return(0)
End


Function WritereactorpowerToHeader(fname,num)
	String fname
	Variable num
	
	// your code here, default of 1
	WriteReal(fname,num,6204)
	
	///   line 12 column 4
	
	return(0)
End








// total monitor count during data collection
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	WriteReal(fname,num,4924)
	
	///   line 1 column 5
	
	return(0)
End

//total detector count
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	WriteReal(fname,num,4908)
	
	///   line 1 column 4
	
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
	WriteReal(fname,num,5703)
	
	//   line 11 column 3
	
	return(0)
End

//wavelength spread (FWHM)
Function WriteWavelengthDistrToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	
	WriteReal(fname,num,5719)
	
	//   line 11 column 4
	
	return(0)
End

//temperature of the sample (C)
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num
	
	//  your code here
	
	WriteReal(fname,num,5347)
	
	//   line 7 column 1
	
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
//	WriteReal(fname,num,5348)
      WriteReal(fname,num,6027)    ///4*81 = 324
      
      // line 15 colum 3
	
	return(0)
End

//Sample Aperture diameter (millimeters)
Function WriteSampleApDiamToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	WriteReal(fname,num,6043)
	
	    // line 15 colum 4
	
	return(0)
End

//Source aperture to sample aperture distance (meters)
Function WriteSrcToSamDistToHeader(fname,num)
	String fname
	Variable num
	
	//	your code here
	WriteReal(fname,num,5784)  //it is collimation at ILL
	
	
	return(0)
End

//lateral detector offset (centimeters)
Function WriteDetectorOffsetToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	
	WriteReal(fname,10*num,5849)
	
	
	
	// line 13 column 2
	
	return(0)
End

//beam stop diameter (millimeters)
Function WriteBeamStopDiamToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
	WriteReal(fname,num,6059)
	
	//line 15 column 5
	
	return(0)
End

//sample to detector distance (meters)
Function WriteSDDToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	WriteReal(fname,num,5152)
	
	// line 4 column 4
	
	return(0)
End

// physical dimension of detector x-pixel (mm)
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	WriteReal(fname,num,5735)
	
	//  line 11 column 5   
	
	return(0)
end

// physical dimension of detector y-pixel (mm)
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	//your code here
	WriteReal(fname,num,5752)
	
	return(0)
end

// sample label string
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	// your code here
//           	WriteText(fname,"                              ",2075)  // need to write in 30 bites no more....

	Variable numChars=30
	String blankStr=""
	blankStr = PadString(blankStr, numChars, 0x20)
	WriteText(fname,blankStr,2075)
	
	if(strlen(str)>numChars)
		str = str[0,numchars-1]
	endif
	
	WriteText(fname,str,2075)   //// need to change that in order to erase the title and write a new one

	return(0)
End

// total counting time (stored here as seconds/10??)
Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	// your code here
//	WriteReal(fname,num,4894)
	WriteReal(fname,10*num,4892)
	
	
	
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
	
//	value = getRealValueFromHeader_2(fname,60,28,5,1,3)  // data start at 60+58 lines 
	ReadILLData2(fname,data)
	
	return (0)
End

// file suffix (NCNR data file name specific)
// return null string
Function/S getSuffix(fname)
	String fname
	
	String suffix = getStringFromHeader(fname,9341,6)
	
	// replace the leading space w/ "0"
	suffix = ReplaceString(" ",suffix,"0")
	
	return(suffix)   //// file suffix (6 characters @ byte 9341)
End

// associated file suffix (for transmission)
// NCNR Transmission calculation specific
// return null string
Function/S getAssociatedFileSuffix(fname)
	String fname
	
	string str
	
	str= getStringFromHeader(fname,9350,6)
	
	// replace leading space(s) w/zero
	str = ReplaceString(" ", str, "0" )
//	print  str
	
	return(str)  //  6 characters @ byte 9350
End

// sample label
Function/S getSampleLabel(fname)
	String fname
	
	String str
	
	// your code, returning str
	str = (getStringFromHeader(fname,2075,30))  /// 25*81  +  50////+51 30 lines before the end
	
	
	return(str)
End

// file creation date
Function/S getFileCreationDate(fname)
	String fname
	
	String str
	
	// your code, returning str
	
	str = (getStringFromHeader(fname,2106,50))   //324 +12
	
	return(str)
End


Function/S getFileInstrument(fname)
	String fname
	
	String str
	
	// your code, returning str
	
	str = (getStringFromHeader(fname,324,3))   //324 +12
	
	return(str)
End


//reactor power
Function getReactorpower(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,1,5)  //
	
	value = getRealValueFromHeader(fname,83)
	
//	print value
	
	return(value)
end





//monitor count
Function getMonitorCount(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,1,5)  //
	
	value = getRealValueFromHeader(fname,4)
	
//	print value
	
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
	
//	value = getRealValueFromHeader_2(fname,60,28,5,1,4) 
	
	value = getRealValueFromHeader(fname,3)
	
	return(value)
end

//Attenuator number, return 1 if your attenuators are not
// indexed by number
Function getAttenNumber(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,56,4) 
	
	value = getRealValueFromHeader(fname,58)
	
	return(value)
end

//transmission
Function getSampleTrans(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	value = getRealValueFromHeader(fname,45)
	
	return(value)
end

//box counts from stored transmission calculation
// return 0 if not using NCNR transmission module
Function getBoxCounts(fname)
	String fname
	
	Variable value
	
	// your code returning value
	value = getRealValueFromHeader(fname,124)
	
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
	value = getRealValueFromHeader(fname,40)  //mm
	
	return(value)
end

//Sample Rotation Angle (degrees)
Function getSampleRotationAngle(fname)
	String fname
	
	Variable value
	
	// your code returning value
	value = getRealValueFromHeader(fname,64)
	
	return(value)
end

//temperature (C)
Function getTemperature(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,7,1) 
	
	value = getRealValueFromHeader(fname,30)
	
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
//	value = getRealValueFromHeader(fname,14)		//Lionel
	value = getRealValueFromHeader(fname,50)/10		//SRK
	
	return(value)
end

//center of beam Y pos in pixel coordinates
Function getBeamYPos(fname)
	String fname
	
	Variable value
	
	// your code returning value
//	value = getRealValueFromHeader(fname,15)		//Lionel
	value = getRealValueFromHeader(fname,51)/10		//SRK
	
	return(value)
end

//sample to detector distance (meters)
Function getSDD(fname)
	String fname
	
	Variable value
	
	// your code returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,4,4) 
	value = getRealValueFromHeader(fname,18)
	
	return(value)
end

//lateral detector offset (centimeters)
Function getDetectorOffset(fname)
	String fname
	
	Variable value
	
	// your code returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,13,2)
	value = getRealValueFromHeader(fname,61) 
	
	return(value/10)  // need in cm ILL write in mm
end

//Beamstop diameter (millimeters)
Function getBSDiameter(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,15,5) 
	value = getRealValueFromHeader(fname,74)
	
	return(value)
end

//source aperture diameter (millimeters)
Function getSourceApertureDiam(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
	value  = 52
	
	return(value)
end

//sample aperture diameter (millimeters)
Function getSampleApertureDiam(fname)
	String fname
	
	Variable value
	
	// your code returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,15,3) 
	value = getRealValueFromHeader(fname,72)
	
	value = 10
	
	return(value)
end

//source AP to Sample AP distance (meters)
Function getSourceToSampleDist(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,12,3) 
	
	value = getRealValueFromHeader(fname,57)
	
	return(value)
end

//wavelength (Angstroms)
Function getWavelength(fname)
	String fname
	
	Variable value
	
	// your code returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,11,3) 
	value = getRealValueFromHeader(fname,52)
	
	return(value)
end

//wavelength spread (FWHM)
Function getWavelengthSpread(fname)
	String fname
	
	Variable value
	
	// your code returning value
	value = getRealValueFromHeader(fname,53)

	
	return(value)
end

// physical x-dimension of a detector pixel, in mm
Function getDetectorPixelXSize(fname)
	String fname
	
	Variable value
	
	// your code here returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,11,5) 
	value = getRealValueFromHeader(fname,54)
	
	return(value)
end

// physical y-dimension of a detector pixel, in mm
Function getDetectorPixelYSize(fname)
	String fname
	
	Variable value
	
	// your code here returning value
//	value = getRealValueFromHeader_2(fname,60,28,5,12,1) 
	value = getRealValueFromHeader(fname,55)
	
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
// stored here as (s/10), so multiply by 10 ?
Function getCountTime(fname)
	String fname
	
	Variable value
	
	// your code returning value
	
//	value = getRealValueFromHeader_2(fname,60,28,5,1,3)  ///  line 1 col 3
	
	value = getRealValueFromHeader(fname,2)/10
	
	return(value)
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
//
// filename is the full path:name to the file
Function getXYBoxFromFile(filename,x1,x2,y1,y2)
	String filename
	Variable &x1,&x2,&y1,&y2

	// return your bounding box coordinates or default values of 0
	x1=getRealValueFromHeader(filename,120)
	x2=getRealValueFromHeader(filename,121)
	y1=getRealValueFromHeader(filename,122)
	y2=getRealValueFromHeader(filename,123)
	
//	print "in get", x1,x2,y1,y2
	
	return(0)
End

// Writes the coordinates of the box to the header after user input
//
// box to sum over bounded (x1,y1) to (x2,y2)
//
// if not using the NCNR Transmission module, this function is null
//
// filename as passed in is a full path:filename
//
Function WriteXYBoxToHeader(filename,x1,x2,y1,y2)
	String filename
	Variable x1,x2,y1,y2
	
	// your code to write bounding box to the header, or nothing
	
	WriteReal(filename,x1,6804)
	WriteReal(filename,x2,6820)
	WriteReal(filename,y1,6836)
	WriteReal(filename,y2,6852)
	
	// use the last full line and the 4 first numbers
	
//	print "in write",x1,x2,y1,y2
	
	//  should start at 120  for read and  line 25
	
	/// 84 *81
	
	return(0)
End

// for transmission calculation, writes an NCNR-specific alphanumeric identifier
// (suffix of the data file)
//
// if not using the NCNR Transmission module, this function is null
Function WriteAssocFileSuffixToHeader(fname,suffix)
	String fname,suffix
		
	// replace leading space(s) w/zero
	suffix = ReplaceString(" ", suffix, "0" )
		
	suffix = suffix[0,5]		//limit to 6 characters
	
	WriteText(fname,suffix,9350)
	
	
	return(0)
end

Function/S getStringFromHeader(fname,start,num)
	String fname				//full path:name
	Variable start,num		//starting byte and number of characters to read
	
	String str
	Variable refnum
	Open/R refNum as fname
	FSetPos refNum,start
	FReadLine/N=(num) refNum,str
	Close refnum
	
	return(str)
End

Function getRealValueFromHeader(fname,start)
	String fname
	Variable start
	Variable numLinesLoaded = 0,firstchar,countTime
	variable refnum
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v0,ii,valuesread,result
	String buffer 
	Make/O/D/N=128 TemporaryHeader
//	Make/O/D/N=(128) data

	Open/R refNum as fname		//if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif

//skip the next 10 lines
	For(ii=0;ii<60;ii+=1)
		FReadLine refnum,buffer
	EndFor

// read in the whole header
	For (ii=60;ii<188;ii+=1)

		numlinesloaded = ii-60
		FReadLine refNum,buffer	//assume a 2nd line is there, w/16 values
		sscanf buffer,"%g %g %g %g %g ",v0,v1,v2,v3,v4
		valuesRead = V_flag
//		print valuesRead
		
//		print buffer
		
		//valuesRead = V_flag
//		print ii,refnum,v0,v1,v2,v3,v4,v5,v6,v7,v8,v9
//		print buffer
		
		TemporaryHeader[5*numlinesloaded] = v0
		TemporaryHeader[5*numlinesloaded+1] = v1		//monitor
		TemporaryHeader[5*numlinesloaded+2] = v2
		TemporaryHeader[5*numlinesloaded+3] = v3
		TemporaryHeader[5*numlinesloaded+4] = v4
	Endfor
						
	Close refNum		
	result= TemporaryHeader[start]
//	KillWaves/Z TemporaryHeader
	
	return (result)
End

//Function getRealValueFromHeader_1(fname,start)
//	String fname
//	Variable start
//
//	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=1/W=1/Q"
//	
//	GBLoadStr += "/S="+num2str(start)+"/U=10" + "\"" + fname + "\""
//	Execute GBLoadStr
//	Wave w=$"tempGBWave0"
//	
//	return(w[0])
//End

//Function getRealValueFromHeader_2(fname,start,numrow,numcol,rowbit,colbit)
//	String fname
//	Variable start,numcol,numrow,colbit,rowbit
//	variable result
//	make /O/D/N=(numrow) w0,w1,w2,w3,w4
//	Make/O/D/N=(numrow,numcol) dataread
//	
//		
//	loadwave  /A=tempGBwave/L={0, start, numrow, 0, numcol}/N/G/D/O/K=1 fname
//	
//	Wave/Z tempGBwave0=tempGBwave0
//	Wave/Z tempGBwave1=tempGBwave1
//	Wave/Z tempGBwave2=tempGBwave2
//	Wave/Z tempGBwave3=tempGBwave3
//	Wave/Z tempGBwave4=tempGBwave4
//	
//	
//	w0=tempGBWave0
//	 w1=tempGBWave1
//	 w2=tempGBWave2
//	 w3=tempGBWave3
//	 w4=tempGBWave4
//	
/////           	redimension could use that to redimension dataread in only one colunm... but will see later..
//
//
//
//	KillWaves/Z tempGBwave0,tempGBwave1,tempGBwave3,tempGBwave2,tempGBwave4
//	///        Make/O/D/N=(numrow,numcol),wres
//	
//	dataread[][0] = w0[p]
//	dataread[][1] = w1[p]
//	dataread[][2] = w2[p]
//	dataread[][3] = w3[p]
//	dataread[][4] = w4[p]
//
//KillWaves/Z w0,w1,w2,w3,w4
//	
////	wave wres = $"tempGBwave"  +num2str(linebit-1)
//	result  = dataread[rowbit-1][colbit-1]
//	
//	return(result)
//End


//Function ReadILLData(fname)
//	String fname
//	
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
//	Variable refNum=0,ii,p1,p2,tot,num=pixelsX,numHdrLines=118   ///waas 20 for NIST
//	String str=""
//	//data is initially linear scale
//	Variable/G :gIsLogScale=0
//	Make/O/T/N=(numHdrLines) hdrLines
//	Make/O/D/N=(pixelsX*pixelsY) data	
//	Make/O/D/N=(1638,10)	datahelp	//,linear_data
//	
//	//full filename and path is now passed in...
//	//actually open the file
////	SetDataFolder destPath
//	Open/R/Z refNum as fname		// /Z flag means I must handle open errors
//	if(refnum==0)		//FNF error, get out
//		DoAlert 0,"Could not find file: "+fname
//		Close/A
//		SetDataFolder root:
//		return(1)
//	endif
//	if(V_flag!=0)
//		DoAlert 0,"File open error: V_flag="+num2Str(V_Flag)
//		Close/A
//		SetDataFolder root:
//		return(1)
//	Endif
//	// 
//	for(ii=0;ii<numHdrLines;ii+=1)		//read (or skip) 18 header lines
//		FReadLine refnum,str
//		hdrLines[ii]=str
//	endfor
//	//	
//	Close refnum
//	
////	SetDataFolder destPath
//
//// loadwave  /A=tempt/L={0, 118, 1638, 1, 10}/N/J/D/O/E=1/K=1 fname
//
//loadwave  /A=tempt/L={0, 0, 1638, 0, 10}/N/G/D/O/E=1/K=1 fname
//
//Wave/Z tempt0=tempt0
//	Wave/Z tempt1=tempt1
//	Wave/Z tempt2=tempt2
//	Wave/Z tempt3=tempt3
//	Wave/Z tempt4=tempt4
//	Wave/Z tempt5=tempt5
//	Wave/Z tempt6=tempt6
//	Wave/Z tempt7=tempt7
//	Wave/Z tempt8=tempt8
//	Wave/Z tempt9=tempt9
//	
//	
//	
//	
//	datahelp[][0]=tempt0[p]
//	datahelp[][1]=tempt1[p]
//	datahelp[][2]=tempt2[p]
//	datahelp[][3]=tempt3[p]
//	datahelp[][4]=tempt4[p]
//	datahelp[][5]=tempt5[p]
//	datahelp[][6]=tempt6[p]
//	datahelp[][7]=tempt7[p]
//	datahelp[][8]=tempt8[p]
//	datahelp[][9]=tempt9[p]
//	
//	Killwaves/Z tempt1,tempt2,tempt3,tempt4,tempt0,tempt5,tempt6,tempt7,tempt8,tempt9
//
/////////////Wave/Z tempt0=tempt0
/////data=tempt
//	
//	
//	Redimension/N=(pixelsX,pixelsY) datahelp
//
//
////	LoadWave/Q/J/D/E=1/V={" " ,"non",1,1}/N=temp fName 
////	Wave/Z temp0=temp0
////	data=temp0
////	Redimension/N=(pixelsX,pixelsY) data		//,linear_data
//	
//	//linear_data = data
//	
//	KillWaves/Z temp0 
//	
//	//return the data folder to root
//	SetDataFolder root:
//	
//	Return(0)
//End



Function ReadILLData2(fname,data)
	String fname
	wave data

	Variable numLinesLoaded = 0,firstchar,countTime
	variable refnum
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v0,ii,valuesread
	String buffer 
	Make/O/D/N=16384 Dataline		//temporary storage

	Open/R refNum as fname		//if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif

//skip the next 10 lines
	For(ii=0;ii<118;ii+=1)
		FReadLine refnum,buffer
	EndFor

	For (ii=118;ii<1757;ii+=1)
		numlinesloaded = ii-118
		FReadLine refNum,buffer	//assume a 2nd line is there, w/16 values
		sscanf buffer,"%g %g %g %g %g %g %g %g %g %g",v0,v1,v2,v3,v4,v5,v6,v7,v8,v9
		valuesRead = V_flag
//		print valuesRead		
//		 buffer		
		//valuesRead = V_flag
//		print ii,refnum,v0,v1,v2,v3,v4,v5,v6,v7,v8,v9
//		print buffer
		
		if(ii == 1756)
			dataline[10*numlinesloaded] = v0				//last line has only four values
			dataline[10*numlinesloaded+1] = v1
			dataline[10*numlinesloaded+2] = v2
			dataline[10*numlinesloaded+3] = v3
		else
			dataline[10*numlinesloaded] = v0		//reading in 10 values per line
			dataline[10*numlinesloaded+1] = v1
			dataline[10*numlinesloaded+2] = v2
			dataline[10*numlinesloaded+3] = v3
			dataline[10*numlinesloaded+4] = v4
			dataline[10*numlinesloaded+5] = v5
			dataline[10*numlinesloaded+6] = v6
			dataline[10*numlinesloaded+7] = v7
			dataline[10*numlinesloaded+8] = v8
			dataline[10*numlinesloaded+9] = v9
		endif
	Endfor
						
	Close refNum	
	
	data = dataline
	redimension /N=(128,128) data
	
//	Killwaves/Z dataline
	
	return (0)

end

// Write* routines all must:
// (1) open file "fname". fname is a full file path and name to the file on disk
// (2) write the specified value to the header at the correct location in the file
// (3) close the file

//
// ILL header values are 16 characters: one space followed by 15 bytes of the value, in scientific notation (pos 2 is the sign, last 4 are "e(+-)XX" )
// SRK - May 2008
Function WriteReal(path,value,start)
	string path
	variable value,start

	variable refnum
	
	String valStr
	sprintf valStr, "  %14e",value
//	print valstr, strlen(valStr)
	
	Open/A/T= "????" refnum as path
	
	FStatus refnum
	FSetPos refnum, start	
	FBinWrite refNum, valStr	
	FSetpos refnum,V_logEOF		// correct length is 142317 total bytes
	
	Close refnum
	
	return (0)

end


Function/S PromptForPathtest(msgStr)
	String msgStr
	String fullPath
	Variable refnum
	
	//this just asks for the filename, doesn't open the file
	Open/D/R/T="????"/M=(msgStr) refNum
	fullPath = S_FileName		//fname is the full path
	//	Print refnum,fullPath
	
	//null string is returned in S_FileName if user cancelled, and is passed back to calling  function
	Return(fullPath)
End


/// !!!! Make sure the text string is the correct LENGTH before sending it here!!!
// SRK - May 2008
Function WriteText(path,str,start)
	string path,str
	variable start
	
	variable refnum
	
	Open/A/T= "????TEXT" refnum as path
	
	FStatus refnum
	FSetPos refnum, start
	FBinWrite/F=0 refnum, str      //native object format (character)
	FSetPos refnum,V_logEOF
	
	Close refnum
	
	return (0)

end
