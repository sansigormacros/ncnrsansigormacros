#pragma rtGlobals=1		// Use modern global access method.


Proc testAddRotCyl()

	Variable ii,zval,rotx,roty,fill,rad
	
	FFT_T=root:FFT_T
	
	rotx=0
	roty=90
	zval = 0
	rad=20
	fill=20
	
	ii=rad/FFT_T+1
//	print ii
	do
		zval=ii
		FFTDrawRotCylinder("mat",rad,200,64,64,zval,rotx,roty,fill)
		ii+=(2*rad)/FFT_T
		rotx += 12
	while(ii<(127-(rad/FFT_T)))
	
//	print ii
End


// draws a single cylinder with the specified center and rotation. does not clear the matrix
//
// x-rotation is done first, then the y-rotation
//
Proc FFTDrawRotCylinder(matStr,rad,len,xc,yc,zc,xrot,yrot,fill)
	String matStr="mat"
	Variable rad=25,len=300,xc=50,yc=50,zc=50,xrot=10,yrot=90,fill=10
	Prompt matStr,"the wave"		//,popup,WaveList("*",";","")
	Prompt rad,"enter real radius (A)"
	Prompt len,"enter length (A)"
	Prompt xc,"enter the X-center"
	Prompt yc,"enter the Y-center"
	Prompt zc,"enter the Z-center"
	Prompt xrot,"x-rotation (degrees)"
	Prompt yrot,"y-rotation (degrees)"
	Prompt fill,"fill SLD value"	
	
	Make/O/D/N=1 xx,yy,zz,rri,hti,rotx,roty,sld
	
	xx[0] = xc
	yy[0] = yc
	zz[0] = zc
	rri[0] = rad
	hti[0] = len
	rotx[0] = xrot
	roty[0] = yrot
	sld[0] = fill	

	Duplicate/O xx, sbp
	
	// parse
//	KR_MultiCylinder(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)
	KR_MultiCylinder_Units(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)

	XYZV_FillMat_Centered(xoutW,youtW,ZoutW,xc,yc,zc,rad,len,fill,0)			//last 1 will erase the matrix, 0 retains matrix

	//force a redraw (re-coloring) of the gizmo window
	FFTMakeGizmoButtonProc("")
	
End


// -- now this will put the cylinders properly at the specified centers, in the units of "mat"
//
/// seems to work - but what do I do about fractional positions? when converting to a matrix?
//
// the wave "gg" has been dropped, since it's only used as a flag in an old file loader
//
// NOW - SBP is FORCED to the value of FFT_T - no matter what is in the file.
//
Function KR_MultiCylinder_Units(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)
	Wave xx,yy,zz,rri,hti,sbp,rotx,roty,sld

	Variable I, J, K, L, PT	//integer indices loops, num cylinders, include or exclude sphere in circle
	Variable STH, SPH, CTH, CPH, FTR  //sine and cosines and deg-->rad conversion: x rotn theta & y rotn phi
	Variable  XMID, YMID, ZMID, XOUT, YOUT, ZOUT  //cartesian positions used in various calculations
	Variable RR,HH  //RR is limit of loops, GG used as end of read param files--exit=2, NUM of cylinder
	Variable  P5  //spheres half diameter shift from grid points (avoids zeros)
	Variable X0, Y0,Z0
	Variable PI2
	Variable ix,nptW
	
	NVAR FFT_T = root:FFT_T
