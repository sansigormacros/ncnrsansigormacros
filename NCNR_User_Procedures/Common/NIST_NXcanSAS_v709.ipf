#pragma rtGlobals=3		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

#include <HDF5 Browser>

//************************
// Vers 1.15 20171003
//
//************************


///////////////////////////////////////////////////////////////////////////
//
// Basic file open/create and file initialization routines

// Generic open or create file
Function NXcanSAS_OpenOrCreate(dialog,fullpath,base)
	Variable dialog
	String fullpath,base
	Variable fileID
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog(base)
	else
		fileID = NxCansas_CreateFile(fullpath,base)
	Endif
	if(!fileID)
		abort "Unable to create file at " + fullpath + "."
	EndIf
	return fileID
End

// Select/create file through prompt
Function NxCansas_DoSaveFileDialog(base)
	String base
	Variable refNum, fileID
	String message = "Save a file"
	String outputPath
	String fileFilters = "Data Files (*.h5):.h5;"
	fileFilters += "All Files:.*;"
	Open /D /F=fileFilters /M=message refNum
	outputPath = S_fileName
	fileID = NxCansas_CreateFile(outputPath,base)
	return fileID
End

// Create file with a known path
Function NxCansas_CreateFile(fullpath, base)
	String fullpath,base
	Variable fileID
	Make/T/O/N=1 $("root:NXfile_name") = fullpath
	fullpath = ReplaceString(":\\", fullpath, ":")
	fullpath = ReplaceString("\\", fullpath, ":")
	HDF5CreateFile /O/Z fileID as fullpath
	NXCansas_InitializeFile(fileID, base)
	return fileID
End

// Open\ file with a known path
Function NxCansas_OpenFile(fullpath)
	String fullpath
	String fileName
	Variable fileID
	fileName = ParseFilePath(3,fullpath,":",0,0)
	Make/T/O/N=1 $("root:NXfile_name") = fileName
	fullpath = ReplaceString(":\\", fullpath, ":")
	fullpath = ReplaceString("\\", fullpath, ":")
	HDF5OpenFile /Z fileID as fullpath
	return fileID
End

// Select/create file through prompt
Function NxCansas_DoOpenFileDialog()
	Variable refNum,fileID
	String message = "Select a file"
	String inputPath,fileName
	String fileFilters = "Data Files (*.h5):.h5;"
	STRUCT HDF5BrowserData bd
	fileFilters += "All Files:.*;"
	Open /D /F=fileFilters /M=message refNum as fileName
	inputPath = S_fileName
	fileID = NxCansas_OpenFile(inputPath)
	return fileID
End

// Initialize the file to a base state
Function NxCansas_InitializeFile(fileID, base)
	Variable fileID
	String base
	String location,nxParent
	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf location,"%s:sasentry%d",base,sasentry // Igor memory base path for all
	sPrintf nxParent,"/sasentry%d/",sasentry // HDF5 base path for all
	NewDataFolder/O/S $(location)
	Make/O/T/N=1 $(location + ":vals") = {""}
	Make/O/T/N=3 $(location + ":attr") = {"NX_class", "canSAS_class", "version"}
	Make/O/T/N=3 $(location + ":attrVals") = {"NXentry", "SASentry", "1.0"}
	CreateStrNxCansas(fileID,nxParent,"","",$(location + ":vals"),$(location + ":attr"),$(location + ":attrVals"))
	Make/O/T/N=1 $(location + ":entryAttr") = {""}
	Make/O/T/N=1 $(location + ":entryAttrVals") = {""}
	CreateStrNxCansas(fileID,nxParent,"","definition",{"NXcanSAS"},$(location + ":entryAttr"),$(location + ":entryAttrVals"))
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Functions used to save data to file

// Intermediate error handler for saving variable waves - this function should be called instead of saveNxCansas
Function CreateVarNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	Variable err
	err = saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End
// Intermediate error handler for saving string waves - this function should be called instead of saveNxCansas
Function CreateStrNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T valueWave,attr,attrValues
	Variable err
	err = saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End

