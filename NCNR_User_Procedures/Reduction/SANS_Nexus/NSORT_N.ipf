#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//****************************
// Vers. 1.2 092101
//
// NSORT panel for combining and inter-normalizing 2 or 3 datasets
// that have previously been averaged
//
// MAR 2016 SRK added functionality to combine 4 datasets
//
// - handles 3 or 6-column datasets
// allows manual scaling
// allows user to interactively delete data points from either end of any datset
//
//*********************

//main entry point for displaying the nsort panel
//initializes folder/globals as needed
//
Proc ShowNSORTPanel()
	DoWindow/F NSORT_Panel
	if(V_flag==0)
		InitNSORTPanel()
		NSORT_Panel()
	Endif
	SetDataFolder root:
	PathInfo/S catPathName
	String junk = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:myGlobals:NSORT:gPathStr = "no folder selected"
	else
		String/G root:myGlobals:NSORT:gPathStr = junk
	endif
	LowQPopMenuProc("",1,"")
	MedQPopMenuProc("",1,"")
	HighQPopMenuProc("",1,"")
	HighestQPopMenuProc("",1,"")
End

//initializes globals/folder for the NSORT panel as needed
//all of the globals are stored in root:myGlobals:NSORT folder
//the globals are the values displayed in the panel
//
Proc InitNSORTPanel()

	//set up the global variables needed for the NSORT panel
	NewDataFolder/O root:myGlobals:NSORT
	Variable/G root:myGlobals:NSORT:gScale1_2 = 1
	Variable/G root:myGlobals:NSORT:gScale2_3 = 1
	Variable/G root:myGlobals:NSORT:gScale3_4 = 1
	//
	//save the number of points to trim from beginning/end of the data files
	//
	Variable/G root:myGlobals:NSORT:gPtsBeg1 = NumVarOrDefault("root:myGlobals:NSORT:gPtsBeg1", 0 )
	Variable/G root:myGlobals:NSORT:gPtsEnd1 = NumVarOrDefault("root:myGlobals:NSORT:gPtsEnd1", 0 )
	Variable/G root:myGlobals:NSORT:gPtsBeg2 = NumVarOrDefault("root:myGlobals:NSORT:gPtsBeg2", 0 )
	Variable/G root:myGlobals:NSORT:gPtsEnd2 = NumVarOrDefault("root:myGlobals:NSORT:gPtsEnd2", 0 )
	Variable/G root:myGlobals:NSORT:gPtsBeg3 = NumVarOrDefault("root:myGlobals:NSORT:gPtsBeg3", 0 )
	Variable/G root:myGlobals:NSORT:gPtsEnd3 = NumVarOrDefault("root:myGlobals:NSORT:gPtsEnd3", 0 )
	Variable/G root:myGlobals:NSORT:gPtsBeg4 = NumVarOrDefault("root:myGlobals:NSORT:gPtsBeg4", 0 )
	Variable/G root:myGlobals:NSORT:gPtsEnd4 = NumVarOrDefault("root:myGlobals:NSORT:gPtsEnd4", 0 )
	
	Variable/G root:myGlobals:NSORT:gColumns1 = 0
	Variable/G root:myGlobals:NSORT:gColumns2 = 0
	Variable/G root:myGlobals:NSORT:gColumns3 = 0
	Variable/G root:myGlobals:NSORT:gColumns4 = 0
	Variable/G root:myGlobals:NSORT:gNormToNum = 1
	String/G root:myGlobals:NSORT:gPathStr = ""
	String/G root:myGlobals:NSORT:gDataPopList = "none"
	String/G root:myGlobals:NSORT:gDataPopList_3 = "none"
	
	SetDataFolder root:		//(redundant)
End

//New loader that uses data folders etc...
//AJJ Jan 2010
Function LoadDataForNSORT(fileStr,setNum)
	String fileStr		//full path:name to a valid file
	Variable setNum	//number of set (used for naming) = 0, 1, or 2 (ONLY), (2016) 3 is now valid for 4th data set
	
	Variable err=0

	String nm0,nm1,nm2
	//String firstFileName = S_fileName
	Variable pt=0,begPts,endPts,numCols
	
	NVAR gColumns1 = root:myGlobals:NSORT:gColumns1
	NVAR gColumns2 = root:myGlobals:NSORT:gColumns2
	NVAR gColumns3 = root:myGlobals:NSORT:gColumns3
	NVAR gColumns4 = root:myGlobals:NSORT:gColumns4
	NVAR begPts1 = root:myGlobals:NSORT:gPtsBeg1
	NVAR endPts1 = root:myGlobals:NSORT:gPtsEnd1
	NVAR begPts2 = root:myGlobals:NSORT:gPtsBeg2
	NVAR endPts2 = root:myGlobals:NSORT:gPtsEnd2
	NVAR begPts3 = root:myGlobals:NSORT:gPtsBeg3
	NVAR endPts3 = root:myGlobals:NSORT:gPtsEnd3
	NVAR begPts4 = root:myGlobals:NSORT:gPtsBeg4
	NVAR endPts4 = root:myGlobals:NSORT:gPtsEnd4
	
	String cmd
	String typStr= "", trimStr=""
	
	switch (setNum)
		case 1:
			sprintf cmd , "A_LoadOneDDataToName(\"%s\",\"%s\",%d,%d)",fileStr,"LowQSet",0,1
			Execute cmd
			typStr = "LowQSet"
			trimStr = "TrimLowQSet"
			begPts = begPts1
			endPts = endPts1
			break
		case 2:
			sprintf cmd , "A_LoadOneDDataToName(\"%s\",\"%s\",%d,%d)",fileStr,"MedQSet",0,1
			Execute cmd		
			typStr = "MedQSet"
			trimStr = "TrimMedQSet"
			begPts = begPts2
			endPts = endPts2
			break
		case 3:
			sprintf cmd , "A_LoadOneDDataToName(\"%s\",\"%s\",%d,%d)",fileStr,"HighQSet",0,1
			Execute cmd
			typStr = "HighQSet"
			trimStr = "TrimHighQSet"
			begPts = begPts3
			endPts = endPts3
			break
		case 4:
			sprintf cmd , "A_LoadOneDDataToName(\"%s\",\"%s\",%d,%d)",fileStr,"HighestQSet",0,1
			Execute cmd
			typStr = "HighestQSet"
			trimStr = "TrimHighestQSet"
			begPts = begPts4
			endPts = endPts4
			break
	endswitch
		
	String typPrefix = "root:"+typStr+":"+typStr
	String trimPrefix = "root:"+typStr+":"+trimStr
	
	if (WaveExists($(typPrefix+"_res")))
		//6 col data loaded
//		print "6 col data loaded"
		numCols = 6
		Duplicate/O $(typPrefix+"_q") $(trimPrefix+"_q")
		Duplicate/O $(typPrefix+"_i") $(trimPrefix+"_i")
		Duplicate/O $(typPrefix+"_s") $(trimPrefix+"_s")
		Duplicate/O $(typPrefix+"_res") $(trimPrefix+"_res")
		//Trimmed data set
//		Duplicate/O $(typPrefix+"_q"),$(trimPrefix+"_q")
//		Duplicate/O $(typPrefix+"_i"),$(trimPrefix+"_i")
//		Duplicate/O $(typPrefix+"_s"),$(trimPrefix+"_s")
		WaveStats/Q $(typPrefix+"_q")			//get info about the original q-values read in
		pt = V_npnts-endPts
		DeletePoints pt,endPts,$(trimPrefix+"_q"),$(trimPrefix+"_i"),$(trimPrefix+"_s"),$(trimPrefix+"_res")	//delete end points first
		DeletePoints 0,begPts,$(trimPrefix+"_q"),$(trimPrefix+"_i"),$(trimPrefix+"_s"),$(trimPrefix+"_res")	//then delete points from beginning			
	else
		//Assume
		//3 col data loaded
//		print "Assuming 3 col data loaded"
		numcols = 3
		Duplicate/O $(typPrefix+"_q") $(trimPrefix+"_q")
		Duplicate/O $(typPrefix+"_i") $(trimPrefix+"_i")
		Duplicate/O $(typPrefix+"_s") $(trimPrefix+"_s")		
		//Trimmed data set
//		Duplicate/O $(typPrefix+"_q"),$(trimPrefix+"_q")
//		Duplicate/O $(typPrefix+"_i"),$(trimPrefix+"_i")
//		Duplicate/O $(typPrefix+"_s"),$(trimPrefix+"_s")
		WaveStats/Q $(typPrefix+"_q")			//get info about the original q-values read in
		pt = V_npnts-endPts
		DeletePoints pt,endPts,$(trimPrefix+"_q"),$(trimPrefix+"_i"),$(trimPrefix+"_s")	//delete end points first
		DeletePoints 0,begPts,$(trimPrefix+"_q"),$(trimPrefix+"_i"),$(trimPrefix+"_s")	//then delete points from beginning							
	endif

	switch (setNum)
		case 1:
			gColumns1 = numCols
			break
		case 2:
			gColumns2 = numCols
			break
		case 3:
			gColumns3 = numCols
			break
		case 4:
			gColumns4 = numCols
			break
	endswitch
	
	return(0)
	
End

Function WriteNSORTedFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,[res])
	Wave q3,i3,sig3,res
	String firstFileName,secondFileName,thirdFileName,fourthfileName,normTo
	Variable norm12,norm23,norm34

	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	NVAR useNXcanSASOutput = root:Packages:NIST:gNXcanSAS_Write

	if (useXMLOutput == 1)
		if(WaveExists(res))
			WriteNSORTedXMLFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,res=res)
		else
			WriteNSORTedXMLFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
		endif
	elseif (useNXcanSASOutput == 1)
		if(WaveExists(res))
			WriteNSORTedNXcanSASFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,res=res)
		else
			WriteNSORTedNXcanSASFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
		endif
	else
		if(WaveExists(res))
			WriteOLDNSORTedFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,res=res)
		else
			WriteOLDNSORTedFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
		endif		
	endif

End


Function WriteOLDNSORTedFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,[res])
	Wave q3,i3,sig3,res
	String firstFileName,secondFileName,thirdFileName,fourthFileName,normTo
	Variable norm12,norm23,norm34

	Variable err=0,refNum,numCols,dialog=1
	String fullPath="",formatStr="",str2
	//check each wave - else REALLY FATAL error when writing file
	If(!(WaveExists(q3)))
		err = 1
		return err
	Endif
	If(!(WaveExists(i3)))
		err = 1
		return err
	Endif
	If(!(WaveExists(sig3)))
		err = 1
		return err
	Endif
	
	if(WaveExists(res))
		numCols = 6
	else
		numCols = 3
	endif
	
// 05SEP05 SRK -- added to automatically combine files from a table - see the end of NSORT.ipf for details
// - use the flag set in DoCombineFiles() to decide if the table entries should be used
//Ê Êroot:myGlobals:CombineTable:useTable= (1) (0)
//if(exists("root:myGlobals:CombineTable:SaveName"))
	NVAR/Z useTable = root:myGlobals:CombineTable:useTable
	if(NVAR_Exists(useTable) && useTable==1)
		SVAR str=root:myGlobals:CombineTable:SaveNameStr	//messy, but pass in as a global
		fullPath = str
//		str2 = "Is the file name "+str+" correct?"
//		DoAlert 1,str2
//		if(V_flag==1)
			dialog=0		//bypass the dialog if the name is good (assumed, since DoAlert is bypassed)
//		endif
	endif
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as",fname="",suffix=".ABS")		//won't actually open the file
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
//	// read in the header information from each of the combined files and put this information in the file header
//	String dum,hdr1="none\r\n",hdr2="none\r\n",hdr3="none\r\n"
//	PathInfo catPathName
//	
//	// the first file exists, check anyways
//	if(cmpstr(firstFileName,"none") !=0)
//		Open/R refNum as S_Path+firstFileName
//		FReadLine refNum, dum
//		FReadLine refNum, hdr1 			//just grab the second line
//		Close refNum
//	endif
//	//second file
//	if(cmpstr(secondFileName,"none") !=0)
//		Open/R refNum as S_Path+secondFileName
//		FReadLine refNum, dum
//		FReadLine refNum, hdr2 			//just grab the second line
//		Close refNum
//	endif
//	// third file
//	if(cmpstr(thirdFileName,"none") !=0)
//		Open/R refNum as S_Path+thirdFileName
//		FReadLine refNum, dum
//		FReadLine refNum, hdr3 			//just grab the second line
//		Close refNum
//	endif

	
	//actually open the file
	Open refNum as fullpath
	
	fprintf refnum, "COMBINED FILE CREATED: %s \r\n",date()
	
