#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all of the necessary files

#include "OblateForm"
#include "EffectiveDiameter"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotOblate_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_HS,ywave_OEF_HS
	xwave_OEF_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_HS = {0.01,100,50,110,60,1e-6,2e-6,0.0001}
	make/o/t parameters_OEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","bkg (cm-1)"}
	Edit parameters_OEF_HS,coef_OEF_HS
	ywave_OEF_HS := Oblate_HS(coef_OEF_HS,xwave_OEF_HS)
	Display ywave_OEF_HS vs xwave_OEF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedOblate_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_HS = {0.01,100,50,110,60,1e-6,2e-6,0.0001}
	make/o/t smear_parameters_OEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","bkg (cm-1)"}
	Edit smear_parameters_OEF_HS,smear_coef_OEF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_OEF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_HS							

	smeared_OEF_HS := SmearedOblate_HS(smear_coef_OEF_HS,$gQvals)		
	Display smeared_OEF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Oblate_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis, the minor axis for an oblate ellipsoid
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_OEF_HS
	form_OEF_HS[0] = 1
	form_OEF_HS[1] = w[1]
	form_OEF_HS[2] = w[2]
	form_OEF_HS[3] = w[3]
	form_OEF_HS[4] = w[4]
	form_OEF_HS[5] = w[5]
	form_OEF_HS[6] = w[6]
	form_OEF_HS[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_OEF_HS
	struct_OEF_HS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_HS[1] = w[0]
	
	//calculate each and combine
	inten = OblateForm(form_OEF_HS,x)
	inten *= HardSphereStruct(struct_OEF_HS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_OEF_HS,struct_OEF_HS
	
	return (inten)
End

Proc PlotOblate_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_SW,ywave_OEF_SW
	xwave_OEF_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SW = {0.01,100,50,110,60,1e-6,2e-6,1.0,1.2,0.0001}
	make/o/t parameters_OEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit parameters_OEF_SW,coef_OEF_SW
	ywave_OEF_SW := Oblate_SW(coef_OEF_SW,xwave_OEF_SW)
	Display ywave_OEF_SW vs xwave_OEF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedOblate_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_SW = {0.01,100,50,110,60,1e-6,2e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_OEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_OEF_SW,smear_coef_OEF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_OEF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SW							

	smeared_OEF_SW := SmearedOblate_SW(smear_coef_OEF_SW,$gQvals)		
	Display smeared_OEF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Oblate_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_OEF_SW
	form_OEF_SW[0] = 1
	form_OEF_SW[1] = w[1]
	form_OEF_SW[2] = w[2]
	form_OEF_SW[3] = w[3]
	form_OEF_SW[4] = w[4]
	form_OEF_SW[5] = w[5]
	form_OEF_SW[6] = w[6]
	form_OEF_SW[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_OEF_SW
	struct_OEF_SW[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_SW[1] = w[0]
	struct_OEF_SW[2] = w[7]
	struct_OEF_SW[3] = w[8]
	
	//calculate each and combine
	inten = OblateForm(form_OEF_SW,x)
	inten *= SquareWellStruct(struct_OEF_SW,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SW,struct_OEF_SW
	
	return (inten)
End

Proc PlotOblate_SC(num,qmin,qmax)
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
	
	Make/O/D/n=(num) xwave_OEF_SC,ywave_OEF_SC
	xwave_OEF_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SC = {0.01,100,50,110,60,1e-6,2e-6,20,0,298,78,0.0001}
	make/o/t parameters_OEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit parameters_OEF_SC,coef_OEF_SC
	ywave_OEF_SC := Oblate_SC(coef_OEF_SC,xwave_OEF_SC)
	Display ywave_OEF_SC vs xwave_OEF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedOblate_SC()								
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
	Make/O/D smear_coef_OEF_SC = {0.01,100,50,110,60,1e-6,2e-6,20,0,298,78,0.0001}
	make/o/t smear_parameters_OEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit smear_parameters_OEF_SC,smear_coef_OEF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_OEF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SC							

	smeared_OEF_SC := SmearedOblate_SC(smear_coef_OEF_SC,$gQvals)		
	Display smeared_OEF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Oblate_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_OEF_SC
	form_OEF_SC[0] = 1
	form_OEF_SC[1] = w[1]
	form_OEF_SC[2] = w[2]
	form_OEF_SC[3] = w[3]
	form_OEF_SC[4] = w[4]
	form_OEF_SC[5] = w[5]
	form_OEF_SC[6] = w[6]
	form_OEF_SC[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_OEF_SC
	struct_OEF_SC[0] = DiamEllip(Ras,Rbs)
	struct_OEF_SC[1] = w[7]
	struct_OEF_SC[2] = w[0]
	struct_OEF_SC[3] = w[9]
	struct_OEF_SC[4] = w[8]
	struct_OEF_SC[5] = w[10]
	
	//calculate each and combine
	inten = OblateForm(form_OEF_SC,x)
	inten *= HayterPenfoldMSA(struct_OEF_SC,x)
	inten *= w[0]
	inten += w[11]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SC,struct_OEF_SC
	
	return (inten)
End


Proc PlotOblate_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_SHS,ywave_OEF_SHS
	xwave_OEF_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,0.05,0.2,0.0001}
	make/o/t parameters_OEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit parameters_OEF_SHS,coef_OEF_SHS
	ywave_OEF_SHS := Oblate_SHS(coef_OEF_SHS,xwave_OEF_SHS)
	Display ywave_OEF_SHS vs xwave_OEF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedOblate_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_OEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","Contrast (core-shell) (A-2)","Constrast (shell-solvent) (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_OEF_SHS,smear_coef_OEF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_OEF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SHS							

	smeared_OEF_SHS := SmearedOblate_SHS(smear_coef_OEF_SHS,$gQvals)		
	Display smeared_OEF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Oblate_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_OEF_SHS
	form_OEF_SHS[0] = 1
	form_OEF_SHS[1] = w[1]
	form_OEF_SHS[2] = w[2]
	form_OEF_SHS[3] = w[3]
	form_OEF_SHS[4] = w[4]
	form_OEF_SHS[5] = w[5]
	form_OEF_SHS[6] = w[6]
	form_OEF_SHS[7] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_OEF_SHS
	struct_OEF_SHS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_SHS[1] = w[0]
	struct_OEF_SHS[2] = w[7]
	struct_OEF_SHS[3] = w[8]
	
	//calculate each and combine
	inten = OblateForm(form_OEF_SHS,x)
	inten *= StickyHS_Struct(struct_OEF_SHS,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SHS,struct_OEF_SHS
	
	return (inten)
End


// this is all there is to the smeared calculation!
Function SmearedOblate_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Oblate_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Oblate_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Oblate_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Oblate_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End