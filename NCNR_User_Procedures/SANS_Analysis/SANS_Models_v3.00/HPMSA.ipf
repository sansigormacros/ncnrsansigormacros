#pragma rtGlobals=1		// Use modern global access method.

Proc PlotHayterPenfoldMSA(num,qmin,qmax)
	Variable num=128, qmin=.001, qmax=.3
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "

	//			 Set up data folder for global variables
 	string SaveDF=GetDataFolder(1)
 	if (DataFolderExists("root:HayPenMSA"))
 		SetDataFolder root:HayPenMSA
 	else
 		NewDataFolder/S root:HayPenMSA
	endif
	//variable/G a,b,c,f,eta,gek,ak,u,v,gamk,seta,sgek,sak,scal,g1, fval, evar
	Make/O/D/N=17 gMSAWave
	SetDataFolder SaveDF
	//
	make/o/d/n=(num) xwave_hpmsa, ywave_hpmsa, xdiamwave_hpmsa	
	xwave_hpmsa = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))		
	make/o/d coef_hpmsa = {41.5,19,0.0192,298,0.0,78}                    //**** numerical vals, # of variables
	make/o/t parameters_hpmsa = {"Diameter (A)","Charge","Volume Fraction","Temperature(K)","monovalent salt conc. (M)","dielectric constant of solvent"}
	Edit parameters_hpmsa,coef_hpmsa
	ywave_hpmsa := HayterPenfoldMSA(coef_hpmsa,xwave_hpmsa)
	xdiamwave_hpmsa:=xwave_hpmsa*coef_hpmsa[0]
	//Display ywave_hpmsa vs xdiamwave_hpmsa	
	Display ywave_hpmsa vs xwave_hpmsa	
	ModifyGraph log=0,marker=29,msize=2,mode=4,grid=1			//**** log=0 if linear scale desired
	Label bottom "q (\\S-1\\M)"
	Label left "Structure Factor"	
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Wrapper for Hayter Penfold MSA routines:
//		SETS UP THE PARAMETERS FOR THE
//		CALCULATION OF THE STRUCTURE FACTOR ,S(Q)
//		GIVEN THE THREE REQUIRED PARAMETERS VALK, GAMMA, ETA.
//
//      *** NOTE ****  THIS CALCULATION REQUIRES THAT THE NUMBER OF 
//                     Q-VALUES AT WHICH THE S(Q) IS CALCULATED BE
//                     A POWER OF 2
//

Function HayterPenfoldMSA(w,x) : FitFunc
	wave w
	variable x
      
//      variable timer=StartMSTimer
      
	variable Elcharge=1.602189e-19		// electron charge in Coulombs (C)
	variable kB=1.380662e-23				// Boltzman constant in J/K
	variable FrSpPerm=8.85418782E-12	//Permittivity of free space in C^2/(N m^2)

	variable SofQ, QQ, Qdiam, gammaek, Vp, csalt, ss
	variable VolFrac, SIdiam, diam, Kappa, cs, IonSt
	variable dialec, Perm, Beta, Temp, zz, charge, ierr

	diam=w[0]		//in   (not SI .. should force people to think in nm!!!)
	zz = w[1]		//# of charges
	VolFrac=w[2]	
	QQ=x			//in ^-1 (not SI .. should force people to think in nm^-1!!!)
	Temp=w[3]		//in degrees Kelvin
	csalt=w[4]		//in molarity
	dialec=w[5]		// unitless

//			 Set up data folder for global variables in the calling macro
// 	string SaveDF=GetDataFolder(1)
 //	if (DataFolderExists("root:HayPenMSA"))
// 		SetDataFolder root:HayPenMSA
 //	else
// 		NewDataFolder/S root:HayPenMSA
//	endif
//	variable/G a,b,c,f,eta,gek,ak,u,v,gamk,seta,sgek,sak,scal,g1, fval, evar
//	SetDataFolder SaveDF

//need NVAR references to ALL global variables in HayPenMSA subfolder
//	NVAR a=root:HayPenMSA:a
//	NVAR b=root:HayPenMSA:b
//	NVAR c=root:HayPenMSA:c
//	NVAR f=root:HayPenMSA:f
//	NVAR eta=root:HayPenMSA:eta
//	NVAR gek=root:HayPenMSA:gek
//	NVAR ak=root:HayPenMSA:ak
//	NVAR u=root:HayPenMSA:u
//	NVAR v=root:HayPenMSA:v
//	NVAR gamk=root:HayPenMSA:gamk
//	NVAR seta=root:HayPenMSA:seta
//	NVAR sgek=root:HayPenMSA:sgek
//	NVAR sak=root:HayPenMSA:sak
//	NVAR scal=root:HayPenMSA:scal
//	NVAR g1=root:HayPenMSA:g1
//	NVAR fval=root:HayPenMSA:fval
//	NVAR evar=root:HayPenMSA:evar
	
