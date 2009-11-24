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

Window DataManagementPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(459,44,959,364)/N=wrapperPanel/K=1 as "Data Set Management"
	ModifyPanel fixedSize=1

	//Main bit of panel
	GroupBox grpBox_0,pos={20,10},size={460,75}

	Button DS1_button,pos={300,20},size={150,20},proc=DM_LoadDataSetProc,title="Load 1D Data Set 1"
	PopupMenu DS1_popup,pos={30,21},size={318,20},title="Data Set 1",proc=DMDS_PopMenuProc
	PopupMenu DS1_popup,mode=1,value= #"DM_DataSetPopupList()"

	Button DS2_button,pos={300,50},size={150,20},proc=DM_LoadDataSetProc,title="Load 1D Data Set 2"
	PopupMenu DS2_popup,pos={30,51},size={318,20},title="Data Set 2",proc=DMDS_PopMenuProc
	PopupMenu DS2_popup,mode=1,value= #"DM_DataSetPopupList()"

	//Default to disabled for second data set - only needed for arithmetic
	Button DS2_button,disable=2
	PopupMenu DS2_popup,disable=2

	//Tabs
	TabControl DSTabs,pos={20,90},size={460,200},tabLabel(0)="Management", proc=DSTabsProc
	TabControl DSTabs,tablabel(1)="Arithmetic"
	TabControl DSTabs,value=0

	//Management Tab
	Button DSTabItem_0a,title="Rename",pos={75,200},size={150,20}
	Button DSTabItem_0b,title="Duplicate",pos={275,200},size={150,20}
	Button DSTabItem_0c,title="Save",pos={75,240},size={150,20}
	Button DSTabItem_0d,title="Unload",pos={275,240},size={150,20}
	SetVariable DSTabItem_0e,title="Old Name",pos={50,120},size={400,20}
	SetVariable DSTabItem_0e,fsize=12,value=_STR:"",noedit=2
	SetVariable DSTabItem_0f,title="New Name (max 25 characters)",pos={50,150},size={400,20}
	SetVariable DSTabItem_0f,fsize=12,value=_STR:""

EndMacro

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

Function DMDS_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			ControlInfo/W=$(pa.win) $(pa.ctrlName)
			SetVariable DSTabItem_0e,win=$(pa.win),value=_STR:S_Value
	
			SetDataFolder root:			
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
Function DSTabsProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"DSTabItem_"
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,9]
		if(cmpstr(nameStr,"DSTabItem_")==0)
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
	
	//Deal with second data button
	//Make sure this gets changed if the number of the Arithmetic tab changes
	if (tab == 1)
		Button DS2_button,disable=0
		PopupMenu DS2_popup,disable=0
	else
		Button DS2_button,disable=2
		PopupMenu DS2_popup,disable=2
	endif
End


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
Function SubtractDataSets(set1Folder,set2Folder,set2Scale,resultName)
	String set1Folder
	String set2Folder
	Variable set2Scale
	String resultName

	//Create folder for result
	
	//Create result waves

	//Do subtraction of I waves - including interpolation if necessary. 
	//Can we flag when interpolation was necessary?
	
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