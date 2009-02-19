#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.21
#pragma IgorVersion=6.0

//********************
// 101101 Vers. 1
//
// Main initialization procedures for USANS reduction
// initializes globals and oflders
// draws the main panel for user interaction
// action procedures for the USANS_Panel
//
//
//
// 09 NOV 04 vers 1.1
// - updated dOmega and dQv
// - write out dQv to 6-column data sets for analysis compatibility
//
//
//********************

Menu "USANS"
	"USANS Reduction Panel",ShowUSANSPanel()
	"Build USANS Notebook"
	"Desmear USANS Data",Desmear()
	"-"
	"Load USANS Data",A_LoadOneDData()
	"Convert to 6 Columns",Convert3ColTo6Col()
	"-"
	"Feedback or Bug Report",U_OpenTracTicketPage("")
	"Check for Updates",CheckForLatestVersion()
End

// Bring the USANS_Panel to the front
// ALWAYS initializes the folders and variables
// then draws the panel if necessary
//
Proc ShowUSANSPanel()
	//version number
	Variable/G root:USANS_RED_VERSION=2.21			//distribution as of Jan 2007
	
	Init_MainUSANS()
	DoWindow/F USANS_Panel
	if(V_Flag==0)
		USANS_Panel()
	Endif
End

// initializes the folders and globals for use with the USANS_Panel
// waves for the listboxes must exist before the panel is drawn
// "dummy" values for the COR_Graph are set here
// instrumental constants are set here as well
//
Proc Init_MainUSANS()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:USANS
	NewDataFolder/O root:Packages:NIST:USANS:Globals
	NewDataFolder/O/S root:Packages:NIST:USANS:Globals:MainPanel
	
	String/G root:Packages:NIST:USANS:Globals:gUSANSFolder  = "root:Packages:NIST:USANS"
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	//NB This is also hardcoded a bit further down - search for "WHY WHY WHY" AJJ Sept 08
	
	Make/O/T/N=1 fileWave,samWave,empWave,curWave //Added curWave Sept 06 A. Jackson
	fileWave=""
	samWave=""
	empWave=""
	curWave="" //Added Sept 06 A. Jackson
	//Wave for handling Current Data AJJ Sept 06
	Make/O/N=1 SAMisCurrent,EMPisCurrent
	SAMisCurrent = 0
	EMPisCurrent = 0
	Make/O/T/N=5 statusWave=""
	Make/O/B/U/N=1 selFileW
	Make/O/B/U/N=1 cselFileW
	//for the graph control bar
	Variable/G gTransWide = 1
	Variable/G gTransRock = 1
	Variable/G gEmpCts = 0.76			//default values as of 15 DEC 05 J. Barker
	Variable/G gBkgCts = 0.62			//default values as of 15 DEC 05 J. Barker
	Variable/G gThick = 0.1
	Variable/G gTypeCheck=1
	Variable/G gTransRatio=1
	//Text filter for data files AJJ Sept 06
	String/G FilterStr
	Variable/G gUseCurrentData = 0
	
	SetDataFolder root:
	
	NewDataFolder/O $(USANSFolder+":RAW")
	NewDataFolder/O $(USANSFolder+":SAM")
	NewDataFolder/O $(USANSFolder+":COR")
	NewDataFolder/O $(USANSFolder+":EMP")
	NewDataFolder/O $(USANSFolder+":BKG")
	NewDataFolder/O $(USANSFolder+":SWAP")
	NewDataFolder/O $(USANSFolder+":Graph")
	
	//dummy waves for bkg and emp levels
	Make/O $(USANSFolder+":EMP:empLevel"),$(USANSFolder+":BKG:bkgLevel")
	//WHY WHY WHY?????
	//Explicit dependency
	root:Packages:NIST:USANS:EMP:empLevel := root:Packages:NIST:USANS:Globals:MainPanel:gEmpCts //dependency to connect to SetVariable in panel
	root:Packages:NIST:USANS:BKG:bkgLevel := root:Packages:NIST:USANS:Globals:MainPanel:gBkgCts

	
	//INSTRUMENTAL CONSTANTS 
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_H = 3.9e-6		//Darwin FWHM	(pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_V = 0.014		//Vertical divergence	(pre- NOV 2004)
	//Variable/G  root:Globals:MainPanel:gDomega = 2.7e-7		//Solid angle of detector (pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDomega = 7.1e-7		//Solid angle of detector (NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDefaultMCR= 1e6		//factor for normalization
	
	//Variable/G  root:Globals:MainPanel:gDQv = 0.037		//divergence, in terms of Q (1/A) (pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDQv = 0.117		//divergence, in terms of Q (1/A)  (NOV 2004)

	

End

//draws the USANS_Panel, the main control panel for the macros
//

