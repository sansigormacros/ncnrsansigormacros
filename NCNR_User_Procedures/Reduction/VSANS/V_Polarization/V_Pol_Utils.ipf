#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// utility functions to work with VSANS polarized beam files
//
// SRK JUN 2020
//
// Currently I do not make full use of the metadata that is supposed to
// be in the data files, since what data is stored and where it is stored
// is clearly different than what I was told. Many changes have apparently 
// been made without keeping me in the loop. Tough to program effectively.
//
//

// TODO:
// -- add functions to identify the files for the different panels
//
// -- for the cell parameter panel
//    I have a scan function that finds the cell information and populates the table 
//    automatically
//
// -- for the decay panel
//		identify Purpose = (HE3)
//					Intent = (Sample or Empty Cell or Blocked Beam or Open Beam) 
//					polarizer state = (HeIn, HeOut) (currently search the file label)
//
//
// -- for the fliper polarization panel
//		identify Purpose = (TRANSMISSION)
//					Intent = (Sample, Open Beam - or Blocked Beam)
//					flip_identity = (T_UU, T_UD, T_DD, T_DU)
//
//
// -- for the polarization reduction panel
//		-- identify to fill in (SAM, EMP, BGD)
//						Purpose = (SCATTERING)
//						Intent = (Sample, Empty Cell, Blocked Beam)
//						flip_identity = (S_UU, S_UD, S_DD, S_DU)
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
//
Function/S V_ListForDecayPanel(state,intent)
	Variable state
	String intent

	String purpose
	Variable method
	String str,newList,stateStr
	
	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method = 0
	purpose = "HE3"
	
	// search for this tag in the sample label
	if(state==1)
		stateStr="HeIN"
	else
		stateStr="HeOUT"
	endif
	
	str = V_getPurposeIntentLabelList(purpose,intent,stateStr,method)

	newList = V_ConvertFileListToNumList(str)
	
	return(newList)
end



// "purpose" string, or grep string
// state is the state of the back polarizer (in|out) (1|0)
// intent
//
// *** currently, intent and purpose are filtered quickly from the file catalog
// -- second, the state of the polarizer (a string) is located by searching the file label
// ( the state should ideally be found from the metadata too, not the file lablel)
//
//
// method is the method to use to find the file
// 0 = (default) is to use the file catalog (= fastest)
// 1 = Grep (not terribly slow)
// 2 = read every file (bad choice)
//
//
//	TODO: replace the "method=0" with a strsearch of the sample label
//  x- the grep seems rather slow. reading the fields directly is not too bad
//    but depends on whether there was a recent save.
//
//
Function/S V_getPurposeIntentLabelList(purpose,intent,labelStr,method)
	String purpose,intent,labelStr
	Variable method
	
	Variable ii,num,np
	String list="",item="",fname,newList="",tmpLbl
	

	
	
// get a short list of the files with the correct purpose

	// get the list from the file catalog
	
	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T purposeW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose
	WAVE/T labelsW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels
	
	list = V_getFileIntentPurposeList(intent,purpose,method)

	np = itemsinList(list)
	for(ii=0;ii<np;ii+=1)
		item=StringFromList(ii, list)
		tmpLbl = V_getSampleDescription(item)
			if(method==0)
				if(strsearch(tmpLbl,labelStr,0) > 0)
					newList += item + ";"
				endif
			endif
	endfor
	
//	np = numpnts(purposeW)		//fileNameW is LONGER - so don't use numpnts(fileWave)
//	for(ii=0;ii<np;ii+=1)
//		if(cmpstr(purposeW[ii],purpose)==0)		//this is case-INSENSITIVE (necessary, since the case is unknown)
//			list += fileNameW[ii] + ";"
//			
//			if(method==0)
//				if(strsearch(labelsW[ii],stateStr,0) > 0)
//					newList += fileNameW[ii] + ";"
//				endif
//			endif
//			
//		endif
//		
//	endfor
//	
	if(method==0)
		return(sortList(newList,";",0))
	endif
	
	// other methods, proceed to use the string to pare the list down
	
	List = SortList(List,";",0)


