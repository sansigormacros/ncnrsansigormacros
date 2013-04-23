#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// this file contains globals and functions that are specific to a
// particular facility or data file format
// branched out 29MAR07 - SRK
//
// functions are either labeled with the procedure file that calls them,
// or noted that they are local to this file


// initializes globals that are specific to a particular facility
// - number of XY pixels
// - pixexl resolution [cm]
// - detector deadtime constant [s]
//
// called by Initialize.ipf
//
Function InitFacilityGlobals()

	//Detector -specific globals
	Variable/G root:myGlobals:gNPixelsX=128
	Variable/G root:myGlobals:gNPixelsY=128
	
	// as of Jan2008, detector pixel sizes are read directly from the file header, so they MUST
	// be set correctly in instr.cfg
	Variable/G root:myGlobals:PixelResNG3_ILL = 1.0		//pixel resolution in cm
	Variable/G root:myGlobals:PixelResNG5_ILL = 1.0
	Variable/G root:myGlobals:PixelResNG7_ILL = 1.0
	Variable/G root:myGlobals:PixelResNG3_ORNL = 0.5
	Variable/G root:myGlobals:PixelResNG5_ORNL = 0.5
	Variable/G root:myGlobals:PixelResNG7_ORNL = 0.5
	Variable/G root:myGlobals:PixelResDefault = 0.5
	
	Variable/G root:myGlobals:DeadtimeNG3_ILL = 3.0e-6		//deadtime in seconds
	Variable/G root:myGlobals:DeadtimeNG5_ILL = 3.0e-6
	Variable/G root:myGlobals:DeadtimeNG7_ILL = 3.0e-6
	Variable/G root:myGlobals:DeadtimeNG3_ORNL = 3.4e-6
	Variable/G root:myGlobals:DeadtimeNG5_ORNL = 0.6e-6		//as of 9 MAY 2002
	Variable/G root:myGlobals:DeadtimeNG7_ORNL = 3.4e-6
	Variable/G root:myGlobals:DeadtimeDefault = 3.4e-6
	
	//new 11APR07
	Variable/G root:myGlobals:BeamstopXTol = -8			// (cm) is BS Xpos is -5 cm or less, it's a trans measurement
	// sample aperture offset is NOT stored in the VAX header, but it should be
	// - when it is, remove the global and write an accessor AND make a place for 
	// it in the RealsRead 
	Variable/G root:myGlobals:apOff = 5.0				// (cm) distance from sample aperture to sample position

End


//**********************
// Resolution calculation - used by the averaging routines
// to calculate the resolution function at each q-value
// - the return value is not used
//
// equivalent to John's routine on the VAX Q_SIGMA_AVE.FOR
// Incorporates eqn. 3-15 from J. Appl. Cryst. (1995) v. 28 p105-114
//
// - 21 MAR 07 uses projected BS diameter on the detector
// - APR 07 still need to add resolution with lenses. currently there is no flag in the 
//          raw data header to indicate the presence of lenses.
//
// - Aug 07 - added input to switch calculation based on lenses (==1 if in)
//
// - called by CircSectAvg.ipf and RectAnnulAvg.ipf
//
// passed values are read from RealsRead
// except DDet and apOff, which are set from globals before passing
//
//
Function/S getResolution(inQ,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,SigmaQ,QBar,fSubS)
	Variable inQ, lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses
	Variable &fSubS, &QBar, &SigmaQ		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, q_small, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]

	String results
	results ="Failure"

	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]
	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
	Variable LB
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	q_small = 2.0*Pi*(BS-a2)*(1.0-lambdaWidth)/(lambda*L2)
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
//	if(usingLenses==1)			//SRK 2007
	if(usingLenses != 0)			//SRK 2008 allows for the possibility of different numbers of lenses in header
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007

	r0 = L2*tan(2.0*asin(lambda*inQ/(4.0*Pi) ))
	delta = 0.5*(BS - r0)^2/v_d

	if (r0 < BS) 
		inc_gamma=exp(gammln(1.5))*(1-gammp(1.5,delta))
	else
		inc_gamma=exp(gammln(1.5))*(1+gammp(1.5,delta))
	endif

	fSubS = 0.5*(1.0+erf( (r0-BS)/sqrt(2.0*v_d) ) )
	if (fSubS <= 0.0) 
		fSubS = 1.e-10
	endif
	fr = 1.0 + sqrt(v_d)*exp(-1.0*delta) /(r0*fSubS*sqrt(2.0*Pi))
	fv = inc_gamma/(fSubS*sqrt(Pi)) - r0^2*(fr-1.0)^2/v_d

	rmd = fr*r0
	v_r1 = v_b + fv*v_d +v_g

	rm = rmd + 0.5*v_r1/rmd
	v_r = v_r1 - 0.5*(v_r1/rmd)^2
	if (v_r < 0.0) 
		v_r = 0.0
	endif
	QBar = (4.0*Pi/lambda)*sin(0.5*atan(rm/L2))
	SigmaQ = QBar*sqrt(v_r/rmd^2 +v_lambda)

	results = "success"
	Return results
End


//
//**********************
// 2D resolution function calculation - ***NOT*** in terms of X and Y
// but written in terms of Parallel and perpendicular to the Q vector at each point
//
// -- it must be written this way since the 2D function is an ellipse with its major
// axis pointing in the direction of Q_parallel. Hence there is no way to properly define the 
// elliptical gaussian in terms of sigmaX and sigmaY
//
// based on notes from David Mildner, 2008
//
//
// - 21 MAR 07 uses projected BS diameter on the detector
// - APR 07 still need to add resolution with lenses. currently there is no flag in the 
//          raw data header to indicate the presence of lenses.
//
// - Aug 07 - added input to switch calculation based on lenses (==1 if in)
//
// passed values are read from RealsRead
// except DDet and apOff, which are set from globals before passing
//
// phi is the azimuthal angle, CCW from +x axis
// r_dist is the real-space distance from ctr of detector to QxQy pixel location
//
Function/S get2DResolution(inQ,phi,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,r_dist,SigmaQX,SigmaQY,fSubS)
	Variable inQ, phi,lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses,r_dist
	Variable &SigmaQX,&SigmaQY,&fSubS		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]
	Variable m_h	= 252.8			// m/h [=] s/cm^2

	String results
	results ="Failure"

	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]
	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
	Variable LB
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
//	if(usingLenses==1)			//SRK 2007
	if(usingLenses != 0)			//SRK 2008 allows for the possibility of different numbers of lenses in header
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007

	r0 = L2*tan(2.0*asin(lambda*inQ/(4.0*Pi) ))
	delta = 0.5*(BS - r0)^2/v_d

	if (r0 < BS) 
		inc_gamma=exp(gammln(1.5))*(1-gammp(1.5,delta))
	else
		inc_gamma=exp(gammln(1.5))*(1+gammp(1.5,delta))
	endif

	fSubS = 0.5*(1.0+erf( (r0-BS)/sqrt(2.0*v_d) ) )
	if (fSubS <= 0.0) 
		fSubS = 1.e-10
	endif
