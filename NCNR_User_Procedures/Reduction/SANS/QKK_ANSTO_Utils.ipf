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
	Variable/G root:myGlobals:gNPixelsX=192					// number of X and Y pixels
	Variable/G root:myGlobals:gNPixelsY=192
	
	// pixel dimensions are now read directly from the file header.
//	Variable/G root:myGlobals:PixelResDefault = 0.5			//pixel resolution in cm
	
	Variable/G root:myGlobals:DeadtimeDefault = 2.14e-6 // 3.4e-6		//deadtime in seconds ???nha

	Variable/G root:myGlobals:apOff = 5.0		// (cm) distance from sample aperture to sample position

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
Function DetectorDeadtime(fileStr,detStr)
	String fileStr,detStr
	
	// [davidm]
	nvar DeadtimeDefault = root:myGlobals:DeadtimeDefault

	return DeadtimeDefault
	
End

//given a filename of a SANS data filename of the form
//QKKNNNNNNN.nx.hdf
//returns the prefix 
Function/S GetPrefixStrFromFile(item)
	String item
	String invalid = ""	//"" is not a valid run prefix, since it's text
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, skip the three characters preceeding it
		if (pos <=7)
			//not enough characters
			return (invalid)
		else
			runStr = item[0,pos-8]
			return (runStr)
		Endif
	Endif
End

Function/S RunDigitString(num)
	Variable num
	
	String numStr=""

	//make 7 digit string from run number
	sprintf numStr,"%07u",num
	
	//Print "numstr = ",numstr
	return(numstr)
End

// item is a filename
//
// this function extracts some sort of number from the file
// presumably some sort of automatically incrementing run number set by the
// acquisition system
//
// this run number should be a unique identifier for the file
//
Function GetRunNumFromFile(item)
	String item

	Variable invalid = -1
	Variable num=-1		// an invalid return value
	
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get the three characters preceeding it
		if (pos <=6)
			//not enough characters
			return (invalid)
		else
			runStr = item[pos-7,pos-1]
			//convert to a number
			num = str2num(runStr)
			//if valid, return it
			//if (num == NaN) // will always be false [davidm]
			if(numtype(num) == 2)
				//3 characters were not a number
				return (invalid)
			else
				//run was OK
				return (num)
			Endif
		Endif
	Endif	
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
	
	String runStr = ""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get the three characters preceeding it
		if (pos <=6)
			//not enough characters
			return (invalid)
		else
			runStr = item[pos-7,pos-1]
			return (runStr)
		Endif
	Endif
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
	
	String fullName="",partialName="",item="",numStr=""
	
	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif

	//make 7 digit string from run number
	sprintf numStr,"%07u",num

	//partialname = "QKK"+tmp_num+".nx.hdf"

	String list="",newList="",testStr=""

	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	//find (the) one with the number in the run # location in the name
	Variable numItems,ii,runFound,isRAW
	numItems = ItemsInList(list,";")		//get the new number of items in the list
	ii=0
	do
		//parse through the list in this order:
		// 1 - does item contain run number (as a string) "QKKXXXXXXX.nx.hdf"
		// 2 - exclude by isRaw? (to minimize disk access)
		item = StringFromList(ii, list  ,";" )
		if(strlen(item) != 0)
			//find the run number, if it exists as a three character string
			testStr = GetRunNumStrFromFile(item)
			runFound= cmpstr(numStr,testStr)	//compare the three character strings, 0 if equal
			if(runFound == 0)
				//the run Number was found
				//build valid filename
				partialName = FindValidFileName(item)
				if(strlen(partialName) != 0)		//non-null return from FindValidFileName()
					fullName = path + partialName
					//check if RAW, if so,this must be the file!
					isRAW = CheckIfRawData(fullName)
					if(isRaw)
						//stop here
						return(fullname)
					Endif
				Endif
			Endif
		Endif
		ii+=1
	while(ii<numItems)		//process all items in list
	Return ("")	//null return if file not found in list
End

//function to test a file to see if it is a RAW SANS file
//
// returns truth 0/1
//
// called by many procedures (both external and local)
//
Function CheckIfRawData(fname)
	String fname
	Variable value = 0
	
	Variable hdfID,hdfgID
	Variable isNXHDF = 0
	
	//nha. look for non-NeXus files 
	if (strsearch(fname, "nx.hdf", 0) >= 0)
		isNXHDF = 1
	endif

	if(isNXHDF == 1)
		//Need to actually determine if file is RAW data.
		HDF5OpenFile/Z hdfID as fname
		HDF5OpenGroup/Z hdfID, "/data", hdfgID
		if (V_Flag == 0)
			//DIV file (with nx.hdf suffix)
			value = 0
		else
			//Some other nx.hdf file
			value = 1
		endif
		HDF5CloseGroup/Z hdfgID
		HDF5CloseFile/Z hdfID
	else
		value = 0
	endif
	
	return(value)
