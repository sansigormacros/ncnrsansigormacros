#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// http://en.wikipedia.org/wiki/Superformula
//
// and the SuperEllipsoid
// and the superquadric
// and the supertoroid
//
//
// The superEllipsoid is in an implicit form, so it can easily be converted
// to voxels, since the implicit form defines inside/outside of the surface.
//
// -- need to clean up the superEllipsoid version so that it can be incorporated into the real-space
//  modeling functions - since this would be a rather unique, if not totally useless thing to do.
//
//
// the general superformula is given in polar coordinates, so it is going to require a 
// bit of math to get the voxel representation. 
//
// With an implicit equation for the surface - it's a snap to generate the voxels.
//
//



// you can also use:
//
// mat_as_3dCloud()
//
// Gizmo_superSurface()
//



Macro Setup_SuperFormulas()

	DoWindow/F SuperFormulaPanel
	if(V_flag == 0)
		Setup_super3D_waves(128)
	
		Variable/G gSuperRadioVal= 4		//start with superFormula checked

		SuperFormulaPanel()
	endif
		
End

Proc SuperFormulaPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(634,45,934,394) /K=1
	
	
	DoWindow/C SuperFormulaPanel
//	ShowTools/A
	SetDrawLayer UserBack
	SetVariable setvar0,pos={37.00,92.00},size={80.00,18.00},title="r",fSize=12
	SetVariable setvar0,limits={-20,20,1},value= _NUM:3,disable=1
	SetVariable setvar1,pos={37.00,118.00},size={80.00,18.00},title="t",fSize=12
	SetVariable setvar1,limits={-20,20,1},value= _NUM:2,disable=1
	SetVariable setvar2,pos={37.00,145.00},size={80.00,18.00},title="s",fSize=12
	SetVariable setvar2,limits={-20,20,1},value= _NUM:4,disable=1
	SetVariable setvar3,pos={37.00,172.00},size={80.00,18.00},title="rad",fSize=12
	SetVariable setvar3,limits={0,50,1},value= _NUM:15,disable=1
	
	SetVariable setvar4,pos={162.00,91.00},size={80.00,18.00},title="m",fSize=12
	SetVariable setvar4,limits={-20,20,1},value= _NUM:15
	SetVariable setvar5,pos={162.00,117.00},size={80.00,18.00},title="n1",fSize=12
	SetVariable setvar5,limits={-20,20,1},value= _NUM:1	
	SetVariable setvar6,pos={162.00,143.00},size={80.00,18.00},title="n2",fSize=12
	SetVariable setvar6,limits={-20,20,1},value= _NUM:2
	SetVariable setvar7,pos={162.00,170.00},size={80.00,18.00},title="n3",fSize=12
	SetVariable setvar7,limits={-20,20,1},value= _NUM:6

	SetVariable setvar8,pos={35,226.00},size={120.00,18.00},title="x-scaling"
	SetVariable setvar8,fSize=12,limits={0,50,1},value= _NUM:20
	SetVariable setvar9,pos={35,253.00},size={120.00,18.00},title="y-scaling"
	SetVariable setvar9,fSize=12,limits={0,50,1},value= _NUM:20
	SetVariable setvar10,pos={35,281.00},size={120.00,18.00},title="z-scaling"
	SetVariable setvar10,fSize=12,limits={0,50,1},value= _NUM:20
	
	CheckBox check0,pos={43.00,15.00},size={64.00,15.00},title="Ellipsoid",fSize=12
	CheckBox check0,value= 0,mode=1,proc=SuperCheckProc
	CheckBox check1,pos={44.00,38.00},size={54.00,15.00},title="Toroid",fSize=12
	CheckBox check1,value= 0,mode=1,proc=SuperCheckProc
	CheckBox check2,pos={149.00,14.00},size={61.00,15.00},title="Quadric",fSize=12
	CheckBox check2,value= 0,mode=1,proc=SuperCheckProc
	CheckBox check3,pos={149.00,38.00},size={96.00,15.00},title="SuperFormula"
	CheckBox check3,fSize=12,value= 1,mode=1,proc=SuperCheckProc

	Button button0,pos={190.00,215.00},size={80.00,20.00},proc=SuperCalcButtonProc,title="Calculate"
	Button button1,pos={190.00,245.00},size={80.00,20.00},proc=PointCloudButtonProc,title="Point Cloud"


End

