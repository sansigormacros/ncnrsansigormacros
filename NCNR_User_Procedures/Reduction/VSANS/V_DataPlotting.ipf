#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0


//
// functions to plot the averaged data in various views.
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
// -- decide what to add to the control bar
//
// -- see Middle_IQ_Graph() and similar for how VCALC does this plot
//
// -- when/if I want to add phi-averaging to this, go gack to AvgGraphics.ipf for the pink panel
//    and to the function Draw_Plot1D() for the drawing of the plot
//
Function V_PlotData_Panel()


	DoWindow V_1D_Data
	if(V_flag==0)
	
		Display /W=(277,526,748,938)/N=V_1D_Data/K=1
//		Display /W=(476,96,850,429)/N=V_1D_Data/K=1
		ControlBar 70
		
		PopupMenu popup0,pos={16,5},size={71,20},title="Bin Type"
		PopupMenu popup0,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
		PopupMenu popup0,value= "One;Two;Four;Slit Mode;"
		PopupMenu popup0,mode=1,proc=V_BinningModePopup
//		PopupMenu ymodel,pos={16,5},size={71,20},title="y-axis"
//		PopupMenu ymodel,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
//		PopupMenu ymodel,value= #"\"I;log(I);ln(I);1/I;I^a;Iq^a;I^a q^b;1/sqrt(I);ln(Iq);ln(Iq^2)\""
//		PopupMenu ymodel,mode=NumVarOrDefault("root:myGlobals:Plot_1d:gYMode", 1 ),proc=YMode_PopMenuProc
//		PopupMenu xmodel,pos={150,5},size={74,20},title="x-axis"
//		PopupMenu xmodel,help={"This popup selects how the x-axis will be linearized given the chosen data"}
//		PopupMenu xmodel,value= #"\"q;log(q);q^2;q^c\""
//		PopupMenu xmodel,mode=NumVarOrDefault("root:myGlobals:Plot_1d:gXMode", 1 ),proc=XMode_PopMenuProc
//		Button Rescale,pos={281,4},size={70,20},proc=Rescale_Plot_1D_ButtonProc,title="Rescale"
//		Button Rescale,help={"Rescale the x and y-axes of the data"},disable=1

//		SetVariable expa,pos={28,28},size={80,15},title="pow \"a\""
//		SetVariable expa,help={"This sets the exponent \"a\" for some y-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//		SetVariable expa,limits={-2,10,0},value= root:myGlobals:Plot_1d:gExpA
//		SetVariable expb,pos={27,46},size={80,15},title="pow \"b\""
//		SetVariable expb,help={"This sets the exponent \"b\" for some x-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//		SetVariable expb,limits={0,10,0},value= root:myGlobals:Plot_1d:gExpB
//
//		SetVariable expc,pos={167,28},size={80,15},title="pow \"c\""
//		SetVariable expc,help={"This sets the exponent \"c\" for some x-axis formats. The value is ignored if the model does not use \"c\" as an adjustable exponent"}
//		SetVariable expc,limits={-10,10,0},value= root:myGlobals:Plot_1d:gExpC
		
		Button AllQ,pos={281,28},size={70,20},proc=V_AllQ_Plot_1D_ButtonProc,title="All Q"
		Button AllQ,help={"Show the full q-range of the dataset"}
		
	endif
		
	
	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	V_QBinAllPanels(type)

// TODO:
// x- "B" detector is currently skipped - Q is not yet calculated
	Execute ("V_Back_IQ_Graph(\""+type+"\")")
	Execute ("V_Middle_IQ_Graph(\""+type+"\")")
	Execute ("V_Front_IQ_Graph(\""+type+"\")")
	
	
End

//function to restore the graph axes to full scale, undoing any zooming
Function V_AllQ_Plot_1D_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
//	DoWindow/F V_1D_Data
	SetAxis/A
End


//
// recalculate the I(q) binning. no need to adjust model function or views
// just rebin
//
Function V_BinningModePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

	V_QBinAllPanels(type)

	Execute ("V_Back_IQ_Graph(\""+type+"\")")
	Execute ("V_Middle_IQ_Graph(\""+type+"\")")
	Execute ("V_Front_IQ_Graph(\""+type+"\")")
	
	return(0)	
End

Function V_GetBinningPopMode()

	Variable binType
	ControlInfo/W=V_1D_Data popup0
	strswitch(S_Value)	// string switch
		case "One":
			binType = 1
			break		// exit from switch
		case "Two":
			binType = 2
			break		// exit from switch
		case "Four":
			binType = 3
			break		// exit from switch
		case "Slit Mode":
			binType = 4
			break		// exit from switch

		default:			// optional default expression executed
			binType = 0
			Abort "Binning mode not found in 	V_QBinAllPanels() "// when no case matches
	endswitch
	
	return(binType)
end

//
// duplicated from Middle_IQ_Graph from VCALC
// but plotted in a standalone graph window and not the VCALC subwindow
//
// V_1D_Data
//
// TODO
// x- need to set binType
// x- currently  hard-wired == 1
//
// input "type" is the data type and defines the folder
//
Proc V_Middle_IQ_Graph(type) 
	String type

	Variable binType

	binType = V_GetBinningPopMode()
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)

