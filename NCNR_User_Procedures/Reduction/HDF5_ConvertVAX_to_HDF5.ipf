#pragma rtGlobals=1		// Use modern global access method.

//
// DON'T TOSS THIS FILE-- THERE ARE USEFUL PROCEDURES HERE
// -- some that may be in use elsewhere in reading/writing of HDF files



//
//
// crudely converts the VAX format as read into RAW into an HDF5 file
//
// Not any thought was given to HDF5 structure
//
// the simple read/write works...
// linear_data does not seem to need to be transposed at all
//
//  -- this seems too easy. what am I doing wrong? Is something getting garbled when I 
// write back any single values back to the file
//
// -- try a string value next
//


// lays out the tree

Function SetupStructure()

	SetDataFolder root:
	
	NewDataFolder/O root:entry1
	NewDataFolder/O root:entry1:Run1
	NewDataFolder/O root:entry1:Run1:Sample
	NewDataFolder/O root:entry1:Run1:Run
	NewDataFolder/O root:entry1:Run1:Detector
	NewDataFolder/O root:entry1:Run1:Instrument
	NewDataFolder/O root:entry1:Run1:Analysis


	SetDataFolder root:entry1
    Make/O/T/N=1 filename
    
	SetDataFolder root:entry1:Run1
      	Make/O/T/N=1 runLabel

	SetDataFolder root:entry1:Run1:Sample
// SAMPLE      
        Make/O/D/N=1 TRNS
        Make/O/D/N=1 THK
        Make/O/D/N=1 POSITION
        Make/O/D/N=1 ROTANG
        Make/O/I/N=1 TABLE
        Make/O/I/N=1 HOLDER
        Make/O/I/N=1 BLANK
        Make/O/D/N=1 TEMP
        Make/O/D/N=1 FIELD
        Make/O/I/N=1 TCTRLR
        Make/O/D/N=1 MAGNET
        Make/O/T/N=1 TUNITS
        Make/O/T/N=1 FUNITS

	SetDataFolder root:entry1:Run1:Run
// RUN
        Make/O/I/N=1 NPRE
        Make/O/I/N=1 CTIME
        Make/O/I/N=1 RTIME
        Make/O/I/N=1 NUMRUNS
        Make/O/D/N=1 MONCNT
        Make/O/D/N=1 SAVMON
        Make/O/D/N=1 DETCNT
        Make/O/D/N=1 ATTEN
        Make/O/T/N=1 TIMDAT
        Make/O/T/N=1 TYPE
        Make/O/T/N=1 DEFDIR
        Make/O/T/N=1 MODE
        Make/O/T/N=1 RESERVE
//        Make/O/T/N=1 LOGDATIM
        
        
	SetDataFolder root:entry1:Run1:Detector
// DET
        Make/O/T/N=1 TYP
        Make/O/D/N=3 CALX
        Make/O/D/N=3 CALY
        Make/O/I/N=1 NUM
        Make/O/I/N=1 DetSPACER
        Make/O/D/N=1 BEAMX
        Make/O/D/N=1 BEAMY
        Make/O/D/N=1 DIS
        Make/O/D/N=1 ANG
        Make/O/D/N=1 SIZ
        Make/O/D/N=1 BSTOP
        Make/O/D/N=1 DetBLANK

		Make/O/D/N=(128,128) data

	SetDataFolder root:entry1:Run1:Instrument
// RESOLUTION
        Make/O/D/N=1 AP1
        Make/O/D/N=1 AP2
        Make/O/D/N=1 AP12DIS
        Make/O/D/N=1 LMDA
        Make/O/D/N=1 DLMDA
        Make/O/D/N=1 SAVEFlag
// BMSTP
        Make/O/D/N=1 XPOS
        Make/O/D/N=1 YPOS        
// TIMESLICING
        Make/O/T/N=1 SLICING
        Make/O/I/N=1 MULTFACT
        Make/O/I/N=1 LTSLICE

// POLARIZATION
        Make/O/T/N=1 PRINTPOL
        Make/O/T/N=1 FLIPPER
        Make/O/D/N=1 HORIZ
        Make/O/D/N=1 VERT        
// TEMP
        Make/O/T/N=1 PRINTEMP
        Make/O/D/N=1 HOLD