Function SuperCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			// which radio button?
			// be sure that the others are "off"
			
			// disable the parameters not needed
			// enable the parameters that are needed
			
			NVAR gRadioVal= root:gSuperRadioVal
	
			strswitch (cba.ctrlName)
				case "check0":		// Ellipsoid
					gRadioVal= 1
					
					SetVariable setvar0 disable=0
					SetVariable setvar1 disable=0
					SetVariable setvar2 disable=1
					SetVariable setvar3 disable=1
					SetVariable setvar4 disable=1
					SetVariable setvar5 disable=1
					SetVariable setvar6 disable=1
					SetVariable setvar7 disable=1
					
					break
				case "check1":		// Toroid
					gRadioVal= 2
					SetVariable setvar0 disable=0
					SetVariable setvar1 disable=0
					SetVariable setvar2 disable=1
					SetVariable setvar3 disable=0
					SetVariable setvar4 disable=1
					SetVariable setvar5 disable=1
					SetVariable setvar6 disable=1
					SetVariable setvar7 disable=1
					break
				case "check2":		// Quadric
					gRadioVal= 3
					SetVariable setvar0 disable=0
					SetVariable setvar1 disable=0
					SetVariable setvar2 disable=0
					SetVariable setvar3 disable=1
					SetVariable setvar4 disable=1
					SetVariable setvar5 disable=1
					SetVariable setvar6 disable=1
					SetVariable setvar7 disable=1
					break
				case "check3":		// SuperFormula
					gRadioVal= 4
					SetVariable setvar0 disable=1
					SetVariable setvar1 disable=1
					SetVariable setvar2 disable=1
					SetVariable setvar3 disable=1
					SetVariable setvar4 disable=0
					SetVariable setvar5 disable=0
					SetVariable setvar6 disable=0
					SetVariable setvar7 disable=0
					break
			endswitch
			CheckBox check0,value= gRadioVal==1
			CheckBox check1,value= gRadioVal==2
			CheckBox check2,value= gRadioVal==3
			CheckBox check3,value= gRadioVal==4
			

			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SuperCalcButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// switch to the proper function call
			// read in the values from the panel
			// calculate the shape
			NVAR gRadioVal= root:gSuperRadioVal

			Variable aa,bb,cc
			Variable mm,n1,n2,n3
			Variable rr,ss,tt,rad
			
			ControlInfo setvar8
			aa = V_Value
			ControlInfo setvar9
			bb = V_Value
			ControlInfo setvar10
			cc = V_Value


			switch (gRadioVal)
				case 1:		// Ellipsoid
					ControlInfo setvar0
					rr = V_Value
					ControlInfo setvar1
					tt = V_Value				
					
					isInsideSuperEllipsoid(rr,tt,aa,bb,cc)
					
					break
				case 2:		// Toroid
					ControlInfo setvar0
					rr = V_Value
					ControlInfo setvar1
					tt = V_Value				
					ControlInfo setvar3
					rad = V_Value
			
					isInsideSuperToroid(rr,tt,aa,bb,cc,rad)

					break
				case 3:		// Quadric
					ControlInfo setvar0
					rr = V_Value
					ControlInfo setvar1
					tt = V_Value				
					ControlInfo setvar2
					ss = V_Value

					isInsideSuperQuadric(rr,ss,tt,aa,bb,cc)
					
					break
				case 4:		// SuperFormula
					ControlInfo setvar4
					mm = V_Value
					ControlInfo setvar5
					n1 = V_Value				
					ControlInfo setvar6
					n2 = V_Value
					ControlInfo setvar7
					n3 = V_Value

					isInsideSuperFormula(mm,n1,n2,n3,aa,bb,cc)

					break
			endswitch

			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PointCloudButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "mat_as_3dCloud()"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End









// the 3D version
// partially converted 
//
//		superFormula_3d(1.5,1.5,7,7,1,1)
//  	superFormula_3d(1.1,1.1,.2,.2,1,1)
//
//
Function superFormula_3d(n1,n2,n3,n4,a1,a2)
	Variable n1,n2,n3,n4,a1,a2

	variable np,ii,jj,nu,nv,raux1,raux2,sig,r1,r2
	
	np=1000
	Make/O/D/N=(np) u3,v3
	
	Make/O/D/N=(np+1,np+1,3) M_Parametric//,r1,r2

