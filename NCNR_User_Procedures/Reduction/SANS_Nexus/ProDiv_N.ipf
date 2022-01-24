#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


// JAN 2022
//
// Updated to read/write a Nexus-style DIV file
//
//
// -- as of 20 JAN 2022
// ** Read/Write are UNTESTED -- I need more data to practice with
//




//********************
// Vers. 1.2 092101
//
// Procedures to create a "DIV" file for use as a detector sensitivity file
// Follows the same procedure as PRODIV on the VAX
// -requires two "full" reduced runs from plexiglass or water
// -prompts the user for the locations of the offset and no-offset files
// and for the range of data to replace
// - then writes of the "div" file and fake-VAX format, which is rather ugly
// since the DIV file is floating point...
//
//
// 08 AUG 03
// allowed for creation of DIV files on 8m SANS with two beamstops
//
// JAN2006 - not modified! still hard-wired to take a 128x128 detector image
//
// Oct 2009 - SRK - pulled out the writing of the data file to NCNR_DataReadWrite.ipf
//      leaving a stub Write_DIV_File() for the writer. Fully corrected, patched, and normalized DIV data
//      is written out from "type" folder. The DIV file written out must be written in a 
//      format that is readable by ReadHeaderAndWork(type,fname). Each facility gets to pick their own format.
//
//      no longer hard-wired to 128x128
//
//*********************


//works on the data in "type" folder
//sums all of the data, and normalizes by the number of cells (=pixelX*pixelY)
// calling procedure must make sure that the folder is on linear scale FIRST
Function NormalizeDIV(type)
	String type
	
	Wave data = getDetectorDataW(type)		//this will be the linear data
	WAVE data_lin=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	
	Variable totCts=sum(data,Inf,-Inf)		//sum all of the data
	NVAR pixelX = root:myGlobals:gNPixelsX
	NVAR pixelY = root:myGlobals:gNPixelsY

	
	data /= totCts
	data *= pixelX*pixelY
	
	data_lin /= totCts
	data_lin *= pixelX*pixelY
	
	data_err /= totCts
	data_err *= pixelX*pixelY
		
	return(0)
End

// prompts the user for the location of the "COR" -level data 
// data can be copied to any data folder (except DIV) for use here...
//
// then there is a "pause for user" to allow the user to select the "box"
// in the ON-AXIS datset that is to be replaced by the data in the off-axis data
//
// corrections are done...
//
// finally, the DIV file is written to disk
Function MakeDIVFile(ctrType,offType)
	String ctrType,offType
	
	Prompt ctrType,"On-Center Plex data (corrected)",popup,"STO;SUB;BGD;COR;CAL;SAM;EMP;"
	Prompt offType,"Offset Plex data (corrected)",popup,"STO;SUB;BGD;COR;CAL;SAM;EMP;"
	DoPrompt "Pick the data types",ctrType,offType
	//"COR" data in both places - reduction must be done ahead of time
	
	//temporarily set data display to linear
	NVAR gLog = root:Packages:NIST:gLogScalingAsDefault
	Variable oldState = gLog
	gLog=0	//linear
	
	if(V_Flag==1)
		//user cancelled
		return(1)
	endif

	
	//show the ctrType
	//get the xy range to replace
	Execute "ChangeDisplay(\""+ctrType+"\")"
	
	NewPanel/K=2/W=(139,341,382,432) as "Get XY Range"
	DoWindow/C tmp_GetXY
	AutoPositionWindow/E/M=1/R=SANS_Data
	DrawText 15,20,"Find the (X1,X2) and (Y1,Y2) range to"
	DrawText 15,40,"replace and press continue"
	Button button0, pos={80,58},size={92,20},title="Continue"
	Button button0,proc=XYContinueButtonProc
	
	PauseForUser tmp_GetXY,SANS_Data
	
	//replace the center section of the "on" data with the center of the "off" data
	Variable x1,x2,y1,y2
	GetXYRange(x1,x2,y1,y2)
	Printf "X=(%d,%d)  Y=(%d,%d)\r", x1,x2,y1,y2
	ReplaceDataBlock(ctrType,offType,x1,x2,y1,y2)
	
	DoAlert 1,"Is this NG1 data with a second beamstop?"
	if(V_flag==1)
		GetXYRange(x1,x2,y1,y2)
		Printf "X=(%d,%d)  Y=(%d,%d)\r", x1,x2,y1,y2
		ReplaceDataBlock(ctrType,offType,x1,x2,y1,y2)
	endif
	
	//normalize the new data (and show it)
	NormalizeDiv(ctrtype)
	UpdateDisplayInformation(ctrtype)
	
	// setup the Nexus DIV structure
	Execute "Setup_SANS_DIV_Struct()"
	
	// copy the DIV file to the new structure
	CopyDIVToSave_OnePanel(ctrtype)
	
	//write out the new data file
	Execute "Save_SANS_DIV_Nexus(\"Test_SANS_DIV_file\")"
