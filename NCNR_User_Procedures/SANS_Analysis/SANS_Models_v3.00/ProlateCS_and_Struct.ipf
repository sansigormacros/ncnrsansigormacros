#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all the necessary files...
#include "ProlateForm"
#include "EffectiveDiameter"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotProlate_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_HS,ywave_PEF_HS
	xwave_PEF_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_HS = {0.01,100,50,110,60,1e-6,2e-6,0.0001}
	make/o/t parameters_PEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","bkg (cm-1)"}
	Edit parameters_PEF_HS,coef_PEF_HS
	ywave_PEF_HS := Prolate_HS(coef_PEF_HS,xwave_PEF_HS)
	Display ywave_PEF_HS vs xwave_PEF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedProlate_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_HS = {0.01,100,50,110,60,1e-6,2e-6,0.0001}
	make/o/t smear_parameters_PEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","bkg (cm-1)"}
	Edit smear_parameters_PEF_HS,smear_coef_PEF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PEF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_HS							

	smeared_PEF_HS := SmearedProlate_HS(smear_coef_PEF_HS,$gQvals)		
	Display smeared_PEF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Prolate_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PEF_HS
	form_PEF_HS[0] = 1
	form_PEF_HS[1] = w[1]
	form_PEF_HS[2] = w[2]
	form_PEF_HS[3] = w[3]
	form_PEF_HS[4] = w[4]
	form_PEF_HS[5] = w[5]
	form_PEF_HS[6] = w[6]
	form_PEF_HS[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_PEF_HS
	struct_PEF_HS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_HS[1] = w[0]
	
	//calculate each and combine
	inten = ProlateForm(form_PEF_HS,x)
	inten *= HardSphereStruct(struct_PEF_HS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_PEF_HS,struct_PEF_HS
	
	return (inten)
End

Proc PlotProlate_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_SW,ywave_PEF_SW
	xwave_PEF_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SW = {0.01,100,50,110,60,1e-6,2e-6,1.0,1.2,0.0001}
	make/o/t parameters_PEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit parameters_PEF_SW,coef_PEF_SW
	ywave_PEF_SW := Prolate_SW(coef_PEF_SW,xwave_PEF_SW)
	Display ywave_PEF_SW vs xwave_PEF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedProlate_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_SW = {0.01,100,50,110,60,1e-6,2e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_PEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_PEF_SW,smear_coef_PEF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PEF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SW							

	smeared_PEF_SW := SmearedProlate_SW(smear_coef_PEF_SW,$gQvals)		
	Display smeared_PEF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Prolate_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PEF_SW
	form_PEF_SW[0] = 1
	form_PEF_SW[1] = w[1]
	form_PEF_SW[2] = w[2]
	form_PEF_SW[3] = w[3]
	form_PEF_SW[4] = w[4]
	form_PEF_SW[5] = w[5]
	form_PEF_SW[6] = w[6]
	form_PEF_SW[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PEF_SW
	struct_PEF_SW[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_SW[1] = w[0]
	struct_PEF_SW[2] = w[7]
	struct_PEF_SW[3] = w[8]
	
	//calculate each and combine
	inten = ProlateForm(form_PEF_SW,x)
	inten *= SquareWellStruct(struct_PEF_SW,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SW,struct_PEF_SW
	
	return (inten)
End

Proc PlotProlate_SC(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif
	
	Make/O/D/n=(num) xwave_PEF_SC,ywave_PEF_SC
	xwave_PEF_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SC = {0.01,100,50,110,60,1e-6,2e-6,20,0,298,78,0.0001}
	make/o/t parameters_PEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit parameters_PEF_SC,coef_PEF_SC
	ywave_PEF_SC := Prolate_SC(coef_PEF_SC,xwave_PEF_SC)
	Display ywave_PEF_SC vs xwave_PEF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedProlate_SC()								
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
	Make/O/D smear_coef_PEF_SC = {0.01,100,50,110,60,1e-6,2e-6,20,0,298,78,0.0001}
	make/o/t smear_parameters_PEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit smear_parameters_PEF_SC,smear_coef_PEF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PEF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SC							

	smeared_PEF_SC := SmearedProlate_SC(smear_coef_PEF_SC,$gQvals)		
	Display smeared_PEF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Prolate_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PEF_SC
	form_PEF_SC[0] = 1
	form_PEF_SC[1] = w[1]
	form_PEF_SC[2] = w[2]
	form_PEF_SC[3] = w[3]
	form_PEF_SC[4] = w[4]
	form_PEF_SC[5] = w[5]
	form_PEF_SC[6] = w[6]
	form_PEF_SC[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PEF_SC
	struct_PEF_SC[0] = DiamEllip(Ras,Rbs)
	struct_PEF_SC[1] = w[7]
	struct_PEF_SC[2] = w[0]
	struct_PEF_SC[3] = w[9]
	struct_PEF_SC[4] = w[8]
	struct_PEF_SC[5] = w[10]
	
	//calculate each and combine
	inten = ProlateForm(form_PEF_SC,x)
	inten *= HayterPenfoldMSA(struct_PEF_SC,x)
	inten *= w[0]
	inten += w[11]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SC,struct_PEF_SC
	
	return (inten)
End


Proc PlotProlate_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_SHS,ywave_PEF_SHS
	xwave_PEF_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,0.05,0.2,0.0001}
	make/o/t parameters_PEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit parameters_PEF_SHS,coef_PEF_SHS
	ywave_PEF_SHS := Prolate_SHS(coef_PEF_SHS,xwave_PEF_SHS)
	Display ywave_PEF_SHS vs xwave_PEF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedProlate_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_PEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_PEF_SHS,smear_coef_PEF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PEF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SHS							

	smeared_PEF_SHS := SmearedProlate_SHS(smear_coef_PEF_SHS,$gQvals)		
	Display smeared_PEF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Prolate_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PEF_SHS
	form_PEF_SHS[0] = 1
	form_PEF_SHS[1] = w[1]
	form_PEF_SHS[2] = w[2]
	form_PEF_SHS[3] = w[3]
	form_PEF_SHS[4] = w[4]
	form_PEF_SHS[5] = w[5]
	form_PEF_SHS[6] = w[6]
	form_PEF_SHS[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PEF_SHS
	struct_PEF_SHS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_SHS[1] = w[0]
	struct_PEF_SHS[2] = w[7]
	struct_PEF_SHS[3] = w[8]
	
	//calculate each and combine
	inten = ProlateForm(form_PEF_SHS,x)
	inten *= StickyHS_Struct(struct_PEF_SHS,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SHS,struct_PEF_SHS
	
	return (inten)
End


// this is all there is to the smeared calculation!
Function SmearedProlate_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Prolate_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Prolate_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Prolate_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Prolate_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End