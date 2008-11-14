#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// calculates the scattering of a "capped cylinder" with "flat" spherical end caps
// where the radius of the end cap is larger than the radius of the cylinder.
// The center of the spherical end caps is within the length of the cylinder.
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
Proc PlotCappedCylinder(num,qmin,qmax)
	Variable num=100, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^1) for model: " 
	Prompt qmax "Enter maximum q-value (^1) for model: "
	//
	Make/O/D/n=(num) xwave_CapCyl, ywave_CapCyl
	xwave_CapCyl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CapCyl = {1,20,400,40,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_CapCyl = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_CapCyl, coef_CapCyl
	
	Variable/G root:g_CapCyl
	g_CapCyl := CappedCylinder(coef_CapCyl, ywave_CapCyl, xwave_CapCyl)
	Display ywave_CapCyl vs xwave_CapCyl
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CappedCylinder","coef_CapCyl","CapCyl")
//
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCappedCylinder(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CapCyl = {1,20,400,40,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_CapCyl = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_CapCyl,smear_coef_CapCyl					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CapCyl,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_CapCyl							//
					
	Variable/G gs_CapCyl=0
	gs_CapCyl := fSmearedCappedCylinder(smear_coef_CapCyl,smeared_CapCyl,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CapCyl vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCappedCylinder","smear_coef_CapCyl","CapCyl")
End

	

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function CappedCylinder(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("CappedCylinderX")
	yw = CappedCylinderX(cw,xw)
#else
	yw = fCappedCylinder(cw,xw)
#endif
	return(0)
End

//
// - a double integral - choose points wisely - 76 for both...
//
Function fCappedCylinder(w,x) : FitFunc
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
	endRad = w[3]
	sldc = w[4]
	slds = w[5]
	bkg = w[6]

	hDist = -1*sqrt(abs(endRad^2-rad^2))
		
	contr = sldc-slds
	
	Variable/G root:gDumTheta=0,root:gDumT=0
	
	inten = IntegrateFn76(CapCyl_Outer,0,pi/2,w,x)
	
	Variable hh=abs(hdist)		//need a positive h for the volume of the spherical section
	inten /= pi*rad*rad*len + 2*(1/3*pi*(endRad-hh)^2*(2*endRad+hh))		//divide by volume
	inten *= 1e8		//convert to cm^-1
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	Return (inten)
End

// outer integral
// x is the q-value
Function CapCyl_Outer(w,x,dum)
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

	hDist = -1*sqrt(abs(endRad^2-rad^2))
			
	NVAR dTheta = root:gDumTheta
	NVAR dt = root:gDumT
	dTheta = dum
	retval = IntegrateFn76(CapCyl_Inner,-hDist/endRad,1,w,x)
	
	Variable arg1,arg2
	arg1 = x*len/2*cos(dum)
	arg2 = x*rad*sin(dum)
	
	retVal += pi*rad*rad*len*sinc(arg1)*2*Besselj(1, arg2)/arg2
	
	retVal *= retval*sin(dum)		// = |A(q)|^2*sin(theta)
	
	return(retVal)
End

//returns the value of the integrand of the inner integral
Function CapCyl_Inner(w,x,dum)
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
	
	retVal = CapCyl(w,x,dt,dTheta)
	
	retVal *= 4*pi*endRad^3
	
	return(retVal)
End

Function CapCyl(w,x,tt,Theta)
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

	hDist = -1*sqrt(abs(endRad^2-rad^2))
		
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
Function fSmearedCappedCylinder(coefW,yW,xW)
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
	err = SmearedCappedCylinder(fs)
	
	return (0)
End
		
// this is all there is to the smeared calculation!
//
// 20 points should be fine here. This function is not much different than cylinders, where 20 is sufficient
Function SmearedCappedCylinder(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(CappedCylinder,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
