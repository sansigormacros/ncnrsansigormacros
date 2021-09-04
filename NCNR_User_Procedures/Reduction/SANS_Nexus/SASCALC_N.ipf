#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.0
#pragma IgorVersion=6.1
#pragma ModuleName=SASCALC

//
// AUG 2021
//
// Can I just leave SASCALC alone - and have it work "internally" as if it was VAX,
// and then at the very end, if it desired to write out a 2D data file, only then do
// I convert the VAX RTI to a Nexus tree for writing.
//
// -- NO -leaving everything untouched won't completely work, since the SASCALC procedures (for the 2D MC)
// need to do some "reads" from the SAS folder. In VCALC, I set up the skeleton of the file
// structure in the folder, enough to cover the variables I'm trying to read from the folder
// -- I'll need to do this for the SAS folder.
// -- I've already made some of the read changes in the MC file, so I may be stuck now...
//
//
//
//






//
// SASCALC.ipf
//
// 04 OCT 2006 SRK
// 30 OCT 2006 SRK - corrected beamDiameter size in attenuator calculation (Bh vs Bm)
// 11 DEC 2006 SRK - added 2.5 cm A1 option for NG3@7guide config
// 09 MAR 2007 SRK - now appends text of each frozen configuration for printing
//					  - colorized frozen traces so that they aren't all red (unfrozen is black)
// 19 MAR 2007 SRK - corrections added for projected BS diameter at anode plane
// 11 APR 2007 SRK - default aperture offset of 5 cm added to match VAX implementation
// nn AUG 2007 SRK - added defulat sample aperture size
// 						 added option of lenses, approximated beamDiam=sourceDiam, BSdiam=1"
//						 Lens flux, trans is not corrected for lens/prism transmission
//						 Lenses can still be inserted in incorrect cases, and are not automatically taken out
// 27 JAN 2009 SRK - Changed behavior of Lens checkbox. Now, it SETS parameters as needed for proper
//						 configuration. 17.2 can be typed in for lens/prism on NG3. Invalid conditions
//						 will automatically uncheck the box
// 03 MAR 2012 SRK - Added new source apertures in 6th and 7th boxes of NG3
//
// 05 OCT 2012 SRK - (not visible) but added the skeleton bits for the 10m SANS instrument. Don't have the
//							details of the distances, etc, but I'll fill that in as needed
// 						-- to "un-hide" the 10m SANS, uncomment the CheckBox control in the panel (see the constant declared below)
// 03 JAN 2013 SRK -- settled on "A" for new 10m SANS and "B" for the NG3 when it's relocated. Both instruments share
//							NGB, so this will have to do. files will be SA4 and SA5 respectively, if the VAX naming continues
// 21 Jan 2014 MJW - Added creation of strings representing NICE configurations and the ability to output these strings to a text document.
//							Configuration string variables are saved using the Freeze button (2 per configuration, one for scattering
//							and one for transmission) and deleted using the clear button.
//							Configurations are outputted to text using command "SaveNICEConfigs()"
//
//  MAY 2014 SRK -- changed nomenclature of NG3 to be CGB (shows on button as NGB30) - Nothing changes in the simulation
//                  so this change is nothing but cosmetic. I will need to update the flux calibration, but there is no need to keep the old.
//
//
//
//
// calculate what q-values you get based on the instruments settings
// that you would typically input to SASCALC
// calculation is for (80A radius spheres) * (beam stop shadow factor)
// or a Debye function (Rg=50A) * (beam stop shadow factor) 
// - NOT true intensity, not counts, just a display
//
// TODO_10m:
//
// -- For the 10m SANS...
//
//		x- how many guides are there
//		x- no lenses? focusing pinholes?
//		x- aperture sizes?
//		- flux values
//		x- huber/sample chamber is inline, so get rid of this for 10m (gray out?)
//		x- does this hook into anywhere in the main program? Attenuators, etc.
//			where knowledge of the 10m SANS is necessary??
//		x- setting the instrument "number" is done here as "10". This will have a trickle-down effect for the places that use
//		the global -- root:Packages:NIST:SAS:instrument (search for it everywhere...)
// 		x- repair the naming/numbering scheme to look for the string "NGx" and switch on that, not a number, which is unreliable and confusing.
//
//
//	TODO_CGB:
//  For the moved NG3 instrument:
//   -- update the flux values once some measurements have been done
//   -- update the wavelength spread values once they have been measured
//   -- be sure that no other dimensions have been changed after the move
//   -- polarizer is gone now. Be sure apertures are correct in UpdateControls()
//   -- any other changes???
//
// use str2hex(str) (my function) to convert "A" to 10
//
// Optional:
// - freeze configurations with a user defined tag
// - different model functions (+ change simple parameters)
// - resolution smeared models
// - "simulation" of data and error bars given a model and a total number of detector counts
// - streamline code (globals needed in panel vs. wave needed for calculation)
//
// - there is a lot of re-calculation of things (a consequence of the fake-OO) that could be streamlined
//
// Done:
// - include resolution effects (includes BS effect, smeared model)
// - (data = 1) then multiply by a typical form factor
// - masked two pixels around the edge, as default
// - conversion from # guides to SSD from sascalc
// - show multiple configurations at once
// - interactive graphics on panel
// - full capabilities of SASCALC
// - correct beamstop diameter
// - get the sample/huber position properly incorporated (ssd and sdd)
// - get SDD value to update when switching NG7->NG3 and illegal value
// - disallow 6 guides at NG3 (post a warning)
//
//

Constant show10mSANS = 1



Proc SASCALC()
	DoWindow/F SASCALC
	if(V_flag==0)
		S_initialize_space()
		initNG3()		//start life as NG3
		Sascalc_Panel()
		ReCalculateInten(1)		//will use defaults
	Endif

End

Proc S_initialize_space()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:SAS
	
	Make/O/D/N=23 root:Packages:NIST:SAS:integersRead
	Make/O/D/N=52 root:Packages:NIST:SAS:realsRead
	Make/O/T/N=11 root:Packages:NIST:SAS:textRead
	// data
	Make/O/D/N=(128,128) root:Packages:NIST:SAS:data,root:Packages:NIST:SAS:linear_data
	Make/O/D/N=2 root:Packages:NIST:SAS:aveint,root:Packages:NIST:SAS:qval,root:Packages:NIST:SAS:sigave
	root:Packages:NIST:SAS:data = 1
	root:Packages:NIST:SAS:linear_data = 1

	
	// other variables
	// -(hard coded right now - look for NVAR declarations)
	Variable/G root:Packages:NIST:gBinWidth=1		//uses global preference
	Variable/G root:Packages:NIST:SAS:gisLogScale=0
	String/G root:Packages:NIST:SAS:FileList = "SASCALC"
	
	// for the panel
//	Variable/G root:Packages:NIST:SAS:gInst=3		//or 7 for NG7
//	String/G root:Packages:NIST:SAS:gInstStr="NG3"		//or "NG7" or "NGB"=10m or "CGB"=NG3 moved
	String/G root:Packages:NIST:SAS:gInstStr="CGB"		//or "NG7" or "NGB"=10m or "CGB"=NG3 moved
	Variable/G root:Packages:NIST:SAS:gNg=0
	Variable/G root:Packages:NIST:SAS:gTable=2		//2=chamber, 1=table
	Variable/G root:Packages:NIST:SAS:gDetDist=1000		//sample chamber to detector in cm
	Variable/G root:Packages:NIST:SAS:gSSD=1632		//!!SSD in cm fo 0 guides (derived from Ng)
	Variable/G root:Packages:NIST:SAS:gOffset=0
	Variable/G root:Packages:NIST:SAS:gSamAp=1.27		//samAp diameter in cm
	Variable/G root:Packages:NIST:SAS:gLambda=6
	Variable/G root:Packages:NIST:SAS:gDeltaLambda=0.125		//default value
	String/G root:Packages:NIST:SAS:gSourceApString = "1.43 cm;2.54 cm;3.81 cm;"
	String/G root:Packages:NIST:SAS:gDeltaLambdaStr = "0.109;0.125;0.236;"		//ng3 defaults
	String/G root:Packages:NIST:SAS:gApPopStr = "1/16\";1/8\";3/16\";1/4\";5/16\";3/8\";7/16\";1/2\";9/16\";5/8\";11/16\";3/4\";other;"
	Variable/G root:Packages:NIST:SAS:gSamApOther = 10		//non-standard aperture diameter, in mm
	Variable/G root:Packages:NIST:SAS:gUsingLenses = 0		//0=no lenses, 1=lenses(or prisms)
	Variable/G root:Packages:NIST:SAS:gModelOffsetFactor = 1
	
	// for the MC simulation
	Variable/G root:Packages:NIST:SAS:doSimulation	=0		// == 1 if 1D simulated data, 0 if other from the checkbox
	Variable/G root:Packages:NIST:SAS:gRanDateTime=datetime
	Variable/G root:Packages:NIST:SAS:gImon = 10000
	Variable/G root:Packages:NIST:SAS:gThick = 0.1
	Variable/G root:Packages:NIST:SAS:gSig_incoh = 0.1
	String/G root:Packages:NIST:SAS:gFuncStr = ""
	Variable/G root:Packages:NIST:SAS:gR2 = 2.54/2	
	Variable/G root:Packages:NIST:SAS:gSamTrans=0.8			//for 1D, default value
	Variable/G root:Packages:NIST:SAS:gCntTime = 300
	Variable/G root:Packages:NIST:SAS:gDoMonteCarlo = 0
	Variable/G root:Packages:NIST:SAS:gUse_MC_XOP = 1				//set to zero to use Igor code
	Variable/G root:Packages:NIST:SAS:gBeamStopIn = 1			//set to zero for beamstop out (transmission)
	Variable/G root:Packages:NIST:SAS:gRawCounts = 0
	Variable/G root:Packages:NIST:SAS:gSaveIndex = 100
	String/G root:Packages:NIST:SAS:gSavePrefix = "SIMUL"
	Variable/G root:Packages:NIST:SAS:gAutoSaveIndex = 100			//a way to set the index for automated saves
	String/G root:Packages:NIST:SAS:gAutoSaveLabel = ""				//a way to set the "sample" label for automated saves
	Make/O/D/N=10 root:Packages:NIST:SAS:results = 0
	Make/O/T/N=10 root:Packages:NIST:SAS:results_desc = {"total X-section (1/cm)","SAS X-section (1/cm)","number that scatter","number that reach detector","avg # times scattered","fraction single coherent","fraction multiple coherent","fraction multiple scattered","fraction transmitted","detector counts w/beamstop"}

	Variable/G root:Packages:NIST:SAS:g_1DTotCts = 0			//summed counts (simulated)
	Variable/G root:Packages:NIST:SAS:g_1DEstDetCR = 0		// estimated detector count rate
	Variable/G root:Packages:NIST:SAS:g_1DFracScatt = 0		// fraction of beam captured on detector
	Variable/G root:Packages:NIST:SAS:g_1DEstTrans = 0		// estimated transmission of sample (OUTPUT)
	Variable/G root:Packages:NIST:SAS:g_1D_DoABS = 1
	Variable/G root:Packages:NIST:SAS:g_1D_AddNoise = 1
	Variable/G root:Packages:NIST:SAS:g_MultScattFraction=0
	Variable/G root:Packages:NIST:SAS:g_detectorEff=0.75			//average value for most wavelengths
	Variable/G root:Packages:NIST:SAS:g_actSimTime = 0				//for the save
	Variable/G root:Packages:NIST:SAS:g_SimTimeWarn = 10			//manually set to a very large value for scripted operation
	Variable/G root:Packages:NIST:SAS:g_estimateOnly = 0			// == 1 for just a time estimate, == 0 (default) to do the simulation
	Variable/G root:Packages:NIST:SAS:g_estimatedMCTime		// estimated MC sim time
	
	PlotEC_Empirical(100,0.001,0.7)		// plot an empirical empty cell, only used for the simulation, not needed for SASCALC
