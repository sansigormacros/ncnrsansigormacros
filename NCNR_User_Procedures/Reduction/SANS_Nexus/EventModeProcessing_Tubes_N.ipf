#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 7.00




/////////////
// SANS-Tubes Event File Format
// (Phil Chabot)
//////////////
//
// The event file shall be of binary format, with data encoded in little endian format.
// The file shall have a header section and a data section
//

////////////////////


//
// Event mode prcessing for SANS-Tubes
//


//
// TODO:
//
// -- can any of the loops be speeded up by using integers where possible (indexes, counters, etc.)
//     rather than DP variables? --see the discussion list for suggestions?
//
//
// -- Can any of this be multithreaded?
//  -- the histogram operation, the Indexing for the histogram, all are candidates
//  -- can the decoding be multithreaded as a wave assignment speedup?
//
//
// -- search for TODO for unresolved issues not on this list
//
// -- add comments to the code as needed
//
// -- write the help file, and link the help buttons to the help docs
//
// -- examples?
//
//
// X- the slice display "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
//     interprets the data as being RGB - and so does nothing.
//     need to find a way around this. This was fixed by displaying the data using the G=1 flag on AppendImage
//     to prevent the "atuo-detection" of data as RGB
//
//
///////////////   SWITCHES (not used for SANS)     /////////////////
//
// for the "File Too Big" limit:
//	Variable/G root:Packages:NIST:Event:gEventFileTooLarge = 150		// 150 MB considered too large
//
// for the tolerance of "step" detection
//	Variable/G root:Packages:NIST:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
//
//

//  
// x- these dimensions are hard-wired
//
// NTUBES is the total number of tubes = 112
//
Constant NTUBES=112
Constant XBINS=112
Constant YBINS=128

Static Constant MODE_STREAM = 0
Static Constant MODE_OSCILL = 1
Static Constant MODE_TISANE = 2
Static Constant MODE_TOF = 3

// FEB 2021 - 
Constant kBadStep_s = 0.016		// "bad" step threshold (in seconds) for deleting an event



//
Structure eventWord
	uchar xPos
	uchar yPos
	uint64 eventTime
endStructure
//
//
Structure eventWord2
	uchar xPos1
	uchar yPos1
	uint64 eventTime1
	uchar xPos2
	uchar yPos2
	uint64 eventTime2
endStructure
//
//
Structure eventWord5
	uchar xPos1
	uchar yPos1
	uint64 eventTime1
	uchar xPos2
	uchar yPos2
	uint64 eventTime2
	uchar xPos3
	uchar yPos3
	uint64 eventTime3
	uchar xPos4
	uchar yPos4
	uint64 eventTime4
	uchar xPos5
	uchar yPos5
	uint64 eventTime5
endStructure
//

Structure eventWord8
	uchar xPos1
	uchar yPos1
	uint64 eventTime1
	uchar xPos2
	uchar yPos2
	uint64 eventTime2
	uchar xPos3
	uchar yPos3
	uint64 eventTime3
	uchar xPos4
	uchar yPos4
	uint64 eventTime4
	uchar xPos5
	uchar yPos5
	uint64 eventTime5
	uchar xPos6
	uchar yPos6
	uint64 eventTime6
	uchar xPos7
	uchar yPos7
	uint64 eventTime7
	uchar xPos8
	uchar yPos8
	uint64 eventTime8
endStructure

Structure eventWord10
	uchar xPos1
	uchar yPos1
	uint64 eventTime1
	uchar xPos2
	uchar yPos2
	uint64 eventTime2
	uchar xPos3
	uchar yPos3
	uint64 eventTime3
	uchar xPos4
	uchar yPos4
	uint64 eventTime4
	uchar xPos5
	uchar yPos5
	uint64 eventTime5
	uchar xPos6
	uchar yPos6
	uint64 eventTime6
	uchar xPos7
	uchar yPos7
	uint64 eventTime7
	uchar xPos8
	uchar yPos8
	uint64 eventTime8
	uchar xPos9
	uchar yPos9
	uint64 eventTime9
	uchar xPos10
	uchar yPos10
	uint64 eventTime10
endStructure



//////////////////////////////////////////////////
/////
//
// Header for event file on 10m SANS (5/2022)
//
//////////
// NAS = Neutron Acquisition Server (NISTO)
//
//File byte offset		Size (bytes)		Value				Description
//
//		0 						3 			'NAS' 						Magic number
//		3 						2 			Revision 					Revision number encoded as 0xMinorMajor (0xFF00)
//		5 						2 			Data section offset 		Offset to event data in bytes from file beginning
//		7 						10 		Origin Timestamp 			UTC base timestamp (IEEE1588) for relative time systems
//		17 					2 			HV 							High Voltage Reading in volt
//		19 					4 			Clock Frequency 			Timestamping clock frequency in Hz
//
//
Function Read_10b_EventHeader()

	String gNASStr=""
	gNASStr = PadString(gNASStr,3,0x20)		//pad to 3 bytes
	
	Variable gRevision,gOffset,gTime1,gTime2,gTime3,gTime4,gTime5,gVolt,gResol,gTime6
	Variable refnum,ii
	String filePathStr=""
	
	
	Open/R refnum as filepathstr
	

	FBinRead refnum, gNASStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
//	FBinRead/F=2/U/B=3 refnum, gTime6
//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol

	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum
	

	Print "string = ",gNASStr
	Print "revision = ",gRevision
	Print "offset = ",gOffset
	Print "time part 1 = ",gTime1
	Print "time part 2 = ",gTime2
	Print "time part 3 = ",gTime3
	Print "time part 4 = ",gTime4
	Print "time part 5 = ",gTime5
//	Print "time part 6 = ",gTime6
//	Print "det group = ",gDetStr
	Print "voltage (V) = ",gVolt
	Print "clock freq (Hz) = ",gResol
	
	print "1/freq (s) = ",1/gResol


//// read all as a byte wave
	Make/O/B/U/N=23 byteWave		// header is total of 23 bytes

	
	Open/R refnum as filepathstr
	

	FBinRead refnum, byteWave


	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum
	
	for(ii=0;ii<numpnts(byteWave);ii+=1)
		printf "%X  ",byteWave[ii]
	endfor
	printf "\r"
	
	return(0)
End


//
// SLOW - this works, but it is approx 15x slower than reading in as a 
// struct (reading 10 events at a time)
//
Function Read_10b_EventFile()

	String gNASStr=""
	gNASStr = PadString(gNASStr,3,0x20)		//pad to 3 bytes
	
	Variable gRevision,gOffset,gTime1,gTime2,gTime3,gTime4,gTime5,gVolt,gResol,gTime6
	Variable refnum
	String filePathStr=""
	int ii
	
	Open/R refnum as filepathstr
	
tic()

	FBinRead refnum, gNASStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
//	FBinRead/F=2/U/B=3 refnum, gTime6
//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol

//	FStatus refnum
//	FSetPos refnum, V_logEOF
//	
//	Close refnum
//	
//	filePathStr = S_fileName
//	
	

	Print "string = ",gNASStr
	Print "revision = ",gRevision
	Print "offset = ",gOffset
	Print "time part 1 = ",gTime1
	Print "time part 2 = ",gTime2
	Print "time part 3 = ",gTime3
	Print "time part 4 = ",gTime4
	Print "time part 5 = ",gTime5
	Print "voltage (V) = ",gVolt
	Print "clock freq (Hz) = ",gResol
	
	print "1/freq (s) = ",1/gResol



// how many events?
	int numEvents
	uint64	timeVal
	int		xPos,yPos
	
	// 10 bytes per event 1b,1b,8b
	FStatus refnum
	numEvents = (V_logEOF - 23)/10
	Print "numEvents = ",numEvents


	Make/O/U/B/N=(numEvents) xW,yW
	Make/O/U/L/N=(numEvents) timeW

//	Open/R refnum as filepathstr
//	FSetPos refnum, 23		// at start of data block

	for(ii=0;ii<numevents;ii+=1)
	
		FBinRead/U/F=1 refnum, xPos
		FBinRead/U/F=1 refnum, yPos
		FBinRead/U/F=6 refnum, timeVal
		
		xw[ii] = xPos
		yw[ii] = yPos
		timeW[ii] = timeVal

	endfor

	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum

toc()

// get the actual event times	
	Duplicate/O timeW rescaledTime
	Redimension/D rescaledTime
	rescaledTime = timeW - timeW[0]
	rescaledTime *= 1e-9

	
	return(0)
End

//
// this appears to work correctly, using the struct defined in the same order
// as the byte order (not reversed as necessary for XOPs)
//
// will need to test out speed considerations
//
// -- would increasing the number of words in struct definition speed things up?
// -- -- then I need to count carefully to not run past EOF
//
// based on testing, 10 words in a struct seems to work well
// -- use this for now, until someone needs more speed
//
//
//Function Read_10b_EventFile_asStruct(num)
Function Read_10b_EventFile_asStruct()
	
	
	Variable num=10
	

	String gNASStr="",g10byte=""
	gNASStr = PadString(gNASStr,3,0x20)		//pad to 3 bytes
	g10byte = PadString(g10byte,10,0x20)		//pad to 10 bytes
	
	Variable gRevision,gOffset,gTime1,gTime2,gTime3,gTime4,gTime5,gVolt,gResol,gTime6
	Variable refnum
	String filePathStr=""
	int ii
	
	Open/R refnum as filepathstr
	
tic()

	FBinRead refnum, gNASStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
//	FBinRead/F=2/U/B=3 refnum, gTime6
//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol

//	FStatus refnum
//	FSetPos refnum, V_logEOF
//	
//	Close refnum
//	
//	filePathStr = S_fileName
//	
	

	Print "string = ",gNASStr
	Print "revision = ",gRevision
	Print "offset = ",gOffset
	Print "time part 1 = ",gTime1
	Print "time part 2 = ",gTime2
	Print "time part 3 = ",gTime3
	Print "time part 4 = ",gTime4
	Print "time part 5 = ",gTime5
	Print "voltage (V) = ",gVolt
	Print "clock freq (Hz) = ",gResol
	
	print "1/freq (s) = ",1/gResol


// how many events?
	int numEvents
	uint64	timeVal
	int		xPos,yPos
	
	// 10 bytes per event 1b,1b,8b
	FStatus refnum
	numEvents = (V_logEOF - 23)/10
	Print "numEvents = ",numEvents
	

	Make/O/U/B/N=(numEvents) xW,yW
	Make/O/U/L/N=(numEvents) timeW

//	Open/R refnum as filepathstr
//	FSetPos refnum, 23		// at start of data block

	int step,jj

	STRUCT eventWord s
	STRUCT eventWord2 s2
	STRUCT eventWord5 s5
	STRUCT eventWord8 s8
	STRUCT eventWord10 s10


