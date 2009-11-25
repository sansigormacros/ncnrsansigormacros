#pragma rtGlobals=1		// Use modern global access method.

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

Function DataManagementPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(459,44,959,364)/N=DataManagementPanel/K=1 as "Data Set Management"
	ModifyPanel fixedSize=1

	//Main bit of panel
	GroupBox grpBox_0,pos={20,10},size={460,50}
	GroupBox grpBox_1,pos={20,80},size={460,200}

	Button DS1_button,pos={300,20},size={150,20},proc=DM_LoadDataSetProc,title="Load 1D Data Set 1"
	PopupMenu DS1_popup,pos={30,21},size={318,20},title="Data Set 1",proc=DMDS_PopMenuProc
	PopupMenu DS1_popup,mode=1,value= #"DM_DataSetPopupList()"

	//Button DS2_button,pos={300,50},size={150,20},proc=DM_LoadDataSetProc,title="Load 1D Data Set 2"
	//PopupMenu DS2_popup,pos={30,51},size={318,20},title="Data Set 2",proc=DMDS_PopMenuProc
	//PopupMenu DS2_popup,mode=1,value= #"DM_DataSetPopupList()"

	//Default to disabled for second data set - only needed for arithmetic
	//Button DS2_button,disable=2
	//PopupMenu DS2_popup,disable=2

	//Tabs
	//TabControl DSTabs,pos={20,90},size={460,200},tabLabel(0)="Management", proc=DSTabsProc
	//TabControl DSTabs,tablabel(1)="Arithmetic"
	//TabControl DSTabs,value=0

	//Management Tab
	Button Rename_button,title="Rename",pos={75,200},size={150,20}
	Button  Duplicate_button,title="Duplicate",pos={275,200},size={150,20}
	Button Save_button,title="Save",pos={75,240},size={150,20}
	Button Unload_button,title="Unload",pos={275,240},size={150,20}
	SetVariable OldName_setvar,title="Old Name",pos={50,100},size={400,20}
	SetVariable OldName_setvar,fsize=12,value=_STR:"",noedit=2
	SetVariable NewName_setvar,title="New Name (max 25 characters)",pos={50,140},size={400,20}
	SetVariable NewName_setvar,fsize=12,value=_STR:"",proc=setvarproc,live=1

End

Function MakeDAPanel()

//	//Set up globals
//	String/G root:Packages:NIST:gDA_DS1Name
//	String/G root:Packages:NIST:gDA_DS2Name
//	String/G root:Packages:NIST:gDA_ResultName	
//
//	String/G root:Packages:NIST:gDA_DS1Trace
//	String/G root:Packages:NIST:gDA_DS2Trace
//	String/G root:Packages:NIST:gDA_ResultTrace	

	
	PauseUpdate; Silent 1		// building window...
	DoWindow/K DataArithmeticPanel
	NewPanel /W=(459,44,959,404)/N=DataArithmeticPanel/K=1 as "Data Set Arithmetic"
	ModifyPanel fixedSize=1

	//Main bit of panel
	GroupBox grpBox_0,pos={20,10},size={460,105}

	Button DS1_button,pos={300,20},size={150,20},proc=DMDA_LoadDataSetProc,title="Load 1D Data Set 1"
	Button DS1_button,valueColor=(65535,0,0),userdata="DS1"
	PopupMenu DS1_popup,pos={30,21},size={318,20},title="Data Set 1"
	PopupMenu DS1_popup,mode=1,value= #"DM_DataSetPopupList()"
	PopupMenu DS1_popup,fsize=12,fcolor=(65535,0,0),valueColor=(65535,0,0)

	Button DS2_button,pos={300,50},size={150,20},proc=DMDA_LoadDataSetProc,title="Load 1D Data Set 2"
	Button DS2_button,valueColor=(0,0,65535),userdata="DS2"
	PopupMenu DS2_popup,pos={30,51},size={318,20},title="Data Set 2"
	PopupMenu DS2_popup,mode=1,value= #"DM_DataSetPopupList()"
	PopupMenu DS2_popup,fsize=12,fcolor=(0,0,65535),valueColor=(0,0,65535)

	Button DSPlot_button,title="Plot",pos={175,85},size={150,20}
	Button DSPlot_button,proc=DSPlotButtonProc


	//Tabs
	TabControl DATabs,pos={20,120},size={460,220},tabLabel(0)="Subtract", proc=DATabsProc
	TabControl DATabs,tablabel(1)="Add",tablabel(2)="Multiply",tablabel(3)="Divide"
	TabControl DATabs,value=0

	Button DACalculate_button,title="Calculate",pos={50,310},size={150,20}
	Button DACalculate_button,proc=DACalculateProc
	Button DASave_button,title="Save Result",pos={300,310},size={150,20}
	Button DACursors_button,title="Get Cursors",pos={175,250},size={150,20}
	SetVariable DAResultName_sv,title="Result Name (max 25 characters)",pos={50,280},size={400,20}
	SetVariable DAResultName_Sv,fsize=12,value=_STR:"SubtractionResult",proc=setvarproc,live=1
	CheckBox DANoDS2_cb,title="Data Set 2 = 1?",pos={300,180}
	
	ValDisplay DARangeStar_vd,title="Start",pos={40,220},size={100,20},fsize=12
	ValDisplay DARangeEnd_vd,title="End  ",pos={160,220},size={100,20},fsize=12
	
	SetVariable DAScale_sv,title="Scale Factor (f)",pos={280,220},size={180,20},fsize=12,value=_NUM:1

	GroupBox grpBox_1,pos={30,210},size={440,70}
	
	NewPanel/HOST=DataArithmeticPanel/N=arithDisplay/W=(50,150,170,190)
	arithDisplayProc(0)
	
