#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



// TODO
// x- initialization
// x- link to main panel
//
// ?? redesign the panel based on the CATALOG?
// -- refresh the catalog, then work with those waves?
//
// -- this still seems to be very awkward to use. Come up with something better
//
// -- need more checks - be sure that the files match
// -- SDD, wavelength, beam on proper panel, etc.
//
// -- need popups (transmission, open) to respond to popup changes and
//   update their fields, since they may be auto-located incorrectly.
// 
// to patch the box coordinates
// err = V_writeBoxCoordinates(fname,V_List2NumWave(str,";","inW"))



//
Function V_InitTransmissionPanel()
	
	DoWindow/F V_TransmissionPanel
	if(V_Flag == 0)
		V_InitTransPanelGlobals()
		Execute "V_TransmissionPanel()"
	endif
End

Function V_InitTransPanelGlobals()

// root:Packages:NIST:VSANS:Globals:Transmission
	NewDataFolder/O/S root:Packages:NIST:VSANS:Globals:Transmission
	Variable/G gSamGrpID,gTrnGrpID,gTrans,gTransErr
	String/G gSamLabel="file label",gTransLabel="file label",gEmptyLabel="file label"
	String/G gEmptyBoxCoord="1;2;3;4;",gEmptyPanel="ENTER PANEL"
	String/G gSamMatchList = "_none_"
	String/G gTransMatchList = "_none_"


	SetDataFolder root:
	return(0)
End

Window V_TransmissionPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1496,366,1974,990) /K=1
	ModifyPanel cbRGB=(32896,16448,0,19621)
	DoWindow/C V_TransmissionPanel

//	ShowTools/A
	PopupMenu popup_0,pos={16.00,359.00},size={104.00,23.00},fstyle=1,fsize=12,proc=V_TSamFilePopMenuProc,title="Sample"
	PopupMenu popup_0,mode=1,popvalue="_none_",value= #"root:Packages:NIST:VSANS:Globals:Transmission:gSamMatchList"
	PopupMenu popup_1,pos={12.00,229.00},size={195.00,23.00},fstyle=1,fsize=12,proc=V_TTransmFilePopMenuProc,title="Transmission"
	PopupMenu popup_1,mode=1,popvalue="_none_",value = #"root:Packages:NIST:VSANS:Globals:Transmission:gTransMatchList"//value= V_getFilePurposeList("TRANSMISSION",0)
	PopupMenu popup_2,pos={17.00,79.00},size={188.00,23.00},fstyle=1,fsize=12,proc=V_TEmpBeamPopMenuProc,title="Open Beam"
	PopupMenu popup_2,mode=1,popvalue="sans1.nxs.ngv",value= V_getFileIntentList("OPEN BEAM",0)
	Button button_0,pos={34.00,499.00},size={100.00,20.00},proc=V_CalcTransmButtonProc,title="Calculate"
	Button button_2,pos={349.00,13.00},size={30.00,20.00},proc=V_HelpTransmButtonProc,title="?"
	Button button_3,pos={410.00,13.00},size={50.00,20.00},proc=V_DoneTransmButtonProc,title="Done"
	Button button_4,pos={164.00,500.00},size={150.00,20.00},proc=V_CalcTransmListButtonProc,title="Calculate All In Popup"
	SetVariable setvar_0,pos={18.00,390.00},size={300.00,14.00},title="Label:"
	SetVariable setvar_0,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gSamLabel
	SetVariable setvar_1,pos={18.00,417.00},size={300.00,14.00},title="Group ID:"
	SetVariable setvar_1,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gSamGrpID
	SetVariable setvar_2,pos={15.00,257.00},size={300.00,14.00},title="Label:"
	SetVariable setvar_2,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTransLabel
	SetVariable setvar_3,pos={14.00,283.00},size={300.00,14.00},title="Group ID:"
	SetVariable setvar_3,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTrnGrpID
	SetVariable setvar_4,pos={18.00,108.00},size={300.00,14.00},title="Label:"
	SetVariable setvar_4,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyLabel
	SetVariable setvar_5,pos={18.00,132.00},size={300.00,14.00},title="XY Box:"
	SetVariable setvar_5,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyBoxCoord
	SetVariable setvar_6,pos={18.00,157.00},size={300.00,14.00},fstyle=1,fsize=12,title="Panel:"
	SetVariable setvar_6,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyPanel
	SetVariable setvar_7,pos={18.00,442.00},size={300.00,14.00},title="Transmission:"
	SetVariable setvar_7,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTrans
	SetVariable setvar_8,pos={18.00,467.00},size={300.00,14.00},title="Error:"
	SetVariable setvar_8,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTransErr
EndMacro


//Window V_TransmissionPanel() : Panel
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(1286,328,1764,952)
//	ModifyPanel cbRGB=(32896,16448,0,19621)
//	DoWindow/C V_TransmissionPanel
//
////	ShowTools/A
//	PopupMenu popup_0,pos={19.00,55.00},size={86.00,23.00},proc=V_TSamFilePopMenuProc,title="Sample"
////	PopupMenu popup_0,mode=1,value= V_getFilePurposeList("SCATTERING",0)//+V_getFileIntentList("EMPTY CELL",0)
//	PopupMenu popup_0,mode=1,value=root:Packages:NIST:VSANS:Globals:Transmission:gSamMatchList 
//	PopupMenu popup_1,pos={102,248},size={72.00,23.00},proc=V_TTransmFilePopMenuProc,title="Transmission"
//	PopupMenu popup_1,mode=1,value= V_getFilePurposeList("TRANSMISSION",0)
//	PopupMenu popup_2,pos={164,353},size={72.00,23.00},proc=V_TEmpBeamPopMenuProc,title="Open Beam"
////	PopupMenu popup_2,mode=1,value= V_getFileIntentList("EMPTY BEAM",0)
//	PopupMenu popup_2,mode=1,value= V_getFileIntentList("OPEN BEAM",0)
//	Button button_0,pos={37,193},size={100.00,20.00},proc=V_CalcTransmButtonProc,title="Calculate"
////	Button button_1,pos={23.00,491.00},size={100.00,20.00},proc=V_WriteTransmButtonProc,title="Write"
//	Button button_2,pos={349.00,13.00},size={30.00,20.00},proc=V_HelpTransmButtonProc,title="?"
//	Button button_3,pos={410.00,13.00},size={50.00,20.00},proc=V_DoneTransmButtonProc,title="Done"
//	SetVariable setvar_0,pos={21.00,86.00},size={300.00,14.00},title="Label:"
//	SetVariable setvar_0,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gSamLabel
//	SetVariable setvar_1,pos={21.00,113.00},size={300.00,14.00},title="Group ID:"
//	SetVariable setvar_1,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gSamGrpID
//	SetVariable setvar_2,pos={105,276.00},size={300.00,14.00},title="Label:"
//	SetVariable setvar_2,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTransLabel
//	SetVariable setvar_3,pos={104,302},size={300.00,14.00},title="Group ID:"
//	SetVariable setvar_3,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTrnGrpID
//	SetVariable setvar_4,pos={165,382},size={300.00,14.00},title="Label:"
//	SetVariable setvar_4,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyLabel
//	SetVariable setvar_5,pos={165,406},size={300.00,14.00},title="XY Box:"
//	SetVariable setvar_5,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyBoxCoord
//	SetVariable setvar_6,pos={165,431},size={300.00,14.00},title="Panel:"
//	SetVariable setvar_6,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gEmptyPanel
//	SetVariable setvar_7,pos={21,138},size={300.00,14.00},title="Transmission:"
//	SetVariable setvar_7,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTrans
//	SetVariable setvar_8,pos={21,163},size={300.00,14.00},title="Error:"
//	SetVariable setvar_8,limits={-inf,inf,0},value= root:Packages:NIST:VSANS:Globals:Transmission:gTransErr
//EndMacro

// TODO
// -- fill in the details
// -- currently, I pick these from the Catalog, for speed
// -- ? is the catalog current?
// -- T error is not part of the Catalog - is that OK?
//
// when the SAM file menu is popped:
//  fill in the fields:
// x- label
// x- group id
// x- transmission
// -- T error
//
Function V_TSamFilePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa


// **** TODO
// short-circuit the switch, and simply report the values
// -- the TransFile popup now drives the panel
		SVAR gSamLabel = root:Packages:NIST:VSANS:Globals:Transmission:gSamLabel
		gSamLabel = V_getSampleDescription(pa.popStr)
		NVAR gSamGrpID = root:Packages:NIST:VSANS:Globals:Transmission:gSamGrpID
		gSamGrpID = V_getSample_GroupID(pa.popStr)
		NVAR gTrans = root:Packages:NIST:VSANS:Globals:Transmission:gTrans
		gTrans = V_getSampleTransmission(pa.popStr)
		NVAR gTransErr = root:Packages:NIST:VSANS:Globals:Transmission:gTransErr
		gTransErr = V_getSampleTransError(pa.popStr)

	return(0)	
	
End

// TODO
//
// Given the group ID of the sample, try to locate a (the) matching transmission file
// by locating a matching ID in the list of transmission (intent) files
//
// then pop the menu
//
//
Function V_TTransmFilePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR gTransLabel = root:Packages:NIST:VSANS:Globals:Transmission:gTransLabel
			gTransLabel = V_getSampleDescription(popStr)
			NVAR gTrnGrpID = root:Packages:NIST:VSANS:Globals:Transmission:gTrnGrpID
			gTrnGrpID = V_getSample_GroupID(popStr)			
			
//			SVAR gSamMatchList = root:Packages:NIST:VSANS:Globals:Transmission:gSamMatchList
//			String quote = "\""
//			gSamMatchList = quote + V_getFileIntentPurposeIDList("SAMPLE","SCATTERING",gTrnGrpID,0) + quote
			// this resets a global string, since I can't pass a parameter (only constants) in value=fn()		
//			PopupMenu popup_0,mode=1,value=#gSamMatchList
			PopupMenu popup_0,mode=1,value=V_getSamListForPopup()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function/S V_getSamListForPopup()

//	String quote = "\""
	NVAR gTrnGrpID = root:Packages:NIST:VSANS:Globals:Transmission:gTrnGrpID

	String retStr = V_getFileIntentPurposeIDList("SAMPLE","SCATTERING",gTrnGrpID,0)

// and be sure to add in the empty cell, since it's not a "sample"
	retStr += V_getFileIntentPurposeIDList("EMPTY CELL","SCATTERING",gTrnGrpID,0)

	// now filter through the string to refine the list to only scattering files that match
	// the transmission file conditions
	String newList="",item
	Variable num,ii
	
	String transStr
	ControlInfo popup_1			//the transmission file popup
	transStr = S_Value
	
	num=ItemsInList(retStr)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, retStr,";")
		if(V_Scatter_Match_Trans(transStr,item))
			newList += item + ";"
		endif
	endfor

	SVAR newSamList = root:Packages:NIST:VSANS:Globals:Transmission:gSamMatchList
	newSamList = newList
	
	return(newList)
End


Function/S V_getTransListForPopup()

	String retStr = V_getFilePurposeList("TRANSMISSION",0)
	
	// now filter through the string to refine the list to only transmission files that match
	// the open beam file conditions
	String newList="",item
	Variable num,ii
	
	String openStr
	ControlInfo popup_2		//the open beam popup
	openStr = S_Value
	
	num=ItemsInList(retStr)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, retStr,";")
		if(V_Trans_Match_Open(openStr,item))
			newList += item + ";"
		endif
	endfor

	SVAR newTransList = root:Packages:NIST:VSANS:Globals:Transmission:gTransMatchList
	newTransList = newList
	
	return(newList)
	
End

Function V_TEmpBeamPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			Print "empty beam match at ",popStr
			SetVariable setvar_4,value=_STR:V_getSampleDescription(popStr)
			

			WAVE boxCoord = V_getBoxCoordinates(popStr)
			Print boxCoord
			SetVariable setvar_5,value=_STR:V_NumWave2List(boxCoord,";")
			
			String detStr = V_getReduction_BoxPanel(popStr)
			SetVariable setvar_6,value =_STR:detStr
			
			PopupMenu popup_1,mode=1,value=V_getTransListForPopup()
			
			SVAR newBox = root:Packages:NIST:VSANS:Globals:Transmission:gEmptyBoxCoord
			newBox = V_NumWave2List(boxCoord,";")
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// NOTE: DIV is not needed for the transmission calculation, since it's a ratio
// and the DIV simply drops out. (DIV is needed for ABS scaling calculation of Kappa, since
// that is not a ratio)
//
// TODO
// -- figure out which detector corrections are necessary to do on loading
// data for calculation. Then set/reset preferences accordingly
// (see V_isoCorrectButtonProc() for example of how to do this)
//
//  -- DIV (turn off)
// -- NonLinear (turn off ?)
// -- solid angle (turn off ?)
// -- dead time (keep on?)
//
// -- once calculated, update the Transmission panel
// -- update the data file
// -- update the CATALOG (and/or delete the RawVSANS to force a re-read)
//
Function V_CalcTransmButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			String SamFile,TransFile,EmptyFile

			ControlInfo/W=V_TransmissionPanel popup_0
			SamFile = S_Value

			ControlInfo/W=V_TransmissionPanel popup_1
			TransFile = S_Value		
		
			ControlInfo/W=V_TransmissionPanel popup_2
			EmptyFile = S_Value
		
			V_CalcOneTransmission(SamFile,TransFile,EmptyFile)			

			
			// done
			break
		case -1: // control being killed
			break
	endswitch


	return 0
