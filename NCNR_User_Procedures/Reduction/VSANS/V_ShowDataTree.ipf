#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//
// This is a copy (wtih slight modifications) of the DataFolderTree_SRK.ipf file
// which itself is from Igor Exchange (see below)
//
// it is modified to look for VSANS files, and ignore the DAS_log folder if possible
// since it's not part of the file I'm concerned with during reduction.
//
//

////////
// see the help entry for IndexedDir for help on (possibly) how to do this faster
// -- see the function Function ScanDirectories(pathName, printDirNames)
//


// from IgorExchange On July 17th, 2011 jtigor
// started from "Recursively List Data Folder Contents"
// Posted July 15th, 2011 by hrodstein

Proc V_ShowDataFolderTree(dataFolderStr, level, sNBName)
//	String dataFolderStr="root:"
	String dataFolderStr="root:Packages:NIST:VSANS:RawVSANS:"
	Variable level=0
	String sNBName="DataFolderTree"
	
	V_ListDataFolder($dataFolderStr, level, sNBName)


end

// ListDataFolder(dfr, level)
// Recursively lists objects in data folder.
// Pass data folder path for dfr and 0 for level.
// Example: ListDataFolder(root:, 0, "NoteBook")
//Start with sNBName = "" to print to history
Function V_ListDataFolder(dfr, level, sNBName)
	DFREF dfr
	Variable level			// Pass 0 to start
 	String sNBName
 
	String name
 	String sString
 
	if (level == 0)
		name = GetDataFolder(1, dfr)
		sPrintf sString, "%s (data folder)\r", name
		V_WriteBrowserInfo(sString, 1, sNBName)
	endif
 
	Variable i
 
	String indentStr = "\t"
	for(i=0; i<level; i+=1)
		indentStr += "\t"
	endfor
 
	Variable numWaves = CountObjectsDFR(dfr, 1)
	for(i=0; i<numWaves; i+=1)
		name = GetIndexedObjNameDFR(dfr, 1, i)
//		Print "wave type = ",WaveType(dfr:$name,1)		//1=numeric, 2=text
		if(WaveType(dfr:$name,1) == 1)
			WAVE w=dfr:$name
			if(numpnts(w) > 1)		//the Igor_Folder_Attributes wave has zero points, catch the error
				sPrintf sString, "%s%s (%d-D wave N=(%s)) val=%g\ttyp=%s\r", indentStr, name, WaveDims(w),V_PrintDims(w),w[0], V_PrintWaveType(w)
//				sPrintf sString, "%s%s (wave) %g\ttyp=%g\r", indentStr, name, w[0], WaveType(w)
//				sPrintf sString, "%s%s   \t%g\r", indentStr, name, w[0]
			else
			// variables show up as 1-point waves, don't report as (wave)
//				sPrintf sString, "%s%s (wave)\r", indentStr, name
				sPrintf sString, "%s%s \t%g\r", indentStr, name, w[0]
			endif
		else
			WAVE/T wt=dfr:$name		// text wave is assumed...
//			sPrintf sString, "%s%s (wave) \"%s\"\ttyp=text\r", indentStr, name, wt[0]
			sPrintf sString, "%s%s   \t\"%s\"\r", indentStr, name, wt[0]
		endif
		V_WriteBrowserInfo(sString, 2, sNBName)
	endfor	
 
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 4, sNBName)
	endfor	
 
	Variable numDataFolders = CountObjectsDFR(dfr, 4)	
	for(i=0; i<numDataFolders; i+=1)
		name = GetIndexedObjNameDFR(dfr, 4, i)
		if(cmpstr(name,"DAS_logs") != 0)		//ignore DAS_log folder
			sPrintf sString, "%s%s (data folder)\r", indentStr, name
			V_WriteBrowserInfo(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			V_ListDataFolder(childDFR, level+1, sNBName)
		endif
	endfor	
 
//when finished walking tree, save as RTF with dialog	
	if(level == 0 && strlen(sNBName) != 0)
		SaveNotebook /I /S=4  $sNBName
	endif
End
 
Function V_WriteBrowserInfo(sString, vType, sNBName)
	String sString
	Variable vType
	String sNBName
 
	if(strlen(sNBName) == 0)
		print sString
		return 0
	endif
	DoWindow $sNBName
	if(V_flag != 1)
		NewNoteBook/F=1 /N=$sNBName /V=1 as sNBName
	else
		DoWindow/F $sNBName
	endif
	Notebook $sNBName selection={endOfFile, endOfFile}
	if(vType == 1)//wave
		Notebook $sNBName fstyle=1
		Notebook $sNBName text=sString
		Notebook $sNBName fstyle=-1
	else
		Notebook $sNBName text=sString	
	endif
 
End

Function/S V_PrintWaveType(w)
	Wave w
	
	String str=""
	Variable typ
	typ = WaveType(w)
	
	if(typ==0)
		return("Text")
	endif
	
	Variable waveIsComplex = WaveType(w) & 0x01
	Variable waveIs32BitFloat = WaveType(w) & 0x02
	Variable waveIs64BitFloat = WaveType(w) & 0x04
	Variable waveIs8BitInteger = WaveType(w) & 0x08
	Variable waveIs16BitInteger = WaveType(w) & 0x10
	Variable waveIs32BitInteger = WaveType(w) & 0x20
	Variable waveIs64BitInteger = WaveType(w) & 0x80
	Variable waveIsUnsigned = WaveType(w) & 0x40
	
	if(waveiscomplex != 0)
		return("Complex")
	endif

	if(waveIs32BitFloat != 0)
		return("32bF")
	endif
	
	if(waveIs64BitFloat != 0)
		return("64bF")
	endif
	
	if(waveIs8BitInteger != 0)
		return("8bI")
	endif
	
	if(waveIs16BitInteger != 0)
		return("16bI")
	endif
	
	if(waveIs32BitInteger != 0)
		return("32bI")
	endif
	
	if(waveIs64BitInteger != 0)
		return("64bI")
	endif	
	
	return(str)
End


// construct a string with the dims of a wave - no parenthesis
Function/S V_PrintDims(w)
	Wave w
	
	String str=""
	Variable num=WaveDims(w),ii
	
	for(ii=0;ii<num;ii+=1)
		str += num2str(DimSize(w,ii)) + ","
	endfor
	
	ii=strlen(str)
	str = str[0,ii-2] // remove the last comma
	
	return(str)
end

