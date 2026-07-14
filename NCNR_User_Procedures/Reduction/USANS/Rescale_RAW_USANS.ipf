#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

/////////////////////////////////
//
// -- MARCH 2023
//
//		rescales a raw data file
// -- rescales all of the count data (detCts, transDetCts)
// -- but does not rescale the counting time or the monitor counts
//
// -- useful if data was collected at different reactor power levels
// and one set needs to be rescaled to the other
//

Proc SelectFileToRescale(file1, scale)
	string file1
	variable scale = 2
	Prompt file1, "First File", popup, BT5FileList("")
	Prompt scale, "Multiplicative scale factor"
	//	Prompt file2, "Second File", popup, BT5FileList("")

	//	Print file1,file2

	LoadAndRescaleUSANS(file1, scale)

	string filen = file1[0, strlen(file1) - 5] + "_Rescaled" + ".BT5"

	SaveRescaledUSANS(filen)
EndMacro

Proc SaveRescaledUSANS(newName)
	string newName
	Prompt newName, "Enter new FileName"

	SaveRescaledBT5File(newName, 1) // 1 asks to confirm the name w/ a dialog

EndMacro

// if you bypass the dialog, newname needs to be a full path
Function SaveRescaledBT5File(string newName, variable dialog)

	variable refnum
	string   fullPath

	WAVE/T tw1 = tw1

	if(dialog)
		PathInfo/S savePathName
		fullPath = DoSaveFileDialog("Save data as", fname = newName)
		if(cmpstr(fullPath, "") == 0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		endif
		newName = FullPath
		//Print "dialog fullpath = ",fullpath
	endif

	Open refNum as newName
	wfprintf refnum, "%s", tw1
	Close refnum

	return (0)
End

//
//		rescales a raw data file
// -- rescales all of the count data (detCts, transDetCts)
// -- but does not rescale the counting time or the monitor counts
//
//
//
Function LoadAndRescaleUSANS(string file1, variable scale)

	SVAR ext = root:Packages:NIST:USANS:Globals:MainPanel:gUExt

	//load file into a textWave
	Make/O/T/N=200 tw1

	string fname    = ""
	string fpath    = ""
	string fullPath = ""
	variable ctTime1, ang11, ang21
	//	Variable ctTime2,ang12,ang22
	variable dialog = 1

	PathInfo/S savePathName
	fpath = S_Path

	if(strlen(S_Path) == 0)
		DoAlert 0, "You must select a Save Path... from the main USANS_Panel"
		return (0)
	endif

	fname = fpath + file1
	LoadBT5_toWave(file1, fpath, tw1, ctTime1, ang11, ang21) //redimensions tw1
	Print "File 1: time, angle1, angle2", ctTime1, ang11, ang21

	variable v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16
	variable a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16
	variable ii, valuesRead, countTime, num, refnum
	string s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
	string filen     = ""
	string fileLabel = ""
	string buffer    = ""
	string str       = ""
	string term      = "\r\n"

	//	//line 0, info to update
	//	buffer = tw1[0]
	//	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s",s1,s2,s3,s4,s5,s6,v1,v2,s7,v3,s8
	//	sprintf str,"%s %s 'I'        %d    1  'TIME'   %d  'SUM'",s1,s2+" "+s3+" "+s4+" "+s5,ctTime1+ctTime2,v3
	////	num=v3
	//	tw3[0] = str+term
	//	tw3[1] = tw1[1]		//labels, direct copy
	//
	//	//line 2, sample label
	//	buffer = tw1[2]
	//	sscanf buffer,"%s",s1
	//	tw3[2] = s1 + " = "+file1+" + "+file2+term
	//	tw3[3,12] = tw1[p]		//unused values, direct copy

	//
	// no changes in lines 0-12 of the file
	//
	num = numpnts(tw1) //
	//parse two lines at a time per data point,starting at 13
	for(ii = 13; ii < (num - 1); ii += 2)
		buffer = tw1[ii]
		sscanf buffer, "%g%g%g%g%g", v1, v2, v3, v4, v5 // 5 values here now

		//		buffer = tw2[ii]
		//		sscanf buffer,"%g%g%g%g%g",a1,a2,a3,a4,a5		// 5 values here now
		//
		//		if(a1 != v1)
		//			DoAlert 0,"Angles don't match and can't be directly added"
		//			//Killwaves/Z tw1,tw2,tw3
		//			abort
		//			return(0)
		//		endif

		// v1 is the angle
		// 2nd value (v2) is the time, do not rescale this
		// 3rd value is the beam monitor, do not rescale this
		//

		//		v2 *= scale
		//		v3 *= scale
		v4 *= scale
		v5 *= scale
		sprintf str, "     %g   %g   %g   %g   %g", v1, v2, v3, v4, v5
		tw1[ii] = str + term

		buffer = tw1[ii + 1]
		sscanf buffer, "%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g", v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16

		//rescale all of the count values except v1, which is the monitor counts
		//
		//		v1 *= scale
		v2  *= scale
		v3  *= scale
		v4  *= scale
		v5  *= scale
		v6  *= scale
		v7  *= scale
		v8  *= scale
		v9  *= scale
		v10 *= scale
		v11 *= scale
		v12 *= scale
		v13 *= scale
		v14 *= scale
		v15 *= scale
		v16 *= scale

		sprintf str, "%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g", v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16
		tw1[ii + 1] = str + term

	endfor

	return (0)
End

