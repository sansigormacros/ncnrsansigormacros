#pragma rtGlobals=1		// Use modern global access method.

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


Macro VCALC_Panel()
	DoWindow/F VCALC
	if(V_flag==0)
	
		//initialize space = folders, parameters, instrument constants, etc.
		VC_Initialize_Space()
		
		//open the panel
		DrawVCALC_Panel()
		
		// two graphs with the ray-tracing side/top views
		SetupSideView()
		SetupTopView()
		
		// a front view of the panels
		FrontView_1x()
		
		// TODO: fake a "click" on the front SDD to force (almost)everything to update
		// including the I(q) graph
		FakeFrontMiddleSDDClick()

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
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(34,44,1274,699)/N=VCALC/K=1
	ModifyPanel cbRGB=(49151,60031,65535)
//	ShowTools/A
	SetDrawLayer UserBack
	
// always visible stuff, not on any tab
	
	GroupBox group0,pos={10,10},size={444,180},title="Setup"
	TabControl Vtab,labelBack=(45000,61000,58000),pos={14,215},size={430,426},tabLabel(0)="Collim"
	TabControl Vtab,tabLabel(1)="Sample",tabLabel(2)="Front Det",tabLabel(3)="Mid Det"
	TabControl Vtab,tabLabel(4)="Back Det",tabLabel(5)="Simul",value= 0,proc=VCALCTabProc
	GroupBox group1,pos={460,10},size={762,635},title="Detector Panel Positions + Data"

	PopupMenu popup_a,pos={50,40},size={142,20},title="Presets"
	PopupMenu popup_a,mode=1,popvalue="Low Q",value= root:Packages:NIST:VSANS:VCALC:gPresetPopStr

	PopupMenu popup_b,pos={690,310},size={142,20},title="Binning type",proc=VC_RebinIQ_PopProc
	PopupMenu popup_b,mode=1,popvalue="One",value= root:Packages:NIST:VSANS:VCALC:gBinTypeStr
	
	SetVariable setVar_a,pos={476,26},size={120,15},title="axis degrees",proc=FrontView_Range_SetVarProc
	SetVariable setVar_a,limits={0.3,30,0.2},value=_NUM:20

	// for panels (in degrees)	
	Display/W=(476,45,757,303)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,FrontView
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "degrees"
	Label bottom "degrees"	
	SetActiveSubwindow ##


	// for side view
	Display/W=(842,25,1200,170)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,SideView
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "Vertical position (mm)"
	Label bottom "SDD (m)"	
	SetActiveSubwindow ##	
	
	// for top view
	Display/W=(842,180,1200,325)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,TopView
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "Horizontal position (mm)"
	Label bottom "SDD (m)"	
	SetActiveSubwindow ##	

	// for panels (as 2D Q)
	Display/W=(475,332,814,631)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,Panels_Q
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph tick=2,mirror=1,grid=2,standoff=0
	ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
	SetAxis left -0.2,0.2
	SetAxis bottom -0.2,0.2
	Label left "Qy"
	Label bottom "Qx"	
	SetActiveSubwindow ##

	SetVariable setVar_b,pos={476,314},size={120,15},title="axis Q",proc=Front2DQ_Range_SetVarProc
	SetVariable setVar_b,limits={0.02,1,0.02},value=_NUM:0.3
	CheckBox check_0a title="Log?",size={60,20},pos={619,313},proc=Front2DQ_Log_CheckProc

	// for averaged I(Q)
	Display/W=(842,334,1204,629)/HOST=# //root:Packages:NIST:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,Panels_IQ
//	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph tick=2,mirror=1,grid=2
//	Label left "Intensity"
//	Label bottom "Q"	
	SetActiveSubwindow ##


	