//	KillTopGraphAndTable(1)					// then kill the graph and table that the macro generates (but the function is in Wrapper, which is often not loaded
	String topGraph= WinName(0,1)	//this is the topmost graph	
	String topTable= WinName(0,2)	//this is the topmost table
	KillWindow $topGraph
	KillWindow $topTable
	
	
	//tick labels for SDD slider
	//userTicks={tvWave,tlblWave }
	Make/O/D/N=5 root:Packages:NIST:SAS:tickSDDNG3,root:Packages:NIST:SAS:tickSDDNG7
	Make/O/T/N=5 root:Packages:NIST:SAS:lblSDDNG3,root:Packages:NIST:SAS:lblSDDNG7
	Make/O/D/N=5 root:Packages:NIST:SAS:tickSDDNGB
	Make/O/T/N=5 root:Packages:NIST:SAS:lblSDDNGB
	root:Packages:NIST:SAS:tickSDDNG3 = {133,400,700,1000,1317}
	root:Packages:NIST:SAS:lblSDDNG3 = {"133","400","700","1000","1317"}
	root:Packages:NIST:SAS:tickSDDNG7 = {100,450,800,1150,1530}
	root:Packages:NIST:SAS:lblSDDNG7 = {"100","450","800","1150","1530"}
	root:Packages:NIST:SAS:tickSDDNGB = {106,200,300,400,525}
	root:Packages:NIST:SAS:lblSDDNGB = {"106","200","300","400","525"}
//	root:Packages:NIST:SAS:tickSDDNGB = {106,200,300,400,500,525}
//	root:Packages:NIST:SAS:lblSDDNGB = {"106","200","300","400","500","525"}
		
	//for the fake dependency
	Variable/G root:Packages:NIST:SAS:gTouched=0
	Variable/G root:Packages:NIST:SAS:gCalculate=0
	//for plotting
	Variable/G root:Packages:NIST:SAS:gFreezeCount=1		//start the count at 1 to keep Jeff happy
	Variable/G root:Packages:NIST:SAS:gDoTraceOffset=0		// (1==Yes, offset 2^n), 0==turn off the offset
	
	// fill a fake data header
	// fill w/default values
	S_fillDefaultHeader(root:Packages:NIST:SAS:integersRead,root:Packages:NIST:SAS:realsRead,root:Packages:NIST:SAS:textRead)
	
End

Function initNG3()

	SetDataFolder root:Packages:NIST:SAS
	
//	String/G gSelectedInstrument="checkNG3"
//	String/G gInstStr = "NG3"
	String/G gSelectedInstrument="checkCGB"
	String/G gInstStr = "CGB"
	
	Variable/G s12 = 54.8
	Variable/G d_det = 0.508
	Variable/G a_pixel = 0.508
	Variable/G del_r = 0.5
	Variable/G det_width = 64.0
	Variable/G lambda_t = 5.50
	Variable/G l2r_lower = 132.3
	Variable/G l2r_upper =  1317
	Variable/G lambda_lower = 2.5
	Variable/G lambda_upper = 20.0
	Variable/G d_upper = 25.0
	Variable/G bs_factor = 1.05
	Variable/G t1 = 0.63
	Variable/G t2 = 1.0
	Variable/G t3 = 0.75
	Variable/G l_gap = 100.0
	Variable/G guide_width = 6.0
	Variable/G idmax = 100.0
//	//old values, from 3/2002
//	Variable/G phi_0 = 2.95e13
//	Variable/G b = 0.023
//	Variable/G c = 0.023

	//new values, from 11/2009 --- BeamFluxReport_2009.ifn
	Variable/G phi_0 = 2.42e13
	Variable/G b = 0.0
	Variable/G c = -0.0243
	Variable/G gGuide_loss = 0.924
	
//	//fwhm values (new variables) (+3, 0, -3, calibrated 2009)
//	Variable/G fwhm_narrow = 0.109
//	Variable/G fwhm_mid = 0.125
//	Variable/G fwhm_wide = 0.236
//	
//	//source apertures (cm)
//	Variable/G a1_0_0 = 1.43
//	Variable/G a1_0_1 = 2.54
//	Variable/G a1_0_2 = 3.81
//	Variable/G a1_7_0 = 2.5	// after the polarizer		
//	Variable/G a1_7_1 = 5.0
//	Variable/G a1_7_1 = 0.95		// new Mar 2012 9.5 mm diameter source aperture
//	Variable/G a1_def = 5.00
	
	//default configuration values
//	ng = 0
//	a1 = 3.81
//	pos_table = 2
//	l2r = 1310.0
//	a2 = 1.27
//	det_off = 0.0
//	lambda = 6.0
//	lambda_width = 0.15
	Variable/G	l2diff = 5.0
//	


	UpdateSASHeader()
	
	SetDataFolder root:
end

Function initNG7()

	SetDataFolder root:Packages:NIST:SAS

	String/G gSelectedInstrument="checkNG7"
	String/G gInstStr = "NG7"
	
	Variable/G s12 = 54.8
	Variable/G d_det = 0.508
	Variable/G a_pixel = 0.508
	Variable/G del_r = 0.5
	Variable/G det_width = 64.0
	Variable/G lambda_t = 5.50
	Variable/G l2r_lower = 100
	Variable/G l2r_upper =  1531
	Variable/G lambda_lower = 4.0
	Variable/G lambda_upper = 20.0
	Variable/G d_upper = 25.0
	Variable/G bs_factor = 1.05
	Variable/G t1 = 0.63
	Variable/G t2 = 0.7
	Variable/G t3 = 0.75
	Variable/G l_gap = 188.0
	Variable/G guide_width = 5.0
	Variable/G idmax = 100.0
	
//	//old values, from 3/2002
//	Variable/G phi_0 = 2.3e13
//	Variable/G b = 0.028
//	Variable/G c = 0.028

	//new values, from 11/2009	
	Variable/G phi_0 = 2.55e13
	Variable/G b = 0.0395
	Variable/G c = 0.0442
	Variable/G gGuide_loss = 0.974
	
//	//fwhm values (new variables)
//	Variable/G fwhm_narrow = 0.09
//	Variable/G fwhm_mid = 0.115		//2009
//	Variable/G fwhm_wide = 0.22
//	
//	//source apertures (cm)
//	Variable/G a1_0_0 = 1.43
//	Variable/G a1_0_1 = 2.22
//	Variable/G a1_0_2 = 3.81
//	Variable/G a1_7_0 = 5.0		// don't apply to NG7
//	Variable/G a1_7_1 = 5.0
//	Variable/G a1_def = 5.00
	
	//default configuration values
//	ng = 0
//	a1 = 2.22
//	pos_table = 2
//	l2r = 1530.0
//	a2 = 1.27
//	det_off = 0.0
//	lambda = 6.0
//	lambda_width = 0.11
	Variable/G	l2diff = 5.0
//	

	UpdateSASHeader()
	SetDataFolder root:
end

/// this is the (incomplete) definition of the 10m SANS instrument
// on NG-B, which will be referred to as NGB here to keep the NG(number) notation
// reserving CGB for the moved NG3 instrument
// which may be simpler here to keep functions from breaking...
//
// Updated 24 JAN 2013 with current flux numbers from John
//
Function initNGB()

	SetDataFolder root:Packages:NIST:SAS

	String/G gSelectedInstrument="checkNGB"	
	String/G gInstStr = "NGB"

	Variable/G s12 = 0			//**		no difference between sample and huber position
	Variable/G d_det = 0.508
	Variable/G a_pixel = 0.508
	Variable/G del_r = 0.5
	Variable/G det_width = 64.0
	Variable/G lambda_t = 5.50				//good, Jan 2013
	Variable/G l2r_lower = 106
	Variable/G l2r_upper =  525
	Variable/G lambda_lower = 3.0
	Variable/G lambda_upper = 30.0
	Variable/G d_upper = 25.0			
	Variable/G bs_factor = 1.05		
	Variable/G t1 = 0.63				//**good, Jan 2013
	Variable/G t2 = 1.0					//**good, Jan 2013
	Variable/G t3 = 0.75				//**good, Jan 2013
	Variable/G l_gap = 165				//**good, Jan 2013
	Variable/G guide_width = 5.0		//**good, Jan 2013
	Variable/G idmax = 100.0			//** max count rate per pixel
//	current values -- Jan 2013
	Variable/G phi_0 = 2.5e13
	Variable/G b = 0.03
	Variable/G c = 0.03

	Variable/G gGuide_loss = 0.95
	
//	//fwhm values (new variables) (+3, 0, -3, calibrated 2009)
//	Variable/G fwhm_narrow = 0.10
//	Variable/G fwhm_mid = 0.20
//	Variable/G fwhm_wide = 0.30
//	
//	//source apertures (cm)
//	Variable/G a1_0_0 = 1.43
//	Variable/G a1_0_1 = 2.54
//	Variable/G a1_0_2 = 3.81
//	Variable/G a1_7_0 = 2.5	// after the polarizer		
//	Variable/G a1_7_1 = 5.0
//	Variable/G a1_7_1 = 0.95		// new Mar 2012 9.5 mm diameter source aperture
//	Variable/G a1_def = 5.00
//	
	//default configuration values
//	ng = 0
//	a1 = 3.81
//	pos_table = 2
//	l2r = 1310.0
//	a2 = 1.27
//	det_off = 0.0
//	lambda = 6.0
//	lambda_width = 0.15
	Variable/G	l2diff = 5.0
//	
	UpdateSASHeader()
	SetDataFolder root:
end

// as the instrument changes, fill in appropriate values into the header waves of the SAS folder
// so that any simulation data (2D VAX) that is written out will be as correct as possible
// -- this should be taken care of in SimulationVAXHeader(), so this is really redundant
Function UpdateSASHeader()

	Wave/T tw=root:Packages:NIST:SAS:textRead
	// fill in the instrument
	SVAR gInstStr = root:Packages:NIST:SAS:gInstStr
	tw[3] = "["+gInstStr+"SANS99]"

End

Function S_fillDefaultHeader(iW,rW,tW)
	Wave iW,rW
	Wave/T tW

	// text wave
	// fill in the instrument
	SVAR gInstStr = root:Packages:NIST:SAS:gInstStr
	tw[3] = "["+gInstStr+"SANS99]"
	
	// integer wave
	// don't need anything
	
	// real wave
	rw = 0
	rw[16] = 65		// beamcenter X (pixels)
	rw[17] = 64		// beamcenter Y
	
	rw[10]	= 5.08			//detector resolution (5mm) and calibration constants (linearity)
	rw[11] = 10000
	rw[12] = 0
	rw[13] = 5.08
	rw[14] = 10000
	rw[15] = 0
	
	rw[20] = 65		// det size in cm
	rw[18] = 6		// SDD in meters (=L2)
	
	rw[26] = 6		//lambda in Angstroms
	rw[4] = 1		//transmission
	
	rw[21] = 76.2			//BS diameter in mm
	rw[23] = 50			//A1 diameter in mm
	rw[24] = 12.7			//A2 diameter in mm
	rw[25] = 7.02			//L1 distance in meters (derived from number of guides)
	rw[27] = 0.11			//DL/L wavelength spread
	
	return(0)
End

//
Window SASCALC_Panel()

	PauseUpdate; Silent 1		// building window...

// if I make the graph a subwindow in a panel, it breaks the "append 1d" from the wrapper	
//	NewPanel/W=(5,44,463,570)/K=1 as "SASCALC"
//	DoWindow/C SASCALC
//	ModifyPanel cbRGB=(49151,53155,65535)
//
//	
//	String fldrSav0= GetDataFolder(1)
//	SetDataFolder root:Packages:NIST:SAS:
//	
//	Display/HOST=#/W=(5,200,463,570) aveint vs qval
//	ModifyGraph mode=3
//	ModifyGraph marker=19
//	ModifyGraph rgb=(0,0,0)
//	Modifygraph log=1
//	Modifygraph grid=1
//	Modifygraph mirror=2
//	ModifyGraph msize(aveint)=2
//	ErrorBars/T=0 aveint Y,wave=(sigave,sigave)
//	Label bottom, "Q (1/A)"
//	Label left, "Relative Intensity"
//	legend
//	
//	RenameWindow #,G_aveint
//	SetActiveSubwindow ##

//// end panel commands

