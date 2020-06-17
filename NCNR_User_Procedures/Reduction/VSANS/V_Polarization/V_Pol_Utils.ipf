#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// utility functions to work with VSANS polarized beam files
//
// SRK JUN 2020
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












//
//
// To fill the cell parameters
// - scan through the metadata in the files
// -- add anything found to the table

//
// - or do I find the cell name/data as needed?
//



// function to scan through all of the data files and
// search for possible cell names and parameters
Function V_ScanCellParams()

	Variable ii,num,numcells
	String newList = "",lastCell="",tmpCell,fname
	
	Make/O/T/N=(5,6) foundCells
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
				foundCells[numcells][0] = tmpCell
				foundCells[numcells][1] = num2str(V_getWavelength(fname))	
				foundCells[numcells][2] = num2str(V_getBackPolarizer_tE(fname))	
				foundCells[numcells][3] = num2str(V_getBackPolarizer_tE_err(fname))	
				foundCells[numcells][4] = num2str(V_getBackPolarizer_opacityAt1Ang(fname))	
				foundCells[numcells][5] = num2str(V_getBackPolarizer_opacityAt1Ang_err(fname))	
				
				// update the saved name
				numcells += 1
				lastCell = tmpCell
			endif
		endif
	endfor

	return(0)
End