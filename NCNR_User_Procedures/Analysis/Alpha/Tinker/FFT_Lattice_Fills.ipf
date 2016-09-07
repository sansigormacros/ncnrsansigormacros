#pragma rtGlobals=1		// Use modern global access method.

// this is intended to be a series of methods to fill points
// on a particular lattice spacing
//
// possible methods include:
// filling a specified 3D volume
// filling a planar region
// filling a line (not really a crystal)
//
// once the points are located, then objects can be drawn at each
// point, possibly spheres, or cylinders in a given direction

//
// Hexagonal Close Packed
//
//



Macro PutXAxisCylindersAt3DPoints(w,num,rad,len,periodic,sobol,fill,centered)
	String w="mat"
	Variable num=100,rad=20,len=300,periodic=1,sobol=1,fill=10,centered=0
	Prompt w,"matrix"
	Prompt num,"number of starting points"
	prompt rad,"radius of cylinders"
	prompt len,"length of cylinders"
	prompt periodic,"1=periodic, 0=non-periodic boundaries"
	Prompt sobol,"1=Sobol, 0=random"
	Prompt fill,"fill SLD value"
	Prompt centered,"concentrate at center (0|1)"

	
//	$w=0
// always start fresh
	FFTEraseMatrixButtonProc("")
	
	X_CylindersAt3DPoints($w,num,rad,len,sobol,periodic,fill,centered)
	
	NumberOfPoints()
end


Function X_CylindersAt3DPoints(mat,num,rad,len,sobol,periodic,fill,centered)
	Wave mat
	variable num,rad,len		//length in direction
	Variable periodic		//==1 if periodic boundaries
	Variable sobol		//==1 if sobol selection of points (2D)
	Variable fill
	Variable centered
	
	NVAR 	solventSLD = root:FFT_SolventSLD

	Variable np
	np = DimSize(mat,0)			// assumes that all dimensions are the same

	if(centered)	
		Make/O/D/N=(np/2,np/2,np/2) small
		if(sobol)
			SobolFill3DMat(small,num,fill)
		else
			RandomFill3DMat(small,num,fill)
		endif
		ParseMatrix3D_rho(small)
		killwaves small

		Wave x3d=x3d
		Wave y3d=y3d
		Wave z3d=z3d
		x3d += np/4
		y3d += np/4
		z3d += np/4
		
	else
		//use the full matrix
		if(sobol)
			SobolFill3DMat(mat,num,fill)
		else
			RandomFill3DMat(mat,num,fill)
		endif
	
		ParseMatrix3D_rho(mat)
		Wave x3d=x3d
		Wave y3d=y3d
		Wave z3d=z3d
	
	endif

	
	Variable ii=0
	NVAR  grid=root:FFT_T
	
	for(ii=0;ii<num;ii+=1)
		FillXCylinder(mat,grid,rad,x3d[ii],y3d[ii],z3d[ii],len,fill)		//cylinder 1
	endfor
	
	return(0)
End

