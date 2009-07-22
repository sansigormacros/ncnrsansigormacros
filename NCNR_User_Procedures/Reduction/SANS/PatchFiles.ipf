#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

//**************************
// Vers. 1.2 092101
//
//proceures required to allow patching of raw SANS data headers
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
	If(V_flag == 0)
		InitializePatchPanel()
		//draw panel
		Patch_Panel()
	Endif
End

//initialization of the panel, creating the necessary data folder and global
//variables if necessary - simultaneously initialize the globals for the Trans
//panel at theis time, to make sure they all exist
//
Proc InitializePatchPanel()
	//create the global variables needed to run the Patch Panel
	//all are kept in root:myGlobals:Patch
	If( ! (DataFolderExists("root:myGlobals:Patch"))  )
		//create the data folder and the globals for BOTH the Patch and Trans panels
		NewDataFolder/O root:myGlobals:Patch
		CreatePatchGlobals()
	Endif

End

//the data folder root:myGlobals:Patch must exist
//
Proc CreatePatchGlobals()
	//ok, create the globals
	String/G root:myGlobals:Patch:gPatchMatchStr = "*"
	PathInfo catPathName
	If(V_flag==1)
		String dum = S_path
		String/G root:myGlobals:Patch:gCatPathStr = dum
	else
		String/G root:myGlobals:Patch:gCatPathStr = "no path selected"
	endif
	String/G root:myGlobals:Patch:gPatchList = "none"
	String/G root:myGlobals:Patch:gPS1 = "no file selected"
	String/G root:myGlobals:Patch:gPS2 = "no file selected"
	String/G root:myGlobals:Patch:gPS3 = "no box selected"
	Variable/G root:myGlobals:Patch:gPV1 =0
	Variable/G root:myGlobals:Patch:gPV2 = 0
	Variable/G root:myGlobals:Patch:gPV3 = 0
	Variable/G root:myGlobals:Patch:gPV4 = 0
	Variable/G root:myGlobals:Patch:gPV5 = 0
	Variable/G root:myGlobals:Patch:gPV6 = 0
	Variable/G root:myGlobals:Patch:gPV7 = 0
	Variable/G root:myGlobals:Patch:gPV8 = 0
	Variable/G root:myGlobals:Patch:gPV9 = 0
	Variable/G root:myGlobals:Patch:gPV10 = 0
	Variable/G root:myGlobals:Patch:gPV11 = 0
	Variable/G root:myGlobals:Patch:gPV12 = 0
	Variable/G root:myGlobals:Patch:gPV13 = 0
	Variable/G root:myGlobals:Patch:gPV14 = 0
	Variable/G root:myGlobals:Patch:gPV15 = 0
	Variable/G root:myGlobals:Patch:gPV16 = 0
	Variable/G root:myGlobals:Patch:gPV17 = 0
	Variable/G root:myGlobals:Patch:gPV18 = 0
	Variable/G root:myGlobals:Patch:gPV19 = 0
	Variable/G root:myGlobals:Patch:gTransCts = 0
	Variable/G root:myGlobals:Patch:gRadioVal = 1
End

//button action procedure to select the local path to the folder that
//contains the SANS data
//sets catPathName, updates the path display and the popup of files (in that folder)
//
Function PickPathButton(PathButton) : ButtonControl
	String PathButton
	
	//set the global string to the selected pathname
	PickPath()
	//set a local copy of the path for Patch
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:myGlobals:Patch:gCatPathStr = "no folder selected"
	else
		String/G root:myGlobals:Patch:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=Patch_Panel $"PathDisplay"
	
	//then update the popup list
	// (don't update the list - not until someone enters a search critera) -- Jul09
	//
	SetMatchStrProc("",0,"*","")		//this is equivalent to finding everything, typical startup case

End


