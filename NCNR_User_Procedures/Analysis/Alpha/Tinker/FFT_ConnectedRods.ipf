#pragma rtGlobals=1		// Use modern global access method.

// I should be able to calculate the average number of connections from a search of the 
// connXYZ table. I might have other counting routines elsewhere for this too.
//
//
//		Set the Euler angles 55,-65,-150 for a consistent view
//
//

Proc Overnight()
	mTestConnRods()
End


Proc mTestConnRods()

	String suffix = ""
	Variable ranType = 1
	Variable t1 = ticks
	
// constant for all steps
	root:FFT_SolventSLD = 0

// always start fresh when changing dimensions
//	root:FFT_T = 40
//	root:FFT_N = 256
//	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
	
//	DoWindow/F Gizmo_VoxelMat
	
//	suffix = "a"
//	CalculateTriangulated(40,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "b"
//	CalculateTriangulated(100,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "c"
//	CalculateTriangulated(200,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "d"
//	CalculateTriangulated(300,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "e"
//	CalculateTriangulated(400,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "f"
//	CalculateTriangulated(500,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	
	
// always start fresh when changing dimensions
	root:FFT_T = 5
	root:FFT_N = 256
	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	
	suffix = "gg"
	CalculateTriangulated(6,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "hh"
	CalculateTriangulated(7,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "ii"
	CalculateTriangulated(9,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "jj"
	CalculateTriangulated(10,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "kk"
	CalculateTriangulated(20,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "ll"
	CalculateTriangulated(30,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	
	// then repeat everything with the random sequence
	ranType = 0
	
	// always start fresh when changing dimensions
//	root:FFT_T = 40
//	root:FFT_N = 256
//	FFT_MakeMatrixButtonProc("")
//	FFTEraseMatrixButtonProc("")
	
//	DoWindow/F Gizmo_VoxelMat
	
//	suffix = "m"
//	CalculateTriangulated(40,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "n"
//	CalculateTriangulated(100,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "o"
//	CalculateTriangulated(200,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "p"
//	CalculateTriangulated(300,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "q"
//	CalculateTriangulated(400,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
//	
//	suffix = "r"
//	CalculateTriangulated(500,40,20,"_CR"+suffix,ranType)
//	DoUpdate/W=Gizmo_VoxelMat
//	ExportGizmo wave as "p_connRod_"+suffix
	
	
	
// always start fresh when changing dimensions
	root:FFT_T = 5
	root:FFT_N = 256
	FFT_MakeMatrixButtonProc("")
	FFTEraseMatrixButtonProc("")
	
	suffix = "ss"
	CalculateTriangulated(6,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "tt"
	CalculateTriangulated(7,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "uu"
	CalculateTriangulated(9,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "vv"
	CalculateTriangulated(10,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "ww"
	CalculateTriangulated(20,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	suffix = "xx"
	CalculateTriangulated(30,40,20,"_CR"+suffix,ranType)
	DoUpdate/W=Gizmo_VoxelMat
	ExportGizmo wave as "p_connRod_"+suffix
	
	
	Print "Total elapsed time (s) = ",(ticks-t1)/60.15
	Print "Total elapsed time (min) = ",(ticks-t1)/60.15/60
	Print "Total elapsed time (hr) = ",(ticks-t1)/60.15/60/60
	

end

Function PrintWaveNote(kwStr)
	String kwStr
	
	String alph="abcdefghijklmnopqrstuvwxyz"
	String str=""
	Variable ii
	
	for(ii=1;ii<12;ii+=1)
		Wave w = $("root:iBin_"+alph[ii]+"p")
		str = note(w)
		if(strlen(kwStr) > 0)
			Print NumberByKey(kwStr, Str ,"=",";")
		else
			Print str
		endif
	endfor
	
	return(0)
End

// npts is the number of nodes
// diam is the diameter of the rods
// nPass is the number of averaging passes
// tagStr is the identifying tag for the files
// ranType selects the RNG => 1 = Sobol, other = enoise
Function CalculateTriangulated(nPts,diam,nPass,tagStr,ranType)
	Variable nPts,diam,nPass
	String tagStr
	Variable ranType
	
	Variable ii,np,frac,nocc,fill
	Wave m=root:mat
	NVAR grid=root:FFT_T
	NVAR Nedge = root:FFT_N

	np = 0
	frac = 0
	fill = 10
	for(ii=0;ii<nPass;ii+=1)		//number of averaging passes
		m=0
		
		if(ranType == 1)
			SobolFill3DMat(m,nPts,fill)
		else
			RandomFill3DMat(m,nPts,fill)
		endif
		ParseMatrix3D_rho(m)				// get the triplets of points to connect
		
		Print "connecting"
		ConnectTriangulated(diam)
		
		Execute "DoFFT()"
		Print "step ii=",ii
		if(ii==0)
			Duplicate/O iBin, $("iBin"+tagStr),$("qBin"+tagStr),$("i2"+tagStr),$("eBin"+tagStr)
			wave ib=$("iBin"+tagStr)
			wave qb=$("qBin"+tagStr)
			wave i2=$("i2"+tagStr)
			wave eb=$("eBin"+tagStr)
			Wave iBin=iBin
			Wave qbin=qBin
			qb = qBin
			ib = iBin
			i2 = iBin*iBin
			eb = 0
		else
			ib += iBin
			i2 += iBin*iBin
		endif
		
		// get an average of the fill parameters, since it's somewhat random
		nocc = NonZeroValues(m)
		np += nocc
		frac += nocc/DimSize(m,0)^3
		Print "np,frac = ",np,frac
	endfor

	ib /= npass
	i2 /= npass
	if(nPass > 1)
		eb = sqrt((i2-ib^2)/(npass-1))
	else
		eb = 1e-10
	endif
	np /= npass
	frac /= npass
	

	String nStr
	sprintf nstr,"T=%d;N=%d;Npass=%d;NNodes=%d;VolFrac=%g;",grid,Nedge,nPass,nPts,frac
	Note ib, nStr

	return(0)
End 





// at this point, the matrix has been filled with points
// and parsed to 3 xyz waves with ParseMatrix3D_rho()
//
Function ConnectTriangulated(diam)
	Variable diam

	Variable ii,num,thick,fill
	Variable x1,x2,y1,y2,z1,z2
	String testStr=""
	
	NVAR FFT_T = root:FFT_T
	thick = diam/FFT_T / 2
//	Print "diam, grid, thick = ",diam,FFT_T,thick
	
	Wave m=root:mat
	Wave x3d=root:x3d
	Wave y3d=root:y3d
	Wave z3d=root:z3d
	
	ConvertXYZto3N(x3d,y3d,z3d)
	Wave xyzTrip=root:matGiz
	
	Triangulate3d/OUT=2 xyzTrip
	// M_TetraPath is generated
	Wave M_TetraPath=M_TetraPath
	M_TetraPath = round(M_TetraPath)
	

	num = DimSize(M_TetraPath,0)
	fill = 1
	
	// make the list of connected points (to save time)
	Make/O/T/N=0 connXYZ
	
	Print "num = ",num
	for(ii=0;ii<num-1;ii+=1)
		if(numtype(M_tetraPath[ii][0]) == 0 && numtype(M_tetraPath[ii+1][0]) == 0)		// 0 = a normal number
			x1 = M_TetraPath[ii][0]
			x2 = M_TetraPath[ii+1][0]
			y1 = M_TetraPath[ii][1]
			y2 = M_TetraPath[ii+1][1]
			z1 = M_TetraPath[ii][2]
			z2 = M_TetraPath[ii+1][2]
			
			testStr = XYZstr(x1,y1,z1,x2,y2,z2)
			if(!XYZ_are_Connected(connXYZ,testStr))		// are points already connected?
				// if not, connect them
				ConnectPoints3D(m, x1,y1,z1,x2,y2,z2,thick,fill)
//				print "connected"
				// and list them as connected
				AddXYZConnList(connXYZ,x1,y1,z1,x2,y2,z2)
//				Print "fraction done = ",ii/num
			endif
		else
			//Print "ii = ",ii
		endif
	endfor

	Print "done connecting"
//	Execute "NumberOfPoints(\"mat\")"
	
	return(0)
End

// adds two entries to the list
// pt1->pt2
// pt2->pt1
// 
Function AddXYZConnList(w,x1,y1,z1,x2,y2,z2)
	Wave/T w
	Variable x1,y1,z1,x2,y2,z2

	String str1=XYZstr(x1,y1,z1,x2,y2,z2)
	String str2=XYZstr(x2,y2,z2,x1,y1,z1)

	Variable num=numpnts(w)
	InsertPoints num,2,w
	w[num] = str1
	w[num+1] = str2
	
	return(0)
End

// wave w is a text wave
//
Function XYZ_are_Connected(w,str)
	Wave/T w
	String str
	
	Variable ans=0
	
	// do the check
	FindValue/TEXT=str/TXOP=4 w
	
	//return the answer
	if(V_Value == -1)
		return(0)		//not connected
	else
		return(1)		//yes, connected
	endif
End

Function/S XYZstr(x1,y1,z1,x2,y2,z2)
	Variable x1,y1,z1,x2,y2,z2

	String str=""
	str += num_to_3char(x1)
	str += num_to_3char(y1)
	str += num_to_3char(z1)
	str += num_to_3char(x2)
	str += num_to_3char(y2)
	str += num_to_3char(z2)
	
	return(str)
End

Function/S num_to_3char(num)
	Variable num
	
	String numStr=""
	if(num<10)
		numStr = "00"+num2str(num)
	else
		if(num<100)
			numStr = "0"+num2str(num)
		else
			numStr = num2str(num)
		Endif
	Endif
	return(numstr)
End


/// this does not work ---
//
// the fCOnnectDots3D function does not work - and I 
// don't know what's wronk with it - so I switched to the
// Triangulate3D operation
// Jan 2011
//
//Function TestConnRods(nPts,nConn,nPass,tagStr)
//	Variable nPts,nConn,nPass
//	String tagStr
//	
//	Variable ii,np,frac,num
//	Variable row,col,lay,xt,yt,zt,err
//	
//	Wave m=mat
//	NVAR grid=root:FFT_T
//	NVAR Nedge = root:FFT_N
//	WAVE/Z x3d=root:x3d
//	
//	for(ii=0;ii<nPass;ii+=1)		//number of averaging passes
//		//fill the spheres into the box
//		m=0
//		RandomFill3DMat(m,nPts)
//		ParseMatrix3D_rho(m)				// get the triplets of points to connect
//		
//		num=numpnts(x3d)
//		Make/O/N=(num) numConnection3D=0
//		Make/O/T/N=(num) connectedTo3D=""
//		fConnectDots3D(nConn)
//		
//		Execute "DoFFT()"
//		Print "step ii=",ii
//		if(ii==0)
//			Duplicate/O iBin, $("iBin"+tagStr),$("qBin"+tagStr),$("i2"+tagStr),$("eBin"+tagStr)
//			wave ib=$("iBin"+tagStr)
//			wave qb=$("qBin"+tagStr)
//			wave i2=$("i2"+tagStr)
//			wave eb=$("eBin"+tagStr)
//			Wave iBin=iBin
//			Wave qbin=qBin
//			qb = qBin
//			ib = iBin
//			i2 = iBin*iBin
//			eb = 0
//		else
//			ib += iBin
//			i2 += iBin*iBin
//		endif
//	endfor
//
//	ib /= npass
//	i2 /= npass
//	if(nPass > 1)
//		eb = sqrt((i2-ib^2)/(npass-1))
//	else
//		eb = 1e-10
//	endif
//	
//	np = NonZeroValues(m)
//	frac = np/DimSize(m,0)^3
//	String nStr
//	sprintf nstr,"T=%d;N=%d;Npass=%d;NNodes=%d;NConn=%d;VolFrac=%g;",grid,Nedge,nPass,nPts,nConn,frac
//	Note ib, nStr
//
//	
//End

