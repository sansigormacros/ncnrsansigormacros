#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0 


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
	if(v_flag==0) // PathInfo returns path doesn't exist
		err = PickPath()//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif

	CreateTransGlobals()	
	Variable ScatFileTableExists
	ScatFileTableExists = WinType("ScatterFileTable")
	//if(v_flag==0)
	If(!ScatFileTableExists)
		BuildScatTableWindow()
		ModifyTable width(Point)=18
		
		ModifyTable width(root:myGlobals:TransHeaderInfo:S_SDD)			= 40
		ModifyTable width(root:myGlobals:TransHeaderInfo:S_Lambda)			= 40
		ModifyTable width(root:myGlobals:TransHeaderInfo:S_Transmission)	= 60
		
		ModifyTable rgb(root:myGlobals:TransHeaderInfo:S_Filenames)		= (0,0,65535)
		ModifyTable width(root:myGlobals:TransHeaderInfo:S_Filenames)		= 105
		ModifyTable width(root:myGlobals:TransHeaderInfo:T_Filenames)		= 105
		ModifyTable width(root:myGlobals:TransHeaderInfo:EMP_Filenames)	= 105
		
		ModifyTable width(root:myGlobals:TransHeaderInfo:S_Labels)			= 140
		ModifyTable width(root:myGlobals:TransHeaderInfo:T_Labels)			= 140
	Endif

	DoWindow/F ScatterFileTable //bring window to front
	
	//open xml file
	variable fileID = getReport()
	if(fileID<=1)
		Abort "Cannot open experimental report file " + S_filename
	endif
	
	//currently have 2 function to read the 2 types of report files, with and without sample environment
	//trying to merge into 1. 	
	
	//getFileAssociations(fileID)
	getFileAssociationsSampleEnv(fileID)
	
	//close xml file without save
	XMLclosefile(fileID,0)
	
	//Read data from datafile into globals
	GetTransHeaderInfoToWave()

	//Sort entries based on date
	//	SortGlobals(0)

	//position the windows nicely
	//	AutoPositionWindow/M=1/R=ScatterFileTable
	//	DoWindow/F Trans_Panel //nha Trans_Panel not required?
	
End

Function getReport()
	// Open the experiment report file(s) in this path 
	variable refnum
	Open/D/R /M="Open experiment report file" /T=".xml" refnum
	if(cmpstr(S_filename,"")==0)
		Abort "No experimental report file selected"
	Endif  
	variable fileID = XMLopenFile(S_filename)
	
	return fileID

End

Function getFileAssociations(fileID)

	// nha 22/1/2010 - new xml report structure, from December 2009
	// incompatible with previous report structure
	// assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf

	variable fileID
	variable ii,jj

	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T xmlContent = $"root:M_xmlcontent"
	Wave/T xmlContentNodes = $"root:W_xmlcontentnodes"


	string prefix = "QKK"
	string suffix = ".nx.hdf"
	string full_fname, xpath, xpath_config, xpath_type, xpath_fname, xmlString, list, fname
	variable nConfig, tSamples, sSamples
	wave w_fname
	
	//determine no. of samples
	xpath = "/report//config" //root node of report
	XMLWaveFmXpath(fileID,xpath,"","")
	nConfig = DimSize(xmlContentNodes,0)
	
	ii=1
	do 
		xpath_config = "/report/config[" + num2str(ii) + "]"  //there may be multiple config per report
		
		xpath_fname = xpath_config + "/transmission//sample[@type = 'sample']/@runId" //select all sample nodes of type sample and return runId attribute
		XMLwaveFmXpath(fileID,xpath_fname,"","")
		tSamples = DimSize(xmlContentNodes,0)

		if(tSamples>=1)  //sample exist under the transmission node - probably a more elegant way of get these values into T_Filenames
			jj=0
			do
				full_fname = prefix + xmlcontent[0][jj] + suffix
				InsertPoints jj,1,T_Filenames
				if(strlen(xmlcontent[0][jj])<7) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
					T_Filenames[jj] = ""
				else
					T_Filenames[jj] = full_fname
				endif
				jj+=1
			while (jj<tSamples)
		endif
		
		xpath_fname = xpath_config + "/scattering//sample[@type = 'sample']/@runId" //select all sample nodes of type sample and return runId attribute
		XMLwaveFmXpath(fileID,xpath_fname,"","")
		sSamples = DimSize(xmlContentNodes,0)

		if(sSamples>=1)  //sample exist under the scattering node 
			jj=0
			do
				full_fname = prefix + xmlcontent[0][jj] + suffix
				InsertPoints jj,1,S_Filenames
				if(strlen(xmlcontent[0][jj])<7) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
					S_Filenames[jj] = ""
				else
					S_Filenames[jj] = full_fname
				endif
				jj+=1
			while (jj<sSamples)
		endif
		
		if(sSamples!=tSamples)
			// the experiment model from Dec 2009 should have equal numbers of scattering and trans 
			// sample, according to Tony Lam, although the string may be ""
			//abort "The number transmissions samples in the report file does not equal the number of scattering files"
		endif
		
		// use empty beam for transmission, not empty cell
		//empty beam transmission
		xpath_fname = xpath_config + "/emptyBeamTransmissionRunId" //select all sample nodes of type sample and return runId attribute
		XMLwaveFmXpath(fileID,xpath_fname,"","")
		if(sSamples>=1)  //sample exist under the scattering node 
			jj=0
			do
				full_fname = prefix + xmlcontent[0][0] + suffix
				InsertPoints jj,1,EMP_Filenames
				if(strlen(xmlcontent[0][0])<7) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
					EMP_Filenames[jj] = ""
				else
					EMP_Filenames[jj] = full_fname
				endif
				jj+=1
			while (jj<sSamples)
		endif		
		ii+=1
	while(ii<nConfig+1) //ii is using one-based counting because xml is one-based
	
	//delete rows with blanks
	ii=0
	do
		if(cmpstr(T_Filenames[ii],"")==0 || cmpstr(S_Filenames[ii],"")==0 || cmpstr(EMP_Filenames[ii],"")==0)
			print "Row is incomplete and therefore being deleted " + T_Filenames[ii] + " " + S_Filenames[ii] + " " + EMP_Filenames[ii]
			DeletePoints ii,1,T_Filenames,S_Filenames,EMP_Filenames
			ii-=1
		endif
		ii+=1
	while (ii<DimSize(S_Filenames,0))
		
			
	//Check if the files in the report file are available in the path.
	//
	
	//Put up a dialog of the number of missing files and their filenames. ABORT or CONTINUE
	//

End 

Function/S pickFileInCatPath(fileFilterStr, messageStr)

	string fileFilterStr
	string messageStr

	variable refNum
	Open/D/R /F=fileFilterStr /M=messageStr refNum

	variable len = strlen(S_fileName)
	variable lastSepIndex = strsearch(S_fileName, ":", inf, 1)
	if (lastSepIndex == -1)
		return S_fileName
	else
		svar defaultPath = root:myGlobals:gCatPathStr
		string selectedPath
		variable q = 0
							
		for (selectedPath = ""; q <= lastSepIndex; q += 1)
			selectedPath += S_fileName[q]
		endfor
							
		if (cmpstr(defaultPath, selectedPath) == 0) // path does match
		
			string result
			for (result = ""; q < len; q += 1)
				result += S_fileName[q]
			endfor
			return result
			
		else // path doesn't match
			DoAlert 1, "You need to pick a file in the same location as the report file. Would you like to pick another file?"
			
			if (V_flag == 1) // answer was yes
				return pickFileInCatPath(fileFilterStr, messageStr)
			else
				return ""
			endif
		endif
	endif
						
End

Function getFileAssociationsSampleEnv(fileID)

	// nha 22/1/2010 - new xml report structure, from December 2009
	// incompatible with previous report structure
	// assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf

	variable fileID
	variable ii, jj
	variable kkS, kkSmax, kkT, kkTmax, kkE
	variable kkToffset
	
	variable s_pos, t_pos

	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	
