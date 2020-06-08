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
		PathInfo catPathName
		If(V_flag==1)
			String dum = S_path
			String/G root:myGlobals:MRED:gCatPathStr = dum
		else
			String/G root:myGlobals:MRED:gCatPathStr = "no path selected"
		endif
		String/G root:myGlobals:MRED:gMRedSampleList = "none"
		String/G root:myGlobals:MRED:gMRedEmptyList = "none"
		String/G root:myGlobals:MRED:gMRProtoList = "none"
		String/G root:myGlobals:MRED:gSampleRuns = ""
		String/G root:myGlobals:MRED:gEmptyRuns = ""
		String/G root:myGlobals:MRED:actSampleRuns = ""
		String/G root:myGlobals:MRED:actEmptyRuns = ""
		String/G root:myGLobals:MRED:gScaleEMP = ""
		String/G root:myGlobals:MRED:actScaleEMP = ""
	Endif 
End

//panel recreation macro for the MRED panel
//
Window Multiple_Reduce_Panel()

	// Layout 
	//
	// [Pick Path] Path [      path selected      ] [?]
	// ------------------------------------------------
	// Sample Runs   [      sample runs ]
	// Empty Runs    [      empty runs  ]
	// ------------------------------------------------
	// [Runs to Table] [SDD List] [Table to Runs]
	// [Protocol]                   [Reduce All] [Done]
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(535,72,955,237) /K=1 as "Multiple File Reduction"
	ModifyPanel cbRGB=(65535,49151,29490)
	ModifyPanel fixedSize=1

	SetVariable PathDisplay,pos={77,7},size={300,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:myGlobals:MRED:gCatPathStr
	Button PathButton,pos={3,3},size={70,20},proc=PickMRPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={385,3},size={25,20},proc=ShowMRHelp,title="?"
	Button helpButton,help={"Show the help file for reducing multiple files using the same protocol"}

	SetDrawLayer UserBack
	DrawLine 4,30,416,30
	
	SetVariable MRSampleList,pos={10,48},size={350,13},proc=FileNumberListProc,title = "Sample Runs:"
	SetVariable MRSampleList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	SetVariable MRSampleList,limits={-Inf,Inf,1},value= root:myGlobals:MRED:gSampleRuns

	SetVariable MREmptyList,pos={10,74},size={300,13},proc=FileNumberListProc,title = "Empty Runs:"
	SetVariable MREmptyList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
	SetVariable MREmptyList,limits={-Inf,Inf,1},value= root:myGlobals:MRED:gEmptyRuns

	SetVariable MRScaleEMP,pos={320,74},size={80,13},proc=FileNumberListProc,title = "Scale:"
	SetVariable MRScaleEMP,help={"Scale to be applied to the empty runs."}
	SetVariable MRScaleEMP,limits={-Inf,Inf,0},value= root:myGlobals:MRED:gScaleEMP
	
	SetDrawLayer UserBack
	DrawLine 4,105,416,105
	
	PopupMenu MRProto_pop,pos={4,112},size={120,19},proc=MRProtoPopMenuProc,title="Protocol "
	PopupMenu MRProto_pop,help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu MRProto_pop,mode=1,popvalue="none",value= #"root:myGlobals:MRED:gMRProtoList"		
	Button ReductionTableBtn,pos={127,112},size={100,20},proc=ShowMRReductionTable,title="Runs to Table"
	Button ReductionTableBtn,help={"Generates a table that shows the reduction files per row."}
	Button sddList,pos={232,112},size={90,20},proc=ScatteringAtSDDTableButton,title="Files at SDD"
	Button sddList,help={"Use this button to generate a table of scattering files at a given ample to detector distance."}
	Button mapToRuns,pos={327,112},size={90,20},proc=MapTableToRuns,title="Table to Runs"
	Button mapToRuns,help={"Accept the list of files to reduce."}	

	//SetDrawLayer UserBack
	//DrawLine 4,135,416,135
	
	Button ReduceAllButton,pos={232,140},size={120,20},proc=ReduceAllSampleFiles,title="Reduce All"
	Button ReduceAllButton,help={"This will reduce ALL of the files in the popup list, not just the top file."}
	Button DoneButton,pos={357,140},size={60,20},proc=MRDoneButtonProc,title="Done"
	Button DoneButton,help={"When done reducing files, this will close this control panel."}
	


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

Function/S RunToQuokkaFile(num)
	Variable num
	
	String fname
	sprintf fname, "QKK%07u.nx.hdf", num
	return (fname)
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
			tempName = FindValidFilename(partialName)		//will add the version # if needed	
			fullName = pathStr + tempName						//prepend the path (CAT)
			
			//discard strings that are not filenames (print the non-files)
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)		// 1 if RAW, 0 if unknown type
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
	String/G root:myGlobals:MRED:gMRedSampleList = list
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
	SVAR numList=root:myGLobals:MRED:gSampleRuns
	
	commaList = ParseRunNumberList(numList)
	//convert commaList to a semicolon delimited list
	Variable num=ItemsinList(commaList,","),ii
	for(ii=0;ii<num;ii+=1)
		// ReplaceString to get rid of empty spaces [dmaennic]
		semiList += ReplaceString(" ", StringFromList(ii, commaList  ,","), "") + ";"
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
	
	DoWindow/K CatMRTable	
	KillDataFolder root:myGlobals:MRED
