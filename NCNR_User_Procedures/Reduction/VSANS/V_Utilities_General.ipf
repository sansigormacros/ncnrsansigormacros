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
	// SRK 2016, for windows 10, try to eliminate this restriction	
	//---- connecting through the network neighborhood seems to be perfectly fine except for 
	//     path issues with GBLoadWave, which only affects VAX data sets
		
//		print igorinfo(3)
//		//set the global to the path (as a string)
//		// need 4 \ since it is the escape character
//		if(cmpstr("\\\\",dum[0,1])==0)	//Windows user going through network neighborhood
//			DoAlert 0,alertStr
//			KillPath catPathName
//			return(1)
//		endif
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
	
	if(V_DataExists(type) > 0)
		V_UpdateDisplayInformation(type)
	else
		DoAlert 0,"No data in "+type
	endif
End

// 
//
// very simple function to look for something in a work folder
// -- only checks for FR data to exist, assumes everything else is there
// -- can't use the V_get() functions, these will try to load data if it's not there!
Function V_DataExists(type)
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
Function V_CloseEnough(v1,v2,tol)
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

// TODO:
// x- this still does not quite work. If there are no sub folders present in the RawVSANS folder
//    it still thinks there is (1) item there.
// -- if I replace the semicolon with a comma, it thinks there are two folders present and appears
//    to delete the RawVSANS folder itself! seems very dangerous...this is because DataFolderDir returns
//    a comma delimited list, but with a semicolon and \r at the end. need to remove these...
//
// NOTE -- use V_CleanupData_w_Progress(0,1) to get a progress bar - since this will take more than
//     a few seconds to complete, especially if a file catalog was done, or a "batch" patching, etc.
//
// *** this appears to be unused, in favor of V_CleanupData_w_Progress(0,1)  **********
//
Function V_CleanOutRawVSANS()

	SetDataFolder root:Packages:NIST:VSANS:RawVSANS:
	
	// get a list of the data folders there
	// kill them all if possible
	String list,item
	Variable numFolders,ii,pt
	
	list = DataFolderDir(1)
	// this has FOLDERS: at the beginning and is comma-delimited
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]			//remove the ";\r" from the end of the string
//	print list
	
	numFolders = ItemsInList(list , ",")
//	Print List
//	print strlen(list)

	for(ii=0;ii<numFolders;ii+=1)
		item = StringFromList(ii, list ,",")
//		Print item
		KillDataFolder/Z $(item)
	endfor

	list = DataFolderDir(1)
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]
	numFolders = ItemsInList(list, ",")
	Printf "%g RawVSANS folders could not be killed\r",numFolders
		
	SetDataFolder root:
	return(0)
End

//
// examples straight from Wavemetrics help file topic "Progress Windows"
// Try simpletest(0,0) and simpletest(1,0), simpletest(0,1) and simpletest(1,1)
//
//
// look for simpletest() function in Wavemetrics help file topic "Progress Windows"
//  this is a modified version.
//
// call with (1,1) to get the candystripe bar
// call with (0,1) to the the "countdown" bar as they are killed
//
Function V_CleanupData_w_Progress(indefinite, useIgorDraw)
	Variable indefinite
	Variable useIgorDraw		// True to use Igor's own draw method rather than native
	
	Variable num,numToClean
	
	// is there anything there to be killed?
	num = V_CleanOutOneRawVSANS()
	numToClean = num
	if(num <= 0)
		return(0)
	endif
	
	// there are some folders to kill, so proceed
	
	NewPanel /N=ProgressPanel /W=(285,111,739,193)
	ValDisplay valdisp0,win=ProgressPanel,pos={18,32},size={342,18},limits={0,num,0},barmisc={0,0}
	ValDisplay valdisp0,win=ProgressPanel,value= _NUM:0
	DrawText 20,24,"Cleaning up old files... Please Wait..."
	
	if( indefinite )
		ValDisplay valdisp0,win=ProgressPanel,mode= 4	// candy stripe
	else
		ValDisplay valdisp0,win=ProgressPanel,mode= 3	// bar with no fractional part
	endif
	if( useIgorDraw )
		ValDisplay valdisp0,win=ProgressPanel,highColor=(15000,45535,15000)		//(0,65535,0)
	endif
	Button bStop,win=ProgressPanel,pos={375,32},size={50,20},title="Stop"
	DoUpdate /W=ProgressPanel /E=1	// mark this as our progress window

	do
		num = V_CleanOutOneRawVSANS()
		if( V_Flag == 2 || num == 0 || num == -1)	// either "stop" or clean exit, or "done" exit from function
			break
		endif
		
		ValDisplay valdisp0,win=ProgressPanel,value= _NUM:num,win=ProgressPanel
		DoUpdate /W=ProgressPanel
	while(1)
	

	KillWindow ProgressPanel
	return(numToClean)