//	fr = 1.0 + sqrt(v_d)*exp(-1.0*delta) /(r0*fSubS*sqrt(2.0*Pi))
//	fv = inc_gamma/(fSubS*sqrt(Pi)) - r0^2*(fr-1.0)^2/v_d
//
//	rmd = fr*r0
//	v_r1 = v_b + fv*v_d +v_g
//
//	rm = rmd + 0.5*v_r1/rmd
//	v_r = v_r1 - 0.5*(v_r1/rmd)^2
//	if (v_r < 0.0) 
//		v_r = 0.0
//	endif

	Variable kap,a_val,a_val_L2
	
	kap = 2*pi/lambda
	a_val = L2*(L1+L2)*g/2*(m_h)^2
	a_val_L2 = a_val/L2*1e-16		//convert 1/cm^2 to 1/A^2


///////// in terms of Q_parallel ("x") and Q_perp ("y") - this works, since parallel is in the direction of Q and I
// can calculate that from the QxQy (I just need the projection)


// for test case with no gravity, set a_val = 0
// note that gravity has no wavelength dependence. the lambda^4 cancels out.
//
//	a_val = 0

	// the detector pixel is square, so correct for phi
	DDet = DDet*cos(phi) + DDet*sin(phi)
	
	// this is really sigma_Q_parallel
	SigmaQX = kap*kap/12* (3*(S1/L1)^2 + 3*(S2/LP)^2 + (DDet/L2)^2 + (del_r/L2)^2 + (sin(phi))^2*8*(a_val_L2)^2*lambda^4*lambdaWidth^2)
	SigmaQX += inQ*inQ*v_lambda

	//this is really sigma_Q_perpendicular
	SigmaQY = 3*(S1/L1)^2 + 3*(S2/LP)^2 + (DDet/L2)^2 + (del_r/L2)^2 + (cos(phi))^2*8*(a_val_L2)^2*lambda^4*lambdaWidth^2
	SigmaQY *= kap*kap/12
	
	SigmaQX = sqrt(SigmaQX)
	SigmaQy = sqrt(SigmaQY)
	
	
	results = "success"
	Return results
End




//Utility function that returns the detector resolution (in cm)
//Global values are set in the Initialize procedure
//
//
// - called by CircSectAvg.ipf, RectAnnulAvg.ipf, and ProtocolAsPanel.ipf
//
// fileStr is passed as TextRead[3]
// detStr is passed as TextRead[9]
//
// *** as of Jan 2008, depricated. Now detector pixel sizes are read from the file header
// rw[10] = x size (mm); rw[13] = y size (mm)
//
Function xDetectorPixelResolution(fileStr,detStr)
	String fileStr,detStr
	
	Variable DDet
	String instr=fileStr[1,3]	//filestr is "[NGnSANSn] " or "[NGnSANSnn]" (11 characters total)
	
	NVAR PixelResNG3_ILL = root:myGlobals:PixelResNG3_ILL		//pixel resolution in cm
	NVAR PixelResNG5_ILL = root:myGlobals:PixelResNG5_ILL
	NVAR PixelResNG7_ILL = root:myGlobals:PixelResNG7_ILL
	NVAR PixelResNG3_ORNL = root:myGlobals:PixelResNG3_ORNL
	NVAR PixelResNG5_ORNL = root:myGlobals:PixelResNG5_ORNL
	NVAR PixelResNG7_ORNL = root:myGlobals:PixelResNG7_ORNL
	NVAR PixelResDefault = root:myGlobals:PixelResDefault
	
	strswitch(instr)
		case "NG3":
			if(cmpstr(detStr, "ILL   ") == 0 )
				DDet= PixelResNG3_ILL
			else
				DDet = PixelResNG3_ORNL	//detector is ordella-type
			endif
			break
		case "NG5":
			if(cmpstr(detStr, "ILL   ") == 0 )
				DDet= PixelResNG5_ILL
			else
				DDet = PixelResNG5_ORNL	//detector is ordella-type
			endif
			break
		case "NG7":
			if(cmpstr(detStr, "ILL   ") == 0 )
				DDet= PixelResNG7_ILL
			else
				DDet = PixelResNG7_ORNL	//detector is ordella-type
			endif
			break
		default:							
			//return error?
			DDet = PixelResDefault	//0.5 cm, typical for new ORNL detectors
	endswitch
	
	return(DDet)
End

