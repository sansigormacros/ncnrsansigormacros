#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.
#pragma IgorVersion=6.1

// Version 1.0
// SRK 7 OCT 2009
//

// Adding two raw .bt5 files:
//	- only files with the same angle range and the same number of points can be added.
//	- NO shifting is done - these are raw data files, and the angular shift is not known
//	- it can be repeated multiple times to add more than two files together
//	- the two added files are listed in the title of the summed file.
// -- see AddBT5AndSave() if you want something that cen be automated to bypass the user dialogs.

// Adding two data sets:
//	- here, two entire data sets (inlcluding the main beam) are added together after
//	   loading and normalizing and coverting to Q. The data file is NOT saved out, because
//		it is not a format that can be re-read in for reduction.
//	- to use the summed data set, it is first summed in a separate panel, and then transferred
//		to either the active "SAM" or "EMP" data
//	- since the zero offset can make the point values not exactly the same, only those within a
//		certain tolerance are actually added. Points that cannot be added are still kept in the final
//		data set.
//

// issues
// - are the errors calculated correctly? I think so...
// - if there is a direct 1:1 correspondence of the data points, saving is easy
//   -- if not, then some points will have a different counting time
//   -- this is always the case if I do a "full" data set.
//
// - convert to countrate seems like a good idea, then 1+1=2 and I can propagate errors
//  -- but how to save the data? At this point, errCR != sqrt(CR)
// -> answer is -- don't save the full data sets that have been summed...
//
// - Why can't I just use the whole set of files from the main USANS panel, and add what needs
//   to be added? Because if there is an angle shift, I have no way of knowing which files to apply
//   the shift to...
//
// - do I have anything hard-wired in the code that needs to be generalized before release?
//

// simple stuff to do:
// - allow user to input Qpeak (maybe of no use?) If so, do it right away with a dialog
//   if no peak was found.

Proc ShowUSANSAddPanel()
	DoWindow/F USANS_Add_Panel
	if(V_Flag == 0)
		Init_AddUSANS()
		USANS_Add_Panel()
	endif
EndMacro

// initializes the folders and globals for use with the USANS_Add_Panel
//
// there is some overlap of the controls from the Main_USANS panel
// separate waves are created for the lists in :AddPanel
//
Proc Init_AddUSANS()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:USANS
	NewDataFolder/O root:Packages:NIST:USANS:Globals
	NewDataFolder/O/S root:Packages:NIST:USANS:Globals:AddPanel

	string/G root:Packages:NIST:USANS:Globals:gUSANSFolder = "root:Packages:NIST:USANS"
	string   USANSFolder                                   = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//Preference value to determine if we are outputting XML
	//	Variable/G root:Packages:NIST:USANS:Globals:gUseXMLOutput = 0
	string/G FilterStr
	variable/G gAddUSANSTolerance = 0.01 // add points if x is within 1% (an arbitrary choice!)

	Make/O/T/N=1 fileWave, AWave, BWave
	fileWave = ""
	AWave    = ""
	BWave    = ""

	//	Make/O/T/N=5 statusWave=""
	Make/O/B/U/N=1 selFileW

	SetDataFolder root:

	NewDataFolder/O $(USANSFolder + ":TMP_A")
	NewDataFolder/O $(USANSFolder + ":TMP_B")
	NewDataFolder/O $(USANSFolder + ":SUM_AB")

EndMacro

//draws the USANS_Add_Panel, somewhat similar to the Main panel
//
// but used exclusively for adding files, and is a graph/control bar
//