/// draw as a graph
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:SAS:
	
	Display/W=(5,44,463,570)/K=1  aveint vs qval as "SASCALC"
	DoWindow/C SASCALC
	ModifyGraph cbRGB=(49151,53155,65535)
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	Modifygraph log=1
	Modifygraph grid=1
	Modifygraph mirror=2
	ModifyGraph msize(aveint)=2
	ErrorBars/T=0 aveint Y,wave=(sigave,sigave)
	Label bottom, "Q (1/A)"
	Label left, "Relative Intensity"
	legend
	
	ControlBar/T 200

	SetDataFolder fldrSav0
	
	Slider SC_Slider,pos={11,46},size={150,45},proc=GuideSliderProc,live=0
	Slider SC_Slider,limits={0,8,1},variable= root:Packages:NIST:SAS:gNg,vert= 0//,thumbColor= (1,16019,65535)
	Slider SC_Slider_1,pos={234,45},size={150,45},proc=DetDistSliderProc,live=0
	Slider SC_Slider_1,tkLblRot= 90,userTicks={root:Packages:NIST:SAS:tickSDDNG3,root:Packages:NIST:SAS:lblSDDNG3 }
	Slider SC_Slider_1,limits={133,1317,1},variable= root:Packages:NIST:SAS:gDetDist,vert= 0//,thumbColor= (1,16019,65535)
	Slider SC_Slider_2,pos={394,21},size={47,65},proc=OffsetSliderProc,live=0,ticks=4
	Slider SC_Slider_2,limits={0,25,1},variable= root:Packages:NIST:SAS:gOffset//,thumbColor= (1,16019,65535)
//	CheckBox checkNG3,pos={20,19},size={36,14},proc=SelectInstrumentCheckProc,title="NG3"
//	CheckBox checkNG3,value=1,mode=1
	CheckBox checkCGB,pos={17,19},size={36,14},proc=SelectInstrumentCheckProc,title="NGB30"
	CheckBox checkCGB,value=1,mode=1
	CheckBox checkNG7,pos={70,19},size={36,14},proc=SelectInstrumentCheckProc,title="NG7"
	CheckBox checkNG7,value=0,mode=1

	CheckBox checkChamber,pos={172,48},size={57,14},proc=TableCheckProc,title="Chamber"
	CheckBox checkChamber,value=1,mode=1
	CheckBox checkHuber,pos={172,27},size={44,14},proc=TableCheckProc,title="Huber"
	CheckBox checkHuber,value=0,mode=1
//	-- hide/unhide the 10m SANS
	if(show10mSANS)
		CheckBox checkNGB,pos={114,19},size={40,14},proc=SelectInstrumentCheckProc,title="NGB"
		CheckBox checkNGB,value=0,mode=1
	endif
//		
	PopupMenu popup0,pos={6,94},size={76,20},proc=SourceAperturePopMenuProc
	PopupMenu popup0,mode=1,popvalue="3.81 cm",value= root:Packages:NIST:SAS:gSourceApString
	PopupMenu popup0_1,pos={172,72},size={49,20},proc=SampleAperturePopMenuProc
	PopupMenu popup0_1,mode=8,popvalue="1/2\"",value= root:Packages:NIST:SAS:gApPopStr
	SetVariable setvar0,pos={301,107},size={130,15},title="Det Dist (cm)",proc=SDDSetVarProc
	SetVariable setvar0,limits={133,1317,1},value=root:Packages:NIST:SAS:gDetDist
	SetVariable setvar0_1,pos={321,129},size={110,15},title="Offset (cm)",proc=OffsetSetVarProc
	SetVariable setvar0_1,limits={0,25,1},value= root:Packages:NIST:SAS:gOffset
	SetVariable setvar0_2,pos={6,130},size={90,15},title="Lambda",proc=LambdaSetVarProc
	SetVariable setvar0_2,limits={4,20,0.1},value= root:Packages:NIST:SAS:gLambda
	PopupMenu popup0_2,pos={108,127},size={55,20},proc=DeltaLambdaPopMenuProc
	PopupMenu popup0_2,mode=2,value= root:Packages:NIST:SAS:gDeltaLambdaStr
	Button FreezeButton title="Freeze",size={60,20},pos={180,166}
	Button FreezeButton proc=FreezeButtonProc
	Button ClearButton title="Clear",size={60,20},pos={250,166}
	Button ClearButton proc=S_ClearButtonProc
//	GroupBox group0,pos={6,1},size={108,36},title="Instrument"
	GroupBox group0,pos={6,1},size={160,39},title="Instrument"
	SetDataFolder fldrSav0
	
	SetVariable setvar0_3,pos={140,94},size={110,15},title="Diam (mm)",disable=1
	SetVariable setvar0_3,limits={0,100,0.1},value= root:Packages:NIST:SAS:gSamApOther,proc=SampleApOtherSetVarProc
	
	CheckBox checkLens,pos={6,155},size={44,14},proc=LensCheckProc,title="Lenses?"
	CheckBox checkLens,value=root:Packages:NIST:SAS:gUsingLenses
	
	CheckBox checkSim,pos={6,175},size={44,14},proc=SimCheckProc,title="Simulation?"
	CheckBox checkSim,value=0
	
	CheckBox check0_1,pos={80,155},size={90,14},title="Offset Traces?",variable= root:Packages:NIST:SAS:gDoTraceOffset

	// help, done buttons
	Button SC_helpButton,pos={340,166},size={25,20},proc=showSASCALCHelp,title="?"
	Button SC_helpButton,help={"Show help file for simulation of SANS Data"}
	Button SC_DoneButton,pos={380,166},size={50,20},proc=SASCALCDoneButton,title="Done"
	Button SC_DoneButton,help={"This button will close the panel"}

	// set up a fake dependency to trigger recalculation
	//root:Packages:NIST:SAS:gCalculate := ReCalculateInten(root:Packages:NIST:SAS:gTouched)
EndMacro

//clean up
Proc SASCALCDoneButton(ctrlName): ButtonControl
	String ctrlName
	DoWindow/K SASCALC
	DoWindow/K Trial_Configuration
	DoWindow/K Saved_Configurations
	DoWindow/K MC_SASCALC
	DoWindow/K Sim_1D_Panel
end

//
Proc showSASCALCHelp(ctrlName): ButtonControl
	String ctrlName
	DisplayHelpTopic/K=1/Z "SASCALC"
	if(V_flag !=0)
		DoAlert 0,"The SANS Simulation Help file could not be found"
	endif
end

// based on the instrument selected...
// set the SDD range
// set the source aperture popup (based on NGx and number of guides)
// set the wavelength spread popup
//
Function UpdateControls()
	//poll the controls on the panel, and change needed values
	Variable isNG3,Ng,mode

	ControlInfo/W=SASCALC SC_slider
	Ng=V_value
	NVAR gNg = root:Packages:NIST:SAS:gNg
	gNg = Ng		//update the global from the panel
	
	SVAR A1str= root:Packages:NIST:SAS:gSourceApString// = "1.43 cm;2.54 cm;3.81 cm;"
	SVAR dlStr = root:Packages:NIST:SAS:gDeltaLambdaStr
	SVAR selInstr = root:Packages:NIST:SAS:gInstStr
	NVAR lambda = root:Packages:NIST:SAS:gLambda

	strswitch(selInstr)	// string switch
		case "CGB":
		case "NG3":			// 
			switch(ng)	
				case 0:
					ControlInfo/W=SASCALC popup0
					mode=V_value
					A1str="1.43 cm;2.54 cm;3.81 cm;"
					break
	//			case 6:									//Mar 2012 - 6 guides is OK now, 5 cm aperture present in 7th box
	//				A1str = "! 6 Guides invalid;"
	//				mode=1
	//				break
				case 7:							// switched order in 2009 to keep 5 cm as default, 2.5 cm for polarizer
					A1Str = "5.00 cm;2.50 cm;0.95 cm;"		// Mar 2012 - 3rd aperture added
					mode = 1
					break
				default:
					A1str = "5 cm;"
					mode=1
			endswitch
			//wavelength spread
			dlStr = "0.109;0.125;0.236;"		//updated calibration 2009
			Slider SC_Slider win=SASCALC,limits={0,8,1},ticks=1
			//detector limits
			Slider SC_Slider_1,win=SASCALC,limits={133,1317,1},userTicks={root:Packages:NIST:SAS:tickSDDNG3,root:Packages:NIST:SAS:lblSDDNG3 }
			SetVariable setvar0,win=SASCALC,limits={133,1317,1}
			NVAR detDist=root:Packages:NIST:SAS:gDetDist
			if(detDist < 133 )
				detDist = 133
			elseif (detDist > 1317 )
				detDist = 1317
			endif

			// wavelength limits
			SetVariable setvar0_2 win=SASCALC,limits={4,20,0.1}
			if(lambda < 4)
				lambda = 4
			endif
			if(lambda > 20)
				lambda = 20
			endif

			// un-disable the sample table position
			CheckBox checkChamber,win=SASCALC,disable=0
			CheckBox checkHuber,win=SASCALC,disable=0
						
			break
								
		case "NG7":			// 
			switch(ng)	
				case 0:
					ControlInfo/W=SASCALC popup0
					mode=V_value
					A1str="1.43 cm;2.22 cm;3.81 cm;"
					break
				default:
					A1str = "5.08 cm;"
					mode=1
			endswitch
			
			dlStr = "0.09;0.115;0.22;"
			Slider SC_Slider win=SASCALC,limits={0,8,1},ticks=1
			Slider SC_Slider_1,win=SASCALC,limits={100,1531,1},userTicks={root:Packages:NIST:SAS:tickSDDNG7,root:Packages:NIST:SAS:lblSDDNG7 }
			SetVariable setvar0,win=SASCALC,limits={100,1531,1}
			
			if(detDist < 100 )
				detDist = 100
			elseif (detDist > 1531 )
				detDist = 1531
			endif
			// wavelength limits
			SetVariable setvar0_2 win=SASCALC,limits={4,20,0.1}
			if(lambda < 4)
				lambda = 4
			endif
			if(lambda > 20)
				lambda = 20
			endif
						
			// un-disable the sample table position
			CheckBox checkChamber,win=SASCALC,disable=0
			CheckBox checkHuber,win=SASCALC,disable=0
			
			break
			
		case "NGB":		// 10m SANS 
			if(ng>2)
				ng=2
				gNg = Ng		//update the global
			endif
			switch(ng)	
				case 0:
					ControlInfo/W=SASCALC popup0
					mode=V_value
					A1str="1.3 cm;2.5 cm;3.8 cm;"
					break
				default:
					A1str = "5.0 cm;"
					mode=1
			endswitch
			
			dlStr = "0.10;0.132;0.154;0.25;"
			Slider SC_Slider win=SASCALC,limits={0,2,1},ticks=2			//number of guides different on 10m SANS, 3 ticks
			Slider SC_Slider_1,win=SASCALC,limits={106,525,1},userTicks={root:Packages:NIST:SAS:tickSDDNGB,root:Packages:NIST:SAS:lblSDDNGB }
			SetVariable setvar0,win=SASCALC,limits={106,525,1}

			NVAR detDist=root:Packages:NIST:SAS:gDetDist
			if(detDist < 106 )
				detDist = 106
			elseif (detDist > 525 )
				detDist = 525
			endif
			
			// wavelength limits
			SetVariable setvar0_2 win=SASCALC,limits={3,30,0.1}
			if(lambda < 3)
				lambda = 3
			endif
			if(lambda > 30)
				lambda = 30
			endif
					
			// disable the sample table position, as long as the sample positions are identical for the 10 m
			CheckBox checkChamber,win=SASCALC,disable=2
			CheckBox checkHuber,win=SASCALC,disable=2

			break
			
		default:							// optional default expression executed
				DoAlert 0,"No matching instrument!  UpdateControls"					// when no case matches
	endswitch
	
	// force update of the sliders
	Slider SC_Slider,win=SASCALC,variable=root:Packages:NIST:SAS:gNg				//guides
	Slider SC_Slider_1,win=SASCALC,variable=root:Packages:NIST:SAS:gDetDist		//detector distance
	Slider SC_Slider_2,win=SASCALC,variable=root:Packages:NIST:SAS:gOffset		//detector offset


	ControlUpdate popup0
	PopupMenu popup0,win=SASCALC,mode=mode		//source Ap
	ControlInfo/W=SASCALC popup0
	SourceAperturePopMenuProc("",0,S_Value)			//send popNum==0 so recalculation won't be done
	
	ControlUpdate popup0_2		// delta lambda pop
	ControlInfo/W=SASCALC popup0_2
	DeltaLambdaPopMenuProc("",0,S_Value)		//sets the global and the wave
End

