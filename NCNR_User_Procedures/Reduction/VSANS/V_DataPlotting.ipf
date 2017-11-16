#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0


//
// functions to plot the averaged data in various views and binning types
//



//
// simple entry procedure
//
// graph with the 1D representation of the VSANS detectors
//
// TODO:
// -- add multiple options for how to present/rescale the data
// -- automatically position the window next to the 2D data
// -- color coding of the different panels (data tags/arrows/toggle on/off)?
// -- VERIFY accuracy
//
// -- decide what to add to the control bar
// ()()() In SANS, there are only 3 waves (q-i-s) and these are copied over to the plot1D folder, and the copy
//    of the data is plotted, not the data in the WORK folder. Then for rescaling, a "fresh" copy of the data is
//    fetched, and then rescaled. The plot automatically reflects these changes.
//  --- for VSANS, this is much more difficult since there are multiple possibilites of 1D data, depending on the
//     binning chosen. Currently, the data is plotted directly from the WORK folder, so this would need to be changed
//     at the start, then deciding which waves to copy over. Messy. Very Messy. For now, simply toggle log/lin
//
// -- at the very least, add a log/lin toggle for the axes
//
// -- document, document, document
//
// -- see Middle_IQ_Graph() and similar for how VCALC does this plot
//
// -- when/if I want to add phi-averaging to this, go gack to AvgGraphics.ipf for the pink panel
//    and to the function Draw_Plot1D() for the drawing of the plot
//
// If -9999 is passed in as the "binType", then read the proper value from the popup on the graph.
//  otherwise, assume that a proper value has been passed in, say from the reduction protocol
//
Function V_PlotData_Panel()
//	Variable binType

	DoWindow/F V_1D_Data
	if(V_flag==0)
	
//		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Plot_1D
//		Variable/G root:Packages:NIST:VSANS:Globals:Plot_1D:gYMode = 1
//		Variable/G root:Packages:NIST:VSANS:Globals:Plot_1D:gXMode = 1
//		Variable/G root:Packages:NIST:VSANS:Globals:Plot_1D:gExpA = 1
//		Variable/G root:Packages:NIST:VSANS:Globals:Plot_1D:gExpB = 1
//		Variable/G root:Packages:NIST:VSANS:Globals:Plot_1D:gExpC = 1
		
		
		Display /W=(277,526,748,938)/N=V_1D_Data/K=1

		ControlBar 70
		
		PopupMenu popup0,pos={16,5},size={71,20},title="Bin Type"
		PopupMenu popup0,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
		PopupMenu popup0,value= ksBinTypeStr
		PopupMenu popup0,mode=1,proc=V_BinningModePopup
		
		CheckBox check0,pos={18.00,36.00},size={57.00,16.00},proc=V_Plot1D_LogCheckProc,title="Log Axes"
		CheckBox check0,value= 1
	
//		PopupMenu ymodel,pos={150,5},size={71,20},title="y-axis"
//		PopupMenu ymodel,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
//		PopupMenu ymodel,value= #"\"I;log(I);ln(I);1/I;I^a;Iq^a;I^a q^b;1/sqrt(I);ln(Iq);ln(Iq^2)\""
//		PopupMenu ymodel,mode=NumVarOrDefault("root:Packages:NIST:VSANS:Globals:Plot_1d:gYMode", 1 ),proc=V_YMode_PopMenuProc
//		PopupMenu xmodel,pos={220,5},size={74,20},title="x-axis"
//		PopupMenu xmodel,help={"This popup selects how the x-axis will be linearized given the chosen data"}
//		PopupMenu xmodel,value= #"\"q;log(q);q^2;q^c\""
//		PopupMenu xmodel,mode=NumVarOrDefault("root:Packages:NIST:VSANS:Globals:Plot_1d:gXMode", 1 ),proc=V_XMode_PopMenuProc
////		Button Rescale,pos={281,5},size={70,20},proc=V_Rescale_Plot_1D_ButtonProc,title="Rescale"
////		Button Rescale,help={"Rescale the x and y-axes of the data"},disable=1
//
//		SetVariable expa,pos={120,28},size={80,15},title="pow \"a\""
//		SetVariable expa,help={"This sets the exponent \"a\" for some y-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//		SetVariable expa,limits={-2,10,0},value= root:Packages:NIST:VSANS:Globals:Plot_1d:gExpA
//		SetVariable expb,pos={120,46},size={80,15},title="pow \"b\""
//		SetVariable expb,help={"This sets the exponent \"b\" for some x-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//		SetVariable expb,limits={0,10,0},value= root:Packages:NIST:VSANS:Globals:Plot_1d:gExpB
//
//		SetVariable expc,pos={220,28},size={80,15},title="pow \"c\""
//		SetVariable expc,help={"This sets the exponent \"c\" for some x-axis formats. The value is ignored if the model does not use \"c\" as an adjustable exponent"}
//		SetVariable expc,limits={-10,10,0},value= root:Packages:NIST:VSANS:Globals:Plot_1d:gExpC
		
		Button AllQ,pos={320,28},size={70,20},proc=V_AllQ_Plot_1D_ButtonProc,title="All Q"
		Button AllQ,help={"Show the full q-range of the dataset"}
		
		Legend/C/N=text0/J/X=72.00/Y=60.00
	endif
		
	