//Utility function that returns the detector deadtime (in seconds)
//Global values are set in the Initialize procedure
//
// - called by WorkFileUtils.ipf
//
// fileStr is passed as TextRead[3]
// detStr is passed as TextRead[9]
//
Function DetectorDeadtime(fileStr,detStr)
	String fileStr,detStr
	
	Variable deadtime
	String instr=fileStr[1,3]	//filestr is "[NGnSANSn] " or "[NGnSANSnn]" (11 characters total)
	
	NVAR DeadtimeNG3_ILL = root:myGlobals:DeadtimeNG3_ILL		//pixel resolution in cm
	NVAR DeadtimeNG5_ILL = root:myGlobals:DeadtimeNG5_ILL
	NVAR DeadtimeNG7_ILL = root:myGlobals:DeadtimeNG7_ILL
	NVAR DeadtimeNG3_ORNL = root:myGlobals:DeadtimeNG3_ORNL
	NVAR DeadtimeNG5_ORNL = root:myGlobals:DeadtimeNG5_ORNL
	NVAR DeadtimeNG7_ORNL = root:myGlobals:DeadtimeNG7_ORNL
	NVAR DeadtimeDefault = root:myGlobals:DeadtimeDefault
	
	strswitch(instr)
		case "NG3":
			if(cmpstr(detStr, "ILL   ") == 0 )
				deadtime= DeadtimeNG3_ILL
			else
				deadtime = DeadtimeNG3_ORNL	//detector is ordella-type
			endif
			break
		case "NG5":
			if(cmpstr(detStr, "ILL   ") == 0 )
				deadtime= DeadtimeNG5_ILL
			else
				deadtime = DeadtimeNG5_ORNL	//detector is ordella-type
			endif
			break
		case "NG7":
			if(cmpstr(detStr, "ILL   ") == 0 )
				deadtime= DeadtimeNG7_ILL
			else
				deadtime = DeadtimeNG7_ORNL	//detector is ordella-type
			endif
			break
		default:							
			//return error?
			deadtime = DeadtimeDefault	//1e-6 seconds, typical for new ORNL detectors
	endswitch
	
	return(deadtime)
End

//make a three character string of the run number
//Moved to facility utils
Function/S RunDigitString(num)
	Variable num
	
	String numStr=""
	if(num<10)
		numStr = "00"+num2str(num)
	else
		if(num<100)
			numStr = "0"+num2str(num)
		else
			numStr = num2str(num)
		Endif
	Endif
	//Print "numstr = ",numstr
	return(numstr)
End

//given a filename of a SANS data filename of the form
//TTTTTnnn.SAn_TTT_Txxx
//returns the prefix "TTTTT" as some number of characters
//returns "" as an invalid file prefix
//
// NCNR-specifc, does not really belong here - but it's a beta procedure used for the
// Combine Files Panel
//
Function/S GetPrefixStrFromFile(item)
	String item
	String invalid = ""	//"" is not a valid run prefix, since it's text
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, skip the three characters preceeding it
		if (pos <=3)
			//not enough characters
			return (invalid)
		else
			runStr = item[0,pos-4]
			return (runStr)
		Endif
	Endif
End




/////VAX filename/Run number parsing utilities
//
// a collection of uilities for processing vax filenames
//and processing lists (especially for display in popup menus)
//
//required to correctly account for VAX supplied version numbers, which
//may or may not be removed by the ftp utility
//
// - parses lists of run numbers into real filenames
// - selects proper detector constants
//
//**************************
//
//given a filename of a SANS data filename of the form
//TTTTTnnn.SAn_TTT_Txxx
//returns the run number "nnn" as a number
//returns -1 as an invalid file number
//
// called by several ipfs
//
//
Function GetRunNumFromFile(item)
	String item
	Variable invalid = -1	//negative numbers are invalid
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get the three characters preceeding it
		if (pos <=2)
			//not enough characters
			return (invalid)
		else
			runStr = item[pos-3,pos-1]
			//convert to a number
			num = str2num(runStr)
			//if valid, return it
			if (num == NaN)
				//3 characters were not a number
				return (invalid)
			else
				//run was OK
				return (num)
			Endif
		Endif
	Endif
End

//given a filename of a SANS data filename of the form
//TTTTTnnn.SAn_TTT_Txxx
//returns the run number "nnn" as a STRING of THREE characters
//returns "ABC" as an invalid file number
//
// local function to aid in locating files by run number
//
Function/S GetRunNumStrFromFile(item)
	String item
	String invalid = "ABC"	//"ABC" is not a valid run number, since it's text
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get the three characters preceeding it
		if (pos <=2)
			//not enough characters
			return (invalid)
		else
			runStr = item[pos-3,pos-1]
			return (runStr)
		Endif
	Endif
End

//returns a string containing the full path to the file containing the 
//run number "num". The null string is returned if no valid file can be found
//the path "catPathName" used and is hard-wired, will abort if this path does not exist
//the file returned will be a RAW SANS data file, other types of files are 
//filtered out.
//
// called by Buttons.ipf and Transmission.ipf, and locally by parsing routines
//
Function/S FindFileFromRunNumber(num)
	Variable num
	
	String fullName="",partialName="",item=""
	//get list of raw data files in folder that match "num" (add leading zeros)
	if( (num>999) || (num<=0) )
		//Print "error in  FindFileFromRunNumber(num), file number too large or too small"
		Return ("")
	Endif
	//make a three character string of the run number
	String numStr=""
	if(num<10)
		numStr = "00"+num2str(num)
	else
		if(num<100)
			numStr = "0"+num2str(num)
		else
			numStr = num2str(num)
		Endif
	Endif
	//Print "numstr = ",numstr
	
	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	String list="",newList="",testStr=""
	
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	//find (the) one with the number in the run # location in the name
	Variable numItems,ii,runFound,isRAW
	numItems = ItemsInList(list,";")		//get the new number of items in the list
	ii=0
	do
		//parse through the list in this order:
		// 1 - does item contain run number (as a string) "TTTTTnnn.SAn_XXX_Tyyy"
		// 2 - exclude by isRaw? (to minimize disk access)
		item = StringFromList(ii, list  ,";" )
		if(strlen(item) != 0)
			//find the run number, if it exists as a three character string
			testStr = GetRunNumStrFromFile(item)
			runFound= cmpstr(numStr,testStr)	//compare the three character strings, 0 if equal
			if(runFound == 0)
				//the run Number was found
				//build valid filename
				partialName = FindValidFileName(item)
				if(strlen(partialName) != 0)		//non-null return from FindValidFileName()
					fullName = path + partialName
					//check if RAW, if so,this must be the file!
					isRAW = CheckIfRawData(fullName)
					if(isRaw)
						//stop here
						return(fullname)
					Endif
				Endif
			Endif
		Endif
		ii+=1
	while(ii<numItems)		//process all items in list
	Return ("")	//null return if file not found in list
End

