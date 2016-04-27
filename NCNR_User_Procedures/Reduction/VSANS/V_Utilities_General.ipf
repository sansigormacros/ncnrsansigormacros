#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
//		general utilities
//
// for use by multiple panels and packages


//prompts user to choose the local folder that contains the SANS Data
//only one folder can be used, and its path is catPathName (and is a NAME, not a string)
//this will overwrite the path selection
//returns 1 if no path selected as error condition, or if user cancelled
Function V_PickPath()
	
	//set the global string to the selected pathname
	NewPath/O/M="pick the SANS data folder" catPathName
	if(V_Flag != 0)
		return(1)		//user cancelled
	endif
	
	PathInfo/S catPathName
	String dum = S_path
	String alertStr = ""
	alertStr = "You must set the path to Charlotte through a Mapped Network Drive, not through the Network Neighborhood"
	//alertStr += "  Please see the manual for details."
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packges:NIST:VSANS:Globals:gCatPathStr = "no folder selected"
		return(1)
	else
		//set the global to the path (as a string)
		// need 4 \ since it is the escape character
		if(cmpstr("\\\\",dum[0,1])==0)	//Windows user going through network neighborhood
			DoAlert 0,alertStr
			KillPath catPathName
			return(1)
		endif
		String/G root:Packges:NIST:VSANS:Globals:gCatPathStr = dum
		return(0)		//no error
	endif
End

//
// entry from the Main Panel
//
Proc V_ChangeDisplay(type)
	String type
	Prompt type,"WORK data type to display",popup,"RAW;SAM;EMP;BGD;ADJ;"

// make sure that data exists before passing this on...
	
	if(DataExists(type) > 0)
		UpdateDisplayInformation(type)
	else
		DoAlert 0,"No data in "+type
	endif
End

// TODO
//
// very simple function to look for something in a work folder
// -- only checks for FR data to exist, assumes everything else is there
// -- can't use the V_get() functions, these will try to load data if it's not there!
Function DataExists(type)
	String type
	
	Wave/Z w = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_FR:data")
	
	return(WaveExists(w))
end
//
// tests if two values are close enough to each other
// very useful since ICE came to be
//
// tol is an absolute value (since input v1 or v2 may be zero, can't reliably
// use a percentage
Function CloseEnough(v1,v2,tol)
	Variable v1, v2, tol

	if(abs(v1-v2) < tol)
		return(1)
	else
		return(0)
	endif
End



// TODO:
// -- this must be called as needed to force a re-read of the data from disk
//    "as needed" means that when an operation is done that needs to ensure
//     a fresh read from disk, it must take care of the kill.
// -- the ksBaseDFPath needs to be removed. It's currently pointing to RawVSANS, which is
//    really not used as intended anymore.
//
Function V_KillNamedDataFolder(fname)
	String fname
	
	Variable err=0
	
	String folderStr = V_GetFileNameFromPathNoSemi(fname)
	folderStr = V_RemoveDotExtension(folderStr)
	
	KillDataFolder/Z $(ksBaseDFPath+folderStr)
	err = V_flag
	
	return(err)
end

//given a filename of a SANS data filename of the form
// name.anything
//returns the name as a string without the ".fbdfasga" extension
//
// returns the input string if a "." can't be found (maybe it wasn't there)
Function/S V_RemoveDotExtension(item)
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

//returns a string containing filename (WITHOUT the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// called by MaskUtils.ipf, ProtocolAsPanel.ipf, WriteQIS.ipf
//
Function/S V_GetFileNameFromPathNoSemi(fullPath)
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

//
// -- this was copied directly, no changes , from PlotUtils_Macro_v40
//
// returns the path to the file, or null if the user cancelled
// fancy use of optional parameters
// 
// enforce short file names (25 characters)
Function/S V_DoSaveFileDialog(msg,[fname,suffix])
	String msg,fname,suffix
	Variable refNum
//	String message = "Save the file as"

	if(ParamIsDefault(fname))
//		Print "fname not supplied"
		fname = ""
	endif
	if(ParamIsDefault(suffix))
//		Print "suffix not supplied"
		suffix = ""
	endif
	
	String outputPath,tmpName,testStr
	Variable badLength=0,maxLength=25,l1,l2
	
	
	tmpName = fname + suffix
	
	do
		badLength=0
		Open/D/M=msg/T="????" refNum as tmpName		//OS will allow 255 characters, but then I can't read it back in!
		outputPath = S_fileName
		
		testStr = ParseFilePath(0, outputPath, ":", 1, 0)		//just the filename
		if(strlen(testStr)==0)
			break		//cancel, allow exit
		endif
		if(strlen(testStr) > maxLength)
			badlength = 1
			DoAlert 2,"File name is too long. Is\r"+testStr[0,maxLength-1]+"\rOK?"
			if(V_flag==3)
				outputPath = ""
				break
			endif
			if(V_flag==1)			//my suggested name is OK, so trim the output
				badlength=0
				l1 = strlen(testStr)		//too long length
				l1 = l1-maxLength		//number to trim
				//Print outputPath
				l2=strlen(outputPath)
				outputPath = outputPath[0,l2-1-l1]
				//Print "modified  ",outputPath
			endif
			//if(V_flag==2)  do nothing, let it go around again
		endif
		
	while(badLength)
	
	return outputPath
