#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// RTI clean


//// a bunch of test functions to try to automate data reduction
//
// OCT 2014
//
//
//
//
//
// 1) start with gathering some basic information
// 		AskForConfigurations()
//
// 2) then sort the configurations from low Q to high Q
// 		SortConfigs()
//
//
// 3) fill in the other files for the configuration. Currently a manual operation
//
//
// 4) from the matrix of file numbers and some default choices,
// save (n) configurations as config_n, to match row (n) of the matrix
//
// -- panel must be open
//		ReductionProtocolPanel()
//		FillInProtocol(index) -- need to set the ABS parameters before saving
//		--save the protocol (I pick the name)	
//		Auto_SaveProtocol(index)
//
//	---- Run as:
//		Auto_FillSaveProtocols()
//
// 5) calculate all of the transmissions
// -- start by opening the Transmission panel
// -- list all of the files
// then:
// - for each empty beam file:
//		setXYBox (writes out box and counts to the file)
// 		check if there are transmission measurements at this config (SDD && lam)
//			if so, this is the empty beam
//				so try to guess the scattering files and calc transmission
//
//			go get another transmission at this configuration
//
//		go get another empty beam file
//
//	- at the end, search through all of the scattering files. look at
// the S_Transmission wave for: T=1 (be sure these are blocked beam) and search for
//  T > 1, as these are wrong.
//
//	-- may need user intervention if things go wrong.
//
//	---- to Run:
//		Auto_Transmission()
// then
//		ListFiles_TransUnity()
//		ListFiles_TransTooLarge()
//
//
//
// 6) reduce all of the data at each configuration
//
// - open the MRED panel
// - for each configuration
// - pick the configuration
// - get the SDD, and the list of scattering files
// - set the list and reduce all files
// - when saving the files, can I enforce a prefix C0_, C1_etc. on the files?
//
// ---- Run As:
//    Auto_MRED()
//
//
// 7) figure out how to combine the data
//
// -- get listings of what I think I should be combining - this is saved from the transmission assignment
// (default trim of data points for overlap, no rescaling)
//
//
// -- look for the beamstop shadow at the beginning of the file
// -- trim a default 5? 10? from the high Q end
//
// -- then just concatentate and sort.
//
//	---- Run As:
//			Auto_NSORT(tableOnly=1)		 to allow editing of the list of files and names
//			Auto_NSORT(tableOnly=0)		does the combination
//
//
///////////////////////////////////
//
// TODO 
//
//
// 		--properly generate the help file (reformat), link it to the help button, and get it into the SANS reduction 
//				help file.
//		-- make a better entry point from the Macros menu, and the SANS menu
//
//		-- may want to allow for some user feedback in NSORT in selecting the exact points to keep
//       this is still a step where human judgement is rather useful.
//     --  make it easier to edit the NSORT table. may be helpful to see the sample labels. This was
//      clearly the case with 4 configs (one lens) since they fell in different piles during transmission
//      calculation, so they did not appear together for combining files.
//
//




///////// A simple panel so I don't have to run the commands
//
// --there is nothing to initialize
//


Proc Auto_Reduce_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1323,334,1574,663) /K=1
	DoWindow/C AutoReduce
	ModifyPanel cbRGB=(26205,52428,1)
	SetDrawLayer UserBack
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,28,"(1)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,68,"(2)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,108,"(3)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,148,"(4)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 27,174,"(4.1)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 27,193,"(4.2)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,228,"(5)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 7,269,"(6)"
	SetDrawEnv fname= "Monaco",fstyle= 1
	DrawText 27,295,"(6.1)"
	SetDrawEnv fstyle= 1
	SetDrawEnv save

	Button button0,pos={35,10},size={150,20},proc=AutoAskForConfigButton,title="Ask for Config"
	Button button1,pos={35,50},size={150,20},proc=AutoSortConfigButton,title="Fill Config"
	Button button2,pos={35,90},size={150,20},proc=AutoFillProtocolButton,title="Fill Protocols"
	Button button3,pos={35,130},size={150,20},proc=AutoCalcTransButton,title="Calc Transmission"
	Button button4,pos={70,155},size={150,20},proc=AutoFindUnityTransButton,title="Unity Transm"
	Button button5,pos={70,175},size={150,20},proc=AutoFindLargeTransButton,title="Large Transm"
	Button button6,pos={35,210},size={150,20},proc=AutoReduceEverythingButton,title="Reduce Everything"
	Button button7,pos={35,250},size={150,20},proc=AutoNSORTTableButton,title="NSORT Table"
	Button button8,pos={70,275},size={150,20},proc=AutoNSORTEverythingButton,title="NSORT Everything"

	Button button9,pos={220,5},size={20,20},proc=AutoReduceHelpButton,title="?"
	
EndMacro

