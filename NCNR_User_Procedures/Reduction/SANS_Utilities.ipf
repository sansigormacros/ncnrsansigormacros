#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 6.0

// contains general utility procedures for:
// file open dialogs
// paths
// lists to waves (and the reverse)
//
// and BETA procedures for:
// generating MRED lists
// guessing of transmission file assignments
//
// - these files may or may not be NCNR-specific. They may eventually 
// need to be moved into NCNR_Utils, or to more appropriate locations
//
//
// 29MAR07 SRK
//


//////////////////////
// "intelligent" differentiation of the data files based on information gathered while
// getting the FIle Catalog. Uses some waves that are generated there, but not displayed in the table
//
// See CatVSTable.ipf for where these files are created (and sorted to keep them together)
////////////

//testing - unused
//
Function/S TextWave2SemiList(textW)
	Wave/T textW
	
	String list=""
	Variable num=numpnts(textW),ii=0
	do
		list += textw[ii] + ";"
		ii+=1
	while(ii<num)
	return(list)
End

Function/S NumWave2CommaList(numW)
	Wave numW
	
	String list=""
	Variable num=numpnts(numW),ii=0
	do
		list += num2Str(numW[ii]) + ","
		ii+=1
	while(ii<num)
	return(list)
End

// utility function to convert a list (string) of semicolon-delimited
//items to a text wave
Function List2TextWave(str,tw)
	String str
	wave/T tw
	
	Variable num=ItemsinList(str,";"),ii=0
	Redimension/N=(num) tw
	do
		tw[ii] = StringFromList(ii, str ,";")
		ii+=1
	while(ii<num)
	return(0)
	
End

// generates a list of the procedure files in the experiment
// putting the results in a wave named "tw", editing and sorting the wave
//
Proc ListIncludedFiles()
	Make/O/T/N=2 tw
	String str=""
	//str = WinList("*", ";","INCLUDE:6")
	str = WinList("*", ";","WIN:128")
	List2TextWave(str,tw)
	Edit tw
	Sort tw tw
End

// returns a comma delimited list of run numbers based on the run numbers collected
// during the building of the File Catalog (why do it twice)
Function/S RunNumberList()

	Wave w= $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	String list=""
	if(WaveExists(w) == 0)
		list = ""
	else
		list=NumWave2CommaList(w)
	endif
	return(list)
End

// list is a comma delimited list of run numbers, from the File Catalog
// - scan through the list and remove numbers that are not transmission files
//
Function/S isTransList(list)
	String list
	
	//scan through the list, find the corresponding point number, and see what isTrans says
	Variable ii,num,temp
	String newList=""
	num=ItemsInList(list ,",")
	for(ii=0;ii<num;ii+=1)
		temp = str2num( StringFromList(ii, list ,",") )
		if(RunNumIsTransFile(temp))
			newList += num2str(temp) + ","
		endif
	endfor
	
	return(newList)
End

//truth if run number is a transmission file
// based on whatever is currently in the File Catalog
//
// Can't use findlevel - it assumes a monotonic RunNumber wave
Function RunNumIsTransFile(num)
	Variable num
	
	Wave isTrans = $"root:myGlobals:CatVSHeaderInfo:IsTrans"
	Wave RunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	
	if( (WaveExists(isTrans) == 0 ) ||  (WaveExists(RunNumber) == 0 ) )
		return(0)
	endif
	
	Variable pts=numpnts(RunNumber),ii
	for(ii=0;ii<pts;ii+=1)
		if(RunNumber[ii] == num)
			return(isTrans[ii])
		endif
	endfor
//	FindLevel/P/Q RunNumber,num
//
//	if(isTrans[V_LevelX]==1)
//		return(1)
//	else
//		return(0)
//	endif
End

//truth if run number is at the given sample to detector distance
// based on whatever is currently in the File Catalog
//
// need fuzzy comparison, since SDD = 1.33 may actually be represented in FP as 1.33000004	!!!
Function RunNumIsAtSDD(num,sdd)
	Variable num,sdd
	
	Wave w = $"root:myGlobals:CatVSHeaderInfo:SDD"
	Wave RunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	
	if( (WaveExists(w) == 0 ) ||  (WaveExists(RunNumber) == 0 ) )
		return(0)
	endif
	Variable pts=numpnts(RunNumber),ii
	for(ii=0;ii<pts;ii+=1)
		if(RunNumber[ii] == num)
			if(abs(w[ii] - sdd) < 0.001	)		//if numerically within 0.001 meter, they're the same
				return(1)
			else
				return(0)
			endif
		endif
	endfor
