#pragma rtGlobals=1		// Use modern global access method.


Proc ConnectDots2D(maxNumConn,thick)
	Variable maxNumConn=1,thick=1
	
	Variable num=numpnts(x2d)
	Make/O/N=(num) numConnection2D=0
	Make/O/T/N=(num) connectedTo2D=""
	fConnectDots2D(maxNumConn,thick)
end

// connect the dots, no periodic boundary conditions
Function fConnectDots2D(maxNumConn, thick)
	Variable maxNumConn, thick
	
	
	WAVE x2d=x2d
	WAVE y2d=y2d
	WAVE numConnection2D = numConnection2D
	WAVE/T connectedTo2D = connectedTo2D
	WAVE plane=plane
	Variable num=numpnts(x2d),ii=0
	Variable matSize=DimSize(plane,0),jj

	Variable nnX,nnY,nnInd,nnDist		//return values of the neareset neighbor

	do
		for(ii=0;ii<num;ii+=1)
			if(numConnection2D[ii] < maxNumConn)
				FindNearestNeighbor2D(x2d,y2d,ii,maxNumConn,nnX,nnY,nnInd,nnDist)
				
				numConnection2D[nnInd] += 1
				numConnection2D[ii] += 1
				connectedTo2D[nnInd] += num2str(ii)+","
				connectedTo2D[ii] += num2str(nnInd)+","
				
				ConnectPoints2D(plane, x2d[ii],y2d[ii],x2d[nnInd],y2d[nnInd],thick)
			endif
		endfor
		//without rotation, a very closed network structure tends to form (bias?)
		// rotate (10?) points so that we're not starting from the same place every time
		// -- but the "connectedTo" information is LOST...
		//Rotate 10, x2d,y2d, numConnection,connectedTo
		//Print sum(numConnection,-inf,inf), num*maxNumConn
	while(sum(numConnection2D,-inf,inf) < num*maxNumConn)

End


///////////////////
// find the nearest point to the input point
//
// The nearest point that is returned must satisfy the input criteria
// (1) not already connected to input point
// (2) not already connected to the maximum number of interconnects
//
// Input:
// 	xw,yw: waves of identical length that are the XY pairs for the nodes to connect
//	pt: index of the trial point
// 	nConn: wave of # of connections of the XY pair
//	connTo: text wave of (comma-delimited) indexes of the connected points
//	matSize: dimension of the plane (assumed square)
// 	maxN: maximum number of connections
//
// Output:
//	(change) nConn, connTo (at each end)
// 	Index of the XY pair to connect (as pass by reference)
//	(?) Distance
//
//
Function FindNearestNeighbor2D(xw,yw,startPt,maxConn,nnX,nnY,nnInd,nnDist)
	Wave xw,yw
	Variable startPt,maxConn,&nnX,&nnY,&nnInd,&nnDist
	
	Variable num,matSize,numToFind
	
	//make waves to hold the answers
	num=numpnts(xw)
	Make/O/N=(num) distWave2D,distIndex2D
	
	//now calculate the distances
	Variable ii,dist,testPt
	
	//this is probably the slowest step by far in the process...(tiny XOP?)
	for(ii=0;ii<num;ii+=1)
		distWave2D[ii] = (xw[ii]-xw[startPt])^2 +  (yw[ii]-yw[startPt])^2 		//d^2
	endfor

	MakeIndex distWave2D distIndex2D		//then distWave[distIndex[ii]] will loop through in order of distance
	WAVE numConnection2D = numConnection2D
	WAVE/T connectedTo2D = connectedTo2D
	WAVE plane = plane
	
	for(ii=1;ii<num;ii+=1)		//[0] point is the test point, dist == 0
		testPt =  distIndex2D[ii]		//index
		if(numConnection2D[testPt] < maxConn )		//can test pt accept another connection?
			if(WhichListItem(num2str(testPt),connectedTo2D[startPt],",",0) == -1) // not already connected to the starting point?
	//			Print ii,testPt
	//			Printf "nearest point is (%d,%d), dist^2 = %g\r",xw[testPt],yw[testPt],distWave[testPt]
				nnX = xw[testPt]		//return values as pass-by-reference
				nnY = yw[testPt]
				nnInd = testPt
				nnDist = distWave2D[testPt]

				return(0)		//found a point, return
			endif
		endif
	endfor

	return (1)		//did not find a point, return error
