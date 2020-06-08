#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 7.00

//
// ********
// TODO -- figure out how much of this file is really used, and how much is
//    simply garbage now. I make "fake" data files by starting with a real data file
//    written from NICE, and then I re-write proper values and data arrays to it from 
//    simulations in VCALC. So I do not need to define the structure myself.
//
//   JAN 2017
//
//
//
//
//

//
// This file has utility procedures to be able to read/write
// test HDF5 (from Igor) for SANS and VSANS in Nexus format
//
// It is predominantly to be able to WRITE a full Nexus file from Igor
// -- this is only necessary to be able to write out "fake" VSANS files from VCALC
//    since I need a "template" of the Nexus folder structure to start from and fill in
//
// It doesn't reproduce the NICE logs, but will leave a space for them if
// it is read in and is part of the xref.
//
// It may be easier to hard-wire my own folder definition (NewDataFolder)
// that is MY Nexus file to write out and use that as the base case
// rather than rely on Pete's code, which is terribly slow for writing.
// Attributes are the issue, but it may be unimportant if they are missing.
//



//
// There's an odd sequence of steps that need to be done to use HDFGateway
// to most easily write out attributes, and be able to read then back in.
// Rather awkward, but it works without me needing to go nuts with an atomistic
// understanding of HDF5. This is necessary for me to be able to write out
// Nexus files, which is important both for testing, and for simulation.
//
// This is done as a set of macros that need to be applied in a specific sequence
// in order to be able to generate HDF5___xref
// Ideally, the HDF5___xref wave can be saved/imported to make proper saving possible
// once the "tree" is finalized.
//
//
// The basic saving routines are here, just as Proc rather than Macro menu clutter
//

//

//
// FEB 2017: All that is functional right now is the Setup/save of DIV and MASK files, and the attribute routines.
//
// The DIV and MASK routines are in their respective procedure files, and call save functions for the simplified
// Nexus structure (in V_HDF5_RW_Utils.ipf).
//
// The R/W with attributes is part of the HDF5 Gateway procedure from Pete Jemain, and needs to be kept and functional
// to be able to work with attributes - if needed.
//





/////////////////////////////



Proc Load_Nexus_V_Template()
	H_HDF5Gate_Read_Raw("")
	String tmpStr=root:file_name  //SRK - so I can get the file name that was loaded
	
// this is the folder name
	String base_name = StringFromList(0,File_Name,".")
	RenameDataFolder $("root:"+base_name), V_Nexus_Template
End


Proc Fill_Nexus_V_Template()
	H_Fill_VSANS_Template_wSim()
End


Proc Save_Nexus_V_Template()
	H_HDF5Gate_Write_Raw("root:V_Nexus_Template:","")
End



/////////////below is largely depricated, ugly dance to be able to "fake" a file from Igor
// which was not complete anyways.




Proc IgorOnly_Setup_VSANS_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_VSANS_Structure()
	
	// writes in the attributes
	H_Fill_VSANS_Attributes()
	
	// fill in with VCALC simulation bits
	H_Fill_VSANS_wSim()
	
End

Proc IgorOnly_Save_VSANS_Nexus(fileName)
	String fileName="Test_VSANS_file"

	// save as HDF5 (no attributes saved yet)
	Save_VSANS_file("root:VSANS_file", fileName+".h5")
	
	// read in a data file using the gateway-- reads from the home path
	H_HDF5Gate_Read_Raw(fileName+".h5")
	
	// after reading in a "partial" file using the gateway (to generate the xref)
	// Save the xref to disk (for later use)
	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
	
	// after you've generated the HDF5___xref, load it in and copy it
	// to the necessary folder location.
	Copy_HDF5___xref("root:VSANS_file", "HDF5___xref")
	
	// writes out the contents of a data folder using the gateway
	H_HDF5Gate_Write_Raw("root:VSANS_file", fileName+".h5")

	// re-load the data file using the gateway-- reads from the home path
	// now with attributes
	H_HDF5Gate_Read_Raw(fileName+".h5")
	
End



Proc IgorOnly_Setup_SANS_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_SANS_Structure()
	
	// writes in the attributes
	H_Fill_SANS_Attributes()
	
	// fill in with VCALC simulation bits
	H_Fill_SANS_wSim()

End

Proc IgorOnly_Save_SANS_Nexus(fileName)
	String fileName="Test_SANS_file"
	
	// save as HDF5 (no attributes saved yet) (save_VSANS is actually generic HDF...)
	Save_VSANS_file("root:SANS_file", fileName+".h5")
	
	// read in a data file using the gateway-- reads from the home path
	H_HDF5Gate_Read_Raw(fileName+".h5")
	
	// after reading in a "partial" file using the gateway (to generate the xref)
	// Save the xref to disk (for later use)
	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
	
	// after you've generated the HDF5___xref, load it in and copy it
	// to the necessary folder location.
	Copy_HDF5___xref("root:SANS_file", "HDF5___xref")
	
	// writes out the contents of a data folder using the gateway
	H_HDF5Gate_Write_Raw("root:SANS_file", fileName+".h5")

	// re-load the data file using the gateway-- reads from the home path
	// now with attributes
	H_HDF5Gate_Read_Raw(fileName+".h5")


