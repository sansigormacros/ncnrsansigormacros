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
	//Print  "GetFileNameFromPath(filename) = " +  GetFileNameFromPathNoSemi(filename)
	ReadHeaderAndData(filename)	//this is the full Path+file

///***** done by a call to UpdateDisplayInformation()
//	//the calling macro must change the display type
//	String/G root:myGlobals:gDataDisplayType="RAW"		//displayed data type is raw
//	
//	//data is displayed here
//	fRawWindowHook()
	
	Return(0)
End


//function that does the guts of reading the binary data file
//fname is the full path:name;vers required to open the file
//VAX record markers are skipped as needed
//VAX data as read in is in compressed I*2 format, and is decompressed
//immediately after being read in. The final root:RAW:data wave is the real
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
Function ReadHeaderAndData(fname)
	String fname
	//this function is for reading in RAW data only, so it will always put data in RAW folder
	String curPath = "root:RAW"
	SetDataFolder curPath		//use the full path, so it will always work
	Variable/G root:RAW:gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	
	Variable refNum,integer,realval
	String sansfname,textstr
	
	Make/O/N=23 $"root:RAW:IntegersRead"
	Make/O/N=52 $"root:RAW:RealsRead"
	Make/O/T/N=11 $"root:RAW:TextRead"
	
	Wave intw=$"root:RAW:IntegersRead"
	Wave realw=$"root:RAW:RealsRead"
	Wave/T textw=$"root:RAW:TextRead"
	
	//***NOTE ****
	// the "current path" gets mysteriously reset to "root:" after the SECOND pass through
	// this read routine, after the open dialog is presented
	// the "--read" waves end up in the correct folder, but the data does not! Why?
	//must re-set data folder before writing data array (done below)
	
	//full filename and path is now passed in...
	//actually open the file
	Open/R refNum as fname
	//skip first two bytes (VAX record length markers, not needed here)
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
	Wave w=$"root:RAW:tempGBWave0"
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
	
	SetDataFolder curPath
	//read in the data
	strToExecute = "GBLoadWave/O/N=tempGBwave/B/T={16,2}/S=514/Q" + "\"" + fname + "\""
	Execute strToExecute

	SetDataFolder curPath		//use the full path, so it will always work
	
	Make/O/N=16384 $"root:RAW:data"
	WAVE data=$"root:RAW:data"
	SkipAndDecompressVAX(w,data)
	Redimension/N=(128,128) data			//NIST raw data is 128x128 - do not generalize
	
	//keep a string with the filename in the RAW folder
	String/G root:RAW:fileList = textw[0]
	
	//set the globals to the detector dimensions (pixels)
	Variable/G root:myGlobals:gNPixelsX=128		//default for Ordela data (also set in Initialize/NCNR_Utils.ipf)
	Variable/G root:myGlobals:gNPixelsY=128
//	if(cmpstr(textW[9],"ILL   ")==0)		//override if OLD Cerca data
//		Variable/G root:myGlobals:gNPixelsX=64
//		Variable/G root:myGlobals:gNPixelsY=64
//	endif
	
	//clean up - get rid of w = $"root:RAW:tempGBWave0"
	KillWaves/Z w
	
	//return the data folder to root
	SetDataFolder root:
	
	Return 0

End


//function to take the I*2 data that was read in, in VAX format
//where the integers are "normal", but there are 2-byte record markers
//sprinkled evenly through the data
//there are skipped, leaving 128x128=16384 data values
//the input array (in) is larger than 16384
//(out) is 128x128 data (single precision) as defined in ReadHeaderAndData()
//
// local function to post-process compressed VAX binary data
//
//
Function SkipAndDecompressVAX(in,out)
	Wave in,out
	
	Variable skip,ii

	ii=0
	skip=0
	do
		if(mod(ii+skip,1022)==0)
			skip+=1
		endif
		out[ii] = Decompress(in[ii+skip])
		ii+=1
	while(ii<16384)
	return(0)
End

//decompresses each I*2 data value to its real I*4 value
//using the decompression routine written by Jim Ryhne, many moons ago
//
// the compression routine (not shown here, contained in the VAX fortran RW_DATAFILE.FOR) maps I4 to I2 values.
// (back in the days where disk space *really* mattered). the I4toI2 function spit out:
// I4toI2 = I4								when I4 in [0,32767]
// I4toI2 = -777							when I4 in [2,767,000,...]
// I4toI2 mapped to -13277 to -32768 	otherwise
//
// the mapped values [-776,-1] and [-13276,-778] are not used.
// in this compression scheme, only 4 significant digits are retained (to allow room for the exponent)
// technically, the maximum value should be 2,768,499 since this maps to -32768. But this is of
// little consequence. If you have individual pixel values on the detector that are that large, you need
// to re-think your experiment.
//
// local function to post-process compressed VAX binary data
//
//
Function Decompress(val)
	Variable val

	Variable i4,npw,ipw,ib,nd

	ib=10
	nd=4
	ipw=ib^nd
	i4=val

	if (i4 <= -ipw) 
		npw=trunc(-i4/ipw)
		i4=mod(-i4,ipw)*(ib^npw)
		return i4
	else
		return i4
	endif
