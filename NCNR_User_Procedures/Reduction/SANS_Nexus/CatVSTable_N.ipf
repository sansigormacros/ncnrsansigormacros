#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// RTI clean

// JAN 2022 - updated to add more columns of metadata
//
// Adding columns to the table now means:
// 1-Make the wave in BuildCatVeryShortTable
// 2-Declare the wave in GetHeaderInfoToWave, and read/fill in the value
// 3- update declarations in SortWaves
//
//
//
// new columns of PURPOSE and INTENT can have the values:
//   PURPOSE = Transmission, Scattering, He3
//   INTENT = Sample, Empty Cell, Blocked Beam, Open Beam, Standard
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
	
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:Intent"
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:Purpose"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Group_ID"	
	
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:SDD"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:YCenter"
//	Make/O/B/N=0 $"root:myGlobals:CatVSHeaderInfo:nGuides"
//	Make/O/B/N=0 $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Field"
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Pos"		//added Mar 2010
	//For ANSTO
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:SICS"	
	Make/O/T/N=0 $"root:myGlobals:CatVSHeaderInfo:HDF"
	
	Make/O/D/N=0 $"root:myGlobals:CatVSHeaderInfo:Reactorpower"       //only used for for ILL, June 2008,
	WAVE ReactorPower = $"root:myGlobals:CatVSHeaderInfo:Reactorpower"

	WAVE/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	WAVE/T Suffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	WAVE/T Labels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	WAVE/T DateAndTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	
	WAVE/T Intent = $"root:myGlobals:CatVSHeaderInfo:Intent"
	WAVE/T Purpose = $"root:myGlobals:CatVSHeaderInfo:Purpose"
	WAVE Group_ID = $"root:myGlobals:CatVSHeaderInfo:Group_ID"		
	
	WAVE SDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	WAVE Lambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	WAVE CntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	WAVE TotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	WAVE CntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	WAVE Transmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	WAVE Thickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	WAVE XCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	WAVE YCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
//	WAVE/B nGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
//	WAVE/B NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	WAVE nGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	WAVE NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	WAVE RunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	WAVE IsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	WAVE RotAngle = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	WAVE Temperature = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	WAVE Field = $"root:myGlobals:CatVSHeaderInfo:Field"
	WAVE MCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	WAVE Pos = $"root:myGlobals:CatVSHeaderInfo:Pos"
	//For ANSTO
	WAVE SICS = $"root:myGlobals:CatVSHeaderInfo:SICS"	
	WAVE HDF = $"root:myGlobals:CatVSHeaderInfo:HDF"
	
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
//#if (exists("QUOKKA")==6)
//		//ANSTO
//		ModifyTable width(:myGlobals:CatVSHeaderInfo:SICS)=80
//		ModifyTable width(:myGlobals:CatVSHeaderInfo:HDF)=40
//#endif		
//		
//#if (exists("ILL_D22")==6)
//		ModifyTable width(:myGlobals:CatVSHeaderInfo:Reactorpower)=50		//activate for ILL, June 2008
//#endif

#if (exists("NCNR_Nexus")==6)
		ModifyTable width(:myGlobals:CatVSHeaderInfo:intent)=60
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Group_ID)=50
		ModifyTable width(:myGlobals:CatVSHeaderInfo:nGuides)=40
		ModifyTable width(:myGlobals:CatVSHeaderInfo:Pos)=30
		ModifyTable sigDigits(:myGlobals:CatVSHeaderInfo:Pos)=3			//to make the display look nice, given the floating point values from ICE
		ModifyTable sigDigits(:myGlobals:CatVSHeaderInfo:Lambda)=3		//may not work in all situations, but an improvement
		ModifyTable sigDigits(:myGlobals:CatVSHeaderInfo:SDD)=5
		ModifyTable trailingZeros(:myGlobals:CatVSHeaderInfo:Temperature)=1
		ModifyTable sigDigits(:myGlobals:CatVSHeaderInfo:Temperature)=4
#endif

		ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run
		
		// (DONE - FEB 2020)
	//  x- experimental hook with contextual menu
	//		
		SetWindow kwTopWin hook=CatTableHook, hookevents=1	// mouse down events
	Endif


