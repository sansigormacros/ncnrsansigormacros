#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
//		general utilities
//
// for use by multiple panels and packages
//

//prompts user to choose the local folder that contains the VSANS Data
//only one folder can be used, and its path is catPathName (and is a NAME, not a string)
//this will overwrite the path selection
//returns 1 if no path selected as error condition, or if user cancelled
Function V_PickPath()

	//set the global string to the selected pathname
	NewPath/O/M="pick the SANS data folder" catPathName
	if(V_Flag != 0)
		return (1) //user cancelled
	endif

	PathInfo/S catPathName
	string dum      = S_path
	string alertStr = ""
	alertStr = "You must set the path to Charlotte through a Mapped Network Drive, not through the Network Neighborhood"
	//alertStr += "  Please see the manual for details."
	if(V_flag == 0)
		//path does not exist - no folder selected
		string/G root:Packages:NIST:VSANS:Globals:gCatPathStr = "no folder selected"
		return (1)
	endif

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
	string/G root:Packages:NIST:VSANS:Globals:gCatPathStr = dum
	return (0) //no error

End

//
// entry from the Main Panel
//
Proc V_ChangeDisplay(type)
	string type
	Prompt type, "WORK data type to display", popup, "RAW;SAM;EMP;BGD;COR;ABS;STO;SUB;ADJ;"

	// make sure that data exists before passing this on...

	if(V_DataExists(type) > 0)
		V_UpdateDisplayInformation(type)
	else
		DoAlert 0, "No data in " + type
	endif
EndMacro

//
//
// very simple function to look for something in a work folder
// -- only checks for FR data to exist, assumes everything else is there
// -- can't use the V_get() functions, these will try to load data if it's not there!
Function V_DataExists(string type)

	WAVE/Z w = $("root:Packages:NIST:VSANS:" + type + ":entry:instrument:detector_FR:data")

	return (WaveExists(w))
End

// (DONE):
// x- this must be called as needed to force a re-read of the data from disk
//    "as needed" means that when an operation is done that needs to ensure
//     a fresh read from disk, it must take care of the kill.
//
// ksBaseDFPath points to RawVSANS
//
//
Function V_KillNamedDataFolder(string fname)

	variable err = 0

	string folderStr = V_GetFileNameFromPathNoSemi(fname)
	folderStr = V_RemoveDotExtension(folderStr)

	KillDataFolder/Z $(ksBaseDFPath + folderStr)
	err = V_flag

	return (err)
End

