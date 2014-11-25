#pragma rtGlobals=3		// Use modern global access method and strict wave access.


////////////////////////////////
//
// SRK NOV 2014
//
// A panel to make it easy to set up "runs" for simulation
//
//
//
//
//
// TO DO:
//		x- Move everything to a proper data folder so that everything is saved in its proper place
//    	x- configurations, samples, and listBox waves.
//
//
//		use Sim_ as a prefix for the functions rather than MC_
//
//		root:Packages:NIST:RunSim
//
//
// -- add buttons for:
//		x- Run the checked runs from the list (non-consecutive OK)
//		x- Save the run list + later restore
//		x- save the configurations to disk + restore
//		x- save the samples to disk + restore (but the model must be loaded too when these are restored)
//
///////////////////////////////

Proc ShowRunListPanel()
	DoWindow/F RunListPanel
	if(V_flag==0)
		Initialize_RLP()
		RunListPanel()
	endif
End


//
//
Function Initialize_RLP()
	
	Variable row,col
	row=50
	col=8

	NewDataFolder/O/S root:Packages:NIST:RunSim
	
	Variable/G gRunIndex = 100
	
	Make/O/T/N=(row,col) textW
	Make/O/B/N=(row,col) selW=0
	
	//set the column Labels
	Variable ii
	Make/O/T/N=(col) names
	names[0,4] = {"Run","Config","Sample","Sample Label","Count Time"}
	names[5,7] = {"Save Name","Abs ?","Noise ?"}
	for(ii=0;ii<col;ii+=1)
		SetDimLabel 1,ii,$names[ii],textW
	endfor
	
	//make all cells editable
	selW = (0x02)
	// make the first column a checkbox, not editable
	selW[][0] = (0x20)
	textW[][0] = num2Str(p)
	
	SetDataFolder root:
	
	return(0)
end


//
// Always visible:
//  -- run list
//  -- "Run" button
//
// Tabs:
// - setup samples (+ save)
// - setup configurations  (+save)
// - setup run list (+ add + save + modify)
//
//
Proc RunListPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(517,291,1210,852)  /K=1
	ModifyPanel cbRGB=(40941,58697,43183)
	DoWindow/C RunListPanel
	
//
	TabControl RunListTab,pos={10,10},size={660,230},tabLabel(0)="Configurations",proc=RunListTabProc
	TabControl RunListTab,tabLabel(1)="Setup Samples",tabLabel(2)="Setup Runs"//,tabLabel(3)="2-D Ops",tabLabel(4)="Misc Ops"
	TabControl RunListTab,value=0
	TabControl RunListTab labelBack=(65535,58981,27524)
	
// always visible
// clickEventModifiers=8  = ignore the shift key in the list box (I'm using that bit (3) of selWave to flag trans)
	ListBox RLCtrlA,pos={17,290},size={660,250},proc=MyListboxProc,frame=2,clickEventModifiers=8
	ListBox RLCtrlA,listWave=root:Packages:NIST:RunSim:textW,selWave=root:Packages:NIST:RunSim:selW//,colorWave=root:Packages:NIST:RunSim:myColors
	ListBox RLCtrlA,row= 0,mode= 2,editStyle= 2,widths= {40,70,120,120,50,120,30,30}

	Button RLCtrlB,pos={20,255},size={140,20},proc=Sim_RunSelected1DButton,title="Run Selected 1D"
	Button RLCtrlC,pos={180,255},size={140,20},proc=Sim_RunSelected2DButton,title="Run Selected 2D"
	Button RLCtrlD,pos={340,255},size={140,20},proc=Sim_RunSelectedDryButton,title="Dry Run 2D"

	SetVariable RLCtrlE,pos={500,255},size={100,20},title="Run Index"
	SetVariable RLCtrlE,limits={0,900,1},value= root:Packages:NIST:RunSim:gRunIndex

	Button RLCtrlF,pos={650,6},size={20,20},proc=Sim_RLHelpButtonProc,title="?"


