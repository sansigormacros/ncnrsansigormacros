#pragma rtGlobals=1		// Use modern global access method.
#pragma version=6.0
#pragma IgorVersion=8.0

//
// JULY 2021 -- TODO - replace the functions in this file---
//								or move to the new version
//
//
// all that is left in this file is some odd utility functions that 
// may or may not be useful to patch (batchwise) bits of the raw data file
// headers.

//
// There are some old VAX-file R/W routines that have no value
// within the new nexus format, and need to be REPLACED with the correct get, put, or write
// functions in the files:
// 	NCNR_HDF5_Read.ipf
// 	NCNR_HDF5_Write.ipf
//		NCNR_DataReadWriteUtils_N.ipf
//
//
// I have strayed from the clean split of functions that are "facility-specific"
// and made a lot of NCNR-specific changes and they are now sprinkled throughout 
// the code. Efforts to open the code to other facilities has long since fallen
// by the wayside...
//
//


//**************************
//
// Vers. 1.2 092101
// Vers. 5.0 29MAR07 - branched from main reduction to split out facility
//                     specific calls
//
////////////////////////////
// Vers. 6.0 JULY 2014 - first attempt to use HDF5 as the raw file format
//
// -- NOTE - the file format has NOT BEEN DEFINED! I am simply converting the VAX file to 
// an HDF5 file. I'm using Pete Jemain's HDF5Gateway, with some modifications.
//
// -- following the ANSTO code, read everything into a tree of folders
//  then each "get" first looks for the local copy, and reads the necessary value from there
//  - if the file has not been loaded, then load it, and read the value (or read it directly?)
//
////////////////////////////
//
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


///// Data in HDF 5 format should NOT be compressed
// TODO -- 
// -- This function is still used in the RealTime reader, which is still looking
//    for VAX files. It has its own special reader, and may never be used with NICE, so
//    commenting it all out may be the final result.
//


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
	SetDataFolder "root:Packages:NIST:"+destPath

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable pixelsX = getDet_pixel_num_x(destPath)
	Variable pixelsY = getDet_pixel_num_y(destPath)
	
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
	
	Duplicate/O data linear_data
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
//
// SRK JUL 2021 -- for now, leave this as-is with the RealsRead references
//
// I will likely need to replace this somehow, but I'm not sure yet. It may be as simple (tedious)
// as defining all of the "put" statements
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




Function KillNamedDataFolder(fname)
	String fname
	
	Variable err=0
	
	String folderStr = N_GetFileNameFromPathNoSemi(fname)
	folderStr = RemoveDotExtension(folderStr)
	
	KillDataFolder/Z $("root:"+folderStr)
	err = V_flag
	
	return(err)
end


//sample transmission error (one sigma) is a real value at byte 396
Function WriteTransmissionErrorToHeader(fname,transErr)
	String fname
	Variable transErr
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ParamEXTRA2"
	wTmpWrite[0] = transErr //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End


//whole transmission is a real value at byte 392
Function WriteWholeTransToHeader(fname,trans)
	String fname
	Variable trans
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ParamEXTRA1"
	wTmpWrite[0] = trans //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//box sum counts is a real value at byte 494
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "FACTOR"
	wTmpWrite[0] = counts //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//box sum counts error is is a real value at byte 400
Function WriteBoxCountsErrorToHeader(fname,rel_err)
	String fname
	Variable rel_err
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ParamEXTRA3"
	wTmpWrite[0] = rel_err //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//beam stop X-pos is at byte 368
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "XPOS"
	wTmpWrite[0] = xpos //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//sample thickness is at byte 162
Function WriteThicknessToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "THK"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//beam center X pixel location is at byte 252
Function WriteBeamCenterXToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "BEAMX"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//beam center Y pixel location is at byte 256
Function WriteBeamCenterYToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "BEAMY"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//attenuator number (not its transmission) is at byte 51
Function WriteAttenNumberToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Run"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ATTEN"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//monitor count is at byte 39
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Run"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "MONCNT"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//total detector count is at byte 47
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Run"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "DETCNT"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//transmission detector count is at byte 388
Function WriteTransDetCountToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "TRNSCNT"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//wavelength is at byte 292
Function WriteWavelengthToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "LMDA"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//wavelength spread is at byte 296
Function WriteWavelengthDistrToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "DLMDA"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//temperature is at byte 186
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "TEMP"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//magnetic field is at byte 190
Function WriteMagnFieldToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "FIELD"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err

	return(0)
End

//Source Aperture diameter is at byte 280
Function WriteSourceApDiamToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "AP1"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//Sample Aperture diameter is at byte 284
Function WriteSampleApDiamToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "AP2"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//Source to sample distance is at byte 288
Function WriteSrcToSamDistToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "AP12DIS"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//detector offset is at byte 264
Function WriteDetectorOffsetToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ANG"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//beam stop diameter is at byte 272
Function WriteBeamStopDiamToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "BSTOP"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//sample to detector distance is at byte 260
Function WriteSDDToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "DIS"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

//TODO - this dangerously fills in the values for the other two detector constants
//
//detector pixel X size (mm) is at byte 220
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=3 wTmpWrite3
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "CALX"
	wTmpWrite3[0] = num
	wTmpWrite3[0] = 10000
	wTmpWrite3[0] = 0

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite3)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err

	return(0)
End

//TODO - this dangerously fills in the values for the other two detector constants
//
//detector pixel Y size (mm) is at byte 232
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=3 wTmpWrite3
	String groupName = "/Detector"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "CALY"
	wTmpWrite3[0] = num
	wTmpWrite3[0] = 10000
	wTmpWrite3[0] = 0

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite3)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End

// Write the detector deadtime to the file header (in seconds) @ byte 498
Function WriteDeadtimeToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "AnalysisQMIN"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
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
//
// TODO
// limit to 60 characters?? do I need to do this with HDF5?
//
// do I need to pad to 60 characters?
//
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	if(strlen(str) > 60)
		str = str[0,59]
	endif
//	WriteTextToHeader(fname,str,98)
	
	
	Make/O/T/N=1 tmpTW
	String groupName = "/Run1"	//	explicitly state the group
	String varName = "runLabel"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	
	return(0)
End



