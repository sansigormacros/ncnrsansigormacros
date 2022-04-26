#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.0
#pragma IgorVersion=6.1
#pragma ModuleName=SASCALC

// [davidm]
// need details for Lenses // wavelenghts 8.9 A // Sample Detector Distance 20 m // Abilitty to change 

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
//
// calculate what q-values you get based on the instruments settings
// that you would typically input to SASCALC
// calculation is for (80A radius spheres) * (beam stop shadow factor)
// or a Debye function (Rg=50A) * (beam stop shadow factor) 
// - NOT true intensity, not counts, just a display
//
// To Do:
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

Proc SASCALC()
	DoWindow/F SASCALC
	if(V_flag==0)
		S_initialize_space()
		initQuokka()		//start life as Quokka
		Sascalc_Panel()
		
		// [david/ to update realsRead before calculations
		DisplayConfigurationText()
		
		ReCalculateInten(1)		//will use defaults
	Endif

// now a checkbox as needed
//	DoWindow/F MC_SASCALC
//	if(V_flag==0)
//		MC_SASCALC()
//	endif
End

Proc S_initialize_space()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:SAS
	
	Make/O/D/N=23 root:Packages:NIST:SAS:integersRead
	Make/O/D/N=53 root:Packages:NIST:SAS:realsRead
	Make/O/T/N=11 root:Packages:NIST:SAS:textRead
	// data
	Make/O/D/N=(192,192) root:Packages:NIST:SAS:data,root:Packages:NIST:SAS:linear_data // [davidm] is bigger now!
	Make/O/D/N=2 root:Packages:NIST:SAS:aveint,root:Packages:NIST:SAS:qval,root:Packages:NIST:SAS:sigave
	root:Packages:NIST:SAS:data = 1
	root:Packages:NIST:SAS:linear_data = 1
	
	// other variables
	// -(hard coded right now - look for NVAR declarations)
	Variable/G root:Packages:NIST:gBinWidth=1		//uses global preference
	Variable/G root:Packages:NIST:SAS:gisLogScale=0
	String/G root:Packages:NIST:SAS:FileList = "SASCALC"
	
	// for the panel
//	Variable/G root:Packages:NIST:SAS:gInst=3		//or 7 for NG7 or 10 for Quokka // [davidm] never used! new name is root:Packages:NIST:SAS:instrument
	Variable/G root:Packages:NIST:SAS:gNg=5		// [davidm] 1-9
//	Variable/G root:Packages:NIST:SAS:gTable=2		//2=chamber, 1=table // [davidm] don't need that for Quokka
	Variable/G root:Packages:NIST:SAS:gDetDist=1300		//sample chamber to detector in cm // [davidm] epg to provide real distance here
	Variable/G root:Packages:NIST:SAS:gSSD=1632		//!!SSD in cm fo 0 guides (derived from Ng)// [davidm] it's approx. 20300 mm
	Variable/G root:Packages:NIST:SAS:gOffset=0
	Variable/G root:Packages:NIST:SAS:gSamAp=1.0		//samAp diameter in cm
	Variable/G root:Packages:NIST:SAS:gLambda=5
	Variable/G root:Packages:NIST:SAS:gDeltaLambda=0.14		//default value
	String/G root:Packages:NIST:SAS:gSourceApString = "0.50 cm;1.00 cm;2.00 cm;3.00 cm;4.00 cm;5.00 cm;"
	String/G root:Packages:NIST:SAS:gBeamstopIndexStr = "1;2;3;4;5;6"
	
	String/G root:Packages:NIST:SAS:gDeltaLambdaStdResStr = "0.068;0.100;0.180"
	String/G root:Packages:NIST:SAS:gDeltaLambdaHighResStr = "0.041;0.064;0.140"
	
	String/G root:Packages:NIST:SAS:gApPopStr = "0.25 cm;0.50 cm;0.75 cm;1.00 cm;1.25 cm;1.50 cm;1.75 cm;2.00 cm;2.50 cm;3.00 cm" // [davidm] do we need "other"?
//	Variable/G root:Packages:NIST:SAS:gSamApOther = 10		//non-standard aperture diameter, in mm // epg to comfirm
	Variable/G root:Packages:NIST:SAS:gUsingLenses = 0		//0=no lenses, 1=lenses(or prisms)
	Variable/G root:Packages:NIST:SAS:gModelOffsetFactor = 1
	
	// for the MC simulation
	Variable/G root:Packages:NIST:SAS:doSimulation	=0		// == 1 if 1D simulated data, 0 if other from the checkbox
//	Variable/G root:Packages:NIST:SAS:gRanDateTime=datetime
//	Variable/G root:Packages:NIST:SAS:gImon = 10000
//	Variable/G root:Packages:NIST:SAS:gThick = 0.1
//	Variable/G root:Packages:NIST:SAS:gSig_incoh = 0.1
	String/G root:Packages:NIST:SAS:gFuncStr = ""
