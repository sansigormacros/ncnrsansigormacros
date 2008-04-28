#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all the necessary files...

#include "EffectiveDiameter"
#include "UniformEllipsoid"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotEllipsoid_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_HS,ywave_EOR_HS
	xwave_EOR_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_HS = {0.01,20.,400,3.0e-6,0.01}
	make/o/t parameters_EOR_HS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_HS,coef_EOR_HS
	ywave_EOR_HS := Ellipsoid_HS(coef_EOR_HS,xwave_EOR_HS)
	Display ywave_EOR_HS vs xwave_EOR_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedEllipsoid_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_HS = {0.01,20.,400,3.0e-6,0.01}
	make/o/t smear_parameters_EOR_HS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_HS,smear_coef_EOR_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_EOR_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_HS							

	smeared_EOR_HS := SmearedEllipsoid_HS(smear_coef_EOR_HS,$gQvals)		
	Display smeared_EOR_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Ellipsoid_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_EOR_HS
	form_EOR_HS[0] = 1
	form_EOR_HS[1] = w[1]
	form_EOR_HS[2] = w[2]
	form_EOR_HS[3] = w[3]
	form_EOR_HS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_EOR_HS
	struct_EOR_HS[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_HS[1] = w[0]
	
	//calculate each and combine
	inten = EllipsoidForm(form_EOR_HS,x)
	inten *= HardSphereStruct(struct_EOR_HS,x)
	inten *= w[0]
	inten += w[4]
	
	//cleanup waves
//	Killwaves/Z form_EOR_HS,struct_EOR_HS
	
	return (inten)
End

Proc PlotEllipsoid_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_SW,ywave_EOR_SW
	xwave_EOR_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SW = {0.01,20.,400,3.0e-6,1.0,1.2,0.01}
	make/o/t parameters_EOR_SW = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SW,coef_EOR_SW
	ywave_EOR_SW := Ellipsoid_SW(coef_EOR_SW,xwave_EOR_SW)
	Display ywave_EOR_SW vs xwave_EOR_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedEllipsoid_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_SW = {0.01,20.,400,3.0e-6,1.0,1.2,0.01}
	make/o/t smear_parameters_EOR_SW = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SW,smear_coef_EOR_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_EOR_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SW							

	smeared_EOR_SW := SmearedEllipsoid_SW(smear_coef_EOR_SW,$gQvals)		
	Display smeared_EOR_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Ellipsoid_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_EOR_SW
	form_EOR_SW[0] = 1
	form_EOR_SW[1] = w[1]
	form_EOR_SW[2] = w[2]
	form_EOR_SW[3] = w[3]
	form_EOR_SW[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_EOR_SW
	struct_EOR_SW[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_SW[1] = w[0]
	struct_EOR_SW[2] = w[4]
	struct_EOR_SW[3] = w[5]
	
	//calculate each and combine
	inten = EllipsoidForm(form_EOR_SW,x)
	inten *= SquareWellStruct(struct_EOR_SW,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SW,struct_EOR_SW
	
	return (inten)
End

Proc PlotEllipsoid_SC(num,qmin,qmax)
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
	
	Make/O/D/n=(num) xwave_EOR_SC,ywave_EOR_SC
	xwave_EOR_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SC = {0.01,20.,400,3.0e-6,20,0,298,78,0.01}
	make/o/t parameters_EOR_SC = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SC,coef_EOR_SC
	ywave_EOR_SC := Ellipsoid_SC(coef_EOR_SC,xwave_EOR_SC)
	Display ywave_EOR_SC vs xwave_EOR_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedEllipsoid_SC()								
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
	Make/O/D smear_coef_EOR_SC = {0.01,20.,400,3.0e-6,20,0,298,78,0.01}
	make/o/t smear_parameters_EOR_SC = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SC,smear_coef_EOR_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_EOR_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SC							

	smeared_EOR_SC := SmearedEllipsoid_SC(smear_coef_EOR_SC,$gQvals)		
	Display smeared_EOR_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End


Function Ellipsoid_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_EOR_SC
	form_EOR_SC[0] = 1
	form_EOR_SC[1] = w[1]
	form_EOR_SC[2] = w[2]
	form_EOR_SC[3] = w[3]
	form_EOR_SC[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_EOR_SC
	struct_EOR_SC[0] = DiamEllip(aa,bb)
	struct_EOR_SC[1] = w[4]
	struct_EOR_SC[2] = w[0]
	struct_EOR_SC[3] = w[6]
	struct_EOR_SC[4] = w[5]
	struct_EOR_SC[5] = w[7]
	
	//calculate each and combine
	inten = EllipsoidForm(form_EOR_SC,x)
	inten *= HayterPenfoldMSA(struct_EOR_SC,x)
	inten *= w[0]
	inten += w[8]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SC,struct_EOR_SC
	
	return (inten)
End

Proc PlotEllipsoid_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_SHS,ywave_EOR_SHS
	xwave_EOR_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SHS = {0.01,20.,400,3.0e-6,0.05,0.2,0.01}
	make/o/t parameters_EOR_SHS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SHS,coef_EOR_SHS
	ywave_EOR_SHS := Ellipsoid_SHS(coef_EOR_SHS,xwave_EOR_SHS)
	Display ywave_EOR_SHS vs xwave_EOR_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedEllipsoid_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_SHS = {0.01,20.,400,3.0e-6,0.05,0.2,0.01}
	make/o/t smear_parameters_EOR_SHS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","contrast (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SHS,smear_coef_EOR_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_EOR_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SHS							

	smeared_EOR_SHS := SmearedEllipsoid_SHS(smear_coef_EOR_SHS,$gQvals)		
	Display smeared_EOR_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Ellipsoid_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_EOR_SHS
	form_EOR_SHS[0] = 1
	form_EOR_SHS[1] = w[1]
	form_EOR_SHS[2] = w[2]
	form_EOR_SHS[3] = w[3]
	form_EOR_SHS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_EOR_SHS
	struct_EOR_SHS[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_SHS[1] = w[0]
	struct_EOR_SHS[2] = w[4]
	struct_EOR_SHS[3] = w[5]
	
	//calculate each and combine
	inten = EllipsoidForm(form_EOR_SHS,x)
	inten *= StickyHS_Struct(struct_EOR_SHS,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SHS,struct_EOR_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedEllipsoid_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Ellipsoid_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Ellipsoid_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Ellipsoid_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Ellipsoid_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End