End

//****************
//main entry procedure for reading a "WORK.DIV" file
//displays a quick image of the  file, to check that it's correct
//data is deposited in root:DIV data folder
//
// local, currently unused
//
//
Proc ReadWork_DIV()
//	Silent 1
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:DIV:data"
	NewImage/F/K=1/S=2 $waveStr		//this is an experimental IGOR operation
	ModifyImage '' ctab= {*,*,YellowHot,0}
	//Display;AppendImage $waveStr
	
	//change the title string to WORK.DIV, rather than PLEXnnn_TST_asdfa garbage
	String/G root:DIV:fileList = "WORK.DIV"
	
	SetDataFolder root:		//(redundant)
//	Silent 0
End


//this function is the guts of reading a binary VAX file of real (4-byte) values
// (i.e. a WORK.aaa file) 
// work files have the same header structure as RAW SANS data, just with
//different data (real, rather than compressed integer data)
//
//************
//this routine incorrectly reads in several data values where the VAX record
//marker splits the 4-byte real (at alternating record markers)
//this error seems to not be severe, but shoud be corrected (at great pain)
//************
//
// called from ProtocolAsPanel.ipf
//
//
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

//function to read in the ASC output of SANS reduction
// currently the file has 20 header lines, followed by a single column
// of 16384 values, Data is written by row, starting with Y=1 and X=(1->128)
//
//returns 0 if read was ok
//returns 1 if there was an error
//
// called by WorkFileUtils.ipf
//
Function ReadASCData(fname,destPath)
	String fname, destPath
	//this function is for reading in ASCII data so put data in user-specified folder
	SetDataFolder "root:"+destPath

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


/////*****************
////unused testing procedure for writing a 4 byte floating point value in VAX format
//Proc TestReWriteReal()
//	String Path
//	Variable value,start
//	
//	GetFileAndPath()
//	Path = S_Path + S_filename
//	
//	value = 0.2222
//	start = 158		//trans starts at byte 159
//	ReWriteReal(path,value,start)
//	
//	SetDataFolder root:
//End

//function will re-write a real value (4bytes) to the header of a RAW data file
//to ensure re-readability, the real value must be written mimicking VAX binary format
//which is done in this function
//path is the full path:file;vers to the file
//value is the real value to write
//start is the position to move the file marker to, to begin writing
//--so start is actually the "end byte" of the previous value
//
// Igor cannot write VAX FP values - so to "fake it"
// (1) write IEEE FP, 4*desired value, little endian
// (2) read back as two 16-bit integers, big endian
// (3) write the two 16-bit integers, reversed, writing each as big endian
//
//this procedure takes care of all file open/close pairs needed
//
Function WriteVAXReal(path,value,start)
	String path
	Variable value,start
	
	//Print " in F(), path = " + path
	Variable refnum,int1,int2, value4

//////
	value4 = 4*value
	
	Open/A/T="????TEXT" refnum as path
	//write IEEE FP, 4*desired value
	FSetPos refnum,start
	FBinWrite/B=3/F=4 refnum,value4		//write out as little endian
	//move to the end of the file
	FStatus refnum
	FSetPos refnum,V_logEOF	
	Close refnum
	
///////
	Open/R refnum as path
	//read back as two 16-bit integers
	FSetPos refnum,start
	FBinRead/B=2/F=2 refnum,int1	//read as big-endian
	FBinRead/B=2/F=2 refnum,int2	
	//file was opened read-only, no need to move to the end of the file, just close it	
	Close refnum
	
///////
	Open/A/T="????TEXT" refnum as path
	//write the two 16-bit integers, reversed
	FSetPos refnum,start
	FBinWrite/B=2/F=2 refnum,int2	//re-write as big endian
	FBinWrite/B=2/F=2 refnum,int1
	//move to the end of the file
	FStatus refnum
	FSetPos refnum,V_logEOF
	Close refnum		//at this point, it is as the VAX would have written it. 
	
	Return(0)
End

//sample transmission is a real value at byte 158
Function WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans
	
	WriteVAXReal(fname,trans,158)		//transmission start byte is 158
	return(0)
