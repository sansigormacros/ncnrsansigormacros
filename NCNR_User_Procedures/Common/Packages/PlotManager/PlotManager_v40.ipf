#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.00
#pragma IgorVersion=6.1


//////////////////////////////////////////
//
// Plot manager that is largely based on the plot manager in the Reduction package
//
// "A_" is crudely prepended to function names to avoid conflicts
//
// -- data folders will sitll overlap, but should not be an issue
//
// 28SEP07 SRK
//
//////////////////////////////////////////
Proc Show_Plot_Manager()
	A_Init_OneDLoader()
	DoWindow/F Plot_Manager
	if(V_flag==0)
		A_Plot_Manager()
	endif
	A_OneDLoader_GetListButton("")
End

Window A_Plot_Manager()

	Variable sc = 1		//default
	if(exists("root:Packages:NIST:VSANS:Globals:gLaptopMode")==2)	//NVAR does exist
		if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)	//then is the value 1
			sc = 0.7
		endif
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(658*sc,347*sc,1018*sc,737*sc)/N=Plot_Manager/K=2 as "Plot Manager"
	ModifyPanel cbRGB=(37265,65535,32896)
	ModifyPanel fixedSize=1
	
	Button button0,pos={sc*165,353*sc},size={sc*50,20*sc},proc=A_PlotManager_Done,title="Done"
	PopupMenu popup0,pos={sc*15,225*sc},size={sc*233,20*sc},title="Data in Memory"
	PopupMenu popup0,mode=1,value= #"A_OneDDataInMemory()"
	Button button2,pos={sc*122,259*sc},size={sc*100,20*sc},proc=A_PlotManager_Append,title="Append Data"
	Button button3,pos={sc*15,259*sc},size={sc*80,20*sc},proc=A_PlotManager_newGraph,title="New Graph"
	Button button4,pos={sc*15,293*sc},size={sc*220,20*sc},proc=A_PlotManager_Kill,title="Remove Selection From Memory"
	Button button5,pos={sc*15,323*sc},size={sc*220,20*sc},proc=A_PlotManager_KillAll,title="Remove All Data From Memory"
	ListBox fileList,pos={sc*13,11*sc},size={sc*206,179*sc}
	ListBox fileList,listWave=root:Packages:NIST:OneDLoader:fileWave
	ListBox fileList,selWave=root:Packages:NIST:OneDLoader:selWave,mode= 4
	Button button6,pos={sc*238,165*sc},size={sc*100,20*sc},proc=A_OneDLoader_LoadButton,title="Load File(s)"
	Button button6,help={"Loads the selected files into memory and will graph them if that option is checked"}
	Button button7,pos={sc*238,20*sc},size={sc*100,20*sc},proc=A_OneDLoader_NewFolderButton,title="New Folder"
	Button button7,help={"Select a new data folder"}
	Checkbox check0,pos={sc*240,190*sc},title="Plot data on loading?",noproc,value=1
	GroupBox group0,pos={sc*222,127*sc},size={sc*50,4*sc},title="Shift-click to load"
	GroupBox group0_1,pos={sc*222,143*sc},size={sc*50,4*sc},title="multiple files"
	GroupBox group1,pos={sc*7,207*sc},size={sc*350,4*sc}
	Button button8,pos={sc*238,76*sc},size={sc*100,20*sc},proc=A_OneDLoader_HelpButton,title="Help"
	Button button9,pos={sc*238,48*sc},size={sc*100,20*sc},proc=A_PlotManager_Refresh,title="Refresh List"
EndMacro

//open the Help file for the Fit Manager
Function A_OneDLoader_HelpButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/K=1/Z "Plot Manager"
			if(V_flag !=0)
				DoAlert 0,"The Plot Manager Help file could not be found"
			endif
			break
	endswitch

	return 0
End

