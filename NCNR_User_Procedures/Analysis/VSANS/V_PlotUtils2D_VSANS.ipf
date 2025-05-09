#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// JAN 2021
// 2D NXcanSAS is the preferred output format for VSANS data, but QxQy_ASCII is still
// a valid output format. 

// NXcanSAS output puts all of the 2D reduced data into a single nexus file, storing each
// detector panel in a structure similar to the raw data file.
//
// QxQy_ASCII output produces individual .DAT files for each detector
// panel and a single _COMBINED.DAT file with all panels in one. (meant for sasView)
//


//
// this file contains simple routines to load/plot .DAT files
//
// see instead the procedures in V_2DLoader_NXcanSAS.ipf
// for simple load/plot of the 2D NXcanSAS output
//




//
// Load in and plot the 9-column VSANS QxQy data file
//
//		Data columns are Qx - Qy - I(Qx,Qy) - err(I) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow) - Mask

//Proc V_LoadQxQy_VSANS_TopBottom()
//	V_LoadQxQy_VSANS(128,48)
//End
//
//Proc V_LoadQxQy_VSANS_LeftRight()
//	V_LoadQxQy_VSANS(48,128)
//End


Proc V_LoadQxQy_ASCII_DAT_VSANS()
	
	SetDataFolder root:
	
	LoadWave/G/D/W/A
	String fileName = S_fileName
	String path = S_Path
	Variable numCols = V_flag

	Variable numX,numY

	String w0,w1,w2,w3,w4,w5,w6,w7,w8
	String n0,n1,n2,n3,n4,n5,n6,n7,n8
	
	
	if(numCols == 9 || numCols == 8)
		// put the names of the 9 loaded waves into local names
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		n5 = StringFromList(5, S_waveNames ,";" )
		n6 = StringFromList(6, S_waveNames ,";" )
		n7 = StringFromList(7, S_waveNames ,";" )
		if(numCols == 9)
			n8 = StringFromList(8, S_waveNames ,";" )
		endif
		
		//remove the semicolon AND period from file names
		w0 = CleanupName((S_fileName + "_qx"),0)
		w1 = CleanupName((S_fileName + "_qy"),0)
		w2 = CleanupName((S_fileName + "_i"),0)
		w3 = CleanupName((S_fileName + "_iErr"),0)
		w4 = CleanupName((S_fileName + "_qz"),0)
		w5 = CleanupName((S_fileName + "_sQpl"),0)
		w6 = CleanupName((S_fileName + "_sQpp"),0)
		w7 = CleanupName((S_fileName + "_fs"),0)
		if(numCols ==9)
			w8 = CleanupName((S_fileName + "_msk"),0)
		endif

		String baseStr=w1[0,strlen(w1)-4]
		if(DataFolderExists("root:"+baseStr))
				DoAlert 1,"The file "+S_filename+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
				if(V_flag==2)	//user selected No, don't load the data
					SetDataFolder root:
					KillWaves/Z $n0,$n1,$n2,$n3,$n4,$n5,$n6,$n7,$n8		// kill the default waveX that were loaded
					return		//quits the macro
				endif
				SetDataFolder $("root:"+baseStr)
		else
			NewDataFolder/S $("root:"+baseStr)
		endif
		
		//read in the 30 lines of header (18th line starts w/ ASCII... 19th line is blank)
		Variable nHeader=30
		Make/O/T/N=(nHeader) header
		Variable refnum,ii
		string tmpStr=""
		Open/R refNum  as (path+filename)
		ii=0
		do
			tmpStr = ""
			FReadLine refNum, tmpStr
			header[ii] = tmpStr
			ii+=1
		while(ii < nHeader)		
		Close refnum		
		
		////overwrite the existing data, if it exists
		Duplicate/O $("root:"+n0), $w0
		Duplicate/O $("root:"+n1), $w1
		Duplicate/O $("root:"+n2), $w2
		Duplicate/O $("root:"+n3), $w3
		Duplicate/O $("root:"+n4), $w4
		Duplicate/O $("root:"+n5), $w5
		Duplicate/O $("root:"+n6), $w6
		Duplicate/O $("root:"+n7), $w7
		if(numCols == 9)
			Duplicate/O $("root:"+n8), $w8
		endif
	endif		//9-columns