//	NVAR a=root:HayPenMSA:a = gMSAWave[0]
//	NVAR b=root:HayPenMSA:b = gMSAWave[1]
//	NVAR c=root:HayPenMSA:c = gMSAWave[2]
//	NVAR f=root:HayPenMSA:f = gMSAWave[3]
//	NVAR eta=root:HayPenMSA:eta = gMSAWave[4]
//	NVAR gek=root:HayPenMSA:gek = gMSAWave[5]
//	NVAR ak=root:HayPenMSA:ak = gMSAWave[6]
//	NVAR u=root:HayPenMSA:u = gMSAWave[7]
//	NVAR v=root:HayPenMSA:v = gMSAWave[8]
//	NVAR gamk=root:HayPenMSA:gamk = gMSAWave[9]
//	NVAR seta=root:HayPenMSA:seta = gMSAWave[10]
//	NVAR sgek=root:HayPenMSA:sgek = gMSAWave[11]
//	NVAR sak=root:HayPenMSA:sak = gMSAWave[12]
//	NVAR scal=root:HayPenMSA:scal = gMSAWave[13]
//	NVAR g1=root:HayPenMSA:g1 = gMSAWave[14]
//	NVAR fval=root:HayPenMSA:fval = gMSAWave[15]
//	NVAR evar=root:HayPenMSA:evar = gMSAWave[16]
//use wave instead
	WAVE gMSAWave = $"root:HayPenMSA:gMSAWave"
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// convert to USEFUL inputs in SI units                                                //
////////////////////////////    NOTE: easiest to do EVERYTHING in SI units                               //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	Beta=1/(kB*Temp)		// in Joules^-1
	Perm=dialec*FrSpPerm	//in C^2/(N  m^2)
	charge=zz*Elcharge		//in Coulomb (C)
	SIdiam = diam*1E-10		//in m
	Vp=4*pi/3*(SIdiam/2)^3	//in m^3
	cs=csalt*6.022E23*1E3	//# salt molecules/m^3

//         Compute the derived values of :
//			 Ionic strength IonSt (in C^2/m^3)  
// 			Kappa (Debye-Huckel screening length in m)
//	and		gamma Exp(-k)
	IonSt=0.5 * Elcharge^2*(zz*VolFrac/Vp+2*cs)
	Kappa=sqrt(2*Beta*IonSt/Perm)     //Kappa calc from Ionic strength
//	Kappa=2/SIdiam					// Use to compare with HP paper
	gMSAWave[5]=Beta*charge^2/(pi*Perm*SIdiam*(2+Kappa*SIdiam)^2)

//         Finally set up dimensionless parameters 
	Qdiam=QQ*diam
      gMSAWave[6] = Kappa*SIdiam
      gMSAWave[4] = VolFrac


      
