#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

// utility functions to work with VSANS polarized beam files
//
// SRK JUN 2020
//
// Currently I do not make full use of the metadata that is supposed to
// be in the data files, since what data is stored and where it is stored
// is clearly different than what I was told.
//
// See the list of text tags farther down this file -- these are the
// text tags for the different flipper/purupose/intent combinations
// -- these tags are added to the file label by the GUI (NICE) so that I
// can rely on them, rather than the current fautly state of the metadata
//

// TODO
// -- once there has been some testing of the accuracy of the labeling of
// specific files for different panels, I can moce from popup mode to just fill it in
// without any need for intervention.
//
//  Popups now are made column-specific, and this seems to work correctly.
//
//
//
//-------------------------------
//
//		V_ScanCellParams()
//
// -- for the cell parameter panel
//    I have a scan function that finds the cell information and populates the table
//    automatically
//
//----------------
//
//		V_ListForDecayPanel()
//
// -- for the decay panel
//		identify Purpose = (HE3)
//					Intent = (Sample or Empty Cell or Blocked Beam or Open Beam)
//					polarizer state = (HeIn, HeOut) (currently search the file label)
//
// -- See: V_DecayTableHook()
//			AND V_FlipperTableHook()  -- the decay list is used in both places
//
//
//--------------
//
//
//		V_ListForFlipperPanel()
//
// -- for the fliper polarization panel
//		identify Purpose = (TRANSMISSION)
//					Intent = (Sample, Open Beam - or Blocked Beam)
//					flip_identity = (T_UU, T_UD, T_DD, T_DU)
//
//
// -- See: V_FlipperTableHook()
//
//------------------------------
//
//		V_ListForCorrectionPanel()
//
// -- for the polarization reduction panel
//		-- identify to fill in (SAM, EMP, BGD)
//						Purpose = (SCATTERING)
//						Intent = (Sample, Empty Cell, Blocked Beam)
//						flip_identity = (S_UU, S_UD, S_DD, S_DU)
//
// -- this list is a little different since it's in a list box. See:
//   V_PolCor_FileListBoxProc() for its use
//
//---------------------------------
//
//
//

// these are the choices of what to read:
// "Front Flipper Direction" == V_getFrontFlipper_Direction(fname) == ("UP" | "DOWN")
//
// "Front Flipper Flip State" == V_getFrontFlipper_flip(fname) = ("True" | "False")
//
// "Front Flipper Type" == V_getFrontFlipper_type(fname) == ("RF")
//
//	"Back Polarizer Direction" == V_getBackPolarizer_direction(fname)	== ("UP" | "DOWN" | "UNPOLARIZED")
//
//	"Back polarizer in?" == V_getBackPolarizer_inBeam(fname) == (0 | 1)

// TODO:
// x- (done)for the cell panel: currenlty I scan for the cells, and open a table with
// the results. would it be possible to automatically add the row to the table of
// cells (and update) rather than requiring a manual copy? The potential snag that
// I see is hitting the button 2X => duplicated row in the table. How can I prevent this,
// or correct this?
// ---- even if there are duplicated cells in the table, this does not cause any issues
// since the "update" step generates a string with the parameters, one for each cell.
// duplicated cells simply generate a duplicate (overwritten) string.
// --- the next step, the decay panel gets the active cells from the strings that exist.
//
//

// -- for the decay panel
//		identify Purpose = (HE3)
//					Intent = (Sample or Empty Cell or Blocked Beam or Open Beam)
//					polarizer state = (HeIn, HeOut) (currently search the file label)
//
// NOTE that the table hook V_DecayTableHook() calls the list 4X and adds them
//  calling once w/intent=Sample, once w/intent=Empty Cell, Blocked beam, Open Beam
//
//
// use the results of this search to fill in the table
// (along with the cell name)
//
// with the list of purpose=HE3
// -- then pick the background, HeIN, HeOUT files
// -- BUT - in the example data I have, these fields are NOT correctly filled in the header!
// so- what use is any of this...
//
//	// state = 1 = HeIN, 0=HeOUT
//
//
//  TODO:
// -- filter out the INTENT = blocked beam -- this is a separate file
// -- and needs to not be in the regular list
//
// -- See: V_DecayTableHook()
//		AND V_FlipperTableHook()  -- this list is used in both places
//
//
Function/S V_ListForDecayPanel(variable state, string intent)

	string   purpose
	variable method
	string str, newList, stateStr

	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method  = 0
	purpose = "HE3"

	// search for this tag in the sample label
	if(state == 1)
		stateStr = "HeIN"
	else
		stateStr = "HeOUT"
	endif

	str = V_PolFileList_LabPurInt(stateStr, purpose, intent)

	//	str = V_getPurposeIntentLabelList(purpose,intent,stateStr,method)

	newList = V_ConvertFileListToNumList(str)

	return (newList)