// throw away a few events (10 or less)
// to make sure I've got a multiple of 10 (or num)
	do
		numEvents -= 1
	while(mod(numEvents,num) != 0)

	step = num

	if(step == 1)
		Print "reading 10 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s
			
	
			xw[ii] = s.xPos		//1st byte xPos
			yw[ii] = s.yPos		//2nd byte yPos
			timeW[ii] = s.eventTime	// last 8 bytes timeVal
	
		endfor
	endif

	if(step == 2)
		Print "reading 20 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s2
			
			xw[ii] = s2.xPos1		//1st byte xPos
			yw[ii] = s2.yPos1		//2nd byte yPos
			timeW[ii] = s2.eventTime1	// last 8 bytes timeVal

			xw[ii+1] = s2.xPos2		//1st byte xPos
			yw[ii+1] = s2.yPos2		//2nd byte yPos
			timeW[ii+1] = s2.eventTime2	// last 8 bytes timeVal
	
		endfor
	endif


	if(step == 5)
		Print "reading 50 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s5
			
			xw[ii] = s5.xPos1		//1st byte xPos
			yw[ii] = s5.yPos1		//2nd byte yPos
			timeW[ii] = s5.eventTime1	// last 8 bytes timeVal
			
			xw[ii+1] = s5.xPos2		//1st byte xPos
			yw[ii+1] = s5.yPos2		//2nd byte yPos
			timeW[ii+1] = s5.eventTime2	// last 8 bytes timeVal
			
			xw[ii+2] = s5.xPos3		//1st byte xPos
			yw[ii+2] = s5.yPos3		//2nd byte yPos
			timeW[ii+2] = s5.eventTime3	// last 8 bytes timeVal
			
			xw[ii+3] = s5.xPos4		//1st byte xPos
			yw[ii+3] = s5.yPos4		//2nd byte yPos
			timeW[ii+3] = s5.eventTime4	// last 8 bytes timeVal
			
			xw[ii+4] = s5.xPos5		//1st byte xPos
			yw[ii+4] = s5.yPos5		//2nd byte yPos
			timeW[ii+4] = s5.eventTime5	// last 8 bytes timeVal
	
		endfor
	endif

	if(step == 8)
		Print "reading 80 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s8
			
			jj = ii
			xw[jj] = s8.xPos1		//1st byte xPos
			yw[jj] = s8.yPos1		//2nd byte yPos
			timeW[jj] = s8.eventTime1	// last 8 bytes timeVal
			
			jj += 1
			xw[jj] = s8.xPos2		
			yw[jj] = s8.yPos2		
			timeW[jj] = s8.eventTime2	

			jj += 1
			xw[jj] = s8.xPos3	
			yw[jj] = s8.yPos3		
			timeW[jj] = s8.eventTime3	

			jj += 1
			xw[jj] = s8.xPos4		
			yw[jj] = s8.yPos4		
			timeW[jj] = s8.eventTime4	

			jj += 1
			xw[jj] = s8.xPos5		
			yw[jj] = s8.yPos5		
			timeW[jj] = s8.eventTime5	

			jj += 1
			xw[jj] = s8.xPos6		
			yw[jj] = s8.yPos6		
			timeW[jj] = s8.eventTime6	

			jj += 1
			xw[jj] = s8.xPos7		
			yw[jj] = s8.yPos7		
			timeW[jj] = s8.eventTime7	

			jj += 1
			xw[jj] = s8.xPos8		
			yw[jj] = s8.yPos8		
			timeW[jj] = s8.eventTime8	

	
		endfor
	endif


	if(step == 10)
		Print "reading 100 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s10
			
			jj = ii
			xw[jj] = s10.xPos1		//1st byte xPos
			yw[jj] = s10.yPos1		//2nd byte yPos
			timeW[jj] = s10.eventTime1	// last 8 bytes timeVal
			
			jj += 1
			xw[jj] = s10.xPos2		
			yw[jj] = s10.yPos2		
			timeW[jj] = s10.eventTime2	

			jj += 1
			xw[jj] = s10.xPos3	
			yw[jj] = s10.yPos3		
			timeW[jj] = s10.eventTime3	

			jj += 1
			xw[jj] = s10.xPos4		
			yw[jj] = s10.yPos4		
			timeW[jj] = s10.eventTime4	

			jj += 1
			xw[jj] = s10.xPos5		
			yw[jj] = s10.yPos5		
			timeW[jj] = s10.eventTime5	

			jj += 1
			xw[jj] = s10.xPos6		
			yw[jj] = s10.yPos6		
			timeW[jj] = s10.eventTime6	

			jj += 1
			xw[jj] = s10.xPos7		
			yw[jj] = s10.yPos7		
			timeW[jj] = s10.eventTime7	

			jj += 1
			xw[jj] = s10.xPos8		
			yw[jj] = s10.yPos8		
			timeW[jj] = s10.eventTime8	

			jj += 1
			xw[jj] = s10.xPos9		
			yw[jj] = s10.yPos9		
			timeW[jj] = s10.eventTime9	

			jj += 1
			xw[jj] = s10.xPos10		
			yw[jj] = s10.yPos10		
			timeW[jj] = s10.eventTime10	

	
		endfor
	endif




	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum

toc()

// get the actual event times	
	Duplicate/O timeW rescaledTime
	Redimension/D rescaledTime
	rescaledTime = timeW - timeW[0]
	rescaledTime *= 1e-9

	
	return(0)
End




// Initialization of the SANS event mode panel
Proc Show_Event_Panel()
	DoWindow/F SANS_EventModePanel
	if(V_flag ==0)
		Init_Event()
		SANS_EventModePanel()
	EndIf
End

// 
//
Function Init_Event()

	NewDataFolder/O/S root:Packages:NIST:Event

	String/G 	root:Packages:NIST:Event:gEvent_logfile
	String/G 	root:Packages:NIST:Event:gEventDisplayString="Details of the file load"


// globals that are the header of the SANS (Tube) event file
	String/G root:Packages:NIST:Event:gNASStr=""
	Variable/G root:Packages:NIST:Event:gRevision = 0
	Variable/G root:Packages:NIST:Event:gOffset=0		// = 25 bytes if no disabled tubes
	Variable/G root:Packages:NIST:Event:gTime1=0
	Variable/G root:Packages:NIST:Event:gTime2=0
	Variable/G root:Packages:NIST:Event:gTime3=0
	Variable/G root:Packages:NIST:Event:gTime4=0	// these 4 time pieces are supposed to be 8 bytes total
	Variable/G root:Packages:NIST:Event:gTime5=0	// these 5 time pieces are supposed to be 10 bytes total
	Variable/G root:Packages:NIST:Event:gTime6=0	// these 5 time pieces are supposed to be 10 bytes total
	String/G root:Packages:NIST:Event:gDetStr=""
	Variable/G root:Packages:NIST:Event:gVolt=0
	Variable/G root:Packages:NIST:Event:gResol=0		//time resolution in nanoseconds
// TODO -- need a wave? for the list of disabled tubes
// don't know how many there might be, or why I would need to know

	Variable/G root:Packages:NIST:Event:gEvent_t_longest = 0

	Variable/G root:Packages:NIST:Event:gEvent_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:Event:gEvent_nslices = 10  //Number of time slices
	
	Variable/G root:Packages:NIST:Event:gEvent_logint = 1

	Variable/G root:Packages:NIST:Event:gEvent_Mode = 0				// ==0 for "stream", ==1 for Oscillatory
	Variable/G root:Packages:NIST:Event:gRemoveBadEvents = 1		// ==1 to remove "bad" events, ==0 to read "as-is"
	Variable/G root:Packages:NIST:Event:gSortStreamEvents = 0		// ==1 to sort the event stream, a last resort for a stream of data
	
	Variable/G root:Packages:NIST:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	
		
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData


// for decimation (not used for Tube SANS - may be added back in the future)
	Variable/G root:Packages:NIST:Event:gEventFileTooLarge = 1501		// 1500 MB considered too large
	Variable/G root:Packages:NIST:Event:gDecimation = 100
	Variable/G root:Packages:NIST:Event:gEvent_t_longest_decimated = 0

// for large file splitting (unused)
	String/G root:Packages:NIST:Event:gSplitFileList = ""		// a list of the file names as split
	
// for editing (unused)
	Variable/G root:Packages:NIST:Event:gStepTolerance = 5		// 5 = # of standard deviations from mean. See PutCursorsAtStep()
	
	SetDataFolder root:
End


//
// the main panel for SANS Event mode
// -- a duplicate of the SANS panel, with the functions I'm not using disabled.
//  could be added back in the future
//
Proc SANS_EventModePanel()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif
	
	PauseUpdate; Silent 1		// building window...
	if(root:Packages:NIST:gLaptopMode == 1)
		NewPanel /W=(82*sc,10*sc,884*sc,590*sc)/N=SANS_EventModePanel/K=2
	else
		NewPanel /W=(82,44,884,664)/N=SANS_EventModePanel/K=2
	endif
	
	DoWindow/C SANS_EventModePanel
	ModifyPanel fixedSize=1,noEdit =1

//	SetDrawLayer UserBack
//	DrawText 479,345,"Stream Data"
//	DrawLine 563,338,775,338
//	DrawText 479,419,"Oscillatory or Stream Data"
//	DrawLine 647,411,775,411

//	ShowTools/A
	Button button0,pos={sc*14,70*sc},size={sc*150,20*sc},proc=LoadEventLog_Button,title="Load Event Log File"
	Button button0,fSize=12*sc
	Button button23,pos={sc*14,100*sc},size={sc*150,20*sc},proc=LoadEventLog_Button,title="Load From RAW"
	Button button23,fSize=12*sc
	TitleBox tb1,pos={sc*475,450*sc},size={sc*266,86*sc},fsize=12*sc
	TitleBox tb1,variable= root:Packages:NIST:Event:gEventDisplayString

	CheckBox chkbox2,pos={sc*376,150*sc},size={sc*81,15*sc},proc=LogIntEvent_Proc,title="Log Intensity"
	CheckBox chkbox2,fsize=12*sc,variable= root:Packages:NIST:Event:gEvent_logint
	CheckBox chkbox3,pos={sc*14,150*sc},size={sc*119,15*sc},title="Remove Bad Events?",fsize=12*sc
	CheckBox chkbox3,variable= root:Packages:NIST:Event:gRemoveBadEvents
	
	Button doneButton,pos={sc*738,36*sc},size={sc*50,20*sc},proc=EventDone_Proc,title="Done"
	Button doneButton,fSize=12*sc
	Button button6,pos={sc*748,9*sc},size={sc*40,20*sc},proc=EventModeHelpButtonProc,title="?",fSize=12*sc

//	Button button5,pos={sc*633,228*sc},size={sc*140,20*sc},proc=ExportSlicesButtonProc,title="Export Slices as VAX",disable=2

	Button button8,pos={sc*570,35*sc},size={sc*120,20*sc},proc=CustomBinButtonProc,title="Custom Bins",fSize=12*sc
	Button button2,pos={sc*570,65*sc},size={sc*140,20*sc},proc=ShowEventDataButtonProc,title="Show Event Data",fSize=12*sc
	Button button3,pos={sc*570,95*sc},size={sc*140,20*sc},proc=ShowBinDetailsButtonProc,title="Show Bin Details",fSize=12*sc

			
	Button button7,pos={sc*211,33*sc},size={sc*120,20*sc},proc=AdjustEventDataButtonProc,title="Adjust Events",fSize=12*sc
	Button button4,pos={sc*211,63*sc},size={sc*120,20*sc},proc=UndoTimeSortButtonProc,title="Undo Time Sort",fSize=12*sc
	Button button18,pos={sc*211,90*sc},size={sc*120,20*sc},proc=EC_ImportWavesButtonProc,title="Import Edited",fSize=12*sc
	
	SetVariable setvar0,pos={sc*208,149*sc},size={sc*160,16*sc},proc=sliceSelectEvent_Proc,title="Display Time Slice"
	SetVariable setvar0,fsize=12*sc
	SetVariable setvar0,limits={0,1000,1},value= root:Packages:NIST:Event:gEvent_tsdisp	
	SetVariable setvar1,pos={sc*389,29*sc},size={sc*160,16*sc},title="Number of slices",fsize=12*sc
	SetVariable setvar1,limits={1,1000,1},value= root:Packages:NIST:Event:gEvent_nslices
	SetVariable setvar2,pos={sc*389,54*sc},size={sc*160,16*sc},title="Max Time (s)",fsize=12*sc
	SetVariable setvar2,value= root:Packages:NIST:Event:gEvent_t_longest
	
	PopupMenu popup0,pos={sc*389,77*sc},size={sc*119,20*sc},proc=BinTypePopMenuProc,title="Bin Spacing"
	PopupMenu popup0,mode=1,popvalue="Equal",value= #"\"Equal;Fibonacci;Custom;\"",fSize=12*sc
	Button button1,pos={sc*389,103*sc},size={sc*120,20*sc},proc=ProcessEventLog_Button,title="Bin Event Data",fSize=12*sc

	
	Button button24,pos={sc*488,270*sc},size={sc*180,20*sc},proc=DuplRAWForExport_Button,title="Duplicate RAW for Export",fSize=12*sc
	Button button25,pos={sc*488,300*sc},size={sc*180,20*sc},proc=CopySlicesForExport_Button,title="Copy Slices for Export",fSize=12*sc
	Button button26,pos={sc*488,330*sc},size={sc*180,20*sc},proc=SaveExportedNexus_Button,title="Save Exported to Nexus",fSize=12*sc

//	Button button10,pos={sc*488,305*sc},size={sc*100,20*sc},proc=SplitFileButtonProc,title="Split Big File",disable=2
//	Button button14,pos={sc*488,350*sc},size={sc*120,20*sc},proc=Stream_LoadDecim,title="Load Split List",disable=2
//	Button button19,pos={sc*649,350*sc},size={sc*120,20*sc},proc=Stream_LoadAdjustedList,title="Load Edited List",disable=2
//	Button button20,pos={sc*680,376*sc},size={sc*90,20*sc},proc=ShowList_ToLoad,title="Show List",disable=2
//	SetVariable setvar3,pos={sc*487,378*sc},size={sc*150,16*sc},title="Decimation factor",disable=2
//	SetVariable setvar3,fsize=12
//	SetVariable setvar3,limits={1,inf,1},value= root:Packages:NIST:Event:gDecimation
//
//	Button button15_0,pos={sc*488,425*sc},size={sc*110,20*sc},proc=AccumulateSlicesButton,title="Add First Slice",disable=2
//	Button button16_1,pos={sc*488,450*sc},size={sc*110,20*sc},proc=AccumulateSlicesButton,title="Add Next Slice",disable=2
//	Button button17_2,pos={sc*620,425*sc},size={sc*110,20*sc},proc=AccumulateSlicesButton,title="Display Total",disable=2

	CheckBox chkbox1_0,pos={sc*25,30*sc},size={sc*69,14*sc},title="Oscillatory",fsize=12*sc
	CheckBox chkbox1_0,mode=1,proc=EventModeRadioProc,value=0
	CheckBox chkbox1_1,pos={sc*25,50*sc},size={sc*53,14*sc},title="Stream",fsize=12*sc
	CheckBox chkbox1_1,proc=EventModeRadioProc,value=1,mode=1
