#pragma rtGlobals=1		// Use modern global access method.




/////////////
// different views of the detector positions - based on John's drawings and the geometry
//
//
// These are the side and top views with the "rays" traced out to show
// where the detector views overlap
//
// TODO: make sure that all of the values are from global constants, not hard-wired values
//
//
//


// generate the waves needed for drawing the views
// draw a blank graph
Function SetupSideView()

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	Make/O/D/N=2 FT_profileX,FT_profileY,FB_profileX,FB_profileY
	Make/O/D/N=2 MT_profileX,MT_profileY,MB_profileX,MB_profileY
	
	Make/O/D/N=4 FT_rayX,FT_rayY,FB_rayX,FB_rayY
	Make/O/D/N=4 MT_rayX,MT_rayY,MB_rayX,MB_rayY

	Make/O/D/N=2 B_S_profileX,B_S_profileY
	Make/O/D/N=4 B_S_rayX,B_S_rayY
	
	DoWindow SideView
	if(V_Flag==0)
		Execute "SideView()"
	endif
	
//	UpdateSideView()  // don't bother running this here - the Execute is a separate command and is out of sync.
	
	SetDataFolder root:
	return(0)
End

//TODO - still need to account for the 30cm SDD offset for the T/B detectors. These are only
//      seen in the side view.
Function UpdateSideView()

	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
// wave declarations
	Wave FT_profileX,FT_profileY,FB_profileX,FB_profileY
	Wave MT_profileX,MT_profileY,MB_profileX,MB_profileY
	
	Wave FT_rayX,FT_rayY,FB_rayX,FB_rayY
	Wave MT_rayX,MT_rayY,MB_rayX,MB_rayY

	Wave B_S_profileX,B_S_profileY
	Wave B_S_rayX,B_S_rayY

// Dimensions of detectors
	NVAR F_LR_w = front_LR_w
	NVAR F_LR_h =  front_LR_h
	NVAR F_TB_w =  front_TB_w
	NVAR F_TB_h =  front_TB_h
	
	NVAR M_LR_w = middle_LR_w
	NVAR M_LR_h =  middle_LR_h
	NVAR M_TB_w =  middle_TB_w
	NVAR M_TB_h =  middle_TB_h

	NVAR B_h =  back_h
	NVAR B_w =  back_w


// get the values from the panel
	Variable F_LR_sep,F_TB_sep, F_SDD, F_offset, TB_SDD_offset
	Variable M_LR_sep,M_TB_sep, M_SDD, M_offset
	Variable B_SDD, B_offset

// TODO -- this needs to be a global	
	TB_SDD_offset = 300		//in mm !!  distance T/B are behind L/R - not to be confused with lateral offset
	TB_SDD_offset /= 1000		//convert to meters for the plot
	
	//front
//	ControlInfo VCALCCtrl_2a
//	F_LR_sep = V_Value
	ControlInfo VCALCCtrl_2b
	F_TB_sep = V_Value
	ControlInfo VCALCCtrl_2c
	F_offset = V_Value
	ControlInfo VCALCCtrl_2d
	F_SDD = V_Value
				
	//middle
//	ControlInfo VCALCCtrl_3a
//	M_LR_sep = V_Value
	ControlInfo VCALCCtrl_3b
	M_TB_sep = V_Value
	ControlInfo VCALCCtrl_3c
	M_offset = V_Value
	ControlInfo VCALCCtrl_3d
	M_SDD = V_Value
	
	//back			
	ControlInfo VCALCCtrl_4a
	B_offset = V_Value	
	ControlInfo VCALCCtrl_4b
	B_SDD = V_Value		

//	Print "Front ", F_LR_sep,F_TB_sep, F_SDD, F_offset
//	Print "Middle ",  M_LR_sep,M_TB_sep, M_SDD, M_offset
//	Print "Back ",  B_SDD, B_offset			
			

// FRONT
	FT_profileX = F_SDD+TB_SDD_offset		//SDD in meters, set back from L/R
	FB_profileX = FT_profileX
	
	FT_profileY[0] = F_TB_sep		// separation in mm
	FT_profileY[1] = FT_profileY[0] + F_TB_h	// add in height of T/B panel in mm
	
	FB_profileY = -FT_profileY

	//angles (not calculating anything, just connect the dots)
	FT_rayX[0] = 0
	FT_rayX[1] = F_SDD+TB_SDD_offset
	FT_rayX[2] = F_SDD+TB_SDD_offset
	FT_rayX[3] = 0
	
	FT_rayY[0] = 0
	FT_rayy[1] = FT_profileY[0]
	FT_rayY[2] = FT_profileY[1]
	FT_rayY[3] = 0
	
	
	FB_rayX[0] = 0
	FB_rayX[1] = F_SDD+TB_SDD_offset
	FB_rayX[2] = F_SDD+TB_SDD_offset
	FB_rayX[3] = 0
	
	FB_rayY[0] = 0
	FB_rayy[1] = FB_profileY[0]
	FB_rayY[2] = FB_profileY[1]
	FB_rayY[3] = 0	