//  ***************  now go to John Hayter and Jeff Penfold setup routine************
 
 
//    *** ALL FURTHER PROGRAMS COMMENTS ARE FROM J. HAYTER 
//        EXCEPT WHERE INDICATED  ^*
//
//    
//       ROUTINE TO CALCULATE S(Q*SIG) FOR A SCREENED COULOMB
//       POTENTIAL BETWEEN FINITE PARTICLES OF DIAMETER 'SIG'
//       AT ANY VOLUME FRACTION.  THIS ROUTINE IS MUCH MORE POWER-
//       FUL THAN "SQHP" AND SHOULD BE USED TO REPLACE THE LATTER
//       IN EXISTING PROGRAMS.  NOTE THAT THE COMMON AREA IS 
//       CHANGED;  IN PARTICULAR THE POTENTIAL IS PASSED 
//       DIRECTLY AS 'GEK' = GAMMA*EXP(-K) IN THE PRESENT ROUTINE.
//
//     JOHN B. HAYTER
//         
//  ***** THIS VERSION ENTERED ON 5/30/85 BY JOHN F. BILLMAN
//
//       CALLING SEQUENCE:
//
//            CALL SQHPA(QQ,SQ,NPT,IERR)
//
//      QQ:   ARRAY OF DIMENSION NPT CONTAINING THE VALUES
//            OF Q*SIG AT WHICH S(Q*SIG) WILL BE CALCULATED.
//      SQ:   ARRAY OF DIMENSION NPT INTO WHICH THE VALUES OF
//            S(Q*SIG) WILL BE RETURNED
//      NPT:  NUMBER OF VALUES OF Q*SIG
//
//      IERR  > 0:   NORMAL EXIT; IERR=NUMBER OF ITERATIONS
//             -1:   NEWTON ITERATION NON-CONVERGENT IN "SQCOEF"   
//             -2:   NEWTON ITERATION NON-CONVERGENT IN "SQFUN"
//             -3:   CANNOT RESCALE TO G(1+) > 0.
//
//        ALL OTHER PARAMETERS ARE TRANSMITTED THROUGH A SINGLE
//        NAMED COMMON AREA:
// 
//     REAL*8 a,b,//,f 
//     COMMON /SQHPB/ ETA,GEK,AK,A,B,C,F,U,V,GAMK,SETA,SGEK,SAK,SCAL,G1
//                                                  
//     ON ENTRY:
//
//       ETA:    VOLUME FRACTION
//       GEK:    THE CONTACT POTENTIAL GAMMA*EXP(-K)
//        AK:    THE DIMENSIONLESS SCREENING CONSTANT
//               K=KAPPA*SIG  WHERE KAPPA IS THE INVERSE SCREENING
//               LENGTH AND SIG IS THE PARTICLE DIAMETER
//
//     ON EXIT:
//
//       GAMK IS THE COUPLING:  2*GAMMA*SS*EXP(-K/SS), SS=ETA^(1/3).
//       SETA,SGEK AND SAK ARE THE RESCALED INPUT PARAMETERS.
//       SCAL IS THE RESCALING FACTOR:  (ETA/SETA)^(1/3).
//       G1=G(1+), THE CONTACT VALUE OF G(R/SIG).
//       A.B,C,F,U,V ARE THE CONSTANTS APPEARING IN THE ANALYTIC
//       SOLUTION OF THE MSA [HAYTER-PENFOLD; MOL. PHYS. 42: 109 (1981)  
// 
//     NOTES:
//
//       (A)  AFTER THE FIRST CALL TO SQHPA, S(Q*SIG) MAY BE EVALUATED
//            AT OTHER Q*SIG VALUES BY REDEFINING THE ARRAY QQ AND CALLING
//            "SQHCAL" DIRECTLY FROM THE MAIN PROGRAM.
//
//       (B)  THE RESULTING S(Q*SIG) MAY BE TRANSFORMED TO G(SS/SIG)
//            BY USING THE ROUTINE "TROGS"
//
//       (C)  NO ERROR CHECKING OF INPUT PARAMETERS IS PERFORMED;
//            IT IS THE RESPONSIBILITY OF THE CALLING PROGRAM TO 
//            VERIFY VALIDITY.
//
//      SUBROUTINES CALLED BY SQHPA:
//
//         (1) SQCOEF:    RESCALES THE PROBLEM AND CALCULATES THE
//                        APPROPRIATE COEFFICIENTS FOR "SQHCAL"
//
//         (2) SQFUN:     CALCULATES VARIOUS VALUES FOR "SQCOEF"
//
//         (3) SQHCAL:    CALCULATES H-P  S(Q*SIG)  GIVEN IN A,B,C,F
//




//Function sqhpa(qq)  {this is where Hayter-Penfold program began}
		

//       FIRST CALCULATE COUPLING

      ss=gMSAWave[4]^(1.0/3.0)
       gMSAWave[9] = 2.0*ss*gMSAWave[5]*exp(gMSAWave[6]-gMSAWave[6]/ss)

//        CALCULATE COEFFICIENTS, CHECK ALL IS WELL
//        AND IF SO CALCULATE S(Q*SIG)
                         
      ierr=0
      ierr=sqcoef(ierr)
      if (ierr>=0) 
            SofQ=sqhcal(Qdiam)
       else
       	SofQ=NaN
       	print "Error Level = ",ierr
             print "Please report HPMSA problem with above error code"
      endif
      //KillDataFolder root:HayPenMSA
//      variable elapsed=StopMSTimer(timer)
//      Print "elapsed time = ",elapsed

      return SofQ 
end

