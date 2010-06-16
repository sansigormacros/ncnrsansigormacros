#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

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


/////////////
Proc ReWrite1DData(folderStr,delim,term)
	String folderStr,delim,term
	Prompt folderStr,"Data Set",popup,W_DataSetPopupList()
	Prompt delim,"delimeter",popup,"tab;space;"
	Prompt term,"line termination",popup,"CR;LF;CRLF;"
	
	if (root:Packages:NIST:gXML_Write == 1)
		SetDataFolder root:
		ReWrite1DXMLData(folderStr)
	else
		SetDataFolder root:
		fReWrite1DData(folderStr,delim,term)
	endif	
End


// always asks for a file name
// - and right now, always expect 6-column data, either SANS or USANS (re-writes -dQv)
// - AJJ Nov 2009 : better make sure we always fake 6 columns on reading then....
Function fReWrite1DData(folderStr,delim,term)
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
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as",fname=baseStr+".txt")
		Print fullPath
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif

	Open refnum as fullpath
	
	fprintf refnum,"Modified data written from folder %s on %s\r\n",baseStr,(date()+" "+time())
	wfprintf refnum,formatStr,qw,iw,sw,sigQ,qbar,fs
	Close refnum
	
	KillWaves/Z sigQ,qbar,fs
	
	SetDataFolder root:
	return(0)
End