// figure out if the data was TB, LR, or COMBINED
//
	String typeStr=""

	if(strsearch(filename,"_FT",0) > 0)
		typeStr="TB"
	endif
	if(strsearch(filename,"_FB",0) > 0)
		typeStr="TB"
	endif
	if(strsearch(filename,"_MT",0) > 0)
		typeStr="TB"
	endif
	if(strsearch(filename,"_MB",0) > 0)
		typeStr="TB"
	endif

	if(strsearch(filename,"_FL",0) > 0)
		typeStr="LR"
	endif
	if(strsearch(filename,"_FR",0) > 0)
		typeStr="LR"
	endif
	if(strsearch(filename,"_ML",0) > 0)
		typeStr="LR"
	endif
	if(strsearch(filename,"_MR",0) > 0)
		typeStr="LR"
	endif
	
	if(strsearch(filename,"_COMBINED",0) > 0)
		typeStr = "COMBINED"
	endif

	if(cmpstr(typeStr,"TB")==0)
		numX=128
		numY=48
	endif
	if(cmpstr(typeStr,"LR")==0)
		numX=48
		numY=128
	endif
	
	// it's probably SANS data...
	if(cmpstr(typeStr,"")==0)
		numX=128
		numY=128
	endif
	
	
	// single panels are converted into a matrix to plot out
	// the combined panels are plotted as points with f(z) color scale
	//
	if(cmpstr(typeStr,"COMBINED")==0)
	
		Display /W=(560.4,39.8,942.6,387.2) $w1 vs $w0
		ModifyGraph mode=3
		ModifyGraph marker=16
		ModifyGraph msize=1
		ModifyGraph zColor($w1)={$w3,*,*,ColdWarm}
		ModifyGraph logZColor=1
	
	else
	
		/// do this for all 2D data, whether or not resolution information was read in
		
		Variable/G gIsLogScale = 0
		
		Variable num=numpnts($w0)
		// assume that the Q-grid is "uniform enough" for DISPLAY ONLY
		// use the 3 original waves for all of the fitting...
	
	// for L/R x=48,y=128
	// for T/B x=128,y=48
		
		V_ConvertQxQy2Mat($w0,$w1,$w2,numX,numY,baseStr+"_mat")
	
		if(numCols == 9)		//mask is present
			V_ConvertQxQy2Mat($w0,$w1,$w8,numX,numY,baseStr+"_mat_mask")
			Display/W=(40,400,40+3*numX,400+3*numY);Appendimage $(baseStr+"_mat_mask")
		endif
		Duplicate/O $(baseStr+"_mat"),$(baseStr+"_lin") 		//keep a linear-scaled version of the data
	
		Display/W=(40,40,40+3*numX,40+3*numY);Appendimage $(baseStr+"_mat")
		ModifyImage $(baseStr+"_mat") ctab= {*,*,ColdWarm,0}
	
		if(exists("root:Packages:NIST:VSANS:Globals:logLookupWave")==1)
			ModifyImage $(baseStr+"_mat") ctabAutoscale=0,lookup= root:Packages:NIST:VSANS:Globals:logLookupWave
		endif
		
	//	PlotQxQy(baseStr)		//this sets the data folder back to root:!!

	endif

	//clean up		
	SetDataFolder root:
	KillWaves/Z $n0,$n1,$n2,$n3,$n4,$n5,$n6,$n7,$n8
	
EndMacro




// for reformatting the matrix of VSANS QxQy data after it's been read in
//
// this assumes that:
// --QxQy data was written out in the format specified by the Igor macros, that is the x varies most rapidly
//
// TODO -- this needs to be made generic for reading in different panels with different XY dimensions
// x- add the XY dimensions to the QxQyASCII file header somewhere so that it can be read in and used here
//
// the SANS analysis 2D loader assumes that the matrix is square, mangling the VSANS data.
// the column data (for fitting) is still fine, but the matrix representation is incorrect.
//
Function V_ConvertQxQy2Mat(Qx,Qy,inten,numX,numY,matStr)
	Wave Qx,Qy,inten
	Variable numX,numY
	String matStr
	
	String folderStr=GetWavesDataFolder(Qx,1)
	
//	Variable numX,numY
//	numX=48
//	numY=128
	Make/O/D/N=(numX,numY) $(folderStr + matStr)
	Wave mat=$(folderStr + matStr)
	
	WaveStats/Q Qx
	SetScale/I x, V_min, V_max, "", mat
	WaveStats/Q Qy
	SetScale/I y, V_min, V_max, "", mat
	
	Variable xrows=numX
	
	mat = inten[q*xrows+p]
	
	return(0)
End