//user account name, starts at byte 78
// limit to 11 characters
Function WriteAcctNameToHeader(fname,str)
	String fname,str
	
	if(strlen(str) > 9)
		str = str[0,8]
	endif
	str = "["+str+"]"
	
	
	Make/O/T/N=1 tmpTW
	String groupName = "/Run1/Run"	//	Explicitly state the group
	String varName = "DEFDIR"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err

	return(0)
End


// TODO -- this is an issue - I don't know how to access this
// ????
//
// file name, starts at byte 2
// limit to 21 characters
//
// be sure that any white space to pad to 21 characters is at the front of the string
Function WriteFileNameToHeader(fname,str)
	String fname,str
	
	Variable i
	String newStr=""
//	printf "\"%s\"\t%d\r",str,strlen(str)

	//strip any white spaces from the end (from TrimWSR(str) in cansasXML.ipf)
	for (i=strlen(str)-1; char2num(str[i])<=32 && i>=0; i-=1)    // find last non-white space
	endfor
	str = str[0,i]
//	printf "\"%s\"\t%d\r",str,strlen(str)

	// if the string is less than 21 characters, fix it with white space at the beginning
	if(strlen(str) < 21)
		newStr = PadString(newStr,21,0x20)		//pad with fortran-style spaces
		newStr[21-strlen(str),20] = str
	else
		newStr = str
	endif
//	printf "\"%s\"\t%d\r",newstr,strlen(newstr)

	Make/O/T/N=1 tmpTW
	String groupName = "/"	//	explicitly state the group -- this is the top level, so group is ""
	String varName = "filename"
	tmpTW[0] = str //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End


////rewrite an integer field back to the header
//// fname is the full path:name
//// val is the integer value
//// start is the start byte
//Function RewriteIntegerToHeader(fname,val,start)
//	String fname
//	Variable val,start
//	
//	Variable refnum
//	Open/A/T="????TEXT" refnum as fname      //Open for writing! Move to EOF before closing!
//	FSetPos refnum,start
//	FBinWrite/B=3/F=3 refnum, val      //write a 4-byte integer
//	//move to the end of the file before closing
//	FStatus refnum
//	FSetPos refnum,V_logEOF
//	Close refnum
//		
//	return(0)
//end

// this is technically an integer, but use the same writer that uses
// double.
Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Run"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "CTIME"
	wTmpWrite[0] = num //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	return(0)
End






//////////////////////////////////////////////////////////////////////////////////

























//go find the file, open it and write 4 integers to the file
//in the positions for analysis.rows(2), .cols(2) = 4 unused 4byte integers
Function WriteXYBoxToHeader(fname,x1,x2,y1,y2)
	String fname
	Variable x1,x2,y1,y2
	
	DoAlert 0,"XYBOX definition/writing not implemented"
	return(0)
	
//	Variable refnum
//	Open/A/T="????TEXT" refnum as filename
//	FSetPos refnum,478
//	FBinWrite/F=3/B=3 refNum, x1
//	FBinWrite/F=3/B=3 refNum, x2
//	FBinWrite/F=3/B=3 refNum, y1
//	FBinWrite/F=3/B=3 refNum, y2
//	//move to the end of the file before closing
//	FStatus refnum
//	FSetPos refnum,V_logEOF
//	Close refnum

	Make/O/D/N=2 wTmpWrite2
	String groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "ROWS"
	wTmpWrite2[0] = x1 //
	wTmpWrite2[1] = x2
	
	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite2)
//	Print "HDF write err = ",err

	groupName = "/Analysis"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	varName = "COLS"
	wTmpWrite2[0] = y1 //
	wTmpWrite2[1] = y2
	
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite2)
//	Print "HDF write err = ",err

	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
		
	return(0)
End

//associated file suffix is the first 4 characters of a text field starting
// at byte 404
// suffix must be four characters long, if not, it's truncated
//
// -- TODO - be careful when writing this -- this is technically wrong, as it
// obliterates everything else in the string (42 characters) and only cares
// about the first 4 characters...
//
Function WriteAssocFileSuffixToHeader(fname,suffix)
	String fname,suffix
	
	Print "AssocFileSuffix definition not implemented"
	return(0)
		
	suffix = suffix[0,3]		//limit to 4 characters
	
	Make/O/T/N=1 tmpTW
	String groupName = "/Run1/Analysis"	//	explicitly state the group
	String varName = "paramRESERVE"
	tmpTW[0] = suffix //

	variable err
	err = WriteTextWaveToHDF(fname, groupName, varName, tmpTW)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
	
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
		file = N_FindFileFromRunNumber(ii)
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
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			xdim = getDet_x_pixel_size(file)
			ydim = getDet_y_pixel_size(file)
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

Function WriteLensFlagToHeader(fname,flag)
	String fname
	Variable flag
	
	Make/O/D/N=1 wTmpWrite
	String groupName = "/Instrument"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
	String varName = "SAVEFlag"
	wTmpWrite[0] = flag //

	variable err
	err = WriteWaveToHDF(fname, groupName, varName, wTmpWrite)
//	Print "HDF write err = ",err
	
	// now be sure to kill the data folder to force a re-read of the data next time this file is read in
//	err = KillNamedDataFolder(fname)
//	Print "DataFolder kill err = ",err
		
	return(0)
End

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
	
	fullname = N_FindFileFromRunNumber(num)
	Print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "HeaderToPinhole - file not found"
	else
		//Print "Unconvert",fullname
		WriteLensFlagToHeader(fullname,0)
	Endif
	return(0)
End

// sets the flag to one in the file (= 1)
Function HeaderToLensResolution(num) 
	Variable num	
	
	//Print "Convert"
	String fullname=""
	
	fullname = N_FindFileFromRunNumber(num)
	Print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "HeaderToLens - file not found"
	else
		//Print "Convert",fullname
		WriteLensFlagToHeader(fullname,1)
	Endif
	return(0)
End