// make the matrix a numeric wave.
// assume that the DIV file can be found from the file list as ".DIV"
// and the MASK file can be found as ".MASK" (if not, ask for help)
//
//
Function AskForConfigurations()

	Variable num
	Prompt num,"How many configurations were used?"
	DoPrompt "Enter the number of configs",num
	
	Make/O/D/N=(num,5) Configs
	WAVE w = Configs
	// set the column labels
	SetDimLabel 1,0,'SDD',w
	SetDimLabel 1,1,'Wavelength',w
	SetDimLabel 1,2,'BKG',w
	SetDimLabel 1,3,'EMP',w
	SetDimLabel 1,4,'Empty Beam',w

	Edit w.ld
	ModifyTable width(Configs.l)=20
	
	DoAlert 0, "Fill in the SDD and wavelength for each configuration"

	return(0)
end

//
//
Function SortConfigs()

	WAVE w = Configs
	 
	Variable num = DimSize(w, 0 )

	Make/O/D/N=(num) wave0,wave1
	wave0 = w[p][%'SDD']
	wave1 = w[p][%'Wavelength']
	
	Sort/R {wave0,wave1},wave0,wave1

	w[][%'SDD'] = wave0[p]
	w[][%'Wavelength'] = wave1[p]
	
	KillWaves wave0,wave1

// now try to find the configurations as best as I can
	// loop over the rows
	Variable ii
	for(ii=0;ii<num;ii+=1)
		FindConfigurationFiles(ii)
	endfor

	DoAlert 0, "I've sorted Low Q to High Q -- And while at it, filled in the run numbers for BKG, EMP and empty beam for each configuration"

	return(0)
End


//
// find the other files for each configuration as best possible
//
//
Function FindConfigurationFiles(row)
	Variable row
	
	WAVE w = Configs

	// for the SDD and wavelength, find the BKG and EMP and Empty beam
	Variable sdd, lam
	sdd = w[row][%'SDD']
	lam = w[row][%'Wavelength']

	//(see MRED and Patch for help on this)
	// find files with a reasonable string in the header somewhere -- returns a short list
	// filter out the wrong SDD
	// filter out the wrong wavelength
	// filter out (is Trans) if needed

	string newList="",item,matchStr,list="",pathStr
	Variable num,ii,runNum

	PathInfo catPathName
	pathStr = S_Path
	
// blocked beam
	matchStr = "block"
	list = FindFileContainingString(matchStr)

//	print list
	newList = ""
	num = ItemsinList(list)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list)
		if(SameSDD_byName(pathStr+item,sdd) && SameWavelength_byName(pathStr+item,lam) && !N_isTransFile(pathStr+item))
			newList += item 
			break		//only keep the first instance
		endif	
	endfor
	
	runNum = N_GetRunNumFromFile(newList)
	w[row][%'BKG'] = runNum
	
	Printf "Config %d BKG: %s = %s\r",row,newList,getSampleDescription(pathStr+newList)
	
	// and the empty cell scattering
	matchStr = "empty"
	list = FindFileContainingString(matchStr)

//	print list
	newList = ""
	num = ItemsinList(list)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list)
		if(SameSDD_byName(pathStr+item,sdd) && SameWavelength_byName(pathStr+item,lam) && !N_isTransFile(pathStr+item))
			newList += item
			break		//only keep the first instance
		endif	
	endfor
	
	runNum = N_GetRunNumFromFile(newList)
	w[row][%'EMP'] = runNum	
	
	
	Printf "Config %d EMP: %s = %s\r",row,newList,getSampleDescription(pathStr+newList)

	//and the empty beam transmission
	matchStr = "empty"
	list = FindFileContainingString(matchStr)

//	print list
	newList = ""
	num = ItemsinList(list)
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list)
		if(SameSDD_byName(pathStr+item,sdd) && SameWavelength_byName(pathStr+item,lam) && N_isTransFile(pathStr+item))
			newList += item
			break		//only keep the first instance
		endif	
	endfor
	
	runNum = N_GetRunNumFromFile(newList)
	w[row][%'Empty Beam'] = runNum

	Printf "Config %d Empty beam: %s = %s\r\r",row,newList,getSampleDescription(pathStr+newList)
	

	return(0)
End

Function/S FindFileContainingString(matchStr)
	string matchStr
	

	string newList,item,list=""
	Variable num,ii

	
	newList = N_GetRawDataFileList()
	num=ItemsInList(newList)

	for(ii=0;ii<num;ii+=1)
		item=StringFromList(ii, newList , ";")
//		Grep/P=catPathName/Q/E=("(?i)\\b"+matchStr+"\\b") item
		Grep/P=catPathName/Q/E=("(?i)"+matchStr) item
		if( V_value )	// at least one instance was found
			list += item + ";"
		endif
	endfor

	newList = list

	
	return(newList)
end




Function/S FindDIVFile()
	
	String list,fileStr=""
	
	list = IndexedFile(catPathName, -1, ".DIV")
//	Print list
//	if(itemsinlist(list) == 1)
		fileStr = StringFromList(0, list)		// just return the first one
//	endif
	
	return(fileStr)

End

Function/S FindMASKFile()

	String list,fileStr=""
	
	list = IndexedFile(catPathName, -1, ".MASK")
//	Print list
//	if(itemsinlist(list) == 1)
		fileStr = StringFromList(0, list)		// just return the first one
//	endif
	
	return(fileStr)
End

