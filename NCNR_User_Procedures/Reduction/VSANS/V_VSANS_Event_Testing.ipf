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
Structure eventWord
	uchar eventTime[6]
	uchar location
	uchar tube
endStructure



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

s_tic()
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

s_toc()
		
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

s_tic()

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
s_toc()	
	
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


