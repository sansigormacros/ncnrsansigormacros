#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// be sure to include all the necessary files...

#include "Sphere_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotSphere_HS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	//make the normal model waves
	Make/O/D/n=(num) xwave_S_HS,ywave_S_HS					
	xwave_S_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_HS = {0.1,60,1e-6,6.3e-6,0.01}						
	make/o/t parameters_S_HS = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_HS,coef_S_HS
	Variable/G root:g_S_HS						
	g_S_HS := Sphere_HS(coef_S_HS,ywave_S_HS,xwave_S_HS)			
//	ywave_S_HS := Sphere_HS(coef_S_HS,xwave_S_HS)			
	Display/K=1 ywave_S_HS vs xwave_S_HS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Sphere_HS","coef_S_HS","parameters_S_HS","S_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_HS = {0.1,60,1e-6,6.3e-6,0.01}						
	make/o/t smear_parameters_S_HS = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}		
	Edit smear_parameters_S_HS,smear_coef_S_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_S_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_HS							
					
	Variable/G gs_S_HS=0
	gs_S_HS := fSmearedSphere_HS(smear_coef_S_HS,smeared_S_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_S_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere_HS","smear_coef_S_HS","smear_parameters_S_HS","S_HS")
End


//AAO function
Function Sphere_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
		
	//setup form factor coefficient wave
	Make/O/D/N=5 form_S_HS
	form_S_HS[0] = 1
	form_S_HS[1] = w[1]
	form_S_HS[2] = w[2]
	form_S_HS[3] = w[3]
	form_S_HS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_S_HS
	struct_S_HS[0] = w[1]
	struct_S_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_S_HS_PQ,temp_S_HS_SQ		//make waves for the AAO
	SphereForm(form_S_HS,temp_S_HS_PQ,xw)
	HardSphereStruct(struct_S_HS,temp_S_HS_SQ,xw)
	yw = temp_S_HS_PQ * temp_S_HS_SQ
	yw *= w[0]
	yw += w[4]
	
	//cleanup waves
	//Killwaves/Z form_S_HS,struct_S_HS
	
	return (0)
End

/////////////////////////////////
Proc PlotSphere_SW(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	///
	Make/O/D/N=4 form_S_SW
	Make/O/D/N=4 struct_S_SW
	///
	Make/O/D/n=(num) xwave_S_SW,ywave_S_SW					
	xwave_S_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_SW = {0.1,60,1e-6,6.3e-6,1.0,1.2,0.01}						
	make/o/t parameters_S_SW = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SW,coef_S_SW	
	Variable/G root:g_S_SW							
	g_S_SW := Sphere_SW(coef_S_SW,ywave_S_SW,xwave_S_SW)			
//	ywave_S_SW := Sphere_SW(coef_S_SW,xwave_S_SW)			
	Display/K=1 ywave_S_SW vs xwave_S_SW							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	AddModelToStrings("Sphere_SW","coef_S_SW","parameters_S_SW","S_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_SW = {0.1,60,1e-6,6.3e-6,1.0,1.2,0.01}						
	make/o/t smear_parameters_S_SW = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkgd (cm-1)"}		
	Edit smear_parameters_S_SW,smear_coef_S_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_S_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SW							
					
	Variable/G gs_S_SW=0
	gs_S_SW := fSmearedSphere_SW(smear_coef_S_SW,smeared_S_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_S_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere_SW","smear_coef_S_SW","smear_parameters_S_SW","S_SW")
End
	

//AAO function
Function Sphere_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
		
	//setup form factor coefficient wave
	Make/O/D/N=5 form_S_SW
	form_S_SW[0] = 1
	form_S_SW[1] = w[1]
	form_S_SW[2] = w[2]
	form_S_SW[3] = w[3]
	form_S_SW[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_S_SW
	struct_S_SW[0] = w[1]
	struct_S_SW[1] = w[0]
	struct_S_SW[2] = w[4]
	struct_S_SW[3] = w[5]
	
	//calculate each and combine
	Duplicate/O xw temp_S_SW_PQ,temp_S_SW_SQ
	SphereForm(form_S_SW,temp_S_SW_PQ,xw)
	SquareWellStruct(struct_S_SW,temp_S_SW_SQ,xw)
	yw = temp_S_SW_PQ * temp_S_SW_SQ
	yw *= w[0]
	yw += w[6]
	
	//cleanup waves
	//Killwaves/Z form_S_SW,struct_S_SW
	
	return (0)
End

/////////////////////////////////
Proc PlotSphere_SC(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	///
	Make/O/D/n=(num) xwave_S_SC,ywave_S_SC					
	xwave_S_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))				
	Make/O/D coef_S_SC = {0.2,50,1e-6,6.3e-6,20,0,298,78,0.0001}						
	make/o/t parameters_S_SC = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SC,coef_S_SC
	Variable/G root:g_S_SC							
	g_S_SC := Sphere_SC(coef_S_SC,ywave_S_SC,xwave_S_SC)			
//	ywave_S_SC := Sphere_SC(coef_S_SC,xwave_S_SC)			
	Display/K=1 ywave_S_SC vs xwave_S_SC							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Sphere_SC","coef_S_SC","parameters_S_SC","S_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere_SC(str)								
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
	Make/O/D smear_coef_S_SC = {0.2,50,1e-6,6.3e-6,20,0,298,78,0.0001}						
	make/o/t smear_parameters_S_SC = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkgd (cm-1)"}		
	Edit smear_parameters_S_SC,smear_coef_S_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_S_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SC							
					
	Variable/G gs_S_SC=0
	gs_S_SC := fSmearedSphere_SC(smear_coef_S_SC,smeared_S_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_S_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere_SC","smear_coef_S_SC","smear_parameters_S_SC","S_SC")
End
	

//AAO function
Function Sphere_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw

	//setup form factor coefficient wave
	Make/O/D/N=5 form_S_SC
	form_S_SC[0] = 1
	form_S_SC[1] = w[1]
	form_S_SC[2] = w[2]
	form_S_SC[3] = w[3]
	form_S_SC[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_S_SC
	struct_S_SC[0] = 2*w[1]		//diameter
	struct_S_SC[1] = w[4]
	struct_S_SC[2] = w[0]
	struct_S_SC[3] = w[6]
	struct_S_SC[4] = w[5]
	struct_S_SC[5] = w[7]
	
	//calculate each and combine
	Duplicate/O xw temp_S_SC_PQ,temp_S_SC_SQ
	SphereForm(form_S_SC,temp_S_SC_PQ,xw)
	HayterPenfoldMSA(struct_S_SC,temp_S_SC_SQ,xw)
	yw = temp_S_SC_PQ * temp_S_SC_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
	//Killwaves/Z form_S_SC,struct_S_SC
	return (0)
End

/////////////////////////////////
Proc PlotSphere_SHS(num,qmin,qmax)						
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	///
	Make/O/D/N=4 form_S_SHS
	Make/O/D/N=4 struct_S_SHS
	///
	Make/O/D/n=(num) xwave_S_SHS,ywave_S_SHS					
	xwave_S_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_S_SHS = {0.1,60,1e-6,6.3e-6,0.05,0.2,0.01}						
	make/o/t parameters_S_SHS = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit/K=1 parameters_S_SHS,coef_S_SHS
	Variable/G root:g_S_SHS						
	g_S_SHS := Sphere_SHS(coef_S_SHS,ywave_S_SHS,xwave_S_SHS)			
//	ywave_S_SHS := Sphere_SHS(coef_S_SHS,xwave_S_SHS)			
	Display/K=1 ywave_S_SHS vs xwave_S_SHS							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Sphere_SHS","coef_S_SHS","parameters_S_SHS","S_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_S_SHS = {0.1,60,1e-6,6.3e-6,0.05,0.2,0.01}						
	make/o/t smear_parameters_S_SHS = {"volume fraction","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkgd (cm-1)"}		
	Edit smear_parameters_S_SHS,smear_coef_S_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_S_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_S_SHS							
					
	Variable/G gs_S_SHS=0
	gs_S_SHS := fSmearedSphere_SHS(smear_coef_S_SHS,smeared_S_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_S_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere_SHS","smear_coef_S_SHS","smear_parameters_S_SHS","S_SHS")
End


//AAO function
Function Sphere_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_S_SHS
	form_S_SHS[0] = 1
	form_S_SHS[1] = w[1]
	form_S_SHS[2] = w[2]
	form_S_SHS[3] = w[3]
	form_S_SHS[4] = 0
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_S_SHS
	struct_S_SHS[0] = w[1]
	struct_S_SHS[1] = w[0]
	struct_S_SHS[2] = w[4]
	struct_S_SHS[3] = w[5]
	
	//calculate each and combine
	Duplicate/O xw temp_S_SHS_PQ,temp_S_SHS_SQ
	SphereForm(form_S_SHS,temp_S_SHS_PQ,xw)
	StickyHS_Struct(struct_S_SHS,temp_S_SHS_SQ,xw)
	yw = temp_S_SHS_PQ * temp_S_SHS_SQ
	yw *= w[0]
	yw += w[6]
	
	//cleanup waves
	//Killwaves/Z form_S_SHS,struct_S_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedSphere_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Sphere_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
 
// this is all there is to the smeared calculation!
Function SmearedSphere_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Sphere_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedSphere_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Sphere_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedSphere_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(Sphere_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSphere_HS(coefW,yW,xW)
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
	err = SmearedSphere_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSphere_SW(coefW,yW,xW)
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
	err = SmearedSphere_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSphere_SC(coefW,yW,xW)
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
	err = SmearedSphere_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSphere_SHS(coefW,yW,xW)
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
	err = SmearedSphere_SHS(fs)
	
	return (0)
End