// returns true (1) if the run number has the same SDD as input
Function SameSDD_byRun(runNum,sdd)
	Variable runNum,sdd

	String fname
	Variable good
	
	good = 0
	fname = ""
	//generate a name
	fname = N_FindFileFromRunNumber(runNum)
	// test
	good = SameSDD_byName(fname,sdd) 
	
	return(good)
End


// returns true (1) if the file (fullPath) has the same SDD as input
// -- fuzzy test, within 1% is a match
//
Function SameSDD_byName(fname,sdd)
	String fname
	Variable sdd

	Variable good,tmp,tolerance
	
	tolerance = 0.01
	good = 0
	tmp = getDet_Distance(fname)
	
	if(abs(tmp - sdd) < tolerance)		//need a fuzzy test here, just like for the wavelength
		return(1)
	else
		return(0)
	endif
	
End

// returns true (1) if the run number has the same wavelength as input
Function SameWavelength_byRun(runNum,lambda)
	Variable runNum,lambda

	String fname
	Variable good
	
	good = 0
	fname = ""
	//generate a name
	fname = N_FindFileFromRunNumber(runNum)
	// test
	good = SameWavelength_byName(fname,lambda) 
	
	return(good)
End


// returns true (1) if the file (fullPath) has the same wavelength as input
// -- fuzzy test, within 1% is a match
//
Function SameWavelength_byName(fname,lambda)
	String fname
	Variable lambda

	Variable good,tmp,tolerance
	
	tolerance = 0.01
	good = 0
	tmp = getWavelength(fname)
	
	if(abs(tmp - lambda) < tolerance)		//need a fuzzy test here
		return(1)
	else
		return(0)
	endif
	
End


// simple loop to automate the generation/saving of protocols from the configuration matrix
//
Function Auto_FillSaveProtocols()

	WAVE w = root:Configs
	 
	Variable num,ii
	num = DimSize(w,0)
	
	for(ii=0;ii<num;ii+=1)
		FillInProtocol(ii)
		Auto_SaveProtocol(ii)
	endfor
	
	return(0)
End

//
// I could possibly just fill in the protocol on my own, or 
// fill in the panel and go through the parsing.
//
// be sure the panel is open before starting this.
//
Function FillInProtocol(index)
	variable index
	
	// be sure it's open and on top (redundant, but do it anyways)
	Execute "ReductionProtocolPanel()"
	
	SVAR bgd = root:myGlobals:Protocols:gBGD
	SVAR emp = root:myGlobals:Protocols:gEMP
	SVAR div = root:myGlobals:Protocols:gDIV
	SVAR mask = root:myGlobals:Protocols:gMASK
	SVAR gABS = root:myGlobals:Protocols:gAbsStr

	WAVE configs=root:configs
	bgd = num2str(configs[index][%'BKG'])
	emp = num2str(configs[index][%'EMP'])

	div = FindDIVFile()
	mask = FindMASKFile()
	
	// now do the absolute scaling
	// be sure to load in the DIV file 
	String pathStr
	PathInfo catPathName
	pathStr = S_path
	
	ReadHeaderAndWork("DIV",pathStr+div)
	
	// be sure that the beam center is properly set
	Auto_FindWriteBeamCenter(configs[index][%'Empty Beam'])
	
	// then I can calculate Kappa
	gABS = Auto_CalcKappa(configs[index][%'Empty Beam'])
	
	return(0)
end


Function Auto_SaveProtocol(index)
	variable index
	
	String newProtocol
	
	newProtocol = "config_"+num2str(index)
	Make/O/T/N=8 $("root:myGlobals:Protocols:" + newProtocol)
	MakeProtocolFromPanel( $("root:myGlobals:Protocols:" + newProtocol) )
	
	return(0)
End



//
// parallels the functionality of AskForAbsoluteParams_Quest()
//
Function/S Auto_CalcKappa(runNum)
	Variable runNum
	
	String filename,pathStr
	
	filename = N_FindFileFromRunNumber(runNum)
	
	ReadHeaderAndData(filename,"RAW")	//this is the full Path+file
	UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
	
	Wave data = getDetectorDataW("RAW")		//this will be the linear data
	String acctStr = "RAW"


	//get the necessary variables for the calculation of kappa
	Variable detCnt,countTime,attenTrans,monCnt,sdd,pixel,kappa
	Variable kappa_err
	String junkStr,errStr

	pixel = getDet_x_pixel_size("RAW")/10			// header value (X) is in mm, want cm here

	countTime = getCollectionTime("RAW")
	//detCnt = rw[2]		//080802 -use sum of data, not scaler from header
	monCnt = getControlMonitorCount("RAW")
	sdd = getDet_Distance(filename)		// return value is in [cm]
				
	//lookup table for transmission factor
	//determine which instrument the measurement was done on from acctStr
	Variable lambda = getWavelength("RAW")
	Variable attenNo = getAtten_number("RAW")
	Variable atten_err
	attenTrans = getAttenuator_transmission("RAW")
	atten_err = getAttenuator_trans_err("RAW")
	//Print "attenTrans = ",attenTrans
	
	Variable x1,x2,y1,y2,ct_err
	Variable xctr,yctr
	// set the xy box to be the whole detector to find the beam center (may be wrong in the file)
	// then +/- 20 pix (within bounds) to sum

	xctr = getDet_beam_center_x("RAW")
	yctr = getDet_beam_center_y("RAW")

	x1 = xctr - 15
	x2 = xctr + 15
	y1 = yctr - 15
	y2 = yctr + 15
	KeepSelectionInBounds(x1,x2,y1,y2)

	Printf "Using Box X(%d,%d),Y(%d,%d)\r",x1,x2,y1,y2
	
	//need the detector sensitivity file - make a guess, allow to override
	// it must already be there, done by calling routine
	//
	Wave divData = $"root:Packages:NIST:div:Data"
	// correct by detector sensitivity
	data /= divData
	
	detCnt = SumCountsInBox(x1,x2,y1,y2,ct_err,"RAW")
