#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////////
//
// model function that calculates the scattering from 
// lamellar surfactant structures. contrast is two-phase,
// from the solvent and uniform bilayer. Integer numbers of 
// repeating bilayers (at a repeat spacing) leads to the
// familiar lamellar peaks. Bending constant information
// can be extracted from the Caille parameter with moderate
// success. A number of the parameters should be held
// fixed during the fitting procedure, as they should be well
// known:
//		repeat spacing D = 2*pi/Qo
//		contrast = calculated value
//		polydispersity should be close to 0.1-0.3
//   Caille parameter <0.8 or 1.0
//
// NOTES for Curve Fitting:
// the epsilon wave "epsilon_Lamellar" should be used to force a 
// larger derivative step for the # of repeat units, which is an integer.
// a singular matix error will always result if you don't follow this.
// Also, the # of repeats should be constrained to ~3<N<200, otherwise
// the optimization can pick a VERY large N, and waste lots of time
// in the summation loop
//
// instrumental resolution is taken into account in the REGULAR
// model calculation. resolution of ONLY the S(Q) peaks are 
// included. performing the typical smearing calculation would
// be "double smearing", so is not done.
//
// the delta Q parameter "gDelQ" or "dQ" is taken from the q-dependent
// instrument resolution "abssq" column as this is the identical definition
// as in the original reference. If the real resolution function cannot be
// found, a default value, typical of a "medium" q-range on the NG3 SANS is
// used, although the real values are highly preferred
//
// REFERENCE:	Nallet, Laversanne, and Roux, J. Phys. II France, 3, (1993) 487-502.
//		also in J. Phys. Chem. B, 105, (2001) 11081-11088.
//
// 14 JULY 2003 SRK
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotLamellarPS(num,qmin,qmax)
	Variable num=128, qmin=.001, qmax=.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	// constants