// clear EVERYTHING
//		ClearAllIQIfDisplayed("MLRTB")
//		ClearAllIQIfDisplayed("MLR")
//		ClearAllIQIfDisplayed("MTB")		//this returns to root:
//		ClearAllIQIfDisplayed("MT")	
//		ClearAllIQIfDisplayed("ML")	
//		ClearAllIQIfDisplayed("MR")	
//		ClearAllIQIfDisplayed("MB")	

	if(binType==1)
		ClearAllIQIfDisplayed("MLRTB")
		ClearAllIQIfDisplayed("MLR")
		ClearAllIQIfDisplayed("MTB")		//this returns to root:
		ClearAllIQIfDisplayed("MT")	
		ClearAllIQIfDisplayed("ML")	
		ClearAllIQIfDisplayed("MR")	
		ClearAllIQIfDisplayed("MB")			
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=V_1D_Data iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=V_1D_Data iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
	endif
	
	if(binType==2)
		ClearAllIQIfDisplayed("MLRTB")
		ClearAllIQIfDisplayed("MT")	
		ClearAllIQIfDisplayed("ML")	
		ClearAllIQIfDisplayed("MR")	
		ClearAllIQIfDisplayed("MB")
	

		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_MLR vs qBin_qxqy_MLR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MTB vs qBin_qxqy_MTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_MLR)=(65535,0,0),rgb(iBin_qxqy_MTB)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_MLR)={0,2}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearAllIQIfDisplayed("MLR")
		ClearAllIQIfDisplayed("MTB")	
		ClearAllIQIfDisplayed("MT")	
		ClearAllIQIfDisplayed("ML")	
		ClearAllIQIfDisplayed("MR")	
		ClearAllIQIfDisplayed("MB")	
	
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_MLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_MLRTB vs qBin_qxqy_MLRTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_MLRTB)=(65535,0,0)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged
		ClearAllIQIfDisplayed("MLRTB")
		ClearAllIQIfDisplayed("MLR")
		ClearAllIQIfDisplayed("MTB")
		
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_ML
		
		if(V_flag==0)
			AppendToGraph/W=V_1D_Data iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=V_1D_Data iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=V_1D_Data iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
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
// TODO
// x- need to set binType
// x- currently  hard-wired == 1
//
//
Proc V_Front_IQ_Graph(type) 
	String type

	Variable binType


	binType = V_GetBinningPopMode()
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)

// clear EVERYTHING
//		ClearAllIQIfDisplayed("FLRTB")
//		
//		ClearAllIQIfDisplayed("FLR")
//		ClearAllIQIfDisplayed("FTB")
//
//		ClearAllIQIfDisplayed("FT")	
//		ClearAllIQIfDisplayed("FL")	
//		ClearAllIQIfDisplayed("FR")	
//		ClearAllIQIfDisplayed("FB")
		
	if(binType==1)
		ClearAllIQIfDisplayed("FLRTB")
		
		ClearAllIQIfDisplayed("FLR")
		ClearAllIQIfDisplayed("FTB")

		ClearAllIQIfDisplayed("FT")	
		ClearAllIQIfDisplayed("FL")	
		ClearAllIQIfDisplayed("FR")	
		ClearAllIQIfDisplayed("FB")
				
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=V_1D_Data iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=V_1D_Data iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
	endif
	
	if(binType==2)
		ClearAllIQIfDisplayed("FLRTB")
		ClearAllIQIfDisplayed("FT")	
		ClearAllIQIfDisplayed("FL")	
		ClearAllIQIfDisplayed("FR")	
		ClearAllIQIfDisplayed("FB")	

		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FTB vs qBin_qxqy_FTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearAllIQIfDisplayed("FLR")
		ClearAllIQIfDisplayed("FTB")	
		ClearAllIQIfDisplayed("FT")	
		ClearAllIQIfDisplayed("FL")	
		ClearAllIQIfDisplayed("FR")	
		ClearAllIQIfDisplayed("FB")	
	
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FLRTB vs qBin_qxqy_FLRTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FLRTB)=(39321,26208,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - MT, ML, MR, MB are averaged
		ClearAllIQIfDisplayed("FLRTB")
		ClearAllIQIfDisplayed("FLR")
		ClearAllIQIfDisplayed("FTB")
		
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=V_1D_Data iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=V_1D_Data iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
			
	endif
	
	SetDataFolder root:
End


// TODO
// x- need to set binType
// x- currently  hard-wired == 1
//
////////////to plot the back panel I(q)
Proc V_Back_IQ_Graph(type)
	String type
	
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

	Variable binType

	binType = V_GetBinningPopMode()
	
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)	

	if(binType==1 || binType==2 || binType==3)
	
		ClearAllIQIfDisplayed("B")
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)	
		CheckDisplayed/W=V_1D_Data iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif
	endif

	//nothing different here since there is ony a single detector to display, but for the future...
	if(binType==4)
	
		ClearAllIQIfDisplayed("B")
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)	
		CheckDisplayed/W=V_1D_Data iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif
	endif

	
	SetDataFolder root:
End

