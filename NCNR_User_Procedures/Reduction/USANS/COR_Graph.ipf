#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.0

////////////////////////////
// 101001 Vers. 1
//
// procedures to plot the sma, emp, and cor data
// - user interaction is through control bar on COR_Graph
// - provides user with feedback about peak angle, transmissions
// - asks for information about BKG and EMP levels
// - asks for sample thickness
// - interactively selects range of data to save (and type)
// - dispatches to routines to determine transmissions and correct the data
// - dispatches to save routines
//
/////////////////////////////


//plot all that is available in the root:Graph folder
// no distinction as to what the status of the data really is
// "Clr" buttons on the USANS_Panel will clear the graph..
//
Function DoCORGraph()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	DoWindow/F COR_Graph
	if(V_flag==0)
		//draw the blank window and the control bar
		Display /W=(5,42,450,550) /K=1
		DoWindow/C COR_Graph
		ControlBar 150
		SetVariable gTransWide,pos={210,12},size={135,15},title="Trans - Wide",format="%5.4f"
		SetVariable gTransWide,help={"Average counts on transmssion detector at wide angles"}
		SetVariable gTransWide,limits={0,1,0.001},value= $(USANSFolder+":Globals:MainPanel:gTransWide")
		SetVariable gTransRock,pos={210,27},size={135,15},title="Trans - Rock",format="%5.4f"
		SetVariable gTransRock,help={"Transmission counts at the zero-angle peak"}
		SetVariable gTransRock,limits={0,1,0.001},value= $(USANSFolder+":Globals:MainPanel:gTransRock")
		SetVariable gEmpCts,pos={210,42},size={135,15},title="EMP Level",format="%7.4f"
		SetVariable gEmpCts,limits={-Inf,Inf,0.1},value= $(USANSFolder+":Globals:MainPanel:gEmpCts")
		SetVariable gEmpCts,help={"High q limit of empty cell scattering normalized to 1.0e6 monitor counts"}
		SetVariable gBkgCts,pos={210,57},size={135,15},title="BKG Level",format="%7.4f"
		SetVariable gBkgCts,limits={-Inf,Inf,0.1},value= $(USANSFolder+":Globals:MainPanel:gBkgCts")
		SetVariable gBkgCts,help={"Background scattering level normalized to 1.0e6 monitor counts"}
		SetVariable gThick,pos={210,72},size={135,15},title="SAM Thick(cm)",format="%5.4f"
		SetVariable gThick,help={"Thickness of the sample in centimeters"}
		SetVariable gThick,limits={0,5,0.01},value= $(USANSFolder+":Globals:MainPanel:gThick")
		Button UpdateButton,pos={115,19},size={88,20},proc=UpdateButtonProc,title="Update Trans"
		Button UpdateButton,help={"Updates both the wide and rocking transmission values based on the raw data files"}
		Button CorrectButton,pos={115,53},size={88,20},proc=CorrectButtonProc,title="Correct Data"
		Button CorrectButton,help={"Corrects the sample data by subtracting empty cell and backgrond scattering"}
		Button SaveDataButton,pos={355,3},size={85,20},proc=SaveButtonProc,title="Save Data..."
		Button SaveDataButton,help={"Saves the selected data type to disk in ASCII format"}
		CheckBox useCrsrCheck,pos={360,27},size={119,14},proc=UseCrsrCheckProc,title="Use Cursors?"
		CheckBox useCrsrCheck,value= 0
		CheckBox useCrsrCheck,help={"Adds cursors to the datset to select the range of data points to save"}
		CheckBox CORCheck,pos={380,44},size={40,14},title="COR",value=1,proc=TypeToggleCheckProc,mode=1
		CheckBox CORCheck,help={"Selects COR data as the saved type"}
		CheckBox SAMCheck,pos={380,60},size={40,14},title="SAM",value=0,proc=TypeToggleCheckProc,mode=1
		CheckBox SAMCheck,help={"Selects SAM data s the saved type"}
		CheckBox EMPCheck,pos={380,76},size={40,14},title="EMP",value= 0,proc=TypeToggleCheckProc,mode=1
		CheckBox EMPCheck,help={"Selects EMP data as the saved type"}
		Button qpkButton,pos={12,61},size={90,20},proc=QpkButtonProc,title="Change Qpk"
		Button qpkButton,help={"Use this to override the automatically determined peak locations in SAM or EMP datasets"}
		ValDisplay valdispSAM,pos={10,15},size={100,14},title="Qpk SAM",format="%1.3f"
		ValDisplay valdispSAM,limits={0,0,0},barmisc={0,1000},value=QpkFromNote("SAM")
		ValDisplay valdispSAM,help={"Displays the peak angle the raw SAM data, determined automatically"}
		ValDisplay valdispEMP,pos={10,36},size={100,14},title="Qpk EMP",format="%1.3f"
		ValDisplay valdispEMP,limits={0,0,0},barmisc={0,1000},value=QpkFromNote("EMP")
		ValDisplay valdispEMP,help={"Displays the peak angle the raw EMP data, determined automatically"}
	
		CheckBox check0 title="Log X-axis",proc=LogLinToggleCheckProc
		CheckBox check0 pos={12,100},value=0,mode=0
		SetVariable setvar0,pos={210,100},size={120,20},title="Trock/Twide",format="%5.4f"
		SetVariable setVar0,help={"fraction of unscattered neutrons"}
		SetVariable setVar0,limits={0,2,0},value= $(USANSFolder+":Globals:MainPanel:gTransRatio")
		
		Legend
	Endif
	// add each data type to the graph, if possible (each checks on its own)
	//SAM
	GraphSAM()
	//EMP
	GraphEMP()
	//COR
	GraphCOR()
	//EMP and BKG levels
	GraphEMPBKGLevels()
	
	ControlUpdate/A/W=COR_Graph
	
	ModifyGraph log(left)=1,mirror=2,grid=1,standoff=0
	ModifyGraph tickUnit=1
	Label left "(Counts/sec)/(MON*10\\S6\\M)"
	Label bottom "q (A\\S-1\\M)"
	
	return(0)
