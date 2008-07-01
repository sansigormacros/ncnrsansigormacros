#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.0

//loads 3-column or 6-column data into current folder, typically root:
// 5-column data from average/qsig i loaded  below with U_LoadUSANSData() procedure
//
//
Proc U_LoadOneDData()

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
		KillWaves $n0,$n1,$n2
		
		if(DataFolderExists("root:myGlobals"))
			String/G root:myGlobals:gLastFileName = filename
		endif
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// set data units for the waves
//			if(DataFolderExists("root:myGlobals"))
//				String angst = root:myGlobals:gAngstStr
//			else
			String angst = "A"
//			endif
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
				ModifyGraph tickUnit=1
				ErrorBars $w1 Y,wave=($w2,$w2)
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
				ModifyGraph grid=1,mirror=2,standoff=0
				ModifyGraph tickUnit=1
				ErrorBars $w1 Y,wave=($w2,$w2)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
			ModifyGraph grid=1,mirror=2,standoff=0
			ModifyGraph tickUnit=1
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
			
		// Annotate graph
		//Textbox/A=LT "XY data loaded from " + S_fileName
	    DoWindow/F Plot_Manager
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
		Duplicate/O $n5, $w5
		KillWaves $n0,$n1,$n2,$n3,$n4,$n5
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// copy waves to global strings for use in the smearing calculation
		if(DataFolderExists("root:myGlobals"))
			String/G root:myGlobals:gLastFileName = filename
		endif
		String/G gQVals = w0
		String/G gSig_Q = w3
		String/G gQ_bar = w4
		String/G gShadow = w5
		
		// set data units for the waves
//			if(DataFolderExists("root:myGlobals"))
//				String angst = root:myGlobals:gAngstStr
//			else
			String angst = "A"
//			endif
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
				ModifyGraph tickUnit=1
				ErrorBars $w1 Y,wave=($w2,$w2)
			else
			//new graph
				Display $w1 vs $w0
				ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
				ModifyGraph grid=1,mirror=2,standoff=0
				ModifyGraph tickUnit=1
				ErrorBars $w1 Y,wave=($w2,$w2)
				Legend
			endif
		else
		// graph window was not target, make new one
			Display $w1 vs $w0
			ModifyGraph log=1,mode=3,marker=19,msize=2,rgb=(rr,gg,bb)
			ModifyGraph grid=1,mirror=2,standoff=0
			ModifyGraph tickUnit=1
			ErrorBars $w1 Y,wave=($w2,$w2)
			Legend
		endif
			
		// Annotate graph
		//Textbox/A=LT "XY data loaded from " + S_fileName
	    DoWindow/F Plot_Manager
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
	
	endif
End


//load the data specified by fileStr (a full path:name)
// Does not graph the data - just loads it
//
Proc U_LoadOneDDataWithName(fileStr)
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
			DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves/Z $n0,$n1,$n2		// kill the default waveX that were loaded
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
		KillWaves $n0,$n1,$n2
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		if(DataFolderExists("root:myGlobals"))
			String/G root:myGlobals:gLastFileName = filename
		endif
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
			DoAlert 1,"This file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
			if(V_flag==2)	//user selected No
				KillWaves $n0,$n1,$n2,$n3,$n4,$n5		// kill the default waveX that were loaded
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
		Duplicate/O $n5, $w5
		KillWaves $n0,$n1,$n2,$n3,$n4,$n5
		
		Duplicate/o $w2 $wt
		$wt = 1/$w2		//assign the weighting wave
		
		// copy waves to global strings for use in the smearing calculation
		if(DataFolderExists("root:myGlobals"))
			String/G root:myGlobals:gLastFileName = filename
		endif
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


//procedure for loading desmeared USANS data in the format (5-columns)
// qvals - I(q) - sig I - Ism(q) - fitted Ism(q)
//no weighting wave is created (not needed in IGOR 4)
Proc U_LoadUSANSData()

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A
   String filename = S_fileName
	
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
		
End
