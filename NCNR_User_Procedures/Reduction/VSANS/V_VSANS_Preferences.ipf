#pragma rtGlobals=3		// Use modern global access method and strict wave access.


/// TODO
// -- update all to be only VSANS-specific
// -- update all of the function names to be unique to VSANS so that there are no
//    name clashes with the "duplicate" version that is in PlotUtils.ipf
//
// -- Make this a VSANS-only panel
// -- eliminate the USANS tab
// -- be sure the general tab is either unique, or eliminate it
// -- be sure the Analysis tab is unique, or eliminate it
//
//
// global variables used by VSANS are stored in:
// root:Packages:NIST:VSANS:Globals
//


///////////////////////////
Proc Show_VSANSPreferences_Panel()

	DoWindow/F VSANSPref_Panel
	if(V_flag==0)
		// only re-initialize if the variables don't exist, so you don't overwrite what users have changed
		if( exists("root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault") != 2 )		//if the global variable does not exist, initialize
			Initialize_VSANSPreferences()
		endif
		VSANSPref_Panel()
	Endif
//	Print "Preferences Panel stub"
End


// TODO -- there are more detector specific corrections here that need to be added
//
// create the globals here if they are not already present
// each package initialization should call this to repeat the initialization
// without overwriting what was already set
Proc Initialize_VSANSPreferences()
	
	Variable val

	// GENERAL tab
	/// General items for everyone
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gXML_Write", 0 )
	Variable/G root:Packages:NIST:VSANS:Globals:gXML_Write = val
	
	
	// VSANS tab
	///// items for VSANS reduction
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault=val
	
//	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gAllowDRK", 0 )
//	Variable/G root:Packages:NIST:VSANS:Globals:gAllowDRK=val			//don't show DRK as default
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoTransCheck", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoTransCheck=val
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gBinWidth", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gBinWidth=val
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gNPhiSteps", 72 )
	Variable/G root:Packages:NIST:VSANS:Globals:gNPhiSteps=val
	
	// flags to turn detector corrections on/off for testing (you should leave these ON)
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoDetectorEffCorr", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoDetectorEffCorr = 1
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoTransmissionCorr", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoTransmissionCorr = 1

// flag to allow adding raw data files with different attenuation (normally not done)	
//	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten",0)
//	Variable/G root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten=val
	
	
	// VSANS ANALYSIS tab
	/// items for VSANS Analysis
	
	
end

Function V_LogScalePrefCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gLog = root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault
	glog=checked
	//print "log pref checked = ",checked
End

//Function DRKProtocolPref(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//	
//	NVAR gDRK = root:Packages:NIST:VSANS:Globals:gAllowDRK
//	gDRK = checked
//	//Print "DRK preference = ",checked
//End

Function V_UnityTransPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoTransCheck
	gVal = checked
End

Function V_XMLWritePref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gXML_Write
	gVal = checked
End

Function V_DoTransCorrPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoTransmissionCorr
	gVal = checked
End

Function V_DoEfficiencyCorrPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoDetectorEffCorr
	gVal = checked
End

Function V_DoRawAttenAdjPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten
	gVal = checked
End

Function V_PrefDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K VSANSPref_Panel
End

Proc VSANSPref_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(646,208,1070,468)/K=2 as "VSANS Preference Panel"
	DoWindow/C VSANSPref_Panel
	ModifyPanel cbRGB=(49694,61514,27679)
	SetDrawLayer UserBack
	ModifyPanel fixedSize=1
//////
//on main portion of panel, always visible
	Button PrefPanelButtonA,pos={354,12},size={50,20},proc=V_PrefDoneButtonProc,title="Done"

	TabControl PrefTab,pos={7,49},size={410,202},tabLabel(0)="General",proc=V_PrefTabProc
	TabControl PrefTab,tabLabel(1)="VSANS",tabLabel(2)="Analysis"
	TabControl PrefTab,value=1
	TabControl PrefTab labelBack=(49694,61514,27679)
	
//on tab(0) - General
	CheckBox PrefCtrl_0a,pos={21,96},size={124,14},proc=V_XMLWritePref,title="Use canSAS XML Output"
	CheckBox PrefCtrl_0a,help={"Checking this will set the default output format to be canSAS XML rather than NIST 6 column"}
	CheckBox PrefCtrl_0a,value= root:Packages:NIST:VSANS:Globals:gXML_Write

	CheckBox PrefCtrl_0a,disable=1