// MIDDLE	
	MT_profileX = M_SDD+TB_SDD_offset		//SDD in meters
	MB_profileX = MT_profileX
	
	MT_profileY[0] = M_TB_sep		// separation in mm
	MT_profileY[1] = MT_profileY[0] + M_TB_h	// add in height of T/B panel in mm
	
	MB_profileY = -MT_profileY

	//angles (not calculating anything, just connect the dots)
	MT_rayX[0] = 0
	MT_rayX[1] = M_SDD+TB_SDD_offset
	MT_rayX[2] = M_SDD+TB_SDD_offset
	MT_rayX[3] = 0
	
	MT_rayY[0] = 0
	MT_rayy[1] = MT_profileY[0]
	MT_rayY[2] = MT_profileY[1]
	MT_rayY[3] = 0
	
	
	MB_rayX[0] = 0
	MB_rayX[1] = M_SDD+TB_SDD_offset
	MB_rayX[2] = M_SDD+TB_SDD_offset
	MB_rayX[3] = 0
	
	MB_rayY[0] = 0
	MB_rayy[1] = MB_profileY[0]
	MB_rayY[2] = MB_profileY[1]
	MB_rayY[3] = 0	

// BACK
	B_S_profileX = B_SDD		//SDDb in meters
	
	B_S_profileY[0] = B_h/2		// half-height
	B_S_profileY[1] = -B_h/2		// half-height

	B_S_rayX[0] = 0
	B_S_rayX[1] = B_SDD
	B_S_rayX[2] = B_SDD
	B_S_rayX[3] = 0
	
	B_S_rayY[0] = 0
	B_S_rayy[1] = B_S_profileY[0]
	B_S_rayY[2] = B_S_profileY[1]
	B_S_rayY[3] = 0	
	
	SetDataFolder root:
	
	Execute "SideView()"
	
	return(0)
	
End


Window SideView() : Graph

	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	CheckDisplayed/W=VCALC#SideView FB_rayY
	if(V_flag == 0)
//		Display /W=(41,720,592,1119) FB_rayY vs FB_rayX as "SideView"
		AppendToGraph/W=VCALC#SideView FB_rayY vs FB_rayX
		AppendToGraph/W=VCALC#SideView FT_rayY vs FT_rayX
		AppendToGraph/W=VCALC#SideView MB_rayY vs MB_rayX
		AppendToGraph/W=VCALC#SideView MT_rayY vs MT_rayX
		AppendToGraph/W=VCALC#SideView B_S_rayY vs B_S_rayX
		AppendToGraph/W=VCALC#SideView B_S_profileY vs B_S_profileX
		AppendToGraph/W=VCALC#SideView FB_profileY vs FB_profileX
		AppendToGraph/W=VCALC#SideView FT_profileY vs FT_profileX
		AppendToGraph/W=VCALC#SideView MB_profileY vs MB_profileX
		AppendToGraph/W=VCALC#SideView MT_profileY vs MT_profileX
	
		ModifyGraph/W=VCALC#SideView lSize(B_S_profileY)=5,lSize(FB_profileY)=5,lSize(FT_profileY)=5,lSize(MB_profileY)=5
		ModifyGraph/W=VCALC#SideView lSize(MT_profileY)=5
		ModifyGraph/W=VCALC#SideView rgb(FB_rayY)=(0,0,0),rgb(FT_rayY)=(0,0,0),rgb(MB_rayY)=(0,0,0),rgb(MT_rayY)=(0,0,0)
		ModifyGraph/W=VCALC#SideView rgb(B_S_rayY)=(0,0,0),rgb(B_S_profileY)=(1,52428,52428),rgb(FB_profileY)=(3,52428,1)
		ModifyGraph/W=VCALC#SideView rgb(FT_profileY)=(3,52428,1),rgb(MB_profileY)=(1,12815,52428),rgb(MT_profileY)=(1,12815,52428)
		ModifyGraph/W=VCALC#SideView grid=1
		ModifyGraph/W=VCALC#SideView mirror=2
		ModifyGraph/W=VCALC#SideView nticks(left)=8
		Label/W=VCALC#SideView left "\\Z10Vertical position (mm)"
		Label/W=VCALC#SideView bottom "\\Z10SDD (meters)"
		SetAxis/W=VCALC#SideView left -800,800
		SetAxis/W=VCALC#SideView bottom 0,25
