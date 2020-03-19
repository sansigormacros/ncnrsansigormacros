#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


/// 
// x- update all to be only VSANS-specific
// x- update all of the function names to be unique to VSANS so that there are no
//    name clashes with the "duplicate" version that is in PlotUtils.ipf
//
// x- Make this a VSANS-only panel
// x- eliminate the USANS tab
// x- be sure the general tab is either unique, or eliminate it
// x- be sure the Analysis tab is unique, or eliminate it
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
		// these variables were recently created, so they may not exist if someone
		// opens an old experiment -- then errors will result
		if(exists("root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor") != 2)
			V_InitializeWindowTrans()		//set up the globals (need to check in multiple places)
		endif
		
		VSANSPref_Panel()
	Endif
//	Print "Preferences Panel stub"
End


//  x- there are more detector specific corrections here that need to be added
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

	// flag to set "Laptop Mode" where the panels are drawn smaller and onscreen
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gLaptopMode", 0 )
	Variable/G root:Packages:NIST:VSANS:Globals:gLaptopMode = val	
	
	// VSANS tab
	///// items for VSANS reduction
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault=val
	
//	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gAllowDRK", 0 )
//	Variable/G root:Packages:NIST:VSANS:Globals:gAllowDRK=val			//don't show DRK as default
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoTransCheck", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoTransCheck=val
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gBinWidth", 1.2 )
	Variable/G root:Packages:NIST:VSANS:Globals:gBinWidth=val
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gNPhiSteps", 90 )
	Variable/G root:Packages:NIST:VSANS:Globals:gNPhiSteps=val
	
	// flags to turn detector corrections on/off for testing (you should leave these ON)
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoDetectorEffCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoDetectorEffCor = 1
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoTransmissionCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoTransmissionCor = 1

	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoDIVCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoDIVCor = 1
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor = 1

	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor = 1

	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoNonLinearCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoNonLinearCor = 1

	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor = 1
	
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization = 1

	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor = 1
	V_InitializeWindowTrans()		//set up the globals (need to check in multiple places)

	// Special global to prevent fake data from "B" detector from being written out
	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gIgnoreDetB", 1 )
	Variable/G root:Packages:NIST:VSANS:Globals:gIgnoreDetB = 1

// TODOHIGHRES
// OCT 2018
// new global to flag the highRes detector binning to accomodate the change in binning
//  that was set 10/16/18 (changed from 4x4 bin to 1x1= no binning)
// set this flag == 1 for 1x1
// set flag 4 == 4x4
	Variable/G root:Packages:NIST:VSANS:Globals:gHighResBinning = 4
			
	DoAlert 1,"Are you using the back detector? (This can be changed later in the Preferences Panel)"
	if(V_flag == 1)
		// yes
		Variable/G root:Packages:NIST:VSANS:Globals:gIgnoreDetB = 0
//		DoAlert 1,"Are you using 1x1 binning?"
//		if(V_flag == 1)
//			// yes
//			Variable/G root:Packages:NIST:VSANS:Globals:gHighResBinning = 1
//		endif
	endif


	DoAlert 1,"Do you want small panels? (this can be changed later in preferences)"
	if(V_flag == 1)
		// yes
		Variable/G root:Packages:NIST:VSANS:Globals:gLaptopMode = 1
	endif
// flag to allow adding raw data files with different attenuation (normally not done)	
//	val = NumVarOrDefault("root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten",0)
//	Variable/G root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten=val
	
	
	// VSANS ANALYSIS tab
	/// items for VSANS Analysis
	

	
	
end

Function V_InitializeWindowTrans()

	Variable/G root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor = 1

	// TODO -- when correcting this, search for all occurences!!! also in V_WorkFolderUtils !!!
	// these global values need to be replaced with real numbers
	// error is currently set to zero
	Variable/G root:Packages:NIST:VSANS:Globals:gDownstreamWinTrans = 1
	Variable/G root:Packages:NIST:VSANS:Globals:gDownstreamWinTransErr = 0

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
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoTransmissionCor
	gVal = checked
End

// this is efficiency + shadowing
Function V_DoEfficiencyCorrPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor
	gVal = checked
End

Function V_DoRawAttenAdjPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten
	gVal = checked
End

Function V_DoDIVCorPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	gVal = checked
End

Function V_DoDeadTimeCorPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor
	gVal = checked
End

Function V_DoSolidAngleCorPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
	gVal = checked
End

Function V_DoNonLinearCorPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
	gVal = checked
End