//uses the same data folder listing as the wrapper
// if it's right there, it's right here
Function/S A_OneDDataInMemory()
	//AJJ Oct 2008
	//To make this general for both analysis and reduction this code must be a duplicate 
	//W_DataPopupList rather than a call to it as IGOR doesn't like assignment to function 
	//that doesn't exists even if you've done a if(exists... to check first.
	//Grrr
	String list = GetAList(4)
	if (strlen(list) == 0)
		list = "No data loaded"
	endif
	list = SortList(list)
	
	return(list)
end


Function A_PlotManager_Done(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K Plot_Manager
End

Function A_PlotManager_Append(ctrlName) : ButtonControl
	String ctrlName
	//appends data set from memory
	
	//get the current selection
	ControlInfo popup0
	if(strlen(S_Value)==0 || cmpstr(S_Value,"No data loaded")==0)
		Abort "You must load data from a file into memory before appending the data"
	Endif
	
	A_PM_doAppend(S_Value)
	
	DoWindow/F Plot_Manager
End

//actually does the appending
//pass it the name of the wave, find the q-i-s waves
Function A_PM_doAppend(DF)
	String DF
	//appends data set from memory
	String qStr,eStr,istr
	Variable rr,gg,bb
	
	if(cmpstr(WinList("*", ";","WIN:1"),"") == 0 )
		DoAlert 0,"There are no open graphs. Please use the New Graph button"
		return(0)
	endif
	
	SetDataFolder $("root:"+DF)
	//iStr will end in "i"
	qStr = DF+"_q"
	eStr = DF+"_s"
	iStr = DF+"_i"
	
	rr = abs(trunc(enoise(65535)))
	gg = abs(trunc(enoise(65535)))
	bb = abs(trunc(enoise(65535)))
	
	// append to whatever is top-most graph
	AppendToGraph $iStr vs $qStr
	ModifyGraph log=1,mode($istr)=3,marker($iStr)=19,msize($iStr)=2,rgb($iStr)=(rr,gg,bb)
	ErrorBars/T=0 $iStr Y,wave=($eStr,$eStr)

	SetDataFolder root:
End

Proc A_PlotManager_newGraph(ctrlName) : ButtonControl
	String ctrlName
	
	//get the current selection
	ControlInfo popup0
	if(strlen(S_Value)==0 || cmpstr(S_Value,"No data loaded")==0)
		Abort "You must load data from a file into memory before plotting the data"
	Endif
	
	A_PM_doNewGraph(S_Value)
	DoWindow/F Plot_Manager
End

Function A_PM_doNewGraph(DF)
	String DF

	String qStr,eStr,iStr
	Variable rr,gg,bb
	
	SVAR/Z angst = root:Packages:NIST:gAngstStr
	
	SetDataFolder $("root:"+DF)
	//iStr will end in "i"
	qStr = DF+"_q"
	eStr = DF+"_s"
	iStr = DF+"_i"
	
	rr = abs(trunc(enoise(65535)))
	gg = abs(trunc(enoise(65535)))
	bb = abs(trunc(enoise(65535)))
	
	// always make a new graph
	Display $iStr vs $qStr
	ModifyGraph log=1,mode($istr)=3,marker($iStr)=19,msize($iStr)=2,rgb=(rr,gg,bb)
	ModifyGraph grid=1,mirror=2,standoff=0
	ErrorBars/T=0 $iStr Y,wave=($eStr,$eStr)
	ModifyGraph tickUnit=1
				
	Label left "I(q)"
//	Label bottom "q (A\\S-1\\M)"
	Label bottom "q ("+angst+"\\S-1\\M)"	
	Legend
	
	SetDataFolder root:
End

//kill the specified wave (if possible)
Proc A_PlotManager_Kill(ctrlName) : ButtonControl
	String ctrlName
	
	String savDF=GetDataFolder(1)
	String DF

	ControlInfo popup0
	DF=S_Value		//this will end in "i"

	SetDataFolder DF
	KillVariables/A			//removes the dependent variables
	SetDataFolder savDF
		
	//now kill the data folder
	KillDataFolder/Z $DF
	ControlUpdate popup0		//refresh the popup, very important if last item removed
End

//kill the specified wave (if possible)
Proc A_PlotManager_KillAll(ctrlName) : ButtonControl
	String ctrlName
	
	String savDF=GetDataFolder(1)
	String DF

	String list =  A_OneDDataInMemory()
	Variable num=ItemsInList(list),ii
	
	ii=0
	do	
		DF=StringFromList(ii, list  ,";")
		
		SetDataFolder DF
		KillVariables/A			//removes the dependent variables first
		SetDataFolder savDF
	
		//now kill the data folder
		KillDataFolder/Z $DF
		ii+=1
	while(ii<num)
	ControlUpdate popup0		//refresh the popup, very important if all items are removed
End

Proc A_Init_OneDLoader()
	//create the data folder
	NewDataFolder/O/S root:Packages:NIST:OneDLoader
	//create the waves
	Make/O/T/N=1 fileWave=""
	Make/O/N=1 selWave=0
	Variable/G ind=0
	SetDataFolder root:
End


//prompt for a new path, and get a new listing
Function A_OneDLoader_NewFolderButton(ctrlName) : ButtonControl
	String ctrlName

	A_PickPath()
	A_OneDLoader_GetListButton("")
	return(0)
End

//refresh the listing
Function A_PlotManager_Refresh(ctrlName) : ButtonControl
	String ctrlName

	A_OneDLoader_GetListButton("")
	return(0)
End

//filters to remove only the files that are named like a raw data file, i.e. "*.SAn"
//does not check to see if they really are RAW files though...(too tedious)
Function A_OneDLoader_GetListButton(ctrlName) : ButtonControl
	String ctrlName
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use \"New Folder\" button on Main Panel"
	Endif
	
	String newList = A_ReducedDataFileList("")
	Variable num
	
	num=ItemsInList(newlist,";")
	WAVE/T fileWave=$"root:Packages:NIST:OneDLoader:fileWave"
	WAVE selWave=$"root:Packages:NIST:OneDLoader:selWave"
	Redimension/N=(num) fileWave
	Redimension/N=(num) selWave
	fileWave = StringFromList(p,newlist,";")
	Sort filewave,filewave
End

Function A_OneDLoader_LoadButton(ctrlName) : ButtonControl
	String ctrlName
	
	//loop through the selected files in the list...
	Wave/T fileWave=$"root:Packages:NIST:OneDLoader:fileWave"
	Wave sel=$"root:Packages:NIST:OneDLoader:selWave"
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
			fname=pathStr + fileWave[ii]
			Execute "A_LoadOneDDataWithName(\""+fname+"\","+num2str(doGraph)+")"
			cnt += 1 	//a file was loaded
		endif
		ii+=1
	while(ii<num)

	ControlUpdate/W=Plot_Manager popup0

	return(0)
End


//function called by the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// could also use the alternate procedure of keeping only file with the proper extension
//
// another possibility is to get a listing of the text files, but is unreliable on 
// Windows, where the data file must be .txt (and possibly OSX)
//
// TODO: this is a duplicated procedure. See the equivalent in NCNR_Utils and which one to keep?
Function/S A_ReducedDataFileList(ctrlName)
	String ctrlName

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		Return("")
	Endif
	
	list = IndexedFile(catpathName,-1,"????")
	
	list = RemoveFromList(ListMatch(list,"*.SA1*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.SA2*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.SA3*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.SA4*",";"), list, ";", 0)		// added JAN 2013 for new guide hall
	list = RemoveFromList(ListMatch(list,"*.SA5*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,".*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.pxp",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.DIV",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.GSP",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.MASK",";"), list, ";", 0)
#if(exists("QUOKKA") == 6)
	list = RemoveFromList(ListMatch(list,"*.nx.hdf",";"), list, ";", 0)	
	list = RemoveFromList(ListMatch(list,"*.bin",";"), list, ";", 0)	
#endif
	

	//sort
	newList = SortList(List,";",0)

	return newlist
End