End

Function V_CalcTransmListButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			SVAR gSamMatchList = root:Packages:NIST:VSANS:Globals:Transmission:gSamMatchList

			String SamFile,TransFile,EmptyFile

			ControlInfo/W=V_TransmissionPanel popup_1
			TransFile = S_Value		
		
			ControlInfo/W=V_TransmissionPanel popup_2
			EmptyFile = S_Value
		
			String list
			list = gSamMatchList
//			list = list[1,strlen(list)-1]
//			list = list[0,strlen(list)-2]
			
			Variable num,ii
			num = ItemsInList(list, ";")
			for(ii=0;ii<num;ii+=1)
				SamFile = StringFromList(ii, list, ";")
				
				if(ii==0)
					// calculate the transmission for the first file
					V_CalcOneTransmission(SamFile,TransFile,EmptyFile)	
				else
					// then just write in the values (globals) that V_CalcOne determined
					NVAR gTrans = root:Packages:NIST:VSANS:Globals:Transmission:gTrans
					NVAR gTransErr = root:Packages:NIST:VSANS:Globals:Transmission:gTransErr
					
					// write both out to the sample *scattering* file on disk
					V_writeSampleTransmission(SamFile,gTrans)
					V_writeSampleTransError(SamFile,gTransErr)	

				endif		
			endfor
			
			Print "Done Processing Transmission List"

			// done
			break
		case -1: // control being killed
			break
	endswitch


	return 0
End



Function V_CalcOneTransmission(SamFileName,TransFileName,EmptyFileName)			
	String SamFileName,TransFileName,EmptyFileName

		Variable trans,trans_err
		Variable emptyCts,empty_ct_err,samCts,sam_ct_err
		String detStr
		
		
		// save preferences for file loading
		Variable savDivPref,savSAPref
		NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
		savDivPref = gDoDIVCor
		NVAR gDoSolidAngleCor = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
		savSAPref = gDoSolidAngleCor
		
		// set local preferences
		gDoDIVCor = 0
		gDoSolidAngleCor = 0
		
		// check for sample transmission + error
		// if present -- exit
		
		trans = V_getSampleTransmission(samfileName)
		trans_err = V_getSampleTransError(samfileName)