// tab 0
// for saving configurations	
	Button RLCtrl_0a,pos={25,60},size={100,20},proc=Sim_StoreConfigButton,title="Store Config"
	PopupMenu RLCtrl_0b,pos={25,100},size={107,20},proc=Sim_RecallConfigPopMenu,title="Recall Config"
	PopupMenu RLCtrl_0b,mode=1,value= ListSASCALCConfigs()
	Button RLCtrl_0c,pos={270,60},size={120,20},proc=Sim_SaveConfigButton,title="Save Configs"
	Button RLCtrl_0d,pos={270,90},size={120,20},proc=Sim_RestoreConfigButton,title="Restore Configs"
	Button RLCtrl_0e,pos={270,120},size={120,20},proc=Sim_ClearConfigButton,title="Clear All Configs"

// tab 1
// for saving sample conditions

///////////// don't relabel control 1j
	SetVariable RLCtrl_1j,pos={25,40},size={300,15},title="Sample Label"
	SetVariable RLCtrl_1j,limits={-inf,inf,0},value= _STR:"Enter Sample Label",disable=1
	
	Button RLCtrl_1a,pos={25,180},size={100,20},proc=Sim_StoreSampleButton,title="Store Sample",disable=1
	
	PopupMenu RLCtrl_1b,pos={25,210},size={111,20},proc=Sim_RecallSamplePopMenu,title="Recall Sample"
	PopupMenu RLCtrl_1b,mode=1,value= ListSimSamples(),disable=1
	
	SetVariable RLCtrl_1c,pos={25,65},size={160,15},title="Thickness (cm)"
	SetVariable RLCtrl_1c,limits={0,inf,0.1},value= root:Packages:NIST:SAS:gThick
	SetVariable RLCtrl_1c, proc=Sim_1D_SamThickSetVarProc,disable=1

	SetVariable RLCtrl_1d,pos={25,90},size={160,15},title="Sample Transmission"
	SetVariable RLCtrl_1d,limits={0,1,0.01},value= root:Packages:NIST:SAS:gSamTrans
	SetVariable RLCtrl_1d, proc=Sim_1D_SamTransSetVarProc,disable=1

	SetVariable RLCtrl_1e,pos={25,115},size={160,15},title="Incoherent XS (1/cm)"
	SetVariable RLCtrl_1e,limits={0,10,0.001},value= root:Packages:NIST:SAS:gSig_incoh
	SetVariable RLCtrl_1e,disable=1
	
	SetVariable RLCtrl_1f,pos={25,140},size={160,15},title="Sample Radius (cm)"
	SetVariable RLCtrl_1f,limits={0,10,0.001},value= root:Packages:NIST:SAS:gR2
	SetVariable RLCtrl_1f,disable=1
	
	Button RLCtrl_1g,pos={270,90},size={120,20},proc=Sim_SaveSampleButton,title="Save Samples",disable=1
	Button RLCtrl_1h,pos={270,120},size={120,20},proc=Sim_RestoreSampleButton,title="Restore Samples",disable=1
	Button RLCtrl_1i,pos={270,150},size={120,20},proc=Sim_ClearSampleButton,title="Clear All Samples",disable=1
			
	
// tab 2
// for setting up of the run list
// RLCtrl_2
	PopupMenu RLCtrl_2a,pos={26,40},size={161,20},title="Configuration"
	PopupMenu RLCtrl_2a,mode=2,popvalue="Config_",proc=Sim_RecallConfigPopMenu,value= #"ListSASCALCConfigs()",disable=1
	
	PopupMenu RLCtrl_2b,pos={26,70},size={161,20},title="Sample"
	PopupMenu RLCtrl_2b,mode=2,popvalue="Sam_",proc=Sim_RecallSamplePopMenu,value= #"ListSimSamples()",disable=1