////// OCT 2009, facility specific bits from MonteCarlo functions()
//"type" is the data folder that has the data array that is to be (re)written as a full
// data file, as if it was a raw data file
//
Function/S Write_RawData_File(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name

	String filename = ""
	filename = Write_VAXRaw_Data(type,fullpath,dialog)
	
	return(filename)
End

// given a data folder, write out the corresponding VAX binary data file.
//
// I don't think that I can generate a STRUCT and then lay that down - since the
// VAX FP format has to be duplicated with a write/read/flip/re-write dance...
//
// seems to work correctly byte for byte
// compression has been implmented also, for complete replication of the format (n>32767 in a cell)
//
// SRK 29JAN09
//
// other functions needed:
//
//
// one to generate a fake data file name, and put the matching name in the data header
// !! must fake the Annn suffix too! this is used...
// use a prefix, keep a run number, initials SIM, and alpha as before (start randomly, don't bother changing?)
//
// for right now, keep a run number, and generate
// PREFIXnnn.SA2_SIM_Annn
// also, start the index @ 100 to avoid leading zeros (although I have the functions available)

// one to generate the date/time string in VAX format, right # characters// Print Secs2Time(DateTime,3)				// Prints 13:07:29
// Print Secs2Time(DateTime,3)				// Prints 13:07:29
//	Print Secs2Date(DateTime,-2)		// 1993-03-14			//this call is independent of System date/time!//
//
//
// simulation should call as ("SAS","",0) to bypass the dialog, and to fill the header
// this could be modified in the future to be more generic
//
///
// changed to return the string w/ the filename as written for later use
Function/S Write_VAXRaw_Data(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	String destStr=""
	Variable refNum,ii,val,err
	
	
	destStr = "root:Packages:NIST:"+type
	
	SetDataFolder $destStr
	WAVE intw=integersRead
	WAVE rw=realsRead
	WAVE/T textw=textRead
	
	WAVE linear_data = linear_data
	Duplicate/O linear_data tmp_data
		
	NVAR/Z rawCts = root:Packages:NIST:SAS:gRawCounts
	if(cmpstr("SAS",type)==0 && !rawCts)		//simulation data, and is not RAW counts, so scale it back

		//use kappa to get back to counts => linear_data = round(linear_data*kappa)
		String strNote = note(linear_data) 
		Variable kappa = NumberByKey("KAPPA", strNote , "=", ";")
		NVAR detectorEff = root:Packages:NIST:SAS:g_detectorEff

		tmp_data *= kappa
		tmp_data *= detectorEff
//		Print kappa, detectorEff
		Redimension/I tmp_data
	endif
	
	WAVE w=tmp_data

	// check for data values that are too large. the maximum VAX compressed data value is 2767000
	//
	WaveStats/Q w
	if(V_max > 2767000)
		Abort "Some individual pixel values are > 2767000 and the data can't be saved in VAX format"
	Endif
	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(w)))
		Abort "linear_data DNExist WriteVAXData()"
	Endif
	
	
//	if(dialog)
//		PathInfo/S catPathName
//		fullPath = DoSaveFileDialog("Save data as")
//		If(cmpstr(fullPath,"")==0)
//			//user cancel, don't write out a file
//			Close/A
//			Abort "no data file was written"
//		Endif
//		//Print "dialog fullpath = ",fullpath
//	Endif
	
	// save to home, or get out
	//
	PathInfo home
	if(V_flag	== 0)
		Abort "no save path defined. Save the experiment to generate a home path"
	endif
	
	fullPath = S_path		//not the full path yet, still need the name, after the header is filled
	
	
	Make/O/B/U/N=33316 tmpFile		//unsigned integers for a blank data file
	tmpFile=0
	
