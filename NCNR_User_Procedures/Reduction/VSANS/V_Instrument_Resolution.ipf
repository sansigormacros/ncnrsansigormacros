#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


//
// resolution calculations for VSANS, under a variety of collimation conditions
//
// Partially converted (July 2017)
//
//
// -- still missing a lot of physical dimensions for the SANS (1D) case
// let alone anything more complex
//
//
// SANS-like (pinhole) conditions are largely copied from the SANS calcuations
// and are the traditional extra three columns
//
// Other conditions, such as white beam, or narrow slit mode, will likely require some
// format for the resolution information that is different than the three column format.
// The USANS solution of a "flag" is clunky, and depends entirely on the analysis package to 
// know exactly what to do.
//
// the 2D SANS-like resolution calculation is also expected to be similar to SANS, but is
// unverified at this point (July 2017). 2D errors are also unverified.
// -- Most importantly for 2D VSANS data, there is no defined output format.
//


// TODO:
// -- some of the input geometry is hidden in other locations:
// Sample Aperture to Gate Valve (cm)  == /instrument/sample_aperture/distance
// Sample [position] to Gate Valve (cm) = /instrument/sample_table/offset_distance
//
// -- the dimensions and the units for the beam stops are very odd, and what is written to the
//   file is not what is noted in the GUI - so verify the units that I'm actually reading.
// 




//**********************
// Resolution calculation - used by the averaging routines
// to calculate the resolution function at each q-value
// - the return value is not used
//
// equivalent to John's routine on the VAX Q_SIGMA_AVE.FOR
// Incorporates eqn. 3-15 from J. Appl. Cryst. (1995) v. 28 p105-114
//
// - 21 MAR 07 uses projected BS diameter on the detector
// - APR 07 still need to add resolution with lenses. currently there is no flag in the 
//          raw data header to indicate the presence of lenses.
//
// - Aug 07 - added input to switch calculation based on lenses (==1 if in)
//
// - called by CircSectAvg.ipf and RectAnnulAvg.ipf
//
// passed values are read from RealsRead
// except DDet and apOff, which are set from globals before passing
//
// DDet is the detector pixel resolution
// apOff is the offset between the sample aperture and the sample position
//
//
Function getResolution(inQ,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,SigmaQ,QBar,fSubS)
	Variable inQ, lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses
	Variable &fSubS, &QBar, &SigmaQ		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, q_small, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]


	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]
	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
	Variable LB
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	q_small = 2.0*Pi*(BS-a2)*(1.0-lambdaWidth)/(lambda*L2)
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
//	if(usingLenses==1)			//SRK 2007
	if(usingLenses != 0)			//SRK 2008 allows for the possibility of different numbers of lenses in header
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0			//the 2.3548 is a conversion from FWHM->Gauss, see http://mathworld.wolfram.com/GaussianFunction.html
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007

	r0 = L2*tan(2.0*asin(lambda*inQ/(4.0*Pi) ))
	delta = 0.5*(BS - r0)^2/v_d

	if (r0 < BS) 
		inc_gamma=exp(gammln(1.5))*(1-gammp(1.5,delta))
	else
		inc_gamma=exp(gammln(1.5))*(1+gammp(1.5,delta))
	endif

	fSubS = 0.5*(1.0+erf( (r0-BS)/sqrt(2.0*v_d) ) )
	if (fSubS <= 0.0) 
		fSubS = 1.e-10
	endif
	fr = 1.0 + sqrt(v_d)*exp(-1.0*delta) /(r0*fSubS*sqrt(2.0*Pi))
	fv = inc_gamma/(fSubS*sqrt(Pi)) - r0^2*(fr-1.0)^2/v_d

	rmd = fr*r0
	v_r1 = v_b + fv*v_d +v_g

	rm = rmd + 0.5*v_r1/rmd
	v_r = v_r1 - 0.5*(v_r1/rmd)^2
	if (v_r < 0.0) 
		v_r = 0.0
	endif
	QBar = (4.0*Pi/lambda)*sin(0.5*atan(rm/L2))
	SigmaQ = QBar*sqrt(v_r/rmd^2 +v_lambda)


