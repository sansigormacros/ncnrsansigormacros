#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// this file contains globals and functions that are specific to a
// particular facility or data file format
// branched out 29MAR07 - SRK
//
// functions are either labeled with the procedure file that calls them,
// or noted that they are local to this file


// initializes globals that are specific to a particular facility
// - number of XY pixels
// - pixexl resolution [cm]
// - detector deadtime constant [s]
//
// called by Initialize.ipf
//
Function InitFacilityGlobals()

	//Detector -specific globals
	Variable/G root:myGlobals:gNPixelsX=128					// number of X and Y pixels
	Variable/G root:myGlobals:gNPixelsY=128
	
	// pixel dimensions are now read directly from the file header.
//	Variable/G root:myGlobals:PixelResDefault = 0.5			//pixel resolution in cm
	
	Variable/G root:myGlobals:DeadtimeDefault =  (0.9e-6 )/128		//deadtime in seconds
	
	Variable/G root:myGlobals:BeamstopYTol = 100	

	Variable/G root:myGlobals:apOff = 5.0		// (cm) distance from sample aperture to sample position

	// changing behavior specific to ILL correction of data
	Variable/G root:myGlobals:gDoDetectorEffCorr = 1				//default state is ==1


End


//**********************
// Resolution calculation - used by the averaging routines
// to calculate the resolution function at each q-value
// - the return value is not used
//
// equivalent to John's routine on the VAX Q_SIGMA_AVE.FOR
// Incorporates eqn. 3-15 from J. Appl. Cryst. (1995) v. 28 p105-114
//
// - 21 MAR 07 uses projected BS diameter on the detector
// - APR 07 still need to add resolution with lenses. currently there is no flag in the 
//          raw data header to indicate the presence of lenses.
//
// - Aug 07 - added input to switch calculation based on lenses (==1 if in)
//
// - called by CircSectAvg.ipf and RectAnnulAvg.ipf
//
// passed values are read from RealsRead
// except DDet and apOff, which are set from globals before passing
//
//
Function/S getResolution(inQ,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,SigmaQ,QBar,fSubS)
	Variable inQ, lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses
	Variable &fSubS, &QBar, &SigmaQ		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, q_small, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]

	String results
	results ="Failure"

	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]
	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
	Variable LB
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	q_small = 2.0*Pi*(BS-a2)*(1.0-lambdaWidth)/(lambda*L2)
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
//	if(usingLenses==1)			//SRK 2007
	if(usingLenses != 0)			//SRK 2008 allows for the possibility of different numbers of lenses in header
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007

	r0 = L2*tan(2.0*asin(lambda*inQ/(4.0*Pi) ))
	delta = 0.5*(BS - r0)^2/v_d

	if (r0 < BS) 
		inc_gamma=exp(gammln(1.5))*(1-gammp(1.5,delta))
	else
		inc_gamma=exp(gammln(1.5))*(1+gammp(1.5,delta))
	endif

	fSubS = 0.5*(1.0+erf( (r0-BS)/sqrt(2.0*v_d) ) )
	if (fSubS <= 0.0) 
		fSubS = 1.e-10
	endif
	fr = 1.0 + sqrt(v_d)*exp(-1.0*delta) /(r0*fSubS*sqrt(2.0*Pi))
	fv = inc_gamma/(fSubS*sqrt(Pi)) - r0^2*(fr-1.0)^2/v_d

	rmd = fr*r0
	v_r1 = v_b + fv*v_d +v_g

	rm = rmd + 0.5*v_r1/rmd
	v_r = v_r1 - 0.5*(v_r1/rmd)^2
	if (v_r < 0.0) 
		v_r = 0.0
	endif
	QBar = (4.0*Pi/lambda)*sin(0.5*atan(rm/L2))
	SigmaQ = QBar*sqrt(v_r/rmd^2 +v_lambda)

	results = "success"
	Return results
End