//        Make/O/D/N=1 ERR
        Make/O/D/N=1 ERR_TEMP
        Make/O/D/N=1 TempBLANK
        Make/O/T/N=1 EXTEMP
        Make/O/T/N=1 EXTCNTL 
        Make/O/T/N=1 TempEXTRA2
        Make/O/I/N=1 TempRESERVE
// MAGNET
        Make/O/T/N=1 PRINTMAG
        Make/O/T/N=1 SENSOR
        Make/O/D/N=1 CURRENT
        Make/O/D/N=1 CONV
        Make/O/D/N=1 FIELDLAST
        Make/O/D/N=1 MagnetBLANK
        Make/O/D/N=1 MagnetSPACER
// VOLTAGE
        Make/O/T/N=1 PRINTVOLT
        Make/O/D/N=1 VOLTS
        Make/O/D/N=1 VoltBLANK
        Make/O/I/N=1 VoltSPACER
     
	SetDataFolder root:entry1:Run1:Analysis
// ANALYSIS
        Make/O/I/N=2 ROWS
        Make/O/I/N=2 COLS
        Make/O/D/N=1 FACTOR
        Make/O/D/N=1 AnalysisQMIN
        Make/O/D/N=1 AnalysisQMAX
        Make/O/D/N=1 IMIN
        Make/O/D/N=1 IMAX

// PARAMS
        Make/O/I/N=1 BLANK1
        Make/O/I/N=1 BLANK2
        Make/O/I/N=1 BLANK3
        Make/O/D/N=1 TRNSCNT
        Make/O/D/N=1 ParamEXTRA1
        Make/O/D/N=1 ParamEXTRA2
        Make/O/D/N=1 ParamEXTRA3
        Make/O/T/N=1 ParamRESERVE

	SetDataFolder root:
	
End


// fills the tree structure based on the RTI from RAW
// logicals are skipped
Function FillStructureFromRTI()

	WAVE rw = root:Packages:NIST:RAW:RealsRead
	WAVE iw = root:Packages:NIST:RAW:IntegersRead
	WAVE/T tw = root:Packages:NIST:RAW:TextRead

	
	SetDataFolder root:entry1
    Wave/T filename

	String newFileName= N_GetNameFromHeader(tw[0])		//02JUL13

	//TODO - not the best choice of file name, (maybe not unique) but this is only a test...     
    filename[0] = newfilename[0,7]+".h5"		//make sure the file name in the header matches that on disk!
    
	SetDataFolder root:entry1:Run1
    Wave/T runLabel

	runLabel[0] = tw[6]

	SetDataFolder root:entry1:Run1:Sample
// SAMPLE      
        Wave TRNS
        Wave THK
        Wave POSITION
        Wave ROTANG
        Wave TABLE
        Wave HOLDER
        Wave BLANK
        Wave TEMP
        Wave FIELD
        Wave TCTRLR
        Wave MAGNET
        Wave/T TUNITS
        Wave/T FUNITS

        TRNS[0] = rw[4]
        THK[0] = rw[5]
        POSITION[0] = rw[6]
        ROTANG[0] = rw[7]
        TABLE[0] = iw[4]
        HOLDER[0] = iw[5]
        BLANK[0] = iw[6]
        TEMP[0] = rw[8]
        FIELD[0] = rw[9]
        TCTRLR[0] = iw[7]
        MAGNET[0] = iw[8]
        TUNITS[0] = tw[7]
        FUNITS[0] = tw[8]


	SetDataFolder root:entry1:Run1:Run
// RUN
        Wave NPRE
        Wave CTIME
        Wave RTIME
        Wave NUMRUNS
        Wave MONCNT
        Wave SAVMON
        Wave DETCNT
        Wave ATTEN
        Wave/T TIMDAT
        Wave/T TYPE
        Wave/T DEFDIR
        Wave/T MODE
        Wave/T RESERVE
//        Wave/T LOGDATIM
        
        
        NPRE[0] = iw[0]
        CTIME[0] = iw[1]
        RTIME[0] = iw[2]
        NUMRUNS[0] = iw[3]
        MONCNT[0] = rw[0]
        SAVMON[0] = rw[1]
        DETCNT[0] = rw[2]
        ATTEN[0] = rw[3]
        TIMDAT[0] = tw[1]
        TYPE[0] = tw[2]
        DEFDIR[0] = tw[3]
        MODE[0] = tw[4]
        RESERVE[0] = tw[5]
