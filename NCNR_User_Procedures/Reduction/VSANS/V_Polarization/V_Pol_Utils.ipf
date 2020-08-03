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
//		identify (TRANSMISSION) --- although data is collected as SCATTERING
//					(HeIn, HeOut)
//					(He3, BLOCKED BEAM)
//
//
// -- for the fliper polarization panel
//		identify (TRANSMISSION)
//					(T_UU, T_UD, T_DD, T_DU)
//					(SAMPLE, BLOCKED BEAM)
//
//
//
// -- for the polarization reduction panel
//		-- identify (SAM, EMP, BGD)
//						(SCATTERING)
//						(S_UU, S_UD, S_DD, S_DU)
//



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



// fields currently used in the patch panel
//	listWave[0][1] = "Front Flipper Direction"
//	listWave[0][2] = V_getFrontFlipper_Direction(fname)
//
//	listWave[1][1] = "Front Flipper Flip State"
//	listWave[1][2] = V_getFrontFlipper_flip(fname)	
//
//	listWave[2][1] = "Front Flipper Type"
//	listWave[2][2] = V_getFrontFlipper_type(fname)	
//
//	listWave[3][1] = "Back Polarizer Direction"
//	listWave[3][2] = V_getBackPolarizer_direction(fname)	
//
//	listWave[4][1] = "Back polarizer in?"
//	listWave[4][2] = num2str(V_getBackPolarizer_inBeam(fname))	
//
//




// TODO:
// for the decay panel:
// -- identify the files with:
// Trans -- HeIN
// Trans -- HeOUT
// Blocked beam file
// all have PURPOSE "HE3" (not TRANSMISSION)
// INTENT can be anything
//
// use the results of this search to fill in the table
// (along with the cell name)
//
// with the list of purpose=HE3
// -- then pick the background, HeIN, HeOUT files
// -- BUT - in the example data I have, these fields are NOT correctly filled in the header!
// so- what use is any of this...
//
//
//  TODO:
// -- filter out the INTENT = blocked beam -- this is a separate file
// -- and needs to be not in the regular list
//
//
Function/S V_ListForDecayPanel()

	String purpose="HE3"
	Variable method
	String str,newList
	Variable state
	
	// Don't use method = 0 (won't give the correct list)
	// method = 2 = read the state field
	// method = 1 = grep for the text
	method = 0
	// state = 1 = HeIN, 0=HeOUT
	state = 1
	
	str = V_getFilePurposeDecayList(purpose,state,method)

	newList = V_ConvertFileListToNumList(str)
	
	return(newList)
end



// testStr is the "purpose" string, or grep string
// state is the state of the back polarizer (in|out) (1|0)
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
Function/S V_getFilePurposeDecayList(testStr,state,method)
	String testStr
	Variable state,method
	
	Variable ii,num
	String list="",item="",fname,newList="",purpose,stateStr
	
	if(state==1)
		stateStr="HeIN"
	else
		stateStr="HeOUT"
	endif
	
	
// get a short list of the files with the correct purpose

	// get the list from the file catalog
	
	WAVE/T fileNameW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames
	WAVE/T purposeW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose
	WAVE/T labelsW = root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels
	
	Variable np = numpnts(purposeW)		//fileNameW is LONGER - so don't use numpnts(fileWave)
	for(ii=0;ii<np;ii+=1)
		if(cmpstr(purposeW[ii],testStr)==0)		//this is case-INSENSITIVE (necessary, since the case is unknown)
			list += fileNameW[ii] + ";"
			
			if(method==0)
				if(strsearch(labelsW[ii],stateStr,0) > 0)
					newList += fileNameW[ii] + ";"
				endif
			endif
			
		endif
		
	endfor
	
	if(method==0)
		return(sortList(newList,";",0))
	endif
	
	// other methods, proceed
	
	List = SortList(List,";",0)


//now pare down the list (reading each of the files) using the field:
// V_getBackPolarizer_inBeam(fname) (returns 0|1)

	PathInfo catPathName
	String path = S_path
	Variable fileState

	if(method==2)	
		newList = ""
		num=ItemsInList(list)
		
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, list , ";")
			fname = path + item
			fileState = V_getBackPolarizer_inBeam(fname)
			if(fileState == state)
				newList += item + ";"
			endif
		endfor	
	endif


// OR-- by using grep and an appropriate string
// if state == 1, use HeIN, if == 0, use HeOUT
// (could I grep the sample label field (or strsearch)?
//
	
	// use Grep
	if(method == 1)
		newList = ""
		num=ItemsInList(list)

		
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, list , ";")
			Grep/P=catPathName/Q/E=("(?i)"+stateStr) item
			if( V_value )	// at least one instance was found
	//				Print "found ", item,ii
				newList += item + ";"
			endif
		endfor	

	endif


	
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