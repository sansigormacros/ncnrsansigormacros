#pragma rtGlobals=1		// Use modern global access method.


///////// SRK - VERY SIMPLE batch converter has been added: see
//
//	Function batchXML26ColConvert()
//



// Functions and interfaces to manage datasets now that they are in data folders
// Planned interface
// - Panel to select/load data and then select operation
// Planned functions:
// - Rename a data set - AJJ Done Nov 2009
// - Duplicate a data set - AJJ Done Nov 2009
// - Subtract one data set from another
// - Add one data set to another
// - Divide data sets
// - Multiply data sets
// - Save a data folder to file

/////////////////// Data Management Panel ///////////////////////////////////////////////////////

// 
Proc MakeDMPanel()
	DoWindow/F DataManagementPanel
	if(V_flag==0)
		fMakeDMPanel()
	endif
End

Proc fMakeDMPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(459,44,959,410)/N=DataManagementPanel/K=2 as "Data Set Management"
	ModifyPanel fixedSize=1,cbRGB=(30000,60000,60000)

	//Main bit of panel
	GroupBox grpBox_0,pos={20,10},size={460,100}
	GroupBox grpBox_1,pos={20,130},size={460,70}
	GroupBox grpBox_2,pos={20,220},size={460,40}

	GroupBox grpBox_3,pos={20,280},size={460,40}

	Button DS_button,title="Load 1D Data Set",pos={300,20},size={150,20}
	Button DS_button,proc=DM_LoadDataSetProc
	Button Unload_button,title="Unload 1D Data Set",pos={300,50},size={150,20}
	Button Unload_button,proc=DM_UnloadProc	
	Button Save_button,title="Save 1D Data Set",pos={300,80},size={150,20}
	Button Save_button,proc=DM_SaveProc
	PopupMenu DS_popup,pos={30,40},size={318,20},title="Data Set ",proc=DM_PopupProc
	PopupMenu DS_popup,mode=1,value= #"DM_DataSetPopupList()"

	CheckBox XMLStateCtrl,pos={30,82},size={124,14},title="XML Output Enabled (change in Preferences)"
	CheckBox XMLStateCtrl,help={"Default output format is canSAS XML rather than NIST 6 column"}
	CheckBox XMLStateCtrl,value= root:Packages:NIST:gXML_Write,disable=2

	Button Rename_button,title="Rename",pos={75,170},size={150,20}
	Button Rename_button,proc=DM_RenameProc
	Button  Duplicate_button,title="Duplicate",pos={275,170},size={150,20}
	Button Duplicate_button,proc=DM_DuplicateProc

	SetVariable NewName_setvar,title="New Name (max 25 characters)",pos={50,140},size={400,20}
	SetVariable NewName_setvar,fsize=12,value=_STR:"",proc=DMNameSetvarproc,live=1
		
	Button SaveAsXML_button,title="Save as canSAS XML",pos={75,230},size={150,20}
	Button SaveAsXML_button,proc=DMSaveAsXMLproc	

	Button SaveAs6col_button,title="Save as NIST 6 column",pos={275,230},size={150,20}
	Button SaveAs6col_button,proc=DMSaveAs6colproc	
	
	Button BatchConvertData_button,title="Convert Format of 1D Data Files",pos={75,290},size={350,20}
	Button BatchConvertData_button,proc=DMBatchConvertProc
			
	Button DMDone_button,title="Done",pos={360,330},size={60,20}
	Button DMDone_button,proc=DMDoneButtonProc
	Button DMHelp_button,title="?",pos={440,330},size={30,20}
	Button DMHelp_button,proc=DMHelpButtonProc
	
	
	ControlInfo/W=DataManagementPanel DS_popup
	if (cmpstr(S_Value,"No data loaded") == 0)
		SetVariable NewName_setvar,value=_STR:"dataset_copy"
	else
		//fake call to popup
		STRUCT WMPopupAction pa
		pa.win = "DataManagementPanel"
		pa.ctrlName = "DS_popup"
		pa.eventCode = 2
		DM_PopupProc(pa)
	endif

End

Function DMBatchConvertProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode)
		case 2:
			Execute	"MakeBatchConvertPanel()"
			break
	endswitch
	
	return 0
End


Function DMNameSetvarproc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
				String sv = sva.sval
				if( strlen(sv) > 25 )
					sv= sv[0,24]
					SetVariable  $(sva.ctrlName),win=$(sva.win),value=_STR:sv
					ControlUpdate /W=$(sva.win) $(sva.ctrlName)
					Beep
				endif
				break
		endswitch
	return 0
End

Function DM_RenameProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String DS,NewName
	
	ControlInfo/W=$(ba.win) DS_popup
	DS = S_Value
	
	ControlInfo/W=$(ba.win) NewName_setvar
	NewName = CleanupName(S_Value, 0 )		//clean up any bad characters, and put the cleaned string back
	SetVariable NewName_setvar,value=_STR:NewName
	
	switch (ba.eventcode)
		case 2: // mouse up
			RenameDataSet(DS,NewName)
			ControlUpdate /W=$(ba.win) DS_Popup
			break
	endswitch


	
	return 0
end
		
Function DM_DuplicateProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String DS,NewName
	
	ControlInfo/W=$(ba.win) DS_popup
	DS = S_Value
	
	ControlInfo/W=$(ba.win) NewName_setvar
	NewName = CleanupName(S_Value, 0 )		//clean up any bad characters, and put the cleaned string back
	SetVariable NewName_setvar,value=_STR:NewName
	
	switch (ba.eventcode)
		case 2: // mouse up
			DuplicateDataSet(DS,NewName,0)
			ControlUpdate /W=$(ba.win) DS_Popup
			break
	endswitch
	
	return 0
end

Function DM_SaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch(ba.eventCode)
		case 2:
			ControlInfo/W=$(ba.win) DS_popup
			SaveDataSetToFile(S_Value)
			break
	endswitch
	
	return 0
end

