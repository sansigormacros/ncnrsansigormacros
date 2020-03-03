#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 7.00


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
// - SANS -- called by CircSectAvg.ipf and RectAnnulAvg.ipf
//
// - VSANS -- called in VC_fDoBinning_QxQy2D(folderStr, binningType)
//
// DDet is the detector pixel resolution
// apOff is the offset between the sample aperture and the sample position
//
//
// INPUT:
// inQ = q-value [1/A]
// folderStr = folder with the current reduction step
// type = binning type (not the same as the detStr)
// collimationStr = collimation type, to switch for lenses, etc.

// READ/DERIVED within the function
// lambda = wavelength [A]
// lambdaWidth = [dimensionless]
// DDet = detector pixel resolution [cm]	**assumes square pixel
// apOff = sample aperture to sample distance [cm]
// S1 = source aperture diameter [mm]
// S2 = sample aperture diameter [mm]
// L1 = source to sample distance [m] 
// L2 = sample to detector distance [m]
// BS = beam stop diameter [mm]
// del_r = step size [mm] = binWidth*(mm/pixel) 
// usingLenses = flag for lenses = 0 if no lenses, non-zero if lenses are in-beam
//
// OUPUT:
// SigmaQ
// QBar
// fSubS
//
//
Function V_getResolution(inQ,folderStr,type,collimationStr,SigmaQ,QBar,fSubS)
	Variable inQ
	String folderStr,type,collimationStr
	Variable &SigmaQ, &QBar, &fSubS		//these are the output quantities at the input Q value

	Variable isVCALC
	if(cmpstr(folderStr,"VCALC") == 0)
		isVCALC = 1
	endif

	Variable lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses
		
	//lots of calculation variables
	Variable a2, q_small, lp, v_lambda, v_b, v_d, vz, yg, v_g
	Variable r0, delta, inc_gamma, fr, fv, rmd, v_r1, rm, v_r

	//Constants
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]

///////// get all of the values from the header
// TODO: check the units of all of the inputs
// lambda = wavelength [A]
	if(isVCALC)
		lambda = VCALC_getWavelength()
	else
		lambda = V_getWavelength(folderStr)
	endif
	
// lambdaWidth = [dimensionless]
	if(isVCALC)
		lambdaWidth = VCALC_getWavelengthSpread()
	else
		lambdaWidth = V_getWavelength_spread(folderStr)
	endif
	
// DDet = detector pixel resolution [cm]	**assumes square pixel
	// V_getDet_pixel_fwhm_x(folderStr,detStr)
	// V_getDet_pixel_fwhm_y(folderStr,detStr)
//	DDet = 0.8		// TODO -- this is hard-wired

	if(isVCALC)
		if(strlen(type) == 1)
			// it's "B"
			DDet = VCALC_getPixSizeX(type)		// value is already in cm
		else
			DDet = VCALC_getPixSizeX(type[0,1])		// value is already in cm
		endif		
	else
		if(strlen(type) == 1)
			// it's "B"
			DDet = V_getDet_pixel_fwhm_x(folderStr,type)		// value is already in cm
		else
			DDet = V_getDet_pixel_fwhm_x(folderStr,type[0,1])		// value is already in cm
		endif		
	endif	
// apOff = sample aperture to sample distance [cm]
	apOff = 10		// TODO -- this is hard-wired


// S1 = source aperture diameter [mm]
// may be either circle or rectangle
	String s1_shape="",bs_shape=""
	Variable width,height,equiv_S1,equiv_bs
	
	if(isVCALC)
		S1 = VC_sourceApertureDiam()*10		//VCALC is in cm, conver to [mm]
	else
		s1_shape = V_getSourceAp_shape(folderStr)
		if(cmpstr(s1_shape,"CIRCLE") == 0)
			S1 = str2num(V_getSourceAp_size(folderStr))
		else
			S1 = V_getSourceAp_height(folderStr)		// TODO: need the width or at least an equivalent diameter
		endif
	endif
	
