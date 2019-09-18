#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.






//
// for the event mode data with the proposed 64 bit structure, I may be able to use Igor for everything.
//
// Skipping the appropriate bits of the header (after I read them in) may be possible with
// either LoadWave (treating the entire wave as 64 bit, unsigned), loading chunks from clipboard?
// -- see in LoadWave, the suggestions for "Loading Large Waves"
//
// or using FBinRead, again, filling a wave, or a chunk of the data, as needed
//
// Then - since the data has sequential timing, not dependent on rollovers, I can
// chunk the data for parallel processing, and piece it back together 
// after all of the decoding is done.
//
// 
// I don't know if it's possible to use a STRUCT  definition for each 64 bit word so that I could address
// the bytes directly - since that may not work properly in Igor, and I'm not sure how to address the 6 byte section
// -possibly with a uchar(6) definition?
//
//
// 	(from WM help) You can define an array of structures as a field in a structure:
//		Structure mystruct
//			STRUCT Point pt[100]			// Allowed as a sub-structure
//		EndStructure
//
// -- which may be of use to read "blocks" of datq from a file using FBinRead
//
// -- right now, I'm having issues with being able to "cast" or convert uint64 values to STRUCT
// (I don't know how to read from the struct if I can't fill it??)
//
// TODO:
//
// (5/2017)
// The basic bits of reading work, but will need to be customized to be able to accomodate file names in/out
// and especially the number of disabled tubes (although as long as I have the offset, it shouldn't be that
// big of an issue.
//
// -- don't see the struct idea working out. only in real c-code if needed
//
// -- need to add detector binning to the decoding, to place the counts within the correct panels
// -- not sure how this will work with JointHistogram Operation
// (split to separate "streams" of values for each detector panel?
//
//
// -- can I efficiently use "sort" (on the tube index) to block the data into groups that can be split
//  into 4 sets of waves
//  that can then be binned per panel, using the usual Joint histogram procedures? Works only if the 
// tube indexing is orderly. if it's a mess, Ill need to try something else (indexed sort?) (replace?)
// (manually? ugh.)
//

//
////
//Structure eventWord
//	uchar eventTime[6]
//	uchar location
//	uchar tube
//endStructure



//
//
Function V_testBitShift()

//	// /l=64 bit, /U=unsigned
//	Make/L/U/N=100 eventWave
//	eventWave = 0
	
	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
	
	int64 i64_num,b1,b2,b3,b4,b5,b6,b7,b8
	int64 i64_ticks,i64_start
	
	b1=255
	b3=255
	b5=255
	b7=255
	b2=0
	b4=0
	b6=0
	b8=0
	
	b7 = b7 << 8
	b6 = b6 << 16
	b5 = b5 << 24
	b4 = b4 << 32
	b3 = b3 << 40
	b2 = b2 << 48
	b1 = b1 << 56
	
	i64_num = b1+b2+b3+b4+b5+b6+b7+b8
	printf "%64b\r",i64_num
	
	return(0)
End

Function V_MakeFakeEvents()

//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=10 smallEventWave
	smallEventWave = 0
	
	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
	
	uint64 i64_num,b1,b2,b3,b4,b5,b6,b7,b8
	uint64 i64_ticks,i64_start
	
//	b1 = 47
//	b2 = 123
//	i64_ticks = 123456789
	b1 = 41
	b2 = 66
	i64_ticks = 15


//	b2 = b2 << 48
//	b1 = b1 << 56
//	
//	i64_num = b1+b2+i64_ticks

	// don't shift b1
	b2 = b2 << 8
	i64_ticks = i64_ticks << 16

	i64_num = b1+b2+i64_ticks

	printf "%64b\r",i64_num
	print i64_num
	
	smallEventWave[0] = i64_num
	
	return(0)
End

Function V_decodeFakeEvent()

	WAVE w = smallEventWave
	uint64 val,b1,b2,btime
	val = w[0]
	
//	printf "%64b\r",w[0]		//wrong (drops the last Å 9 bits)
	printf "%64b\r",val			//correct, assign value to 64bit variable
//	print w[0]				//wrong
	print val				// correct
	
//	b1 = (val >> 56 ) & 0xFF			// = 255, last byte, after shifting
//	b2 = (val >> 48 ) & 0xFF	
//	btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes


	b1 = val & 0xFF
	b2 = (val >> 8) & 0xFF
	btime = (val >> 16)

	
	print b1
	print b2
	print btime


//	//test as struct
//	Print "as STRUCT"
//	
//	STRUCT eventWord s
//	
//	s = w[0]
//	
//	print s.tube
//	print s.location
//	print s.eventTime
	

		
	return(0)
End

//
// tested up to num=1e8 successfully
//
Function V_MakeFakeEventWave(num)
	Variable num
	
	Variable ii


//	num = 1e3
	
//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=(num) eventWave
	eventWave = 0
	
	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
	
	uint64 i64_num,b1,b2
	uint64 i64_ticks,i64_start
	
	i64_start = ticks
	for(ii=0;ii<num;ii+=1)
//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)
		b1 = trunc(abs(enoise(192)))		//since truncated, need 192 as highest random to give 191 after trunc
		b2 = trunc(abs(enoise(128)))		// same here, to get results [0,127]
		
//		i64_ticks = ticks-i64_start
		i64_ticks = ii+1
		
//		b2 = b2 << 48
//		b1 = b1 << 56

		// don't shift b1
		b2 = b2 << 8
		i64_ticks = i64_ticks << 16
	
		i64_num = b1+b2+i64_ticks
	
		eventWave[ii] = i64_num
	endfor


	return(0)
End


//
// TODO:
// -- can this be multithreaded (eliminating the loop)?
//
// MultiThread tube = (w[p]) & 0xFF	
// MultiThread location = (w[p] >> 8 ) & 0xFF	
// MultiThread eventTime = (w[p] >> 16)
//
// !!!!- yes - for a 35 MB file:
// for loop = 4.3 s
// MultiThread = 0.35 s
//
// !!! can I use the bit operations in MatrixOp? 1D waves are valid
//  to use with MatrixOp. Would it be better than multiThread?
//
//
Function V_decodeFakeEventWave(w)
	Wave w

v_tic()
//	WAVE w = eventWave
	uint64 val,b1,b2,btime
	val = w[0]
	