//        LOGDATIM
        
        
	SetDataFolder root:entry1:Run1:Detector
// DET
        Wave/T TYP
        Wave CALX
        Wave CALY
        Wave NUM
        Wave DetSPACER
        Wave BEAMX
        Wave BEAMY
        Wave DIS
        Wave ANG
        Wave SIZ
        Wave BSTOP
        Wave DetBLANK
        
		 Wave data

		//CALX is 3 pts
		//CALY is 3 pts
		//data is 128,128
		
       TYP[0] = tw[9]
        CALX[0] = rw[10]
        CALX[1] = rw[11]
        CALX[2] = rw[12]
        CALY[0] = rw[13]
        CALY[1] = rw[14]
        CALY[2] = rw[15]
        NUM[0] = iw[9]
        DetSPACER[0] = iw[10]
        BEAMX[0] = rw[16]
        BEAMY[0] = rw[17]
        DIS[0] = rw[18]
        ANG[0] = rw[19]
        SIZ[0] = rw[20]
        BSTOP[0] = rw[21]
        DetBLANK[0] = rw[22]

		 Wave linear_data = root:Packages:NIST:RAW:linear_data
 		 data = linear_data
		
		
	SetDataFolder root:entry1:Run1:Instrument
// RESOLUTION
        Wave AP1
        Wave AP2
        Wave AP12DIS
        Wave LMDA
        Wave DLMDA
        Wave SAVEFlag
// BMSTP
        Wave XPOS
        Wave YPOS        
// TIMESLICING
        Wave/T SLICING		//logical
        Wave MULTFACT
        Wave LTSLICE

// POLARIZATION
        Wave/T PRINTPOL			//logical
        Wave/T FLIPPER			//logical
        Wave HORIZ
        Wave VERT        
// TEMP
        Wave/T PRINTEMP			//logical
        Wave HOLD
        Wave ERR_TEMP
        Wave TempBLANK
        Wave/T EXTEMP			//logical
        Wave/T EXTCNTL 			//logical
        Wave/T TempEXTRA2		//logical
        Wave TempRESERVE
// MAGNET
        Wave/T PRINTMAG			//logical
        Wave/T SENSOR			//logical
        Wave CURRENT
        Wave CONV
        Wave FIELDLAST
        Wave MagnetBLANK
        Wave MagnetSPACER
// VOLTAGE
        Wave/T PRINTVOLT		//logical
        Wave VOLTS
        Wave VoltBLANK
        Wave VoltSPACER
  
  
        AP1[0] = rw[23]
        AP2[0] = rw[24]
        AP12DIS[0] = rw[25]
        LMDA[0] = rw[26]
        DLMDA[0] = rw[27]
        SAVEFlag[0] = rw[28]
  
        XPOS[0] = rw[37]
        YPOS[0] = rw[38]
     
        MULTFACT[0] = iw[11]
        LTSLICE[0] = iw[12]
     
        HORIZ[0] = rw[45]
        VERT[0] = rw[46]
// TEMP
        HOLD[0] = rw[29]
        ERR_TEMP[0] = rw[30]
        TempBLANK[0] = rw[31]
        TempRESERVE[0] = iw[14]
// MAGNET
        CURRENT[0] = rw[32]
        CONV[0] = rw[33]
        FIELDLAST[0] = rw[34]
        MagnetBLANK[0] = rw[35]
        MagnetSPACER[0] = rw[36]
// VOLTAGE
        VOLTS[0] = rw[43]
        VoltBLANK[0] = rw[44]
        VoltSPACER[0] = iw[18]
     
	SetDataFolder root:entry1:Run1:Analysis
// ANALYSIS
        Wave ROWS
        Wave COLS
        Wave FACTOR
        Wave AnalysisQMIN
        Wave AnalysisQMAX
        Wave IMIN
        Wave IMAX

// PARAMS
        Wave BLANK1
        Wave BLANK2
        Wave BLANK3
        Wave TRNSCNT
        Wave ParamEXTRA1
        Wave ParamEXTRA2
        Wave ParamEXTRA3
        Wave/T ParamRESERVE	
	
			// ROWS is 2 pts
			// COLS is 2 pts
			
