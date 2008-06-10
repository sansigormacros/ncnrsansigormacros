#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// be sure to include all the necessary files...
#include "EffectiveDiameter_v40"
#include "Cylinder_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotCylinder_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_HS,ywave_CYL_HS
	xwave_CYL_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_HS = {0.01,20.,400,1e-6,6.3e-6,0.01}
	make/o/t parameters_CYL_HS = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_HS,coef_CYL_HS
	
	Variable/G root:g_CYL_HS
	g_CYL_HS := Cylinder_HS(coef_CYL_HS,ywave_CYL_HS,xwave_CYL_HS)
	Display ywave_CYL_HS vs xwave_CYL_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cylinder_HS","coef_CYL_HS","CYL_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinder_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_HS = {0.01,20.,400,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_CYL_HS = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_HS,smear_coef_CYL_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CYL_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_HS							
					
	Variable/G gs_CYL_HS=0
	gs_CYL_HS := fSmearedCylinder_HS(smear_coef_CYL_HS,smeared_CYL_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CYL_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinder_HS","smear_coef_CYL_HS","CYL_HS")
End
		

Function Cylinder_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_CYL_HS
	form_CYL_HS[0] = 1
	form_CYL_HS[1] = w[1]
	form_CYL_HS[2] = w[2]
	form_CYL_HS[3] = w[3]
	form_CYL_HS[4] = w[4]	
	form_CYL_HS[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_CYL_HS
	struct_CYL_HS[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_CYL_HS_PQ,temp_CYL_HS_SQ		//make waves for the AAO
	CylinderForm(form_CYL_HS,temp_CYL_HS_PQ,xw)
	HardSphereStruct(struct_CYL_HS,temp_CYL_HS_SQ,xw)
	yw = temp_CYL_HS_PQ * temp_CYL_HS_SQ
	yw *= w[0]
	yw += w[5]
	
	//cleanup waves (don't do this - it takes a lot of time...)
//	Killwaves/Z form_CYL_HS,struct_CYL_HS
	
	return (0)
End

Proc PlotCylinder_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_SW,ywave_CYL_SW
	xwave_CYL_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SW = {0.01,20.,400,1e-6,6.3e-6,1.0,1.2,0.01}
	make/o/t parameters_CYL_SW = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SW,coef_CYL_SW
	
	Variable/G root:g_CYL_SW
	g_CYL_SW := Cylinder_SW(coef_CYL_SW,ywave_CYL_SW,xwave_CYL_SW)
	Display ywave_CYL_SW vs xwave_CYL_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cylinder_SW","coef_CYL_SW","CYL_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinder_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_SW = {0.01,20.,400,1e-6,6.3e-6,1.0,1.2,0.01}
	make/o/t smear_parameters_CYL_SW = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SW,smear_coef_CYL_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CYL_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SW							
					
	Variable/G gs_CYL_SW=0
	gs_CYL_SW := fSmearedCylinder_SW(smear_coef_CYL_SW,smeared_CYL_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CYL_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinder_SW","smear_coef_CYL_SW","CYL_SW")
End
	

Function Cylinder_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_CYL_SW
	form_CYL_SW[0] = 1
	form_CYL_SW[1] = w[1]
	form_CYL_SW[2] = w[2]
	form_CYL_SW[3] = w[3]
	form_CYL_SW[4] = w[4]
	form_CYL_SW[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CYL_SW
	struct_CYL_SW[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_SW[1] = w[0]
	struct_CYL_SW[2] = w[5]
	struct_CYL_SW[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw temp_CYL_SW_PQ,temp_CYL_SW_SQ		//make waves for the AAO
	CylinderForm(form_CYL_SW,temp_CYL_SW_PQ,xw)
	SquareWellStruct(struct_CYL_SW,temp_CYL_SW_SQ,xw)
	yw = temp_CYL_SW_PQ * temp_CYL_SW_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SW,struct_CYL_SW
	
	return (0)
End

Proc PlotCylinder_SC(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_CYL_SC,ywave_CYL_SC
	xwave_CYL_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SC = {0.01,20.,400,1e-6,6.3e-6,20,0,298,78,0.01}
	make/o/t parameters_CYL_SC = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SC,coef_CYL_SC
	
	Variable/G root:g_CYL_SC
	g_CYL_SC := Cylinder_SC(coef_CYL_SC,ywave_CYL_SC,xwave_CYL_SC)
	Display ywave_CYL_SC vs xwave_CYL_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cylinder_SC","coef_CYL_SC","CYL_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinder_SC(str)								
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
	Make/O/D smear_coef_CYL_SC = {0.01,20.,400,1e-6,6.3e-6,20,0,298,78,0.01}
	make/o/t smear_parameters_CYL_SC = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SC,smear_coef_CYL_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CYL_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SC							
					
	Variable/G gs_CYL_SC=0
	gs_CYL_SC := fSmearedCylinder_SC(smear_coef_CYL_SC,smeared_CYL_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CYL_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinder_SC","smear_coef_CYL_SC","CYL_SC")
End


Function Cylinder_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_CYL_SC
	form_CYL_SC[0] = 1
	form_CYL_SC[1] = w[1]
	form_CYL_SC[2] = w[2]
	form_CYL_SC[3] = w[3]
	form_CYL_SC[4] = w[4]
	form_CYL_SC[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_CYL_SC
	struct_CYL_SC[0] = DiamCyl(len,rad)
	struct_CYL_SC[1] = w[5]
	struct_CYL_SC[2] = w[0]
	struct_CYL_SC[3] = w[7]
	struct_CYL_SC[4] = w[6]
	struct_CYL_SC[5] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_CYL_SC_PQ,temp_CYL_SC_SQ		//make waves for the AAO
	CylinderForm(form_CYL_SC,temp_CYL_SC_PQ,xw)
	HayterPenfoldMSA(struct_CYL_SC,temp_CYL_SC_SQ,xw)
	yw = temp_CYL_SC_PQ * temp_CYL_SC_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SC,struct_CYL_SC
	
	return (0)
End


Proc PlotCylinder_SHS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_CYL_SHS,ywave_CYL_SHS
	xwave_CYL_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_CYL_SHS = {0.01,20.0,400,1e-6,6.3e-6,0.05,0.2,0.01}
	make/o/t parameters_CYL_SHS = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit parameters_CYL_SHS,coef_CYL_SHS
	
	Variable/G root:g_CYL_SHS
	g_CYL_SHS := Cylinder_SHS(coef_CYL_SHS,ywave_CYL_SHS,xwave_CYL_SHS)
	Display ywave_CYL_SHS vs xwave_CYL_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Cylinder_SHS","coef_CYL_SHS","CYL_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinder_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_CYL_SHS = {0.01,20.0,400,1e-6,6.3e-6,0.05,0.2,0.01}
	make/o/t smear_parameters_CYL_SHS = {"volume fraction","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","incoh. bkg (cm^-1)"}
	Edit smear_parameters_CYL_SHS,smear_coef_CYL_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_CYL_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_CYL_SHS							
					
	Variable/G gs_CYL_SHS=0
	gs_CYL_SHS := fSmearedCylinder_SHS(smear_coef_CYL_SHS,smeared_CYL_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_CYL_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinder_SHS","smear_coef_CYL_SHS","CYL_SHS")
End
	

Function Cylinder_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten,rad,len
	rad=w[1]
	len=w[2]
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_CYL_SHS
	form_CYL_SHS[0] = 1
	form_CYL_SHS[1] = w[1]
	form_CYL_SHS[2] = w[2]
	form_CYL_SHS[3] = w[3]
	form_CYL_SHS[4] = w[4]
	form_CYL_SHS[5] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_CYL_SHS
	struct_CYL_SHS[0] = 0.5*DiamCyl(len,rad)
	struct_CYL_SHS[1] = w[0]
	struct_CYL_SHS[2] = w[5]
	struct_CYL_SHS[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw temp_CYL_SHS_PQ,temp_CYL_SHS_SQ		//make waves for the AAO
	CylinderForm(form_CYL_SHS,temp_CYL_SHS_PQ,xw)
	StickyHS_Struct(struct_CYL_SHS,temp_CYL_SHS_SQ,xw)
	yw = temp_CYL_SHS_PQ * temp_CYL_SHS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_CYL_SHS,struct_CYL_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedCylinder_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Cylinder_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Cylinder_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Cylinder_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedCylinder_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Cylinder_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCylinder_HS(coefW,yW,xW)
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
	err = SmearedCylinder_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCylinder_SW(coefW,yW,xW)
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
	err = SmearedCylinder_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCylinder_SC(coefW,yW,xW)
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
	err = SmearedCylinder_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedCylinder_SHS(coefW,yW,xW)
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
	err = SmearedCylinder_SHS(fs)
	
	return (0)
End