//	CheckBox chkbox1_2,pos={sc*104,59*sc},size={sc*53,14*sc},title="TISANE",fsize=12
//	CheckBox chkbox1_2,proc=EventModeRadioProc,value=0,mode=1
	CheckBox chkbox1_3,pos={sc*104,30*sc},size={sc*37,14*sc},title="TOF",fsize=12*sc
	CheckBox chkbox1_3,proc=EventModeRadioProc,value=0,mode=1
	
//	CheckBox chkbox1_4,pos={sc*30,125*sc},size={sc*37,14*sc},title="F",fsize=12*sc
//	CheckBox chkbox1_4,proc=EventCarrRadioProc,value=1,mode=1
//	CheckBox chkbox1_5,pos={sc*90,125*sc},size={sc*37,14*sc},title="M",fsize=12*sc
//	CheckBox chkbox1_5,proc=EventCarrRadioProc,value=0,mode=1
	
	GroupBox group0_0,pos={sc*5,5*sc},size={sc*174,140*sc},title="(1) Loading Mode",fSize=12*sc,fStyle=1
	GroupBox group0_3,pos={sc*191,5*sc},size={sc*165,130*sc},title="(2) Edit Events",fSize=12*sc,fStyle=1
	GroupBox group0_1,pos={sc*372,5*sc},size={sc*350,130*sc},title="(3) Bin Events",fSize=12*sc,fStyle=1
	GroupBox group0_2,pos={sc*477,169*sc},size={sc*310,250*sc},title="(4) View / Export",fSize=12*sc,fStyle=1

//	GroupBox group0_4,pos={sc*474,278*sc},size={sc*312,200*sc},title="Split / Accumulate Files",fSize=12
//	GroupBox group0_4,fStyle=1
	
	Display/W=(10*sc,170*sc,460*sc,610*sc)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:Event:dispsliceData		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage dispsliceData ctab= {*,*,ColdWarm,0}
	ModifyImage dispsliceData ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slicegraph
	SetActiveSubwindow ##
EndMacro


//
//
Function DuplRAWForExport_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DuplicateRAWForExport()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// Split the binned to panels right before copying the slices
// in case the user hasn't done this
//
Function CopySlicesForExport_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//			//
			CopySlicesForExport()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
//
Function SaveExportedNexus_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			//
			Execute "SaveExportedEvents()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// mode selector
//Static Constant MODE_STREAM = 0
//Static Constant MODE_OSCILL = 1
//Static Constant MODE_TISANE = 2
//Static Constant MODE_TOF = 3
//
Function EventModeRadioProc(name,value)
	String name
	Variable value
	
	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
	
	strswitch (name)
		case "chkbox1_0":
			gEventModeRadioVal= MODE_OSCILL
			break
		case "chkbox1_1":
			gEventModeRadioVal= MODE_STREAM
			break
//		case "chkbox1_2":
//			gEventModeRadioVal= MODE_TISANE
//			break
		case "chkbox1_3":
			gEventModeRadioVal= MODE_TOF
			break
	endswitch
	CheckBox chkbox1_0,value= gEventModeRadioVal==MODE_OSCILL
	CheckBox chkbox1_1,value= gEventModeRadioVal==MODE_STREAM
//	CheckBox chkbox1_2,value= gEventModeRadioVal==MODE_TISANE
	CheckBox chkbox1_3,value= gEventModeRadioVal==MODE_TOF

	return(0)
End



Function AdjustEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowEventCorrectionPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CustomBinButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "Show_CustomBinPanel()"
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ShowEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
//			tic()
//			printf "Show rescaled time graph = "
			Execute "ShowRescaledTimeGraph()"
//			toc()
			//
//			tic()
//			printf "calculate and show differential = "
			DifferentiatedTime()
//			toc()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BinTypePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			if(cmpstr(popStr,"Custom")==0)
				Execute "Show_CustomBinPanel()"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ShowBinDetailsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowBinTable()"
			Execute "BinEventBarGraph()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function UndoTimeSortButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "UndoTheSorting()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EventModeHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z "SANS Data Reduction Documentation[Processing SANS Event Data]"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EventDone_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K SANS_EventModePanel
			break
	endswitch
	return(0)
End



Function ProcessEventLog_Button(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR mode=root:Packages:NIST:Event:gEvent_Mode
	
	if(mode == MODE_STREAM)
		Stream_ProcessEventLog("")
	endif
	
	if(mode == MODE_OSCILL)
		Osc_ProcessEventLog("")
	endif
	
	// If TOF mode, process as Oscillatory -- that is, take the times as is
	if(mode == MODE_TOF)
		Osc_ProcessEventLog("")
	endif
	
	// toggle the checkbox for log display to force the display to be correct
	NVAR gLog = root:Packages:NIST:Event:gEvent_logint
	LogIntEvent_Proc("",gLog)
	
	return(0)
end

//
// for oscillatory mode
//
//
Function Osc_ProcessEventLog(ctrlName)
	String ctrlName

	Make/O/D/N=(XBINS,YBINS) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Make/O/D/N=(XBINS,YBINS) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount
	Make/O/D/N=(nslices) timeWidth
	Wave timeWidth = timeWidth
	Wave binEndTime = binEndTime
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0


	String binTypeStr=""
	ControlInfo /W=SANS_EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch


// now before binning, sort the data

	//this is slow - undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	SetDataFolder root:Packages:NIST:Event:

tic()
	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
		
		//SetDataFolder root:Packages:NIST:Event
		IndexForHistogram(xLoc,yLoc,binnedData)			// index the events AFTER sorting
		//SetDataFolder root:
	Endif
	
printf "sort time = "
toc()

	Wave index = root:Packages:NIST:Event:SavedIndex		//this is the histogram index

tic()
	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

	// typically zero will never be a valid time value in oscillatory mode. in "stream" mode, the first is normalized to == 0
	// but not here - times are what they are.
		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
//		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor
printf "histogram time = "
toc()

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End

// for a "continuous exposure"
//
// if there is a sort of these events, I need to re-index the events for the histogram
// - see the oscillatory mode  - and sort the events here, then immediately re-index for the histogram
// - but with the added complication that I need to always remember to index for the histogram, every time
// - since I don't know if I've sorted or un-sorted. Osc mode always forces a re-sort and a re-index
//
//
Function Stream_ProcessEventLog(ctrlName)
	String ctrlName

//	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth

	
	Make/O/D/N=(XBINS,YBINS) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR yesSortStream = root:Packages:NIST:Event:gSortStreamEvents		//do I sort the events?
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Make/O/D/N=(XBINS,YBINS) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount//,binStartTime
	Make/O/D/N=(nslices) timeWidth
	Wave binEndTime = binEndTime
	Wave timeWidth = timeWidth
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0
	
	String binTypeStr=""
	ControlInfo /W=SANS_EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,timeWidth,nslices,t_longest)
			break
		case "Custom":		// execute if case matches expression
			//bins are set by the user on the panel - assume it's good to go
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	endswitch

//
// for SANS Tube events, the stream data shows time reversal due to the communication
// cycling between the packs of tubes (per Phil), so sort the data to remove this.
// unfortunately, this removes any chance of seeing other time errors.
// fortunately, no time encoding errors have been seen with the tubes.
//
// -- still, sorting is not routinely done (there is no need)
//
	if(yesSortStream == 1)
		SortTimeData()
	endif
	
// index the events before binning
// if there is a sort of these events, I need to re-index the events for the histogram
//	SetDataFolder root:Packages:NIST:Event
	IndexForHistogram(xLoc,yLoc,binnedData)
//	SetDataFolder root:
	Wave index = root:Packages:NIST:Event:SavedIndex		//the index for the histogram
	
	
	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
//		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End


Proc	UndoTheSorting()
	Osc_UndoSort()
End

// for oscillatory mode
//
// -- this takes the previously generated index, and un-sorts the data to restore to the
// "as-collected" state
//
Function Osc_UndoSort()

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	Wave rescaledTime = rescaledTime
	Wave OscSortIndex = OscSortIndex
	Wave yLoc = yLoc
	Wave xLoc = xLoc
	Wave timePt = timePt

	Sort OscSortIndex OscSortIndex,yLoc,xLoc,timePt,rescaledTime

	KillWaves/Z OscSortIndex
	
	SetDataFolder root:
	return(0)
End


// now before binning, sort the data
//
//this is slow - undoing the sorting and starting over, but if you don't,
// you'll never be able to undo the sort
//
Function SortTimeData()

	SetDataFolder root:Packages:NIST:Event:

	KillWaves/Z OscSortIndex
	
	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
	Endif
	
	SetDataFolder root:
	return(0)
End



Function SetLinearBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable del,ii,t2
	binEndTime[0]=0		//so the bar graph plots right...
	del = t_longest/nslices
	
	for(ii=0;ii<nslices;ii+=1)
		t2 = (ii+1)*del
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest*(1-1e-6)		//otherwise floating point errors such that the last time point is off the end of the Binary search

	timeWidth = binEndTime[p+1]-binEndTime[p]

	return(0)	
End


// TODO
// either get this to work, or scrap it entirely. it currently isn't on the popup
// so it can't be accessed
Function SetLogBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii

	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime
	
	binEndTime[0]=0		//so the bar graph plots right...

	// just like the log-scaled q-points
	tMin = rescaledTime[1]/1			//just a guess... can't use tMin=0, and rescaledTime[0] == 0 by definition
	Print rescaledTime[1], tMin
	for(ii=0;ii<nslices;ii+=1)
		binEndTime[ii+1] =alog(log(tMin) + (ii+1)*((log(t_longest)-log(tMin))/nslices))
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	timeWidth = binEndTime[p+1]-binEndTime[p]

	return(0)
End

Function MakeFibonacciWave(w,num)
	Wave w
	Variable num

	//skip the initial zero
	Variable f1,f2,ii
	f1=1
	f2=1
	w[0] = f1
	w[1] = f2
	for(ii=2;ii<num;ii+=1)
		w[ii] = f1+f2
		f1=f2
		f2=w[ii]
	endfor
		
	return(0)
end

Function SetFibonacciBins(binEndTime,timeWidth,nslices,t_longest)
	Wave binEndTime,timeWidth
	Variable nslices,t_longest

	Variable tMin,ii,total,t2,tmp
	Make/O/D/N=(nslices) fibo
	fibo=0
	MakeFibonacciWave(fibo,nslices)
	
//	Make/O/D tmpFib={1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946}

	binEndTime[0]=0		//so the bar graph plots right...
	total = sum(fibo,0,nslices-1)		//total number of "pieces"
	
	tmp=0
	for(ii=0;ii<nslices;ii+=1)
		t2 = sum(fibo,0,ii)/total*t_longest
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	timeWidth = binEndTime[p+1]-binEndTime[p]
	
	return(0)
End



// 
// -- The "file too large" check has currently been set to 1.5 GB
//
//	
Function LoadEventLog_Button(ctrlName) : ButtonControl
	String ctrlName

	NVAR mode=root:Packages:NIST:Event:gEvent_mode
	Variable err=0
	Variable fileref,totBytes
	NVAR fileTooLarge = root:Packages:NIST:Event:gEventFileTooLarge		//limit load to 1500MB

	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	String abortStr
	
	PathInfo catPathName
	if(V_flag==0)
		DoAlert 0,"Please 'Pick Path' to the data from the Main (yellow) Panel."
		return(0)
	endif
	
	// load from raw?
	// if so, which carriage?
	String loadFromRAW="No"
	String detStr
	if(cmpstr(ctrlName,"button23")==0)
		loadFromRAW = "Yes"	
	endif
	
//	Prompt loadFromRAW,"Load from RAW?",popup,"Yes;No;"
//	Prompt detStr,"Carriage",popup,"M;F;"
//	DoPrompt "Load data from...",loadFromRAW,detStr
	
//	if(V_flag)		//user cancel
//		return(0)
//	endif
	
	if(cmpstr(loadFromRAW,"Yes")==0)
		PathInfo catPathName
		filename = S_Path + getDetEventFileName("RAW")
		
		// check here to see if the file can be found. if not report the error and exit
		Open/R/Z=1 fileref as fileName
		if(V_flag == 0)
			Close fileref
		else
			DoAlert 0,"The event file associated with RAW cannot be found.       "+filename
			return(0)
		endif
	else
		Open/R/D/P=catPathName/F=fileFilters fileref
		filename = S_filename
		if(strlen(S_filename) == 0)
			// user cancelled
			DoAlert 0,"No file selected, no file loaded."
			return(1)
		endif
	endif
//  keep this	, but set to 1.5 GB
// since I'm now in 64-bit space
/// Abort if the files are too large
	Open/R fileref as fileName
		FStatus fileref
	Close fileref