//	Variable/G root:Packages:NIST:SAS:gR2 = 2.54/2	// [davidm] not used?
//	Variable/G root:Packages:NIST:SAS:gSamTrans=0.8			//for 1D, default value
//	Variable/G root:Packages:NIST:SAS:gCntTime = 300
	Variable/G root:Packages:NIST:SAS:gDoMonteCarlo = 0
//	Variable/G root:Packages:NIST:SAS:gUse_MC_XOP = 1				//set to zero to use Igor code
//	Variable/G root:Packages:NIST:SAS:gBeamStopIn = 1			//set to zero for beamstop out (transmission)
//	Variable/G root:Packages:NIST:SAS:gRawCounts = 0
//	Variable/G root:Packages:NIST:SAS:gSaveIndex = 100
//	String/G root:Packages:NIST:SAS:gSavePrefix = "SIMUL"
	Variable/G root:Packages:NIST:SAS:gAutoSaveIndex = 100			//a way to set the index for automated saves
	String/G root:Packages:NIST:SAS:gAutoSaveLabel = ""				//a way to set the "sample" label for automated saves
	Make/O/D/N=10 root:Packages:NIST:SAS:results = 0
	Make/O/T/N=10 root:Packages:NIST:SAS:results_desc = {"total X-section (1/cm)","SAS X-section (1/cm)","number that scatter","number that reach detector","avg # times scattered","fraction single coherent","fraction multiple coherent","fraction multiple scattered","fraction transmitted","detector counts w/beamstop"}

	Variable/G root:Packages:NIST:SAS:g_1DTotCts = 0			//summed counts (simulated)
	Variable/G root:Packages:NIST:SAS:g_1DEstDetCR = 0		// estimated detector count rate
	Variable/G root:Packages:NIST:SAS:g_1DFracScatt = 0		// fraction of beam captured on detector
	Variable/G root:Packages:NIST:SAS:g_1DEstTrans = 0		// estimated transmission of sample
	Variable/G root:Packages:NIST:SAS:g_1D_DoABS = 1
	Variable/G root:Packages:NIST:SAS:g_1D_AddNoise = 1
	Variable/G root:Packages:NIST:SAS:g_MultScattFraction=0
	Variable/G root:Packages:NIST:SAS:g_detectorEff=0.75			//average value for most wavelengths
	Variable/G root:Packages:NIST:SAS:g_actSimTime = 0				//for the save
	Variable/G root:Packages:NIST:SAS:g_SimTimeWarn = 10			//manually set to a very large value for scripted operation
	
	
	//tick labels for SDD slider
//	//userTicks={tvWave,tlblWave }
//	Make/O/D/N=5 root:Packages:NIST:SAS:tickSDDNG3,	root:Packages:NIST:SAS:tickSDDNG7,	root:Packages:NIST:SAS:tickSDDQuokka
//	Make/O/T/N=5 root:Packages:NIST:SAS:lblSDDNG3,		root:Packages:NIST:SAS:lblSDDNG7,	root:Packages:NIST:SAS:lblSDDQuokka
	
	// [davidm] what are the values for Quokka? -> min = 1m; max = 20m
//	root:Packages:NIST:SAS:tickSDDQuokka	= {133,400,700,1000,1317}
//	root:Packages:NIST:SAS:lblSDDQuokka	= {"133","400","700","1000","1317"}
	
//	root:Packages:NIST:SAS:tickSDDNG3	= {133,400,700,1000,1317}
//	root:Packages:NIST:SAS:lblSDDNG3	= {"133","400","700","1000","1317"}
//	root:Packages:NIST:SAS:tickSDDNG7	= {100,450,800,1150,1530}
//	root:Packages:NIST:SAS:lblSDDNG7	= {"100","450","800","1150","1530"}
	
	//for the fake dependency
	Variable/G root:Packages:NIST:SAS:gTouched=1
	Variable/G root:Packages:NIST:SAS:gCalculate=0
	//for plotting
	Variable/G root:Packages:NIST:SAS:gFreezeCount=1		//start the count at 1 to keep Jeff happy
	Variable/G root:Packages:NIST:SAS:gDoTraceOffset=0		// (1==Yes, offset 2^n), 0==turn off the offset
	
	// fill w/default values
	S_fillDefaultHeader(root:Packages:NIST:SAS:integersRead,root:Packages:NIST:SAS:realsRead,root:Packages:NIST:SAS:textRead)
	
End

Function initQuokka()

	SetDataFolder root:Packages:NIST:SAS
	
	Variable/G instrument = 10
	Variable/G s12 = 54.8 // sample position offset [epg]
	Variable/G d_det = 0.5 // epg to confirm
	Variable/G a_pixel = 0.508 // epg to confirm
	Variable/G del_r = 0.5 // with of annulus [may be a bug]
	Variable/G det_width = 96.0
	Variable/G lambda_t = 5.50 // possibly related to source term
	
