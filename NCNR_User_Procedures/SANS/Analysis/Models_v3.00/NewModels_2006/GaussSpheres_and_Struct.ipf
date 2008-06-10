#pragma rtGlobals=1		// Use modern global access method.
//
// be sure to include all of the necessary files
//
#include "GaussSpheres"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotGaussPolySphere_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_pgs_HS,ywave_pgs_HS
	xwave_pgs_HS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pgs_HS = {0.01,60,0.2,1e-6,3e-6,0.001}
	make/O/T parameters_pgs_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_pgs_HS,coef_pgs_HS
	ywave_pgs_HS := GaussPolySphere_HS(coef_pgs_HS,xwave_pgs_HS)
	Display ywave_pgs_HS vs xwave_pgs_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedGaussPolySphere_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pgs_HS = {0.01,60,0.2,1e-6,3e-6,0.001}					
	make/o/t smear_parameters_pgs_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_pgs_HS,smear_coef_pgs_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_pgs_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgs_HS							

	smeared_pgs_HS := SmearedGaussPolySphere_HS(smear_coef_pgs_HS,$gQvals)		
	Display smeared_pgs_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function GaussPolySphere_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_pgs_HS
	form_pgs_HS[0] = 1
	form_pgs_HS[1] = w[1]
	form_pgs_HS[2] = w[2]
	form_pgs_HS[3] = w[3]
	form_pgs_HS[4] = w[4]
	form_pgs_HS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_pgs_HS
	struct_pgs_HS[0] = diam/2
	struct_pgs_HS[1] = w[0]
	
	//calculate each and combine
	inten = GaussPolySphere(form_pgs_HS,x)
	inten *= HardSphereStruct(struct_pgs_HS,x)
	inten *= w[0]
	inten += w[5]
	
	//cleanup waves
//	Killwaves/Z form_pgs_HS,struct_pgs_HS
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotGaussPolySphere_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_pgs_SW,ywave_pgs_SW
	xwave_pgs_SW = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pgs_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}
	make/O/T parameters_pgs_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}
	Edit parameters_pgs_SW,coef_pgs_SW
	ywave_pgs_SW := GaussPolySphere_SW(coef_pgs_SW,xwave_pgs_SW)
	Display ywave_pgs_SW vs xwave_pgs_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedGaussPolySphere_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pgs_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}					
	make/o/t smear_parameters_pgs_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_pgs_SW,smear_coef_pgs_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_pgs_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgs_SW							

	smeared_pgs_SW := SmearedGaussPolySphere_SW(smear_coef_pgs_SW,$gQvals)		
	Display smeared_pgs_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function GaussPolySphere_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_pgs_SW
	form_pgs_SW[0] = 1
	form_pgs_SW[1] = w[1]
	form_pgs_SW[2] = w[2]
	form_pgs_SW[3] = w[3]
	form_pgs_SW[4] = w[4]
	form_pgs_SW[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_pgs_SW
	struct_pgs_SW[0] = diam/2
	struct_pgs_SW[1] = w[0]
	struct_pgs_SW[2] = w[5]
	struct_pgs_SW[3] = w[6]
	
	//calculate each and combine
	inten = GaussPolySphere(form_pgs_SW,x)
	inten *= SquareWellStruct(struct_pgs_SW,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_pgs_SW,struct_pgs_SW
	
	return (inten)
End


/////////////////////////////////////////
Proc PlotGaussPolySphere_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif

	Make/O/D/N=(num) xwave_pgs_SC,ywave_pgs_SC
	xwave_pgs_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pgs_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}
	make/O/T parameters_pgs_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}
	Edit parameters_pgs_SC,coef_pgs_SC
	ywave_pgs_SC := GaussPolySphere_SC(coef_pgs_SC,xwave_pgs_SC)
	Display ywave_pgs_SC vs xwave_pgs_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedGaussPolySphere_SC()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif

	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pgs_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}					
	make/o/t smear_parameters_pgs_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_pgs_SC,smear_coef_pgs_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_pgs_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgs_SC							

	smeared_pgs_SC := SmearedGaussPolySphere_SC(smear_coef_pgs_SC,$gQvals)		
	Display smeared_pgs_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function GaussPolySphere_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_pgs_SC
	form_pgs_SC[0] = 1
	form_pgs_SC[1] = w[1]
	form_pgs_SC[2] = w[2]
	form_pgs_SC[3] = w[3]
	form_pgs_SC[4] = w[4]
	form_pgs_SC[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_pgs_SC
	struct_pgs_SC[0] = diam
	struct_pgs_SC[1] = w[5]
	struct_pgs_SC[2] = w[0]
	struct_pgs_SC[3] = w[7]
	struct_pgs_SC[4] = w[6]
	struct_pgs_SC[5] = w[8]
	
	//calculate each and combine
	inten = GaussPolySphere(form_pgs_SC,x)
	inten *= HayterPenfoldMSA(struct_pgs_SC,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_pgs_SC,struct_pgs_SC
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotGaussPolySphere_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_pgs_SHS,ywave_pgs_SHS
	xwave_pgs_SHS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pgs_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}
	make/O/T parameters_pgs_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}
	Edit parameters_pgs_SHS,coef_pgs_SHS
	ywave_pgs_SHS := GaussPolySphere_SHS(coef_pgs_SHS,xwave_pgs_SHS)
	Display ywave_pgs_SHS vs xwave_pgs_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedGaussPolySphere_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pgs_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}					
	make/o/t smear_parameters_pgs_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_pgs_SHS,smear_coef_pgs_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_pgs_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgs_SHS							

	smeared_pgs_SHS := SmearedGaussPolySphere_SHS(smear_coef_pgs_SHS,$gQvals)		
	Display smeared_pgs_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function GaussPolySphere_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_pgs_SHS
	form_pgs_SHS[0] = 1
	form_pgs_SHS[1] = w[1]
	form_pgs_SHS[2] = w[2]
	form_pgs_SHS[3] = w[3]
	form_pgs_SHS[4] = w[4]
	form_pgs_SHS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_pgs_SHS
	struct_pgs_SHS[0] = diam/2
	struct_pgs_SHS[1] = w[0]
	struct_pgs_SHS[2] = w[5]
	struct_pgs_SHS[3] = w[6]
	
	//calculate each and combine
	inten = GaussPolySphere(form_pgs_SHS,x)
	inten *= StickyHS_Struct(struct_pgs_SHS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_pgs_SHS,struct_pgs_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedGaussPolySphere_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(GaussPolySphere_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedGaussPolySphere_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(GaussPolySphere_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedGaussPolySphere_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(GaussPolySphere_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedGaussPolySphere_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(GaussPolySphere_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End