//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
Function/S xGetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:myGlobals:Patch:gPatchMatchStr
	if(strlen(match) == 0)		//if nothing is entered for a match string, return everything, rather than nothing
		match = "*"
	endif
	
	newlist = MyMatchList(match,newlist,";")
	
	newList = SortList(newList,";",0)
	Return(newList)
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
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:myGlobals:Patch:gPatchMatchStr
	if(strlen(match) == 0 || cmpstr(match,"*")==0)		//if nothing or "*" entered for a match string, return everything, rather than nothing
		match = "*"
	// old way, with simply a wildcard
		newlist = MyMatchList(match,newlist,";")
		newList = SortList(newList,";",0)
		return(newList)
	endif
	
	//loop through all of the files as needed
	// Grep Note: the \\b sequences limit matches to a word boundary before and after
	// "boondoggle", so "boondoggles" and "aboondoggle" won't match.
	
	String list="",item="",fname,runList="",numStr=""
	Variable ii,num=ItemsInList(newList),val,sdd
	NVAR gRadioVal= root:myGlobals:Patch:gRadioVal
	


	// run number list
	if(gRadioVal == 1)
//		list = ParseRunNumberList(match)		//slow, file access every time
//		list = ReplaceString(",", list, ";")
//		newList = list
		
		list = ExpandNumRanges(match)		//now simply comma delimited
		num=ItemsInList(list,",")
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,list,",")
			val=str2num(item)
			//make a three character string of the run number
			if(val<10)
				numStr = "00"+num2str(val)
			else
				if(val<100)
					numStr = "0"+num2str(val)
				else
					numStr = num2str(val)
				Endif
			Endif
			runList += ListMatch(newList,"*"+numStr+"*",";")
			
		endfor
		newlist = runList
		
	endif
	
	//grep through what text I can find in the VAX binary
	if(gRadioVal == 2)
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
//			Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
			Grep/P=catPathName/Q/E=("(?i)"+match) item
			if( V_value )	// at least one instance was found
//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

		newList = list
	endif
	
	// SDD
	if(gRadioVal == 3)
		val = str2num(match)
//		print val
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
			fname = path + item
			sdd = getSDD(fname)
			if(abs(val - sdd) < 0.001	)		//if numerically within 0.001 meter, they're the same
				list += item + ";"
			endif
		endfor
		
		newList = list
	endif

	newList = SortList(newList,";",0)
	Return(newList)
End




// -- no longer refreshes the list - this seems redundant, and can be slow if grepping
//
//updates the popup list when the menu is "popped" so the list is 
//always fresh, then automatically displays the header of the popped file
//value of match string is used in the creation of the list - use * to get
//all valid files
//
Function PatchPopMenuProc(PatchPopup,popNum,popStr) : PopupMenuControl
	String PatchPopup
	Variable popNum
	String popStr

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
Function SetMatchStrProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)
	
	String list = GetValidPatchPopupList()
	
	String/G root:myGlobals:Patch:gPatchList = list
	ControlUpdate PatchPopup
	PopupMenu PatchPopup,mode=1
	
	if(strlen(list) > 0)
		ShowHeaderButtonProc("SHButton")
	endif
End


