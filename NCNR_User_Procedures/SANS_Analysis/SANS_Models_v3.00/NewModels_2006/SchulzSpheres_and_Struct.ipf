#pragma rtGlobals=1		// Use modern global access method.
//
// be sure to include all of the necessary files
//
#include "SchulzSpheres"

#include "HardSphereStruct"
#include "HPMSA"
#include "SquareWellStruct"
#include "StickyHardSphereStruct"

Proc PlotSchulzSpheres_HS(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_HS,ywave_sch_HS
	xwave_sch_HS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_HS = {0.01,60,0.2,1e-6,3e-6,0.001}
	make/O/T parameters_sch_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_sch_HS,coef_sch_HS
	ywave_sch_HS := SchulzSpheres_HS(coef_sch_HS,xwave_sch_HS)
	Display ywave_sch_HS vs xwave_sch_HS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSchulzSpheres_HS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_HS = {0.01,60,0.2,1e-6,3e-6,0.001}					
	make/o/t smear_parameters_sch_HS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_HS,smear_coef_sch_HS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sch_HS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_HS							

	smeared_sch_HS := SmearedSchulzSpheres_HS(smear_coef_sch_HS,$gQvals)		
	Display smeared_sch_HS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function SchulzSpheres_HS(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = SchulzSpheres(form_sch_HS,x)
	inten *= HardSphereStruct(struct_sch_HS,x)
	inten *= w[0]
	inten += w[5]
	
	//cleanup waves
//	Killwaves/Z form_sch_HS,struct_sch_HS
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotSchulzSpheres_SW(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_SW,ywave_sch_SW
	xwave_sch_SW = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}
	make/O/T parameters_sch_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SW,coef_sch_SW
	ywave_sch_SW := SchulzSpheres_SW(coef_sch_SW,xwave_sch_SW)
	Display ywave_sch_SW vs xwave_sch_SW
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSchulzSpheres_SW()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_SW = {0.01,60,0.2,1e-6,3e-6,1.0,1.2,0.001}					
	make/o/t smear_parameters_sch_SW = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","well depth (kT)","well width (diam.)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SW,smear_coef_sch_SW					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sch_SW,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SW							

	smeared_sch_SW := SmearedSchulzSpheres_SW(smear_coef_sch_SW,$gQvals)		
	Display smeared_sch_SW vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function SchulzSpheres_SW(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = SchulzSpheres(form_sch_SW,x)
	inten *= SquareWellStruct(struct_sch_SW,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_sch_SW,struct_sch_SW
	
	return (inten)
End


/////////////////////////////////////////
Proc PlotSchulzSpheres_SC(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	if (DataFolderExists("root:HayPenMSA"))
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
 	else
 		NewDataFolder root:HayPenMSA
 		Make/O/D/N=17 root:HayPenMSA:gMSAWave
	endif

	Make/O/D/N=(num) xwave_sch_SC,ywave_sch_SC
	xwave_sch_SC = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}
	make/O/T parameters_sch_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SC,coef_sch_SC
	ywave_sch_SC := SchulzSpheres_SC(coef_sch_SC,xwave_sch_SC)
	Display ywave_sch_SC vs xwave_sch_SC
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSchulzSpheres_SC()								
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
	Make/O/D smear_coef_sch_SC = {0.01,60,0.2,1e-6,3e-6,20,0,298,78,0.001}					
	make/o/t smear_parameters_sch_SC = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","charge","movalent salt(M)","Temperature (K)","dielectric const","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SC,smear_coef_sch_SC					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sch_SC,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SC							

	smeared_sch_SC := SmearedSchulzSpheres_SC(smear_coef_sch_SC,$gQvals)		
	Display smeared_sch_SC vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function SchulzSpheres_SC(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = SchulzSpheres(form_sch_SC,x)
	inten *= HayterPenfoldMSA(struct_sch_SC,x)
	inten *= w[0]
	inten += w[9]
	
	//cleanup waves
//	Killwaves/Z form_sch_SC,struct_sch_SC
	
	return (inten)
End

/////////////////////////////////////////
Proc PlotSchulzSpheres_SHS(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/N=(num) xwave_sch_SHS,ywave_sch_SHS
	xwave_sch_SHS = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_sch_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}
	make/O/T parameters_sch_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}
	Edit parameters_sch_SHS,coef_sch_SHS
	ywave_sch_SHS := SchulzSpheres_SHS(coef_sch_SHS,xwave_sch_SHS)
	Display ywave_sch_SHS vs xwave_sch_SHS
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedSchulzSpheres_SHS()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sch_SHS = {0.01,60,0.2,1e-6,3e-6,0.05,0.2,0.001}					
	make/o/t smear_parameters_sch_SHS = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","perturbation parameter (0.1)","stickiness, tau","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_sch_SHS,smear_coef_sch_SHS					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sch_SHS,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sch_SHS							

	smeared_sch_SHS := SmearedSchulzSpheres_SHS(smear_coef_sch_SHS,$gQvals)		
	Display smeared_sch_SHS vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Function SchulzSpheres_SHS(w,x) : FitFunc
	Wave w
	Variable x
	
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
	inten = SchulzSpheres(form_sch_SHS,x)
	inten *= StickyHS_Struct(struct_sch_SHS,x)
	inten *= w[0]
	inten += w[7]
	
	//cleanup waves
//	Killwaves/Z form_sch_SHS,struct_sch_SHS
	
	return (inten)
End



// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_HS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(SchulzSpheres_HS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SW(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(SchulzSpheres_SW,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SC(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(SchulzSpheres_SC,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

// this is all there is to the smeared calculation!
Function SmearedSchulzSpheres_SHS(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(SchulzSpheres_SHS,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End