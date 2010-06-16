#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1



// there are utlity functions here (commented out) for plotting the 2D resolution function
// at any point on the detector


// I can only calculate (nord) points in an AAO fashion, so threading the function calculation
// doesn't help. Even if I can rewrite this to calculate nord*nord AAO, that will typically be 10*10=100
// and that is not enough points to thread with any benefit

// but the calculation of each q value is independent, so I can split the total number of q-values between processors
//
// -- but I must be careful to pass this a function that is not already threaded!
// --- BUT - I can't pass either a function reference, OR a structure to a thread!
// ---- So sadly, each 2D resolution calculation must be threaded by hand.
//
// See the Sphere_2D function for an example of how to thread the smearing
//
//
// SRK May 2010

//
// NOTE: there is a definition of FindTheta = -1* FindPhi() that is a duplicate of what is in RawWindowHook.ipf
// and should eventually be in a common location for analysis and reduction packages
//


//// this is the completely generic 2D smearing, not threaded, but takes FUNCREF and STRUCT parameters
//
// uses resolution ellipse defined perpendicular "Y" and parallel "X",
// rotating the ellipse into its proper orientaiton based on qx,qy
//
// 5 gauss points is not enough - it gives artifacts as a function of phi
// 10 gauss points is minimally sufficient
// 20 gauss points are needed if lots of oscillations (just like in 1D)
// even more may be necessary for highly peaked functions
//
//
Function Smear_2DModel_PP(fcn,s,nord)
	FUNCREF SANS_2D_ModelAAO_proto fcn
	Struct ResSmear_2D_AAOStruct &s
	Variable nord
	
	String weightStr,zStr

	Variable ii,jj,kk,num
	Variable qx,qy,qz,qval,fs
	Variable qy_pt,qx_pt,res_x,res_y,answer,sumIn,sumOut
	
	Variable a,b,c,normFactor,phi,theta,maxSig,numStdDev=3
	
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
			Abort "Smear_2DModel_PP called with invalid nord value"					
	endswitch
	
	Wave/Z wt = $weightStr
	Wave/Z xi = $zStr
	
/// keep these waves local
//	Make/O/D/N=1 yPtW
	Make/O/D/N=(nord) fcnRet,xptW,res_tot,yptW
	
	// now just loop over the points as specified
	num=numpnts(s.xw[0])
	
	answer=0
	
	Variable spl,spp,apl,app,bpl,bpp,phi_pt,qpl_pt
	Variable t1=StopMSTimer(-2)

	//loop over q-values
	for(ii=0;ii<num;ii+=1)
	
//		if(mod(ii, 1000 ) == 0)
//			Print "ii= ",ii
//		endif
		
		qx = s.xw[0][ii]
		qy = s.xw[1][ii]
		qz = s.qz[ii]
		qval = sqrt(qx^2+qy^2+qz^2)
		spl = s.sQpl[ii]
		spp = s.sQpp[ii]
		fs = s.fs[ii]
		
		normFactor = 2*pi*spl*spp
		
		phi = -1*FindTheta(qx,qy) 		//Findtheta is an exact duplicate of FindPhi() * -1
		
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
			
			fcn(s.coefW,fcnRet,xptw,yptw)			//calculate nord pts at a time
			
			//sumIn += wt[jj]*wt[kk]*res_tot*fcnRet[0]
			fcnRet *= wt[jj]*wt*res_tot
			//
			answer += (bpl-apl)/2.0*sum(fcnRet)		//
		endfor

		answer *= (bpp-app)/2.0
		s.zw[ii] = answer
	endfor
	
	Variable elap = (StopMSTimer(-2) - t1)/1e6
	Print "elapsed time = ",elap
	
	return(0)
end





//phi is defined from +x axis, proceeding CCW around [0,2Pi]
//rotate the resolution function by theta,  = -phi
//
// this is only different by (-1) from FindPhi
// I'd just call FindPhi, but it's awkward to include
//
Threadsafe Function FindTheta(vx,vy)
	variable vx,vy

	
	return(-1 * FindPhi(vx,vy))
end



	
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
/// utility functions to test the calculation of the resolution function and 
//	 plotting of it for visualization
//
// -- these need to have the reduction package included for it to compile
//
// this works with the raw 2D data, calculating resolution in place
// type is "RAW"
// xx,yy are in detector coordinates
//
// call as: 
// PlotResolution_atPixel("RAW",pcsr(A),qcsr(A))
//
// then:
// Display;AppendImage res;AppendMatrixContour res;ModifyContour res labels=0,autoLevels={*,*,3}
// 

