#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this function is for the form factor of an ellipsoid of rotation with uniform scattering length density
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotEllipsoidForm(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_eor,ywave_eor
	xwave_eor =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_eor = {1.,20.,400,1e-6,6.3e-6,0.01}
	make/o/t parameters_eor = {"scale","R a (rotation axis) (A)","R b (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_eor,coef_eor
	Variable/G root:g_eor
	g_eor := EllipsoidForm(coef_eor,ywave_eor,xwave_eor)
//	ywave_eor := EllipsoidForm(coef_eor,xwave_eor)
	Display ywave_eor vs xwave_eor
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("EllipsoidForm","coef_eor","parameters_eor","eor")
End
///////////////////////////////////////////////////////////

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedEllipsoidForm(str)	
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissingDF(str))
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_eor = {1.,20.,400,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_eor = {"scale","R a (rotation axis) (A)","R b (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_eor,smear_coef_eor
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_eor,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_eor	

	Variable/G gs_eor=0
	gs_eor := fSmearedEllipsoidForm(smear_coef_eor,smeared_eor,smeared_qvals)
	
	Display smeared_eor vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedEllipsoidForm","smear_coef_eor","smear_parameters_eor","eor")
End

//AAO version
Function EllipsoidForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("EllipsoidFormX")
	MultiThread yw = EllipsoidFormX(cw,xw)
#else
	yw = fEllipsoidForm(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fEllipsoidForm(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] Axis of rotation
	//[2] two equal radii
	//[3] sld ellipsoid
	//[3] sld solvent (A^-2)
	//[4] background (cm^-1)
	Variable scale, ra,vra,delrho,bkg,slde,slds
	scale = w[0]
	vra = w[1]
	ra = w[2]
	slde = w[3]
	slds = w[4]
	bkg = w[5]
	
	delrho = slde - slds

	//if vra < ra, OBLATE
	//if vra > ra, PROLATE
//
// the OUTPUT form factor is <f^2>/Vell [cm-1]
//

// local variables
	Variable nord,ii,va,vb,contr,vell,nden,summ,yyy,zi,qq,halfheight
	Variable answer
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"

	
//	if wt,z waves don't exist, create them
// 20 Gauss points is not enough for Ellipsoid calculation
	
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=76 $weightStr,$zStr
		Wave w76 = $weightStr
		Wave z76 = $zStr		// wave references to pass
		Make76GaussPoints(w76,z76)	
	//		    printf "w[0],z[0] = %g %g\r", w76[0],z76[0]
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	// execute if condition is false
		endif
		Wave w76 = $weightStr
		Wave z76 = $zStr		// Not sure why this has to be "declared" twice
	//	    printf "w[0],z[0] = %g %g\r", w76[0],z76[0]	
	endif


// set up the integration
	// end points and weights
	nord = 76
	va = 0
	vb = 1

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0		
		yyy = w76[ii] * eor(qq, ra,vra, zi)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
// Multiply by contrast^2
	answer *= delrho*delrho
//normalize by Ellipsoid volume
//NOTE that for this (Fournet) definition of the integral, one must MULTIPLY by Vell
	vell=4*Pi/3*ra*ra*vra
	answer *= vell
//convert to [cm-1]
	answer *= 1.0e8
//Scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
	
End		//End of function EllipsoidForm()

///////////////////////////////////////////////////////////////
Function eor(qq,ra,vra,theta)
	Variable qq,ra,vra,theta
	
// qq is the q-value for the calculation (1/A)
// ra are the like radius of the Ellipsoid (A)
// vra is the unlike semiaxis of the Ellipsoid = L/2 (A) (= the rotation axis!)
// theta is the dummy variable of the integration

   //Local variables 
	Variable retval,arg,t1, nu
	
	nu = vra/ra
	arg = qq*ra*sqrt(1+theta^2*(nu^2-1))
	
	if(arg == 0.0)
    	retval =1.0/3.0
    else
    	retval = (sin(arg)-arg*cos(arg))/(arg*arg*arg)
    endif
    retval *= retval
    retval *= 9.0
    	
    return retval
    
End 	//Function eor()

// this is all there is to the smeared calculation!
Function SmearedEllipsoidForm(s) :FitFunc
	Struct ResSmearAAOStruct &s
	
	//the name of your unsmeared model is the first argument
	Smear_Model_20(EllipsoidForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedEllipsoidForm(coefW,yW,xW)
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
	err = SmearedEllipsoidForm(fs)
	
	return (0)
End