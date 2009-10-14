#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1
#pragma version=4.00

//************************
//
// Utility procedure to allow the user to select exactly which fitting
// functions they wish to include in their experiment. Smearing and plotting
// procedures are automatically included
//
// Functions are now in "SANS Models" Menu, with submenus for
// smeared/unsmeared functions
//
// this change was prompted due to the 31 item limitation of Windows submenus
// resulting in functions being unavailable in the curve fitting dialog
//
// A built-in list of procedure files is included, and should match the current
// distribution package -- see the procedure asdf() for instructions on how
// to update the built-in list of procedures
//
// SRK 091801
//
// Updated for easier use 02 JUL 04 SRK
//
// SRK 16DEC05 added utility function to get the list of all functions
// first - select and include all of the models
//    -- Proc GetAllModelFunctions()
//
// SEE TypeNewModelList() for instructions on how to permanently add new model
// functions to the list... (APR 06 SRK)
//
// added Freeze Model - to duplicate a model function/strip the dependency
// and plot it on the top graph - so that parameters can be changed...
// SRK 09 JUN 2006
//
//***************************

// main procedure for invoking the Procedure list panel
// initializes each time to make sure
Proc ModelPicker_Panel()
	
	DoWindow/F Procedure_List
	if(V_Flag==0)
		Init_FileList()
		Procedure_List()
		AutoPositionWindow/M=1/R=WrapperPanel Procedure_List		//keep it on-screen
	endif
End

// initialization procedure to create the necessary data folder and the waves for
// the list box in the panel
Proc Init_FileList()
	//create the data folders  and globals
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	
	if(!DataFolderExists("root:Packages:NIST:FileList"))
		NewDataFolder/O/S root:Packages:NIST:FileList
		//create the waves
		Make/O/T/N=0 fileWave,includedFileWave
		Make/O/N=0 selWave,selToDelWave
	//	String/G allFiles=""
		String/G MenuItemStr1=""
		String/G MenuItemStr2=""
		//DON'T create MenuItemStr_def 
		
		// a switch for me to turn off file checking
		Variable/G checkForFiles=1		//set to true initially
		
		// always turn off file checking for me
		checkForFiles = !(stringmatch(ParseFilePath(0,SpecialDirPath("Desktop",0,0,0),":",1,1),"s*ine"))		//zero for me
		
		// turn off file checking if the proper alias to the NCNR procedures is there
		PathInfo igor
		NewPath/O/Q tmpUPPath S_Path + "User Procedures"  
		String fileList = IndexedFile(tmpUPPath,-1,"????")
		if(strsearch(fileList, "NCNR_User_Procedures", 0  , 2) != -1)	//ignore case
			checkforfiles = 0
			Print "found the proper procedures"
		endif
		
		//fill the list of procedures
		//
		// first time, create wave from built-in list
		FileList_BuiltInList()		//makes sure that the wave exists
		FileList_GetListButtonProc("")	//converts it into a list for the panel
		
		// "include" nothing to force a load of the utility procedures
		FileList_InsertButtonProc("") 
		

		
		SetDataFolder root:
	Endif
End


// for my own testing to read in a new list of procedures
// FileList_GetListButtonProc("") will only read in a new list
// if the wave SANS_Model_List does not exist
Proc ReadNewProcList()
	KillWaves/Z root:Packages:NIST:FileList:SANS_Model_List		//kill the old list
	FileList_GetListButtonProc("")
End

// To create a new "Built-in" list of procedures, edit the 
// wave SANS_Model_List (a text wave), adding your new procedure names
// (sort alphabetically if desired)
// then use TypeNewModelList() to spit out the text format.
// then paste this list into FileList_BuiltInList
//
// note that you won't have help for these new procedures until 
// you update the function documentation, making the name of the procedure
// file a Subtopic
//
Proc TypeNewModelList()
	variable ii=0,num=numpnts(root:Packages:NIST:FileList:SANS_Model_List)
	printf "Make/O/T/N=%d  SANS_Model_List\r\r",num
	do
		printf "SANS_Model_List[%d] = \"%s\"\r",ii,root:Packages:NIST:FileList:SANS_Model_List[ii]
		ii+=1
	while(ii<num)
End

Proc FileList_BuiltInList()
	SetDataFolder root:Packages:NIST:FileList