// all controls are named VCALCCtrl_NA where N is the tab number and A is the letter denoting

	
// tab(0), collimation - initially visible
	Slider VCALCCtrl_0a,pos={223,324},size={200,45},limits={0,10,1},value= 1,vert= 0
	SetVariable VCALCCtrl_0b,pos={25,294},size={120,15},title="wavelength"
	SetVariable VCALCCtrl_0b,limits={4,20,1},value=_NUM:8,proc=VC_Lambda_SetVarProc
	PopupMenu VCALCCtrl_0c,pos={26,257},size={150,20},title="monochromator"
	PopupMenu VCALCCtrl_0c,mode=1,popvalue="Velocity Selector",value= root:Packages:NIST:VSANS:VCALC:gMonochromatorType
	PopupMenu VCALCCtrl_0d,pos={26,321},size={115,20},title="delta lambda"
	PopupMenu VCALCCtrl_0d,mode=1,popvalue="0.10",value= root:Packages:NIST:VSANS:VCALC:gDeltaLambda
	PopupMenu VCALCCtrl_0e,pos={291,262},size={132,20},title="source shape"
	PopupMenu VCALCCtrl_0e,mode=1,popvalue="circular",value= root:Packages:NIST:VSANS:VCALC:gSourceShape
	PopupMenu VCALCCtrl_0f,pos={283,293},size={141,20},title="source aperture"
	PopupMenu VCALCCtrl_0f,mode=1,popvalue="1.0 cm",value= root:Packages:NIST:VSANS:VCALC:gSourceDiam
	

// tab(1) - Sample conditions, initially not visible
	PopupMenu VCALCCtrl_1a,pos={38,270},size={142,20},title="table location",disable=1
	PopupMenu VCALCCtrl_1a,mode=1,popvalue="Changer",value= root:Packages:NIST:VSANS:VCALC:gTableLocation
	PopupMenu VCALCCtrl_1b,pos={270,270},size={115,20},title="Aperture Shape",disable=1
	PopupMenu VCALCCtrl_1b,mode=1,popvalue="circular",value= root:Packages:NIST:VSANS:VCALC:gSampleApertureShape 
	PopupMenu VCALCCtrl_1c,pos={270,330},size={132,20},title="Aperture Size (cm)",disable=1
	PopupMenu VCALCCtrl_1c,mode=1,popvalue="0.5",value= root:Packages:NIST:VSANS:VCALC:gSampleApertureDiam
	

// tab(2) - Front detector panels, initially not visible
	SetVariable VCALCCtrl_2a,pos={30,260},size={150,15},title="L/R Separation (mm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2a,limits={0,400,1},disable=1,value=_NUM:100
	SetVariable VCALCCtrl_2b,pos={30,290},size={150,15},title="T/B Separation (mm)",proc=VC_FDet_LR_SetVarProc
	SetVariable VCALCCtrl_2b,limits={0,400,1},disable=1,value=_NUM:100
	SetVariable VCALCCtrl_2c,pos={205,290},size={150,15},title="Lateral Offset (mm)"
	SetVariable VCALCCtrl_2c,limits={0,200,0.1},disable=1,value=_NUM:0
	SetVariable VCALCCtrl_2d,pos={205,260},size={230,15},title="Sample to Detector Distance (m)",proc=VC_FDet_SDD_SetVarProc
	SetVariable VCALCCtrl_2d,limits={1,8,0.1},disable=1	,value=_NUM:1.5
	

// tab(3) - Middle detector panels, initially not visible
	SetVariable VCALCCtrl_3a,pos={30,260},size={150,15},title="L/R Separation (mm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3a,limits={0,400,1},disable=1,value=_NUM:120
	SetVariable VCALCCtrl_3b,pos={30,290},size={150,15},title="T/B Separation (mm)",proc=VC_MDet_LR_SetVarProc
	SetVariable VCALCCtrl_3b,limits={0,400,1},disable=1,value=_NUM:120
	SetVariable VCALCCtrl_3c,pos={205,290},size={150,15},title="Lateral Offset (mm)"
	SetVariable VCALCCtrl_3c,limits={0,200,0.1},disable=1,value=_NUM:0
	SetVariable VCALCCtrl_3d,pos={205,260},size={230,15},title="Sample to Detector Distance (m)",proc=VC_MDet_SDD_SetVarProc
	SetVariable VCALCCtrl_3d,limits={8,20,0.1},disable=1,value=_NUM:10
	