///////////// progress window

// NEW for SANS, from VSANS
// clear out the folders in the RawSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "bad" local copy will be read in for any subsequent operations.
//
// This will display a progress bar
	CleanoutRawSANS()

//	Variable numToClean
//	numToClean = CleanupData_w_Progress(0,1)
//
//	Print "Cleaned # files = ",numToClean
//	Print "Cleanup time (s) = ",(ticks - t1)/60.15
//	Variable cleanupTime = (ticks - t1)/60.15

// NOW - re-load all of the data in the folder to RawSANS

	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	numitems = ItemsInList(list,";")
	Variable sc=1
	NVAR/Z gLaptopMode = root:Packages:NIST:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	// show a progress bar for filling the file catalog
	Variable indefinite=0,useIgorDraw=1
	NewPanel /N=ProgressPanel /W=(285*sc,111*sc,739*sc,193*sc)
	ValDisplay valdisp0,win=ProgressPanel,pos={sc*18,32*sc},size={sc*342,18*sc},limits={0,numitems,0},barmisc={0,0}
	ValDisplay valdisp0,win=ProgressPanel,value= _NUM:0
	DrawText 20*sc,24*sc,"Refreshing file catalog... Please Wait..."

	if( indefinite )
		ValDisplay valdisp0,win=ProgressPanel,mode= 4	// candy stripe
	else
		ValDisplay valdisp0,win=ProgressPanel,mode= 3	// bar with no fractional part
	endif
	if( useIgorDraw )
		ValDisplay valdisp0,win=ProgressPanel,highColor=(49535,1000,1000)		//(0,65535,0)
	endif
	Button bStop,win=ProgressPanel,pos={sc*375,32*sc},size={sc*50,20*sc},title="Stop"
	DoUpdate /W=ProgressPanel /E=1	// mark this as our progress window
	
	
	//////////Now, build a fresh listing of files


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
		tempName = N_FindValidFilename(partialName)
		
		
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
			ok = N_CheckIfRawData(fullName)
		
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
		
		ValDisplay valdisp0,win=ProgressPanel,value= _NUM:ii
		DoUpdate /W=ProgressPanel
	while(ii<numitems)
	
	KillWindow ProgressPanel
	
//Now sort them all based on some criterion that may be facility dependent (aim is to order them as collected)
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
	
	if(numpnts(w) == 0)
		return(0)
	endif
	
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

	WAVE/T Intent = $"root:myGlobals:CatVSHeaderInfo:Intent"
	WAVE/T Purpose = $"root:myGlobals:CatVSHeaderInfo:Purpose"
	WAVE Group_ID = $"root:myGlobals:CatVSHeaderInfo:Group_ID"		


	Wave GSDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
//	Wave/B GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
//	Wave/B GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	Wave GPos = $"root:myGlobals:CatVSHeaderInfo:Pos"
	Wave/Z GReactPow = $"root:myGlobals:CatVSHeaderInfo:ReactorPower"		//activate for ILL June 2008 ( and the sort line too)
	//For ANSTO
	Wave/T GSICS = $"root:myGlobals:CatVSHeaderInfo:SICS"
	Wave/T GHDF = $"root:myGlobals:CatVSHeaderInfo:HDF"

#if (exists("ILL_D22")==6)
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,GReactPow
#elif (exists("NCNR_Nexus")==6)
	//	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR
	Sort GSuffix, GSuffix, GFilenames, Intent,Purpose,Group_ID, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,GPos,gNumGuides
#elif (exists("QUOKKA")==6)
    //ANSTO
	Sort GFilenames, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR, GSICS, GHDF
#else
//	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR
	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, Intent,Purpose,Group_ID, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR
#endif


	return(0)
End

//function to create the CAT/VSTable to display the header information
//this table is just like any other table
Function BuildTableWindow()
	Wave/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T Labels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T DateAndTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	
	WAVE/T Intent = $"root:myGlobals:CatVSHeaderInfo:Intent"
	WAVE/T Purpose = $"root:myGlobals:CatVSHeaderInfo:Purpose"
	WAVE Group_ID = $"root:myGlobals:CatVSHeaderInfo:Group_ID"		

	Wave SDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave Lambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave CntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave TotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave CntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave Transmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave Thickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave XCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave YCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