End

Function CheckIfFileExists(fname)
	String fname
	
	GetFileFolderInfo /Z/Q fname

	return V_Flag == 0

End

Function isScatFile(fname)
	String fname
	Variable isTrans, isEmp
	Variable value =1
	
	isTrans = isTransFile(fname)
	isEmp = isEmpFile(fname)
	
	if(isTrans)
		value = 0
	endif
	if(isEmp)
		value = 0
	endif 
	return(value)
End

Function isEmpFile(fName)
	String fname

	variable err
	string dfName = ""
	variable value = 0
	
	err = hdfRead(fname, dfName)
	//err not handled here

	Wave/T wSampleName = $(dfName+":sample:name") 
	String sampleName = wSampleName[0]
	
	if (cmpstr(sampleName,"MT beam")==0)
		value = 1
	endif 
	
	return(value)
End


// function returns 1 if file is a transmission file, 0 if not
//
// called by Transmission.ipf, CatVSTable.ipf, NSORT.ipf
//
Function isTransFile(fName)
	String fname

// nha. TO DO. entry1 will have to change when the new naming convention for nxentry is implemented. 

	variable err
	string dfName = ""
	variable value = 0

	// [davidm]
	hdfReadSimulated(fname, dfName)
	if (exists(dfName+":sample:TransmissionFlag") != 1)
		err = hdfRead(fname, dfName)
		//err not handled here
	endif

	Wave wTransmission_Flag = $(dfName+":sample:TransmissionFlag") //is only being set after 27/5/2009. ???
	
	if (WaveExists(wTransmission_Flag))
		value = wTransmission_Flag[0]
	else
		print "Can't find Transmission Flag in " + fname
	endif
//	
//   AJJ June 2nd 2010 - Unclear that this check is correct. Certainly BSPosXmm is not correct parameter in current data format...
//	if (value == 0)
//	//workaround - determine by bsx position
//	Wave wBSX = $(dfName+":instrument:beam_stop:geometry:position:BSPosXmm")
//	variable bsx = wBSX[0]
//		
//		if (bsx >= -10 )
//			value = 1
//		endif
//	endif

	return(value)
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

	// [davidm] if partialName only contains a number, then the filename is generated
	variable num = str2num(partialName)
	Variable i, err = numtype(num) != 0
	
	if (!err)
		for (i = 0; i != strlen(partialName); i = i + 1)
			if (numtype(str2num(partialName[i])) != 0)
				err = 1
				break
			endif
		endfor
	endif
	
	if (!err)
		PartialName = "QKK" + RunDigitString(num) + ".nx.hdf"
	endif
	
	return PartialName		
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
// given the fully qualified path and filename ie. fullName, return just the filename
	String fullName
	String newName = ""

	//your code here
	newName = ParseFilePath(0, fullName, ":", 1, 0)

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

		tempStr=FindValidFilename(item) //returns filename if good, null if error
		
		if(strlen(tempstr)!=0)
			//valid name, add to list
			//Print "it's a file"
				if(strlen(newList)==0)
					newList = tempStr
				else
					newList += "," + tempStr
				endif		
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
Function AttenuationFactor(fileStr,lam,attenNo)
	
	//
	String fileStr //
	Variable lam,attenNo
	
	Variable attenFactor=1

	// your code here	
	attenFactor = LookupAtten(lam,attenNo)

	return(attenFactor)
End

Function LookupAtten(lambda,attenNo)
	Variable lambda, attenNo
	
	Variable trans
	String attStr="root:myGlobals:Attenuators:att"+num2str(trunc(attenNo))
	String lamStr = "root:myGlobals:Attenuators:lambda"
	
	if(attenNo == 0)
		return (1)		//no attenuation, return trans == 1
	endif
	
//	if( (lambda < 5) || (lambda > 5 ) )
//		Abort "Wavelength out of calibration range (5A). You must manually enter the absolute parameters"
//	Endif
	
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Execute "MakeAttenTable()"
	Endif
	//just in case creating the tables fails....
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Abort "Attenuator lookup waves could not be found. You must manually enter the absolute parameters"
	Endif
	
	//lookup the value by interpolating the wavelength
	//the attenuator must always be an integer
	

	Wave att = $attStr
	Wave lam = $lamstr
	//nha - commented below out until we have attenuation factors over multiple lambda values
	//trans = interp(lambda,lam,att)
	
//	Print "trans = ",trans
	//nha - delete this line when multiple lambda values
	trans = att
	
	return trans