//Utility function that returns the detector resolution (in cm)
//Global values are set in the Initialize procedure
//
// - called by CircSectAvg.ipf, RectAnnulAvg.ipf, and ProtocolAsPanel.ipf
//
// fileStr is passed as TextRead[3]
// detStr is passed as TextRead[9]
//
// *** as of Jan 2008, depricated. Now detector pixel sizes are read from the file header
// rw[10] = x size (mm); rw[13] = y size (mm)
//
// depricated - pixel dimensions are read directly from the file header
Function xDetectorPixelResolution(fileStr,detStr)
	String fileStr,detStr
	
	Variable DDet

	//your code here
//	DDet= getRealValueFromHeader_2(fileStr,60,28,5,11,5) 
	
	DDet = getRealValueFromHeader(filestr,55)
	
	return(DDet)
End

//Utility function that returns the detector deadtime (in seconds)
//Global values are set in the Initialize procedure
//
// - called by WorkFileUtils.ipf
//
// fileStr is passed as TextRead[3] and is the filename
// detStr is passed as TextRead[9] and is an identifier for the detector
//
// [dateAndTimeStr] is optional, and could be used as a switch for 
// different historical detector configurations
Function DetectorDeadtime(fileStr,detStr,[dateAndTimeStr])
	String fileStr,detStr,dateAndTimeStr
	
	Variable deadtime
	
	// your code here
	deadtime = (2e-6)

	return(deadtime)
End


// item is a filename
//
// this function extracts some sort of number from the file
// presumably some sort of automatically incrementing run number set by the
// acquisition system
//
// this run number should be a unique identifier for the file
//

//
Function GetRunNumFromFile(item)
	String item

	Variable num=-1		// an invalid return value
	
	String runStr=""
	
	runStr = ParseFilePath(0, item, ":", 1, 0)
//	runstr = item
	num = str2num(runstr)
	
	
	//your code here
	
	return (num)
End

// item is a filename
//
// this function extracts some sort of number from the file
// presumably some sort of automatically incrementing run number set by the
// acquisition system
//
// this run number should be a unique identifier for the file
//
// same as GetRunNumFromFile(0), just with a string return
//
// "ABC" returned as an invalid result
Function/S GetRunNumStrFromFile(item)
	String item
	
	String invalid = "ABC"	//"ABC" is not a valid run number, since it's text
	String retStr
	retStr=invalid
	
	retstr = ParseFilePath(0, item, ":", 1, 0)
	//your code here
	

	
	return(retStr)
End

//returns a string containing the full path to the file containing the 
//run number "num". The null string is returned if no valid file can be found.
//
//
// search in the path "catPathName" (hard-wired), will abort if this path does not exist
//the file returned will be a RAW SANS data file, other types of files are 
//filtered out.
//
// called by Buttons.ipf and Transmission.ipf, and locally by parsing routines
//
Function/S FindFileFromRunNumber(num)
	Variable num
	
	String fullName="",partialName="",item=""
	String numStr=""
	
	numStr = num2str(num)
	// pad to 6 characters
	switch(strlen(numstr))	// numeric switch
		case 6:		// execute if case matches expression
			break						// exit from switch
		case 5:
			numStr = "0"+numStr
			break
		case 4:
			numStr = "00"+numStr
			break
		case 3:
			numStr = "000"+numStr
			break
		case 2:
			numStr = "0000"+numStr
			break
		case 1:
			numStr = "00000"+numStr
			break												
		default:							// optional default expression executed
	endswitch
	
