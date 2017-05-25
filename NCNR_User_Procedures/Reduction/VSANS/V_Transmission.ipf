#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



// TODO
//-- initialization
// x- link to main panel
//
// ?? redesign the panel based on the CATALOG?
// -- refresh the catalog, then work with those waves?
// 

// TODO
// -- currently, the initialization does nothing.
Function V_InitTransmissionPanel()

	Execute "V_TransmissionPanel()"
	
End


Window V_TransmissionPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1286,328,1764,952)
	ModifyPanel cbRGB=(32896,16448,0,19621)
	DoWindow/C V_TransmissionPanel

//	ShowTools/A
	PopupMenu popup_0,pos={19.00,55.00},size={86.00,23.00},proc=V_TSamFilePopMenuProc,title="Sample"
	PopupMenu popup_0,mode=1,value= V_getFileIntentList("SAMPLE",0)+V_getFileIntentList("EMPTY CELL",0)
	PopupMenu popup_1,pos={102,248},size={72.00,23.00},proc=V_TTransmFilePopMenuProc,title="Transmission"
	PopupMenu popup_1,mode=1,value= V_getFileIntentList("TRANSMISSION",0)
	PopupMenu popup_2,pos={164,353},size={72.00,23.00},proc=V_TEmpBeamPopMenuProc,title="Empty Beam"
	PopupMenu popup_2,mode=1,value= V_getFileIntentList("EMPTY BEAM",0)
	Button button_0,pos={37,193},size={100.00,20.00},proc=V_CalcTransmButtonProc,title="Calculate"
//	Button button_1,pos={23.00,491.00},size={100.00,20.00},proc=V_WriteTransmButtonProc,title="Write"
	Button button_2,pos={349.00,13.00},size={30.00,20.00},proc=V_HelpTransmButtonProc,title="?"
	Button button_3,pos={410.00,13.00},size={50.00,20.00},proc=V_DoneTransmButtonProc,title="Done"
	SetVariable setvar_0,pos={21.00,86.00},size={300.00,14.00},title="Label:"
	SetVariable setvar_0,limits={-inf,inf,0},value= _STR:"file label"
	SetVariable setvar_1,pos={21.00,113.00},size={300.00,14.00},title="Group ID:"
	SetVariable setvar_1,limits={-inf,inf,0},value= VSANS_RED_VERSION
	SetVariable setvar_2,pos={105,276.00},size={300.00,14.00},title="Label:"
	SetVariable setvar_2,limits={-inf,inf,0},value= _STR:"file label"
	SetVariable setvar_3,pos={104,302},size={300.00,14.00},title="Group ID:"
	SetVariable setvar_3,limits={-inf,inf,0},value= VSANS_RED_VERSION
	SetVariable setvar_4,pos={165,382},size={300.00,14.00},title="Label:"
	SetVariable setvar_4,limits={-inf,inf,0},value= _STR:"file label"
	SetVariable setvar_5,pos={165,406},size={300.00,14.00},title="XY Box:"
	SetVariable setvar_5,limits={-inf,inf,0},value= _STR:"dummy"
	SetVariable setvar_6,pos={165,431},size={300.00,14.00},title="Panel:"
	SetVariable setvar_6,limits={-inf,inf,0},value= _STR:"dummy"
	SetVariable setvar_7,pos={21,138},size={300.00,14.00},title="Transmission:"
	SetVariable setvar_7,limits={-inf,inf,0},value= VSANS_RED_VERSION
	SetVariable setvar_8,pos={21,163},size={300.00,14.00},title="Error:"
	SetVariable setvar_8,limits={-inf,inf,0},value= VSANS_RED_VERSION
EndMacro

