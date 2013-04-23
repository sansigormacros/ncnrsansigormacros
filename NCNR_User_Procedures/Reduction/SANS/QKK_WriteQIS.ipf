#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

//************************
// Vers 1.2 091001
//
//************************

//for writing out data (q-i-s) from the "type" folder, and including reduction information
//if fullpath is a complete HD path:filename, no dialog will be presented
//if fullpath is just a filename, the save dialog will be presented
//if dialog = 1, a dialog will always be presented
//
// root:myGlobals:Protocols:gProtoStr is the name of the currently active protocol
//
Function WriteWaves_W_Protocol(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	String destStr=""
	destStr = "root:Packages:NIST:"+type
	
	Variable refNum
	String formatStr = "%15g %15g %15g %15g %15g %15g\r\n"
	String fname,ave="C",hdrStr1="",hdrStr2=""
	Variable step=1
	
	
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")
	WAVE qvals =$(destStr + ":qval")
	WAVE inten=$(destStr + ":aveint")
	WAVE sig=$(destStr + ":sigave")
 	WAVE qbar = $(destStr + ":QBar")
  	WAVE sigmaq = $(destStr + ":SigmaQ")
 	WAVE fsubs = $(destStr + ":fSubS")

	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)
	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(qbar)))
		Abort "qbar DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(sigmaq)))
		Abort "sigmaq DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(fsubs)))
		Abort "fsubs DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist BinaryWrite_W_Protocol()"
	Endif

	//strings can be too long to print-- must trim to 255 chars
	Variable ii,num=8
	Make/O/T/N=(num) tempShortProto
	for(ii=0;ii<num;ii+=1)
		tempShortProto[ii] = (proto[ii])[0,240]
	endfor
	
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
	
	hdrStr1 = num2str(rw[0])+"  "+num2str(rw[26])+"       "+num2str(rw[19])+"     "+num2str(rw[18])
	hdrStr1 += "     "+num2str(rw[4])+"     "+num2str(rw[5]) + ave +"   "+num2str(step) + "\r\n"

	hdrStr2 = num2str(rw[16])+"  "+num2str(rw[17])+"  "+num2str(rw[23])+"    "+num2str(rw[24])+"    "
	hdrStr2 += num2str(rw[25])+"    "+num2str(rw[27])+"    "+num2str(rw[21])+"    "+textW[9] + "\r\n"
	
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	//actually open the file here
	Open refNum as fullpath
	
	//write out the standard header information
	fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
	fprintf refnum,"LABEL: %s\r\n",textw[6]
	fprintf refnum,"MON CNT   LAMBDA   DET ANG   DET DIST   TRANS   THICK   AVE   STEP\r\n"
	fprintf refnum,hdrStr1
	fprintf refnum,"BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP \r\n"
	fprintf refnum,hdrStr2
//	fprintf refnum,headerFormat,rw[0],rw[26],rw[19],rw[18],rw[4],rw[5],ave,step

	//insert protocol information here
	//-1 list of sample files
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	fprintf refnum, "SAM: %s\r\n",samFiles
	fprintf refnum, "BGD: %s\r\n",tempShortProto[0]
	fprintf refnum, "EMP: %s\r\n",tempShortProto[1]
	fprintf refnum, "DIV: %s\r\n",tempShortProto[2]
	fprintf refnum, "MASK: %s\r\n",tempShortProto[3]
	fprintf refnum, "ABS Parameters (3-6): %s\r\n",tempShortProto[4]
	fprintf refnum, "Average Choices: %s\r\n",tempShortProto[5]
	
	//write out the data columns
	fprintf refnum,"The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"
	wfprintf refnum, formatStr, qvals,inten,sig,sigmaq,qbar,fsubs
	
	Close refnum
	
	SetDataFolder root:		//(redundant)
	
	//write confirmation of write operation to history area
	Print "Averaged File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z tempShortProto
	Return(0)
End


