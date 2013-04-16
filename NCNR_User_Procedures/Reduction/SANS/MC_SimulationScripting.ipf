#pragma rtGlobals=1		// Use modern global access method.

// this is a file with all of the functions that can be used to
// script the MC simulation of data
// 1D will also be supported, unless I can find a reason not to support this.
//
// there will be a lot of utility functions to "move" the parts of an instrument that
// are "moveable" into different configurations. The aim is to have this appear as
// much like running an experiment as possible.
//
//
//  The basic cycle:
//
// 1) plot the model function, and set the coefficients to what you want
//
// 2) set (and save) as many configurations as you like -picking ones that are most appropriate for the sample scattering
//
//		Sim_SaveConfiguration(waveStr)
//
// 3) simulate the sample scattering at your configurations for specified times. The 1D count rate
//		 should match fairly well to the 2D count rate. (Check this for low/high incoherent levels)
//-or-
// 4) run everything for a short time (say 1s to 10s) to get the count rates
//  - this will actually save the files - just like a real experiment. This is like step 6, but with short count times.
//
// 5) with the sample count rates, find the optimal count times
//
//		OptimalCount(samCR,empCR)
//
// 6) Write a function to "run" the samples at configurations and count times. Don't forget to simulate
//		 the transmissions. (See the examples below). Copy the function to a new procedure window, rename it,
// 		and edit it there as you wish.
//
//		ListSASCALCConfigs() will print out the list of configurations
//
// 7) Then with the optimal count times, do a dry run to see how long the whole simulation would take. 
//
//		Sim_DryRun(funcStr)
//
// 8) Then if that's OK, run the full simulation
//
//		Your function here()
//
// 9) If it's 1D data, use NSORT to combine. If it's 2D data, reduce as usual. Be sure to skip the detector
//		efficiency correction, and set the dead time to a tiny value so that it won't have any
//    effect (since the detector CR is fictionally high, and the detector is perfect):
//
//		Sim_SetDeadTimeTiny()
//
// When you have a lot of 1D waves to combine, and they are not numbered like in a real reduction
// experiment, see:
//
//  MakeCombineTable_byName()
//  DoCombineFiles_byName(lowQfile,medQfile,hiQfile,saveName) (in NSORT.ipf)
//
// this works with 1, 2, or 3 data files
//


// In general, when setting up a simulation, it's easier to set up sample conditions for a particular
// sample, and loop through the configurations. If you want your 2D data to "look" like a typical 
// experiment, then you'll need to simulate each different sample at one configuration, then "move"
// to a different configuration and loop through the samples again. Somewhat more cumbersome, all to 
// get the file catalog to be "grouped" like a real SANS experiment.


//
// Important - in the reduction process, set the  dead time correction to something
// really small, say 10^-15 
//
// see Sim_SetDeadTimeTiny()

//
// TODO:
// x- need to update the 1D writer to allow a name to be passed in, rather than
// always using the dialog
// x- fill in the "RunSample" functions
//
//  -- I need a little panel to control all of this, and get the information, just 
//     like setting up a real experiment. Or maybe not. Maybe better to keep some of this
//     hidden.
//  -- It would be nice to be able to automatically do the sum_model to add the 2D empty cell contribution
//     For some experiments it's quite useful to see the level of this contribution, rather than
//     the completely clean simulation.
//  -- in this file, clearly separate the examples from the utility functions
//  -- get a function list of everything, and document what each does (if not obvious)
//  -- step by step comments of one of the examples (1D and 2D) are probably the most useful
//  -- "dry run" function to estimate the total simulation time for 2D. (? set all monitor counts to 1000
//      or whatever I use to get other estimates, and then run through everything to get estimated times)
//
// set the global: 
// 	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just a time estimate, == 0 (default) to do the simulation
// and then do the dry run
//
//
// ----- transmission really doesn't work in the simulation...
// -- add function to simulate transmission in 2D by saving a "Trans" configuration
//     and automatically using that. Currently the trans is already written to the file
// x- would also need a function to simulate an empty beam measurement to rescale the 
//     transmissions. (use the model given, set scale (w[0] to something really small)
//  -- or better, use the empty cell function that is guaranteed to have coefficients that are
//     well behaved - and I can set/reset them to get a proper "empty beam"
//
//
// -- scattering from an empty cell is NOT provided in 2D

