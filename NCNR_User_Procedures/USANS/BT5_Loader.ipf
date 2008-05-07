#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.0

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
	
	Variable num=200,err=0,refnum
	Make/O/D/N=(num) $("root:"+type+":Angle")
	Make/O/D/N=(num) $("root:"+type+":DetCts")
	Make/O/D/N=(num) $("root:"+type+":ErrDetCts")
	Make/O/D/N=(num) $("root:"+type+":MonCts")
	Make/O/D/N=(num) $("root:"+type+":TransCts")
	Wave Angle = $("root:"+type+":Angle")
	Wave DetCts = $("root:"+type+":DetCts")
	Wave ErrDetCts = $("root:"+type+":ErrDetCts")
	Wave MonCts = $("root:"+type+":MonCts")
	Wave TransCts = $("root:"+type+":TransCts")
	
	Open/R refNum as fname		//if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif
	//read in the ASCII data line-by-line
	Variable numLinesLoaded = 0,firstchar,countTime
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,ii,valuesRead
	String buffer ="",s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
	String filen="",fileLabel=""
	
	//parse the first line
	FReadLine refnum,buffer
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s",s1,s2,s3,s4,s5,s6,v1,v2,s7,v3,s8
	ii=strlen(s1)
	filen=s1[1,(ii-2)]			//remove the ' from beginning and end
	//Print "filen = ",filen,strlen(filen)
	//v2 is the monitor prefactor. multiply monitor time by prefactor. AJJ 5 March 07
	countTime=v1*v2
	//Print "time (sec) = ",countTime
	
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
		sscanf buffer,"%g%g%g",v1,v2,v3		//v2,v3 not used
		angle[numlinesloaded] = v1		//[0] is the ANGLE
		
		FReadLine refNum,buffer	//assume a 2nd line is there, w/16 values
		sscanf buffer,"%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g",v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16
		//valuesRead = V_flag
		//print valuesRead
		MonCts[numlinesloaded] = v1		//monitor
		DetCts[numlinesloaded] = v2 + v3 + v5 + v6 + v7		//5 detectors
		TransCts[numlinesloaded] = v4		//trans detector
		ErrDetCts[numlinesloaded] = sqrt(detCts[numlinesloaded])
		//values 8-16 are always zero
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
	
	Variable pkNotFound,pkPt,pkAngle,pkVal,temp
	Wave angle = $("root:"+type+":Angle")
	Wave detCts = $("root:"+type+":DetCts")

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
	
	Wave angle = $("root:"+type+":Angle")
	Variable num=numpnts(angle)
	Variable deg2QConv=5.55e-5		//JGB -- 2/24/01
	
	Make/O/N=(num) $("root:"+type+":Qvals")
	Wave qvals = $("root:"+type+":Qvals")	
	Qvals = deg2QConv*(angle[p] - pkAngle)
	
	return(0)	//no error
End

//updates the wavenote with the average Trans det cts for calculation of T_Wide
//  finds the average number of counts on the transmission detector at angles
// greater than 2 deg. (per John, practical experience where the trans data levels off)
//
// error value of 1 is returned and wavenote not updated if level is not found
// 
//
Function FindTWideCts(type)
	String type
	
	Variable levNotFound,levPt,Cts,num,ii
	Wave angle = $("root:"+type+":Angle")
	Wave detCts = $("root:"+type+":DetCts")
	Wave TransCts = $("root:"+type+":TransCts")
	FindLevel/Q/P angle,2		//use angles greater than 2 deg
	levNotFound=V_Flag		//V_Flag==1 if no pk found
	if(levNotFound)
		return(1)
	endif
	levPt = trunc(V_LevelX)		// in points, force to integer
	
	//average the trans cts from levPt to the end of the dataset
	num=numpnts(TransCts)
	Cts=0
	for(ii=levPt;ii<num;ii+=1)
		Cts += transCts[ii]
	endfor
	Cts /= (num-levPt-1)
	
	//update the note
	Wave DetCts = $("root:"+type+":DetCts")
	String str,strVal
	str=note(DetCts)
	str = ReplaceNumberByKey("TWIDE",str,Cts,":",";")
	Note/K DetCts
	Note detCts,str
	
	return(0)
End