//	Wave/T xmlContent = $"root:Packages:NIST:M_xmlcontent"
//	Wave/T xmlContentNodes = $"root:Packages:NIST:W_xmlcontentnodes" // this location doesn't work. Don't know why. nha ???

	// "root:M_xmlcontent" and "root:W_xmlcontentnodes" is not available until XMLWaveFmXpath has been called the first time! [davidm]
	//Wave/T xmlContent = $"root:M_xmlcontent"                             // this has been move to the lines after: XMLWaveFmXpath
	//Wave/T xmlContentNodes = $"root:W_xmlcontentnodes"
	
	// "root:M_listXPath" is not available until xmlListXPath(fileID,xpath,"")  has been called the first time!  [davidm]
	// Wave/T listXPath = $"root:M_listXPath"  // this has been move to the line after: err = xmlListXPath(fileID,xpath,"") 

	string prefix = "QKK"
	string suffix = ".nx.hdf"
	string full_fname, xpath, xpath_SampleEnv, xpath_config, xpath_type, xpath_fname, xmlString, list, fname
	variable nSampleEnv, nConfig, tSamples, sSamples
	variable tSampleNum, sSampleNum, eSampleNum // used to accumulate the number of samples across multiple configs
	variable noRunIds

	variable hasSampleEnv
	variable err
	
	// to disable asking dialogs
	variable specifyTFile_Enabled		= 1 // 0: Disabled; 1: Enabled; 2: Always specify if missing
	variable specifySFile_Enabled		= 1
	variable specifyEMPFile_Enabled	= 1
	
	//in a report there are 0..n /sampleEnvironment
	//these have 1..n or 1..2 /config
		//these have a /transmission /scattering 
			//these have 1..n sample which may or maynot have a runId
		//config also has 0..1 /emptyCellTransmissionRunId    0..1 /emptyCellScatteringRunId    0..1 /emptyBeamTransmissionRunId 
	
	//determine no. of sampleEnvironment tags
	hasSampleEnv = 0
	xpath = "/report//sampleEnvironment" //root node of report - what happens if this xpath doesn't exist ???TEST
//	xpath = "/report//config"  // for test ??? nha
	
	//check if the file contains the required nodes
	//xmlelementlist(fileID)
	err = xmlListXPath(fileID,xpath,"") // this creates a three column text wave, M_listXPath
	
	Wave/T listXPath = $"root:M_listXPath"

	if (err != 0)
		abort "Can't read xml file"
	endif
	
	if (DimSize(listXPath,0) > 0)
		hasSampleEnv = 1 
	else
		xpath = "/report//config"
	endif

	nSampleEnv = 0 
	if (hasSampleEnv)
		XMLWaveFmXpath(fileID,xpath,"","")
		
		Wave/T xmlContentNodes = $"root:W_xmlcontentnodes" // [davidm]
		
		nSampleEnv = DimSize(xmlContentNodes,0)
	endif 
	ii=1 //sample environment iterator
	
	tSampleNum = 0
	sSampleNum = 0
	eSampleNum = 0 

	do 
		if (hasSampleEnv)
			xpath_SampleEnv = "/report/sampleEnvironment[" + num2str(ii) + "]"  //there may be multiple sampleEnvironment per report
		else
			xpath_SampleEnv = "/report"
		endif
			
		//determine no. of config tags
		xpath = xpath_SampleEnv + "//config" 
		XMLWaveFmXpath(fileID,xpath,"","")

		Wave/T xmlContent = $"root:M_xmlcontent"				// [davidm]
		Wave/T xmlContentNodes = $"root:W_xmlcontentnodes"
		
		nConfig = DimSize(xmlContentNodes,0)
		jj=1  // config iterator

		do
			//Execute  "ProgressWindow spin"
			xpath_config = xpath_SampleEnv + "/config[" + num2str(jj) + "]" //there may be multiple config per report

			// get the positions of the s-samples (used to check if report file does not contain all samples)
			xpath_fname = xpath_config + "/scattering//sample[@type = 'sample']/@position" //select all sample nodes of type sample and return position attribute
			XMLwaveFmXpath(fileID,xpath_fname,"","")
			Duplicate /FREE/T xmlcontent, S_Positions
			
			// get the runIds of the s-sampels
			xpath_fname = xpath_config + "/scattering//sample[@type = 'sample']/@runId" //select all sample nodes of type sample and return runId attribute
			XMLwaveFmXpath(fileID,xpath_fname,"","")
			sSamples = DimSize(xmlContentNodes,0)
			kkSmax = sSamples - 1
			
			// if no runIds are specified then xmlcontent is empty
			noRunIds = DimSize(xmlcontent,0) == 0

			// s-sample exist under the scattering node 
			if (sSamples > 0) 
				for (kkS = 0; kkS <= kkSmax; kkS += 1) // scattering sample iterator
				
					InsertPoints sSampleNum + kkS, 1, S_Filenames
					
					if (noRunIds)
						S_Filenames[sSampleNum + kkS] = ""
					else
						full_fname = prefix + xmlcontent[0][kkS] + suffix
						if (strlen(xmlcontent[0][kkS]) < 7) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
							S_Filenames[sSampleNum + kkS] = ""
						else
							S_Filenames[sSampleNum + kkS] = full_fname
						endif
					endif
					
				endfor
			endif

			// get the positions of the t-samples (used to check if report file does not contain samples)
			xpath_fname = xpath_config + "/transmission//sample[@type = 'sample']/@position" //select all sample nodes of type sample and return position attribute
			XMLwaveFmXpath(fileID,xpath_fname,"","")
			Duplicate /FREE/T xmlcontent, T_Positions
			
			// get the runIds of the t-sampels
			xpath_fname = xpath_config + "/transmission//sample[@type = 'sample']/@runId" //select all sample nodes of type sample and return runId attribute
			XMLwaveFmXpath(fileID,xpath_fname,"","")
			tSamples = DimSize(xmlContentNodes,0)
			kkTmax = tSamples - 1
			
			// if no runIds are specified then xmlcontent is empty
			noRunIds = DimSize(xmlcontent,0) == 0

			// we need to know how many t-samples are added (if report file does not contain all t-sampels)
			kkToffset = 0

			// t-sample exist under the transmission node
			if (tSamples > 0) 
				for (kkS = 0, kkT = 0; kkT <= kkTmax;) // transmission sample iterator

					// we need to compare the position of the current s- and t-sample
					if (kkS <= kkSmax)
						s_pos = str2num(S_Positions[0][kkS])
					else
						s_pos = Inf // this means that at least one s-sample is missing
					endif
					t_pos = str2num(T_Positions[0][kkT])
					
					if (s_pos < t_pos) // t-sample is missing
					
						if (specifyTFile_Enabled)
							DoAlert 1, "For the S-File \"" + S_Filenames[tSampleNum+kkS] + "\" (position " + S_Positions[0][kkS] + ") no T-File was specified. Would you like to select one now?"
						else
							V_flag = 0 // if disabled then answer is always no
						endif
					
						// insert new t-sample
						InsertPoints tSampleNum + kkT + kkToffset, 1, T_Filenames
						if (V_flag != 1) // answer was no
							T_Filenames[tSampleNum + kkT + kkToffset] = ""
							
							if (specifyTFile_Enabled == 1)
								DoAlert 1, "Would you like to specify any missing T-Files?"
								if (V_flag != 1) // answer was no
									specifyTFile_Enabled = 0
								else
									specifyTFile_Enabled = 2
								endif
							endif
							
						else
							T_Filenames[tSampleNum + kkT + kkToffset] = pickFileInCatPath("Hierarchical Data Format (*.nx.hdf):.nx.hdf;All Files:.*;", "Select the corresponding T-File")
						endif
						
						kkToffset += 1
						kkS += 1
						tSamples += 1
						
					else // insert t-sample from report file
					
						InsertPoints tSampleNum + kkT + kkToffset, 1, T_Filenames
					
						if (noRunIds)
							T_Filenames[tSampleNum + kkT + kkToffset] = ""
						else					
							full_fname = prefix + xmlcontent[0][kkT] + suffix
							if(strlen(xmlcontent[0][kkT]) < 7) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
								T_Filenames[tSampleNum + kkT + kkToffset] = ""
							else
								T_Filenames[tSampleNum + kkT + kkToffset] = full_fname
							endif
						endif
						
						kkT += 1
						
						if (s_pos == t_pos)
							kkS += 1
						else // s-sample is missing
						
							if (specifySFile_Enabled)
								DoAlert 1, "For the T-File \"" + T_Filenames[tSampleNum+kkT] + "\" (position " + T_Positions[0][kkT] + ") no S-File was specified. Would you like to select one now?"
							else
								V_flag = 0 // if disabled then answer is always no
							endif
						
							// insert new s-sample
							InsertPoints tSampleNum + kkT + kkToffset, 1, S_Filenames
							if (V_flag != 1) // answer was no
								S_Filenames[tSampleNum + kkT + kkToffset] = ""
								
								if (specifySFile_Enabled == 1)
									DoAlert 1, "Would you like to specify any missing S-Files?"
									if (V_flag != 1) // answer was no
										specifySFile_Enabled = 0
									else
										specifySFile_Enabled = 2
									endif
								endif
							
							else
								S_Filenames[tSampleNum + kkT + kkToffset] = pickFileInCatPath("Hierarchical Data Format (*.nx.hdf):.nx.hdf;All Files:.*;", "Select the corresponding S-File")
							endif
						
							sSamples += 1
						endif
					endif
				endfor
			endif

			if (sSamples > tSamples) // checks if t-samples are still missing
				do
					if (specifyTFile_Enabled)
						DoAlert 1, "For the S-File \"" + S_Filenames[tSampleNum+kkS] + "\" (position " + S_Positions[0][kkS] + ") no T-File was specified. Would you like to select one now?"
					else
						V_flag = 0 // if disabled then answer is always no
					endif
							
					// insert new t-sample
					InsertPoints tSampleNum + kkT + kkToffset, 1, T_Filenames
					if (V_flag != 1) // answer was no
					
						T_Filenames[tSampleNum + kkT + kkToffset] = ""
						
						if (specifyTFile_Enabled == 1)
							DoAlert 1, "Would you like to specify any missing T-Files?"
							if (V_flag != 1) // answer was no
								specifyTFile_Enabled = 0
							else
								specifyTFile_Enabled = 2
							endif
						endif
						
					else
						T_Filenames[tSampleNum + kkT + kkToffset] = pickFileInCatPath("Hierarchical Data Format (*.nx.hdf):.nx.hdf;All Files:.*;", "Select the corresponding T-File")
					endif
					
					kkToffset += 1
					kkS += 1
					tSamples += 1

				while (sSamples > tSamples)
			endif
				
			tSampleNum += tSamples 
			sSampleNum += sSamples

			// empty beam transmission
			xpath_fname = xpath_config + "/emptyBeamTransmissionRunId"
			XMLwaveFmXpath(fileID,xpath_fname,"","")
			
			if (sSamples>=1)  //sample exist under the scattering node 
				
				if (WaveDims(xmlcontent) && (strlen(xmlcontent[0][0]) == 7)) // assumes the ANSTO filename convention QKKnnnnnnn.nx.hdf
					full_fname = prefix + xmlcontent[0][0] + suffix
				else
					kkS = sSampleNum-sSamples
					string sFilenames = S_Filenames[kkS]
					
					for (kkS += 1; kkS < sSampleNum; kkS += 1)
						if (strlen(S_Filenames[kkS]) > 0)
							sFilenames = sFilenames + ", " + S_Filenames[kkS]
						endif
					endfor

					// only ask if sFilenames is not empty
					full_fname = ""
					if (strlen(sFilenames) > 0)
					
						if (specifyEMPFile_Enabled)
							DoAlert 1, "For the listed S-File(s), no appropriate EMP-File was specified. Would you like to select one now?\n" + sFilenames
						else
							V_flag = 0 // if disabled then answer is always no
						endif
							
						if (V_flag == 1) // answer was yes
							full_fname = pickFileInCatPath("Hierarchical Data Format (*.nx.hdf):.nx.hdf;All Files:.*;", "Select an EMP-File")
						elseif (specifyEMPFile_Enabled == 1)
							DoAlert 1, "Would you like to specify any missing EMP-Files?"
							if (V_flag != 1) // answer was no
								specifyEMPFile_Enabled = 0
							else
								specifyEMPFile_Enabled = 2
							endif
						endif
					endif
				endif
			
				kkE = 0
				do
					InsertPoints eSampleNum + kkE,1,EMP_Filenames
					EMP_Filenames[eSampleNum + kkE] = full_fname
					kkE += 1
				while (kkE < sSamples)
				
				eSampleNum += sSamples
			endif
			
			jj += 1
		while(jj<nConfig+1)
		ii+=1
	while(ii<nsampleEnv+1) //ii is using one-based counting because xml is one-based
	
	//delete rows with blanks
	// ??? testing without removal of blanks. nha. 
