#pragma rtGlobals=1		// Use modern global access method.

Proc WriteModelData(xwave,ywave,delim,term)
	String xwave,ywave,delim,term
	Prompt xwave,"X data",popup,WaveList("*",";","")
	Prompt ywave,"y data",popup,WaveList("*",";","")
	Prompt delim,"delimeter",popup,"tab;space;"
	Prompt term,"line termination",popup,"CR;LF;CRLF;"
	
	//Print xwave, ywave, delim, term
	
	fWriteModelData($xwave,$ywave,delim,term)
	
End

Function fWriteModelData(xwave,ywave,delim,term)
	Wave xwave,ywave
	String delim,term
	
	String formatStr="",fullpath=""
	Variable refnum
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
	
	Open/D refnum as NameofWave(ywave)+".txt"	//doesn't open file
	If(cmpstr(S_filename,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	fullpath=S_filename
	Open refnum as fullpath
	
	fprintf refnum,"Model data created %s\r\n",(date()+" "+time())
	wfprintf refnum,formatStr,xwave,ywave
	Close refnum
	return(0)
End