// S2 = sample aperture diameter [cm]
// as of 3/2018, the "internal" sample aperture is not in use, only the external
// TODO : verify the units on the Ap2 (external)
// sample aperture 1(internal) is set to report "12.7 mm" as a STRING
// sample aperture 2(external) reports the number typed in...
//
	if(isVCALC)
		S2 = VC_sampleApertureDiam()*10		// convert cm to mm
	else
	// I'm trusting [cm] is in the RAW data file, or returned from the function if the date is prior to 5/22/19
		S2 = V_getSampleAp2_size(folderStr)*10		// sample ap 1 or 2? 2 = the "external", convert to [mm]
	endif
	
// L1 = source Ap to sample Ap distance [m] 
	if(isVCALC)
		L1 = VC_calcSSD()/100		//convert cm to m
	else
		L1 = V_getSourceAp_distance(folderStr)/100
	endif

// L2 = sample aperture to detector distance [m]
// take the first two characters of the "type" to get the correct distance.
// if the type is say, MLRTB, then the implicit assumption in combining all four panels is that the resolution
// is not an issue for the slightly different distances.
	if(isVCALC)
		if(strlen(type) == 1)
			// it's "B"
			L2 = VC_calc_L2(type)/100		//convert cm to m
		else
			L2 = VC_calc_L2(type[0,1])/100		//convert cm to m
		endif
	else
		if(strlen(type) == 1)
		// it's "B"
			L2 = V_getDet_ActualDistance(folderStr,type)/100		//convert cm to m
		else
			L2 = V_getDet_ActualDistance(folderStr,type[0,1])/100		//convert cm to m
		endif
	endif

	
// BS = beam stop diameter [mm]
//TODO:? which BS is in? carr2, carr3, none?
// -- need to check the detector, num_beamstops field, then description, then shape/size or shape/height and shape/width
//

	if(isVCALC)
		BS = VC_beamstopDiam(type[0,1])*10 // convert cm to mm
	else
		BS = V_IdentifyBeamstopDiameter(folderStr,type)		//returns diameter in [mm]
	endif
//	BS = V_getBeamStopC2_size(folderStr)		// Units are [mm] 
//	BS = 25.4			//TODO hard-wired value
	
//	bs_shape = V_getBeamStopC2_shape(folderStr)
//	if(cmpstr(s1_shape,"CIRCLE") == 0)
//		bs = V_getBeamStopC2_size(folderStr)
//	else
//		bs = V_getBeamStopC2_height(folderStr)	
//	endif


	
// del_r = step size [mm] = binWidth*(mm/pixel) 
	del_r = 1*DDet*10		// TODO: this is probably not the correct value

// usingLenses = flag for lenses = 0 if no lenses, non-zero if lenses are in-beam
	usingLenses = 0

//if(cmpstr(type[0,1],"FL")==0)
//	Print "(FL) Resolution lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses"
//	Print lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses
//endif



// TODO:
// this is the point where I need to switch on the different collimation types (white beam, slit, Xtal, etc)
// to calculate the correct resolution, or fill the waves with the correct "flags"
//

// For white beam data, the wavelength distribution can't be represented as a gaussian, but all of the other 
//  geometric corrections still apply. Passing zero for the lambdaWidth will return the geometry contribution,
//  as long as the wavelength can be handled separately. It appears to be correct to do as a double integral,
//  with the inner(lambda) calculated first, then the outer(geometry).
//

// possible values are:
//
// pinhole
// pinhole_whiteBeam
// convergingPinholes
//
// *slit data should be reduced using the slit routine, not here, proceed but warn
// narrowSlit
// narrowSlit_whiteBeam

// TODO: this is a messy way to identify the super white beam condition, and it needs to be 
// done in a cleaner fashion (through IdentityCollimation) once NICE catches up

//	String monoType = V_IdentifyMonochromatorType(folderStr)


	if(cmpstr(collimationStr,"pinhole_super_white_beam")==0)
		lambdaWidth = 0
	endif
		
	if(cmpstr(collimationStr,"pinhole_whiteBeam") == 0)
		//		set lambdaWidth == 0 so that the gaussian resolution calculates only the geometry contribution.
		// the white beam distribution will need to be flagged some other way
		//
		lambdaWidth = 0
	endif

	if(cmpstr(collimationStr,"convergingPinholes") == 0)

		//		set usingLenses == 1 so that the Gaussian resolution calculation will be for a focus condition
		usingLenses = 1
	endif


