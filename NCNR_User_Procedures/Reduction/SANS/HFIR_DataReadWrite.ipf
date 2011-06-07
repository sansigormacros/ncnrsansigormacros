#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*************************************************************************************************
//
// Vers. ????
// Vers. ???? - branched from main reduction to split out facility
//                     specific calls
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//					NIST CNR Igor Pro Data Reduction Package
//				   HFIR SANS version for SPICE raw data format: 
//
//						University of Tennessee / NIST
//							   DANSE/SANS
//								Jun. 2009: JHC
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// - RAW data files are read into the RAW folder - integer data from the detector
//   is decompressed and given the proper orientation
// - header information is placed into real,integer, or text waves in the order they appear
//   in the file header
//
// Work data (DIV File) is read into the DIV folder
//
//*************************************************************************************************

//simple, main entry procedure that will load a RAW sans data file (not a work file)
//into the RAW dataFolder. It is up to the calling procedure to display the file
//
// called by MainPanel.ipf and ProtocolAsPanel.ipf
//
Function LoadRawSANSData(msgStr)
	String msgStr

	String filename = ""

	//each routine is responsible for checking the current (displayed) data folder
	//selecting it, and returning to root when done
	PathInfo/S catPathName		//should set the next dialog to the proper path...
	//get the filename, then read it in
	filename = PromptForPath(msgStr)//in SANS_Utils.ipf
	
	//check for cancel from dialog
	if(strlen(filename)==0)
		//user cancelled, abort
		SetDataFolder root:
		DoAlert 0, "No file selected, action aborted"
		return(1)
	Endif
	
	Variable t1=ticks
	
	variable error
	String errorMsg
	
	error=ReadHeaderAndData(filename)	//this is the full Path+file

	if (error < 0)
		String windowName =""
		switch(error)					// fileID holds the return code; check it
			case -1:			
				//errorMsg = filename+ ": \r\t Failed to parse XML..."		//No Alert for this case...
				break
			case -2:			
				//errorMsg = filename+ ": \r\t Either not found or cannot be opened for reading..."		//No Alert for this case...
				break
			case -3:
				errorMsg =  "\r\t XMLutils needs an upgrade:  http://www.igorexchange.com/project/XMLutils"
				break
			case -4:
				errorMsg = filename+ " ===> Not supported version of xml or SPICE..."	
				break
		endswitch
		SetDataFolder root:
		//print "Failed loading", filename, "..."
		DoAlert 0, errorMsg
		//Clean up waves...
		//KillWaves/Z M_listAttr, nsList,W_xmlcontentnodes
		return(1)		//Do not change.
	endif
///***** done by a call to UpdateDisplayInformation()
//	//the calling macro must change the display type
//	String/G root:myGlobals:gDataDisplayType="RAW"		//displayed data type is raw
//	
//	//data is displayed here
//	fRawWindowHook()
	SetDataFolder root:
	
	Print "Time to load and display (s) = ",(ticks-t1)/60.15
	Return(0)		//Do not change.
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
Function ReadHeaderAndData(filename)
	String filename
	
	String curPath = "root:Packages:NIST:RAW:"	
	//***NOTE ****
	// the "current path" gets mysteriously reset to "root:" after the SECOND pass through
	// this read routine, after the open dialog is presented
	// the "--read" waves end up in the correct folder, but the data does not! Why?
	//must re-set data folder before writing data array (done below)
	SetDataFolder curPath	
	//full filename and path is now passed in...
	//actually open the file
	//Open/R refNum as fname
	STRING/G errorMsg	
	Variable refNum,t1=ticks
	//print "Loading", filename, "..."	
	if (stringmatch(filename,"*.xml") <1)
		//print "\r  ==> Failed: Not a *.xml file."
		return (-1)				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(filename)	
	if (refNum < 0)
		XmlCloseFile(refNum,0)
		//print "\r  ==> Failed: Not a standard xml file format."
		return (-2) 				//Not a xml file. Do nothing...
	endif
	
	/////////////////////////////////////////////////////////////////////////////////////////////////\/\/\/\/ from P. R. Jemian	
	//	test to see if XMLutils has the needed upgrade
	XMLlistXpath(refNum, "/*", "")	
	IF ( EXISTS( "M_listXPath" ) == 0 )
		XmlCloseFile(refNum,0)
		//errorMsg = "XMLutils needs an upgrade:  http://www.igorexchange.com/project/XMLutils"
	
		SetDataFolder root:
		RETURN(-3)						// XOPutils needs an upgrade
	ENDIF
	///////////////////////////////////////////////////////////////////////////////////////////////\/\/\/\ from P. R. Jemian
	
	// Check if  it is the SPICE version = 1.1
	String ns_ver = "1.1"
	Variable ns = 0
	ns = str2num(XMLstrFmXpath(refNum, "//SPICErack/@SPICE_version","",""))
	
	// older version	
	if (ns <1.1)
		//errorMsg = filename + ": This SPICE version is not supported"
		XmlCloseFile(refNum,0)
		SetDataFolder root:
		return (-4)
	endif
	
	//this function is for reading in RAW data only, so it will always put data in RAW folder
	
	String curFolder="RAW"
	SetDataFolder curPath		//use the full path, so it will always work
	Variable/G root:Packages:NIST:RAW:gIsLogScale = 0		//initial state is linear, keep this in RAW folder
	Variable integer,realval
	String sansfname,textstr
	
	Make/O/N=23 $"root:Packages:NIST:RAW:IntegersRead"
	Make/O/N=52 $"root:Packages:NIST:RAW:RealsRead"
	Make/O/T/N=11 $"root:Packages:NIST:RAW:TextRead"
	
	Wave intw=$"root:Packages:NIST:RAW:IntegersRead"
	Wave realw=$"root:Packages:NIST:RAW:RealsRead"
	Wave/T textw=$"root:Packages:NIST:RAW:TextRead"
	
	//Make/O/N=16384 $"root:Pacakges:NIST:RAW:data"
	//WAVE data=$"root:Packages:NIST:RAW:data"
	
	//intw = 0
	//realw = 0
	//textw = ""
	
	
	//Redimension/N=(192,192) data			//NIST raw data is 128x128 - do not generalize
	//data =0
	
	//ORNL HFIR SANS DATA
	String tempheadhfir =""
       ReadHFIRSansRaw(refNum,curFolder,tempheadhfir) 

       //Take the file name from "actual file name", not from the header: (JC found some cases that those are different.)
       //This  can be removed where the problem is solved....
       textw[0]=GetFName(filename,  1)

	SetDataFolder curPath
	String/G fileList = textw[0]
	//return the data folder to root
	
	WAVE data=$"root:Packages:NIST:RAW:data"
	Duplicate/O data linear_data			// data is "fresh" and linear scale, so copy it now
		
	// proper error for counting statistics, good for low count values too
	// rather than just sqrt(n)
	// see N. Gehrels, Astrophys. J., 303 (1986) 336-346, equation (7)
	// for S = 1 in eq (7), this corresponds to one sigma error bars
	Duplicate/O linear_data linear_data_error
	linear_data_error = 1 + sqrt(linear_data + 0.75)				
	//
	
	SetDataFolder root:

	Return 0

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
	
	String fname = PromptForPath("Select detector sensitivity file")
	ReadHeaderAndWork("DIV",fname)		//puts what is read in work.div
	
	String waveStr = "root:Packages:NIST:DIV:data"
	NewImage/F/K=1/S=2 $waveStr		//this is an experimental IGOR operation
	ModifyImage '' ctab= {*,*,YellowHot,0}

	String/G root:Packages:NIST:DIV:fileList = "WORK.DIV"
	
	SetDataFolder root:		//(redundant)
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
	String curPath = "root:Packages:NIST:"+cur_folder
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
	if (stringmatch(fname,"*.xml") <1)
		return 0				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(fname)	
	if (refNum < 0)
		XMLclosefile(refNum, 0)
		return 0 				//Not a xml file. Do nothing...
	endif
	
	//ORNL HFIR SANS DATA
	String tempheadhfir =""
       ReadHFIRSansRaw(refNum,cur_folder,tempheadhfir) 

	//Take the file name from "actual file name", not from the header: (JC found some cases that those are different.)
       //This  can be removed where the problem is solved....
       textw[0]=GetFName(fname,  1)
	
	//keep a string with the filename in the DIV folder
	String/G $(curPath + ":fileList") = textw[0]

	WAVE data=$"root:Packages:NIST:RAW:data"
	Duplicate/O data $"root:Packages:NIST:RAW:linear_data"			// data is "fresh" and linear scale, so copy it now
	
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

	Duplicate/O data linear_data_error
	linear_data_error = 1 + sqrt(data + 0.75)
	
	//just in case there are odd inputs to this, like negative intensities
	WaveStats/Q linear_data_error
	linear_data_error = numtype(linear_data_error[p]) == 0 ? linear_data_error[p] : V_avg
	linear_data_error = linear_data_error[p] != 0 ? linear_data_error[p] : V_avg
		
	//linear_data = data
	
	KillWaves/Z temp0 
	Close/A
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

	String/G $("root:"+destFolder+":fileList") = tempStr
	textw[0] = tempStr		//filename
	textw[1] = junkStr		//run date-time
	
	tempStr = hdr[1]
	tempStr = tempStr[0,strlen(tempStr)-2]		//clean off the last LF

	textW[6] = tempStr	//sample label
	
	return(0)