Window USANS_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(600,44,1015,493)/K=1 as "USANS_Panel"
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1
	DrawText 12,53,"Data Files"
	SetDrawEnv fstyle= 1
	DrawText 157,192,"Empty Scans"
	SetDrawEnv fstyle= 1
	DrawText 154,54,"Sample Scans"
	DrawLine 6,337,398,337
	DrawLine 5,33,393,33
	SetDrawEnv fstyle= 1
	DrawText 140,357,"Raw Data Header"
	SetDrawEnv fstyle= 1
	DrawText 293,55,"Current Data"
	ListBox fileLB,pos={5,55},size={110,230},proc=FileListBoxProc
	ListBox fileLB,listWave=root:Packages:NIST:USANS:Globals:MainPanel:fileWave
	ListBox fileLB,selWave=root:Packages:NIST:USANS:Globals:MainPanel:selFileW,mode= 4
	ListBox samLB,pos={149,55},size={110,90},listWave=root:Packages:NIST:USANS:Globals:MainPanel:samWave
	ListBox samLB,mode= 1,selRow= -1
	Button ClearSamButton,pos={224,148},size={35,21},proc=ClearButtonProc,title="Clr"
	Button ClearSamButton,help={"Clears the list of sample scans"}
	Button ClearEmpButton,pos={227,286},size={35,20},proc=ClearButtonProc,title="Clr"
	Button ClearEmpButton,help={"Clears the list of empty scans"}
	Button RefreshButton,pos={9,310},size={104,20},proc=RefreshListButtonProc,title="Refresh"
	Button RefreshButton,help={"Refreshes the list of raw ICP data files"}
	Button DelSamButton,pos={186,148},size={35,20},proc=DelSamButtonProc,title="Del"
	Button DelSamButton,help={"Deletes the selected file(s) from the list of sample scans"}
	Button DelEmpButton,pos={190,286},size={35,20},proc=DelEmpButtonProc,title="Del"
	Button DelEmpButton,help={"Deletes the selected file(s) from the list of empty scans"}
	ListBox empLB,pos={151,194},size={110,90}
	ListBox empLB,listWave=root:Packages:NIST:USANS:Globals:MainPanel:empWave,mode= 1,selRow= 0
	Button toSamList,pos={118,55},size={25,90},proc=toSamListButtonProc,title="S->"
	Button toSamList,help={"Adds the selected file(s) to the list of sample scans"}
	Button toEmpList,pos={120,195},size={25,90},proc=toEmptyListButtonProc,title="E->"
	Button toEmpList,help={"Adds the selected file(s) to the list of empty (cell) scans"}
	ListBox StatusLB,pos={11,358},size={386,77}
	ListBox StatusLB,listWave=root:Packages:NIST:USANS:Globals:MainPanel:statusWave
	Button pickPathButton,pos={6,8},size={80,20},proc=PickBT5PathButton,title="DataPath..."
	Button pickPathButton,help={"Select the data folder where the raw ICP data files are located"}
	Button PlotSelectedSAMButton,pos={148,148},size={35,20},proc=PlotSelectedSAMButtonProc,title="Plot"
	Button PlotSelectedSAMButton,help={"Plot the selected sample scattering files in the COR_Graph"}
	Button PlotSelectedEMPButton,pos={152,286},size={35,20},proc=PlotSelectedEMPButtonProc,title="Plot"
	Button PlotSelectedEMPButton,help={"Plot the selected empty cell scattering files in the COR_Graph"}
	Button pickSavePathButton,pos={97,8},size={80,20},proc=PickSaveButtonProc,title="SavePath..."
	Button pickSavePathButton,help={"Select the data folder where data is to be saved to disk"}
	Button USANSHelpButton,pos={341,6},size={50,20},proc=USANSHelpButtonProc,title="Help"
	Button USANSHelpButton,help={"Show the USANS reduction help file"}
	Button RefreshCurrent,pos={298,310},size={95,20},proc=RefreshCurrentButtonProc,title="Refresh",disable=2
	Button RefreshCurrent,help={"Updates data files on Charlotte and gets current data file name"}
	Button AddCurToSAM,pos={264,55},size={25,90},proc=CurtoSamListButtonProc,title="<-S",disable=2
	Button AddCurToSAM,help={"Adds the current data file to the list of sample scans"}
	Button AddCurToEMP,pos={265,194},size={25,90},proc=CurtoEmptyListButtonProc,title="<-E",disable=2
	Button AddCurToEMP,help={"Adds the current data file to the list of empty scans"}
	ListBox CurFileBox,pos={295,55},size={100,230},proc=FileListBoxProc,disable=1
	ListBox CurFileBox,listWave=root:Packages:NIST:USANS:Globals:MainPanel:curWave,mode=1
	SetVariable FilterSetVar,pos={8,289},size={106,18},title="Filter",fSize=12
	SetVariable FilterSetVar,value= root:Packages:NIST:USANS:Globals:MainPanel:FilterStr
	CheckBox UseCurrentData,pos={298,290},size={10,10},proc=UseCurrentDataProc,title="Enable Current Data"
	CheckBox UseCurrentData,value=0
	Button USANSFeedback,pos={220,6},size={100,20},proc=U_OpenTracTicketPage,title="Feedback"
	
EndMacro



//draws a simple graph of the monitor counts, transmission counts, and detector counts
// plots the selected raw data file when "plot raw" is selected from the USANS_Panel
//
Proc GraphRawData()
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	SetDataFolder $(USANSFolder+":RAW:")
	//String textStr = StringForRawGraph()
	//textStr=StringByKey("FILE",textStr,":",";")+" MONRATE:"+num2str(mean(MonCts)/NumberByKey("TIMEPT",textStr,":",";"))
	Display /W=(600,525,1015,850)/L=left1/B=bottom1 /K=1 DetCts vs Angle as "Raw Data"
	ModifyGraph margin(top)=50
	//Display /W=(600,525,1015,850) /K=1 DetCts vs Angle as "Raw Data"
	DoWindow/C RawDataWin
	//AppendToGraph/L=left1 /B=bottom1 DetCts vs Angle
	AppendToGraph/L=left2/B=bottom1 TransCts vs Angle
	AppendToGraph/L=left3/B=bottom1 MonCts vs Angle
	SetAxis/A/N=2 left1
	SetAxis/A/N=2 left2
	SetAxis/A/N=2 left3
	ModifyGraph mode=4, marker=19
	ModifyGraph rgb(TransCts)=(1,4,52428),rgb(MonCts)=(1,39321,19939)
	ModifyGraph msize=1,grid=1,mirror=2,standoff=1,lblPos=50,tickUnit=1,notation=1,freePos={0.1,kwFraction}
	ModifyGraph nticks(left2)=2
	ModifyGraph nticks(left3)=2
	ModifyGraph mirror(bottom1)=0
	ModifyGraph axisEnab(left1)={0.1,0.5},gridEnab(left1)={0.1,1}
	ModifyGraph axisEnab(left2)={0.57,0.77},gridEnab(left2)={0.1,1}
	ModifyGraph axisEnab(left3)={0.8,1},gridEnab={0.1,1}
	ModifyGraph axisEnab(bottom1)={0.1,1},gridEnab(bottom1)={0.1,1}
	ErrorBars/T=0 DetCts Y,wave=(ErrDetCts,ErrDetCts)
	TextBox/F=0/E=2/A=MB/Y=2/N=text1 "Angle"
	TextBox/F=0/O=90/E=2/A=LC/X=2/N=text2 "Counts"
	//TextBox/N=text1/A=RC/X=0.50/Y=-2 textStr
	//Label bottom1 "Angle (degrees)"
	Label left1 " "
	Label left2 " "
	Label left3 " "
	TitleForRawGraph()
	SetDataFolder fldrSav
