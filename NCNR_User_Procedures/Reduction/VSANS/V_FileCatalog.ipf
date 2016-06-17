#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//
// UPDATED for VSANS - only the simplest implementation to start with
// June 2016  SRK
// included ANSTO sort panel from david m
//


//
// TODO
// -- clean up and remove all of the references to other facilities, since they will not have VSANS modules
// -- add in more appropriate and some missing fields more useful to VSANS (intent, multiple beam centers, etc.)
//
// TODO PRIORITY:
// x- clean up the list of files that now accumulates in the RawVSANS folder!!! Everything is there, including
//    files that are NOT RAW VSANS data (MASK and DIV, but these are HDF)
// x- WHY -- because if I PATCH anything, then re-run the catalog, the changes are NOT shown, since the 
//    reader will g to the LOCAL copy first! So maybe I need to clear the folder out before I start the 
//    file catalog
// -- maybe it's a good thing to wipe out the RawVSANS folder before an Experiment SAVE (to save a LOT of 
//    space on disk and a potentially VERY long save
// x- see V_CleanOutRawVSANS() in V_Utilities_General for the start of this (this is now called in 
//    V_BuildCatVeryShortTable(), the starting point for generating the table.) 
//
// NEW for VSANS
// clear out the folders in the RawVSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "bad" local copy will be read in.
// TODO:
//  -- this *may* be a very slow operation. Warn users. Give them a choice to keep local copies. If
//     the "patched" values are written locally too, then maybe the update from disk is not needed.
//     But typically, I'd like to see that the disk version really did get updated...
//

//
//	SRK modified 30 JAN07 to include Rotation angle, Temperature, and B-field in the table (at the end)
//

//**************
// Vers 1.2 090401
//
// Procedures for creating the Catalog listings of the SANS datafiles in the folder
// specified by catPathName.
// Header information from each of the dataifles is organized in a table for
// easy identification of each file. CatVSANSTable is the preferred invocation,
// although CatVSNotebook and CatNotebook can also be used.
// Files in the folder that are not RAW SANS data are appended to the end of the listing.
//**************

//this main procedure does all the work, obtaining the folder path, 
//parsing the filenames in the list and (dispatching) to write out the 
//appropriate information to the growing (table) of data. V_GetHeaderInfoToWave() does the individual reads
Function V_BuildCatVeryShortTable()
	
	Variable err
	Variable t1 = ticks
	
	PathInfo catPathName
	if(v_flag==0)
		err = V_PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	DoWindow/F CatVSANSTable
	
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"		//added Mar 2010


	WAVE/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	WAVE/T Suffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	WAVE/T Labels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	WAVE/T DateAndTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	WAVE SDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	WAVE Lambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	WAVE CntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	WAVE TotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	WAVE CntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	WAVE Transmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	WAVE Thickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	WAVE XCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	WAVE YCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"

	WAVE/T nGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	WAVE NumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	WAVE RunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
	WAVE IsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	WAVE RotAngle = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	WAVE Temperature = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	WAVE Field = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	WAVE MCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	WAVE Pos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"

	
	If(V_Flag==0)
		V_BuildTableWindow()
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts)=60
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate)=60
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens)=30
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Field)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR)=50

		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos)=30
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos)=3			//to make the display look nice, given the floating point values from ICE
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda)=3		//may not work in all situations, but an improvement
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD)=5
		ModifyTable trailingZeros(root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature)=1
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature)=4

		ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run
	Endif