// ANALYSIS
        ROWS[0] = iw[19]
        ROWS[1] = iw[20]
        COLS[0] = iw[21]
        COLS[1] = iw[22]

        FACTOR[0] = rw[47]
        AnalysisQMIN[0] = rw[48]
        AnalysisQMAX[0] = rw[49]
        IMIN[0] = rw[50]
        IMAX[0] = rw[51]

// PARAMS
        BLANK1[0] = iw[15]
        BLANK2[0] = iw[16]
        BLANK3[0] = iw[17]
        TRNSCNT[0] = rw[39]
        ParamEXTRA1[0] = rw[40]
        ParamEXTRA2[0] = rw[41]
        ParamEXTRA3[0] = rw[42]
        ParamRESERVE[0] = tw[10]
			
			
	SetDataFolder root:
		
	return(0)
End



Function Test_HDFWriteTrans(fname,val)
	String fname
	Variable val
	
	
	String str
	PathInfo home
	str = S_path
	
	writeSampleTransmission(str+fname,val)
	
	return(0)
End

//Function WriteTransmissionToHeader(fname,trans)
//	String fname
//	Variable trans
//	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
//
//	variable err
//	err = HDFWrite_Wave(fname, groupName, varName, wTmpWrite)
//	KillWaves wTmpWrite
//	
//	//err not handled here
//		
//	return(0)
//End



Function Test_ListAttributes(fname,groupName)
	String fname,groupName
	Variable trans
	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
	String str
	PathInfo home
	str = S_path
	
	variable err
	err = HDF_ListAttributes(str+fname, groupName)
	
	//err not handled here
		
	return(0)
End

Function HDF_ListAttributes(fname, groupName)
	String fname, groupName
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name, attrValue=""
	
	STRUCT HDF5DataInfo di	// Defined in HDF5 Browser.ipf.
	InitHDF5DataInfo(di)	// Initialize structure.
	
	try	
		HDF5OpenFile /Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		HDF5OpenGroup /Z fileID , groupName, groupID

	//	!! At the moment, there is no entry for sample thickness in our data file
	//	therefore create new HDF5 group to enable write / patch command
	//	comment out the following group creation once thickness appears in revised file
	
		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else

//			HDF5AttributeInfo(fileID, "/", 1, "file_name", 0, di)
			err = HDF5AttributeInfo(fileID, "/", 1, "NeXus_version", 0, di)
			Print di

//			see the HDF5 Browser  for how to get the actual <value> of the attribute. See GetPreviewString in 
//        or in FillGroupAttributesList or in FillDatasetAttributesList (from FillLists)
//			it seems to be ridiculously complex to get such a simple bit of information - the HDF5BrowserData STRUCT
// 			needs to be filled first. Ugh.

//#if (IgorVersion() < 9)
//			attrValue = GetPreviewString(fileID, 1, di, "/entry", "cucumber")
//#else
//			attrValue = HDF5Browser#GetPreviewString(fileID, 1, di, "/entry", "cucumber")
//#endif
			Print "attrValue = ",attrValue
			
			
			//get attributes and save them
			HDF5ListAttributes/TYPE=1 /Z fileID, groupName 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
			
			// passing the groupID works too, then the group name is not needed			
			HDF5ListAttributes/TYPE=1 /Z groupID, "." 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
		endif
	catch

		// catch any aborts here
		
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

// this is my procedure to save VAX to HDF5, once I've filled the folder tree
//
Function VAXSaveGroupAsHDF5(dfPath, filename)
	String dfPath	// e.g., "root:FolderA" or ":"
	String filename

	Variable result = 0	// 0 means no error
	
	Variable fileID
	HDF5CreateFile/P=home /O /Z fileID as filename
	if (V_flag != 0)
		Print "HDF5CreateFile failed"
		return -1
	endif

	HDF5SaveGroup /IGOR=0 /O /R /Z $dfPath, fileID, "."
//	HDF5SaveGroup /O /R /Z $dfPath, fileID, "."
	if (V_flag != 0)
		Print "HDF5SaveGroup failed"
		result = -1
	endif
	
	HDF5CloseFile fileID

	return result
End