//	if(cmpstr(tw[9],"ILL   ")==0)
//		detCnt /= 4		// for cerca detector, header is right, sum(data) is 4x too large this is usually corrected in the Add step
//		pixel *= 1.04			// correction for true pixel size of the Cerca
//	endif
	//		
	kappa = detCnt/countTime/attenTrans*1.0e8/(monCnt/countTime)*(pixel/sdd)^2
	
	kappa_err = (ct_err/detCnt)^2 + (atten_err/attenTrans)^2
	kappa_err = sqrt(kappa_err) * kappa
		
	junkStr = num2str(kappa)
	errStr = num2Str(kappa_err)
		
	// set the parameters in the global string
	Execute "AskForAbsoluteParams(1,1,"+junkStr+",1,"+errStr+")"		//no missing parameters, no dialog
		
	DoWindow/K SANS_Data

	Printf "Kappa was successfully calculated as = %g +/- %g (%g %%)\r",kappa,kappa_err,(kappa_err/kappa)*100
	
	SVAR kapStr = root:myGlobals:Protocols:gAbsStr	
	
	return(kapStr)
end


// given a run number:
// -- load it to RAW
// -- find the beam center
// -- write this out to the file
//
Function Auto_FindWriteBeamCenter(runNum)
	Variable runNum
	
	String filename,pathStr
	
	filename = N_FindFileFromRunNumber(runNum)
	
	ReadHeaderAndData(filename,"RAW")	//this is the full Path+file
	UpdateDisplayInformation("RAW")			//display the new type of data that was loaded

	Wave data = getDetectorDataW("RAW")		//this will be the linear data

	Variable xzsum,yzsum,zsum,ii,jj,top,bottom,left,right
	Variable counts,xctr,yctr
	xzsum = 0
	yzsum = 0
	zsum = 0
	
	left = 0
	right = 127
	bottom = 0
	top = 127
	// count over rectangular selection, doing each row, L-R, bottom to top
	ii = bottom -1
	do
		ii +=1
		jj = left-1
		do
			jj += 1
			counts = data[jj][ii]
			xzsum += jj*counts
			yzsum += ii*counts
			zsum += counts
		while(jj<right)
	while(ii<top)
	
	xctr = xzsum/zsum
	yctr = yzsum/zsum
	
	// add 1 to each to get to detector coordinates (1,128)
	// rather than the data array which is [0,127]
	xctr+=1
	yctr+=1
	
	Print "Automatic Beam X-center (in detector coordinates) = ",xctr
	Print "Automatic Beam Y-center (in detector coordinates) = ",yctr

	//write the center to the header, so I don't need to find it again
	writeDet_beam_center_x(filename,xctr)
	writeDet_beam_center_y(filename,yctr)
	
	return(0)
	
End


// load the file
// - convert to SAM
// - find the box and write out the counts
//
//  parallels SetXYBoxCoords()
//
Function Auto_SetXYBox(runNum)
	Variable runNum

	String filename,pathStr
	Variable err,xctr,yctr,x1,x2,y1,y2
	filename = N_FindFileFromRunNumber(runNum)

// load the data	and convert to SAM
	ReadHeaderAndData(filename,"RAW")	//this is the full Path+file
	UpdateDisplayInformation("RAW")			//display the new type of data that was loaded
	err = Raw_to_work_for_Ordela("SAM")
	String/G root:myGlobals:gDataDisplayType="SAM"
	UpdateDisplayInformation("SAM")			//display the new type of data that was loaded
//	fRawWindowHook()

// set the XYBox
	xctr = getDet_beam_center_x(filename)
	yctr = getDet_beam_center_y(filename)

	x1 = xctr - 15
	x2 = xctr + 15
	y1 = yctr - 15
	y2 = yctr + 15
	KeepSelectionInBounds(x1,x2,y1,y2)
	//write string as keyword-packed string, to use IGOR parsing functions
	String msgStr = "X1="+num2str(x1)+";"
	msgStr += "X2="+num2str(x2)+";"
	msgStr += "Y1="+num2str(y1)+";"
	msgStr += "Y2="+num2str(y2)+";"
	String/G root:myGlobals:Patch:gPS3 = msgStr
	String/G root:myGlobals:Patch:gEmpBox = msgStr
	//changing this global wil update the display variable on the TransPanel
	String/G root:myGlobals:TransHeaderInfo:gBox = msgStr

