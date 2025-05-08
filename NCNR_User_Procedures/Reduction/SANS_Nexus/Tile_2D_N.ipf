#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma version=5.0
#pragma IgorVersion=6.1

//***************************
// Vers 1.2 100901
//
//***************************

//Procedures to create a layout of 2D raw data files selected from a list.
//2D data files are log or linear scale, selected on the panel. The min/max range of the Z-scale (counts)
// can be fixed so that all images are on a directly comparable scale.
//New or existing layouts can be used.
//Graphics are repeatedly read in to the "RAW" folder, then saved to the Clipboard
//as PNG files (note that the Demo version of IGOR can't do this operation) to be
//appended to the seelcted layout. Graphics are sequentially named with the suffix "L_PNG"
//created layouts are killed along with the graphics files in memory when the panel is killed
//********************
// Also contains procedures for a simple panel for 2d export of data files (especially raw data)
//
//

// initializes data folder and waves needed for the panel (contains a listbox)
Proc Init_Tile()
	//create the data folder
	NewDataFolder/O/S root:myGlobals:Tile_2D
	//create the waves
	Make/O/T/N=1 fileWave = ""
	Make/O/N=1 selWave = 0
	variable/G ind      = 0
	variable/G minScale = 0
	variable/G maxScale = 100
	SetDataFolder root:
EndMacro

// main procedure to call to bring up the panel
// re-initializes necessary folders and waves
Proc Show_Tile_2D_Panel()
	DoWindow/F Tile_2D
	if(V_Flag == 0)
		Init_Tile()
		Tile_2D()
	endif
EndMacro

//procedure to draw the "tile" panel
Proc Tile_2D()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(849, 337, 1248, 573)/K=2
	DoWindow/C Tile_2D

	ListBox fileList, pos={5, 4}, size={206, 226}
	ListBox fileList, listWave=root:myGlobals:Tile_2D:fileWave
	ListBox fileList, selWave=root:myGlobals:Tile_2D:selWave, mode=4
	Button button0, pos={217, 161}, size={170, 20}, proc=AddToLayoutButtonProc, title="Add Selected To Layout"
	Button button0, help={"Adds images of the selected files to the layout selected in the popup menu"}
	Button button1, pos={316, 207}, size={50, 20}, proc=TileDoneButtonProc, title="Done"
	Button button1, help={"Closes the panel, kills the layouts, and kills images from your memory"}
	Button button3, pos={227, 6}, size={60, 20}, proc=GetListButtonProc, title="Get List"
	Button button3, help={"Refreshes the list of data files"}
	Button button4, pos={340, 6}, size={25, 20}, proc=ShowTileHelp, title="?"
	Button button4, help={"Show help file for tiling raw data files in a layout"}
	Button button5, pos={217, 185}, size={170, 20}, proc=AddAllToLayout, title="Add All To Layout"
	Button button5, help={"Adds images of all raw files, 40 per layout"}
	CheckBox check0, pos={216, 94}, size={71, 14}, title="Log scaling"
	CheckBox check0, help={"If checked, the image color will be log scale"}, value=1
	PopupMenu popup0, pos={226, 38}, size={141, 20}, title="Layout ?"
	PopupMenu popup0, help={"Sets a new or existing layout as the destination when adding images"}
	PopupMenu popup0, mode=1, popvalue="New Layout", value=#"\"New Layout;\"+WinList(\"*\", \";\",\"WIN:4\")"
	PopupMenu popup1, pos={226, 64}, size={141, 20}, title="Data Type?"
	PopupMenu popup1, help={"Choose what data type you want ot tile."}
	PopupMenu popup1, mode=1, popvalue="RAW", value="RAW;ASC"
	CheckBox check1, pos={216, 116}, size={72, 14}, proc=FixScale_CheckProc, title="Fixed Scale"
	CheckBox check1, value=0, help={"Sets a fixed z-scale (counts) for all images in the layout. Enter the min and max values"}
	SetVariable scale_0, pos={216, 140}, size={80, 15}, title="min"
	SetVariable scale_0, limits={-Inf, Inf, 0}, value=root:myGlobals:Tile_2D:minScale
	SetVariable scale_0, help={"Minimum mapped count value"}, disable=1 //initially not visible
	SetVariable scale_1, pos={300, 140}, size={80, 15}, title="max"
	SetVariable scale_1, limits={-Inf, Inf, 0}, value=root:myGlobals:Tile_2D:maxScale
	SetVariable scale_1, help={"Maximum mapped count value"}, disable=1 //initially not visible
