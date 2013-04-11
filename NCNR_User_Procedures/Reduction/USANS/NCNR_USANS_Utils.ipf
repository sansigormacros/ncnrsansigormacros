#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.20
#pragma IgorVersion=6.1

// utilities and constants that are specific to the NCNR USANS

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


// returns the detector dead time for the main detectors, and the transmission detector
//
// NCNR values switch based on a date when hardware was swapped out. other facilities can ignore the date
//
// also, if dead time is not known, zero can be returned to inactivate the dead time correction
//
//
//Discovered significant deadtime on detectors in Oct 2010
//JGB and AJJ changed pre-amps during shutdown Oct 27 - Nov 7 2010
//Need different deadtime before and after 8th November 2010
//
Function USANS_DetectorDeadtime(filedt,MainDeadTime,TransDeadTime)
	String filedt
	Variable &MainDeadTime,&TransDeadTime
	
	if (BT5Date2Secs(filedt) < date2secs(2010,11,7))
			MainDeadTime = 4e-5
			TransDeadTime = 1.26e-5
			//print "Old Dead Times"
			//MainDeadTime = 0
			//TransDeadTime = 0
	else
			MainDeadTime = 7e-6
			TransDeadTime = 1.26e-5
			//print "New Dead Times"
	endif
	
	return(0)
end