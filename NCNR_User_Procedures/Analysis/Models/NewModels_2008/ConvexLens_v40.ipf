#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// calculates the scattering of a convex lens.
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
Proc PlotConvexLens(num,qmin,qmax)
	Variable num=100, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^1) for model: " 
	Prompt qmax "Enter maximum q-value (^1) for model: "
	//
	Make/O/D/n=(num) xwave_ConvLens, ywave_ConvLens
	xwave_ConvLens =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_ConvLens = {1,20,40,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_ConvLens = {"Scale Factor","cylinder radius rc (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_ConvLens, coef_ConvLens
	
	Variable/G root:g_ConvLens
	g_ConvLens := ConvexLens(coef_ConvLens, ywave_ConvLens, xwave_ConvLens)
	Display ywave_ConvLens vs xwave_ConvLens
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("ConvexLens","coef_ConvLens","parameters_ConvLens","ConvLens")
//
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedConvexLens(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ConvLens = {1,20,40,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_ConvLens = {"Scale Factor","cylinder radius rc (A)","end cap radius R >= rc (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_ConvLens,smear_coef_ConvLens					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_ConvLens,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_ConvLens							//
					
	Variable/G gs_ConvLens=0
	gs_ConvLens := fSmearedConvexLens(smear_coef_ConvLens,smeared_ConvLens,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_ConvLens vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedConvexLens","smear_coef_ConvLens","smear_parameters_ConvLens","ConvLens")
End

	

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function ConvexLens(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("ConvexLensX")
	yw = ConvexLensX(cw,xw)
#else
	yw = fConvexLens(cw,xw)
#endif
	return(0)
End

//
// - a double integral - choose points wisely - 76 for both...
//
Function fConvexLens(w,x) : FitFunc
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
//	len = w[2]
	endRad = w[2]
	sldc = w[3]
	slds = w[4]
	bkg = w[5]

	hDist = -1*sqrt(abs(endRad^2-rad^2))

	Make/O/D/N=7 CLens_tmp
	CLens_tmp[0] = w[0]
	CLens_tmp[1] = w[1]
	CLens_tmp[2] = 0.01		//length is some small number, essentially zero
	CLens_tmp[3] = w[2]
	CLens_tmp[4] = w[3]
	CLens_tmp[5] = w[4]
	CLens_tmp[6] = w[5]
		
	contr = sldc-slds
	
	Variable/G root:gDumTheta=0,root:gDumT=0
	
	inten = IntegrateFn76(ConvLens_Outer,0,pi/2,CLens_tmp,x)
	
	Variable hh=abs(hDist)		//need positive value for spherical cap volume
	inten /= 2*(1/3*pi*(endRad-hh)^2*(2*endRad+hh))		//divide by volume
	inten *= 1e8		//convert to cm^-1
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	Return (inten)
End

// outer integral
// x is the q-value
Function ConvLens_Outer(w,x,dum)
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
	retval = IntegrateFn76(ConvLens_Inner,-hDist/endRad,1,w,x)
	
	Variable arg1,arg2
	arg1 = x*len/2*cos(dum)
	arg2 = x*rad*sin(dum)
	
	retVal += pi*rad*rad*len*sinc(arg1)*2*Besselj(1, arg2)/arg2
	
	retVal *= retval*sin(dum)		// = |A(q)|^2*sin(theta)
	
	return(retVal)
End

//returns the value of the integrand of the inner integral
Function ConvLens_Inner(w,x,dum)
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
	
	retVal = ConvLens(w,x,dt,dTheta)
	
	retVal *= 4*pi*endRad^3
	
	return(retVal)
End

Function ConvLens(w,x,tt,Theta)
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
Function fSmearedConvexLens(coefW,yW,xW)
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
	err = SmearedConvexLens(fs)
	
	return (0)
End
		
// this is all there is to the smeared calculation!
//
// 20 points should be fine here. This function is not much different than cylinders, where 20 is sufficient
Function SmearedConvexLens(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(ConvexLens,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End