#pragma rtGlobals=1		// Use modern global access method.

// be sure to include all the necessary files...

#include "RectPolySpheres"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotPolyRectSphere_HS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_HS,ywave_RECT_HS
	xwave_RECT_HS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_HS = {0.1,60,0.1,6e-6,0.0001}
	make/o/t parameters_RECT_HS = {"volume fraction","avg radius (A)","polydispersity","contrast (A-2)","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_HS,coef_RECT_HS
	ywave_RECT_HS := PolyRectSphere_HS(coef_RECT_HS,xwave_RECT_HS)
	Display/K=1 ywave_RECT_HS vs xwave_RECT_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyRectSphere_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_HS = {0.1,60,0.1,6e-6,0.0001}
	make/o/t smear_parameters_RECT_HS = {"volume fraction","avg radius (A)","polydispersity","contrast (A-2)","bkg (cm-1)"}
	Edit smear_parameters_RECT_HS,smear_coef_RECT_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_RECT_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_HS							

	smeared_RECT_HS := SmearedPolyRectSphere_HS(smear_coef_RECT_HS,$gQvals)		
	Display smeared_RECT_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyRectSphere_HS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_RECT_HS
	form_RECT_HS[0] = 1
	form_RECT_HS[1] = w[1]
	form_RECT_HS[2] = w[2]
	form_RECT_HS[3] = w[3]
	form_RECT_HS[4] = 0
	
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
	inten = PolyRectSpheres(form_RECT_HS,x)
	inten *= HardSphereStruct(struct_RECT_HS,x)
	inten *= w[0]
	inten += w[4]
	
	//cleanup waves
//	Killwaves/Z form_RECT_HS,struct_RECT_HS
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotPolyRectSphere_SW(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_SW,ywave_RECT_SW
	xwave_RECT_SW =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SW = {0.1,60,0.1,6e-6,1.0,1.2,0.0001}
	make/o/t parameters_RECT_SW = {"volume fraction","avg radius(A)","polydispersity","contrast (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SW,coef_RECT_SW
	ywave_RECT_SW := PolyRectSphere_SW(coef_RECT_SW,xwave_RECT_SW)
	Display/K=1 ywave_RECT_SW vs xwave_RECT_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyRectSphere_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_SW = {0.1,60,0.1,6e-6,1.0,1.2,0.0001}
	make/o/t smear_parameters_RECT_SW = {"volume fraction","avg radius(A)","polydispersity","contrast (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1)"}
	Edit smear_parameters_RECT_SW,smear_coef_RECT_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_RECT_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SW							

	smeared_RECT_SW := SmearedPolyRectSphere_SW(smear_coef_RECT_SW,$gQvals)		
	Display smeared_RECT_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyRectSphere_SW(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_RECT_SW
	form_RECT_SW[0] = 1
	form_RECT_SW[1] = w[1]
	form_RECT_SW[2] = w[2]
	form_RECT_SW[3] = w[3]
	form_RECT_SW[4] = 0
	
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
	struct_RECT_SW[2] = w[4]
	struct_RECT_SW[3] = w[5]
	
	//calculate each and combine
	inten = PolyRectSpheres(form_RECT_SW,x)
	inten *= SquareWellStruct(struct_RECT_SW,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SW,struct_RECT_SW
	
	return (inten)
End


/////////////////////////////////////////
Proc PlotPolyRectSphere_SC(num,qmin,qmax)
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
	
	Make/O/D/n=(num) xwave_RECT_SC,ywave_RECT_SC
	xwave_RECT_SC =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SC = {0.1,60,0.1,6e-6,10,0,298,78,0.0001}
	make/o/t parameters_RECT_SC = {"volume fraction","avg radius (A)","polydispersity","contrast (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SC,coef_RECT_SC
	ywave_RECT_SC := PolyRectSphere_SC(coef_RECT_SC,xwave_RECT_SC)
	Display/K=1 ywave_RECT_SC vs xwave_RECT_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyRectSphere_SC()								
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
	Make/O/D smear_coef_RECT_SC = {0.1,60,0.1,6e-6,10,0,298,78,0.0001}
	make/o/t smear_parameters_RECT_SC = {"volume fraction","avg radius (A)","polydispersity","contrast (A-2)","charge","Monovalent salt (M)","Temperature (K)","dielectric const.","bkg (cm-1)"}
	Edit smear_parameters_RECT_SC,smear_coef_RECT_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_RECT_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SC							

	smeared_RECT_SC := SmearedPolyRectSphere_SC(smear_coef_RECT_SC,$gQvals)		
	Display smeared_RECT_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyRectSphere_SC(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_RECT_SC
	form_RECT_SC[0] = 1
	form_RECT_SC[1] = w[1]
	form_RECT_SC[2] = w[2]
	form_RECT_SC[3] = w[3]
	form_RECT_SC[4] = 0
	
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
	struct_RECT_SC[1] = w[4]
	struct_RECT_SC[2] = w[0]
	struct_RECT_SC[3] = w[6]
	struct_RECT_SC[4] = w[5]
	struct_RECT_SC[5] = w[7]
	
	//calculate each and combine
	inten = PolyRectSpheres(form_RECT_SC,x)
	inten *= HayterPenfoldMSA(struct_RECT_SC,x)
	inten *= w[0]
	inten += w[8]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SC,struct_RECT_SC
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotPolyRectSphere_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_RECT_SHS,ywave_RECT_SHS
	xwave_RECT_SHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_RECT_SHS = {0.1,60,0.1,6e-6,0.05,0.2,0.0001}
	make/o/t parameters_RECT_SHS = {"volume fraction","avg radius(A)","polydispersity","contrast (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit/K=1 parameters_RECT_SHS,coef_RECT_SHS
	ywave_RECT_SHS := PolyRectSphere_SHS(coef_RECT_SHS,xwave_RECT_SHS)
	Display/K=1 ywave_RECT_SHS vs xwave_RECT_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedPolyRectSphere_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_RECT_SHS = {0.1,60,0.1,6e-6,0.05,0.2,0.0001}
	make/o/t smear_parameters_RECT_SHS = {"volume fraction","avg radius(A)","polydispersity","contrast (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1)"}
	Edit smear_parameters_RECT_SHS,smear_coef_RECT_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_RECT_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_RECT_SHS							

	smeared_RECT_SHS := SmearedPolyRectSphere_SHS(smear_coef_RECT_SHS,$gQvals)		
	Display smeared_RECT_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"

	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function PolyRectSphere_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
	Variable inten
	
	//setup form factor coefficient wave
	Make/O/D/N=5 form_RECT_SHS
	form_RECT_SHS[0] = 1
	form_RECT_SHS[1] = w[1]
	form_RECT_SHS[2] = w[2]
	form_RECT_SHS[3] = w[3]
	form_RECT_SHS[4] = 0
	
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
	struct_RECT_SHS[2] = w[4]
	struct_RECT_SHS[3] = w[5]
	
	//calculate each and combine
	inten = PolyRectSpheres(form_RECT_SHS,x)
	inten *= StickyHS_Struct(struct_RECT_SHS,x)
	inten *= w[0]
	inten += w[6]
	
	//cleanup waves
//	Killwaves/Z form_RECT_SHS,struct_RECT_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyRectSphere_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyRectSphere_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyRectSphere_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedPolyRectSphere_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyRectSphere_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End