// [davidm] never used:
//	Variable/G l2r_lower = 132.3
//	Variable/G l2r_upper =  1317
//	Variable/G lambda_lower = 2.5
//	Variable/G lambda_upper = 20.0
//	Variable/G d_upper = 25.0

	Variable/G bs_factor = 1.05
	Variable/G t1 = 0.63 // NIST guids transmision
	Variable/G t2 = 1.0 // NIST guids transmision
	Variable/G t3 = 0.75 // NIST guids transmision
	Variable/G l_gap = 100.0 // check for Quokka
	Variable/G guide_width = 5.0
	Variable/G idmax = 100.0
	
//	//old values, from 3/2002
//	Variable/G phi_0 = 2.95e13
//	Variable/G b = 0.023
//	Variable/G c = 0.023

	//new values, from 11/2009 --- BeamFluxReport_2009.ifn
	Variable/G phi_0 = 2.42e13 // flux terms
	Variable/G b = 0.0 // transmission losses
	Variable/G c = -0.0243 // transmission losses
	Variable/G gGuide_loss = 0.98
	
	//fwhm values (new variables) (+3, 0, -3, calibrated 2009)
	Variable/G fwhm_narrow = 0.109 // to be provided
	Variable/G fwhm_mid = 0.14
	Variable/G fwhm_wide = 0.236 // to be provided
	
// [davidm] never used:
	//source apertures (cm)
//	Variable/G a1_0_0 = 1.43 // [davidm] : 0.5 1.0  2.0 3.0 4.0 5.0
//	Variable/G a1_0_1 = 2.54
//	Variable/G a1_0_2 = 3.81
//	Variable/G a1_7_0 = 2.5	// after the polarizer		
//	Variable/G a1_7_1 = 5.0
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
//	Variable/G	l2diff = 5.0 // [davidm] ???
//	
	SetDataFolder root:
end

Function S_fillDefaultHeader(iW,rW,tW)
	Wave iW,rW
	Wave/T tW
	
	NVAR gLambda = root:Packages:NIST:SAS:gLambda
	NVAR gDeltaLambda = root:Packages:NIST:SAS:gDeltaLambda

	// text wave
	// don't need anything
	
	// integer wave
	// don't need anything
	
	// real wave
	rw = 0
	rw[16] = 96		// beamcenter X (pixels)
	rw[17] = 96		// beamcenter Y
	
	rw[10]	= 5.08			//detector resolution (5mm) and calibration constants (linearity)
	rw[11] = 10000
	rw[12] = 0
	rw[13] = 5.08
	rw[14] = 10000
	rw[15] = 0
	
	rw[20] = 96		// det size in cm
	rw[18] = 6		// SDD in meters (=L2)
	
	rw[26] = gLambda		//lambda in Angstroms
	rw[4] = 1		//transmission
	
	rw[21] = 101 // set for BS index = 1, diameter in mm
	rw[23] = 50			//A1 diameter in mm
	rw[24] = 10 // 12.7			//A2 diameter in mm
	rw[25] = 20.3 // 7.02			//L1 distance in meters (derived from number of guides)
	rw[27] = gDeltaLambda // 0.11			//DL/L wavelength spread

	rw[52] = 56 // set for BS index = 1, distance in mm
	
	return(0)
End


Window SASCALC_Panel()

	PauseUpdate
	Silent 1

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:SAS:
	
	Display/W=(5,44,650,630)/K=1  aveint vs qval as "SASCALC"
	DoWindow/C SASCALC
	ModifyGraph cbRGB=(49151,53155,65535)
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	Modifygraph log=1
	Modifygraph grid=1
	Modifygraph mirror=2
	ModifyGraph msize(aveint)=2
	
	ErrorBars aveint Y,wave=(sigave,sigave)
	Label bottom, "Q (1/A)"
	Label left, "Relative Intensity"
	legend
	
	ControlBar/L 163

	SetDataFolder fldrSav0
	
	variable top = 5
	variable margin = 10
	variable groupWidth = 150
	
	// Instrument
	GroupBox group0 title="Instrument", pos={6,top}, size={groupWidth-35,36}
	// Quokka
	CheckBox checkQuokka title="Quokka", pos={20,top+16}, size={36,14}
	CheckBox checkQuokka value=1, mode=1
	
	// Help
	Button SC_helpButton title="?", pos={130,top+14}, size={25,20}, proc=showSASCALCHelp
	Button SC_helpButton help={"Show help file for simulation of SANS Data"}
	
	top += 36 + margin
	
	// Lambda
	SetVariable setvar0_2 title="Lambda", pos={56,top}, size={100,20}, bodyWidth=70, proc=LambdaSetVarProc
	SetVariable setvar0_2 limits={4.5,20,0.01}, value= root:Packages:NIST:SAS:gLambda
	
	top += 15 + margin
	
	// Velocity Selector
	PopupMenu popup0_3 title="Velocity Selector", pos={56,top}, size={100,20}, bodyWidth=70, proc=VelocitySelectorPopMenuProc
	PopupMenu popup0_3 mode=2, popvalue=" std. resolution", value=" std. resolution; high resolution"
	
	top += 20 + margin
	
	// Spread (of Wavelength)
	PopupMenu popup0_2 title="Spread", pos={56,top}, size={100,20}, bodyWidth=70, proc=DeltaLambdaPopMenuProc
	PopupMenu popup0_2 mode=2, value=root:Packages:NIST:SAS:gDeltaLambdaStdResStr		// for std. resolution