End

// add SAM data to the graph if it exists and is not already on the graph
//
Function GraphSAM()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//is it already on the graph?
	SetDataFolder $(USANSFolder+":Graph")
	String list=""
	list = Wavelist("DetCts_SAM*",";","WIN:COR_Graph")
	if(strlen(list)!=0)
		//Print "SAM already on graph"
		return(0)
	Endif
	//append the data if it exists
	If(waveExists($"DetCts_SAM")==1)
		DoWindow/F COR_Graph
		AppendToGraph DetCts_SAM vs Qvals_SAM
		ModifyGraph rgb(DetCts_SAM)=(1,12815,52428)
		ModifyGraph mode(DetCts_SAM)=3,marker(DetCts_SAM)=19,msize(DetCts_SAM)=2
		ModifyGraph tickUnit=1
		ErrorBars/T=0 DetCts_SAM Y,wave=(ErrDetCts_SAM,ErrDetCts_SAM)
	endif
	SetDataFolder root:
End

// add EMP data to the graph if it exists and is not already on the graph
//
Function GraphEMP()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":Graph")
	String list=""
	list = Wavelist("DetCts_EMP*",";","WIN:COR_Graph")
	if(strlen(list)!=0)
	//	Print "EMP already on graph"
		return(0)
	Endif
	//append the data if it exists
	If(waveExists($"DetCts_EMP")==1)
		DoWindow/F COR_Graph
		AppendToGraph DetCts_EMP vs Qvals_EMP
		ModifyGraph msize(DetCts_EMP)=2,rgb(DetCts_EMP)=(1,39321,19939)
		ModifyGraph mode(DetCts_EMP)=3,marker(DetCts_EMP)=19
		ModifyGraph tickUnit=1
		ErrorBars/T=0 DetCts_EMP Y,wave=(ErrDetCts_EMP,ErrDetCts_EMP)
	endif
	SetDataFolder root:
	return(0)
End

