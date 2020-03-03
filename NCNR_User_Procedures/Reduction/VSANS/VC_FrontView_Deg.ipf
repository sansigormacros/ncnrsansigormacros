#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


/////////////////////////
//
// Function to draw schematic boxes for the detector coverage based on the geometry
// of the instrument setup
//
// -- all of the dimensions are based on the angles and ranges in degrees
//
// -- this draws all 9 of the panels. Zooming is then simply rescaling the axes
//
// -- Now it is part of the main panel. This function is then called again
//    to update the drawing when any detector settings are changed
//
//////////////////////////

Function FrontView_1x()
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC

// Dimensions of detectors
	NVAR F_LR_w = root:Packages:NIST:VSANS:VCALC:gFront_LR_w
	NVAR F_LR_h =  root:Packages:NIST:VSANS:VCALC:gFront_LR_h
	NVAR F_TB_w =  root:Packages:NIST:VSANS:VCALC:gFront_TB_w
	NVAR F_TB_h =  root:Packages:NIST:VSANS:VCALC:gFront_TB_h
	
	NVAR M_LR_w = root:Packages:NIST:VSANS:VCALC:gMiddle_LR_w
	NVAR M_LR_h =  root:Packages:NIST:VSANS:VCALC:gMiddle_LR_h
	NVAR M_TB_w =  root:Packages:NIST:VSANS:VCALC:gMiddle_TB_w
	NVAR M_TB_h =  root:Packages:NIST:VSANS:VCALC:gMiddle_TB_h

	NVAR B_h =  root:Packages:NIST:VSANS:VCALC:gBack_h
	NVAR B_w =  root:Packages:NIST:VSANS:VCALC:gBack_w


// get the values from the panel
	Variable F_L_sep,F_R_sep,F_T_sep, F_B_sep,F_SDD
	Variable M_L_sep,M_R_sep,M_T_sep, M_B_sep, M_SDD
	Variable B_SDD, B_offset
	Variable axisRange
	
// these offset values are in cm !!
//in cm !!  distance T/B are behind L/R - not to be confused with lateral offset
	NVAR front_SDDsetback = root:Packages:NIST:VSANS:VCALC:gFront_SDDsetback
	NVAR middle_SDDsetback = root:Packages:NIST:VSANS:VCALC:gMiddle_SDDsetback
	
	
	//front
	ControlInfo/W=VCALC VCALCCtrl_2a
	F_L_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_2aa
	F_R_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_2b
	F_T_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_2bb
	F_B_sep = V_Value

	ControlInfo/W=VCALC VCALCCtrl_2d
	F_SDD = V_Value
				
	//middle
	ControlInfo/W=VCALC VCALCCtrl_3a
	M_L_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_3aa
	M_R_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_3b
	M_T_sep = V_Value
	ControlInfo/W=VCALC VCALCCtrl_3bb
	M_B_sep = V_Value
	
	ControlInfo/W=VCALC VCALCCtrl_3d
	M_SDD = V_Value
	
	//back			
	ControlInfo/W=VCALC VCALCCtrl_4a
	B_offset = V_Value	
	ControlInfo/W=VCALC VCALCCtrl_4b
	B_SDD = V_Value	
	
	// axis range
	ControlInfo/W=VCALC setVar_a	
	axisRange = V_Value

	Make/O/D/N=2 fv_degX,fv_degY		
	fv_degX[0] = -axisRange
	fv_degX[1] = axisRange
	fv_degY[0] = -axisRange
	fv_degY[1] = axisRange
			
// green 	fillfgc= (1,52428,26586)
// black 	fillfgc= (0,0,0)
// yellow fillfgc= (65535,65535,0)
// blue 	fillfgc= (1,16019,65535)
// red 	fillfgc= (65535,0,0)
// light blue fillfgc= (1,52428,52428)
// light brown fillfgc= (39321,26208,1)

	//clear the old drawing (this wipes out everything in the layer)
	DrawAction/L=UserBack/W=VCALC#FrontView delete

	//start drawing from the back, and work to the front as would be visible
	// ********* all of the dimensions are in cm
	Variable tmp_x1,tmp_x2,tmp_y1,tmp_y2
	
	// back detector +/- degrees
	tmp_x1 = -atan(B_w/2/(B_SDD)) *(180/pi)
	tmp_x2 = -tmp_x1
	tmp_y1 = -atan(B_h/2/(B_SDD)) *(180/pi)
	tmp_y2 = -tmp_y1
	
	//DrawRect [/W=winName ] left, top, right, bottom
	SetDrawLayer/W=VCALC#FrontView UserBack
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (1,52428,52428)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1			//only one panel in back

