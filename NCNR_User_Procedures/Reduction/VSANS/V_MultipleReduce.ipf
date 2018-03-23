#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*************************
//
// Procedures for the MRED panel to allow quick batch reduction of data files
//
//****note that much of this file is becoming obsolete as improved methods for 
//reducing multiple files are introduced. Some of these procedures may not last long***
//
//**************************

//
// TODO
// -- these procedures are in the process of being updated for VSANS
//    and are highly susceptible to change pending user feedback
//

//panel to allow reduction of a series of files using a selected  protocol
//
//main entry procedure to open the panel, initializing if necessary
Proc V_ReduceMultipleFiles()
	
	DoWindow/F V_Multiple_Reduce_Panel
	If(V_flag == 0)
		V_InitializeMultReducePanel()
		//draw panel
		V_Multiple_Reduce_Panel()
		//pop the protocol list
		V_MRProtoPopMenuProc("",1,"")
	Endif
End

//create the global variables needed to run the MReduce Panel
//all are kept in root:Packages:NIST:VSANS:Globals:MRED
//
Proc V_InitializeMultReducePanel()

	If(DataFolderExists("root:Packages:NIST:VSANS:Globals:MRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:MRED
//		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		If(V_flag==1)
			String dum = S_path
			String/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = dum
		else
			String/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = "no path selected"
		endif
		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRedList = "none"
		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList = "none"
		String/G root:Packages:NIST:VSANS:Globals:MRED:gFileNumList=""


	Endif 
End

//panel recreation macro for the MRED panel
//
Window V_Multiple_Reduce_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(535,72,951,228) /K=1 as "Multiple VSANS File Reduction"
	ModifyPanel cbRGB=(64535,49151,48490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7,30,422,30
	SetVariable PathDisplay,pos={77,7},size={300,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr
	Button PathButton,pos={3,3},size={70,20},proc=V_PickMRPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={385,3},size={25,20},proc=V_ShowMRHelp,title="?"
	Button helpButton,help={"Show the help file for reducing multiple files using the same protocol"}
	PopupMenu MRFilesPopup,pos={3,72},size={167,19},proc=V_MRedPopMenuProc,title="File(s) to Reduce"
	PopupMenu MRFilesPopup,help={"The displayed file is the one that will be reduced. The entire list will be reduced if \"Reduce All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh."}
	PopupMenu MRFilesPopup,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:MRED:gMRedList"
	SetVariable MRList,pos={3,48},size={350,13},proc=V_FileNumberListProc,title="File number list: "
	SetVariable MRList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	SetVariable MRList,limits={-Inf,Inf,1},value= root:Packages:NIST:VSANS:Globals:MRED:gFileNumList
	Button ReduceAllButton,pos={3,128},size={180,20},proc=V_ReduceAllPopupFiles,title="Reduce All Files in Popup"
	Button ReduceAllButton,help={"This will reduce ALL of the files in the popup list, not just the top file."}
//	Button ReduceOneButton,pos={3,98},size={180,20},proc=V_ReduceTopPopupFile,title="Reduce Top File in Popup"
//	Button ReduceOneButton,help={"This will reduce TOP files in the popup list, not all of the files."}
	Button DoneButton,pos={290,128},size={110,20},proc=V_MRDoneButtonProc,title="Done Reducing"
	Button DoneButton,help={"When done reducing files, this will close this control panel."}
	Button cat_short,pos={310,72},size={90,20},proc=V_ShowCatShort_MRED,title="File Catalog"
	Button cat_short,help={"Use this button to generate a table with file header information. Very useful for identifying files."}
//	Button show_cat_short,pos={280,98},size={120,20},proc=ShowCatShort_MRED,title="Show File Catalog"
//	Button show_cat_short,help={"Use this button to bring the File Catalog window to the front."}
//	Button sddList,pos={280,72},size={120,20},proc=ScatteringAtSDDTableButton,title="Files at SDD List"
//	Button sddList,help={"Use this button to generate a table of scattering files at a given ample to detector distance."}
//	Button acceptList,pos={280,98},size={120,20},proc=AcceptMREDList,title="Accept List"
//	Button acceptList,help={"Accept the list of files to reduce."}
	PopupMenu MRProto_pop,pos={3,98},size={119,19},proc=V_MRProtoPopMenuProc,title="Protocol "
	PopupMenu MRProto_pop,help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu MRProto_pop,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList"
EndMacro



//function takes a list of filenames (just the name, no path , no extension)
//that is COMMA delimited, and creates a new list that is also COMMA delimited
//and contains the full path:file;vers for each file in the list
//and ensures that files in returned list are RAW data, and can be found on disk
//
Function/S  V_FullNameListFromFileList(list)
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
			tempName = V_FindValidFilename(partialName)		//will add the version # if needed	
			fullName = pathStr + tempName						//prepend the path (CAT)
			
			//discard strings that are not filenames (print the non-files)
			//make sure the file is really a RAW data file
			ok = V_CheckIfRawData(fullName)		// 1 if RAW, 0 if unknown type
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
Function V_DoReduceList(list)
	String list
	
	//selected protocol is in a temporary global variable so that it can be used with execute
	SVAR gMredProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr
	//input list is a comma delimited list of individual sample files to be reduced using the 
	//given protocol - based on WM proc "ExecuteCmdOnList()"
	//input filenames must be full path:file;ext, so they can be found on disk
	
	String cmdTemplate = "V_ExecuteProtocol(\"" + gMredProtoStr + "\",\"%s\")"
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
Function V_FileNumberListProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
		
	V_MRedPopMenuProc("MRFilesPopup",0,"")
End

Proc V_ShowMRHelp(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial[Reduce Multiple Files]"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button procedure for bringing File Catalog window to front, if it exists
//so that the user can see what's going on
//
Proc V_ShowCatShort_MRED(ctrlName) : ButtonControl
	String ctrlName

	V_BuildCatVeryShortTable()
End

//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function V_PickMRPathButton(PathButton) : ButtonControl
	String PathButton
	
	V_PickPath()		//sets the main global path string for catPathName
	
	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = "no folder selected"
	else
		String/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=Multiple_Reduce_Panel $"PathDisplay"
	
	//then update the popup list
	V_MRedPopMenuProc("MRFilesPopup",1,"")
End

// changes the contents of the popup list of files to be reduced based on the 
// range of file numbers entered in the text box
//
Function V_MREDPopMenuProc(MRFilesPopup,popNum,popStr) : PopupMenuControl
	String MRFilesPopup
	Variable popNum
	String popStr

	String list = V_GetValidMRedPopupList()
//	
	String/G root:Packages:NIST:VSANS:Globals:MRED:gMredList = list
	ControlUpdate MRFilesPopup

End

// get a  list of all of the sample files, based on intent
//
//parses the file number list to get valid raw data filenames for reduction
// -if the numbers and full ranges can be translated to correspond to actual files
// on disk, the popup list is updated - otherwise the offending number is reported
// and the user must fix the problem before any reduction can be done
//
//		V_ParseRunNumberList() does the work
//
// only accepts files in the list that are purpose=scattering
//
Function/S V_GetValidMRedPopupList()

//	String semiList = V_GetSAMList()

	String commaList="",semiList="",fname="",purpose=""
	SVAR numList=root:Packages:NIST:VSANS:Globals:MRED:gFileNumList
	
	commaList = V_ParseRunNumberList(numList)
	//convert commaList to a semicolon delimited list, checking that files are SCATTERING
	Variable num=ItemsinList(commaList,","),ii
	for(ii=0;ii<num;ii+=1)
		fname = StringFromList(ii, commaList  ,",")
		purpose = V_getReduction_Purpose(fname)
		if(cmpstr(purpose,"SCATTERING") == 0)
			semiList += StringFromList(ii, commaList  ,",") + ";"
		endif
	endfor
//	print semiList
//sort the list
	semiList = SortList(semiList,";",0)
	return(semiList)


	return(semiList)
End

//returns a list of the available protocol waves in the protocols folder
//removes "CreateNew", "tempProtocol" and "fakeProtocol" from list (if they exist)
//since these waves do not contain valid protocol instructions
//
Function V_MRProtoPopMenuProc(MRProto_pop,popNum,popStr) : PopupMenuControl
	String MRProto_pop
	Variable popNum
	String popStr

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	String list = WaveList("*",";","")
	SetDataFolder root:
	
	//remove items from the list (list is unchanged if the items are not present)
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("fakeProtocol", list, ";")
	list = RemoveFromList("PanelNameW", list, ";")
	list = RemoveFromList("Beg_pts", list, ";")
	list = RemoveFromList("End_pts", list, ";")
	list = RemoveFromList("trimUpdate", list, ";")
	
	String/G root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList = list
	ControlUpdate MRProto_pop

End

//button procedure to close the panel, and the SDD table if if was generated
//
Function V_MRDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// this button will make sure all files are closed 
	//and close the panel

	Close/A
	DoWindow/K V_Multiple_Reduce_Panel
	
	DoWindow/K SDDTable	
	KillDataFolder root:Packages:NIST:VSANS:Globals:MRED
End

//button action function caled to reduce all of the files in the "file" popup
//using the protocol specified in the "protocol" popup
//converts list of files into comma delimited list of full path:filename;vers
//that can be reduced as a list
// also sets the current protocol to a global accessible to the list processing routine
//
Function V_ReduceAllPopupFiles(ctrlName) : ButtonControl
	String ctrlName
	
	//popup (and global list) is a semicolon separated list of files, WITHOUT extensions
	//transform this list into a COMMA delimited list of FULL filenames, and then they can be processed
	
	SVAR semiList = root:Packages:NIST:VSANS:Globals:MRED:gMredList
	
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
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr = "root:Packages:NIST:VSANS:Globals:Protocols:"+protocolNameStr
	
	//also set this as the current protocol, for the function that writes the averaged waves
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr
	
	//reduce all the files in the list here, using the global protocol(the full reference)
	//DoReduceList is found in MultipleReduce.ipf
	V_DoReduceList(commaList)
	
	Return 0
End


//
// reduce just the top file on the popup
//
Function V_ReduceTopPopupFile(ctrlName) : ButtonControl
	String ctrlName

	// get just the top file from the popup
	ControlInfo MRFilesPopup
	String commaList = S_Value + ","

	//get the selected protocol, and pass as a global
	ControlInfo MRProto_pop
	String protocolNameStr = S_Value
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr = "root:Packages:NIST:VSANS:Globals:Protocols:"+protocolNameStr
	
	//also set this as the current protocol, for the function that writes the averaged waves
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr
	
	//reduce all the files in the list here, using the global protocol(the full reference)
	//DoReduceList is found in MultipleReduce.ipf
	V_DoReduceList(commaList)
	
	Return 0
End