// tab(4) - Back detector panel
	SetVariable VCALCCtrl_4a,pos={188,290},size={150,15},title="Lateral Offset (mm)"
	SetVariable VCALCCtrl_4a,limits={0,200,0.1},disable=1,value=_NUM:0
	SetVariable VCALCCtrl_4b,pos={188,260},size={230,15},title="Sample to Detector Distance (m)",proc=VC_BDet_SDD_SetVarProc
	SetVariable VCALCCtrl_4b,limits={20,25,0.1},disable=1,value=_NUM:22
	PopupMenu VCALCCtrl_4c,pos={40,260},size={180,20},title="Detector type",disable=1
	PopupMenu VCALCCtrl_4c,mode=1,popvalue="2D",value= root:Packages:NIST:VSANS:VCALC:gBackDetType

// tab(5) - Simulation setup
 	SetVariable VCALCCtrl_5a,pos={40,290},size={200,15},title="Neutrons on Sample (imon)"
	SetVariable VCALCCtrl_5a,limits={1e7,1e15,1e7},disable=1,value=_NUM:1e10,proc=VC_SimImon_SetVarProc
	PopupMenu VCALCCtrl_5b,pos={40,260},size={180,20},title="Model Function",disable=1
	PopupMenu VCALCCtrl_5b,mode=1,popvalue="Debye",value= root:Packages:NIST:VSANS:VCALC:gModelFunctionType,proc=VC_SimModelFunc_PopProc
	
End

//
// just recalculates the detector panels, doesn't adjust the views
//
Function Recalculate_AllDetectors()

	fPlotBackPanels()
	fPlotMiddlePanels()
	fPlotFrontPanels()

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
	

	
	return(0)
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

//
// recalculate the detectors with a preset model function
//
Function VC_SimModelFunc_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	Recalculate_AllDetectors()
	
	return(0)	
End


//
// recalculate the I(q) binning. no need to adjust model function or views
// just rebin
//
Function VC_RebinIQ_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	// do the q-binning for front panels to get I(Q)
	Execute "BinAllFrontPanels()"
	Execute "Front_IQ_Graph()"

	// do the q-binning for middle panels to get I(Q)
	Execute "BinAllMiddlePanels()"
	Execute "Middle_IQ_Graph()"
	
	// do the q-binning for the back panel to get I(Q)
	Execute "BinAllBackPanels()"
	Execute "Back_IQ_Graph()"
	
	return(0)	
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
//			fPlotBackPanels()
//			fPlotMiddlePanels()
//			fPlotFrontPanels()

			Recalculate_AllDetectors()		
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// setVar for the simulation monitor count
//
Function VC_SimImon_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval

			Recalculate_AllDetectors()		
				
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
			
			UpdateSideView()
			UpdateTopView()
			FrontView_1x()
			
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
			
			UpdateSideView()
			UpdateTopView()
			FrontView_1x()
			
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
			
			UpdateSideView()
			UpdateTopView()
			FrontView_1x()
			
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
			
			Variable LR_sep,TB_sep
			// don't know if LR or TB called, so get the explicit values
			//
			ControlInfo VCALCCtrl_2a
			LR_sep = V_Value
			ControlInfo VCALCCtrl_2b
			TB_sep = V_Value
			
//			UpdateFrontDetector(LR_sep,TB_sep)
			
			UpdateSideView()
			UpdateTopView()
			FrontView_1x()
			
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
			
			Variable LR_sep,TB_sep
			// don't know if LR or TB called, so get the explicit values
			//
			ControlInfo VCALCCtrl_3a
			LR_sep = V_Value
			ControlInfo VCALCCtrl_3b
			TB_sep = V_Value
			
//			UpdateMiddleDetector(LR_sep,TB_sep)
			
			UpdateSideView()
			UpdateTopView()
			FrontView_1x()
			
			fPlotMiddlePanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




// this all needs to be fixed and updated - it is all pertinent to SANS (SASCALC)
// and not yet specific to VSANS
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
	Variable/G gFront_LR_w = 384		//front bank, nominal LR panel width (mm)
	Variable/G gFront_LR_h = 1000
	Variable/G gFront_TB_w = 500
	Variable/G gFront_TB_h = 384

// SDD offset of T/B (decide on units??)
// for the Nexus file, the detector distance should already be corrected for the "setback"
// of the T/B panels. keep as VCALC variable
	Variable/G gFront_SDDOffset = 300			// (mm)
	
	
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
	
