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

Function/S V_ListForDecayPanel()

	String intent="SCATTERING"
	String purpose="HE3"
	Variable method=0		//use the file catalog
	String str
	
	str = V_getFilePurposeList(purpose,method)
//	V_getFileIntentPurposeList(intent,purpose,method)
	
	return(str)
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