End

// read specific bits of information from the header
// each of these operations MUST take care of open/close on their own

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


Function/S getStringFromHeader(fname,wantedterm)
	String fname, wantedterm				//full path:name, term name
	
	String str = ""
	Variable refNum,i
	
	//check the ext.
	if (stringmatch(fname,"*.xml") <1)
		//print "Failed: Not a *.xml file."
		return (str)				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(fname)	
	if (refNum < 0)
		//print "Failed: Not a xml file."
		XmlCloseFile(refNum,0)
		return (str) 				//Not a xml file. Do nothing...
	endif

	//ORNL HFIR SANS strings meta DATA
	if (stringmatch("*filename",wantedterm)>0)
		str =GetFName(fname,  1)
	else
      		str=ReadSFromHHead(refNum,wantedterm)  //Get it from the header.
       endif
	
	//return the data folder to root
	//SetDataFolder root:
		
	return(str)
End

// file suffix (NCNR data file name specific)

// file suffix (13 characters @ byte 19)
Function/S getSuffix(fname)
	String fname
	
	return(getStringFromHeader(fname,"//suffix"))		//!!!!!!!!!!!!!!!!!!!!!!!!!
End

// associated file suffix (for transmission)

Function/S getAssociatedFileSuffix(fname)
	String fname
	
	return(getStringFromHeader(fname,"//assoc_suffix"))		//!!!!!!!!!!!!!!!!!!!!!!!!!
End

// sample label (60 characters @ byte 98)
Function/S getSampleLabel(fname)
	String fname
	
	return(getStringFromHeader(fname,"//Header/Scan_Title"))
End

// file creation date (20 characters @ byte 55)
Function/S getFileCreationDate(fname)
	String fname
 
	return(getStringFromHeader(fname,"//SPICErack/@start_time"))
End

// Check if the file is transmission file?
Function/S getIsTrans(fname)
	String fname
	return(getStringFromHeader(fname,"//Header/Transmission"))
End

// read a single real value with GBLoadWave
Function getRealValueFromHeader(fname,wantedterm,unit)
	String fname, wantedterm,unit
	
	Variable vresult
	Variable refNum
	
	if (stringmatch(fname,"*.xml") <1)
		//print "Failed: Not a *.xml file."
		return 0				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(fname)	
	if (refNum < 0)
		//print "Failed: Not a xml file."
		return 0 				//Not a xml file. Do nothing...
	endif

	//ORNL HFIR SANS strings meta DATA
       vresult=ReadVFromHHead(refNum,wantedterm,unit) 
	
	return(vresult)
End