//////// Two procedures that test out Pete Jemain's HDF5Gateway
//
// This works fine, but it may not be terribly compatible with the way NICE will eventually
// write out the data files. I'll have very little control over that and I'll need to cobble together
// a bunch of fixes to cover up their mistakes.
//
// Using Nick Hauser's code as a starting point may be a lot more painful, but more flexible in the end.
//
// I'm completely baffled about what to do with attributes. Are they needed, is this the best way to deal
// with them, do I care about reading them in, and if I do, why?
//
Proc HDF5Gate_WriteTest()

	// create the folder structure
	NewDataFolder/O/S root:mydata
	NewDataFolder/O sasentry
	NewDataFolder/O :sasentry:sasdata

	// create the waves
	Make/O :sasentry:sasdata:I0
	Make/O :sasentry:sasdata:Q0

	Make/O/N=0 Igor___folder_attributes
	Make/O/N=0 :sasentry:Igor___folder_attributes
	Make/O/N=0 :sasentry:sasdata:Igor___folder_attributes

	// create the attributes
	Note/K Igor___folder_attributes, "producer=IgorPro\rNX_class=NXroot"
	Note/K :sasentry:Igor___folder_attributes, "NX_class=NXentry"
	Note/K :sasentry:sasdata:Igor___folder_attributes, "NX_class=NXdata"
	Note/K :sasentry:sasdata:I0, "units=1/cm\rsignal=1\rtitle=reduced intensity"
	Note/K :sasentry:sasdata:Q0, "units=1/A\rtitle=|scattering vector|"

	// create the cross-reference mapping
	Make/O/T/N=(5,2) HDF5___xref
	Edit/K=0 'HDF5___xref';DelayUpdate
	HDF5___xref[0][1] = ":"
	HDF5___xref[1][1] = ":sasentry"
	HDF5___xref[2][1] = ":sasentry:sasdata"
	HDF5___xref[3][1] = ":sasentry:sasdata:I0"
	HDF5___xref[4][1] = ":sasentry:sasdata:Q0"
	HDF5___xref[0][0] = "/"
	HDF5___xref[1][0] = "/sasentry"
	HDF5___xref[2][0] = "/sasentry/sasdata"
	HDF5___xref[3][0] = "/sasentry/sasdata/I"
	HDF5___xref[4][0] = "/sasentry/sasdata/Q"

	// Check our work so far.
	// If something prints, there was an error above.
	print H5GW_ValidateFolder("root:mydata")

	// set I0 and Q0 to your data

	print H5GW_WriteHDF5("root:mydata", "mydata.h5")
	
	SetDataFolder root:
End

Proc HDF5Gate_ReadTest(file)
	String file
//	NewDataFolder/O/S root:newdata
	Print H5GW_ReadHDF5("", file)	// reads into current folder
	SetDataFolder root:
End



//// after reading in an HDF file, convert it into something I can use with data reduction
//
// This is to be an integral part of the file loader
//
// I guess I need to load the file into a temporary location, and then copy what I need to the local RTI
// and then get rid of the temp dump. ANSTO keeps all of the loads around, but this may get too large
// especially if NICE dumps all of the logs into the data file.
// 
// -- and I may need to have a couple of these, at least for testing to be able to convert the 
// minimal VAX file to HDF, and also to write out/ have a container/ for what NICE calls a data file.
//
//


// From the HDF5 tree as read in from a (converted) raw VAX file,
// put everything back into its proper place in the RTI waves
// (and the data!)
// 
Function FillRTIFromHDFTree(folderStr)
	String folderStr

	WAVE rw = root:Packages:NIST:RAW:RealsRead
	WAVE iw = root:Packages:NIST:RAW:IntegersRead
	WAVE/T tw = root:Packages:NIST:RAW:TextRead

	rw = -999
	iw = 11111
	tw = "jibberish"
	
	folderStr = RemoveDotExtension(folderStr)		// to make sure that the ".h5" or any other extension is removed
//	folderStr = RemoveEnding(folderStr,".h5")		// to make sure that the ".h5" or any other extension is removed
	
	String base="root:"+folderStr+":"
	SetDataFolder $base
    Wave/T filename
    
    tw[0] = filename[0]
    
	SetDataFolder $(base+"Run1")
    Wave/T runLabel

	tw[6] = runLabel[0]

	SetDataFolder $(base+"Run1:Sample")