//	SVAR workType = root:Packages:NIST:VSANS:Globals:gCurDispType
//
//	if(binType == -9999)
//		binType = V_GetBinningPopMode()		//dummy passed in, replace with value from panel
//	endif
//	
//	
//	V_QBinAllPanels(workType,binType)


	
End

// 
// x- winStr is currently hard-wired, but this may not be an issue
Function V_Update1D_Graph(workType,binType)
	String workType
	Variable binType
	
	// 
// x- "B" detector is currently skipped - Q is not yet calculated
	String str,winStr="V_1D_Data",workPathStr
	workPathStr = "root:Packages:NIST:VSANS:"+worktype
	
	sprintf str,"(\"%s\",%d,\"%s\")",workPathStr,binType,winStr
	
	Execute ("V_Back_IQ_Graph"+str)
//	Print "V_Back_IQ_Graph"+str
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)

	
	return(0)
end

Function V_Plot1D_LogCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
				
				ModifyGraph log=(checked)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
////function to set the popItem (mode) of the graph, to re-create the graph based on user preferences
//Function V_YMode_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//	Variable/G root:Packages:NIST:VSANS:Globals:Plot_1d:gYMode=popNum
//	V_Rescale_Plot_1D_ButtonProc("")
//End
//
////function to set the popItem (mode) of the graph, to re-create the graph based on user preferences
//Function V_XMode_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//	Variable/G root:Packages:NIST:VSANS:Globals:Plot_1d:gXMode=popNum
//	V_Rescale_Plot_1D_ButtonProc("")
//End