xMenu "Macros"
	Submenu "Simulation Scripting - Beta"
		"Save Configuration",Sim_saveConfProc()
		"Move to Configuration",Sim_moveConfProc()
		"List Configurations",ListSASCALCConfigs()
		"Setup Sim Example",Setup_Sim_Example()
		"1D Count Rates",DryRunProc_1D()
		"2D Dry Run",DryRunProc_2D()
		"Optimal Count Times",OptimalCountProc()
		"Make Table to Combine By Name",MakeCombineTable_byName()
		"Combine by Name",DoCombineFiles_byName(lowQfile,medQfile,hiQfile,saveName)
		"Turn Off Dead Time Correction",Sim_SetDeadTimeTiny()
	End
End

// run this before the examples to make sure that the proper named configurations exist.
// this function will overwrite any same-named waves
Function Setup_Sim_Example()

	SetDataFolder root:Packages:NIST:SAS:
	
	Make/O/T/N=20 Config_1m,Config_4m,Config_13m
	Config_1m = {"checkNG7","8","5.08 cm","6","0.115","checkChamber","1/2\"","0","100","25","","","","","","","","","",""}
	Config_4m = {"checkNG7","5","5.08 cm","6","0.115","checkChamber","1/2\"","0","400","0","","","","","","","","","",""}
	Config_13m = {"checkNG7","1","5.08 cm","6","0.115","checkChamber","1/2\"","0","1300","0","","","","","","","","","",""}
  
	SetDataFolder root:

End

Function Example_1DSim()

	String confList,ctTimeList,saveNameList,funcStr,titleStr
	

	Sim_SetSimulationType(0)		//kill the simulation panel
	Sim_SetSimulationType(1)		//open the 1D simulation panel
	
//(1)	enter the (unsmeared) function name
	funcStr = "SchulzSpheres_SC"
	Wave cw = $("root:"+getFunctionCoef(funcStr))
	Sim_SetModelFunction(funcStr)						// model function name
		
//(2) model coefficients here, if needed. Wave name is "cw"
//   then set the sample thickness. Be sure to use an appropriate incoherent background in the model
	Sim_Set1D_Transmission(0.75)						// For 1D, I need to supply the transmission
	Sim_SetThickness(0.2)								// thickness
	Sim_Set1D_ABS(1)										// absolute scaling (1== yes)
	Sim_Set1D_Noise(1)									// noise (1== yes, add statistical noise)

	cw[0] = 0.1
	// as needed - look at the parameter list for the model
	
	
//(3) set the configuration list, times, and saved names
// -- the mumber of listed configurations must match the number of discrete count times and save names
// titleStr is the label and is the same for each run of the same sample
	confList = "Config_1m;Config_4m;Config_13m;"
	ctTimeList = "100;300;900;"
	saveNameList = "sim_1m.abs;sim_4m.abs;sim_13m.abs;"
	titleStr = "MySample 1"

	// then this runs the samples as listed
	Sim_RunSample_1D(confList,ctTimeList,titleStr,saveNameList)

	// no transmissions or empty beam measurements to make for 1D simulation

	return(0)	
End

//
Function Example_2DSim()

	String confList,ctTimeList,titleStr,transConfList,transCtTimeList
	Variable runIndex,val,totalTime
	String funcStr

tic()

	Sim_SetSimulationType(0)		//kill the simulation panel
	Sim_SetSimulationType(2)		//open the 2D simulation panel
	Sim_SetSimTimeWarning(36000)			//sets the threshold for the warning dialog to 10 hours
	totalTime = 0


//(1)	enter the (unsmeared) function name
	funcStr = "SchulzSpheres_SC"
	Wave cw = $("root:"+getFunctionCoef(funcStr))
	Sim_SetModelFunction(funcStr)						// model function name

//(2) set the standard sample cell size (1" diam banjo cell)
// and set the conditions for beam stop in, and raw counts
	Sim_SetSampleRadius(1.27)							// sam radius (cm)
	Sim_SetRawCountsCheck(1)							// raw cts? 1== yes
	Sim_SetBeamStopInOut(1)								// BS in? 1==yes

//(3) model coefficients here, if needed. Wave name is "cw"
//   then set the sample thickness and incoherent cross section

	cw[0] = 0.1
	// as needed - look at the parameter list for the model

	Sim_SetThickness(0.2)								// thickness (cm)
	Sim_SetIncohXS(1.3)									// incoh XS
	
//(4) starting run index for the saved raw data files. this will automatically increment
//    as the sample is "Run"
	runIndex = 400
	
