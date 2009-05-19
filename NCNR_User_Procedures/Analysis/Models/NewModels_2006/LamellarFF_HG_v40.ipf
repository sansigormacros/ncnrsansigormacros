#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// model function that calculates the scattering from 
// lamellar surfactant structures. contrast is from the solvent,
// surfactant headgroups, and surfactant tails
//
// The system is considered to be DILUTE - Interference (S(Q))
// effects are NOT taken into account.
// ONLY the form factor is calculated
//
// REFERENCE:	Nallet, Laversanne, and Roux, J. Phys. II France, 3, (1993) 487-502.
//		also in J. Phys. Chem. B, 105, (2001) 11081-11088.
//
// 16 JULY 2003 SRK
// 13 FEB 06 correct normalization (L.Porcar)
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotLamellarFF_HG(num,qmin,qmax)
	Variable num=128, qmin=.001, qmax=.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_LamellarFF_HG, ywave_LamellarFF_HG
	xwave_LamellarFF_HG =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_LamellarFF_HG = {1,15,10,4e-7,3e-6,6e-6,0}			//CH#2
	make/o/t parameters_LamellarFF_HG = {"Scale","Tail length (A)","Headgroup thickness (A)","SLD Tails (A^-2)","SLD Headgroup (A^-2)","SLD Solvent (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_LamellarFF_HG, coef_LamellarFF_HG
	ModifyTable width(parameters_LamellarFF_HG)=160
	
	Variable/G root:g_LamellarFF_HG
	g_LamellarFF_HG := LamellarFF_HG(coef_LamellarFF_HG, ywave_LamellarFF_HG, xwave_LamellarFF_HG)
	Display ywave_LamellarFF_HG vs xwave_LamellarFF_HG
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("LamellarFF_HG","coef_LamellarFF_HG","parameters_LamellarFF_HG","LamellarFF_HG")
//
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedLamellarFF_HG(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_LamellarFF_HG = {1,15,10,4e-7,3e-6,6e-6,0}		//CH#4
	make/o/t smear_parameters_LamellarFF_HG = {"Scale","Tail length (A)","Headgroup thickness (A)","SLD Tails (A^-2)","SLD Headgroup (A^-2)","SLD Solvent (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_LamellarFF_HG,smear_coef_LamellarFF_HG					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_LamellarFF_HG,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_LamellarFF_HG							//
					
	Variable/G gs_LamellarFF_HG=0
	gs_LamellarFF_HG := fSmearedLamellarFF_HG(smear_coef_LamellarFF_HG,smeared_LamellarFF_HG,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_LamellarFF_HG vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedLamellarFF_HG","smear_coef_LamellarFF_HG","smear_parameters_LamellarFF_HG","LamellarFF_HG")
End



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function LamellarFF_HG(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("LamellarFF_HGX")
	yw = LamellarFF_HGX(cw,xw)
#else
	yw = fLamellarFF_HG(cw,xw)
#endif
	return(0)
End

//CH#1
// you should write your function to calculate the intensity
// for a single q-value (that's the input parameter x)
// based on the wave (array) of parameters that you send it (w)
//
Function fLamellarFF_HG(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//[0]Scale
//[1]tail length
//[2]hg thickness
//[3]sld tail
//[4]sld HG
//[5]sld solvent
//[6]Incoherent Bgd (cm-1)
	
//	give them nice names
	Variable scale,delT,delH,slds,sldh,sldt,sig,contr,NN,Cp,bkg
	scale = w[0]
	delT = w[1]
	delH = w[2]
	sldt = w[3]
	sldh = w[4]
	slds = w[5]
	bkg = w[6]
	
//	local variables
	Variable inten, qval,Pq,drh,drt
	
	//	x is the q-value for the calculation
	qval = x
	drh = sldh - slds
	drt = sldt - slds		//correction 13FEB06 by L.Porcar
	
	Pq = drh*(sin(qval*(delH+delT))-sin(qval*delT)) + drt*sin(qval*delT)
	Pq *= Pq
	Pq *= 4/(qval^2)
	
	inten = 2*Pi*scale*Pq/Qval^2		//dimensionless...
	
	inten /= 2*(delT+delH)			//normalize by the bilayer thickness
	
	inten *= 1e8		// 1/A to 1/cm
	Return (inten+bkg)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedLamellarFF_HG(coefW,yW,xW)
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
	err = SmearedLamellarFF_HG(fs)
	
	return (0)
End

//the smeared model calculation
Function SmearedLamellarFF_HG(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(LamellarFF_HG,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End