//for writing out data (phi-i-s) from the "type" folder, and including reduction information
//if fullpath is a complete HD path:filename, no dialog will be presented
//if fullpath is just a filename, the save dialog will be presented
//if dialog = 1, a dialog will always be presented
//
// root:myGlobals:Protocols:gProtoStr is the name of the currently active protocol
//
Function WritePhiave_W_Protocol(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	String destStr
	destStr = "root:Packages:NIST:"+type
	
	Variable refNum
	String formatStr = "%15.4g %15.4g %15.4g\r\n"
	String fname,ave="C",hdrStr1,hdrStr2
	Variable step=1
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")
	WAVE phival =$(destStr + ":phival")
	WAVE inten=$(destStr + ":aveint")
	WAVE sig=$(destStr + ":sigave")
	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)
	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(phival)))
		Abort "qvals DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist BinaryWrite_W_Protocol()"
	Endif
	//strings can be too long to print-- must trim to 255 chars
	Variable ii,num=8
	Make/O/T/N=(num) tempShortProto
	for(ii=0;ii<num;ii+=1)
		tempShortProto[ii] = (proto[ii])[0,240]
	endfor
	
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
	
	hdrStr1 = num2str(rw[0])+"  "+num2str(rw[26])+"       "+num2str(rw[19])+"     "+num2str(rw[18])
	hdrStr1 += "     "+num2str(rw[4])+"     "+num2str(rw[5]) + ave +"   "+num2str(step) + "\r\n"

	hdrStr2 = num2str(rw[16])+"  "+num2str(rw[17])+"  "+num2str(rw[23])+"    "+num2str(rw[24])+"    "
	hdrStr2 += num2str(rw[25])+"    "+num2str(rw[27])+"    "+num2str(rw[21])+"    "+textW[9] + "\r\n"
	
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	//actually open the file here
	Open refNum as fullpath
	
	//write out the standard header information
	fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
	fprintf refnum,"LABEL: %s\r\n",textw[6]
	fprintf refnum,"MON CNT   LAMBDA   DET ANG   DET DIST   TRANS   THICK   AVE   STEP\r\n"
	fprintf refnum,hdrStr1
	fprintf refnum,"BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP \r\n"
	fprintf refnum,hdrStr2
	
	//insert protocol information here
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	fprintf refnum, "SAM: %s\r\n",samFiles
	fprintf refnum, "BGD: %s\r\n",tempShortProto[0]
	fprintf refnum, "EMP: %s\r\n",tempShortProto[1]
	fprintf refnum, "DIV: %s\r\n",tempShortProto[2]
	fprintf refnum, "MASK: %s\r\n",tempShortProto[3]
	fprintf refnum, "ABS Parameters (3-6): %s\r\n",tempShortProto[4]
	fprintf refnum, "Average Choices: %s\r\n",tempShortProto[5]
	
	//write out the data columns
	fprintf refnum,"The 3 columns are | Phi (deg) | I(phi) (1/cm) | std. dev. I(phi) (1/cm) |\r\n"
	wfprintf refnum, formatStr, phival,inten,sig
	
	Close refnum
	
	SetDataFolder root:		//(redundant)
	
	//write confirmation of write operation to history area
	Print "Averaged File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z tempShortProto

	Return(0)
End