Function NxCansas_writeAttributes(fileID,path,attrNames,attrVals)
	Variable fileID
	String path
	Wave/T attrNames, attrVals
	int numAttrs,i
	numAttrs = numpnts(attrNames)
	Duplicate/O/T attrNames, names
	Duplicate/O/T attrVals, vals
	
	for(i=0; i < numAttrs; i += 1)
		String name_i = names[i]
		String vals_i = vals[i]
		Make/O/T/N=1 vals_i_wave
		vals_i_wave[0] = vals_i
		if(!CmpStr(name_i,"") == 0)
			HDF5SaveData /A=name_i vals_i_wave, fileID, path
		endif
	endfor
	
End

Function NxCansas_CreateGroup(fileID,parent)
	Variable fileID
	String parent
	Variable groupID
	try	
		if(!fileID)
			abort "HDF5 file does not exist"
		endif
		
		// Create the group if it doesn't already exist
		HDF5CreateGroup /Z fileID, parent, groupID
			
	catch
		// DO something if error is thrown
		Print "NxCansas write err in saveNxCansas = ",V_AbortCode
	endtry
	return groupID
End

// Write in a single NxCansas element (from the STRUCTURE)
// This method should only be called by CreateVarNxCansas
Function saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)

	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)

	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
		
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

// Write in a single NxCansas element
// This method should only be called by CreateStrNxCansas
Function saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T attr,attrValues, valueWave
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)
	
	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
	
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
// NXcanSAS Reader and Utilities

