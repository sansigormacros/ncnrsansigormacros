#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=7.00

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
	if(V_flag == 0)
		V_InitializeMultReducePanel()
		//draw panel
		V_Multiple_Reduce_Panel()
		//pop the protocol list
		V_MRProtoPopMenuProc("", 1, "")
	endif
EndMacro

//create the global variables needed to run the MReduce Panel
//all are kept in root:Packages:NIST:VSANS:Globals:MRED
//
Proc V_InitializeMultReducePanel()

	if(DataFolderExists("root:Packages:NIST:VSANS:Globals:MRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:MRED
		//		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		if(V_flag == 1)
			string   dum                                               = S_path
			string/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = dum
		else
			string/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = "no path selected"
		endif
		string/G root:Packages:NIST:VSANS:Globals:MRED:gMRedList    = "none"
		string/G root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList = "none"
		string/G root:Packages:NIST:VSANS:Globals:MRED:gFileNumList = ""

	endif
EndMacro

//panel recreation macro for the MRED panel
//
Window V_Multiple_Reduce_Panel()

	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(535 * sc, 72 * sc, 951 * sc, 228 * sc)/K=1 as "Multiple VSANS File Reduction"
	ModifyPanel cbRGB=(64535, 49151, 48490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7 * sc, 30 * sc, 422 * sc, 30 * sc
	SetVariable PathDisplay, pos={sc * 77, 7 * sc}, size={sc * 300, 13 * sc}, title="Path"
	SetVariable PathDisplay, help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr
	Button PathButton, pos={sc * 3, 3 * sc}, size={sc * 70, 20 * sc}, proc=V_PickMRPathButton, title="Pick Path"
	Button PathButton, help={"Select the folder containing the raw SANS data files"}
	Button helpButton, pos={sc * 385, 3 * sc}, size={sc * 25, 20 * sc}, proc=V_ShowMRHelp, title="?"
	Button helpButton, help={"Show the help file for reducing multiple files using the same protocol"}
	PopupMenu MRFilesPopup, pos={sc * 3, 72 * sc}, size={sc * 167, 19 * sc}, proc=V_MRedPopMenuProc, title="File(s) to Reduce"
	PopupMenu MRFilesPopup, help={"The displayed file is the one that will be reduced. The entire list will be reduced if \"Reduce All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh."}
	PopupMenu MRFilesPopup, mode=1, popvalue="none", value=#"root:Packages:NIST:VSANS:Globals:MRED:gMRedList"
	SetVariable MRList, pos={sc * 3, 48 * sc}, size={sc * 350, 13 * sc}, proc=V_FileNumberListProc, title="File number list: "
	SetVariable MRList, help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	SetVariable MRList, limits={-Inf, Inf, 1}, value=root:Packages:NIST:VSANS:Globals:MRED:gFileNumList
	Button ReduceAllButton, pos={sc * 3, 128 * sc}, size={sc * 180, 20 * sc}, proc=V_ReduceAllPopupFiles, title="Reduce All Files in Popup"
	Button ReduceAllButton, help={"This will reduce ALL of the files in the popup list, not just the top file."}
	//	Button ReduceOneButton,pos={sc*3,98*sc},size={sc*180,20*sc},proc=V_ReduceTopPopupFile,title="Reduce Top File in Popup"
	//	Button ReduceOneButton,help={"This will reduce TOP files in the popup list, not all of the files."}
	Button DoneButton, pos={sc * 290, 128 * sc}, size={sc * 110, 20 * sc}, proc=V_MRDoneButtonProc, title="Done Reducing"
	Button DoneButton, help={"When done reducing files, this will close this control panel."}
	Button cat_short, pos={sc * 310, 72 * sc}, size={sc * 90, 20 * sc}, proc=V_ShowCatShort_MRED, title="File Catalog"
	Button cat_short, help={"Use this button to generate a table with file header information. Very useful for identifying files."}
	//	Button show_cat_short,pos={sc*280,98*sc},size={sc*120,20*sc},proc=ShowCatShort_MRED,title="Show File Catalog"
	//	Button show_cat_short,help={"Use this button to bring the File Catalog window to the front."}
	//	Button sddList,pos={sc*280,72*sc},size={sc*120,20*sc},proc=ScatteringAtSDDTableButton,title="Files at SDD List"
	//	Button sddList,help={"Use this button to generate a table of scattering files at a given ample to detector distance."}
	//	Button acceptList,pos={sc*280,98*sc},size={sc*120,20*sc},proc=AcceptMREDList,title="Accept List"
	//	Button acceptList,help={"Accept the list of files to reduce."}
	PopupMenu MRProto_pop, pos={sc * 3, 98 * sc}, size={sc * 119, 19 * sc}, proc=V_MRProtoPopMenuProc, title="Protocol "
	PopupMenu MRProto_pop, help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu MRProto_pop, mode=1, popvalue="none", value=#"root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList"
EndMacro

//function takes a list of filenames (just the name, no path , no extension)
//that is COMMA delimited, and creates a new list that is also COMMA delimited
//and contains the full path:file;vers for each file in the list
//and ensures that files in returned list are RAW data, and can be found on disk
//
Function/S V_FullNameListFromFileList(string list)

	string newList = ""
	string pathStr = ""
	string sepStr  = ","
	PathInfo catPathName
	if(V_flag == 0)
		Abort "CatPath does not exist - use Pick Path to select the data folder"
	endif

	pathStr = S_Path

	variable ii, num, ok
	string str
	string fullName    = ""
	string partialName = ""
	string tempName    = ""

	num = ItemsInList(list, ",")
	ii  = 0
	do
		//take each item, and try to find the file (extensions for raw data should be ;1)
		partialName = StringFromList(ii, list, ",") //COMMA separated list
		if(strlen(partialName) != 0) //null string items will be skipped
			tempName = V_FindValidFilename(partialName) //will add the version # if needed
			fullName = pathStr + tempName               //prepend the path (CAT)

			//discard strings that are not filenames (print the non-files)
			//make sure the file is really a RAW data file
			ok = V_CheckIfRawData(fullName) // 1 if RAW, 0 if unknown type
			if(!ok)
				//write to cmd window that file was not a RAW SANS file
				str = "This file is not recognized as a RAW SANS data file: " + tempName + "\r"
				Print str
			else
				//yes, a valid file:path;ext that is RAW SANS
				//add the full path:file;ext +"," to the newList
				newList += fullName + sepStr
			endif
		endif //partialName from original list != ""
		ii += 1
	while(ii < num) //process all items in list

	return (newList)
End

//takes a COMMA delimited list of files (full path:name;vers output of FullNameListFromFileList()
//function and reduces each of the files in the list
//the protocol is from the global string (wich is NOt in the MRED folder, but in the Protocols folder
//
Function V_DoReduceList(string list)

	//selected protocol is in a temporary global variable so that it can be used with execute
	SVAR gMredProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr
	//input list is a comma delimited list of individual sample files to be reduced using the
	//given protocol - based on WM proc "ExecuteCmdOnList()"
	//input filenames must be full path:file;ext, so they can be found on disk

	//	String cmdTemplate = "V_ExecuteProtocol(\"" + gMredProtoStr + "\",\"%s\")"
	string theItem
	variable index = 0
	string cmd
	variable num = ItemsInList(list, ",")
	do
		theItem = StringFromList(index, list, ",") //COMMA separated list
		if(strlen(theItem) != 0)
			//sprintf cmd,cmdTemplate,theItem		//null string items will be skipped
			//Print "cmd = ",cmd
			//Execute cmd
			V_ExecuteProtocol(gMredProtoStr, theItem)
		endif
		index += 1
	while(index < num) //exit after all items have been processed

	//will continue until all files in list are reduced, according to gMredProtoStr protocol
	return (0)
End

//executed when a list of filenumbers is entered in the box
//responds as if the file popup was hit, to update the popup list contents
//
Function V_FileNumberListProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	V_MRedPopMenuProc("MRFilesPopup", 0, "")
End

Proc V_ShowMRHelp(ctrlName) : ButtonControl
	string ctrlName

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Reduce Multiple Files]"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Tutorial Help file could not be found"
	endif
EndMacro

//button procedure for bringing File Catalog window to front, if it exists
//so that the user can see what's going on
//
Proc V_ShowCatShort_MRED(ctrlName) : ButtonControl
	string ctrlName

	V_BuildCatVeryShortTable()
EndMacro

//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function V_PickMRPathButton(string PathButton) : ButtonControl

	V_PickPath() //sets the main global path string for catPathName

	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
	string dum = S_path
	if(V_flag == 0)
		//path does not exist - no folder selected
		string/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = "no folder selected"
	else
		string/G root:Packages:NIST:VSANS:Globals:MRED:gCatPathStr = dum
	endif

	//Update the pathStr variable box
	ControlUpdate/W=Multiple_Reduce_Panel $"PathDisplay"

	//then update the popup list
	V_MRedPopMenuProc("MRFilesPopup", 1, "")
End

// changes the contents of the popup list of files to be reduced based on the
// range of file numbers entered in the text box
//
Function V_MREDPopMenuProc(string MRFilesPopup, variable popNum, string popStr) : PopupMenuControl

	string list = V_GetValidMRedPopupList()
	//
	string/G root:Packages:NIST:VSANS:Globals:MRED:gMredList = list
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

	string commaList = ""
	string semiList  = ""
	string fname     = ""
	string purpose   = ""
	SVAR   numList   = root:Packages:NIST:VSANS:Globals:MRED:gFileNumList

	// if a "*" is entered, return all of the SAMPLE+SCATTERING files
	if(cmpstr(numList, "*") == 0)
		semiList = V_GetSAMList()
		return (semiList)
	endif

	commaList = V_ParseRunNumberList(numList)
	//convert commaList to a semicolon delimited list, checking that files are SCATTERING
	variable ii
	variable num = ItemsinList(commaList, ",")
	for(ii = 0; ii < num; ii += 1)
		fname   = StringFromList(ii, commaList, ",")
		purpose = V_getReduction_Purpose(fname)
		if(cmpstr(purpose, "SCATTERING") == 0)
			semiList += StringFromList(ii, commaList, ",") + ";"
		endif
	endfor
	//	print semiList
	//sort the list
	semiList = SortList(semiList, ";", 0)
	return (semiList)

	return (semiList)
End

//returns a list of the available protocol waves in the protocols folder
//removes "CreateNew", "tempProtocol" and "fakeProtocol" from list (if they exist)
//since these waves do not contain valid protocol instructions
//
Function V_MRProtoPopMenuProc(string MRProto_pop, variable popNum, string popStr) : PopupMenuControl

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	string list = WaveList("*", ";", "")
	SetDataFolder root:

	//remove items from the list (list is unchanged if the items are not present)
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("fakeProtocol", list, ";")
	list = RemoveFromList("PanelNameW", list, ";")
	list = RemoveFromList("Beg_pts", list, ";")
	list = RemoveFromList("End_pts", list, ";")
	list = RemoveFromList("trimUpdate", list, ";")

	string/G root:Packages:NIST:VSANS:Globals:MRED:gMRProtoList = list
	ControlUpdate MRProto_pop

End

//button procedure to close the panel, and the SDD table if if was generated
//
Function V_MRDoneButtonProc(string ctrlName) : ButtonControl

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
Function V_ReduceAllPopupFiles(string ctrlName) : ButtonControl

	//popup (and global list) is a semicolon separated list of files, WITHOUT extensions
	//transform this list into a COMMA delimited list of FULL filenames, and then they can be processed

	SVAR semiList = root:Packages:NIST:VSANS:Globals:MRED:gMredList

	//process each item in the list, and generate commaList
	variable num       = ItemsInList(semiList, ";")
	variable ii        = 0
	string   commaList = ""
	string   item      = ""
	do
		item       = StringFromList(ii, semiList, ";")
		commaList += item + ","
		ii        += 1
	while(ii < num)
	//080601 - send only the comma list of filenames, not full path:name
	//commaList = FullNameListFromFileList(commaList)		//gets the full file names (including extension) for each item in list

	//get the selected protocol, and pass as a global
	ControlInfo MRProto_pop
	string   protocolNameStr                                          = S_Value
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr = "root:Packages:NIST:VSANS:Globals:Protocols:" + protocolNameStr

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr

	//reduce all the files in the list here, using the global protocol(the full reference)
	//DoReduceList is found in MultipleReduce.ipf
	V_DoReduceList(commaList)

	return 0
End

//
// reduce just the top file on the popup
//
Function V_ReduceTopPopupFile(string ctrlName) : ButtonControl

	// get just the top file from the popup
	ControlInfo MRFilesPopup
	string commaList = S_Value + ","

	//get the selected protocol, and pass as a global
	ControlInfo MRProto_pop
	string   protocolNameStr                                          = S_Value
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gMredProtoStr = "root:Packages:NIST:VSANS:Globals:Protocols:" + protocolNameStr

	//also set this as the current protocol, for the function that writes the averaged waves
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr

	//reduce all the files in the list here, using the global protocol(the full reference)
	//DoReduceList is found in MultipleReduce.ipf
	V_DoReduceList(commaList)

	return 0
End