// TODO -- fill in the details
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

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			Variable ii,np
			
			WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
			WAVE/T labelW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels
			WAVE groupIDW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID
			WAVE transmW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission
			
			// TODO
			// I don't have a wave for the transmission error value, so it's not displayed here
			// -- do I read it in, or just ignore it...	
			np = numpnts(labelW)		//fileNameW is LONGER - so don't use numpnts(fileWave)
			for(ii=0;ii<np;ii+=1)
				if(cmpstr(fileNameW[ii],popStr)==0)
				
					SetVariable setvar_0,value=labelW[ii]
					SetVariable setvar_1,value=groupIDW[ii]
					SetVariable setvar_7,value=transmW[ii]
					break		//found, get out
				endif		
			endfor
		
		// loop back through to find the transmission file with the matching group id
		// TODO x- set the popup string to the matching name on exit
			Variable targetID = groupIDW[ii]
			String list = V_getFileIntentList("TRANSMISSION",0)
			WAVE/T intentW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent
			for(ii=0;ii<np;ii+=1)
				if(cmpstr(intentW[ii],"TRANSMISSION")==0 && groupIDW[ii] == targetID)
					Print "transmission file match at ",filenameW[ii]
					SetVariable setvar_2,value=labelW[ii]
					SetVariable setvar_3,value=groupIDW[ii]
					PopupMenu popup_1,mode=WhichListItem(fileNameW[ii], list )+1
					break
				endif		
			endfor

		// now loop back through to find the empty beam file
		// TODO 
		// x- fill in the XY box
		// --  Detector Panel field is hard-wired for "B"
		//	
			WAVE/T intentW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent
			list = V_getFileIntentList("EMPTY BEAM",0)
			
			for(ii=0;ii<np;ii+=1)
				if(cmpstr(intentW[ii],"EMPTY BEAM")==0)
					Print "empty beam match at ",filenameW[ii]
					SetVariable setvar_4,value=labelW[ii]
					PopupMenu popup_2,mode=WhichListItem(fileNameW[ii], list )+1
					
					SetVariable setvar_6,value =_STR:"B"

					WAVE boxCoord = V_getBoxCoordinates(filenameW[ii])
					Print boxCoord
					SetVariable setvar_5,value=_STR:V_NumWave2List(boxCoord,";")

					
					break
				endif		
			endfor
								
			break
		case -1: // control being killed
			break
	endswitch

	return 0
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
			
			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_TEmpBeamPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
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
			
			Variable trans,trans_err
			Variable emptyCts,empty_ct_err,samCts,sam_ct_err
			String fileName,samFileName,emptyFileName
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
			ControlInfo/W=V_TransmissionPanel popup_0
			fileName = S_Value
			trans = V_getSampleTransmission(fileName)
			trans_err = V_getSampleTransError(fileName)
//			// TODO
//			// -- this criteria is rather crude. think it through better
//			// -- or should I simply let it overwrite? What is the harm in that?
//			if(trans != 0 && trans < 1 && trans_err != 0)
//				Printf "Sample transmission, error = %g +/- %g   already exists, nothing calculated\r",trans,trans_err
//				break
//			endif
			
		// for empty beam

			ControlInfo/W=V_TransmissionPanel popup_2
			emptyFileName = S_Value			
			
			emptyCts = V_getBoxCounts(emptyFileName)
			empty_ct_err = V_getBoxCountsError(emptyFileName)
			WAVE xyBoxW = V_getBoxCoordinates(emptyFileName)
			// TODO
			// -- need to get the panel string for the sum.
			// -- the detector string is currently hard-wired
			detStr = "B"
			
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
			
			ControlInfo/W=V_TransmissionPanel popup_1
			samFileName = S_Value
			// check for box count + error values
			samCts = V_getBoxCounts(samFileName)
			sam_ct_err = V_getBoxCountsError(samFileName)
			// if present, proceed
			// TODO
			// -- this criteria is rather crude. think it through better
			if(samCts > 1 && sam_ct_err != 0)
				Printf "Sam Trans box counts, error = %g +/- %g   already exists, nothing calculated\r",samCts,sam_ct_err
				
			else
				// else
				// read in the data file
				V_LoadAndPlotRAW_wName(samFileName)
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
			samAttenFactor = V_getAttenuator_transmission(samFileName)
			sam_atten_err = V_getAttenuator_trans_err(samFileName)	
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
				Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\r",fileName, samCts,trans,trans_err
			else
				Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\tAttenuatorRatio = %g\r",fileName, samCts,trans,trans_err,attenRatio
			endif
			
			// write both out to the sample *scattering* file on disk
			V_writeSampleTransmission(fileName,trans)
			V_writeSampleTransError(fileName,trans_err)	
			
			// TODO
			// -- update the value displayed in the panel 
			// -- update the local value in the file catalog
			// -- delete the file from RawVSANS to force a re-read?
//			SetVariable setvar_7,value= trans
//			SetVariable setvar_8,value= trans_err
//			DoUpdate/W=V_TransmissionPanel
			
			
			// done
			break
		case -1: // control being killed
			break
	endswitch

	// restore preferences on exit
	gDoDIVCor = savDivPref
	gDoSolidAngleCor = savSAPref


	return 0
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