//function to test a binary file to see if it is a RAW binary SANS file
//first checks the total bytes in the file (which for raw data is 33316 bytes)
//**note that the "DIV" file will also show up as a raw file by the run field
//should be listed in CAT/SHORT and in patch windows
//
//Function then checks the file fname (full path:file) for "RAW" run.type field
//if not found, the data is not raw data and zero is returned
//
// called by many procedures (both external and local)
//
Function CheckIfRawData(fname)
	String fname
	
	Variable refnum,totalBytes
	String testStr=""
	
	Open/R/T="????TEXT" refNum as fname
	if(strlen(s_filename) == 0)	//user cancel (/Z not used, so V_flag not set)
		return(0)
	endif
	
	//get the total number of bytes in the file
	FStatus refNum
	totalBytes = V_logEOF
	//Print totalBytes
	if(totalBytes < 100)
		Close refNum
		return(0)		//not a raw file
	endif
	FSetPos refNum,75
	FReadLine/N=3 refNum,testStr
	Close refNum
	
	if(totalBytes == 33316 && ( cmpstr(testStr,"RAW")==0 ||  cmpstr(testStr,"SIM")==0))
		//true, is raw data file
		Return(1)
	else
		//some other file
		Return(0)
	Endif
End

//function to check the header of a raw data file (full path specified by fname)
//checks the field of the x-position of the beamstop during data collection
//if the x-position is more negative (farther to the left) than xTol(input)
//the the beamstop is "out" and the file is a transmission run and not a scattering run
//xtol typically set at -5 (cm) - trans runs have bs(x) at -10 to -15 cm 
// function returns 1 if beamstop is out, 0 if beamstop is in
//
// tolerance is set as a global value "root:myGlobals:BeamstopXTol"
//
// called by Transmission.ipf, CatVSTable.ipf, NSORT.ipf
//
Function isTransFile(fName)
	String fname
	
	Variable refnum,xpos
	NVAR xTol = root:myGlobals:BeamstopXTol
	
	//pos = 369, read one real value
	
	SetDataFolder root:
	String GBLoadStr="GBLoadWave/O/N=tempGBwave/T={2,2}/J=2/W=1/Q"
	String strToExecute=""
	// 1 R*4 value
	strToExecute = GBLoadStr + "/S=368/U=1" + "\"" + fname + "\""
	Execute strToExecute
	Wave w=$"root:tempGBWave0"
	xPos = w[0]
	KillWaves/Z w
	//Print "xPos = ",xpos
	
	if(xpos<=xTol)
		//xpos is farther left (more negative) than xtol (currently -5 cm)
		Return(1)
	else
		//some other file
		Return(0)
	Endif
End


//function to remove all spaces from names when searching for filenames
//the filename (as saved) will never have interior spaces (TTTTTnnn_AB _Bnnn)
//but the text field in the header WILL, if less than 3 characters were used for the 
//user's initials, and can have leading spaces if prefix was less than 5 characters
//
//returns a string identical to the original string, except with the interior spaces removed
//
// local function for file name manipulation
//
Function/S RemoveAllSpaces(str)
	String str
	
	String tempstr = str
	Variable ii,spc,len		//should never be more than 2 or 3 trailing spaces in a filename
	ii=0
	do
		len = strlen(tempStr)
		spc = strsearch(tempStr," ",0)		//is the last character a space?
		if (spc == -1)
			break		//no more spaces found, get out
		endif
		str = tempstr
		tempStr = str[0,(spc-1)] + str[(spc+1),(len-1)]	//remove the space from the string
	While(1)	//should never be more than 2 or 3
	
	If(strlen(tempStr) < 1)
		tempStr = ""		//be sure to return a null string if problem found
	Endif
	
	//Print strlen(tempstr)
	
	Return(tempStr)
		
End


//Function attempts to find valid filename from partial name by checking for
// the existence of the file on disk.
// - checks as is
// - adds ";vers" for possible VAX files
// - strips spaces
// - permutations of upper/lowercase
//
// added 11/99 - uppercase and lowercase versions of the file are tried, if necessary
// since from marquee, the filename field (textread[0]) must be used, and can be a mix of
// upper/lowercase letters, while the filename on the server (should) be all caps
// now makes repeated calls to ValidFileString()
//
// returns a valid filename (No path prepended) or a null string
//
// called by any functions, both external and local
//
Function/S FindValidFilename(partialName)
	String PartialName
	
	String retStr=""
	
	//try name with no changes - to allow for ABS files that have spaces in the names 12APR04
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//if the partial name is derived from the file header, there can be spaces at the beginning
	//or in the middle of the filename - depending on the prefix and initials used
	//
	//remove any leading spaces from the name before starting
	partialName = RemoveAllSpaces(partialName)
	
	//try name with no spaces
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all UPPERCASE
	partialName = UpperStr(partialName)
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	Endif
	
	//try all lowercase (ret null if failure)
	partialName = LowerStr(partialName)
	retStr = ValidFileString(partialName)
	if(cmpstr(retStr,"") !=0)
		//non-null return
		return(retStr)
	else
		return(retStr)
	Endif
End

// Function checks for the existence of a file
// partialName;vers (to account for VAX filenaming conventions)
// The partial name is tried first with no version number
//
// *** the PATH is hard-wired to catPathName (which is assumed to exist)
// version numers up to ;10 are tried
// only the "name;vers" is returned if successful. The path is not prepended
//
// local function
//
Function/S ValidFileString(partialName)
	String partialName
	
	String tempName = "",msg=""
	Variable ii,refnum
	
	ii=0
	do
		if(ii==0)
			//first pass, try the partialName
			tempName = partialName
			Open/Z/R/T="????TEXT"/P=catPathName refnum tempName	//Does open file (/Z flag)
			if(V_flag == 0)
				//file exists
				Close refnum		//YES needed, 
				break
			endif
		else
			tempName = partialName + ";" + num2str(ii)
			Open/Z/R/T="????TEXT"/P=catPathName refnum tempName
			if(V_flag == 0)
				//file exists
				Close refnum
				break
			endif
		Endif
		ii+=1
		//print "ii=",ii
	while(ii<11)
	//go get the selected bits of information, using tempName, which exists
	if(ii>=11)
		//msg = partialName + " not found. is version number > 11?"
		//DoAlert 0, msg
		//PathInfo catPathName
		//Print S_Path
		Return ("")		//use null string as error condition
	Endif
	
	Return (tempName)
End