//	fprintf refnum, "FIRST File %s",hdr1		//new, Mar 2008
//	fprintf refnum, "SECOND File %s",hdr2		//new, Mar 2008
//	fprintf refnum, "THIRD File %s",hdr3		//new, Mar 2008
	
	fprintf refNum, "NSORT-ed   %s\t  +  %s\t  +  %s\t + %s\r\n",firstFileName, secondFileName,thirdFileName,fourthFileName
	fprintf refNum, "normalized to   %s\r\n",normTo
	fprintf refNum, "multiplicative factor 1-2 = %12.8g\t multiplicative factor 2-3 = %12.8g\t multiplicative factor 3-4 = %12.8g\r\n",norm12,norm23,norm34

	if (numCols == 3)
		formatStr = "%15.4g %15.4g %15.4g\r\n"
		fprintf refnum, "The 3 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) |\r\n"
		wfprintf refnum, formatStr, q3,i3,sig3
	elseif (numCols == 6)
		Make/O/N=(dimsize(res,0)) sigq3 = res[p][0]
		Make/O/N=(dimsize(res,0)) qbar3 = res[p][1]
		Make/O/N=(dimsize(res,0)) fs3 = res[p][2]
	
		formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"	
		fprintf refnum, "The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"
		wfprintf refnum, formatStr, q3,i3,sig3,sigq3,qbar3,fs3
	endif
	
	Close refnum
	
	Return err
End


//gets the scaling constant to make (best) overlap of the specified datasets
//the scaling value is an average value of the individual scaling values for 
//every data point (at the low q end) of set 2 that overlaps with set 1
//(as if set 1 were held fixed)
//num2 is the highest point number in set 2 that can overlap with set 1
//(num2+1) individual scaling values are computed
//wave2 must be multiplied by norm to rescale to wave1
//the scale factor is the return value
//
Function NCNR_GetScalingInOverlap(num2,wave1q,wave1i,wave2q,wave2i)
	Variable num2		//largest point number of wave2 in overlap region
	Wave wave1q,wave1i,wave2q,wave2i		//1 = first dataset, 2= second dataset

	Variable ii,ival1,newi,ratio
	ratio=0
	ii=0
	do
		//get scaling factor at each point of wave 2 in the overlap region
		newi = interp(wave2q[ii],wave1q,wave1i)		//get the intensity of wave1 at an overlap point
		ratio += newi/wave2i[ii]					//get the scale factor
		//Print "ratio = ",ratio
		ii+=1
	while(ii<=num2)
	Variable val
	val = ratio/(num2+1)		// +1 counts for point zero
	//Print "val = ",val

	Variable tol=1.05			//5% is the preferred number (for Andrew and Lionel, at least)

	ControlInfo/W=NSORT_Panel WarningCheck
	if(( V_Value==1 ) && ( (val > tol) || (val < 1/tol) ) )
		String str=""
		sprintf str,"The scaling factor is more than a factor of %g from 1. Proceed with caution.\r",tol
		DoAlert 0,str
	endif
	
	Return val
End