//	u3 = (x/np)*2*pi		// range from (0,2Pi)		//wrong definition
//	v3 = (x/np)*pi		// range from (0,pi)	
		
	u3 = (x/np)*2*pi - pi		// range from (-pi, pi)
	v3 = (x/np)*pi - pi/2		// range from (-pi/2, pi/2)

	nu = np
	nv = np
	sig = 1
	
	for(ii=0;ii<nu;ii+=1)
		for(jj=0;jj<nv;jj+=1)
			raux1 = abs(1/a1*abs(cos(n1*u3[ii]/4)))^n3+abs(1/a2*abs(sin(n1*u3[ii]/4)))^n4
			r1 = abs(raux1)^(-1/n2)
			raux2 = abs(1/a1*abs(cos(n1*v3[jj]/4)))^n3+abs(1/a2*abs(sin(n1*v3[jj]/4)))^n4
			r2 = abs(raux2)^(-1/n2)

// the three values here are XYZ calculated from the polar representation of the superformula
//
			M_Parametric[ii][jj][0] = r1*cos(u3[ii])*r2*cos(v3[jj])
			M_Parametric[ii][jj][1] = r1*sin(u3[ii])*r2*cos(v3[jj])
			M_Parametric[ii][jj][2] = sig*r2*sin(v3[jj])			
		endfor
	endfor
			
	return(0)
end


// the 3D version
// partially converted 
//
//		superFormula_3d_v2(3.5,3.5,1,1,1,1,1)
//  	superFormula_3d_v2(1.1,1.1,.5,.5,.5,1,1)
//		superFormula_3d_v2(3.5,3.5,2,7,15,1,1)
//
// a more general version - note that there is a 7th parameter
//
Function superFormula_3d_v2(m1,m2,n1,n2,n3,aa,bb)
	Variable m1,m2,n1,n2,n3,aa,bb

	variable np,ii,jj,nu,nv,raux1,raux2,sig,r1,r2
	
	np=1000
	Make/O/D/N=(np) u3,v3
	
	Make/O/D/N=(np+1,np+1,3) M_Parametric//,r1,r2

//	u3 = (x/np)*2*pi		// range from (0,2Pi)		//this is the standard definition of spherical coordinates
//	v3 = (x/np)*pi		// range from (0,pi)		//but not what was used in this case
		
	u3 = (x/np)*2*pi - pi		// range from (-pi, pi)
	v3 = (x/np)*pi - pi/2		// range from (-pi/2, pi/2)

	nu = np
	nv = np
	sig = 1
	
	for(ii=0;ii<nu;ii+=1)
		for(jj=0;jj<nv;jj+=1)
			raux1 = abs(1/aa*abs(cos(m1*u3[ii]/4)))^n2+abs(1/bb*abs(sin(m2*u3[ii]/4)))^n3
			r1 = abs(raux1)^(-1/n1)
			raux2 = abs(1/aa*abs(cos(m1*v3[jj]/4)))^n2+abs(1/bb*abs(sin(m2*v3[jj]/4)))^n3
			r2 = abs(raux2)^(-1/n1)

// the three values here are XYZ calculated from the polar representation of the superformula
//
			M_Parametric[ii][jj][0] = r1*cos(u3[ii])*r2*cos(v3[jj])
			M_Parametric[ii][jj][1] = r1*sin(u3[ii])*r2*cos(v3[jj])
			M_Parametric[ii][jj][2] = sig*r2*sin(v3[jj])			
		endfor
	endfor
			
	return(0)
end



  
Function SuperEllipsoid_3d(rr,tt,aa,bb,cc)
	Variable rr,tt,aa,bb,cc

	variable np,ii,jj,nu,nv,r1,r2
	
	np=1000
	Make/O/D/N=(np) uu,vv
	
	Make/O/D/N=(np+1,np+1,3) M_Parametric

//	u3 = (x/np)*2*pi		// range from (0,2Pi)		//wrong definition
//	v3 = (x/np)*pi		// range from (0,pi)	
		
	uu = (x/np)*2*pi - pi		// range from (-pi, pi)
	vv = (x/np)*pi - pi/2		// range from (-pi/2, pi/2)

	nu = np
	nv = np
	
	for(ii=0;ii<nu;ii+=1)
		for(jj=0;jj<nv;jj+=1)

			M_Parametric[ii][jj][0] = aa*SE_C(vv[jj],2/tt)*SE_C(uu[ii],2/rr)
			M_Parametric[ii][jj][1] = bb*SE_C(vv[jj],2/tt)*SE_S(uu[ii],2/rr)
			M_Parametric[ii][jj][2] = cc*SE_S(vv[jj],2/tt)
		endfor
	endfor
			
	return(0)
