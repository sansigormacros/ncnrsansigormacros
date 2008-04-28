#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0

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
		
	Variable/G gs_sf2D=0
	gs_sf2D := Sphere2D(coef_sf2D,zwave_sf2D,xwave_sf2D,ywave_sf2D)	//AAO 2D calculation
	
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
	Variable/G gs_sf2Dmat=0
	gs_sf2Dmat := UpdateQxQy2Mat(xwave_sf2D,ywave_sf2D,zwave_sf2D,sf2D_lin,sf2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Sphere2D","coef_sf2D","sf2D")
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
	
	Variable npt=numpnts(yw)
	Variable i,nthreads= ThreadProcessorCount
	variable mt= ThreadGroupCreate(nthreads)

//	Variable t1=StopMSTimer(-2)
	
	for(i=0;i<nthreads;i+=1)
	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
		ThreadStart mt,i,Sphere2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
	endfor

	do
		variable tgs= ThreadGroupWait(mt,100)
	while( tgs != 0 )

	variable dummy= ThreadGroupRelease(mt)
	
//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
End