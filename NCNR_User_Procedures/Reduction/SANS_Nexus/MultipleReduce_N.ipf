#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*************************
// Vers. 1.2 092101
//
// Procedures for the MRED panel to allow quick batch reduction of data files
// -as of 8/01, use the new method of requiring only run numbers to select the datafiles
//		and these data failes need not be consecutively numbered
//
//****note that much of this file is becoming obsolete as improved methods for 
//reducing multiple files are introduced. Some of these procedures may not last long***
//
//**************************

//panel to allow reduction of a series of files using a selected  protocol
//
//main entry procedure to open the panel, initializing if necessary
Proc ReduceMultipleFiles()
	
	DoWindow/F Multiple_Reduce_Panel
	If(V_flag == 0)
		InitializeMultReducePanel()
		//draw panel
		Multiple_Reduce_Panel()
		//pop the protocol list
		MRProtoPopMenuProc("",1,"")
	Endif
End

//create the global variables needed to run the MReduce Panel
//all are kept in root:myGlobals:MRED
//
Proc InitializeMultReducePanel()

	If(DataFolderExists("root:myGlobals:MRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:myGlobals:MRED
//		String/G root:myGlobals:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		If(V_flag==1)
			String dum = S_path
			String/G root:myGlobals:MRED:gCatPathStr = dum
		else
			String/G root:myGlobals:MRED:gCatPathStr = "no path selected"
		endif
		String/G root:myGlobals:MRED:gMRedList = "none"
		String/G root:myGlobals:MRED:gMRProtoList = "none"
		String/G root:myGlobals:MRED:gFileNumList=""
//		String/G root:myGlobals:MRED:gMRS1 = "no file selected"
//		String/G root:myGlobals:MRED:gMRS2 = "no file selected"
//		String/G root:myGlobals:MRED:gMRS3 = "no box selected"
//		Variable/G root:myGlobals:MRED:gMRV1 =0
//		Variable/G root:myGlobals:MRED:gMRV2 = 999
	Endif 
End

//panel recreation macro for the MRED panel
//
Window Multiple_Reduce_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(535,72,951,228) /K=1 as "Multiple File Reduction"
	ModifyPanel cbRGB=(65535,49151,29490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7,30,422,30
	SetVariable PathDisplay,pos={77,7},size={300,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:myGlobals:MRED:gCatPathStr
	Button PathButton,pos={3,3},size={70,20},proc=PickMRPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={385,3},size={25,20},proc=ShowMRHelp,title="?"
	Button helpButton,help={"Show the help file for reducing multiple files using the same protocol"}
	PopupMenu MRFilesPopup,pos={3,72},size={167,19},proc=MRedPopMenuProc,title="File(s) to Reduce"
	PopupMenu MRFilesPopup,help={"The displayed file is the one that will be reduced. The entire list will be reduced if \"Reduce All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh."}
	PopupMenu MRFilesPopup,mode=1,popvalue="none",value= #"root:myGlobals:MRED:gMRedList"
	SetVariable MRList,pos={3,48},size={350,13},proc=FileNumberListProc,title="File number list: "
	SetVariable MRList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	SetVariable MRList,limits={-Inf,Inf,1},value= root:myGlobals:MRED:gFileNumList
	Button ReduceAllButton,pos={3,128},size={180,20},proc=ReduceAllPopupFiles,title="Reduce All Files in Popup"
	Button ReduceAllButton,help={"This will reduce ALL of the files in the popup list, not just the top file."}
	Button DoneButton,pos={280,128},size={110,20},proc=MRDoneButtonProc,title="Done Reducing"
	Button DoneButton,help={"When done reducing files, this will close this control panel."}
//	Button cat_short,pos={310,72},size={90,20},proc=DoCatShort,title="File Catalog"
//	Button cat_short,help={"Use this button to generate a table with file header information. Very useful for identifying files."}
//	Button show_cat_short,pos={280,98},size={120,20},proc=ShowCatShort_MRED,title="Show File Catalog"
//	Button show_cat_short,help={"Use this button to bring the File Catalog window to the front."}
	Button sddList,pos={280,72},size={120,20},proc=ScatteringAtSDDTableButton,title="Files at SDD List"
	Button sddList,help={"Use this button to generate a table of scattering files at a given ample to detector distance."}
	Button acceptList,pos={280,98},size={120,20},proc=AcceptMREDList,title="Accept List"
	Button acceptList,help={"Accept the list of files to reduce."}
	PopupMenu MRProto_pop,pos={3,98},size={119,19},proc=MRProtoPopMenuProc,title="Protocol "
	PopupMenu MRProto_pop,help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu MRProto_pop,mode=1,popvalue="none",value= #"root:myGlobals:MRED:gMRProtoList"
EndMacro

//simple procedure to bring the CAT TABLE to the front if it is present
//alerts user, but does nothing else if CAT TABLE is not present 
//called by several panels
//
Proc ShowCATWindow()
	DoWindow/F CatVSTable
	if(V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
	Endif
End


//function takes a list of filenames (just the name, no path , no extension)
//that is COMMA delimited, and creates a new list that is also COMMA delimited
//and contains the full path:file;vers for each file in the list
//and ensures that files in returned list are RAW data , and can be found on disk
//
Function/S  FullNameListFromFileList(list)
	String list
	
	String newList="",pathStr="",sepStr=","
	PathInfo catPathName
	if(V_flag==0)
		Abort "CatPath does not exist - use Pick Path to select the data folder"
	else
		pathStr = S_Path
	Endif
	
	Variable ii,num,ok
	String fullName="",partialName="",tempName="",str
	 
	num = ItemsInList(list,",")
	ii=0
	do
		//take each item, and try to find the file (extensions for raw data should be ;1)
		partialName = StringFromList(ii,list,",")	//COMMA separated list
		if(strlen(partialName)!=0)		//null string items will be skipped
			tempName = N_FindValidFilename(partialName)		//will add the version # if needed	
			fullName = pathStr + tempName						//prepend the path (CAT)
			
			//discard strings that are not filenames (print the non-files)
			//make sure the file is really a RAW data file
			ok = N_CheckIfRawData(fullName)		// 1 if RAW, 0 if unknown type
			if (!ok)
				//write to cmd window that file was not a RAW SANS file
				str = "This file is not recognized as a RAW SANS data file: "+tempName+"\r"
				Print str
			else
				//yes, a valid file:path;ext that is RAW SANS
				//add the full path:file;ext +"," to the newList
				newList += fullName + sepStr
			Endif
		endif		//partialName from original list != ""
		ii+=1
	while(ii<num)	//process all items in list
	
	Return(newList)
End

//takes a COMMA delimited list of files (full path:name;vers output of FullNameListFromFileList()
//function and reduces each of the files in the list
//the protocol is from the global string (wich is NOt in the MRED folder, but in the Protocols folder
//
Function DoReduceList(list)
	String list
	
	//selected protocol is in a temporary global variable so that it can be used with execute
	SVAR gMredProtoStr = root:myGlobals:Protocols:gMredProtoStr
	//input list is a comma delimited list of individual sample files to be reduced using the 
	//given protocol - based on WM proc "ExecuteCmdOnList()"
	//input filenames must be full path:file;ext, so they can be found on disk
	
	String cmdTemplate = "ExecuteProtocol(\"" + gMredProtoStr + "\",\"%s\")"
	String theItem
	Variable index=0
	String cmd
	Variable num = ItemsInList(list,",")
	do
		theItem = StringFromList(index,list,",")	//COMMA separated list
		if(strlen(theItem)!=0)
			sprintf cmd,cmdTemplate,theItem		//null string items will be skipped
			//Print "cmd = ",cmd
			Execute cmd
		endif
		index +=1
	while(index<num)	//exit after all items have been processed
	
	//will continue until all files in list are reduced, according to gMredProtoStr protocol
	return(0)
End

//executed when a list of filenumbers is entered in the box
//responds as if the file popup was hit, to update the popup list contents
//
Function FileNumberListProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
		
	MRedPopMenuProc("MRFilesPopup",0,"")
End

Proc ShowMRHelp(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Reduce Multiple Files]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button procedure for bringing File Catalog window to front, if it exists
//so that the user can see what's going on
//
Proc ShowCatShort_MRED(ctrlName) : ButtonControl
	String ctrlName

	ShowCATWindow()
End

//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function PickMRPathButton(PathButton) : ButtonControl
	String PathButton
	
	PickPath()		//sets the main global path string for catPathName
	
	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:myGlobals:MRED:gCatPathStr = "no folder selected"
	else
		String/G root:myGlobals:MRED:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=Multiple_Reduce_Panel $"PathDisplay"
	
	//then update the popup list
	MRedPopMenuProc("MRFilesPopup",1,"")
End

// changes the contents of the popup list of files to be reduced based on the 
// range of file numbers entered in the text box
//
Function MREDPopMenuProc(MRFilesPopup,popNum,popStr) : PopupMenuControl
	String MRFilesPopup
	Variable popNum
	String popStr

	String list = GetValidMRedPopupList()
//	
	String/G root:myGlobals:MRED:gMredList = list
	ControlUpdate MRFilesPopup

End

//parses the file number list to get valid raw data filenames for reduction
// -if the numbers and full ranges can be translated to correspond to actual files
// on disk, the popup list is updated - otherwise the offending number is reported
// and the user must fix the problem before any reduction can be done
//
//ParseRunNumberList() does the work, as it does for the protocol panel
//
Function/S GetValidMRedPopupList()

	String commaList="",semiList=""
	SVAR numList=root:myGLobals:MRED:gFileNumList
	
	commaList = N_ParseRunNumberList(numList)
	//convert commaList to a semicolon delimited list
	Variable num=ItemsinList(commaList,","),ii
	for(ii=0;ii<num;ii+=1)
		semiList += StringFromList(ii, commaList  ,",") + ";"
	endfor
//	print semiList
//sort the list
	semiList = SortList(semiList,";",0)
	return(semiList)
End

//returns a list of the available protocol waves in the protocols folder
//removes "CreateNew", "tempProtocol" and "fakeProtocol" from list (if they exist)
//since these waves do not contain valid protocol instructions
//
Function MRProtoPopMenuProc(MRProto_pop,popNum,popStr) : PopupMenuControl
	String MRProto_pop
	Variable popNum
	String popStr

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:myGlobals:Protocols
	String list = WaveList("*",";","")
	SetDataFolder root:
	
	//remove items from the list (list is unchanged if the items are not present)
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("fakeProtocol", list, ";")
	
	String/G root:myGlobals:MRED:gMRProtoList = list
	ControlUpdate MRProto_pop

End

//button procedure to close the panel, and the SDD table if if was generated
//
Function MRDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// this button will make sure all files are closed 
	//and close the panel

	Close/A
	DoWindow/K Multiple_Reduce_Panel
	
	DoWindow/K SDDTable	
	KillDataFolder root:myGlobals:MRED
End

//button action function caled to reduce all of the files in the "file" popup
//using the protocol specified in the "protocol" popup
//converts list of files into comma delimited list of full path:filename;vers
//that can be reduced as a list
// also sets the current protocol to a global accessible to the list processing routine
//
Function ReduceAllPopupFiles(ctrlName) : ButtonControl
	String ctrlName
	
	//popup (and global list) is a semicolon separated list of files, WITHOUT extensions
	//transform this list into a COMMA delimited list of FULL filenames, and then they can be processed
	
	SVAR semiList = root:myGlobals:MRED:gMredList
	
	//process each item in the list, and generate commaList
	Variable num = ItemsInList(semiList,";" )
	Variable ii=0
	String commaList = "",item = ""
	do
		item = StringFromList(ii, semiList  ,";" )
		commaList += item + ","
		ii+=1
	while(ii<num)
	//080601 - send only the comma list of filenames, not full path:name	
	//commaList = FullNameListFromFileList(commaList)		//gets the full file names (including extension) for each item in list

	//get the selected protocol, and pass as a global
	ControlInfo MRProto_pop
	String protocolNameStr = S_Value
	String/G root:myGlobals:Protocols:gMredProtoStr = "root:myGlobals:Protocols:"+protocolNameStr
	
	//also set this as the current protocol, for the function that writes the averaged waves
	String/G root:myGlobals:Protocols:gProtoStr = protocolNameStr
	
	//reduce all the files in the list here, using the global protocol(the full reference)
	//DoReduceList is found in MultipleReduce.ipf
	DoReduceList(commaList)
	
	Return 0
End


//****************************
// below are very old procedures, not used (maybe of no value)


//little used procedure - works only with menu selections of list processing
//
Proc ClearFileList()
	String/G root:myGlobals:Protocols:gReduceList=""
	DoAlert 0,"The file reduction list has been initialized"
	ShowList()
End

//old procedure, (not used) - data is saved to the catPathName folder, the same folder
//where the data came from in the first place, avoiding extra paths
Proc PickSaveFolder()
	NewPath/O/M="pick folder for averaged data" Save_path
	PathInfo/S Save_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		Print "No destination path selected - save dialog will be presented"
	endif
End

//little used reduction procedure, asks for protocol, then uses this protocol
//to reduce the files in a list built by selecting files from the CAT window
//did not get favorable reviews from users and may not be kept
//
Proc ReduceFilesInList()

	String protocolName=""

	//generate a list of valid path:file;ext items, comma separated as the input filenames for
	//ExecuteProtocol(), their final destination
	
	String list = root:myGlobals:Protocols:gReduceList
	Variable num = ItemsInList(list,"," )
	
	list = FullNameListFromFileList(list)
	
	//Print list
	
	//get protocolName in the same manner as "recallprotocol" button
	//but remember to set a global for  Execute to use
	SetDataFolder root:myGlobals:Protocols		//must be in protocols folder before executing this Proc	
	Execute "PickAProtocol()"
	//get the selected protocol wave choice through a global string variable
	protocolName = root:myGlobals:Protocols:gProtoStr
	//If "CreateNew" was selected, ask user to try again
	if(cmpstr("CreateNew",protocolName) == 0)
		Abort "CreateNew is for making a new Protocol. Select a previously saved Protocol"
	Endif
	SetDataFolder root:
//	String/G root:myGlobals:Protocols:gMredProtoStr = "root:myGlobals:Protocols:"+protocolName
	
	//pass the full path to the protocol for ExecuteProtocol() later
	//Print gMredProtoStr," protocol name"
	
	DoReduceList(list)
	
//	KillStrings/Z gMredProtoStr
	
//	SetDataFolder root:
	
End

//displays the current contents of the FileList window, for multiple file reduction
//little used function and may not be kept
//
Proc ShowList()
	
	DoWindow/F ListWin
	If(V_Flag ==0)
		NewNotebook/F=1/N=ListWin as "File List"
	Endif
	//clear old window contents, reset the path
	Notebook ListWin,selection={startOfFile,EndOfFile}
	Notebook ListWin,text="\r"
	
	//Write out each item of the comma-delimited list to the notebook
	String list = root:myGlobals:Protocols:gReduceList
	Variable index = 0
	String theItem=""
	Variable num = ItemsInList(list,"," )
	do
		theItem = StringFromList(index,list,",")	//COMMA separated list
		if(strlen(theItem)!=0)
			Notebook ListWin,text=(theItem+"\r")		//null string items will be skipped
		endif
		index +=1
	while(index<num)	//exit after all items are printed
End


//little used function to add the selected file from the CAT/SHORT window to the fileList
//so that the list of files can be processed batchwise
//
Proc AddSelectionToList()

	if(WinType("CatWin")==0)
		Abort "There is no CAT/SHORT window. Use the CAT/SHORT button to create one."
	Endif
	GetSelection notebook,CatWin,3
	//build a comma separated list of names
	//does the global variable exist?
	if(exists("root:myGlobals:Protocols:gReduceList")==2)		//a string exists
		//do nothing extra
	else
		//create (initialize) the global string
		String/G root:myGlobals:Protocols:gReduceList = ""
	endif
	String list = root:myGlobals:Protocols:gReduceList
	list += S_Selection + ","
	String/G root:myGlobals:Protocols:gReduceList = list		//reassign the global
	
	
End

//little used function to remove the selected file in the CAT/SHORT window from the fileList
Proc RemoveFileFromList()
	//if(WinType("CatWin")==0)
		//Abort "There is no CAT/SHORT window. Use the CAT/SHORT button to create one."
	//Endif
	GetSelection notebook,ListWin,3
	//remove the selected item from the list
	String list = root:myGlobals:Protocols:gReduceList
	list = RemoveFromList(S_selection,list,",")
	String/G root:myGlobals:Protocols:gReduceList = list
	
	ShowList()
End

// based on WM PossiblyQuoteList(list, separator)
//	Input is a list of names that may contain liberal names.
//	Returns the list with liberal names quoted.
//	Example:
//		Input:		"wave0;wave 1;"
//		Output:		"wave0;'wave 1';"
//	The list is expected to be a standard separated list, like "wave0;wave1;wave2;".
//*****unused*******
Function/S PossiblyQuoteFileList(list, separator)
	String list
	String separator
	
	String item, outputList = ""
	Variable ii= 0
	Variable items= ItemsInList(list, separator)
	do
		if (ii >= items)			// no more items?
			break
		endif
		item= StringFromList(ii, list, separator)
		outputList += PossiblyQuoteName(item) + separator
		ii += 1
	while(1)
	return outputList
End

Function ScatteringAtSDDTableButton(ctrlName)
	String ctrlName
	
	Execute "CreateScatteringAtSDDTable()"
	return(0)
End

Function AcceptMREDList(ctrlName)
	String ctrlName
	
	SVAR/Z list = root:myGlobals:MRED:gFileNumList
	if(SVAR_Exists(list)==0)		//check for myself
		DoAlert 0,"The Multiple Reduce Panel must be open for you to use this function"
		Return(1)
	endif
	
	// convert the wave to a comma-delimited List
	wave/Z numW = $"root:myGlobals:MRED:RunNumber"
	if(waveExists(numW)==0 || numpnts(numW)==0)
		DoAlert 0, "Generate a list of files at a specific detector distance using the Files at SDD List button"
		return(0)
	Endif
	
	list = NumWave2IntegerCommaList(numW)
	
	//force an update If the SVAR exists, then the panel does too - MRED cleans up after itself when done
	DoWindow/F Multiple_Reduce_Panel			//bring to front
	MRedPopMenuProc("MRFilesPopup",0,"")		//parse the list, pop the menu
	
	
	return(0)
End

// - to create a table of scattering runs at an input SDD
Proc CreateScatteringAtSDDTable(SDD_to_Filter)
	Variable SDD_to_Filter
	
	NewDataFolder/O root:myGlobals:MRED
	DoWindow/F SDDTable
	
	Make/O/T/N=0 $"root:myGlobals:MRED:Filenames"
	Make/O/T/N=0 $"root:myGlobals:MRED:Suffix"
	Make/O/T/N=0 $"root:myGlobals:MRED:Labels"
	Make/O/D/N=0 $"root:myGlobals:MRED:SDD"
	Make/O/D/N=0 $"root:myGlobals:MRED:RunNumber"
	Make/O/D/N=0 $"root:myGlobals:MRED:IsTrans"

	If(V_Flag==0)
		SetDataFolder root:myGlobals:MRED
		Edit Labels, SDD, runNumber as "Scattering at SDD"
		DoWindow/C $"SDDTable"
		
		ModifyTable width(SDD)=40
		ModifyTable width(Labels)=180
		ModifyTable format(RunNumber)=1		//so that HFIR 8-digit numbers are interpreted correctly as integers
		
		ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run
		SetDataFolder root:
	Endif

	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	

	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName
	Variable lastPoint
	ii=0
	
	Make/T/O/N=0 notRAWlist
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = N_FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = N_CheckIfRawData(fullName)
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				GetHeaderInfoToSDDWave(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
//Now sort them all based on the suffix data (orders them as collected)
//	SortCombineWaves()
// sort by label
//	SortCombineByLabel()
// remove the transmission waves
//
	RemoveTransFilesFromSDDList()

// Remove anything not at the desired SDD, then sort by run number
	RemoveWrongSDDFromSDDList(SDD_to_Filter)
	
// remove anything named blocked, empty cell, etc.
	RemoveLabeledFromSDDList("EMPTY")		//not case-sensitive
	RemoveLabeledFromSDDList("MT CELL")		//not case-sensitive
	RemoveLabeledFromSDDList("BLOCKED BEAM")		//not case-sensitive
	RemoveLabeledFromSDDList("BEAM BLOCKED")		//not case-sensitive

End

// need fuzzy comparison, since SDD = 1.33 may actually be represented in FP as 1.33000004	!!!
//
Function RemoveLabeledFromSDDList(findThisStr)
	String findThisStr
	Wave/T filenames = $"root:myGlobals:MRED:Filenames"
	Wave/T suffix = $"root:myGlobals:MRED:Suffix"
	Wave/T labels = $"root:myGlobals:MRED:Labels"
	Wave sdd = $"root:myGlobals:MRED:SDD"
	Wave runnum = $"root:myGlobals:MRED:RunNumber"
	Wave isTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(Labels),ii,loc
	ii=num-1
	do
		loc = strsearch(labels[ii], findThisStr, 0 ,2)		//2==case insensitive, but Igor 5 specific
		if(loc != -1)
			Print "Remove w[ii] = ",runnum[ii],"  ",labels[ii]
			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
		endif
		ii-=1
	while(ii>=0)
	return(0)
End		

// need fuzzy comparison, since SDD = 1.33 may actually be represented in FP as 1.33000004	!!!
//
Function RemoveWrongSDDFromSDDList(tSDD)
	Variable tSDD
	
	Wave/T filenames = $"root:myGlobals:MRED:Filenames"
	Wave/T suffix = $"root:myGlobals:MRED:Suffix"
	Wave/T labels = $"root:myGlobals:MRED:Labels"
	Wave sdd = $"root:myGlobals:MRED:SDD"
	Wave runnum = $"root:myGlobals:MRED:RunNumber"
	Wave isTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(sdd),ii,tol = 0.1
	ii=num-1
	do
//		if(abs(sdd[ii] - tSDD) > tol)		//if numerically more than 0.001 m different, they're not the same
//			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
//		endif
		if(trunc(abs(sdd[ii] - tSDD)) > tol)		//just get the integer portion of the difference - very coarse comparison
			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
		endif
		ii-=1
	while(ii>=0)
	
	// now sort
	Sort RunNum, 	filenames,suffix,labels,sdd,runnum,isTrans
	return(0)
End


Function RemoveTransFilesFromSDDList()
	Wave/T filenames = $"root:myGlobals:MRED:Filenames"
	Wave/T suffix = $"root:myGlobals:MRED:Suffix"
	Wave/T labels = $"root:myGlobals:MRED:Labels"
	Wave sdd = $"root:myGlobals:MRED:SDD"
	Wave runnum = $"root:myGlobals:MRED:RunNumber"
	Wave isTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(isTrans),ii
	ii=num-1
	do
		if(isTrans[ii] != 0)
			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
		endif
		ii-=1
	while(ii>=0)
	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function GetHeaderInfoToSDDWave(fname,sname)
	String fname,sname
	
	String textstr,temp,lbl,date_time,suffix
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick,xcenter,ycenter,numatten
	Variable lastPoint, beamstop

	Wave/T GFilenames = $"root:myGlobals:MRED:Filenames"
	Wave/T GSuffix = $"root:myGlobals:MRED:Suffix"
	Wave/T GLabels = $"root:myGlobals:MRED:Labels"
	Wave GSDD = $"root:myGlobals:MRED:SDD"
	Wave GRunNumber = $"root:myGlobals:MRED:RunNumber"
	Wave GIsTrans = $"root:myGlobals:MRED:IsTrans"
	
	lastPoint = numpnts(GLambda)
		
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file suffix
	InsertPoints lastPoint,1,GSuffix
	// -- replace the suffix (that doesn't exist in the Nexus file) -- with the filename for now
	GSuffix[lastPoint]=getSuffix(fname)

	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleDescription(fname)
	
	//read in the SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]= getDet_Distance(fname)

	//the run number (not displayed in the table, but carried along)
	InsertPoints lastPoint,1,GRunNumber
	GRunNumber[lastPoint] = N_GetRunNumFromFile(sname)

	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = N_isTransFile(fname)		//returns one if beamstop is "out"
	
	KillWaves/Z w
	return(0)
End