End



//
// previous/next button needs these functions
// as well as many other utilities that manipulate the data file names
// and parse run numbers.
//


// TODO
// x- load in the proper file
// x- re-click the I(q) button
// x- be sure that the globals are updated w/ filename
// -- getting the file_name from the root: global is a poor choice. 
//     Need a better, more reliable solution than this
// -- make a copy of "oldName" that is local and not the SVAR, as the SVAR changes
//    when the next file is loaded in (if it's not in RawVSANS), resulting in a "skipped" file number
//
//displays next (or previous) file in series of run numbers
//file is read from disk, if path is set and the file number is present
//increment +1, adds 1 to run number, -1 subtracts one
//
// will automatically step a gap of 10 run numbers, but nothing larger. Don't want to loop too long
// trying to find a file (frustrating), don't want to look past the end of the run numbers (waste)
// -- may find a more elegant solution later.
//
Function V_LoadPlotAndDisplayRAW(increment)
	Variable increment

	Variable i,val
	String filename,tmp,curFileName
	//take the currently displayed RAW file 
	SVAR oldName = root:file_name
	oldname = V_RemoveAllSpaces(oldname)		// 
	curFileName = oldName
//	print oldName
	
	filename = oldname
//	for (i = 0; i < abs(increment); i += 1)
//		filename = GetPrevNextRawFile(filename,increment/abs(increment))
//	endfor	
	i = 1
	val = increment
	do
//		print filename,val
		filename = V_GetPrevNextRawFile(filename,val)
//		print "new= ",filename
		
		val = i*increment
		i+=1
		tmp = ParseFilePath(0, filename, ":", 1, 0)

//		print val,strlen(tmp),strlen(oldname)
//		print cmpstr(tmp,oldname)

		if(strlen(tmp) == 0)		//in some cases, a null string can be returned - handle gracefully
			return(0)
		endif
		
	while( (cmpstr(tmp,curFileName) == 0) && i < 11)
//	print filename
	
	// display the specified RAW data file
	// this is the set of steps done in DisplayMainButtonProc(ctrlName) : ButtonControl
	Variable err=	V_LoadHDF5Data(filename,"RAW")			// load the data, set the global w/file name loaded
//	Print "Load err = "+num2str(err)
	if(!err)
		SVAR hdfDF = root:file_name			// last file loaded, may not be the safest way to pass
		String folder = StringFromList(0,hdfDF,".")
		
		// this (in SANS) just passes directly to fRawWindowHook()
		Execute "UpdateDisplayInformation(\"RAW\")"	// plot the data in whatever folder type
		
		FakeRestorePanelsButtonClick()		//so the panels display correctly
		
	endif

	// TODO
	// -- update the 1D plotting as needed. these are SANS calls (OK for now, but will need to be better)
	//do the average and plot (either the default, or what is on the panel currently)
	V_PlotData_Panel()
	

	return(0)
End


// Return the full path:filename that represents the previous or next file.
// Input is current filename and increment. 
// Increment should be -1 or 1
// -1 => previous file
// 1 => next file
Function/S V_GetPrevNextRawFile(curfilename, prevnext)
	String curfilename
	Variable prevnext

	String filename
	
	//get the run number
	Variable num = V_GetRunNumFromFile(curfilename)
		
	//find the next specified file by number
	fileName = V_FindFileFromRunNumber(num+prevnext)

	if(cmpstr(fileName,"")==0)
		//null return, do nothing
		fileName = V_FindFileFromRunNumber(num)		//returns the full path, not just curFileName
	Endif

	Return filename
End