//changing the number of guides changes the SSD
// the source aperture popup may need to be updated
//
Function GuideSliderProc(ctrlName,sliderValue,event)
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved
	
	Variable recalc=0
	
	if(event %& 0x1)	// bit 0, value set
		if(cmpstr(ctrlName,"") != 0)		//here by direct action, so do LensCheck and recalculate
			recalc=1
			LensCheckProc("",2)		//make sure lenses are deselected
		endif
		sourceToSampleDist()		//updates the SSD global and wave
		//change the sourceAp popup, SDD range, etc
		UpdateControls()				// the Ng global is actually set inside this function
		ReCalculateInten(recalc)
	endif
	return 0
End

// changing the detector position changes the SDD
//
Function DetDistSliderProc(ctrlName,sliderValue,event)
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	Variable recalc=0
	if(event %& 0x1)	// bit 0, value set
		if(cmpstr(ctrlName,"") != 0)
			recalc=1
			LensCheckProc("",2)		//make sure lenses are only selected for valid configurations
		endif
		sampleToDetectorDist()		//changes the SDD and wave (DetDist is the global)
		ReCalculateInten(recalc)
	endif

	return 0
End

// change the offset
// - changes the beamcenter (x,y) position too
Function OffsetSliderProc(ctrlName,sliderValue,event)
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	if(event %& 0x1)	// bit 0, value set
		detectorOffset()
		ReCalculateInten(1)
	endif

	return 0
End

// changing the instrument - 
// re-initialize the global values
// update the controls to appropriate limits/choices
//
// updated for 10m SANS
Function SelectInstrumentCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked


	strswitch(ctrlName)	// string switch
		case "checkCGB":			// 
			checkBox checkCGB,win=SASCALC, value=1
			checkBox checkNG7,win=SASCALC, value=0
			checkBox checkNGB,win=SASCALC, value=0
			initNG3()
			break	
//		case "checkNG3":			// 
//			checkBox checkNG3,win=SASCALC, value=1
//			checkBox checkNG7,win=SASCALC, value=0
//			checkBox checkNGB,win=SASCALC, value=0
//			initNG3()
//			break						
		case "checkNG7":			// 
//			checkBox checkNG3,win=SASCALC, value=0
			checkBox checkCGB,win=SASCALC, value=0
			checkBox checkNG7,win=SASCALC, value=1
			checkBox checkNGB,win=SASCALC, value=0 
			initNG7()
			break
		case "checkNGB":		// 10m SANS
//			checkBox checkNG3,win=SASCALC, value=0
			checkBox checkCGB,win=SASCALC, value=0
			checkBox checkNG7,win=SASCALC, value=0 
			checkBox checkNGB,win=SASCALC, value=1
			initNGB()
			break
		default:							// optional default expression executed
									// when no case matches
	endswitch


	LensCheckProc("",2)		//check if lenses are still valid (they won't be)
	UpdateControls()
	ReCalculateInten(1)
End

//changing the table position 
// changes the SSD and SDD
Function TableCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	NVAR table=root:Packages:NIST:SAS:gTable
	if(cmpstr(ctrlName,"checkHuber")==0)
		checkBox checkHuber,win=SASCALC, value=1
		checkBox checkChamber,win=SASCALC, value=0
		table=1		//in Huber position
	else
		checkBox checkHuber,win=SASCALC, value=0
		checkBox checkChamber,win=SASCALC, value=1 
		table = 2 		//in Sample chamber
	endif
	sampleToDetectorDist()
	sourceToSampleDist()		//update
	ReCalculateInten(1)
End


//lenses (or prisms) in/out changes resolution
//
// passing in a checked == 2 will do a check of the configuration without
// affecting the box state
//
// if an invalid configuration is detected, the box is unchecked
// and the lens flag is set to zero (=out).
//
// When necessary controls are "popped", a ctrlName="" is passed to signal the control
// to NOT recalculate the intensity, and to NOT (recursively) call LensCheckProc again
//
// currently, the 17.2 A for lens/prism @ ng3 must be typed in
//
Function LensCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	// don't let the box get checked if the conditions are wrong
	// lambda != 8.09,8.4,17.2
	// Ng != 0
	NVAR lens = root:Packages:NIST:SAS:gUsingLenses
	NVAR ng = root:Packages:NIST:SAS:gNg
	NVAR lam = root:Packages:NIST:SAS:gLambda
	NVAR dist = root:Packages:NIST:SAS:gDetDist
//	NVAR instrument = root:Packages:NIST:SAS:instrument
	Wave rw=root:Packages:NIST:SAS:realsRead
	
	SVAR selInstr = root:Packages:NIST:SAS:gInstStr
		
	// directly uncheck the box, just set the flag and get out
	if(checked == 0)
		lens = 0
		CheckBox checkLens,win=SASCALC,value=0
		rw[28]=0		//flag for lenses out
		ReCalculateInten(1)
		return(0)
	endif
	
	// check the box, enforce the proper conditions
	if(checked == 1)
		lens = checked	
		strswitch(selInstr)	// string switch
			case "CGB":
			case "NG3":
				dist = 1317
				DetDistSliderProc("",1317,1)
				
				lam = 8.4
				LambdaSetVarProc("",8.4,"8.4","") 
	
				ng=0
				Slider SC_Slider,win=SASCALC,variable=root:Packages:NIST:SAS:gNg
				GuideSliderProc("",0,1)

				PopupMenu popup0,win=SASCALC,mode=1,popvalue="1.43 cm"		//first item in source aperture menu
				
				PopupMenu popup0_2,win=SASCALC,mode=2		//deltaLambda
				ControlInfo/W=SASCALC popup0_2
				DeltaLambdaPopMenuProc("",0,S_value)			//zero as 2nd param skips recalculation
				rw[28]=1		//flag for lenses in (not the true number, but OK)
		
				break
			case "NG7":
				dist = 1531
				DetDistSliderProc("",1531,1)
				
				lam = 8.09
				LambdaSetVarProc("",8.09,"8.09","") 
				
				ng=0
				Slider SC_Slider,win=SASCALC,variable=root:Packages:NIST:SAS:gNg
				GuideSliderProc("",0,1)
				
				PopupMenu popup0,win=SASCALC,mode=1,popvalue="1.43 cm"		//first item
				
				PopupMenu popup0_2,win=SASCALC,mode=2		//deltaLambda
				ControlInfo/W=SASCALC popup0_2
				DeltaLambdaPopMenuProc("",0,S_value)			//zero as 2nd param skips recalculation
				rw[28]=1		//flag for lenses in (not the true number, but OK)
				
				break
			case "NGB":
				// 10m SANS - force no lenses for now
				// TODO:  -- put in CORRECT VALUES -- THESE ARE FICTIONAL
				lens = 0		//no lenses
				CheckBox checkLens,win=SASCALC,value=0
				rw[28]=0		//flag for lenses out

				break
			default:
				DoAlert 0,"No matching instrument! LCP"
		endswitch
	endif
	
	// this is my internal check to see if conditions are still valid
	// I get to this point by calling this myself and passing the fictional value of (2) for the
	// checkbox value...
	//
	
	// I'll uncheck as needed
	Variable lensNotAllowed=0
	if(checked == 2)

		// source aperture must be 1.43 cm diameter
		// number of guides must be zero
		Variable a1 = sourceApertureDiam()
		if(a1 != 1.43  || Ng !=0)
			lensNotAllowed=1
		endif
	
		// instrument specific distance requirements
//		if(cmpstr(selInstr,"NG3") == 0 && dist != 1317)
		if(cmpstr(selInstr,"CGB") == 0 && dist != 1317)
			lensNotAllowed=1
		endif
	
		if(cmpstr(selInstr,"NG7") == 0 && dist != 1531)
			lensNotAllowed=1
		endif
		
		// instrument specific wavelength requirements
//		if(cmpstr(selInstr,"NG3") == 0 && !(lam == 8.4 || lam == 17.2) )
		if(cmpstr(selInstr,"CGB") == 0 && !(lam == 8.4 || lam == 17.2) )
			lensNotAllowed=1
		endif
		
		if(cmpstr(selInstr,"NG7") == 0 && lam != 8.09 )
			lensNotAllowed=1
		endif

	// right now, if 10m instrument, no lenses allowed		
		if(cmpstr(selInstr,"NGB") == 0)
			lensNotAllowed=1
		endif
		
	endif
	
	if(lensNotAllowed)
		lens = 0
		CheckBox checkLens,win=SASCALC,value=0
		rw[28]=0		//flag for lenses out
		return(0)
	endif

	ReCalculateInten(1)


	return(1)		//return value not used
End

//
//simulation controls as a control bar that toggles on/off to the right
//
// depending on the state of the 2D flag, open the 1d or 2d control panel
// AND - if doing simulation, check first that the Analysis package is loaded - otheriwse lots of errors
Function SimCheckProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct


	if(CB_Struct.checked)
		if(exists("SANS_ANA_VERSION")!=2)		//if the analysis package is not loaded
			// be sure that the SANS Analysis is loaded and compiles
			NCNR_AnalysisLoader("Load NCNR Analysis Macros")
		endif
		
		NVAR do2D = root:Packages:NIST:SAS:gDoMonteCarlo
		
		if((CB_Struct.eventMod & 2^1) != 0 )		//if the shift key is down (bit 1)- go to 2D mode
			do2D = 1
		endif
		
		if(do2D)
			DoWindow/F MC_SASCALC
			if(V_flag==0)
				Execute "MC_SASCALC()"		//sets the variable
				AutoPositionWindow/M=1/R=SASCALC MC_SASCALC
			endif
		else
			//draw 1D panel
			DoWindow/F Sim_1D_Panel
			if(V_flag==0)
				Execute "Sim_1D_Panel()"
				AutoPositionWindow/M=1/R=SASCALC Sim_1D_Panel
			endif
		endif
		NVAR doSim = root:Packages:NIST:SAS:doSimulation
		doSim=1
	else
		//get rid of the controls (just try both)
		DoWindow MC_SASCALC
		if(V_flag!=0)
			NVAR do2D = root:Packages:NIST:SAS:gDoMonteCarlo
			do2D = 0
			KillWindow MC_SASCALC
		endif
		DoWindow Sim_1D_Panel
		if(V_flag!=0)
			KillWindow Sim_1D_Panel
		endif
		
		NVAR doSim = root:Packages:NIST:SAS:doSimulation
		doSim=0
	endif

	return(0)
End

//
// change the source aperture
// 
Function SourceAperturePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Variable a1 = sourceApertureDiam()		//sets the new value in the wave
	
	// if LensCheckProc is calling this, don't call it again.
	// if this is called by a direct pop, then check
	if(cmpstr(ctrlName,"") != 0)
		LensCheckProc("",2)		//make sure lenses are only selected for valid configurations
	endif
	
	ReCalculateInten(popnum)		//skip the recalculation if I pass in a zero
End

// set sample aperture
//
Function SampleAperturePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	sampleApertureDiam()
	ReCalculateInten(1)
End

// set sample to detector distance
//
Function SDDSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	sampleToDetectorDist()
	if(cmpstr(ctrlName,"") != 0)
		LensCheckProc("",2)		//make sure lenses are only selected for valid configurations
	endif
	ReCalculateInten(1)
End

// set offset
// -- also changes the beamcenter (x,y)
//
Function OffsetSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	detectorOffset()		//sets the offset in the wave and also the new (x,y) beamcenter
	
	ReCalculateInten(1)
	return(0)
End

// change the wavelength
Function LambdaSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

//	WAVE rw=root:Packages:NIST:SAS:realsRead
	Variable recalc=0
	
//	rw[26] = str2num(varStr)
	if(cmpstr(ctrlName,"") != 0)
		recalc=1
		LensCheckProc("",2)		//make sure lenses are only selected for valid configurations
	endif
	ReCalculateInten(recalc)
	return(0)
End

// get the wavelength from the panel control
Function getSASCALCWavelength()

	ControlInfo setvar0_2
	Variable val=V_Value
	return(val)
End

// get the wavelength spread from the global
Function getSASCALCWavelengthSpread()

	NVAR val=root:Packages:NIST:SAS:gDeltaLambda
	return(val)
End


// change the wavelength spread
Function DeltaLambdaPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	NVAR dl=root:Packages:NIST:SAS:gDeltaLambda
	dl=str2num(popStr)
//	WAVE rw=root:Packages:NIST:SAS:realsRead
//	rw[27] = dl
	ReCalculateInten(popnum)		//skip the calculation if I pass in  zero
	return(0)
End


// a stored value in [mm]
// HARD-WIRED at the tube value of 8.4 mm
//
// TODO -- add this to the "initialize space" section
//
Function getSASCALX_x_pix_size()

	Variable val = 8.4
	return(val)
