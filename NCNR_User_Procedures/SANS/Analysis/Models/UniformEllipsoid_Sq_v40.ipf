#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// be sure to include all the necessary files...

#include "EffectiveDiameter_v40"
#include "UniformEllipsoid_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotEllipsoid_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_HS,ywave_EOR_HS
	xwave_EOR_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_HS = {0.01,20.,400,1e-6,6.3e-6,0.01}
	make/o/t parameters_EOR_HS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_HS,coef_EOR_HS
	
	Variable/G root:g_EOR_HS
	g_EOR_HS := Ellipsoid_HS(coef_EOR_HS,ywave_EOR_HS,xwave_EOR_HS)
	Display ywave_EOR_HS vs xwave_EOR_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Ellipsoid_HS","coef_EOR_HS","EOR_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedEllipsoid_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_HS = {0.01,20.,400,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_EOR_HS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_HS,smear_coef_EOR_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_EOR_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_HS							
					
	Variable/G gs_EOR_HS=0
	gs_EOR_HS := fSmearedEllipsoid_HS(smear_coef_EOR_HS,smeared_EOR_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_EOR_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedEllipsoid_HS","smear_coef_EOR_HS","EOR_HS")
End
	

//AAO function
Function Ellipsoid_HS(w,yW,xW) : FitFunc
	Wave w,yW,xW
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_EOR_HS
	form_EOR_HS[0] = 1
	form_EOR_HS[1] = w[1]
	form_EOR_HS[2] = w[2]
	form_EOR_HS[3] = w[3]
	form_EOR_HS[4] = w[4]
	form_EOR_HS[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_EOR_HS
	struct_EOR_HS[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw, temp_EOR_HS_PQ,temp_EOR_HS_SQ
	EllipsoidForm(form_EOR_HS,temp_EOR_HS_PQ,xW)
	HardSphereStruct(struct_EOR_HS,temp_EOR_HS_SQ,xW)
	yw = temp_EOR_HS_PQ * temp_EOR_HS_SQ
	yw *= w[0]
	yw += w[5]
	
	//cleanup waves
//	Killwaves/Z form_EOR_HS,struct_EOR_HS
	
	return (0)
End

Proc PlotEllipsoid_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_SW,ywave_EOR_SW
	xwave_EOR_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SW = {0.01,20.,400,1e-6,6.3e-6,1.0,1.2,0.01}
	make/o/t parameters_EOR_SW = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SW,coef_EOR_SW
	
	Variable/G root:g_EOR_SW
	g_EOR_SW := Ellipsoid_SW(coef_EOR_SW,ywave_EOR_SW,xwave_EOR_SW)
	Display ywave_EOR_SW vs xwave_EOR_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Ellipsoid_SW","coef_EOR_SW","EOR_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedEllipsoid_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_SW = {0.01,20.,400,1e-6,6.3e-6,1.0,1.2,0.01}
	make/o/t smear_parameters_EOR_SW = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SW,smear_coef_EOR_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_EOR_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SW							
					
	Variable/G gs_EOR_SW=0
	gs_EOR_SW := fSmearedEllipsoid_SW(smear_coef_EOR_SW,smeared_EOR_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_EOR_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedEllipsoid_SW","smear_coef_EOR_SW","EOR_SW")
End
	

Function Ellipsoid_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_EOR_SW
	form_EOR_SW[0] = 1
	form_EOR_SW[1] = w[1]
	form_EOR_SW[2] = w[2]
	form_EOR_SW[3] = w[3]
	form_EOR_SW[4] = w[4]
	form_EOR_SW[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_EOR_SW
	struct_EOR_SW[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_SW[1] = w[0]
	struct_EOR_SW[2] = w[5]
	struct_EOR_SW[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw, temp_EOR_SW_PQ,temp_EOR_SW_SQ
	EllipsoidForm(form_EOR_SW,temp_EOR_SW_PQ,xw)
	SquareWellStruct(struct_EOR_SW,temp_EOR_SW_SQ,xw)
	yw = temp_EOR_SW_PQ * temp_EOR_SW_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SW,struct_EOR_SW
	
	return (0)
End

Proc PlotEllipsoid_SC(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_EOR_SC,ywave_EOR_SC
	xwave_EOR_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SC = {0.01,20.,400,1e-6,6.3e-6,20,0,298,78,0.01}
	make/o/t parameters_EOR_SC = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SC,coef_EOR_SC

	Variable/G root:g_EOR_SC
	g_EOR_SC := Ellipsoid_SC(coef_EOR_SC,ywave_EOR_SC,xwave_EOR_SC)
	Display ywave_EOR_SC vs xwave_EOR_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Ellipsoid_SC","coef_EOR_SC","EOR_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedEllipsoid_SC(str)								
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
	Make/O/D smear_coef_EOR_SC = {0.01,20.,400,1e-6,6.3e-6,20,0,298,78,0.01}
	make/o/t smear_parameters_EOR_SC = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SC,smear_coef_EOR_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_EOR_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SC							
					
	Variable/G gs_EOR_SC=0
	gs_EOR_SC := fSmearedEllipsoid_SC(smear_coef_EOR_SC,smeared_EOR_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_EOR_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedEllipsoid_SC","smear_coef_EOR_SC","EOR_SC")
End


Function Ellipsoid_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_EOR_SC
	form_EOR_SC[0] = 1
	form_EOR_SC[1] = w[1]
	form_EOR_SC[2] = w[2]
	form_EOR_SC[3] = w[3]
	form_EOR_SC[4] = w[4]
	form_EOR_SC[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_EOR_SC
	struct_EOR_SC[0] = DiamEllip(aa,bb)
	struct_EOR_SC[1] = w[5]
	struct_EOR_SC[2] = w[0]
	struct_EOR_SC[3] = w[7]
	struct_EOR_SC[4] = w[6]
	struct_EOR_SC[5] = w[8]
	
	//calculate each and combine
	Duplicate/O xw, temp_EOR_SC_PQ,temp_EOR_SC_SQ
	EllipsoidForm(form_EOR_SC,temp_EOR_SC_PQ,xw)
	HayterPenfoldMSA(struct_EOR_SC,temp_EOR_SC_SQ,xw)
	yw = temp_EOR_SC_PQ * temp_EOR_SC_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SC,struct_EOR_SC
	
	return (0)
End

Proc PlotEllipsoid_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_EOR_SHS,ywave_EOR_SHS
	xwave_EOR_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_EOR_SHS = {0.01,20.,400,1e-6,6.3e-6,0.05,0.2,0.01}
	make/o/t parameters_EOR_SHS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit parameters_EOR_SHS,coef_EOR_SHS
	
	Variable/G root:g_EOR_SHS
	g_EOR_SHS := Ellipsoid_SHS(coef_EOR_SHS,ywave_EOR_SHS,xwave_EOR_SHS)
	Display ywave_EOR_SHS vs xwave_EOR_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Ellipsoid_SHS","coef_EOR_SHS","EOR_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedEllipsoid_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_EOR_SHS = {0.01,20.,400,1e-6,6.3e-6,0.05,0.2,0.01}
	make/o/t smear_parameters_EOR_SHS = {"volume fraction","R(a) rotation axis (A)","R(b) (A)","SLD ellipsoid (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit smear_parameters_EOR_SHS,smear_coef_EOR_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_EOR_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_EOR_SHS							
					
	Variable/G gs_EOR_SHS=0
	gs_EOR_SHS := fSmearedEllipsoid_SHS(smear_coef_EOR_SHS,smeared_EOR_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_EOR_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedEllipsoid_SHS","smear_coef_EOR_SHS","EOR_SHS")
End
	

Function Ellipsoid_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,aa,bb
	aa=w[1]
	bb=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_EOR_SHS
	form_EOR_SHS[0] = 1
	form_EOR_SHS[1] = w[1]
	form_EOR_SHS[2] = w[2]
	form_EOR_SHS[3] = w[3]
	form_EOR_SHS[4] = w[4]
	form_EOR_SHS[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_EOR_SHS
	struct_EOR_SHS[0] = 0.5*DiamEllip(aa,bb)
	struct_EOR_SHS[1] = w[0]
	struct_EOR_SHS[2] = w[5]
	struct_EOR_SHS[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw, temp_EOR_SHS_PQ,temp_EOR_SHS_SQ
	EllipsoidForm(form_EOR_SHS,temp_EOR_SHS_PQ,xw)
	StickyHS_Struct(struct_EOR_SHS,temp_EOR_SHS_SQ,xw)
	yw = temp_EOR_SHS_PQ *temp_EOR_SHS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_EOR_SHS,struct_EOR_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedEllipsoid_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Ellipsoid_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Ellipsoid_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Ellipsoid_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedEllipsoid_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Ellipsoid_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedEllipsoid_HS(coefW,yW,xW)
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
	err = SmearedEllipsoid_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedEllipsoid_SW(coefW,yW,xW)
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
	err = SmearedEllipsoid_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedEllipsoid_SC(coefW,yW,xW)
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
	err = SmearedEllipsoid_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedEllipsoid_SHS(coefW,yW,xW)
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
	err = SmearedEllipsoid_SHS(fs)
	
	return (0)
End