End

Proc MakeAttenTable()

	NewDataFolder/O root:myGlobals:Attenuators
	//do explicitly to avoid data folder problems, redundant, but it must work without fail

	//Quokka specific nha.
	Variable num=12		
	
	Make/O/N=(num) root:myGlobals:Attenuators:att0
	Make/O/N=(num) root:myGlobals:Attenuators:att1
	Make/O/N=(num) root:myGlobals:Attenuators:att2
	Make/O/N=(num) root:myGlobals:Attenuators:att3
	Make/O/N=(num) root:myGlobals:Attenuators:att4
	Make/O/N=(num) root:myGlobals:Attenuators:att5
	Make/O/N=(num) root:myGlobals:Attenuators:att6
	Make/O/N=(num) root:myGlobals:Attenuators:att7
	Make/O/N=(num) root:myGlobals:Attenuators:att8
	Make/O/N=(num) root:myGlobals:Attenuators:att9
	Make/O/N=(num) root:myGlobals:Attenuators:att10
	Make/O/N=(num) root:myGlobals:Attenuators:att11
	
	// epg
	// note 5A only at this stage but other wavelengths as measured
	// these values have to be re-determined as were measured on time and not monitor counts
	//Make/O/N=(num) root:myGlobals:Attenuators:lambda={5}
	Make/O/N=(num) root:myGlobals:Attenuators:lambda={4.94}	

	//Quokka attenuator factors. 19/1/09 nha
	//20/3/09 nha updated to 
	//file://fianna/Sections/Bragg/Data_Analysis_Team/Project/P025 Quokka Commissioning DRV/3_Development/ATTest-timeseries.pdf 
	//updated by epg 13-02-2010 to reflect kwo measurements at g7
	
//	root:myGlobals:Attenuators:att0 = {1}
//	root:myGlobals:Attenuators:att1 = {0.498782}
//	root:myGlobals:Attenuators:att2 = {0.176433}
//	root:myGlobals:Attenuators:att3 = {0.0761367}
//	root:myGlobals:Attenuators:att4 = {0.0353985}
//	root:myGlobals:Attenuators:att5 = {0.0137137}
//	root:myGlobals:Attenuators:att6 = {0.00614167}
//	root:myGlobals:Attenuators:att7 = {0.00264554}
//	root:myGlobals:Attenuators:att8 = {0.000994504}
//	root:myGlobals:Attenuators:att9 = {0.000358897}
//	root:myGlobals:Attenuators:att10 = {7.2845e-05}
//	root:myGlobals:Attenuators:att11 = {1.67827e-06}
	
	// [davidm] 19/12/2011 new attenuators
 	root:myGlobals:Attenuators:att0 = {1}
	root:myGlobals:Attenuators:att1 = {0.493851474862975}
	root:myGlobals:Attenuators:att2 = {0.172954232066555}
	root:myGlobals:Attenuators:att3 = {0.0730333204657658}
	root:myGlobals:Attenuators:att4 = {0.0338860321760628}
	root:myGlobals:Attenuators:att5 = {0.0123806637881081}
	root:myGlobals:Attenuators:att6 = {0.00547518298963546}
	root:myGlobals:Attenuators:att7 = {0.00243389583698184}
	root:myGlobals:Attenuators:att8 = {0.000833797438995085}
	root:myGlobals:Attenuators:att9 = {0.000314495412044638}
	root:myGlobals:Attenuators:att10 = {6.18092704241135e-05}
	root:myGlobals:Attenuators:att11 = {1.1150347032482e-06}

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
	
	//nha. Reads Quokka file names 5/2/09
	
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
		if( stringmatch(item,"*.nx.hdf") )
			newlist += item + ";"
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)
	return(newList)
	
	// your code here
	
	return(list)
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

//convert a comma delimited runNumberList 
//e.g. 1234567,2345678
// to a comma delimited filename list
// e.g. QKK1234567.nx.hdf,QKK2345678.nx.hdf
Function/S RunNumberListToFilenameList(runNumberList)
	String runNumberList
	String filenameList, fileStr, numStr
	String item
	variable num,ii,runNumber
	
	filenameList = ""
	
	num = ItemsInList(runNumberList,",")
	ii=0
       do
		item = StringFromList(ii, runNumberList, ",")
		runNumber = str2num(item) 
                                    
		 if (numtype(runNumber) != 0) // error
			fileStr = item
		else
			//make 7 digit string from run number
			sprintf numStr ,"%07u", runNumber
			fileStr = "QKK" +  numStr + ".nx.hdf"
		endif

		//build FilenameList
		filenameList = filenameList + fileStr
		ii += 1
		if (ii<num)
			filenameList = filenameList + ","
		endif
	while(ii<num)

	return filenameList
