#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1



///
// ***********
// it may be prefereable to COPY the files to the UP folder, so that the installer doesn't "eat" itself 
// and require users to re-download if they do something wrong. the difficulty with CopyFolder is that
// on Windows it does a "mix-in" copy, rather than a delete/overwrite all. So it may be better to just leave
// the installer as is, requiring a fresh copy each time. SRK 10MAR09
//
//
///

// Install the NCNR Macros

//InstallNCNRMacros() // run this function when experiment is loaded
//InstallerPanel() // run this function when experiment is loaded

//
// package-6.001
// - lots more diagnostics added

// FEB 2010 - now make use of the user-specific procedure path. It's always writeable, and not in the application folder
//
// since old material may be installed, and permission may be gone:
// - check for permission
// - check for old material installed in Igor Pro/
// -- if nothing installed in Igor Pro/, then permissions are not a problem
// -- install in the new uer-specific path as intended
//
// -- now I need to search both locations to move old stuff out
// -- then install clean into the new user path (userPathStr)
//
// ** The NCNR_Package_Loader is now installed in the Igor Procedures folder so that the package can be loaded at any time
//    improving compatibility with Jan Ilavsky's package
//

Function InstallNCNRMacros(forceInstall)
	Variable forceInstall		// if == 1, install whatever possible, even if R/W errors from the OS

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
	
	// check for install problems
	// locked folders, OS errors _err will be non-zero if there is an error
	Variable UP_err,IH_err,IE_err
	UP_err = FolderPermissionCheck("User Procedures:")
	IH_err = FolderPermissionCheck("Igor Help Files:")
	IE_err = FolderPermissionCheck("Igor Extensions:")	
//	Print UP_err,IH_err,IE_err

	String alertStr=""
	if(UP_err != 0)
		alertStr += "User Procedures has no write permission.\r"
	endif
	if(IH_err != 0)
		alertStr += "Igor Help Files has no write permission.\r"
	endif
	if(IE_err != 0)
		alertStr += "Igor Extensions has no write permission.\r"
	endif

/// SRK - 2010 - errors are not used here. instead, errors are caught if a file or folder move fails. If there
// is nothing to move out, or it moves out OK, then permissions don't matter.
	
//	if(forceInstall == 0)
//		if(UP_err != 0 || IH_err != 0 || IE_err != 0)
//			alertStr += "You will need to install manually."
//			DoAlert 0,alertStr
//			return(0)
//		endif
//	endif
	
	
	// check the platform
	Variable isMac=0
	if(cmpstr("Macintosh",IgorInfo(2))==0)
		isMac=1
	endif
	

	String igorPathStr,homePathStr,userPathStr
	PathInfo Igor
	igorPathStr = S_Path		//these have trailing colons
	PathInfo home					//the location where this was run from...
	homePathStr = S_Path
	// the Igor 6.1 User Procedure Path, same sub-folders as in Igor App Folder
	userPathStr=RemoveEnding(SpecialDirPath("Igor Pro User Files",0,0,0),":")+":"
	
	// clean up old stuff, moving to home:old_moved_files
	// extensions - these show up as files, even the aliases
	// help files - these are files
	// user procedures - these can be in folders or as files
	variable i=0, AliasSet=0, isThere = 0
	String tmpStr


//////////////////////////////////////////////////////////////////////
	
////// clean up the Igor Extensions (first the old path -- in the App folder)
	NewPath /Q/O ExPath, igorPathStr+"Igor Extensions:"
	PathInfo ExPath
	String extPathStr = S_Path 
	string strFileList = IndexedFile(ExPath, -1, "????" )
	
	//files first
	Wave/T extFiles=root:IExtFiles
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFiles)
		if(isThere)
			MoveFile/O/P=ExPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor
	
	//then anything that shows up as a folder
	Wave/T extFolders=root:IExtFolders
	strFileList = IndexedDir(ExPath, -1, 0 )
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFolders)
		if(isThere)
			MoveFolder extPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor

////// then clean up the Igor Extensions (now look in the User Path, by changing the definition of ExPath)
	NewPath /Q/O ExPath, userPathStr+"Igor Extensions:"
	PathInfo ExPath
	extPathStr = S_Path 
	strFileList = IndexedFile(ExPath, -1, "????" )
		
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFiles)
		if(isThere)
			MoveFile/O/P=ExPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor
	
	//then anything that shows up as a folder
	strFileList = IndexedDir(ExPath, -1, 0 )
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFolders)
		if(isThere)
			MoveFolder extPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor

//////////////////////////////////////////////////////////////////////
	
/////// clean up the User Procedures -- in the APP folder
	NewPath /Q/O UPPath, igorPathStr+"User Procedures:"
	PathInfo UPPath
	String UPPathStr = S_Path
	strFileList = IndexedFile(UPPath, -1, "????" )			//for files
	
	// (files first)
	Wave/T UPFilesWave=root:UPFiles
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFilesWave)
		if(isThere)
			MoveFile/O/P=UPPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from User Procedures: "+IsMoveOK(V_flag)
		endif
	endfor
	
	//(folders second)
	strFileList = IndexedDir(UPPath, -1, 0)			//for folders, just the names, not full paths
	Wave/T UPFoldersWave=root:UPFolders
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFoldersWave)
		if(isThere)
		// THIS is the problem, when NCNR_Help_Files is moved - it is in use
			MoveFolder/Z UPPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from User Procedures: "+IsMoveOK(V_flag)
		endif
	endfor

/////// now clean up the User Procedures -- in the User Folder
	NewPath /Q/O UPPath, userPathStr+"User Procedures:"
	PathInfo UPPath
	UPPathStr = S_Path
	strFileList = IndexedFile(UPPath, -1, "????" )			//for files
	
	// (files first)
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFilesWave)
		if(isThere)
			MoveFile/O/P=UPPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from User Procedures: "+IsMoveOK(V_flag)
		endif
	endfor
	
	//(folders second)
	strFileList = IndexedDir(UPPath, -1, 0)			//for folders, just the names, not full paths
		
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFoldersWave)
		if(isThere)
		// THIS is the problem, when NCNR_Help_Files is moved - it is in use
			MoveFolder/Z UPPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from User Procedures: "+IsMoveOK(V_flag)
		endif
	endfor


//////////////////////////////////////////////////////////////////////



/////// now try to clean up the Igor Help Files (in the APP folder)
	NewPath /Q/O IHPath, igorPathStr+"Igor Help Files:"
	PathInfo IHPath
	String IHPathStr = S_Path
	strFileList = IndexedFile(IHPath, -1, "????" )			//for files
	
	// files first
	Wave/T IHFilesWave=root:IHFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFilesWave)
		if(isThere)
			MoveFile/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Help Files: "+IsMoveOK(V_flag)
		endif
	endfor	
	
	// then anything that shows up as a folder
	Wave/T IHFilesWave=root:IHFolders
	strFileList = IndexedDir(IHPath, -1, 0)	
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFolders)
		if(isThere)
			MoveFolder IHPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Help Files: "+IsMoveOK(V_flag)
		endif
	endfor
	
	/////// now try the Igor Help Files (in the USER folder)
	NewPath /Q/O IHPath, userPathStr+"Igor Help Files:"
	PathInfo IHPath
	IHPathStr = S_Path
	strFileList = IndexedFile(IHPath, -1, "????" )			//for files
	
	// files first	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFilesWave)
		if(isThere)
			MoveFile/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Help Files: "+IsMoveOK(V_flag)
		endif
	endfor	
	
	// then anything that shows up as a folder
	strFileList = IndexedDir(IHPath, -1, 0)	
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFolders)
		if(isThere)
			MoveFolder IHPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Help Files: "+IsMoveOK(V_flag)
		endif
	endfor

///////////////////
////// clean up the Igor Procedures (first the old path -- in the App folder, likely empty)
	NewPath /Q/O IgProcPath, igorPathStr+"Igor Procedures:"
	PathInfo IgProcPath
	String IgProcPathStr = S_Path 
	strFileList = IndexedFile(IgProcPath, -1, "????" )
	
	//files first
	Wave/T IgProcFiles=root:IgProcFiles
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IgProcFiles)
		if(isThere)
			MoveFile/O/P=IgProcPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Procedures: "+IsMoveOK(V_flag)
		endif
	endfor
	
	//then anything that shows up as a folder (don't bother with this)
	Wave/T IgProcFolders=root:IgProcFolders
	
	strFileList = IndexedDir(IgProcPath, -1, 0 )
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IgProcFolders)
		if(isThere)
			MoveFolder IgProcPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor

////// then clean up the Igor Procedures (now look in the User Path, by changing the definition of IgProcPath)
	NewPath /Q/O IgProcPath, userPathStr+"Igor Procedures:"
	PathInfo IgProcPath
	IgProcPathStr = S_Path 
	strFileList = IndexedFile(IgProcPath, -1, "????" )
		
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IgProcFiles)
		if(isThere)
			MoveFile/O/P=IgProcPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Procedures: "+IsMoveOK(V_flag)
		endif
	endfor

	//then anything that shows up as a folder
	strFileList = IndexedDir(IgProcPath, -1, 0 )
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IgProcFolders)
		if(isThere)
			MoveFolder IgProcPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Extensions: "+IsMoveOK(V_flag)
		endif
	endfor

//////////////////////////////////////////////////////////////////////
	

// at this point all of the old stuff is cleaned up as best as I can
//
// at this point the paths point to the User Folder, not in the App folder	
	
	
	
	
//////////// INSTALL the new stuff
//
//(1) copy the items to install to the User Special Folder
//(2) --- now I don't need to set up aliases! they are just there
//
// the old ones should be gone already, so just put in the new ones

// they may not be possible to remove, so try to overwrite...

	NewPath /Q/O SpecialPath, userPathStr

// the help files
	MoveFolder/Z=1 homePathStr+"NCNR_Help_Files" as IHPathStr+"NCNR_Help_Files"
	Print "******Move folder NCNR_Help_Files into User Special Folder, NO overwite: "+IsMoveOK(V_flag)

// not needed now
//	CreateAliasShortcut/O/P=SpecialPath "NCNR_Help_Files" as igorPathStr+"Igor Help Files:NCNR_Help_Files"
//	Print "Creating shortcut from NCNR_Help_Files into Igor Help Files: "+IsMoveOK(V_flag)

// the Igor Procedures
	MoveFolder/Z=1 homePathStr+"NCNR_Igor_Procedures" as IgProcPathStr+"NCNR_Igor_Procedures"
	Print "*******Move folder NCNR_Igor_Procedures into User Special Folder, NO overwrite: "+IsMoveOK(V_flag)

// the User Procedures	
	MoveFolder/Z=1 homePathStr+"NCNR_User_Procedures" as UPPathStr+"NCNR_User_Procedures"
	Print "*******Move folder NCNR_User_Procedures into User Special Folder, NO overwrite: "+IsMoveOK(V_flag)
	
// don't need an alias for the UserProcedures - they're already here....


// Igor Extensions, platform-specific
	if(isMac)
		MoveFolder/Z=1 homePathStr+"NCNR_Extensions:Mac_XOP" as extPathStr+"NCNR_Extensions"
	else
		MoveFolder/Z=1 homePathStr+"NCNR_Extensions:Win_XOP" as extPathStr+"NCNR_Extensions"
	endif
	Print "*******Move folder NCNR_Extensions:xxx_XOP into User Special Folder, NO overwrite: "+IsMoveOK(V_flag)
//	
// not needed now
//	if(isMac)
//		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Mac_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	else
//		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Win_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	endif
//	Print "Creating shortcut for XOP into Igor Extensions: "+IsMoveOK(V_flag)
	

// put shortcuts to the template in the "top" folder
//
	NewPath/O/Q UtilPath, homePathStr+"NCNR_SANS_Utilities:"
	strFileList = IndexedFile(UtilPath,-1,".pxt")	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
//		isThere = CheckForMatch(tmpStr,IHFolders)
//		if(isThere)
//			Print "Move "+ tmpStr
//			MoveFolder/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			CreateAliasShortcut/O/P=UtilPath tmpStr as homePathStr +tmpStr
			Print "Creating shortcut for "+tmpStr+" into top level: "+IsMoveOK(V_flag)
//		endif
	endfor


