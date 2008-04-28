#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this function is for the form factor of a prolate ellipsoid
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotProlateForm(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^-1) for model: "
	Prompt qmax "Enter maximum q-value (^-1) for model: "
	
	Make/O/D/n=(num) xwave_pef,ywave_pef
	xwave_pef =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_pef = {1.,100,50,110,60,1e-6,2e-6,6.3e-6,0.001}
	make/o/t parameters_pef = {"scale","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit parameters_pef,coef_pef
	Variable/G root:g_pef
	g_pef := ProlateForm(coef_pef,ywave_pef,xwave_pef)
//	ywave_pef := ProlateForm(coef_pef,xwave_pef)
	Display ywave_pef vs xwave_pef
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("ProlateForm","coef_pef","pef")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlateForm(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pef = {1.,100,50,110,60,1e-6,2e-6,6.3e-6,0.001}
	make/o/t smear_parameters_pef = {"scale","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_pef,smear_coef_pef
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_pef,smeared_qvals				//**** mod
	SetScale d,0,0,"1/cm",smeared_pef						
		
	Variable/G gs_pef=0
	gs_pef := fSmearedProlateForm(smear_coef_pef,smeared_pef,smeared_qvals)	//this wrapper fills the STRUCT

	Display smeared_pef vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)	
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlateForm","smear_coef_pef","pef")
End

//AAO version
Function ProlateForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("ProlateFormX")
	yw = ProlateFormX(cw,xw)
#else
	yw = fProlateForm(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fProlateForm(w,x) : FitFunc
	Wave w
	Variable x

//The input variables are (and output)
	//[0] scale
	//[1] crmaj, major radius of core	[]
	//[2] crmin, minor radius of core
	//[3] trmaj, overall major radius
	//[4] trmin, overall minor radius
	//[5] sld core, [A^-2]
	//[6] sld shell, 
	//[7] sld solvent
	//[8] bkg [cm-1]
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
	delps = slds - sld 			//shell - solvent
// local variables
	Variable yyy,va,vb,ii,nord,zi,qq,summ,nfn,npro,answer,prolatevol
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"

//	if wt,z waves don't exist, create them

	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=76 $weightStr,$zStr
		Wave w76 = $weightStr
		Wave z76 = $zStr		// wave references to pass
		Make76GaussPoints(w76,z76)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"	// execute if condition is false
		endif
		Wave w76 = $weightStr
		Wave z76 = $zStr
	endif

// set up the integration
	// end points and weights
	nord = 76
	nfn = 2		//only <f^2> is calculated
	npro = 1	// PROLATE ELLIPSOIDS
	va =0
	vb =1 
//move this zi(i) evaluation inside other nord loop, since I don't have an array
//      i=0
//      do 
//       zi[i] = ( z76[i]*(vb-va) + vb + va )/2.0
 //       i +=1
 //  	while (i<nord)
//
// evaluate at Gauss points 
	// remember to index from 0,size-1

	qq = x		//current x point is the q-value for evaluation
	summ = 0.0
	ii=0
	do
		//printf "top of nord loop, i = %g\r",i
		if(nfn ==1) //then 		// "f1" required for beta factor
			if(npro ==1) //then	// prolate
				zi = ( z76[ii]*(vb-va) + vb + va )/2.0	
//	     yyy = w76[ii]*gfn1(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
			Endif
//
			if(npro ==0) //then	// oblate  
				zi = ( z76[ii]*(vb-va) + vb + va )/2.0
//	      yyy = w76[i]*gfn3(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
			Endif
		Endif		//nfn = 1
	  //
		if(nfn !=1) //then		//calculate"f2" = <f^2> = averaged form factor
			if(npro ==1) //then	//prolate
				zi = ( z76[ii]*(vb-va) + vb + va )/2.0
				yyy = w76[ii]*gfn2(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
				//printf "yyy = %g\r",yyy
			Endif
//
			if(npro ==0) //then	//oblate
				zi = ( z76[ii]*(vb-va) + vb + va )/2.0
//	   	yyy = w76[ii]*gfn4(zi,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
			Endif
		Endif		//nfn <>1
	  
		summ = yyy + summ		// get running total of integral
		ii+=1
	while (ii<nord)				// end of loop over quadrature points
//   
// calculate value of integral to return

	answer = (vb-va)/2.0*summ
	
	//normailze by particle volume
	prolatevol = 4*Pi/3*trmaj*trmin*trmin
	answer /= prolatevol
	
	// rescale from 1/ to 1/cm
	answer *= 1.0e8
	//scale (arb)
	answer *= scale
	////then add in background
	answer += bkg

	Return (answer)
End 	//prolate form factor

//
//     FUNCTION gfn2:    CONTAINS F(Q,A,B,mu)**2  AS GIVEN
//                       BY (53) AND (56,57) IN CHEN AND 
//                       KOTLARCHYK REFERENCE
//
//     <PROLATE ELLIPSOIDS>
//
Function gfn2(xx,crmaj,crmin,trmaj,trmin,delpc,delps,qq)
	Variable xx,crmaj,crmin,trmaj,trmin,delpc,delps,qq
	// local variables
	Variable aa,bb,u2,ut2,uq,ut,vc,vt,gfnc,gfnt,tgfn,gfn2,pi43,gfn

	PI43=4.0/3.0*PI
	aa = crmaj
	bb = crmin
	u2 = (aa*aa*xx*xx + bb*bb*(1.0-xx*xx))
	ut2 = (trmaj*trmaj*xx*xx + trmin*trmin*(1.0-xx*xx))
	uq = sqrt(u2)*qq
	ut= sqrt(ut2)*qq
	vc = PI43*aa*bb*bb
	vt = PI43*trmaj*trmin*trmin
	gfnc = 3.0*(sin(uq)/uq/uq - cos(uq)/uq)/uq*vc*delpc
	gfnt = 3.0*(sin(ut)/ut/ut - cos(ut)/ut)/ut*vt*delps
	gfn = gfnc+gfnt
	gfn2 = gfn*gfn
	
	return gfn2
End		//function gfn2 for prolate ellipsoids


// this is all there is to the smeared calculation!
Function SmearedProlateForm(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(ProlateForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlateForm(coefW,yW,xW)
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
	err = SmearedProlateForm(fs)
	
	return (0)
End