////paste here... after deleting the old make statement and list
	
  Make/O/T/N=90  SANS_Model_List

  SANS_Model_List[0] = "BE_Polyelectrolyte.ipf"
  SANS_Model_List[1] = "CoreShellCylinder.ipf"
  SANS_Model_List[2] = "CoreShell_Sq.ipf"
  SANS_Model_List[3] = "CoreShell.ipf"
  SANS_Model_List[4] = "Cylinder_Sq.ipf"
  SANS_Model_List[5] = "Cylinder.ipf"
  SANS_Model_List[6] = "DAB_model.ipf"
  SANS_Model_List[7] = "HPMSA.ipf"
  SANS_Model_List[8] = "HardSphereStruct.ipf"
  SANS_Model_List[9] = "HollowCylinders.ipf"
  SANS_Model_List[10] = "Lorentz_model.ipf"
  SANS_Model_List[11] = "OblateCoreShell_Sq.ipf"
  SANS_Model_List[12] = "OblateCoreShell.ipf"
  SANS_Model_List[13] = "Peak_Gauss_model.ipf"
  SANS_Model_List[14] = "Peak_Lorentz_model.ipf"
  SANS_Model_List[15] = "PolyCoreShellRatio_Sq.ipf"
  SANS_Model_List[16] = "PolyCoreShellRatio.ipf"
  SANS_Model_List[17] = "PolyCore_Sq.ipf"
  SANS_Model_List[18] = "PolyCore.ipf"
  SANS_Model_List[19] = "PolyHardSphereInten.ipf"
  SANS_Model_List[20] = "PolyRectSphere_Sq.ipf"
  SANS_Model_List[21] = "PolyRectSphere.ipf"
  SANS_Model_List[22] = "Power_Law_model.ipf"
  SANS_Model_List[23] = "ProlateCoreShell_Sq.ipf"
  SANS_Model_List[24] = "ProlateCoreShell.ipf"
  SANS_Model_List[25] = "SmearedRPA.ipf"
  SANS_Model_List[26] = "Sphere_Sq.ipf"
  SANS_Model_List[27] = "Sphere.ipf"
  SANS_Model_List[28] = "SquareWellStruct.ipf"
  SANS_Model_List[29] = "StackedDiscs.ipf"
  SANS_Model_List[30] = "Teubner.ipf"
  SANS_Model_List[31] = "UniformEllipsoid_Sq.ipf"
  SANS_Model_List[32] = "UniformEllipsoid.ipf"
  SANS_Model_List[33] = "CoreShellCyl2D.ipf"
  SANS_Model_List[34] = "Cylinder_2D.ipf"
  SANS_Model_List[35] = "Ellipsoid2D.ipf"
  SANS_Model_List[36] = "EllipticalCylinder2D.ipf"
  SANS_Model_List[37] = "Beaucage.ipf"
  SANS_Model_List[38] = "BimodalSchulzSpheres.ipf"
  SANS_Model_List[39] = "BinaryHardSpheres.ipf"
  SANS_Model_List[40] = "Cylinder_PolyLength.ipf"
  SANS_Model_List[41] = "Cylinder_PolyRadius.ipf"
  SANS_Model_List[42] = "Debye.ipf"
  SANS_Model_List[43] = "EllipticalCylinder.ipf"
  SANS_Model_List[44] = "FlexCyl_EllipCross.ipf"
  SANS_Model_List[45] = "FlexCyl_PolyLen.ipf"
  SANS_Model_List[46] = "FlexCyl_PolyRadius.ipf"
  SANS_Model_List[47] = "FlexibleCylinder.ipf"
  SANS_Model_List[48] = "Fractal.ipf"
  SANS_Model_List[49] = "GaussSpheres_Sq.ipf"
  SANS_Model_List[50] = "GaussSpheres.ipf"
  SANS_Model_List[51] = "LamellarFF_HG.ipf"
  SANS_Model_List[52] = "LamellarFF.ipf"
  SANS_Model_List[53] = "LamellarPS_HG.ipf"
  SANS_Model_List[54] = "LamellarPS.ipf"
  SANS_Model_List[55] = "LogNormalSphere_Sq.ipf"
  SANS_Model_List[56] = "LogNormalSphere.ipf"
  SANS_Model_List[57] = "MultiShell.ipf"
  SANS_Model_List[58] = "Parallelepiped.ipf"
  SANS_Model_List[59] = "PolyCoreShellCylinder.ipf"
  SANS_Model_List[60] = "SchulzSpheres_Sq.ipf"
  SANS_Model_List[61] = "SchulzSpheres.ipf"
  SANS_Model_List[62] = "StickyHardSphereStruct.ipf"
  SANS_Model_List[63] = "TriaxialEllipsoid.ipf"
  SANS_Model_List[64] = "Vesicle_UL_and_Struct.ipf"
  SANS_Model_List[65] = "Vesicle_UL.ipf"
  //2008 Models
  SANS_Model_List[66] = "Core_and_NShells.ipf"
  SANS_Model_List[67] = "PolyCore_and_NShells.ipf"
  SANS_Model_List[68] = "Fractal_PolySphere.ipf"
  SANS_Model_List[69] = "GaussLorentzGel.ipf"
  SANS_Model_List[70] = "PolyGaussCoil.ipf"
  SANS_Model_List[71] = "Two_Power_Law.ipf"
  SANS_Model_List[72] = "BroadPeak.ipf"
  SANS_Model_List[73] = "CorrelationLengthModel.ipf"
  SANS_Model_List[74] = "TwoLorentzian.ipf"
  SANS_Model_List[75] = "PolyGaussShell.ipf"
  SANS_Model_List[76] = "LamellarParacrystal.ipf"
  SANS_Model_List[77] = "SC_ParaCrystal.ipf"
  SANS_Model_List[78] = "BCC_ParaCrystal.ipf"
  SANS_Model_List[79] = "FCC_ParaCrystal.ipf"
  SANS_Model_List[80] = "Spherocylinder.ipf"
  SANS_Model_List[81] = "Dumbbell.ipf"
  SANS_Model_List[82] = "ConvexLens.ipf"
  SANS_Model_List[83] = "CappedCylinder.ipf"
  SANS_Model_List[84] = "Barbell.ipf"
  //2009 Models
  SANS_Model_List[85] = "PolyCoreBicelle.ipf"
  SANS_Model_List[86] = "CSParallelepiped.ipf"
  SANS_Model_List[87] = "Fractal_PolyCore.ipf"
  SANS_Model_List[88] = "FuzzySpheres.ipf"
  SANS_Model_List[89] = "FuzzySpheres_Sq.ipf"


  ///end paste here