End

Proc Test2D()

	Variable fill = 10
	
	Make/O/N=(100,100) plane
	DoWindow/F Plane_View
	if(V_flag==0)
		Display/K=1 /W=(40,44,330,334)
		DoWindow/C Plane_View
		AppendImage  root:plane
		ModifyGraph width={Plan,1,bottom,left},height={Plan,1,left,bottom}
	endif
	plane=0
	RandomPoints2D(plane,10,fill)
End

Proc Erase2D()
	plane=0
End


//for the 3D equivalent, see RandomFill3DMat(mat,num)
//
Function RandomPoints2D(w,num,fill)
	Wave w
	variable num		//number of spheres to add
	Variable fill
	
	Variable row,col,ii,xt,yt,zt,fail=0
	
	row=DimSize(w,0)		
	col=DimSize(w,1)
	
	ii=0
	do
		xt=trunc(abs(enoise(row)))		//distr betw (0,npt)
		yt=trunc(abs(enoise(col)))
		if( w[xt][yt] == 0 )
			w[xt][yt] = fill
			ii+=1		//increment number of spheres actually added
			//Print "point ",ii
		else
			fail +=1
		endif
	while(ii<num)
	Print "failures = ",fail
	
	ParseMatrix2D(w)		//convert to XY pairs
	
	return(0)
End

// the Sobol sequence MUST be initlalized before passing to thie routine
Function SobolPoints2D(w,num,fill)
	Wave w
	variable num		//number of spheres to add
	Variable fill
	
	Variable row,col,ii,xt,yt,zt,fail=0
	
	Make/O/D/N=2 Sobol2D
	
	// initialize Sobol
//	SobolX(-1,Sobol2D)
	row=DimSize(w,0)		
	col=DimSize(w,1)
	
	for(ii=0;ii<num;ii+=1)
		SobolX(2,Sobol2D)
		xt = Sobol2D[0] *row
		yt = Sobol2D[1] *col
		w[xt][yt] = fill
	endfor
	
	ParseMatrix2D(w)		//convert to XY pairs
	
	return(0)
End

// parses the 2d matrix to get xy coordinates
// CHANGE - ? Make as byte waves to save space
//
// XY waves are hard-wired to be "x2D,y2D"
// overwrites previous waves
//
//3D equivalent is ParseMatrix3D_rho(mat)
//
Function ParseMatrix2D(mat)
	Wave mat
	
	Variable nptx,npty,ii,jj,num
	
	nptx=DimSize(mat,0)
	npty=DimSize(mat,1)	
	Make/O/N=0 x2D,y2D,ptNum
	num=0
	
	for(ii=0;ii<nptx;ii+=1)
		for(jj=0;jj<npty;jj+=1)
			if(mat[ii][jj])
				num+=1
				InsertPoints num,1,x2D,y2D,ptNum
				x2D[num-1]=ii
				y2D[num-1]=jj
				ptNum[num-1]=num-1
			endif
		endfor
	endfor
	
	return(0)
End