// add COR data to the graph if it exists and is not already on the graph
//
Function GraphCOR()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":Graph")
	
	String list=""
	list = Wavelist("DetCts_COR*",";","WIN:COR_Graph")
	if(strlen(list)!=0)
	//	Print "COR already on graph"
		return(0)
	Endif
	//append the data if it exists
	If(waveExists($"DetCts_COR")==1)
		DoWindow/F COR_Graph
		AppendToGraph DetCts_COR vs Qvals_COR
		ModifyGraph msize(DetCts_COR)=2,rgb(DetCts_COR)=(52428,34958,1)
		ModifyGraph mode(DetCts_COR)=3,marker(DetCts_COR)=19
		ModifyGraph tickUnit=1
		ErrorBars DetCts_COR Y,wave=(ErrDetCts_COR,ErrDetCts_COR)
	endif

	SetDataFolder root:
	return(0)
End

// add horizoontal lines for the background and empty cell levels
Function GraphEMPBKGLevels()

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//if the data is on the graph, remove them and replot, to properly reset the scale
	DoUpdate
	String list = TraceNameList("COR_Graph",";",1)
	//Print list
	DoWindow/F COR_Graph
	if(stringmatch(list,"*empLevel*")==1)
		//remove
		RemoveFromGraph empLevel,bkgLevel
	Endif
	DoUpdate
	AppendToGraph $(USANSFolder+":EMP:EMPLevel"),$(USANSFolder+":BKG:BKGLevel")
	ModifyGraph rgb(empLevel)=(0,0,0),lsize(bkgLevel)=2,rgb(bkgLevel)=(52428,1,1)
	ModifyGraph lsize(empLevel)=2,offset={0,0}
	ModifyGraph tickUnit=1
	GetAxis/W=COR_Graph/Q bottom
	SetScale/I x V_min,V_max,"",$(USANSFolder+":EMP:EMPLevel"),$(USANSFolder+":BKG:BKGLevel")
	return(0)
End

// polls the control bar for proper selections of SavePath
// checks for selected dataset from radio buttons
// obtains the poin numbers from the cursors, if selected
// dispatches to save routine
//
Function SaveButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	PathInfo/S savePathName
	if(V_Flag==0)
		DoAlert 0,"Pick a \"SavePath...\"\rNo data file has been written"
		return(1)
	Endif
	
	String type=""
	Variable useCrsrs=0,ptA=0,ptB=0
	
	//check for data save type (controlled by radio buttons)
	NVAR gRadioVal=$(USANSFolder+":Globals:MainPanel:gTypeCheck")		//1=COR,2=SAM,3=EMP
	switch(gRadioVal)
		case 1:	//COR
			type="COR"
			break				
		case 2:	//SAM
			type="SAM"
			break
		case 3:	//EMP
			type="EMP"
			break	
		default:
			DoAlert 0,"No Radio button selected\rNo data file written"
			return(1)
	endswitch
	
	//check for data save between cursors
	ControlInfo UseCrsrCheck
	useCrsrs = V_Value 		//1 if checked
	//if so, read off the point range (cursors should be on the same wave as the save type)
	if(useCrsrs)
		Wave xwave=$(USANSFolder+":Graph:Qvals_"+type)
		ptA=x2pnt(xwave,xcsr(A))
		ptB=x2pnt(xwave,xcsr(B))
		if(ptA>ptB)
			ptA=x2pnt(xwave,xcsr(B))
			ptB=x2pnt(xwave,xcsr(A))
		endif
		ptA=trunc(ptA)	//make sure it's integer
		ptB=trunc(ptB)
		//Print ptA,ptB
	endif
	
	//fill in the blanks and dispatch to save routine
	WriteUSANSWaves(type,"",ptA,ptB,1)
	
	return(0)
End

//show/hide cursors depending on the checkbox selection
//put cursors on the selected save data type
Function UseCrsrCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	NVAR gRadioVal=$(USANSFolder+":Globals:MainPanel:gTypeCheck")		//1=COR,2=SAM,3=EMP
	String type=""
	switch(gRadioVal)
		case 1:	//COR
			type="COR"
			break				
		case 2:	//SAM
			type="SAM"
			break
		case 3:	//EMP
			type="EMP"
			break	
		default:
			DoAlert 0,"No Radio button selected\rCan't place cursors"
			return(1)
	endswitch
	if(checked)
		//show info and cursors, if the wave in on the graph
		String str,yname
		str=TraceNameList("", ";", 1)
		yname="DetCts_"+type
		Variable ok=WhichListItem(yname, str,";",0)
		if(ok != -1)
			Wave ywave=$(USANSFolder+":Graph:DetCts_"+type)
			Showinfo/W=COR_Graph
			Cursor/A=1/P/S=1 A,$yname,0
			Cursor/A=0/P/S=1 B,$yname,numpnts(ywave)-1
		else
			//trace is not on graph
			CheckBox $ctrlName, value=0		//not checked
			HideInfo/W=COR_Graph
			Cursor/K A
			Cursor/K B
			DoAlert 0,type+" data is not on the graph"
		endif
	else
		//hide info and cursors, if there are any displayed
		HideInfo/W=COR_Graph
		Cursor/K A
		Cursor/K B
		CheckBox useCrsrCheck,value= 0
	endif
	DoUpdate