//(5) set the configuration list, times, a single sample label, and the starting run index
// -- the mumber of listed configurations must match the number of discrete count times
	confList = "Config_1m;Config_4m;Config_13m;"
	ctTimeList = "100;300;900;"
	transConfList = "Config_13m;"		// trans only @ 13m
	transCtTimeList = "1;"				// trans count time = 1s
	titleStr = "MySample 1"

	// runIndex is PBR and updates as the number of files are written
	
	// this runs the sample
	totalTime += Sim_RunSample_2D(confList,ctTimeList,titleStr,runIndex)
	// this runs the transmissions
	totalTime += Sim_RunTrans_2D(transConfList,transCtTimeList,titleStr,runIndex)
	
	// run the empty beam at all configurations
	// This will automatically change the function to "EC_Empirical" and "empty beam" conditions
	transConfList = "Config_1m;Config_4m;Config_13m;"
	transCtTimeList = "1;1;1;"	
	titleStr = "Empty Beam"
	totalTime += Sim_RunEmptyBeamTrans_2D(transConfList,transCtTimeList,titleStr,runIndex)
	
	Print "runIndex = ",runIndex

	Sim_SetSimTimeWarning(10)

toc()
	
	return(totalTime)
End

// this example was really used, run repeatedly with different count times to get
// replicate data sets to test the overlap
Function Example_Loop_1DSim()

	String confList,ctTimeList,saveNameList,funcStr,titleStr
	

	Sim_SetSimulationType(0)		//kill the simulation panel
	Sim_SetSimulationType(1)		//open the 1D simulation panel
	
//(1)	enter the (unsmeared) function name
	funcStr = "DAB_model"
	Wave cw = $("root:"+getFunctionCoef(funcStr))
	Sim_SetModelFunction(funcStr)						// model function name
		
//(2) model coefficients here, if needed. Wave name is "cw"
//   then set the sample thickness. Be sure to use an appropriate incoherent background in the model
	Sim_Set1D_Transmission(0.8)						// For 1D, I need to supply the transmission
	Sim_SetThickness(0.1)								// thickness
	Sim_Set1D_ABS(1)										// absolute scaling (1== yes)
	Sim_Set1D_Noise(1)									// noise (1== yes, add statistical noise)


	cw = {1e-05,200,0}
	
	
//(3) set the configuration list, times, and saved names
// -- the mumber of listed configurations must match the number of discrete count times and save names
// titleStr is the label and is the same for each run of the same sample
	confList = "Config_4m;"
	ctTimeList = ""		//filled in the loop
	saveNameList = ""
	titleStr = "DAB versus count time t = "

	Make/O/D ctTime = {5,11,16,21,27,32,37,43,48,53,107,160,214,267,321,374,428,481,535,1604,5348,21390,53476}

	Variable ii=0,nTrials=10,jj
	
	for(jj=0;jj<numpnts(ctTime);jj+=1)	
		for(ii=0;ii<nTrials;ii+=1)
			titleStr = "DAB versus count time t = "+num2str(ctTime[jj])
			saveNameList = "DAB_4m_t"+num2str(ctTime[jj])+"_"+num2str(ii)+".abs;"
			ctTimeList = num2str(ctTime[jj])+";"
			// then this runs the samples as listed
			Sim_RunSample_1D(confList,ctTimeList,titleStr,saveNameList)
		endfor
	endfor

	// no transmissions or empty beam measurements to make for 1D simulation

	return(0)	
End





// pass in a semicolon delimited list of configurations + corresponding count times + saved names
Function Sim_RunSample_1D(confList,ctTimeList,titleStr,saveNameList)
	String confList,ctTimeList,titleStr,saveNameList
	
	Variable ii,num,ct,cr,numPt
	String twStr,fname,type
	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just count rate, == 0 (default) to do the simulation and save
	WAVE/Z crWave = root:CR_1D
	WAVE/Z/T fileWave = root:Files_1D

	type = "SAS"		// since this is a simulation
	num=ItemsInList(confList)
	
	for(ii=0;ii<num;ii+=1)
		twStr = StringFromList(ii, confList,";")
		Wave/T tw=$("root:Packages:NIST:SAS:"+twStr)
		ct = str2num(StringFromList(ii, ctTimeList,";"))
		fname = StringFromList(ii, saveNameList,";")
		
		Sim_MoveToConfiguration(tw)
		Sim_SetCountTime(ct)
		cr = Sim_Do1DSimulation()
		
		// either save it out, or return a table of the count rates
		if(g_estimateOnly)
			numPt = numpnts(crWave)
			InsertPoints numPt, 1, crWave,fileWave
			crWave[numPt] = cr
			fileWave[numPt] = fname
		else
			Sim_Save1D_wName(type,titleStr,fname)		//this function will increment the runIndex
		endif
	
	endfor

	return(0)