//function to rescale the axes of the graph as selected from the popups and the 
// entered values of the exponents
//** assumes the current waves are unknown, so it goes and gets a "fresh" copy from
//the data folder specified by the waves on the graph, which is the same folder that
//contains the "fresh" copy of the 1D data
//
// for log(10) scaling, simply modify the axes, not the data - gives better plots
//
//Function V_Rescale_Plot_1D_ButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	
//	DoWindow/F V_1D_Data
////Scaling exponents and background value
//	Variable pow_a,pow_b,pow_c
//	ControlInfo expa
//	pow_a = V_value
//	ControlInfo expb
//	pow_b = V_value
//	ControlInfo expc
//	pow_c = V_value
//	
////check for physical limits on exponent values, abort if bad values found
//	if((pow_a < -2) || (pow_a > 10))
//		Abort "Exponent a must be in the range (-2,10)"
//	endif
//	if((pow_b < 0) || (pow_b > 10))
//		Abort "Exponent b must be in the range (0,10)"
//	endif
//	//if q^c is the x-scaling, c must be be within limits and also non-zero
//	ControlInfo xModel
//	If (cmpstr("q^c",S_Value) == 0)
//		if(pow_c == 0) 
//			Abort "Exponent c must be non-zero, q^0 = 1"
//		endif
//		if((pow_c < -10) || (pow_c > 10))
//			Abort "Exponent c must be in the range (-10,10)"
//		endif
//	endif		//check q^c exponent
//	
//// get the current experimental q, I, and std dev. waves
//	SVAR curFolder=root:Packages:NIST:VSANS:Globals:gDataDisplayType
//
//// what is the binning? == what waves do we need to copy over
//	
//
//	//get the untarnished data, so we can rescale it freshly here
//	Wave yw = $("root:Packages:NIST:"+curFolder+":aveint")
//	Wave ew = $("root:Packages:NIST:"+curFolder+":sigave")
//	//get the correct x values
//	NVAR isPhiAve= root:myGlobals:Plot_1d:isPhiAve 	//0 signifies (normal) x=qvals
//	if(isPhiAve)
//		//x is angle
//		Wave xw=$("root:Packages:NIST:"+curFolder+":phival")
//	else
//		//x is q-values
//		Wave xw=$("root:Packages:NIST:"+curFolder+":qval")
//	endif
//	Wave yAxisWave=root:myGlobals:Plot_1d:yAxisWave		//refs to waves to be modified, hard-wired positions
//	Wave xAxisWave=root:myGlobals:Plot_1d:xAxisWave
//	Wave yErrWave=root:myGlobals:Plot_1d:yErrWave
//	
//	//variables set for each model to control look of graph
//	String xlabel,ylabel,xstr,ystr
//	Variable logLeft=0,logBottom=0
//	//check for proper y-scaling selection, make the necessary waves
//	ControlInfo yModel
//	ystr = S_Value
//	do
//		If (cmpstr("I",S_Value) == 0)
//			SetScale d 0,0,"1/cm",yAxisWave
//			yErrWave = ew
//			yAxisWave = yw
//			ylabel = "I(q)"
//			break	
//		endif
//		If (cmpstr("ln(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yw
//			yAxisWave = ln(yw)
//			ylabel = "ln(I)"
//			break	
//		endif
//		If (cmpstr("log(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yAxisWave = yw
//			yErrWave = ew
//			logLeft=1				//scale the axis, not the wave
//			ylabel = "I(q)"
////			yErrWave = ew/(2.30*yw)
////			yAxisWave = log(yw)
////			ylabel = "log(I)"
//			break	
//		endif
//		If (cmpstr("1/I",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yw^2
//			yAxisWave = 1/yw
//			ylabel = "1/I"
//			break
//		endif
//		If (cmpstr("I^a",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*abs(pow_a*(yw^(pow_a-1)))
//			yAxisWave = yw^pow_a
//			ylabel = "I^"+num2str(pow_a)
//			break
//		endif
//		If (cmpstr("Iq^a",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*xw^pow_a
//			yAxisWave = yw*xw^pow_a
//			ylabel = "I*q^"+num2str(pow_a)
//			break
//		endif
//		If (cmpstr("I^a q^b",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*abs(pow_a*(yw^(pow_a-1)))*xw^pow_b
//			yAxisWave = yw^pow_a*xw^pow_b
//			ylabel = "I^" + num2str(pow_a) + "q^"+num2str(pow_b)
//			break
//		endif
//		If (cmpstr("1/sqrt(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = 0.5*ew*yw^(-1.5)
//			yAxisWave = 1/sqrt(yw)
//			ylabel = "1/sqrt(I)"
//			break
//		endif
//		If (cmpstr("ln(Iq)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave =ew/yw
//			yAxisWave = ln(xw*yw)
//			ylabel = "ln(q*I)"
//			break
//		endif
//		If (cmpstr("ln(Iq^2)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yw
//			yAxisWave = ln(xw*xw*yw)
//			ylabel = "ln(I*q^2)"
//			break
//		endif
//		//more ifs for each case as they are added
//		
//		// if selection not found, abort
//		DoAlert 0,"Y-axis scaling incorrect. Aborting"
//		Abort
//	while(0)	//end of "case" statement for y-axis scaling
//	
//	//check for proper x-scaling selection
//	SVAR/Z angst = root:Packages:NIST:gAngstStr 
//	String dum
//	
//	ControlInfo xModel
//	xstr = S_Value
//	do
//		If (cmpstr("q",S_Value) == 0)	
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = xw
//			if(isPhiAve)
//				xlabel="Angle (deg)"
//			else
//				xlabel = "q ("+angst+"\\S-1\\M)"
//			endif
//			break	
//		endif
//		If (cmpstr("q^2",S_Value) == 0)	
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = xw*xw
//			if(isPhiAve)
//				xlabel="(Angle (deg) )^2"
//			else
//				xlabel = "q^2 ("+angst+"\\S-2\\M)"
//			endif
//			break	
//		endif
//		If (cmpstr("log(q)",S_Value) == 0)	
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = xw		//scale the axis, not the wave
//			//xAxisWave = log(xw)
//			logBottom=1
//			if(isPhiAve)
//				//xlabel="log(Angle (deg))"
//				xlabel="Angle (deg)"
//			else
//				//xlabel = "log(q)"
//				xlabel = "q ("+angst+"\\S-1\\M)"
//			endif
//			break	
//		endif
//		If (cmpstr("q^c",S_Value) == 0)
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = xw^pow_c
//			dum = num2str(pow_c)
//			if(isPhiAve)
//				xlabel="Angle^"+dum
//			else
//				xlabel = "q^"+dum+" ("+angst+"\\S-"+dum+"\\M)"
//			endif
//			break
//		endif
//	
//		//more ifs for each case
//		
//		// if selection not found, abort
//		DoAlert 0,"X-axis scaling incorrect. Aborting"
//		Abort
//	while(0)	//end of "case" statement for x-axis scaling
//	
//	Label left ylabel
//	Label bottom xlabel	//E denotes "scaling"  - may want to use "units" instead	
//	ModifyGraph log(left)=(logLeft)
//	ModifyGraph log(bottom)=(logBottom)
//	
//End


//function to restore the graph axes to full scale, undoing any zooming
Function V_AllQ_Plot_1D_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SetAxis/A
End


//
// recalculate the I(q) binning. no need to adjust model function or views
// just rebin
//
// see V_CombineModePopup() in V_Combine_1D.ipf for a duplicate version of this function
//
Function V_BinningModePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

// dispatch based on the string, not on the number of selection in the pop string
	V_QBinAllPanels_Circular(type,V_BinTypeStr2Num(popStr))

	String str,winStr="V_1D_Data",workTypeStr
	workTypeStr = "root:Packages:NIST:VSANS:"+type
	
	sprintf str,"(\"%s\",%d,\"%s\")",workTypeStr,V_BinTypeStr2Num(popStr),winStr

	Execute ("V_Back_IQ_Graph"+str)
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)

	
	return(0)	
End

Function V_GetBinningPopMode()

	Variable binType
	
	if(WinType("V_1D_Data")==0)
		DoAlert 0,"V_1D_Data window is not open, called from V_GetBinningPopMode()"
		return(0)
	endif
	
	ControlInfo/W=V_1D_Data popup0
	binType = V_BinTypeStr2Num(S_Value)
	
	return(binType)
end