//*****************
// saves the data after all of the desired reduction steps (average options)
// as a 2x expanded PNG file (approx 33kb)
//
Function SaveAsPNG(type,fullPath,dialog)
	String type,fullPath
	Variable dialog
	
	Variable refnum
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as")		//won't actually open the file
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	//cleanup the filename passed in from Protocol...
	String oldStr="",newStr="",pathStr=""
	oldStr=GetFileNameFromPathNoSemi(fullPath)	//just the filename
	pathStr=GetPathStrFromfullName(fullPath)	//just the path
	
	newStr = CleanupName(oldStr, 0 )				//filename with _EXT rather than .EXT
	fullPath=pathStr+newStr+".png"				//tack on the png extension
	
	print "type=",type
	//graph the current data and save a little graph
	Wave data =  $("root:Packages:NIST:"+type+":data")
	Wave q_x_axis = $"root:myGlobals:q_x_axis"
	Wave q_y_axis = $"root:myGlobals:q_y_axis"
	Wave NIHColors = $"root:myGlobals:NIHColors"
	
	NewImage/F data
	DoWindow/C temp_PNG
	ModifyImage data cindex= NIHColors
	AppendToGraph/R q_y_axis
	ModifyGraph tkLblRot(right)=90,lowTrip(right)=0.001
	AppendToGraph/T q_x_axis
	ModifyGraph lowTrip(top)=0.001,standoff=0,mode=2
	ModifyGraph fSize(right)=9,fSize(top)=9,btLen=3
	
//	ModifyGraph nticks=0
	
//	WaveStats/Q data
// 	ScaleColorsToData(V_min, V_max, NIHColors)

// ***comment out for DEMO_MODIFIED version
	SavePict/Z/E=-5/B=144 as fullPath			//PNG at 2x screen resolution
//***

	Print "Saved graphic as ",newStr+".png"
	DoWindow/K temp_PNG
End

//****************
//Testing only , not called
Proc Fast_ASCII_2D_Export(type,term)
	String type,term
	Prompt type,"2-D data type for Export",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;MSK;"
	Prompt term,"line termination",popup,"CR;LF;CRLF;"
	
	//terminator is currently ignored
	Fast2dExport(type,"",1)
	
End

//the default termination for the platform is used...
//if RAW export, sets "dummy" protocol to "RAW data export"
Function Fast2dExport(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
		
	String destStr="",ave="C",typeStr=""
	Variable step=1,refnum
	destStr = "root:Packages:NIST:"+type
	
	//must select the linear_data to export
	// can't export log data if there are -ve intensities from a subtraction
	NVAR isLog = $(destStr+":gIsLogScale")
	if(isLog==1)
		typeStr = ":linear_data"
	else
		typeStr = ":data"
	endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Wave data=$(destStr+typeStr)
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")

	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	String rawTag=""
	if(cmpstr(type,"RAW")==0)
		Make/O/T/N=8 proto={"none","none","none","none","none","none","none","none"}
		RawTag = "RAW Data File: "	
	else
		Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)
	endif
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	//check each wave - MUST exist, or will cause a crash
	If(!(WaveExists(data)))
		Abort "data DNExist AsciiExport()"
	Endif
	If(!(WaveExists(intw)))
		Abort "intw DNExist AsciiExport()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist AsciiExport()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist AsciiExport()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist AsciiExport()"
	Endif
	
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
	