//	Write_DIV_File(ctrtype)
	
	
	gLog = oldState		//set log/lin pref back to user - set preference
	Return(0)
End



//
// copies the detector panel from a work folder, (at COR level)
// to the DIV structure to write out
//
//
Function CopyDIVToSave_OnePanel(type)
	String type
	
	String topath = "root:SANS_DIV_file:entry:instrument:detector"
	String fromPath = "root:Packages:NIST:"+type+":entry:instrument:detector"
	
	
	Duplicate/O $(fromPath+":data") $(toPath+":data")
	Duplicate/O $(fromPath+":linear_data_error") $(toPath+":linear_data_error")
			
	return(0)
End




//ctrData is changed -- offData is not touched
//simple replacement of the selected data...
//
// working in detector coordinates
Function ReplaceDataBlock(ctrType,offType,x1,x2,y1,y2)
	String ctrType,offType
	Variable x1,x2,y1,y2
	
	//do it crudely, with nested for loops
	WAVE ctrData=$("root:Packages:NIST:"+ctrtype+":data")
	WAVE offData=$("root:Packages:NIST:"+offtype+":data")
	
	WAVE ctrData_lin=$("root:Packages:NIST:"+ctrtype+":linear_data")
	WAVE offData_lin=$("root:Packages:NIST:"+offtype+":linear_data")
	
	WAVE ctrData_err=$("root:Packages:NIST:"+ctrtype+":linear_data_error")
	WAVE offData_err=$("root:Packages:NIST:"+offtype+":linear_data_error")
	
	Variable ii,jj
	
	for(ii=x1;ii<=x2;ii+=1)
		for(jj=y1;jj<=y2;jj+=1)
			ctrData[ii][jj] = offData[ii][jj]
			ctrData_lin[ii][jj] = offData_lin[ii][jj]
			ctrData_err[ii][jj] = offData_err[ii][jj]
		endfor
	endfor
	
	return(0)
End

//continue button waiting for the user to pick the range, and continue the execution
//
Function XYContinueButtonProc(ctrlName)
	String ctrlName
	
	DoWindow/K tmp_GetXY
End

// prompts the user to enter the XY range for the box replacement
// user can get these numbers by printing out marquee coordinates to the command window
//
Function GetXYRange(x1,x2,y1,y2)
	Variable &x1,&x2,&y1,&y2
	
	Variable x1p,x2p,y1p,y2p
	Prompt x1p,"X1"
	Prompt x2p,"X2"
	Prompt y1p,"Y1"
	Prompt y2p,"Y2"
	DoPrompt "Enter the range to replace",x1p,x2p,y1p,y2p
	x1=x1p
	x2=x2p
	y1=y1p
	y2=y2p
	
//	Print x1,x2,y1,y2
	Return(0)
End


/////////////////////
//
// for the DIV "protocol" panel, I probably need to have parts of the protocol panel initialized...
// folders are generated at the startup initialization, before protocol panel
//
Proc BuildDIVPanel()
	DoWindow/F DIV_Panel
	if(V_flag==0)
		InitDIVPanel()
		DIV_Panel()
	Endif
End