End

// TODO:
//
// -- for the flipper polarization panel
//
//		identify Purpose = (TRANSMISSION)
//					Intent = (Sample, Open Beam, -or Blocked Beam)
//					flip_identity = (T_UU, T_UD, T_DD, T_DU)
//

// use the results of this search to fill in the table
//
// -- I could read in the flipper information and deduce the UU, DD, UD, DU, etc,
// -- BUT - in the example data I have, these fields are NOT correctly filled in the header!
// so- instead I search the file label...
//
//
// flipStr is found from the column label: ("T_UU" | "T_DD" | "T_DU" | "T_UD")
// intent is either "Sample" or "Blocked Beam", also from the column label
//
Function/S V_ListForFlipperPanel(string flipStr, string intent)

	string   purpose
	variable method
	string str, newList, stateStr

	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method  = 0
	purpose = "TRANSMISSION"

	str = V_PolFileList_LabPurInt(flipStr, purpose, intent)

	//	str = V_getPurposeIntentLabelList(purpose,intent,flipStr,method)

	newList = V_ConvertFileListToNumList(str)

	return (newList)
End

// TODO:
//
// -- for the polarization reduction panel
//		-- identify to fill in (SAM, EMP, BGD)
//						Purpose = (SCATTERING)
//						Intent = (Sample, Empty Cell, Blocked Beam)
//						flip_identity = (S_UU, S_UD, S_DD, S_DU)
//

// use the results of this search to fill in the table
//
// -- I could read in the flipper information and deduce the UU, DD, UD, DU, etc,
// -- BUT - in the example data I have, these fields are NOT correctly filled in the header!
// so- instead I search the file label...
//
//
// flipStr is found from the column label: ("S_UU" | "S_DD" | "S_DU" | "S_UD")
// intent is either "Sample" or "Blocked Beam", also from the column label
//
Function/S V_ListForCorrectionPanel(string flipStr, string intent)

	string   purpose
	variable method
	string str, newList, stateStr

	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method  = 0
	purpose = "SCATTERING"

	str = V_PolFileList_LabPurInt(flipStr, purpose, intent)
	//	str = V_getPurposeIntentLabelList(purpose,intent,flipStr,method)

	newList = V_ConvertFileListToNumList(str)

	return (newList)
End

// function to scan through all of the data files and
// search for possible cell names and parameters
Function V_ScanCellParams()

	variable ii, num, numcells
	variable lam, opacity
	string tmpCell, fname
	string newList  = ""
	string lastCell = ""

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells

	Make/O/T/N=(0, 6) foundCells
	WAVE/T foundCells = foundCells
	foundCells = ""

	newList = V_GetRawDataFileList()

	num = ItemsInList(newList)

	numcells = 0
	for(ii = 0; ii < num; ii += 1)
		// get the BackPolarizer name
		fname   = StringFromList(ii, newList)
		tmpCell = V_getBackPolarizer_name(fname)
		// if it doesn't exist the return string will start with: "The specified..."
		if(cmpstr(tmpCell[0, 3], "The ") != 0)
			if(cmpstr(tmpCell, lastCell) != 0) //different than other cell names
				// legit string, get the other params
				// add a point to the wave
				InsertPoints 0, 1, foundCells

				// CONVERT the opacity + error to the correct wavelength by multiplying

				lam                     = V_getWavelength(fname)
				opacity                 = V_getBackPolarizer_opac1A(fname)
				foundCells[numcells][0] = tmpCell
				foundCells[numcells][1] = num2str(lam)
				foundCells[numcells][2] = num2str(V_getBackPolarizer_tE(fname))
				foundCells[numcells][3] = num2str(V_getBackPolarizer_tE_err(fname))
				foundCells[numcells][4] = num2str(opacity * lam)
				foundCells[numcells][5] = num2str(V_getBackPolarizer_opac1A_err(fname) * lam)

				// update the saved name
				numcells += 1
				lastCell  = tmpCell
			endif
		endif
	endfor

	//	Edit foundCells

	//
	SetDataFolder root:

	return (0)
End

Function/S V_ConvertFileListToNumList(string list)

	variable num, ii
	string item
	string newList = ""

	num = ItemsInList(list)

	for(ii = 0; ii < num; ii += 1)
		item     = StringFromList(ii, list)
		newList += V_GetRunNumStrFromFile(item) + ";"
	endfor

	return (newList)