///////// don't relabel control 2c	
	SetVariable RLCtrl_2c,pos={26,100},size={300,15},title="Sample Label"
	SetVariable RLCtrl_2c,limits={-inf,inf,0},value= _STR:"Enter Sample Label",disable=1
	
	CheckBox RLCtrl_2d,pos={26,130},size={60,14},title="Abs scale?",variable= root:Packages:NIST:SAS:g_1D_DoABS,disable=1
	CheckBox RLCtrl_2d,proc=RL_ABSCheck
	CheckBox RLCtrl_2e,pos={26,160},size={60,14},title="Noise?",variable= root:Packages:NIST:SAS:g_1D_AddNoise,disable=1
	CheckBox RLCtrl_2e,proc=RL_NoiseCheck

	
	SetVariable RLCtrl_2f,pos={26,185},size={150,15},title="Count Time (s)",format="%d"
	SetVariable RLCtrl_2f,limits={1,36000,10},value= root:Packages:NIST:SAS:gCntTime,disable=1
	
	SetVariable RLCtrl_2g,pos={26,210},size={300,15},title="Save Name"
	SetVariable RLCtrl_2g,limits={-inf,inf,0},value= _STR:"Enter File Name",disable=1
		
	Button RLCtrl_2h,pos={350,140},size={120,20},proc=Sim_AddToRunListButton,title="Add to Run List",disable=1
	Button RLCtrl_2i,pos={350,170},size={120,20},proc=Sim_AddTransToRunListButton,title="Add Trans Run",disable=1
	Button RLCtrl_2j,pos={350,200},size={120,20},proc=Sim_AddEmptyToRunListButton,title="Add Empty Beam",disable=1
	
	Button RLCtrl_2k,pos={500,140},size={120,20},proc=Sim_SaveRunListButton,title="Save Run List",disable=1
	Button RLCtrl_2l,pos={500,170},size={120,20},proc=Sim_RestoreRunListButton,title="Restore Run List",disable=1	
	Button RLCtrl_2m,pos={500,200},size={120,20},proc=Sim_ClearRowRunListButton,title="Clear Run",disable=1	
	
	
EndMacro

Function RL_ABSCheck(name,value)
	String name
	Variable value
	
	NVAR gRadioVal= root:Packages:NIST:SAS:g_1D_DoABS
	
	CheckBox RLCtrl_2d,value= gRadioVal==1

	return 0
End

Function RL_NoiseCheck(name,value)
	String name
	Variable value
	
	NVAR gRadioVal= root:Packages:NIST:SAS:g_1D_AddNoise
	
	CheckBox RLCtrl_2e,value= gRadioVal==1

	return 0
End


Proc Sim_RLHelpButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "Simulation Run List Scripting"
	if(V_flag !=0)
		DoAlert 0,"The Simulation Run List Scripting Help file could not be found"
	endif
End

//
// return the list of stored configurations - useful for popup
//
Function/S ListSASCALCConfigs()
	String str
	SetDataFolder root:Packages:NIST:SAS
	str = WaveList("Conf*",";","")
	SetDataFolder root:
//	print str
	return(str)
End

//
// return the list of stored sample conditions - userful for popup
//
Function/S ListSimSamples()
	String str
	SetDataFolder root:Packages:NIST:RunSim
	str = WaveList("Sam*",";","")
	SetDataFolder root:
//	print str
	return(str)
End


//
// stores a configuration to a wave
// any string can be used, "Config_" prefix is added
//
Function Sim_StoreConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "Sim_StoreConfProc()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// moves to the specified configuration and recalculates the intensity
// at the new configuration (done by the move function)
//
Function Sim_RecallConfigPopMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			Sim_MoveToConfiguration($("root:Packages:NIST:SAS:"+popStr))
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// gather all of the information to "store" the state of a sample
// so that it can be recalled later
//
// coefficents are from unsmeared models only, so they are in the root folder
//
// sample has information to do either a 1D or 2D simulation, fill it all in whether needed or not
//
// stores a copy of the coefficient wave + all of the other information as a wave note:
//
//	FUNC:function name 
// COEF:coefficient wave name
// THICK:thickness
// TRANS:transmission
// INCXS:incoherent cross section
// SAMRAD:sample radius
// LABEL:sample label string
//
//
Function Sim_StoreSampleButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR thick = root:Packages:NIST:SAS:gThick
			NVAR trans = root:Packages:NIST:SAS:gSamTrans
			NVAR xs = root:Packages:NIST:SAS:gSig_incoh
			NVAR r2 = root:Packages:NIST:SAS:gR2

			String funcStr="",cwStr="",noteStr="",lblStr=""
