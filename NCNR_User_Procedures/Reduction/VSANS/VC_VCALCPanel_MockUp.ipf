#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 7.00

//
//
// mockup of the panel for VCALC
//
// -- all is housed in the folder:
// 	NewDataFolder/O root:Packages:NIST:VSANS:VCALC
//
// -- Put all of the constants to define the instrument plus all of the VCALC stuff
//
// anticipating that at the same level as VCALC will be all of the reduction folders
// in a similar way as for SANS reduction
//
//
// TODO:
// -- adjust the size of the panel to better fit a laptop (for my telework)
//


Proc VCALC_Panel()
	DoWindow/F VCALC
	if(V_flag==0)
	
		//initialize space = folders, parameters, instrument constants, etc.
		VC_Initialize_Space()
		
		//open the panel
		DrawVCALC_Panel()

		// check for a mask, if not present, generate a default mask (this will be updated later)
		if(!Exists("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_FT:data"))
			V_GenerateDefaultMask()
		endif
		
		// two graphs with the ray-tracing side/top views
//		SetupSideView()
//		SetupTopView()
		
		// a front view of the panels
//		FrontView_1x()
		
		// pop one of the presets to get everything to update
		VC_Preset_WhiteBeam()
		
		// a recalculation is needed after the change
		// this re-bins the I(q) data too
		VC_Recalculate_AllDetectors()

		// update the views
		VC_UpdateViews()
				
	endif
End

Function FakeFrontMiddleSDDClick()
	
	STRUCT WMSetVariableAction sva
	sva.eventCode = 3
//	sva.dval = 0.3

	VC_BDet_SDD_SetVarProc(sva)		
	VC_MDet_SDD_SetVarProc(sva)
	VC_FDet_SDD_SetVarProc(sva)

	return(0)
end


Proc DrawVCALC_Panel()
	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif
	
	PauseUpdate; Silent 1		// building window...

// original panel size		
//	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)	
//		NewPanel /W=(34*sc,44*sc,1274*sc,660*sc)/N=VCALC/K=1
//	else
//		NewPanel /W=(34,44,1274,699)/N=VCALC/K=1
//	endif


// new panel size with some removed subwindow graphs
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)	
		NewPanel /W=(34*sc,44*sc,1050*sc,680*sc)/N=VCALC/K=1
	else
		NewPanel /W=(34,44,900,699)/N=VCALC/K=1
	endif
	
	
	ModifyPanel cbRGB=(49151,60031,65535)
//	ShowTools/A
	SetDrawLayer UserBack
	
// always visible stuff, not on any tab
	
	GroupBox group0,pos={sc*10,10*sc},size={sc*440,125*sc},title="Setup"
	TabControl Vtab,labelBack=(45000,61000,58000),pos={sc*14,150*sc},size={sc*430,200*sc},tabLabel(0)="Collim"
	TabControl Vtab,tabLabel(1)="Sample",tabLabel(2)="Front Det",tabLabel(3)="Mid Det"
	TabControl Vtab,tabLabel(4)="Back Det",tabLabel(5)="Simul",value= 0,proc=VCALCTabProc

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)	
		GroupBox group1,pos={sc*460,10*sc},size={sc*550,610*sc},title="Detector Panel Positions + Data"
	else	
		GroupBox group1,pos={460,10},size={762,635},title="Detector Panel Positions + Data"
	endif
	Button button_a,pos={sc*210,70*sc},size={sc*100,20*sc},title="Show Mask",proc=V_VCALCShowMaskButtonProc
	Button button_b,pos={sc*210,100*sc},size={sc*100,20*sc},title="Recalculate",proc=V_VCALCRecalcButtonProc
	Button button_c,pos={sc*330,70*sc},size={sc*100,20*sc},title="Save Config",proc=V_VCALCSaveConfiguration
	Button button_d,pos={sc*330,100*sc},size={sc*100,20*sc},title="Save NICE",proc=V_VCALCSaveNICEConfiguration


	PopupMenu popup_a,pos={sc*50,40*sc},size={sc*142,20*sc},title="Presets"
	PopupMenu popup_a,mode=1,popvalue="White Beam",value= root:Packages:NIST:VSANS:VCALC:gPresetPopStr
	PopupMenu popup_a,proc=VC_PresetConfigPopup

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)	

		SetVariable setVar_b,pos={sc*780,30*sc},size={sc*120,15*sc},title="axis Q",proc=Front2DQ_Range_SetVarProc
		SetVariable setVar_b,limits={0.01,1,0.02},value=_NUM:0.52
		CheckBox check_0a title="Log?",size={sc*60,20*sc},pos={sc*780,60*sc},proc=Front2DQ_Log_CheckProc

		PopupMenu popup_b,pos={sc*820,320*sc},size={sc*142,20*sc},title="Binning type",proc=VC_RebinIQ_PopProc
		PopupMenu popup_b,mode=1,value= root:Packages:NIST:VSANS:VCALC:gBinTypeStr
		Button AllQ,pos={sc*820,350*sc},size={sc*70,20*sc},proc=VC_AllQ_Plot_1D_ButtonProc,title="All Q"
		Button AllQ,help={"Show the full q-range of the dataset"}

		Button Offset,pos={sc*820,380*sc},size={sc*70,20*sc},proc=VC_RemoveOffset_ButtonProc,title="No Offset"
		Button Offset,help={"Remove the offset"}

	else	
		PopupMenu popup_b,pos={670,311},size={142,20},title="Binning type",proc=VC_RebinIQ_PopProc
		PopupMenu popup_b,mode=1,value= root:Packages:NIST:VSANS:VCALC:gBinTypeStr
		SetVariable setVar_b,pos={476,313},size={120,15},title="axis Q",proc=Front2DQ_Range_SetVarProc
		SetVariable setVar_b,limits={0.02,1,0.02},value=_NUM:0.52
		CheckBox check_0a title="Log?",size={60,20},pos={619,313},proc=Front2DQ_Log_CheckProc

		PopupMenu popup_b,pos={670,311},size={142,20},title="Binning type",proc=VC_RebinIQ_PopProc
		PopupMenu popup_b,mode=1,value= root:Packages:NIST:VSANS:VCALC:gBinTypeStr		
		Button AllQ,pos={820,320},size={70,20},proc=VC_AllQ_Plot_1D_ButtonProc,title="All Q"
		Button AllQ,help={"Show the full q-range of the dataset"}

		Button Offset,pos={820,380},size={70,20},proc=VC_RemoveOffset_ButtonProc,title="No Offset"
		Button Offset,help={"Remove the offset"}
	endif


		