//		TextBox/W=VCALC#SideView/C/N=text0/A=MC/X=22.54/Y=42.04 "\\JCSIDE VIEW\rOnly the Top/Bottom panels are shown"
		TextBox/W=VCALC#SideView/C/N=text0/A=MC/X=40.15/Y=43.62 "\\JCSIDE VIEW\r= Top/Bottom panels"
	endif
	SetDataFolder fldrSav0
	
EndMacro



//////////////////
// generate the waves needed for drawing the views
// draw a blank graph
//
// TOP VIEW uses the L and R banks
//
Function SetupTopView()

	SetDataFolder root:Packages:NIST:VSANS:VCALC

	Make/O/D/N=2 FL_profileX,FL_profileY,FR_profileX,FR_profileY
	Make/O/D/N=2 ML_profileX,ML_profileY,MR_profileX,MR_profileY
	
	Make/O/D/N=4 FL_rayX,FL_rayY,FR_rayX,FR_rayY
	Make/O/D/N=4 ML_rayX,ML_rayY,MR_rayX,MR_rayY

	Make/O/D/N=2 B_T_profileX,B_T_profileY
	Make/O/D/N=4 B_T_rayX,B_T_rayY

	DoWindow TopView
	if(V_Flag==0)
		Execute "TopView()"
	endif
	
	
	SetDataFolder root:
	return(0)
End

Function UpdateTopView()

	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
// wave declarations
	Wave FL_profileX,FL_profileY,FR_profileX,FR_profileY
	Wave ML_profileX,ML_profileY,MR_profileX,MR_profileY
	
	Wave FL_rayX,FL_rayY,FR_rayX,FR_rayY
	Wave ML_rayX,ML_rayY,MR_rayX,MR_rayY

	Wave B_T_profileX,B_T_profileY
	Wave B_T_rayX,B_T_rayY

// Dimensions of detectors
	NVAR F_LR_w = front_LR_w
	NVAR F_LR_h =  front_LR_h
	NVAR F_TB_w =  front_TB_w
	NVAR F_TB_h =  front_TB_h
	
	NVAR M_LR_w = middle_LR_w
	NVAR M_LR_h =  middle_LR_h
	NVAR M_TB_w =  middle_TB_w
	NVAR M_TB_h =  middle_TB_h

	NVAR B_h =  back_h
	NVAR B_w =  back_w


// get the values from the panel
	Variable F_LR_sep,F_TB_sep, F_SDD, F_offset
	Variable M_LR_sep,M_TB_sep, M_SDD, M_offset
	Variable B_SDD, B_offset
	//front
	ControlInfo VCALCCtrl_2a
	F_LR_sep = V_Value
//	ControlInfo VCALCCtrl_2b
//	F_TB_sep = V_Value
	ControlInfo VCALCCtrl_2c
	F_offset = V_Value
	ControlInfo VCALCCtrl_2d
	F_SDD = V_Value
				
	//middle
	ControlInfo VCALCCtrl_3a
	M_LR_sep = V_Value
//	ControlInfo VCALCCtrl_3b
//	M_TB_sep = V_Value
	ControlInfo VCALCCtrl_3c
	M_offset = V_Value
	ControlInfo VCALCCtrl_3d
	M_SDD = V_Value
	
	//back			
	ControlInfo VCALCCtrl_4a
	B_offset = V_Value	
	ControlInfo VCALCCtrl_4b
	B_SDD = V_Value		

//	Print "Front ", F_LR_sep,F_TB_sep, F_SDD, F_offset
//	Print "Middle ",  M_LR_sep,M_TB_sep, M_SDD, M_offset
//	Print "Back ",  B_SDD, B_offset			
			

// FRONT
	FL_profileX = F_SDD		//SDD in meters
	FR_profileX = FL_profileX
	
	FL_profileY[0] = F_LR_sep		// separation in mm
	FL_profileY[1] = FL_profileY[0] + F_LR_w	// add in width of L/R panel in mm
	
	FR_profileY = -FL_profileY

	//angles (not calculating anything, just connect the dots)
	FL_rayX[0] = 0
	FL_rayX[1] = F_SDD
	FL_rayX[2] = F_SDD
	FL_rayX[3] = 0
	
	FL_rayY[0] = 0
	FL_rayy[1] = FL_profileY[0]
	FL_rayY[2] = FL_profileY[1]
	FL_rayY[3] = 0
	
	
	FR_rayX[0] = 0
	FR_rayX[1] = F_SDD
	FR_rayX[2] = F_SDD
	FR_rayX[3] = 0
	
	FR_rayY[0] = 0
	FR_rayy[1] = FR_profileY[0]
	FR_rayY[2] = FR_profileY[1]
	FR_rayY[3] = 0	


