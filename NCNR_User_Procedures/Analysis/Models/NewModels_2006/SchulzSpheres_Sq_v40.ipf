#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

//
// be sure to include all of the necessary files
//
#include "SchulzSpheres_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotSchulzSpheres_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_HS,ywave_sch_HS
	xwave_sch_HS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_HS = {0.01,60,0.2,1e-6,3e-6,0.001}
	make/O/T parameters_sch_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_sch_HS,coef_sch_HS
	
	Variable/G root:g_sch_HS
	g_sch_HS := SchulzSpheres_HS(coef_sch_HS,ywave_sch_HS,xwave_sch_HS)
	Display ywave_sch_HS vs xwave_sch_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SchulzSpheres_HS","coef_sch_HS","parameters_sch_HS","sch_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSchulzSpheres_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_HS = {0.01,60,0.2,1e-6,3e-6,0.001}					
	make/o/t smear_parameters_sch_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_HS,smear_coef_sch_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sch_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_HS							
					
	Variable/G gs_sch_HS=0
	gs_sch_HS := fSmearedSchulzSpheres_HS(smear_coef_sch_HS,smeared_sch_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sch_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSchulzSpheres_HS","smear_coef_sch_HS","smear_parameters_sch_HS","sch_HS")
End
	


Function SchulzSpheres_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_sch_HS
	form_sch_HS[0] = 1
	form_sch_HS[1] = w[1]
	form_sch_HS[2] = w[2]
	form_sch_HS[3] = w[3]
	form_sch_HS[4] = w[4]
	form_sch_HS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	
	Vpoly = 4*pi/3*(Ravg)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_sch_HS
	struct_sch_HS[0] = diam/2
	struct_sch_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw tmp_sch_HS_PQ,tmp_sch_HS_SQ
	SchulzSpheres(form_sch_HS,tmp_sch_HS_PQ,xw)
	HardSphereStruct(struct_sch_HS,tmp_sch_HS_SQ,xw)
	yw = tmp_sch_HS_PQ * tmp_sch_HS_SQ
	yw *= w[0]
	yw += w[5]
	
	//cleanup waves
//	Killwaves/Z form_sch_HS,struct_sch_HS
	
	return (0)
End

/////////////////////////////////////////
Proc PlotSchulzSpheres_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_SW,ywave_sch_SW
	xwave_sch_SW = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}
	make/O/T parameters_sch_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SW,coef_sch_SW

	Variable/G root:g_sch_SW
	g_sch_SW := SchulzSpheres_SW(coef_sch_SW,ywave_sch_SW,xwave_sch_SW)
	Display ywave_sch_SW vs xwave_sch_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SchulzSpheres_SW","coef_sch_SW","parameters_sch_SW","sch_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSchulzSpheres_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}					
	make/o/t smear_parameters_sch_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SW,smear_coef_sch_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sch_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SW							
					
	Variable/G gs_sch_SW=0
	gs_sch_SW := fSmearedSchulzSpheres_SW(smear_coef_sch_SW,smeared_sch_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sch_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSchulzSpheres_SW","smear_coef_sch_SW","smear_parameters_sch_SW","sch_SW")
End

	

Function SchulzSpheres_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_sch_SW
	form_sch_SW[0] = 1
	form_sch_SW[1] = w[1]
	form_sch_SW[2] = w[2]
	form_sch_SW[3] = w[3]
	form_sch_SW[4] = w[4]
	form_sch_SW[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	
	Vpoly = 4*pi/3*(Ravg)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_sch_SW
	struct_sch_SW[0] = diam/2
	struct_sch_SW[1] = w[0]
	struct_sch_SW[2] = w[5]
	struct_sch_SW[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw tmp_sch_SW_PQ,tmp_sch_SW_SQ
	SchulzSpheres(form_sch_SW,tmp_sch_SW_PQ,xw)
	SquareWellStruct(struct_sch_SW,tmp_sch_SW_SQ,xw)
	yw = tmp_sch_SW_PQ * tmp_sch_SW_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_sch_SW,struct_sch_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotSchulzSpheres_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave

	Make/O/D/N=(num) xwave_sch_SC,ywave_sch_SC
	xwave_sch_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}
	make/O/T parameters_sch_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SC,coef_sch_SC
	
	Variable/G root:g_sch_SC
	g_sch_SC := SchulzSpheres_SC(coef_sch_SC,ywave_sch_SC,xwave_sch_SC)
	Display ywave_sch_SC vs xwave_sch_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SchulzSpheres_SC","coef_sch_SC","parameters_sch_SC","sch_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSchulzSpheres_SC(str)								
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
	Make/O/D smear_coef_sch_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}					
	make/o/t smear_parameters_sch_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SC,smear_coef_sch_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sch_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SC							
					
	Variable/G gs_sch_SC=0
	gs_sch_SC := fSmearedSchulzSpheres_SC(smear_coef_sch_SC,smeared_sch_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sch_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSchulzSpheres_SC","smear_coef_sch_SC","smear_parameters_sch_SC","sch_SC")
End


Function SchulzSpheres_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_sch_SC
	form_sch_SC[0] = 1
	form_sch_SC[1] = w[1]
	form_sch_SC[2] = w[2]
	form_sch_SC[3] = w[3]
	form_sch_SC[4] = w[4]
	form_sch_SC[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	
	Vpoly = 4*pi/3*(Ravg)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_sch_SC
	struct_sch_SC[0] = diam
	struct_sch_SC[1] = w[5]
	struct_sch_SC[2] = w[0]
	struct_sch_SC[3] = w[7]
	struct_sch_SC[4] = w[6]
	struct_sch_SC[5] = w[8]
	
	//calculate each and combine
	Duplicate/O xw tmp_sch_SC_PQ,tmp_sch_SC_SQ
	SchulzSpheres(form_sch_SC,tmp_sch_SC_PQ,xw)
	HayterPenfoldMSA(struct_sch_SC,tmp_sch_SC_SQ,xw)
	yw = tmp_sch_SC_PQ *tmp_sch_SC_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_sch_SC,struct_sch_SC
	
	return (0)
End

/////////////////////////////////////////
Proc PlotSchulzSpheres_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_SHS,ywave_sch_SHS
	xwave_sch_SHS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}
	make/O/T parameters_sch_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SHS,coef_sch_SHS
	
	Variable/G root:g_sch_SHS
	g_sch_SHS := SchulzSpheres_SHS(coef_sch_SHS,ywave_sch_SHS,xwave_sch_SHS)
	Display ywave_sch_SHS vs xwave_sch_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SchulzSpheres_SHS","coef_sch_SHS","parameters_sch_SHS","sch_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSchulzSpheres_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}					
	make/o/t smear_parameters_sch_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SHS,smear_coef_sch_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_sch_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SHS							
					
	Variable/G gs_sch_SHS=0
	gs_sch_SHS := fSmearedSchulzSpheres_SHS(smear_coef_sch_SHS,smeared_sch_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_sch_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSchulzSpheres_SHS","smear_coef_sch_SHS","smear_parameters_sch_SHS","sch_SHS")
End


Function SchulzSpheres_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=6 form_sch_SHS
	form_sch_SHS[0] = 1
	form_sch_SHS[1] = w[1]
	form_sch_SHS[2] = w[2]
	form_sch_SHS[3] = w[3]
	form_sch_SHS[4] = w[4]
	form_sch_SHS[5] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	
	Vpoly = 4*pi/3*(Ravg)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_sch_SHS
	struct_sch_SHS[0] = diam/2
	struct_sch_SHS[1] = w[0]
	struct_sch_SHS[2] = w[5]
	struct_sch_SHS[3] = w[6]
	
	//calculate each and combine
	Duplicate/O xw tmp_sch_SHS_PQ,tmp_sch_SHS_SQ
	SchulzSpheres(form_sch_SHS,tmp_sch_SHS_PQ,xw)
	StickyHS_Struct(struct_sch_SHS,tmp_sch_SHS_SQ,xw)
	yw = tmp_sch_SHS_PQ * tmp_sch_SHS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_sch_SHS,struct_sch_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_HS(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(SchulzSpheres_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SW(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(SchulzSpheres_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SC(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(SchulzSpheres_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SHS(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(SchulzSpheres_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSchulzSpheres_HS(coefW,yW,xW)
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
	err = SmearedSchulzSpheres_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSchulzSpheres_SW(coefW,yW,xW)
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
	err = SmearedSchulzSpheres_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSchulzSpheres_SC(coefW,yW,xW)
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
	err = SmearedSchulzSpheres_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedSchulzSpheres_SHS(coefW,yW,xW)
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
	err = SmearedSchulzSpheres_SHS(fs)
	
	return (0)
End
