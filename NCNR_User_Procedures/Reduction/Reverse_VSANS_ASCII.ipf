#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access


// I don't have any idea what this function is for or when I wrote it 2022?
// What did I need it for?
//

Macro ReverseVSANSData()

	fReverseData()
end

Function fReverseData()

	String folderStr=""
	Prompt folderStr,"Data folder",popup,A_OneDDataInMemory()
	DoPrompt "Pick the data folder",folderStr
	
	SetDataFolder $("root:"+folderStr)
	
	String detSavePath = folderStr+"_REV"
	// declare the waves, and reverse them
	Wave/T labelWave=header
	
	Wave qx_val_s = $(folderStr + "_qx")
	Wave qy_val_s = $(folderStr + "_qy")
	Wave qz_val_s = $(folderStr + "_qz")
	Wave z_val_s = $(folderStr + "_i")
	Wave sw_s = $(folderStr + "_iErr")
	Wave SigmaQx_s = $(folderStr + "_sQpl")
	Wave SigmaQy_s = $(folderStr + "_sQpp")
	Wave fSubS_s = $(folderStr + "_fs")
	Wave MaskData_s = $(folderStr + "_msk")

	MatrixOp/O qx_val_s = reverseCols(qx_val_s)
	MatrixOp/O qy_val_s = reverseCols(qy_val_s)
	MatrixOp/O qz_val_s = reverseCols(qz_val_s)
	MatrixOp/O z_val_s = reverseCols(z_val_s)
	MatrixOp/O sw_s = reverseCols(sw_s)
	MatrixOp/O SigmaQx_s = reverseCols(SigmaQx_s)
	MatrixOp/O SigmaQy_s = reverseCols(SigmaQy_s)
	MatrixOp/O fSubS_s = reverseCols(fSubS_s)
	MatrixOp/O MaskData_s = reverseCols(MaskData_s)
	
	
	// re-write out the new data file, including the header
	// force the name, don't ask
	
	//not demo-compatible, but approx 8x faster!!	
#if(strsearch(stringbykey("IGORKIND",IgorInfo(0),":",";"), "demo", 0 ) == -1)
		
		Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s as detSavePath	// write out the resolution information

#else
		Open refNum as detSavePath
		wfprintf refNum,"%s\r\n",labelWave
		fprintf refnum,"\r\n"
//		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,MaskData_s
		Close refNum

#endif
	
	
	SetDataFolder root:
	return(0)
end