//	printf "%64b\r",w[0]		//wrong (drops the last Å 9 bits)
//	printf "%64b\r",val			//correct, assign value to 64bit variable
//	print w[0]				//wrong
//	print val				// correct
	
	Variable num,ii
	num=numpnts(w)
	
	Make/O/L/U/N=(num) eventTime
	Make/O/U/B/N=(num) tube,location		//8 bit unsigned

 MultiThread tube = (w[p]) & 0xFF	
 MultiThread location = (w[p] >> 8 ) & 0xFF	
 MultiThread eventTime = (w[p] >> 16)
	
//	for(ii=0;ii<num;ii+=1)
//		val = w[ii]
//		
////		b1 = (val >> 56 ) & 0xFF			// = 255, last two bytes, after shifting
////		b2 = (val >> 48 ) & 0xFF	
////		btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes
//
//		b1 = val & 0xFF
//		b2 = (val >> 8) & 0xFF
//		btime = (val >> 16)
//
//		tube[ii] = b1
//		location[ii] = b2
//		eventTime[ii] = btime
//		
//	endfor

v_toc()
		
	return(0)
End


Function V_writeFakeEventFile(fname)
	String fname

	WAVE w = eventWave
	Variable refnum
	
	String vsansStr="VSANS"
	Variable revision = 11
	Variable offset = 26		// no disabled tubes
	Variable time1 = 2017
	Variable time2 = 0525
	Variable time3 = 1122
	Variable time4 = 3344		// these 4 time pieces are supposed to be 8 bytes total
	Variable time5 = 3344		// these 5 time pieces are supposed to be 10 bytes total
	String detStr = "M"
	Variable volt = 1500
	Variable resol = 1e7
	
	
	Open refnum as fname

	FBinWrite refnum, vsansStr
	FBinWrite/F=2/U refnum, revision
	FBinWrite/F=2/U refnum, offset
	FBinWrite/F=2/U refnum, time1
	FBinWrite/F=2/U refnum, time2
	FBinWrite/F=2/U refnum, time3
	FBinWrite/F=2/U refnum, time4
	FBinWrite/F=2/U refnum, time5
	FBinWrite refnum, detStr
	FBinWrite/F=2/U refnum, volt
	FBinWrite/F=3/U refnum, resol

	FGetPos refnum 
	Print "End of header = ",V_filePos
	offset = V_filePos
	
	FSetPos refnum,7
	FBinWrite/F=2/U refnum, offset			//write the correct offset 

	
	FSetPos refNum, offset
	
	FBinWrite refnum, w
	
	close refnum
	
	return(0)
End

//
// use GBLoadWave to do the reading, then I can do the decoding
//
Function V_readFakeEventFile(fileName)
	String filename
	
// this reads in uint64 data, to a unit64 wave, skipping 22 bytes	
//	GBLoadWave/B/T={192,192}/W=1/S=22
	Variable num,refnum
	

//  to read a VSANS event file:
//
// - get the file name
//	- read the header (all of it, since I need parts of it) (maybe read as a struct? but I don't know the size!)
// - move to EOF and close
//
// - Use GBLoadWave to read the 64-bit events in

	String vsansStr=""
	Variable revision
	Variable offset		// no disabled tubes
	Variable time1
	Variable time2
	Variable time3
	Variable time4		// these 4 time pieces are supposed to be 8 bytes total
	Variable time5		// these 5 time pieces are supposed to be 10 bytes total
	String detStr=""
	Variable volt
	Variable resol

	vsansStr = PadString(vsansStr,5,0x20)		//pad to 5 bytes
	detStr = PadString(detStr,1,0x20)				//pad to 1 byte

	Open/R refnum as filename
	filename = S_fileName

v_tic()

	FBinRead refnum, vsansStr
	FBinRead/F=2/U refnum, revision
	FBinRead/F=2/U refnum, offset
	FBinRead/F=2/U refnum, time1
	FBinRead/F=2/U refnum, time2
	FBinRead/F=2/U refnum, time3
	FBinRead/F=2/U refnum, time4
	FBinRead/F=2/U refnum, time5
	FBinRead refnum, detStr			//NOTE - the example data file Phil sent skipped the detStr (no placeholder!)
	FBinRead/F=2/U refnum, volt
	FBinRead/F=3/U refnum, resol

	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum
	
// number of data bytes
	num = V_logEOF-offset
	Print "Number of data values = ",num/8
	
	GBLoadWave/B/T={192,192}/W=1/S=(offset) filename		// intel, little-endian
//	GBLoadWave/T={192,192}/W=1/S=(offset) filename			// motorola, big-endian
	
	Duplicate/O $(StringFromList(0,S_waveNames)) V_Events
	KillWaves/Z $(StringFromList(0,S_waveNames))
v_toc()	
	
	Print vsansStr
	Print revision
	Print offset
	Print time1
	Print time2
	Print time3
	Print time4
	Print time5
	Print detStr
	print volt
	print resol
	
	return(0)
End

//
//
//
Function V_MakeFakeEventWave_TOF(delayTime,std)
	Variable delayTime,std

	Variable num,ii,jj,numRepeat


	num = 1000
	numRepeat = 1000
	
//	delayTime = 50		//microseconds
//	std = 4					//std deviation, microseconds
	
//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=(num*numRepeat) eventWave
	eventWave = 0
	
	Make/O/D/N=(num) arrival
	
	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
	
	uint64 i64_num,b1,b2,b3,b4,b5,b6,b7,b8
	uint64 i64_ticks,i64_start
	
//	i64_start = ticks
	i64_ticks = 0
	for(jj=0;jj<numRepeat;jj+=1)
		arrival = delayTime + gnoise(std)
		sort arrival,arrival
		arrival *= 1000		//milliseconds now
	
		for(ii=0;ii<num;ii+=1)
	//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)
			b1 = trunc(abs(enoise(192)))		//since truncated, need 192 as highest random to give 191 after trunc
			b2 = trunc(abs(enoise(128)))		// same here, to get results [0,127]
			
			i64_ticks = trunc(arrival[ii])
			
//			b2 = b2 << 48
//			b1 = b1 << 56

			// don't shift b1
			b2 = b2 << 8
			i64_ticks = i64_ticks << 16
		
			i64_num = b1+b2+i64_ticks
			eventWave[jj*num+ii] = i64_num
		endfor
		
	endfor

	return(0)
End