Function DM_UnloadProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch (ba.eventcode)
		case 2: // mouse up
			
			String savDF=GetDataFolder(1)
			String DF
			ControlInfo /W=$(ba.win) DS_Popup
			DF = S_Value
			
			print DF
			//check for horrific null output from control
			if (cmpstr(DF,"") != 0)
			
				SetDataFolder DF
				KillVariables/A
				SetDataFolder savDF
			
				KillDataFolder/Z $DF
				ControlUpdate /W=$(ba.win) DS_Popup
			
				ControlInfo/W=DataManagementPanel DS_popup
				if (cmpstr(S_Value,"No data loaded") == 0)
					SetVariable NewName_setvar,value=_STR:"dataset_copy"
				else
					//fake call to popup
					STRUCT WMPopupAction pa
					pa.win = "DataManagementPanel"
					pa.ctrlName = "DS_popup"
					pa.eventCode = 2
					DM_PopupProc(pa)
				endif
			endif
			break
	endswitch
	
	return 0
end
		

Function DM_PopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	String resultName
	
	switch( pa.eventCode)
		case 2:
			//print "Called by "+pa.ctrlname+" with value "+pa.popStr
			ControlInfo/W=$(pa.win) $(pa.ctrlName)
			String popStr = S_Value
			if (stringmatch(pa.ctrlname,"*DS*") == 1)
				resultName = stringfromlist(0,popStr,"_")+"_copy"
				
				SetVariable NewName_setvar win=$(pa.win), value=_STR:resultName
			endif
		break
	endswitch
	

End


//Must follow naming scheme to match buttons to popups
//"Name_button" goes with "Name_popup"
Function DM_LoadDataSetProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba


	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String cmd = "A_LoadOneDDataWithName(\"\","+num2str(0)+")"
			Execute cmd
		
			SVAR gLastFileName = root:packages:NIST:gLastFileName

			String windowName = ba.win
			String popupName = StringFromList(0,ba.ctrlName,"_")+"_popup"
			
			ControlUpdate/W=$(windowName) $(popupName)
			//instead of a simple controlUpdate, better to pop the menu to make sure that the other menus follow
			// convoluted method to find the right item and pop the menu.

			String list,folderStr
			Variable num
			folderStr = CleanupName(gLastFileName,0)
			list = DM_DataSetPopupList()
			num=WhichListItem(folderStr,list,";",0,0)
			if(num != -1)
				PopupMenu $(popupName),mode=num+1,win=$(windowName)
				ControlUpdate/W=$(windowName) $(popupName)
				
				if (cmpstr(popupName,"DS_popup") ==  0)
					//send fake mouse action to popup to update old name if 
					Struct WMPopupAction pa
					pa.eventCode = 2		//fake mouse up
					pa.win = windowName
					pa.ctrlName = "DS_popup"
					DM_PopupProc(pa)
				endif			
			endif
			break
	endswitch
	
	return 0
End


Function/S DMGetDSName(dsNum)
	Variable dsNum
	
	String ctrlName
	if (dsNum == 1)
		ctrlName = "DS1_popup"
	elseif (dsNum == 2)
		ctrlName = "DS2_popup"
	endif
	
	ControlInfo/W=DataManagementPanel $(ctrlName)

	Return S_Value

End


Function DMDoneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			DoWindow/K DataManagementPanel
			break
	endswitch

	return 0
End

Function DMHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			DisplayHelpTopic/Z/K=1 "Data Set Management"
			if(V_flag !=0)
				DoAlert 0,"The Data Set Management Help file could not be found"
			endif
			break
	endswitch

	return 0
End

/////////////////////// Batch Data Conversion Panel ////////////////////////////////////
//
//

Proc MakeNCNRBatchConvertPanel()
	NCNRInitBatchConvert()
	DoWindow/F NCNRBatchConvertPanel
	if(V_flag==0)
		fMakeNCNRBatchConvertPanel()
	endif
End


Function NCNRInitBatchConvert()
	NewDataFolder/O/S root:Packages:NIST:BatchConvert
	Make/O/T/N=1 filewave=""
	Make/O/N=1 selWave=0
	Variable/G ind=0
	SetDataFolder root:
End

Proc fMakeNCNRBatchConvertPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(658,347,1018,737)/N=NCNRBatchConvertPanel/K=2 as "Batch Convert 1D Data"
	ModifyPanel cbRGB=(40000,50000,32896)
	ModifyPanel fixedSize=1
	
	ListBox fileList,pos={13,11},size={206,179}
	ListBox fileList,listWave=root:Packages:NIST:BatchConvert:fileWave
	ListBox fileList,selWave=root:Packages:NIST:BatchConvert:selWave,mode= 4

	Button button7,pos={238,20},size={100,20},proc=NCNRBatchConvertNewFolder,title="New Folder"
	Button button7,help={"Select a new data folder"}
	TitleBox msg0,pos={238,140},size={100,30},title="\JCShift-click to\rselect multiple files"
	TitleBox msg0,frame=0,fixedSize=1
	
	GroupBox filterGroup,pos={13,200},size={206,60},title="Filter list by input file type"
	
	Button button8,pos={238,76},size={100,20},proc=NCNRBatchConvertHelpProc,title="Help"
	Button button9,pos={238,48},size={100,20},proc=NCNRBatchConvertRefresh,title="Refresh List"
	Button button0,pos={238,106},size={100,20},proc=NCNRBatchConvertDone,title="Done"

	GroupBox outputGroup,pos={13,270},size={206,60},title="Output File Type"

	
	Button button6,pos={13,350},size={206,20},proc=NCNRBatchConvertFiles,title="Convert File(s)"
	Button button6,help={"Converts the files to the format selected"}
	

	
End


Function NCNRBatchConvertFiles(ba) : ButtonControl
		STRUCT WMButtonAction &ba
		
		switch (ba.eventCode)
			case 2:
				Wave/T fileWave=$"root:Packages:NIST:BatchConvert:fileWave"
				Wave sel=$"root:BatchConvert:NIST:BatchConvert:selWave"
				
				break
		endswitch

	return 0
End


