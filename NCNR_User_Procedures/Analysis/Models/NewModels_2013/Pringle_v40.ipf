#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this function is for the form factor of a right circular cylinder with uniform scattering length density
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotPringleForm(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/D/n=(num) xwave_pringle,ywave_pringle
	xwave_pringle =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_pringle = {1.,50.,10,0.001,0.02,1e-6,6.3e-6,0.01}
	make/o/t parameters_pringle = {"scale","radius (A)","thickness (A)","alpha (rad)","beta (rad)","SLD pringle (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_pringle,coef_pringle
	Variable/G root:g_pringle
	g_pringle := PringleForm(coef_pringle,ywave_pringle,xwave_pringle)
//	ywave_pringle := PringleForm(coef_pringle,xwave_pringle)
	Display ywave_pringle vs xwave_pringle
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PringleForm","coef_pringle","parameters_pringle","pringle")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPringleForm(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_pringle = {1.,50.,10,0.001,0.02,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_pringle = {"scale","radius (A)","thickness (A)","alpha (rad)","beta (rad)","SLD pringle (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_pringle,smear_coef_pringle
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_pringle,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_pringle	
					
	Variable/G gs_pringle=0
	gs_pringle := fSmearedPringleForm(smear_coef_pringle,smeared_pringle,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_pringle vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPringleForm","smear_coef_pringle","smear_parameters_pringle","cyl")
End

// AAO verison
// even 100 points gets a 1.7x speedup from MultiThread
// then the fit is 1.24x faster (1.25s vs 1.55s)
Function PringleForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

#if exists("PringleFormX")
//	yw = PringleFormX(cw,xw)
	MultiThread yw = PringleFormX(cw,xw)
#else
	yw = fPringleForm(cw,xw)
#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fPringleForm(w,x) : FitFunc
	Wave w
	Variable x
	
//The input variables are (and output)
	//[0] scale
	//[1] pringle RADIUS (A)
	//[2] pringle THICKNESS (A)
	//[3] pringle angle alpha
	//[4] pringle angle beta
	//[5] sld pringle (A^-2)
	//[6] sld solvent
	//[7] background (cm^-1)
	Variable scale, radius,thickness,a,b,delrho,bkg,sldCyl,sldSolv
	scale = w[0]
	radius = w[1]
	thickness = w[2]
	a = w[3]
	b = w[4]
	sldCyl = w[5]
	sldSolv = w[6]
	bkg = w[7]
	delrho = sldCyl-sldSolv

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
	vb = Pi/2.0

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0		
		yyy = w76[ii] * pringle(qq, radius, a, b, thickness, zi)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
// Multiply by contrast^2
	answer *= delrho*delrho
//normalize by cylinder volume
	vcyl=Pi*radius*radius*thickness

	// Need to work out why this is the scale factor! At the moment it is a fudge.
	answer *= 4*vcyl/(radius^4)
//convert to [cm-1]
	answer *= 1.0e8
//Scale
	answer *= scale
// add in the background
	answer += bkg

	Return (answer)
	
End		//End of function PringleForm()

///////////////////////////////////////////////////////////////
Function pringle(qq,rr,aa,bb,d,phi)
	Variable qq,rr,aa,bb,d,phi
	
// qq is the q-value for the calculation (1/A)
// rr is the radius of the cylinder (A)


   //Local variables 
   Variable sumterm, sincterm, nn,retval
   
   sincterm = sinc(qq*d*cos(phi)/2)^2

   //calculate sum term from n = -3 to 3 
      sumterm = 0
    	for (nn = -3; nn<= 3; nn = nn+1)
		sumterm =  sumterm + (pringleC(nn,qq,rr,d,aa,bb,phi)^2 + pringleS(nn,qq,rr,d,aa,bb,phi)^2)
	endfor
	
	retval = sin(phi)*sumterm*sincterm
	
       return retval
    
End 	//Function cyl()

// this is all there is to the smeared calculation!
Function SmearedPringleForm(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(PringleForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

Function pringleC(n,q,r,d,a,b,phi)
	Variable n,q, r,d, a, b, phi
	
	Variable bessargs, cosarg, bessargcb,retval

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
	vb = r

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0
		
		bessargs = q*zi*sin(phi)
		cosarg = q*zi*zi*a*cos(phi)
		bessargcb = q*zi*zi*b*cos(phi)
				
		yyy = w76[ii] * zi*cos(cosarg)*BesselJ(n,bessargcb)*BesselJ(2*n,bessargs)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      retval = (vb-va)/2.0*summ

//	retval *= (4*Pi*Pi*d)
//	retval *= sinc(q*d*cos(phi)/2)^2

	return retval
End


Function pringleS(n,q,r,d,a,b,phi)
	Variable n,q, r, d, a, b, phi
	
	Variable bessargs, sinarg, bessargcb,retval

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
	vb = r

// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0		// initialize integral
      ii=0
      do
		// Using 76 Gauss points
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0
		
		bessargs = q*zi*sin(phi)
		sinarg = q*zi*zi*a*cos(phi)
		bessargcb = q*zi*zi*b*cos(phi)
				
		yyy = w76[ii] * zi*sin(sinarg)*BesselJ(n,bessargcb)*BesselJ(2*n,bessargs)
		summ += yyy 

        	ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      retval = (vb-va)/2.0*summ

//	retval *= (4*Pi*Pi*d)
//	retval *= sinc(q*d*cos(phi)/2)^2
	
	return retval
End


//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPringleForm(coefW,yW,xW)
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
	err = SmearedPringleForm(fs)
	
	return (0)
End