//	ii=0
//	do
//		if(cmpstr(T_Filenames[ii],"")==0 || cmpstr(S_Filenames[ii],"")==0 || cmpstr(EMP_Filenames[ii],"")==0)
//			print "Row is incomplete and therefore being deleted " + T_Filenames + " " + S_Filenames + " " + EMP_Filenames
//			DeletePoints ii,1,T_Filenames,S_Filenames,EMP_Filenames
//			ii-=1
//		endif
//		ii+=1
//	while (ii<DimSize(S_Filenames,0))
		
			
	//Check if the files in the report file are available in the path.
	//
	
	//Put up a dialog of the number of missing files and their filenames. ABORT or CONTINUE
	//

End 

//actually creates the table of scattering files
// - the waves must exist
//
Function BuildScatTableWindow()
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave/T T_Labels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   S_SDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_Lambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave   S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	Wave   T_SDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_Lambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	//	Wave   T_Transmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	//	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	Wave   EMP_x1= $"root:myGlobals:TransHeaderInfo:EMP_x1"
	Wave   EMP_x2= $"root:myGlobals:TransHeaderInfo:EMP_x2"
	Wave   EMP_y1= $"root:myGlobals:TransHeaderInfo:EMP_y1"
	Wave   EMP_y2= $"root:myGlobals:TransHeaderInfo:EMP_y2"
				
	Edit/K=1/W=(20,20,520,470) S_Filenames, T_Filenames, EMP_Filenames, S_Labels, T_Labels, S_SDD, T_SDD, S_Lambda, T_Lambda, S_Transmission, S_Whole, EMP_x1, EMP_x2, EMP_y1, EMP_y2 as "ScatteringFiles"
	
	String name="ScatterFileTable"
	DoWindow/C $name

End


//sorts each of the tables by date - does this by using the suffix "Annn"
// which is automatically supplied by the VAX (and can't be changed)
// - only problem may be "Z999" -> "A001" rollover
//
// sorts files alphabetically byt the sample label
// - consistent and descriptive sample labels really pay off here
//
Function SortGlobals(sortFlag)
	Variable sortFlag
	
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T T_Labels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   T_SDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_Lambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	//	Wave   T_Transmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	//	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"

	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave   S_SDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_Lambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave   S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	Wave   EMP_x1= $"root:myGlobals:TransHeaderInfo:EMP_x1"
	Wave   EMP_x2= $"root:myGlobals:TransHeaderInfo:EMP_x2"
	Wave   EMP_y1= $"root:myGlobals:TransHeaderInfo:EMP_y1"
	Wave   EMP_y2= $"root:myGlobals:TransHeaderInfo:EMP_y2"
	
	if(sortFlag == 0) // by date
		Sort S_Filenames, S_Filenames, S_Labels, S_SDD, S_Lambda, S_Transmission, S_Whole, EMP_Filenames, T_Filenames, T_Labels, T_SDD, T_Lambda, EMP_x1, EMP_x2, EMP_y1, EMP_y2 
	else  //by label
		Sort S_Labels, S_Labels, S_Filenames, S_SDD, S_Lambda, S_Transmission, S_Whole, EMP_Filenames, 	T_Filenames, T_Labels, T_SDD, T_Lambda, EMP_x1, EMP_x2, EMP_y1, EMP_y2
	endif
End