Function LoadNXcanSASData(fileStr,outstr,doPlot,forceOverwrite)
	String fileStr, outstr
	Variable doPlot,forceOverwrite
	
	Variable refnum,fileID
	Variable rr,gg,bb,xdim,ydim
	SetDataFolder root:		//build sub-folders for each data set under root
	
	String filename
	String I_dataS,Q_dataS,dQ_dataS,dQl_dataS,dQw_dataS,dI_dataS
	String angst = StrVarOrDefault("root:Packages:NIST:gAngstStr", "A")
	String/G loadDir = "root:"
	
	// Check fullpath and dialog
	if(stringmatch(fileStr, ""))
		fileID = NxCansas_DoOpenFileDialog()
	else
		fileID = NxCansas_OpenFile(fileStr)
	Endif
	
	filename = ParseFilePath(3,fileStr,":",0,0)
	String basestr
	if (!cmpstr(outstr, ""))		//Outstr = "", cmpstr returns 0
		baseStr = ShortFileNameString(CleanupName(filename,0))
		baseStr = CleanupName(baseStr,0)		//in case the user added odd characters
	else
		baseStr = outstr			//for output, hopefully correct length as passed in
	endif
	String baseFormat = baseStr + "_%d"
	
	if(fileID)
		HDF5ListGroup /F/R/Type=1/Z fileID,"/"
		String groupList = S_HDF5ListGroup
		Variable groupID
		Variable inc=1,ii=0,isMultiData=0,i=0,j=0
		String entryUnformatted = "/sasentry%d/"
		String dataUnformatted = "sasdata%d/"
		String addDigit = "%d"
		String entryBase
		String dataBase = "sasdata/"
		sPrintf entryBase,entryUnformatted,inc
		// Open first group
		HDF5OpenGroup /Z fileID, entryBase + dataBase, groupID
		If (groupID == 0)
			sPrintF dataBase,dataUnformatted,0
			HDF5OpenGroup /z fileID, entryBase + dataBase, groupID
			isMultiData = 1
			sPrintF baseStr,baseformat,0
		EndIf
		
		// Multiple SASentry groups
		do
			//go back to the root folder and clean up before leaving
			// Multiple SASdata groups
			do
				if (isMultiData == 1)
					sPrintF baseStr,baseformat,ii
				EndIf
				loadDir = "root:" + baseStr
				NewDataFolder/O/S $(loadDir)
				// Load in data
				HDF5LoadData /O/Z/N=$(baseStr + "_i") fileID, entryBase + dataBase + "I"
				HDF5LoadData /O/Z/N=$(baseStr + "_q") fileID, entryBase + dataBase + "Q"
				HDF5LoadData /O/Z/N=$(baseStr + "_dq") fileID, entryBase + dataBase + "dQ"
				HDF5LoadData /O/Z/N=$(baseStr + "_dql") fileID, entryBase + dataBase + "dQl"
				HDF5LoadData /O/Z/N=$(baseStr + "_dqw") fileID, entryBase + dataBase + "dQw"
				HDF5LoadData /O/Z/N=$(baseStr + "_s") fileID, entryBase + dataBase + "Idev"
				if (DimSize($(baseStr + "_i"), 1) > 1)
					// Do not auto-plot 2D data
					doPlot = 0
					xdim = DimSize($(baseStr + "_i"), 0)
					ydim = DimSize($(baseStr + "_i"), 1)
					Wave q = $(baseStr + "_q")
					Wave dq = $(baseStr + "_dq")
					
					//
					// FIXME: All points set to the same value - need to loop
					//
					
					Make/O/N=(xdim,ydim) $(baseStr + "_qx")
					Wave qx = $(baseStr + "_qx")
					Make/O/N=(xdim,ydim) $(baseStr + "_qy")
					Wave qy = $(baseStr + "_qy")
					if (numpnts(dq)>0)
						Make/O/N=(xdim,ydim) $(baseStr + "_dqx")
						Wave dqx = $(baseStr + "_dqx")
						Make/O/N=(xdim,ydim) $(baseStr + "_dqy")
						Wave dqy = $(baseStr + "_dqy")
					EndIf
					for(i=0; i < xdim; i += 1)
						for(j=0; j < ydim; j +=1)
							qx[i][j] = q[0][i][j]
							qy[i][j] = q[1][i][j]
							if (numpnts(dq)>0)
								dqx[i][j] = dq[0][i][j]
								dqy[i][j] = dq[1][i][j]
							EndIf
						endFor
					endFor
					
					KillWaves $(baseStr + "_q")
				EndIf
				if (isMultiData)
					sprintf dataBase,dataUnformatted,ii
					// Open next group to see if it exists
					HDF5OpenGroup /Z fileID, entryBase + dataBase, groupID
				else
					groupID = 0
				endIf
				ii += 1
				// Load in Meta Data
				LoadMetaData(fileID,loadDir,entryBase)
			while (groupID != 0)
			inc += 1
			If (isMultiData)
				sprintf dataBase,dataUnformatted,ii
			endIf
			// Open next group to see if it exists
		sPrintf entryBase,entryUnformatted,inc
			HDF5OpenGroup /Z fileID, entryBase + dataBase, groupID
		while(groupID != 0)
		
		//plot if desired
		if(doPlot)
			Print GetDataFolder(1)
			
			String w0 = (baseStr + "_q")
			String w1 = (baseStr + "_i")
			String w2 = (baseStr + "_s")
			
			// assign colors randomly
			rr = abs(trunc(enoise(65535)))
			gg = abs(trunc(enoise(65535)))
			bb = abs(trunc(enoise(65535)))
			
			// if target window is a graph, and user wants to append, do so
		   DoWindow/B Plot_Manager
			if(WinType("") == 1)
				DoAlert 1,"Do you want to append this data to the current graph?"
				
				if(V_Flag == 1)
					AppendToGraph $w1 vs $w0
					ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
					ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
					ModifyGraph tickUnit(left)=1
				else
				//new graph
					Display $w1 vs $w0
					ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
					ModifyGraph grid=1,mirror=2,standoff=0
					ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
					ModifyGraph tickUnit(left)=1
					Label left "I(q)"
					Label bottom "q ("+angst+"\\S-1\\M)"
					Legend
				endif
			else
			// graph window was not target, make new one
				Display $w1 vs $w0
				ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
				ModifyGraph grid=1,mirror=2,standoff=0
				ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
				ModifyGraph tickUnit(left)=1
				Label left "I(q)"
				Label bottom "q ("+angst+"\\S-1\\M)"
				Legend
			endif
		endif
	endif
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif

end

Function LoadMetaData(fileID,loadDir,parentBase)
	String parentBase,loadDir
	Variable fileID
	Variable groupID
	SetDataFolder $(loadDir)
	Make/O/N=52 $(loadDir + ":realsRead")
	Make/O/T/N=11 $(loadDir + ":textRead")
	Wave rw = $(loadDir + ":realsRead")
	Wave/T textw = $(loadDir + ":textRead")
	int isMultiDetector = 0, ii = 0
	
	// Title
	HDF5OpenGroup /Z fileID, parentBase, groupID
	HDF5LoadData /O/Z/N=title fileID, parentBase + "title"
	Wave/T title = $(loadDir + ":title")
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	
	// SASaperture
	String apertureParent = instrParent + "sasaperture/"
	HDF5OpenGroup /Z fileID, apertureParent, groupID
	HDF5LoadData /O/Z/N=xg fileID, apertureParent + "x_gap"
	Wave xg = $(loadDir + ":xg")
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	HDF5OpenGroup /Z fileID, collimationParent, groupID
	HDF5LoadData /O/Z/N=cdis fileID, collimationParent + "distance"
	Wave cdis = $(loadDir + ":cdis")
	
	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	HDF5OpenGroup /Z fileID, detectorParent, groupID
	If (groupID == 0)
		isMultiDetector = 1
		ii = 1
		String detectorUnformatted = "sasdetector%d/"
		sprintf detectorParent,instrParent + detectorUnformatted,ii
		HDF5OpenGroup /Z fileID, detectorParent, groupID
	EndIf
	do
		HDF5LoadData /O/Z/N=detname fileID, detectorParent + "name"
		HDF5LoadData /O/Z/N=sdd fileID, detectorParent + "SDD"
		HDF5LoadData /O/Z/N=bcx fileID, detectorParent + "beam_center_x"
		HDF5LoadData /O/Z/N=bcy fileID, detectorParent + "beam_center_y"
		HDF5LoadData /O/Z/N=xps fileID, detectorParent + "x_pixel_size"
		HDF5LoadData /O/Z/N=xpy fileID, detectorParent + "y_pixel_size"
		Wave/T detname = $(loadDir + ":detname")
		Wave sdd = $(loadDir + ":sdd")
		Wave bcx = $(loadDir + ":bcx")
		Wave bcy = $(loadDir + ":bcy")
		Wave xps = $(loadDir + ":xps")
		Wave xpy = $(loadDir + ":xpy")
		If (isMultiDetector)
			ii += 1
			sprintf detectorParent,instrParent + detectorUnformatted,ii
			HDF5OpenGroup /Z fileID, detectorParent, groupID
		Else
			groupID = 0
		EndIf
	while (groupID != 0)
	
	// SASsource
	String sourceParent = instrParent + "sassource/"
	HDF5OpenGroup /Z fileID, sourceParent, groupID
	HDF5LoadData /O/Z/N=wvel fileID, sourceParent + "incident_wavelength"
	HDF5LoadData /O/Z/N=wvels fileID, sourceParent + "incident_wavelength_spread"
	Wave wvel = $(loadDir + ":wvel")
	Wave wvels = $(loadDir + ":wvels")
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	HDF5OpenGroup /Z fileID, sampleParent, groupID
	HDF5LoadData /O/Z/N=smplname fileID, sampleParent + "name"
	HDF5LoadData /O/Z/N=smplthick fileID, sampleParent + "thickness"
	HDF5LoadData /O/Z/N=smpltrans fileID, sampleParent + "transmission"
	Wave/T smplname = $(loadDir + ":smplname")
	Wave smplthick = $(loadDir + ":smplthick")
	Wave smpltrans = $(loadDir + ":smpltrans")
	
	textw[0] = title[0]
	textw[6] = smplname[0]
	textw[9] = detname[0]
	rw[4] = smplthick[0]
	rw[5] = smpltrans[0]
	rw[10] = xps[0]
	rw[13] = xpy[0]
	rw[16] = bcx[0]
	rw[17] = bcy[0]
	rw[18] = sdd[0]
	rw[24] = xg[0]
	rw[25] = cdis[0]
	rw[26] = wvel[0]
	rw[27] = wvels[0]
	
	KillWaves title,smplname,detname,smplthick,smpltrans,xps,xpy,bcx,bcy,sdd,xg,cdis,wvel,wvels
	
