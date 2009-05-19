#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// model function that calculates the scattering from 
// lamellar surfactant structures. contrast is two-phase,
// from the solvent and uniform bilayer. The system is
// considered to be DILUTE - Interference (S(Q)) effects
// are NOT taken into account. ONLY the form factor is calculated
//
//
// REFERENCE:	Nallet, Laversanne, and Roux, J. Phys. II France, 3, (1993) 487-502.
//		also in J. Phys. Chem. B, 105, (2001) 11081-11088.
//
// 16 JULY 2003 SRK
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotLamellarFF(num,qmin,qmax)
	Variable num=128, qmin=.001, qmax=.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_LamellarFF, ywave_LamellarFF
	xwave_LamellarFF =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_LamellarFF = {1,50,0.15,1e-6,6.3e-6,0}			//CH#2
	make/o/t parameters_LamellarFF = {"Scale","Bilayer Thick (delta) (A)","polydisp of thickness","SLD bilayer (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_LamellarFF, coef_LamellarFF
	ModifyTable width(parameters_LamellarFF)=160
	
	Variable/G root:g_LamellarFF
	g_LamellarFF := LamellarFF(coef_LamellarFF, ywave_LamellarFF,xwave_LamellarFF)
	Display ywave_LamellarFF vs xwave_LamellarFF
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("LamellarFF","coef_LamellarFF","parameters_LamellarFF","LamellarFF")
//
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedLamellarFF(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_LamellarFF = {1,50,0.15,1e-6,6.3e-6,0}		//CH#4
	make/o/t smear_parameters_LamellarFF = {"Scale","Bilayer Thick (delta) (A)","polydisp of thickness","SLD bilayer (A^-2)","SLD solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_LamellarFF,smear_coef_LamellarFF					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_LamellarFF,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_LamellarFF							//
					
	Variable/G gs_LamellarFF=0
	gs_LamellarFF := fSmearedLamellarFF(smear_coef_LamellarFF,smeared_LamellarFF,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_LamellarFF vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	
	AddModelToStrings("SmearedLamellarFF","smear_coef_LamellarFF","smear_parameters_LamellarFF","LamellarFF")
End
////////////////////////////////////////////////////
	


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function LamellarFF(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("LamellarFFX")
	yw = LamellarFFX(cw,xw)
#else
	yw = fLamellarFF(cw,xw)
#endif
	return(0)
End

//CH#1
// you should write your function to calculate the intensity
// for a single q-value (that's the input parameter x)
// based on the wave (array) of parameters that you send it (w)
//
Function fLamellarFF(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//[0]Scale
//[1]Bilay Thick (delta)
//[2] polydispersity of thickness
//[3] sld bilayer
//[4] sld solv
//[5]Incoherent Bgd (cm-1)
	
//	give them nice names
	Variable scale,dd,del,sig,contr,NN,Cp,bkg,sldb,slds
	scale = w[0]
	del = w[1]
	sig = w[2]*del
	sldb = w[3]
	slds = w[4]
	bkg = w[5]
	
	contr = sldb - slds
//	local variables
	Variable inten, qval,Pq,Sq,ii,alpha,temp,t1,t2,t3,dQ
	
	//	x is the q-value for the calculation
	qval = x
	
	Pq = 2*contr^2/qval/qval*(1-cos(qval*del)*exp(-0.5*qval^2*sig^2))
	
	inten = 2*Pi*scale*Pq/Qval^2		//this is now dimensionless...
	
	inten /= del			//normalize by the thickness (in A)
	
	inten *= 1e8		// 1/A to 1/cm
	
	Return (inten+bkg)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedLamellarFF(coefW,yW,xW)
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
	err = SmearedLamellarFF(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedLamellarFF(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(LamellarFF,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End