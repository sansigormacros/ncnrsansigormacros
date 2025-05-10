#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma version=5.0
#pragma IgorVersion=6.1

//**************************
// Vers. 1.2 092101
//
//procedures required to allow patching of raw SANS data headers
//only a limited number of fields are allowble for changes, although the list could
//be enhanced quite easily, at the expense of a larger, more complex panel
//information for the Patch Panel is stored in the root:myGlobals:Patch subfolder
//
// writes changes directly to the raw data headers as requested
// * note that if a data file is currently in a work folder, the (real) header on disk
// will be updated, but the data in the folder will not reflect these changes, unless
// the data folder is first cleared
//
//**************************

//main entry procedure for displaying the Patch Panel
//
Proc PatchFiles()

	DoWindow/F Patch_Panel
	if(V_flag == 0)
		InitializePatchPanel()
		//draw panel
		Patch_Panel()
	endif
EndMacro

//initialization of the panel, creating the necessary data folder and global
//variables if necessary - simultaneously initialize the globals for the Trans
//panel at theis time, to make sure they all exist
//
Proc InitializePatchPanel()
	//create the global variables needed to run the Patch Panel
	//all are kept in root:myGlobals:Patch
	if(!(DataFolderExists("root:myGlobals:Patch")))
		//create the data folder and the globals for BOTH the Patch and Trans panels
		NewDataFolder/O root:myGlobals:Patch
	endif
	CreatePatchGlobals() //re-create them every time (so text and radio buttons are correct)
EndMacro

//the data folder root:myGlobals:Patch must exist
//
Proc CreatePatchGlobals()
	//ok, create the globals
	string/G root:myGlobals:Patch:gPatchMatchStr = "*"
	PathInfo catPathName
	if(V_flag == 1)
		string   dum                              = S_path
		string/G root:myGlobals:Patch:gCatPathStr = dum
	else
		string/G root:myGlobals:Patch:gCatPathStr = "no path selected"
	endif
	string/G   root:myGlobals:Patch:gPatchList = "none"
	string/G   root:myGlobals:Patch:gPS1       = "no file selected"
	string/G   root:myGlobals:Patch:gPS2       = "no file selected"
	string/G   root:myGlobals:Patch:gPS3       = "no box selected"
	variable/G root:myGlobals:Patch:gPV1       = 0
	variable/G root:myGlobals:Patch:gPV2       = 0
	variable/G root:myGlobals:Patch:gPV3       = 0
	variable/G root:myGlobals:Patch:gPV4       = 0
	variable/G root:myGlobals:Patch:gPV5       = 0
	variable/G root:myGlobals:Patch:gPV6       = 0
	variable/G root:myGlobals:Patch:gPV7       = 0
	variable/G root:myGlobals:Patch:gPV8       = 0
	variable/G root:myGlobals:Patch:gPV9       = 0
	variable/G root:myGlobals:Patch:gPV10      = 0
	variable/G root:myGlobals:Patch:gPV11      = 0
	variable/G root:myGlobals:Patch:gPV12      = 0
	variable/G root:myGlobals:Patch:gPV13      = 0
	variable/G root:myGlobals:Patch:gPV14      = 0
	variable/G root:myGlobals:Patch:gPV15      = 0
	variable/G root:myGlobals:Patch:gPV16      = 0
	variable/G root:myGlobals:Patch:gPV17      = 0
	variable/G root:myGlobals:Patch:gPV18      = 0
	variable/G root:myGlobals:Patch:gPV19      = 0
	variable/G root:myGlobals:Patch:gTransCts  = 0
	variable/G root:myGlobals:Patch:gRadioVal  = 1
EndMacro

//button action procedure to select the local path to the folder that
//contains the SANS data
//sets catPathName, updates the path display and the popup of files (in that folder)
//
Function PickPathButton(string PathButton) : ButtonControl

	//set the global string to the selected pathname
	PickPath()
	//set a local copy of the path for Patch
	PathInfo/S catPathName
	string dum = S_path
	if(V_flag == 0)
		//path does not exist - no folder selected
		string/G root:myGlobals:Patch:gCatPathStr = "no folder selected"
	else
		string/G root:myGlobals:Patch:gCatPathStr = dum
	endif

	//Update the pathStr variable box
	ControlUpdate/W=Patch_Panel $"PathDisplay"

	//then update the popup list
	// (don't update the list - not until someone enters a search critera) -- Jul09
	//
	SetMatchStrProc("", 0, "*", "") //this is equivalent to finding everything, typical startup case

End

//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
Function/S xGetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	string path = S_path
	if(V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	endif

	string newList = ""

	newList = N_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:myGlobals:Patch:gPatchMatchStr
	if(strlen(match) == 0) //if nothing is entered for a match string, return everything, rather than nothing
		match = "*"
	endif

	newlist = MyMatchList(match, newlist, ";")

	newList = SortList(newList, ";", 0)
	return (newList)
End

//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
// Uses Grep to look through the any text in the file, which includes the sample label
// can be very slow across the network, as it re-pops the menu on a selection (since some folks don't hit
// enter when inputing a filter string)
//
// - or -
// a list or range of run numbers
// - or -
// a SDD (to within 0.001m)
// - or -
// * to get everything
//
// 	NVAR gRadioVal= root:myGlobals:Patch:gRadioVal
// 1== Run # (comma range OK)
// 2== Grep the text (SLOW)
// 3== filter by SDD (within 0.001 m)
Function/S GetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	string path = S_path
	if(V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	endif

	string newList = ""

	newList = N_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:myGlobals:Patch:gPatchMatchStr
	if(strlen(match) == 0 || cmpstr(match, "*") == 0) //if nothing or "*" entered for a match string, return everything, rather than nothing
		match = "*"
		// old way, with simply a wildcard
		newlist = MyMatchList(match, newlist, ";")
		newList = SortList(newList, ";", 0)
		return (newList)
	endif

	//loop through all of the files as needed

	string fname
	string list    = ""
	string item    = ""
	string runList = ""
	string numStr  = ""
	variable ii, val, sdd
	variable num       = ItemsInList(newList)
	NVAR     gRadioVal = root:myGlobals:Patch:gRadioVal

	// run number list
	if(gRadioVal == 1)
		//		list = ParseRunNumberList(match)		//slow, file access every time
		//		list = ReplaceString(",", list, ";")
		//		newList = list

		// cut this 0ct 2014 -- the ListMatch at the bottom returns bad results when certain conditions are met:
		// -- for example OCT14nnn runs will return all of the OCT141nn runs if you try to match run 141
		//
		//
		//		list = ExpandNumRanges(match)		//now simply comma delimited
		//		num=ItemsInList(list,",")
		//		for(ii=0;ii<num;ii+=1)
		//			item = StringFromList(ii,list,",")
		//			val=str2num(item)
		//			//make a three character string of the run number
		//			if(val<10)
		//				numStr = "00"+num2str(val)
		//			else
		//				if(val<100)
		//					numStr = "0"+num2str(val)
		//				else
		//					numStr = num2str(val)
		//				Endif
		//			Endif
		//			runList += ListMatch(newList,"*"+numStr+"*",";")
		//
		//		endfor

		// oct 2014 -- try this way:
		list = N_ExpandNumRanges(match) //now simply comma delimited
		num  = ItemsInList(list, ",")
		for(ii = 0; ii < num; ii += 1)
			item = StringFromList(ii, list, ",")
			val  = str2num(item)

			runList += N_GetFileNameFromPathNoSemi(N_FindFileFromRunNumber(val)) + ";"

		endfor
		newlist = runList

	endif

	//grep through what text I can find in the VAX binary
	// Grep Note: the \\b sequences limit matches to a word boundary before and after
	// "boondoggle", so "boondoggles" and "aboondoggle" won't match.
	if(gRadioVal == 2)
		for(ii = 0; ii < num; ii += 1)
			item = StringFromList(ii, newList, ";")
			//			Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
			Grep/P=catPathName/Q/E=("(?i)" + match) item
			if(V_value) // at least one instance was found
				//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

		newList = list
	endif

	// SDD
	variable pos
	string SDDStr = ""
	if(gRadioVal == 3)
		pos = strsearch(match, "*", 0)
		if(pos == -1) //no wildcard
			val = str2num(match)
		else
			val = str2num(match[0, pos - 1])
		endif

		//		print val
		for(ii = 0; ii < num; ii += 1)
			item  = StringFromList(ii, newList, ";")
			fname = path + item
			sdd   = getDet_Distance(fname) / 100 // convert [cm] to [m]
			if(pos == -1)
				//no wildcard
				if(abs(val - sdd) < 0.01) //if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif
			else
				//yes, wildcard, try a string match?
				// string match doesn't work -- 1* returns 1m and 13m data
				// round the value (or truncate?)

				//SDDStr = num2str(sdd)
				//if(strsearch(SDDStr,match[0,pos-1],0) != -1)
				//	list += item + ";"
				//endif

				if(abs(val - round(sdd)) < 0.01) //if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif

			endif
		endfor

		newList = list
	endif

	newList = SortList(newList, ";", 0)
	return (newList)
End

// -- no longer refreshes the list - this seems redundant, and can be slow if grepping
//
//updates the popup list when the menu is "popped" so the list is
//always fresh, then automatically displays the header of the popped file
//value of match string is used in the creation of the list - use * to get
//all valid files
//
Function PatchPopMenuProc(string PatchPopup, variable popNum, string popStr) : PopupMenuControl

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)

	//	String list = GetValidPatchPopupList()

	//	String/G root:myGlobals:Patch:gPatchList = list
	//	ControlUpdate PatchPopup
	ShowHeaderButtonProc("SHButton")
End

//when text is entered in the match string, the popup list is refined to
//include only the selected files, useful for trimming a lengthy list, or selecting
//a range of files to patch
//only one wildcard (*) is allowed
//
Function SetMatchStrProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)

	string list = GetValidPatchPopupList()

	string/G root:myGlobals:Patch:gPatchList = list
	ControlUpdate PatchPopup
	PopupMenu PatchPopup, mode=1

	if(strlen(list) > 0)
		ShowHeaderButtonProc("SHButton")
	endif