// SAMPLE      
        Wave TRNS
        Wave THK
        Wave POSITION
        Wave ROTANG
        Wave TABLE
        Wave HOLDER
        Wave BLANK
        Wave TEMP
        Wave FIELD
        Wave TCTRLR
        Wave MAGNET
        Wave/T TUNITS
        Wave/T FUNITS

        rw[4] = TRNS[0]
        rw[5] = THK[0]
        rw[6] = POSITION[0]
        rw[7] = ROTANG[0]
        iw[4] = TABLE[0]
        iw[5] = HOLDER[0]
        iw[6] = BLANK[0]
        rw[8] = TEMP[0]
        rw[9] = FIELD[0]
        iw[7] = TCTRLR[0]
        iw[8] = MAGNET[0]
        tw[7] = TUNITS[0]
        tw[8] = FUNITS[0]


	SetDataFolder $(base+"Run1:Run")
// RUN
        Wave NPRE
        Wave CTIME
        Wave RTIME
        Wave NUMRUNS
        Wave MONCNT
        Wave SAVMON
        Wave DETCNT
        Wave ATTEN
        Wave/T TIMDAT
        Wave/T TYPE
        Wave/T DEFDIR
        Wave/T MODE
        Wave/T RESERVE
//        Wave/T LOGDATIM
        
        
        iw[0] = NPRE[0]
        iw[1] = CTIME[0]
        iw[2] = RTIME[0]
        iw[3] = NUMRUNS[0]
        rw[0] = MONCNT[0]
        rw[1] = SAVMON[0]
        rw[2] = DETCNT[0]
        rw[3] = ATTEN[0]
        tw[1] = TIMDAT[0]
        tw[2] = TYPE[0]
        tw[3] = DEFDIR[0]
        tw[4] = MODE[0]
        tw[5] = RESERVE[0]
//        LOGDATIM
        
        
	SetDataFolder $(base+"Run1:Detector")
// DET
        Wave/T TYP
        Wave CALX
        Wave CALY
        Wave NUM
        Wave DetSPACER
        Wave BEAMX
        Wave BEAMY
        Wave DIS
        Wave ANG
        Wave SIZ
        Wave BSTOP
        Wave DetBLANK
        
		 Wave data

		//CALX is 3 pts
		//CALY is 3 pts
		//data is 128,128
		
        tw[9] = TYP[0]
        rw[10] = CALX[0]
        rw[11] = CALX[1]
        rw[12] = CALX[2]
        rw[13] = CALY[0]
        rw[14] = CALY[1]
        rw[15] = CALY[2]
        iw[9] = NUM[0]
        iw[10] = DetSPACER[0]
        rw[16] = BEAMX[0]
        rw[17] = BEAMY[0]
        rw[18] = DIS[0]
        rw[19] = ANG[0]
        rw[20] = SIZ[0]
        rw[21] = BSTOP[0]
        rw[22] = DetBLANK[0]

//		 Wave linear_data = root:Packages:NIST:RAW:linear_data
//		 Wave raw_data = root:Packages:NIST:RAW:data
// 		 linear_data = data
//		 raw_data = data
		
		/// **** what about the error wave?
		
		
		
	SetDataFolder $(base+"Run1:Instrument")
// RESOLUTION
        Wave AP1
        Wave AP2
        Wave AP12DIS
        Wave LMDA
        Wave DLMDA
        Wave SAVEFlag
// BMSTP
        Wave XPOS
        Wave YPOS        
// TIMESLICING
        Wave/T SLICING		//logical
        Wave MULTFACT
        Wave LTSLICE

// POLARIZATION
        Wave/T PRINTPOL			//logical
        Wave/T FLIPPER			//logical
        Wave HORIZ
        Wave VERT        
// TEMP
        Wave/T PRINTEMP			//logical
        Wave HOLD
        Wave ERR_TEMP
//        Wave ERR0
        Wave TempBLANK
        Wave/T EXTEMP			//logical
        Wave/T EXTCNTL 			//logical
        Wave/T TempEXTRA2		//logical
        Wave TempRESERVE
// MAGNET
        Wave/T PRINTMAG			//logical
        Wave/T SENSOR			//logical
        Wave CURRENT
        Wave CONV
        Wave FIELDLAST
        Wave MagnetBLANK
        Wave MagnetSPACER