Function NCNRBatchConvertNewFolder(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch (ba.eventcode)
		case 2:
			A_PickPath()
			NCNRBatchConvertGetList()
			break
	endswitch

End

Function NCNRBatchConvertGetList()

	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use \"New Folder\" button"
	Endif
	
	String newList = A_ReducedDataFileList("")
	Variable num
	
	num=ItemsInList(newlist,";")
	WAVE/T fileWave=$"root:Packages:NIST:BatchConvert:fileWave"
	WAVE selWave=$"root:Packages:NIST:BatchConvert:selWave"
	Redimension/N=(num) fileWave
	Redimension/N=(num) selWave
	fileWave = StringFromList(p,newlist,";")
	Sort filewave,filewave
End

Function NCNRBatchConvertRefresh(ba) : ButtonControl
		STRUCT WMButtonAction &ba
		
		switch (ba.eventCode)
			case 2:
				NCNRBatchConvertGetList()
				break
		endswitch
		
		return 0
End
	

Function NCNRBatchConvertDone(ba) : ButtonControl
		STRUCT WMButtonAction &ba

		switch (ba.eventCode)
			case 2:
				DoWindow/K NCNRBatchConvertPanel
				break
		endswitch
		
		return 0
End

Function NCNRBatchConvertHelpProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			DisplayHelpTopic/Z/K=1 "Batch Data Conversion"
			if(V_flag !=0)
				DoAlert 0,"The Batch Data Conversion Help file could not be found"
			endif
			break
	endswitch

	return 0
End

/////////////////////// Data Arithmetic Panel /////////////////////////////////////////

// 
Function MakeDAPanel()
	DoWindow/F DataArithmeticPanel
	if(V_flag==0)
		fMakeDAPanel()
	else
		DoWindow/F DAPlotPanel
	endif
	
	return(0)
End

Function fMakeDAPanel()
	PauseUpdate; Silent 1		// building window...
	DoWindow/K DataArithmeticPanel
	NewPanel /W=(459,44,959,404)/N=DataArithmeticPanel/K=2 as "Data Set Arithmetic"
	ModifyPanel fixedSize=1

	//Main bit of panel
	GroupBox grpBox_0,pos={20,10},size={460,105}

	Button DS1_button,pos={300,20},size={150,20},proc=DA_LoadDataSetProc,title="Load 1D Data Set 1"
	Button DS1_button,valueColor=(65535,0,0),userdata="DS1"
	PopupMenu DS1_popup,pos={30,21},size={318,20},title="Data Set 1"
	PopupMenu DS1_popup,mode=1,value= #"DM_DataSetPopupList()"
	PopupMenu DS1_popup,proc=DA_PopupProc
	PopupMenu DS1_popup,fsize=12,fcolor=(65535,0,0),valueColor=(65535,0,0)

	Button DS2_button,pos={300,50},size={150,20},proc=DA_LoadDataSetProc,title="Load 1D Data Set 2"
	Button DS2_button,valueColor=(0,0,65535),userdata="DS2"
	PopupMenu DS2_popup,pos={30,51},size={318,20},title="Data Set 2"
	PopupMenu DS2_popup,mode=1,value= #"DM_DataSetPopupList()"
	PopupMenu DS2_popup,proc=DA_PopupProc
	PopupMenu DS2_popup,fsize=12,fcolor=(0,0,65535),valueColor=(0,0,65535)

	Button DAPlot_button,title="Plot",pos={100,85},size={150,20}
	Button DAPlot_button,proc=DAPlotButtonProc
	Button DADone_button,title="Done",pos={360,85},size={60,20}
	Button DADone_button,proc=DADoneButtonProc
	Button DAHelp_button,title="?",pos={440,85},size={30,20}
	Button DAHelp_button,proc=DAHelpButtonProc


	//Tabs
	TabControl DATabs,pos={20,120},size={460,220},tabLabel(0)="Subtract", proc=DATabsProc
	TabControl DATabs,tablabel(1)="Add",tablabel(2)="Multiply",tablabel(3)="Divide"
	TabControl DATabs,value=0

	Button DACalculate_button,title="Calculate",pos={50,310},size={150,20}
	Button DACalculate_button,proc=DACalculateProc
	Button DASave_button,title="Save Result",pos={300,310},size={150,20}
	Button DASave_button,proc=DASaveProc,disable=2
	Button DACursors_button,title="Get Matching Range",pos={175,250},size={150,20}
	Button DACursors_button,proc=DACursorButtonProc
	
	SetVariable DAResultName_sv,title="Result Name (max 25 characters)",pos={50,280},size={400,20}
	SetVariable DAResultName_Sv,fsize=12,proc=DANameSetvarproc,live=1
	//Update the result name
	ControlInfo/W=DataArithmeticPanel DS1_popup
	if (cmpstr(S_Value,"No data loaded") == 0)
		SetVariable DAResultName_sv,value=_STR:"SubtractionResult"
	else
		//fake call to popup
		STRUCT WMPopupAction pa
		pa.win = "DataArithmeticPanel"
		pa.ctrlName = "DS1_popup"
		pa.eventCode = 2
		DA_PopupProc(pa)
	endif
	
	CheckBox DANoDS2_cb,title="Data Set 2 = 1?",pos={300,180}
	CheckBox DANoDS2_cb,proc=DANoDS2Proc
	
	ValDisplay DARangeStar_vd,title="Start",pos={40,220},size={100,20},fsize=12,value=_NUM:0
	ValDisplay DARangeEnd_vd,title="End  ",pos={160,220},size={100,20},fsize=12,value=_NUM:0
	
	SetVariable DAScale_sv,title="Scale Factor (f)",pos={280,220},size={180,20},fsize=12,value=_NUM:1

	GroupBox grpBox_1,pos={30,210},size={440,70}
	
	NewPanel/HOST=DataArithmeticPanel/N=arithDisplay/W=(50,150,170,190)
	
	//Update the result name
	ControlInfo/W=DataArithmeticPanel DS1_popup

	
	
	arithDisplayProc(0)
	
End


Function MakeDAPlotPanel()
	PauseUpdate; Silent 1		// building window...
	DoWindow/K DAPlotPanel
	NewPanel /W=(14,44,454,484)/N=DAPlotPanel/K=1 as "Data Set Arithmetic"
	ModifyPanel fixedSize=1

	Display/HOST=DAPlotPanel/N=DAPlot/W=(0,0,440,400)
	Legend
	ShowInfo
	SetActiveSubWindow DAPlotPanel
	Checkbox DAPlot_log_cb, title="Log I(q)", pos={20,410},value=0
	Checkbox DAPlot_log_cb, proc=DALogLinIProc
	
End

Function AddDAPlot(dataset)
	Variable dataset
	
	String win = "DataArithmeticPanel"
	String DS1name,DS2name,ResultName

	switch(dataset)
		case 1:
			ControlInfo/W=$(win) DS1_popup
			DS1name = S_Value
			Wave qWave = $("root:"+DS1name+":"+DS1name+"_q")
			Wave iWave = $("root:"+DS1name+":"+DS1name+"_i")
			Wave errWave = $("root:"+DS1name+":"+DS1name+"_s")
			AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
			ErrorBars/W=DAPlotPanel#DAPlot /T=0 $(DS1name+"_i"), Y wave=(errWave,errWave)
			ModifyGraph/W=DAPlotPanel#DAPlot rgb($(DS1name+"_i"))=(65535,0,0)
			ControlInfo/W=$(win) DANoDS2_cb
//			if (V_Value == 1)
//					Cursor/W=DAPlotPanel#DAPlot A, $(DS1name+"_i"), leftx(iWave)
//					Cursor/W=DAPlotPanel#DAPlot/A=0 B, $(DS1name+"_i"),  rightx(iWave)
//			endif
			break
		case 2:
			ControlInfo/W=$(win) DANoDS2_cb
			if (V_Value == 0)
				ControlInfo/W=$(win) DS2_popup
				DS2name = S_Value
				if(cmpstr(DS2name,"No data loaded")==0)
					break			//in case someone loads set 1, but not set two, then plots
				endif
				Wave qWave = $("root:"+DS2name+":"+DS2name+"_q")
				Wave iWave = $("root:"+DS2name+":"+DS2name+"_i")
				Wave errWave = $("root:"+DS2name+":"+DS2name+"_s")
				AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
				ErrorBars/W=DAPlotPanel#DAPlot /T=0 $(DS2name+"_i"), Y wave=(errWave,errWave)			
				ModifyGraph/W=DAPlotPanel#DAPlot rgb($(DS2name+"_i"))=(0,0,65535)
				Cursor/W=DAPlotPanel#DAPlot A, $(DS2name+"_i"), leftx(iWave)
				Cursor/W=DAPlotPanel#DAPlot/A=0 B, $(DS2name+"_i"),  rightx(iWave)
			else
				ControlInfo/W=$(win) DS1_popup
				DS1name = S_Value
				DuplicateDataSet("root:"+DS1name,"NullSolvent",1)
				Wave qWave =root:NullSolvent:NullSolvent_q
				Wave iWave = root:NullSolvent:NullSolvent_i
				Wave errWave = root:NullSolvent:NullSolvent_s
				Wave iWaveDS1 = $("root:"+DS1name+":"+DS1name+"_i")
				iWave = 1
				errWave = 0
				AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
				ErrorBars/W=DAPlotPanel#DAPlot /T=0 NullSolvent_i, Y wave=(errWave,errWave)			
				ModifyGraph/W=DAPlotPanel#DAPlot rgb(NullSolvent_i)=(0,0,65535)
				//Cursor/W=DAPlotPanel#DAPlot A, NullSolvent_i, leftx(iWave)
				//Cursor/W=DAPlotPanel#DAPlot/A=0 B, NullSolvent_i,  rightx(iWave)
				if(strlen(CsrInfo(A,"DAPlotPanel#DAPlot")) == 0)		//cursors not already on the graph		
					Cursor/W=DAPlotPanel#DAPlot A, $(DS1Name+"_i"), leftx(iWaveDS1)
					Cursor/W=DAPlotPanel#DAPlot/A=0 B, $(DS1Name+"_i"),  rightx(iWaveDS1)			
				endif
			endif
			break
		case 3:
			ControlInfo/W=$(win) DAResultName_sv
			ResultName = S_Value
			Wave qWave = $("root:"+ResultName+":"+ResultName+"_q")
			Wave iWave = $("root:"+ResultName+":"+ResultName+"_i")
			Wave errWave = $("root:"+ResultName+":"+ResultName+"_s")
			AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
			ErrorBars/W=DAPlotPanel#DAPlot /T=0 $(ResultName+"_i"), Y wave=(errWave,errWave)
			ModifyGraph/W=DAPlotPanel#DAPlot rgb($(ResultName+"_i"))=(0,65535,0)
			break
	endswitch

	ControlInfo/W=DAPlotPanel DAPlot_log_cb
	ModifyGraph/W=DAPlotPanel#DAPlot mode=3, msize=2, marker=19, mirror=1, tick=2, log(bottom)=1,log(left)=V_Value,tickUnit=1
End

Function arithDisplayProc(s)
	Variable s

	SetActiveSubWindow DataArithmeticPanel#arithDisplay

	switch (s)
		case 0:
			//Subtract
			DrawAction/L=progFront delete
			DrawRect 0,0,120,40
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,65535,0)
			DrawText 10,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 20,30,"="
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (65535,0,0)
			DrawText 35,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,65535)
			DrawText 95,32,"I"
			SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 52,32,"-"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 75,30,"f"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 85,32,"*"
			break
		case 1:
			//Add
			DrawAction/L=progFront delete
			DrawRect 0,0,120,40
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,65535,0)
			DrawText 10,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 20,30,"="
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (65535,0,0)
			DrawText 35,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,65535)
			DrawText 95,32,"I"
			SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 52,32,"+"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 75,30,"f"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 85,32,"*"
			break
		case 2:
			//Multiply
			DrawAction/L=progFront delete
			DrawRect 0,0,120,40
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,65535,0)
			DrawText 10,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 20,30,"="
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (65535,0,0)
			DrawText 35,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,65535)
			DrawText 95,32,"I"
			SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 52,32,"*"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 66,30,"("
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 75,30,"f"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 85,32,"*"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)					
			DrawText 105,30,")"
			break
		case 3:
			//Divide
			DrawAction/L=progFront delete
			DrawRect 0,0,120,40
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,65535,0)
			DrawText 10,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 20,30,"="
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (65535,0,0)
			DrawText 35,32,"I"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,65535)
			DrawText 95,32,"I"
			SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 52,32,"/"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 66,30,"("
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
			DrawText 75,30,"f"
			SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
			DrawText 85,32,"*"
			SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)					
			DrawText 105,30,")"
			break		
	endswitch

	SetActiveSubWindow DataArithmeticPanel
	
	return 0