EndMacro

Function ShowTileHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Tile 2-D Images]"
	if(V_flag != 0)
		DoAlert 0, "The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

Function FixScale_CheckProc(string ctrlName, variable checked) : CheckBoxControl

	//	Print "fix scale =",checked
	//Tile_2D panel must be on top, since it's being checked
	SetVariable scale_0, disable=(!checked)
	SetVariable scale_1, disable=(!checked)
End

// upon hitting the "add to layout" button...
// polls the selected file(s) in the listbox and sequentially loads each
// file into RAW folder, and makes a PNG of the file, and appends each to the selected layout
// ...see SetGraphic() in Schematic.ipf
Function AddToLayoutButtonProc(string ctrlName) : ButtonControl

	ControlInfo popup0
	string layoutStr = S_Value //create new layout or append to old one

	ControlInfo/W=Tile_2D popup1
	string DataStr = S_Value //create new layout or append to old one

	ControlInfo check0
	variable makeLog = V_Value //make the images logscale?

	ControlInfo check1
	variable fixScale = V_Value //use fixed, user-defined scale

	variable minScale, maxScale
	NVAR mns = root:myGlobals:Tile_2D:minScale
	NVAR mxs = root:myGlobals:Tile_2D:maxScale
	if(fixScale == 1)
		if(makeLog == 1)
			//check for zero
			if((mns <= 0) || (mxs <= 0))
				Abort "min and max scale must be greater than zero for log-scaling"
			endif
			minScale = log(mns)
			maxScale = log(mxs)
		else
			minScale = mns
			maxScale = mxs
		endif
	else
		minScale = -1
		maxScale = -1 //if both are equal, autoscale data
	endif

	//loop through the selected files in the list...
	WAVE/T fileWave = $"root:myGlobals:Tile_2D:fileWave"
	WAVE   sel      = $"root:myGlobals:Tile_2D:selWave"
	NVAR   ind      = root:myGlobals:Tile_2D:ind
	variable shift
	variable num      = numpnts(sel)
	variable ii       = 0
	variable err      = 0
	variable startInd = ind
	variable ht       = 1.5
	variable wd       = 1.5 //height and width of the graphic (in inches)
	string   fname    = ""
	string   pathStr  = ""

	PathInfo catPathName //this is where the files are
	pathStr = S_path

	// get the current state
	NVAR     defaultScaling = root:Packages:NIST:gLogScalingAsDefault
	variable oldState       = defaultScaling
	defaultScaling = 0 //set the scaling to linear

	do
		fname = pathStr + N_FindValidFilename(fileWave[ii]) //in case of VAX version numbers

		if(sel[ii] == 1)
			if(stringmatch(fname, "*.ASC"))
				NewDataFolder/O root:Packages:NIST:ASC
				Load_NamedASC_File(fname, "ASC")

				MakePNGforLayout(minScale, maxScale, "ASC", ind)
				ind += 1 //a running count of all of the PNG's
			else
				LoadRawSANSData(fname, "RAW") //fname is the full path
				string/G root:myGlobals:gDataDisplayType = "RAW"
				fRawWindowHook()

				MakePNGforLayout(minScale, maxScale, "RAW", ind)
				ind += 1 //a running count of all of the PNG's
			endif
		endif

		ii += 1
	while(ii < num)
	//close the SANS_Data window
	DoWindow/K SANS_Data

	//now add to the appropriate layout
	if(cmpstr(layoutStr, "New Layout") == 0)
		NewLayout
		DoWindow/C $("PNGLayout" + num2str(ind))
	else
		DoWindow/F $layoutStr
	endif
	for(ii = startInd; ii < ind; ii += 1)
		AppendLayoutObject/F=1/R=(72, 40, 144, 112) picture  $(DataStr + num2str(ii) + "L_PNG")
		//		ModifyLayout top($("RAW"+num2str(ii)+"L_PNG"))=(40+mod(30*ii,560))	//separate the graphics (in points)
		//		ModifyLayout/I width($("RAW"+num2str(ii)+"L_PNG"))=(wd),height($("RAW"+num2str(ii)+"L_PNG"))=(wd) //(in inches)
	endfor
	//careful tiling the objects in the layout - it alters the aspect ratio
	variable totalNumPNGs = itemsinlist(PICTList("*L_PNG", ";", "WIN:"))
	string   rcStr        = "/A=(4,3)"
	wd = 2.5
	//	Print totalNumPNGs
	if(totalNumPNGs > 12)
		rcStr = "/A=(5,4)"
		wd    = 1.9
	endif
	if(totalNumPNGs > 20)
		rcStr = "/A=(7,5)"
		wd    = 1.4
	endif
	if(totalNumPNGs > 35)
		rcStr = "/A=(8,5)"
		wd    = 1.2
	endif
	if(totalNumPNGs > 40)
		rcStr = ""
		wd    = 1
	endif
	Execute "Tile" + rcStr + "/O=8"

	// pick an appropriate width and height (the same) for the permutations of rows and columns to get the
	// largest possible images
	// -- then propogate this change to the Add All to Layout function
	//
	for(ii = startInd; ii < ind; ii += 1)
		ModifyLayout/I width($(DataStr + num2str(ii) + "L_PNG"))=(wd), height($(DataStr + num2str(ii) + "L_PNG"))=(wd) //(in inches)
	endfor

	defaultScaling = oldState //set the scaling back to the previous state
	return (0)
