#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
//
// this function is for the form factor of an oblate ellipsoid with a core-shell structure
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotOblateForm(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_oef,ywave_oef
	xwave_oef =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_oef = {1.,200,20,250,30,1e-6,2e-6,6.3e-6,0.001}
	make/o/t parameters_oef = {"scale","major core (A)","minor core (A)","major shell (A)","minor shell (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit parameters_oef,coef_oef
	Variable/G root:g_oef
	g_oef := OblateForm(coef_oef,ywave_oef,xwave_oef)
//	ywave_oef := OblateForm(coef_oef,xwave_oef)
	Display ywave_oef vs xwave_oef
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("OblateForm","coef_oef","parameters_oef","oef")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOblateForm(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_oef = {1.,200,20,250,30,1e-6,2e-6,6.3e-6,0.001}
	make/o/t smear_parameters_oef = {"scale","major core (A)","minor core (A)","major shell (A)","minor shell (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit smear_parameters_oef,smear_coef_oef
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_oef,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_oef										
		
	Variable/G gs_oef=0
	gs_oef := fSmearedOblateForm(smear_coef_oef,smeared_oef,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_oef vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOblateForm","smear_coef_oef","smear_parameters_oef","oef")
End


//AAO version
Function OblateForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("OblateFormX")
	MultiThread yw = OblateFormX(cw,xw)
#else
	yw = fOblateForm(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fOblateForm(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] crmaj, major radius of core	[A]
	//[2] crmin, minor radius of core
	//[3] trmaj, overall major radius
	//[4] trmin, overall minor radius
	//[5] sldc, core [A-2]
	//[6] slds, shell
	//[7] sld (solvent)
	//[8] bkg, [cm-1]
	Variable scale,crmaj,crmin,trmaj,trmin,delpc,delps,bkg,sldc,slds,sld
	scale = w[0]
	crmaj = w[1]
	crmin = w[2]
	trmaj = w[3]
	trmin = w[4]
	sldc = w[5]
	slds = w[6]
	sld = w[7]
	bkg = w[8]

	delpc = sldc - slds			//core - shell
	delps = slds - sld			//shell - solvent
	
// local variables
	Variable yyy,va,vb,ii,nord,zi,qq,summ,nfn,npro,answer,oblatevol
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"

	
//	if wt,z waves don't exist, create them

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
	nfn = 2		//only <f^2> is calculated
	npro = 0	// OBLATE ELLIPSOIDS
	va =0
	vb =1 

	qq = x		//current x point is the q-value for evaluation
      summ = 0.0
      ii=0
      do
      		//printf "top of nord loop, i = %g\r",i
        if(nfn ==1) //then 		// "f1" required for beta factor
          if(npro ==1) //then	// prolate
          	 zi = ( z76[ii]*(vb-va) + vb + va )/2.0	
//            yyy = w76[ii]*gfn1(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
          Endif
//
          if(npro ==0) //then	// oblate  
          	 zi = ( z76[ii]*(vb-va) + vb + va )/2.0
//            yyy = w76[ii]*gfn3(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
          Endif
        Endif		//nfn = 1
        //
        if(nfn !=1) //then		//calculate"f2" = <f^2> = averaged form factor
          if(npro ==1) //then	//prolate
             zi = ( z76[ii]*(vb-va) + vb + va )/2.0
//            yyy = w76[ii]*gfn2(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
          //printf "yyy = %g\r",yyy
          Endif
//
          if(npro ==0) //then	//oblate
          	 zi = ( z76[ii]*(vb-va) + vb + va )/2.0
          	yyy = w76[ii]*gfn4(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
          Endif
        Endif		//nfn <>1
        
        summ = yyy + summ		// get running total of integral
        ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

      answer = (vb-va)/2.0*summ
      
      // normalize by particle volume
      oblatevol = 4*Pi/3*trmaj*trmaj*trmin
      answer /= oblatevol
      
      //convert answer [A-1] to [cm-1]
      answer *= 1.0e8  
      //scale
      answer *= scale
      // //then add background
      answer += bkg

	Return (answer)
End
//
//     FUNCTION gfn4:    CONTAINS F(Q,A,B,MU)**2  AS GIVEN
//                       BY (53) & (58-59) IN CHEN AND
//                       KOTLARCHYK REFERENCE
//
//       <OBLATE ELLIPSOID>

Function gfn4(xx,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
	Variable xx,crmaj,crmin,trmaj,trmin,delpc,delps,qq
	// local variables
	Variable aa,bb,u2,ut2,uq,ut,vc,vt,gfnc,gfnt,tgfn,gfn4,pi43
	
	PI43=4.0/3.0*PI
  	aa = crmaj
 	bb = crmin
 	u2 = (bb*bb*xx*xx + aa*aa*(1.0-xx*xx))
 	ut2 = (trmin*trmin*xx*xx + trmaj*trmaj*(1.0-xx*xx))
   	uq = sqrt(u2)*qq
 	ut= sqrt(ut2)*qq
	vc = PI43*aa*aa*bb
   	vt = PI43*trmaj*trmaj*trmin
   	gfnc = 3.0*(sin(uq)/uq/uq - cos(uq)/uq)/uq*vc*delpc
  	gfnt = 3.0*(sin(ut)/ut/ut - cos(ut)/ut)/ut*vt*delps
  	tgfn = gfnc+gfnt
  	gfn4 = tgfn*tgfn
  	
  	return gfn4
  	
End 		// function gfn4 for oblate ellipsoids 

// this is all there is to the smeared calculation!
Function SmearedOblateForm(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(OblateForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOblateForm(coefW,yW,xW)
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
	err = SmearedOblateForm(fs)
	
	return (0)
End