// TODO:
//
// There may be memory issues with this
//
// -- do I want to do the time binning first?
// -- does it really matter?
//
Function V_SortAndSplitFakeEvents()

	Wave eventTime = root:EventTime
	Wave location = root:location
	Wave tube = root:tube
	
	Sort tube,tube,eventTime,location

	Variable b1,e1,b2,e2,b3,e3,b4,e4	
	FindValue/S=0/I=48 tube
	b1 = 0
	e1 = V_Value - 1
	b2 = V_Value
	FindValue/S=(b2)/I=96 tube
	e2 = V_Value - 1
	b3 = V_Value
	FindValue/S=(b3)/I=144 tube
	e3 = V_Value - 1
	b4 = V_Value
	e4 = numpnts(tube)-1
	
	Print b1,e1
	Print b2,e2
	Print b3,e3
	Print b4,e4
	
//	tube and location become x and y, and can be byte data
// eventTime still needs to be 64 bit - when do I convert it to FP? 
	Make/O/B/U/N=(e1-b1+1) tube1,location1
	Make/O/L/U/N=(e1-b1+1) eventTime1

	Make/O/B/U/N=(e2-b2+1) tube2,location2
	Make/O/L/U/N=(e2-b2+1) eventTime2
	
	Make/O/B/U/N=(e3-b3+1) tube3,location3
	Make/O/L/U/N=(e3-b3+1) eventTime3
	
	Make/O/B/U/N=(e4-b4+1) tube4,location4
	Make/O/L/U/N=(e4-b4+1) eventTime4
	
	
	tube1 = tube[p+b1]
	tube2 = tube[p+b2]
	tube3 = tube[p+b3]
	tube4 = tube[p+b4]
	
	location1 = location[p+b1]
	location2 = location[p+b2]
	location3 = location[p+b3]
	location4 = location[p+b4]
	
	eventTime1 = eventTime[p+b1]
	eventTime2 = eventTime[p+b2]
	eventTime3 = eventTime[p+b3]
	eventTime4 = eventTime[p+b4]
	
	
	KillWaves/Z eventTime,location,tube
	
	return(0)
End



// TODO:
//
// There may be memory issues with this
//
// -- do I want to do the time binning first?
// -- does it really matter?
//
Function V_SortAndSplitEvents()


	SetDataFolder root:Packages:NIST:VSANS:Event:
	
	Wave eventTime = EventTime
	Wave location = location
	Wave tube = tube

	Variable t1=ticks
 Print "sort started"	
	Sort tube,tube,eventTime,location
print "sort done ",(ticks-t1)/60

	Variable b1,e1,b2,e2,b3,e3,b4,e4	
	FindValue/S=0/I=48 tube
	b1 = 0
	e1 = V_Value - 1
	b2 = V_Value
	FindValue/S=(b2)/I=96 tube
	e2 = V_Value - 1
	b3 = V_Value
	FindValue/S=(b3)/I=144 tube
	e3 = V_Value - 1
	b4 = V_Value
	e4 = numpnts(tube)-1
	
	Print b1,e1
	Print b2,e2
	Print b3,e3
	Print b4,e4
	
//	tube and location become x and y, and can be byte data
// eventTime still needs to be 64 bit - when do I convert it to FP? 
	Make/O/B/U/N=(e1-b1+1) tube1,location1
	Make/O/L/U/N=(e1-b1+1) eventTime1

	Make/O/B/U/N=(e2-b2+1) tube2,location2
	Make/O/L/U/N=(e2-b2+1) eventTime2
	
	Make/O/B/U/N=(e3-b3+1) tube3,location3
	Make/O/L/U/N=(e3-b3+1) eventTime3
	
	Make/O/B/U/N=(e4-b4+1) tube4,location4
	Make/O/L/U/N=(e4-b4+1) eventTime4
	
	
	tube1 = tube[p+b1]
	tube2 = tube[p+b2]
	tube3 = tube[p+b3]
	tube4 = tube[p+b4]
	
	location1 = location[p+b1]
	location2 = location[p+b2]
	location3 = location[p+b3]
	location4 = location[p+b4]
	
	eventTime1 = eventTime[p+b1]
	eventTime2 = eventTime[p+b2]
	eventTime3 = eventTime[p+b3]
	eventTime4 = eventTime[p+b4]
	
	
	KillWaves/Z eventTime,location,tube
	
	return(0)
End


//
// switch the "active" panel to the selected group (1-4) (5 concatenates them all together)
//

//
// copy the set of tubes over to the "active" set that is to be histogrammed
// and redimension them to be sure that they are double precision
//
Function V_SwitchTubeGroup(tubeGroup)
	Variable tubeGroup
	
	SetDataFolder root:Packages:NIST:VSANS:Event:
	
	if(tubeGroup <= 4)
		Wave tube = $("tube"+num2Str(tubeGroup))
		Wave location = $("location"+num2Str(tubeGroup))
		Wave eventTime = $("eventTime"+num2Str(tubeGroup))
		
		Wave/Z xloc,yLoc,timePt
		
		KillWaves/Z timePt,xLoc,yLoc
		Duplicate/O eventTime timePt

// TODO:
// -- for processing, initially treat all of the tubes along x, and 128 pixels along y
//   panels can be transposed later as needed to get the orientation correct


//		if(tubeGroup == 1 || tubeGroup == 4)	
		// L/R panels, they have tubes along x	
			Duplicate/O tube xLoc
			Duplicate/O location yLoc
//		else
//		// T/B panels, tubes are along y
//			Duplicate/O tube yLoc
//			Duplicate/O location xLoc		
//		endif
		
		Redimension/D xLoc,yLoc,timePt	
		
	endif
	
	if(tubeGroup == 5)
		Wave xloc,yLoc,timePt
		
		KillWaves/Z timePt,xLoc,yLoc
		
		String str = ""
		str = "tube1;tube2;tube3;tube4;"
		Concatenate/O/NP str,xloc
		str = "location1;location2;location3;location4;"
		Concatenate/O/NP str,yloc
		str = "eventTime1;eventTime2;eventTime3;eventTime4;"
		Concatenate/O/NP str,timePt
		
		Redimension/D xLoc,yLoc,timePt	
	endif
	
	
	return(0)
End