//
	totBytes = V_logEOF/1e6		//in MB
	if(totBytes > fileTooLarge)
		sprintf abortStr,"File is %g MB, larger than the limit of %g MB. Split and Decimate.",totBytes,fileTooLarge
		Abort abortStr
	endif
//	
	Print "TotalBytes (MB) = ",totBytes
	

Variable t1 = ticks
	SetDataFolder root:Packages:NIST:Event:

// load in the event file and decode it
	
//	readFakeEventFile(fileName)
	LoadEvents()			// this now loads, decodes, and returns xLoc, yLoc, timePt [=] ticks
	
	SetDataFolder root:Packages:NIST:Event:			//verify we're back to root:



	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes	
	
	NVAR gResol = root:Packages:NIST:Event:gResol		//timeStep in clock frequency (Hz)
	Printf "Time Step = 1/Frequency (ns) = %g\r",(1/gResol)*1e9
	variable timeStep_s = (1/gResol)

	Redimension/D timePt		//otherwise rescaled time will be integer...
	
/////
// now do a little processing of the times based on the type of data
//	

	if(mode == MODE_STREAM)		// continuous "Stream" mode - start from zero

			KillWaves/Z rescaledTime
			Duplicate/O timePt rescaledTime

			rescaledTime = timeStep_s*(timePt-timePt[0])		//convert to seconds and start from zero

			t_longest = waveMax(rescaledTime)		//should be the last point	
	endif

	
	if(mode == MODE_OSCILL)		// oscillatory mode - don't adjust the times, we get periodic t0 to reset t=0
		KillWaves/Z rescaledTime
		Duplicate/O timePt rescaledTime
		rescaledTime *= timeStep_s			//convert to seconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif

// MODE_TISANE


// MODE_TOF
	if(mode == MODE_TOF)		// TOF mode - don't adjust the times, we get periodic t0 to reset t=0
		KillWaves/Z rescaledTime
		Duplicate/O timePt rescaledTime
		rescaledTime *= timeStep_s		//convert to seconds and that's all
		t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way
	
		KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around
	endif


// FEB 2021 -- comb through each panel of data (separately) and look for bad time
// steps. (> 16 ms) -- eliminate these. Do for all 4 panels, then the data is "clean"
// and any "bad" time steps are OK, just buffering
//
	NVAR removeBadEvents = root:Packages:NIST:Event:gRemoveBadEvents

//tic()
//	if(RemoveBadEvents)
//		// this loops through all 4 panels, removing bad time steps
//		EC_CleanAllPanels()
//	endif
//Printf "cleanup panels = "
//toc()

tic()
// safe to sort stream data now, even if bad steps haven't been removed (the data is probably good)
//	if(mode == MODE_STREAM && RemoveBadEvents)
	if(mode == MODE_STREAM)
		SortTimeData()
	Endif
	printf "sort = "
toc()

	SetDataFolder root:

Variable t2 = ticks

tic()
	STRUCT WMButtonAction ba
	ba.eventCode = 2
	ShowEventDataButtonProc(ba)
printf "draw plots = "
toc()


Variable t3 = ticks

	Print "load and process (s) = ",(t2-t1)/60.15
	Print "Overall including graphs (s) = ",(t3-t1)/60.15
	return(0)
End




//
// -- MUCH faster to count the number of lines to remove, then delete (N)
// rather then delete them one-by-one in the do-loop
//
Function CleanupTimes(xLoc,yLoc,timePt)
	Wave xLoc,yLoc,timePt

	// start at the back and remove zeros
	Variable num=numpnts(xLoc),ii,numToRemove

	numToRemove = 0
	ii=num
	do
		ii -= 1
		if(timePt[ii] == 0 && xLoc[ii] == 0 && yLoc[ii] == 0)
			numToRemove += 1
		endif
	while(timePt[ii-1] == 0 && xLoc[ii-1] == 0 && yLoc[ii-1] == 0)
	
	if(numToRemove != 0)
		DeletePoints ii, numToRemove, xLoc,yLoc,timePt
	endif
	
	Print "CleanupTimes - zeroes removed = ",numToRemove
	return(0)
End

Function LogIntEvent_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:Event
	
	Wave slicedData = slicedData
	Wave logSlicedData = logSlicedData
	Wave dispSliceData = dispSliceData
	
	if(checked)
		logslicedData = log(slicedData)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	NVAR selectedslice = root:Packages:NIST:Event:gEvent_tsdisp

	sliceSelectEvent_Proc("", selectedslice, "", "")

	SetDataFolder root:

End


// (DONE)
// this "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
// interprets the data as being RGB - and so does nothing.
// need to find a way around this
//
////  When first plotted, AppendImage/G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
///
// I could modify this procedure to use the log = 0|1 keyword for the log Z display
// rather than creating a duplicate wave of log(data)
//
Function sliceSelectEvent_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:Event:gEvent_nslices
	NVAR selectedslice = root:Packages:NIST:Event:gEvent_tsdisp
	
	if(varNum < 0)
		selectedslice = 0
		DoUpdate
	elseif (varNum > nslices-1)
		selectedslice = nslices-1
		DoUpdate
	else
		ModifyImage/W=SANS_EventModePanel#Event_slicegraph ''#0 plane = varNum 
	endif

End

Function DifferentiatedTime()



	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime

	SetDataFolder root:Packages:NIST:Event:
		
		
		
		
	Differentiate rescaledTime/D=rescaledTime_DIF
//	Display rescaledTime,rescaledTime_DIF
	DoWindow/F Differentiated_Time
	if(V_flag == 0)
		Display/N=Differentiated_Time/K=1 rescaledTime_DIF
		Legend
		Modifygraph gaps=0
		ModifyGraph zero(left)=1
		Label left "\\Z14Delta (dt/event)"
		Label bottom "\\Z14Event number"
	endif
	
	
//	
//	Duplicate/O rescaledTime,rescaledTime_samp
//	Resample/DOWN=1000 rescaledTime_samp		
//	
//	Differentiate rescaledTime_samp/D=rescaledTimeDec_DIF
////	Display rescaledTime,rescaledTime_DIF
//	DoWindow/F Differentiated_Time_Decim
//	if(V_flag == 0)
//		Display/N=Differentiated_Time_Decim/K=1 rescaledTimeDec_DIF
//		Legend
//		Modifygraph gaps=0
//		ModifyGraph zero(left)=1
//		Label left "\\Z14Delta (dt/event)"
//		Label bottom "\\Z14Event number (decimated)"
//	endif
	
	
	SetDataFolder root:
	
	return(0)
End


//
// for the bit shifts, see the decimal-binary conversion
// http://www.binaryconvert.com/convert_unsigned_int.html
//
//  for 64-bit values:
// http://calc.penjee.com
//
//
// This function loads the events, and decodes them.
//
//
/////
//
// Header for event file on 10m SANS (5/2022)
//
//////////
// NAS = Neutron Acquisition Server (NISTO)
//
//File byte offset		Size (bytes)		Value				Description
//
//		0 						3 			'NAS' 						Magic number
//		3 						2 			Revision 					Revision number encoded as 0xMinorMajor (0xFF00)
//		5 						2 			Data section offset 		Offset to event data in bytes from file beginning
//		7 						10 		Origin Timestamp 			UTC base timestamp (IEEE1588) for relative time systems
//		17 					2 			HV 							High Voltage Reading in volt
//		19 					4 			Clock Frequency 			Timestamping clock frequency in Hz
//
//
Function LoadEvents()
	
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:Event:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
	
	SetDataFolder root:Packages:NIST:Event

	Variable refnum
	String buffer
	String fileStr,tmpStr
	Variable verbose
	Variable xval,yval
	Variable numXYevents,totBytes

//  to read a SANS event file:
//
// - get the file name
//	- read the header (all of it, since I need parts of it)
// - read the events as structs (10 bytes each), reading 10 at a time for speed
// - move to EOF and close
//


/// globals to report the header back for use or status
	SVAR gNASStr = root:Packages:NIST:Event:gNASStr
	NVAR gRevision = root:Packages:NIST:Event:gRevision
	NVAR gOffset = root:Packages:NIST:Event:gOffset		// = 22 bytes if no disabled tubes
	NVAR gTime1 = root:Packages:NIST:Event:gTime1
	NVAR gTime2 = root:Packages:NIST:Event:gTime2
	NVAR gTime3 = root:Packages:NIST:Event:gTime3
	NVAR gTime4 = root:Packages:NIST:Event:gTime4	// these 4 time pieces are supposed to be 8 bytes total
	NVAR gTime5 = root:Packages:NIST:Event:gTime5	// these 5 time pieces are supposed to be 10 bytes total
	NVAR gTime6 = root:Packages:NIST:Event:gTime6	// these 6 time pieces are supposed to be 12 bytes total
	SVAR gDetStr = root:Packages:NIST:Event:gDetStr
	NVAR gVolt = root:Packages:NIST:Event:gVolt
	NVAR gResol = root:Packages:NIST:Event:gResol		//time resolution in nanoseconds
/////

	gNASStr = PadString(gNASStr,3,0x20)		//pad to 3 bytes
	gDetStr = PadString(gDetStr,1,0x20)				//pad to 1 byte

	numXYevents = 0

//


	Open/R refnum as filepathstr
	
tic()

	FBinRead refnum, gNASStr
	FBinRead/F=2/U/B=3 refnum, gRevision
	FBinRead/F=2/U/B=3 refnum, gOffset
	FBinRead/F=2/U/B=3 refnum, gTime1
	FBinRead/F=2/U/B=3 refnum, gTime2
	FBinRead/F=2/U/B=3 refnum, gTime3
	FBinRead/F=2/U/B=3 refnum, gTime4
	FBinRead/F=2/U/B=3 refnum, gTime5
//	FBinRead/F=2/U/B=3 refnum, gTime6
//	FBinRead refnum, gDetStr
	FBinRead/F=2/U/B=3 refnum, gVolt
	FBinRead/F=3/U/B=3 refnum, gResol


// how many events?
	int numEvents
	uint64	timeVal
	int		xPos,yPos
	
	// 10 bytes per event 1b,1b,8b
	FStatus refnum
	numEvents = (V_logEOF - 23)/10
	Print "numEvents = ",numEvents
	

	Make/O/U/B/N=(numEvents) xW,yW
	Make/O/U/L/N=(numEvents) timeW

//	Open/R refnum as filepathstr
//	FSetPos refnum, 23		// at start of data block

	int step,jj,ii

	STRUCT eventWord s
	STRUCT eventWord2 s2
	STRUCT eventWord5 s5
	STRUCT eventWord8 s8
	STRUCT eventWord10 s10


	Variable num = 10