//returns a string containing filename (WITHOUT the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// called by MaskUtils.ipf, ProtocolAsPanel.ipf, WriteQIS.ipf
//
Function/S GetFileNameFromPathNoSemi(fullPath)
	String fullPath
	
	Variable offset1,offset2
	String filename=""
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			fileName = FullPath[offset1,strlen(FullPath) ]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	//remove version number from name, if it's there - format should be: filename;N
	filename =  StringFromList(0,filename,";")		//returns null if error
	
	Return filename
End

//returns a string containing filename (INCLUDING the ;vers)
//the input string is a full path to the file (Mac-style, still works on Win in IGOR)
//with the folders separated by colons
//
// local, currently unused
//
Function/S GetFileNameFromPathKeepSemi(fullPath)
	String fullPath
	
	Variable offset1,offset2
	String filename
	//String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			fileName = FullPath[offset1,strlen(FullPath) ]
			//PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	//keep version number from name, if it's there - format should be: filename;N
	
	Return filename
End

//given the full path and filename (fullPath), strips the data path
//(Mac-style, separated by colons) and returns this path
//this partial path is the same string that would be returned from PathInfo, for example
//
// - allows the user to save to a different path than catPathName
//
// called by WriteQIS.ipf
//
Function/S GetPathStrFromfullName(fullPath)
	String fullPath
	
	Variable offset1,offset2
	//String filename
	String PartialPath
	offset1 = 0
	do
		offset2 = StrSearch(fullPath, ":", offset1)
		if (offset2 == -1)				// no more colons ?
			//fileName = FullPath[offset1,strlen(FullPath) ]
			PartialPath = FullPath[0, offset1-1]
			break
		endif
		offset1 = offset2+1
	while (1)
	
	Return PartialPath
End

//given the VAX filename, pull off the first 8 characters to make a valid
//file string that can be used for naming averaged 1-d files
//
// called by ProtocolAsPanel.ipf and Tile_2D.ipf
//
Function/S GetNameFromHeader(fullName)
	String fullName
	String temp, newName = ""
	Variable spc,ii=0
	
	//filename is 20 characters NNNNNxxx.SAn_NNN_NNN
	//want the first 8 characters, NNNNNxxx, then strip off any spaces at the beginning
	//NNNNN was entered as less than 5 characters
	//returns a null string if no name can be found
	do
		temp = fullname[ii,7]		//characters ii,7 of the name
		spc = strsearch(temp," ",0)
		if (spc == -1)
			break		//no more spaces found
		endif
		ii+=1
	While(ii<8)
	
	If(strlen(temp) < 1)
		newName = ""		//be sure to return a null string if problem found
	else
		newName = temp
	Endif
	
	Return(newName)
End

//list (input) is a list, typically returned from IndexedFile()
//which is semicolon-delimited, and may contain filenames from the VAX
//that contain version numbers, where the version number appears as a separate list item
//(and also as a non-existent file)
//these numbers must be purged from the list, especially for display in a popup
//or list processing of filenames
//the function returns the list, cleaned of version numbers (up to 11)
//raw data files will typically never have a version number other than 1.
//
// if there are no version numbers in the list, the input list is returned
//
// called by CatVSTable.ipf, NSORT.ipf, Transmission.ipf, WorkFileUtils.ipf 
//
Function/S RemoveVersNumsFromList(list)
	String list
	
	//get rid of version numbers first (up to 11)
	Variable ii,num
	String item 
	num = ItemsInList(list,";")
	ii=1
	do
		item = num2str(ii)
		list = RemoveFromList(item, list ,";" )
		ii+=1
	while(ii<12)
	
	return (list)
End

//input is a list of run numbers, and output is a list of filenames (not the full path)
//*** input list must be COMMA delimited***
//output is equivalent to selecting from the CAT table
//if some or all of the list items are valid filenames, keep them...
//if an error is encountered, notify of the offending element and return a null list
//
//output is COMMA delimited
//
// this routine is expecting that the "ask", "none" special cases are handled elsewhere
//and not passed here
//
// called by Marquee.ipf, MultipleReduce.ipf, ProtocolAsPanel.ipf
//
Function/S ParseRunNumberList(list)
	String list
	
	String newList="",item="",tempStr=""
	Variable num,ii,runNum
	
	//expand number ranges, if any
	list = ExpandNumRanges(list)
	
	num=itemsinlist(list,",")
	
	for(ii=0;ii<num;ii+=1)
		//get the item
		item = StringFromList(ii,list,",")
		//is it already a valid filename?
		tempStr=FindValidFilename(item) //returns filename if good, null if error
		if(strlen(tempstr)!=0)
			//valid name, add to list
			//Print "it's a file"
			newList += tempStr + ","
		else
			//not a valid name
			//is it a number?
			runNum=str2num(item)
			//print runnum
			if(numtype(runNum) != 0)
				//not a number -  maybe an error			
				DoAlert 0,"List item "+item+" is not a valid run number or filename. Please enter a valid number or filename."
				return("")
			else
				//a run number or an error
				tempStr = GetFileNameFromPathNoSemi( FindFileFromRunNumber(runNum) )
				if(strlen(tempstr)==0)
					//file not found, error
					DoAlert 0,"List item "+item+" is not a valid run number. Please enter a valid number."
					return("")
				else
					newList += tempStr + ","
				endif
			endif
		endif
	endfor		//loop over all items in list
	
	return(newList)
End

//takes a comma delimited list that MAY contain number range, and
//expands any range of run numbers into a comma-delimited list...
//and returns the new list - if not a range, return unchanged
//
// local function
//
Function/S ExpandNumRanges(list)
	String list
	
	String newList="",dash="-",item,str
	Variable num,ii,hasDash
	
	num=itemsinlist(list,",")
//	print num
	for(ii=0;ii<num;ii+=1)
		//get the item
		item = StringFromList(ii,list,",")
		//does it contain a dash?
		hasDash = strsearch(item,dash,0)		//-1 if no dash found
		if(hasDash == -1)
			//not a range, keep it in the list
			newList += item + ","
		else
			//has a dash (so it's a range), expand (or add null)
			newList += ListFromDash(item)		
		endif
	endfor
	
	return newList
End