End

//another way to add a single procedure name to the list
// (only in the current experiment!)
// not a permanent add to the template, unless you re-save the 
// template
Proc AddProcedureToList(ProcedureName)
	String ProcedureName
	
	SetDataFolder root:Packages:NIST:FileList
	Variable num
	num=numpnts(fileWave)
	Redimension/N=(num+1) fileWave
	fileWave[num] = ProcedureName
	num=numpnts(selWave)
	Redimension/N=(num+1) selWave
	selWave[num] = 0
	
	SetDataFolder root:
End
/////////////////////////////////////////////////////////////


Proc doCheck(val)
	Variable val
	// a switch for me to turn off file checking
	root:Packages:NIST:FileList:checkForFiles=val	//0==no check, 1=check	
End


//Function MakeMenu_ButtonProc(ctrlName) : ButtonControl
//	String ctrlName

//	RefreshMenu()
//End

//procedure for drawing the simple panel to pick and compile selected models
//
Proc Procedure_List()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1115,44,1453,363) /K=2
	DoWindow/C Procedure_List
	ModifyPanel fixedSize=1
	
	ListBox fileList,pos={4,3},size={200,203},listWave=root:Packages:NIST:FileList:fileWave
	ListBox fileList,selWave=root:Packages:NIST:FileList:selWave,mode= 4
	ListBox inclList,pos={4,212},size={200,100}
	ListBox inclList,listWave=root:Packages:NIST:FileList:includedFileWave
	ListBox inclList,selWave=root:Packages:NIST:FileList:selToDelWave,mode= 4
	Button button0,pos={212,173},size={110,20},proc=FileList_InsertButtonProc,title="Include File(s)"
	Button button0,help={"Includes the selected procedures, functions appear under the SANS Models menu"}
	Button button5,pos={212,283},size={110,20},proc=FileList_RemoveButtonProc,title="Remove File(s)"
	Button button5,help={"Removes selected procedures from the experiment"}
	Button PickerButton,pos={212,14},size={90,20},proc=FileList_HelpButtonProc,title="Help"
	Button PickerButton,help={"If you need help understanding what a help button does, you really need help"}
	Button button1,pos={212,37},size={100,20},proc=FileList_HelpButtonProc,title="Function Help"
	Button button1,help={"If you need help understanding what a help button does, you really need help"}
	GroupBox group0,pos={203,128},size={46,11},title="Select model functions"
	GroupBox group0_1,pos={203,145},size={46,11},title="to include"
EndMacro


//button function to prompt user to select path where procedures are located
Function FL_PickButtonProc(ctrlName) : ButtonControl
	String ctrlName

	PickProcPath()