End

// upon hitting the "add to layout" button...
// loads all of the data files in the list
// file into RAW folder, and makes a PNG of the file, and appends each to the selected layout
// ...see SetGraphic() in Schematic.ipf
// This test version will add 40 images to each layout, and tile them
//
Function AddALLToLayout(string ctrlName) : ButtonControl

	DoWindow/F Tile_2D
	if(V_flag == 0)
		DoAlert 0, "You must have the Tile_2D panel open to use this operation"
		return (0)
	endif

	//pop the file list to get a current list
	GetListButtonProc("")

	//tile_2d will now be the top window, but check anyways, since this is not called from a button control
	ControlInfo/W=Tile_2D popup0
	string layoutStr = S_Value //create new layout or append to old one

	ControlInfo/W=Tile_2D popup1
	string DataStr = S_Value //create new layout or append to old one

	ControlInfo/W=Tile_2D check0
	variable makeLog = V_Value //make the images logscale?

	ControlInfo/W=Tile_2D check1
	variable fixScale = V_Value //use fixed, user-defined scale

	variable minScale, maxScale
	NVAR mns = root:myGlobals:Tile_2D:minScale
	NVAR mxs = root:myGlobals:Tile_2D:maxScale
	if(fixScale == 1)
		if(makeLog == 1)
			//check for zero
			if((mns <= 0) || (mxs <= 0))
				Abort "min and max scale must be greater than zero for log-scaling"
			endif
			minScale = log(mns)
			maxScale = log(mxs)
		else
			minScale = mns
			maxScale = mxs
		endif
	else
		minScale = -1
		maxScale = -1 //if both are equal, autoscale data
	endif

	//loop through the selected files in the list...
	WAVE/T fileWave = $"root:myGlobals:Tile_2D:fileWave"
	WAVE   sel      = $"root:myGlobals:Tile_2D:selWave"
	NVAR   ind      = root:myGlobals:Tile_2D:ind //largest index of the PNG files currently in memory
	variable num
	variable ii  = 0
	variable err = 0
	variable startInd, shift
	variable ht           = 1.5
	variable wd           = 1.5 //height and width of the graphic (in inches)
	string   fname        = ""
	string   pathStr      = ""
	variable numPerLayout = 40  //number of images per layout

	num      = numpnts(fileWave) //total number of files
	startind = ind               //this layout(s) PNG files start with this index

	PathInfo catPathName //this is where the files are
	pathStr = S_path

	// get the current state
	NVAR     defaultScaling = root:Packages:NIST:gLogScalingAsDefault
	variable oldState       = defaultScaling
	defaultScaling = 0 //set the scaling to linear

	//make all of the PNG files
	do
		fname = pathStr + N_FindValidFilename(fileWave[ii]) //in case of VAX version numbers

		//Modified for summer student 2014 by mjw
		//Original is follows
		//
		//LoadRawSANSData(fname,"RAW")		//fname is the full path
		//String/G root:myGlobals:gDataDisplayType="RAW"
		//fRawWindowHook()
		//if(makeLog)
		//	err = ConvertFolderToLogScale("RAW")
		//endif
		//MakePNGforLayout(minScale,maxScale,"RAW",ind)
		//ind+=1			//a running count of all of the PNG's
		//

		if(stringmatch(fname, "*.ASC"))
			NewDataFolder/O root:Packages:NIST:ASC
			Load_NamedASC_File(fname, "ASC")

			MakePNGforLayout(minScale, maxScale, "ASC", ind)
			ind += 1 //a running count of all of the PNG's
		else
			LoadRawSANSData(fname, "RAW") //fname is the full path
			string/G root:myGlobals:gDataDisplayType = "RAW"
			fRawWindowHook()

			MakePNGforLayout(minScale, maxScale, "RAW", ind)
			ind += 1 //a running count of all of the PNG's
		endif
		//End Modification

		ii += 1
	while(ii < num)
	//close the SANS_Data window
	DoWindow/K SANS_Data

	//now add to the appropriate layout(s)

	//	if(cmpstr(layoutStr,"New Layout")==0)
	//		NewLayout
	//		DoWindow/C $("PNGLayout"+num2str(ind))
	//	else
	//		DoWindow/F $layoutStr
	//	endif
	variable jj, kk
	string rcStr = ""

	// determine the appropriate scaling for the number of files.
	// if < 40 files, pick the scaling. if > 40, use wd =1, and the last
	// layout may be sparse, but will be scaled like the others.

	if(num > 12)
		rcStr = "/A=(5,4)"
		wd    = 1.9
	endif
	if(num > 20)
		rcStr = "/A=(7,5)"
		wd    = 1.4
	endif
	if(num > 35)
		rcStr = "/A=(8,5)"
		wd    = 1.2
	endif
	if(num > 40)
		rcStr = ""
		wd    = 1
	endif

	NewLayout
	DoWindow/C $("PNGLayout" + num2str(startInd))
	for(ii = startInd; ii < ind; ii += numPerLayout)
		jj = ii
		do
			AppendLayoutObject/F=1/R=(72, 40, 144, 112) picture  $(DataStr + num2str(jj) + "L_PNG")
			ModifyLayout/I width($(DataStr + num2str(jj) + "L_PNG"))=(wd), height($(DataStr + num2str(ii) + "L_PNG"))=(wd) //(in inches)
			jj += 1
		while((jj < (ii + numPerLayout)) && (jj < ind)) //index in batch, keep from running over total number of PNGs
		Execute "Tile" + rcStr + "/O=8"
		//now make them square
		for(kk = ii; kk < jj; kk += 1)
			ModifyLayout/I width($(DataStr + num2str(kk) + "L_PNG"))=(wd), height($(DataStr + num2str(kk) + "L_PNG"))=(wd) //(in inches)
		endfor

		if(jj < ind) //need another layout
			NewLayout
			DoWindow/C $("PNGLayout" + num2str(jj))
		endif
	endfor

	defaultScaling = oldState //set the scaling back to the previous state
	return (0)