//	Wave/B NumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
//	Wave/B NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave NumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave NumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave RotAngle =  $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave Temperature = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave Field= $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave MCR = $"root:myGlobals:CatVSHeaderInfo:MCR"		//added Mar 2008
	Wave Pos = $"root:myGlobals:CatVSHeaderInfo:Pos"
	Wave/Z ReactorPower = $"root:myGlobals:CatVSHeaderInfo:reactorpower"       //activate for ILL, June 08 (+ edit line)
	Wave/Z SICS = $"root:myGlobals:CatVSHeaderInfo:SICS" // For ANSTO June 2010
	Wave/Z HDF = $"root:myGlobals:CatVSHeaderInfo:HDF" // For ANSTO June 2010
	
#if (exists("ILL_D22")==6)
	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR, ReactorPower as "Data File Catalog"
#elif (exists("NCNR_Nexus")==6)
// original order, magnetic at the end
//	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
// with numGuides
	Edit Filenames, Labels, DateAndTime, Intent,Purpose,Group_ID, SDD, Lambda, numGuides, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR, Pos as "Data File Catalog"
// alternate ordering, put the magnetic information first
//	Edit Filenames, Labels, RotAngle, Temperature, Field, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens as "Data File Catalog"
#elif (exists("QUOKKA")==6)
	//ANSTO
	Edit Filenames, Labels, DateAndTime,  SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR,SICS, HDF as "Data File Catalog"
#else
	// HFIR or anything else
	Edit Filenames, Labels, DateAndTime, Intent,Purpose,Group_ID,SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
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
	Variable lastPoint,ctime,detcnt,cntrate//,instrumentNum

	Wave/T GFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	
	WAVE/T Intent = $"root:myGlobals:CatVSHeaderInfo:Intent"
	WAVE/T Purpose = $"root:myGlobals:CatVSHeaderInfo:Purpose"
	WAVE Group_ID = $"root:myGlobals:CatVSHeaderInfo:Group_ID"		

	
	
	//ANSTO
	Wave/T GSICS = $"root:myGlobals:CatVSHeaderInfo:SICS"
	Wave/T GHDF = $"root:myGlobals:CatVSHeaderInfo:HDF"
	//END ANSTO
	Wave GSDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave GTransmission = $"root:myGlobals:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:myGlobals:CatVSHeaderInfo:Thickness"
	Wave GXCenter = $"root:myGlobals:CatVSHeaderInfo:XCenter"
	Wave GYCenter = $"root:myGlobals:CatVSHeaderInfo:YCenter"
//	Wave/B GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
//	Wave/B GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GNumGuides = $"root:myGlobals:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:myGlobals:CatVSHeaderInfo:NumAttens"
	Wave GRunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:myGlobals:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:myGlobals:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:myGlobals:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:myGlobals:CatVSHeaderInfo:MCR"
	Wave GPos = $"root:myGlobals:CatVSHeaderInfo:Pos"
	Wave GReactpow = $"root:myGlobals:CatVSHeaderInfo:reactorpower"		//activate for ILL, Jne 2008, (+ last insert @ end of function)	

	lastPoint = numpnts(GLambda)
		
	//filename
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file alphanumeric suffix
	// suffix does not exist for Nexus data. Write "NONE" for now? maybe replace this identifier with the
// run number or the actual file name, since that would be unique for the data file.
// would need to convert the wave to DP from current (text)
	InsertPoints lastPoint,1,GSuffix
	GSuffix[lastPoint]=getSuffix(fname)

	//read the counting time (integer)
	InsertPoints lastPoint,1,GCntTime
	ctime = getCount_time(fname)
	GCntTime[lastPoint]=ctime
	
	//read the file creation date
	InsertPoints lastPoint,1,GDateTime
	GDateTime[lastPoint]=getDataStartTime(fname)

	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleDescription(fname)
	
#if (exists("QUOKKA")==6)
		InsertPoints lastPoint,1,GSICS
		GSICS[lastPoint]=getSICSVersion(fname)
			
		//read the HDF version
		InsertPoints lastPoint,1,GHDF
		GHDF[lastPoint]=getHDFVersion(fname)