//returns a string containing the full path to the file containing the 
//run number "num". The null string is returned if no valid file can be found
//the path "catPathName" used and is hard-wired, will abort if this path does not exist
//the file returned will be a RAW SANS data file, other types of files are 
//filtered out.
//
// called by Buttons.ipf and Transmission.ipf, and locally by parsing routines
//
Function/S V_FindFileFromRunNumber(num)
	Variable num
	
	String fullName="",partialName="",item=""
	//get list of raw data files in folder that match "num" (add leading zeros)
	if( (num>9999) || (num<=0) )
		Print "error in  FindFileFromRunNumber(num), file number too large or too small"
		Return ("")
	Endif
	//make a four character string of the run number
	String numStr=""
	if(num<10)
		numStr = "000"+num2str(num)
	else
		if(num<100)
			numStr = "00"+num2str(num)
		else
			if(num<1000)
				numstr = "0"+num2str(num)
			else
				numStr = num2str(num)
			endif
		Endif
	Endif
	//Print "numstr = ",numstr
	
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
			testStr = V_GetRunNumStrFromFile(item)
			runFound= cmpstr(numStr,testStr)	//compare the three character strings, 0 if equal
			if(runFound == 0)
				//the run Number was found
				//build valid filename
				partialName = V_FindValidFileName(item)
				if(strlen(partialName) != 0)		//non-null return from FindValidFileName()
					fullName = path + partialName
					//check if RAW, if so,this must be the file!
					isRAW = V_CheckIfRawData(fullName)
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

//
// TODO -- for VSANS Nexus files, how do I quickly identify if a file is
//   RAW VSANS data? I don't want to generate any errors, but I want to quickly
//   weed out the reduced data sets, etc. from file catalogs.
//
//function to test a binary file to see if it is a RAW binary SANS file
//first checks the total bytes in the file (which for raw data is 33316 bytes)
//**note that the "DIV" file will also show up as a raw file by the run field
//should be listed in CAT/SHORT and in patch windows
//
//Function then checks the file fname (full path:file) for "RAW" run.type field
//if not found, the data is not raw data and zero is returned
//
// called by many procedures (both external and local)
//
// TODO -- as was written by SANS, this function is expecting fname to be the path:fileName
// - but are the V_get() functions OK with getting a full path, and what do they
//  do when they fail? I don't want them to spit up another open file dialog
//
Function V_CheckIfRawData(fname)
	String fname
	
	Variable refnum,totalBytes
	String testStr=""
	
	testStr = V_getInstrumentName(fname)
	
	if(cmpstr(testStr,"") != 0)
		//testStr exists, ASSUMING it's a raw VSANS data file
		Return(1)
	else
		//some other file
		Return(0)
	Endif
End


Function V_GetRunNumFromFile(item)
	String item
	
	String str = V_GetRunNumStrFromFile(item)
	
	return(str2num(str))
end


// TODO -- the file name structure for VSANS file is undecided
// so some of these base functions will need to change
//
//given a filename of a VSANS data filename of the form
// sansNNNN.nxs.ngv
//returns the run number "NNNN" as a STRING of FOUR characters
//returns "ABCD" as an invalid file number
//
// local function to aid in locating files by run number
//
Function/S V_GetRunNumStrFromFile(item)
	String item
	String invalid = "ABCD"	//"ABCD" is not a valid run number, since it's text
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable numChar = 4
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get the four characters preceeding it
		if (pos <= numChar-1)
			//not enough characters
			return (invalid)
		else
			runStr = item[pos-numChar,pos-1]
			return (runStr)
		Endif
	Endif
End

//Function attempts to find valid filename from partial name by checking for
// the existence of the file on disk.
// - checks as is
// - strips spaces
// - permutations of upper/lowercase
//
// added 11/99 - uppercase and lowercase versions of the file are tried, if necessary
// since from marquee, the filename field (textread[0]) must be used, and can be a mix of			//02JUL13
// upper/lowercase letters, while the filename on the server (should) be all caps
// now makes repeated calls to ValidFileString()
//
// returns a valid filename (No path prepended) or a null string
//
// called by any functions, both external and local
//
Function/S V_FindValidFilename(partialName)
	String PartialName
	
	String retStr=""
	
	//try name with no changes - to allow for ABS files that have spaces in the names 12APR04
	retStr = V_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//if the partial name is derived from the file header, there can be spaces at the beginning
	//or in the middle of the filename - depending on the prefix and initials used
	//
	//remove any leading spaces from the name before starting
	partialName = V_RemoveAllSpaces(partialName)
	
	//try name with no spaces
	retStr = V_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all UPPERCASE
	partialName = UpperStr(partialName)
	retStr = V_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all lowercase (ret null if failure)
	partialName = LowerStr(partialName)
	retStr = V_ValidFileString(partialName)
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
// TODO -- is this really necessary anymore for the NON-VAX files of VSANS.
// -- can this be made a pass-through, or will there be another function that is needed for VSANS?
//
Function/S V_ValidFileString(partialName)
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

//function to remove all spaces from names when searching for filenames
//the filename (as saved) will never have interior spaces (TTTTTnnn_AB _Bnnn)
//but the text field in the header WILL, if less than 3 characters were used for the 
//user's initials, and can have leading spaces if prefix was less than 5 characters
//
//returns a string identical to the original string, except with the interior spaces removed
//
// local function for file name manipulation
//
Function/S V_RemoveAllSpaces(str)
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
