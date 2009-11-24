#pragma rtGlobals=1		// Use modern global access method.

// Functions and interfaces to manage datasets now that they are in data folders
// Planned functions:
// - Rename a data set
// - Duplicate a data set
// - Subtract one data set from another
// - Add one data set to another
// - Divide data sets
// - Multiply data sets

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