End

//(Blocked beam should always be OUT unless otherwise noted)

//Run type: FullPol (assumption is SM in Front and 3He in Back)

//HeBB (frontPolarizer OUT, backPolarizer OUT, BlockBeam IN)
//HeOUT (frontPolarizer OUT, backPolarizer OUT)	Purpose="HE3"
//HeIN (frontPolarizer OUT, backPolarizer UP)	Purpose="HE3"
//T_UU (frontPolarizer UP, backPolarizer UP)		Purpose="TRANSMISSION"
//T_DU (frontPolarizer DOWN, backPolarizer UP)		Purpose="TRANSMISSION"
//T_DD (frontPolarizer DOWN, backPolarizer DOWN)		Purpose="TRANSMISSION"
//T_UD (frontPolarizer UP, backPolarizer DOWN)		Purpose="TRANSMISSION"
//T_SM (frontPolarizer UP, backPolarizer OUT)		Purpose="TRANSMISSION"
//S_UU (frontPolarizer UP, backPolarizer UP)		Purpose="SCATTERING"
//S_DU (frontPolarizer DOWN, backPolarizer UP)		Purpose="SCATTERING"
//S_DD (frontPolarizer DOWN, backPolarizer DOWN)		Purpose="SCATTERING"
//S_UD (frontPolarizer UP, backPolarizer DOWN)		Purpose="SCATTERING"
//BB_FP (frontPolarizer UP, backPolarizer OUT, BlockBeam IN) Intent="Blocked Beam", Purpose="SCATTERING"
//

//Run type: HalfPol3He (assumption is 3He in Back)

//HeBB (frontPolarizer OUT, backPolarizer OUT, BlockBeam IN)
//HeOUT (frontPolarizer OUT, backPolarizer OUT)
//HeIN (frontPolarizer OUT, backPolarizer UP)
//T_HeO (frontPolarizer OUT, backPolarizer OUT)
//S_HeU (frontPolarizer OUT, backPolarizer UP)
//S_HeD (frontPolarizer OUT, backPolarizer DOWN)
//BB_He (frontPolarizer OUT, backPolarizer OUT, BlockBeam IN)
//

//Run type: HalfPolSM (assumption is SM in Front)

//T_SM (frontPolarizer UP, backPolarizer OUT)
//S_SMU (frontPolarizer UP, backPolarizer OUT)
//S_SMD (frontPolarizer DOWN, backPolarizer OUT)
//BB_SM (frontPolarizer UP, backPolarizer OUT, BlockBeam IN)
//
//Run type: NoPol
//T_NP (frontPolarizer OUT, backPolarizer OUT)
//S_NP (frontPolarizer OUT, backPolarizer OUT)
//BB_NP (frontPolarizer OUT, backPolarizer OUT, BlockBeam IN)

// for these list-generating functions:
// flipStr is the tag string in the file label
// purpose
// intent 	are both from the file header
//
// *** currently, intent and purpose are filtered quickly from the file catalog
// -- second, the state of the polarizer (a string) is located by searching the file label
// ( the state should ideally be found from the metadata too, not the file label)
// -- but this label is placed by the GUI and should be reliable
//
//
// Only one method is the method to use to find the file
// 0 = (default) is to use the file catalog (= fastest)
// NO-1 = Grep (not terribly slow)
// NO-2 = read every file (bad choice)
//

Function/S V_PolFileList_LabPur(string labelStr, string purpose)

	string list

	list = V_getFilePurposeList(purpose, 0)

	list = V_getLabelList(list, labelStr) //label matches in purp. list

	//	list = V_Pol_List(frontPol,backPol,purpose)

	return (list)
End

Function/S V_PolFileList_LabPurInt(string labelStr, string purpose, string intent)

	string list

	list = V_getFileIntentPurposeList(intent, purpose, 0)
	list = V_getLabelList(list, labelStr) //label matches in PI list

	//	list = V_Pol_List(frontPol,backPol,purpose)

	return (list)
End

//
// a short list of the files with the correct purpose is passed in
// - then the label is searched for the correct labelStr
//
Function/S V_getLabelList(string list, string labelStr)

	variable ii, num, np
	string fname, tmpLbl
	string item    = ""
	string newList = ""

	np = itemsinList(list)
	for(ii = 0; ii < np; ii += 1)
		item   = StringFromList(ii, list)
		tmpLbl = V_getSampleDescription(item)
		if(strsearch(tmpLbl, labelStr, 0) > 0)
			newList += item + ";"
		endif
	endfor

	return (sortList(newList, ";", 0))
End
