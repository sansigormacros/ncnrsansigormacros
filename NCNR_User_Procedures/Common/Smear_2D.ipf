#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

Function TestSmear_2D()

	Variable DX,NUM,X0,Y0,L1,L2,S1,S2,SIG_DET,DLAMB,LAMBDA
	DX = 0.5
	num = 128
//	x0 = 64
	x0 = 114
	y0 = 64
	L1 = 300		//units of cm ??
	L2 = 130
	s1 = 5.0/2
	s2 = 1.27/2
	sig_det = 0.5			//not sure about this
	dlamb = 0.15
	lambda = 6
	
	Duplicate/O root:no_gravity_dat:no_gravity_dat_mat root:no_gravity_dat:John_mat
	Wave data=root:no_gravity_dat:John_mat
	
	SUB_SMEAR_2D(DX,NUM,X0,Y0,L1,L2,S1,S2,SIG_DET,DLAMB,LAMBDA,DATA)
	
	Duplicate/O root:no_gravity_dat:John_mat root:no_gravity_dat:John_mat_log
	Wave log_data=root:no_gravity_dat:John_mat_log
	
	log_data = log(data)
	
end

// I have changed the array indexing to [0,], so subtract 1 from the x0,Y0 center 
// to shift from detector coordinates to Igor array index
//
//
// !! the wi values do not match what is written in John's notebook. Are these the 
// correct values for hermite integration??
//
Function SUB_SMEAR_2D(DX,NUM,X0,Y0,L1,L2,S1,S2,SIG_DET,DLAMB,LAMBDA,DATA)		//,Q_MODEL_NAME)
	Variable DX,NUM,X0,Y0,L1,L2,S1,S2,SIG_DET,DLAMB,LAMBDA
	Wave data
	
	Variable I,J,KI,KJ		//integers
	Variable SUMm,THET0,Q0,R_PL,R_PD,Q0_PL,Q0_PD,LP,V_R,V_L
	Variable PHI,R0,SIGQ_R,SIGQ_A,Q_PL,Q_PD,DIF_PD_I
	Variable RES_I,RES_J,RES,DIF_PL_J,DIF_PD_J,DIF_PL_I
//	DIMENSION DATA(128,128),XI(3),WI(3)
//	EXTERNAL Q_MODEL_NAME
//	PARAMETER PI = 3.14159265
	Variable N_QUAD = 3
	Make/O/D xi_h = {.6167065887,1.889175877,3.324257432}
	Make/O/D wi_h = {.72462959522,.15706732032,.45300099055E-2}
	
//C	DATA XI/.4360774119,1.3358490740,2.3506049736/
//	DATA XI/.6167065887,1.889175877,3.324257432/
//	DATA WI/.72462959522,.15706732032,.45300099055E-2/
//C	DX :	PIXEL SIZE, CM
//C	NUM:	NUMBER OF PIXELS ACROSS DETECTOR. (128)
//C	X0,Y0:	BEAM CENTER, IN UNITS OF PIXELS.
//C	L1:	SOURCE TO SAMPLE DISTANCE.
//C	L2:	SAMPLE TO DETECTOR DISTANCE.
//C	S1:	SOURCE APERTURE RADIUS.
//C	S2:	SAMPLE APERTURE RADIUS.
//C	SIG_DET:STANDARD DEVIATION OF DETECTOR SPATIAL RESOLUTION.
//C	DLAMB:	FWHM WAVLENGTH RESOLUTION.
//C	LAMBDA: MEAN WAVELENGTH.
//C	DATA:   OUTPUT SMEARED ARRAY (NUM,NUM)

	Make/O/D/N=(128,128) sigQR, sigQA


	LP = 1 / ( 1/L1 + 1/L2 )
	V_R = 0.25*(S1/L1)^2 + 0.25*(S2/LP)^2 + (SIG_DET/L2)^2
	V_L = DLAMB^2/6.
	for(i=0;i<num;i+=1)
	  R_PL = DX*(I-X0)
	  for(j=0;j<num;j+=1)
	    R_PD = DX*(J-Y0)
	    PHI = ATAN(R_PD/R_PL)		//do I need atan2 here?
	    R0 = SQRT(R_PL^2+R_PD^2)
	    THET0 = ATAN(R0/L2)
	    Q0 = 4*PI*SIN(0.5*THET0)/LAMBDA
//C	DETERMINE Q VECTOR, CARTESIAN REPRESENTATION.
	    Q0_PL = Q0*COS(PHI)
	    Q0_PD = Q0*SIN(PHI)
