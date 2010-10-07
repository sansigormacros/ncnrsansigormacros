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
Proc PlotCylinder2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	if (!exists("Cylinder_2DX") )
		Abort "You must have the SANSAnalysis XOP installed to use 2D models"
	endif
	SetDataFolder $("root:"+str)
	
	// NOTE THAT THE COEFFICIENTS [N] ARE IN A DIFFERENT ORDER !!!
	// Setup parameter table for model function
//	make/O/T/N=11 parameters_Cyl2D
//	Make/O/D/N=11 coef_Cyl2D
	make/O/T/N=11 parameters_Cyl2D
	Make/O/D/N=11 coef_Cyl2D
	coef_Cyl2D[0] = 1.0
	coef_Cyl2D[1] = 20.0
	coef_Cyl2D[2] = 60.0
	coef_Cyl2D[3] = 1e-6
	coef_Cyl2D[4] = 6.3e-6
	coef_Cyl2D[5] = 0.0
	coef_Cyl2D[6] = 1.57
	coef_Cyl2D[7] = 0.0
	coef_Cyl2D[8] = 0.0
	coef_Cyl2D[9] = 0.0
	coef_Cyl2D[10] = 0.0
	
	// currently, the number of integration points is hard-wired to be 25 in Cylinder2D_T
	//coef_Cyl2D[11] = 25
	//
	parameters_Cyl2D[0] = "Scale"
	parameters_Cyl2D[1] = "Radius"
	parameters_Cyl2D[2] = "Length"
	parameters_Cyl2D[3] = "SLD cylinder (A^-2)"
	parameters_Cyl2D[4] = "SLD solvent"
	parameters_Cyl2D[5] = "Background"
	parameters_Cyl2D[6] = "Axis Theta"
	parameters_Cyl2D[7] = "Axis Phi"
	
	parameters_Cyl2D[9] = "Sigma of polydisp in Theta [rad]"		//*****
	parameters_Cyl2D[10] = "Sigma of polydisp in Phi [rad]"			//*****
	parameters_Cyl2D[8] = "Sigma of polydisp in Radius [A]"		//*****
	
//	parameters_Cyl2D[11] = "number of integration points"

	Edit parameters_Cyl2D,coef_Cyl2D					
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_Cyl2D
	Duplicate/O $(str+"_qy") ywave_Cyl2D,zwave_Cyl2D			
		
	Variable/G g_Cyl2D=0
	g_Cyl2D := Cylinder2D(coef_Cyl2D,zwave_Cyl2D,xwave_Cyl2D,ywave_Cyl2D)	//AAO 2D calculation
	
	Display ywave_Cyl2D vs xwave_Cyl2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_Cyl2D)={zwave_Cyl2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_Cyl2D,ywave_Cyl2D,zwave_Cyl2D,"Cyl2D_mat")
	Duplicate/O $"Cyl2D_mat",$"Cyl2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_Cyl2Dmat=0
	g_Cyl2Dmat := UpdateQxQy2Mat(xwave_Cyl2D,ywave_Cyl2D,zwave_Cyl2D,Cyl2D_lin,Cyl2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Cylinder2D","coef_Cyl2D","parameters_Cyl2D","Cyl2D")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
//
// NON-THREADED IMPLEMENTATION
//
//Function Cylinder2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//#if exists("CylinderModel_D")
//
//	Make/O/D/N=12 Cyl2D_tmp				// there seems to be no speed penalty for doing this...
//	Cyl2D_tmp = cw
//	Cyl2D_tmp[11] = 25					// hard-wire the number of integration points
//	
//	zw= CylinderModel_D(Cyl2D_tmp,xw,yw)
//
//	//zw = CylinderModel_D(cw,xw,yw)
//#else
//	Abort "You do not have the SANS Analysis XOP installed"
//#endif
//	return(0)
//End
//

////threaded version of the function
//ThreadSafe Function Cylinder2D_T(cw,zw,xw,yw,p1,p2)
//	WAVE cw,zw,xw,yw
//	Variable p1,p2
//	
//#if exists("Cylinder_2DX")			//to hide the function if XOP not installed
//
//	Make/O/D/N=12 Cyl2D_tmp				// there seems to be no speed penalty for doing this...
//	Cyl2D_tmp = cw
//	Cyl2D_tmp[11] = 25					// hard-wire the number of integration points
//	Cyl2D_tmp[5] = 0						// send a background of zero
//	
//	zw[p1,p2]= Cylinder_2DX(Cyl2D_tmp,xw,yw) + cw[5]		//add in the proper background here
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
//Function Cylinder2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//	Variable npt=numpnts(yw)
//	Variable ii,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
////	Variable t1=StopMSTimer(-2)
//	
//	for(ii=0;ii<nthreads;ii+=1)
//	//	Print (ii*npt/nthreads),((ii+1)*npt/nthreads-1)
//		ThreadStart mt,ii,Cylinder2D_T(cw,zw,xw,yw,(ii*npt/nthreads),((ii+1)*npt/nthreads-1))
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
//	return(0)
//End


/// now using the MultiThread keyword. as of Igor 6.20, the manual threading
// as above gives a wave read error (index out of range). Same code works fine in Igor 6.12
Function Cylinder2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw
	
	//	Variable t1=StopMSTimer(-2)

#if exists("Cylinder_2DX")			//to hide the function if XOP not installed

	Make/O/D/N=12 Cyl2D_tmp				// there seems to be no speed penalty for doing this...
	Cyl2D_tmp = cw
	Cyl2D_tmp[11] = 25					// hard-wire the number of integration points
	Cyl2D_tmp[5] = 0						// send a background of zero
	
	MultiThread zw = Cylinder_2DX(Cyl2D_tmp,xw,yw) + cw[5]		//add in the proper background here

#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
End