//	Print "numstr = ",numstr
	
	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String list="",newList="",testStr=""
	
	
	
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	//find (the) one with the number in the run # location in the name
	Variable numItems,ii,runFound,isRAW
	numItems = ItemsInList(list,";")		//get the new number of items in the list
	ii=0
	
	do
		//parse through the list in this order:
		// 1 - does item contain run number (as a string) "TTTTTnnn.SAn_XXX_Tyyy"
		// 2 - exclude by isRaw? (to minimize disk access)
		item = StringFromList(ii, list  ,";" )
		if(strlen(item) != 0)
			//find the run number, if it exists as a three character string
			testStr = GetRunNumStrFromFile(item)
			runFound = cmpstr(numStr,testStr)
			if(runFound == 0)
				partialName = FindValidFileName(item)
				if(strlen(partialName) != 0)		//non-null return from FindValidFileName()
					fullName = path + partialName
					//check if RAW, if so,this must be the file!
					isRAW = CheckIfRawData(fullName)
					if(isRaw)
						//stop here
						//print fullname
						return(fullname)
					Endif
				Endif
			Endif
		Endif
		ii+=1
	while(ii<numItems)		//process all items in list
	Return ("")	//null return if file not found in list
	
	//your code here
	
End
	
	
//make an (N) character string of the run number
//Moved to facility utils
//
// same scheme to get 6-character string as in GetRunNumStrFromFile(item)
//
Function/S RunDigitString(num)
	Variable num

//	String fullName="",partialName="",item=""
//	String numStr=""
//	
//	numStr = num2istr(num)
//	// pad to 6 characters
//	switch(strlen(numstr))	// numeric switch
//		case 6:		// execute if case matches expression
//			break						// exit from switch
//		case 5:
//			numStr = "0"+numStr
//			break
//		case 4:
//			numStr = "00"+numStr
//			break
//		case 3:
//			numStr = "000"+numStr
//			break
//		case 2:
//			numStr = "0000"+numStr
//			break
//		case 1:
//			numStr = "00000"+numStr
//			break												
//		default:							// optional default expression executed
//	endswitch
//	

	String numStr=""

	//make 6 digit string from run number
	sprintf numStr,"%06u",num
	
	//Print "numstr = ",numstr
	if(strlen(numstr) > 6)
		return("")
	else
		return(numstr)
	endif
	
End
	
	return(numstr)
End

// there is no prefix on D22 data files - they're just a run number
//
// so return null
//
// NCNR-specifc, does not really belong here - it's a beta procedure used for the
// Combine Files Panel, and I'm not sure of how I'm really going to get this to work properly
// since the .ABS file written is not of the form that NSORT->Set3NSORTFiles(low,med,hi,pref)
// is trying to construct
//
Function/S GetPrefixStrFromFile(item)
	String item
	return("")
End



//function to test a file to see if it is a RAW SANS file
//
// returns truth 0/1
//
// called by many procedures (both external and local)
//
Function CheckIfRawData(fname)
	String fname
	

Variable refnum,totalBytes
	String testStr=""
	
	Open/R/T="????" refNum as fname
	//get the total number of bytes in the file
	FStatus refNum
	totalBytes = V_logEOF
//	Print totalBytes
	FSetPos refNum,75
	FReadLine/N=3 refNum,testStr
//	print teststr
	Close refNum
	
	if(totalBytes == 142317 && cmpstr(testStr,"RRR")==0)
		//true, is raw data file
		
//		print "yes"
		Return(1)
		
		
	else
		//some other file
		
//		print "no"
		Return(0)
	Endif




//	if()
//		//true, is raw data file
//		Return(1)
//	else
//		//some other file
//		Return(0)
//	Endif

End

//function to test a file to see if it is a DIV file
//
// returns truth 0/1
//
// called by many procedures (both external and local)
//
Function CheckIfDIVData(fname)
	String fname
	

//	if(your test here)
//		//true, is DIV file data file
		Return(1)
//	else
//		//some other file
//		Return(0)
//	Endif

End

// function returns 1 if file is a transmission file, 0 if not
//
// called by Transmission.ipf, CatVSTable.ipf, NSORT.ipf
//
Function isTransFile(fName)
	String fname
	
	variable ypos
	NVAR yTol = root:myGlobals:BeamstopYTol
	
	ypos = getRealValueFromHeader(fname,15)
	
