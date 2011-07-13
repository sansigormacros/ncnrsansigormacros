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
Proc PlotSphere2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	SetDataFolder $("root:"+str)
	
	Make/O/D coef_sf2D = {1.,60,1e-6,6.3e-6,0.01}						
	make/o/t parameters_sf2D = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent","bkgd (cm-1)"}		
	Edit parameters_sf2D,coef_sf2D				
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_sf2D
	Duplicate/O $(str+"_qy") ywave_sf2D,zwave_sf2D			
		
	Variable/G g_sf2D=0
	g_sf2D := Sphere2D(coef_sf2D,zwave_sf2D,xwave_sf2D,ywave_sf2D)	//AAO 2D calculation
	
	Display ywave_sf2D vs xwave_sf2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_sf2D)={zwave_sf2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_sf2D,ywave_sf2D,zwave_sf2D,"sf2D_mat")
	Duplicate/O $"sf2D_mat",$"sf2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_sf2Dmat=0
	g_sf2Dmat := UpdateQxQy2Mat(xwave_sf2D,ywave_sf2D,zwave_sf2D,sf2D_lin,sf2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Sphere2D","coef_sf2D","parameters_sf2D","sf2D")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphere2D(str)								
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
//	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
//		Abort
//	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sf2D = {1.,60,1e-6,6.3e-6,0.01}					
	make/o/t smear_parameters_sf2D = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit smear_parameters_sf2D,smear_coef_sf2D					
	
	Duplicate/O $(str+"_qx") smeared_sf2D	//1d place for the smeared model
	SetScale d,0,0,"1/cm",smeared_sf2D					
		
	Variable/G gs_sf2D=0
	gs_sf2D := fSmearedSphere2D(smear_coef_sf2D,smeared_sf2D)	//this wrapper fills the STRUCT

	Display $(str+"_qy") vs $(str+"_qx")
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor($(str+"_qy"))={smeared_sf2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	Duplicate/O $(str+"_qx"), sm_qx
	Duplicate/O $(str+"_qy"), sm_qy		// I can't use local variables in dependencies, so I need the name (that I can't get)
	
	ConvertQxQy2Mat(sm_qx,sm_qy,smeared_sf2D,"sm_sf2D_mat")
	Duplicate/O $"sm_sf2D_mat",$"sm_sf2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G gs_sf2Dmat=0
	gs_sf2Dmat := UpdateQxQy2Mat(sm_qx,sm_qy,smeared_sf2D,sm_sf2D_lin,sm_sf2D_mat)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphere2D","smear_coef_sf2D","smear_parameters_sf2D","sf2D")
End

//
//  Fit function that is actually a wrapper to dispatch the calculation to N threads
//
// nthreads is 1 or an even number, typically 2
// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
//
Function Sphere2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw

#if exists("Sphere_2DX")			//to hide the function if XOP not installed
	MultiThread 	zw= Sphere_2DX(cw,xw,yw)
#endif

	return(0)
End


///
//// keep this section as an example
//

//	Variable npt=numpnts(yw)
//	Variable i,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
////	Variable t1=StopMSTimer(-2)
//	
//	for(i=0;i<nthreads;i+=1)
//	//	Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
//		ThreadStart mt,i,Sphere2D_T(cw,zw,xw,yw,(i*npt/nthreads),((i+1)*npt/nthreads-1))
//	endfor
//
//	do
//		variable tgs= ThreadGroupWait(mt,100)
//	while( tgs != 0 )
//
//	variable dummy= ThreadGroupRelease(mt)
//	
////	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
//	
//
////// end example of threading



//threaded version of the function
//ThreadSafe Function Sphere2D_T(cw,zw,xw,yw,p1,p2)
//	WAVE cw,zw,xw,yw
//	Variable p1,p2
//	
//#if exists("Sphere_2DX")			//to hide the function if XOP not installed
//	
//	zw[p1,p2]= Sphere_2DX(cw,xw,yw)
//
//#endif
//
//	return 0
//End


//non-threaded version of the function, necessary for the smearing calculation
// -- the smearing calculation can only calculate (nord) points at a time.
//
ThreadSafe Function Sphere2D_noThread(cw,zw,xw,yw)
	WAVE cw,zw, xw,yw
	
#if exists("Sphere_2DX")			//to hide the function if XOP not installed
	zw= Sphere_2DX(cw,xw,yw)
#endif

	return 0
End



//// the threaded version must be specifically written, since
//// FUNCREF can't be passed into  a threaded calc (structures can't be passed either)
// so in this implementation, the smearing is dispatched as threads to a function that
// can calculate the function for a range of points in the input qxqyqz. It is important
// that the worker calls the un-threaded model function (so write one) and that in the (nord x nord)
// loop, vectors of length (nord) are calculated rather than pointwise, since the model
// function is AAO.
// -- makes things rather messy to code individual functions, but I really see no other way
// given the restrictions of what can be passed to threaded functions.
//
//
// The smearing is handled this way since 1D smearing is 20 x 200 pts = 4000 evaluations
// and the 2D is (10 x 10) x 16000 pts = 1,600,000 evaluations (if it's done like the 1D, it's 4000x slower)
//
//
// - the threading gives a clean speedup of 2 for N=2, even for this simple calculation
//  -- 4.8X speedup for N=8 (4 real cores + 4 virtual cores)
//
// nord = 5,10,20 allowed
//
Function SmearedSphere2D(s)
	Struct ResSmear_2D_AAOStruct &s
	
//// non-threaded, but generic calculation
//// the last param is nord	
//	Smear_2DModel_PP(Sphere2D_noThread,s,10)


//// the last param is nord
	SmearedSphere2D_THR(s,10)		

	return(0)
end


Function fSmearedSphere2D(coefW,resultW)
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
	err = SmearedSphere2D(s)
	
	return (0)
End




//
// this is the threaded version, that dispatches the calculation out to threads
//
// must be written specific to each 2D function
// 
Function SmearedSphere2D_THR(s,nord)
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
//		Print trunc(i*npt/nthreads),trunc((i+1)*npt/nthreads-1)
		ThreadStart mt,i,SmearedSphere2D_T(s.coefW,s.xw[0],s.xw[1],s.qz,s.sQpl,s.sQpp,s.fs,s.zw,wt,xi,trunc(i*npt/nthreads),trunc((i+1)*npt/nthreads-1),nord)
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
// - worker function for threads of Sphere2D
//
ThreadSafe Function SmearedSphere2D_T(coef,qxw,qyw,qzw,sxw,syw,fsw,zw,wt,xi,pt1,pt2,nord)
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
	Variable qperp_pt,phi_prime,q_prime

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
///		app = -numStdDev*spp + phi		//perpendicular = phi integration limits (WRONG)
///		bpp = numStdDev*spp + phi
		app = -numStdDev*spp + 0		//q_perp = 0
		bpp = numStdDev*spp + 0
		
		//make sure the limits are reasonable.
		if(apl < 0)
			apl = 0
		endif
		// do I need to specially handle limits when phi ~ 0?
	
		
		sumOut = 0
		for(jj=0;jj<nord;jj+=1)		// call phi the "outer'
///			phi_pt = (xi[jj]*(bpp-app)+app+bpp)/2
			qperp_pt = (xi[jj]*(bpp-app)+app+bpp)/2		//this is now q_perp
			
			sumIn=0
			for(kk=0;kk<nord;kk+=1)		//at phi, integrate over Qpl

				qpl_pt = (xi[kk]*(bpl-apl)+apl+bpl)/2
				
///				FindQxQy(qpl_pt,phi_pt,qx_pt,qy_pt)		//find the corresponding QxQy to the Q,phi

				// find QxQy given Qpl and Qperp on the grid
				//
				q_prime = sqrt(qpl_pt^2+qperp_pt^2)
				phi_prime = phi + qperp_pt/q_prime
				FindQxQy(q_prime,phi_prime,qx_pt,qy_pt)
				
				yPtw[kk] = qy_pt					//phi is the same in this loop, but qy is not
				xPtW[kk] = qx_pt					//qx is different here too, as we're varying Qpl

				res_tot[kk] = exp(-0.5*( (qpl_pt-qval)^2/spl/spl + (qperp_pt)^2/spp/spp ) )
///				res_tot[kk] = exp(-0.5*( (qpl_pt-qval)^2/spl/spl + (phi_pt-phi)^2/spp/spp ) )
				res_tot[kk] /= normFactor
//				res_tot[kk] *= fs

			endfor
			
			Sphere2D_noThread(coef,fcnRet,xptw,yptw)			//fcn passed in is an AAO
			
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


