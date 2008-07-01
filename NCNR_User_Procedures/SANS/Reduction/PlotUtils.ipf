#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

//**************************
// Vers. 1.2 092101
//
//must be using IGOR Pro v. 3.14 or higher for StringFromList()
//loads 3-column or 6-column data into the experiment with appropriate extensions
// added to the cleaned-up filenames
//
// 2 versions - one to always present dialog, and a second if the filename
// is already known
//
//*****************************


// loads a 1-d (ascii) datafile and plots the data
// will not overwrite existing data (old data must be deleted first)
// - multiple datasets can be automatically plotted on the same graph
//
//substantially easier to write this as a Proc rather than a function...
//
Proc LoadOneDData()

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A
	String filename = S_fileName
	Variable numCols = V_flag
	
	//changes JIL
	if(numCols==2)		//no errors	
		n1 = StringFromList(1, S_waveNames ,";" )		
		Duplicate/O $("root:"+n1), errorTmp
		errorTmp = 0.01*(errorTmp)+ 0.03*sqrt(errorTmp)
		S_waveNames+="errorTmp;"
		numCols=3
	endif
	 
	if(numCols==3)
		String w0,w1,w2,n0,n1,n2,wt
		Variable rr,gg,bb
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		wt = CleanupName((S_fileName + "wt"),0)		//create a name for the weighting wave
		
		if(exists(w0) !=0)
			DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves/Z $n0,$n1,$n2		// kill the default waveX that were loaded
				String/G root:myGlobals:gLastFileName = filename		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif
		
		////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		KillWaves $n0,$n1,$n2
		
		String/G root:myGlobals:gLastFileName = filename
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// set data units for the waves
		String angst = root:myGlobals:gAngstStr
		SetScale d,0,0,"1/"+angst,$w0
		SetScale d,0,0,"1/cm",$w1
		
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
		
		// if target window is a graph, and user wants to append, do so
	    DoWindow/B Plot_Manager
		if(WinType("") == 1)
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $w1 vs $w0
				ModifyGraph mode=3,marker=19,msize=2,rgb ($w1) =(rr,gg,bb)
				ErrorBars $w1 Y,wave=($w2,$w2)
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
				ModifyGraph grid=1,mirror=2,standoff=0
				ErrorBars $w1 Y,wave=($w2,$w2)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
			ModifyGraph grid=1,mirror=2,standoff=0
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
			
		// Annotate graph
		//Textbox/A=LT "XY data loaded from " + S_fileName
	       DoWindow/F Plot_Manager
		return
	endif
	
	if(numCols == 6)
		String w0,w1,w2,n0,n1,n2,wt
		String w3,w4,w5,n3,n4,n5			//3 extra waves to load
		Variable rr,gg,bb
		
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		n5 = StringFromList(5, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		w3 = CleanupName((S_fileName + "sq"),0)
		w4 = CleanupName((S_fileName + "qb"),0)
		w5 = CleanupName((S_fileName + "fs"),0)
		wt = CleanupName((S_fileName + "wt"),0)		//create a name for the weighting wave
		
		if(exists(w0) !=0)		//the wave already exists
			DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
				String/G root:myGlobals:gLastFileName = filename		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif

////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		Duplicate/O $n3, $w3
		Duplicate/O $n4, $w4
		Duplicate/O $n5, $w5
		KillWaves $n0,$n1,$n2,$n3,$n4,$n5
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// copy waves to global strings for use in the smearing calculation
		String/G root:myGlobals:gLastFileName = filename
		String/G gQVals = w0
		String/G gSig_Q = w3
		String/G gQ_bar = w4
		String/G gShadow = w5
		
		// set data units for the waves
		String angst = root:myGlobals:gAngstStr
		SetScale d,0,0,"1/"+angst,$w0
		SetScale d,0,0,"1/cm",$w1
		
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
	
		// if target window is a graph, and user wants to append, do so
	        DoWindow/B Plot_Manager
		if(WinType("") == 1)
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $w1 vs $w0
				ModifyGraph mode=3,marker=19,msize=2,rgb ($w1) =(rr,gg,bb)
				ErrorBars $w1 Y,wave=($w2,$w2)
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
				ModifyGraph grid=1,mirror=2,standoff=0
				ErrorBars $w1 Y,wave=($w2,$w2)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
			ModifyGraph grid=1,mirror=2,standoff=0
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
			
		// Annotate graph
		//Textbox/A=LT "XY data loaded from " + S_fileName
	       DoWindow/F Plot_Manager
		return
	endif
	
	if(numCols==5)			//old USANS desmeared data
		String w0,w1,w2,n0,n1,n2,w3,n3,w4,n4
		Variable rr,gg,bb
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName+"_q"),0)
		w1 = CleanupName((S_fileName+"_i"),0)
		w2 = CleanupName((S_fileName+"_s"),0)
		w3 = CleanupName((S_fileName+"_ism"),0)
		w4 = CleanupName((S_fileName+"_fit_ism"),0)
		
		if(exists(w0) !=0)		//the wave already exists
			DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves $n0,$n1,$n2,$n3,$n4		// kill the default waveX that were loaded
				String/G root:myGlobals:gLastFileName = filename		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif
		
