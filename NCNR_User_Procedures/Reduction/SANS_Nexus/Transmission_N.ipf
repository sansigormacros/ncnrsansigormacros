#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//*************************
// Vers. 1.2 092101
//
// - procedures for (easier) caluclation of transmissions along with
//  simultaneous patching of the calculated transmission in designated 
//  raw sans files.
// - transmission and empty beam files are linked to the dataset by their "Annn" suffix
//   only (and their residence in the same data folder)
// - unused (analysis) integer values are used to store these run numbers in the sample
//   file headers so that transmissions can be automatically calculated, once the xy box is set
//   in the empty beam file.
// 
//***************************

//main entry procedure for displaying the Trans input panel
//also initializes the globals as needed
//
Proc CalcTrans()
	
	DoWindow/F Trans_Panel
	If(V_flag == 0)
		InitializeTransPanel()
		//draw panel
		Trans_Panel()
		AutoPositionWindow/M=1/R=Main_Panel Trans_Panel
	Endif
End

// The BuildFileTables routine will build two tables:  one containing the
// data from the headers of transmission files in the folder and one 
// containing the header data from all other SANS data files.  They will
// each have the first column empty for, in the case of transmission files,
// the empty beam file and, in the case of scattering files, the scattering
// run file name.
Proc BuildFileTables()

	Variable err
	PathInfo catPathName
 	if(v_flag==0)
 		err = PickPath()//sets the local path to the data (catPathName)
   		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
 	Endif

 	DoWindow/F TransFileTable

 	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Suffices"
 	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
 	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Lambda"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Whole"
	If(V_Flag==0)
		BuildTransTableWindow()
		ModifyTable width(:myGlobals:TransHeaderInfo:T_SDD)=40
		ModifyTable width(:myGlobals:TransHeaderInfo:T_Lambda)=40
		ModifyTable rgb(:myGlobals:TransHeaderInfo:T_Filenames)=(0,0,65535)
		ModifyTable width(:myGlobals:TransHeaderInfo:T_Transmission)=60
		ModifyTable width(:myGlobals:TransHeaderInfo:T_Whole)=60
		
		ModifyTable width(Point)=0
		//ModifyTable width(:myGlobals:TransHeaderInfo:T_Transmission)=40
	Endif
	
	DoWindow/F ScatterFileTable
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Trans_Error"

	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Whole"
	If(V_Flag==0)
		BuildScatTableWindow()
		ModifyTable width(:myGlobals:TransHeaderInfo:S_SDD)=40
		ModifyTable width(:myGlobals:TransHeaderInfo:S_Lambda)=40
		ModifyTable width(:myGlobals:TransHeaderInfo:S_Transmission)=60
		ModifyTable rgb(:myGlobals:TransHeaderInfo:S_Filenames)=(0,0,65535)
		
		ModifyTable width(Point)=0
	Endif

	String temp=""

	//get a list of all files in the folder, some will be junk version numbers that don't exist
	String list,partialName,tempName
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok

	numitems = ItemsInList(list,";")

	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName
	Variable lastPoint
	ii=0

	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = N_FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0)		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(str2num(partialName) == NaN)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = N_CheckIfRawData(fullName)
			if (ok)
				GetTransHeaderInfoToWave(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
	//Now sort them all based on the suffix data
	SortTransByDate()
	//Now fill in the filenames of the ones that have already had EMP or TRANS
	//files associated with them.
	GetFilenamesFromSuffices()

	//position the windows nicely
	AutoPositionWindow/M=1/R=TransFileTable  ScatterFileTable
	DoWindow/F Trans_Panel
End

//actually creates the table of transmission files
// - the waves must exist
//
Function BuildTransTableWindow()
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_Suffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Wave/T T_Labels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   T_SDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_Lambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	Wave   T_Transmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Edit/K=1/W=(30,30,500,250) T_EMP_Filenames, T_Filenames, T_Labels, T_SDD, T_Lambda, T_Transmission, T_Whole as "TransmissionFiles"
	
	SetWindow kwTopWin hook=GuessFromTableHook, hookevents=1	// mouse down events
	
	String name="TransFileTable"
	DoWindow/C $name

End

//actually creates the table of scattering files
// - the waves must exist
//
Function BuildScatTableWindow()
	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_Suffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Wave/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave   S_SDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_Lambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave   S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"

	
	Edit/K=1/W=(50,50,520,270) S_TRANS_Filenames, S_Filenames, S_Labels, S_SDD, S_Lambda, S_Transmission, S_GTrans_err as "ScatteringFiles"
	String name="ScatterFileTable"
	DoWindow/C $name

End

//sorts each of the tables by date - does this by using the suffix "Annn"
// which is automatically supplied by the VAX (and can't be changed)
// - only problem may be "Z999" -> "A001" rollover
//
Function SortTransByDate()
	Wave/T T_GEMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Wave/T T_GLabels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   T_GSDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_GLambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	Wave   T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"

	Wave/T S_GTRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Wave/T S_GLabels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave   S_GSDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_GLambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_GTransmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave 	 S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"
	Wave   S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	Sort T_GSuffix, T_GEMP_Filenames, T_GSuffix, T_GSuffices, T_GFilenames, T_GLabels, T_GSDD, T_GLambda, T_GTransmission, T_Whole
	Sort S_GSuffix, S_GTRANS_Filenames, S_GSuffix, S_GSuffices, S_GFilenames, S_GLabels, S_GSDD, S_GLambda, S_GTransmission, S_Whole, S_GTrans_err
	
End

// sorts files alphabetically byt the sample label
// - consistent and descriptive sample labels really pay off here
//
Function SortTransByLabel()
	Wave/T T_GEMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Wave/T T_GLabels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   T_GSDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_GLambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	Wave   T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Wave/T S_GTRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Wave/T S_GLabels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave   S_GSDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_GLambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_GTransmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave   S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"
	Wave   S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	Sort T_GLabels, T_GEMP_Filenames, T_GSuffix, T_GSuffices, T_GFilenames, T_GLabels, T_GSDD, T_GLambda, T_GTransmission, T_Whole
	Sort S_GLabels, S_GTRANS_Filenames, S_GSuffix, S_GSuffices, S_GFilenames, S_GLabels, S_GSDD, S_GLambda, S_GTransmission, S_Whole, S_GTrans_err
	
End

//reads the file and assigns header information to the proper table
//
//fname - is the full path:name of the datafile (used by Open)
//sname - is the name only, used as the filename field
//
// takes care of all necessary open/close of file
//
Function GetTransHeaderInfoToWave(fname,sname)
	String fname,sname
	
	Variable isTrans

	Variable lastPoint

	isTrans = N_isTransFile(fname)
	// decalre the correct set of waves
	// S_Whole is only a place holder so the waves are of equal length
	if (isTrans)
		Wave/T GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
		Wave/T G_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
		Wave/T GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
		Wave/T GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
		Wave/T GLabels = $"root:myGlobals:TransHeaderInfo:T_Labels"
		Wave GSDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
		Wave GLambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
		Wave GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
		Wave GWhole = $"root:myGlobals:TransHeaderInfo:T_Whole"
	Else
		Wave/T GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
		Wave/T G_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
		Wave/T GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
		Wave/T GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
		Wave/T GLabels = $"root:myGlobals:TransHeaderInfo:S_Labels"
		Wave GSDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
		Wave GLambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
		Wave GTransmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
		Wave S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"
		Wave GWhole = $"root:myGlobals:TransHeaderInfo:S_Whole"		
	Endif

	lastPoint = numpnts(GLambda)
	
	InsertPoints lastPoint,1,G_TRANS_Filenames
	G_TRANS_Filenames[lastPoint]=""

	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file suffix
	InsertPoints lastPoint,1,GSuffix
	GSuffix[lastPoint]=getSuffix(fname)

	//read any suffix that this file is associated with
	InsertPoints lastPoint,1,GSuffices
	GSuffices[lastPoint]=getAssociatedFileSuffix(fname)
	    
	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleDescription(fname)
	    

	//Transmission
	InsertPoints lastPoint,1,GTransmission
	GTransmission[lastPoint]=getSampleTransmission(fname)
	

	
	//Whole detector Transmission
	InsertPoints lastPoint,1,GWhole
	GWhole[lastPoint]=getSampleTransWholeDetector(fname)
	    
	//SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]=getDet_Distance(fname)
	    
	//wavelength
	InsertPoints lastPoint,1,GLambda
	GLambda[lastPoint]=getWavelength(fname)
	
	if(isTrans==0)	
		//Transmission error
		InsertPoints lastPoint,1,S_GTrans_err
		S_GTrans_err[lastPoint] = getSampleTransError(fname)
	Endif			
			
	return(0)
End

//fills in the file relations that have already been set
//
//
Function GetFilenamesFromSuffices()
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	
	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	
	Variable num_s_files, num_t_files, ii, jj
	num_t_files = numpnts(T_GFilenames)
	num_s_files = numpnts(S_GFilenames)
	//print num_t_files, num_s_files
	
	// Get transmission file relations
	ii= 0
	do
		if (cmpstr(T_GSuffices[ii],"")!=0)
			jj=0
			do
				if (cmpstr(T_GSuffices[ii],T_GSuffix[jj])==0)
					T_EMP_Filenames[ii]=T_GFilenames[jj]
				endif
			jj+=1
			while(jj<num_t_files)
		endif
		ii+=1
	while(ii<num_t_files)
  
	// Get scattering file relations
	ii= 0
	do
		if (cmpstr(S_GSuffices[ii],"")!=0)
			jj=0
			do
				if (cmpstr(S_GSuffices[ii],T_GSuffix[jj])==0)
					S_TRANS_Filenames[ii]=T_GFilenames[jj]
				endif
			jj+=1
			while(jj<num_t_files)
		endif
		ii+=1
	while(ii<num_s_files)
End

// gets the selected transmission filename, and puts its name as the 
//empty beam reference file
// lists the xy box coordinates as read from the file header (zeros if not yet assigned)
//
Function PickEMPTransButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable TransFileTableExists
	TransFileTableExists = WinType("TransFileTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	if (TransFileTableExists != 0)
		String/G root:myGlobals:TransHeaderInfo:gEMP = ""
		GetSelection table,TransFileTable,7
		//Print S_Selection
		if(strsearch(S_selection,"T_Filenames",0) == 0)
		   //selection OK, add to list
			Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
			Wave/T selectedFiles = $"filenames"

		  	SVAR temp = root:myGlobals:TransHeaderInfo:gEMP
			//
			temp = temp+selectedFiles[0]		//take just the first file
			
			UpdateBoxCoordinates()
			
			//check to make sure that if the box is set, that the count value in the box is set too...
			// if the box is set by a protocol, then the counts are not set -> and the transmission will be INF
			String tempName = N_FindValidFilename(temp)
			if(cmpstr(tempName,"")==0)
				//file not found, get out
				Abort "Empty beam file not found UpdateBoxCoordinates(ctrlName)"
			Endif
			//name is ok, prepend path to tempName for read routine 
			PathInfo catPathName
			String filename = S_path + tempName
			Variable boxCounts = getBoxCounts(filename)
			
			variable x1,x2,y1,y2
			getXYBoxFromFile(filename,x1,x2,y1,y2)
			
			if( (boxCounts == 0) && (x1!=0) && (x2!=0) && (y1!=0) && (y2!=0) )
				DoAlert 0,"Box Counts were not recorded. Please re-select the box using SetXYBox"
			endif
			
			
		Else
			DoWindow/F TransFileTable
   			DoAlert 0,"Invalid selection from the Transmision file table. You must select a file from the T_Filenames column"
		Endif
	else
		//no selection
		DoAlert 0,"No file selected from Transmission file table or no Transmission file table available"
	Endif
End

//initialize data folder and globals for the Trans panel as needed
//since this operation is somewhat tangled with the Patch Panel, keep all of the 
//globals in the Patch subfolder (make sure both panels are simultaneously initialized)
//do not create a separate Trans folder
//
Proc InitializeTransPanel()
	//create the global variables needed to run the Trans Panel
	//all are kept in root:myGlobals:TransHeaderInfo
	If( ! (DataFolderExists("root:myGlobals:TransHeaderInfo"))  )
		//create the data folder and the clobals for BOTH the Patch and Trans Panels
		NewDataFolder/O root:myGlobals:TransHeaderInfo
		CreateTransGlobals()
	Endif
End


//
Proc CreateTransGlobals()

	PathInfo catPathName
	If(V_flag==1)
		String dum = S_path
		String/G root:myGlobals:TransHeaderInfo:gCatPathStr = dum
	else
		String/G root:myGlobals:TransHeaderInfo:gCatPathStr = "no path selected"
	endif

	String/G root:myGlobals:TransHeaderInfo:gEMP = "no file selected"
	String/G root:myGlobals:TransHeaderInfo:gBox = ""
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Lambda"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Trans_Error"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	String/G root:myGlobals:TransHeaderInfo:gMatchingSampleFiles = ""

End


//function that writes out (to the header of a raw binary SANS file)
//characters representing the empty beam file and the sample transmission file
//the 4-character file suffix is written, rather than the run numbers
//from this, the trans files can be located, and the 
//sample file contains all the information needed to calculate its transmission
//
//uses first 4 bytes of params.reserve (character field) starting at byte 404
//(previous version (AM) used run.reserve field @ byte 91, which was not empty, and not at the start of the field!)
//
Function AssignSelTransFilesToData(startRow,endRow)
	Variable startRow,endRow

//	GetSelection table,ScatterFileTable,1
	
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	
	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	
	Variable num_s_files, num_t_files, ii, jj
	Variable refnum
	num_t_files = numpnts(T_GFilenames)
	String suffix = ""
	PathInfo catPathName
	String pathname = S_path
	String filename

	// Write suffix of empty beam file into transmission files
	ii= 0
	do
		if (cmpstr(T_EMP_Filenames[ii],"")!=0)
			jj=0
			do
				if (cmpstr(T_EMP_Filenames[ii],T_GFilenames[jj])==0)
					suffix=T_GSuffix[jj]
					filename = pathname + T_GFilenames[ii]
					WriteAssocFileSuffixToHeader(filename,suffix)
				endif
				jj+=1
			while(jj<num_t_files)
		endif
	ii+=1
	while(ii<num_t_files)
 
	// Write suffix of transmission files into scattering files
	ii= startRow
	do
		if (cmpstr(S_TRANS_Filenames[ii],"")!=0)
			jj=0
			do
				if (cmpstr(S_TRANS_Filenames[ii],T_GFilenames[jj])==0)
					suffix=T_GSuffix[jj]
					filename = pathname + S_GFilenames[ii]
					WriteAssocFileSuffixToHeader(filename,suffix)
				endif
				jj+=1
			while(jj<num_t_files)
		endif
		ii+=1
	while(ii<=endRow)
	return(0)
End

// Allows to calculate transmissions without need of a scattering file. Used with the Calculate Total Trans button.

Function AssignTotalTransFilesToData(startRow,endRow)
	Variable startRow,endRow

//	GetSelection table,ScatterFileTable,1
	
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GSuffices = $"root:myGlobals:TransHeaderInfo:T_Suffices"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"

	Variable num_t_files, ii, jj
	Variable refnum
	num_t_files = numpnts(T_GFilenames)
	String suffix = ""
	PathInfo catPathName
	String pathname = S_path
	String filename

	// Write suffix of empty beam file into transmission files
	ii= 0
	do
		if (cmpstr(T_EMP_Filenames[ii],"")!=0)
			jj=0
			do
				if (cmpstr(T_EMP_Filenames[ii],T_GFilenames[jj])==0)
					suffix=T_GSuffix[jj]
					filename = pathname + T_GFilenames[ii]
					WriteAssocFileSuffixToHeader(filename,suffix)
				endif
				jj+=1
			while(jj<num_t_files)
		endif
	ii+=1
	while(ii<num_t_files)
 
	return(0)
End


//function that clears the selected assignments of sample trans -> sample scattering
//also writes a trans=1 value back to the sample file
//
// DEC 2006 - now also writes blank suffix to clear trans->empty assignment, and Twhole=1
//
// target = 1 = ScatterFileTable
// target = 2 = TransFileTable
Function fClearSelectedAssignments(startRow,endRow,target)
	Variable startRow,endRow,target
	
	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GSuffices = $"root:myGlobals:TransHeaderInfo:S_Suffices"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_GSuffix = $"root:myGlobals:TransHeaderInfo:S_Suffix"
	Wave S_GTransmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_GSuffix = $"root:myGlobals:TransHeaderInfo:T_Suffix"
	Wave T_GTransmission =  $"root:myGlobals:TransHeaderInfo:T_Transmission"
	Wave T_GTWhole =  $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	
	Variable num_s_files, num_t_files, ii, jj
	Variable refnum,zero=0
	num_t_files = numpnts(T_GFilenames)
	String suffix = "    "		//4 blank spaces
	PathInfo catPathName
	String pathname = S_path
	String filename

// If the selection is from the TransFileTable
// - wipe out the box coordinates
// - wipe out the suffix
// - wipe out the transmission
// - wipe out T_whole 
// - update the waves in the table

	if(target == 2)
		ii= startRow
		do
			filename = pathname + T_GFilenames[ii]
			
			// write in zeros for the box coordinates
			WriteXYBoxToHeader(filename,0,0,0,0)
			
			// write in a null suffix
			WriteAssocFileSuffixToHeader(filename,suffix)
			
			//write a trans==1 to the file header of the raw data
			writeSampleTransmission(filename,1)		//sample trans
			
			WriteWholeTransToHeader(filename,1)		//WholeTrans start byte is 392
			
			WriteTransmissionErrorToHeader(filename,0)			//reset transmission error to zero
			WriteBoxCountsErrorToHeader(filename,0)
			
			//then update the table that is displayed
			T_EMP_Filenames[ii] = ""
			T_GTransmission[ii] = 1
			T_GTWhole[ii] = 1
			
			ii+=1
		while(ii<=endRow)
	endif
	
 
 	if(target == 1)
		// Write null suffix of transmission files into scattering files
		ii= startRow
		do
			filename = pathname + S_GFilenames[ii]
			// write in a null suffix
			WriteAssocFileSuffixToHeader(filename,suffix)
			
			//write a trans==1 to the file header of the raw data (open/close done in function)
			writeSampleTransmission(filename,1)		//sample trans
			WriteTransmissionErrorToHeader(filename,0)			//reset transmission error to zero
			WriteBoxCountsErrorToHeader(filename,0)
			
			//then update the table that is displayed
			S_TRANS_Filenames[ii] = ""
			S_GTransmission[ii] = 1
			S_GTrans_err[ii] = 0
			
			ii+=1
		while(ii<=endRow)
	endif
	
	return(0)
End

//given a selection of scattering files, calculates the transmission
//and writes the new transmission to the file header
//
//given the full path;name;vers  (= filenmame), of a raw binary SANS file,
//the transmission of the sample is calculated (if possible) from information
//in the file header. empty beam and sample transmision run numbers are extracted
//and the files are located from the run number (if possible)
//from the header of the empty beam file, the XY box coordinates and "empty" 
//counts are determined
//once all information is located, the transmission is calculated and the 
//transmission field of the sample file is automatically "Patched"
// - updates the global variable that is displayed in the panel
//can be run in batch mode, sequentially passing each item from a list of filenames
//this is the single step of the batch mode
// 
//in batch mode: execution will proceed through all of the files, reporting
//results to the history window. If no trans could be successfully calculated
//(for a blocked beam, for example), then that is displayed as well, and the 
//raw data is not modified
//
// now takes the attenuation of the sample trans and empty beam trans into account, (normally this == 1)
// and rescales the transmission as appropriate
// 3/31/04  SRK
//
Function CalcSelTransFromHeader(startRow,endRow)
	Variable startRow,endRow
//	GetSelection table,ScatterFileTable,1

	String filename
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	
	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave S_GTransmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave S_GTrans_err =  $"root:myGlobals:TransHeaderInfo:S_Trans_Error"

	Variable num_s_files, num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans,sam_atten_err,emp_atten_err
	Variable x1,x2,y1,y2,err,attenEmp,attenSam,empty_ct_err,sam_ct_err,samAttenFactor,empAttenFactor,trans_err
	String suffix = "",pathName,textStr,abortStr,emptyFile,transFile,samFileStr,empFileStr

	
	num_t_files = numpnts(T_GFilenames)
	
	PathInfo catPathName
	pathname = S_path

	ii= startRow
	do
		if (cmpstr(S_TRANS_Filenames[ii],"")!=0)	//if there is a sample trans file assigned
			jj=0
			do
				if (cmpstr(S_TRANS_Filenames[ii],T_GFilenames[jj])==0)	//find it in the trans file table
					if (cmpstr(T_EMP_Filenames[jj],"")!=0)		//if empty beam file assigned, proceed with the calculation
						//full path+name to access all 3 files
						filename=pathname+S_GFilenames[ii]
						emptyFile = pathname+T_EMP_Filenames[jj]
						transFile = pathname+T_GFilenames[jj]
						//////////
						// check the empty beam file for previously selected coordinates
						//if they exist, set the xy string , save the normalized counts somewhere
						//the value was written to an unused r*4 header analysis.factor (@b494)
						GetXYBoxFromFile(emptyFile,x1,x2,y1,y2)
						
						//read the real count value
						emptyCts = getBoxCounts(emptyFile)
						// get the error in count value
						empty_ct_err = getBoxCountsError(emptyFile)
						
						// read the attenuator number of the empty beam file
						attenEmp = getAtten_number(emptyFile)
						//
						if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
							//no region selected	-- prompt user to select box w/marquee
							DoWindow/F TransFileTable
							Abort "Use \"Set BCENT File\", then \"SetXYBox\" to select XY range in empty beam file "+T_EMP_Filenames[jj]
							//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
						Endif
		
						//read in trans file then add to SAM
						ReadHeaderAndData(transFile,"RAW")
						//adds to SAM
						err = Raw_to_work_for_Ordela("SAM")
						//sum region in SAM
						transCts =  SumCountsInBox(x1,x2,y1,y2,sam_ct_err,"SAM")	
						// get the attenuator, lambda, and sample string (to get the instrument)
					
						samfileStr = getAcctName("SAM")
						empfileStr = getAcctName("EMP")
						//lambda = getWavelength("SAM")
						//attenSam = getAtten_number("SAM")
						
						//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
						samAttenFactor = getAttenuator_transmission(samFileStr)
						sam_atten_err = getAttenuator_trans_err(samFileStr)
						empAttenFactor = getAttenuator_transmission(empFileStr)
						emp_atten_err = getAttenuator_trans_err(empFileStr)
						AttenRatio = empAttenFactor/samAttenFactor
						//calculate trans based on empty beam value and rescale by attenuation ratio
						trans= transCts/emptyCts * AttenRatio
						
						// squared, relative error
						if(AttenRatio == 1)
							trans_err = (sam_ct_err/transCts)^2 + (empty_ct_err/emptyCts)^2		//same atten, att_err drops out
						else
							trans_err = (sam_ct_err/transCts)^2 + (empty_ct_err/emptyCts)^2 + (sam_atten_err/samAttenFactor)^2 + (emp_atten_err/empAttenFactor)^2
						endif
						trans_err = sqrt(trans_err)
						trans_err *= trans		// now, one std deviation
						
						//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
						If(attenRatio==1)
							Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\r",S_GFilenames[ii], transCts,trans,trans_err
						else
							Printf "%s\t\tTrans Counts = %g\tTrans = %g +/- %g\tAttenuatorRatio = %g\r",S_GFilenames[ii], transCts,trans,trans_err,attenRatio
						endif
						//write the trans to the file header of the raw data (open/close done in function)
						writeSampleTransmission(filename,trans)
						
						WriteTransmissionErrorToHeader(filename,trans_err)
/////						
						//then update the global that is displayed
						S_GTransmission[ii] = trans
						S_GTrans_err[ii] = trans_err

						
					else  // There is no empty assigned
						abortStr = "Empty beam file not assigned properly for " + T_GFilenames[jj]
						Print abortStr
						//Abort abortStr
						return(1)
					endif
				endif
				jj+=1
			while(jj<num_t_files)
		else //no transmission file
			abortStr = "Transmission beam file not assigned properly for " + S_GFilenames[ii]
			Print abortStr
		endif
		ii+=1
	while(ii<=endRow)
	print "done"
	return(0)
End

// 
// For the calculation of the Transmission using only the Trans Files screen
// Uses only the information on the transmissionFiles screen to calculate 
// a "box" Transmission for comparison with the Whole Transmission
// updated 5/11/2006 by Bryan Greenwald
Function CalcTotalTrans(startRow,endRow)
	Variable startRow,endRow
//	GetSelection table,ScatterFileTable,1

	String filename
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	
//	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
//	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
//	Wave S_GTransmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave GWhole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Variable num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans,samAttenFactor,empAttenFactor,trans_err
	Variable x1,x2,y1,y2,err,attenEmp,attenSam,empty_ct_err,sam_ct_err,emp_atten_err,sam_atten_err
	String suffix = "",pathName,textStr,abortStr,emptyFile,transFile,samFileStr,empFileStr

	
	num_t_files = numpnts(T_GFilenames)
	
	PathInfo catPathName
	pathname = S_path

	ii= startRow
	do
		if (cmpstr(T_Emp_Filenames[ii],"")!=0)	//if there is a sample trans file assigned
			jj=0
			do
				if (cmpstr(T_Emp_Filenames[ii],T_GFilenames[jj])==0)	//find it in the trans file table
					if (cmpstr(T_EMP_Filenames[ii],"")!=0)		//if empty beam file assigned, proceed with the calculation
						//full path+name to access all 3 files
						filename=pathname+T_GFilenames[ii]
						emptyFile = pathname+T_EMP_Filenames[ii]
						transFile = pathname+T_GFilenames[ii]
						//////////
						// check the empty beam file for previously selected coordinates
						//if they exist, set the xy string , save the normalized counts somewhere
						//the value was written to an unused r*4 header analysis.factor (@b494)
						getXYBoxFromFile(emptyFile,x1,x2,y1,y2)
						
						//read the real count value
						emptyCts = getBoxCounts(emptyFile)
						// get the count error
						empty_ct_err = getBoxCountsError(emptyFile)
						
						// read the attenuator number of the empty beam file
						attenEmp = getAtten_number(emptyFile)
						
						//
						if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
							//no region selected	-- prompt user to select box w/marquee
							DoWindow/F TransFileTable
							Abort "Use \"Set BCENT File\", then \"SetXYBox\" to select XY range in empty beam file "+T_EMP_Filenames[jj]
							//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
						Endif
		
						//read in trans file then add to SAM
						ReadHeaderAndData(transFile,"RAW")
						//adds to SAM
						err = Raw_to_work_for_Ordela("SAM")
						//sum region in SAM
						transCts =  SumCountsInBox(x1,x2,y1,y2,sam_ct_err,"SAM")	
						// get the attenuator, lambda, and sample string (to get the instrument)
						
						samfileStr = getAcctName("SAM")
						empfileStr = getAcctName("EMP")
//						lambda = getWavelength("SAM")
//						attenSam = getAtten_number("SAM")
						
						//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
						samAttenFactor = getAttenuator_transmission(samFileStr)
						sam_atten_err = getAttenuator_trans_err(samFileStr)
						empAttenFactor = getAttenuator_transmission(empFileStr)
						emp_atten_err = getAttenuator_trans_err(empFileStr)
						AttenRatio = empAttenFactor/samAttenFactor
						//calculate trans based on empty beam value and rescale by attenuation ratio
						trans= transCts/emptyCts * AttenRatio
						
						// squared, relative error
						if(AttenRatio == 1)
							trans_err = (sam_ct_err/transCts)^2 + (empty_ct_err/emptyCts)^2		//same atten, att_err drops out
						else
							trans_err = (sam_ct_err/transCts)^2 + (empty_ct_err/emptyCts)^2 + (sam_atten_err/samAttenFactor)^2 + (emp_atten_err/empAttenFactor)^2
						endif
						trans_err = sqrt(trans_err)
						trans_err *= trans		// now, one std deviation						
						
						//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
						If(attenRatio==1)
							//Printf "%s\t\tTrans Counts = %g\t Actual Trans = %g\r",T_GFilenames[ii], transCts,trans
							Printf "%s\t\tBox Counts = %g\t Trans = %g +/- %g\r",T_GFilenames[ii], transCts,trans,trans_err
						else
							//Printf "%s\t\tTrans Counts = %g\t Trans = %g\tAttenuatorRatio = %g\r",T_GFilenames[ii], transCts,trans,attenRatio
							Printf "%s\t\tBox Counts = %g\t Trans = %g +/- %g\t AttenuatorRatio = %g\r",T_GFilenames[ii], transCts,trans,trans_err,attenRatio
						endif
						//write the trans to the file header of the raw data (open/close done in function)
						writeSampleTransmission(filename,trans)		//transmission start byte is 158
						
						WriteTransmissionErrorToHeader(filename,trans_err)
												
						//then update the global that is displayed
						T_GTransmission[ii] = trans
						
					else  // There is no empty assigned
						abortStr = "Empty beam file not assigned properly for " + T_GFilenames[jj]
						Print abortStr
						//Abort abortStr
						return(1)
					endif
				endif
				jj+=1
			while(jj<num_t_files)
		else //no transmission file
			abortStr = "Transmission beam file not assigned properly for " + T_GFilenames[ii]
			Print abortStr
		endif
		ii+=1
	while(ii<=endRow)
	//print "done"
	return(0)
End

// 
// For the calculation of the Transmission using only the whole detector
// Used to compute the transmission for the TransmissionFiles table using
// the entire detector. For comparison with the "box" trans
// updated: 5/11/2006 by Bryan Greenwald
Function CalcWholeTrans(startRow,endRow)
	Variable startRow,endRow
//	GetSelection table,ScatterFileTable,1

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR type = root:myGlobals:gDataDisplayType
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
		
	String filename
	Wave/T T_EMP_Filenames = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	
	Wave/T T_GFilenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	
//	Wave/T S_TRANS_Filenames = $"root:myGlobals:TransHeaderInfo:S_TRANS_Filenames"
//	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
//	Wave S_GTransmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave GWhole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Variable num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans,sam_atten,emp_atten
	Variable x1,x2,y1,y2,err,attenEmp,attenSam,empty_ct_err,sam_ct_err,emp_atten_err,sam_atten_err
	String suffix = "",pathName,textStr,abortStr,emptyFile,transFile,samFileStr,empFileStr
	
	num_t_files = numpnts(T_GFilenames)
	
	PathInfo catPathName
	pathname = S_path

	ii= startRow
	do
		if (cmpstr(T_Emp_Filenames[ii],"")!=0)	//if there is a sample trans file assigned
			jj=0
			do
				if (cmpstr(T_Emp_Filenames[ii],T_GFilenames[jj])==0)	//find it in the trans file table
					if (cmpstr(T_EMP_Filenames[ii],"")!=0)		//if empty beam file assigned, proceed with the calculation
						//full path+name to access all 3 files
						filename=pathname+T_GFilenames[ii]
						emptyFile = pathname+T_EMP_Filenames[ii]
						transFile = pathname+T_GFilenames[ii]
						//////////
						// check the empty beam file for previously selected coordinates
						//if they exist, set the xy string , save the normalized counts somewhere
						//the value was written to an unused r*4 header analysis.factor (@b494)
						
						getXYBoxFromFile(emptyFile,x1,x2,y1,y2)
						//read the real count value
						emptyCts = getBoxCounts(emptyFile)
						// get the box count error
						empty_ct_err = getBoxCountsError(emptyFile)
						
						// read the attenuator number of the empty beam file
						attenEmp = getAtten_number(emptyFile)
						
						//
						if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
							//no region selected	-- prompt user to select box w/marquee
							DoWindow/F TransFileTable
							Abort "Use \"Set BCENT File\", then \"SetXYBox\" to select XY range in empty beam file "+T_EMP_Filenames[jj]
							//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
						Endif
		
						//read in trans file then add to SAM
						ReadHeaderAndData(transFile,"RAW")
						//adds to SAM
						err = Raw_to_work_for_Ordela("SAM")
						//sum region in SAM
						transCts =  SumCountsInBox(0,pixelsX-1,0,pixelsY-1,sam_ct_err,"SAM")	
						// get the attenuator, lambda, and sample string (to get the instrument)
					
						samfileStr = getAcctName("SAM")
						empfileStr = getAcctName("EMP")
//						lambda = getWavelength("SAM")
//						attenSam = getAtten_number("SAM")
//						
						//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
						sam_atten = getAttenuator_transmission(samFileStr)
						sam_atten_err = getAttenuator_trans_err(samFileStr)
						emp_atten = getAttenuator_transmission(empFileStr)
						emp_atten_err = getAttenuator_trans_err(empFileStr)

						AttenRatio = sam_atten/emp_atten
						
						//calculate trans based on empty beam value and rescale by attenuation ratio
						trans= transCts/emptyCts * AttenRatio
						
						//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
						If(attenRatio==1)
							//Printf "%s\t\tTrans Counts = %g\tTrans using whole detector = %g\t Tbox/Twhole = %g\r",T_GFilenames[ii], transCts,trans,T_GTransmission[ii]/trans
							Printf "%s\t\tTotal Counts = %g\t Trans using whole detector = %g\t",T_GFilenames[ii], transCts,trans
						else
							//Printf "%s\t\tTrans Counts = %g\tTrans = %g\tAttenuatorRatio = %g, Tbox/Twhole = %g\r",T_GFilenames[ii], transCts,trans,attenRatio, T_GTransmission[ii]/trans
							Printf "%s\t\tTotal Counts = %g\t Trans using whole detector = %g\t AttenuatorRatio = %g",T_GFilenames[ii], transCts,trans,attenRatio
						endif
						If(T_GTransmission[ii]/trans > 0.95)		//95%, from conversation w/Lionel
							printf " Tbox/Twhole = %g\r",T_GTransmission[ii]/trans
						else
							printf " !!! Tbox/Twhole is low !!! = %g\r",T_GTransmission[ii]/trans
						endif
						//write the trans to the file header of the raw data (open/close done in function)
						WriteWholeTransToHeader(filename,trans)
						
						//then update the global that is displayed
						GWhole[ii] = trans
						
					else  // There is no empty assigned
						abortStr = "Empty beam file not assigned properly for " + T_GFilenames[jj]
						Print abortStr
						//Abort abortStr
						return(1)
					endif
				endif
				jj+=1
			while(jj<num_t_files)
		else //no transmission file
			abortStr = "Transmission beam file not assigned properly for " + T_GFilenames[ii]
			Print abortStr
		endif
		ii+=1
	while(ii<=endRow)
	print "done"
	return(0)
End


//window recreation macro for the Trans Panel
//
Proc Trans_Panel() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(173,197,548,444) /K=1 as "Calculate Transmissions"
	DoWindow/C Trans_Panel
	ModifyPanel cbRGB=(49807,47186,38011)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 0,56,368,56
	DrawLine 0,142,368,142
	Button pick_emp,pos={4,65},size={105,20},proc=PickEMPTransButton,title="set EMPTY file"
	Button pick_emp,help={"This button will set the file selected in the Transmission file table to be the empty beam file."}
	SetVariable empStr,pos={114,67},size={250,17},title="file:"
	SetVariable empStr,help={"Filename of the empty beam file(s) to be used in the transmission calculation"}
	SetVariable empStr,fSize=10
	SetVariable empStr,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gEMP
	Button Trn_button_1,pos={5,91},size={90,20},proc=Trn_SetXYBoxButton,title="Set XY Box"
	Button Trn_button_1,help={"Sets the XY box to sum over"}
	Button Trn_button_2,pos={174,156},size={110,20},proc=Trn_SortFilesByDate,title="Sort by Date"
	Button Trn_button_2,help={"Sort the scattering and transmission files by creation date."}
	Button Trn_button_3,pos={174,186},size={110,20},proc=Trn_SortFilesByLabel,title="Sort by Label"
	Button Trn_button_3,help={"Sort the scattering and transmission files by label."}
	SetVariable Trn_setvar_1,pos={135,90},size={227,17},title="Box is "
	SetVariable Trn_setvar_1,help={"Box coordinates to sum over"},fSize=10
	SetVariable Trn_setvar_1,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gBox
	Button Trn_button_0,pos={1,1},size={70,20},proc=Trn_PickPathButton,title="Pick Path"
	Button Trn_button_0,help={"Select the folder containing the SANS data files"}
	Button Trn_button_9,pos={335,1},size={25,20},proc=ShowTransHelp,title="?"
	Button Trn_button_9,help={"Show the help file for calculating sample transmissions"}
	SetVariable Trn_setvar_0,pos={80,4},size={250,17},title="Path"
	SetVariable Trn_setvar_0,help={"Currently selected data path"},fSize=10
	SetVariable Trn_setvar_0,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gCatPathStr
	Button Trn_button_5,pos={5,186},size={161,20},proc=Trn_CalcAllFilesButton,title="Calculate All Files"
	Button Trn_button_5,help={"Calculate transmission and patch headers of ALL files in the Scattering File Table."}
	Button Trn_button_6,pos={295,215},size={67,20},proc=Trn_PanelDoneButtonProc,title="Done"
	Button Trn_button_6,help={"Close the panel when done calculating transmissions"}
	Button Trn_button_7,pos={67,32},size={214,20},proc=Trn_RefreshProc,title="List Files"
	Button Trn_button_7,help={"Generate or refresh the tables of files."}
	Button Trn_button_8,pos={5,156},size={161,20},proc=Trn_CalcSelectedFilesButton,title="Calculate Selected Files"
	Button Trn_button_8,help={"Calculate transmission and patch headers of selected files in the Scattering File Table."}
	Button Trn_button_10,pos={5,215}, size={161,20},proc=TotalTransButtonProc
	Button Trn_button_10 title="Calculate Total Trans"
	Button Trn_button_10 help={"Calculate transmission over the whole detector and patch headers of ALL files in the data folder."}
	Button setEmpForAll,pos={4,117},size={120,20},proc=FillEMPFilenameWSelection,title="Use EMP for ALL"
	Button setEmpForAll,help={"This button will set the file selected in the Transmission file table to be the empty beam file."}
	Button ClearTrans,pos={175,215},size={110,20},proc=ClearSelectedAssignments,title="Clear Selection"
	Button ClearTrans,help={"This button will set the file selected in the Transmission file table to be the empty beam file."}
EndMacro


Function TotalTransButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TotalTrans(ctrlName)
End


Proc ShowTransHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Calculate Transmissions]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End


//generates the file tables of scattering files and transmission files
//
// if the tables already exist, they will be updated
//
Proc Trn_RefreshProc(ctrlName) : ButtonControl
	String ctrlName
	BuildFileTables()
End

//shows a noteboox of help text describing how to calculate transmissions
// - better that the user read the igor or pdf file, but it's a victory to get
//users to read anything at all
//
Proc Trn_ShowHelpProc(ctrlName) : ButtonControl
	String ctrlName
	DisplayTransHelp()
End

//sorts the tables by date
//
Proc Trn_SortFilesByDate(ctrlName) : ButtonControl
	String ctrlName
	SortTransByDate()
End

//sorts the tables alphabetically by the sample label field
//
Proc Trn_SortFilesByLabel(ctrlName) : ButtonControl
	String ctrlName
	SortTransByLabel()
End

//button action procedure to select the local path to the 
//folder containing the RAW SANS data files
// - once the data folder is selected, all of the popup file menus are 
//forced to update with fresh file lists
//
Function Trn_PickPathButton(PathButton) : ButtonControl
	String PathButton
	
	//set the global string to the selected pathname
	Variable err
	err = PickPath()
	if(err)
		return(1)		//some problem with path or user cancelled, get out
	endif
	
	PathInfo/S catPathName
	String path = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:myGlobals:TransHeaderInfo:gCatPathStr = "no folder selected"
	else
		String/G root:myGlobals:TransHeaderInfo:gCatPathStr = path
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=Trans_Panel $"Trn_setvar_0"
	//Generate tables
	Execute "BuildFileTables()"
	
End

//button action function that asks the user to set the XY box to sum over
//for all transmission calculations
//
// requires the user to set the box coordinates with the marquee popup
//that wil properly set the keyword string, and write the values to the empty beam header
//
Function Trn_SetXYBoxButton(ctrlName) : ButtonControl
	String ctrlName

	String msgStr = "Select the Empty Beam File"
	String filename=""
	
	//get the filename from the popup menu
	//and construct a full path to it
	SVAR partialName = root:myGlobals:TransHeaderInfo:gEMP
	print partialName
	//get a valid file based on this partialName and catPathName
	String tempName = N_FindValidFilename(partialName)
	if(cmpstr(tempName,"")==0)
		//file not found, get out
		Abort "Empty beam file not found Trn_SetXYBoxButton(ctrlName)"
	Endif
	//name is ok, prepend path to tempName for read routine 
	PathInfo catPathName
	filename = S_path + tempName
	
	//read the file in - check for previous coordinates
	ReadHeaderAndData(filename,"RAW")
	//data is displayed here (go through the normal display steps, so all is created properly
	String/G root:myGlobals:gDataDisplayType="RAW"
	fRawWindowHook()
	
	// check the empty beam file for previously selected coordinates
	//if they exist, set the xy string , save the normalized counts somewhere
	//the value was written to an unused r*4 header analysis.factor (@b494)
	Variable refnum,x1,x2,y1,y2,err
	getXYBoxFromFile(filename,x1,x2,y1,y2)
	
	//read the real count value, assign to a global
	Variable/G root:myGlobals:gTransCts = getBoxCounts(filename)			//***NOTE this is NOT in the Trans sub-folder
	//
	if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
		//no region selected
		
		//add the empty beam file to work.SAM
		err = Raw_to_work_for_Ordela("SAM")
	
		//the calling macro must change the display type
		String/G root:myGlobals:gDataDisplayType="SAM"		//displayed data type is sam
	
		//data is displayed here
		fRawWindowHook()
	
		//prompt user to select box w/marquee
		DoAlert 0,"Select the region to sum with the Marquee"
	
		//from here the Marquee menu selection must handle the task of setting the box
		//and updating the information in the file header
	else
		// region already selected, just put up the values from the file header
		//allow user the option of overriding the current box region
		msgStr = "X1="+num2str(x1)+";"
		msgStr += "X2="+num2str(x2)+";"
		msgStr += "Y1="+num2str(y1)+";"
		msgStr += "Y2="+num2str(y2)+";"
		String textStr
		textStr = "Override current box  "+msgStr+" ?"
		DoAlert 1,textStr
		If((V_flag)==1)
			//get new box coordinates, same procedure as above
			//add the empty beam file to work.SAM
			err = Raw_to_work_for_Ordela("SAM")
	
			//the calling macro must change the display type
			String/G root:myGlobals:gDataDisplayType="SAM"		//displayed data type is sam
	
			//data is displayed here
			fRawWindowHook()
	
			//prompt user to select box w/marquee
			DoAlert 0,"Select the region to sum with the Marquee"
	
			//from here the Marquee menu selection must handle the task of setting the box
			//and updating the information in the file header
		else
			String/G root:myGlobals:TransHeaderInfo:gBox = msgStr
		Endif
	Endif
	
	UpdateBoxCoordinates()
	Return (0)
End


//button action function that assigns the selected empty beam file (run number only) 
//and the sample trnansmissionfile (run number only) to the popup list of  sample scattering
//files (ALL of the list items). Assignment is done by writing the integer run numbers of 
//trans files to the header of each of the  scattering files, in a batchwise processing
//of the popup list
//
//transmission are not calculated here - only the file numbers are set
//
//*********unused***********
//Function Trn_AssignAllFilesButton(ctrlName) : ButtonControl
//	String ctrlName
//
//	AssignTransFilesToData()
//		
//End

//button action procedure to calculate the transmission of all of the sample files in the
//sample popup list, based on the information in EACH sample header and in the empty beam file
//the box must be set properly in the empty beam file, AND the empty and trans
//run number must also be set properly in EACH scattering file, 
//If run numbers are not properly assigned, no trans is calculated and the 
//header is not modified
//
//The RAW data header of EACH sample file IS modified, with the newly calculated transmission
//
//not very friendly, but forces users to assign the files before continuing
//
Function Trn_CalcAllFilesButton(ctrlName) : ButtonControl
	String ctrlName

	//calculate the transmission and Patch the header (if possible)
	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Variable num_s_files = numpnts(S_GFilenames)
	AssignSelTransFilesToData(0,num_s_files-1)		//do all the files (points 0 to n-1, inclusive)
	CalcSelTransFromHeader(0,num_s_files-1)	
	
End

//for selected scattering files in the scattering table,
// the "Annn" association of trans file is written to the data file,
// the the transmission is actually calculated
//
Function Trn_CalcSelectedFilesButton(ctrlName) : ButtonControl
	String ctrlName
 
   Variable scatterTableExists
   scatterTableExists = WinType("ScatterFileTable")
   if (scatterTableExists != 0)
		GetSelection table,ScatterFileTable,1
		if(V_Flag != 0)
			AssignSelTransFilesToData(V_StartRow,V_EndRow)
			//calculate the transmission and Patch the header (if possible)
			CalcSelTransFromHeader(V_StartRow,V_EndRow)
		Else
			DoAlert 0,"No selection from Scattering Files table"
		Endif
   Else
		DoAlert 0,"No file selected from Scattering Files table or no Scattering Files table available"
   Endif
End

//
// I am not sure what the difference is inthe function of CalcTotalTrans and CalcWholeTrans ? 
// do they really do anything different?
// is it a useful calculation at all?
// 
Function TotalTrans(ctrlName) : ButtonControl
	String ctrlName
 
   Variable transTableExists
   transTableExists = WinType("TransFileTable")
   if (transTableExists != 0)
		GetSelection table,transFileTable,1
		if(V_Flag != 0)
			AssignTotalTransFilesToData(V_StartRow,V_EndRow)
			//calculate the transmission and Patch the header (if possible)
			CalcTotalTrans(V_StartRow,V_EndRow)
			CalcWholeTrans(V_StartRow,V_EndRow)
		Else
			DoAlert 0,"No selection from Trans Files table"
		Endif
   Else
		DoAlert 0,"No file selected from Trans Files table or no Trans Files table available"
   Endif
End


//simple button procedure to close the trans panel
// - automatically kills the two tables as well
//
Function Trn_PanelDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// this button will make sure all files are closed 
	//and close the panel
	
	Close/A
	DoWindow/K Trans_Panel
	DoWindow/K ScatterFileTable
	DoWindow/K TransFileTable
End


//function to update the box coordinates of the file selected as the 
//empty beam file - takes the file that is currently popped from the list
//reads the 4 "analysis" integers that hold the box coordinates
//resets the globals string that is displayed with the new values
//should be called whenever the "empty" popup is popped, to ensure
//that current header information is displayed
//
Function UpdateBoxCoordinates()

	//construct a full name, and read in the label from the file
	//and set the global
	String textstr=""
	ControlInfo empStr
	SVAR item = root:myGlobals:TransHeaderInfo:gEMP
	String tempName = N_FindValidFilename(item)
	if(cmpstr(tempName,"")==0)
		//file not found, get out
		Abort "Empty beam file not found UpdateBoxCoordinates(ctrlName)"
	Endif
	//name is ok, prepend path to tempName for read routine 
	PathInfo catPathName
	String filename = S_path + tempName
	
	Variable refnum,x1,x2,y1,y2,err
	GetXYBoxFromFile(filename,x1,x2,y1,y2)
	
	//and update the global string
	String msgStr=""
	msgStr = "X1="+num2str(x1)+";"
	msgStr += "X2="+num2str(x2)+";"
	msgStr += "Y1="+num2str(y1)+";"
	msgStr += "Y2="+num2str(y2)+";"
	
	String/G root:myGlobals:TransHeaderInfo:gBox = msgStr
	
	ControlUpdate/W=Trans_panel Trn_setvar_1
End

//crude procedure to display a notebook of help information for users
//
Proc DisplayTransHelp()
	String nb = "Notebook0"
	NewNotebook/N=$nb/F=1/V=1/W=(342,302,868,674) as "Notebook0:Transmission Help"
	Notebook $nb defaultTab=36, statusWidth=238, pageMargins={36,72,36,72}
	Notebook $nb showRuler=1, rulerUnits=1, updating={1, 3600}
	Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Geneva",10,0,(0,0,0)}
	Notebook $nb ruler=Normal; Notebook $nb  justification=1, fSize=14, fStyle=1, text="Transmission Help\r"
	Notebook $nb ruler=Normal, fSize=-1, fStyle=-1, text="\r"
	Notebook $nb text="This panel allows quick and easy calculation of sample transmission. The neutron transmission of a sampl"
	Notebook $nb text="e must be calculated and entered into the header of each sample scattering file before proper background"
	Notebook $nb text=" corrections or absolute scaling can be done.\r"
	Notebook $nb text="\r"
	Notebook $nb text="During data collection, you measured an empty beam  - that is a measurement with heavy attenuation of th"
	Notebook $nb text="e neutron beam and the beamstop mover out of line with the direct beam. Then without changing the attenu"
	Notebook $nb text="ation or replacing the beamstop, you put a sample in the beam, and repeated the measurement (a sample tr"
	Notebook $nb text="ansmission measurement). The neutron transmission of the sample is simply the ratio of the number of neu"
	Notebook $nb text="tron counts from the sample transmission measurement normalized by the number of neutron counts from the"
	Notebook $nb text=" empty beam measurement. In this way, each sample transmission file is \"linked\" to the same empty beam t"
	Notebook $nb text="ransmission file.\r"
	Notebook $nb text="\r"
	Notebook $nb text="This calculated transmission value must be entered into the header of the sample scattering measurement "
	Notebook $nb text="- that is the measurement of the sample with the beamstop covering the primary (transmitted) beam, and n"
	Notebook $nb text="o (or few) attenuators in place. In this way, the sample transmission file is \"linked\" to its correspond"
	Notebook $nb text="ing sample scattering file. This panel allows you to set up the links and calculate the transmission.Tra"
	Notebook $nb text="nsmisison values are automatically patched to the scattering file headers as they are calculated.\r"
	Notebook $nb text="\r"
	Notebook $nb text="To Calculate Transmissions:\r"
	Notebook $nb text="\r"
	Notebook $nb text="1) Click \"List Files\" to get two lists (tables) - one of all the sample scattering files in the folder, "
	Notebook $nb text="and one of the transmission files.\r"
	Notebook $nb text="\r"
	Notebook $nb text="2) Select the region of the detector to sum over from the empty beam transmission file. Do theis by clic"
	Notebook $nb text="king on the filename of the empty beam transmision file (from the TransmissionFiles window, in the blue "
	Notebook $nb text="\"T_Filenames\" column). Return to the panel, and click the \"set EMP file\" button\", and the filename shoul"
	Notebook $nb text="d appear in the file box. The \"Box is\" field should have zeros for the x and y coordinates. Click the \"S"
	Notebook $nb text="et XY Box\" button. The empty beam file will be displayed, and you will be instructed to select the regio"
	Notebook $nb text="n to sum with the marquee. On the data, click and drag a rectangle that encompasses the primary beam. Mo"
	Notebook $nb text="ve the cursor inside the selection, to get an \"upside-down hat\" cursor. Click to get a menu, and near th"
	Notebook $nb text="e bottom, select \"Set XY Box Coords\". The pixel values should be updated to the Transmission panel, and "
	Notebook $nb text="are written to the empty beam header for future calculations. Note that the marquee selection can also b"
	Notebook $nb text="e used to measure the beam center, or centroid of any selected region.\r"
	Notebook $nb text="\r"
	Notebook $nb text="3) Now you need to \"link\" the ", fStyle=2, text="sample", fStyle=-1, text=" transmission files to the "
	Notebook $nb fStyle=2, text="empty", fStyle=-1, text=" ", fStyle=2, text="beam", fStyle=-1
	Notebook $nb text=" transmission file. Do this in the TransmissionFiles window by selecting the filename (in the blue T_Fil"
	Notebook $nb text="enames column) and pasing it to the corresponding row(s) in the T_EMP_Filenames column. This links the e"
	Notebook $nb text="mpty beam transmission with the sample transmission file. Do this for every sample transmission file.\r"
	Notebook $nb text="\r"
	Notebook $nb text="4) Now you need to link the sample ", fStyle=2, text="transmission", fStyle=-1
	Notebook $nb text=" file to the sample ", fStyle=2, text="scattering", fStyle=-1
	Notebook $nb text=" file. Do this by selecting the name of the transmission file (from the blue T_Filenames column) and pas"
	Notebook $nb text="ting it into the corresponding row of the S_TRANS_Filenames column of the ScatteringFiles window. This l"
	Notebook $nb text="inks the scattering file to its corresponding sample transmission file. This for all of the sample scatt"
	Notebook $nb text="ering files.\r"
	Notebook $nb text="\r"
	Notebook $nb text="5) Calculate the transmissions (and automatically write the transmission value to the satterng file head"
	Notebook $nb text="er) by clicking \"Calculate All Files\" from the Transmission Panel. The results will be printed to the co"
	Notebook $nb text="mmand window at the bottom of the screen. Any improperly assigned files will be listed. For example, blo"
	Notebook $nb text="cked beam scattering files will return an error, since the transmssion known to be zero, and is not meas"
	Notebook $nb text="ured (and no files are \"linked\"). Rather than calculating the transmission of all of the files,  a range"
	Notebook $nb text=" of S_Filenames can be selected, then calculated by clicking \"Calculate Selected Files\".\r"
	Notebook $nb text="\r"
	Notebook $nb text="By default the lists are sorted by run number (= chronological). In some cases it may be easier to sort "
	Notebook $nb text="by the sample label to group several of the same sample scattering files collected at different sample-t"
	Notebook $nb text="o-detector distances. Its utility depends, of course, on how consistent and unique your sample labels ar"
	Notebook $nb text="e.\r"
	Notebook $nb text="\r"
	Notebook $nb text="The \"links\" are stored in the corresponding files, and wil be re-generated when the lists are re-generat"
	Notebook $nb text="ed. Unassigned links will appear as blank elements in the T_EMP_Filenames or S_TRANS_Filenames columns.\r"
	Notebook $nb text="\r"
	Notebook $nb, selection={startOfFile,startOfFile}
	Notebook $nb text="\r"
End



//*******************
//************
//   A simple panel to allow users of the NG1 SANS instrument to make their
// transmission files "look" like a transmission measurement to the data reduction
// program. Transmission files are designated by an x-position of the beamstop of
// < -5 (cm). this simple procedure sets xpos=-10 for individual files. files 
// con be "un-converted", which set the xpos=0.
// 1/30/01 SRK
//************

Proc TransformToTransFile()
	Variable/G root:myGlobals:gConvTrans=1
	DoWindow/F Convert_to_Trans
	if(V_flag==0)
		Convert2Trans()
	endif
End

//fname must be the full path and name for the file
Function ChangeBSXPos(fname,xpos)
	String fname
	Variable xpos
	
	Variable start
	//x-position starts after byte 368 in VAX files
	WriteBSXPosToHeader(fname,xpos)
	return(0)
End

//sets the beamstop position to zero NOT the original position
Function UnConvertButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	//Print "UnConvert"
	String fullname=""
	ControlInfo fileNum
	Variable num = V_Value	//run number to find
	
	fullname = N_FindFileFromRunNumber(num)
	Print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "Unconvert - file not found"
	else
		//Print "Unconvert",fullname
		ChangeBSXPos(fullName,0)
	Endif
	return(0)
End

//button procedure to do the conversion 
// writes fake beamstop position to the data file
//
Function ConvertButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String fullname=""
	ControlInfo fileNum
	Variable num = V_Value	//run number to find
	
	fullname = N_FindFileFromRunNumber(num)
	print fullname
	//report error or change the file
	if(cmpstr(fullname,"")==0)
		Print "Convert - file not found"
	else
		//Print "Convert",fullname
		ChangeBSXPos(fullName,-10)
	Endif
	return(0)
End

//simple panel recreation macro
//
Proc Convert2Trans()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(434,74,671,216) /K=1
	DoWindow/C Convert_to_Trans
	SetDrawLayer UserBack
	DrawText 18,22,"Convert files to be recognized"
	DrawText 43,39,"as transmission files"
	SetVariable fileNum,pos={43,58},size={130,15},title="File Number"
	SetVariable fileNum,limits={1,Inf,1},value=root:myGlobals:gConvTrans
	SetVariable fileNum,help={"Sets the run number of the file that is to be converted"}
	Button ConvButton,pos={73,79},size={80,20},proc=ConvertButtonProc,title="Convert"
	Button ConvButton,help={"Converts the chosen file to appear as a transmission file"}
	Button UndoButton,pos={68,105},size={90,20},proc=UnConvertButtonProc,title="Un-Convert"
	Button UndoButton,help={"Converts the chosen file to appear as a scattering file"}
EndMacro

//
// The proper list of transmission files MUST be present in the Patch Popup list
// -- using Grep for "trans" is a possible choice
//
// testing only TODO_10m -- a quick fix for the missing BS xpos to identify trans
Function BatchConvert_10mTrans(xPos)
	Variable xPos			//pass -10 to make it trans, pass 0 to make it scattering again
	
	//this will change (checked) values in ALL of the headers in the popup list
	SVAR list = root:myGlobals:Patch:gPatchList
	String partialName="", tempName = ""
	Variable numitems,ii,ok
	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	ii=0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		   
		//get a valid file based on this partialName and catPathName
		tempName = N_FindValidFilename(partialName)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
	
		//make sure the file is really a RAW data file
		ok = N_CheckIfRawData(tempName)
		if (!ok)
		   Print "this file is not recognized as a RAW SANS data file = ",tempName
		else
		   //go write the changes to the file
		   ChangeBSXPos(tempName,xPos)
		Endif
		
		ii+=1
	while(ii<numitems)
	
End

/////
//  A quick way to fill all the T_EMP_Filenames with the selected empty beam file
// Note that you must go back and clear or reassign any files that are special cases
//
// IMPORTANT - this will overwrite any other file assignments (typically not a problem
// if you  are using only one wavelength)
//
/////
// March 2010:
// changed from the previous beta menu operation, now uses the text from the file name box
// rather than requiring a selection on the table (since you just set the box...)
//
Function FillEMPFilenameWSelection(ctrlName)
	String ctrlName
	
//	GetSelection table,TransFileTable,3
//	Variable row=V_startRow			//ony need the selected row, we know the column names and location

	SVAR empName = root:myGlobals:TransHeaderInfo:gEMP
	if(strlen(empName)==0 || cmpstr(empName,"no path selected")==0)
		DoAlert 0,"Please select and set an empty beam file"
		return(0)
	endif
	Wave/T fw = root:myGlobals:TransHeaderInfo:T_FileNames		//trans files
	Wave/T ew = root:myGlobals:TransHeaderInfo:T_EMP_FileNames		//empty beam reference files
	
	ew[] = empName
	
	return(0)
End

//given a selection of the SAMPLE files, try to find the corresponding transmission file
//
Function GuessTransFile(charsToUse,row)
	Variable charsToUse,row			//number of characers to use from the beginning of the label, and the row of the sample file
	
//	GetSelection table,ScatterFileTable,3
//	Variable row=V_startRow			//ony need the selected row, we know the column names and location
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	
	Variable num,ii,found
	String samStr = "",testStr=""
	
	samStr = (sw[row])[0,charsToUse-1]		//string to try and match
	samStr += "*"
//	Print samStr
	num=numpnts(tw)
	ii=0
	do
		testStr=tw[ii]
		found = stringmatch(testStr, samStr )
		if(found == 1)
			Print "Match Found at:  ",samStr,tnam[ii],tw[ii]
			snam[row] = tnam[ii]			//write the file name into the table
			return(0)	
		endif
		ii+=1
	while(ii<num)
	
	//method 2
//	samStr = (sw[row])[0,charsToUse-1]		//string to try and match
////	Print samStr
//	num=numpnts(tw)
//	ii=0
//	do
//		testStr=tw[ii]
//		found = strsearch(testStr,samStr,0)		//start from zero, Need Igor 5 to allow 4th parameter to ignore case
//		if(found != -1)
//			Print "Match Found at:  ",samStr,tnam[ii],tw[ii]
//			snam[row] = tnam[ii]			//write the file name into the table
//			return(0)	
//		endif
//		ii+=1
//	while(ii<num)
	
	Print "No Match found"
	return(0)
End

//given a single transmission file, try to find the corresponding scattering file(s)
//
// apply TWO criteria
// (1) the label must match "well enough"
// (2) the wavelength must be the same "enough", given the unnecessary precision reported by ICE
//
// (for example, "6" can be anything from 6.0008 to 6.0020 in a recent experiment)
//
// passes the matching rows in the sample table back
//
Function GuessTransToScattFiles(charsToUse,row,matchRows)
	Variable charsToUse,row			//number of characers to use from the beginning of the label, and the row of the transmission file
	Wave matchRows		//rows where (potential) matches found. initially zero points
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	Wave sLam = root:myGlobals:TransHeaderInfo:S_Lambda		//Scattering file wavelength
	Wave tLam = root:myGlobals:TransHeaderInfo:T_Lambda		//Transmission file wavelength
	
	Variable num,ii,found,tolerance=0.01		//0.01 = 1% tolerance
	String transStr = "",testStr=""
	
	transStr = (tw[row])[0,charsToUse-1]		//string to try and match
	transStr += "*"
	
	//loop over ALL sample files
	num=numpnts(sw)
	ii=0
	do
		testStr=sw[ii]
		found = stringmatch(testStr, transStr )
		if( (found == 1) && (abs(sLam[ii] - tLam[row]) < tolerance) )		// both must match
			Print "Match Found at:  ",transStr,snam[ii],sw[ii]
			InsertPoints numpnts(matchRows), 1, matchRows
			matchRows[numpnts(matchRows)-1] = ii
		endif
		ii+=1
	while(ii<num)
	
	//method 2 *UNTESTED*
//	transStr = (tw[row])[0,charsToUse-1]		//string to try and match
//	num=numpnts(sw)
//	ii=0
//	do
//		testStr=sw[ii]
//		found = strsearch(testStr,transStr,0,2)		//start from zero, ignore case
//		if(found != -1)
//			Print "Match Found at:  ",transStr,snam[ii],sw[ii]
//			InsertPoints numpnts(matchRows), 1, matchRows
//			matchRows[numpnts(matchRows)-1] = ii
////			snam[ii] = tnam[row]			//write the file name into the table
//		endif
//		ii+=1
//	while(ii<num)
	
//	Print "No Match found"
	return(0)
End

//get a single selection from the Trans table
// find all of the matching scattering files (rows)
// ask the user if the selections are OK
// if NOT OK, do nothing
// if OK: make the assignments, and immediately calculate the transmission
//
Function fGuessTransToScattFiles(numChars)
	Variable numChars
	
	Variable ii,row
	Variable transTableExists
	
	Variable/G root:myGlobals:TransHeaderInfo:gNumMatchChars = numChars
	SVAR gMatchSamStr = root:myGlobals:TransHeaderInfo:gMatchingSampleFiles
	
	Make/O/D/N=0 root:myGlobals:TransHeaderInfo:matchRows
	Wave matchRows=root:myGlobals:TransHeaderInfo:matchRows
	
   transTableExists = WinType("TransFileTable")
   if (transTableExists != 0)
		GetSelection table,transFileTable,1	
		row = V_startRow
		GuessTransToScattFiles(numChars,row,matchRows)
	else
		Print "Transmission->Scattering File table is not open"
		return (1)
	endif
	
	Variable num=numpnts(matchRows)
	String result="",tmpStr
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	Wave/T samfile = root:myGlobals:TransHeaderInfo:S_FileNames	//Scattering file name

	//// set up as a list box
	Make/O/T/N=(num,4) root:myGlobals:TransHeaderInfo:T_ListWave=""
	Make/O/D/N=(num,4,2) root:myGlobals:TransHeaderInfo:T_selWave
	Make/O/T/N=4 root:myGlobals:TransHeaderInfo:T_titles					// 4 rows to match 4-column ListWave
	Make/O/W/U/N=(2,3) root:myGlobals:TransHeaderInfo:T_Colors
	WAVE/T ListWave = root:myGlobals:TransHeaderInfo:T_ListWave
	WAVE selWave = root:myGlobals:TransHeaderInfo:T_selWave
	WAVE/T titles = root:myGlobals:TransHeaderInfo:T_titles
	WAVE colors = root:myGlobals:TransHeaderInfo:T_Colors


	colors[][] = 0
	colors[0][] = 65000
	colors[1][] = 60000


	// can do fancy formatted string with ...
	//"asdf* matches file: \\f01filen\\f00 \\K(52428,1,1)\\f01afdsfdd\\f00\\K(0,0,0)asdfasdfs"

	for(ii=0;ii<num;ii+=1)
		sprintf tmpStr,"\\f01\\K(52428,1,1)%s\\K(0,0,0)\\f00* Matches file: \\f01%s\\f00 | \\K(52428,1,1)\\f01%s\\f00\\K(0,0,0)%s\r",(tw[row])[0,numChars-1],samfile[matchRows[ii]],(sw[matchRows[ii]])[0,numchars-1],(sw[matchRows[ii]])[numchars,59]
		result += tmpStr
		listWave[ii][1] = (tw[row])[0,numChars-1] + "*" + (tw[row])[numChars,59]
		listWave[ii][2] = samfile[matchRows[ii]]
		listWave[ii][3] = (sw[matchRows[ii]])[0,numchars-1] + (sw[matchRows[ii]])[numchars,59]  // ??
	endfor
	
	
	if(cmpstr(result,"")==0)
		result = "No match found for "+ (tw[row])[0,numChars-1]
	endif
	
//	Print result
	Print "*******"
	
	String/G root:myGlobals:TransHeaderInfo:gResultStr = result
	selWave[][][] = 0
	selWave[][0][] = 2^5	 + 2^4		//if 2^4 also, it's selected  --- if((val & 2^4) != 0), then the bit is set
	
	selWave[][][1]= round(p/2-trunc(p/2))					// change the color index values
	SetDimLabel 2,1,backColors,selWave

	titles[0] = "Keep Match?"
	titles[1] = "Match String"
	titles[2] = "Matching Sample File"
	titles[3] = "Matching Sample Label"
	

	
	DoWindow/F ConfirmGuess		//if being called recursively, the panel is already up
	if(V_flag==1)
		TitleBox title0,pos={9,5},variable=root:myGlobals:TransHeaderInfo:gResultStr
	else
		NewPanel /W=(600,44,1200,270) as "Confirm Guess"
		DoWindow/C ConfirmGuess

		ListBox list0,pos={1,2},size={580,180},listWave=ListWave,selWave=selWave,colorWave=colors
		ListBox list0,titleWave=titles,widths={70,180,150,180}
			
//		TitleBox title0,pos={15,8},size={560,32}
//		TitleBox title0,variable= root:myGlobals:TransHeaderInfo:gResultStr
		
		Button button0,pos={240,190},size={190,20},proc=DoAssignTransButtonProc,title="Assign Transmission Files"
		Button button1,pos={10,190},size={100,20},proc=DoTryAgainMoreButtonProc,title="Try Again (+)"
		Button button2,pos={120,190},size={100,20},proc=DoTryAgainFewerButtonProc,title="Try Again (-)"
		Button button3,pos={450,190},size={70,20},proc=SkipTransButtonProc,title="Skip"
	endif
	
	PauseForUser ConfirmGuess

// figure out from the return code what the user did...
// 1 = OK, accept guess (assign, and calculate immediately)
// 2 = try again (+) // NO - not an "exit" code
// 3 = try again (-)	//NO - not an "exit" code
// 0 = cancel, don't do anything, drop out of case
	NVAR guessOK = root:myGlobals:TransHeaderInfo:GuessOK
	
	// switch here...
	switch(guessOK)	// numeric switch
		case 1:		
			// accept guess (assign, and calculate immediately)
			gMatchSamStr=""
			num=numpnts(matchRows)		//this may have changed
			for(ii=0;ii<num;ii+=1)
				if((selWave[ii][0] & 2^4) != 0)			//box is checked, make the assignment for this file
					snam[matchRows[ii]] = tnam[row]
					AssignSelTransFilesToData(matchRows[ii],matchRows[ii])
					CalcSelTransFromHeader(matchRows[ii],matchRows[ii])		//does only that sample file
					gMatchSamStr += samfile(matchRows[ii]) + ";"			// this is for later, when trying to guess whish sample files to combine
				endif
			endfor			
			break						
		case 2:	//try again (with more characters)
			// not an exit code, does nothing
			break
		case 3:	//try again (with fewer characters)
			// not an exit code, can't do anything
			break
		case 0:	// cancel
			gMatchSamStr = ""
			// do nothing
			break
		default:							
			//	do nothing					
	endswitch
	
	return(0)
End

// a hook attached to the Transmission Files Table
// given a single selected Trans File, popup gives choices
// to guess using "n" characters, then dispatch accordingly
Function GuessFromTableHook(infoStr)
	String infoStr
	String event= StringByKey("EVENT",infoStr)
//	Print "EVENT= ",event

	String menuStr=""
	menuStr += "Guess using N characters;"
	menuStr += "Guess using 3 characters;"
	menuStr += "Guess using 6 characters;"
	menuStr += "Guess using 9 characters;"
	menuStr += "Guess using 12 characters;"
	menuStr += "Guess using 15 characters;"
	menuStr += "Guess using 18 characters;"
	menuStr += "Guess using 21 characters;"
	menuStr += "Guess using 24 characters;"
	
	strswitch(event)
		case "mousedown":
			Variable xpix= NumberByKey("MOUSEX",infoStr)
			Variable ypix= NumberByKey("MOUSEY",infoStr)
			Variable modif= NumberByKey("MODIFIERS",infoStr)
			//print modif
			if(modif & 2^1)		//bit 1 set, shift key is down
				PopupContextualMenu/C=(xpix, ypix) menuStr
				strswitch(S_selection)
					case "Guess using 3 characters":
						fGuessTransToScattFiles(3)
						break
					case "Guess using 6 characters":
						fGuessTransToScattFiles(6)
						break
					case "Guess using 9 characters":
						fGuessTransToScattFiles(9)
						break
					case "Guess using 12 characters":
						fGuessTransToScattFiles(12)
						break
					case "Guess using 15 characters":
						fGuessTransToScattFiles(15)
						break
					case "Guess using 18 characters":
						fGuessTransToScattFiles(18)
						break
					case "Guess using 21 characters":
						fGuessTransToScattFiles(21)
						break
					case "Guess using 24 characters":
						fGuessTransToScattFiles(24)
						break
					case "Guess using N characters":
						Variable num=10
						Prompt num, "Number of characters"
						DoPrompt "Enter the number of characters to match", num
						if (V_Flag)
							break	//user cancel, do nothing
						endif
						fGuessTransToScattFiles(num)
						break
				endswitch		//on selection
			endif
	endswitch	// on event
	
	return 0
End

// sets a flag if the user thinks that the guess was correct, and wants to use the
// identified files for the transmission
Function DoAssignTransButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//Print "Assigned stuff, and left."
			Variable/G root:myGlobals:TransHeaderInfo:GuessOK= 1
			DoWindow/K ConfirmGuess
			break
	endswitch


	return 0
End

// files are wrong, let the user try it again
// sets a flag, nothing else
Function DoTryAgainMoreButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable row,ii,num
	String tmpStr
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	Wave/T samfile = root:myGlobals:TransHeaderInfo:S_FileNames	//Scattering file name
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable/G root:myGlobals:TransHeaderInfo:GuessOK= 2
			NVAR numChars = root:myGlobals:TransHeaderInfo:gNumMatchChars
			SVAR resultStr = root:myGlobals:TransHeaderInfo:gResultStr

			numChars += 1

			Make/O/D/N=0 root:myGlobals:TransHeaderInfo:matchRows
			Wave matchRows=root:myGlobals:TransHeaderInfo:matchRows

			WAVE/T ListWave = root:myGlobals:TransHeaderInfo:T_ListWave
			WAVE selWave = root:myGlobals:TransHeaderInfo:T_selWave
			WAVE/T titles = root:myGlobals:TransHeaderInfo:T_titles
		
		   //transTableExists = WinType("TransFileTable")
   		//if (transTableExists != 0)
			GetSelection table,transFileTable,1	
			row = V_startRow
			GuessTransToScattFiles(numChars,row,matchRows)
		
			num=numpnts(matchRows)
			
			//Redimension the list box waves
			Redimension/N=(num,4) ListWave
			Redimension/N=(num,4,2) selWave
			ListWave = ""
			selWave[][][] = 0

			selWave[][0][] = 2^5 + 2^4

			selWave[][][1]= round(p/2-trunc(p/2))					// change the color index values

			resultStr = ""
			for(ii=0;ii<num;ii+=1)
				sprintf tmpStr,"\\f01\\K(52428,1,1)%s\\K(0,0,0)\\f00* Matches file: \\f01%s\\f00 | \\K(52428,1,1)\\f01%s\\f00\\K(0,0,0)%s\r",(tw[row])[0,numChars-1],samfile[matchRows[ii]],(sw[matchRows[ii]])[0,numchars-1],(sw[matchRows[ii]])[numchars,59]
				resultStr += tmpStr
				listWave[ii][1] = (tw[row])[0,numChars-1] + "*" + (tw[row])[numChars,59]
				listWave[ii][2] = samfile[matchRows[ii]]
				listWave[ii][3] = (sw[matchRows[ii]])[0,numchars-1] + (sw[matchRows[ii]])[numchars,59]  // ??
			endfor
	
			if(cmpstr(resultStr,"")==0)
				resultStr = "No match found for "+ (tw[row])[0,numChars-1]
			endif		
			
//			DoWindow/K ConfirmGuess
			//Print "Try Again"
			break
	endswitch
	
	return 0
End

// files are wrong, let the user try it again
// sets a flag, nothing else
Function DoTryAgainFewerButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable row,ii,num
	String tmpStr
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	Wave/T samfile = root:myGlobals:TransHeaderInfo:S_FileNames	//Scattering file name
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable/G root:myGlobals:TransHeaderInfo:GuessOK= 3
			
			NVAR numChars = root:myGlobals:TransHeaderInfo:gNumMatchChars
			SVAR resultStr = root:myGlobals:TransHeaderInfo:gResultStr

			numChars -= 1

			Make/O/D/N=0 root:myGlobals:TransHeaderInfo:matchRows
			Wave matchRows=root:myGlobals:TransHeaderInfo:matchRows

			WAVE/T ListWave = root:myGlobals:TransHeaderInfo:T_ListWave
			WAVE selWave = root:myGlobals:TransHeaderInfo:T_selWave
			WAVE/T titles = root:myGlobals:TransHeaderInfo:T_titles
		
		   //transTableExists = WinType("TransFileTable")
   		//if (transTableExists != 0)
			GetSelection table,transFileTable,1	
			row = V_startRow
			GuessTransToScattFiles(numChars,row,matchRows)
		
			num=numpnts(matchRows)

			//Redimension the list box waves
			Redimension/N=(num,4) ListWave
			Redimension/N=(num,4,2) selWave
			ListWave = ""
			selWave[][][] = 0

			selWave[][0][] = 2^5 + 2^4

			selWave[][][1]= round(p/2-trunc(p/2))					// change the color index values

			resultStr = ""
			for(ii=0;ii<num;ii+=1)
				sprintf tmpStr,"\\f01\\K(52428,1,1)%s\\K(0,0,0)\\f00* Matches file: \\f01%s\\f00 | \\K(52428,1,1)\\f01%s\\f00\\K(0,0,0)%s\r",(tw[row])[0,numChars-1],samfile[matchRows[ii]],(sw[matchRows[ii]])[0,numchars-1],(sw[matchRows[ii]])[numchars,59]
				resultStr += tmpStr
				listWave[ii][1] = (tw[row])[0,numChars-1] + "*" + (tw[row])[numChars,59]
				listWave[ii][2] = samfile[matchRows[ii]]
				listWave[ii][3] = (sw[matchRows[ii]])[0,numchars-1] + (sw[matchRows[ii]])[numchars,59]  // ??
			endfor
	
			if(cmpstr(resultStr,"")==0)
				resultStr = "No match found for "+ (tw[row])[0,numChars-1]
			endif		
//			DoWindow/K ConfirmGuess
			//Print "Try Again"
			break
	endswitch
	
	return 0
End


// cancel, skip this set of trans
Function SkipTransButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//just kill the panel, don't do anything
			Variable/G root:myGlobals:TransHeaderInfo:GuessOK= 0
			DoWindow/K ConfirmGuess
			break
	endswitch
	
	return 0
End

Function GuessAllTransFiles(numChars)
	Variable numChars
	
	if(WinType("ScatterFileTable") ==0 )
		return(1)
	endif
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Variable ii,num=numpnts(sw)
	
	for(ii=0;ii<num;ii+=1)
		GuessTransFile(numChars,ii)
	endfor
	
	return(0)
End

Function fGuessSelectedTransFiles(numChars)
	Variable numChars
	
	Variable ii
	Variable scatterTableExists
   	scatterTableExists = WinType("ScatterFileTable")
   	if (scatterTableExists != 0)
		GetSelection table,ScatterFileTable,1	
		for(ii=V_StartRow;ii<=V_EndRow;ii+=1)
			GuessTransFile(numChars,ii)
		endfor
	else
		Print "Transmission->Scattering File table is not open"
	endif
	return(0)
End

// now a button on the Transmission Panel
Function ClearSelectedAssignments(ctrlName)
	String ctrlName

	/// old way, from the menu - takes the selection from the top window, have it now return the top table.
//	String winStr = WinList("*", ";", "WIN:" )		//returns the top window (with a trailing semicolon!)
	String winStr = WinName(0,2,1)			//returns the top visible table
	Variable scatterTableExists, transTableExists
//	Print winStr
   	scatterTableExists = cmpstr(winStr,"ScatterFileTable")
   	if (scatterTableExists == 0)
		GetSelection table,ScatterFileTable,1	
		fClearSelectedAssignments(V_startRow,V_endRow,1)
	endif
	
	transTableExists = cmpstr(winStr,"TransFileTable")
   	if (transTableExists == 0)
		GetSelection table,TransFileTable,1	
		fClearSelectedAssignments(V_startRow,V_endRow,2)
	endif
	
///////// new method, presents a clunky dialog - don't use this way unless I absolutely need to
//	Variable whichTable=1
//	Prompt whichTable,"Which Table?",popup,"Transmission Files;Scattering Files;"
//	DoPrompt "Which Selection to Clear",whichTable
//	if (V_Flag)
//		return 0									// user canceled
//	endif
//
//	if (whichTable == 1)		//the Transmission Table
//		GetSelection table,TransFileTable,1	
//		fClearSelectedAssignments(V_startRow,V_endRow,2)
//	else
//		//the Scattering Files table
//		GetSelection table,ScatterFileTable,1	
//		fClearSelectedAssignments(V_startRow,V_endRow,1)
//	endif
	return(0)
End