// more readable method for calculating the variance in Q
// EXCEPT - this is calculated for Qo, NOT qBar
// (otherwise, they are nearly equivalent, except for close to the beam stop)
//	Variable kap,a_val,a_val_l2,m_h
//	g = 981.0				//gravity acceleration [cm/s^2]
//	m_h	= 252.8			// m/h [=] s/cm^2
//	
//	kap = 2*pi/lambda
//	a_val = L2*(L1+L2)*g/2*(m_h)^2
//	a_val_L2 = a_val/L2*1e-16		//convert 1/cm^2 to 1/A^2
//
//	sigmaQ = 0
//	sigmaQ = 3*(S1/L1)^2
//	
//	if(usingLenses != 0)
//		sigmaQ += 2*(S2/lp)^2*(lambdaWidth)^2	//2nd term w/ lenses
//	else	
//		sigmaQ += 2*(S2/lp)^2						//2nd term w/ no lenses
//	endif
//	
//	sigmaQ += (del_r/L2)^2
//	sigmaQ += 2*(r0/L2)^2*(lambdaWidth)^2
//	sigmaQ += 4*(a_val_l2)^2*lambda^4*(lambdaWidth)^2
//	
//	sigmaQ *= kap^2/12
//	sigmaQ = sqrt(sigmaQ)


	Return (0)
End


//
//**********************
// 2D resolution function calculation - ***NOT*** in terms of X and Y
// but written in terms of Parallel and perpendicular to the Q vector at each point
//
// -- it is more naturally written this way since the 2D function is an ellipse with its major
// axis pointing in the direction of Q_parallel. Hence there is no way to properly define the 
// elliptical gaussian in terms of sigmaX and sigmaY
//
// For a full description of the gravity effect on the resolution, see:
//
//	"The effect of gravity on the resolution of small-angle neutron diffraction peaks"
//	D.F.R Mildner, J.G. Barker & S.R. Kline J. Appl. Cryst. (2011). 44, 1127-1129.
//	[ doi:10.1107/S0021889811033322 ]
//
//		2/17/12 SRK
// 		NOTE: the first 2/3 of this code is the 1D code, copied here just to have the beam stop
// 				calculation here, if I decide to implement it. The real calculation is all at the 
//				bottom and is quite compact
//
//
//
//
// - 21 MAR 07 uses projected BS diameter on the detector
// - APR 07 still need to add resolution with lenses. currently there is no flag in the 
//          raw data header to indicate the presence of lenses.
//
// - Aug 07 - added input to switch calculation based on lenses (==1 if in)
//
// passed values are read from RealsRead
// except DDet and apOff, which are set from globals before passing
//
// phi is the azimuthal angle, CCW from +x axis
// r_dist is the real-space distance from ctr of detector to QxQy pixel location
//
// MAR 2011 - removed the del_r terms, they don't apply since no bining is done to the 2D data
//
Function get2DResolution(inQ,phi,lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses,r_dist,SigmaQX,SigmaQY,fSubS)
	Variable inQ, phi,lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses,r_dist
	Variable &SigmaQX,&SigmaQY,&fSubS		//these are the output quantities at the input Q value
	
	//lots of calculation variables
	Variable a2, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]
	Variable m_h	= 252.8			// m/h [=] s/cm^2


	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]
	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
	Variable LB
	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
	lp = 1.0/( 1.0/L1 + 1.0/L2)

	v_lambda = lambdaWidth^2/6.0
	