End

//filters to keep onle the files that are named like a raw data file, i.e. "*.SAn"
//does not check to see if they really are RAW files though...(too slow)
// ... if the filename does NOt have "SA1","SA2", or "SA3" in the name (anywhere)
// the files will NOT show up in the list box
//
Function GetListButtonProc(string ctrlName) : ButtonControl

	//make sure that path exists
	PathInfo catPathName
	if(V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	endif

	string newList = ""
	variable num

	ControlInfo/W=Tile_2D popup1
	string DataStr = S_Value //create new layout or append to old one

	if(stringmatch(DataStr, "RAW"))
		newList = N_GetRawDataFileList()
	endif
	if(stringmatch(DataStr, "ASC"))
		newList = N_GetASCDataFileList()
	endif

	num = ItemsInList(newlist, ";")
	WAVE/T fileWave = $"root:myGlobals:Tile_2D:fileWave"
	WAVE   selWave  = $"root:myGlobals:Tile_2D:selWave"
	Redimension/N=(num) fileWave
	Redimension/N=(num) selWave
	fileWave = StringFromList(p, newlist, ";")
	Sort filewave, filewave
End

// procedure called when user is done
// deletes all of the graphs, layouts, etc associated with the files that were read in...
//to free up memory and cluttered space
//
//since panel and graphics are killed, gives the user a chance to reconsider
Function TileDoneButtonProc(string ctrlName) : ButtonControl

	DoAlert 1, "Closing the panel will kill the created Layouts. Do you want to continue?"
	if(V_Flag == 2)
		return (0)
	endif

	string pngList = PICTList("*L_PNG", ";", "")
	string item    = ""
	string ltList  = WinList("PNGLayout*", ";", "WIN:4") //default named layout windows
	variable ii, num

	//close the layouts, then kill the PNG's
	num = ItemsinList(ltList, ";")
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, ltList, ";")
		DoWindow/K $item
	endfor

	num = ItemsinList(pngList, ";")
	for(ii = 0; ii < num; ii += 1)
		item = StringFromList(ii, pngList, ";")
		KillPICTs/Z $item
	endfor
	//kill the panel, and reset the globals
	DoWindow/K Tile_2D
	Execute "Init_Tile()"
	return (0)