//	print ypos

//  print ytol
	
	if(abs(ypos)>=ytol)
//		//yes, its a transmisison file

//print "yes"
		Return(1)
	else
//		//some other file

//print "no"
		Return(0)
	Endif
End


//function to remove all spaces from names when searching for filenames
//the filename (as saved) will never have interior spaces (TTTTTnnn_AB _Bnnn)
//but the text field in the header may
//
//returns a string identical to the original string, except with the interior spaces removed
//
// local function for file name manipulation
//
// no change needed here
Function/S RemoveAllSpaces(str)
	String str
	
	String tempstr = str
	Variable ii,spc,len		//should never be more than 2 or 3 trailing spaces in a filename
	ii=0
	do
		len = strlen(tempStr)
		spc = strsearch(tempStr," ",0)		//is the last character a space?
		if (spc == -1)
			break		//no more spaces found, get out
		endif
		str = tempstr
		tempStr = str[0,(spc-1)] + str[(spc+1),(len-1)]	//remove the space from the string
	While(1)	//should never be more than 2 or 3
	
	If(strlen(tempStr) < 1)
		tempStr = ""		//be sure to return a null string if problem found
	Endif
	
	//Print strlen(tempstr)
	
	Return(tempStr)
		
End


//Function attempts to find valid filename from partial name by checking for
// the existence of the file on disk
//
// returns a valid filename (No path prepended) or a null string
//
// called by any functions, both external and local
//
Function/S FindValidFilename(partialName)
	String PartialName
	
	String retStr=""
	
	//your code here
	
	
	
	//try name with no changes - to allow for ABS files that have spaces in the names 12APR04
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//if the partial name is derived from the file header, there can be spaces at the beginning
	//or in the middle of the filename - depending on the prefix and initials used
	//
	//remove any leading spaces from the name before starting
	partialName = RemoveAllSpaces(partialName)
	
	//try name with no spaces
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all UPPERCASE
	partialName = UpperStr(partialName)
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all lowercase (ret null if failure)
	partialName = LowerStr(partialName)
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	else
		return(retStr)
	Endif
End

// Function checks for the existence of a file
// partialName;vers (to account for VAX filenaming conventions)
// The partial name is tried first with no version number
//
// *** the PATH is hard-wired to catPathName (which is assumed to exist)
// version numers up to ;10 are tried
// only the "name;vers" is returned if successful. The path is not prepended
//
// local function
//



Function/S ValidFileString(partialName)
	String partialName
	
	String tempName = "",msg=""
	Variable ii,refnum
	
	ii=0
	do
		if(ii==0)
			//first pass, try the partialName
			tempName = partialName
			Open/Z/R/T="????TEXT"/P=catPathName refnum tempName	//Does open file (/Z flag)
			if(V_flag == 0)
				//file exists
				Close refnum		//YES needed, 
				break
			endif
		else
			tempName = partialName + ";" + num2str(ii)
			Open/Z/R/T="????TEXT"/P=catPathName refnum tempName
			if(V_flag == 0)
				//file exists
				Close refnum
				break
			endif
		Endif
		ii+=1
		//print "ii=",ii
	while(ii<11)
	//go get the selected bits of information, using tempName, which exists
	if(ii>=11)
		//msg = partialName + " not found. is version number > 11?"
		//DoAlert 0, msg
		//PathInfo catPathName
		//Print S_Path
		Return ("")		//use null string as error condition
	Endif
	
	Return (tempName)
End




//returns a string containing filename (WITHOUT the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// called by MaskUtils.ipf, ProtocolAsPanel.ipf, WriteQIS.ipf
//
// NEEDS NO CHANGES
//
Function/S GetFileNameFromPathNoSemi(fullPath)
	String fullPath
	
	Variable offset1,offset2
	String filename=""
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			fileName = FullPath[offset1,strlen(FullPath) ]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	//remove version number from name, if it's there - format should be: filename;N
	filename =  StringFromList(0,filename,";")		//returns null if error
	
	Return filename
