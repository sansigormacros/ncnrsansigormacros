#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function MixTest()

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
	Variable rho1,rho2,rhos,radius1,radius2,ctr,separation,fill1,fill2
	rho1=1e-6
	rho2=3e-6
	rhos=6e-6
	
	radius1 = 40
	radius2 = 80
	ctr=50
	separation = radius1 + radius2
	
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
	return(0)
End


Function CoreShellTest()

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
	Variable rho1,rho2,rhos,radius1,radius2,ctr,separation,fill1,fill2
	rho1=6.5e-6
	rho2=4.7e-6
	rhos=5e-6
	
//	rho1 += 3e-6
//	rho2 += 3e-6
//	rhos += 3e-6
	
	radius1 = 20
	radius2 = 40
	ctr=50
	
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
	
	FillSphereRadius(m,FFT_T,radius2,ctr,ctr,ctr,fill2)
	FillSphereRadius(m,FFT_T,radius1,ctr,ctr,ctr,fill1)
	return(0)
End

Function ThreeShellTest()

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
	Variable rcore,rhocore,thick1,rhoshel1,thick2,rhoshel2,thick3,rhoshel3,rhos,fill1,fill2,fill3,fillc,ctr
	WAVE w=root:coef_ThreeShell
	
	rcore = w[1]
	rhocore = w[2]
	thick1 = w[3]
	rhoshel1 = w[4]
	thick2 = w[5]
	rhoshel2 = w[6]
	thick3 = w[7]
	rhoshel3 = w[8]
	rhos = w[9]
	
//	rho1 += 3e-6
//	rho2 += 3e-6
//	rhos += 3e-6
		
	FFT_SolventSLD = trunc(rhos/FFT_delRho)		//spits back an integer, maybe not correct

// generate the matrix and erase it
//	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	Wave m=root:mat

// fill the matrix with solvent
	FFTFillSolventMatrixProc("")

// with the input parameters, build the structure
	ctr = trunc(FFT_N/2)
	fillc = trunc(rhocore/FFT_delRho)
	fill1 = trunc(rhoshel1/FFT_delRho)
	fill2 = trunc(rhoshel2/FFT_delRho)
	fill3 = trunc(rhoshel3/FFT_delRho)
	
	FillSphereRadius(m,FFT_T,rcore+thick1+thick2+thick3,ctr,ctr,ctr,fill3)		//outer size (shell 3)
	FillSphereRadius(m,FFT_T,rcore+thick1+thick2,ctr,ctr,ctr,fill2)		//outer size (shell 2)
	FillSphereRadius(m,FFT_T,rcore+thick1,ctr,ctr,ctr,fill1)		//outer size (shell 1)
	FillSphereRadius(m,FFT_T,rcore,ctr,ctr,ctr,fillc)		//core
	return(0)
End



Function TetrahedronFill()

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
	Variable rho1,rho2,rho3,rho4,rhos,radius1,radius2,ctr,separation,fill1,fill2,fill3,fill4
	rho1 = 1e-6
	rho2 = 2e-6
	rho3 = 3e-6
	rho4 = 4e-6
	rhos = 6e-6
	
	radius1 = 150
	ctr=50
	separation = radius1
	separation = sqrt(2)*radius1/2
	
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
	fill3 = trunc(rho3/FFT_delRho)
	fill4 = trunc(rho4/FFT_delRho)
	
	// vertices are  (relative) - 4 corners of a cube
//	(1,1,1)
//	(-1,-1,1)
//	(-1,1,-1)
//	(1,-1,-1)
	
	FillSphereRadius(m,FFT_T,radius1,ctr+separation/FFT_T,ctr+separation/FFT_T,ctr+separation/FFT_T,fill1)
	FillSphereRadius(m,FFT_T,radius1,ctr-separation/FFT_T,ctr-separation/FFT_T,ctr+separation/FFT_T,fill2)
	FillSphereRadius(m,FFT_T,radius1,ctr-separation/FFT_T,ctr+separation/FFT_T,ctr-separation/FFT_T,fill3)
	FillSphereRadius(m,FFT_T,radius1,ctr+separation/FFT_T,ctr-separation/FFT_T,ctr-separation/FFT_T,fill4)
	return(0)
End



Function AxisCylinderFill()

// make sure all of the globals are set correctly
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
	Variable rho1,rho2,rho3,rho4,rhos,radius1,radius2,ctr,separation,fill1,fill2,fill3,fill4
	Variable len
	
	rho1 = 1e-6
	rho2 = 2e-6
	rho3 = 3e-6
	rho4 = 4e-6
	rhos = 6e-6
	
	radius1=40
	len = 300
	
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
	fill3 = trunc(rho3/FFT_delRho)
	fill4 = trunc(rho4/FFT_delRho)

	
	FillXCylinder(m,FFT_T,radius1,ctr+len/2/FFT_T,ctr,ctr,len,fill1)
	FillYCylinder(m,FFT_T,radius1,ctr,ctr+len/2/FFT_T,ctr,len,fill2)
	FillZCylinder(m,FFT_T,radius1,ctr,ctr,ctr+len/2/FFT_T,len,fill3)
	
	return(0)
	
