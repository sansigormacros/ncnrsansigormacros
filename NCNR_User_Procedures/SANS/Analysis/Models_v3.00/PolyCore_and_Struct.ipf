#pragma rtGlobals=1		// Use modern global access method.
//
// be sure to include all of the necessary files
//
#include "PolyCore"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

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
	ywave_PCF_HS := PolyCore_HS(coef_PCF_HS,xwave_PCF_HS)
	Display/K=1 ywave_PCF_HS vs xwave_PCF_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyCore_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_HS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.0001}
	make/o/t smear_parameters_PCF_HS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_PCF_HS,smear_coef_PCF_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PCF_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_HS							

	smeared_PCF_HS := SmearedPolyCore_HS(smear_coef_PCF_HS,$gQvals)		
	Display smeared_PCF_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyCore_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
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
	inten = PolyCoreForm(form_PCF_HS,x)
	inten *= HardSphereStruct(struct_PCF_HS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_PCF_HS,struct_PCF_HS
	
	return (inten)
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
	ywave_PCF_SW := PolyCore_SW(coef_PCF_SW,xwave_PCF_SW)
	Display/K=1 ywave_PCF_SW vs xwave_PCF_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyCore_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_SW = {0.1,60,.2,10,1e-6,2e-6,3e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_PCF_SW = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_PCF_SW,smear_coef_PCF_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PCF_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SW							

	smeared_PCF_SW := SmearedPolyCore_SW(smear_coef_PCF_SW,$gQvals)		
	Display smeared_PCF_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyCore_SW(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = PolyCoreForm(form_PCF_SW,x)
	inten *= SquareWellStruct(struct_PCF_SW,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SW,struct_PCF_SW
	
	return (inten)
End


/////////////////////////////////////////
Proc PlotPolyCore_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif
	
	Make/O/D/n=(num) xwave_PCF_SC,ywave_PCF_SC
	xwave_PCF_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_PCF_SC = {0.1,60,.2,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t parameters_PCF_SC = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_PCF_SC,coef_PCF_SC
	ywave_PCF_SC := PolyCore_SC(coef_PCF_SC,xwave_PCF_SC)
	Display/K=1 ywave_PCF_SC vs xwave_PCF_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyCore_SC()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif

	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_SC = {0.1,60,.2,10,1e-6,2e-6,3e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_PCF_SC = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_PCF_SC,smear_coef_PCF_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PCF_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SC							

	smeared_PCF_SC := SmearedPolyCore_SC(smear_coef_PCF_SC,$gQvals)		
	Display smeared_PCF_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyCore_SC(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = PolyCoreForm(form_PCF_SC,x)
	inten *= HayterPenfoldMSA(struct_PCF_SC,x)
	inten *= w[0]
	inten += w[11]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SC,struct_PCF_SC
	
	return (inten)
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
	ywave_PCF_SHS := PolyCore_SHS(coef_PCF_SHS,xwave_PCF_SHS)
	Display/K=1 ywave_PCF_SHS vs xwave_PCF_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyCore_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PCF_SHS = {0.1,60,.2,10,1e-6,2e-6,3e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_PCF_SHS = {"volume fraction","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_PCF_SHS,smear_coef_PCF_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_PCF_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_PCF_SHS							

	smeared_PCF_SHS := SmearedPolyCore_SHS(smear_coef_PCF_SHS,$gQvals)		
	Display smeared_PCF_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyCore_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = PolyCoreForm(form_PCF_SHS,x)
	inten *= StickyHS_Struct(struct_PCF_SHS,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_PCF_SW,struct_PCF_SW
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedPolyCore_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyCore_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyCore_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyCore_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyCore_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyCore_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End