//initialization procedure for the protocol panel
//note that :gAbsStr is also shared (common global) to that used in 
//the questionnare form of the protcol (see protocol.ipf)
//
//0901, uses 8 points in protocol wave
Proc InitDIVPanel()

	//set up the global variables needed for the protocol panel
	//global strings to put in a temporary protocol textwave
	Variable ii=0,nsteps=8
	String waveStr="DIV_Protocol"
	SetDataFolder root:myGlobals:Protocols
	Make/O/T/N=(nsteps) $"root:myGlobals:Protocols:DIV_Protocol" = ""
	
	DIV_protocol[2] = "none"
	DIV_protocol[3] = "none"
	DIV_protocol[4] = "none"
	DIV_protocol[5] = "AVTYPE=none;"
	DIV_protocol[6] = "DRK=none,DRKMODE=0,"
	

	String/G root:myGlobals:Protocols:gPlex="Plex"
	String/G root:myGlobals:Protocols:gPlexBgd="Bgd"
	String/G root:myGlobals:Protocols:gPlexEmp="Emp"
	String/G root:myGlobals:Protocols:gPlex_off="Plex offset"
	String/G root:myGlobals:Protocols:gPlexBgd_off="Bgd offset"
	String/G root:myGlobals:Protocols:gPlexEmp_off="Emp offset"
	String/G root:myGlobals:Protocols:gPlexName="Plex_date.div"
	
	Variable/G root:myGlobals:Protocols:gPlexX1=45
	Variable/G root:myGlobals:Protocols:gPlexX2=87
	Variable/G root:myGlobals:Protocols:gPlexY1=43
	Variable/G root:myGlobals:Protocols:gPlexY2=85
	Variable/G root:myGlobals:Protocols:gPlexTrans=0.48
	
	SetDataFolder root:
	
End

// load in one on-center file and show the box
//
Function ShowBoxButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(cmpstr(ba.ctrlName, "ShowBox") == 0)
			
				//parse for the first run number
				SVAR gPlex = root:myGlobals:Protocols:gPlex
				String item,fname
				
				item = StringFromList(0, gPlex ,",")
				fname = N_FindFileFromRunNumber(str2num(item))
				if(strlen(fname) == 0)
					Abort "Bad file number in Plex field"
				endif
				// load the file
				ReadHeaderAndData(fname,"RAW")	//this is the full Path+file
				UpdateDisplayInformation("RAW")
				//draw a box of the specified size. This is persistent on the display as you scroll to the offset data
				NVAR x1 = root:myGlobals:Protocols:gPlexX1
				NVAR x2 = root:myGlobals:Protocols:gPlexX2
				NVAR y1 = root:myGlobals:Protocols:gPlexY1
				NVAR y2 = root:myGlobals:Protocols:gPlexY2
				
				SetDrawLayer/W=SANS_Data/K UserFront			//set the layer, and clear it
				SetDrawEnv/W=SANS_Data xcoord=bottom,ycoord=left,fillpat=0,linethick=3,linefgc=(65535, 65535, 65535)
				DrawRect/W=SANS_Data x1, y2, x2, y1
				
				Button $ba.ctrlName,title="Clear Box",rename=HideBox,win=DIV_Panel
				
			else
				if(winType("SANS_Data")==1)
					SetDrawLayer/W=SANS_Data/K UserFront			//set the layer, and clear it
					Button $ba.ctrlName,title="Show Box",rename=ShowBox,win=DIV_Panel
				else
					Button $ba.ctrlName,title="Show Box",rename=ShowBox,win=DIV_Panel
				endif
			endif	
			
			break
	endswitch

	return 0
End