//be sure to add a trailing comma to the return string...
//
// local function
//
Function/S ListFromDash(item)
	String item
	
	String numList="",loStr="",hiStr=""
	Variable lo,hi,ii
	
	loStr=StringFromList(0,item,"-")	//treat the range as a list
	hiStr=StringFromList(1,item,"-")
	lo=str2num(loStr)
	hi=str2num(hiStr)
	if( (numtype(lo) != 0) || (numtype(hi) !=0 ) || (lo > hi) )
		numList=""
		return numList
	endif
	for(ii=lo;ii<=hi;ii+=1)
		numList += num2str(ii) + ","
	endfor
	
	Return numList
End


////////Transmission
//******************
//lookup tables for attenuator transmissions
//NG3 and NG7 attenuators are physically different, so the transmissions are slightly different
//NG1 - (8m SANS) is not supported
//
// new calibration done June 2007, John Barker
//
Proc MakeNG3AttenTable()

	NewDataFolder/O root:myGlobals:Attenuators
	//do explicitly to avoid data folder problems, redundant, but it must work without fail
	Variable num=10		//10 needed for tables after June 2007

	Make/O/N=(num) root:myGlobals:Attenuators:ng3att0
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att1
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att2
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att3
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att4
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att5
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att6
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att7
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att8
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att9
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att10
	
	//each wave has 10 elements, the transmission of att# at the wavelengths 
	//lambda = 4,5,6,7,8,10,12,14,17,20 (4 A and 20 A are extrapolated values)
	Make/O/N=(num) root:myGlobals:Attenuators:ng3lambda={4,5,6,7,8,10,12,14,17,20}
	
	// new calibration done June 2007, John Barker
	root:myGlobals:Attenuators:ng3att0 = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
	root:myGlobals:Attenuators:ng3att1 = {0.444784,0.419,0.3935,0.3682,0.3492,0.3132,0.2936,0.2767,0.2477,0.22404}
	root:myGlobals:Attenuators:ng3att2 = {0.207506,0.1848,0.1629,0.1447,0.1292,0.1056,0.09263,0.08171,0.06656,0.0546552}
	root:myGlobals:Attenuators:ng3att3 = {0.092412,0.07746,0.06422,0.05379,0.04512,0.03321,0.02707,0.02237,0.01643,0.0121969}
	root:myGlobals:Attenuators:ng3att4 = {0.0417722,0.03302,0.02567,0.02036,0.01604,0.01067,0.00812,0.006316,0.00419,0.00282411}
	root:myGlobals:Attenuators:ng3att5 = {0.0187129,0.01397,0.01017,0.007591,0.005668,0.003377,0.002423,0.001771,0.001064,0.000651257}
	root:myGlobals:Attenuators:ng3att6 = {0.00851048,0.005984,0.004104,0.002888,0.002029,0.001098,0.0007419,0.0005141,0.000272833,0.000150624}
	root:myGlobals:Attenuators:ng3att7 = {0.00170757,0.001084,0.0006469,0.0004142,0.0002607,0.0001201,7.664e-05,4.06624e-05,1.77379e-05,7.30624e-06}
	root:myGlobals:Attenuators:ng3att8 = {0.000320057,0.0001918,0.0001025,6.085e-05,3.681e-05,1.835e-05,6.74002e-06,3.25288e-06,1.15321e-06,3.98173e-07}
	root:myGlobals:Attenuators:ng3att9 = {6.27682e-05,3.69e-05,1.908e-05,1.196e-05,8.738e-06,6.996e-06,6.2901e-07,2.60221e-07,7.49748e-08,2.08029e-08}
	root:myGlobals:Attenuators:ng3att10 = {1.40323e-05,8.51e-06,5.161e-06,4.4e-06,4.273e-06,1.88799e-07,5.87021e-08,2.08169e-08,4.8744e-09,1.08687e-09}
  
  //old tables, pre-June 2007
//  	Make/O/N=9 root:myGlobals:Attenuators:ng3lambda={5,6,7,8,10,12,14,17,20}
//	root:myGlobals:Attenuators:ng3att0 = {1, 1, 1, 1, 1, 1, 1, 1,1 }
//	root:myGlobals:Attenuators:ng3att1 = {0.421, 0.394, 0.371, 0.349, 0.316, 0.293, 0.274, 0.245,0.220}
//	root:myGlobals:Attenuators:ng3att2 = {0.187, 0.164, 0.145, 0.130, 0.106, 0.0916, 0.0808, 0.0651,0.0531}
//	root:myGlobals:Attenuators:ng3att3 = {0.0777, 0.0636, 0.0534, 0.0446, 0.0330, 0.0262, 0.0217, 0.0157 ,0.0116}
//	root:myGlobals:Attenuators:ng3att4 = {0.0328, 0.0252, 0.0195, 0.0156, 0.0104, 7.68e-3, 5.98e-3, 3.91e-3,0.00262}
//	root:myGlobals:Attenuators:ng3att5 = {0.0139, 9.94e-3, 7.34e-3, 5.44e-3, 3.29e-3, 2.25e-3, 1.66e-3, 9.95e-4, 6.12e-4}
//	root:myGlobals:Attenuators:ng3att6 = {5.95e-3, 3.97e-3, 2.77e-3, 1.95e-3, 1.06e-3, 6.81e-4, 4.71e-4, 2.59e-4 , 1.45e-4}
//	root:myGlobals:Attenuators:ng3att7 = {1.07e-3, 6.24e-4, 3.90e-4, 2.44e-4, 1.14e-4, 6.55e-5, 4.10e-5, 1.64e-5 , 7.26e-6}
//	root:myGlobals:Attenuators:ng3att8 = {1.90e-4, 9.84e-5, 5.60e-5, 3.25e-5, 1.55e-5, 6.60e-6, 3.42e-6, 1.04e-6 , 3.48e-7}
//	root:myGlobals:Attenuators:ng3att9 = {3.61e-5, 1.74e-5, 9.90e-6, 6.45e-6, 2.35e-6, 6.35e-7, 2.86e-7, 6.61e-8 , 1.73e-8}
//	root:myGlobals:Attenuators:ng3att10 = {7.60e-6, 3.99e-6, 2.96e-6, 2.03e-6, 3.34e-7, 6.11e-8, 2.39e-8, 4.19e-9 , 8.60e-10}

End

