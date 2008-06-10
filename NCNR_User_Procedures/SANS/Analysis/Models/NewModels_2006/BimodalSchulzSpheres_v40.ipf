#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// this model calculation is for the scattered intensity from a dispersion of polydisperse spheres
// hard sphere interactions are NOT included 
// the polydispersity in radius is a Schulz distribution
//
// TWO polulations of spheres are considered
//
// 31 DEC 03 SRK
////////////////////////////////////////////////
#include "SchulzSpheres_v40"

Proc PlotBimodalSchulzSpheres(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_bss,ywave_bss
	xwave_bss =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_bss = {0.01,200,0.2,1e-6,0.05,25,0.2,1e-6,6.4e-6,0.001}
	make/o/t/N=10 parameters_bss
	parameters_bss[0,3] = {"volume fraction(1)","Radius (1) (A)","polydispersity(1)","SLD(1) (A^-2)"}
	parameters_bss[4,9] = {"volume fraction(2)","Radius (2)","polydispersity(2)","SLD(2)","SLD (solvent)","background (cm-1 sr-1)"}
	Edit parameters_bss,coef_bss
	
	Variable/G root:g_bss
	g_bss := BimodalSchulzSpheres(coef_bss,ywave_bss,xwave_bss)
	Display ywave_bss vs xwave_bss
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("BimodalSchulzSpheres","coef_bss","bss")
End


///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedBimodalSchulzSpheres(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_bss = {0.01,200,0.2,1e-6,0.05,25,0.2,1e-6,6.4e-6,0.001}
	make/o/t/N=10 smear_parameters_bss
	smear_parameters_bss[0,3] = {"volume fraction(1)","Radius (1) (A)","polydispersity(1)","SLD(1) (A^-2)"}
	smear_parameters_bss[4,9] = {"volume fraction(2)","Radius (2)","polydispersity(2)","SLD(2)","SLD (solvent)","background (cm-1 sr-1)"}
	Edit smear_parameters_bss,smear_coef_bss
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_bss,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_bss
					
	Variable/G gs_bss=0
	gs_bss := fSmearedBimodalSchulzSpheres(smear_coef_bss,smeared_bss,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_bss vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedBimodalSchulzSpheres","smear_coef_bss","bss")
End
	

//  Calculates some characteristic parameters for bimodal Shulz distribution
Macro NumberDensity_Bimodal()

	Variable nden1,nden2,phi1,phi2,R1,R2,Ravg,p1,p2,Rg1,Rg2,I1_0,I2_0,I0,Sv1,Sv2,Sv,vpoly1,vpoly2
	Variable z1,z2,v2poly1,v2poly2
	
	if(Exists("coef_bss")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	phi1 = coef_bss[0]  // volume fraction, mode 1
	phi2 = coef_bss[4]  // volume fraction, mode 1
	R1 = coef_bss[1]  // mean radius, mode 1(A)
	R2 = coef_bss[5]  // mean radius, mode 1(A)
	p1 = coef_bss[2]  // polydispersity, mode 1
	p2 = coef_bss[6]  // polydispersity, mode 1
			
	z1 = (1/p1)^2-1
	z2 = (1/p2)^2-1
	//  average particle volume   	
	vpoly1 = 4*Pi/3*(z1+3)*(z1+2)/(z1+1)/(z1+1)*r1^3
	vpoly2 = 4*Pi/3*(z2+3)*(z2+2)/(z2+1)/(z2+1)*r2^3
	//average particle volume^2   	
	v2poly1 = (4*Pi/3)^2*(z1+6)*(z1+5)*(z1+4)*(z1+3)*(z1+2)/((z1+1)^5)*r1^6
	v2poly2 = (4*Pi/3)^2*(z2+6)*(z2+5)*(z2+4)*(z2+3)*(z2+2)/((z2+1)^5)*r2^6
	nden1 = phi1/vpoly1		//nden in 1/A^3
	nden2 = phi2/vpoly2		//nden in 1/A^3

	rg1 = r1*((3*(z1+8)*(z1+7))/5/(z1+1)/(z1+1))^0.5   // in A
	rg2 = r2*((3*(z2+8)*(z2+7))/5/(z2+1)/(z2+1))^0.5   // in A
	sv1 = 1.0e8*3*phi1*(z1+1)/R1/(z1+3)  // in 1/cm
	sv2 = 1.0e8*3*phi2*(z2+1)/R2/(z2+3)  // in 1/cm
	I1_0 = 1.0e8*nden1*v2poly1*(coef_bss[3]-coef_bss[8])^2  // 1/cm/sr
	I2_0 = 1.0e8*nden2*v2poly2*(coef_bss[7]-coef_bss[8])^2  // 1/cm/sr
	
	Print "mode 1 number density (A^-3) = ",nden1
	Print "mode 2 number density (A^-3) = ",nden2

	Ravg = (nden1*R1+nden2*R2)/(nden1+nden2)

	Print "mean radius, mode 1 (A) = ",R1
	Print "mean radius, mode 2 (A) = ",R2
	Print "mean radius, total     (A) = ",Ravg
	Print "polydispersity, mode 1 (sig/avg) = ",p1
	Print "polydispersity, mode 2 (sig/avg) = ",p2
	Print "volume fraction, mode 1 = ",phi1
	Print "volume fraction, mode 2 = ",phi2

	Print "Guinier Radius, mode 1 (A) = ",Rg1
	Print "Guinier Radius, mode 2 (A) = ",Rg2
	I0 = I1_0+I2_0
	Print "Forward scattering cross-section, mode 1 (cm-1 sr-1) I(0)= ",I1_0
	Print "Forward scattering cross-section, mode 2 (cm-1 sr-1) I(0)= ",I2_0
	Print "Forward scattering cross-section, total     (cm-1 sr-1) I(0)= ",I0
	Sv = Sv1+Sv2
	Print "Interfacial surface area per unit sample volume, mode 1 (cm-1) Sv= ",Sv1	
	Print "Interfacial surface area per unit sample volume, mode 2 (cm-1) Sv= ",Sv2	
	Print "Interfacial surface area per unit sample volume, total     (cm-1) Sv= ",Sv	
End


//   Plots bimodal size distribution
Macro Plot_Bimodal_Distribution()

	variable p1,p2,r1,r2,z1,z2,phi1,phi2,f1,f2,nden1,nden2,vpoly1,vpoly2,maxr
	
	if(Exists("coef_bss")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	phi1 = coef_bss[0]  // volume fraction, mode 1
	phi2 = coef_bss[4]  // volume fraction, mode 1
	R1 = coef_bss[1]  // mean radius, mode 1(A)
	R2 = coef_bss[5]  // mean radius, mode 1(A)
	p1 = coef_bss[2]  // polydispersity, mode 1
	p2 = coef_bss[6]  // polydispersity, mode 1
			
	z1 = (1/p1)^2-1
	z2 = (1/p2)^2-1
	//  average particle volume   	
	vpoly1 = 4*Pi/3*(z1+3)*(z1+2)/(z1+1)/(z1+1)*r1^3
	vpoly2 = 4*Pi/3*(z2+3)*(z2+2)/(z2+1)/(z2+1)*r2^3

	nden1 = phi1/vpoly1		//nden in 1/A^3
	nden2 = phi2/vpoly2		//nden in 1/A^3
	f1 = nden1/(nden1+nden2)
	f2 = nden2/(nden1+nden2)

	Make/O/D/N=1000 Bimodal_Schulz_distribution
	if (r1>r2) then
	   maxr =  r1*(1+6*p1)
	else
	   maxr =  r2*(1+6*p2)
	endif

	SetScale/I x, 0, maxr, Bimodal_Schulz_distribution
	Bimodal_Schulz_distribution = f1*Schulz_Point_bss(x,r1,z1)+f2*Schulz_Point_bss(x,r2,z2)
	Display Bimodal_Schulz_distribution
	Label left "f(R) (normalized)"
	Label bottom "R (A)"
	legend
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
// now AAO function
Function BimodalSchulzSpheres(w,yw,xw) : FitFunc
	Wave w,yw,xw			// the coefficient wave, y, x

	Variable ans=0
	Make/O/D/N=6 temp_coef_1,temp_coef_2		//coefficient waves for each population
	temp_coef_1[0] = w[0]
	temp_coef_1[1] = w[1]
	temp_coef_1[2] = w[2]
	temp_coef_1[3] = w[3]
	temp_coef_1[4] = w[8]
	temp_coef_1[5] = 0

//second population
	temp_coef_2[0] = w[4]
	temp_coef_2[1] = w[5]
	temp_coef_2[2] = w[6]
	temp_coef_2[3] = w[7]
	temp_coef_2[4] = w[8]
	temp_coef_2[5] = 0		//always zero - background is added in the final step
	
	//calculate both models and sum (add background here)
	Duplicate/O xw tmp_ss1,tmp_ss2
	SchulzSpheres(temp_coef_1,tmp_ss1,xw)
	SchulzSpheres(temp_coef_2,tmp_ss2,xw)
	yw = tmp_ss1 + tmp_ss2
	yw += w[9]		//background
	
	return(0)
End

Function Schulz_Point_bss(x,avg,zz)
	Variable x,avg,zz
	
	Variable dr
	
	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
	return (exp(dr))
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedBimodalSchulzSpheres(coefW,yW,xW)
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
	err = SmearedBimodalSchulzSpheres(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedBimodalSchulzSpheres(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(BimodalSchulzSpheres,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	