//	PopupMenu popup0_2 mode=2, value=root:Packages:NIST:SAS:gDeltaLambdaHighResStr	// for high resolution
	
	top += 20 + margin
	
	// Source Aperture
	PopupMenu popup0 title="Source Aperture", pos={56,top}, size={100,20}, bodyWidth=70, proc=SourceAperturePopMenuProc
	PopupMenu popup0 mode=1, value=root:Packages:NIST:SAS:gSourceApString

	top += 20 + margin
	
	// Beamstop index
	PopupMenu popup0_4 title="Beamstop Index", pos={56,top}, size={100,20}, bodyWidth=70, proc=BeamstopIndexPopMenuProc
	PopupMenu popup0_4 mode=1, value=root:Packages:NIST:SAS:gBeamstopIndexStr	
	top += 20 + margin
	
	// Number of Guides
	GroupBox group1, title="Number of Guides", pos={6,top}, size={groupWidth,25+120}
	// Slider
	Slider SC_Slider pos={30,top+18}, size={0,120}, proc=GuideSliderProc
	Slider SC_Slider limits={9,0,1}, variable=root:Packages:NIST:SAS:gNg, live=0, side=1, vert=1
	
	top += 25+120 + margin
	
//	// Lenses
//	CheckBox checkLens title="Use Lenses", pos={57,top}, size={44,0}, proc=LensCheckProc
//	CheckBox checkLens value=root:Packages:NIST:SAS:gUsingLenses, side=1
//	
//	top += 14 + margin
	
	// Sample Aperture
	PopupMenu popup0_1 title="Sample Aperture", pos={56,top}, size={100,20}, bodyWidth=70, proc=SampleAperturePopMenuProc
	PopupMenu popup0_1 mode=8, popvalue="2.00 cm", value= root:Packages:NIST:SAS:gApPopStr
	
	top += 20 + margin
	
	// Sample To Detector
	GroupBox group2 title="Sample Detector Distance", pos={6,top}, size={groupWidth,25+120+20+5}
	// Slider
	Slider SC_Slider_1 pos={30,top+18}, size={0,120}, proc=DetDistSliderProc
	Slider SC_Slider_1 limits={2000,100,1}, variable=root:Packages:NIST:SAS:gDetDist, live=0, side=1, vert=1, ticks=20
	// Value
	SetVariable setvar0 pos={34,top+18+120+8}, size={80,20}, title="(cm)", proc=SDDSetVarProc
	SetVariable setvar0 limits={100,2000,1}, value=root:Packages:NIST:SAS:gDetDist
	
	top += 25+120+20+5 + margin
	
	// Detector Offset
	GroupBox group3 title="Detector Offset", pos={6,top}, size={groupWidth,25+45+20+5}
	// Slider
	Slider SC_Slider_2 pos={20,top+18}, size={122,0}, proc=OffsetSliderProc
	Slider SC_Slider_2 limits={0,45,1}, variable=root:Packages:NIST:SAS:gOffset, live=0, vert=0
	// Value
	SetVariable setvar0_1 pos={34,top+18+45+8}, size={80,20}, title="(cm)", proc=OffsetSetVarProc
	SetVariable setvar0_1 limits={0,45,1}, value=root:Packages:NIST:SAS:gOffset
	
	top += 25+45+20+5 + margin
	
	// Simulation
	CheckBox checkSim title="Simulation", pos={57,top}, size={44,0}, proc=SimCheckProc
	CheckBox checkSim value=0, side=1
	
	top += 14 + margin
	
	// Offset Traces
	CheckBox check0_1 title="Offset Traces", pos={57,top}, size={44,0}
	CheckBox check0_1 variable=root:Packages:NIST:SAS:gDoTraceOffset, side=1

	top += 14 + margin
	
// Buttons:	
	
	// Freeze
	Button FreezeButton title="Freeze", pos={6,top}, size={groupWidth,21}
	Button FreezeButton proc=FreezeButtonProc
	
	top += 12 + margin
	
	// Clear
	Button ClearButton title="Clear", pos={6,top}, size={groupWidth,21}
	Button ClearButton proc=S_ClearButtonProc
	
	top += 12 + margin
	
	// Done
	Button SC_DoneButton, title="Done", pos={6,top}, size={groupWidth,21}
	Button SC_DoneButton, proc=SASCALCDoneButton, help={"This button will close the panel"}
	
	//////
	
	SetDataFolder fldrSav0

	// set up a fake dependency to trigger recalculation
	//root:Packages:NIST:SAS:gCalculate := ReCalculateInten(root:Packages:NIST:SAS:gTouched)
	
EndMacro

// help
Proc showSASCALCHelp(ctrlName): ButtonControl
	String ctrlName
	DisplayHelpTopic/K=1/Z "SASCALC"
	if(V_flag !=0)
		DoAlert 0,"The SANS Simulation Help file could not be found"
	endif
end

