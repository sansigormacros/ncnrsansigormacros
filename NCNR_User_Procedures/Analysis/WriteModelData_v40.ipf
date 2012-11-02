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


// 10/22/2012 - MJW
// Added suffixes ending in _q_RA, _qvals, _qvals_RA to list of possible x-waves to allow writing of rescaled model data
// Added removal of qvals, _qvals_RA and _q_RA from the list of possible y-waves
Function/S PossibleModelWaves(filterStr)
	String filterStr
	
	String list,tmplist,tmplist2,DF,newList=""
	Variable ii,num
	
	//waves in root
	list = WaveList(filterStr,";","")
	
	// get the real-space model waves, if present
	if(cmpstr(filterStr,"x*")==0)
		list += WaveList("qBin*",";","")
	else
		list += WaveList("iBin*",";","")
	endif
	
	//add possble smeared models that are housed in data folders
	ControlInfo/W=WrapperPanel popup_0
	if(V_flag==0 || cmpstr(S_Value,"No data loaded")==0)
		return(list)
	else
		DF="root:"+S_Value
		SetDataFolder $DF
		if(cmpstr(filterStr,"x*")==0)
			tmplist = WaveList("*_q",";","")
			tmplist += WaveList("*_q_RA",";","")
			tmplist += WaveList("*_qvals",";","")
			tmplist += WaveList("*_qvals_RA",";","")
			tmpList += WaveList("GFitX_*",";","")
		else
			tmplist = WaveList("smea*",";","")
			tmpList += WaveList("GFit_*",";","")
			tmplist2 = WaveList("*_qvals",";","")
			tmpList = RemoveFromList(tmplist2,tmplist,";")
			tmplist2 = WaveList("*_qvals_RA",";","")
			tmpList = RemoveFromList(tmplist2,tmplist,";")
			tmplist2 = WaveList("*_q_RA",";","")
			tmpList = RemoveFromList(tmplist2,tmplist,";")
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
			SetDataFolder root:
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

//MJW 24 Oct 2012
//Included WriteRescaledData and fWriteRescaledData to write data from the RescaledAxis Panel.
Function WriteRescaledData()

	string xwavelist ="", ywavelist ="", swavelist="None"

	SetDataFolder root:
	String topGraph= WinName(0,1)	//this is the topmost graph
		if(strlen(topGraph)==0)
		Abort "There is no graph"
	endif

	DoWindow/F $topGraph
	GetWindow/Z $topGraph, wavelist
	wave/t W_Wavelist
	SetDataFolder root:Packages:NIST:RescaleAxis
	if (exists("W_WaveList")==1)
		KillWaves/Z root:Packages:NIST:RescaleAxis:W_WaveList
	endif
	MoveWave root:W_WaveList, root:Packages:NIST:RescaleAxis:W_WaveList
	SetDataFolder root:Packages:NIST:RescaleAxis

	variable i
	string temp
	for(i=0; i < numpnts(W_Wavelist)/3; i+=1)
		temp = W_Wavelist[i][0]
		if(stringmatch(temp,"*_q") || stringmatch(temp,"*_q_RA") || stringmatch(temp,"*_qvals") || stringmatch(temp,"*_qvals_RA") || stringmatch(temp,"*xwave*"))
			if(strlen(xwavelist)==0)
				xwavelist = temp
			else
				xwavelist =xwavelist +";"+temp
			endif
		elseif (stringmatch(temp, "*_i") || stringmatch(temp, "*_i_RA") || stringmatch(temp,"*FitYW*") || stringmatch(temp,"*ywave*") || stringmatch(temp,"*smeared*"))
			if(strlen(ywavelist)==0)
				ywavelist = temp
			else
				ywavelist =ywavelist +";"+temp
			endif
		elseif (stringmatch(temp,"*_s") || stringmatch(temp,"*_s_RA"))
				swavelist =swavelist +";"+temp
		endif
	endfor

	string xwave,ywave,swave,delim, term
	Prompt ywave,"Y data",popup,ywavelist
	Prompt xwave,"X data",popup,xwavelist
	Prompt swave,"Error data",popup,swavelist
	Prompt delim,"delimeter",popup,"tab;space;"
	Prompt term,"line termination",popup,"CR;LF;CRLF;"
	DoPrompt/help="" "Choose the Data to Save",ywave,xwave,swave,delim,term
	
	if(V_flag==1)
		Abort "Cancel was clicked therefore no data was exported"
	endif

	print xwave, ywave, swave
		
	for(i=0; i < numpnts(W_Wavelist)/3; i+=1)
		temp = W_Wavelist[i][0]
		if(stringmatch(temp,ywave))
		ywave = W_Wavelist[i][1]
		elseif (stringmatch(temp, xwave))
		xwave = W_Wavelist[i][1]
		elseif (stringmatch(temp,swave))
		swave = W_Wavelist[i][1]
		endif
	endfor
	
	fWriteRescaledData(xwave,ywave,swave,delim,term)
End

Function fWriteRescaledData(xwavestr,ywavestr,swavestr,delim,term)
	String xwavestr,ywavestr,swavestr,delim,term
	
	SetDataFolder root:
	wave xwave = $xwavestr
	wave ywave = $ywavestr
	wave swave = $swavestr
	String formatStr="",fullpath=""
	Variable refnum,dialog=1
	
	//setup delimeter and terminator choices
	if(stringmatch(swavestr,"None"))
		If(cmpstr(delim,"tab")==0)
			//tab-delimeted
			formatStr="%15.4g\t%15.4g"
		else
			//use 3 spaces
			formatStr="%15.4g   %15.4g"
		Endif
	else
		If(cmpstr(delim,"tab")==0)
			//tab-delimeted
			formatStr="%15.4g\t%15.4g\t%15.4g"
		else
			//use 3 spaces
			formatStr="%15.4g   %15.4g   %15.4g"
		Endif
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
	if(stringmatch(swavestr,"None"))
		wfprintf refnum,formatStr,xwave,ywave
	else
		wfprintf refnum,formatStr,xwave,ywave,swave
	endif
	Close refnum
	return(0)
End
