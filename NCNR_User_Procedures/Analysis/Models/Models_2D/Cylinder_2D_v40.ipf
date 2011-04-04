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

///  REQUIRES DANSE XOP for 2D FUNCTIONS

//
// 4.8x speedup for threading (N=4 + Nvirt=4)
//

//
// the calculation is done as for the QxQy data set:
// three waves XYZ, then converted to a matrix
//
Proc PlotCylinder2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	if (!exists("Cylinder_2DX") )
		Abort "You must have the SANSAnalysis XOP installed to use 2D models"
	endif
	SetDataFolder $("root:"+str)
	
	// NOTE THAT THE COEFFICIENTS [N] ARE IN A DIFFERENT ORDER !!!
	// Setup parameter table for model function
	make/O/T/N=11 parameters_Cyl2D
	Make/O/D/N=11 coef_Cyl2D
	coef_Cyl2D[0] = 1.0
	coef_Cyl2D[1] = 20.0
	coef_Cyl2D[2] = 60.0
	coef_Cyl2D[3] = 1e-6
	coef_Cyl2D[4] = 6.3e-6
	coef_Cyl2D[5] = 0.0
	coef_Cyl2D[6] = 1.57
	coef_Cyl2D[7] = 0.0
	coef_Cyl2D[8] = 0.0
	coef_Cyl2D[9] = 0.0
	coef_Cyl2D[10] = 0.0
	
	// currently, the number of integration points is hard-wired to be 25 in Cylinder2D_T
	//coef_Cyl2D[11] = 25
	//
	parameters_Cyl2D[0] = "Scale"
	parameters_Cyl2D[1] = "Radius"
	parameters_Cyl2D[2] = "Length"
	parameters_Cyl2D[3] = "SLD cylinder (A^-2)"
	parameters_Cyl2D[4] = "SLD solvent"
	parameters_Cyl2D[5] = "Background"
	parameters_Cyl2D[6] = "Axis Theta"
	parameters_Cyl2D[7] = "Axis Phi"
	
	parameters_Cyl2D[9] = "Sigma of polydisp in Theta [rad]"		//*****
	parameters_Cyl2D[10] = "Sigma of polydisp in Phi [rad]"			//*****
	parameters_Cyl2D[8] = "Sigma of polydisp in Radius [A]"		//*****
	