//	Variable/G gFront_L_pixelX = 0.84			
//	Variable/G gFront_L_pixelY = 0.8			
//	Variable/G gFront_R_pixelX = 0.84			// (cm)
//	Variable/G gFront_R_pixelY = 0.8			// (cm)
//	
//	Variable/G gFront_T_pixelX = 0.4			// (cm)		these tubes are horizontal
//	Variable/G gFront_T_pixelY = 0.84			// (cm)
//	Variable/G gFront_B_pixelX = 0.4			// (cm)
//	Variable/G gFront_B_pixelY = 0.84			// (cm)
	
// number of pixels in each bank (this can be modified at acquisition time, so it must be adjustable here)
	Make/O/D/N=1 :entry:instrument:detector_FL:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FL:pixel_num_y = 128	// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
	Make/O/D/N=1 :entry:instrument:detector_FR:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FR:pixel_num_y = 128	// == pixels in vertical direction 
	Make/O/D/N=1 :entry:instrument:detector_FT:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_FT:pixel_num_y = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_FB:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_FB:pixel_num_y = 48	// == number of tubes

//	Variable/G gFront_L_nPix_X = 48		// == number of tubes
//	Variable/G gFront_L_nPix_Y = 128		// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
//	Variable/G gFront_R_nPix_X = 48		// == number of tubes
//	Variable/G gFront_R_nPix_Y = 128		// == pixels in vertical direction 
//	Variable/G gFront_T_nPix_X = 128		// == pixels in horizontal direction
//	Variable/G gFront_T_nPix_Y = 48		// == number of tubes
//	Variable/G gFront_B_nPix_X = 128		// == pixels in horizontal direction
//	Variable/G gFront_B_nPix_Y = 48		// == number of tubes

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
	Variable/G gMiddle_LR_w = 384		//middle bank, nominal LR panel width (mm)
	Variable/G gMiddle_LR_h = 1000
	Variable/G gMiddle_TB_w = 500
	Variable/G gMiddle_TB_h = 384
// SDD offset of T/B (decide on units??)
// for the Nexus file, the detector distance should already be corrected for the "setback"
// of the T/B panels. keep as VCALC variable
	Variable/G gMiddle_SDDOffset = 300			// (mm)
	
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

//	Variable/G gMiddle_L_pixelX = 0.84		// (cm)		these tubes are vertical
//	Variable/G gMiddle_L_pixelY = 0.8		// (cm)
//	Variable/G gMiddle_R_pixelX = 0.84		// (cm)
//	Variable/G gMiddle_R_pixelY = 0.8		// (cm)
//	
//	Variable/G gMiddle_T_pixelX = 0.4			// (cm)		these tubes are horizontal
//	Variable/G gMiddle_T_pixelY = 0.84			// (cm)
//	Variable/G gMiddle_B_pixelX = 0.4			// (cm)
//	Variable/G gMiddle_B_pixelY = 0.84		// (cm)

// number of pixels in each bank (this can be modified at acquisition time, so it must be adjustable here)
	Make/O/D/N=1 :entry:instrument:detector_ML:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_ML:pixel_num_y = 128	// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
	Make/O/D/N=1 :entry:instrument:detector_MR:pixel_num_x = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_MR:pixel_num_y = 128	// == pixels in vertical direction 
	Make/O/D/N=1 :entry:instrument:detector_MT:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_MT:pixel_num_y = 48	// == number of tubes
	Make/O/D/N=1 :entry:instrument:detector_MB:pixel_num_x = 128	// == pixels in horizontal direction
	Make/O/D/N=1 :entry:instrument:detector_MB:pixel_num_y = 48	// == number of tubes
	
//	Variable/G gMiddle_L_nPix_X = 48		// == number of tubes
//	Variable/G gMiddle_L_nPix_Y = 128		// == pixels in vertical direction (was 256, John says likely will run @ 128 9/2015)
//	Variable/G gMiddle_R_nPix_X = 48		// == number of tubes
//	Variable/G gMiddle_R_nPix_Y = 128		// == pixels in vertical direction 
//	Variable/G gMiddle_T_nPix_X = 128		// == pixels in horizontal direction
//	Variable/G gMiddle_T_nPix_Y = 48		// == number of tubes
//	Variable/G gMiddle_B_nPix_X = 128		// == pixels in horizontal direction
//	Variable/G gMiddle_B_nPix_Y = 48		// == number of tubes

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
	Variable/G gBack_w = 150				//w and h for the back detector, (mm) 150 pix * 1mm/pix
	Variable/G gBack_h = 150
	
	Make/O/D/N=1 :entry:instrument:detector_B:x_pixel_size = 0.1		// 1 mm resolution (units of cm here)
	Make/O/D/N=1 :entry:instrument:detector_B:y_pixel_size = 0.1		