End

// data has laready been loaded into RAW folder
// make a PNG file by first creating a small graph, then save the graph to the  clipboard,
// and then load it back in from the clipboard in to memory
// (from memory it can be easily appended to a layout)
//
// if minScale and maxScale are equal, data will be (individually) autoscaled
// if minScale and maxScale are unequal, all sets will be scaled to those values
//
Function MakePNGforLayout(variable minScale, variable maxScale, string type, variable ii)

	if(!WaveExists($"root:myGlobals:NIHColors"))
		NIHColorIndex()
	endif

	WAVE   NIHColors = $"root:myGlobals:NIHColors"
	WAVE   data      = getDetectorDataW(type) //this will be the linear data
	string nameStr   = type + num2str(ii) + "L_PNG"

	PauseUpdate; Silent 1 // building window...
	Display/W=(40, 40, 196, 196)
	//plot and name the picture, then kill it
	AppendImage data
	DoWindow/C temp_png
	if(minScale == maxScale)
		WaveStats/Q data
		minScale = V_min
		maxScale = V_max
	endif
	ScaleColorsToData(minScale, maxScale, NIHColors)
	ModifyImage data, cindex=NIHColors
	ModifyGraph margin(left)=14, margin(bottom)=14, margin(top)=14, margin(right)=14
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SVAR fileStr = $("root:Packages:NIST:" + type + ":fileList")
	Textbox/N=text0/F=0/A=MT/X=0.00/Y=0.00/E fileStr

	// comment out the line below for DEMO_MODIFIED version
	SavePICT/Z/E=-5 as "Clipboard" //saves as PNG format

	LoadPICT/O/Q "Clipboard", $nameStr
	DoWindow/K temp_png
	return (0)
