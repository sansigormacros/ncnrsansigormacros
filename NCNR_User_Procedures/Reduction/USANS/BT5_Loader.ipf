#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1

/////////////////////////
// 101001 Vers. 1
//
// functions to load and parse the ASCII ICP files generated at BT5 USANS
// Nearly all of the important information about the data is dragged around
// with the DetCts wave as a wave note
//
// - thes wave note is a string of KEY:value items
//
//	str = "FILE:"+filen+";"
//	str += "TIMEPT:"+num2str(counttime)+";"
//	str += "PEAKANG:;"		//no value yet
//	str += "STATUS:;"		//no value yet
//	str += "LABEL:"+fileLabel+";"
//	str += "PEAKVAL:;"		//no value yet
//	str += "TWIDE:0;"		//no value yet
//
/////////////////////////


//given the filename, loads a single data file into a "TYPE" folder, into a
//series of 1D waves. counting time is associated with the DetCts wave as a note
//"blank" note entries are set up here as well, so later they can be polled/updated
Function LoadBT5File(fname,type)
	String fname,type

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Variable num=500,err=0,refnum
	Make/O/D/N=(num) $(USANSFolder+":"+type+":Angle")
	Make/O/D/N=(num) $(USANSFolder+":"+type+":DetCts")
	Make/O/D/N=(num) $(USANSFolder+":"+type+":ErrDetCts")
	Make/O/D/N=(num) $(USANSFolder+":"+type+":MonCts")
	Make/O/D/N=(num) $(USANSFolder+":"+type+":TransCts")
	Wave Angle = $(USANSFolder+":"+type+":Angle")
	Wave DetCts = $(USANSFolder+":"+type+":DetCts")
	Wave ErrDetCts = $(USANSFolder+":"+type+":ErrDetCts")
	Wave MonCts = $(USANSFolder+":"+type+":MonCts")
	Wave TransCts = $(USANSFolder+":"+type+":TransCts")
	
	Open/R refNum as fname		//if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif
	//read in the ASCII data line-by-line
	Variable numLinesLoaded = 0,firstchar,countTime
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,ii,valuesRead
	String buffer ="",s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
	String filen="",fileLabel="",filedt=""
	
	Variable MainDeadTime,TransDeadTime
	
	//parse the first line
	FReadLine refnum,buffer
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s",s1,s2,s3,s4,s5,s6,v1,v2,s7,v3,s8
	ii=strlen(s1)
	filen=s1[1,(ii-2)]			//remove the ' from beginning and end
	//Print "filen = ",filen,strlen(filen)
	//v2 is the monitor prefactor. multiply monitor time by prefactor. AJJ 5 March 07
	countTime=v1*v2
	//Print "time (sec) = ",countTime
	
	//Deadtime correction
	//Discovered significant deadtime on detectors in Oct 2010
	//JGB and AJJ changed pre-amps during shutdown Oct 27 - Nov 7 2010
	//Need different deadtime before and after 8th November 2010
	filedt = s2+" "+s3+" "+s4+" "+s5
	ii=strlen(filedt)
	filedt = filedt[1,(ii-2)]
		
//	print filedt
//	print BT5Date2Secs(filedt)
//	print date2secs(2010,11,7)
	
	// as of Feb 6 2019, USANS is using NICE for data collection rather than ICP
	// as a consequence, the data file is somewhat different. Specifically, the 
	// order of the detectors in the comma-delimited list is different, with the
	// 5 main detectors all listed in order, rather than separated.
	// --- I can either flag on the date, or set a global to switch
	// I also do not know if there will be any other changes in the data file format
	
	Variable useNewDataFormat

// test by date
	Variable thisFileSecs
	NVAR switchSecs = root:Packages:NIST:USANS:Globals:MainPanel:gFileSwitchSecs
	thisFileSecs = BT5DateTime2Secs(filedt)		// could use BT5Date2Secs() to exclude HR:MIN
	if(thisFileSecs >= switchSecs)
		useNewDataFormat = 1
	else
		useNewDataFormat = 0
	endif