end

Function SE_C(ww,mm)
	Variable ww,mm
	
	Variable ans
	
	ans = sign(cos(ww)) * (abs(cos(ww)))^mm
	
	return(ans)
End


Function SE_S(ww,mm)
	Variable ww,mm
	
	Variable ans
	
	ans = sign(sin(ww)) * (abs(sin(ww)))^mm
	
	return(ans)
End


// will plot either the 2d or 3d version, whichever was most recently
// calculated -- the M_parametric wave is plotted
Proc Gizmo_superSurface()
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/T="Gizmo0"/W=(286,371,959,941)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo Surface=root:M_Parametric,name=surface0
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ surfaceColorType,1}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ srcMode,4}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ frontColor,1,0,0,1}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ backColor,0,0,1,1}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ SurfaceCTABScaling,16}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ textureType,1}
	ModifyGizmo modifyObject=surface0,objectType=Surface,property={calcNormals,1}
	AppendToGizmo light=Directional,name=light0
	ModifyGizmo modifyObject=light0,objectType=light,property={ position,-0.832778,0.305999,0.461353,0.000000}
	ModifyGizmo modifyObject=light0,objectType=light,property={ direction,-0.832778,0.305999,0.461353}
	ModifyGizmo modifyObject=light0,objectType=light,property={ ambient,0.533333,0.533333,0.533333,1.000000}
	ModifyGizmo modifyObject=light0,objectType=light,property={ specular,1.000000,1.000000,1.000000,1.000000}
	AppendToGizmo freeAxesCue={0,0,0,1.3},name=freeAxesCue0
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	ModifyGizmo setDisplayList=0, opName=pushAttribute0, operation=pushAttribute, data=1
	ModifyGizmo setDisplayList=1, object=light0
	ModifyGizmo setDisplayList=2, object=surface0
	ModifyGizmo setDisplayList=3, opName=popAttribute0, operation=popAttribute
	ModifyGizmo setDisplayList=4, object=freeAxesCue0
	ModifyGizmo setDisplayList=5, object=axes0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={1129,602,1946,899}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={-0.111733,-0.610876,-0.767227,-0.160412}
EndMacro



///////

//
Proc Setup_super3D_waves(num)
	Variable num=128
	Make/O/D/N=(num,num,num) superW
	SetScale/P x -(num/2),1,"",superW
	SetScale/P y -(num/2),1,"",superW
	SetScale/P z -(num/2),1,"",superW
	
End

////
//
Function isInsideSuperEllipsoid(rr,tt,aa,bb,cc)
	Variable rr,tt,aa,bb,cc

	if(exists("root:mat") == 0)
		FFT_MakeMatrixButtonProc("")
	endif
		
	Duplicate/O root:mat inW, voxW
	Redimension/D inW
	Variable num=DimSize(inW, 0)
	SetScale/P x -(num/2),1,"",inW
	SetScale/P y -(num/2),1,"",inW
	SetScale/P z -(num/2),1,"",inW
	
	// using the wave scaling
	inW = ( abs(x/aa)^rr + abs(y/bb)^rr )^(tt/rr) + abs(z/cc)^tt
	voxW = inW[p][q][r] <= 1 ? 1 : 0

	Wave w = root:mat
	w = voxW
	
	return(0)
end

// pass superW to this function, really just for the scaling...
// so I need to fix this in the future
Function isInsideSuperToroid(rr,tt,aa,bb,cc,rad)
	Variable rr,tt,aa,bb,cc,rad
	
	Variable dd
	if(exists("root:mat") == 0)
		FFT_MakeMatrixButtonProc("")
	endif
		
	Duplicate/O root:mat inW, voxW
	Redimension/D inW
	Variable num=DimSize(inW, 0)
	SetScale/P x -(num/2),1,"",inW
	SetScale/P y -(num/2),1,"",inW
	SetScale/P z -(num/2),1,"",inW
	
	// using the wave scaling
	dd = rad/sqrt(aa^2 + bb^2)
	inW = ( ( abs(x/aa)^rr + abs(y/bb)^rr )^(1/rr) - dd )^tt + abs(z/cc)^tt
	voxW = inW[p][q][r] <= 1 ? 1 : 0

	Wave w = root:mat
	w = voxW
	
	return(0)