End


// list is a comma delimited list of run numbers, from the File Catalog
// - scan through the list and remove numbers that are not at the specified SDD
//
Function/S atSDDList(list,sdd)
	String list
	Variable sdd
	
	//scan through the list, find the corresponding point number, and see what SDD the run is at
	Variable ii,num,temp
	String newList=""
	num=ItemsInList(list ,",")
	for(ii=0;ii<num;ii+=1)
		temp = str2num( StringFromList(ii, list ,",") )
		if(RunNumIsAtSDD(temp,sdd))
			newList += num2str(temp) + ","
		endif
	endfor
	
	return(newList)
End

//given a comma-delimited list, remove those that are trans files
//
Function/S removeTrans(list)
	String list
	
	//scan through the list, and remove those that are trans files
	Variable ii,num,temp
//	String newList=""
	num=ItemsInList(list ,",")
	for(ii=0;ii<num;ii+=1)
		temp = str2num( StringFromList(ii, list ,",") )
		if(RunNumIsTransFile(temp))
			list = RemoveFromList(num2str(temp),list,",")
			ii -= 1			//item ii was just deleted (everything moves to fill in)
			num -= 1		// and the list is shorter now
		endif
	endfor
	
	return(list)
End

Function setMREDFileList(str)
	String str
	
	SVAR/Z list = root:myGlobals:MRED:gFileNumList
	if(SVAR_Exists(list)==0)		//check for myself
		DoAlert 0,"The Multiple Reduce Panel must be open for you to use this function"
		Return(1)
	endif
	
	list = str
	
	//force an update If the SVAR exists, then the panel does too - MRED cleans up after itself when done
	DoWindow/F Multiple_Reduce_Panel			//bring to front
	MRedPopMenuProc("MRFilesPopup",0,"")		//parse the list, pop the menu
	
	return(0)
End

Proc FillEMPUsingSelection()
	FillEMPFilenameWSelection()
End

Proc GuessEveryTransFile(num)
	Variable num=6
	GuessAllTransFiles(num)
End

Proc GuessSelectedTransFiles(num)
	Variable num=6
	fGuessSelectedTransFiles(num)
End

Proc ClearSelectedTransAssignments()
	ClearSelectedAssignments()
End

Proc CreateRunNumList()
	String/G rStr=""
	rStr=RunNumberList()
	Print "The list is stored in root:rStr"
	print rStr
End

Proc TransList()
	String/G rStr=""
	rStr=RunNumberList()
	rStr=isTransList(rStr)
	print rStr
End

Proc ScatteringAtSDDList(sdd)
	Variable sdd=13
	
	String/G rStr=""
	rStr=RunNumberList()
	rStr=removeTrans(rStr)
	rStr=atSDDList(rStr,sdd)
	
	//for Igor 4, the search is case-sensitive, so use all permutations
	// in Igor 5, use the proper flag in strsearch() inside FindStringInLabel()
	rStr = RemoveEmptyBlocked(rStr,"EMPTY")
//	rStr = RemoveEmptyBlocked(rStr,"Empty")
//	rStr = RemoveEmptyBlocked(rStr,"empty")
//	rStr = RemoveEmptyBlocked(rStr,"MT Cell")
	rStr = RemoveEmptyBlocked(rStr,"MT CELL")
//	rStr = RemoveEmptyBlocked(rStr,"mt cell")
	rStr = RemoveEmptyBlocked(rStr,"BLOCKED")
//	rStr = RemoveEmptyBlocked(rStr,"Blocked")
//	rStr = RemoveEmptyBlocked(rStr,"blocked")
	
	print rStr
End

Proc FillMREDList()
	setMREDFileList(rStr)
	DoUpdate
End

//num passed in is the run number, as in the list
// ii is the index of all of the files from the catalog
//return will be -1 if string not found, >=0 if found
//
Function FindStringInLabel(num,findThisStr)
	Variable num
	String findThisStr
	
	Wave/T w = $"root:myGlobals:CatVSHeaderInfo:Labels"
	Wave RunNumber = $"root:myGlobals:CatVSHeaderInfo:RunNumber"
	
	if( (WaveExists(w) == 0 ) ||  (WaveExists(RunNumber) == 0 ) )
		return(0)
	endif
	
	Variable pts=numpnts(RunNumber),ii,loc
	for(ii=0;ii<pts;ii+=1)
		if(RunNumber[ii] == num)