//	FFT_T = sbp[0]
//	sbp[0] = FFT_T
	sbp = FFT_T
	
	variable npts,cyl
	npts = numpnts(xx)
	cyl = npts
		
	Make/O/D/N=0 xoutW,youtW,zoutW,sbpW,sldW
	
	PI2=pi*2
	FTR=PI2/360
	
	nptW = 0
	
	for(l=0;l<(cyl);L+=1)	//only change from run4
	//for each cylinder of loop use index NUM
	//calculate x & y rotation cos and sin
		STH=SIN(Rotx[L]*FTR)
		SPH=sin(roty[L]*FTR)
		CTH=cos(rotx[L]*FTR)
		CPH=cos(roty[L]*FTR)
		//print "sth",sth
		//print"L=",L
		P5=SBP[L]/2  //set sphere centers' half-diameter displacement from grid (avoids glitches)
		// print "p5 & sbp[L]",p5,sbp[L]
	
		RR=(RRI[L]/SBP[L])//as an index, Igor truncates the number to an integer....does NOT round it
		RR=RR+1 //rr is the loop limit for square around final circle
		HH=(HTI[L]/(2*SBP[L]))	//as an index, Igor truncates the number to an integer....does NOT round it
		for(k=-HH;k<HH;k+=1)  // should have +1 for HH to complete to k=HH?????
			for(i=-RR;i<RR;i+=1)  //should this have i<RR+1 or in above RR=RR+2????
				for(j=-RR;j<RR;J+=1)
					x0=sbp[L]*i+P5
					y0=SBP[L]*j+P5
					z0=SBP[L]*k+p5
					if((((y0^2)/(RRI[L]^2))+((x0^2)/(RRI[L]^2)))<=1)
						IX=-1
					else
						IX=0
					endif 
					xmid=x0
					ymid=y0*cth+z0*sth
					zmid=-y0*sth+z0*cth
					// end rotation about x begin rotn about y on rotated pts
					//
					xout=xmid*cph-zmid*sph
					xout=xx[L]+xout/SBP[L]
					yout=ymid
					yout=yy[L]+yout/SBP[L]
					zout=xmid*sph+zmid*cph
					zout=zz[L]+zout/SBP[L]

					// now print to wave file the point or not depending on whether ix<0 or not

					if (ix<0)
					//write to wave file
						InsertPoints nptW,1,xoutW,youtW,zoutW,sbpW,sldW
						xoutW[nptW] = xout
						youtW[nptW] = yout
						zoutW[nptW] = zout
						sbpW[nptW] = sbp[L]
						sldW[nptW] = sld[L]
						
						nptW +=1
					
						//print  xout,yout,zout,sbp[L],sld[L]
					//else
						//continue
					endif  //for write or not
				endfor  // for j
			endfor	//  for i
		endfor  //for k 
	endfor // for L 


	// rescale to the sphere size
//	xoutW /= FFT_T
//	youtW /= FFT_T
//	zoutW /= FFT_T

	xoutW = trunc(xoutW)
	youtW = trunc(youtW)
	zoutW = trunc(zoutW)
	
	return(0) // end do loop cycle for cylinders
end





///
/// -- replaced by KR_MultiCylinder_Units()
///
/// seems to work - but what do I do about fractional positions? when converting to a matrix?
//
// the wave "gg" has been dropped, since it's only used as a flag in an old file loader
//
// NOW - SBP is FORCED to the value of FFT_T - no matter what is in the file.
//
Function KR_MultiCylinder(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)
	Wave xx,yy,zz,rri,hti,sbp,rotx,roty,sld

	Variable I, J, K, L, PT	//integer indices loops, num cylinders, include or exclude sphere in circle
	Variable STH, SPH, CTH, CPH, FTR  //sine and cosines and deg-->rad conversion: x rotn theta & y rotn phi
	Variable  XMID, YMID, ZMID, XOUT, YOUT, ZOUT  //cartesian positions used in various calculations
	Variable RR,HH  //RR is limit of loops, GG used as end of read param files--exit=2, NUM of cylinder
	Variable  P5  //spheres half diameter shift from grid points (avoids zeros)
	Variable X0, Y0,Z0
	Variable PI2
	Variable ix,nptW
	
	NVAR FFT_T = root:FFT_T