//
// duplicated from Middle_IQ_Graph from VCALC
// but plotted in a standalone graph window and not the VCALC subwindow
//
// V_1D_Data
//
// 
// x- need to set binType
// x- currently  hard-wired == 1
//
// input "fullPathToFolder" is the data type and defines the folder, 
// i.e. "root:Packages:NIST:VSANS:"+"SAM"
//
Proc V_Middle_IQ_Graph(fullPathToFolder,binType,winNameStr) 
	String fullPathToFolder
	Variable binType
	String winNameStr

//	binType = V_GetBinningPopMode()
	SetDataFolder $(fullPathToFolder)

// clear EVERYTHING
	ClearIQIfDisplayed_AllFldr("MLRTB",winNameStr)
	ClearIQIfDisplayed_AllFldr("MLR",winNameStr)
	ClearIQIfDisplayed_AllFldr("MTB",winNameStr)		//this returns to root:
	ClearIQIfDisplayed_AllFldr("MT",winNameStr)	
	ClearIQIfDisplayed_AllFldr("ML",winNameStr)	
	ClearIQIfDisplayed_AllFldr("MR",winNameStr)	
	ClearIQIfDisplayed_AllFldr("MB",winNameStr)		


// then replace the traces as needed, depending on the binType

	if(binType==1)
	
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=$winNameStr iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=$winNameStr iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=$winNameStr iBin_qxqy_MB vs qBin_qxqy_MB
			ErrorBars/T=0 iBin_qxqy_ML Y,wave=(:eBin_qxqy_ML,:eBin_qxqy_ML)
			ErrorBars/T=0 iBin_qxqy_MR Y,wave=(:eBin_qxqy_MR,:eBin_qxqy_MR)
			ErrorBars/T=0 iBin_qxqy_MT Y,wave=(:eBin_qxqy_MT,:eBin_qxqy_MT)
			ErrorBars/T=0 iBin_qxqy_MB Y,wave=(:eBin_qxqy_MB,:eBin_qxqy_MB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
	endif
	
	if(binType==2)
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLR vs qBin_qxqy_MLR
			AppendToGraph/W=$winNameStr iBin_qxqy_MTB vs qBin_qxqy_MTB
			ErrorBars/T=0 iBin_qxqy_MLR Y,wave=(:eBin_qxqy_MLR,:eBin_qxqy_MLR)
			ErrorBars/T=0 iBin_qxqy_MTB Y,wave=(:eBin_qxqy_MTB,:eBin_qxqy_MTB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLR)=(65535,0,0),rgb(iBin_qxqy_MTB)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_MLR)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLRTB vs qBin_qxqy_MLRTB
			ErrorBars/T=0 iBin_qxqy_MLRTB Y,wave=(:eBin_qxqy_MLRTB,:eBin_qxqy_MLRTB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLRTB)=(65535,0,0)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_ML
		
		if(V_flag==0)
			AppendToGraph/W=$winNameStr iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=$winNameStr iBin_qxqy_MR vs qBin_qxqy_MR
//			AppendToGraph/W=$winNameStr iBin_qxqy_MT vs qBin_qxqy_MT
//			AppendToGraph/W=$winNameStr iBin_qxqy_MB vs qBin_qxqy_MB
			ErrorBars/T=0 iBin_qxqy_ML Y,wave=(:eBin_qxqy_ML,:eBin_qxqy_ML)
			ErrorBars/T=0 iBin_qxqy_MR Y,wave=(:eBin_qxqy_MR,:eBin_qxqy_MR)
//			ErrorBars/T=0 iBin_qxqy_MT Y,wave=(:eBin_qxqy_MT,:eBin_qxqy_MT)
//			ErrorBars/T=0 iBin_qxqy_MB Y,wave=(:eBin_qxqy_MB,:eBin_qxqy_MB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MR)=(65535,0,0)
//			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MR)={0,8}
//			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_MB)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
			
	endif

	if(binType==5)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLRTB vs qBin_qxqy_MLRTB
			ErrorBars/T=0 iBin_qxqy_MLRTB Y,wave=(:eBin_qxqy_MLRTB,:eBin_qxqy_MLRTB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLRTB)=(65535,0,0)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==6)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLR vs qBin_qxqy_MLR
			ErrorBars/T=0 iBin_qxqy_MLR Y,wave=(:eBin_qxqy_MLR,:eBin_qxqy_MLR)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLR)=(65535,0,0)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==7)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLR vs qBin_qxqy_MLR
			ErrorBars/T=0 iBin_qxqy_MLR Y,wave=(:eBin_qxqy_MLR,:eBin_qxqy_MLR)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLR)=(65535,0,0)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	SetDataFolder root:
End

//
// duplicated from Middle_IQ_Graph from VCALC
// but plotted in a standalone graph window and not the VCALC subwindow
//
// V_1D_Data
//
// 
// x- need to set binType
// x- currently  hard-wired == 1
// x- error bars on the data
//
Proc V_Front_IQ_Graph(fullPathToFolder,binType,winNameStr) 
	String fullPathToFolder
	Variable binType
	String winNameStr


//	binType = V_GetBinningPopMode()
	SetDataFolder $(fullPathToFolder)