End

//Must follow naming scheme to match buttons to popups
//"Name_button" goes with "Name_popup"
Function DA_LoadDataSetProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String cmd = "A_LoadOneDDataWithName(\"\","+num2str(0)+")"
			Execute cmd
		
			SVAR gLastFileName = root:packages:NIST:gLastFileName

			String windowName = ba.win
			String popupName = StringFromList(0,ba.ctrlName,"_")+"_popup"
			
			ControlUpdate/W=$(windowName) $(popupName)
			//instead of a simple controlUpdate, better to pop the menu to make sure that the other menus follow
			// convoluted method to find the right item and pop the menu.

			String list,folderStr
			Variable num
			folderStr = CleanupName(gLastFileName,0)
			list = DM_DataSetPopupList()
			num=WhichListItem(folderStr,list,";",0,0)
			if(num != -1)
				PopupMenu $(popupName),mode=num+1,win=$(windowName)
				ControlUpdate/W=$(windowName) $(popupName)
		
			endif
			//fake call to popup
			STRUCT WMPopupAction pa
			pa.win = ba.win
			pa.ctrlName = "DS1_popup"
			pa.eventCode = 2
			DA_PopupProc(pa)
			break
	endswitch
	
	return 0
End

Function DA_PopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	String resultName
	
	switch( pa.eventCode)
		case 2:
			//print "Called by "+pa.ctrlname+" with value "+pa.popStr
			ControlInfo/W=$(pa.win) $(pa.ctrlName)
			String popStr = S_Value
			if (stringmatch(pa.ctrlname,"*DS1*") == 1)
				resultName = stringfromlist(0,popStr,"_")+"_mod"
				
				SetVariable DAResultName_sv win=$(pa.win), value=_STR:resultName
			endif
		break
	endswitch
	