//	FFT_T = sbp[0]
//	sbp[0] = FFT_T
	sbp = FFT_T
	
	variable npts,cyl
	npts = numpnts(xx)
	cyl = npts
		
	Make/O/D/N=0 xoutW,youtW,zoutW,sbpW,sldW
	
	PI2=pi*2
	FTR=PI2/360
	
	nptW = 0
	
	for(l=0;l<(cyl);L+=1)	//only change from run4
	//for each cylinder of loop use index NUM
	//calculate x & y rotation cos and sin
		STH=SIN(Rotx[L]*FTR)
		SPH=sin(roty[L]*FTR)
		CTH=cos(rotx[L]*FTR)
		CPH=cos(roty[L]*FTR)
		//print "sth",sth
		//print"L=",L
		P5=SBP[L]/2  //set sphere centers' half-diameter displacement from grid (avoids glitches)
		// print "p5 & sbp[L]",p5,sbp[L]
	
		RR=(RRI[L]/SBP[L])//as an index, Igor truncates the number to an integer....does NOT round it
		RR=RR+1 //rr is the loop limit for square around final circle
		HH=(HTI[L]/(2*SBP[L]))	//as an index, Igor truncates the number to an integer....does NOT round it
		for(k=-HH;k<HH;k+=1)  // should have +1 for HH to complete to k=HH?????
			for(i=-RR;i<RR;i+=1)  //should this have i<RR+1 or in above RR=RR+2????
				for(j=-RR;j<RR;J+=1)
					x0=sbp[L]*i+P5
					y0=SBP[L]*j+P5
					z0=SBP[L]*k+p5
					if((((y0^2)/(RRI[L]^2))+((x0^2)/(RRI[L]^2)))<=1)
						IX=-1
					else
						IX=0
					endif 
					xmid=x0
					ymid=y0*cth+z0*sth
					zmid=-y0*sth+z0*cth
					// end rotation about x begin rotn about y on rotated pts
					//
					xout=xmid*cph-zmid*sph
					xout=xx[L]+xout
					yout=ymid
					yout=yy[L]+yout
					zout=xmid*sph+zmid*cph
					zout=zz[L]+zout

					// now print to wave file the point or not depending on whether ix<0 or not

					if (ix<0)
					//write to wave file
						InsertPoints nptW,1,xoutW,youtW,zoutW,sbpW,sldW
						xoutW[nptW] = xout
						youtW[nptW] = yout
						zoutW[nptW] = zout
						sbpW[nptW] = sbp[L]
						sldW[nptW] = sld[L]
						
						nptW +=1
					
						//print  xout,yout,zout,sbp[L],sld[L]
					//else
						//continue
					endif  //for write or not
				endfor  // for j
			endfor	//  for i
		endfor  //for k 
	endfor // for L 


	// rescale to the sphere size
	xoutW /= FFT_T
	youtW /= FFT_T
	zoutW /= FFT_T
	
	return(0) // end do loop cycle for cylinders
end






// triplet to display as a scatter plot in Gizmo
//
// will overwrite the triplet
//
Function MakeTriplet(xoutW,youtW,zoutW)
	Wave xoutW,youtW,zoutW
	
	KillWaves/Z triplet
	concatenate/O {xoutW,youtW,zoutW},triplet 
end



Proc KR_LoadAndFill()

	KR_Load()
	XYZV_FillMat(xoutW,youtW,ZoutW,sldW,1)			//last 1 will erase the matrix
	MakeTriplet(xoutW,youtW,zoutW)
	 
	DoBinned_KR_FFTPanel()
	Print "now display the gizmo, triplet or use one of the calculation methods"
	
End

Proc KR_CalcFromInput()

	KR_MultiCylinder(xCtr,yCtr,zCtr,rad,length,sphereDiam,rot_x,rot_y,SLD_sph)
	// these are really just for display, or if the FFT of mat is wanted later.
	XYZV_FillMat(xoutW,youtW,ZoutW,sldW,1)			//last 1 will erase the matrix
	MakeTriplet(xoutW,youtW,zoutW)

// and the calculation. Assumes SLDs are all the same	 
	DoBinned_KR_FFTPanel(100,0.004,0.5)
	
End

//called from the FFT method panel
//
// in this method, the distances are binned as by Otto Glatter, and has been partially XOPed
//
// if the number of bins is too high (say 100000), then using the non-integer XYZ will
// be 2-3 times slower since there will be a lot more bins - then the loop over the q-values at the
// very end will be what is significantly slower. If the number of bins is reduced to 10000 (as suggested
// in Otto's book, p.160), then the two methods (types 12 and 2) give very similar timing, and the
// results are indistinguishable.
//
Proc DoBinned_KR_FFTPanel(num,qMin,qMax)
	Variable num=100,qmin=0.004,qmax=0.5
	
	Variable t1
	String qStr="qval_KR",iStr="ival_KR"		//default wave names, always overwritten
	Variable grid
	
	grid=root:FFT_T

	Make/O/D/N=(num) $qStr,$iStr
	$qStr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		
	
	Variable estTime,nx
	String str = ""

	nx = NonZeroValues(mat)
	
	estTime = EstimatedTime(nx,num,2)		// 0 =  XOP, 1 = no XOP, 2 = binned distances
	sprintf str, "Estimated time for the calculation is %g seconds. Proceed?",estTime
	DoAlert 1,str
	if(V_Flag==1)		//yes, proceed
		t1=ticks
		fDoCalc($qStr,$iStr,grid,12,1)
//		Printf "Elapsed AltiSpheres time = %g seconds\r\r",(ticks-t1)/60.15
	Endif
End