Proc USANS_Add_Panel()
	PauseUpdate; Silent 1 // building window...
	Display/W=(100, 44, 900, 493)/K=1 as "USANS_Add_Panel"
	DoWindow/C USANS_Add_Panel
	DoWindow/T USANS_Add_Panel, "Add Raw USANS Files"
	ControlBar/L 300

	//	ModifyGraph cbRGB=(36929,50412,31845)
	ModifyGraph cbRGB=(65535, 60076, 49151)

	//	(I don't know where these end up anyhow...)
	//	SetDrawLayer UserBack
	//	SetDrawEnv fstyle= 1
	//	DrawText 12,53,"Data Files"
	//	SetDrawEnv fstyle= 1
	//	DrawText 157,192,"Empty Scans"
	//	SetDrawEnv fstyle= 1
	//	DrawText 154,54,"Sample Scans"
	//	DrawLine 6,337,398,337
	//	DrawLine 5,33,393,33
	//	SetDrawEnv fstyle= 1
	//	DrawText 140,357,"Raw Data Header"
	//	SetDrawEnv fstyle= 1

	ListBox AfileLB, pos={5, 55}, size={110, 230} //,proc=AddFileListBoxProc
	ListBox AfileLB, listWave=root:Packages:NIST:USANS:Globals:AddPanel:fileWave
	ListBox AfileLB, selWave=root:Packages:NIST:USANS:Globals:AddPanel:selFileW, mode=4
	ListBox A_LB, pos={149, 55}, size={110, 90}, listWave=root:Packages:NIST:USANS:Globals:AddPanel:AWave
	ListBox A_LB, mode=1, selRow=-1
	Button Clear_A_Button, pos={227, 148}, size={35, 20}, proc=ClearABButtonProc, title="Clr"
	Button Clear_A_Button, help={"Clears the list of sample scans"}
	Button Clear_B_Button, pos={227, 286}, size={35, 20}, proc=ClearABButtonProc, title="Clr"
	Button Clear_B_Button, help={"Clears the list of empty scans"}
	Button ARefreshButton, pos={9, 310}, size={104, 20}, proc=RefreshListButtonProc, title="Refresh"
	Button ARefreshButton, help={"Refreshes the list of raw ICP data files"}
	Button Del_A_Button, pos={183, 148}, size={35, 20}, proc=DelAButtonProc, title="Del"
	Button Del_A_Button, help={"Deletes the selected file(s) from the list of SET A scans"}
	Button Del_B_Button, pos={183, 286}, size={35, 20}, proc=DelBButtonProc, title="Del"
	Button Del_B_Button, help={"Deletes the selected file(s) from the list of SET B scans"}
	ListBox B_LB, pos={151, 194}, size={110, 90}
	ListBox B_LB, listWave=root:Packages:NIST:USANS:Globals:AddPanel:BWave, mode=1, selRow=0
	Button to_A_List, pos={118, 55}, size={25, 90}, proc=to_A_ListButtonProc, title="A\r->"
	Button to_A_List, help={"Adds the selected file(s) to the list of SET A scans"}
	Button to_B_List, pos={120, 195}, size={25, 90}, proc=to_B_ListButtonProc, title="B\r->"
	Button to_B_List, help={"Adds the selected file(s) to the list of SET B scans"}
	//	ListBox StatusLB,pos={11,358},size={386,77}
	//	ListBox StatusLB,listWave=root:Packages:NIST:USANS:Globals:AddPanel:statusWave
	Button pickPathButton, pos={6, 8}, size={80, 20}, proc=PickBT5PathButton, title="DataPath..."
	Button pickPathButton, help={"Select the data folder where the raw ICP data files are located"}
	Button PlotSelected_A_Button, pos={140, 148}, size={35, 20}, proc=PlotSelected_AB_ButtonProc, title="Plot"
	Button PlotSelected_A_Button, help={"Plot the selected sample scattering files in the COR_Graph"}
	Button PlotSelected_B_Button, pos={140, 286}, size={35, 20}, proc=PlotSelected_AB_ButtonProc, title="Plot"
	Button PlotSelected_B_Button, help={"Plot the selected empty cell scattering files in the COR_Graph"}
	Button pickSavePathButton, pos={97, 8}, size={80, 20}, proc=PickSaveButtonProc, title="SavePath..."
	Button pickSavePathButton, help={"Select the data folder where data is to be saved to disk"}
	Button USANSHelpButton, pos={220, 6}, size={50, 20}, proc=USANSAddFilesHelpButton, title="Help"
	Button USANSHelpButton, help={"Show the USANS reduction help file"}

	SetVariable FilterSetVar, pos={8, 289}, size={106, 18}, title="Filter", fSize=12
	SetVariable FilterSetVar, value=root:Packages:NIST:USANS:Globals:AddPanel:FilterStr

	Button A_AddDone, pos={231, 414}, size={50, 20}, proc=AddUSANSDone, title="Done"
	Button A_AddDone, help={"Closes the panel"}
	Button AddUSANSButton, pos={12, 368}, size={80, 20}, proc=AddUSANSFilesButtonProc, title="Add Files"
	Button AddUSANSButton, help={"Adds the A and B files  together"}
	Button AddUSANSButton, fColor=(16386, 65535, 16385)
	Button ClearSumButton, pos={159, 322}, size={80, 20}, proc=ClearSumButtonProc, title="Clear Sum"
	Button ClearSumButton, help={"Clears the summed data from the graph and clears the data in memory"}
	Button SaveSumButton, pos={13, 405}, size={80, 20}, proc=SaveSumButtonProc, title="Move Sum"
	Button SaveSumButton, help={"Saves the summed data as a fake bt5 file"}
	Button SaveSumButton, fColor=(16385, 28398, 65535)

EndMacro

