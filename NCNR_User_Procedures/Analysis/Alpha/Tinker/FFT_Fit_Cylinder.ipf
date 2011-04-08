#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
//
// This is a proof of principle to convert a structure built of spheres
// into a fitting function
//
////////////////////////////////////////////////

Proc PlotCylinderFFT(num,qmin,qmax)
	Variable num=100,qmin=0.004,qmax=0.4
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/o/D/n=(num) xwave_cylFFT,ywave_cylFFT
	xwave_cylFFT =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_cylFFT = {1.,20.,400,1e-6,6.3e-6,0.01}
	make/o/t parameters_cylFFT = {"scale","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_cylFFT,coef_cylFFT
	Variable/G root:g_cylFFT
	g_cylFFT := CylinderFFT(coef_cylFFT,ywave_cylFFT,xwave_cylFFT)

	Display ywave_cylFFT vs xwave_cylFFT
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("CylinderFFT","coef_cylFFT","parameters_cylFFT","cylFFT")
End

/////////////////////////////////////////////////////////////
//// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinderFFT(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_cylFFT = {1.,20.,400,1e-6,6.3e-6,0.01}
	make/o/t smear_parameters_cylFFT = {"scale","radius (A)","length (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_cylFFT,smear_coef_cylFFT
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_cylFFT,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_cylFFT	
					
	Variable/G gs_cylFFT=0
	gs_cylFFT := fSmearedCylinderFFT(smear_coef_cylFFT,smeared_cylFFT,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_cylFFT vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinderFFT","smear_coef_cylFFT","smear_parameters_cylFFT","cylFFT")
End

// The calculation is inherently AAO, so it's all done here, not passed to another FitFunc
//
// not quite sure how to handle the SLDs yet, since I'm treating them as 1 or 2 digit integers
//
Function CylinderFFT(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

//The input variables are (and output)
	//[0] scale
	//[1] cylinder RADIUS (A)
	//[2] total cylinder LENGTH (A)
	//[3] sld cylinder (A^-2)
	//[4] sld solvent
	//[5] background (cm^-1)
	Variable scale, radius,length,delrho,bkg,sldCyl,sldSolv,ctr,fill
	scale = cw[0]
	radius = cw[1]
	length = cw[2]
	sldCyl = cw[3]
	sldSolv = cw[4]
	bkg = cw[5]


// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	
	FFT_SolventSLD = trunc(sldSolv*1e6)		//spits back an integer, maybe not correct

// generate the matrix and erase it
//	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	Wave m=root:mat

// fill the matrix with solvent
	FFTFillSolventMatrixProc("")

// with the input parameters, build the structure
	ctr = trunc(FFT_N/2)
	fill = trunc(sldCyl*1e6)
	
	FillXCylinder(m,FFT_T,radius,ctr,ctr,ctr,length,fill)

// set up for the calculation


// do the calculation (use the binned if only one SLD, or bin+SLD if the model requires this)
	fDoCalc(xw,yw,FFT_T,2,0)		//the binned calculation

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
Function SmearedCylinderFFT(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(CylinderFFT,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
//
//
////wrapper to calculate the smeared model as an AAO-Struct
//// fills the struct and calls the ususal function with the STRUCT parameter
////
//// used only for the dependency, not for fitting
////
Function fSmearedCylinderFFT(coefW,yW,xW)
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
	err = SmearedCylinderFFT(fs)
	
	return (0)
End