// change the wavelength
Function LambdaSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[26] = str2num(varStr)

	// [davidm] might require lense check
		
	ReCalculateInten(1)
End

// change the velocity selector
Function VelocitySelectorPopMenuProc(ctrlName,popNum,popStr)
	String ctrlName
	Variable popNum
	String popStr
	
	strswitch (popStr)
		case " std. resolution":
			PopupMenu popup0_2 win=SASCALC, value=GetDeltaLambdaStdResSt() // direct referencing causes problems with Igor Pro 6.20
			break
		case " high resolution":
			PopupMenu popup0_2 win=SASCALC, value=GetDeltaLambdaHighResStr()
			break
		default:
			PopupMenu popup0_2 win=SASCALC, value="internal error", mode=1
			return 0
	endswitch
	
	ControlInfo/W=SASCALC popup0_2
	DeltaLambdaPopMenuProc("", V_Value, S_Value)

End

Function/S GetDeltaLambdaStdResSt()
	SVAR str = root:Packages:NIST:SAS:gDeltaLambdaStdResStr
	return str
End

Function/S GetDeltaLambdaHighResStr()
	SVAR str = root:Packages:NIST:SAS:gDeltaLambdaHighResStr
	return str
End

// change the wavelength spread
Function DeltaLambdaPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	NVAR dl=root:Packages:NIST:SAS:gDeltaLambda
	dl = str2num(popStr)
	
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[27] = dl
	
	ReCalculateInten(popnum)		//skip the calculation if I pass in  zero
End

// change the source aperture
Function SourceAperturePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	sourceApertureDiam()			// sets the new value in the wave
	
	// [davidm] might require lense check
	
	ReCalculateInten(popNum)		// skip the recalculation if I pass in a zero
End

// change the source aperture
Function BeamstopIndexPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	beamstopIndex()			// sets the new value in the wave
	
	// [davidm] might require lense check
	
	ReCalculateInten(popNum)		// skip the recalculation if I pass in a zero
End

// changing the number of guides changes the SSD
Function GuideSliderProc(ctrlName, sliderValue, event) : SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved
	
	if(event %& 0x1)
		// [davidm] might require lense check
		
		sourceToSampleDist()		//updates the SSD global and wave
		ReCalculateInten(1)
	endif
End

// set sample aperture
Function SampleAperturePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	sampleApertureDiam()
	
	// [davidm] might require lense check
	
	ReCalculateInten(popNum)
End

// changing the detector position changes the SDD
//
Function DetDistSliderProc(ctrlName,sliderValue,event) : SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	if(event %& 0x1)
		// [davidm] might require lense check
		
		sampleToDetectorDist()	//changes the SDD and wave (DetDist is the global)
		ReCalculateInten(1)
	endif
End

// set sample to detector distance
//
Function SDDSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	sampleToDetectorDist()
	
	// [davidm] might require lense check
	
	ReCalculateInten(1)
End

// change the offset
// - changes the beamcenter (x,y) position too
Function OffsetSliderProc(ctrlName,sliderValue,event) : SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	if(event %& 0x1)
		detectorOffset()
		ReCalculateInten(1)
	endif
End

// set offset
// - changes the beamcenter (x,y) position too
Function OffsetSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	detectorOffset()		//sets the offset in the wave and also the new (x,y) beamcenter
	ReCalculateInten(1)
End

//simulation controls as a control bar that toggles on/off to the right
// depending on the state of the 2D flag, open the 1d or 2d control panel
Function SimCheckProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct

	if(CB_Struct.checked)
		NVAR do2D = root:Packages:NIST:SAS:gDoMonteCarlo
		
		if(CB_Struct.eventMod == 2)		//if the shift key is down - go to 2D mode
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
		if(V_flag != 0)
			NVAR do2D = root:Packages:NIST:SAS:gDoMonteCarlo
			do2D = 0
			KillWindow MC_SASCALC
		endif
		DoWindow Sim_1D_Panel
		if(V_flag != 0)
			KillWindow Sim_1D_Panel
		endif
		
		NVAR doSim = root:Packages:NIST:SAS:doSimulation
		doSim=0
		
	endif
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
	ErrorBars $("aveint_"+num2str(ct)) Y,wave=($("sigave_"+num2str(ct)),$("sigave_"+num2str(ct)))
	
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
	Notebook Saved_Configurations font="Monaco",fSize=10,fstyle=0,text=GetConfigurationText()

End

//clears the frozen traces on the graph, asks if you want to clear the saved text
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

End

// done => to close SASCALC
Proc SASCALCDoneButton(ctrlName): ButtonControl
	String ctrlName
	DoWindow/K SASCALC
	DoWindow/K Trial_Configuration
	DoWindow/K Saved_Configurations
	DoWindow/K MC_SASCALC
	DoWindow/K Sim_1D_Panel
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
	SVAR funcStr = root:Packages:NIST:SAS:gFuncStr		//set by the popup

	if(doSimulation == 1)
		if(doMonteCarlo == 1)
			//2D simulation (in MultiScatter_MonteCarlo_2D.ipf)
			
			Simulate_2D_MC(funcStr,aveint,qval,sigave,sigmaq,qbar,fsubs)
			
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
	Variable pixelsX=192, pixelsY=192
	
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
	WAVE data=$(destPath + ":data")

