#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.00
#pragma IgorVersion=6.0

// This is to be used with the Analysis packages ONLY
// there are a number of utility procedures here for loading
// data and generating valid lists of data files that are
// directly copied from the Reduction package
// -- There WILL be name conflicts if you mix the two...
//
// 16 DEC 05 SRK
// prepended function names with A_ to tag them for the 
// "A"nalysis parckage, though nearly all are duplicate procedures
// so there will be no overlap with the reduction package
//
//
// these extra procedures are used by:
// Linearized fits (duplicated in Reduction - will need to handle gently)
// Invariant (no overlap with reduction)
//
// SRK MAR 2005

// create a KW=string; of model=coef correspondence as the models are plotted, rather than
// some other hard-wired solution
Function AddModelToStrings(funcStr,coefStr,suffix)
	String funcStr,coefStr,suffix
	
	if(exists("root:Packages:NIST:coefKWStr")==0)
		String/G root:Packages:NIST:coefKWStr=""
		String/G root:Packages:NIST:suffixKWStr=""
	endif
	SVAR coefKWStr = root:Packages:NIST:coefKWStr
	SVAR suffixKWStr = root:Packages:NIST:suffixKWStr
	coefKWStr += funcStr+"="+coefStr+";"
	suffixKWStr += coefStr+"="+suffix+";"
end

// loads a 1-d (ascii) datafile and plots the data
// will overwrite existing data if user is OK with this
// - multiple datasets can be automatically plotted on the same graph
//
//substantially easier to write this as a Proc rather than a function...

//
Proc A_LoadOneDData()
	A_LoadOneDDataWithName("",1)		//will prompt for file and plot data
End

// load the data specified by fileStr (a full path:name)
// and plots if doPlot==1
// if fileStr is null, a dialog is presented to select the file
//
// 3 cases (if)
// - 3 columns = QIS, no resolution
// - 6 columns = QSIG, SANS w/resolution
// - 5 columns = old-style desmeared USANS data (from VAX)
//
// This loader replaces the A_LoadOneDData() which was almost completely duplicated code
//
//new version, 19JUN07 that loads each data set into a separate data folder
// the data folder is given the "base name" of the data file as it's loaded
//
Proc A_LoadOneDDataWithName(fileStr,doPlot)
	String fileStr
	Variable doPlot
	
	Variable rr,gg,bb
	String w0,w1,w2,n0,n1,n2
	String w3,w4,w5,n3,n4,n5			//3 extra waves to load
	SetDataFolder root:		//build sub-folders for each data set under root
	Variable dQv = root:Packages:NIST:USANS_dQv
	
	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A/Q fileStr
	String fileName = S_fileName
	Variable numCols = V_flag
	
	//changes JIL
	if(numCols==2)		//no errors	
		n1 = StringFromList(1, S_waveNames ,";" )		
		Duplicate/O $("root:"+n1), errorTmp
		 errorTmp = 0.01*(errorTmp)+ 0.03*sqrt(errorTmp)
		S_waveNames+="errorTmp;"
		numCols=3
	endif
	
	if(numCols==3)		//simple 3-column data with no resolution information
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		
		String baseStr=w1[0,strlen(w1)-3]
		if(DataFolderExists("root:"+baseStr))
				DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
				if(V_flag==2)	//user selected No, don't load the data
					SetDataFolder root:
					KillWaves $n0,$n1,$n2		// kill the default waveX that were loaded
					//if(DataFolderExists("root:Packages:NIST"))
					//	String/G root:Packages:NIST:gLastFileName = filename
					//endif
					return		//quits the macro
				endif
				SetDataFolder $("root:"+baseStr)
		else
			NewDataFolder/S $("root:"+baseStr)
		endif
		
		////overwrite the existing data, if it exists
		Duplicate/O $("root:"+n0), $w0
		Duplicate/O $("root:"+n1), $w1
		Duplicate/O $("root:"+n2), $w2

		// no resolution matrix to make

		SetScale d,0,0,"1/A",$w0
		SetScale d,0,0,"1/cm",$w1
		
	endif		//3-col data
	
	if(numCols == 6)		//6-column SANS or USANS data that has resolution information
		
		// put the names of the (default named) loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		n5 = StringFromList(5, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		w3 = CleanupName((S_fileName + "sq"),0)
		w4 = CleanupName((S_fileName + "qb"),0)
		w5 = CleanupName((S_fileName + "fs"),0)
		
		String baseStr=w1[0,strlen(w1)-3]
		if(DataFolderExists("root:"+baseStr))
				DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
				if(V_flag==2)	//user selected No, don't load the data
					SetDataFolder root:
					KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
					if(DataFolderExists("root:Packages:NIST"))
						String/G root:Packages:NIST:gLastFileName = filename
					endif		//set the last file loaded to the one NOT loaded
					return		//quits the macro
				endif
				SetDataFolder $("root:"+baseStr)
				Print "Old Data Folder"
				Print GetDataFolder(1)
		else
			NewDataFolder/S $("root:"+baseStr)
			Print "New Data Folder"
			Print GetDataFolder(1)
		endif

