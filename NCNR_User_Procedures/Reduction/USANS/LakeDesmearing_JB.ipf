#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1

//////////////////////////////////////////////
// Igor conversion:	03 FEB 06 SRK
//			Revision:	03 MAR 06 SRK
//
//	Program uses Lake's iterative technique, J. A. Lake, Acta Cryst. 23 (1967) 191-4.
//	to DESMEAR Infinite slit smeared USANS DATA.
//
//	TO SEE DESCRIPTION, CHECK COMPUTER SOFTWARE LOGBOOK, P13,41-46, 50
//	J. BARKER, August, 2001
//	Switches from fast to slow convergence near target chi JGB 2/2003
//
// steps are:
// load
// mask
// extrapolate (find the power law of the desmeared set = smeared -1)
// smooth (optional)
// desmear based on dQv and chi^2 target
// save result
//
/////////
// Waves produced at each step: (Q/I/S with the following extensions)
//
// Load:		Uses -> nothing (Kills old waves)
//				Produces -> "_exp" and "_exp_orig"
//
// Mask:		Uses -> "_exp"
//				Produces -> "_msk"
//
// Extrapolate:	Uses -> nothing
//					Produces -> nothing
//
// Smooth:	Uses -> "_smth" OR "_msk" OR "_exp" (in that order)
//				Produces -> "_smth"
//
// Desmear:	Uses ->  "_smth" OR "_msk" OR "_exp" (in that order)
//				Produces -> "_dsm"
//
////////

///***** TO FIX *******
// - ? power law + background extrapolation (only useful for X-ray data...)
//
// see commented code lines for Igor 4 or Igor 5
// - there are only a few options and calls that are not Igor 4 compatible.
// Igor 4 routines are currently used.

////////////////////////////////////////////////////////////////////////

// main entry routine
Proc Desmear()

	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//check for the correct data folder, initialize if necessary
	//
	if(DataFolderExists(USANSFolder+":DSM") == 0)
		Execute "Init_Desmearing()"
	endif

	SetDataFolder $(USANSFolder+":DSM")
	//always initialize these global variables
	gStr1 = ""
	gStr2 = ""
	gIterStr = ""
	SetDataFolder root:

	DoWindow/F Desmear_Graph
	if(V_flag==0)
		Execute "Desmear_Graph()"
	endif
End

Proc Init_Desmearing()

	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//set up the folder(s) needed
	NewDataFolder/O $(USANSFolder+":DSM")
	NewDataFolder/O $(USANSFolder+":myGlobals")		//in case it wasn't created elsewhere

	SetDataFolder $(USANSFolder+":DSM")

	String/G gCurFile=""

	Variable/G gMaxFastIter = 100			//max number of iter in Fast convergence
	Variable/G gMaxSlowIter = 10000

	Variable/G gNptsExtrap = 15		//points for high q extrapolation
	Variable/G gChi2Target = 1		//chi^2 target
	Variable/G gPowerM = -4
	Variable/G gDqv = 0.117			//2005 measured slit height - see John
	Variable/G gNq = 1
	Variable/G gS = 0		// global varaible for Midpnt()
	Variable/G gSmoothFac=0.03

	Variable/G gChi2Final = 0		//chi^2 final
	Variable/G gIterations = 0		//total number of iterations

	String/G gStr1 = ""				//information strings
	String/G gStr2 = ""
	String/G gIterStr = ""
	Variable/G gChi2Smooth = 0

	Variable/G gFreshMask=1

	SetDataFolder root:
End

//////////// Lake desmearing routines

//	Smears guess Y --> YS using weighting array
Function DSM_Smear(Y_wave,Ys,NQ,FW)
	Wave Y_wave,Ys
	Variable nq
	Wave FW

	Variable ii,jj,summ
	for(ii=0;ii<nq;ii+=1)
		summ=0
		for(jj=0;jj<nq;jj+=1)
			summ = summ + Y_wave[jj]*FW[ii][jj]
		endfor
		Ys[ii] = summ
	endfor

	Return (0)
End

//	CALCULATES CHI^2
FUNCTION CHI2(ys_new,ys_exp,w,NQ)
	Wave ys_new,ys_exp,w
	Variable nq

	Variable CHI2,summ,ii

	SUMm = 0.0
	for(ii=0;ii<nq;ii+=1)
//		if(numtype(YS_EXP[ii]) == 0 && numtype(YS_NEW[ii]) == 0)
		SUMm=SUMm+W[ii]*(YS_EXP[ii]-YS_NEW[ii])^2
//		endif
	endfor

	CHI2=SUMm/(NQ-1)

	RETURN CHI2
END

//	Routine calculates the weights needed to convert a table
//	representation of a scattering function I(q) into the infinite
//	slit smeared table represented as Is(q)
//	Is(qi) = Sum(j=i-n) Wij*I(qj)
//	Program assumes data is extrapolated from qn to dqv using powerlaw
//	I(q) = Aq^m
//	Required input:
//	N	: Number of data points {in Global common block }
//	q(N)	: Array of q values     {in Global common block }
//	dqv	: Limit of slit length  {in Global common block }
//	m	: powerlaw for extrapolation.
//
//	Routine output:
//	W(N,N)	: Weights array
//
//	The weights obtained from this routine can be used to calculate
//	Is(q) for any I(q) function.
//
//	Calculation based upon linear interpolation between points.
//	See p.44, Computer Software Log book.
//	11/00 JGB
Function Weights_L(m,FW,Q_exp)		//changed input w to FW (FW is two dimensional)
	Variable m
	Wave FW,Q_exp

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	NVAR dqv = $(USANSFolder+":DSM:gDqv")
	NVAR NN = $(USANSFolder+":DSM:gNq")

//	Calculate Remainder fractions and put into separate array.
	Variable lower,ii,ss,jj
	Duplicate/O Q_exp $(USANSFolder+":DSM:R_wave")
	wave r_wave = $(USANSFolder+":DSM:R_wave")

//	Make/O/D/N=75 root:DSM:SS_save	//debug
//	wave SS_save = root:DSM:SS_save

	Print "calculating remainders by integration..."
	for(ii=0;ii<NN-1;ii+=1)
		lower = sqrt(Q_exp[NN-1]^2-Q_exp[ii]^2)
		ss = Qromo(lower,dqv,Q_exp[ii],m)		//new parameter list for Qromo call
//		SS_save[ii] = ss
		R_wave[ii] = (Q_exp[NN-1]^(-m)/dqv)*SS
//		Printf "I = %d R_wave[ii] =%g\r",ii,R_wave[ii]
	endfor

	lower = 0.0
	ss = Qromo(lower,dqv,Q_exp[NN-1],m)		//new parameter list for Qromo call
	R_wave[NN-1] = (Q_exp[NN-1]^(-m)/dqv)*SS
//	Printf "I = %d R_wave[ii] =%g\r",NN-1,R_wave[NN-1]
//	SS_save[ii] = ss

//	Make/O/D/N=(75,75) root:DSM:IG_save		//debug
//	wave IG_save=root:DSM:IG_save

//	Zero weight matrix... then fill it
	FW = 0
	Print "calculating full weights...."
//	Calculate weights
	for(ii=0;ii<NN;ii+=1)
		for(jj=ii+1;jj<NN-1;jj+=1)
			FW[ii][jj] = DU(ii,jj)*(1.0+Q_exp[jj]/(Q_exp[jj+1]-Q_exp[jj]))
			FW[ii][jj] -= (1.0/(Q_exp[jj+1]-Q_exp[jj]))*IG(ii,jj)
			FW[ii][jj] -= DU(ii,jj-1)*Q_exp[jj-1]/(Q_exp[jj]-Q_exp[jj-1])
			FW[ii][jj] += (1.0/(Q_exp[jj]-Q_exp[jj-1]))*IG(ii,jj-1)
			FW[ii][jj] *= (1.0/dqv)
//		Printf "FW[%d][%d] = %g\r",ii,jj,FW[ii][jj]
		endfor
	endfor
//
//	special case: I=J,I=N
	for(ii=0;ii<NN-1;ii+=1)
		FW[ii][ii] = DU(ii,ii)*(1.0+Q_exp[ii]/(Q_exp[ii+1]-Q_exp[ii]))
		FW[ii][ii] -= (1.0/(Q_exp[ii+1]-Q_exp[ii]))*IG(ii,ii)
		FW[ii][ii] *= (1.0/dqv)
//		Printf "FW[%d][%d] = %g\r",ii,jj,FW[ii][jj]
//     following line corrected for N -> NN-1 since Igor indexes from 0! (Q_exp[NN] DNE!)
		FW[ii][NN-1] = -DU(ii,NN-2)*Q_exp[NN-2]/(Q_exp[NN-1]-Q_exp[NN-2])
		FW[ii][NN-1] += (1.0/(Q_exp[NN-1]-Q_exp[NN-2]))*IG(ii,NN-2)
		FW[ii][NN-1] *= (1.0/dqv)
		FW[ii][NN-1] += R_wave[ii]