//
			ControlInfo/W=WrapperPanel popup_1
			funcStr=S_Value
			ControlInfo/W=WrapperPanel popup_2
			cwStr=S_Value
			ControlInfo/W=RunListPanel RLCtrl_1j
			lblStr = S_Value
			
			sprintf noteStr,"FUNC:%s;COEF:%s;THICK:%g;TRANS:%g;INCXS:%g;SAMRAD:%g;LABEL:%s;",funcStr,cwStr,thick,trans,xs,r2,lblStr
			Wave cw = $("root:"+cwStr)
			
			Duplicate/O cw tmpCW
			Note tmpCW,noteStr
			
			Execute "Sim_StoreSampleProc()"
						
			KillWaves/Z root:tmpCW
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// "store" the sample conditions to the root:Packages:NIST:RunSim folder
// -- need to do things this way to present a dialog for a name
//
Proc Sim_StoreSampleProc(waveStr)
	String waveStr
	
	SetDataFolder root:Packages:NIST:RunSim
	waveStr = CleanupName("Sam_"+waveStr,0)
	Duplicate/O root:tmpCW $(waveStr)
	SetDataFolder root:
		
End


//
// sample has information to do either a 1D or 2D simulation, fill it all in whether needed or not
//
// reset all of the sample information, and recalculate the intensity
//
Function Sim_RecallSamplePopMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			String noteStr="",funcStr="",coefStr="",lblStr=""
			Variable val
			// read the wave note
			Wave samWave = $("root:Packages:NIST:RunSim:"+popStr)
			noteStr = note(samWave)
			
			// reset the function, coef
			funcStr = StringByKey("FUNC", noteStr, ":", ";")
			PopupMenu popup_1 win=WrapperPanel,popmatch=funcStr
			SVAR gStr = root:Packages:NIST:SAS:gFuncStr 
			gStr = funcStr
			
			// coef wave
			coefStr = StringByKey("COEF", noteStr, ":", ";")
			Wave cw = $("root:"+coefStr)
			cw = samWave
			
			// now fake a mouse up on the function popup, and the table subwindow should repopulate
			//
			Struct WMPopupAction ps
			ps.eventCode = 2		//fake mouse up
			ps.popStr = funcStr
			Function_PopMenuProc(ps)
			
			// and set the variables
			NVAR thick = root:Packages:NIST:SAS:gThick
			NVAR trans = root:Packages:NIST:SAS:gSamTrans
			NVAR xs = root:Packages:NIST:SAS:gSig_incoh
			NVAR r2 = root:Packages:NIST:SAS:gR2

			thick = NumberByKey("THICK", noteStr, ":", ";")
			trans = NumberByKey("TRANS", noteStr, ":", ";")
			xs = NumberByKey("INCXS", noteStr, ":", ";")
			r2 = NumberByKey("SAMRAD", noteStr, ":", ";")		
			lblStr = StringByKey("LABEL",noteStr,":",";")
			
			SetVariable RLCtrl_2c,win=RunListPanel,value= _STR:lblStr
			SetVariable RLCtrl_1j,win=RunListPanel,value= _STR:lblStr
			
			// fake a "set" of the thickness to re-calculate, or simply re-calculate(since that's all that is done)
			ReCalculateInten(1)			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// function to control the drawing of controls in the TabControl on the RunList panel
// Naming scheme for the controls MUST be strictly adhered to... else controls will 
// appear in odd places...
// all controls are named RLCtrl_NA where N is the tab number and A is the letter denoting
// the controls position on that particular tab.
// in this way, they will always be drawn correctly..
//
// -- see the preference panel -- duplicated from there
//
Function RunListTabProc(name,tab)
	String name
	Variable tab
	
