#pragma rtGlobals=1		// Use modern global access method.


// the "scale" or "volume fraction" factor is the "material" volume fraction
// - i.e. the volume fraction of surfactant added. NOT the excluded volume
// of the vesicles, which can be much larger. See the Vesicle_Volume_N_Rg macro
//
// this excluded volume is accounted for in the structure factor calculations.
//

#include "Vesicle_UL"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotVesicle_HS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	//make the normal model waves
	Make/O/D/n=(num) xwave_ves_HS,ywave_ves_HS					
	xwave_ves_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_ves_HS = {0.1,100,30,6.36e-6,0.5e-6,0}						
	make/o/t parameters_ves_HS = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","bkg (cm-1)"}		
	Edit/K=1 parameters_ves_HS,coef_ves_HS								
	ywave_ves_HS := Vesicle_HS(coef_ves_HS,xwave_ves_HS)			
	Display/K=1 ywave_ves_HS vs xwave_ves_HS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedVesicle_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ves_HS = {0.1,100,30,6.36e-6,0.5e-6,0}					
	make/o/t smear_parameters_ves_HS = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","bkg (cm-1)"}		
	Edit smear_parameters_ves_HS,smear_coef_ves_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ves_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_ves_HS							

	smeared_ves_HS := SmearedVesicle_HS(smear_coef_ves_HS,$gQvals)		
	Display smeared_ves_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Vesicle_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_ves_HS
	form_ves_HS[0] = 1
	form_ves_HS[1] = w[1]
	form_ves_HS[2] = w[2]
	form_ves_HS[3] = w[3]
	form_ves_HS[4] = w[4]
	form_ves_HS[5] = 0
	
	// calculate the excluded volume of the vesicles
	Variable totvol,core,shell,exclVol,nden
	totvol=4*pi/3*(w[1]+w[2])^3
	core=4*pi/3*(w[1])^3
	shell = totVol-core
	//	nden = phi/(shell volume) or phi/Vtotal
	nden = w[0]/shell
	exclVol = nden*totvol

	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_ves_HS
	struct_ves_HS[0] = w[1] + w[2]
	struct_ves_HS[1] = exclVol
	
	//calculate each and combine
	inten = VesicleForm(form_ves_HS,x)
	inten *= HardSphereStruct(struct_ves_HS,x)
	inten *= w[0]
	inten += w[5]
	
	//cleanup waves
	//Killwaves/Z form_ves_HS,struct_ves_HS
	
	return (inten)
End

/////////////////////////////////
Proc PlotVesicle_SW(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	///
	Make/O/D/N=4 form_ves_SW
	Make/O/D/N=4 struct_ves_SW
	///
	Make/O/D/n=(num) xwave_ves_SW,ywave_ves_SW					
	xwave_ves_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_ves_SW = {0.1,100,30,6.36e-6,0.5e-6,1,1.2,0}						
	make/o/t parameters_ves_SW = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit/K=1 parameters_ves_SW,coef_ves_SW								
	ywave_ves_SW := Vesicle_SW(coef_ves_SW,xwave_ves_SW)			
	Display/K=1 ywave_ves_SW vs xwave_ves_SW							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedVesicle_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ves_SW = {0.1,100,30,6.36e-6,0.5e-6,1,1.2,0}						
	make/o/t smear_parameters_ves_SW = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit smear_parameters_ves_SW,smear_coef_ves_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ves_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_ves_SW							

	smeared_ves_SW := SmearedVesicle_SW(smear_coef_ves_SW,$gQvals)		
	Display smeared_ves_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Vesicle_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_ves_SW
	form_ves_SW[0] = 1
	form_ves_SW[1] = w[1]
	form_ves_SW[2] = w[2]
	form_ves_SW[3] = w[3]
	form_ves_SW[4] = w[4]
	form_ves_SW[5] = 0
	
	// calculate the excluded volume of the vesicles
	Variable totvol,core,shell,exclVol,nden
	totvol=4*pi/3*(w[1]+w[2])^3
	core=4*pi/3*(w[1])^3
	shell = totVol-core
	//	nden = phi/(shell volume) or phi/Vtotal
	nden = w[0]/shell
	exclVol = nden*totvol
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_ves_SW
	struct_ves_SW[0] = w[1] + w[2]
	struct_ves_SW[1] = exclVol
	struct_ves_SW[2] = w[5]
	struct_ves_SW[3] = w[6]
	
	//calculate each and combine
	inten = VesicleForm(form_ves_SW,x)
	inten *= SquareWellStruct(struct_ves_SW,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
	//Killwaves/Z form_ves_SW,struct_ves_SW
	
	return (inten)
End

/////////////////////////////////
Proc PlotVesicle_SC(num,qmin,qmax)						
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
	
	///
	Make/O/D/n=(num) xwave_ves_SC,ywave_ves_SC					
	xwave_ves_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))				
	Make/O/D coef_ves_SC = {0.1,100,30,6.36e-6,0.5e-6,20,0,298,78,0}						
	make/o/t parameters_ves_SC = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit/K=1 parameters_ves_SC,coef_ves_SC								
	ywave_ves_SC := Vesicle_SC(coef_ves_SC,xwave_ves_SC)			
	Display/K=1 ywave_ves_SC vs xwave_ves_SC							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedVesicle_SC()								
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
	Make/O/D smear_coef_ves_SC = {0.1,100,30,6.36e-6,0.5e-6,20,0,298,78,0}						
	make/o/t smear_parameters_ves_SC = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit smear_parameters_ves_SC,smear_coef_ves_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ves_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_ves_SC							

	smeared_ves_SC := SmearedVesicle_SC(smear_coef_ves_SC,$gQvals)		
	Display smeared_ves_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Vesicle_SC(w,x) : FitFunc
	Wave w
	Variable x
	
