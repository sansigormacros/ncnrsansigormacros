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
	
	b1 = 47
	b2 = 123
	i64_ticks = 123456789


	b2 = b2 << 48
	b1 = b1 << 56
	
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
	
	b1 = (val >> 56 ) & 0xFF			// = 255, last byte, after shifting
	b2 = (val >> 48 ) & 0xFF
	
	btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes
	
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
Function V_MakeFakeEventWave()

	Variable num,ii


	num = 1e3
	
//	// /l=64 bit, /U=unsigned
	Make/O/L/U/N=(num) eventWave
	eventWave = 0
	
	// for each 64-bit value:
	// byte 1: tube index [0,191]
	// byte 2: pixel value [0,127]
	// bytes 3-8 (= 6 bytes): time stamp in resolution unit
	
	uint64 i64_num,b1,b2,b3,b4,b5,b6,b7,b8
	uint64 i64_ticks,i64_start
	
	i64_start = ticks
	for(ii=0;ii<num;ii+=1)
//		sleep/T/C=-1 1			// 6 ticks, approx 0.1 s (without the delay, the loop is too fast)
		b1 = trunc(abs(enoise(192)))		//since truncated, need 192 as highest random to give 191 after trunc
		b2 = trunc(abs(enoise(128)))		// same here, to get results [0,127]
		
//		i64_ticks = ticks-i64_start
		i64_ticks = ii+1
		
		b2 = b2 << 48
		b1 = b1 << 56
	
		i64_num = b1+b2+i64_ticks
		eventWave[ii] = i64_num
	endfor


	return(0)
End


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
	
	for(ii=0;ii<num;ii+=1)
		val = w[ii]
		
		b1 = (val >> 56 ) & 0xFF			// = 255, last two bytes, after shifting
		b2 = (val >> 48 ) & 0xFF
	
		btime = val & 0xFFFFFFFFFFFF	// = really big number, last 6 bytes

		tube[ii] = b1
		location[ii] = b2
		eventTime[ii] = btime
		
	endfor

s_toc()
		
	return(0)
End


Function V_writeFakeEventFile(fname)
	String fname

	WAVE w = eventWave
	Variable refnum
	
	String vsansStr="VSANS"
	Variable revision = 11
	Variable offset = 22		// no disabled tubes
	Variable time1 = 2017
	Variable time2 = 0525
	Variable time3 = 1122
	Variable time4 = 3344		// these 4 time pieces are supposed to be 8 bytes total
	String detStr = "M"
	Variable volt = 1500
	Variable resol = 1000
	
	
	Open refnum as fname

	FBinWrite refnum, vsansStr
	FBinWrite/F=2/U refnum, revision
	FBinWrite/F=2/U refnum, offset
	FBinWrite/F=2/U refnum, time1
	FBinWrite/F=2/U refnum, time2
	FBinWrite/F=2/U refnum, time3
	FBinWrite/F=2/U refnum, time4
	FBinWrite refnum, detStr
	FBinWrite/F=2/U refnum, volt
	FBinWrite/F=2/U refnum, resol

	FGetPos refnum 
	Print V_filePos
	
	FBinWrite refnum, w
	
	close refnum
	
	return(0)
End

//
// use GBLoadWave to do the reading, then I can do the decoding
//
Function V_readFakeEventFile()

	String fname
// this reads in uint64 data, to a unit64 wave, skipping 22 bytes	
//	GBLoadWave/B/T={192,192}/W=1/S=22
	Variable num,refnum
	

// so to read:
//
// - get the file name
//	- read the header (all of it, since I need parts of it) (maybe read as a struct? but I don't know the size!)
// - move to EOF and close
//
// - Use GBLoadWave to read it in

	String vsansStr=""
	Variable revision
	Variable offset		// no disabled tubes
	Variable time1
	Variable time2
	Variable time3
	Variable time4		// these 4 time pieces are supposed to be 8 bytes total
	String detStr=""
	Variable volt
	Variable resol

	vsansStr = PadString(vsansStr,5,0x20)		//pad to 5 bytes
	detStr = PadString(detStr,1,0x20)				//pad to 1 byte

	Open/R refnum 
	fname = S_fileName

s_tic()

	FBinRead refnum, vsansStr
	FBinRead/F=2/U refnum, revision
	FBinRead/F=2/U refnum, offset
	FBinRead/F=2/U refnum, time1
	FBinRead/F=2/U refnum, time2
	FBinRead/F=2/U refnum, time3
	FBinRead/F=2/U refnum, time4
	FBinRead refnum, detStr
	FBinRead/F=2/U refnum, volt
	FBinRead/F=2/U refnum, resol

	FStatus refnum
	FSetPos refnum, V_logEOF
	
	Close refnum
	
// number of data bytes
	num = V_logEOF-offset
	Print num/8
	
	GBLoadWave/B/T={192,192}/W=1/S=22 fname
	
	Duplicate/O $(StringFromList(0,S_waveNames)) V_Events
	KillWaves/Z $(StringFromList(0,S_waveNames))
s_toc()	
	
	return(0)
End

//
// tested up to num=1e8 successfully
//
Function V_MakeFakeEventWave_TOF()

	Variable num,ii,jj,delayTime,numRepeat,std


	num = 1000
	numRepeat = 100
	
	delayTime = 30		//microseconds
	std = 5					//std deviation, microseconds
	
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
			
			b2 = b2 << 48
			b1 = b1 << 56
		
			i64_num = b1+b2+i64_ticks
			eventWave[jj*num+ii] = i64_num
		endfor
		
	endfor

	return(0)
End
