#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

function ShowOnlineReductionPanel()

	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		return 0
	Endif
	
	DoWindow/F ORPanel
	If(V_flag != 0)
		return 0
	endif
	
	// data
	NewDataFolder/O root:myGlobals:OnlineReduction
	
	String/G root:myGlobals:OnlineReduction:Filename = ""
	String/G root:myGlobals:OnlineReduction:Protocol = ""
	Variable/G root:myGlobals:OnlineReduction:LastFileModification = 0
	
	// panel
	PauseUpdate; Silent 1
	NewPanel /W=(300,350,702,481) /K=2
	
	DoWindow/C ORPanel
	DoWindow/T ORPanel,"Online Reduction"	
	ModifyPanel cbRGB=(240*255,170*255,175*255)

	variable top = 5
	variable groupWidth = 390

	// filename
	GroupBox group_Flename		pos={6,top},		size={groupWidth,18+26},		title="select file for online reduction:"
	PopupMenu popup_Filename	pos={12,top+18},	size={groupWidth-12-0,20},	title=""
	PopupMenu popup_Filename	mode=1,			value=ASC_FileList(),			bodyWidth=groupWidth-12-0
	PopupMenu popup_Filename	proc=ORPopupSelectFileProc
	
	string fileList = ASC_FileList()
	if (ItemsInList(fileList) > 0)
		String/G root:myGlobals:OnlineReduction:Filename = StringFromList(0, fileList)
	else
		String/G root:myGlobals:OnlineReduction:Filename = ""
	endif

	top += 18+26+7

	// protocol
	GroupBox group_Protocol		pos={6,top},		size={groupWidth,18+22},		title="select protocol for online reduction:"
	SetVariable setvar_Protocol	pos={12,top+18},	size={groupWidth-12-18,0},	title=" "
	SetVariable setvar_Protocol	value=root:myGlobals:OnlineReduction:Protocol
	
	Button button_SelectProtocol pos={12+groupWidth-12-18,top+18-1}, size={18,18}, title="...", proc=ORButtonSelectProtocolProc

	top += 18+22+7
	variable left = 12
	
	// sart, stop, done	
	Button button_Start	pos={left + 70 * 0, top},	size={60,20},	title="Start",	proc=ORButtonStartProc
	Button button_Stop	pos={left + 70 * 1, top},	size={60,20},	title="Stop",	proc=ORButtonStopProc,	disable=2
	Button button_Done	pos={left + 70 * 2, top},	size={60,20},	title="Done",	proc=ORButtonDoneProc
	
end

function ORPopupSelectFileProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	String/G root:myGlobals:OnlineReduction:Filename = popStr
	
end

function ORButtonSelectProtocolProc(ctrlName) : ButtonControl
	String ctrlName

	String protocolName=""
	SVar gProtoStr=root:myGlobals:Protocols:gProtoStr
	
	//pick a protocol wave from the Protocols folder
	//must switch to protocols folder to get wavelist (missing parameter)
	SetDataFolder root:myGlobals:Protocols
	Execute "PickAProtocol()"
	
	//get the selected protocol wave choice through a global string variable
	protocolName = gProtoStr
	
	//If "CreateNew" was selected, go to the questionnare, to make a new set
	//and put the name of the new Protocol wave in gProtoStr
	if(cmpstr("CreateNew",protocolName) == 0)
		ProtocolQuestionnare()
		protocolName = gProtoStr
	Endif
	
	String/G root:myGlobals:OnlineReduction:Protocol = protocolName

	SetDataFolder root:
	
end

function ORButtonStartProc(ctrlName) : ButtonControl
	String ctrlName

	BackgroundInfo
	if(V_Flag != 2) // task is not running
		if (ORReduceFile() == 0) // check if first reduction works
		
			// set up task
			SetBackground ORUpdate()
			CtrlBackground period=(1*60), noBurst=0 // 60 = 1 sec // noBurst prevents rapid "catch-up calls
			CtrlBackground start
			
			DoWindow /T ORPanel, "Online Reduction - Running (Updated: " + time() + ")"
			DoWindow /F ORPanel
			// enable
			Button button_Stop			disable = 0
			// disable
			Button button_Start			disable = 2		
			PopupMenu popup_Filename	disable = 2
			SetVariable setvar_Protocol	disable = 2
			Button button_SelectProtocol	disable = 2
			
		endif
	endif

end

function ORButtonStopProc(ctrlName) : ButtonControl
	String ctrlName

	BackgroundInfo
	if(V_Flag == 2) // task is running
		// stop task
		CtrlBackground stop
	endif
		
	DoWindow /T ORPanel, "Online Reduction"
	DoWindow /F ORPanel
	// enable
	Button button_Start			disable = 0	
	PopupMenu popup_Filename	disable = 0
	SetVariable setvar_Protocol	disable = 0
	Button button_SelectProtocol	disable = 0
	// disable
	Button button_Stop			disable = 2

end

function ORButtonDoneProc(ctrlName) : ButtonControl
	String ctrlName

	ORButtonStopProc(ctrlName)
	DoWindow/K ORPanel

end

function ORUpdate()

	SVar filename = root:myGlobals:OnlineReduction:Filename
	NVar/z lastFileModification = root:myGlobals:OnlineReduction:LastFileModification
	
	if (lastFileModification == GetModificationDate(filename)) // no changes
	
		return 0 // continue task	
			
	elseif (ORReduceFile() == 0) // update
		
		DoWindow /T ORPanel, "Online Reduction - Running (Updated: " + time() + ")"
		print "Last Update: " + time()
		return 0 // continue task
		
	else	 // failure
		
		Beep
		ORButtonStopProc("")
		return 2 // stop task if error occurs
			
	endif
end

function ORReduceFile()

	SVar protocol = root:myGlobals:OnlineReduction:Protocol
	SVar filename = root:myGlobals:OnlineReduction:Filename

	String waveStr	= "root:myGlobals:Protocols:"+protocol
	String samStr	= filename
	
	if (exists(waveStr) != 1)
		DoAlert 0,"The Protocol with the name \"" + protocol + "\" was not found."
		return 1 // for error
	endif
	
	NVar/z lastFileModification = root:myGlobals:OnlineReduction:LastFileModification
	lastFileModification = GetModificationDate(samStr)

	// file needs to be removed from the DataFolder so that it will be reloaded
	string partialName = filename
	variable index = strsearch(partialName,".",0)
	if (index != -1)
		partialName = partialName[0,index-1]
	endif
	KillDataFolder/Z $"root:Packages:quokka:"+partialName
	
	return ExecuteProtocol(waveStr, samStr)

end

function GetModificationDate(filename)
	string filename
	
	PathInfo catPathName // this is where the files are
	string path = S_path + filename

	Getfilefolderinfo/q/z path
	if(V_flag)
		Abort "file was not found"
	endif

	return  V_modificationDate
	
end