/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
//
//
//      CALCULATES RESCALED VOLUME FRACTION AND CORRESPONDING
//      COEFFICIENTS FOR "SQHPA"
//
//      JOHN B. HAYTER   (I.L.L.)    14-SEP-81
//
//      ON EXIT:
//
//      SETA IS THE RESCALED VOLUME FRACTION
//      SGEK IS THE RESCALED CONTACT POTENTIAL
//      SAK IS THE RESCALED SCREENING CONSTANT
//      A,B,C,F,U,V ARE THE MSA COEFFICIENTS
//      G1= G(1+) IS THE CONTACT VALUE OF G(R/SIG):
//      FOR THE GILLAN CONDITION, THE DIFFERENCE FROM
//      ZERO INDICATES THE COMPUTATIONAL ACCURACY.
//
//      IR > 0:    NORMAL EXIT,  IR IS THE NUMBER OF ITERATIONS.
//         < 0:    FAILED TO CONVERGE
//


Function sqcoef(ir)
	variable ir
	
      variable itm=40.0, acc=5.0E-6, ix,ig,ii,del,e1,e2,f1,f2
      WAVE gMSAWave = $"root:HayPenMSA:gMSAWave"
      
//	NVAR a=root:HayPenMSA:a
//	NVAR b=root:HayPenMSA:b
//	NVAR c=root:HayPenMSA:c
//	NVAR f=root:HayPenMSA:f
//	NVAR eta=root:HayPenMSA:eta
//	NVAR gek=root:HayPenMSA:gek
//	NVAR ak=root:HayPenMSA:ak
//	NVAR u=root:HayPenMSA:u
//	NVAR v=root:HayPenMSA:v
//	NVAR gamk=root:HayPenMSA:gamk
//	NVAR seta=root:HayPenMSA:seta
//	NVAR sgek=root:HayPenMSA:sgek
//	NVAR sak=root:HayPenMSA:sak
//	NVAR scal=root:HayPenMSA:scal
//	NVAR g1=root:HayPenMSA:g1
//	NVAR fval=root:HayPenMSA:fval
//	NVAR evar=root:HayPenMSA:evar

	           
      ig=1
      if (gMSAWave[6]>=(1.0+8.0*gMSAWave[4]))
		ig=0
		gMSAWave[15]=gMSAWave[14]
		 gMSAWave[16]=gMSAWave[4]
		  ix=1
		ir = sqfun(ix,ir)
		gMSAWave[14]=gMSAWave[15]
		 gMSAWave[4]=gMSAWave[16]
		if((ir<0.0) %| (gMSAWave[14]>=0.0))
		   return ir
		endif
	endif
      gMSAWave[10]=min(gMSAWave[4],0.20)
      if ((ig!=1) %| ( gMSAWave[9]>=0.15))
		ii=0                               
		do
			ii=ii+1
			if(ii>itm)
				ir=-1
				return ir		
			endif
			if (gMSAWave[10]<=0.0)
			    gMSAWave[10]=gMSAWave[4]/ii
			endif
			if(gMSAWave[10]>0.6)
			    gMSAWave[10] = 0.35/ii
			 endif
			e1=gMSAWave[10]
			gMSAWave[15]=f1
			gMSAWave[16]=e1
			ix=2
			ir = sqfun(ix,ir)
			f1=gMSAWave[15]
			 e1=gMSAWave[16]
			e2=gMSAWave[10]*1.01
			gMSAWave[15]=f2
			 gMSAWave[16]=e2
			 ix=2
			ir = sqfun(ix,ir)
			f2=gMSAWave[15]
			 e2=gMSAWave[16]
			e2=e1-(e2-e1)*f1/(f2-f1)
			gMSAWave[10] = e2
			del = abs((e2-e1)/e1)
		while (del>acc)
		gMSAWave[15]=gMSAWave[14]
		 gMSAWave[16]=e2
		 ix=4
		ir = sqfun(ix,ir)
		gMSAWave[14]=gMSAWave[15]
		 e2=gMSAWave[16]
		ir=ii
		if ((ig!=1) %| (gMSAWave[10]>=gMSAWave[4])) 
		    return ir
		endif
	endif
	gMSAWave[15]=gMSAWave[14]
	gMSAWave[16]=gMSAWave[4]
	 ix=3
	ir = sqfun(ix,ir)
	gMSAWave[14]=gMSAWave[15]
	 gMSAWave[4]=gMSAWave[16]
	if ((ir>=0) %& (gMSAWave[14]<0.0))
	      ir=-3
	endif
	return ir
