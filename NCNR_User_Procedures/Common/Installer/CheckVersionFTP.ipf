#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
//
// updated Jan 2021 to use github for the current version and to
// (hopefully) do a better job of keeping track of the current installed version
//
// https://github.com/sansigormacros/ncnrsansigormacros/wiki/Current-Release-Version-Number
//

Function getReleaseVersion()
	URLRequest url="https://github.com/sansigormacros/ncnrsansigormacros/wiki/Current-Release-Version-Number"
	String str=S_ServerResponse
	Variable loc=Strsearch(str,"version==",0)
//	Print str[loc,loc+20]
	
	str = str[loc,loc+20]		//trim the large response to a short string
	
	Variable version=0 
	version = NumberByKey("version",str,"==")
//	Print version
	
	return(version)
End

//
// get the current version from GitHub and compare to any local value
//
//
//
Proc CheckForLatestVersion()

	String currentStr,installedStr,fileNameStr="",varStr="",str
	Variable refNum,upToDateVersion,runningVersion
	
	
	uptoDateVersion = getReleaseVersion()		//get this from GitHub
	
//	
//	fileNameStr = SpecialDirPath("Packages", 0, 0, 0)
//	fileNameStr += "CurrentVersion.txt"
//
//	FTPDownload/O/Z/V=7/T=1 url, fileNameStr
//
//	Open/R refNum as fileNameStr
//	FReadLine refNum, currentStr
//	Close refnum
//	
//	Print "Current = ",CurrentStr
//	// don't use the local strings anymore	
////	setDataFolder root:
////	varStr=VariableList("*VERSION",";",6)
////	if(strlen(varStr)==0)
////		SetDataFolder root:Packages:NIST:
////		varStr=VariableList("*VERSION",";",6)
////	endif
////	if(strlen(varStr)==0)
////		Abort "Can't find the local version number"
////	Endif
	
	// find the installed version
	PathInfo Igor
	String IgorPathStr = S_Path
	fileNameStr = IgorPathStr + "User Procedures:NCNR_User_Procedures:InstalledVersion.txt"
	
	// the Igor 6.1 User Procedure Path, same sub-folders as in Igor App Folder
	String userPathStr=RemoveEnding(SpecialDirPath("Igor Pro User Files",0,0,0),":")+":"
	
	// try the UP folder in the Igor Pro folder (older installations)
	Open/R/Z refNum as fileNameStr
	if(V_flag != 0)
		//then try the special user directory (for 6.1+ installations)
		Open/R/Z refNum as userPathStr + "User Procedures:NCNR_User_Procedures:InstalledVersion.txt"
		if(V_flag != 0)
			//couldn't find the file, send user to web site to update
			sprintf str,"I could not determine what version of the SANS Macros you are running."
//			str += " You need to go to the NCNR website for the latest version. Do you want to go there now?"
			str += " You need to go to the SANS GitHub website for the latest version. Do you want to go there now?"
			DoAlert 1,str
			if(V_flag==1)
//				BrowseURL "http://www.ncnr.nist.gov/programs/sans/data/red_anal.html"
//				BrowseURL "http://danse.chem.utk.edu/trac/wiki"
				BrowseURL "https://github.com/sansigormacros/ncnrsansigormacros/releases/latest"
			endif
			//don't need to close if nothing was opened (/Z)
			
			return		//couldn't find either file, nothing opened, exit
		endif
	endif
	
	// the file was opened, check the version
	FReadLine refNum, installedStr
	Close refnum
	
	Print "Installed = ",installedStr	
	
	runningVersion = NumberByKey(StringFromList(0,"PACKAGE_VERSION"), installedStr,"=",";")
//	upToDateVersion = NumberByKey(StringFromList(0,"PACKAGE_VERSION"), currentStr,"=",";")
	
	If(runningVersion < upToDateVersion)
		sprintf str,"You are running version %g and the latest version is %g.",runningVersion,upToDateVersion
//		str += " You need to go to the NCNR website for the latest version. Do you want to go there now?"
//		str += " You need to go to the SANS Trac website for the latest version. Do you want to go there now?"
		str += " You need to go to the SANS GitHub website for the latest version. Do you want to go there now?"

		DoAlert 1,str
		if(V_flag==1)
//			BrowseURL "http://www.ncnr.nist.gov/programs/sans/data/red_anal.html"
//			BrowseURL "http://danse.chem.utk.edu/trac/wiki"
			BrowseURL "https://github.com/sansigormacros/ncnrsansigormacros/releases/latest"

		endif
	else
		if(runningVersion == upToDateVersion)
			DoAlert 0,"You are running the most up-to-date version = "+num2str(upToDateVersion)
		else
		sprintf str,"You are running version %g and the latest version is %g.",runningVersion,upToDateVersion
		str += "\r\rYou must be from the future."
		DoAlert 1,str
		endif

	endif
	
	return
End

Function OpenTracTicketPage()
//	DoAlert 1,"Your web browser will open to a page where you can submit your bug report or feature request. OK?"
//	if(V_flag==1)
//		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
//	endif
	String str = "Your web browser will open to the NCNR software page. "
	str += "At the bottom of the page there is contact information for where you can submit your bug report or feature request."
	DoAlert 1,str
	if(V_flag==1)
//		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
		BrowseURL "https://www.nist.gov/ncnr/data-reduction-analysis/sans-software"
	endif
End

Function OpenHelpMoviePage()
	DoAlert 1,"Your web browser will open to a page where you can view help movies. OK?"
	if(V_flag==1)
//		BrowseURL "ftp://webster.ncnr.nist.gov/pub/sans/kline/movies/"
		// Andrew has set up a (depricated) http page. in the future, link to NISTube (once I get permission/ERB approval)
		BrowseURL "https://www.nist.gov/ncnr/sans-usans-reduction-video-tutorials"
	endif
End