// installation is done, quit to start fresh
	DoAlert 1, "Quit Igor to complete installation.\rQuit now? "
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
		if(cmpstr(str,tw[ii])==0 || cmpstr(str,tw[ii]+".lnk")==0)
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
			InstallNCNRMacros(0)
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
	
	// check for permissions
	Variable UP_err,IH_err,IE_err
	UP_err = FolderPermissionCheck("User Procedures:")
	IH_err = FolderPermissionCheck("Igor Help Files:")
	IE_err = FolderPermissionCheck("Igor Extensions:")
	
	Print UP_err,IH_err,IE_err
	
	String alertStr=""
	if(UP_err != 0)
		alertStr += "User Procedures has no write permission. Error = "+num2Str(UP_err)+"\r"
	else
		alertStr += "User Procedures permission is OK.\r"
	endif
	if(IH_err != 0)
		alertStr += "Igor Help Files has no write permission. Error = "+num2Str(IH_err)+"\r"
	else
		alertStr += "Igor Help Files permission is OK.\r"
	endif
	if(IE_err != 0)
		alertStr += "Igor Extensions has no write permission. Error = "+num2Str(IE_err)+"\r"
	else
		alertStr += "Igor Extensions permission is OK.\r"
	endif
	
	if(UP_err != 0 || IH_err != 0 || IE_err != 0)
		alertStr += "You will need to install manually."
	endif
	
	Notebook $nb text="\r\r**Folder Permissions**\r"
	Notebook $nb text=AlertStr +"\r"
	
	
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
//
//
	// then get a listing of the "home" directory. If files were not moved properly, they will still be here
	Notebook $nb text="\r\r**Home (files)**\r"
//	NewPath /Q/O IgorProcPath, igorPathStr+"Igor Procedures:"

	//files
	strFileList = IndexedFile(home, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Home (folders)**\r"
	strFileList = IndexedDir(home, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
	//move to the beginning of the notebook
	Notebook $nb selection={startOfFile, startOfFile}	
	Notebook $nb text=""
	
	return(0)
End

Function AskUserToKillHelp()

	//// clean up the Igor help files
// first, kill any open help files
// there are 5 of them
	Variable numHelpFilesOpen=0
//	do
		numHelpFilesOpen = 0
		// V_flag is set to zero if it's found, non-zero (unspecified value?) if it's not found
		DisplayHelpTopic/Z "Beta SANS Tools"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
		
		DisplayHelpTopic/Z "SANS Data Analysis Documentation"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "SANS Model Function Documentation"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "SANS Data Reduction Tutorial"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "USANS Data Reduction"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
			
//		PauseForUser		// can't use this, it keeps you from interacting with anything....
//	while(NumHelpFilesOpen != 0)
	DoWindow HelpNotebook
	if(V_flag)
		DoWindow/K HelpNotebook
	endif
	
	String helpStr = "Please kill the open Help Files by holding down the OPTION key (Macintosh) or ALT key (Windows) and then CLICKING on the close box of each help window."
	helpStr += " Once you have finished, please close this window and install the SANS Macros."
	if(NumHelpFilesOpen != 0)
		NewNotebook/F=1/K=1/N=HelpNotebook /W=(5,44,547,380) as "Please close the open help files"
		Notebook HelpNotebook,fsize=18,fstyle=1,showRuler=0,text=helpStr
		return(0)
	endif

	return(0)
End

//check each of the three folders
// folder string MUST have the trailing colon
Function FolderPermissionCheck(folderStr)
	String folderStr
	Variable refnum
	String str="delete me"
	
	String igorPathStr,resultStr=""
	PathInfo Igor
	igorPathStr = S_Path
	
	NewPath /Q/O tmpPath, igorPathStr+folderStr

	
	Open/Z/P=tmpPath refnum as "test.txt"
	if(V_flag != 0)
		return(V_flag)
	else
		FBinWrite refnum,str
		Close refnum
		
//		Print "folder OK"
		DeleteFile/Z/P=tmpPath  "test.txt"
	endif
	
	
	return(V_flag)
end

Function/S IsMoveOK(flag)
	Variable flag
	
	String alertStr="There are old NCNR procedures and files present. You will need admin privileges to manually remove them before you can continue"
	if(flag == 0)
		return(" OK")
	else
		DoAlert 0,alertStr
		return(" ERROR")
	endif
end

//// this will "force" an install, even if there are R/W errors
//Macro ForceInstall()
//
//	Execute "InstallNCNRMacros(1)"
//end