// Show the help file, don't necessarily keep it with the experiment (/K=1)
Function USANSAddFilesHelpButton(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "Adding Two Data Sets"
	if(V_flag != 0)
		DoAlert 0, "The USANS Data Reduction Help file could not be found"
	endif
	return (0)
End

Function AddUSANSDone(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			DoWindow/K USANS_Add_Panel
			break
		default:
			// no action if the event code doesn't match
			break
	endswitch

	return 0
End

Function AddUSANSFilesButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here

			Add_AB("")

			break
		default:
			// no action if the event code doesn't match
			break
	endswitch

	return 0
End

Function ClearSumButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			RemoveFromGraph/W=USANS_Add_Panel/Z $("DetCts_" + "SUM_AB")
			CleanOutFolder("SUM_AB")

			break
		default:
			// no action if the event code doesn't match
			break
	endswitch

	return 0
End

// really a "move" since I'm not sure about how to poroperly save...
//
Function SaveSumButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			string type = ""
			Prompt type, "Move the sumed data to:", popup, "EMP;SAM;"
			DoPrompt "Move Summed Data", type
			if(V_flag)
				return (0)
			endif

			MoveSummedData(type)

			break
		default:
			// no action if the event code doesn't match
			break
	endswitch

	return 0
End

Function Add_AB(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	// copy waves over to the SUM_AB folder
	string fromType = "TMP_A"
	string toType   = "SUM_AB"
	Duplicate/O $(USANSFolder + ":" + fromType + ":Angle"), $(USANSFolder + ":" + toType + ":Angle_A")
	Duplicate/O $(USANSFolder + ":" + fromType + ":DetCts"), $(USANSFolder + ":" + toType + ":DetCts_A")
	Duplicate/O $(USANSFolder + ":" + fromType + ":MonCts"), $(USANSFolder + ":" + toType + ":MonCts_A")
	Duplicate/O $(USANSFolder + ":" + fromType + ":TransCts"), $(USANSFolder + ":" + toType + ":TransCts_A")
	Duplicate/O $(USANSFolder + ":" + fromType + ":ErrDetCts"), $(USANSFolder + ":" + toType + ":ErrDetCts_A")

	fromType = "TMP_B"
	Duplicate/O $(USANSFolder + ":" + fromType + ":Angle"), $(USANSFolder + ":" + toType + ":Angle_B")
	Duplicate/O $(USANSFolder + ":" + fromType + ":DetCts"), $(USANSFolder + ":" + toType + ":DetCts_B")
	Duplicate/O $(USANSFolder + ":" + fromType + ":MonCts"), $(USANSFolder + ":" + toType + ":MonCts_B")
	Duplicate/O $(USANSFolder + ":" + fromType + ":TransCts"), $(USANSFolder + ":" + toType + ":TransCts_B")
	Duplicate/O $(USANSFolder + ":" + fromType + ":ErrDetCts"), $(USANSFolder + ":" + toType + ":ErrDetCts_B")

	SetDataFolder $(USANSFolder + ":" + toType)
	WAVE Angle_A     = Angle_A
	WAVE DetCts_A    = DetCts_A
	WAVE MonCts_A    = MonCts_A
	WAVE TransCts_A  = TransCts_A
	WAVE ErrDetCts_A = ErrDetCts_A

	WAVE Angle_B     = Angle_B
	WAVE DetCts_B    = DetCts_B
	WAVE MonCts_B    = MonCts_B
	WAVE TransCts_B  = TransCts_B
	WAVE ErrDetCts_B = ErrDetCts_B

	Make/O/D/N=0 Angle, DetCts, MonCts, TransCts, ErrDetCts

	//do something with the wave note on each DetCts wave so it's not lost
	//	String/G note_A = note(DetCts_A)
	//	String/G note_B = note(DetCts_B)

	variable minPt, minDelta
	variable ii, jj, nA, nB
	variable sumPt = 0
	nA = numpnts(Angle_A)
	nB = numpnts(Angle_B)
	Make/O/D/N=(nB) tmp_delta

	NVAR tol = root:Packages:NIST:USANS:Globals:AddPanel:gAddUSANSTolerance //1% error allowed as default

	for(ii = 0; ii < nA; ii += 1)
		Redimension/N=(nB) tmp_delta
		tmp_delta = NaN //initialize every pass
		tmp_delta = abs((Angle_A[ii] - Angle_B) / Angle_B)

		WaveStats/Q tmp_delta
		minPt    = V_minLoc
		minDelta = V_min

		if(minDelta < tol)
			//			Printf "Angle_A %g matches with Angle_B %g with error %g\r",Angle_A[ii],Angle_B[minPt],minDelta
			// add the points to the sum waves
			InsertPoints sumPt, 1, Angle, DetCts, MonCts, TransCts, ErrDetCts
			Angle[sumPt]     = (Angle_A[ii] + Angle_B[minPt]) / 2
			DetCts[sumPt]    = (DetCts_A[ii] + DetCts_B[minPt]) / 2
			MonCts[sumPt]    = (MonCts_A[ii] + MonCts_B[minPt]) / 2
			TransCts[sumPt]  = (TransCts_A[ii] + TransCts_B[minPt]) / 2
			ErrDetCts[sumPt] = sqrt(ErrDetCts_A[ii]^2 + ErrDetCts_B[minPt]^2) / 2

			sumPt += 1
			// remove the point from B (all of them)
			DeletePoints minPt, 1, Angle_B, DetCts_B, MonCts_B, TransCts_B, ErrDetCts_B
			nB -= 1
			//
		else
			//Printf "NoMatch for Angle_A %g  with error %g\r",Angle_A[ii],minDelta
			// just copy it over
			InsertPoints sumPt, 1, Angle, DetCts, MonCts, TransCts, ErrDetCts
			Angle[sumPt]     = Angle_A[ii]
			DetCts[sumPt]    = DetCts_A[ii]
			MonCts[sumPt]    = MonCts_A[ii]
			TransCts[sumPt]  = TransCts_A[ii]
			ErrDetCts[sumPt] = ErrDetCts_A[ii]

			sumPt += 1
		endif

	endfor

	// bring in all of the unmatched "B" values, including the error
	Concatenate {Angle_B}, Angle
	Concatenate {DetCts_B}, DetCts
	Concatenate {MonCts_B}, MonCts
	Concatenate {TransCts_B}, TransCts
	Concatenate {ErrDetCts_B}, ErrDetCts

	// then sort everything by angle
	Sort Angle, Angle, DetCts, MonCts, TransCts, ErrDetCts

	// update the wave note on detCts? it is zeroed now, for one
	string aNote = ""
	string bNote = ""
	string afile = ""
	string bFile = ""
	string str   = ""
	aNote = note(DetCts_A)
	aNote = ReplaceNumberByKey("PEAKANG", aNote, 0, ":", ";") //set the angle to zero in the summed set
	//adjust the A wavenote, to account for the new dataset
	bNote = note(DetCts_B)
	bFile = StringByKey("FILE", bNote, ":", ";")

	aFile  = StringByKey("FILE", aNote, ":", ";")
	aFile += "," + bfile
	aNote  = ReplaceStringByKey("FILE", aNote, aFile, ":", ";")

	Note/K DetCts
	Note DetCts, aNote

	SetDataFolder root:

	//copy the data to plot to the root:Graph directory, and give clear names
	string type = "SUM_AB"
	if(WaveExists($(USANSFolder + ":" + type + ":Qvals")))
		Duplicate/O $(USANSFolder + ":" + type + ":Qvals"), $(USANSFolder + ":Graph:Qvals_" + type)
	endif
	Duplicate/O $(USANSFolder + ":" + type + ":Angle"), $(USANSFolder + ":Graph:Angle_" + type)
	Duplicate/O $(USANSFolder + ":" + type + ":DetCts"), $(USANSFolder + ":Graph:DetCts_" + type)
	Duplicate/O $(USANSFolder + ":" + type + ":ErrDetCts"), $(USANSFolder + ":Graph:ErrDetCts_" + type)

	Do_AB_Graph("SUM_AB")
	return (0)
End

// plots the selected A or B files onto the USANS_Add_Panel
// Does the following:
// - loads raw data
// ?? normalizes counts to time and 1E6 monitor counts
// - sorts by angle
// - finds zero angle (and peak height)
// X converts to q-values
// X finds T wide
// - updates the graph
//
Function PlotSelected_AB_ButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	string type = ""
	if(cmpstr(ctrlName, "PlotSelected_A_Button") == 0)
		type = "TMP_A"
		WAVE/T listW = $(USANSFolder + ":Globals:AddPanel:AWave")
	else
		type = "TMP_B"
		WAVE/T listW = $(USANSFolder + ":Globals:AddPanel:BWave")
	endif

	//get selected files from listbox (everything)
	//use the listBox wave directly

	//Wave for indication of current data set AJJ Sept 2006
	//	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")
	variable ii
	variable num        = numpnts(listW)
	string   fname      = ""
	string   fpath      = ""
	string   curPathStr = ""
	PathInfo bt5PathName
	fpath = S_Path
	PathInfo bt5CurPathName
	curPathStr = S_Path

	//	print fpath

	if(cmpstr("", listW[0]) == 0)
		return (0) //null item in 1st position, exit
	endif

	//load, normalize, and append
	//loop over the number of items in the list
	for(ii = 0; ii < num; ii += 1)
		fname = fpath + listw[ii]

		LoadBT5File(fname, "SWAP") //overwrite what's in the SWAP folder
		//		Convert2Countrate("SWAP",0)		//convert to cts/s, don't normalize to default Mon
		Convert2Countrate("SWAP", 1) //convert to cts/s, yes, normalize to default Mon
		if(ii == 0) //first time, overwrite
			NewDataWaves("SWAP", type)
		else //append to waves in "SAM"
			AppendDataWaves("SWAP", type)
		endif
	endfor
	//sort after all loaded
	DoAngleSort(type)

	//find the peak and convert to Q-values
	variable zeroAngle = FindZeroAngle(type)
	if(zeroAngle == -9999)
		DoAlert 0, "Couldn't find a peak - using zero as zero angle"
		zeroAngle = 0
	endif

	//	ConvertAngle2Qvals(type,zeroAngle)
	WAVE angle = $(USANSFolder + ":" + type + ":Angle")
	Angle = angle[p] - zeroAngle

	//
	//copy the data to plot to the root:Graph directory, and give clear names
	if(WaveExists($(USANSFolder + ":" + type + ":Qvals")))
		Duplicate/O $(USANSFolder + ":" + type + ":Qvals"), $(USANSFolder + ":Graph:Qvals_" + type)
	endif
	Duplicate/O $(USANSFolder + ":" + type + ":Angle"), $(USANSFolder + ":Graph:Angle_" + type)
	Duplicate/O $(USANSFolder + ":" + type + ":DetCts"), $(USANSFolder + ":Graph:DetCts_" + type)
	Duplicate/O $(USANSFolder + ":" + type + ":ErrDetCts"), $(USANSFolder + ":Graph:ErrDetCts_" + type)

	//now plot the data (or just bring the graph to the front)
	Do_AB_Graph(type)
End

// add SAM data to the graph if it exists and is not already on the graph
//
Function Do_AB_Graph(string type)

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//is it already on the graph?
	SetDataFolder $(USANSFolder + ":Graph")
	
	// not all of these waves may exist
	WAVE/Z DetCts_TMP_A = DetCts_TMP_A
	WAVE/Z Angle_TMP_A = Angle_TMP_A
	WAVE/Z ErrDetCts_TMP_A = ErrDetCts_TMP_A
	
	WAVE/Z DetCts_TMP_B = DetCts_TMP_B
	WAVE/Z Angle_TMP_B = Angle_TMP_B
	WAVE/Z ErrDetCts_TMP_B = ErrDetCts_TMP_B

	WAVE/Z DetCts_SUM_AB = DetCts_SUM_AB
	WAVE/Z Angle_SUM_AB = Angle_SUM_AB
	WAVE/Z ErrDetCts_SUM_AB = ErrDetCts_SUM_AB
			
	string list = ""
	list = Wavelist("DetCts_" + type + "*", ";", "WIN:USANS_Add_Panel")
	if(strlen(list) != 0)
		//Print "SAM already on graph"
		SetDataFolder root:
		return (0)
	endif

	//check for the three possibilities
	if(cmpstr(type, "TMP_A") == 0)
		//append the data if it exists
		if(waveExists($"DetCts_TMP_A") == 1)
			//			DoWindow/F USANS_Add_Panel
			AppendToGraph DetCts_TMP_A vs Angle_TMP_A
			ModifyGraph rgb(DetCts_TMP_A)=(1, 12815, 52428)
			ModifyGraph mode(DetCts_TMP_A)=3, marker(DetCts_TMP_A)=19, msize(DetCts_TMP_A)=2
			ModifyGraph tickUnit=1, log=1, mirror=2, grid=1
			ErrorBars/T=0 DetCts_TMP_A, Y, wave=(ErrDetCts_TMP_A, ErrDetCts_TMP_A)
		endif
	endif

	if(cmpstr(type, "TMP_B") == 0)
		//append the data if it exists
		if(waveExists($"DetCts_TMP_B") == 1)
			//			DoWindow/F USANS_Add_Panel
			AppendToGraph DetCts_TMP_B vs Angle_TMP_B
			ModifyGraph rgb(DetCts_TMP_B)=(1, 39321, 19939)
			ModifyGraph mode(DetCts_TMP_B)=3, marker(DetCts_TMP_B)=19, msize(DetCts_TMP_B)=2
			ModifyGraph tickUnit=1, log=1, mirror=2, grid=1
			ErrorBars/T=0 DetCts_TMP_B, Y, wave=(ErrDetCts_TMP_B, ErrDetCts_TMP_B)
		endif
	endif

	if(cmpstr(type, "SUM_AB") == 0)
		//append the data if it exists
		if(waveExists($"DetCts_SUM_AB") == 1)
			//			DoWindow/F USANS_Add_Panel
			AppendToGraph DetCts_SUM_AB vs Angle_SUM_AB
			ModifyGraph rgb(DetCts_SUM_AB)=(65535, 0, 0)
			ModifyGraph mode(DetCts_SUM_AB)=3, marker(DetCts_SUM_AB)=19, msize(DetCts_SUM_AB)=2
			ModifyGraph tickUnit=1, log=1, mirror=2, grid=1
			ErrorBars/T=0 DetCts_SUM_AB, Y, wave=(ErrDetCts_SUM_AB, ErrDetCts_SUM_AB)
		endif
	endif

	if(strlen(list) == 0)
		//drawing a new graph
		Legend
		Label left, "(Counts/sec)/(MON)*10\\S6\\M"
		Label bottom, "Angle (deg)"
	endif

	SetDataFolder root:
End

// copies the selected files from the raw file list box to the sam file listbox
//
// makes sure that any null items are removed from the wave attached to the listbox
//
Function to_A_ListButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//Print "toSamList button"
	WAVE/T fileWave = $(USANSFolder + ":Globals:AddPanel:fileWave")
	WAVE/T AWave    = $(USANSFolder + ":Globals:AddPanel:AWave")
	WAVE   sel      = $(USANSFolder + ":Globals:AddPanel:selFileW")
	//Wave to indicate Current status
	//	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")

	variable num    = numpnts(sel)
	variable ii     = 0
	variable lastPt = numpnts(AWave)
	do
		if(sel[ii] == 1)
			InsertPoints lastPt, 1, AWave
			AWave[lastPt] = filewave[ii]
			//			InsertPoints lastPt, 1, isCurrent
			//			isCurrent[lastPt] = 0
			lastPt += 1
		endif
		ii += 1
	while(ii < num)

	//clean out any (null) elements
	num = numpnts(AWave)
	for(ii = 0; ii < num; ii += 1)
		if(cmpstr(AWave[ii], "") == 0)
			DeletePoints ii, 1, AWave
			//			DeletePoints ii,1,isCurrent
			num -= 1
		endif
	endfor

	return (0)
End

// copies the selected files from the raw file list box to the sam file listbox
//
// makes sure that any null items are removed from the wave attached to the listbox
//
Function to_B_ListButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//Print "toEmptyList button"
	WAVE/T fileWave = $(USANSFolder + ":Globals:AddPanel:fileWave")
	WAVE/T BWave    = $(USANSFolder + ":Globals:AddPanel:BWave")
	WAVE   sel      = $(USANSFolder + ":Globals:AddPanel:selFileW")
	//Wave to indicate Current status
	//	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")

	variable num    = numpnts(sel)
	variable ii     = 0
	variable lastPt = numpnts(BWave)
	do
		if(sel[ii] == 1)
			InsertPoints lastPt, 1, BWave
			BWave[lastPt] = filewave[ii]
			//			InsertPoints lastPt, 1, isCurrent
			//			isCurrent[lastPt] = 0
			lastPt += 1
		endif
		ii += 1
	while(ii < num)

	//clean out any (null) elements
	num = numpnts(BWave)
	for(ii = 0; ii < num; ii += 1)
		if(cmpstr(BWave[ii], "") == 0)
			DeletePoints ii, 1, BWave
			//			DeletePoints ii,1,isCurrent
			num -= 1
		endif
	endfor

	return (0)
End

//deletes the selected file from the A list
// multiple selections are not allowed
// the cor_graph is not updated
//
Function DelAButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	ControlInfo A_LB
	variable selRow = V_Value
	WAVE     lw     = $(S_DataFolder + S_Value)
	DeletePoints selRow, 1, lw
	//Clear out current flag AJJ Sept O6
	//	Wave isCurrent = $(USANSFolder+":Globals:AddPanel:SAMisCurrent")
	//	DeletePoints selRow, 1, isCurrent
End

//deletes the selected file from the B list
// multiple selections are not allowed
// the cor_graph is not updated
//
Function DelBButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	ControlInfo B_LB
	variable selRow = V_Value
	WAVE     lw     = $(S_DataFolder + S_Value)
	DeletePoints selRow, 1, lw
	//Clear out current flag AJJ Sept O6
	//	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")
	//	DeletePoints selRow, 1, isCurrent
End

//clears either the A or B scan Lists...
//Also clears the data folders and the COR_Graph
//
Function ClearABButtonProc(string ctrlName) : ButtonControl

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder + ":Globals:AddPanel")
	strswitch(ctrlName)
		case "Clear_A_Button":
			Make/O/T/N=1 AWave
			AWave = ""

			//clear the graph, then the data folders as well
			RemoveFromGraph/W=USANS_Add_Panel/Z $("DetCts_" + "TMP_A")
			CleanOutFolder("TMP_A")
			RemoveFromGraph/W=USANS_Add_Panel/Z $("DetCts_" + "SUM_AB")
			CleanOutFolder("SUM_AB")
			break
		case "Clear_B_Button":
			Make/O/T/N=1 BWave
			BWave = ""

			//clear the graph, then the data folders as well
			//			CleanOutGraph("TMP_B")
			RemoveFromGraph/W=USANS_Add_Panel/Z $("DetCts_" + "TMP_B")
			CleanOutFolder("TMP_B")
			//			CleanOutGraph("SUM_AB")
			RemoveFromGraph/W=USANS_Add_Panel/Z $("DetCts_" + "SUM_AB")
			CleanOutFolder("SUM_AB")
			break
		default:
			// no action if the button name doesn't match
			break
	endswitch

	SetDataFolder root:
End

//move the summed data to one of the other data types for reduction
//
// type is either SAM or EMP
//
// -- still need to move stuff to the EMP folder??
//
Function MoveSummedData(string type)

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	variable zeroAngle = 0 //summed data is already converted to zero angle
	ConvertAngle2Qvals("SUM_AB", zeroAngle)

	//find the Trans Cts for T_Wide
	FindTWideCts("SUM_AB")

	if(cmpstr(type, "EMP") == 0)
		//copy the data to plot to the root:Graph directory, and give clear names
		if(WaveExists($(USANSFolder + ":SUM_AB:Qvals")))
			Duplicate/O $(USANSFolder + ":SUM_AB:Qvals"), $(USANSFolder + ":Graph:Qvals_EMP")
		endif
		Duplicate/O $(USANSFolder + ":SUM_AB:Angle"), $(USANSFolder + ":Graph:Angle_EMP")
		Duplicate/O $(USANSFolder + ":SUM_AB:DetCts"), $(USANSFolder + ":Graph:DetCts_EMP")
		Duplicate/O $(USANSFolder + ":SUM_AB:ErrDetCts"), $(USANSFolder + ":Graph:ErrDetCts_EMP")

		// then copy everything to the EMP folder, for later processing steps
		NewDataWaves("SUM_AB", "EMP")

	endif

	if(cmpstr(type, "SAM") == 0)
		//copy the data to plot to the root:Graph directory, and give clear names
		if(WaveExists($(USANSFolder + ":SUM_AB:Qvals")))
			Duplicate/O $(USANSFolder + ":SUM_AB:Qvals"), $(USANSFolder + ":Graph:Qvals_SAM")
		endif
		Duplicate/O $(USANSFolder + ":SUM_AB:Angle"), $(USANSFolder + ":Graph:Angle_SAM")
		Duplicate/O $(USANSFolder + ":SUM_AB:DetCts"), $(USANSFolder + ":Graph:DetCts_SAM")
		Duplicate/O $(USANSFolder + ":SUM_AB:ErrDetCts"), $(USANSFolder + ":Graph:ErrDetCts_SAM")

		// then copy everything to the SAM folder, for later processing steps
		NewDataWaves("SUM_AB", "SAM")

	endif

	//now plot the data (or just bring the graph to the front)
	DoCORGraph()
	return (0)
End

/////////////////////////////////
//
//
// simple add procedures, if raw files are the same, and there's nothing to shift
//
//

Proc SelectFilesToAdd(file1, file2)
	string file1, file2
	Prompt file1, "First File", popup, BT5FileList("")
	Prompt file2, "Second File", popup, BT5FileList("")

	//	Print file1,file2

	LoadAndAddUSANS(file1, file2)

	string filen = file1[0, strlen(file1) - 5] + "_SUM" + ".BT5"

	GetAddedFileName(filen)
EndMacro

Proc GetAddedFileName(newName)
	string newName
	Prompt newName, "Enter new FileName"

	SaveAddedBT5Files(newName, 1) // 1 asks to confirm the name w/ a dialog
EndMacro

// this procedure will add two and name without any dialogs. Pass it the three names
// if the save name is null, you'll get a dialog
Proc AddBT5AndSave(file1, file2, filen)
	string file1, file2
	string filen = "TMP.BT5"
	Prompt file1, "First File", popup, BT5FileList("")
	Prompt file2, "Second File", popup, BT5FileList("")
	Prompt filen, "output file name"

	LoadAndAddUSANS(file1, file2)

	//	String filen = file1[0,strlen(file1)-5]+"_SUM"+".BT5"

	PathInfo savePathName
	filen = S_Path + filen
	SaveAddedBT5Files(filen, 0) //0==no dialog

EndMacro

Function/S BT5FileList(string filter)

	SVAR ext = root:Packages:NIST:USANS:Globals:MainPanel:gUExt
	filter = "*" + ext + "*"

	//get all the files, then trim the list
	string list    = IndexedFile(bt5PathName, -1, "????")
	string newList = ""
	string item    = ""
	variable ii
	variable num = ItemsInList(list, ";")
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, list, ";")

		if(stringmatch(item, filter)) //ONLY keep files that match the filter + *.bt5 AJJ Sept 06
			newlist += item + ";"
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList, ";", 0) //get them in order
	num     = ItemsInList(newlist, ";")

	return (newList)