end

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
//
//        
//       CALCULATES VARIOUS COEFFICIENTS AND FUNCTION
//       VALUES FOR "SQCOEF"  (USED BY "SQHPA").
//
//   **  THIS ROUTINE WORKS LOCALLY IN DOUBLE PRECISION  **
//
//       JOHN B. HAYTER    (I.L.L.)  23-MAR-82
//
//       IX=1:   SOLVE FOR LARGE K, RETURN G(1+).
//          2:   RETURN FUNCTION TO SOLVE FOR ETA(GILLAN).
//          3:   ASSUME NEAR GILLAN, SOLVE, RETURN G(1+).
//          4:   RETURN G(1+) FOR ETA=ETA(GILLAN).
//
//



Function sqfun(ix,ir)
	variable ix, ir
	
      variable acc=1.0e-6, itm=40.0
      variable reta,eta2,eta21,eta22,eta3,eta32,eta2d,eta2d2,eta3d,eta6d,e12,e24,ibig,rgek
      variable rak,ak1,ak2,dak,dak2,dak4,d,d2,dd2,dd4,dd45,ex1,ex2,sk,ck,ckma,skma
      variable al1,al2,al3,al4,al5,al6,be1,be2,be3,vu1,vu2,vu3,vu4,vu5,ph1,ph2,ta1,ta2,ta3,ta4,ta5
      variable a1,a2,a3,b1,b2,b3,v1,v2,v3,p1,p2,p3,pp,pp1,pp2,p1p2,t1,t2,t3,um1,um2,um3,um4,um5,um6
      variable w0,w1,w2,w3,w4,w12,w13,w14,w15,w16,w24,w25,w26,w32,w34,w3425,w35,w3526,w36,w46,w56
      variable fa,fap,ca,e24g,pwk,qpw,pg,ii,del,fun,fund,g24
      WAVE gMSAWave = $"root:HayPenMSA:gMSAWave"
      
//	NVAR a=root:HayPenMSA:a
//	NVAR b=root:HayPenMSA:b
//	NVAR c=root:HayPenMSA:c
//	NVAR f=root:HayPenMSA:f
//	NVAR eta=root:HayPenMSA:eta
//	NVAR gek=root:HayPenMSA:gek
//	NVAR ak=root:HayPenMSA:ak
//	NVAR u=root:HayPenMSA:u
//	NVAR v=root:HayPenMSA:v
//	NVAR gamk=root:HayPenMSA:gamk
//	NVAR seta=root:HayPenMSA:seta
//	NVAR sgek=root:HayPenMSA:sgek
//	NVAR sak=root:HayPenMSA:sak
//	NVAR scal=root:HayPenMSA:scal
//	NVAR g1=root:HayPenMSA:g1
//	NVAR fval=root:HayPenMSA:fval
//	NVAR evar=root:HayPenMSA:evar
	

//     CALCULATE CONSTANTS; NOTATION IS HAYTER PENFOLD (1981)

      reta = gMSAWave[16]                                                
      eta2 = reta*reta
      eta3 = eta2*reta
      e12 = 12.0*reta
      e24 = e12+e12
      gMSAWave[13] = (gMSAWave[4]/gMSAWave[16])^(1.0/3.0)
       gMSAWave[12]=gMSAWave[6]/gMSAWave[13]
      ibig=0
      if (( gMSAWave[12]>15.0) %& (ix==1))
            ibig=1
      endif
       gMSAWave[11] = gMSAWave[5]*gMSAWave[13]*exp(gMSAWave[6]- gMSAWave[12])
      rgek =  gMSAWave[11]
      rak =  gMSAWave[12]
      ak2 = rak*rak
      ak1 = 1.0+rak
      dak2 = 1.0/ak2
      dak4 = dak2*dak2
      d = 1.0-reta
      d2 = d*d
      dak = d/rak                                                  
      dd2 = 1.0/d2
      dd4 = dd2*dd2
      dd45 = dd4*2.0e-1
      eta3d=3.0*reta
      eta6d = eta3d+eta3d
      eta32 = eta3+ eta3
      eta2d = reta+2.0
      eta2d2 = eta2d*eta2d
      eta21 = 2.0*reta+1.0
      eta22 = eta21*eta21

//     ALPHA(I)

      al1 = -eta21*dak
      al2 = (14.0*eta2-4.0*reta-1.0)*dak2
      al3 = 36.0*eta2*dak4