//	Variable/G gBack_pixelX = 0.1		
//	Variable/G gBack_pixelY = 0.1

	Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_x = 150	// detector pixels in x-direction
	Make/O/D/N=1 :entry:instrument:detector_B:pixel_num_y = 150
//	Variable/G gBack_nPix_X = 150		
//	Variable/G gBack_nPix_Y = 150	

// pixel beam center - HDF style
	Make/O/D/N=1 :entry:instrument:detector_B:beam_center_x = 75		// == x beam center, in pixels
	Make/O/D/N=1 :entry:instrument:detector_B:beam_center_y = 75		// == y beam center, in pixels


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
	String/G gPresetPopStr = "Low Q;High Q;Converging Pinholes;Narrow Slit Aperture;White Beam;Polarizer;"
	String/G gBinTypeStr = "One;Two;Four;Slit Mode;"




// popup strings for each tab (then use the string in the panel)
// tab 0 - collimation
	String/G gMonochromatorType = "Velocity Selector;Graphite;White Beam;"
	String/G gSourceShape = "circular;rectangular;converging pinholes;"
	String/G gSourceDiam = "1.0 cm;2.0 cm;5.0 cm;"
	String/G gDeltaLambda = "0.10;0.20;0.30;"
	
// tab 1 - sample conditions
	String/G gTableLocation = "Changer;Stage;"
	String/G gSampleApertureShape = "circular;rectangular;converging pinholes;"
	String/G gSampleApertureDiam = "0.5;1.0;1.5;2.0;"
	
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

	Variable/G gNg=0
//	Variable/G gOffset=0
	Variable/G gSamAp=1.27		//samAp diameter in cm
	String/G gSourceApString = "1.43 cm;2.54 cm;3.81 cm;"
	String/G gApPopStr = "1/16\";1/8\";3/16\";1/4\";5/16\";3/8\";7/16\";1/2\";9/16\";5/8\";11/16\";3/4\";other;"
	Variable/G gSamApOther = 10		//non-standard aperture diameter, in mm
	Variable/G gUsingLenses = 0		//0=no lenses, 1=lenses(or prisms)
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
	Variable/G gInstrument = 6		// files (may) be tagged SA6 as the 6th SANS instrument
	Variable/G gS12 = 54.8
//	Variable/G d_det = 0.5
//	Variable/G a_pixel = 0.5
//	Variable/G del_r = 0.5
//	Variable/G det_width = 64.0
	Variable/G gLambda_t = 5.50
	Variable/G gL2r_lower = 132.3
	Variable/G gL2r_upper =  1317
	Variable/G gLambda_lower = 2.5
	Variable/G gLambda_upper = 20.0
	Variable/G gD_upper = 25.0
	Variable/G gBs_factor = 1.05
	Variable/G gT1 = 0.63
	Variable/G gT2 = 1.0
	Variable/G gT3 = 0.75
	Variable/G gL_gap = 100.0
	Variable/G gGuide_width = 6.0
	Variable/G gIdmax = 100.0

//
//	//new values, from 11/2009 --- BeamFluxReport_2009.ifn
	Variable/G gPhi_0 = 2.42e13
	Variable/G gB = 0.0
	Variable/G gC = -0.0243
	Variable/G gGuide_loss = 0.924
//	
//	//fwhm values (new variables) (+3, 0, -3, calibrated 2009)
	Variable/G gFwhm_narrow = 0.109
	Variable/G gFwhm_mid = 0.125
	Variable/G gFwhm_wide = 0.236
//	
//	//source apertures (cm)
	Variable/G gA1_0_0 = 1.43
	Variable/G gA1_0_1 = 2.54
	Variable/G gA1_0_2 = 3.81
	Variable/G gA1_7_0 = 2.5			// after the polarizer		
	Variable/G gA1_7_1 = 5.0
	Variable/G gA1_7_1 = 0.95		//
	Variable/G gA1_def = 5.00
//	
	SetDataFolder root:
end