End


// 
// x- this still does not quite work. If there are no sub folders present in the RawVSANS folder
//    it still thinks there is (1) item there.
// x- if I replace the semicolon with a comma, it thinks there are two folders present and appears
//    to delete the RawVSANS folder itself! seems very dangerous...this is because DataFolderDir returns
//    a comma delimited list, but with a semicolon and \r at the end. need to remove these...
//
// x- for use with progress bar, kills only one folder, returns the new number of folders left
// x- if n(in) = n(out), nothing was able to be killed, so return "done" code
Function V_CleanOutOneRawVSANS()

	SetDataFolder root:Packages:NIST:VSANS:RawVSANS:
	
	// get a list of the data folders there
	// kill them all if possible
	String list,item
	Variable numFolders,ii,pt,numIn
	
	list = DataFolderDir(1)
	// this has FOLDERS: at the beginning and is comma-delimited
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]			//remove the ";\r" from the end of the string
//	print list
	
	numFolders = ItemsInList(list , ",")
	numIn = numFolders
//	Print List
//	print strlen(list)

	if(numIn > 0)
		item = StringFromList(0, list ,",")
//		Print item
		KillDataFolder/Z $(item)
	endif

	list = DataFolderDir(1)
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]
	numFolders = ItemsInList(list, ",")
	
	if(numIn == numFolders)
		Printf "%g RawVSANS folders could not be killed\r",numFolders
		SetDataFolder root:

		return (-1)
	endif
	
	SetDataFolder root:	
	return(numFolders)
End





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
// this will only load the data into RAW, overwriting whatever is there. no copy is put in rawVSANS
//
Function V_LoadAndPlotRAW_wName(fname)
	String fname

	Variable err=	V_LoadHDF5Data(fname,"RAW")			// load the data 
//	Print "Load err = "+num2str(err)
	if(!err)
		SVAR hdfDF = root:file_name			// last file loaded, may not be the safest way to pass
		String folder = StringFromList(0,hdfDF,".")
		
		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW")		// plot the data in whatever folder type
				
		// set the global to display ONLY if the load was called from here, not from the 
		// other routines that load data (to read in values)
		SVAR gLastFile =	root:Packages:NIST:VSANS:Globals:gLastLoadedFile
		gLastFile = hdfDF
	endif
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
	SVAR oldName = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
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
		V_UpdateDisplayInformation("RAW")	// plot the data in whatever folder type
		
		// set the global to display ONLY if the load was called from here, not from the 
		// other routines that load data (to read in values)
		SVAR gLastLoad = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
		gLastLoad = hdfDF
	endif

	// 
	// x- update the 1D plotting as needed. these are SANS calls (OK for now, but will need to be better)
	//do the average and plot (either the default, or what is on the panel currently)
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType
	type = "RAW"
	V_PlotData_Panel()		// read the binType from the panel
	Variable binType = V_GetBinningPopMode()
	V_BinningModePopup("",binType,"")		// does default circular binning and updates the graph


	return(0)
End


// Return the full path:filename that represents the previous or next file.
// Input is current filename and increment. 
// Increment should be -1 or 1
// -1 => previous file
// 1 => next file
//
// V_CheckIfRawData(fname)
//
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
//the file returned will be a RAW VSANS data file, other types of files are 
//filtered out.
//
//
// -- with the run numbers incrementing from 1, there is no need to add leading zeros to the
//    file names. simply add the number and go.
//
// called by Buttons.ipf and Transmission.ipf, and locally by parsing routines
//
Function/S V_FindFileFromRunNumber(num)
	Variable num
	
	String fullName="",partialName="",item=""
	//get list of raw data files in folder that match "num"

	String numStr=""
	numStr = num2str(num)

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
						//print "is raw, ",fullname
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
//  x- for VSANS Nexus files, how do I quickly identify if a file is
//   RAW VSANS data? I don't want to generate any errors, but I want to quickly
//   weed out the reduced data sets, etc. from file catalogs.
//	(check the instrument name...)

