#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//************************
//	Vers. 1.2 092101
//
//7/2001 converted protocols to simply use the filenames, rather than the path:filename
//this should allow portability of the protocols between machines
//**ALL** protocols now depend on the path "catPathName"
//
//procedure files for construction of protocols interactively,
//selecting files from the CAT/VSHORT table, rather than picking blindly
//from a dialog - the process of selecting/setting files is not as 
//transparent as it could be for new users
//
//*************************
//////////////////////////////////
//
//		KEYWORD=<value> lists used in protocol definitions
//
//		KEYWORDS are ALWAYS capitalized, and yes, it does matter
//
//		for ABSOLUTE parameters
//		(4) possible keywords, all with numerical values
//		TSTAND=value		transmission of the standard
//		DSTAND=value		thickness of the standard, in centimeters
//		IZERO=value		I(q=0) value for the standard, in normalized neutron counts
//		XSECT=value		calibrated cross-section of the standard sample
//
// 		For calibration with a transmission file, set TSTAND, DSTAND, and XSECT to 1.0
//		and set IZERO to KAPPA (defined in Tania's handout, or in documentation of MRED_KAP on VAX)
//
//
//		For AVERAGE and for DRAWING
//			DRAWING routines only use a subset of the total list, since saving, naming, etc. don't apply
//		(10) possible keywords, some numerical, some string values
//		AVTYPE=string		string from set {Circular,Annular,Rectangular,Sector,2D_ASCII,QxQy_ASCII,PNG_Graphic;Sector_PlusMinus;}
//		PHI=value			azimuthal angle (-90,90)
//		DPHI=value			+/- angular range around phi for average
//		WIDTH=value		total width of rectangular section, in pixels
//		SIDE=string		string from set {left,right,both} **note NOT capitalized
//		QCENTER=value		q-value (1/A) of center of annulus for annular average
//		QDELTA=value		total width of annulus centered at QCENTER
//		PLOT=string		string from set {Yes,No} = truth of generating plot of averaged data
//		SAVE=string		string from set {Yes,No} = truth of saving averaged data to disk
//		NAME=string		string from set {Auto,Manual} = Automatic name generation or Manual(dialog)
//
//
//		For work.DRK usage:
//		**the list is COMMA delimited, soparator is =
//		DRK=none,DRKMODE=0,
//		DRK=name 			is the name of the file, must be a full name, expected to be raw data
//		DRKMODE=value		is a numeric value (0 or 10 to add to the Correct(mode) switch (unused?)
//
//////////////////////////////////


//main entry procedure for initialzing and displaying the protocol panel
// initilaizes folders and globals as needed
//
Proc ReductionProtocolPanel()
	DoWindow/F ProtocolPanel
	if(V_flag==0)
		InitProtocolPanel()
		ProtocolPanel()
	Endif
End

//initialization procedure for the protocol panel
//note that :gAbsStr is also shared (common global) to that used in 
//the questionnare form of the protcol (see protocol.ipf)
//
//0901, uses 8 points in protocol wave
Proc InitProtocolPanel()

	//set up the global variables needed for the protocol panel
	//global strings to put in a temporary protocol textwave
	Variable ii=0,nsteps=8
	String waveStr="tempProtocol"
	SetDataFolder root:myGlobals:Protocols
	Make/O/T/N=(nsteps) $"root:myGlobals:Protocols:tempProtocol" = ""

	String/G root:myGlobals:Protocols:gSAM="ask"
	String/G root:myGlobals:Protocols:gBGD="ask"
	String/G root:myGlobals:Protocols:gEMP="ask"
	String/G root:myGlobals:Protocols:gDIV="ask"
	String/G root:myGlobals:Protocols:gMASK="ask"
	String/G root:myGlobals:Protocols:gAbsStr="ask"
	String/G root:myGlobals:Protocols:gAVE="AVTYPE=Circular;SAVE=Yes;NAME=Auto;PLOT=Yes;"
	String/G root:myGlobals:Protocols:gDRK="DRK=none,DRKMODE=0,"
	
	SetDataFolder root:
	
End

//button control to create a CAT/SHORT notebook listing of all data files
//in the selected folder (catPathName)
//
Function DoCatShort(ctrlName) : ButtonControl
	String ctrlName

	Execute "BuildCatVeryShortTable()"
	
End

//button procedure to reset the panel seletctions/checks...etc...
//to reflect the choices in a previously saved protocol
// - parses through the protocol and resets the appropriate global strings and
//updates the panel display
//
Function RecallProtocolButton(ctrlName) : ButtonControl
	String ctrlName

	//will reset panel values based on a previously saved protocol
	//pick a protocol wave from the Protocols folder
	//MUST move to Protocols folder to get wavelist
	SetDataFolder root:myGlobals:Protocols
	Execute "PickAProtocol()"
	
	//get the selected protocol wave choice through a global string variable
	SVAR protocolName = root:myGlobals:Protocols:gProtoStr

	//If "CreateNew" was selected, ask user to try again
	if(cmpstr("CreateNew",protocolName) == 0)
		Abort "CreateNew is for making a new Protocol. Select a previously saved Protocol"
	Endif
	
	//reset the panel based on the protocol textwave (currently a string)
	ResetToSavedProtocol(protocolName)
	
	SetDataFolder root:
	return(0)
End

//deletes the selected protocol from the list and from memory
//
Function DeleteProtocolButton(ctrlName) : ButtonControl
	String ctrlName

	//put up a list of protocols and pick one
	SetDataFolder root:myGlobals:Protocols
//	Execute "DeleteAProtocol()"
	String Protocol=""
	Prompt Protocol "Delete A Protocol",popup, DeletableProtocols()
	DoPrompt "Select protocol to delete",protocol
	If(V_flag==1)
		return(0)
	endif

	//If "CreateNew, Base, DoAll, or tempProtocol" was selected, do nothing
	strswitch(protocol)
		case "CreateNew":
			break
		case "DoAll":
			break
		case "Base":
			break
		case "tempProtocol":
			break
		default:
			//delete the protocol
			KillWaves/Z $protocol
	endswitch
	
	SetDataFolder root:
	return(0)
End


//function that actually parses the protocol specified by nameStr
//which is just the name of the wave, without a datafolder path
//
Function ResetToSavedProtocol(nameStr)
	String nameStr
	
	//allow special cases of Base and DoAll Protocols to be recalled to panel - since they "ask"
	//and don't need paths
	
	String catPathStr
	PathInfo catPathName
	catPathStr=S_path
	
	//SetDataFolder root:myGlobals:Protocols		//on windows, data folder seems to get reset (erratically) to root: 
	Wave/T w=$("root:myGlobals:Protocols:" + nameStr)
	
	String fullPath="",comma=",",list="",nameList="",PathStr="",item=""
	Variable ii=0,numItems,checked,specialProtocol
	
	if((cmpstr(nameStr,"Base")==0) || (cmpstr(nameStr,"DoAll")==0))
		specialProtocol = 1
	else
		specialProtocol = 0
	Endif
	
	//background
	checked = 1
	nameList = w[0]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gBGD = nameList
	CheckBox prot_check win=ProtocolPanel,value=checked
	
	//empty
	checked = 1
	nameList = w[1]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gEMP = nameList
	CheckBox prot_check_1 win=ProtocolPanel,value=checked
	
	//DIV file
	checked = 1
	nameList = w[2]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gDIV = nameList
	CheckBox prot_check_2 win=ProtocolPanel,value=checked
	
	//Mask file
	checked = 1
	nameList = w[3]
	If(cmpstr(nameList,"none") ==0)
		checked = 0
	Endif

	//set the global string to display and checkbox
	String/G root:myGlobals:Protocols:gMASK = nameList
	CheckBox prot_check_3 win=ProtocolPanel,value=checked
	
	//4 = abs parameters
	list = w[4]
	numItems = ItemsInList(list,";")
	checked = 1
	if(numitems == 4 || numitems == 5)		//allow for protocols with no SDEV list item
		//correct number of parameters, assume ok
		String/G root:myGlobals:Protocols:gAbsStr = list
		CheckBox prot_check_9 win=ProtocolPanel,value=checked
	else
		item = StringFromList(0,list,";")
		if(cmpstr(item,"none")==0)
			checked = 0
			list = "none"
			String/G root:myGlobals:Protocols:gAbsStr = list
			CheckBox prot_check_9 win=ProtocolPanel,value=checked
		else
			//force to "ask"
			checked = 1
			String/G root:myGlobals:Protocols:gAbsStr = "ask"
			CheckBox prot_check_9 win=ProtocolPanel,value=checked
		Endif
	Endif
	
	//5 = averaging choices
	list = w[5]
	item = StringByKey("AVTYPE",list,"=",";")
	if(cmpstr(item,"none") == 0)
		checked = 0
		String/G root:myGlobals:Protocols:gAVE = "none"
		CheckBox prot_check_5 win=ProtocolPanel,value=checked
	else
		checked = 1
		String/G root:myGlobals:Protocols:gAVE = list
		CheckBox prot_check_5 win=ProtocolPanel,value=checked
	Endif
	
	//6 = DRK choice
	list = w[6]
	item = StringByKey("DRK",list,"=",",")
	//print list,item
	if(cmpstr(item,"none") == 0)
		checked = 0
		String/G root:myGlobals:Protocols:gDRK = list
		CheckBox prot_check_6 win=ProtocolPanel,value=checked
	else
		checked = 1
		String/G root:myGlobals:Protocols:gDRK = list
		CheckBox prot_check_6 win=ProtocolPanel,value=checked
	Endif
	
	//7 = unused
	
	//all has been reset, get out
	Return (0)
End

//button action procedure that simply closes the panel
//
Function DoneProtocolButton(ctrlName) : ButtonControl
	String ctrlName

	//will gracefully close and exit the protocol panel
	
	DoWindow/K ProtocolPanel
End