End

// plots the selected EMP files onto the COR_Graph 
// Does the following:
// - loads raw data
// - normalizes counts to time and 1E6 monitor counts
// sorts by angle
// finds zero angle (and peak height)
// converts to q-values
// finds T wide
// updates the graph
//
Function PlotSelectedEMPButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//get selected files from listbox (everything)
	//use the listBox wave directly
	Wave/T listW=$(USANSFolder+":Globals:MainPanel:empWave")
	//Wave for indication of current data set AJJ Sept 2006
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")
	Variable ii,num=numpnts(listW)
	String fname="",fpath="",curPathStr=""
	PathInfo bt5PathName
	fpath = S_Path
	PathInfo bt5CurPathName
	curPathStr = S_Path
		
	if(cmpstr("",listW[0])==0)
		return(0)		//null item in 1st position, exit
	Endif
	
	//load, normalize, and append
	//loop over the number of items in the list
	for(ii=0;ii<num;ii+=1)
		
		//Check to see if file is current data set AJJ Sept 06
		if (isCurrent[ii] ==  1)
			fname = curPathStr + listw[ii]
		else 
			fname = fpath + listw[ii]
		endif

		
		LoadBT5File(fname,"SWAP")	//overwrite what's in the SWAP folder
		Convert2Countrate("SWAP")
		if(ii==0)	//first time, overwrite
			NewDataWaves("SWAP","EMP")
		else		//append to waves in "EMP"
			AppendDataWaves("SWAP","EMP")
		endif
	endfor
	//sort after all loaded
	DoAngleSort("EMP")
	
	//find the peak and convert to Q-values
	Variable zeroAngle = FindZeroAngle("EMP")
	if(zeroAngle == -9999)
		DoAlert 0,"Couldn't find a peak - using zero as zero angle"
		zeroAngle = 0
	Endif
	ConvertAngle2Qvals("EMP",zeroAngle)
	
	//find the Trans Cts for T_Wide
	FindTWideCts("EMP")
	
	//copy the data to plot to the root:Graph directory, and give clear names
	if(WaveExists($(USANSFolder+":EMP:Qvals")))
		Duplicate/O $(USANSFolder+":EMP:Qvals"),$(USANSFolder+":Graph:Qvals_EMP")
	Endif
	Duplicate/O $(USANSFolder+":EMP:Angle"),$(USANSFolder+":Graph:Angle_EMP")
	Duplicate/O $(USANSFolder+":EMP:DetCts"),$(USANSFolder+":Graph:DetCts_EMP")
	Duplicate/O $(USANSFolder+":EMP:ErrDetCts"),$(USANSFolder+":Graph:ErrDetCts_EMP")
	
	//now plot the data (or just bring the graph to the front)
	DoCORGraph()
End

// plots the selected SAM files onto the COR_Graph 
// Does the following:
// - loads raw data
// - normalizes counts to time and 1E6 monitor counts
// sorts by angle
// finds zero angle (and peak height)
// converts to q-values
// finds T wide
// updates the graph
//
Function PlotSelectedSAMButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//get selected files from listbox (everything)
	//use the listBox wave directly
	Wave/T listW=$(USANSFolder+":Globals:MainPanel:samWave")
	//Wave for indication of current data set AJJ Sept 2006
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")
	Variable ii,num=numpnts(listW)
	String fname="",fpath="",curPathStr=""
	PathInfo bt5PathName
	fpath = S_Path
	PathInfo bt5CurPathName
	curPathStr = S_Path
	
	print fpath
	
	if(cmpstr("",listW[0])==0)
		return(0)		//null item in 1st position, exit
	Endif
	
	//load, normalize, and append
	//loop over the number of items in the list
	for(ii=0;ii<num;ii+=1)
		fname = fpath + listw[ii]
		
		//Check to see if file is current data set AJJ Sept 06
		if (isCurrent[ii] ==  1)
			fname = curPathStr + listw[ii]
		else 
			fname = fpath + listw[ii]
		endif
				
		LoadBT5File(fname,"SWAP")	//overwrite what's in the SWAP folder
		Convert2Countrate("SWAP")
		if(ii==0)	//first time, overwrite
			NewDataWaves("SWAP","SAM")
		else		//append to waves in "SAM"
			AppendDataWaves("SWAP","SAM")
		endif
	endfor
	//sort after all loaded
	DoAngleSort("SAM")
	
	//find the peak and convert to Q-values
	Variable zeroAngle = FindZeroAngle("SAM")
	if(zeroAngle == -9999)
		DoAlert 0,"Couldn't find a peak - using zero as zero angle"
		zeroAngle = 0
	Endif
	ConvertAngle2Qvals("SAM",zeroAngle)
	//find the Trans Cts for T_Wide
	FindTWideCts("SAM")
	//
	//copy the data to plot to the root:Graph directory, and give clear names
	if(WaveExists($(USANSFolder+":SAM:Qvals")))
		Duplicate/O $(USANSFolder+":SAM:Qvals"),$(USANSFolder+":Graph:Qvals_SAM")
	Endif
	Duplicate/O $(USANSFolder+":SAM:Angle"),$(USANSFolder+":Graph:Angle_SAM")
	Duplicate/O $(USANSFolder+":SAM:DetCts"),$(USANSFolder+":Graph:DetCts_SAM")
	Duplicate/O $(USANSFolder+":SAM:ErrDetCts"),$(USANSFolder+":Graph:ErrDetCts_SAM")
	
	//now plot the data (or just bring the graph to the front)
	DoCORGraph()