#endif
		
	//read the reals
	//detector count and (derived) count rate
	detcnt = getDetector_counts(fname)
	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,GTotCnts
	GTotCnts[lastPoint]=detcnt
	InsertPoints lastPoint,1,GCntRate
	GCntRate[lastPoint]=cntrate
	
	//Attenuators
	InsertPoints lastPoint,1,GNumAttens
	GNumAttens[lastPoint]=getAtten_number(fname)
	
	//Transmission
	InsertPoints lastPoint,1,GTransmission
	GTransmission[lastPoint]=getSampleTransmission(fname)
	
	//Thickness
	InsertPoints lastPoint,1,GThickness
	GThickness[lastPoint]=getSampleThickness(fname)

	//XCenter of beam on detector
	InsertPoints lastPoint,1,GXCenter
	GXCenter[lastPoint]=getDet_beam_center_x(fname)

	//YCenter
	InsertPoints lastPoint,1,GYCenter
	GYCenter[lastPoint]=getDet_beam_center_y(fname)

	//SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]=getDet_Distance(fname) / 100 // convert [cm] to [m]
	
	//wavelength
	InsertPoints lastPoint,1,GLambda
	GLambda[lastPoint]=getWavelength(fname)
	
	//Rotation Angle
	InsertPoints lastPoint,1,GRot
	GRot[lastPoint]=getSampleRotationAngle(fname)
	
	//Sample Temperature
	InsertPoints lastPoint,1,GTemp
	GTemp[lastPoint]=getSampleTemperature(fname)
	
	//Sample Field
	InsertPoints lastPoint,1,GField
	GField[lastPoint]=getFieldStrength(fname)
	
	//Beamstop position (not reported)
	//strToExecute = GBLoadStr + "/S=368/U=1" + "\"" + fname + "\""

	//the run number (not displayed in the table, but carried along)
	InsertPoints lastPoint,1,GRunNumber
	GRunNumber[lastPoint] = N_GetRunNumFromFile(sname)

	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = N_isTransFile(fname)		//returns one if beamstop is "out"
	
	// Monitor Count Rate
	InsertPoints lastPoint,1,GMCR
	GMCR[lastPoint]  = getBeamMonNormData(fname)/ctime		//total monitor count / total count time



#if (exists("ILL_D22")==6)
	// Reactor Power (activate for ILL)
	InsertPoints lastPoint,1,GReactpow
	GReactPow[lastPoint]  = getReactorPower(fname)
#endif	

// number of guides and sample position, only for NCNR
#if (exists("NCNR_Nexus")==6)

	// acct name is "[NGxSANSxx]" -- [1,3] is the instrument "name" "NGx"
	//so that Ng can be correctly calculated
	// in Nexus, this is the last extension, not necessarily the last 3 characters of the file name
	String/G root:Packages:NIST:SAS:gInstStr = getInstrName(fname) 
	
	InsertPoints lastPoint,1,GNumGuides
	GNumGuides[lastPoint]  = numGuides(getSourceAp_distance(fname)/100)		//  convert [cm] to [m]
	
	//Sample Position
	InsertPoints lastPoint,1,GPos
	GPos[lastPoint] = str2num(getSamplePosition(fname))
#endif

	//intent, purpose, and group_id
	InsertPoints lastPoint,1,Intent,Purpose,Group_ID
	Intent[lastPoint] = getReduction_intent(fname)
	Purpose[lastPoint] = getReduction_purpose(fname)
	Group_ID[lastPoint] = getSample_GroupID(fname)
	


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
		tempName = N_FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = N_CheckIfRawData(fullName)
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
	date_time = getDataStartTime(fname)

	// read the sample.label text field
	lbl = getSampleDescription(fname)
	
	//read the counting time (integer)
	ctime = getCount_time(fname)
		
	//read the reals
	
	//detector count + countrate
	detcnt = getDetector_counts(fname)
	cntrate = detcnt/ctime
	
	//wavelength
	lambda = getWavelength(fname)
	
	//SDD
	sdd = getDet_Distance(fname) / 100  // convert [cm] to [m]
	
	//Transmission
	trans = getSampleTransmission(fname)
	
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