////overwrite the existing data, if it exists
		Duplicate/O $("root:"+n0), $w0
		Duplicate/O $("root:"+n1), $w1
		Duplicate/O $("root:"+n2), $w2
		Duplicate/O $("root:"+n3), $w3
		Duplicate/O $("root:"+n4), $w4
		Duplicate/O $("root:"+n5), $w5

		// need to switch based on SANS/USANS
		if (isSANSResolution($w3[0]))		//checks to see if the first point of the wave is <0]
			// make a resolution matrix for SANS data
			Variable np=numpnts($w0)
			Make/D/O/N=(np,4) $(baseStr+"_res")
			
			$(baseStr+"_res")[][0] = $w3[p]		//sigQ
			$(baseStr+"_res")[][1] = $w4[p]		//qBar
			$(baseStr+"_res")[][2] = $w5[p]		//fShad
			$(baseStr+"_res")[][3] = $w0[p]		//Qvalues
		else
			//the data is USANS data
			// marix calculation here, but for now, just copy the waves
			//$(baseStr+"_res")[][0] = $w3[p]		//sigQ
			//$(baseStr+"_res")[][1] = $w4[p]		//qBar
			//$(baseStr+"_res")[][2] = $w5[p]		//fShad
			//$(baseStr+"_res")[][3] = $w0[p]		//Qvalues
			dQv = -$w3[0]
			
			USANS_CalcWeights(baseStr,dQv)
			
		endif
		Killwaves/Z $w3,$w4,$w5			//get rid of the resolution waves that are in the matrix

		SetScale d,0,0,"1/A",$w0
		SetScale d,0,0,"1/cm",$w1
	
	endif	//6-col data

	if(numCols==5)		//this is the "old-style" VAX desmeared data format
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName+"_q"),0)
		w1 = CleanupName((S_fileName+"_i"),0)
		w2 = CleanupName((S_fileName+"_s"),0)
		w3 = CleanupName((S_fileName+"_ism"),0)
		w4 = CleanupName((S_fileName+"_fit_ism"),0)
		
		String baseStr=w1[0,strlen(w1)-3]
		if(DataFolderExists("root:"+baseStr))
				DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
				if(V_flag==2)	//user selected No, don't load the data
					KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
					//if(DataFolderExists("root:Packages:NIST"))
					//	String/G root:Packages:NIST:gLastFileName = filename
					//endif		//set the last file loaded to the one NOT loaded
					return		//quits the macro
				endif
				SetDataFolder $("root:"+baseStr)
		else
			NewDataFolder/S $("root:"+baseStr)
		endif
		
		////overwrite the existing data, if it exists	
		Duplicate/O $("root:"+n0), $w0
		Duplicate/O $("root:"+n1), $w1
		Duplicate/O $("root:"+n2), $w2
		Duplicate/O $("root:"+n3), $w3
		Duplicate/O $("root:"+n4), $w4
		
		// no resolution matrix
	endif		//5-col data
	
	//////
	if(DataFolderExists("root:Packages:NIST"))
		String/G root:Packages:NIST:gLastFileName = filename
	endif
	
	//plot if desired
	if(doPlot)
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
		
		// if target window is a graph, and user wants to append, do so
	   DoWindow/B Plot_Manager
		if(WinType("") == 1)
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $w1 vs $w0
				ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1) =(rr,gg,bb),tickUnit=1
				ErrorBars $w1 Y,wave=($w2,$w2)
				ModifyGraph tickUnit(left)=1
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
				ModifyGraph grid=1,mirror=2,standoff=0
				ErrorBars $w1 Y,wave=($w2,$w2)
				ModifyGraph tickUnit(left)=1
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
			ModifyGraph grid=1,mirror=2,standoff=0
			ErrorBars $w1 Y,wave=($w2,$w2)
			ModifyGraph tickUnit(left)=1
			Legend
		endif
	endif
		
	//go back to the root folder and clean up before leaving
	SetDataFolder root:
	KillWaves/Z $n0,$n1,$n2,$n3,$n4,$n5
End


//procedure for loading NSE data in the format (4-columns)
// qvals - time - I(q,t) - dI(q,t)
//
//
// this does NOT load the data into separate folders...
//
Proc A_LoadNSEData()
	A_LoadNSEDataWithName("",1)
End