//      BETA(I)

      be1 = -(eta2+7.0*reta+1.0)*dak
      be2 = 9.0*reta*(eta2+4.0*reta-2.0)*dak2
      be3 = 12.0*reta*(2.0*eta2+8.0*reta-1.0)*dak4

//      NU(I)

      vu1 = -(eta3+3.0*eta2+45.0*reta+5.0)*dak
      vu2 = (eta32+3.0*eta2+42.0*reta-2.0e1)*dak2
      vu3 = (eta32+3.0e1*reta-5.0)*dak4
      vu4 = vu1+e24*rak*vu3
      vu5 = eta6d*(vu2+4.0*vu3)

//      PHI(I)
      
      ph1 = eta6d/rak
      ph2 = d-e12*dak2

//      TAU(I)

      ta1 = (reta+5.0)/(5.0*rak)
      ta2 = eta2d*dak2
      ta3 = -e12*rgek*(ta1+ta2)
      ta4 = eta3d*ak2*(ta1*ta1-ta2*ta2)
      ta5 = eta3d*(reta+8.0)*1.0e-1-2.0*eta22*dak2

//     DOUBLE PRECISION SINH(K), COSH(K)

      ex1 = exp(rak)
      ex2 = 0.0
      if ( gMSAWave[12]<20.0)
           ex2=exp(-rak)
      endif
      sk=0.5*(ex1-ex2)
      ck = 0.5*(ex1+ex2)
      ckma = ck-1.0-rak*sk
      skma = sk-rak*ck

//      a(I)

      a1 = (e24*rgek*(al1+al2+ak1*al3)-eta22)*dd4
      if (ibig==0)
		a2 = e24*(al3*skma+al2*sk-al1*ck)*dd4
		a3 = e24*(eta22*dak2-0.5*d2+al3*ckma-al1*sk+al2*ck)*dd4
	endif

//      b(I)

      b1 = (1.5*reta*eta2d2-e12*rgek*(be1+be2+ak1*be3))*dd4
      if (ibig==0)
		b2 = e12*(-be3*skma-be2*sk+be1*ck)*dd4
		b3 = e12*(0.5*d2*eta2d-eta3d*eta2d2*dak2-be3*ckma+be1*sk-be2*ck)*dd4
	endif

//      V(I)

      v1 = (eta21*(eta2-2.0*reta+1.0e1)*2.5e-1-rgek*(vu4+vu5))*dd45
      if (ibig==0)
		v2 = (vu4*ck-vu5*sk)*dd45
		v3 = ((eta3-6.0*eta2+5.0)*d-eta6d*(2.0*eta3-3.0*eta2+18.0*reta+1.0e1)*dak2+e24*vu3+vu4*sk-vu5*ck)*dd45
	endif


//       P(I)

      pp1 = ph1*ph1
      pp2 = ph2*ph2
      pp = pp1+pp2
      p1p2 = ph1*ph2*2.0
      p1 = (rgek*(pp1+pp2-p1p2)-0.5*eta2d)*dd2
      if (ibig==0)
		p2 = (pp*sk+p1p2*ck)*dd2
		p3 = (pp*ck+p1p2*sk+pp1-pp2)*dd2
	endif

//       T(I)
 
      t1 = ta3+ta4*a1+ta5*b1
      if (ibig!=0)

//		VERY LARGE SCREENING:  ASYMPTOTIC SOLUTION

  		v3 = ((eta3-6.0*eta2+5.0)*d-eta6d*(2.0*eta3-3.0*eta2+18.0*reta+1.0e1)*dak2+e24*vu3)*dd45
		t3 = ta4*a3+ta5*b3+e12*ta2 - 4.0e-1*reta*(reta+1.0e1)-1.0
		p3 = (pp1-pp2)*dd2
		b3 = e12*(0.5*d2*eta2d-eta3d*eta2d2*dak2+be3)*dd4
		a3 = e24*(eta22*dak2-0.5*d2-al3)*dd4
		um6 = t3*a3-e12*v3*v3
		um5 = t1*a3+a1*t3-e24*v1*v3
		um4 = t1*a1-e12*v1*v1
		al6 = e12*p3*p3
		al5 = e24*p1*p3-b3-b3-ak2
		al4 = e12*p1*p1-b1-b1
		w56 = um5*al6-al5*um6
		w46 = um4*al6-al4*um6
		fa = -w46/w56
		ca = -fa
		gMSAWave[3] = fa
		gMSAWave[2] = ca
		gMSAWave[1] = b1+b3*fa
		gMSAWave[0] = a1+a3*fa
		gMSAWave[8] = v1+v3*fa
		gMSAWave[14] = -(p1+p3*fa)
		gMSAWave[15] = gMSAWave[14]
		if (abs(gMSAWave[15])<1.0e-3)
		     gMSAWave[15] = 0.0
		endif
		gMSAWave[10] = gMSAWave[16]
	else
		t2 = ta4*a2+ta5*b2+e12*(ta1*ck-ta2*sk)
		t3 = ta4*a3+ta5*b3+e12*(ta1*sk-ta2*(ck-1.0))-4.0e-1*reta*(reta+1.0e1)-1.0