//	Print "name,number",name,tab
	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	Variable numChar
	numChar = strlen("RLCtrl_")
	for(ii=0;ii<num;ii+=1)
		//items all start w/"RLCtrl_", 7 characters
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,numChar-1]
		if(cmpstr(nameStr,"RLCtrl_")==0)
			onTab = str2num(item[numChar])			//[numChar] is a number
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
				case 3:
					PopupMenu $item,disable=(tab!=onTab)
					break
				// add more items to the switch if different control types are used
			endswitch
		endif
	endfor 
	return(0)
End


//
// parses the panel to fill in the values on the run list, which is a big listBox control
//
// setting the selW bits to flag as trans or empty beam runs
// ** this not an approved use of these bits, so I may run into trouble later...
//
// 2^2 = empty beam
// 2^3 = sample trans
//
// before exiting, increment the selected row in the listBox
//
Function Sim_AddToRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Lots of steps to make this happen
			
			// declarations
			SetDataFolder root:Packages:NIST:RunSim
	
			Wave/T textW = textW
			Wave selW = selW
			
			SetDataFolder root:
						
			// get the selected row (not based on checkboxes)
			Variable selRow
			
			ControlInfo/W=RunListPanel RLCtrlA
//			Print "sel = ",V_value
			selRow = V_value
			
			// fill in each of the 7 columns, and check the box (default is to run the sample)
			selW[selRow][0] = 2^5 + 2^4		//2^5 = checkbox, 2^4 true = checked
			
			// config
			ControlInfo/W=RunListPanel RLCtrl_2a
			textW[selRow][1] = S_Value
			
			// sample
			ControlInfo/W=RunListPanel RLCtrl_2b
			textW[selRow][2] = S_Value
			
			// sample Label
			ControlInfo/W=RunListPanel RLCtrl_2c
			textW[selRow][3] = S_Value
			
			// Count time
			NVAR ctTime = root:Packages:NIST:SAS:gCntTime
			textW[selRow][4] = num2str(ctTime)
			
			//save name
			ControlInfo/W=RunListPanel RLCtrl_2g
			textW[selRow][5] = S_Value
			
			// abs?
			NVAR doAbs = root:Packages:NIST:SAS:g_1D_DoABS
			textW[selRow][6] = num2str(doAbs)
			
			// noise?
			NVAR doNoise = root:Packages:NIST:SAS:g_1D_AddNoise
			textW[selRow][7] = num2str(doNoise)
					
			// move the selected row before exiting
			ListBox RLCtrlA,win=RunListPanel,selRow=(selRow+1)	
			
			break
		case -1: // control being killed
			break
	endswitch


	return 0
End


