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

///  REQUIRES DANSE XOP for 2D FUNCTIONS

//
// the calculation is done as for the QxQy data set:
// three waves XYZ, then converted to a matrix
//
Proc PlotEllipticalCylinder2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)

	if (!exists("EllipticalCylinder_2DX"))
		Abort "You must have the SANSAnalysis XOP installed to use 2D models"
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	//make/O/T/N=14 parameters_EllCyl2D
	//Make/O/D/N=14 coef_EllCyl2D
	make/O/T/N=14 parameters_EllCyl2D
	Make/O/D/N=14 coef_EllCyl2D
	
	coef_EllCyl2D[0] = 1.0
	coef_EllCyl2D[1] = 20.0
	coef_EllCyl2D[2] = 1.5
	coef_EllCyl2D[3] = 400.0
	coef_EllCyl2D[4] = 3e-6
	coef_EllCyl2D[5] = 6.3e-6
	coef_EllCyl2D[6] = 0.0
	coef_EllCyl2D[7] = 1.57
	coef_EllCyl2D[8] = 0.0
	coef_EllCyl2D[9] = 0.0
	coef_EllCyl2D[10] = 0.0
	coef_EllCyl2D[11] = 0.0
	coef_EllCyl2D[12] = 0.0
	coef_EllCyl2D[13] = 0.0
	
	// now hard-wire the # of integration points
	//coef_EllCyl2D[14] = 25
		
	parameters_EllCyl2D[0] = "Scale"
	parameters_EllCyl2D[1] = "R_minor"
	parameters_EllCyl2D[2] = "R_ratio (major/minor)"
	parameters_EllCyl2D[3] = "Length"
	parameters_EllCyl2D[4] = "SLD cylinder (A^-2)"
	parameters_EllCyl2D[5] = "SLD solvent"
	parameters_EllCyl2D[6] = "Background"
	parameters_EllCyl2D[7] = "Axis Theta"
	parameters_EllCyl2D[8] = "Axis Phi"
	parameters_EllCyl2D[9] = "Ellipse Psi"
	parameters_EllCyl2D[10] = "Sigma of polydisp in R_minor [Angstrom]"
	parameters_EllCyl2D[11] = "Sigma of polydisp in R_ratio"
	parameters_EllCyl2D[12] = "Sigma of polydisp in Theta [rad]"
	parameters_EllCyl2D[13] = "Sigma of polydisp in Phi [rad]"
	//parameters_EllCyl2D[14] = "Num of polydisp points"
	
	Edit parameters_EllCyl2D,coef_EllCyl2D					
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_EllCyl2D
	Duplicate/O $(str+"_qy") ywave_EllCyl2D,zwave_EllCyl2D			
		
	Variable/G g_EllCyl2D=0
	g_EllCyl2D := EllipticalCylinder2D(coef_EllCyl2D,zwave_EllCyl2D,xwave_EllCyl2D,ywave_EllCyl2D)	//AAO 2D calculation
	
	Display ywave_EllCyl2D vs xwave_EllCyl2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_EllCyl2D)={zwave_EllCyl2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_EllCyl2D,ywave_EllCyl2D,zwave_EllCyl2D,"EllCyl2D_mat")
	Duplicate/O $"EllCyl2D_mat",$"EllCyl2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_EllCyl2Dmat=0
	g_EllCyl2Dmat := UpdateQxQy2Mat(xwave_EllCyl2D,ywave_EllCyl2D,zwave_EllCyl2D,EllCyl2D_lin,EllCyl2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("EllipticalCylinder2D","coef_EllCyl2D","parameters_EllCyl2D","EllCyl2D")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
//
// NON-THREADED IMPLEMENTATION
//
//Function EllipticalCylinder2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//#if exists("EllipticalCylinderModel_D")
//
//	Make/O/D/N=15 EllCyl2D_tmp
//	EllCyl2D_tmp = cw
//	EllCyl2D_tmp[14] = 25
//	
//	zw = EllipticalCylinderModel_D(EllCyl2D_tmp,xw,yw)
//	
////	zw = EllipticalCylinderModel_D(cw,xw,yw)
//#else
//	Abort "You do not have the SANS Analysis XOP installed"
//#endif
//	return(0)
//End
//

////threaded version of the function
//ThreadSafe Function EllipticalCylinder2D_T(cw,zw,xw,yw,p1,p2)
//	WAVE cw,zw,xw,yw
//	Variable p1,p2
//	
//#if exists("EllipticalCylinder_2DX")			//to hide the function if XOP not installed
//
//	Make/O/D/N=15 EllCyl2D_tmp
//	EllCyl2D_tmp = cw
//	EllCyl2D_tmp[14] = 25
//	EllCyl2D_tmp[6] = 0 		//pass in a zero background and add it in later
//	
//	zw[p1,p2]= EllipticalCylinder_2DX(EllCyl2D_tmp,xw,yw) + cw[6]
//	
//#endif
//
//	return 0
//End
//
////
////  Fit function that is actually a wrapper to dispatch the calculation to N threads
////
//// nthreads is 1 or an even number, typically 2
//// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
//// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
//// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
////
//Function EllipticalCylinder2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//	Variable npt=numpnts(yw)
//	Variable i,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
//	for(i=0;i<nthreads;i+=1)
//	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
//		ThreadStart mt,i,EllipticalCylinder2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
//	endfor
//
//	do
//		variable tgs= ThreadGroupWait(mt,100)
//	while( tgs != 0 )
//
//	variable dummy= ThreadGroupRelease(mt)
//	
//	return(0)
//End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// nthreads is 1 or an even number, typically 2
// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
//
Function EllipticalCylinder2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw
	
#if exists("EllipticalCylinder_2DX")			//to hide the function if XOP not installed

	Make/O/D/N=15 EllCyl2D_tmp
	EllCyl2D_tmp = cw
	EllCyl2D_tmp[14] = 25
	EllCyl2D_tmp[6] = 0 		//pass in a zero background and add it in later
	
	MultiThread zw= EllipticalCylinder_2DX(EllCyl2D_tmp,xw,yw) + cw[6]
	
#endif
	
	return(0)
End