//		Printf "FW[%d][%d] = %g\r",ii,NN-1,FW[ii][NN-1]
	endfor
//
//	special case: I=J=N
	FW[NN-1][NN-1] = R_wave[NN-1]
//
	Return (0)
End

////
Function Integrand_dsm(u,qi,m)
	Variable u,qi,m

	Variable integrand
	Integrand = (u^2+qi^2)^(m/2)
	return integrand
end

///
Function DU(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave Q_exp = $(USANSFolder+":DSM:Q_exp")
	Variable DU

//	Wave DU_save=root:DSM:DU_save
	If (ii == jj)
	  DU = sqrt(Q_exp[jj+1]^2-Q_exp[ii]^2)
	Else
	  DU = sqrt(Q_exp[jj+1]^2-Q_exp[ii]^2) - sqrt(Q_exp[jj]^2-Q_exp[ii]^2)
	EndIf

//	DU_save[ii][jj] = DU
	Return DU
End

Function IG(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave Q_exp=$(USANSFolder+":DSM:Q_exp")
	Variable IG,UL,UU

//	WAVE IG_save = root:DSM:IG_save
	If (ii == jj)
	  UL=0.0
	Else
	  UL=sqrt(Q_exp[jj]^2-Q_exp[ii]^2)
	EndIf
	UU=sqrt(Q_exp[jj+1]^2-Q_exp[ii]^2)

	//in FORTRAN log = natural log....
	IG = UU*Q_exp[jj+1]+Q_exp[ii]^2*ln(UU+Q_exp[jj+1])
	IG -= UL*Q_exp[jj]
	IG -= Q_exp[ii]^2*ln(UL+Q_exp[jj])
	IG *= 0.5
//	IG_save[ii][jj] = IG

	Return IG
End

//
Function FF(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Variable FF
	NVAR dqv = $(USANSFolder+":DSM:gDqv")

	FF = (1.0/dqv)*(0.5+HH(ii,jj))
	Return FF
End

//
Function GG(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Variable GG
	NVAR dqv = $(USANSFolder+":DSM:gDqv")

	GG = (1.0/dqv)*(0.5-HH(ii,jj))
	Return	GG
End
//
Function HH(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave Q_exp=$(USANSFolder+":DSM:Q_exp")
	Variable HH

	HH = 0.5*(Q_exp[jj+1]+Q_exp[jj])/(Q_exp[jj+1]-Q_exp[jj])
	HH -= (1.0/(Q_exp[jj+1]-Q_exp[jj]))*(CC(ii,jj+1)-CC(ii,jj))
	return HH
End
//
//
Function CC(ii,jj)
	Variable ii,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	wave Q_exp = $(USANSFolder+":DSM:Q_exp")
	Variable CC

	If (ii == jj)
	  CC = 0.0
	Else
	  CC = (Q_exp[jj]-Q_exp[ii])^0.5
	EndIf
	Return CC
End

// QROMO is a gerneric NR routine that takes function arguments
// Call Qromo(Integrand,lower,dqv,Q_exp(N),m,SS,Midpnt)
// -- here, it is always called with Integrand and Midpnt as the functions
// -- so rewrite in a simpler way....
//
// SS is the returned value?
// H_wave, S_wave (original names H,S)
//
// modified using c-version in NR (pg 143)
Function QROMO(A,B,qi,m)
	Variable A,B,qi,m

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Variable EPS,JMAX,JMAXP,KM,K
	EPS=1.E-6
	JMAX=14
	KM=4
	K=KM+1

	Make/O/D/N=(JMAX) $(USANSFolder+":DSM:S_wave")
	Make/O/D/N=(JMAX+1) $(USANSFolder+":DSM:H_wave")
	wave S_wave=$(USANSFolder+":DSM:S_wave")
	wave H_wave=$(USANSFolder+":DSM:H_wave")
	S_wave=0
	H_wave=0

	H_Wave[0] = 1

	variable jj,SS,DSS

	for(jj=0;jj<jmax;jj+=1)
		S_wave[jj] = Midpnt(A,B,jj,qi,m)		//remove FUNC, always call Integrand from within Midpnt
		IF (jj>=KM)		//after 1st 5 points calculated
		    POLINT(H_wave,S_wave,jj-KM,KM,0.0,SS,DSS)		//ss, dss returned
		    IF (ABS(DSS) < EPS*ABS(SS))
		    	RETURN ss
		    endif
		ENDIF
//	  S_wave[jj+1]=S_wave[jj]
	  H_wave[jj+1]=H_wave[jj]/9.
	endfor

	DoAlert 0,"Too many steps in QROMO"
	return 1			//error if you get here
END

//
// see NR pg 109
// - Given input arrays xa[1..n] and ya[1..n], and a given value x
// return a value y and an error estimate dy. if P(x) is the polynomial of
// degree N-1 such that P(xai) = yai, then the returned value y=P(x)
//
// arrays XA[] and YA[] are passed in with an offset of the index
// of where to start the interpolation
Function POLINT(XA,YA,offset,N,X,Y,DY)
	Wave XA,YA
	Variable offset,N,X,&Y,&DY

	Variable ii,mm,nmax,ns,dif,den,ho,hp,wi,dift

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	NMAX=10

	Make/O/D/N=(NMAX) $(USANSFolder+":DSM:Ci"),$(USANSFolder+":DSM:Di")
	wave Ci = $(USANSFolder+":DSM:Ci")
	wave Di = $(USANSFolder+":DSM:Di")

	NS=1
	DIF=ABS(X-XA[0])
	for(ii=0;ii<n;ii+=1)
		DIFT=ABS(X-XA[ii+offset])
		IF (DIFT < DIF)
			NS=ii
			DIF=DIFT
		ENDIF
		Ci[ii]=YA[ii+offset]
		Di[ii]=YA[ii+offset]
	endfor

	Y=YA[NS+offset]
	NS=NS-1
	for(mm=1;mm<n-1;mm+=1)
		for(ii=0;ii<(n-mm);ii+=1)
			HO=XA[ii+offset]-X
			HP=XA[ii+offset+mm]-X
			Wi=Ci[ii+1]-Di[ii]
			DEN=HO-HP
			IF(DEN == 0.)
				print "den == 0 in POLINT - ERROR!!!"
			endif
			DEN=Wi/DEN
			Di[ii]=HP*DEN
			Ci[ii]=HO*DEN
		endfor	//ii
		IF (2*NS < (N-mm) )
			DY=Ci[NS+1]
		ELSE
			DY=Di[NS]
			NS=NS-1
		ENDIF
		Y=Y+DY
	endfor	//mm
	RETURN (0)		//y and dy are returned as pass-by-reference
END

//
// FUNC is always Integrand()
// again, see the c-version, NR pg 142
Function MIDPNT(A,B,N,qi,m)
	Variable A,B,N,qi,m

	Variable it,tnm,del,ddel,x,summ,jj

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	NVAR S_ret = $(USANSFolder+":DSM:gS")

	IF (N == 0)
		S_ret=(B-A)*Integrand_dsm(0.5*(A+B),qi,m)
//		Print "N==0, S_ret = ",s_ret
		return(S_ret)
	  		//IT=1
	ELSE
		//AJJ This code is confusing!
//		it = 1
//		for(jj=1;jj<n-1;jj+=1)
//			it *= 3
//		endfor
		//AJJ Equivalent and simpler
		it = 3^(N-1)
		//
		TNM=IT
		DEL=(B-A)/(3.*TNM)
		DDEL=DEL+DEL
		X=A+0.5*DEL
		SUMm=0.
		for(jj=1;jj<=it;jj+=1)
			SUMm=SUMm+Integrand_dsm(X,qi,m)
			X=X+DDEL
			SUMm=SUMm+Integrand_dsm(X,qi,m)
			X=X+DEL
		endfor
		S_ret=(S_ret+(B-A)*SUMm/TNM)/3.
		IT=3*IT
	ENDIF
	return S_ret
END

//////////// end of Lake desmearing routines

// - Almost everything below here is utility routines for data handling, panel
// controls, and all the fluff that makes this useable. Note that this is
// a lot more code than the actual guts of the Lake method!
// (the guts of the iteration are in the DemsearButtonProc)


// add three "fake" resolution columns to the output file so that it
// looks like a regular SANS data set, but make the sigQ column 100x smaller than Q
// so that there is effectively no resolution smearing. Set Qbar = Q, and fs = 1
//
// SRK 06 FEB 06
//
Function WriteUSANSDesmeared(fullpath,lo,hi,dialog)
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	String termStr="\r\n"
	String destStr = USANSFolder+":DSM:"
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr

	Variable refNum,integer,realval

	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE Q_dsm =$(destStr + "Q_dsm")
	WAVE I_dsm=$(destStr + "I_dsm")
	WAVE S_dsm=$(destStr + "S_dsm")

	//check each wave
	If(!(WaveExists(Q_dsm)))
		Abort "Q_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(I_dsm)))
		Abort "I_dsm DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(S_dsm)))
		Abort "S_dsm DNExist in WriteUSANSDesmeared()"
	Endif

	// 06 FEB 06 SRK
	// make dummy waves to hold the "fake" resolution, and write it as the last 3 columns
	//
	Duplicate/O Q_dsm,res1,res2,res3
	res3 = 1		// "fake" beamstop shadowing
	res1 /= 100		//make the sigmaQ so small that there is no smearing

	if(dialog)
		Open/D refnum as fullpath+".dsm"		//won't actually open the file
		If(cmpstr(S_filename,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		fullpath = S_filename
	Endif

	//write out partial set?
	Duplicate/O Q_dsm,tq,ti,te
	ti=I_dsm
	te=S_dsm
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=Q_dsm[p+lo]
		ti=I_dsm[p+lo]
		te=S_dsm[p+lo]
	endif

	//tailor the output given the type of data written out...
	String samStr="",dateStr="",str1,str2

	NVAR m = $(USANSFolder+":DSM:gPowerM")				// power law exponent
	NVAR chiFinal = $(USANSFolder+":DSM:gChi2Final")		//chi^2 final
	NVAR iter = $(USANSFolder+":DSM:gIterations")		//total number of iterations

	//get the number of spline passes from the wave note
	String noteStr
	Variable boxPass,SplinePass
	noteStr=note(I_dsm)
	BoxPass = NumberByKey("BOX", noteStr, "=", ";")
	splinePass = NumberByKey("SPLINE", noteStr, "=", ";")

	samStr = fullpath
	dateStr="CREATED: "+date()+" at  "+time()
	sprintf str1,"Chi^2 = %g   PowerLaw m = %4.2f   Iterations = %d",chiFinal,m,iter
	sprintf str2,"%d box smooth passes and %d smoothing spline passes",boxPass,splinePass


	//actually open the file
	Open refNum as fullpath

	fprintf refnum,"%s"+termStr,samStr
	fprintf refnum,"%s"+termStr,str1
	fprintf refnum,"%s"+termStr,str2
	fprintf refnum,"%s"+termStr,dateStr

	wfprintf refnum, formatStr, tq,ti,te,res1,res2,res3

	Close refnum

	Killwaves/Z ti,tq,te,res1,res2,res3

	Return(0)
End


// since this data is only smoothed, repeat the three fake resolution columns with the
// negative value for the dQv value
//
// SRK 29 JUL 2019
//
Function WriteUSANS_Smoothed(fullpath,lo,hi,dialog)
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	String termStr="\r\n"
	String destStr = USANSFolder+":DSM:"
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr

	Variable refNum,integer,realval
	NVAR gDQV = root:Packages:NIST:USANS:DSM:gDqv

	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE Q_smth =$(destStr + "Q_smth")
	WAVE I_smth=$(destStr + "I_smth")
	WAVE S_smth=$(destStr + "S_smth")

	//check each wave
	If(!(WaveExists(Q_smth)))
		Abort "Q_smth DNExist in WriteUSANS_Smoothed()"
	Endif
	If(!(WaveExists(I_smth)))
		Abort "I_smth DNExist in WriteUSANS_Smoothed()"
	Endif
	If(!(WaveExists(S_smth)))
		Abort "S_smth DNExist in WriteUSANS_Smoothed()"
	Endif

	// 06 FEB 06 SRK
	// make dummy waves to hold the "fake" resolution, and write it as the last 3 columns
	//
	Duplicate/O Q_smth,res1,res2,res3
	res1 = -gDQV
	res2 = -gDQV
	res3 = -gDQV

	if(dialog)
		Open/D refnum as fullpath+".smth"		//won't actually open the file
		If(cmpstr(S_filename,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		fullpath = S_filename
	Endif

	//write out partial set?
	Duplicate/O Q_smth,tq,ti,te
	ti=I_smth
	te=S_smth
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=Q_smth[p+lo]
		ti=I_smth[p+lo]
		te=S_smth[p+lo]
	endif

	//tailor the output given the type of data written out...
	String samStr="",dateStr="",str1,str2

	//get the number of spline passes from the wave note
	String noteStr
	Variable boxPass,SplinePass
	noteStr=note(I_smth)
	BoxPass = NumberByKey("BOX", noteStr, "=", ";")
	splinePass = NumberByKey("SPLINE", noteStr, "=", ";")


	samStr = fullpath
	dateStr="CREATED: "+date()+" at  "+time()
//	sprintf str1,"Chi^2 = %g   PowerLaw m = %4.2f   Iterations = %d",chiFinal,m,iter
	str1 = "smoothed data file, not desmeared"
	sprintf str2,"%d box smooth passes and %d smoothing spline passes",boxPass,splinePass


	//actually open the file
	Open refNum as fullpath

	fprintf refnum,"%s"+termStr,samStr
//	fprintf refnum,"%s"+termStr,str1
	fprintf refnum,"%s"+termStr,str2
	fprintf refnum,"%s"+termStr,dateStr

	wfprintf refnum, formatStr, tq,ti,te,res1,res2,res3

	Close refnum

	Killwaves/Z ti,tq,te,res1,res2,res3

	Return(0)
End


/// procedures to do the extrapolation to high Q
// very similar to the procedures in the Invariant package
//
//create the wave to extrapolate
// w is the input q-values
Function DSM_SetExtrWaves(w)
	Wave w

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Variable num_extr=25

	SetDataFolder $(USANSFolder+":DSM")

	Make/O/D/N=(num_extr) extr_hqq,extr_hqi
	extr_hqi=1		//default values

	//set the q-range
	Variable qmax,num
//	qmax=0.03

	num=numpnts(w)
	qmax=6*w[num-1]

	extr_hqq = w[num-1] + x * (qmax-w[num-1])/num_extr

	SetDataFolder root:
	return(0)
End

//creates I_ext,Q_ext,S_ext with extended q-values
//
// if num_extr == 0 , the input waves are returned as _ext
//
// !! uses simple linear extrapolation at low Q - just need something
// reasonable in the waves to keep from getting smoothing artifacts
// - uses power law at high q
Function ExtendToSmooth(qw,iw,sw,nbeg,nend,num_extr)
	Wave qw,iw,sw
	Variable nbeg,nend,num_extr

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Variable/G V_FitMaxIters=300
	Variable/G V_fitOptions=4		//suppress the iteration window
	Variable num_new,qmax,num,qmin
	num=numpnts(qw)

	num_new = num + 2*num_extr

//	Print "num,num_new",num,num_new

	SetDataFolder $(USANSFolder+":DSM")
	Make/O/D/N=(num_new) Q_ext,I_ext,S_ext

	if(num_extr == 0)		//the extended waves are the input, get out
		Q_ext = qw
		I_ext = iw
		S_ext = sw
		setDatafolder root:
		return (0)
	endif

	//make the extensions
	Make/O/D/N=(num_extr) hqq,hqi,lqq,lqi
	hqi=1		//default values
	lqi=0
	//set the q-range based on the high/low values of the data set
//	qmin=1e-6
	qmin= qw[0]*0.5
	qmax = qw[num-1]*2

	hqq = qw[num-1] + x * (qmax-qw[num-1])/num_extr
	lqq = qmin + x * (qw[0]-qmin)/num_extr

	//do the fits
	Duplicate/O iw dummy			//use this as the destination to suppress fit_ from being appended

	//Use simple linear fits	line: y = K0+K1*x
	CurveFit/Q line iw[0,(nbeg-1)] /X=qw /W=sw /D=dummy
	Wave W_coef=W_coef
	lqi=W_coef[0]+W_coef[1]*lqq
//
// Guinier or Power-law fits
//
//	Make/O/D G_coef={100,-100}		//input
//	FuncFit DSM_Guinier_Fit G_coef iw[0,(nbeg-1)] /X=qw /W=sw /D
//	lqi= DSM_Guinier_Fit(G_coef,lqq)

//	Printf "I(q=0) = %g (1/cm)\r",G_coef[0]
//	Printf "Rg = %g (A)\r",sqrt(-3*G_coef[1])

	Make/O/D P_coef={0,1,-4}			//input  --- (set background to zero and hold fixed)
	CurveFit/Q/N/H="100" Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /D=dummy
	hqi=P_coef[0]+P_coef[1]*hqq^P_coef[2]

//	Printf "Power law exponent = %g\r",P_coef[2]
//	Printf "Pre-exponential = %g\r",P_coef[1]

	// concatenate the extensions
	Q_ext[0,(num_extr-1)] = lqq[p]
	Q_ext[num_extr,(num_extr+num-1)] = qw[p-num_extr]
	Q_ext[(num_extr+num),(2*num_extr+num-1)] = hqq[p-num_extr-num]
	I_ext[0,(num_extr-1)] = lqi[p]
	I_ext[num_extr,(num_extr+num-1)] = iw[p-num_extr]
	I_ext[(num_extr+num),(2*num_extr+num-1)] = hqi[p-num_extr-num]
	S_ext[0,(num_extr-1)] = sw[0]
	S_ext[num_extr,(num_extr+num-1)] = sw[p-num_extr]
	S_ext[(num_extr+num),(2*num_extr+num-1)] = sw[num-1]

	killwaves/z dummy
	SetDataFolder root:
	return(0)
End

// pass in the (smeared) experimental data and find the power-law extrapolation
// 10 points is usually good enough, unless the data is crummy
// returns the prediction for the exponent
//
Function DSM_DoExtrapolate(qw,iw,sw,nend)
	Wave qw,iw,sw
	Variable nend

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Setdatafolder $(USANSFolder+":DSM")

//	Wave extr_lqi=extr_lqi
//	Wave extr_lqq=extr_lqq
	Wave extr_hqi=extr_hqi
	Wave extr_hqq=extr_hqq
	Variable/G V_FitMaxIters=300
	Variable/G V_fitOptions=4		//suppress the iteration window
	Variable num=numpnts(iw),retVal


	/////////for the fit
	Make/O/D P_coef={0,1,-4}			//input
	Make/O/T Constr={"K2<0","K2 > -8"}
	//(set background to zero and hold fixed)

	// initial guess
	P_coef[1] = iw[num-1]/qw[num-1]^P_coef[2]

	CurveFit/H="100" Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /I=1 /C=constr
	extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]

	// for the case of data with a background
//	Make/O/D P_coef={0,1,-4}			//input
//	//(set background to iw[num-1], let it be a free parameter
//	P_coef[0] = iw[num-1]
//	CurveFit Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /D
//	extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]

//	if(checked && if(not already displayed))
//		AppendToGraph extr_hqi vs extr_hqq
//		ModifyGraph lsize(extr_hqi)=2
//	endif


	Printf "Smeared Power law exponent = %g\r",P_coef[2]
	Printf "**** For Desmearing, use a Power law exponent of %5.1f\r",P_coef[2]-1

	retVal = P_coef[2]-1
	SetDataFolder root:
	return(retVal)
End

Function DSM_Guinier_Fit(w,x) //: FitFunc
	Wave w
	Variable x

	//fit data to I(q) = A*exp(B*q^2)
	// (B will be negative)
	//two parameters
	Variable a,b,ans
	a=w[0]
	b=w[1]
	ans = a*exp(b*x*x)
	return(ans)
End

Proc Desmear_Graph()
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	PauseUpdate; Silent 1		// building window...
	Display /W=(5,44,408,558) /K=1
	ModifyGraph cbRGB=(51664,44236,58982)
	DoWindow/C Desmear_Graph
	ControlBar 160
	// break into tabs
	TabControl DSM_Tab,pos={5,3},size={392,128},proc=DSM_TabProc
	TabControl DSM_Tab,labelBack=(49151,49152,65535),tabLabel(0)="Load"
	TabControl DSM_Tab,tabLabel(1)="Mask",tabLabel(2)="Extrapolate"
	TabControl DSM_Tab,tabLabel(3)="Smooth",tabLabel(4)="Desmear",value= 0

	//always visible - revert and save
	//maybe the wrong place here?
	Button DSMControlA,pos={225,135},size={80,20},proc=DSM_RevertButtonProc,title="Revert"
	Button DSMControlA,help={"Revert the smeared data to its original state and start over"}
	Button DSMControlB,pos={325,135},size={50,20},proc=DSM_SaveButtonProc,title="Save"
	Button DSMControlB,help={"Save the desmeared data set"}
	Button DSMControlC,pos={25,135},size={50,20},proc=DSM_HelpButtonProc,title="Help"
	Button DSMControlC,help={"Show the help file for desmearing"}

	// add the controls to each tab ---- all names start with "DSMControl_"

	//tab(0) Load - initially visible
	Button DSMControl_0a,pos={23,39},size={80,20},proc=DSM_LoadButtonProc,title="Load Data"
	Button DSMControl_0a,help={"Load slit-smeared USANS data = \".cor\" files"}
	CheckBox DSMControl_0b,pos={26,74},size={80,14},proc=DSM_LoadCheckProc,title="Log Axes?"
	CheckBox DSMControl_0b,help={"Toggle Log/Lin Q display"},value= 1
	TitleBox DSMControl_0c,pos={120,37},size={104,19},font="Courier",fSize=10
	TitleBox DSMControl_0c,variable= $(USANSFolder+":DSM:gStr1")
	//second message string not used currently
//	TitleBox DSMControl_0d,pos={120,57},size={104,19},font="Courier",fSize=10
//	TitleBox DSMControl_0d,variable= root:DSM:gStr2

	//tab(1) Mask
	Button DSMControl_1a,pos={20,35},size={90,20},proc=DSM_MyMaskProc,title="Mask Point"		//bMask
	Button DSMControl_1a,help={"Toggles the masking of the selected data point"}
	Button DSMControl_1a,disable=1
	Button DSMControl_1b,pos={20,65},size={140,20},proc=DSM_MaskGTCursor,title="Mask Q >= Cursor"		//bMask
	Button DSMControl_1b,help={"Toggles the masking of all q-values GREATER than the current cursor location"}
	Button DSMControl_1b,disable=1
	Button DSMControl_1c,pos={20,95},size={140,20},proc=DSM_MaskLTCursor,title="Mask Q <= Cursor"		//bMask
	Button DSMControl_1c,help={"Toggles the masking of all q-values LESS than the current cursor location"}
	Button DSMControl_1c,disable=1
	Button DSMControl_1d,pos={180,35},size={90,20},proc=DSM_ClearMaskProc,title="Clear Mask"		//bMask
	Button DSMControl_1d,help={"Clears all mask points"}
	Button DSMControl_1d,disable=1
//	Button DSMControl_1b,pos={144,66},size={110,20},proc=DSM_MaskDoneButton,title="Done Masking"
//	Button DSMControl_1b,disable=1

	//tab(2) Extrapolate
	Button DSMControl_2a,pos={31,42},size={90,20},proc=DSM_ExtrapolateButtonProc,title="Extrapolate"
	Button DSMControl_2a,help={"Extrapolate the high-q region with a power-law"}
	Button DSMControl_2a,disable=1
	SetVariable DSMControl_2b,pos={31,70},size={100,15},title="# of points"
	SetVariable DSMControl_2b,help={"Set the number of points for the power-law extrapolation"}
	SetVariable DSMControl_2b,limits={5,100,1},value=  $(USANSFolder+":DSM:gNptsExtrap")
	SetVariable DSMControl_2b,disable=1
	CheckBox DSMControl_2c,pos={157,45},size={105,14},proc=DSM_ExtrapolationCheckProc,title="Show Extrapolation"
	CheckBox DSMControl_2c,help={"Show or hide the high q extrapolation"},value= 1
	CheckBox DSMControl_2c,disable=1
	SetVariable DSMControl_2d,pos={31,96},size={150,15},title="Power Law Exponent"
	SetVariable DSMControl_2d,help={"Power Law exponent from the fit = the DESMEARED slope - override as needed"}
	SetVariable DSMControl_2d format="%5.2f"
	SetVariable DSMControl_2d,limits={-inf,inf,0},value= $(USANSFolder+":DSM:gPowerM")
	SetVariable DSMControl_2d,disable=1

	//tab(3) Smooth
	Button DSMControl_3a,pos={34,97},size={70,20},proc=DSM_SmoothButtonProc,title="Smooth"
	Button DSMControl_3a,disable=1
		//BoxCheck
	CheckBox DSMControl_3b,pos={34,39},size={35,14},title="Box",value= 1
	CheckBox DSMControl_3b,help={"Use a single pass of 3-point box smoothing"}
	CheckBox DSMControl_3b,disable=1
		//SSCheck
	CheckBox DSMControl_3c,pos={34,60},size={45,14},title="Spline",value= 0
	CheckBox DSMControl_3c,help={"Use a single pass of a smoothing spline"}
	CheckBox DSMControl_3c,disable=1
		//extendCheck
	CheckBox DSMControl_3d,pos={268,60},size={71,14},title="Extend Data"
	CheckBox DSMControl_3d,help={"extends the data at both low q and high q to avoid end effects in smoothing"}
	CheckBox DSMControl_3d,value= 0
	CheckBox DSMControl_3d,disable=1
	Button DSMControl_3e,pos={125,97},size={90,20},proc=DSM_SmoothUndoButtonProc,title="Start Over"
	Button DSMControl_3e,help={"Start the smoothing over again without needing to re-mask the data set"}
	Button DSMControl_3e,disable=1
	SetVariable DSMControl_3f,pos={94,60},size={150,15},title="Smoothing factor"
	SetVariable DSMControl_3f,help={"Smoothing factor for the smoothing spline"}
	SetVariable DSMControl_3f format="%5.4f"
	SetVariable DSMControl_3f,limits={0.01,2,0.01},value= $(USANSFolder+":DSM:gSmoothFac")
	SetVariable DSMControl_3f,disable=1
	CheckBox DSMControl_3g,pos={268,39},size={90,14},title="Log-scale smoothing?"
	CheckBox DSMControl_3g,help={"Use log-scaled intensity during smoothing (reverts to linear if negative intensity points found)"}
	CheckBox DSMControl_3g,value=0
	CheckBox DSMControl_3g,disable=1
	ValDisplay DSMControl_3h pos={235,97},title="Chi^2",size={80,20},value=root:Packages:NIST:USANS:DSM:gChi2Smooth
	ValDisplay DSMControl_3h,help={"This is the Chi^2 value for the smoothed data vs experimental data"}
	ValDisplay DSMControl_3h,disable=1

	//tab(4) Desmear
	Button DSMControl_4a,pos={35,93},size={80,20},proc=DSM_DesmearButtonProc,title="Desmear"
	Button DSMControl_4a,help={"Do the desmearing - the result is in I_dsm"}
	Button DSMControl_4a,disable=1
	SetVariable DSMControl_4b,pos={35,63},size={120,15},title="Chi^2 target"
	SetVariable DSMControl_4b,help={"Set the targetchi^2 for convergence (recommend chi^2=1)"}
	SetVariable DSMControl_4b,limits={0,inf,0.1},value= $(USANSFolder+":DSM:gChi2Target")
	SetVariable DSMControl_4b,disable=1
	SetVariable DSMControl_4c,pos={35,35},size={80,15},title="dQv"
	SetVariable DSMControl_4c,help={"Slit height as read in from the data file. 0.117 is the NIST value, override if necessary"}
	SetVariable DSMControl_4c,limits={-inf,inf,0},value= $(USANSFolder+":DSM:gDqv")
	SetVariable DSMControl_4c,disable=1
	TitleBox DSMControl_4d,pos={160,37},size={104,19},font="Courier",fSize=10
	TitleBox DSMControl_4d,variable= $(USANSFolder+":DSM:gIterStr")
	TitleBox DSMControl_4d,disable=1


	SetDataFolder root:
EndMacro

// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will
// appear in odd places...
// all buttons are named DSMControl_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly :-)
//
Function DSM_TabProc(ctrlName,tab) //: TabControl
	String ctrlName
	Variable tab

	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"DSMControl_"		//11 characters
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,10]
		if(cmpstr(nameStr,"DSMControl_")==0)
			onTab = str2num(item[11])			//12th is a number
			ControlInfo $item
			switch(abs(V_flag))
				case 1:
					Button $item,disable=(tab!=onTab)
					break
				case 2:
					CheckBox $item,disable=(tab!=onTab)
					break
				case 5:
					SetVariable $item,disable=(tab!=onTab)
					break
				case 10:
					TitleBox $item,disable=(tab!=onTab)
					break
				case 4:
					ValDisplay $item,disable=(tab!=onTab)
					break
				// add more items to the switch if different control types are used
			endswitch

		endif
	endfor

	if(tab==1)
		DSM_MyMaskProc("")		//start maksing if you click on the tab
	else
		DSM_MaskDoneButton("")		//masking is done if you click off the tab
	endif

	if(tab == 2)
		//calculate the extrapolation when the tab is selected - this re-fits the data, what we want to avoid
//		DSM_ExtrapolateButtonProc("")

		// OR
		// use the coefficients from when it was loaded
		SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
		WAVE P_coef = $(USANSFolder+":DSM:P_coef")
		wave Qw = $(USANSFolder+":DSM:Q_exp")

		DSM_SetExtrWaves(Qw)
		Wave extr_hqi=$(USANSFolder+":DSM:extr_hqi")
		Wave extr_hqq=$(USANSFolder+":DSM:extr_hqq")
		extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]

		AppendExtrapolation()

	endif

	return 0
End

Proc AppendSmeared()
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM")
//	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_exp_orig",0,2) == -1)		//Igor 5
	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_exp_orig",0) == -1)
		AppendToGraph/W=Desmear_Graph  I_exp_orig vs Q_exp_orig
		ModifyGraph mode=4,marker=19		//3 is markers, 4 is markers and lines
		ModifyGraph rgb(I_exp_orig)=(0,0,0)
		ModifyGraph msize=2,grid=1,log=1,mirror=2,standoff=0,tickunit=1
		ErrorBars/T=0 I_exp_orig Y,wave=(S_exp_orig,S_exp_orig)
		Legend/N=text0/J "\\F'Courier'\\s(I_exp_orig) I_exp_orig"
		Label left "Intensity"
		Label bottom "Q (1/A)"
	endif
	//always update the textbox - kill the old one first
	TextBox/K/N=text1
//	TextBox/C/N=text1/F=0/A=MT/E=2/X=5.50/Y=0.00 root:DSM:gCurFile			//Igor 5
	TextBox/C/N=text1/F=0/A=MT/E=1/X=5.50/Y=0.00 $(USANSFolder+":DSM:gCurFile")
End

Proc AppendMask()
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

//	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"MaskData",0,2) == -1)			//Igor 5
	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"MaskData",0) == -1)
		SetDataFolder $(USANSFolder+":DSM:")
		AppendToGraph/W=Desmear_Graph MaskData vs Q_exp_orig
		ModifyGraph mode(MaskData)=3,marker(MaskData)=8,msize(MaskData)=2.5,opaque(MaskData)=1
		ModifyGraph rgb(MaskData)=(65535,16385,16385)
		setdatafolder root:
	endif
end

Proc AppendSmoothed()
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

//	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_smth",0,2) == -1)			//Igor 5
	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_smth",0) == -1)
		SetDataFolder $(USANSFolder+":DSM:")
		AppendToGraph/W=Desmear_Graph I_smth vs Q_smth
		ModifyGraph/W=Desmear_Graph rgb(I_smth)=(3,52428,1),lsize(I_smth)=2
		setdatafolder root:
	endif
end

Function RemoveSmoothed()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM:")
	RemoveFromGraph/W=Desmear_Graph/Z I_smth
	setdatafolder root:
end

Function RemoveMask()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM:")
	RemoveFromGraph/W=Desmear_Graph/Z MaskData
	setdatafolder root:
end

Proc AppendDesmeared()
	String USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

//	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_dsm",0,2) == -1)		//Igor 5
	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"I_dsm",0) == -1)
		SetDataFolder $(USANSFolder+":DSM:")
		AppendToGraph/W=Desmear_Graph I_dsm vs Q_dsm
		ModifyGraph mode(I_dsm)=3,marker(I_dsm)=19
		ModifyGraph rgb(I_dsm)=(1,16019,65535),msize(I_dsm)=2
		ErrorBars/T=0 I_dsm Y,wave=(S_dsm,S_dsm)
		setdatafolder root:
	endif
end

Function RemoveDesmeared()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM:")
	RemoveFromGraph/W=Desmear_Graph/Z I_dsm
	setdatafolder root:
end

Function AppendExtrapolation()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

// 	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"extr_hqi",0,2) == -1)		//Igor 5
	if( strsearch(TraceNameList("Desmear_Graph", "", 1),"extr_hqi",0) == -1)
		SetDataFolder $(USANSFolder+":DSM:")
		
		WAVE extr_hqi = extr_hqi
		WAVE extr_hqq = extr_hqq
		
		AppendToGraph/W=Desmear_Graph extr_hqi vs extr_hqq
		ModifyGraph/W=Desmear_Graph lSize(extr_hqi)=2
		setdatafolder root:
	endif
end

Function RemoveExtrapolation()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM:")
	RemoveFromGraph/W=Desmear_Graph/Z extr_hqi
	setdatafolder root:
end

// step (1) - read in the data, and plot it
// clear out all of the "old" waves, remove them from the graph first
// reads in a fresh copy of the data
//
// produces Q_exp, I_exp, S_exp waves (and originals "_orig")
// add a dummy wave note that can be changed on later steps
//
Function DSM_LoadButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	String qStr,iStr,sStr,sqStr
	Variable nq,dqv,numBad,val

	// remove any of the old traces on the graph and delete the waves
	CleanUpJunk()

	SetDataFolder root:
	Execute "A_LoadOneDDataWithName(\"\",0)"
	SVAR fileStr = root:Packages:NIST:gLastFileName
	if (cmpstr(fileStr,"") == 0)
		return(0)		//get out if no file selected
	endif
	//define the waves that the smoothing will be looking for...
	SVAR fname = $("root:Packages:NIST:gLastFileName")		//this changes as any data is loaded
	SVAR curFile = $(USANSFolder+":DSM:gCurFile")					//keep this for title, save
	curFile = fname

	qStr = CleanupName((fName + "_q"),0)		//the q-wave
	iStr = CleanupName((fName + "_i"),0)		//the i-wave
	sStr = CleanupName((fName + "_s"),0)		//the s-wave
	sqStr = CleanupName((fName + "sq"),0)		//the sq-wave, which should have -dQv as the elements

	String DFStr= CleanupName(fname,0)

	Duplicate/O $("root:"+DFStr+":"+qStr) $(USANSFolder+":DSM:Q_exp")
	Duplicate/O $("root:"+DFStr+":"+iStr) $(USANSFolder+":DSM:I_exp")
	Duplicate/O $("root:"+DFStr+":"+sStr) $(USANSFolder+":DSM:S_exp")
	wave Q_exp = $(USANSFolder+":DSM:Q_exp")
	Wave I_exp = $(USANSFolder+":DSM:I_exp")
	Wave S_exp = $(USANSFolder+":DSM:S_exp")

	// copy over the high q extrapolation information
	Duplicate/O $("root:"+DFStr+":P_coef") $(USANSFolder+":DSM:P_coef")
	NVAR slope = $("root:"+DFStr+":USANS_m")
	NVAR powerM = $(USANSFolder+":DSM:gPowerM")
	powerM = slope

	// remove any negative q-values (and q=0 values!)(and report this)
	// ? and trim the low q to be >= 3.0e-5 (1/A), below this USANS is not reliable.
	NumBad = RemoveBadQPoints(Q_exp,I_exp,S_exp,0)
	SVAR str1 = $(USANSFolder+":DSM:gStr1")
	sprintf str1,"%d negative q-values were removed",numBad

// don't trim off any positive q-values
//	val = 3e-5		//lowest "good" q-value from USANS
//	NumBad = RemoveBadQPoints(Q_exp,I_exp,S_exp,val-1e-8)
//	SVAR str2 = root:DSM:gStr2
//	sprintf str2,"%d q-values below q = %g were removed",numBad,val

	Duplicate/O $(USANSFolder+":DSM:Q_exp") $(USANSFolder+":DSM:Q_exp_orig")
	Duplicate/O $(USANSFolder+":DSM:I_exp") $(USANSFolder+":DSM:I_exp_orig")
	Duplicate/O $(USANSFolder+":DSM:S_exp") $(USANSFolder+":DSM:S_exp_orig")
	wave I_exp_orig = $(USANSFolder+":DSM:I_exp_orig")

	nq = numpnts($(USANSFolder+":DSM:Q_exp"))

	dQv = NumVarOrDefault("root:"+DFStr+":USANS_dQv", 0.117 )
//	if(WaveExists(sigQ))			//try to read dQv
////		dqv = -sigQ[0][0]
////		DoAlert 0,"Found dQv value of " + num2str(dqv)
//	else
//		dqv = 0.117
//	//	dqv = 0.037		//old value
//		DoAlert 0,"Could not find dQv in the data file - using " + num2str(dqv)
//	endif
	NVAR gDqv = $(USANSFolder+":DSM:gDqv")				//needs to be global for Weights_L()
	NVAR gNq = $(USANSFolder+":DSM:gNq")
	//reset the globals
	gDqv = dqv
	gNq = nq

	// append the (blank) wave note to the intensity wave
	Note I_exp,"BOX=0;SPLINE=0;"
	Note I_exp_orig,"BOX=0;SPLINE=0;"

	//draw the graph
	Execute "AppendSmeared()"

	SetDataFolder root:
End

// remove any q-values <= val
Function RemoveBadQPoints(qw,iw,sw,val)
	Wave qw,iw,sw
	Variable val

	Variable ii,num,numBad,qval
	num = numpnts(qw)

	ii=0
	numBad=0
	do
		qval = qw[ii]
		if(qval <= val)
			numBad += 1
		else		//keep the points
			qw[ii-numBad] = qval
			iw[ii-numBad] = iw[ii]
			sw[ii-numBad] = sw[ii]
		endif
		ii += 1
	while(ii<num)
	//trim the end of the waves
	DeletePoints num-numBad, numBad, qw,iw,sw
	return(numBad)
end

// if mw = Nan, keep the point, if a numerical value, delete it
Function RemoveMaskedPoints(mw,qw,iw,sw)
	Wave mw,qw,iw,sw

	Variable ii,num,numBad,mask
	num = numpnts(qw)

	ii=0
	numBad=0
	do
		mask = mw[ii]
		if(numtype(mask) != 2)		//if not NaN
			numBad += 1
		else		//keep the points that are NaN
			qw[ii-numBad] = qw[ii]
			iw[ii-numBad] = iw[ii]
			sw[ii-numBad] = sw[ii]
		endif
		ii += 1
	while(ii<num)
	//trim the end of the waves
	DeletePoints num-numBad, numBad, qw,iw,sw
	return(numBad)
end

// produces the _msk waves that have the new number of data points
//
Function DSM_MaskDoneButton(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

//	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	Variable aExists= strlen(CsrWave(A)) > 0			//Igor 4
	if(!aExists)
		return(1)		//possibly reverted data, no cursor, no Mask wave
	endif

	Duplicate/O $(USANSFolder+":DSM:Q_exp_orig"),$(USANSFolder+":DSM:Q_msk")
	Duplicate/O $(USANSFolder+":DSM:I_exp_orig"),$(USANSFolder+":DSM:I_msk")
	Duplicate/O $(USANSFolder+":DSM:S_exp_orig"),$(USANSFolder+":DSM:S_msk")
	Wave Q_msk=$(USANSFolder+":DSM:Q_msk")
	Wave I_msk=$(USANSFolder+":DSM:I_msk")
	Wave S_msk=$(USANSFolder+":DSM:S_msk")

	//finish up - trim the data sets and reassign the working set
	Wave MaskData=$(USANSFolder+":DSM:MaskData")

	RemoveMaskedPoints(MaskData,Q_msk,I_msk,S_msk)

	//reset the number of points
	NVAR gNq = $(USANSFolder+":DSM:gNq")
	gNq = numpnts(Q_msk)

	Cursor/K A
	HideInfo

	return(0)
End


// not quite the same as revert
Function DSM_ClearMaskProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave MaskData=$(USANSFolder+":DSM:MaskData")
	MaskData = NaN

	return(0)
end

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function DSM_MyMaskProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Wave data=$(USANSFolder+":DSM:I_exp_orig")

//	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	Variable aExists= strlen(CsrWave(A)) > 0			//Igor 4

// need to get rid of old smoothed data if data is re-masked
	Execute "RemoveSmoothed()"
	SetDataFolder $(USANSFolder+":DSM")
	Killwaves/Z I_smth,Q_smth,S_smth

	WAVE I_exp_orig = I_exp_orig
	WAVE Q_exp_orig = Q_exp_orig
	
	if(aExists)		//mask the selected point
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[pcsr(A)] = (numType(MaskData[pcsr(A)])==0) ? NaN : data[pcsr(A)]		//if NaN, doesn't plot
	else
		Cursor /A=1/H=1/L=1/P/W=Desmear_Graph A I_exp_orig leftx(I_exp_orig)
		ShowInfo
		//if the mask wave does not exist, make one
		if(exists("MaskData") != 1)
			Duplicate/O Q_exp_orig MaskData
			MaskData = NaN		//use all data
		endif
		Execute "AppendMask()"
	endif

	SetDataFolder root:

	return(0)
End

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function DSM_MaskLTCursor(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

//	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	Variable aExists= strlen(CsrWave(A)) > 0			//Igor 4

	if(!aExists)
		return(1)
	endif
// need to get rid of old smoothed data if data is re-masked
	Execute "RemoveSmoothed()"
	SetDataFolder $(USANSFolder+":DSM")
	Killwaves/Z I_smth,Q_smth,S_smth

	Wave data=I_exp_orig

	Variable pt,ii
	pt = pcsr(A)
	for(ii=pt;ii>=0;ii-=1)
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[ii] = (numType(MaskData[ii])==0) ? NaN : data[ii]		//if NaN, doesn't plot
	endfor

	SetDataFolder root:
	return(0)
End

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function DSM_MaskGTCursor(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder


//	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	Variable aExists= strlen(CsrWave(A)) > 0			//Igor 4

	if(!aExists)
		return(1)
	endif
// need to get rid of old smoothed data if data is re-masked
	Execute "RemoveSmoothed()"
	SetDataFolder $(USANSFolder+":DSM")
	Killwaves/Z I_smth,Q_smth,S_smth

	Wave data=I_exp_orig
	WAVE MaskData = MaskData

	Variable pt,ii,endPt
	endPt=numpnts(MaskData)
	pt = pcsr(A)
	for(ii=pt;ii<endPt;ii+=1)
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[ii] = (numType(MaskData[ii])==0) ? NaN : data[ii]		//if NaN, doesn't plot
	endfor

	SetDataFolder root:

	return(0)
End

Function CleanUpJunk()
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	// clean up the old junk on the graph, /Z for no error
	Execute "RemoveExtrapolation()"
	Execute "RemoveDesmeared()"
	Execute "RemoveSmoothed()"
	Execute "RemoveMask()"

	//remove the cursor
	Cursor/K A

	//always initialize these
	String/G $(USANSFolder+":DSM:gStr1") = ""
	String/G $(USANSFolder+":DSM:gStr2") = ""
	String/G $(USANSFolder+":DSM:gIterStr") = ""

	// clean up the old waves from smoothing and desmearing steps
	SetDataFolder $(USANSFolder+":DSM")
	Killwaves/Z I_smth,I_dsm,I_dsm_sm,Q_smth,Q_dsm,S_smth,S_dsm,Yi_SS,Yq_SS
	Killwaves/Z Weights,FW,R_wave,S_wave,H_wave,Di,Ci
	Killwaves/Z Is_old,I_old,err
	Killwaves/Z Q_ext,I_ext,S_ext,hqq,hqi,lqq,lqi
	Killwaves/Z MaskData,Q_msk,I_msk,S_msk
	Killwaves/Z Q_work,I_work,S_work				//working waves for desmearing step
	SetDataFolder root:
End

// does not alter the data sets - reports a power law
// exponent and makes it global so it will automatically
// be used during the desmearing
//
// generates extr_hqi vs extr_hqq that are Appended to the graph
Function DSM_ExtrapolateButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	NVAR nend = $(USANSFolder+":DSM:gNptsExtrap")
	NVAR m_pred = $(USANSFolder+":DSM:gPowerM")

	SetDataFolder $(USANSFolder+":DSM")
//use masked data if it exists
	if(exists("I_msk")==1 && exists("Q_msk")==1 && exists("S_msk")==1)
		wave Qw = $(USANSFolder+":DSM:Q_msk")
		Wave Iw = $(USANSFolder+":DSM:I_msk")
		Wave Sw = $(USANSFolder+":DSM:S_msk")
	else
		//start from the "_exp" waves
		if(exists("I_exp")==1 && exists("Q_exp")==1 && exists("S_exp")==1)
			wave Qw = $(USANSFolder+":DSM:Q_exp")
			Wave Iw = $(USANSFolder+":DSM:I_exp")
			Wave Sw = $(USANSFolder+":DSM:S_exp")
		endif
	endif
	SetDataFolder root:

	DSM_SetExtrWaves(Qw)
	m_pred = DSM_DoExtrapolate(Qw,Iw,Sw,nend)
	AppendExtrapolation()

	return(0)
End

//smooths the data in steps as requested...
//
// typically do a simple Box smooth first,
// then do a smoothing spline, keeping the same number of data points
//
// chi-squared is reported - so you can see how "bad" the smoothing is
// smoothing of the data is done on a log(I) scale if requested
// setting doLog variable to 0 will return to linear smoothing
// (I see little difference)
//
// start from the "_smth" waves if they exist
// otheriwse start from the working waves
//
// create Q_smth, I_smth, S_smth
// keep track of the smoothing types and passes in the wave note
//
Function DSM_SmoothButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM")

	Variable ii,new_n,pass,nq_ext,offset,doLog=1
	String noteStr=""

	// want log scaling of intensity during smoothing?
	ControlInfo DSMControl_3g
	doLog = V_value

////	if(exists("I_smth")==1 && exists("Q_smth")==1 && exists("S_smth")==1 && ! freshMask)
	if(exists("I_smth")==1 && exists("Q_smth")==1 && exists("S_smth")==1)
		//start from the smoothed waves --- just need the wave references
	else
		//start from the "msk", creating smth waves
		if(exists("I_msk")==1 && exists("Q_msk")==1 && exists("S_msk")==1)
			wave Q_msk,I_msk,S_msk
			Duplicate/O I_msk,I_smth,Q_smth,S_smth
			I_smth = I_msk
			Q_smth = Q_msk
			S_smth = S_msk
		else
			//start from the "_exp" waves
			if(exists("I_exp")==1 && exists("Q_exp")==1 && exists("S_exp")==1)
				wave Q_exp,I_exp,S_exp
				Duplicate/O I_exp,I_smth,Q_smth,S_smth
				I_smth = I_exp
				Q_smth = Q_exp
				S_smth = S_exp
			endif
		endif
	endif

	wave Q_smth,I_smth,S_smth

	// extend the data to avoid end effects
	//creates I_ext,Q_ext,S_ext with extended q-values
	// fit 15 pts at each end, typically add 10 pts to each end
	// does nothing if num_extr = 0
	ControlInfo/W=Desmear_Graph DSMControl_3d		//extendCheck
	if(V_value == 1)
		ExtendToSmooth(Q_smth,I_smth,S_smth,15,15,10)
	else
		ExtendToSmooth(Q_smth,I_smth,S_smth,15,15,0)		//don't extend, just use the original data
	endif

	//whether extending or not, the working data is "_ext", set by ExtendToSmooth()
	SetDataFolder $(USANSFolder+":DSM")
	wave Q_ext,I_ext ,S_ext

	noteStr=note(I_smth)
	Note I_ext , noteStr

	WaveStats/Q I_ext
	if(V_min<=0)
		Print "negative itensity found, using linear scale for smoothing"
		doLog = 0
	endif

	if(doLog)
		//convert to log scale
		Duplicate/O I_ext I_log,I_log_err
		Wave I_log ,I_log_err
		I_log = log(I_ext)
		WaveStats/Q I_log
		offset = 2*(-V_min)
		I_log += offset
		I_log_err = S_ext/(2.30*I_ext)
		I_ext = I_log
	endif
	//

	ControlInfo/W=Desmear_Graph DSMControl_3b		//BoxCheck
	if(V_value == 1)
		//do a simple Box smooth first - number of points does not change
		// fills ends with neighboring value (E=3) (n=3 points in smoothing window)
		Smooth/E=3/B 3, I_ext

		noteStr=note(I_ext)
		pass = NumberByKey("BOX", noteStr, "=", ";")
		noteStr = ReplaceNumberByKey("BOX", noteStr, pass+1, "=", ";")
		Note/K I_ext
		Note I_ext , noteStr
//		Print "box = ",noteStr
	endif

	NVAR sParam = gSmoothFac		//already in the right DF

	ControlInfo/W=Desmear_Graph DSMControl_3c		//SSCheck
	if(V_value == 1)
		nq_ext = numpnts(Q_ext)
		Interpolate2/T=3/N=(nq_ext)/I=2/F=1/SWAV=S_ext/Y=Yi_SS/X=Yq_SS Q_ext, I_ext		//Igor 5
//		Interpolate/T=3/N=(nq)/I=2/F=1/S=S_ext/Y=Yi_SS/X=Yq_SS I_ext /X=Q_ext			//Igor 4
//	//Igor 4
//		String str=""
//		nq_ext = numpnts(Q_ext)
//		str = "Interpolate/T=3/N=("+num2str(nq_ext)+")/I=1/F=("+num2str(sParam)+")/Y=Yi_SS/X=Yq_SS I_ext /X=Q_ext"
//		Execute str
//		Print Str
	// end Igor 4
//		Interpolate2/T=3/N=(nq_ext)/I=1/F=(sParam)/Y=Yi_SS/X=Yq_SS Q_ext, I_ext

		wave yi_ss = yi_ss		// already in the right DF
		wave yq_ss = yq_ss
		// reassign the "working" waves with the result of interpolate, which has the same I/Q values
		I_ext = yi_ss
		Q_ext = yq_ss

		noteStr=note(I_ext)
		pass = NumberByKey("SPLINE", noteStr, "=", ";")
		noteStr = ReplaceNumberByKey("SPLINE", noteStr, pass+1, "=", ";")
		Note/K I_ext
		Note I_ext , noteStr
//		Print "spline = ",noteStr
	endif

	//undo the scaling
	If(doLog)
		I_ext -= offset
		I_ext = 10^I_ext
	endif

	// at this point, I_ext has too many points - and we need to just return the
	// center chunk that is the original q-values
	// as assign this to the working set for the desmear step
	// and to the _smth set in case another smoothng pass is desired
	// Q_smth has not changed, S_smth has not changed
	I_smth = interp(Q_smth[p], Q_ext, I_ext )

	Note/K I_smth
	Note I_smth , noteStr
//	Print "end of smoothed, note = ",note(I_smth)

	Variable nq = numpnts($(USANSFolder+":DSM:Q_smth"))
//	Print "nq after smoothing = ",nq

	//reset the global
	NVAR gNq = gNq
	gNq = nq
	//report the chi^2 difference between the smoothed curve and the experimental data
	NVAR chi2 = gChi2Smooth
	chi2 = SmoothedChi2(I_smth)

	Execute "AppendSmoothed()"

	setDataFolder root:
	return(0)
End

// undo the smoothing and start over - useful if you've smoothed
// too aggressively and need to back off
Function DSM_SmoothUndoButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	Execute "RemoveSmoothed()"
	SetDataFolder $(USANSFolder+":DSM")
	Killwaves/Z I_smth,Q_smth,S_smth,Q_ext,I_ext,S_ext,Yi_SS,Yq_SS
	SetDataFolder root:
	return (0)
end

//calculate the chi^2 value for the smoothed data
Function SmoothedChi2(I_smth)
	Wave I_smth

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	//start from the "msk", if they exist
	if(exists("I_msk")==1 && exists("Q_msk")==1 && exists("S_msk")==1)
		Wave iw = $(USANSFolder+":DSM:I_msk")
		Wave sw = $(USANSFolder+":DSM:S_msk")
	else
		//start from the "_exp" waves
		if(exists("I_exp")==1 && exists("Q_exp")==1 && exists("S_exp")==1)
			Wave iw = $(USANSFolder+":DSM:I_exp")
			Wave sw = $(USANSFolder+":DSM:S_exp")
		endif
	endif

	Variable ii,chi2,num
	chi2=0
	num = numpnts(iw)
	for(ii=0;ii<num;ii+=1)
		chi2 += (iw[ii] - I_smth[ii])^2 / (sw[ii])^2
	endfor
	Chi2 /= (num-1)
	return (chi2)
end

// I_dsm is the desmeared data
//
// step (7) - desmearing is done, write out the result
//
Function DSM_SaveButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR useXMLOutput = root:Packages:NIST:gXML_Write

	String saveStr
	SVAR curFile = $(USANSFolder+":DSM:gCurFile")
	saveStr = CleanupName((curFile),0)		//the output filename
	//

	ControlInfo DSM_Tab
	Variable curTab = V_Value

	switch(curTab)	// numeric switch
		case 4:	// data from the desmeared data tab
			if (useXMLOutput == 1)
				WriteXMLUSANSDesmeared(saveStr,0,0,1)
			else
				WriteUSANSDesmeared(saveStr,0,0,1)			//use the full set (lo=hi=0) and present a dialog
			endif
			break
		case 3:
				WriteUSANS_Smoothed(saveStr,0,0,1)
			break
		default:
			DoAlert 0,"Can only save data from the smooth or desmeared tabs"
	endswitch



	SetDataFolder root:
	return(0)
End

Function DSM_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "Desmearing USANS Data"
	if(V_flag !=0)
		DoAlert 0,"The Desmearing USANS Data Help file could not be found"
	endif
	return(0)
End


//toggles the log/lin display of the loaded data set
Function DSM_LoadCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	ModifyGraph log=(checked)
	return(0)
End


Function DSM_ExtrapolationCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if(checked)
		AppendExtrapolation()
	else
		RemoveExtrapolation()
	endif
	return(0)
End


// takes as input the "working waves"
//
// creates intermediate waves to work on
//
// output of Q_dsm,I_dsm,S_dsm (and I_dsm_sm, the result of smearing I_dsm)
//
Function DSM_DesmearButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder

	SetDataFolder $(USANSFolder+":DSM")
	if(exists("I_smth")==1 && exists("Q_smth")==1 && exists("S_smth")==1)
		wave Q_smth , I_smth ,S_smth
		Duplicate/O I_smth,I_work,Q_work,S_work
		I_work = I_smth
		Q_work = Q_smth
		S_work = S_smth
	else
		//start from the "msk", creating work waves
		if(exists("I_msk")==1 && exists("Q_msk")==1 && exists("S_msk")==1)
			wave Q_msk,I_msk,S_msk
			Duplicate/O I_msk,I_work,Q_work,S_work
			I_work = I_msk
			Q_work = Q_msk
			S_work = S_msk
		else
			//start from the "_exp" waves
			if(exists("I_exp")==1 && exists("Q_exp")==1 && exists("S_exp")==1)
				wave Q_exp,I_exp,S_exp
				Duplicate/O I_exp,I_work,Q_work,S_work
				I_work = I_exp
				Q_work = Q_exp
				S_work = S_exp
			endif
		endif
	endif
	//SetDataFolder root:

	NVAR nq = gNq
	NVAR m = gPowerM
	NVAR chi2_target = gChi2Target
	NVAR maxFastIter = gMaxFastIter
	NVAR maxSlowIter = gMaxSlowIter

	//	SET WEIGHTING OF EXPERIMENTAL DATA.
	Duplicate/O Q_work weights
	Wave weights = weights
	weights = 1/S_work^2

//	calculate weighting array for smearing of data
	Make/O/D/N=(nq,nq) FW
	Wave FW
	Weights_L(m,FW,Q_work)

//	^^^^   Iterative desmearing   ^^^^*
	Variable chi2_old,chi2_new,done,iter
//	FOR 0TH ITERATION, EXPERIMENTAL DATA IS USED FOR Y_OLD, create ys_old for result
//	y_old = I_old, y_new = I_dsm, I_dsm_sm = ys_new,
// duplicate preserves the wave note!
	Duplicate/O I_work I_old,Is_old,I_dsm,I_dsm_sm
	Duplicate/O Q_work Q_dsm,S_dsm		//sets Q_dsm correctly
	wave S_dsm,I_old,Is_old,I_dsm,I_dsm_sm
	I_old = I_work
	Is_old = 0
	I_dsm = 0
	I_dsm_sm = 0

//	Smear 0TH iter guess Y --> YS
	DSM_Smear(I_old,Is_old,NQ,FW)
	chi2_OLD = chi2(Is_old,I_work,weights,NQ)

	printf "starting chi^2 = %g\r",chi2_old
	Print "Starting fast convergence..... "

	done = 0		//false
	iter = 0
	Do 					// while not done, use Fast convergence
		I_dsm = I_work * I_old / Is_old	//	  Calculate corrected guess (no need for do-loop)

//	  Smear iter guess I_dsm --> I_dsm_sm and see how well I_dsm_sm matches experimental data
		DSM_Smear(I_dsm,I_dsm_sm,NQ,FW)
		chi2_new = chi2(I_dsm_sm,I_work,weights,NQ)

//	  Stop iteration if fit from new iteration has worse fit...
		If (chi2_new > chi2_old)
			Done = 1
		Endif

//	  Stop iteration if fit is better than target value...
		If (chi2_new < chi2_target)
			Done = 1
		Else
			Iter += 1
			Printf "Iteration %d, Chi^2(new) = %g\r", Iter,chi2_new
			I_old = I_dsm
			Is_old = I_dsm_sm
			if(iter>maxFastIter)
				break
			endif
			CHI2_OLD = CHI2_NEW
		EndIf
	while( !done )

	// append I_dsm,I_exp to the graph
	Execute "AppendDesmeared()"
	DoUpdate

	SetDataFolder $(USANSFolder+":DSM")


// step (6) - refine the desmearing using slow convergence
	Print "Starting slow convergence..... "
	done = 0		//  ! reset flag for slow convergence
	Do
		I_dsm = I_old + (I_work - Is_old)	//	  Calculate corrected guess

//	  Smear iter guess Y --> YS
		DSM_Smear(I_dsm,I_dsm_sm,NQ,FW)
		chi2_new = chi2(I_dsm_sm,I_work,weights,NQ)

//	  Stop iteration if fit from new iteration has worse fit...
		If (chi2_new > chi2_old)
			Done = 1
		Endif

//	  Stop iteration if fit is better than target value...
		If (chi2_new < chi2_target)
			Done = 1
		Else
			Iter += 1

			if(mod(iter, 50 ) ==0 )
				Printf "Iteration %d, Chi^2(new) = %g\r", Iter,chi2_new
				DoUpdate
			endif
			I_old = I_dsm
			Is_old = I_dsm_sm

			CHI2_OLD = CHI2_NEW
		EndIf
		if(iter>maxSlowIter)
			break
		endif
	While ( !done )

	Printf "Iteration %d, Chi^2(new) = %g\r", Iter,chi2_new

	// adjust the error
	SetDataFolder $(USANSFolder+":DSM")
	Duplicate/O S_work err
	S_dsm = abs(err/I_work*I_dsm)		//proportional error
//John simply keeps the same error as was read in from the smeared data set - is this right?
//	S_dsm = S_Work

	NVAR gChi =  gChi2Final		//chi^2 final
	NVAR gIter = gIterations		//total number of iterations
	gChi = chi2_new
	gIter = Iter

	SVAR str = gIterStr
	sprintf str,"%d iterations required",iter

	SetDataFolder root:
	return(0)
End

Function DSM_RevertButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder


	CleanUpJunk()

 	SetDataFolder $(USANSFolder+":DSM")

	//reset the working waves to the original
	wave Q_exp_orig,I_exp_orig,S_exp_orig

	Duplicate/O Q_exp_orig Q_exp
	Duplicate/O I_exp_orig I_exp
	Duplicate/O S_exp_orig S_exp
	// kill the data folder
	// re-initialize?

	SetDataFolder root:

	return(0)
End