//
// parses the panel to fill in the values on the run list, which is a big listBox control
//
// setting the selW bits to flag as trans or empty beam runs
// 2^2 = empty beam
// 2^3 = sample trans
//
//
Function Sim_AddTransToRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			// set the sample conditions as "normal"
			STRUCT WMButtonAction bb
			bb.eventCode = 2
			Sim_AddToRunListButton(bb)	
			
			// declarations
			SetDataFolder root:Packages:NIST:RunSim
			Wave selW = selW
			Wave/T textW = textW
			SetDataFolder root:	
				
			// get the selected row (not based on checkboxes)
			Variable selRow
			
			ControlInfo/W=RunListPanel RLCtrlA
			selRow = V_value
			selRow -= 1 // since Sim_AddToRunListButton() increments the selection row by default
	
			// flag the row as a sample transmission measurement to deal with when running	
			selW[selRow][0] += 2^3		//

			textW[selRow][4] = "1"		//force the count time to 1 s
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// parses the panel to fill in the values on the run list, which is a big listBox control
//
// setting the selW bits to flag as trans or empty beam runs
// 2^2 = empty beam
// 2^3 = sample trans
//
//
Function Sim_AddEmptyToRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			// set the sample conditions as "normal"
			STRUCT WMButtonAction bb
			bb.eventCode = 2
			Sim_AddToRunListButton(bb)	
			
			// declarations
			SetDataFolder root:Packages:NIST:RunSim
			Wave selW = selW
			Wave/T textW = textW
			SetDataFolder root:	
				
			// get the selected row (not based on checkboxes)
			Variable selRow
			
			ControlInfo/W=RunListPanel RLCtrlA
			selRow = V_value
			selRow -= 1 // since Sim_AddToRunListButton() increments the selection row by default

			// flag the row as an empty beam measurement to deal with when running	
			selW[selRow][0] += 2^2		//

			textW[selRow][4] = "1"		//force the count time to 1 s

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// clears the selected row in the list box
//
Function Sim_ClearRowRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Lots of steps to make this happen
			
			// declarations
			SetDataFolder root:Packages:NIST:RunSim
	
			Wave/T textW = textW
			Wave selW = selW
			
			SetDataFolder root:		
			// get the selected row (not based on checkboxes)
			Variable selRow
			
			ControlInfo/W=RunListPanel RLCtrlA
			selRow = V_value
			
			// fill in each of the 7 columns, and check the box (default is to run the sample)
			selW[selRow][0] = 2^5		//set back to an un-checked checkBox

			textW[selRow][1,] = ""		// don't clear the run number

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// saves the entire run list to disk as an Igor text file
//
Function Sim_SaveRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:RunSim
	
			Wave/T textW = textW
			Wave/T names = names
			Wave selW = selW
			// save as Igor text to preserve everything
			Save/I/T/P=home textW,selW,names as "RunList.itx"

			SetDataFolder root:	
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// read a saved run list from an Igor text file
// -- this will wipe out whatever is currently on the list
//
Function Sim_RestoreRunListButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:RunSim
	
			String fname
			
			fname = "RunList.itx"
			LoadWave/O/T fname
			
			SetDataFolder root:
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// saves all of the currently stored samples to disk as an Igor text file
// -- the Igor text format preserves the wave note
//
Function Sim_SaveSampleButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:RunSim
	
			String strList = ""
			strList = WaveList("Sam*", ";", "" )

			// save as Igor text to preserve everything
			Save/B/I/T/P=home strList as "Samples.itx"

			SetDataFolder root:	
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//	reads a saved set of samples from a file. Will only wipe out samples that unfortunately have
// the same name. otherwise, they will simply be added to the list of samples
//
// -- NOTE that the model functions must be present (loaded and plotted separately) for the samples
//    to actually be used.
//
//
Function Sim_RestoreSampleButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:RunSim
	
			String fname
			
			fname = "Samples.itx"
			LoadWave/O/T fname
			
			SetDataFolder root:
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// save the currently stored configurations to an Igor text file
//
Function Sim_SaveConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:SAS
	
			String strList = ""
			strList = WaveList("Config*", ";", "" )

			// save as Igor text to preserve everything
			Save/B/I/T/P=home strList as "Configurations.itx"

			SetDataFolder root:	
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//	reads a saved set of configurations from a file. Will only wipe out configurations that unfortunately have
// the same name. otherwise, they will simply be added to the list of configurations 
//
Function Sim_RestoreConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SetDataFolder root:Packages:NIST:SAS
	
			String fname
			
			fname = "Configurations.itx"
			LoadWave/O/T fname
			
			SetDataFolder root:
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//	will delete ALL of the stored configurations
//
Function Sim_ClearConfigButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DoAlert 1,"Do you really want to delete all of the stored configurations?"
			if(V_flag==2)		//no, get out now
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:SAS
	
			Variable num,ii
			String strList = "",item=""
			strList = WaveList("Config*", ";", "" )
			num = ItemsInList(strList)
			for(ii=0;ii<num;ii+=1)
				item = StringFromList(ii, strList)
				KillWaves/Z	$item
			endfor
			
			SetDataFolder root:
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// will delete ALL of the stored sample conditions
//
Function Sim_ClearSampleButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			DoAlert 1,"Do you really want to delete all of the stored sample conditions?"
			if(V_flag==2)		//no, get out now
				return(0)
			endif
			SetDataFolder root:Packages:NIST:RunSim
	
			Variable num,ii
			String strList = "",item=""
			strList = WaveList("Sam*", ";", "" )
			num = ItemsInList(strList)
			for(ii=0;ii<num;ii+=1)
				item = StringFromList(ii, strList)
				KillWaves/Z	$item
			endfor
			
			SetDataFolder root:
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// step through the listBox, and execute the 1D simulation for each checked row, saving the result
//
Function Sim_RunSelected1DButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Lots of steps to make this happen
			DoWindow Sim_1D_Panel
			if(V_flag == 0)
				Sim_SetSimulationType(0)		//kill the simulation panel
				Sim_SetSimulationType(1)		//open the 1D simulation panel
			endif
			
			// declarations
			SetDataFolder root:Packages:NIST:RunSim
	
			Wave/T textW = textW
			Wave selW = selW
			
			SetDataFolder root:
				
			String configStr="",sampleStr="",lblStr="",saveStr="",ctTimeStr=""
			Variable numRows,ii,selRow
			numRows = DimSize(textW,0)
			
			NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just count rate, == 0 (default) to do the simulation and save
			g_estimateOnly = 0		// be sure this is zero, or it will only get CR, not actually run

			//loop through all of the rows
			for(ii=0;ii<numRows;ii+=1)
				if((selW[ii][0] & 2^4) != 0)		//checkbox is checked
					
					Print "**************** Running simulation for row = ",ii
					
					// move to configuration (no, Sim_RunSample_1D() will take care of this)
					configStr = textW[ii][1]