//			loc = strsearch(w[ii], findThisStr, 0)			//Igor 4 version is case-sensitive
			loc = strsearch(w[ii], findThisStr, 0 ,2)		//2==case insensitive, but Igor 5 specific
			if(loc != -1)
				Print "Remove w[ii] = ",num,"  ",w[ii]
			endif
		endif
	endfor
	
	return(loc)		//return will be -1 if string not found, >=0 if found
end

//rStr is the global string, already atSDD (so there should be only one instance of
// empty and one instance of blocked
//
//scan through the list, and remove those that are have "empty" or "blocked" in the label
// or anything that is listed in StrToFind
//
Function/S RemoveEmptyBlocked(list,StrToFind)
	String list,StrToFind
	
	Variable ii,num,temp
	num=ItemsInList(list ,",")
	for(ii=0;ii<num;ii+=1)
		temp = str2num( StringFromList(ii, list ,",") )
		if(FindStringInLabel(temp,StrToFind) != -1)
			list = RemoveFromList(num2str(temp),list,",")
			ii -= 1			//item ii was just deleted (everything moves to fill in)
			num -= 1		// and the list is shorter now
		endif
	endfor
	//print list
	return(list)
end

// input is a single run number to remove from the list
//  - typically EC and BN - before sending to MRED
Proc RemoveRunFromList(remList)
	String remList=""
	 
	rStr = RemoveFromList(remList, rStr ,",")
end


//////////general folder utilities

//prompts user to choose the local folder that contains the SANS Data
//only one folder can be used, and its path is catPathName (and is a NAME, not a string)
//this will overwrite the path selection
//returns 1 if no path selected as error condition, or if user cancelled
Function PickPath()
	
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
		String/G root:myGlobals:gCatPathStr = "no folder selected"
		return(1)
	else
		//set the global to the path (as a string)
		// need 4 \ since it is the escape character
		if(cmpstr("\\\\",dum[0,1])==0)	//Windoze user going through network neighborhood
			DoAlert 0,alertStr
			KillPath catPathName
			return(1)
		endif
		String/G root:myGlobals:gCatPathStr = dum
		// these are now set in theire respective procedures, since the folders don't exist yet!
//		String/G root:myGlobals:Patch:gCatPathStr = dum	//and the global used by Patch and Trans
//		String/G root:myGlobals:TransHeaderInfo:gCatPathStr = dum	//and the global used by Patch and Trans
		return(0)		//no error
	endif
End

//a utility function that prompts the user for a file (of any type)
//and returns the full path:name;vers string required to open the file
//the file is NOT opened by this routine (/D flag)
//a null string is returned if no file is selected
//"msgStr" is the message displayed in the dialog, informing the user what
//file is desired
//
Function/S PromptForPath(msgStr)
	String msgStr
	String fullPath
	Variable refnum
	
	//this just asks for the filename, doesn't open the file
	Open/D/R/T="????"/M=(msgStr) refNum
	fullPath = S_FileName		//fname is the full path
	//	Print refnum,fullPath
	
	//null string is returned in S_FileName if user cancelled, and is passed back to calling  function
	Return(fullPath)
End



//procedure is not called from anywhere, for debugging purposes only
//not for gerneral users, since it Kills data folders, requiring
//re-initialization of the experiment
//
Proc ClearWorkFolders()

	//not foolproof - will generage an error if any wavs, etc.. are in use.
	KillDataFolder root:RAW
	KillDataFolder root:SAM
	KillDataFolder root:EMP
	KillDataFolder root:BGD
	KillDataFolder root:COR
	KillDataFolder root:DIV
	KillDataFolder root:MSK
	KillDataFolder root:ABS
	KillDataFolder root:CAL
	SetDataFolder root:
	
End

//not used - but potentially very useful for ensuring that old
// data in work folders is not accidentally being used
//
Function ClearWorkFolder(type)
	String type
	
	SetDataFolder $("root:"+type)
	KillWaves/A/Z
	KillStrings/A/Z
	KillVariables/A/Z
	
	SetDataFolder root:
End


//procedure is not called from anywhere, for debugging purposes only
//not for gerneral users, but could be useful in reducon clutter
//
Proc ClearRootFolder()

	DoAlert 1,"Are you sure you want to delete everything from the root level?"
	SetDataFolder root:
	KillWaves/A/Z
	KillStrings/A/Z
	KillVariables/A/Z
	
End

/////////string matching


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
Function/S MyMatchList(matchStr,list,sep)
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
		if( MyStrMatch(matchStr,item) == 0 )
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
Function MyStrMatch(matchStr,str)
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