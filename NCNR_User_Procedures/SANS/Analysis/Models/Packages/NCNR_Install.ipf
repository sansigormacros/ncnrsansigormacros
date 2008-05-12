#pragma rtGlobals=1		// Use modern global access method.

// Install the NCNR Macros

//InstallNCNRMacros() // run this function when experiment is loaded
//InstallerPanel() // run this function when experiment is loaded

//
// package-6.001
//


Function InstallNCNRMacros()

	//first step, check for Igor 6!!!
	if(NumberByKey("IGORVERS", IgorInfo(0)) < 6)
		Abort "You must be running Igor 6 or later to use these macros."
	endif
	
	
	// check to see if the installer has already been run... if so, the folders will be gone... stop now BEFORE removing things
	String test = IndexedDir(home, -1, 0)	
	if(stringmatch(test, "*NCNR_User_Procedures*") == 0)
		print test
		Abort "You've already run the installer. If you want to re-install, you'll need a fresh copy from the NCNR website."
	endif
	
	// check the platform
	Variable isMac=0
	if(cmpstr("Macintosh",IgorInfo(2))==0)
		isMac=1
	endif
	
	String igorPathStr,homePathStr
	PathInfo Igor
	igorPathStr = S_Path		//these have trailing colons
	PathInfo home					//the location where this was run from...
	homePathStr = S_Path
	
	// clean up old stuff, moving to home:old_moved_files
	// extensions - these show up as files, even the aliases
	// help files - these are files
	// user procedures - these can be in folders or as files
	variable i=0, AliasSet=0, isThere = 0
	String tmpStr
	
// clean up the Igor Extensions
	NewPath /Q/O ExPath, igorPathStr+"Igor Extensions:"
	PathInfo ExPath
	String extPathStr = S_Path 
	string strFileList = IndexedFile(ExPath, -1, "????" )
	
	Wave/T extFiles=root:IExtFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFiles)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFile/O/P=ExPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
		endif
	endfor
	
	//then anything that shows up as a folder
	Wave/T extFolders=root:IExtFolders
	strFileList = IndexedDir(ExPath, -1, 0 )
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFolders)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFolder extPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
		endif
	endfor
	
// clean up the user procedures (files first)
	NewPath /Q/O UPPath, igorPathStr+"User Procedures:"
	PathInfo UPPath
	String UPPathStr = S_Path
	strFileList = IndexedFile(UPPath, -1, "????" )			//for files
	
	Wave/T UPFilesWave=root:UPFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFilesWave)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFile/O/P=UPPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
		endif
	endfor
	
// clean up the user procedures (folders second)
	strFileList = IndexedDir(UPPath, -1, 0)			//for folders, just the names, not full paths
	
	Wave/T UPFoldersWave=root:UPFolders
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFoldersWave)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFolder UPPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
		endif
	endfor

// clean up the Igor help files
	NewPath /Q/O IHPath, igorPathStr+"Igor Help Files:"
	PathInfo IHPath
	String IHPathStr = S_Path
	strFileList = IndexedFile(IHPath, -1, "????" )			//for files
	
	Wave/T IHFilesWave=root:IHFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFilesWave)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFile/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
		endif
	endfor	
	
	// then anything that shows up as a folder
	Wave/T IHFilesWave=root:IHFolders
	strFileList = IndexedDir(IHPath, -1, 0)	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFolders)
		if(isThere)
			Print "Move "+ tmpStr
			MoveFolder IHPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
		endif
	endfor
	
// INSTALL the new stuff
//(1) copy the items to install to the User Procedures folder
//(2) set up the aliases from there
//
// the old ones should be gone already, so just put in the new ones
//  and then create shortcuts for XOP and help files
	MoveFolder homePathStr+"NCNR_Help_Files" as UPPathStr+"NCNR_Help_Files"
	CreateAliasShortcut/O/P=UPPath "NCNR_Help_Files" as igorPathStr+"Igor Help Files:NCNR_Help_Files"
	
	MoveFolder homePathStr+"NCNR_User_Procedures" as UPPathStr+"NCNR_User_Procedures"
	// don't need an alias for the UserProcedures - they're already here....

	MoveFolder homePathStr+"NCNR_Extensions" as UPPathStr+"NCNR_Extensions"
	if(isMac)
		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Mac_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
	else
		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Win_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
	endif
	

// put shortcuts to the template in the "top" folder
//??
	NewPath/O/Q UtilPath, homePathStr+"NCNR_SANS_Utilities:"
	strFileList = IndexedFile(UtilPath,-1,".pxt")	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
//		isThere = CheckForMatch(tmpStr,IHFolders)
//		if(isThere)
//			Print "Move "+ tmpStr
//			MoveFolder/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			CreateAliasShortcut/O/P=UtilPath tmpStr as homePathStr +tmpStr
//		endif
	endfor
	