//					Sim_MoveToConfiguration($("root:Packages:NIST:SAS:"+configStr))
					
					// set the sample
					sampleStr = textW[ii][2]
				
					Struct WMPopupAction ps
					ps.eventCode = 2		//fake mouse up
					ps.popStr = sampleStr
					Function_PopMenuProc(ps)
					
					Sim_RecallSamplePopMenu(ps)
					
					// set the count time
//					NVAR ctTime = root:Packages:NIST:SAS:gCntTime
//					ctTime = str2num(textW[ii][4])

					// set the abs, noise checkboxes
					NVAR doAbs = root:Packages:NIST:SAS:g_1D_DoABS
					doAbs = str2num(textW[ii][6])
					
					NVAR doNoise = root:Packages:NIST:SAS:g_1D_AddNoise
					doNoise = str2num(textW[ii][7])				
					 
					// finally, run the simulation, saving the result (use scripting I've already written)
					lblStr = textW[ii][3]
					ctTimeStr = textW[ii][4]
					saveStr = textW[ii][5]
					Sim_RunSample_1D(configStr,ctTimeStr,lblStr,saveStr)
	
				endif
			
			endfor
			
			Print "****************** Run list has been completed ***********************"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// sets the simulation to "estimate only" mode, and determines the projected total "run" time, reporting
// the result to the command window. Resets to normal simulation mode on exiting.
//
Function Sim_RunSelectedDryButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just count rate, == 0 (default) to do the simulation and save
			g_estimateOnly = 1
			
			STRUCT WMButtonAction bb
			bb.eventCode = 2
			Sim_RunSelected2DList(bb)
			
			g_estimateOnly = 0
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// Runs the selected items in the list as 2D simulation. Either run the dry run first, or be prepared
// to wait for some unknown length of time, maybe forever. There is no stop button.
//
//
//
Function Sim_RunSelected2DButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just count rate, == 0 (default) to do the simulation and save
			g_estimateOnly = 0
			
			STRUCT WMButtonAction bb
			bb.eventCode = 2
			Sim_RunSelected2DList(bb)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// Runs the selected items in the list as 2D simulation. Either run the dry run first, or be prepared