// get the counts and write everything to the header
	Variable counts,ct_err
	counts = SumCountsInBox(x1,x2,y1,y2,ct_err,"SAM")

	Make/O/D/N=4 tmpW
	tmpW[0] = x1
	tmpW[1] = x2
	tmpW[2] = y1
	tmpW[3] = y2
	
	writeBoxCoordinates(filename,tmpW)
		
	Print counts, " counts in XY box"
	writeBoxCounts(filename,counts)
	
	writeBoxCountsError(filename,ct_err)
	
	KillWaves/Z tmpW
	
	return(0)
End

//// calculating the transmissions
// 5) calculate all of the transmissions
// -- start by opening the Transmission panel
// -- list all of the files
// then:
// - for each empty beam file:
//		setXYBox (write out box and counts to the file)
// 		check if there are transmission measurements at this config (SDD && lam)
//			if so, this is the empty beam
//				so try to guess the scattering files and calc transmission
//
//			go get another transmission at this configuration
//
//		go get another empty beam file
//
//	- at the end, search through all of the scattering files. look at
// the S_Transmission wave for: T=1 (be sure these are blocked beam) and search for
//  T > 1, as these are wrong.
//
//	-- may need user intervention if things go wrong.
//
Function Auto_Transmission()

	//open the panel
	Execute "CalcTrans()"
	//list the files - this is equivalent to pressing the button
	Execute "BuildFileTables()"
	
	// get all of the empty beam files (from the initial setup)
	WAVE configs = root:configs
	
	// declare all of the necessary TransTable files so that I can check, and do assignments
	WAVE/T TransFiles = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	WAVE/T EmpAssignments = $"root:myGlobals:TransHeaderInfo:T_EMP_Filenames"
	
	Variable nEmpFiles,nTransFiles,ii,jj,empNum,empLam,empSDD,testNum,numChars
	String empName="",pathStr,testName
	
	PathInfo catPathName
	pathStr = S_path
	
	numChars = 8 		//for the trans guess
	
	nEmpFiles = DimSize(configs, 0)
	nTransFiles = numpnts(TransFiles)


// this is only to save the "matches" for use later in combining the reduced data
	SVAR gMatchSamStr = root:myGlobals:TransHeaderInfo:gMatchingSampleFiles
	Make/O/T/N=(nTransFiles) savedMatches
	savedMatches = ""

	for(ii=0;ii<nEmpFiles;ii+=1)		//loop over the empty beam files (from Configs)
		empNum = configs[ii][%'Empty Beam']
		empName = N_GetFileNameFromPathNoSemi(N_FindFileFromRunNumber(empNum))
		// auto_find the beam center
		Auto_FindWriteBeamCenter(empNum)
		// set the XY box for the file, and the counts in the box
		Auto_SetXYBox(empNum)
		
		// get the wavelength and SDD (from the config) for comparison
		empLam = configs[ii][%'Wavelength']
		empSDD = configs[ii][%'SDD']
		
		
		// loop through the trans files in the table (skip the empNum file)
		// and see if any match the configuration
		// -- if so do something
		
		for(jj=0;jj<nTransFiles;jj+=1)
//		for(jj=0;jj<10;jj+=1)
		
			// if it's the same file, skip it
			testNum = N_GetRunNumFromFile(TransFiles[jj])
			testName = TransFiles[jj]
			if(testNum != empNum)		
				// do the configurations match?
				if(SameWavelength_byName(pathStr+testName,empLam) && SameSDD_byName(pathStr+testName,empSDD))
					// if yes:
					// assign this empty beam as the reference empty beam
					EmpAssignments[jj] = empName
					
					// try to find matching scattering runs
					// set the selection on the table
					ModifyTable/W=TransFileTable selection=(jj,1,jj,1,jj,1)
					
					// pick the number of characters to use
					fGuessTransToScattFiles(numChars)
					
					// ** if "correct" runs are found, calculate the transmissions *** this is the tough step
					// at this point, I'm still asking for user intervention, since I have no way of knowing
					// how to tell if I have the right files, or even the right number of files.
					
					// this is a ; delimited list of the raw data files that have the same transmission assignment
					// - that may be the ones to combine together.
					savedMatches[jj] = gMatchSamStr			
					
				endif
			endif
		endfor
		
	endfor		//loop over all empty beam files

	DoAlert 0,"Transmissions are done"

	return(0)
End


// spit out a list of scattering files with T=1
// ask the user if these are OK
Function ListFiles_TransUnity()

	WAVE/T S_FileNames = $"root:myGlobals:TransHeaderInfo:S_FileNames"
	WAVE/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	WAVE S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"

	Variable num,ii
	num = numpnts(S_Transmission)
	
	for(ii=0;ii<num;ii+=1)
		if(S_transmission[ii] == 1)
			printf "File %s = %s has T=1. Is this OK?\r",S_FileNames[ii],S_Labels[ii]
		endif
	endfor
	
	return(0)
End


// spit out a list of scattering files with T>1
// let the user know that these are incorrect and need to be repaired

