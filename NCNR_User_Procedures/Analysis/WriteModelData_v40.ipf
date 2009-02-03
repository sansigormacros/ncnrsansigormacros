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
		fullPath = DoSaveFileDialog("Save data as",fname=NameofWave(ywave)+".txt")
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