// NEW for VSANS
// clear out the folders in the RawVSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "bad" local copy will be read in.
// TODO:
//  -- this *may* be a very slow operation. Warn users. Give them a choice to keep local copies. If
//     the "patched" values are written locally too, then maybe the update from disk is not needed.
//     But typically, I'd like to see that the disk version really did get updated...
//
		V_CleanOutRawVSANS()




	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName
	Variable lastPoint
	ii=0
	
	Make/T/O/N=0 notRAWlist
	do
	
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = V_FindValidFilename(partialName)
		
		
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = V_CheckIfRawData(fullName)
		
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				V_GetHeaderInfoToWave(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
//Now sort them all based on some criterion that may be facility dependent (aim is to order them as collected)
	V_SortWaves()
//Append the files that are not raw files to the list
	V_AppendNotRAWFiles(notRAWlist)	
	KillWaves/Z notRAWlist
//
//	Print "Total time (s) = ",(ticks - t1)/60.15
//	Print "Time per raw data file (s) = ",(ticks - t1)/60.15/(numItems-numpnts(notRawList))
	//
	// clean out again, so that the file SAVE is not slow due to the large experiment size
	// TODO -- decide if this is really necessary
//	
//	V_CleanOutRawVSANS()
			
			
	return(0)
End

//appends the list of files that are not RAW SANS data to the filename wave (1st column)
//for display in the table. Note that the filenames column will now be longer than all other
//waves in the table
Function V_AppendNotRAWFiles(w)
	Wave/T w
	Wave/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Variable lastPoint
	lastPoint = numpnts(Filenames)
	InsertPoints lastPoint,numpnts(w),Filenames
	Filenames[lastPoint,numpnts(Filenames)-1] = w[p-lastPoint]
	return(0)
End

//sorts all of the waves of header information using the suffix (A123) 
//the result is that all of the data is in the order that it was collected,
// regardless of how the prefix or run numbers were changed by the user
Function V_SortWaves()
	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	Wave GSDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"

	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"


// TODO -- the default sort is by SUFFIX, which does not exist for VSANS. So decide on a better key
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,GPos,gNumGuides

	return(0)
End

//function to create the CAT/VSTable to display the header information
//this table is just like any other table
Function V_BuildTableWindow()
	Wave/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Wave/T Labels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Wave/T DateAndTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	Wave SDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	Wave Lambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Wave CntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	Wave TotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	Wave CntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	Wave Transmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Wave Thickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	Wave XCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	Wave YCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"

	Wave/T NumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Wave NumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Wave RotAngle =  $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Wave Temperature = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Wave Field= $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Wave MCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	Wave Pos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"


// original order, magnetic at the end
//	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
// with numGuides
	Edit Filenames, Labels, DateAndTime, SDD, Lambda, numGuides, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR, Pos as "Data File Catalog"
// alternate ordering, put the magnetic information first
//	Edit Filenames, Labels, RotAngle, Temperature, Field, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens as "Data File Catalog"


	String name="CatVSANSTable"
	DoWindow/C $name
	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function V_GetHeaderInfoToWave(fname,sname)
	String fname,sname
	

	Variable lastPoint,ctime,detcnt,cntrate

	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"

	Wave GSDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"
	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"

	lastPoint = numpnts(GLambda)
		
	//filename
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file alphanumeric suffix
	// TODO -- this does not exist for VSANS - so is there an equivalent, or delete?
	InsertPoints lastPoint,1,GSuffix
	GSuffix[lastPoint]="unknown"

	//read the counting time (integer)
	InsertPoints lastPoint,1,GCntTime
	ctime = V_getCount_time(fname)
	GCntTime[lastPoint]=ctime
	
	//read the file creation date (string)
	InsertPoints lastPoint,1,GDateTime
	GDateTime[lastPoint]=V_getDataStartTime(fname)

	// read the sample.label text field (string)
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=V_getSampleDescription(fname)
	
		
	//read the reals
	//detector count and (derived) count rate
	// TODO -- this is hard-wired for a single detector, which is WRONG
	detcnt = V_getDet_IntegratedCount(fname,"FL")
	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,GTotCnts
	GTotCnts[lastPoint]=detcnt
	InsertPoints lastPoint,1,GCntRate
	GCntRate[lastPoint]=cntrate
	
	//Attenuators
	// TODO -- this is not really the number --
	InsertPoints lastPoint,1,GNumAttens
	GNumAttens[lastPoint]=V_getAttenThickness(fname)
	
	//Transmission
	InsertPoints lastPoint,1,GTransmission
	GTransmission[lastPoint]=V_getSampleTransmission(fname)
	
	//Thickness
	InsertPoints lastPoint,1,GThickness
	GThickness[lastPoint]=V_getSampleThickness(fname)

	// TODO --  the x and y center have different meaning, since there are multiple panels
	//XCenter of beam on detector
	InsertPoints lastPoint,1,GXCenter
	GXCenter[lastPoint]=123
	
	// TODO --  the x and y center have different meaning, since there are multiple panels
	//YCenter
	InsertPoints lastPoint,1,GYCenter
	GYCenter[lastPoint]=321

	// TODO -- SDD has no real meaning - since there are multiple distances to report
	//SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]=44
	
	//wavelength
	InsertPoints lastPoint,1,GLambda
	GLambda[lastPoint]=V_getWavelength(fname)
	
	//Rotation Angle
	InsertPoints lastPoint,1,GRot
	GRot[lastPoint]=V_getSampleRotationAngle(fname)
	
	// TODO -- this is not yet implemented
	//Sample Temperature
	InsertPoints lastPoint,1,GTemp
	GTemp[lastPoint]=-273

	// TODO -- this is not yet implemented
	//Sample Field
	InsertPoints lastPoint,1,GField
	GField[lastPoint]=1000
	
	//Beamstop position (not reported)
	//strToExecute = GBLoadStr + "/S=368/U=1" + "\"" + fname + "\""

	//the run number (not displayed in the table, but carried along)
	InsertPoints lastPoint,1,GRunNumber
	GRunNumber[lastPoint] = V_GetRunNumFromFile(sname)

	// TODO -- the isTransFile utility has not yet been written
	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = V_isTransFile(fname)		//returns one if beamstop is "out"
	
	// Monitor Count Rate
	InsertPoints lastPoint,1,GMCR
	GMCR[lastPoint]  = V_getMonitorCount(fname)/ctime		//total monitor count / total count time


// number of guides and sample position, only for NCNR (a string now)
	InsertPoints lastPoint,1,GNumGuides
	GNumGuides[lastPoint]  = V_getNumberOfGuides(fname)

// TODO -- maybe this is better to convert to a text wave?	
	//Sample Position (== number position in 10CB)
	InsertPoints lastPoint,1,GPos
	GPos[lastPoint] = str2num(V_getSamplePosition(fname))

	return(0)
End



// just to call the function to generate the panel
Macro Catalog_Sort()
	V_BuildCatSortPanel()
End

// [davidm] create CAT Sort-Panel
function V_BuildCatSortPanel()

	// check if CatVSANSTable exists
	DoWindow CatVSANSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return 0
	endif
	
	// bring CatSortPanel to front
	DoWindow/F CatSortPanel
	if (V_flag != 0)
		return 0
	endif
	
	print "Creating CAT Sort-Panel..."
		
	//PauseUpdate
	NewPanel /W=(600,360,790,730)/K=1 as "CAT - Sort Panel"
	DoWindow/C CatSortPanel
	ModifyPanel fixedSize=1, cbRGB = (42919, 53970, 60909)
	
	Button SortFilenamesButton,		pos={25, 8},		size={140,24},proc=V_CatVSANSTable_SortProc,title="Filenames"
	Button SortLabelsButton,			pos={25,38},		size={140,24},proc=V_CatVSANSTable_SortProc,title="Labels"
	Button SortDateAndTimeButton,	pos={25,68},		size={140,24},proc=V_CatVSANSTable_SortProc,title="Date and Time"
	Button SortSSDButton,			pos={25,98},		size={140,24},proc=V_CatVSANSTable_SortProc,title="SSD"
	Button SortSDDButton,			pos={25,128},	size={140,24},proc=V_CatVSANSTable_SortProc,title="SDD"
	Button SortLambdaButton,			pos={25,158},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Lambda"
	Button SortCountTimButton,		pos={25,188},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Count Time"
	Button SortTotalCountsButton,		pos={25,218},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Total Counts"
	Button SortCountRateButton,		pos={25,248},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Count Rate"
	Button SortMonitorCountsButton,	pos={25,278},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Monitor Counts"
	Button SortTransmissionButton,	pos={25,308},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Transmission"
	Button SortThicknessButton,		pos={25,338},	size={140,24},proc=V_CatVSANSTable_SortProc,title="Thickness"

end

Proc V_CatVSANSTable_SortProc(ctrlName) : ButtonControl // added by [davidm]
	String ctrlName
	
	// check if CatVSANSTable exists
	DoWindow CatVSANSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return
	endif
		
	// have to use function
	V_CatVSANSTable_SortFunction(ctrlName)
	
end

function V_CatVSANSTable_SortFunction(ctrlName) // added by [davidm]
	String ctrlName

	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	Wave GSDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"
	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"

	
	// take out the "not-RAW-Files"
	Variable fileCount = numpnts(GFilenames)
	Variable rawCount = numpnts(GLabels)
	Variable notRAWcount = fileCount - rawCount
	
	if (notRAWcount > 0)
		Make/T/O/N=(notRAWcount) notRAWlist
		notRAWlist[0, notRAWcount-1] = GFilenames[p+rawCount]
		DeletePoints rawCount, notRAWcount, GFilenames
	endif
	
	strswitch (ctrlName)
	
		case "SortFilenamesButton":
			Sort GFilenames, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
			break
			
		case "SortLabelsButton":
			Sort GLabels, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
			break
			
		case "SortDateAndTimeButton":
			Sort GDateTime, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
			break
			
		case "SortSSDButton":
			break
			
		case "SortSDDButton":
			Sort GSDD, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortLambdaButton":
			Sort GLambda, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortCountTimButton":
			Sort GCntTime, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortTotalCountsButton":
			Sort GTotCnts, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortCountRateButton":
			Sort GCntRate, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortMonitorCountsButton":
			break
			
		case "SortTransmissionButton":
			Sort GTransmission, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
			
		case "SortThicknessButton":
			Sort GThickness, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
			break
	
	endswitch
	
	// insert the "not-RAW-Files" again
	if (notRAWcount > 0)
		InsertPoints rawCount, notRAWcount, GFilenames
		GFilenames[rawCount, fileCount-1] = notRAWlist[p-rawCount]
	endif
end