End


// rad1 > rad2
//
Function FilledPores(rad1,rad2,rho1,rho2,len,sep)
	variable rad1,rad2,rho1,rho2,len,sep		//length of cylinders
	
	Variable fill1,fill2
	
	Wave 	mat=mat
	NVAR 	solventSLD = root:FFT_SolventSLD
	
	NVAR grid=root:FFT_T
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7

// fill the matrix with solvent
	FFTFillSolventMatrixProc("")


	fill1 = trunc(rho1/FFT_delRho)
	fill2 = trunc(rho2/FFT_delRho)
	
	Variable np,spacing
	np = DimSize(mat,0)			// assumes that all dimensions are the same
	
	// fill a 2D plane with points
	Make/O/B/N=(np,np) plane
	plane = solventSLD

	spacing = round(sep/grid)		// so it's an integer
	FillPlaneHexagonal(plane,spacing,fill2)		//use the core SLD
	
	// put it in the proper plane of the matrix
	mat[np/2][][] = plane[q][r]			// in the YZ plane
	
	ParseMatrix3D_rho(mat)
	Wave x3d=x3d
	Wave y3d=y3d
	Wave z3d=z3d
	
	Variable ii=0,num
	num = numpnts(x3d)	
	
	for(ii=0;ii<num;ii+=1)
		FillXCylinder(mat,grid,rad1,x3d[ii],y3d[ii],z3d[ii],len,fill1)		//cylinder 1
		Print "cyl = ",ii,num
	endfor

// makes a crude core-shell cylinder	
	for(ii=0;ii<num;ii+=1)
		FillXCylinder(mat,grid,rad2,x3d[ii],y3d[ii],z3d[ii],len,fill2)		//cylinder 2
		Print "core = ",ii,num
	endfor
	
	return(0)
End

//draw several structures
// save them
// re-load them
// do the FFT calcualtion + rename
// do the Binned SLD calculation + rename
//
//	SaveExperiment statements are done after every step to be sure that there is enough free memory
// -- running without caused a "not enough memory" error before any of the calculations could be done
// -- so I'm not completely sure that the Save statements will work.
//
//
Function TestSaveLoad_CoreShellHexagonal()


	Wave 	mat=mat
	NVAR 	solventSLD = root:FFT_SolventSLD
	
	NVAR grid=root:FFT_T
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7
	