// clear EVERYTHING
	ClearIQIfDisplayed_AllFldr("FLRTB",winNameStr)
	
	ClearIQIfDisplayed_AllFldr("FLR",winNameStr)
	ClearIQIfDisplayed_AllFldr("FTB",winNameStr)

	ClearIQIfDisplayed_AllFldr("FT",winNameStr)	
	ClearIQIfDisplayed_AllFldr("FL",winNameStr)	
	ClearIQIfDisplayed_AllFldr("FR",winNameStr)	
	ClearIQIfDisplayed_AllFldr("FB",winNameStr)
		
	if(binType==1)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=$winNameStr iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=$winNameStr iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=$winNameStr iBin_qxqy_FB vs qBin_qxqy_FB
			ErrorBars/T=0 iBin_qxqy_FL Y,wave=(:eBin_qxqy_FL,:eBin_qxqy_FL)
			ErrorBars/T=0 iBin_qxqy_FR Y,wave=(:eBin_qxqy_FR,:eBin_qxqy_FR)
			ErrorBars/T=0 iBin_qxqy_FT Y,wave=(:eBin_qxqy_FT,:eBin_qxqy_FT)
			ErrorBars/T=0 iBin_qxqy_FB Y,wave=(:eBin_qxqy_FB,:eBin_qxqy_FB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif		
	endif
	
	if(binType==2)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=$winNameStr iBin_qxqy_FTB vs qBin_qxqy_FTB
			ErrorBars/T=0 iBin_qxqy_FLR Y,wave=(:eBin_qxqy_FLR,:eBin_qxqy_FLR)
			ErrorBars/T=0 iBin_qxqy_FTB Y,wave=(:eBin_qxqy_FTB,:eBin_qxqy_FTB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
//			Label/W=$winNameStr left "Intensity (1/cm)"
//			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)	
	
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLRTB vs qBin_qxqy_FLRTB
			ErrorBars/T=0 iBin_qxqy_FLRTB Y,wave=(:eBin_qxqy_FLRTB,:eBin_qxqy_FLRTB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLRTB)=(39321,26208,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged
		
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=$winNameStr iBin_qxqy_FR vs qBin_qxqy_FR
//			AppendToGraph/W=$winNameStr iBin_qxqy_FT vs qBin_qxqy_FT
//			AppendToGraph/W=$winNameStr iBin_qxqy_FB vs qBin_qxqy_FB
			ErrorBars/T=0 iBin_qxqy_FL Y,wave=(:eBin_qxqy_FL,:eBin_qxqy_FL)
			ErrorBars/T=0 iBin_qxqy_FR Y,wave=(:eBin_qxqy_FR,:eBin_qxqy_FR)
//			ErrorBars/T=0 iBin_qxqy_FT Y,wave=(:eBin_qxqy_FT,:eBin_qxqy_FT)
//			ErrorBars/T=0 iBin_qxqy_FB Y,wave=(:eBin_qxqy_FB,:eBin_qxqy_FB)
			
			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FR)=(39321,26208,1)
//			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FR)={0,8}
//			ModifyGraph/W=$winNameStr,muloffset(iBin_qxqy_FB)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
			
	endif

	if(binType==5)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=$winNameStr iBin_qxqy_FTB vs qBin_qxqy_FTB
			ErrorBars/T=0 iBin_qxqy_FLR Y,wave=(:eBin_qxqy_FLR,:eBin_qxqy_FLR)
			ErrorBars/T=0 iBin_qxqy_FTB Y,wave=(:eBin_qxqy_FTB,:eBin_qxqy_FTB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
//			Label/W=$winNameStr left "Intensity (1/cm)"
//			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==6)	
	
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLRTB vs qBin_qxqy_FLRTB
			ErrorBars/T=0 iBin_qxqy_FLRTB Y,wave=(:eBin_qxqy_FLRTB,:eBin_qxqy_FLRTB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLRTB)=(39321,26208,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==7)

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=$winNameStr iBin_qxqy_FTB vs qBin_qxqy_FTB
			ErrorBars/T=0 iBin_qxqy_FLR Y,wave=(:eBin_qxqy_FLR,:eBin_qxqy_FLR)
			ErrorBars/T=0 iBin_qxqy_FTB Y,wave=(:eBin_qxqy_FTB,:eBin_qxqy_FTB)

			ModifyGraph/W=$winNameStr mode=4
			ModifyGraph/W=$winNameStr marker=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize=2
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
//			Label/W=$winNameStr left "Intensity (1/cm)"
//			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	
	SetDataFolder root:
End


// 
// x- need to set binType
// x- currently  hard-wired == 1
// x- error bars on the data
//
//	type = the data folder
// binType = numerical index of the bin type (1->4)
//  one;two;four;slit
// winNameStr = the name of the target window
//
////////////to plot the back panel I(q)
Proc V_Back_IQ_Graph(fullPathToFolder,binType,winNameStr)
	String fullPathToFolder
	Variable binType
	String winNameStr
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

//	Variable binType

//	binType = V_GetBinningPopMode()
	
	ClearIQIfDisplayed_AllFldr("B",winNameStr)


	SetDataFolder $(fullPathToFolder)	

//	if(binType==1 || binType==2 || binType==3)
	if(binType==1 || binType==2 || binType==3)
	
		SetDataFolder $(fullPathToFolder)	
		CheckDisplayed/W=$winNameStr iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_B vs qBin_qxqy_B
			ErrorBars/T=0 iBin_qxqy_B Y,wave=(:eBin_qxqy_B,:eBin_qxqy_B)
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_B)=4
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_B)=19,msize(iBin_qxqy_B)=2
//			ModifyGraph/W=$winNameStr msize(iBin_qxqy_B)=3,textMarker(iBin_qxqy_B)={"B","default",1,0,5,0.00,0.00}

		endif
		
	endif

	//nothing different here since there is ony a single detector to display, but for the future...
	if(binType==4)
	
		SetDataFolder $(fullPathToFolder)				// ClearIQIfDisplayed_AllFldr() resets to root:
		CheckDisplayed/W=$winNameStr iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_B)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_B)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_B)=2
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif
	endif

	if(binType==5 || binType==6 || binType==7)
	
		SetDataFolder $(fullPathToFolder)	
		CheckDisplayed/W=$winNameStr iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_B vs qBin_qxqy_B
			ErrorBars/T=0 iBin_qxqy_B Y,wave=(:eBin_qxqy_B,:eBin_qxqy_B)
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_B)=4
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_B)=19,msize(iBin_qxqy_B)=2
//			ModifyGraph/W=$winNameStr msize(iBin_qxqy_B)=3,textMarker(iBin_qxqy_B)={"B","default",1,0,5,0.00,0.00}

		endif
		
	endif

	
	SetDataFolder root:
End



//	type = the data folder
// binType = numerical index of the bin type (1->4)
//  one;two;four;slit
// winNameStr = the name of the target window
//
////////////to plot the back panel I(q)
Proc V_Back_IQ_Graph_trim(fullPathToFolder,binType,winNameStr)
	String fullPathToFolder
	Variable binType
	String winNameStr
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

//	Variable binType

//	binType = V_GetBinningPopMode()
	

	SetDataFolder $(fullPathToFolder)	

	if(binType==1 || binType==2 || binType==3)
	
//		ClearIQIfDisplayed_AllFldr("B_trim",winNameStr)
		CheckDisplayed/W=$winNameStr $("iBin_qxqy_B_trim")
		if(V_flag==1)
			RemoveFromGraph/W=$winNameStr $("iBin_qxqy_B_trim")
		endif
		SetDataFolder $(fullPathToFolder)	
		CheckDisplayed/W=$winNameStr iBin_qxqy_B_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_B_trim vs qBin_qxqy_B_trim
			ErrorBars/T=0 iBin_qxqy_B_trim Y,wave=(:eBin_qxqy_B_trim,:eBin_qxqy_B_trim)
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_B_trim)=4
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_B_trim)=(1,52428,52428)
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_B_trim)=19,msize(iBin_qxqy_B_trim)=3
//			ModifyGraph/W=$winNameStr msize(iBin_qxqy_B_trim)=3,textMarker(iBin_qxqy_B_trim)={"B","default",1,0,5,0.00,0.00}

		endif
		
//		ClearIQIfDisplayed_AllFldr("B_trim")
//		SetDataFolder $(fullPathToFolder)	
//		CheckDisplayed/W=V_1D_Data iBin_qxqy_B_trim
//		
//		if(V_flag==0)
//			AppendtoGraph/W=V_1D_Data iBin_qxqy_B_trim vs qBin_qxqy_B_trim
//			ModifyGraph/W=V_1D_Data mode=4
//			ModifyGraph/W=V_1D_Data marker=19
//			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_B_trim)=(1,52428,52428)
//			ModifyGraph/W=V_1D_Data msize=2
//			ModifyGraph/W=V_1D_Data grid=1
//			ModifyGraph/W=V_1D_Data log=1
//			ModifyGraph/W=V_1D_Data mirror=2
//		endif
		
	endif

	//nothing different here since there is ony a single detector to display, but for the future...
	if(binType==4)
	
//		ClearIQIfDisplayed_AllFldr("B_trim",winNameStr)
		CheckDisplayed/W=$winNameStr $("iBin_qxqy_B_trim")
		if(V_flag==1)
			RemoveFromGraph/W=$winNameStr $("iBin_qxqy_B_trim")
		endif
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)	
		CheckDisplayed/W=$winNameStr iBin_qxqy_B_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_B_trim vs qBin_qxqy_B_trim
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_B_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_B_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_B_trim)=(1,52428,52428)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_B_trim)=3
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif
	endif

	
	SetDataFolder root:
End


// 
// x- need to set binType
// x- currently  hard-wired == 1
//
// input "fullPathToFolder" is the data type and defines the folder, 
// i.e. "root:Packages:NIST:VSANS:"+"SAM"
//
Proc V_Middle_IQ_Graph_trim(fullPathToFolder,binType,winNameStr) 
	String fullPathToFolder
	Variable binType
	String winNameStr

