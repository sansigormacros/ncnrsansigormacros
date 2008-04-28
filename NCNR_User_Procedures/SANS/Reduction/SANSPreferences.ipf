#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0


///////////////////////////
// user preferences
// 
// globals are created in initialize.ipf
//
// this panel allows for user modification
///////////////////////////
Proc Show_Preferences_Panel()

	DoWindow/F Pref_Panel
	if(V_flag==0)
		Init_Pref()
		Pref_Panel()
	Endif
//	Print "Preferences Panel stub"
End

Proc init_pref()
	// all creation of global values for the pref panel
	// should be done in the experiment initialization
	// since all these globals will be in active use
	// even if the preferences are never actively set
end

Function LogScalePrefCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gLog = root:myGlobals:gLogScalingAsDefault
	glog=checked
	//print "log pref checked = ",checked
End

Function DRKProtocolPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gDRK = root:myGlobals:gAllowDRK
	gDRK = checked
	//Print "DRK preference = ",checked
End

Function UnityTransPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:myGlobals:gDoTransCheck
	gVal = checked
End

Function PrefDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K pref_panel
End

// draws the panel
// each checkbox should actively change a global value
Proc Pref_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=2 /W=(607,158,899,360) as "SANS Preference Panel"
	DoWindow/C pref_panel
	ModifyPanel cbRGB=(49694,61514,27679)
	CheckBox check0,pos={10,10},size={186,14},proc=LogScalePrefCheck,title="Use Log scaling for 2D data display"
	CheckBox check0,help={"Checking this will display 2D SANS data with a logarithmic color scale of neutron counts. If not checked, the color mapping will be linear."}
	CheckBox check0,value= root:myGlobals:gLogScalingAsDefault
	CheckBox check1,pos={10,30},size={184,14},proc=DRKProtocolPref,title="Allow DRK correction in protocols"
	CheckBox check1,help={"Checking this will allow DRK correction to be used in reduction protocols. You will need to re-draw the protocol panel for this change to be visible."}
	CheckBox check1,value= root:myGlobals:gAllowDRK
	CheckBox check2,pos={10,50},size={184,14},proc=UnityTransPref,title="Check for Transmission = 1"
	CheckBox check2,help={"Checking this will check for SAM or EMP Trans = 1 during data correction"}
	CheckBox check2,value= root:myGlobals:gDoTransCheck
	Button button0,pos={226,168},size={50,20},proc=PrefDoneButtonProc,title="Done"
	SetVariable setvar0,pos={10,80},size={200,15},title="Averaging Bin Width (pixels)"
	SetVariable setvar0,limits={1,100,1},value= root:myGlobals:gBinWidth
	SetVariable setvar1,pos={10,105},size={200,15},title="# Phi Steps (annular avg)"
	SetVariable setvar1,limits={1,360,1},value= root:myGlobals:gNPhiSteps
	//keep these hidden for now so that nobody can accidentally change them from
	//the default values set in Initialize.ipf (128x128)
//	SetVariable setvar2,pos={10,125},size={200,15},title="Detector Pixels (X)"
//	SetVariable setvar2,limits={1,2000,1},value= root:myGlobals:gNPixelsX
//	SetVariable setvar3,pos={10,145},size={200,15},title="Detector Pixels (Y)"
//	SetVariable setvar3,limits={1,2000,1},value= root:myGlobals:gNPixelsY

End