// old method, used shortcuts from main package (risky if user deletes them)
//	CreateAliasShortcut/O/P=home "NCNR_Help_Files" as igorPathStr+"Igor Help Files:NCNR_Help_Files"
//	CreateAliasShortcut/O/P=home "NCNR_User_Procedures" as igorPathStr+"User Procedures:NCNR_User_Procedures"
//	if(isMac)
//		CreateAliasShortcut/O/P=home "NCNR_Extensions:Mac XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	else
//		CreateAliasShortcut/O/P=home "NCNR_Extensions:Win XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	endif
	

// installation is done, quit to start fresh
	doAlert 1, "Quit Igor to complete installation.\rQuit now? "
	if (V_Flag==1)
		execute "Quit /Y"
	endif
	
	return 1
End

// return (1) if str is an entry in tw
// must be an exact match, with or without ".lnk" extension
//
Function CheckForMatch(str,tw)
	String str
	Wave/T tw
	
	Variable num=numpnts(tw),ii=0
	
	do
		if(cmpstr(str,tw[ii])==0 || cmpstr(str+".lnk",tw[ii])==0)
			return (1)
		endif
		ii+=1
	while(ii<num)
	
	return(0)
End


Function InstallButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			InstallNCNRMacros()
			break
	endswitch

	return 0
End

Function UpdateCheckButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "CheckForLatestVersion()"
			break
	endswitch

	return 0
End

Function DiagnosticsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			InstallDiagnostics()
			break
	endswitch

	return 0
End

Window InstallerPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(150,50,445,292)	/K=2
	Button button0,pos={73,24},size={150,40},proc=InstallButtonProc,title="Install SANS Macros"
	Button button0,fColor=(1,26214,0)
	Button button0_1,pos={75,94},size={150,40},proc=UpdateCheckButtonProc,title="Check for Updates"
	Button button0_1,fColor=(1,26221,39321)
	Button button0_2,pos={75,164},size={150,40},proc=DiagnosticsProc,title="Print Diagnostics"
	Button button0_2,fColor=(65535,0,0)
EndMacro

// generate a notebook with install diagnostics suitable for e-mail
Function InstallDiagnostics()
	
	String nb="Install_Diagnostics_v6",textStr
	
	DoWindow/F $nb
	if(V_flag==0)
		NewNotebook/N=$nb/F=0 /W=(387,44,995,686) as nb
	else
		//clear contents
		Notebook $nb selection={startOfFile, endOfFile}	
		Notebook $nb text="\r"
	endif	
	
// what version, what platform
	Notebook $nb text="**Install Diagnostics**\r\r"
	Notebook $nb text="**Version / Platform**\r"
	textStr =  IgorInfo(0)+"\r"
	Notebook $nb text=textStr
	textStr =  IgorInfo(2)+"\r"
	Notebook $nb text=textStr
// what is the currently installed version from the string
	PathInfo Igor
	String IgorPathStr = S_Path
	String fileNameStr = IgorPathStr + "User Procedures:NCNR_User_Procedures:InstalledVersion.txt"
	String installedStr
	Variable refnum
	
	Open/R/Z refNum as fileNameStr
	if(V_flag != 0)
		//couldn't find the file
		textstr = "I could not determine what version of the SANS Macros you are running."
	else
		FReadLine refNum, installedStr
		Close refnum
		textStr = installedStr
	endif
	
	Notebook $nb text="\r\r**InstalledVersion.txt**\r"
	Notebook $nb text=textStr +"\r"

// get listings of everything in each folder
	string strfileList=""

// what is the listing of the Igor Extensions
	Notebook $nb text="\r\r**Igor Extensions (files)**\r"
	NewPath /Q/O ExPath, igorPathStr+"Igor Extensions:"
	
	//files
	strFileList = IndexedFile(ExPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Extensions (folders)**\r"
	strFileList = IndexedDir(ExPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"


// what is the listing of Igor Help files
	Notebook $nb text="\r\r**Igor Help (files)**\r"
	NewPath /Q/O IHPath, igorPathStr+"Igor Help Files:"

	//files
	strFileList = IndexedFile(IHPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Help (folders)**\r"
	strFileList = IndexedDir(IHPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
	
// what is the listing of the User Procedures
	Notebook $nb text="\r\r**User Procedures (files)**\r"
	NewPath /Q/O UPPath, igorPathStr+"User Procedures:"
	//files
	strFileList = IndexedFile(UPPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**User Procedures (folders)**\r"
	strFileList = IndexedDir(UPPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
// what is the listing of the Igor Procedures

//  generating a path for this seems to be problematic - since it can't be killed , or found on another computer
// that is (apparently) because if there is anything included from the IgP folder (and there is on even the default installation)
// - then the path is "in use" and can't be killed...
//
	Notebook $nb text="\r\r**Igor Procedures (files)**\r"
	NewPath /Q/O IgorProcPath, igorPathStr+"Igor Procedures:"

	//files
	strFileList = IndexedFile(IgorProcPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Procedures (folders)**\r"
	strFileList = IndexedDir(IgorProcPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"


	//move to the beginning of the notebook
	Notebook $nb selection={startOfFile, startOfFile}	
	Notebook $nb text=""
	
	return(0)
End