Function ShowNSORTHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Sort and Combine Averaged Datasets]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//button action procedure that simply closes the NSORT panel when done
//and removes the NSORT-specific waves that were created
// - the graph window must be killed first, so that the waves will not
//be in use
//
Function NSORT_DoneButton(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K NSORT_Panel
	
	DoWindow/K NSORT_Graph
	
	//clean up the temporary waves in the root: folder
	SetDataFolder root:

	KillDataFolder/Z LowQSet
	KillDataFolder/Z MedQSet
	KillDataFolder/Z HighQSet
	KillDataFolder/Z HighestQSet

End

//button action procedure that plots dataset specified 
//on an NSORT graph window. 
//switch is on input controlName (low-med-high set)
//parses partial filename from corresponding popup menu
//builds a valid filename, loads the data (re-loads if already on graph)
//and plots twice - once for the full datset (open symbols)
//and once for the "trimmed" dataset (solid symbols, same color)
//
Function Plot_0_Button(ctrlName) : ButtonControl
	String ctrlName

	String tempName="",partialName=""
	Variable setNum,err
	//switch on ctrlName string - Plot_1, Plot_2, Plot_3
	
	strswitch(ctrlName)	// string switch
		case "Plot_1":		
			//low-q
			setNum = 1
			ControlInfo/W=NSORT_Panel popup_1
			break
		case "Plot_2":		
			//medium-q
			setNum = 2
			ControlInfo/W=NSORT_Panel popup_2
			break
		case "Plot_3":		
			//high-q
			setNum = 3
			ControlInfo/W=NSORT_Panel popup_3
			break
		case "Plot_4":		
			//highest-q
			setNum = 4
			ControlInfo/W=NSORT_Panel popup_4
			break
	endswitch
	

	//find the file from the partial filename
	If( (cmpstr(S_value,"")==0) || (cmpstr(S_value,"none")==0) )
		//null selection, or "none" from any popup
		Abort "no file selected in popup menu"
	else
		//selection not null
		partialName = S_value
		//Print partialName
	Endif
	//get a valid file based on this partialName and catPathName
	tempName = FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//load in the data (into the root directory)
	err = LoadDataForNSORT(tempName,setNum)
	
	//bring the plot to the front, and put the new data on it
	//and put cursors on the plotted dataset
	//if the dataset is already on the graph, it will have been overwritten and updated by the load routine
	//actually plot it twice, open(opaque) circles for the full dataset, 
	// then solid (filled) circles for the points actually kept
	String list="",searchStr=""
	Variable isOnPlot=0
	
//	DoWindow/F NSORT_Graph
	if(WinType("NSORT_Graph")==0)
		//no window, create one
		strswitch(ctrlName)	// string switch
			case "Plot_1":		
				//low-q
				Display/K=1
				DoWindow/C NSORT_Graph
				DisplayLowSet()
				break
			case "Plot_2":		
				//medium-q
				Display/K=1
				DoWindow/C NSORT_Graph
				DisplayMedSet()
				break
			case "Plot_3":		
				//high-q
				Display/K=1
				DoWindow/C NSORT_Graph
				DisplayHighSet()
				break
			case "Plot_4":		
				//highest-q
				Display/K=1
				DoWindow/C NSORT_Graph
				DisplayHighestSet()
				break
		endswitch
		Legend
	else
		//plot already exists, waves have been updated
		//make sure that the desired waves are actually on the graph, and add them if they aren't
		list = TraceNameList("NSORT_Graph",";",1)
	
		strswitch(ctrlName)	// string switch
			case "Plot_1":		
				//low-q
				isOnPlot = strsearch(list, "LowQSet_i", 0)		// isOnPlot == -1 if it is NOT found in the list
				if(isOnPlot == -1)
					DisplayLowSet()
				Endif
				break
			case "Plot_2":		
				//medium-q
				isOnPlot = strsearch(list, "MedQSet_i", 0)		// isOnPlot == -1 if it is NOT found in the list
				if(isOnPlot == -1)
					DisplayMedSet()
				Endif
				break
			case "Plot_3":		
				//high-q
				isOnPlot = strsearch(list, "HighQSet_i", 0)		// isOnPlot == -1 if it is NOT found in the list
				if(isOnPlot == -1)
					DisplayHighSet()
				Endif
				break
			case "Plot_4":		
				//highest-q
				isOnPlot = strsearch(list, "HighestQSet_i", 0)		// isOnPlot == -1 if it is NOT found in the list
				if(isOnPlot == -1)
					DisplayHighestSet()
				Endif
				break
		endswitch	
	
	Endif
	
	
	//the stripPoints variable boxes should also update the graph, if necessary
	return(0)
End

//adds both highest-q sets (full and trimmed) to the graph, which is 
//assumed to exist along with the high-q waves
//
Function DisplayHighestSet()
	//function assumes that the window "NSORT_Graph" already exists
//	DoWindow/F NSORT_Graph

	SetDataFolder root:HighestQSet:
	AppendToGraph/W=NSORT_Graph $"HighestQSet_i" vs $"HighestQSet_q"
	ModifyGraph/W=NSORT_Graph log=1,mode=3,marker($"HighestQSet_i")=8,msize=2,rgb($"HighestQSet_i")=(65535,32896,0),opaque($"HighestQSet_i")=1
	ErrorBars/W=NSORT_Graph/T=0 $"HighestQSet_i" Y,wave=($"HighestQSet_s",$"HighestQSet_s")
	AppendToGraph/W=NSORT_Graph $"TrimHighestQSet_i" vs $"TrimHighestQSet_q"
	ModifyGraph/W=NSORT_Graph mode($"TrimHighestQSet_i")=3,marker($"TrimHighestQSet_i")=19,msize=2,rgb($"TrimHighestQSet_i")=(65535,32896,0)
	SetDataFolder root:
End

//adds both high-q sets (full and trimmed) to the graph, which is 
//assumed to exist along with the high-q waves
//
Function DisplayHighSet()
	//function assumes that the window "NSORT_Graph" already exists
//	DoWindow/F NSORT_Graph

	SetDataFolder root:HighQSet:
	AppendToGraph/W=NSORT_Graph $"HighQSet_i" vs $"HighQSet_q"
	ModifyGraph/W=NSORT_Graph log=1,mode=3,marker($"HighQSet_i")=8,msize=2,rgb($"HighQSet_i")=(0,0,65535),opaque($"HighQSet_i")=1
	ErrorBars/W=NSORT_Graph/T=0 $"HighQSet_i" Y,wave=($"HighQSet_s",$"HighQSet_s")
	AppendToGraph/W=NSORT_Graph $"TrimHighQSet_i" vs $"TrimHighQSet_q"
	ModifyGraph/W=NSORT_Graph mode($"TrimHighQSet_i")=3,marker($"TrimHighQSet_i")=19,msize=2,rgb($"TrimHighQSet_i")=(0,0,65535)
	SetDataFolder root:
End

//adds both med-q sets (full and trimmed) to the graph, which is 
//assumed to exist along with the med-q waves
//
Function DisplayMedSet()
	//function assumes that the window "NSORT_Graph" already exists
//	DoWindow/F NSORT_Graph
	
	SetDataFolder root:MedQSet:
	AppendToGraph/W=NSORT_Graph $"MedQSet_i" vs $"MedQSet_q"
	ModifyGraph/W=NSORT_Graph log=1,mode=3,marker($"MedQSet_i")=8,msize=2,rgb($"MedQSet_i")=(65535,0,0),opaque($"MedQSet_i")=1
	ErrorBars/W=NSORT_Graph/T=0 $"MedQSet_i" Y,wave=($"MedQSet_s",$"MedQSet_s")
	AppendToGraph/W=NSORT_Graph $"TrimMedQSet_i" vs $"TrimMedQSet_q"
	ModifyGraph/W=NSORT_Graph mode($"TrimMedQSet_i")=3,marker($"TrimMedQSet_i")=19,msize=2,rgb($"TrimMedQSet_i")=(65535,0,0)
	SetDataFolder root:
End

//adds both low-q sets (full and trimmed) to the graph, which is 
//assumed to exist along with the low-q waves
//
Function DisplayLowSet()
	//function assumes that the window "NSORT_Graph" already exists
//	DoWindow/F NSORT_Graph

	SetDataFolder root:LowQSet:
	AppendToGraph/W=NSORT_Graph $"LowQSet_i" vs $"LowQSet_q"
	ModifyGraph/W=NSORT_Graph log=1,mode=3,marker($"LowQSet_i")=8,msize=2,rgb($"LowQSet_i")=(2,39321,1),opaque($"LowQSet_i")=1
	ErrorBars/W=NSORT_Graph/T=0 $"LowQSet_i" Y,wave=($"LowQSet_s",$"LowQSet_s")
	AppendToGraph/W=NSORT_Graph $"TrimLowQSet_i" vs $"TrimLowQSet_q"
	ModifyGraph/W=NSORT_Graph mode($"TrimLowQSet_i")=3,marker($"TrimLowQSet_i")=19,msize=2,rgb($"TrimLowQSet_i")=(2,39321,1)
	ModifyGraph tickUnit(left)=1
	SetDataFolder root:
End

//button action procedure to set both the main global of the catPath string
//and also the duplicate global string used in the NSORT folder
//after path selected, the popup menus are updated
//
Function NSORTPickPathButton(ctrlName) : ButtonControl
	String ctrlName

	Variable err = PickPath()		//sets global path value
	SVAR pathStr = root:myGlobals:gCatPathStr
	
	//set the global string for NSORT to the selected pathname
	String/G root:myGlobals:NSORT:gPathStr = pathStr
	
	//call each of the popup menu proc's to re-set the menu choices
	//setting the checkboxes to force update
//	CheckBox check_0,win=NSORT_Panel,value=1
//	CheckBox check_1,win=NSORT_Panel,value=1
//	CheckBox check_2,win=NSORT_Panel,value=1
	LowQPopMenuProc("popup_1",1,"")
	MedQPopMenuProc("popup_2",1,"")
	HighQPopMenuProc("popup_3",1,"")
	HighestQPopMenuProc("popup_4",1,"")
	
End


//action procedure associated with the setvar box
//when a value is entered, the global value is set, and the corresponding dataset
//is updated on the plot, showing the new result of removing this number of points
//
//	SetVar boxes are named beg_N and end_N (so 4th element is the number)
//
// 1 == LowQ
// 2 == MedQ
// 3 == HighQ
// 4 == HighestQ
//
//"Plot_1" is the low-q button name
//"Plot_2" is the med-q button name
//"Plot_3" is the high-q button name
//"Plot_4" is the high-q button name
//
//calling plot_0_Button() responds as if that named button were pressed
// and gets the proper number to trim directly from the SetVar
//
Function SetBegOrEnd(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
//  global is automatically updated as the value is entered
	String numStr= num2Str( str2num(ctrlName[4]) )
	Plot_0_Button("Plot_"+numStr)
	DoWindow/F NSORT_Panel
End

//this will---
//re-load the data sets (since they may not have been loaded if they were not plotted)
// apply the scaling to the datasets (so that they will show up in the graph)
//and actually write the file
//
// then "pop" the  lists to get the new file lists with the new name in the list
//
Function WriteNSORTFileButton(ctrlName) : ButtonControl
	String ctrlName
		
	// Put here the dialog that says if ANY of the datasets had 3-column data, the results will all have only three columns
	// Set the number of output columns
	Variable isAThree = 0, isASix = 0,err
	String fileStr="",tempName

	NVAR Columns1 = root:myGlobals:NSORT:gColumns1
	NVAR Columns2 = root:myGlobals:NSORT:gColumns2
	NVAR Columns3 = root:myGlobals:NSORT:gColumns3
	NVAR Columns4 = root:myGlobals:NSORT:gColumns4
	if( (Columns1 == 3) || (Columns2 == 3) || (Columns3 == 3) || (Columns4 == 3)) 
		isAThree = 1
	endif
	if( (Columns1 == 6) || (Columns2 == 6) || (Columns3 == 6) || (Columns4 == 6)) 
		isASix = 1
	endif
	if( (isAThree == 1) && (isASix == 1))
		DoAlert 0, "These files contained a mixture of 3-column and 6-column data.  Only 3 columns were output."
	endif
	
	//is there just one data set? if so, then dispatch to a simpler routine, since no normalization is needed
	ControlInfo/W=NSORT_Panel popup_2		//if MedQSet is "none", then so is HighQSet and HighestQSet
	fileStr = S_Value
	if(cmpstr(fileStr,"none") == 0)
		// just like in the rescaling routines, always RELOAD the data  !!!
		//load file1
		ControlInfo/W=NSORT_Panel popup_1
		fileStr = S_Value
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(fileStr)
		
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
		err = LoadDataForNSORT(tempName,1)
		//////end load file1
	
		//send just the trimmed (LowQ) set to be written out
		WAVE lowq = $"root:LowQSet:TrimLowQSet_q"
		WAVE lowi = $"root:LowQSet:TrimLowQSet_i"
		WAVE lows = $"root:LowQSet:TrimLowQSet_s"
//		WAVE/Z lowsq = $"root:LowQSet:TrimLowQSet_sq"		//these may not exist
//		WAVE/Z lowqb = $"root:LowQSet:TrimLowQSet_qb"
//		WAVE/Z lowfs = $"root:LowQSet:TrimLowQSet_fs"
		WAVE/Z lowres = $"root:LowQSet:TrimLowQSet_res"
		NVAR scaleFactor= root:myGlobals:NSORT:gScale1_2
		
		//
		lowi *= scaleFactor
		lows *= scaleFactor
		
		ControlInfo/W=NSORT_Panel PreviewCheck
		if( V_Value==1 )		//if ==1, just preview and exit
			return(0)
		endif
			
		ControlInfo/W=NSORT_Panel popup_1
		if(isAThree)
			WriteNSORTedFile(lowq,lowi,lows,S_Value,"none","none","none",S_Value,scaleFactor,1,1)
		else
			WriteNSORTedFile(lowq,lowi,lows,S_Value,"none","none","none",S_Value,scaleFactor,1,1,res=lowres)
		endif
		//  just get the new list and return - don't actually "pop" the menu, or the selected item will change
		SVAR popList = root:myGlobals:NSORT:gDataPopList
		SVAR popList_3 = root:myGlobals:NSORT:gDataPopList_3
		popList  = ReducedDataFileList("")
		popList_3 = "none;" +  ReducedDataFileList("")
		return(0)
	endif
		
		
	//two or more datasets, combine them
	//have they been manually or auto-normalized?
	ControlInfo/W=NSORT_Panel AutoCheck
	Variable checked = V_Value
	
	//do the normalization and update the global scale factors displayed in the Panel
	err = DoAutoScaleFromPanel(checked)			// DoAutoScaleFromPanel writes out the datafile

	//  just get the new list - don't actually "pop" the menu, or the selected item will change
	SVAR popList = root:myGlobals:NSORT:gDataPopList
	SVAR popList_3 = root:myGlobals:NSORT:gDataPopList_3
	popList  = ReducedDataFileList("")
	popList_3 = "none;" +  ReducedDataFileList("")
	
	return(0)
End

//window recreation macro for NSORT Panel
//
Window NSORT_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(569,69,944,584)//K=2
	ModifyPanel cbRGB=(49151,53155,65535)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 5
	DrawText 35,20,"NSORT - Rescale and combine 1-D files"
	DrawLine 0,55,346,55
	DrawLine 0,128,346,128
	DrawLine 0,214,346,214
	DrawLine 0,295,346,295
	DrawLine 0,372,347,372
	DrawLine 0,460,346,460
	
	SetDrawEnv fstyle= 5
	DrawText 5,74,"Low Q:"
	SetDrawEnv fstyle= 5
	DrawText 5,148,"Medium Q:"
	SetDrawEnv fstyle= 5
	DrawText 8,234,"High Q: (or none)"
	SetDrawEnv fstyle= 5
	DrawText 8,314,"Highest Q: (or none)"
	SetDrawEnv fstyle= 4
	DrawText 178,75,"Delete Points?"
	SetDrawEnv fstyle= 4
	DrawText 178,146,"Delete Points?"
	SetDrawEnv fstyle= 4
	DrawText 184,236,"Delete Points?"
	SetDrawEnv fstyle= 4
	DrawText 184,316,"Delete Points?"
	DrawText 31,456,"To Manually scale data, enter scale factors above"
	
	Button NSORT_Done,pos={274,483},size={50,20},proc=NSORT_DoneButton,title="Done"
	Button NSORT_Done,help={"closes the panel"}
	Button Plot_1,pos={279,63},size={50,20},proc=Plot_0_Button,title="Plot"
	Button Plot_1,help={"Plots the dataset from the popup, showing the full set as open circles and the trimmed set as solid circles"}
	Button Plot_2,pos={283,144},size={50,20},proc=Plot_0_Button,title="Plot"
	Button Plot_2,help={"Plots the dataset from the popup, showing the full set as open circles and the trimmed set as solid circles"}
	Button Plot_3,pos={284,223},size={50,20},proc=Plot_0_Button,title="Plot"
	Button Plot_3,help={"Plots the dataset from the popup, showing the full set as open circles and the trimmed set as solid circles"}
	Button Plot_4,pos={284.00,303.00},size={50.00,20.00},proc=Plot_0_Button,title="Plot"
	Button Plot_4,help={"Plots the dataset from the popup, showing the full set as open circles and the trimmed set as solid circles"}

	Button PathButton,pos={6,26},size={80,20},proc=NSORTPickPathButton,title="Pick Path"
	Button PathButton,help={"Select the local path to the folder containing your SANS data"}
	Button helpButton,pos={340,26},size={25,20},proc=ShowNSORTHelp,title="?"
	Button helpButton,help={"Show the help file for sorting and internormalizing 1-D data sets"}
	SetVariable setPath,pos={95,29},size={240,14},title="Path:",fSize=10
	SetVariable setPath,limits={0,0,0},value= root:myGlobals:NSORT:gPathStr
	SetVariable setPath,help={"The current path to the local folder with SANS data"}
	SetVariable end_1,pos={182,101},size={80,14},proc=SetBegOrEnd,title="End Pts"
	SetVariable end_1,fSize=10,help={"How many points to remove from the high-q end of this dataset"}
	SetVariable end_1,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsEnd1
	SetVariable end_2,pos={182,176},size={80,14},proc=SetBegOrEnd,title="End Pts"
	SetVariable end_2,fSize=10,help={"How many points to remove from the high-q end of this dataset"}
	SetVariable end_2,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsEnd2
	SetVariable end_3,pos={182,269},size={80,14},proc=SetBegOrEnd,title="End Pts"
	SetVariable end_3,fSize=10,help={"How many points to remove from the high-q end of this dataset"}
	SetVariable end_3,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsEnd3
	SetVariable end_4,pos={182.00,349.00},size={80.00,16.00},proc=SetBegOrEnd,title="End Pts"
	SetVariable end_4,help={"How many points to remove from the high-q end of this dataset"}
	SetVariable end_4,fSize=10
	SetVariable end_4,limits={-inf,inf,0},value= root:myGlobals:NSORT:gPtsEnd4
	SetVariable beg_1,pos={182,79},size={80,14},proc=SetBegOrEnd,title="Beg Pts"
	SetVariable beg_1,fSize=10,help={"How many points to remove from the low-q end of this dataset"}
	SetVariable beg_1,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsBeg1
	SetVariable beg_2,pos={182,155},size={80,14},proc=SetBegOrEnd,title="Beg Pts"
	SetVariable beg_2,fSize=10,help={"How many points to remove from the low-q end of this dataset"}
	SetVariable beg_2,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsBeg2
	SetVariable beg_3,pos={182,246},size={80,14},proc=SetBegOrEnd,title="Beg Pts"
	SetVariable beg_3,fSize=10,help={"How many points to remove from the low-q end of this dataset"}
	SetVariable beg_3,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gPtsBeg3
	SetVariable beg_4,pos={182.00,326.00},size={80.00,16.00},proc=SetBegOrEnd,title="Beg Pts"
	SetVariable beg_4,help={"How many points to remove from the low-q end of this dataset"}
	SetVariable beg_4,fSize=10
	SetVariable beg_4,limits={-inf,inf,0},value= root:myGlobals:NSORT:gPtsBeg4
	Button DoCombine,pos={13,483},size={160,20},proc=WriteNSORTFileButton,title="Write Combined File"
	Button DoCombine,help={"Combine and normalize the selected files as specifed"}
	SetVariable scale_12,pos={159,381},size={160,14},proc=SetScale_12,title="Mult factor 1-2"
	SetVariable scale_12,fSize=10,help={"Factor that will multiply medium-q set to scale to low-q set"}
	SetVariable scale_12,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gScale1_2
	SetVariable scale_23,pos={159,401},size={160,14},proc=SetScale_23,title="Mult factor 2-3"
	SetVariable scale_23,fSize=10,help={"Factor that will multiply high-q set to scale to medium-q set"}
	SetVariable scale_23,limits={-Inf,Inf,0},value= root:myGlobals:NSORT:gScale2_3
	SetVariable scale_34,pos={159.00,421.00},size={160.00,16.00},proc=SetScale_34,title="Mult factor 3-4"
	SetVariable scale_34,help={"Factor that will multiply highest-q set to scale to high-q set"}
	SetVariable scale_34,fSize=10
	SetVariable scale_34,limits={-inf,inf,0},value= root:myGlobals:NSORT:gScale3_4
	CheckBox check1,pos={5,105},size={160,20},proc=CheckProc,title="Normalize to this file",value=1
	CheckBox check1,help={"If checked, the combined dataset will be normalized to this dataset"}
	CheckBox check2,pos={5,185},size={160,20},proc=CheckProc,title="Normalize to this file",value=0
	CheckBox check2,help={"If checked, the combined dataset will be normalized to this dataset"}
	CheckBox check3,pos={4,270},size={160,20},proc=CheckProc,title="Normalize to this file",value=0
	CheckBox check3,help={"If checked, the combined dataset will be normalized to this dataset"}
	CheckBox check4,pos={4.00,350.00},size={107.00,16.00},proc=CheckProc,title="Normalize to this file"
	CheckBox check4,help={"If checked, the combined dataset will be normalized to this dataset"}
	CheckBox check4,value= 0
	PopupMenu popup_1,pos={6,77},size={99,19},proc=LowQPopMenuProc
	PopupMenu popup_1,mode=1,value= #"root:myGlobals:NSORT:gDataPopList"
	PopupMenu popup_1,help={"Choose the dataset with the lowest overall q-value (longest detector distance)"}
	PopupMenu popup_2,pos={6,153},size={99,19},proc=MedQPopMenuProc
	PopupMenu popup_2,mode=1,value= #"root:myGlobals:NSORT:gDataPopList_3"
	PopupMenu popup_2,help={"Choose the dataset with the intermediate q-values (\"medium\" detector distance)"}
	PopupMenu popup_3,pos={6,239},size={99,19},proc=HighQPopMenuProc
	PopupMenu popup_3,mode=1,value= #"root:myGlobals:NSORT:gDataPopList_3"
	PopupMenu popup_3,help={"Choose the dataset with the highest overall q-value (shortest detector distance), or NONE if no third set desired"}
	PopupMenu popup_4,pos={6.00,319.00},size={58.00,23.00},proc=HighestQPopMenuProc
	PopupMenu popup_4,help={"Choose the dataset with the highest overall q-value (shortest detector distance), or NONE if no fourth set desired"}
	PopupMenu popup_4,mode=1,popvalue="none",value= #"root:myGlobals:NSORT:gDataPopList_3"
	CheckBox AutoCheck,pos={14,386},size={100,20},title="Auto Scale",value=0
	CheckBox AutoCheck,help={"If checked, the scale factor will be automatically determined, if not checked, the current values in the fields will be used"}
	CheckBox PreviewCheck,pos={15,465},size={74,14},title="Preview Only",value= 0
	CheckBox WarningCheck,pos={111,465},size={93,14},title="Overlap warning?",value= 1
EndMacro

//sets the scale factor (multiplicative) between sets 1 and 2
//re-sets the global variable
//
Function SetScale_12(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Variable/G root:myGlobals:NSORT:gScale1_2 = varNum
	
End

//sets the scale factor (multiplicative) between sets 2 and 3
//re-sets the global variable
//
Function SetScale_23(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Variable/G root:myGlobals:NSORT:gScale2_3 = varNum
End

//sets the scale factor (multiplicative) between sets 3 and 4
//re-sets the global variable
//
Function SetScale_34(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Variable/G root:myGlobals:NSORT:gScale3_4 = varNum
End

//control procedures for the checkboxes to specify which file is to be
//held fixed (so all other files are normalized to the checked file
//the three checkboxes behave as "radio buttons" - only one can be checked
//
Function CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	//controls the three checkboxes to act as "radio buttons" to have only one file to 
	//normalize to.
	//all three boxes should call this routine
	
	//do the "radio button control"
	do
		if(cmpstr(ctrlName,"check2") == 0)
			CheckBox check1 value=0
			CheckBox check2 value=1
			CheckBox check3 value=0
			CheckBox check4 value=0
			Variable/G root:myGlobals:NSORT:gNormToNum = 2
			break
		Endif
		if(cmpstr(ctrlName,"check3") == 0)
			CheckBox check1 value=0
			CheckBox check2 value=0
			CheckBox check3 value=1
			CheckBox check4 value=0
			Variable/G root:myGlobals:NSORT:gNormToNum = 3
			break
		Endif
		if(cmpstr(ctrlName,"check4") == 0)
			CheckBox check1 value=0
			CheckBox check2 value=0
			CheckBox check3 value=0
			CheckBox check4 value=1
			Variable/G root:myGlobals:NSORT:gNormToNum = 4
			break
		Endif
		//default case is normalize to file1
		CheckBox check1 value=1
		CheckBox check2 value=0
		CheckBox check3 value=0
			CheckBox check4 value=0
		Variable/G root:myGlobals:NSORT:gNormToNum = 1
	While(0)
	
	ControlUpdate/A/W=NSORT_Panel
	DoUpdate
		
End

//when menu is popped, it gets a valid list to display and updates the control
//
// 2002- always refreshes, as new (fast) filter is used
Function LowQPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	String/G root:myGlobals:NSORT:gDataPopList = ReducedDataFileList("")
	ControlUpdate popup_1

	return(0)
End

//when menu is popped, it gets a valid list to display and updates the control
//
Function MedQPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
		
	String/G root:myGlobals:NSORT:gDataPopList_3 = "none;" +  ReducedDataFileList("")
	ControlUpdate popup_2
	if(cmpstr(popStr,"none")==0)
		PopupMenu popup_3,mode=1	//force "none" (item #1) to be the selection
		CheckBox AutoCheck,value=0	//un-check the auto-scale checkbox
		DoAlert 0,"You have only one data set. Auto Scaling has been unchecked and Mult Factor 1-2 will be applied to your data. Remember to re-check this as needed"// remind the user of this fact
		RemoveFromGraph/Z MedQSet_i,TrimMedQSet_i,HighQSet_i,TrimHighQSet_i		//remove the data from the graph
	Endif	
	return(0)
End

//when menu is popped, it gets a valid list to display and updates the control
// - will be different, since set 3 can also be "none" if only 2 sets
//are to be NSORTed
//
Function HighQPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	//add the option "none" to the file list (which should already end with a semicolon)
	String/G root:myGlobals:NSORT:gDataPopList_3 = "none;" +  ReducedDataFileList("")

	ControlUpdate/W=NSORT_Panel popup_3
	if(cmpstr(popStr,"none")==0)
		RemoveFromGraph/Z HighQSet_i,TrimHighQSet_i		//remove the data from the graph
	Endif	
	ControlInfo/W=NSORT_Panel popup_2
	if(cmpstr(S_Value,"none")==0)
		PopupMenu popup_3,win=NSORT_Panel,mode=1	//force "none" (item #1) to be the selection if medium is none
	endif
	return(0)	
End


//when menu is popped, it gets a valid list to display and updates the control
// - will be different, since set 3 can also be "none" if only 2 sets
//are to be NSORTed
//
Function HighestQPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	//add the option "none" to the file list (which should already end with a semicolon)
	String/G root:myGlobals:NSORT:gDataPopList_3 = "none;" +  ReducedDataFileList("")

	ControlUpdate/W=NSORT_Panel popup_4
	if(cmpstr(popStr,"none")==0)
		RemoveFromGraph/Z HighestQSet_i,TrimHighestQSet_i		//remove the data from the graph
	Endif	
	ControlInfo/W=NSORT_Panel popup_2
	if(cmpstr(S_Value,"none")==0)
		PopupMenu popup_3,win=NSORT_Panel,mode=1	//force "none" (item #1) to be the selection if medium is none
		PopupMenu popup_4,win=NSORT_Panel,mode=1	//force "none" (item #1) to be the selection if medium is none
	endif
	ControlInfo/W=NSORT_Panel popup_3
	if(cmpstr(S_Value,"none")==0)
		PopupMenu popup_4,win=NSORT_Panel,mode=1	//force "none" (item #1) to be the selection if medium is none
	endif
	return(0)	
End

//be sure to use the "Trim.." datasets that have had the bad points removed
//and then do the scaling based on the choices in the panel
//input (auto) is a switch 
//
Function DoAutoScaleFromPanel(auto)
	Variable auto		//if auto == 1, do the scaling, if 0, use manual scale values

	NVAR normTo = root:myGlobals:NSORT:gNormToNum
	Variable err=0,setNum,norm12,norm23,norm34
	String fileStr="",tempName="",name1="",name2="",name3="",normToStr="",name4=""
	
//Set the number of output columns
	Variable numOutputColumns = 0

	NVAR Columns1 = root:myGlobals:NSORT:gColumns1
	NVAR Columns2 = root:myGlobals:NSORT:gColumns2
	NVAR Columns3 = root:myGlobals:NSORT:gColumns3
	NVAR Columns4 = root:myGlobals:NSORT:gColumns4
	if( (Columns1 == 3) || (Columns2 == 3) || (Columns3 == 3) || (Columns4 == 3) ) 
		numOutputColumns = 3
	else
		if( (Columns1 == 6) && (Columns2 == 6) && ((Columns3 == 0) || (Columns3 == 6)) || (Columns4 == 6) ) 
			numOutputColumns = 6
		endif
  	endif

	//rescale 1-2
	
	//load file1
	ControlInfo/W=NSORT_Panel popup_1
	fileStr = S_Value
	name1 = fileStr
	setNum = 1
	//get a valid file based on this partialName and catPathName
	tempName = FindValidFilename(fileStr)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	err = LoadDataForNSORT(tempName,setNum)
	//////end load file1
	
	//load file2
	ControlInfo/W=NSORT_Panel popup_2
	fileStr = S_Value
	name2 = fileStr
	setNum = 2
	//get a valid file based on this partialName and catPathName
	tempName = FindValidFilename(fileStr)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	err = LoadDataForNSORT(tempName,setNum)
	//////end load file2
	
	//load file3 , if necessary
	ControlInfo/W=NSORT_Panel popup_3
	fileStr = S_Value
	name3 = fileStr
	setNum = 3
	if(cmpstr(fileStr,"none") == 0)
		//do nothing
	else
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(fileStr)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
		err = LoadDataForNSORT(tempName,setNum)
	Endif
	//////end load file3
	
	//load file4 , if necessary
	ControlInfo/W=NSORT_Panel popup_4
	fileStr = S_Value
	name4 = fileStr
	setNum = 4
	if(cmpstr(fileStr,"none") == 0)
		//do nothing
	else
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(fileStr)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
		err = LoadDataForNSORT(tempName,setNum)
	Endif
	//////end load file4
	
	
	//assign filename of file to normalize to
	switch(normTo)
		case 1:
			normToStr = name1
			break
		case 2:
			normToStr = name2
			break
		case 3:
			normToStr = name3
			break
		case 4:
			normToStr = name4
			break
	endswitch


	Variable n1,n2,n12,num2
	Variable n3,n123
	Variable n4,n1234
	
   if(numOutputColumns == 3) //Start the 3-column specific stuff here.
		//order points in sets 1-2, indexing overlap region
		//put result in temporary waves
		WaveStats/Q $"root:LowQSet:TrimLowQSet_q"
		n1 = V_npnts
		WaveStats/Q $"root:MedQSet:TrimMedQSet_q"
		n2 = V_npnts
		n12 = n1+ n2
		
		Make/O/N=(n12) q12,i12,sig12
		WAVE lowq = $"root:LowQSet:TrimLowQSet_q"
		WAVE medq = $"root:MedQSet:TrimMedQSet_q"
		WAVE lowi = $"root:LowQSet:TrimLowQSet_i"
		WAVE medi =  $"root:MedQSet:TrimMedQSet_i"
		WAVE lows = $"root:LowQSet:TrimLowQSet_s"
		WAVE meds = $"root:MedQSet:TrimMedQSet_s"
		q12[0,n1-1] = lowq[p]
		q12[n1,n1+n2-1]= medq[p-n1]
		i12[0,n1-1] = lowi[p]
		i12[n1,n1+n2-1]= medi[p-n1]
		sig12[0,n1-1] = lows[p]
		sig12[n1,n1+n2-1]= meds[p-n1]
		
		Sort q12, q12,i12,sig12
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q medq,(lowq[n1-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm12 = NCNR_GetScalingInOverlap(num2,lowq,lowi,medq,medi)
			//Set the global variable for the 1-2 scale factor
			Variable/G root:myGlobals:NSORT:gScale1_2 = norm12
		else
			//use the value from the panel ( which is the global)
			NVAR temp12 = root:myGlobals:NSORT:gScale1_2
			norm12 = temp12
		Endif
		
		If(normTo== 2)
			//normalize to second file, so multiply 1st by 1/norm
			norm12 = 1/norm12
			lowi *= norm12
			lows *= norm12
		else
			//normalize to first file, OR THIRD FILE so multiply 2nd by norm
			medi *= norm12
			meds *= norm12
		Endif
		
		//Print "NSORT-ed ",name1," + ", name2
		//Print "normalized to ",normTo
		//Print "multiplicative factor = ",norm12
		
		
		//Make the combined, scaled dataset by overwriting the old sets
		Make/O/N=(n12) q12,i12,sig12
		q12[0,n1-1] = lowq[p]
		q12[n1,n1+n2-1]= medq[p-n1]
		i12[0,n1-1] = lowi[p]
		i12[n1,n1+n2-1]= medi[p-n1]
		sig12[0,n1-1] = lows[p]
		sig12[n1,n1+n2-1]= meds[p-n1]
		
		Sort q12, q12,i12,sig12
		//at this point 1-2 are combined
		
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate
		
		//do we need to continue, or write out the set here and stop?
		if(cmpstr(name3,"none") == 0)
			//stop here
			norm23 = 1		//norm23 was not used
			Variable/G root:myGlobals:NSORT:gScale2_3 = 1
			//If any of them have three columns write three column data
			
			ControlInfo/W=NSORT_Panel PreviewCheck
			if( V_Value==0 )		//if zero skip the preview and write out the file
				err=WriteNSORTedFile(q12,i12,sig12,name1,name2,name3,name4,normToStr,norm12,norm23,norm34)
			endif
			//cleanup waves before exiting
			KillWaves/Z q12,i12,sig12
			return err
		Endif
		
		//need to add the third file... which was already loaded at the top of the function
		/////
		//order points in sets 12-3, indexing overlap region
		//put result in temporary waves
		WaveStats/Q q12
		n12 = V_npnts
		WaveStats/Q $"root:HighQSet:TrimHighQSet_q"
		n3 = V_npnts
		n123 = n12+ n3
		
		Make/O/N=(n123) q123,i123,sig123
		WAVE highq = $"root:HighQSet:TrimHighQSet_q"
		WAVE highi = $"root:HighQSet:TrimHighQSet_i"
		WAVE highs = $"root:HighQSet:TrimHighQSet_s"
	
		q123[0,n12-1] = q12[p]
		q123[n1,n12+n3-1]= highq[p-n12]
		i123[0,n12-1] = i12[p]
		i123[n1,n12+n3-1]= highi[p-n12]
		sig123[0,n12-1] = sig12[p]
		sig123[n1,n12+n3-1]= highs[p-n12]
		
		Sort q123, q123,i123,sig123
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q highq,(q12[n12-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm23 = NCNR_GetScalingInOverlap(num2,q12,i12,highq,highi)
			//Set the global variable for the 12 - 3 scale factor
			Variable/G root:myGlobals:NSORT:gScale2_3 = norm23
		else
			//use the value from the panel ( which is the global)
			NVAR temp23 = root:myGlobals:NSORT:gScale2_3
			norm23 = temp23
		Endif
		
		If( (normTo== 1) || (normTo ==2) )
			//normalize to first or second file, so multiply third by norm23
			highi *= norm23
			highs *= norm23
		else
			//normalize to THIRD file, 1-2 by 1/norm23
			norm23 = 1/norm23
			i12 *= norm23
			sig12 *= norm23
			// for the display, scale the trimmed sets 1 and 2
			lowi *= norm23
			lows *= norm23
			medi *= norm23
			meds *= norm23
		Endif
		
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate

		//Print "NSORT-ed ",name1," + ", name2, " + ", name3
		//Print "normalized to ",normTo
		//Print "multiplicative factor 1-2 = ",norm12," multiplicative factor 12 - 3 = ",norm23
		
		
		Make/O/N=(n123) q123,i123,sig123
		q123[0,n12-1] = q12[p]
		q123[n12,n12+n3-1]= highq[p-n12]
		i123[0,n12-1] = i12[p]
		i123[n12,n12+n3-1]= highi[p-n12]
		sig123[0,n12-1] = sig12[p]
		sig123[n12,n12+n3-1]= highs[p-n12]
		
		Sort q123, q123,i123,sig123
		//at this point 12 - 3 are combined
		//write out the set here and stop
	
		ControlInfo/W=NSORT_Panel PreviewCheck
		if( V_Value==0 )		//if zero skip the preview and write out the file
			err=WriteNSORTedFile(q123,i123,sig123,name1,name2,name3,name4,normToStr,norm12,norm23,norm34)
		endif
		//cleanup waves before exiting
		KillWaves/Z q12,i12,sig12,q123,i123,sig123
		
		
		//do we need to continue, or write out the set here and stop?
		if(cmpstr(name4,"none") == 0)
			//stop here
			norm34 = 1		//norm34 was not used
			Variable/G root:myGlobals:NSORT:gScale3_4 = 1
			//If any of them have three columns write three column data
			
			ControlInfo/W=NSORT_Panel PreviewCheck
			if( V_Value==0 )		//if zero skip the preview and write out the file
				err=WriteNSORTedFile(q123,i123,sig123,name1,name2,name3,name4,normToStr,norm12,norm23,norm34)
			endif
			//cleanup waves before exiting
			KillWaves/Z q123,i123,sig123
			return err
		Endif
		
		//need to add the fourth file... which was already loaded at the top of the function
		/////
		//order points in sets 123-4, indexing overlap region
		//put result in temporary waves
		WaveStats/Q q123
		n123 = V_npnts
		WaveStats/Q $"root:HighestQSet:TrimHighestQSet_q"
		n4 = V_npnts
		n1234 = n123 + n4
		
		Make/O/N=(n1234) q1234,i1234,sig1234
		WAVE highestq = $"root:HighestQSet:TrimHighestQSet_q"
		WAVE highesti = $"root:HighestQSet:TrimHighestQSet_i"
		WAVE highests = $"root:HighestQSet:TrimHighestQSet_s"
	
		q1234[0,n123-1] = q123[p]
		q1234[n12,n123+n4-1]= highestq[p-n123]
		i1234[0,n123-1] = i123[p]
		i1234[n12,n123+n4-1]= highesti[p-n123]
		sig1234[0,n123-1] = sig123[p]
		sig1234[n12,n123+n4-1]= highests[p-n123]
		
		Sort q1234, q1234,i1234,sig1234
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q highestq,(q123[n123-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm34 = NCNR_GetScalingInOverlap(num2,q123,i123,highestq,highesti)
			//Set the global variable for the 123 - 4 scale factor
			Variable/G root:myGlobals:NSORT:gScale3_4 = norm34
		else
			//use the value from the panel ( which is the global)
			NVAR temp34 = root:myGlobals:NSORT:gScale3_4
			norm34 = temp34
		Endif
		
// normalization
		switch (normTo)
			case 1:
			case 2:
			case 3:
				//normalize to first or second or third file, so multiply fourth by norm34
				highesti *= norm34
				highests *= norm34
				break
			case 4:
				//normalize to FOURTH file, 123 by multiplicative factor 1/norm34
				norm34 = 1/norm34
				i123 *= norm34
				sig123 *= norm34
				// for the display, scale the trimmed sets 1 and 2 and 3
				lowi *= norm34
				lows *= norm34
				medi *= norm34
				meds *= norm34
				highi *= norm34
				highs *= norm34
				break
		endswitch
				
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate

		//Print "NSORT-ed ",name1," + ", name2, " + ", name3
		//Print "normalized to ",normTo
		//Print "multiplicative factor 1-2 = ",norm12," multiplicative factor 12 - 3 = ",norm23
		
		
		Make/O/N=(n1234) q1234,i1234,sig1234
		q1234[0,n123-1] = q123[p]
		q1234[n123,n123+n4-1]= highestq[p-n123]
		i1234[0,n123-1] = i123[p]
		i1234[n123,n123+n4-1]= highesti[p-n123]
		sig1234[0,n123-1] = sig123[p]
		sig1234[n123,n123+n4-1]= highests[p-n123]
		
		Sort q123, q123,i123,sig123
		//at this point 12 - 3 are combined
		//write out the set here and stop
	
		ControlInfo/W=NSORT_Panel PreviewCheck
		if( V_Value==0 )		//if zero skip the preview and write out the file
			err=WriteNSORTedFile(q123,i123,sig123,name1,name2,name3,name4,normToStr,norm12,norm23,norm34)
		endif
		//cleanup waves before exiting
		KillWaves/Z q12,i12,sig12,q123,i123,sig123
		
		
		
		
		//combined dataset will already be displayed if the NSORT_Graph is open
	
		////////////////
		return err
   endif // End the 3-column specific stuff here

   if(numOutputColumns == 6) // Start the 6-column specific stuff here
		//order points in sets 1-2, indexing overlap region
		//put result in temporary waves
		WaveStats/Q $"root:LowQSet:TrimLowQSet_q"
		n1 = V_npnts
		WaveStats/Q $"root:MedQSet:TrimMedQSet_q"
		n2 = V_npnts
		n12 = n1+ n2
		
		Make/O/N=(n12) q12,i12,sig12,sq12,qb12,fs12
		Make/O/N=(n12,3) res12
		WAVE lowq = $"root:LowQSet:TrimLowQSet_q"
		WAVE medq = $"root:MedQSet:TrimMedQSet_q"
		WAVE lowi = $"root:LowQSet:TrimLowQSet_i"
		WAVE medi =  $"root:MedQSet:TrimMedQSet_i"
		WAVE lows = $"root:LowQSet:TrimLowQSet_s"
		WAVE meds = $"root:MedQSet:TrimMedQSet_s"
		WAVE lowres = $"root:LowQSet:TrimLowQSet_res"
		WAVE medres = $"root:MedQSet:TrimMedQSet_res"
		
		q12[0,n1-1] = lowq[p]
		q12[n1,n1+n2-1]= medq[p-n1]
		i12[0,n1-1] = lowi[p]
		i12[n1,n1+n2-1]= medi[p-n1]
		sig12[0,n1-1] = lows[p]
		sig12[n1,n1+n2-1]= meds[p-n1]
		sq12[0,n1-1] = lowres[p][0]
		sq12[n1,n1+n2-1]= medres[p-n1][0]
		qb12[0,n1-1] = lowres[p][1]
		qb12[n1,n1+n2-1]= medres[p-n1][1]
		fs12[0,n1-1] = lowres[p][2]
		fs12[n1,n1+n2-1]= medres[p-n1][2]

		
		Sort q12, q12,i12,sig12,sq12,qb12,fs12
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q medq,(lowq[n1-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm12 = NCNR_GetScalingInOverlap(num2,lowq,lowi,medq,medi)
			//Set the global variable for the 1-2 scale factor
			Variable/G root:myGlobals:NSORT:gScale1_2 = norm12
		else
			//use the value from the panel ( which is the global)
			NVAR temp12 = root:myGlobals:NSORT:gScale1_2
			norm12 = temp12
		Endif
		
		If(normTo== 2)
			//normalize to second file, so multiply 1st by 1/norm
			norm12 = 1/norm12
			lowi *= norm12
			lows *= norm12
		else
			//normalize to first file, OR THIRD FILE so multiply 2nd by norm
			medi *= norm12
			meds *= norm12
		Endif
		
		//Print "NSORT-ed ",name1," + ", name2
		//Print "normalized to ",normTo
		//Print "multiplicative factor = ",norm12
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate

		
		//Make the combined, scaled dataset by overwriting the old sets
		Make/O/N=(n12) q12,i12,sig12,sq12,qb12,fs12
		Make/O/N=(n12,3) res12
		q12[0,n1-1] = lowq[p]
		q12[n1,n1+n2-1]= medq[p-n1]
		i12[0,n1-1] = lowi[p]
		i12[n1,n1+n2-1]= medi[p-n1]
		sig12[0,n1-1] = lows[p]
		sig12[n1,n1+n2-1]= meds[p-n1]
		sq12[0,n1-1] = lowres[p][0]
		sq12[n1,n1+n2-1]= medres[p-n1][0]
		qb12[0,n1-1] = lowres[p][1]
		qb12[n1,n1+n2-1]= medres[p-n1][1]
		fs12[0,n1-1] = lowres[p][2]
		fs12[n1,n1+n2-1]= medres[p-n1][2]

		
		Sort q12, q12,i12,sig12,sq12,qb12,fs12
		//at this point 1-2 are combined
		//do we need to continue, or write out the set here and stop?
		if(cmpstr(name3,"none") == 0)
			//stop here
			norm23 = 1		//norm23 was not used
			Variable/G root:myGlobals:NSORT:gScale2_3 = 1
			
			ControlInfo/W=NSORT_Panel PreviewCheck
			if( V_Value==0 )		//if zero skip the preview and write out the file
				res12[][0] = sq12[p]
				res12[][1] = qb12[p]
				res12[][2] = fs12[p]
				err=WriteNSORTedFile(q12,i12,sig12,name1,name2,name3,name4,normToStr,norm12,norm23,norm34,res=res12)
			endif
			// always clean up waves before exiting
			KillWaves/Z q12,i12,sig12,sq12,qb12,fs12
			return err
		Endif
		
		//need to add the third file... which was already loaded at the top of the function
		/////
		//order points in sets 12-3, indexing overlap region
		//put result in temporary waves
		WaveStats/Q q12
		n12 = V_npnts
		WaveStats/Q $"root:HighQSet:TrimHighQSet_q"
		n3 = V_npnts
		n123 = n12+ n3
		
		Make/O/N=(n123) q123,i123,sig123,sq123,qb123,fs123
		Make/O/N=(n123,3) res123
		WAVE highq = $"root:HighQSet:TrimHighQSet_q"
		WAVE highi = $"root:HighQSet:TrimHighQSet_i"
		WAVE highs = $"root:HighQSet:TrimHighQSet_s"
		WAVE highres = $"root:HighQSet:TrimHighQSet_res"
	
	
		q123[0,n12-1] = q12[p]
		q123[n12,n12+n3-1]= highq[p-n12]
		i123[0,n12-1] = i12[p]
		i123[n12,n12+n3-1]= highi[p-n12]
		sig123[0,n12-1] = sig12[p]
		sig123[n12,n12+n3-1]= highs[p-n12]
		sq123[0,n12-1] = sq12[p]
		sq123[n12,n12+n3-1]= highres[p-n12][0]
		qb123[0,n12-1] = qb12[p]
		qb123[n12,n12+n3-1]= highres[p-n12][1]
		fs123[0,n12-1] = fs12[p]
		fs123[n12,n12+n3-1]= highres[p-n12][2]

		
		Sort q123, q123,i123,sig123,sq123,qb123,fs123
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q highq,(q12[n12-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm23 = NCNR_GetScalingInOverlap(num2,q12,i12,highq,highi)
			//Set the global variable for the 12 - 3 scale factor
			Variable/G root:myGlobals:NSORT:gScale2_3 = norm23
		else
			//use the value from the panel ( which is the global)
			NVAR temp23 = root:myGlobals:NSORT:gScale2_3
			norm23 = temp23
		Endif
		
		If( (normTo== 1) || (normTo ==2) )
			//normalize to first or second file, so multiply third by norm23
			highi *= norm23
			highs *= norm23
		else
			//normalize to THIRD file, 1-2 by 1/norm23
			norm23 = 1/norm23
			i12 *= norm23
			sig12 *= norm23
			// for the display, scale the trimmed sets 1 and 2
			lowi *= norm23
			lows *= norm23
			medi *= norm23
			meds *= norm23
		Endif
		
		//Print "NSORT-ed ",name1," + ", name2, " + ", name3
		//Print "normalized to ",normTo
		//Print "multiplicative factor 1-2 = ",norm12," multiplicative factor 12 - 3 = ",norm23
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate
		
		Make/O/N=(n123) q123,i123,sig123
		Make/O/N=(n123,3) res123
		q123[0,n12-1] = q12[p]
		q123[n12,n12+n3-1]= highq[p-n12]
		i123[0,n12-1] = i12[p]
		i123[n12,n12+n3-1]= highi[p-n12]
		sig123[0,n12-1] = sig12[p]
		sig123[n12,n12+n3-1]= highs[p-n12]
		sq123[0,n12-1] = sq12[p]
		sq123[n12,n12+n3-1]= highres[p-n12][0]
		qb123[0,n12-1] = qb12[p]
		qb123[n12,n12+n3-1]= highres[p-n12][1]
		fs123[0,n12-1] = fs12[p]
		fs123[n12,n12+n3-1]= highres[p-n12][2]

		
		Sort q123, q123,i123,sig123,sq123,qb123,fs123
		//at this point 12 - 3 are combined
		
		//do we need to continue, or write out the set here and stop?
		if(cmpstr(name4,"none") == 0)
			//stop here
		
			ControlInfo/W=NSORT_Panel PreviewCheck
			if( V_Value==0 )		//if zero skip the preview and write out the file
				res123[][0] = sq123[p]
				res123[][1] = qb123[p]
				res123[][2] = fs123[p]
				err=WriteNSORTedFile(q123,i123,sig123,name1,name2,name3,name4,normToStr,norm12,norm23,norm34,res=res123)
			endif
			// always clean up waves before exiting
			KillWaves/Z q12,i12,sig12,q123,i123,sig123,sq123,qb123,fs123 //,res123
			return err
		Endif
		
		// new 2016 - combine the 4th data set

		//need to add the fourth file... which was already loaded at the top of the function
		/////
		//order points in sets 123-4, indexing overlap region
		//put result in temporary waves
		WaveStats/Q q123
		n123 = V_npnts
		WaveStats/Q $"root:HighestQSet:TrimHighestQSet_q"
		n4 = V_npnts
		n1234 = n123 + n4
		
		Make/O/N=(n1234) q1234,i1234,sig1234,sq1234,qb1234,fs1234
		Make/O/N=(n1234,3) res1234
		WAVE highestq = $"root:HighestQSet:TrimHighestQSet_q"
		WAVE highesti = $"root:HighestQSet:TrimHighestQSet_i"
		WAVE highests = $"root:HighestQSet:TrimHighestQSet_s"
		WAVE highestres = $"root:HighestQSet:TrimHighestQSet_res"
	
	
		q1234[0,n123-1] = q123[p]
		q1234[n123,n123+n4-1]= highestq[p-n123]
		i1234[0,n123-1] = i123[p]
		i1234[n123,n123+n4-1]= highesti[p-n123]
		sig1234[0,n123-1] = sig123[p]
		sig1234[n123,n123+n4-1]= highests[p-n123]
		sq1234[0,n123-1] = sq123[p]
		sq1234[n123,n123+n4-1]= highestres[p-n123][0]
		qb1234[0,n123-1] = qb123[p]
		qb1234[n123,n123+n4-1]= highestres[p-n123][1]
		fs1234[0,n123-1] = fs123[p]
		fs1234[n123,n123+n4-1]= highestres[p-n123][2]

		
		Sort q1234, q1234,i1234,sig1234,sq1234,qb1234,fs1234
		/////////////////
		
		//find the maximum point number of set 2  in the overlap region
		FindLevel/P/Q highestq,(q123[n123-1])
		num2 = trunc(V_levelX)
		//Print "num2 = ",num2
		
		if (auto)
			//there must be overlap points to use auto-scaling
			if(numtype(num2) != 0)
				Abort "There are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
			endif
			//do auto-scaling of data
			norm34 = NCNR_GetScalingInOverlap(num2,q123,i123,highestq,highesti)
			//Set the global variable for the 12 - 3 scale factor
			Variable/G root:myGlobals:NSORT:gScale3_4 = norm34
		else
			//use the value from the panel ( which is the global)
			NVAR temp34 = root:myGlobals:NSORT:gScale3_4
			norm34 = temp34
		Endif

// normalization
		switch (normTo)
			case 1:
			case 2:
			case 3:
				//normalize to first or second or third file, so multiply fourth by norm34
				highesti *= norm34
				highests *= norm34
				break
			case 4:
				//normalize to FOURTH file, 123 by multiplicative factor 1/norm34
				norm34 = 1/norm34
				i123 *= norm34
				sig123 *= norm34
				// for the display, scale the trimmed sets 1 and 2 and 3
				lowi *= norm34
				lows *= norm34
				medi *= norm34
				meds *= norm34
				highi *= norm34
				highs *= norm34
				break
		endswitch
		
	
		//Print "NSORT-ed ",name1," + ", name2, " + ", name3
		//Print "normalized to ",normTo
		//Print "multiplicative factor 1-2 = ",norm12," multiplicative factor 12 - 3 = ",norm23
		ControlUpdate/A/W=NSORT_Panel
		DoUpdate
		
		Make/O/N=(n1234) q1234,i1234,sig1234
		Make/O/N=(n1234,3) res1234
		q1234[0,n123-1] = q123[p]
		q1234[n123,n123+n4-1]= highestq[p-n123]
		i1234[0,n123-1] = i123[p]
		i1234[n123,n123+n4-1]= highesti[p-n123]
		sig1234[0,n123-1] = sig123[p]
		sig1234[n123,n123+n4-1]= highests[p-n123]
		sq1234[0,n123-1] = sq123[p]
		sq1234[n123,n123+n4-1]= highestres[p-n123][0]
		qb1234[0,n123-1] = qb123[p]
		qb1234[n123,n123+n4-1]= highestres[p-n123][1]
		fs1234[0,n123-1] = fs123[p]
		fs1234[n123,n123+n4-1]= highestres[p-n123][2]
		
		Sort q1234, q1234,i1234,sig1234,sq1234,qb1234,fs1234
		//at this point 123 - 4 are combined
		
//write out the set here and stop
			//stop here
	
		ControlInfo/W=NSORT_Panel PreviewCheck
		if( V_Value==0 )		//if zero skip the preview and write out the file
			res1234[][0] = sq1234[p]
			res1234[][1] = qb1234[p]
			res1234[][2] = fs1234[p]
			err=WriteNSORTedFile(q1234,i1234,sig1234,name1,name2,name3,name4,normToStr,norm12,norm23,norm34,res=res1234)
		endif
		// always clean up waves before exiting
		KillWaves/Z q123,i123,sig123,q1234,i1234,sig1234,sq1234,qb1234,fs1234 //,res1234
		return err

		//combined dataset will already be displayed if the NSORT_Graph is open
	
		////////////////
		return err
   endif // End the if(6-column) specific stuff here
	
	
End






/////////////////////////////////////////////////////////////
// testing, may speed up NSORT, NCNR-specific naming scheme of 
// run numbers and a run prefix
//
// it is assumed that you are combining data from the current reduction session,
// so that the XML y/n hasn't changed.
//
Function Set3NSORTFiles(low,med,hi,pref)
	Variable low,med,hi
	String pref
	
	//make strings from the numbers
	String absStr="",ext
	Variable popNum
	DoWindow/F NSORT_Panel
	
	SVAR lowQPopStr = root:myGlobals:NSORT:gDataPopList
	SVAR medHiQPopStr = root:myGlobals:NSORT:gDataPopList_3
	
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	if(useXMLOutput)
		ext = ".ABSx"
	else
		ext = ".ABS"
	endif
	
	//lowQ menu
	absStr = pref+RunDigitString(low)+ext
	popNum = WhichListItem(absStr,lowQPopStr,";",0)
	if(popNum == -1)
		Abort "Could not find file: " + absStr +" aborting...  Be sure that your output format is the same as the input"
	endif
	popNum += 1		// add 1 to get the item number
	PopupMenu popup_1,win=NSORT_Panel,mode=(popNum)
	
	//medQ (a different list for the popup)
	absStr = pref+RunDigitString(med)+ext
	popNum = WhichListItem(absStr,medHiQPopStr,";",0)
	if(popNum == -1)
		Abort "Could not find file: "+absStr+" aborting...  Be sure that your output format is the same as the input"
	endif
	popNum += 1		// add 1 to get the item number
	PopupMenu popup_2,win=NSORT_Panel,mode=(popNum)
	
	
	//highQ (same pop list as medQ)
	if(hi != 0)
		absStr = pref+RunDigitString(hi)+ext
		popNum = WhichListItem(absStr,medHiQPopStr,";",0)
		if(popNum == -1)
			Abort "Could not find file: "+absStr+" aborting...  Be sure that your output format is the same as the input"
		endif
		popNum += 1		// add 1 to get the item number
		PopupMenu popup_3,win=NSORT_Panel,mode=(popNum)
	else
		PopupMenu popup_3,win=NSORT_Panel,mode=(1)
	endif
End

/////////////////////////////////////////////////////////////
// testing, may speed up NSORT, NCNR-specific naming scheme of 
// run numbers and a run prefix
//
// it is assumed that you are combining data from the current reduction session,
// so that the XML y/n hasn't changed.
//
// updated to use 4 files
//
// TODO:
// -- still assuming ABS
//
Function Set4NSORTFiles(low,med,hi,highest,pref)
	Variable low,med,hi,highest
	String pref
	
	//make strings from the numbers
	String absStr="",ext
	Variable popNum
	DoWindow/F NSORT_Panel
	
	SVAR lowQPopStr = root:myGlobals:NSORT:gDataPopList
	SVAR medHiQPopStr = root:myGlobals:NSORT:gDataPopList_3
	
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	if(useXMLOutput)
		ext = ".ABSx"
	else
		ext = ".ABS"
	endif
	
	//lowQ menu
	absStr = pref+RunDigitString(low)+ext
	popNum = WhichListItem(absStr,lowQPopStr,";",0)
	if(popNum == -1)
		Abort "Could not find file: " + absStr +" aborting...  Be sure that your output format is the same as the input"
	endif
	popNum += 1		// add 1 to get the item number
	PopupMenu popup_1,win=NSORT_Panel,mode=(popNum)
	
	//medQ (a different list for the popup)
	absStr = pref+RunDigitString(med)+ext
	popNum = WhichListItem(absStr,medHiQPopStr,";",0)
	if(popNum == -1)
		Abort "Could not find file: "+absStr+" aborting...  Be sure that your output format is the same as the input"
	endif
	popNum += 1		// add 1 to get the item number
	PopupMenu popup_2,win=NSORT_Panel,mode=(popNum)
	
	
	//highQ (same pop list as medQ)
	if(hi != 0)
		absStr = pref+RunDigitString(hi)+ext
		popNum = WhichListItem(absStr,medHiQPopStr,";",0)
		if(popNum == -1)
			Abort "Could not find file: "+absStr+" aborting...  Be sure that your output format is the same as the input"
		endif
		popNum += 1		// add 1 to get the item number
		PopupMenu popup_3,win=NSORT_Panel,mode=(popNum)
	else
		PopupMenu popup_3,win=NSORT_Panel,mode=(1)
	endif
	
	//highestQ (same pop list as medQ)
	if(highest != 0)
		absStr = pref+RunDigitString(highest)+ext
		popNum = WhichListItem(absStr,medHiQPopStr,";",0)
		if(popNum == -1)
			Abort "Could not find file: "+absStr+" aborting...  Be sure that your output format is the same as the input"
		endif
		popNum += 1		// add 1 to get the item number
		PopupMenu popup_4,win=NSORT_Panel,mode=(popNum)
	else
		PopupMenu popup_4,win=NSORT_Panel,mode=(1)
	endif
	
	return(0)
End

//more beta procedures - to create a table of scattering runs to combine with NSORT
Proc CreateTableToCombine(ctrlName)
	String ctrlName
	
	NewDataFolder/O root:myGlobals:CombineTable
//	DoWindow/F CombineTable
	
	Make/O/T/N=0 $"root:myGlobals:CombineTable:Filenames"
	Make/O/T/N=0 $"root:myGlobals:CombineTable:Suffix"
	Make/O/T/N=0 $"root:myGlobals:CombineTable:Labels"
	Make/O/D/N=0 $"root:myGlobals:CombineTable:SDD"
	Make/O/D/N=0 $"root:myGlobals:CombineTable:RunNumber"
	Make/O/D/N=0 $"root:myGlobals:CombineTable:IsTrans"


	AppendToTable/W=CombinePanel#GroupedFiles root:myGlobals:CombineTable:Labels, root:myGlobals:CombineTable:SDD, root:myGlobals:CombineTable:RunNumber

	ModifyTable/W=CombinePanel#GroupedFiles width(:myGlobals:CombineTable:SDD)=40
	ModifyTable/W=CombinePanel#GroupedFiles width(:myGlobals:CombineTable:Labels)=180
	ModifyTable/W=CombinePanel#GroupedFiles width(Point)=0		//JUN04, remove point numbers - confuses users since point != run


	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	//remove version numbers from semicolon-delimited list
	list =  RemoveVersNumsFromList(list)
	numitems = ItemsInList(list,";")
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	//***version numbers have been removed***
	String str,fullName
	Variable lastPoint
	ii=0
	
	Make/T/O/N=0 notRAWlist
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = FindValidFilename(partialName)
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = CheckIfRawData(fullName)
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				GetHeaderInfoToCombineWave(fullName,tempName)
			Endif
		Endif
		ii+=1
	while(ii<numitems)
//Now sort them all based on the suffix data (orders them as collected)
//	SortCombineWaves()
// sort by label
	SortCombineByLabel()
// remove the transmission waves
//
	RemoveTransFilesFromCombine()
//
	SetDataFolder root:
	
	Killwaves/Z notRAWlist
End


Function RemoveTransFilesFromCombine()
	Wave/T filenames = $"root:myGlobals:CombineTable:Filenames"
	Wave/T suffix = $"root:myGlobals:CombineTable:Suffix"
	Wave/T labels = $"root:myGlobals:CombineTable:Labels"
	Wave sdd = $"root:myGlobals:CombineTable:SDD"
	Wave runnum = $"root:myGlobals:CombineTable:RunNumber"
	Wave isTrans = $"root:myGlobals:CombineTable:IsTrans"
	
	Variable num=numpnts(isTrans),ii
	ii=num-1
	do
		if(isTrans[ii] != 0)
			DeletePoints ii, 1, filenames,suffix,labels,sdd,runnum,isTrans
		endif
		ii-=1
	while(ii>=0)
	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function GetHeaderInfoToCombineWave(fname,sname)
	String fname,sname
	
	String textstr,temp,lbl,date_time,suffix
	Variable ctime,lambda,sdd,detcnt,cntrate,refNum,trans,thick,xcenter,ycenter,numatten
	Variable lastPoint, beamstop

	Wave/T GFilenames = $"root:myGlobals:CombineTable:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CombineTable:Suffix"
	Wave/T GLabels = $"root:myGlobals:CombineTable:Labels"
	Wave GSDD = $"root:myGlobals:CombineTable:SDD"
	Wave GRunNumber = $"root:myGlobals:CombineTable:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CombineTable:IsTrans"
	
	lastPoint = numpnts(GLambda)
		
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
	//read the file suffix
	InsertPoints lastPoint,1,GSuffix
	// -- replace the suffix (that doesn't exist in the Nexus file) -- with the filename for now
	GSuffix[lastPoint]=getSuffix(fname)

	// read the sample.label text field
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=getSampleDescription(fname)
	
	//read in the SDD
	InsertPoints lastPoint,1,GSDD
	GSDD[lastPoint]= getDet_Distance(fname)

	//the run number (not displayed in the table, but carried along)
	InsertPoints lastPoint,1,GRunNumber
	GRunNumber[lastPoint] = GetRunNumFromFile(sname)

	// 0 if the file is a scattering  file, 1 (truth) if the file is a transmission file
	InsertPoints lastPoint,1,GIsTrans
	GIsTrans[lastPoint]  = isTransFile(fname)		//returns one if beamstop is "out"
	
	KillWaves/Z w
	return(0)
End

//sorts all of the waves of header information using the suffix (A123) 
//the result is that all of the data is in the order that it was collected,
// regardless of how the prefix or run numbers were changed by the user
Function SortCombineWaves()
	Wave/T GFilenames = $"root:myGlobals:CombineTable:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CombineTable:Suffix"
	Wave/T GLabels = $"root:myGlobals:CombineTable:Labels"
	Wave GSDD = $"root:myGlobals:CombineTable:SDD"
	Wave GRunNumber = $"root:myGlobals:CombineTable:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CombineTable:IsTrans"

//	Sort GSuffix, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans
	Sort GSuffix, GSuffix, GFilenames, GLabels, GSDD, GRunNumber, GIsTrans
	return(0)
End

//sorts all of the waves of header information using the suffix (A123) 
//the result is that all of the data is in the order that it was collected,
// regardless of how the prefix or run numbers were changed by the user
Function SortCombineByLabel()
	Wave/T GFilenames = $"root:myGlobals:CombineTable:Filenames"
	Wave/T GSuffix = $"root:myGlobals:CombineTable:Suffix"
	Wave/T GLabels = $"root:myGlobals:CombineTable:Labels"
	Wave GSDD = $"root:myGlobals:CombineTable:SDD"
	Wave GRunNumber = $"root:myGlobals:CombineTable:RunNumber"
	Wave GIsTrans = $"root:myGlobals:CombineTable:IsTrans"

	Sort GLabels, GSuffix, GFilenames, GLabels, GSDD, GRunNumber, GIsTrans
//	Sort {GLabels, GSDD}, GSuffix, GFilenames, GLabels, GSDD, GRunNumber, GIsTrans		//sort on GLabels, GSDD breaks the tie
	return(0)
End

//main procedure, called from the menu
// sets a flag (temporarily) to use the names from the table
// during the procedure that writes the data files.
//
//
Function DoCombineFiles(ctrlName)
	String ctrlName
	
	
	if(WinType("NSORT_Panel") == 0)
		DoAlert 0, "The SORT Panel must be open to combine the files"
		return(0)
	endif
	
	DoAlert 1,"Do you have all the assignments set in the bottom table? If not, < No > will exit."
	if(V_flag == 2)
		return(0)		//no, get out
	endif
	// pop all of the menus to make sure that they are properly populated
	LowQPopMenuProc("",1,"")
	MedQPopMenuProc("",1,"")
	HighQPopMenuProc("",1,"")
	HighestQPopMenuProc("",1,"")
	
//	String savedDataFolder = GetDataFolder(1)		// save
	Wave LowRun = root:myGlobals:CombineTable:LowRun
	Wave MediumRun = root:myGlobals:CombineTable:MediumRun
	Wave HighRun = root:myGlobals:CombineTable:HighRun
	Wave HighestRun = root:myGlobals:CombineTable:HighestRun
	Wave/T prefix = root:myGlobals:CombineTable:Prefix
	Wave/T saveName = root:myGlobals:CombineTable:saveName

	Variable/G root:myGlobals:CombineTable:useTable=1
	
	Variable num=numpnts(lowRun),ii,lowFile,medFile,hiFile,highestFile
	String prefixStr = ""
	Pathinfo catPathName
	String path=S_Path
	
	ii=0
	do
		lowFile = LowRun[ii]
		medFile = MediumRun[ii]
		hiFile = highRun[ii]
		highestFile = highestRun[ii]
		prefixStr = prefix[ii]
		
		Set4NSORTFiles(lowFile,medFile,hiFile,highestFile,prefixStr)		//set the files and pop the NSORT popups
		
		//pass the new file name in as a global (ugh!)
		String/G root:myGlobals:CombineTable:SaveNameStr = path+saveName[ii]
		//combine the files and write the data
		WriteNSORTFileButton("")
		
		Print "wrote file : ",path+saveName[ii]
		ii+=1
	while(ii<num)

	Variable/G root:myGlobals:CombineTable:useTable=0		//turn this off immediately
	
	return(0)
End


// only respond to clicks in the subwindow (table) rather than everywhere. Hooks can't be set for subwindows
//
//// Window hook example:
//  WINDOW:CombinePanel;HCSPEC:CombinePanel#GroupedFiles;EVENT:mouseup;MOUSEX:152;MOUSEY:143;TICKS:7722029;MODIFIERS:0;
//
Function CombineTableHook(infoStr)
	String infoStr
	String event= StringByKey("EVENT",infoStr)
	String subwin = StringByKey("HCSPEC",infoStr)
//	Print subwin
//	Print infoStr
//	Print "EVENT= ",event
	if(cmpstr(subwin,"CombinePanel#GroupedFiles")==0)
		strswitch(event)
			case "mousedown":
				Variable xpix= NumberByKey("MOUSEX",infoStr)
				Variable ypix= NumberByKey("MOUSEY",infoStr)
				Variable modif= NumberByKey("MODIFIERS",infoStr)
				//print modif
				if(modif & 2^1)		//bit 1 set, shift key is down
					PopupContextualMenu/C=(xpix, ypix) "combine;"
					strswitch(S_selection)
						case "combine":
							//Print "combine the files"
							SendSelectionToTable()
							break
					endswitch		//on selection
				endif
		endswitch	// on event
	endif
	return 0
End

//ASSUMES 3 FILES!!!!
Function SendSelectionToTable()

	DoWindow/F CombinePanel
	if(V_flag==0)
//		Make/O/N=0 $"root:myGlobals:CombineTable:Low"
//		Make/O/N=0 $"root:myGlobals:CombineTable:Medium"
//		Make/O/N=0 $"root:myGlobals:CombineTable:High"
//		Make/O/T/N=0 $"root:myGlobals:CombineTable:Prefix"
//		Make/O/T/N=0 $"root:myGlobals:CombineTable:SaveName"
//		edit Low,Medium,High,Prefix,SaveName as "Run Numbers to Combine"
//		DoWindow/C ToCombine

		return(0)
		
	else
		Wave low = $"root:myGlobals:CombineTable:LowRun"
		Wave medium = $"root:myGlobals:CombineTable:MediumRun"
		Wave high = $"root:myGlobals:CombineTable:HighRun"
		Wave highest = $"root:myGlobals:CombineTable:HighestRun"
		Wave/T prefix = $"root:myGlobals:CombineTable:Prefix"
		Wave/T saveName = $"root:myGlobals:CombineTable:SaveName"
		
		Wave/T gLabels = $"root:myGlobals:CombineTable:Labels"
		Wave gSDD = $"root:myGlobals:CombineTable:SDD"
		Wave gRunNumber = $"root:myGlobals:CombineTable:RunNumber"
		Wave/T filenames = $"root:myGlobals:CombineTable:FileNames"
	endif
	
	GetSelection table,CombinePanel#GroupedFiles,3
//	Print V_startRow, V_endRow
	
	//prompt for combined name, give the user a chance to cancel
	Variable num=V_endRow-V_startRow+1
	Variable ii
	String saveStr=""
	Prompt saveStr,"saved file name for "+ gLabels[V_StartRow]	//+tmpLbl[1]
	DoPrompt "Enter the combined file name",saveStr
	if(V_flag==1)
		return(1)		//user cancel, get out before anything is set
	endif

	if( !(num==2 || num==3 || num==4) )
		Abort "invalid table selection - must select either 2 or 3 or 4 files to combine"
	endif
	Make/O/T/N=(4) tmpLbl
	Make/O/N=(4) tmpSDD,tmpRun
	
	//initialize with fake values in case 2 or 3 files are combined
	tmpLbl = ""
	tmpSDD = 0.01		//fake sdd in meters to always be the "highest" Q
	tmpRun = 0			//pass a run number of zero to be later interpreted as "none"
	
	//fill in the real values from the selection
	for(ii=V_startRow;ii<=V_endRow;ii+=1)
		tmpLbl[ii-V_startRow] = gLabels[ii]
		tmpSDD[ii-V_startRow] = gSDD[ii]
		tmpRun[ii-V_startRow] = gRunNumber[ii]
	endfor
//	if(num==2)	// then "highest" q run needs to be forced to zero
//		ii=2
//		tmpLbl[ii] = ""
//		tmpSDD[ii] = 0.01		//fake sdd in meters to always be the "highest" Q
//		tmpRun[ii] = 0			//pass a run number of zero to be later interpreted as "none"
//	endif
	Sort tmpSDD, tmpSDD,tmpLbl,tmpRun
	
//	Print tmpSDD
	
	num=numpnts(low)
	InsertPoints num, 1, low,medium,high,highest,prefix,SaveName
	low[num] = tmpRun[3]
	medium[num] = tmpRun[2]
	high[num] = tmpRun[1]
	highest[num] = tmpRun[0]
	prefix[num] = GetPrefixStrFromFile(filenames[ii])
	saveName[num] = saveStr	

	KillWaves/Z tmpLbl,tmpRun,tmpSDD
	return(0)
end


////////////////////////
// replaces the beta menu items
//

Proc ShowCombinePanel()
	DoWindow/F CombinePanel
	if(V_flag==0)
		CombinePanel()
		CreateTableToCombine("")
		DoAlert 1,"Do you want to clear the list of runs and file names to combine?"
		TableToCombineAndSave(V_flag==1)		// clear and initialize, if desired
	endif
end

Proc CombinePanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(546,442,1197,915) /K=1 as "Sort and Combine Data Files"
	ModifyPanel cbRGB=(49151,53155,65535)
	DoWindow/C CombinePanel
	Button button0_0,pos={20,20},size={160,20},proc=CreateTableToCombine,title="List Files to Combine"
	Button button0_1,pos={206,20},size={140,20},proc=DoCombineFiles,title="Combine Files"
	Button button0_2,pos={509,40},size={60,20},proc=CombinePanelDone,title="Done"
	Button button0_3,pos={522,14},size={30,20},proc=ShowCombineHelp,title="?"
	Button button0_4,pos={500,220},size={120,20},proc=ClearCombineTable,title="Clear Table?"
	Edit/W=(20,54,368,249)/HOST=# 
	ModifyTable format=1,width=0
	RenameWindow #,GroupedFiles
	SetActiveSubwindow ##
	Edit/W=(20,263,634,455)/HOST=# 
	ModifyTable format=1
	RenameWindow #,RunNumbersToCombine
	SetActiveSubwindow ##
	SetWindow kwTopWin hook=CombineTableHook, hookevents=1	// mouse down events
EndMacro

Proc ShowCombineHelp(ctrlName): ButtonControl
	String ctrlName
	DisplayHelpTopic/K=1/Z "SANS Data Reduction Tutorial[Batch Combine Data Files]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
end

Function CombinePanelDone(ctrlName)
	String ctrlName
	
	DoWindow/K CombinePanel
	return(0)
end

Function ClearCombineTable(ctrlName)
	String ctrlName
	
	DoAlert 1,"Do you want to clear the list of runs and file names to combine?"
	TableToCombineAndSave(V_flag==1)		// clear and initialize, if desired
	return(0)
end

Function TableToCombineAndSave(clear)
	Variable clear
	
	if(clear)
		// make the waves and table for the sets to combine
		Make/O/N=0 $"root:myGlobals:CombineTable:LowRun"
		Make/O/N=0 $"root:myGlobals:CombineTable:MediumRun"
		Make/O/N=0 $"root:myGlobals:CombineTable:HighRun"
		Make/O/N=0 $"root:myGlobals:CombineTable:HighestRun"
		Make/O/T/N=0 $"root:myGlobals:CombineTable:Prefix"
		Make/O/T/N=0 $"root:myGlobals:CombineTable:SaveName"
	endif
	SetDataFolder root:myGlobals:CombineTable
	
	// make the second table
	AppendToTable/W=CombinePanel#RunNumbersToCombine LowRun,MediumRun,HighRun,HighestRun,Prefix,SaveName
	
	SetDataFolder root:
End



/////////////////////////////////
// currently unused
//
Proc MakeCombineTable_byName()
	NewDataFolder/O root:myGlobals:CombineTable			//in case it doesn't exist yet
	Make/O/T/N=1 lowQfile,medQfile,hiQfile,saveName
	Edit/W=(330,148,973,360) lowQfile,medQfile,hiQfile,saveName
	ModifyTable format(Point)=1,width(lowQfile)=120,width(medQfile)=120,width(hiQfile)=120
	ModifyTable width(saveName)=120	
End

//
// currently unused
//
// Another beta procedure, to allow files to be combined quickly
// - make 4 waves (text) with the low, med, hi, and wave names
// (if there is no hiQ, then pass a wave with "" for all entries)
// - then pass the waves, and the save will work like in the DoCombineFiles
//
// - the named files must be there - there is no error checking
// - the NSORT panel must be open with the proper selections of beg,end and autoscale, etc.
//
// - could write a little proc to generate a table to fill in and a button to call this
// - and then think of quick ways to populate the table with file names (and minimize typos)
//
Function DoCombineFiles_byName(lowW,medW,hiW,saveW)
	Wave/T lowW,medW,hiW,saveW
		
	if(WinType("NSORT_Panel") == 0)
		DoAlert 0, "The SORT Panel must be open to combine the files"
		return(0)
	endif
	
	// pop all of the menus to make sure that they are properly populated
	LowQPopMenuProc("",1,"")
	MedQPopMenuProc("",1,"")
	HighQPopMenuProc("",1,"")
	
	Variable num=numpnts(lowW),ii
	String lowFile,medFile,hiFile
	
	Pathinfo catPathName
	String path=S_Path
	
////////	Make/O/D/N=(numpnts(lowW)) scale_4m
	NVAR scale12 = root:myGlobals:NSORT:gScale1_2

	
// this variable must exist and be set to 1 to be able to automatically name files
// and use the global saveNameStr that is passed in
// -- turn this off when done	
	Variable/G root:myGlobals:CombineTable:useTable=1		

	ii=0
	do
		lowFile = lowW[ii]
		medFile = medW[ii]
		hiFile = hiW[ii]
		
		//Set3NSORTFiles(lowFile,medFile,hiFile,prefixStr)		//set the files and pop the NSORT popups
		//lowQ menu
		PopupMenu popup_1 win=NSORT_Panel,popmatch=lowFile
		
		// mediumQ menu
		if(strlen(medFile)!=0)
			PopupMenu popup_2 win=NSORT_Panel,popmatch=medFile
		else
			PopupMenu popup_2,win=NSORT_Panel,popmatch="none"	//set to "none"
		endif
	
		//highQ (same pop list as medQ)
		if(strlen(hiFile)!=0)
			PopupMenu popup_3 win=NSORT_Panel,popmatch=hiFile
		else
			PopupMenu popup_3,win=NSORT_Panel,popmatch="none"	//set to "none"
		endif
		
		
		//pass the new file name in as a global (ugh!)
		String/G root:myGlobals:CombineTable:SaveNameStr = path+saveW[ii]
		//combine the files and write the data
		WriteNSORTFileButton("")
		
//////		scale_4m[ii] = scale12
		
		Print "wrote file : ",path+saveW[ii]
		ii+=1
	while(ii<num)

	Variable/G root:myGlobals:CombineTable:useTable=0		//turn this off immediately
	
	return(0)
End