//	if(usingLenses==1)			//SRK 2007
	if(usingLenses != 0)			//SRK 2008 allows for the possibility of different numbers of lenses in header
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(2/3)*(lambdaWidth/lambda)^2*(S2*L2/lp)^2		//correction to 2nd term
	else
		v_b = 0.25*(S1*L2/L1)^2 +0.25*(S2*L2/lp)^2		//original form
	endif
	
	v_d = (DDet/2.3548)^2 + del_r^2/12.0
	vz = vz_1 / lambda
	yg = 0.5*g*L2*(L1+L2)/vz^2
	v_g = 2.0*(2.0*yg^2*v_lambda)					//factor of 2 correction, B. Hammouda, 2007

	r0 = L2*tan(2.0*asin(lambda*inQ/(4.0*Pi) ))
	delta = 0.5*(BS - r0)^2/v_d

	if (r0 < BS) 
		inc_gamma=exp(gammln(1.5))*(1-gammp(1.5,delta))
	else
		inc_gamma=exp(gammln(1.5))*(1+gammp(1.5,delta))
	endif

	fSubS = 0.5*(1.0+erf( (r0-BS)/sqrt(2.0*v_d) ) )
	if (fSubS <= 0.0) 
		fSubS = 1.e-10
	endif
//	fr = 1.0 + sqrt(v_d)*exp(-1.0*delta) /(r0*fSubS*sqrt(2.0*Pi))
//	fv = inc_gamma/(fSubS*sqrt(Pi)) - r0^2*(fr-1.0)^2/v_d
//
//	rmd = fr*r0
//	v_r1 = v_b + fv*v_d +v_g
//
//	rm = rmd + 0.5*v_r1/rmd
//	v_r = v_r1 - 0.5*(v_r1/rmd)^2
//	if (v_r < 0.0) 
//		v_r = 0.0
//	endif

	Variable kap,a_val,a_val_L2,proj_DDet
	
	kap = 2*pi/lambda
	a_val = L2*(L1+L2)*g/2*(m_h)^2
	a_val_L2 = a_val/L2*1e-16		//convert 1/cm^2 to 1/A^2


	// the detector pixel is square, so correct for phi
	proj_DDet = DDet*cos(phi) + DDet*sin(phi)


///////// OLD - don't use ---
//in terms of Q_parallel ("x") and Q_perp ("y") - this works, since parallel is in the direction of Q and I
// can calculate that from the QxQy (I just need the projection)
//// for test case with no gravity, set a_val = 0
//// note that gravity has no wavelength dependence. the lambda^4 cancels out.
////
////	a_val = 0
////	a_val_l2 = 0
//
//	
//	// this is really sigma_Q_parallel
//	SigmaQX = kap*kap/12 * (3*(S1/L1)^2 + 3*(S2/LP)^2 + (proj_DDet/L2)^2 + (sin(phi))^2*8*(a_val_L2)^2*lambda^4*lambdaWidth^2)
//	SigmaQX += inQ*inQ*v_lambda
//
//	//this is really sigma_Q_perpendicular
//	proj_DDet = DDet*sin(phi) + DDet*cos(phi)		//not necessary, since DDet is the same in both X and Y directions
//
//	SigmaQY = kap*kap/12 * (3*(S1/L1)^2 + 3*(S2/LP)^2 + (proj_DDet/L2)^2 + (cos(phi))^2*8*(a_val_L2)^2*lambda^4*lambdaWidth^2)
//	
//	SigmaQX = sqrt(SigmaQX)
//	SigmaQy = sqrt(SigmaQY)
//	

/////////////////////////////////////////////////
/////	
//	////// this is all new, inclusion of gravity effect into the parallel component
//       perpendicular component is purely geometric, no gravity component
//
// the shadow factor is calculated as above -so keep the above calculations, even though
// most of them are redundant.
//
	
