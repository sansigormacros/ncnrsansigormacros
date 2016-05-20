#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// be sure to include all the necessary files...
#include "ProlateCoreShell_v40"
#include "EffectiveDiameter_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"
#include "Two_Yukawa_v40"

Proc PlotProlate_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_HS,ywave_PEF_HS
	xwave_PEF_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_HS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.0001}
	make/o/t parameters_PEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit parameters_PEF_HS,coef_PEF_HS
	
	Variable/G root:g_PEF_HS
	g_PEF_HS := Prolate_HS(coef_PEF_HS,ywave_PEF_HS,xwave_PEF_HS)
	Display ywave_PEF_HS vs xwave_PEF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Prolate_HS","coef_PEF_HS","parameters_PEF_HS","PEF_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlate_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_HS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.0001}
	make/o/t smear_parameters_PEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_PEF_HS,smear_coef_PEF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PEF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_HS							
					
	Variable/G gs_PEF_HS=0
	gs_PEF_HS := fSmearedProlate_HS(smear_coef_PEF_HS,smeared_PEF_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PEF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlate_HS","smear_coef_PEF_HS","smear_parameters_PEF_HS","PEF_HS")
End
	

Function Prolate_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_PEF_HS
	form_PEF_HS[0] = 1
	form_PEF_HS[1] = w[1]
	form_PEF_HS[2] = w[2]
	form_PEF_HS[3] = w[3]
	form_PEF_HS[4] = w[4]
	form_PEF_HS[5] = w[5]
	form_PEF_HS[6] = w[6]
	form_PEF_HS[7] = w[7]
	form_PEF_HS[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_PEF_HS
	struct_PEF_HS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_PEF_HS_PQ,temp_PEF_HS_SQ		//make waves for the AAO
	ProlateForm(form_PEF_HS,temp_PEF_HS_PQ,xw)
	HardSphereStruct(struct_PEF_HS,temp_PEF_HS_SQ,xw)
	yw = temp_PEF_HS_PQ *temp_PEF_HS_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_PEF_HS,struct_PEF_HS
	
	return (0)
End

Proc PlotProlate_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_SW,ywave_PEF_SW
	xwave_PEF_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SW = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t parameters_PEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit parameters_PEF_SW,coef_PEF_SW
	
	Variable/G root:g_PEF_SW
	g_PEF_SW := Prolate_SW(coef_PEF_SW,ywave_PEF_SW,xwave_PEF_SW)
	Display ywave_PEF_SW vs xwave_PEF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Prolate_SW","coef_PEF_SW","parameters_PEF_SW","PEF_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlate_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_SW = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_PEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_PEF_SW,smear_coef_PEF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PEF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SW							
					
	Variable/G gs_PEF_SW=0
	gs_PEF_SW := fSmearedProlate_SW(smear_coef_PEF_SW,smeared_PEF_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PEF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlate_SW","smear_coef_PEF_SW","smear_parameters_PEF_SW","PEF_SW")
End
	

Function Prolate_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_PEF_SW
	form_PEF_SW[0] = 1
	form_PEF_SW[1] = w[1]
	form_PEF_SW[2] = w[2]
	form_PEF_SW[3] = w[3]
	form_PEF_SW[4] = w[4]
	form_PEF_SW[5] = w[5]
	form_PEF_SW[6] = w[6]
	form_PEF_SW[7] = w[7]
	form_PEF_SW[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PEF_SW
	struct_PEF_SW[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_SW[1] = w[0]
	struct_PEF_SW[2] = w[8]
	struct_PEF_SW[3] = w[9]
	
	//calculate each and combine
	Duplicate/O xw temp_PEF_SW_PQ,temp_PEF_SW_SQ		//make waves for the AAO
	ProlateForm(form_PEF_SW,temp_PEF_SW_PQ,xw)
	SquareWellStruct(struct_PEF_SW,temp_PEF_SW_SQ,xw)
	yw = temp_PEF_SW_PQ * temp_PEF_SW_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SW,struct_PEF_SW
	
	return (0)
End

Proc PlotProlate_SC(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_PEF_SC,ywave_PEF_SC
	xwave_PEF_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SC = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,20,0,298,78,0.0001}
	make/o/t parameters_PEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit parameters_PEF_SC,coef_PEF_SC
	
	Variable/G root:g_PEF_SC
	g_PEF_SC := Prolate_SC(coef_PEF_SC,ywave_PEF_SC,xwave_PEF_SC)
	Display ywave_PEF_SC vs xwave_PEF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Prolate_SC","coef_PEF_SC","parameters_PEF_SC","PEF_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlate_SC(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_SC = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,20,0,298,78,0.0001}
	make/o/t smear_parameters_PEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit smear_parameters_PEF_SC,smear_coef_PEF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PEF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SC							
					
	Variable/G gs_PEF_SC=0
	gs_PEF_SC := fSmearedProlate_SC(smear_coef_PEF_SC,smeared_PEF_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PEF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlate_SC","smear_coef_PEF_SC","smear_parameters_PEF_SC","PEF_SC")
End


Function Prolate_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_PEF_SC
	form_PEF_SC[0] = 1
	form_PEF_SC[1] = w[1]
	form_PEF_SC[2] = w[2]
	form_PEF_SC[3] = w[3]
	form_PEF_SC[4] = w[4]
	form_PEF_SC[5] = w[5]
	form_PEF_SC[6] = w[6]
	form_PEF_SC[7] = w[7]
	form_PEF_SC[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PEF_SC
	struct_PEF_SC[0] = DiamEllip(Ras,Rbs)
	struct_PEF_SC[1] = w[8]
	struct_PEF_SC[2] = w[0]
	struct_PEF_SC[3] = w[10]
	struct_PEF_SC[4] = w[9]
	struct_PEF_SC[5] = w[11]
	
	//calculate each and combine
	Duplicate/O xw temp_PEF_SC_PQ,temp_PEF_SC_SQ		//make waves for the AAO
	ProlateForm(form_PEF_SC,temp_PEF_SC_PQ,xw)
	HayterPenfoldMSA(struct_PEF_SC,temp_PEF_SC_SQ,xw)
	yw = temp_PEF_SC_PQ * temp_PEF_SC_SQ
	yw *= w[0]
	yw += w[12]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SC,struct_PEF_SC
	
	return (0)
End


Proc PlotProlate_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_SHS,ywave_PEF_SHS
	xwave_PEF_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t parameters_PEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit parameters_PEF_SHS,coef_PEF_SHS
	
	Variable/G root:g_PEF_SHS
	g_PEF_SHS := Prolate_SHS(coef_PEF_SHS,ywave_PEF_SHS,xwave_PEF_SHS)
	Display ywave_PEF_SHS vs xwave_PEF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Prolate_SHS","coef_PEF_SHS","parameters_PEF_SHS","PEF_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlate_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_PEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_PEF_SHS,smear_coef_PEF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PEF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_SHS							
					
	Variable/G gs_PEF_SHS=0
	gs_PEF_SHS := fSmearedProlate_SHS(smear_coef_PEF_SHS,smeared_PEF_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PEF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlate_SHS","smear_coef_PEF_SHS","smear_parameters_PEF_SHS","PEF_SHS")
End
	

Function Prolate_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_PEF_SHS
	form_PEF_SHS[0] = 1
	form_PEF_SHS[1] = w[1]
	form_PEF_SHS[2] = w[2]
	form_PEF_SHS[3] = w[3]
	form_PEF_SHS[4] = w[4]
	form_PEF_SHS[5] = w[5]
	form_PEF_SHS[6] = w[6]
	form_PEF_SHS[7] = w[7]
	form_PEF_SHS[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PEF_SHS
	struct_PEF_SHS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_SHS[1] = w[0]
	struct_PEF_SHS[2] = w[8]
	struct_PEF_SHS[3] = w[9]
	
	//calculate each and combine
	Duplicate/O xw temp_PEF_SHS_PQ,temp_PEF_SHS_SQ		//make waves for the AAO
	ProlateForm(form_PEF_SHS,temp_PEF_SHS_PQ,xw)
	StickyHS_Struct(struct_PEF_SHS,temp_PEF_SHS_SQ,xw)
	yw = temp_PEF_SHS_PQ * temp_PEF_SHS_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_PEF_SHS,struct_PEF_SHS
	
	return (0)
End

// two yukawa
Proc PlotProlate_2Y(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PEF_2Y,ywave_PEF_2Y
	xwave_PEF_2Y =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PEF_2Y = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,6,10,-1,2,0.0001}
	make/o/t parameters_PEF_2Y = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","scale, K1","charge, Z1","scale, K2","charge, Z2","bkg (cm-1)"}
	Edit parameters_PEF_2Y,coef_PEF_2Y
	
	Variable/G root:g_PEF_2Y
	g_PEF_2Y := Prolate_2Y(coef_PEF_2Y,ywave_PEF_2Y,xwave_PEF_2Y)
	Display ywave_PEF_2Y vs xwave_PEF_2Y
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Prolate_2Y","coef_PEF_2Y","parameters_PEF_2Y","PEF_2Y")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedProlate_2Y(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PEF_2Y = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,6,10,-1,2,0.0001}
	make/o/t smear_parameters_PEF_2Y = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","scale, K1","charge, Z1","scale, K2","charge, Z2","bkg (cm-1)"}
	Edit smear_parameters_PEF_2Y,smear_coef_PEF_2Y					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PEF_2Y,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PEF_2Y							
					
	Variable/G gs_PEF_2Y=0
	gs_PEF_2Y := fSmearedProlate_2Y(smear_coef_PEF_2Y,smeared_PEF_2Y,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PEF_2Y vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedProlate_2Y","smear_coef_PEF_2Y","smear_parameters_PEF_2Y","PEF_2Y")
End
	

Function Prolate_2Y(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[3]	//Ras is the rotation axis
	Rbs = w[4]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_PEF_2Y
	form_PEF_2Y[0] = 1
	form_PEF_2Y[1] = w[1]
	form_PEF_2Y[2] = w[2]
	form_PEF_2Y[3] = w[3]
	form_PEF_2Y[4] = w[4]
	form_PEF_2Y[5] = w[5]
	form_PEF_2Y[6] = w[6]
	form_PEF_2Y[7] = w[7]
	form_PEF_2Y[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PEF_2Y
	struct_PEF_2Y[0] = w[0]
	struct_PEF_2Y[1] = 0.5*DiamEllip(Ras,Rbs)
	struct_PEF_2Y[2] = w[8]
	struct_PEF_2Y[3] = w[9]
	struct_PEF_2Y[4] = w[10]
	struct_PEF_2Y[5] = w[11]
	
	//calculate each and combine
	Duplicate/O xw temp_PEF_2Y_PQ,temp_PEF_2Y_SQ		//make waves for the AAO
	ProlateForm(form_PEF_2Y,temp_PEF_2Y_PQ,xw)
	TwoYukawa(struct_PEF_2Y,temp_PEF_2Y_SQ,xw)
	yw = temp_PEF_2Y_PQ *temp_PEF_2Y_SQ
	yw *= w[0]
	yw += w[12]
	
	//cleanup waves
//	Killwaves/Z form_PEF_2Y,struct_PEF_2Y
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Prolate_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Prolate_Sw,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Prolate_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Prolate_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedProlate_2Y(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Prolate_2Y,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlate_HS(coefW,yW,xW)
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
	err = SmearedProlate_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlate_SW(coefW,yW,xW)
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
	err = SmearedProlate_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlate_SC(coefW,yW,xW)
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
	err = SmearedProlate_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlate_SHS(coefW,yW,xW)
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
	err = SmearedProlate_SHS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedProlate_2Y(coefW,yW,xW)
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
	err = SmearedProlate_2Y(fs)
	
	return (0)
End
