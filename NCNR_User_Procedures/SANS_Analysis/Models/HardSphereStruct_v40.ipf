#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.ipf is not required (no smearing calculation done) PlotUtils.ipf should be included
////////////////////////////////////////////////
// this function is for the hard sphere structure factor
//
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotHardSphereStruct(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.3
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_hss,ywave_hss
	//xwave_hss = (x+1)*((qmax-qmin)/num)
	xwave_hss = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	Make/O/D coef_hss = {50,0.2}
	make/o/t parameters_hss = {"Radius (A)","vol fraction"}
	Edit parameters_hss,coef_hss
	Variable/G root:g_hss
	g_hss := HardSphereStruct(coef_hss,ywave_hss,xwave_hss)
//	ywave_hss := HardSphereStruct(coef_hss,xwave_hss)
	Display ywave_hss vs xwave_hss
	ModifyGraph marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Structure Factor"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("HardSphereStruct","coef_hss","hss")
End

//AAO version
Function HardSphereStruct(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("HardSphereStructX")
	yw = HardSphereStructX(cw,xw)
#else
	yw = fHardSphereStruct(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////
// no smeared version is calculated - it is simply not appropriate

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fHardSphereStruct(w,x) : FitFunc
	Wave w
	Variable x
	                
//     SUBROUTINE HSSTRCT: CALCULATES THE STRUCTURE FACTOR FOR A
//                         DISPERSION OF MONODISPERSE HARD SPHERES
//                         IN THE PERCUS-YEVICK APPROXIMATION
//
//     REFS:  PERCUS,YEVICK PHYS. REV. 110 1 (1958)
//            THIELE J. CHEM PHYS. 39 474 (1968)
//            WERTHEIM  PHYS. REV. LETT. 47 1462 (1981)
//
// Input variables are:
	//[0] radius
	//[1] volume fraction
	//Variable timer=StartMSTimer
	
	Variable r,phi,struc
	r = w[0]
	phi = w[1]

// Local variables
	Variable denom,dnum,alpha,fbeta,gamm,q,a,asq,ath,afor,rca,rsa
	Variable calp,cbeta,cgam,prefac,c,vstruc
//  COMPUTE CONSTANTS
//
      DENOM = (1.0-PHI)^4
      DNUM = (1.0 + 2.0*PHI)^2
      ALPHA = DNUM/DENOM
      fBETA = -6.0*PHI*((1.0 + PHI/2.0)^2)/DENOM
      GAMM = 0.50*PHI*DNUM/DENOM
//
//  CALCULATE THE STRUCTURE FACTOR
//     
// loop over q-values used to be here
//      DO 10 I=1,NPTSM
        Q = x		// q-value for the calculation is passed in as variable x
        A = 2.0*Q*R
//        IF(A.LT.1.0D-10)  A = 1.0D-10
        ASQ = A*A
        ATH = ASQ*A
        AFOR = ATH*A
        RCA = COS(A)
        RSA = SIN(A)
        CALP = ALPHA*(RSA/ASQ - RCA/A)
        CBETA = fBETA*(2.0*RSA/ASQ - (ASQ - 2.0)*RCA/ATH - 2.0/ATH)
        CGAM = GAMM*(-RCA/A + (4.0/A)*((3.0*ASQ - 6.0)*RCA/AFOR + (ASQ - 6.0)*RSA/ATH + 6.0/AFOR))
        PREFAC = -24.0*PHI/A
        C = PREFAC*(CALP + CBETA + CGAM)
        VSTRUC = 1.0/(1.0-C)
        STRUC = VSTRUC
//   10 CONTINUE
	//Variable elapse=StopMSTimer(timer)
      //Print "HS struct eval time (s) = ",elapse
      RETURN Struc
End
// End of HardSphereStruct