Function fDoBinned_KR_FFTPanel(num,qMin,qMax)
	Variable num,qmin,qmax
	
	Variable t1,multiSLD,mode
	String qStr="qval_KR",iStr="ival_KR"		//default wave names, always overwritten
	
	NVAR grid=root:FFT_T
	ControlInfo/W=MultiCyl check_0
	multiSLD = V_Value
	if(multiSLD)
		mode=13
	else
		mode=12
	endif

	Make/O/D/N=(num) qval_KR,ival_KR
	qval_KR = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		
	
	Variable estTime,nx,tooLong
	String str = ""
	tooLong = 300
	
	nx = NonZeroValues(mat)
	
	estTime = EstimatedTime(nx,num,2)		// 0 =  XOP, 1 = no XOP, 2 = binned distances
	if(estTime > tooLong)
		sprintf str, "Estimated time for the calculation is %g seconds. Proceed?",estTime
		DoAlert 1,str
	endif
	if(V_Flag==1 || estTime < tooLong)		//yes, proceed
		t1=ticks
		fDoCalc(qval_KR,ival_KR,grid,mode,1)
//		Printf "Elapsed AltiSpheres time = %g seconds\r\r",(ticks-t1)/60.15
	Endif
End

/////////////////////////////////////
// for each cylinder:
//
// xx,yy,zz,rri,hti,sbp,rotx,roty,sld
// xx,yy,zz = center of cylinder
// rri,hti = radius, height (units??)
// sbp = ??? -- I think this is the diameter of the primary sphere
// rotx, rotx = rotation angles (in degrees, but defined as ??)
// sld = SLD of cylinder
//
// Put this into a panel with the table and the data
// and fields for all of the inputs
Macro Setup_KR_MultiCylinder()
	
	Make/O/D/N=0 xx,yy,zz,rri,hti,sbp,rotx,roty,sld
	Variable/G root:KR_Qmin = 0.004
	Variable/G root:KR_Qmax = 0.4
	Variable/G root:KR_Npt = 100

	FFT_MakeMatrixButtonProc("")

	NewPanel /W=(241,44,1169,458)/N=MultiCyl/K=1 as "Multi-Cylinder"
	ModifyPanel cbRGB=(49825,57306,65535)

	Button button_0,pos={45,80},size={100,20},proc=KR_Show3DButtonProc,title="Show 3D"
	Button button_1,pos={46,51},size={100,20},proc=KR_Plot1DButtonProc,title="Plot 1D"
	Button button_2,pos={178,50},size={150,20},proc=KR_GenerateButtonProc,title="Generate Structure"
	Button button_4,pos={178,80},size={120,20},proc=KR_DoCalcButtonProc,title="Do Calculation"
	Button button_3,pos={600,60},size={120,20},proc=KR_DeleteRow,title="Delete Row(s)"
	Button button_5,pos={600,10},size={120,20},proc=KR_SaveTable,title="Save Table"
	Button button_6,pos={600,35},size={120,20},proc=KR_ImportTable,title="Import Table"
	ValDisplay valdisp_0,pos={339,16},size={80,13},title="FFT_T"
	ValDisplay valdisp_0,limits={0,0,0},barmisc={0,1000},value= #"root:FFT_T"
	SetVariable setvar_0,pos={339,40},size={140,15},title="Q min (A)"
	SetVariable setvar_0,limits={0,10,0},value= KR_Qmin
	SetVariable setvar_1,pos={339,65},size={140,15},title="Q max (A)"
	SetVariable setvar_1,limits={0,10,0},value= KR_Qmax
	SetVariable setvar_2,pos={339,90},size={140,15},title="Num Pts"
	SetVariable setvar_2,limits={10,500,0},value= KR_Npt
	CheckBox check_0,pos={599,93},size={59,14},title="Multi SLD",value= 0

	Edit/W=(18,117,889,378)/HOST=#  xx,yy,zz,rri,hti,rotx,roty,sld
	ModifyTable format(Point)=1,width(Point)=0
	RenameWindow #,T0
	SetActiveSubwindow ##

End




Function KR_Plot1DButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up			
			DoWindow/F KR_IQ
			if(V_flag==0)
				Execute "KR_IQ()"
			Endif
			
			break
	endswitch

	return 0
End

Function KR_Show3DButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DoWindow/F Gizmo_VoxelMat
			if(V_flag==0)
				Execute "Gizmo_VoxelMat()"
			endif
	
			break
	endswitch

	return 0
End

