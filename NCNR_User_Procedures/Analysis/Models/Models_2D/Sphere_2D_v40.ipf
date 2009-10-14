#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
// The plotting macro sets up TWO dependencies
// - one for the triplet calculation
// - one for a matrix to display, a copy of the triplet
//
// For display, there are two copies of the matrix. One matrix is linear, and is a copy of the 
// triplet (which is ALWAYS linear). The other matrix is toggled log/lin for display
// in the same way the 2D SANS data matrix is handled.
//

///  REQUIRES XOP for 2D FUNCTIONS

//
// the calculation is done as for the QxQy data set:
// three waves XYZ, then converted to a matrix
//
Proc PlotSphere2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	SetDataFolder $("root:"+str)
	
	Make/O/D coef_sf2D = {1.,60,1e-6,6.3e-6,0.01}						
	make/o/t parameters_sf2D = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent","bkgd (cm-1)"}		
	Edit parameters_sf2D,coef_sf2D				
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_sf2D
	Duplicate/O $(str+"_qy") ywave_sf2D,zwave_sf2D			
		
	Variable/G g_sf2D=0
	g_sf2D := Sphere2D(coef_sf2D,zwave_sf2D,xwave_sf2D,ywave_sf2D)	//AAO 2D calculation
	
	Display ywave_sf2D vs xwave_sf2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_sf2D)={zwave_sf2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_sf2D,ywave_sf2D,zwave_sf2D,"sf2D_mat")
	Duplicate/O $"sf2D_mat",$"sf2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_sf2Dmat=0
	g_sf2Dmat := UpdateQxQy2Mat(xwave_sf2D,ywave_sf2D,zwave_sf2D,sf2D_lin,sf2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Sphere2D","coef_sf2D","parameters_sf2D","sf2D")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere2D(str)								
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
//	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
//		Abort
//	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sf2D = {1.,60,1e-6,6.3e-6,0.01}					
	make/o/t smear_parameters_sf2D = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit smear_parameters_sf2D,smear_coef_sf2D					
	
	Duplicate/O $(str+"_qx") smeared_sf2D	//1d place for the smeared model
	SetScale d,0,0,"1/cm",smeared_sf2D					
		
	Variable/G gs_sf2D=0
	gs_sf2D := fSmearedSphere2D(smear_coef_sf2D,smeared_sf2D)	//this wrapper fills the STRUCT

	Display $(str+"_qy") vs $(str+"_qx")
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor($(str+"_qy"))={smeared_sf2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	Duplicate/O $(str+"_qx"), sm_qx
	Duplicate/O $(str+"_qy"), sm_qy		// I can't use local variables in dependencies, so I need the name (that I can't get)
	
	ConvertQxQy2Mat(sm_qx,sm_qy,smeared_sf2D,"sm_sf2D_mat")
	Duplicate/O $"sm_sf2D_mat",$"sm_sf2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G gs_sf2Dmat=0
	gs_sf2Dmat := UpdateQxQy2Mat(sm_qx,sm_qy,smeared_sf2D,sm_sf2D_lin,sm_sf2D_mat)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere2D","smear_coef_sf2D","smear_parameters_sf2D","sf2D")
End


//threaded version of the function
ThreadSafe Function Sphere2D_T(cw,zw,xw,yw,p1,p2)
	WAVE cw,zw,xw,yw
	Variable p1,p2
	
#if exists("Sphere_2DX")			//to hide the function if XOP not installed
	
	zw[p1,p2]= Sphere_2DX(cw,xw,yw)

#endif

	return 0
End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// nthreads is 1 or an even number, typically 2
// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
//
Function Sphere2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw


#if exists("Sphere_2DX")			//to hide the function if XOP not installed
	
	MultiThread 	zw= Sphere_2DX(cw,xw,yw)

#endif

//	Variable npt=numpnts(yw)
//	Variable i,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
////	Variable t1=StopMSTimer(-2)
//	
//	for(i=0;i<nthreads;i+=1)
//	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
//		ThreadStart mt,i,Sphere2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
//	endfor
//
//	do
//		variable tgs= ThreadGroupWait(mt,100)
//	while( tgs != 0 )
//
//	variable dummy= ThreadGroupRelease(mt)
//	
////	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
//	
	return(0)
End


//non-threaded version of the function
Function Sphere2D_noThread(cw,zw,xw,yw)
	WAVE cw,zw, xw,yw
	
#if exists("Sphere_2DX")			//to hide the function if XOP not installed
	
	zw= Sphere_2DX(cw,xw,yw)

#endif

	return 0
End

// I think I did this because when I do the quadrature loops I'm calling the AAO with 1-pt waves, so threading
// would just be a slowdown
Function SmearedSphere2D(s)
	Struct ResSmear_2D_AAOStruct &s
	
	Smear_2DModel_5(Sphere2D_noThread,s)
//	Smear_2DModel_20(Sphere2D_noThread,s)
	return(0)
end


Function fSmearedSphere2D(coefW,resultW)
	Wave coefW,resultW
	
	String str = getWavesDataFolder(resultW,0)
	String DF="root:"+str+":"
	
	WAVE qx = $(DF+str+"_qx")
	WAVE qy = $(DF+str+"_qy")
	WAVE qz = $(DF+str+"_qz")
	WAVE sigQx = $(DF+str+"_sigQx")
	WAVE sigQy = $(DF+str+"_sigQy")
	WAVE shad = $(DF+str+"_fs")
	
	STRUCT ResSmear_2D_AAOStruct s
	WAVE s.coefW = coefW	
	WAVE s.zw = resultW	
	WAVE s.qx = qx
	WAVE s.qy = qy
	WAVE s.qz = qz
	WAVE s.sigQx = sigQx
	WAVE s.sigQy = sigQy
	WAVE s.fs = shad
	
	Variable err
	err = SmearedSphere2D(s)
	
	return (0)
End