End

Function CreateMRTable()

	Make/O/D/N=0 $"root:myGlobals:MRED:SampleRuns"
	Make/O/T/N=0 $"root:myGlobals:MRED:EmptyRuns"
	Make/O/T/N=0 $"root:myGlobals:MRED:Suffix"
	Make/O/T/N=0 $"root:myGlobals:MRED:Labels"
	Make/O/D/N=0 $"root:myGlobals:MRED:SDD"
	Make/O/D/N=0 $"root:myGlobals:MRED:IsTrans"
	Make/O/T/N=0 $"root:myGlobals:MRED:Scale"

	SetDataFolder root:myGlobals:MRED
	Edit SampleRuns, EmptyRuns, Scale, SDD, Labels as "Multiple Reduction Sequence"
	DoWindow/C $"CatMRTable"
	
	ModifyTable format(SampleRuns)=1		//so that HFIR 8-digit numbers are interpreted correctly as integers
	ModifyTable format(EmptyRuns)=1		//so that HFIR 8-digit numbers are interpreted correctly as integers
	ModifyTable width(Scale)=40
	ModifyTable width(SDD)=40
	ModifyTable width(Labels)=180

	ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run
End

Function ClearMRTable()

	WAVE SampleRuns = $"root:myGlobals:MRED:SampleRuns"
	WAVE/T EmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	WAVE/T Suffix = $"root:myGlobals:MRED:Suffix"
	WAVE/T Labels = $"root:myGlobals:MRED:Labels"
	WAVE SDD = $"root:myGlobals:MRED:SDD"
	WAVE IsTrans = $"root:myGlobals:MRED:IsTrans"
	WAVE/T ScaleEMP = $"root:myGlobals:MRED:Scale"
	
	DeletePoints 0, numpnts(SampleRuns), SampleRuns
	DeletePoints 0, numpnts(EmptyRuns), EmptyRuns	
	DeletePoints 0, numpnts(ScaleEMP), ScaleEMP
	DeletePoints 0, numpnts(Suffix), Suffix
	DeletePoints 0, numpnts(Labels), Labels	
	DeletePoints 0, numpnts(SDD), SDD
	DeletePoints 0, numpnts(IsTrans), IsTrans	
End

