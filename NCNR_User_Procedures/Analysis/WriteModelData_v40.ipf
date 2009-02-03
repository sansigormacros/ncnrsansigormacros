#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

Proc WriteModelData(xwave,ywave,delim,term)
	String xwave,ywave,delim,term
	Prompt xwave,"X data",popup,PossibleModelWaves("x*")
	Prompt ywave,"Y data",popup,PossibleModelWaves("y*")
	Prompt delim,"delimeter",popup,"tab;space;"
	Prompt term,"line termination",popup,"CR;LF;CRLF;"
	
	//Print xwave, ywave, delim, term
	
	fWriteModelData($xwave,$ywave,delim,term)
	
End

Function/S PossibleModelWaves(filterStr)
	String filterStr
	
	String list,tmplist,DF,newList=""
	Variable ii,num
	
	//waves in root
	list = WaveList(filterStr,";","")
	
	//add possble smeared models that are housed in data folders
	ControlInfo/W=WrapperPanel popup_0
	if(V_flag==0 || cmpstr(S_Value,"No data loaded")==0)
		return(list)
	else
		DF="root:"+S_Value
		SetDataFolder $DF
		if(cmpstr(filterStr,"x*")==0)
			tmplist = WaveList("*_q",";","")
			tmpList += WaveList("GFitX_*",";","")
		else
			tmplist = WaveList("smea*",";","")
			tmpList += WaveList("GFit_*",";","")
		endif
		//prepend these list items with the folder
		num=itemsinlist(tmplist)
		if(num > 0)
			ii=0
			do
				newList += DF+":"+StringFromList(ii, tmpList, ";") + ";"
				ii+=1
			while(ii<num)
			
			//then add to the list
			list += newList
		endif
	endif
	
	SetDataFolder root:
	return(list)
end

// always asks for a file name
Function fWriteModelData(xwave,ywave,delim,term)
	Wave xwave,ywave
	String delim,term
	
	String formatStr="",fullpath=""
	Variable refnum,dialog=1
	
	//setup delimeter and terminator choices
	If(cmpstr(delim,"tab")==0)
		//tab-delimeted
		formatStr="%15.4g\t%15.4g"
	else
		//use 3 spaces
		formatStr="%15.4g   %15.4g"
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
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = A_DoSaveFileDialog("Save data as",fname=NameofWave(ywave)+".txt")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	Open refnum as fullpath
	
	fprintf refnum,"Model data created %s\r\n",(date()+" "+time())
	wfprintf refnum,formatStr,xwave,ywave
	Close refnum
	return(0)
End

// returns the path to the file, or null if the user cancelled
// fancy use of optional parameters
// 
// enforce short file names (26 characters)
// DUPLICATE of similar-named function in WriteQIS (including starts a bad dependency chain)
Function/S A_DoSaveFileDialog(msg,[fname,suffix])
	String msg,fname,suffix
	Variable refNum
//	String message = "Save the file as"

	if(ParamIsDefault(fname))
//		Print "fname not supplied"
		fname = ""
	endif
	if(ParamIsDefault(suffix))
//		Print "suffix not supplied"
		suffix = ""
	endif
	
	String outputPath,tmpName,testStr
	Variable badLength=0,maxLength=26,l1,l2
	
	
	tmpName = fname + suffix
	
	do
		badLength=0
		Open/D/M=msg/T="????" refNum as tmpName
		outputPath = S_fileName
		
		testStr = ParseFilePath(0, outputPath, ":", 1, 0)		//just the filename
		if(strlen(testStr)==0)
			break		//cancel, allow exit
		endif
		if(strlen(testStr) > maxLength)
			badlength = 1
			DoAlert 2,"File name is too long. Is\r"+testStr[0,25]+"\rOK?"
			if(V_flag==3)
				outputPath = ""
				break
			endif
			if(V_flag==1)			//my suggested name is OK, so trim the output
				badlength=0
				l1 = strlen(testStr)		//too long length
				l1 = l1-maxLength		//number to trim
				//Print outputPath
				l2=strlen(outputPath)
				outputPath = outputPath[0,l2-1-l1]
				//Print "modified  ",outputPath
			endif
			//if(V_flag==2)  do nothing, let it go around again
		endif
		
	while(badLength)
	
	return outputPath
End