// new calibration done June 2007, John Barker
Proc MakeNG7AttenTable()

	NewDataFolder/O root:myGlobals:Attenuators
	
	Variable num=10		//10 needed for tables after June 2007
	
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att0
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att1
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att2
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att3
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att4
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att5
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att6
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att7
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att8
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att9
	Make/O/N=(num) root:myGlobals:Attenuators:ng7att10
	
	//NG7 wave has 10 elements, the transmission of att# at the wavelengths 
	//lambda =4, 5,6,7,8,10,12,14,17,20
	// note that some of the higher attenuations and ALL of the 4 A and 20A data is interpolated
	// none of these values are expected to be used in reality since the flux would be too low in practice
	Make/O/N=(num) root:myGlobals:Attenuators:ng7lambda={4,5,6,7,8,10,12,14,17,20}

// New calibration, June 2007, John Barker
	root:myGlobals:Attenuators:ng7att0 = {1, 1, 1, 1, 1, 1, 1, 1 ,1,1}	
	root:myGlobals:Attenuators:ng7att1 = {0.448656,0.4192,0.3925,0.3661,0.3458,0.3098,0.2922,0.2738,0.2544,0.251352}
 	root:myGlobals:Attenuators:ng7att2 = {0.217193,0.1898,0.1682,0.148,0.1321,0.1076,0.0957,0.08485,0.07479,0.0735965}
  	root:myGlobals:Attenuators:ng7att3 = {0.098019,0.07877,0.06611,0.05429,0.04548,0.03318,0.02798,0.0234,0.02004,0.0202492}
  	root:myGlobals:Attenuators:ng7att4 = {0.0426904,0.03302,0.02617,0.02026,0.0158,0.01052,0.008327,0.006665,0.005745,0.00524807}
  	root:myGlobals:Attenuators:ng7att5 = {0.0194353,0.01398,0.01037,0.0075496,0.005542,0.003339,0.002505,0.001936,0.001765,0.00165959}
  	root:myGlobals:Attenuators:ng7att6 = {0.00971666,0.005979,0.004136,0.002848,0.001946,0.001079,0.0007717,0.000588,0.000487337,0.000447713}
  	root:myGlobals:Attenuators:ng7att7 = {0.00207332,0.001054,0.0006462,0.0003957,0.0002368,0.0001111,7.642e-05,4.83076e-05,3.99401e-05,3.54814e-05}
  	root:myGlobals:Attenuators:ng7att8 = {0.000397173,0.0001911,0.0001044,5.844e-05,3.236e-05,1.471e-05,6.88523e-06,4.06541e-06,3.27333e-06,2.81838e-06}
  	root:myGlobals:Attenuators:ng7att9 = {9.43625e-05,3.557e-05,1.833e-05,1.014e-05,6.153e-06,1.64816e-06,6.42353e-07,3.42132e-07,2.68269e-07,2.2182e-07}
  	root:myGlobals:Attenuators:ng7att10 = {2.1607e-05,7.521e-06,2.91221e-06,1.45252e-06,7.93451e-07,1.92309e-07,5.99279e-08,2.87928e-08,2.19862e-08,1.7559e-08}

// Pre-June 2007 calibration values - do not use these anymore	
////	root:myGlobals:Attenuators:ng7att0 = {1, 1, 1, 1, 1, 1, 1, 1 ,1}
////	root:myGlobals:Attenuators:ng7att1 = {0.418, 0.393, 0.369, 0.347, 0.313, 0.291, 0.271, 0.244, 0.219 }
////	root:myGlobals:Attenuators:ng7att2 = {0.189, 0.167, 0.148, 0.132, 0.109, 0.0945, 0.0830, 0.0681, 0.0560}
////	root:myGlobals:Attenuators:ng7att3 = {0.0784, 0.0651, 0.0541, 0.0456, 0.0340, 0.0273, 0.0223, 0.0164 , 0.0121}
////	root:myGlobals:Attenuators:ng7att4 = {0.0328, 0.0256, 0.0200, 0.0159, 0.0107, 7.98e-3, 6.14e-3, 4.09e-3 , 0.00274}
////	root:myGlobals:Attenuators:ng7att5 = {0.0139, 0.0101, 7.43e-3, 5.58e-3, 3.42e-3, 2.36e-3, 1.70e-3, 1.03e-3 , 6.27e-4}
////	root:myGlobals:Attenuators:ng7att6 = {5.90e-3, 4.07e-3, 2.79e-3, 1.99e-3, 1.11e-3, 7.13e-4, 4.91e-4, 2.59e-4 , 1.42e-4}
////	root:myGlobals:Attenuators:ng7att7 = {1.04e-3, 6.37e-4, 3.85e-4, 2.46e-4, 1.16e-4, 6.86e-5, 4.10e-5, 1.64e-5 ,7.02e-6}
////	root:myGlobals:Attenuators:ng7att8 = {1.90e-4, 1.03e-4, 5.71e-5, 3.44e-5, 1.65e-5, 6.60e-6, 3.42e-6, 1.04e-6 , 3.48e-7}
////	root:myGlobals:Attenuators:ng7att9 = {3.58e-5, 1.87e-5, 1.05e-5, 7.00e-6, 2.35e-6, 6.35e-7, 2.86e-7, 6.61e-8 , 1.73e-8}
////	root:myGlobals:Attenuators:ng7att10 = {7.76e-6, 4.56e-6, 3.25e-6, 2.03e-6, 3.34e-7, 6.11e-8, 2.39e-8, 4.19e-9, 8.60e-10}
End

//returns the transmission of the attenuator (at NG3) given the attenuator number
//which must be an integer(to select the wave) and given the wavelength.
//the wavelength may be any value between 4 and 20 (A), and is interpolated
//between calibrated wavelengths for a given attenuator
//
// Mar 2010 - abs() added to attStr to account for ICE reporting -0.0001 as an attenuator position, which truncates to "-0"
Function LookupAttenNG3(lambda,attenNo)
	Variable lambda, attenNo
	
	Variable trans
	String attStr="root:myGlobals:Attenuators:ng3att"+num2str(trunc(abs(attenNo)))
	String lamStr = "root:myGlobals:Attenuators:ng3lambda"
	
	if(attenNo == 0)
		return (1)		//no attenuation, return trans == 1
	endif
	
	if( (lambda < 4) || (lambda > 20 ) )
		Abort "Wavelength out of calibration range (4,20). You must manually enter the absolute parameters"
	Endif
	
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Execute "MakeNG3AttenTable()"
	Endif
	//just in case creating the tables fails....
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Abort "Attenuator lookup waves could not be found. You must manually enter the absolute parameters"
	Endif
	
	//lookup the value by interpolating the wavelength
	//the attenuator must always be an integer
	Wave att = $attStr
	Wave lam = $lamstr
	trans = interp(lambda,lam,att)
	