// TODO -- as was written by SANS, this function is expecting fname to be the path:fileName
// - but are the V_get() functions OK with getting a full path, and what do they
//  do when they fail? I don't want them to spit up another open file dialog
//
// -- problem -- if "sans1234.abs" is passed, then V_getStringFromHDF5(fname,path,num)
//  will remove the extension and look for the sans1234 folder -- which may or may not be present.
//  If it is present, then sans1234 validates as RAW data -- which is incorrect!
// -- so I need a way to exclude everything that does not have the proper extension...
//
//
Function V_CheckIfRawData(fname)
	String fname
	
	String testStr=""

// check for the proper raw data extension
	if( stringmatch(fname,"*.nxs.ngv*") )
		// name appears OK, proceed
		testStr = V_getInstrumentName(fname)

		if(cmpstr(testStr,"NG3-VSANS") == 0)
			//testStr exists, ASSUMING it's a raw VSANS data file
			Return(1)
		else
			//some other file
			Return(0)
		Endif
	
	else
		// not a proper raw VSANS file name
		return(0)
		
	endif	
	

End

//  x- need to fill in correctly by determining this from the INTENT field
//
Function V_isTransFile(fname)
	String fname
	
	Variable refnum,totalBytes
	String testStr=""
	
	testStr = V_getReduction_intent(fname)

	if(cmpstr(testStr,"TRANSMISSION") == 0)		//
		//yes, a transmission file
		Return(1)
	else
		//some other file intent
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
//returns the run number "NNNN" as a STRING of (x) characters
//
// -- the run number incements from 1, so the number of digits is UNKNOWN
// -- number starts at position [4] (the 5th character)
// -- number ends with the character prior to the first "."
//
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
		//found, get the characters preceeding it, but still after the "sans" characters
		if (pos-1 < 4)
			//not enough characters
			return (invalid)
		else
			runStr = item[4,pos-1]
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

// returns a list of raw data files in the catPathName directory on disk
// - list is SEMICOLON-delimited
//
//  decide how to do this...
// (1)
// checks each file in the directory to see if it is a RAW data file by
// call to V_CheckIfRawData() which currently looks for the instrument name in the file.
// -- CON - this is excruciatingly slow, and by checking a field in the file, has to load in the 
//  ENTIRE data file, and will load EVERY file in the folder. ugh.
//
// (2)
// as was done for VAX files, look for a specific string in the file name as written by the acquisition
//  (was .saN), now key on ".nxs.ngv"?
//
// ** use method (2), reading each file is just way too slow
//
//
Function/S V_GetRawDataFileList()
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	Endif
	String path = S_Path
	
	String list=IndexedFile(catPathName,-1,"????")
	String newList="",item="",validName="",fullName=""
	Variable num=ItemsInList(list,";"),ii
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list  ,";")

		validName = V_FindValidFileName(item)
		if(strlen(validName) != 0)		//non-null return from FindValidFileName()
			fullName = path + validName		

	//method (1)			
//			if(V_CheckIfRawData(item))
//				newlist += item + ";"
//			endif

	//method (2)			
			if( stringmatch(item,"*.nxs.ngv*") )
				newlist += item + ";"
			endif

			
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)
	return(newList)
End

//
// 
// x- does this need to be more sophisticated?
//
// simple "not" of V_GetRawDataFileList()
Function/S V_Get_NotRawDataFileList()
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	Endif
	String path = S_Path
	
	String list=IndexedFile(catPathName,-1,"????")
	String newList="",item="",validName="",fullName=""
	Variable num=ItemsInList(list,";"),ii
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list  ,";")

//		validName = V_FindValidFileName(item)
//		if(strlen(validName) != 0)		//non-null return from FindValidFileName()
//			fullName = path + validName		

	//method (2)			
			if( !stringmatch(item,"*.nxs.ngv*") )
				newlist += item + ";"
			endif

			
//		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)
	return(newList)
End


