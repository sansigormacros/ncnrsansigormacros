#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1


// A collection of function needed to implement the desmearing algorithm in the Quokka package

// initializes the folders and globals for use with the USANS_Panel
// waves for the listboxes must exist before the panel is drawn
// "dummy" values for the COR_Graph are set here
// instrumental constants are set here as well
//
Proc Init_MainUSANS()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:USANS
	NewDataFolder/O root:Packages:NIST:USANS:Globals
	NewDataFolder/O/S root:Packages:NIST:USANS:Globals:MainPanel
	
	
	if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		String/G root:Packages:NIST:gAngstStr = num2char(-127)
//		Variable/G root:myGlobals:gIsMac = 1
	else
		//either Windows or Windows NT
		String/G root:Packages:NIST:gAngstStr = num2char(-59)
//		Variable/G root:myGlobals:gIsMac = 0
		//SetIgorOption to keep some PC's (graphics cards?) from smoothing the 2D image
		//Execute "SetIgorOption WinDraw,forceCOLORONCOLOR=1"
	endif
	
	String/G root:Packages:NIST:USANS:Globals:gUSANSFolder  = "root:Packages:NIST:USANS"
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	//NB This is also hardcoded a bit further down - search for "WHY WHY WHY" AJJ Sept 08
	

	Make/O/T/N=1 fileWave,samWave,empWave,curWave //Added curWave Sept 06 A. Jackson
	fileWave=""
	samWave=""
	empWave=""
	curWave="" //Added Sept 06 A. Jackson
	//Wave for handling Current Data AJJ Sept 06
	Make/O/N=1 SAMisCurrent,EMPisCurrent
	SAMisCurrent = 0
	EMPisCurrent = 0
	Make/O/T/N=5 statusWave=""
	Make/O/B/U/N=1 selFileW
	Make/O/B/U/N=1 cselFileW
	//for the graph control bar
	Variable/G gTransWide = 1
	Variable/G gTransRock = 1
	Variable/G gEmpCts = 0.76			//default values as of 15 DEC 05 J. Barker
	Variable/G gBkgCts = 0.62			//default values as of 15 DEC 05 J. Barker
	Variable/G gThick = 0.1
	Variable/G gTypeCheck=1
	Variable/G gTransRatio=1
	//Text filter for data files AJJ Sept 06
	String/G FilterStr
	Variable/G gUseCurrentData = 0
	
	SetDataFolder root:
	
	NewDataFolder/O $(USANSFolder+":RAW")
	NewDataFolder/O $(USANSFolder+":SAM")
	NewDataFolder/O $(USANSFolder+":COR")
	NewDataFolder/O $(USANSFolder+":EMP")
	NewDataFolder/O $(USANSFolder+":BKG")
	NewDataFolder/O $(USANSFolder+":SWAP")
	NewDataFolder/O $(USANSFolder+":Graph")
	
	//dummy waves for bkg and emp levels
	Make/O $(USANSFolder+":EMP:empLevel"),$(USANSFolder+":BKG:bkgLevel")
	//WHY WHY WHY????? - because dependencies can only involve globals. No locals allowed, since the dependency
	// must remain in existence after the function is finished
	//Explicit dependency
	root:Packages:NIST:USANS:EMP:empLevel := root:Packages:NIST:USANS:Globals:MainPanel:gEmpCts //dependency to connect to SetVariable in panel
	root:Packages:NIST:USANS:BKG:bkgLevel := root:Packages:NIST:USANS:Globals:MainPanel:gBkgCts

// initializes facility specific constants to define the instrument	
	Init_USANS_Facility()	

	//initializes preferences. this includes XML y/n, and SANS Reduction items. 
	// if they already exist, they won't be overwritten
	
	Execute "Initialize_Preferences()"	
	
End

//facility-specific constants
Function Init_USANS_Facility()

	//INSTRUMENTAL CONSTANTS 
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_H = 3.9e-6		//Darwin FWHM	(pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gTheta_V = 0.014		//Vertical divergence	(pre- NOV 2004)
	//Variable/G  root:Globals:MainPanel:gDomega = 2.7e-7		//Solid angle of detector (pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDomega = 7.1e-7		//Solid angle of detector (NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDefaultMCR= 1e6		//factor for normalization
	
	//Variable/G  root:Globals:MainPanel:gDQv = 0.037		//divergence, in terms of Q (1/A) (pre- NOV 2004)
	Variable/G  	root:Packages:NIST:USANS:Globals:MainPanel:gDQv = 0.117		//divergence, in terms of Q (1/A)  (NOV 2004)

	String/G root:Packages:NIST:gXMLLoader_Title=""
	
	//November 2010 - deadtime corrections -- see USANS_DetectorDeadtime() below
	//Only used in BT5_Loader.ipf and dependent on date, so defined there on each file load.
	
	
	// to convert from angle (in degrees) to Q (in 1/Angstrom)
	Variable/G root:Packages:NIST:USANS:Globals:MainPanel:deg2QConv=5.55e-5		//JGB -- 2/24/01
	
	// extension string for the raw data files
	// -- not that the extension as specified here starts with "."
	String/G  	root:Packages:NIST:USANS:Globals:MainPanel:gUExt = ".bt5"
	
	
	
	return(0)