End

// main add procedure, farms out as needed
//
Function LoadAndAddUSANS(string file1, string file2)

	SVAR ext = root:Packages:NIST:USANS:Globals:MainPanel:gUExt

	//load each file into a textWave
	Make/O/T/N=200 tw1, tw2

	string fname    = ""
	string fpath    = ""
	string fullPath = ""
	variable ctTime1, ang11, ang21
	variable ctTime2, ang12, ang22
	variable dialog = 1

	PathInfo/S savePathName
	fpath = S_Path

	if(strlen(S_Path) == 0)
		DoAlert 0, "You must select a Save Path... from the main USANS_Panel"
		return (0)
	endif

	fname = fpath + file1
	LoadBT5_toWave(file1, fpath, tw1, ctTime1, ang11, ang21) //redimensions tw1
	Print "File 1: time, angle1, angle2", ctTime1, ang11, ang21

	fname = fpath + file2
	LoadBT5_toWave(file2, fpath, tw2, ctTime2, ang12, ang22) //redimensions tw2
	Print "File 2: time, angle1, angle2", ctTime2, ang12, ang22

	// check if OK to add
	// # lines loaded
	// #pts1 = #pts2
	// angle range 1 = angle range 2
	if(numpnts(tw1) != numpnts(tw2))
		DoAlert 0, "Files are not the same length and can't be directly added"
		//Killwaves/Z tw1,tw2,tw3
		abort
		return (0)
	endif
	if(ang11 != ang12)
		DoAlert 0, "Files don't start at the same angle and can't be directly added"
		//Killwaves/Z tw1,tw2,tw3
		abort
		return (0)
	endif
	if(ang21 != ang22)
		DoAlert 0, "Files don't end at the same angle and can't be directly added"
		//Killwaves/Z tw1,tw2,tw3
		abort
		return (0)
	endif

	//if OK, parse line-by-line into third textWave
	// add / update as necessary
	Print "OK to add"

	variable v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16
	variable a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16
	variable ii, valuesRead, countTime, num, refnum
	string s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
	string filen     = ""
	string fileLabel = ""
	string buffer    = ""
	string str       = ""
	string term      = "\r\n"

	Duplicate/O/T tw2, tw3
	tw3 = ""

	//line 0, info to update
	buffer = tw1[0]
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s", s1, s2, s3, s4, s5, s6, v1, v2, s7, v3, s8
	sprintf str, "%s %s 'I'        %d    1  'TIME'   %d  'SUM'", s1, s2 + " " + s3 + " " + s4 + " " + s5, ctTime1 + ctTime2, v3
	//	num=v3
	tw3[0] = str + term
	tw3[1] = tw1[1] //labels, direct copy

	//line 2, sample label
	buffer = tw1[2]
	sscanf buffer, "%s", s1
	tw3[2]     = s1 + " = " + file1 + " + " + file2 + term
	tw3[3, 12] = tw1[p] //unused values, direct copy

	num = numpnts(tw1) //
	//parse two lines at a time per data point,starting at 13
	for(ii = 13; ii < (num - 1); ii += 2)
		buffer = tw1[ii]
		sscanf buffer, "%g%g%g%g%g", v1, v2, v3, v4, v5 // 5 values here now

		buffer = tw2[ii]
		sscanf buffer, "%g%g%g%g%g", a1, a2, a3, a4, a5 // 5 values here now

		if(a1 != v1)
			DoAlert 0, "Angles don't match and can't be directly added"
			//Killwaves/Z tw1,tw2,tw3
			abort
			return (0)
		endif

		sprintf str, "     %g   %g   %g   %g   %g", v1, v2 + a2, v3 + a3, v4 + a4, v5 + a5
		tw3[ii] = str + term

		buffer = tw1[ii + 1]
		sscanf buffer, "%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g", v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16

		buffer = tw2[ii + 1]
		sscanf buffer, "%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g", a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16

		sprintf str, "%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g", a1 + v1, a2 + v2, a3 + v3, a4 + v4, a5 + v5, a6 + v6, a7 + v7, a8 + v8, a9 + v9, a10 + v10, a11 + v11, a12 + v12, a13 + v13, a14 + v14, a15 + v15, a16 + v16
		tw3[ii + 1] = str + term

	endfor

	//	// write out the final file (=tw3)
	//	filen = file1[0,strlen(file1)-5]+"_SUM"+ext
	//
	//	if(dialog)
	//		PathInfo/S savePathName
	//		fullPath = DoSaveFileDialog("Save data as",fname=filen)
	//		If(cmpstr(fullPath,"")==0)
	//			//user cancel, don't write out a file
	//			Close/A
	//			Abort "no data file was written"
	//		Endif
	//		//Print "dialog fullpath = ",fullpath
	//	Endif
	//
	//	Open refNum as fullPath
	//	wfprintf refnum, "%s",tw3
	//	Close refnum
	//
	//	//killwaves/Z tw1,tw2,tw3

	return (0)