//writes out the CATalog information to the notebook named CatWin (which must exist)
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
//
// this is just for 1D (not Raw) data files
Function Write_ABSHeader_toNotebook(fname,sname)
	String fname,sname
	
	String textstr,temp,lbl,date_time
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick
	
	//read the file creation date
	date_time = getDataStartTime(fname)

	// read the sample.label text field
	lbl = getSampleDescription(fname)
	
	//read the counting time (integer)
	ctime = getCount_time(fname)
		
	//read the reals
	
	//detector count + countrate
	detcnt = getDetector_counts(fname)
	cntrate = detcnt/ctime
	
	//wavelength
	lambda = getWavelength(fname)
	
	//SDD
	sdd = getDet_Distance(fname) / 100  // convert [cm] to [m]
	
	//Transmission
	trans = getSampleTransmission(fname)
	
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
		tempName = N_FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = N_CheckIfRawData(fullName)
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
	date_time = getDataStartTime(fname) 

	// read the sample.label text field
	lbl = getSampleDescription(fname)
	
	//read the counting time (integer)
	ctime = getCount_time(fname)
		
	//read the reals
	//detector count + countrate
	detcnt = getDetector_counts(fname)
	cntrate = detcnt/ctime
	
	//wavelength
	lambda = getWavelength(fname)
	
	//SDD
	sdd = getDet_Distance(fname) / 100	// convert [cm] to [m]
	
	//Transmission
	trans = getSampleTransmission(fname)
	
	//Thickness
	thick = getSampleThickness(fname)
		
	//Attenuators
	numatten = getAtten_number(fname)

	//XCenter
	xCenter = getDet_beam_center_x(fname)

	//YCenter
	yCenter = getDet_beam_center_y(fname)

	
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


//
// TODO:
// -- FEB 2020 copied this function over from VSANS, since it was popular there
//
// -- what else to add to the menu? (MSK and DIV now work)
// -- add directly to WORK files?
// -- "set" as some special file type, intent, use? (quick "patch" operations)
// -- "check" the reduction protocol for completeness?
//
// x- seems to not "let go" of a selection (missing the mouse up?)
//    (possibly) less annoying if I only handle mouseup and present a menu then.
//
//
// // new columns of PURPOSE and INTENT can have the values:
//   PURPOSE = Transmission, Scattering, He3
//   INTENT = Sample, Empty Cell, Blocked Beam, Open Beam, Standard
//
//
Function CatTableHook(infoStr)
	String infoStr
	String event= StringByKey("EVENT",infoStr)
	
	Variable ii
	
	String pathStr
	PathInfo catPathName
	pathStr = S_path
	
//	Print "EVENT= ",event
	strswitch(event)
		case "mouseup":
//			Variable xpix= NumberByKey("MOUSEX",infoStr)
//			Variable ypix= NumberByKey("MOUSEY",infoStr)
//			PopupContextualMenu/C=(xpix, ypix) "yes;no;maybe;"

//		determine which column has been selected
// answers are:
// column =   Intent.d;
// column =   Purpose.d; (ignore the input if multiple columns are selected, revert to "Load")
			GetSelection table,CatVSTable,2
//			Print "column = ",S_selection

			if(cmpstr(S_selection,"Intent.d;") == 0)
				PopupContextualMenu "Change Intent;-;Sample;Empty Cell;Blocked Beam;Open Beam;Standard;"
				
			elseif(cmpstr(S_selection,"Purpose.d;") == 0)
				PopupContextualMenu "Change Purpose;-;TRANSMISSION;SCATTERING;He3;"
				
			else
				PopupContextualMenu "Load RAW;Load MSK;Load DIV;-;Send to MRED;"

			endif
			

			WAVE/T Filenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
			Variable err
			strswitch(S_selection)			// S_selection is now the contextual selection
				case "Load RAW":
					GetSelection table,CatVSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					LoadRawSANSData(pathStr + FileNames[V_StartRow],"RAW")	//this is the full Path+file