end

// pass superW to this function, really just for the scaling...
// so I need to fix this in the future
//
// See https://en.wikipedia.org/w/index.php?title=Superquadrics&oldid=770878683
//
Function isInsideSuperQuadric(rr,ss,tt,aa,bb,cc)
	Variable rr,ss,tt,aa,bb,cc
	
	if(exists("root:mat") == 0)
		FFT_MakeMatrixButtonProc("")
	endif
		
	Duplicate/O root:mat inW, voxW
	Redimension/D inW
	Variable num=DimSize(inW, 0)
	SetScale/P x -(num/2),1,"",inW
	SetScale/P y -(num/2),1,"",inW
	SetScale/P z -(num/2),1,"",inW
	
	// using the wave scaling
	inW = ( abs(x/aa)^rr + abs(y/bb)^ss + abs(z/cc)^tt )
	voxW = inW[p][q][r] <= 1 ? 1 : 0

	Wave w = root:mat
	w = voxW
	
	return(0)
end


// pass superW to this function, really just for the scaling...
// so I need to fix this in the future
//
// this is a modified version of the superformula
//
// I have fixed a == b == 1. almost all examples have this, and the 
// equation goes haywire if you stray far from one. For ease in use with voxels,
// I've added aa,bb,cc as scaling values for x,y,z, in the same way it is done for the
// ellipsoid and qudric equations
//
//
// This could be further extended by using a separate set of parameters (m,n1,n2,n3) for
// r_phi and r_theta.
//
// The "m" values could also be different (m1, m2) for each r_ calculation.
//
Function isInsideSuperFormula(m,n1,n2,n3,aa,bb,cc)
	Variable m,n1,n2,n3,aa,bb,cc
	
	if(exists("root:mat") == 0)
		FFT_MakeMatrixButtonProc("")
	endif
		
	Duplicate/O root:mat inW, voxW
	Redimension/D inW
	Variable num=DimSize(inW, 0)
	SetScale/P x -(num/2),1,"",inW
	SetScale/P y -(num/2),1,"",inW
	SetScale/P z -(num/2),1,"",inW
	
	// using the wave scaling
	
	// calculate r
	// (not needed - calculate as part of asin()
	
	// calculate phi
	Duplicate/O inW phi
	phi = atan2(y,x)
	
	// calculate theta
	Duplicate/O inW theta
	theta = asin(z/sqrt(x^2+y^2+z^2))
	
	// calculate r(phi)
	Duplicate/O inW r_phi
//	r_phi = ( abs(1/aa*cos(m*phi/4))^n2+abs(1/bb*sin(m*phi/4))^n3 )^(-1/n1)
	r_phi = ( abs(cos(m*phi/4))^n2+abs(sin(m*phi/4))^n3 )^(-1/n1)
	
	// calculate r(theta)
	Duplicate/O inW r_theta
//	r_theta = ( abs(1/aa*cos(m*theta/4))^n2+abs(1/bb*sin(m*theta/4))^n3 )^(-1/n1)
	r_theta = ( abs(cos(m*theta/4))^n2+abs(sin(m*theta/4))^n3 )^(-1/n1)
		
	// evaluate for inside/outside
//	inW = (x/(r_theta*r_phi))^2 + (y/(r_theta*r_phi))^2 + (z/(r_theta))^2		// ?? add cc here to scale z
	inW = (x/(r_theta*r_phi*aa))^2 + (y/(r_theta*r_phi*bb))^2 + (z/(r_theta*cc))^2		// ?? add cc here to scale z
	
	voxW = inW[p][q][r] <= 1 ? 1 : 0

	Wave w = root:mat
	Redimension/B voxW
	w = voxW

	KillWaves/Z phi,theta,r_phi,r_theta	
	return(0)
end