//monitor count is at byte 39
Function getMonitorCount(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Counters/monitor",""))
end

//saved monitor count is at byte 43
Function getSavMon(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Counters/monitor",""))  //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!??
end

//detector count is at byte 47
Function getDetCount(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Counters/psd",""))   //Need to check!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end

//Attenuator number is at byte 51
Function getAttenNumber(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Motor_Positions/attenuation","percent")) //in unit of percents
end

//transmission is at byte 158
Function getSampleTrans(fname)
	String fname
	return(getRealValueFromHeader(fname,"//Transmission_for_Sample",""))
end

//box counts are stored at byte 494
Function getBoxCounts(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Box_Counts",""))  		
end

//whole detector trasmission is at byte 392
Function getSampleTransWholeDetector(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Counters/detector","")) //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end

//SampleThickness is at byte 162
Function getSampleThickness(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/Sample_Thickness","cm"))
end

//Sample Rotation Angle is at byte 170
Function getSampleRotationAngle(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"",""))			//ToDo: define this...
end

//temperature is at byte 186
Function getTemperature(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Parameter_Positions/tsample","C"))   
end

//field strength is at byte 190
Function getFieldStrength(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//magnetic_field","G"))
end

//beam xPos is at byte 252
Function getBeamXPos(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/beam_center_x_pixel",""))
end

//beam Y pos is at byte 256
Function getBeamYPos(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/beam_center_y_pixel",""))
end

//sample to detector distance is at byte 260
Function getSDD(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Motor_Positions/sample_det_dist","m"))
end

//detector offset is at byte 264
Function getDetectorOffset(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Motor_Positions/detector_trans","cm"))  //cm:  HFIR mm
end

//Beamstop diameter is at byte 272
Function getBSDiameter(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Motor_Positions/beam_trap_size","mm"))  //check if this beamstop diameter?
end

//source aperture diameter is at byte 280
Function getSourceApertureDiam(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/source_aperture_size","mm"))
end

//sample aperture diameter is at byte 284
Function getSampleApertureDiam(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/sample_aperture_size","mm"))
end

//source AP to Sample AP distance is at byte 288
Function getSourceToSampleDist(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/source_distance","m")) //unit=m   :hfir = mm
end

//wavelength is at byte 292
Function getWavelength(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/wavelength", "A"))
end

//wavelength spread is at byte 296
Function getWavelengthSpread(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/wavelength_spread",""))
end

//transmission detector count is at byte 388
Function getTransDetectorCounts(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Counters/detector",""))   
end

//detector pixel X size is at byte 220
Function getDetectorPixelXSize(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/x_mm_per_pixel","mm"))
end

//detector pixel Y size is at byte 232
Function getDetectorPixelYSize(fname)
	String fname
	
	return(getRealValueFromHeader(fname,"//Header/y_mm_per_pixel","mm"))
end

//total count time is at byte 31	
Function getCountTime(fname)
	String fname
	Variable mtime
	
	mtime = getRealValueFromHeader(fname,"//Counters/time","")
	if (mtime == 0)
		mtime = 1		//get rid of a singular for calculating a rate in case.
	endif 
	return(mtime)
end

//////  integer values
//////Not used !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Function getIntegerFromHeader(fname,wanted)   ///Not used !!!!!!!!!
	String fname				//full path:name
	String wanted		//starting byte

	Variable refNum	                                                               
	Variable vresult
	
	if (stringmatch(fname,"*.xml") <1)
		//print "Failed: Not a *.xml file."
		return 0				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(fname)
	XMLclosefile(refNum, 0)
	if (refNum < 0)
		//print "Failed: Not a xml file."
		return 0 				//Not a xml file. Do nothing...
	endif

	//ORNL HFIR SANS strings meta DATA
       vresult=ReadVFromHHead(refNum,wanted, "") 
		
	return(0)
End
//////////////////////////////////////////////////////////////////////////////////

//reads the wavelength from a reduced data file (not very reliable)
// - does not work with NSORTed files
// - only used in FIT/RPA (which itself is almost NEVER used...)
//
Function GetLambdaFromReducedData(tempName)
	String tempName
	
	String junkString
	Variable lambdaFromFile, fileVar, junkVal
	lambdaFromFile = 6.0

	Open/R/P=catPathName fileVar as tempName
	FReadLine fileVar, junkString
	FReadLine fileVar, junkString
	FReadLine fileVar, junkString
	if(strsearch(LowerStr(junkString),"lambda",0) != -1)
		FReadLine/N=11 fileVar, junkString
		FReadLine/N=10 fileVar, junkString
		sscanf  junkString, "%f",junkVal

		lambdaFromFile = junkVal
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
	
	Variable refnum
	String tmpFile = FindValidFilename(fname)
	// tmpFile is only a parital path
	
	// return your bounding box coordinates or default values of 0
	x1=getRealValueFromHeader(fname,"//XYBox_x1","")
	x2=getRealValueFromHeader(fname,"//XYBox_x2","")
	y1=getRealValueFromHeader(fname,"//XYBox_y1","")
	y2=getRealValueFromHeader(fname,"//XYBox_y2","")
	
	if (x1 == -1 || x2 == -1 || y1 == -1 || y2 == -1)
		x1 = 0
		x2 = 0
		y1 = 0
		y2 = 0
	endif
	
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
	
	// your code to write bounding box to the header, or nothing
	String x1str = "", x2str = "", y1str = "", y2str = ""
	sprintf x1str, "%d", x1
	sprintf x2str, "%d", x2
	sprintf y1str, "%d", y1
	sprintf y2str, "%d", y2

	WriteHFIRHead(fname,x1str,"/SPICErack/XYBox_x1" ,"") 	
	WriteHFIRHead(fname,x2str,"/SPICErack/XYBox_x2" ,"") 
	WriteHFIRHead(fname,y1str,"/SPICErack/XYBox_y1" ,"") 
	WriteHFIRHead(fname,y2str,"/SPICErack/XYBox_y2" ,"") 
	
	return(0)
End

// for transmission calculation, writes an NCNR-specific alphanumeric identifier
// (suffix of the data file)
//
Function WriteAssocFileSuffixToHeader(fname,suffix)
	String fname,suffix
		
	
	WriteHFIRHead(fname,suffix,"/SPICErack/assoc_suffix" ,"text") 
	return(0)
end


//// ==================================================================
//Keep these functions in case NIST changes: We need these...
// TrimWhiteSpace (code from Jon Tischler)
Function/T   HFIR_TrimWS(strg)
   
   String strg
   return HFIR_TrimWSL(HFIR_TrimWSR(strg))
End

Function/T   HFIR_TrimWSL(strg)
    String strg
    Variable i, N=strlen(strg)
    for (i=0;char2num(strg[i])<=32 && i<N;i+=1)    // find first non-white space
    endfor
    return strg[i,Inf]
End

Function/T   HFIR_TrimWSR(strg)
    String strg
    Variable i
    for (i=strlen(strg)-1; char2num(strg[i])<=32 && i>=0; i-=1)    // find last non-white space
   endfor
    return strg[0,i]
End
//// ==================================================================

Function ReadHFIRRaw(refNum,prtname,pname)   //NOT USED!!!!!!!!
	Variable refNum
	String pname, prtname
	
	//temp list of ns
	MAKE/T/N=(1)/O nsList
	nsList[0] = "1.1" 
	
	// Check if  it is the SPICE version = 1.1
	Variable  item,i
	String thislocation, ns=""
	Variable nns

	for (item = 0; item < DimSize(nsList, 0); item += 1)		// loop over all possible namespaces
		XMLlistAttr(refNum, prtname, nsList[item])
		wave/T M_listAttr
	
		for (i = 0; i < DimSize(M_listAttr,0); i+=1)			// loop over all available attributes
			// Expect the required hfir XML header (will fail if "schemalocation" is not found)
			if ( CmpStr(  LowerStr(M_listAttr[i][1]),  LowerStr(pname) ) == 0 )
				thisLocation = HFIR_TrimWS(M_listAttr[i][2])
				if ( StringMatch(thisLocation, nsList[item] + "*") )
					ns = nsList[item]
					Break
				endif
			endif
		endfor
		if (strlen(ns))
			Break		
		endif
	endfor
	sscanf ns,"%f",nns
return nns
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//       Read ORNL HFIR SANS data ( xml format) file:general loading from display raw data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function ReadHFIRSansRaw(refNum,curFolder,tempheadhfir)
    Variable refNum
    String curFolder,tempheadhfir
      
	String curPath="root:Packages:NIST:"+curFolder
  	SetDataFolder curPath
	Make/O/N=23 $(curPath+":IntegersRead")
	Make/O/N=52 $(curPath+":RealsRead")
	Make/O/T/N=11 $(curPath+":TextRead")
	
	Wave intw=$(curPath+":IntegersRead")
	Wave realw=$(curPath+":RealsRead")
	Wave/T textw=$(curPath+":TextRead")
	
	Variable ind,i,j,centerdata=1
	Variable pixnumx=0,pixnumy=0
	String val = "", pix_num = ""// numerical and text values
	Variable value = 0.0,t1=ticks
	String unitstr =""	//unit string

	//Initialize wave values	 
	 realw=0
	 intw=0
	 textw=""
	 textw[2]=curFolder
	 textw[3]=""
	 textw[4]="C"   			     ///???
	 textw[7]="C"                        // temperature unit C
	 textw[10]="xml"			//HFIR SANS RAW data file extension
	 realw[4]  = 1				//Default for transmission for sample
	 realw[12]=0.00                       //following 6 values are for non-linear spatial corrections to a detector (RC timing)
	 realw[15]=0.00                        // 10 and 13 are the X and Y pixel dimensions,,(11,12 and 13,14 are set to values for a linear response, as from a new Ordela detector)
	 realw[11]=10000.00                          //nonlinear spatial pix(x) //Do not change unless knowing what you are doing...
	 realw[14]=10000.00                          //nonlinear spatial pix(y)
	 // detector physical width (right now assumes square...) (in cm)
	 // beam stop X-position (motor reading, approximate cm from zero position)
	 // currently NCNR-specific use to identify transmission measurements
	 // you return 0
	 realw[37] = 0
 	 //textw[2]="RAW"      //????
  
//	Print "Time to list attributes (s) = ",(ticks-t1)/60.15
//	Print "Time to list elements (s) = ",(ticks-t1)/60.15

	// Get and set the number of pixels from the line just above data.
 	pix_num = XMLstrFmXpath(refNum,"//Data/Detector/@type","","")
	pixnumx=Str2num(StringFromList(0,StringFromList(1,pix_num ,","),"]"))   
	pixnumy=Str2num(StringFromList(1,StringFromList(0,pix_num ,","),"["))
	Variable/G root:myGlobals:gNPixelsX=pixnumx
	Variable/G root:myGlobals:gNPixelsY=pixnumy	
	SetDataFolder curPath

			//******Below deleted since HFIR prefers to use <Data type="INT32[xxx,xxx]" for pixnumbers
			//********Leave the following lines in case they change the policy.
			//if (stringmatch(tempheadhfir,"Number_of_X_Pixels")>0)			
	   	 	//	pixnumx=Str2num(val)     
	   	 	//	Variable/G root:myGlobals:gNPixelsX=pixnumx	
	   	 	//	 SetDataFolder curPath
	   	 	//elseif  (stringmatch(tempheadhfir,"Number_of_Y_Pixels")>0)
	   	 	//	pixnumy=Str2num(val) 
	   	 	//	Variable/G root:myGlobals:gNPixelsY=pixnumy
	   	 	//	 SetDataFolder curPath
	   	 	// Note for units: If in-unit is null, out will be unity.
	   	 	textw[6] = XMLstrFmXpath(refNum,"//Header/Scan_Title","","")
   	 	
	   	 	textw[3] = XMLstrFmXpath(refNum,"//Header/Users","","")		//ToDo: Define	 
	   	 		
	   	 	textw[9] = XMLstrFmXpath(refNum,"//Header/Instrument","","")				//ToDo: Define
	   	 	
	   	 	value = ValfromUnit(refNum,"//Transmission_for_Sample","")
	   	 	if (value <= 0)
	   	 		value = 1 		//HFIR default = -1 while NIST package not working if it is <=0: Set default =1. <=NOT good!!!
	   	 	endif
	   	 	realw[4] = value
	   	 	
	   	 	realw[3] = ValfromUnit(refNum,"//Motor_Positions/attenuation","percent") 
	   	 	realw[8] = ValfromUnit(refNum,"//Parameter_Positions/tsample","C") 
	   	 	realw[0] = ValfromUnit(refNum,"//Counters/monitor","") 
	   	 	realw[5] = ValfromUnit(refNum,"//Header/Sample_Thickness","cm") 
	   	 	realw[2] = ValfromUnit(refNum,"//Counters/psd","")       ////Need to check!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			realw[10] = ValfromUnit(refNum,"//Header/x_mm_per_pixel","mm")  
			realw[13] = ValfromUnit(refNum,"//Header/y_mm_per_pixel","mm")  
			Variable/G root:myGlobals:PixelResDefault = unit_convert(realw[13],"mm","cm") //back to cm unit for this default value??!!
	   	 	SetDataFolder curPath
	   	 	
	   	 	realw[16] = ValfromUnit(refNum,"//Header/beam_center_x_pixel","")  
	   	 	realw[17] = ValfromUnit(refNum,"//Header/beam_center_y_pixel","")  
	   	 	realw[21] = ValfromUnit(refNum,"//Motor_Positions/beam_trap_size","mm")    //what is different from the beam trap diameter in the file???
	   	 	realw[18] = ValfromUnit(refNum,"//Motor_Positions/sample_det_dist","m") 
			intw[1]  = ValfromUnit(refNum,"//Counters/time","sec")     //Not supported. Assumed in "sec"
			intw[2] = intw[1] //???
			realw[23]  = ValfromUnit(refNum,"//Header/source_aperture_size","mm")      //diameter???
			realw[24]  = ValfromUnit(refNum,"//Header/sample_aperture_size","mm")      //diameter???
	   	 	realw[25]  = ValfromUnit(refNum,"//Header/source_distance","m") 	
	   	 	realw[26]  = ValfromUnit(refNum,"//Header/wavelength","a") 	
	   	 	realw[27]  = ValfromUnit(refNum,"//Header/wavelength_spread","") 	
			
			//Set pixel numbers 
	   	 	//SetDataFolder curPath
	   	 	NVAR pixnumx1= root:myGlobals:gNPixelsX	   	 	     
	   	 	NVAR pixnumy1= root:myGlobals:gNPixelsY
	   	 	Variable pixnx = pixnumx1, pixny = pixnumy1
	   	 	realw[20] = realw[10]*pixnx/10.0 			// physical detector width  in cm  // ToDo: Need to check for ypix size???
	   	 	
	   	 	//prepare to get data
      			Make/O/N=(pixnumx1*pixnumy1) $(curPath+":data")
			WAVE  data=$(curPath+":data")
			//set the globals to the detector dimensions (pixels)
			Redimension/N=(pixnx,pixny) data			//ORNL pixnums are given from the data file
			Variable intens = 0
	
			// Read 2d data
			XMLwaveFmXpath(refNum,"/SPICErack/Data/Detector",""," \t\n\r")
			WAVE/T M_xmlContent
	   	 	for (i=0;i<pixnx;i+=1)
	   	 		for  (j=0;j<pixny;j+=1)
	   	 			sscanf M_xmlContent[j+i*pixny],"%i", intens
	   	 			data[i][j]=intens
	   	 		endfor
	   	 	endfor
	   	 	

	   	 	
	   	 	///////unit test 1/2//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	   	 	//if  (stringmatch(tempheadhfir,"Detector")<1 ||stringmatch(tempheadhfir,"data"))
	   	 	//	print tempheadhfir+"="+val+"["+unitstr+"]"
	   	 	//endif
	   	 	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		


	  //If the data is a sensitivity data, need to be narmalize so that the average over the detector should be 1.
	 If (stringmatch(curFolder, "DIV") >0)
	 	//Variable V_avg
	 	 WaveStats/Z/Q data
	  	data /= V_avg
	  endif
	   	 	

	//keep a string of the filename in the RAW folder
	
	Variable strpos
		
	textw[0] = RemoveAllSpaces(XMLstrFmXpath(refNum,"//SPICErack/@filename","","") )    //////ShortFileName(RemoveAllSpaces(XMLstrFmXpath(refNum,"//SPICErack/@filename","","") )  )         // file name
	textw[1] =   XMLstrFmXpath(refNum,"//SPICErack/@start_time","","")		//Date and Time
	textw[5]=StringFromList(0,textw[1]," ")  									//Date
	
	//String/G $(curPath+":FileList") = textw[0]
	
	///////unit test 2/2//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//SetDataFolder curPath
	//print "****** ["+num2str(pixnx)+","+num2str(pixny)+"]*******"
	//for (i=0;i<Dimsize(textw,0);i+=1)
	//	print "textw["+num2str(i)+"] ="+textw[i]
	//endfor
	//for (i=0;i<Dimsize(realw,0);i+=1)
	//	print "realw["+num2str(i)+"] ="+num2str(realw[i])
	//endfor
	//for (i=0;i<Dimsize(intw,0);i+=1)
	//	print "intw["+num2str(i)+"] ="+num2str(intw[i])
	//endfor
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// We have everything from file: Need to close the file soon as possible
	XMLclosefile(refNum, 0)	
	SetDataFolder curPath
	Killwaves/Z M_listXPath
End

/// Get real value in NIST unit ///////////////////////////////////////////////////////////////////////////////////////////////////
Function ValfromUnit(refNum,wantedterm,NISTunit)
	Variable refNum    //FileID
	String wantedterm,NISTunit  //Xpath, value in string, unit from HFIR, unit from NIST
	
	String val="", unitstr=""
	Variable value = 0.0 
	//SetDataFolder curPath ////????????/
	
	val =   XMLstrFmXpath(refNum,wantedterm,"","")

	// Case of no value or zero value, check if written by HFIR Patch
	if (stringmatch(wantedterm,"//*")>0&& strlen(val) ==0)
	   	 wantedterm = "//" +  StringFromList(3, wantedterm,"//")
	   	 // if valid wnatedterm
	   	 if (strlen(wantedterm) >1)
	   	 	val =   XMLstrFmXpath(refNum,wantedterm,"","")
	   	 endif
	endif	
	unitstr =  RemoveAllSpaces(XMLstrFmXpath(refNum,wantedterm+"/@units","",""))
	
	//The units of the source_distance is treated special...
	if (stringmatch(wantedterm,"*source_distance")>0 )
		if  (strlen(unitstr)==0)
	   	 	unitstr = "mm" 		//Give mm unit since no unit is provided from the file. ///This needs to be corrected soon!!!!
	   	 endif
	endif
	//String to double
	sscanf val, "%f", value
	Variable data
	data = unit_convert(value,unitstr,NISTunit)

	return data
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Read Real Values from HFIR data  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function ReadVFromHHead(refNum,wantedterm,NCunit) 
      Variable refNum
      String wantedterm, NCunit
      
      Variable vresult=-1  // (wantedterm=="", return -1)
	Variable ind=0,i=0, value = 0
	String  ntype = ""
	String savedDataFolder = GetDataFolder(1)
	//Default for transmission rate (between 0 to 1): HFIR not provide this as a Float number???? ==>make one: if exist, read it below.
	if (stringmatch(wantedterm,"//Transmission_for_Sample")>0)
		vresult=1		
	endif
	
	String unitstr = "", typestr="",tempheadhfir="", val=""

	if (stringmatch(wantedterm,"") >0 ) // set zero if wnatedterm is "" ,not defined(eg., rotation angle).
		vresult =0
		//close here
		XMLclosefile(refNum, 0)
		return vresult
	else
		//Find the value,unit, and type of the value: a little ugly but faster...
		val =   XMLstrFmXpath(refNum,wantedterm,"","")
		// Case of no value or zero value, check if it written by HFIR Patch
		if (stringmatch(wantedterm,"//*")>0&& strlen(val) ==0)
	   	 	wantedterm = "//" +  StringFromList(3, wantedterm,"//")
	   	 	// if valid wnatedterm
	   	 	if (strlen(wantedterm) >1)
	   	 		val =   XMLstrFmXpath(refNum,wantedterm,"","")
	   	 	endif
	   	endif
		unitstr =  RemoveAllSpaces(XMLstrFmXpath(refNum,wantedterm+"/@units","",""))
		typestr =  RemoveAllSpaces(XMLstrFmXpath(refNum,wantedterm+"/@type","",""))
		//close here
		XMLclosefile(refNum, 0)
	endif
	
	if   (stringmatch(typestr , "INT*")>0)
		ntype = "i"		//INT32
	elseif (stringmatch(typestr , "FLOAT*")>0)
		ntype ="f"		//FLOAT32
	else
		ntype ="s"		//TEXT
	endif	
	
	String ustr ="%f"				//default: float
	if (stringmatch(ntype,"i") > 0)	//for integer	
		ustr = "%d"
	endif	
					
	//Special case starts!!! 
	//No unit found in hfir ("mm") but needs to convert to meters.
	//The following 3 lines should be removed once HFIR puts th units on the raw data files.
	if (stringmatch(wantedterm,"*source_distance")>0&& strlen(unitstr) ==0)
		unitstr = "mm" 		
	endif
	//Special case ends!!!
	
	//Do NOT use str2num(): will loose many decimal digits.
	sscanf val, ustr, value	
	vresult = unit_convert(value,unitstr,NCunit)
	if (stringmatch(wantedterm,"*Transmission_for_Sample")>0 && vresult == 0)
	   	 //Transmission default value if it was set to 0.
	   	 vresult = 1
	endif
	   	 	
	//Set PixResDefault from y_mm_per_pixel (not x_mm_per_pixel!!!!!!!!)
	if (stringmatch(wantedterm,"*y_mm_per_pixel")>0)
	   	 Variable/G root:myGlobals:PixelResDefault = unit_convert(vresult,"mm","cm") //back to cm unit for this default value??!!
	   	 SetDataFolder savedDataFolder		//In case...
	endif

		
      	return (vresult)

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Read Strings from HFIR data  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function/S ReadSFromHHead(refNum,wantedterm) 
      Variable refNum
      String wantedterm
      
      String tempheadhfir = ""
      String result = "",gotterm ="n" ,name
	Variable ind,i

      if   (stringmatch(wantedterm,"")>0) 
      		result = ""
      		XMLclosefile(refNum, 0)
      		return (result)
	endif
	
	result =  XMLstrFmXpath(refNum,wantedterm,"","")
	if (stringmatch(result, "") != -1 )	
		gotterm ="y" 	
	endif

	//HFIR header does not have "suffix" tag but one can get the info from file name before user writes the tag into the header.
	if (stringmatch("",result)>0	 && stringmatch("//suffix",wantedterm)>0 )
		name = RemoveAllSpaces(XMLstrFmXpath(refNum,"//SPICErack/@filename","",""))
	   	result=StringFromList(2,StringFromList(0, name,"."), "_")+"_"+StringFromList(3,StringFromList(0,name,"."), "_")
	endif

	//Close file here.
	XMLclosefile(refNum, 0)
	
	if (stringmatch(gotterm,"n")>0 ) 
		result = ""
	endif	

      return (result)
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//WRITE Real Values to HFIR data file  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function WriteHFIRHead(filename,value,wantedterm,NCunit) 
      
      String filename, value,wantedterm, NCunit //where value is a string...
      
	String valstr
      Variable/D vresult = 0 
      Variable refNum
	Variable ind=0,i=0, vals
	
	Variable typenum = 0
	String ntype = ""	//Do not change this initial, "".
      	String nstr = "/SPICErack" 		//to add new nodes and content: NEVER CAHNGE this string
      	String errorMsg =""
	
	//print "Loading", filename, "..."
	if (stringmatch(filename,"*.xml") <1)
		//print "\r  ==>  Failed: Not a *.xml file."
		return 0				//Not *.xml. Do nothing...
	endif
	//actually open the file
	refNum = XmlOpenFile(filename)	

	if (refNum < 0)
		switch(refNum)					
			case -1:
				errorMsg = errorMsg+filename+ "  ==>  Not a standard xml file format; Please check if the file is not broken..."
			break
			case -2:
				errorMsg = errorMsg+filename+"  ==>  Please check if the file name is same as that written in the header..."
			break
		endswitch
		print errorMsg
		XMLclosefile(refNum, 0)
		return -1 				//Not a xml file. Do nothing...
	endif

		String unitstr = "",typestr="", val=""

		if  (strlen(wantedterm)==0)	
			vresult =0				//If input is NULL, do nothing...
			nstr = ""					//reset as No new node

		else   //(stringmatch(tempheadhfir,wantedterm)>0)	
			val =   XMLstrFmXpath(refNum,wantedterm,"","")
			// if no regular entry is found, check patch entry.
			if (stringmatch(wantedterm,"//*")>0&& strlen(val) ==0)
	   	 		wantedterm = "//" +  StringFromList(3, wantedterm,"//")
	   	 		// if valid wnatedterm
	   	 		if (strlen(wantedterm) >1)
	   	 			val =   XMLstrFmXpath(refNum,wantedterm,"","")
	   	 		endif
	   		endif
			//Special case starts!!! 
			//No unit founds in hfir ("mm") file but needs to convert to meters. Let's give it one.
			if (stringmatch(wantedterm,"*source_distance")>0&& strlen(unitstr) ==0)
				unitstr = "mm" 	
				ntype ="f"	
			//Special case ends!!!
			else
				unitstr =  XMLstrFmXpath(refNum,wantedterm+"/@units","","")
				typestr =  RemoveAllSpaces(XMLstrFmXpath(refNum,wantedterm+"/@type","",""))
	
				ntype ="s"		//TEXT	
				
					if  (strlen(typestr)==0)
						ntype = "s"
					elseif   (stringmatch(typestr, "INT*")>0)
						ntype = "i"		//INT32
					elseif (stringmatch(typestr, "FLOAT*")>0)
						ntype ="f"		//FLOAT32
					endif	
			endif
			
			if (stringmatch(ntype,"s") > 0)	//for strings		
				vresult = 1			
				valstr =value
			else
				String ustr ="%f"				//default: float
				if (stringmatch(ntype,"i") > 0)	//for integer	
					ustr = "%d"
				endif			
				sscanf  value,ustr, vals
	   	 		vresult = unit_convert(vals,NCunit,unitstr)	//Unit correction...(back to the HFIR unit)
	   	 		
				sprintf valstr,ustr, vresult
	   	 	endif
	   	 	
	   	 	if (stringmatch(wantedterm,"/SPICErack/*")>0&& strlen(val) ==0)
	   	 		nstr = "/SPICErack"
	   	 		// remove "/SPICErack/" from wantedterm 
	   	 		wantedterm = StringFromList(2, wantedterm,"/SPICErack/")
	   	 	elseif (stringmatch(wantedterm,"//*")>0&& strlen(val) ==0)
	   	 		nstr = "/SPICErack"
	   	 		//remove'//' to wantedterm 
	   	 		wantedterm = StringFromList(2, wantedterm,"//")
	   	 	else
	   	 		XMLsetNodeStr(refNum,wantedterm,"",valstr)	//to set
	   	 		nstr = ""				//reset as No new node
	   	 	endif
	   	 	//break
	   	 endif		
	//to write new  attr name and value which are not found in the raw file.
	if (strlen(nstr)>2)	 			
		 XMLaddNode(refNum,nstr,"",wantedterm,value,1)
		 // nstr to add new node
		 nstr = "//"+wantedterm
		 // get unit
	   	 if (stringmatch(NCunit,"text")>0)	
	   	 	ntype = "text"
	   	 	vresult = 1
	   	 else
	   	 	XMLsetAttr(refNum,nstr,"","units",NCunit) 	//use NIST units.
	   	 	ntype = "FLOAT32" 						//Let's set the any number as float for now...	
	   	 	sscanf  value, "%f", vals
	   	 	vresult = vals 		
	   	 endif
	   	 //print "*** Note:*** \r     *** No parameter named",wantedterm, "was found, so it was added to the end of your data file."
	   	 XMLsetAttr(refNum,nstr,"","type",ntype)    	
	endif

	//KillWaves/Z W_ElementList,M_xmlContent,M_listXPath,M_listAttr			//clean up
	if	(strlen(wantedterm)==0 && vresult == -1)
		XMLclosefile(refNum, 0)
		//print "Failed writing",wantedterm, "on", filename, "..."
	else
		XMLclosefile(refNum, 1)						//save and close the file.
		//print "Finished writing",wantedterm,"=",value,"[",NCunit,"]  on", filename, "..."
	endif
      	return (vresult)

End


Function UserGetWLPanel_ContButton(cntrlName)
      String cntrlName
      DoWindow /K WaveLengthInput
End

Function Daskcheckbox(cntrlName,checked)
String cntrlName
Variable checked

Wave realw=$"root:RAW:RealsRead"
Variable/G root:myGlobals:globDask=checked
      if (checked==1)
           Variable /G root:myGlobals:globwlfix=realw[26]
           Variable /G root:myGlobals:globdwlfix=realw[27]
      endif

 End
 
 
Function Daskcheckbox1(cntrlName,checked)
String cntrlName
Variable checked

Wave templw=$"root:RAW:tempwave1"
Variable/G root:myGlobals:globDask1=checked
      if (checked==1)
           Variable /G root:myGlobals:globwlfix=templw[0]
           Variable /G root:myGlobals:globdwlfix=templw[1]
      endif

 End
 
//Write whether Transmission is True or False.
Function Write_isTransmissionToHeader(fname,str)
	String fname,str

	WriteHFIRHead(fname,str, "//Header/Transmission","text") 	
	return(0)
End

//sample transmission is a real value at byte 158
Function WriteTransmissionToHeader(fname,trans)
	String fname
	Variable trans

	String transstr = ""
	sprintf transstr, "%f", trans

	 WriteHFIRHead(fname,transstr,"/SPICErack/Transmission_for_Sample" ,"") 		
	return(0)
End

//whole transmission is a real value at byte 392
Function WriteWholeTransToHeader(fname,trans)
	String fname
	Variable trans

	String transstr = ""
	sprintf transstr, "%f", trans

	WriteHFIRHead(fname,transstr,"//Counters/detector" ,"") 	//????????????????????????????????????????????????????????
	return(0)
End

//box sum counts is a real value
// used for transmission calculation module
//box sum counts is a real value at byte 494
Function WriteBoxCountsToHeader(fname,counts)
	String fname
	Variable counts

	String countsstr = ""
	sprintf countsstr, "%f", counts

	WriteHFIRHead(fname,countsstr,"/SPICErack/Box_Counts" ,"") 	
	return(0)
End

//Below units refer to NIST units..
//beam stop X-pos is at byte 368
Function WriteBSXPosToHeader(fname,xpos)
	String fname
	Variable xpos

	String xposstr = ""
	sprintf xposstr, "%f", xpos

	WriteHFIRHead(fname,xposstr,"//Motor_Positions/beam_trap_x","mm") 	///Is this diameter?
	return(0)
End

//sample thickness is at byte 162
Function WriteThicknessToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/Sample_Thickness","cm") 
	return(0)
End

//beam center X pixel location is at byte 252
Function WriteBeamCenterXToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/beam_center_x_pixel" ,"") 
	return(0)
End

//beam center Y pixel location is at byte 256
Function WriteBeamCenterYToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/beam_center_y_pixel","") 
	return(0)
End

//Attenuation (percent) 0 for no attanuation (not its transmission) 
Function WriteAttenNumberToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Motor_Positions/attenuation","percent")  	// HFIR has attenuation % instead of this. thus user has to use patch unless somebody change the format!!!!
	return(0)
End

//monitor count is at byte 39
Function WriteMonitorCountToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Counters/monitor","") 
	return(0)
End

//total detector count is at byte 47
Function WriteDetectorCountToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Counters/psd","") 
	return(0)
End

//transmission detector count is at byte 388
Function WriteTransDetCountToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Counters/detector","")   ///Check with Steve & Ken!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
	return(0)
End

//wavelength is at byte 292
Function WriteWavelengthToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/wavelength" ,"angstroms") 
	return(0)
End

//wavelength spread is at byte 296
Function WriteWavelengthDistrToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/wavelength_spread","") 
	return(0)
End

//temperature is at byte 186
Function WriteTemperatureToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Parameter_Positions/tsample" ,"C") 
	return(0)
End

//magnetic field is at byte 190
Function WriteMagnFieldToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"/SPICErack/magnetic_field","G")  //Not defined on HFIR file...  Should be changed the name when decided...
	return(0)
End

//Source Aperture diameter is at byte 280
Function WriteSourceApDiamToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/source_aperture_size","mm") 
	return(0)
End

//Sample Aperture diameter is at byte 284
Function WriteSampleApDiamToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/sample_aperture_size","mm") 
	return(0)
End

//Source to sample distance is at byte 288
Function WriteSrcToSamDistToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/source_distance","m")     //unit=m   :hfir = mm ???????????????
	return(0)
End

//detector offset is at byte 264
Function WriteDetectorOffsetToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num

	WriteHFIRHead(fname,numstr,"//Header/detector_trans","cm")  //cm:  HFIR = mm !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	return(0)
End

//beam stop diameter is at byte 272
Function WriteBeamStopDiamToHeader(fname,num)
	String fname
	Variable num
	
	String numstr = ""
	sprintf numstr, "%f", num
	
	WriteHFIRHead(fname,numstr,"//Motor_Positions/beam_trap_size","mm")  //check !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	return(0)
End

//sample to detector distance is at byte 260
Function WriteSDDToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num
	
	WriteHFIRHead(fname,numstr,"//Motor_Positions/sample_det_dist","m")
	return(0)
End

//detector pixel X size (mm) is at byte 220
Function WriteDetPixelXToHeader(fname,num)
	String fname
	Variable num

	String numstr = ""
	sprintf numstr, "%f", num
	
	WriteHFIRHead(fname,numstr, "//Header/x_mm_per_pixel","mm")
	return(0)
End

//detector pixel Y size (mm) is at byte 232
Function WriteDetPixelYToHeader(fname,num)
	String fname
	Variable num
	
	String numstr = ""
	sprintf numstr, "%f", num
	
	WriteHFIRHead(fname,numstr, "//Header/y_mm_per_pixel","mm")
	return(0)
End

// sample label
// limit to 60 characters
Function WriteSamLabelToHeader(fname,str)
	String fname,str
	
	if(strlen(str) > 60)
		str = str[0,59]
	endif
	WriteHFIRHead(fname,str, "//Header/Scan_Title","text") //Users tend to put the sample descrpt here instead of "Sample_Name"...
	return(0)
End


Function WriteCountTimeToHeader(fname,num)
	String fname
	Variable num
	
	String numstr = ""
	sprintf numstr, "%f", num
	
	WriteHFIRHead(fname,numstr,"//Counters/time","sec") 
	return(0)
End


/////Handy Unit converter for length & time units"
Function length_unit_convert(from,to)  // input: ("m", cm")==> output=10,....;   input: ("", "") ==> out = 1
	String from, to
	
	Variable i, out
	
	Make/O/T/N=(18,2) munit
	
	//ToDo: to combine the same units	
	//length units 
	munit[0][0]="m"   //popular units first...
	munit[0][1]= "1"
	munit[1][0]="cm" 
	munit[1][1]= "0.01"
	munit[2][0]="mm" 
	munit[2][1]= "0.001"
	munit[3][0]="angstroms"  //HFIR used this rather than A
	munit[3][1]= "1e-10"
	munit[4][0]="meters" 
	munit[4][1]= "1"
	munit[5][0]="um" 
	munit[5][1]= "1e-06"
	munit[6][0]="nm" 
	munit[6][1]= "1e-09"
	munit[7][0]="km" 
	munit[7][1]= "1000"
	munit[8][0]="a" 
	munit[8][1]= "1e-10"
	munit[9][0]="angstrom" 
	munit[9][1]= "1e-10"
	munit[10][0]="microns" 
	munit[10][1]= "1e-6"
	munit[11][0]="meter" 
	munit[11][1]= "1"
	
	//time units
	munit[12][0]="sec" 
	munit[12][1]= "1"
	munit[13][0]="seconds" 
	munit[13][1]= "1"
	munit[14][0]="min" 
	munit[14][1]= "60"
	munit[15][0]="minutes" 
	munit[15][1]= "60"
	munit[16][0]="hrs" 
	munit[16][1]= "3600"
	munit[17][0]="hours" 
	munit[17][1]= "3600"
	//Add more units here...
	 
	String  v_from="", v_to=""
	for (i = 0; i<DimSize(munit,0); i+=1)
		if (stringmatch(munit[i][0],from)>0)  // IgorPro "stringmatch()" function handles both lower & upper cases.
			v_from = munit[i][1]
			break
		endif
	endfor
	
	for (i = 0; i<DimSize(munit,0); i+=1)
		if (stringmatch(munit[i][0],to)>0)
			v_to = munit[i][1]
			break
		endif
	endfor
	
	KillWaves/Z munit
	
	
	if (strlen(v_from)==0 || strlen(v_to) ==0)
		out = 1    		//Do nothing...
	else
		Variable vf, vt
		sscanf  v_to, "%f", vt
		sscanf  v_from, "%f", vf
		out = vf / vt
	endif
	return out
End


///For length and temperature units
Function unit_convert(val, from,to)  // input: ("m", cm")==> output=10,....;   input: ("", "") ==> out = 1
	Variable val
	String from, to

	from = RemoveAllSpaces(from)
	to = RemoveAllSpaces(to)
			
	Variable i, out = val

	//Search for two same strings, or one with none.
	if (stringmatch(from,to)>0 ||strlen(from) == 0||strlen(to)==0) 
		out = val
		
	//Temperature unit: support only C and K
	elseif (stringmatch(from,"C")>0 || stringmatch(to,"K")>0||stringmatch(to,"C")>0 || stringmatch(from,"K")>0)
		out =temp_unit_convert(val, from,to) 
		
	//Length unit                    
	else
		out = val*length_unit_convert(from,to)  						
	endif

	return out
End

//temperature unit converter: Only support K and C.
Function temp_unit_convert(val, from,to)  
	Variable val
	String from, to
	
	Variable i, j, out = val

	Make/O/T/N=(2,2) tunit
	
	tunit[0][0]="C"   //popular units first...
	tunit[0][1]= "-273.15"
	tunit[1][0]="K" 
	tunit[1][1]= "0"	

	String  v_from="", v_to=""

	for (i = 0; i<DimSize(tunit,0); i+=1)
		if (stringmatch(tunit[i][0],from)==1)  // IgorPro "stringmatch()" function handles both lower & upper cases.
			v_from = tunit[i][1]
			break
		endif
	endfor

	for (j = 0; j<DimSize(tunit,0); j+=1)
		if (stringmatch(tunit[j][0],to)==1)
			v_to = tunit[j][1]
			break
		endif	
	endfor	
	KillWaves/Z tunit
	if (strlen(v_from)==0 || strlen(v_to) ==0)
		out = 1    		//Do nothing...
	else
		Variable vt, vf
		sscanf  v_to, "%f", vt
		sscanf  v_from, "%f", vf
		out = val + (vt - vf)
	endif
	return out
End


///This function make HFIR SANS data file shorter which is more than 30 characters causing problem taking other names after the file name.
//Will remove instrumental name.
Function/S ShortFileName(fileName)
	String fileName
	//Default: just passing
	String fname = fileName

	//Check whether it is from HiResSANS or BioSANS and remove the head
	if (stringmatch(fileName,"HiResSANS_*.*")>0 )
		fname = ReplaceString("HiResSANS_",fname,"HS_",0,1)    
	elseif (stringmatch(filename,"BioSANS_*.*")>0)
		fname = ReplaceString("BioSANS_",fname,"BS_",0,1)     
	endif
	return fname
END

//Not used
///This function return the original HFIR SANS data file name that was shorten before.
//Put them back to HiResSANS*** or BioSANS***.
Function/S FullFileName(fname)
	String fname
	//Default: just passing
	String fileName = fname
	
	//Check whether it is from HiResSANS or BioSANS
	if (stringmatch(fname,"*HS_*.*")>0 )
		fileName = ReplaceString("HS_",fname,"HiResSANS_",0,1)  
	elseif (stringmatch(fname,"*BS_*.*")>0)
		fileName = ReplaceString("BS_",fname,"BioSANS_",0,1)   
	endif

	return fileName
END


///Find file name from full Path+file 
Function/S GetFName(path,  length)
	String path
	Variable length // 1 for full name, 0 for shorten name, others pass the name
	
	Variable index 
	String ofname, mfname
	
	// get index of the file name
	index = ItemsInList(path,":") - 1
	// get file name
	ofname = StringFromList(index,path,":")
	//modify the name if need otherwise return w/o change
	if (length == 0)
		mfname = ShortFileName(ofname)
	elseif (length == 1)
		mfname = FullFileName(ofname)
	else
		mfname = ofname
	endif
	// return the path+modified file name
	return mfname
End


///Find file name from full Path+file and replace file name to a shorter or full name in path+file.
Function/S ReplaceFName(path,  length)
	String path
	Variable length // 1 for full name, 0 for shorten name
	
	Variable index 
	String ofname,mfname
	
	// get index of the file name
	index = ItemsInList(path,":") - 1
	// get file name
	ofname = StringFromList(index,path,":")
	//modify the name if need otherwise return w/o change
	if (length == 0)
		mfname = ShortFileName(ofname)
	else
		mfname = FullFileName(ofname)
	endif
	// return the path+modified file name
	return ReplaceString(ofname,path,mfname,0,1)
End

////Unused ///Not working well
// Change file name before and after Xml open
Function/S XmlFileOpen(fname)
	String fname
	
	// fname = path + full file name
	fname = ReplaceFName(fname,  1)
	XmlOpenFile(fname)
	// path + short file name
	return ReplaceFName(fname,  0)
End


////// OCT 2009, facility specific bits from ProDiv()
//"type" is the data folder that has the corrected, patched, and normalized DIV data array
//
// the header of this file is rather unimportant. Filling in a title at least would be helpful/
//
Function Write_DIV_File(type)
	String type
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	
	return(0)
End

////// OCT 2009, facility specific bits from MonteCarlo functions()
//"type" is the data folder that has the data array that is to be (re)written as a full
// data file, as if it was a raw data file
//
// not really necessary
//
Function Write_RawData_File(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	Print "Write_RawData_File stub"
	
	return(0)
End
