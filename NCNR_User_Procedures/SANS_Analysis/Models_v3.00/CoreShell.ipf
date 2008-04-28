#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
//
// this function is for the form factor of a sphere with a core-shell structure
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotCoreShellSphere(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_css,ywave_css
	xwave_css =alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_css = {1.,60,10,1e-6,2e-6,3e-6,0.001}
	make/o/t parameters_css = {"scale","core radius (A)","shell thickness (A)","Core SLD (A-2)","Shell SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}
	Edit parameters_css,coef_css
	ywave_css := CoreShellForm(coef_css,xwave_css)
	Display ywave_css vs xwave_css
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedCoreShellSphere()								//**** name of your function
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	make/o/d smear_coef_css = {1.,60,10,1e-6,2e-6,3e-6,0.001}
	make/o/t smear_parameters_css = {"scale","core radius (A)","shell thickness (A)","Core SLD (A-2)","Shell SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}
	Edit smear_parameters_css,smear_coef_css
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	
	Duplicate/O $gQvals smeared_css,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_css							

	smeared_css := SmearedCoreShellForm(smear_coef_css,$gQvals)									
	Display smeared_css vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function CoreShellForm(w,x) : FitFunc
	Wave w
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of core [Å]
	//[2] thickness of the shell	[Å]
	//[3] SLD of the core	[Å-2]
	//[4] SLD of the shell
	//[5] SLD of the solvent
	//[6] background	[cm-1]
	
	// All inputs are in ANGSTROMS
	//OUTPUT is normalized by the particle volume, and converted to [cm-1]
	
	
	Variable scale,rcore,thick,rhocore,rhoshel,rhosolv,bkg
	scale = w[0]
	rcore = w[1]
	thick = w[2]
	rhocore = w[3]
	rhoshel = w[4]
	rhosolv = w[5]
	bkg = w[6]
	
	// calculates scale *( f^2 + bkg)
	Variable bes,f,vol,qr,contr,f2
	
	// core first, then add in shell
	qr=x*rcore
	contr = rhocore-rhoshel
	bes = 3*(sin(qr)-qr*cos(qr))/qr^3
	vol = 4*pi/3*rcore^3
	f = vol*bes*contr
	//now the shell
	qr=x*(rcore+thick)
	contr = rhoshel-rhosolv
	bes = 3*(sin(qr)-qr*cos(qr))/qr^3
	vol = 4*pi/3*(rcore+thick)^3
	f += vol*bes*contr
	
	// normalize to particle volume and rescale from [Å-1] to [cm-1]
	f2 = f*f/vol*1.0e8
	
	//scale if desired
	f2 *= scale
	// then add in the background
	f2 += bkg
	
	return (f2)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShellForm(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShellForm,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