Function ConnectPoints2D(w, x1,y1,x2,y2,thick)
	Wave w
	Variable  x1,y1,x2,y2,thick
	
	//find all of the points within dist=thick of the line defined by p1 and p2
	// and give these points (in w) the value 1
	
	//find the equation of the line Ax+By+C=0 (or mx - y + b = 0)
	Variable A,B,C
	A = (y2-y1)/(x2-x1)
	B = -1
	C = y1 - A*x1
	if (x1 == x2)	//special case of a vertical line
		A=1
		B=0
		C=-x1
	endif
	// search through the box defined by p1 and p2
	Variable ii,jj,dist
	
	for(ii=min(x1,x2);ii<=max(x1,x2);ii+=1)
		for(jj=min(y1,y2);jj<=max(y1,y2);jj+=1)
			//find distance between current point and P1P2
			dist = Pt_Line_Distance2D(ii,jj,A,B,C)
			//print dist
			if(dist<=thick)
				w[ii][jj] = 1		//add the point
			endif
		endfor
	endfor
	
End

// connect two points, maybe needing to apply periodic conditions
// wave w is the 2d matrix (the plane)
//
// P1 is in, P2 MAY be a ghost point
//
//
// INCOMPLETE
Function ConnectPoints2DPeriodic(w, x1,y1,x2,y2,thick,list,jj)
	Wave w
	Variable  x1,y1,x2,y2,thick
	String list		//full list of points
	Variable jj		//index of list we're using
	
	//find the intersection with the edge of the box
	//
	// then do two fills - from p1 to edge, then from reflection of edge to p2
	Variable xProj,yProj,xIn,yIn,wDim
	String keyStr,xyStr
	
	keyStr = "XY"+num2str(jj+1)
	xyStr = StringByKey(keyStr,list,"=",";")
	xProj = str2num(StringFromList(0, xyStr ,","))
	yProj = str2num(StringFromList(1, xyStr ,","))
	wDim = DimSize(w,0)
	 xIn = (xProj >= wDim) ? 0 : 1		//== 0 if x out of bounds, 1 if in- bounds
	 xIn = (xProj < 0) ? 0 : 1
	 yIn = (yProj >= wDim) ? 0 : 1		//== 0 if y out of bounds, 1 if in- bounds
	 yIn = (yProj < 0) ? 0 : 1
	//find the equation of the line Ax+By+C=0 (or mx - y + b = 0)
	Variable A,B,C
	
	if(xIn && yIn)		//normal connection
		A = (y2-y1)/(x2-x1)
		B = -1
		C = y1 - A*x1
		if (x1 == x2)	//special case of a vertical line
			A=1
			B=0
			C=-x1
		endif
		ConnectPoints2D(w, x1,y1,x2,y2,thick)		//do the normal connection
		return(1)
	endif
	//x,y or both are out-of bounds, find the intersecting point
	Variable xInt,yInt
	xInt = (x1+xProj)/2
	yInt = (y1+yProj)/2
	
	//*****still need to find the intersecting point and do the two fills
	
	
End

//distance between a point (x3,y3) and a line Ax + By + C = 0
Function Pt_Line_Distance2D(x3,y3,A,B,C)
	Variable x3,y3,A,B,C
	
	Variable dist
	
	dist = A*x3+B*y3+C
	dist /= sqrt(A*A+B*B)
	
	return(abs(dist))
End


Proc ConnectDots2DPeriodic()
	
	Variable num=numpnts(x2d),ii=0,thick=1,numToFind=1,nei=0
	Variable matSize=DimSize(plane,0),jj
	String list="",keyStr="",ghostStr=""
	ii=0
	do
		list = FindNearestNeighborPeriodic(x2d,y2d,ii,2,matSize,numToFind)
		print list
		jj=0
		do
			//get point from list
			keyStr = "N"+num2str(jj+1)
			nei = NumberByKey(keyStr, list , "=",";" )
//			keyStr = "G"+num2str(jj+1)
//			ghostStr = StringByKey(keyStr,list,"=",";")
			ConnectPoints2D(plane, x2D[ii],y2d[ii],x2D[nei],y2D[nei],thick)
//			ConnectPoints2DPeriodic(plane, x2D[ii],y2d[ii],x2D[nei],y2D[nei],thick,list,jj)
			jj+=1
		while(jj<numToFind)
		ii+=1
	while(ii<num)