// do everything...
//
Function GenerateDIVButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable err=0
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			//temporarily set data display to linear
			NVAR gLog = root:Packages:NIST:gLogScalingAsDefault
			Variable oldState = gLog
			gLog=0	//linear
			
			
			SVAR gPlex = root:myGlobals:Protocols:gPlex
			SVAR gPlexBgd = root:myGlobals:Protocols:gPlexBgd
			SVAR gPlexEmp = root:myGlobals:Protocols:gPlexEmp
			SVAR gPlex_off = root:myGlobals:Protocols:gPlex_off
			SVAR gPlexBgd_off = root:myGlobals:Protocols:gPlexBgd_off
			SVAR gPlexEmp_off = root:myGlobals:Protocols:gPlexEmp_off
			SVAR gPlexName = root:myGlobals:Protocols:gPlexName
			
			NVAR X1 = root:myGlobals:Protocols:gPlexX1
			NVAR X2 = root:myGlobals:Protocols:gPlexX2
			NVAR Y1 = root:myGlobals:Protocols:gPlexY1
			NVAR Y2 = root:myGlobals:Protocols:gPlexY2
			NVAR gPlexTrans = root:myGlobals:Protocols:gPlexTrans
			
			WAVE/T proto = $"root:myGlobals:Protocols:DIV_Protocol"
			
			String item,fname,str
			Variable ii,num
		// reduce the on-center
			//patch trans
			num = ItemsInList(gPlex, ",")
			for(ii=0;ii<num;ii+=1)
				item = StringFromList(ii, gPlex ,",")
				fname = N_FindFileFromRunNumber(str2num(item))
				if(strlen(fname) == 0)
					Abort "Bad file number in no offset Plex field"
				endif
				writeSampleTransmission(fname,gPlexTrans)
			endfor
			
			//go through the protocol
			str = N_ParseRunNumberList(gPlexBgd)
			if(strlen(str) > 0)
				proto[0] = str
			else
				Abort "Bad file number in no offset Bgd"
			endif
			str = N_ParseRunNumberList(gPlexEmp)
			if(strlen(str) > 0)
				proto[1] = str
				err = CheckDIVBeamCenter(str,65,65)
				if(err)
					Abort "On-center EMP files do not have correct beam center"
				endif
			else
				Abort "Bad file number in no offset Emp"
			endif
			str = N_ParseRunNumberList(gPlex)
			if(strlen(str) > 0)
				err = CheckDIVBeamCenter(str,65,65)
				if(err)
					Abort "On-center PLEX files do not have correct beam center"
				endif
				ExecuteProtocol("root:myGlobals:Protocols:DIV_Protocol",str)
			else
				Abort "Bad file number in no offset Plex"
			endif
			// move it into STO
			Execute "CopyWorkFolder(\"COR\",\"STO\")"
			
			
			
		// reduce the off-center, keep in COR
			//patch trans
			num = ItemsInList(gPlex_off, ",")
			for(ii=0;ii<num;ii+=1)
				item = StringFromList(ii, gPlex_off ,",")
				fname = N_FindFileFromRunNumber(str2num(item))
				if(strlen(fname) == 0)
					Abort "Bad file number in Plex field"
				endif
				writeSampleTransmission(fname,gPlexTrans)
			endfor
			
			//go through the protocol
			str = N_ParseRunNumberList(gPlexBgd_off)
			if(strlen(str) > 0)
				proto[0] = str
			else
				Abort "Bad file number in offset Bgd"
			endif
			str = N_ParseRunNumberList(gPlexEmp_off)
			if(strlen(str) > 0)
				proto[1] = str
				err = CheckDIVBeamCenter(str,110,65)
				if(err)
					Abort "Off-center EMP files do not have correct beam center"
				endif
			else
				Abort "Bad file number in offset Emp"
			endif
			str = N_ParseRunNumberList(gPlex_off)
			if(strlen(str) > 0)
				err = CheckDIVBeamCenter(str,110,65)
				if(err)
					Abort "Off-center PLEX files do not have correct beam center"
				endif
				ExecuteProtocol("root:myGlobals:Protocols:DIV_Protocol",str)
			else
				Abort "Bad file number in offset Emp"
			endif
			
		
		// replace the patch
		// on-center data is changed (STO)
			ReplaceDataBlock("STO","COR",x1,x2,y1,y2)
		// normalize
			NormalizeDiv("STO")
			UpdateDisplayInformation("STO")
			
			
			// setup the Nexus DIV structure
			Execute "Setup_SANS_DIV_Struct()"
			
			// copy the DIV file to the new structure
			CopyDIVToSave_OnePanel("STO")
			
			//write out the new data file
			Execute "Save_SANS_DIV_Nexus(\"Test_SANS_DIV_file\")"
	
//		//write out the new data file
//			Write_DIV_File("STO")
				
			gLog=oldState		//revert display preference to old state	
			break
	endswitch

	return 0
End

// if a dark color is used, then
//�SetVariable setvar0 labelBack=(65535,65535,65535)
// for each variable will give a white background to the label text
Proc DIV_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(594,44,932,570)/K=1 as "DIV_Panel"
	DoWindow/C DIV_Panel
