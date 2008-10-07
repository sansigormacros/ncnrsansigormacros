#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
//
// this function is for the form factor of a polydisperse spherical particle, with a core-shell structure
// the polydispersity of the overall (core+shell) radius is described by a Schulz distribution
// the ratio R(core)/ R (total) is constant
//
// 06 NOV 98 SRK
//////////////////////////////////////////////// 

Proc PlotPolyCoreShellRatio(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_pcr,ywave_pcr
	xwave_pcr = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	Make/O/D coef_pcr = {1.,60,10,.2,1e-6,2e-6,3e-6,0.001}
	Make/O/t parameters_pcr = {"scale","avg core rad (A)","avg shell thickness (A)","overall polydisp (0,1)",,"SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit parameters_pcr,coef_pcr
	ywave_pcr := PolyCoreShellRatio(coef_pcr,xwave_pcr)
	Display ywave_pcr vs xwave_pcr
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedPolyCoreShellRatio()		
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pcr = {1.,60,10,.2,1e-6,2e-6,3e-6,0.001}
	make/o/t smear_parameters_pcr = {"scale","avg core rad (A)","avg shell thickness (A)","overall polydisp (0,1)",,"SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_pcr,smear_coef_pcr
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_pcr,smeared_qvals				//**** mod
	SetScale d,0,0,"1/cm",smeared_pcr							//**** mod

	smeared_pcr := SmearedPolyCoreShellRatio(smear_coef_pcr,$gQvals)
	Display smeared_pcr vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)

End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
//C	CALC'S THE FORM FACTOR FOR A MONOMODAL
//c	POPULATION OF POLYDISPERSE SHERES WITH A
//c	CORE AND SHELL TYPE SLD DISTRIBUTION. IT
//c	ASSUMES THAT THE CORE RADIUS IS A CONSTANT
//c	FRACTION (P) OF THE SHELL  RADIUS.
//c
//c
//c	REF.:    "DETERMINATION OF THE STRUCTURE AND DYNAMICS OF
//c	         MICELLAR SOLUTIONS BY NEUTRON SMALL-ANGLE SCATTERING"
//c	         BY J.B.HAYTER IN PHYSICS OF AMPHIPHILES--MICELLES,
//c	         VESICLES, AND MICROEMULSIONS ED BY  DEGIORGIO,V;  CORTI,M,
//c	         PP59-93,1983.
//c
//c	EQNS: 32-37
//c
Function PolyCoreShellRatio(w,x) : FitFunc
	Wave w;Variable x

	//assign nice names to the input wave
	//w[0] = scale
	//w[1] = core radius [A]
	//w[2] = shell thickness [A]
	//w[3] = polydispersity index (0<p<1)
	//w[4] = SLD core [A^-2]
	//w[5] = SLD shell  [A^-2]
	//w[6] = SLD solvent [A^-2]
	//w[7] = bkg [cm-1]
	Variable scale,corrad,thick,shlrad,pp,drho1,drho2,sig,zz,bkg
	Variable sld1,sld2,sld3,zp1,zp2,zp3,vpoly
	
	scale = w[0]
	corrad = w[1]
	thick = w[2]
	sig = w[3]
	sld1 = w[4]
	sld2 = w[5]
	sld3 = w[6]
	bkg = w[7]
	
	//calculations on input parameters
	shlrad = corrad + thick
	zz = (1/sig)^2-1
	drho1 = sld1-sld2		//core-shell
	drho2 = sld2-sld3		//shell-solvent
	zp1 = zz + 1.
	zp2 = zz + 2.
	zp3 = zz + 3.
	vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(corrad+thick)^3
	
	//local variables
	Variable pi43,c1,c2,form,volume,arg1,arg2
	
	PI43=4.0/3.0*PI
 	Pp=CORRAD/SHLRAD
 	VOLUME=PI43*SHLRAD*SHLRAD*SHLRAD
 	C1=DRHO1*VOLUME
 	C2=DRHO2*VOLUME
 	
 	// the beta factor is not calculated
 	// the calculated form factor <f^2> has units [length^2]
 	// and must be multiplied by number density [l^-3] and the correct unit
 	// conversion to get to absolute scale
 	
//      DO 10  I=1,NPTSM
//        F=P*P*P*C1*FNT1(QVALSM(I)*P*SHLRAD,Z)
//     2   +C2*FNT1(QVALSM(I)*SHLRAD,Z)
//       FAVE2=F*F
		
	arg1 = x*shlrad*pp
	arg2 = x*shlrad
		
	FORM=(Pp^6.0)*C1*C1*FNT2(arg1,Zz)
	form += C2*C2*FNT2(arg2,Zz)
	form += 2.0*C1*C2*FNT3(arg2,Pp,Zz)
	
	//convert the result to [cm^-1]
	
	//scale the result
	// - divide by the polydisperse volume, mult by 10^8
	form  /= vpoly
	form *= 1.0e8
	form *= scale

	//add in the background
	form += bkg
      
 	RETURN (form)
END
//////////////////////////////////////
//cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
//c
//c      FUNCTION FNT1(Y,Z)
//c
	Function FNT1(Yy,Zz)
	Variable yy,zz
	
	//local variables
	Variable z1,z2,uu,vv,ww,term1,term2,fnt1

	Z1=Zz+1.0
	Z2=Zz+2.0
	Uu=Yy/Z1
	Vv=ATAN(Uu)
	Ww=ATAN(2.0*Uu)
	TERM1=SIN(Z1*Vv)/((1.0+Uu*Uu)^(Z1/2.0))
	TERM2=Yy*COS(Z2*Vv)/((1.0+Uu*Uu)^(Z2/2.0))
	FNT1=3.0/Yy/Yy/Yy*(TERM1-TERM2)
	
	RETURN (fnt1)
END

//cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
//c
//c      FUNCTION FNT2(Y,Z)
//c
FUNCTION FNT2(Yy,Zz)
	Variable yy,zz
	
	//local variables
	Variable z1,z2,z3,uu,ww,term1,term2,term3,fnt2
	
	Z1=Zz+1.0
	Z2=Zz+2.0
	Z3=Zz+3.0
	Uu=Yy/Z1
	Ww=ATAN(2.0*Uu)
	TERM1=COS(Z1*Ww)/((1.0+4.0*Uu*Uu)^(Z1/2.0))
	TERM2=2.0*Yy*SIN(Z2*Ww)/((1.0+4.0*Uu*Uu)^(Z2/2.0))
	TERM3=1.0+COS(Z3*Ww)/((1.0+4.0*Uu*Uu)^(Z3/2.0))
	FNT2=(4.50/Z1/Yy^6.0)*(Z1*(1.0-TERM1-TERM2)+Yy*Yy*Z2*TERM3)
	
	RETURN (fnt2)
END

//cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
//c
//c      FUNCTION FNT3(Y,P,Z)
//c
FUNCTION FNT3(Yy,Pp,Zz)
	Variable yy,pp,zz
     	
	//local variables
	Variable z1,z2,z3,yp,yn,up,un,vp,vn,term1,term2,term3,term4,term5,term6,fnt3
     	
	Z1=Zz+1
	Z2=Zz+2
	Z3=Zz+3
	YP=(1.0+Pp)*Yy
	YN=(1.0-Pp)*Yy
	UP=YP/Z1
	UN=YN/Z1
	VP=ATAN(UP)
	VN=ATAN(UN)
	TERM1=COS(Z1*VN)/((1.0+UN*UN)^(Z1/2.0))
	TERM2=COS(Z1*VP)/((1.0+UP*UP)^(Z1/2.0))
	TERM3=COS(Z3*VN)/((1.0+UN*UN)^(Z3/2.0))
	TERM4=COS(Z3*VP)/((1.0+UP*UP)^(Z3/2.0))
	TERM5=YN*SIN(Z2*VN)/((1.0+UN*UN)^(Z2/2.0))
	TERM6=YP*SIN(Z2*VP)/((1.0+UP*UP)^(Z2/2.0))
	FNT3=(4.5/Z1/Yy^6.0)
	fnt3 *=(Z1*(TERM1-TERM2)+Yy*Yy*Pp*Z2*(TERM3+TERM4)+Z1*(TERM5-TERM6))
     
	RETURN (fnt3)
END
/////////////////////////////////

// this is all there is to the smeared calculation!
Function SmearedPolyCoreShellRatio(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyCoreShellRatio,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