Function ShowMRReductionTable(ctrlName) : ButtonControl
	String ctrlName

	// Builds a table that lists the reduction steps to be performed but 
	// it needs the path to the data
	Variable err
	PathInfo catPathName
	if(v_flag==0)
		err = PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "No path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	DoWindow/F CatMRTable
	
	If(V_Flag==0)
		CreateMRTable()
	Else
		ClearMRTable()
	Endif
	
	// Get a list of the sample and empty files from the runs
	String sampleCSV="",emptyCSV=""
	SVAR sampleRuns=root:myGLobals:MRED:gSampleRuns
	SVAR emptyRuns=root:myGLobals:MRED:gEmptyRuns
	SVAR scaleEmpty=root:myGLobals:MRED:gScaleEMP
	
	// reset the act runs to test need for update
	String/G root:myGlobals:MRED:actSampleRuns = sampleRuns
	String/G root:myGlobals:MRED:actEmptyRuns = emptyRuns
	String/G root:myGLobals:MRED:actScaleEMP = scaleEmpty
	
	sampleCSV = ParseRunNumberList(sampleRuns)
	emptyCSV = ParseRunNumberList(emptyRuns)
	
	// If the runs are not empty and not equal raise a warning.
	Variable numSamples = ItemsInList(sampleCSV,",")
	Variable numEmpty = ItemsInList(emptyCSV,",")
	if (numSamples == 0)
		DoAlert 0,"Specify a valid set of samples runs to run this function"
		Return(1)
	Endif
	Variable fillEmpty = 0
	if (numEmpty > 0 && numEmpty != numSamples)
		DoAlert 1,"No 1-1 mapping to the sample runs - fill empty runs with trailing value?"
		fillEmpty = (V_Flag == 1)
	Endif
	
	Variable ix
	String sfile, efile, spath, erun
	String elast = ""
	for (ix = 0; ix < numSamples; ix += 1)
	
		sfile = StringFromList(ix,sampleCSV,",")
		efile = StringFromList(ix,emptyCSV,",")
		If (ix < numEmpty)
			elast = efile
		Else
			If (fillEmpty)
				efile = elast
			Endif
		Endif
		If (cmpstr(sfile,"") == 0)
			DoAlert 0, "Empty sample run included in the list, do you wish to continue?"
			If (V_Flag == 1)
				continue
			Else
				return (1)
			EndIf
		Endif
		PathInfo catPathName
		spath = S_path + sfile

		GetHeaderInfoToSDDWave(spath,sfile,efile,scaleEmpty)
		
	EndFor
	
End

//button action function caled to reduce all of the files in the "file" popup
//using the protocol specified in the "protocol" popup
//converts list of files into comma delimited list of full path:filename;vers
//that can be reduced as a list
// also sets the current protocol to a global accessible to the list processing routine
//
Function ReduceAllSampleFiles(ctrlName) : ButtonControl
	String ctrlName
	
	// Firstly confirm that there is a list of files to be processed
	DoWindow/F CatMRTable
	If(V_Flag==0)
		ShowMRReductionTable(ctrlName)
	Else
		// check if the runs sequence or scale has changed since the table was built
		SVAR sampleRunsStr = root:myGlobals:MRED:gSampleRuns
		SVAR emptyRunsStr = root:myGlobals:MRED:gEmptyRuns
		SVAR scaleEMPStr = root:myGlobals:MRED:gScaleEMP
		SVAR sampleTblStr = root:myGlobals:MRED:actSampleRuns
		SVAR emptyTblStr = root:myGlobals:MRED:actEmptyRuns
		SVAR scaleTableStr = root:myGlobals:MRED:actScaleEMP
		
		If (cmpstr(sampleRunsStr, sampleTblStr) != 0 || cmpstr(emptyRunsStr, emptyTblStr) != 0 || cmpstr(scaleEMPStr, scaleTableStr) != 0)
			ShowMRReductionTable(ctrlName)
		Endif
	Endif
	
	// Define a copy of the protocol after recovering the protocol from the popup.
	// The protocol is just a text wave array. The copy just replaces the empty filename.
	SetDataFolder root:myGlobals:Protocols
	ControlInfo MRProto_pop
	String protocolNameStr = S_Value
	String/G root:myGlobals:Protocols:gMRedProtoStr = "root:myGlobals:Protocols:" + protocolNameStr
	SVAR baseProtocol = root:myGlobals:Protocols:gMRedProtoStr
	
	WAVE/T prot = $baseProtocol
	Duplicate/O prot copyMRedProto
	String/G root:myGlobals:Protocols:gProtoStr = NameOfWave(copyMRedProto)
	String actProtStr = "root:myGlobals:Protocols:" + NameOfWave(copyMRedProto)
	WAVE/T actProt = $actProtStr
	
	// Set up the list of files from the table
	WAVE SampleRuns = $"root:myGlobals:MRED:SampleRuns"
	WAVE/T EmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	WAVE/T ScaleEMP = $"root:myGlobals:MRED:Scale"
	
	// Run through the list of sample files
	Variable ix
	Variable numScale = numpnts(ScaleEMP)
	Variable numSample = numpnts(SampleRuns)
	for (ix = 0; ix < numSample; ix += 1)
	
		String sfile = RunToQuokkaFile(SampleRuns[ix])
		String efile = ""
		String erun = EmptyRuns[ix]	
		Variable scale = 1.0
		
		// check if an empty file is required by the protocol
		// replace file name if "ask" or "", skip if "none"
		if (cmpstr(prot[1],"ask") == 0 || cmpstr(prot[1],"") == 0)
			If (cmpstr(erun, "") != 0)
				efile = RunToQuokkaFile(str2num(erun))
			Endif
			if (cmpstr(efile,"") != 0)
				actProt[1] = efile
			else
				actProt[1] = prot[1]
			Endif
		Else
			actProt[1] = prot[1]
		Endif
		// 
		If (ix < numScale && cmpstr(ScaleEMP[ix],"") != 0)
			scale = str2num(ScaleEMP[ix])
			If (scale == NaN)
				DoAlert 0, "Invalid empty scale value in the list, continue with scale = 1?"
				If (V_Flag == 1)
					scale = 1
					continue
				Else
					return (1)
				EndIf
			Endif
			actProt[7] = num2str(scale)
		Else
			actProt[7] = prot[7]
		Endif		
		ExecuteProtocol(actProtStr, sfile)
	EndFor
	
	return(0)
	
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

	Variable err
	PathInfo catPathName
	if(v_flag==0)
		err = PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "No path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	Execute "CreateScatteringAtSDDTable()"
	return(0)