//			// TODO
//			// -- this criteria is rather crude. think it through better
//			// -- or should I simply let it overwrite? What is the harm in that?
//			if(trans != 0 && trans < 1 && trans_err != 0)
//				Printf "Sample transmission, error = %g +/- %g   already exists, nothing calculated\r",trans,trans_err
//				break
//			endif
		
	// for empty beam		
		emptyCts = V_getBoxCounts(emptyFileName)
		empty_ct_err = V_getBoxCountsError(emptyFileName)
		WAVE xyBoxW = V_getBoxCoordinates(emptyFileName)
		// TODO
		// x- need to get the panel string for the sum.
		// x- the detector string is currently hard-wired
		detStr = V_getReduction_BoxPanel(emptyFileName)
		
		SVAR gEmptyPanel = root:Packages:NIST:VSANS:Globals:Transmission:gEmptyPanel
		gEmptyPanel = detStr

		
		// check for box count + error values
		// if present, proceed
		// TODO
		// -- this criteria is rather crude. think it through better
		if(emptyCts > 1 && empty_ct_err != 0)
			Printf "Empty beam box counts, error = %g +/- %g   already exists, box counts not re-calculated\r",emptyCts,empty_ct_err
			
		else
			// else the counts have not been determined
			// read in the data file
			V_LoadAndPlotRAW_wName(emptyFileName)
			// convert raw->SAM
			V_Raw_to_work("SAM")
			V_UpdateDisplayInformation("SAM")	
			
			// and determine box sum and error
			// store these locally
			emptyCts = V_SumCountsInBox(xyBoxW[0],xyBoxW[1],xyBoxW[2],xyBoxW[3],empty_ct_err,"SAM",detStr)
	
			Print "empty counts = ",emptyCts
			Print "empty err/counts = ",empty_ct_err/emptyCts
			
			// TODO
			// write these back to the file
			// (write locally?)
			
		endif

	// for Sample Transmission File
		
		// check for box count + error values
		samCts = V_getBoxCounts(TransFileName)
		sam_ct_err = V_getBoxCountsError(TransFileName)
		// if present, proceed
		// TODO
		// -- this criteria is rather crude. think it through better
		if(samCts > 1 && sam_ct_err != 0)
			Printf "Sam Trans box counts, error = %g +/- %g   already exists, nothing calculated\r",samCts,sam_ct_err
			
		else
			// else
			// read in the data file
			V_LoadAndPlotRAW_wName(TransFileName)
			// convert raw->SAM
			V_Raw_to_work("SAM")
			V_UpdateDisplayInformation("SAM")	
			
			// get the box coordinates
			// and determine box sum and error
			
			// store these locally
			samCts = V_SumCountsInBox(xyBoxW[0],xyBoxW[1],xyBoxW[2],xyBoxW[3],sam_ct_err,"SAM",detStr)
	
			Print "sam counts = ",samCts
			Print "sam err/counts = ",sam_ct_err/samCts
			
			// TODO
			// write these back to the file
			// (write locally?)	
		endif
		
	//then calculate the transmission
		Variable empAttenFactor,emp_atten_err,samAttenFactor,sam_atten_err,attenRatio
		
		// get the attenuation factor for the empty beam
		empAttenFactor = V_getAttenuator_transmission(emptyFileName)
		emp_atten_err = V_getAttenuator_trans_err(emptyFileName)
		// get the attenuation factor for the sample transmission
		samAttenFactor = V_getAttenuator_transmission(TransFileName)
		sam_atten_err = V_getAttenuator_trans_err(TransFileName)	
		AttenRatio = empAttenFactor/samAttenFactor		
		// calculate the transmission
		// calculate the transmission error
		trans = samCts/emptyCts * AttenRatio
					
		// squared, relative error
		if(AttenRatio == 1)
			trans_err = (sam_ct_err/samCts)^2 + (empty_ct_err/emptyCts)^2		//same atten, att_err drops out
		else
			trans_err = (sam_ct_err/samCts)^2 + (empty_ct_err/emptyCts)^2 + (sam_atten_err/samAttenFactor)^2 + (emp_atten_err/empAttenFactor)^2
		endif
		trans_err = sqrt(trans_err)
		trans_err *= trans		// now, one std deviation
		
		//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
		If(attenRatio==1)
			Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\r",SamFileName, samCts,trans,trans_err
		else
			Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\tAttenuatorRatio = %g\r",SamFileName, samCts,trans,trans_err,attenRatio
		endif
		
		// write both out to the sample *scattering* file on disk
		V_writeSampleTransmission(SamFileName,trans)
		V_writeSampleTransError(SamFileName,trans_err)	
		
		// (DONE)
		// x- update the value displayed in the panel 
		// (NO) update the local value in the file catalog
		// x- delete the file from RawVSANS to force a re-read?
		NVAR gTrans = root:Packages:NIST:VSANS:Globals:Transmission:gTrans
		gTrans = trans
		NVAR gTransErr = root:Packages:NIST:VSANS:Globals:Transmission:gTransErr
		gTransErr = trans_err

		V_KillNamedDataFolder(V_RemoveDotExtension(samFileName))

	// restore preferences on exit
	gDoDIVCor = savDivPref
	gDoSolidAngleCor = savSAPref

	return(0)			

End







Function V_WriteTransmButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_HelpTransmButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DoAlert 0,"Transmission Help not written yet"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DoneTransmButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K V_TransmissionPanel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