//Function PlotResolution_atPixel(type,xx,yy)
//	String type
//	Variable xx,yy
//	
/////from QxQyExport
//	String destStr="",typeStr=""
//	Variable step=1,refnum
//	destStr = "root:Packages:NIST:"+type
//	
//	//must select the linear_data to export
//	NVAR isLog = $(destStr+":gIsLogScale")
//	if(isLog==1)
//		typeStr = ":linear_data"
//	else
//		typeStr = ":data"
//	endif
//	
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
//	
//	Wave data=$(destStr+typeStr)
//	WAVE intw=$(destStr + ":integersRead")
//	WAVE rw=$(destStr + ":realsRead")
//	WAVE/T textw=$(destStr + ":textRead")
//	
////	Duplicate/O data,qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
//	Variable qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
//
//	Variable xctr,yctr,sdd,lambda,pixSize
//	xctr = rw[16]
//	yctr = rw[17]
//	sdd = rw[18]
//	lambda = rw[26]
//	pixSize = rw[13]/10		//convert mm to cm (x and y are the same size pixels)
//	
////	qx_val = CalcQx(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)		//+1 converts to detector coordinate system
////	qy_val = CalcQy(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
//	
//	qx_val = CalcQx(xx+1,yy+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)		//+1 converts to detector coordinate system
//	qy_val = CalcQy(xx+1,yy+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
//	
////	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val
//
/////************
//// do everything to write out the resolution too
//	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
//	qval = CalcQval(xx+1,yy+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
//	qz_val = CalcQz(xx+1,yy+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
//	phi = FindPhi( pixSize*((xx+1)-xctr) , pixSize*((yy+1)-yctr))		//(dx,dy)
//	r_dist = sqrt(  (pixSize*((xx+1)-xctr))^2 +  (pixSize*((yy+1)-yctr))^2 )		//radial distance from ctr to pt
////	Redimension/N=(pixelsX*pixelsY) qz_val,qval,phi,r_dist
//	//everything in 1D now
////	Duplicate/O qval SigmaQX,SigmaQY,fsubS
//	Variable SigmaQX,SigmaQY,fsubS
//
//	Variable L2 = rw[18]
//	Variable BS = rw[21]
//	Variable S1 = rw[23]
//	Variable S2 = rw[24]
//	Variable L1 = rw[25]
//	Variable lambdaWidth = rw[27]	
//	Variable usingLenses = rw[28]		//new 2007
//
//	//Two parameters DDET and APOFF are instrument dependent.  Determine
//	//these from the instrument name in the header.
//	//From conversation with JB on 01.06.99 these are the current good values
//	Variable DDet
//	NVAR apOff = root:myGlobals:apOff		//in cm
//	DDet = rw[10]/10			// header value (X) is in mm, want cm here
//
//	Variable ret1,ret2,ret3,del_r
//	del_r = rw[10]
//	
//	get2DResolution(qval,phi,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,r_dist,ret1,ret2,ret3)
//	SigmaQX = ret1	
//	SigmaQY = ret2	
//	fsubs = ret3	
///////
//
////	Variable theta,phi,qx,qy,sx,sy,a,b,c,val,ii,jj,num=15,x0,y0
//	Variable theta,qx,qy,sx,sy,a,b,c,val,ii,jj,num=15,x0,y0,maxSig,nStdDev=3,normFactor
//	Variable qx_ret,qy_ret
//	
////	theta = FindPhi(qx_val,qy_val)
//// need to rotate properly - theta is defined a starting from +y axis, moving CW
//// we define phi starting from +x and moving CCW
//	theta = -phi			//seems to give the right behavior...
//	
//	
//	Print qx_val,qy_val,qval
//	Print "phi, theta",phi,theta
//	
//	FindQxQy(qval,phi,qx_ret,qy_ret)
//	
//	sx = SigmaQx
//	sy = sigmaQy
//	x0 = qx_val
//	y0 = qy_val
//	
//	a = cos(theta)^2/(2*sx*sx) + sin(theta)^2/(2*sy*sy)
//	b = -1*sin(2*theta)/(4*sx*sx) + sin(2*theta)/(4*sy*sy)
//	c = sin(theta)^2/(2*sx*sx) + cos(theta)^2/(2*sy*sy)
//	
//	normFactor = pi/sqrt(a*c-b*b)
//
//	Make/O/D/N=(num,num) res
//	// so the resolution function 'looks right' on a 2D plot - otherwise it always looks like a circle
//	maxSig = max(sx,sy)
//	Setscale/I x -nStdDev*maxSig+x0,nStdDev*maxSig+x0,res
//	Setscale/I y -nStdDev*maxSig+y0,nStdDev*maxSig+y0,res
////	Setscale/I x -nStdDev*sx+x0,nStdDev*sx+x0,res
////	Setscale/I y -nStdDev*sy+y0,nStdDev*sy+y0,res
//	
//	Variable xPt,yPt,delx,dely,offx,offy
//	delx = DimDelta(res,0)
//	dely = DimDelta(res,1)
//	offx = DimOffset(res,0)
//	offy = DimOffset(res,1)
//
//	Print "sx,sy = ",sx,sy
//	for(ii=0;ii<num;ii+=1)
//		xPt = offx + ii*delx
//		for(jj=0;jj<num;jj+=1)
//			yPt = offy + jj*dely
//			res[ii][jj] = exp(-1*(a*(xPt-x0)^2 + 2*b*(xPt-x0)*(yPt-y0) + c*(yPt-y0)^2))
//		endfor
//	endfor	
//	res /= normFactor
//	
//	//Print sum(res,-inf,inf)*delx*dely
//	if(WaveExists($"coef")==0)
//		Make/O/D/N=6 coef
//	endif
//	Wave coef=coef
//	coef[0] = 1
//	coef[1] = qx_val
//	coef[2] = qy_val
//	coef[3] = sx
//	coef[4] = sy
//	coef[5] = theta
//
////	Variable t1=StopMSTimer(-2)
//
////
////	do2dIntegrationGauss(-nStdDev*maxSig+x0,nStdDev*maxSig+x0,-nStdDev*maxSig+y0,nStdDev*maxSig+y0)
////
//
////	Variable elap = (StopMSTimer(-2) - t1)/1e6
////	Print "elapsed time = ",elap
////	Print "time for 16384 = (minutes)",16384*elap/60
//	return(0)
//End