Proc A_LoadNSEDataWithName(fileStr,doPlot)

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A  fileStr
	String filename = S_fileName
	
	String w0,w1,w2,n0,n1,n2,wt,w3,n3
	Variable rr,gg,bb
	
	// put the names of the three loaded waves into local names
	n0 = StringFromList(0, S_waveNames ,";" )
	n1 = StringFromList(1, S_waveNames ,";" )
	n2 = StringFromList(2, S_waveNames ,";" )
	n3 = StringFromList(3, S_waveNames ,";" )
	
	
	//remove the semicolon AND period from files from the VAX
	w0 = CleanupName(("qvals_"+S_fileName),0)
	w1 = CleanupName(("time_"+S_fileName),0)
	w2 = CleanupName(("iqt_"+S_fileName),0)
	w3 = CleanupName(("iqterr_"+S_fileName),0)
	
	if(exists(w0) !=0)
		DoAlert 0,"This file has already been loaded. Use Append to Graph..."
		KillWaves $n0,$n1,$n2		// kill the default waveX that were loaded
		return
	endif
	
	// Rename to give nice names
	Rename $n0, $w0
	Rename $n1, $w1
	Rename $n2, $w2
	Rename $n3, $w3
		
	if(doPlot)
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
		
		// if target window is a graph, and user wants to append, do so
		if(WinType("") == 1)
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $w2 vs $w1
				ModifyGraph mode($w2)=3,marker($w2)=29,msize($w2)=2,rgb($w2) =(rr,gg,bb),grid=1,mirror=2,tickUnit=1
				ErrorBars $w2 Y,wave=($w3,$w3)
			else
			//new graph
				Display $w2 vs $w1
				ModifyGraph standoff=0,mode($w2)=3,marker($w2)=29,msize($w2)=2,rgb($w2)=(rr,gg,bb),grid=1,mirror=2,tickUnit=1
				ErrorBars $w2 Y,wave=($w3,$w3)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w2 vs $w1
			ModifyGraph standoff=0,mode($w2)=3,marker($w2)=29,msize($w2)=2,rgb($w2)=(rr,gg,bb),grid=1,mirror=2,tickUnit=1
			ErrorBars $w2 Y,wave=($w3,$w3)
			Legend
		endif
	endif //doPlot		

End

//procedure for loading desmeared USANS data in the format (5-columns)
// qvals - I(q) - sig I - Ism(q) - fitted Ism(q)
//no weighting wave is created (not needed in IGOR 4)
//
// not really ever used...
//
Proc A_LoadUSANSData()

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A
   String filename = S_fileName
	
	String w0,w1,w2,n0,n1,n2,w3,n3,w4,n4
	Variable rr,gg,bb
	
	// put the names of the three loaded waves into local names
	n0 = StringFromList(0, S_waveNames ,";" )
	n1 = StringFromList(1, S_waveNames ,";" )
	n2 = StringFromList(2, S_waveNames ,";" )
	n3 = StringFromList(3, S_waveNames ,";" )
	n4 = StringFromList(4, S_waveNames ,";" )
	
	
	//remove the semicolon AND period from files from the VAX
	w0 = CleanupName((S_fileName+"_q"),0)
	w1 = CleanupName((S_fileName+"_i"),0)
	w2 = CleanupName((S_fileName+"_s"),0)
	w3 = CleanupName((S_fileName+"_ism"),0)
	w4 = CleanupName((S_fileName+"_fit_ism"),0)
	
	if(exists(w0) !=0)		//the wave already exists
		DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
		if(V_flag==2)	//user selected No
			KillWaves $n0,$n1,$n2,$n3,$n4		// kill the default waveX that were loaded
			if(DataFolderExists("root:Packages:NIST"))
				String/G root:Packages:NIST:gLastFileName = filename
			endif		//set the last file loaded to the one NOT loaded
			return		//quits the macro
		endif
	endif
	
	////overwrite the existing data, if it exists
	Duplicate/O $n0, $w0
	Duplicate/O $n1, $w1
	Duplicate/O $n2, $w2
	Duplicate/O $n3, $w3
	Duplicate/O $n4, $w4
	KillWaves $n0,$n1,$n2,$n3,$n4
	
	if(DataFolderExists("root:Packages:NIST"))
		String/G root:Packages:NIST:gLastFileName = filename
	endif
		
	// assign colors randomly
	rr = abs(trunc(enoise(65535)))
	gg = abs(trunc(enoise(65535)))
	bb = abs(trunc(enoise(65535)))
	
		// if target window is a graph, and user wants to append, do so
	if(WinType("") == 1)
		DoAlert 1,"Do you want to append this data to the current graph?"
		if(V_Flag == 1)
			AppendToGraph $w1 vs $w0
			ModifyGraph mode=3,marker=29,msize=2,rgb ($w1) =(rr,gg,bb),tickUnit=1,grid=1,mirror=2
			ErrorBars $w1 Y,wave=($w2,$w2)
		else
		//new graph
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=29,msize=2,rgb=(rr,gg,bb),tickUnit=1,grid=1,mirror=2
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
	else
	// graph window was not target, make new one
		Display $w1 vs $w0
		ModifyGraph log=1,mode=3,marker=29,msize=2,rgb=(rr,gg,bb),tickUnit=1,grid=1,mirror=2
		ErrorBars $w1 Y,wave=($w2,$w2)
		Legend
	endif
		
