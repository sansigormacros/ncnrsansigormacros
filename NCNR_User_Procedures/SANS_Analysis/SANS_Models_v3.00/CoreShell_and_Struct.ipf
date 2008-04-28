#pragma rtGlobals=1		// Use modern global access method.
//// include everything that is necessary
//
#include "CoreShell"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotCoreShell_HS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CSS_HS,ywave_CSS_HS
	xwave_CSS_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CSS_HS = {0.1,60,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t parameters_CSS_HS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit/K=1 parameters_CSS_HS,coef_CSS_HS
	ywave_CSS_HS := CoreShell_HS(coef_CSS_HS,xwave_CSS_HS)
	Display/K=1 ywave_CSS_HS vs xwave_CSS_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCoreShell_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_HS = {0.1,60,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t smear_parameters_CSS_HS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_CSS_HS,smear_coef_CSS_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CSS_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_HS							

	smeared_CSS_HS := SmearedCoreShell_HS(smear_coef_CSS_HS,$gQvals)		
	Display smeared_CSS_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function CoreShell_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_CSS_HS
	form_CSS_HS[0] = 1
	form_CSS_HS[1] = w[1]
	form_CSS_HS[2] = w[2]
	form_CSS_HS[3] = w[3]
	form_CSS_HS[4] = w[4]
	form_CSS_HS[5] = w[5]
	form_CSS_HS[6] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_CSS_HS
	struct_CSS_HS[0] = w[1] + w[2]
	struct_CSS_HS[1] = w[0]
	
	//calculate each and combine
	inten = CoreShellForm(form_CSS_HS,x)
	inten *= HardSphereStruct(struct_CSS_HS,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_CSS_HS,struct_CSS_HS
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotCoreShell_SW(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CSS_SW,ywave_CSS_SW
	xwave_CSS_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CSS_SW = {0.1,60,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t parameters_CSS_SW = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit/K=1 parameters_CSS_SW,coef_CSS_SW
	ywave_CSS_SW := CoreShell_SW(coef_CSS_SW,xwave_CSS_SW)
	Display/K=1 ywave_CSS_SW vs xwave_CSS_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCoreShell_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_SW = {0.1,60,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_CSS_SW = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_CSS_SW,smear_coef_CSS_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CSS_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SW							

	smeared_CSS_SW := SmearedCoreShell_SW(smear_coef_CSS_SW,$gQvals)		
	Display smeared_CSS_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function CoreShell_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_CSS_SW
	form_CSS_SW[0] = 1
	form_CSS_SW[1] = w[1]
	form_CSS_SW[2] = w[2]
	form_CSS_SW[3] = w[3]
	form_CSS_SW[4] = w[4]
	form_CSS_SW[5] = w[5]
	form_CSS_SW[6] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CSS_SW
	struct_CSS_SW[0] = w[1] + w[2]
	struct_CSS_SW[1] = w[0]
	struct_CSS_SW[2] = w[6]
	struct_CSS_SW[3] = w[7]
	
	//calculate each and combine
	inten = CoreShellForm(form_CSS_SW,x)
	inten *= SquareWellStruct(struct_CSS_SW,x)
	inten *= w[0]
	inten += w[8]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SW,struct_CSS_SW
	
	return (inten)
End


/////////////////////////////////////////
Proc PlotCoreShell_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif
	
	Make/O/D/n=(num) xwave_CSS_SC,ywave_CSS_SC
	xwave_CSS_SC = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CSS_SC = {0.1,60,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t parameters_CSS_SC = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_CSS_SC,coef_CSS_SC
	ywave_CSS_SC := CoreShell_SC(coef_CSS_SC,xwave_CSS_SC)
	Display/K=1 ywave_CSS_SC vs xwave_CSS_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCoreShell_SC()								
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
	Make/O/D smear_coef_CSS_SC = {0.1,60,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_CSS_SC = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_CSS_SC,smear_coef_CSS_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CSS_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SC							

	smeared_CSS_SC := SmearedCoreShell_SC(smear_coef_CSS_SC,$gQvals)		
	Display smeared_CSS_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function CoreShell_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_CSS_SC
	form_CSS_SC[0] = 1
	form_CSS_SC[1] = w[1]
	form_CSS_SC[2] = w[2]
	form_CSS_SC[3] = w[3]
	form_CSS_SC[4] = w[4]
	form_CSS_SC[5] = w[5]
	form_CSS_SC[6] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_CSS_SC
	struct_CSS_SC[0] = 2*(w[1]+w[2])
	struct_CSS_SC[1] = w[6]
	struct_CSS_SC[2] = w[0]
	struct_CSS_SC[3] = w[8]
	struct_CSS_SC[4] = w[7]
	struct_CSS_SC[5] = w[9]
	
	//calculate each and combine
	inten = CoreShellForm(form_CSS_SC,x)
	inten *= HayterPenfoldMSA(struct_CSS_SC,x)
	inten *= w[0]
	inten += w[10]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SC,struct_CSS_SC
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotCoreShell_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CSS_SHS,ywave_CSS_SHS
	xwave_CSS_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CSS_SHS = {0.1,60,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t parameters_CSS_SHS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit/K=1 parameters_CSS_SHS,coef_CSS_SHS
	ywave_CSS_SHS := CoreShell_SHS(coef_CSS_SHS,xwave_CSS_SHS)
	Display/K=1 ywave_CSS_SHS vs xwave_CSS_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCoreShell_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_SHS = {0.1,60,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_CSS_SHS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_CSS_SHS,smear_coef_CSS_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CSS_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SHS							

	smeared_CSS_SHS := SmearedCoreShell_SHS(smear_coef_CSS_SHS,$gQvals)		
	Display smeared_CSS_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function CoreShell_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_CSS_SHS
	form_CSS_SHS[0] = 1
	form_CSS_SHS[1] = w[1]
	form_CSS_SHS[2] = w[2]
	form_CSS_SHS[3] = w[3]
	form_CSS_SHS[4] = w[4]
	form_CSS_SHS[5] = w[5]
	form_CSS_SHS[6] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CSS_SHS
	struct_CSS_SHS[0] = w[1] + w[2]
	struct_CSS_SHS[1] = w[0]
	struct_CSS_SHS[2] = w[6]
	struct_CSS_SHS[3] = w[7]
	
	//calculate each and combine
	inten = CoreShellForm(form_CSS_SHS,x)
	inten *= StickyHS_Struct(struct_CSS_SHS,x)
	inten *= w[0]
	inten += w[8]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SHS,struct_CSS_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedCoreShell_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShell_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShell_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShell_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(CoreShell_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End