end

Function WriteXMLUSANSDesmeared(fullpath,lo,hi,dialog)
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder	
	
	Struct NISTXMLfile nf
	
	String termStr="\r\n"
	String destStr = USANSFolder+":DSM:"
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE Q_dsm =$(destStr + "Q_dsm")
	WAVE I_dsm=$(destStr + "I_dsm")
	WAVE S_dsm=$(destStr + "S_dsm")
	
	//check each wave
	If(!(WaveExists(Q_dsm)))
		Abort "Q_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(I_dsm)))
		Abort "I_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(S_dsm)))
		Abort "S_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	
	// 06 FEB 06 SRK
	// make dummy waves to hold the "fake" resolution, and write it as the last 3 columns
	//
	Duplicate/O Q_dsm,res1,res2,res3
	res3 = 1		// "fake" beamstop shadowing
	res1 /= 100		//make the sigmaQ so small that there is no smearing
	
	if(dialog)
		Open/D refnum as fullpath+".dsmx"		//won't actually open the file
		If(cmpstr(S_filename,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		fullpath = S_filename
	Endif
	
	//write out partial set?
	Duplicate/O Q_dsm,tq,ti,te
	ti=I_dsm
	te=S_dsm
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=Q_dsm[p+lo]
		ti=I_dsm[p+lo]
		te=S_dsm[p+lo]
	endif
	
		//Data
	Wave nf.Q = tq
	nf.unitsQ = "1/A"
	Wave nf.I = ti
	nf.unitsI = "1/cm"
	Wave nf.Idev = te
	nf.unitsIdev = "1/cm"
	Wave nf.Qdev = res1
	nf.unitsQdev = "1/A"
	Wave nf.Qmean = res2
	nf.unitsQmean = "1/A"
	Wave nf.Shadowfactor = res3
	nf.unitsShadowfactor = "none"
	
	//tailor the output given the type of data written out...
	String samStr="",dateStr="",str1,str2
	
	NVAR m = $(USANSFolder+":DSM:gPowerM")				// power law exponent
	NVAR chiFinal = $(USANSFolder+":DSM:gChi2Final")		//chi^2 final
	NVAR iter = $(USANSFolder+":DSM:gIterations")		//total number of iterations
	
	//get the number of spline passes from the wave note
	String noteStr
	Variable boxPass,SplinePass
	noteStr=note(I_dsm)
	BoxPass = NumberByKey("BOX", noteStr, "=", ";")
	splinePass = NumberByKey("SPLINE", noteStr, "=", ";")
	
	samStr = fullpath
	dateStr="CREATED: "+date()+" at  "+time()
	sprintf str1,"Chi^2 = %g   PowerLaw m = %4.2f   Iterations = %d",chiFinal,m,iter
	sprintf str2,"%d box smooth passes and %d smoothing spline passes",boxPass,splinePass
	
	//AJJ to fix with sensible values
	nf.run = "Test"
	nf.nameSASinstrument = "BT5 USANS"
	nf.SASnote = ""
	//
	nf.sample_ID = ""
	nf.title = samstr
	nf.radiation = "neutron"
	nf.wavelength = 2.38
	nf.unitswavelength = "A"
	
	//Do something with beamstop (rw[21])
	nf.detector_name = "BT5 DETECTOR ARRAY"

	nf.SASprocessnote = samStr+"\n"
	nf.SASprocessnote += str1+"\n"
	nf.SASprocessnote += str2+"\n"
	nf.SASprocessnote += datestr+"\n"

	
	nf.nameSASProcess = "NIST IGOR"

	//Close refnum
	
	writeNISTXML(fullpath, nf)
	
	SetDataFolder root:		//(redundant)
	
	KillWaves/Z res1,res2,res2,ti,te,tq
	
	Return(0)
End
