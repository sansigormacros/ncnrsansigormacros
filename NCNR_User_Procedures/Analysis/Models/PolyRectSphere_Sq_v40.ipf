#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// be sure to include all the necessary files...

#include "PolyRectSphere_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotPolyRectSphere_HS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_HS,ywave_RECT_HS
	xwave_RECT_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_HS = {0.1,60,0.1,1e-6,6.3e-6,0.0001}
	make/o/t parameters_RECT_HS = {"volume fraction","avg radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_HS,coef_RECT_HS
	
	Variable/G root:g_RECT_HS
	g_RECT_HS := PolyRectSphere_HS(coef_RECT_HS,ywave_RECT_HS,xwave_RECT_HS)
	Display/K=1 ywave_RECT_HS vs xwave_RECT_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRectSphere_HS","coef_RECT_HS","parameters_RECT_HS","RECT_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyRectSphere_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_HS = {0.1,60,0.1,1e-6,6.3e-6,0.0001}
	make/o/t smear_parameters_RECT_HS = {"volume fraction","avg radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","bkg (cm-1)"}
	Edit smear_parameters_RECT_HS,smear_coef_RECT_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_RECT_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_HS							
					
	Variable/G gs_RECT_HS=0
	gs_RECT_HS := fSmearedPolyRectSphere_HS(smear_coef_RECT_HS,smeared_RECT_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_RECT_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRectSphere_HS","smear_coef_RECT_HS","smear_parameters_RECT_HS","RECT_HS")
End
	

Function PolyRectSphere_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_RECT_HS
	form_RECT_HS[0] = 1
	form_RECT_HS[1] = w[1]
	form_RECT_HS[2] = w[2]
	form_RECT_HS[3] = w[3]
	form_RECT_HS[4] = w[4]
	form_RECT_HS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]		// <R^3> = Ravg^3*(1+3*pd^2)
	
	Vpoly = 4*pi/3*Ravg^3*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_RECT_HS
	struct_RECT_HS[0] = diam/2
	struct_RECT_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_RECT_HS_PQ,temp_RECT_HS_SQ		//make waves for the AAO
	PolyRectSpheres(form_RECT_HS,temp_RECT_HS_PQ,xw)
	HardSphereStruct(struct_RECT_HS,temp_RECT_HS_SQ,xw)
	yw = temp_RECT_HS_PQ * temp_RECT_HS_SQ
	yw *= w[0]
	yw += w[5]
	
	//cleanup waves
//	Killwaves/Z form_RECT_HS,struct_RECT_HS
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyRectSphere_SW(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_SW,ywave_RECT_SW
	xwave_RECT_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SW = {0.1,60,0.1,1e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t parameters_RECT_SW = {"volume fraction","avg radius(A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SW,coef_RECT_SW
	
	Variable/G root:g_RECT_SW
	g_RECT_SW := PolyRectSphere_SW(coef_RECT_SW,ywave_RECT_SW,xwave_RECT_SW)
	Display/K=1 ywave_RECT_SW vs xwave_RECT_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRectSphere_SW","coef_RECT_SW","parameters_RECT_SW","RECT_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyRectSphere_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_SW = {0.1,60,0.1,1e-6,6.3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_RECT_SW = {"volume fraction","avg radius(A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_RECT_SW,smear_coef_RECT_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_RECT_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SW							
					
	Variable/G gs_RECT_SW=0
	gs_RECT_SW := fSmearedPolyRectSphere_SW(smear_coef_RECT_SW,smeared_RECT_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_RECT_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRectSphere_SW","smear_coef_RECT_SW","smear_parameters_RECT_SW","RECT_SW")
End
	

Function PolyRectSphere_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_RECT_SW
	form_RECT_SW[0] = 1
	form_RECT_SW[1] = w[1]
	form_RECT_SW[2] = w[2]
	form_RECT_SW[3] = w[3]
	form_RECT_SW[4] = w[4]
	form_RECT_SW[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]		// <R^3> = Ravg^3*(1+3*pd^2)
	
	Vpoly = 4*pi/3*Ravg^3*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_RECT_SW
	struct_RECT_SW[0] = diam/2
	struct_RECT_SW[1] = w[0]
	struct_RECT_SW[2] = w[5]
	struct_RECT_SW[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw temp_RECT_SW_PQ,temp_RECT_SW_SQ		//make waves for the AAO
	PolyRectSpheres(form_RECT_SW,temp_RECT_SW_PQ,xw)
	SquareWellStruct(struct_RECT_SW,temp_RECT_SW_SQ,xw)
	yw = temp_RECT_SW_PQ * temp_RECT_SW_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SW,struct_RECT_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotPolyRectSphere_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_RECT_SC,ywave_RECT_SC
	xwave_RECT_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SC = {0.1,60,0.1,1e-6,6.3e-6,10,0,298,78,0.0001}
	make/o/t parameters_RECT_SC = {"volume fraction","avg radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SC,coef_RECT_SC
	
	Variable/G root:g_RECT_SC
	g_RECT_SC := PolyRectSphere_SC(coef_RECT_SC,ywave_RECT_SC,xwave_RECT_SC)
	Display/K=1 ywave_RECT_SC vs xwave_RECT_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRectSphere_SC","coef_RECT_SC","parameters_RECT_SC","RECT_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyRectSphere_SC(str)								
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
	Make/O/D smear_coef_RECT_SC = {0.1,60,0.1,1e-6,6.3e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_RECT_SC = {"volume fraction","avg radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_RECT_SC,smear_coef_RECT_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_RECT_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SC							
					
	Variable/G gs_RECT_SC=0
	gs_RECT_SC := fSmearedPolyRectSphere_SC(smear_coef_RECT_SC,smeared_RECT_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_RECT_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRectSphere_SC","smear_coef_RECT_SC","smear_parameters_RECT_SC","RECT_SC")
End


Function PolyRectSphere_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_RECT_SC
	form_RECT_SC[0] = 1
	form_RECT_SC[1] = w[1]
	form_RECT_SC[2] = w[2]
	form_RECT_SC[3] = w[3]
	form_RECT_SC[4] = w[4]
	form_RECT_SC[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]		// <R^3> = Ravg^3*(1+3*pd^2)
	
	Vpoly = 4*pi/3*Ravg^3*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_RECT_SC
	struct_RECT_SC[0] = diam
	struct_RECT_SC[1] = w[5]
	struct_RECT_SC[2] = w[0]
	struct_RECT_SC[3] = w[7]
	struct_RECT_SC[4] = w[6]
	struct_RECT_SC[5] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_RECT_SC_PQ,temp_RECT_SC_SQ		//make waves for the AAO
	PolyRectSpheres(form_RECT_SC,temp_RECT_SC_PQ,xw)
	HayterPenfoldMSA(struct_RECT_SC,temp_RECT_SC_SQ,xw)
	yw = temp_RECT_SC_PQ * temp_RECT_SC_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SC,struct_RECT_SC
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyRectSphere_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_SHS,ywave_RECT_SHS
	xwave_RECT_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SHS = {0.1,60,0.1,1e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t parameters_RECT_SHS = {"volume fraction","avg radius(A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SHS,coef_RECT_SHS
	
	Variable/G root:g_RECT_SHS
	g_RECT_SHS := PolyRectSphere_SHS(coef_RECT_SHS,ywave_RECT_SHS,xwave_RECT_SHS)
	Display/K=1 ywave_RECT_SHS vs xwave_RECT_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRectSphere_SHS","coef_RECT_SHS","parameters_RECT_SHS","RECT_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyRectSphere_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_SHS = {0.1,60,0.1,1e-6,6.3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_RECT_SHS = {"volume fraction","avg radius(A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_RECT_SHS,smear_coef_RECT_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_RECT_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SHS							
					
	Variable/G gs_RECT_SHS=0
	gs_RECT_SHS := fSmearedPolyRectSphere_SHS(smear_coef_RECT_SHS,smeared_RECT_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_RECT_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRectSphere_SHS","smear_coef_RECT_SHS","smear_parameters_RECT_SHS","RECT_SHS")
End
	

Function PolyRectSphere_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_RECT_SHS
	form_RECT_SHS[0] = 1
	form_RECT_SHS[1] = w[1]
	form_RECT_SHS[2] = w[2]
	form_RECT_SHS[3] = w[3]
	form_RECT_SHS[4] = w[4]
	form_RECT_SHS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]		// <R^3> = Ravg^3*(1+3*pd^2)
	
	Vpoly = 4*pi/3*Ravg^3*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_RECT_SHS
	struct_RECT_SHS[0] = diam/2
	struct_RECT_SHS[1] = w[0]
	struct_RECT_SHS[2] = w[5]
	struct_RECT_SHS[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw temp_RECT_SHS_PQ,temp_RECT_SHS_SQ		//make waves for the AAO
	PolyRectSpheres(form_RECT_SHS,temp_RECT_SHS_PQ,xw)
	StickyHS_Struct(struct_RECT_SHS,temp_RECT_SHS_SQ,xw)
	yw = temp_RECT_SHS_PQ * temp_RECT_SHS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SHS,struct_RECT_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyRectSphere_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyRectSphere_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyRectSphere_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyRectSphere_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRectSphere_HS(coefW,yW,xW)
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
	err = SmearedPolyRectSphere_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRectSphere_SW(coefW,yW,xW)
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
	err = SmearedPolyRectSphere_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRectSphere_SC(coefW,yW,xW)
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
	err = SmearedPolyRectSphere_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRectSphere_SHS(coefW,yW,xW)
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
	err = SmearedPolyRectSphere_SHS(fs)
	
	return (0)
End