////	//
	Variable yg_d,acc,sdd,ssd,lambda0,DL_L,sig_l
	Variable var_qlx,var_qly,var_ql,qx,qy,sig_perp,sig_para, sig_para_new
	
	G = 981.  //!	ACCELERATION OF GRAVITY, CM/SEC^2
	acc = vz_1 		//	3.956E5 //!	CONVERT WAVELENGTH TO VELOCITY CM/SEC
	SDD = L2		//1317
	SSD = L1		//1627 		//cm
	lambda0 = lambda		//		15
	DL_L = lambdaWidth		//0.236
	SIG_L = DL_L/sqrt(6)
	YG_d = -0.5*G*SDD*(SSD+SDD)*(LAMBDA0/acc)^2
/////	Print "DISTANCE BEAM FALLS DUE TO GRAVITY (CM) = ",YG
//		Print "Gravity q* = ",-2*pi/lambda0*2*yg_d/sdd
	
	sig_perp = kap*kap/12 * (3*(S1/L1)^2 + 3*(S2/LP)^2 + (proj_DDet/L2)^2)
	sig_perp = sqrt(sig_perp)
	
// TODO -- not needed???	
//	FindQxQy(inQ,phi,qx,qy)


// missing a factor of 2 here, and the form is different than the paper, so re-write	
//	VAR_QLY = SIG_L^2 * (QY+4*PI*YG_d/(2*SDD*LAMBDA0))^2
//	VAR_QLX = (SIG_L*QX)^2
//	VAR_QL = VAR_QLY + VAR_QLX  //! WAVELENGTH CONTRIBUTION TO VARIANCE
//	sig_para = (sig_perp^2 + VAR_QL)^0.5
	
	// r_dist is passed in, [=]cm
	// from the paper
	a_val = 0.5*G*SDD*(SSD+SDD)*m_h^2 * 1e-16		//units now are cm /(A^2)
	
	var_QL = 1/6*(kap/SDD)^2*(DL_L)^2*(r_dist^2 - 4*r_dist*a_val*lambda0^2*sin(phi) + 4*a_val^2*lambda0^4)
	sig_para_new = (sig_perp^2 + VAR_QL)^0.5
	
	
///// return values PBR	
	SigmaQX = sig_para_new
	SigmaQy = sig_perp
	
////	

	Return (0)
End