// VOLTAGE
        Wave/T PRINTVOLT		//logical
        Wave VOLTS
        Wave VoltBLANK
        Wave VoltSPACER
  
  
        rw[23] = AP1[0]
        rw[24] = AP2[0]
        rw[25] = AP12DIS[0]
        rw[26] = LMDA[0]
        rw[27] = DLMDA[0]
        rw[28] = SAVEFlag[0]
  
        rw[37] = XPOS[0]
        rw[38] = YPOS[0]
     
        iw[11] = MULTFACT[0]
        iw[12] = LTSLICE[0]
     
        rw[45] = HORIZ[0]
        rw[46] = VERT[0]
// TEMP
        rw[29] = HOLD[0]
        rw[30] = ERR_TEMP[0]
//        rw[30] = ERR0[0]
        rw[31] = TempBLANK[0]
        iw[14] = TempRESERVE[0]
// MAGNET
        rw[32] = CURRENT[0]
        rw[33] = CONV[0]
        rw[34] = FIELDLAST[0]
        rw[35] = MagnetBLANK[0]
        rw[36] = MagnetSPACER[0]
// VOLTAGE
        rw[43] = VOLTS[0]
        rw[44] = VoltBLANK[0]
        iw[18] = VoltSPACER[0]
     
	SetDataFolder $(base+"Run1:Analysis")
// ANALYSIS
        Wave ROWS
        Wave COLS
        Wave FACTOR
        Wave AnalysisQMIN
        Wave AnalysisQMAX
        Wave IMIN
        Wave IMAX

// PARAMS
        Wave BLANK1
        Wave BLANK2
        Wave BLANK3
        Wave TRNSCNT
        Wave ParamEXTRA1
        Wave ParamEXTRA2
        Wave ParamEXTRA3
        Wave/T ParamRESERVE	
	
			// ROWS is 2 pts
			// COLS is 2 pts
			
// ANALYSIS
        iw[19] = ROWS[0]
        iw[20] = ROWS[1]
        iw[21] = COLS[0]
        iw[22] = COLS[1]

        rw[47] = FACTOR[0]
        rw[48] = AnalysisQMIN[0]
        rw[49] = AnalysisQMAX[0]
        rw[50] = IMIN[0]
        rw[51] = IMAX[0]

// PARAMS
        iw[15] = BLANK1[0]
        iw[16] = BLANK2[0]
        iw[17] = BLANK3[0]
        rw[39] = TRNSCNT[0]
        rw[40] = ParamEXTRA1[0]
        rw[41] = ParamEXTRA2[0]
        rw[42] = ParamEXTRA3[0]
        tw[10] = ParamRESERVE[0]
			
			
	SetDataFolder root:
		
	return(0)
End





//given a filename of a SANS data filename of the form
// name.anything
//returns the name as a string without the ".fbdfasga" extension
//
// returns the input string if a"." can't be found (maybe it wasn't there"
Function/S RemoveDotExtension(item)
	String item
	String invalid = item	//
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get all of the characters preceeding it
		runStr = item[0,pos-1]
		return (runStr)
	Endif
End




//////////////////////////////////////////////////



Macro BatchConvertToHDF5(firstFile,lastFile)
	Variable firstFile=1,lastFile=100

	SetupStructure()
	fBatchConvertToHDF5(firstFile,lastFile)

End

// lo is the first file number
// hi is the last file number (inclusive)
//
Function fBatchConvertToHDF5(lo,hi)
	Variable lo,hi
	
	Variable ii
	String file
	
	String fname="",pathStr="",fullPath="",newFileName=""

	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = N_FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			// load the data
			ReadHeaderAndData(file,"RAW")		//file is the full path
			String/G root:myGlobals:gDataDisplayType="RAW"	
			fRawWindowHook()
			WAVE/T/Z tw = $"root:Packages:NIST:RAW:textRead"	//to be sure that wave exists if no data was ever displayed
			newFileName= N_GetNameFromHeader(tw[0])		//02JUL13
			
			// convert it
			FillStructureFromRTI()
			
			// save it
			VAXSaveGroupAsHDF5("root:entry1", newfilename[0,7]+".h5")

		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