//					err = V_LoadHDF5Data(FileNames[V_StartRow],"RAW")
					if(!err)		//directly from, and the same steps as DisplayMainButtonProc(ctrlName)
						// this (in SANS) just passes directly to fRawWindowHook()
						UpdateDisplayInformation("RAW")		// plot the data in whatever folder type
					endif
					break
					
				case "Load MSK":
					GetSelection table,CatVSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					LoadRawSANSData(pathStr + FileNames[V_StartRow],"MSK")
					Execute "maskButtonProc(\"maskButton\")"
					
					break
					
				case "Load DIV":
					GetSelection table,CatVSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					
					LoadRawSANSData(pathStr + FileNames[V_StartRow], "DIV")
					
					break
				case "Send to MRED":
					//  root:myGlobals:MRED:gFileNumList
					SVAR/Z numList=root:myGlobals:MRED:gFileNumList
					if(SVAR_Exists(numList))
						GetSelection table,CatVSTable,1
						for(ii=V_StartRow;ii<=V_endRow;ii+=1)
	//						Print "selected " + FileNames[ii]
							numList += fileNames[ii] + ","
						endfor
						// pop the menu on the mred panel
						MREDPopMenuProc("",1,"")
					endif
					break

// popups to modify the purpose or intent
// Purpose -- Transmission;Scattering;He3;
				case "TRANSMISSION":
					Wave/T purpose = root:myGlobals:CatVSHeaderInfo:Purpose
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReduction_Purpose(fileNames[ii],"TRANSMISSION")	
						purpose[ii] = "TRANSMISSION"			//update the table too
					break
				case "SCATTERING":
					Wave/T purpose = root:myGlobals:CatVSHeaderInfo:Purpose
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReduction_Purpose(fileNames[ii],"SCATTERING")	
						purpose[ii] = "SCATTERING"			//update the table too
					break
				case "He3":
					Wave/T purpose = root:myGlobals:CatVSHeaderInfo:Purpose
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReduction_Purpose(fileNames[ii],"He3")	
						purpose[ii] = "He3"			//update the table too
					break
					
// Intent --  "Change Intent;-;Sample;Empty Cell;Blocked Beam;Open Beam;Standard;"
				case "Sample":
					Wave/T intent = root:myGlobals:CatVSHeaderInfo:Intent
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReductionIntent(fileNames[ii],"Sample")	
						intent[ii] = "Sample"			//update the table too
					break
				case "Empty Cell":
					Wave/T intent = root:myGlobals:CatVSHeaderInfo:Intent
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReductionIntent(fileNames[ii],"Empty Cell")	
						intent[ii] = "Empty Cell"			//update the table too
					break
				case "Blocked Beam":
					Wave/T intent = root:myGlobals:CatVSHeaderInfo:Intent
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReductionIntent(fileNames[ii],"Blocked Beam")	
						intent[ii] = "Blocked Beam"			//update the table too
					break
				case "Open Beam":
					Wave/T intent = root:myGlobals:CatVSHeaderInfo:Intent
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReductionIntent(fileNames[ii],"Open Beam")	
						intent[ii] = "Open Beam"			//update the table too
					break
				case "Standard":
					Wave/T intent = root:myGlobals:CatVSHeaderInfo:Intent
						GetSelection table,CatVSTable,1
						ii = V_StartRow
						writeReductionIntent(fileNames[ii],"Standard")	
						intent[ii] = "Standard"			//update the table too
					break
					
					
			endswitch		//popup selection
	endswitch	// event
	
	return 0
End



/////////// SORT CATALOG PANEL



// just to call the function to generate the panel
Proc S_Catalog_Sort()
	S_BuildCatSortPanel()
End