// throw away a few events (10 or less)
// to make sure I've got a multiple of 10 (or num)
	do
		numEvents -= 1
	while(mod(numEvents,num) != 0)

	step = num

	if(step == 1)
		Print "reading 10 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s
			
	
			xw[ii] = s.xPos		//1st byte xPos
			yw[ii] = s.yPos		//2nd byte yPos
			timeW[ii] = s.eventTime	// last 8 bytes timeVal
	
		endfor
	endif

	if(step == 2)
		Print "reading 20 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s2
			
			xw[ii] = s2.xPos1		//1st byte xPos
			yw[ii] = s2.yPos1		//2nd byte yPos
			timeW[ii] = s2.eventTime1	// last 8 bytes timeVal

			xw[ii+1] = s2.xPos2		//1st byte xPos
			yw[ii+1] = s2.yPos2		//2nd byte yPos
			timeW[ii+1] = s2.eventTime2	// last 8 bytes timeVal
	
		endfor
	endif


	if(step == 5)
		Print "reading 50 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s5
			
			xw[ii] = s5.xPos1		//1st byte xPos
			yw[ii] = s5.yPos1		//2nd byte yPos
			timeW[ii] = s5.eventTime1	// last 8 bytes timeVal
			
			xw[ii+1] = s5.xPos2		//1st byte xPos
			yw[ii+1] = s5.yPos2		//2nd byte yPos
			timeW[ii+1] = s5.eventTime2	// last 8 bytes timeVal
			
			xw[ii+2] = s5.xPos3		//1st byte xPos
			yw[ii+2] = s5.yPos3		//2nd byte yPos
			timeW[ii+2] = s5.eventTime3	// last 8 bytes timeVal
			
			xw[ii+3] = s5.xPos4		//1st byte xPos
			yw[ii+3] = s5.yPos4		//2nd byte yPos
			timeW[ii+3] = s5.eventTime4	// last 8 bytes timeVal
			
			xw[ii+4] = s5.xPos5		//1st byte xPos
			yw[ii+4] = s5.yPos5		//2nd byte yPos
			timeW[ii+4] = s5.eventTime5	// last 8 bytes timeVal
	
		endfor
	endif

	if(step == 8)
		Print "reading 80 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s8
			
			jj = ii
			xw[jj] = s8.xPos1		//1st byte xPos
			yw[jj] = s8.yPos1		//2nd byte yPos
			timeW[jj] = s8.eventTime1	// last 8 bytes timeVal
			
			jj += 1
			xw[jj] = s8.xPos2		
			yw[jj] = s8.yPos2		
			timeW[jj] = s8.eventTime2	

			jj += 1
			xw[jj] = s8.xPos3	
			yw[jj] = s8.yPos3		
			timeW[jj] = s8.eventTime3	

			jj += 1
			xw[jj] = s8.xPos4		
			yw[jj] = s8.yPos4		
			timeW[jj] = s8.eventTime4	

			jj += 1
			xw[jj] = s8.xPos5		
			yw[jj] = s8.yPos5		
			timeW[jj] = s8.eventTime5	

			jj += 1
			xw[jj] = s8.xPos6		
			yw[jj] = s8.yPos6		
			timeW[jj] = s8.eventTime6	

			jj += 1
			xw[jj] = s8.xPos7		
			yw[jj] = s8.yPos7		
			timeW[jj] = s8.eventTime7	

			jj += 1
			xw[jj] = s8.xPos8		
			yw[jj] = s8.yPos8		
			timeW[jj] = s8.eventTime8	

	
		endfor
	endif


	if(step == 10)
		Print "reading 100 bytes"
		for(ii=0;ii<numevents;ii+=step)
		
			FBinRead/F=0 refnum, s10
			
			jj = ii
			xw[jj] = s10.xPos1		//1st byte xPos
			yw[jj] = s10.yPos1		//2nd byte yPos
			timeW[jj] = s10.eventTime1	// last 8 bytes timeVal
			
			jj += 1
			xw[jj] = s10.xPos2		
			yw[jj] = s10.yPos2		
			timeW[jj] = s10.eventTime2	

			jj += 1
			xw[jj] = s10.xPos3	
			yw[jj] = s10.yPos3		
			timeW[jj] = s10.eventTime3	

			jj += 1
			xw[jj] = s10.xPos4		
			yw[jj] = s10.yPos4		
			timeW[jj] = s10.eventTime4	

			jj += 1
			xw[jj] = s10.xPos5		
			yw[jj] = s10.yPos5		
			timeW[jj] = s10.eventTime5	

			jj += 1
			xw[jj] = s10.xPos6		
			yw[jj] = s10.yPos6		
			timeW[jj] = s10.eventTime6	

			jj += 1
			xw[jj] = s10.xPos7		
			yw[jj] = s10.yPos7		
			timeW[jj] = s10.eventTime7	

			jj += 1
			xw[jj] = s10.xPos8		
			yw[jj] = s10.yPos8		
			timeW[jj] = s10.eventTime8	

			jj += 1
			xw[jj] = s10.xPos9		
			yw[jj] = s10.yPos9		
			timeW[jj] = s10.eventTime9	

			jj += 1
			xw[jj] = s10.xPos10		
			yw[jj] = s10.yPos10		
			timeW[jj] = s10.eventTime10	

	
		endfor
	endif


	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum

toc()

	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	

	KillWaves/Z timePt,xLoc,yLoc
	Duplicate/O xW xLoc
	Duplicate/O yW yLoc
	Rename timeW timePt
	
	KillWaves/Z xw,yW
	
// TODO
// add more to the status display of the file load/decode
//	
	// dispStr will be displayed on the panel
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numevents
	dispStr += tmpStr

	KillWaves/Z Events

	SetDataFolder root:
	
	return(0)
	
End 


//////////////

Proc BinEventBarGraph()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif
	
	DoWindow/F EventBarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(110*sc,705*sc,610*sc,1132*sc)/N=V_EventBarGraph /K=1 binCount vs binEndTime
		SetDataFolder fldrSav0
		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=0
		ModifyGraph useBarStrokeRGB=1
		ModifyGraph standoff=0
		SetAxis left 0,*
		Label bottom "\\Z14Time (seconds)"
		Label left "\\Z14Number of Events"
	endif
End


Proc ShowBinTable() 
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	DoWindow/F BinEventTable
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Edit/W=(498*sc,699*sc,1003*sc,955*sc) /K=1/N=BinEventTable binCount,binEndTime,timeWidth
		ModifyTable format(Point)=1,sigDigits(binEndTime)=8,width(binEndTime)=100*sc
		SetDataFolder fldrSav0
	endif
EndMacro


// only show the first 1500 data points
//
Proc ShowRescaledTimeGraph()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif
	
	DoWindow/F RescaledTimeGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(25*sc,44*sc,486*sc,356*sc)/K=1/N=RescaledTimeGraph rescaledTime
		SetDataFolder fldrSav0
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb(rescaledTime)=(0,0,0)
		ModifyGraph msize=1
//		SetAxis/A=2 left			//only autoscale the visible data (based on the bottom limits)
		SetAxis bottom 0,1500
		ErrorBars rescaledTime OFF 
			
		if(root:Packages:NIST:gLaptopMode == 1)
			Label left "\\Z10Time (seconds)"
			Label bottom "\\Z10Event number"
		else
			Label left "\\Z14Time (seconds)"
			Label bottom "\\Z14Event number"
		endif
		ShowInfo
	endif
	
EndMacro



/////////////
//The histogramming
//
// 6 AUG 2012
//
// from Igor Exchange, RGerkin
//  http://www.igorexchange.com/node/1373
// -- see the related thread on the mailing list
//
//Function Setup_JointHistogram()
//
////	tic()
//
//	make/D /o/n=1000000 data1=gnoise(1), data2=gnoise(1)
//	make/D /o/n=(25,25) myHist
//	setscale x,-3,3,myHist
//	setscale y,-3,3,myHist
//	IndexForHistogram(data1,data2,myhist)
//	Wave index=SavedIndex
//	JointHistogram(data1,data2,myHist,index)
//	NewImage myHist
//	
////	toc()
//	
//End


// this is not used - it now conflicts with the name of a built-in function in Igor 7
//
Function xJointHistogram(w0,w1,hist,index)
	wave w0,w1,hist,index
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 	
	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1} index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// histogram with a point range
//
// x- just need to send x2pnt or findLevel, or something similar to define the POINT
// values
//
// x- can also speed this up since the index only needs to be done once, so the
// histogram operation can be done separately, as the bins require
//
//
Function JointHistogramWithRange(w0,w1,hist,index,pt1,pt2)
	wave w0,w1,hist,index
	Variable pt1,pt2
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)

	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1}/R=[pt1,pt2] index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// just does the indexing, creates wave SavedIndex in the current folder for the index
//
Function IndexForHistogram(w0,w1,hist)
	wave w0,w1,hist
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 
	// Scale between 0 and the number of bins to create an index wave.  
	if(ThreadProcessorCount<4) // For older machines, matrixop is faster.  
		matrixop /free idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	else // For newer machines with many cores, multithreading with make is faster.  
		make/free/n=(n) idx
		multithread idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	endif
 
 	KillWaves/Z SavedIndex
 	MoveWave idx,SavedIndex
 	
//	// Compute the histogram and redimension it.  
//	histogram /b={0,1,bins0*bins1} idx,hist
//	redimension /n=(bins0,bins1) hist // Redimension to 2D.  
//	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
//	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End





////////////// Post-processing of the event mode data
//
//
// TODO:
// -- this is ALL geared towards ordela event mode data and the 6.7s errors, and bad signal
//   I don't know if I'll need any of this for the SANS Tube event data.
//
//
Proc ShowEventCorrectionPanel()
	DoWindow/F EventCorrectionPanel
	if(V_flag ==0)
		EventCorrectionPanel()
	EndIf
End

Proc EventCorrectionPanel()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif
	
	PauseUpdate; Silent 1		// building window...
	SetDataFolder root:Packages:NIST:Event:
	
	if(exists("rescaledTime") == 1)
		Display /W=(35*sc,44*sc,761*sc,533*sc)/K=2 rescaledTime
		DoWindow/C EventCorrectionPanel
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=1
		ErrorBars rescaledTime OFF
			
		if(root:Packages:NIST:gLaptopMode == 1)
			Label left "\\Z10Time (seconds)"
			Label bottom "\\Z10Event number"	
		else
			Label left "\\Z14Time (seconds)"
			Label bottom "\\Z14Event number"	
		endif
		SetAxis bottom 0,0.10*numpnts(rescaledTime)		//show 1st 10% of data for speed in displaying
		
		ControlBar 100
		Button button0,pos={sc*20,12*sc},size={sc*70,20*sc},proc=EC_AddCursorButtonProc,title="Cursors",fSize=12*sc
		Button button1,pos={sc*20,38*sc},size={sc*80,20*sc},proc=EC_ShowAllButtonProc,title="All Data",fSize=12*sc
//		Button button2,pos={sc*20,64*sc},size={sc*80,20*sc},proc=EC_ColorizeTimeButtonProc,title="Colorize"


//		Button buttonDispAll,pos={sc*140,12*sc},size={sc*100,20*sc},proc=EC_DisplayButtonProc,title="Display-All"
//		Button button4,pos={sc*140,38*sc},size={sc*100,20*sc},proc=EC_DisplayButtonProc,title="Display-One"

		Button buttonDispZoom,pos={sc*140,12*sc},size={sc*100,20*sc},proc=EC_DisplayButtonProc,title="Display-Zoom",fSize=12*sc
//		Button button4,pos={sc*140,38*sc},size={sc*100,20*sc},proc=EC_DisplayButtonProc,title="Display-One"

		SetVariable setVar1,pos={sc*140,38*sc},size={sc*100,20*sc},title="Scale",value=_NUM:0.1
		SetVariable setvar1,limits={0.01,1,0.02},fSize=12*sc

//		Button button7,pos={sc*140,64*sc},size={sc*100,20*sc},proc=EC_FindOutlierButton,title="Zap Outlier"

//	
//		Button buttonDiffAll,pos={sc*290,12*sc},size={sc*110,20*sc},proc=EC_DoDifferential,title="Differential-All"
//		Button button6,pos={sc*290,38*sc},size={sc*110,20*sc},proc=EC_DoDifferential,title="Differential-One"	
//		Button button9,pos={sc*290,64*sc},size={sc*110,20*sc},proc=EC_TrimPointsButtonProc,title="Clean-One"
//
//		SetVariable setVar0,pos={sc*290,88*sc},size={sc*130,20*sc},title="Panel Number",value=_NUM:1
//		SetVariable setvar0,limits={1,4,1}
	

//		Button buttonCleanAll,pos={sc*(290+150),12*sc},size={sc*110,20*sc},proc=EC_SortTimeButtonProc,title="Sort-All"
		Button button10,pos={sc*(290+150),64*sc},size={sc*110,20*sc},proc=EC_SaveWavesButtonProc,title="Save Waves",fSize=12*sc

				
		Button button11,pos={sc*683,12*sc},size={sc*30,20*sc},proc=EC_HelpButtonProc,title="?",fSize=12*sc
		Button button12,pos={sc*658,90*sc},size={sc*60,20*sc},proc=EC_DoneButtonProc,title="Done",fSize=12*sc		

	else
		DoAlert 0, "Please load some event data, then you'll have something to edit."
	endif
	
	SetDataFolder root:
	
EndMacro



// figure out which traces are on the graph - and put the cursors there
//
Function EC_AddCursorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:

			String list=""			
			list = WaveList("*", ";", "WIN:EventCorrectionPanel")

			// can be either rescaledTime or onePanel, not both
			if(strlen(list) == 0)
				DoAlert 0,"No data on graph"
			else
				if(strsearch(list,"rescaled",0) >= 0)
					Wave rescaledTime = rescaledTime
					Cursor/P A rescaledTime 0
					Cursor/P B rescaledTime numpnts(rescaledTime)-1
				else
					//must be onePanel
					Wave onePanel = onePanel
					Cursor/P A onePanel 0
					Cursor/P B onePanel numpnts(onePanel)-1
				endif
			
			endif


			ShowInfo
			
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//
Function EC_ColorizeTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
//			Group_as_Panel(-1)		//colorize the entire data set

			// use the tube_panel wave generated in Group_as_Panel() to color the z
			//
			SetDataFolder root:Packages:NIST:Event:
			Wave tube_panel = tube_panel
			Wave rescaledTime = rescaledTime
			
			String list = WaveList("*", ";", "WIN:EventCorrectionPanel")

			if(strsearch(list,"rescaled",0) >= 0)
				ModifyGraph mode(rescaledTime)=4
				ModifyGraph marker(rescaledTime)=19
				ModifyGraph lSize(rescaledTime)=2
				ModifyGraph msize(rescaledTime)=3
				ModifyGraph gaps(rescaledTime)=0
				ModifyGraph useMrkStrokeRGB(rescaledTime)=1
				ModifyGraph zColor(rescaledTime)={tube_panel,*,*,Rainbow16}
			else
				DoAlert 0,"Show All Data before colorizing"			
			endif
		
			SetDataFolder root:			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//
Function EC_SortTimeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:Event:
			
			SortTimeData()

			
			SetDataFolder root:			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