//	// this function takes care of everything in clearing/filling the matrix
	FilledPores(40,25,2e-6,0e-6,400,100)
	SaveMyMatrix("mat_R40C25_L400_S100_N512.ibw")
	Print "Done with save 1 of 7"
	SaveExperiment

	FilledPores(40,25,2e-6,0e-6,400,120)
	SaveMyMatrix("mat_R40C25_L400_S120_N512.ibw")
	Print "Done with save 2 of 7"
	SaveExperiment
	
	FilledPores(40,25,2e-6,0e-6,400,140)
	SaveMyMatrix("mat_R40C25_L400_S140_N512.ibw")
	Print "Done with save 3 of 7"
	SaveExperiment
	
	FilledPores(40,25,2e-6,0e-6,400,160)
	SaveMyMatrix("mat_R40C25_L400_S160_N512.ibw")
	Print "Done with save 4 of 7"
	SaveExperiment
	
	FilledPores(40,25,2e-6,0e-6,400,180)
	SaveMyMatrix("mat_R40C25_L400_S180_N512.ibw")
	Print "Done with save 5 of 7"
	SaveExperiment

	FilledPores(40,25,2e-6,0e-6,400,200)
	SaveMyMatrix("mat_R40C25_L400_S200_N512.ibw")
	Print "Done with save 6 of 7"
	SaveExperiment
	
	FilledPores(40,25,2e-6,0e-6,400,220)
	SaveMyMatrix("mat_R40C25_L400_S220_N512.ibw")
	Print "Done with save 7 of 7"
	SaveExperiment

	
	
	//re-load the matrices
	Variable num,qmin,qmax
	num=1000
	qmin=0.01
	qmax=0.6
	
	Make/O/D/N=(num) qval_SLD,ival_SLD
	qval_SLD = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		
	
	
	Wave/Z iBin=root:iBin
	Wave/Z qBin=root:qBin
	
	ReloadMatrix("mat_R40C25_L400_S100_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S100_N512
	Duplicate/O qBin qBin_R40C25_L400_S100_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S100
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S100
	Print "Done with calculation 1 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40C25_L400_S120_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S120_N512
	Duplicate/O qBin qBin_R40C25_L400_S120_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S120
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S120
	Print "Done with calculation 2 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40C25_L400_S140_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S140_N512
	Duplicate/O qBin qBin_R40C25_L400_S140_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S140
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S140
	Print "Done with calculation 3 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40C25_L400_S160_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S160_N512
	Duplicate/O qBin qBin_R40C25_L400_S160_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S160
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S160
	Print "Done with calculation 4 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40C25_L400_S180_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S180_N512
	Duplicate/O qBin qBin_R40C25_L400_S180_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S180
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S180
	Print "Done with calculation 5 of 7"
	SaveExperiment

	ReloadMatrix("mat_R40C25_L400_S200_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S200_N512
	Duplicate/O qBin qBin_R40C25_L400_S200_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S200
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S200
	Print "Done with calculation 6 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40C25_L400_S220_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40C25_L400_S220_N512
	Duplicate/O qBin qBin_R40C25_L400_S220_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S220
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S220
	Print "Done with calculation 7 of 7"
	SaveExperiment

		
	
	Print "All calculations done"



	return(0)
End


Function TestSaveLoad_Hexagonal_vs_Sep()


	Wave 	mat=mat
	NVAR 	solventSLD = root:FFT_SolventSLD
	
	NVAR grid=root:FFT_T
	NVAR FFT_delRho = root:FFT_delRho		//the SLD multiplier, should have been initialized to 1e-7


// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,100,20)
	SaveMyMatrix("mat_R40_L400_S100_N512.ibw")
	Print "Done with save 1 of 7"
	SaveExperiment

// fill the matrix with solvent
	FFTFillSolventMatrixProc("")	
	X_CylindersHexagonalGrid(mat,40,400,120,20)
	SaveMyMatrix("mat_R40_L400_S120_N512.ibw")
	Print "Done with save 2 of 7"
	SaveExperiment
	
	// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,140,20)
	SaveMyMatrix("mat_R40_L400_S140_N512.ibw")
	Print "Done with save 3 of 7"
	SaveExperiment
	
	// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,160,20)
	SaveMyMatrix("mat_R40_L400_S160_N512.ibw")
	Print "Done with save 4 of 7"
	SaveExperiment
	
	// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,180,20)
	SaveMyMatrix("mat_R40_L400_S180_N512.ibw")
	Print "Done with save 5 of 7"
	SaveExperiment
	
	// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,200,20)
	SaveMyMatrix("mat_R40_L400_S200_N512.ibw")
	Print "Done with save 6 of 7"
	SaveExperiment
	
	// fill the matrix with solvent
	FFTFillSolventMatrixProc("")
	X_CylindersHexagonalGrid(mat,40,400,220,20)
	SaveMyMatrix("mat_R40_L400_S220_N512.ibw")
	Print "Done with save 7 of 7"
	SaveExperiment
	
	
	//re-load the matrices
	Variable num,qmin,qmax
	num=1000
	qmin=0.01
	qmax=0.6
	
	Make/O/D/N=(num) qval_SLD,ival_SLD
	qval_SLD = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		

	Wave/Z iBin=root:iBin
	Wave/Z qBin=root:qBin

	ReloadMatrix("mat_R40_L400_S100_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S100_N512
	Duplicate/O qBin qBin_R40_L400_S100_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S100
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S100
	Print "Done with calculation 1 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40_L400_S120_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S120_N512
	Duplicate/O qBin qBin_R40_L400_S120_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S120
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S120
	Print "Done with calculation 2 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40_L400_S140_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S140_N512
	Duplicate/O qBin qBin_R40_L400_S140_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S140
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S140
	Print "Done with calculation 3 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40_L400_S160_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S160_N512
	Duplicate/O qBin qBin_R40_L400_S160_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S160
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S160
	Print "Done with calculation 4 of 7"
	SaveExperiment
	
	ReloadMatrix("mat_R40_L400_S180_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S180_N512
	Duplicate/O qBin qBin_R40_L400_S180_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S180
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S180
	Print "Done with calculation 5 of 7"
	SaveExperiment
	

	ReloadMatrix("mat_R40_L400_S200_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S200_N512
	Duplicate/O qBin qBin_R40_L400_S200_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40C25_L400_S200
//	Duplicate/O qval_SLD qval_SLD_R40C25_L400_S200
	Print "Done with calculation 6 of 7"
	SaveExperiment

	ReloadMatrix("mat_R40_L400_S220_N512.ibw")
	Calc_IQ_FFT()
//	Execute "DoFFT()"
	Duplicate/O iBin iBin_R40_L400_S220_N512
	Duplicate/O qBin qBin_R40_L400_S220_N512
//	fDoCalc(qval_SLD,ival_SLD,grid,3,1)
//	Duplicate/O ival_SLD ival_SLD_R40_L400_S220
//	Duplicate/O qval_SLD qval_SLD_R40_L400_S220
	Print "Done with calculation 7 of 7"
	SaveExperiment
		
	
	Print "All calculations done"



	return(0)
End