End

// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will 
// appear in odd places...
// all buttons are named MainButton_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly..
//
Function DATabsProc(tca) : TabControl
	STRUCT WMTabControlAction &tca
		
	switch (tca.eventCode)
		case 2:
		//	Print "name,number",name,tab
			String ctrlList = ControlNameList("",";"),item="",nameStr=""
			Variable num = ItemsinList(ctrlList,";"),ii,onTab
			for(ii=0;ii<num;ii+=1)
				//items all start w/"DSTabItem_"
				item=StringFromList(ii, ctrlList ,";")
				nameStr=item[0,9]
				if(cmpstr(nameStr,"DATabItem_")==0)
					onTab = str2num(item[10])
					ControlInfo $item
					switch (V_flag)
						case 1:
							Button $item,disable=(tca.tab!=onTab)
							break
						case 2:
							CheckBox $item,disable=(tca.tab!=onTab)
							break
						case 3:
							PopUpMenu	$item,disable=(tca.tab!=onTab)
							break
						case 5:
							SetVariable	$item,disable=(tca.tab!=onTab)
							break
					endswitch
				endif
			endfor
			
			arithDisplayProc(tca.tab)
			break
	endswitch	
End


Function DACalculateProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String DS1,DS2,Resultname
	
	switch(ba.eventCode)
	case 2:	
		//Which tab?
		ControlInfo/W=$(ba.win) DATabs
		Variable tabNum = V_value
		//Print "Tab number "+num2str(tabNum)

		ControlInfo/W=$(ba.win) DS1_popup
		DS1 = S_Value
		ControlInfo/W=$(ba.win) DANoDS2_cb
		if (V_Value == 0)
			ControlInfo/W=$(ba.win) DS2_popup
			DS2 = S_Value
		else
			DS2 = "NullSolvent"
		endif
		ControlInfo/W=$(ba.win) DAResultName_sv
		Resultname = CleanupName(S_Value, 0 )		//clean up any bad characters, and put the cleaned string back
		SetVariable DAResultName_sv,value=_STR:ResultName
		
		ControlInfo/W=$(ba.win) DAScale_sv
		Variable Scalefactor = V_Value

		switch(tabNum)
			case 0:
				//do subtraction
				//print "Subtraction of "+DS2+" from "+DS1+" with sf "+num2str(scalefactor)+ " into "+Resultname
				SubtractDataSets(DS1,DS2,Scalefactor,Resultname)
				break
			case 1:
				//do addition
				AddDataSets(DS1,DS2,Scalefactor,Resultname)
				break
			case 2:
				//do multiplication
				MultiplyDataSets(DS1,DS2,Scalefactor,Resultname)
				break
			case 3:
				//do division
				DivideDataSets(DS1,DS2,Scalefactor,Resultname)
				break
		endswitch
		
		//Sort out plot
		//Fake button press to DAPlotButtonProc
		STRUCT WMButtonAction ba2
		ba2.win = ba.win
		ba2.ctrlName = "DAPlot_button"
		ba2.eventCode = 2
		
		// I've commented this out - the cursors get reset to the ends since this removes all sets from the graph, and
		// then replots them. What is the real purpose of this call? To clear the old result off before adding the 
		// new one? 
//		DAPlotButtonProc(ba2)
		ba2.userData = ResultName
		DAPlotRemoveResult(ba2)
		
		
		AddDAPlot(3)
		DoWindow/F DataArithmeticPanel
		
		//Enable save button now that we have a result to save
		Button DASave_Button win=$(ba.win),disable=0
		
//		SetActiveSubWindow DAPlotPanel
	endswitch
	
End

