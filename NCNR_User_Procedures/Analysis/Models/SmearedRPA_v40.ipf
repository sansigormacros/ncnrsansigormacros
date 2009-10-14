#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// currently, there is NO XOP version of RPA, since there is an extra input parameter
// wave that must be carried into the function.
// this can be done with the STRUCT, if extra space is allocated for such
//
//
Proc PlotRPAForm(num,qmin,qmax,nCASE)
	Variable num=100,qmin=0.001,qmax=0.5
	Variable/g gCASE 		//Global Variable
	Variable nCASE
	Prompt num "Enter number of data points: "
	Prompt qmin "Enter minimum Q value (A^-1): "
	Prompt qmax "Enter maximum Q value (A^-1): "
	Prompt nCASE, "Choose one of the following cases:",popup "CASE 1: C/D BINARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 2: C-D DIBLOCK COPOLYMER;"
	"CASE 3: B/C/D TERNARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 4: B/C-D MIXTURE OF HOMOPOLYMER B AND DIBLOCK COPOLYMER C-D;"
	"CASE 5: B-C-D TRIBLOCK COPOLYMER;"
	"CASE 6: A/B/C/D QUATERNARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 7: A/B/C-D MIXTURE OF TWO HOMOPOLYMERS A/B AND A DIBLOCK C-D;"
	"CASE 8: A/B-C-D MIXTURE OF A HOMOPOLYMER A AND A TRIBLOCK B-C-D;"
	"CASE 9: A-B/C-D MIXTURE OF TWO DIBLOCK COPOLYMERS A-B AND C-D;"
	"CASE 10: A-B-C-D FOUR-BLOCK COPOLYMER"

	Make/O/D/n=(num) xwave_rpa,ywave_rpa
	//xwave_rpa=qmin+x*(qmax-qmin)/num
	//switch to log-scaling of the q-values
	xwave_rpa=alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	
	gCASE = nCASE
