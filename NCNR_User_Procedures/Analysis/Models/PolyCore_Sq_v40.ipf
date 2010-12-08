#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
// be sure to include all of the necessary files
//
#include "PolyCore_v40"

#include "HardSphereStruct_v40"
#include "HPMSA_v40"
#include "SquareWellStruct_v40"
#include "StickyHardSphereStruct_v40"
#include "Two_Yukawa_v40"

Proc PlotPolyCore_HS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCF_HS,ywave_PCF_HS
	xwave_PCF_HS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_HS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t parameters_PCF_HS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_HS,coef_PCF_HS
	Variable/G root:g_PCF_HS
	g_PCF_HS := PolyCore_HS(coef_PCF_HS,ywave_PCF_HS,xwave_PCF_HS)
//	ywave_PCF_HS := PolyCore_HS(coef_PCF_HS,xwave_PCF_HS)
	Display/K=1 ywave_PCF_HS vs xwave_PCF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCore_HS","coef_PCF_HS","parameters_PCF_HS","PCF_HS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCore_HS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_HS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t smear_parameters_PCF_HS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_PCF_HS,smear_coef_PCF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_HS							
					
	Variable/G gs_PCF_HS=0
	gs_PCF_HS := fSmearedPolyCore_HS(smear_coef_PCF_HS,smeared_PCF_HS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCore_HS","smear_coef_PCF_HS","smear_parameters_PCF_HS","PCF_HS")
End
	

//AAO function
Function PolyCore_HS(w,yw,xw) : FitFunc
	Wave w,yw,xw
		
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCF_HS
	form_PCF_HS[0] = 1
	form_PCF_HS[1] = w[1]
	form_PCF_HS[2] = w[2]
	form_PCF_HS[3] = w[3]
	form_PCF_HS[4] = w[4]
	form_PCF_HS[5] = w[5]
	form_PCF_HS[6] = w[6]
	form_PCF_HS[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[3]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	
	//setup structure factor coefficient wave
	Make/O/D/N=2 struct_PCF_HS
	struct_PCF_HS[0] = diam/2
	struct_PCF_HS[1] = w[0]
	
	//calculate each and combine
	Duplicate/O xw temp_PCF_HS_PQ,temp_PCF_HS_SQ		//make waves for the AAO
	PolyCoreForm(form_PCF_HS,temp_PCF_HS_PQ,xw)
	HardSphereStruct(struct_PCF_HS,temp_PCF_HS_SQ,xw)
	yw = temp_PCF_HS_PQ*temp_PCF_HS_SQ
	yw *= w[0]
	yw += w[7]
	
	//cleanup waves
//	Killwaves/Z form_PCF_HS,struct_PCF_HS
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyCore_SW(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCF_SW,ywave_PCF_SW
	xwave_PCF_SW = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_SW = {0.1,60,.2,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t parameters_PCF_SW = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_SW,coef_PCF_SW
	
	Variable/G root:g_PCF_SW
	g_PCF_SW := PolyCore_SW(coef_PCF_SW,ywave_PCF_SW,xwave_PCF_SW)
	Display/K=1 ywave_PCF_SW vs xwave_PCF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCore_SW","coef_PCF_SW","parameters_PCF_SW","PCF_SW")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCore_SW(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_SW = {0.1,60,.2,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_PCF_SW = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_PCF_SW,smear_coef_PCF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SW							
					
	Variable/G gs_PCF_SW=0
	gs_PCF_SW := fSmearedPolyCore_SW(smear_coef_PCF_SW,smeared_PCF_SW,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCore_SW","smear_coef_PCF_SW","smear_parameters_PCF_SW","PCF_SW")
End
	

Function PolyCore_SW(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCF_SW
	form_PCF_SW[0] = 1
	form_PCF_SW[1] = w[1]
	form_PCF_SW[2] = w[2]
	form_PCF_SW[3] = w[3]
	form_PCF_SW[4] = w[4]
	form_PCF_SW[5] = w[5]
	form_PCF_SW[6] = w[6]
	form_PCF_SW[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[3]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PCF_SW
	struct_PCF_SW[0] = diam/2
	struct_PCF_SW[1] = w[0]
	struct_PCF_SW[2] = w[7]
	struct_PCF_SW[3] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_PCF_SW_PQ,temp_PCF_SW_SQ		//make waves for the AAO
	PolyCoreForm(form_PCF_SW,temp_PCF_SW_PQ,xw)
	SquareWellStruct(struct_PCF_SW,temp_PCF_SW_SQ,xw)
	yw = temp_PCF_SW_PQ * temp_PCF_SW_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SW,struct_PCF_SW
	
	return (0)
End


/////////////////////////////////////////
Proc PlotPolyCore_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if(!DataFolderExists(":HayPenMSA"))
		NewDataFolder :HayPenMSA
	endif
 	Make/O/D/N=17 :HayPenMSA:gMSAWave
	
	Make/O/D/n=(num) xwave_PCF_SC,ywave_PCF_SC
	xwave_PCF_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_SC = {0.1,60,.2,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t parameters_PCF_SC = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_SC,coef_PCF_SC
	
	Variable/G root:g_PCF_SC
	g_PCF_SC := PolyCore_SC(coef_PCF_SC,ywave_PCF_SC,xwave_PCF_SC)
	Display/K=1 ywave_PCF_SC vs xwave_PCF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCore_SC","coef_PCF_SC","parameters_PCF_SC","PCF_SC")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCore_SC(str)								
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
	Make/O/D smear_coef_PCF_SC = {0.1,60,.2,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_PCF_SC = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_PCF_SC,smear_coef_PCF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SC							
					
	Variable/G gs_PCF_SC=0
	gs_PCF_SC := fSmearedPolyCore_SC(smear_coef_PCF_SC,smeared_PCF_SC,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCore_SC","smear_coef_PCF_SC","smear_parameters_PCF_SC","PCF_SC")
End


Function PolyCore_SC(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCF_SC
	form_PCF_SC[0] = 1
	form_PCF_SC[1] = w[1]
	form_PCF_SC[2] = w[2]
	form_PCF_SC[3] = w[3]
	form_PCF_SC[4] = w[4]
	form_PCF_SC[5] = w[5]
	form_PCF_SC[6] = w[6]
	form_PCF_SC[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[3]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PCF_SC
	struct_PCF_SC[0] = diam
	struct_PCF_SC[1] = w[7]
	struct_PCF_SC[2] = w[0]
	struct_PCF_SC[3] = w[9]
	struct_PCF_SC[4] = w[8]
	struct_PCF_SC[5] = w[10]
	
	//calculate each and combine
	Duplicate/O xw temp_PCF_SC_PQ,temp_PCF_SC_SQ		//make waves for the AAO
	PolyCoreForm(form_PCF_SC,temp_PCF_SC_PQ,xw)
	HayterPenfoldMSA(struct_PCF_SC,temp_PCF_SC_SQ,xw)
	yw = temp_PCF_SC_PQ * temp_PCF_SC_SQ
	yw *= w[0]
	yw += w[11]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SC,struct_PCF_SC
	
	return (0)
End

/////////////////////////////////////////
Proc PlotPolyCore_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCF_SHS,ywave_PCF_SHS
	xwave_PCF_SHS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_SHS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t parameters_PCF_SHS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_SHS,coef_PCF_SHS
	
	Variable/G root:g_PCF_SHS
	g_PCF_SHS := PolyCore_SHS(coef_PCF_SHS,ywave_PCF_SHS,xwave_PCF_SHS)
	Display/K=1 ywave_PCF_SHS vs xwave_PCF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCore_SHS","coef_PCF_SHS","parameters_PCF_SHS","PCF_SHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCore_SHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_SHS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_PCF_SHS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_PCF_SHS,smear_coef_PCF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SHS							
					
	Variable/G gs_PCF_SHS=0
	gs_PCF_SHS := fSmearedPolyCore_SHS(smear_coef_PCF_SHS,smeared_PCF_SHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCore_SHS","smear_coef_PCF_SHS","smear_parameters_PCF_SHS","PCF_SHS")
End
	

Function PolyCore_SHS(w,yw,xw) : FitFunc
	Wave w,yw,xw
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCF_SHS
	form_PCF_SHS[0] = 1
	form_PCF_SHS[1] = w[1]
	form_PCF_SHS[2] = w[2]
	form_PCF_SHS[3] = w[3]
	form_PCF_SHS[4] = w[4]
	form_PCF_SHS[5] = w[5]
	form_PCF_SHS[6] = w[6]
	form_PCF_SHS[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[3]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	//setup structure factor coefficient wave
	Make/O/D/N=4 struct_PCF_SHS
	struct_PCF_SHS[0] = diam/2
	struct_PCF_SHS[1] = w[0]
	struct_PCF_SHS[2] = w[7]
	struct_PCF_SHS[3] = w[8]
	
	//calculate each and combine
	Duplicate/O xw temp_PCF_SHS_PQ,temp_PCF_SHS_SQ		//make waves for the AAO
	PolyCoreForm(form_PCF_SHS,temp_PCF_SHS_PQ,xw)
	StickyHS_Struct(struct_PCF_SHS,temp_PCF_SHS_SQ,xw)
	yw = temp_PCF_SHS_PQ * temp_PCF_SHS_SQ
	yw *= w[0]
	yw += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SW,struct_PCF_SW
	
	return (0)
End

// two yukawa
Proc PlotPolyCore_2Y(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_PCF_2Y,ywave_PCF_2Y
	xwave_PCF_2Y = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_2Y = {0.1,60,.2,10,1e-6,2e-6,3e-6,6,10,-1,2,0.0001}
	make/o/t parameters_PCF_2Y = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","scale, K1","charge, Z1","scale, K2","charge, Z2","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_2Y,coef_PCF_2Y
	Variable/G root:g_PCF_2Y
	g_PCF_2Y := PolyCore_2Y(coef_PCF_2Y,ywave_PCF_2Y,xwave_PCF_2Y)
//	ywave_PCF_2Y := PolyCore_2Y(coef_PCF_2Y,xwave_PCF_2Y)
	Display/K=1 ywave_PCF_2Y vs xwave_PCF_2Y
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCore_2Y","coef_PCF_2Y","parameters_PCF_2Y","PCF_2Y")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCore_2Y(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_2Y = {0.1,60,.2,10,1e-6,2e-6,3e-6,6,10,-1,2,0.0001}
	make/o/t smear_parameters_PCF_2Y = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","scale, K1","charge, Z1","scale, K2","charge, Z2","bkg (cm-1)"}
	Edit smear_parameters_PCF_2Y,smear_coef_PCF_2Y					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PCF_2Y,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_2Y							
					
	Variable/G gs_PCF_2Y=0
	gs_PCF_2Y := fSmearedPolyCore_2Y(smear_coef_PCF_2Y,smeared_PCF_2Y,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PCF_2Y vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCore_2Y","smear_coef_PCF_2Y","smear_parameters_PCF_2Y","PCF_2Y")
End
	

//AAO function
Function PolyCore_2Y(w,yw,xw) : FitFunc
	Wave w,yw,xw
		
	//setup form factor coefficient wave
	Make/O/D/N=8 form_PCF_2Y
	form_PCF_2Y[0] = 1
	form_PCF_2Y[1] = w[1]
	form_PCF_2Y[2] = w[2]
	form_PCF_2Y[3] = w[3]
	form_PCF_2Y[4] = w[4]
	form_PCF_2Y[5] = w[5]
	form_PCF_2Y[6] = w[6]
	form_PCF_2Y[7] = 0
	
	//calculate the diameter of the effective one-component sphere
	Variable pd,diam,zz,Vpoly,Ravg,thick
	pd = w[2]
	zz = (1/pd)^2 - 1
	Ravg = w[1]
	thick = w[3]
	
	Vpoly = 4*pi/3*(Ravg+thick)^3*(zz+3)*(zz+2)/(zz+1)^2
	diam = (6*Vpoly/pi)^(1/3)
	
	
	//setup structure factor coefficient wave
	Make/O/D/N=6 struct_PCF_2Y
	struct_PCF_2Y[0] = w[0]
	struct_PCF_2Y[1] = diam/2
	struct_PCF_2Y[2] = w[7]
	struct_PCF_2Y[3] = w[8]
	struct_PCF_2Y[4] = w[9]
	struct_PCF_2Y[5] = w[10]
	
	//calculate each and combine
	Duplicate/O xw temp_PCF_2Y_PQ,temp_PCF_2Y_SQ		//make waves for the AAO
	PolyCoreForm(form_PCF_2Y,temp_PCF_2Y_PQ,xw)
	TwoYukawa(struct_PCF_2Y,temp_PCF_2Y_SQ,xw)
	yw = temp_PCF_2Y_PQ*temp_PCF_2Y_SQ
	yw *= w[0]
	yw += w[11]
	
	//cleanup waves
//	Killwaves/Z form_PCF_2Y,struct_PCF_2Y
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_HS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCore_HS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SW(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCore_SW,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SC(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCore_SC,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCore_SHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_2Y(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCore_2Y,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCore_HS(coefW,yW,xW)
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
	err = SmearedPolyCore_HS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCore_SW(coefW,yW,xW)
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
	err = SmearedPolyCore_SW(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCore_SC(coefW,yW,xW)
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
	err = SmearedPolyCore_SC(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCore_SHS(coefW,yW,xW)
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
	err = SmearedPolyCore_SHS(fs)
	
	return (0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCore_2Y(coefW,yW,xW)
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
	err = SmearedPolyCore_2Y(fs)
	
	return (0)
End