// fake mask that uses all of the detector
	Make/D/O/N=(pixelsX,pixelsY) $(destPath + ":mask")
	Wave mask = $(destPath + ":mask")
	mask = 0
	//1 pixel all around // [davidm] 
	mask[0][] = 1
	mask[191][] = 1
	mask[][0] = 1
	mask[][191] = 1
	//
	//pixels within rcentr of beam center are broken into 9 parts (units of mm)
	rcentr = 100		//original // [davidm] ???
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
					sigave[kk-1] = small_num
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
	DDet = 0.508		// resolution in cm
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
	
	// [davidm] to deal with later
//	if(usingLenses==1)			//SRK 2007
//		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
//	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
//	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	//v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007
	v_g = (2.0*yg^2*v_lambda)					//factor of 2 correction removed 2022 JGB

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

Function/S GetConfigurationText()

	String str="",temp

	SetDataFolder root:Packages:NIST:SAS
	
	NVAR numberOfGuides=gNg
	NVAR wavelength=gLambda
	NVAR lambdaWidth=gDeltaLambda
	NVAR instrument = instrument
//	NVAR L2diff = L2diff
 	NVAR lens = root:Packages:NIST:SAS:gUsingLenses
	NVAR gDetDist = root:Packages:NIST:SAS:gDetDist // chamberToDetectorDist
	SVAR/Z aStr = root:Packages:NIST:gAngstStr

	Variable bmDiameter = beamDiameter("maximum")
	Variable bsDiameter = beamstopDiam()

	AddLine(str, "Source Aperture Diameter",			"%8.1f cm",	sourceApertureDiam(),			-1)	
	AddLine(str, "Source to Sample Distance (SSD)",	"%8.0f cm",	sourceToSampleDist(),			-1)
	AddLine(str, "Sample Aperture to Detector",			"%8.0f cm",	sampleToDetectorDist(),			-1) // sampleToDetectorDist() + L2diff
	AddLine(str, "Beam Diameter",						"%8.2f cm",	bmDiameter,		-1)
	if (bsDiameter < bmDiameter)
		AddLine(str, "Beamstop Diameter",					"%8.2f cm � < Beam diameter",	bsDiameter,					-1)
		DoAlert 0, "Beam is larger than the maximum Beam Stop Size"
	else
		AddLine(str, "Beamstop Diameter",					"%8.2f cm",	beamstopDiam(),					-1)
	endif
	AddLine(str, "Beamstop Distance",					"%8.2f cm",	beamstopDist(),					-1)
	
	AddLine(str, "Minimum Q-value",					"%8.4f 1/A (sigQ/Q = %4.1f%%)",	qMin(),			deltaQ(qMin()))
	AddLine(str, "Maximum Q-value",					"%8.4f 1/A (sigQ/Q = %4.1f%%)",	qMaxCorner(),	deltaQ(qMaxCorner()))
	
	AddLine(str, "Maximum Horizontal Q-value",			"%8.4f 1/A",		qMaxHoriz(),					-1)
	AddLine(str, "Maximum Vertical Q-value",			"%8.4f 1/A",		qMaxVert(),					-1)
	AddLine(str, "Beam Intensity",						"%8.0f counts",	beamIntensity(),				-1)
	AddLine(str, "Figure of Merit",						"%8.3g A^2/s",	figureOfMerit(),				-1)
//	AddLine(str, "Attenuator transmission",				"%8.6f Atten",	attenuatorTransmission(),		-1)

	str += "*********************** Quokka ***********************\r"

	AddLine(str, "Sample Aperture Diameter",			"%8.2f cm",	sampleApertureDiam(),	-1)
	AddLine(str, "Number of Guides",					"%8d",		numberOfGuides,			-1)
//	AddLine(str, "Sample Chamber to Detector Distance",	"%8.1f cm",	gDetDist,				-1)
	AddLine(str, "Detector Offset",						"%8.1f cm",	detectorOffset(),			-1)
	AddLine(str, "Neutron Wavelength",					"%8.2f A",	wavelength,				-1)
	AddLine(str, "Wavelength Spread (FWHM)",			"%8.3f",		lambdaWidth,			-1)
//	AddLine(str, "Sample Aperture to Sample Position",	"%8.2f cm",	L2Diff,					-1)
	
	str += "Lenses are OUT\r"
   	
	setDataFolder root:
	return str			 
End

function AddLine(text, pre, format, value1, value2)
	string &text
	string pre, format
	variable value1, value2
	
	text += pre

	variable i
	for (i = 37 - strlen(pre); i > 0; i -= 1)
		text += " "
	endfor
	
	string temp
	if (value2 == -1)
		sprintf temp, format, value1
	else
		sprintf temp, format, value1, value2
	endif
	
	text += temp + "\r"
end

