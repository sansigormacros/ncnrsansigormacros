#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.ipf is not necessary (no smearing calculations done) PlotUtils.ipf is recommended
////////////////////////////////////////////////
//
// this function calculates the interparticle structure factor for spherical particles interacting
// through a square well potential.
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotSquareWellStruct(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.3
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^-1) for model: "
	Prompt qmax "Enter maximum q-value (^-1) for model: "
	
	Make/O/D/n=(num) xwave_sws,ywave_sws
	xwave_sws = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		
	Make/O/D coef_sws = {50,0.04,1.5,1.2}
	make/o/t parameters_sws = {"Radius (A)","vol fraction","well depth (kT)","well width (diameters)"}
	Edit parameters_sws,coef_sws
	ywave_sws := SquareWellStruct(coef_sws,xwave_sws)
	Display ywave_sws vs xwave_sws
	ModifyGraph marker=29,msize=2,mode=4
	Label bottom "q (\\S-1\\M)"
	Label left "Structure Factor"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////
// smearing a structure factor is not appropriate, so it's not done
///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function SquareWellStruct(w,x) : FitFunc
	Wave w
	Variable x

//     SUBROUTINE SQWELL: CALCULATES THE STRUCTURE FACTOR FOR A
//                        DISPERSION OF MONODISPERSE HARD SPHERES
//     IN THE Mean Spherical APPROXIMATION ASSUMING THE SPHERES
//     INTERACT THROUGH A SQUARE WELL POTENTIAL.
//** not the best choice of closure ** see note below
//     REFS:  SHARMA,SHARMA, PHYSICA 89A,(1977),212
//
//     
 
// NOTE - depths >1.5kT and volume fractions > 0.08 give UNPHYSICAL RESULTS
// when compared to Monte Carlo simulations

// Input variables are:
	//[0] radius
	//[1] volume fraction
	//[2] well depth e/kT, dimensionless, +ve depths are attractive
	//[3] well width, multiples of diameter
	
	Variable req,phis,edibkb,lambda,struc
	req = w[0]
	phis = w[1]
	edibkb = w[2]
	lambda = w[3]
	
//  COMPUTE CONSTANTS
//  local variables
	Variable sigma,eta,eta2,eta3,eta4,etam1,etam14,alpha,beta,gamma
	Variable qvs,sk,sk2,sk3,sk4,t1,t2,t3,t4,ck
	 
      SIGMA = req*2.
      ETA = phis
      ETA2 = ETA*ETA
      ETA3 = ETA*ETA2
      ETA4 = ETA*ETA3       
      ETAM1 = 1. - ETA 
      ETAM14 = ETAM1*ETAM1*ETAM1*ETAM1
      ALPHA = (  ( (1. + 2.*ETA)^2 ) + ETA3*( ETA-4.0 )  )/ETAM14
      BETA = -(ETA/3.0) * ( 18. + 20.*ETA - 12.*ETA2 + ETA4 )/ETAM14
      GAMMA = 0.5*ETA*( (1. + 2.*ETA)^2 + ETA3*(ETA-4.) )/ETAM14
//
//  CALCULATE THE STRUCTURE FACTOR
//
// the loop over q-values used to be here     
//      DO 20 I=1,NPTSM
        QVS = x
        SK = x*SIGMA
        SK2 = SK*SK
        SK3 = SK*SK2
        SK4 = SK3*SK
        T1 = ALPHA * SK3 * ( SIN(SK) - SK * COS(SK) )
        T2 = BETA * SK2 * ( 2.*SK*SIN(SK) - (SK2-2.)*COS(SK) - 2.0 )
        T3 =   ( 4.0*SK3 - 24.*SK ) * SIN(SK)  
        T3 = T3 - ( SK4 - 12.0*SK2 + 24.0 )*COS(SK) + 24.0    
        T3 = GAMMA*T3
        T4 = -EDIBKB*SK3*(SIN(LAMBDA*SK) - LAMBDA*SK*COS(LAMBDA*SK)+ SK*COS(SK) - SIN(SK) )
        CK =  -24.0*ETA*( T1 + T2 + T3 + T4 )/SK3/SK3
        STRUC  = 1./(1.-CK)
//   20 CONTINUE
      Return struc
End