End

// if you bypass the dialog, newname needs to be a full path
Function SaveAddedBT5Files(string newName, variable dialog)

	variable refnum
	string   fullPath

	WAVE/T tw3 = tw3

	if(dialog)
		PathInfo/S savePathName
		fullPath = DoSaveFileDialog("Save data as", fname = newName)
		if(cmpstr(fullPath, "") == 0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		endif
		newName = FullPath
		//Print "dialog fullpath = ",fullpath
	endif

	Open refNum as newName
	wfprintf refnum, "%s", tw3
	Close refnum

	return (0)
End

//returns count time and start/stop angles as written in header
// number of lines in the file is a separate check
//
Function LoadBT5_toWave(string fname, string fpath, WAVE/T tw, variable &ctTime, variable &a1, variable &a2)

	variable firstchar, refnum
	variable numLinesLoaded = 0
	string   buffer         = ""
	variable v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, ii, valuesRead
	string s1, s2, s3, s4, s5, s6, s7, s8, s9, s10

	Open/R/P=bt5PathName refNum as fname

	//read the data until EOF - assuming always a pair or lines
	do
		FReadLine refNum, buffer
		if(strlen(buffer) == 0)
			break // End of file
		endif
		firstChar = char2num(buffer[0])
		if((firstChar == 10) || (firstChar == 13))
			break // Hit blank line. End of data in the file.
		endif

		tw[numLinesLoaded] = buffer

		numlinesloaded += 1
	while(1)

	Close refNum // Close the file.

	//trim the waves to the correct number of points
	Redimension/N=(numlinesloaded) tw

	buffer = tw[0]
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s", s1, s2, s3, s4, s5, s6, v1, v2, s7, v3, s8
	//v2 is the monitor prefactor. multiply monitor time by prefactor. AJJ 5 March 07
	ctTime = v1 * v2

	buffer = tw[6]
	sscanf buffer, "%g%g%g%g", v1, v2, v3, v4
	a1 = v2
	a2 = v4

	return (0)
End
///////////////////////////////////