End

// fakes an empty beam transmission by setting the conditions of the
// empty cell temporarily to something that doesn't scatter
Function Sim_RunEmptyBeamTrans_2D(confList,ctTimeList,titleStr,runIndex)
	String confList,ctTimeList,titleStr
	Variable &runIndex
	
	Wave cw = root:Packages:NIST:SAS:coef_ECEmp		//EC coefs are in the SAS folder, not root:
	Variable totalTime
	
	// change the function and coefficients
	Sim_SetModelFunction("EC_Empirical")
	cw = {1e-18,3.346,0,9,0}
	Sim_SetIncohXS(0)									// incoh XS = 0 for empty beam
	Sim_SetThickness(0.1)							// thickness (cm) to give proper level of scattering

		
	totalTime = Sim_RunTrans_2D(confList,ctTimeList,titleStr,runIndex)
		
	// change them back
	cw = {2.2e-08,3.346,0.0065,9,0.016}
	
	return(totalTime)
End

 
// should be called with each list having only one item
// and a count time of 1 s
//
// -- for an empty beam, before calling, set the incoh XS = 0 and set the scale
// of the model to something tiny so that there is no coherent scattering
//
Function Sim_RunTrans_2D(confList,ctTimeList,titleStr,runIndex)
	String confList,ctTimeList,titleStr
	Variable &runIndex
	
	Variable ii,num,ct,index,totalTime
	String twStr,type

	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just a time estimate, == 0 (default) to do the simulation
	NVAR g_estimatedMCTime = root:Packages:NIST:SAS:g_estimatedMCTime		// estimated MC sim time
	totalTime = 0
		
	type = "SAS"		// since this is a simulation
	num=ItemsInList(confList)
	
	for(ii=0;ii<num;ii+=1)
		twStr = StringFromList(ii, confList,";")
		Wave/T tw=$("root:Packages:NIST:SAS:"+twStr)
		ct = str2num(StringFromList(ii, ctTimeList,";"))
		
		Sim_MoveToConfiguration(tw)
		Sim_SetBeamStopInOut(0)								// BS out for Trans
		Sim_SetCountTime(ct)
		Sim_DoMCSimulation()
		
		if(g_estimateOnly)
			totalTime += g_estimatedMCTime		//	don't save, don't increment. time passed back as global after each MC simulation
		else
			SaveAsVAXButtonProc("",runIndex=runIndex,simLabel=(titleStr+" at "+twStr))
			runIndex += 1
		endif

	endfor
	
	Sim_SetBeamStopInOut(1)								// put the BS back in

	return(totalTime)
End



// if just an estimate, I can also get the count rate too
// WAVE results = root:Packages:NIST:SAS:results
//	Print "Sample Simulation (2D) CR = ",results[9]/ctTime
// -- for estimates, iMon is set to 1000, so time=1000/(root:Packages:NIST:SAS:gImon)
Function Sim_RunSample_2D(confList,ctTimeList,titleStr,runIndex)
	String confList,ctTimeList,titleStr
	Variable &runIndex

	Variable ii,num,ct,index,totalTime
	String twStr,type

	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just a time estimate, == 0 (default) to do the simulation
	NVAR g_estimatedMCTime = root:Packages:NIST:SAS:g_estimatedMCTime		// estimated MC sim time
	totalTime = 0
	
	type = "SAS"		// since this is a simulation
	num=ItemsInList(confList)
	
	
	for(ii=0;ii<num;ii+=1)
		twStr = StringFromList(ii, confList,";")
		Wave/T tw=$("root:Packages:NIST:SAS:"+twStr)
		ct = str2num(StringFromList(ii, ctTimeList,";"))
		
		Sim_MoveToConfiguration(tw)
		Sim_SetBeamStopInOut(1)								// BS in?
		Sim_SetCountTime(ct)
		Sim_DoMCSimulation()
		
		if(g_estimateOnly)
			totalTime += g_estimatedMCTime		//	don't save, don't increment. time passed back as global after each MC simulation
		else
			SaveAsVAXButtonProc("",runIndex=runIndex,simLabel=(titleStr+" at "+twStr))
			runIndex += 1
		endif
		
	endfor

	return(totalTime)