End

//sort the data in the "type"folder, based on angle
//carry along all associated waves
//
Function DoAngleSort(type)
	String type
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Wave angle = $(USANSFolder+":"+Type+":Angle")
	Wave detCts = $(USANSFolder+":"+Type+":DetCts")
	Wave ErrdetCts = $(USANSFolder+":"+Type+":ErrDetCts")
	Wave MonCts = $(USANSFolder+":"+Type+":MonCts")
	Wave TransCts = $(USANSFolder+":"+Type+":TransCts")
	
	Sort Angle DetCts,ErrDetCts,MonCts,TransCts,Angle
	return(0)
End

// converts to countrate per 1E6 monitor counts (default value)
// by dividing by the counting time (reported in header in seconds per point)
// and the globally defined monitor count
//
// works on data in "type" folder
//
// note that trans detector counts are NOT normalized to 1E6 mon cts (not necessary)
//
Function Convert2Countrate(type)
	String type
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	String noteStr = note($(USANSFolder+":"+Type+":DetCts"))
	Variable ctTime
	ctTime = NumberByKey("TIMEPT",noteStr,":",";")
	print ctTime
	//normalize by counting time
	Wave detCts = $(USANSFolder+":"+Type+":DetCts")
	Wave ErrdetCts = $(USANSFolder+":"+Type+":ErrDetCts")
	Wave MonCts = $(USANSFolder+":"+Type+":MonCts")
	Wave TransCts = $(USANSFolder+":"+Type+":TransCts")
	
	detCts /= ctTime
	ErrDetCts /= ctTime
	MonCts /= ctTime
	TransCts /= ctTime
	
	//normalize to monitor countrate [=] counts/monitor
	//trans countrate does not need to be normalized
	NVAR defaultMCR=$(USANSFolder+":Globals:MainPanel:gDefaultMCR") 
	DetCts /= monCts/defaultMCR
	ErrDetCts /= MonCts/defaultMCR
	
	//adjust the note (now on basis of 1 second)
	ctTime = 1
	noteStr = ReplaceNumberByKey("TIMEPT",noteStr,ctTime,":",";")
	Note/K detCts
	Note detCts,noteStr
	
	return(0)
End


// copies data from one folder to another
//
// used for the first set, simply obliterate the old waves in the folder
//
Function NewDataWaves(fromType,toType)
	String fromType,toType
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Duplicate/O $(USANSFolder+":"+fromType+":Angle"),$(USANSFolder+":"+toType+":Angle")
	Duplicate/O $(USANSFolder+":"+fromType+":DetCts"),$(USANSFolder+":"+toType+":DetCts")
	Duplicate/O $(USANSFolder+":"+fromType+":ErrDetCts"),$(USANSFolder+":"+toType+":ErrDetCts")
	Duplicate/O $(USANSFolder+":"+fromType+":MonCts"),$(USANSFolder+":"+toType+":MonCts")
	Duplicate/O $(USANSFolder+":"+fromType+":TransCts"),$(USANSFolder+":"+toType+":TransCts")
	
	//check for qvals wave, move if it's there
	if(WaveExists($(USANSFolder+":"+fromType+":Qvals")))
		Duplicate/O $(USANSFolder+":"+fromType+":Qvals"),$(USANSFolder+":"+toType+":Qvals")
	Endif
	
End

//to add additional data to a folder, need to concatenate the data in the waves
//and need to update the wave note associated with "DetCts" to include the additional file
//
Function AppendDataWaves(fromType,toType)
	String fromType,toType

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	String fromNote="",toNote="",newNote="",fromfile="",toFile=""
	
	
	ConcatenateData( (USANSFolder+":"+toType+":Angle"),(USANSFolder+":"+fromType+":Angle") ) //appends "from" at the end of "to"
	ConcatenateData( (USANSFolder+":"+toType+":DetCts"),(USANSFolder+":"+fromType+":DetCts") )
	ConcatenateData( (USANSFolder+":"+toType+":ErrDetCts"),(USANSFolder+":"+fromType+":ErrDetCts") )
	ConcatenateData( (USANSFolder+":"+toType+":MonCts"),(USANSFolder+":"+fromType+":MonCts") )
	ConcatenateData( (USANSFolder+":"+toType+":TransCts"),(USANSFolder+":"+fromType+":TransCts") )
	

	//adjust the wavenote, to account for the new dataset
	fromNote = note($(USANSFolder+":"+fromType+":DetCts"))
	fromFile = StringByKey("FILE",fromNote,":",";")
	toNote = note($(USANSFolder+":"+toType+":DetCts"))
	toFile = StringByKey("FILE",toNote,":",";")
	toFile += "," + fromfile
	toNote = ReplaceStringByKey("FILE",toNote,toFile,":",";")
	Note/K $(USANSFolder+":"+toType+":DetCts")
	Note $(USANSFolder+":"+toType+":DetCts"),toNote
	
	Return(0)
End

// action procedure to select the raw data path where the bt5 files are located
//
Function PickBT5PathButton(PathButton) : ButtonControl
	String PathButton
	
	//Print "DataPathButton Proc"
	Variable err = PickBT5Path()		//=1 if error

End

//pick the data folder to save the data to - in general must be a local disk, not the ICP database....
//
Function PickSaveButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	NewPath/O/M="SAVE data to the selected folder" savePathName
	PathInfo/S savePathName
	String dum = S_path
	if (V_flag == 0)
		return(1)
	else
		return(0)		//no error
	endif
End

// Show the help file, don't necessarily keep it with the experiment (/K=1)
Function USANSHelpButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DisplayHelpTopic/Z/K=1 "USANS Data Reduction"
	if(V_flag !=0)
		DoAlert 0,"The USANS Data Reduction Help file could not be found"
	endif
	return(0)
End