End


//// Extra "Utility Procedures"
// to pick path, get a list of data files, and make sure that a valid filename
// is passed to LoadOneDDataWithName()
//

//prompts user to choose the local folder that contains the SANS Data
//only one folder can be used, and its path is catPathName (and is a NAME, not a string)
//this will overwrite the path selection
//returns 1 if no path selected as error condition
Function A_PickPath()
	
	//set the global string to the selected pathname
	NewPath/O/M="pick the SANS data folder" catPathName
	PathInfo/S catPathName
	String dum = S_path
	String alertStr = ""
	alertStr = "You must set the path to Charlotte through a Mapped Network Drive, not through the Network Neighborhood"
	//alertStr += "  Please see the manual for details."
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packages:NIST:gCatPathStr = "no folder selected"
		return(1)
	else
		//set the global to the path (as a string)
		// need 4 \ since it is the escape character
		if(cmpstr("\\\\",dum[0,1])==0)	//Windoze user going through network neighborhood
			DoAlert 0,alertStr
			KillPath catPathName
			return(1)
		endif
		String/G root:Packages:NIST:gCatPathStr = dum
		return(0)		//no error
	endif
End

//Function attempts to find valid filename from partial name that has been stripped of
//the VAX version number. The partial name is tried first
//*** the PATH is hard-wired to catPathName (which is assumed to exist)
//version numers up to ;10 are tried
//only the "name;vers" is returned. the path is not prepended, hence the return string
//is not a complete specification of the file
//
// added 11/99 - uppercase and lowercase versions of the file are tried, if necessary
// since from marquee, the filename field (textread[0]) must be used, and can be a mix of
// upper/lowercase letters, while the filename on the server (should) be all caps
// now makes repeated calls to ValidFileString()
//
Function/S A_FindValidFilename(partialName)
	String PartialName
	
	String retStr=""
	
	//try name with no changes - to allow for ABS files that have spaces in the names 12APR04
	retStr = A_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//if the partial name is derived from the file header, there can be spaces at the beginning
	//or in the middle of the filename - depending on the prefix and initials used
	//
	//remove any leading spaces from the name before starting
	partialName = A_RemoveAllSpaces(partialName)
	
	//try name with no spaces
	retStr = A_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all UPPERCASE
	partialName = UpperStr(partialName)
	retStr = A_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all lowercase (ret null if failure)
	partialName = LowerStr(partialName)
	retStr = A_ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	else
		return(retStr)
	Endif
End

//function to test a binary file to see if it is a RAW binary SANS file
//first checks the total bytes in the file (which for raw data is 33316 bytes)
//**note that the "DIV" file will also show up as a raw file by the run field
//should be listed in CAT/SHORT and in patch windows
//
//Function then checks the file fname (full path:file) for "RAW" run.type field
//if not found, the data is not raw data and zero is returned
Function A_CheckIfRawData(fname)
	String fname
	
	Variable refnum,totalBytes
	String testStr=""
	
	Open/R/T="????TEXT" refNum as fname
	//get the total number of bytes in the file, to avoid moving past EOF
	FStatus refNum
	totalBytes = V_logEOF
	//Print totalBytes
	if(totalBytes!=33316)
		//can't possibly be a raw data file
		Close refnum
		return(0)		//not a raw SANS file
	Endif
	FSetPos refNum,75
	FReadLine/N=3 refNum,testStr
	Close refNum
	
	if(cmpstr(testStr,"RAW")==0)
		//true, is raw data file
		Return(1)
	else
		//some other file
		Return(0)
	Endif
End

//list (input) is a list, typically returned from IndexedFile()
//which is semicolon-delimited, and may contain filesnames from the VAX
//that contain version numbers, where the version number appears as a separate list item
//(and also as a non-existent file)
//these numbers must be purged from the list, especially for display in a popup
//or list processing of filenames
//the function returns the list, cleaned of version numbers (up to 11)
//raw data files will typically never have a version number other than 1.
Function/S A_RemoveVersNumsFromList(list)
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

//Function attempts to find valid filename from partial name that has been stripped of
//the VAX version number. The partial name is tried first
//*** the PATH is hard-wired to catPathName (which is assumed to exist)
//version numers up to ;10 are tried
//only the "name;vers" is returned. the path is not prepended, hence the return string
//is not a complete specification of the file
//
Function/S A_ValidFileString(partialName)
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
Function/S A_RemoveAllSpaces(str)
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