/////////
	Variable numTextLines=18
	Make/O/T/N=(numTextLines) labelWave
	labelWave[0] = "FILE: "+textw[0]+"   CREATED: "+textw[1]
	labelWave[1] = "LABEL: "+textw[6]
	labelWave[2] = "MON CNT   LAMBDA(A)   DET_OFF(cm)   DET_DIST(m)   TRANS   THICK(cm)    COUNT TIME"
	labelWave[3] = num2str(rw[0])+"  "+num2str(rw[26])+"       "+num2str(rw[19])+"     "+num2str(rw[18])
	labelWave[3] += "     "+num2str(rw[4])+"     "+num2str(rw[5])+"     "+num2str(intw[2])
	labelWave[4] = "BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP  "
	labelWave[5] = num2str(rw[16])+"  "+num2str(rw[17])+"  "+num2str(rw[23])+"  "+num2str(rw[24])+"  "
	labelWave[5] += num2str(rw[25])+"  "+num2str(rw[27])+"  "+num2str(rw[21])+"  "+textW[9]
	labelWave[6] = "PIXELS(X)    PIXELS(Y)   PIXELSIZE X (mm)  PIXELSIZE Y (mm)"
	labelWave[7] += num2str(pixelsX)+"    "+num2str(pixelsY)+"    "+num2str(rw[10])+"    "+num2str(rw[13])
	labelWave[8] =  "SAM: "+rawTag+samFiles
	labelWave[9] =  "BGD: "+proto[0]
	labelWave[10] =  "EMP: "+proto[1]
	labelWave[11] =  "DIV: "+proto[2]
	labelWave[12] =  "MASK: "+proto[3]
	labelWave[13] =  "ABS Parameters (3-6): "+proto[4]
	labelWave[14] = "Average Choices: "+proto[5]
	labelWave[15] = ""
	labelWave[16] = "*** Data written from "+type+" folder and may not be a fully corrected data file ***"
	labelWave[17] = "The detector image is a standard X-Y coordinate system"
	labelWave[18] = "Data is written by row, starting with Y=1 and X=(1->128)"
	//labelWave[19] = "ASCII data created " +date()+" "+time()
	PathInfo catPathName
	String sfPath = S_Path+StringFromList(0,samfiles,";")
	print sfPath
	labelWave[19] = "RAW SAM FILE "+StringFromList(0, samfiles  , ";")+ " TIMESTAMP: "+getFileCreationDate(sfPath)
	
	//strings can be too long to print-- must trim to 255 chars
	Variable ii
	for(ii=0;ii<numTextLines;ii+=1)
		labelWave[ii] = (labelWave[ii])[0,240]
	endfor
//	If(cmpstr(term,"CR")==0)
//		termStr = "\r"
//	Endif
//	If(cmpstr(term,"LF")==0)
//		termStr = "\n"
//	Endif
//	If(cmpstr(term,"CRLF")==0)
//		termStr = "\r\n"
//	Endif
	
	Duplicate/O data,spWave		
	Redimension/S/N=(pixelsX*pixelsY) spWave		//single precision (/S)
	
	//not demo- compatible, but approx 100x faster!!
	
// for some reason, Igor 6.10 barfs on this and the Save operation gives an out-of-memory error!
// so for now, go back to the old way...

//#if(cmpstr(stringbykey("IGORKIND",IgorInfo(0),":",";"),"pro") == 0)
//	Save/G/M="\r\n" labelWave,spWave as fullPath
//#else
	Open refNum as fullpath
	wfprintf refNum,"%s\r\n",labelWave
	fprintf refnum,"\r\n"
	wfprintf refNum,"%g\r\n",spWave
	Close refNum
//#endif

	Killwaves/Z spWave,labelWave		//don't delete proto!
	
	Print "2D ASCII File written: ", GetFileNameFromPathNoSemi(fullPath)
	
	return(0)
End