Function ListFiles_TransTooLarge()

	WAVE/T S_FileNames = $"root:myGlobals:TransHeaderInfo:S_FileNames"
	WAVE/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	WAVE S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"

	Variable num,ii
	num = numpnts(S_Transmission)
	
	for(ii=0;ii<num;ii+=1)
		if(S_transmission[ii] > 1)
			printf "File %s = %s has T=1. This is NOT OK!\r",S_FileNames[ii],S_Labels[ii]
		endif
	endfor
	
	return(0)
End




// TOO -- rewrite this correctly, using a proper "fuzzy" match for the wavelength,
// adding items that do not match to a growing list of "different" wavelengths to check against
// -- use 1% tol, not 5%
//
// use the function "CloseEnough()"
//
Function HowManyWavelengths()
	
	Variable num
	WAVE lam = root:myGlobals:CatVSHeaderInfo:Lambda
	
	Variable ii,npt,tol
	npt = numpnts(lam)
	tol = 1.01		// 1%
	
	Duplicate/O lam,tmp
	sort tmp,tmp
	
	num = 1
	Make/O/D/N=1 numLam
	numLam[0] = tmp[0]
	
	
	for(ii=1;ii<npt;ii+=1)
		if(tmp[ii] > tol*numLam[num-1])
			InsertPoints num, 1, numLam
			numLam[num] = tmp[ii]
			num += 1
		endif
	
	endfor
	
	Printf "Found %d different wavelengths\r",num
	
	return(num)
End


// somewhat tricky -- look for combinations of different
// SDD and wavelength. -- if lenses are used, often they are both at the 
// same SDD, but at different wavelengths -- for lenses
Function HowManyConfigurations()

	Variable num
	WAVE SDD = root:myGlobals:CatVSHeaderInfo:SDD
	WAVE lam = root:myGlobals:CatVSHeaderInfo:Lambda
	

	
	return(num)
End


/////
//
//
Function Auto_MRED()

	// open the panel
	Execute "ReduceMultipleFiles()"
	
	WAVE w = root:Configs
	SVAR protoList = root:myGlobals:MRED:gMRProtoList
	
	Variable num,ii,sdd,item
	String str
	num = DimSize(w,0)
	
	// protocols are named "config_n"
	for(ii=0;ii<num;ii+=1)
	
		// pick the configuration (ii)
		// set the protocol - find which list item
		str = "config_"+num2str(ii)
		item = WhichListItem(str, protoList)
		PopupMenu MRProto_pop,win=Multiple_Reduce_Panel,mode=(item+1)		//popup counts from one

		// get the SDD
		SDD = w[ii][%'SDD']
		
		// get the scattering files at the SDD
		Execute "CreateScatteringAtSDDTable("+num2str(SDD)+")"
		
		RemoveWrongLamFromSDDList(w[ii][%'Wavelength'])
		
		// set the list
		AcceptMREDList("")
		
		// reduce them all
		ReduceAllPopupFiles("")
	endfor
	
	return(0)
End

// need fuzzy comparison
//
// Only wavelengths matching testLam are kept
//
Function RemoveWrongLamFromSDDList(testLam)
	Variable testLam
	
	Wave/T filenames = $"root:myGlobals:MRED:Filenames"
	Wave/T suffix = $"root:myGlobals:MRED:Suffix"
	Wave/T labels = $"root:myGlobals:MRED:Labels"
	Wave sdd = $"root:myGlobals:MRED:SDD"
	Wave runnum = $"root:myGlobals:MRED:RunNumber"
	Wave isTrans = $"root:myGlobals:MRED:IsTrans"
	
	String path
	PathInfo catPathName
	path = S_Path
	
	Variable num=numpnts(sdd),ii,tol = 0.1,lam
	
	ii=num-1
	do
		lam = getWavelength(path+filenames[ii])
		if(trunc(abs(lam - testLam)) > tol)		//just get the integer portion of the difference - very coarse comparison
			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
		endif
		ii-=1
	while(ii>=0)
	
	// now sort
	Sort RunNum, 	filenames,suffix,labels,sdd,runnum,isTrans
	return(0)
End

// does no scaling, only the basic (default) trim of the ends, concatenate, sort, and save
//
//
Function Auto_NSORT(tableOnly)
	variable tableOnly

	Wave/T SavedMatches = root:savedMatches

	if(tableOnly)
		Duplicate/T/O savedMatches saveName
		saveName = ""
	Endif
	
	
	DoWindow/F Auto_NSORT_Table
	if(V_flag == 0)
		Edit/N=Auto_NSORT_Table savedMatches,saveName
	endif
	
	Variable num,ii,numitems,numChars,jj,nEnd
	String item,path,tmpStr,cmd,folderStr
	
	// number of characters in the file label to keep for the file name
	numChars = 16
	// number of points to trim from end
	nEnd = 10
	
	
	PathInfo catPathName
	path = S_Path
	
	if(tableOnly)	
		num=numpnts(savedMatches)
	// guess at the file names
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(0, savedMatches[ii])
			if(cmpstr(item,"") != 0)
				tmpStr = N_RemoveAllSpaces(getSampleDescription(path+item))
				tmpStr = CleanupName(tmpStr, 0 )
				saveName[ii] = tmpStr[0,numChars-1]+".abs"
			endif
		endfor
		
		DoAlert 0,"Edit the table to combine the correct files, and names that you like"
		
		return(0)
	endif


	// now, the table may have been edited
	num=numpnts(savedMatches)