Proc V_SwitchGroupAndCleanup(num)
	Variable num
	
	V_SwitchTubeGroup(num)
	SetDataFolder root:Packages:NIST:VSANS:Event:
	Duplicate/O timePt rescaledTime
	KillWaves/Z OscSortIndex
	print WaveMax(rescaledTime)
	root:Packages:NIST:VSANS:Event:gEvent_t_longest = waveMax(rescaledTime)
	
	SetDataFolder root:

end

Function V_count(num)
	Variable num
	
	SetDataFolder root:Packages:NIST:VSANS:Event:

	Wave xloc = xloc
	wave yloc = yloc
	Variable ii,npt,total=0
	npt = numpnts(xloc)
	for(ii=0;ii<npt;ii+=1)
		if(xloc[ii] == num)
			total += 1
		endif
		if(yloc[ii] == num)
			total += 1
		endif
	endfor
	
	Print total
	
	SetDataFolder root:
	return(0)
end



// Based on the numbering 0-191:
// group 1 = R (0,47) 			MatrixOp out = ReverseRows(in)
// group 2 = T (48,95) 		output = slices_T[q][p][r]
// group 3 = B (96,143) 		output = slices_B[XBINS-q-1][YBINS-p-1][r]		(reverses rows and columns)
// group 4 = L (144,191) 	MatrixOp out = ReverseCols(in)
//
// the transformation flips the panel to the view as if the detector was viewed from the sample position
// (this is the standard view for SANS and VSANS)
//
// Takes the data that was binned, and separates it into the 4 detector panels
// Waves are 3D waves x-y-time
//
// MatrixOp may not be necessary for the R/L transformations, but indexing or MatrixOp are both really fast.
//
//
Function V_SplitBinnedToPanels()

	SetDataFolder root:Packages:NIST:VSANS:Event:	
	Wave slicedData = slicedData		//this is 3D
	
	Variable nSlices = DimSize(slicedData,2)
	
	Make/O/D/N=(XBINS,YBINS,nSlices) slices_R, slices_L, slices_T, slices_B, output
	
	slices_R = slicedData[p][q][r]
	slices_T = slicedData[p+48][q][r]
	slices_B = slicedData[p+96][q][r]
	slices_L = slicedData[p+144][q][r]
	
	MatrixOp/O output = ReverseRows(slices_R)
	slices_R = output
	
	MatrixOp/O output = ReverseCols(slices_L)
	slices_L = output

		
	Redimension/N=(YBINS,XBINS,nSlices) output
	output = slices_T[q][p][r]
	KillWaves/Z slices_T
	Duplicate/O output slices_T
	
	output = slices_B[XBINS-q-1][YBINS-p-1][r]
	KillWaves/Z slices_B
	Duplicate/O output slices_B
	
	KillWaves/Z output
	SetDataFolder root:

	return(0)
End


// simple panel to display the 4 detector panels after the data has been binned and sliced
//
// TODO:
// -- label panels, axes
// -- add a way to display different slices (this can still be done on the main panel, all at once)
// -- any other manipulations?
//

Proc VSANS_EventPanels()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(720,45,1530,570)/N=VSANS_EventPanels/K=1
	DoWindow/C VSANS_EventPanels
	ModifyPanel fixedSize=1,noEdit =1

