#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1


// plots the form factor of spheres with a Gaussian radius distribution
// and a fuzzy surface
//
// M. Stieger, J. S. Pedersen, P. Lindner, W. Richtering, Langmuir 20 (2004) 7283-7292.
//
// potentially a lorentzian could be added to the low Q, if absolutely necessary
//
// SRK JUL 2009
//
// Use different volume fraction and radius for hard sphere interaction as Stieger et al.
//
//
// AJJ Feb 2010


//
// be sure to include all of the necessary files
//
#include "FuzzySpheres_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotFuzzySphere_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_fuzz_HS,ywave_fuzz_HS
	xwave_fuzz_HS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_fuzz_HS = {0.01,60,0.2,10,1e-6,3e-6,0.001}
	make/O/T parameters_fuzz_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_fuzz_HS,coef_fuzz_HS
	
	Variable/G root:g_fuzz_HS
	g_fuzz_HS := FuzzySphere_HS(coef_fuzz_HS,ywave_fuzz_HS,xwave_fuzz_HS)
	Display ywave_fuzz_HS vs xwave_fuzz_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FuzzySphere_HS","coef_fuzz_HS","parameters_fuzz_HS","fuzz_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFuzzySphere_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fuzz_HS = {0.01,60,0.2,10,1e-6,3e-6,0.001}					
	make/o/t smear_parameters_fuzz_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_fuzz_HS,smear_coef_fuzz_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fuzz_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fuzz_HS							
					
	Variable/G gs_fuzz_HS=0
	gs_fuzz_HS := fSmearedFuzzySphere_HS(smear_coef_fuzz_HS,smeared_fuzz_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fuzz_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFuzzySphere_HS","smear_coef_fuzz_HS","smear_parameters_fuzz_HS","fuzz_HS")
End



Function FuzzySphere_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_fuzz_HS
	form_fuzz_HS[0] = 1
	form_fuzz_HS[1] = w[1]
	form_fuzz_HS[2] = w[2]
	form_fuzz_HS[3] = w[3]
	form_fuzz_HS[4] = w[4]
	form_fuzz_HS[5] = w[5]
	form_fuzz_HS[6] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_fuzz_HS
	struct_fuzz_HS[0] = diam/2
	struct_fuzz_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw tmp_fuzz_HS_PQ,tmp_fuzz_HS_SQ
	FuzzySpheres(form_fuzz_HS,tmp_fuzz_HS_PQ,xw)
	HardSphereStruct(struct_fuzz_HS,tmp_fuzz_HS_SQ,xw)
	yw = tmp_fuzz_HS_PQ * tmp_fuzz_HS_SQ
	yw *= w[0]
	yw += w[6]
	
	//cleanup waves
//	Killwaves/Z form_fuzz_HS,struct_fuzz_HS
	
	return (0)
End

/////////////////////////////////////////
Proc PlotFuzzySphere_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_fuzz_SW,ywave_fuzz_SW
	xwave_fuzz_SW = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_fuzz_SW = {0.01,60,0.2,10,1e-6,3e-6,1.0,1.2,0.001}
	make/O/T parameters_fuzz_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}
	Edit parameters_fuzz_SW,coef_fuzz_SW
	
	Variable/G root:g_fuzz_SW
	g_fuzz_SW := FuzzySphere_SW(coef_fuzz_SW,ywave_fuzz_SW,xwave_fuzz_SW)
	Display ywave_fuzz_SW vs xwave_fuzz_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FuzzySphere_SW","coef_fuzz_SW","parameters_fuzz_SW","fuzz_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFuzzySphere_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fuzz_SW = {0.01,60,0.2,10,1e-6,3e-6,1.0,1.2,0.001}					
	make/o/t smear_parameters_fuzz_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_fuzz_SW,smear_coef_fuzz_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fuzz_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fuzz_SW							
					
	Variable/G gs_fuzz_SW=0
	gs_fuzz_SW := fSmearedFuzzySphere_SW(smear_coef_fuzz_SW,smeared_fuzz_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fuzz_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFuzzySphere_SW","smear_coef_fuzz_SW","smear_parameters_fuzz_SW","fuzz_SW")
End
	

Function FuzzySphere_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_fuzz_SW
	form_fuzz_SW[0] = 1
	form_fuzz_SW[1] = w[1]
	form_fuzz_SW[2] = w[2]
	form_fuzz_SW[3] = w[3]
	form_fuzz_SW[4] = w[4]
	form_fuzz_SW[5] = w[5]
	form_fuzz_SW[6] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_fuzz_SW
	struct_fuzz_SW[0] = diam/2
	struct_fuzz_SW[1] = w[0]
	struct_fuzz_SW[2] = w[6]
	struct_fuzz_SW[3] = w[7]
	
	//calculate each and combine
	Duplicate/O xw tmp_fuzz_SW_PQ,tmp_fuzz_SW_SQ
	FuzzySpheres(form_fuzz_SW,tmp_fuzz_SW_PQ,xw)
	SquareWellStruct(struct_fuzz_SW,tmp_fuzz_SW_SQ,xw)
	yw = tmp_fuzz_SW_PQ * tmp_fuzz_SW_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_fuzz_SW,struct_fuzz_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotFuzzySphere_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave

	Make/O/D/N=(num) xwave_fuzz_SC,ywave_fuzz_SC
	xwave_fuzz_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_fuzz_SC = {0.01,60,0.2,10,1e-6,3e-6,20,0,298,78,0.001}
	make/O/T parameters_fuzz_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}
	Edit parameters_fuzz_SC,coef_fuzz_SC
	
	Variable/G root:g_fuzz_SC
	g_fuzz_SC := FuzzySphere_SC(coef_fuzz_SC,ywave_fuzz_SC,xwave_fuzz_SC)
	Display ywave_fuzz_SC vs xwave_fuzz_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FuzzySphere_SC","coef_fuzz_SC","parameters_fuzz_SC","fuzz_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFuzzySphere_SC(str)								
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
	Make/O/D smear_coef_fuzz_SC = {0.01,60,0.2,10,1e-6,3e-6,20,0,298,78,0.001}					
	make/o/t smear_parameters_fuzz_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_fuzz_SC,smear_coef_fuzz_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fuzz_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fuzz_SC							
					
	Variable/G gs_fuzz_SC=0
	gs_fuzz_SC := fSmearedFuzzySphere_SC(smear_coef_fuzz_SC,smeared_fuzz_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fuzz_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFuzzySphere_SC","smear_coef_fuzz_SC","smear_parameters_fuzz_SC","fuzz_SC")
End


Function FuzzySphere_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_fuzz_SC
	form_fuzz_SC[0] = 1
	form_fuzz_SC[1] = w[1]
	form_fuzz_SC[2] = w[2]
	form_fuzz_SC[3] = w[3]
	form_fuzz_SC[4] = w[4]
	form_fuzz_SC[5] = w[5]
	form_fuzz_SC[6] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_fuzz_SC
	struct_fuzz_SC[0] = diam
	struct_fuzz_SC[1] = w[6]
	struct_fuzz_SC[2] = w[0]
	struct_fuzz_SC[3] = w[8]
	struct_fuzz_SC[4] = w[7]
	struct_fuzz_SC[5] = w[9]
	
	//calculate each and combine
	Duplicate/O xw tmp_fuzz_SC_PQ,tmp_fuzz_SC_SQ
	FuzzySpheres(form_fuzz_SC,tmp_fuzz_SC_PQ,xw)
	HayterPenfoldMSA(struct_fuzz_SC,tmp_fuzz_SC_SQ,xw)
	yw = tmp_fuzz_SC_PQ * tmp_fuzz_SC_SQ
	yw *= w[0]
	yw += w[10]
	
	//cleanup waves
//	Killwaves/Z form_fuzz_SC,struct_fuzz_SC
	
	return (0)
End

/////////////////////////////////////////
Proc PlotFuzzySphere_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_fuzz_SHS,ywave_fuzz_SHS
	xwave_fuzz_SHS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_fuzz_SHS = {0.01,60,0.2,10,1e-6,3e-6,0.05,0.2,0.001}
	make/O/T parameters_fuzz_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}
	Edit parameters_fuzz_SHS,coef_fuzz_SHS
	
	Variable/G root:g_fuzz_SHS
	g_fuzz_SHS := FuzzySphere_SHS(coef_fuzz_SHS,ywave_fuzz_SHS,xwave_fuzz_SHS)
	Display ywave_fuzz_SHS vs xwave_fuzz_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FuzzySphere_SHS","coef_fuzz_SHS","parameters_fuzz_SHS","fuzz_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFuzzySphere_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fuzz_SHS = {0.01,60,0.2,10,1e-6,3e-6,0.05,0.2,0.001}					
	make/o/t smear_parameters_fuzz_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","interface thickness (A)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_fuzz_SHS,smear_coef_fuzz_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fuzz_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fuzz_SHS							
					
	Variable/G gs_fuzz_SHS=0
	gs_fuzz_SHS := fSmearedFuzzySphere_SHS(smear_coef_fuzz_SHS,smeared_fuzz_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fuzz_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFuzzySphere_SHS","smear_coef_fuzz_SHS","smear_parameters_fuzz_SHS","fuzz_SHS")
End
	

Function FuzzySphere_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=7 form_fuzz_SHS
	form_fuzz_SHS[0] = 1
	form_fuzz_SHS[1] = w[1]
	form_fuzz_SHS[2] = w[2]
	form_fuzz_SHS[3] = w[3]
	form_fuzz_SHS[4] = w[4]
	form_fuzz_SHS[5] = w[5]
	form_fuzz_SHS[6] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,Vpoly,Ravg
	pd = w[2]
	Ravg = w[1]
	
	Vpoly = (4*pi/3*Ravg^3)*(1+3*pd^2)
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_fuzz_SHS
	struct_fuzz_SHS[0] = diam/2
	struct_fuzz_SHS[1] = w[0]
	struct_fuzz_SHS[2] = w[6]
	struct_fuzz_SHS[3] = w[7]
	
	//calculate each and combine
	Duplicate/O xw tmp_fuzz_SHS_PQ,tmp_fuzz_SHS_SQ
	FuzzySpheres(form_fuzz_SHS,tmp_fuzz_SHS_PQ,xw)
	StickyHS_Struct(struct_fuzz_SHS,tmp_fuzz_SHS_SQ,xw)
	yw = tmp_fuzz_SHS_PQ * tmp_fuzz_SHS_SQ
	yw *= w[0]
	yw += w[8]
	
	//cleanup waves
//	Killwaves/Z form_fuzz_SHS,struct_fuzz_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedFuzzySphere_HS(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FuzzySphere_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedFuzzySphere_SW(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FuzzySphere_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedFuzzySphere_SC(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FuzzySphere_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedFuzzySphere_SHS(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FuzzySphere_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFuzzySphere_HS(coefW,yW,xW)
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
	err = SmearedFuzzySphere_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFuzzySphere_SW(coefW,yW,xW)
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
	err = SmearedFuzzySphere_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFuzzySphere_SC(coefW,yW,xW)
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
	err = SmearedFuzzySphere_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFuzzySphere_SHS(coefW,yW,xW)
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
	err = SmearedFuzzySphere_SHS(fs)
	
	return (0)
End