End

//bring the help notebook to the front
Function FileList_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName

	if(cmpstr(ctrlName,"PickerButton")==0)		//PickerButton is the picker help
		DisplayHelpTopic/Z/K=1 "SANS Model Picker"
		if(V_flag !=0)
			DoAlert 0,"The SANS Model Picker Help file could not be found"
		endif
		return(0)
	endif
	
	//otherwise, show the help for the selected function	
	//loop through the selected files in the list...
	//
	Wave/T fileWave=$"root:Packages:NIST:FileList:fileWave"
	Wave sel=$"root:Packages:NIST:FileList:selWave"
	
	Variable num=numpnts(sel),ii
	String fname=""
	
//	NVAR doCheck=root:Packages:NIST:FileList:checkForFiles
	ii=num-1		//work bottom-up to not lose the index
	do
		if(sel[ii] == 1)		
				fname = fileWave[ii] //RemoveExten(fileWave[ii])
		endif
		ii-=1
	while(ii>=0)
	
	// nothing selected in the list to include,
	//try the list of already-included files
	if(cmpstr(fname,"")==0)
		Wave/T inclFileWave=$"root:Packages:NIST:FileList:includedFileWave"
		Wave seltoDel=$"root:Packages:NIST:FileList:selToDelWave"
		num=numpnts(seltoDel)
		ii=num-1		//work bottom-up to not lose the index
		do
			if(seltoDel[ii] == 1)		
					fname = inclFileWave[ii] //RemoveExten(fileWave[ii])
			endif
			ii-=1
		while(ii>=0)
	endif
	
	if(cmpstr(fname,"")!=0)
//		Print "show help for ",RemoveExten(fname)
//		Print fname[strlen(fname)-11,strlen(fname)-1]
//		Print fname
		if(cmpstr(fname[strlen(fname)-7,strlen(fname)-1],"_Sq.ipf") ==0 )
			DisplayHelpTopic/Z/K=1 "How Form Factors and Structure Factors are Combined"
			if(V_flag !=0)
				DoAlert 0,"The Help file could not be found"
			endif
		else
			DisplayHelpTopic/Z/K=1 fname
			if(V_flag !=0)
				DoAlert 0,"The Help file could not be found for " + fname
			endif
		endif
	else
		DoAlert 0,"Please select a function from the list to display its help file"
	endif
	
	return(0)
End

//closes the panel when done
Function FileListDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//kill the panel
	DoWindow/K Procedure_List
	return(0)
End

//reads in the list of procedures
// (in practice, the list will be part of the experiment)
// but this can be used to easily update the list if
// new models are added, or if a custom list is desired
// - these lists could also be stored in the template
//
Function FileList_GetListButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String list=""

	if(Exists("root:Packages:NIST:FileList:SANS_Model_List") != 1)
		SetDataFolder root:Packages:NIST:FileList
		LoadWave/A/T
		WAVE/T w=$(StringFromList(0,S_WaveNames,";"))
		SetDataFolder root:
	else
		WAVE/T w=$("root:Packages:NIST:FileList:SANS_Model_List")
	endif
	
//	// convert the input wave to a semi-list
//	SVAR allFiles=root:Packages:NIST:FileList:allFiles
//	allFiles=MP_TextWave2SemiList(w)
	list=MP_TextWave2SemiList(w)
	
	//get the list of available files from the specified path
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii

	// remove the items that have already been included
	Wave/T includedFileWave=$"root:Packages:NIST:FileList:includedFileWave"
	Variable numInc=numpnts(includedFileWave)
	for(ii=0;ii<numInc;ii+=1)
		list = RemoveFromList(includedFileWave[ii],list,";")
	endfor
	list = SortList(list,";",0)
	num=ItemsInList(list,";")
	WAVE/T fileWave=$"root:Packages:NIST:FileList:fileWave"
	WAVE selWave=$"root:Packages:NIST:FileList:selWave"
	Redimension/N=(num) fileWave		//make the waves the proper length
	Redimension/N=(num) selWave
	fileWave = StringFromList(p,list,";")		//converts the list to a wave
	Sort filewave,filewave
	
	return(0)
End

//*******OLD WAY*******
//*******NOT USED*******
//gets the list of files in the folder specified by procPathName
//filters the list to remove some of the procedures that the user does not need to see
// list is assigned to textbox wave
Function OLD_FileList_GetListButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	//make sure that path exists
	PathInfo procPathName
	if (V_flag == 0)
		//Abort "Folder path does not exist - use Pick Path button to set path"
		//build the path to the User Procedures folder
		PathInfo Igor
	//	Print S_Path
		String UserProcStr=S_path+"User Procedures:"
		NewPath/O/Q procPathName  UserProcStr
	Endif
	
	String list=""