//
// switch based on ba.ctrlName
//
// now, this changes the zoom of the display to some fraction of full scale
//
Function EC_DisplayButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:Event:
//			// save the zoom
//			Variable b_min,b_max,l_min,l_max
//			GetAxis/Q bottom
//			b_min=V_min
//			b_max=V_max
//			GetAxis/Q left
//			l_min=V_min
//			l_max=V_max
//			
//			if(cmpstr(ba.ctrlName,"buttonDispZoom")==0)
//				// button is Display-All
//				RemoveFromGraph/Z onePanel,rescaledTime
//				AppendToGraph rescaledTime
//				ModifyGraph rgb(rescaledTime)=(0,0,0)
//
//			else
//				// button is Display-One
//				ControlInfo setvar0
//				KeepOneGroup(V_Value)
//			
//				SetDataFolder root:Packages:NIST:Event:
//
//				RemoveFromGraph/Z rescaledTime,onePanel
//				AppendToGraph onePanel
//				ModifyGraph rgb(onePanel)=(0,0,0)
//
//			endif
			
			ControlInfo setvar1
			
			// restore the zoom
		//	SetAxis left, l_min,l_max
			String list = WaveList("*", ";", "WIN:EventCorrectionPanel")
			String item = StringFromList(0,list,";")
			Wave w=$item
			Variable npt = numpnts(w)

			Wave rescaledTime = rescaledTime

			SetAxis bottom, 0,V_Value*npt
			SetAxis left 0,rescaledTime[trunc(V_Value*npt)]
			
			SetDataFolder root:			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



//
// switch based on ba.ctrlName
//
// differentiated time - all data, or part