//	ModifyPanel cbRGB=(35867,28177,65535)		//purple
//	ModifyPanel cbRGB=(1,16019,65535)				//electric blue
	ModifyPanel cbRGB=(36631,59604,33902)		//spring green
	SetDrawLayer UserBack
	DrawRect 71,324,145,391
	TitleBox title0,pos={14,16},size={50,20},title="No Offset"
	TitleBox title0_1,pos={17,125},size={35,20},title="Offset"
	SetVariable setvar0,pos={15,46},size={250,15},title="PLEX",value= root:myGlobals:Protocols:gPlex
	SetVariable setvar0_1,pos={16,69},size={250,15},title="EMP",value= root:myGlobals:Protocols:gPlexEmp
	SetVariable setvar0_2,pos={14,92},size={250,15},title="BGD",value= root:myGlobals:Protocols:gPlexBgd
	SetVariable setvar1,pos={17,158},size={250,15},title="PLEX",value= root:myGlobals:Protocols:gPlex_off
	SetVariable setvar001,pos={18,181},size={250,15},title="EMP",value= root:myGlobals:Protocols:gPlexEmp_off
	SetVariable setvar002,pos={16,204},size={250,15},title="BGD",value= root:myGlobals:Protocols:gPlexBgd_off
	SetVariable setvar002_1,pos={14,251},size={150,15},title="Transmission"
	SetVariable setvar002_1,limits={0,1,0.01},value= root:myGlobals:Protocols:gPlexTrans
//	SetVariable setvar003,pos={16,441},size={250,15},title="DIV FILE NAME"
//	SetVariable setvar003,value= root:myGlobals:Protocols:gPlexName
	Button ShowBox,pos={226,325},size={90,20},proc=ShowBoxButtonProc,title="Show Box"
	Button button1,pos={25,430},size={150,20},proc=GenerateDIVButtonProc,title="Generate DIV File"
	Button button2,pos={25,460},size={150,20},proc=ReloadDIVButtonProc,title="Load DIV File"
	Button button4,pos={240,481},size={80,20},proc=DoneDIVButtonProc,title="Done"
	Button button3,pos={240,10},size={50,20},proc=DIVHelpButtonProc,title="Help"
	Button button5,pos={25,490},size={150,20},proc=CompareDIVButtonProc,title="Compare DIV Files"
	SetVariable setvar00201,pos={84,297},size={50,15},limits={0,root:myGlobals:gNPixelsY-1,1},title=" ",value= root:myGlobals:Protocols:gPlexY2
	SetVariable setvar00202,pos={15,350},size={50,15},limits={0,root:myGlobals:gNPixelsX-1,1},title=" ",value= root:myGlobals:Protocols:gPlexX1
	SetVariable setvar00203,pos={85,399},size={50,15},limits={0,root:myGlobals:gNPixelsY-1,1},title=" ",value= root:myGlobals:Protocols:gPlexY1
	SetVariable setvar00204,pos={156,348},size={50,15},limits={0,root:myGlobals:gNPixelsX-1,1},title=" ",value= root:myGlobals:Protocols:gPlexX2
EndMacro


// done
//
Function DoneDIVButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K DIV_Panel
			break
	endswitch

	return 0
End

// load in a DIV file, print out the stats, display in SANS_Data
//
Function ReloadDIVButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ReadWork_DIV()"
			WaveStats root:Packages:NIST:DIV:data
			Print "*"			
//			Execute "ChangeDisplay(\"DIV\")"	
			break
	endswitch

	return 0
End

//
Function DIVHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Detector Sensitivity File]"
			if(V_flag !=0)
				DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
			endif
			break
	endswitch

	return 0
End

// load in two DIV files, divide them, and display the results
// first is divided by the second, results are in SUB
//
Function CompareDIVButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"First DIV / Second DIV = Result in SUB folder"
			
			Execute "ReadWork_DIV()"
			CopyWorkContents("DIV","STO")
			CopyWorkContents("DIV","SUB")

			Execute "ReadWork_DIV()"
			CopyWorkContents("DIV","DRK")

			WAVE sub_d = getDetectorDataW("SUB")
			WAVE sto_d = getDetectorDataW("STO")
			WAVE drk_d = getDetectorDataW("DRK")
			
			sub_d = sto_d/drk_d