//	Make/O/W/N=16401 dataWRecMarkers			// don't convert to 16 bit here, rather write to file as 16 bit later
	Make/O/I/N=16401 dataWRecMarkers
	AddRecordMarkers(w,dataWRecMarkers)
		
	// need to re-compress?? maybe never a problem, but should be done for the odd case
	dataWRecMarkers = CompressI4toI2(dataWRecMarkers)		//unless a pixel value is > 32767, the same values are returned
	
	// fill the last bits of the header information
	err = SimulationVAXHeader(type)		//if the type != 'SAS', this function does nothing
	
	if (err == -1)
		Abort "no sample label entered - no file written"			// User did not fill in header correctly/completely
	endif
	fullPath = fullPath + textW[0]
	
	// lay down a blank file
	Open refNum as fullpath
		FBinWrite refNum,tmpFile			//file is the right size, but all zeroes
	Close refNum
	
	// fill up the header
	// text values
	// elements of textW are already the correct length set by the read, but just make sure
	String str
	
	if(strlen(textw[0])>21)
		textw[0] = (textw[0])[0,20]
	endif
	if(strlen(textw[1])>20)
		textw[1] = (textw[1])[0,19]
	endif
	if(strlen(textw[2])>3)
		textw[2] = (textw[2])[0,2]
	endif
	if(strlen(textw[3])>11)
		textw[3] = (textw[3])[0,10]
	endif
	if(strlen(textw[4])>1)
		textw[4] = (textw[4])[0]
	endif
	if(strlen(textw[5])>8)
		textw[5] = (textw[5])[0,7]
	endif
	if(strlen(textw[6])>60)
		textw[6] = (textw[6])[0,59]
	endif
	if(strlen(textw[7])>6)
		textw[7] = (textw[7])[0,5]
	endif
	if(strlen(textw[8])>6)
		textw[8] = (textw[8])[0,5]
	endif
	if(strlen(textw[9])>6)
		textw[9] = (textw[9])[0,5]
	endif
	if(strlen(textw[10])>42)
		textw[10] = (textw[10])[0,41]
	endif	
	
	ii=0
	Open/A/T="????TEXT" refnum as fullpath      //Open for writing! Move to EOF before closing!
		str = textW[ii]
		FSetPos refnum,2							////file name
		FBinWrite/F=0 refnum, str      //native object format (character)
		ii+=1
		str = textW[ii]
		FSetPos refnum,55							////date/time
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,75							////type
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,78						////def dir
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,89						////mode
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,90						////reserve
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,98						////@98, sample label
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,202						//// T units
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,208						//// F units
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,214						////det type
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,404						////reserve
		FBinWrite/F=0 refnum, str
	
		//move to the end of the file before closing
		FStatus refnum
		FSetPos refnum,V_logEOF
	Close refnum
	
	
	// integer values (4 bytes)
	ii=0
	Open/A/T="????TEXT" refnum as fullpath      //Open for writing! Move to EOF before closing!
		val = intw[ii]
		FSetPos refnum,23							//nprefactors
		FBinWrite/B=3/F=3 refnum, val      //write a 4-byte integer
		ii+=1
		val=intw[ii]
		FSetPos refnum,27							//ctime
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,31							//rtime
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,35							//numruns
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,174							//table
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,178							//holder
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,182							//blank
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,194							//tctrlr
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,198							//magnet
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,244							//det num
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,248							//det spacer
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,308							//tslice mult
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,312							//tsclice ltslice
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,332							//extra
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,336							//reserve
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,376							//blank1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,380							//blank2
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,384							//blank3
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,458							//spacer
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,478							//box x1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,482							//box x2
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,486							//box y1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,490							//box y2
		FBinWrite/B=3/F=3 refnum, val
		
		//move to the end of the file before closing
		FStatus refnum
		FSetPos refnum,V_logEOF
	Close refnum
	
		
	//VAX 4-byte FP values. No choice here but to write/read/re-write to get 
	// the proper format. there are 52! values to write
	//WriteVAXReal(fullpath,rw[n],start)
	// [0]
	WriteVAXReal(fullpath,rw[0],39)
	WriteVAXReal(fullpath,rw[1],43)
	WriteVAXReal(fullpath,rw[2],47)
	WriteVAXReal(fullpath,rw[3],51)
	WriteVAXReal(fullpath,rw[4],158)
	WriteVAXReal(fullpath,rw[5],162)
	WriteVAXReal(fullpath,rw[6],166)
	WriteVAXReal(fullpath,rw[7],170)
	WriteVAXReal(fullpath,rw[8],186)
	WriteVAXReal(fullpath,rw[9],190)
	// [10]
	WriteVAXReal(fullpath,rw[10],220)
	WriteVAXReal(fullpath,rw[11],224)
	WriteVAXReal(fullpath,rw[12],228)
	WriteVAXReal(fullpath,rw[13],232)
	WriteVAXReal(fullpath,rw[14],236)
	WriteVAXReal(fullpath,rw[15],240)
	WriteVAXReal(fullpath,rw[16],252)
	WriteVAXReal(fullpath,rw[17],256)
	WriteVAXReal(fullpath,rw[18],260)
	WriteVAXReal(fullpath,rw[19],264)
	// [20]
	WriteVAXReal(fullpath,rw[20],268)
	WriteVAXReal(fullpath,rw[21],272)
	WriteVAXReal(fullpath,rw[22],276)
	WriteVAXReal(fullpath,rw[23],280)
	WriteVAXReal(fullpath,rw[24],284)
	WriteVAXReal(fullpath,rw[25],288)
	WriteVAXReal(fullpath,rw[26],292)
	WriteVAXReal(fullpath,rw[27],296)
	WriteVAXReal(fullpath,rw[28],300)
	WriteVAXReal(fullpath,rw[29],320)
	// [30]
	WriteVAXReal(fullpath,rw[30],324)
	WriteVAXReal(fullpath,rw[31],328)
	WriteVAXReal(fullpath,rw[32],348)
	WriteVAXReal(fullpath,rw[33],352)
	WriteVAXReal(fullpath,rw[34],356)
	WriteVAXReal(fullpath,rw[35],360)
	WriteVAXReal(fullpath,rw[36],364)
	WriteVAXReal(fullpath,rw[37],368)
	WriteVAXReal(fullpath,rw[38],372)
	WriteVAXReal(fullpath,rw[39],388)
	// [40]
	WriteVAXReal(fullpath,rw[40],392)
	WriteVAXReal(fullpath,rw[41],396)
	WriteVAXReal(fullpath,rw[42],400)
	WriteVAXReal(fullpath,rw[43],450)
	WriteVAXReal(fullpath,rw[44],454)
	WriteVAXReal(fullpath,rw[45],470)
	WriteVAXReal(fullpath,rw[46],474)
	WriteVAXReal(fullpath,rw[47],494)
	WriteVAXReal(fullpath,rw[48],498)
	WriteVAXReal(fullpath,rw[49],502)
	// [50]
	WriteVAXReal(fullpath,rw[50],506)
	WriteVAXReal(fullpath,rw[51],510)
	
	
	// write out the data
	Open refNum as fullpath
		FSetPos refnum,514					//  OK
		FBinWrite/F=2/B=3 refNum,dataWRecMarkers		//don't trust the native format
		FStatus refNum
		FSetPos refNum,V_logEOF
	Close refNum
	
	// all done
	Killwaves/Z tmpFile,dataWRecMarkers,tmp_data
	
	Print "Saved VAX binary data as:  ",textW[0]
	SetDatafolder root:
	return(fullpath)
End


Function AddRecordMarkers(in,out)
	Wave in,out
	
	Variable skip,ii

//	Duplicate/O in,out
//	Redimension/N=16401 out

	out=0
	
	ii=0
	skip=0
	out[ii] = 1
	ii+=1
	do
		if(mod(ii+skip,1022)==0)
			out[ii+skip] = 0		//999999
			skip+=1			//increment AFTER filling the current marker
		endif
		out[ii+skip] = in[ii-1]
		ii+=1
	while(ii<=16384)
	
	
	return(0)
End




//        INTEGER*2 FUNCTION I4ToI2(I4)
//C
//C       Original author : Jim Rhyne
//C       Modified by     : Frank Chen 09/26/90
//C
//C       I4ToI2 = I4,                            I4 in [0,32767]
//C       I4ToI2 = -777,                          I4 in (2767000,...)
//C       I4ToI2 mapped to -13277 to -32768,      otherwise
//C
//C       the mapped values [-776,-1] and [-13276,-778] are not used
//C
//C       I4max should be 2768499, this value will maps to -32768
//C       and mantissa should be compared  using 
//C               IF (R4 .GE. IPW)
//C       instead of
//C               IF (R4 .GT. (IPW - 1.0))
//C
//
//
//C       I4      :       input I*4
//C       R4      :       temperory real number storage
//C       IPW     :       IPW = IB ** ND
//C       NPW     :       number of power
//C       IB      :       Base value
//C       ND      :       Number of precision digits
//C       I4max   :       max data value w/ some error
//C       I2max   :       max data value w/o error
//C       Error   :       when data value > I4max
//C
//        INTEGER*4       I4
//        INTEGER*4       NPW
//        REAL*4          R4
//        INTEGER*4       IPW
//        INTEGER*4       IB      /10/
//        INTEGER*4       ND      /4/
//        INTEGER*4       I4max   /2767000/
//        INTEGER*4       I2max   /32767/
//        INTEGER*4       Error   /-777/
//
Function CompressI4toI2(i4)
	Variable i4

	Variable npw,ipw,ib,nd,i4max,i2max,error,i4toi2
	Variable r4
	
	ib=10
	nd=4
	i4max=2767000
	i2max=32767
	error=-777
	
	if(i4 <= i4max)
		r4=i4
		if(r4 > i2max)
			ipw = ib^nd
			npw=0
			do
				if( !(r4 > (ipw-1)) )		//to simulate a do-while loop evaluating at top
					break
				endif
				npw=npw+1
				r4=r4/ib		
			while (1)
			i4toi2 = -1*trunc(r4+ipw*npw)
		else
			i4toi2 = trunc(r4)		//shouldn't I just return i4 (as a 2 byte value?)
		endif
	else
		i4toi2=error
	endif
	return(i4toi2)