// to wait for some unknown length of time, maybe forever. There is no stop button.
//
// this is the function that really does the work
//
// sets everything up - sample and configuration, then checks the selW bit to dispatch
// to sample trans, empty beam, or regular run.
//
// run Index comes in as a global from the panel.
//
Function Sim_RunSelected2DList(ba)
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Lots of steps to make this happen
			DoWindow MC_SASCALC
			if(V_flag == 0)
				Sim_SetSimulationType(0)		//kill the simulation panel
				Sim_SetSimulationType(2)		//open the 2D simulation panel
			endif
			
			Sim_SetSimTimeWarning(36000)			//sets the threshold for the warning dialog to 10 hours

			// declarations
			SetDataFolder root:Packages:NIST:RunSim
	
			Wave/T textW = textW
			Wave selW = selW
			
			SetDataFolder root:
				
			String configStr="",sampleStr="",lblStr="",saveStr="",ctTimeStr="",funcStr="",noteStr=""
			Variable numRows,ii,selRow,totalTime,thick,xs,r2,index,saveVal
			numRows = DimSize(textW,0)
			
			NVAR g_estimateOnly = root:Packages:NIST:SAS:g_estimateOnly		// == 1 for just count rate, == 0 (default) to do the simulation and save

			NVAR gIndex = root:Packages:NIST:RunSim:gRunIndex
			// local copy to be able to PBR
			index = gIndex
			
			totalTime = 0 
			
			//loop through all of the rows
			for(ii=0;ii<numRows;ii+=1)
				if((selW[ii][0] & 2^4) != 0)		//checkbox is checked
					
					Print "**************** Running simulation for row = ",ii
					
					// move to configuration
					configStr = textW[ii][1]
//					Sim_MoveToConfiguration($("root:Packages:NIST:SAS:"+configStr))
					
					// set the sample
					sampleStr = textW[ii][2]
				
					Struct WMPopupAction ps
					ps.eventCode = 2		//fake mouse up
					ps.popStr = sampleStr
					Function_PopMenuProc(ps)
					
					Sim_RecallSamplePopMenu(ps)
					
					// don't set the count time here -- this is set in Run_Sim(function)
//					NVAR ctTime = root:Packages:NIST:SAS:gCntTime
//					ctTime = str2num(textW[ii][4])

					//set the function String, radius, thickness, and Incoh from the sample specifics
					Wave samWave = $("root:Packages:NIST:RunSim:"+sampleStr)
					noteStr = note(samWave)
			
					// reset the function, coef
					funcStr = StringByKey("FUNC", noteStr, ":", ";")
					thick = NumberByKey("THICK", noteStr, ":", ";")
					xs = NumberByKey("INCXS", noteStr, ":", ";")
					r2 = NumberByKey("SAMRAD", noteStr, ":", ";")
					Sim_SetModelFunction(funcStr)						// model function name
					Sim_SetSampleRadius(r2)							// sam radius (cm)
					Sim_SetThickness(thick)								// thickness (cm)
					Sim_SetIncohXS(xs)									// incoh XS

	
					// set the abs, noise checkboxes
					Sim_SetRawCountsCheck(!str2num(textW[ii][6]))							// raw cts? 1== yes
					Sim_SetBeamStopInOut(1)								// BS in? 1==yes, this is a scattering measurement
					
					 
					lblStr = textW[ii][3]
					ctTimeStr = textW[ii][4]
					saveStr = textW[ii][5]
					
					// now do the run depending what the type of sample actually is...
					// 2^2 = empty beam
					// 2^3 = sample trans
					if ((selW[ii][0] & 2^2) != 0)		//run is an empty beam
						totalTime += Sim_RunEmptyBeamTrans_2D(configStr,ctTimeStr,lblStr,index)
					elseif ((selW[ii][0] & 2^3) != 0)		//run is a sample transmission, if not, run as a sample (no other choice)
						totalTime += Sim_RunTrans_2D(configStr,ctTimeStr,lblStr,index)
					else
						totalTime += Sim_RunSample_2D(configStr,ctTimeStr,lblStr,index)		//it's a regular sample run
					endif
	
				endif
			
			endfor
			
			Sim_SetSimTimeWarning(10)		//reset this before exiting
			gIndex = index		// reset the global
			
			Print "****************** Run list has been completed ***********************"
			if(g_estimateOnly)
				Print "Total Time (s) = ",totalTime
			endif
			
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

