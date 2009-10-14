#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1

//////////////
//for writing out data (q-i-s-dum-dum-dum) from the "type" folder
//if fullpath is a complete HD path:filename, no dialog will be presented
//if fullpath is just a filename, the save dialog will be presented (forced if dialog =1)
//lo,hi are an (optional) range of the data[lo,hi] to save (in points)
//if lo=hi=0, all of the data is written out
//
//////// 27 OCT 04
// now writes 6-column data such that the last three columns are the divergence
//  = a constant value, set in Init_MainUSANS()
//
Function WriteUSANSWaves(type,fullpath,lo,hi,dialog)
	String type,fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	
	String termStr="\r\n"		//VAX uses only <CR> as terminator, but only CRLF seems to FTP correctly to VAX
	String destStr="",formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr
	destStr = USANSFolder+":"+type
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE qvals =$(destStr + ":Qvals")
	WAVE inten=$(destStr + ":DetCts")
	WAVE sig=$(destStr + ":ErrDetCts")
	
	//check each wave
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist in WriteUSANSWaves()"
	Endif
	
	// 27 OCT 04 SRK
	// make a dummy wave to hold the divergence, and write it as the last 3 columns
	// and make the value negative as a flag for the analysis software
	//
	Duplicate/O qvals,dumWave
	NVAR DQv=$(USANSFolder+":Globals:MainPanel:gDQv")
	dumWave = - DQv
	///
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	//write out partial set?
	Duplicate/O qvals,tq,ti,te
	ti=inten
	te=sig
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,dumWave		//lo to hi, inclusive
		tq=qvals[p+lo]
		ti=inten[p+lo]
		te=sig[p+lo]
	endif
	
	//tailor the output given the type of data written out...
	WAVE inten_EMP=$(USANSFolder+":EMP:DetCts")
	String samStr="",empStr="",dateStr="",samLabelStr="",paramStr="",empLevStr="",bkgLevStr=""
	String pkStr=""
	NVAR TransWide = $(USANSFolder+":Globals:MainPanel:gTransWide")
	NVAR TransRock = $(USANSFolder+":Globals:MainPanel:gTransRock")
	NVAR empCts = $(USANSFolder+":Globals:MainPanel:gEmpCts")
	NVAR bkgCts = $(USANSFolder+":Globals:MainPanel:gBkgCts")
	NVAR thick = $(USANSFolder+":Globals:MainPanel:gThick")
	
	strswitch(type)
		case "SAM":		
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "Uncorrected SAM data"
			empLevStr = "Uncorrected SAM data"
			bkgLevStr = "Uncorrected SAM data"
			paramStr = "Uncorrected SAM data"
			pkStr += "SAM PEAK ANGLE: "+num2str(QpkFromNote("SAM"))
			break						
		case "EMP":	
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "Uncorrected EMP data"
			empLevStr = "Uncorrected EMP data"
			bkgLevStr = "Uncorrected EMP data"
			paramStr = "Uncorrected EMP data"
			pkStr += "EMP PEAK ANGLE: "+num2str(QpkFromNote("EMP"))
			break
		default:		//"COR" is the default	
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "EMP FILES: "+StringByKey("FILE",note(inten_EMP),":",";")	
			empLevStr = "EMP LEVEL: " + num2str(empCts)
			bkgLevStr = "BKG LEVEL: " + num2str(bkgCts)
			paramStr = "Ds = "+num2str(thick)+" cm ; "
			paramStr += "Twide = "+num2Str(TransWide)+" ; "
			paramStr += "Trock = "+num2str(TransRock)	
			pkStr += "SAM PEAK ANGLE: "+num2str(QpkFromNote("SAM"))
			pkStr += " ; EMP PEAK ANGLE: "+num2str(QpkFromNote("EMP"))				
	endswitch
	
	//these strings are always the same
	dateStr="CREATED: "+date()+" at  "+time()
	samLabelStr ="LABEL: "+StringByKey("LABEL",note(inten),":",";")	
	
	//actually open the file
	Open refNum as fullpath
	
	fprintf refnum,"%s"+termStr,samStr
	fprintf refnum,"%s"+termStr,dateStr
	fprintf refnum,"%s"+termStr,samLabelStr
	fprintf refnum,"%s"+termStr,empStr
	fprintf refnum,"%s"+termStr,paramStr
	fprintf refnum,"%s"+termStr,pkStr
	fprintf refnum,"%s"+termStr,empLevStr + " ; "+bkglevStr
	
	//
	wfprintf refnum, formatStr, tq,ti,te,dumWave,dumWave,dumWave
	
	Close refnum
	
	Killwaves/Z ti,tq,te,dumWave
	
	Return(0)
End


// convert "old" 3-column .cor files to "new" 6-column files
// Append the suffix="_6col.cor" to the new data files
//
// these "old" files will all have dQv = 0.037 (1/A) to match the 
// absolute scaling constant. "New" files written Nov 2004 or later 
// will have the appropriate values of dQv and scaling, as set in
// the initialization routines.
//
// files were written out in the style above, 7 header lines, then the data
//
Function Convert3ColTo6Col()
	
	String termStr="\r\n"		//VAX uses only <CR> as terminator, but only CRLF seems to FTP correctly to VAX
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr
	String newFName="",suffix="_6col.cor",fullpath=""
	
	Variable refNum_old,refnum_new,integer,realval
	
	// 08 NOV 04 SRK
	Variable ii,dQv = -0.037		//hard-wired value for divergence (pre- NOV 2004 value)
	///
	
	Open/R/D/M="Select the 3-column data file"/T="????" refnum_old		//won't actually open the file
	If(cmpstr(S_filename,"")==0)
		//user cancel, don't write out a file
		Close/A
		Abort "no data file was written"
	Endif
	fullpath = S_filename
	newFname = fullpath[0,strlen(fullpath)-5]+suffix
	Print fullpath
	Print newFname
	
	String tmpStr
	String extraStr=""
	sprintf extraStr,"%15.6g %15.6g %15.6g",dQv,dQv,dQv
	extraStr += termStr
	//actually open each of the files
	Open/R refNum_old as fullpath
	Open refNum_new as newFname
	
	//7 header lines
	for(ii=0;ii<7;ii+=1)
		FReadLine refNum_old, tmpStr		//returns only CR
		fprintf refnum_new,tmpStr+"\n"		// add LF so file has CRLF
	endfor
	
	do
		FReadLine refNum_old, tmpStr
		if(strlen(tmpStr)==0)
			break
		endif
		fprintf refnum_new,tmpStr[0,strlen(tmpStr)-2]+extraStr
	while(1)
	
	Close refnum_old
	Close refnum_new
		
	Return(0)
End