// now loop over the files:
	for(ii=0;ii<num;ii+=1)
		numItems = ItemsInList(savedMatches[ii])
		if(numItems != 0)
			for(jj=0;jj<numItems;jj+=1)
				// load
				item = StringFromList(jj, savedMatches[ii])
				folderStr = GetPrefixAndNumStrFromFile(item)		//this is where the data will be loaded to
				
				// check for existence first - this bypasses cases like the empty cell, which have transmission but are not reduced
				if(cmpstr("",N_ValidFileString(folderStr+".ABS")) !=0)
	
					sprintf cmd , "A_LoadOneDDataToName(\"%s\",\"%s\",%d,%d)",path+folderStr+".ABS","",0,1
					Execute cmd		//no plot, force overwrite
					
					// trim
					Auto_TrimData(folderStr+"_ABS",nEnd)
					SetDataFolder root:
					
					// if first file, duplicate for a placeholder for the combined data, force overwrite
					if(jj==0)
						DuplicateDataSet(folderStr+"_ABS", CleanupName(saveName[ii],0), 1)
					else
						Auto_Concatenate(folderStr+"_ABS", CleanupName(saveName[ii],0))
					endif
					
				endif
			endfor
			
			// sort
			Auto_Sort(CleanupName(saveName[ii],0))
			
			// save
			if(DataFolderExists("root:"+CleanupName(saveName[ii],0)))
				Auto_Write1DData(CleanupName(saveName[ii],0),"tab","CRLF")
			endif
		endif
	endfor

	// kill the loaded data sets (since they have been modified!)
	Execute "A_PlotManager_KillAll(\"\")"

	return(0)
End


// this will bypass save dialogs
// -- AND WILL OVERWITE DATA WITH THE SAME NAME
//
Function Auto_Write1DData(folderStr,delim,term)
	String folderStr,delim,term
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1
	
	String dataSetFolderParent,basestr
	
	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,folderStr,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,folderStr,":",1,0)
	
	//make sure the waves exist
	SetDataFolder $(dataSetFolderParent+basestr)
	WAVE/Z qw = $(baseStr+"_q")
	WAVE/Z iw = $(baseStr+"_i")
	WAVE/Z sw = $(baseStr+"_s")
	WAVE/Z resw = $(baseStr+"_res")
	
	if(WaveExists(qw) == 0)
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		Abort "s is missing"
	endif
	if(WaveExists(resw) == 0)
		Abort "Resolution information is missing."
	endif
	
	Duplicate/O qw qbar,sigQ,fs
	if(dimsize(resW,1) > 4)
		//it's USANS put -dQv back in the last 3 columns
		NVAR/Z dQv = USANS_dQv
		if(NVAR_Exists(dQv) == 0)
			SetDataFolder root:
			Abort "It's USANS data, and I don't know what the slit height is."
		endif
		sigQ = -dQv
		qbar = -dQv
		fs = -dQv
	else
		//it's SANS
		sigQ = resw[p][0]
		qbar = resw[p][1]
		fs = resw[p][2]
	endif
	
	PathInfo catPathName
	fullPath = S_Path + folderStr

	Open refnum as fullpath

	fprintf refnum,"Combined data written from folder %s on %s\r\n",folderStr,(date()+" "+time())
	formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
	fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"	

	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs
	Close refnum
	
	KillWaves/Z sigQ,qbar,fs
	
	SetDataFolder root:
	return(0)
End


// concatentate folder1 to the end of folder2
//
// this seems like a lot of extra work to do something so simple...
//
Function Auto_Concatenate(folder1,folder2)
	String folder1,folder2
	
	
	Concatenate/NP {$("root:"+folder1+":"+folder1+"_q"),$("root:"+folder2+":"+folder2+"_q")},tmp_q
	Concatenate/NP {$("root:"+folder1+":"+folder1+"_i"),$("root:"+folder2+":"+folder2+"_i")},tmp_i
	Concatenate/NP {$("root:"+folder1+":"+folder1+"_s"),$("root:"+folder2+":"+folder2+"_s")},tmp_s
	Concatenate/NP {$("root:"+folder1+":res0"),$("root:"+folder2+":res0")},tmp_res0
	Concatenate/NP {$("root:"+folder1+":res1"),$("root:"+folder2+":res1")},tmp_res1
	Concatenate/NP {$("root:"+folder1+":res2"),$("root:"+folder2+":res2")},tmp_res2
	Concatenate/NP {$("root:"+folder1+":res3"),$("root:"+folder2+":res3")},tmp_res3
	