//		MU(i)

		um1 = t2*a2-e12*v2*v2
		um2 = t1*a2+t2*a1-e24*v1*v2
		um3 = t2*a3+t3*a2-e24*v2*v3
		um4 = t1*a1-e12*v1*v1
		um5 = t1*a3+t3*a1-e24*v1*v3
		um6 = t3*a3-e12*v3*v3

//			GILLAN CONDITION ?
//
//			YES - G(X=1+) = 0
//
//			COEFFICIENTS AND FUNCTION VALUE
//
		IF ((IX==1) %| (IX==3))

//			NO - CALCULATE REMAINING COEFFICIENTS.

//			LAMBDA(I)

			al1 = e12*p2*p2
			al2 = e24*p1*p2-b2-b2
			al3 = e24*p2*p3
			al4 = e12*p1*p1-b1-b1
			al5 = e24*p1*p3-b3-b3-ak2
			al6 = e12*p3*p3

//			OMEGA(I)

			w16 = um1*al6-al1*um6
			w15 = um1*al5-al1*um5
			w14 = um1*al4-al1*um4
			w13 = um1*al3-al1*um3
			w12 = um1*al2-al1*um2

			w26 = um2*al6-al2*um6
			w25 = um2*al5-al2*um5
			w24 = um2*al4-al2*um4

			w36 = um3*al6-al3*um6
			w35 = um3*al5-al3*um5
			w34 = um3*al4-al3*um4
			w32 = um3*al2-al3*um2
//
			w46 = um4*al6-al4*um6
			w56 = um5*al6-al5*um6
			w3526 = w35+w26
			w3425 = w34+w25
       
//			QUARTIC COEFFICIENTS

			w4 = w16*w16-w13*w36
			w3 = 2.0*w16*w15-w13*w3526-w12*w36
			w2 = w15*w15+2.0*w16*w14-w13*w3425-w12*w3526
			w1 = 2.0*w15*w14-w13*w24-w12*w3425
			w0 = w14*w14-w12*w24

//			ESTIMATE THE STARTING VALUE OF f

			if (ix==1)

//				LARGE K

				fap = (w14-w34-w46)/(w12-w15+w35-w26+w56-w32)
			else


//				ASSUME NOT TOO FAR FROM GILLAN CONDITION.
//				IF BOTH RGEK AND RAK ARE SMALL, USE P-W ESTIMATE.

				gMSAWave[14]=0.5*eta2d*dd2*exp(-rgek)
				if (( gMSAWave[11]<=2.0) %& ( gMSAWave[11]>=0.0) %& ( gMSAWave[12]<=1.0))
					e24g = e24*rgek*exp(rak)
					pwk = sqrt(e24g)
					qpw = (1.0-sqrt(1.0+2.0*d2*d*pwk/eta22))*eta21/d
					gMSAWave[14] = -qpw*qpw/e24+0.5*eta2d*dd2
				endif
  				pg = p1+gMSAWave[14]
				ca = ak2*pg+2.0*(b3*pg-b1*p3)+e12*gMSAWave[14]*gMSAWave[14]*p3
				ca = -ca/(ak2*p2+2.0*(b3*p2-b2*p3))
				fap = -(pg+p2*ca)/p3
			endif

//			AND REFINE IT ACCORDING TO NEWTON

			ii=0
			do 
  				ii = ii+1
				if (ii>itm)