End

//******************
//procedures to display a simple panel to export a list of files as ASCII
//******************

// initialization procedure to create the necessary data floder and the waves for
// the list box in the panel
Proc Init_RawExport()
	//create the data folder
	NewDataFolder/O/S root:myGlobals:RAW2ASCII
	//create the waves
	Make/O/T/N=1 fileWave = ""
	Make/O/N=1 selWave = 0
	variable/G ind = 0
	SetDataFolder root:
EndMacro

// main procedure for invoking the raw to ascii panel
// initializes each time to make sure
Proc Export_RAW_Ascii_Panel()
	Init_RawExport()
	DoWindow/F RAW_to_ASCII
	if(V_Flag == 0)
		RAW_to_ASCII()
	endif
EndMacro

//procedure for drawing the simple panel to export raw->ascii
//root:myGlobals:RAW2ASCII:selWave = 1
Proc RAW_to_ASCII()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(501, 97, 885, 282)/K=2
	DoWindow/C RAW_to_ASCII
	ListBox fileList, pos={4, 3}, size={206, 179}
	ListBox fileList, listWave=root:myGlobals:RAW2ASCII:fileWave
	ListBox fileList, selWave=root:myGlobals:RAW2ASCII:selWave, mode=4
	Button button0, pos={239, 132}, size={110, 20}, proc=RA_ExportButtonProc, title="Export File(s)"
	Button button0, help={"Exports (saves to disk) the selected files as ASCII format"}
	Button button1, pos={270, 156}, size={50, 20}, proc=RawExportDoneButtonProc, title="Done"
	Button button1, help={"Closes the panel"}
	Button button3, pos={230, 16}, size={60, 20}, proc=RA_GetListButtonProc, title="Get List"
	Button button3, help={"Refreshes the file listing"}
	Button button4, pos={330, 16}, size={25, 20}, proc=ShowRawExportHelp, title="?"
	Button button4, help={"Show the help file for 2-D export of raw data files"}
	CheckBox check0, pos={220, 50}, size={115, 14}, title="detector coordinates", value=1, mode=1
	CheckBox check0, proc=RA_ExportCheckProc
	CheckBox check1, pos={220, 66}, size={104, 14}, title="Qx,Qy coordinates", value=0, mode=1
	CheckBox check1, proc=RA_ExportCheckProc
	CheckBox check2, pos={220, 82}, size={104, 14}, title="Det. Coord, Grasp compatible", value=0, mode=1
	CheckBox check2, proc=RA_ExportCheckProc
	CheckBox check3, pos={220, 110}, size={104, 14}, title="Select All Files", value=0
	CheckBox check3, proc=RA_SelectAllCheckProc
EndMacro

Function RA_SelectAllCheckProc(string ctrlName, variable checked) : CheckBoxControl

	WAVE w = root:myGlobals:RAW2ASCII:selWave
	if(checked)
		w = 1 // select everything
		CheckBox check3, value=1
	else
		w = 0 // deselect all
		CheckBox check3, value=0
	endif

	return (0)
End

Function RA_ExportCheckProc(string ctrlName, variable checked) : CheckBoxControl

	strswitch(ctrlName)
		case "check0":
			CheckBox check0, value=1
			CheckBox check1, value=0
			CheckBox check2, value=0
			break
		case "check1":
			CheckBox check0, value=0
			CheckBox check1, value=1
			CheckBox check2, value=0
			break
		case "check2": // FIXME(CodeStyleFallthroughCaseRequireComment)
			CheckBox check0, value=0
			CheckBox check1, value=0
			CheckBox check2, value=1
		default:
			// FIXME(BugproneMissingSwitchDefaultCase)
			break
	endswitch
	return (0)