End

// a prototype function with no parameters
// for a real experiment - it must return the total time, if you want a proper estimate
Function Sim_Expt_Proto()
	Print "In the Sim_Expt_Proto -- error"
	return(0)
End

Proc DryRunProc_2D(funcStr)
	String funcStr
	Sim_2DDryRun(funcStr)
end

// pass the function string, no parameters
Function Sim_2DDryRun(funcStr)
	String funcStr
	
	FUNCREF Sim_Expt_Proto func=$funcStr
	
	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly
	g_estimateOnly = 1
	
	Variable totalTime
//	totalTime = Sim_CountTime_2D()	// your "exeriment" here, returning the totalTime
	
	totalTime = func()
	g_estimateOnly = 0
	
	Printf "Total Estimated Time = %g s or %g h\r",totalTime,totalTime/3600
end

Proc DryRunProc_1D(funcStr)
	String funcStr
	Sim_1DDryRun(funcStr)
end

// pass the function string, no parameters
// makes a (new) table of the files and CR
Function Sim_1DDryRun(funcStr)
	String funcStr
	
	FUNCREF Sim_Expt_Proto func=$funcStr
	
	NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly
	g_estimateOnly = 1
	
	Variable totalTime
	
	Make/O/D/N=0 root:CR_1D
	Make/O/T/N=0 root:Files_1D
	
	totalTime = func()
	g_estimateOnly = 0
	
	Edit Files_1D,CR_1D
	
//	Printf "Total Estimated Time = %g s or %g h\r",totalTime,totalTime/3600
	return(0)
end





Proc OptimalCountProc(samCountRate,emptyCountRate)
	Variable samCountRate,emptyCountRate
	OptimalCount(samCountRate,emptyCountRate)
End

Function OptimalCount(samCR,empCR)
	Variable samCR,empCR
	
	String str
	Variable ratio,target
	ratio = sqrt(samCR/empCR)
	
	str = "For %g Sample counts, t sam = %g s and t emp = %g s\r"
	
	target = 1e6
	printf str,target,round(target/samCR),round((target/samCR)/ratio)
	
	target = 1e5
	printf str,target,round(target/samCR),round((target/samCR)/ratio)	

	target = 1e4
	printf str,target,round(target/samCR),round((target/samCR)/ratio)	
	return(0)
end


//
// Important - in the reduction process, set the  dead time correction to something
// really small, say 10^-15 so that  it won't have any effect (since the detector CR is fictionally high)
//
Function Sim_SetDeadTimeTiny()

//	NVAR DeadtimeNG3_ILL = root:myGlobals:DeadtimeNG3_ILL		//pixel resolution in cm
//	NVAR DeadtimeNG5_ILL = root:myGlobals:DeadtimeNG5_ILL
//	NVAR DeadtimeNG7_ILL = root:myGlobals:DeadtimeNG7_ILL
//	NVAR DeadtimeNGB_ILL = root:myGlobals:DeadtimeNGB_ILL
	NVAR DeadtimeNG3_ORNL_VAX = root:myGlobals:DeadtimeNG3_ORNL_VAX
//	NVAR DeadtimeNG3_ORNL_ICE = root:myGlobals:DeadtimeNG3_ORNL_ICE
//	NVAR DeadtimeNG5_ORNL = root:myGlobals:DeadtimeNG5_ORNL
	NVAR DeadtimeNG7_ORNL_VAX = root:myGlobals:DeadtimeNG7_ORNL_VAX
//	NVAR DeadtimeNG7_ORNL_ICE = root:myGlobals:DeadtimeNG7_ORNL_ICE
	NVAR DeadtimeNGB_ORNL_ICE = root:myGlobals:DeadtimeNGB_ORNL_ICE
	NVAR DeadtimeDefault = root:myGlobals:DeadtimeDefault

	DeadtimeNG3_ORNL_VAX = 1e-15
	DeadtimeNG7_ORNL_VAX = 1e-15
	DeadtimeNGB_ORNL_ICE = 1e-15
	DeadtimeDefault = 1e-15
	
	return(0)
End



/////////////////////////////////////////////////////////////////////
///////////// All of the utility functions to make things "move"



// set the wavelength
Function Sim_SetLambda(val)
	Variable val

	NVAR lam = root:Packages:NIST:SAS:gLambda
	lam=val
	LambdaSetVarProc("",val,num2str(val),"")
	return(0)