//	binType = V_GetBinningPopMode()
	SetDataFolder $(fullPathToFolder)

	String midList = "ML;MR;MT;MB;MLR;MTB;MLRTB;"
	String type
	Variable ii
	

	if(binType==1)
		ii=0
		do
			type = StringFromList(ii, midlist, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(midList))
	
			
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_ML_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_ML_trim vs qBin_qxqy_ML_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MR_trim vs qBin_qxqy_MR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MT_trim vs qBin_qxqy_MT_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MB_trim vs qBin_qxqy_MB_trim
			ErrorBars/T=0 iBin_qxqy_ML_trim Y,wave=(:eBin_qxqy_ML_trim,:eBin_qxqy_ML_trim)
			ErrorBars/T=0 iBin_qxqy_MR_trim Y,wave=(:eBin_qxqy_MR_trim,:eBin_qxqy_MR_trim)
			ErrorBars/T=0 iBin_qxqy_MT_trim Y,wave=(:eBin_qxqy_MT_trim,:eBin_qxqy_MT_trim)
			ErrorBars/T=0 iBin_qxqy_MB_trim Y,wave=(:eBin_qxqy_MB_trim,:eBin_qxqy_MB_trim)
			
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_ML_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MT_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_ML_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MT_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_ML_trim)=(65535,0,0),rgb(iBin_qxqy_MB_trim)=(1,16019,65535),rgb(iBin_qxqy_MR_trim)=(65535,0,0),rgb(iBin_qxqy_MT_trim)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_ML_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MT_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_ML_trim)={0,4},muloffset(iBin_qxqy_MB_trim)={0,2},muloffset(iBin_qxqy_MR_trim)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
	endif
	
	if(binType==2)
// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, midlist, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(midList))
		

	

		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLR_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLR_trim vs qBin_qxqy_MLR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MTB_trim vs qBin_qxqy_MTB_trim
			ErrorBars/T=0 iBin_qxqy_MLR_trim Y,wave=(:eBin_qxqy_MLR_trim,:eBin_qxqy_MLR_trim)
			ErrorBars/T=0 iBin_qxqy_MTB_trim Y,wave=(:eBin_qxqy_MTB_trim,:eBin_qxqy_MTB_trim)
			
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MLR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MTB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MLR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MTB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLR_trim)=(65535,0,0),rgb(iBin_qxqy_MTB_trim)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MLR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MTB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_MLR_trim)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, midlist, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(midList))

	
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_MLRTB_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_MLRTB_trim vs qBin_qxqy_MLRTB_trim
			ErrorBars/T=0 iBin_qxqy_MLRTB_trim Y,wave=(:eBin_qxqy_MLRTB_trim,:eBin_qxqy_MLRTB_trim)
			
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MLRTB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MLRTB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_MLRTB_trim)=(65535,0,0)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MLRTB_trim)=3
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged
// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, midlist, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(midList))
		

		
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_ML_trim
		
		if(V_flag==0)
			AppendToGraph/W=$winNameStr iBin_qxqy_ML_trim vs qBin_qxqy_ML_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MR_trim vs qBin_qxqy_MR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MT_trim vs qBin_qxqy_MT_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_MB_trim vs qBin_qxqy_MB_trim
			ErrorBars/T=0 iBin_qxqy_ML_trim Y,wave=(:eBin_qxqy_ML_trim,:eBin_qxqy_ML_trim)
			ErrorBars/T=0 iBin_qxqy_MR_trim Y,wave=(:eBin_qxqy_MR_trim,:eBin_qxqy_MR_trim)
			ErrorBars/T=0 iBin_qxqy_MT_trim Y,wave=(:eBin_qxqy_MT_trim,:eBin_qxqy_MT_trim)
			ErrorBars/T=0 iBin_qxqy_MB_trim Y,wave=(:eBin_qxqy_MB_trim,:eBin_qxqy_MB_trim)
			
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_ML_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MT_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_MB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_ML_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MT_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_MB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_ML_trim)=(65535,0,0),rgb(iBin_qxqy_MB_trim)=(1,16019,65535),rgb(iBin_qxqy_MR_trim)=(65535,0,0),rgb(iBin_qxqy_MT_trim)=(1,16019,65535)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_ML_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MT_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_MB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_ML_trim)={0,4},muloffset(iBin_qxqy_MB_trim)={0,2},muloffset(iBin_qxqy_MR_trim)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
			
	endif
	
	SetDataFolder root:
End




// 
// x- need to set binType
// x- currently  hard-wired == 1
// x- error bars on the data
//
Proc V_Front_IQ_Graph_trim(fullPathToFolder,binType,winNameStr) 
	String fullPathToFolder
	Variable binType
	String winNameStr


	String frontList = "FL;FR;FT;FB;FLR;FTB;FLRTB;"
	String type
	Variable ii