//prompts user to choose the local folder that contains the BT5 Data
//only one folder can be used, and its path is bt5PathName (and is a NAME, not a string)
//this will overwrite the path selection
//returns 1 if no path selected as error condition
Function PickBT5Path()
	
	NVAR isChecked = root:Packages:NIST:USANS:Globals:MainPanel:gUseCurrentData
	
	//set the global string to the selected pathname
	NewPath/O/M="pick the BT5 data folder" bt5PathName
	PathInfo/S bt5PathName
	String dum = S_path
	if (V_flag == 0)
		//Path does not exist
		return(1)
	else
		if (isChecked == 1)
			NewPath/O/M="Select Current Data" bt5CurPathName, getCurrentPath(S_Path)
			return(0)		//no error
		Endif
	endif
End

//action procedure to load and plot a raw data file
// loads the data based on selected file and bt5pathname
// draws a new graph if necessary
// otherwise just updates the data
//
Function PlotRawButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	String fname=""
	
	if (cmpstr(ctrlName,"FileLB") == 0)
		//Print "PlotRaw Button"
		//take the selection, and simply plot the counts vs. angle - don't save the data anyplace special
		//get the selected wave
		Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:fileWave")
		Wave sel=$(USANSFolder+":Globals:MainPanel:selFileW")
		Variable ii=0,num=numpnts(sel),err

		
		PathInfo bt5PathName
		fname = S_Path
		do
			if(sel[ii] == 1)
				fname+=filewave[ii]
				break
			endif
			ii+=1
		while(ii<num)
	elseif (cmpstr(ctrlName,"CurFileBox" )== 0)
		Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:curWave")
		PathInfo bt5CurPathName
		fname = S_Path
		fname+=filewave[0]
	endif
	//Print fname
	err = LoadBT5File(fname,"RAW")
	if(err)
		return(err)
	endif
	//if the "Raw Data" Graph exists, do nothing - else draw it
	//DoWindow/F RawDataWin
	if(WinType("RawDataWin")!=1)
		Execute "GraphRawData()"
	else
		//just update the textbox
		//String textStr=StringForRawGraph()
		//TextBox/W=RawDataWin/C/N=text1/A=RC/X=0.50/Y=-2 textStr
		//TextBox/W=RawDataWin/C/E=2/A=MT/X=0/Y=0/N=text0 textStr
		TitleForRawGraph()
	Endif
	//bring the panel back to the front
	DoWindow/F USANS_Panel
End

// action procedure for the raw data listbox
// responds to selection or (shift)selection events
// by acting if the "status" button was pressed
//(note that the status button is obsolete and not drawn on the USANS_Panel, but 
// I kept the nomenclature)
//
Function FileListBoxProc(ctrlName,row,col,event)
	String ctrlName
	Variable row,col,event
	
	if (cmpstr(ctrlName, "fileLB") == 0)
		//event == 4 is a selection
		//event == 5 is a selection + shift key
		if( (event==4) || (event==5) )
			StatusButtonProc(ctrlName)		//act as if status button was pressed
			PlotRawButtonProc(ctrlName)					//automatically plots the raw data
		Endif
		return(0)
	elseif (cmpstr(ctrlName,"CurFileBox") == 0)
		//print "Selected current data"
		if  (event == 4)
			StatusButtonProc(ctrlName)
			PlotRawButtonProc(ctrlName)
		endif
		return(0)
	endif
	return(1)
End

// displays the status of the selected file in the raw data file list box
// - spits the information out to a second listbox
// - called automatically as an action when there is a selection in the file listbox
// not used as a button procedure anymore
//
Function StatusButtonProc(ctrlName) 
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	String fname=""


	if(cmpstr(ctrlName,"fileLB")==0)
		//Print "Status Button"	
		//display the (first) selected wave
		Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:fileWave")
		Wave sel=$(USANSFolder+":Globals:MainPanel:selFileW")
		Variable ii=0,num=numpnts(sel)
		
		PathInfo bt5PathName
		fname = S_Path
		do
			if(sel[ii] == 1)
				fname+=filewave[ii]
				break
			endif
			ii+=1
		while(ii<num)
	elseif(cmpstr(ctrlName,"CurFileBox")==0)
		Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:curWave")
		PathInfo bt5CurPathName
		fname = S_Path
		fname+=filewave[0]
	endif		
	//Print fname
	ReadBT5Header(fname)
End

// copies the selected files from the raw file list box to the sam file listbox
//
// makes sure that any null items are removed from the wave attached to the listbox
//
Function toSamListButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//Print "toSamList button"
	Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:fileWave")
	Wave/T samWave=$(USANSFolder+":Globals:MainPanel:samWave")
	Wave sel=$(USANSFolder+":Globals:MainPanel:selFileW")
	//Wave to indicate Current status
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")

	
	Variable num=numpnts(sel),ii=0
	variable lastPt=numpnts(samWave)
	do
		if(sel[ii] == 1)
			InsertPoints lastPt,1, samWave
			samWave[lastPt]=filewave[ii]
			InsertPoints lastPt, 1, isCurrent
			isCurrent[lastPt] = 0
			lastPt +=1
		endif
		ii+=1
	while(ii<num)
	
	//clean out any (null) elements
	num=numpnts(samwave)
	for(ii=0;ii<num;ii+=1)
		if(cmpstr(samWave[ii],"") ==0)
			DeletePoints ii,1,samWave
			DeletePoints ii,1,isCurrent
			num -= 1
		Endif
	Endfor
	
	return(0)
End

// copies the selected files from the raw file list box to the sam file listbox
//
// makes sure that any null items are removed from the wave attached to the listbox
//
Function toEmptyListButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//Print "toEmptyList button"
	Wave/T fileWave=$(USANSFolder+":Globals:MainPanel:fileWave")
	Wave/T empWave=$(USANSFolder+":Globals:MainPanel:empWave")
	Wave sel=$(USANSFolder+":Globals:MainPanel:selFileW")
	//Wave to indicate Current status
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")


	
	Variable num=numpnts(sel),ii=0
	variable lastPt=numpnts(empWave)
	do
		if(sel[ii] == 1)
			InsertPoints lastPt,1, empWave
			empWave[lastPt]=filewave[ii]
			InsertPoints lastPt, 1, isCurrent
			isCurrent[lastPt] = 0
			lastPt +=1
		endif
		ii+=1
	while(ii<num)
	
	//clean out any (null) elements
	num=numpnts(empwave)
	for(ii=0;ii<num;ii+=1)
		if(cmpstr(empWave[ii],"") ==0)
			DeletePoints ii,1,empWave
			DeletePoints ii,1,isCurrent
			num -= 1
		Endif
	Endfor
	
	return(0)