End

//radio button control of save type
//sets global, so buttons don't need to be polled
Function TypeToggleCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	NVAR gRadioVal=$(USANSFolder+":Globals:MainPanel:gTypeCheck")
	
	strswitch(ctrlName)
		case "CORCheck":
			gRadioVal=1
			break
		case "SAMCheck":
			gRadioVal=2
			break
		case "EMPCheck":
			gRadioVal=3
			break
	endswitch
	CheckBox CORCheck,value= (gRadioVal==1)
	CheckBox SAMCheck,value= (gRadioVal==2)
	CheckBox EMPCheck,value= (gRadioVal==3)
	
	//move the cursors to the correct trace on the graph
	ControlInfo useCrsrCheck
	checked=V_Value
	UseCrsrCheckProc("useCrsrCheck",V_Value)
End

//updates the trans values and the bkg/empty values on the graph, if necessary
//calculate the T_Wide and T_Rock from the wave notes
// if there is an error in the wave notes, "NaN" will typically be returned
//
Function UpdateButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Wave samCts=$(USANSFolder+":SAM:DetCts")
	Wave empCts=$(USANSFolder+":EMP:DetCts")
	if((WaveExists(samCts)==0) || (WaveExists(empCts)==0))
		Variable/G $(USANSFolder+":Globals:MainPanel:gTransWide")=NaN		//error
		Variable/G $(USANSFolder+":Globals:MainPanel:gTransRock")=NaN
		return(1)
	Endif
	//get the wave notes, and the transCt values
	String samNote=note(samCts),empNote=note(empCts)
	Variable samWide,empWide,samRock,empRock
	samWide = NumberByKey("TWIDE",samNote,":",";")
	empWide = NumberByKey("TWIDE",empNote,":",";")
	samRock = NumberByKey("PEAKVAL",samNote,":",";")
	empRock = NumberByKey("PEAKVAL",empNote,":",";")
	Variable/G $(USANSFolder+":Globals:MainPanel:gTransWide")=samWide/empWide
	Variable/G $(USANSFolder+":Globals:MainPanel:gTransRock")=samRock/empRock
	
	TransRatio()		//calculate the ratio and update
	
	return(0)
End

// dispatches to the function to perform the data correction
//
Function CorrectButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoCorrectData()
	return(0)
End

//button to present a simple input dialog to ask the user for the data type
// (either SAM or EMP) and the new value of the peak angle to use.
//
// rarely needed, but sometimes the data can fool IGOR, and no peak can be found
// in some cases, data may not cover the primary beam. In both of these cases it 
// is necessary to manually override the peak angle
//
// calls RePlotWithUserAngle to "re-do" everything
//
Function QpkButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	Variable newPkAngle=0
	String dataSet="SAM;EMP;",type=""
	
	Prompt type,"Select Data Set",popup,dataSet
	Prompt newPkAngle, "Enter new peak ANGLE, in Degrees"
	DoPrompt "Override the peak angle",type,newPkAngle
	//Print newPkAngle,type
	if(V_Flag==1)		//user cancel, exit
		return(1)
	endif
	//with the new information (type and angle) re-do the whole mess
	//...as if the "plot" button was hit, except that the angle is known...
	
	RePlotWithUserAngle(type,newPkAngle)
End

Function TransRatio()
	NVAR tr = root:Packages:NIST:USANS:Globals:MainPanel:gTransRock
	NVAR tw = root:Packages:NIST:USANS:Globals:MainPanel:gTransWide
	NVAR rat = root:Packages:NIST:USANS:Globals:MainPanel:gTransRatio
	
	rat = tr/tw
	if(rat < 0.9)
		SetVariable setVar0 labelBack=(65535,32768,32768)
	else
		SetVariable setVar0 labelBack=0
	endif
	return(0)