//	list=IndexedFile(procPathName,-1,"????")

// new way, to catch all files in all subfolders
	SVAR allFiles=root:Packages:NIST:FileList:allFiles
	allFiles=""		//clear the list

	ListAllFilesAndFolders("procPathName",1,1,0)	//this sets allFiles
	list = allFiles
	
	//get the list of available files from the specified path
	
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii
	//remove procedures from the list the are unrelated, or may be loaded by default (Utils)
	list = RemoveFromList(".DS_Store",list,";")		//occurs on OSX, not "hidden" to Igor
	list = RemoveFromList("GaussUtils.ipf",list,";" )
	list = RemoveFromList("PlotUtils.ipf",list,";" )
	list = RemoveFromList("PlotUtilsMacro.ipf",list,";" )
	list = RemoveFromList("WriteModelData.ipf",list,";" )
	list = RemoveFromList("WMMenus.ipf",list,";" )
	list = RemoveFromList("DemoLoader.ipf",list,";" )
	// remove the items that have already been included
	Wave/T includedFileWave=$"root:Packages:NIST:FileList:includedFileWave"
	Variable numInc=numpnts(includedFileWave)
	for(ii=0;ii<numInc;ii+=1)
		list = RemoveFromList(includedFileWave[ii],list,";")
	endfor
	list = SortList(list,";",0)
	num=ItemsInList(list,";")
	WAVE/T fileWave=$"root:Packages:NIST:FileList:fileWave"
	WAVE selWave=$"root:Packages:NIST:FileList:selWave"
	Redimension/N=(num) fileWave		//make the waves the proper length
	Redimension/N=(num) selWave
	fileWave = StringFromList(p,list,";")		//converts the list to a wave
	Sort filewave,filewave
End

// returns 1 if the file exists, 0 if the file is not there
// fails miserably if there are aliases in the UP folder, although
// the #include doesn't mind
Function CheckFileInUPFolder(fileStr)
	String fileStr

	Variable err=0
	String/G root:Packages:NIST:FileList:allFiles=""
	SVAR allFiles = root:Packages:NIST:FileList:allFiles

	SVAR fileVerExt = root:Packages:NIST:SANS_ANA_EXTENSION

	fileStr = RemoveExten(fileStr)+fileVerExt
	
	PathInfo Igor
	String UPStr=S_path+"User Procedures:"
	NewPath /O/Q/Z UPPath ,UPStr
	ListAllFilesAndFolders("UPPath",1,1,0)	//this sets allFiles
	String list = allFiles
//	err = FindListItem(fileStr, list ,";" ,0)
	err = strsearch(list, fileStr, 0,2)		//this is not case-sensitive, but Igor 5!
//	err = strsearch(list, fileStr, 0)		//this is Igor 4+ compatible
//	Print err
	if(err == -1)
		return(0)
	else
		return(1)		//name was found somewhere
	endif
End


Function FileList_InsertButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	//loop through the selected files in the list...
	Wave/T fileWave=$"root:Packages:NIST:FileList:fileWave"
	Wave sel=$"root:Packages:NIST:FileList:selWave"
	//and adjust the included file lists
	Wave/T includedFileWave=$"root:Packages:NIST:FileList:includedFileWave"
	Wave selToDel=$"root:Packages:NIST:FileList:selToDelWave"

	SVAR fileVerExt=root:Packages:NIST:SANS_ANA_EXTENSION
	
	Variable numIncl=numpnts(includedFileWave)
	Variable num=numpnts(sel),ii,ok
	String fname=""

	//Necessary for every analysis experiment
	Execute/P "INSERTINCLUDE \"PlotUtilsMacro_v40\""
	Execute/P "INSERTINCLUDE \"GaussUtils_v40\""
	Execute/P "INSERTINCLUDE \"WriteModelData_v40\""
	
	NVAR doCheck=root:Packages:NIST:FileList:checkForFiles
	
	ii=num-1		//work bottom-up to not lose the index
	do
		if(sel[ii] == 1)
			//can I make sure the file exists before trying to include it?
			if(doCheck)
				ok = CheckFileInUPFolder(fileWave[ii])
			endif
			if(ok || !doCheck)
				fname = RemoveExten(fileWave[ii])	
				Execute/P "INSERTINCLUDE \""+fname+fileVerExt+"\""
				// add to the already included list, and remove from the to-include list (and selWaves also)
				InsertPoints numpnts(includedFileWave), 1, includedFileWave,selToDel
				includedFileWave[numpnts(includedFileWave)-1]=fileWave[ii]
				
				DeletePoints ii, 1, fileWave,sel
			else
				DoAlert 0,"File "+fileWave[ii]+" was not found in the User Procedures folder, so it was not included"
			endif
		endif
		ii-=1
	while(ii>=0)