End

//deletes the selected file from the sam list
// multiple selections are not allowed
// the cor_graph is not updated
//
Function DelSamButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	ControlInfo SamLB
	Variable selRow=V_Value
	Wave lw=$(S_DataFolder + S_Value)
	DeletePoints selRow,1,lw	
	//Clear out current flag AJJ Sept O6
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")
	DeletePoints selRow, 1, isCurrent	
End

//deletes the selected file from the emp list
// multiple selections are not allowed
// the cor_graph is not updated
//
Function DelEmpButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	ControlInfo EmpLB
	Variable selRow=V_Value
	Wave lw=$(S_DataFolder + S_Value)
	DeletePoints selRow,1,lw
	//Clear out current flag AJJ Sept O6
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")
	DeletePoints selRow, 1, isCurrent	
End

//refreshes the file list presented in the raw data file listbox
//bt5PathName is hard-wired in, will prompt if none exists
// reads directly from disk
//
// EXCLUDES all files that do not match "*.bt5*" (not case sensitive)
//
// sorts the list to alphabetical order
//
Function RefreshListButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SVAR FilterStr = $(USANSFolder+":Globals:MainPanel:FilterStr")
	print FilterStr
	String filter
	
	//check for path and force user to pick a path
	do
		PathInfo bt5PathName
		if(V_Flag)
			break
		Endif
		PickBT5Path()
	while(V_Flag==0)
	
	//Get the filter and determine the match string required AJJ Sept06
	if (stringmatch(FilterStr,"!"))
		filter = FilterStr+"*.bt5*"
	else
		filter = "*.bt5*"
	endif
	
	//get all the files, then trim the list
	String list=IndexedFile(bt5PathName,-1,"????")
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list  ,";")
		
		if( stringmatch(item,filter) )		//ONLY keep files that match the filter + *.bt5 AJJ Sept 06
			newlist += item + ";"
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)	//get them in order
	num=ItemsInList(newlist,";")
	Wave/T fileWave = $(USANSFolder+":Globals:MainPanel:fileWave")
	Wave selFileW = $(USANSFolder+":Globals:MainPanel:selFileW")
	Redimension/N=(num) fileWave
	Redimension/N=(num) selFileW
	fileWave=""
	selFileW = 0
	fileWave = StringFromList(p,newlist,";")	//  ! quick and easy assignment of the list
	Sort filewave,filewave
	
End

//clears either the sample or empty scan Lists...
//Also clears the data folders and the COR_Graph
//
// very useful to make sure that the data is really what you think it is on the cor_graph
//
Function ClearButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
		
	SetDataFolder $(USANSFolder+":Globals:MainPanel")
	strswitch(ctrlName)
		case "ClearSamButton":
			Make/O/T/N=1 samWave
			samWave=""
			//Clear out current flags AJJ Sept O6
			Make/O/N=1 SAMisCurrent,EMPisCurrent
			SAMisCurrent = 0
			EMPisCurrent = 0
			//clear the graph, then the data folders as well
			CleanOutGraph("SAM")
			CleanOutFolder("SAM")
			CleanOutGraph("COR")
			CleanOutFolder("COR")
			break
		case "ClearEmpButton":
			Make/O/T/N=1 empWave
			empWave=""
			//Clear out current flags AJJ Sept O6
			Make/O/N=1 SAMisCurrent,EMPisCurrent
			SAMisCurrent = 0
			EMPisCurrent = 0
			//clear the graph, then the data folders as well
			CleanOutGraph("EMP")
			CleanOutFolder("EMP")
			CleanOutGraph("COR")
			CleanOutFolder("COR")
			break
	endswitch
	// uncheck the cursors
	UseCrsrCheckProc("",0)
	
	DoWindow/F USANS_Panel		//focus back to MainPanel
	SetDataFolder root:
End

//reads header information, to display on main panel only
// called from the action procedure of the raw data listbox
//
// puts the pertinent information in the "statusWave" that is associated 
//with the status listbox (which will automatically update)
//
Function ReadBT5Header(fname)
	String fname
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Variable err=0,refNum
	Wave/T statusWave=$(USANSFolder+":Globals:MainPanel:statusWave")
	
	Open/R refNum as fname		//READ-ONLY.......if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif
	//read in the ASCII data line-by-line
	Variable numLinesLoaded = 0,firstchar
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,ii,valuesRead
	String buffer ="",s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
	
	//parse the first line
	FReadLine refnum,buffer
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s",s1,s2,s3,s4,s5,s6,v1,v2,s7,v3,s8
	statusWave[0] = "FILE: "+s1
	statusWave[1] = "DATE: "+s2+" "+s3+" "+s4+" "+s5
	
	//v1 is the time per point (sec)
	//v2  is the monitor prefactor. Let's multiply the time by the prefactor. AJJ 5 March 07
	statusWave[2] = "TIME/PT: "+num2istr(v1*v2)+" sec"
	
	//skip the next line
	FReadLine refnum,buffer
	//the next line is the title, use it all except the last character - causes formatting oddities in listBox
	FReadLine refnum,buffer
	statusWave[3] = "TITLE: "+ buffer[0,strlen(buffer)-2]
	
	//skip the next 3 lines
	For(ii=0;ii<3;ii+=1)
		FReadLine refnum,buffer
	EndFor
	
	//parse the angular range from the next line
	FReadLine refnum,buffer
	sscanf buffer,"%g%g%g%g",v1,v2,v3,v4
	statusWave[4] = "RANGE: "+num2str(v2)+" to "+num2str(v4)+" step "+num2str(v3)
	
	Close refNum		// Close the file, read-only, so don't need to move to EOF first
	return err			// Zero signifies no error.	