// or use the global
//	NVAR gVal = root:Packages:NIST:gUseNICEDataFormat	
//	useNewDataFormat = gVal
	
	
	USANS_DetectorDeadtime(filedt,MainDeadTime,TransDeadTime)
	
	//skip line 2
	FReadLine refnum,buffer
	//the next line is the sample label, use it all, minus the terminator
	FReadLine refnum,filelabel
	
	//skip the next 10 lines
	For(ii=0;ii<10;ii+=1)
		FReadLine refnum,buffer
	EndFor
	
	//read the data until EOF - assuming always a pair or lines
	do
		FReadLine refNum, buffer
		if (strlen(buffer) == 0)
			break							// End of file
		endif
		firstChar = char2num(buffer[0])
		if ( (firstChar==10) || (firstChar==13) )
			break							// Hit blank line. End of data in the file.
		endif
		sscanf buffer,"%g%g%g%g%g",v1,v2,v3,v4,v5		// 5 values here now
		angle[numlinesloaded] = v1		//[0] is the ANGLE
		
		FReadLine refNum,buffer	//assume a 2nd line is there, w/16 values
		sscanf buffer,"%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g",v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16
		//valuesRead = V_flag
		//print valuesRead
		if(useNewDataFormat == 1)
		// new order is MonCt, det1,det2,det3,det4,det5, Trans
			MonCts[numlinesloaded] = v1		//monitor
			v2 = v2/(1.0-v2*MainDeadTime/countTime)   // Deadtime correction
			v3 = v3/(1.0-v3*MainDeadTime/countTime)   // Deadtime correction
			v4 = v6/(1.0-v4*MainDeadTime/countTime)   // Deadtime correction
			v5 = v5/(1.0-v5*MainDeadTime/countTime)   // Deadtime correction
			v6 = v6/(1.0-v6*MainDeadTime/countTime)   // Deadtime correction
			DetCts[numlinesloaded] = v2 + v3 + v4 + v5 + v6		//5 detectors
			TransCts[numlinesloaded] = v7/(1.0-v7*TransDeadTime/countTime)		//trans detector+deadtime correction
			ErrDetCts[numlinesloaded] = sqrt(detCts[numlinesloaded])
			//values 8-16 are always zero
		else
		// this is the original format from ICP
			MonCts[numlinesloaded] = v1		//monitor
			v2 = v2/(1.0-v2*MainDeadTime/countTime)   // Deadtime correction
			v3 = v3/(1.0-v3*MainDeadTime/countTime)   // Deadtime correction
			v5 = v5/(1.0-v5*MainDeadTime/countTime)   // Deadtime correction
			v6 = v6/(1.0-v6*MainDeadTime/countTime)   // Deadtime correction
			v7 = v7/(1.0-v7*MainDeadTime/countTime)   // Deadtime correction
			DetCts[numlinesloaded] = v2 + v3 + v5 + v6 + v7		//5 detectors
			TransCts[numlinesloaded] = v4/(1.0-v4*TransDeadTime/countTime)		//trans detector+deadtime correction
			ErrDetCts[numlinesloaded] = sqrt(detCts[numlinesloaded])
			//values 8-16 are always zero
		endif
		
		numlinesloaded += 1		//2 lines in file read, one "real" line of data
	while(1)
		
	Close refNum		// Close the file.
	//Print "numlines = ",numlinesloaded
	//trim the waves to the correct number of points
	Redimension/N=(numlinesloaded) Angle,MonCts,DetCts,TransCts,ErrDetCts
	
	//remove LF from end of filelabel
	filelabel=fileLabel[0,(strlen(fileLabel)-2)]
	
	//set the wave note for the DetCts
	String str=""
	str = "FILE:"+filen+";"
	str += "TIMEPT:"+num2str(counttime)+";"
	str += "PEAKANG:;"		//no value yet
	str += "STATUS:;"		//no value yet
	str += "LABEL:"+fileLabel+";"
	str += "PEAKVAL:;"		//no value yet
	str += "TWIDE:0;"		//no value yet
	Note DetCts,str
	
	String/G fileLbl = filelabel
	return err			// Zero signifies no error.	
End


//will search for peak in root:type:DetCts,  find and returns the angle
// of the peak poistion (= q=0)
//returns -9999 if error, appends value to wavenote
// !can't return -1,0,1, since these may be the peak angle!
//
Function FindZeroAngle(type)
	String type
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder	
	
	Variable pkNotFound,pkPt,pkAngle,pkVal,temp
	Wave angle = $(USANSFolder+":"+type+":Angle")
	Wave detCts = $(USANSFolder+":"+type+":DetCts")


	WaveStats/Q detcts
	temp=V_Maxloc		//in points
	FindPeak/P/Q/M=10/R=[(temp-10),(temp+10)] DetCts		//+/- 10 pts from maximum
	
	//FindPeak/P/Q/M=(1000) detCts		// /M=min ht -- peak must be at least 100x higher than 1st pt
	pkNotFound=V_Flag		//V_Flag==1 if no pk found
	pkPt = V_PeakLoc
	pkVal = V_PeakVal		//for calc of T_rock
	if(pkNotFound)
		//DoAlert 0, "Peak not found"
		Return (-9999)		//fatal error
	Endif
	pkAngle = Angle[pkPt]
	//Print "Peak Angle = ",pkAngle
	//update the note
	String str=""
	str=note(DetCts)
	str = ReplaceNumberByKey("PEAKANG",str,pkangle,":",";")
	str = ReplaceNumberByKey("PEAKVAL",str,pkVal,":",";")
	Note/K DetCts
	Note detCts,str
	
	return(pkAngle)
End