End

//returns a string containing filename (INCLUDING the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// local, currently unused
//
// NEEDS NO CHANGES
//
Function/S GetFileNameFromPathKeepSemi(fullPath)
	String fullPath
	
	Variable offset1,offset2
	String filename
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			fileName = FullPath[offset1,strlen(FullPath) ]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	//keep version number from name, if it's there - format should be: filename;N
	
	Return filename
End

//given the full path and filename (fullPath), strips the data path
//(Mac-style, separated by colons) and returns this path
//this partial path is the same string that would be returned from PathInfo, for example
//
// - allows the user to save to a different path than catPathName
//
// called by WriteQIS.ipf
//
// NEEDS NO CHANGES
//
Function/S GetPathStrFromfullName(fullPath)
	String fullPath
	
	Variable offset1,offset2
	//String filename
	String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			//fileName = FullPath[offset1,strlen(FullPath) ]
			PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	Return PartialPath
End

//given the filename trim or modify the filename to get a new
//file string that can be used for naming averaged 1-d files
//
// called by ProtocolAsPanel.ipf and Tile_2D.ipf
//
Function/S GetNameFromHeader(fullName)
	String fullName
	String  temp,newName = ""
	
	Variable spc,ii=0
	
	//filename is 20 characters NNNNNxxx.SAn_NNN_NNN
	//want the first 8 characters, NNNNNxxx, then strip off any spaces at the beginning
	//NNNNN was entered as less than 5 characters
	//returns a null string if no name can be found
	do
		temp = fullname[ii,7]		//characters ii,7 of the name
		spc = strsearch(temp," ",0)
		if (spc == -1)
			break		//no more spaces found
		endif
		ii+=1
	While(ii<8)
	
	If(strlen(temp) < 1)
		newName = ""		//be sure to return a null string if problem found
	else
		newName = temp
	Endif
	
//      print newname
	//your code here
	
	Return(newName)
End

//list (input) is a list, typically returned from IndexedFile()
//which is semicolon-delimited, and may contain filenames from the VAX
//that contain version numbers, where the version number appears as a separate list item
//(and also as a non-existent file)
//these numbers must be purged from the list, especially for display in a popup
//or list processing of filenames
//the function returns the list, cleaned of version numbers (up to 11)
//raw data files will typically never have a version number other than 1.
//
// if there are no version numbers in the list, the input list is returned
//
// called by CatVSTable.ipf, NSORT.ipf, Transmission.ipf, WorkFileUtils.ipf 
//
//
// NO CHANGE NEEDED
//
Function/S RemoveVersNumsFromList(list)
	String list
	
	//get rid of version numbers first (up to 11)
	Variable ii,num
	String item 
	num = ItemsInList(list,";")
	ii=1
	do
		item = num2str(ii)
		list = RemoveFromList(item, list ,";" )
		ii+=1
	while(ii<12)
	
	return (list)
End

//input is a list of run numbers, and output is a list of filenames (not the full path)
//*** input list must be COMMA delimited***
//output is equivalent to selecting from the CAT table
//if some or all of the list items are valid filenames, keep them...
//if an error is encountered, notify of the offending element and return a null list
//
//output is COMMA delimited
//
// this routine is expecting that the "ask", "none" special cases are handled elsewhere
//and not passed here
//
// called by Marquee.ipf, MultipleReduce.ipf, ProtocolAsPanel.ipf
//
// NO CHANGE NEEDED
//
Function/S ParseRunNumberList(list)
	String list
	
	String newList="",item="",tempStr=""
	Variable num,ii,runNum
	
	//expand number ranges, if any
	list = ExpandNumRanges(list)
	
	num=itemsinlist(list,",")
	
	for(ii=0;ii<num;ii+=1)
		//get the item
		item = StringFromList(ii,list,",")
		//is it already a valid filename?
		tempStr=FindValidFilename(item) //returns filename if good, null if error
		if(strlen(tempstr)!=0)
			//valid name, add to list
			//Print "it's a file"
			newList += tempStr + ","
		else
			//not a valid name
			//is it a number?
			runNum=str2num(item)
			//print runnum
			if(numtype(runNum) != 0)
				//not a number -  maybe an error			
				DoAlert 0,"List item "+item+" is not a valid run number or filename. Please enter a valid number or filename."
				return("")
			else
				//a run number or an error
				tempStr = GetFileNameFromPathNoSemi( FindFileFromRunNumber(runNum) )
				if(strlen(tempstr)==0)
					//file not found, error
					DoAlert 0,"List item "+item+" is not a valid run number. Please enter a valid number."
					return("")
				else
					newList += tempStr + ","
				endif
			endif
		endif
	endfor		//loop over all items in list
	
	return(newList)
