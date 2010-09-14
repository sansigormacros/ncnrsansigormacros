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
		PathInfo/S savePathName
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

/////////XML Routines////////
///AJJ Jan 2010
///Have to put these here, annoyingly, because we depend on USANS specific functions
///Need to think about consolidation of functions.

#if( Exists("XmlOpenFile") )

Function WriteXMLUSANSWaves(type,fullpath,lo,hi,dialog)
	String type,fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR dQv = root:Packages:NIST:USANS:Globals:MainPanel:gDQv
	
	Struct NISTXMLfile nf
	
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
	
	//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
	Duplicate/O qvals,dumWave
	dumWave = dQv			//written out as a positive value, since the column is identified by its label, dQl
	///
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as",fname="",suffix="."+type+"x")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	//write out partial set?
	// duplicate the original data, all 3 waves
	Duplicate/O qvals,tq,ti,te
	ti=inten
	te=sig
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,dumWave		//lo to hi, inclusive
		tq=qvals[p+lo]
		ti=inten[p+lo]
		te=sig[p+lo]
	endif
	
	//Data
	Wave nf.Q = tq
	nf.unitsQ = "1/A"
	Wave nf.I = ti
	nf.unitsI = "1/cm"
	Wave nf.Idev = te
	nf.unitsIdev = "1/cm"
	// for slit-smeared USANS, set only a 4th column to  -dQv
	Wave nf.dQl = dumWave
	nf.unitsdQl= "1/A"

	//write out the standard header information
	//fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
	
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
	
	
	//AJJ to fix with sensible values
	nf.run = ""
	nf.nameSASinstrument = "BT5 USANS"
	nf.SASnote = ""
	//
	nf.sample_ID = ""
	nf.title = StringByKey("LABEL",note(inten),":",";")
	nf.radiation = "neutron"
	nf.wavelength = 2.38
	nf.unitswavelength = "A"
	nf.sample_thickness = thick
	nf.unitssample_thickness = "cm"
	
	//Do something with beamstop (rw[21])
	nf.detector_name = "BT5 DETECTOR ARRAY"

	nf.SASprocessnote = samStr+"\n"
	nf.SASprocessnote += dateStr+"\n"
	nf.SASprocessnote += samLabelStr+"\n"
	nf.SASprocessnote += empStr+"\n"
	nf.SASprocessnote += paramStr+"\n"
	nf.SASprocessnote += pkStr+"\n"
	nf.SASprocessnote += empLevStr + " ; "+bkglevStr+"\n"
	
	nf.nameSASProcess = "NIST IGOR"

	//Close refnum
	
	writeNISTXML(fullpath, nf)
	
	SetDataFolder root:		//(redundant)
	
	//write confirmation of write operation to history area
	Print "Averaged XML File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z dumWave
	Return(0)
End

Function WriteXMLUSANSDesmeared(fullpath,lo,hi,dialog)
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder	
	
	Struct NISTXMLfile nf
	
	String termStr="\r\n"
	String destStr = USANSFolder+":DSM:"
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE Q_dsm =$(destStr + "Q_dsm")
	WAVE I_dsm=$(destStr + "I_dsm")
	WAVE S_dsm=$(destStr + "S_dsm")
	
	//check each wave
	If(!(WaveExists(Q_dsm)))
		Abort "Q_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(I_dsm)))
		Abort "I_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(S_dsm)))
		Abort "S_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	
	// 06 FEB 06 SRK
	// make dummy waves to hold the "fake" resolution, and write it as the last 3 columns
	//
	Duplicate/O Q_dsm,res1,res2,res3
	res3 = 1		// "fake" beamstop shadowing
	res1 /= 100		//make the sigmaQ so small that there is no smearing
	
	if(dialog)
		Open/D refnum as fullpath+".dsmx"		//won't actually open the file
		If(cmpstr(S_filename,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		fullpath = S_filename
	Endif
	
	//write out partial set?
	Duplicate/O Q_dsm,tq,ti,te
	ti=I_dsm
	te=S_dsm
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=Q_dsm[p+lo]
		ti=I_dsm[p+lo]
		te=S_dsm[p+lo]
	endif
	
		//Data
	Wave nf.Q = tq
	nf.unitsQ = "1/A"
	Wave nf.I = ti
	nf.unitsI = "1/cm"
	Wave nf.Idev = te
	nf.unitsIdev = "1/cm"
	Wave nf.Qdev = res1
	nf.unitsQdev = "1/A"
	Wave nf.Qmean = res2
	nf.unitsQmean = "1/A"
	Wave nf.Shadowfactor = res3
	nf.unitsShadowfactor = "none"
	
	//tailor the output given the type of data written out...
	String samStr="",dateStr="",str1,str2
	
	NVAR m = $(USANSFolder+":DSM:gPowerM")				// power law exponent
	NVAR chiFinal = $(USANSFolder+":DSM:gChi2Final")		//chi^2 final
	NVAR iter = $(USANSFolder+":DSM:gIterations")		//total number of iterations
	
	//get the number of spline passes from the wave note
	String noteStr
	Variable boxPass,SplinePass
	noteStr=note(I_dsm)
	BoxPass = NumberByKey("BOX", noteStr, "=", ";")
	splinePass = NumberByKey("SPLINE", noteStr, "=", ";")
	
	samStr = fullpath
	dateStr="CREATED: "+date()+" at  "+time()
	sprintf str1,"Chi^2 = %g   PowerLaw m = %4.2f   Iterations = %d",chiFinal,m,iter
	sprintf str2,"%d box smooth passes and %d smoothing spline passes",boxPass,splinePass
	
	//AJJ to fix with sensible values
	nf.run = "Test"
	nf.nameSASinstrument = "BT5 USANS"
	nf.SASnote = ""
	//
	nf.sample_ID = ""
	nf.title = samstr
	nf.radiation = "neutron"
	nf.wavelength = 2.38
	nf.unitswavelength = "A"
	
	//Do something with beamstop (rw[21])
	nf.detector_name = "BT5 DETECTOR ARRAY"

	nf.SASprocessnote = samStr+"\n"
	nf.SASprocessnote += str1+"\n"
	nf.SASprocessnote += str2+"\n"
	nf.SASprocessnote += datestr+"\n"

	
	nf.nameSASProcess = "NIST IGOR"

	//Close refnum
	
	writeNISTXML(fullpath, nf)
	
	SetDataFolder root:		//(redundant)
	
	KillWaves/Z res1,res2,res2,ti,te,tq
	
	Return(0)
End


#else	// if( Exists("XmlOpenFile") )
	// No XMLutils XOP: provide dummy function so that IgorPro can compile dependent support code
	
	
	Function WriteXMLUSANSWaves(type,fullpath,lo,hi,dialog)
		String type,fullpath
		Variable lo,hi,dialog		//=1 will present dialog for name
	
	    Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end
	
	Function WriteXMLUSANSDesmeared(type,fullpath,lo,hi,dialog)
		String type,fullpath
		Variable lo,hi,dialog		//=1 will present dialog for name
	
	    Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end
			
	
	
#endif