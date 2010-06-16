#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
// The plotting macro sets up TWO dependencies
// - one for the triplet calculation
// - one for a matrix to display, a copy of the triplet
//
// For display, there are two copies of the matrix. One matrix is linear, and is a copy of the 
// triplet (which is ALWAYS linear). The other matrix is toggled log/lin for display
// in the same way the 2D SANS data matrix is handled.
//

///  REQUIRES XOP for 2D FUNCTIONS

//
// the calculation is done as for the QxQy data set:
// three waves XYZ, then converted to a matrix
//
Proc PlotPeakGauss2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	SetDataFolder $("root:"+str)
	
	Make/O/D coef_pkGau2D = {100.0, 0.25,0.005, 1.0}						
	make/o/t parameters_pkGau2D = {"Scale Factor, I0 ", "Peak position (A^-1)", "Std Dev (A^-1)","Incoherent Bgd (cm-1)"}		
	Edit parameters_pkGau2D,coef_pkGau2D				
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_pkGau2D
	Duplicate/O $(str+"_qy") ywave_pkGau2D,zwave_pkGau2D			
		
	Variable/G g_pkGau2D=0
	g_pkGau2D := PeakGauss2D(coef_pkGau2D,zwave_pkGau2D,xwave_pkGau2D,ywave_pkGau2D)	//AAO 2D calculation
	
	Display ywave_pkGau2D vs xwave_pkGau2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_pkGau2D)={zwave_pkGau2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_pkGau2D,ywave_pkGau2D,zwave_pkGau2D,"pkGau2D_mat")
	Duplicate/O $"pkGau2D_mat",$"pkGau2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_pkGau2Dmat=0
	g_pkGau2Dmat := UpdateQxQy2Mat(xwave_pkGau2D,ywave_pkGau2D,zwave_pkGau2D,pkGau2D_lin,pkGau2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("PeakGauss2D","coef_pkGau2D","parameters_pkGau2D","pkGau2D")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPeakGauss2D(str)								
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
//	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
//		Abort
//	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pkGau2D = {100.0, 0.25,0.005, 1.0}					
	make/o/t smear_parameters_pkGau2D = {"Scale Factor, I0 ", "Peak position (A^-1)", "Std Dev (A^-1)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_pkGau2D,smear_coef_pkGau2D					
	
	Duplicate/O $(str+"_qx") smeared_pkGau2D	//1d place for the smeared model
	SetScale d,0,0,"1/cm",smeared_pkGau2D					
		
	Variable/G gs_pkGau2D=0
	gs_pkGau2D := fSmearedPeakGauss2D(smear_coef_pkGau2D,smeared_pkGau2D)	//this wrapper fills the STRUCT

	Display $(str+"_qy") vs $(str+"_qx")
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor($(str+"_qy"))={smeared_pkGau2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	Duplicate/O $(str+"_qx"), sm_qx
	Duplicate/O $(str+"_qy"), sm_qy		// I can't use local variables in dependencies, so I need the name (that I can't get)
	
	ConvertQxQy2Mat(sm_qx,sm_qy,smeared_pkGau2D,"sm_pkGau2D_mat")
	Duplicate/O $"sm_pkGau2D_mat",$"sm_pkGau2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G gs_pkGau2Dmat=0
	gs_pkGau2Dmat := UpdateQxQy2Mat(sm_qx,sm_qy,smeared_pkGau2D,sm_pkGau2D_lin,sm_pkGau2D_mat)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPeakGauss2D","smear_coef_pkGau2D","smear_parameters_pkGau2D","pkGau2D")
End


//threaded version of the function
ThreadSafe Function PeakGauss2D_T(cw,zw,xw,yw,p1,p2)
	WAVE cw,zw,xw,yw
	Variable p1,p2
	
#if exists("PeakGauss2DX")			//to hide the function if XOP not installed
	
	zw[p1,p2]= PeakGauss2DX(cw,xw,yw)

#else
	zw[p1,p2] =  I_PeakGauss2D(cw,xw,yw)
#endif

	return 0
End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// not used
//
Function PeakGauss2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw
	
	Variable npt=numpnts(yw)
	Variable i,nthreads= ThreadProcessorCount
	variable mt= ThreadGroupCreate(nthreads)

//	Variable t1=StopMSTimer(-2)
	
	for(i=0;i<nthreads;i+=1)
	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
		ThreadStart mt,i,PeakGauss2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
	endfor

	do
		variable tgs= ThreadGroupWait(mt,100)
	while( tgs != 0 )

	variable dummy= ThreadGroupRelease(mt)
	
//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
End


//non-threaded version of the function
ThreadSafe Function PeakGauss2D_noThread(cw,zw,xw,yw)
	WAVE cw,zw, xw,yw
	
#if exists("PeakGauss2DX")			//to hide the function if XOP not installed
	zw= PeakGauss2DX(cw,xw,yw)
#else
	zw = I_PeakGauss2D(cw,xw,yw)
#endif

	return 0
End

// I think I did this because when I do the quadrature loops I'm calling the AAO with 1-pt waves, so threading
// would just be a slowdown
Function SmearedPeakGauss2D(s)
	Struct ResSmear_2D_AAOStruct &s
	
	//no threads
//	Smear_2DModel_PP(PeakGauss2D_noThread,s,10)

	//or threaded...
	SmearPeakGauss2D_THR(s,10)
	
	return(0)
end


Function fSmearedPeakGauss2D(coefW,resultW)
	Wave coefW,resultW
	
	String str = getWavesDataFolder(resultW,0)
	String DF="root:"+str+":"
	
	WAVE qx = $(DF+str+"_qx")
	WAVE qy = $(DF+str+"_qy")
	WAVE qz = $(DF+str+"_qz")
	WAVE sQpl = $(DF+str+"_sQpl")
	WAVE sQpp = $(DF+str+"_sQpp")
	WAVE shad = $(DF+str+"_fs")
	
	STRUCT ResSmear_2D_AAOStruct s
	WAVE s.coefW = coefW	
	WAVE s.zw = resultW	
	WAVE s.xw[0] = qx
	WAVE s.xw[1] = qy
	WAVE s.qz = qz
	WAVE s.sQpl = sQpl
	WAVE s.sQpp = sQpp
	WAVE s.fs = shad
	
	Variable err
	err = SmearedPeakGauss2D(s)
	
	return (0)
End

ThreadSafe Function I_PeakGauss2D(w,x,y)
	Wave w
	Variable x,y
	
	Variable retVal,qval
	qval = sqrt(x^2+y^2)
		
	retval = Peak_Gauss_modelX(w,qval)
//	retval = fPeak_Gauss_model(w,qval)
	
	return(retVal)
End

///////////////
//
// this is the threaded version, that dispatches the calculation out to threads
//
// must be written specific to each 2D function
// 
Function SmearPeakGauss2D_THR(s,nord)
	Struct ResSmear_2D_AAOStruct &s
	Variable nord
	
	String weightStr,zStr
	
// create all of the necessary quadrature waves here - rather than inside a threadsafe function
	switch(nord)	
		case 5:		
			weightStr="gauss5wt"
			zStr="gauss5z"
			if (WaveExists($weightStr) == 0)
				Make/O/D/N=(nord) $weightStr,$zStr
				Make5GaussPoints($weightStr,$zStr)	
			endif
			break				
		case 10:		
			weightStr="gauss10wt"
			zStr="gauss10z"
			if (WaveExists($weightStr) == 0)
				Make/O/D/N=(nord) $weightStr,$zStr
				Make10GaussPoints($weightStr,$zStr)	
			endif
			break				
		case 20:		
			weightStr="gauss20wt"
			zStr="gauss20z"
			if (WaveExists($weightStr) == 0)
				Make/O/D/N=(nord) $weightStr,$zStr
				Make20GaussPoints($weightStr,$zStr)	
			endif
			break
		default:							
			Abort "Smear_2DModel_PP_Threaded called with invalid nord value"					
	endswitch
	
	Wave/Z wt = $weightStr
	Wave/Z xi = $zStr		// wave references to pass

	Variable npt=numpnts(s.xw[0])
	Variable i,nthreads= ThreadProcessorCount
	variable mt= ThreadGroupCreate(nthreads)

	Variable t1=StopMSTimer(-2)
	
	for(i=0;i<nthreads;i+=1)
	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
		ThreadStart mt,i,SmearPeakGauss2D_T(s.coefW,s.xw[0],s.xw[1],s.qz,s.sQpl,s.sQpp,s.fs,s.zw,wt,xi,(i*npt/nthreads),((i+1)*npt/nthreads-1),nord)
	endfor

	do
		variable tgs= ThreadGroupWait(mt,100)
	while( tgs != 0 )

	variable dummy= ThreadGroupRelease(mt)
	
// comment out the threading + uncomment this for testing to make sure that the single thread works
//	nThreads=1
//	SmearSphere2D_T(s.coefW,s.xw[0],s.xw[1],s.qz,s.sQpl,s.sQpp,s.fs,s.zw,wt,xi,(i*npt/nthreads),((i+1)*npt/nthreads-1),nord)

	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
end

//
// - worker function for threads of PeakGauss2D
//
ThreadSafe Function SmearPeakGauss2D_T(coef,qxw,qyw,qzw,sxw,syw,fsw,zw,wt,xi,pt1,pt2,nord)
	WAVE coef,qxw,qyw,qzw,sxw,syw,fsw,zw,wt,xi
	Variable pt1,pt2,nord
	
// now passed in....
//	Wave wt = $weightStr
//	Wave xi = $zStr		

	Variable ii,jj,kk,num
	Variable qx,qy,qz,qval,sx,sy,fs
	Variable qy_pt,qx_pt,res_x,res_y,answer,sumIn,sumOut
	
	Variable normFactor,phi,theta,maxSig,numStdDev=3
	
/// keep these waves local
	Make/O/D/N=(nord) fcnRet,xptW,res_tot,yptW
	
	// now just loop over the points as specified
	
	answer=0
	
	Variable spl,spp,apl,app,bpl,bpp,phi_pt,qpl_pt

	//loop over q-values
	for(ii=pt1;ii<(pt2+1);ii+=1)
		
		qx = qxw[ii]
		qy = qyw[ii]
		qz = qzw[ii]
		qval = sqrt(qx^2+qy^2+qz^2)
		spl = sxw[ii]
		spp = syw[ii]
		fs = fsw[ii]
		
		normFactor = 2*pi*spl*spp
		
		phi = FindPhi(qx,qy)
		
		apl = -numStdDev*spl + qval		//parallel = q integration limits
		bpl = numStdDev*spl + qval
		app = -numStdDev*spp + phi		//perpendicular = phi integration limits
		bpp = numStdDev*spp + phi
		
		//make sure the limits are reasonable.
		if(apl < 0)
			apl = 0
		endif
		// do I need to specially handle limits when phi ~ 0?
	
		
		sumOut = 0
		for(jj=0;jj<nord;jj+=1)		// call phi the "outer'
			phi_pt = (xi[jj]*(bpp-app)+app+bpp)/2

			sumIn=0
			for(kk=0;kk<nord;kk+=1)		//at phi, integrate over Qpl

				qpl_pt = (xi[kk]*(bpl-apl)+apl+bpl)/2
				
				FindQxQy(qpl_pt,phi_pt,qx_pt,qy_pt)		//find the corresponding QxQy to the Q,phi
				yPtw[kk] = qy_pt					//phi is the same in this loop, but qy is not
				xPtW[kk] = qx_pt					//qx is different here too, as we're varying Qpl
				
				res_tot[kk] = exp(-0.5*( (qpl_pt-qval)^2/spl/spl + (phi_pt-phi)^2/spp/spp ) )
				res_tot[kk] /= normFactor
//				res_tot[kk] *= fs

			endfor
			
			PeakGauss2D_noThread(coef,fcnRet,xptw,yptw)			//fcn passed in is an AAO
			
			//sumIn += wt[jj]*wt[kk]*res_tot*fcnRet[0]
			fcnRet *= wt[jj]*wt*res_tot
			//
			answer += (bpl-apl)/2.0*sum(fcnRet)		//
		endfor

		answer *= (bpp-app)/2.0
		zw[ii] = answer
	endfor
	
	return(0)
end