//reads the file and assigns header information to globals, which are read by the ScatteringTable.
//assumes that associations have been found in experiment report
//
//scat_fname - is the full path:name of the datafile (used by Open)
//
// takes care of all necessary open/close of file
//
Function GetTransHeaderInfoToWave()

	String s_fname,t_fname,emp_fname
	
	Variable lastPoint, ii

	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T S_Labels = $"root:myGlobals:TransHeaderInfo:S_Labels"
	Wave/T T_Labels = $"root:myGlobals:TransHeaderInfo:T_Labels"
	Wave   S_SDD = $"root:myGlobals:TransHeaderInfo:S_SDD"
	Wave   S_Lambda = $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Wave   S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave   S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	Wave   T_SDD = $"root:myGlobals:TransHeaderInfo:T_SDD"
	Wave   T_Lambda = $"root:myGlobals:TransHeaderInfo:T_Lambda"
	//	Wave   T_Transmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	//	Wave   T_Whole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Wave   EMP_x1= $"root:myGlobals:TransHeaderInfo:EMP_x1"
	Wave   EMP_x2= $"root:myGlobals:TransHeaderInfo:EMP_x2"
	Wave   EMP_y1= $"root:myGlobals:TransHeaderInfo:EMP_y1"
	Wave   EMP_y2= $"root:myGlobals:TransHeaderInfo:EMP_y2"

	lastPoint = numpnts(S_Filenames)
	PathInfo catPathName
	variable x1, x2, y1, y2
	
	variable FilesAreMissing = 0

	//Execute "ProgressWindow open, text=\"Loading Table...\""
	
	ii = 0
	do 
		s_fname = S_path + S_Filenames[ii]
		t_fname = S_path + T_Filenames[ii]
		emp_fname = S_path + EMP_Filenames[ii]

		//Execute "ProgressWindow text=\"Loading Table...\n" + S_Filenames[ii] + "\""
		
		InsertPoints ii,1,S_Labels
		InsertPoints ii,1,S_Transmission
		InsertPoints ii,1,S_Whole
		InsertPoints ii,1,S_SDD
		InsertPoints ii,1,S_Lambda
		InsertPoints ii,1,T_Labels
		//		InsertPoints ii,1,T_Transmission
		//		InsertPoints ii,1,T_Whole
		InsertPoints ii,1,T_SDD
		InsertPoints ii,1,T_Lambda
		InsertPoints ii,1,EMP_x1
		InsertPoints ii,1,EMP_x2
		InsertPoints ii,1,EMP_y1
		InsertPoints ii,1,EMP_y2		
		
		if (CheckIfFileExists(s_fname))
			if (CheckIfRawData(s_fname))
				// read the sample.label text field - OK
				S_Labels[ii]=getSampleLabel(s_fname)
			    
				//Transmission - OK as long as it has been patched in ???
				S_Transmission[ii]=getSampleTrans(s_fname)
			
				//Whole detector Transmission - Don't know where this will be in the file. Need help from epg ???
				S_Whole[ii]=getSampleTransWholeDetector(s_fname)
			
				//SDD - OK
				S_SDD[ii]=getSDD(s_fname)
			
				//wavelength - OK
				S_Lambda[ii]=getWavelength(s_fname)
			endif
		else
			S_Filenames[ii] = "? " + S_Filenames[ii]
			FilesAreMissing = 1
		endif
		
		if (CheckIfFileExists(t_fname))
			if (CheckIfRawData(t_fname))	
				// read the sample.label text field - OK
				T_Labels[ii]=getSampleLabel(t_fname)
			
				//Transmission - OK as long as it has been patched in ???
				//T_Transmission[ii]=getSampleTrans(t_fname)
			
				//Whole detector Transmission - Don't know where this will be in the file. Need help from epg ???
				//T_Whole[ii]=getSampleTransWholeDetector(t_fname)    
			
				//SDD - OK
				T_SDD[ii]=getSDD(t_fname)
			    
				//wavelength - OK
				T_Lambda[ii]=getWavelength(t_fname)
			endif
		else
			T_Filenames[ii] = "? " + T_Filenames[ii]
			FilesAreMissing = 1
		endif
		
		if (CheckIfFileExists(emp_fname))
			if (CheckIfRawData(emp_fname))
				getXYBoxFromFile(emp_fname,x1,x2,y1,y2)
				EMP_x1[ii] = x1
				EMP_x2[ii] = x2
				EMP_y1[ii] = y1
				EMP_y2[ii] = y2
			endif
		else
			EMP_Filenames[ii] = "? " + EMP_Filenames[ii]
			FilesAreMissing = 1
		endif
		
		ii+=1
		//Execute  "ProgressWindow percent=" + Num2Str(100*ii/lastPoint)
		
	while(ii<lastPoint)
	
	//Execute "ProgressWindow close"
	
	if (FilesAreMissing)
		DoAlert /T="Warning" 0, "The files marked with \"?\" in the table could not be found.\r\n\r\nSome files listed in the XML-Catalog may be missing."
	endif
	
	return(0)
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
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:T_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Lambda"
	//	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Transmission"
	//	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Make/O/T/N=0 $"root:myGlobals:TransHeaderInfo:S_Labels"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_SDD"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Lambda"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:EMP_x1"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:EMP_x2"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:EMP_y1"
	Make/O/D/N=0 $"root:myGlobals:TransHeaderInfo:EMP_y2"
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

	String S_Filename, T_Filename, EMP_Filename
	
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"

	Wave   S_Transmission = $"root:myGlobals:TransHeaderInfo:S_Transmission"
	
	Variable/G $"root:Packages:quokka:IgnoreTrans"
	NVAR IgnoreTrans = $"root:Packages:quokka:IgnoreTrans"
	
	Variable num_s_files, num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans
	Variable x1,x2,y1,y2,err,attenEmp,attenSam
	String suffix = "",pathName,textStr,abortStr,samFileStr
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
		
	num_t_files = numpnts(T_Filenames)
	
	PathInfo catPathName
	pathname = S_path

	// [davidm] restructured the following code
	for (ii = startRow; ii<=endRow; ii += 1)
	
		S_Filename		= pathname + S_Filenames[ii]
		T_Filename		= pathname + T_Filenames[ii]
		EMP_Filename	= pathname + EMP_Filenames[ii]
		
		// check S-file
		if ((cmpstr(S_Filenames[ii],"") == 0) || !CheckIfFileExists(S_Filename))
			Print "Scattering beam file not assigned properly in line", ii+1
			
		// check T-file
		elseif ((cmpstr(T_Filenames[ii],"") == 0) || !CheckIfFileExists(T_Filename))
			Print "Transmission beam file not assigned properly for", S_Filenames[ii]
			
		// check EMP-file
		elseif ((cmpstr(EMP_Filenames[ii],"") == 0) || !CheckIfFileExists(EMP_Filename))
			Print "Empty beam file not assigned properly for", S_Filenames[ii]

		// proceed
		else
			// check the empty beam file for previously selected coordinates
			//if they exist, set the xy string , save the normalized counts somewhere
			GetXYBoxFromFile(EMP_Filename,x1,x2,y1,y2)
						
			//read the real count value
			//emptyCts = getBoxCounts(emptyFile)
			//if(emptyCts < 1) //box counts hasn't been patched to file
			ReadHeaderAndData(EMP_Filename)
			IgnoreTrans = 1 // to prevent the warning message: ***transmission is ZERO***
			err = Raw_to_work("SAM")
			IgnoreTrans = 0
			emptyCts =  SumCountsInBox(x1,x2,y1,y2,"SAM")
			//nha debug
			//textStr = "Box counts for " +  emptyFile + "  " + num2str(emptyCts)
			//print textStr
			//endif

			// read the attenuator number of the empty beam file
			attenEmp = getAttenNumber(EMP_Filename)
			//
			if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
				//no region selected	-- prompt user to select box w/marquee
				DoWindow/F ScatterFileTable
				Abort "Use \"Set EMP File\", then \"SetXYBox\" to select XY range in empty beam file "+EMP_Filenames[ii]
				//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
			Endif
		
			//read in trans file 
			ReadHeaderAndData(T_Filename)
			//adds to SAM
			IgnoreTrans = 1 // to prevent the warning message: ***transmission is ZERO***
			err = Raw_to_work("SAM")
			IgnoreTrans = 0
			//sum region in SAM
			transCts =  SumCountsInBox(x1,x2,y1,y2,"SAM")	
			// get the attenuator, lambda, and sample string (to get the instrument)
			//				WAVE/T samText = $"root:Packages:NIST:SAM:textRead"
			WAVE samReals = $"root:Packages:NIST:SAM:realsRead"
			//				samfileStr = samText[3]
			lambda = samReals[26]
			attenSam = samReals[3]
			//nha debug
			//variable attenSamFromFile
			//attenSamFromFile = getAttenNumber(transFile)
			//textStr = num2str(attenSam) + "  "+ num2str(attenSamFromFile)
			//print textStr
			//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
			AttenRatio = AttenuationFactor("",lambda,attenEmp)/AttenuationFactor("",lambda,attenSam)
			//calculate trans based on empty beam value and rescale by attenuation ratio
			trans= transCts/emptyCts * AttenRatio
						
			//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
			If(attenRatio==1)
				Printf "%s\t\tTrans Counts = %g\tTrans = %g\r",S_Filenames[ii], transCts,trans
			else
				Printf "%s\t\tTrans Counts = %g\tTrans = %g\tAttenuatorRatio = %g\r",S_Filenames[ii], transCts,trans,attenRatio
			endif
			//write the trans to the file header of the raw data (open/close done in function)
			WriteTransmissionToHeader(S_Filename,trans)
	
			// after patching, the file needs to be removed from the DataFolder
			// so that it will be reloaded if it is needed again [davidm]
			string partialName = S_Filenames[ii]
			variable index = strsearch(partialName, ".", 0)
			if (index != -1)
				partialName = partialName[0,index-1]
			endif
			KillDataFolder/Z $"root:Packages:quokka:"+partialName
		
			//then update the global that is displayed
			S_Transmission[ii] = trans
		endif
	endfor
	
	print "done"
	return 0
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
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	//	Wave T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	//	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	//	Wave S_GTransmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	//	Wave GWhole= $"root:myGlobals:TransHeaderInfo:T_Whole"
	
	Variable num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans
	Variable x1,x2,y1,y2,err,attenEmp,attenSam
	String suffix = "",pathName,textStr,abortStr,emptyFile,transFile,samFileStr
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	String strToExecute
	
	//	num_t_files = numpnts(T_Filenames)
	
	PathInfo catPathName
	pathname = S_path

	ii= startRow
	do
		if (cmpstr(T_Filenames[ii],"")!=0)	//if there is a sample trans file assigned
			if (cmpstr(EMP_Filenames[ii],"")!=0)		//if empty beam file assigned, proceed with the calculation

				//full path+name to access all 3 files
				filename=pathname+S_Filenames[ii]
				emptyFile = pathname+ EMP_Filenames[ii]
				transFile = pathname+T_Filenames[ii]
				//////////
				// check the empty beam file for previously selected coordinates
				//if they exist, set the xy string , save the normalized counts somewhere
				//the value was written to an unused r*4 header analysis.factor (@b494)
				getXYBoxFromFile(emptyFile,x1,x2,y1,y2)
						
				//read the real count value
				emptyCts = getBoxCounts(emptyFile)
				// read the attenuator number of the empty beam file
				attenEmp = getAttenNumber(emptyFile)
				//
				if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
					//no region selected	-- prompt user to select box w/marquee
					DoWindow/F TransFileTable
					Abort "Use \"Set EMP File\", then \"SetXYBox\" to select XY range in empty beam file "+EMP_Filenames[ii]
					//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
				Endif
		
				//read in trans file then add to SAM
				ReadHeaderAndData(transFile)
				//adds to SAM
				err = Raw_to_work("SAM")
				//sum region in SAM
				transCts =  SumCountsInBox(x1,x2,y1,y2,"SAM")	
				// get the attenuator, lambda, and sample string (to get the instrument)
				WAVE/T samText = $"root:Packages:NIST:SAM:textRead"
				WAVE samReals = $"root:Packages:NIST:SAM:realsRead"
				samfileStr = samText[3]
				lambda = samReals[26]
				attenSam = samReals[3]
				//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
				AttenRatio = AttenuationFactor("",lambda,attenEmp)/AttenuationFactor("",lambda,attenSam)
				//calculate trans based on empty beam value and rescale by attenuation ratio
				trans= transCts/emptyCts * AttenRatio
						
				//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
				If(attenRatio==1)
					//Printf "%s\t\tTrans Counts = %g\t Actual Trans = %g\r",T_GFilenames[ii], transCts,trans
					Printf "%s\t\tBox Counts = %g\t Trans = %g\r",T_Filenames[ii], transCts,trans
				else
					//Printf "%s\t\tTrans Counts = %g\t Trans = %g\tAttenuatorRatio = %g\r",T_GFilenames[ii], transCts,trans,attenRatio
					Printf "%s\t\tBox Counts = %g\t Trans = %g\t AttenuatorRatio = %g\r",T_Filenames[ii], transCts,trans,attenRatio
				endif
				//write the trans to the file header of the raw data (open/close done in function)
				WriteTransmissionToHeader(filename,trans)		//transmission start byte is 158
				
				// after patching, the file needs to be removed from the DataFolder
				// so that it will be reloaded if it is needed again [davidm]
				string partialName = S_Filenames[ii]
				variable index = strsearch(partialName, ".", 0)
				if (index != -1)
					partialName = partialName[0,index-1]
				endif
				KillDataFolder/Z $"root:Packages:quokka:"+partialName
				
				//then update the global that is displayed
				//						T_GTransmission[ii] = trans
						
			else  // There is no empty assigned
				abortStr = "Empty beam file not assigned properly for " + S_Filenames[jj]
				Print abortStr
				//Abort abortStr
				return(1)
			endif
		else //no transmission file
			abortStr = "Transmission beam file not assigned properly for " + S_Filenames[ii]
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

	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	String filename
	Wave/T EMP_Filenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	
	Wave/T T_Filenames = $"root:myGlobals:TransHeaderInfo:T_Filenames"
	//	Wave T_GTransmission = $"root:myGlobals:TransHeaderInfo:T_Transmission"
	
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	//	Wave/T S_GFilenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave S_Transmission =  $"root:myGlobals:TransHeaderInfo:S_Transmission"
	Wave S_Whole= $"root:myGlobals:TransHeaderInfo:S_Whole"
	
	Variable num_t_files, ii, jj
	Variable refnum, transCts, emptyCts,attenRatio,lambda,trans
	Variable x1,x2,y1,y2,err,attenEmp,attenSam
	String suffix = "",pathName,textStr,abortStr,emptyFile,transFile,samFileStr
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	String strToExecute
	
	//	num_t_files = numpnts(T_GFilenames)
	
	PathInfo catPathName
	pathname = S_path

	ii= startRow
	do
		if (cmpstr(T_Filenames[ii],"")!=0)	//if there is a sample trans file assigned
			if (cmpstr(EMP_Filenames[ii],"")!=0)		//if empty beam file assigned, proceed with the calculation
				//full path+name to access all 3 files
				filename=pathname+ S_Filenames[ii]
				emptyFile = pathname+EMP_Filenames[ii]
				transFile = pathname+T_Filenames[ii]
				//////////
				// check the empty beam file for previously selected coordinates
				//if they exist, set the xy string , save the normalized counts somewhere
				//the value was written to an unused r*4 header analysis.factor (@b494)
						
				getXYBoxFromFile(emptyFile,x1,x2,y1,y2)
				//read the real count value
				emptyCts = getBoxCounts(emptyFile)
				// read the attenuator number of the empty beam file
				attenEmp = getAttenNumber(emptyFile)
				//
				if( ((x1-x2)==0) || ((y1-y2)==0) )		//zero width marquee in either direction
					//no region selected	-- prompt user to select box w/marquee
					DoWindow/F TransFileTable
					Abort "Use \"Set EMP File\", then \"SetXYBox\" to select XY range in empty beam file "+EMP_Filenames[ii]
					//from here the Marquee menu selection must handle the task of setting the box and updating the information in the file header
				Endif
		
				//read in trans file then add to SAM
				ReadHeaderAndData(transFile)
				//adds to SAM
				err = Raw_to_work("SAM")
				//sum region in SAM
				transCts =  SumCountsInBox(0,pixelsX-1,0,pixelsY-1,"SAM")	
				// get the attenuator, lambda, and sample string (to get the instrument)
				WAVE/T samText = $"root:Packages:NIST:SAM:textRead"
				WAVE samReals = $"root:Packages:NIST:SAM:realsRead"
				samfileStr = samText[3]
				lambda = samReals[26]
				attenSam = samReals[3]
				//calculate the ratio of attenuation factors - assumes that same instrument used for each, AND same lambda
				AttenRatio = AttenuationFactor("",lambda,attenEmp)/AttenuationFactor("",lambda,attenSam)
				//calculate trans based on empty beam value and rescale by attenuation ratio
				trans= transCts/emptyCts * AttenRatio
						
				//write out counts and transmission to history window, showing the attenuator ratio, if it is not unity
				If(attenRatio==1)
					//Printf "%s\t\tTrans Counts = %g\tTrans using whole detector = %g\t Tbox/Twhole = %g\r",T_GFilenames[ii], transCts,trans,T_GTransmission[ii]/trans
					Printf "%s\t\tTotal Counts = %g\t Trans using whole detector = %g\t",T_Filenames[ii], transCts,trans
				else
					//Printf "%s\t\tTrans Counts = %g\tTrans = %g\tAttenuatorRatio = %g, Tbox/Twhole = %g\r",T_GFilenames[ii], transCts,trans,attenRatio, T_GTransmission[ii]/trans
					Printf "%s\t\tTotal Counts = %g\t Trans using whole detector = %g\t AttenuatorRatio = %g",T_Filenames[ii], transCts,trans,attenRatio
				endif
				If(S_Transmission[ii]/trans > 0.97)
					printf " Tbox/Twhole = %g\r",S_Transmission[ii]/trans
				else
					printf " !!! Tbox/Twhole is low !!! = %g\r",S_Transmission[ii]/trans
				endif
				//write the trans to the file header of the raw data (open/close done in function)
				WriteWholeTransToHeader(filename,trans)
						
				//then update the global that is displayed
				S_Whole[ii] = trans
						
			else  // There is no empty assigned
				abortStr = "Empty beam file not assigned properly for " + S_Filenames[ii]
				Print abortStr
				//Abort abortStr
				return(1)
			endif
		
		else //no transmission file
			abortStr = "Transmission beam file not assigned properly for " + S_Filenames[ii]
			Print abortStr
		endif
		ii+=1
	while(ii<=endRow)
	print "done"
	return(0)