//	Print "trans = ",trans
	
	return trans
End

//returns the transmission of the attenuator (at NG7) given the attenuator number
//which must be an integer(to select the wave) and given the wavelength.
//the wavelength may be any value between 4 and 20 (A), and is interpolated
//between calibrated wavelengths for a given attenuator
//
// this set of tables is also used for NG5 (NG1) SANS instrument - as the attenuator has never been calibrated
//
// local function
//
// Mar 2010 - abs() added to attStr to account for ICE reporting -0.0001 as an attenuator position, which truncates to "-0"
Function LookupAttenNG7(lambda,attenNo)
	Variable lambda, attenNo
	
	Variable trans
	String attStr="root:myGlobals:Attenuators:ng7att"+num2str(trunc(abs(attenNo)))
	String lamStr = "root:myGlobals:Attenuators:ng7lambda"
	
	if(attenNo == 0)
		return (1)		//no attenuation, return trans == 1
	endif
	
	if( (lambda < 4) || (lambda > 20 ) )
		Abort "Wavelength out of calibration range (4,20). You must manually enter the absolute parameters"
	Endif
	
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Execute "MakeNG7AttenTable()"
	Endif
	//just in case creating the tables fails....
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Abort "Attenuator lookup waves could not be found. You must manually enter the absolute parameters"
	Endif
	
	//lookup the value by interpolating the wavelength
	//the attenuator must always be an integer
	Wave att = $attStr
	Wave lam = $lamstr
	trans = interp(lambda,lam,att)
	
	//Print "trans = ",trans
	
	return trans

End

//returns the proper attenuation factor based on the instrument (NG3, NG5, or NG7)
//NG5 values are taken from the NG7 tables (there is very little difference in the
//values, and NG5 attenuators have not been calibrated (as of 8/01)
//
// filestr is passed from TextRead[3] = the default directory
// lam is passed from RealsRead[26]
// AttenNo is passed from ReaslRead[3]
//
// Attenuation factor as defined here is <= 1
//
// ORNL can pass ("",1,attenuationFactor) and have this function simply
// spit back the attenuationFactor (that was read into rw[3])
//
// called by Correct.ipf, ProtocolAsPanel.ipf, Transmission.ipf
//
Function AttenuationFactor(fileStr,lam,attenNo)
	String fileStr
	Variable lam,attenNo
	
	Variable attenFactor=1,loc
	String instr=fileStr[1,3]	//filestr is "[NGnSANSn] " or "[NGnSANSnn]" (11 characters total)
	
	strswitch(instr)
		case "NG3":
			attenFactor = LookupAttenNG3(lam,attenNo)
			break
		case "NG5":
			//using NG7 lookup Table
			attenFactor = LookupAttenNG7(lam,attenNo)
			break
		case "NG7":
			attenFactor = LookupAttenNG7(lam,attenNo)
			break
		default:							
			//return error?
			attenFactor=1
	endswitch
//	print "instr, lambda, attenNo,attenFactor = ",instr,lam,attenNo,attenFactor
	return(attenFactor)
End

//function called by the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// could also use the alternate procedure of keeping only file with the proper extension
//
// another possibility is to get a listing of the text files, but is unreliable on 
// Windows, where the data file must be .txt (and possibly OSX)
//
// called by FIT_Ops.ipf, NSORT.ipf, PlotUtils.ipf
//
Function/S ReducedDataFileList(ctrlName)
	String ctrlName

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the main panel"
		Return("")
	Endif
	
	list = IndexedFile(catpathName,-1,"????")
	
	list = RemoveFromList(ListMatch(list,"*.SA1*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.SA2*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.SA3*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,".*",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.pxp",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.DIV",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.GSP",";"), list, ";", 0)
	list = RemoveFromList(ListMatch(list,"*.MASK",";"), list, ";", 0)

	//remove VAX version numbers
	list = RemoveVersNumsFromList(List)
	//sort
	newList = SortList(List,";",0)

	return newlist
End

// returns a list of raw data files in the catPathName directory on disk
// - list is SEMICOLON-delimited
//
// does it the "cheap" way, simply finding the ".SAn" in the file name
// = does not check for proper byte length.
//
// called by PatchFiles.ipf, Tile_2D.ipf
//
Function/S GetRawDataFileList()
	
	//make sure that path exists
	PathInfo catPathName
	if (V_flag == 0)
		Abort "Folder path does not exist - use Pick Path button on Main Panel"
	Endif
	
	String list=IndexedFile(catPathName,-1,"????")
	String newList="",item=""
	Variable num=ItemsInList(list,";"),ii
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii, list  ,";")
		if( stringmatch(item,"*.sa1*") )
			newlist += item + ";"
		endif
		if( stringmatch(item,"*.sa2*") )
			newlist += item + ";"
		endif
		if( stringmatch(item,"*.sa3*") )
			newlist += item + ";"
		endif
		//print "ii=",ii
	endfor
	newList = SortList(newList,";",0)
	return(newList)
End

// Return the filename that represents the previous or next file.
// Input is current filename and increment. 
// Increment should be -1 or 1
// -1 => previous file
// 1 => next file
Function/S GetPrevNextRawFile(curfilename, prevnext)
	String curfilename
	Variable prevnext

	String filename
	
	//get the run number
	Variable num = GetRunNumFromFile(curfilename)
		
	//find the next specified file by number
	fileName = FindFileFromRunNumber(num+prevnext)

	if(cmpstr(fileName,"")==0)
		//null return, do nothing
		fileName = FindFileFromRunNumber(num)
	Endif

//	print "in FU "+filename

	Return filename
End