////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		Duplicate/O $n3, $w3
		Duplicate/O $n4, $w4
		KillWaves $n0,$n1,$n2,$n3,$n4
		
		String/G root:myGlobals:gLastFileName = filename
		
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
		
			// if target window is a graph, and user wants to append, do so
		if(WinType("") == 1)
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $w1 vs $w0
				ModifyGraph mode=3,marker=29,msize=2,rgb ($w1) =(rr,gg,bb),tickUnit=1,grid=1,mirror=2
				ErrorBars $w1 Y,wave=($w2,$w2)
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode=3,marker=29,msize=2,rgb=(rr,gg,bb),tickUnit=1,grid=1,mirror=2
				ErrorBars $w1 Y,wave=($w2,$w2)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=29,msize=2,rgb=(rr,gg,bb),tickUnit=1,grid=1,mirror=2
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
	
		return
	endif
	
End

//load the data specified by fileStr (a full path:name)
// Does not graph the data - just loads it
//
Proc LoadOneDDataWithName(fileStr)
	String fileStr
	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A/Q fileStr
	String fileName = S_fileName
	Variable numCols = V_flag
	
	//changes JIL
	if(numCols==2)		//no errors	
		n1 = StringFromList(1, S_waveNames ,";" )		
		Duplicate/O $("root:"+n1), errorTmp
		errorTmp = 0.01*(errorTmp)+ 0.03*sqrt(errorTmp)
		S_waveNames+="errorTmp;"
		numCols=3
	endif

	if(numCols==3)
		String w0,w1,w2,n0,n1,n2,wt
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		wt = CleanupName((S_fileName + "wt"),0)		//create a name for the weighting wave
		
		if(exists(w0) !=0)
//				DoAlert 0,"This file has already been loaded. Use Append to Graph..."
//				KillWaves $n0,$n1,$n2		// kill the default waveX that were loaded
//				return
			DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves/Z $n0,$n1,$n2		// kill the default waveX that were loaded
				String/G root:myGlobals:gLastFileName = filename		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif
		
		////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		KillWaves $n0,$n1,$n2
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		String/G root:myGlobals:gLastFileName = filename
		String/G gQVals = w0
		String/G gInten = w1
		String/G gSigma = w2
	
	endif
	
	if(numCols == 6)
		String w0,w1,w2,n0,n1,n2,wt
		String w3,w4,w5,n3,n4,n5			//3 extra waves to load
		
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		n5 = StringFromList(5, S_waveNames ,";" )
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName + "_q"),0)
		w1 = CleanupName((S_fileName + "_i"),0)
		w2 = CleanupName((S_fileName + "_s"),0)
		w3 = CleanupName((S_fileName + "sq"),0)
		w4 = CleanupName((S_fileName + "qb"),0)
		w5 = CleanupName((S_fileName + "fs"),0)
		wt = CleanupName((S_fileName + "wt"),0)		//create a name for the weighting wave
		
		if(exists(w0) !=0)		//the wave already exists
//				DoAlert 0,"This file has already been loaded."
//				KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
//				return		//quits the macro
			DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
				String/G root:myGlobals:gLastFileName = filename		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif

////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		Duplicate/O $n3, $w3
		Duplicate/O $n4, $w4
		Duplicate/O $n5, $w5
		KillWaves $n0,$n1,$n2,$n3,$n4,$n5
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// copy waves to global strings for use in the smearing calculation
		String/G root:myGlobals:gLastFileName = filename
		String/G gQVals = w0
		String/G gInten = w1
		String/G gSigma = w2
		String/G gSig_Q = w3
		String/G gQ_bar = w4
		String/G gShadow = w5
		
	endif

	if(numCols==5)
		String w0,w1,w2,n0,n1,n2,w3,n3,w4,n4
		Variable rr,gg,bb
		
		// put the names of the three loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		
		
		//remove the semicolon AND period from files from the VAX
		w0 = CleanupName((S_fileName+"_q"),0)
		w1 = CleanupName((S_fileName+"_i"),0)
		w2 = CleanupName((S_fileName+"_s"),0)
		w3 = CleanupName((S_fileName+"_ism"),0)
		w4 = CleanupName((S_fileName+"_fit_ism"),0)
		
		if(exists(w0) !=0)		//the wave already exists
			DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves $n0,$n1,$n2,$n3,$n4		// kill the default waveX that were loaded
				if(DataFolderExists("root:myGlobals"))
					String/G root:myGlobals:gLastFileName = filename
				endif		//set the last file loaded to the one NOT loaded
				return		//quits the macro
			endif
		endif
		
		////overwrite the existing data, if it exists
		Duplicate/O $n0, $w0
		Duplicate/O $n1, $w1
		Duplicate/O $n2, $w2
		Duplicate/O $n3, $w3
		Duplicate/O $n4, $w4
		KillWaves $n0,$n1,$n2,$n3,$n4
	
		if(DataFolderExists("root:myGlobals"))
			String/G root:myGlobals:gLastFileName = filename
		endif

	endif
End



//////////////////////////////////////////
Proc Show_Plot_Manager()
	DoWindow/F Plot_Manager
	if(V_flag==0)
		Plot_Manager()
	endif
End

Proc Plot_Manager() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(658,347,920,562)/K=1
	DoWindow/C Plot_Manager
	ModifyPanel cbRGB=(37265,65535,32896),fixedSize=1
	Button button0,pos={161,178},size={50,20},proc=PlotManager_Done,title="Done"
	PopupMenu popup0,pos={11,50},size={211,20},title="Data in Memory"
	PopupMenu popup0,mode=1,value= #"OneDDataInMemory()"
	Button button1,pos={60,14},size={140,20},proc=PlotManger_Load,title="Load Data From File"
	Button button2,pos={118,84},size={100,20},proc=PlotManager_Append,title="Append Data"
	Button button3,pos={11,84},size={80,20},proc=PlotManager_newGraph,title="New Graph"
	Button button4,pos={11,118},size={220,20},proc=PlotManager_Kill,title="Remove Selection From Memory"
	Button button5,pos={11,148},size={220,20},proc=PlotManager_KillAll,title="Remove All Data From Memory"
EndMacro

//lists the intensity waves in the current data folder
// only looks for data ending in "i"
//
Function/S OneDDataInMemory()
	//SetDataFolder root:
	String list = WaveList("*i", ";", "" )
	list = SortList(list,";",0)			//re-alphabetize the list
	return(list)
end