End

Function PickEMPTransButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable ScatFileTableExists
	ScatFileTableExists = WinType("ScatterFileTable")
	//??BUG?? V_flag returns 1 even if no selection?
	//check manually for null selection
	//Print "local v_flag = ",num2str(V_flag)
	Wave/T LocFilenames = $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	if (ScatFileTableExists != 0)
		String/G root:myGlobals:TransHeaderInfo:gEMP = ""
		GetSelection table,ScatterFileTable,7
		//Print S_Selection
		if(strsearch(S_selection,"EMP_Filenames",0) == 0)
			//selection OK, add to list
			Duplicate/O/R=[V_startRow,V_endRow] LocFilenames, filenames
			Wave/T selectedFiles = $"filenames"

			SVAR temp = root:myGlobals:TransHeaderInfo:gEMP
			//
			temp = temp+selectedFiles[0]		//take just the first file
			UpdateBoxCoordinates()
		Else
			DoWindow/F ScatterFileTable
			DoAlert 0,"Invalid selection from the Scattering file table. You must select a file from the EMP_Filenames column"
		Endif
	else
		//no selection
		DoAlert 0,"No file selected from Scattering file table or no Scattering file table available"
	Endif
End


//window recreation macro for the Trans Panel
//
Proc Trans_Panel() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(173,197,540,424)/K=1 as "Calculate Transmissions"
	DoWindow/C Trans_Panel
	ModifyPanel cbRGB=(49807,47186,38011)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 0,56,368,56
	DrawLine 0,125,368,125
	Button pick_emp,pos={4,65},size={105,20},proc=PickEMPTransButton,title="set EMP file"
	Button pick_emp,help={"This button will set the file selected in the Transmission file table to be the empty beam file."}
	SetVariable empStr,pos={114,67},size={250,17},title="file:"
	SetVariable empStr,help={"Filename of the empty beam file(s) to be used in the transmission calculation"}
	SetVariable empStr,fSize=10
	SetVariable empStr,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gEMP
	Button Trn_button_1,pos={5,101},size={90,20},proc=Trn_SetXYBoxButton,title="Set XY Box"
	Button Trn_button_1,help={"Sets the XY box to sum over"}
	Button Trn_button_2,pos={174,139},size={110,20},proc=Trn_SortFilesByDate,title="Sort by Date"
	Button Trn_button_2,help={"Sort the scattering and transmission files by creation date."}
	Button Trn_button_3,pos={174,169},size={110,20},proc=Trn_SortFilesByLabel,title="Sort by Label"
	Button Trn_button_3,help={"Sort the scattering and transmission files by label."}
	Button Trn_button_4,pos={295,139},size={67,20},proc=Trn_ShowHelpProc,title="Help"
	Button Trn_button_4,help={"Show a help notebook for calculating transmissions."}
	SetVariable Trn_setvar_1,pos={135,100},size={227,17},title="Box is "
	SetVariable Trn_setvar_1,help={"Box coordinates to sum over"},fSize=10
	SetVariable Trn_setvar_1,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gBox
	Button Trn_button_0,pos={1,1},size={70,20},proc=Trn_PickPathButton,title="Pick Path"
	Button Trn_button_0,help={"Select the folder containing the SANS data files"}
	Button Trn_button_9,pos={335,1},size={25,20},proc=ShowTransHelp,title="?"
	Button Trn_button_9,help={"Show the help file for calculating sample transmissions"}
	SetVariable Trn_setvar_0,pos={80,4},size={250,17},title="Path"
	SetVariable Trn_setvar_0,help={"Currently selected data path"},fSize=10
	SetVariable Trn_setvar_0,limits={-Inf,Inf,0},value= root:myGlobals:TransHeaderInfo:gCatPathStr
	Button Trn_button_5,pos={5,169},size={161,20},proc=Trn_CalcAllFilesButton,title="Calculate All Files"
	Button Trn_button_5,help={"Calculate transmission and patch headers of ALL files in the Scattering File Table."}
	Button Trn_button_6,pos={295,198},size={67,20},proc=Trn_PanelDoneButtonProc,title="Done"
	Button Trn_button_6,help={"Close the panel when done calculating transmissions"}
	
	Button Trn_button_7,pos={67,32},size={114,20},proc=Trn_RefreshProc,title="List Files"
	Button Trn_button_7,help={"Generate or refresh the tables of files."}
	
	Button Trn_button_7b, pos={67+114+5,32},size={114,20},proc=Trn_AutoCompleteProc,title="Auto Complete"
	Button Trn_button_7b, help={"???"}
	
	Button Trn_button_8,pos={5,139},size={161,20},proc=Trn_CalcSelectedFilesButton,title="Calculate Selected Files"
	Button Trn_button_8,help={"Calculate transmission and patch headers of selected files in the Scattering File Table."}
	Button Trn_button_10,pos={5,198}, size={161,20},proc=TotalTransButtonProc
	Button Trn_button_10 title="Calculate Total Trans"
	Button Trn_button_10 help={"Calculate transmission over the whole detector and patch headers of ALL files in the data folder."}