//C	DETERMINE SIGMA'S FOR RESOLUTION FUNCTION, RADIALLY, AZIMUTHAL
	    SIGQ_R = Q0*SQRT(V_R+V_L)
	    SIGQ_A = Q0*SQRT(V_R)
	    
		 sigQR[i][j] = sigq_R
		 sigQA[i][j] = sigq_A

	    SUMm = 0.0
	    for(KI=0;ki<N_quad;ki+=1)
	      DIF_PL_I = SIGQ_R*COS(PHI)*xi_h[ki]
	      DIF_PD_I = SIGQ_R*SIN(PHI)*xi_h[ki]
	      for( KJ=0;kj<N_QUAD;kj+=1)
				DIF_PL_J = SIGQ_A*SIN(PHI)*xi_h[kj]
				DIF_PD_J = SIGQ_A*COS(PHI)*xi_h[kj]
		//C		-,-
				Q_PL = Q0_PL - DIF_PL_I - DIF_PL_J
				Q_PD = Q0_PD - DIF_PD_I - DIF_PD_J
				SUMm = SUMm + wi_h[ki]*wi_h[kj]*I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)		
		//C		-,+
				Q_PL = Q0_PL - DIF_PL_I + DIF_PL_J
				Q_PD = Q0_PD - DIF_PD_I + DIF_PD_J
				SUMm = SUMm + wi_h[ki]*wi_h[kj]*I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)		
		//C		+,-
				Q_PL = Q0_PL + DIF_PL_I - DIF_PL_J
				Q_PD = Q0_PD + DIF_PD_I - DIF_PD_J
				SUMm = SUMm + wi_h[ki]*wi_h[kj]*I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)		
		//C		+,+
				Q_PL = Q0_PL + DIF_PL_I + DIF_PL_J
				Q_PD = Q0_PD + DIF_PD_I + DIF_PD_J
				SUMm = SUMm + wi_h[ki]*wi_h[kj]*I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)		
	        endfor	//   KJ
	    endfor  // KI
	    DATA[i][j] = SUMm / PI
	  endfor  //   J
	endfor  // I
	
	RETURN(0)

END

/// --- either way, same to machine precision
Function I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)
	Variable Q_PL,Q_PD
	
	Variable I_MACRO,Q,PHI,PHI_MODEL,NU
	
	//Q_MODEL_NAME
	//eccentricity factor for ellipse in John's code...
	NU = 1
	
//C	PHI = ATAN(Q_PD/Q_PL)

	Q = SQRT((NU*Q_PD)^2+Q_PL^2)
	
	WAVE cw = $"root:coef_Peak_Gauss"
	
	I_MACRO = Peak_Gauss_modelX(cw,Q)
//	I_MACRO = Q_MODEL_NAME(Q)
	
	RETURN(I_MACRO)
END

//Function I_MACRO(Q_PL,Q_PD)		//,Q_MODEL_NAME)
//	Variable Q_PL,Q_PD
//	
//	Variable I_MACRO
//	
//	Make/O/D/N=1 fcnRet,xptW,yPtw
//	xptw[0] = q_pl
//	yptw[0] = q_pd
//
//	WAVE cw = $"root:coef_sf"
//
//	I_MACRO = Sphere_2DX(cw,xptw,yptw)
//	
//	RETURN(I_MACRO)
//END

////Structure ResSmear_2D_AAOStruct
////	Wave coefW
////	Wave zw			//answer
////	Wave qy			// q-value
////	Wave qx
////	Wave qz
////	Wave sigQx		//resolution
////	Wave sigQy
////	Wave fs
////	String info
////EndStructure
//
Function Smear_2DModel_5(fcn,s)
	FUNCREF SANS_2D_ModelAAO_proto fcn
	Struct ResSmear_2D_AAOStruct &s
	
	String weightStr="gauss5wt",zStr="gauss5z"
	Variable nord=5