End


// function to fill the extra bits of header information to make a "complete"
// simulated VAX data file.
//
// NCNR-Specific. is hard wired to the SAS folder. If saving from any other folder, set all of the header
// information before saving, and pass a null string to this procedure to bypass it entirely
//
Function SimulationVAXHeader(folder)
	String folder

	if(cmpstr(folder,"SAS")!=0)		//if not the SAS folder passed in, get out now, and return 1 (-1 is the error condition)
		return(1)
	endif
	
	Wave rw=root:Packages:NIST:SAS:realsRead
	Wave iw=root:Packages:NIST:SAS:integersRead
	Wave/T tw=root:Packages:NIST:SAS:textRead
	Wave res=root:Packages:NIST:SAS:results
	
// integers needed:
	//[2] count time
	NVAR ctTime = root:Packages:NIST:SAS:gCntTime
	iw[2] = ctTime
	
//reals are partially set in SASCALC initializtion
	//remaining values are updated automatically as SASCALC is modified
	// -- but still need:
	//	[0] monitor count
	//	[2] detector count (w/o beamstop)
	//	[4] transmission
	//	[5] thickness (in cm)
	NVAR imon = root:Packages:NIST:SAS:gImon
	rw[0] = imon
	rw[2] = res[9]
	rw[4] = res[8]
	NVAR thick = root:Packages:NIST:SAS:gThick
	rw[5] = thick
	
// text values needed:
// be sure they are padded to the correct length
	// [0] filename (do I fake a VAX name? probably yes...)
	// [1] date/time in VAX format
	// [2] type (use SIM)
	// [3] def dir (use [NG7SANS99])
	// [4] mode? C
	// [5] reserve (another date), prob not needed
	// [6] sample label
	// [9] det type "ORNL  " (6 chars)

	SVAR gInstStr = root:Packages:NIST:SAS:gInstStr
		
	tw[1] = Secs2Date(DateTime,-2)+"  "+ Secs2Time(DateTime,3) 		//20 chars, not quite VAX format
	tw[2] = "SIM"
	tw[3] = "["+gInstStr+"SANS99]"
	tw[4] = "C"
	tw[5] = "01JAN09 "
	tw[9] = "ORNL  "
	
	
	//get the run index and the sample label from the optional parameters, or from a dialog
	NVAR index = root:Packages:NIST:SAS:gSaveIndex
	SVAR prefix = root:Packages:NIST:SAS:gSavePrefix
// did the user pass in values?
	NVAR autoSaveIndex = root:Packages:NIST:SAS:gAutoSaveIndex
	SVAR autoSaveLabel = root:Packages:NIST:SAS:gAutoSaveLabel
	
	String labelStr=""	
	Variable runNum
	if( (autoSaveIndex != 0) && (strlen(autoSaveLabel) > 0) )
		// all is OK, proceed with the save
		labelStr = autoSaveLabel
		runNum = autoSaveIndex		//user must take care of incrementing this!
	else
		//one or the other, or both are missing, so ask
		runNum = index
		Prompt labelStr, "Enter sample label "		// Set prompt for x param
		Prompt runNum,"Run Number (automatically increments)"
		DoPrompt "Enter sample label", labelStr,runNum
		if (V_Flag)
			//Print "no sample label entered - no file written"
			//index -=1
			return -1								// User canceled
		endif
		if(runNum != index)
			index = runNum
		endif
		index += 1
	endif
	
	//make a three character string of the run number
	String numStr=""
	if(runNum<10)
		numStr = "00"+num2str(runNum)
	else
		if(runNum<100)
			numStr = "0"+num2str(runNum)
		else
			numStr = num2str(runNum)
		Endif
	Endif
	//date()[0] is the first letter of the day of the week
	// OK for most cases, except for an overnight simulation! then the suffix won't sort right...
//	tw[0] = prefix+numstr+".SA2_SIM_"+(date()[0])+numStr

//fancier, JAN=A, FEB=B, etc...
	String timeStr= secs2date(datetime,-1)
	String monthStr=StringFromList(1, timeStr  ,"/")

	tw[0] = prefix+numstr+".SA2_SIM_"+(num2char(str2num(monthStr)+64))+numStr
	
	labelStr = PadString(labelStr,60,0x20) 	//60 fortran-style spaces
	tw[6] = labelStr[0,59]
	
	return(0)
End

