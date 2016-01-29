#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// this will become the equivalent of "RawWindowHook"


Proc UpdateDisplayInformation(type)
	String type 
	
	DoWindow VSANS_Data
	if(V_flag==0)
		VSANS_DataPanel()		//draws the panel
	endif
	
	// update the information here  - in either case
	
end


Window VSANS_DataPanel() :Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(37,45,1042,784) /N=VSANS_Data
	ShowTools/A
	
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 200,140,310,230
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 320,140,430,230
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 440,140,550,230
	
	SetDrawEnv fsize= 18
	DrawText 230,185,"Front"
	SetDrawEnv fsize= 18
	DrawText 348,185,"Middle"
	SetDrawEnv fsize= 18
	DrawText 476,185,"Back"
	
	ToolsGrid visible=1

	TabControl tab0,pos={13,111},size={572,617},proc=VDataTabProc,tabLabel(0)="Front"
	TabControl tab0,tabLabel(1)="Middle",tabLabel(2)="Back",value= 2
	Button button0,pos={619,135},size={140,20}
	Button button0_1,pos={769,135},size={140,20}
	Button button0_2,pos={623,189},size={140,20}
	Button button0_3,pos={773,189},size={140,20}
	Button button0_4,pos={622,247},size={140,20}
	Button button0_5,pos={772,247},size={140,20}
	
	// for back panels (in pixels?)	
	Display/W=(50,239,546,710)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,det_panelsB
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
	// for middle panels (in pixels?)	
	Display/W=(50,239,546,710)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,det_panelsM
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
	// for front panels (in pixels?)	
	Display/W=(50,239,546,710)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
	RenameWindow #,det_panelsF
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
EndMacro


//
//lots to to here:
//
// - 1 - display the appropriate controls for each tab, and hide the others
// - 2 - display the correct detector data for each tab, and remove the others from the graph
// -----?? can I draw 3 graphs, and just put the right one on top?? move the other two to the side?
//
//
// TODO 
//   -- add all of the controls of the VCALC panel (log scaling, adjusting the axes, etc.)
//	-- get the panel to be correctly populated first, rather than needing to click everywhere to fill in
Function VDataTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
		
			SetDataFolder root:Packages:NIST:VSANS:VCALC
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsB fv_degY
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsM fv_degY
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsF fv_degY
			SetDataFolder root:
			
			if(tab==2)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Back
				//Wave det_B
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_B
				Wave det_B=data
				CheckDisplayed /W=VSANS_Data#det_panelsB det_B
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsB det_B
//					ModifyImage/W=VSANS_Data#det_panelsB det_B ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsB ''#0 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(50,239,546,710)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320,140,430,230)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200,140,310,230)
				SetDataFolder root:
			endif
			
			if(tab==1)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
				//Wave det_MR,det_ML,det_MB,det_MT
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_ML
				Wave det_ML=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MR
				Wave det_MR=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MT
				Wave det_MT=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MB
				Wave det_MB=data
				CheckDisplayed /W=VSANS_Data#det_panelsM det_MR
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsM det_MT		//order is important here to get LR on "top" of display
					AppendImage/W=VSANS_Data#det_panelsM det_MB
					AppendImage/W=VSANS_Data#det_panelsM det_ML
					AppendImage/W=VSANS_Data#det_panelsM det_MR
//					ModifyImage/W=VSANS_Data#det_panelsM det_MT ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_MB ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_ML ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_MR ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctab= {*,*,ColdWarm,0}		// ''#n means act on the nth image (there are 4)
					ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(50,239,546,710)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440,140,550,230)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200,140,310,230)
				SetDataFolder root:
			endif

			if(tab==0)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
				//Wave det_FL,det_FR,det_FT,det_FB
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FL
				Wave det_FL=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FR
				Wave det_FR=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FT
				Wave det_FT=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FB
				Wave det_FB=data
				CheckDisplayed /W=VSANS_Data#det_panelsF det_FL
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsF det_FB
					AppendImage/W=VSANS_Data#det_panelsF det_FT
					AppendImage/W=VSANS_Data#det_panelsF det_FL
					AppendImage/W=VSANS_Data#det_panelsF det_FR
//					ModifyImage/W=VSANS_Data#det_panelsF det_FB ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FT ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FL ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FR ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(50,239,546,710)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440,140,550,230)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320,140,430,230)
				SetDataFolder root:
			endif
			
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End