//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave wt = $weightStr
		Wave xi = $zStr		// wave references to pass
		Make5GaussPoints(wt,xi)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave wt = $weightStr
		Wave xi = $zStr		// create the wave references
	endif
	
	Variable ii,jj,kk,ax,bx,ay,by,num
	Variable qx,qy,qz,qval,sqx,sqy,fs
	Variable qy_pt,qx_pt,res_x,res_y,res_tot,answer,sumIn,sumOut
	num=numpnts(s.qx)
	
	// end points of integration
	// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
	// +/- 3 sigq catches 99.73% of distrubution
	// change limits (and spacing of zi) at each evaluation based on R()
	//integration from va to vb
	Make/O/D/N=1 fcnRet,xptW,yPtw
	
	answer=0
	//loop over q-values
	for(ii=0;ii<num;ii+=1)
		qx = s.qx[ii]
		qy = s.qy[ii]
		qz = s.qz[ii]
		qval = sqrt(qx^2+qy^2+qz^2)
		sqx = s.sigQx[ii]
		sqy = s.sigQy[ii]
		fs = s.fs[ii]
		
		ax = -3*sqx + qx		//qx integration limits
		bx = 3*sqx + qx
		ay = -3*sqy + qy		//qy integration limits
		by = 3*sqy + qy
		
		// 5-pt quadrature loops
		sumOut = 0
		for(jj=0;jj<nord;jj+=1)		// call qy the "outer'
			qy_pt = (xi[jj]*(by-ay)+ay+by)/2
			res_y = exp((-1*(qy - qy_pt)^2)/(2*sqy*sqy))

			sumIn=0
			for(kk=0;kk<nord;kk+=1)

				qx_pt = (xi[kk]*(bx-ax)+ax+bx)/2
				res_x = exp((-1*(qx - qx_pt)^2)/(2*sqx*sqx))
				
				res_tot = res_x*res_y/(2*pi*sqx*sqy)
				xptw[0] = qx_pt
				yptw[0] = qy_pt
				fcn(s.coefW,fcnRet,xptw,yptw)			//fcn passed in is an AAO
				sumIn += wt[jj]*wt[kk]*res_tot*fcnRet[0]
			endfor
			answer += (bx-ax)/2.0*sumIn		//this is NOT the right normalization
		endfor

		answer *= (by-ay)/2.0
		s.zw[ii] = answer
//		s.zw[ii] = sumIn
	endfor
	
	
	return(0)
end

Function Smear_2DModel_20(fcn,s)
	FUNCREF SANS_2D_ModelAAO_proto fcn
	Struct ResSmear_2D_AAOStruct &s
	
	String weightStr="gauss20wt",zStr="gauss20z"
	Variable nord=20

//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave wt = $weightStr
		Wave xi = $zStr		// wave references to pass
		Make20GaussPoints(wt,xi)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave wt = $weightStr
		Wave xi = $zStr		// create the wave references
	endif
	
	Variable ii,jj,kk,ax,bx,ay,by,num
	Variable qx,qy,qz,qval,sqx,sqy,fs
	Variable qy_pt,qx_pt,res_x,res_y,res_tot,answer,sumIn,sumOut
	num=numpnts(s.qx)
	
	// end points of integration
	// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
	// +/- 3 sigq catches 99.73% of distrubution
	// change limits (and spacing of zi) at each evaluation based on R()
	//integration from va to vb
	Make/O/D/N=1 fcnRet,xptW,yPtw
	
	answer=0
	//loop over q-values
	for(ii=0;ii<num;ii+=1)
		qx = s.qx[ii]
		qy = s.qy[ii]
		qz = s.qz[ii]
		qval = sqrt(qx^2+qy^2+qz^2)
		sqx = s.sigQx[ii]
		sqy = s.sigQy[ii]
		fs = s.fs[ii]
		
		ax = -3*sqx + qx		//qx integration limits
		bx = 3*sqx + qx
		ay = -3*sqy + qy		//qy integration limits
		by = 3*sqy + qy
		
		// 20-pt quadrature loops
		sumOut = 0
		for(jj=0;jj<nord;jj+=1)		// call qy the "outer'
			qy_pt = (xi[jj]*(by-ay)+ay+by)/2
			res_y = exp((-1*(qy - qy_pt)^2)/(2*sqy*sqy))

			sumIn=0
			for(kk=0;kk<nord;kk+=1)

				qx_pt = (xi[kk]*(bx-ax)+ax+bx)/2
				res_x = exp((-1*(qx - qx_pt)^2)/(2*sqx*sqx))
				
				res_tot = res_x*res_y/(2*pi*sqx*sqy)
				xptw[0] = qx_pt
				yptw[0] = qy_pt
				fcn(s.coefW,fcnRet,xptw,yptw)			//fcn passed in is an AAO
				sumIn += wt[jj]*wt[kk]*res_tot*fcnRet[0]
			endfor
			answer += (bx-ax)/2.0*sumIn		//this is NOT the right normalization
		endfor

		answer *= (by-ay)/2.0
		s.zw[ii] = answer
//		s.zw[ii] = sumIn
	endfor
	
	
	return(0)
end