EndMacro


Function TotalTransButtonProc(ctrlName) : ButtonControl
	String ctrlName
	TotalTrans(ctrlName)
End


Proc ShowTransHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/K=1 "SANS Data Reduction Tutorial[Calculate Transmissions]"
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

Function Example2()
	String browserCmd,cmd1,cmd2,promptStr

	cmd1="Display %s"
	cmd2="AppendToGraph %s"
	promptStr="Select Waves for Graph"
	sprintf browserCmd, "CreateBrowser prompt=\"%s\", executeMode=2, command1=\"%s\", command2=\"%s\"",promptStr,cmd1,cmd2
	Execute browserCmd
End

//improves the file tables of scattering files and transmission files
Function Trn_AutoCompleteProc(ctrlName) : ButtonControl
	String ctrlName

	Variable i, in
	Variable j, jn
	Variable row
	
	Wave/T S_Filenames		= $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Wave/T T_Filenames		= $"root:myGlobals:TransHeaderInfo:T_Filenames"
	Wave/T EMP_Filenames	= $"root:myGlobals:TransHeaderInfo:EMP_Filenames"
	Wave/T S_Labels			= $"root:myGlobals:TransHeaderInfo:S_Labels"

	String Pathname, S_Filename, T_Filename, EMP_Filename, S_Label
	String safeLabel
	
	String dicValidRows		= "" // [safeLabel] -> [[row1],[row2],...]
	String dicCandidates		= "" // [safeLabel] -> [[row1],[row2],...]	// candidates to be auto completed
	
	String validRows		// [[row1],[row2],...]
	String candidateRows	// [[row1],[row2],...]
	
	String title, message, selection