////////Transmission
//******************
//lookup tables for attenuator transmissions
//
//
// new calibration done June 2007, John Barker
//
Proc MakeNG3AttenTable()

	NewDataFolder/O root:myGlobals:Attenuators
	//do explicitly to avoid data folder problems, redundant, but it must work without fail
	Variable num=10		//10 needed for tables after June 2007

	Make/O/N=(num) root:myGlobals:Attenuators:ng3att0
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att1
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att2
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att3
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att4
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att5
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att6
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att7
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att8
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att9
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att10
	
	// and a wave for the errors at each attenuation factor
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att0_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att1_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att2_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att3_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att4_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att5_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att6_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att7_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att8_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att9_err
	Make/O/N=(num) root:myGlobals:Attenuators:ng3att10_err
	
	
	//each wave has 10 elements, the transmission of att# at the wavelengths 
	//lambda = 4,5,6,7,8,10,12,14,17,20 (4 A and 20 A are extrapolated values)
	Make/O/N=(num) root:myGlobals:Attenuators:ng3lambda={4,5,6,7,8,10,12,14,17,20}
	
	// new calibration done June 2007, John Barker
	root:myGlobals:Attenuators:ng3att0 = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
	root:myGlobals:Attenuators:ng3att1 = {0.444784,0.419,0.3935,0.3682,0.3492,0.3132,0.2936,0.2767,0.2477,0.22404}
	root:myGlobals:Attenuators:ng3att2 = {0.207506,0.1848,0.1629,0.1447,0.1292,0.1056,0.09263,0.08171,0.06656,0.0546552}
	root:myGlobals:Attenuators:ng3att3 = {0.092412,0.07746,0.06422,0.05379,0.04512,0.03321,0.02707,0.02237,0.01643,0.0121969}
	root:myGlobals:Attenuators:ng3att4 = {0.0417722,0.03302,0.02567,0.02036,0.01604,0.01067,0.00812,0.006316,0.00419,0.00282411}
	root:myGlobals:Attenuators:ng3att5 = {0.0187129,0.01397,0.01017,0.007591,0.005668,0.003377,0.002423,0.001771,0.001064,0.000651257}
	root:myGlobals:Attenuators:ng3att6 = {0.00851048,0.005984,0.004104,0.002888,0.002029,0.001098,0.0007419,0.0005141,0.000272833,0.000150624}
	root:myGlobals:Attenuators:ng3att7 = {0.00170757,0.001084,0.0006469,0.0004142,0.0002607,0.0001201,7.664e-05,4.06624e-05,1.77379e-05,7.30624e-06}
	root:myGlobals:Attenuators:ng3att8 = {0.000320057,0.0001918,0.0001025,6.085e-05,3.681e-05,1.835e-05,6.74002e-06,3.25288e-06,1.15321e-06,3.98173e-07}
	root:myGlobals:Attenuators:ng3att9 = {6.27682e-05,3.69e-05,1.908e-05,1.196e-05,8.738e-06,6.996e-06,6.2901e-07,2.60221e-07,7.49748e-08,2.08029e-08}
	root:myGlobals:Attenuators:ng3att10 = {1.40323e-05,8.51e-06,5.161e-06,4.4e-06,4.273e-06,1.88799e-07,5.87021e-08,2.08169e-08,4.8744e-09,1.08687e-09}
  
  // percent errors as measured, May 2007 values
  // zero error for zero attenuators, appropriate average values put in for unknown values
	root:myGlobals:Attenuators:ng3att0_err = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	root:myGlobals:Attenuators:ng3att1_err = {0.15,0.142,0.154,0.183,0.221,0.328,0.136,0.13,0.163,0.15}
	root:myGlobals:Attenuators:ng3att2_err = {0.25,0.257,0.285,0.223,0.271,0.405,0.212,0.223,0.227,0.25}
	root:myGlobals:Attenuators:ng3att3_err = {0.3,0.295,0.329,0.263,0.323,0.495,0.307,0.28,0.277,0.3}
	root:myGlobals:Attenuators:ng3att4_err = {0.35,0.331,0.374,0.303,0.379,0.598,0.367,0.322,0.33,0.35}
	root:myGlobals:Attenuators:ng3att5_err = {0.4,0.365,0.418,0.355,0.454,0.745,0.411,0.367,0.485,0.4}
	root:myGlobals:Attenuators:ng3att6_err = {0.45,0.406,0.473,0.385,0.498,0.838,0.454,0.49,0.5,0.5}
	root:myGlobals:Attenuators:ng3att7_err = {0.6,0.554,0.692,0.425,0.562,0.991,0.715,0.8,0.8,0.8}
	root:myGlobals:Attenuators:ng3att8_err = {0.7,0.705,0.927,0.503,0.691,1.27,1,1,1,1}
	root:myGlobals:Attenuators:ng3att9_err = {1,0.862,1.172,0.799,1.104,1.891,1.5,1.5,1.5,1.5}
	root:myGlobals:Attenuators:ng3att10_err = {1.5,1.054,1.435,1.354,1.742,2,2,2,2,2}
  

End





