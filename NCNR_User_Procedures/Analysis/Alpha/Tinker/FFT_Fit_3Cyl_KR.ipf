#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

////////////////////////////////////////////////
//
// This is a proof of principle to convert a structure built of spheres
// into a fitting function
//
////////////////////////////////////////////////

Proc PlotThreeCylKR(num,qmin,qmax)
	Variable num=100,qmin=0.004,qmax=0.4
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	
	// make the needed waves, three rows for this case
	Make/O/D/N=3 xCtr_KR,yCtr_KR,zCtr_KR,rad_KR,len_KR,sph_KR,rotx_KR,roty_KR,SLD_KR
	
	make/o/D/n=(num) xwave_c3KR,ywave_c3KR
	xwave_c3KR =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/D coef_c3KR = {0.01,40,32,26,34,26,34,1e-6,2e-6,0.01}
	make/o/t parameters_c3KR = {"scale","radius 1 (A)","length 1 (A)","radius 2 (A)","length 2 (A)","radius 3 (A)","length 3 (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit parameters_c3KR,coef_c3KR
	Variable/G root:g_c3KR
	g_c3KR := ThreeCylKR(coef_c3KR,ywave_c3KR,xwave_c3KR)

	Display ywave_c3KR vs xwave_c3KR
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("ThreeCylKR","coef_c3KR","parameters_c3KR","c3KR")
End

/////////////////////////////////////////////////////////////
//// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedThreeCylKR(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	// make the needed waves, three rows for this case
	Make/O/D/N=3 xCtr_KR,yCtr_KR,zCtr_KR,rad_KR,len_KR,sph_KR,rotx_KR,roty_KR,SLD_KR
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/o/D smear_coef_c3KR = {0.01,40,32,26,34,26,34,1e-6,2e-6,0.01}
	make/o/t smear_parameters_c3KR = {"scale","radius 1 (A)","length 1 (A)","radius 2 (A)","length 2 (A)","radius 3 (A)","length 3 (A)","SLD cylinder (A^-2)","SLD solvent (A^-2)","incoh. bkg (cm^-1)"}
	Edit smear_parameters_c3KR,smear_coef_c3KR
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_c3KR,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_c3KR	
					
	Variable/G gs_c3KR=0
	gs_c3KR := fSmearedThreeCylKR(smear_coef_c3KR,smeared_c3KR,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_c3KR vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedThreeCylKR","smear_coef_c3KR","smear_parameters_c3KR","c3KR")
End

// The calculation is inherently AAO, so it's all done here, not passed to another FitFunc
//
// not quite sure how to handle the SLDs yet, since I'm treating them as 1 or 2 digit integers
//
Function ThreeCylKR(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

//	Variable t1=StopMSTimer(-2)

//The input variables are (and output)
	//[0] scale
	//[1] cylinder RADIUS (A)
	//[2] total cylinder LENGTH (A)
	//[3] sld cylinder (A^-2)
	//[4] sld solvent
	//[5] background (cm^-1)
	Variable scale,delrho,bkg,sldCyl,sldSolv,ctr,fill
	Variable r0,r1,r2,l0,l1,l2
	scale = cw[0]
	r0 = cw[1]
	l0 = cw[2]
	r1 = cw[3]
	l1 = cw[4]
	r2 = cw[5]
	l2 = cw[6]
	sldCyl = cw[7]
	sldSolv = cw[8]
	bkg = cw[9]


// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	
	FFT_SolventSLD = trunc(sldSolv*1e6)		//spits back an integer, maybe not correct

// generate the matrix and erase it
//	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
//	Wave m=root:mat

// fill the matrix with solvent
//	FFTFillSolventMatrixProc("")

	// waves to pass to parsing routine
	WAVE xCtr_KR=root:xCtr_KR
	WAVE yCtr_KR=root:yCtr_KR
	WAVE zCtr_KR=root:zCtr_KR
	WAVE rad_KR=root:rad_KR
	WAVE len_KR=root:len_KR
	WAVE sph_KR=root:sph_KR
	WAVE rotx_KR=root:rotx_KR
	WAVE roty_KR=root:roty_KR
	WAVE SLD_KR=root:SLD_KR



// with the input parameters, build the structure
// the first cylinder is at 0,0,0
// the second cylinder is on "top" (Z)
// the third cylinder is on the "bottom" (-Z)
	xCtr_KR[0] = 0
	yCtr_KR[0] = 0
	zCtr_KR[0] = 0
	rad_KR[0] = r0
	len_KR[0] = l0

	xCtr_KR[1] = 0
	yCtr_KR[1] = 0
	zCtr_KR[1] = l0/2 + l1/2
	rad_KR[1] = r1
	len_KR[1] = l1
	
	xCtr_KR[2] = 0
	yCtr_KR[2] = 0
	zCtr_KR[2] = -(l0/2 + l2/2)
	rad_KR[2] = r2
	len_KR[2] = l2
	
	//no rotation here, only one SLD
	sph_KR = FFT_T		//use the global
	rotx_KR = 0
	roty_KR = 0
	SLD_KR = trunc(sldCyl*1e6)
	


// this parses the information and generates xoutW, youtW, zoutW, sldW in the root folder
	KR_MultiCylinder(xCtr_KR,yCtr_KR,zCtr_KR,rad_KR,len_KR,sph_KR,rotx_KR,roty_KR,SLD_KR)
	
	
	// these are really just for display, or if the FFT of mat is wanted later.
	WAVE xoutW=root:xoutW
	WAVE youtW=root:youtW
	WAVE zoutW=root:zoutW
	WAVE sldW=root:sldW
		
	XYZV_FillMat(xoutW,youtW,ZoutW,sldW,1)			//last 1 will erase the matrix
	MakeTriplet(xoutW,youtW,zoutW)



// do the calculation (use the binned if only one SLD, or bin+SLD if the model requires this)
	fDoCalc(xw,yw,FFT_T,12,0)		//the binned calculation

// reset the volume fraction to get the proper scaling
// the calculation is normalized to the volume fraction of spheres filling the matrix
	Variable frac
	Wave m=root:mat

	frac = VolumeFraction_Occ(m)

	yw /= frac
	yw *= scale
	yw += bkg

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6

	return(0)
End


//
//// this is all there is to the smeared calculation!
Function SmearedThreeCylKR(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(ThreeCylKR,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
//
//
////wrapper to calculate the smeared model as an AAO-Struct
//// fills the struct and calls the ususal function with the STRUCT parameter
////
//// used only for the dependency, not for fitting
////
Function fSmearedThreeCylKR(coefW,yW,xW)
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
	err = SmearedThreeCylKR(fs)
	
	return (0)
End