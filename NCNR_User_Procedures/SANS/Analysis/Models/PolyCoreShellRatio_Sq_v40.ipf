#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// be sure to include all the necessary files...

#include "PolyCoreShellRatio_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"

Proc PlotPolyCSRatio_HS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCR_HS,ywave_PCR_HS
	xwave_PCR_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PCR_HS = {0.1,60,10,0.1,1e-6,2e-6,6e-6,0.0001}
	make/o/t parameters_PCR_HS = {"volume fraction","avg radius (A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit/K=1 parameters_PCR_HS,coef_PCR_HS
	
	Variable/G root:g_PCR_HS
	g_PCR_HS := PolyCSRatio_HS(coef_PCR_HS,ywave_PCR_HS,xwave_PCR_HS)
	Display/K=1 ywave_PCR_HS vs xwave_PCR_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCSRatio_HS","coef_PCR_HS","PCR_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCSRatio_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCR_HS = {0.1,60,10,0.1,1e-6,2e-6,6e-6,0.0001}
	make/o/t smear_parameters_PCR_HS = {"volume fraction","avg radius (A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_PCR_HS,smear_coef_PCR_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCR_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCR_HS							
					
	Variable/G gs_PCR_HS=0
	gs_PCR_HS := fSmearedPolyCSRatio_HS(smear_coef_PCR_HS,smeared_PCR_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCR_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCSRatio_HS","smear_coef_PCR_HS","PCR_HS")
End
	

Function PolyCSRatio_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCR_HS
	form_PCR_HS[0] = 1
	form_PCR_HS[1] = w[1]
	form_PCR_HS[2] = w[2]
	form_PCR_HS[3] = w[3]
	form_PCR_HS[4] = w[4]
	form_PCR_HS[5] = w[5]
	form_PCR_HS[6] = w[6]
	form_PCR_HS[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[3]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[2]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_PCR_HS
	struct_PCR_HS[0] = diam/2
	struct_PCR_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_PCR_HS_PQ,temp_PCR_HS_SQ		//make waves for the AAO
	PolyCoreShellRatio(form_PCR_HS,temp_PCR_HS_PQ,xw)
	HardSphereStruct(struct_PCR_HS,temp_PCR_HS_SQ,xw)
	yw = temp_PCR_HS_PQ * temp_PCR_HS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_PCR_HS,struct_PCR_HS
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyCSRatio_SW(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCR_SW,ywave_PCR_SW
	xwave_PCR_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PCR_SW = {0.1,60,10,0.1,1e-6,2e-6,3e-6,1,1.2,0.0001}
	make/o/t parameters_PCR_SW = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit/K=1 parameters_PCR_SW,coef_PCR_SW
	
	Variable/G root:g_PCR_SW
	g_PCR_SW := PolyCSRatio_SW(coef_PCR_SW,ywave_PCR_SW,xwave_PCR_SW)
	Display/K=1 ywave_PCR_SW vs xwave_PCR_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCSRatio_SW","coef_PCR_SW","PCR_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCSRatio_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCR_SW = {0.1,60,10,0.1,1e-6,2e-6,3e-6,1,1.2,0.0001}
	make/o/t smear_parameters_PCR_SW = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_PCR_SW,smear_coef_PCR_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCR_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCR_SW							
					
	Variable/G gs_PCR_SW=0
	gs_PCR_SW := fSmearedPolyCSRatio_SW(smear_coef_PCR_SW,smeared_PCR_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCR_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCSRatio_SW","smear_coef_PCR_SW","PCR_SW")
End
	

Function PolyCSRatio_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCR_SW
	form_PCR_SW[0] = 1
	form_PCR_SW[1] = w[1]
	form_PCR_SW[2] = w[2]
	form_PCR_SW[3] = w[3]
	form_PCR_SW[4] = w[4]
	form_PCR_SW[5] = w[5]
	form_PCR_SW[6] = w[6]
	form_PCR_SW[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[3]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[2]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PCR_SW
	struct_PCR_SW[0] = diam/2
	struct_PCR_SW[1] = w[0]
	struct_PCR_SW[2] = w[7]
	struct_PCR_SW[3] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_PCR_SW_PQ,temp_PCR_SW_SQ		//make waves for the AAO
	PolyCoreShellRatio(form_PCR_SW,temp_PCR_SW_PQ,xw)
	SquareWellStruct(struct_PCR_SW,temp_PCR_SW_SQ,xw)
	yw = temp_PCR_SW_PQ * temp_PCR_SW_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCR_SW,struct_PCR_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotPolyCSRatio_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_PCR_SC,ywave_PCR_SC
	xwave_PCR_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PCR_SC = {0.1,60,10,0.1,1e-6,2e-6,6e-6,10,0,298,78,0.0001}
	make/o/t parameters_PCR_SC = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_PCR_SC,coef_PCR_SC
	
	Variable/G root:g_PCR_SC
	g_PCR_SC := PolyCSRatio_SC(coef_PCR_SC,ywave_PCR_SC,xwave_PCR_SC)
	Display/K=1 ywave_PCR_SC vs xwave_PCR_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCSRatio_SC","coef_PCR_SC","PCR_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCSRatio_SC(str)								
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
	Make/O/D smear_coef_PCR_SC = {0.1,60,10,0.1,1e-6,2e-6,6e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_PCR_SC = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_PCR_SC,smear_coef_PCR_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCR_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCR_SC							
					
	Variable/G gs_PCR_SC=0
	gs_PCR_SC := fSmearedPolyCSRatio_SC(smear_coef_PCR_SC,smeared_PCR_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCR_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCSRatio_SC","smear_coef_PCR_SC","PCR_SC")
End


Function PolyCSRatio_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCR_SC
	form_PCR_SC[0] = 1
	form_PCR_SC[1] = w[1]
	form_PCR_SC[2] = w[2]
	form_PCR_SC[3] = w[3]
	form_PCR_SC[4] = w[4]
	form_PCR_SC[5] = w[5]
	form_PCR_SC[6] = w[6]
	form_PCR_SC[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[3]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[2]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PCR_SC
	struct_PCR_SC[0] = diam
	struct_PCR_SC[1] = w[7]
	struct_PCR_SC[2] = w[0]
	struct_PCR_SC[3] = w[9]
	struct_PCR_SC[4] = w[8]
	struct_PCR_SC[5] = w[10]
	
	//calculate each and combine
	Duplicate/O xw temp_PCR_SC_PQ,temp_PCR_SC_SQ		//make waves for the AAO
	PolyCoreShellRatio(form_PCR_SC,temp_PCR_SC_PQ,xw)
	HayterPenfoldMSA(struct_PCR_SC,temp_PCR_SC_SQ,xw)
	yw = temp_PCR_SC_PQ * temp_PCR_SC_SQ
	yw *= w[0]
	yw += w[11]
	
	//cleanup waves
//	Killwaves/Z form_PCR_SC,struct_PCR_SC
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyCSRatio_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCR_SHS,ywave_PCR_SHS
	xwave_PCR_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PCR_SHS = {0.1,60,10,0.1,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t parameters_PCR_SHS = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit/K=1 parameters_PCR_SHS,coef_PCR_SHS
	
	Variable/G root:g_PCR_SHS
	g_PCR_SHS := PolyCSRatio_SHS(coef_PCR_SHS,ywave_PCR_SHS,xwave_PCR_SHS)
	Display/K=1 ywave_PCR_SHS vs xwave_PCR_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCSRatio_SHS","coef_PCR_SHS","PCR_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCSRatio_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCR_SHS = {0.1,60,10,0.1,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_PCR_SHS = {"volume fraction","avg radius(A)","avg shell thickness (A)","overall polydispersity","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_PCR_SHS,smear_coef_PCR_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCR_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCR_SHS							
					
	Variable/G gs_PCR_SHS=0
	gs_PCR_SHS := fSmearedPolyCSRatio_SHS(smear_coef_PCR_SHS,smeared_PCR_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCR_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCSRatio_SHS","smear_coef_PCR_SHS","PCR_SHS")
End


Function PolyCSRatio_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCR_SHS
	form_PCR_SHS[0] = 1
	form_PCR_SHS[1] = w[1]
	form_PCR_SHS[2] = w[2]
	form_PCR_SHS[3] = w[3]
	form_PCR_SHS[4] = w[4]
	form_PCR_SHS[5] = w[5]
	form_PCR_SHS[6] = w[6]
	form_PCR_SHS[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[3]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[2]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PCR_SHS
	struct_PCR_SHS[0] = diam/2
	struct_PCR_SHS[1] = w[0]
	struct_PCR_SHS[2] = w[7]
	struct_PCR_SHS[3] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_PCR_SHS_PQ,temp_PCR_SHS_SQ		//make waves for the AAO
	PolyCoreShellRatio(form_PCR_SHS,temp_PCR_SHS_PQ,xw)
	StickyHS_Struct(struct_PCR_SHS,temp_PCR_SHS_SQ,xw)
	yw = temp_PCR_SHS_PQ * temp_PCR_SHS_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCR_SHS,struct_PCR_SHS
	
	return (0)
End



// this is all there is to the smeared calculation!
Function SmearedPolyCSRatio_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCSRatio_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCSRatio_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCSRatio_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCSRatio_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCSRatio_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCSRatio_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCSRatio_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCSRatio_HS(coefW,yW,xW)
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
	err = SmearedPolyCSRatio_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCSRatio_SW(coefW,yW,xW)
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
	err = SmearedPolyCSRatio_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCSRatio_SC(coefW,yW,xW)
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
	err = SmearedPolyCSRatio_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCSRatio_SHS(coefW,yW,xW)
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
	err = SmearedPolyCSRatio_SHS(fs)
	
	return (0)
End