#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//
//	SRK modified 30 JAN07 to include Rotation angle, Temperature, and B-field in the table (at the end)
//

//**************
// Vers 1.2 090401
//
// Procedures for creating the Catalog listings of the SANS datafiles in the folder
// specified by catPathName.
// Header information from each of the dataifles is organized in a table for
// easy identification of each file. CatVSTable is the preferred invocation,
// although CatVSNotebook and CatNotebook can also be used.
// Files in the folder that are not RAW SANS data are appended to the end of the listing.
//**************

//this main procedure does all the work, obtaining the folder path, 
//parsing the filenames in the list and (dispatching) to write out the 
//appropriate information to the notebook window
Function BuildCatVeryShortTable()
	
	Variable err
	Variable t1 = ticks
	
	PathInfo catPathName
	if(v_flag==0)
		err = PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	DoWindow/F CatVSTable
	
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:Suffix"
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:Labels"
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:SDD"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:YCenter"
	Make/O/B/N=0 $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Make/O/B/N=0 $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Field"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
#if (exists("ILL_D22")==6)
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Reactorpower"       //activate for ILL, June 2008,
	WAVE ReactorPower = $"root:myGlobals:CatVSHeaderInfo:Reactorpower"
#endif

	WAVE/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	WAVE/T Suffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	WAVE/T Labels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	WAVE/T DateAndTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	WAVE SDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	WAVE Lambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	WAVE CntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	WAVE TotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	WAVE CntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	WAVE Transmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	WAVE Thickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	WAVE XCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	WAVE YCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
	WAVE/B NumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	WAVE/B NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	WAVE RunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	WAVE IsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	WAVE RotAngle = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	WAVE Temperature = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	WAVE Field = $"root:myGlobals:CatVSHeaderInfo:Field"
	WAVE MCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	
	
	If(V_Flag==0)
		BuildTableWindow()
		ModifyTable width(:myGlobals:CatVSHeaderInfo:SDD)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Lambda)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:CntTime)=50
		ModifyTable width(:myGlobals:CatVSHeaderInfo:TotCnts)=60
		ModifyTable width(:myGlobals:CatVSHeaderInfo:CntRate)=60
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Transmission)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Thickness)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:XCenter)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:YCenter)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:NumAttens)=30
		ModifyTable width(:myGlobals:CatVSHeaderInfo:RotAngle)=50
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Field)=50
		ModifyTable width(:myGlobals:CatVSHeaderInfo:MCR)=50
#if (exists("ILL_D22")==6)
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Reactorpower)=50		//activate for ILL, June 2008
#endif

#if (exists("NCNR")==6)
		ModifyTable width(:myGlobals:CatVSHeaderInfo:nGuides)=40