//	while(ii<13)		//do only point zero
End

//
// ??? is this 3D or 2D  ?????
//
// find the numToFind nearest points to the input pt
//NEED to pass in maximum dimension of the matrix (assume it's square!)
// a KW=val string is returned
// returns: N1=...point number of 1st neighbor
// 			G1 = ...ghost type of neighbor n
//			D1.... distance
//			XY1.... X,Y pair (comma delimited of the actual point, may be a ghost)
Function/S FindNearestNeighborPeriodic(xw,yw,pt,num,matSize,numToFind)
	Wave xw,yw
	Variable pt,num,matSize,numToFind
		
	// look over a box +/-num around pt
	// using periodic conditions
	String ghostStr="",retStr="",pointList="",xyStr=""
	Variable boxDim
	
	// get a list of local points
	boxDim = num
	do
		pointList=ListPointsInBox(xw,yw,pt,boxDim,matSize)
		print pointList
		if ( ItemsInList(pointList ,";") >= numToFind )
			break
		endif
		boxDim += 5
	while(boxDim < matSize)
	Print "boxDim = ",boxDim
	
	//make waves to hold the answers
	Make/O/N=(ItemsInList(pointList ,";")) ptWave,distWave
	Make/O/T/N=(ItemsInList(pointList ,";")) ghostWave,xyWave
	//now calculate the distances
	Variable ii,dist,testPt

	for(ii=0;ii<ItemsInList(pointList ,";");ii+=1)
		testPt = str2num(StringFromList(ii,pointList,";"))
		if(testPt != pt)
			dist = Point2PointPeriodic(xw[pt],yw[pt],xw[testPt],yw[testPt],matSize,ghostStr,xyStr)
			ptWave[ii] = testPt
			distWave[ii] = dist
			ghostWave[ii] = ghostStr
			xyWave[ii] = xyStr
		endif
	endfor
	//sort by distance
	Sort distWave distWave,ptWave,ghostWave,xyWave
	// build the return string
	for(ii=0;ii<numToFind;ii+=1)
		retStr += "N"+num2str(ii+1)+"="+num2str(ptWave[ii])+";"		//point number
		retStr += "D"+num2str(ii+1)+"="+num2str(distWave[ii])+";"	//distance
		retStr += "G"+num2str(ii+1)+"="+ghostWave[ii]+";"
		retStr += "XY"+num2str(ii+1)+"="+xyWave[ii]+";"				//xy point, may be ghost
	endfor
	
	return (retStr)
End