End

//closes the panel when done
Function RawExportDoneButtonProc(string ctrlName) : ButtonControl

	//kill the panel
	DoWindow/K RAW_to_ASCII
	return (0)
End

//filters to keep onle the files that are named like a raw data file, i.e. "*.SAn"
//does not check to see if they really are RAW files though...(too slow)
Function RA_GetListButtonProc(string ctrlName) : ButtonControl

	//make sure that path exists
	PathInfo catPathName
	if(V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	endif

	variable num
	string newList = N_GetRawDataFileList()

	num = ItemsInList(newlist, ";")
	WAVE/T fileWave = $"root:myGlobals:RAW2ASCII:fileWave"
	WAVE   selWave  = $"root:myGlobals:RAW2ASCII:selWave"
	Redimension/N=(num) fileWave
	Redimension/N=(num) selWave
	fileWave = StringFromList(p, newlist, ";")
	Sort filewave, filewave
End

// does a Fast2DExport of the files selected from the listbox
//polls the listbox for selected files and loops through each selection
//exported file is filename + ".ASC" if an ascii detector image
// or ".DAT" if it is in Qx, Qy, I(Qx,Qy) triple format
//
// temporarily change the default logScale display to linear during export
//
Function RA_ExportButtonProc(string ctrlName) : ButtonControl

	//loop through the selected files in the list...
	WAVE/T   fileWave    = $"root:myGlobals:RAW2ASCII:fileWave"
	WAVE     sel         = $"root:myGlobals:RAW2ASCII:selWave"
	variable num         = numpnts(sel)
	variable ii          = 0
	variable qxqy        = 0
	variable detCoord    = 0
	variable GraspASCII  = 0
	string   fname       = ""
	string   pathStr     = ""
	string   fullPath    = ""
	string   newFileName = ""

	PathInfo catPathName //this is where the files are
	pathStr = S_path

	//what type of export?
	// check0 is det coord, check1 is QxQy, check2 is old-style VAX ASCII for Grasp
	ControlInfo check0
	detCoord = V_Value //==1 if detCoord desired
	ControlInfo check1
	qxqy = V_Value //==1 if qxqy desired
	ControlInfo check2
	GraspASCII = V_Value //==1 if GraspASCII desired

	// get the current state
	NVAR     defaultScaling = root:Packages:NIST:gLogScalingAsDefault
	variable oldState       = defaultScaling
	defaultScaling = 0 //set the scaling to linear
	do
		if(sel[ii] == 1)
			fname = pathStr + N_FindValidFilename(fileWave[ii]) //in case of VAX version numbers
			LoadRawSANSData(fname, "RAW") //fname is the full path
			string/G root:myGlobals:gDataDisplayType = "RAW"
			fRawWindowHook()
			newFileName = N_FindValidFilename(fileWave[ii])

			if(qxqy)
				fullPath = pathStr + newFileName + ".DAT"
				QxQy_Export("RAW", fullpath, 0)
			endif
			if(detCoord)
				fullPath = pathStr + newFileName + ".ASC"
				Fast2dExport("RAW", fullpath, 0)
			endif
			if(GraspASCII)
				fullPath = pathStr + newFileName + ".GSP"
				//				fullPath=pathStr+fileWave[ii]+".GSP"		//NOT COMPATIBLE WITH GRASP!!! SEP2019
				Fast2dExport_OldStyle("RAW", fullpath, 0)
			endif
		endif
		ii += 1
	while(ii < num)

	defaultScaling = oldState //set the scaling back to what it was
	return (0)
End

Function ShowRawExportHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[2-D ASCII Export]"
	if(V_flag != 0)
		DoAlert 0, "The SANS Data Reduction Tutorial Help file could not be found"
	endif
End