//// ASCII EXPORT in detector coordinates - mimicking the VAX CONVERT command
// this is done simply to be able to produce converted raw data files that can be 
// read in with Grasp. A rather awkward structure, definitely not the preferred export format
//
// SRK 14 NOV 07
//
Function Fast2dExport_OldStyle(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
		
	String destStr=""
	String typeStr=""
	Variable refnum
	
	destStr = "root:Packages:NIST:"+type
	
	//must select the linear_data to export
	// can't export log data if there are -ve intensities from a subtraction
	NVAR isLog = $(destStr+":gIsLogScale")
	if(isLog==1)
		typeStr = ":linear_data"
	else
		typeStr = ":data"
	endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Wave data=$(destStr+typeStr)
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")

	//check each wave - MUST exist, or will cause a crash
	If(!(WaveExists(data)))
		Abort "data DNExist AsciiExport()"
	Endif
	If(!(WaveExists(intw)))
		Abort "intw DNExist AsciiExport()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist AsciiExport()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist AsciiExport()"
	Endif

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
	
/////////
	String tmpStr=""
	Variable numTextLines=17
	Make/O/T/N=(numTextLines) labelWave
	
//	sprintf tmpStr," '%s'   '%s'   '%s'",textw[0],textw[1],textw[2]
	sprintf tmpStr," '%s'        '%s'        '%s'     'SAn''ABC''A123'",GetFileNameFromPathNoSemi(fullPath),textw[1],textw[2]
	labelWave[0] = tmpStr
	labelWave[1] = " "+textw[6]		//label
	
//	sprintf tmpStr," %d  %g  %g  %g",intw[2],rw[0],rw[39],rw[2]
	sprintf tmpStr," %6d        %13.5E     %13.5E     %13.5E",intw[2],rw[0],rw[39],rw[2]
	labelWave[2] = tmpStr
	labelWave[3] = " Cnt.Time(sec.)    Mon. Cnt.      Trans. Det. Cnt.  Tot. Det. Cnt."
	
//	sprintf tmpStr," %g  %g  %g '%s' %g '%s' %d  %d  %g",rw[4],rw[5],rw[8],textw[7],rw[9],textw[8],intw[4],intw[5],rw[6]
	sprintf tmpStr,"%10.3g   %9.2g%8.2f '%6s'%8.2f '%6s'%7d%7d%7.2f",rw[4],rw[5],rw[8],textw[7],rw[9],textw[8],intw[4],intw[5],rw[6]
	labelWave[4] = tmpStr
	labelWave[5] = " Trans.      Thckns       Temp.           H Field         Table  Holder  Pos"
	
//	sprintf tmpStr," %g  %g  %d  '%s'  %g",rw[26],rw[27],intw[9],textw[9],rw[7]
	sprintf tmpStr," %8.2f        %5.2f          %2d   '%6s'          %6.2f",rw[26],rw[27],intw[9],textw[9],rw[7]
	labelWave[6] = tmpStr
	labelWave[7] = " Wavelength &  Spread(FWHM)    Det.#  Type      Sample Rotation Angle"
	
//	sprintf tmpStr," %g  %g  %g  %g  %g  %g",rw[18],rw[19],rw[16],rw[17],rw[21],rw[3]
	sprintf tmpStr," %12.2f%12.2f          %6.2f  %6.2f  %10.2f        %4.1f",rw[18],rw[19],rw[16],rw[17],rw[21],rw[3]
	labelWave[8] = tmpStr
	labelWave[9] = " Sam-Det Dis.(m)   Det.Ang.(cm.)   Beam Center(x,y)  Beam Stop(mm)  Atten.No."
	
//	sprintf tmpStr," %g  %g  %g  %g  %g  %g",rw[10],rw[11],rw[12],rw[13],rw[14],rw[15]
	sprintf tmpStr," %8.3f      %10.4E  %10.4E%8.3f      %10.4E  %10.4E",rw[10],rw[11],rw[12],rw[13],rw[14],rw[15]
	labelWave[10] = tmpStr
	labelWave[11] = "        Det. Calib Consts. (x)           Det. Calib Consts. (y)"
	
//	sprintf tmpStr," %g  %g  %g  '%s'  %g  %g",rw[23],rw[24],rw[25],"    F",rw[45],rw[46]
	sprintf tmpStr,"%12.2f%12.2f%12.2f      '%s'%8.2f    %8.2f",rw[23],rw[24],rw[25],"     F",rw[45],rw[46]
	labelWave[12] = tmpStr
	labelWave[13] = " Aperture (A1,A2) Sizes(mm)    Sep.(m)    Flip ON   Horiz. and Vert. Cur.(amps)"
	
//	sprintf tmpStr," %d  %d  %d  %d  %g  %g  %g",intw[19],intw[20],intw[21],intw[22],rw[47],rw[48],rw[49]
	sprintf tmpStr,"%6d%6d%6d%6d%10.3f%10.6f%10.6f",intw[19],intw[20],intw[21],intw[22],rw[47],rw[48],rw[49]
	labelWave[14] = tmpStr
	labelWave[15] = "      Rows        Cols       Factor   Qmin      Qmax"
	
	labelWave[16] = " Packed Counts by Rows (L -> R) and Top -> Bot"
	 
	//strings can be too long to print-- must trim to 255 chars
	Variable ii
	for(ii=0;ii<numTextLines;ii+=1)
		labelWave[ii] = (labelWave[ii])[0,240]
	endfor
	
	Duplicate/O data,spWave		
	Redimension/S/N=(pixelsX*pixelsY) spWave		//single precision (/S)
	
//	now need to convert the wave of data points into row of no more than 80 characters
// per row, comma delimited, not splitting any values
	Make/O/T/N=0 tw
	
	Variable sPt,ePt,ind=0,len
	sPt=0
	ePt=0
	len = pixelsX*pixelsY
	do
		tmpStr = Fill80Chars(spWave,sPt,ePt,len)
		InsertPoints ind, 1, tw
		tw[ind]=tmpStr
		ind+=1
//		Print "at top, ePt = ",ePt
		sPt=ePt
	while(ePt<len)
		
	Open refNum as fullpath
	wfprintf refNum,"%s\r",labelWave			//VAX uses just \r
	wfprintf refNum,"%s\r",tw
	Close refNum
	
	Killwaves/Z spWave,labelWave,tw		//clean up
	
	Print "2D ASCII File written for Grasp: ", GetFileNameFromPathNoSemi(fullPath)
	
	return(0)
End

Function/S Fill80chars(w,sPt,ePt,len)
	Wave w
	Variable sPt,&ePt,len
	
	String retStr
	Variable numChars=1,numPt=0
	
	retStr = " "		//lines start with a space
	do
		if( (numChars + strlen(num2str(w[sPt+numPt])) + 1 <= 80)	 && (sPt + numPt) < len )
			retStr += num2str(w[sPt+numPt]) +","
			numChars += strlen(num2str(w[sPt+numPt])) + 1
			numPt += 1
		else
			// pad to 80 chars
			ePt = sPt + numPt
			//printf "%d : ", strlen(retstr)
			if(strlen(retStr) < 80)
				do
					retStr += " "
				while(strlen(retStr) < 80)
			endif
			//Print strlen(retStr),sPt,ePt," : ",retstr
			break
		endif
	while(1)
	
	return(retStr)
End

//// end ASCII - old style export procedures


// NEW additions - May 2009
//ASCII export of data as 8-columns qx-qy-Intensity-err-qz-sigmaQ_parall-sigmaQ_perp-fShad
// + limited header information
//
// - May 2010:
// now the smearing is correct, and is now defined in terms of Q_parallel and Q_perpendicular
//
// - June 2010:
// TEMPORARY - I've added "fake" error that is sqrt(value). It really needs to be propogated
//  in a more correct way, but this is at least a placeholder for the error column
//
// - creates the qx and qy data here, based on the data and header information
//
// Need to ensure that the data being exported is the linear copy of the dataset - check the global
//
Function QxQy_Export(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	String destStr="",typeStr=""
	Variable step=1,refnum
	destStr = "root:Packages:NIST:"+type
	
	//must select the linear_data to export
	NVAR isLog = $(destStr+":gIsLogScale")
	if(isLog==1)
		typeStr = ":linear_data"
	else
		typeStr = ":data"
	endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	Wave data=$(destStr+typeStr)
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")

	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	String rawTag=""
	if(cmpstr(type,"RAW")==0)
		Make/O/T/N=8 proto={"none","none","none","none","none","none","none","none"}
		RawTag = "RAW Data File: "	
	else
		Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)
	endif
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	//check each wave - MUST exist, or will cause a crash
	If(!(WaveExists(data)))
		Abort "data DNExist QxQy_Export()"
	Endif
	If(!(WaveExists(intw)))
		Abort "intw DNExist QxQy_Export()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist QxQy_Export()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist QxQy_Export()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist QxQy_Export()"
	Endif
	
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
	
/////////
	Variable numTextLines=18
	Make/O/T/N=(numTextLines) labelWave
	labelWave[0] = "FILE: "+textw[0]+"   CREATED: "+textw[1]
	labelWave[1] = "LABEL: "+textw[6]
	labelWave[2] = "MON CNT   LAMBDA (A)  DET_OFF(cm)   DET_DIST(m)   TRANS   THICK(cm)"
	labelWave[3] = num2str(rw[0])+"  "+num2str(rw[26])+"       "+num2str(rw[19])+"     "+num2str(rw[18])
	labelWave[3] += "     "+num2str(rw[4])+"     "+num2str(rw[5])
	labelWave[4] = "BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP  "
	labelWave[5] = num2str(rw[16])+"  "+num2str(rw[17])+"  "+num2str(rw[23])+"    "+num2str(rw[24])+"    "
	labelWave[5] += num2str(rw[25])+"    "+num2str(rw[27])+"    "+num2str(rw[21])+"    "+textW[9]
	labelWave[6] =  "SAM: "+rawTag+samFiles
	labelWave[7] =  "BGD: "+proto[0]
	labelWave[8] =  "EMP: "+proto[1]
	labelWave[9] =  "DIV: "+proto[2]
	labelWave[10] =  "MASK: "+proto[3]
	labelWave[11] =  "ABS Parameters (3-6): "+proto[4]
	labelWave[12] = "Average Choices: "+proto[5]
	labelWave[13] = ""
	labelWave[14] = "*** Data written from "+type+" folder and may not be a fully corrected data file ***"
//	labelWave[15] = "Data columns are Qx - Qy - I(Qx,Qy)"
//	labelWave[15] = "Data columns are Qx - Qy - I(Qx,Qy) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow)"
	labelWave[15] = "Data columns are Qx - Qy - I(Qx,Qy) - err(I) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow)"
	labelWave[16] = "ERROR WAVE IS ONLY AN ESTIMATE  - 6/2010"
	labelWave[17] = "ASCII data created " +date()+" "+time()
	//strings can be too long to print-- must trim to 255 chars
	Variable ii,jj
	for(ii=0;ii<numTextLines;ii+=1)
		labelWave[ii] = (labelWave[ii])[0,240]
	endfor
//	If(cmpstr(term,"CR")==0)
//		termStr = "\r"
//	Endif
//	If(cmpstr(term,"LF")==0)
//		termStr = "\n"
//	Endif
//	If(cmpstr(term,"CRLF")==0)
//		termStr = "\r\n"
//	Endif
	
	Duplicate/O data,qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
	
//	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val
//	MyMat2XYZ(data,qx_val,qy_val,z_val) 		//x and y are [p][q] indexes, not q-vals yet
	
	Variable xctr,yctr,sdd,lambda,pixSize
	xctr = rw[16]
	yctr = rw[17]
	sdd = rw[18]
	lambda = rw[26]
	pixSize = rw[13]/10		//convert mm to cm (x and y are the same size pixels)
	
	qx_val = CalcQx(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)		//+1 converts to detector coordinate system
	qy_val = CalcQy(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	
	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val

///************
// do everything to write out the resolution too
	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	qval = CalcQval(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	qz_val = CalcQz(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr))		//(dx,dy)
	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr))^2 )		//radial distance from ctr to pt
	Redimension/N=(pixelsX*pixelsY) qz_val,qval,phi,r_dist
	//everything in 1D now
	Duplicate/O qval SigmaQX,SigmaQY,fsubS

	Variable L2 = rw[18]
	Variable BS = rw[21]
	Variable S1 = rw[23]
	Variable S2 = rw[24]
	Variable L1 = rw[25]
	Variable lambdaWidth = rw[27]	
	Variable usingLenses = rw[28]		//new 2007

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current good values
	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	DDet = rw[10]/10			// header value (X) is in mm, want cm here

	Variable ret1,ret2,ret3,nq
	nq = pixelsX*pixelsY
	ii=0
	
	do
		get2DResolution(qval[ii],phi[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,pixSize,usingLenses,r_dist[ii],ret1,ret2,ret3)
		SigmaQX[ii] = ret1	
		SigmaQY[ii] = ret2	
		fsubs[ii] = ret3	
		ii+=1
	while(ii<nq)	

//*********************

	// generate my own error wave for I(qx,qy)
	Duplicate/O z_val sw
	sw = sqrt(z_val)		//assumes Poisson statistics for each cell (counter)
	//	sw = 0.05*sw		// uniform 5% error? tends to favor the low intensity too strongly
	// get rid of the "bad" errorsby replacing the NaN, Inf, and zero with V_avg
	// THIS IS EXTREMEMLY IMPORTANT - if this is not done, there are some "bad" values in the 
	// error wave (things that are not numbers) - and this wrecks the smeared model fitting.
	// It appears to have no effect on the unsmeared model.
	WaveStats/Q sw
	sw = numtype(sw[p]) == 0 ? sw[p] : V_avg
	sw = sw[p] != 0 ? sw[p] : V_avg
	

	//not demo-compatible, but approx 8x faster!!	
#if(cmpstr(stringbykey("IGORKIND",IgorInfo(0),":",";"),"pro") == 0)
	Duplicate/O qx_val,qx_val_s
	Duplicate/O qy_val,qy_val_s
	Duplicate/O qz_val,qz_val_s
	Duplicate/O z_val,z_val_s
	Duplicate/O SigmaQx,sigmaQx_s
	Duplicate/O SigmaQy,sigmaQy_s
	Duplicate/O fSubS,fSubS_s
	Duplicate/O sw,sw_s
	
	//so that double precision is not written ou
	Redimension/S qx_val_s,qy_val_s,qz_val_s,z_val_s,sigmaQx_s,sigmaQy_s,fSubS_s,sw_s
	
//	Save/G/M="\r\n" labelWave,qx_val,qy_val,z_val as fullpath	// without resolution
	Save/G/M="\r\n" labelWave,qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s as fullpath	// write out the resolution information
#else
	Open refNum as fullpath
	wfprintf refNum,"%s\r\n",labelWave
	fprintf refnum,"\r\n"
//	wfprintf refNum,"%8g\t%8g\t%8g\r\n",qx_val,qy_val,z_val
	wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val,qy_val,z_val,sw,qz_val,SigmaQx,SigmaQy,fSubS
	Close refNum
#endif
	
	KillWaves/Z qx_val_s,qy_val_s,z_val_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,sw,sw_s
	
	Killwaves/Z spWave,labelWave,qx_val,qy_val,z_val,qval,qz_val,sigmaQx,SigmaQy,fSubS,phi,r_dist
	
	Print "QxQy_Export File written: ", GetFileNameFromPathNoSemi(fullPath)
	return(0)

End


//Function MyMat2XYZ(mat,xw,yw,zw)
//	WAVE mat,xw,yw,zw
//
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
//	
//	xw= mod(p,pixelsX)		// X varies quickly
//	yw= floor(p/pixelsY)	// Y varies slowly
//	zw= mat(xw[p])(yw[p])
//
//End

//converts xyz triple to a matrix
//MAJOR assumption is that the x and y-spacings are LINEAR
// (ok for small-angle approximation)
//
// currently unused
//
Function LinXYZToMatrix(xw,yw,zw,matStr)
	WAVE xw,yw,zw
	String matStr
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	//mat is "zw" redimensioned to a matrix
	Make/O/N=(pixelsX*pixelsY) $matStr
	WAVE mat=$matStr
	mat=zw
	Redimension/N=(pixelsX,pixelsY) mat
	WaveStats/Q xw
	SetScale/I x, V_min, V_max, "",mat
	WaveStats/Q yw
	SetScale/I y, V_min, V_max, "",mat
	
	Display;Appendimage mat
	ModifyGraph lowTrip=0.0001
	ModifyGraph width={Plan,1,bottom,left},height={Plan,1,left,bottom}
	ModifyImage $matStr ctab={*,*,YellowHot,0}
	
	return(0)
End