//button action procedure that saves the current choices on the panel
//as a named protocol, for later recall
//asks for a valid name, then creates a protocol from the panel choices
//creates a wave, and sets the current protocol name to this new protocol
//
//now allows the user the choice to overwrite a protocol
//
Function SaveProtocolButton(ctrlName) : ButtonControl
	String ctrlName

	Variable notDone=1, newProto=1
	//will prompt for protocol name, and save the protocol as a text wave
	//prompt for name of new protocol wave to save
	do
		Execute "AskForName()"
		SVAR newProtocol = root:myGlobals:Protocols:gNewStr
		
		//make sure it's a valid IGOR name
		newProtocol = CleanupName(newProtocol,0)	//strict naming convention
		String/G root:myGlobals:Protocols:gNewStr=newProtocol		//reassign, if changed
		Print "newProtocol = ",newProtocol
		
		SetDataFolder root:myGlobals:Protocols
		if(WaveExists( $("root:myGlobals:Protocols:" + newProtocol) ) == 1)
			//wave already exists
			DoAlert 1,"That name is already in use. Do you wish to overwrite the existing protocol?"
			if(V_Flag==1)
				notDone = 0
				newProto = 0
			else
				notDone = 1
			endif
		else
			//name is good
			notDone = 0
		Endif
	while(notDone)
	
	//current data folder is  root:myGlobals:Protocols
	if(newProto)
		Make/O/T/N=8 $("root:myGlobals:Protocols:" + newProtocol)
	Endif
	
	MakeProtocolFromPanel( $("root:myGlobals:Protocols:" + newProtocol) )
	String/G  root:myGlobals:Protocols:gProtoStr = newProtocol
	
	//the data folder WAS changed above, this must be reset to root:
	SetDatafolder root:
End

//function that does the guts of reading the panel controls and globals
//to create the necessary text fields for a protocol
//Wave/T w (input) is an empty text wave of 8 elements for the protocol
//on output, w[] is filled with the protocol strings as needed from the panel 
//
Function MakeProtocolFromPanel(w)
	Wave/T w
	
	//construct the protocol text wave form the panel
	//it is to be parsed by ExecuteProtocol() for the actual data reduction
	PathInfo catPathName			//this is where the files came from
	String pathstr=S_path,tempStr,curList
	Variable checked,ii,numItems
	
	//look for checkbox, then take each item in list and prepend the path
	//w[0] = background
	ControlInfo/W=ProtocolPanel prot_check
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gBGD
		if(cmpstr(str,"ask")==0)
			w[0] = str		//just ask
		else
			tempstr = ParseRunNumberList(str)
			if(strlen(tempStr)==0)
				return(1)				//error parsing list
			else
				w[0] = tempstr
				str = tempstr		//set the protocol and the global
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[0] = "none"
		String/G root:myGlobals:Protocols:gBGD = "none"
	endif
	
	//w[1] = empty
	ControlInfo/W=ProtocolPanel prot_check_1
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gEMP
		if(cmpstr(str,"ask")==0)
			w[1] = str
		else
			tempstr = ParseRunNumberList(str)
			if(strlen(tempStr)==0)
				return(1)
			else
				w[1] = tempstr
				str=tempStr
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[1] = "none"
		String/G root:myGlobals:Protocols:gEMP = "none"
	endif
	
	//w[2] = div file
	ControlInfo/W=ProtocolPanel prot_check_2
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gDIV
		if(cmpstr(str,"ask")==0)
			w[2] = str
		else
			tempStr = ParseRunNumberList(str)
			if(strlen(tempStr)==0)
				return(1)
			else
				w[2] = tempstr
				str=tempstr
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[2] = "none"
		String/G root:myGlobals:Protocols:gDIV = "none"
	endif
	
	//w[3] = mask file
	ControlInfo/W=ProtocolPanel prot_check_3
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gMASK
		if(cmpstr(str,"ask")==0)
			w[3] = str
		else
			tempstr = ParseRunNumberList(str)
			if(strlen(tempstr)==0)
				return(1)
			else
				w[3] = tempstr
				str = tempstr
			endif
		endif
	else
		//none used - set textwave (and global?)
		w[3] = "none"
		String/G root:myGlobals:Protocols:gMASK = "none"
	endif
	
	//w[4] = abs parameters
	ControlInfo/W=ProtocolPanel prot_check_9
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str=root:myGlobals:Protocols:gAbsStr
		w[4] = str
	else
		//none used - set textwave (and global?)
		w[4] = "none"
		String/G root:myGlobals:Protocols:gAbsStr = "none"
	endif
	
	//w[5] = averaging choices
	ControlInfo/W=ProtocolPanel prot_check_5			//do the average?
	checked = V_value
	if(checked)
		//just read the global
		SVAR avestr=root:myGlobals:Protocols:gAVE
		w[5] = avestr
	else
		//none used - set textwave
		w[5] = "AVTYPE=none;"
	endif
	
	//w[6]
	//work.DRK information
	SVAR drkStr=root:myGlobals:Protocols:gDRK
	w[6] = drkStr
	
	//w[7]
	//currently unused
	w[7] = ""
	
	return(0)
End


