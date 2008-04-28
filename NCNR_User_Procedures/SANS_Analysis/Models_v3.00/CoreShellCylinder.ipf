#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this function is for the form factor of a right circular cylinder with core/shell scattering length density profile
//
// the core dimensions are given and a constant shell thickness is added to the radius and to dach and of the length
// this way, the scattering amplitude is simply the difference between two cylinders of different dimensions
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotCoreShellCylinderForm(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_cscyl,ywave_cscyl
	xwave_cscyl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_cscyl = {1.,20.,10.,400,1.0e-6,4.0e-6,1.0e-6,0.01}
	make/o/t parameters_cscyl = {"scale","core radius (A)","shell THICKNESS (A)","CORE length (A)","SLD core (A^-2)","SLD shell (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_cscyl,coef_cscyl
	ywave_cscyl := CoreShellCylinderForm(coef_cscyl,xwave_cscyl)
	Display ywave_cscyl vs xwave_cscyl
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End
///////////////////////////////////////////////////////////

Proc PlotSmearedCSCylinderForm()	
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	make/o/d smear_coef_cscyl =  {1.,20.,10.,400,1.0e-6,4.0e-6,1.0e-6,0.01}
	make/o/t smear_parameters_cscyl = {"scale","core radius (A)","shell radius (A)","length (A)","SLD core (A^-2)","SLD shell (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_cscyl,smear_coef_cscyl
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_cscyl,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_cscyl	

	smeared_cscyl := SmearedCoreShellCylinderForm(smear_coef_cscyl,$gQvals)
	Display smeared_cscyl vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function CoreShellCylinderForm(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] cylinder CORE RADIUS (A)
	//[2] shell Thickness (A)
	//[3]  cylinder CORE LENGTH (A)
	//[4] core SLD (A^-2)
	//[5] shell SLD (A^-2)
	//[6] solvent SLD (A^-2)
	//[7] background (cm^-1)
	Variable scale,length,delrho,bkg,rcore,thick,rhoc,rhos,rhosolv
	scale = w[0]
	rcore = w[1]
	thick = w[2]
	length = w[3]
	rhoc = w[4]
	rhos = w[5]
	rhosolv = w[6]
	bkg = w[7]
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
	vb = Pi/2
      halfheight = length/2.0

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0		
		yyy = w76[ii] * CoreShellcyl(qq, rcore, thick, rhoc,rhos,rhosolv, halfheight, zi)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
// contrast is now explicitly included in the core-shell calculation

//normalize by cylinder volume
//NOTE that for this (Fournet) definition of the integral, one must MULTIPLY by Vcyl
//calculate TOTAL volume
// length is the total core length 
	vcyl=Pi*(rcore+thick)*(rcore+thick)*(length+2*thick)
	answer /= vcyl
//convert to [cm-1]
	answer *= 1.0e8
//Scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
	
End		//End of function CoreShellCylinderForm()

///////////////////////////////////////////////////////////////
// F(qq, rcore, thick, rhoc,rhos,rhosolv, length, zi)
//
Function CoreShellcyl(qq, rcore, thick, rhoc,rhos,rhosolv, length, dum)
	Variable qq, rcore, thick, rhoc,rhos,rhosolv, length, dum
	
// qq is the q-value for the calculation (1/A)
// rcore is the core radius of the cylinder (A)
//thick is the uniform thickness
// rho(n) are the respective SLD's

// length is the *Half* CORE-LENGTH of the cylinder = L (A)

// dum is the dummy variable for the integration (x in Feigin's notation)

   //Local variables 
	Variable dr1,dr2,besarg1,besarg2,vol1,vol2,sinarg1,sinarg2,t1,t2,retval
	
	dr1 = rhoc-rhos
	dr2 = rhos-rhosolv
	vol1 = Pi*rcore*rcore*(2*length)
	vol2 = Pi*(rcore+thick)*(rcore+thick)*(2*length+2*thick)
	
	besarg1 = qq*rcore*sin(dum)
	besarg2 = qq*(rcore+thick)*sin(dum)
	sinarg1 = qq*length*cos(dum)
	sinarg2 = qq*(length+thick)*cos(dum)
	
	t1 = 2*vol1*dr1*sin(sinarg1)/sinarg1*bessJ(1,besarg1)/besarg1
	t2 = 2*vol2*dr2*sin(sinarg2)/sinarg2*bessJ(1,besarg2)/besarg2
	
	retval = ((t1+t2)^2)*sin(dum)
	
    return retval
    
End 	//Function CoreShellcyl()

// this is all there is to the smeared calculation!
Function SmearedCoreShellCylinderForm(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShellCylinderForm,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