//			WaveStats root:Packages:NIST:DIV:data
//			Print "*"	
					
			Execute "ChangeDisplay(\"SUB\")"	
			break
	endswitch

	return 0
End


Function CompareDIV()

	STRUCT WMButtonAction ba

	ba.eventCode=2
	CompareDIVButtonProc(ba) 
	return(0)
End

//loop through each file and check the x and y center
// within some tolerance (5 pixels) should be fine
//
// this is really just to flag the case where (0,0) is the "center" which causes all sorts
// of solid angle problems when generating a DIV file.
//
// TODO_10m: extra-wide tolerance for NGB = 10m SANS. Once "normal" beam centers are settled, then the tolerance can be adjusted here
Function CheckDIVBeamCenter(str,xc,yc)
	String str
	Variable xc,yc
	
	Variable err,ii,num,tmpX,tmpY,badCtr,tol=10
	String fileStr,pathStr,acct
	
	PathInfo catPathName
	pathStr=S_path
	
	num = ItemsInList(str,",")
	ii=0
	badCtr = 0
	
	// get the account, to identify the instrument
	fileStr = pathStr + StringFromList(ii, str,",")
//	acct = getInstrName(fileStr)
//	String instr=acct[1,3]	//filestr is "[NGnSANSn] " or "[NGnSANSnn]" (11 characters total)	
//	if(cmpstr(instr,"NGA")==0 || cmpstr(instr,"NGB")==0 )
//		tol=20		//if the 10m SANS, give an extra-wide tolerance, and show an alert
//		DoAlert 0,"NGB SANS instrument. Be sure that the correct beam centers are entered for all of the plex files."
//	endif
	
	do
		fileStr = pathStr + StringFromList(ii, str,",")
		tmpX = getDet_beam_center_x(fileStr)
		tmpY = getDet_beam_center_y(fileStr)
		if(abs(tmpX - xc) > tol)
			badCtr = 1
		endif
		if(abs(tmpY - yc) > tol)
			badCtr = 1
		endif		
		ii+=1
	while(ii<num && !badCtr)
	
	return(badCtr)
//	return(0)
end


//////////////  DIV file Utils



// currently, there are no dummy fill values or attributes for the fake DIV file
//
Proc Setup_SANS_DIV_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_SANS_DIV_Structure()
	
End

Proc Save_SANS_DIV_Nexus(fileName)
	String fileName="Test_SANS_DIV_file"

	// save as HDF5 (no attributes saved yet)
	Save_SANS_file("root:SANS_DIV_file", fileName+".h5")
	
End

//
//
// simple generation of a fake div file. for sans, nothing other than the creation date was written to the 
// file header. nothing more is needed (possibly)
//
//
Proc H_Setup_SANS_DIV_Structure()
	
	NewDataFolder/O/S root:SANS_DIV_file		

	NewDataFolder/O/S root:SANS_DIV_file:entry	
		Make/O/T/N=1	title	= "This is a DIV file for the 10m SANS: SANS_DIV"
//		Make/O/T/N=1	start_date	= V_CurrentTime_to_ISO8601String(DateTime)
		Make/O/T/N=1	start_date	= "2022-01-16T06:15:30-5:00"

		NewDataFolder/O/S root:SANS_DIV_file:entry:instrument		
			Make/O/T/N=1	name	= "SANS_NGB"
		NewDataFolder/O/S root:SANS_DIV_file:entry:instrument:detector
			Make/O/D/N=(112,128)	data	= 1 
			Make/O/D/N=(112,128)	linear_data_error	= 0.01

		
		// fake, empty folders so that the generic loaders can be used
		NewDataFolder/O root:SANS_DIV_file:entry:DAS_logs
		NewDataFolder/O root:SANS_DIV_file:entry:control
		NewDataFolder/O root:SANS_DIV_file:entry:reduction
		NewDataFolder/O root:SANS_DIV_file:entry:sample
		NewDataFolder/O root:SANS_DIV_file:entry:user

			
	SetDataFolder root:

End