//	Display/W=(745,45,945,425)/HOST=# 
	Display/W=(10,45,210,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_L		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_L ctab= {*,*,ColdWarm,0}
	ModifyImage slices_L ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slice_L
	SetActiveSubwindow ##

//	Display/W=(1300,45,1500,425)/HOST=# 
	Display/W=(565,45,765,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_R		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_R ctab= {*,*,ColdWarm,0}
	ModifyImage slices_R ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slice_R
	SetActiveSubwindow ##

//	Display/W=(945,45,1300,235)/HOST=# 
	Display/W=(210,45,565,235)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_T		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_T ctab= {*,*,ColdWarm,0}
	ModifyImage slices_T ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slice_T
	SetActiveSubwindow ##

//	Display/W=(945,235,1300,425)/HOST=# 
	Display/W=(210,235,565,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:Event:slices_B		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage slices_B ctab= {*,*,ColdWarm,0}
	ModifyImage slices_B ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Event_slice_B
	SetActiveSubwindow ##
//


End

//
/////// to copy a sliced data set to a folder to save
//


// load event file from RAW data loaded
	// pick either the front or middle carriage
	// pick the "mode" of loading data (osc, stream, etc.)
// process the event data
// split to panels
// move slices to "export" location
// move bin details to export location
// repeat load + process + move with the 2nd carriage, using the same time binning
//
// save the data file, giving a new name to not overwrite the original data file
//


//
// root:Packages:NIST:VSANS:RAW:gFileList		//name of the data file(s) in raw (take 1st from semi-list)
//

Function V_DuplicateRAWForExport()
	KillDataFolder/Z root:export
	DuplicateDataFolder root:Packages:NIST:VSANS:RAW: root:export
	return(0)
end

Function V_CopySlicesForExport(detStr)
	String detStr
	
	if(cmpstr(detStr,"M") == 0)
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_B root:export:entry:instrument:detector_MB:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_T root:export:entry:instrument:detector_MT:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_L root:export:entry:instrument:detector_ML:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_R root:export:entry:instrument:detector_MR:slices
	else
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_B root:export:entry:instrument:detector_FB:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_T root:export:entry:instrument:detector_FT:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_L root:export:entry:instrument:detector_FL:slices
		Duplicate/O root:Packages:NIST:VSANS:Event:slices_R root:export:entry:instrument:detector_FR:slices
	endif
	
	Duplicate/O root:Packages:NIST:VSANS:Event:binEndTime root:export:entry:reduction:binEndTime
	Duplicate/O root:Packages:NIST:VSANS:Event:timeWidth root:export:entry:reduction:timeWidth	
	
	return(0)
end

//
// data is intact in the file so that it can still be read in as a regular raw data file.
//
Proc V_SaveExportedEvents()

	String filename = root:Packages:NIST:VSANS:RAW:gFileList		//name of the data file(s) in raw (take 1st from semi-list)
	String saveName

	saveName = StringFromList(0, fileName+";")
	Save_VSANS_file("root:export", "Events_"+saveName)
	Printf "Saved file %s\r","Events_"+saveName
End




//////////////////////////////////////////////////////////////
//
//
// Panel for reducing event data
//
//
//
//		Panel to have readout/buttons for:
//			# slices
//			timing information (table, graph)
//			protocol to use (popup)
//			Event_ file (popup)
//
//			Manually advance slice and display in RAW (for testing)
//
//

//
//		Save the total monitor count
//		Save the total count time
//		Save the sample label
//
//		? Don't need to save the original detector data (I can sum the slices)
//
//
// for each slice(N)
//		find the binWidth -> bin fraction
//		adjust count time
// 	adjust monitor count
//		? adjust integrated detector count
// 	adjust sample label (mark as slice(N)?)
//
//		copy slice(N) to each detector panel (ignore B)
//
//		Process through reduction protocol
//
//		give appropriate output name (N)
//
//


//*************************
//
// Procedures to allow batch reduction of Event data files
//
//****note that much of this file is becoming obsolete as improved methods for 
//reducing multiple files are introduced. Some of these procedures may not last long***
//
//**************************

//
//panel to allow reduction of a series of files using a selected  protocol
//
//main entry procedure to open the panel, initializing if necessary
Proc V_ReduceEventFilesPanel()
	
	DoWindow/F V_Event_Reduce_Panel
	If(V_flag == 0)
		V_InitializeEventReducePanel()
		//draw panel
		V_Event_Reduce_Panel()
		//pop the protocol list
		V_EVR_ProtoPopMenuProc("",1,"")
		//then update the popup list
		V_EVR_RedPopMenuProc("ERFilesPopup",1,"")
	Endif
End

//create the global variables needed to run the MReduce Panel
//all are kept in root:Packages:NIST:VSANS:Globals:MRED
//
Proc V_InitializeEventReducePanel()

	If(DataFolderExists("root:Packages:NIST:VSANS:Globals:EVRED"))
		//ok, do nothing
	else
		//no, create the folder and the globals
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:EVRED
//		String/G root:Packages:NIST:VSANS:Globals:MRED:gMRedMatchStr = "*"
		PathInfo catPathName
		If(V_flag==1)
			String dum = S_path
			String/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = dum
		else
			String/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = "no path selected"
		endif
		String/G root:Packages:NIST:VSANS:Globals:EVRED:gMRedList = "none"
		String/G root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList = "none"
		String/G root:Packages:NIST:VSANS:Globals:EVRED:gFileNumList=""
		Variable/G root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices=1
		Variable/G root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice=1


	Endif 
End


//
// borrows some of the basic functions from the MRED panel
//
Window V_Event_Reduce_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(535,72,951,288) /K=1 as "Event File File Reduction"
	ModifyPanel cbRGB=(60535,51151,51490)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawLine 7,30,422,30
	SetVariable PathDisplay,pos={77,7},size={300,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while reducing. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr
	Button PathButton,pos={3,3},size={70,20},proc=V_PickEVRPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={385,3},size={25,20},proc=V_ShowEVRHelp,title="?"
	Button helpButton,help={"Show the help file for reducing event files"}
	PopupMenu ERFilesPopup,pos={3,45},size={167,19},proc=V_EVR_RedPopMenuProc,title="File to Reduce"
	PopupMenu ERFilesPopup,help={"The displayed file is the one that will be reduced."}
	PopupMenu ERFilesPopup,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:EVRED:gMRedList"

	SetVariable ERSlices,pos={3,75},size={100,15},title="# of slices"
	SetVariable ERSlices,limits={0,1000,0},value=root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices
	
	SetVariable ERSelSlice,pos={150,75},size={100,15},title="current slice"
	SetVariable ERSelSlice,limits={0,1000,1},value=root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	SetVariable ERSelSlice,proc=V_ChangeSliceViewSetVar

	Button ToSTOButton,pos={305,45},size={100,20},proc=V_EVR_LoadAndSTO,title="Load to STO"
	Button ToSTOButton,help={"Load the event file and copy to STO"}

	Button TimeBinButton,pos={305,75},size={100,20},proc=V_EVR_TimeBins,title="Time Bins"
	Button TimeBinButton,help={"Display the time bins"}
				
//	SetVariable ERList,pos={3,48},size={350,13},proc=V_FileNumberListProc,title="File number list: "
//	SetVariable ERList,help={"Enter a comma delimited list of file numbers to reduce. Ranges can be entered using a dash."}
//	SetVariable ERList,limits={-Inf,Inf,1},value= root:Packages:NIST:VSANS:Globals:EVRED:gFileNumList

	PopupMenu ERProto_pop,pos={3,118},size={119,19},proc=V_EVR_ProtoPopMenuProc,title="Protocol "
	PopupMenu ERProto_pop,help={"All of the data files in the popup will be reduced using this protocol"}
	PopupMenu ERProto_pop,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList"
	Button ReduceAllButton,pos={3,178},size={180,20},proc=V_EVR_ReduceAllSlices,title="Reduce All Slices"
	Button ReduceAllButton,help={"This will reduce all slices."}
	Button ReduceOneButton,pos={3,148},size={180,20},proc=V_EVR_ReduceTopSlice,title="Reduce Selected Slice"
	Button ReduceOneButton,help={"This will reduce the selected slice."}
	
	Button DoneButton,pos={290,178},size={110,20},proc=V_EVR_DoneButtonProc,title="Done Reducing"
	Button DoneButton,help={"When done reducing files, this will close this control panel."}
EndMacro


//allows the user to set the path to the local folder that contains the SANS data
//2 global strings are reset after the path "catPathName" is reset in the function PickPath()
// this path is the only one, the globals are simply for convenience
//
Function V_PickEVRPathButton(PathButton) : ButtonControl
	String PathButton
	
	V_PickPath()		//sets the main global path string for catPathName
	
	//then update the "local" copy in the MRED subfolder
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = "no folder selected"
	else
		String/G root:Packages:NIST:VSANS:Globals:EVRED:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=V_Event_Reduce_Panel $"PathDisplay"
	
	//then update the popup list
	V_EVR_RedPopMenuProc("ERFilesPopup",1,"")
End

//
// loads the file in the popup (to RAW as usual)
// then copies the data to STO
//
//	updates the total number of slices
//
// resets the slice view to 0
//		changes the limits on the SetVar control {0,n,1}
//
Function V_EVR_LoadAndSTO(PathButton) : ButtonControl
	String PathButton

	String fileName
	Variable err

	ControlInfo ERFilesPopup
	fileName = S_Value
	
	err = V_LoadHDF5Data(FileName,"RAW")
	if(!err)		//directly from, and the same steps as DisplayMainButtonProc(ctrlName)
		SVAR hdfDF = root:file_name			// last file loaded, may not be the safest way to pass
		String folder = StringFromList(0,hdfDF,".")
		
		// this (in SANS) just passes directly to fRawWindowHook()
		V_UpdateDisplayInformation("RAW")		// plot the data in whatever folder type
								
		// set the global to display ONLY if the load was called from here, not from the 
		// other routines that load data (to read in values)
		SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
		gLast = hdfDF
						
	endif
	
	// now copy RAW to STO for safe keeping...
	//V_CopyHDFToWorkFolder(oldtype,newtype)
	V_CopyHDFToWorkFolder("RAW","STO")

	// read the number of slices from FL
	WAVE/Z w = root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:slices
	NVAR num = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices
	
	num = DimSize(w, 2)
	
	//change the slice view to slice 0
	SetVariable ERSelSlice,win=V_Event_Reduce_Panel,limits={0,(num-1),1}
	NVAR value=root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	value=0
	V_ChangeSliceViewSetVar("",0,"","")
	
	return(0)
End

// given a file already loaded into RAW (and copied to STO)
// display a selected slice (8 panels)
// rescale the monitor count
// rescale the count time
// update the sample label
//
// TODO -- and I missing anything that is done at the normal RAW load time
// that I am not doing here simply by copying over
// -- like... data error, nonlinear corrections, etc.
// the nonlinear corrections need only be done once, since the detector is the same for all slices.
//
Function V_ChangeSliceViewSetVar(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Variable ii
	String detStr,fname	
	// varNum is the only meaningful input, the slice number
	
	// copy STO to RAW
	V_CopyHDFToWorkFolder("STO","RAW")
	
	
	// switch data to point to the correct slice
	string tmpStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:" 

	fname="RAW"
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		Wave data = V_getDetectorDataW(fname,detStr)
		
		WAVE/Z slices = $("root:Packages:NIST:VSANS:RAW:entry:instrument:detector_"+detStr+":slices")
		data = slices[p][q][varNum]
		V_MakeDataError(tmpStr+"detector_"+detStr)		//update the error wave to match the slice
	endfor
		
	// TODO: update the times and counts
	// use a special "put", not "write" so it is written to the RAW folder, not the file
	//
	wave binEnd = root:Packages:NIST:VSANS:RAW:entry:reduction:binEndTime
	wave timeWidth = root:Packages:NIST:VSANS:RAW:entry:reduction:timeWidth
	
	Variable timeFract,num
	num = numpnts(binEnd)
	timeFract = timeWidth[varNum]/binEnd[num-1]

// get values from STO
	Variable mon_STO,ctTime_STO
	String label_STO

	ctTime_STO = V_getCount_time("STO")
	mon_STO = V_getBeamMonNormData("STO")
	label_STO = V_getSampleDescription("STO")
	
// mon ct
	V_putBeamMonNormData("RAW",mon_STO*timeFract)
// ct time
	V_putCount_time("RAW",ctTime_STO*timeFract)
// label
	V_putSampleDescription("RAW",label_STO+" slice "+num2str(varNum))
	
	return(0)
End


//
// locates the time bins and shows the time bin table (and plot?)
//
// Can't show the plot of counts/bin since there would be 8 of these now, one for
// each panel. Could show a total count per slice, but the numbers (binCount) is currently
// not written to the Event_ file.
//
// the macro that is called from the main Event panel shows the total counts/bin for the carriage
// that is active. Maybe this would be OK, but then there are still two sets of data, one for
// Front and one for Middle...
//
Function V_EVR_TimeBins(PathButton) : ButtonControl
	String PathButton

	wave binEnd = root:Packages:NIST:VSANS:RAW:entry:reduction:binEndTime
	wave timeWidth = root:Packages:NIST:VSANS:RAW:entry:reduction:timeWidth

	edit binEnd,timeWidth
	
//	DoWindow/F V_EventBarGraph
//	if(V_flag == 0)
//		PauseUpdate; Silent 1		// building window...
//		String fldrSav0= GetDataFolder(1)
//		SetDataFolder root:Packages:NIST:VSANS:Event:
//		Display /W=(110,705,610,1132)/N=V_EventBarGraph /K=1 binCount vs binEndTime
//		SetDataFolder fldrSav0
//		ModifyGraph mode=5
//		ModifyGraph marker=19
//		ModifyGraph lSize=2
//		ModifyGraph rgb=(0,0,0)
//		ModifyGraph msize=2
//		ModifyGraph hbFill=2
//		ModifyGraph gaps=0
//		ModifyGraph usePlusRGB=1
//		ModifyGraph toMode=0
//		ModifyGraph useBarStrokeRGB=1
//		ModifyGraph standoff=0
//		SetAxis left 0,*
//		Label bottom "\\Z14Time (seconds)"
//		Label left "\\Z14Number of Events"
//	endif
	
	
	return(0)
End

Proc V_ShowEVRHelp(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Documentation[Reducing Event Data]"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
	endif
End




//
//
//
Function V_EVR_RedPopMenuProc(ERFilesPopup,popNum,popStr) : PopupMenuControl
	String ERFilesPopup
	Variable popNum
	String popStr

	String list = V_GetValidEVRedPopupList()
//	
	SVAR str= root:Packages:NIST:VSANS:Globals:EVRED:gMredList
	str=list
	ControlUpdate ERFilesPopup
	return(0)
End

// get a  list of all of the sample files, based on intent
//
//
// only accepts files in the list that are purpose=scattering
//
Function/S V_GetValidEVRedPopupList()

	String semiList=""

	semiList = V_GetSAMList()
	return(semiList)

End

//returns a list of the available protocol waves in the protocols folder
//removes "CreateNew", "tempProtocol" and "fakeProtocol" from list (if they exist)
//since these waves do not contain valid protocol instructions
//
// also removes Base and DoAll since for event file reduction, speed is of the essence
// and there is no provision in the protocol for "asking" for the files to be identified
//
Function V_EVR_ProtoPopMenuProc(ERProto_pop,popNum,popStr) : PopupMenuControl
	String ERProto_pop
	Variable popNum
	String popStr

	//get list of currently valid protocols, and put it in the popup (the global list)
	//excluding "tempProtocol" and "CreateNew" if they exist
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	String list = WaveList("*",";","")
	SetDataFolder root:
	
	//remove items from the list (list is unchanged if the items are not present)
	list = RemoveFromList("CreateNew", list, ";")
	list = RemoveFromList("tempProtocol", list, ";")
	list = RemoveFromList("fakeProtocol", list, ";")
	list = RemoveFromList("PanelNameW", list, ";")
	list = RemoveFromList("Beg_pts", list, ";")
	list = RemoveFromList("End_pts", list, ";")
	list = RemoveFromList("trimUpdate", list, ";")
	list = RemoveFromList("Base", list, ";")
	list = RemoveFromList("DoAll", list, ";")
	
	String/G root:Packages:NIST:VSANS:Globals:EVRED:gMRProtoList = list
	ControlUpdate ERProto_pop

End

//
//button procedure to close the panel, 
//
Function V_EVR_DoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// this button will make sure all files are closed 
	//and close the panel

	Close/A
	DoWindow/K V_Event_Reduce_Panel
	
	KillDataFolder root:Packages:NIST:VSANS:Globals:EVRED
End




//
// reduce just the selected slice
//
// Assumes that:
// - the event data file has been loaded and copied to STO for repeated access
// - the protocol has been properly and completely defined (test one slice first!)
//
//
Function V_EVR_ReduceTopSlice(ctrlName) : ButtonControl
	String ctrlName

	//get the selected protocol
	ControlInfo ERProto_pop
	String protocolNameStr = S_Value
	
	//also set this as the current protocol, for the function that writes the averaged waves
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr
	
	// get the file name from the popup
	ControlInfo ERFilesPopup
	String samStr = S_Value
	
	// get the current slice number
	NVAR curSlice = root:Packages:NIST:VSANS:Globals:EVRED:gCurSlice
	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices
	
	//reduce all the files in the list here, using the global protocol(the full reference)
	//see -- DoReduceList is found in MultipleReduce.ipf
	
//	V_DoReduceList(commaList)
	Variable skipLoad = 0
	V_ExecuteProtocol_Event(protocolNameStr,samStr,curSlice,skipLoad)
	
	Return 0
End



//
// reduce all slices
//
Function V_EVR_ReduceAllSlices(ctrlName) : ButtonControl
	String ctrlName

	//get the selected protocol
	ControlInfo ERProto_pop
	String protocolNameStr = S_Value
	
	//also set this as the current protocol, for the function that writes the averaged waves
	String/G root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr = protocolNameStr
	
	// get the file name from the popup
	ControlInfo ERFilesPopup
	String samStr = S_Value
	
	// get the total number of slices
	NVAR totalSlices = root:Packages:NIST:VSANS:Globals:EVRED:gNumSlices
	
	
	Variable skipLoad = 0
	Variable curSlice = 0
	// do the first one (slice 0)
	V_ExecuteProtocol_Event(protocolNameStr,samStr,curSlice,skipLoad)
	
	skipLoad = 1
	for(curSlice = 1;curSlice<totalSlices; curSlice +=1)
		V_ExecuteProtocol_Event(protocolNameStr,samStr,curSlice,skipLoad)
	endfor
	
	
	Return 0
End



//////////////////////////////////
//
// This is the Event-equivalent version of ExecuteProtocol
// with special handling for shuffling the event slices from STO to RAW->SAM
// -skips repetitive loads
// -adjusts timing
// -names slices

//protStr is the full path to the selected protocol wave
//samStr is the name of the event data file "Event_sansNNNN.nxs.ngv"
// SliceNum is the number of slice to reduce (copy it from STO)
// skipLoad is a flag (0|1) to allow skip of loading EMP, BGD, etc. on repeated passes
Function V_ExecuteProtocol_Event(protStr,samStr,sliceNum,skipLoad)
	String protStr,samStr
	Variable sliceNum
	Variable skipLoad

	String protoPath = "root:Packages:NIST:VSANS:Globals:Protocols:"
	WAVE/T prot = $(protoPath+protStr)
//	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols
	
	Variable filesOK,err,notDone
	String activeType, msgStr, junkStr, pathStr=""
	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
//	NVAR useXMLOutput = root:Packages:NIST:gXML_Write
	
	//Parse the instructions in the prot wave
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	//6 = DRK file (**out of sequence)
	//7 = beginning trim points
	//8 = end trim points
	//9 = unused
	//10 = unused
	//11 = unused

//////////////////////////////
// DIV
//////////////////////////////
// for VSANS, DIV is used on each data file as it is converted to WORK, so it needs to be
//  the first thing in place, before any data or backgrounds are loaded

	//check for work.div file (prot[2])
	//load in if needed
	// no math is done here, DIV is applied as files are converted to WORK (the first operation in VSANS)
	//
		// save the state of the DIV preference
	NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	Variable saved_gDoDIVCor = gDoDIVCor
	
	if(!skipLoad)
		
		err = V_Proto_LoadDIV(prot[2])
		
		if(err)
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif
	endif
	
//////////////////////////////
// SAM
//////////////////////////////

	// move the selected slice number to RAW, then to SAM
	V_ChangeSliceViewSetVar("",sliceNum,"","")
	
	//Execute "V_Convert_to_Workfile()"
	err = V_Raw_to_work("SAM")
	
	//always update
	activeType = "SAM"
	V_UpdateDisplayInformation(ActiveType)


//////////////////////////////
// BGD
//////////////////////////////
	
	//check for BGD file  -- "ask" might not fail - "ask?" will - ? not allowed in VAX filenames
	// add if needed
	//use a "case" statement
	if(!skipLoad)
	
		msgStr = "Select background file"
		activeType = "BGD"
		
		err = V_Proto_LoadFile(prot[0],activeType,msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif
	
	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation(ActiveType)
	endif

//////////////////////////////
// EMP
//////////////////////////////	
	
	//check for emp file (prot[1])
	// add if needed
	if(!skipLoad)

		msgStr = "Select empty cell data"
		activeType = "EMP"
		
		err = V_Proto_LoadFile(prot[1],activeType,msgStr)
		if(err)
			PathInfo/S catPathName
			SetDataFolder root:
			Abort "No file selected, data reduction aborted"
		endif
	
	//	//Loader is in charge of updating, since it knows if data was loaded
	//	V_UpdateDisplayInformation(ActiveType)
	endif

//////////////////////////////
// CORRECT
//////////////////////////////

	//do the CORRECT step based on the answers to emp and bkg subtraction
	//by setting the proper"mode"
	//1 = both emp and bgd subtraction
	//2 = only bgd subtraction
	//3 = only emp subtraction
	//4 = no subtraction 
	//additional modes 091301
	//11 = emp, bgd, drk
	//12 = bgd and drk
	//13 = emp and drk
	//14 = no subtractions
	//work.drk is from proto[6]
	//
	//subtracting just the DRK data is NOT an option - it doesnt' really make any physical sense
	// - in this case, DRK is skipped (equivalent to mode==4)
	// automatically accounts for attenuators given the lookup tables and the 
	//desired subtractions
	//Attenuator lookup tables are alredy implemented (NG1 = NG7)
	//


/////// DRK is SKIPPED
	
//	//read in the DRK data if necessary
//	//only one file, assumed to be RAW data
//	//
//	String fname="",drkStr=""
//	drkStr=StringByKey("DRK",prot[6],"=",",")
//	if(cmpstr(drkStr,"none") != 0)
//		err = ReadHeaderAndData( (pathStr+drkStr) )
//		if(err)
//			PathInfo/S catPathName
//			Abort "reduction sequence aborted"
//		endif
//		err = V_Raw_to_Work_NoNorm("DRK")
//	endif

	//dispatch to the proper "mode" of Correct()
//	V_Dispatch_to_Correct(bgdStr,empStr,drkStr)
	V_Dispatch_to_Correct(prot[0],prot[1],prot[6])
	
	if(err)
		PathInfo/S catPathName
		SetDataFolder root:
		Abort "error in Correct, called from executeprotocol, normal cor"
	endif
	activeType = "COR"

// always update - COR will always be generated
	V_UpdateDisplayInformation(ActiveType)		


//////////////////////////////
//  ABSOLUTE SCALE
//////////////////////////////

	err = V_Proto_ABS_Scale(prot[4],activeType)
	
	if(err)
		SetDataFolder root:
		Abort "Error in V_Absolute_Scale(), called from V_ExecuteProtocol"
	endif
//	activeType = "ABS"


//////////////////////////////
// MASK
//////////////////////////////
//
// DONE
//		x- fill in the "ask" step
//  x- none is OK, except if the kill fails for any reason
// x- the regular case of the file name specified by the protocol works correctly
// x- don't create a null mask if not used, it will handle the error and print out that the mask is missing
//
//mask data if desired (mask is applied when the data is binned to I(q)) and is
//not done explicitly here
	
	//check for mask
	//doesn't change the activeType
	if(!skipLoad)

		V_Proto_ReadMask(prot[3])
	endif
	
//////////////////////////////
// AVERAGING
//////////////////////////////

	// average/save data as specified
	//Parse the keyword=<Value> string as needed, based on AVTYPE
	
	//average/plot first 
	String av_type = StringByKey("AVTYPE",prot[5],"=",";")
	If(cmpstr(av_type,"none") != 0)
		If (cmpstr(av_type,"")==0)		//if the key could not be found... (if "ask" the string)
			//get the averaging parameters from the user, as if the set button was hit in the panel
			V_SetAverageParamsButtonProc("dummy")		//from "ProtocolAsPanel"
			SVAR tempAveStr = root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr
			av_type = StringByKey("AVTYPE",tempAveStr,"=",";")
		else
			//there is info in the string, use the protocol
			//set the global keyword-string to prot[5]
			String/G root:Packages:NIST:VSANS:Globals:Protocols:gAvgInfoStr = prot[5]
		Endif
	Endif


	String detGroup = StringByKey("DETGROUP",prot[5],"=",";")		//only for annular, null if not present

	
//convert the folder to linear scale before averaging, then revert by calling the window hook
// (not needed for VSANS, data is always linear scale)

//
// (DONE)
// -x this generates a "Bin Type Not Found" error if reducing only to a 2D level (like for DIV)
//		because binTypeStr is null
	String binTypeStr = StringByKey("BINTYPE",prot[5],"=",";")
	// plotting is not really necessary, and the graph may not be open - so skip for now?
	Variable binType
	// only get the binning type if user asks for averaging
	If(cmpstr(av_type,"none") != 0)
		binType = V_BinTypeStr2Num(binTypeStr)
		if(binType == 0)
				Abort "Binning mode not found in V_QBinAllPanels() "// when no case matches
		endif
	endif


// identify the collimation type
// this will be a string used to determine how the resolution information is to be calculated
// and written to the reduced data file
//
// possible values are:
//
// pinhole
// pinhole_whiteBeam
// narrowSlit
// narrowSlit_whiteBeam
// convergingPinholes
//

	String collimationStr
	collimationStr = V_IdentifyCollimation(activeType)
	

////////////////////////////////////////
// DISPATCH TO AVERAGING
/////////////////////////////////////////
//
// TODO:
// -- do I calculate the proper resolution here?, YES, I've already decoded the binning type
//   and the averaging type has been specified by the protocol.
//
// so currently, the resolution is calculated every time that the data is averaged (in VC_fDoBinning_QxQy2D)
//
// -- if I calculate the resolution here, then the Trimming routines must be updated
//    to trim the resolution waves also. This will work for the columns present in
//    pinhole resolution, but anything using the matrix method - it won't work - and I'll need 
//    a different solution
//

	V_Proto_doAverage(prot[5],av_type,activeType,binType,collimationStr)



////////////////////////
// PLOT THE DATA
////////////////////////

	V_Proto_doPlot(prot[5],av_type,activeType,binType,detGroup)
	
	

////////////////////	
// SAVE THE DATA
////////////////////

// 
// x- how do I get the sample file name?
//    local variable samFileLoaded is the file name loaded (contains the extension)
//
// V_Proto_SaveFile(avgStr,activeType,samFileLoaded,av_type,binType,detGroup,trimBegStr,trimEndStr)

	prot[9] = collimationStr
	String outputFileName
	outputFileName = RemoveEnding(samStr,".nxs.ngv") + "_SL"+num2str(sliceNum)
	//? remove the "Events_" from the beginning? some other naming scheme entirely?
	
	V_Proto_SaveFile(prot[5],activeType,outputFileName,av_type,binType,detGroup,prot[7],prot[8])
	
//////////////////////////////
// DONE WITH THE PROTOCOL
//////////////////////////////	
	
	// reset any global preferences that I had changed
	gDoDIVCor = saved_gDoDIVCor
	
	
	Return(0)
End