//now pare down the list (reading each of the files) using the field:
// V_getBackPolarizer_inBeam(fname) (returns 0|1)

//	PathInfo catPathName
//	String path = S_path
//	Variable fileState,state
//	
//	if(method==2)	
//		newList = ""
//		num=ItemsInList(list)
//		
//		for(ii=0;ii<num;ii+=1)
//			item=StringFromList(ii, list , ";")
//			fname = path + item
//			fileState = V_getBackPolarizer_inBeam(fname)
//			if(fileState == state)
//				newList += item + ";"
//			endif
//		endfor	
//	endif


// OR-- by using grep and an appropriate string

// this greps the whole file, not just the sample label
//
	
	// use Grep
	if(method == 1)
		newList = ""
		num=ItemsInList(list)

		
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, list , ";")
			Grep/P=catPathName/Q/E=("(?i)"+labelStr) item
			if( V_value )	// at least one instance was found
	//				Print "found ", item,ii
				newList += item + ";"
			endif
		endfor	

	endif


	
	return(newList)
end


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
Function/S V_ListForFlipperPanel(flipStr,intent)
	String flipStr,intent

	String purpose
	Variable method
	String str,newList,stateStr
	
	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method = 0
	purpose = "TRANSMISSION"
	
	
	str = V_getPurposeIntentLabelList(purpose,intent,flipStr,method)

	newList = V_ConvertFileListToNumList(str)
	
	return(newList)
end



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
Function/S V_ListForCorrectionPanel(flipStr,intent)
	String flipStr,intent

	String purpose
	Variable method
	String str,newList,stateStr
	
	// method = 0 (fastest, uses catatlog + searches sample label)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method = 0
	purpose = "SCATTERING"
	
	
	str = V_getPurposeIntentLabelList(purpose,intent,flipStr,method)

	newList = V_ConvertFileListToNumList(str)
	
	return(newList)
end







// function to scan through all of the data files and
// search for possible cell names and parameters
Function V_ScanCellParams()

	Variable ii,num,numcells
	Variable lam,opacity
	String newList = "",lastCell="",tmpCell,fname

	SetDataFolder root:Packages:NIST:VSANS:Globals:Polarization:Cells
	
	Make/O/T/N=(0,6) foundCells
	Wave/T foundCells=foundCells
	foundCells = ""
	
	newList = V_GetRawDataFileList()

	num = ItemsInList(newList)
	
	numcells = 0
	for(ii=0;ii<num;ii+=1)
		// get the BackPolarizer name
		fname = StringFromList(ii,newList)
		tmpCell = V_getBackPolarizer_name(fname)
		// if it doesn't exist the return string will start with: "The specified..."
		if(cmpstr(tmpCell[0,3],"The ")!=0)
			if(cmpstr(tmpCell,lastCell)!=0)		//different than other cell names
				// legit string, get the other params
				// add a point to the wave
				InsertPoints 0,1, foundCells

				// CONVERT the opacity + error to the correct wavelength by multiplying
				
				lam = V_getWavelength(fname)
				opacity = V_getBackPolarizer_opacityAt1Ang(fname)
				foundCells[numcells][0] = tmpCell
				foundCells[numcells][1] = num2str(lam)	
				foundCells[numcells][2] = num2str(V_getBackPolarizer_tE(fname))	
				foundCells[numcells][3] = num2str(V_getBackPolarizer_tE_err(fname))	
				foundCells[numcells][4] = num2str(opacity*lam)	
				foundCells[numcells][5] = num2str(V_getBackPolarizer_opacityAt1Ang_err(fname)*lam)	
				
				// update the saved name
				numcells += 1
				lastCell = tmpCell
			endif
		endif
	endfor

//	Edit foundCells

//
	SetDataFolder root:
	
	return(0)
End




Function/S V_ConvertFileListToNumList(list)
	String list
	
	Variable num,ii
	String newList="",item
	
	num=ItemsInList(list)
	
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list)
		newList += V_GetRunNumStrFromFile(item) + ";"
	endfor
	
	return(newList)
End