End

//whole transmission is a real value at byte 392
Function WriteWholeTransToHeader(fname,trans)
	String fname
	Variable trans
	
	WriteVAXReal(fname,trans,392)		//transmission start byte is 392
	return(0)
End

//box sum counts is a real value at byte 494
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts
	
	WriteVAXReal(fname,counts,494)		// start byte is 494
	return(0)
End

//beam stop X-pos is at byte 368
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos
	
	WriteVAXReal(fname,xpos,368)
	return(0)
End

//sample thickness is at byte 162
Function WriteThicknessToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,162)
	return(0)
End

//beam center X pixel location is at byte 252
Function WriteBeamCenterXToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,252)
	return(0)
End

//beam center Y pixel location is at byte 256
Function WriteBeamCenterYToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,256)
	return(0)
End

//attenuator number (not its transmission) is at byte 51
Function WriteAttenNumberToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,51)
	return(0)
End

//monitor count is at byte 39
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,39)
	return(0)
End

//total detector count is at byte 47
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,47)
	return(0)
End

//transmission detector count is at byte 388
Function WriteTransDetCountToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,388)
	return(0)
End

//wavelength is at byte 292
Function WriteWavelengthToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,292)
	return(0)
End

//wavelength spread is at byte 296
Function WriteWavelengthDistrToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,296)
	return(0)
End

//temperature is at byte 186
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,186)
	return(0)
End

//magnetic field is at byte 190
Function WriteMagnFieldToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,190)
	return(0)
End

//Source Aperture diameter is at byte 280
Function WriteSourceApDiamToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,280)
	return(0)
End

//Sample Aperture diameter is at byte 284
Function WriteSampleApDiamToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,284)
	return(0)
End

//Source to sample distance is at byte 288
Function WriteSrcToSamDistToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,288)
	return(0)
End

//detector offset is at byte 264
Function WriteDetectorOffsetToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,264)
	return(0)
End

//beam stop diameter is at byte 272
Function WriteBeamStopDiamToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,272)
	return(0)
End

//sample to detector distance is at byte 260
Function WriteSDDToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,260)
	return(0)
End

//detector pixel X size (mm) is at byte 220
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,220)
	return(0)
End

//detector pixel Y size (mm) is at byte 232
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	WriteVAXReal(fname,num,232)
	return(0)
End

//rewrite a text field back to the header
// fname is the full path:name
// str is the CORRECT length - it will all be written - pad or trim before passing
// start is the start byte
Function WriteTextToHeader(fname,str,start)
	String fname,str
	Variable start
	
	Variable refnum
	Open/A/T="????TEXT" refnum as fname      //Open for writing! Move to EOF before closing!
	FSetPos refnum,start
	FBinWrite/F=0 refnum, str      //native object format (character)
	//move to the end of the file before closing
	FStatus refnum
	FSetPos refnum,V_logEOF
	Close refnum
		
	return(0)
end

// sample label, starts at byte 98
// limit to 60 characters
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	if(strlen(str) > 60)
		str = str[0,59]
	endif
	WriteTextToHeader(fname,str,98)
	return(0)
End

//rewrite an integer field back to the header
// fname is the full path:name
// val is the integer value
// start is the start byte
Function RewriteIntegerToHeader(fname,val,start)
	String fname
	Variable val,start
	
	Variable refnum
	Open/A/T="????TEXT" refnum as fname      //Open for writing! Move to EOF before closing!
	FSetPos refnum,31
	FBinWrite/B=3/F=3 refnum, val      //write a 4-byte integer
	//move to the end of the file before closing
	FStatus refnum
	FSetPos refnum,V_logEOF
	Close refnum
		
	return(0)
end

Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	RewriteIntegerToHeader(fname,num,31)
	return(0)
End

// read specific bits of information from the header
// each of these operations MUST take care of open/close on their own

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

// file suffix (4 characters @ byte 19)
Function/S getSuffix(fname)
	String fname
	
	return(getStringFromHeader(fname,19,4))
End

// associated file suffix (for transmission) (4 characters @ byte 404)
Function/S getAssociatedFileSuffix(fname)
	String fname
	
	return(getStringFromHeader(fname,404,4))
End

// sample label (60 characters @ byte 98)
Function/S getSampleLabel(fname)
	String fname
	
	return(getStringFromHeader(fname,98,60))
End

// file creation date (20 characters @ byte 55)
Function/S getFileCreationDate(fname)
	String fname
	
	return(getStringFromHeader(fname,55,20))
End