End

//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
//
// Generic Read/Write operations.

//Needed to test whether file is NXcanSAS. The load routine will then either give an error if HDF5 XOP is not present or load the file if it is.
Function isNXcanSAS(filestr)
	String filestr
	
	Variable fileID=0,groupID=0
	Int isHDF5File = 0
	
	fileID = NxCansas_OpenFile(filestr)
	HDF5ListGroup /F/R/Type=1/Z fileID,"/"
	Variable length = strlen(S_HDF5ListGroup)
	
	if (numtype(length) != 2)
		isHDF5File = 1
	endif
	
	if (fileID != 0)
		// Close the file
		HDF5CloseFile /Z fileID
	endif
	
	return isHDF5File

end

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
// Methods related to NSORT

Function WriteNSORTedNXcanSASFile(qw,iw,sw,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,[res])
	Wave qw,iw,sw,res
	String firstFileName,secondFileName,thirdFileName,fourthFileName,normTo
	Variable norm12,norm23,norm34
	
	Variable err=0,refNum,numCols,dialog=1,useRes=0
	String fullPath="",formatStr="",process
	
	//check each wave - else REALLY FATAL error when writing file
	If(!(WaveExists(qw)))
		err = 1
		return err
	Endif
	If(!(WaveExists(iw)))
		err = 1
		return err
	Endif
	If(!(WaveExists(sw)))
		err = 1
		return err
	Endif
	if(WaveExists(res))
		useRes = 1
	endif
	
	NVAR/Z useTable = root:myGlobals:CombineTable:useTable
	if(NVAR_Exists(useTable) && useTable==1)
		SVAR str=root:myGlobals:CombineTable:SaveNameStr	//messy, but pass in as a global
		fullPath = str
		dialog=0
	endif
	
	NewDataFolder/O/S root:Packages:NIST:NSORT
	SetDataFolder root:Packages:NIST:NSORT
	
	process = CreateNSORTProcess(firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
	Make/O/T/N=1 processNote = process
	
	Variable pts = numpnts(qw)
	Make/O/N=(pts) qval = qw
	Make/O/N=(pts) aveint = iw
	Make/O/N=(pts) sigave = sw
	if (useRes)
		Make/O/N=(dimsize(res,0)) SigmaQ = res[p][0]
		Make/O/N=(dimsize(res,0)) QBar = res[p][1]
		Make/O/N=(dimsize(res,0)) fSubS = res[p][2]
	Else
		Make/O/N=(pts) SigmaQ = 0
		Make/O/N=(pts) QBar = 0
		Make/O/N=(pts) fSubS = 0
	EndIf
	
	Make/O/T/N=11 textRead
	textRead[6] = firstfileName
	textRead[0] = "Combined data"
	
	Make/O/N=52 realsRead = 0
	
	WriteNxCanSAS1D("NSORT",fullpath,dialog)
	
End

Function/T CreateNSORTProcess(firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
	String firstFileName,secondFileName,thirdFileName,fourthFileName,normTo
	Variable norm12,norm23,norm34
	String process
	String processFormat = "COMBINED FILE CREATED: %s - NSORT-ed %s\t+ %s\t+ %s\t+%s, normalized to %s, multiplicative factor 1-2 = %12.8g\t multiplicative factor 2-3 = %12.8g\t multiplicative factor 3-4 = %12.8g"
	
	sprintf process,processFormat,date(),firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34
	return process
End

//
///////////////////////////////////////////////////////////////////////////