end

// calculate the intensity
// - either do MC or the straight calculation.
//
// *****currently the smeared calculation is turned off, by not prepending "fSmeared" to the FUNCREFs)
// --- the random deviate can't be calculated for the smeared model since I don't know the resolution
// function over an infinite q-range, just the detector. Maybe the interpolation is OK, but I
// don't really have a good way of testing this. Also, the resolution calculation explicitly multiplies
// by fShad, and this wrecks the random deviate calculation. The 2D looks great, but the probabilities
// are all wrong. fShad is only appropriate post-simulation.
//
//
// (--NO--) ALWAYS DOES THE RESOLUTION SMEARED CALCULATION
//  even though the unsmeared model is plotted. this is more realistic to 
//  present to users that are planning base on what they will see in an experiment.
//
// some bits of the calculation are in a root:Simulation folder that are needed for the resolution smeared calculation
// all other bits (as possible) are in the SAS folder (a 2D work folder)
//
// passing in one does the calculation, "normal" or MC, depending on the global. Normal calculation is the default
// passing in zero from a control skips the calculation
//
Function ReCalculateInten(doIt)
	Variable doIt
	
	if(doIt==0)			
		return(0)
	endif
	
	// update the wave with the beamstop diameter here, since I don't know what
	// combinations of parameters will change the BS - but anytime the curve is 
	// recalculated, or the text displayed, the right BS must be present
	beamstopDiam()
	
	// generate the resolution waves first, so they are present for a smearing calculation
	// average the "fake" 2d data now to generate the smearing information
	S_CircularAverageTo1D("SAS")
	WAVE aveint=root:Packages:NIST:SAS:aveint
	WAVE qval=root:Packages:NIST:SAS:qval
	WAVE sigave=root:Packages:NIST:SAS:sigave
	WAVE SigmaQ=root:Packages:NIST:SAS:sigmaQ
	WAVE qbar=root:Packages:NIST:SAS:qbar
	WAVE fSubS=root:Packages:NIST:SAS:fSubS
	
	//generate a "fake" 1d data folder/set named "Simulation"
	Fake1DDataFolder(qval,aveint,sigave,sigmaQ,qbar,fSubs,"Simulation")
	
	// do the simulation here, or not
	Variable r1,xCtr,yCtr,sdd,pixSize,wavelength
	String coefStr,abortStr,str

	// now the cases are: simulation (0|1), 1D (default) or 2D (hidden)
	NVAR doMonteCarlo = root:Packages:NIST:SAS:gDoMonteCarlo		// == 1 if 2D MonteCarlo set by hidden flag
	NVAR doSimulation = root:Packages:NIST:SAS:doSimulation		// == 1 if 1D simulated data, 0 if other from the checkbox
	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just a time estimate, == 0 (default) to do the simulation
	NVAR g_estimatedMCTime = root:Packages:NIST:SAS:g_estimatedMCTime		// estimated MC sim time
	SVAR funcStr = root:Packages:NIST:SAS:gFuncStr		//set by the popup

	if(doSimulation == 1)
		if(doMonteCarlo == 1)
			//2D simulation (in MultiScatter_MonteCarlo_2D.ipf)
			
			g_estimatedMCTime = Simulate_2D_MC(funcStr,aveint,qval,sigave,sigmaq,qbar,fsubs,g_estimateOnly)
			
			//end 2D simulation
		else
			//1D simulation
			
			if(exists(funcStr) != 0)
				
				Simulate_1D(funcStr,aveint,qval,sigave,sigmaq,qbar,fsubs)
				
			else
				//no function plotted, no simulation can be done
				DoAlert 0,"No function is selected or plotted, so no simulation is done. The default Debye function is used."
		
				aveint = S_Debye(1000,100,0.0,qval)
				aveint *= fSubS		// multiply either estimate by beamstop shadowing
				sigave = 0		//reset for model calculation
			endif
			
		endif // end 1D simulation
	else
		//no simulation
		
		aveint = S_Debye(1000,100,0.0,qval)
		aveint *= fSubS		// multiply either estimate by beamstop shadowing
		sigave = 0		//reset for model calculation
		
		//end no simulation	
	endif
	

	//display the configuration text in a separate notebook
	DisplayConfigurationText()
	
	return(0)
End

//freezes the current configuration
// -1- duplicates the trace on the graph
// -2- copies the configuration text to a second notebook window for printing
Function FreezeButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String str=""
	NVAR ct=root:Packages:NIST:SAS:gFreezeCount
	
	
	SetDataFolder root:Packages:NIST:SAS
	
	Duplicate/O aveint,$("aveint_"+num2str(ct))
	Duplicate/O qval,$("qval_"+num2str(ct))
	Duplicate/O sigave,$("sigave_"+num2str(ct))
	Appendtograph $("aveint_"+num2str(ct)) vs $("qval_"+num2str(ct))
	ModifyGraph mode($("aveint_"+num2str(ct)))=3
	ModifyGraph marker($("aveint_"+num2str(ct)))=19
	ModifyGraph msize($("aveint_"+num2str(ct)))=2
	ErrorBars/T=0 $("aveint_"+num2str(ct)) Y,wave=($("sigave_"+num2str(ct)),$("sigave_"+num2str(ct)))
	NICEConfigText(ct) //create NICE configuration string variables
	
	
	switch(mod(ct,10))	// 10 different colors - black is the unfrozen color
		case 0:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(65535,16385,16385)
			break
		case 1:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(2,39321,1)
			break
		case 2:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(0,0,65535)
			break
		case 3:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(39321,1,31457)
			break
		case 4:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(48059,48059,48059)
			break
		case 5:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(65535,32768,32768)
			break
		case 6:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(0,65535,0)
			break
		case 7:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(16385,65535,65535)
			break
		case 8:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(65535,32768,58981)
			break
		case 9:
			ModifyGraph rgb($("aveint_"+num2str(ct)))=(36873,14755,58982)
			break
	endswitch
	
	NVAR doTraceOffset = root:Packages:NIST:SAS:gDoTraceOffset
	NVAR offset = root:Packages:NIST:SAS:gModelOffsetFactor
	if(doTraceOffset)
		offset = 2^ct
		//multiply by current offset (>=1)
		Wave inten = $("aveint_"+num2str(ct))
		inten *= offset
		//	Print "new offset = ",offset
	endif
	
	ct +=1
	SetDataFolder root:
	
	// create or append the configuration to a new notebook
	if(WinType("Saved_Configurations")==0)
		NewNotebook/F=1/N=Saved_Configurations /W=(480,400,880,725)
		DoWindow/F SASCALC		//return focus to SASCALC window
	endif
	//append the text
	sprintf str,"\rConfiguration #%d\r",ct-1
	Notebook Saved_Configurations showRuler=0,defaultTab=20,selection={endOfFile, endOfFile}
	Notebook Saved_Configurations font="Monaco",fSize=10,fstyle=1,text=str		//bold
	Notebook Saved_Configurations font="Monaco",fSize=10,fstyle=0,text=SetConfigurationText()
	return(0)
End

//clears the frozen traces on the graph, asks if you want to clear the saved text
//
Function S_ClearButtonProc(ctrlName) : ButtonControl
	String ctrlName

	NVAR ct=root:Packages:NIST:SAS:gFreezeCount
	Variable ii
	Setdatafolder root:Packages:NIST:SAS
	for(ii=ct-1;ii>=1;ii-=1)
	//remove all traces, replace aveint
	// kill all waves _ct
		RemoveFromGraph $("aveint_"+num2str(ii))
		Killwaves/Z $("aveint_"+num2str(ii)),$("qval_"+num2str(ii))
		KillStrings/Z $("nice_config_s_"+num2str(ii)),$("nice_config_t_"+num2str(ii)) //Kill NICE configuration string variables
	endfor
	ct=1
	setdatafolder root:
	
	DoAlert 1,"Do you also want to clear the \"Saved Configurations\" text?"
	if(V_flag == 1)		// yes
		DoWindow/K Saved_Configurations
	endif
	
	//reset offset value
	NVAR offset = root:Packages:NIST:SAS:gModelOffsetFactor
	offset = 1
	ReCalculateInten(1)
	return(0)
End


///////////////////////////////////////////////////////////
// 19MAR07 uses correction for beamstop diameter projection to get shadow factor correct
//
Function S_CircularAverageTo1D(type)
	String type
	
	Variable isCircular = 1
	
	//type is the data type to do the averaging on, and will be set as the current folder
	//get the current displayed data (so the correct folder is used)
	String destPath = "root:Packages:NIST:"+type
	
	//
	Variable xcenter,ycenter,x0,y0,sx,sx3,sy,sy3,dtsize,dtdist,dr,ddr
	Variable lambda,trans
	WAVE reals = $(destPath + ":RealsRead")
//	WAVE/T textread = $(destPath + ":TextRead")
//	String fileStr = textread[3]
	
	// center of detector, for non-linear corrections
	Variable pixelsX=128,pixelsY=128
	
	xcenter = pixelsX/2 + 0.5		// == 64.5 for 128x128 Ordela
	ycenter = pixelsY/2 + 0.5		// == 64.5 for 128x128 Ordela
	
	// beam center, in pixels
	x0 = reals[16]
	y0 = reals[17]
	//detector calibration constants
	sx = reals[10]		//mm/pixel (x)
	sx3 = reals[11]		//nonlinear coeff
	sy = reals[13]		//mm/pixel (y)
	sy3 = reals[14]		//nonlinear coeff
	
	dtsize = 10*reals[20]		//det size in mm
	dtdist = 1000*reals[18]		// det distance in mm
	
	NVAR binWidth=root:Packages:NIST:gBinWidth
//	Variable binWidth = 1
	
	dr = binWidth		// ***********annulus width set by user, default is one***********
	ddr = dr*sx		//step size, in mm (this value should be passed to the resolution calculation, not dr 18NOV03)
		
	Variable rcentr,large_num,small_num,dtdis2,nq,xoffst,dxbm,dybm,ii
	Variable phi_rad,dphi_rad,phi_x,phi_y
	Variable forward,mirror
	
	String side = "both"
//	side = StringByKey("SIDE",keyListStr,"=",";")
//	Print "side = ",side
	
	/// data wave is data in the current folder which was set at the top of the function
	Wave data = getDetectorDataW(type)		//this will be the linear data

// fake mask that uses all of the detector
	Make/D/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
	Wave mask = $(destPath + ":mask")
	mask = 0
	//three pixels all around
	mask[0,2][] = 1
	mask[125,127][] = 1
	mask[][0,2] = 1
	mask[][125,127] = 1
	//
	//pixels within rcentr of beam center are broken into 9 parts (units of mm)
	rcentr = 100		//original