//	binType = V_GetBinningPopMode()
	SetDataFolder $(fullPathToFolder)


		
	if(binType==1)
		ii=0
		do
			type = StringFromList(ii, frontList, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(frontList))
		

				
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FL_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FL_trim vs qBin_qxqy_FL_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FR_trim vs qBin_qxqy_FR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FT_trim vs qBin_qxqy_FT_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FB_trim vs qBin_qxqy_FB_trim
			ErrorBars/T=0 iBin_qxqy_FL_trim Y,wave=(:eBin_qxqy_FL_trim,:eBin_qxqy_FL_trim)
			ErrorBars/T=0 iBin_qxqy_FR_trim Y,wave=(:eBin_qxqy_FR_trim,:eBin_qxqy_FR_trim)
			ErrorBars/T=0 iBin_qxqy_FT_trim Y,wave=(:eBin_qxqy_FT_trim,:eBin_qxqy_FT_trim)
			ErrorBars/T=0 iBin_qxqy_FB_trim Y,wave=(:eBin_qxqy_FB_trim,:eBin_qxqy_FB_trim)

			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FL_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FT_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FL_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FT_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FL_trim)=(39321,26208,1),rgb(iBin_qxqy_FB_trim)=(2,39321,1),rgb(iBin_qxqy_FR_trim)=(39321,26208,1),rgb(iBin_qxqy_FT_trim)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FL_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FT_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FL_trim)={0,4},muloffset(iBin_qxqy_FB_trim)={0,2},muloffset(iBin_qxqy_FR_trim)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif		
	endif
	
	if(binType==2)
	// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, frontList, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(frontList))
	


		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLR_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLR_trim vs qBin_qxqy_FLR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FTB_trim vs qBin_qxqy_FTB_trim
			ErrorBars/T=0 iBin_qxqy_FLR_trim Y,wave=(:eBin_qxqy_FLR_trim,:eBin_qxqy_FLR_trim)
			ErrorBars/T=0 iBin_qxqy_FTB_trim Y,wave=(:eBin_qxqy_FTB_trim,:eBin_qxqy_FTB_trim)

			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FLR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FTB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FLR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FTB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLR_trim)=(39321,26208,1),rgb(iBin_qxqy_FTB_trim)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FLR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FTB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FLR_trim)={0,2}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
//			Label/W=$winNameStr left "Intensity (1/cm)"
//			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, frontList, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(frontList))
	

	
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FLRTB_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FLRTB_trim vs qBin_qxqy_FLRTB_trim
			ErrorBars/T=0 iBin_qxqy_FLRTB_trim Y,wave=(:eBin_qxqy_FLRTB_trim,:eBin_qxqy_FLRTB_trim)

			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FLRTB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FLRTB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FLRTB_trim)=(39321,26208,1)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FLRTB_trim)=3
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
			Label/W=$winNameStr left "Intensity (1/cm)"
			Label/W=$winNameStr bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged
// clear EVERYTHING
		ii=0
		do
			type = StringFromList(ii, frontList, ";")
			CheckDisplayed/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			if(V_flag==1)
				RemoveFromGraph/W=$winNameStr $("iBin_qxqy_"+type+"_trim")
			endif
			ii+=1
		while(ii<ItemsInList(frontList))
	

		
		SetDataFolder $(fullPathToFolder)
		CheckDisplayed/W=$winNameStr iBin_qxqy_FL_trim
		
		if(V_flag==0)
			AppendtoGraph/W=$winNameStr iBin_qxqy_FL_trim vs qBin_qxqy_FL_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FR_trim vs qBin_qxqy_FR_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FT_trim vs qBin_qxqy_FT_trim
			AppendToGraph/W=$winNameStr iBin_qxqy_FB_trim vs qBin_qxqy_FB_trim
			ErrorBars/T=0 iBin_qxqy_FL_trim Y,wave=(:eBin_qxqy_FL_trim,:eBin_qxqy_FL_trim)
			ErrorBars/T=0 iBin_qxqy_FR_trim Y,wave=(:eBin_qxqy_FR_trim,:eBin_qxqy_FR_trim)
			ErrorBars/T=0 iBin_qxqy_FT_trim Y,wave=(:eBin_qxqy_FT_trim,:eBin_qxqy_FT_trim)
			ErrorBars/T=0 iBin_qxqy_FB_trim Y,wave=(:eBin_qxqy_FB_trim,:eBin_qxqy_FB_trim)
			
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FL_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FR_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FT_trim)=4
			ModifyGraph/W=$winNameStr mode(iBin_qxqy_FB_trim)=4
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FL_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FR_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FT_trim)=19
			ModifyGraph/W=$winNameStr marker(iBin_qxqy_FB_trim)=19
			ModifyGraph/W=$winNameStr rgb(iBin_qxqy_FL_trim)=(39321,26208,1),rgb(iBin_qxqy_FB_trim)=(2,39321,1),rgb(iBin_qxqy_FR_trim)=(39321,26208,1),rgb(iBin_qxqy_FT_trim)=(2,39321,1)
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FL_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FR_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FT_trim)=3
			ModifyGraph/W=$winNameStr msize(iBin_qxqy_FB_trim)=3
			ModifyGraph/W=$winNameStr muloffset(iBin_qxqy_FL_trim)={0,4},muloffset(iBin_qxqy_FB_trim)={0,2},muloffset(iBin_qxqy_FR_trim)={0,8}
			ModifyGraph/W=$winNameStr grid=1
			ModifyGraph/W=$winNameStr log=1
			ModifyGraph/W=$winNameStr mirror=2
		endif		
			
	endif
	
	SetDataFolder root:
End