// (DONE)
// x- this still does not quite work. If there are no sub folders present in the RawVSANS folder
//    it still thinks there is (1) item there.
// x- if I replace the semicolon with a comma, it thinks there are two folders present and appears
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
	string list, item
	variable numFolders, ii, pt

	list = DataFolderDir(1)
	// this has FOLDERS: at the beginning and is comma-delimited
	list = list[8, strlen(list)]
	pt   = strsearch(list, ";", Inf, 1)
	list = list[0, pt - 1] //remove the ";\r" from the end of the string
	//	print list

	numFolders = ItemsInList(list, ",")
	//	Print List
	//	print strlen(list)

	for(ii = 0; ii < numFolders; ii += 1)
		item = StringFromList(ii, list, ",")
		//		Print item
		KillDataFolder/Z $(item)
	endfor

	list       = DataFolderDir(1)
	list       = list[8, strlen(list)]
	pt         = strsearch(list, ";", Inf, 1)
	list       = list[0, pt - 1]
	numFolders = ItemsInList(list, ",")
	Printf "%g RawVSANS folders could not be killed\r", numFolders

	SetDataFolder root:
	return (0)
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
// set flag True to use Igor's own draw method rather than native
Function V_CleanupData_w_Progress(variable indefinite, variable useIgorDraw)

	variable num, numToClean

	// is there anything there to be killed?
	num        = V_CleanOutOneRawVSANS()
	numToClean = num
	if(num <= 0)
		return (0)
	endif

	// there are some folders to kill, so proceed

	variable sc = 1

	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode

	if(gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel/N=ProgressPanel/W=(285 * sc, 111 * sc, 739 * sc, 193 * sc)
	ValDisplay valdisp0, win=ProgressPanel, pos={sc * 18, 32 * sc}, size={sc * 342, 18 * sc}, limits={0, num, 0}, barmisc={0, 0}
	ValDisplay valdisp0, win=ProgressPanel, value=_NUM:0
	DrawText 20 * sc, 24 * sc, "Cleaning up old files... Please Wait..."

	if(indefinite)
		ValDisplay valdisp0, win=ProgressPanel, mode=4 // candy stripe
	else
		ValDisplay valdisp0, win=ProgressPanel, mode=3 // bar with no fractional part
	endif
	if(useIgorDraw)
		ValDisplay valdisp0, win=ProgressPanel, highColor=(15000, 45535, 15000) //(0,65535,0)
	endif
	Button bStop, win=ProgressPanel, pos={sc * 375, 32 * sc}, size={sc * 50, 20 * sc}, title="Stop"
	DoUpdate/W=ProgressPanel/E=1 // mark this as our progress window

	do
		num = V_CleanOutOneRawVSANS()
		if(V_Flag == 2 || num == 0 || num == -1) // either "stop" or clean exit, or "done" exit from function
			break
		endif

		ValDisplay valdisp0, win=ProgressPanel, value=_NUM:num
		DoUpdate/W=ProgressPanel
	while(1)

	KillWindow ProgressPanel
	return (numToClean)
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
	string list, item
	variable numFolders, ii, pt, numIn

	list = DataFolderDir(1)
	// this has FOLDERS: at the beginning and is comma-delimited
	list = list[8, strlen(list)]
	pt   = strsearch(list, ";", Inf, 1)
	list = list[0, pt - 1] //remove the ";\r" from the end of the string
	//	print list

	numFolders = ItemsInList(list, ",")
	numIn      = numFolders
	//	Print List
	//	print strlen(list)

	if(numIn > 0)
		item = StringFromList(0, list, ",")
		//		Print item
		KillDataFolder/Z $(item)
	endif

	list       = DataFolderDir(1)
	list       = list[8, strlen(list)]
	pt         = strsearch(list, ";", Inf, 1)
	list       = list[0, pt - 1]
	numFolders = ItemsInList(list, ",")

	if(numIn == numFolders)
		Printf "%g RawVSANS folders could not be killed\r", numFolders
		SetDataFolder root:

		return (-1)
	endif

	SetDataFolder root:
	return (numFolders)
End

//given a filename of a SANS data filename of the form
// name.anything
//returns the name as a string without the ".fbdfasga" extension
//
// returns the input string if a "." can't be found (maybe it wasn't there)
Function/S V_RemoveDotExtension(string item)

	string   invalid = item //
	variable num     = -1

	//find the "dot"
	string   runStr = ""
	variable pos    = strsearch(item, ".", 0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	endif

	//found, get all of the characters preceeding it
	runStr = item[0, pos - 1]
	return (runStr)
End

//returns a string containing filename (WITHOUT the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// called by MaskUtils.ipf, ProtocolAsPanel.ipf, WriteQIS.ipf
//
Function/S V_GetFileNameFromPathNoSemi(string fullPath)

	variable offset1, offset2
	string filename = ""
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if(offset2 == -1) // no more colons ?
			fileName = FullPath[offset1, strlen(FullPath)]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2 + 1
	while(1)

	//remove version number from name, if it's there - format should be: filename;N
	filename = StringFromList(0, filename, ";") //returns null if error

	return filename
End

//
// -- this was copied directly, no changes , from PlotUtils_Macro_v40
//
// returns the path to the file, or null if the user cancelled
// fancy use of optional parameters
//
// enforce short file names (25 characters)
Function/S V_DoSaveFileDialog(string msg, [string fname, string suffix])

	variable refNum
	//	String message = "Save the file as"

	if(ParamIsDefault(fname))
		//		Print "fname not supplied"
		fname = ""
	endif
	if(ParamIsDefault(suffix))
		//		Print "suffix not supplied"
		suffix = ""
	endif

	string outputPath, tmpName, testStr
	variable l1, l2
	variable badLength = 0
	variable maxLength = 25

	tmpName = fname + suffix

	do
		badLength = 0
		Open/D/M=msg/T="????" refNum as tmpName //OS will allow 255 characters, but then I can't read it back in!
		outputPath = S_fileName

		testStr = ParseFilePath(0, outputPath, ":", 1, 0) //just the filename
		if(strlen(testStr) == 0)
			break //cancel, allow exit
		endif
		if(strlen(testStr) > maxLength)
			badlength = 1
			DoAlert 2, "File name is too long. Is\r" + testStr[0, maxLength - 1] + "\rOK?"
			if(V_flag == 3)
				outputPath = ""
				break
			endif
			if(V_flag == 1) //my suggested name is OK, so trim the output
				badlength = 0
				l1        = strlen(testStr) //too long length
				l1        = l1 - maxLength  //number to trim
				//Print outputPath
				l2         = strlen(outputPath)
				outputPath = outputPath[0, l2 - 1 - l1]
				//Print "modified  ",outputPath
			endif
			//if(V_flag==2)  do nothing, let it go around again
		else
			// length is OK, set the output path, exit loop and return
			outputPath = testStr
		endif

	while(badLength)

	return outputPath
End

//
// this will only load the data into RAW, overwriting whatever is there. no copy is put in rawVSANS
//
Function V_LoadAndPlotRAW_wName(string fname)

	variable err = V_LoadHDF5Data(fname, "RAW") // load the data
	//	Print "Load err = "+num2str(err)
	if(!err)
		SVAR   hdfDF  = root:file_name // last file loaded, may not be the safest way to pass
		string folder = StringFromList(0, hdfDF, ".")

		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

		// set the global to display ONLY if the load was called from here, not from the
		// other routines that load data (to read in values)
		SVAR gLastFile = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
		gLastFile = hdfDF
	endif
End

//
// previous/next button needs these functions
// as well as many other utilities that manipulate the data file names
// and parse run numbers.
//

// DONE
// x- getting the file_name from the root: global is a poor choice.
//     Need a better, more reliable solution than this -- actually this is a fine choice, since
//     I need to load a file (which sets the global) to get the button to display "next"
//
// DONE
// x- load in the proper file
// x- re-click the I(q) button
// x- be sure that the globals are updated w/ filename
// x- make a copy of "oldName" that is local and not the SVAR, as the SVAR changes
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
Function V_LoadPlotAndDisplayRAW(variable increment)

	variable i, val
	string filename, tmp, curFileName, str
	//take the currently displayed RAW file
	SVAR oldName = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
	oldname     = V_RemoveAllSpaces(oldname) //
	curFileName = oldName

	filename = oldname

	i   = 1
	val = increment
	do

		val      = i * increment
		filename = V_GetPrevNextRawFile(oldName, val)

		//		printf "i=%d, file=%s\r",i,filename

		tmp = ParseFilePath(0, filename, ":", 1, 0)

		i += 1
	while(strlen(tmp) == 0 && i < 11)

	if(strlen(tmp) == 0) //in some cases, a null string can be returned - handle gracefully
		return (0)
	endif

	// display the specified RAW data file
	// this is the set of steps done in DisplayMainButtonProc(ctrlName) : ButtonControl
	variable err = V_LoadHDF5Data(filename, "RAW") // load the data, set the global w/file name loaded
	//	Print "Load err = "+num2str(err)
	if(!err)
		SVAR   hdfDF  = root:file_name // last file loaded, may not be the safest way to pass
		string folder = StringFromList(0, hdfDF, ".")

		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW") // plot the data in whatever folder type

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
	V_PlotData_Panel() // read the binType from the panel
	variable binType = V_GetBinningPopMode()
	ControlInfo/W=V_1D_Data popup0
	V_BinningModePopup("", binType, S_Value) // does default circular binning and updates the graph

	return (0)
End

// Return the full path:filename that represents the previous or next file.
// Input is current filename and increment.
// Increment should be -1 or 1
// -1 => previous file
// 1 => next file
//
// V_CheckIfRawData(fname)
//
Function/S V_GetPrevNextRawFile(string curfilename, variable prevnext)

	string filename

	//get the run number
	variable num = V_GetRunNumFromFile(curfilename)

	//find the next specified file by number
	fileName = V_FindFileFromRunNumber(num + prevnext)

	return filename
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
Function/S V_FindFileFromRunNumber(variable num)

	string fullName    = ""
	string partialName = ""
	string item        = ""
	//get list of raw data files in folder that match "num"

	string numStr = ""
	numStr = num2istr(num)

	//make sure that path exists
	PathInfo catPathName
	string path = S_path
	if(V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	endif
	string list    = ""
	string newList = ""
	string testStr = ""

	list = IndexedFile(catPathName, -1, "????") //get all files in folder
	//find (the) one with the number in the run # location in the name
	variable numItems, ii, runFound, isRAW
	numItems = ItemsInList(list, ";") //get the new number of items in the list
	ii       = 0
	do
		//parse through the list in this order:
		// 1 - does item contain run number (as a string) "TTTTTnnn.SAn_XXX_Tyyy"
		// 2 - exclude by isRaw? (to minimize disk access)
		item = StringFromList(ii, list, ";")
		if(strlen(item) != 0)
			//find the run number, if it exists as a three character string
			testStr  = V_GetRunNumStrFromFile(item)
			runFound = cmpstr(numStr, testStr) //compare the three character strings, 0 if equal
			if(runFound == 0)
				//the run Number was found
				//build valid filename
				partialName = V_FindValidFileName(item)
				if(strlen(partialName) != 0) //non-null return from FindValidFileName()
					fullName = path + partialName
					//check if RAW, if so,this must be the file!
					isRAW = V_CheckIfRawData(fullName)
					if(isRaw)
						//print "is raw, ",fullname
						//stop here
						return (fullname)
					endif
				endif
			endif
		endif
		ii += 1
	while(ii < numItems) //process all items in list
	return ("") //null return if file not found in list
End

//
//  x- for VSANS Nexus files, how do I quickly identify if a file is
//   RAW VSANS data? I don't want to generate any errors, but I want to quickly
//   weed out the reduced data sets, etc. from file catalogs.
//	(check the instrument name...)

// (DONE) x- as was written by SANS, this function is expecting fname to be the path:fileName
// - but are the V_get() functions OK with getting a full path, and what do they
//  do when they fail? I don't want them to spit up another open file dialog
//
// x- problem -- if "sans1234.abs" is passed, then V_getStringFromHDF5(fname,path,num)
//  will remove the extension and look for the sans1234 folder -- which may or may not be present.
//  If it is present, then sans1234 validates as RAW data -- which is incorrect!
// x- so I need a way to exclude everything that does not have the proper extension...
//
//
Function V_CheckIfRawData(string fname)

	string testStr = ""

	// check for the proper raw data extension
	if(stringmatch(fname, "*.nxs.ngv*"))
		// name appears OK, proceed
		testStr = V_getInstrumentName(fname)

		if(cmpstr(testStr, "NG3-VSANS") == 0)
			//testStr exists, ASSUMING it's a raw VSANS data file
			return (1)
		endif

		//some other file
		return (0)

	else
		// not a proper raw VSANS file name
		return (0)

	endif

End

//  x- need to fill in correctly by determining this from the INTENT field
//
Function V_isTransFile(string fname)

	variable refnum, totalBytes
	string testStr = ""

	testStr = V_getReduction_intent(fname)

	if(cmpstr(testStr, "TRANSMISSION") == 0) //
		//yes, a transmission file
		return (1)
	endif

	//some other file intent
	return (0)
End

Function V_GetRunNumFromFile(string item)

	string str = V_GetRunNumStrFromFile(item)

	return (str2num(str))
End

// (DONE) x- the file name structure for VSANS file is undecided
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
Function/S V_GetRunNumStrFromFile(string item)

	string   invalid = "ABCD" //"ABCD" is not a valid run number, since it's text
	variable num     = -1

	//find the "dot"
	string   runStr  = ""
	variable numChar = 4
	variable pos     = strsearch(item, ".", 0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	endif

	//found, get the characters preceeding it, but still after the "sans" characters
	if((pos - 1) < 4)
		//not enough characters
		return (invalid)
	endif

	runStr = item[4, pos - 1]
	return (runStr)
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
Function/S V_FindValidFilename(string partialName)

	string retStr = ""

	//try name with no changes - to allow for ABS files that have spaces in the names 12APR04
	retStr = V_ValidFileString(partialName)
	if(cmpstr(retStr, "") != 0)
		//non-null return
		return (retStr)
	endif

	//if the partial name is derived from the file header, there can be spaces at the beginning
	//or in the middle of the filename - depending on the prefix and initials used
	//
	//remove any leading spaces from the name before starting
	partialName = V_RemoveAllSpaces(partialName)

	//try name with no spaces
	retStr = V_ValidFileString(partialName)
	if(cmpstr(retStr, "") != 0)
		//non-null return
		return (retStr)
	endif

	//try all UPPERCASE
	partialName = UpperStr(partialName)
	retStr      = V_ValidFileString(partialName)
	if(cmpstr(retStr, "") != 0)
		//non-null return
		return (retStr)
	endif

	//try all lowercase (ret null if failure)
	partialName = LowerStr(partialName)
	retStr      = V_ValidFileString(partialName)
	if(cmpstr(retStr, "") != 0)
		//non-null return
		return (retStr)
	endif

	return (retStr)
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
// DONE
// x- this is essentially a pass-through, since there are no version numbers for VSANS data files
//    it is kept in case there are conditions in the future.
//
Function/S V_ValidFileString(string partialName)

	string tempName = ""
	string msg      = ""
	variable ii, refnum

	ii = 0
	do
		if(ii == 0)
			//first pass, try the partialName
			tempName = partialName
			Open/Z/R/T="????TEXT"/P=catPathName refnum, tempName //Does open file (/Z flag)
			if(V_flag == 0)
				//file exists
				Close refnum //YES needed,
				break
			endif
		else
			tempName = partialName + ";" + num2istr(ii)
			Open/Z/R/T="????TEXT"/P=catPathName refnum, tempName
			if(V_flag == 0)
				//file exists
				Close refnum
				break
			endif
		endif
		ii += 1
		//print "ii=",ii
	while(ii < 11)
	//go get the selected bits of information, using tempName, which exists
	if(ii >= 11)
		//msg = partialName + " not found. is version number > 11?"
		//DoAlert 0, msg
		//PathInfo catPathName
		//Print S_Path
		return ("") //use null string as error condition
	endif

	return (tempName)
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
Function/S V_RemoveAllSpaces(string str)

	string tempstr = str
	variable ii, spc, len //should never be more than 2 or 3 trailing spaces in a filename
	ii = 0
	do
		len = strlen(tempStr)
		spc = strsearch(tempStr, " ", 0) //is the last character a space?
		if(spc == -1)
			break //no more spaces found, get out
		endif
		str     = tempstr
		tempStr = str[0, (spc - 1)] + str[(spc + 1), (len - 1)] //remove the space from the string
	while(1) //should never be more than 2 or 3

	if(strlen(tempStr) < 1)
		tempStr = "" //be sure to return a null string if problem found
	endif

	//Print strlen(tempstr)

	return (tempStr)

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
	if(V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	endif
	string path = S_Path

	string list      = IndexedFile(catPathName, -1, "????")
	string newList   = ""
	string item      = ""
	string validName = ""
	string fullName  = ""
	variable ii
	variable num = ItemsInList(list, ";")

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")

		validName = V_FindValidFileName(item)
		if(strlen(validName) != 0) //non-null return from FindValidFileName()
			fullName = path + validName

			//method (1)
			//			if(V_CheckIfRawData(item))
			//				newlist += item + ";"
			//			endif

			//method (2)
			if(stringmatch(item, "*.nxs.ngv*"))
				newlist += item + ";"
			endif

		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList, ";", 0)
	return (newList)
End

//
//
// x- does this need to be more sophisticated?
//
// simple "not" of V_GetRawDataFileList()
Function/S V_Get_NotRawDataFileList()

	//make sure that path exists
	PathInfo catPathName
	if(V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	endif
	string path = S_Path

	string list      = IndexedFile(catPathName, -1, "????")
	string newList   = ""
	string item      = ""
	string validName = ""
	string fullName  = ""
	variable ii
	variable num = ItemsInList(list, ";")

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")

		//		validName = V_FindValidFileName(item)
		//		if(strlen(validName) != 0)		//non-null return from FindValidFileName()
		//			fullName = path + validName

		//method (2)
		if(!stringmatch(item, "*.nxs.ngv*"))
			newlist += item + ";"
		endif

		//		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList, ";", 0)
	return (newList)
End

// removes any item with ".EXT" from the list
// don't pass the "."
// returns a modified list
Function/S V_RemoveEXTFromList(string list, string ext)

	ext = "*." + ext
	variable ii
	variable num = ItemsInList(list, ";")
	string item
	string newList = ""

	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")

		if(!stringmatch(item, ext))
			newlist += item + ";"
		endif

	endfor
	return (newList)
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
Function/S V_MyMatchList(string matchStr, string list, string sep)

	string item
	string   outList = ""
	variable n       = strlen(list)
	variable en
	variable st = 0
	do
		en = strsearch(list, sep, st)
		if(en < 0)
			if(st < (n - 1))
				en  = n  // no trailing separator
				sep = "" // don't put sep in output, either
			else
				break // no more items in list
			endif
		endif
		item = list[st, en - 1]
		if(V_MyStrMatch(matchStr, item) == 0)
			outlist += item + sep
		endif
		st = en + 1
	while(st < n) // exit is by break, above
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
Function V_MyStrMatch(string matchStr, string str)

	variable match  = 1 // 0 means match
	variable invert = strsearch(matchStr, "!", 0) == 0
	if(invert)
		matchStr[0, 0] = "" // remove the "!"
	endif
	variable st      = 0
	variable en      = strlen(str) - 1
	variable starPos = strsearch(matchStr, "*", 0)
	if(starPos >= 0) // have a star
		if(starPos == 0) // at start
			matchStr[0, 0] = "" // remove star at start
		else // at end
			matchStr[starPos, 999999] = "" // remove star and rest of (ignored, illegal) pattern
		endif
		variable len = strlen(matchStr)
		if(len > 0)
			if(starPos == 0) // star at start, match must be at end
				st = en - len + 1
			else
				en = len - 1 // star at end, match at start
			endif
		else
			str = "" // so that "*" matches anything
		endif
	endif
	match = !CmpStr(matchStr, str[st, en]) == 0 // 1 or 0
	if(invert)
		match = 1 - match
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
Function/S V_ParseRunNumberList(string list)

	string newList = ""
	string item    = ""
	string tempStr = ""
	variable num, ii, runNum

	//expand number ranges, if any
	list = V_ExpandNumRanges(list)

	num = itemsinlist(list, ",")

	for(ii = 0; ii < num; ii += 1)
		//get the item
		item = StringFromList(ii, list, ",")
		//is it already a valid filename?
		tempStr = V_FindValidFilename(item) //returns filename if good, null if error
		if(strlen(tempstr) != 0)
			//valid name, add to list
			//Print "it's a file"
			newList += tempStr + ","
		else
			//not a valid name
			//is it a number?
			runNum = str2num(item)
			//print runnum
			if(numtype(runNum) != 0)
				//not a number -  maybe an error
				DoAlert 0, "List item " + item + " is not a valid run number or filename. Please enter a valid number or filename."
				return ("")
			endif

			//a run number or an error
			tempStr = V_GetFileNameFromPathNoSemi(V_FindFileFromRunNumber(runNum))
			if(strlen(tempstr) == 0)
				//file not found, error
				DoAlert 0, "List item " + item + " is not a valid run number. Please enter a valid number."
				return ("")
			endif

			newList += tempStr + ","
		endif
	endfor //loop over all items in list

	return (newList)
End

//takes a comma delimited list that MAY contain number range, and
//expands any range of run numbers into a comma-delimited list...
//and returns the new list - if not a range, return unchanged
//
// local function
//
Function/S V_ExpandNumRanges(string list)

	string item, str
	string newList = ""
	string dash    = "-"
	variable num, ii, hasDash

	num = itemsinlist(list, ",")
	//	print num
	for(ii = 0; ii < num; ii += 1)
		//get the item
		item = StringFromList(ii, list, ",")
		//does it contain a dash?
		hasDash = strsearch(item, dash, 0) //-1 if no dash found
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
Function/S V_ListFromDash(string item)

	string numList = ""
	string loStr   = ""
	string hiStr   = ""
	variable lo, hi, ii

	loStr = StringFromList(0, item, "-") //treat the range as a list
	hiStr = StringFromList(1, item, "-")
	lo    = str2num(loStr)
	hi    = str2num(hiStr)
	if((numtype(lo) != 0) || (numtype(hi) != 0) || (lo > hi))
		numList = ""
		return numList
	endif
	for(ii = lo; ii <= hi; ii += 1)
		numList += num2istr(ii) + ","
	endfor

	return numList
End

//*********************
// List utilities
//*********************
Function/WAVE V_List2TextWave(string list, string sep, string waveStr)

	variable n = ItemsInList(list, sep)
	Make/O/T/N=(n) $waveStr = StringFromList(p, list, sep)
	return $waveStr
End

Function/WAVE V_List2NumWave(string list, string sep, string waveStr)

	variable n = ItemsInList(list, sep)
	Make/O/D/N=(n) $waveStr = str2num(StringFromList(p, list, sep))
	return $waveStr
End

Function/S V_TextWave2List(WAVE/T w, string sep)

	string   newList = ""
	variable n       = numpnts(w)
	variable ii      = 0
	do
		newList += w[ii] + sep
		ii      += 1
	while(ii < n)
	return (newList)
End

//for numerical waves
Function/S V_NumWave2List(WAVE w, string sep)

	string newList = ""
	string temp    = ""
	variable val
	variable n  = numpnts(w)
	variable ii = 0
	do
		val  = w[ii]
		temp = ""
		sprintf temp, "%g", val
		newList += temp
		newList += sep
		ii      += 1
	while(ii < n)
	return (newList)
End

/////
// @ IgorExchange
//TicToc
//Posted April 16th, 2009 by bgallarda
//	•	in Programming 6.10.x

////duplicated here -- for VSANS use
Function v_tic()

	NVAR/Z tictoc = root:tictoc
	if(NVAR_exists(tictoc))
		print "timer exists"
	endif
	variable/G root:tictoc = startMSTimer
End

Function v_toc()

	NVAR/Z   tictoc = root:tictoc
	variable ttTime = stopMSTimer(tictoc)
	printf "%g seconds\r", (ttTime / 1e6)
	killvariables/Z root:tictoc

	return (ttTime / 1e6)
End

////// methods for filtering out different lists of files.

// testStr is the "intent" string, or grep string
// method is the method to use to find the file
// 0 = (default) is to use the file catalog (= fastest)
// 1 = Grep (not terribly slow)
// 2 = read every file (bad choice)
//
Function/S V_getFileIntentList(string testStr, variable method)

	variable ii, num
	string fname, newList, intent
	string list = ""
	string item = ""

	// read every file...
	if(method == 2)
		PathInfo catPathName
		string path = S_path
		newList = V_GetRawDataFileList()
		num     = ItemsInList(newList)

		for(ii = 0; ii < num; ii += 1)
			item   = StringFromList(ii, newList, ";")
			fname  = path + item
			intent = V_getReduction_intent(fname)
			if(cmpstr(intent, testStr) == 0)
				list += item + ";"
			endif
		endfor
	endif

	// use Grep
	if(method == 1)
		newList = V_GetRawDataFileList()
		num     = ItemsInList(newList)
		for(ii = 0; ii < num; ii += 1)
			item = StringFromList(ii, newList, ";")
			Grep/P=catPathName/Q/E=("(?i)" + testStr) item
			if(V_value) // at least one instance was found
				//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

	else
		// get the list from the file catalog

		WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
		WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent

		variable np = numpnts(intentW) //fileNameW is LONGER - so don't use numpnts(fileWave)
		for(ii = 0; ii < np; ii += 1)
			if(cmpstr(intentW[ii], testStr) == 0) //this is case-INSENSITIVE (necessary, since the case is unknown)
				list += fileNameW[ii] + ";"
			endif
		endfor

		List = SortList(List, ";", 0)
	endif

	return (list)
End

// testStr is the "purpose" string, or grep string
// method is the method to use to find the file
// 0 = (default) is to use the file catalog (= fastest)
// 1 = Grep (not terribly slow)
// 2 = read every file (bad choice)
//
Function/S V_getFilePurposeList(string testStr, variable method)

	variable ii, num
	string fname, newList, purpose
	string list = ""
	string item = ""

	// read every file...
	if(method == 2)
		PathInfo catPathName
		string path = S_path
		newList = V_GetRawDataFileList()
		num     = ItemsInList(newList)

		for(ii = 0; ii < num; ii += 1)
			item    = StringFromList(ii, newList, ";")
			fname   = path + item
			purpose = V_getReduction_purpose(fname)
			if(cmpstr(purpose, testStr) == 0)
				list += item + ";"
			endif
		endfor
	endif

	// use Grep
	if(method == 1)
		newList = V_GetRawDataFileList()
		num     = ItemsInList(newList)
		for(ii = 0; ii < num; ii += 1)
			item = StringFromList(ii, newList, ";")
			Grep/P=catPathName/Q/E=("(?i)" + testStr) item
			if(V_value) // at least one instance was found
				//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

	else
		// get the list from the file catalog

		WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
		WAVE/T purposeW  = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose

		variable np = numpnts(purposeW) //fileNameW is LONGER - so don't use numpnts(fileWave)
		for(ii = 0; ii < np; ii += 1)
			if(cmpstr(purposeW[ii], testStr) == 0) //this is case-INSENSITIVE (necessary, since the case is unknown)
				list += fileNameW[ii] + ";"
			endif
		endfor

		List = SortList(List, ";", 0)
	endif

	return (list)
End

// match BOTH the intent and purpose
// -- needed to identify the SAMPLE + SCATTERING data files.
//
//
// method is the method to use to find the file (currently ignored, CAT is always used)
// 0 = (default) is to use the file catalog (= fastest)
// 1 = Grep (not terribly slow)
// 2 = read every file (bad choice)
//
Function/S V_getFileIntentPurposeList(string intent, string purpose, variable method)

	variable ii, num
	string fname, newList
	string list = ""
	string item = ""

	//	// read every file...
	//	if(method == 2)
	//		PathInfo catPathName
	//		String path = S_path
	//		newList = V_GetRawDataFileList()
	//		num=ItemsInList(newList)
	//
	//		for(ii=0;ii<num;ii+=1)
	//			item=StringFromList(ii, newList , ";")
	//			fname = path + item
	//			purpose = V_getReduction_purpose(fname)
	//			if(cmpstr(purpose,testStr) == 0)
	//				list += item + ";"
	//			endif
	//		endfor
	//	endif
	//
	//	// use Grep
	//	if(method == 1)
	//		newList = V_GetRawDataFileList()
	//		num=ItemsInList(newList)
	//		for(ii=0;ii<num;ii+=1)
	//			item=StringFromList(ii, newList , ";")
	//			Grep/P=catPathName/Q/E=("(?i)"+testStr) item
	//			if( V_value )	// at least one instance was found
	//	//				Print "found ", item,ii
	//				list += item + ";"
	//			endif
	//		endfor
	//
	//	else
	// get the list from the file catalog

	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T purposeW  = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose
	WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent

	variable np = numpnts(purposeW) //fileNameW is LONGER - so don't use numpnts(fileWave)
	for(ii = 0; ii < np; ii += 1)
		if(cmpstr(purposeW[ii], purpose) == 0 && cmpstr(intentW[ii], intent) == 0) //this is case-INSENSITIVE (necessary, since the case is unknown)
			//print "adding  "+ fileNameW[ii]+"   "+num2str(ii)
			list += fileNameW[ii] + ";"

		endif
	endfor

	List = SortList(List, ";", 0)

	return (list)
End

// match the INTENT and PURPOSE and GROUP_ID
//
// -- needed to identify the SAMPLE + SCATTERING data files.
//
//
// method is the method to use to find the file (currently ignored, CAT is always used)
// 0 = (default) is to use the file catalog (= fastest)
// 1 = Grep (not terribly slow)
// 2 = read every file (bad choice)
//
Function/S V_getFileIntentPurposeIDList(string intent, string purpose, variable targetID, variable method)

	variable ii, num
	string fname, newList
	string list = ""
	string item = ""

	//	// read every file...
	//	if(method == 2)
	//		PathInfo catPathName
	//		String path = S_path
	//		newList = V_GetRawDataFileList()
	//		num=ItemsInList(newList)
	//
	//		for(ii=0;ii<num;ii+=1)
	//			item=StringFromList(ii, newList , ";")
	//			fname = path + item
	//			purpose = V_getReduction_purpose(fname)
	//			if(cmpstr(purpose,testStr) == 0)
	//				list += item + ";"
	//			endif
	//		endfor
	//	endif
	//
	//	// use Grep
	//	if(method == 1)
	//		newList = V_GetRawDataFileList()
	//		num=ItemsInList(newList)
	//		for(ii=0;ii<num;ii+=1)
	//			item=StringFromList(ii, newList , ";")
	//			Grep/P=catPathName/Q/E=("(?i)"+testStr) item
	//			if( V_value )	// at least one instance was found
	//	//				Print "found ", item,ii
	//				list += item + ";"
	//			endif
	//		endfor
	//
	//	else
	// get the list from the file catalog

	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T purposeW  = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose
	WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent
	WAVE   groupIDW  = root:Packages:NIST:VSANS:CatVSHeaderInfo:group_id

	variable np = numpnts(purposeW) //fileNameW is LONGER - so don't use numpnts(fileWave)
	for(ii = 0; ii < np; ii += 1)
		if(cmpstr(purposeW[ii], purpose) == 0 && cmpstr(intentW[ii], intent) == 0 && groupIDW[ii] == targetID) //this is case-INSENSITIVE (necessary, since the case is unknown)
			list += fileNameW[ii] + ";"
		endif
	endfor

	List = SortList(List, ";", 0)

	return (list)
End

// from WM procedure, extended to three waves for I(q) data sets
//
// RemoveNaNsQIS(theQWave, theIWave, theSWave)
//	Removes all points in an XYZ triple if any of the three waves has the value NaN.
//	A NaN represents a blank or missing value.
//	Returns the number of points removed.
Function V_RemoveNaNsQIS(WAVE theXWave, WAVE theYWave, WAVE theZWave)

	variable p, numPoints, numNaNs
	variable xval, yval, zval

	numNaNs   = 0
	p         = 0                 // the loop index
	numPoints = numpnts(theXWave) // number of times to loop

	do
		xval = theXWave[p]
		yval = theYWave[p]
		zval = theZWave[p]
		if((numtype(xval) == 2) | (numtype(yval) == 2) | (numtype(zval) == 2)) // either is NaN?
			numNaNs += 1
		else // if not an outlier
			theXWave[p - numNaNs] = xval // copy to input wave
			theYWave[p - numNaNs] = yval // copy to input wave
			theZWave[p - numNaNs] = zval // copy to input wave
		endif
		p += 1
	while(p < numPoints)

	// Truncate the wave
	DeletePoints numPoints - numNaNs, numNaNs, theXWave, theYWave, theZWave

	return (numNaNs)
End

//
////// utilities for the back detector to diagnose saturation issues
//
//
// as of March 2019, the detector data is processed differently, with more
// processing done before passing the data to the file. The data is collected
// in 1x1 mode, then filtered (11x11) and rebinned. This increases the
// pixel saturation value to 16399*16 = 262384
// and the read background to ≈ 200*16
//
//
//
// old values were (pre-March 2019) =  saturation value of 16384 and read baackground of 200
// (before the 1x1 collection)
//

Proc Vm_NumberSaturated(folderStr)
	string folderStr = "RAW"
	V_NumberSaturated(folderStr)
EndMacro

Function V_NumberSaturated(string folderStr)

	variable num, saturationValue
	Duplicate/O $("root:Packages:NIST:VSANS:" + folderStr + ":entry:instrument:detector_B:data"), tmpData

	saturationValue = 16399 * 16

	tmpData = (tmpData > (saturationValue - 1)) ? NaN : tmpData
	WaveStats/Q tmpData
	num = V_numNaNs

	Printf "Number of saturated pixels = %d (%g %)\r", num, num / (680 * 1656) * 100
	KillWaves/Z tmpData

	V_ColorizeSaturated()
	return (num)
End

// turns the saturated values to lime green
Function V_ColorizeSaturated()

	ModifyImage data, ctab={0, 16399 * 16 - 1, ColdWarm, 0}, minRGB=0, maxRGB=(32792, 65535, 1)
End

///

Function V_PrintLoHiNum()

	variable lo, hi
	V_Find_LoHi_RunNum(lo, hi)
	Print "lo = ", lo
	Print "hi = ", hi

End

//
// finds the lo, hi run numbers in the current directory
// - (NO)--sets the global values for later use
//
// - 2025 -- changed back to pass by reference to be able to set global values that are
// 		specific to each patch panel and won't change unexpectedly
//
// - (NO) you don't really need to pass anything in, the parameters are leftovers from
// the initial version where the values were pass-by-reference and returned
//
// note that 1111 (is a special number for the ReadNoise file, ignore this run)
//
Function V_Find_LoHi_RunNum(variable &lo, variable &hi)

	string fileList = ""
	string fname    = ""
	variable ii, num, runNum

	// set to values that will change
	lo = 1e8
	hi = 0

	// get a file listing of all raw data files
	fileList = V_GetRawDataFileList()
	num      = itemsInList(fileList)

	for(ii = 0; ii < num; ii += 1)
		fname  = stringFromList(ii, fileList)
		runNum = V_GetRunNumFromFile(fname)

		if(runNum != 1111) //ignore this run
			lo = (runNum < lo) ? runNum : lo // if runNum < lo, update
			hi = (runNum > hi) ? runNum : hi // if runNum > hi, update
		endif
	endfor

	// set the globals
	//	NVAR loVal = root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Lo
	//	NVAR hiVal = root:Packages:NIST:VSANS:Globals:Patch:gFileNum_Hi
	//
	//	loVal = lo
	//	hiVal = hi

	return (0)
End