Function KR_DeleteRow(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			GetSelection table, MultiCyl#T0,3
//			Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
			DoAlert 1, "Do want to delete rows "+num2Str(V_StartRow)+" through "+num2str(V_endRow)+" ?"
			if(V_flag==1)			
				DeletePoints V_StartRow,(V_endRow-V_StartRow+1),xx,yy,zz,rri,hti,sbp,rotx,roty,sld
			endif
			
			break
	endswitch

	return 0
End

Function KR_SaveTable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
//			xx,yy,zz,rri,hti,rotx,roty,sld
			Save/T/P=home/I xx,yy,zz,rri,hti,rotx,roty,sld as "SavedCyl.itx"
			
			break
	endswitch

	return 0
End

Function KR_ImportTable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			LoadWave/T/O/P=home			
			break
	endswitch

	return 0
End

//just generates the structure, no calculation
Function KR_GenerateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Wave xx=root:xx
			if(numpnts(xx)==0)
				return(0)
			endif
			wave yy=yy
			wave zz=zz
			wave rri=rri
			wave hti=hti
//			wave sbp=sbp
			wave rotx=rotx
			wave roty=roty
			wave sld=sld
	
			Duplicate/O xx, sbp
			NVAR FFT_T=root:FFT_T
			sbp = FFT_T
			
			// parse
			KR_MultiCylinder(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)

			// these are really just for display, or if the FFT of mat is wanted later.
			WAVE xoutW=root:xoutW
			WAVE youtW=root:youtW
			WAVE zoutW=root:zoutW
			WAVE sldW=root:sldW
	
			XYZV_FillMat(xoutW,youtW,ZoutW,sldW,1)			//last 1 will erase the matrix
//			MakeTriplet(xoutW,youtW,zoutW)
//		
//		// and the calculation. Assumes SLDs are all the same	
//			NVAR qmin = root:KR_Qmin
//			NVAR qmax = root:KR_Qmax
//			NVAR npt = root:KR_Npt
//		 
//			fDoBinned_KR_FFTPanel(npt,qmin,qmax)
//	

			//force a redraw (re-coloring) of the gizmo window
			FFTMakeGizmoButtonProc("")
			
			break
	endswitch


	
	return 0
End



Function KR_DoCalcButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Wave xx=root:xx
			if(numpnts(xx)==0)
				return(0)
			endif
			wave yy=yy
			wave zz=zz
			wave rri=rri
			wave hti=hti
//			wave sbp=sbp
			wave rotx=rotx
			wave roty=roty
			wave sld=sld
	
			Duplicate/O xx, sbp
			NVAR FFT_T=root:FFT_T
			sbp = FFT_T
			
			// parse
			KR_MultiCylinder(xx,yy,zz,rri,hti,sbp,rotx,roty,sld)

			// these are really just for display, or if the FFT of mat is wanted later.
			WAVE xoutW=root:xoutW
			WAVE youtW=root:youtW
			WAVE zoutW=root:zoutW
			WAVE sldW=root:sldW
	
			XYZV_FillMat(xoutW,youtW,ZoutW,sldW,1)			//last 1 will erase the matrix
			MakeTriplet(xoutW,youtW,zoutW)
		
		// and the calculation. Assumes SLDs are all the same	
			NVAR qmin = root:KR_Qmin
			NVAR qmax = root:KR_Qmax
			NVAR npt = root:KR_Npt
		 
			fDoBinned_KR_FFTPanel(npt,qmin,qmax)
	
			
			break
	endswitch

	return 0
End


Proc KR_IQ() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(295,44,627,302) ival_KR vs qval_KR
	DoWindow/C KR_IQ
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph msize=2
	ModifyGraph gaps=0
	ModifyGraph grid=1
	ModifyGraph log=1
	ModifyGraph mirror=2
	Legend/N=text0/J "\\s(ival_KR) ival_KR"
EndMacro

/////////////////////////////////////
//
//
// for the "manual" fitting
//

Proc Vary_One_Cyl_Param(waveStr,row,percent,numStep)
// pick the wave and row and %
	String waveStr="xx"
	Variable row=1
	Variable percent = 105
	Variable numStep = 10
	Prompt waveStr,"wave",popup,"xx;yy;zz;rri;hti;rotx;roty;sld;"

	print waveStr
	
// dispatch to calculation
	MultiCyl_Loop($waveStr,row,percent,numStep)
	
// plot the chi2_map
	DoWindow/F MultiCyl_ChiMap
	if(V_flag==0)
		MultiCyl_ChiMap()
	endif

end

Function MultiCyl_Loop(w,row,percent,numStep)
	Wave w
	Variable row,percent,numStep
	
	Variable loLim,hiLim,ii,minIndex,minChiSq
	String folderStr
	
	Make/O/D/N=(numStep) chi2_map,testVals
	Wave chi2_map=chi2_map
	Wave testVals=testVals
	
	loLim = w[row] - percent*w[row]/100
	hiLim = w[row] + percent*w[row]/100
	testVals = loLim + x*(hiLim-loLim)/numStep

//		the experimental data
	ControlInfo/W=WrapperPanel popup_0
	folderStr=S_Value
	// wave references for the data (to pass)
	String DF="root:"+folderStr+":"	
	
	WAVE yw=$(DF+folderStr+"_i")
	WAVE xw=$(DF+folderStr+"_q")
	WAVE sw=$(DF+folderStr+"_s")

	duplicate/o yw, interpCalc,chi2_data
	Wave chi2_data=chi2_data
	Wave interpCalc=interpCalc
		
	STRUCT WMButtonAction ba
	ba.eventCode = 2
	
// loop
	for(ii=0;ii<numStep;ii+=1)
//   	set the value
		w[row] = testVals[ii]
//		generate the structure
//
		KR_GenerateButtonProc(ba)

//		do the calculation
		KR_DoCalcButtonProc(ba)

		WAVE ival_KR=ival_KR
		WAVE qval_KR=qval_KR
		
		interpCalc = interp(xw, qval_KR, ival_KR )
		
//		calculate chi-squared
		chi2_data = (yw-interpCalc)^2
		chi2_data /= sw^2
	

		Wavestats/Q chi2_data
		chi2_map[ii] = V_avg * V_npnts
// end loop
	endfor

// find the best chi squared
	WaveStats/Q chi2_map
// reset the value to the best
 	minIndex = V_minRowLoc
	w[row] = testVals[minIndex]
	
	minChiSq = chi2_map[minIndex]
	print "Minimum chi2 = ",minChiSq


// and then recalculate at the best solution
	KR_GenerateButtonProc(ba)

//		do the calculation
	KR_DoCalcButtonProc(ba)
	
	return(0)
End

Proc MultiCyl_ChiMap()
	PauseUpdate; Silent 1		// building window...
	Display /W=(35,44,466,414) chi2_map vs testVals
	DoWindow/C MultiCyl_ChiMap
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph msize=2
	Label left "chi-squared"
	Label bottom "test values"
end

//Function testKRPar()
//	
//	Variable row, col
//	String wStr
//	
//	getParamFromKRSetup(row,col,wStr)
//	Print row, col, wStr
//	
//	wStr = StringFromList(0, wStr)		// some wave "xx.d"
//	wStr = StringFromList(0, wStr, ".")  // removes the ".d"
//	Wave w=$wStr
//	print w[row]
//	
//	Variable numStep,loLim,hiLim,percent
//	numStep = 25
//	percent = 50
//	
//	loLim = w[row] - percent*w[row]/100
//	hiLim = w[row] + percent*w[row]/100
//	
//	
//	Make/O/D/N=(numStep) testKRVals
//	testKRVals = loLim + x*(hiLim-loLim)/numStep	
//
//	print testKRvals
//	return(0)
//	
//End
//
//Function getParamFromKRSetup(row,col,wStr)
//	Variable &row,&col
//	String &wStr
//	
//	Variable parNum
//	
//	GetSelection table, MultiCyl#T0, 3
//	row = V_startRow
//	col = V_startCol
//	Print S_Selection
//	wStr = S_Selection
//	
//	
//	return(0)
//End

Proc Vary_Two_Cyl_Param(waveStr,row,waveStr2,row2,percent,percent2,numStep)
// pick the wave and row and %
	String waveStr="xx"
	Variable row=1
	String waveStr2="rri"
	Variable row2=0
	Variable percent = 105
	Variable percent2 = 50
	Variable numStep=5
	Prompt waveStr,"wave",popup,"xx;yy;zz;rri;hti;rotx;roty;sld;"
	Prompt waveStr2,"wave2",popup,"xx;yy;zz;rri;hti;rotx;roty;sld;"
	
// dispatch to calculation
	MultiCyl_Loop_2D($waveStr,row,$waveStr2,row2,percent,percent2,numStep)
	
// plot the chi2_map
	DoWindow/F MultiCyl_ChiMap_2D
	if(V_flag==0)
		MultiCyl_ChiMap_2D()
	else
		//V_min*1.01 = the 1% neighborhood around the solution
		WaveStats/Q chi2_Map_2D
		ModifyImage/W=MultiCyl_ChiMap_2D chi2_Map_2D ctab= {(V_min*1.01),*,ColdWarm,0}
		ModifyImage/W=MultiCyl_ChiMap_2D chi2_Map_2D minRGB=(0,65535,0),maxRGB=(0,65535,0)
	endif

end


Function MultiCyl_Loop_2D(w,row,w2,row2,percent,percent2,numStep)
	Wave w
	Variable row
	Wave w2
	Variable row2,percent,percent2,numStep
	
	Variable loLim,hiLim,ii,jj,minIndex,minChiSq
	String folderStr
	
	Make/O/D/N=(numStep,numStep) chi2_Map_2D
	Make/O/D/N=(numStep) testVals,testVals2
	Wave chi2_Map_2D=chi2_Map_2D
	Wave testVals=testVals
	Wave testVals2=testVals2
	
	testVals = 0
	testVals2 = 0
	chi2_Map_2D = 0
	
	
	loLim = w[row] - percent*w[row]/100
	hiLim = w[row] + percent*w[row]/100
	testVals = loLim + x*(hiLim-loLim)/(numStep-1)
//	Print lolim,hilim

	SetScale/I x LoLim,HiLim,"", chi2_Map_2D

	loLim = w2[row2] - percent2*w2[row2]/100
	hiLim = w2[row2] + percent2*w2[row2]/100
	testVals2 = loLim + x*(hiLim-loLim)/(numStep-1)
//	Print lolim,hilim

	SetScale/I y LoLim,HiLim,"", chi2_Map_2D


//		the experimental data
	ControlInfo/W=WrapperPanel popup_0
	folderStr=S_Value
	// wave references for the data (to pass)
	String DF="root:"+folderStr+":"	
	
	WAVE yw=$(DF+folderStr+"_i")
	WAVE xw=$(DF+folderStr+"_q")
	WAVE sw=$(DF+folderStr+"_s")

	duplicate/o yw, interpCalc,chi2_data
	Wave chi2_data=chi2_data
	Wave interpCalc=interpCalc
	
	STRUCT WMButtonAction ba
	ba.eventCode = 2
	
// double loop
	for(ii=0;ii<numStep;ii+=1)
		Print "			Outer Loop Index = ",ii," out of ",numStep
		//set the value from the outer loop
		w[row] = testVals[ii]

		for(jj=0;jj<numStep;jj+=1)
		
	//   	set the inner value
			w2[row2] = testVals2[jj]
	//		generate the structure
	//
			KR_GenerateButtonProc(ba)
	
	//		do the calculation
			KR_DoCalcButtonProc(ba)
	
			WAVE ival_KR=ival_KR
			WAVE qval_KR=qval_KR
			
			interpCalc = interp(xw, qval_KR, ival_KR )
			
	//		calculate chi-squared
			chi2_data = (yw-interpCalc)^2
			chi2_data /= sw^2
		
			Wavestats/Q chi2_data
			chi2_Map_2D[ii][jj] = V_avg * V_npnts
			
		endfor
	endfor


// find the best chi squared
	WaveStats/Q chi2_Map_2D
// reset the value to the best
	w[row] = V_MinRowLoc
	w2[row2] = V_MinColLoc	
	
	minChiSq = V_Min
	print "Minimum chi2 = ",minChiSq

// and then recalculate at the best solution
	KR_GenerateButtonProc(ba)

//		do the calculation
	KR_DoCalcButtonProc(ba)
	
	return(0)
End

Proc MultiCyl_ChiMap_2D()
	PauseUpdate; Silent 1		// building window...
	Display /W=(35,44,466,414)
	AppendImage chi2_Map_2D
	DoWindow/C MultiCyl_ChiMap_2D
	ModifyImage chi2_Map_2D ctab= {*,*,ColdWarm,0}
	
	//V_min*1.01 = the 1% neighborhood around the solution
	WaveStats/Q chi2_Map_2D
	ModifyImage/W=MultiCyl_ChiMap_2D chi2_Map_2D ctab= {(V_min*1.01),*,ColdWarm,0}
	ModifyImage/W=MultiCyl_ChiMap_2D chi2_Map_2D minRGB=(0,65535,0),maxRGB=(0,65535,0)
	
	Label bottom "test values"
	Label left "test values"
end



//
///// seems to work - but what do I do about fractional positions? when converting to a matrix?
////
////
//
//Function KR_Load()
//	Variable I, J, K, L, PT	//integer indices loops, num cylinders, include or exclude sphere in circle
//	Variable STH, SPH, CTH, CPH, FTR  //sine and cosines and deg-->rad conversion: x rotn theta & y rotn phi
//	Variable  XMID, YMID, ZMID, XOUT, YOUT, ZOUT  //cartesian positions used in various calculations
//	Variable RR,HH  //RR is limit of loops, GG used as end of read param files--exit=2, NUM of cylinder
//	Variable  P5  //spheres half diameter shift from grid points (avoids zeros)
//	Variable X0, Y0,Z0
//	Variable PI2
//	Variable ix,nptW
//
//
//	LoadWave /G /N  
//	Print S_filename
//	Print S_wavenames
//	
//	//Make / O /N=0 OutputPoints
//	//	wave out=OutputPoints
//	//	variable num=numpnts(out)
//	
//	KillWaves/Z xx,yy,zz,rri,hti,sbp,rotx,roty,sld,gg
//	
//	Rename wave0, xx
//	Rename wave1, yy
//	Rename wave2, zz
//	Rename wave3, RRI
//	Rename wave4, HTI
//	Rename wave5, SBP
//	Rename wave6, ROTX
//	Rename wave7, ROTY
//	Rename wave8, SLD
//	Rename wave9, GG
//	
//	//print  NUM,xx,yy,zz,rri,hti,sbp,rotx,roty,sld,gg
//
//	
//	wave gg = gg
//	variable nn =-1,npts,cyl
//	npts = numpnts(GG)
//	
//	for (i=0;i<=npts;i+=1)
//		if (gg[i]==2)
//			cyl = i+1
//			break
//			print "gg[i],i=",gg,i
//		endif
//	endfor
//	print"cyl=",cyl
//	
//
//	wave xx=xx
//	wave yy=yy
//	wave zz=zz
//	wave rri=rri
//	wave hti=hti
//	wave sbp=sbp
//	wave rotx=rotx
//	wave roty=roty
//	wave sld=sld
//	
//	// SBP = diameter of the spheres
//	NVAR FFT_T = root:FFT_T
//	FFT_T = SBP[0]
//	//
//	
//	Make/O/D/N=0 xoutW,youtW,zoutW,sbpW,sldW
//	
//	PI2=pi*2
//	FTR=PI2/360
//	// print "ftr=", ftr
//	
//	nptW = 0
//	
//	for(l=0;l<(cyl);L+=1)	//only change from run4
//	//for each cylinder of loop use index NUM
//	//calculate x & y rotation cos and sin
//		STH=SIN(Rotx[L]*FTR)
//		SPH=sin(roty[L]*FTR)
//		CTH=cos(rotx[L]*FTR)
//		CPH=cos(roty[L]*FTR)
//		//print "sth",sth
//		//print"L=",L
//		P5=SBP[L]/2  //set sphere centers' half-diameter displacement from grid (avoids glitches)
//		// print "p5 & sbp[L]",p5,sbp[L]
//	
//		RR=(RRI[L]/SBP[L])//as an index, Igor truncates the number to an integer....does NOT round it
//		RR=RR+1 //rr is the loop limit for square around final circle
//		HH=(HTI[L]/(2*SBP[L]))	//as an index, Igor truncates the number to an integer....does NOT round it
//		for(k=-HH;k<HH;k+=1)  // should have +1 for HH to complete to k=HH?????
//			for(i=-RR;i<RR;i+=1)  //should this have i<RR+1 or in above RR=RR+2????
//				for(j=-RR;j<RR;J+=1)
//					x0=sbp*i+P5
//					y0=SBP*j+P5
//					z0=SBP*k+p5
//					if((((y0^2)/(RRI[L]^2))+((x0^2)/(RRI[L]^2)))<=1)
//						IX=-1
//					else
//						IX=0
//					endif 
//					xmid=x0
//					ymid=y0*cth+z0*sth
//					zmid=-y0*sth+z0*cth
//					// end rotation about x begin rotn about y on rotated pts
//					//
//					xout=xmid*cph-zmid*sph
//					xout=xx[L]+xout
//					yout=ymid
//					yout=yy[L]+yout
//					zout=xmid*sph+zmid*cph
//					zout=zz[L]+zout
//
//					// now print to wave file the point or not depending on whether ix<0 or not
//
//					if (ix<0)
//					//write to wave file
//						InsertPoints nptW,1,xoutW,youtW,zoutW,sbpW,sldW
//						xoutW[nptW] = xout
//						youtW[nptW] = yout
//						zoutW[nptW] = zout
//						sbpW[nptW] = sbp[L]
//						sldW[nptW] = sld[L]
//						
//						nptW +=1
//					
//						//print  xout,yout,zout,sbp[L],sld[L]
//					//else
//						//continue
//					endif  //for write or not
//				endfor  // for j
//			endfor	//  for i
//		endfor  //for k 
//	endfor // for L 
//
//	// rescale to the sphere size
//	xoutW /= FFT_T
//	youtW /= FFT_T
//	zoutW /= FFT_T
//	
//	return(0) // end do loop cycle for cylinders
//end