End

//takes a comma delimited list that MAY contain number range, and
//expands any range of run numbers into a comma-delimited list...
//and returns the new list - if not a range, return unchanged
//
// local function
//
// NO CHANGE NEEDED
//
Function/S ExpandNumRanges(list)
	String list
	
	String newList="",dash="-",item,str
	Variable num,ii,hasDash
	
	num=itemsinlist(list,",")
//	print num
	for(ii=0;ii<num;ii+=1)
		//get the item
		item = StringFromList(ii,list,",")
		//does it contain a dash?
		hasDash = strsearch(item,dash,0)		//-1 if no dash found
		if(hasDash == -1)
			//not a range, keep it in the list
			newList += item + ","
		else
			//has a dash (so it's a range), expand (or add null)
			newList += ListFromDash(item)		
		endif
	endfor
	
	return newList
End

//be sure to add a trailing comma to the return string...
//
// local function
//
// NO CHANGE NEEDED
//
Function/S ListFromDash(item)
	String item
	
	String numList="",loStr="",hiStr=""
	Variable lo,hi,ii
	
	loStr=StringFromList(0,item,"-")	//treat the range as a list
	hiStr=StringFromList(1,item,"-")
	lo=str2num(loStr)
	hi=str2num(hiStr)
	if( (numtype(lo) != 0) || (numtype(hi) !=0 ) || (lo > hi) )
		numList=""
		return numList
	endif
	for(ii=lo;ii<=hi;ii+=1)
		numList += num2str(ii) + ","
	endfor
	
	Return numList
End


//returns the proper attenuation factor based on the instrument
//
// filestr is passed from TextRead[3] = the default directory, used to identify the instrument
// lam is passed from RealsRead[26]
// AttenNo is passed from ReaslRead[3]
//
// Attenuation factor as defined here is <= 1
//
// Facilities can pass ("",1,attenuationFactor) and have this function simply
// spit back the attenuationFactor (that was read into rw[3])
//
// called by Correct.ipf, ProtocolAsPanel.ipf, Transmission.ipf
//
// atten_err is one std. deviation, passed back by reference
Function AttenuationFactor(fileStr,lam,attenNo,atten_err)
	String fileStr
	Variable lam,attenNo,&atten_err
	
	Variable attenFactor
	make/O/N=4 Attenuators_ILL={1,147,902,2874}
	
	attenFactor = Attenuators_ILL[attenNo]

	// Change April 2011 - now returns error in atten trans
	atten_err = 0
		
//	print attenfactor
	
	// your code here

	return(1/attenFactor)
End