// move the concatenated result into the destination folder (killing the old stuff first)
	KillWaves/Z $("root:"+folder2+":"+folder2+"_q")
	KillWaves/Z $("root:"+folder2+":"+folder2+"_i")
	KillWaves/Z $("root:"+folder2+":"+folder2+"_s")
	KillWaves/Z $("root:"+folder2+":res0")
	KillWaves/Z $("root:"+folder2+":res1")
	KillWaves/Z $("root:"+folder2+":res2")
	KillWaves/Z $("root:"+folder2+":res3")
	
	Duplicate/O tmp_q $("root:"+folder2+":"+folder2+"_q")
	Duplicate/O tmp_i $("root:"+folder2+":"+folder2+"_i")
	Duplicate/O tmp_s $("root:"+folder2+":"+folder2+"_s")
	Duplicate/O tmp_res0 $("root:"+folder2+":res0")
	Duplicate/O tmp_res1 $("root:"+folder2+":res1")
	Duplicate/O tmp_res2 $("root:"+folder2+":res2")
	Duplicate/O tmp_res3 $("root:"+folder2+":res3")

	KillWaves/Z tmp_q,tmp_i,tmp_s,tmp_res0,tmp_res1,tmp_res2,tmp_res3	
	
	
	return(0)		
End
			
Function Auto_Sort(folderStr)
	String folderStr

	if(DataFolderExists("root:"+folderStr)	== 0)
		return(0)
	endif
	
	SetDataFolder $("root:"+folderStr)
	
	Wave qw = $(folderStr + "_q")
	Wave iw = $(folderStr + "_i")
	Wave sw = $(folderStr + "_s")
	
	Wave res0 = res0
	Wave res1 = res1
	Wave res2 = res2
	Wave res3 = res3
	// sort the waves
	
	Sort qw, qw,iw,sw,res0,res1,res2,res3
	
	// restore the res wave
	KillWaves/Z $(folderStr+"_res")
	Make/O/D/N=(numpnts(qw),4) $(folderStr+"_res")
	WAVE resWave = $(folderStr+"_res")
	
	//Put resolution contents back
	reswave[][0] = res0[p]
	reswave[][1] = res1[p]
	reswave[][2] = res2[p]
	reswave[][3] = res3[p]
	
	SetDataFolder root:
	return(0)
End
			
// trims the beamstop out (based on shadow)
// trims num from the highQ end
// splits the res wave into individual waves in anticipation of concatenation
//
Function Auto_TrimData(folderStr,nEnd)
	String folderStr
	Variable nEnd

	if(DataFolderExists("root:"+folderStr)	== 0)
		return(0)
	endif
		
	SetDataFolder $("root:"+folderStr)
	
	Wave qw = $(folderStr + "_q")
	Wave iw = $(folderStr + "_i")
	Wave sw = $(folderStr + "_s")
	Wave res = $(folderStr + "_res")
	
	variable num,ii
	
	num=numpnts(qw)
	//Break out resolution wave into separate waves
	Make/O/D/N=(num) res0 = res[p][0]		// sigQ
	Make/O/D/N=(num) res1 = res[p][1]		// qBar
	Make/O/D/N=(num) res2 = res[p][2]		// fshad
	Make/O/D/N=(num) res3 = res[p][3]		// qvals
	
	// trim off the last nEnd points from everything
	DeletePoints num-nEnd,nEnd, qw,iw,sw,res0,res1,res2,res3
	
	// delete all points where the shadow is < 0.98
	num=numpnts(qw)
	for(ii=0;ii<num;ii+=1)
		if(res2[ii] < 0.98)
			DeletePoints ii,1, qw,iw,sw,res0,res1,res2,res3
			num -= 1
			ii -= 1
		endif
	endfor
	
////Put resolution contents back???
//		reswave[][0] = res0[p]
//		reswave[][1] = res1[p]
//		reswave[][2] = res2[p]
//		reswave[][3] = res3[p]
//		
			
	SetDataFolder root:
	return(0)
end


//given a filename of a SANS data filename of the form
//TTTTTnnn.SAn_TTT_Txxx
//returns the prefix "TTTTTnnn" as some number of characters
//returns "" as an invalid file prefix
//
// NCNR-specifc, does not really belong here - but it's a beta procedure used for automation
//
Function/S GetPrefixAndNumStrFromFile(item)
	String item
	String invalid = ""	//"" is not a valid run prefix, since it's text
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		runStr = item[0,pos-1]
		return (runStr)
	Endif
End


// 		
Function AutoReduceHelpButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "Automated SANS Data Reduction"
			if(V_flag !=0)
				DoAlert 0,"The SANS Reduction Automation Help file could not be found"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// 		
Function AutoAskForConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			AskForConfigurations()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoSortConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SortConfigs()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoFillProtocolButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Auto_FillSaveProtocols()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoCalcTransButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Auto_Transmission()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoFindUnityTransButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ListFiles_TransUnity()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoFindLargeTransButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ListFiles_TransTooLarge()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoReduceEverythingButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Auto_MRED()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AutoNSORTTableButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable tableOnly = 1
			Auto_NSORT(tableOnly)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AutoNSORTEverythingButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable tableOnly = 0
			Auto_NSORT(tableOnly)
			DoAlert 0,"Sorting and Saving Done"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