Function PlotManager_Done(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K Plot_Manager
End

Proc PlotManger_Load(ctrlName) : ButtonControl
	String ctrlName
	
	OneDLoader_Panel()
	//LoadOneDData()
	ControlUpdate/W=Plot_Manager popup0
End

Function PlotManager_Append(ctrlName) : ButtonControl
	String ctrlName
	//appends data set from memory
	String iStr,qStr,eStr
	Variable rr,gg,bb
	
	//get the current selection
	ControlInfo popup0
	if(strlen(S_Value)==0)
		Abort "You must load data from a file into memory before appending the data"
	Endif
	
	PM_doAppend(S_Value)
	
	DoWindow/F Plot_Manager
End

//actually does the appending
//pass it the name of the wave, find the q-i-s waves
Function PM_doAppend(iStr)
	String iStr
	//appends data set from memory
	String qStr,eStr
	Variable rr,gg,bb
	
	if(cmpstr(WinList("*", ";","WIN:1"),"") == 0 )
		DoAlert 0,"There are no open graphs. Please use the New Graph button"
		return(0)
	endif
	
	//this assumes that iStr IS the i-wave, and the name ends in "i"
	qStr=iStr[0,strlen(iStr)-2]+"q"
	eStr=iStr[0,strlen(iStr)-2]+"s"
	
	rr = abs(trunc(enoise(65535)))
	gg = abs(trunc(enoise(65535)))
	bb = abs(trunc(enoise(65535)))
	
	// append to whatever is top-most graph
	AppendToGraph $iStr vs $qStr
	ModifyGraph log=1,mode($istr)=3,marker($iStr)=19,msize($iStr)=2,rgb($iStr)=(rr,gg,bb)
	ErrorBars $iStr Y,wave=($eStr,$eStr)
End

Proc PlotManager_newGraph(ctrlName) : ButtonControl
	String ctrlName

	String iStr,qStr,eStr
	Variable rr,gg,bb
	
	//get the current selection
	ControlInfo popup0
	if(strlen(S_Value)==0)
		Abort "You must load data from a file into memory before plotting the data"
	Endif
	PM_doNewGraph(S_Value)
	DoWindow/F Plot_Manager
End

Function PM_doNewGraph(iStr)
	String iStr

	String qStr,eStr
	Variable rr,gg,bb
	
	//iStr will end in "i"
	qStr=iStr[0,strlen(iStr)-2]+"q"
	eStr=iStr[0,strlen(iStr)-2]+"s"
	
	rr = abs(trunc(enoise(65535)))
	gg = abs(trunc(enoise(65535)))
	bb = abs(trunc(enoise(65535)))
	
	// always make a new graph
	Display $iStr vs $qStr
	ModifyGraph log=1,mode($istr)=3,marker($iStr)=19,msize($iStr)=2,rgb=(rr,gg,bb)
	ModifyGraph grid=1,mirror=2,standoff=0
	ErrorBars $iStr Y,wave=($eStr,$eStr)
	
	Label left "I(q)"
	SVAR angst = root:myGlobals:gAngstStr
	Label bottom "q ("+angst+"\\S-1\\M)"
	
	Legend
End

//kill the specified wave (if possible)
Proc PlotManager_Kill(ctrlName) : ButtonControl
	String ctrlName
	
	String iStr,qStr,eStr,sqStr,qbStr,fsStr,wtStr

	ControlInfo popup0
	iStr=S_Value		//this will end in "i"
	qStr=iStr[0,strlen(iStr)-2]+"q"
	eStr=iStr[0,strlen(iStr)-2]+"s"
	sqStr=iStr[0,strlen(iStr)-3]+"sq"			//remove the underscore from these names
	qbStr=iStr[0,strlen(iStr)-3]+"qb"
	fsStr=iStr[0,strlen(iStr)-3]+"fs"
	wtStr=iStr[0,strlen(iStr)-3]+"wt"
	
	CheckDisplayed/A $iStr			//is the intensity data in use?
	if(V_flag==0)
		Killwaves/Z $iStr,$qStr,$eStr,$sqStr,$qbStr,$fsStr,$wtStr
	endif
	ControlUpdate popup0		//refresh the popup, very important if last item removed
End

//kill the specified wave (if possible)
Proc PlotManager_KillAll(ctrlName) : ButtonControl
	String ctrlName
	
	String iStr,qStr,eStr,sqStr,qbStr,fsStr,wtStr

	String list =  OneDDataInMemory()
	Variable num=ItemsInList(list),ii
	
	ii=0
	do	
		iStr=StringFromList(ii, list  ,";")
		qStr=iStr[0,strlen(iStr)-2]+"q"
		eStr=iStr[0,strlen(iStr)-2]+"s"
		sqStr=iStr[0,strlen(iStr)-3]+"sq"		//remove the underscore from these names
		qbStr=iStr[0,strlen(iStr)-3]+"qb"
		fsStr=iStr[0,strlen(iStr)-3]+"fs"
		wtStr=iStr[0,strlen(iStr)-3]+"wt"
		
		CheckDisplayed/A $iStr			//is the intensity data in use?
		if(V_flag==0)
			Killwaves/Z $iStr,$qStr,$eStr,$sqStr,$qbStr,$fsStr,$wtStr
		endif
		ii+=1
	while(ii<num)
	ControlUpdate popup0		//refresh the popup, very important if all items are removed
End

Proc Init_OneDLoader()
	//create the data folder
	NewDataFolder/O/S root:myGlobals:OneDLoader
	//create the waves
	Make/O/T/N=1 fileWave=""
	Make/O/N=1 selWave=0
	Variable/G ind=0
	SetDataFolder root:
End

// main procedure for invoking the raw to ascii panel
// initializes each time to make sure
Proc OneDLoader_Panel()
	Init_OneDLoader()
	DoWindow/F OneDLoader
	if(V_Flag==0)
		OneDLoader()
	endif
	 OneDLoader_GetListButton("")
End

//procedure for drawing the simple panel to export raw->ascii
//
Proc OneDLoader()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(501,97,885,282) /K=2
	DoWindow/C OneDLoader
	SetDrawLayer UserBack
	DrawText 237,38,"Shift-click to load"
	DrawText 254,58,"multiple files"
	ListBox fileList,pos={4,3},size={206,179}
	ListBox fileList,listWave=root:myGlobals:OneDLoader:fileWave
	ListBox fileList,selWave=root:myGlobals:OneDLoader:selWave,mode= 4
	Button button0,pos={239,78},size={110,20},proc=OneDLoader_LoadButton,title="Load File(s)"
	Button button0,help={"Loads the selected files into memory and will graph them if that option is checked"}
	Button button1,pos={260,150},size={70,20},proc=OneDLoader_CancelButton,title="Cancel"
	Button button1,help={"Closes the panel without loading any data"}
	CheckBox check0,pos={242,112},size={113,14},title="All in a new graph?",value= 1
	CheckBox check0,help={"Makes a new graph with all of the selected data. Otherwise, you will be prompted to append data"}
//	Button button3,pos={230,16},size={60,20},proc=OneDLoader_GetListButton,title="Get List"
//	Button button3,help={"Refreshes the file listing"}
EndMacro

//closes the panel if user cancels
Function OneDLoader_CancelButton(ctrlName) : ButtonControl
	String ctrlName

	//kill the panel
	DoWindow/K OneDLoader
	return(0)
End

//filters to remove only the files that are named like a raw data file, i.e. "*.SAn"
//does not check to see if they really are RAW files though...(too tedious)
Function OneDLoader_GetListButton(ctrlName) : ButtonControl
	String ctrlName
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	Endif
	
	String newList = ReducedDataFileList("")
	Variable num
	
	num=ItemsInList(newlist,";")
	WAVE/T fileWave=$"root:myGlobals:OneDLoader:fileWave"
	WAVE selWave=$"root:myGlobals:OneDLoader:selWave"
	Redimension/N=(num) fileWave
	Redimension/N=(num) selWave
	fileWave = StringFromList(p,newlist,";")
	Sort filewave,filewave
End

Function OneDLoader_LoadButton(ctrlName) : ButtonControl
	String ctrlName
	
	//loop through the selected files in the list...
	Wave/T fileWave=$"root:myGlobals:OneDLoader:fileWave"
	Wave sel=$"root:myGlobals:OneDLoader:selWave"
	Variable num=numpnts(sel),ii=0
	String fname="",pathStr="",fullPath="",newFileName=""
	
	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
	Variable doGraph,cnt

	ControlInfo check0
	doGraph=V_Value
	cnt=0
	// get the current state
	do
		if(sel[ii] == 1)
			fname=pathStr + FindValidFilename(fileWave[ii])		//in case of VAX version numbers
			Execute "LoadOneDDataWithName(\""+fname+"\")"
			cnt += 1 	//a file was loaded
			if(doGraph==1)
				SVAR  fileName = root:myGlobals:gLastFileName		//last file loaded
				if(cnt==1)
					PM_doNewGraph(  CleanupName((fileName + "_i"),0) )		//create the name of the intensity wave loaded
				else
					PM_doAppend(  CleanupName((fileName + "_i"),0) )	
				endif
			endif
		endif
		ii+=1
	while(ii<num)
	//kill the panel
	DoWindow/K OneDLoader
	return(0)
End