// given the peakAngle (q=0) and the "type" folder of scattering angle, 
// convert the angle to Q-values [degrees to (1/A)]
// makes a new Qvals wave, duplicating the Angle wave, which is assumed to exist
// Uses a conversion constant supplied by John Barker, and is hard-wired in
//
Function ConvertAngle2Qvals(type,pkAngle)
	String type
	Variable pkAngle

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Wave angle = $(USANSFolder+":"+type+":Angle")
	Variable num=numpnts(angle)
//	Variable deg2QConv=5.55e-5		//JGB -- 2/24/01
	NVAR deg2QConv=root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv

	
	Make/O/N=(num) $(USANSFolder+":"+type+":Qvals")
	Wave qvals = $(USANSFolder+":"+type+":Qvals")	
	Qvals = deg2QConv*(angle[p] - pkAngle)
	
	return(0)	//no error
End

//updates the wavenote with the average Trans det cts for calculation of T_Wide
//  finds the average number of counts on the transmission detector at angles
// greater than 2 deg. (per John, practical experience where the trans data levels off)
//
// error value of 1 is returned and wavenote not updated if level is not found
// 
// now normalizes to the monitor counts
//
// 17 APR 2013 SRK - coverted the 2 degree "cutoff" to use q-values instead. Then the 
//  location is generic and can be used for either NCNR or KUSANS
//
Function FindTWideCts(type)
	String type
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Variable levNotFound,levPt,Cts,num,ii,sumMonCts
	
	Wave angle = $(USANSFolder+":"+type+":Angle")
	Wave detCts = $(USANSFolder+":"+type+":DetCts")
	Wave TransCts = $(USANSFolder+":"+type+":TransCts")
	Wave monCts = $(USANSFolder+":"+type+":MonCts")
	Wave Qvals = $(USANSFolder+":"+type+":Qvals")
	
	num=numpnts(TransCts)

//	FindLevel/Q/P angle,2		//use angles greater than 2 deg
//	Print "Using angle, pt = ",V_levelX
	
	FindLevel/Q/P Qvals,1e-4		//use angles greater than 2 deg = 2*5.55e-5 = 1e-4 (1/A)
	Print "Using Qval, pt = ",V_levelX

	levNotFound=V_Flag		//V_Flag==1 if no pk found
	
	if(levNotFound)
		//post a warning, and use just the last 4 points...
//		DoAlert 0,"You don't have "+type+" data past 2 degrees - so Twide may not be reliable"
		DoAlert 0,"You don't have "+type+" data past 1e-4 A-1 (~2 degrees) - so Twide may not be reliable"
		levPt = num-4
	else
		levPt = trunc(V_LevelX)		// in points, force to integer
	endif
	
	//average the trans cts from levPt to the end of the dataset
	Cts=0
	sumMonCts=0
	
	for(ii=levPt;ii<num;ii+=1)
		Cts += transCts[ii]
		sumMonCts += monCts[ii]
	endfor
	// get the average over that number of data points
	sumMonCts /= (num-levPt-1)
	Cts /= (num-levPt-1)
	
//	Print "cts = ",cts
//	Print "sumMoncts = ",sumMoncts
	
	//normalize to the average monitor counts
	Cts /= sumMonCts
	
//	Print "normalized counts = ",cts


	//update the note
	Wave DetCts = $(USANSFolder+":"+type+":DetCts")
	String str,strVal
	str=note(DetCts)
	str = ReplaceNumberByKey("TWIDE",str,Cts,":",";")
	Note/K DetCts
	Note detCts,str

	return(0)
End


Function BT5DateTime2Secs(datestring)
	String datestring
	
	Variable bt5secs
	
	String monthnums = "Jan:1;Feb:2;Mar:3;Apr:4;May:5;Jun:6;Jul:7;Aug:8;Sep:9;Oct:10;Nov:11;Dec:12"
		
	Variable bt5month = str2num(StringByKey(stringfromlist(0,datestring, " "),monthnums))
	Variable bt5day = str2num(stringfromlist(1,datestring," "))
	Variable bt5year = str2num(stringfromlist(2,datestring," "))
	Variable bt5hours = str2num(stringfromlist(0,stringfromlist(3,datestring," "),":"))
	Variable bt5mins = str2num(stringfromlist(1,stringfromlist(3,datestring," "),":"))
	
	bt5secs = date2secs(bt5year,bt5month,bt5day) + 3600*bt5hours + 60*bt5mins

	return bt5secs
End

Function BT5Date2Secs(datestring)
	String datestring
	
	Variable bt5secs
	
	String monthnums = "Jan:1;Feb:2;Mar:3;Apr:4;May:5;Jun:6;Jul:7;Aug:8;Sep:9;Oct:10;Nov:11;Dec:12"
		
	Variable bt5month = str2num(StringByKey(stringfromlist(0,datestring, " "),monthnums))
	Variable bt5day = str2num(stringfromlist(1,datestring," "))
	Variable bt5year = str2num(stringfromlist(2,datestring," "))
	
	bt5secs = date2secs(bt5year,bt5month,bt5day)

	return bt5secs
End