// should not end up here, except for odd testing cases
	if(cmpstr(collimationStr,"narrowSlit") == 0)

		Print "??? Slit data is being averaged as pinhole - reset the AVERAGE parameters in the protocol ???"
	endif
	
// should not end up here, except for odd testing cases
	if(cmpstr(collimationStr,"narrowSlit_whiteBeam") == 0)

		//		set lambdaWidth == 0 so that the gaussian resolution calculates only the geometry contribution.
		// the white beam distribution will need to be flagged some other way
		//
		Print "??? Slit data is being averaged as pinhole - reset the AVERAGE parameters in the protocol ???"

		lambdaWidth = 0
	endif


/////////////////////////////
/////////////////////////////
// do the calculation
	S1 *= 0.5*0.1			//convert to radius and [cm]
	S2 *= 0.5*0.1

	L1 *= 100.0			// [cm]
	L1 -= apOff				//correct the distance

	L2 *= 100.0
	L2 += apOff
	del_r *= 0.1				//width of annulus, convert mm to [cm]
	
	BS *= 0.5*0.1			//nominal BS diameter passed in, convert to radius and [cm]

// TODO -- this empirical correction is for the geometry of the SANS beamstop location and the 
//   Ordela detector construction. For now on VSANS, don't correct for the projection.
//	// 21 MAR 07 SRK - use the projected BS diameter, based on a point sample aperture
//	Variable LB
//	LB = 20.1 + 1.61*BS			//distance in cm from beamstop to anode plane (empirical)
//	BS = bs + bs*lb/(l2-lb)		//adjusted diameter of shadow from parallax
	
	//Start resolution calculation
	a2 = S1*L2/L1 + S2*(L1+L2)/L1
//	q_small = 2.0*Pi*(BS-a2)*(1.0-lambdaWidth)/(lambda*L2)
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
// MAR 2011 - removed the del_r terms, they don't apply since no binning is done to the 2D data
//
Function V_get2DResolution(inQ,phi,r_dist,folderStr,type,collimationStr,SigmaQX,SigmaQY,fSubS)
	Variable inQ,phi,r_dist
	String folderStr,type,collimationStr
	Variable &SigmaQX,&SigmaQY,&fSubS		//these are the output quantities at the input Q value
//	Variable SigmaQX,SigmaQY,fSubS		//these are the output quantities at the input Q value

	
	Variable lambda, lambdaWidth, DDet, apOff, S1, S2, L1, L2, BS, del_r,usingLenses

	//	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
	//	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt

///////// get all of the values from the header
// TODO: check the units of all of the inputs
// lambda = wavelength [A]
	lambda = V_getWavelength(folderStr)
	
// lambdaWidth = [dimensionless]
	lambdaWidth = V_getWavelength_spread(folderStr)
	
// DDet = detector pixel resolution [cm]	**assumes square pixel
	// V_getDet_pixel_fwhm_x(folderStr,detStr)
	// V_getDet_pixel_fwhm_y(folderStr,detStr)
//	DDet = 0.8		// TODO -- this is hard-wired

	if(strlen(type) == 1)
		// it's "B"
		DDet = V_getDet_pixel_fwhm_x(folderStr,type)		// value is already in cm
	else
		DDet = V_getDet_pixel_fwhm_x(folderStr,type[0,1])		// value is already in cm
	endif
		
// apOff = sample aperture to sample distance [cm]
	apOff = 10		// TODO -- this is hard-wired


// S1 = source aperture diameter [mm]
// may be either circle or rectangle
	String s1_shape="",bs_shape=""
	Variable width,height,equiv_S1,equiv_bs
	
	s1_shape = V_getSourceAp_shape(folderStr)
	if(cmpstr(s1_shape,"CIRCLE") == 0)
		S1 = str2num(V_getSourceAp_size(folderStr))
	else
		S1 = V_getSourceAp_height(folderStr)		// TODO: need the width or at least an equivalent diameter
	endif
	
	
