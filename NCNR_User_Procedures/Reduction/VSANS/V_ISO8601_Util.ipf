#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00

//
// The general format of the time string is:
//  1901-01-01T12:00:00-0500
// (note that the -0500 appears to be incorrect - should be -05:00
//
//   Complete date plus hours, minutes and seconds:
//      YYYY-MM-DDThh:mm:ssTZD (eg 1997-07-16T19:20:30+01:00)
//

// What utilities do I need to have to interpret these times?

// possible needs:
// Convert to "Igor" time? (as a number for computation)
// Find the elapsed time between two ISO times?
// Convert "Igor" time to ISO time? (as a string for writing)
//

// What does Igor have built-in to work with...?
//
// Unfortunately, there are functions based on the Julian calendar
// and the ISO standard uses the Gregorian calendar...
//
// print time()
//  10:53:42 AM
// print date()
//  Wed, Oct 7, 2015
// Print DateTime
//  3.52706e+09
// Print secs2date(DateTime,-2)
//  2015-10-07
// Print secs2time(DateTime,2)
//  10:55
// Print secs2time(DateTime,3)
//  10:55:50



// The two utilites are self-consistent, at least --
// passing in an ISO time returns itself atfer comupting the "Igor" seconds
//
// print CurrentTime_to_ISO8601String(ISO8601_to_IgorTime("2015-10-07T11:04:26-05:00"))
//

//
// Call w/ DateTime as the argument as V_CurrentTime_to_ISO8601String(DateTime)
//
// DONE -- verify that this is correct
Function/S V_CurrentTime_to_ISO8601String(now)
	Variable now
	
	String s1,s2,s3,ISOstr
	
	s3 = "-05:00"		// time zone string
	
	// Y-M-D
	s1 = secs2date(now,-2)
	//H:M:S
	s2 = secs2time(now,3)

	ISOstr = s1 + "T" + s2 + s3
	
	return(ISOstr)
End

//
// takes the ISO time and converts it into "Igor" time
// as if it was reported from DateTime:
//
// "The DateTime function returns number of seconds from 1/1/1904 to the current date and time."
//
// DONE -- verify that this is correct, since I'm not actually parsing the string, but rather
// counting on the string to be EXACTLY the correct format
//
Function V_ISO8601_to_IgorTime(ISOstr)
	String ISOstr
	
	Variable secs
	String s1,s2
	s1 = ISOstr[0,9] 		//taking strictly the first 10 characters YYYY-MM-DD
	s2 = ISOstr[11,18]		// skip the "T" and take the next 8 chars HH:MM:SS
	// skip the time zone...
//	print s1
//	print s2
	
	Variable yr,mo,dy,hh,mm,ss
	yr = str2num(s1[0,3])
	mo = str2num(s1[5,6])
	dy = str2num(s1[8,9])
	hh = str2num(s2[0,1])
	mm = str2num(s2[3,4])
	ss = str2num(s2[6,7])

	secs = date2secs(yr,mo,dy)
	secs += hh*60*60
	secs += mm*60
	secs += ss
	
	return(secs)
End


// utility to compare two iso dates
// returns
// 1 if iso1 is greater than iso2 (meaning iso1 is more RECENT)
// 2 if iso2 is greater than iso1 (meaning iso2 is more RECENT)
// 0 if they are the same time
//
//
Function V_Compare_ISO_Dates(iso1,iso2)
	String iso1,iso2
	
	if(V_ISO8601_to_IgorTime(iso1) == V_ISO8601_to_IgorTime(iso2))
		return(0)
	endif

	if(V_ISO8601_to_IgorTime(iso1) > V_ISO8601_to_IgorTime(iso2))
		return(1)
	else
		return(2)
	endif
	
	return(-1)
End