//// this is called each time to integrate the gaussian
//Function do2dIntegrationGauss(xMin,xMax,yMin,yMax)
//	Variable xMin,xMax,yMin,yMax
//	
//	Variable/G globalXmin=xMin
//	Variable/G globalXmax=xMax
//	Variable/G globalY
//			
//	Variable result=Integrate1d(Gauss2DFuncOuter,yMin,yMax,2,5)	   
//	KillVariables/z globalXmax,globalXmin,globalY
//	print "integration of 2D = ",result
//End
//
//Function Gauss2DFuncOuter(inY)
//	Variable inY
//	
//	NVAR globalXmin,globalXmax,globalY
//	globalY=inY
//	
//	return integrate1D(Gauss2DFuncInner,globalXmin,globalXmax,2,5)		
//End
//
//Function Gauss2DFuncInner(inX)
//	Variable inX
//	
//	NVAR globalY
//	Wave coef=coef
//	
//	return Gauss2D_theta(coef,inX,GlobalY)
//End
//
//Function Gauss2D_theta(w,x,y)
//	Wave w
//	Variable x,y
//	
//	Variable val,a,b,c
//	Variable scale,x0,y0,sx,sy,theta,normFactor
//	
//	scale = w[0]
//	x0 = w[1]
//	y0 = w[2]
//	sx = w[3]
//	sy = w[4]
//	theta = w[5]
//	
//	a = cos(theta)^2/(2*sx*sx) + sin(theta)^2/(2*sy*sy)
//	b = -1*sin(2*theta)/(4*sx*sx) + sin(2*theta)/(4*sy*sy)
//	c = sin(theta)^2/(2*sx*sx) + cos(theta)^2/(2*sy*sy)
//	
//	val = exp(-1*(a*(x-x0)^2 + 2*b*(x-x0)*(y-y0) + c*(y-y0)^2))
//	
//	normFactor = pi/sqrt(a*c-b*b)
//	
//	return(scale*val/normFactor)
//end
//
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