// S2 = sample aperture diameter [cm]
// as of 3/2018, the "internal" sample aperture is not in use, only the external
// TODO : verify the units on the Ap2 (external)
// sample aperture 1(internal) is set to report "12.7 mm" as a STRING
// sample aperture 2(external) reports the number typed in...
//
// so I'm trusting [cm] is in the file
	S2 = V_getSampleAp2_size(folderStr)*10		// sample ap 1 or 2? 2 = the "external", convert to [mm]
	
// L1 = source to sample distance [m] 
	L1 = V_getSourceAp_distance(folderStr)/100

// L2 = sample to detector distance [m]
// take the first two characters of the "type" to get the correct distance.
// if the type is say, MLRTB, then the implicit assumption in combining all four panels is that the resolution
// is not an issue for the slightly different distances.
	if(strlen(type) == 1)
		// it's "B"
		L2 = V_getDet_ActualDistance(folderStr,type)/100		//convert cm to m
	else
		L2 = V_getDet_ActualDistance(folderStr,type[0,1])/100		//convert cm to m
	endif
	
// BS = beam stop diameter [mm]
//TODO:? which BS is in? carr2, carr3, none?
// -- need to check the detector, num_beamstops field, then description, then shape/size or shape/height and shape/width
//
// TODO: the values in the file are incorrect!!! BS = 1000 mm diameter!!!
	BS = V_IdentifyBeamstopDiameter(folderStr,type)		//returns diameter in [mm]
//	BS = V_getBeamStopC2_size(folderStr)		// Units are [mm] 
//	BS = 25.4			//TODO hard-wired value
	
//	bs_shape = V_getBeamStopC2_shape(folderStr)
//	if(cmpstr(s1_shape,"CIRCLE") == 0)
//		bs = V_getBeamStopC2_size(folderStr)
//	else
//		bs = V_getBeamStopC2_height(folderStr)	
//	endif


	
// del_r = step size [mm] = binWidth*(mm/pixel) 
	del_r = 1*DDet*10		// TODO: this is probably not the correct value

// usingLenses = flag for lenses = 0 if no lenses, non-zero if lenses are in-beam
	usingLenses = 0

//if(cmpstr(type[0,1],"FL")==0)
//	Print "(FL) Resolution lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses"
//	Print lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,del_r,usingLenses
//endif



// TODO:
// this is the point where I need to switch on the different collimation types (white beam, slit, Xtal, etc)
// to calculate the correct resolution, or fill the waves with the correct "flags"
//

// For white beam data, the wavelength distribution can't be represented as a gaussian, but all of the other 
//  geometric corrections still apply. Passing zero for the lambdaWidth will return the geometry contribution,
//  as long as the wavelength can be handled separately. It appears to be correct to do as a double integral,
//  with the inner(lambda) calculated first, then the outer(geometry).
//

// possible values are:
//
// pinhole
// pinhole_whiteBeam
// convergingPinholes
//
// *slit data should be reduced using the slit routine, not here, proceed but warn
// narrowSlit
// narrowSlit_whiteBeam


	if(cmpstr(collimationStr,"pinhole") == 0)
		//nothing to change	
	endif

	if(cmpstr(collimationStr,"pinhole_whiteBeam") == 0)
		//		set lambdaWidth == 0 so that the gaussian resolution calculates only the geometry contribution.
		// the white beam distribution will need to be flagged some other way
		//
		lambdaWidth = 0
	endif

	if(cmpstr(collimationStr,"convergingPinholes") == 0)

		//		set usingLenses == 1 so that the Gaussian resolution calculation will be for a focus condition
		usingLenses = 1
	endif


// should not end up here, except for odd testing cases
	if(cmpstr(collimationStr,"narrowSlit") == 0)

		Print "??? Slit data is being averaged as pinhole - reset the AVERAGE parameters in the protocol ???"
	endif
	
// should not end up here, except for odd testing cases
	if(cmpstr(collimationStr,"narrowSlit_whiteBeam") == 0)

		//		set lambdaWidth == 0 so that the gaussian resolution calculates only the geometry contribution.
		// the white beam distribution will need to be flagged some other way
		//
		Print "??? Slit data is being averaged as pinhole - reset the AVERAGE parameters in the protocol ???"

		lambdaWidth = 0
	endif


	
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