Function ExamineHeader(type)
	String type

	String data_folder = type
	String dataPath = "root:Packages:NIST:"+data_folder
	String cur_folder = "ExamineHeader"
	String curPath = "root:Packages:NIST:"+cur_folder
	
	//SetDataFolder curPath

	Wave intw=$(dataPath+":IntegersRead")
	Wave realw=$(dataPath+":RealsRead")
	Wave/T textw=$(dataPath+":TextRead")
	Wave logw=$(dataPath+":LogicalsRead")


	print "----------------------------------"
	print "Header Details"
	print "----------------------------------"
	print "fname :\t\t"+textw[0]
	//
	print "run.npre :\t\t"+num2str(intw[0])
	print "run.ctime :\t\t"+num2str(intw[1])
	print "run.rtime :\t\t"+num2str(intw[2])
	print "run.numruns :\t\t"+num2str(intw[3])
	//
	print "run.moncnt :\t\t"+num2str(realw[0])
	print "run.savmon :\t\t"+num2str(realw[1])
	print "run.detcnt :\t\t"+num2str(realw[2])
	print "run.atten :\t\t"+num2str(realw[3])	
	//
	print "run.timdat:\t\t"+textw[1]
	print "run.type:\t\t"+textw[2]
	print "run.defdir:\t\t"+textw[3]
	print "run.mode:\t\t"+textw[4]
	print "run.reserve:\t\t"+textw[5]
	print "sample.labl:\t\t"+textw[6]
	//
	print "sample.trns:\t\t"+num2str(realw[4])
	print "sample.thk:\t\t"+num2str(realw[5])
	print "sample.position:\t\t"+num2str(realw[6])
	print "sample.rotang:\t\t"+num2str(realw[7])
	//
	print "sample.table:\t\t"+num2str(intw[4])
	print "sample.holder:\t\t"+num2str(intw[5])
	print "sample.blank:\t\t"+num2str(intw[6])
	//
	print "sample.temp:\t\t"+num2str(realw[8])
	print "sample.field:\t\t"+num2str(realw[9])	
	//
	print "sample.tctrlr:\t\t"+num2str(intw[7])
	print "sample.magnet:\t\t"+num2str(intw[8])
	//
	print "sample.tunits:\t\t"+textw[7]
	print "sample.funits:\t\t"+textw[8]
	print "det.typ:\t\t"+textw[9]
	//
	print "det.calx(1):\t\t"+num2str(realw[10])
	print "det.calx(2):\t\t"+num2str(realw[11])
	print "det.calx(3):\t\t"+num2str(realw[12])
	print "det.caly(1):\t\t"+num2str(realw[13])
	print "det.caly(2):\t\t"+num2str(realw[14])
	print "det.caly(3):\t\t"+num2str(realw[15])
	//
	print "det.num:\t\t"+num2str(intw[9])
	print "det.spacer:\t\t"+num2str(intw[10])
	//
	print "det.beamx:\t\t"+num2str(realw[16])
	print "det.beamy:\t\t"+num2str(realw[17])
	print "det.dis:\t\t"+num2str(realw[18])
	print "det.offset:\t\t"+num2str(realw[19])
	print "det.siz:\t\t"+num2str(realw[20])
	print "det.bstop:\t\t"+num2str(realw[21])
	print "det.blank:\t\t"+num2str(realw[22])
	print "resolution.ap1:\t\t"+num2str(realw[23])
	print "resolution.ap2:\t\t"+num2str(realw[24])
	print "resolution.ap12dis:\t\t"+num2str(realw[25])
	print "resolution.lmda:\t\t"+num2str(realw[26])
	print "resolution.dlmda:\t\t"+num2str(realw[27])
	print "resolution.nlenses:\t\t"+num2str(realw[28])	
	//
	print "tslice.slicing:\t\t"+num2str(logw[0])
	//
	print "tslice.multfact:\t\t"+num2str(intw[11])
	print "tslice.ltslice:\t\t"+num2str(intw[12])
	//
	print "temp.printemp:\t\t"+num2str(logw[1])
	//
	print "temp.hold:\t\t"+num2str(realw[29])
	print "temp.err:\t\t"+num2str(realw[30])
	print "temp.blank:\t\t"+num2str(realw[31])
	//
	print "temp.extra:\t\t"+num2str(intw[13])
	print "temp.err:\t\t"+num2str(intw[14])
	//
	print "magnet.printmag:\t\t"+num2str(logw[2])
	print "magnet.sensor:\t\t"+num2str(logw[3])
	//
	print "magnet.current:\t\t"+num2str(realw[32])
	print "magnet.conv:\t\t"+num2str(realw[33])
	print "magnet.fieldlast:\t\t"+num2str(realw[34])
	print "magnet.blank:\t\t"+num2str(realw[35])
	print "magnet.spacer:\t\t"+num2str(realw[36])
	print "bmstp.xpos:\t\t"+num2str(realw[37])
	print "bmstop.ypos:\t\t"+num2str(realw[38])
	//	
	print "params.blank1:\t\t"+num2str(intw[15])
	print "params.blank2:\t\t"+num2str(intw[16])
	print "params.blank3:\t\t"+num2str(intw[17])
	//
	print "params.trnscnt:\t\t"+num2str(realw[39])
	print "params.extra1:\t\t"+num2str(realw[40])
	print "params.extra2:\t\t"+num2str(realw[41])
	print "params.extra3:\t\t"+num2str(realw[42])
	//	
	print "params.reserve:\t\t"+textw[10]
	//
	print "voltage.printemp:\t\t"+num2str(logw[4])
	//
	print "voltage.volts:\t\t"+num2str(realw[43])
	print "voltage.blank:\t\t"+num2str(realw[44])
	//	
	print "voltage.spacer:\t\t"+num2str(intw[18])
	//
	print "polarization.printpol:\t\t"+num2str(logw[5])
	print "polarization.flipper:\t\t"+num2str(logw[6])
	//	
	print "polarization.horiz:\t\t"+num2str(realw[45])
	print "polarization.vert:\t\t"+num2str(realw[46])
	//
	print "analysis.rows(1):\t\t"+num2str(intw[19])
	print "analysis.rows(2):\t\t"+num2str(intw[20])
	print "analysis.cols(1):\t\t"+num2str(intw[21])
	print "analysis.cols(2):\t\t"+num2str(intw[22])
	//
	print "analysis.factor:\t\t"+num2str(realw[47])
	print "analysis.qmin:\t\t"+num2str(realw[48])
	print "analysis.qmax:\t\t"+num2str(realw[49])
	print "analysis.imin:\t\t"+num2str(realw[50])
	print "analysis.imax:\t\t"+num2str(realw[51])

End


// Sept 2009 -SRK
// the ICE instrument control software is not correctly writing out the file name to the header in the specific
// case of a file prefix less than 5 characters. ICE is quite naturally putting the blanke space(s) at the end of
// the string. However, the VAX puts them at the beginning...
Proc PatchFileNameInHeader(firstFile,lastFile)
	Variable firstFile=1,lastFile=100

	fPatchFileName(firstFile,lastFile)

End

