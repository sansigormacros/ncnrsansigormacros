#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// be sure to include all of the necessary files

#include "OblateCoreShell_v40"
#include "EffectiveDiameter_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotOblate_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_HS,ywave_OEF_HS
	xwave_OEF_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_HS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.0001}
	make/o/t parameters_OEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit parameters_OEF_HS,coef_OEF_HS
	
	Variable/G root:g_OEF_HS
	g_OEF_HS := Oblate_HS(coef_OEF_HS,ywave_OEF_HS,xwave_OEF_HS)
	Display ywave_OEF_HS vs xwave_OEF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Oblate_HS","coef_OEF_HS","OEF_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOblate_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_HS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.0001}
	make/o/t smear_parameters_OEF_HS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit smear_parameters_OEF_HS,smear_coef_OEF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_OEF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_HS							
					
	Variable/G gs_OEF_HS=0
	gs_OEF_HS := fSmearedOblate_HS(smear_coef_OEF_HS,smeared_OEF_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_OEF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOblate_HS","smear_coef_OEF_HS","OEF_HS")
End
	

Function Oblate_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis, the minor axis for an oblate ellipsoid
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_OEF_HS
	form_OEF_HS[0] = 1
	form_OEF_HS[1] = w[1]
	form_OEF_HS[2] = w[2]
	form_OEF_HS[3] = w[3]
	form_OEF_HS[4] = w[4]
	form_OEF_HS[5] = w[5]
	form_OEF_HS[6] = w[6]
	form_OEF_HS[7] = w[7]
	form_OEF_HS[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_OEF_HS
	struct_OEF_HS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_OEF_HS_PQ,temp_OEF_HS_SQ		//make waves for the AAO
	OblateForm(form_OEF_HS,temp_OEF_HS_PQ,xw)
	HardSphereStruct(struct_OEF_HS,temp_OEF_HS_SQ,xw)
	yw = temp_OEF_HS_PQ * temp_OEF_HS_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_OEF_HS,struct_OEF_HS
	
	return (0)
End

Proc PlotOblate_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_SW,ywave_OEF_SW
	xwave_OEF_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SW = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t parameters_OEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit parameters_OEF_SW,coef_OEF_SW
	
	Variable/G root:g_OEF_SW
	g_OEF_SW := Oblate_SW(coef_OEF_SW,ywave_OEF_SW,xwave_OEF_SW)
	Display ywave_OEF_SW vs xwave_OEF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Oblate_SW","coef_OEF_SW","OEF_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOblate_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_SW = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_OEF_SW = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_OEF_SW,smear_coef_OEF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_OEF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SW							
					
	Variable/G gs_OEF_SW=0
	gs_OEF_SW := fSmearedOblate_SW(smear_coef_OEF_SW,smeared_OEF_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_OEF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOblate_SW","smear_coef_OEF_SW","OEF_SW")
End


Function Oblate_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_OEF_SW
	form_OEF_SW[0] = 1
	form_OEF_SW[1] = w[1]
	form_OEF_SW[2] = w[2]
	form_OEF_SW[3] = w[3]
	form_OEF_SW[4] = w[4]
	form_OEF_SW[5] = w[5]
	form_OEF_SW[6] = w[6]
	form_OEF_SW[7] = w[7]
	form_OEF_SW[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_OEF_SW
	struct_OEF_SW[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_SW[1] = w[0]
	struct_OEF_SW[2] = w[8]
	struct_OEF_SW[3] = w[9]
	
	//calculate each and combine
	Duplicate/O xw temp_OEF_SW_PQ,temp_OEF_SW_SQ		//make waves for the AAO
	OblateForm(form_OEF_SW,temp_OEF_SW_PQ,xw)
	SquareWellStruct(struct_OEF_SW,temp_OEF_SW_SQ,xw)
	yw = temp_OEF_SW_PQ * temp_OEF_SW_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SW,struct_OEF_SW
	
	return (0)
End

Proc PlotOblate_SC(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_OEF_SC,ywave_OEF_SC
	xwave_OEF_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SC = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,20,0,298,78,0.0001}
	make/o/t parameters_OEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit parameters_OEF_SC,coef_OEF_SC
	
	Variable/G root:g_OEF_SC
	g_OEF_SC := Oblate_SC(coef_OEF_SC,ywave_OEF_SC,xwave_OEF_SC)
	Display ywave_OEF_SC vs xwave_OEF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Oblate_SC","coef_OEF_SC","OEF_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOblate_SC(str)								
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
	Make/O/D smear_coef_OEF_SC = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,20,0,298,78,0.0001}
	make/o/t smear_parameters_OEF_SC = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1)"}
	Edit smear_parameters_OEF_SC,smear_coef_OEF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_OEF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SC							
					
	Variable/G gs_OEF_SC=0
	gs_OEF_SC := fSmearedOblate_SC(smear_coef_OEF_SC,smeared_OEF_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_OEF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOblate_SC","smear_coef_OEF_SC","OEF_SC")
End


Function Oblate_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_OEF_SC
	form_OEF_SC[0] = 1
	form_OEF_SC[1] = w[1]
	form_OEF_SC[2] = w[2]
	form_OEF_SC[3] = w[3]
	form_OEF_SC[4] = w[4]
	form_OEF_SC[5] = w[5]
	form_OEF_SC[6] = w[6]
	form_OEF_SC[7] = w[7]
	form_OEF_SC[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_OEF_SC
	struct_OEF_SC[0] = DiamEllip(Ras,Rbs)
	struct_OEF_SC[1] = w[8]
	struct_OEF_SC[2] = w[0]
	struct_OEF_SC[3] = w[10]
	struct_OEF_SC[4] = w[9]
	struct_OEF_SC[5] = w[11]
	
	//calculate each and combine
	Duplicate/O xw temp_OEF_SC_PQ,temp_OEF_SC_SQ		//make waves for the AAO
	OblateForm(form_OEF_SC,temp_OEF_SC_PQ,xw)
	HayterPenfoldMSA(struct_OEF_SC,temp_OEF_SC_SQ,xw)
	yw = temp_OEF_SC_PQ * temp_OEF_SC_SQ
	yw *= w[0]
	yw += w[12]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SC,struct_OEF_SC
	
	return (0)
End


Proc PlotOblate_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_OEF_SHS,ywave_OEF_SHS
	xwave_OEF_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_OEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t parameters_OEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit parameters_OEF_SHS,coef_OEF_SHS
	
	Variable/G root:g_OEF_SHS
	g_OEF_SHS := Oblate_SHS(coef_OEF_SHS,ywave_OEF_SHS,xwave_OEF_SHS)
	Display ywave_OEF_SHS vs xwave_OEF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Oblate_SHS","coef_OEF_SHS","OEF_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedOblate_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_OEF_SHS = {0.01,100,50,110,60,1e-6,2e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_OEF_SHS = {"volume fraction","major core radius (A)","minor core radius (A)","major shell radius (A)","minor shell radius (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_OEF_SHS,smear_coef_OEF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_OEF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_OEF_SHS							
					
	Variable/G gs_OEF_SHS=0
	gs_OEF_SHS := fSmearedOblate_SHS(smear_coef_OEF_SHS,smeared_OEF_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_OEF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedOblate_SHS","smear_coef_OEF_SHS","OEF_SHS")
End
	

Function Oblate_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,Ras,Rbs
	Ras = w[4]	//Ras is the rotation axis
	Rbs = w[3]
	
	//setup form factor coefficient wave
	Make/O/D/N=9 form_OEF_SHS
	form_OEF_SHS[0] = 1
	form_OEF_SHS[1] = w[1]
	form_OEF_SHS[2] = w[2]
	form_OEF_SHS[3] = w[3]
	form_OEF_SHS[4] = w[4]
	form_OEF_SHS[5] = w[5]
	form_OEF_SHS[6] = w[6]
	form_OEF_SHS[7] = w[7]
	form_OEF_SHS[8] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_OEF_SHS
	struct_OEF_SHS[0] = 0.5*DiamEllip(Ras,Rbs)
	struct_OEF_SHS[1] = w[0]
	struct_OEF_SHS[2] = w[8]
	struct_OEF_SHS[3] = w[9]
	
	//calculate each and combine
	Duplicate/O xw temp_OEF_SHS_PQ,temp_OEF_SHS_SQ		//make waves for the AAO
	OblateForm(form_OEF_SHS,temp_OEF_SHS_PQ,xw)
	StickyHS_Struct(struct_OEF_SHS,temp_OEF_SHS_SQ,xw)
	yw = temp_OEF_SHS_PQ * temp_OEF_SHS_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_OEF_SHS,struct_OEF_SHS
	
	return (0)
End


// this is all there is to the smeared calculation!
Function SmearedOblate_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Oblate_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Oblate_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Oblate_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedOblate_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Oblate_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOblate_HS(coefW,yW,xW)
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
	err = SmearedOblate_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOblate_SW(coefW,yW,xW)
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
	err = SmearedOblate_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOblate_SC(coefW,yW,xW)
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
	err = SmearedOblate_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedOblate_SHS(coefW,yW,xW)
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
	err = SmearedOblate_SHS(fs)
	
	return (0)
End
