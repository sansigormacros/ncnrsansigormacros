#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0

Proc ShowCylinderOrientation()
	Gizmo1()
end

Window Gizmo1() : GizmoPlot
	PauseUpdate; Silent 1	// Building Gizmo 6 window...

	// Do nothing if the Gizmo XOP is not available.
	if(exists("NewGizmo")!=4)
		DoAlert 0, "Gizmo XOP must be installed"
		return
	endif

	NewGizmo/N=ObjOrient/T="Object Orientation" /K=1 /W=(953,158,1318,524)
	ModifyGizmo startRecMacro
	AppendToGizmo Axes=CustomAxis,name=axes0
	ModifyGizmo ModifyObject=axes0,property={0,axisRange,0,0,-1,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={0,lineWidth,15}
	ModifyGizmo ModifyObject=axes0,property={0,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,property={0,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={0,axisMinValue,-1}
	ModifyGizmo ModifyObject=axes0,property={0,axisMaxValue,1}
	AppendToGizmo Axes=boxAxes,name=axes1
	ModifyGizmo ModifyObject=axes1,property={-1,axisMode,1}
	ModifyGizmo ModifyObject=axes1,property={0,gridType,1}
	ModifyGizmo ModifyObject=axes1,property={0,gridPlaneColor,0.719997,0.719997,0.719997,1}
	ModifyGizmo ModifyObject=axes1,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes1,property={-1,axisColor,0,0,0,1}
	AppendToGizmo attribute color={0,0.244,1,1},name=color0
	AppendToGizmo attribute ambient={1,1,1,1,1032},name=ambient0
	ModifyGizmo setDisplayList=0, object=axes0
	ModifyGizmo setDisplayList=1, object=axes1
	ModifyGizmo SETQUATERNION={-0.105935,0.419811,0.039369,0.900544}
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo compile

	ModifyGizmo bringToFront
	ModifyGizmo hookFunction=GizmoRotationHook
	ModifyGizmo showAxisCue=1
	ModifyGizmo endRecMacro
End



// angles are input in degrees
Proc ChangeAngle(theta,phi)
	Variable theta,phi
	Prompt theta,"THETA in degrees"
	Prompt phi, "PHI in degrees"
	
	Variable dx,dy,dz
	
	theta = theta/360*2*pi
	phi = phi/360*2*pi
	
	Print "theta, phi in radians = ",theta,phi
	
	dx = sin(theta)*cos(phi)
	dy = sin(theta)*sin(phi)
	dz = cos(theta)
	
	Print "Unit vector dx,dy,dz = ",dx,dy,dz
	ModifyGizmo/N=ObjOrient ModifyObject=axes0,property={0,axisRange,-dx,-dy,-dz,dx,dy,dz}
end

//Window Gizmo0() : GizmoPlot
//	PauseUpdate; Silent 1	// Building Gizmo 6 window...
//
//	// Do nothing if the Gizmo XOP is not available.
//	if(exists("NewGizmo")!=4)
//		DoAlert 0, "Gizmo XOP must be installed"
//		return
//	endif
//
//	NewGizmo/N=Gizmo0/T="Gizmo0" /W=(679,232,937,496)
//	ModifyGizmo startRecMacro
//	AppendToGizmo Axes=boxAxes,name=axes0
//	ModifyGizmo ModifyObject=axes0,property={-1,axisMode,1}
//	ModifyGizmo ModifyObject=axes0,property={0,gridType,1}
//	ModifyGizmo ModifyObject=axes0,property={0,gridPlaneColor,0.719997,0.719997,0.719997,1}
//	ModifyGizmo ModifyObject=axes0,property={-1,axisScalingMode,1}
//	ModifyGizmo ModifyObject=axes0,property={-1,axisColor,0,0,0,1}
//	AppendToGizmo cylinder={0.05,0.05,1,10,10},name=cylinder0
//	AppendToGizmo attribute color={0,0.244,1,1},name=color0
//	AppendToGizmo attribute ambient={1,1,1,1,1032},name=ambient0
//	ModifyGizmo setDisplayList=0, object=axes0
//	ModifyGizmo setDisplayList=1, opName=rotate0, operation=rotate, data={10,1,0,0}
//	ModifyGizmo setDisplayList=2, opName=rotate1, operation=rotate, data={45,0,1,0}
//	ModifyGizmo setDisplayList=3, opName=translate0, operation=translate, data={0,0,-0.5}
//	ModifyGizmo setDisplayList=4, attribute=color0
//	ModifyGizmo setDisplayList=5, object=cylinder0
//	ModifyGizmo SETQUATERNION={-0.135609,0.238706,0.084163,0.957887}
//	ModifyGizmo autoscaling=1
//	ModifyGizmo currentGroupObject=""
//	ModifyGizmo compile
//
//	ModifyGizmo showInfo
//	ModifyGizmo infoWindow={156,382,646,561}
//	ModifyGizmo bringToFront
//	ModifyGizmo hookFunction=GizmoRotationHook
//	ModifyGizmo showAxisCue=1
//	ModifyGizmo endRecMacro
//End