//returns the transmission of the attenuator (at NG3) given the attenuator number
//which must be an integer(to select the wave) and given the wavelength.
//the wavelength may be any value between 4 and 20 (A), and is interpolated
//between calibrated wavelengths for a given attenuator
//
// Mar 2010 - abs() added to attStr to account for ICE reporting -0.0001 as an attenuator position, which truncates to "-0"
Function LookupAttenNG3(lambda,attenNo,atten_err)
	Variable lambda, attenNo, &atten_err
	
	Variable trans
	String attStr="root:myGlobals:Attenuators:ng3att"+num2str(trunc(abs(attenNo)))
	String attErrWStr="root:myGlobals:Attenuators:ng3att"+num2str(trunc(abs(attenNo)))+"_err"
	String lamStr = "root:myGlobals:Attenuators:ng3lambda"
	
	if(attenNo == 0)
		return (1)		//no attenuation, return trans == 1
	endif
	
	if( (lambda < 4) || (lambda > 20 ) )
		Abort "Wavelength out of calibration range (4,20). You must manually enter the absolute parameters"
	Endif
	
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) || !(WaveExists($attErrWStr)))
		Execute "MakeNG3AttenTable()"
	Endif
	//just in case creating the tables fails....
	if(!(WaveExists($attStr)) || !(WaveExists($lamStr)) )
		Abort "Attenuator lookup waves could not be found. You must manually enter the absolute parameters"
	Endif
	
	//lookup the value by interpolating the wavelength
	//the attenuator must always be an integer
	Wave att = $attStr
	Wave attErrW = $attErrWStr
	Wave lam = $lamstr
	trans = interp(lambda,lam,att)
	atten_err = interp(lambda,lam,attErrW)

// the error in the tables is % error. return the standard deviation instead
	atten_err = trans*atten_err/100
		
//	Print "trans = ",trans
//	Print "trans err = ",atten_err
	
	return trans
End




// a utility function so that I can get the values from the command line
// since the atten_err is PBR
//
Function PrintAttenuation(instr,lam,attenNo)
	String instr
	Variable lam,attenNo
	
	Variable atten_err, attenFactor
	
	// 22 FEB 2013 - not sure what changed with the writeout of ICE data files... but ....
	// to account for ICE occasionally writing out "3" as 2.9998, make sure I can construct
	// a single digit -> string "3" to identify the proper wave in the lookup table
	
	attenNo = round(attenNo)
	
	strswitch(instr)
		case "CGB":
		case "NG3":
			attenFactor = LookupAttenNG3(lam,attenNo,atten_err)
			break
		default:							
			//return error?
			DoAlert 0, "No matching instrument -- PrintAttenuation"
			attenFactor=1
	endswitch

	Print "atten, err = ", attenFactor, atten_err
	
	return(0)
End


//
//returns the proper attenuation factor based on the instrument (NG3, NG5, or NG7)
//NG5 values are taken from the NG7 tables (there is very little difference in the
//values, and NG5 attenuators have not been calibrated (as of 8/01)
//
// filestr is passed from TextRead[3] = the default directory
// lam is passed from RealsRead[26]
// AttenNo is passed from ReaslRead[3]
//
// Attenuation factor as defined here is <= 1
//
// HFIR can pass ("",1,attenuationFactor) and have this function simply
// spit back the attenuationFactor (that was read into rw[3])
//
// called by Correct.ipf, ProtocolAsPanel.ipf, Transmission.ipf
//
//
// as of March 2011, returns the error (one standard deviation) in the attenuation factor as the last parameter, by reference
Function AttenuationFactor(fileStr,lam,attenNo,atten_err)
	String fileStr
	Variable lam,attenNo, &atten_err
	
	Variable attenFactor=1,loc
	String instr=fileStr[1,3]	//filestr is "[NGnSANSn] " or "[NGnSANSnn]" (11 characters total)


	// 22 FEB 2013 - not sure what changed with the writeout of ICE data files... but ....
	// to account for ICE occasionally writing out "3" as 2.9998, make sure I can construct
	// a single digit -> string "3" to identify the proper wave in the lookup table
	
	attenNo = round(attenNo)
	
		
	strswitch(instr)
		case "CGB":
		case "NG3":
			attenFactor = LookupAttenNG3(lam,attenNo,atten_err)
			break
		default:							
			//return error?
			DoAlert 0, "No matching instrument -- PrintAttenuation"
			attenFactor=1
	endswitch
//	print "instr, lambda, attenNo,attenFactor = ",instr,lam,attenNo,attenFactor
	return(attenFactor)
End