//	Execute/P "COMPILEPROCEDURES ";Execute/P/Q/Z "RefreshMenu()"
	Execute/P "COMPILEPROCEDURES "
	
	sel=0		//clear the selections
	selToDel=0
	
	return(0)
End

Function FileList_RemoveButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	//loop through the selected files in the list...
	Wave/T includedFileWave=$"root:Packages:NIST:FileList:includedFileWave"
	Wave selToDel=$"root:Packages:NIST:FileList:selToDelWave"
	// and put the unwanted procedures back in the to-add list
	Wave/T fileWave=$"root:Packages:NIST:FileList:fileWave"
	Wave sel=$"root:Packages:NIST:FileList:selWave"
	
	SVAR fileVerExt=root:Packages:NIST:SANS_ANA_EXTENSION
	
	Variable num=numpnts(selToDel),ii
	String fname="",funcToDelStr=""
	
	ii=num-1		//work backwards
	do
		if(selToDel[ii] == 1)
			fname = RemoveExten(includedFileWave[ii])
			Execute/P "DELETEINCLUDE \""+fname+fileVerExt+"\""
			//add to the to-include list
			InsertPoints numpnts(fileWave), 1, fileWave,sel
			fileWave[numpnts(fileWave)-1]=includedFileWave[ii]
			//delete the point 
			DeletePoints ii, 1, includedFileWave,selToDel
			//
			// could kill dependencies connected to the procedure file, but really not necessary
			//funcToDelStr = FunctionList("*",";","WIN:"+fname+fileVerExt+".ipf")
			//KillAllDependentObjects("root:",funcToDelStr, 1, 1, 0)
			 
		endif
		ii-=1
	while(ii>=0)
	Execute/P "COMPILEPROCEDURES "
	
	sel=0
	selToDel=0
	
	Sort filewave,filewave
	return(0)
End

Function KillDependentVariables(folderStr,funcToDelStr)
	String folderStr,funcToDelStr
	
	String objName,formStr,funcStr,matchStr
	Variable index = 0,loc
	
	do
		objName = GetIndexedObjName(folderStr, 2, index)
		if (strlen(objName) == 0)
			break
		endif
		formStr = GetFormula($(folderStr+objName))
		if(strlen(formStr) != 0)
			loc = strsearch(formStr,"(",0)
			funcStr = formStr[0,loc-1]
//			Print objName,funcStr
			matchStr = ListMatch(funcToDelStr, funcStr ,";")
			if(strlen(matchStr) != 0)
				SetFormula $(folderStr+objName),""		//kill the dependency
				Printf "killed the dependency of %s on the function %s\r",folderStr+objName,matchStr
			endif
				
		endif
				
		index += 1
	while(1)
End



// doesn't really kill all objects...
// kills the dependency formula for any variable that has a formula that contains a function name
// that matches anything in the funcToDelStr, which are functions that are about to be removed
// from the experiment by DELETEINCLUDE
//
// recursively looks through all data folders
//
// on the first call:
// pass "root:" as the pathName
// full = 1
// recurse = 1
// level = 0
//
Function KillAllDependentObjects(pathName,funcToDelStr, full, recurse, level)
	String pathName		// Name of symbolic path in which to look for folders.
	String funcToDelStr		//list of functions to look for
	Variable full			// True to print full paths instead of just folder name.
	Variable recurse		// True to recurse (do it for subfolders too).
	Variable level		// Recursion level. Pass 0 for the top level.
	
	Variable ii
	String prefix
	
//	SVAR allFiles=root:Packages:NIST:FileList:allFiles
	// Build a prefix (a number of tabs to indicate the folder level by indentation)
	prefix = ""
	ii = 0
	do
		if (ii >= level)
			break
		endif
		prefix += "\t"					// Indent one more tab
		ii += 1
	while(1)
	
