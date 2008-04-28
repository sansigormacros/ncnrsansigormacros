#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all the necessary files...
#include "EffectiveDiameter"
#include "CylinderForm"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotCylinder_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_HS,ywave_CYL_HS
	xwave_CYL_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_HS = {0.01,20.,400,3.0e-6,0.01}
	make/o/t parameters_CYL_HS = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_HS,coef_CYL_HS
	ywave_CYL_HS := Cylinder_HS(coef_CYL_HS,xwave_CYL_HS)
	Display ywave_CYL_HS vs xwave_CYL_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCylinder_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
		
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_HS = {0.01,20.,400,3.0e-6,0.01}
	make/o/t smear_parameters_CYL_HS = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_HS,smear_coef_CYL_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CYL_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_HS							

	smeared_CYL_HS := SmearedCylinder_HS(smear_coef_CYL_HS,$gQvals)		
	Display smeared_CYL_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Cylinder_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_CYL_HS
	form_CYL_HS[0] = 1
	form_CYL_HS[1] = w[1]
	form_CYL_HS[2] = w[2]
	form_CYL_HS[3] = w[3]
	form_CYL_HS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_CYL_HS
	struct_CYL_HS[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_HS[1] = w[0]
	
	//calculate each and combine
	inten = CylinderForm(form_CYL_HS,x)
	inten *= HardSphereStruct(struct_CYL_HS,x)
	inten *= w[0]
	inten += w[4]
	
	//cleanup waves (don't do this - it takes a lot of time...)
//	Killwaves/Z form_CYL_HS,struct_CYL_HS
	
	return (inten)
End

Proc PlotCylinder_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_SW,ywave_CYL_SW
	xwave_CYL_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SW = {0.01,20.,400,3.0e-6,1.0,1.2,0.01}
	make/o/t parameters_CYL_SW = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SW,coef_CYL_SW
	ywave_CYL_SW := Cylinder_SW(coef_CYL_SW,xwave_CYL_SW)
	Display ywave_CYL_SW vs xwave_CYL_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCylinder_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_SW = {0.01,20.,400,3.0e-6,1.0,1.2,0.01}
	make/o/t smear_parameters_CYL_SW = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SW,smear_coef_CYL_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CYL_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SW							

	smeared_CYL_SW := SmearedCylinder_SW(smear_coef_CYL_SW,$gQvals)		
	Display smeared_CYL_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Cylinder_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_CYL_SW
	form_CYL_SW[0] = 1
	form_CYL_SW[1] = w[1]
	form_CYL_SW[2] = w[2]
	form_CYL_SW[3] = w[3]
	form_CYL_SW[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CYL_SW
	struct_CYL_SW[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_SW[1] = w[0]
	struct_CYL_SW[2] = w[4]
	struct_CYL_SW[3] = w[5]
	
	//calculate each and combine
	inten = CylinderForm(form_CYL_SW,x)
	inten *= SquareWellStruct(struct_CYL_SW,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SW,struct_CYL_SW
	
	return (inten)
End

Proc PlotCylinder_SC(num,qmin,qmax)
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
	
	Make/O/D/n=(num) xwave_CYL_SC,ywave_CYL_SC
	xwave_CYL_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SC = {0.01,20.,400,3.0e-6,20,0,298,78,0.01}
	make/o/t parameters_CYL_SC = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SC,coef_CYL_SC
	ywave_CYL_SC := Cylinder_SC(coef_CYL_SC,xwave_CYL_SC)
	Display ywave_CYL_SC vs xwave_CYL_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCylinder_SC()								
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
	Make/O/D smear_coef_CYL_SC = {0.01,20.,400,3.0e-6,20,0,298,78,0.01}
	make/o/t smear_parameters_CYL_SC = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SC,smear_coef_CYL_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CYL_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SC							

	smeared_CYL_SC := SmearedCylinder_SC(smear_coef_CYL_SC,$gQvals)		
	Display smeared_CYL_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Cylinder_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_CYL_SC
	form_CYL_SC[0] = 1
	form_CYL_SC[1] = w[1]
	form_CYL_SC[2] = w[2]
	form_CYL_SC[3] = w[3]
	form_CYL_SC[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_CYL_SC
	struct_CYL_SC[0] = DiamCyl(len,rad)
	struct_CYL_SC[1] = w[4]
	struct_CYL_SC[2] = w[0]
	struct_CYL_SC[3] = w[6]
	struct_CYL_SC[4] = w[5]
	struct_CYL_SC[5] = w[7]
	
	//calculate each and combine
	inten = CylinderForm(form_CYL_SC,x)
	inten *= HayterPenfoldMSA(struct_CYL_SC,x)
	inten *= w[0]
	inten += w[8]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SC,struct_CYL_SC
	
	return (inten)
End


Proc PlotCylinder_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_SHS,ywave_CYL_SHS
	xwave_CYL_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SHS = {0.01,20.0,400,3.0e-6,0.05,0.2,0.01}
	make/o/t parameters_CYL_SHS = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SHS,coef_CYL_SHS
	ywave_CYL_SHS := Cylinder_SHS(coef_CYL_SHS,xwave_CYL_SHS)
	Display ywave_CYL_SHS vs xwave_CYL_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedCylinder_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_SHS = {0.01,20.0,400,3.0e-6,0.05,0.2,0.01}
	make/o/t smear_parameters_CYL_SHS = {"volume fraction","radius (A)","length (A)","contrast (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SHS,smear_coef_CYL_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_CYL_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SHS							

	smeared_CYL_SHS := SmearedCylinder_SHS(smear_coef_CYL_SHS,$gQvals)		
	Display smeared_CYL_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Cylinder_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_CYL_SHS
	form_CYL_SHS[0] = 1
	form_CYL_SHS[1] = w[1]
	form_CYL_SHS[2] = w[2]
	form_CYL_SHS[3] = w[3]
	form_CYL_SHS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CYL_SHS
	struct_CYL_SHS[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_SHS[1] = w[0]
	struct_CYL_SHS[2] = w[4]
	struct_CYL_SHS[3] = w[5]
	
	//calculate each and combine
	inten = CylinderForm(form_CYL_SHS,x)
	inten *= StickyHS_Struct(struct_CYL_SHS,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SHS,struct_CYL_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedCylinder_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Cylinder_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Cylinder_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Cylinder_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Cylinder_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End