end

// set the wavelength spread
// ?? what are the allowable choices
// there are 3 choices for each instrument
// 
// TO DO ?? do this in a better way
// currently there is no error checking...
//
Function Sim_SetDeltaLambda(strVal)
	String strVal
	
	
	DeltaLambdaPopMenuProc("",1,strVal)		// recalculates intensity if 2nd param==1, skip if == 0
	PopupMenu popup0_2 win=SASCALC,popmatch=strVal
//	ControlUpdate/W=SASCALC popup0_2
	
	return(0)
End

// if state == 0, lenses out (box un-checked, no parameters change)
// if state == 1, lenses in, changes guides, aperture, SDD and wavelength appropriately
// if prisms desired, follow this call with a set wavelength=17.2
Function Sim_SetLenses(state)
	Variable state
	
	LensCheckProc("",state)
	CheckBox checkLens,win=SASCALC,value=state
	
	return(0)
End

// instrName = "checkNG3" or "checkNG7" or "checkNGB"
// these are the only allowable choices
Function Sim_SetInstrument(instrName)
	String instrName
	
	SelectInstrumentCheckProc(instrName,0)
	return(0)
End


//two steps to change the number of guides
// - first the number of guides, then the source aperture (if 0g, 7g where there are choices)
//
// strVal is "5 cm" or "1.43 cm" (MUST be identical to the popup string, MUST have the units)
///
Function Sim_SetNumGuides_SrcAp(ng,strVal)
	Variable ng
	String strVal

	NVAR gNg=root:Packages:NIST:SAS:gNg
	gNg = ng
	
	Slider SC_Slider,win=SASCALC,variable=root:Packages:NIST:SAS:gNg				//guides

	// with the new number of guides, update the allowable source aperture popups
	DoWindow/F SASCALC
	UpdateControls()
	
	// TO DO -- this needs some logic added, or an additional parameter to properly set the 
	// source aperture
	
	popupmenu popup0 win=SASCALC,popmatch=strVal
	Variable dum=sourceApertureDiam()		//sets the proper value in the header wave
	return(0)
End

// strVal is "1/2\"" or similar. note the extra backslash so that " is part of the string
//
Function Sim_SetSampleApertureDiam(strVal)
	String strVal
	
	popupmenu popup0_1 win=SASCALC,popmatch=strVal
	Variable dum=sampleApertureDiam()		//sets the proper value in the header wave
	return(0)
End	

Function Sim_SetOffset(offset)
	Variable offset
	
	NVAR detOffset = root:Packages:NIST:SAS:gOffset
	detOffset = offset	//in cm
	detectorOffset()		//changes header and estimates (x,y) beamcenter
	return(0)
end

Function Sim_SetSDD(sdd)
	Variable sdd
	
	NVAR detDist = root:Packages:NIST:SAS:gDetDist

	detDist = sdd
	sampleToDetectorDist()		//changes the SDD and wave (DetDist is the global)
	return(0)
end


// change the huber/sample chamber position
// if str="checkHuber", the pos is set to huber
// otherwise, it's set to the sample chamber position
//
Function Sim_SetTablePos(strVal)
	String strVal
	
	TableCheckProc(strVal,0)
	return(0)
end


//
// ------------ specifc for the simulation
//
//
// type = 0 = none, kills panel
// type = 1 = 1D
// type = 2 = 2D
//
// -- DON'T leave the do2D global set to 1 - be sure to set back to 0 before exiting
//
Function Sim_SetSimulationType(type)
	Variable type

	STRUCT WMCheckboxAction CB_Struct
	Variable checkState
	if(type == 1 || type == 2)
		CB_Struct.checked = 1
		checkState = 1
	else
		CB_Struct.checked = 0
		checkState = 0
	endif

	NVAR do2D = root:Packages:NIST:SAS:gDoMonteCarlo

	if(type == 1)
		do2D = 0
	else
		do2D = 1
	endif
	
	SimCheckProc(CB_Struct)

	// Very important
	do2D = 0
	
	CheckBox checkSim win=SASCALC,value=checkState
	return(0)
End

Function Sim_DoMCSimulation()

	STRUCT WMButtonAction ba
	ba.eventCode = 2			//fake mouse click on button

	MC_DoItButtonProc(ba)
	return(0)
End

Function Sim_Do1DSimulation()

	ReCalculateInten(1)
	NVAR estCR = root:Packages:NIST:SAS:g_1DEstDetCR
	return(estCR)