//displays the header of the selected file (top in the popup) when the button is clicked
//sort of a redundant button, since the procedure is automatically called (as if it were
//clicked) when a new file is chosen from the popup
//
Function ShowHeaderButtonProc(SHButton) : ButtonControl
	String SHButton

	//displays (editable) header information about current file in popup control
	//putting the values in the SetVariable displays (resetting the global variables)
	
	//get the popup string
	String partialName, tempName
	Variable ok
	ControlInfo/W=Patch_Panel PatchPopup
	If(strlen(S_value)==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		partialName = S_value
		//Print partialName
	Endif
	//get a valid file based on this partialName and catPathName
	tempName = FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = CheckIfRawData(tempName)
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
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
Function GetCheckBoxesState(w,num)
	Wave w	   //on return, this wave contains the current state of the checkboxes
	Variable num
	
	if(num != 20)
		Abort "wrong number of checkboxes GetCheckBoxesState()"
	Endif
	ControlInfo checkPS1
	w[0] = V_value
	
	Variable ii
	String baseStr="checkPV"
	
	ii=1
	do
		ControlInfo $(baseStr + num2str(ii))
		w[ii] = V_Value
		ii+=1
	while(ii<num)
	return(0)
End

//on return, wt is a TEXT wave with the values in the SetVar boxes
//will poll the SetVariable controls to get the new values - will get all the values,
//and let the writing routine decide which ones it will actually use
//num (input) is a simple check to make sure that the wave is set up properly
//from the calling routine
//
Function GetEditedSetVarBoxes(wt,num)
	Wave/T wt	   
	Variable num
	
	if(num != 20)
		Abort "wrong number of checkboxes GetEditedSetVarBoxes()"
	Endif
	//pass all as a text wave - so only one wave has to be passed (conversion 2x, though)
	//global is set to the changed value when entered. read others directly from the control
	//make sure the text label is exactly 60 characters long, to match VAX field length
	SVAR dum=root:myGlobals:Patch:gPS1
	String str60="", junk="junk" 
	str60 = PadString(junk,60,0x20)
	if(strlen(dum) <= 60)
		if(strlen(dum) == 60)
		   str60 = dum
		else
		   str60 = PadString(dum,60,0x20)
		Endif
	else
		//too long, truncate
		str60[0,59] = dum[0,59]
	Endif
	
	wt[0] = str60
	
	Variable ii
	String baseStr="PV"
	ii=1
	do
		ControlInfo $(baseStr + num2str(ii))
		wt[ii] = num2str(V_Value)
		ii+=1
	while(ii<num)
	
	return(0)	//no error
End


//simple function to get the string value from the popup list of filenames
//returned string is only the text in the popup, a partial name with no path
//or VAX version number.
//
Function/S GetPatchPopupString()

	String str=""
	
	ControlInfo patchPopup
	If(cmpstr(S_value,"")==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		str = S_value
		//Print str
	Endif
	
	Return str
End

//Changes (writes to disk!) the specified changes to the (single) file selected in the popup
//reads the checkboxes to determine which (if any) values need to be written
//
Function ChangeHeaderButtonProc(CHButton) : ButtonControl
	String CHButton

	//read the (20) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars	 
	String partialName="", tempName = ""
	Variable ok,nvars = 20,ii
	
	Make/O/N=(nvars) tempChange
	Wave w=tempchange
	GetCheckBoxesState(w,nvars)
	//Print "w[0] = ",w[0]
	
	
	//Get the current values in each of the fields - to pass to Write() as a textwave
	Make/O/T/N=(nvars) tempValues
	Wave/T wt=tempValues
	//initialize textwave
	ii=0
	do
		wt[ii] = ""
		ii+=1
	while(ii<nvars)
	GetEditedSetVarBoxes(wt,nvars)
	
	//get the popup string
	partialName = GetPatchPopupString()
	
	//get a valid file based on this partialName and catPathName
	tempName = FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = CheckIfRawData(tempName)
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
	//go write the changes to the file
	WriteHeaderForPatch(tempName,w,wt)
	
	//clean up wave before leaving
	KillWaves/Z w,wt
	
End

//*****this function actually writes the data to disk*****
//overwrites the specific bytes the the header that are to be changed
//real values are written out mimicking VAX format, so that can be properly
//re-read as raw binary VAX files.
//if any additional fields are to be edited, the exact byte location must be known
//
Function WriteHeaderForPatch(fname,change,textVal)
	String fname
	Wave change
	Wave/T textVal
	
	Variable refnum,num
	String textstr
	
	//change the sample label ?
	if(change[0])
		WriteSamLabelToHeader(fname,textVal[0])
	Endif
	
	//total count time is an integer, handle separately
	if(change[6])
		num =str2num(textVal[6])
		WriteCountTimeToHeader(fname,num)
	Endif
	
	//ReWriteReal() takes care of open/close on its own
	if(change[1])		//sample transmission
		num = str2num(textVal[1])
		WriteTransmissionToHeader(fname,num)
	Endif
	if(change[2])		//sample thickness
		num = str2num(textVal[2])
		WriteThicknessToHeader(fname,num)
	Endif
	if(change[3])		//pixel X
		num = str2num(textVal[3])
		WriteBeamCenterXToHeader(fname,num)
	Endif
	if(change[4])		// pixel Y
		num = str2num(textVal[4])
		WriteBeamCenterYToHeader(fname,num)
	Endif
	if(change[5])		//attenuator number
		num = str2num(textVal[5])
		WriteAttenNumberToHeader(fname,num)
	Endif
	//[6] was the counting time, integer written above
	if(change[7])    //monitor count
		num = str2num(textVal[7]) 
		WriteMonitorCountToHeader(fname,num)
	Endif
	if(change[8])     //total detector count
		num = str2num(textVal[8])
		WriteDetectorCountToHeader(fname,num)
	Endif
	if(change[9])      //trans det count
		num = str2num(textVal[9])
		WriteTransDetCountToHeader(fname,num)
	Endif
	if(change[10])      //wavelength
		num = str2num(textVal[10])
		WriteWavelengthToHeader(fname,num)
	Endif
	///
	if(change[11])      //wavelength spread
		num = str2num(textVal[11])
		WriteWavelengthDistrToHeader(fname,num)
	Endif
	if(change[12])      //temperature
		num = str2num(textVal[12])
		WriteTemperatureToHeader(fname,num)
	Endif
	if(change[13])      //magnetic field
		num = str2num(textVal[13])
		WriteMagnFieldToHeader(fname,num)
	Endif
	if(change[14])      //source aperture
		num = str2num(textVal[14])
		WriteSourceApDiamToHeader(fname,num)
	Endif
	if(change[15])      //sample aperture
		num = str2num(textVal[15])
		WriteSampleApDiamToHeader(fname,num)
	Endif
	///
	if(change[16])      //source-sam dist
		num = str2num(textVal[16])
		WriteSrcToSamDistToHeader(fname,num)
	Endif
	if(change[17])      //det offset
		num = str2num(textVal[17])
		WriteDetectorOffsetToHeader(fname,num)
	Endif
	if(change[18])      //beamstop diam
		num = str2num(textVal[18])
		WriteBeamStopDiamToHeader(fname,num)
	Endif
	if(change[19])     //SDD
		num = str2num(textVal[19])
		WriteSDDToHeader(fname,num)
	Endif
	Return(0)
End

//panel recreation macro for the PatchPanel...
//
Proc Patch_Panel()
	PauseUpdate; Silent 1	   // building window...
	NewPanel /W=(519,85,950,608)/K=1 as "Patch Raw SANS Data Files"
//	NewPanel /W=(519,85,950,608) as "Patch Raw SANS Data Files"
	DoWindow/C Patch_Panel
	ModifyPanel cbRGB=(1,39321,19939)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fname= "Courier",fstyle= 1
	DrawText 3,107,"Change?"
	DrawLine 7,30,422,30
	DrawLine 7,288,422,288
	DrawLine 7,199,422,199
	DrawLine 7,378,422,378
	DrawLine 7,469,422,469
	SetVariable PathDisplay,pos={77,7},size={310,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while patching. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,font="Courier",fSize=10
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gCatPathStr
	Button PathButton,pos={2,3},size={70,20},proc=PickPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={400,3},size={25,20},proc=ShowPatchHelp,title="?"
	Button helpButton,help={"Show the help file for patching raw data headers"}
	PopupMenu PatchPopup,pos={4,37},size={156,19},proc=PatchPopMenuProc,title="File(s) to Patch"
	PopupMenu PatchPopup,help={"The displayed file is the one that will be edited. The entire list will be edited if \"Change All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh. \r List items are selected from the file based on MatchString"}
	PopupMenu PatchPopup,mode=1,popvalue="none",value= #"root:myGlobals:Patch:gPatchList"
//	Button SHButton,pos={324,37},size={100,20},proc=ShowHeaderButtonProc,title="Show Header"
//	Button SHButton,help={"This will display the header of the file indicated in the popup menu."}
	Button CHButton,pos={314,37},size={110,20},proc=ChangeHeaderButtonProc,title="Change Header"
	Button CHButton,help={"This will change the checked values (ONLY) in the single file selected in the popup."}
	SetVariable PMStr,pos={6,63},size={174,13},proc=SetMatchStrProc,title="Match String"
	SetVariable PMStr,help={"Enter the search string to narrow the list of files. \"*\" is the wildcard character. After entering, \"pop\" the menu to refresh the file list."}
	SetVariable PMStr,font="Courier",fSize=10
	SetVariable PMStr,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPatchMatchStr
	Button ChAllButton,pos={245,60},size={180,20},proc=ChAllHeadersButtonProc,title="Change All Headers in List"
	Button ChAllButton,help={"This will change the checked values (ONLY) in ALL of the files in the popup list, not just the top file. If the \"change\" checkbox for the item is not checked, nothing will be changed for that item."}
	Button DoneButton,pos={310,489},size={110,20},proc=DoneButtonProc,title="Done Patching"
	Button DoneButton,help={"When done Patching files, this will close this control panel."}
	Button cat_short,pos={9,485},size={100,20},proc=DoCatShort,title="File Catalog"
	Button cat_short,help={"Use this button to generate a notebook with file header information. Very useful for identifying files."}
	SetVariable PS1,pos={42,111},size={338,13},proc=SetLabelVarProc,title="label"
	SetVariable PS1,help={"Current sample label"},font="Courier",fSize=10
	SetVariable PS1,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPS1
	SetVariable PV1,pos={42,129},size={340,13},title="Transmission"
	SetVariable PV1,help={"Current transmission\rvalue"},font="Courier",fSize=10
	SetVariable PV1,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV1
	SetVariable PV2,pos={42,147},size={340,13},title="Thickness (cm)"
	SetVariable PV2,help={"Current sample thickness, in units of centimeters"}
	SetVariable PV2,font="Courier",fSize=10
	SetVariable PV2,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV2
	SetVariable PV3,pos={42,165},size={340,13},title="Beamcenter X"
	SetVariable PV3,help={"Current X-position of the beamcenter, in pixels"}
	SetVariable PV3,font="Courier",fSize=10
	SetVariable PV3,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV3
	SetVariable PV4,pos={42,183},size={340,13},title="Beamcenter Y"
	SetVariable PV4,help={"Current Y-position of the beamcenter, in pixels"}
	SetVariable PV4,font="Courier",fSize=10
	SetVariable PV4,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV4
	SetVariable PV5,pos={42,202},size={340,13},title="Attenuator number"
	SetVariable PV5,help={"attenuator number present during data collection"}
	SetVariable PV5,font="Courier",fSize=10
	SetVariable PV5,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV5
	SetVariable PV6,pos={42,219},size={340,13},title="Counting time (s)",font="Courier",fSize=10
	SetVariable PV6,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV6
	SetVariable PV6,help={"total counting time in seconds"}
	SetVariable PV7,pos={42,237},size={340,13},title="Monitor count",font="Courier",fSize=10
	SetVariable PV7,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV7
	SetVariable PV7,help={"total monitor counts"}
	SetVariable PV8,pos={42,255},size={340,13},title="Detector count",font="Courier",fSize=10
	SetVariable PV8,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV8
	SetVariable PV8,help={"total detector counts"}
	SetVariable PV9,pos={42,273},size={340,13},title="Trans. det. count",font="Courier",fSize=10
	SetVariable PV9,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV9
	SetVariable PV9,help={"Transmission\r detector counts"}
	SetVariable PV10,pos={42,291},size={340,13},title="Wavelength (A)",font="Courier",fSize=10
	SetVariable PV10,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV10
	SetVariable PV10,help={"neutron wavelength in angstroms"}
	SetVariable PV11,pos={42,309},size={340,13},title="Wavelength spread (dL/L)",font="Courier",fSize=10
	SetVariable PV11,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV11
	SetVariable PV11,help={"wavelength spread (delta lambda)/lambda"}
	SetVariable PV12,pos={42,327},size={340,13},title="Temperature (C)",font="Courier",fSize=10
	SetVariable PV12,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV12
	SetVariable PV12,help={"Set point temperature in centigrade"}
	SetVariable PV13,pos={42,345},size={340,13},title="Magnetic field (G)",font="Courier",fSize=10
	SetVariable PV13,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV13
	SetVariable PV13,help={"magnetic field strength units?"}
	SetVariable PV14,pos={42,363},size={340,13},title="Source aperture diameter (mm)",font="Courier",fSize=10
	SetVariable PV14,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV14
	SetVariable PV14,help={"source aperture diameter, in millimeters"}
	SetVariable PV15,pos={42,381},size={340,13},title="Sample aperture diameter (mm)",font="Courier",fSize=10
	SetVariable PV15,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV15
	SetVariable PV15,help={"sample aperture diameter, in millimeters"}
	SetVariable PV16,pos={42,399},size={340,13},title="Source to sample distance (m)",font="Courier",fSize=10
	SetVariable PV16,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV16
	SetVariable PV16,help={"Source to sample distance in meters"}
	SetVariable PV17,pos={42,417},size={340,13},title="Detector offset (cm)",font="Courier",fSize=10
	SetVariable PV17,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV17
	SetVariable PV17,help={"Detector offset, in centimeters"}
	SetVariable PV18,pos={42,435},size={340,13},title="Beamstop diameter (mm)",font="Courier",fSize=10
	SetVariable PV18,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV18
	SetVariable PV18,help={"beamstop diamter, in millimeters (1 inch = 25.4mm)"}
	SetVariable PV19,pos={42,453},size={340,13},title="Sample to detector distance (m)",font="Courier",fSize=10
	SetVariable PV19,limits={-Inf,Inf,0},value= root:myGlobals:Patch:gPV19
	SetVariable PV19,help={"sample to detector distance, in meters"}
	
	CheckBox checkPS1,pos={18,108},size={20,20},title=""
	CheckBox checkPS1,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV1,pos={18,126},size={20,20},title=""
	CheckBox checkPV1,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV2,pos={18,144},size={20,20},title=""
	CheckBox checkPV2,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV3,pos={18,162},size={20,20},title=""
	CheckBox checkPV3,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV4,pos={18,180},size={20,20},title=""
	CheckBox checkPV4,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV5,pos={18,198},size={20,20},title=""
	CheckBox checkPV5,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV6,pos={18,216},size={20,20},title=""
	CheckBox checkPV6,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV7,pos={18,234},size={20,20},title="",value=0
	CheckBox checkPV7,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV8,pos={18,252},size={20,20},title="",value=0
	CheckBox checkPV8,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV9,pos={18,270},size={20,20},title="",value=0
	CheckBox checkPV9,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV10,pos={18,288},size={20,20},title="",value=0
	CheckBox checkPV10,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV11,pos={18,306},size={20,20},title="",value=0
	CheckBox checkPV11,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV12,pos={18,324},size={20,20},title="",value=0
	CheckBox checkPV12,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV13,pos={18,342},size={20,20},title="",value=0
	CheckBox checkPV13,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV14,pos={18,360},size={20,20},title="",value=0
	CheckBox checkPV14,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV15,pos={18,378},size={20,20},title="",value=0
	CheckBox checkPV15,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV16,pos={18,396},size={20,20},title="",value=0
	CheckBox checkPV16,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV17,pos={18,414},size={20,20},title="",value=0
	CheckBox checkPV17,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV18,pos={18,432},size={20,20},title="",value=0
	CheckBox checkPV18,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV19,pos={18,450},size={20,20},title="",value=0
	CheckBox checkPV19,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox check0,pos={18,80},size={40,15},title="Run #",value= 1,mode=1,proc=MatchCheckProc
	CheckBox check1,pos={78,80},size={40,15},title="Text",value= 0,mode=1,proc=MatchCheckProc
	CheckBox check2,pos={138,80},size={40,15},title="SDD",value= 0,mode=1,proc=MatchCheckProc

End


Function MatchCheckProc(name,value)
	String name
	Variable value
	
	NVAR gRadioVal= root:myGlobals:Patch:gRadioVal
	
	strswitch (name)
		case "check0":
			gRadioVal= 1
			break
		case "check1":
			gRadioVal= 2
			break
		case "check2":
			gRadioVal= 3
			break
	endswitch
	CheckBox check0,value= gRadioVal==1
	CheckBox check1,value= gRadioVal==2
	CheckBox check2,value= gRadioVal==3
End

//This function will read only the selected values editable in the patch panel
//The values read are passed to the panel through the global variables
//the function WriteHeaderForPatch() MUST mirror this set of reads, or nothing can be updated
//
//fname is the full path:name;vers to open the file
//
Function ReadHeaderForPatch(fname)
	String fname
	//this function is for reading in values to be patched - so don't save any waves
	//just reset the global variables that are on the patch panel
	
	// each "get" is an individual call to GBLoadWave...
	// test for acceptable speed over a network...
	
	//assign to the globals for display in the panel
	String/G root:myGlobals:Patch:gPS1= getSampleLabel(fname)
	Variable/G root:myGlobals:Patch:gPV1 = getSampleTrans(fname)
	Variable/G root:myGlobals:Patch:gPV2 = getSampleThickness(fname)
	Variable/G root:myGlobals:Patch:gPV3 = getBeamXPos(fname)
	Variable/G root:myGlobals:Patch:gPV4 = getBeamYPos(fname)
	Variable/G root:myGlobals:Patch:gPV5 = getAttenNumber(fname)
	Variable/G root:myGlobals:Patch:gPV6 = getCountTime(fname)
	Variable/G root:myGlobals:Patch:gPV7 = getMonitorCount(fname)
	Variable/G root:myGlobals:Patch:gPV8 = getDetCount(fname)
	Variable/G root:myGlobals:Patch:gPV9 = getTransDetectorCounts(fname)
	Variable/G root:myGlobals:Patch:gPV10 = getWavelength(fname)
	Variable/G root:myGlobals:Patch:gPV11 = getWavelengthSpread(fname)
	Variable/G root:myGlobals:Patch:gPV12 = getTemperature(fname)
	Variable/G root:myGlobals:Patch:gPV13 = getFieldStrength(fname)
	Variable/G root:myGlobals:Patch:gPV14 = getSourceApertureDiam(fname)
	Variable/G root:myGlobals:Patch:gPV15 = getSampleApertureDiam(fname)
	Variable/G root:myGlobals:Patch:gPV16 = getSourceToSampleDist(fname)
	Variable/G root:myGlobals:Patch:gPV17 = getDetectorOffset(fname)
	Variable/G root:myGlobals:Patch:gPV18 = getBSDiameter(fname)
	Variable/G root:myGlobals:Patch:gPV19 = getSDD(fname)
	
	Return 0
End

Function ShowPatchHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Patch File Headers]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button action procedure to change the selected information (checked values)
//in each file in the popup list. This will change multiple files, and as such,
//the user is given a chance to bail out before the whole list of files
//is modified
//useful for patching a series of runs with the same beamcenters, or transmissions
//
Function ChAllHeadersButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String msg
	msg = "Do you really want to write all of these values to each data file in the popup list? "
	msg += "- clicking NO will leave all files unchanged"
	DoAlert 1,msg
	If(V_flag == 2)
		Abort "no files were changed"
	Endif
	
	//this will change (checked) values in ALL of the headers in the popup list
	SVAR list = root:myGlobals:Patch:gPatchList
	Variable numitems,ii
	numitems = ItemsInList(list,";")
	
	if(numitems == 0)
		Abort "no items in list for multiple patch"
	Endif
	
	//read the (6) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars	 
	String partialName="", tempName = ""
	Variable ok,nvars = 20
	
	Make/O/N=(nvars) tempChange
	Wave w=tempchange
	GetCheckBoxesState(w,nvars)
	//Print "w[0] = ",w[0]
	
	//Get the current values in each of the fields - to pass to Write() as a textwave
	Make/O/T/N=(nvars) tempValues
	Wave/T wt=tempValues
	//initialize textwave
	ii=0
	do
		wt[ii] = ""
		ii+=1
	while(ii<nvars)
	GetEditedSetVarBoxes(wt,nvars)
	
	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	ii=0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		   
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(partialName)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
	
		//make sure the file is really a RAW data file
		ok = CheckIfRawData(tempName)
		if (!ok)
		   Print "this file is not recognized as a RAW SANS data file = ",tempName
		else
		   //go write the changes to the file
		   WriteHeaderForPatch(tempName,w,wt)
		Endif
		
		ii+=1
	while(ii<numitems)
	
	//clean up wave before leaving
	KillWaves/Z w,wt
		
End


//simple action for button to close the panel
Function DoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K Patch_Panel
	
End

//resets the global string corresponding to the sample label 
//updates when new text is entered
//
Function SetLabelVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	//reset the global variable to the entered text so that it can be relayed to the 
	//write() routine. Only the TEXT SetVariable control needs to be handled this way
	
	String/G root:myGlobals:Patch:gPS1 = varStr

End


// testing, very dangerous batch changing of the file header labels
//
// testStr is the string at the front of a label, that will be moved to the "back"
// if doIt is 1, it will write to the headers, any other value will only print to history
Function MPatchLabel(testStr,doIt)
	String testStr
	Variable doIt

//	SVAR list = root:myGlobals:Patch:gPatchList
	String list = GetValidPatchPopupList()

	Variable numitems,ii
	numitems = ItemsInList(list,";")
	
	if(numitems == 0)
		Abort "no items in list for multiple patch"
	Endif
	
	String partialName="", tempName = ""
	Variable ok,nvars = 20
	
	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	string str1,str2,str3
	Variable match,loc,len,spc,jj,len1
	len=strlen(testStr)
	ii=0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		   
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(partialName)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
	
		//make sure the file is really a RAW data file
		ok = CheckIfRawData(tempName)
		if (!ok)
		   Print "this file is not recognized as a RAW SANS data file = ",tempName
		else
		   //go write the changes to the file
		   str1 = getSampleLabel(tempName)
			match = strsearch(str1, testStr, 0)
			if(match != -1)
				str2 = ReplaceString(testStr, str1, "", 0, 1)
				
				jj=strlen(str2)
				do
					jj -= 1
					spc = cmpstr(str2[jj], " ")		//can add the optional flag ,0), but I don't care about case, and Igor 6.02 is necessary...
					if (spc != 0)
						break		//no more spaces found, get out
					endif
				While(1)	// jj is the location of the last non-space
				
				str2[jj+2,jj+1+len] = testStr
			
			// may need to remove leading spaces???
				str2 = PadString(str2, 60, 0x20 )
				
				if(doIt == 1)
					WriteSamLabelToHeader(tempName,str2)
					print str2," ** Written to file **"
				else
					//print str2,strlen(str2)
					print str2," ** Testing, not written to file **"
				endif
			else
				
				jj=strlen(str1)
				do
					jj -= 1
					spc = cmpstr(str1[jj], " ")
					if (spc != 0)
						break		//no more spaces found, get out
					endif
				While(1)
	
				//print str1, jj, str1[jj]	
			endif
		Endif
		
		ii+=1
	while(ii<numitems)


end