// [davidm] create CAT Sort-Panel
Function S_BuildCatSortPanel()

	// check if CatSANSTable exists
	DoWindow CatVSTable
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

	Variable sc=1
	
	NVAR gLaptopMode = root:Packages:NIST:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif
		
	//PauseUpdate
	NewPanel /W=(600*sc,360*sc,790*sc,740*sc)/K=1 as "CAT - Sort Panel"
	DoWindow/C CatSortPanel
	ModifyPanel fixedSize=1, cbRGB = (42919, 53970, 60909)
	
	Button SortFilenamesButton,	pos={sc*25, 8*sc},		size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Filenames"
	Button SortLabelsButton,		pos={sc*25,38*sc},		size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Labels"
	Button SortDateAndTimeButton,	pos={sc*25,68*sc},		size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Date and Time"

	Button SortLambdaButton,		pos={sc*25,98*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Lambda"
	Button SortCountTimButton,		pos={sc*25,128*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Count Time"
	Button SortSDDFButton,			pos={sc*25,158*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="SDD"
	Button SortCountRateFButton,	pos={sc*25,188*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Count Rate"
	Button SortMonitorCountsButton,	pos={sc*25,218*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Monitor Counts"
	Button SortTransmissionButton,pos={sc*25,248*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Transmission"

	Button SortIntentButton,		pos={sc*25,278*sc},		size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Intent"
	Button SortPurposeButton,		pos={sc*25,308*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Purpose"
	Button SortIDButton,				pos={sc*25,338*sc},	size={sc*140,24*sc},proc=S_CatSANSTable_SortProc,title="Group ID"
end

Proc S_CatSANSTable_SortProc(ctrlName) : ButtonControl // added by [davidm]
	String ctrlName
	
	// check if CatSANSTable exists
	DoWindow CatVSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return
	endif
		
	// have to use function
	S_CatSANSTable_SortFunction(ctrlName)
	
end

function S_CatSANSTable_SortFunction(ctrlName) // added by [davidm]
	String ctrlName

// still need to declare these to access notRaw files and to get count of length
	Wave/T GFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T GLabels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	
	// take out the "not-RAW-Files"
	Variable fileCount = numpnts(GFilenames)
	Variable rawCount = numpnts(GLabels)
	Variable notRAWcount = fileCount - rawCount
	
	if (notRAWcount > 0)
		Make/T/O/N=(notRAWcount) notRAWlist
		notRAWlist[0, notRAWcount-1] = GFilenames[p+rawCount]
		DeletePoints rawCount, notRAWcount, GFilenames
	endif


// get the list
	SetDataFolder root:myGlobals:CatVSHeaderInfo:
	
	String list = WaveList("*",",",""),sortKey=""
	String cmd
	
	list = list[0,strlen(list)-2]		//remove the trailing comma or "invalid column name" error
	list = RemoveFromList("HDF",list,",")		//these are not tracked at the NCNR
	list = RemoveFromList("SICS",list,",")		//these are not tracked at the NCNR
	list = RemoveFromList("Reactorpower",list,",")	//these are not tracked at the NCNR
	
// set the sortKey string	
	strswitch (ctrlName)
	
		case "SortFilenamesButton":
			sortKey = "Filenames"
			break
			
		case "SortLabelsButton":
			sortKey = "Labels"
			break
			
		case "SortDateAndTimeButton":
			sortKey = "DateAndTime"

			break
			
		case "SortIntentButton":
			sortKey = "Intent"

			break
			
		case "SortIDButton":
			sortKey = "Group_ID"

			break
			
		case "SortLambdaButton":
			sortKey = "Lambda"

			break
			
		case "SortCountTimButton":
			sortKey = "CntTime"

			break
			
		case "SortSDDFButton":
			sortKey = "SDD"

			break
			
		case "SortCountRateFButton":
			sortKey = "CntRate"

			break
			
		case "SortMonitorCountsButton":
			sortKey = "MCR"

			break
			
		case "SortTransmissionButton":
			sortKey = "Transmission"

			break
			
		case "SortPurposeButton":
			sortKey = "Purpose"

			break
	
	endswitch
	
	//do the sort
//	sprintf cmd, "Sort %s, %s", sortKey,list
// use braces and second key to keep anything with the same first "key" value in numerical run number order
	sprintf cmd, "Sort {%s,Filenames} %s", sortKey,list
//	Print cmd			// For debugging
	
	Execute cmd
	
	
	// insert the "not-RAW-Files" again
	if (notRAWcount > 0)
		InsertPoints rawCount, notRAWcount, GFilenames
		GFilenames[rawCount, fileCount-1] = notRAWlist[p-rawCount]
	endif
	
	SetDataFolder root:

end

/////////////////