// read a single real value with GBLoadWave
Function getRealValueFromHeader(fname,start)
	String fname
	Variable start

	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	
	GBLoadStr += "/S="+num2str(start)+"/U=1" + "\"" + fname + "\""
	Execute GBLoadStr
	Wave w=$"tempGBWave0"
	
	return(w[0])
End

//monitor count is at byte 39
Function getMonitorCount(fname)
	String fname
	
	return(getRealValueFromHeader(fname,39))
end

//saved monitor count is at byte 43
Function getSavMon(fname)
	String fname
	
	return(getRealValueFromHeader(fname,43))
end

//detector count is at byte 47
Function getDetCount(fname)
	String fname
	
	return(getRealValueFromHeader(fname,47))
end

//Attenuator number is at byte 51
Function getAttenNumber(fname)
	String fname
	
	return(getRealValueFromHeader(fname,51))
end

//transmission is at byte 158
Function getSampleTrans(fname)
	String fname
	
	return(getRealValueFromHeader(fname,158))
end

//box counts are stored at byte 494
Function getBoxCounts(fname)
	String fname
	
	return(getRealValueFromHeader(fname,494))
end

//whole detector trasmission is at byte 392
Function getSampleTransWholeDetector(fname)
	String fname
	
	return(getRealValueFromHeader(fname,392))
end

//SampleThickness is at byte 162
Function getSampleThickness(fname)
	String fname
	
	return(getRealValueFromHeader(fname,162))
end

//Sample Rotation Angle is at byte 170
Function getSampleRotationAngle(fname)
	String fname
	
	return(getRealValueFromHeader(fname,170))
end

//temperature is at byte 186
Function getTemperature(fname)
	String fname
	
	return(getRealValueFromHeader(fname,186))
end

//field strength is at byte 190
// 190 is not the right location, 348 looks to be correct for the electromagnets, 450 for the 
// superconducting magnet. Although each place is only the voltage, it is correct
Function getFieldStrength(fname)
	String fname
	
//	return(getRealValueFromHeader(fname,190))
	return(getRealValueFromHeader(fname,348))
end

//beam xPos is at byte 252
Function getBeamXPos(fname)
	String fname
	
	return(getRealValueFromHeader(fname,252))
end

//beam Y pos is at byte 256
Function getBeamYPos(fname)
	String fname
	
	return(getRealValueFromHeader(fname,256))
end

//sample to detector distance is at byte 260
Function getSDD(fname)
	String fname
	
	return(getRealValueFromHeader(fname,260))
end

//detector offset is at byte 264
Function getDetectorOffset(fname)
	String fname
	
	return(getRealValueFromHeader(fname,264))
end

//Beamstop diameter is at byte 272
Function getBSDiameter(fname)
	String fname
	
	return(getRealValueFromHeader(fname,272))
end

//source aperture diameter is at byte 280
Function getSourceApertureDiam(fname)
	String fname
	
	return(getRealValueFromHeader(fname,280))
end

//sample aperture diameter is at byte 284
Function getSampleApertureDiam(fname)
	String fname
	
	return(getRealValueFromHeader(fname,284))
end

//source AP to Sample AP distance is at byte 288
Function getSourceToSampleDist(fname)
	String fname
	
	return(getRealValueFromHeader(fname,288))
end

//wavelength is at byte 292
Function getWavelength(fname)
	String fname
	
	return(getRealValueFromHeader(fname,292))
end

//wavelength spread is at byte 296
Function getWavelengthSpread(fname)
	String fname
	
	return(getRealValueFromHeader(fname,296))
end

//transmission detector count is at byte 388
Function getTransDetectorCounts(fname)
	String fname
	
	return(getRealValueFromHeader(fname,388))
end

//detector pixel X size is at byte 220
Function getDetectorPixelXSize(fname)
	String fname
	
	return(getRealValueFromHeader(fname,220))
end

//detector pixel Y size is at byte 232
Function getDetectorPixelYSize(fname)
	String fname
	
	return(getRealValueFromHeader(fname,232))
end

// stub for ILL - power is written to their header, not ours
Function getReactorPower(fname)
	String fname

	return 0

end

//////  integer values

Function getIntegerFromHeader(fname,start)
	String fname				//full path:name
	Variable start		//starting byte
	
	Variable refnum,val
	Open/R refNum as fname
	FSetPos refNum,start
	FBinRead/B=3/F=3 refnum,val
	Close refnum
	
	return(val)
End

//total count time is at byte 31	
Function getCountTime(fname)
	String fname
	return(getIntegerFromHeader(fname,31))
end