//	parameters_Cyl2D[11] = "number of integration points"

	Edit parameters_Cyl2D,coef_Cyl2D					
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") xwave_Cyl2D
	Duplicate/O $(str+"_qy") ywave_Cyl2D,zwave_Cyl2D			
		
	Variable/G g_Cyl2D=0
	g_Cyl2D := Cylinder2D(coef_Cyl2D,zwave_Cyl2D,xwave_Cyl2D,ywave_Cyl2D)	//AAO 2D calculation
	
	Display ywave_Cyl2D vs xwave_Cyl2D
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor(ywave_Cyl2D)={zwave_Cyl2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	ConvertQxQy2Mat(xwave_Cyl2D,ywave_Cyl2D,zwave_Cyl2D,"Cyl2D_mat")
	Duplicate/O $"Cyl2D_mat",$"Cyl2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G g_Cyl2Dmat=0
	g_Cyl2Dmat := UpdateQxQy2Mat(xwave_Cyl2D,ywave_Cyl2D,zwave_Cyl2D,Cyl2D_lin,Cyl2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("Cylinder2D","coef_Cyl2D","parameters_Cyl2D","Cyl2D")
End


// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedCylinder2D(str)						
	String str
	Prompt str,"Pick the data folder containing the 2D data",popup,getAList(4)
	
	if (!exists("Cylinder_2DX") )
		Abort "You must have the SANSAnalysis XOP installed to use 2D models"
	endif
	SetDataFolder $("root:"+str)
	
	// NOTE THAT THE COEFFICIENTS [N] ARE IN A DIFFERENT ORDER !!!
	// Setup parameter table for model function
	make/O/T/N=11 smear_parameters_Cyl2D
	Make/O/D/N=11 smear_coef_Cyl2D
	smear_coef_Cyl2D[0] = 1.0
	smear_coef_Cyl2D[1] = 20.0
	smear_coef_Cyl2D[2] = 60.0
	smear_coef_Cyl2D[3] = 1e-6
	smear_coef_Cyl2D[4] = 6.3e-6
	smear_coef_Cyl2D[5] = 0.0
	smear_coef_Cyl2D[6] = 1.57
	smear_coef_Cyl2D[7] = 0.0
	smear_coef_Cyl2D[8] = 0.0
	smear_coef_Cyl2D[9] = 0.0
	smear_coef_Cyl2D[10] = 0.0
	
	// currently, the number of integration points is hard-wired to be 25 in Cylinder2D_T
	//smear_coef_Cyl2D[11] = 25
	//
	smear_parameters_Cyl2D[0] = "Scale"
	smear_parameters_Cyl2D[1] = "Radius"
	smear_parameters_Cyl2D[2] = "Length"
	smear_parameters_Cyl2D[3] = "SLD cylinder (A^-2)"
	smear_parameters_Cyl2D[4] = "SLD solvent"
	smear_parameters_Cyl2D[5] = "Background"
	smear_parameters_Cyl2D[6] = "Axis Theta"
	smear_parameters_Cyl2D[7] = "Axis Phi"
	
	smear_parameters_Cyl2D[9] = "Sigma of polydisp in Theta [rad]"		//*****
	smear_parameters_Cyl2D[10] = "Sigma of polydisp in Phi [rad]"			//*****
	smear_parameters_Cyl2D[8] = "Sigma of polydisp in Radius [A]"		//*****
	
//	smear_parameters_Cyl2D[11] = "number of integration points"

	Edit smear_parameters_Cyl2D,smear_coef_Cyl2D					
	
	// generate the triplet representation
	Duplicate/O $(str+"_qx") smeared_Cyl2D
	SetScale d,0,0,"1/cm",smeared_Cyl2D					
		
	Variable/G gs_Cyl2D=0
	gs_Cyl2D := fSmearedCylinder2D(smear_coef_Cyl2D,smeared_Cyl2D)		//wrapper to fill the STRUCT
	
	Display $(str+"_qy") vs $(str+"_qx")
	modifygraph log=0
	ModifyGraph mode=3,marker=16,zColor($(str+"_qy"))={smeared_Cyl2D,*,*,YellowHot,0}
	ModifyGraph standoff=0
	ModifyGraph width={Aspect,1}
	ModifyGraph lowTrip=0.001
	Label bottom "qx (A\\S-1\\M)"
	Label left "qy (A\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	// generate the matrix representation
	Duplicate/O $(str+"_qx"), sm_qx
	Duplicate/O $(str+"_qy"), sm_qy		// I can't use local variables in dependencies, so I need the name (that I can't get)
	
	// generate the matrix representation
	ConvertQxQy2Mat(sm_qx,sm_qy,smeared_Cyl2D,"sm_Cyl2D_mat")
	Duplicate/O $"sm_Cyl2D_mat",$"sm_Cyl2D_lin" 		//keep a linear-scaled version of the data
	// _mat is for display, _lin is the real calculation

	// not a function evaluation - this simply keeps the matrix for display in sync with the triplet calculation
	Variable/G gs_Cyl2Dmat=0
	gs_Cyl2Dmat := UpdateQxQy2Mat(sm_qx,sm_qy,smeared_Cyl2D,sm_Cyl2D_lin,sm_Cyl2D_mat)
	
	
	SetDataFolder root:
	AddModelToStrings("SmearedCylinder2D","smear_coef_Cyl2D","smear_parameters_Cyl2D","Cyl2D")
End






////
////  Fit function that is actually a wrapper to dispatch the calculation to N threads
////
//// nthreads is 1 or an even number, typically 2
//// it doesn't matter if npt is odd. In this case, fractional point numbers are passed
//// and the wave indexing works just fine - I tested this with test waves of 7 and 8 points
//// and the points "2.5" and "3.5" evaluate correctly as 2 and 3
////
//Function Cylinder2D(cw,zw,xw,yw) : FitFunc
//	Wave cw,zw,xw,yw
//	
//	Variable npt=numpnts(yw)
//	Variable ii,nthreads= ThreadProcessorCount
//	variable mt= ThreadGroupCreate(nthreads)
//
////	Variable t1=StopMSTimer(-2)
//	
//	for(ii=0;ii<nthreads;ii+=1)
//	//	Print (ii*npt/nthreads),((ii+1)*npt/nthreads-1)
//		ThreadStart mt,ii,Cylinder2D_T(cw,zw,xw,yw,(ii*npt/nthreads),((ii+1)*npt/nthreads-1))
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
//	return(0)
//End


/// now using the MultiThread keyword. as of Igor 6.20, the manual threading
// as above gives a wave read error (index out of range). Same code works fine in Igor 6.12
//ThreadSafe Function Cylinder2D(cw,zw,xw,yw) : FitFunc
Function Cylinder2D(cw,zw,xw,yw) : FitFunc
	Wave cw,zw,xw,yw
	
	//	Variable t1=StopMSTimer(-2)

#if exists("Cylinder_2DX")			//to hide the function if XOP not installed

	Make/O/D/N=12 Cyl2D_tmp				// there seems to be no speed penalty for doing this...
	Cyl2D_tmp[0,10] = cw
	Cyl2D_tmp[11] = 25					// hard-wire the number of integration points
	Cyl2D_tmp[5] = 0						// send a background of zero
	
	MultiThread zw = Cylinder_2DX(Cyl2D_tmp,xw,yw) + cw[5]		//add in the proper background here

#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
End


/////////////////////smeared functions //////////////////////

Function SmearedCylinder2D(s)
	Struct ResSmear_2D_AAOStruct &s
	
//// non-threaded, but generic calculation
//// the last param is nord	
//	Smear_2DModel_PP(Cylinder2D_noThread,s,10)

// this is generic, but I need to declare the Cylinder2D threadsafe
// and this calculation is significantly slower than the manually threaded calculation
// if the function is fast to calculate. Once the function has polydispersity on 2 or more parameters
// then this AAO calculation and the manual threading are both painfully slow, and more similar in execution time
//
// see the function for timing details
//
//	Smear_2DModel_PP_AAO(Cylinder2D,s,10)

//// the last param is nord
	SmearedCylinder2D_THR(s,10)		

	return(0)
end

// for the plot dependency only
Function fSmearedCylinder2D(coefW,resultW)
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
	err = SmearedCylinder2D(s)
	
	return (0)
End

//
// NON-THREADED IMPLEMENTATION
// -- same as threaded, but no MultiThread KW
//
ThreadSafe Function Cylinder2D_noThread(cw,zw,xw,yw)
	Wave cw,zw,xw,yw
	
	//	Variable t1=StopMSTimer(-2)

#if exists("Cylinder_2DX")			//to hide the function if XOP not installed

	Make/O/D/N=12 Cyl2D_tmp				// there seems to be no speed penalty for doing this...
	Cyl2D_tmp[0,10] = cw
	Cyl2D_tmp[11] = 5					// hard-wire the number of integration points
	Cyl2D_tmp[5] = 0						// send a background of zero
	
	zw = Cylinder_2DX(Cyl2D_tmp,xw,yw) + cw[5]		//add in the proper background here

#endif

//	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
End

//
// this is the threaded version, that dispatches the calculation out to threads
//
// must be written specific to each 2D function
// 
Function SmearedCylinder2D_THR(s,nord)
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
//		Print (i*npt/nthreads),((i+1)*npt/nthreads-1)
		ThreadStart mt,i,SmearedCylinder2D_T(s.coefW,s.xw[0],s.xw[1],s.qz,s.sQpl,s.sQpp,s.fs,s.zw,wt,xi,(i*npt/nthreads),((i+1)*npt/nthreads-1),nord)
	endfor

	do
		variable tgs= ThreadGroupWait(mt,100)
	while( tgs != 0 )

	variable dummy= ThreadGroupRelease(mt)
	
// comment out the threading + uncomment this for testing to make sure that the single thread works
//	nThreads=1
//	SmearedCylinder2D_T(s.coefW,s.xw[0],s.xw[1],s.qz,s.sQpl,s.sQpp,s.fs,s.zw,wt,xi,(i*npt/nthreads),((i+1)*npt/nthreads-1),nord)

	Print "elapsed time = ",(StopMSTimer(-2) - t1)/1e6
	
	return(0)
end

//
// - worker function for threads of Cylinder2D
//
ThreadSafe Function SmearedCylinder2D_T(coef,qxw,qyw,qzw,sxw,syw,fsw,zw,wt,xi,pt1,pt2,nord)
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
		app = -numStdDev*spp + 0		//q_perp = 0
		bpp = numStdDev*spp + 0
		
		//make sure the limits are reasonable.
		if(apl < 0)
			apl = 0
		endif
		// do I need to specially handle limits when phi ~ 0?
	
		
		sumOut = 0
		for(jj=0;jj<nord;jj+=1)		// call phi the "outer'
			qperp_pt = (xi[jj]*(bpp-app)+app+bpp)/2		//this is now q_perp

			sumIn=0
			for(kk=0;kk<nord;kk+=1)		//at phi, integrate over Qpl

				qpl_pt = (xi[kk]*(bpl-apl)+apl+bpl)/2
				
				// find QxQy given Qpl and Qperp on the grid
				//
				q_prime = sqrt(qpl_pt^2+qperp_pt^2)
				phi_prime = phi + qperp_pt/qpl_pt
				FindQxQy(q_prime,phi_prime,qx_pt,qy_pt)
				
				yPtw[kk] = qy_pt					//phi is the same in this loop, but qy is not
				xPtW[kk] = qx_pt					//qx is different here too, as we're varying Qpl
				
				res_tot[kk] = exp(-0.5*( (qpl_pt-qval)^2/spl/spl + (qperp_pt)^2/spp/spp ) )
				res_tot[kk] /= normFactor
//				res_tot[kk] *= fs

			endfor
			
			Cylinder2D_noThread(coef,fcnRet,xptw,yptw)			//fcn passed in is an AAO
			
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


