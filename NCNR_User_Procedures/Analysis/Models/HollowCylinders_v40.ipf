#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this function is for the form factor of a right circular cylinder with uniform scattering length density
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotHollowCylinder(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_Hcyl,ywave_Hcyl
	xwave_Hcyl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_Hcyl = {1.,20.,30.,400,1.0e-6,6.3e-6,0.01}
	make/o/t parameters_Hcyl = {"scale","core radius (A)","shell radius (A)","length (A)","SLD shell (A^-2)","SLD solvent (in/out)","incoh. bkg (cm^-1)"}
	Edit parameters_Hcyl,coef_Hcyl
	Variable/G root:g_hcyl
	g_Hcyl := HollowCylinder(coef_Hcyl,ywave_Hcyl,xwave_Hcyl)
//	ywave_Hcyl := HollowCylinder(coef_Hcyl,xwave_Hcyl)
	Display ywave_Hcyl vs xwave_Hcyl
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("HollowCylinder","coef_Hcyl","parameters_Hcyl","Hcyl")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedHollowCylinder(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_Hcyl = {1.,20.,30.,400,1.0e-6,6.3e-6,0.01}
	make/o/t smear_parameters_Hcyl = {"scale","core radius (A)","shell radius (A)","length (A)","SLD shell (A^-2)","SLD solvent (in/out)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_Hcyl,smear_coef_Hcyl
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_Hcyl,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_Hcyl	
					
	Variable/G gs_Hcyl=0
	gs_Hcyl := fSmearedHollowCylinder(smear_coef_Hcyl,smeared_Hcyl,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_Hcyl vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedHollowCylinder","smear_coef_Hcyl","smear_parameters_Hcyl","Hcyl")
End


//AAO version
Function HollowCylinder(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("HollowCylinderX")
	yw = HollowCylinderX(cw,xw)
#else
	yw = fHollowCylinder(cw,xw)
#endif
	return(0)
End
///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fHollowCylinder(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] cylinder CORE RADIUS (A)
	//[2] cylinder shell radius (A)
	//[3] total cylinder LENGTH (A)
	//[4] contrast (A^-2)
	//[5] background (cm^-1)
	Variable scale,length,delrho,bkg,rcore,rshell,contrast,sldc,slds
	scale = w[0]
	rcore = w[1]
	rshell = w[2]
	length = w[3]
	sldc = w[4]
	slds = w[5]
	contrast = sldc - slds
	bkg = w[6]
//
// the OUTPUT form factor is <f^2>/Vcyl [cm-1]
//

// local variables
	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq,halfheight
	Variable answer
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"

	
//	if wt,z waves don't exist, create them
// 20 Gauss points is not enough for cylinder calculation
	
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
      halfheight = length/2.0

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0		
		yyy = w76[ii] * Hollowcyl(qq, rcore, rshell, length, zi)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
// multiply by the contrast
	answer *= contrast*contrast

//normalize by cylinder volume
//NOTE that for this (Fournet) definition of the integral, one must MULTIPLY by Vcyl
	vcyl=Pi*(rshell^2-rcore^2)*length
	answer *= vcyl
//convert to [cm-1]
	answer *= 1.0e8
//Scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
	
End		//End of function HollowCylinderForm()

///////////////////////////////////////////////////////////////
Function Hollowcyl(qq,r2,r1,h,theta)
	Variable qq,r2,r1,h,theta
	
// qq is the q-value for the calculation (1/A)
// r2 is the core radius of the cylinder (A)
//r1 is the shell raduis
// rho(n) are the respective SLD's
// h is the total-LENGTH of the cylinder = L (A)
// theta is the dummy variable for the integration (x in Feigin's notation)

   //Local variables 
	Variable gamma,besarg1,besarg2,lam1,lam2,t2,retval,psi,sinarg
	
	gamma = r2/r1
	besarg1 = qq*r1*sqrt(1-theta^2)
	besarg2 = qq*r2*sqrt(1-theta^2)
	lam1 = 2*bessJ(1,besarg1)/besarg1
	lam2 = 2*bessJ(1,besarg2)/besarg2
	psi = 1/(1-gamma^2)*(lam1 -  gamma^2*lam2)		//SRK 10/19/00
	
	sinarg = qq*h*theta/2
	t2 = sin(sinarg)/sinarg
	
	retval = psi*psi*t2*t2
	
    return retval
    
End 	//Function Hollowcyl()


// this is all there is to the smeared calculation!
Function SmearedHollowCylinder(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(HollowCylinder,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedHollowCylinder(coefW,yW,xW)
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
	err = SmearedHollowCylinder(fs)
	
	return (0)
End