// remove what is not the 
//
Function DAPlotRemoveResult(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	String ResultName = ba.userData
	String item="",traceList=""
	Variable ii=0,num

	switch (ba.eventCode)
		case 2:		//mouse up
			//data set 1
			ControlInfo/W=$(win) DS1_popup
			String DS1 = S_Value
			
			//Get folder for DS2
			ControlInfo/W=$(win) DS2_popup
			String DS2 = S_Value
			
			// state of the checkbox
			ControlInfo/W=$(win) DANoDS2_cb
			if(V_Value)
				DS2 = "NullSolvent"
			endif
			
			DoWindow DAPlotPanel
			if (V_Flag == 0)
				MakeDAPlotPanel()
			else 
				DoWindow/HIDE=0/F DAPlotPanel
				traceList = TraceNameList("DAPlotPanel#DAPlot",";",1)
				num=ItemsInList(traceList)
				ii=0
				do 
					item = StringFromList(ii,traceList,";")
					if (stringmatch(item,ResultName+"*")==1)		//it it's the specific trace I've asked to remove
						RemoveFromGraph/W=DAPlotPanel#DAPlot $item
					elseif (stringmatch(item,DS1+"*")==0 && stringmatch(item,DS2+"*")==0)		//if it's not set1 & not set2
						RemoveFromGraph/W=DAPlotPanel#DAPlot $item
					endif
					
					ii+=1
				while(ii<num)				
			endif
			
			break
	endswitch

	return 0
End


Function DAPlotButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			//mouse up
			//Get folder for DS1
			DoWindow DAPlotPanel
			if (V_Flag == 0)
				MakeDAPlotPanel()
			else 
				DoWindow/HIDE=0/F DAPlotPanel
				do 
					String tracename = StringFromList(0,TraceNameList("DAPlotPanel#DAPlot",";",1),";")
					if (cmpstr(tracename,"")==0)
						break
					else
						RemoveFromGraph/W=DAPlotPanel#DAPlot $tracename
					endif			
				while(1)				
			endif
			
			ControlInfo/W=$(win) DS1_popup
			String DS1 = S_Value
			if (cmpstr(DS1,"") != 0 )
				AddDAPlot(1)
			endif
			//Get folder for DS2
			ControlInfo/W=$(win) DS2_popup
			String DS2 = S_Value
			if (cmpstr(DS2,"") != 0)
				AddDAPlot(2)
			endif
			break
	endswitch

	return 0
End

Function DADoneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			DoWindow/K DAPlotPanel
			DoWindow/K DataArithmeticPanel
			break
	endswitch

	return 0
End

Function DAHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			DisplayHelpTopic/Z/K=1 "Data Set Arithmetic"
			if(V_flag !=0)
				DoAlert 0,"The Data Set Arithmetic Help file could not be found"
			endif
			break
	endswitch

	return 0
End

Function DALogLinIProc(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	switch(cba.eventcode)
		case 2:
			
			ModifyGraph/W=DAPlotPanel#DAPlot log(left)=cba.checked
		
	endswitch


End

Function DACursorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String DS1,DS2
	
	switch(ba.eventCode)
		case 2:
		
			ControlInfo/W=$(ba.win) DS1_popup
			DS1 = S_Value
			ControlInfo/W=$(ba.win) DANoDS2_cb
			Variable NoDS2 = V_Value
			if (NoDS2 == 0)
				ControlInfo/W=$(ba.win) DS2_popup
				DS2 = S_Value
			else
				DS2 = "NullSolvent"
			endif
		
			//AJJ Nov 2009 - UGLY - Will have to revisit this when we deal with hierarchical folders
			Wave set1_i = $("root:"+DS1+":"+DS1+"_i")
			Wave set1_q = $("root:"+DS1+":"+DS1+"_q")
			Wave set2_i = $("root:"+DS2+":"+DS2+"_i")
			Wave set2_q = $("root:"+DS2+":"+DS2+"_q")
			Duplicate/O set1_i tmp_i
			Duplicate/O set1_q tmp_q
			tmp_i = set1_i / interp(set1_q[p],set2_q,set2_i)	
			
			//Get cursors
			Variable q1,q2
			
			DoWindow/F DAPlotPanel
			SetActiveSubWindow DAPlotPanel#DAPlot
			
			q1 = CsrXWaveRef(A)[pcsr(A)]
			q2 = CsrXWaveRef(B)[pcsr(B)]

			//Update value display
			ValDisplay DARangeStar_vd,value=_NUM:q1, win=$(ba.win)
			ValDisplay DARangeEnd_vd,value=_NUM:q2, win=$(ba.win)
			
			//Calculate scalefactor
			
			if (NoDS2 == 1)
				Wave avgWave = set1_i
			else
				Wave avgWave = tmp_i
			endif

			Variable p1 = BinarySearch(tmp_q,q1)			
			Variable p2 = BinarySearch(tmp_q,q2)			

			//print avgWave

			WaveStats/Q/R=[p1,p2] avgWave
			//print V_avg
			//Update sv control
			SetVariable DAScale_sv, value=_NUM:V_avg, win=$(ba.win)
			
			KillWaves/Z tmp_i,tmp_q
			DoWindow/F DataArithmeticPanel
	endswitch

End


Function DANoDS2Proc(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba
	
	
	switch(cba.eventCode)
		case 2:
			if (cba.checked == 1)
				//Disable DS2 popup etc
				PopupMenu DS2_popup win=$(cba.win), disable=2
				Button DS2_button win=$(cba.win), disable=2
			else
				//Enable DS2 popup etc
				PopupMenu DS2_popup win=$(cba.win), disable=0
				Button DS2_button win=$(cba.win), disable=0
			endif
			//Sort out plot
			//Fake button press to DAPlotButtonProc
			STRUCT WMButtonAction ba2
			ba2.win = cba.win
			ba2.ctrlName = "DAPlot_button"
			ba2.eventCode = 2
			DAPlotButtonProc(ba2)
			SetActiveSubWindow DAPlotPanel
			DoWindow/F DataArithmeticPanel
	endswitch

End

Function DASaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch(ba.eventCode)
		case 2:
			ControlInfo/W=$(ba.win) DAResultName_sv
			SaveDataSetToFile(S_Value)
			break
	endswitch


End

/////////////////////// Common Panel Functions ///////////////////////////////////////


// is there a simpler way to do this? I don't think so.
Function/S DM_DataSetPopupList()

	String str=GetAList(4)

	if(strlen(str)==0)
		str = "No data loaded"
	endif
	str = SortList(str)
	
	return(str)
End


Function DANameSetvarproc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
				String sv = sva.sval
				if( strlen(sv) > 25 )
					sv= sv[0,24]
					SetVariable  $(sva.ctrlName),win=$(sva.win),value=_STR:sv
					ControlUpdate /W=$(sva.win) $(sva.ctrlName)
					Beep
				endif
				Button DASave_Button win=$(sva.win), disable=2
				break
		endswitch
	return 0
End


////////////////////// Functions to do manipulations ///////////////////////////////////

Function RenameDataSet(dataSetFolder, newName)
	String dataSetFolder
	String newName
	
	String dataSetFolderParent,basestr,objName
	Variable index = 0
	
	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,dataSetFolder,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,dataSetFolder,":",1,0)

//	try
		RenameDataFolder $(dataSetFolder) $(newName)//; AbortOnRTE
	

		SetDataFolder $(dataSetFolderParent+newName)//; AbortOnRTE
		do
			objName = GetIndexedObjName("",1,index)
			if (strlen(objName) == 0)
				break
			endif
			Rename $(objName) $(ReplaceString(basestr,objName,newName))
			index+=1
		while(1)
		SetDataFolder root:
//	catch
//		Print "Aborted: " + num2str(V_AbortCode)
//		SetDataFolder root:
//	endtry
End


Function DuplicateDataSet(dataSetFolder, newName, forceoverwrite)
	String dataSetFolder
	String newName
	Variable forceoverwrite

	String dataSetFolderParent,basestr,objName
	Variable index = 0

	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,dataSetFolder,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,dataSetFolder,":",1,0)
	
	print "Duplicating "+dataSetFolder+" as "+newName
	
	SetDataFolder $(dataSetFolderParent)
	
	if (!DataFolderExists(newName))
		NewDataFolder $(newName)
	else
		if (!forceoverwrite)
			DoAlert 1, "A dataset with the name "+newName+" already exists. Overwrite?"
			if (V_flag == 2)
				return 1
			endif
		endif
	endif	

	//If we are here, the folder (now) exists and the user has agreed to overwrite
	//either in the function call or from the alert.
	do
		objName = GetIndexedObjName(basestr,1,index)
		if (strlen(objName) == 0)
			break
		endif
		objname = ":"+basestr+":"+objname
			Duplicate/O $(objName) $(ReplaceString(basestr,objName,newName))
		index+=1
	while(1)

	SetDataFolder root:
	return 0
End


// Subtract Set2 From Set1
// Use Result_I = Set1_I - f*Set2_I
Function SubtractDataSets(set1Name,set2Name,set2Scale,resultName)
	String set1Name
	String set2Name
	Variable set2Scale
	String resultName

	String set1Path = "root:"+set1Name+":"
	String set2Path = "root:"+set2Name+":"
	String resultPath = "root:"+resultName+":"
	
	SetDataFolder root:
	//Create folder for result
	//UnloadDataSet(resultName)
	//Make the folder
	if (DuplicateDataSet(set1Path,resultName,0)) 
		return 1
	else
	//Do subtraction of I waves - including interpolation if necessary. 
	Wave result_i = $(resultPath+resultName+"_i")
	Wave result_s = $(resultPath+resultName+"_s")
	Wave set1_i = $(set1Path+set1Name+"_i")
	Wave set1_q = $(set1Path+set1Name+"_q")
	Wave set1_s = $(set1Path+set1Name+"_s")
	Wave set2_i = $(set2Path+set2Name+"_i")
	Wave set2_q = $(set2Path+set2Name+"_q")
	Wave set2_s = $(set2Path+set2Name+"_s")
	
	result_i = set1_i - (set2Scale*interp(set1_q[p],set2_q,set2_i))
	result_s = sqrt(set1_s^2 + (set2Scale*interp(set1_q[p],set2_q,set2_s))^2 )
	//Calculate result error wave - can we produce corrected Q error? 
	
	//Generate history string to record what was done?
	return 0
	endif
End

// Add Set2 to Set1
// Use Result_I = Set1_I + f*Set2_I
Function AddDataSets(set1Name,set2Name,set2Scale,resultName)
	String set1Name
	String set2Name
	Variable set2Scale
	String resultName

	String set1Path = "root:"+set1Name+":"
	String set2Path = "root:"+set2Name+":"
	String resultPath = "root:"+resultName+":"
	
	SetDataFolder root:
	//Create folder for result
	if(DuplicateDataSet(set1Path,resultName,0))
		//User said no overwrite
		return 1
	else
	//Do addition of I waves - including interpolation if necessary. 
	Wave result_i = $(resultPath+resultName+"_i")
	Wave result_s = $(resultPath+resultName+"_s")
	Wave set1_i = $(set1Path+set1Name+"_i")
	Wave set1_q = $(set1Path+set1Name+"_q")
	Wave set1_s = $(set1Path+set1Name+"_s")
	Wave set2_i = $(set2Path+set2Name+"_i")
	Wave set2_q = $(set2Path+set2Name+"_q")
	Wave set2_s = $(set2Path+set2Name+"_s")
	
	result_i =  set1_i + set2Scale*interp(set1_q[p],set2_q,set2_i)	
	//Calculate result error wave (note that this is identical to subtraction)
	result_s = sqrt(set1_s^2 + (set2Scale*interp(set1_q[p],set2_q,set2_s))^2 )

	//  - can we produce corrected Q error? 
	//Generate history string to record what was done?
	return 0
	endif
End

// Multiply Set1 by Set2
// Use Result_I  = Set1_I * (f*Set2_I)
Function MultiplyDataSets(set1Name, set2Name, set2Scale, resultName)
	String set1Name
	String set2Name
	Variable set2Scale
	String resultName

	String set1Path = "root:"+set1Name+":"
	String set2Path = "root:"+set2Name+":"
	String resultPath = "root:"+resultName+":"
	
	SetDataFolder root:
	//Create folder for result
	//Make the folder
	if(DuplicateDataSet(set1Path,resultName,0))
		//User said no overwrite
		return 1
	else
	//Do multiplcation of I waves - including interpolation if necessary. 
	Wave result_i = $(resultPath+resultName+"_i")
	Wave result_s = $(resultPath+resultName+"_s")
	Wave set1_i = $(set1Path+set1Name+"_i")
	Wave set1_q = $(set1Path+set1Name+"_q")
	Wave set1_s = $(set1Path+set1Name+"_s")
	Wave set2_i = $(set2Path+set2Name+"_i")
	Wave set2_q = $(set2Path+set2Name+"_q")
	Wave set2_s = $(set2Path+set2Name+"_s")
	
	result_i =  set1_i*set2Scale*interp(set1_q[p],set2_q,set2_i)
	//Calculate result error wave
	// sum each of the relative errors, interpolating set 2 intensity and error as needed
	// then sqrt
	result_s = (set2Scale*interp(set1_q[p],set2_q,set2_i)*set1_s)^2
	result_s += (set2Scale*set1_i*interp(set1_q[p],set2_q,set2_s))^2
	result_s = sqrt(result_s)

	// - can we produce corrected Q error? 

	//Generate history string to record what was done?
	return 0
	endif
End

// Divide Set1 by Set2
// Use Result_I  = Set1_I / (f*Set2_I)
Function DivideDataSets(set1Name, set2Name, set2Scale, resultName)
	String set1Name
	String set2Name
	Variable set2Scale
	String resultName

	String set1Path = "root:"+set1Name+":"
	String set2Path = "root:"+set2Name+":"
	String resultPath = "root:"+resultName+":"
	
	SetDataFolder root:
	//Create folder for result
	//Make the folder
	if(DuplicateDataSet(set1Path,resultName,0))
		//User said no overwrite
		return 1
	else
	//Do division of I waves - including interpolation if necessary. 
	Wave result_i = $(resultPath+resultName+"_i")
	Wave result_s = $(resultPath+resultName+"_s")
	Wave set1_i = $(set1Path+set1Name+"_i")
	Wave set1_q = $(set1Path+set1Name+"_q")
	Wave set1_s = $(set1Path+set1Name+"_s")
	Wave set2_i = $(set2Path+set2Name+"_i")
	Wave set2_q = $(set2Path+set2Name+"_q")
	Wave set2_s = $(set2Path+set2Name+"_s")
	
	result_i =  set1_i/(set2Scale*interp(set1_q[p],set2_q,set2_i)	)
	//Calculate result error wave
	// sum each of the relative errors, interpolating set 2 intensity and error as needed
	// then sqrt
	result_s = (set1_s/set2Scale/interp(set1_q[p],set2_q,set2_i))^2
	result_s += (interp(set1_q[p],set2_q,set2_s)*set1_i/set2Scale/interp(set1_q[p],set2_q,set2_i)^2)^2
	result_s = sqrt(result_s)

	// - can we produce corrected Q error? 
	
	//Generate history string to record what was done?
	return 0
	endif
End


///////////////////////////Other Utility functions ////////////////////////////

Function SaveDataSetToFile(folderName)
	String folderName

	String protoStr = ""
	//Check for history string in folder
	//If it doesn't exist then 

	//Do saving of data file.
	
	NVAR gXML_Write = root:Packages:NIST:gXML_Write 

	if (gXML_Write == 1)
		ReWrite1DXMLData(folderName)
	else
		fReWrite1DData(folderName,"tab","CRLF")
	endif

//	NISTSave1DData(folderName,protoStr)

	//Include history string to record what was done?

End



//////////////////// Write data functions ////////////////////////////////////
// AJJ Nov 2009 - should move towards unified writer
//
//////////////////////////////////////////////////////////////////////////

//Function NISTSave1DData(folderPath,protoStr)
//	String folderPath, protoStr
//	
//	//protoStr is string that will be written to either 
//	
//
//End



///////// SRK - VERY SIMPLE batch converter
// no header information is preserved
// file names are partially preserved
//

/// to use this:
// -open the Plot Manager and set the path
// -run this function
//
// it doesn't matter if the XML ouput flag is set - this overrides.
Function batchXML26ColConvert()

	String list, item,path,fname
	Variable num,ii
	
	PathInfo CatPathName
	path = S_Path

	list = A_ReducedDataFileList("")
	num = itemsInList(list)
	Print num
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list ,";")
		fname=path + item
		Execute "A_LoadOneDDataWithName(\""+fname+"\",0)"		//won't plot