//
// plots the voxelgram generated by isInsideSuperEllipse()
//
// execute mat = voxW, then the voxelgram can be FFT'd, or Debye's method
//
Proc Gizmo_superVox()
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(1810,345,2232,750)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo voxelgram=root:voxW,name=voxelgram0
	ModifyGizmo ModifyObject=voxelgram0,objectType=voxelgram,property={ valueRGBA,0,1,0.000015,0.195544,0.800000,0.100008}
	ModifyGizmo ModifyObject=voxelgram0,objectType=voxelgram,property={ mode,0}
	ModifyGizmo ModifyObject=voxelgram0,objectType=voxelgram,property={ pointSize,2}
	AppendToGizmo freeAxesCue={0,0,0,1},name=freeAxesCue0
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,ticks,3}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	AppendToGizmo light=Directional,name=light0
	ModifyGizmo modifyObject=light0,objectType=light,property={ position,0.514700,0.447400,-0.731400,0.000000}
	ModifyGizmo modifyObject=light0,objectType=light,property={ direction,0.514700,0.447400,-0.731400}
	ModifyGizmo modifyObject=light0,objectType=light,property={ ambient,0.933300,0.933300,0.933300,1.000000}
	ModifyGizmo modifyObject=light0,objectType=light,property={ specular,1.000000,1.000000,1.000000,1.000000}
	AppendToGizmo attribute blendFunc={770,771},name=blendFunc0
	ModifyGizmo setDisplayList=0, object=freeAxesCue0
	ModifyGizmo setDisplayList=1, object=light0
	ModifyGizmo setDisplayList=2, attribute=blendFunc0
	ModifyGizmo setDisplayList=3, object=voxelgram0
	ModifyGizmo setDisplayList=4, object=axes0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={1476,23,2293,321}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={0.140038,0.591077,0.776874,0.165764}
EndMacro



/////////////////////////////////////////////////////
/// below is from spherical harmonic demo -- and needs to be adapted to the SuperFormula

Function calcParametric(L,M,size)
	Variable L,M,size
	
	Make/O/N=(size+1,size+1,3) M_Parametric
	
	Variable i,j,dt,df,rr,theta,phi
	dt=pi/size
	df=2*dt
	
	SetScale/P x 0,1,"", M_Parametric
	SetScale/P y 0,1,"", M_Parametric
	
	for(i=0;i<=size;i+=1)
		theta=i*dt
		for(j=0;j<=size;j+=1)
			phi=j*df
			rr=sqrt(magsqr(sphericalHarmonics(L,m,theta,phi)))
			M_Parametric[i][j][0]=rr*sin(theta)*cos(phi)
			M_Parametric[i][j][1]=rr*sin(theta)*sin(phi)
			M_Parametric[i][j][2]=rr*cos(theta)
		endfor
	endfor
End

Function updateParamSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR LL,MM,resolution
	
	if(abs(MM)>LL)
		if(MM<0)
			MM=-LL
		else
			MM=LL
		endif
	endif
	
	calcParametric(LL,MM,resolution)
End


//// from another WM Demo
Function makeSphere(pointsx,pointsy)
	Variable pointsx,pointsy
	
	Variable i,j,rad
	Make/O/n=(pointsx,pointsy,3) sphereData
	Variable anglePhi,angleTheta
	Variable dPhi,dTheta
	
	
	dPhi=2*pi/(pointsx-1)
	dTheta=pi/(pointsy-1)
	Variable xx,yy,zz
	Variable sig
	
	for(j=0;j<pointsy;j+=1)
		angleTheta=j*dTheta
		zz=sin(angleTheta)
		if(angleTheta>pi/2)
			sig=-1
		else
			sig=1
		endif
		for(i=0;i<pointsx;i+=1)
			anglePhi=i*dPhi
			xx=zz*cos(anglePhi)
			yy=zz*sin(anglePhi)
			sphereData[i][j][0]=xx
			sphereData[i][j][1]=yy
			sphereData[i][j][2]=sig*sqrt(1-xx*xx-yy*yy)
//			sphereData[i][j][2]=sqrt(1-xx*xx-yy*yy)
		endfor
	endfor
End


//////////////////////////////////////////////////////////////////////////////////////////////
Function makeDoubleCone(pointsx,pointsy)
	Variable pointsx,pointsy
	
	Variable i,j,rad
	Make/O/n=(pointsx,pointsy,3) sphereData
	Variable anglePhi,angleTheta
	Variable dPhi,dTheta
	
	
	dPhi=2*pi/pointsx
	dTheta=pi/pointsy
	Variable xx,yy,zz
	
	for(j=0;j<pointsy;j+=1)
		angleTheta=j*dTheta
		zz=cos(angleTheta)
		for(i=0;i<pointsx;i+=1)
			anglePhi=i*dPhi
			xx=zz*cos(anglePhi)
			yy=zz*sin(anglePhi)
			sphereData[i][j][0]=xx
			sphereData[i][j][1]=yy
			sphereData[i][j][2]=zz
		endfor
	endfor
End