//reads the wavelength from a reduced data file (not very reliable)
// - does not work with NSORTed files
// - only used in FIT/RPA (which itself is almost NEVER used...)
//
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
// filename is the full path:name 
Function getXYBoxFromFile(filename,x1,x2,y1,y2)
	String filename
	Variable &x1,&x2,&y1,&y2
	
	Variable refnum
//	String tmpFile = FindValidFilename(filename)
		
//	Open/R/P=catPathName refnum as tmpFile
	Open/R refnum as filename
	FSetPos refnum,478
	FBinRead/F=3/B=3 refnum, x1
	FBinRead/F=3/B=3 refnum, x2
	FBinRead/F=3/B=3 refnum, y1
	FBinRead/F=3/B=3 refnum, y2
	Close refnum
	
	return(0)
End

//go find the file, open it and write 4 integers to the file
//in the positions for analysis.rows(2), .cols(2) = 4 unused 4byte integers
Function WriteXYBoxToHeader(filename,x1,x2,y1,y2)
	String filename
	Variable x1,x2,y1,y2
	
	Variable refnum
	Open/A/T="????TEXT" refnum as filename
	FSetPos refnum,478
	FBinWrite/F=3/B=3 refNum, x1
	FBinWrite/F=3/B=3 refNum, x2
	FBinWrite/F=3/B=3 refNum, y1
	FBinWrite/F=3/B=3 refNum, y2
	//move to the end of the file before closing
	FStatus refnum
	FSetPos refnum,V_logEOF
	Close refnum
	
	return(0)
End

//associated file suffix is the first 4 characters of a text field starting
// at byte 404
// suffix must be four characters long, if not, it's truncated
//
Function WriteAssocFileSuffixToHeader(fname,suffix)
	String fname,suffix
		
	suffix = suffix[0,3]		//limit to 4 characters
	WriteTextToHeader(fname,suffix,404)
	
	return(0)
end


// Jan 2008
// it has been determined that the true pixel dimension of the ordela detectors is not 5.0 mm
// but somewhat larger (5.08? mm). "new" data files will be written out with the proper size
// and old files will be patched batchwise to put the prpoer value in the header

Proc PatchDetectorPixelSize(firstFile,lastFile,XSize,YSize)
	Variable firstFile=1,lastFile=100,XSize=5.08,YSize=5.08

	fPatchDetectorPixelSize(firstFile,lastFile,XSize,YSize)

End

Proc ReadDetectorPixelSize(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadDetectorPixelSize(firstFile,lastFile)
End

// simple utility to patch the detector pixel size in the file headers
// pass in the dimensions in mm
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchDetectorPixelSize(lo,hi,xdim,ydim)
	Variable lo,hi,xdim,ydim
	
	Variable ii
	String file
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			WriteDetPixelXToHeader(file,xdim)
			WriteDetPixelyToHeader(file,ydim)
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the pixel size stored in the file header
Function fReadDetectorPixelSize(lo,hi)
	Variable lo,hi
	
	String file
	Variable xdim,ydim,ii
	
	for(ii=lo;ii<=hi;ii+=1)
		file = FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			xdim = getDetectorPixelXSize(file)
			ydim = getDetectorPixelYSize(file)
			printf "File %d:  Pixel dimensions (mm): X = %g\t Y = %g\r",ii,xdim,ydim
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End



//*******************
//************
// simple command - line utilities to convert/unconvert the header value
// that flags files as using lenses
//
// stored in reals[28], header byte start @ 300
//
// currently, two values (0 | 1) = (no lens | yes lens)
// ideally, this field will have the actual number of lenses inserted.
//
// this is used in getResolution (reads the reals[]) and switches the calculation
//************

Proc ConvertToLens(RunNumber)
	Variable RunNumber
	HeaderToLensResolution(RunNumber) 
End

Proc ConvertToPinhole(RunNumber)
	Variable RunNumber
	HeaderToPinholeResolution(RunNumber)
End

// sets the flag to zero in the file (= 0)
Function HeaderToPinholeResolution(num) 
	Variable num	
	
	//Print "UnConvert"
	String fullname=""
	
	fullname = FindFileFromRunNumber(num)
	Print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "HeaderToPinhole - file not found"
	else
		//Print "Unconvert",fullname
		WriteVAXReal(fullname,0,300)
	Endif
	return(0)
End

// sets the flag to one in the file (= 1)
Function HeaderToLensResolution(num) 
	Variable num	
	
	//Print "UnConvert"
	String fullname=""
	
	fullname = FindFileFromRunNumber(num)
	Print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "HeaderToPinhole - file not found"
	else
		//Print "Unconvert",fullname
		WriteVAXReal(fullname,1,300)
	Endif
	return(0)
End