//button control function to set the background (SAM) file name to the 
//selected name in the CAT/SHORT window
//the version number of the file need not be selected, it will be added later if needed
//multiple SAMple files can be added together if the list is not reset
//
Function PickSAMButton(ctrlName) : ButtonControl
	String ctrlName

	//set the SAM file(s) as a global string
	//multiple files are added as a COMMA separated list of files, w/extension
	//global string is either null or contains filename(s) on entry
	
	//ask to reset the list?
	DoAlert 2,"Reset the list of sample files?"
	if(V_flag == 3)
		return(0)		//cancel, get out
	endif
	if(V_flag == 1)
		String/G root:myGlobals:Protocols:gSAM = ""
	Endif
	
	Variable catVSTableExists, num_sans_files
	catVSTableExists = WinType("catVSTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	if (catVSTableExists != 0)
		GetSelection table,CatVSTable,7
		if(strsearch(S_selection,"Filenames",0) == 0)
		   //selection OK, add to list
          Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
          Wave/T selectedFiles = $"filenames"
          num_sans_files = numpnts(selectedFiles)
		   SVAR temp = root:myGlobals:Protocols:gSAM
          Variable ii=0
          do
            temp = temp+selectedFiles[ii]+","
            ii+=1
          while (ii < num_sans_files)
      Else
		   		DoAlert 0,"Invalid selection from the File Catalog window"
      Endif
	else
		//no selection
		String/G root:myGlobals:Protocols:gSAM = "ask"
		DoAlert 0,"No file selected from File Catalog table or no File Catalog table available"
	Endif
	return(0)
End

//button control to set the background (BGD) file name to the 
//selected name in the CAT/SHORT window
//the version number of the file need not be selected, it will be added later if needed
//multiple BGD files can be added together if the file list is not reset
//
Function PickBGDButton(ctrlName) : ButtonControl
	String ctrlName

	//set the BGD file(s) as a global string
	//multiple files are added as a COMMA separated list of files, w/extension
	//global string is either null or contains filename(s) on entry
	
	//ask to reset the list?
	DoAlert 2,"Reset the list of background files?"
	if(V_flag == 3)
		return(0)		//cancel, get out
	endif
	if(V_flag == 1)
		String/G root:myGlobals:Protocols:gBGD = ""
	Endif

	Variable catVSTableExists, num_sans_files
	catVSTableExists = WinType("CatVSTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	if (catVSTableExists != 0)
		GetSelection table,CatVSTable,7
		if(strsearch(S_selection,"Filenames",0) == 0)
	   //selection OK, add to list
		   Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
		   Wave/T selectedFiles = $"filenames"
		   num_sans_files = numpnts(selectedFiles)
		   SVAR temp = root:myGlobals:Protocols:gBGD
			Variable ii=0
			do
				temp = temp+selectedFiles[ii]+","
				ii+=1
			while (ii < num_sans_files)
		Else
			DoAlert 0,"Invalid selection from the File Catalog table"
		Endif
	else
		//no selection
		DoAlert 0,"No file selected from File Catalog table or no File Catalog table available"
	Endif
	
End

//button control function to set the background (EMP) file name to the 
//selected name in the CAT/SHORT window
//the version number of the file need not be selected, it will be added later if needed
//multiple EMP files can be added together if the file list is not reset
//
Function PickEMPButton(ctrlName) : ButtonControl
	String ctrlName

	//ask to reset the list?
	DoAlert 2,"Reset the list of empty cell files?"
	if(V_flag == 3)
		return(0)		//cancel, get out
	endif
	if(V_flag == 1)
		String/G root:myGlobals:Protocols:gEMP = ""
	Endif
	
	Variable catVSTableExists, num_sans_files
	catVSTableExists = WinType("catVSTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	if (catVSTableExists != 0)
		GetSelection table,CatVSTable,7
		if(strsearch(S_selection,"Filenames",0) == 0)
		   //selection OK, add to list
      		Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
       	Wave/T selectedFiles = $"filenames"
      		num_sans_files = numpnts(selectedFiles)
      		SVAR temp = root:myGlobals:Protocols:gEMP
   			Variable ii=0
			do
				temp = temp+selectedFiles[ii]+","
				ii+=1
			while (ii < num_sans_files)
		Else
			DoAlert 0,"Invalid selection from the File Catalog table"
		Endif
	else
		//no selection
		DoAlert 0,"No file selected from File Catalog table or no File Catalog table available"
	Endif
	
End

//button control function to set the background (DIV) file name to the 
//selected name in the CAT/SHORT window
//the version number of the file need not be selected, it will be added later if needed
//there can only be one DIV file for a given protocol
//
Function PickDIVButton(ctrlName) : ButtonControl
	String ctrlName

	//alwys reset the list of DIV files, there can be only one
	String/G root:myGlobals:Protocols:gDIV = ""
	Variable catVSTableExists, num_sans_files
	catVSTableExists = WinType("catVSTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	if (catVSTableExists != 0)
		GetSelection table,CatVSTable,7
		if(strsearch(S_selection,"Filenames",0) == 0)
		   //selection OK, add to list
       	Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
    		Wave/T selectedFiles = $"filenames"
    	   num_sans_files = numpnts(selectedFiles)            
		   SVAR temp = root:myGlobals:Protocols:gDIV
   			temp = selectedFiles[0]
  		Else
			DoAlert 0,"Invalid selection from the File Catalog table"
   		Endif
	else
		//no selection
		DoAlert 0,"No file selected from File Catalog table or no File Catalog table available"
	Endif
	
End

//button control function to set the background (MSK) file name to the 
//selected name in the CAT/SHORT window
//the version number of the file need not be selected, it will be added later if needed
//there can only be one MSK file for a given protocol
//
Function PickMASKButton(ctrlName) : ButtonControl
	String ctrlName
	
	//always reset the list of MASK files - ther can be only one
	String/G root:myGlobals:Protocols:gMASK = ""
	
	Variable catVSTableExists, num_sans_files
	catVSTableExists = WinType("catVSTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:CatVSHeaderInfo:Filenames"
	if (catVSTableExists != 0)
		GetSelection table,CatVSTable,7
		if(strsearch(S_selection,"Filenames",0) == 0)
			//selection OK, add to list
	    	Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
	    	Wave/T selectedFiles = $"filenames"
	    	num_sans_files = numpnts(selectedFiles)           
			SVAR temp = root:myGlobals:Protocols:gMASK
	   		temp = selectedFiles[0]
     	Else
			DoAlert 0,"Invalid selection from the File Catalog table"
   		Endif
	else
		//no selection
		DoAlert 0,"No file selected from File Catalog table or no File Catalog table available"
	Endif
	
End

//button action function to reduce one file with the information specified on
//the panel
//a temporary protocol is created, even if the fields correspond to a named protocol
//(only the protocol wave values are written to the data header, but the name is written to the 
//schematic - this could cause some unwanted confusion)
//
//if a sample file(s) is selected, only that file(s) will be reduced
//if no file is selected, the user will be prompted with a standard open
//dialog to select sample data file(s)
//
Function ReduceOneButton(ctrlName) : ButtonControl
	String ctrlName

	//parse the information on the panel and assign to tempProtocol wave (in protocol folder)
	//and execute
	String temp="root:myGlobals:Protocols:tempProtocol"
	Wave/T w=$temp
	Variable ii=0,num=8
	do
		w[ii] = ""
		ii+=1
	while(ii<num)
	
	MakeProtocolFromPanel(w)

	//the "current" protocol is the "tempProtocol" that was parsed from the panel input
	//set the global, so that the data writing routine can find the protocol wave (fatal otherwise)
	String/G root:myGlobals:Protocols:gProtoStr="tempProtocol"
	
	PathInfo catPathName			//this is where the files came from
	String pathstr=S_path,samStr
	
	//take the string from the panel
	SVAR tempStr = root:myGlobals:Protocols:gSAM
	
	if( (strlen(tempStr) == 0) || (cmpstr(tempStr,"ask")==0) )
		//let user select the files
		tempStr="ask"
		ExecuteProtocol(temp,tempStr)
		return(0)
	Else
		//parse the list of numbers
		//send only the filenames, without paths
		samStr = ParseRunNumberList(tempStr)
		If(strlen(samStr)==0)
			DoAlert 0,"The SAM file number cound not be interpreted. Please enter a valid run number or filename"
			return(1)
		endif
		tempStr=samStr		//reset the global
		ExecuteProtocol(temp,samStr)
		return(0)
	endif
End


//button action function will prompt user for absolute scaling parameters
//either from an empty beam file or by manually entering the 4 required values
//uses the same function and shared global string as the questionnare form of reduction
//in "protocol.ipf" - the string is root:myGlobals:Protocols:gAbsStr
//
Function SetABSParamsButton(ctrlName) : ButtonControl
	String ctrlName

	//will prompt for a list of ABS parameters (4) through a global string variable
	
	Execute "AskForAbsoluteParams_Quest()"
	
End

//simple button action procedure to bring the CAT/SHORT notebook window to the front
//in case it's buried behind other windows
//
Function ShowCATButton(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/F CatVSTable
	if(V_flag==0)
		DoAlert 0,"There is no File Catalog table window. Use the File Catalog table button to create one."
	Endif
	
End

//the panel recreation macro
//
Window ProtocolPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(553,48,851,500) /K=1 as "Data Reduction Protocol"
	ModifyPanel cbRGB=(27589,43441,64159), fixedSize=1
	SetDrawLayer UserBack
	DrawLine 2,25,300,25
	DrawLine 2,69,300,69
	DrawLine 2,120,300,120
	DrawLine 2,169,300,169
	DrawLine 2,217,300,217
	DrawLine 2,262,300,262
	DrawLine 2,357,300,357
	DrawLine 2,379,300,379
	DrawLine 2,308,300,308
	Button button0,pos={12,2},size={90,20},proc=DoCatShort,title="File Catalog"
	Button button0,help={"Use this button to generate a catalog of raw data file headers. Select files from the list for EMP, BGD,..."}
	Button button_help,pos={260,2},size={25,20},proc=ShowProtoHelp,title="?"
	Button button_help,help={"Show the help file for setting up a reduction protocol"}
	CheckBox prot_check,pos={5,75},size={74,14},title="Background"
	CheckBox prot_check,help={"If checked, the specified background file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check,value= 1
	Button pick_bgd,pos={114,75},size={100,20},proc=PickBGDButton,title="set BGD file"
	Button pick_bgd,help={"This button will set the file selected in the File Catalog table to be the background file."}
	Button recallProt,pos={7,406},size={107,20},proc=RecallProtocolButton,title="Recall Protocol"
	Button recallProt,help={"Resets the panel to the file choices in  a previously saved protocol"}
	Button del_protocol,pos={7,428},size={110,20},proc=DeleteProtocolButton,title="Delete Protocol"
	Button del_protocol,help={"Use this to delete a previously saved protocol."}
	Button done_protocol,pos={225,428},size={45,20},proc=DoneProtocolButton,title="Done"
	Button done_protocol,help={"This button will close the panel. The panel can be recalled at any time from the SANS menu."}
	Button saveProtocol,pos={7,384},size={100,20},proc=SaveProtocolButton,title="Save Protocol"
	Button saveProtocol,help={"Saves the cerrent selections in the panel to a protocol which can be later recalled"}
	CheckBox prot_check_1,pos={5,127},size={71,14},title="Empty Cell"
	CheckBox prot_check_1,help={"If checked, the specified empty cell file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_1,value= 1
	CheckBox prot_check_2,pos={6,175},size={72,14},title="Sensitivity"
	CheckBox prot_check_2,help={"If checked, the specified detector sensitivity file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_2,value= 1
	CheckBox prot_check_3,pos={9,268},size={43,14},title="Mask"
	CheckBox prot_check_3,help={"If checked, the specified mask file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_3,value= 1
	Button pick_emp,pos={113,125},size={100,20},proc=PickEMPButton,title="set EMP file"
	Button pick_emp,help={"This button will set the file selected in the File Catalog table to be the empty cell file."}
	Button pick_DIV,pos={114,173},size={100,20},proc=PickDIVButton,title="set DIV file"
	Button pick_DIV,help={"This button will set the file selected in the File Catalog table to be the sensitivity file."}
	Button pick_MASK,pos={119,266},size={100,20},proc=PickMASKButton,title="set MASK file"
	Button pick_MASK,help={"This button will set the file selected in the File Catalog table to be the mask file."}
	SetVariable bgdStr,pos={7,98},size={250,15},title="file:"
	SetVariable bgdStr,help={"Filename of the background file(s) to be used in the data reduction"}
	SetVariable bgdStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gBGD
	SetVariable empStr,pos={8,148},size={250,15},title="file:"
	SetVariable empStr,help={"Filename of the empty cell file(s) to be used in the data reduction"}
	SetVariable empStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gEMP
	SetVariable divStr,pos={9,197},size={250,15},title="file:"
	SetVariable divStr,help={"Filename of the detector sensitivity file to be used in the data reduction"}
	SetVariable divStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gDIV
	SetVariable maskStr,pos={9,289},size={250,15},title="file:"
	SetVariable maskStr,help={"Filename of the mask file to be used in the data reduction"}
	SetVariable maskStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gMASK
	Button ReduceOne,pos={194,384},size={100,20},proc=ReduceOneButton,title="Reduce A File"
	Button ReduceOne,help={"Using the panel selections, the specified sample file will be reduced. If none is specified, the user will be prompted for a sample file"}
	CheckBox prot_check_4,pos={5,30},size={53,14},title="Sample"
	CheckBox prot_check_4,help={"If checked, the specified sample file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_4,value= 1
	Button pick_sam,pos={115,28},size={100,20},proc=PickSAMButton,title="set SAM file"
	Button pick_sam,help={"This button will set the file selected in the File Catalog table to be the sample file"}
	SetVariable samStr,pos={6,50},size={250,15},title="file:"
	SetVariable samStr,help={"Filename of the sample file(s) to be used in the data reduction"}
	SetVariable samStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gSAM
	Button pick_ABS,pos={115,220},size={110,20},proc=SetABSParamsButton,title="set ABS params"
	Button pick_ABS,help={"This button will prompt the user for absolute scaling parameters"}
	CheckBox prot_check_9,pos={7,222},size={59,14},title="Absolute"
	CheckBox prot_check_9,help={"If checked, absolute calibration will be included in the data reduction. If the parameter list is \"ask\", then the user will be prompted for absolue parameters"}
	CheckBox prot_check_9,value= 1
	SetVariable absStr,pos={7,243},size={250,15},title="parameters:"
	SetVariable absStr,help={"Keyword-string of values necessary for absolute scaling of data. Remaining parameters are taken from the sample file."}
	SetVariable absStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gAbsStr
	Button show_cat,pos={120,2},size={120,20},proc=ShowCATButton,title="Show File Catalog"
	Button show_cat,help={"Brings the current condensed File Catalog table to the front"}
	CheckBox prot_check_5,pos={6,311},size={56,14},title="Average"
	CheckBox prot_check_5,help={"If checked, the specified averaging will be performed at the end of the data reduction."}
	CheckBox prot_check_5,value= 1
	Button pick_AVE,pos={108,313},size={150,20},proc=SetAverageParamsButtonProc,title="set AVERAGE params"
	Button pick_AVE,help={"Prompts the user for the type of 1-D averaging to perform, as well as saving options"}
	SetVariable aveStr,pos={9,336},size={250,15},title="parameters:"
	SetVariable aveStr,help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
	SetVariable aveStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gAVE
	//only show DRK if user wants to see it 
	//if global = 1,then show => set disable = 0
	CheckBox prot_check_6,pos={6,363},size={113,14},proc=DrkCheckProc,title="Use DRK correction"
	CheckBox prot_check_6,help={"If checked, the selected file will be used for DRK correction. Typically this is NOT checked"}
	CheckBox prot_check_6,value= 0,disable = (!root:Packages:NIST:gAllowDRK)
	SetVariable drkStr,pos={120,363},size={150,15},title="."
	SetVariable drkStr,help={"DRK detector count file"},disable = (!root:Packages:NIST:gAllowDRK)
	SetVariable drkStr,limits={-Inf,Inf,0},value= root:myGlobals:Protocols:gDRK
	Button export_button, size={60,20},pos={125,384},title="Export",proc=ExportProtocol
	Button export_button, help={"Exports the protocol to disk for Importing into another experiment"}
	Button import_button, size={60,20},pos={125,406},title="Import",proc=ImportProtocol
	Button import_button,help={"Imports a protocol from disk for use in this experiment"}
EndMacro

//activated when user checks/unchecks the box
//either prompts for a file using a standard dialog, or removes the current file
Function DrkCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked		//Desired state, not previous state

	SVAR drkStr=root:myGlobals:Protocols:gDRK
	if(checked==1)
		//print "Unchecked on call"
		//this just asks for the filename, doesn't open the file
		String msgStr="Select the DRK file",fullPath="",fileStr=""
		Variable refnum
		
		Open/D/R/T="????"/M=(msgStr)/P=catPathName refNum
		fullPath = S_FileName		//fname is the full path
		if(cmpstr(fullpath,"")==0)
			//user cancelled
			CheckBox prot_check_6,value=0		//keep box unchecked
			return(0)
		Endif
		fileStr=GetFileNameFromPathNoSemi(fullPath)
		//Print fileStr
		//update the global string
		drkStr = ReplaceStringByKey("DRK",drkStr,fileStr,"=",",")
		drkStr = ReplaceNumberByKey("DRKMODE", drkStr, 10 ,"=",",")
	else
		//print "checked on call"
		drkStr="DRK=none,DRKMODE=0,"		//change the global
	endif
	
End


Function ShowProtoHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Build a Data Reduction Protocol]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button action procedure to get the type of average requested by the user
//presented as a missing parameter dialog, which is really user-UN-friendly
//and will need to be re-thought. Defaults of dialog are set for normal
//circular average, so typically click "continue" and proceed
//
Function SetAverageParamsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	Execute "GetAvgInfo()"
	
	//set the global string
	SVAR tempStr = root:myGlobals:Protocols:gAvgInfoStr
	String/G root:myGlobals:Protocols:gAVE = tempStr

End

//procedure called by protocol panel to ask user for average type choices
// somewhat confusing and complex, but may be as good as it gets.
//
Proc GetAvgInfo(av_typ,autoSave,autoName,autoPlot,side,phi,dphi,width,QCtr,QDelta)
	String av_typ,autoSave,AutoName,autoPlot,side
	Variable phi=0,dphi=10,width=10,Qctr = 0.01,qDelta=10
	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII;PNG_Graphic;Sector_PlusMinus;"
// comment out above line in DEMO_MODIFIED version, and uncomment the line below (to disable PNG save)
//	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII"
	Prompt autoSave,"Save files to disk?",popup,"Yes;No"
	Prompt autoName,"Auto-Name files?",popup,"Auto;Manual"
	Prompt autoPlot,"Plot the averaged Data?",popup,"Yes;No"
	Prompt side,"Include detector halves?",popup,"both;right;left"
	Prompt phi,"Orientation Angle (-90,90) degrees (Rectangular or Sector)"
	Prompt dphi, "Azimuthal range (0,45) degrees (Sector only)"
	Prompt width, "Width of Rectangular average (1,128)"
	Prompt Qctr, "q-value of center of annulus"
	Prompt Qdelta,"Pixel width of annulus"

	//assign results of dialog to key=value string, semicolon separated
	//do only what is necessary, based on av_typ
	String/G root:myGlobals:Protocols:gAvgInfoStr=""
	
	// all averages need these four values
	root:myGlobals:Protocols:gAvgInfoStr += "AVTYPE=" + av_typ + ";"
	root:myGlobals:Protocols:gAvgInfoStr += "SAVE=" + autoSave + ";"
	root:myGlobals:Protocols:gAvgInfoStr += "NAME=" + autoName + ";"
	root:myGlobals:Protocols:gAvgInfoStr += "PLOT=" + autoPlot + ";"
	
	if(cmpstr(av_typ,"Sector")==0 || cmpstr(av_typ,"Sector_PlusMinus")==0)
		root:myGlobals:Protocols:gAvgInfoStr += "SIDE=" + side + ";"
		root:myGlobals:Protocols:gAvgInfoStr += "PHI=" + num2str(phi) + ";"
		root:myGlobals:Protocols:gAvgInfoStr += "DPHI=" + num2str(dphi) + ";"
	Endif
	
	if(cmpstr(av_typ,"Rectangular")==0)
		root:myGlobals:Protocols:gAvgInfoStr += "SIDE=" + side + ";"
		root:myGlobals:Protocols:gAvgInfoStr += "PHI=" + num2str(phi) + ";"
		root:myGlobals:Protocols:gAvgInfoStr += "WIDTH=" + num2str(width) + ";"
	Endif
	
	if(cmpstr(av_typ,"Annular")==0)
		root:myGlobals:Protocols:gAvgInfoStr += "QCENTER=" + num2str(QCtr) + ";"
		root:myGlobals:Protocols:gAvgInfoStr += "QDELTA=" + num2str(QDelta) + ";"
	Endif
End

//not used????
//checks the syntax of all of the file fields in the panel
Function CheckProtocolSyntax(ctrlName) : ButtonControl
	String ctrlName
	
	String retStr=""
	//SAM
	SVAR list = root:myGlobals:Protocols:gSAM
	retStr = ParseRunNumberList(list)
	if(strlen(retStr)==0)
		//error
		Print "SAM Syntax Error"
		return(1)
	else
		list = retStr
		Print "SAM syntax OK"
	Endif

	//MASK
	SVAR list = root:myGlobals:Protocols:gMASK
	retStr = ParseRunNumberList(list)
	
End
//*************



//
// Procedure files for creating and executing a data reduction protocol
//
//**** ONLY invoked from the MAIN PANEL**** NOT REALLY EVER USED ******
//Procedure for reducing a sample file (multiple added files) with a specified
//protocol. User may create a new protocol, and will be prompted
//for information "questionnare-style" where the user must know the 
//filenames for empty cell, background...etc.. as they will be presented
//with standard file open dialogs to select each file desired for use in the
//new protocol
//once a protocol is selected (or created) the uer is propmted for sample data
// and the file is processed through the protocol.
//
Proc ReduceAFile()

	String protocolName="",waveStr="",samStr = "ask"
	Variable err
	
	//pick a protocol wave from the Protocols folder
	//must switch to protocols folder to get wavelist (missing parameter)
	SetDataFolder root:myGlobals:Protocols
	PickAProtocol()
	
	//get the selected protocol wave choice through a global string variable
	protocolName = root:myGlobals:Protocols:gProtoStr
	
	//If "CreateNew" was selected, go to the questionnare, to make a new set
	//and put the name of the new Protocol wave in gProtoStr
	if(cmpstr("CreateNew",protocolName) == 0)
		ProtocolQuestionnare()
		protocolName = root:myGlobals:Protocols:gProtoStr
	Endif
	
	//give the full path:name to the executeProtocol function
	waveStr = "root:myGlobals:Protocols:"+protocolName
	//samStr is set at top to "ask", since this is the action always desired from "ReduceAFile"
	
	ExecuteProtocol(waveStr,samStr)
	
	//return data folder to root before Macro is done
	SetDataFolder root:
	
End


//prompts the user to pick a previously created protocol from a popup list
//of given the option to create a new protocol
//the chosen protocol is passed back to the calling procedure by a global string
//the popup is presented as a missing parameter dialog (called with empty parameter list)
//
Proc PickAProtocol(protocol)
	String Protocol
	Prompt Protocol "Pick A Protocol",popup, WaveList("*",";","")
	
	String/G  root:myGlobals:Protocols:gProtoStr = protocol
End

Proc DeleteAProtocol(protocol)
	String Protocol
//	Prompt Protocol "Delete A Protocol",popup, WaveList("*",";","")
	Prompt Protocol "Delete A Protocol",popup, DeletableProtocols()

	String/G  root:myGlobals:Protocols:gProtoStr = protocol
End

Function/S DeletableProtocols()
	String list=WaveList("*",";","")

	list= RemoveFromList("Base", list  , ";")
	list= RemoveFromList("DoAll", list  , ";")
	list= RemoveFromList("CreateNew", list  , ";")
	list= RemoveFromList("tempProtocol", list  , ";")
	if(cmpstr(list,"")==0)
		list = "_no_protocols_;"
	endif
	
	return(list)
End

//missing paramater dialog to solicit user for a waveStr for the protocol 
//about to be created
//name is passed back as a global string and calling procedure is responsible for
//checking for wave conflicts and valid names
//
Proc AskForName(protocol)
	String Protocol
	Prompt Protocol "Enter a new name for your protocol (no extension)"
	
	String/G  root:myGlobals:Protocols:gNewStr = protocol
End

//this is a lengthy procedure for sequentially polling the user about what data
//reduction steps they want to be performed during the protocol
//ensures that a valid protocol name was chosen, then fills out each "item"
//(6 total) needed for reduction
//it the user cancels at any point, the partial protocol will be deleted
//
Function ProtocolQuestionnare()
	String filename,cmd
	Variable notDone,refnum
	
	//prompt for name of new protocol wave to save
	do
		Execute "AskForName()"
		SVAR newProtoStr = root:myGlobals:Protocols:gNewStr
		
		//make sure it's a valid IGOR name
		newProtoStr = CleanupName(newProtoStr,0)	//strict naming convention
		String/G root:myGlobals:Protocols:gNewStr=newProtoStr		//reassign, if changed
		//Print "newProtoStr = ",newProtoStr
		
		SetDataFolder root:myGlobals:Protocols
		if(WaveExists( $("root:myGlobals:Protocols:" + newProtoStr) ) == 1)
			//wave already exists
			DoAlert 0,"that name is already in use. Please pick a new name"
			notDone = 1
		else
			//name is  good
			notDone = 0
		Endif
	while(notDone)
	
	//Print "protocol questionnare is "+newProtocol
	
	//make a new text wave (6 points) and fill it in, in response to questions
	SetDataFolder root:myGlobals:Protocols //(redundant - full wave specs are used)
	Make/O/T/N=8 $("root:myGlobals:Protocols:" + newProtoStr)
	Wave/T newProtocol = $("root:myGlobals:Protocols:" + newProtoStr)
	
	//ask the questions 
	/////
	//*****Multiple files in these lists are full paths/filenames which may or may not
	//have semicolon version numbers in the filename. Therefore, construct the list with
	//COMMAS as separators - to avoid messy parsing
	///////
	
	
//////////////////////////
	String drkStr="",fileStr=""
	DoAlert 1,"Do you want to correct your data for DRK (beam off) counts?"
	if(V_flag == 1)		//1=yes
		//prompt for DRK  file, but don't actually open it (/D flag)
		Open/D/R/T="TEXT????"/M="Select the DRK file"/P=catPathName refnum
		//check for cancel
		if(strlen(S_filename)==0)
			//user cancelled, abort
			KillWaves/Z newProtocol
			SetDataFolder root:
			Abort "Incomplete protocol has been deleted"
		Endif
		//assign filename (just the name) to [6]
		fileStr = GetFileNameFromPathNoSemi(S_filename)
		drkStr = "DRK=none,DRKMODE=0,"
		drkStr = ReplaceStringByKey("DRK",drkStr,fileStr,"=",",")
		drkStr = ReplaceNumberByKey("DRKMODE", drkStr, 10 ,"=",",")	
		newProtocol[6] = drkStr
	else
		//no Work.DRK desired
		newProtocol[6] = "DRK=none,DRKMODE=0,"
	Endif
	
////////////
	
/////////////////
	DoAlert 1,"Do you want to subtract background from your data?"
	if(V_flag == 1)		//1=yes
		//prompt for background file, but don't actually open it (/D flag)
		Open/D/R/T="TEXT????"/M="Select the Background data file"/P=catPathName refnum
		//check for cancel
		if(strlen(S_filename)==0)
			//user cancelled, abort
			KillWaves/Z newProtocol
			SetDataFolder root:
			Abort "Incomplete protocol has been deleted"
		Endif
		//assign filename (full path) to [0]
		newProtocol[0] = GetFileNameFromPathNoSemi(S_filename)
		
		notDone=1
		do
			//prompt for additional background files
			DoAlert 1,"Do you want to add another background file?"
			if(V_flag == 1)		//yes
				Open/D/R/T="TEXT????"/M="Select another Background data file"/P=catPathName refnum
				//check for cancel
				if(strlen(S_filename)==0)
					//user cancelled, abort ********maybe just break out of the loop here
					KillWaves/Z newProtocol
					SetDataFolder root:
					Abort "Incomplete protocol has been deleted"
				Endif
				//assign filename (full path) to [0]
				newProtocol[0] += "," + GetFileNameFromPathNoSemi(S_filename)		//***COMMA separated list
				notDone = 1  		//keep going
			else
				notDone = 0			//no more to add
			Endif
		While(notDone)
	else		//no background desired
		newProtocol[0] = "none"
	Endif
//////////////////////	
	DoAlert 1,"Do you want to subtract empty cell scattering from your data?"
	if(V_flag == 1)		//1=yes
		//prompt for Empty cell file, but don't actually open it (/D flag)
		Open/D/R/T="TEXT????"/M="Select the Empty Cell data file"/P=catPathName refnum
		//check for cancel
		if(strlen(S_filename)==0)
			//user cancelled, abort
			KillWaves/Z newProtocol
			SetDataFolder root:
			Abort "Incomplete protocol has been deleted"
		Endif
		//assign filename (full path) to [1]
		newProtocol[1] = GetFileNameFromPathNoSemi(S_filename)
		
		notDone=1
		do
			//prompt for additional Empty Cell files
			DoAlert 1,"Do you want to add another Empty Cell file?"
			if(V_flag == 1)		//yes
				Open/D/R/T="TEXT????"/M="Select another Empty Cell data file"/P=catPathName refnum
				//check for cancel
				if(strlen(S_filename)==0)
					//user cancelled, abort ********maybe just break out of the loop here
					KillWaves/Z newProtocol
					SetDataFolder root:
					Abort "Incomplete protocol has been deleted"
				Endif
				//assign filename (full path) to [1]
				newProtocol[1] += "," + GetFileNameFromPathNoSemi(S_filename)		//***COMMA separated list
				notDone = 1  		//keep going
			else
				notDone = 0			//no more to add
			Endif
		While(notDone)
	else		//no background desired
		newProtocol[1] = "none"
	Endif
//////////////////////////
	DoAlert 1,"Do you want to correct your data for detector sensitivity?"
	if(V_flag == 1)		//1=yes
		//prompt for DIV  file, but don't actually open it (/D flag)
		Open/D/R/T="TEXT????"/M="Select the detector sensitivity file"/P=catPathName refnum
		//check for cancel
		if(strlen(S_filename)==0)
			//user cancelled, abort
			KillWaves/Z newProtocol
			SetDataFolder root:
			Abort "Incomplete protocol has been deleted"
		Endif
		//assign filename (full path) to [2]
		newProtocol[2] = GetFileNameFromPathNoSemi(S_filename)
	else
		//no Work.DIV desired
		newProtocol[2] = "none"
	Endif	
//////////////////////////
	DoAlert 1,"Do you want to mask your files before averaging?"
	if(V_flag == 1)		//1=yes
		//prompt for mask  file, but don't actually open it (/D flag)
		Open/D/R/T="TEXT????MASK"/M="Select the mask file"/P=catPathName refnum
		//check for cancel
		if(strlen(S_filename)==0)
			//user cancelled, abort
			KillWaves/Z newProtocol
			SetDataFolder root:
			Abort "Incomplete protocol has been deleted"
		Endif
		//assign filename (full path) to [3]
		newProtocol[3] = GetFileNameFromPathNoSemi(S_filename)
	else
		//no MASK desired
		newProtocol[3] = "none"
	Endif	
	
	//absolute scaling
	
	//////////////////////////
	//ABS parameters stored as keyword=value string
	DoAlert 1,"Do you want absolute scaling?"
	if(V_flag == 1)		//1=yes
		//missing param - prompt for values, put in semicolon-separated list
		Execute "AskForAbsoluteParams_Quest()"
		SVAR absStr =  root:myGlobals:Protocols:gAbsStr
		newProtocol[4] = absStr
	else
		//no absolute scaling desired
		newProtocol[4] = "none"
	Endif	
	
	//type of average, plot?, auto/manual naming/saving... put in semicolon separated string
	//of KEY=<value> format for easy parsing
	//Kewords are: AVTYPE,PHI,DPHI,PLOT,SAVE,NAME,SIDE,WIDTH
	//note that AVTYPE,NAME,SIDE have string values, others have numerical values
	///////////////////////
	DoAlert 1,"Do you want to average your data to I vs. q?"
	if(V_flag == 1)		//1=yes
		String/G root:myGlobals:Protocols:gAvgInfoStr = ""
		Execute "GetAvgInfo()"		//will put up missing paramter dialog and do all the work
		//:gAvgInfo is reset by the Proc(), copy this string tot he protocol
		SVAR tempStr=root:myGlobals:Protocols:gAvgInfoStr
		
		//get a file path for saving files, if desired
		/////no - save files to the same data folder as the one with the raw data 
		//then only one path to manage.
		//String yesNo = StringByKey("SAVE", tempStr,"=", ";")
		//if(cmpstr("Yes",yesNo) == 0)		//0=yes
			//NewPath/C/M="Select Folder"/O Save_path		//Save_path is the symbolic path
		//Endif	

		newProtocol[5] = tempStr
		KillStrings/Z tempStr
	else
		//no averaging desired
		newProtocol[5] = "AVTYPE=none"
	Endif
	
	//returns the name of the newly created (= currently in use) protocol wave through a global
	String/G root:myGlobals:Protocols:gProtoStr = newProtoStr
End

//function to check the work files (to see what's already there)
//and compare that with the files that are supposed to be there, according to the 
//current protocol (to save unnecessary time re-loading files)
//
//the "type" folder is checked for all files in the list req(ested)Files
//note that the list of files is a full path:name;ver, while the 
//fileList in the folder is just the name (or a list of names)
//
//returns 0 false, if files are NOT present
//or 1 = true, yes, the files are there as requested
//
Function AreFilesThere(type,reqFiles)
	String type,reqFiles
	
	//in general, reqFiles is a list of full paths to files - which MAY include semicolon version numbers
	//reqFiles MUST be constructed with COMMAS as list separators, to avoid disaster
	//when the version numbers are interpreted as filenames
	
	//get the number of files requested
	Variable nReq,nCur,match,ii
	nReq = ItemsInList(reqFiles,",")
	
	//get the name of the file currently in BGD - in the global fileList
	//fileList has NAMES ONLY - since it was derived from the file header
	String testStr
	testStr = "root:Packages:NIST:"+type+":fileList"
	if(Exists(testStr) == 2)		//2 if string variable exists
		SVAR curFiles = $testStr
	else
		//no files currently in type folder, return zero
		Return (0)
	Endif
	//get the number of files already in folder
	nCur = ItemsInList(curFiles,";")
	If(nCur != nReq)
		Return (0)		//quit now, the wrong number of files present
	Endif
	//right number of files... are the names right...
	//check for a match (case-sensitive!!) of each requested file in the curFile string
	//need to extract filenames from reqFiles, since they're the full path and name
	
	ii=0
	do
		testStr = StringFromList(ii,reqFiles,",")	//testStr is the Nth full path and filename
		//testStr = GetFileNameFromPathNoSemi(testStr)	//testStr will now be just the filename
		match = stringmatch(curFiles,testStr)
		If(!match)
			Return (0)		//req file was not found in curFile list - get out now
		Endif
		ii+=1
	while(ii<nreq)
	
	Return (1)		//indicate that files are OK, no changes needed
End

//will add the files specified in the protocol to the "type" folder
//will add multiple files together if more than one file is requested
//(list is a comma delimited list of filenames, with NO path information)
//
// This routine NOW DOES check for the possibility that the filenames may have ";vers" from the
// VAX - data should be picked up from Charlotte, where it won't have version numbers.
//
Function AddFilesInList(type,list)
	String type,list
	
	//type is the work folder to put the data into, and list is a COMMA delimited list of paths/names
	Variable num,ii,err=0,refNum
	String filename,pathStr=""
	PathInfo catPathName			//this is where the files are
	pathstr=S_path
	
	num = ItemsInList(list,",")		// comma delimited list
	
	ii=0
	do
		//FindValidFilename only needed in case of vax version numbers
		filename = pathStr + FindValidFilename(StringFromList(ii,list,","))
		Open/Z/R refnum as filename
		if(V_flag != 0)		//file not found
			//Print "file not found AddFilesInList()"
			//Print filename
			err = 1
			return(err)
		Endif
		Close refnum		//file was found and opened, so close it
		ReadHeaderAndData(filename)
		if(ii == 0)
			//first pass, wipe out the old contents of the work file
			err =  Raw_to_work(type)
		else
			err = Add_raw_to_work(type)
		Endif
		ii+=1
	while(ii<num)
	return(err)
End

//function will reduce a sample file (or ask for file(s))
//using the protocol named as "protoStr" in the Protocols subfolder
//samStr is the file(s) or "ask" to force prompt
//sequentially proceeds through flowchart, doing reduction steps as needed
//show Schematic to debug what steps/values were used
//
//function is long, but straightforward logic
//
Function ExecuteProtocol(protStr,samStr)
	String protStr,samStr
	//protStr is the full path to the selected protocol wave
	//samStr is either "ask" or the name ONLY ofthe desired sample data file(s) (NO PATH)
	WAVE/T prot = $protStr
	SetDataFolder root:myGlobals:Protocols
	
	Variable filesOK,err,notDone
	String activeType, msgStr, junkStr, pathStr=""
	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)
	
	//prompt for sam data => read raw data, add to sam folder
	//or parse file(s) from the input paramter string
	activeType = "SAM"
	msgStr = "Select sample data"
	//Ask for SAM file or parse
	do
		if((cmpstr(samStr,"ask") == 0) || (cmpstr(samStr,"")==0) )		//zero if strings are equal
			err = LoadRawSANSData(msgStr)		//will prompt for file
			if(err)
				PathInfo/S catPathName
				Abort "reduction sequence aborted"
			endif
			UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
			err =  Raw_to_work(activeType)		//this is the first file (default)
			//Ask for another SAM file
			do
				DoAlert 1,"Do you want to add another Sample file?"
				if(V_flag == 1)		//yes
					err = LoadRawSANSData(msgStr)		//will prompt for file
					if(err)
						PathInfo/S catPathName
						Abort "reduction sequence aborted"
					endif
					UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
					err = Add_raw_to_work(activeType)
					notDone = 1
				else
					notDone = 0
				endif
			while(notDone)
			break
		Endif
		//"none" is not an option - you always need a sample file - "none" will never return zero
		//if not "ask" AND not "none" then try to parse the filenames
		If((cmpstr(samStr,"none") != 0) && (cmpstr(samStr,"ask") != 0))
			//filesOK = AreFilesThere(activeType,samStr)		//return 1 if correct files are already there
			filesOK = 0		// Feb 2008, always force a reload of files. Maybe slow, but always correct 
			if(!filesOK)
				//add the correct file(s) to SAM
				err = AddFilesInList(activeType,samStr)
				if(err)
					//Print "samstr = ",samStr
					Abort "SAM file not found, reset SAM file"
				Endif
			Endif
		Endif
	While(0)
	//always update
	UpdateDisplayInformation(ActiveType)
	
	//check for bkg file  -- "ask" might not fail - "ask?" will - ? not allowed in VAX filenames
	// add if needed
	//use a "case" statement
	msgStr = "Select background file"
	activeType = "BGD"
	do
		if(cmpstr(prot[0],"ask") == 0)		//zero if strings are equal
			err = LoadRawSANSData(msgStr)		//will prompt for file
			if(err)
				PathInfo/S catPathName
				Abort "reduction sequence aborted"
			endif
			UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
			err =  Raw_to_work(activeType)		//this is the first file (default)
			//Ask for another BGD file
			do
				DoAlert 1,"Do you want to add another Background file?"
				if(V_flag == 1)		//yes
					err = LoadRawSANSData(msgStr)		//will prompt for file
					if(err)
						PathInfo/S catPathName
						Abort "reduction sequence aborted"
					endif
					UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
					err = Add_raw_to_work(activeType)
					notDone = 1
				else
					notDone = 0
				endif
			while(notDone)
			UpdateDisplayInformation(ActiveType)		//update before breaking from loop
			break
		Endif
		If(cmpstr(prot[0],"none") == 0)
			//clean out the BKG folder?
			//KillDataFolder root:BKG
			//NewDataFolder/O root:BKG
			break
		Endif
		//if not "ask" AND not "none" then try to parse the filenames
		If((cmpstr(prot[0],"none") != 0) && (cmpstr(prot[0],"ask") != 0))
			//filesOK = AreFilesThere(activeType,prot[0])
			filesOK = 0		// Feb 2008, always force a reload of files. Maybe slow, but always correct 
			if(!filesOK)
				//add the correct file(s) to BGD
				err = AddFilesInList(activeType,prot[0])
				If(err)
					Abort "BGD file not found. Reset BGD file list"
				Endif
			Endif
			UpdateDisplayInformation(ActiveType)		//update before breaking from loop
		Endif
	While(0)
	
	
	//check for emp file (prot[1])
	// add if needed
	msgStr = "Select empty cell data"
	activeType = "EMP"
	do
		if(cmpstr(prot[1],"ask") == 0)
			err = LoadRawSANSData(msgStr)		//will prompt for file
			if(err)
				PathInfo/S catPathName
				Abort "reduction sequence aborted"
			endif
			UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
			err =  Raw_to_work(activeType)		//this is the first file (default)
			//Ask for another EMP file
			do
				DoAlert 1,"Do you want to add another Empty Cell file?"
				if(V_flag == 1)		//yes
					err = LoadRawSANSData(msgStr)		//will prompt for file
					if(err)
						PathInfo/S catPathName
						Abort "reduction sequence aborted"
					endif
					UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
					err = Add_raw_to_work(activeType)
					notDone = 1
				else
					notDone = 0
				endif
			while(notDone)
			UpdateDisplayInformation(ActiveType)		//update before breaking from loop
			break
		Endif
		If(cmpstr(prot[1],"none") == 0)
			//clean out the EMP folder?
			//KillDataFolder root:Packages:NIST:EMP
			//NewDataFolder/O root:Packages:NIST:EMP
			break
		Endif
		//if not "ask" AND not "none" then try to parse the filenames
		If((cmpstr(prot[1],"none") != 0) && (cmpstr(prot[1],"ask") != 0))
			//filesOK = AreFilesThere(activeType,prot[1])
			filesOK = 0		// Feb 2008, always force a reload of files. Maybe slow, but always correct 
			if(!filesOK)
				//add the correct file(s) to BGD
				err = AddFilesInList(activeType,prot[1])
				If(err)
					Abort "EMP file not found. Reset EMP file list"
				Endif
			Endif
			UpdateDisplayInformation(ActiveType)		//update before breaking from loop
		Endif
	While(0)
	
	//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction 
	//additional modes 091301
	//11 = emp, bgd, drk
	//12 = bgd and drk
	//13 = emp and drk
	//14 = no subtractions
	//work.drk is from proto[6]
	//
	//subtracting just the DRK data is NOT an option - it doesnt' really make any physical sense
	// - in this case, DRK is skipped (equivalent to mode==4)
	// automatically accounts for attenuators given the lookup tables and the 
	//desired subtractions
	//Attenuator lookup tables are alredy implemented (NG1 = NG7)
	//
	
	//read in the DRK data if necessary
	//only one file, assumed to be RAW data
	//
	String fname="",drkStr=""
	drkStr=StringByKey("DRK",prot[6],"=",",")
	if(cmpstr(drkStr,"none") != 0)
		err = ReadHeaderAndData( (pathStr+drkStr) )
		if(err)
			PathInfo/S catPathName
			Abort "reduction sequence aborted"
		endif
		err = Raw_to_Work_NoNorm("DRK")
	endif
	
	//dispatch to the proper "mode" of Correct()
	Variable mode=4,val
	do
		if( (cmpstr("none",prot[0]) == 0)	&& (cmpstr("none",prot[1]) == 0) )
			//no subtraction (mode = 4),
			mode = 4
		Endif
		If((cmpstr(prot[0],"none") != 0) && (cmpstr(prot[1],"none") == 0))
			//subtract BGD only
			mode=2
		Endif
		If((cmpstr(prot[0],"none") == 0) && (cmpstr(prot[1],"none") != 0))
			//subtract EMP only
			mode=3
		Endif
		If((cmpstr(prot[0],"none") != 0) && (cmpstr(prot[1],"none") != 0))
			// bkg and emp subtraction are to be done (BOTH not "none")
			mode=1
		Endif
		activeType = "COR"
		//add in DRK mode (0= no used, 10 = used)
		val = NumberByKey("DRKMODE",prot[6],"=","," )
		mode += val
//		print "mode = ",mode
		err = Correct(mode)
		if(err)
			SetDataFolder root:
			Abort "error in Correct, called from executeprotocol, normal cor"
		endif
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	While(0)
	
	//check for work.div file (prot[2])
	//add if needed
	// can't properly check the filename - so for now add and divide, if anything other than "none"
	//do/skip divide step based on div answer
	If(cmpstr("none",prot[2])!=0)		// if !0, then there's a file requested
		If(cmpstr("ask",prot[2]) == 0)
			//ask user for file
			 junkStr = PromptForPath("Select the detector sensitivity file")
			If(strlen(junkStr)==0)
				SetDataFolder root:
				Abort "No file selected, data reduction aborted"
			Endif
			 ReadHeaderAndWork("DIV", junkStr)
		else
			//assume it's a path, and that the first (and only) item is the path:file
			//list processing is necessary to remove any final comma
			junkStr = pathStr + StringFromList(0, prot[2],"," )
			ReadHeaderAndWork("DIV",junkStr)
		Endif
		//got a DIV file, select the proper type of work data to DIV (= activeType)
		err = Divide_work(activeType)		//returns err = 1 if data doesn't exist in specified folders
		If(err)
			SetDataFolder root:
			Abort "data missing in DIV step, call from executeProtocol"
		Endif
		activeType = "CAL"
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	Endif
	
	Variable c2,c3,c4,c5,kappa_err
	//do absolute scaling if desired
	if(cmpstr("none",prot[4])!=0)
		if(cmpstr("ask",prot[4])==0)
			//get the params from the user
			Execute "AskForAbsoluteParams_Quest()"
			//then from the list
			SVAR junkAbsStr = root:myGlobals:Protocols:gAbsStr
			c2 = NumberByKey("TSTAND", junkAbsStr, "=", ";")	//parse the list of values
			c3 = NumberByKey("DSTAND", junkAbsStr, "=", ";")
			c4 = NumberByKey("IZERO", junkAbsStr, "=", ";")
			c5 = NumberByKey("XSECT", junkAbsStr, "=", ";")
			kappa_err = NumberByKey("SDEV", junkAbsStr, "=", ";")
		else
			//get the parames from the list
			c2 = NumberByKey("TSTAND", prot[4], "=", ";")	//parse the list of values
			c3 = NumberByKey("DSTAND", prot[4], "=", ";")
			c4 = NumberByKey("IZERO", prot[4], "=", ";")
			c5 = NumberByKey("XSECT", prot[4], "=", ";")
			kappa_err = NumberByKey("SDEV", prot[4], "=", ";")
		Endif
		//get the sample trans and thickness from the activeType folder
		String destStr = "root:Packages:NIST:"+activeType+":realsread"
		Wave dest = $destStr
		Variable c0 = dest[4]		//sample transmission
		Variable c1 = dest[5]		//sample thickness
		
		err = Absolute_Scale(activeType,c0,c1,c2,c3,c4,c5,kappa_err)
		if(err)
			SetDataFolder root:
			Abort "Error in Absolute_Scale(), called from executeProtocol"
		endif
		activeType = "ABS"
		UpdateDisplayInformation(ActiveType)		//update before breaking from loop
	Endif
	
	//check for mask
	//add mask if needed
	// can't properly check the filename - so for now always add
	//doesn't change the activeType
	if(cmpstr("none",prot[3])!=0)
		If(cmpstr("ask",prot[3])==0)
			//get file from user
			junkStr = PromptForPath("Select Mask file")
			If(strlen(junkStr)==0)
				//no selection of mask file is not a fatal error, keep going, and let cirave()
				//make a "null" mask 
				//if none desired, make sure that the old mask is deleted
				//junkStr = GetDataFolder(1)
				//SetDataFolder root:Packages:NIST:MSK
				KillWaves/Z root:Packages:NIST:MSK:data
				//SetDataFolder junkStr
				DoAlert 0,"No Mask file selected, data not masked"
			else
				//read in the file from the dialog
				ReadMCID_MASK(junkStr)
			Endif
		else
			//just read it in from the protocol
			//list processing is necessary to remove any final comma
			junkStr = pathStr + StringFromList(0, prot[3],"," )
			ReadMCID_MASK(junkStr)
		Endif
	else
		//if none desired, make sure that the old mask is deleted
		//junkStr = GetDataFolder(1)
		//SetDataFolder root:Packages:NIST:MSK
		KillWaves/Z root:Packages:NIST:MSK:data
		//SetDataFolder junkStr
	Endif
	
	//mask data if desired (this is done automatically  in the average step) and is
	//not done explicitly here (if no mask in MSK folder, a null mask is created and "used")
	
	// average/save data as specified
	
	//Parse the keyword=<Value> string as needed, based on AVTYPE
	
	//average/plot first 
	String av_type = StringByKey("AVTYPE",prot[5],"=",";")
	If(cmpstr(av_type,"none") != 0)
		If (cmpstr(av_type,"")==0)		//if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit
			//in the panel
			SetAverageParamsButtonProc("dummy")		//from "ProtocolAsPanel"
			SVAR tempAveStr = root:myGlobals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE",tempAveStr,"=",";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			String/G root:myGlobals:Protocols:gAvgInfoStr = prot[5]
		Endif
	Endif
	
	//convert the folder to linear scale before averaging, then revert by calling the window hook
	ConvertFolderToLinearScale(activeType)
	
	strswitch(av_type)	//dispatch to the proper routine to average to 1D data
		case "none":		
			//still do nothing
			break			
		case "2D_ASCII":	
			//do nothing
			break
		case "QxQy_ASCII":
			//do nothing
			break
		case "PNG_Graphic":
			//do nothing
			break
		case "Rectangular":
			RectangularAverageTo1D(activeType)
			break
		case "Annular":
			AnnularAverageTo1D(activeType)
			break
		case "Circular":
			CircularAverageTo1D(activeType)
			break
		case "Sector":
			CircularAverageTo1D(activeType)
			break
		case "Sector_PlusMinus":
			Sector_PlusMinus1D(activeType)
			break
		default:	
			//do nothing
	endswitch
///// end of averaging dispatch
	// put data back on log or lin scale as set by default
	fRawWindowHook()
	
	//save data if desired
	String fullpath = "", newfileName=""
	String item = StringByKey("SAVE",prot[5],"=",";")		//does user want to save data?
	If( (cmpstr(item,"Yes")==0) && (cmpstr(av_type,"none") != 0) )		
		//then save
		//get name from textwave of the activeType dataset
		String textStr = "root:Packages:NIST:"+activeType+":textread"
		Wave/T textPath = $textStr
		String tempFilename = samStr
		If(WaveExists(textPath) == 1)
#if (exists("QUOKKA")==6)
			newFileName = ReplaceString(".nx.hdf", tempFilename, "")
#elif (exists("HFIR")==6)
//			newFileName = ReplaceString(".xml",textPath[0],"")		//removes 4 chars
//			newFileName = ReplaceString("SANS",newFileName,"")		//removes 4 more chars = 8
//			newFileName = ReplaceString("exp",newFileName,"")			//removes 3 more chars = 11
//			newFileName = ReplaceString("scan",newFileName,"")		//removes 4 more chars = 15, should be enough?
			newFileName = GetPrefixStrFromFile(textPath[0])+GetRunNumStrFromFile(textPath[0])
#else
			newFileName = UpperStr(GetNameFromHeader(textPath[0]))		//NCNR data drops here, trims to 8 chars
#endif
		else
			newFileName = ""			//if the header is missing?
			//Print "can't read the header - newfilename is null"
		Endif
		
		//pick ABS or AVE extension
		String exten = activeType
		if(cmpstr(exten,"ABS") != 0)
			exten = "AVE"
		endif
		if(cmpstr(av_type,"2D_ASCII") == 0)
			exten = "ASC"
		endif
		if(cmpstr(av_type,"QxQy_ASCII") == 0)
			exten = "DAT"
		endif
		
		// add an "x" to the file extension if the output is XML
		// currently (2010), only for ABS and AVE (1D) output
		if( cmpstr(exten,"ABS") == 0 || cmpstr(exten,"AVE") == 0 )
			if(useXMLOutput == 1)
				exten += "x"
			endif
		endif
				
		//Path is catPathName, symbolic path
		//if this doesn't exist, a dialog will be presented by setting dialog = 1
		Variable dialog = 0
		PathInfo/S catPathName
		item = StringByKey("NAME",prot[5],"=",";")		//Auto or Manual naming
		String autoname = StringByKey("AUTONAME",prot[5],"=",";")		//autoname -  will get empty string if not present
		If((cmpstr(item,"Manual")==0) || (cmpstr(newFileName,"") == 0))
			//manual name if requested or if no name can be derived from header
			fullPath = newfileName + "."+ exten //puts possible new name or null string in dialog
			dialog = 1		//force dialog for user to enter name
		else
			//auto-generate name and prepend path - won't put up any dialogs since it has all it needs
			//use autoname if present
			if (cmpstr(autoname,"") != 0)
				fullPath = S_Path + autoname + "." +exten
			else
				fullPath = S_Path + newFileName+"." + exten
			endif	
		Endif
		//
		strswitch(av_type)	
			case "Annular":
				WritePhiave_W_Protocol(activeType,fullPath,dialog)
				break
			case "2D_ASCII":
				Fast2DExport(activeType,fullPath,dialog)
				break
			case "QxQy_ASCII":
				QxQy_Export(activeType,fullPath,dialog)
				break
			case "PNG_Graphic":
				SaveAsPNG(activeType,fullpath,dialog)
				break
			default:
				if (useXMLOutput == 1)
					WriteXMLWaves_W_Protocol(activeType,fullPath,dialog)
				else
					WriteWaves_W_Protocol(activeType,fullpath,dialog)
				endif
		endswitch
		
		//Print "data written to:  "+ fullpath
	Endif
	
	//done with everything in protocol list
	Return(0)
End

//updates the currently displayed information to the data in "type"
//data folder - changes the title of the window and the global of the 
//currently displayed data type - the recreation macro does the work
//
Function UpdateDisplayInformation(type)
	String type

//	String newTitle = "WORK_"+type
//	DoWindow/F SANS_Data
//	DoWindow/T SANS_Data, newTitle
//	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	//reset the current displaytype to "type"
	String/G root:myGlobals:gDataDisplayType=Type
	
	fRawWindowHook()
	
	//no error
	Return(0)
End

//missing parameter dialog to solicit the 4 absolute intensity parameters
//from the user
//values are passed back as a global string variable (keyword=value)
//
Proc AskForAbsoluteParams(c2,c3,c4,c5,err)
	Variable c2=0.95,c3=0.1,c4=1,c5=32.0,err=0
	Prompt c2, "Standard Transmission"
	Prompt c3, "Standard Thickness (cm)"
	Prompt c4, "I(0) from standard fit (normalized to 1E8 monitor cts)"
	Prompt c5, "Standard Cross-Section (cm-1)"
	Prompt err, "error in I(q=0) (one std dev)"
	
	String/G root:myGlobals:Protocols:gAbsStr=""
	
	root:myGlobals:Protocols:gAbsStr = "TSTAND="+num2str(c2)
	root:myGlobals:Protocols:gAbsStr +=  ";" + "DSTAND="+num2str(c3)
	root:myGlobals:Protocols:gAbsStr +=  ";" + "IZERO="+num2str(c4)
	root:myGlobals:Protocols:gAbsStr +=  ";" + "XSECT="+num2str(c5)
	root:myGlobals:Protocols:gAbsStr +=  ";" + "SDEV="+num2str(err)
	
End

//asks the user for absolute scaling information. the user can either
//enter the 4 necessary values in manually (missing parameter dialog)
//or the user can select an empty beam file from a standard open dialog
//if an empty beam file is selected, the "kappa" value is automatically calculated
//in either case, the global keyword=value string is set.
//
//Proc AskForAbsoluteParams_Quest()
Function AskForAbsoluteParams_Quest()	
	
	Variable err, isNG5=0,loc,refnum
	//ask user if he wants to use a transmision file for absolute scaling
	//or if he wants to enter his own information
	err = UseStdOrEmpForABS()
	//DoAlert 1,"<Yes> to enter your own values, <No> to select an empty beam flux file"
	If ( err==1 ) 
		//secondary standard selected, prompt for values
		Execute "AskForAbsoluteParams()"		//missing parameters
	else
		//empty beam flux file selected, prompt for file, and use this to calculate KAPPA
		Variable kappa=1
		
		//ask for file and read it into RAW
		//will cancel if no file is selected
		err = LoadRawSANSData("select the empty beam file")		//reads the RAW data
		UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
		if(err)
			PathInfo/S catPathName
			Abort "reduction sequence aborted"
		endif
			
		Wave/T tw=$"root:Packages:NIST:RAW:TextRead"
		Wave rw=$"root:Packages:NIST:RAW:RealsRead"
		Wave iw=$"root:Packages:NIST:RAW:IntegersRead"
		String acctStr = tw[3]
		//NG5 attenuator transmission is assumed to be the same as the table for NG7
			
		//get the necessary variables for the calculation of kappa
		Variable detCnt,countTime,attenTrans,monCnt,sdd,pixel
		String detStr=tw[9]
//		pixel = DetectorPixelResolution(acctStr,detStr)		//get the pixel size from the file information
		//note that reading the detector pixel size from the header ASSUMES SQUARE PIXELS! - Jan2008
		pixel = rw[10]/10			// header value (X) is in mm, want cm here
	
		countTime = iw[2]
		//detCnt = rw[2]		//080802 -use sum of data, not scaler from header
		monCnt = rw[0]
		sdd = rw[18]
		sdd *=100		//convert from meters to cm
				
		//lookup table for transmission factor
		//determine which instrument the measurement was done on from acctStr
		Variable lambda = rw[26]
		Variable attenNo = rw[3]
		Variable atten_err
		attenTrans = AttenuationFactor(acctStr,lambda,attenNo,atten_err)
		//Print "attenTrans = ",attenTrans
		
		//get the XY box, if needed
		Variable x1,x2,y1,y2,ct_err
		String filename=tw[0],tempStr
		PathInfo/S catPathName
		String tempName = S_Path + FindValidFilename(filename)
		err = GetXYBoxFromFile(tempName,x1,x2,y1,y2)		//xy's are passed/returned by reference
//		Print x1,x2,y1,y2

		if( ((x1-x2)==0) || ((y1-y2)==0) )	//need to re-select the box
			err = SelectABS_XYBox(x1,x2,y1,y2)		//this will pause for user input
			if(err)
				Abort "Box not selected properly - Please re-set the ABS parameters"
			Endif
			//box is OK, write box values to file
			WriteXYBoxToHeader(tempName,x1,x2,y1,y2)
		else
			//give option to override
			tempStr = "X=("+num2str(x1)+","+num2str(x2)+") Y=("+num2str(y1)+","+num2str(y2)+")"
			DoAlert 1,"The current box is "+tempStr+".  Do you want to override these values?"
			//Print v_flag
			if(V_flag==1)	//1==yes, override
				err = SelectABS_XYBox(x1,x2,y1,y2)
				if(err)
					Abort "Box not selected properly -Please re-set the ABS parameters"
				Endif
			endif
		Endif
		Printf "Using Box X(%d,%d),Y(%d,%d)\r",x1,x2,y1,y2
		
		//need the detector sensitivity file - make a guess, allow to override
		String junkStr="",errStr=""
		if(! waveexists($"root:Packages:NIST:DIV:data"))
			junkStr = PromptForPath("Select the detector sensitivity file")
			Print junkStr
#if(exists("HFIR")==6)
			if(strlen(junkStr)==0 || !CheckIfDIVData(junkStr))		//if either is false, exit
				//Print strlen(junkStr)
				//Print CheckIfDIVData(junkStr)
				SetDataFolder root:
				Abort "No DIV (PLEX) file selected. Please use setABSParams again, selecting the empty beam file and then the detector sensitivity (Plex_) file"
			endif
#else
			if(strlen(junkStr)==0 || !CheckIfDIVData(junkStr))		//for NCNR, and other data confirm it is DIV if either is false, exit
				SetDataFolder root:
				Abort "No DIV (PLEX) file selected. Please use setABSParams again, selecting the empty beam file and then the detector sensitivity (Plex_) file"
			endif
#endif
			ReadHeaderAndWork("DIV", junkStr)
		endif
		//toggle SANS_Data to linear display if needed, so that we're working with linear scaled data
		ControlInfo/W=SANS_Data bisLog
		if(V_Flag==1)
			Log_Lin("bisLog")	
		endif	
		Wave divData = $"root:Packages:NIST:div:Data"
		Wave data = $"root:Packages:NIST:raw:data"		//this will be the linear data
		// correct by detector sensitivity
		data /= divData
		
		// now do the sum, only in the box	
//		detCnt = sum($"root:Packages:NIST:raw:data", -inf, inf )
//		Print "box is now ",x1,x2,y1,y2
		detCnt = SumCountsInBox(x1,x2,y1,y2,ct_err,"RAW")
		if(cmpstr(tw[9],"ILL   ")==0)
			detCnt /= 4		// for cerca detector, header is right, sum(data) is 4x too large this is usually corrected in the Add step
			pixel *= 1.04			// correction for true pixel size of the Cerca
		endif
		//		
		kappa = detCnt/countTime/attenTrans*1.0e8/(monCnt/countTime)*(pixel/sdd)^2
		
		Variable kappa_err
		kappa_err = (ct_err/detCnt)^2 + (atten_err/attenTrans)^2
		kappa_err = sqrt(kappa_err) * kappa
		
		junkStr = num2str(kappa)
		errStr = num2Str(kappa_err)
		// set the parameters in the global string
//		Print "AskForAbsoluteParams(1,1,"+junkStr+",1,"+errStr+")"	
		Execute "AskForAbsoluteParams(1,1,"+junkStr+",1,"+errStr+")"		//no missing parameters, no dialog
		
		//should wipe out the data in the RAW folder, since it's not really RAW now
		DoWindow/K SANS_Data
		// SRK JUL 2006 don't clear the contents - just kill the window to force new data to be loaded
		// - obsucre bug if "ask" in ABS section of protocol clears RAW folder, then Q-axes can't be set from RAW:RealsRead
		//ClearDataFolder("RAW")
		Printf "Kappa was successfully calculated as = %g +/- %g (%g %)\r",kappa,kappa_err,(kappa_err/kappa)*100
	Endif
	
End

Function UserSelectBox_Continue(ctrlName) :buttonControl
	String ctrlName
	
	DoWindow/K junkWindow		//kill panel
end

Function SelectABS_XYBox(x1,x2,y1,y2)
	Variable &x1,&x2,&y1,&y2
	
	Variable err=0
	
	Variable/G root:V_marquee=1		//sets the sneaky bit to automatically update marquee coords
	Variable/G root:V_left,root:V_right,root:V_bottom,root:V_top	//must be global for auto-update
	DoWindow/F SANS_Data
	NewPanel/K=2 /W=(139,341,382,432) as "Select the primary beam"
	DoWindow/C junkWindow
	AutoPositionWindow/E/M=1/R=SANS_Data
	
	Drawtext 21,20 ,"Select the primary beam with the"
	DrawText 21,40, "marquee and press continue"
	Button button0,pos={80,58},size={92,20},title="Continue"
	Button button0,proc=UserSelectBox_Continue
	
	PauseForUser junkWindow,SANS_Data
	
	DoWindow/F SANS_Data

	//GetMarquee left,bottom			//not needed
	NVAR V_left=V_left
	NVAR V_right=V_right
	NVAR V_bottom=V_bottom
	NVAR V_top=V_top
	
	x1 = V_left
	x2 = V_right
	y1 = V_bottom
	y2 = V_top
//	Print "new values,before rounding = ",x1,x2,y1,y2
	KeepSelectionInBounds(x1,x2,y1,y2)
	//Print "new values = ",x1,x2,y1,y2
	
	KillVariables/Z root:V_Marquee,root:V_left,root:V_right,root:V_bottom,root:V_top
	if((x1-x2)==0 || (y1-y2)==0)
		err=1
	endif
	return(err)
End

Function UseStdOrEmpForABS()
		
	NewPanel/K=2 /W=(139,341,402,448) as "Absolute Scaling"
	DoWindow/C junkABSWindow
	ModifyPanel cbRGB=(57346,65535,49151)
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1
	DrawText 21,20,"Method of absolute calibration"
	Button button0,pos={52,33},size={150,20},proc=UserSelectABS_Continue,title="Empty Beam Flux"
	Button button1,pos={52,65},size={150,20},proc=UserSelectABS_Continue,title="Secondary Standard"
	
	PauseForUser junkABSWindow
	NVAR val = root:myGlobals:tmpAbsVal
	return(val)
End

//returns 0 if button0 (empty beam flux)
// or 1 if secondary standard
Function UserSelectABS_Continue(ctrlName) :buttonControl
	String ctrlName
	
	variable val=0
	If(cmpstr(ctrlName,"button0")==0)
		val=0		
	else
		val=1
	endif
//	print "val = ",ctrlName,val
	Variable/G root:myGlobals:tmpAbsVal = val
	DoWindow/K junkABSWindow		//kill panel
	return(0)
end


//save the protocol as an IGOR text wave (.itx)
//
//
Function ExportProtocol(ctrlName) : ButtonControl
	String ctrlName
// get a list of protocols
	String Protocol=""
	SetDataFolder root:myGlobals:Protocols
	Prompt Protocol "Pick A Protocol",popup, WaveList("*",";","")
	DoPrompt "Pick A Protocol to Export",Protocol
	if(V_flag==1)
		//Print "user cancel"
		SetDatafolder root:
		return(1)
	endif
//get the selection, or exit
	Wave/T pW= $protocol
	Make/O/T/N=13 tw
// save in the proper format (must write manually, for demo version)
	tw[0] = "IGOR"
	tw[1] = "WAVES/T \t"+protocol
	tw[2] = "BEGIN"
	tw[3,10] = "\t\""+pW[p-3]+"\""
	tw[11] = "END"
	tw[12] = "X SetScale/P x 0,1,\"\","+protocol+"; SetScale y 0,0,\"\","+protocol
	
	Variable refnum
	String fullPath
	
	PathInfo/S catPathName
	fullPath = DoSaveFileDialog("Export Protocol as",fname=Protocol,suffix="")
	If(cmpstr(fullPath,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no Protocol file was written"
	Endif

	//actually open the file
	Open refNum as fullpath+".itx"
	
	wfprintf refnum, "%s\r", tw
	Close refnum
	//Print "all is well  ",protocol
	KillWaves/Z tw
	setDataFolder root:
	return(0)

End

//imports a protocol from disk into the protocols folder
//
// will overwrite existing protocols if necessary
//
//
Function ImportProtocol(ctrlName) : ButtonControl
	String ctrlName

	SetDataFolder root:myGlobals:Protocols

	String fullPath
	
	PathInfo/S catPathName
	fullPath = DoOpenFileDialog("Import Protocol")
	If(cmpstr(fullPath,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no protocol was loaded"
	Endif
	
	LoadWave/O/T fullPath
	
	SetDataFolder root:
	return(0)
end