End

// counting time (set this last - after all of the instrument moves are done AND the 
// intensity has been updated)
//
// ctTime is in seconds
// sets the global variable, and fakes an "entry" in that field
Function Sim_SetCountTime(ctTime)
	Variable ctTime
	
	STRUCT WMSetVariableAction sva
	NVAR ct = root:Packages:NIST:SAS:gCntTime
	ct=ctTime
	sva.dval = ctTime			//seconds
	sva.eventCode = 3		//live update code
	CountTimeSetVarProc(sva)
	return(0)
End


Function Sim_SetIncohXS(val)
	Variable val
	
	NVAR xs = root:Packages:NIST:SAS:gSig_incoh
	xs = val
	return(0)
End

Function Sim_SetThickness(val)
	Variable val
	
	NVAR th = root:Packages:NIST:SAS:gThick
	th = val
	return(0)
End

Function Sim_SetSampleRadius(val)
	Variable val
	
	NVAR r2 = root:Packages:NIST:SAS:gR2
	r2 = val
	
	return(0)
End

Function Sim_SetNumberOfNeutrons(val)
	Variable val
	
	NVAR num = root:Packages:NIST:SAS:gImon
	num = val
	
	return(0)
End

// 1 == beam stop in
// 0 == beam stop out == transmission
//
Function Sim_SetBeamStopInOut(val)
	Variable val
	
	NVAR BS = root:Packages:NIST:SAS:gBeamStopIn			//set to zero for beamstop out (transmission)
	WAVE rw=root:Packages:NIST:SAS:realsRead
	
	BS = val			//set the global
	
	// fake the header
	if(BS == 1)
		rw[37] = 0				// make sure BS X = 0 if BS is in
	else
		rw[37] = -10			// fake BS out as X = -10 cm
	endif
	
	return(0)
End

Function Sim_SetRawCountsCheck(val)
	Variable val
	
	NVAR rawCt = root:Packages:NIST:SAS:gRawCounts
	rawCt = val
	return(0)
End

Function Sim_Set1D_ABS(val)
	Variable val
	
	NVAR gAbs = root:Packages:NIST:SAS:g_1D_DoABS
	gAbs = val
	
	return(0)
End

Function Sim_Set1D_Noise(val)
	Variable val
	
	NVAR doNoise = root:Packages:NIST:SAS:g_1D_AddNoise
	doNoise = val
	return(0)
End

Function Sim_Set1D_Transmission(val)
	Variable val
	
	NVAR trans = root:Packages:NIST:SAS:gSamTrans
	trans = val
	return(0)
End

Function Sim_SetModelFunction(strVal)
	String strVal
	
	DoWindow MC_SASCALC
	if(V_flag==1)
		//then 2D
		PopupMenu MC_popup0 win=MC_SASCALC,popmatch=strVal
	endif
	
	DoWindow	Sim_1D_Panel
	if(V_flag==1)
		//then 1D
		PopupMenu MC_popup0 win=Sim_1D_Panel,popmatch=strVal
	endif
	
	SVAR gStr = root:Packages:NIST:SAS:gFuncStr 
	gStr = strVal

	return(0)
End


// ------------

//
// set the threshold for the time warning dialog to some really large value (say 36000 s)
// while doing the simulation to keep the dialog from popping up and stopping the simulation.
// then be sure to set it back to 10 s for "normal" simulations that are atttended
//
// input val is in seconds
Function Sim_SetSimTimeWarning(val)
	Variable val

	NVAR SimTimeWarn = root:Packages:NIST:SAS:g_SimTimeWarn
	SimTimeWarn = val			//sets the threshold for the warning dialog	

	return(0)
end

// if you need to eliminate the high count data to save the rest of the set
Function Sim_TrimOverflowCounts()
	Wave w = root:Packages:NIST:SAS:linear_data
	w = (w > 2767000) ? 0 : w
	return(0)
End

// if home path exists, save there, otherwise present a dialog
// (no sense to use catPathName, since this is simulation, not real data
//
Function Sim_Save1D_wName(type,titleStr,fname)
	String type,titleStr,fname
	
	String fullPath
	NVAR autoSaveIndex = root:Packages:NIST:SAS:gAutoSaveIndex

	//now save the data	
	PathInfo home
	fullPath = S_path + fname
	
	Save_1DSimData("",runIndex=autoSaveIndex,simLabel=titleStr,saveName=fullPath)
	
	autoSaveIndex += 1
	return(0)
