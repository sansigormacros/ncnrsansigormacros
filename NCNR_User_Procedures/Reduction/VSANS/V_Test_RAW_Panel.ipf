#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// this will become the equivalent of "RawWindowHook"





Window VSANS_Data() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(37,45,1042,784)
	ShowTools/A
	TabControl tab0,pos={13,111},size={572,617},proc=VDataTabProc,tabLabel(0)="Front"
	TabControl tab0,tabLabel(1)="Middle",tabLabel(2)="Back",value= 2
	Button button0,pos={619,135},size={140,20}
	Button button0_1,pos={769,135},size={140,20}
	Button button0_2,pos={623,189},size={140,20}
	Button button0_3,pos={773,189},size={140,20}
	Button button0_4,pos={622,247},size={140,20}
	Button button0_5,pos={772,247},size={140,20}
EndMacro



Function VDataTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End