End

Function MakeDAPlotPanel()
	PauseUpdate; Silent 1		// building window...
	DoWindow/K DAPlotPanel
	NewPanel /W=(14,44,454,484)/N=DAPlotPanel/K=1 as "Data Set Arithmetic"
	ModifyPanel fixedSize=1

	Display/HOST=DAPlotPanel/N=DAPlot/W=(0,0,440,400)
	SetActiveSubWindow DAPlotPanel
	Checkbox DAPlot_log_cb, title="Log I(q)", pos={20,410}
End


Function DSPlotButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	SVAR DS1name = root:Packages:NIST:gDA_DS1Name
	SVAR DS2name = root:Packages:NIST:gDA_DS2Name
	SVAR Resultname = root:Packages:NIST:gDA_ResultName	
	
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

Function AddDAPlot(dataset)
	Variable dataset
	
	String win = "DataArithmeticPanel"

	switch(dataset)
		case 1:
			ControlInfo/W=$(win) DS1_popup
			String DS1name = S_Value
			Wave qWave = $("root:"+DS1name+":"+DS1name+"_q")
			Wave iWave = $("root:"+DS1name+":"+DS1name+"_i")
			Wave errWave = $("root:"+DS1name+":"+DS1name+"_s")
			AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
			break
		case 2:
			ControlInfo/W=$(win) DS2_popup
			String DS2name = S_Value
			Wave qWave = $("root:"+DS2name+":"+DS2name+"_q")
			Wave iWave = $("root:"+DS2name+":"+DS2name+"_i")
			Wave errWave = $("root:"+DS2name+":"+DS2name+"_s")
			AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
			break
		case 3:
			ControlInfo/W=$(win) DAResultName_sv
			String ResultName = S_Value
			Wave qWave = $("root:"+ResultName+":"+ResultName+"_q")
			Wave iWave = $("root:"+ResultName+":"+ResultName+"_i")
			Wave errWave = $("root:"+ResultName+":"+ResultName+"_s")
			AppendToGraph/W=DAPlotPanel#DAPlot iWave vs Qwave
			break
	endswitch
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
				
				if (cmpstr(popupName,"DS1_popup") ==  0)
					//send fake mouse action to popup to update old name if 
					Struct WMPopupAction pa
					pa.eventCode = 2		//fake mouse up
					pa.win = windowName
					pa.ctrlName = "DS1_popup"
					DMDS_PopMenuProc(pa)
				endif			
			endif
			break
	endswitch
	
	return 0
End

//Must follow naming scheme to match buttons to popups
//"Name_button" goes with "Name_popup"
Function DMDA_LoadDataSetProc(ba) : ButtonControl
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
			break
	endswitch
	
	return 0
End


Function DMDS_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			ControlInfo/W=$(pa.win) $(pa.ctrlName)
			SetVariable OldName_setvar,win=$(pa.win),value=_STR:S_Value
//			ControlInfo/W=$(pa.win) DSTabItem_0e
//			SVAR val = S_Value
//			 
//			ControlInfo/W=$(pa.win) $(pa.ctrlName)
//			val = S_Value

			SetDataFolder root:			
			break
	endswitch

	return 0
End

Function SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
				String sv = sva.sval
				if( strlen(sv) > 25 )
					sv= sv[0,24]
					SetVariable  $(sva.ctrlName),win=$(sva.win),value=_STR:sv
					Beep
				endif
				break
		endswitch
	return 0
End

// is there a simpler way to do this? I don't think so.
Function/S DM_DataSetPopupList()

	String str=GetAList(4)

	if(strlen(str)==0)
		str = "No data loaded"
	endif
	str = SortList(str)
	
	return(str)
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

// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will 
// appear in odd places...
// all buttons are named MainButton_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly..
//
Function DATabsProc(name,tab)
	String name
	Variable tab
	
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
					Button $item,disable=(tab!=onTab)
					break
				case 2:
					CheckBox $item,disable=(tab!=onTab)
					break
				case 3:
					PopUpMenu	$item,disable=(tab!=onTab)
					break
				case 5:
					SetVariable	$item,disable=(tab!=onTab)
					break
			endswitch
		endif
	endfor 
	
	arithDisplayProc(tab)
End


