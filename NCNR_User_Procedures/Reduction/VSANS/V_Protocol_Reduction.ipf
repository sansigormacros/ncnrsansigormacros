#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=7.00

//************************

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
//		QDELTA=value		(+/-) width of annulus centered at QCENTER, in units of q
//		DETGROUP=value	string with "F" or "M" to name the detector group where the annulus lies.

//		PLOT=string		string from set {Yes,No} = truth of generating plot of averaged data
//		SAVE=string		string from set {Yes,No} = truth of saving averaged data to disk, now with "Concatenate"  or "Individual"
//		NAME=string		string from set {Auto,Manual} = Automatic name generation or Manual(dialog)
//
//
//    BINTYPE=string (VSANS binning type) "One;Two;Four;Slit Mode;", as defined by ksBinTypeStr
//
//
//		For work.DRK usage:
//		**the list is COMMA delimited, separator is =
//		DRK=none,DRKMODE=0,
//		DRK=name 			is the name of the file, must be a full name, expected to be raw data
//		DRKMODE=value		is a numeric value (0 or 10 to add to the Correct(mode) switch (unused?)
//
//////////////////////////////////

//main entry procedure for initialzing and displaying the protocol panel
// initilaizes folders and globals as needed
//
Proc V_ReductionProtocolPanel()
	DoWindow/F V_ProtocolPanel
	if(V_flag == 0)
		V_InitProtocolPanel()
		V_ProtocolPanel()
	endif
EndMacro

//initialization procedure for the protocol panel
//note that :gAbsStr is also shared (common global) to that used in
//the questionnare form of the protcol (see protocol.ipf)
//
Proc V_InitProtocolPanel()

	if(exists("	root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames") == 0)
		Abort "You must generate a file catalog before building protocols"
	endif

	//set up the global variables needed for the protocol panel
	//global strings to put in a temporary protocol textwave
	variable ii      = 0
	string   waveStr = "tempProtocol"
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	Make/O/T/N=(kNumProtocolSteps) $"root:Packages:NIST:VSANS:Globals:Protocols:tempProtocol" = ""

	string/G root:Packages:NIST:VSANS:Globals:Protocols:gSAM     = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gBGD     = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gEMP     = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gDIV     = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gMASK    = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr  = "ask"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gAVE     = "AVTYPE=Circular;SAVE=Yes - Concatenate;NAME=Auto;PLOT=No;BINTYPE=F4-M4-B;"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gDRK     = "DRK=none,DRKMODE=0,"
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gHRNoise = "not yet loaded"

	// global strings for trimming data are initialized in the main VSANS initilization
	//  in case the trimming is done before the protocol panel is opened

	SetDataFolder root:

EndMacro

//button procedure to reset the panel seletctions/checks...etc...
//to reflect the choices in a previously saved protocol
// - parses through the protocol and resets the appropriate global strings and
//updates the panel display
//
Function V_RecallProtocolButton(string ctrlName) : ButtonControl

	//will reset panel values based on a previously saved protocol
	//pick a protocol wave from the Protocols folder
	//MUST move to Protocols folder to get wavelist
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	Execute "V_PickAProtocol()"

	//get the selected protocol wave choice through a global string variable
	SVAR protocolName = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr

	//If "CreateNew" was selected, ask user to try again
	if(cmpstr("CreateNew", protocolName) == 0)
		Abort "CreateNew is for making a new Protocol. Select a previously saved Protocol"
	endif

	//reset the panel based on the protocol textwave (currently a string)
	V_ResetToSavedProtocol(protocolName)

	SetDataFolder root:
	return (0)
End

//deletes the selected protocol from the list and from memory
//
Function V_DeleteProtocolButton(string ctrlName) : ButtonControl

	//put up a list of protocols and pick one
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	//	Execute "DeleteAProtocol()"
	string Protocol = ""
	Prompt Protocol, "Delete A Protocol", popup, V_DeletableProtocols()
	DoPrompt "Select protocol to delete", protocol
	if(V_flag == 1)
		return (0)
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
	return (0)
End

//
//function that actually parses the protocol specified by nameStr
//which is just the name of the wave, without a datafolder path
//
//
//  x- updated this for 12 steps
//
Function V_ResetToSavedProtocol(string nameStr)

	//allow special cases of Base and DoAll Protocols to be recalled to panel - since they "ask"
	//and don't need paths

	string catPathStr
	PathInfo catPathName
	catPathStr = S_path

	//SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols		//on windows, data folder seems to get reset (erratically) to root:
	WAVE/T w = $("root:Packages:NIST:VSANS:Globals:Protocols:" + nameStr)

	string fullPath = ""
	string comma    = ","
	string list     = ""
	string nameList = ""
	string PathStr  = ""
	string item     = ""
	variable numItems, checked, specialProtocol
	variable ii = 0

	if((cmpstr(nameStr, "Base") == 0) || (cmpstr(nameStr, "DoAll") == 0))
		specialProtocol = 1
	else
		specialProtocol = 0
	endif

	//background
	checked  = 1
	nameList = w[0]
	if(cmpstr(nameList, "none") == 0)
		checked = 0
	endif

	//set the global string to display and checkbox
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gBGD = nameList
	CheckBox prot_check, win=V_ProtocolPanel, value=checked

	//empty
	checked  = 1
	nameList = w[1]
	if(cmpstr(nameList, "none") == 0)
		checked = 0
	endif

	//set the global string to display and checkbox
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gEMP = nameList
	CheckBox prot_check_1, win=V_ProtocolPanel, value=checked

	//DIV file
	checked  = 1
	nameList = w[2]
	if(cmpstr(nameList, "none") == 0)
		checked = 0
	endif

	//set the global string to display and checkbox
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gDIV = nameList
	CheckBox prot_check_2, win=V_ProtocolPanel, value=checked

	//Mask file
	checked  = 1
	nameList = w[3]
	if(cmpstr(nameList, "none") == 0)
		checked = 0
	endif

	//set the global string to display and checkbox
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gMASK = nameList
	CheckBox prot_check_3, win=V_ProtocolPanel, value=checked

	//4 = abs parameters
	list     = w[4]
	numItems = ItemsInList(list, ";")
	checked  = 1
	//	if(numitems == 4 || numitems == 5)		//allow for protocols with no SDEV list item
	if(numitems > 1) //
		//correct number of parameters, assume ok
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr = list
		CheckBox prot_check_9, win=V_ProtocolPanel, value=checked
	else
		item = StringFromList(0, list, ";")
		if(cmpstr(item, "none") == 0)
			checked = 0
			list    = "none"
			string/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr = list
			CheckBox prot_check_9, win=V_ProtocolPanel, value=checked
		else
			//force to "ask"
			checked = 1
			string/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr = "ask"
			CheckBox prot_check_9, win=V_ProtocolPanel, value=checked
		endif
	endif

	//5 = averaging choices
	list = w[5]
	item = StringByKey("AVTYPE", list, "=", ";")
	if(cmpstr(item, "none") == 0)
		checked = 0
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gAVE = "none"
		CheckBox prot_check_5, win=V_ProtocolPanel, value=checked
	else
		checked = 1
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gAVE = list
		CheckBox prot_check_5, win=V_ProtocolPanel, value=checked
	endif

	//	//6 = DRK choice
	//	list = w[6]
	//	item = StringByKey("DRK",list,"=",",")
	//	//print list,item
	//	if(cmpstr(item,"none") == 0)
	//		checked = 0
	//		String/G root:Packages:NIST:VSANS:Globals:Protocols:gDRK = list
	//		CheckBox prot_check_6 win=V_ProtocolPanel,value=checked
	//	else
	//		checked = 1
	//		String/G root:Packages:NIST:VSANS:Globals:Protocols:gDRK = list
	//		CheckBox prot_check_6 win=V_ProtocolPanel,value=checked
	//	Endif

	//7 = beginning trim points
	SVAR gBegPtsStr = root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	gBegPtsStr = w[7]
	//8 = end trim points
	SVAR gEndPtsStr = root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr
	gEndPtsStr = w[8]

	//9 = unused
	//10 = unused
	//11 = unused

	//all has been reset, get out
	return (0)
End

//button action procedure that simply closes the panel
//
Function V_DoneProtocolButton(string ctrlName) : ButtonControl

	//will gracefully close and exit the protocol panel

	DoWindow/K V_ProtocolPanel
End