//					FAILED TO CONVERGE IN ITM ITERATIONS

  					ir=-2
					return ir
				endif
				fa = fap
				fun = w0+(w1+(w2+(w3+w4*fa)*fa)*fa)*fa
				fund = w1+(2.0*w2+(3.0*w3+4.0*w4*fa)*fa)*fa
				fap = fa-fun/fund
				del=abs((fap-fa)/fa)
			while (del>acc)
			ir = ir+ii
			fa = fap
			ca = -(w16*fa*fa+w15*fa+w14)/(w13*fa+w12)
			gMSAWave[14] = -(p1+p2*ca+p3*fa)
			gMSAWave[15] = gMSAWave[14]
			if (abs(gMSAWave[15])<1.0e-3)
			      gMSAWave[15] = 0.0
			endif
			gMSAWave[10] = gMSAWave[16]
		else
			ca = ak2*p1+2.0*(b3*p1-b1*p3)
			ca = -ca/(ak2*p2+2.0*(b3*p2-b2*p3))
			fa = -(p1+p2*ca)/p3
			if (ix==2)
			        gMSAWave[15] = um1*ca*ca+(um2+um3*fa)*ca+um4+um5*fa+um6*fa*fa
			endif
			if (ix==4)
			       gMSAWave[15] = -(p1+p2*ca+p3*fa)
			endif
		endif
   		gMSAWave[3] = fa
		gMSAWave[2] = ca
		gMSAWave[1] = b1+b2*ca+b3*fa
		gMSAWave[0] = a1+a2*ca+a3*fa
		gMSAWave[8] = (v1+v2*ca+v3*fa)/gMSAWave[0]
	endif
   	g24 = e24*rgek*ex1
	 gMSAWave[7] = (rak*ak2*ca-g24)/(ak2*g24)
      return ir
      end

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//
//      CALCULATES S(Q) FOR "SQHPA"
//
//  **  THIS ROUTINE WORKS LOCALLY IN DOUBLE PRECISION **
//
//    JOHN B. HAYTER  (I.L.L.)    19-AUG-81
//


Function sqhcal(qq)
      	variable qq
      	
      	variable SofQ,etaz,akz,gekz,e24,x1,x2,ck,sk,ak2,qk,q2k,qk2,qk3,qqk,sink,cosk,asink,qcosk,aqk,inter  		
	WAVE gMSAWave = $"root:HayPenMSA:gMSAWave"
	
	
	//NVAR a=root:HayPenMSA:a
	//NVAR b=root:HayPenMSA:b
	//NVAR c=root:HayPenMSA:c
	//NVAR f=root:HayPenMSA:f
	//NVAR eta=root:HayPenMSA:eta
	//NVAR gek=root:HayPenMSA:gek
	//NVAR ak=root:HayPenMSA:ak
	//NVAR u=root:HayPenMSA:u
	//NVAR v=root:HayPenMSA:v
	//NVAR gamk=root:HayPenMSA:gamk
	//NVAR seta=root:HayPenMSA:seta
	//NVAR sgek=root:HayPenMSA:sgek
	//NVAR sak=root:HayPenMSA:sak
	//NVAR scal=root:HayPenMSA:scal
	//NVAR g1=root:HayPenMSA:g1

      etaz = gMSAWave[10]
      akz =  gMSAWave[12]
      gekz =  gMSAWave[11]
      e24 = 24.0*etaz
      x1 = exp(akz)
      x2 = 0.0
      if ( gMSAWave[12]<20.0)
             x2 = exp(-akz)
      endif
      ck = 0.5*(x1+x2)
      sk = 0.5*(x1-x2)
      ak2 = akz*akz

      if (qq<=0.0) 
		SofQ = -1.0/gMSAWave[0]
	else
		qk = qq/gMSAWave[13]
		q2k = qk*qk
		qk2 = 1.0/q2k
		qk3 = qk2/qk
		qqk = 1.0/(qk*(q2k+ak2))
		sink = sin(qk)
		cosk = cos(qk)
		asink = akz*sink
		qcosk = qk*cosk
		aqk = gMSAWave[0]*(sink-qcosk)
     		aqk=aqk+gMSAWave[1]*((2.0*qk2-1.0)*qcosk+2.0*sink-2.0/qk)
     		inter=24.0*qk3+4.0*(1.0-6.0*qk2)*sink
     		aqk=(aqk+0.5*etaz*gMSAWave[0]*(inter-(1.0-12.0*qk2+24.0*qk2*qk2)*qcosk))*qk3
     		aqk=aqk +gMSAWave[2]*(ck*asink-sk*qcosk)*qqk
     		aqk=aqk +gMSAWave[3]*(sk*asink-qk*(ck*cosk-1.0))*qqk
     		aqk=aqk +gMSAWave[3]*(cosk-1.0)*qk2
     		aqk=aqk -gekz*(asink+qcosk)*qqk
		SofQ = 1.0/(1.0-e24*aqk)
      endif
      return SofQ
end
      