End

// [davidm] create CAT Sort-Dialog
function BuildCatSortDialog()

	// check if CatVSTable exists
	DoWindow CatVSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return 0
	endif
	
	// bring CatSortDialog to front
	DoWindow/F CatSortDialog
	if (V_flag != 0)
		return 0
	endif
	
	print "Creating CAT Sort-Dialog..."
		
	//PauseUpdate
	NewPanel /W=(600,360,790,730)/K=1 as "CAT - Sort Dialog"
	DoWindow/C CatSortDialog
	ModifyPanel fixedSize=1, cbRGB = (42919, 53970, 60909)
	
	Button SortFilenamesButton,		pos={25, 8},		size={140,24},proc=CatVSTable_SortProc,title="Filenames"
	Button SortLabelsButton,			pos={25,38},		size={140,24},proc=CatVSTable_SortProc,title="Labels"
	Button SortDateAndTimeButton,	pos={25,68},		size={140,24},proc=CatVSTable_SortProc,title="Date and Time"
	Button SortSSDButton,			pos={25,98},		size={140,24},proc=CatVSTable_SortProc,title="SSD"
	Button SortSDDButton,			pos={25,128},	size={140,24},proc=CatVSTable_SortProc,title="SDD"
	Button SortLambdaButton,			pos={25,158},	size={140,24},proc=CatVSTable_SortProc,title="Lambda"
	Button SortCountTimButton,		pos={25,188},	size={140,24},proc=CatVSTable_SortProc,title="Count Time"
	Button SortTotalCountsButton,		pos={25,218},	size={140,24},proc=CatVSTable_SortProc,title="Total Counts"
	Button SortCountRateButton,		pos={25,248},	size={140,24},proc=CatVSTable_SortProc,title="Count Rate"
	Button SortMonitorCountsButton,	pos={25,278},	size={140,24},proc=CatVSTable_SortProc,title="Monitor Counts"
	Button SortTransmissionButton,	pos={25,308},	size={140,24},proc=CatVSTable_SortProc,title="Transmission"
	Button SortThicknessButton,		pos={25,338},	size={140,24},proc=CatVSTable_SortProc,title="Thickness"

end

proc CatVSTable_SortProc(ctrlName) : ButtonControl // added by [davidm]
	String ctrlName
	
	// check if CatVSTable exists
	DoWindow CatVSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return
	endif
		
	// have to use function
	CatVSTable_SortFunction(ctrlName)
	
end

function CatVSTable_SortFunction(ctrlName) // added by [davidm]
	String ctrlName

	Wave/T GFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:myGlobals:CatVSHeaderInfo:DateAndTime"
	Wave GSDD = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave GLambda = $"root:myGlobals:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:myGlobals:CatVSHeaderInfo:CntTime"
	Wave GTotCnts = $"root:myGlobals:CatVSHeaderInfo:TotCnts"
	Wave GCntRate = $"root:myGlobals:CatVSHeaderInfo:CntRate"
	Wave GMonCnts = $"root:myGlobals:CatVSHeaderInfo:MonCnts"
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
	Wave GPos = $"root:myGlobals:CatVSHeaderInfo:Pos"
	Wave/Z GReactPow = $"root:myGlobals:CatVSHeaderInfo:ReactorPower"
	//For ANSTO
	Wave GSSD = $"root:myGlobals:CatVSHeaderInfo:SSD"
	Wave/T GSICS = $"root:myGlobals:CatVSHeaderInfo:SICS"
	Wave/T GHDF = $"root:myGlobals:CatVSHeaderInfo:HDF"
	
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
			Sort GFilenames, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortLabelsButton":
			Sort GLabels, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortDateAndTimeButton":
			Sort GDateTime, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortSSDButton":
			Sort GSSD, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortSDDButton":
			Sort GSDD, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortLambdaButton":
			Sort GLambda, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortCountTimButton":
			Sort GCntTime, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortTotalCountsButton":
			Sort GTotCnts, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortCountRateButton":
			Sort GCntRate, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortMonitorCountsButton":
			Sort GMonCnts, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortTransmissionButton":
			Sort GTransmission, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
			
		case "SortThicknessButton":
			Sort GThickness, GSuffix, GFilenames, GLabels, GDateTime, GSSD, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GMonCnts, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR, GSICS, GHDF
			break
	
	endswitch
	
	// insert the "not-RAW-Files" again
	if (notRAWcount > 0)
		InsertPoints rawCount, notRAWcount, GFilenames
		GFilenames[rawCount, fileCount-1] = notRAWlist[p-rawCount]
	endif
end