Function EC_DoDifferential(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
						
			SetDataFolder root:Packages:NIST:Event:
			// save the zoom
			String list=""
			Variable b_min,b_max,l_min,l_max
			GetAxis/Q bottom
			b_min=V_min
			b_max=V_max
			GetAxis/Q left
			l_min=V_min
			l_max=V_max
	
	
				
			if(cmpstr(ba.ctrlName,"buttonDiffAll")==0)
				// button is Display-All
				
				DifferentiatedTime()
				//generates rescaledTime_DIF
				
				DoWindow/F EventCorrectionPanel
				//if trace is not on graph, add it

				SetDataFolder root:Packages:NIST:Event:

				list = WaveList("*_DIF", ";", "WIN:EventCorrectionPanel")
				if(WhichListItem("rescaledTime_DIF", list,";") < 0)			// not on the graph
					AppendToGraph/R rescaledTime_DIF
					ModifyGraph msize=1,rgb(rescaledTime_DIF)=(65535,0,0)
					ModifyGraph gaps(rescaledTime_DIF)=0
					
					RemoveFromGraph/Z onePanel,rescaledTime
					AppendToGraph rescaledTime
					ModifyGraph rgb(rescaledTime)=(0,0,0)

					ReorderTraces _back_, {rescaledTime_DIF}		// put the differential behind the event data
				endif
				RemoveFromGraph/Z onePanel_DIF 		//just in case
			else
				// button is Display-One
				ControlInfo setvar0
			//	KeepOneGroup(V_Value) // not needed here - (fresh) grouping is done in Differentiate
				
//				Differentiate_onePanel(V_Value,-1)		// do the whole data set
				// generates the wave onePanel_DIF

				DoWindow/F EventCorrectionPanel
				//if trace is not on graph, add it
				SetDataFolder root:Packages:NIST:Event:


				list = WaveList("*_DIF", ";", "WIN:EventCorrectionPanel")
				if(WhichListItem("onePanel_DIF", list,";") < 0)			// not on the graph
					AppendToGraph/R onePanel_DIF
					ModifyGraph msize=1,rgb(onePanel_DIF)=(65535,0,0)
					ModifyGraph gaps(onePanel_DIF)=0

					RemoveFromGraph/Z rescaledTime,onePanel
					AppendToGraph onePanel
					ModifyGraph rgb(onePanel)=(0,0,0)
				
					ReorderTraces _back_, {onePanel_DIF}		// put the differential behind the event data
				endif
				RemoveFromGraph/Z rescaledTime_DIF 		//just in case

			endif

			// touch up the graph with labels left and right
			NVAR laptopMode = root:Packages:NIST:gLaptopMode
			if(laptopMode == 1)
				Label left "\\Z10Time (seconds)"
				Label right "\\Z10Differential (dt/event)"	
			else
				Label left "\\Z14Time (seconds)"
				Label right "\\Z14Differential (dt/event)"	
			endif
			
			// restore the zoom
			SetAxis left, l_min,l_max
			SetAxis bottom, b_min,b_max
			
			SetDataFolder root:			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// points removed are inclusive
//
// put both cursors on the same point to remove just that single point
//
// -- setVar0
//
// SortTimeData()
//
Function EC_TrimPointsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			SetDataFolder root:Packages:NIST:Event:
			// save the zoom
			String list=""
			Variable b_min,b_max,l_min,l_max
			GetAxis/Q bottom
			b_min=V_min
			b_max=V_max
			GetAxis/Q left
			l_min=V_min
			l_max=V_max
	
			// get the panel number
			ControlInfo setvar0
			
//			KeepOneGroup(V_Value)
			
			// no need to run KeepOneGroup() - this is done in Differentiate_onePanel
			// to be sure that the grouping has been immediately done.
			
//			Differentiate_onePanel(V_Value,-1)		// do the whole data set
			// generates the wave onePanel_DIF and badPoints

			SetDataFolder root:Packages:NIST:Event:
	
	/// delete all of the "time reversal" points from the data
			Wave rescaledTime = rescaledTime
			Wave/Z rescaledTime_DIF = rescaledTime_DIF
			Wave timePt = timePt
			Wave xLoc = xLoc
			Wave yLoc = yLoc
			Wave location = location
			Wave tube=tube
			Variable ii,num,pt,step16
			
			Wave bad=badPoints		// these are the "time reversal" points

			num=numpnts(bad)
			step16 = 0
			// loop through backwards so I don't shift the index
			for(ii=num-1;ii>=0;ii-=1)
				pt = bad[ii]-1		// actually want to delete the point before
				// is the time step > 16 ms? 
				if((rescaledTime[ii] - rescaledTime[ii-1]) > kBadStep_s)
					DeletePoints pt, 1, rescaledTime,location,timePt,xLoc,yLoc,tube
					
					if(WaveExists(rescaledTime_DIF))
						DeletePoints pt, 1,rescaledTime_DIF		//may not extst
					endif
					
					Printf "(Pt-1)=%d, time step (ms) = %g \r",pt,rescaledTime[ii] - rescaledTime[ii-1]
					step16 += 1
				endif
			endfor
			
			//purely to get the grammar right
			if(step16 == 1)
				Printf "%d point in set %d had step > 16 ms\r",step16,V_Value
			else
				Printf "%d points in set %d had step > 16 ms\r",step16,V_Value
			endif	
					
			// restore the zoom
			SetAxis left, l_min,l_max
			SetAxis bottom, b_min,b_max

			
			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// This is the same functionality as the button, but instead loops
// over all 4 panels.
//
// Cleans all of the "bad" > 16 ms points from each panel
//
// then follow this call with a sort All, since the remaining steps are
// simply a consequence of buffering
//
// If I need to reproduce this, go back to VSANS
//
Function EC_CleanAllPanels()
		

//		SetDataFolder root:Packages:NIST:Event:
//
//	/// delete all of the "time reversal" points from the data
//		Wave rescaledTime = rescaledTime
//		Wave/Z rescaledTime_DIF = rescaledTime_DIF
//		Wave timePt = timePt
//		Wave xLoc = xLoc
//		Wave yLoc = yLoc
////		Wave location = location
////		Wave tube=tube
//		Variable ii,num,pt,step16,jj
//		
//		jj=1
//
//		
//		Differentiate_onePanel(jj,-1)		// do the whole data set
//		// generates the wave onePanel_DIF and badPoints
//
//		Wave bad=root:Packages:NIST:Event:badPoints		// these are the "time reversal" points
//
//		num=numpnts(bad)
//		step16 = 0
//		
//		// loop through backwards so I don't shift the index
//		for(ii=num-1;ii>=0;ii-=1)
//			pt = bad[ii]-1		// actually want to delete the point before
//			// is the time step > 16 ms? 
//			if((rescaledTime[ii] - rescaledTime[ii-1]) > kBadStep_s)
//				DeletePoints pt, 1, rescaledTime,timePt,xLoc,yLoc
//				
//				if(WaveExists(rescaledTime_DIF))
//					DeletePoints pt, 1, rescaledTime_DIF		// this may not exist
//				endif
//				
//				Print "time step (ms) = ",rescaledTime[ii] - rescaledTime[ii-1]
//				step16 += 1
//			endif
//		endfor
//		
//		//purely to get the grammar right
//		if(step16 == 1)
//			Printf "%d point in set %d had step > 16 ms\r",step16,jj
//		else
//			Printf "%d points in set %d had step > 16 ms\r",step16,jj
//		endif
//	
//		// updates the longest time (as does every operation of adjusting the data)
//		NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
//		t_longest = waveMax(rescaledTime)
//		
//		SetDataFolder root:

	return(0)
End





//
// Function to delete a single point identified with both cursors
// -- see SANS event mode for implementation
//
Function EC_FindOutlierButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:Event:
			
			Wave rescaledTime = rescaledTime
			Wave onePanel = onePanel
			Wave timePt = timePt
			Wave xLoc = xLoc
			Wave yLoc = yLoc
			Variable ptA,ptB,numElements,lo,hi
			
			ptA = pcsr(A)
			ptB = pcsr(B)
//			lo=min(ptA,ptB)
//			hi=max(ptA,ptB)			
			numElements = 1			//just remove a single point
			if(ptA == ptB)
				DeletePoints ptA, numElements, rescaledTime,timePt,xLoc,yLoc,onePanel
			endif
//			printf "Points %g to %g have been deleted in rescaledTime, timePt, xLoc, and yLoc\r",ptA,ptB
			
			// updates the longest time (as does every operation of adjusting the data)
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			t_longest = waveMax(rescaledTime)
			
	
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// don't un-do the sort, that was part of the necessary adjustments
//
// not implemented -- saving takes way too long...
// and the SANS data appears to be rather clean
//
Function EC_SaveWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DoAlert 0,"Save not implemented"
						
//			SetDataFolder root:Packages:NIST:Event:
//			
//			Wave rescaledTime = rescaledTime
//			Wave timePt = timePt
//			Wave xLoc = xLoc
//			Wave yLoc = yLoc
//			Wave tube = tube
//			Save/T xLoc,yLoc,timePt,rescaledTime,tube		//will ask for a name
//			
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// this duplicates all of the bits that would be done if the "load" button was pressed
//
Function EC_ImportWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:

			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			SVAR dispStr = root:Packages:NIST:Event:gEventDisplayString
			String tmpStr="",fileStr,filePathStr
			
			// load in the waves, saved as Igor text to preserve the data type
			LoadWave/T/O/P=catPathName
			filePathStr = S_fileName
			if(strlen(S_fileName) == 0)
				//user cancelled
				DoAlert 0,"No file selected, nothing done."
				return(0)
			endif
			
			NVAR mode = root:Packages:NIST:Event:gEvent_Mode				// ==0 for "stream", ==1 for Oscillatory
			// clear out the old sort index, if present, since new data is being loaded
			KillWaves/Z OscSortIndex
			Wave timePt=timePt
			Wave rescaledTime=rescaledTime
			
			t_longest = waveMax(rescaledTime)		//should be the last point
			
	
			fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
			sprintf tmpStr, "%s: a user-modified event file\r",fileStr 
			dispStr = tmpStr
	
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EC_ShowAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SetDataFolder root:Packages:NIST:Event:

			String list = WaveList("*", ";", "WIN:EventCorrectionPanel")
			if(strsearch(list,"rescaledTime",0) >= 0)
				// already on graph, do nothing
				
			else
				RemoveFromGraph/Z onePanel,rescaledTime
				RemoveFromGraph/Z onePanel_DIF,rescaledTime_DIF
				AppendToGraph rescaledTime
				
//				AppendToGraph/R rescaledTime_DIF
//				ModifyGraph msize=1,rgb(rescaledTime_DIF)=(65535,0,0)
//				ModifyGraph gaps(rescaledTime_DIF)=0
//				
//				ModifyGraph rgb(rescaledTime)=(0,0,0)
//
//				ReorderTraces _back_, {rescaledTime_DIF}		// put the differential behind the event data
			endif
			
			
			
			SetAxis/A
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EC_HelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DisplayHelpTopic/Z "VSANS Data Reduction Documentation[Correcting Errors in VSANS Event Data]"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EC_DoneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoWindow/K EventCorrectionPanel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End












//////////////   Custom Bins  /////////////////////
//
//
//
// make sure that the bins are defined and the waves exist before
// trying to draw the panel
//
Proc Show_CustomBinPanel()
	DoWindow/F CustomBinPanel
	if(V_flag ==0)
		Init_CustomBins()
		CustomBinPanel()
	EndIf
End


Function Init_CustomBins()

	NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest

	Variable/G root:Packages:NIST:Event:gEvent_ForceTmaxBin=1		//==1 to enforce t_longest in user-defined custom bins

	SetDataFolder root:Packages:NIST:Event:
		
	Make/O/D/N=(nSlice) timeWidth
	Make/O/D/N=(nSlice+1) binEndTime,binCount
	
	timeWidth = t_longest/nslice
	binEndTime = p
	binCount = p+1	
	
	SetDataFolder root:
	
	return(0)
End

////////////////	
//
// Allow custom definitions of the bin widths
//
// Define by the number of bins, and the time width of each bin
//
// This shares the number of slices and the maximum time with the main panel
//
Proc CustomBinPanel()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(130*sc,44*sc,851*sc,455*sc)/K=2 /N=CustomBinPanel
	DoWindow/C CustomBinPanel
	ModifyPanel fixedSize=1//,noEdit =1
	SetDrawLayer UserBack
	
	Button button0,pos={sc*654,42*sc}, size={sc*50,20*sc},title="Done"
	Button button0,proc=CB_Done_Proc,fSize=12*sc
	Button button1,pos={sc*663,14*sc},size={sc*40,20*sc},proc=CB_HelpButtonProc,title="?",fSize=12*sc
	Button button2,pos={sc*216,42*sc},size={sc*80,20*sc},title="Update",proc=CB_UpdateWavesButton,fSize=12*sc	
	SetVariable setvar1,pos={sc*23,13*sc},size={sc*160,20*sc},title="Number of slices"
	SetVariable setvar1,proc=CB_NumSlicesSetVarProc,value=root:Packages:NIST:Event:gEvent_nslices,fSize=12*sc
	SetVariable setvar2,pos={sc*24,44*sc},size={sc*160,20*sc},title="Max Time (s)",fSize=12*sc
	SetVariable setvar2,value=root:Packages:NIST:Event:gEvent_t_longest	

	CheckBox chkbox1,pos={sc*216,14*sc},title="Enforce Max Time?",fSize=12*sc
	CheckBox chkbox1,variable = root:Packages:NIST:Event:gEvent_ForceTmaxBin
	Button button3,pos={sc*500,14*sc},size={sc*90,20*sc},proc=CB_SaveBinsButtonProc,title="Save Bins",fSize=12*sc
	Button button4,pos={sc*500,42*sc},size={sc*100,20*sc},proc=CB_ImportBinsButtonProc,title="Import Bins",fSize=12*sc	
		
	SetDataFolder root:Packages:NIST:Event:

	Display/W=(291*sc,86*sc,706*sc,395*sc)/HOST=CustomBinPanel/N=BarGraph binCount vs binEndTime
	ModifyGraph mode=5
	ModifyGraph marker=19
	ModifyGraph lSize=2
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=2
	ModifyGraph hbFill=2
	ModifyGraph gaps=0
	ModifyGraph usePlusRGB=1
	ModifyGraph toMode=1
	ModifyGraph useBarStrokeRGB=1
	ModifyGraph standoff=0
	SetAxis left 0,*
	Label bottom "\\Z14Time (seconds)"
	Label left "\\Z14Number of Events"
	SetActiveSubwindow ##
	
	// and the table
	Edit/W=(13*sc,87*sc,280*sc,394*sc)/HOST=CustomBinPanel/N=T0
	AppendToTable/W=CustomBinPanel#T0 timeWidth,binEndTime
	ModifyTable width(Point)=40
	SetActiveSubwindow ##
	
	SetDataFolder root:
	
EndMacro

// save the bins - use Igor Text format
//
Function CB_SaveBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			
			Save/T timeWidth,binEndTime			//will ask for a name

			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End

// Import the bins - use Igor Text format
//
// -- be sure that the number of bins is reset
// -?- how about the t_longest? - this should be set by the load, not here
//
// -- loads in timeWidth and binEndTime
//
Function CB_ImportBinsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices

			SetDataFolder root:Packages:NIST:Event:

			// prompt for the load of data
			LoadWave/T/O
			if(strlen(S_fileName) == 0)
				//user cancelled
				DoAlert 0,"No file selected, nothing done."
				return(0)
			endif

			Wave timeWidth = timeWidth
			nSlice = numpnts(timeWidth)
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End



//
// can either use the widths as stated -- then the end time may not
// match the actual end time of the data set
//
// -- or --
//
// enforce the end time of the data set to be the end time of the bins,
// then the last bin width must be reset to force the constraint
//
//
Function CB_UpdateWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR nSlice = root:Packages:NIST:Event:gEvent_nslices
			NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
			NVAR enforceTmax = root:Packages:NIST:Event:gEvent_ForceTmaxBin
			
			// update the waves, and recalculate everything for the display
			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			Wave binCount = binCount
			
			// use the widths as entered
			binEndTime[0] = 0
			binEndTime[1,] = binEndTime[p-1] + timeWidth[p-1]
			
			// enforce the longest time as the end bin time
			// note that this changes the last time width
			if(enforceTmax)
				binEndTime[nSlice] = t_longest
				timeWidth[nSlice-1] = t_longest - binEndTime[nSlice-1]
			endif
			
			binCount = p+1
			binCount[nSlice] = 0		// last point is zero, just for display
//			binCount *= sign(timeWidth)		//to alert to negative time bins
			
			// make the timeWidth bold and red if the widths are negative
			WaveStats/Q timeWidth
			if(V_min < 0)
				ModifyTable/W=CustomBinPanel#T0 style(timeWidth)=1,rgb(timeWidth)=(65535,0,0)			
			else
				ModifyTable/W=CustomBinPanel#T0 style(timeWidth)=0,rgb(timeWidth)=(0,0,0)			
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	SetDataFolder root:
	
	return 0
End

Function CB_HelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//
			DisplayHelpTopic/Z "VSANS Data Reduction Documentation[Setting up Custom Bin Widths - VSANS]"

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CB_Done_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K CustomBinPanel
			break
	endswitch
	return(0)
End


Function CB_NumSlicesSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			SetDataFolder root:Packages:NIST:Event:

			Wave timeWidth = timeWidth
			Wave binEndTime = binEndTime
			
			Redimension/N=(dval) timeWidth
			Redimension/N=(dval+1) binEndTime,binCount
			
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


///////////////////
//
// utility to split a large file
// 100 MB is the recommended size
// events can be clipped here, so be sure to trim the ends of the 
// resulting files as needed.
//
// - works like the unix 'split' command
//
//

Proc SplitBigFile(splitSize, baseStr)
	Variable splitSize = 100
	String baseStr="split"
	Prompt splitSize,"Target file size, in MB"
	Prompt baseStr,"File prefix, number will be appended"
	
	
	fSplitBigFile(splitSize, baseStr)
	
	ShowSplitFileTable()
End

Function/S fSplitBigFile(splitSize, baseStr)
	Variable splitSize
	String baseStr		


	String fileName=""		// File name, partial path, full path or "" for dialog.
	Variable refNum
	String str
	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
	
	listStr=""		//initialize output list

	Variable readSize=1e6		//1 MB
	Make/O/B/U/N=(readSize) aBlob			//1MB worth
	Variable numSplit
	Variable num,ii,jj,outRef,frac
	String thePath, outStr
	
	Printf "SplitSize = %u MB\r",splitSize
	splitSize = trunc(splitSize) * 1e6		// now in bytes
	
	
	// Open file for read.
	Open/R/Z=2/F="????"/P=catPathName refNum as fileName
	thePath = ParseFilePath(1, S_fileName, ":", 1, 0)
	Print "thePath = ",thePath
	
	// Store results from Open in a safe place.
	Variable err = V_flag
	String fullPath = S_fileName

	if (err == -1)
		Print "cancelled by user."
		return ("")
	endif

	FStatus refNum
	
	Printf "total # bytes = %u\r",V_logEOF

	numSplit=0
	if(V_logEOF > splitSize)
		numSplit = trunc(V_logEOF/splitSize)
	endif

	frac = V_logEOF - numSplit*splitSize
	Print "numSplit = ",numSplit
	Printf "frac = %u\r",frac
	
	num=0
	if(frac > readSize)
		num = trunc(frac/readSize)
	endif

	
	frac = frac - num*readSize

	Print "num = ",num
	Printf "frac = %u\r",frac
	
//	baseStr = "split"
	
	for(ii=0;ii<numSplit;ii+=1)
		outStr = (thePath+baseStr+num2str(ii))
//		Print "outStr = ",outStr
		Open outRef as outStr

		for(jj=0;jj<(splitSize/readSize);jj+=1)
			FBinRead refNum,aBlob
			FBinWrite outRef,aBlob
		endfor

		Close outRef
//		listStr += outStr+";"
		listStr += baseStr+num2str(ii)+";"
	endfor

	Make/O/B/U/N=(frac) leftover
	// ii was already incremented past the loop
	outStr = (thePath+baseStr+num2str(ii))
	Open outRef as outStr
	for(jj=0;jj<num;jj+=1)
		FBinRead refNum,aBlob
		FBinWrite outRef,aBlob
	endfor
	FBinRead refNum,leftover
	FBinWrite outRef,leftover

	Close outRef
//	listStr += outStr+";"
	listStr += baseStr+num2str(ii)+";"

	FSetPos refNum,V_logEOF
	Close refNum
	
	KillWaves/Z aBlob,leftover
	return(listStr)
End

//// allows the list of loaded files to be edited
//Function ShowSplitFileTable()
//
//	SVAR str = root:Packages:NIST:Event:gSplitFileList
//	
//	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
//	if(waveExists(tw) != 1)	
//		Make/O/T/N=1 root:Packages:NIST:Event:SplitFileWave
//		WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
//	endif
//
//	List2TextWave(str,tw)
//	Edit tw
//
//	return(0)
//End


//// save the sliced data, and accumulate slices
//  *** this works with sliced data -- that is data that has been PROCESSED
//
// need some way of ensuring that the slices match up since I'm blindly adding them together. 
//
// mode = 0		wipe out the old accumulated, copy slicedData to accumulatedData
// mode = 1		add current slicedData to accumulatedData
// mode = 2		copy accumulatedData to slicedData in preparation of export or display
// mode = 3		unused...
//
//	"Split Large File",SplitBigFile()
//	"Accumulate First Slice",AccumulateSlices(0)
//	"Add Current Slice",AccumulateSlices(1)
//	"Display Accumulated Slices",AccumulateSlices(2)	
//
Function AccumulateSlicesButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable mode
	mode = str2num(ctrlName[strlen(ctrlName)-1])
//	Print "mode=",mode
	AccumulateSlices(mode)
	
	return(0)
End

Function AccumulateSlices(mode)
	Variable mode
	
	SetDataFolder root:Packages:NIST:Event:

	switch(mode)	
		case 0:
			DoAlert 0,"The current data has been copied to the accumulated set. You are now ready to add more data."
			KillWaves/Z accumulatedData
			Duplicate/O slicedData accumulatedData		
			break
		case 1:
			DoAlert 0,"The current data has been added to the accumulated data. You can add more data."
			Wave acc=accumulatedData
			Wave cur=slicedData
			acc += cur
			break
		case 2:
			DoAlert 0,"The accumulated data is now the display data and is ready for display or export."
			Duplicate/O accumulatedData slicedData
			// do something to "touch" the display to force it to update
			NVAR gLog = root:Packages:NIST:Event:gEvent_logint
			LogIntEvent_Proc("",gLog)
			break
		default:			
				
	endswitch

	SetDataFolder root:
	return(0)
end


// make a table with the associations of the event files and the raw data file
//
Function MakeEventFileTable()

	String rawList="",item=""
	Variable num,ii
	
	rawList = N_GetRawDataFileList()
	num = itemsinlist(rawList)
	Make/O/T/N=(num) RawFiles,Event_Files
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,rawList)
		
		RawFiles[ii] = item
		Event_Files[ii] = getDetEventFileName(item)
//		Event_Middle[ii] = getDetEventFileName(item,"ML")
	endfor
	
	Edit RawFiles,Event_Files
		
	return(0)
End

////////////////////////////////////////////
//
// Panel and procedures for decimation
//
////////////////////////////////////////////

//Function E_ShowDecimateButton(ctrlName) : ButtonControl
//	String ctrlName
//
//	DoWindow/F DecimatePanel
//	if(V_flag ==0)
//		Execute "DecimatePanel()"
//	endif
//End
//
//
//Proc DecimatePanel() //: Panel
//	
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(1602,44,1961,380)/K=1
////	ShowTools/A
//	Button button0,pos={sc*29,15*sc},size={sc*100,20*sc},proc=SplitFileButtonProc,title="Split Big File"
//	SetVariable setvar0,pos={sc*182,55*sc},size={sc*150,15*sc},title="Decimation factor",fsize=12
//	SetVariable setvar0,limits={1,inf,1},value= root:Packages:NIST:Event:gDecimation
//	Button button1,pos={sc*26,245*sc},size={sc*150,20*sc},proc=LoadDecimateButtonProc,title="Load and Decimate"
//	Button button2,pos={sc*25,277*sc},size={sc*150,20*sc},proc=ConcatenateButtonProc,title="Concatenate"
//	Button button3,pos={sc*25,305*sc},size={sc*150,20*sc},proc=DisplayConcatenatedButtonProc,title="Display Concatenated"
//	Button button4,pos={sc*29,52*sc},size={sc*130,20*sc},proc=Stream_LoadDecim,title="Load From List"
//	
//	GroupBox group0 title="Manual Controls",size={sc*185,112*sc},pos={sc*14,220}
//EndMacro