End

Function MapTableToRuns(ctrlName)
	String ctrlName
	
	// maps the sample and empty in the table to the runs
	SVAR/Z slist = root:myGlobals:MRED:gSampleRuns
	SVAR/Z elist = root:myGLobals:MRED:gEmptyRuns
	if(SVAR_Exists(slist)==0 || SVAR_Exists(elist) == 0)		//check for myself
		DoAlert 0,"The Multiple Reduce Panel must be open for you to use this function"
		Return(1)
	endif
	
	// convert the sample runs
	Wave/Z sruns = $"root:myGlobals:MRED:SampleRuns"
	slist = RunListToSequence(sruns, 0)
	
	// the empty runs is a string list so convert to a list of numbers and use 
	// 0 as the empty value
	Wave/T/Z eruns = $"root:myGlobals:MRED:EmptyRuns"
	Variable ix, num = numpnts(eruns)
	MAKE/U/O/N=(num) temp 
	for (ix = 0; ix < num; ix += 1)
		String run = eruns[ix]
		if (cmpstr(run,"") != 0)
			temp[ix] = str2num(run)
		else
			temp[ix] = 0
		endif
	endfor
	elist = RunListToSequence(temp, 0)
	
	// copy the act run list to the table
	String/G root:myGlobals:MRED:actSampleRuns = slist
	String/G root:myGlobals:MRED:actEmptyRuns = elist
	
	return(0)
End

// - to create a table of scattering runs at an input SDD
Proc CreateScatteringAtSDDTable(SDD_to_Filter)
	Variable SDD_to_Filter
	
	NewDataFolder/O root:myGlobals:MRED
	DoWindow/F CatMRTable
	If(V_Flag==0)
		CreateMRTable()
		SetDataFolder root:
	Else
		ClearMRTable()
	Endif

	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	//remove version numbers from semicolon-delimited list
	list =  RemoveVersNumsFromList(list)
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
		tempName = FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			//if(str2num(partialName) == NaN) // will always be false [davidm]
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				GetHeaderInfoToSDDWave(fullName,tempName,"","")
				// add the scale factor
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
	WAVE SampleRuns = $"root:myGlobals:MRED:SampleRuns"
	WAVE/T EmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	WAVE/T Suffix = $"root:myGlobals:MRED:Suffix"
	WAVE/T Labels = $"root:myGlobals:MRED:Labels"
	WAVE SDD = $"root:myGlobals:MRED:SDD"
	WAVE IsTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(Labels),ii,loc
	ii=num-1
	do
		loc = strsearch(labels[ii], findThisStr, 0 ,2)		//2==case insensitive, but Igor 5 specific
		if(loc != -1)
			Print "Remove w[ii] = ",num,"  ",labels[ii]
			DeletePoints ii, 1, SampleRuns,EmptyRuns,Suffix,Labels,SDD,IsTrans
		endif
		ii-=1
	while(ii>=0)
	return(0)