//function called by the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// could also use the alternate procedure of keeping only file with the proper extension
//
// another possibility is to get a listing of the text files, but is unreliable on 
// Windows, where the data file must be .txt (and possibly OSX)
//
// called by FIT_Ops.ipf, NSORT.ipf, PlotUtils.ipf
//
// modify for specific facilities by changing the "*.SA1*","*.SA2*","*.SA3*" stringmatch
// items which are specific to NCNR
//
Function/S ReducedDataFileList(ctrlName)
	String ctrlName

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		Return("")
	Endif
	
	list = IndexedFile(catpathName,-1,"????")
	num=ItemsInList(list,";")
	//print "num = ",num
	for(ii=(num-1);ii>=0;ii-=1)
		item = StringFromList(ii, list  ,";")
		//simply remove all that are not raw data files (SA1 SA2 SA3)
		if( !stringmatch(item,"*.SA1*") && !stringmatch(item,"*.SA2*") && !stringmatch(item,"*.SA3*") )
			if( !stringmatch(item,".*") && !stringmatch(item,"*.pxp") && !stringmatch(item,"*.DIV"))		//eliminate mac "hidden" files, pxp, and div files
				newlist += item + ";"
			endif
		endif
	endfor
	//remove VAX version numbers
	newList = RemoveVersNumsFromList(newList)
	//sort
	newList = SortList(newList,";",0)

	return newlist
End

// returns a list of raw data files in the catPathName directory on disk
// - list is SEMICOLON-delimited
//
// called by PatchFiles.ipf, Tile_2D.ipf
//
Function/S GetRawDataFileList()
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	Endif
	
	String list=IndexedFile(catPathName,-1,"????")
	
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii
	
	
	for(ii=0;ii<num;ii+=1)
	item = StringFromList(ii, list  ,";")
//	if( stringmatch(item,"*") )
	//		newlist += item + ";"
//	endif
	if( stringmatch(item,"!*.*") )
			newlist	+= item + ";"
			
		
	endif
	
	
	endfor
	
	// your code here
	newList = SortList(newList,";",0)
	
//	print newlist
	
	return(newlist)
End

//**********************
// 2D resolution function calculation - in terms of X and Y
//
// based on notes from David Mildner, 2008
//
// the final NCNR version is located in NCNR_Utils.ipf
//
Function/S get2DResolution(inQ,phi,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,r_dist,SigmaQX,SigmaQY,fSubS)
	Variable inQ, phi,lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses,r_dist
	Variable &SigmaQX,&SigmaQY,&fSubS		//these are the output quantities at the input Q value
	
	return("Function Empty")
End

// a tube-by-tube correction that replaces our area detecor correction
Function DetEffCorrILL(lambda,dtdist,xd)  
	Variable lambda,dtdist,xd
	Variable ff=1,theta
 
	theta =360* atan( xd/dtdist )/(2*Pi)
 
	if (lambda <=5.1 && lambda>=4.9)
		ff= 1.000087- 7.094023e-5*abs(theta) + 8.622997e-5*abs(theta^2) + 9.262026e-6*abs(theta^3) -3.216369e-7*abs(theta^4) +2.142398e-9*abs(theta^5)
	elseif  (lambda <=8.1 && lambda>=7.9)
		ff= 0.9993575- 0.0002320264*abs(theta) + 9.751713e-5*abs(theta^2) + 1.018564e-5*abs(theta^3) -3.977445e-7*abs(theta^4) +2.960205e-9*abs(theta^5)
	endif
	ff= 0.9992674-0.0001808763*abs(theta) +8.134414e-05*abs(theta^2) +1.151734e-05*abs(theta^3) - 4.401022e-07*abs(theta^4)+3.71246e-09*abs(theta^5)

	return(ff)
End


// Return the filename that represents the previous or next file.
// Input is current filename and increment. 
// Increment should be -1 or 1
// -1 => previous file
// 1 => next file
Function/S GetPrevNextRawFile(curfilename, prevnext)
	String curfilename
	Variable prevnext

	String filename
	
	//get the run number
	Variable num = GetRunNumFromFile(curfilename)
		
	//find the next specified file by number
	fileName = FindFileFromRunNumber(num+prevnext)

	if(cmpstr(fileName,"")==0)
		//null return, do nothing
		fileName = FindFileFromRunNumber(num)
	Endif

//	print "in FU "+filename

	Return filename
End