#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
// !!! FOR THE ELLIPSOID, THE ANGLE THETA IS DEFINED FROM ????
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
Proc PlotEllipsoid2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)

	if (!exists("Ellipsoid_2DX"))
		Abort "You must have the SANSAnalysis XOP installed to use 2D models"
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
//	make/O/T/N=12 parameters_Ellip2D
//	Make/O/D/N=12 coef_Ellip2D
	make/O/T/N=12 parameters_Ellip2D
	Make/O/D/N=12 coef_Ellip2D
	
	coef_Ellip2D[0] = 1.0
	coef_Ellip2D[1] = 20.0
	coef_Ellip2D[2] = 60.0
	coef_Ellip2D[3] = 1.0e-6
	coef_Ellip2D[4] = 6.3e-6
	coef_Ellip2D[5] = 0.0
	coef_Ellip2D[6] = 1.57
	coef_Ellip2D[7] = 0.0
	coef_Ellip2D[8] = 0.0
	coef_Ellip2D[9] = 0.0
	coef_Ellip2D[10] = 0.0
	coef_Ellip2D[11] = 0.0
	// hard-wire the number of integration points
//	coef_Ellip2D[12] = 10
	
	parameters_Ellip2D[0] = "Scale"
	parameters_Ellip2D[1] = "Radius_a (rotation axis)"
	parameters_Ellip2D[2] = "Radius_b"
	parameters_Ellip2D[3] = "SLD cylinder (A^-2)"
	parameters_Ellip2D[4] = "SLD solvent"
	parameters_Ellip2D[5] = "Background"
	parameters_Ellip2D[6] = "Axis Theta"
	parameters_Ellip2D[7] = "Axis Phi"
	parameters_Ellip2D[8] = "Sigma of polydisp in R_a [Angstrom]"
	parameters_Ellip2D[9] = "Sigma of polydisp in R_b [Angstrom]"
	parameters_Ellip2D[10] = "Sigma of polydisp in Theta [rad]"
	parameters_Ellip2D[11] = "Sigma of polydisp in Phi [rad]"
	
//	parameters_Ellip2D[12] = "Num of polydisp points"

	
	Edit parameters_Ellip2D,coef_Ellip2D					
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_Ellip2D
	Duplicate/O $(str+"_qy") ywave_Ellip2D,zwave_Ellip2D			
		
	Variable/G g_Ellip2D=0
	g_Ellip2D := Ellipsoid2D(coef_Ellip2D,zwave_Ellip2D,xwave_Ellip2D,ywave_Ellip2D)	//AAO 2D calculation
	
	Display ywave_Ellip2D vs xwave_Ellip2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_Ellip2D)={zwave_Ellip2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_Ellip2D,ywave_Ellip2D,zwave_Ellip2D,"Ellip2D_mat")
	Duplicate/O $"Ellip2D_mat",$"Ellip2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_Ellip2Dmat=0
	g_Ellip2Dmat := UpdateQxQy2Mat(xwave_Ellip2D,ywave_Ellip2D,zwave_Ellip2D,Ellip2D_lin,Ellip2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Ellipsoid2D","coef_Ellip2D","parameters_Ellip2D","Ellip2D")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
//
// NON-THREADED IMPLEMENTATION
//
//Function Ellipsoid2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//#if exists("EllipsoidModel_D")
//
//	Make/O/D/N=13 Ellip2D_tmp
//	Ellip2D_tmp = cw
//	Ellip2D_tmp[12] = 25
//	
//	zw = EllipsoidModel_D(Ellip2D_tmp,xw,yw)
//	
////	zw = EllipsoidModel_D(cw,xw,yw)
//#else
//	Abort "You do not have the SANS Analysis XOP installed"
//#endif
//	return(0)
//End
////
//
////threaded version of the function
//ThreadSafe Function Ellipsoid2D_T(cw,zw,xw,yw,p1,p2)
//	WAVE cw,zw,xw,yw
//	Variable p1,p2
//	
//#if exists("Ellipsoid_2DX")			//to hide the function if XOP not installed
//
//	Make/O/D/N=13 Ellip2D_tmp
//	Ellip2D_tmp = cw
//	Ellip2D_tmp[12] = 25
//	Ellip2D_tmp[5] = 0		//pass in a zero background and add it in later
//	
//	zw[p1,p2]= Ellipsoid_2DX(Ellip2D_tmp,xw,yw) + cw[5]
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
//Function Ellipsoid2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//	Variable npt=numpnts(yw)
//	Variable i,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
//	for(i=0;i<nthreads;i+=1)
//	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
//		ThreadStart mt,i,Ellipsoid2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
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
Function Ellipsoid2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw
	
#if exists("Ellipsoid_2DX")			//to hide the function if XOP not installed

	Make/O/D/N=13 Ellip2D_tmp
	Ellip2D_tmp = cw
	Ellip2D_tmp[12] = 25
	Ellip2D_tmp[5] = 0		//pass in a zero background and add it in later
	
	MultiThread zw= Ellipsoid_2DX(Ellip2D_tmp,xw,yw) + cw[5]
	
#endif
	
	return(0)
End