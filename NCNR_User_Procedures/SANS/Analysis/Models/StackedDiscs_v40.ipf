#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile.
// Adopting these into the experiment will insure that they are always present.
////////////////////////////////////////////////
//
// This function calculates the total coherent scattered intensity from stacked discs (tactoids) with a core/layer
// structure.  Assuming the next neighbor distance (d-spacing) in a stack of parallel discs obeys a Gaussian 
// distribution, a strcture factor S(q) proposed by Kratky and Porod in 1949 is used in this function.
//
// 04 JUL 01   DLH
//
// SRK - 2007
// this model needs 76 Gauss points for a proper smearing calculation
// since there can be sharp interference fringes that develop from the stacking
////////////////////////////////////////////////

Proc PlotStackedDiscs(num,qmin,qmax)
	Variable num=500,qmin=0.001,qmax=1.0
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/D/n=(num) xwave_scyl,ywave_scyl
	xwave_scyl =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_scyl = {0.01,3000.,10.,15.,4.0e-6,-4.0e-7,5.0e-6,1,0,1.0e-3}
	make/o/t parameters_scyl = {"scale","Disc Radius (A)","Core Thickness (A)","Layer Thickness (A)","Core SLD (A^-2)","Layer SLD (A^-2)","Solvent  SLD(A^-2)","# of Stacking","GSD of d-Spacing","incoh. bkg (cm^-1)"}
	Edit parameters_scyl,coef_scyl
	
	Variable/G root:g_scyl
	g_scyl := StackedDiscs(coef_scyl,ywave_scyl,xwave_scyl)
//	ywave_scyl := StackedDiscs(coef_scyl,xwave_scyl)
	Display ywave_scyl vs xwave_scyl
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("StackedDiscs","coef_scyl","scyl")
End
///////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedStackedDiscs(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_scyl = {0.01,3000.,10.,15.,4.0e-6,-4.0e-7,5.0e-6,1,0,1.0e-3}
	make/o/t smear_parameters_scyl = {"scale","Disc Radius (A)","Core Thickness (A)","Layer Thickness (A)","Core SLD (A^-2)","Layer SLD (A^-2)","Solvent SLD (A^-2)","# of Stacking","GSD of d-Spacing","incoh. bkg (cm^-1)"}
	Edit smear_parameters_scyl,smear_coef_scyl
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_scyl,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_scyl				
		
	Variable/G gs_scyl=0
	gs_scyl := fSmearedStackedDiscs(smear_coef_scyl,smeared_scyl,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_scyl vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedStackedDiscs","smear_coef_scyl","scyl")
End

///////////////////////////////////////////////////////////////

//AAO version
Function StackedDiscs(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("StackedDiscsX")
	yw = StackedDiscsX(cw,xw)
#else
	yw = fStackedDiscs(cw,xw)
#endif
	return(0)
End
///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fStackedDiscs(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] Scale
	//[1] Disc Radius (A)
	//[2] Disc Core Thickness (A)
	//[3] Disc Layer Thickness (A)
	//[4] Core SLD (A^-2)
	//[5] Layer SLD (A^-2)
	//[6] Solvent SLD (A^-2)
	//[7] Number of Discs Stacked
	//[8] Gaussian Standrad Deviation of d-Spacing
	//[9] background (cm^-1)
	
	Variable scale,length,bkg,rcore,thick,rhoc,rhol,rhosolv,N,gsd
	scale = w[0]
	rcore = w[1]
	length = w[2]
	thick = w[3]
	rhoc = w[4]
	rhol = w[5]
	rhosolv = w[6]
	N = w[7]
	gsd = w[8]
	bkg = w[9]
//
// the OUTPUT form factor is <f^2>/Vcyl [cm-1]
//

// local variables
	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq,halfheight,kk,sqq,dexpt,d
	Variable answer
	
	d=2*thick+length
	
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
		yyy = w76[ii] * Stackdisc_kern(qq, rcore, rhoc,rhol,rhosolv, halfheight,thick,zi,gsd,d,N)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
// contrast is now explicitly included in the core-shell calculation

//Normalize by total disc volume
//NOTE that for this (Fournet) definition of the integral, one must MULTIPLY by Vcyl
//Calculate TOTAL volume
// length is the total core thickness 

	vcyl=Pi*rcore*rcore*(2*thick+length)*N
	answer /= vcyl

//Convert to [cm-1]
	answer *= 1.0e8

//Scale
	answer *= scale
	
// add in the background
	answer += bkg

	Return (answer)
	
End		//End of function StackDiscs()

///////////////////////////////////////////////////////////////

// F(qq, rcore, rhoc,rhosolv, length, zi)
//
Function Stackdisc_kern(qq, rcore, rhoc,rhol,rhosolv, length,thick,dum,gsd,d,N)
	Variable qq, rcore, rhoc,rhol,rhosolv, length,thick,dum,gsd,d,N
         	
// qq is the q-value for the calculation (1/A)
// rcore is the core radius of the cylinder (A)
// rho(n) are the respective SLD's
// length is the *Half* CORE-LENGTH of the cylinder = L (A)
// dum is the dummy variable for the integration (x in Feigin's notation)

   //Local variables 
	Variable totald,dr1,dr2,besarg1,besarg2,area,sinarg1,sinarg2,t1,t2,retval,kk,sqq,dexpt
	
	dr1 = rhoc-rhosolv
	dr2 = rhol-rhosolv
	area = Pi*rcore*rcore
	totald=2*(thick+length)
	
	besarg1 = qq*rcore*sin(dum)
	besarg2 = qq*rcore*sin(dum)
	
	sinarg1 = qq*length*cos(dum)
	sinarg2 = qq*(length+thick)*cos(dum)
	
	t1 = 2*area*(2*length)*dr1*(sin(sinarg1)/sinarg1)*(bessJ(1,besarg1)/besarg1)
	t2 = 2*area*dr2*(totald*sin(sinarg2)/sinarg2-2*length*sin(sinarg1)/sinarg1)*(bessJ(1,besarg2)/besarg2)
	
	retval =((t1+t2)^2)*sin(dum)
	
	// loop for the structure facture S(q)
	
	     kk=1
	     sqq=0.0
      do
		dexpt=qq*cos(dum)*qq*cos(dum)*d*d*gsd*gsd*kk/2.0
		sqq=sqq+(N-kk)*cos(qq*cos(dum)*d*kk)*exp(-1.*dexpt)

        	kk+=1
	while (kk<N)				
	
	// end of loop for S(q)

	sqq=1.0+2.0*sqq/N
	
	retval *= sqq
    
    return retval
    
End 		//Function Stackdisc()

///////////////////////////////////////////////////////////////

// this model needs 76 Gauss points for a proper smearing calculation
// since there can be sharp interference fringes that develop from the stacking
Function SmearedStackedDiscs(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_76(StackedDiscs,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End


//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedStackedDiscs(coefW,yW,xW)
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
	err = SmearedStackedDiscs(fs)
	
	return (0)
End