End		

// need fuzzy comparison, since SDD = 1.33 may actually be represented in FP as 1.33000004	!!!
//
Function RemoveWrongSDDFromSDDList(tSDD)
	Variable tSDD
	
	WAVE SampleRuns = $"root:myGlobals:MRED:SampleRuns"
	WAVE/T EmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	WAVE/T Suffix = $"root:myGlobals:MRED:Suffix"
	WAVE/T Labels = $"root:myGlobals:MRED:Labels"
	WAVE SDD = $"root:myGlobals:MRED:SDD"
	WAVE IsTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(sdd),ii,tol = 0.1
	ii=num-1
	do
//		if(abs(sdd[ii] - tSDD) > tol)		//if numerically more than 0.001 m different, they're not the same
//			DeletePoints ii, 1, SampleRuns,EmptyRuns,Suffix,Labels,SDD,IsTrans
//		endif
		if(trunc(abs(sdd[ii] - tSDD)) > tol)		//just get the integer portion of the difference - very coarse comparison
			DeletePoints ii, 1, SampleRuns,EmptyRuns,Suffix,Labels,SDD,IsTrans
		endif
		ii-=1
	while(ii>=0)
	
	// now sort
	Sort SampleRuns, SampleRuns,EmptyRuns,Suffix,Labels,SDD,IsTrans
	return(0)
End


Function RemoveTransFilesFromSDDList()
	WAVE SampleRuns = $"root:myGlobals:MRED:SampleRuns"
	WAVE/T EmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	WAVE/T Suffix = $"root:myGlobals:MRED:Suffix"
	WAVE/T Labels = $"root:myGlobals:MRED:Labels"
	WAVE SDD = $"root:myGlobals:MRED:SDD"
	WAVE IsTrans = $"root:myGlobals:MRED:IsTrans"
	
	Variable num=numpnts(isTrans),ii
	ii=num-1
	do
		if(isTrans[ii] != 0)
			DeletePoints ii, 1, SampleRuns,EmptyRuns,Suffix,Labels,SDD,IsTrans
		endif
		ii-=1
	while(ii>=0)
	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function GetHeaderInfoToSDDWave(fname,sname,ename, empscale)
	String fname,sname,ename,empscale
	
	String textstr,temp,lbl,date_time,suffix
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick,xcenter,ycenter,numatten
	Variable lastPoint, beamstop

	Wave/T GSuffix = $"root:myGlobals:MRED:Suffix"
	Wave/T GLabels = $"root:myGlobals:MRED:Labels"
	Wave GSDD = $"root:myGlobals:MRED:SDD"
	Wave GSampleRuns = $"root:myGlobals:MRED:SampleRuns"
	Wave/T GEmptyRuns = $"root:myGlobals:MRED:EmptyRuns"
	Wave/T GScaleEMP = $"root:myGlobals:MRED:Scale"
	Wave GIsTrans = $"root:myGlobals:MRED:IsTrans"
	
	lastPoint = numpnts(GSampleRuns)
		
	//the run number
	InsertPoints lastPoint,1,GSampleRuns
	GSampleRuns[lastPoint] = GetRunNumFromFile(sname)

	//the empty runs are left as text as they may be empty
	InsertPoints lastPoint,1,GEmptyRuns
	If (cmpstr(ename,"")!= 0) 
		GEmptyRuns[lastPoint] = num2istr(GetRunNumFromFile(ename))
	Else
		GEmptyRuns[lastPoint] = ""
	EndIf
	
	// add the scale factor 
	InsertPoints lastPoint,1,GScaleEMP
	GScaleEMP[lastPoint] = empscale
	
	//read the file suffix
	InsertPoints lastPoint,1,GSuffix
	GSuffix[lastPoint]=getSuffix(fname)

	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleLabel(fname)
	
	//read in the SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]= getSDD(fname)
		
	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = isTransFile(fname)		//returns one if beamstop is "out"
	
	KillWaves/Z w
	return(0)
End