End

//displays the header of the selected file (top in the popup) when the button is clicked
//sort of a redundant button, since the procedure is automatically called (as if it were
//clicked) when a new file is chosen from the popup
//
Function ShowHeaderButtonProc(string SHButton) : ButtonControl

	//displays (editable) header information about current file in popup control
	//putting the values in the SetVariable displays (resetting the global variables)

	//get the popup string
	string partialName, tempName
	variable ok
	ControlInfo/W=Patch_Panel PatchPopup
	if(strlen(S_value) == 0 || cmpstr(S_Value, "none") == 0)
		//null selection
		Abort "no file selected in popup menu"
	endif

	//selection not null
	partialName = S_value
	//Print partialName
	//get a valid file based on this partialName and catPathName
	tempName = N_FindValidFilename(partialName)

	//prepend path to tempName for read routine
	PathInfo catPathName
	tempName = S_path + tempName

	//make sure the file is really a RAW data file
	ok = N_CheckIfRawData(tempName)
	if(!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	endif

	//Print tempName

	ReadHeaderForPatch(tempName)

	ControlUpdate/A/W=Patch_Panel

End

//utility function that polls the checkboxes of the editable parameters
//returns a wave with the yes/no checked state of the boxes
// 0 = not checked (user does NOT want this header value updated)
// 1 = checked (YES, change this value in the header)
//num (input) is a simple check to make sure that the wave is set up properly
//from the calling routine
//
// on return, wave w contains the current state of the checkboxes
Function GetCheckBoxesState(WAVE w, variable num)

	if(num != 20)
		Abort "wrong number of checkboxes GetCheckBoxesState()"
	endif
	ControlInfo checkPS1
	w[0] = V_value

	variable ii
	string baseStr = "checkPV"

	ii = 1
	do
		ControlInfo $(baseStr + num2str(ii))
		w[ii] = V_Value
		ii   += 1
	while(ii < num)
	return (0)
End

//on return, wt is a TEXT wave with the values in the SetVar boxes
//will poll the SetVariable controls to get the new values - will get all the values,
//and let the writing routine decide which ones it will actually use
//num (input) is a simple check to make sure that the wave is set up properly
//from the calling routine
//
Function GetEditedSetVarBoxes(WAVE/T wt, variable num)

	if(num != 20)
		Abort "wrong number of checkboxes GetEditedSetVarBoxes()"
	endif
	//pass all as a text wave - so only one wave has to be passed (conversion 2x, though)
	//global is set to the changed value when entered. read others directly from the control
	//make sure the text label is exactly 60 characters long, to match VAX field length
	SVAR   dum   = root:myGlobals:Patch:gPS1
	string str60 = ""
	string junk  = "junk"
	str60 = PadString(junk, 60, 0x20)
	if(strlen(dum) <= 60)
		if(strlen(dum) == 60)
			str60 = dum
		else
			str60 = PadString(dum, 60, 0x20)
		endif
	else
		//too long, truncate
		str60[0, 59] = dum[0, 59]
	endif

	wt[0] = str60

	variable ii
	string baseStr = "PV"
	ii = 1
	do
		ControlInfo $(baseStr + num2str(ii))
		wt[ii] = num2str(V_Value)
		ii    += 1
	while(ii < num)

	return (0) //no error
End

//simple function to get the string value from the popup list of filenames
//returned string is only the text in the popup, a partial name with no path
//or VAX version number.
//
Function/S GetPatchPopupString()

	string str = ""

	ControlInfo patchPopup
	if(cmpstr(S_value, "") == 0)
		//null selection
		Abort "no file selected in popup menu"
	endif

	//selection not null
	str = S_value
	//Print str

	return str
End

//Changes (writes to disk!) the specified changes to the (single) file selected in the popup
//reads the checkboxes to determine which (if any) values need to be written
//
Function ChangeHeaderButtonProc(string CHButton) : ButtonControl

	//read the (20) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars
	string partialName = ""
	string tempName    = ""
	variable ok, ii
	variable nvars = 20

	Make/O/N=(nvars) tempChange
	WAVE w = tempchange
	GetCheckBoxesState(w, nvars)
	//Print "w[0] = ",w[0]

	//Get the current values in each of the fields - to pass to Write() as a textwave
	Make/O/T/N=(nvars) tempValues
	WAVE/T wt = tempValues
	//initialize textwave
	ii = 0
	do
		wt[ii] = ""
		ii    += 1
	while(ii < nvars)
	GetEditedSetVarBoxes(wt, nvars)

	//get the popup string
	partialName = GetPatchPopupString()

	//get a valid file based on this partialName and catPathName
	tempName = N_FindValidFilename(partialName)

	//prepend path to tempName for read routine
	PathInfo catPathName
	tempName = S_path + tempName

	//make sure the file is really a RAW data file
	ok = N_CheckIfRawData(tempName)
	if(!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	endif

	//go write the changes to the file
	WriteHeaderForPatch(tempName, w, wt)

	//clean up wave before leaving
	KillWaves/Z w, wt

End

//*****this function actually writes the data to disk*****
//overwrites the specific bytes the the header that are to be changed
//real values are written out mimicking VAX format, so that can be properly
//re-read as raw binary VAX files.
//if any additional fields are to be edited, the exact byte location must be known
//
Function WriteHeaderForPatch(string fname, WAVE change, WAVE/T textVal)

	variable refnum, num
	string textstr

	//change the sample label ?
	if(change[0])
		writeSampleDescription(fname, textVal[0])
	endif

	//total count time is an integer, handle separately
	if(change[6])
		num = str2num(textVal[6])
		writeCount_time(fname, num) // in entry/control
		writeCollectionTime(fname, num) // in entry/
	endif

	//ReWriteReal() takes care of open/close on its own
	if(change[1]) //sample transmission
		num = str2num(textVal[1])
		writeSampleTransmission(fname, num)
	endif
	if(change[2]) //sample thickness
		num = str2num(textVal[2])
		writeSampleThickness(fname, num)
	endif
	if(change[3]) //pixel X
		num = str2num(textVal[3])
		writeDet_beam_center_x(fname, num)
	endif
	if(change[4]) // pixel Y
		num = str2num(textVal[4])
		writeDet_beam_center_y(fname, num)
	endif
	if(change[5]) //attenuator number
		num = str2num(textVal[5])
		writeAtten_num_dropped(fname, num)
	endif
	//[6] was the counting time, integer written above
	if(change[7]) //monitor count -- change in both places
		num = str2num(textVal[7])
		writeControlMonitorCount(fname, num)
		writeBeamMonNorm_data(fname, num)
	endif
	if(change[8]) //total detector count (both locations)
		num = str2num(textVal[8])
		writeDetector_counts(fname, num)
		writeDet_Integratedcount(fname, num)
	endif
	if(change[9]) //trans det count
		num = str2num(textVal[9])
		DoAlert 0, "Trans Det Count field DNE - not written"
		//		WriteTransDetCountToHeader(fname,num)		// TODO: replace this with something that actually exists
	endif
	if(change[10]) //wavelength
		num = str2num(textVal[10])
		writeWavelength(fname, num)
	endif
	///
	if(change[11]) //wavelength spread
		num = str2num(textVal[11])
		writeWavelength_spread(fname, num)
	endif
	if(change[12]) //temperature
		num = str2num(textVal[12])
		writeSampleTemperature(fname, num)
	endif
	if(change[13]) //magnetic field
		num = str2num(textVal[13])
		DoAlert 0, "Magnetic field DNE - not written"
		//		WriteMagnFieldToHeader(fname,num)			//TODO: this is currently not in the header
	endif
	if(change[14]) //source aperture, a string
		writeSourceAp_size(fname, textVal[14])
	endif
	if(change[15]) //sample aperture, a FP value (new for Nexus
		num = str2num(textVal[15]) // write in units of [mm]
		writeSampleAp_size(fname, num)
	endif
	///
	if(change[16]) //source-sam dist
		num  = str2num(textVal[16])
		num *= 100 // asking for [m], convert to [cm] to write
		//		DoAlert 0,"Verify in the code that this is the correct distance (source ap to sample ap)"
		writeSourceAp_distance(fname, num) // DONE-- just like SDD, units are [cm]
	endif
	if(change[17]) //det offset
		num = str2num(textVal[17])
		writeDet_LateralOffset(fname, num)
	endif
	if(change[18]) //beamstop diam
		num = str2num(textVal[18]) / 10 //field is [mm], store as [cm]
		writeBeamStop_size(fname, num)
	endif
	if(change[19]) //SDD
		num  = str2num(textVal[19])
		num *= 100 //convert [m] as requested to [cm] as stored in the header
		writeDet_distance(fname, num)
	endif
	return (0)
End

//panel recreation macro for the PatchPanel...
//
Proc Patch_Panel()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(519, 85, 950, 608)/K=1 as "Patch Raw SANS Data Files"
	//	NewPanel /W=(519,85,950,608) as "Patch Raw SANS Data Files"
	DoWindow/C Patch_Panel
	//	ModifyPanel cbRGB=(1,39321,19939)
	ModifyPanel cbRGB=(30000, 55000, 39000)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fname="Courier", fstyle=1
	DrawText 3, 107, "Change?"
	DrawLine 7, 30, 422, 30
	DrawLine 7, 288, 422, 288
	DrawLine 7, 199, 422, 199
	DrawLine 7, 378, 422, 378
	DrawLine 7, 469, 422, 469
	SetVariable PathDisplay, pos={77, 7}, size={310, 13}, title="Path"
	SetVariable PathDisplay, help={"This is the path to the folder that will be used to find the SANS data while patching. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay, font="Courier", fSize=10
	SetVariable PathDisplay, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gCatPathStr
	Button PathButton, pos={2, 3}, size={70, 20}, proc=PickPathButton, title="Pick Path"
	Button PathButton, help={"Select the folder containing the raw SANS data files"}
	Button helpButton, pos={400, 3}, size={25, 20}, proc=ShowPatchHelp, title="?"
	Button helpButton, help={"Show the help file for patching raw data headers"}
	PopupMenu PatchPopup, pos={4, 37}, size={156, 19}, proc=PatchPopMenuProc, title="File(s) to Patch"
	PopupMenu PatchPopup, help={"The displayed file is the one that will be edited. The entire list will be edited if \"Change All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh. \r List items are selected from the file based on MatchString"}
	PopupMenu PatchPopup, mode=1, popvalue="none", value=#"root:myGlobals:Patch:gPatchList"
	//	Button SHButton,pos={324,37},size={100,20},proc=ShowHeaderButtonProc,title="Show Header"
	//	Button SHButton,help={"This will display the header of the file indicated in the popup menu."}
	Button CHButton, pos={314, 37}, size={110, 20}, proc=ChangeHeaderButtonProc, title="Change Header"
	Button CHButton, help={"This will change the checked values (ONLY) in the single file selected in the popup."}
	SetVariable PMStr, pos={6, 63}, size={174, 13}, proc=SetMatchStrProc, title="Match String"
	SetVariable PMStr, help={"Enter the search string to narrow the list of files. \"*\" is the wildcard character. After entering, \"pop\" the menu to refresh the file list."}
	SetVariable PMStr, font="Courier", fSize=10
	SetVariable PMStr, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPatchMatchStr
	Button ChAllButton, pos={245, 60}, size={180, 20}, proc=ChAllHeadersButtonProc, title="Change All Headers in List"
	Button ChAllButton, help={"This will change the checked values (ONLY) in ALL of the files in the popup list, not just the top file. If the \"change\" checkbox for the item is not checked, nothing will be changed for that item."}
	Button DoneButton, pos={310, 489}, size={110, 20}, proc=DoneButtonProc, title="Done Patching"
	Button DoneButton, help={"When done Patching files, this will close this control panel."}
	Button cat_short, pos={9, 485}, size={100, 20}, proc=DoCatShort, title="File Catalog"
	Button cat_short, help={"Use this button to generate a notebook with file header information. Very useful for identifying files."}
	SetVariable PS1, pos={42, 111}, size={338, 13}, proc=SetLabelVarProc, title="label"
	SetVariable PS1, help={"Current sample label"}, font="Courier", fSize=10
	SetVariable PS1, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPS1
	SetVariable PV1, pos={42, 129}, size={340, 13}, title="Transmission"
	SetVariable PV1, help={"Current transmission\rvalue"}, font="Courier", fSize=10
	SetVariable PV1, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV1
	SetVariable PV2, pos={42, 147}, size={340, 13}, title="Thickness (cm)"
	SetVariable PV2, help={"Current sample thickness, in units of centimeters"}
	SetVariable PV2, font="Courier", fSize=10
	SetVariable PV2, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV2
	SetVariable PV3, pos={42, 165}, size={340, 13}, title="Beamcenter X"
	SetVariable PV3, help={"Current X-position of the beamcenter, in pixels"}
	SetVariable PV3, font="Courier", fSize=10
	SetVariable PV3, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV3
	SetVariable PV4, pos={42, 183}, size={340, 13}, title="Beamcenter Y"
	SetVariable PV4, help={"Current Y-position of the beamcenter, in pixels"}
	SetVariable PV4, font="Courier", fSize=10
	SetVariable PV4, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV4
	SetVariable PV5, pos={42, 202}, size={340, 13}, title="Attenuator number"
	SetVariable PV5, help={"attenuator number present during data collection"}
	SetVariable PV5, font="Courier", fSize=10
	SetVariable PV5, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV5
	SetVariable PV6, pos={42, 219}, size={340, 13}, title="Counting time (s)", font="Courier", fSize=10
	SetVariable PV6, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV6
	SetVariable PV6, help={"total counting time in seconds"}
	SetVariable PV7, pos={42, 237}, size={340, 13}, title="Monitor count", font="Courier", fSize=10
	SetVariable PV7, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV7
	SetVariable PV7, help={"total monitor counts"}
	SetVariable PV8, pos={42, 255}, size={340, 13}, title="Detector count", font="Courier", fSize=10
	SetVariable PV8, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV8
	SetVariable PV8, help={"total detector counts"}
	SetVariable PV9, pos={42, 273}, size={340, 13}, title="Trans. det. count", font="Courier", fSize=10
	SetVariable PV9, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV9
	SetVariable PV9, help={"Transmission\r detector counts"}
	SetVariable PV10, pos={42, 291}, size={340, 13}, title="Wavelength (A)", font="Courier", fSize=10
	SetVariable PV10, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV10
	SetVariable PV10, help={"neutron wavelength in angstroms"}
	SetVariable PV11, pos={42, 309}, size={340, 13}, title="Wavelength spread (dL/L)", font="Courier", fSize=10
	SetVariable PV11, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV11
	SetVariable PV11, help={"wavelength spread (delta lambda)/lambda"}
	SetVariable PV12, pos={42, 327}, size={340, 13}, title="Temperature (C)", font="Courier", fSize=10
	SetVariable PV12, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV12
	SetVariable PV12, help={"Set point temperature in centigrade"}
	SetVariable PV13, pos={42, 345}, size={340, 13}, title="Magnetic field (G)", font="Courier", fSize=10
	SetVariable PV13, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV13
	SetVariable PV13, help={"magnetic field strength units?"}
	SetVariable PV14, pos={42, 363}, size={340, 13}, title="Source aperture diameter (mm)", font="Courier", fSize=10
	SetVariable PV14, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV14
	SetVariable PV14, help={"source aperture diameter, in millimeters"}
	SetVariable PV15, pos={42, 381}, size={340, 13}, title="Sample aperture diameter (mm)", font="Courier", fSize=10
	SetVariable PV15, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV15
	SetVariable PV15, help={"sample aperture diameter, in millimeters"}
	SetVariable PV16, pos={42, 399}, size={340, 13}, title="Source to sample distance (m)", font="Courier", fSize=10
	SetVariable PV16, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV16
	SetVariable PV16, help={"Source to sample distance in meters"}
	SetVariable PV17, pos={42, 417}, size={340, 13}, title="Detector offset (cm)", font="Courier", fSize=10
	SetVariable PV17, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV17
	SetVariable PV17, help={"Detector offset, in centimeters"}
	SetVariable PV18, pos={42, 435}, size={340, 13}, title="Beamstop diameter (mm)", font="Courier", fSize=10
	SetVariable PV18, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV18
	SetVariable PV18, help={"beamstop diamter, in millimeters (1 inch = 25.4mm)"}
	SetVariable PV19, pos={42, 453}, size={340, 13}, title="Sample to detector distance (m)", font="Courier", fSize=10
	SetVariable PV19, limits={-Inf, Inf, 0}, value=root:myGlobals:Patch:gPV19
	SetVariable PV19, help={"sample to detector distance, in meters"}

	CheckBox checkPS1, pos={18, 111}, size={20, 20}, title=""
	CheckBox checkPS1, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV1, pos={18, 129}, size={20, 20}, title=""
	CheckBox checkPV1, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV2, pos={18, 147}, size={20, 20}, title=""
	CheckBox checkPV2, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV3, pos={18, 165}, size={20, 20}, title=""
	CheckBox checkPV3, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV4, pos={18, 183}, size={20, 20}, title=""
	CheckBox checkPV4, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV5, pos={18, 201}, size={20, 20}, title=""
	CheckBox checkPV5, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV6, pos={18, 219}, size={20, 20}, title=""
	CheckBox checkPV6, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV7, pos={18, 237}, size={20, 20}, title="", value=0
	CheckBox checkPV7, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV8, pos={18, 255}, size={20, 20}, title="", value=0
	CheckBox checkPV8, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV9, pos={18, 273}, size={20, 20}, title="", value=0
	CheckBox checkPV9, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV10, pos={18, 291}, size={20, 20}, title="", value=0
	CheckBox checkPV10, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV11, pos={18, 309}, size={20, 20}, title="", value=0
	CheckBox checkPV11, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV12, pos={18, 327}, size={20, 20}, title="", value=0
	CheckBox checkPV12, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV13, pos={18, 345}, size={20, 20}, title="", value=0
	CheckBox checkPV13, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV14, pos={18, 363}, size={20, 20}, title="", value=0
	CheckBox checkPV14, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV15, pos={18, 381}, size={20, 20}, title="", value=0
	CheckBox checkPV15, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV16, pos={18, 399}, size={20, 20}, title="", value=0
	CheckBox checkPV16, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV17, pos={18, 417}, size={20, 20}, title="", value=0
	CheckBox checkPV17, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV18, pos={18, 435}, size={20, 20}, title="", value=0
	CheckBox checkPV18, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0
	CheckBox checkPV19, pos={18, 453}, size={20, 20}, title="", value=0
	CheckBox checkPV19, help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."}, value=0

	CheckBox check0, pos={18, 80}, size={40, 15}, title="Run #", value=1, mode=1, proc=MatchCheckProc
	CheckBox check1, pos={78, 80}, size={40, 15}, title="Text", value=0, mode=1, proc=MatchCheckProc
	CheckBox check2, pos={138, 80}, size={40, 15}, title="SDD", value=0, mode=1, proc=MatchCheckProc

EndMacro

Function MatchCheckProc(string name, variable value)

	NVAR gRadioVal = root:myGlobals:Patch:gRadioVal

	strswitch(name)
		case "check0":
			gRadioVal = 1
			break
		case "check1":
			gRadioVal = 2
			break
		case "check2":
			gRadioVal = 3
			break
		default:
			// no default case needed
			break
	endswitch
	CheckBox check0, value=gRadioVal == 1
	CheckBox check1, value=gRadioVal == 2
	CheckBox check2, value=gRadioVal == 3
End

//This function will read only the selected values editable in the patch panel
//The values read are passed to the panel through the global variables
//the function WriteHeaderForPatch() MUST mirror this set of reads, or nothing can be updated
//
//fname is the full path:name;vers to open the file
//
Function ReadHeaderForPatch(string fname)

	//this function is for reading in values to be patched - so don't save any waves
	//just reset the global variables that are on the patch panel

	// each "get" is an individual call to GBLoadWave...
	// test for acceptable speed over a network...

	//assign to the globals for display in the panel
	string/G   root:myGlobals:Patch:gPS1  = getSampleDescription(fname)
	variable/G root:myGlobals:Patch:gPV1  = getSampleTransmission(fname)
	variable/G root:myGlobals:Patch:gPV2  = getSampleThickness(fname)
	variable/G root:myGlobals:Patch:gPV3  = getDet_beam_center_x(fname)
	variable/G root:myGlobals:Patch:gPV4  = getDet_beam_center_y(fname)
	variable/G root:myGlobals:Patch:gPV5  = getAtten_number(fname)
	variable/G root:myGlobals:Patch:gPV6  = getCount_time(fname)
	variable/G root:myGlobals:Patch:gPV7  = getBeamMonNormData(fname)
	variable/G root:myGlobals:Patch:gPV8  = getDetector_counts(fname)
	variable/G root:myGlobals:Patch:gPV9  = 0                                 // replace this value --getTransDetectorCounts(fname)
	variable/G root:myGlobals:Patch:gPV10 = getWavelength(fname)
	variable/G root:myGlobals:Patch:gPV11 = getWavelength_Spread(fname)
	variable/G root:myGlobals:Patch:gPV12 = getSampleTemperature(fname)
	variable/G root:myGlobals:Patch:gPV13 = getFieldStrength(fname)
	variable/G root:myGlobals:Patch:gPV14 = getSourceAp_size(fname)
	variable/G root:myGlobals:Patch:gPV15 = getSampleAp_size(fname)
	variable/G root:myGlobals:Patch:gPV16 = getSourceAp_distance(fname) / 100 // convert [cm] to [m]
	variable/G root:myGlobals:Patch:gPV17 = getDet_LateralOffset(fname)
	variable/G root:myGlobals:Patch:gPV18 = getBeamStop_size(fname) * 10      // stored in =cm], present [mm]
	variable/G root:myGlobals:Patch:gPV19 = getDet_Distance(fname) / 100      // convert [cm] to [m]

	return 0
End

Function ShowPatchHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Patch File Headers]"
	if(V_flag != 0)
		DoAlert 0, "The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button action procedure to change the selected information (checked values)
//in each file in the popup list. This will change multiple files, and as such,
//the user is given a chance to bail out before the whole list of files
//is modified
//useful for patching a series of runs with the same beamcenters, or transmissions
//
Function ChAllHeadersButtonProc(string ctrlName) : ButtonControl

	string msg
	msg  = "Do you really want to write all of these values to each data file in the popup list? "
	msg += "- clicking NO will leave all files unchanged"
	DoAlert 1, msg
	if(V_flag == 2)
		Abort "no files were changed"
	endif

	//this will change (checked) values in ALL of the headers in the popup list
	SVAR list = root:myGlobals:Patch:gPatchList
	variable numitems, ii
	numitems = ItemsInList(list, ";")

	if(numitems == 0)
		Abort "no items in list for multiple patch"
	endif

	//read the (6) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars
	string partialName = ""
	string tempName    = ""
	variable ok
	variable nvars = 20

	Make/O/N=(nvars) tempChange
	WAVE w = tempchange
	GetCheckBoxesState(w, nvars)
	//Print "w[0] = ",w[0]

	//Get the current values in each of the fields - to pass to Write() as a textwave
	Make/O/T/N=(nvars) tempValues
	WAVE/T wt = tempValues
	//initialize textwave
	ii = 0
	do
		wt[ii] = ""
		ii    += 1
	while(ii < nvars)
	GetEditedSetVarBoxes(wt, nvars)

	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	ii = 0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")

		//get a valid file based on this partialName and catPathName
		tempName = N_FindValidFilename(partialName)

		//prepend path to tempName for read routine
		PathInfo catPathName
		tempName = S_path + tempName

		//make sure the file is really a RAW data file
		ok = N_CheckIfRawData(tempName)
		if(!ok)
			Print "this file is not recognized as a RAW SANS data file = ", tempName
		else
			//go write the changes to the file
			WriteHeaderForPatch(tempName, w, wt)
		endif

		ii += 1
	while(ii < numitems)

	//clean up wave before leaving
	KillWaves/Z w, wt

End

//simple action for button to close the panel
Function DoneButtonProc(string ctrlName) : ButtonControl

	// This will display a progress bar and cleanup all files so that updated values will be read in
	// NOTE that this only clears the data, does not update the Cat Table
	// since the user may not want to immediately do this (and it may be slow)
	variable numToClean
	numToClean = CleanupData_w_Progress(0, 1)

	//  BUT I may want to do this instead -- does a cleanup AND reloads the Cat Table
	//	Execute "BuildCatVeryShortTable()"

	DoWindow/K Patch_Panel

End

//resets the global string corresponding to the sample label
//updates when new text is entered
//
Function SetLabelVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	//reset the global variable to the entered text so that it can be relayed to the
	//write() routine. Only the TEXT SetVariable control needs to be handled this way

	string/G root:myGlobals:Patch:gPS1 = varStr

End

// testing, very dangerous batch changing of the file header labels
//
// testStr is the string at the front of a label, that will be moved to the "back"
// if doIt is 1, it will write to the headers, any other value will only print to history
Function MPatchLabel(string testStr, variable doIt)

	//	SVAR list = root:myGlobals:Patch:gPatchList
	string list = GetValidPatchPopupList()

	variable numitems, ii
	numitems = ItemsInList(list, ";")

	if(numitems == 0)
		Abort "no items in list for multiple patch"
	endif

	string partialName = ""
	string tempName    = ""
	variable ok
	variable nvars = 20

	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	string str1, str2, str3
	variable match, loc, len, spc, jj, len1
	len = strlen(testStr)
	ii  = 0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")

		//get a valid file based on this partialName and catPathName
		tempName = N_FindValidFilename(partialName)

		//prepend path to tempName for read routine
		PathInfo catPathName
		tempName = S_path + tempName

		//make sure the file is really a RAW data file
		ok = N_CheckIfRawData(tempName)
		if(!ok)
			Print "this file is not recognized as a RAW SANS data file = ", tempName
		else
			//go write the changes to the file
			str1  = getSampleDescription(tempName)
			match = strsearch(str1, testStr, 0)
			if(match != -1)
				str2 = ReplaceString(testStr, str1, "", 0, 1)

				jj = strlen(str2)
				do
					jj -= 1
					spc = cmpstr(str2[jj], " ") //can add the optional flag ,0), but I don't care about case, and Igor 6.02 is necessary...
					if(spc != 0)
						break //no more spaces found, get out
					endif
				while(1) // jj is the location of the last non-space

				str2[jj + 2, jj + 1 + len] = testStr

				// may need to remove leading spaces???
				str2 = PadString(str2, 60, 0x20)

				if(doIt == 1)
					writeSampleDescription(tempName, str2)
					print str2, " ** Written to file **"
				else
					//print str2,strlen(str2)
					print str2, " ** Testing, not written to file **"
				endif
			else

				jj = strlen(str1)
				do
					jj -= 1
					spc = cmpstr(str1[jj], " ")
					if(spc != 0)
						break //no more spaces found, get out
					endif
				while(1)

				//print str1, jj, str1[jj]
			endif
		endif

		ii += 1
	while(ii < numitems)

End

///////////////////////
// functions to patch/correct items that are missing/incorrect in the test Nexus files
//

Proc Patch_PixelsPlus(lo, hi)
	variable lo, hi

	fPatch_PixelsPlus(lo, hi)
EndMacro

//  utility to reset the pixel sizes, pixel_num_x, plus more in the file headers
//
// lo is the first file number
// hi is the last file number (inclusive)
//
//
Function fPatch_PixelsPlus(variable lo, variable hi)

	variable ii, jj
	string fname, detStr

	variable nx, tube_width, yPixel

	if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
		nx         = 128
		tube_width = 5.08
		yPixel     = 5.08
	else
		nx         = 112
		tube_width = 8.4
		yPixel     = 8.14
	endif

	//loop over all files
	for(jj = lo; jj <= hi; jj += 1)
		fname = N_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)

			// pix num x = 112, not 128
			writeDet_pixel_num_x(fname, nx) //
			writeDet_x_pixel_size(fname, tube_width)
			writeDet_y_pixel_size(fname, yPixel) // guessing, if the tubes are equivalent to VSANS

			writeSampleAp_size(fname, 12.7) // default diam of 12.7 [mm]

			Print fname
			printf "run number %d reset to correct values\r", jj

		else
			printf "run number %d not found\r", jj
		endif

	endfor

	return (0)
End

// added functionality for Nexus files
//
// more things to patch...
//

Proc Patch_GroupID_catTable()
	fPatch_GroupID_catTable()
EndMacro

Proc Patch_Purpose_catTable()
	fPatch_Purpose_catTable()
EndMacro

Proc Patch_Intent_catTable()
	fPatch_Intent_catTable()
EndMacro

// patches the group_ID, based on whatever is in the catTable
//
Function fPatch_GroupID_catTable()

	variable lo, hi

	variable ii, jj, num

	WAVE   id        = root:myGlobals:CatVSHeaderInfo:Group_ID
	WAVE/T fileNameW = root:myGlobals:CatVSHeaderInfo:Filenames

	num = numpnts(id)
	//loop over all files
	for(jj = 0; jj < num; jj += 1)
		Print "update file ", jj, fileNameW[jj]
		writeSample_GroupID(fileNameW[jj], id[jj])
	endfor

	return (0)
End

// patches the Purpose, based on whatever is in the catTable
//
Function fPatch_Purpose_catTable()

	variable lo, hi

	variable ii, jj, num

	WAVE/T purpose   = root:myGlobals:CatVSHeaderInfo:Purpose
	WAVE/T fileNameW = root:myGlobals:CatVSHeaderInfo:Filenames

	num = numpnts(purpose)
	//loop over all files
	for(jj = 0; jj < num; jj += 1)
		Print "update file ", jj, fileNameW[jj]
		writeReduction_Purpose(fileNameW[jj], purpose[jj])
	endfor

	return (0)
End

// patches the Intent, based on whatever is in the catTable
//
Function fPatch_Intent_catTable()

	variable lo, hi

	variable ii, jj, num

	WAVE/T intent    = root:myGlobals:CatVSHeaderInfo:Intent
	WAVE/T fileNameW = root:myGlobals:CatVSHeaderInfo:Filenames

	num = numpnts(intent)
	//loop over all files
	for(jj = 0; jj < num; jj += 1)
		Print "update file ", jj, fileNameW[jj]
		writeReductionIntent(fileNameW[jj], intent[jj])
	endfor

	return (0)
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////
//
// this is a block to patch DEADTIME waves to the file headers, and can patch multiple files
//
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
//
Proc PatchDetectorDeadtime(firstFile, lastFile, deadtimeStr)
	variable firstFile   = 1
	variable lastFile    = 100
	string   deadtimeStr = "deadTimeWave"

	fPatchDetectorDeadtime(firstFile, lastFile, $deadtimeStr)

EndMacro

Proc ReadDetectorDeadtime(firstFile, lastFile)
	variable firstFile = 1
	variable lastFile  = 100

	fReadDetectorDeadtime(firstFile, lastFile)

EndMacro

// simple utility to patch the detector deadtime in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchDetectorDeadtime(variable lo, variable hi, WAVE deadtimeW)

	variable ii, numTubes
	string fname

	if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
		numTubes = 128
	else
		numTubes = 112
	endif

	// check the dimensions of the deadtimeW/N=112
	if(DimSize(deadtimeW, 0) != numTubes)
		Abort "dead time wave is not of proper dimension (N = " + num2str(numTubes) + ")"
	endif

	//loop over all files
	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			writeDetector_deadtime(fname, deadtimeW)
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

// simple utility to read the detector deadtime stored in the file header
// root:myGlobals:Patch:
Function fReadDetectorDeadtime(variable lo, variable hi)

	string   fname
	variable ii

	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			WAVE deadtimeW = getDetector_deadtime(fname)
			Duplicate/O deadTimeW, root:myGlobals:Patch:deadtimeWave
			//			printf "File %d:  Detector Dead time (s) = %g\r",ii,deadtime
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

Function PatchDetectorDeadtimePanel()

	DoWindow/F DeadtimePanel
	if(V_flag == 0)

		NewDataFolder/O/S root:myGlobals:Patch

		if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
			Make/O/D/N=128 deadTimeWave = 0
		else
			Make/O/D/N=112 deadTimeWave = 0
		endif

		variable/G gFileNum_Lo_dt, gFileNum_Hi_dt
		variable lo, hi

		NVAR gFileNum_Lo_dt = root:myGlobals:Patch:gFileNum_Lo_dt
		NVAR gFileNum_Hi_dt = root:myGlobals:Patch:gFileNum_Hi_dt

		Find_LoHi_RunNum(lo, hi) //lo,hi returned pbr
		gFileNum_Lo_dt = lo
		gFileNum_Hi_dt = hi

		SetDataFolder root:

		Execute "DeadtimePatchPanel()"
	endif
End

//
Proc DeadtimePatchPanel() : Panel
	PauseUpdate; Silent 1 // building window...

	variable sc = 1

	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	//	Variable lo,hi
	//	Find_LoHi_RunNum(lo,hi)		//set the globals

	NewPanel/W=(600 * sc, 400 * sc, 1000 * sc, 1000 * sc)/N=DeadtimePanel/K=1
	//	ShowTools/A
	ModifyPanel cbRGB=(16266, 47753, 2552, 23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 85 * sc, 99 * sc, "Current Values"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 258 * sc, "Write to all files (inclusive)"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 209 * sc, 30 * sc, "Dead Time Constants"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 133 * sc, "Run Number(s)"

	//	PopupMenu popup_0,pos={sc*20,40*sc},size={sc*109,20*sc},title="Detector Panel"
	//	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;\""

	Button button0, pos={sc * 20, 81 * sc}, size={sc * 50.00, 20.00 * sc}, proc=ReadDTButtonProc, title="Read"
	Button button0_1, pos={sc * 20, 220 * sc}, size={sc * 50.00, 20.00 * sc}, proc=WriteDTButtonProc, title="Write"
	Button button0_2, pos={sc * 18.00, 336.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=GeneratePerfDTButton, title="Perfect Dead Time"
	Button button0_3, pos={sc * 18.00, 370.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=LoadCSVDTButton, title="Load Dead Time CSV"
	Button button0_4, pos={sc * 18.00, 400.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=WriteCSVDTButton, title="Write Dead Time CSV"

	SetVariable setvar0, pos={sc * 20, 141 * sc}, size={sc * 100.00, 14.00 * sc}, title="first"
	SetVariable setvar0, value=root:myGlobals:Patch:gFileNum_Lo_dt
	SetVariable setvar1, pos={sc * 20.00, 167 * sc}, size={sc * 100.00, 14.00 * sc}, title="last"
	SetVariable setvar1, value=root:myGlobals:Patch:gFileNum_Hi_dt

	// display the wave
	Edit/W=(180 * sc, 40 * sc, 380 * sc, 550 * sc)/HOST=# root:myGlobals:Patch:deadTimeWave
	ModifyTable width(Point)=30
	ModifyTable width(root:myGlobals:Patch:deadTimeWave)=110 * sc
	RenameWindow #, T0
	SetActiveSubwindow ##

EndMacro

Function LoadCSVDTButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0 //will prompt for the file, auto name

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//
// writes the entire content of the CSV file (all 8 panels) to each detector entry in each data file
// as specified by the run number range
//
Function WriteCSVDTButton(STRUCT WMButtonAction &ba) : ButtonControl

	variable ii
	string   detStr

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			//			ControlInfo popup_0
			//			String detStr = S_Value
			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi        = V_Value
			WAVE     deadTimeW = root:myGlobals:Patch:deadTimeWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no
				fPatchDetectorDeadtime(lo, hi, deadtimeW)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
	//
	// -- Problem - for converted data, I don't know the file name
	//
	// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii = lo; ii <= hi; ii += 1)
		KillDataFolder/Z $("root:Packages:NIST:RawSANS:sans" + num2istr(ii))
	endfor

	//	// This will display a progress bar
	//	Variable numToClean
	//	numToClean = CleanupData_w_Progress(0,1)

	return 0
End

Function GeneratePerfDTButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			WAVE deadTimeWave = root:myGlobals:Patch:deadTimeWave

			deadTimeWave = 1e-18

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function ReadDTButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			variable hi = lo

			fReadDetectorDeadtime(lo, hi)

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function WriteDTButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi        = V_Value
			WAVE     deadTimeW = root:myGlobals:Patch:deadTimeWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no
				fPatchDetectorDeadtime(lo, hi, deadtimeW)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
// this is a block to patch CALIBRATION waves to the file headers, and can patch multiple files
//
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
// TODO -- verify that the calibration waves are not transposed
//
Proc PatchDetectorCalibration(firstFile, lastFile, calibStr)
	variable firstFile = 1
	variable lastFile  = 100
	string   calibStr  = "calibrationWave"

	fPatchDetectorCalibration(firstFile, lastFile, $calibStr)

EndMacro

Proc ReadDetectorCalibration(firstFile, lastFile)
	variable firstFile = 1
	variable lastFile  = 100

	fReadDetectorCalibration(firstFile, lastFile)
EndMacro

// simple utility to patch the detector calibration wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
// TODO
// -- use the flag ksDetType to switch on the type of detector (10m tubes or Ordela)
// to allow only the correct dimension for the calibration waves (3,112) or (3,128)
//
//
Function fPatchDetectorCalibration(variable lo, variable hi, WAVE calibW)

	variable ii, xDim
	string fname

	xDim = 0
	if(cmpstr(ksDetType, "Ordela") == 0)
		xDim = 128
	endif
	if(cmpstr(ksDetType, "Tubes") == 0)
		xDim = 112
	endif

	if(xDim == 0)
		Abort "ksDetType unknown in PatchFiles:fPatchDetectorCalibration()"
	endif

	// check the dimensions of the calibW (3,112) or (3,128)
	if(DimSize(calibW, 0) != 3 || DimSize(calibW, 1) != xDim)
		Abort "Calibration wave is not of proper dimension (3," + num2istr(xDim) + ")"
	endif

	//loop over all files
	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			writeDetTube_spatialCalib(fname, calibW)
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

// simple utility to read the detector deadtime stored in the file header
Function fReadDetectorCalibration(variable lo, variable hi)

	string   fname
	variable ii

	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			WAVE calibW = getDetTube_spatialCalib(fname)
			Duplicate/O calibW, root:myGlobals:Patch:calibrationWave
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

// switch based on whether the detector is Ordela (128 "tubes") or 10 m SANS (112 tubes)
//
Function PatchDetectorCalibrationPanel()

	DoWindow/F CalibrationPanel
	if(V_flag == 0)

		NewDataFolder/O/S root:myGlobals:Patch

		if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
			Make/O/D/N=(3, 128) calibrationWave = 0
		else
			Make/O/D/N=(3, 112) calibrationWave = 0
		endif

		variable/G gFileNum_Lo_calib, gFileNum_Hi_calib
		variable lo, hi

		NVAR gFileNum_Lo_calib = root:myGlobals:Patch:gFileNum_Lo_calib
		NVAR gFileNum_Hi_calib = root:myGlobals:Patch:gFileNum_Hi_calib

		Find_LoHi_RunNum(lo, hi) //lo,hi returned pbr
		gFileNum_Lo_calib = lo
		gFileNum_Hi_calib = hi

		Execute "CalibrationPatchPanel()"
		SetDataFolder root:

	endif
End

//
//
Proc CalibrationPatchPanel() : Panel
	PauseUpdate; Silent 1 // building window...

	variable sc = 1

	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	//	Variable lo,hi
	//	Find_LoHi_RunNum(lo,hi)		//set the globals

	NewPanel/W=(600 * sc, 400 * sc, 1200 * sc, 1000 * sc)/N=CalibrationPanel/K=1
	//	ShowTools/A
	ModifyPanel cbRGB=(16266, 47753, 2552, 23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 85 * sc, 99 * sc, "Current Values"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 258 * sc, "Write to all files (inclusive)"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 227 * sc, 28 * sc, "Quadratic Calibration Constants per Tube"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 133 * sc, "Run Number(s)"

	//	PopupMenu popup_0,pos={sc*20,40*sc},size={sc*109,20*sc},title="Detector Panel"
	//	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;ML;MR;MT;MB;\""

	Button button0, pos={sc * 20, 81 * sc}, size={sc * 50.00, 20.00 * sc}, proc=ReadCalibButtonProc, title="Read"
	Button button0_1, pos={sc * 20, 220 * sc}, size={sc * 50.00, 20.00 * sc}, proc=WriteCalibButtonProc, title="Write"
	Button button0_2, pos={sc * 18.00, 336.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=GeneratePerfCalibButton, title="Perfect Calibration"
	Button button0_3, pos={sc * 18.00, 370.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=LoadCSVCalibButton, title="Load Calibration CSV"
	Button button0_4, pos={sc * 18.00, 400.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=WriteCSVCalibButton, title="Write Calibration CSV"

	SetVariable setvar0, pos={sc * 20, 141 * sc}, size={sc * 100.00, 14.00 * sc}, title="first"
	SetVariable setvar0, value=root:myGlobals:Patch:gFileNum_Lo_calib
	SetVariable setvar1, pos={sc * 20.00, 167 * sc}, size={sc * 100.00, 14.00 * sc}, title="last"
	SetVariable setvar1, value=root:myGlobals:Patch:gFileNum_Hi_calib

	// display the wave
	Edit/W=(180 * sc, 40 * sc, 580 * sc, 550 * sc)/HOST=# root:myGlobals:Patch:calibrationWave
	ModifyTable width(Point)=30
	ModifyTable width(root:myGlobals:Patch:calibrationWave)=100 * sc
	// the elements() command transposes the view in the table, but does not transpose the wave
	ModifyTable elements(root:myGlobals:Patch:calibrationWave)=(-3, -2)
	RenameWindow #, T0
	SetActiveSubwindow ##

EndMacro

Function LoadCSVCalibButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0 //will prompt for the file, auto name

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//
// writes the entire content of the CSV file (all 8 panels) to each detector entry in each data file
// as specified by the run number range
//
Function WriteCSVCalibButton(STRUCT WMButtonAction &ba) : ButtonControl

	variable ii
	string   detStr

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			//			ControlInfo popup_0
			//			String detStr = S_Value
			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi              = V_Value
			WAVE     calibrationWave = root:myGlobals:Patch:calibrationWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no

				//			for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
				//				detStr = StringFromList(ii, ksDetectorListNoB, ";")
				WAVE tmp_a = $("root:tmp_a")
				WAVE tmp_b = $("root:tmp_b")
				WAVE tmp_c = $("root:tmp_c")
				calibrationWave[0][] = tmp_a[q]
				calibrationWave[1][] = tmp_b[q]
				calibrationWave[2][] = tmp_c[q]
				fPatchDetectorCalibration(lo, hi, calibrationWave)
				//			endfor
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
	//
	// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii = lo; ii <= hi; ii += 1)
		KillDataFolder/Z $("root:Packages:NIST:RawSANS:sans" + num2istr(ii))
	endfor
	return 0
End

//
// "Perfect" values here are from Phil (2/2018)
//
// TODO -- "Ordela" vs "Tubes"
// -- where is the calibrationWave generated -- need to redimension and re-fill
//
Function GeneratePerfCalibButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			WAVE calibrationWave = root:myGlobals:Patch:calibrationWave

			if(cmpstr(ksDetType, "Ordela") == 0) // either "Ordela" or "Tubes"
				calibrationWave[0][] = -320
				calibrationWave[1][] = 5.08
				calibrationWave[2][] = 0
			else
				calibrationWave[0][] = -521
				calibrationWave[1][] = 8.14
				calibrationWave[2][] = 0
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function ReadCalibButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			variable hi = lo

			fReadDetectorCalibration(lo, hi)

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function WriteCalibButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi     = V_Value
			WAVE     calibW = root:myGlobals:Patch:calibrationWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no
				fPatchDetectorCalibration(lo, hi, calibW)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
// this is a block to patch ATTENUATION waves to the file headers, and can patch multiple files
//
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
//
Proc PatchAttenTable(firstFile, lastFile, attenStr)
	variable firstFile = 1
	variable lastFile  = 100
	string   attenStr  = "AttenWave"

	fPatchAttenTable(firstFile, lastFile, $attenStr)

EndMacro

Proc ReadAttenTable(firstFile, lastFile)
	variable firstFile = 1
	variable lastFile  = 100

	fReadAttenTable(firstFile, lastFile)

EndMacro

// simple utility to patch the detector calibration wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchAttenTable(variable lo, variable hi, WAVE attW)

	variable ii
	string   fname

	// check the dimensions of the attW (12,12)
	if(DimSize(attW, 0) != 12 || DimSize(attW, 1) != 12)
		Abort "attenuator table wave is not of proper dimension (12,12)"
	endif

	//loop over all files
	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			writeAttenIndex_table(fname, attW)
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

// simple utility to read the detector deadtime stored in the file header
Function fReadAttenTable(variable lo, variable hi)

	string   fname
	variable ii

	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			WAVE attW = getAttenIndex_table(fname)
			Duplicate/O attW, root:myGlobals:Patch:attenWave
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

Function PatchAttenTablePanel()

	DoWindow/F AttenTablePanel
	if(V_flag == 0)

		NewDataFolder/O/S root:myGlobals:Patch

		Make/O/D/N=(12, 12) attenWave = 0

		variable/G gFileNum_Lo_att, gFileNum_Hi_att
		variable lo, hi

		NVAR gFileNum_Lo_att = root:myGlobals:Patch:gFileNum_Lo_att
		NVAR gFileNum_Hi_att = root:myGlobals:Patch:gFileNum_Hi_att

		Find_LoHi_RunNum(lo, hi) //lo,hi returned pbr
		gFileNum_Lo_att = lo
		gFileNum_Hi_att = hi

		SetDataFolder root:

		Execute "DrawPatchAttenTablePanel()"
	endif
End

//
//
Proc DrawPatchAttenTablePanel() : Panel
	PauseUpdate; Silent 1 // building window...

	variable sc = 1

	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	//	Variable lo,hi
	//	Find_LoHi_RunNum(lo,hi)		//set the globals

	NewPanel/W=(600 * sc, 400 * sc, 1200 * sc, 1000 * sc)/N=AttenTablePanel/K=1
	//	ShowTools/A
	ModifyPanel cbRGB=(16266, 47753, 2552, 23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 85 * sc, 99 * sc, "Current Values"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 258 * sc, "Write to all files (inclusive)"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 227 * sc, 28 * sc, "Attenuation Table"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 133 * sc, "Run Number(s)"

	Button button0, pos={sc * 20, 81 * sc}, size={sc * 50.00, 20.00 * sc}, proc=ReadAttTableButtonProc, title="Read"
	Button button0_1, pos={sc * 20, 220 * sc}, size={sc * 50.00, 20.00 * sc}, proc=WriteAttTableButtonProc, title="Write"
	//	Button button0_2,pos={sc*18.00,336.00*sc},size={sc*140.00,20.00*sc},proc=GeneratePerfCalibButton,title="Perfect Calibration"
	Button button0_3, pos={sc * 18.00, 370.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=LoadCSVAttTableButton, title="Load Att Table CSV"
	Button button0_4, pos={sc * 18.00, 400.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=WriteCSVAttTableButton, title="Write Att Table CSV"

	SetVariable setvar0, pos={sc * 20, 141 * sc}, size={sc * 100.00, 14.00 * sc}, title="first"
	SetVariable setvar0, value=root:myGlobals:Patch:gFileNum_Lo_att
	SetVariable setvar1, pos={sc * 20.00, 167 * sc}, size={sc * 100.00, 14.00 * sc}, title="last"
	SetVariable setvar1, value=root:myGlobals:Patch:gFileNum_Hi_att

	// display the wave
	Edit/W=(180 * sc, 40 * sc, 580 * sc, 550 * sc)/HOST=# root:myGlobals:Patch:attenWave
	ModifyTable width(Point)=30
	ModifyTable width(root:myGlobals:Patch:attenWave)=100 * sc
	// the elements() command transposes the view in the table, but does not transpose the wave
	//	ModifyTable elements(root:myGlobals:Patch:calibrationWave) = (-3, -2)
	RenameWindow #, T0
	SetActiveSubwindow ##

EndMacro

Function LoadCSVAttTableButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0 //will prompt for the file, auto name

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//
// writes the entire content of the CSV file
//
// first need to put the 12 1D waves into a 2D wave to write to file
//
Function WriteCSVAttTableButton(STRUCT WMButtonAction &ba) : ButtonControl

	variable ii
	string   detStr

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			//			DoAlert 0,"incomplete function WriteCSVAttTableButton()"

			//		return(0)

			//			ControlInfo popup_0
			//			String detStr = S_Value
			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi        = V_Value
			WAVE     attenWave = root:myGlobals:Patch:attenWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no

				WAVE NGBlambda = $("root:NGBlambda")
				WAVE NGBatt0   = $("root:NGBatt0")
				WAVE NGBatt1   = $("root:NGBatt1")
				WAVE NGBatt2   = $("root:NGBatt2")
				WAVE NGBatt3   = $("root:NGBatt3")
				WAVE NGBatt4   = $("root:NGBatt4")
				WAVE NGBatt5   = $("root:NGBatt5")
				WAVE NGBatt6   = $("root:NGBatt6")
				WAVE NGBatt7   = $("root:NGBatt7")
				WAVE NGBatt8   = $("root:NGBatt8")
				WAVE NGBatt9   = $("root:NGBatt9")
				WAVE NGBatt10  = $("root:NGBatt10")

				attenWave[][0]  = NGBlambda[p]
				attenWave[][1]  = NGBatt0[p]
				attenWave[][2]  = NGBatt1[p]
				attenWave[][3]  = NGBatt2[p]
				attenWave[][4]  = NGBatt3[p]
				attenWave[][5]  = NGBatt4[p]
				attenWave[][6]  = NGBatt5[p]
				attenWave[][7]  = NGBatt6[p]
				attenWave[][8]  = NGBatt7[p]
				attenWave[][9]  = NGBatt8[p]
				attenWave[][10] = NGBatt9[p]
				attenWave[][11] = NGBatt10[p]

				fPatchAttenTable(lo, hi, attenWave)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
	//
	// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii = lo; ii <= hi; ii += 1)
		KillDataFolder/Z $("root:Packages:NIST:RawSANS:sans" + num2istr(ii))
	endfor
	return 0
End

Function ReadAttTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			variable hi = lo

			fReadAttenTable(lo, hi)

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function WriteAttTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi        = V_Value
			WAVE     attenWave = root:myGlobals:Patch:attenWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no
				fPatchAttenTable(lo, hi, attenWave)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
// this is a block to patch ATTENUATION ERROR waves to the file headers, and can patch multiple files
//
// uses a simple panel to show what the table of values is.
// "read" will read only the first run number contents.
//
//
Proc PatchAttenErrTable(firstFile, lastFile, attenErrStr)
	variable firstFile   = 1
	variable lastFile    = 100
	string   attenErrStr = "AttenErrWave"

	fPatchAttenErrTable(firstFile, lastFile, $attenErrStr)

EndMacro

Proc ReadAttenErrTable(firstFile, lastFile)
	variable firstFile = 1
	variable lastFile  = 100

	fReadAttenErrTable(firstFile, lastFile)

EndMacro

// simple utility to patch the detector Atten Error wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function fPatchAttenErrTable(variable lo, variable hi, WAVE attErrW)

	variable ii
	string   fname

	// check the dimensions of the attErrW (12,12)
	if(DimSize(attErrW, 0) != 12 || DimSize(attErrW, 1) != 12)
		Abort "attenuator Err table wave is not of proper dimension (12,12)"
	endif

	//loop over all files
	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			writeAttenIndex_table_err(fname, attErrW)
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	/// clear out the freshly patched files so that they are forced to be read in from disk next time
	for(ii = lo; ii <= hi; ii += 1)
		KillDataFolder/Z $("root:Packages:NIST:RawSANS:sans" + num2istr(ii))
	endfor

	return (0)
End

// simple utility to read the detector deadtime stored in the file header
Function fReadAttenErrTable(variable lo, variable hi)

	string   fname
	variable ii

	for(ii = lo; ii <= hi; ii += 1)
		fname = N_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			WAVE attW = getAttenIndex_error_table(fname)
			Duplicate/O attW, root:myGlobals:Patch:attenErrWave
		else
			printf "run number %d not found\r", ii
		endif
	endfor

	return (0)
End

Function PatchAttenErrTablePanel()

	DoWindow/F AttenErrTablePanel
	if(V_flag == 0)

		NewDataFolder/O/S root:myGlobals:Patch

		Make/O/D/N=(12, 12) attenErrWave = 0

		variable/G gFileNum_Lo_attErr, gFileNum_Hi_attErr
		variable lo, hi

		NVAR gFileNum_Lo_attErr = root:myGlobals:Patch:gFileNum_Lo_attErr
		NVAR gFileNum_Hi_attErr = root:myGlobals:Patch:gFileNum_Hi_attErr

		Find_LoHi_RunNum(lo, hi) //lo,hi returned pbr
		gFileNum_Lo_attErr = lo
		gFileNum_Hi_attErr = hi

		SetDataFolder root:

		Execute "DrawPatchAttenErrTablePanel()"
	endif
End

//
//
Proc DrawPatchAttenErrTablePanel() : Panel
	PauseUpdate; Silent 1 // building window...

	variable sc = 1

	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	//	Variable lo,hi
	//	Find_LoHi_RunNum(lo,hi)		//set the globals

	NewPanel/W=(600 * sc, 400 * sc, 1200 * sc, 1000 * sc)/N=AttenErrTablePanel/K=1
	//	ShowTools/A
	ModifyPanel cbRGB=(16266, 47753, 2552, 23355)

	SetDrawLayer UserBack
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 85 * sc, 99 * sc, "Current Values"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 258 * sc, "Write to all files (inclusive)"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 227 * sc, 28 * sc, "Attenuation Error Table"
	SetDrawEnv fsize=14 * sc, fstyle=1
	DrawText 18 * sc, 133 * sc, "Run Number(s)"

	Button button0, pos={sc * 20, 81 * sc}, size={sc * 50.00, 20.00 * sc}, proc=ReadAttErrTableButtonProc, title="Read"
	Button button0_1, pos={sc * 20, 220 * sc}, size={sc * 50.00, 20.00 * sc}, proc=WriteAttErrTableButtonProc, title="Write"
	//	Button button0_2,pos={sc*18.00,336.00*sc},size={sc*140.00,20.00*sc},proc=GeneratePerfCalibButton,title="Perfect Calibration"
	Button button0_3, pos={sc * 18.00, 370.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=LoadCSVAttErrTableButton, title="Load Att Err Table CSV"
	Button button0_4, pos={sc * 18.00, 400.00 * sc}, size={sc * 140.00, 20.00 * sc}, proc=WriteCSVAttErrTableButton, title="Write Att Err Table CSV"

	SetVariable setvar0, pos={sc * 20, 141 * sc}, size={sc * 100.00, 14.00 * sc}, title="first"
	SetVariable setvar0, value=root:myGlobals:Patch:gFileNum_Lo_attErr
	SetVariable setvar1, pos={sc * 20.00, 167 * sc}, size={sc * 100.00, 14.00 * sc}, title="last"
	SetVariable setvar1, value=root:myGlobals:Patch:gFileNum_Hi_attErr

	// display the wave
	Edit/W=(180 * sc, 40 * sc, 580 * sc, 550 * sc)/HOST=# root:myGlobals:Patch:attenErrWave
	ModifyTable width(Point)=30
	ModifyTable width(root:myGlobals:Patch:attenErrWave)=100 * sc
	// the elements() command transposes the view in the table, but does not transpose the wave
	//	ModifyTable elements(root:myGlobals:Patch:calibrationWave) = (-3, -2)
	RenameWindow #, T0
	SetActiveSubwindow ##

EndMacro

Function LoadCSVAttErrTableButton(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			LoadWave/J/A/D/O/W/E=1/K=0 //will prompt for the file, auto name

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//
// writes the entire content of the CSV file
//
// first need to put the 12 1D waves into a 2D wave to write to file
//
Function WriteCSVAttErrTableButton(STRUCT WMButtonAction &ba) : ButtonControl

	variable ii
	string   detStr

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			//			DoAlert 0,"incomplete function WriteCSVAttErrTableButton()"

			//			return(0)

			//			ControlInfo popup_0
			//			String detStr = S_Value
			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi           = V_Value
			WAVE     attenErrWave = root:myGlobals:Patch:attenErrWave

			WAVE NGBlambda    = $("root:NGBlambda")
			WAVE NGBatt0_err  = $("root:NGBatt0_err")
			WAVE NGBatt1_err  = $("root:NGBatt1_err")
			WAVE NGBatt2_err  = $("root:NGBatt2_err")
			WAVE NGBatt3_err  = $("root:NGBatt3_err")
			WAVE NGBatt4_err  = $("root:NGBatt4_err")
			WAVE NGBatt5_err  = $("root:NGBatt5_err")
			WAVE NGBatt6_err  = $("root:NGBatt6_err")
			WAVE NGBatt7_err  = $("root:NGBatt7_err")
			WAVE NGBatt8_err  = $("root:NGBatt8_err")
			WAVE NGBatt9_err  = $("root:NGBatt9_err")
			WAVE NGBatt10_err = $("root:NGBatt10_err")

			attenErrWave[][0]  = NGBlambda[p]
			attenErrWave[][1]  = NGBatt0_err[p]
			attenErrWave[][2]  = NGBatt1_err[p]
			attenErrWave[][3]  = NGBatt2_err[p]
			attenErrWave[][4]  = NGBatt3_err[p]
			attenErrWave[][5]  = NGBatt4_err[p]
			attenErrWave[][6]  = NGBatt5_err[p]
			attenErrWave[][7]  = NGBatt6_err[p]
			attenErrWave[][8]  = NGBatt7_err[p]
			attenErrWave[][9]  = NGBatt8_err[p]
			attenErrWave[][10] = NGBatt9_err[p]
			attenErrWave[][11] = NGBatt10_err[p]

			fPatchAttenErrTable(lo, hi, attenErrWave)

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	// TODO
	// -- clear out the data folders (from lo to hi?)
	//
	// root:Packages:NIST:VSANS:RawVSANS:sans1301:
	for(ii = lo; ii <= hi; ii += 1)
		KillDataFolder/Z $("root:Packages:NIST:RawSANS:sans" + num2istr(ii))
	endfor
	return 0
End

Function ReadAttErrTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			variable hi = lo

			fReadAttenErrTable(lo, hi)

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

Function WriteAttErrTableButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			ControlInfo setvar0
			variable lo = V_Value
			ControlInfo setvar1
			variable hi           = V_Value
			WAVE     attenErrWave = root:myGlobals:Patch:attenErrWave

			DoAlert 2, "Do you want to write these values to ALL runs from\r" + num2istr(lo) + " to " + num2istr(hi) + " ?"
			if(V_Flag == 1) //yes, anything else is a no
				fPatchAttenErrTable(lo, hi, attenErrWave)
			endif

			break
		case -1: // control being killed
			break
		default:
			// no default case needed
			break
	endswitch

	return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

//
// finds the lo, hi run numbers in the current directory
// - (NO)--sets the global values for later use
//
// - 2025 -- changed back to pass by reference to be able to set global values that are
// 		specific to each patch panel and won't change unexpectedly
//
// - (NO) you don't really need to pass anything in, the parameters are leftovers from
// the initial version where the values were pass-by-reference and returned
//
Function Find_LoHi_RunNum(variable &lo, variable &hi)

	string fileList = ""
	string fname    = ""
	variable ii, num, runNum

	// set to values that will change
	lo = 1e8
	hi = 0

	// get a file listing of all raw data files
	fileList = N_GetRawDataFileList()
	num      = itemsInList(fileList)

	for(ii = 0; ii < num; ii += 1)
		fname  = stringFromList(ii, fileList)
		runNum = N_GetRunNumFromFile(fname)

		lo = (runNum < lo) ? runNum : lo // if runNum < lo, update
		hi = (runNum > hi) ? runNum : hi // if runNum > hi, update
	endfor

	//	// set the globals
	//	NVAR loVal = root:myGlobals:Patch:gFileNum_Lo
	//	NVAR hiVal = root:myGlobals:Patch:gFileNum_Hi
	//
	//	loVal = lo
	//	hiVal = hi

	return (0)
End

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

// -- quick patch for the integrated detector count -- which should be
//  correctly written in the converted files from this point
//  (it is in the 10m files)
//
Function fPatch_IntegratedCount(variable lo, variable hi)

	variable ii, jj, cts
	string fname

	//loop over all files
	for(jj = lo; jj <= hi; jj += 1)
		fname = N_FindFileFromRunNumber(jj)
		if(strlen(fname) != 0)

			cts = getDetector_Counts(fname)

			writeDet_IntegratedCount(fname, cts)

			Print fname
			printf "run number %d reset to correct values\r", jj

		else
			printf "run number %d not found\r", jj
		endif

	endfor

	return (0)
End