End

Function LogLinToggleCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked			
			if(checked)
				ModifyGraph log(bottom)=1
			else
				ModifyGraph log(bottom)=0
			endif
			break
	endswitch

	return 0
End


//returns the peak location found (and used) for zero angle
//displayed on the COR_Graph
Function QpkFromNote(type)
	String type

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
		
	Wave/Z detCts=$(USANSFolder+":Graph:DetCts_"+type)
	if(!WaveExists(detCts))
		return(NaN)
	Endif
	String str=note(detcts)
	Variable val
	
	val=NumberByKey("PEAKANG", str,":",";") 
	return(val)
End

//nearly identical to PlotSelectedSAMButtonProc
// - re-loads the data and goes through all the steps as it they were new datsets
// - DOES NOT try to find the peak angle, instead uses the input zeroAngle
// - replaces the PEAKANG:value with the input zeroAngle
// updates the plot with the corrected angle
//
Function RePlotWithUserAngle(type,zeroAngle)
	String type
	Variable zeroAngle

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	//SETS the wave note with the PEAKANG value
	
	//loads each of the data files
	//normalizes each file to countrate immediately
	//appends them to the individual waves in "SAM" folder
	//sorts by angle
	//converts to Q-values USING SUPPLIED ANGLE
	//
	//get selected files from listbox (everything)
	//use the listBox wave directly
	
	Wave/T listW=$(USANSFolder+":Globals:MainPanel:"+type+"Wave")
	Variable ii,num=numpnts(listW)
	String fname="",fpath=""
	PathInfo bt5PathName
	fpath = S_Path
	
	//load, normalize, and append
	//loop over the number of items in the list
	for(ii=0;ii<num;ii+=1)
		fname = fpath + listw[ii]
		LoadBT5File(fname,"SWAP")	//overwrite what's in the SWAP folder
		Convert2Countrate("SWAP")
		if(ii==0)	//first time, overwrite
			NewDataWaves("SWAP",type)
		else		//append to waves in TYPE folder
			AppendDataWaves("SWAP",type)
		endif
	endfor
	//sort after all loaded
	DoAngleSort(type)
	
	//find the peak and convert to Q-values
	//Variable zeroAngle = FindZeroAngle("SAM")
	//if(zeroAngle == -9999)
		//DoAlert 0,"Couldn't find a peak - using zero as zero angle"
	//	zeroAngle = 0
	//Endif
	
	//find the peak value at the supplied angle, rather than automatic...
	Wave tmpangle = $(USANSFolder+":"+type+":Angle")
	Wave tmpdetCts = $(USANSFolder+":"+type+":DetCts")
	Variable pkHt=0
	pkHt = interp(zeroAngle,tmpangle,tmpdetcts)
	String str=""
	str=note(tmpDetCts)
	str = ReplaceNumberByKey("PEAKANG",str,zeroAngle,":",";")
	str = ReplaceNumberByKey("PEAKVAL",str,pkHt,":",";")
	Note/K tmpDetCts
	Note tmpdetCts,str
	
	ConvertAngle2Qvals(type,zeroAngle)
	//find the Trans Cts for T_Wide
	FindTWideCts(type)
	//
	//copy the data to plot to the root:Graph directory, and give clear names
	if(WaveExists($(USANSFolder+":"+type+":Qvals")))
		Duplicate/O $(USANSFolder+":"+type+":Qvals"),$(USANSFolder+":Graph:Qvals_"+type)
	Endif
	Duplicate/O $(USANSFolder+":"+type+":Angle"),$(USANSFolder+":Graph:Angle_"+type)
	Duplicate/O $(USANSFolder+":"+type+":DetCts"),$(USANSFolder+":Graph:DetCts_"+type)
	Duplicate/O $(USANSFolder+":"+type+":ErrDetCts"),$(USANSFolder+":Graph:ErrDetCts_"+type)
	
	//now plot the data (or just bring the graph to the front)
	DoCORGraph()
	
	//update the valDisplays
	ControlUpdate/A/W=COR_Graph		//overkill, does them all
End