End

Proc Sim_saveConfProc(waveStr)
	String waveStr
	
	Sim_SaveConfiguration(waveStr)
End
//
// just make a wave and fill it
// I'll keep track of what's in each element
// -- not very user friendly, but nobody needs to see this
//
// poll the panel to fill it in
//
// 0 = instrument
// 1 = number of guides
// 2 = source aperture
// 3 = lambda
// 4 = delta lambda
// 5 = huber/chamber
// 6 = sample aperture
// 7 = lenses/prism/none
// 8 = SDD
// 9 = offset
//
Function Sim_SaveConfiguration(waveStr)
	String waveStr
	
	String str=""
	
	SetDataFolder root:Packages:NIST:SAS
	
	Make/O/T/N=20 $("Config_"+waveStr)
	Wave/T tw=$("Config_"+waveStr)
	tw = ""
	
	// 0 = instrument
	SVAR instStr = root:Packages:NIST:SAS:gInstStr
	tw[0] = "check"+instStr
	
	// 1 = number of guides
	NVAR ng = root:Packages:NIST:SAS:gNg
	tw[1] = num2str(ng)
	
	// 2 = source aperture
	ControlInfo/W=SASCALC popup0
	tw[2] = S_Value
	
	// 3 = lambda
	NVAR lam = root:Packages:NIST:SAS:gLambda
	tw[3] = num2str(lam)
	
	// 4 = delta lambda
//	NVAR dlam = root:Packages:NIST:SAS:gDeltaLambda
//	tw[4] = num2str(dlam)
	
	//or
	ControlInfo/W=SASCALC popup0_2
	tw[4] = S_Value
	
	
	// 5 = huber/chamber
	NVAR sampleTable = root:Packages:NIST:SAS:gTable		//2=chamber, 1=table
	if(sampleTable==1)
		str = "checkHuber"
	else
		str = "checkChamber"
	endif
	tw[5] = str
	
	// 6 = sample aperture
	ControlInfo/W=SASCALC popup0_1
	tw[6] = S_Value
	
	// 7 = lenses/prism/none
	NVAR lens = root:Packages:NIST:SAS:gUsingLenses		//==0 for no lenses, 1 for lenses(or prisms)
	tw[7] = num2str(lens)
	
	// 8 = SDD
	NVAR sdd = root:Packages:NIST:SAS:gDetDist
	tw[8] = num2str(sdd)
	
	// 9 = offset
	NVAR offset = root:Packages:NIST:SAS:gOffset
	tw[9] = num2str(offset)
	
	//
	
	SetDataFolder root:
	return(0)
End

Proc Sim_moveConfProc(waveStr)
	String waveStr
	Prompt waveStr,"Select Configuration",popup,ListSASCALCConfigs()
	
	Sim_MoveToConfiguration($("root:Packages:NIST:SAS:"+waveStr))
End
// restore the configuration given a wave of information
//
// be sure to recalculate the intensity after all is set
// -- some changes recalculate, some do not...
//
Function Sim_MoveToConfiguration(tw)
	WAVE/T tw


// 0 = instrument
	Sim_SetInstrument(tw[0])
	 
// 1 = number of guides
// 2 = source aperture
	Sim_SetNumGuides_SrcAp(str2num(tw[1]),tw[2])
	
// 3 = lambda
	Sim_SetLambda(str2num(tw[3]))
	
// 4 = delta lambda
	Sim_SetDeltaLambda(tw[4])

// 5 = huber/chamber
	Sim_SetTablePos(tw[5])

// 6 = sample aperture
	Sim_SetSampleApertureDiam(tw[6])

// 7 = lenses/prism/none
	Sim_SetLenses(str2num(tw[7]))
	
// 8 = SDD
	Sim_SetSDD(str2num(tw[8]))

// 9 = offset
	Sim_SetOffset(str2num(tw[9]))


	ReCalculateInten(1)
	return(0)
end


///////////// a panel to (maybe) write to speed the setup of the runs
//
Function/S ListSASCALCConfigs()
	String str
	SetDataFolder root:Packages:NIST:SAS
	str = WaveList("Conf*",";","")
	SetDataFolder root:
	print str
	return(str)
End

//Proc Sim_SetupRunPanel() : Panel
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(399,44,764,386)
//	ModifyPanel cbRGB=(56639,28443,117)
//	ShowTools/A
//EndMacro