Function DACalculateProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
		
	//Which tab?
	ControlInfo/W=$(ba.win) DATabs
	print V_value
	switch(V_Value)
		case 0:
			print "Doing subtraction"
			//do subtraction
			ControlInfo/W=$(ba.win) DS1_popup
			String DS1 = S_Value
			ControlInfo/W=$(ba.win) DS2_popup
			String DS2 = S_Value
			ControlInfo/W=$(ba.win) DAResultName_sv
			String Resultname = S_Value
			ControlInfo/W=$(ba.win) DAScalefactor_sv
			Variable Scalefactor = V_Value
			SubtractDataSets(DS1,DS2,Scalefactor,Resultname)
		case 1:
			//do addition
		case 2:
			//do multiplication
		case 3:
			//do division
	endswitch
	//Do calculation
	
	
	//Sort out plot
	AddDAPlot(3)

End

/////// Functions to do manipulations /////////

Function RenameDataSet(dataSetFolder, newName)
	String dataSetFolder
	String newName
	
	String dataSetFolderParent,basestr,objName
	Variable index = 0
	
	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,dataSetFolder,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,dataSetFolder,":",1,0)

	try
		RenameDataFolder $(dataSetFolder) $(newName); AbortOnRTE
	

		SetDataFolder $(dataSetFolderParent+newName); AbortOnRTE
		do
			objName = GetIndexedObjName("",1,index)
			if (strlen(objName) == 0)
				break
			endif
			Rename $(objName) $(ReplaceString(basestr,objName,newName))
			index+=1
		while(1)
		SetDataFolder root:
	catch
		Print "Aborted: " + num2str(V_AbortCode)
		SetDataFolder root:
	endtry
End


Function DuplicateDataSet(dataSetFolder, newName)
	String dataSetFolder
	String newName

	String dataSetFolderParent,basestr,objName
	Variable index = 0

	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,dataSetFolder,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,dataSetFolder,":",1,0)
	
	try
		DuplicateDataFolder $(dataSetFolder) $(dataSetFolderParent+newName); AbortOnRTE

		SetDataFolder $(dataSetFolderParent+newName); AbortOnRTE
		do
			objName = GetIndexedObjName("",1,index)
			if (strlen(objName) == 0)
				break
			endif
			Rename $(objName) $(ReplaceString(basestr,objName,newName))
			index+=1
		while(1)
		SetDataFolder root:
	catch
		Print "Aborted: " + num2str(V_AbortCode)
		SetDataFolder root:
	endtry
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


	//Do subtraction of I waves - including interpolation if necessary. 
	//Can we flag when interpolation was necessary?
	//AJJ Nov 2009 - assuming no interpolation user beware!
	Wave result_i = $(resultPath+resultName+"_i")
	Wave set1_i = $(set1Path+set1Name+"_i")
	Wave set2_i = $(set2Path+set2Name+"_i")
	result_i =  set1_i - (set2Scale*set2_i)
	
	//Generate correct result Q wave - including interpolation if necessary
	
	//Calculate result error wave - can we produce corrected Q error? 
	
	//Generate history string to record what was done?

End

// Add Set2 to Set1
// Use Result_I = Set1_I + f*Set2_I
Function AddDataSets(set1Folder,set2Folder,set2Scale,resultName)
	String set1Folder
	String set2Folder
	Variable set2Scale
	String resultName

	//Create folder for result
	
	//Create result waves

	//Do addition of I waves - including interpolation if necessary. 
	//Can we flag when interpolation was necessary?
	
	//Generate correct result Q wave - including interpolation if necessary
	
	//Calculate result error wave - can we produce corrected Q error? 

	//Generate history string to record what was done?

End

// Multiply Set1 by Set2
// Use Result_I  = Set1_I * (f*Set2_I)
Function MultiplyDataSets(set1Folder, set2Folder, set2Scale, resultName)
	String set1Folder
	String set2Folder
	Variable set2Scale
	String resultName

	//Create folder for result
	
	//Create result waves

	//Do multiplcation of I waves - including interpolation if necessary. 
	//Can we flag when interpolation was necessary?
	
	//Generate correct result Q wave - including interpolation if necessary
	
	//Calculate result error wave - can we produce corrected Q error? 

	//Generate history string to record what was done?

End

// Divide Set1 by Set2
// Use Result_I  = Set1_I / (f*Set2_I)
Function DivideDataSets(set1Folder, set2Folder, set2Scale, resultName)
	String set1Folder
	String set2Folder
	Variable set2Scale
	String resultName

	//Create folder for result
	
	//Create result waves

	//Do division of I waves - including interpolation if necessary. 
	//Can we flag when interpolation was necessary?
	
	//Generate correct result Q wave - including interpolation if necessary
	
	//Calculate result error wave - can we produce corrected Q error? 
	
	//Generate history string to record what was done?

End

Function SaveDataSetToFile(folderName)
	String folderName

	//Do saving of data file.

	//Include history string to record what was done?

End


//This will be hideous
Function UnloadDataSet(folderName)
	String folderName

	
End