Function DisplayConfigurationText()

	if(WinType("Trial_Configuration")==0)
		NewNotebook/F=0/K=1/N=$"Trial_Configuration" /W=(480,44,880,369)
	endif
	//replace the text
	Notebook Trial_Configuration selection={startOfFile, endOfFile}
	Notebook Trial_Configuration font="Consolas", fSize=10, text=GetConfigurationText()

end

//parses the control for A1 diam
// updates the wave
Function sourceApertureDiam()

	Variable diam
	
	ControlInfo/W=SASCALC popup0
	variable len = strlen(S_Value)
	if (numtype(len) == 2) // strlen returned NaN?
		return 0
	endif

	sscanf S_Value, "%f cm", diam // value in cm
	
	if (V_flag != 1)
		DoAlert 0, "Internal Error"
	endif
		
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[23] = diam*10		//source aperture diameter in mm
	
	return diam
end

// parses the control for the beamstop index and sets the 
// beamstop diameter and distance in the wave

Function beamstopIndex()

	Variable index
	Variable diameter
	Variable distance
	
	ControlInfo/W=SASCALC popup0_4
	variable len = strlen(S_Value)
	if (numtype(len) == 2) // strlen returned NaN?
		return 0
	endif

	sscanf S_Value, "%d", index 
	
	if (V_flag != 1)
		DoAlert 0, "Internal Error"
	endif

	switch(index)
		case 1:
			distance = 56
			diameter = 101
			break
		case 2:
			distance = 103
			diameter = 80
			break
		case 3:
			distance = 173
			diameter = 61
			break
		case 4:
			distance = 221
			diameter = 22
			break
		case 5:
			distance = 255
			diameter = 20
			break
		case 6:
			distance = 329
			diameter = 10
			break
		default:
			DoAlert 0, "no matching beamstop index, using index = 1"
			distance = 56
			diameter = 101
	endswitch

	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[21] = diameter		//beamstop diameter in mm
	rw[52] = distance		//beamstop distance in mm

end

//parses the control for A2 diam
// updates the wave and global
// returns a2 in cm
Function sampleApertureDiam()

	// set the global
	NVAR a2=root:Packages:NIST:SAS:gSamAp
	
	ControlInfo/W=SASCALC popup0_1
	variable len = strlen(S_Value)
	if (numtype(len) == 2) // strlen returned NaN?
		return 0
	endif
	
	sscanf S_Value, "%f cm", a2 // value in cm
	if (V_flag != 1)
		DoAlert 0, "Internal Error"
	endif
	
	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[24] = a2*10		//sample aperture diameter in mm
	
	return a2
end

//compute SSD and update both the global and the wave
Function sourceToSampleDist()

	NVAR NG=root:Packages:NIST:SAS:gNg
	NVAR S12 = root:Packages:NIST:SAS:S12
//	NVAR L2Diff = root:Packages:NIST:SAS:L2Diff
	NVAR SSD = root:Packages:NIST:SAS:gSSD
	
	//SSD = 1632 - 155*NG - s12*(2-tableposition()) - L2Diff // [davidm] will replace with look up table
	
	SSD = 0
	
	switch (NG)
		case 0:
			SSD += 4	// 20
		case 1:
			SSD += 2	// 16
		case 2:
			SSD += 2	// 14
		case 3:
			SSD += 2	// 12
		case 4:
			SSD += 2	// 10
		case 5:
			SSD += 2	// 8
		case 6:
			SSD += 2	// 6
		case 7:
			SSD += 2	// 4
		case 8:
			SSD += 1	// 2
		case 9:
			SSD += 1	// 1
	endswitch
	
	SSD *= 100 // convert to cm
	
	//SSD -= L2Diff // [davidm] ???

	WAVE rw=root:Packages:NIST:SAS:realsRead
	rw[25] = SSD/100		// in meters
	return(SSD)
End

//returns the offset value
// slider and setVar are linked to the same global
// updates the wave and changes the beamcenter (x,y) in the wave
Function detectorOffset()
	
	WAVE rw=root:Packages:NIST:SAS:RealsRead
	NVAR val = root:Packages:NIST:SAS:gOffset
	rw[19] = val		// already in cm
	//move the beamcenter, make it an integer value for the MC simulation
	rw[16] = 96 + round(2*rw[19])		//approximate beam X is 64 w/no offset, 114 w/25 cm offset 
	rw[17] = 96		//typical value
	
	return(val)
end

//sets the SDD (slider and setVar are linked by the global and is the detector position
//  relative to the chamber)
// updates the wave
Function sampleToDetectorDist()

	NVAR detDist = root:Packages:NIST:SAS:gDetDist
	NVAR S12 = root:Packages:NIST:SAS:S12
	WAVE rw=root:Packages:NIST:SAS:RealsRead	
	Variable SDD	
	
	// [davidm] without l2diff !!!
	
	//SDD = detDist + s12*(2-tableposition())
	SDD = detDist
	
	rw[18] = SDD/100		// convert to meters for header
	return(SDD)
End