//	rcentr = 0
	// values for error if unable to estimate value
	//large_num = 1e10
	large_num = 1		//1e10 value (typically sig of last data point) plots poorly, arb set to 1
	small_num = 1e-10
	
	// output wave are expected to exist (?) initialized to zero, what length?
	// 200 points on VAX --- use 300 here, or more if SAXS data is used with 1024x1024 detector (1000 pts seems good)
	Variable defWavePts=500
	Make/O/D/N=(defWavePts) $(destPath + ":qval"),$(destPath + ":aveint")
	Make/O/D/N=(defWavePts) $(destPath + ":ncells"),$(destPath + ":dsq"),$(destPath + ":sigave")
	Make/O/D/N=(defWavePts) $(destPath + ":SigmaQ"),$(destPath + ":fSubS"),$(destPath + ":QBar")

	WAVE qval = $(destPath + ":qval")
	WAVE aveint = $(destPath + ":aveint")
	WAVE ncells = $(destPath + ":ncells")
	WAVE dsq = $(destPath + ":dsq")
	WAVE sigave = $(destPath + ":sigave")
	WAVE qbar = $(destPath + ":QBar")
	WAVE sigmaq = $(destPath + ":SigmaQ")
	WAVE fsubs = $(destPath + ":fSubS")
	
	qval = 0
	aveint = 0
	ncells = 0
	dsq = 0
	sigave = 0
	qbar = 0
	sigmaq = 0
	fsubs = 0

	dtdis2 = dtdist^2
	nq = 1
	xoffst=0
	//distance of beam center from detector center
	dxbm = S_FX(x0,sx3,xcenter,sx)
	dybm = S_FY(y0,sy3,ycenter,sy)
		
	//BEGIN AVERAGE **********
	Variable xi,dxi,dx,jj,data_pixel,yj,dyj,dy,mask_val=0.1
	Variable dr2,nd,fd,nd2,ll,kk,dxx,dyy,ir,dphi_p
	
	// IGOR arrays are indexed from [0][0], FORTAN from (1,1) (and the detector too)
	// loop index corresponds to FORTRAN (old code) 
	// and the IGOR array indices must be adjusted (-1) to the correct address
	ii=1
	do
		xi = ii
		dxi = S_FX(xi,sx3,xcenter,sx)
		dx = dxi-dxbm		//dx and dy are in mm
		
		jj = 1
		do
			data_pixel = data[ii-1][jj-1]		//assign to local variable
			yj = jj
			dyj = S_FY(yj,sy3,ycenter,sy)
			dy = dyj - dybm
			if(!(mask[ii-1][jj-1]))			//masked pixels = 1, skip if masked (this way works...)
				dr2 = (dx^2 + dy^2)^(0.5)		//distance from beam center NOTE dr2 used here - dr used above
				if(dr2>rcentr)		//keep pixel whole
					nd = 1
					fd = 1
				else				//break pixel into 9 equal parts
					nd = 3
					fd = 2
				endif
				nd2 = nd^2
				ll = 1		//"el-el" loop index
				do
					dxx = dx + (ll - fd)*sx/3
					kk = 1
					do
						dyy = dy + (kk - fd)*sy/3
						if(isCircular)
							//circular average, use all pixels
							//(increment) 
							nq = S_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
						else
							//a sector average - determine azimuthal angle
							dphi_p = S_dphi_pixel(dxx,dyy,phi_x,phi_y)
							if(dphi_p < dphi_rad)
								forward = 1			//within forward sector
							else
								forward = 0
							Endif
							if((Pi - dphi_p) < dphi_rad)
								mirror = 1		//within mirror sector
							else
								mirror = 0
							Endif
							//check if pixel lies within allowed sector(s)
							if(cmpstr(side,"both")==0)		//both sectors
								if ( mirror || forward)
									//increment
									nq = S_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
								Endif
							else
								if(cmpstr(side,"right")==0)		//forward sector only
									if(forward)
										//increment
										nq = S_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
									Endif
								else			//mirror sector only
									if(mirror)
										//increment
										nq = S_IncrementPixel(data_pixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
									Endif
								Endif
							Endif		//allowable sectors
						Endif	//circular or sector check
						kk+=1
					while(kk<=nd)
					ll += 1
				while(ll<=nd)
			Endif		//masked pixel check
			jj += 1
		while (jj<=pixelsY)
		ii += 1
	while(ii<=pixelsX)		//end of the averaging
		
	//compute q-values and errors
	Variable ntotal,rr,theta,avesq,aveisq,var
	
	lambda = reals[26]
	ntotal = 0
	kk = 1
	do
		rr = (2*kk-1)*ddr/2
		theta = 0.5*atan(rr/dtdist)
		qval[kk-1] = (4*Pi/lambda)*sin(theta)
		if(ncells[kk-1] == 0)
			//no pixels in annuli, data unknown
			aveint[kk-1] = 0
			sigave[kk-1] = large_num
		else
			if(ncells[kk-1] <= 1)
				//need more than one pixel to determine error
				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
				sigave[kk-1] = large_num
			else
				//assume that the intensity in each pixel in annuli is normally
				// distributed about mean...
				aveint[kk-1] = aveint[kk-1]/ncells[kk-1]
				avesq = aveint[kk-1]^2
				aveisq = dsq[kk-1]/ncells[kk-1]
				var = aveisq-avesq
				if(var<=0)
//					sigave[kk-1] = small_num
					sigave[kk-1] = large_num		//if there are zero counts, make error large_num to be a warning flag
				else
					sigave[kk-1] = sqrt(var/(ncells[kk-1] - 1))
				endif
			endif
		endif
		ntotal += ncells[kk-1]
		kk+=1
	while(kk<=nq)
	
	//Print "NQ = ",nq
	// data waves were defined as 300 points (=defWavePts), but now have less than that (nq) points
	// use DeletePoints to remove junk from end of waves
	//WaveStats would be a more foolproof implementation, to get the # points in the wave
	Variable startElement,numElements
	startElement = nq
	numElements = defWavePts - startElement
	DeletePoints startElement,numElements, qval,aveint,ncells,dsq,sigave
	
	//////////////end of VAX sector_ave()
		


// ***************************************************************
//
// Do the extra 3 columns of resolution calculations starting here.
//
// ***************************************************************

	Variable L2 = reals[18]
	Variable BS = reals[21]		//this the diameter is stored in mm
//  SRK - why was I using the projected diameter of the beam stop?? I added a step at the beginning of every recalculation
// of the intensity to get the right beamstop diameter into RealsRead...
//	Variable BS = beamstopDiamProjection(1) * 10		//calculated projection in cm *10 = mm
	Variable S1 = reals[23]
	Variable S2 = reals[24]
	Variable L1 = reals[25]
	lambda = reals[26]
	Variable lambdaWidth = reals[27]

	Variable DDet, apOff
	//typical value for NG3 and NG7 - distance between sample aperture and sample in (cm)
	apOff=5.0
	// hard wire value for Ordela detectors
	DDet = 0.5		// resolution in cm
	//	String detStr=textRead[9]
	//	DDet = DetectorPixelResolution(fileStr,detStr)		//needs detector type and beamline

	//Go from 0 to nq doing the calc for all three values at
	//every Q value

	ii=0
	Variable ret1,ret2,ret3
	do
		S_getResolution(qval[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,ddr,ret1,ret2,ret3)
		sigmaq[ii] = ret1	//res_wave[0]
		qbar[ii] = ret2		//res_wave[1]
		fsubs[ii] = ret3		//res_wave[2]
		ii+=1
	while(ii<nq)
	DeletePoints startElement,numElements, sigmaq, qbar, fsubs

	fsubs += 1e-8		//keep the values from being too small

// End of resolution calculations
// ***************************************************************
	
	//get rid of the default mask, if one was created (it is in the current folder)
	//don't just kill "mask" since it might be pointing to the one in the MSK folder
	Killwaves/Z $(destPath+":mask")
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return 0
End

//returns nq, new number of q-values
//arrays aveint,dsq,ncells are also changed by this function
//
Function S_IncrementPixel(dataPixel,ddr,dxx,dyy,aveint,dsq,ncells,nq,nd2)
	Variable dataPixel,ddr,dxx,dyy
	Wave aveint,dsq,ncells
	Variable nq,nd2
	
	Variable ir
	
	ir = trunc(sqrt(dxx*dxx+dyy*dyy)/ddr)+1
	if (ir>nq)
		nq = ir		//resets maximum number of q-values
	endif
	aveint[ir-1] += dataPixel/nd2		//ir-1 must be used, since ir is physical
	dsq[ir-1] += dataPixel*dataPixel/nd2
	ncells[ir-1] += 1/nd2
	
	Return nq
End

//function determines azimuthal angle dphi that a vector connecting
//center of detector to pixel makes with respect to vector
//at chosen azimuthal angle phi -> [cos(phi),sin(phi)] = [phi_x,phi_y]
//dphi is always positive, varying from 0 to Pi
//
Function S_dphi_pixel(dxx,dyy,phi_x,phi_y)
	Variable dxx,dyy,phi_x,phi_y
	
	Variable val,rr,dot_prod
	
	rr = sqrt(dxx^2 + dyy^2)
	dot_prod = (dxx*phi_x + dyy*phi_y)/rr
	//? correct for roundoff error? - is this necessary in IGOR, w/ double precision?
	if(dot_prod > 1)
		dot_prod =1
	Endif
	if(dot_prod < -1)
		dot_prod = -1
	Endif
	
	val = acos(dot_prod)
	
	return val

End

//calculates the x distance from the center of the detector, w/nonlinear corrections
//
Function S_FX(xx,sx3,xcenter,sx)		
	Variable xx,sx3,xcenter,sx
	
	Variable retval
	
	retval = sx3*tan((xx-xcenter)*sx/sx3)
	Return retval
End

//calculates the y distance from the center of the detector, w/nonlinear corrections
//
Function S_FY(yy,sy3,ycenter,sy)		
	Variable yy,sy3,ycenter,sy
	
	Variable retval
	
	retval = sy3*tan((yy-ycenter)*sy/sy3)
	Return retval
End

//**********************
// Resolution calculation - used by the averaging routines
// to calculate the resolution function at each q-value
// - the return value is not used
//
// equivalent to John's routine on the VAX Q_SIGMA_AVE.FOR
// Incorporates eqn. 3-15 from J. Appl. Cryst. (1995) v. 28 p105-114
//
Function/S S_getResolution(inQ,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,SigmaQ,QBar,fSubS)
	Variable inQ, lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r
	Variable &fSubS, &QBar, &SigmaQ		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, q_small, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	//Variable del_r = .1
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]

	String results
	results ="Failure"
	
	NVAR usingLenses = root:Packages:NIST:SAS:gUsingLenses

	//rename for working variables,  these must be gotten from global
	//variables

//	Variable wLam, wLW, wL1, wL2, wS1, wS2
//	Variable wBS, wDDet, wApOff
//	wLam = lambda
//	wLW = lambdaWidth
//	wDDet = DDet
//	wApOff = apOff
	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff

	BS *= 0.5*0.1			//convert to radius and [cm]
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	q_small = 2.0*Pi*(BS-a2)*(1.0-lambdaWidth)/(lambda*L2)
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
	if(usingLenses==1)			//SRK 2007
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

Function S_Debye(scale,rg,bkg,x)
	Variable scale,rg,bkg
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of gyration [A]
	//[2] background	[cm-1]
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add in the background
	return (Pq+bkg)
End


Function S_SphereForm(scale,radius,delrho,bkg,x)				
	Variable scale,radius,delrho,bkg
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (A)
	//[2] delrho (A-2)
	//[3] background (cm-1)
	
//	Variable scale,radius,delrho,bkg				
//	scale = w[0]
//	radius = w[1]
//	delrho = w[2]
//	bkg = w[3]
	
	
	// calculates scale * f^2/Vol where f=Vol*3*delrho*((sin(qr)-qrcos(qr))/qr^3
	// and is rescaled to give [=] cm^-1
	
	Variable bes,f,vol,f2
	//
	//handle q==0 separately
	If(x==0)
		f = 4/3*pi*radius^3*delrho*delrho*scale*1e8 + bkg
		return(f)
	Endif
	
	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3
	vol = 4*pi/3*radius^3
	f = vol*bes*delrho		// [=] A
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8		// [=] 1/cm
	
	return (scale*f2+bkg)	// Scale, then add in the background
	
End

Function/S SetConfigurationText()

	String str="",temp

	SetDataFolder root:Packages:NIST:SAS
	
	NVAR numberOfGuides=gNg
	NVAR gTable=gTable		//2=chamber, 1=table
	NVAR wavelength=gLambda
	NVAR lambdaWidth=gDeltaLambda
//	NVAR instrument = instrument
	NVAR L2diff = L2diff
   NVAR lens = root:Packages:NIST:SAS:gUsingLenses
	SVAR/Z aStr = root:Packages:NIST:gAngstStr
	SVAR selInstr = root:Packages:NIST:SAS:gInstStr

	
	sprintf temp,"Source Aperture Diameter =\t\t%6.2f cm\r",sourceApertureDiam()
	str += temp
	sprintf temp,"Source to Sample =\t\t\t\t%6.0f cm\r",sourceToSampleDist()
	str += temp
	sprintf temp,"Sample Aperture to Detector =\t%6.0f cm\r",sampleToDetectorDist() + L2diff
	str += temp
	sprintf temp,"Beam diameter =\t\t\t\t\t%6.2f cm\r",beamDiameter("maximum")
	str += temp
	sprintf temp,"Beamstop diameter =\t\t\t\t%6.2f inches\r",beamstopDiam()/2.54
	str += temp
	sprintf temp,"Minimum Q-value =\t\t\t\t%6.4f 1/%s (sigQ/Q = %3.1f %%)\r",qMin(),aStr,deltaQ(qMin())
	str += temp
	sprintf temp,"Maximum Horizontal Q-value =\t%6.4f 1/%s\r",qMaxHoriz(),aStr
	str += temp
	sprintf temp,"Maximum Vertical Q-value =\t\t%6.4f 1/%s\r",qMaxVert(),aStr
	str += temp
	sprintf temp,"Maximum Q-value =\t\t\t\t%6.4f 1/%s (sigQ/Q = %3.1f %%)\r",qMaxCorner(),aStr,deltaQ(qMaxCorner())
	str += temp
	sprintf temp,"Beam Intensity =\t\t\t\t%.0f counts/s\r",beamIntensity()
	str += temp
	sprintf temp,"Figure of Merit =\t\t\t\t%3.3g %s^2/s\r",figureOfMerit(),aStr
	str += temp
	sprintf temp,"Attenuator transmission =\t\t%3.3g = Atten # %d\r",attenuatorTransmission(),attenuatorNumber()
	str += temp
//	
//	// add text of the user-edited values
//	//
	sprintf temp,"***************** %s *** %s *****************\r",selInstr,selInstr
	str += temp
	sprintf temp,"Sample Aperture Diameter =\t\t\t\t%.2f cm\r",sampleApertureDiam()
	str += temp
	sprintf temp,"Number of Guides =\t\t\t\t\t\t%d \r", numberOfGuides
	str += temp
	sprintf temp,"Sample Chamber to Detector =\t\t\t%.1f cm\r", chamberToDetectorDist()
	str += temp
	if(gTable==1)
		sprintf temp,"Sample Position is \t\t\t\t\t\tHuber\r"
	else
		sprintf temp,"Sample Position is \t\t\t\t\t\tChamber\r"
	endif 
	str += temp
	sprintf temp,"Detector Offset =\t\t\t\t\t\t%.1f cm\r", detectorOffset()
	str += temp
	sprintf temp,"Neutron Wavelength =\t\t\t\t\t%.2f %s\r", wavelength,aStr
	str += temp
	sprintf temp,"Wavelength Spread, FWHM =\t\t\t\t%.3f\r", lambdaWidth
	str += temp
	sprintf temp,"Sample Aperture to Sample Position =\t%.2f cm\r", L2Diff
   	str += temp
   	if(lens==1)
		sprintf temp,"Lenses are IN\r"
	else
		sprintf temp,"Lenses are OUT\r"
	endif
	str += temp 
   	
   setDataFolder root:
   return str			 
End


//Write String Variables representing NICE SANS configurations.
Function NICEConfigText(ct)
	variable ct
	
	string NICENameS = "nice_config_s_"+num2str(ct)
	string NICENameT = "nice_config_t_"+num2str(ct)

	SetDataFolder root:Packages:NIST:SAS

	string temp_s, temp_t

	NVAR numberOfGuides=gNg
	NVAR wavelength=gLambda
	NVAR lambdaWidth=gDeltaLambda
	
	//example from a working NICE trajectory
	//"'{1.1m5={attenuator.key=0,wavelength.wavelength=\"5Angstrom\",wavelengthSpread.wavelengthSpread=0.132, guide.guide=0, guide.aperture=\"25.4mm\", beamStop.beamStop=\"2\", beamStopX.X=\"0.1cm\", beamStopY.softPosition=\"6.1cm\",beamStop.beamCenterX= 113.3, beamStop.beamCenterY= 62.5, geometry.sampleToDetectorDistance=\"110cm\", detectorOffset.softPosition=\"25cm\"}	

	// Make two configurations, one for Scattering and one for Transmission
	temp_s = ""
	temp_t = ""
	//Give random names
	//TODO: name the configurations when they are "frozen"
	temp_s = "config_"+num2str(ct)+"_s={"
	temp_t = "config_"+num2str(ct)+"_t={"

	temp_s += "attenuator.key="+"0"+","	
	temp_s += "wavelength.wavelength=\\\""+num2str(wavelength)+"Angstrom\\\","
	temp_s += "wavelengthSpread.wavelengthSpread="+num2str(lambdaWidth)+","
	temp_s += "guide.guide="+num2str(numberOfGuides)+","
	temp_s += "guide.aperture=\\\""+num2str(sourceApertureDiam())+"cm\\\"," 
	temp_s += "beamStop.beamStop=\\\""+num2istr(beamstopDiam()/2.54)+"\\\","
	temp_s += "beamStopX.X=\\\""+"0"+"cm\\\","
	temp_s += "beamStopY.softPosition=\\\""+"0"+"cm\\\","
	temp_s += "beamStop.beamCenterX="+num2str(64+detectorOffset()*2)+","
	temp_s += "beamStop.beamCenterY="+"64"+","
	temp_s += "geometry.sampleToDetectorDistance=\\\""+num2str( chamberToDetectorDist())+"cm\\\","
	temp_s += "detectorOffset.softPosition=\\\""+num2str(detectorOffset())+"cm\\\""
	
	temp_t += "attenuator.key="+num2str(attenuatorNumber())+","	
	temp_t += "wavelength.wavelength=\\\""+num2str(wavelength)+"Angstrom\\\","
	temp_t += "wavelengthSpread.wavelengthSpread="+num2str(lambdaWidth)+","
	temp_t += "guide.guide="+num2str(numberOfGuides)+","
	temp_t += "guide.aperture=\\\""+num2str(sourceApertureDiam())+"cm\\\"," 
	temp_t += "beamStop.beamStop=\\\""+num2istr(beamstopDiam()/2.54)+"\\\","
	temp_t += "beamStopX.X=\\\""+"0"+"cm\\\","
	temp_t += "beamStopY.softPosition=\\\""+"0"+"cm\\\","
	temp_t += "beamStop.beamCenterX="+num2str(64+detectorOffset()*2)+","
	temp_t += "beamStop.beamCenterY="+"64"+","
	temp_t += "geometry.sampleToDetectorDistance=\\\""+num2str( chamberToDetectorDist())+"cm\\\","
	temp_t += "detectorOffset.softPosition=\\\""+num2str(detectorOffset())+"cm\\\""
	
	temp_s += "}"
	temp_t += "}"
	
	SetDataFolder root:Packages:NIST:SAS

	string/g $NICENameS = temp_s
	string/g $NICENameT = temp_t
	
	SetDataFolder root:Packages:NIST:SAS

	return (0)
end

//Export NICE SANS configurations to a plain text file.
Function SaveNICEConfigs()

	String str=""
	NVAR ct=root:Packages:NIST:SAS:gFreezeCount
	
	SetDataFolder root:Packages:NIST:SAS
	
	if (ct == 1)
		DoAlert 0, "No Configurations are available"
		return (0)
	endif
		
	str = "{\r"
	string tempNameS, tempNameT
	
	variable i = 1
	do
		tempNameS = "nice_config_s_"+num2str(i)
		tempNameT = "nice_config_t_"+num2str(i)
		SVAR tempS = $tempNameS
		SVAR tempT = $tempNameT
		if (i != 1)
			str += ",\r"
		endif
		str += tempS + ",\r"
		str += tempT
		i +=1
	while (i<ct)
	
	str += "\r"
	str += "}"
	
	NewNotebook/F=1/N=NICE_Configurations /W=(480,400,880,725)
	Notebook NICE_Configurations text=str
	SaveNotebook/S=6/I NICE_Configurations as "NICE_Configs.txt"
	KillWindow NICE_Configurations	
			
	SetDataFolder root:
	return (0)

end

Function DisplayConfigurationText()

	if(WinType("Trial_Configuration")==0)
		NewNotebook/F=0/K=1/N=Trial_Configuration /W=(480,44,880,369)
	endif
	//replace the text
	Notebook Trial_Configuration selection={startOfFile, endOfFile}
	Notebook Trial_Configuration font="Monaco",fSize=10,text=SetConfigurationText()
	return(0)
end

//parses the control for A1 diam
// updates the wave
Function sourceApertureDiam()
	ControlInfo/W=SASCALC popup0
	Variable diam
	sscanf S_Value, "%g cm", diam
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[23] = diam*10			//sample aperture diameter in mm
	return(diam)
end

// change the sample aperture to a non-standard value
Function SampleApOtherSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
		
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[24] = varNum			//sample aperture diameter in mm
	ReCalculateInten(1)
	return(0)
End

//parses the control for A2 diam
// updates the wave and global
// returns a2 in cm
Function sampleApertureDiam()
	ControlInfo/W=SASCALC popup0_1
	
//	Print "In sampleApertureDiam()"
	//set the global
	NVAR a2=root:Packages:NIST:SAS:gSamAp
	
	if(cmpstr(S_Value,"other") == 0)		// "other" selected
		//enable the setvar, diameter in mm!
		SetVariable setvar0_3,win=SASCALC, disable=0
		// read its value (a global)
		NVAR a2other = root:Packages:NIST:SAS:gSamApOther
		a2=a2other/10				//a2 in cm
	else
		SetVariable setvar0_3,win=SASCALC, disable=1
		//1st item is 1/16", popup steps by 1/16"
		a2 = 2.54/16.0 * (V_Value)			//convert to cm		
	endif
//	WAVE rw=root:Packages:NIST:SAS:realsRead
//	rw[24] = a2*10			//sample aperture diameter in mm
	
	return(a2)
end

//1=huber 2=chamber
Function tableposition()
	ControlInfo/W=SASCALC checkHuber
	if(V_Value)
		return(1)		//huber
	else
		return(2)		//chamber
	endif
End

//compute SSD and update both the global and the wave
//
// for the 10m SANS, table position is inline, so S12 = 0
//
//
Function sourceToSampleDist()

	NVAR NG=root:Packages:NIST:SAS:gNg
	NVAR S12 = root:Packages:NIST:SAS:S12
	NVAR L2Diff = root:Packages:NIST:SAS:L2Diff
	NVAR SSD = root:Packages:NIST:SAS:gSSD
//	NVAR instrument = root:Packages:NIST:SAS:instrument
	SVAR selInstr = root:Packages:NIST:SAS:gInstStr

	Variable NGB_gap = 61.9		// extra distance between a1 and beginning of guide 1 on NGB
	
	strswitch(selInstr)	// string switch
		case "CGB":
		case "NG3":
		case "NG7":
			// NG3 and NG7 are both the same
			SSD = 1632 - 155*NG - s12*(2-tableposition()) - L2Diff
			break
		case "NGB":
			// 10m SANS handled differently
			// s12 == 0 by definition
			// -- 16JAN13 - these are now correct values
			if(ng==0)
				SSD = 513 - L2diff
			else			
				SSD = 513 - NGB_gap - 150*NG - s12*(2-tableposition()) - L2Diff
			endif
			break
		default:
			DoAlert 0,"No matching instrument! sourceToSampleDist"
	endswitch

	
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[25] = SSD/100		// in meters
	return(SSD)
End


// not part of SASCALC, but can be used to convert the SSD to number of guides
//
// SSD in meters
//
Function numGuides(SSD)
	variable SSD
	
	Variable Ng
	
	//NVAR instrument = root:Packages:NIST:SAS:instrument
	SVAR selInstr = root:Packages:NIST:SAS:gInstStr

	Variable NGB_gap = 61.9		// extra distance between a1 and beginning of guide 1 on NGB

	strswitch(selInstr)	// string switch
		case "CGB":
		case "NG3":
		case "NG7":
			// NG3 and NG7 are both the same
			Ng = SSD*100 + 5 - 1632
			Ng /= -155
	
			break
		case "NGB":
			// 10m SANS handled differently
			// -- 16JAN13 - these are now correct values
			Ng = 513 - NGB_gap - SSD*100 -5
			Ng /= 150
	
			if(ng < 0)
				ng=0
			endif
			
			break
		default:
			
	endswitch
//	Print "Ng = ",Ng

	Ng = abs(round(Ng))
	return(Ng)
End


//returns the offset value
// slider and setVar are linked to the same global
// updates the wave and changes the beamcenter (x,y) in the wave
//
// does not account for the fall due to gravity in y-direction
Function detectorOffset()
	
	WAVE rw=root:Packages:NIST:SAS:RealsRead
	NVAR val = root:Packages:NIST:SAS:gOffset
	rw[19] = val		// already in cm
	//move the beamcenter, make it an integer value for the MC simulation
	rw[16] = 64  + round(2*rw[19]) //+ 0.5		//approximate beam X is 64 w/no offset, 114 w/25 cm offset 
	rw[17] = 64 	//+ 0.5 //typical value

	return(val)
end

// HARD-WIRED for the middle of a 128 pix X-range, corrected for offset
Function getSASCALCBeamCenter_x()

	NVAR offset = root:Packages:NIST:SAS:gOffset
	Variable val = 64 + round(2*offset)  //approximate beam X is 64 w/no offset, 114 w/25 cm offset
	return(val)
end


// HARD-WIRED for the middle of a 128 pix range in Y
//
Function getSASCALCBeamCenter_y()

	Variable val=64
	return(val)
End


//returns the detector distance (slider and setVar are linked by the global)
//
Function chamberToDetectorDist()

	NVAR val = root:Packages:NIST:SAS:gDetDist
	return(val)
End

//sets the SDD (slider and setVar are linked by the global and is the detector position
//  relative to the chamber)
// updates the wave
// SDD is in [cm]
Function sampleToDetectorDist()

	NVAR detDist = root:Packages:NIST:SAS:gDetDist
	NVAR S12 = root:Packages:NIST:SAS:S12
//	WAVE rw=root:Packages:NIST:SAS:RealsRead	
	Variable SDD	
	
	SDD = detDist + s12*(2-tableposition())
//	rw[18] = SDD/100		// convert to meters for header
	return(SDD)
End

//direction = one of "vertical;horizontal;maximum;"
// all of this is bypassed if the lenses are in
//
// returns beam diameter in [cm]
//
Function beamDiameter(direction)
	String direction

	NVAR lens = root:Packages:NIST:SAS:gUsingLenses
	if(lens)
		return sourceApertureDiam()
	endif
	
    Variable l1 = sourceToSampleDist()
    Variable l2 //= sampleAperToDetDist()
    Variable d1,d2,bh,bv,bm,umbra,a1,a2
    
    NVAR L2diff = root:Packages:NIST:SAS:L2diff
    NVAR lambda = root:Packages:NIST:SAS:gLambda
    NVAR lambda_width = root:Packages:NIST:SAS:gDeltaLambda
    NVAR bs_factor = root:Packages:NIST:SAS:bs_factor
    
    l2 = sampleToDetectorDist() + L2diff
    a1 = sourceApertureDiam()
    a2 = sampleApertureDiam()
    
    d1 = a1*l2/l1
    d2 = a2*(l1+l2)/l1
    bh = d1+d2		//beam size in horizontal direction
    umbra = abs(d1-d2)
    //vertical spreading due to gravity
    bv = bh + 1.25e-8*(l1+l2)*l2*lambda*lambda*lambda_width
    bm = (bs_factor*bh > bv) ? bs_factor*bh : bv //use the larger of horiz*safety or vertical
    
    strswitch(direction)	// string switch
    	case "vertical":		// execute if case matches expression
    		return(bv)
    		break						// exit from switch
    	case "horizontal":		// execute if case matches expression
    		return(bh)
    		break
    	case "maximum":		// execute if case matches expression
    		return(bm)
    		break
    	default:							// optional default expression executed
    		return(bm)						// when no case matches
    endswitch
End

//on NG3 and NG7, allowable sizes are 1,2,3,4" diameter
//
// at the NGB-10m instrument, allowable sizes are 1, 1.5, 2, 3 (inches) ( SRK 2018)
//
//will return values larger than 4.0*2.54 if a larger beam is needed
//
// - in an approximate way, account for lenses
Function beamstopDiam()

	NVAR yesLens = root:Packages:NIST:SAS:gUsingLenses
	Variable bm=0
	Variable bs=0.0,pass=0
 
 	SVAR selInstr = root:Packages:NIST:SAS:gInstStr		// "NG3","NG7","NGB"
   
	if(yesLens)
		//bm = sourceApertureDiam()		//ideal result, not needed
		bs = 1								//force the diameter to 1"
	else
		bm = beamDiameter("maximum")
		do
			if(cmpstr(selInstr,"NGB") == 0)
				pass +=1
				if(pass == 1)
					bs = 1
				endif
				if(pass == 2)
					bs = 1.5
				endif
				if(pass == 3)
					bs = 2
				endif
				if(pass == 4)
					bs = 3
				endif
				if(pass > 4)
					bs += 1
				endif
								
			else
		    	bs += 1			// always add 1" at a time to the beam stop (NG3B-30m and NG7)
	    	endif
	    	
	   while ( (bs*2.54 < bm) || (bs > 30.0)) 			//30 = ridiculous limit to avoid inf loop
	endif

 	//update the wave
 	WAVE rw=root:Packages:NIST:SAS:realsRead
 	rw[21] = bs*25.4		//store the BS diameter in mm
 	
   return (bs*2.54)		//return diameter in cm, not inches for txt
End

//returns the projected diameter of the beamstop at the anode plane.
// most noticeable at short SDD
//if flag == 0 use conservative estimate = largest diameter (for SASCALC, default)
//if flag != 0 use point aperture = average diameter (for resolution calculation)
Function beamstopDiamProjection(flag)
	Variable flag
	
	NVAR L2diff = root:Packages:NIST:SAS:L2diff
	Variable a2 = sampleApertureDiam()
	Variable bs = beamstopDiam()
	Variable l2, LB, BS_P
    
	l2 = sampleToDetectorDist() + L2diff
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	if(flag==0)
		BS_P = bs + (bs+a2)*lb/(l2-lb)		//diameter of shadow from parallax
	else
		BS_P = bs + bs*lb/(l2-lb)		//diameter of shadow, point A2
	endif
	return (bs_p)		//return projected diameter in cm
End

// 19MAR07 - using correction from John for an estimate of the shadow of the beamstop
// at the detection plane. This is a noticeable effect at short SDD, where the projected
// diameter of the beamstop is much larger than the physical diameter.
Function qMin()

    Variable l2s = sampleToDetectorDist()	//distance from sample to detector in cm
//    Variable bs = beamstopDiam()		//beamstop diameter in cm
    Variable bs_p = beamstopDiamProjection(0)		//projected beamstop diameter in cm
    NVAR lambda = root:Packages:NIST:SAS:gLambda
    NVAR d_det = root:Packages:NIST:SAS:d_det		//cm
    NVAR a_pixel = root:Packages:NIST:SAS:a_pixel	//cm

    return( (pi/lambda)*(bs_p + d_det + a_pixel)/l2s )		//use bs_p rather than bs
   // return( (pi/lambda)*(bs + d_det + a_pixel)/l2s )		//use bs (incorrect)
End

Function qMaxVert()

    Variable theta
    Variable l2s = sampleToDetectorDist()	//distance from sample to detector
    NVAR lambda = root:Packages:NIST:SAS:gLambda
	NVAR det_width = root:Packages:NIST:SAS:det_width
	
    theta = atan( (det_width/2.0)/l2s )
    
    return ( 4.0*pi/lambda * sin(theta/2.0) )
end

Function qMaxCorner()

    Variable l2s = sampleToDetectorDist()	//distance from sample to detector
    Variable radial
    NVAR lambda = root:Packages:NIST:SAS:gLambda
	NVAR det_off = root:Packages:NIST:SAS:gOffset
	NVAR det_width = root:Packages:NIST:SAS:det_width

    radial=sqrt( (0.5*det_width)*(0.5*det_width)+(0.5*det_width+det_off)*(0.5*det_width+det_off) )
    
    return ( 4*pi/lambda*sin(0.5*atan(radial/l2s)) )
End

Function qMaxHoriz()

    Variable theta
    Variable l2s = sampleToDetectorDist()	//distance from sample to detector
    NVAR lambda = root:Packages:NIST:SAS:gLambda
	NVAR det_off = root:Packages:NIST:SAS:gOffset
	NVAR det_width = root:Packages:NIST:SAS:det_width

    theta = atan( ((det_width/2.0)+det_off)/l2s )	//from the instance variables
    
    return ( 4.0*pi/lambda * sin(theta/2.0) )
End

// calculate sigma for the resolution function at either limit of q-range
Function deltaQ(atQ)
	Variable atQ
	
    Variable k02,lp,l1,l2,sig_02,sigQ2,a1,a2
    NVAR l2Diff = root:Packages:NIST:SAS:L2diff
	NVAR lambda = root:Packages:NIST:SAS:gLambda
	NVAR lambda_width = root:Packages:NIST:SAS:gDeltaLambda
	NVAR d_det = root:Packages:NIST:SAS:d_det
	NVAR del_r = root:Packages:NIST:SAS:del_r
	
	
    l1 = sourceToSampleDist()
    l2 = sampleToDetectorDist() + L2diff
    a1 = sourceApertureDiam()
    a2 = sampleApertureDiam()
    
    k02 = (6.2832/lambda)*(6.2832/lambda)
    lp = 1/(1/l1 + 1/l2)
    
    sig_02 = (0.25*a1/l1)*(0.25*a1/l1)
    sig_02 += (0.25*a2/lp)*(0.25*a2/lp)
    sig_02 += (d_det/(2.355*l2))*(d_det/(2.355*l2))
    sig_02 += (del_r/l2)*(del_r/l2)/12
    sig_02 *= k02
    
    sigQ2 = sig_02 + (atQ*lambda_width)*(atQ*lambda_width)/6

    return(100*sqrt(sigQ2)/atQ)
End

// updated with new flux numbers from John Barker
// NG3 - Feb 2009
// NG7 - July 2009
//
// guide loss has been changed to 0.95 rather than the old value of 0.95
//
// other values are changed in the initialization routines
//
Function beamIntensity()

    Variable alpha,f,t,t4,t5,t6,as,solid_angle,l1,d2_phi
    Variable a1,a2,retVal
    SetDataFolder root:Packages:NIST:SAS
    NVAR l_gap=l_gap,guide_width =guide_width,ng = gNg
    NVAR lambda_t=lambda_t,b=b,c=c
    NVAR lambda=gLambda,t1=t1,t2=t2,t3=t3,phi_0=phi_0
    NVAR lambda_width=gDeltaLambda
    NVAR guide_loss=gGuide_loss
    
    l1 = sourceToSampleDist()
    a1 = sourceApertureDiam()
    a2 = sampleApertureDiam()
    
    
    alpha = (a1+a2)/(2*l1)	//angular divergence of beam
    f = l_gap*alpha/(2*guide_width)
    t4 = (1-f)*(1-f)
    t5 = exp(ng*ln(guide_loss))	// trans losses of guides in pre-sample flight
    t6 = 1 - lambda*(b-(ng/8)*(b-c))		//experimental correction factor
    t = t1*t2*t3*t4*t5*t6
    
    as = pi/4*a2*a2		//area of sample in the beam
    d2_phi = phi_0/(2*pi)
    d2_phi *= exp(4*ln(lambda_t/lambda))
    d2_phi *= exp(-1*(lambda_t*lambda_t/lambda/lambda))

    solid_angle = pi/4* (a1/l1)*(a1/l1)

    retVal = as * d2_phi * lambda_width * solid_angle * t
    SetDataFolder root:
    return (retVal)
end

Function figureOfMerit()

	Variable bi = beamIntensity()
	NVAR lambda = root:Packages:NIST:SAS:gLambda
	
    return (lambda*lambda*bi)
End

//estimate the number of pixels in the beam, and enforce the maximum countrate per pixel (idmax)
Function attenuatorTransmission()

    Variable num_pixels,i_pix		//i_pix = id in John's notation
    Variable bDiam = beamDiameter("horizontal")	//!! note that prev calculations used bh (horizontal)
    Variable atten,a2
    SetDataFolder root:Packages:NIST:SAS
    NVAR a_pixel=a_pixel,idmax=idmax
    
    a2 = sampleApertureDiam()
    
    num_pixels = pi/4*(0.5*(a2+bDiam))*(0.5*(a2+bDiam))/a_pixel/a_pixel
    i_pix = ( beamIntensity() )/num_pixels
    
    atten = (i_pix < idmax) ? 1.0 : idmax/i_pix
    SetDataFolder root:
    return(atten)
End

// TODO_10m: is this going to be close enough? Are the steps the same?
Function attenuatorNumber()

    Variable atten = attenuatorTransmission()
    Variable af,nf,numAtten
    SetDataFolder root:Packages:NIST:SAS
    NVAR lambda=gLambda
    
    af = 0.498 + 0.0792*lambda - 1.66e-3*lambda*lambda
    nf = -ln(atten)/af		//floating point
    
    numAtten = trunc(nf) + 1			//in c, (int)nf
    //correct for larger step thickness at n > 6
    if(numAtten > 6) 
        numAtten = 7 + trunc( (numAtten-6)/2 )		//in c, numAtten = 7 + (int)( (numAtten-6)/2 )
    endif
    
    SetDatafolder root:
    return (numAtten)
End