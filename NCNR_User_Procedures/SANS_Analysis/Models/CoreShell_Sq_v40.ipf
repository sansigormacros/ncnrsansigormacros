#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

//// include everything that is necessary
//
#include "CoreShell_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

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
	
	Variable/G root:g_CSS_HS
	g_CSS_HS := CoreShell_HS(coef_CSS_HS,ywave_CSS_HS,xwave_CSS_HS)
	Display/K=1 ywave_CSS_HS vs xwave_CSS_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CoreShell_HS","coef_CSS_HS","CSS_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCoreShell_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_HS = {0.1,60,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t smear_parameters_CSS_HS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_CSS_HS,smear_coef_CSS_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CSS_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_HS							
					
	Variable/G gs_CSS_HS=0
	gs_CSS_HS := fSmearedCoreShell_HS(smear_coef_CSS_HS,smeared_CSS_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CSS_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCoreShell_HS","smear_coef_CSS_HS","CSS_HS")
End
	

Function CoreShell_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
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
	Duplicate/O xw temp_CSS_HS_PQ,temp_CSS_HS_SQ		//make waves for the AAO
	CoreShellSphere(form_CSS_HS,temp_CSS_HS_PQ,xw)
	HardSphereStruct(struct_CSS_HS,temp_CSS_HS_SQ,xw)
	yw = temp_CSS_HS_PQ * temp_CSS_HS_SQ
	yw *= w[0]
	yw += w[6]
	
	//cleanup waves
//	Killwaves/Z form_CSS_HS,struct_CSS_HS
	
	return (0)
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
	
	Variable/G root:g_CSS_SW
	g_CSS_SW := CoreShell_SW(coef_CSS_SW,ywave_CSS_SW,xwave_CSS_SW)
	Display/K=1 ywave_CSS_SW vs xwave_CSS_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CoreShell_SW","coef_CSS_SW","CSS_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCoreShell_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_SW = {0.1,60,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_CSS_SW = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_CSS_SW,smear_coef_CSS_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CSS_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SW							
					
	Variable/G gs_CSS_SW=0
	gs_CSS_SW := fSmearedCoreShell_SW(smear_coef_CSS_SW,smeared_CSS_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CSS_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCoreShell_SW","smear_coef_CSS_SW","CSS_SW")
End
	

Function CoreShell_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
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
	Duplicate/O xw temp_CSS_SW_PQ,temp_CSS_SW_SQ		//make waves for the AAO
	CoreShellSphere(form_CSS_SW,temp_CSS_SW_PQ,xw)
	SquareWellStruct(struct_CSS_SW,temp_CSS_SW_SQ,xw)
	yw = temp_CSS_SW_PQ * temp_CSS_SW_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SW,struct_CSS_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotCoreShell_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_CSS_SC,ywave_CSS_SC
	xwave_CSS_SC = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CSS_SC = {0.1,60,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t parameters_CSS_SC = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_CSS_SC,coef_CSS_SC
	
	Variable/G root:g_CSS_SC
	g_CSS_SC := CoreShell_SC(coef_CSS_SC,ywave_CSS_SC,xwave_CSS_SC)
	Display/K=1 ywave_CSS_SC vs xwave_CSS_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CoreShell_SC","coef_CSS_SC","CSS_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCoreShell_SC(str)								
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
	Make/O/D smear_coef_CSS_SC = {0.1,60,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_CSS_SC = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_CSS_SC,smear_coef_CSS_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CSS_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SC							
					
	Variable/G gs_CSS_SC=0
	gs_CSS_SC := fSmearedCoreShell_SC(smear_coef_CSS_SC,smeared_CSS_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CSS_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCoreShell_SC","smear_coef_CSS_SC","CSS_SC")
End
	

Function CoreShell_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
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
	Duplicate/O xw temp_CSS_SC_PQ,temp_CSS_SC_SQ		//make waves for the AAO
	CoreShellSphere(form_CSS_SC,temp_CSS_SC_PQ,xw)
	HayterPenfoldMSA(struct_CSS_SC,temp_CSS_SC_SQ,xw)
	yw = temp_CSS_SC_PQ * temp_CSS_SC_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SC,struct_CSS_SC
	
	return (0)
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
	
	Variable/G root:g_CSS_SHS
	g_CSS_SHS := CoreShell_SHS(coef_CSS_SHS,ywave_CSS_SHS,xwave_CSS_SHS)
	Display/K=1 ywave_CSS_SHS vs xwave_CSS_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CoreShell_SHS","coef_CSS_SHS","CSS_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCoreShell_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CSS_SHS = {0.1,60,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_CSS_SHS = {"volume fraction","core rad (A)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_CSS_SHS,smear_coef_CSS_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CSS_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CSS_SHS							
					
	Variable/G gs_CSS_SHS=0
	gs_CSS_SHS := fSmearedCoreShell_SHS(smear_coef_CSS_SHS,smeared_CSS_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CSS_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCoreShell_SHS","smear_coef_CSS_SHS","CSS_SHS")
End
	

Function CoreShell_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
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
	Duplicate/O xw temp_CSS_SHS_PQ,temp_CSS_SHS_SQ		//make waves for the AAO
	CoreShellSphere(form_CSS_SHS,temp_CSS_SHS_PQ,xw)
	StickyHS_Struct(struct_CSS_SHS,temp_CSS_SHS_SQ,xw)
	yw = temp_CSS_SHS_PQ * temp_CSS_SHS_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_CSS_SHS,struct_CSS_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedCoreShell_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(CoreShell_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(CoreShell_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(CoreShell_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCoreShell_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(CoreShell_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCoreShell_HS(coefW,yW,xW)
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
	err = SmearedCoreShell_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCoreShell_SW(coefW,yW,xW)
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
	err = SmearedCoreShell_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCoreShell_SC(coefW,yW,xW)
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
	err = SmearedCoreShell_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCoreShell_SHS(coefW,yW,xW)
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
	err = SmearedCoreShell_SHS(fs)
	
	return (0)
End