//	String selection
//	Prompt selection, "titleStr", popup, "hallo\tTest;nein\tJa;danke"
//	DoPrompt "hello", selection

	PathInfo catPathName
	Pathname = S_path
	
	// check if ScatterFileTable exists
	if (WinType("ScatterFileTable") == 2)

		//
		// first step: find valid rows and find rows which potentially could be auto fixed
		//
		
		in = DimSize(S_Filenames, 0)
		for (i = 0; i < in; i += 1)
			S_Filename		= Pathname + S_Filenames[i]
			T_Filename		= Pathname + T_Filenames[i]
			EMP_Filename	= Pathname + EMP_Filenames[i]
			S_Label			= S_Labels[i]

			// check S-file
			if ((strlen(S_Filenames[i]) != 0) && CheckIfFileExists(S_Filename) && (strlen(S_Label) != 0))
			
				// make sure that label doesn't interfere with list and dictionary symbols
				safeLabel = S_Label
				safeLabel = ReplaceString("\\",	safeLabel, "\\1") // ReplaceString("\", safeLabel, "\1")
				safeLabel = ReplaceString(":",	safeLabel, "\\2")
				safeLabel = ReplaceString(";",	safeLabel, "\\3")
				
				// check T-file and EMP-file
				if ((strlen(T_Filenames[i]) != 0) && CheckIfFileExists(T_Filename) && (strlen(EMP_Filenames[i]) != 0) && CheckIfFileExists(EMP_Filename))
					// check if sample is already marked as valid row
					if (-1 != strsearch(dicValidRows, safeLabel, 0))
						// add row-index
						validRows = StringByKey(safeLabel, dicValidRows)
						sprintf validRows, "%s, %g", validRows, i
					else
						// set first row-index
						sprintf validRows, "%g", i
					endif
					dicValidRows = ReplaceStringByKey(safeLabel, dicValidRows, validRows)
					
				// S-file seemed fine but problems occurred with T- and EMP-file
				else
					// check if sample is already marked as possible candidate
					if (-1 != strsearch(dicCandidates, safeLabel, 0))
						// add row-index
						candidateRows = StringByKey(safeLabel, dicCandidates)
						sprintf candidateRows, "%s, %g", candidateRows, i
					else
						// set first row-index
						sprintf candidateRows, "%g", i
					endif
					dicCandidates = ReplaceStringByKey(safeLabel, dicCandidates, candidateRows)
				endif			
			endif
		endfor
		
		//
		// second step: fix invalid rows
		//
		
		jn = ItemsInList(dicCandidates)
		for (j = 0; j < jn; j += 1)
			safeLabel = StringFromList(0, StringFromList(j, dicCandidates), ":")

			// check if invalid rows of current sample can be fixed
			if (-1 != strsearch(dicValidRows, safeLabel, 0))
				validRows		= StringByKey(safeLabel, dicValidRows)
				candidateRows	= StringByKey(safeLabel, dicCandidates)
				
				// check if more than one row can be used to fix current candidates
				if (-1 != strsearch(validRows, ",", 0))
			
					sprintf message, "Select row you want to use to update all incomplete rows with that sample."
					
					// check if more than one row is afftected
					if (-1 != strsearch(candidateRows, ",", 0))
						sprintf title, "\"%s\" (Affected rows: %s)", S_Labels[str2num(StringFromList(0, validRows, ","))], candidateRows
					else
						sprintf title, " \"%s\" (Affected row: %s)", S_Labels[str2num(StringFromList(0, validRows, ","))], candidateRows
					endif
					
					selection = StringFromList(0, validRows, ",")
					Prompt selection, message, popup, ReplaceString(", ", validRows, ";")
					DoPrompt /HELP="" title, selection
				
					// evaluate result
					switch (V_flag)
						case 0: // yes
							row = str2num(selection)  // use selected row value
							break
							
						case 1: // cancel
							row = -1 // skip 
							break
				
						default:
							return 0
					endswitch
				else
					// only one row can be used to fix current candidates
					row = str2num(validRows)
					
					// check if more than one row is afftected
					if (-1 != strsearch(candidateRows, ",", 0))
						sprintf message, "The transmission value of \"%s\" can be determined with the information provided in row %g.\rWould you like to apply the information to all rows with that sample? (Affected rows: %s)", S_Labels[row], row, candidateRows
					else
						sprintf message, "The transmission value of \"%s\" can be determined with the information provided in row %g.\rWould you like to apply the information to all rows with that sample? (Affected row: %s)", S_Labels[row], row, candidateRows
					endif
					DoAlert 2, message
					
					// evaluate result
					switch (V_flag)
						case 1: // yes
							break // use selected row value
							
						case 2: // no
							row = -1 // skip 
							break
				
						default: // cancel
							return 0
					endswitch
				endif
				
				// fix current candidates if source row is specified
				if (row != -1)
					// these are the values to be used to fix current candidates
					T_Filename		= T_Filenames[row]
					EMP_Filename	= EMP_Filenames[row]
		
					// fix all invalid rows of current sample
					in = ItemsInList(candidateRows, ",")
					for (i = 0; i < in; i += 1)
						row = str2num(StringFromList(i, candidateRows, ","))
						T_Filenames[row]		= T_Filename
						EMP_Filenames[row]	= EMP_Filename
					endfor
				endif
			endif
			
			
						
//			// if dicValidRows contains row number for current sample, then transmission can be determined
//			row = NumberByKey(safeLabel, dicValidRows) // if item is not in dicValidRows then row is set to NaN 
//			if (numtype(row) == 0) // check for normal number
//				S_Label		= S_Labels[row]
//				if (-1 != strsearch(rowSelection, ",", 0)) // check if more than one row is afftected
//					sprintf message, "The transmission value of \"%s\" can be determined with the information provided in row %g.\rWould you like to apply the information to all rows with that sample? (Affected rows: %s)", S_Label, row, rowSelection
//				else
//					sprintf message, "The transmission value of \"%s\" can be determined with the information provided in row %g.\rWould you like to apply the information to all rows with that sample? (Affected row: %s)", S_Label, row, rowSelection
//				endif
//				DoAlert 2, message
//				
//				switch (V_flag)
//					case 1: // yes
//						T_Filename		= T_Filenames[row]
//						EMP_Filename	= EMP_Filenames[row]
//						// find sample and replace T- and EMP-Filename
//						for (i = 0; i < in; i += 1)
//							// check S-file
//							if ((strlen(S_Filenames[i]) != 0) && CheckIfFileExists(Pathname + S_Filenames[i]) && (cmpstr(S_Label, S_Labels[i]) == 0))
//								T_Filenames[i]		= T_Filename
//								EMP_Filenames[i]	= EMP_Filename
//							endif
//						endfor
//						break
//						
//					case 3: // cancel
//						return 0
//				endswitch
//				
//			// check if transmission of current sample could be determined
//			elseif (-1 != strsearch(listUnclearSamples, safeLabel, 0))
//				S_Label = safeLabel
//				S_Label = ReplaceString("\\3",	S_Label, ";")
//				S_Label = ReplaceString("\\2",	S_Label, ":")
//				S_Label = ReplaceString("\\1",	S_Label, "\\")
//				if (-1 != strsearch(rowSelection, ",", 0)) // check if more than one row is afftected
//					sprintf message, "The transmission value of \"%s\" can be determined with the information provided by multiple rows.\rPlease complete the report file manually for that sample. (Affected rows: %s)", S_Label, rowSelection
//				else
//					sprintf message, "The transmission value of \"%s\" can be determined with the information provided by multiple rows.\rPlease complete the report file manually for that sample. (Affected row: %s)", S_Label, rowSelection
//				endif
//				DoAlert 0, message
//				
//				
//				Example2()
//			endif
		endfor
	else
		DoAlert 0,"No file selected from Scattering Files table or no Scattering Files table available"
	endif
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
	SortGlobals(0)