//	print gCASE

	IF(gCASE <=2)
		Make/O/D inputvalues={1000,0.5,100,1.e-12,1000,0.5,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. LengthLd"}
		Edit inputnames,inputvalues
		Make/O/D coef_rpa = {5,5,-.0004,1,0}
		make/o/t parameters_rpa = {"Seg. Length bc","Seg. Length bd","Chi Param. Kcd","scale","Background"}
		Edit parameters_rpa,coef_rpa
	ENDIF

	IF((gCASE >2) %& (gCASE<=5))
		Make/O/D inputvalues={1000,0.33,100,1.e-12,1000,0.33,100,1.e-12,1000,0.33,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Nb","Vol. Frac. Phib","Spec. Vol. Vb","Scatt. Length Lb","Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. Length Ld"}
		Edit inputnames,inputvalues
		Make/O/D coef_rpa = {5,5,5,-.0004,-.0004,-.0004,1,0}
		make/o/t parameters_rpa = {"Seg. Length bb","Seg. Length bc","Seg. Length bd","Chi Param. Kbc","Chi Param. Kbd","Chi Param. Kcd","scale","Background"}
		Edit parameters_rpa,coef_rpa
	ENDIF

	IF(gCASE >5)
		Make/O/D inputvalues={1000,0.25,100,1.e-12,1000,0.25,100,1.e-12,1000,0.25,100,1.e-12,1000,0.25,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Na","Vol. Frac. Phia","Spec. Vol. Va","Scatt. Length La","Deg. Polym. Nb","Vol. Frac. Phib","Spec. Vol. Vb","Scatt. Length Lb","Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. Length Ld"}
		Edit inputnames,inputvalues
		Make/O/D coef_rpa = {5,5,5,5,-.0004,-.0004,-.0004,-.0004,-.0004,-.0004,1,0}
		make/o/t parameters_rpa = {"Seg. Length ba","Seg. Length bb","Seg. Length bc","Seg. Length bd","Chi Param. Kab","Chi Param. Kac","Chi Param. Kad","Chi Param. Kbc","Chi Param. Kbd","Chi Param. Kcd","scale","Background"}
		Edit parameters_rpa,coef_rpa
	ENDIF
	
	Variable/G root:g_rpa
	g_rpa := RPAForm(coef_rpa,ywave_rpa,xwave_rpa)
	Display ywave_rpa vs xwave_rpa
//	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "Q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("RPAForm","coef_rpa","parameters_rpa","rpa")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedRPAForm(str,nCASE)								
	String str
	Variable nCASE
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	Prompt nCASE, "Choose one of the following cases:",popup "CASE 1: C/D BINARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 2: C-D DIBLOCK COPOLYMER;"
	"CASE 3: B/C/D TERNARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 4: B/C-D MIXTURE OF HOMOPOLYMER B AND DIBLOCK COPOLYMER C-D;"
	"CASE 5: B-C-D TRIBLOCK COPOLYMER;"
	"CASE 6: A/B/C/D QUATERNARY MIXTURE OF HOMOPOLYMERS;"
	"CASE 7: A/B/C-D MIXTURE OF TWO HOMOPOLYMERS A/B AND A DIBLOCK C-D;"
	"CASE 8: A/B-C-D MIXTURE OF A HOMOPOLYMER A AND A TRIBLOCK B-C-D;"
	"CASE 9: A-B/C-D MIXTURE OF TWO DIBLOCK COPOLYMERS A-B AND C-D;"
	"CASE 10: A-B-C-D FOUR-BLOCK COPOLYMER"
	
	SetDataFolder $("root:"+str)

	Variable/g gCASE 		//Global Variable

	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	gCASE = nCASE
//	print gCASE

	
	IF(gCASE <=2)
		Make/O/D inputvalues={1000,0.5,100,1.e-12,1000,0.5,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. LengthLd"}
		Edit inputnames,inputvalues
		Make/O/D smear_coef_rpa = {5,5,-.0004,1,0}
		make/o/t smear_parameters_rpa = {"Seg. Length bc","Seg. Length bd","Chi Param. Kcd","scale","Background"}
		Edit smear_parameters_rpa,smear_coef_rpa
	ENDIF

	IF((gCASE >2) %& (gCASE<=5))
		Make/O/D inputvalues={1000,0.33,100,1.e-12,1000,0.33,100,1.e-12,1000,0.33,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Nb","Vol. Frac. Phib","Spec. Vol. Vb","Scatt. Length Lb","Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. Length Ld"}
		Edit inputnames,inputvalues
		Make/O/D smear_coef_rpa = {5,5,5,-.0004,-.0004,-.0004,1,0}
		make/o/t smear_parameters_rpa = {"Seg. Length bb","Seg. Length bc","Seg. Length bd","Chi Param. Kbc","Chi Param. Kbd","Chi Param. Kcd","scale","Background"}
		Edit smear_parameters_rpa,smear_coef_rpa
	ENDIF

	IF(gCASE >5)
		Make/O/D inputvalues={1000,0.25,100,1.e-12,1000,0.25,100,1.e-12,1000,0.25,100,1.e-12,1000,0.25,100,0.e-12}
		make/o/t inputnames={"Deg. Polym. Na","Vol. Frac. Phia","Spec. Vol. Va","Scatt. Length La","Deg. Polym. Nb","Vol. Frac. Phib","Spec. Vol. Vb","Scatt. Length Lb","Deg. Polym. Nc","Vol. Frac. Phic","Spec. Vol. Vc","Scatt. Length Lc","Deg. Polym. Nd","Vol. Frac. Phid","Spec. Vol. Vd","Scatt. Length Ld"}
		Edit inputnames,inputvalues
		Make/O/D smear_coef_rpa = {5,5,5,5,-.0004,-.0004,-.0004,-.0004,-.0004,-.0004,1,0}
		make/o/t smear_parameters_rpa = {"Seg. Length ba","Seg. Length bb","Seg. Length bc","Seg. Length bd","Chi Param. Kab","Chi Param. Kac","Chi Param. Kad","Chi Param. Kbc","Chi Param. Kbd","Chi Param. Kcd","scale","Background"}
		Edit smear_parameters_rpa,smear_coef_rpa
	ENDIF
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_rpa,smeared_qvals	
	SetScale d,0,0,"1/cm",smeared_rpa					
		
	Variable/G gs_rpa=0
	gs_rpa := fSmearedRPAForm(smear_coef_rpa,smeared_rpa,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_rpa vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedRPAForm","smear_coef_rpa","smear_parameters_rpa","rpa")
End

///////////////////////////////////////////////////////////////
//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
//
// there is no RPAFormX due to the extra inputValues wave of information...
//
Function RPAForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("RPAFormX")
	yw = RPAFormX(cw,xw)
#else
	yw = fRPAForm(cw,xw)
#endif
	return(0)
End


Function fRPAForm(w,x) : FitFunc
	Wave w
	Variable x
	
//	print (GetWavesDataFolder(w,1)+"inputvalues")

	Wave var=$(GetWavesDataFolder(w,1)+"inputvalues")
	Nvar lCASE=$(GetWavesDataFolder(w,1)+"gCASE")
//	print lCASE
//	Variable lCASE
//	RANDOM PHASE APPROXIMATION FOR A FOUR-BLOCK COPOLYMER A-B-C-D
//	THIS FORMALISM APPLIES TO MULTICOMPONENT POLYMER MIXTURES
//	IN THE HOMOGENEOUS (MIXED) PHASE REGION ONLY.

//	THIS GENERAL CASE INCLUDES A MULTITUDE OF (TEN) SPECIAL CASES.

//	HERE ARE THE VARIOUS CASES COVERED:
//	CASE 1: C/D BINARY MIXTURE OF HOMOPOLYMERS
//	CASE 2: C-D DIBLOCK COPOLYMER
//	CASE 3: B/C/D TERNARY MIXTURE OF HOMOPOLYMERS
//	CASE 4: B/C-D MIXTURE OF HOMOPOLYMER B AND DIBLOCK COPOLYMER C-D
//	CASE 5: B-C-D TRIBLOCK COPOLYMER
//	CASE 6: A/B/C/D QUATERNARY MIXTURE OF HOMOPOLYMERS
//	CASE 7: A/B/C-D MIXTURE OF TWO HOMOPOLYMERS A/B AND A DIBLOCK C-D
//	CASE 8: A/B-C-D MIXTURE OF A HOMOPOLYMER A AND A TRIBLOCK B-C-D
//	CASE 9: A-B/C-D MIXTURE OF TWO DIBLOCK COPOLYMERS A-B AND C-D
//	CASE 10: A-B-C-D FOUR-BLOCK COPOLYMER

//	B. HAMMOUDA, NIST, JULY 1998

	Variable Na,Nb,Nc,Nd,Nab,Nac,Nad,Nba,Nbc,Nbd,Nca,Ncb,Ncd
	Variable Phia,Phib,Phic,Phid,Phiab,Phiac,Phiad
	Variable Phiba,Phibc,Phibd,Phica,Phicb,Phicd,Phida,Phidb,Phidc
	Variable va,vb,vc,vd,vab,vac,vad,vba,vbc,vbd,vca,vcb,vcd,vda,vdb,vdc
	Variable m
	Variable ba,bb,bc,bd
	Variable Q
	Variable Xa,Xb,Xc,Xd
	Variable Paa,S0aa,Pab,S0ab,Pac,S0ac,Pad,S0ad
	Variable Pba,S0ba,Pbb,S0bb,Pbc,S0bc,Pbd,S0bd
	Variable Pca,S0ca,Pcb,S0cb,Pcc,S0cc,Pcd,S0cd
	Variable Pda,S0da,Pdb,S0db,Pdc,S0dc,Pdd,S0dd
	Variable Kaa,Kab,Kac,Kad,Kba,Kbb,Kbc,Kbd
	Variable Kca,Kcb,Kcc,Kcd,Kda,Kdb,Kdc,Kdd
	Variable Zaa,Zab,Zac,Zba,Zbb,Zbc,Zca,Zcb,Zcc
	Variable DenT,T11,T12,T13,T21,T22,T23,T31,T32,T33
	Variable Y1,Y2,Y3,X11,X12,X13,X21,X22,X23,X31,X32,X33
	Variable ZZ,DenQ1,DenQ2,DenQ3,DenQ,Q11,Q12,Q13,Q21,Q22,Q23,Q31,Q32,Q33
	Variable N11,N12,N13,N21,N22,N23,N31,N32,N33
	Variable M11,M12,M13,M21,M22,M23,M31,M32,M33
	Variable S11,S12,S13,S14,S21,S22,S23,S24
	Variable S31,S32,S33,S34,S41,S42,S43,S44
	Variable La,Lb,Lc,Ld,Lad,Lbd,Lcd,Nav,Int
	Variable scale
	Variable Background
	Variable ii=0	//to fool curve fitting dialog to let you pick the coefficient wave

	Na=1000
	Nb=1000
	Nc=1000
	Nd=1000	//DEGREE OF POLYMERIZATION	
	Phia=0.25
	Phib=0.25
	Phic=0.25
	Phid=0.25 	//VOL FRACTION
	Kab=-.0004
	Kac=-.0004
	Kad=-.0004	//CHI PARAM
	Kbc=-.0004
	Kbd=-.0004
	Kcd=-.0004	
	La=1.E-12
	Lb=1.E-12
	Lc=1.E-12
	Ld=0.E-12 	//SCATT. LENGTH
	va=100
	vb=100
	vc=100
	vd=100		//SPECIFIC VOLUME
	ba=5
	bb=5
	bc=5
	bd=5		//SEGMENT LENGTH

	IF (lCASE <= 2)
		Phia=0.0000001
		Phib=0.0000001
		Phic=0.5
		Phid=0.5
		Nc=var[0]
		Phic=var[1]
		vc=var[2]
		Lc=var[3]
		bc=w[ii+0]
		Nd=var[4]
		Phid=var[5]
		vd=var[6]
		Ld=var[7]
		bd=w[ii+1]
		Kcd=w[ii+2]
		scale=w[ii+3]	
		background=w[ii+4]
	ENDIF

	IF ((lCASE > 2) %& (lCASE <= 5))
		Phia=0.0000001
		Phib=0.333333
		Phic=0.333333
		Phid=0.333333
		Nb=var[0]
		Phib=var[1]
		vb=var[2]
		Lb=var[3]
		bb=w[ii+0]
		Nc=var[4]
		Phic=var[5]
		vc=var[6]
		Lc=var[7]
		bc=w[ii+1]
		Nd=var[8]
		Phid=var[9]
		vd=var[10]
		Ld=var[11]
		bd=w[ii+2]
		Kbc=w[ii+3]
		Kbd=w[ii+4]
		Kcd=w[ii+5]
		scale=w[ii+6]	
		background=w[ii+7]
	ENDIF

	IF (lCASE > 5)
		Phia=0.25
		Phib=0.25
		Phic=0.25
		Phid=0.25
		Na=var[0]
		Phia=var[1]
		va=var[2]
		La=var[3]
		ba=w[ii+0]
		Nb=var[4]
		Phib=var[5]
		vb=var[6]
		Lb=var[7]
		bb=w[ii+1]
		Nc=var[8]
		Phic=var[9]
		vc=var[10]
		Lc=var[11]
		bc=w[ii+2]
		Nd=var[12]
		Phid=var[13]
		vd=var[14]
		Ld=var[15]
		bd=w[ii+3]
		Kab=w[ii+4]
		Kac=w[ii+5]
		Kad=w[ii+6]
		Kbc=w[ii+7]
		Kbd=w[ii+8]
		Kcd=w[ii+9]
		scale=w[ii+10]	
		background=w[ii+11]
	ENDIF

	Nab=(Na*Nb)^(0.5)
	Nac=(Na*Nc)^(0.5)
	Nad=(Na*Nd)^(0.5)
	Nbc=(Nb*Nc)^(0.5)
	Nbd=(Nb*Nd)^(0.5)
	Ncd=(Nc*Nd)^(0.5)

	vab=(va*vb)^(0.5)
	vac=(va*vc)^(0.5)
	vad=(va*vd)^(0.5)
	vbc=(vb*vc)^(0.5)
	vbd=(vb*vd)^(0.5)
	vcd=(vc*vd)^(0.5)

	Phiab=(Phia*Phib)^(0.5)
	Phiac=(Phia*Phic)^(0.5)
	Phiad=(Phia*Phid)^(0.5)
	Phibc=(Phib*Phic)^(0.5)
	Phibd=(Phib*Phid)^(0.5)
	Phicd=(Phic*Phid)^(0.5)

	Q=x
	Xa=Q^2*ba^2*Na/6
	Xb=Q^2*bb^2*Nb/6
	Xc=Q^2*bc^2*Nc/6
	Xd=Q^2*bd^2*Nd/6

	Paa=2*(Exp(-Xa)-1+Xa)/Xa^2
	S0aa=Na*Phia*va*Paa
	Pab=((1-Exp(-Xa))/Xa)*((1-Exp(-Xb))/Xb)
	S0ab=(Phiab*vab*Nab)*Pab
	Pac=((1-Exp(-Xa))/Xa)*Exp(-Xb)*((1-Exp(-Xc))/Xc)
	S0ac=(Phiac*vac*Nac)*Pac
	Pad=((1-Exp(-Xa))/Xa)*Exp(-Xb-Xc)*((1-Exp(-Xd))/Xd)
	S0ad=(Phiad*vad*Nad)*Pad

	S0ba=S0ab
	Pbb=2*(Exp(-Xb)-1+Xb)/Xb^2
	S0bb=Nb*Phib*vb*Pbb
	Pbc=((1-Exp(-Xb))/Xb)*((1-Exp(-Xc))/Xc)
	S0bc=(Phibc*vbc*Nbc)*Pbc
	Pbd=((1-Exp(-Xb))/Xb)*Exp(-Xc)*((1-Exp(-Xd))/Xd)
	S0bd=(Phibd*vbd*Nbd)*Pbd

	S0ca=S0ac
	S0cb=S0bc
	Pcc=2*(Exp(-Xc)-1+Xc)/Xc^2
	S0cc=Nc*Phic*vc*Pcc
	Pcd=((1-Exp(-Xc))/Xc)*((1-Exp(-Xd))/Xd)
	S0cd=(Phicd*vcd*Ncd)*Pcd

	S0da=S0ad
	S0db=S0bd
	S0dc=S0cd
	Pdd=2*(Exp(-Xd)-1+Xd)/Xd^2
	S0dd=Nd*Phid*vd*Pdd

	IF(lCASE == 1)
		S0aa=0.000001
		S0ab=0.000002		
		S0ac=0.000003		
		S0ad=0.000004		
		S0bb=0.000005		
		S0bc=0.000006		
		S0bd=0.000007		
		S0cd=0.000008
	ENDIF

	IF(lCASE == 2)
		S0aa=0.000001
		S0ab=0.000002		
		S0ac=0.000003		
		S0ad=0.000004		
		S0bb=0.000005		
		S0bc=0.000006		
		S0bd=0.000007		
	ENDIF
	
	IF(lCASE == 3)
		S0aa=0.000001		
		S0ab=0.000002		
		S0ac=0.000003		
		S0ad=0.000004		
		S0bc=0.000005		
		S0bd=0.000006		
		S0cd=0.000007		
	ENDIF

	IF(lCASE == 4)
		S0aa=0.000001		
		S0ab=0.000002		
		S0ac=0.000003		
		S0ad=0.000004		
		S0bc=0.000005		
		S0bd=0.000006		
	ENDIF

	IF(lCASE == 5)
		S0aa=0.000001		
		S0ab=0.000002		
		S0ac=0.000003		
		S0ad=0.000004		
	ENDIF

	IF(lCASE == 6)
		S0ab=0.000001		
		S0ac=0.000002		
		S0ad=0.000003		
		S0bc=0.000004		
		S0bd=0.000005		
		S0cd=0.000006
	ENDIF

	IF(lCASE == 7)
		S0ab=0.000001		
		S0ac=0.000002		
		S0ad=0.000003		
		S0bc=0.000004		
		S0bd=0.000005		
	ENDIF

	IF(lCASE == 8)
		S0ab=0.000001		
		S0ac=0.000002		
		S0ad=0.000003		
	ENDIF

	IF(lCASE == 9)
		S0ac=0.000001		
		S0ad=0.000002		
		S0bc=0.000003		
		S0bd=0.000004
	ENDIF

	S0ba=S0ab		
	S0ca=S0ac		
	S0cb=S0bc		
	S0da=S0ad		
	S0db=S0bd		
	S0dc=S0cd		

	Kaa=0
	Kbb=0
	Kcc=0
	Kdd=0

	Kba=Kab
	Kca=Kac
	Kcb=Kbc
	Kda=Kad
	Kdb=Kbd
	Kdc=Kcd

	Zaa=Kaa-Kad-Kad  
	Zab=Kab-Kad-Kbd  
	Zac=Kac-Kad-Kcd
	Zba=Kba-Kbd-Kad  
	Zbb=Kbb-Kbd-Kbd  
	Zbc=Kbc-Kbd-Kcd
	Zca=Kca-Kcd-Kad  
	Zcb=Kcb-Kcd-Kbd  
	Zcc=Kcc-Kcd-Kcd

	DenT=(-(S0ac*S0bb*S0ca) + S0ab*S0bc*S0ca + S0ac*S0ba*S0cb - S0aa*S0bc*S0cb - S0ab*S0ba*S0cc + S0aa*S0bb*S0cc)

	T11= (-(S0bc*S0cb) + S0bb*S0cc)/DenT
	T12= (S0ac*S0cb - S0ab*S0cc)/DenT
	T13= (-(S0ac*S0bb) + S0ab*S0bc)/DenT
	T21= (S0bc*S0ca - S0ba*S0cc)/DenT
	T22= (-(S0ac*S0ca) + S0aa*S0cc)/DenT
	T23= (S0ac*S0ba - S0aa*S0bc)/DenT
	T31= (-(S0bb*S0ca) + S0ba*S0cb)/DenT
	T32= (S0ab*S0ca - S0aa*S0cb)/DenT
	T33= (-(S0ab*S0ba) + S0aa*S0bb)/DenT

	Y1=T11*S0ad+T12*S0bd+T13*S0cd+1
	Y2=T21*S0ad+T22*S0bd+T23*S0cd+1
	Y3=T31*S0ad+T32*S0bd+T33*S0cd+1

	X11=Y1*Y1 
	X12=Y1*Y2 
	X13=Y1*Y3
	X21=Y2*Y1 
	X22=Y2*Y2 
	X23=Y2*Y3
	X31=Y3*Y1 
	X32=Y3*Y2 
	X33=Y3*Y3

	ZZ=S0ad*(T11*S0ad+T12*S0bd+T13*S0cd)+S0bd*(T21*S0ad+T22*S0bd+T23*S0cd)+S0cd*(T31*S0ad+T32*S0bd+T33*S0cd)

	m=1/(S0dd-ZZ)

	N11=m*X11+Zaa 
	N12=m*X12+Zab 
	N13=m*X13+Zac
	N21=m*X21+Zba 
	N22=m*X22+Zbb 
	N23=m*X23+Zbc
	N31=m*X31+Zca 
	N32=m*X32+Zcb 
	N33=m*X33+Zcc

	M11= N11*S0aa + N12*S0ab + N13*S0ac
	M12= N11*S0ab + N12*S0bb + N13*S0bc
	M13= N11*S0ac + N12*S0bc + N13*S0cc
	M21= N21*S0aa + N22*S0ab + N23*S0ac
	M22= N21*S0ab + N22*S0bb + N23*S0bc
	M23= N21*S0ac + N22*S0bc + N23*S0cc
	M31= N31*S0aa + N32*S0ab + N33*S0ac
	M32= N31*S0ab + N32*S0bb + N33*S0bc
	M33= N31*S0ac + N32*S0bc + N33*S0cc

	DenQ1=1+M11-M12*M21+M22+M11*M22-M13*M31-M13*M22*M31
	DenQ2=	M12*M23*M31+M13*M21*M32-M23*M32-M11*M23*M32+M33+M11*M33
	DenQ3=	-M12*M21*M33+M22*M33+M11*M22*M33
	DenQ=DenQ1+DenQ2+DenQ3

	Q11= (1 + M22-M23*M32 + M33 + M22*M33)/DenQ
	Q12= (-M12 + M13*M32 - M12*M33)/DenQ
	Q13= (-M13 - M13*M22 + M12*M23)/DenQ
	Q21= (-M21 + M23*M31 - M21*M33)/DenQ
	Q22= (1 + M11 - M13*M31 + M33 + M11*M33)/DenQ
	Q23= (M13*M21 - M23 - M11*M23)/DenQ
	Q31= (-M31 - M22*M31 + M21*M32)/DenQ
	Q32= (M12*M31 - M32 - M11*M32)/DenQ
	Q33= (1 + M11 - M12*M21 + M22 + M11*M22)/DenQ

	S11= Q11*S0aa + Q21*S0ab + Q31*S0ac 
	S12= Q12*S0aa + Q22*S0ab + Q32*S0ac 
	S13= Q13*S0aa + Q23*S0ab + Q33*S0ac 
	S14=-S11-S12-S13
	S21= Q11*S0ba + Q21*S0bb + Q31*S0bc
	S22= Q12*S0ba + Q22*S0bb + Q32*S0bc
	S23= Q13*S0ba + Q23*S0bb + Q33*S0bc
	S24=-S21-S22-S23
	S31= Q11*S0ca + Q21*S0cb + Q31*S0cc
	S32= Q12*S0ca + Q22*S0cb + Q32*S0cc
	S33= Q13*S0ca + Q23*S0cb + Q33*S0cc
	S34=-S31-S32-S33
	S41=S14
	S42=S24
	S43=S34
	S44=S11+S22+S33+2*S12+2*S13+2*S23

	Nav=6.022045E23
	Lad=(La/va-Ld/vd)*SQRT(Nav)
	Lbd=(Lb/vb-Ld/vd)*SQRT(Nav)
	Lcd=(Lc/vc-Ld/vd)*SQRT(Nav)

	Int=Lad^2*S11+Lbd^2*S22+Lcd^2*S33+2*Lad*Lbd*S12+2*Lbd*Lcd*S23+2*Lad*Lcd*S13
	Int=Int*scale + background

//	print Q,Int,Nd,var[5],lCASE

	return Int
	
End

// this is all there is to the smeared calculation!
Function SmearedRPAForm(s) :FitFunc

	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(RPAForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedRPAForm(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedRPAForm(fs)
	
	return (0)
End