//	SetVariable setVar_a,pos={sc*476,26*sc},size={sc*120,15*sc},title="axis degrees",proc=FrontView_Range_SetVarProc
//	SetVariable setVar_a,limits={0.3,30,0.2},value=_NUM:28

	ValDisplay valDisp_a,pos={sc*30,380*sc},size={sc*200,15*sc},fstyle=1,title="Beam Intensity",value=root:Packages:NIST:VSANS:VCALC:gBeamIntensity

	SetDrawEnv fstyle= 1
	DrawText 20*sc,420*sc,"Back"
	DrawText 80*sc,420*sc,"Q min"
	DrawText 150*sc,420*sc,"Q max"
	ValDisplay valDisp_b,pos={sc*30,420*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmin_B
	ValDisplay valDisp_c,pos={sc*130,420*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmax_B

	SetDrawEnv fstyle= 1
	DrawText 120*sc,460*sc,"Middle"
	DrawText 180*sc,460*sc,"Q min"
	DrawText 250*sc,460*sc,"Q max"	
	ValDisplay valDisp_d,pos={sc*130,460*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmin_M
	ValDisplay valDisp_e,pos={sc*230,460*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmax_M

	SetDrawEnv fstyle= 1
	DrawText 220*sc,500*sc,"Front"	
	DrawText 280*sc,500*sc,"Q min"
	DrawText 350*sc,500*sc,"Q max"	
	ValDisplay valDisp_f,pos={sc*230,500*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmin_F
	ValDisplay valDisp_g,pos={sc*330,500*sc},size={sc*100,15*sc},title="",value=root:Packages:NIST:VSANS:VCALC:gQmax_F


	ValDisplay valDisp_h,pos={sc*50,530*sc},size={sc*220,15*sc},title="Beam Diam (middle) (cm)",value=root:Packages:NIST:VSANS:VCALC:gBeamDiam
	ValDisplay valDisp_i,pos={sc*50,560*sc},size={sc*220,15*sc},title="Beam Stop Diam (middle) (in)",value=root:Packages:NIST:VSANS:VCALC:gBeamStopDiam
	ValDisplay valDisp_j,pos={sc*50,590*sc},size={sc*220,15*sc},title="Beam Stop Q min (1/A)",value=root:Packages:NIST:VSANS:VCALC:gRealQMin



//	// for panels (in degrees)	
//	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
//		Display/W=(476*sc,45*sc,757*sc,270*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	else
//		Display/W=(476,45,757,303)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	endif
//	RenameWindow #,FrontView
//	ModifyGraph mode=2		// mode = 2 = dots
//	ModifyGraph marker=19
//	ModifyGraph rgb=(0,0,0)
//	ModifyGraph tick=2,mirror=1
//	Label left "degrees"
//	Label bottom "degrees"	
//	SetActiveSubwindow ##


//	// for side view
//	Display/W=(842*sc,25*sc,1200*sc,170*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	RenameWindow #,SideView
//	ModifyGraph mode=2		// mode = 2 = dots
//	ModifyGraph marker=19
//	ModifyGraph rgb=(0,0,0)
//	ModifyGraph tick=2,mirror=1
//	Label left "Vertical position (cm)"
//	Label bottom "SDD (cm)"
//	SetAxis/A/R left	
//	SetActiveSubwindow ##	
//	
//	// for top view
//	Display/W=(842*sc,180*sc,1200*sc,325*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	RenameWindow #,TopView
//	ModifyGraph mode=2		// mode = 2 = dots
//	ModifyGraph marker=19
//	ModifyGraph rgb=(0,0,0)
//	ModifyGraph tick=2,mirror=1
//	Label left "Horizontal position (cm)"
//	Label bottom "SDD (cm)"	
//	SetActiveSubwindow ##	


	// for panels (as 2D Q)
//// original location
//	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
//	// note that the dimensions here are not strictly followed since the aspect ratio is set below
//		Display/W=(475*sc,310*sc,790*sc,590*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	else
//		Display/W=(475,332,814,631)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	endif	

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		Display/W=(476*sc,35*sc,755*sc,290*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	else
		Display/W=(476,35,755,303)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	endif

	RenameWindow #,Panels_Q
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph tick=2,mirror=1,grid=2,standoff=0
//	ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
	ModifyGraph lowTrip=0.001		//to prevent axis labels from switching to scientific notation
	SetAxis left -0.2,0.2
	SetAxis bottom -0.2,0.2
	Label left "Qy"
	Label bottom "Qx"	
	SetActiveSubwindow ##



	// for averaged I(Q)
////original location
//	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
//		Display/W=(842*sc,330*sc,1204*sc,590*sc)/HOST=# //root:Packages:NIST:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	else
//		Display/W=(842,334,1204,629)/HOST=# //root:Packages:NIST:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
//	endif	

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
	// note that the dimensions here are not strictly followed since the aspect ratio is set below
		Display/W=(475*sc,310*sc,800*sc,620*sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	else
		Display/W=(475,332,814,631)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	endif	

	RenameWindow #,Panels_IQ
//	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph tick=2,mirror=1,grid=2
//	Label left "Intensity"
//	Label bottom "Q"	
//	Legend/A=LB
	Legend/C/N=text0/J/A=LB "\\Z08"
	SetActiveSubwindow ##


	
// all controls are named VCALCCtrl_NA where N is the tab number and A is the letter indexing items on tab

	
// tab(0), collimation - initially visible
	Slider VCALCCtrl_0a,pos={sc*223,(334-50)*sc},size={sc*200,45*sc},limits={0,9,1},value= 1,vert= 0,proc=V_GuideSliderProc
	SetVariable VCALCCtrl_0b,pos={sc*25,(294-50)*sc},size={sc*120,15*sc},title="wavelength"
	SetVariable VCALCCtrl_0b,limits={4,20,1},value=_NUM:8,proc=VC_Lambda_SetVarProc
	PopupMenu VCALCCtrl_0c,pos={sc*26,(257-50)*sc},size={sc*150,20*sc},title="monochromator"
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector",value= root:Packages:NIST:VSANS:VCALC:gMonochromatorType
	PopupMenu VCALCCtrl_0c,proc=VC_MonochromSelectPopup
	PopupMenu VCALCCtrl_0d,pos={sc*26,(321-50)*sc},size={sc*115,20*sc},title="delta lambda"
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0d,proc=VC_DeltaLamSelectPopup
	PopupMenu VCALCCtrl_0e,pos={sc*263,(242-50)*sc},size={sc*132,20*sc},title="source shape"
	PopupMenu VCALCCtrl_0e,mode=1,popvalue="circular",value= root:Packages:NIST:VSANS:VCALC:gSourceShape
	PopupMenu VCALCCtrl_0e,proc=VC_SourceApShapeSelectPopup
	PopupMenu VCALCCtrl_0f,pos={sc*263,(272-50)*sc},size={sc*141,20*sc},title="source diam"
	PopupMenu VCALCCtrl_0f,mode=1,popvalue="6.0 cm",value= root:Packages:NIST:VSANS:VCALC:gSourceDiam
	PopupMenu VCALCCtrl_0f,proc=VC_SourceAperDiamSelectPopup
	PopupMenu VCALCCtrl_0g,pos={sc*263,(302-50)*sc},size={sc*141,20*sc},title="source height"
	PopupMenu VCALCCtrl_0g,mode=1,popvalue="10 cm",value= root:Packages:NIST:VSANS:VCALC:gSourceApertureWidth
	PopupMenu VCALCCtrl_0g,proc=VC_SourceAperDiamSelectPopup,disable=2

// tab(1) - Sample conditions, initially not visible
	PopupMenu VCALCCtrl_1a,pos={sc*38,(250-50)*sc},size={sc*142,20*sc},title="table location",disable=1
	PopupMenu VCALCCtrl_1a,mode=1,popvalue="Changer",value= root:Packages:NIST:VSANS:VCALC:gTableLocation
	PopupMenu VCALCCtrl_1b,pos={sc*270,(250-50)*sc},size={sc*115,20*sc},title="Aperture Shape",disable=1
	PopupMenu VCALCCtrl_1b,mode=1,popvalue="circular",value= root:Packages:NIST:VSANS:VCALC:gSampleApertureShape 
	PopupMenu VCALCCtrl_1b,proc=VC_SampleApShapeSelectPopup
	PopupMenu VCALCCtrl_1c,pos={sc*270,(280-50)*sc},size={sc*132,20*sc},title="Aperture Diam (cm)",disable=1
	PopupMenu VCALCCtrl_1c,mode=1,popvalue="1.27",value= root:Packages:NIST:VSANS:VCALC:gSampleApertureDiam
	PopupMenu VCALCCtrl_1c,proc=VC_SampleAperDiamSelectPopup
	SetVariable VCALCCtrl_1d,pos={sc*25,(280-50)*sc},size={sc*210,15*sc},title="Sam Ap to Gate Valve (cm)"//,bodywidth=50
	SetVariable VCALCCtrl_1d,limits={4,40,0.1},value=_NUM:22,proc=VC_A2_to_GV_SetVarProc,disable=1
	SetVariable VCALCCtrl_1e,pos={sc*25,(310-50)*sc},size={sc*210,15*sc},title="Sam Pos to Gate Valve (cm)"
	SetVariable VCALCCtrl_1e,limits={4,40,0.1},value=_NUM:11,proc=VC_Sam_to_GV_SetVarProc,disable=1	
	PopupMenu VCALCCtrl_1f,pos={sc*270,(310-50)*sc},size={sc*132,20*sc},title="Aperture width (cm)",disable=1
	PopupMenu VCALCCtrl_1f,mode=1,popvalue="0.1 cm",value= root:Packages:NIST:VSANS:VCALC:gSampleAperturewidth
	PopupMenu VCALCCtrl_1f,proc=VC_SampleAperDiamSelectPopup

// tab(2) - Front detector panels, initially not visible
	SetVariable VCALCCtrl_2a,pos={sc*30,(260-50)*sc},size={sc*170,15*sc},title="LEFT Offset (cm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2a,limits={-20,19,0.1},disable=1,value=_NUM:-10
	SetVariable VCALCCtrl_2aa,pos={sc*30,(290-50)*sc},size={sc*170,15*sc},title="RIGHT Offset (cm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2aa,limits={-19,20,0.1},disable=1,value=_NUM:10
	
	SetVariable VCALCCtrl_2b,pos={sc*30,(330-50)*sc},size={sc*170,15*sc},title="TOP Offset (cm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2b,limits={0,18,0.1},disable=1,value=_NUM:10
	SetVariable VCALCCtrl_2bb,pos={sc*30,(360-50)*sc},size={sc*170,15*sc},title="BOTTOM Offset (cm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2bb,limits={-18,0,0.1},disable=1,value=_NUM:-10
	
	SetVariable VCALCCtrl_2d,pos={sc*215,(260-50)*sc},size={sc*215,15*sc},title="Gate Valve to Det (cm)",proc=VC_FDet_SDD_SetVarProc
	SetVariable VCALCCtrl_2d,limits={70,800,1},disable=1	,value=_NUM:150
	

// tab(3) - Middle detector panels, initially not visible
	SetVariable VCALCCtrl_3a,pos={sc*30,(260-50)*sc},size={sc*170,15*sc},title="LEFT Offset (cm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3a,limits={-20,19,0.1},disable=1,value=_NUM:-7
	SetVariable VCALCCtrl_3aa,pos={sc*30,(290-50)*sc},size={sc*170,15*sc},title="RIGHT Offset (cm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3aa,limits={-19,20,0.1},disable=1,value=_NUM:7
		
	SetVariable VCALCCtrl_3b,pos={sc*30,(330-50)*sc},size={sc*170,15*sc},title="TOP Offset (cm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3b,limits={0,18,0.1},disable=1,value=_NUM:14
	SetVariable VCALCCtrl_3bb,pos={sc*30,(360-50)*sc},size={sc*170,15*sc},title="BOTTOM Offset (cm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3bb,limits={-18,0,0.1},disable=1,value=_NUM:-14

	SetVariable VCALCCtrl_3d,pos={sc*215,(260-50)*sc},size={sc*205,15*sc},title="Gate Valve to Det (cm)",proc=VC_MDet_SDD_SetVarProc
	SetVariable VCALCCtrl_3d,limits={250,2000,1},disable=1,value=_NUM:1000

	
// tab(4) - Back detector panel
	SetVariable VCALCCtrl_4a,pos={sc*168,(290-50)*sc},size={sc*160,15*sc},title="Lateral Offset (cm)"
	SetVariable VCALCCtrl_4a,limits={0,20,0.1},disable=1,value=_NUM:0
	SetVariable VCALCCtrl_4b,pos={sc*168,(260-50)*sc},size={sc*240,15*sc},title="Gate Valve to Det (cm)",proc=VC_BDet_SDD_SetVarProc
	SetVariable VCALCCtrl_4b,limits={2000,2500,1},disable=1,value=_NUM:2200
//	PopupMenu VCALCCtrl_4c,pos={sc*40,260*sc},size={sc*180,20*sc},title="Detector type",disable=1
//	PopupMenu VCALCCtrl_4c,mode=1,popvalue="2D",value= root:Packages:NIST:VSANS:VCALC:gBackDetType

// tab(5) - Simulation setup
 	SetVariable VCALCCtrl_5a,pos={sc*40,(290-50)*sc},size={sc*260,15*sc},title="Neutrons on Sample (imon)"
	SetVariable VCALCCtrl_5a,limits={1e7,1e15,1e7},disable=1,value=_NUM:1e11,proc=VC_SimImon_SetVarProc
 	SetVariable VCALCCtrl_5c,pos={sc*40,(320-50)*sc},size={sc*220,15*sc},title="Counting Time (s)"
	SetVariable VCALCCtrl_5c,limits={1,1e6,10},disable=1,value=_NUM:600,proc=VC_SimCtTime_SetVarProc
	PopupMenu VCALCCtrl_5b,pos={sc*40,(260-50)*sc},size={sc*200,20*sc},title="Model Function",disable=1
	PopupMenu VCALCCtrl_5b,mode=1,popvalue="Debye",value= root:Packages:NIST:VSANS:VCALC:gModelFunctionType,proc=VC_SimModelFunc_PopProc
	
End

Function V_VCALCShowMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_SetupPanelDisplay()
			
			PopupMenu popup1 win=VSANS_Det_Panels,mode=14,popvalue="VCALC"
			PopupMenu popup0 win=VSANS_Det_Panels,popvalue="F"
			ControlUpdate/A/W=VSANS_Det_Panels

		//pop the carriage menu to refresh the VCALC data
			STRUCT WMPopupAction pa
			pa.eventCode = 2		//fake click
			V_PickCarriagePopMenuProc(pa)
			
// risky, but I can pass the button "click" to the next button to toggle the mask "On"			
			V_ToggleFourMaskButtonProc(ba)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//function to remove the trace offset
// VCALC#Panels_IQ
Function VC_RemoveOffset_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	ModifyGraph/W=VCALC#Panels_IQ muloffset={0,0}
	
	return(0)
End


//function to restore the graph axes to full scale, undoing any zooming
Function VC_AllQ_Plot_1D_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SetAxis/A/W=VCALC#Panels_IQ

	return(0)
End

Function V_VCALCSaveConfiguration(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_DisplayConfigurationText()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_DisplayConfigurationText()

	if(WinType("Trial_Configuration")==0)
		NewNotebook/F=0/K=1/N=Trial_Configuration /W=(480,44,880,369)
	endif
	//replace the text
	Notebook Trial_Configuration selection={startOfFile, endOfFile}
	Notebook Trial_Configuration font="Monaco",fSize=10,text=V_SetConfigurationText()
	return(0)
end


//Export NICE VSANS configurations to a plain text noteboox that can be saved as a text file.
Function V_SaveNICEConfigs()

	String str=""

	if(WinType("NICE_Configuration")==0)
		NewNotebook/F=0/K=1/N=NICE_Configuration /W=(480,44,880,369)
	endif
	//replace the text
	Notebook NICE_Configuration selection={startOfFile, endOfFile}
	Notebook NICE_Configuration font="Monaco",fSize=10,text=V_SetNICEConfigText()
	
//	SaveNotebook/S=6/I NICE_Configuration as "NICE_Configs.txt"
//	KillWindow NICE_Configuration	
			
	return (0)

end

Function V_VCALCSaveNICEConfiguration(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
//			Recalculate_AllDetectors()
			V_SaveNICEConfigs()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_VCALCRecalcButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			VC_Recalculate_AllDetectors()
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//  recalculates the detector panels, doesn't adjust the views
//
Function VC_Recalculate_AllDetectors()

// calculates Q for each panel
// and fills 2D panels with model data
// then plots the 2D panel
	fPlotBackPanels()
	fPlotMiddlePanels()
	fPlotFrontPanels()

// generate a proper mask based on hard+soft shadowing
	VC_ResetVCALCMask()
	VC_DrawVCALCMask()


// update values on the panel
	V_beamIntensity()
	
//	Print "Beam diam (middle) = ",VC_beamDiameter("horizontal",2)		//middle carriage
	
	// fill in the Qmin and Qmax values, based on Q_Tot for the 2D panels (not including mask)
	V_QMinMax_Back()
	V_QMinMax_Middle()
	V_QMinMax_Front()
	
	//calculate beam diameter and beamstop size 
	V_BeamDiamDisplay("maximum", "MR")	//TODO -- hard-wired here for the Middle carriage (and in the SetVar label)
	V_BeamStopDiamDisplay("MR")
	
	//calculate the "real" QMin with the beamstop
	V_QMin_withBeamStop("MR")		//TODO -- hard-wired here as the middle carriage and MR panel
	

//// generate the 1D I(q) - get the values, re-do the calc at the end
	String popStr
	String collimationStr = "pinhole"
	ControlInfo/W=VCALC popup_b
	popStr = S_Value
	V_QBinAllPanels_Circular("VCALC",V_BinTypeStr2Num(popStr),collimationStr)

	// plot the results (1D)
	String type = "VCALC"
	String str,winStr="VCALC#Panels_IQ",workTypeStr
	workTypeStr = "root:Packages:NIST:VSANS:"+type
	
	sprintf str,"(\"%s\",%d,\"%s\")",workTypeStr,V_BinTypeStr2Num(popStr),winStr
	Execute ("V_Back_IQ_Graph"+str)
		
	Execute ("V_Middle_IQ_Graph"+str)
	
	Execute ("V_Front_IQ_Graph"+str)


// generate the 1D I(q)
//	V_QBinAllPanels_Circular("VCALC",V_BinTypeStr2Num(popStr),collimationStr)

	// multiply the averaged data by the shadow factor to simulate a beamstop
	V_IQ_BeamstopShadow()

		
	return(0)
End



// function to control the drawing of controls in the TabControl on the main panel
// Naming scheme for the controls MUST be strictly adhered to... else controls will 
// appear in odd places...
// all controls are named VCALCCtrl_NA where N is the tab number and A is the letter denoting
// the controls position on that particular tab.
// in this way, they will always be drawn correctly..
//
//
// -- this will need to be modified to allow for the graph to be drawn of the detector bank positions
//     if that is individual to each tab - or if it's  always visible - that's still to be decided.
//
//
Function VCALCTabProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"VCALCCtrl_", 10 characters
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,9]
		if(cmpstr(nameStr,"VCALCCtrl_")==0)
			onTab = str2num(item[10])			//[10] is a number
			ControlInfo $item
			switch(abs(V_flag))	
				case 1:
					Button $item,disable=(tab!=onTab)
					break
				case 2:	
					CheckBox $item,disable=(tab!=onTab)
					break
				case 3:	
					PopupMenu $item,disable=(tab!=onTab)
					break
				case 4:
					ValDisplay $item,disable=(tab!=onTab)
					break
				case 5:	
					SetVariable $item,disable=(tab!=onTab)
					break
				case 7:	
					Slider $item,disable=(tab!=onTab)
					break
				case 9:
					GroupBox $item,disable=(tab!=onTab)
					break
				case 10:	
					TitleBox $item,disable=(tab!=onTab)
					break
				// add more items to the switch if different control types are used
			endswitch
		endif
	endfor
	
	String str,str2
	Variable val,val2
	STRUCT WMPopupAction pa

	// if switching to the collim (tab=0) or sample (tab=1) then pop the source shape menu
	// if it's circular so that the "width" popup is not displayed
	//
	// if rectangular, then the proper values (and saved ones) must be displayed

	if(tab == 0)
		ControlInfo VCALCCtrl_0e
		if(cmpstr(S_Value,"circular")==0)
			ControlInfo VCALCCtrl_0f		//the source diam, could have different value if Ng=0
			str=S_Value
			val=V_Value
			
			pa.popStr="circular"
			pa.eventCode = 2		//mouse up
			VC_SourceApShapeSelectPopup(pa)
			PopupMenu VCALCCtrl_0f,popvalue=str,mode=val

		endif
		if(cmpstr(S_Value,"rectangular")==0)
			ControlInfo VCALCCtrl_0f		//the source width, could have different value if Ng=0
			str=S_Value
			val=V_Value
			
			ControlInfo VCALCCtrl_0g		//the source height, could have different value if Ng=0
			str2=S_Value
			val2=V_Value
			
			pa.popStr="rectangular"
			pa.eventCode = 2		//mouse up
			VC_SourceApShapeSelectPopup(pa)
			
			PopupMenu VCALCCtrl_0f,popvalue=str,mode=val
			PopupMenu VCALCCtrl_0g,popvalue=str2,mode=val2

		endif
	endif
	
	// and the same for the sample tab
	if(tab == 1)
		ControlInfo VCALCCtrl_1b
		if(cmpstr(S_Value,"circular")==0)
			ControlInfo VCALCCtrl_1c		//the sample diam, save the value
			str=S_Value
			val = V_Value
			
			pa.popStr="circular"
			pa.eventCode = 2		//mouse up
			VC_SampleApShapeSelectPopup(pa)
			PopupMenu VCALCCtrl_1c,popvalue=str,mode=val

		endif
		
		if(cmpstr(S_Value,"rectangular")==0)
			ControlInfo VCALCCtrl_1c		//the source width, could have different value if Ng=0
			str=S_Value
			val=V_Value
			
			ControlInfo VCALCCtrl_1f		//the source height, could have different value if Ng=0
			str2=S_Value
			val2=V_Value
			
			pa.popStr="rectangular"
			pa.eventCode = 2		//mouse up
			VC_SampleApShapeSelectPopup(pa)
			
			PopupMenu VCALCCtrl_1c,popvalue=str,mode=val
			PopupMenu VCALCCtrl_1f,popvalue=str2,mode=val2

		endif
		
		
	endif
	return(0)
End



// TODO
//changing the number of guides changes the SSD
// the source aperture popup may need to be updated
//
Function V_GuideSliderProc(ctrlName,sliderValue,event)
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved
	
	Variable recalc=0
	SVAR apStr = root:Packages:NIST:VSANS:VCALC:gSourceDiam
	
	if(event %& 0x1)	// bit 0, value set

		//change the sourceAp popup, SDD range, etc
		switch(sliderValue)
			case 0:
				apStr = "0.75 cm;1.5 cm;3.0 cm;"
				break
			default:
				apStr = "6.0 cm;"
				PopupMenu VCALCCtrl_0f,mode=1,popvalue="6.0 cm"
		endswitch
		ControlUpdate/W=VCALC VCALCCtrl_0f

//		Recalculate_AllDetectors()

	endif
	return 0
End





Function Front2DQ_Log_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			Execute "FrontPanels_AsQ()"
			Execute "MiddlePanels_AsQ()"
			Execute "BackPanels_AsQ()"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function VC_SourceAperDiamSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			

			V_beamIntensity()
						
			// a recalculation is needed after the change
			//Recalculate_AllDetectors()
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function VC_SampleAperDiamSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			

			V_beamIntensity()
						
			// a recalculation is needed after the change
			//Recalculate_AllDetectors()
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// see V_GuideSliderProc() for a possible workaround
////
//	String/G gSourceDiam = "6.0 cm;"
//	String/G gSourceDiam_0g = "0.75 cm;1.5 cm;3.0 cm;"		// values from John Mar 2018
//	String/G gSourceApertureWidth = "0.1 cm;0.25 cm;0.5 cm;"
//	String/G gSourceApertureHeight = "10.0 cm;15.0 cm;"
//	
// when a given shape is chosen update the size parameters
Function VC_SourceApShapeSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR diam= root:Packages:NIST:VSANS:VCALC:gSourceDiam
			SVAR wid= root:Packages:NIST:VSANS:VCALC:gSourceApertureWidth
			
			String apStr

			strswitch(popStr)
				case "circular":
					ControlInfo VCALCCtrl_0a		// the guide slider
					if(V_Value == 0)
						apStr = "0.75 cm;1.5 cm;3.0 cm;"
						diam = apStr			// change the global value
						PopupMenu VCALCCtrl_0f,title="source diam",mode=1,popvalue="0.75 cm"
					else
						apStr = "6.0 cm"
						diam = apStr
						PopupMenu VCALCCtrl_0f,title="source diam",mode=1,popvalue="6.0 cm"
					endif
					
					PopupMenu VCALCCtrl_0g,disable=1
					
					break
				case "rectangular":
					apStr = "10.0 cm;15.0 cm;"
					diam = apStr
					PopupMenu VCALCCtrl_0f,title="source height",mode=2,popvalue="15.0 cm"

					apStr = "0.1 cm;0.25 cm;0.5 cm;"
					wid = apStr
					PopupMenu VCALCCtrl_0g,disable=0,title="source width",mode=2,popvalue="0.25 cm"
					
					break
//				case "converging pinholes":
//					apStr = "0.75 cm;1.5 cm;3.0 cm;"
//					diam = apStr			// change the global value
//					PopupMenu VCALCCtrl_0f,title="source diam",mode=1,popvalue="0.75 cm"
//
//					PopupMenu VCALCCtrl_0g,disable=1
//					break
					
			endswitch	
//			Print "Not filled in yet"

			// a recalculation is needed after the change
			//VC_Recalculate_AllDetectors()
			
			// ay least update the intensity
			V_beamIntensity()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
//	String/G gSampleApertureDiam = "1.27;1.59;1.0;2.0;"
//	String/G gSampleApertureWidth = "0.125 cm;0.2 cm;0.3 cm;"
//	String/G gSampleApertureHeight = "7.5 cm;10.0 cm;"
//

// when a given shape is chosen udate the size parameters
Function VC_SampleApShapeSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR diam = root:Packages:NIST:VSANS:VCALC:gSampleApertureDiam
			SVAR wid = root:Packages:NIST:VSANS:VCALC:gSampleAperturewidth

			String  apStr
			
			strswitch(popStr)
				case "circular":
					apStr = "1.27;1.59;1.0;2.0;"
					diam = apStr
					PopupMenu VCALCCtrl_1c,title="Aperture Diam",mode=1,popValue="1.27"

					PopupMenu VCALCCtrl_1f,disable=1
					
					break
				case "rectangular":
					apStr = "7.5 cm;10.0 cm;"
					diam = apStr
					PopupMenu VCALCCtrl_1c,title="Aperture Height",mode=1,popValue="7.5 cm"

					apStr = "0.125 cm;0.2 cm;0.3 cm"
					wid = apStr
					PopupMenu VCALCCtrl_1f,disable=0,title="Aperture Width",mode=1,popValue="0.125 cm"

					break
//				case "converging pinholes":
//					apStr = "1.27;1.59;1.0;2.0;"
//					diam = apStr
//					PopupMenu VCALCCtrl_1c,title="Aperture Diam",mode=1,popValue="1.27"
//
//					PopupMenu VCALCCtrl_1f,disable=1
//					break
					
			endswitch	
//			Print "Not filled in yet"

			// a recalculation is needed after the change
			//VC_Recalculate_AllDetectors()
			
			//or at least update the beam intensity
			V_beamIntensity()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function VC_DeltaLamSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			// a recalculation is needed after the change
//			Recalculate_AllDetectors()
									
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// change the choices for deltaLam based on the
// type of monochromator selected
//
// some cases force a change of the wavelength
//
// then recalculate
Function VC_MonochromSelectPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR DLStr = root:Packages:NIST:VSANS:VCALC:gDeltaLambda
			
			strswitch(popStr)
				case "Velocity Selector":
					DLStr = "0.12;"
//					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.12"
					
					SetVariable VCALCCtrl_0b,disable=0,noedit=0		// allow user editing again

					break
				case "Graphite":
					DLStr = "0.01;"
//					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.01",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.01"
					
					SetVariable VCALCCtrl_0b,value=_NUM:4.75,disable=2		// wavelength
					break
				case "White Beam":
					DLStr = "0.40;"
//					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
					PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.40"

					SetVariable VCALCCtrl_0b,value=_NUM:5.3,disable=2		//wavelength
					break		
				default:
					Print "Error--No match in VC_MonochromSelectPopup"
					return(0)
			endswitch
			

			// a recalculation is needed after the change
//			Recalculate_AllDetectors()
								
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//
// "F+M Ng0 Low Q;F+M Ng2 Mid Q;F+M Ng7 Mid Q;F+M Ng9 High Q;Converging Pinholes;Narrow Slit;White Beam;Graphite;Polarizer;"
//
Function VC_PresetConfigPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			String BinStr = "F2-M2xTB-B"
		
			strswitch(popStr)
				case "F+M Ng0 Low Q":
					VC_Preset_FrontMiddle_Ng0()
					break
				case "F+M Ng2 Mid Q":
					VC_Preset_FrontMiddle_Ng2()
					break
				case "F+M Ng7 Mid Q":
					VC_Preset_FrontMiddle_Ng7()
					break
				case "F+M Ng9 High Q":
					VC_Preset_FrontMiddle_Ng9()
					break
					
				case "White Beam":
					VC_Preset_WhiteBeam()
					break	
				case "Graphite":
					VC_Preset_GraphiteMono()
					break
				case "Narrow Slit":
					VC_Preset_NarrowSlit()
					break
				case "Converging Pinholes":
					VC_Preset_ConvergingPinholes()
					break
				case "Polarizer":
					Print "Preset for Polarized beam not defined yet"
					break
				case "Super White Beam":
					VC_Preset_SuperWhiteBeam()
					break
				
				default:
					Print "Error--No match in VC_PresetConfigPopup"
					return(0)
			endswitch
			
			// update the views
			VC_UpdateViews()
			
			// a recalculation is needed after the change
			// this re-bins the data too
			VC_Recalculate_AllDetectors()
			

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End





//
// recalculate the detectors with a preset model function
//
Function VC_SimModelFunc_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

//	Recalculate_AllDetectors()
	
	return(0)	
End


//
// recalculate the I(q) binning. no need to adjust model function or views
// just rebin
//
// this is for the VCALC 1-D plot subwindow only. so it is set up to 
// operate on that window - but uses the same binning and plotting routines
// as the regualr VSANS data display
//
Function VC_RebinIQ_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string


	String type = "VCALC"
	String str,winStr="VCALC#Panels_IQ",workTypeStr
	workTypeStr = "root:Packages:NIST:VSANS:"+type
	
	String collimationStr = "pinhole"		//TODO: fill this in from the VCALC panel
	
// dispatch based on the string, not on the number of selection in the pop string
	V_QBinAllPanels_Circular(type,V_BinTypeStr2Num(popStr),collimationStr)
	
	sprintf str,"(\"%s\",%d,\"%s\")",workTypeStr,V_BinTypeStr2Num(popStr),winStr

	Execute ("V_Back_IQ_Graph"+str)
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)

//	
	return(0)	
End


//
// setVar for the distance from Sample Position to Gave Valve
//
Function VC_Sam_to_GV_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			// don't need to recalculate the views, but need to recalculate the detectors

//			Recalculate_AllDetectors()		
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
	

//
// setVar for the distance from Sample Aperture to Gave Valve
//
Function VC_A2_to_GV_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			// don't need to recalculate the views, but need to recalculate the detectors

//			Recalculate_AllDetectors()		
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
	
//
// setVar for the wavelength
//
Function VC_Lambda_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			// don't need to recalculate the views, but need to recalculate the detectors

//			Recalculate_AllDetectors()		
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// 

//
// setVar for the simulation counting time
//
Function VC_SimCtTime_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval

			// calc new iMon
			Variable iMon = V_beamIntensity() * dval
	//		Print iMon
			SetVariable VCALCCtrl_5a,value=_NUM:iMon			//display the value in the iMon control
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// setVar for the simulation monitor count
//
//
Function VC_SimImon_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval

//			Recalculate_AllDetectors()		

			// calc new count time
			Variable ctTime = dval/V_beamIntensity()
	//		Print ctTime
			SetVariable VCALCCtrl_5c,value=_NUM:ctTime			//display the value in the ctTime control				
				
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// setVar for the range (in degrees) for the FrontView plot of the detectors
//
Function FrontView_Range_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			FrontView_1x()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// setVar for the range (in Q) for the FrontView plot of the detectors
//
// TODO: this assumes that everything (the data) is already updated - this only updates the plot range
Function Front2DQ_Range_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			SetAxis/W=VCALC#Panels_Q left -dval,dval
			SetAxis/W=VCALC#Panels_Q bottom -dval,dval
			
//			FrontPanels_AsQ()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// SDD for the Front detector. triggers a recalculation
// of the intensity and a redraw of the banks
//
Function VC_FDet_SDD_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			Variable LR_sep,TB_sep
//			// don't know if LR or TB called, so get the explicit values
//			//
//			ControlInfo VCALCCtrl_2a
//			LR_sep = V_Value
//			ControlInfo VCALCCtrl_2b
//			TB_sep = V_Value
//			
//			UpdateFrontDetector(LR_sep,TB_sep)
			
			VC_UpdateViews()
			
			fPlotFrontPanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// SDD for the Middle detector. triggers a recalculation
// of the intensity and a redraw of the banks
//
Function VC_MDet_SDD_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			Variable LR_sep,TB_sep
//			// don't know if LR or TB called, so get the explicit values
//			//
//			ControlInfo VCALCCtrl_2a
//			LR_sep = V_Value
//			ControlInfo VCALCCtrl_2b
//			TB_sep = V_Value
//			
//			UpdateFrontDetector(LR_sep,TB_sep)
			
			VC_UpdateViews()
			
			fPlotMiddlePanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// SDD for the Back detector. triggers a recalculation
// of the intensity and a redraw of the banks
//
Function VC_BDet_SDD_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			Variable LR_sep,TB_sep
//			// don't know if LR or TB called, so get the explicit values
//			//
//			ControlInfo VCALCCtrl_2a
//			LR_sep = V_Value
//			ControlInfo VCALCCtrl_2b
//			TB_sep = V_Value
//			
//			UpdateFrontDetector(LR_sep,TB_sep)
			
			VC_UpdateViews()
			
			fPlotBackPanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// separation, either LR or TB of the front detector. triggers a recalculation
// of the intensity and a redraw of the banks
//
Function VC_FDet_LR_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			Variable LR_sep,TB_sep
//			// don't know if LR or TB called, so get the explicit values
//			//
//			ControlInfo VCALCCtrl_2a
//			LR_sep = V_Value
//			ControlInfo VCALCCtrl_2b
//			TB_sep = V_Value
//			
//			UpdateFrontDetector(LR_sep,TB_sep)
			
			VC_UpdateViews()
			
			fPlotFrontPanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// separation, either LR or TB of the middle detector. triggers a recalculation
// of the intensity and a redraw of the banks
//
Function VC_MDet_LR_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
//			Variable LR_sep,TB_sep
//			// don't know if LR or TB called, so get the explicit values
//			//
//			ControlInfo VCALCCtrl_3a
//			LR_sep = V_Value
//			ControlInfo VCALCCtrl_3b
//			TB_sep = V_Value
			
//			UpdateMiddleDetector(LR_sep,TB_sep)
			
			VC_UpdateViews()
			
			fPlotMiddlePanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// call to update the views (not the q-calculation, that is a separate call)
//
// commented out Aug2020 since degrees and side views removed
//
Function VC_UpdateViews()

//	UpdateSideView()
//	UpdateTopView()
//	FrontView_1x()
	
	return(0)
End

// this all needs to be fixed and updated - not yet specific to VSANS
//
// -- all of the simulation stuff will need to be re-thought
// -- all of the integersRead, data, etc. will need to be re-thought...
// -- but the space needs to be allocated.
// -- parameters and constants need to be defined in their own space
//
// FEB 2016 -- changed the data folder space to mimic the HDF folder structure
// so that the averaging routines could be re-used (along with everything else)
// -- painful, but better in the long run
//
// -- I have not re-named the detector arrays to all be "data" since that is very difficult to
//   deal with on images. Added a global "gVCALC_Active" as a crude workaround as needed. Turn it
//   on when needed and then immediately off
//
Proc VC_Initialize_Space()
//
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O root:Packages:NIST:VSANS
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MB
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MT
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_ML
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MR
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FB
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FT
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FL
	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FR

//	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:Front
//	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:Middle
//	NewDataFolder/O root:Packages:NIST:VSANS:VCALC:Back

	NewDataFolder/O root:Packages:NIST:VSANS:RawVSANS
	
	Variable/G root:Packages:NIST:VSANS:VCALC:gVCALC_Active = 1
	Variable/G root:Packages:NIST:VSANS:VCALC:gUseNonLinearDet = 0		//if == 1, use RAW non-linear corrections
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	

///// FRONT DETECTOR BANKS
// dimensions for the detector banks (then get them in the drawing functions)
// Width and height are not part of the Nexus file definition, but are needed for VCALC drawing
// so keep them as variables
	Variable/G gFront_LR_w = 40.3		//front bank, nominal LR panel width [cm]  0.84cm/tube*48 = 40.3 cm
	Variable/G gFront_LR_h = 100.0
	Variable/G gFront_TB_w = 50.0
	Variable/G gFront_TB_h = 40.3

// SDD setback of T/B (decide on units??)
// for the Nexus file, the detector distance should already be corrected for the "setback"
// of the T/B panels. keep as VCALC variable
	Variable/G gFront_SDDsetback = 41.0			// [cm]
	
	
// detector resolution (xy for each bank!)
	Make/O/D/N=1 :entry:instrument:detector_FL:x_pixel_size = 0.84		// (cm)		these tubes are vertical 8.4 mm x-spacing (JGB 2/2106)
	Make/O/D/N=1 :entry:instrument:detector_FL:y_pixel_size = 0.8		// (cm)		//!! now 8 mm, since nPix=128, rather than 256
	Make/O/D/N=1 :entry:instrument:detector_FR:x_pixel_size = 0.84
	Make/O/D/N=1 :entry:instrument:detector_FR:y_pixel_size = 0.8
	//T/B
	Make/O/D/N=1 :entry:instrument:detector_FT:x_pixel_size = 0.4		//these tubes are horizontal
	Make/O/D/N=1 :entry:instrument:detector_FT:y_pixel_size = 0.84
	Make/O/D/N=1 :entry:instrument:detector_FB:x_pixel_size = 0.4
	Make/O/D/N=1 :entry:instrument:detector_FB:y_pixel_size = 0.84
	

// number of pixels in each bank (this can be modified at acquisition time, so it must be adjustable here)
	Make/O/D/N=1 :entry:instrument:detector_FL:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FL:pixel_num_y = 128	// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
	Make/O/D/N=1 :entry:instrument:detector_FR:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FR:pixel_num_y = 128	// == pixels in vertical direction 
	Make/O/D/N=1 :entry:instrument:detector_FT:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_FT:pixel_num_y = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FB:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_FB:pixel_num_y = 48	// == number of tubes



// pixel beam center - HDF style
	Make/O/D/N=1 :entry:instrument:detector_FL:beam_center_x = 55		// == x beam center, in pixels
	Make/O/D/N=1 :entry:instrument:detector_FL:beam_center_y = 64		// == y beam center, in pixels
	Make/O/D/N=1 :entry:instrument:detector_FR:beam_center_x = -8	
	Make/O/D/N=1 :entry:instrument:detector_FR:beam_center_y = 64	
	Make/O/D/N=1 :entry:instrument:detector_FT:beam_center_x = 64	
	Make/O/D/N=1 :entry:instrument:detector_FT:beam_center_y = -8	
	Make/O/D/N=1 :entry:instrument:detector_FB:beam_center_x = 64	
	Make/O/D/N=1 :entry:instrument:detector_FB:beam_center_y = 55	



///// MIDDLE DETECTOR BANKS
// Width and height are not part of the Nexus file definition, but are needed for VCALC drawing
// so keep them as variables
	Variable/G gMiddle_LR_w = 40.3			//middle bank, nominal LR panel width (cm) 0.84cm/tube*48 = 40.3 cm
	Variable/G gMiddle_LR_h = 100.0
	Variable/G gMiddle_TB_w = 50.0
	Variable/G gMiddle_TB_h = 40.3
// SDD offset of T/B (decide on units??)
// for the Nexus file, the detector distance should already be corrected for the "setback"
// of the T/B panels. keep as VCALC variable
	Variable/G gMiddle_SDDsetback = 41.0			// [cm]
	
// detector resolution (xy for each bank!)
	Make/O/D/N=1 :entry:instrument:detector_ML:x_pixel_size = 0.84		// (cm)		these tubes are vertical 8.4 mm x-spacing (JGB 2/2106)
	Make/O/D/N=1 :entry:instrument:detector_ML:y_pixel_size = 0.8		// (cm)		//!! now 8 mm, since nPix=128, rather than 256
	Make/O/D/N=1 :entry:instrument:detector_MR:x_pixel_size = 0.84
	Make/O/D/N=1 :entry:instrument:detector_MR:y_pixel_size = 0.8
	//T/B
	Make/O/D/N=1 :entry:instrument:detector_MT:x_pixel_size = 0.4		//these tubes are horizontal
	Make/O/D/N=1 :entry:instrument:detector_MT:y_pixel_size = 0.84
	Make/O/D/N=1 :entry:instrument:detector_MB:x_pixel_size = 0.4
	Make/O/D/N=1 :entry:instrument:detector_MB:y_pixel_size = 0.84



// number of pixels in each bank (this can be modified at acquisition time, so it must be adjustable here)
	Make/O/D/N=1 :entry:instrument:detector_ML:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_ML:pixel_num_y = 128	// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
	Make/O/D/N=1 :entry:instrument:detector_MR:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_MR:pixel_num_y = 128	// == pixels in vertical direction 
	Make/O/D/N=1 :entry:instrument:detector_MT:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_MT:pixel_num_y = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_MB:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_MB:pixel_num_y = 48	// == number of tubes
	


// pixel beam center - HDF style
	Make/O/D/N=1 :entry:instrument:detector_ML:beam_center_x = 55		// == x beam center, in pixels
	Make/O/D/N=1 :entry:instrument:detector_ML:beam_center_y = 64		// == y beam center, in pixels
	Make/O/D/N=1 :entry:instrument:detector_MR:beam_center_x = -8	
	Make/O/D/N=1 :entry:instrument:detector_MR:beam_center_y = 64	
	Make/O/D/N=1 :entry:instrument:detector_MT:beam_center_x = 64	
	Make/O/D/N=1 :entry:instrument:detector_MT:beam_center_y = -8	
	Make/O/D/N=1 :entry:instrument:detector_MB:beam_center_x = 64	
	Make/O/D/N=1 :entry:instrument:detector_MB:beam_center_y = 55	




//// BACK DETECTOR
	Variable/G gBack_w = 22.2				//w and h for the back detector [cm]
	Variable/G gBack_h = 50.4
	
	
	// TODOHIRES -- be sure that all of this is correct, since it is hard-wired values
	// -- can't use a switch so I'm using an if(), where the default is 4x4 binning
	if(root:Packages:NIST:VSANS:Globals:gHighResBinning == 1)
		Make/O/D/N=1 :entry:instrument:detector_B:x_pixel_size = 0.00845		// 340 micron resolution (units of [cm] here)
		Make/O/D/N=1 :entry:instrument:detector_B:y_pixel_size = 0.00845		
	
		Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_x = 2720		// detector pixels in x-direction
		Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_y = 6624
		
	// pixel beam center - HDF style
		Make/O/D/N=1 :entry:instrument:detector_B:beam_center_x = 1360.1	// == x beam center, in pixels +0.1 so I know it's from here
		Make/O/D/N=1 :entry:instrument:detector_B:beam_center_y = 3312.1		// == y beam center, in pixels
	else
		Make/O/D/N=1 :entry:instrument:detector_B:x_pixel_size = 0.034		// 340 micron resolution (units of [cm] here)
		Make/O/D/N=1 :entry:instrument:detector_B:y_pixel_size = 0.034		
	
		Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_x = 680		// detector pixels in x-direction
		Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_y = 1656
		
	// pixel beam center - HDF style
		Make/O/D/N=1 :entry:instrument:detector_B:beam_center_x = 340.1	// == x beam center, in pixels +0.1 so I know it's from here
		Make/O/D/N=1 :entry:instrument:detector_B:beam_center_y = 828.1		// == y beam center, in pixels
	endif


// Generate all of the waves used for the detector and the q values
//
// TODO: the detector dimensions need to be properly defined here...
// FRONT
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FL
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_FL
	Duplicate/O det_FL qTot_FL,qx_FL,qy_FL,qz_FL

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FR
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_FR
	Duplicate/O det_FR qTot_FR,qx_FR,qy_FR,qz_FR

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FT
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_FT
	Duplicate/O det_FT qTot_FT,qx_FT,qy_FT,qz_FT
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FB
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_FB
	Duplicate/O det_FB qTot_FB,qx_FB,qy_FB,qz_FB


//MIDDLE
// TODO: the detector dimensions need to be properly defined here...
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_ML
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_ML
	Duplicate/O det_ML qTot_ML,qx_ML,qy_ML,qz_ML
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MR
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_MR
	Duplicate/O det_MR qTot_MR,qx_MR,qy_MR,qz_MR

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MT
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_MT
	Duplicate/O det_MT qTot_MT,qx_MT,qy_MT,qz_MT
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_MB
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_MB
	Duplicate/O det_MB qTot_MB,qx_MB,qy_MB,qz_MB

// BACK
// TODO: the detector dimensions need to be properly defined here...
//	SetDataFolder root:Packages:NIST:VSANS:VCALC:Back

	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B
	Make/O/D/N=(pixel_num_x[0],pixel_num_y[0]) det_B
	Duplicate/O det_B qTot_B,qx_B,qy_B,qz_B


////////////	FOR THE PANEL

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	Make/O/D/N=2 fpx1,fpy1,mpx1,mpy1		// for display of the detector panels
	Make/O/D/N=2 fv_degX,fv_degY


// to fill in:
// values for always-visible items
	String/G gPresetPopStr = "F+M Ng0 Low Q;F+M Ng2 Mid Q;F+M Ng7 Mid Q;F+M Ng9 High Q;Converging Pinholes;Narrow Slit;White Beam;Super White Beam;Graphite;Polarizer;"
	String/G gBinTypeStr = ksBinTypeStr
	Variable/G gBeamIntensity= 0

	Variable/G gQmin_F,gQmax_F,gQmin_M,gQmax_M,gQmin_B,gQmax_B
	Variable/G gBeamDiam,gBeamStopDiam
	Variable/G gRealQMin

// popup strings for each tab (then use the string in the panel)
// tab 0 - collimation
	String/G gMonochromatorType = "Velocity Selector;Graphite;White Beam;Super White Beam;"
	String/G gSourceShape = "circular;rectangular;"		//converging pinholes;"
	String/G gSourceDiam = "6.0 cm;"
	String/G gSourceDiam_0g = "0.75 cm;1.5 cm;3.0 cm;"		// values from John Mar 2018
	String/G gSourceApertureWidth = "0.1 cm;0.25 cm;0.5 cm;"
	String/G gSourceApertureHeight = "10.0 cm;15.0 cm;"

	String/G gDeltaLambda = "0.12;"
	
// tab 1 - sample conditions
	String/G gTableLocation = "Changer;Stage;"
	String/G gSampleApertureShape = "circular;rectangular;"		//converging pinholes;"
	String/G gSampleApertureDiam = "1.27;1.59;1.0;2.0;"
	String/G gSampleApertureWidth = "0.125 cm;0.2 cm;0.3 cm;"
	String/G gSampleApertureHeight = "7.5 cm;10.0 cm;"
	
// tab 2

// tab 3

// tab 4 - back detector
	String/G gBackDetType = "1D;2D;"

// tab 5
	String/G gModelFunctionType = "Debye;Sphere;Big Debye;Big Sphere;AgBeh;Vycor;Empty Cell;Blocked Beam;"
	gModelFunctionType += "Debye +;AgBeh +;Empty Cell +;"

////////////////////



// limits for detector travel? or are these limits part of the panel, hard-wired there


//	// for the panel

//	Variable/G gNg=0
//	Variable/G gOffset=0
//	Variable/G gSamAp=1.27		//samAp diameter in cm
//	String/G gSourceApString = "1.43 cm;2.54 cm;3.81 cm;"
//	String/G gApPopStr = "1/16\";1/8\";3/16\";1/4\";5/16\";3/8\";7/16\";1/2\";9/16\";5/8\";11/16\";3/4\";other;"
//	Variable/G gSamApOther = 10		//non-standard aperture diameter, in mm
//	Variable/G gUsingLenses = 0		//0=no lenses, 1=lenses(or prisms)
//	Variable/G gModelOffsetFactor = 1
//	
//	// for the MC simulation
//	Variable/G doSimulation	=0		// == 1 if 1D simulated data, 0 if other from the checkbox
//	Variable/G gRanDateTime=datetime
//	Variable/G gImon = 10000
//	Variable/G gThick = 0.1
//	Variable/G gSig_incoh = 0.1
//	String/G gFuncStr = ""
//	Variable/G gR2 = 2.54/2	
//	Variable/G gSamTrans=0.8			//for 1D, default value
//	Variable/G gCntTime = 300
//	Variable/G gDoMonteCarlo = 0
//	Variable/G gUse_MC_XOP = 1				//set to zero to use Igor code
//	Variable/G gBeamStopIn = 1			//set to zero for beamstop out (transmission)
//	Variable/G gRawCounts = 0
//	Variable/G gSaveIndex = 100
//	String/G gSavePrefix = "SIMUL"
//	Variable/G gAutoSaveIndex = 100			//a way to set the index for automated saves
//	String/G gAutoSaveLabel = ""				//a way to set the "sample" label for automated saves
//	Make/O/D/N=10 results = 0
//	Make/O/T/N=10 results_desc = {"total X-section (1/cm)","SAS X-section (1/cm)","number that scatter","number that reach detector","avg # times scattered","fraction single coherent","fraction multiple coherent","fraction multiple scattered","fraction transmitted","detector counts w/beamstop"}
//
//	Variable/G g_1DTotCts = 0			//summed counts (simulated)
//	Variable/G g_1DEstDetCR = 0		// estimated detector count rate
//	Variable/G g_1DFracScatt = 0		// fraction of beam captured on detector
//	Variable/G g_1DEstTrans = 0		// estimated transmission of sample
//	Variable/G g_1D_DoABS = 1
//	Variable/G g_1D_AddNoise = 1
//	Variable/G g_MultScattFraction=0
//	Variable/G g_detectorEff=0.75			//average value for most wavelengths
//	Variable/G g_actSimTime = 0				//for the save
//	Variable/G g_SimTimeWarn = 10			//manually set to a very large value for scripted operation
//	

//	
//	//for the fake dependency
//	Variable/G gTouched=0
//	Variable/G gCalculate=0
//	//for plotting
//	Variable/G gFreezeCount=1		//start the count at 1 to keep Jeff happy
//	Variable/G gDoTraceOffset=0		// (1==Yes, offset 2^n), 0==turn off the offset

//
// instrument - specific dimensions
//

//	
//	Variable/G gInstrument = 6		// files (may) be tagged SA6 as the 6th SANS instrument
//	Variable/G gS12 = 54.8
//	Variable/G d_det = 0.5
//	Variable/G a_pixel = 0.5
//	Variable/G del_r = 0.5
//	Variable/G det_width = 64.0
//	Variable/G gLambda_t = 5.50
//	Variable/G gL2r_lower = 132.3
//	Variable/G gL2r_upper =  1317
//	Variable/G gLambda_lower = 2.5
//	Variable/G gLambda_upper = 20.0
//	Variable/G gD_upper = 25.0
//	Variable/G gBs_factor = 1.05
//	Variable/G gT1 = 0.63
//	Variable/G gT2 = 1.0
//	Variable/G gT3 = 0.75
//	Variable/G gL_gap = 100.0
//	Variable/G gGuide_width = 6.0
//	Variable/G gIdmax = 100.0

//
//	//new values, from 11/2009 --- BeamFluxReport_2009.ifn
//	Variable/G gPhi_0 = 2.42e13
//	Variable/G gB = 0.0
//	Variable/G gC = -0.0243
//	Variable/G gGuide_loss = 0.924
//	
//	//fwhm values (new variables) (+3, 0, -3, calibrated 2009)
//	Variable/G gFwhm_narrow = 0.109
//	Variable/G gFwhm_mid = 0.125
//	Variable/G gFwhm_wide = 0.236
//	
//	//source apertures (cm)
//	Variable/G gA1_0_0 = 1.43
//	Variable/G gA1_0_1 = 2.54
//	Variable/G gA1_0_2 = 3.81
//	Variable/G gA1_7_0 = 2.5			// after the polarizer		
//	Variable/G gA1_7_1 = 5.0
//	Variable/G gA1_7_1 = 0.95		//
//	Variable/G gA1_def = 5.00
//	
	SetDataFolder root:
end

// set the global values for display
Function V_QMinMax_Back()

	NVAR min_b = root:Packages:NIST:VSANS:VCALC:gQmin_B
	NVAR max_b = root:Packages:NIST:VSANS:VCALC:gQmax_B

	String folderStr = "VCALC"
	String detStr = ""

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	detStr = "B"
	WAVE qTot_B = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_B = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	Duplicate/O qTot_B tmp_B
	// for the minimum
	tmp_B = (mask_B == 0) ? qTot_B : 1e6
	min_b = WaveMin(tmp_B)

	// for the maximum
	tmp_B = (mask_B == 0) ? qTot_B : -1e6
	max_b = WaveMax(tmp_B)

	KillWaves/Z tmp_B

	return(0)
end

// set the global values for display
Function V_QMinMax_Middle()

	NVAR min_m = root:Packages:NIST:VSANS:VCALC:gQmin_M
	NVAR max_m = root:Packages:NIST:VSANS:VCALC:gQmax_M

	String folderStr = "VCALC"
	String detStr = ""

	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	detStr = "ML"
	WAVE qTot_ML = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_ML = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	detStr = "MR"
	WAVE qTot_MR = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_MR = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	detStr = "MT"
	WAVE qTot_MT = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_MT = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	detStr = "MB"
	WAVE qTot_MB = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_MB = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	Variable min1,min2,min3,min4
	Variable max1,max2,max3,max4
	// WaveMin(), WaveMax() will report NaN or inf
	// so for the min, set masked values to 1e6
	Duplicate/O qTot_ML tmp_ML
	tmp_ML = (mask_ML == 0) ? qTot_ML : 1e6

	Duplicate/O qTot_MR tmp_MR
	tmp_MR = (mask_MR == 0) ? qTot_MR : 1e6
	
	Duplicate/O qTot_MT tmp_MT
	tmp_MT = (mask_MT == 0) ? qTot_MT : 1e6
	
	Duplicate/O qTot_MB tmp_MB
	tmp_MB = (mask_MB == 0) ? qTot_MB : 1e6
	
	min1 = WaveMin(tmp_ML)
	min2 = WaveMin(tmp_MR)
	min3 = WaveMin(tmp_MT)
	min4 = WaveMin(tmp_MB)

	// so for the max, set masked values to -1e6
	tmp_ML = (mask_ML == 0) ? qTot_ML : -1e6
	tmp_MR = (mask_MR == 0) ? qTot_MR : -1e6
	tmp_MT = (mask_MT == 0) ? qTot_MT : -1e6
	tmp_MB = (mask_MB == 0) ? qTot_MB : -1e6
	
	max1 = WaveMax(tmp_ML)
	max2 = WaveMax(tmp_MR)
	max3 = WaveMax(tmp_MT)
	max4 = WaveMax(tmp_MB)

//	print min1,min2,min3,min4
//	print max1,max2,max3,max4
		
	min_m = min(min1,min2,min3,min4)
	max_m = max(max1,max2,max3,max4)

//	min_m = min(WaveMin(tmp_ML),WaveMin(tmp_MT),WaveMin(tmp_MR),WaveMin(tmp_MB))
//	max_m = max(WaveMax(tmp_ML),WaveMax(tmp_MT),WaveMax(tmp_MR),WaveMax(tmp_MB))
	
	KillWaves/Z tmp_ML,tmp_MR,tmp_MT,tmp_MB

	return(0)
end

// set the global values for display
Function V_QMinMax_Front()

	NVAR min_f = root:Packages:NIST:VSANS:VCALC:gQmin_F
	NVAR max_f = root:Packages:NIST:VSANS:VCALC:gQmax_F

	String folderStr = "VCALC"
	String detStr = ""
	
	String folderPath = "root:Packages:NIST:VSANS:"+folderStr
	String instPath = ":entry:instrument:detector_"	

	detStr = "FL"
	WAVE qTot_FL = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_FL = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")
	
	detStr = "FR"
	WAVE qTot_FR = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_FR = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	detStr = "FT"
	WAVE qTot_FT = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_FT = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	detStr = "FB"
	WAVE qTot_FB = $(folderPath+instPath+detStr+":qTot_"+detStr)
	WAVE mask_FB = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

	Variable min1,min2,min3,min4
	Variable max1,max2,max3,max4
	// WaveMin(), WaveMax() will report NaN or inf
	// so for the min, set masked values to 1e6
	Duplicate/O qTot_FL tmp_FL
	tmp_FL = (mask_FL == 0) ? qTot_FL : 1e6

	Duplicate/O qTot_FR tmp_FR
	tmp_FR = (mask_FR == 0) ? qTot_FR : 1e6
	
	Duplicate/O qTot_FT tmp_FT
	tmp_FT = (mask_FT == 0) ? qTot_FT : 1e6
	
	Duplicate/O qTot_FB tmp_FB
	tmp_FB = (mask_FB == 0) ? qTot_FB : 1e6

	min1 = WaveMin(tmp_FL)
	min2 = WaveMin(tmp_FR)
	min3 = WaveMin(tmp_FT)
	min4 = WaveMin(tmp_FB)
	
	// so for the max, set masked values to -1e6
	tmp_FL = (mask_FL == 0) ? qTot_FL : -1e6
	tmp_FR = (mask_FR == 0) ? qTot_FR : -1e6
	tmp_FT = (mask_FT == 0) ? qTot_FT : -1e6
	tmp_FB = (mask_FB == 0) ? qTot_FB : -1e6


	max1 = WaveMax(tmp_FL)
	max2 = WaveMax(tmp_FR)
	max3 = WaveMax(tmp_FT)
	max4 = WaveMax(tmp_FB)

//	print min1,min2,min3,min4
//	print max1,max2,max3,max4
		
	min_f = min(min1,min2,min3,min4)
	max_f = max(max1,max2,max3,max4)
	
//	min_f = min(WaveMin(tmp_FL),WaveMin(tmp_FT),WaveMin(tmp_FR),WaveMin(tmp_FB))
//	max_f = max(WaveMax(tmp_FL),WaveMax(tmp_FT),WaveMax(tmp_FR),WaveMax(tmp_FB))

	KillWaves/Z tmp_FL,tmp_FR,tmp_FT,tmp_FB
	return(0)
end

Function V_QMin_withBeamStop(detStr)
	String detStr
	
	NVAR val = root:Packages:NIST:VSANS:VCALC:gRealQMin

	Variable BSDiam,SDD,two_theta,lambda,qMin

	BSDiam = VC_beamstopDiam(detStr)
	SDD = VC_getSDD(detStr)
	SDD += VCALC_getTopBottomSDDSetback(detStr)
	lambda = VCALC_getWavelength()
	
	two_theta = atan(BSDiam/2/SDD)
	qMin = 4*pi/lambda*sin(two_theta/2)
		
	val = qMin
	
	return(0)
End


Function V_BeamDiamDisplay(direction, detStr)
	String direction
	String detStr
	
	NVAR val = root:Packages:NIST:VSANS:VCALC:gBeamDiam

	val = VC_beamDiameter(direction, detStr)		//middle carriage, maximum extent, includes gravity

	return(0)
End


// carrNum 1=front, 2=middle, 3=back
Function V_BeamStopDiamDisplay(detStr)
	String detStr

	NVAR val = root:Packages:NIST:VSANS:VCALC:gBeamStopDiam

	val = VC_beamstopDiam(detStr)		//returns the value in inches

	return(0)
End
	
		
	