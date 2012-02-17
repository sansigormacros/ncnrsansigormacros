#pragma rtGlobals=1		// Use modern global access method.


// in this procedure file there are a few testing proceudres that are good 
// examples of how to script the calcualtions to automatically fill, calculate
// and rename output for later inspection. Very useful to survey a series of 
// conditions or for very lengthy calculations
//
// there is also a loop to run through all of the calculation methods to 
// get relatice timing information.
//

Proc concSphereLoop()

// constant for all steps
	root:FFT_T = 5
	root:FFT_N = 128
	root:FFT_SolventSLD = 0
	
// always start fresh
	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	
	
//
// this block tests the number of passes needed for a "good" average
//
//	testConcSpheres(10,20,0,5,"_a5")
//	testConcSpheres(10,20,0,10,"_a10")
//	testConcSpheres(10,20,0,20,"_a20")
//	testConcSpheres(10,20,0,50,"_a50")
//	testConcSpheres(10,20,0,100,"_a100")
	
//
// this block tests the concentration
//
//	testConcSpheres(100,20,0,20,"_b")
//	testConcSpheres(200,20,0,20,"_c")
//	testConcSpheres(300,20,0,20,"_d")
//	testConcSpheres(350,20,0,20,"_e")

//	testConcSpheres(600,20,0,20,"_f")
//	testConcSpheres(800,20,0,20,"_g")
//	testConcSpheres(1200,20,0,20,"_h")
//	testConcSpheres(1600,20,0,20,"_i")
//
//	testConcSpheres(2000,20,0,20,"_j")
//	testConcSpheres(2600,20,0,20,"_k")
//	testConcSpheres(3200,20,0,20,"_l")
////
//// this block tests the concentration and polydispersity
////

//	testConcSpheres(84,20,0.25,20,"_bp")
//	testConcSpheres(168,20,0.25,20,"_cp")
//	testConcSpheres(253,20,0.25,20,"_dp")
//	testConcSpheres(295,20,0.25,20,"_ep")
//
//	testConcSpheres(505,20,0.25,20,"_fp")
//	testConcSpheres(674,20,0.25,20,"_gp")
//	testConcSpheres(1011,20,0.25,20,"_hp")
//	testConcSpheres(1348,20,0.25,20,"_ip")

	testConcSpheres(1685,20,0.25,20,"_jp")
	testConcSpheres(2190,20,0.25,20,"_kp")
	testConcSpheres(2696,20,0.25,20,"_lp")


	
//	// this block simply is to save the gizmo as a wave
//
//	DoWindow/F Gizmo_VoxelMat
//	
//	testConcSpheres(100,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p012"
//	
//	testConcSpheres(200,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p024"
//	
//	testConcSpheres(300,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p036"
//	
//	testConcSpheres(350,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p041"
//	
//	
//
//	testConcSpheres(600,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p070"
//	
//	testConcSpheres(800,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p094"
//	
//	testConcSpheres(1200,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p141"
//	
//	testConcSpheres(1600,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p188"
//	
//
//
//	testConcSpheres(2000,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p233"
//	
//	testConcSpheres(2600,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p299"
//	
//	testConcSpheres(3200,20,0.25,1,"_dum")
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_phi_0p366"
////	
///////////////////////////	
end


//
// Note that there is still an issue with the algorithm that skews towards
// smaller radii as the concentration increases (for the polydisperse case)
// if a sphere fails (and the larger ones are more likely to fail), a new position
// AND a new sphere radius is selected
//
//
// with the double do loop modification, now there is the possibility that it
// will try forever to fill a sphere, but there was always that possibility before.
//
//
// nSph = number of LARGE spheres to add (not the voxel size)
// rad = mean radius of these large spheres
// pd = polydispersity (0,1)
// nPass = number of repeat averaging passes
// tagStr = extension string for the output name = "iBin"+tagStr
//
Function TestConcSpheres(nSph,rad,pd,nPass,tagStr)
	Variable nSph,rad,pd,nPass
	String tagStr
	
	Variable ii,np,frac,jj,tmprad,t1
	Variable row,col,lay,xt,yt,zt,err,fails
	String printStr
	Wave m=mat
	NVAR grid=root:FFT_T
	NVAR Nedge = root:FFT_N
	
	row=DimSize(m,0)		
	col=DimSize(m,1)
	lay=DimSize(m,2)
	
	Make/O/D/N=(nSph) failures,radius,skipped
	Variable skipCount=0
	failures = 0
	radius = 0
	skipped = 0
	
	t1 = ticks
	for(ii=0;ii<npass;ii+=1)		//number of averaging passes
		//fill the spheres into the box
		m=0
		skipCount = 0
		failures = 0
		radius = 0
		skipped = 0
		
		for(jj=0;jj<nSph;jj+=1)		//number of spheres
			
			// pick a sphere radius
			if(pd !=0 )
				tmprad = Rad + gnoise(pd*Rad)
			else
				tmprad = rad
			endif
			
			fails = -1
			//now find a place for this sphere
			do
				fails += 1
				//find an unfilled voxel
				do
					xt=trunc(abs(enoise(row)))		//distr betw (0,npt)
					yt=trunc(abs(enoise(col)))
					zt=trunc(abs(enoise(lay)))
				while(m[xt][yt][zt] == 1)
			
				//try to put the sphere there, and keep trying forever
				err = FillSphereRadiusNoOverlap(m,grid,tmprad,xt,yt,zt,1)
				