//direction = one of "vertical;horizontal;maximum;"
// all of this is bypassed if the lenses are in
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
    
    //NVAR L2diff = root:Packages:NIST:SAS:L2diff
    NVAR lambda = root:Packages:NIST:SAS:gLambda
    NVAR lambda_width = root:Packages:NIST:SAS:gDeltaLambda
    NVAR bs_factor = root:Packages:NIST:SAS:bs_factor
    
    l2 = sampleToDetectorDist() // + L2diff
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

Function beamstopDiam() 
   
 	WAVE rw=root:Packages:NIST:SAS:realsRead
 	
    return rw[21] * 0.1	//return diameter in cm
End

Function beamstopDist() // [davidm] we have a list of beam stops
   
 	WAVE rw=root:Packages:NIST:SAS:realsRead
 	
    return rw[52] * 0.1		//return diameter in cm
End

//returns the projected diameter of the beamstop at the anode plane.
// most noticeable at short SDD
//if flag == 0 use conservative estimate = largest diameter (for SASCALC, default)
//if flag != 0 use point aperture = average diameter (for resolution calculation)
Function beamstopDiamProjection(flag)
	Variable flag
	
//	NVAR L2diff = root:Packages:NIST:SAS:L2diff
	Variable a2 = sampleApertureDiam()
	Variable bs = beamstopDiam()
	Variable l2, LB, BS_P
    
	l2 = sampleToDetectorDist() // + L2diff

	LB = beamstopDist()
	//LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical) // epg to provide
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
//    NVAR l2Diff = root:Packages:NIST:SAS:L2diff
	NVAR lambda = root:Packages:NIST:SAS:gLambda
	NVAR lambda_width = root:Packages:NIST:SAS:gDeltaLambda
	NVAR d_det = root:Packages:NIST:SAS:d_det
	NVAR del_r = root:Packages:NIST:SAS:del_r
	
	
    l1 = sourceToSampleDist()
    l2 = sampleToDetectorDist() // + L2diff
    a1 = sourceApertureDiam()
    a2 = sampleApertureDiam()
    
    k02 = (6.2832/lambda)*(6.2832/lambda) // 2*pi/lambda
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
    NVAR guide_loss=gGuide_loss // to confirm
    
    l1 = sourceToSampleDist()
    a1 = sourceApertureDiam()
    a2 = sampleApertureDiam()
    
    
    alpha = (a1+a2)/(2*l1)	//angular divergence of beam
    f = l_gap*alpha/(2*guide_width)
    t4 = (1-f)*(1-f)
    t5 = exp(ng*ln(guide_loss))	// trans losses of guides in pre-sample flight  /// guide_loss ^ ng
    t6 = 1 // t6 = 1 - lambda*(b-(ng/8)*(b-c))		//experimental correction factor // epg to confirm
    t = t1*t2*t3*t4*t5*t6
    
    as = pi/4*a2*a2		//area of sample in the beam
    d2_phi = phi_0/(2*pi)
    d2_phi *= exp(4*ln(lambda_t/lambda))
    d2_phi *= exp(-1*(lambda_t*lambda_t/lambda/lambda))

    solid_angle = pi/4* (a1/l1)*(a1/l1)

    retVal = as * d2_phi * lambda_width * solid_angle * t // d2_phi flux term??? epg to confirm
     SetDataFolder root:
    return (retVal)
end

Function figureOfMerit()

	Variable bi = beamIntensity()
	NVAR lambda = root:Packages:NIST:SAS:gLambda
	
    return (lambda*lambda*bi)
End

//estimate the number of pixels in the beam, and enforce the maximum countrate per pixel (idmax)
//Function attenuatorTransmission()
//
//    Variable num_pixels,i_pix		//i_pix = id in John's notation
//    Variable bDiam = beamDiameter("horizontal")	//!! note that prev calculations used bh (horizontal)
//    Variable atten,a2
//    SetDataFolder root:Packages:NIST:SAS
//    NVAR a_pixel=a_pixel,idmax=idmax
//    
//   a2 = sampleApertureDiam()
//    
//    num_pixels = pi/4*(0.5*(a2+bDiam))*(0.5*(a2+bDiam))/a_pixel/a_pixel
//    i_pix = ( beamIntensity() )/num_pixels
//    
//    atten = (i_pix < idmax) ? 1.0 : idmax/i_pix
//    SetDataFolder root:
//    return(atten)
//End

//Function attenuatorNumber()
//
//    Variable atten = attenuatorTransmission()
//    Variable af,nf,numAtten
//    SetDataFolder root:Packages:NIST:SAS
//    NVAR lambda=gLambda
//    
//    af = 0.498 + 0.0792*lambda - 1.66e-3*lambda*lambda // epg to be provided
//    nf = -ln(atten)/af		//floating point
//    
//    numAtten = trunc(nf) + 1			//in c, (int)nf
//    //correct for larger step thickness at n > 6
//    if(numAtten > 6) 
//        numAtten = 7 + trunc( (numAtten-6)/2 )		//in c, numAtten = 7 + (int)( (numAtten-6)/2 ) // epg to check // look up table
//    endif
//    
//    SetDatafolder root:
//    return (numAtten)
//End