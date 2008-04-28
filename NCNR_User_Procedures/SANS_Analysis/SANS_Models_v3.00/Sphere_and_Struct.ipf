#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all the necessary files...

#include "Sphere"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotSphere_HS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	//make the normal model waves
	Make/O/D/n=(num) xwave_S_HS,ywave_S_HS					
	xwave_S_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_HS = {0.1,60,1e-6,0.01}						
	make/o/t parameters_S_HS = {"volume fraction","Radius (A)","contrast (Å-2)","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_HS,coef_S_HS								
	ywave_S_HS := Sphere_HS(coef_S_HS,xwave_S_HS)			
	Display/K=1 ywave_S_HS vs xwave_S_HS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSphere_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_HS = {0.1,60,1e-6,0.01}						
	make/o/t smear_parameters_S_HS = {"volume fraction","Radius (A)","contrast (Å-2)","bkgd (cm-1)"}		
	Edit smear_parameters_S_HS,smear_coef_S_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_S_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_HS							

	smeared_S_HS := SmearedSphere_HS(smear_coef_S_HS,$gQvals)		
	Display smeared_S_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Sphere_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=4 form_S_HS
	form_S_HS[0] = 1
	form_S_HS[1] = w[1]
	form_S_HS[2] = w[2]
	form_S_HS[3] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_S_HS
	struct_S_HS[0] = w[1]
	struct_S_HS[1] = w[0]
	
	//calculate each and combine
	inten = SphereForm(form_S_HS,x)
	inten *= HardSphereStruct(struct_S_HS,x)
	inten *= w[0]
	inten += w[3]
	
	//cleanup waves
	//Killwaves/Z form_S_HS,struct_S_HS
	
	return (inten)
End

/////////////////////////////////
Proc PlotSphere_SW(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	///
	Make/O/D/N=4 form_S_SW
	Make/O/D/N=4 struct_S_SW
	///
	Make/O/D/n=(num) xwave_S_SW,ywave_S_SW					
	xwave_S_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_SW = {0.1,60,1e-6,1.0,1.2,0.01}						
	make/o/t parameters_S_SW = {"volume fraction","Radius (A)","contrast (Å-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SW,coef_S_SW								
	ywave_S_SW := Sphere_SW(coef_S_SW,xwave_S_SW)			
	Display/K=1 ywave_S_SW vs xwave_S_SW							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSphere_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_SW = {0.1,60,1e-6,1.0,1.2,0.01}						
	make/o/t smear_parameters_S_SW = {"volume fraction","Radius (A)","contrast (Å-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit smear_parameters_S_SW,smear_coef_S_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_S_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SW							

	smeared_S_SW := SmearedSphere_SW(smear_coef_S_SW,$gQvals)		
	Display smeared_S_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Sphere_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=4 form_S_SW
	form_S_SW[0] = 1
	form_S_SW[1] = w[1]
	form_S_SW[2] = w[2]
	form_S_SW[3] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_S_SW
	struct_S_SW[0] = w[1]
	struct_S_SW[1] = w[0]
	struct_S_SW[2] = w[3]
	struct_S_SW[3] = w[4]
	
	//calculate each and combine
	inten = SphereForm(form_S_SW,x)
	inten *= SquareWellStruct(struct_S_SW,x)
	inten *= w[0]
	inten += w[5]
	
	//cleanup waves
	//Killwaves/Z form_S_SW,struct_S_SW
	
	return (inten)
End

/////////////////////////////////
Proc PlotSphere_SC(num,qmin,qmax)						
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
	
	///
	Make/O/D/n=(num) xwave_S_SC,ywave_S_SC					
	xwave_S_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))				
	Make/O/D coef_S_SC = {0.2,50,3e-6,20,0,298,78,0.0001}						
	make/o/t parameters_S_SC = {"volume fraction","Radius (A)","contrast (Å-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SC,coef_S_SC								
	ywave_S_SC := Sphere_SC(coef_S_SC,xwave_S_SC)			
	Display/K=1 ywave_S_SC vs xwave_S_SC							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSphere_SC()								
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
	Make/O/D smear_coef_S_SC = {0.2,50,3e-6,20,0,298,78,0.0001}						
	make/o/t smear_parameters_S_SC = {"volume fraction","Radius (A)","contrast (Å-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit smear_parameters_S_SC,smear_coef_S_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_S_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SC							

	smeared_S_SC := SmearedSphere_SC(smear_coef_S_SC,$gQvals)		
	Display smeared_S_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Sphere_SC(w,x) : FitFunc
	Wave w
	Variable x
	
//	Variable timer=StartMSTimer
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=4 form_S_SC
	form_S_SC[0] = 1
	form_S_SC[1] = w[1]
	form_S_SC[2] = w[2]
	form_S_SC[3] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_S_SC
	struct_S_SC[0] = 2*w[1]		//diameter
	struct_S_SC[1] = w[3]
	struct_S_SC[2] = w[0]
	struct_S_SC[3] = w[5]
	struct_S_SC[4] = w[4]
	struct_S_SC[5] = w[6]
	
	//calculate each and combine
	inten = SphereForm(form_S_SC,x)
	inten *= HayterPenfoldMSA(struct_S_SC,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
	//Killwaves/Z form_S_SC,struct_S_SC
	//Print "ps elapsed time = ",StopMSTimer(timer)
	return (inten)
End

/////////////////////////////////
Proc PlotSphere_SHS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	///
	Make/O/D/N=4 form_S_SHS
	Make/O/D/N=4 struct_S_SHS
	///
	Make/O/D/n=(num) xwave_S_SHS,ywave_S_SHS					
	xwave_S_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_SHS = {0.1,60,1e-6,0.05,0.2,0.01}						
	make/o/t parameters_S_SHS = {"volume fraction","Radius (A)","contrast (Å-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SHS,coef_S_SHS								
	ywave_S_SHS := Sphere_SHS(coef_S_SHS,xwave_S_SHS)			
	Display/K=1 ywave_S_SHS vs xwave_S_SHS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSphere_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_SHS = {0.1,60,1e-6,0.05,0.2,0.01}						
	make/o/t smear_parameters_S_SHS = {"volume fraction","Radius (A)","contrast (Å-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit smear_parameters_S_SHS,smear_coef_S_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_S_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SHS							

	smeared_S_SHS := SmearedSphere_SHS(smear_coef_S_SHS,$gQvals)		
	Display smeared_S_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Sphere_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=4 form_S_SHS
	form_S_SHS[0] = 1
	form_S_SHS[1] = w[1]
	form_S_SHS[2] = w[2]
	form_S_SHS[3] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_S_SHS
	struct_S_SHS[0] = w[1]
	struct_S_SHS[1] = w[0]
	struct_S_SHS[2] = w[3]
	struct_S_SHS[3] = w[4]
	
	//calculate each and combine
	inten = SphereForm(form_S_SHS,x)
	inten *= StickyHS_Struct(struct_S_SHS,x)
	inten *= w[0]
	inten += w[5]
	
	//cleanup waves
	//Killwaves/Z form_S_SHS,struct_S_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedSphere_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Sphere_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSphere_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Sphere_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSphere_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Sphere_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSphere_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Sphere_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