//	Printf "%s%s\r", prefix, pathName
//	Print IndexedFile($pathName,-1,"????")
	//allFiles += IndexedFile($pathName,-1,"????")
	
	KillDependentVariables(pathName,funcToDelStr)
	
	String path
	ii = 0
	do
		path = GetIndexedObjName(pathName, 4, ii)
		if (strlen(path) == 0)
			break							// No more folders
		endif
		path = pathName+path+":"			//the full path
//		Print "ii, path = ",ii,path

		if (recurse)						// Do we want to go into subfolder?
			KillAllDependentObjects(path, funcToDelStr, full, recurse, level+1)
		endif
		
		ii += 1
	while(1)
End


//removes ANY ".ext" extension from the name
// - wipes out all after the "dot"
// - procedure files to be included (using quotes) must be in User Procedures folder
// and end in .ipf?
Function/S RemoveExten(str)
	String str
	
	Variable loc=0
	String tempStr=""
	
	loc=strsearch(str,".",0)
	tempStr=str[0,loc-1]
	return(tempStr)
End

// function to have user select the path where the procedure files are
//	- the selected path is set as procPathName
//
// setting the path to "igor" does not seem to have the desired effect of 
// bringing up the Igor Pro folder in the NewPath Dialog
//
//may also be able to use folder lists on HD - for more sophisticated listings
Function PickProcPath()
	
	//set the global string to the selected pathname
	PathInfo/S Igor
	
	NewPath/O/M="pick the SANS Procedure folder" procPathName
	return(0)		//no error
End


//my menu, seemingly one item, but really a long string for each submenu
// if root:MenuItemStr exists
//Menu "SANS Models"
//	StrVarOrDefault("root:Packages:NIST:FileList:MenuItemStr_def","ModelPicker_Panel")//, RefreshMenu()
//	SubMenu "Unsmeared Models"
//		StrVarOrDefault("root:Packages:NIST:FileList:MenuItemStr1","ModelPicker_Panel")
//	End
//	SubMenu "Smeared Models"
//		StrVarOrDefault("root:Packages:NIST:FileList:MenuItemStr2","ModelPicker_Panel")
//	End
//	SubMenu "Models 3"
//		StrVarOrDefault("root:MenuItemStr3","ModelPicker_Panel")
//	End
//End

//wrapper to use the A_ prepended file loader from the dynamically defined menu
//Proc LoadSANSorUSANSData()
//	A_LoadOneDData()
//End

//// tweaked to find RPA model which has an extra parameter in the declaration
//Function RefreshMenu()
//
//	String list="",sep=";"
//	
//	//list = "Refresh Menu"+sep+"ModelPicker_Panel"+sep+"-"+sep
//	list = "ModelPicker_Panel"+sep+"-"+sep
////	list += MacroList("LoadO*",sep,"KIND:1,NPARAMS:0")		//data loader
//	list += "Load SANS or USANS Data;"		//use the wrapper above to get the right loader
////	list += "Reset Resolution Waves;"		// resets the resolution waves used for the calculations
////	list += "Freeze Model;"						// freeze a model to compare plots on the same graph
//	list += MacroList("WriteM*",sep,"KIND:1,NPARAMS:4")		//data writer
//	list += "-"+sep
//	String/G root:Packages:NIST:FileList:MenuItemStr_def = TrimListTo255(list)
//	
//	list = ""
//	list += MacroList("*",sep,"KIND:1,NPARAMS:3")				//unsmeared plot procedures
//	list += MacroList("Plot*",sep,"KIND:1,NPARAMS:4")				//RPA has 4 parameters
//	list = RemoveFromList("FreezeModel", list ,";")			// remove FreezeModel, it's not a model
//	//	list += "-"+sep
//	String/G root:Packages:NIST:FileList:MenuItemStr1 = TrimListTo255(list)
//
//	list=""
//	list += MacroList("PlotSmea*",sep,"KIND:1,NPARAMS:1")			//smeared plot procedures
//	list += MacroList("PlotSmea*",sep,"KIND:1,NPARAMS:2")			//smeared RPA has 2 parameters
//	String/G root:Packages:NIST:FileList:MenuItemStr2 = TrimListTo255(list)
//
//	BuildMenu "SANS Models"
//	
//	return(0)
//End

//if the length of any of the strings is more than 255, the menu will disappear
Function/S TrimListTo255(list)
	String list
	
	Variable len,num
	num = itemsinlist(list,";")
	len = strlen(list)
	if(len>255)
		DoAlert 0, "Not all menu items are shown - remove some of the models"
		do
			list = RemoveListItem(num-1, list  ,";" )
			len=strlen(list)
			num=itemsinlist(list,";")
		while(len>255)
	endif
	return(list)