Function/S ListPointsInBox(xw,yw,pt,num,matSize)
	Wave xw,yw
	Variable pt,num,matSize
	
	String list=""
	Variable left,right,top,bottom
	Variable ghostLeft,ghostRight,ghostTop,ghostBottom
	Variable ii
	
	left = xw[pt] - num
	if (left<0)
		ghostLeft=1
		left=0
	endif
	right = xw[pt]+num
	if(right>matSize-1)
		ghostRight=1
		right = matSize-1
	Endif
	bottom = yw[pt] - num
	if(bottom<0)
		ghostBottom=1
		bottom=0
	endif
	top = yw[pt] + num
	if(top>matSize-1)
		ghostTop=1
		top= matSize-1
	Endif
	
	//do the bit in the normal matrix using FindPointsInPoly
	Make/O/N=4 tempx={left,right,right,left}
	Make/O/N=4 tempy={bottom,bottom,top,top}
	list = GetPointsInBox(xw,yw,tempx,tempy,list)
	
	//do the "ghost regions" - there will be either 0,1, or 3
	//do each individually
	if(ghostLeft)
		Make/O/N=4 tempx={xw[pt]-num+matSize,matSize,matSize,xw[pt]-num+matSize}
		Make/O/N=4 tempy={bottom,bottom,top,top}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostRight)
		Make/O/N=4 tempx={0,xw[pt] +num - matSize, xw[pt] +num - matSize,0}
		Make/O/N=4 tempy={bottom,bottom,top,top}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostBottom)
		Make/O/N=4 tempx={left,right,right,left}
		Make/O/N=4 tempy={yw[pt]-num+matSize,yw[pt]-num+matSize,matSize,matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostTop)
		Make/O/N=4 tempx={left,right,right,left}
		Make/O/N=4 tempy={0,0,yw[pt] +num - matSize,yw[pt] +num - matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	// then do the diagonal, if necessary
	if(ghostLeft && ghostBottom)	
		Make/O/N=4 tempx={xw[pt]-num+matSize,matSize,matSize,xw[pt]-num+matSize}
		Make/O/N=4 tempy={yw[pt]-num+matSize,yw[pt]-num+matSize,matSize,matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostLeft && ghostTop)	
		Make/O/N=4 tempx={xw[pt]-num+matSize,matSize,matSize,xw[pt]-num+matSize}
		Make/O/N=4 tempy={0,0,yw[pt] +num - matSize,yw[pt] +num - matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostRight && ghostBottom)	
		Make/O/N=4 tempx={0,xw[pt] +num - matSize, xw[pt] +num - matSize,0}
		Make/O/N=4 tempy={yw[pt]-num+matSize,yw[pt]-num+matSize,matSize,matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	if(ghostRight && ghostTop)
		Make/O/N=4 tempx={0,xw[pt] +num - matSize, xw[pt] +num - matSize,0}
		Make/O/N=4 tempy={0,0,yw[pt] +num - matSize,yw[pt] +num - matSize}
		list = GetPointsInBox(xw,yw,tempx,tempy,list)
	endif
	//remove the original point
	list=RemoveFromList(num2str(pt), list ,";")
	return(list)
End

Function/S GetPointsInBox(xw,yw,tempx,tempy,list)
	Wave xw,yw,tempx,tempy
	String list
	
	FindPointsInPoly xw,yw,tempx,tempy
	Wave W_inPoly=W_inPoly
	
	Variable ii
	//scan through all the points
	for(ii=0;ii<numpnts(xw);ii+=1)
		if(W_inPoly[ii] == 1)
			list += num2str(ii) + ";"
		endif
	endfor
	
	return list
End

//find the distance between two points, allowing for periodic boundaries
// on a square grid of maxSize x maxSize
//
// consider x1 y1 as the fixed point
//
Function Point2PointPeriodic(x1,y1,x2,y2,maxSize,ghostStr,xyStr)
	Variable x1,y1,x2,y2,maxSize
	String &ghostStr,&xyStr
	
	Variable dist,dx,dy,tx,ty
	String tempStr=""
	
	dx = abs(x1-x2)
	dy = abs(y1-y2)
	
	// if dx is more than half of maxsize, pass through x (left) (right)
	tx = x2
	if (dx >= maxSize/2)
		if(x1 <= maxSize/2)
			// ghost x2 to the left
			tx = x2 - maxSize
			tempStr += "left"
		else
			//ghost x2 to the right
			tx = x2 + maxSize
			tempStr += "right"
		endif
	endif
	// if dy is more than half of maxSize, pass through y (bottom) (top)
	ty = y2
	if (dy >= maxSize/2)
		if(y1 <= maxSize/2)
			// ghost y2 to the bottom
			ty = y2 - maxSize
			tempStr += "bottom"
		else
			//ghost y2 to the top
			ty = y2 + maxSize
			tempStr += "top"
		endif
	endif
	//calculate the distance
	dist = sqrt( (tx-x1)^2 + (ty-y1)^2 )
//	Print "point2 = ",tx,ty,dist
//	Print tempStr
	ghostStr = tempStr
	xyStr = num2str(tx)+","+num2str(ty)
	return (dist)
end