/////////////////////////////



////////////////////////////////////////////////
//
// another way to plot data as a cloud of points of an isosurface
// change the isoValue to plot a different surface
//
Proc Gizmo_Isosurface()
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(35,45,550,505)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo isoSurface=root:superW,name=isoSurface0
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ surfaceColorType,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineColorType,0}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineWidthType,0}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ fillMode,4}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineWidth,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ isoValue,30}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ frontColor,1,0,0,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ backColor,0,0,1,1}
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,ticks,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,ticks,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,ticks,2}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	AppendToGizmo freeAxesCue={0,0,0,1},name=freeAxesCue0
	ModifyGizmo setDisplayList=0, object=freeAxesCue0
	ModifyGizmo setDisplayList=1, object=axes0
	ModifyGizmo setDisplayList=2, object=isoSurface0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={551,23,1368,322}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={0.055218,0.485731,0.843569,0.222280}
EndMacro

//
// another cloud. would need a way to set the isoValue here as well, to pick the layer that is
// viewed
//
Proc mat_as_3dCloud() : GizmoPlot
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(35,45,550,505)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo isoSurface=root:mat,name=isoSurface0
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ surfaceColorType,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineColorType,0}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineWidthType,0}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ fillMode,4}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ lineWidth,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ isoValue,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ frontColor,1,0,0,1}
	ModifyGizmo ModifyObject=isoSurface0,objectType=isoSurface,property={ backColor,0,0,1,1}
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	AppendToGizmo freeAxesCue={0,0,0,1.5},name=freeAxesCue0
	AppendToGizmo voxelgram=root:mat,name=voxelgram0
	ModifyGizmo ModifyObject=voxelgram0,objectType=voxelgram,property={ valueRGBA,0,1,1.000000,0.000000,0.000000,1.000000}
	ModifyGizmo ModifyObject=voxelgram0,objectType=voxelgram,property={ mode,0}
	ModifyGizmo setDisplayList=0, object=axes0
	ModifyGizmo setDisplayList=1, object=freeAxesCue0
	ModifyGizmo setDisplayList=2, object=isoSurface0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={551,23,1368,322}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={0.205660,0.395226,0.765282,0.464591}
EndMacro


////////////////////////////////////////
//
// I have some of the 2D representations here for testing 
//
Function superFormula_2d(n1,n2,n3,n4,a1,a2)
	Variable n1,n2,n3,n4,a1,a2
	
	Variable np
	np=1000
	
	Make/O/D/N=(np) u,xx,yy,raux,rr
	u = (x/np)*(2*pi)
	
	raux=abs(1/a1*abs(cos(n1*u/4)))^n3+abs(1/a2*abs(sin(n1*u/4)))^n4
	rr=abs(raux)^(-1/n2)
	xx=rr*cos(u)
	yy=rr*sin(u)
 
	return(0)
end


Function is_2DPointInside(xPt,yPt)
	Variable xPt,yPt
	
	Variable uVal, rVal
	uVal = atan2(yPt,xPt) + pi
	rVal = xPt/cos(uVal)
	
//	Print uVal,rVal
	
	WAVE rr = root:rr
	WAVE u = root:u
	
	Variable val
	val = interp(uVal, u, rr )
//	Print val
	
	if( rval^2 > val^2)
//		Print "outside"
		return(0)
	else
//		Print "inside"
		return(1)
	endif
	
	return(0)
end

Function testInsideOutside(range)
	variable range
	Make/O/D/N=10000 testX, testY, testZ
	testX = enoise(-range,range)
	testY = enoise(-range,range)
	testZ = is_2DPointInside(-testx,-testy)		//not sure why, but it makes the graph correct
End

Window SF_2DGraph() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(1002,44,1607,594) yy vs xx
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph msize=1
EndMacro

Window SF_2D_InsideOutside() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(1616,44,2170,600) testY vs testX
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph msize=2
	ModifyGraph zColor(testY)={testz,*,*,Rainbow}
EndMacro


Window SF_2DGraph_overlay() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(1002,44,1607,594) testY vs testX
	AppendToGraph yy vs xx
	ModifyGraph mode=3
	ModifyGraph marker(testY)=16,marker(yy)=19
	ModifyGraph msize=2
	ModifyGraph zColor(testY)={testZ,*,*,BlueRedGreen256}
	Cursor/P A yy 1
	ShowInfo
EndMacro

//// end 2D versions