//	Variable timer=StartMSTimer
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_ves_SC
	form_ves_SC[0] = 1
	form_ves_SC[1] = w[1]
	form_ves_SC[2] = w[2]
	form_ves_SC[3] = w[3]
	form_ves_SC[4] = w[4]
	form_ves_SC[5] = 0
	
	// calculate the excluded volume of the vesicles
	Variable totvol,core,shell,exclVol,nden
	totvol=4*pi/3*(w[1]+w[2])^3
	core=4*pi/3*(w[1])^3
	shell = totVol-core
	//	nden = phi/(shell volume) or phi/Vtotal
	nden = w[0]/shell
	exclVol = nden*totvol
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_ves_SC
	struct_ves_SC[0] = 2*(w[1]+w[2])		//diameter
	struct_ves_SC[1] = w[5]
	struct_ves_SC[2] = exclVol
	struct_ves_SC[3] = w[7]
	struct_ves_SC[4] = w[6]
	struct_ves_SC[5] = w[8]
	
	//calculate each and combine
	inten = VesicleForm(form_ves_SC,x)
	inten *= HayterPenfoldMSA(struct_ves_SC,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
	//Killwaves/Z form_ves_SC,struct_ves_SC
	//Print "ps elapsed time = ",StopMSTimer(timer)
	return (inten)
End

/////////////////////////////////
Proc PlotVesicle_SHS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	///
	Make/O/D/N=4 form_ves_SHS
	Make/O/D/N=4 struct_ves_SHS
	///
	Make/O/D/n=(num) xwave_ves_SHS,ywave_ves_SHS					
	xwave_ves_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_ves_SHS = {0.1,100,30,6.36e-6,0.5e-6,0.05,0.2,0}							
	make/o/t parameters_ves_SHS = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit/K=1 parameters_ves_SHS,coef_ves_SHS								
	ywave_ves_SHS := Vesicle_SHS(coef_ves_SHS,xwave_ves_SHS)			
	Display/K=1 ywave_ves_SHS vs xwave_ves_SHS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedVesicle_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_ves_SHS = {0.1,100,30,6.36e-6,0.5e-6,0.05,0.2,0}							
	make/o/t smear_parameters_ves_SHS = {"Volume fraction","core radius (A)","shell thickness (A)","Core and Solvent SLD (A-2)","Shell SLD (A-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit smear_parameters_ves_SHS,smear_coef_ves_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_ves_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_ves_SHS							

	smeared_ves_SHS := SmearedVesicle_SHS(smear_coef_ves_SHS,$gQvals)		
	Display smeared_ves_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function Vesicle_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_ves_SHS
	form_ves_SHS[0] = 1
	form_ves_SHS[1] = w[1]
	form_ves_SHS[2] = w[2]
	form_ves_SHS[3] = w[3]
	form_ves_SHS[4] = w[4]
	form_ves_SHS[5] = 0
	
	// calculate the excluded volume of the vesicles
	Variable totvol,core,shell,exclVol,nden
	totvol=4*pi/3*(w[1]+w[2])^3
	core=4*pi/3*(w[1])^3
	shell = totVol-core
	//	nden = phi/(shell volume) or phi/Vtotal
	nden = w[0]/shell
	exclVol = nden*totvol
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_ves_SHS
	struct_ves_SHS[0] = w[1]+w[2]
	struct_ves_SHS[1] = exclVol
	struct_ves_SHS[2] = w[5]
	struct_ves_SHS[3] = w[6]
	
	//calculate each and combine
	inten = VesicleForm(form_ves_SHS,x)
	inten *= StickyHS_Struct(struct_ves_SHS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
	//Killwaves/Z form_ves_SHS,struct_ves_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedVesicle_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Vesicle_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedVesicle_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Vesicle_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedVesicle_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Vesicle_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedVesicle_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(Vesicle_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