End

//sorts the tables alphabetically by the sample label field
//
Proc Trn_SortFilesByLabel(ctrlName) : ButtonControl
	String ctrlName
	SortGlobals(1)
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
	String tempName = FindValidFilename(partialName)
	if(cmpstr(tempName,"")==0)
		//file not found, get out
		Abort "Empty beam file not found Trn_SetXYBoxButton(ctrlName)"
	Endif
	//name is ok, prepend path to tempName for read routine 
	PathInfo catPathName
	filename = S_path + tempName
	
	//read the file in - check for previous coordinates
	ReadHeaderAndData(filename)

	Wave realw=$"root:Packages:NIST:RAW:RealsRead"
	if (realw[26] == 0)
		DoAlert /T="Warning" 0, "Lambda for this file is zero! You might need to patch this file again before you continue to work with it."
	endif
		
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
		err = Raw_to_work("SAM")
	
		//the calling macro must change the display type
		String/G root:myGlobals:gDataDisplayType="SAM"		//displayed data type is sam
	
		//data is displayed here
		fRawWindowHook()
	
		//prompt user to select box w/marquee
		DoAlert 0,"(1) Select the region to sum with the Marquee.\n(2) Right click into the selected region.\n(3) Click on SetXYBoxCoords"
		// DoAlert 0,"Select the region to sum with the Marquee"
			
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
			err = Raw_to_work("SAM")
	
			//the calling macro must change the display type
			String/G root:myGlobals:gDataDisplayType="SAM"		//displayed data type is sam
	
			//data is displayed here
			fRawWindowHook()
	
			//prompt user to select box w/marquee
			DoAlert 0,"(1) Select the region to sum with the Marquee.\n(2) Right click into the selected region.\n(3) Click on SetXYBoxCoords"
			// DoAlert 0,"Select the region to sum with the Marquee"
	
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
	Wave/T S_Filenames = $"root:myGlobals:TransHeaderInfo:S_Filenames"
	Variable num_s_files = numpnts(S_Filenames)
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
			//AssignSelTransFilesToData(V_StartRow,V_EndRow)
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
 
	Variable scatTableExists
	scatTableExists = WinType("ScatterFileTable")
	if (scatTableExists != 0)
		GetSelection table,ScatterFileTable,1
		if(V_Flag != 0)
			//AssignTotalTransFilesToData(V_StartRow,V_EndRow)
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
	String tempName = FindValidFilename(item)
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
	
	fullname = FindFileFromRunNumber(num)
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
	
	fullname = FindFileFromRunNumber(num)
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


/////
//  A quick way to fill all the T_EMP_Filenames with the selected empty beam file
// Note that you must go back and clear or reassign any files that are special cases
//
// IMPORTANT - this will overwrite any other file assignments (typically not a problem
// if you  are using only one wavelength)
//
/////
Function FillEMPFilenameWSelection()

	GetSelection table,TransFileTable,3
	Variable row=V_startRow			//ony need the selected row, we know the column names and location
	Wave/T fw = root:myGlobals:TransHeaderInfo:T_FileNames		//trans files
	Wave/T ew = root:myGlobals:TransHeaderInfo:T_EMP_FileNames		//empty beam reference files
	
	ew[] = fw[row]
	
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
// (2) the wavelength must be the same
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
	
	Variable num,ii,found
	String transStr = "",testStr=""
	
	transStr = (tw[row])[0,charsToUse-1]		//string to try and match
	transStr += "*"
	
	//loop over ALL sample files
	num=numpnts(sw)
	ii=0
	do
		testStr=sw[ii]
		found = stringmatch(testStr, transStr )
		if( (found == 1) && (sLam[ii] == tLam[row]) )		// both must match
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
	
	Wave/T sw = root:myGlobals:TransHeaderInfo:S_Labels		//Sample file labels
	Wave/T tw = root:myGlobals:TransHeaderInfo:T_Labels		//trans file labels
	Wave/T tnam = root:myGlobals:TransHeaderInfo:T_FileNames	//trans file names
	Wave/T snam = root:myGlobals:TransHeaderInfo:S_TRANS_FileNames	//Scattering - trans correspondence
	Wave/T samfile = root:myGlobals:TransHeaderInfo:S_FileNames	//Scattering file name
	
	// can do fancy formatted string with ...
	//"asdf* matches file: \\f01filen\\f00 \\K(52428,1,1)\\f01afdsfdd\\f00\\K(0,0,0)asdfasdfs"
	Variable num=numpnts(matchRows)
	String result="",tmpStr
	for(ii=0;ii<num;ii+=1)
		sprintf tmpStr,"\\f01\\K(52428,1,1)%s\\K(0,0,0)\\f00* Matches file: \\f01%s\\f00 | \\K(52428,1,1)\\f01%s\\f00\\K(0,0,0)%s\r",(tw[row])[0,numChars-1],samfile[matchRows[ii]],(sw[matchRows[ii]])[0,numchars-1],(sw[matchRows[ii]])[numchars,59]
		result += tmpStr
	endfor
	
	if(cmpstr(result,"")==0)
		result = "No match found for "+ (tw[row])[0,numChars-1]
	endif
	
	//	Print result
	Print "*******"
	
	String/G root:myGlobals:TransHeaderInfo:gResultStr = result
	
	DoWindow/F ConfirmGuess		//it really shouldn't exist...
	if(V_flag==1)
		TitleBox title0,pos={9,5},variable=root:myGlobals:TransHeaderInfo:gResultStr
	else
		NewPanel /W=(578,44,1263,214) as "Confirm Guess"
		DoWindow/C ConfirmGuess
		TitleBox title0,pos={9,5},size={501,32}
		TitleBox title0,variable= root:myGlobals:TransHeaderInfo:gResultStr
		Button button0,pos={9,107},size={190,20},proc=DoAssignTransButtonProc,title="Assign Transmission Files"
		Button button2,pos={341,108},size={90,20},proc=DoTryAgainButtonProc,title="Try Again"
		ToolsGrid snap=1,visible=1
	endif
	
	PauseForUser ConfirmGuess

	// figure out from the return code what the user did...
	// 1 = OK, accept guess (assign, and calculate immediately)
	// 2 = try again
	// 0 = cancel, don't do anything (not used, simply try again)
	NVAR guessOK = root:myGlobals:TransHeaderInfo:GuessOK
	
	// switch here...
	switch(guessOK)	// numeric switch
		case 1:		
			// accept guess (assign, and calculate immediately)
			for(ii=0;ii<num;ii+=1)
				snam[matchRows[ii]] = tnam[row]
				//AssignSelTransFilesToData(matchRows[ii],matchRows[ii])
				CalcSelTransFromHeader(matchRows[ii],matchRows[ii])		//does only that sample file
			endfor			
			break						
		case 2:	//try again (with more / fewer characters?)	
			//		does nothing right now
			break
		case 0:
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
Function DoTryAgainButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable/G root:myGlobals:TransHeaderInfo:GuessOK= 2
			DoWindow/K ConfirmGuess
			//Print "Try Again"
			break
	endswitch
	
	return 0
End

// not used
Function DoCancelGuessButtonProc(ba) : ButtonControl
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

Function ClearSelectedAssignments()
	
	//	String winStr = WinList("*", ";", "WIN:" )		//returns the target window
	//	Variable scatterTableExists, transTableExists
	//	Print winStr
	//   	scatterTableExists = cmpstr(winStr,"ScatterFileTable;")
	//   	if (scatterTableExists == 0)
	//		GetSelection table,ScatterFileTable,1	
	//		fClearSelectedAssignments(V_startRow,V_endRow,1)
	//	endif
	//	
	//	transTableExists = cmpstr(winStr,"TransFileTable;")
	//   	if (transTableExists == 0)
	//		GetSelection table,TransFileTable,1	
	//		fClearSelectedAssignments(V_startRow,V_endRow,2)
	//	endif
	
	//	return(0)
End