// MIDDLE	
	ML_profileX = M_SDD		//SDD in meters
	MR_profileX = ML_profileX
	
	ML_profileY[0] = M_LR_sep		// separation in mm
	ML_profileY[1] = ML_profileY[0] + M_LR_w	// add in width of L/R panel in mm
	
	MR_profileY = -ML_profileY

	//angles (not calculating anything, just connect the dots)
	ML_rayX[0] = 0
	ML_rayX[1] = M_SDD
	ML_rayX[2] = M_SDD
	ML_rayX[3] = 0
	
	ML_rayY[0] = 0
	ML_rayy[1] = ML_profileY[0]
	ML_rayY[2] = ML_profileY[1]
	ML_rayY[3] = 0
	
	
	MR_rayX[0] = 0
	MR_rayX[1] = M_SDD
	MR_rayX[2] = M_SDD
	MR_rayX[3] = 0
	
	MR_rayY[0] = 0
	MR_rayy[1] = MR_profileY[0]
	MR_rayY[2] = MR_profileY[1]
	MR_rayY[3] = 0	

// BACK
	B_T_profileX = B_SDD		//SDDb in meters
	
	B_T_profileY[0] = B_h/2		// half-height
	B_T_profileY[1] = -B_h/2		// half-height

	B_T_rayX[0] = 0
	B_T_rayX[1] = B_SDD
	B_T_rayX[2] = B_SDD
	B_T_rayX[3] = 0
	
	B_T_rayY[0] = 0
	B_T_rayY[1] = B_T_profileY[0]
	B_T_rayY[2] = B_T_profileY[1]
	B_T_rayY[3] = 0	
	
	SetDataFolder root:
	
	Execute "TopView()"
	
	return(0)
	
End


Window TopView() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	CheckDisplayed/W=VCALC#TopView FR_rayY
	if(V_flag == 0)
		
//		Display /W=(594,721,1144,1119) FR_rayY vs FR_rayX as "TopView"
		AppendToGraph/W=VCALC#TopView FR_rayY vs FR_rayX
		AppendToGraph/W=VCALC#TopView FL_rayY vs FL_rayX
		AppendToGraph/W=VCALC#TopView MR_rayY vs MR_rayX
		AppendToGraph/W=VCALC#TopView ML_rayY vs ML_rayX
		AppendToGraph/W=VCALC#TopView B_T_rayY vs B_T_rayX
		AppendToGraph/W=VCALC#TopView B_T_profileY vs B_T_profileX
		AppendToGraph/W=VCALC#TopView FR_profileY vs FR_profileX
		AppendToGraph/W=VCALC#TopView FL_profileY vs FL_profileX
		AppendToGraph/W=VCALC#TopView MR_profileY vs MR_profileX
		AppendToGraph/W=VCALC#TopView ML_profileY vs ML_profileX
	
		ModifyGraph/W=VCALC#TopView lSize(B_T_profileY)=5,lSize(FR_profileY)=5,lSize(FL_profileY)=5,lSize(MR_profileY)=5
		ModifyGraph/W=VCALC#TopView lSize(ML_profileY)=5
		ModifyGraph/W=VCALC#TopView rgb(FR_rayY)=(0,0,0),rgb(FL_rayY)=(0,0,0),rgb(MR_rayY)=(0,0,0),rgb(ML_rayY)=(0,0,0)
		ModifyGraph/W=VCALC#TopView rgb(B_T_rayY)=(0,0,0),rgb(B_T_profileY)=(1,52428,52428),rgb(FR_profileY)=(39321,26208,1)
		ModifyGraph/W=VCALC#TopView rgb(FL_profileY)=(39321,26208,1)
		ModifyGraph/W=VCALC#TopView grid=1
		ModifyGraph/W=VCALC#TopView mirror=2
		ModifyGraph/W=VCALC#TopView nticks(left)=8
		Label/W=VCALC#TopView left "\\Z10Horizontal position (mm)"
		Label/W=VCALC#TopView bottom "\\Z10SDD (meters)"
		SetAxis/W=VCALC#TopView left -800,800
		SetAxis/W=VCALC#TopView bottom 0,25
		TextBox/W=VCALC#TopView/C/N=text0/A=MC/X=41.61/Y=43.62 "\\JCTOP VIEW\r= Left/Right panels"
	endif
	SetDataFolder fldrSav0

EndMacro