// not needed-- efficiency and shadowing are done together
//Function V_DoTubeShadowCorPref(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//	
//	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor
//	gVal = checked
//End

Function V_DoMonitorNormPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization
	gVal = checked
End

Function V_DoDownstreamWindowCorPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor
	gVal = checked
End


Function V_IgnoreDetBPref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	gVal = checked
End

Function V_LaptopModePref(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR gVal = root:Packages:NIST:VSANS:Globals:gLaptopMode
	gVal = checked
End




Function V_PrefDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K VSANSPref_Panel
End


Proc VSANSPref_Panel()
	Variable sc=1
	
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(646*sc,208*sc,1070*sc,468*sc)/K=2 as "VSANS Preference Panel"
	DoWindow/C VSANSPref_Panel
	ModifyPanel cbRGB=(47748,57192,54093)
	SetDrawLayer UserBack
	ModifyPanel fixedSize=1
//////
//on main portion of panel, always visible
	Button PrefPanelButtonA,pos={354*sc,12*sc},size={50*sc,20*sc},proc=V_PrefDoneButtonProc,title="Done"

	TabControl PrefTab,pos={7*sc,49*sc},size={410*sc,202*sc},tabLabel(0)="General",proc=V_PrefTabProc
	TabControl PrefTab,tabLabel(1)="VSANS",tabLabel(2)="Analysis"
	TabControl PrefTab,value=1
	TabControl PrefTab labelBack=(47748,57192,54093)
	
//on tab(0) - General
	CheckBox PrefCtrl_0a,pos={21*sc,96*sc},size={124*sc,14*sc},proc=V_XMLWritePref,title="Use canSAS XML Output"
	CheckBox PrefCtrl_0a,help={"Checking this will set the default output format to be canSAS XML rather than NIST 6 column"}
	CheckBox PrefCtrl_0a,value= root:Packages:NIST:VSANS:Globals:gXML_Write
	CheckBox PrefCtrl_0b,pos={21*sc,120*sc},size={124*sc,14*sc},proc=V_LaptopModePref,title="Laptop Mode for Panels"
	CheckBox PrefCtrl_0b,help={"Checking this will draw panels smaller to fit on a 1920x1080 laptop screen"}
	CheckBox PrefCtrl_0b,value= root:Packages:NIST:VSANS:Globals:gLaptopMode

	CheckBox PrefCtrl_0a,disable=1
	CheckBox PrefCtrl_0b,disable=1


//on tab(1) - VSANS - initially visible
	CheckBox PrefCtrl_1a,pos={21*sc,80*sc},size={171*sc,14*sc},proc=V_LogScalePrefCheck,title="Use Log scaling for 2D data display"
	CheckBox PrefCtrl_1a,help={"Checking this will display 2D VSANS data with a logarithmic color scale of neutron counts. If not checked, the color mapping will be linear."}
	CheckBox PrefCtrl_1a,value= root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault
//	CheckBox PrefCtrl_1b,pos={21,120},size={163,14},proc=V_DRKProtocolPref,title="Allow DRK correction in protocols"
//	CheckBox PrefCtrl_1b,help={"Checking this will allow DRK correction to be used in reduction protocols. You will need to re-draw the protocol panel for this change to be visible."}
//	CheckBox PrefCtrl_1b,value= root:Packages:NIST:VSANS:Globals:gAllowDRK
	CheckBox PrefCtrl_1c,pos={21*sc,100*sc},size={137*sc,14*sc},proc=V_UnityTransPref,title="Check for Transmission = 1"
	CheckBox PrefCtrl_1c,help={"Checking this will check for SAM or EMP Trans = 1 during data correction"}
	CheckBox PrefCtrl_1c,value= root:Packages:NIST:VSANS:Globals:gDoTransCheck
	SetVariable PrefCtrl_1d,pos={21*sc,130*sc},size={200*sc,15*sc},title="Averaging Bin Width (pixels)"
	SetVariable PrefCtrl_1d,limits={1,100,1},value= root:Packages:NIST:VSANS:Globals:gBinWidth
	SetVariable PrefCtrl_1e,pos={21*sc,155*sc},size={200*sc,15*sc},title="# Phi Steps (annular avg)"
	SetVariable PrefCtrl_1e,limits={1,360,1},value= root:Packages:NIST:VSANS:Globals:gNPhiSteps
	SetVariable PrefCtrl_1p,pos={21*sc,180*sc},size={200*sc,15*sc},title="Window Transmission"
	SetVariable PrefCtrl_1p,limits={0.01,1,0.001},value= root:Packages:NIST:VSANS:Globals:gDownstreamWinTrans

	
	CheckBox PrefCtrl_1f title="Do Transmssion Correction?",size={140*sc,14*sc},value=root:Packages:NIST:VSANS:Globals:gDoTransmissionCor,proc=V_DoTransCorrPref
	CheckBox PrefCtrl_1f pos={255*sc,80*sc},help={"TURN OFF ONLY FOR DEBUGGING. This corrects the data for angle dependent transmssion."}
	CheckBox PrefCtrl_1g title="Do Tube Efficiency+Shadowing?",size={140*sc,14*sc},proc=V_DoEfficiencyCorrPref
	CheckBox PrefCtrl_1g value=root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor,pos={255*sc,100*sc},help={"TURN OFF ONLY FOR DEBUGGING. This corrects the data for angle dependent detector efficiency."}
//	CheckBox PrefCtrl_1h title="Adjust RAW attenuation?",size={140,14},proc=V_DoRawAttenAdjPref
//	CheckBox PrefCtrl_1h value=root:Packages:NIST:VSANS:Globals:gDoAdjustRAW_Atten,pos={255,140},help={"This is normally not done"}

	CheckBox PrefCtrl_1i title="Do DIV Correction?",size={140*sc,14*sc},proc=V_DoDIVCorPref
	CheckBox PrefCtrl_1i value=root:Packages:NIST:VSANS:Globals:gDoDIVCor,pos={255*sc,120*sc},help={"TURN OFF ONLY FOR DEBUGGING."}
	CheckBox PrefCtrl_1j title="Do DeadTime Correction?",size={140*sc,14*sc},proc=V_DoDeadTimeCorPref
	CheckBox PrefCtrl_1j value=root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor,pos={255*sc,140*sc},help={"TURN OFF ONLY FOR DEBUGGING."}	
	CheckBox PrefCtrl_1k title="Do Solid Angle Correction?",size={140*sc,14*sc},proc=V_DoSolidAngleCorPref
	CheckBox PrefCtrl_1k value=root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor,pos={255*sc,160*sc},help={"TURN OFF ONLY FOR DEBUGGING."}
	CheckBox PrefCtrl_1l title="Do Non-linear Correction?",size={140*sc,14*sc},proc=V_DoNonLinearCorPref,disable=2
	CheckBox PrefCtrl_1l value=root:Packages:NIST:VSANS:Globals:gDoNonLinearCor,pos={255*sc,180*sc},help={"Non-linear correction can't be turned off"}
	CheckBox PrefCtrl_1m title="Do Downstream Window Corr?",size={140*sc,14*sc},proc=V_DoDownstreamWindowCorPref
	CheckBox PrefCtrl_1m value=root:Packages:NIST:VSANS:Globals:gDoDownstreamWindowCor,pos={255*sc,200*sc},help={"TURN OFF ONLY FOR DEBUGGING."}
//	CheckBox PrefCtrl_1n title="Do Monitor Normalization?",size={140,14},proc=V_DoMonitorNormPref
//	CheckBox PrefCtrl_1n value=root:Packages:NIST:VSANS:Globals:gDoMonitorNormalization,pos={255,220},help={"TURN OFF ONLY FOR DEBUGGING."}
	CheckBox PrefCtrl_1o title="Ignore Back Detector?",size={140*sc,14*sc},proc=V_IgnoreDetBPref
	CheckBox PrefCtrl_1o value=root:Packages:NIST:VSANS:Globals:gIgnoreDetB,pos={150*sc,220*sc},help={"Will prevent data from Back detector being written to data files."}		
	
//	CheckBox PrefCtrl_1a,disable=1
//	CheckBox PrefCtrl_1b,disable=1
//	CheckBox PrefCtrl_1c,disable=1
//	SetVariable PrefCtrl_1d,disable=1
//	SetVariable PrefCtrl_1e,disable=1
//	CheckBox PrefCtrl_1f,disable=1
//	CheckBox PrefCtrl_1g,disable=1
//	CheckBox PrefCtrl_1h,disable=1
//	CheckBox PrefCtrl_1g,value=0,disable=2		// angle dependent efficiency not done yet
//	CheckBox PrefCtrl_1m,value=0,disable=2		// downstream window transmission no done yet

//on tab(2) - Analysis
	GroupBox PrefCtrl_2a pos={21*sc,100*sc},size={1,1},title="nothing to set",fSize=12
	
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