End

// given a string that is the wavenote of the just-loaded raw data file
// pick out the file and time list items (and values) 
//and return a string that is to be used for the textbox in the graph of raw data
//
Function TitleForRawGraph()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	WAVE detCts=$(USANSFolder+":RAW:detCts")
	WAVE monCts = $(USANSFolder+":RAW:monCts")
	String str=note(detCts)
	
	String retStr="\\JC"
	retStr += StringByKey("FILE",str,":",";")+"\r"
	retStr += "Count Time: "+StringByKey("TIMEPT",str,":",";")
	retStr += " \tMonitor Rate: "+num2str(mean(monCts)/NumberByKey("TIMEPT",str,":",";"))+"\r"
	retStr += "\\s(DetCts) DetCts \\s(TransCts) TransCts \\s(MonCts) MonCts"
	
	TextBox/W=RawDataWin/C/E=2/A=MT/X=5/Y=0/N=text0 retStr
End


//concatenates datasets (full names are passed in as a string)
//tacks w2 onto the end of w1 (so keep w1)
//
// copied from a wavemetrics procedure (concatenatewaves?)
Function ConcatenateData(w1, w2)
	String w1, w2
	
	Variable numPoints1, numPoints2

	if (Exists(w1) == 0)
		Duplicate $w2, $w1
	else
		String wInfo=WaveInfo($w2, 0)
		numPoints1 = numpnts($w1)
		numPoints2 = numpnts($w2)
		Redimension/N=(numPoints1 + numPoints2) $w1
		Wave/D ww1=$w1
		Wave/D ww2=$w2
		ww1[numPoints1, ] = ww2[p-numPoints1]
	endif
End

//takes the given inputs, subtracts EMP and BKG from the SAM data
//the user must supply the correct sample thickness, BKGLevel, and EMPLevel for extrapolation
Function DoCorrectData()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	//constants
//	NVAR  thetaH = root:Globals:MainPanel:gTheta_H			//Darwin FWHM
//	NVAR  thetaV = root:Globals:MainPanel:gTheta_V			//Vertical divergence
	NVAR dOmega =  $(USANSFolder+":Globals:MainPanel:gDomega")			//Solid angle of detector
	NVAR defaultMCR = $(USANSFolder+":Globals:MainPanel:gDefaultMCR")
		
	//waves
	Wave iqSAM = $(USANSFolder+":SAM:DetCts")
	Wave errSAM = $(USANSFolder+":SAM:ErrDetCts")
	Wave qvalSAM = $(USANSFolder+":SAM:Qvals")
	Wave iqEMP = $(USANSFolder+":EMP:DetCts")
	Wave errEMP = $(USANSFolder+":EMP:ErrDetCts")
	Wave qvalEMP = $(USANSFolder+":EMP:Qvals")
	//BKG,EMP levels,trans,thick
	NVAR bkgLevel = $(USANSFolder+":Globals:MainPanel:gBkgCts")
	NVAR empLevel =  $(USANSFolder+":Globals:MainPanel:gEmpCts")
	NVAR Trock =  $(USANSFolder+":Globals:MainPanel:gTransRock")
	NVAR Twide =  $(USANSFolder+":Globals:MainPanel:gTransWide")
	NVAR thick =  $(USANSFolder+":Globals:MainPanel:gThick")
	//New waves in COR folder, same length as SAM data
	Duplicate/O iqSAM,$(USANSFolder+":COR:DetCts")
	Duplicate/O errSAM,$(USANSFolder+":COR:ErrDetCts")
	Duplicate/O qvalSAM,$(USANSFolder+":COR:Qvals")
	Wave iqCOR = $(USANSFolder+":COR:DetCts")
	Wave qvalCOR = $(USANSFolder+":COR:Qvals")
	Wave errCOR = $(USANSFolder+":COR:ErrDetCts")
	
	//correction done here
	//q-values of EMP must be interpolated to match SAM data
	//use the extrapolated value of EMP beyind its measured range
	Variable num=numpnts(iqSAM),ii,scale,tempI,temperr,maxq,wq
	maxq = qvalEMP[(numpnts(qvalEMP)-1)]		//maximum measure q-value for the empty
	
	for(ii=0;ii<num;ii+=1)
		wq = qvalSAM[ii]	//q-point of the sample
		if(wq<maxq)
			tempI = interp(wq,qvalEMP,iqEMP)
			temperr = interp(wq,qvalEMP,errEMP)
		else
			tempI = empLevel
			//temperr = sqrt(empLevel)
			temperr = 0		//JGB 5/31/01
		endif
		iqCOR[ii] = iqSAM[ii] - Trock*tempI - (1-Trock)*bkglevel
		errCOR[ii] = sqrt(errSAM[ii]^2 + Trock^2*temperr^2)		//Trock^2; JGB 5/31/01
	endfor
	
	String str=note(iqEMP)
	Variable pkHtEMP=NumberByKey("PEAKVAL", str,":",";") 
	//absolute scaling factor
	scale = 1/(Twide*thick*dOmega*pkHtEMP)
	iqCOR *= scale
	errCOR *= scale
	
	//copy to Graph directory to plot
	Duplicate/O $(USANSFolder+":COR:Qvals"),$(USANSFolder+":Graph:Qvals_COR")
	Duplicate/O $(USANSFolder+":COR:DetCts"),$(USANSFolder+":Graph:DetCts_COR")
	Duplicate/O $(USANSFolder+":COR:ErrDetCts"),$(USANSFolder+":Graph:ErrDetCts_COR")
	
	//now plot the data (or just bring the graph to the front)
	DoCORGraph()
	return(0)
End