#endif

		ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run
	Endif

	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	//remove version numbers from semicolon-delimited list
	list =  RemoveVersNumsFromList(list)
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
		tempName = FindValidFilename(partialName)
		
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(str2num(partialName) == NaN)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)
		
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				GetHeaderInfoToWave(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
//Now sort them all based on the suffix data (orders them as collected)
	SortWaves()
//Append the files that are not raw files to the list
	AppendNotRAWFiles(notRAWlist)	
	KillWaves/Z notRAWlist
//
//	Print "Total time (s) = ",(ticks - t1)/60.15
//	Print "Time per raw data file (s) = ",(ticks - t1)/60.15/(numItems-numpnts(notRawList))
	return(0)
End

//appends the list of files that are not RAW SANS data to the filename wave (1st column)
//for display in the table. Note that the filenames column will now be longer than all other
//waves in the table
Function AppendNotRAWFiles(w)
	Wave/T w
	Wave/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Variable lastPoint
	lastPoint = numpnts(Filenames)
	InsertPoints lastPoint,numpnts(w),Filenames
	Filenames[lastPoint,numpnts(Filenames)-1] = w[p-lastPoint]
	return(0)
End

//sorts all of the waves of header information using the suffix (A123) 
//the result is that all of the data is in the order that it was collected,
// regardless of how the prefix or run numbers were changed by the user
Function SortWaves()
	Wave/T GFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	Wave GSDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
	Wave/B GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave/B GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	
#if (exists("ILL_D22")==6)
	Wave GReactPow = $"root:myGlobals:CatVSHeaderInfo:ReactorPower"		//activate for ILL June 2008 ( and the sort line too)
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,GReactPow
#endif

#if (exists("NCNR")==6)
	//	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,gNumGuides
#else
	//must be HFIR or ANSTO
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR
#endif


	return(0)
End

//function to create the CAT/VSTable to display the header information
//this table is just like any other table
Function BuildTableWindow()
	Wave/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T Labels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T DateAndTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	Wave SDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave Lambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave CntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave TotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave CntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave Transmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave Thickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave XCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave YCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
	Wave/B NumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave/B NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave RotAngle =  $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave Temperature = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave Field= $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave MCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
#if (exists("ILL_D22")==6)
// for ILL
	Wave ReactorPower = $"root:myGlobals:CatVSHeaderInfo:reactorpower"       //activate for ILL, June 08 (+ edit line)
	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR, ReactorPower as "Data File Catalog"
#endif

#if (exists("NCNR")==6)
// original order, magnetic at the end
//	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
// with numGuides
	Edit Filenames, Labels, DateAndTime, SDD, Lambda, numGuides, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
// alternate ordering, put the magnetic information first
//	Edit Filenames, Labels, RotAngle, Temperature, Field, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens as "Data File Catalog"
#else
	// either HFIR or ANSTO
	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
#endif

	String name="CatVSTable"
	DoWindow/C $name
	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function GetHeaderInfoToWave(fname,sname)
	String fname,sname
	
//	String textstr,temp,lbl,date_time,suffix
//	Variable ,lambda,sdd,,refNum,trans,thick,xcenter,ycenter,numatten
//	Variable lastPoint, beamstop,dum
	Variable lastPoint,ctime,detcnt,cntrate

	Wave/T GFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	Wave GSDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
	Wave/B GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave/B GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:myGlobals:CatVSHeaderInfo:MCR"
#if (exists("ILL_D22")==6)
	Wave GReactpow = $"root:myGlobals:CatVSHeaderInfo:reactorpower"		//activate for ILL, Jne 2008, (+ last insert @ end of function)	
#endif
	lastPoint = numpnts(GLambda)
		
	//filename
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file alphanumeric suffix
	InsertPoints lastPoint,1,GSuffix
	GSuffix[lastPoint]=getSuffix(fname)

	//read the counting time (integer)
	InsertPoints lastPoint,1,GCntTime
	ctime = getCountTime(fname)
	GCntTime[lastPoint]=ctime
	
	//read the file creation date
	InsertPoints lastPoint,1,GDateTime
	GDateTime[lastPoint]=getFileCreationDate(fname)

	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleLabel(fname)
		
	//read the reals
	//detector count and (derived) count rate
	detcnt = getDetCount(fname)
	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,GTotCnts
	GTotCnts[lastPoint]=detcnt
	InsertPoints lastPoint,1,GCntRate
	GCntRate[lastPoint]=cntrate
	
	//Attenuators
	InsertPoints lastPoint,1,GNumAttens
	GNumAttens[lastPoint]=getAttenNumber(fname)
	
	//Transmission
	InsertPoints lastPoint,1,GTransmission
	GTransmission[lastPoint]=getSampleTrans(fname)
	
	//Thickness
	InsertPoints lastPoint,1,GThickness
	GThickness[lastPoint]=getSampleThickness(fname)

	//XCenter of beam on detector
	InsertPoints lastPoint,1,GXCenter
	GXCenter[lastPoint]=getBeamXPos(fname)

	//YCenter
	InsertPoints lastPoint,1,GYCenter
	GYCenter[lastPoint]=getBeamYPos(fname)

	//SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]=getSDD(fname)
	
	//wavelength
	InsertPoints lastPoint,1,GLambda
	GLambda[lastPoint]=getWavelength(fname)
	
	//Rotation Angle
	InsertPoints lastPoint,1,GRot
	GRot[lastPoint]=getSampleRotationAngle(fname)
	
	//Sample Temperature
	InsertPoints lastPoint,1,GTemp
	GTemp[lastPoint]=getTemperature(fname)
	
	//Sample Field
	InsertPoints lastPoint,1,GField
	GField[lastPoint]=getFieldStrength(fname)
	
	//Beamstop position (not reported)
	//strToExecute = GBLoadStr + "/S=368/U=1" + "\"" + fname + "\""

	//the run number (not displayed in the table, but carried along)
	InsertPoints lastPoint,1,GRunNumber
	GRunNumber[lastPoint] = GetRunNumFromFile(sname)

	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = isTransFile(fname)		//returns one if beamstop is "out"
	
	// Monitor Count Rate
	InsertPoints lastPoint,1,GMCR
	GMCR[lastPoint]  = getMonitorCount(fname)/ctime		//total monitor count / total count time

#if (exists("ILL_D22")==6)
	// Reactor Power (activate for ILL)
	InsertPoints lastPoint,1,GReactpow
	GReactPow[lastPoint]  = getReactorPower(fname)
#endif	

// number of guides, only for NCNR
#if (exists("NCNR")==6)
	InsertPoints lastPoint,1,GNumGuides
	GNumGuides[lastPoint]  = numGuides(getSourceToSampleDist(fname))
#endif

	return(0)
End


//this main procedure does all the work for making the cat notebook,
// obtaining the folder path, parsing the filenames in the list,
// and (dispatching) to write out the appropriate information to the notebook window
Proc BuildCatShortNotebook()

	DoWindow/F CatWin
	If(V_Flag ==0)
		String nb = "CatWin"
		NewNotebook/F=1/N=$nb/W=(5.25,40.25,581.25,380.75) as "CATALOG Window"
		Notebook $nb defaultTab=36, statusWidth=238, pageMargins={72,72,72,72}
		Notebook $nb showRuler=1, rulerUnits=1, updating={1, 60}
		Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}
		Notebook $nb ruler=Normal; Notebook $nb  margins={0,0,544}
	Endif
	
	Variable err
	PathInfo catPathName
	if(v_flag==0)
		err = PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	String temp=""
	//clear old window contents, reset the path
	Notebook CatWin,selection={startOfFile,EndOfFile}
	Notebook CatWin,text="\r"
	
	PathInfo catPathName
	temp = "FOLDER: "+S_path+"\r\r"
	Notebook CatWin,font="Times",fsize=12,text = temp
	
	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	//remove version numbers from semicolon-delimited list
	list =  RemoveVersNumsFromList(list)
	
	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName,notRAWlist
	ii=0
	notRAWlist = ""
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(str2num(partialName) == NaN)
				str = "this file was not found: "+partialName+"\r\r"
				Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				notRAWlist += "This file is not recognized as a RAW SANS data file: "+tempName+"\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			else
				//go write the header information to the Notebook
				WriteCatToNotebook(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
	Notebook CatWin,font="Times",fsize=12,text=notRAWlist
End

//writes out the CATalog information to the notebook named CatWin (which must exist)
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function WriteCatToNotebook(fname,sname)
	String fname,sname
	
	String textstr,temp,lbl,date_time
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick
	
	//read the file creation date
	date_time = getFileCreationDate(fname)

	// read the sample.label text field
	lbl = getSampleLabel(fname)
	
	//read the counting time (integer)
	ctime = getCountTime(fname)
		
	//read the reals
	
	//detector count + countrate
	detcnt = getDetCount(fname)
	cntrate = detcnt/ctime
	
	//wavelength
	lambda = getWavelength(fname)
	
	//SDD
	sdd = getSDD(fname)
	
	//Transmission
	trans = getSampleTrans(fname)
	
	//Thickness
	thick = getSampleThickness(fname)
		
	temp = "FILE:  "
	Notebook CatWin,textRGB=(0,0,0),text=temp
	Notebook CatWin,fstyle=1,text=sname
	temp = "\t\t"+date_time+"\r"
	Notebook CatWin,fstyle=0,text=temp
	temp = "LABEL: "+lbl+"\r"
	Notebook CatWin,text=temp
	temp = "COUNTING TIME: "+num2str(ctime)+" secs \t\tDETECTOR COUNT: "+num2str(detcnt)+"\r"
	Notebook CatWin,text=temp
	temp = "WAVELENGTH: "+num2str(lambda)+" A \tSDD: "+num2str(sdd)+" m \t"
	temp += "DET. CNT. RATE: "+num2str(cntrate)+"  cts/sec\r"
	Notebook CatWin,text=temp
	temp = "TRANS: " 
	Notebook CatWin,text=temp
	temp =  num2str(trans)
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp
	temp =  "\t\tTHICKNESS: "
	Notebook CatWin,textRGB=(0,0,0),fStyle = 0,text=temp
	temp =  num2str(thick)
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp
	temp = " cm\r\r"
	Notebook CatWin,textRGB=(0,0,0),fStyle = 0,text=temp
End


//****************
// main procedure for CAT/VS Notebook ******
//this main procedure does all the work, obtaining the folder path, 
//parsing the filenames in the list and (dispatching) to write out the 
//appropriate information to the notebook window
Proc BuildCatVeryShortNotebook()

	DoWindow/F CatWin
	If(V_Flag ==0)
		String nb = "CatWin"
		NewNotebook/F=1/N=$nb/W=(5.25,40.25,581.25,380.75) as "CATALOG Window"
		Notebook $nb defaultTab=36, statusWidth=238, pageMargins={72,72,72,72}
		Notebook $nb showRuler=1, rulerUnits=1, updating={1, 60}
		Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}
		Notebook $nb ruler=Normal; Notebook $nb  margins={0,0,544}
	Endif
	
	Variable err
	PathInfo catPathName
	if(v_flag==0)
		err = PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	String temp=""
	//clear old window contents, reset the path
	Notebook CatWin,selection={startOfFile,EndOfFile}
	Notebook CatWin,text="\r"
	
	PathInfo catPathName
	temp = "FOLDER: "+S_path+"\r\r"
	Notebook CatWin,font="Times",fsize=12,text = temp
	Notebook CatWin,fstyle=1,text="NAME"+", "
	temp = "Label"+", "
	Notebook CatWin,fstyle=0, text=temp
	temp = "CntTime"
	Notebook CatWin,fstyle=1,textRGB=(0,0,50000),text=temp
	temp = ", TotDetCnts, "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp = "Lambda"
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp
	temp = ", SDD, "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp = "CountRate"
	Notebook CatWin,textRGB=(0,50000,0),fStyle = 1,text=temp
	temp =  ", Transmission, "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp =  "Thickness"
	Notebook CatWin,textRGB=(0,0,50000),fStyle = 1,text=temp
	temp = ", Xposition"
	Notebook CatWin,textRGB=(0,0,0),fStyle = 0,text=temp
	temp = ", Yposition"
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 0,text=temp
	temp = "\r\r"
	Notebook CatWin,textRGB=(0,0,0),fStyle = 0,text=temp

	
	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	//remove version numbers from semicolon-delimited list
	list =  RemoveVersNumsFromList(list)
	
	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName,notRAWlist
	ii=0
	
	notRAWlist=""
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(str2num(partialName) == NaN)
				str = "this file was not found: "+partialName+"\r\r"
				Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				notRAWlist += "This file is not recognized as a RAW SANS data file: "+tempName+"\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			else
				//go write the header information to the Notebook
				WriteCatVSToNotebook(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
	Notebook CatWin,font="Times",fsize=12,text=notRAWlist
End

//writes out the CATalog information to the notebook named CatWin (which must exist)
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function WriteCatVSToNotebook(fname,sname)
	String fname,sname
	
	String textstr,temp,lbl,date_time
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick,xcenter,ycenter,numatten
	
	//read the file creation date
	date_time = getFileCreationDate(fname) 

	// read the sample.label text field
	lbl = getSampleLabel(fname)
	
	//read the counting time (integer)
	ctime = getCountTime(fname)
		
	//read the reals
	//detector count + countrate
	detcnt = getDetCount(fname)
	cntrate = detcnt/ctime
	
	//wavelength
	lambda = getWavelength(fname)
	
	//SDD
	sdd = getSDD(fname)
	
	//Transmission
	trans = getSampleTrans(fname)
	
	//Thickness
	thick = getSampleThickness(fname)
		
	//Attenuators
	numatten = getAttenNumber(fname)

	//XCenter
	xCenter = getBeamXPos(fname)

	//YCenter
	yCenter = getBeamYPos(fname)

	
	temp = ""
	Notebook CatWin,textRGB=(0,0,0),text=temp
	Notebook CatWin,fstyle=1,text=sname+", "
//	temp = ", "+date_time+", "
//	Notebook CatWin,fstyle=0,text=temp
	temp = lbl+", "
	Notebook CatWin,fstyle=0, text=temp
	temp = num2str(ctime)
	Notebook CatWin,fstyle=1,textRGB=(0,0,50000),text=temp
	temp = ", " + num2str(detcnt) + ", "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp = num2str(lambda)
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp
	temp = ", "+num2str(sdd)+", "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp = num2str(cntrate)
	Notebook CatWin,textRGB=(0,50000,0),fStyle = 1,text=temp
	temp =  ", "+num2str(trans)+", "
	Notebook CatWin,fstyle=0,textRGB=(0,0,0),text=temp
	temp =  num2str(thick)
	Notebook CatWin,textRGB=(0,0,50000),fStyle = 1,text=temp
	temp = ", "+num2str(xCenter)+", "
	Notebook CatWin,textRGB=(0,0,0),fStyle = 0,text=temp
  	temp = num2str(yCenter)+"\r"
	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp
	//temp = num2str(numatten)+", "
	//Notebook CatWin,text=temp
End