//button action procedure that saves the current choices on the panel
//as a named protocol, for later recall
//asks for a valid name, then creates a protocol from the panel choices
//creates a wave, and sets the current protocol name to this new protocol
//
//now allows the user the choice to overwrite a protocol
//
Function V_SaveProtocolButton(string ctrlName) : ButtonControl

	variable notDone  = 1
	variable newProto = 1
	//will prompt for protocol name, and save the protocol as a text wave
	//prompt for name of new protocol wave to save
	do
		Execute "V_AskForName()"
		SVAR newProtocol = root:Packages:NIST:VSANS:Globals:Protocols:gNewStr

		//make sure it's a valid IGOR name
		newProtocol = CleanupName(newProtocol, 0) //strict naming convention
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gNewStr = newProtocol //reassign, if changed
		Print "newProtocol = ", newProtocol

		SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
		if(WaveExists($("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtocol)) == 1)
			//wave already exists
			DoAlert 1, "That name is already in use. Do you wish to overwrite the existing protocol?"
			if(V_Flag == 1)
				notDone  = 0
				newProto = 0
			else
				notDone = 1
			endif
		else
			//name is good
			notDone = 0
		endif
	while(notDone)

	//current data folder is  root:Packages:NIST:VSANS:Globals:Protocols
	if(newProto)
		Make/O/T/N=(kNumProtocolSteps) $("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtocol)
	endif

	variable err
	err = V_MakeProtocolFromPanel($("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtocol))
	if(err)
		DoAlert 0, "BGD and EMP files do not have the same configuration. No protocol saved."
		KillWaves/Z $("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtocol)
	else
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = newProtocol
	endif
	//the data folder WAS changed above, this must be reset to root:
	SetDatafolder root:
End

//function that does the guts of reading the panel controls and globals
//to create the necessary text fields for a protocol
//Wave/T w (input) is an empty text wave of 8 elements for the protocol
//on output, w[] is filled with the protocol strings as needed from the panel
//
// x- updated for 12 points
//
// returns error==1 if files (emp, bgd) are not of the same configuration
//
Function V_MakeProtocolFromPanel(WAVE/T w)

	//construct the protocol text wave form the panel
	//it is to be parsed by ExecuteProtocol() for the actual data reduction
	PathInfo catPathName //this is where the files came from
	string tempStr, curList
	string pathstr = S_path
	variable checked, ii, numItems

	//look for checkbox, then take each item in list and prepend the path
	//w[0] = background
	ControlInfo/W=V_ProtocolPanel prot_check
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str = root:Packages:NIST:VSANS:Globals:Protocols:gBGD
		if(cmpstr(str, "ask") == 0)
			w[0] = str //just ask
		else
			tempstr = V_ParseRunNumberList(str)
			if(strlen(tempStr) == 0)
				return (1) //error parsing list
			endif

			w[0] = tempstr
			str  = tempstr //set the protocol and the global
		endif
	else
		//none used - set textwave (and global?)
		w[0] = "none"
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gBGD = "none"
	endif

	//w[1] = empty
	ControlInfo/W=V_ProtocolPanel prot_check_1
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str = root:Packages:NIST:VSANS:Globals:Protocols:gEMP
		if(cmpstr(str, "ask") == 0)
			w[1] = str
		else
			tempstr = V_ParseRunNumberList(str)
			if(strlen(tempStr) == 0)
				return (1)
			endif

			w[1] = tempstr
			str  = tempStr
		endif
	else
		//none used - set textwave (and global?)
		w[1] = "none"
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gEMP = "none"
	endif

	//w[2] = div file
	ControlInfo/W=V_ProtocolPanel prot_check_2
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str = root:Packages:NIST:VSANS:Globals:Protocols:gDIV
		if(cmpstr(str, "ask") == 0)
			w[2] = str
		else
			//			Print itemsinlist(str,",")
			tempStr = StringFromList(0, str, ",")
			//			tempStr = V_ParseRunNumberList(str)
			if(strlen(tempStr) == 0)
				return (1)
			endif

			w[2] = tempstr
			str  = tempstr
		endif
	else
		//none used - set textwave (and global?)
		w[2] = "none"
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gDIV = "none"
	endif

	//w[3] = mask file
	ControlInfo/W=V_ProtocolPanel prot_check_3
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str = root:Packages:NIST:VSANS:Globals:Protocols:gMASK
		if(cmpstr(str, "ask") == 0)
			w[3] = str
		else
			tempStr = StringFromList(0, str, ",")
			//			tempstr = V_ParseRunNumberList(str)
			if(strlen(tempstr) == 0)
				return (1)
			endif

			w[3] = tempstr
			str  = tempstr
		endif
	else
		//none used - set textwave (and global?)
		w[3] = "none"
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gMASK = "none"
	endif

	//w[4] = abs parameters
	ControlInfo/W=V_ProtocolPanel prot_check_9
	checked = V_value
	if(checked)
		//build the list
		//just read the global
		SVAR str = root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
		w[4] = str
	else
		//none used - set textwave (and global?)
		w[4] = "none"
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr = "none"
	endif

	//w[5] = averaging choices
	ControlInfo/W=V_ProtocolPanel prot_check_5 //do the average?
	checked = V_value
	if(checked)
		//just read the global
		SVAR avestr = root:Packages:NIST:VSANS:Globals:Protocols:gAVE
		w[5] = avestr
	else
		//none used - set textwave
		w[5] = "AVTYPE=none;"
	endif

	//w[6]
	//work.DRK information
	SVAR drkStr = root:Packages:NIST:VSANS:Globals:Protocols:gDRK
	w[6] = drkStr

	//w[7]
	// beginning trim points
	// if null, then write out the default trim string to the protocol so that it will be used if recalled
	SVAR gBegPtsStr = root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	if(strlen(gBegPtsStr) == 0)
		w[7] = ksBinTrimBegDefault
	else
		w[7] = gBegPtsStr
	endif

	//w[8]
	// End trim points
	// if null, then write out the default trim string to the protocol so that it will be used if recalled
	SVAR gEndPtsStr = root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr
	if(strlen(gEndPtsStr) == 0)
		w[8] = ksBinTrimEndDefault
	else
		w[8] = gEndPtsStr
	endif

	//w[9]
	//collimation type (filled in at averaging?)
	w[9] = ""
	//w[10]
	//currently unused
	w[10] = ""
	//w[11]
	//currently unused
	w[11] = ""

	//	check that w[0](BGD) and w[1](EMP) are from matching configurations
	if(cmpstr(w[0], "none") == 0 || cmpstr(w[0], "ask") == 0)
		// no file specified for BGD, so no issues
		return (0)
	endif
	if(cmpstr(w[1], "none") == 0 || cmpstr(w[1], "ask") == 0)
		// no file specified for EMP, so no issues
		return (0)
	endif
	variable matchOK
	// returns 1 for match , 0 if no match
	matchOK = V_RawFilesMatchConfig(StringFromList(0, w[0], ","), StringFromList(0, w[1], ","))

	return (!matchOK)
End

//
Function V_PickSAMButton(string ctrlName) : ButtonControl

End

//
// TODO
// -- identifying "intent" using V_get can be very slow, since it reads in each and every data file.
//   grep is a lot faster, but there can be a lot of false "hits" unless I do it correctly.
//
//
//	//grep through what text I can find in the VAX binary
//	// Grep Note: the \\b sequences limit matches to a word boundary before and after
//	// "boondoggle", so "boondoggles" and "aboondoggle" won't match.
//	if(gRadioVal == 2)
//		for(ii=0;ii<num;ii+=1)
//			item=StringFromList(ii, newList , ";")
////			Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
//			Grep/P=catPathName/Q/E=("(?i)"+match) item
//			if( V_value )	// at least one instance was found
////				Print "found ", item,ii
//				list += item + ";"
//			endif
//		endfor
//
//		newList = list
//	endif

// match is the string to look for in the search
// 0 is a flag to tell it to look in the file catalog (the fastest method)
// Other options are to grep, or to read the intent field in every file
Function/S V_GetSAMList()

	//	String match="SAMPLE"
	//	String list = V_getFileIntentList(match,0)

	string intent  = "SAMPLE"
	string purpose = "SCATTERING"
	string list    = V_getFileIntentPurposeList(intent, purpose, 0)

	//	Printf "SAM files = %s\r",list
	return (list)
End

Function/S V_GetBGDList()

	string intent  = "BLOCKED BEAM"
	string purpose = "SCATTERING"
	//	String list = V_getFileIntentList(match,0)
	string list = V_getFileIntentPurposeList(intent, purpose, 0)

	//	Printf "BGD files = %s\r",list
	return (list)
End

//
// V_getFileIntentPurposeList(intent,purpose,method)
Function/S V_GetEMPList()

	string intent  = "EMPTY CELL"
	string purpose = "SCATTERING"
	//	String list = V_getFileIntentList(match,0)
	string list = V_getFileIntentPurposeList(intent, purpose, 0)

	//	Printf "EMP files = %s\r",list
	return (list)
End

//
// TODO
// -- decide on the way to locate the blocked beam files. Is the enumerated text of the intent
//    sufficiently unique to locate the file?
// -- can I use the Data Catalog waves to locate the files  - faster?
//    (fails if the catalog has not been read in recently enough)
//
//
Function/S V_PickBGDButton(string ctrlName) : ButtonControl

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num

	PathInfo catPathName
	string path = S_path

	string match = "BLOCKED BEAM"

	//v_tic()
	// get the list from the file catalog (=0.0007s)
	//
	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent

	variable np = numpnts(intentW)
	for(ii = 0; ii < np; ii += 1)
		if(cmpstr(intentW[ii], match) == 0)
			list += fileNameW[ii] + ";"
		endif
	endfor

	List = SortList(List, ";", 0)
	Printf "BGD files = %s\r", list
	//v_toc()

	////v_tic()			// from grep = 3.3s
	//	newList = V_GetRawDataFileList()
	//	num=ItemsInList(newList)
	//
	////	for(ii=0;ii<num;ii+=1)
	////		item=StringFromList(ii, newList , ";")
	////		fname = path + item
	////		intent = V_getReduction_intent(fname)
	////		if(cmpstr(intent,"BLOCKED BEAM") == 0)
	////			list += item + ";"
	////		endif
	////
	////	endfor
	//	list = ""
	//	for(ii=0;ii<num;ii+=1)
	//		item=StringFromList(ii, newList , ";")
	//		Grep/P=catPathName/Q/E=("(?i)"+match) item
	//		if( V_value )	// at least one instance was found
	////				Print "found ", item,ii
	//			list += item + ";"
	//		endif
	//	endfor
	//
	//
	//	List = SortList(List,";",0)
	//	Printf "BGD files = %s\r",list
	////v_toc()

	return (list)
End

//
Function/S V_PickEMPButton(string ctrlName) : ButtonControl

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num

	PathInfo catPathName
	string path = S_path

	string match = "EMPTY CELL"

	// get the list from the file catalog (=0.0007s)
	//
	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent

	variable np = numpnts(intentW)
	for(ii = 0; ii < np; ii += 1)
		if(cmpstr(intentW[ii], match) == 0)
			list += fileNameW[ii] + ";"
		endif
	endfor

	List = SortList(List, ";", 0)
	Printf "EMP files = %s\r", list

	//
	//	newList = V_GetRawDataFileList()
	//	num=ItemsInList(newList)
	//
	////	for(ii=0;ii<num;ii+=1)
	////		item=StringFromList(ii, newList , ";")
	////		fname = path + item
	////		intent = V_getReduction_intent(fname)
	////		if(cmpstr(intent,"EMPTY CELL") == 0)
	////			list += item + ";"
	////		endif
	////
	////	endfor
	//
	//	for(ii=0;ii<num;ii+=1)
	//		item=StringFromList(ii, newList , ";")
	//		Grep/P=catPathName/Q/E=("(?i)"+match) item
	//		if( V_value )	// at least one instance was found
	////				Print "found ", item,ii
	//			list += item + ";"
	//		endif
	//
	//	endfor
	//
	//	List = SortList(List,";",0)
	//	Printf "EMP files = %s\r",list

	return (list)
End

//
Function/S V_PickEMPBeamButton(string ctrlName) : ButtonControl

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num

	PathInfo catPathName
	string path = S_path

	string match = "OPEN BEAM"

	// get the list from the file catalog (=0.0007s)
	//
	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T intentW   = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent

	variable np = numpnts(intentW)
	for(ii = 0; ii < np; ii += 1)
		if(cmpstr(intentW[ii], match) == 0)
			list += fileNameW[ii] + ";"
		endif
	endfor

	List = SortList(List, ";", 0)
	Printf "EMP Beam files = %s\r", list

	return (list)
End

// currently the list will return a not-raw data file that has "DIV" somewhere
// in the file name. Nothing fancier than that (I try to force the DIV in the name when it
// is generated by the instrument scientists)
//
// if something fancier is needed, I could grep for VSANS_DIV stored in the title block of the
// HDF file structure
Function/S V_GetDIVList()

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num, val

	PathInfo catPathName
	string path = S_path

	newList = V_Get_NotRawDataFileList()
	//	newList = V_RemoveEXTFromList(newlist,"hst")		// remove the event files
	//	newList = V_RemoveEXTFromList(newlist,"ave")		// remove the ave files
	//	newList = V_RemoveEXTFromList(newlist,"abs")		// remove the abs files
	//	newList = V_RemoveEXTFromList(newlist,"phi")		// remove the phi files
	//	newList = V_RemoveEXTFromList(newlist,"pxp")		// remove the pxp files
	//	newList = V_RemoveEXTFromList(newlist,"DS_Store")		// remove the DS_Store file (OSX only)

	num = ItemsInList(newList)

	// keep only DIV files in the list
	num = ItemsInList(newList)

	string matchStr = "*DIV*" // this is part of the title of a VSANS _DIV_ file
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, newList, ";")
		val  = stringmatch(item, matchStr)
		if(val) // true if the string did match
			list += item + ";"
		endif

	endfor

	List = SortList(List, ";", 0)

	//
	//	String match="DIV"
	//	for(ii=0;ii<num;ii+=1)
	//		item=StringFromList(ii, newList , ";")
	//		Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
	////		Grep/P=catPathName/Q/E=("(?i)"+match) item
	//		if( V_value )	// at least one instance was found
	////				Print "found ", item,ii
	////			if(strsearch(item,"pxp",0,2) == -1)		//does NOT contain .pxp (the current experiment will be a match)
	//				list += item + ";"
	////			endif
	//		endif
	//	endfor
	//

	return (list)
End

Function/S V_GetMSKList()

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num, val

	PathInfo catPathName
	string path = S_path

	newList = V_Get_NotRawDataFileList()
	//	newList = V_RemoveEXTFromList(newlist,"hst")		// remove the event files
	//	newList = V_RemoveEXTFromList(newlist,"ave")		// remove the ave files
	//	newList = V_RemoveEXTFromList(newlist,"abs")		// remove the abs files
	//	newList = V_RemoveEXTFromList(newlist,"phi")		// remove the phi files
	//	newList = V_RemoveEXTFromList(newlist,"pxp")		// remove the pxp files
	//	newList = V_RemoveEXTFromList(newlist,"png")		// remove the png files
	//	newList = V_RemoveEXTFromList(newlist,"jpg")		// remove the jpg files
	//	newList = V_RemoveEXTFromList(newlist,"DS_Store")		// remove the DS_Store file (OSX only)

	// keep only MASK files in the list
	num = ItemsInList(newList)

	string matchStr = "*MASK*" // this is part of the title of a VSANS _MASK_ file
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, newList, ";")
		val  = stringmatch(item, matchStr)
		if(val) // true if the string did match
			list += item + ";"
		endif

	endfor

	List = SortList(List, ";", 0)

	//
	////	String match="MASK"		// this is part of the title of a VSANS MASK file
	//	String match="VSANS_MASK"		// this is part of the title of a VSANS MASK file
	//	for(ii=0;ii<num;ii+=1)
	//		item=StringFromList(ii, newList , ";")
	//		Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
	////		Grep/P=catPathName/Q/E=("(?i)"+match) item
	//		if( V_value )	// at least one instance was found
	////				Print "found ", item,ii
	////			if(strsearch(item,"pxp",0,2) == -1)		//does NOT contain .pxp (the current experiment will be a match)
	//				list += item + ";"
	////			endif
	//		endif
	//
	//	endfor
	//

	List = SortList(List, ";", 0)

	return (list)
End

//
// TODO
// -- find proper way to search for these files
// -- they *may* be written to the file header(reduction block)
// -- or grep for VSANS_MASK (in the title)
Function/S V_PickMASKButton(string ctrlName) : ButtonControl

	string fname, newList, intent
	string list = ""
	string item = ""
	variable ii, num

	PathInfo catPathName
	string path = S_path

	newList = V_Get_NotRawDataFileList()
	newList = V_RemoveEXTFromList(newlist, "hst") // remove the event files
	num     = ItemsInList(newList)

	//	for(ii=0;ii<num;ii+=1)
	//		item=StringFromList(ii, newList , ";")
	//		fname = path + item
	//		intent = V_getReduction_intent(fname)
	//		if(cmpstr(intent,"MASK") == 0)
	//			list += item + ";"
	//		endif
	//
	//	endfor

	string match = "MASK"
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, newList, ";")
		Grep/P=catPathName/Q/E=("(?i)\\b" + match + "\\b") item
		//		Grep/P=catPathName/Q/E=("(?i)"+match) item
		if(V_value) // at least one instance was found
			//				Print "found ", item,ii
			list += item + ";"
		endif

	endfor

	List = SortList(List, ";", 0)
	Printf "MASK files = %s\r", list

	return (list)

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
Function V_ReduceOneButton(string ctrlName) : ButtonControl

	// exit if polarized beam package is loaded
	if(exists("V_ExecutePolarizedProtocol") != 0)
		DoAlert 0, "To reduce polarized beam data, use the button on the Polarization Correction panel"
		return (0)
	endif

	// if polarized beam not loaded, proceed as ususal...

	//parse the information on the panel and assign to tempProtocol wave (in protocol folder)
	//and execute
	string temp = "root:Packages:NIST:VSANS:Globals:Protocols:tempProtocol"
	WAVE/T w    = $temp
	variable err
	variable ii  = 0
	variable num = 12
	do
		w[ii] = ""
		ii   += 1
	while(ii < num)

	err = V_MakeProtocolFromPanel(w)
	if(err)
		DoAlert 0, "BGD and EMP files do not have the same configuration."
		return (0)
	endif

	//the "current" protocol is the "tempProtocol" that was parsed from the panel input
	//set the global, so that the data writing routine can find the protocol wave (fatal otherwise)
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = "tempProtocol"

	PathInfo catPathName //this is where the files came from
	string samStr
	string pathstr = S_path

	//take the string from the panel
	SVAR tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gSAM

	if((strlen(tempStr) == 0) || (cmpstr(tempStr, "ask") == 0))
		//let user select the files
		tempStr = "ask"
		V_ExecuteProtocol(temp, tempStr)
		return (0)
	endif

	//parse the list of numbers
	//send only the filenames, without paths
	samStr = V_ParseRunNumberList(tempStr)
	if(strlen(samStr) == 0)
		DoAlert 0, "The SAM file number cound not be interpreted. Please enter a valid run number or filename"
		return (1)
	endif
	tempStr = samStr //reset the global
	V_ExecuteProtocol(temp, samStr)
	return (0)
End

//button action function will prompt user for absolute scaling parameters
//either from an empty beam file or by manually entering the 4 required values
//uses the same function and shared global string as the questionnare form of reduction
//in "protocol.ipf" - the string is root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
//
Function V_SetABSParamsButton(string ctrlName) : ButtonControl

	//will prompt for a list of ABS parameters (4) through a global string variable
	if(cmpstr(ctrlName, "pick_ABS_B") == 0)
		Execute "V_AskForAbsoluteParams_Quest(1)"
	else
		Execute "V_AskForAbsoluteParams_Quest(0)"
	endif
End

//the panel recreation macro
//
Window V_ProtocolPanel()

	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(1180 * sc, 332 * sc, 1530 * sc, 932 * sc)/K=1 as "VSANS Reduction Protocol"
	ModifyPanel cbRGB=(56589, 50441, 50159) //, fixedSize=1
	SetDrawLayer UserBack
	DrawLine 3, 40 * sc, 301 * sc, 40 * sc
	DrawLine 3, 100 * sc, 301 * sc, 100 * sc
	DrawLine 3, 157 * sc, 301 * sc, 157 * sc
	DrawLine 3, 208 * sc, 301 * sc, 208 * sc
	DrawLine 3, 257 * sc, 301 * sc, 257 * sc
	DrawLine 3, 305 * sc, 301 * sc, 305 * sc
	DrawLine 3, 350 * sc, 301 * sc, 350 * sc
	DrawLine 3, 445 * sc, 301 * sc, 445 * sc
	DrawLine 3, 513 * sc, 301 * sc, 513 * sc
	DrawLine 3, 396 * sc, 301 * sc, 396 * sc

	//
	Button button_help, pos={sc * 300, 2 * sc}, size={sc * 25, 20 * sc}, proc=V_ShowProtoHelp, title="?"
	Button button_help, help={"Show the help file for setting up a reduction protocol"}

	//	Button button_quest,pos={sc*20,2*sc},size={sc*150,20*sc},proc=V_ProtocolQuestionnaire,title="Questions"
	//	Button button_quest,help={"Run through the questionnaire for setting up a reduction protocol"}
	//	Button button_quest,disable=2

	PopupMenu popup_sam, pos={sc * 90, 105 * sc}, size={sc * 51, 23 * sc}, proc=V_SAMFilePopMenuProc
	PopupMenu popup_sam, mode=1, value=#"V_getSAMList()"
	PopupMenu popup_bkg, pos={sc * 90, 164 * sc}, size={sc * 51, 23 * sc}, proc=V_BKGFilePopMenuProc
	PopupMenu popup_bkg, mode=1, value=#"V_getBGDList()"
	PopupMenu popup_emp, pos={sc * 90, 213 * sc}, size={sc * 51, 23 * sc}, proc=V_EMPFilePopMenuProc
	PopupMenu popup_emp, mode=1, value=#"V_getEMPList()"
	PopupMenu popup_div, pos={sc * 90, 263 * sc}, size={sc * 51, 23 * sc}, proc=V_DIVFilePopMenuProc
	PopupMenu popup_div, mode=1, value=#"V_getDIVList()"
	PopupMenu popup_msk, pos={sc * 90, 356 * sc}, size={sc * 51, 23 * sc}, proc=V_MSKFilePopMenuProc
	PopupMenu popup_msk, mode=1, value=#"V_getMSKList()"

	PopupMenu popup_HRN, pos={sc * 10, 48 * sc}, size={sc * 51, 23 * sc}, proc=V_HRNoiseFilePopMenuProc
	PopupMenu popup_HRN, mode=1, value=#"V_getBGDList()"
	PopupMenu popup_HRN, title="HR Read Noise"

	CheckBox prot_check, pos={sc * 6, 163 * sc}, size={sc * 74, 14 * sc}, title="Background"
	CheckBox prot_check, help={"If checked, the specified background file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check, value=1
	CheckBox prot_check_1, pos={sc * 6, 215 * sc}, size={sc * 71, 14 * sc}, title="Empty Cell"
	CheckBox prot_check_1, help={"If checked, the specified empty cell file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_1, value=1
	CheckBox prot_check_2, pos={sc * 6, 263 * sc}, size={sc * 72, 14 * sc}, title="Sensitivity"
	CheckBox prot_check_2, help={"If checked, the specified detector sensitivity file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_2, value=1
	CheckBox prot_check_3, pos={sc * 6, 356 * sc}, size={sc * 43, 14 * sc}, title="Mask"
	CheckBox prot_check_3, help={"If checked, the specified mask file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_3, value=1
	CheckBox prot_check_4, pos={sc * 6, 105 * sc}, size={sc * 53, 14 * sc}, title="Sample"
	CheckBox prot_check_4, help={"If checked, the specified sample file will be included in the data reduction. If the file name is \"ask\", then the user will be prompted for the file"}
	CheckBox prot_check_4, value=1
	CheckBox prot_check_5, pos={sc * 6, 399 * sc}, size={sc * 56, 14 * sc}, title="Average"
	CheckBox prot_check_5, help={"If checked, the specified averaging will be performed at the end of the data reduction."}
	CheckBox prot_check_5, value=1
	CheckBox prot_check_9, pos={sc * 6, 310 * sc}, size={sc * 59, 14 * sc}, title="Absolute"
	CheckBox prot_check_9, help={"If checked, absolute calibration will be included in the data reduction. If the parameter list is \"ask\", then the user will be prompted for absolue parameters"}
	CheckBox prot_check_9, value=1

	//	Button pick_sam,pos={sc*214,28*sc},size={sc*70,20*sc},proc=V_PickSAMButton,title="set SAM"
	//	Button pick_sam,help={"This button will set the file selected in the File Catalog table to be the sample file"}
	//	Button pick_bgd,pos={sc*214,75*sc},size={sc*70,20*sc},proc=V_PickBGDButton,title="set BGD"
	//	Button pick_bgd,help={"This button will set the file selected in the File Catalog table to be the background file."}
	//	Button pick_emp,pos={sc*214,125*sc},size={sc*70,20*sc},proc=V_PickEMPButton,title="set EMP"
	//	Button pick_emp,help={"This button will set the file selected in the File Catalog table to be the empty cell file."}
	//	Button pick_DIV,pos={sc*214,173*sc},size={sc*70,20*sc},proc=V_PickDIVButton,title="set DIV"
	//	Button pick_DIV,help={"This button will set the file selected in the File Catalog table to be the sensitivity file."}
	Button pick_ABS, pos={sc * 264, 308 * sc}, size={sc * 80, 20 * sc}, proc=V_SetABSParamsButton, title="set ABS MF"
	Button pick_ABS, help={"This button will prompt the user for absolute scaling parameters"}

	Button pick_ABS_B, pos={sc * 264, 330 * sc}, size={sc * 80, 20 * sc}, proc=V_SetABSParamsButton, title="set ABS B"
	Button pick_ABS_B, help={"This button will prompt the user for absolute scaling parameters"}
	//	Button pick_MASK,pos={sc*214,266*sc},size={sc*70,20*sc},proc=V_PickMASKButton,title="set MASK"
	//	Button pick_MASK,help={"This button will set the file selected in the File Catalog table to be the mask file."}

	Button pick_AVE, pos={sc * 188, 401 * sc}, size={sc * 150, 20 * sc}, proc=V_SetAverageParamsButtonProc, title="set AVERAGE params"
	Button pick_AVE, help={"Prompts the user for the type of 1-D averaging to perform, as well as saving options"}

	Button pick_trim, pos={sc * 264, 454 * sc}, size={sc * 70, 20 * sc}, proc=V_TrimDataProtoButton, title="Trim"
	Button pick_trim, help={"This button will prompt the user for trimming parameters"}

	SetVariable HRNStr, pos={sc * 6, 72 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable HRNStr, help={"Filename of the high-resolution read noise file to be used in the data reduction"}
	SetVariable HRNStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gHRNoise

	SetVariable samStr, pos={sc * 6, 130 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable samStr, help={"Filename of the sample file(s) to be used in the data reduction"}
	SetVariable samStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	SetVariable bgdStr, pos={sc * 7, 186 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable bgdStr, help={"Filename of the background file(s) to be used in the data reduction"}
	SetVariable bgdStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gBGD
	SetVariable empStr, pos={sc * 8, 236 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable empStr, help={"Filename of the empty cell file(s) to be used in the data reduction"}
	SetVariable empStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gEMP
	SetVariable divStr, pos={sc * 9, 285 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable divStr, help={"Filename of the detector sensitivity file to be used in the data reduction"}
	SetVariable divStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gDIV
	SetVariable maskStr, pos={sc * 9, 377 * sc}, size={sc * 250, 15 * sc}, title="file:"
	SetVariable maskStr, help={"Filename of the mask file to be used in the data reduction"}
	SetVariable maskStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gMASK
	SetVariable absStr, pos={sc * 7, 331 * sc}, size={sc * 250, 15 * sc}, title="parameters:"
	SetVariable absStr, help={"Keyword-string of values necessary for absolute scaling of data. Remaining parameters are taken from the sample file."}
	SetVariable absStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
	SetVariable aveStr, pos={sc * 9, 424 * sc}, size={sc * 250, 15 * sc}, title="parameters:"
	SetVariable aveStr, help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
	SetVariable aveStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gAVE

	SetVariable begStr, pos={sc * 9, 464 * sc}, size={sc * 250, 15 * sc}, title="Beg Trim:"
	SetVariable begStr, help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
	SetVariable begStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	SetVariable endStr, pos={sc * 9, 484 * sc}, size={sc * 250, 15 * sc}, title="End Trim:"
	SetVariable endStr, help={"Keyword-string of choices used for averaging and saving the 1-D data files"}
	SetVariable endStr, limits={-Inf, Inf, 0}, value=root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr

	//only show DRK if user wants to see it
	//if global = 1,then show => set disable = 0
	//	CheckBox prot_check_6,pos={sc*6,363*sc},size={sc*113,14*sc},proc=DrkCheckProc,title="Use DRK correction"
	//	CheckBox prot_check_6,help={"If checked, the selected file will be used for DRK correction. Typically this is NOT checked"}
	//	CheckBox prot_check_6,value= 0,disable = (!root:Packages:NIST:gAllowDRK)
	//	SetVariable drkStr,pos={sc*120,363*sc},size={sc*150,15*sc},title="."
	//	SetVariable drkStr,help={"DRK detector count file"*sc},disable = (!root:Packages:NIST:gAllowDRK)
	//	SetVariable drkStr,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Protocols:gDRK

	Button export_button, size={sc * 120, 20 * sc}, pos={sc * 125, 540 * sc}, title="Export to Data", proc=V_ExportFileProtocol
	Button export_button, help={"Exports the protocol to data file on disk for Importing into another experiment"}
	Button import_button, size={sc * 120, 20 * sc}, pos={sc * 125, 562 * sc}, title="Import from Data", proc=V_ImportFileProtocol
	Button import_button, help={"Imports a protocol from a data file on disk for use in this experiment"}
	Button recallProt, pos={sc * 7, 540 * sc}, size={sc * 107, 20 * sc}, proc=V_RecallProtocolButton, title="Recall Protocol"
	Button recallProt, help={"Resets the panel to the file choices in  a previously saved protocol"}
	Button del_protocol, pos={sc * 7, 562 * sc}, size={sc * 110, 20 * sc}, proc=V_DeleteProtocolButton, title="Delete Protocol"
	Button del_protocol, help={"Use this to delete a previously saved protocol."}
	Button done_protocol, pos={sc * 285, 562 * sc}, size={sc * 45, 20 * sc}, proc=V_DoneProtocolButton, title="Done"
	Button done_protocol, help={"This button will close the panel. The panel can be recalled at any time from the SANS menu."}
	Button saveProtocol, pos={sc * 7, 518 * sc}, size={sc * 100, 20 * sc}, proc=V_SaveProtocolButton, title="Save Protocol"
	Button saveProtocol, help={"Saves the cerrent selections in the panel to a protocol which can be later recalled"}
	Button ReduceOne, pos={sc * 240, 518 * sc}, size={sc * 100, 20 * sc}, proc=V_ReduceOneButton, title="Reduce A File"
	Button ReduceOne, help={"Using the panel selections, the specified sample file will be reduced. If none is specified, the user will be prompted for a sample file"}

EndMacro

Function V_HRNoiseFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gHRNoise
			tempStr = popStr

			// load the file right now
			////Execute "LoadHighResReadNoiseData()"
			V_LoadHDF5Data(tempStr, "RAW")
			V_CopyHDFToWorkFolder("RAW", "ReadNoise")
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

Function V_SAMFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
			tempStr = popStr
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

Function V_BKGFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gBGD
			tempStr = popStr
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

Function V_EMPFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gEMP
			tempStr = popStr
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

Function V_DIVFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gDIV
			tempStr = popStr
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

Function V_MSKFilePopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum  = pa.popNum
			string   popStr  = pa.popStr
			SVAR     tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gMASK
			tempStr = popStr
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

////activated when user checks/unchecks the box
////either prompts for a file using a standard dialog, or removes the current file
//Function V_DrkCheckProc(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked		//Desired state, not previous state
//
//	SVAR drkStr=root:Packages:NIST:VSANS:Globals:Protocols:gDRK
//	if(checked==1)
//		//print "Unchecked on call"
//		//this just asks for the filename, doesn't open the file
//		String msgStr="Select the DRK file",fullPath="",fileStr=""
//		Variable refnum
//
//		Open/D/R/T="????"/M=(msgStr)/P=catPathName refNum
//		fullPath = S_FileName		//fname is the full path
//		if(cmpstr(fullpath,"")==0)
//			//user cancelled
//			CheckBox prot_check_6,value=0		//keep box unchecked
//			return(0)
//		Endif
//		fileStr=V_GetFileNameFromPathNoSemi(fullPath)
//		//Print fileStr
//		//update the global string
//		drkStr = ReplaceStringByKey("DRK",drkStr,fileStr,"=",",")
//		drkStr = ReplaceNumberByKey("DRKMODE", drkStr, 10 ,"=",",")
//	else
//		//print "checked on call"
//		drkStr="DRK=none,DRKMODE=0,"		//change the global
//	endif
//
//End

Function V_ShowProtoHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[VSANS Reduction Protocol]"
	if(V_flag != 0)
		DoAlert 0, "The VSANS Data Reduction Help file could not be found"
	endif
End

// -- this is a trimmed down version of the "full" set of averaging options
//    add to this as needed as I figure out what functionality is appropriate
//
//
//button action procedure to get the type of average requested by the user
//presented as a missing parameter dialog, which is really user-UN-friendly
//and will need to be re-thought. Defaults of dialog are set for normal
//circular average, so typically click "continue" and proceed
//
Function V_SetAverageParamsButtonProc(string ctrlName) : ButtonControl

	SVAR gAvgInfoStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr

	string av_typ, autoSave, AutoName, binType, side
	variable phi, dphi
	variable width  = 10
	variable Qctr   = 0.01
	variable qDelta = 10
	string detGroup

	if(strlen(gAvgInfoStr) > 0)
		//		fill the dialog with the current choice, not resetting to default
		// can't do this, or it will simply bypass the missing parameter dialog!
		//	V_GetAvgInfo(av_typ,autoSave,autoName,binType,qCtr,qDelta,detGroup)
		av_typ   = StringByKey("AVTYPE", gAvgInfoStr, "=", ";")
		autoSave = StringByKey("SAVE", gAvgInfoStr, "=", ";")
		autoName = StringByKey("NAME", gAvgInfoStr, "=", ";")
		binType  = StringByKey("BINTYPE", gAvgInfoStr, "=", ";")
		qCtr     = NumberByKey("QCENTER", gAvgInfoStr, "=", ";")
		qDelta   = NumberByKey("QDELTA", gAvgInfoStr, "=", ";")
		detGroup = StringByKey("DETGROUP", gAvgInfoStr, "=", ";")
		phi      = NumberByKey("PHI", gAvgInfoStr, "=", ";")
		dphi     = NumberByKey("DPHI", gAvgInfoStr, "=", ";")

		//	Execute "V_GetAvgInfo_Full()"
		//		Execute "V_GetAvgInfo()"
	endif

	//	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII;PNG_Graphic;Sector_PlusMinus;"
	Prompt av_typ, "Type of Average", popup, "Circular;Narrow_Slit;Annular;Sector;QxQy_ASCII;QxQy_NXcanSAS"

	// comment out above line in DEMO_MODIFIED version, and uncomment the line below (to disable PNG save)
	//	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII"
	Prompt autoSave, "Save files to disk?", popup, "Yes - Concatenate;Yes - Individual;No"
	Prompt autoName, "Auto-Name files?", popup, "Auto;Manual"
	//	Prompt autoPlot,"Plot the averaged Data?",popup,"Yes;No"
	Prompt side, "Include detector halves?", popup, "both;right;left"
	Prompt phi, "Orientation Angle (-90,90) degrees (Rectangular or Sector)"
	Prompt dphi, "Sector range (+/-) degrees (0,90) (Sector only)"
	//	Prompt width, "Width of Rectangular average (1,128)"
	Prompt binType, "Binning Type?", popup, ksBinTypeStr

	Prompt Qctr, "q-value of center of annulus"
	Prompt Qdelta, "(+/-) q-width of annulus"
	Prompt detGroup, "Group for annulus"

	DoPrompt "Enter Averaging Parameters", av_typ, autoSave, autoName, binType, qCtr, qDelta, detGroup, side, phi, dphi
	if(V_Flag)
		return (0) // User canceled
	endif

	//assign results of dialog to key=value string, semicolon separated
	//do only what is necessary, based on av_typ
	//
	// reset the string
	gAvgInfoStr = ""

	// hard wired value
	string autoPlot = "Yes"

	SVAR begStr = root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	SVAR endStr = root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr
	begStr = ksBinTrimBegDefault
	endStr = ksBinTrimEndDefault

	// override these default values for narrow slit case
	if(cmpstr(av_typ, "Narrow_Slit") == 0)
//		binType = "F2-M2-B"		//why was this set this way??
		binType = "SLIT-F2-M2-B"

		begStr = ksBinTrimBegZero
		endStr = ksBinTrimEndZero
	endif

	// all averages need these values
	gAvgInfoStr += "AVTYPE=" + av_typ + ";"
	gAvgInfoStr += "SAVE=" + autoSave + ";"
	gAvgInfoStr += "NAME=" + autoName + ";"
	gAvgInfoStr += "PLOT=" + autoPlot + ";"
	gAvgInfoStr += "BINTYPE=" + binType + ";"

	if(cmpstr(av_typ, "Sector") == 0 || cmpstr(av_typ, "Sector_PlusMinus") == 0)
		gAvgInfoStr += "SIDE=" + side + ";"
		gAvgInfoStr += "PHI=" + num2str(phi) + ";"
		gAvgInfoStr += "DPHI=" + num2str(dphi) + ";"
	endif
	//
	//	if(cmpstr(av_typ,"Rectangular")==0)
	//		gAvgInfoStr += "SIDE=" + side + ";"
	//		gAvgInfoStr += "PHI=" + num2str(phi) + ";"
	//		gAvgInfoStr += "WIDTH=" + num2str(width) + ";"
	//	Endif
	//
	if(cmpstr(av_typ, "Annular") == 0)
		gAvgInfoStr += "QCENTER=" + num2str(QCtr) + ";"
		gAvgInfoStr += "QDELTA=" + num2str(QDelta) + ";"
		gAvgInfoStr += "DETGROUP=" + detGroup + ";"
	endif

	//set the global string after user choices
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gAVE = gAvgInfoStr

	return (0)
End

//
// --- To avoid resetting the dialog with default values, the work is done in
// V_SetAverageParamsButtonProc --
//
//
//procedure called by protocol panel to ask user for average type choices
// somewhat confusing and complex, but may be as good as it gets.
//
//Proc V_GetAvgInfo(av_typ,autoSave,autoName,autoPlot,side,phi,dphi,width,QCtr,QDelta)
//Proc V_GetAvgInfo(av_typ,autoSave,autoName,binType,qCtr,qDelta,detGroup)
//	String av_typ,autoSave,AutoName,binType
////	Variable phi=0,dphi=10,width=10,Qctr = 0.01,qDelta=10
//	Variable Qctr=0.1,qDelta=0.01
//	String detGroup="F"
//
////	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII;PNG_Graphic;Sector_PlusMinus;"
//	Prompt av_typ, "Type of Average",popup,"Circular;Narrow_Slit;Annular;"
//
//// comment out above line in DEMO_MODIFIED version, and uncomment the line below (to disable PNG save)
////	Prompt av_typ, "Type of Average",popup,"Circular;Sector;Rectangular;Annular;2D_ASCII;QxQy_ASCII"
//	Prompt autoSave,"Save files to disk?",popup,"Yes - Concatenate;Yes - Individual;No"
//	Prompt autoName,"Auto-Name files?",popup,"Auto;Manual"
////	Prompt autoPlot,"Plot the averaged Data?",popup,"Yes;No"
////	Prompt side,"Include detector halves?",popup,"both;right;left"
////	Prompt phi,"Orientation Angle (-90,90) degrees (Rectangular or Sector)"
////	Prompt dphi, "Azimuthal range (0,45) degrees (Sector only)"
////	Prompt width, "Width of Rectangular average (1,128)"
//	Prompt binType,"Binning Type?",popup,ksBinTypeStr
//
//	Prompt Qctr, "q-value of center of annulus"
//	Prompt Qdelta,"(+/-) q-width of annulus"
//	Prompt detGroup,"Group for annulus"
//
//	//assign results of dialog to key=value string, semicolon separated
//	//do only what is necessary, based on av_typ
//	String/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr=""
//
//	// hard wired value
//	String autoPlot = "Yes"
//
//
//	// all averages need these values
//	root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "AVTYPE=" + av_typ + ";"
//	root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "SAVE=" + autoSave + ";"
//	root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "NAME=" + autoName + ";"
//	root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "PLOT=" + autoPlot + ";"
//	root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "BINTYPE=" + binType + ";"
//
////	if(cmpstr(av_typ,"Sector")==0 || cmpstr(av_typ,"Sector_PlusMinus")==0)
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "SIDE=" + side + ";"
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "PHI=" + num2str(phi) + ";"
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "DPHI=" + num2str(dphi) + ";"
////	Endif
////
////	if(cmpstr(av_typ,"Rectangular")==0)
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "SIDE=" + side + ";"
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "PHI=" + num2str(phi) + ";"
////		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "WIDTH=" + num2str(width) + ";"
////	Endif
////
//	if(cmpstr(av_typ,"Annular")==0)
//		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "QCENTER=" + num2str(QCtr) + ";"
//		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "QDELTA=" + num2str(QDelta) + ";"
//		root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr += "DETGROUP=" + detGroup + ";"
//	Endif
//End

//prompts the user to pick a previously created protocol from a popup list
//of given the option to create a new protocol
//the chosen protocol is passed back to the calling procedure by a global string
//the popup is presented as a missing parameter dialog (called with empty parameter list)
//
// MAXROWS is present to exclude the PanelNameW from appearing as a protocol
Proc V_PickAProtocol(protocol)
	string Protocol
	Prompt Protocol, "Pick A Protocol", popup, V_RecallableProtocols()

	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocol
EndMacro

Proc V_DeleteAProtocol(protocol)
	string Protocol
	//	Prompt Protocol "Delete A Protocol",popup, WaveList("*",";","TEXT:1")
	Prompt Protocol, "Delete A Protocol", popup, V_DeletableProtocols()

	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocol
EndMacro

Function/S V_DeletableProtocols()

	string list = WaveList("*", ";", "TEXT:1,MAXROWS:13")

	list = RemoveFromList("Base", list, ";")
	list = RemoveFromList("DoAll", list, ";")
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("wTTmpWrite", list, ";")
	if(cmpstr(list, "") == 0)
		list = "_no_protocols_;"
	endif

	return (list)
End

Function/S V_RecallableProtocols()

	string list = WaveList("*", ";", "TEXT:1,MAXROWS:13")

	//	list= RemoveFromList("Base", list  , ";")
	//	list= RemoveFromList("DoAll", list  , ";")
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("wTTmpWrite", list, ";")
	if(cmpstr(list, "") == 0)
		list = "_no_protocols_;"
	endif

	return (list)
End

//missing parameter dialog to solicit user for a waveStr for the protocol
//about to be created
//name is passed back as a global string and calling procedure is responsible for
//checking for wave conflicts and valid names
//
Proc V_AskForName(protocol)
	string Protocol
	Prompt Protocol, "Enter a new name for your protocol (no extension)"

	string/G root:Packages:NIST:VSANS:Globals:Protocols:gNewStr = protocol
EndMacro

//this is a lengthy procedure for sequentially polling the user about what data
//reduction steps they want to be performed during the protocol
//ensures that a valid protocol name was chosen, then fills out each "item"
//(6 total) needed for reduction
//it the user cancels at any point, the partial protocol will be deleted
//
Function V_ProtocolQuestionnaire(string ctrlName)

	string filename, cmd
	variable notDone, refnum

	//prompt for name of new protocol wave to save
	do
		Execute "V_AskForName()"
		SVAR newProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gNewStr

		//make sure it's a valid IGOR name
		newProtoStr = CleanupName(newProtoStr, 0) //strict naming convention
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gNewStr = newProtoStr //reassign, if changed
		//Print "newProtoStr = ",newProtoStr

		SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
		if(WaveExists($("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtoStr)) == 1)
			//wave already exists
			DoAlert 0, "that name is already in use. Please pick a new name"
			notDone = 1
		else
			//name is  good
			notDone = 0
		endif
	while(notDone)

	//Print "protocol questionnaire is "+newProtocol

	//make a new text wave (12 points) and fill it in, in response to questions
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols //(redundant - full wave specs are used)
	Make/O/T/N=(kNumProtocolSteps) $("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtoStr)
	WAVE/T newProtocol = $("root:Packages:NIST:VSANS:Globals:Protocols:" + newProtoStr)
	newProtocol = ""

	//ask the questions
	/////
	//*****Multiple files in these lists are full paths/filenames which may or may not
	//have semicolon version numbers in the filename. Therefore, construct the list with
	//COMMAS as separators - to avoid messy parsing
	///////

	string fileFilters = "VSANS Data Files (*.ngv,*.h5):.ngv,.h5;"
	//	fileFilters += "HTML Files (*.htm,*.html):.htm,.html;"
	fileFilters += "All Files:.*;"
	//////////////////////////
	string drkStr  = ""
	string fileStr = ""

	//////////////////////////
	//	DoAlert 1,"Do you want to correct your data for DRK (beam off) counts?"
	//	if(V_flag == 1)		//1=yes
	//		//prompt for DRK  file, but don't actually open it (/D flag)
	//		Open/D/R/F=fileFilters/M="Select the DRK file"/P=catPathName refnum
	//		//check for cancel
	//		if(strlen(S_filename)==0)
	//			//user cancelled, abort
	//			KillWaves/Z newProtocol
	//			SetDataFolder root:
	//			Abort "Incomplete protocol has been deleted"
	//		Endif
	//		//assign filename (just the name) to [6]
	//		fileStr = V_GetFileNameFromPathNoSemi(S_filename)
	//		drkStr = "DRK=none,DRKMODE=0,"
	//		drkStr = ReplaceStringByKey("DRK",drkStr,fileStr,"=",",")
	//		drkStr = ReplaceNumberByKey("DRKMODE", drkStr, 10 ,"=",",")
	//		newProtocol[6] = drkStr
	//	else
	//		//no Work.DRK desired
	//		newProtocol[6] = "DRK=none,DRKMODE=0,"
	//	Endif
	//
	////////////

	// TODO:
	// -- there is a lag in the V_pick() routine as it greps through all of the files. Several seconds even when there
	//   are 20-ish files. Pre-search for the strings? When to refresh them for new data?
	/////////////////
	DoAlert 1, "Do you want to subtract background from your data?"
	if(V_flag == 1) //1=yes

		Prompt filename, "BKG File", popup, V_PickBGDButton("")
		DoPrompt "Select File", filename
		if(V_Flag)
			return 0 // user canceled
		endif
		//		//assign filename to [0]
		newProtocol[0] = V_GetFileNameFromPathNoSemi(fileName)

		// OLD way, using an open file dialog
		// and allowing for multiple files to be added together
		//
		//		//prompt for background file, but don't actually open it (/D flag)
		//		Open/D/R/F=fileFilters/M="Select the Background data file"/P=catPathName refnum
		//		//check for cancel
		//		if(strlen(S_filename)==0)
		//			//user cancelled, abort
		//			KillWaves/Z newProtocol
		//			SetDataFolder root:
		//			Abort "Incomplete protocol has been deleted"
		//		Endif
		//		//assign filename (full path) to [0]
		//		newProtocol[0] = V_GetFileNameFromPathNoSemi(S_filename)

		//		notDone=1
		//		do
		//			//prompt for additional background files
		//			DoAlert 1,"Do you want to add another background file?"
		//			if(V_flag == 1)		//yes
		//				Open/D/R/F=fileFilters/M="Select another Background data file"/P=catPathName refnum
		//				//check for cancel
		//				if(strlen(S_filename)==0)
		//					//user cancelled, abort ********maybe just break out of the loop here
		//					KillWaves/Z newProtocol
		//					SetDataFolder root:
		//					Abort "Incomplete protocol has been deleted"
		//				Endif
		//				//assign filename (full path) to [0]
		//				newProtocol[0] += "," + V_GetFileNameFromPathNoSemi(S_filename)		//***COMMA separated list
		//				notDone = 1  		//keep going
		//			else
		//				notDone = 0			//no more to add
		//			Endif
		//		While(notDone)
		//////

	else //no background desired
		newProtocol[0] = "none"
	endif

	//////////////////////
	DoAlert 1, "Do you want to subtract empty cell scattering from your data?"
	if(V_flag == 1) //1=yes

		Prompt filename, "EMP File", popup, V_PickEMPButton("")
		DoPrompt "Select File", filename
		if(V_Flag)
			return 0 // user canceled
		endif
		//		//assign filename to [1]
		newProtocol[1] = V_GetFileNameFromPathNoSemi(fileName)

		//		//prompt for Empty cell file, but don't actually open it (/D flag)
		//		Open/D/R/F=fileFilters/M="Select the Empty Cell data file"/P=catPathName refnum
		//		//check for cancel
		//		if(strlen(S_filename)==0)
		//			//user cancelled, abort
		//			KillWaves/Z newProtocol
		//			SetDataFolder root:
		//			Abort "Incomplete protocol has been deleted"
		//		Endif
		//		//assign filename (full path) to [1]
		//		newProtocol[1] = V_GetFileNameFromPathNoSemi(S_filename)
		//
		//		notDone=1
		//		do
		//			//prompt for additional Empty Cell files
		//			DoAlert 1,"Do you want to add another Empty Cell file?"
		//			if(V_flag == 1)		//yes
		//				Open/D/R/F=fileFilters/M="Select another Empty Cell data file"/P=catPathName refnum
		//				//check for cancel
		//				if(strlen(S_filename)==0)
		//					//user cancelled, abort ********maybe just break out of the loop here
		//					KillWaves/Z newProtocol
		//					SetDataFolder root:
		//					Abort "Incomplete protocol has been deleted"
		//				Endif
		//				//assign filename (full path) to [1]
		//				newProtocol[1] += "," + V_GetFileNameFromPathNoSemi(S_filename)		//***COMMA separated list
		//				notDone = 1  		//keep going
		//			else
		//				notDone = 0			//no more to add
		//			Endif
		//		While(notDone)

	else //no background desired
		newProtocol[1] = "none"
	endif

	//////////////////////////
	DoAlert 1, "Do you want to correct your data for detector sensitivity?"

	if(V_flag == 1) //1=yes

		Prompt filename, "DIV File", popup, V_GetDIVList()
		DoPrompt "Select File", filename
		if(V_Flag)
			return 0 // user canceled
		endif
		//		//assign filename to [2]
		newProtocol[2] = V_GetFileNameFromPathNoSemi(fileName)

		//		//prompt for DIV  file, but don't actually open it (/D flag)
		//		Open/D/R/F=fileFilters/M="Select the detector sensitivity file"/P=catPathName refnum
		//		//check for cancel
		//		if(strlen(S_filename)==0)
		//			//user cancelled, abort
		//			KillWaves/Z newProtocol
		//			SetDataFolder root:
		//			Abort "Incomplete protocol has been deleted"
		//		Endif
		//		//assign filename (full path) to [2]
		//		newProtocol[2] = V_GetFileNameFromPathNoSemi(S_filename)

	else
		//no Work.DIV desired
		newProtocol[2] = "none"
	endif
	//////////////////////////
	DoAlert 1, "Do you want to mask your files before averaging?"

	if(V_flag == 1) //1=yes

		Prompt filename, "MASK File", popup, V_PickMASKButton("")
		DoPrompt "Select File", filename
		if(V_Flag)
			return 0 // user canceled
		endif
		//		//assign filename to [3]
		newProtocol[3] = V_GetFileNameFromPathNoSemi(fileName)

		//		//prompt for mask  file, but don't actually open it (/D flag)
		//		Open/D/R/F=fileFilters/M="Select the mask file"/P=catPathName refnum
		//		//check for cancel
		//		if(strlen(S_filename)==0)
		//			//user cancelled, abort
		//			KillWaves/Z newProtocol
		//			SetDataFolder root:
		//			Abort "Incomplete protocol has been deleted"
		//		Endif
		//		//assign filename (full path) to [3]
		//		newProtocol[3] = V_GetFileNameFromPathNoSemi(S_filename)

	else
		//no MASK desired
		newProtocol[3] = "none"
	endif

	//absolute scaling

	//////////////////////////
	//ABS parameters stored as keyword=value string
	DoAlert 1, "Do you want absolute scaling?"
	if(V_flag == 1) //1=yes
		//missing param - prompt for values, put in semicolon-separated list
		Execute "V_AskForAbsoluteParams_Quest()"
		SVAR absStr = root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
		newProtocol[4] = absStr
	else
		//no absolute scaling desired
		newProtocol[4] = "none"
	endif

	//type of average, plot?, auto/manual naming/saving... put in semicolon separated string
	//of KEY=<value> format for easy parsing
	//Kewords are: AVTYPE,PHI,DPHI,PLOT,SAVE,NAME,SIDE,WIDTH
	//note that AVTYPE,NAME,SIDE have string values, others have numerical values
	///////////////////////
	DoAlert 1, "Do you want to average your data to I vs. q?"
	if(V_flag == 1) //1=yes
		string/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = ""
		Execute "V_GetAvgInfo()" //will put up missing paramter dialog and do all the work
		//:gAvgInfo is reset by the Proc(), copy this string tot he protocol
		SVAR tempStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr

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
	endif

	//returns the name of the newly created (= currently in use) protocol wave through a global
	string/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = newProtoStr

	//reset the panel based on the protocol textwave (currently a string)
	V_ResetToSavedProtocol(newProtoStr)

	SetDataFolder root:

	return (0)
End

// TODO
// -- this function may not work properly for VSANS, but I haven't tested it yet
// -- I'd rather have some sort of display to show the current content of the WORK folders
//
// -- the global string fileList does not exist, so this will always fail and return zero
//
//
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
Function V_AreFilesThere(string type, string reqFiles)

	//in general, reqFiles is a list of full paths to files - which MAY include semicolon version numbers
	//reqFiles MUST be constructed with COMMAS as list separators, to avoid disaster
	//when the version numbers are interpreted as filenames

	//get the number of files requested
	variable nReq, nCur, match, ii
	nReq = ItemsInList(reqFiles, ",")

	//get the name of the file currently in BGD - in the global fileList
	//fileList has NAMES ONLY - since it was derived from the file header
	string testStr
	testStr = "root:Packages:NIST:" + type + ":fileList"
	if(Exists(testStr) == 2) //2 if string variable exists
		SVAR curFiles = $testStr
	else
		//no files currently in type folder, return zero
		return (0)
	endif
	//get the number of files already in folder
	nCur = ItemsInList(curFiles, ";")
	if(nCur != nReq)
		return (0) //quit now, the wrong number of files present
	endif
	//right number of files... are the names right...
	//check for a match (case-sensitive!!) of each requested file in the curFile string
	//need to extract filenames from reqFiles, since they're the full path and name

	ii = 0
	do
		testStr = StringFromList(ii, reqFiles, ",") //testStr is the Nth full path and filename
		//testStr = GetFileNameFromPathNoSemi(testStr)	//testStr will now be just the filename
		match = stringmatch(curFiles, testStr)
		if(!match)
			return (0) //req file was not found in curFile list - get out now
		endif
		ii += 1
	while(ii < nreq)

	return (1) //indicate that files are OK, no changes needed
End

//
//will add the files specified in the protocol to the "type" folder
//will add multiple files together if more than one file is requested
//(list is a comma delimited list of filenames, with NO path information)
//
// This routine NOW DOES check for the possibility that the filenames may have ";vers" from the
// VAX - data should be picked up from Charlotte, where it won't have version numbers.
//
Function V_AddFilesInList(string type, string list)

	//type is the work folder to put the data into, and list is a COMMA delimited list of paths/names
	variable num, ii, refNum
	variable err = 0
	string filename
	string pathStr = ""
	PathInfo catPathName //this is where the files are
	pathstr = S_path

	num = ItemsInList(list, ",") // comma delimited list

	ii = 0
	do
		//FindValidFilename only needed in case of vax version numbers
		filename = pathStr + V_FindValidFilename(StringFromList(ii, list, ","))
		Open/Z/R refnum as filename
		if(V_flag != 0) //file not found
			//Print "file not found AddFilesInList()"
			//Print filename
			err = 1
			return (err)
		endif
		Close refnum //file was found and opened, so close it

		//		Abort "Find equivalent to ReadHeaderAndData(filename)"
		//		ReadHeaderAndData(filename)
		err = V_LoadHDF5Data(filename, "RAW")

		if(ii == 0)
			//first pass, wipe out the old contents of the work file
			err = V_Raw_to_work(type)
		else
			err = V_Add_raw_to_work(type)
		endif
		ii += 1
	while(ii < num)
	return (err)
End

//function will reduce a sample file (or ask for file(s))
//using the protocol named as "protoStr" in the Protocols subfolder
//samStr is the file(s) or "ask" to force prompt
//sequentially proceeds through flowchart, doing reduction steps as needed
//show Schematic to debug what steps/values were used
//
//function is long, but straightforward logic
//
Function V_ExecuteProtocol(string protStr, string samStr)

	//protStr is the full path to the selected protocol wave
	//samStr is either "ask" or the name ONLY ofthe desired sample data file(s) (NO PATH)
	WAVE/T prot = $protStr
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

	variable filesOK, err, notDone
	string activeType, msgStr, junkStr
	string pathStr = ""
	PathInfo catPathName //this is where the files are
	pathStr = S_path

	//	NVAR useXMLOutput = root:Packages:NIST:gXML_Write

	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)
	//7 = beginning trim points
	//8 = end trim points
	//9 = collimation type for reduced data
	//10 = unused
	//11 = unused

	//////////////////////////////
	// DIV
	//////////////////////////////
	// for VSANS, DIV is used on each data file as it is converted to WORK, so it needs to be
	//  the first thing in place, before any data or backgrounds are loaded

	//check for work.div file (prot[2])
	//load in if needed
	// no math is done here, DIV is applied as files are converted to WORK (the first operation in VSANS)
	//

	// save the state of the DIV preference
	NVAR     gDoDIVCor       = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	variable saved_gDoDIVCor = gDoDIVCor

	err = V_Proto_LoadDIV(prot[2])

	if(err)
		SetDataFolder root:
		Abort "No file selected, data reduction aborted"
	endif

	//////////////////////////////
	// SAM
	//////////////////////////////

	// (DONE):
	// x- (DONE) - adding multiple files added allowed
	//	 -- NOTE detector corrections (including DIV) are done at the V_Raw_to_Work() step
	//   So if the DIV is not part of the protocol, be sure to set/reset the global preference
	//
	//prompt for sam data => read raw data, add to sam folder
	//or parse file(s) from the input paramter string
	activeType = "SAM"
	msgStr     = "Select sample data"

	err = V_Proto_LoadFile(samStr, activeType, msgStr)
	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "No file selected, data reduction aborted"
	endif

	// TODO
	// -- this may not be the most reliable way to pass the file name (for naming of the saved file later)
	SVAR   file_name     = root:file_Name
	string samFileLoaded = file_name //keep a copy of the sample file loaded

	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	samFiles = samStr

	//always update
	V_UpdateDisplayInformation(ActiveType)

	// TODO -- the logic here is flawed
	// check that the SAM file is of the same configuration as BGD or EMP, if they are used
	// need to be able to handle all of the permutations AND catch the "ask" cases

	variable filesMatch = 1 //assume OK

	if(cmpstr("none", prot[0]) == 0 || cmpstr("ask", prot[0]) == 0)
		// BGD not identified, try EMP.
		if(cmpstr("none", prot[1]) == 0 || cmpstr("ask", prot[1]) == 0)
			// EMP not identified either, no mismatch possible
		else
			// compare to EMP
			filesMatch = V_RawFilesMatchConfig(samFileLoaded, StringFromList(0, prot[1], ","))
		endif
	else
		// BGD is identified, compare
		filesMatch = V_RawFilesMatchConfig(samFileLoaded, StringFromList(0, prot[0], ","))
	endif

	if(filesMatch == 0)
		Abort "SAM data is not the same configuration as the protocol."
		SetDataFolder root:
	endif

	//////////////////////////////
	// BGD
	//////////////////////////////

	//check for BGD file  -- "ask" might not fail - "ask?" will - ? not allowed in VAX filenames
	// add if needed
	//use a "case" statement
	msgStr     = "Select background file"
	activeType = "BGD"

	err = V_Proto_LoadFile(prot[0], activeType, msgStr)
	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "No file selected, data reduction aborted"
	endif

	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation(ActiveType)

	//////////////////////////////
	// EMP
	//////////////////////////////

	//check for emp file (prot[1])
	// add if needed
	msgStr     = "Select empty cell data"
	activeType = "EMP"

	err = V_Proto_LoadFile(prot[1], activeType, msgStr)
	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "No file selected, data reduction aborted"
	endif

	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation(ActiveType)

	//////////////////////////////
	// CORRECT
	//////////////////////////////

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

	/////// DRK is SKIPPED

	//	//read in the DRK data if necessary
	//	//only one file, assumed to be RAW data
	//	//
	//	String fname="",drkStr=""
	//	drkStr=StringByKey("DRK",prot[6],"=",",")
	//	if(cmpstr(drkStr,"none") != 0)
	//		err = ReadHeaderAndData( (pathStr+drkStr) )
	//		if(err)
	//			PathInfo/S catPathName
	//			Abort "reduction sequence aborted"
	//		endif
	//		err = V_Raw_to_Work_NoNorm("DRK")
	//	endif

	//dispatch to the proper "mode" of Correct()
	//	V_Dispatch_to_Correct(bgdStr,empStr,drkStr)
	V_Dispatch_to_Correct(prot[0], prot[1], prot[6])

	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "error in Correct, called from executeprotocol, normal cor"
	endif
	activeType = "COR"

	// always update - COR will always be generated
	V_UpdateDisplayInformation(ActiveType)

	//
	// DIV is not done here any more (CAL is not generated)
	// since the DIV step is done at V_Raw_to_Work() step -- doing it here would be
	// double-DIV-ing
	//

	//////////////////////////////
	//  ABSOLUTE SCALE
	//////////////////////////////

	err = V_Proto_ABS_Scale(prot[4], activeType) //activeType is pass-by-reference and updated IF ABS is used

	if(err)
		SetDataFolder root:
		Abort "Error in V_Absolute_Scale(), called from V_ExecuteProtocol"
	endif
	//	activeType = "ABS"

	//////////////////////////////
	// MASK
	//////////////////////////////
	//
	// DONE
	//	x- be sure that the mask reads only the single listed file, not trying to parse for multiple run numbers
	//		x- fill in the "ask" step
	//  x- none is OK, except if the kill fails for any reason
	// x- the regular case of the file name specified by the protocol works correctly
	// x- don't create a null mask if not used, it will handle the error and print out that the mask is missing
	//
	//mask data if desired (mask is applied when the data is binned to I(q)) and is
	//not done explicitly here

	//check for mask
	//doesn't change the activeType
	V_Proto_ReadMask(prot[3])

	//////////////////////////////
	// AVERAGING
	//////////////////////////////

	// average/save data as specified
	//Parse the keyword=<Value> string as needed, based on AVTYPE

	//average/plot first
	string av_type = StringByKey("AVTYPE", prot[5], "=", ";")
	if(cmpstr(av_type, "none") != 0)
		if(cmpstr(av_type, "") == 0) //if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit in the panel
			V_SetAverageParamsButtonProc("dummy") //from "ProtocolAsPanel"
			SVAR tempAveStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE", tempAveStr, "=", ";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			string/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = prot[5]
		endif
	endif

	string detGroup = StringByKey("DETGROUP", prot[5], "=", ";") //only for annular, null if not present

	//convert the folder to linear scale before averaging, then revert by calling the window hook
	// (not needed for VSANS, data is always linear scale)

	//
	// (DONE)
	// -x this generates a "Bin Type Not Found" error if reducing only to a 2D level (like for DIV)
	//		because binTypeStr is null
	string binTypeStr = StringByKey("BINTYPE", prot[5], "=", ";")
	// plotting is not really necessary, and the graph may not be open - so skip for now?
	variable binType
	// only get the binning type if user asks for averaging
	if(cmpstr(av_type, "none") != 0)
		binType = V_BinTypeStr2Num(binTypeStr)
		if(binType == 0)
			Abort "Binning mode not found in V_QBinAllPanels() " // when no case matches
		endif
	endif

	// identify the collimation type
	// this will be a string used to determine how the resolution information is to be calculated
	// and written to the reduced data file
	//
	// possible values are:
	//
	// pinhole
	// pinhole_whiteBeam
	// narrowSlit
	// narrowSlit_whiteBeam
	// convergingPinholes
	//

	string collimationStr
	collimationStr = V_IdentifyCollimation(activeType)

	////////////////////////////////////////
	// DISPATCH TO AVERAGING
	/////////////////////////////////////////
	//
	// TODO:
	// -- do I calculate the proper resolution here?, YES, I've already decoded the binning type
	//   and the averaging type has been specified by the protocol.
	//
	// so currently, the resolution is calculated every time that the data is averaged (in VC_fDoBinning_QxQy2D)
	//
	// -- if I calculate the resolution here, then the Trimming routines must be updated
	//    to trim the resolution waves also. This will work for the columns present in
	//    pinhole resolution, but anything using the matrix method - it won't work - and I'll need
	//    a different solution
	//

	V_Proto_doAverage(prot[5], av_type, activeType, binType, collimationStr)

	////////////////////////
	// PLOT THE DATA
	////////////////////////

	V_Proto_doPlot(prot[5], av_type, activeType, binType, detGroup)

	////////////////////
	// SAVE THE DATA
	////////////////////

	//
	// x- how do I get the sample file name?
	//    local variable samFileLoaded is the file name loaded (contains the extension)
	//
	// V_Proto_SaveFile(avgStr,activeType,samFileLoaded,av_type,binType,detGroup,trimBegStr,trimEndStr)
	//
	// this step does more than save...
	// - trims the selected points from the data set
	// - concatenates the data sets
	// - removes NaN points and removes duplicate q-values by averaging q-values that are within 0.1% of each other
	//

	prot[9] = collimationStr

	V_Proto_SaveFile(prot[5], activeType, samFileLoaded, av_type, binType, detGroup, prot[7], prot[8])

	//////////////////////////////
	// DONE WITH THE PROTOCOL
	//////////////////////////////

	// reset any global preferences that I had changed
	gDoDIVCor = saved_gDoDIVCor

	return (0)
End

//missing parameter dialog to solicit the 4 absolute intensity parameters
//from the user
//values are passed back as a global string variable (keyword=value)
//
Proc V_AskForAbsoluteParams(c2, c3, c4, c5, I_err, back_values)
	variable c2          = 1
	variable c3          = 1
	variable c4          = 1e8
	variable c5          = 1
	variable I_err       = 1
	string   back_values = "no"
	Prompt c2, "Standard Transmission"
	Prompt c3, "Standard Thickness (cm)"
	Prompt c4, "I(0) from standard fit (normalized to 1E8 monitor cts)"
	Prompt c5, "Standard Cross-Section (cm-1)"
	Prompt I_err, "error in I(q=0) (one std dev)"
	prompt back_values, "are these values for the back detector (yes/no)?"

	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

	if(cmpstr(back_values, "no") == 0)
		gAbsStr = ReplaceStringByKey("TSTAND", gAbsStr, num2str(c2), "=", ";")
		gAbsStr = ReplaceStringByKey("DSTAND", gAbsStr, num2str(c3), "=", ";")
		gAbsStr = ReplaceStringByKey("IZERO", gAbsStr, num2str(c4), "=", ";")
		gAbsStr = ReplaceStringByKey("XSECT", gAbsStr, num2str(c5), "=", ";")
		gAbsStr = ReplaceStringByKey("SDEV", gAbsStr, num2str(I_err), "=", ";")
	else
		gAbsStr = ReplaceStringByKey("TSTAND_B", gAbsStr, num2str(c2), "=", ";")
		gAbsStr = ReplaceStringByKey("DSTAND_B", gAbsStr, num2str(c3), "=", ";")
		gAbsStr = ReplaceStringByKey("IZERO_B", gAbsStr, num2str(c4), "=", ";")
		gAbsStr = ReplaceStringByKey("XSECT_B", gAbsStr, num2str(c5), "=", ";")
		gAbsStr = ReplaceStringByKey("SDEV_B", gAbsStr, num2str(I_err), "=", ";")
	endif

	gAbsStr = RemoveFromList("ask", gAbsStr) //now that values are added, remove "ask"

	SetDataFolder root:
EndMacro

//
// DONE
// x- fill in all of the functionality for calculation from direct beam
//  and verify that the calculations are numerically correct
//
//asks the user for absolute scaling information. the user can either
//enter the necessary values in manually (missing parameter dialog)
//or the user can select an empty beam file from a standard open dialog
//if an empty beam file is selected, the "kappa" value is automatically calculated
//in either case, the global keyword=value string is set.
//
//
// if isBack == 1, then the values are for the back panel
// AND there are different steps that must be done to subtract off
//  the read noise of the CCDs
//
Function V_AskForAbsoluteParams_Quest(variable isBack)

	variable err, loc, refnum

	variable ii

	variable kappa = 1
	variable kappa_err

	//get the necessary variables for the calculation of kappa
	variable countTime, monCnt, sdd, pixel_x, pixel_y
	string detStr, junkStr, errStr

	variable empAttenFactor, emp_atten_err

	//get the XY box and files
	variable x1, x2, y1, y2, emptyCts, empty_ct_err
	string emptyFileName, tempStr, divFileName, detPanel_toSum

	//ask user if he wants to use a transmision file for absolute scaling
	//or if he wants to enter his own information
	err = V_UseStdOrEmpForABS()
	//DoAlert 1,"<Yes> to enter your own values, <No> to select an empty beam flux file"
	if(err == 1)
		//secondary standard selected, prompt for values
		Execute "V_AskForAbsoluteParams()" //missing parameters
	else
		//empty beam flux file selected, prompt for file, and use this to calculate KAPPA

		// DONE
		// x- need an empty beam file name
		//
		Prompt emptyFileName, "Empty Beam File", popup, V_PickEMPBeamButton("")
		DoPrompt "Select File", emptyFileName
		if(V_Flag)
			return 0 // user canceled
		endif

		// DONE
		// x- need panel
		// x- now, look for the value in the file, if not there, ask

		detPanel_toSum = V_getReduction_BoxPanel(emptyFileName)
		if(strlen(detPanel_toSum) > 2)
			// it's the error message
			Prompt detPanel_toSum, "Panel with Direct Beam", popup, ksDetectorListAll
			DoPrompt "Select Panel", detPanel_toSum
			if(V_Flag)
				return 0 // user canceled
			endif
		endif

		//need the detector sensitivity file - make a guess, allow to override
		Prompt divFileName, "DIV File", popup, V_GetDIVList()
		DoPrompt "Select File", divFileName
		if(V_Flag)
			return 0 // user canceled
		endif
		V_LoadHDF5Data(divFileName, "DIV")

		WAVE xyBoxW = V_getBoxCoordinates(emptyFileName)

		// load in the data, and use all of the corrections, especially DIV
		// (be sure the corrections are actually set to "on", don't assume that they are)
		// save preferences for file loading
		variable savDivPref, savSAPref
		NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
		savDivPref = gDoDIVCor
		NVAR gDoSolidAngleCor = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
		savSAPref = gDoSolidAngleCor

		// set local preferences
		gDoDIVCor        = 1
		gDoSolidAngleCor = 1

		V_LoadAndPlotRAW_wName(emptyFileName)

		V_UpdateDisplayInformation("RAW")

		// do the DIV correction
		if(gDoDIVCor == 1)
			// need extra check here for file existence
			// if not in DIV folder, load.
			// if unable to load, skip correction and report error (Alert?) (Ask to Load?)
			Print "Doing DIV correction" // for "+ detStr
			for(ii = 0; ii < ItemsInList(ksDetectorListAll); ii += 1)
				detStr = StringFromList(ii, ksDetectorListAll, ";")
				WAVE w     = V_getDetectorDataW("RAW", detStr)
				WAVE w_err = V_getDetectorDataErrW("RAW", detStr)

				V_DIVCorrection(w, w_err, detStr, "RAW") // do the correction in-place
			endfor
		else
			Print "DIV correction NOT DONE" // not an error since correction was unchecked
		endif

		// and determine box sum and error
		// store these locally
		variable tmpReadNoiseLevel, tmpReadNoiseLevel_Err

		// TODO: change the math to do the filtering and subtraction both here in this step,
		// then determine the patch sum and proper error propogation.
		//
		// just do the median filter now, do the background subtraction later on the patch
		if(isBack)
			WAVE w               = V_getDetectorDataW("RAW", "B")
			NVAR gHighResBinning = root:Packages:NIST:VSANS:Globals:gHighResBinning
			switch(gHighResBinning)
				case 1:
					tmpReadNoiseLevel     = kReadNoiseLevel_bin1     // a constant value
					tmpReadNoiseLevel_Err = kReadNoiseLevel_Err_bin1 // a constant value

					//					MatrixFilter /N=11 /P=1 median w			//		/P=n flag sets the number of passes (default is 1 pass)
					//					Print "*** median noise filter 11x11 applied to the back detector (1 pass) ***"
					Print "*** 1x1 binning, NO FIlTER ***"
					break
				case 4:
					tmpReadNoiseLevel     = kReadNoiseLevel_bin4     // a constant value
					tmpReadNoiseLevel_Err = kReadNoiseLevel_Err_bin4 // a constant value

					//					MatrixFilter /N=3 /P=3 median w			//		/P=n flag sets the number of passes (default is 1 pass)

					//					Print "*** median noise filter 3x3 applied to the back detector (3 passes) ***"
					Print "*** 4x4 binning, NO FIlTER ***"

					break
				default:
					Abort "No binning case matches in V_AskForAbsoluteParams_Quest"
			endswitch

		endif

		emptyCts = V_SumCountsInBox(xyBoxW[0], xyBoxW[1], xyBoxW[2], xyBoxW[3], empty_ct_err, "RAW", detPanel_toSum)

		Print "empty counts = ", emptyCts
		Print "empty err/counts = ", empty_ct_err / emptyCts

		// if it's the back panel, find the read noise to subtract
		// shift the marquee to the right to (hopefully) a blank spot
		variable noiseCts, noiseCtsErr, delta, nPixInBox
		if(isBack)

			//			delta = xyBoxW[1] - xyBoxW[0]
			//			noiseCts = V_SumCountsInBox(xyBoxW[1],xyBoxW[1]+delta,xyBoxW[2],xyBoxW[3],noiseCtsErr,"RAW",detPanel_toSum)
			//
			//			print "average read noise per pixel = ",noiseCts/(xyBoxW[1]-xyBoxW[0])/(xyBoxW[3]-xyBoxW[2])
			//			Print "read noise counts = ",noiseCts
			//			Print "read noise err/counts = ",noiseCtsErr/noiseCts
			//
			//			emptyCts -= noiseCts
			//			empty_ct_err = sqrt(empty_ct_err^2 + noiseCtsErr^2)

			// Instead, use the defined constant values
			//		kReadNoiseLevel
			//		kReadNoiseLevel_Err
			//
			nPixInBox    = (xyBoxW[1] - xyBoxW[0]) * (xyBoxW[3] - xyBoxW[2])
			emptyCts    -= tmpReadNoiseLevel * nPixInBox
			empty_ct_err = sqrt(empty_ct_err^2 + (tmpReadNoiseLevel_Err * nPixInBox)^2)

			Print "adjusted empty counts = ", emptyCts
			Print "adjusted err/counts = ", empty_ct_err / emptyCts
		endif

		//
		// x- get all of the proper values for the calculation
		// -x currently the attenuation is incorrect
		//   such that kappa_err = 1*kappa
		// x- verify the calculation (no solid angle needed??)

		// get the attenuation factor for the empty beam
		//  -- the attenuation is not written by NICE to the file
		//  so I need to calculate it myself from the tables
		//
		//		empAttenFactor = V_getAttenuator_transmission(emptyFileName)
		//		emp_atten_err = V_getAttenuator_trans_err(emptyFileName)
		empAttenFactor = V_CalculateAttenuationFactor(emptyFileName)
		emp_atten_err  = V_CalculateAttenuationError(emptyFileName)

		countTime = V_getCount_time(emptyFileName)

		// TODO
		// -- not sure if this is the correct monitor count to use
		monCnt = V_getBeamMonNormData("RAW")

		pixel_x  = V_getDet_x_pixel_size("RAW", detPanel_toSum)
		pixel_x /= 10 //convert mm to cm, since sdd in cm
		pixel_y  = V_getDet_y_pixel_size("RAW", detPanel_toSum)
		pixel_y /= 10 //convert mm to cm, since sdd in cm
		sdd      = V_getDet_ActualDistance("RAW", detPanel_toSum)

		//
		// ** this kappa is different than for SANS!!
		//
		// don't use the solid angle here -- the data (COR) that this factor is applied to will already be
		// converted to counts per solid angle per pixel
		//
		//		kappa = emptyCts/countTime/empAttenFactor*1.0e8/(monCnt/countTime)*(pixel_x*pixel_y/sdd^2)
		kappa = emptyCts / countTime / empAttenFactor * 1.0e8 / (monCnt / countTime)

		kappa_err = (empty_ct_err / emptyCts)^2 + (emp_atten_err / empAttenFactor)^2
		kappa_err = sqrt(kappa_err) * kappa

		// x- set the parameters in the global string
		junkStr = num2str(kappa)
		errStr  = num2Str(kappa_err)

		string strToExecute = ""

		if(isBack)
			sprintf strToExecute, "V_AskForAbsoluteParams(1,1,%g,1,%g,\"%s\")", kappa, kappa_err, "yes" //no missing parameters, no dialog
		else
			sprintf strToExecute, "V_AskForAbsoluteParams(1,1,%g,1,%g,\"%s\")", kappa, kappa_err, "no" //no missing parameters, no dialog
		endif
		//		print strToExecute
		Execute strToExecute

		Printf "Kappa was successfully calculated as = %g +/- %g (%g %%)\r", kappa, kappa_err, (kappa_err / kappa) * 100

		// restore preferences on exit
		gDoDIVCor        = savDivPref
		gDoSolidAngleCor = savSAPref

	endif

End

Function V_UserSelectBox_Continue(string ctrlName) : buttonControl

	DoWindow/K junkWindow //kill panel
End

Function V_SelectABS_XYBox(variable &x1, variable &x2, variable &y1, variable &y2)

	variable sc = 1

	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode

	if(gLaptopMode == 1)
		sc = 0.7
	endif

	variable err = 0

	variable/G root:V_marquee = 1 //sets the sneaky bit to automatically update marquee coords
	variable/G root:V_left, root:V_right, root:V_bottom, root:V_top //must be global for auto-update
	DoWindow/F SANS_Data
	NewPanel/K=2/W=(139 * sc, 341 * sc, 382 * sc, 432 * sc) as "Select the primary beam"
	DoWindow/C junkWindow
	AutoPositionWindow/E/M=1/R=SANS_Data

	Drawtext 21 * sc, 20 * sc, "Select the primary beam with the"
	DrawText 21 * sc, 40 * sc, "marquee and press continue"
	Button button0, pos={sc * 80, 58 * sc}, size={sc * 92, 20 * sc}, title="Continue"
	Button button0, proc=V_UserSelectBox_Continue

	PauseForUser junkWindow, SANS_Data

	DoWindow/F SANS_Data

	//GetMarquee left,bottom			//not needed
	NVAR V_left   = V_left
	NVAR V_right  = V_right
	NVAR V_bottom = V_bottom
	NVAR V_top    = V_top

	x1 = V_left
	x2 = V_right
	y1 = V_bottom
	y2 = V_top
	//	Print "new values,before rounding = ",x1,x2,y1,y2

	// TODO -- replace this call
	//	KeepSelectionInBounds(x1,x2,y1,y2)
	//Print "new values = ",x1,x2,y1,y2

	KillVariables/Z root:V_Marquee, root:V_left, root:V_right, root:V_bottom, root:V_top
	if((x1 - x2) == 0 || (y1 - y2) == 0)
		err = 1
	endif
	return (err)
End

Function V_UseStdOrEmpForABS()

	variable sc = 1

	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode

	if(gLaptopMode == 1)
		sc = 0.7
	endif

	NewPanel/K=2/W=(139 * sc, 341 * sc, 402 * sc, 448 * sc) as "Absolute Scaling"
	DoWindow/C junkABSWindow
	ModifyPanel cbRGB=(57346, 65535, 49151)
	SetDrawLayer UserBack
	SetDrawEnv fstyle=1, fsize=12 * sc
	DrawText 21 * sc, 20 * sc, "Method of absolute calibration"
	Button button0, pos={sc * 52, 33 * sc}, size={sc * 150, 20 * sc}, proc=V_UserSelectABS_Continue, title="Empty Beam Flux"
	Button button1, pos={sc * 52, 65 * sc}, size={sc * 150, 20 * sc}, proc=V_UserSelectABS_Continue, title="Secondary Standard"

	PauseForUser junkABSWindow
	NVAR val = root:Packages:NIST:VSANS:Globals:tmpAbsVal
	return (val)
End

//returns 0 if button0 (empty beam flux)
// or 1 if secondary standard
Function V_UserSelectABS_Continue(string ctrlName) : buttonControl

	variable val = 0
	if(cmpstr(ctrlName, "button0") == 0)
		val = 0
	else
		val = 1
	endif
	//	print "val = ",ctrlName,val
	variable/G root:Packages:NIST:VSANS:Globals:tmpAbsVal = val
	DoWindow/K junkABSWindow //kill panel
	return (0)
End

Function V_TrimDataProtoButton(string ctrlName) : buttonControl

	Execute "V_CombineDataGraph()"
	return (0)
End

//
// export protocol to a data file
//
//
Function V_ExportFileProtocol(string ctrlName) : ButtonControl

	// get a list of protocols
	string Protocol = ""
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	Prompt Protocol, "Pick A Protocol", popup, V_DeletableProtocols()
	DoPrompt "Pick A Protocol to Export", Protocol
	if(V_flag == 1)
		//Print "user cancel"
		SetDatafolder root:
		return (1)
	endif

	string fileName = V_DoSaveFileDialog("pick the file to write to")
	print fileName
	//
	if(strlen(fileName) == 0)
		return (0)
	endif

	V_writeReductionProtocolWave(fileName, $("root:Packages:NIST:VSANS:Globals:Protocols:" + Protocol))

	setDataFolder root:
	return (0)

End

//
// imports a protocol from a file on disk into the protocols folder
//
//
Function V_ImportFileProtocol(string ctrlName) : ButtonControl

	//	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

	string fullPath, fileName
	fullPath = DoOpenFileDialog("Import Protocol from file")
	print fullPath
	//
	if(strlen(fullPath) == 0)
		return (0)
	endif

	fileName = ParseFilePath(0, fullPath, ":", 1, 0) //just the file name at the end of the full path

	WAVE/T tmpW = V_getReductionProtocolWave(fileName)
	if(numpnts(tmpW) == 0)
		DoAlert 0, "No protocol wave has been saved to this data file"
		return (0)
	endif

	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	string newName
	newName = CleanupName(fileName, 0) + "_proto"
	duplicate/O tmpw, $newName

	SetDataFolder root:
	return (0)
End

// currently not used - and not updated to 12 point protocols (5/2017)
//
//save the protocol as an IGOR text wave (.itx)
//
//
Function V_ExportProtocol(string ctrlName) : ButtonControl

	// get a list of protocols
	string Protocol = ""
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	Prompt Protocol, "Pick A Protocol", popup, WaveList("*", ";", "")
	DoPrompt "Pick A Protocol to Export", Protocol
	if(V_flag == 1)
		//Print "user cancel"
		SetDatafolder root:
		return (1)
	endif
	//get the selection, or exit
	WAVE/T pW = $protocol
	Make/O/T/N=13 tw
	// save in the proper format (must write manually, for demo version)
	tw[0]     = "IGOR"
	tw[1]     = "WAVES/T \t" + protocol
	tw[2]     = "BEGIN"
	tw[3, 10] = "\t\"" + pW[p - 3] + "\""
	tw[11]    = "END"
	tw[12]    = "X SetScale/P x 0,1,\"\"," + protocol + "; SetScale y 0,0,\"\"," + protocol

	variable refnum
	string   fullPath

	PathInfo/S catPathName
	fullPath = DoSaveFileDialog("Export Protocol as", fname = Protocol, suffix = "")
	if(cmpstr(fullPath, "") == 0)
		//user cancel, don't write out a file
		Close/A
		Abort "no Protocol file was written"
	endif

	//actually open the file
	Open refNum as fullpath + ".itx"

	wfprintf refnum, "%s\r", tw
	Close refnum
	//Print "all is well  ",protocol
	KillWaves/Z tw
	setDataFolder root:
	return (0)

End

// currently not used - and not updated to 12 point protocols (5/2017)
//imports a protocol from disk into the protocols folder
//
// will overwrite existing protocols if necessary
//
//
Function V_ImportProtocol(string ctrlName) : ButtonControl

	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

	string fullPath

	PathInfo/S catPathName
	fullPath = DoOpenFileDialog("Import Protocol")
	if(cmpstr(fullPath, "") == 0)
		//user cancel, don't write out a file
		Close/A
		Abort "no protocol was loaded"
	endif

	LoadWave/O/T fullPath

	SetDataFolder root:
	return (0)
End

///////////////////////////////////////
//
// individual steps in the protocol
//
//////////////////////////////////////

Function V_Proto_LoadDIV(string protStr)

	string divFileName = ""
	string junkStr     = ""
	string pathStr     = ""
	PathInfo catPathName //this is where the files are
	pathStr = S_path

	if(cmpstr("none", protStr) != 0) // if !0, then there's a file requested
		if(cmpstr("ask", protStr) == 0)
			//ask user for file
			//			 junkStr = PromptForPath("Select the detector sensitivity file")
			Prompt divFileName, "DIV File", popup, V_GetDIVList()
			DoPrompt "Select File", divFileName

			if(strlen(divFileName) == 0)
				//
				return (1) //error
				//				SetDataFolder root:
				//				Abort "No file selected, data reduction aborted"
			endif
			V_LoadHDF5Data(divFileName, "DIV")
		else
			//assume it's a path, and that the first (and only) item is the path:file
			//list processing is necessary to remove any final comma
			junkStr = pathStr + StringFromList(0, protStr, ",")
			V_LoadHDF5Data(junkStr, "DIV")
		endif

	else
		// DIV step is being skipped
		NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
		//		Variable saved_gDoDIVCor = gDoDIVCor
		gDoDIVCor = 0 // protocol says to turn it off for now (reset later)
	endif

	return (0)
End

//
// fileStr is the file name (or list of names)
// activeType is the target work folder
// msgStr is the string for the prompt
//
Function V_Proto_LoadFile(string fileStr, string activeType, string msgStr)

	variable err, filesOK, notDone

	//Ask for Type file or parse
	do
		if((cmpstr(fileStr, "ask") == 0) || (cmpstr(fileStr, "") == 0)) //zero if strings are equal
			err = V_LoadHDF5Data("", "RAW") //will prompt for file
			if(err)
				return (err) //error
				//PathInfo/S catPathName
				//Abort "reduction sequence aborted"
			endif
			V_UpdateDisplayInformation("RAW") //display the new type of data that was loaded
			err = V_Raw_to_work(activeType) //this is the first file (default)
			//Ask for another TYPE file
			do
				DoAlert 1, "Do you want to add another " + activeType + " file?"
				if(V_flag == 1) //yes
					err = V_LoadHDF5Data("", "RAW") //will prompt for file
					if(err)
						return (1) //error
						//PathInfo/S catPathName
						//Abort "reduction sequence aborted"
					endif
					V_UpdateDisplayInformation("RAW") //display the new type of data that was loaded
					err     = V_Add_raw_to_work(activeType)
					notDone = 1
				else
					notDone = 0
				endif
			while(notDone)
			//Loader is in charge of updating, since it knows if data was loaded
			V_UpdateDisplayInformation(ActiveType)
			break
		endif
		//"none" is not an option - you always need a sample file - "none" will never return zero
		//if not "ask" AND not "none" then try to parse the filenames
		if((cmpstr(fileStr, "none") != 0) && (cmpstr(fileStr, "ask") != 0))
			//filesOK = AreFilesThere(activeType,fileStr)		//return 1 if correct files are already there
			filesOK = 0 // Feb 2008, always force a reload of files. Maybe slow, but always correct
			if(!filesOK)
				//add the correct file(s) to Type

				// (DONE)-- adding multiple files is allowed
				err = V_AddFilesInList(activeType, fileStr)

				if(err)
					//Print "fileStr = ",fileStr
					DoAlert 0, fileStr + " file not found, reset file"
					return (err) //error
				endif
			endif
			//Loader is in charge of updating, since it knows if data was loaded
			V_UpdateDisplayInformation(ActiveType)
		endif
	while(0)

	return (0)
End

Function V_Dispatch_to_Correct(string bgdStr, string empStr, string drkStr)

	variable val, err
	variable mode = 4

	if((cmpstr("none", bgdStr) == 0) && (cmpstr("none", empStr) == 0))
		//no subtraction (mode = 4),
		mode = 4
	endif
	if((cmpstr(bgdStr, "none") != 0) && (cmpstr(empStr, "none") == 0))
		//subtract BGD only
		mode = 2
	endif
	if((cmpstr(bgdStr, "none") == 0) && (cmpstr(empStr, "none") != 0))
		//subtract EMP only
		mode = 3
	endif
	if((cmpstr(bgdStr, "none") != 0) && (cmpstr(empStr, "none") != 0))
		// bkg and emp subtraction are to be done (BOTH not "none")
		mode = 1
	endif
	//	activeType = "COR"
	//add in DRK mode (0= not used, 10 = used)
	// TODO: DRK has been de-activated for now
	//	val = NumberByKey("DRKMODE",drkStr,"=","," )
	//	mode += val

	//		print "mode = ",mode

	err = V_Correct(mode)
	if(err)
		return (err)
		//		SetDataFolder root:
		//		Abort "error in Correct, called from executeprotocol, normal cor"
	endif

	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation("COR")

	return (0)
End

Function V_Proto_ABS_Scale(string absStr, string &activeType)

	variable c2, c3, c4, c5, kappa_err, err
	//do absolute scaling if desired

	if(cmpstr("none", absStr) != 0)
		if(cmpstr("ask", absStr) == 0)
			//			//get the params from the user
			//			Execute "V_AskForAbsoluteParams_Quest()"
			//			//then from the list
			//			SVAR junkAbsStr = root:Packages:NIST:VSANS:Globals:Protocols:gAbsStr
			//			c2 = NumberByKey("TSTAND", junkAbsStr, "=", ";")	//parse the list of values
			//			c3 = NumberByKey("DSTAND", junkAbsStr, "=", ";")
			//			c4 = NumberByKey("IZERO", junkAbsStr, "=", ";")
			//			c5 = NumberByKey("XSECT", junkAbsStr, "=", ";")
			//			kappa_err = NumberByKey("SDEV", junkAbsStr, "=", ";")
		else
			//get the parames from the list
			c2        = NumberByKey("TSTAND", absStr, "=", ";") //parse the list of values
			c3        = NumberByKey("DSTAND", absStr, "=", ";")
			c4        = NumberByKey("IZERO", absStr, "=", ";")
			c5        = NumberByKey("XSECT", absStr, "=", ";")
			kappa_err = NumberByKey("SDEV", absStr, "=", ";")
		endif
		//get the sample trans and thickness from the activeType folder
		//		Variable c0 = V_getSampleTransmission(activeType)		//sample transmission
		//		Variable c1 = V_getSampleThickness(activeType)		//sample thickness

		err = V_Absolute_Scale(activeType, absStr)
		if(err)
			return (err)
			SetDataFolder root:
			Abort "Error in V_Absolute_Scale(), called from V_ExecuteProtocol"
		endif
		activeType = "ABS"
		V_UpdateDisplayInformation(ActiveType) //update before breaking from loop
	endif

	return (0)
End

Function V_Proto_ReadMask(string maskStr)

	//check for mask
	//doesn't change the activeType
	string mskFileName = ""
	string pathStr     = ""
	PathInfo catPathName //this is where the files are
	pathStr = S_path

	if(cmpstr("none", maskStr) != 0)
		if(cmpstr("ask", maskStr) == 0)
			//get file from user
			// x- fill in the get file prompt, and handle the result
			Prompt mskFileName, "MASK File", popup, V_PickMASKButton("")
			DoPrompt "Select File", mskFileName
			//			if (V_Flag)
			//				return 0									// user cancelled
			//			endif

			if(strlen(mskFileName) == 0) //use cancelled
				//if none desired, make sure that the old mask is deleted
				KillDataFolder/Z root:Packages:NIST:VSANS:MSK:
				NewDataFolder/O root:Packages:NIST:VSANS:MSK

				DoAlert 0, "No Mask file selected, data not masked"
			else
				//read in the file from the selection
				V_LoadHDF5Data(mskFileName, "MSK")
			endif
		else
			//just read it in from the protocol
			//list processing is necessary to remove any final comma
			mskFileName = pathStr + StringFromList(0, maskStr, ",")
			V_LoadHDF5Data(mskFileName, "MSK")
		endif

	else
		//if none desired, make sure that the old mask is deleted
		// TODO
		// x- clean out the data folder
		// x- note that V_KillNamedDataFolder() points to RawVSANS, and won't work
		// -- what happens if the kill fails? need error handling
		//
		KillDataFolder/Z root:Packages:NIST:VSANS:MSK:
		NewDataFolder/O root:Packages:NIST:VSANS:MSK

	endif

	return (0)
End

Function V_Proto_doAverage(string avgStr, string av_type, string activeType, variable binType, string collimationStr)

	strswitch(av_type) //dispatch to the proper routine to average to 1D data
		case "none":
			//still do nothing
			// set binType and binTypeStr to bad flags
			string binTypeStr = "none"
			binType = -999999
			break

		case "Circular":
			V_QBinAllPanels_Circular(activeType, binType, collimationStr) // this does a default circular average
			break

		case "Sector":
			string   side     = StringByKey("SIDE", avgStr, "=", ";")
			variable phi_rad  = (Pi / 180) * NumberByKey("PHI", avgStr, "=", ";") //in radians
			variable dphi_rad = (Pi / 180) * NumberByKey("DPHI", avgStr, "=", ";")
			V_QBinAllPanels_Sector(activeType, binType, collimationStr, side, phi_rad, dphi_rad)
			break
		case "Sector_PlusMinus":
			//			Sector_PlusMinus1D(activeType)
			break
		case "Rectangular":
			//			RectangularAverageTo1D(activeType)
			break

		case "Annular":
			string   detGroup = StringByKey("DETGROUP", avgStr, "=", ";")
			variable qCtr_Ann = NumberByKey("QCENTER", avgStr, "=", ";")
			variable qWidth   = NumberByKey("QDELTA", avgStr, "=", ";")
			V_QBinAllPanels_Annular(activeType, detGroup, qCtr_Ann, qWidth)
			break

		case "Narrow_Slit":
			V_QBinAllPanels_Slit(activeType, binType) // this does a tall, narrow slit average
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
		default:  
			// no default action
			break
		//do nothing
	endswitch

	return (0)
End

Function V_Proto_doPlot(string plotStr, string av_type, string activeType, variable binType, string detGroup)

	string doPlot = StringByKey("PLOT", plotStr, "=", ";")

	if((cmpstr(doPlot, "Yes") == 0) && (cmpstr(av_type, "none") != 0))

		strswitch(av_type) //dispatch to the proper routine to PLOT 1D data
			case "none":
				//still do nothing
				break

			case "Circular":  
			case "Sector":
				V_PlotData_Panel() //this brings the plot window to the front, or draws it (ONLY)
				V_Update1D_Graph(activeType, binType) //update the graph, data was already binned
				break
			case "Sector_PlusMinus":
				//			Sector_PlusMinus1D(activeType)
				break
			case "Rectangular":
				//			RectangularAverageTo1D(activeType)
				break

			case "Annular":
				V_Phi_Graph_Proc(activeType, detGroup)
				break

			case "Narrow_Slit":
				// these are the same plotting routines as for standard circular average
				V_PlotData_Panel() //this brings the plot window to the front, or draws it (ONLY)
				V_Update1D_Graph(activeType, binType) //update the graph, data was already binned
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
			default:  
				// no default action
				break
			//do nothing
		endswitch

	endif // end of plotting switch

	return (0)
End

Function V_Proto_SaveFile(string avgStr, string activeType, string samFileLoaded, string av_type, variable binType, string detGroup, string trimBegStr, string trimEndStr)

	string fullpath          = ""
	string newfileName       = ""
	string saveType          = StringByKey("SAVE", avgStr, "=", ";") //does user want to save data?
	NVAR   useNXcanSASOutput = root:Packages:NIST:gNXcanSAS_Write

	NVAR gIgnoreBackDet = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	if((cmpstr(saveType[0, 2], "Yes") == 0) && (cmpstr(av_type, "none") != 0))
		//then save
		newFileName = RemoveEnding(samFileLoaded, ".nxs.ngv")

		//pick ABS or AVE extension
		string exten = activeType
		if(cmpstr(exten, "ABS") != 0)
			exten = "AVE"
		endif
		//		if(cmpstr(av_type,"2D_ASCII") == 0)
		//			exten = "ASC"
		//		endif
		//		if(cmpstr(av_type,"QxQy_ASCII") == 0)
		//			exten = "DAT"
		//		endif

		//		// add an "x" to the file extension if the output is XML
		//		// currently (2010), only for ABS and AVE (1D) output
		//		if( cmpstr(exten,"ABS") == 0 || cmpstr(exten,"AVE") == 0 )
		//			if(useXMLOutput == 1)
		//				exten += "x"
		//			endif
		//		endif

		//Path is catPathName, symbolic path
		//if this doesn't exist, a dialog will be presented by setting dialog = 1
		//
		variable dialog = 0

		PathInfo/S catPathName
		string item     = StringByKey("NAME", avgStr, "=", ";")     //Auto or Manual naming
		string autoname = StringByKey("AUTONAME", avgStr, "=", ";") //autoname -  will get empty string if not present
		if((cmpstr(item, "Manual") == 0) || (cmpstr(newFileName, "") == 0))
			//manual name if requested or if no name can be derived from header
			fullPath = newfileName + "." + exten //puts possible new name or null string in dialog
			dialog   = 1                         //force dialog for user to enter name
		else
			//auto-generate name and prepend path - won't put up any dialogs since it has all it needs
			//use autoname if present
			if(cmpstr(autoname, "") != 0)
				fullPath = S_Path + autoname + "." + exten
			else
				fullPath = S_Path + newFileName + "." + exten
			endif
		endif
		//
		strswitch(av_type)
			case "Annular":
				V_fWrite1DAnnular_new("root:Packages:NIST:VSANS:", activeType, detGroup, newFileName + ".phi")
				Print "data written to:  " + newFileName + ".phi"

				break

			case "Circular": //in SANS, this was the default, but is dangerous, so make it explicit here 
			case "Sector": // TODO: this falls through - which luckily works for now...
			case "Rectangular": // TODO: this falls through - which luckily works for now...
			case "Narrow_Slit": // TODO: this falls through - which luckily works for now...

				// no VSANS support of XML output at this point
				//				if (useXMLOutput == 1)
				//					WriteXMLWaves_W_Protocol(activeType,fullPath,dialog)
				//				else
				//					WriteWaves_W_Protocol(activeType,fullpath,dialog)
				//				endif
				//

				if(cmpstr(saveType, "Yes - Concatenate") == 0)
					V_Trim1DDataStr(activeType, binType, trimBegStr, trimEndStr) // x- passing null strings uses global or default trim values

					V_ConcatenateForSave("root:Packages:NIST:VSANS:", activeType, "", binType) // this removes q=0 point, concatenates, sorts

					// RemoveDuplicateQvals -- this step:
					// --removes NaN values
					// -- averages intensity from q-values that are within 0.1% of each other
					V_RemoveDuplicateQvals("root:Packages:NIST:VSANS:", activeType) // works with the "tmp_x" waves from concatenateForSave
					//					prot[9] = collimationStr
					if(useNXcanSASOutput == 1)
						exten = "h5"
						V_WriteNXcanSAS1DData("root:Packages:NIST:VSANS:", activeType, fullPath + ".h5") // pass the full path here
						Print "data written to:  " + fullPath + ".h5"
					else
						V_Write1DData("root:Packages:NIST:VSANS:", activeType, newFileName + "." + exten) //don't pass the full path, just the name
						Print "data written to:  " + newFileName + "." + exten
					endif

				endif

				if(cmpstr(saveType, "Yes - Individual") == 0)
					// remove the q=0 point from the back detector, if it's there
					// does not trim any other points from the data
					if(!gIgnoreBackDet)
						V_RemoveQ0_B(activeType)
					endif
					//					V_Write1DData_ITX("root:Packages:NIST:VSANS:",activeType,newFileName,binType)

					V_Write1DData_Individual("root:Packages:NIST:VSANS:", activeType, newFileName, exten, binType)
				endif

				break

			case "2D_ASCII":
				//				Fast2DExport(activeType,fullPath,dialog)
				break
			case "QxQy_ASCII":
				fullPath = S_Path + newFileName //+".DAT"		add the .DAT and detector panel in the writer, not here
				V_QxQy_Export(activeType, fullPath, newFileName, dialog)
				break
			case "QxQy_NXcanSAS":
				fullPath = S_Path + newFileName + ".2D.h5"
				V_WriteNXcanSAS2DData(activeType, fullPath, newFileName, dialog)
				break
			case "PNG_Graphic":
				//				SaveAsPNG(activeType,fullpath,dialog)
				break

			default:  
				DoAlert 0, "av_type not found in dispatch to write file"
		endswitch

	endif
	return (0)
End