//cleans out the specified data folder (type)
// and clears out the same-named data from the Graph folder
// kills what is not in use
//
Function CleanOutFolder(type)
	String type

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder	
	
	SetDataFolder $(USANSFolder+":"+type)
	Killwaves/Z DetCts,Qvals,ErrDetCts,Angle,MonCts,TransCts
	
	SetDataFolder $(USANSFolder+":Graph")
	KillWaves/Z $("DetCts_"+type),$("ErrDetCts_"+type),$("Qvals_"+type)
	
	SetDataFolder root:
End

// removes the selected datatype from the COR_Graph
//			
Function CleanOutGraph(type)
	String type
	
	DoWindow/F COR_Graph
	if(V_flag)
		RemoveFromGraph/W=COR_Graph/Z $("DetCts_"+type)
	endif
End

//Edits by AJJ, September 2006
//Add functions to get data from Current Folder

Function RefreshCurrentButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder	
	
	//Prod the web update page
	//This is a horrible kludge that doesn't really work as the 
	//webscript does not update the current run as of Sept 26 2006
	//Will get Nick M to look into it
	BrowseURL/Z "http://www-i.ncnr.nist.gov/icpdata/recent.php?action=1&instr=bt5"
	
	Print "Waiting 20s for update..."
	Sleep/S 20
	Print "Waited 20s, new file should be there."
	
	//check for path and force user to pick a path
	//assume that if bt5PathName has been assigned, so has bt5CurPathName
	do
		PathInfo bt5PathName
		if(V_Flag)
			break
		Endif
		PickBT5Path()
	while(V_Flag==0)
	
	PathInfo bt5CurPathName
	if(V_flag==0)
		NewPath/O/M="Select Current Data" bt5CurPathName, getCurrentPath(S_Path)
	endif
		
	//get all the files, then trim the list
	String list=IndexedFile(bt5CurPathName,-1,"????")
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list  ,";")
		if( stringmatch(item,"*.bt5*") )		//ONLY keep files with ".bt5" in the name (NOT case-sensitive) 
			newlist += item + ";"
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)	//get them in order
	num=ItemsInList(newlist,";")
	Wave/T curWave = $(USANSFolder+":Globals:MainPanel:curWave")
	Redimension/N=(num) curWave
	curWave=""
	curWave = StringFromList(p,newlist,";")	//  ! quick and easy assignment of the list
	Sort curwave,curwave
	
End

//Reduced version of toSamListButtonProc for putting current data into Sample data
Function CurtoSamListButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave/T curWave=$(USANSFolder+":Globals:MainPanel:curWave")
	Wave/T samWave=$(USANSFolder+":Globals:MainPanel:samWave")
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:SAMisCurrent")
	
	Variable num, ii = 0
	variable lastPt=numpnts(samWave)
	
	InsertPoints lastPt,1, samWave
	samWave[lastPt]=curwave[ii]
	InsertPoints lastPt, 1, isCurrent
	isCurrent[lastPt] = 1
	
	//clean out any (null) elements
	num = numpnts(samwave)
	for(ii=0;ii<num;ii+=1)
		if(cmpstr(samWave[ii],"") ==0)
			DeletePoints ii,1,samWave
			DeletePoints ii,1,isCurrent
			num -= 1
		Endif
	Endfor
	
	return(0)
End

//Reduced version of toEmptyListButtonProc for putting current data into Empty data
Function CurtoEmptyListButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave/T curWave=$(USANSFolder+":Globals:MainPanel:curWave")
	Wave/T empWave=$(USANSFolder+":Globals:MainPanel:empWave")
	Wave isCurrent = $(USANSFolder+":Globals:MainPanel:EMPisCurrent")
		
	Variable num, ii=0
	variable lastPt=numpnts(empWave)

	InsertPoints lastPt,1, empWave
	empWave[lastPt]=curwave[ii]
	InsertPoints lastPt, 1, isCurrent
	isCurrent[lastPt] = 1

	
	//clean out any (null) elements
	num=numpnts(empwave)
	for(ii=0;ii<num;ii+=1)
		if(cmpstr(empWave[ii],"") ==0)
			DeletePoints ii,1,empWave
			DeletePoints ii,1,isCurrent
			num -= 1
		Endif
	Endfor
	
	
	return(0)
End

Function UseCurrentDataProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	NVAR isChecked = $(USANSFolder+":Globals:MainPanel:gUseCurrentData")
	
	if (checked == 1)
		DoAlert 1, "Enabling Current Data requires access to the NCNR Network.\rDo you wish to continue?" 
		if(V_flag == 1)
			ModifyControl/Z CurFileBox, disable=0
			ModifyControl/Z AddCurToSAM, disable=0
			ModifyControl/Z AddCurToEMP, disable=0
			ModifyControl/Z RefreshCurrent,disable=0
			isChecked = 1
		endif
	else
		ModifyControl/Z CurFileBox, disable=1
		ModifyControl/Z AddCurToSAM, disable=2
		ModifyControl/Z AddCurToEMP, disable=2
		ModifyControl/Z RefreshCurrent,disable=2	
		isChecked = 0
	endif

End

//Function to get path for Current file
Function/S getCurrentPath(inPath)
	String inPath
	
	Variable pos=0,mpos = 0
	Variable i = 0,j = 0
	// The saga continues...
	// Originally used ParseFilePath - not in Igor 4
	// Switched to strsearch, but useful searching from end of string not in Igor 4
	// Now have ugly loops going through the string, but should work.

	for( i = 0;i<4; i+=1)	
		do
			pos = strsearch(inPath,":",j)
			if (pos != -1)
				mpos = pos
			endif
			j = pos+1
		while (pos !=-1)
		
		inPath = inPath[0,mpos -1]
		pos = 0
		mpos = 0
		j = 0
	endfor
	
	inPath = inPath + ":current:"

	return inPath
	
End

//
Function U_OpenTracTicketPage(ctrlName)
	String ctrlName
	DoAlert 1,"Your web browser will open to a page where you can submit your bug report or feature request. OK?"
	if(V_flag==1)
		BrowseURL "http://danse.chem.utk.edu/trac/newticket"
	endif
End