//
// MIDDLE 4 panels (T-B then L-R)
// TO DO -- add in the additional offset (backwards) to the SDD of the T/B panels
// TOP
	tmp_x1 = -atan(M_TB_w/2/(M_SDD+middle_SDDsetback))*(180/pi)		// x symmetric y is not
	tmp_x2 = -tmp_x1
	tmp_y1 = atan(M_T_sep/(M_SDD+middle_SDDsetback))*(180/pi)
	tmp_y2 = atan((M_T_sep+M_TB_h)/(M_SDD+middle_SDDsetback))*(180/pi)
	
//	Print tmp_x1,tmp_x2,tmp_y1,tmp_y2
	
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (1,16019,65535)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1
		
// BOTTOM (x unchanged, negate and swap y1,y2)
	tmp_y1 = atan((M_B_sep-M_TB_h)/(M_SDD+middle_SDDsetback))*(180/pi)
	tmp_y2 = atan(M_B_sep/(M_SDD+middle_SDDsetback))*(180/pi)
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (1,16019,65535)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1		
	
// LEFT
	tmp_x1 = atan((M_L_sep-M_LR_w)/(M_SDD))*(180/pi)		// y symmetric x is not
	tmp_x2 = atan((M_L_sep)/(M_SDD))*(180/pi)
	tmp_y1 = atan(M_LR_h/2/(M_SDD))*(180/pi)
	tmp_y2 = -tmp_y1
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (65535,0,0)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1			
// RIGHT (x changes, y the same)
	tmp_x1 = atan((M_R_sep)/(M_SDD))*(180/pi)		// y symmetric x is not
	tmp_x2 = atan((M_LR_w+M_R_sep)/(M_SDD))*(180/pi)
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (65535,0,0)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1	

//	Print tmp_x1,tmp_x2,tmp_y1,tmp_y2
	
////////
// FRONT 4 panels (T-B then L-R)
// TO DO -- add in the additional offset (backwards) to the SDD of the T/B panels
// TOP
	tmp_x1 = -atan(F_TB_w/2/(F_SDD+front_SDDsetback))*(180/pi)		// x symmetric y is not
	tmp_x2 = -tmp_x1
	tmp_y1 = atan(F_T_sep/(F_SDD+front_SDDsetback))*(180/pi)
	tmp_y2 = atan((F_T_sep+F_TB_h)/(F_SDD+front_SDDsetback))*(180/pi)
	
//	Print tmp_x1,tmp_x2,tmp_y1,tmp_y2
	
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (1,52428,26586)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1
		
// BOTTOM (x unchanged, negate and swap y1,y2)
	tmp_y1 = atan((F_B_sep-F_TB_h)/(F_SDD+front_SDDsetback))*(180/pi)
	tmp_y2 = atan(F_B_sep/(F_SDD+front_SDDsetback))*(180/pi)
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (1,52428,26586)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1		
	
// LEFT
	tmp_x1 = atan((F_L_sep-F_LR_w)/(F_SDD))*(180/pi)		// y symmetric x is not
	tmp_x2 = atan((F_L_sep)/(F_SDD))*(180/pi)
	tmp_y1 = atan(F_LR_h/2/(F_SDD))*(180/pi)
	tmp_y2 = -tmp_y1
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (39321,26208,1)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1			
// RIGHT (x changes, y the same)
	tmp_x1 = atan((F_R_sep)/(F_SDD))*(180/pi)		// y symmetric x is not
	tmp_x2 = atan((F_LR_w+F_R_sep)/(F_SDD))*(180/pi)
	SetDrawEnv/W=VCALC#FrontView xcoord= bottom,ycoord= left,fillfgc= (39321,26208,1)
	DrawRect/W=VCALC#FrontView tmp_x1,tmp_y2,tmp_x2,tmp_y1	
	
	
	SetAxis/W=VCALC#FrontView left -axisRange,axisRange
	SetAxis/W=VCALC#FrontView bottom -axisRange,axisRange


	SetDataFolder root:
		
	return(0)
End