//the following is a WaveMetrics procedure from <StrMatchList>
// MatchList(matchStr,list,sep)
// Returns the items of the list whose items match matchStr
// The lists are separated by the sep character, usually ";"
//
// matchStr may be something like "abc", in which case it is identical to CmpStr
// matchStr may also be "*" to match anything, "abc*" to match anything starting with "abc",
//	"*abc" to match anything ending with "abc".
// matchStr may also begin with "!" to indicate a match to anything not matching the rest of
// 	the pattern.
// At most one "*" and one "!" are allowed in matchStr, otherwise the results are not guaranteed.
//
Function/S V_MyMatchList(matchStr,list,sep)
	String matchStr,list,sep
	String item,outList=""
	Variable n=strlen(list)
	Variable en,st=0
	do
		en= strsearch(list,sep,st)
		if( en < 0 )
			if( st < n-1 )
				en= n	// no trailing separator
				sep=""  // don't put sep in output, either
			else
				break	// no more items in list
			endif
		endif
		item=list[st,en-1]
		if( V_MyStrMatch(matchStr,item) == 0 )
			outlist += item+sep
		Endif
		st=en+1	
	while (st < n )	// exit is by break, above
	return outlist
End

//the following is a WaveMetrics procedure from <StrMatchList>
// StrMatch(matchStr,str)
// Returns 0 if the pattern in matchStr matches str, else it returns 1
//
// matchStr may be something like "abc", in which case it is identical to CmpStr
// matchStr may also be "*" to match anything, "abc*" to match anything starting with "abc",
//	"*abc" to match anything ending with "abc".
// matchStr may also begin with "!" to indicate a match to anything not matching the rest of
// 	the pattern.
// At most one "*" and one "!" are allowed in matchStr, otherwise the results are not guaranteed.
//
Function V_MyStrMatch(matchStr,str)
	String matchStr,str
	Variable match = 1		// 0 means match
	Variable invert= strsearch(matchStr,"!",0) == 0
	if( invert )
		matchStr[0,0]=""	// remove the "!"
	endif
	Variable st=0,en=strlen(str)-1
	Variable starPos= strsearch(matchStr,"*",0)
	if( starPos >= 0 )	// have a star
		if( starPos == 0 )	// at start
			matchStr[0,0]=""				// remove star at start
		else					// at end
			matchStr[starPos,999999]=""	// remove star and rest of (ignored, illegal) pattern
		endif
		Variable len=strlen(matchStr)
		if( len > 0 )
			if(starPos == 0)	// star at start, match must be at end
				st=en-len+1
			else
				en=len-1	// star at end, match at start
			endif
		else
			str=""	// so that "*" matches anything
		endif
	endif
	match= !CmpStr(matchStr,str[st,en])==0	// 1 or 0
	if( invert )
		match= 1-match
	endif
	return match
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
Function/S V_ParseRunNumberList(list)
	String list
	
	String newList="",item="",tempStr=""
	Variable num,ii,runNum
	
	//expand number ranges, if any
	list = V_ExpandNumRanges(list)
	
	num=itemsinlist(list,",")
	
	for(ii=0;ii<num;ii+=1)
		//get the item
		item = StringFromList(ii,list,",")
		//is it already a valid filename?
		tempStr=V_FindValidFilename(item) //returns filename if good, null if error
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
				tempStr = V_GetFileNameFromPathNoSemi( V_FindFileFromRunNumber(runNum) )
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
Function/S V_ExpandNumRanges(list)
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
			newList += V_ListFromDash(item)		
		endif
	endfor
	
	return newList
End

//be sure to add a trailing comma to the return string...
//
// local function
//
Function/S V_ListFromDash(item)
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

//*********************
// List utilities
//*********************
Function/WAVE V_List2TextWave(list,sep,waveStr)
	String list,sep,waveStr
	
	Variable n= ItemsInList(list,sep)
	Make/O/T/N=(n) $waveStr= StringFromList(p,list,sep)
	return $waveStr
End

Function/WAVE V_List2NumWave(list,sep,waveStr)
	String list,sep,waveStr
	
	Variable n= ItemsInList(list,sep)
	Make/O/D/N=(n) $waveStr= str2num( StringFromList(p,list,sep) )
	return $waveStr
End

Function /S V_TextWave2List(w,sep)
	Wave/T w
	String sep
	
	String newList=""
	Variable n=numpnts(w),ii=0
	do
		newList += w[ii] + sep
		ii+=1
	while(ii<n)
	return(newList)
End

//for numerical waves
Function/S V_NumWave2List(w,sep)
	Wave w
	String sep
	
	String newList="",temp=""
	Variable n=numpnts(w),ii=0,val
	do
		val=w[ii]
		temp=""
		sprintf temp,"%g",val
		newList += temp
		newList += sep
		ii+=1
	while(ii<n)
	return(newList)
End