Function SplitFileButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "SplitBigFile()"
End


// show all of the data
//
Proc ShowDecimatedGraph()
	Variable sc = 1
			
	if(root:Packages:NIST:gLaptopMode == 1)
		sc = 0.7
	endif

	DoWindow/F DecimatedGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(25*sc,44*sc,486*sc,356*sc)/K=1/N=DecimatedGraph rescaledTime_dec
		SetDataFolder fldrSav0
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb(rescaledTime_dec)=(0,0,0)
		ModifyGraph msize=1
		ErrorBars rescaledTime_dec OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"
		ShowInfo
	endif
	
EndMacro

// data has NOT been processed
//
// so work with x,y,t, and rescaled time
// variables -- t_longest
Function ConcatenateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoAlert 1,"Is this the first file?"
	Variable first = V_flag
	
	fConcatenateButton(first)
	
	return(0)
End

Function fConcatenateButton(first)
	Variable first


	SetDataFolder root:Packages:NIST:Event:

	Wave timePt_dTmp=timePt_dTmp
	Wave xLoc_dTmp=xLoc_dTmp
	Wave yLoc_dTmp=yLoc_dTmp
	Wave rescaledTime_dTmp=rescaledTime_dTmp
	
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	
	if(first==1)		//1==yes, 2==no
		//then copy the files over, adjusting the time to start from zero
		// rescaledTime starts from zero (set by the loader)

		timePt_dTmp -= timePt_dTmp[0]			//subtract the first value
		
		Duplicate/O timePt_dTmp timePt_dec
		Duplicate/O xLoc_dTmp xLoc_dec
		Duplicate/O yLoc_dTmp yLoc_dec
		Duplicate/O rescaledTime_dTmp rescaledTime_dec
		
		t_longest_dec = t_longest
	
	else
		// concatenate the files + adjust the time
		Wave timePt_dec=timePt_dec
		Wave xLoc_dec=xLoc_dec
		Wave yLoc_dec=yLoc_dec
		Wave rescaledTime_dec=rescaledTime_dec

		// adjust the times -- assuming they add
		// rescaledTime starts from zero (set by the loader)
		//
		//
		rescaledTime_dTmp += rescaledTime_dec[numpnts(rescaledTime_dec)-1]
		rescaledTime_dTmp += abs(rescaledTime_dec[numpnts(rescaledTime_dec)-1] - rescaledTime_dec[numpnts(rescaledTime_dec)-2])
		
		timePt_dTmp -= timePt_dTmp[0]			//subtract the first value	
		
		timePt_dTmp += timePt_dec[numpnts(timePt_dec)-1]		// offset by the last point
		timePt_dTmp += abs(timePt_dec[numpnts(timePt_dec)-1] - timePt_dec[numpnts(timePt_dec)-2])		// plus delta so there's not a flat step
		
		Concatenate/NP/O {timePt_dec,timePt_dTmp}, tmp
		Duplicate/O tmp timePt_dec
		
		Concatenate/NP/O {xLoc_dec,xLoc_dTmp}, tmp
		Duplicate/O tmp xLoc_dec
		
		Concatenate/NP/O {yLoc_dec,yLoc_dTmp}, tmp
		Duplicate/O tmp yLoc_dec
		
		Concatenate/NP/O {rescaledTime_dec,rescaledTime_dTmp}, tmp
		Duplicate/O tmp rescaledTime_dec
		

		KillWaves tmp

		t_longest_dec = rescaledTime_dec[numpnts(rescaledTime_dec)-1]

	endif
	
	
	SetDataFolder root:
	
	return(0)

End

Function DisplayConcatenatedButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//copy the files over to the display set for processing
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt_dec=timePt_dec
	Wave xLoc_dec=xLoc_dec
	Wave yLoc_dec=yLoc_dec
	Wave rescaledTime_dec=rescaledTime_dec
		
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
	
	Duplicate/O timePt_dec timePt
	Duplicate/O xLoc_dec xLoc
	Duplicate/O yLoc_dec yLoc
	Duplicate/O rescaledTime_dec rescaledTime
	
	t_longest = t_longest_dec	
	
	SetDataFolder root:
	
	return(0)

End



// unused, old testing procedure
Function LoadDecimateButtonProc(ctrlName) : ButtonControl
	String ctrlName

	LoadEventLog_Button("")
	
	// now decimate
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated

	NVAR decimation = root:Packages:NIST:Event:gDecimation


	Duplicate/O timePt, timePt_dTmp
	Duplicate/O xLoc, xLoc_dTmp
	Duplicate/O yLoc, yLoc_dTmp
	Resample/DOWN=(decimation)/N=1 timePt_dTmp
	Resample/DOWN=(decimation)/N=1 xLoc_dTmp
	Resample/DOWN=(decimation)/N=1 yLoc_dTmp


	Duplicate/O timePt_dTmp rescaledTime_dTmp
	rescaledTime_dTmp = 1e-7*(timePt_dTmp - timePt_dTmp[0])		//convert to seconds and start from zero
	t_longest_dec = waveMax(rescaledTime_dTmp)		//should be the last point

	SetDataFolder root:

	
End







////
//// loads a list of files, decimating each chunk as it is read in
////
//Function Stream_LoadDecim(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
//	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
//
//	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
//	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
//	NVAR decimation = root:Packages:NIST:Event:gDecimation
//
//	String pathStr
//	PathInfo catPathName
//	pathStr = S_Path
//
//// if "stream" mode is not checked - abort
//	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
//	if(gEventModeRadioVal != MODE_STREAM)
//		Abort "The mode must be 'Stream' to use this function"
//		return(0)
//	endif
//
//// if the list has been edited, turn it into a list
//	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
//	if(WaveExists(tw))
//		listStr = TextWave2SemiList(tw)
//	else
//		ShowSplitFileTable()
//		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
//		return(0)
//	endif
//	
//
//	//loop through everything in the list
//	Variable num,ii
//	num = ItemsInList(listStr)
//	
//	for(ii=0;ii<num;ii+=1)
//
//// (1) load the file, prepending the path		
//		filename = pathStr + StringFromList(ii, listStr  ,";")
//		
//
//#if (exists("EventLoadWave")==4)
//		LoadEvents_XOP()
//#else
//		LoadEvents()
//#endif	
//
//		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root:
//
//		Wave timePt=timePt
//		Wave xLoc=xLoc
//		Wave yLoc=yLoc
//		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//
//		Duplicate/O timePt rescaledTime
//		rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
//		t_longest = waveMax(rescaledTime)		//should be the last point
//		
//// (2) do the decimation, just on timePt. create rescaledTime from the decimated timePt	
//		
//		Duplicate/O timePt, timePt_dTmp
//		Duplicate/O xLoc, xLoc_dTmp
//		Duplicate/O yLoc, yLoc_dTmp
//		Resample/DOWN=(decimation)/N=1 timePt_dTmp
//		Resample/DOWN=(decimation)/N=1 xLoc_dTmp
//		Resample/DOWN=(decimation)/N=1 yLoc_dTmp
//	
//	
//		Duplicate/O timePt_dTmp rescaledTime_dTmp
//		rescaledTime_dTmp = 1e-7*(timePt_dTmp - timePt_dTmp[0])		//convert to seconds and start from zero
//		t_longest_dec = waveMax(rescaledTime_dTmp)		//should be the last point
//		
//
//// (3) concatenate
//		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
//	
//	endfor
//
//////		Now that everything is decimated and concatenated, create the rescaled time wave
////	SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root:
////	Wave timePt_dec = timePt_dec
////	Duplicate/O timePt_dec rescaledTime_dec
////	rescaledTime_dec = 1e-7*(timePt_dec - timePt_dec[0])		//convert to seconds and start from zero
////	t_longest_dec = waveMax(rescaledTime_dec)		//should be the last point
//	
//	DisplayConcatenatedButtonProc("")
//	
//	SetDataFolder root:
//
//	return(0)
//End
//
//Function ShowList_ToLoad(ctrlName)
//	String ctrlName
//	
//	ShowSplitFileTable()
//	
//	return(0)
//End


////
//// loads a list of files that have been adjusted and saved
//// -- does not decimate
////
//Function Stream_LoadAdjustedList(ctrlName)
//	String ctrlName
//	
//	Variable fileref
//
//	SVAR filename = root:Packages:NIST:Event:gEvent_logfile
//	NVAR t_longest = root:Packages:NIST:Event:gEvent_t_longest
//
//	SVAR listStr = root:Packages:NIST:Event:gSplitFileList
//	NVAR t_longest_dec = root:Packages:NIST:Event:gEvent_t_longest_decimated
////	NVAR decimation = root:Packages:NIST:Event:gDecimation
//
//	String pathStr
//	PathInfo catPathName
//	pathStr = S_Path
//
//// if "stream" mode is not checked - abort
//	NVAR gEventModeRadioVal= root:Packages:NIST:Event:gEvent_mode
//	if(gEventModeRadioVal != MODE_STREAM)
//		Abort "The mode must be 'Stream' to use this function"
//		return(0)
//	endif
//
//// if the list has been edited, turn it into a list
//	WAVE/T/Z tw = root:Packages:NIST:Event:SplitFileWave
//	if(WaveExists(tw))
//		listStr = TextWave2SemiList(tw)
//	else
//		ShowSplitFileTable()
//		DoAlert 0,"Enter the file names in the table, then click 'Load From List' again."
//		return(0)
//	endif
//	
//
//	//loop through everything in the list
//	Variable num,ii
//	num = ItemsInList(listStr)
//	
//	for(ii=0;ii<num;ii+=1)
//
//// (1) load the file, prepending the path		
//		filename = pathStr + StringFromList(ii, listStr  ,";")
//		
//		SetDataFolder root:Packages:NIST:Event:
//		LoadWave/T/O fileName
//
//		SetDataFolder root:Packages:NIST:Event:			//LoadEvents sets back to root: ??
//
//// this is what is loaded -- _dec extension is what is concatenated, and will be copied back later
//		Wave timePt=timePt
//		Wave xLoc=xLoc
//		Wave yLoc=yLoc
//		Wave rescaledTime=rescaledTime
//
////		CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
//
////		Duplicate/O timePt rescaledTime
////		rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
////		t_longest = waveMax(rescaledTime)		//should be the last point
//		
//// (2) No decimation
//		
//		Duplicate/O timePt, timePt_dTmp
//		Duplicate/O xLoc, xLoc_dTmp
//		Duplicate/O yLoc, yLoc_dTmp
//		Duplicate/O rescaledTime, rescaledTime_dTmp
//
//
//// (3) concatenate
//		fConcatenateButton(ii+1)		//passes 1 for the first time, >1 each other time
//	
//	endfor
//	
//	DisplayConcatenatedButtonProc("")		// this resets the longest time, too
//		
//	SetDataFolder root:
//
//	return(0)
//End
//
///////////////////////////////////////
//
//// dd-mon-yyyy hh:mm:ss -> Event file name
//// the VAX uses 24 hr time for hh
////
//// scans as string elements since I'm reconstructing a string name
//Function/S DateAndTime2HSTName(dateandtime)
//	string dateAndTime
//	
//	String day,yr,hh,mm,ss,time_secs
//	Variable mon
//	string str,monStr,fileStr
//	
//	str=dateandtime
//	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
//	mon = monStr2num(monStr)
//
//	fileStr = "Event"+yr+num2str(mon)+day+hh+mm+ss+".hst"
//	Print fileStr
//
//	return(fileStr)
//end
//
//// dd-mon-yyyy hh:mm:ss -> Event file name
//// the VAX uses 24 hr time for hh
////
//// scans as string elements since I'm reconstructing a string name
//Function DateAndTime2HSTNumber(dateandtime)
//	string dateAndTime
//	
//	String day,yr,hh,mm,ss,time_secs
//	Variable mon,num
//	string str,monStr,fileStr
//	
//	str=dateandtime
//	sscanf str,"%2s-%3s-%4s %2s:%2s:%2s",day,monStr,yr,hh,mm,ss
//	mon = monStr2num(monStr)
//
//	fileStr = yr+num2str(mon)+day+hh+mm+ss
//	num = str2num(fileStr)
//
//	return(num)
//end
//
//Function HSTName2Num(str)
//	String str
//	
//	Variable num
//	sscanf str,"Event%d.hst",num
//	return(num)
//end
///////////////////////////////