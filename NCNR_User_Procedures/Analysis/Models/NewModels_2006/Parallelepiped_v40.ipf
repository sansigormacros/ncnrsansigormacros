#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////////
//
// calculates the scattering from a rectangular solid
// i.e. a parallelepiped with sides a < b < c
// 
// - the user must make sure that the constraints are not violated
// otherwise the calculation will not be correct
//
// From: Mittelbach and Porod, Acta Phys. Austriaca 14 (1961) 185-211.
//				equations (1), (13), and (14) (in German!)
//
// note that the equations listed in Feigin and Svergun appears
// to be wrong - they use equation (12), which does not appear to 
// be a complete orientational average (?)
//
// a double integral is used, both using Gaussian quadrature
// routines that are now included with GaussUtils
// 20-pt quadrature appears to be enough, 76 pt is available
// by changing the function calls
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotParallelepiped(num,qmin,qmax)
	Variable num=100, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
	//
	Make/O/D/n=(num) xwave_Parallelepiped, ywave_Parallelepiped
	xwave_Parallelepiped =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Parallelepiped = {1,35,75,400,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_Parallelepiped = {"Scale Factor","Shortest Edge A (A)","B (A)","Longest Edge C (A)","SLD particle (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_Parallelepiped, coef_Parallelepiped
	
	Variable/G root:g_Parallelepiped
	g_Parallelepiped := Parallelepiped(coef_Parallelepiped,ywave_Parallelepiped, xwave_Parallelepiped)
	Display ywave_Parallelepiped vs xwave_Parallelepiped
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Parallelepiped","coef_Parallelepiped","parameters_Parallelepiped","Parallelepiped")
//
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedParallelepiped(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Parallelepiped = {1,35,75,400,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_Parallelepiped = {"Scale Factor","Shortest Edge A (A)","B (A)","Longest Edge C (A)","SLD particle (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_Parallelepiped,smear_coef_Parallelepiped					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Parallelepiped,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_Parallelepiped							//
					
	Variable/G gs_Parallelepiped=0
	gs_Parallelepiped := fSmearedParallelepiped(smear_coef_Parallelepiped,smeared_Parallelepiped,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_Parallelepiped vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedParallelepiped","smear_coef_Parallelepiped","smear_parameters_Parallelepiped","Parallelepiped")
End



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Parallelepiped(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("ParallelepipedX")
	MultiThread yw = ParallelepipedX(cw,xw)
#else
	yw = fParallelepiped(cw,xw)
#endif
	return(0)
End

// calculates the form factor of a rectangular solid
// - a double integral - choose points wisely
//
Function fParallelepiped(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//[0] scale factor
	//[1] Edge A (A)
	//[2] Edge B (A)
	//[3] Edge C (A)
	//[4] contrast (A^-2)
	//[5] incoherent background (cm^-1)
//	give them nice names
	Variable scale,aa,bb,cc,contr,bkg,inten,qq,ii,arg,mu,sldp,slds
	scale = w[0]
	aa = w[1]
	bb = w[2]
	cc = w[3]
	sldp = w[4]
	slds = w[5]
	bkg = w[6]
	
	contr = sldp - slds
//	mu = bb*x		//scale in terms of B
//	aa = aa/bb
//	cc = cc/bb
	
	inten = IntegrateFn20(PP_Outer,0,1,w,x)
//	inten = IntegrateFn76(PP_Outer,0,1,w,x)
	
	inten *= aa*cc*bb		//multiply by volume
	inten *= 1e8		//convert to cm^-1
	inten *= contr*contr
	inten *= scale
	inten += bkg
	
	Return (inten)
End

// outer integral

// x is the q-value - remember that "mu" in the notation = B*Q
Function PP_Outer(w,x,dum)
	Wave w
	Variable x,dum
	
	Variable retVal,mu,aa,bb,cc,mudum,arg
	aa = w[1]
	bb = w[2]
	cc = w[3]
	mu = bb*x
	
	mudum = mu*sqrt(1-dum^2)
	retval = IntegrateFn20(PP_inner,0,1,w,mudum)
//	retval = IntegrateFn76(PP_inner,0,1,w,mudum)
	
	cc = cc/bb
	arg = mu*cc*dum/2
	if(arg==0)
		retval *= 1
	else
		retval *= sin(arg)*sin(arg)/arg/arg
	endif
	
	return(retVal)
End

//returns the integrand of the inner integral
Function PP_Inner(w,mu,uu)
	Wave w
	Variable mu,uu
	
	Variable aa,bb,retVal,arg1,arg2,tmp1,tmp2
	
	//NVAR mu = root:gEvalQval		//already has been converted to S=2*pi*q
	aa = w[1]
	bb = w[2]
	aa = aa/bb
	
	//Mu*(1-x^2)^(0.5)
	
	//handle arg=0 separately, as sin(t)/t -> 1 as t->0
	arg1 = (mu/2)*cos(Pi*uu/2)
	arg2 = (mu*aa/2)*sin(Pi*uu/2)
	if(arg1==0)
		tmp1 = 1
	else
		tmp1 = sin(arg1)*sin(arg1)/arg1/arg1
	endif
	if(arg2==0)
		tmp2 = 1
	else
		tmp2 = sin(arg2)*sin(arg2)/arg2/arg2
	endif
	retval = tmp1*tmp2
	
	return(retVal)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedParallelepiped(coefW,yW,xW)
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
	err = SmearedParallelepiped(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedParallelepiped(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Parallelepiped,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End



////////////For testing

Proc PP_Rg_and_IZero()

	variable rg2,iz
	
	iz = coef_Parallelepiped[0]
	iz *= coef_Parallelepiped[1]*coef_Parallelepiped[2]*coef_Parallelepiped[3]
	iz *= (coef_Parallelepiped[4]-coef_Parallelepiped[5])^2
	iz -= coef_Parallelepiped[6]
	iz *= 1e8
	
	
	rg2 = coef_Parallelepiped[1]^2
	rg2 += coef_Parallelepiped[2]^2
	rg2 += coef_Parallelepiped[3]^2
	rg2 /= 12
	
	
	Print "I(q=0) [cm^-1] = ",iz
	Print "Rg [A] = ",sqrt(rg2)
end