//		easier to load all, then write out, since the name will be changed
	endfor
	
	
	list = DM_DataSetPopupList()

	num = itemsInList(list)
	Print num
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list ,";")
		fReWrite1DData_noPrompt(item,"tab","CR")
	endfor
	
End

// quick version (copied from fReWrite1DData() that NEVER asks for a new fileName
// - and right now, always expect 6-column data, either SANS or USANS (re-writes -dQv)
// - AJJ Nov 2009 : better make sure we always fake 6 columns on reading then....
Function fReWrite1DData_noPrompt(folderStr,delim,term)
	String folderStr,delim,term
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1
	
	String dataSetFolderParent,basestr
	
	//setup delimeter and terminator choices
	If(cmpstr(delim,"tab")==0)
		//tab-delimeted
		formatStr="%15.8g\t%15.8g\t%15.8g\t%15.8g\t%15.8g\t%15.8g"
	else
		//use 3 spaces
		formatStr="%15.8g   %15.8g   %15.8g   %15.8g   %15.8g   %15.8g"
	Endif
	If(cmpstr(term,"CR")==0)
		formatStr += "\r"
	Endif
	If(cmpstr(term,"LF")==0)
		formatStr += "\n"
	Endif
	If(cmpstr(term,"CRLF")==0)
		formatStr += "\r\n"
	Endif
	
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
	
	dialog=0
	if(dialog)
		PathInfo/S catPathName
//		fullPath = DoSaveFileDialog("Save data as",fname=baseStr+".txt")
		fullPath = DoSaveFileDialog("Save data as",fname=baseStr[0,strlen(BaseStr)-2])
		Print fullPath
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	PathInfo catPathName
	fullPath = S_Path + baseStr[0,strlen(BaseStr)-2]

	Open refnum as fullpath
	
	fprintf refnum,"Modified data written from folder %s on %s\r\n",baseStr,(date()+" "+time())
	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs
	Close refnum
	
	KillWaves/Z sigQ,qbar,fs
	
	SetDataFolder root:
	return(0)
End

///////////end SRK