End

Function/S MP_TextWave2SemiList(textW)
	Wave/T textW
	
	String list=""
	Variable num=numpnts(textW),ii=0
	do
		list += textw[ii] + ";"
		ii+=1
	while(ii<num)
	return(list)
End

Function MP_SemiList2TextWave(list,outWStr)
	String list,outWStr
	
	Variable num=itemsinList(list)
	Make/T/O/N=(num) $outWStr
	WAVE/T w=$outWStr
	w = StringFromList(p,list,";")
	return(0)
End

//modified to get a list of all files in folder and subfolders
// passed back through a global variable
Function ListAllFilesAndFolders(pathName, full, recurse, level)
	String pathName		// Name of symbolic path in which to look for folders.
	Variable full			// True to print full paths instead of just folder name.
	Variable recurse		// True to recurse (do it for subfolders too).
	Variable level		// Recursion level. Pass 0 for the top level.
	
	Variable ii
	String prefix
	
	SVAR allFiles=root:Packages:NIST:FileList:allFiles
	// Build a prefix (a number of tabs to indicate the folder level by indentation)
	prefix = ""
	ii = 0
	do
		if (ii >= level)
			break
		endif
		prefix += "\t"					// Indent one more tab
		ii += 1
	while(1)
	
//	Printf "%s%s\r", prefix, pathName
//	Print IndexedFile($pathName,-1,"????")
	allFiles += IndexedFile($pathName,-1,"????")
	
	String path
	ii = 0
	do
		path = IndexedDir($pathName, ii, full)
		if (strlen(path) == 0)
			break							// No more folders
		endif
//		Printf "%s%s\r", prefix, path
		
		if (recurse)						// Do we want to go into subfolder?
			String subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
			
			// Now we get the path to the new parent folder
			String subFolderPath
			if (full)
				subFolderPath = path	// We already have the full path.
			else
				PathInfo $pathName		// We have only the folder name. Need to get full path.
				subFolderPath = S_path + path
			endif
			
			NewPath/Q/O $subFolderPathName, subFolderPath
			ListAllFilesAndFolders(subFolderPathName, full, recurse, level+1)
			KillPath/Z $subFolderPathName
		endif
		
		ii += 1
	while(1)
End


// utility function to get the list of all functions
// first - select and include all of the models
//
Proc GetAllModelFunctions()
	String str =  FunctionList("*",";","KIND:10,NINDVARS:1")
	Print itemsinList(str)

	MP_SemiList2TextWave(str,"UserFunctionList")
	edit UserFunctionList
end

// allows an easy way to "freeze" a model calculation
// - duplicates X and Y waves (tags them _q and _i)
// - kill the dependecy
// - append it to the top graph
// - it can later be exported with WriteModelData
//
// in Igor 5, you can restrict the WaveList to be just the top graph...
// SRK  09 JUN 2006
//
// made data folder-aware in a somewhat messy way, but wavelist works only on the
// current data folder, and WaveSelectorWidget is waaaaaay too complex
//
Function FreezeModel()
	String modelType
	Prompt modelType,"What type of model to freeze? (smeared models use the current data set)",popup,"Unsmeared Model;Smeared Model;"
	DoPrompt "Type of Data",modelType
	
	if(V_Flag==1)		//user canceled
		return(1)
	endif
	
	String xWave,yWave,newNameStr

	SetDataFolder root:
	if(cmpstr(modelType,"Smeared Model")==0)
		ControlInfo/W=WrapperPanel popup_0
		String folderStr=S_Value
		SetDataFolder $("root:"+folderStr)
	
		Prompt xwave,"X data",popup,WaveList("s*",";","")
		Prompt ywave,"Y data",popup,WaveList("s*",";","")
		Prompt newNameStr,"new name for the waves, _q and _i will be appended"
	else
		Prompt xwave,"X data",popup,WaveList("x*",";","")
		Prompt ywave,"Y data",popup,WaveList("y*",";","")
		Prompt newNameStr,"new name for the waves, _q and _i will be appended"
	endif

	DoPrompt "Select the Waves to Freeze",xwave,ywave,newNameStr
	if(V_Flag==1)		//user canceled
		SetDataFolder root:
		return(1)
	endif

	Duplicate/O $xwave,$(newNameStr+"_q")
	Duplicate/O $ywave,$(newNameStr+"_i")
	SetFormula $(newNameStr+"_i"), ""
	
	AppendToGraph $(newNameStr+"_i") vs $(newNameStr+"_q") 
	
	SetDataFolder root:
end