//				if(fails == 10)
//					Print "failed 10x on tmprad = ",tmprad
//				endif
//				if(fails == 100)
//					Print "failed 100x on tmprad = ",tmprad
//				endif
				if(fails == 1000)
					Print "failed 1000x on tmprad, skipping = ",tmprad
					skipped[jj] = 1
					skipCount += 1
					err = 0
				endif
			while(err==1)
			failures[jj] = fails
			radius[jj] = tmprad
						
			if(mod(jj, 100 )	== 0)
				Print "sphere jj done, pass = ",jj,ii+1
				Print "time = ",(ticks-t1)/60.15
			endif
			if(jj > 2000 && mod(jj, 10 )	== 0)
				Print "sphere jj done, pass = ",jj,ii+1
				Print "time = ",(ticks-t1)/60.15
			endif
		endfor
		// spheres have been placed, do the calculation	
		ParseMatrix3D_rho(m)	
		
		Execute "DoFFT()"
		sprintf printStr,"completed pass %d of %d \r",ii+1,npass
		Print printStr
		if(ii==0)
			Duplicate/O iBin, $("iBin"+tagStr),$("qBin"+tagStr),$("sBin"+tagStr),isq
			wave ib=$("iBin"+tagStr)
			wave qb=$("qBin"+tagStr)
			wave sb=$("sBin"+tagStr)
			Wave iBin=iBin
			Wave qbin=qBin
			Wave isq=isq
			qb=qBin
			isq = ib*ib
		else
			ib += iBin
			isq += iBin*iBin
		endif
	endfor

	ib /= npass
	isq /= npass
	
	sb = sqrt( (isq-ib^2)/(npass - 1) )		// <I^2> - <I>^2
	
	Variable vol
	NVAR delRho = root:FFT_delRho
	np = NonZeroValues(m)
	frac = np/Nedge^3
//	delRho = 1e-6
	vol = 4*pi/3*(rad)^3		//individual sphere volume based on the voxel equivalent
	
	Print "vol = ",vol
	Print "frac = ",frac
	
//	ib *= delrho*delrho
//	ib *= 1e8
//	ib /= vol
//	ib *= frac
//	ib /= (Nedge)^3
	
	nSph -= skipCount
	
	String nStr
	sprintf nstr,"T=%d;N=%d;Npass=%d;NSpheres=%d;Rad=%g;PD=%g;VolFrac=%g;",grid,Nedge,nPass,nSph,rad,pd,frac
	Note ib, nStr

	
End


Proc FillStatistics()

	Variable num
	
	Wavestats/Q skipped
	Print "Number skipped = ",V_sum
	
	Wavestats/Q radius
	Print "average, sdev = ",V_avg,V_sdev
	fails_vs_radius()
	

End

// for testing of the timing
// type is 0 | 2 | 3
// 0 = FFT
// 2 = binned, single SLD
// 3 = Binned, multiple SLD (3 in this example)
Proc Timing_Method(type)
	Variable type		// type of calculation, not used right now

// constant for all steps
	root:FFT_T = 5
	root:FFT_N = 128
	root:FFT_SolventSLD = 0
	Variable num,qMin,qMax,grid,xc,yc,zc,rad,fill
	num=100
	qMin = 0.004
	qMax = 0.4
	grid = root:FFT_T
	xc = 64
	yc = 64
	zc = 64
	
// always start fresh
	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	
//// type 0
	fill = 1
	rad = 100
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 80
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 70
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 30
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	
//	type 2
	fill = 1
	rad = 150
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")
	
	rad = 120
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 100
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 80
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSpheresCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")
	

// type 3
	fill = 3
	rad = 150
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 2
	rad = 100
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 1
	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSLDCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	fill = 3
	rad = 120
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 2
	rad = 100
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 1
	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSLDCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")
	
	fill = 3
	rad = 100
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 2
	rad = 70
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 1
	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSLDCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	fill = 3
	rad = 80
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 2
	rad = 70
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 1
	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSLDCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")

	fill = 3
	rad = 50
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 2
	rad = 40
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	fill = 1
	rad = 30
	FillSphereRadius(mat,grid,rad,xc,yc,zc,fill)
	DoBinnedSLDCalcFFTPanel(num,qMin,qMax)
	FFTEraseMatrixButtonProc("")


End