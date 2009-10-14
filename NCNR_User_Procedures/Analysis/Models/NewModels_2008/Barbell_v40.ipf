#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////////
//
// calculates the scattering of a "barbell" shape - a cylinder with spherical end caps
// of larger radius than the radius of the cylinder
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
Proc PlotBarbell(num,qmin,qmax)
	Variable num=100, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^1) for model: " 
	Prompt qmax "Enter maximum q-value (^1) for model: "
	//
	Make/O/D/n=(num) xwave_Barbell, ywave_Barbell
	xwave_Barbell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Barbell = {1,20,400,40,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_Barbell = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_Barbell, coef_Barbell
	
	Variable/G root:g_Barbell
	g_Barbell := Barbell(coef_Barbell, ywave_Barbell, xwave_Barbell)
	Display ywave_Barbell vs xwave_Barbell
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Barbell","coef_Barbell","parameters_Barbell","Barbell")
//
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedBarbell(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Barbell = {1,20,400,40,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_Barbell = {"Scale Factor","cylinder radius rc (A)","cylinder length (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Barbell,smear_coef_Barbell					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Barbell,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Barbell							//
					
	Variable/G gs_Barbell=0
	gs_Barbell := fSmearedBarbell(smear_coef_Barbell,smeared_Barbell,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_Barbell vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedBarbell","smear_coef_Barbell","smear_parameters_Barbell","Barbell")
End

	

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Barbell(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BarbellX")
	MultiThread yw = BarbellX(cw,xw)
#else
	yw = fBarbell(cw,xw)
#endif
	return(0)
End

//
// - a double integral - choose points wisely - 76 for both...
//
Function fBarbell(w,x) : FitFunc
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
	
	hDist = sqrt(endRad^2-rad^2)	
		
	contr = sldc-slds
	
	Variable/G root:gDumTheta=0,root:gDumT=0
	
	inten = IntegrateFn76(Barbell_Outer,0,pi/2,w,x)
	
	inten /= pi*rad*rad*len + 2*pi*(2*endRad^3/3+endRad^2*hDist-hDist^3/3)		//divide by volume
	inten *= 1e8		//convert to cm^-1
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	Return (inten)
End

// outer integral
// x is the q-value
Function Barbell_Outer(w,x,dum)
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

	hDist = sqrt(endRad^2-rad^2)	
			
	NVAR dTheta = root:gDumTheta
	NVAR dt = root:gDumT
	dTheta = dum
	retval = IntegrateFn76(Barbell_Inner,-hDist/endRad,1,w,x)
	
	Variable arg1,arg2
	arg1 = x*len/2*cos(dum)
	arg2 = x*rad*sin(dum)
	
	retVal += pi*rad*rad*len*sinc(arg1)*2*Besselj(1, arg2)/arg2
	
	retVal *= retval*sin(dum)		// = |A(q)|^2*sin(theta)
	
	return(retVal)
End

//returns the value of the integrand of the inner integral
Function Barbell_Inner(w,x,dum)
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
	
	retVal = Barbell_integrand(w,x,dt,dTheta)
	
	retVal *= 4*pi*endRad^3
	
	return(retVal)
End

Function Barbell_integrand(w,x,tt,Theta)
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

	hDist = sqrt(endRad^2-rad^2)	
		
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
Function fSmearedBarbell(coefW,yW,xW)
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
	err = SmearedBarbell(fs)
	
	return (0)
End
		
// this is all there is to the smeared calculation!
//
// 20 points should be fine here. This function is not much different than cylinders, where 20 is sufficient
Function SmearedBarbell(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Barbell,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End