Proc ReadFileNameInHeader(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadFileName(firstFile,lastFile)
End


// simple utility to patch the file name in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
// will read the 21 character file name and put any spaces at the front of the string
// like the VAX does. Should have absolutely no effect if there are spaces at the
// beginning of the string, as the VAX does.
Function fPatchFileName(lo,hi)
	Variable lo,hi
	
	Variable ii
	String file,fileName
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			fileName = getFileName(file)
			WriteFileNameToHeader(file,fileName)
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the file name stored in the file header (and the suffix)
Function fReadFileName(lo,hi)
	Variable lo,hi
	
	String file,fileName,suffix
	Variable ii
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			fileName = getFileName(file)
			suffix = getSuffix(file)
			printf "File %d:  File name = %s\t\tSuffix = %s\r",ii,fileName,suffix
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End




// April 2009 - AJJ
// The new ICE instrument control software was not correctly writing the run.defdir field
// The format of that field should be [NGxSANSn] where x is 3 or 7 and nn is 0 through 50

Proc PatchUserAccountName(firstFile,lastFile,acctName)
	Variable firstFile=1,lastFile=100
	String acctName = "NG3SANS0"

	fPatchUserAccountName(firstFile,lastFile,acctName)

End

Proc ReadUserAccountName(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadUserAccountName(firstFile,lastFile)
End

// simple utility to patch the user account name in the file headers
// pass in the account name as a string
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchUserAccountName(lo,hi,acctName)
	Variable lo,hi
	String acctName
	
	Variable ii
	String file
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			WriteAcctNameToHeader(file,acctName)
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the user account name stored in the file header
Function fReadUserAccountName(lo,hi)
	Variable lo,hi
	
	String file,acctName
	Variable ii
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			acctName = getAcctName(file)
			printf "File %d:  Account name = %s\r",ii,acctName
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// May 2009 - SRK
// Monitor count not written correctly to file from ICE

Proc PatchMonitorCount(firstFile,lastFile,monCtRate)
	Variable firstFile=1,lastFile=100,monCtRate

	fPatchMonitorCount(firstFile,lastFile,monCtRate)

End

Proc ReadMonitorCount(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadMonitorCount(firstFile,lastFile)
End

// simple utility to patch the user account name in the file headers
// pass in the account name as a string
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchMonitorCount(lo,hi,monCtRate)
	Variable lo,hi,monCtRate
	
	Variable ii,ctTime
	String file
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			ctTime = getCollectionTime(file)
			WriteMonitorCountToHeader(file,ctTime*monCtRate)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the user account name stored in the file header
Function fReadMonitorCount(lo,hi)
	Variable lo,hi
	
	String file
	Variable ii,monitorCount
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			monitorCount = getControlMonitorCount(file)
			printf "File %d:  Monitor Count = %g\r",ii,monitorCount
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End


// May 2014 - SRK
// Detector Deadtime (possibly) written to file by ICE

Proc PatchDetectorDeadtime(firstFile,lastFile,deadtime)
	Variable firstFile=1,lastFile=100,deadtime

	fPatchDetectorDeadtime(firstFile,lastFile,deadtime)

End

Proc ReadDetectorDeadtime(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadDetectorDeadtime(firstFile,lastFile)
End

// simple utility to patch the detector deadtime in the file headers
// pass in the account name as a string
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchDetectorDeadtime(lo,hi,deadtime)
	Variable lo,hi,deadtime
	
	Variable ii
	String file
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			WriteDeadtimeToHeader(file,deadtime)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to read the detector deadtime stored in the file header
Function fReadDetectorDeadtime(lo,hi)
	Variable lo,hi
	
	String file
	Variable ii,deadtime
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			deadtime = getDetectorDeadtime_value(file)
			printf "File %d:  Detector Dead time (s) = %g\r",ii,deadtime
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End



/////
Proc ReadDetectorCount(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fReadDetectorCount(firstFile,lastFile)
End


// simple utility to read the detector count from the header, and the summed data value
// and print out the values
Function fReadDetectorCount(lo,hi)
	Variable lo,hi
	
	String file
	Variable ii,summed
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			ReadHeaderAndData(file,"RAW")
			Wave rw=root:Packages:NIST:RAW:RealsRead
			Wave data = getDetectorDataW("RAW")		//this will be the linear data
			summed = sum(data,-inf,inf)
			printf "File %d:  DetCt Header = %g\t Detector Sum = %g\t Ratio sum/hdr = %g\r",ii,rw[2],summed,summed/rw[2]
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End


////// OCT 2009, facility specific bits from ProDiv()
//"type" is the data folder that has the corrected, patched, and normalized DIV data array
//
// the header of this file is rather unimportant. Filling in a title at least would be helpful/
//
Function Write_DIV_File(type)
	String type
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	WriteVAXWorkFile(type)
	
	return(0)
End

//writes an VAX-style WORK file, "exactly" as it would be output from the VAX
//except for the "dummy" header and the record markers - the record marker bytes are
// in the files - they are just written as zeros and are meaningless
//file is:
//	516 bytes header
// 128x128=16384 (x4) bytes of data 
// + 2 byte record markers interspersed just for fun
// = 66116 bytes
//prompts for name of the output file.
//
Function WriteVAXWorkFile(type)
	String type
	
	Wave data = getDetectorDataW(type)		//this will be the linear data
	
	Variable refnum,ii=0,hdrBytes=516,a,b,offset
	String fullpath=""
	
	Duplicate/O data,tempData
	Redimension/S/N=(128*128) tempData
	tempData *= 4
	
	PathInfo/S catPathName
	fullPath = DoSaveFileDialog("Save data as")	  //won't actually open the file
	If(cmpstr(fullPath,"")==0)
		//user cancel, don't write out a file
	  Close/A
	  Abort "no data file was written"
	Endif
	
	Make/B/O/N=(hdrBytes) hdrWave
	hdrWave=0
	FakeDIVHeader(hdrWave)
	
	Make/Y=2/O/N=(510) bw510		//Y=2 specifies 32 bit (=4 byte) floating point
	Make/Y=2/O/N=(511) bw511
	Make/Y=2/O/N=(48) bw48

	Make/O/B/N=2 recWave		//two bytes

	//actually open the file
	Open/C="????"/T="TEXT" refNum as fullpath
	FSetPos refNum, 0
	//write header bytes (to be skipped when reading the file later)
	
	FBinWrite /F=1 refnum,hdrWave
	
	ii=0
	a=0
	do
		//write 511 4-byte values (little-endian order), 4* true value
		bw511[] = tempData[p+a]
		FBinWrite /B=3/F=4 refnum,bw511
		a+=511
		//write a 2-byte record marker
		FBinWrite refnum,recWave
		
		//write 510 4-byte values (little-endian) 4* true value
		bw510[] = tempData[p+a]
		FBinWrite /B=3/F=4 refnum,bw510
		a+=510
		
		//write a 2-byte record marker
		FBinWrite refnum,recWave
		
		ii+=1	
	while(ii<16)
	//write out last 48  4-byte values (little-endian) 4* true value
	bw48[] = tempData[p+a]
	FBinWrite /B=3/F=4 refnum,bw48
	//close the file
	Close refnum
	
	//go back through and make it look like a VAX datafile
	Make/W/U/O/N=(511*2) int511		// /W=16 bit signed integers /U=unsigned
	Make/W/U/O/N=(510*2) int510
	Make/W/U/O/N=(48*2) int48
	
	//skip the header for now
	Open/A/T="????TEXT" refnum as fullPath
	FSetPos refnum,0
	
	offset=hdrBytes
	ii=0
	do
		//511*2 integers
		FSetPos refnum,offset
		FBinRead/B=2/F=2 refnum,int511
		Swap16BWave(int511)
		FSetPos refnum,offset
		FBinWrite/B=2/F=2 refnum,int511
		
		//skip 511 4-byte FP = (511*2)*2 2byte int  + 2 bytes record marker
		offset += 511*2*2 + 2
		
		//510*2 integers
		FSetPos refnum,offset
		FBinRead/B=2/F=2 refnum,int510
		Swap16BWave(int510)
		FSetPos refnum,offset
		FBinWrite/B=2/F=2 refnum,int510
		
		//
		offset += 510*2*2 + 2
		
		ii+=1
	while(ii<16)
	//48*2 integers
	FSetPos refnum,offset
	FBinRead/B=2/F=2 refnum,int48
	Swap16BWave(int48)
	FSetPos refnum,offset
	FBinWrite/B=2/F=2 refnum,int48

	//move to EOF and close
	FStatus refnum
	FSetPos refnum,V_logEOF
	
	Close refnum
	
	Killwaves/Z hdrWave,bw48,bw511,bw510,recWave,temp16,int511,int510,int48
End

// given a 16 bit integer wave, read in as 2-byte pairs of 32-bit FP data
// swap the order of the 2-byte pairs
// 
Function Swap16BWave(w)
	Wave w

	Duplicate/O w,temp16
	//Variable num=numpnts(w),ii=0

	//elegant way to swap even/odd values, using wave assignments
	w[0,*;2] = temp16[p+1]
	w[1,*;2] = temp16[p-1]

//crude way, using a loop	
//	for(ii=0;ii<num;ii+=2)
//		w[ii] = temp16[ii+1]
//		w[ii+1] = temp16[ii]
//	endfor
	
	return(0)	
End

// writes a fake label into the header of the DIV file
//
Function FakeDIVHeader(hdrWave)
	WAVE hdrWave
	
	//put some fake text into the sample label position (60 characters=60 bytes)
	String day=date(),tim=time(),lbl=""
	Variable start=98,num,ii
	
	lbl = "Sensitivity (DIV) created "+day +" "+tim
	num=strlen(lbl)
	for(ii=0;ii<num;ii+=1)
		hdrWave[start+ii] = char2num(lbl[ii])
	endfor

	return(0)
End

////////end of ProDiv() specifics


// JUL 2013
// Yet another fix for an ICE issue. Here the issue is when the run number gets "magically"
// reset during an experiment. Then there are duplicate run numbers. When procedures key on the run number,
// the *first* file in the OS file listing is the one that's found. Simply renaming the file with a 
// different number is not sufficient, as the file name embedded in the header must be used (typically from
// marquee operations) where there is a disconnect between the file load and the function - leading to 
// cases where the current data is "unknown", except for textRead.
//
// Hence more patching procedures to re-write files with new file names in the header and the OS.
//
Proc RenumberRunNumber(add)
	Variable add

	fRenumberRunNumber(add)

End

Proc CheckFileNames(firstFile,lastFile)
	Variable firstFile=1,lastFile=100
	
	fCheckFileNames(firstFile,lastFile)
End


// will read the 21 character file name and put any spaces at the front of the string
// like the VAX does. Should have absolutely no effect if there are spaces at the
// beginning of the string, as the VAX does.
Function fRenumberRunNumber(add)
	Variable add
	
	Variable ii,numItems
	String item,runStr,list
	String curFile,newRunStr,newFileStr
	String pathStr
	PathInfo catPathName
	pathStr = S_path
	
// get a list of all of the files in the folder
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	numItems = ItemsInList(list,";")		//get the new number of items in the list

// for each file
	for(ii=0;ii<numItems;ii+=1)
		curFile = StringFromList(ii, list  ,";" )
		runStr = N_GetRunNumStrFromFile(curFile)
		
		if(cmpstr(runStr,"ABC") != 0)		// weed out error if run number can't be found
			newRunStr = num2str( str2num(runStr) + add )
			newFileStr = ReplaceString(runStr, curFile, newRunStr )
		// change the file name on disk to have a new number (+add)
			Printf "Old = %s\t\tNew = %s\r",curFile,newFileStr
			
		// copy the file, saving with the new name
			CopyFile/I=0/O/P=catPathName curFile as newFileStr
			
		// change the run number in the file header to have the new number (writing just the necessary characters)
			WriteTextToHeader(pathStr+newFileStr,newRunStr,7)		//start at byte 7
		endif
					
	endfor
	
	return(0)
End

// simple utility to read the file name stored in the file header (and the suffix)
Function fCheckFileNames(lo,hi)
	Variable lo,hi
	
	String file,fileName,suffix,fileInHdr,fileOnDisk
	Variable ii
	
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			fileOnDisk = ParseFilePath(0, file, ":", 1, 0)
			fileInHdr = getFileName(file)
//			suffix = getSuffix(file)
			printf "File %d:  File on disk = %s\t\tFile in Hdr = %s\r",ii,fileOnDisk,fileInHdr
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