//	Variable/G root:gEuler = 0.5772156649		// Euler's constant
//	Variable/G root:gDelQ = 0.0025		//[=] 1/A, q-resolution, default value
	
	Make/O/D/n=(num) xwave_LamellarPS, ywave_LamellarPS
	xwave_LamellarPS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_LamellarPS = {1,400,30,0.15,1e-6,6.3e-6,20,0.1,0}			//CH#2
	make/o/t parameters_LamellarPS = {"Scale","Lamellar spacing, D (A)","Bilayer Thick (delta) (A)","polydisp of Bilayer Thickness","SLD bilayer (A^-2)","SLD solvent (A^-2)","# of Lamellar plates","Caille parameter","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_LamellarPS, coef_LamellarPS
	ModifyTable width(parameters_LamellarPS)=160
	
	Variable/G root:g_LamellarPS
	g_LamellarPS := LamellarPS(coef_LamellarPS, ywave_LamellarPS, xwave_LamellarPS)
	Display ywave_LamellarPS vs xwave_LamellarPS
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	//
	// make epsilon wave appropriate for integer number of lamellar repeats
	Duplicate/O coef_LamellarPS epsilon_LamellarPS
	epsilon_LamellarPS = 1e-4*coef_LamellarPS
	epsilon_LamellarPS[6] = 1		//to make the derivative useful 
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("LamellarPS","coef_LamellarPS","parameters_LamellarPS","LamellarPS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedLamellarPS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// constants
//	Variable/G root:gEuler = 0.5772156649		// Euler's constant
//	Variable/G root:gDelQ = 0.0025		//[=] 1/A, q-resolution, default value
	// Setup parameter table for model function
	Make/O/D smear_coef_LamellarPS = {1,400,30,0.15,1e-6,6.3e-6,20,0.1,0}		//CH#4
	make/o/t smear_parameters_LamellarPS = {"Scale","Lamellar spacing, D (A)","Bilayer Thick (delta) (A)","polydisp of Bilayer Thickness","SLD bilayer (A^-2)","SLD solvent (A^-2)","# of Lamellar plates","Caille parameter","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_LamellarPS,smear_coef_LamellarPS					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_LamellarPS,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_LamellarPS							//
					
	Variable/G gs_LamellarPS=0
	gs_LamellarPS := fSmearedLamellarPS(smear_coef_LamellarPS,smeared_LamellarPS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_LamellarPS vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	
	// make epsilon wave appropriate for integer number of lamellar repeats
	Duplicate/O smear_coef_LamellarPS epsilon_LamellarPS
	epsilon_LamellarPS = 1e-4*smear_coef_LamellarPS
	epsilon_LamellarPS[6] = 1		//to make the derivative useful 
	
	SetDataFolder root:
	AddModelToStrings("SmearedLamellarPS","smear_coef_LamellarPS","smear_parameters_LamellarPS","LamellarPS")
End


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function LamellarPS(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("LamellarPSX")
	yw = LamellarPSX(cw,xw)
#else
	yw = fLamellarPS(cw,xw)
#endif
	return(0)
End

// instrument resolution IS included here in S(Q)
Function fLamellarPS(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//[0]Scale
//[1]Lam spacing, D
//[2]Bilay Thick (delta)
//[3]polydisp of the bilayer thickness
//[4]contrast
//[5]# of Lam plates
//[6]Caille parameter
//[7]Incoherent Bgd (cm-1)
	
//	give them nice names
	Variable scale,dd,del,sig,contr,NN,Cp,bkg,sldb,slds
	scale = w[0]
	dd = w[1]
	del = w[2]
	sig = w[3]*del
	sldb = w[4]
	slds = w[5]
	contr = sldb-slds
	NN = trunc(w[6])		//be sure that NN is an integer
	Cp = w[7]
	bkg = w[8]
	
//	local variables
	Variable inten, qval,Pq,Sq,ii,alpha,temp,t1,t2,t3,dQ
	Variable Euler = 0.5772156649
	Variable dQDefault = 0
	dQ = dqDefault
	
//	NVAR Euler = root:gEuler
//	NVAR dQDefault = root:gDelQ
	//	x is the q-value for the calculation
	qval = x
	//get the instrument resolution
//	SVAR/Z sigQ = gSig_Q
//	SVAR/Z qStr = gQVals
//	
//	if(SVAR_Exists(sigQ) && SVAR_Exists(qStr))
//		Wave/Z sigWave=$sigQ
//		Wave/Z sig_Qwave = $qStr
//		if(waveexists(sigWave)&&waveexists(sig_qwave))
//			dQ = interp(qval, sig_Qwave, sigWave )
//		else
////			if(qval>0.01 && qval<0.012)
////				print "using default resolution"
////			endif
//			dQ = dQDefault
//		endif
//	else
//		dQ = dQDefault
//	endif
	
	Pq = 2*contr^2/qval/qval*(1-cos(qval*del)*exp(-0.5*qval^2*sig^2))
	
	ii=0
	Sq = 0
	for(ii=1;ii<(NN-1);ii+=1)
		temp = 0
		alpha = Cp/4/pi/pi*(ln(pi*ii) + Euler)
		t1 = 2*dQ*dQ*dd*dd*alpha
		t2 = 2*qval*qval*dd*dd*alpha
		t3 = dQ*dQ*dd*dd*ii*ii
		
		temp = 1-ii/NN
		temp *= cos(dd*qval*ii/(1+t1))
		temp *= exp(-1*(t2 + t3)/(2*(1+t1)) )
		temp /= sqrt(1+t1)
		
		Sq += temp
	endfor
	Sq *= 2
	Sq += 1
	
	inten = 2*Pi*scale*Pq*Sq/(dd*Qval^2)
	
	inten *= 1e8		// 1/A to 1/cm
	//inten = Sq
	Return (inten+bkg)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedLamellarPS(coefW,yW,xW)
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
	err = SmearedLamellarPS(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedLamellarPS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_76(LamellarPS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
////