End



















// passing null file string presents a dialog
// these two procedures will use the full Xrefs, so they can write out full
// files. They are, however, slow
Proc Read_Nexus_Xref()
	H_HDF5Gate_Read_Raw("")
End

Proc Write_Nexus_Xref()
	H_HDF5Gate_Write_Raw()
End

//
// writes out the contents of a data folder using the gateway
// -- the HDF5___xref wave must be present at the top level for it to
//    write out anything.
//
Proc H_HDF5Gate_Write_Raw(dfPath,filename)
	String dfPath	= "root:"	// e.g., "root:FolderA" or ":"
	String filename = "Test_VSANS_file.h5"
//	Prompt dfPath, "Data Folder",popup,H_GetAList(4)	
//	Prompt fileName, "File name"
	
//	DoPrompt "Folder and file to write", dfPath,fileName
	// Check our work so far.
	// If something prints, there was an error above.
//	print H5GW_ValidateFolder(dfPath)

// H5GW_WriteHDF5 calls the validate function, so no need to call it before
	print H5GW_WriteHDF5(dfPath, filename)
	
	SetDataFolder root:
End

//
// read in a data file using the gateway
//
// reads from the home path
//
Proc H_HDF5Gate_Read_Raw(file)
	String file
	
//	NewDataFolder/O/S root:newdata
	Print H5GW_ReadHDF5("", file)	// reads into current folder
	SetDataFolder root:
End



// this is in PlotUtils, but duplicated here
// utility used in the "PlotSmeared...() macros to get a list of data folders
//
//1:	Waves.
//2:	Numeric variables.
//3:	String variables.
//4:	Data folders.
Function/S H_GetAList(type)
	Variable type
	
	SetDataFolder root:
	
	String objName,str=""
	Variable index = 0
	do
		objName = GetIndexedObjName(":", type, index)
		if (strlen(objName) == 0)
			break
		endif
		//Print objName
		str += objName + ";"
		index += 1
	while(1)
	
	// remove myGlobals, Packages, etc. from the folder list
	if(type==4)
		str = RemoveFromList("myGlobals", str , ";" )
		str = RemoveFromList("Packages", str, ";")
	endif
	
	return(str)
End

//
// after reading in a "partial" file using the gateway (to generate the xref)
// Save the xref to disk (for later use)
// 
Proc Save_HDF5___xref(dfPath, filename)
	String dfPath	="root:VSANS_file"		// e.g., "root:FolderA" or ":"
	String filename = "HDF5___xref"

	Save/T/P=home $(dfPath+":HDF5___xref") as "HDF5___xref.itx"

//	Copy_HDF5___xref(dfPath, filename)
	
	SetDataFolder root:
End

// 
// after you've generated the HDF5___xref, load it in and copy it to
// the necessary folder location.
// - then all is set to *really* write out the file correctly, including the attributes
//
Proc Copy_HDF5___xref(dfPath, filename)
	String dfPath	="root:VSANS_file"		// e.g., "root:FolderA" or ":"
	String filename = "HDF5___xref"

	if(exists(filename) != 1)
		//load it in	
		LoadWave/T/P=home/O "HDF5___xref.itx"
	endif
	
	Duplicate/O HDF5___xref, $(dfPath+":HDF5___xref")
	
	SetDataFolder root:
End



//////// testing procedures, may be of use, maybe not //////////////


//////// Two procedures that test out Pete Jemain's HDF5Gateway
//
// This works fine, but it may not be terribly compatible with the way NICE will eventually
// write out the data files. I'll have very little control over that and I'll need to cobble together
// a bunch of fixes to cover up their mistakes.
//
// Using Nick Hauser's code as a starting point may be a lot more painful, but more flexible in the end.
//
// I'm completely baffled about what to do with attributes. Are they needed, is this the best way to deal
// with them, do I care about reading them in, and if I do, why?
//
Proc H_HDF5Gate_WriteTest()

	// create the folder structure
	NewDataFolder/O/S root:mydata
	NewDataFolder/O sasentry
	NewDataFolder/O :sasentry:sasdata

	// create the waves
	Make/O :sasentry:sasdata:I0
	Make/O :sasentry:sasdata:Q0

	Make/O/N=0 Igor___folder_attributes
	Make/O/N=0 :sasentry:Igor___folder_attributes
	Make/O/N=0 :sasentry:sasdata:Igor___folder_attributes

	// create the attributes
	Note/K Igor___folder_attributes, "producer=IgorPro\rNX_class=NXroot"
	Note/K :sasentry:Igor___folder_attributes, "NX_class=NXentry"
	Note/K :sasentry:sasdata:Igor___folder_attributes, "NX_class=NXdata"
	Note/K :sasentry:sasdata:I0, "units=1/cm\rsignal=1\rtitle=reduced intensity"
	Note/K :sasentry:sasdata:Q0, "units=1/A\rtitle=|scattering vector|"

	// create the cross-reference mapping
	Make/O/T/N=(5,2) HDF5___xref
	Edit/K=0 'HDF5___xref';DelayUpdate
	HDF5___xref[0][1] = ":"
	HDF5___xref[1][1] = ":sasentry"
	HDF5___xref[2][1] = ":sasentry:sasdata"
	HDF5___xref[3][1] = ":sasentry:sasdata:I0"
	HDF5___xref[4][1] = ":sasentry:sasdata:Q0"
	HDF5___xref[0][0] = "/"
	HDF5___xref[1][0] = "/sasentry"
	HDF5___xref[2][0] = "/sasentry/sasdata"
	HDF5___xref[3][0] = "/sasentry/sasdata/I"
	HDF5___xref[4][0] = "/sasentry/sasdata/Q"

	// Check our work so far.
	// If something prints, there was an error above.
	print H5GW_ValidateFolder("root:mydata")

	// set I0 and Q0 to your data

	print H5GW_WriteHDF5("root:mydata", "mydata.h5")
	
	SetDataFolder root:
End


//
// given a filename of a VSANS data file of the form
// name.anything.any.other (any number of extensions is OK)
// returns the name as a string without ANY ".fbdfasga" extension
//
// returns the input string if a "." can't be found (maybe it wasn't there)
//
Function/S H_RemoveDotExtension(item)
	String item
	String invalid = item	//
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get all of the characters preceeding it
		runStr = item[0,pos-1]
		return (runStr)
	Endif
End


//
// Writing attributes to a group and to a dataset.
// example from the WM documentation for HDF5SaveData
//
Function DemoAttributes(w)
	Wave w

	Variable result = 0	// 0 means no error
	
	// Create file
	Variable fileID
	HDF5CreateFile/P=home /O /Z fileID as "Test.h5"
	if (V_flag != 0)
		Print "HDF5CreateFile failed"
		return -1
	endif

	// Write an attribute to the root group
	Make /FREE /T /N=1 groupAttribute = "This is a group attribute"
	HDF5SaveData /A="GroupAttribute" groupAttribute, fileID, "/"
	
	// Save wave as dataset
	HDF5SaveData /O /Z w, fileID	// Uses wave name as dataset name
	if (V_flag != 0)
		Print "HDF5SaveData failed"
		result = -1
	endif

	// Write an attribute to the dataset
	Make /FREE /T /N=1 datasetAttribute = "This is a dataset attribute"
	String datasetName = NameOfWave(w)
	HDF5SaveData /A="DatasetAttribute" datasetAttribute, fileID, datasetName

	HDF5CloseFile fileID
	
	return result
End	// The attribute waves are automatically killed since they are free waves



//	
//Function H_Test_HDFWriteTrans(fname,val)
//	String fname
//	Variable val
//	
//	
//	String str
//	PathInfo home
//	str = S_path
//	
//	H_WriteTransmissionToHeader(str+fname,val)
//	
//	return(0)
//End
//
//Function H_WriteTransmissionToHeader(fname,trans)
//	String fname
//	Variable trans
//	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
//
//	variable err
//	err = HDFWrite_Wave(fname, groupName, varName, wTmpWrite)
//	KillWaves wTmpWrite
//	
//	//err not handled here
//		
//	return(0)
//End



Function H_Test_ListAttributes(fname,groupName)
	String fname,groupName
	Variable trans
	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
	String str
	PathInfo home
	str = S_path
	
	variable err
	err = H_HDF_ListAttributes(str+fname, groupName)
	
	//err not handled here
		
	return(0)
End

Function H_HDF_ListAttributes(fname, groupName)
	String fname, groupName
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name, attrValue=""
	
	STRUCT HDF5DataInfo di	// Defined in HDF5 Browser.ipf.
	InitHDF5DataInfo(di)	// Initialize structure.
	
	try	
		HDF5OpenFile /Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		HDF5OpenGroup /Z fileID , groupName, groupID

	//	(QUOKKA) !! At the moment, there is no entry for sample thickness in our data file
	//	therefore create new HDF5 group to enable write / patch command
	//	comment out the following group creation once thickness appears in revised file
	
		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else

//			HDF5AttributeInfo(fileID, "/", 1, "file_name", 0, di)
			HDF5AttributeInfo(fileID, "/", 1, "NeXus_version", 0, di)
			Print di

//			see the HDF5 Browser  for how to get the actual <value> of the attribute. See GetPreviewString in 
//        or in FillGroupAttributesList or in FillDatasetAttributesList (from FillLists)
//			it seems to be ridiculously complex to get such a simple bit of information - the HDF5BrowserData STRUCT
// 			needs to be filled first. Ugh.
			attrValue = GetPreviewString(fileID, 1, di, "/entry", "cucumber")
			Print "attrValue = ",attrValue
			
			
			//get attributes and save them
			HDF5ListAttributes/TYPE=1 /Z fileID, groupName 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
			
			// passing the groupID works too, then the group name is not needed			
			HDF5ListAttributes/TYPE=1 /Z groupID, "." 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
		endif
	catch

		// catch any aborts here
		
	endtry
	
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif
	
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	setDataFolder $cDF
	return err
end


/////////////// end of the testing procedures ////////////////