//on tab(1) - VSANS - initially visible
	CheckBox PrefCtrl_1a,pos={21,100},size={171,14},proc=V_LogScalePrefCheck,title="Use Log scaling for 2D data display"
	CheckBox PrefCtrl_1a,help={"Checking this will display 2D VSANS data with a logarithmic color scale of neutron counts. If not checked, the color mapping will be linear."}
	CheckBox PrefCtrl_1a,value= root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault
//	CheckBox PrefCtrl_1b,pos={21,120},size={163,14},proc=V_DRKProtocolPref,title="Allow DRK correction in protocols"
//	CheckBox PrefCtrl_1b,help={"Checking this will allow DRK correction to be used in reduction protocols. You will need to re-draw the protocol panel for this change to be visible."}
//	CheckBox PrefCtrl_1b,value= root:Packages:NIST:VSANS:Globals:gAllowDRK
	CheckBox PrefCtrl_1c,pos={21,140},size={137,14},proc=V_UnityTransPref,title="Check for Transmission = 1"
	CheckBox PrefCtrl_1c,help={"Checking this will check for SAM or EMP Trans = 1 during data correction"}
	CheckBox PrefCtrl_1c,value= root:Packages:NIST:VSANS:Globals:gDoTransCheck
	SetVariable PrefCtrl_1d,pos={21,170},size={200,15},title="Averaging Bin Width (pixels)"
	SetVariable PrefCtrl_1d,limits={1,100,1},value= root:Packages:NIST:VSANS:Globals:gBinWidth
	SetVariable PrefCtrl_1e,pos={21,195},size={200,15},title="# Phi Steps (annular avg)"
	SetVariable PrefCtrl_1e,limits={1,360,1},value= root:Packages:NIST:VSANS:Globals:gNPhiSteps
	CheckBox PrefCtrl_1f title="Do Transmssion Correction?",size={140,14},value=root:Packages:NIST:VSANS:Globals:gDoTransmissionCorr,proc=V_DoTransCorrPref
	CheckBox PrefCtrl_1f pos={255,100},help={"TURN OFF ONLY FOR DEBUGGING. This corrects the data for angle dependent transmssion."}
	CheckBox PrefCtrl_1g title="Do Efficiency Correction?",size={140,14},proc=V_DoEfficiencyCorrPref
	CheckBox PrefCtrl_1g value=root:Packages:NIST:VSANS:Globals:gDoDetectorEffCorr,pos={255,120},help={"TURN OFF ONLY FOR DEBUGGING. This corrects the data for angle dependent detector efficiency."}
	CheckBox PrefCtrl_1h title="Adjust RAW attenuation?",size={140,14},proc=V_DoRawAttenAdjPref
	CheckBox PrefCtrl_1h value=root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten,pos={255,140},help={"This is normally not done"}

//	CheckBox PrefCtrl_1a,disable=1
//	CheckBox PrefCtrl_1b,disable=1
//	CheckBox PrefCtrl_1c,disable=1
//	SetVariable PrefCtrl_1d,disable=1
//	SetVariable PrefCtrl_1e,disable=1
//	CheckBox PrefCtrl_1f,disable=1
//	CheckBox PrefCtrl_1g,disable=1
//	CheckBox PrefCtrl_1h,disable=1

//on tab(2) - Analysis
	GroupBox PrefCtrl_2a pos={21,100},size={1,1},title="nothing to set",fSize=12
	
	GroupBox PrefCtrl_2a,disable=1

End

// function to control the drawing of controls in the TabControl on the main panel
// Naming scheme for the controls MUST be strictly adhered to... else controls will 
// appear in odd places...
// all controls are named PrefCtrl_NA where N is the tab number and A is the letter denoting
// the controls position on that particular tab.
// in this way, they will always be drawn correctly..
//
Function V_PrefTabProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"PrefCtrl_", 9 characters
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,8]
		if(cmpstr(nameStr,"PrefCtrl_")==0)
			onTab = str2num(item[9])			//[9] is a number
			ControlInfo $item
			switch(abs(V_flag))	
				case 1:
					Button $item,disable=(tab!=onTab)
					break
				case 2:	
					CheckBox $item,disable=(tab!=onTab)
					break
				case 5:	
					SetVariable $item,disable=(tab!=onTab)
					break
				case 10:	
					TitleBox $item,disable=(tab!=onTab)
					break
				case 4:
					ValDisplay $item,disable=(tab!=onTab)
					break
				case 9:
					GroupBox $item,disable=(tab!=onTab)
					break
				// add more items to the switch if different control types are used
			endswitch
		endif
	endfor 
	return(0)
End
