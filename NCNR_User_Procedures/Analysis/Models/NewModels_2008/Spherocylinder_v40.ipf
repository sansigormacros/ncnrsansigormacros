#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// calculates the scattering of a spherocylinder, that is a cylinder with spherical end caps
// where the radius of the end caps is the same as the radius of the cylinder
//
// a double integral is used, both using Gaussian quadrature
// routines that are now included with GaussUtils
//
// 76 point quadrature is necessary for both quadrature calls.
//
//
// REFERENCE:
//		H. Kaya, J. Appl. Cryst. (2004) 37, 223-230.
//		H. Kaya and N-R deSouza, J. Appl. Cryst. (2004) 37, 508-509. (addenda and errata)
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotSpherocylinder(num,qmin,qmax)
	Variable num=100, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^1) for model: " 
	Prompt qmax "Enter maximum q-value (^1) for model: "
	//
	Make/O/D/n=(num) xwave_SphCyl, ywave_SphCyl
	xwave_SphCyl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_SphCyl = {1,20,400,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_SphCyl = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_SphCyl, coef_SphCyl
	
	Variable/G root:g_SphCyl
	g_SphCyl := Spherocylinder(coef_SphCyl, ywave_SphCyl, xwave_SphCyl)
	Display ywave_SphCyl vs xwave_SphCyl
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Spherocylinder","coef_SphCyl","parameters_SphCyl","SphCyl")
//
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSpherocylinder(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_SphCyl = {1,20,400,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_SphCyl = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_SphCyl,smear_coef_SphCyl					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_SphCyl,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_SphCyl							//
					
	Variable/G gs_SphCyl=0
	gs_SphCyl := fSmearedSpherocylinder(smear_coef_SphCyl,smeared_SphCyl,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_SphCyl vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSpherocylinder","smear_coef_SphCyl","smear_parameters_SphCyl","SphCyl")
End

	

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Spherocylinder(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("SpherocylinderX")
	yw = SpherocylinderX(cw,xw)
#else
	yw = fSpherocylinder(cw,xw)
#endif
	return(0)
End

//
// - a double integral - choose points wisely - 76 for both...
//
Function fSpherocylinder(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] cylinder radius (little r)
	//[2] cylinder length (big L)
	//[3] end cap radius (big R)
	//[4] sld cylinder (A^-2)
	//[5] sld solvent
	//[6] incoherent background (cm^-1)
//	give them nice names
	Variable scale,contr,bkg,inten,sldc,slds
	Variable len,rad,hDist,endRad
	scale = w[0]
	rad = w[1]
	len = w[2]
//	endRad = w[3]
	sldc = w[3]
	slds = w[4]
	bkg = w[5]
	
	Make/O/D/N=7 SphCyl_tmp
	SphCyl_tmp[0] = w[0]
	SphCyl_tmp[1] = w[1]
	SphCyl_tmp[2] = w[2]
	SphCyl_tmp[3] = w[1]		//end radius is same as cylinder radius
	SphCyl_tmp[4] = w[3]
	SphCyl_tmp[5] = w[4]
	SphCyl_tmp[6] = w[5]
	
	hDist = 0		//by definition
		
	contr = sldc-slds
	
	Variable/G root:gDumTheta=0,root:gDumT=0
	
	inten = IntegrateFn76(SphCyl_Outer,0,pi/2,SphCyl_tmp,x)
	
	inten /= pi*rad*rad*len + pi*4*endRad^3/3		//divide by volume
	inten *= 1e8		//convert to cm^-1
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	Return (inten)
End

// outer integral
// x is the q-value
Function SphCyl_Outer(w,x,dum)
	Wave w
	Variable x,dum
	
	Variable retVal
	Variable scale,contr,bkg,inten,sldc,slds
	Variable len,rad,hDist,endRad
	scale = w[0]
	rad = w[1]
	len = w[2]
	endRad = w[3]
	sldc = w[4]
	slds = w[5]
	bkg = w[6]

	hDist = 0
				
	NVAR dTheta = root:gDumTheta
	NVAR dt = root:gDumT
	dTheta = dum
	retval = IntegrateFn76(SphCyl_Inner,-hDist/endRad,1,w,x)
	
	Variable arg1,arg2
	arg1 = x*len/2*cos(dum)
	arg2 = x*rad*sin(dum)
	
	retVal += pi*rad*rad*len*sinc(arg1)*2*Besselj(1, arg2)/arg2
	
	retVal *= retval*sin(dum)		// = |A(q)|^2*sin(theta)
	
	return(retVal)
End

//returns the value of the integrand of the inner integral
Function SphCyl_Inner(w,x,dum)
	Wave w
	Variable x,dum
	
	Variable retVal
	Variable scale,contr,bkg,inten,sldc,slds
	Variable len,rad,hDist,endRad
	scale = w[0]
	rad = w[1]
	len = w[2]
	endRad = w[3]
	sldc = w[4]
	slds = w[5]
	bkg = w[6]
	
	NVAR dTheta = root:gDumTheta
	NVAR dt = root:gDumT
	dt = dum
	
	retVal = SphCyl(w,x,dt,dTheta)
	
	retVal *= 4*pi*endRad^3
	
	return(retVal)
End

Function SphCyl(w,x,tt,Theta)
	Wave w
	Variable x,tt,Theta
	
	Variable val,arg1,arg2
	Variable scale,contr,bkg,inten,sldc,slds
	Variable len,rad,hDist,endRad
	scale = w[0]
	rad = w[1]
	len = w[2]
	endRad = w[3]
	sldc = w[4]
	slds = w[5]
	bkg = w[6]
	
	hDist = 0
		
	arg1 = x*cos(theta)*(endRad*tt+hDist+len/2)
	arg2 = x*endRad*sin(theta)*sqrt(1-tt*tt)
	
	val = cos(arg1)*(1-tt*tt)*Besselj(1,arg2)/arg2
	
	return(val)
end

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSpherocylinder(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedSpherocylinder(fs)
	
	return (0)
End
		
// this is all there is to the smeared calculation!
//
// 20 points should be fine here. This function is not much different than cylinders, where 20 is sufficient
Function SmearedSpherocylinder(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Spherocylinder,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End