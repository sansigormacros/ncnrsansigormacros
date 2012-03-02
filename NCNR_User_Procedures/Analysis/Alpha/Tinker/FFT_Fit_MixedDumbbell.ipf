#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
//
// This is a proof of principle to convert a structure built of spheres
// into a fitting function
//
////////////////////////////////////////////////

Proc PlotMixedDumbbellFFT(num,qmin,qmax)
	Variable num=100,qmin=0.004,qmax=0.4
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/D/n=(num) xwave_MixDumFFT,ywave_MixDumFFT
	xwave_MixDumFFT =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_MixDumFFT = {0.01,40,80,1e-6,3e-6,6e-6,0.0}
	make/o/t parameters_MixDumFFT = {"scale","Radius 1 (A)","Radius 2 (A)","SLD sphere 1 (A-2)","SLD sphere 2 (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit parameters_MixDumFFT,coef_MixDumFFT
	Variable/G root:g_MixDumFFT
	g_MixDumFFT := MixedDumbbellFFT(coef_MixDumFFT,ywave_MixDumFFT,xwave_MixDumFFT)

	Display ywave_MixDumFFT vs xwave_MixDumFFT
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("MixedDumbbellFFT","coef_MixDumFFT","parameters_MixDumFFT","MixDumFFT")
End

/////////////////////////////////////////////////////////////
//// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedMixedDumbbellFFT(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_MixDumFFT = {0.01,40,80,1e-6,3e-6,6e-6,0.0}
	make/o/t smear_parameters_MixDumFFT = {"scale","Radius 1 (A)","Radius 2 (A)","SLD sphere 1 (A-2)","SLD sphere 2 (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit smear_parameters_MixDumFFT,smear_coef_MixDumFFT
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_MixDumFFT,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_MixDumFFT	
					
	Variable/G gs_MixDumFFT=0
	gs_MixDumFFT := fSmearedMixedDumbbellFFT(smear_coef_MixDumFFT,smeared_MixDumFFT,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_MixDumFFT vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedMixedDumbbellFFT","smear_coef_MixDumFFT","smear_parameters_MixDumFFT","MixDumFFT")
End

// The calculation is inherently AAO, so it's all done here, not passed to another FitFunc
//
// not quite sure how to handle the SLDs yet, since I'm treating them as 1 or 2 digit integers
//
Function MixedDumbbellFFT(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

//The input variables are (and output)
	Variable scale,radius1,radius2,separation,number,delrho,bkg,edgeSeparation,rho1,rho2,rhos
	Variable ctr,fill1,fill2
				
	scale = cw[0]
	radius1 = cw[1]
	radius2 = cw[2]
	rho1 = cw[3]
	rho2 = cw[4]
	rhos = cw[5]
	bkg = cw[6]
	
	separation = radius1 + radius2		// edge contact
	number = 2			//fixed
	

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7

	
	FFT_SolventSLD = trunc(rhos/FFT_delRho)		//spits back an integer, maybe not correct

// generate the matrix and erase it
//	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	Wave m=root:mat

// fill the matrix with solvent
	FFTFillSolventMatrixProc("")

// with the input parameters, build the structure
	ctr = trunc(FFT_N/2)
	fill1 = trunc(rho1/FFT_delRho)
	fill2 = trunc(rho2/FFT_delRho)
	
	FillSphereRadius(m,FFT_T,radius1,ctr,ctr,ctr,fill1)
	FillSphereRadius(m,FFT_T,radius2,ctr+separation/FFT_T,ctr,ctr,fill2)
	
// set up for the calculation


// do the calculation (use the binned if only one SLD, or bin+SLD if the model requires this)
	fDoCalc(xw,yw,FFT_T,3,0)		//the binned SLD calculation

// reset the volume fraction to get the proper scaling
// the calculation is normalized to the volume fraction of spheres filling the matrix
	Variable frac
	frac = VolumeFraction_Occ(m)

	yw /= frac
	yw *= scale
	yw += bkg

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End


//
//// this is all there is to the smeared calculation!
Function SmearedMixedDumbbellFFT(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(MixedDumbbellFFT,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
//
//
////wrapper to calculate the smeared model as an AAO-Struct
//// fills the struct and calls the ususal function with the STRUCT parameter
////
//// used only for the dependency, not for fitting
////
Function fSmearedMixedDumbbellFFT(coefW,yW,xW)
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
	err = SmearedMixedDumbbellFFT(fs)
	
	return (0)
End

//Function MixTest()
//
//// make sure all of the globals are set correctly
//	NVAR FFT_T = root:FFT_T
//	NVAR FFT_N = root:FFT_N
//	NVAR FFT_SolventSLD = root:FFT_SolventSLD
//	
//	Variable rho1,rho2,rhos,radius1,radius2,ctr,separation,fill1,fill2
//	rho1=1e-6
//	rho2=3e-6
//	rhos=6e-6
//	
//	radius1 = 40
//	radius2 = 80
//	ctr=50
//	separation = radius1 + radius2
//	
//	FFT_SolventSLD = trunc(rhos*1e6)		//spits back an integer, maybe not correct
//
//// generate the matrix and erase it
////	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
//	Wave m=root:mat
//
//// fill the matrix with solvent
//	FFTFillSolventMatrixProc("")
//
//// with the input parameters, build the structure
//	ctr = trunc(FFT_N/2)
//	fill1 = trunc(rho1*1e6)
//	fill2 = trunc(rho2*1e6)
//	
//	FillSphereRadius(m,FFT_T,radius1,ctr,ctr,ctr,fill1)
//	FillSphereRadius(m,FFT_T,radius2,ctr+separation/FFT_T,ctr,ctr,fill2)
//	
//End
//
//Function CoreShellTest()
//
//// make sure all of the globals are set correctly
//	NVAR FFT_T = root:FFT_T
//	NVAR FFT_N = root:FFT_N
//	NVAR FFT_SolventSLD = root:FFT_SolventSLD
//	
//	Variable rho1,rho2,rhos,radius1,radius2,ctr,separation,fill1,fill2
//	rho1=1e-6
//	rho2=3e-6
//	rhos=6e-6
//	
////	rho1 += 3e-6
////	rho2 += 3e-6
////	rhos += 3e-6
//	
//	radius1 = 20
//	radius2 = 40
//	ctr=50
//	
//	FFT_SolventSLD = trunc(rhos*1e6)		//spits back an integer, maybe not correct
//
//// generate the matrix and erase it
////	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
//	Wave m=root:mat
//
//// fill the matrix with solvent
//	FFTFillSolventMatrixProc("")
//
//// with the input parameters, build the structure
//	ctr = trunc(FFT_N/2)
//	fill1 = trunc(rho1*1e6)
//	fill2 = trunc(rho2*1e6)
//	
//	FillSphereRadius(m,FFT_T,radius2,ctr,ctr,ctr,fill2)
//	FillSphereRadius(m,FFT_T,radius1,ctr,ctr,ctr,fill1)
//	
//End
//
//Function ThreeShellTest()
//
//// make sure all of the globals are set correctly
//	NVAR FFT_T = root:FFT_T
//	NVAR FFT_N = root:FFT_N
//	NVAR FFT_SolventSLD = root:FFT_SolventSLD
//	
//	Variable rcore,rhocore,thick1,rhoshel1,thick2,rhoshel2,thick3,rhoshel3,rhos,fill1,fill2,fill3,fillc,ctr
//	WAVE w=root:coef_ThreeShell
//	
//	rcore = w[1]
//	rhocore = w[2]
//	thick1 = w[3]
//	rhoshel1 = w[4]
//	thick2 = w[5]
//	rhoshel2 = w[6]
//	thick3 = w[7]
//	rhoshel3 = w[8]
//	rhos = w[9]
//	
////	rho1 += 3e-6
////	rho2 += 3e-6
////	rhos += 3e-6
//		
//	FFT_SolventSLD = trunc(rhos*1e6)		//spits back an integer, maybe not correct
//
//// generate the matrix and erase it
////	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
//	Wave m=root:mat
//
//// fill the matrix with solvent
//	FFTFillSolventMatrixProc("")
//
//// with the input parameters, build the structure
//	ctr = trunc(FFT_N/2)
//	fillc = trunc(rhocore*1e6)
//	fill1 = trunc(rhoshel1*1e6)
//	fill2 = trunc(rhoshel2*1e6)
//	fill3 = trunc(rhoshel3*1e6)
//	
//	FillSphereRadius(m,FFT_T,rcore+thick1+thick2+thick3,ctr,ctr,ctr,fill3)		//outer size (shell 3)
//	FillSphereRadius(m,FFT_T,rcore+thick1+thick2,ctr,ctr,ctr,fill2)		//outer size (shell 2)
//	FillSphereRadius(m,FFT_T,rcore+thick1,ctr,ctr,ctr,fill1)		//outer size (shell 1)
//	FillSphereRadius(m,FFT_T,rcore,ctr,ctr,ctr,fillc)		//core
//	
//End