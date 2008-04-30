#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0


////////////////////////////////////////////////////
//
//		Calculates the scattering from a binary mixture of
//		hard spheres
//
// there are some typographical errors in Ashcroft/Langreth's paper
// Physical Review, v. 156 (1967) 685-692
//
//		Errata on Phys. Rev. 166 (1968) 934.
//
//(A5) - the entire term should be multiplied by 1/2
//
//final equation for beta12 should be (1+a) rather than (1-a)
//
//
//Definitions are consistent with notation in the paper:
//
// phi is total volume fraction
// nf2 (x) is number density ratio as defined in paper
// aa = alpha as defined in paper
// r2 is the radius of the LARGER sphere (angstroms)
// Sij are the partial structure factor output arrays
//
//		S. Kline 15 JUL 2004
//		see: bhs.c and ashcroft.f
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
//	larger sphere radius(angstroms) = guess[0]
// smaller sphere radius (A) = guess[1]
//	volume fraction of larger spheres = guess[2]
//	volume fraction of small spheres = guess[3]
//	size ratio, alpha(0<a<1) = derived
//	SLD(A-2) of larger particle = guess[4]
//	SLD(A-2) of smaller particle = guess[5]
//	SLD(A-2) of the solvent = guess[6]
//background = guess[7]

Proc PlotBinaryHS(num,qmin,qmax)
	Variable num=256, qmin=.001, qmax=.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å-1) for model: " 
	Prompt qmax "Enter maximum q-value (Å-1) for model: "
//
	Make/O/D/n=(num) xwave_BinaryHS, ywave_BinaryHS
	xwave_BinaryHS =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_BinaryHS = {100,25,0.2,0.1,3.5e-6,0.5e-6,6.36e-6,0.001}			//CH#2
	make/o/t parameters_BinaryHS = {"large radius","small radius","volume fraction large spheres","volume fraction small spheres","large sphere SLD","small sphere SLD","solvent SLD","Incoherent Bgd (cm-1)"}
	Edit parameters_BinaryHS, coef_BinaryHS
	ModifyTable width(parameters_BinaryHS)=160
	ModifyTable width(coef_BinaryHS)=90
	
	Variable/G root:g_BinaryHS
	g_BinaryHS := BinaryHS(coef_BinaryHS, ywave_BinaryHS,xwave_BinaryHS)
	Display ywave_BinaryHS vs xwave_BinaryHS
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (Å\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("BinaryHS","coef_BinaryHS","BinaryHS")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedBinaryHS(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_BinaryHS = {100,25,0.2,0.1,3.5e-6,0.5e-6,6.36e-6,0.001}			//CH#4
	make/o/t smear_parameters_BinaryHS = {"large radius","small radius","volume fraction large spheres","volume fraction small spheres","large sphere SLD","small sphere SLD","solvent SLD","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_BinaryHS,smear_coef_BinaryHS					//display parameters in a table
	ModifyTable width(smear_parameters_BinaryHS)=160
	ModifyTable width(smear_coef_BinaryHS)=90
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_BinaryHS,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_BinaryHS							//
					
	Variable/G gs_BinaryHS=0
	gs_BinaryHS := fSmearedBinaryHS(smear_coef_BinaryHS,smeared_BinaryHS,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_BinaryHS vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedBinaryHS","smear_coef_BinaryHS","BinaryHS")
End



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function BinaryHS(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BinaryHSX")
	yw = BinaryHSX(cw,xw)
#else
	yw = fBinaryHS(cw,xw)
#endif
	return(0)
End


//CH#1
// you should write your function to calculate the intensity
// for a single q-value (that's the input parameter x)
// based on the wave (array) of parameters that you send it (w)
//
Function fBinaryHS(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//	larger sphere radius(angstroms) = guess[0]
// smaller sphere radius (A) = w[1]
//	number fraction of larger spheres = guess[2]
//	total volume fraction of spheres = guess[3]
//	size ratio, alpha(0<a<1) = derived
//	SLD(A-2) of larger particle = guess[4]
//	SLD(A-2) of smaller particle = guess[5]
//	SLD(A-2) of the solvent = guess[6]
//background = guess[7]

//	give them nice names
	Variable r2,r1,nf2,phi,aa,rho2,rho1,rhos,inten,bgd
	Variable err,psf11,psf12,psf22
	Variable phi1,phi2,phr,a3
	
	r2 = w[0]
	r1 = w[1]
	phi2 = w[2]
	phi1 = w[3]
	rho2 = w[4]
	rho1 = w[5]
	rhos = w[6]
	bgd = w[7]
	
	phi = w[2] + w[3]		//total volume fraction
	aa = r1/r2		//alpha(0<a<1)
	
	//calculate the number fraction of larger spheres (eqn 2 in reference)
	a3=aa^3
	phr=phi2/phi
	nf2 = phr*a3/(1-phr+phr*a3)
	// calculate the PSF's here
	
	err = Ashcroft(x,r2,nf2,aa,phi,psf11,psf22,psf12)
	
	// /* do form factor calculations  */
	Variable v1,v2,n1,n2,qr1,qr2,b1,b2
	v1 = 4.0*PI/3.0*r1*r1*r1
	v2 = 4.0*PI/3.0*r2*r2*r2
//	a3 = aa*aa*aa
//	phi1 = phi*(1.0-nf2)*a3/(nf2+(1.0-nf2)*a3)
//	phi2 = phi - phi1
	n1 = phi1/v1
	n2 = phi2/v2

	qr1 = r1*x
	qr2 = r2*x
	b1 = r1*r1*r1*(rho1-rhos)*BHSbfunc(qr1)
	b2 = r2*r2*r2*(rho2-rhos)*BHSbfunc(qr2)
	inten = n1*b1*b1*psf11
	inten += sqrt(n1*n2)*2.0*b1*b2*psf12
	inten += n2*b2*b2*psf22
///* convert I(1/A) to (1/cm)  */
	inten *= 1.0e8
	
	inten += bgd
	Return (inten)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function BinaryHS_PSF11(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BinaryHS_PSF11X")
	yw = BinaryHS_PSF11X(cw,xw)
#else
	yw = fBinaryHS_PSF11(cw,xw)
#endif
	return(0)
End

Function fBinaryHS_PSF11(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//	larger sphere radius(angstroms) = guess[0]
// smaller sphere radius (A) = w[1]
//	number fraction of larger spheres = guess[2]
//	total volume fraction of spheres = guess[3]
//	size ratio, alpha(0<a<1) = derived
//	SLD(A-2) of larger particle = guess[4]
//	SLD(A-2) of smaller particle = guess[5]
//	SLD(A-2) of the solvent = guess[6]
//background = guess[7]

//	give them nice names
	Variable r2,r1,nf2,phi,aa,rho2,rho1,rhos,inten,bgd
	Variable err,psf11,psf12,psf22
	Variable phi1,phi2,a3,phr
	
	r2 = w[0]
	r1 = w[1]
	phi2 = w[2]
	phi1 = w[3]
	rho2 = w[4]
	rho1 = w[5]
	rhos = w[6]
	bgd = w[7]
	
	phi = w[2] + w[3]		//total volume fraction
	aa = r1/r2		//alpha(0<a<1)
	
	//calculate the number fraction of larger spheres (eqn 2 in reference)
	a3=aa^3
	phr=phi2/phi
	nf2 = phr*a3/(1-phr+phr*a3)
	
	// calculate the PSF's here
	
	err = Ashcroft(x,r2,nf2,aa,phi,psf11,psf22,psf12)
	return(psf11)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function BinaryHS_PSF12(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BinaryHS_PSF12X")
	yw = BinaryHS_PSF12X(cw,xw)
#else
	yw = fBinaryHS_PSF12(cw,xw)
#endif
	return(0)
End

Function fBinaryHS_PSF12(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//	larger sphere radius(angstroms) = guess[0]
// smaller sphere radius (A) = w[1]
//	number fraction of larger spheres = guess[2]
//	total volume fraction of spheres = guess[3]
//	size ratio, alpha(0<a<1) = derived
//	SLD(A-2) of larger particle = guess[4]
//	SLD(A-2) of smaller particle = guess[5]
//	SLD(A-2) of the solvent = guess[6]
//background = guess[7]

//	give them nice names
	Variable r2,r1,nf2,phi,aa,rho2,rho1,rhos,inten,bgd
	Variable err,psf11,psf12,psf22
	Variable phi1,phi2,a3,phr
	
	r2 = w[0]
	r1 = w[1]
	phi2 = w[2]
	phi1 = w[3]
	rho2 = w[4]
	rho1 = w[5]
	rhos = w[6]
	bgd = w[7]
	
	phi = w[2] + w[3]		//total volume fraction
	aa = r1/r2		//alpha(0<a<1)
	
	//calculate the number fraction of larger spheres (eqn 2 in reference)
	a3=aa^3
	phr=phi2/phi
	nf2 = phr*a3/(1-phr+phr*a3)
	
	// calculate the PSF's here
	
	err = Ashcroft(x,r2,nf2,aa,phi,psf11,psf22,psf12)
	return(psf12)
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function BinaryHS_PSF22(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("BinaryHS_PSF22X")
	yw = BinaryHS_PSF22X(cw,xw)
#else
	yw = fBinaryHS_PSF22(cw,xw)
#endif
	return(0)
End

Function fBinaryHS_PSF22(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//	larger sphere radius(angstroms) = guess[0]
// smaller sphere radius (A) = w[1]
//	number fraction of larger spheres = guess[2]
//	total volume fraction of spheres = guess[3]
//	size ratio, alpha(0<a<1) = derived
//	SLD(A-2) of larger particle = guess[4]
//	SLD(A-2) of smaller particle = guess[5]
//	SLD(A-2) of the solvent = guess[6]
//background = guess[7]

//	give them nice names
	Variable r2,r1,nf2,phi,aa,rho2,rho1,rhos,inten,bgd
	Variable err,psf11,psf12,psf22
	Variable phi1,phi2,phr,a3
	
	r2 = w[0]
	r1 = w[1]
	phi2 = w[2]
	phi1 = w[3]
	rho2 = w[4]
	rho1 = w[5]
	rhos = w[6]
	bgd = w[7]
	
	phi = w[2] + w[3]		//total volume fraction
	aa = r1/r2		//alpha(0<a<1)
	
	//calculate the number fraction of larger spheres (eqn 2 in reference)
	a3=aa^3
	phr=phi2/phi
	nf2 = phr*a3/(1-phr+phr*a3)
	// calculate the PSF's here
	
	err = Ashcroft(x,r2,nf2,aa,phi,psf11,psf22,psf12)
	return(psf22)
End

Function BHSbfunc(qr)
	Variable qr
	
	Variable ans

	ans = 4.0*pi*(sin(qr)-qr*cos(qr))/qr/qr/qr
	return(ans)
End


Function Ashcroft(qval,r2,nf2,aa,phi,s11,s22,s12)
	Variable qval,r2,nf2,aa,phi,&s11,&s22,&s12

//   CALCULATE CONSTANT TERMS
	Variable s1,s2,v,a3,v1,v2,g11,g12,g22,wmv,wmv3,wmv4
	Variable a1,a2i,a2,b1,b2,b12,gm1,gm12
	Variable err,yy,ay,ay2,ay3,t1,t2,t3,f11,y2,y3,tt1,tt2,tt3
	Variable c11,c22,c12,f12,f22,ttt1,ttt2,ttt3,ttt4,yl,y13
	Variable t21,t22,t23,t31,t32,t33,t41,t42,yl3,wma3,y1

	s2 = 2.0*r2
	s1 = aa*s2
	v = phi
	a3 = aa*aa*aa
	V1=((1.-nf2)*A3/(nf2+(1.-nf2)*A3))*V
	V2=(nf2/(nf2+(1.-nf2)*A3))*V
	G11=((1.+.5*V)+1.5*V2*(aa-1.))/(1.-V)/(1.-V)
	G22=((1.+.5*V)+1.5*V1*(1./aa-1.))/(1.-V)/(1.-v)
	G12=((1.+.5*V)+1.5*(1.-aa)*(V1-V2)/(1.+aa))/(1.-V)/(1.-v)
	wmv = 1/(1.-v)
	wmv3 = wmv*wmv*wmv
	wmv4 = wmv*wmv3
	A1=3.*wmv4*((V1+A3*V2)*(1.+V+V*v)-3.*V1*V2*(1.-aa)*(1.-aa)*(1.+V1+aa*(1.+V2))) + ((V1+A3*V2)*(1.+2.*V)+(1.+V+V*v)-3.*V1*V2*(1.-aa)*(1.-aa)-3.*V2*(1.-aa)*(1.-aa)*(1.+V1+aa*(1.+V2)))*wmv3
	A2I=((V1+A3*V2)*(1.+V+V*v)-3.*V1*V2*(1.-aa)*(1.-aa)*(1.+V1+aa*(1.+V2)))*3*wmv4 + ((V1+A3*V2)*(1.+2.*V)+A3*(1.+V+V*v)-3.*V1*V2*(1.-aa)*(1.-aa)*aa-3.*V1*(1.-aa)*(1.-aa)*(1.+V1+aa*(1.+V2)))*wmv3
	A2=A2I/a3
	B1=-6.*(V1*G11*g11+.25*V2*(1.+aa)*(1.+aa)*aa*G12*g12)
	B2=-6.*(V2*G22*g22+.25*V1/A3*(1.+aa)*(1.+aa)*G12*g12)
	B12=-3.*aa*(1.+aa)*(V1*G11/aa/aa+V2*G22)*G12
	GM1=(V1*A1+A3*V2*A2)*.5
	GM12=2.*GM1*(1.-aa)/aa
//C  
//C   CALCULATE THE DIRECT CORRELATION FUNCTIONS AND PRINT RESULTS
//C
//	DO 20 J=1,npts

	yy=qval*s2
//c   calculate direct correlation functions
//c   ----c11
	AY=aa*yy
	ay2 = ay*ay
	ay3 = ay*ay*ay
	T1=A1*(SIN(AY)-AY*COS(AY))
	T2=B1*(2.*AY*sin(AY)-(AY2-2.)*cos(AY)-2.)/AY
	T3=GM1*((4.*AY*ay2-24.*AY)*sin(AY)-(AY2*ay2-12.*AY2+24.)*cos(AY)+24.)/AY3
	F11=24.*V1*(T1+T2+T3)/AY3 

//c ------c22
	y2=yy*yy
	y3=yy*y2
	TT1=A2*(sin(yy)-yy*cos(yy))
	TT2=B2*(2.*yy*sin(yy)-(Y2-2.)*cos(yy)-2.)/yy
	TT3=GM1*((4.*Y3-24.*yy)*sin(yy)-(Y2*y2-12.*Y2+24.)*cos(yy)+24.)/ay3
	F22=24.*V2*(TT1+TT2+TT3)/Y3

//c   -----c12
	YL=.5*yy*(1.-aa)
	yl3=yl*yl*yl
	wma3 = (1.-aa)*(1.-aa)*(1.-aa)
	Y1=aa*yy
	y13 = y1*y1*y1
	TTT1=3.*wma3*V*sqrt(nf2)*sqrt(1.-nf2)*A1*(sin(YL)-YL*cos(YL))/((nf2+(1.-nf2)*A3)*YL3)
	T21=B12*(2.*Y1*cos(Y1)+(Y1^2-2.)*sin(Y1))
	T22=GM12*((3.*Y1*y1-6.)*cos(Y1)+(Y1^3-6.*Y1)*sin(Y1)+6.)/Y1 
	T23=GM1*((4.*Y13-24.*Y1)*cos(Y1)+(Y13*y1-12.*Y1*y1+24.)*sin(Y1))/(Y1*y1)
	T31=B12*(2.*Y1*sin(Y1)-(Y1^2-2.)*cos(Y1)-2.)
	T32=GM12*((3.*Y1^2-6.)*sin(Y1)-(Y1^3-6.*Y1)*cos(Y1))/Y1
  	T33=GM1*((4.*Y13-24.*Y1)*sin(Y1)-(Y13*y1-12.*Y1*y1+24.)*cos(Y1)+24.)/(y1*y1)
	T41=cos(YL)*((sin(Y1)-Y1*cos(Y1))/(Y1*y1) + (1.-aa)/(2.*aa)*(1.-cos(Y1))/Y1)
	T42=sin(YL)*((cos(Y1)+Y1*sin(Y1)-1.)/(Y1*y1) + (1.-aa)/(2.*aa)*sin(Y1)/Y1)
	TTT2=sin(YL)*(T21+T22+T23)/(y13*y1)
	TTT3=cos(YL)*(T31+T32+T33)/(y13*y1)
	TTT4=A1*(T41+T42)/Y1
	F12=TTT1+24.*V*sqrt(nf2)*sqrt(1.-nf2)*A3*(TTT2+TTT3+TTT4)/(nf2+(1.-nf2)*A3)

	C11=F11
	C22=F22
	C12=F12
	S11=1./(1.+C11-(C12)*c12/(1.+C22)) 
	S22=1./(1.+C22-(C12)*c12/(1.+C11)) 
	S12=-C12/((1.+C11)*(1.+C22)-(C12)*(c12))   

	return(err)
End
	

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedBinaryHS(coefW,yW,xW)
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
	err = SmearedBinaryHS(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedBinaryHS(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(BinaryHS,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End



Macro Plot_BinaryHS_PSF()

	if(Exists("coef_BinaryHS") != 1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	Make/O/D/n=(numpnts(xwave_BinaryHS)) psf11_BinaryHS,psf12_BinaryHS,psf22_BinaryHS,QD2_BinaryHS

	Variable/G root:g_psf11,root:g_psf12,root:g_psf22,root:g_QD2
	
	g_psf11 := BinaryHS_psf11(coef_BinaryHS, psf11_BinaryHS, xwave_BinaryHS)
	g_psf12 := BinaryHS_psf12(coef_BinaryHS, psf12_BinaryHS, xwave_BinaryHS)
	g_psf22 := BinaryHS_psf22(coef_BinaryHS, psf22_BinaryHS, xwave_BinaryHS)
	QD2_BinaryHS := xwave_BinaryHS*coef_BinaryHS[0]*2
//	Display psf11_BinaryHS vs xwave_BinaryHS
//	AppendtoGraph psf12_BinaryHS vs xwave_BinaryHS
//	AppendtoGraph psf22_BinaryHS vs xwave_BinaryHS
	
	Display psf11_BinaryHS vs QD2_BinaryHS
	AppendtoGraph psf12_BinaryHS vs QD2_BinaryHS
	AppendtoGraph psf22_BinaryHS vs QD2_BinaryHS
	
	ModifyGraph marker=19, msize=2, mode=4
	ModifyGraph lsize=2,rgb(psf12_BinaryHS)=(2,39321,1)
	ModifyGraph rgb(psf22_BinaryHS)=(0,0,65535)
	ModifyGraph log=0,grid=1,mirror=2
	SetAxis bottom 0,30
	Label bottom "q*LargeDiameter"
	Label left "Sij(q)"
	Legend
//
End


//useful for finding the parameters that duplicate the 
//figures in the original reference (uses the same notation)
//automatically changes the coefficient wave
Macro Duplicate_AL_Parameters(eta,xx,alpha,Rlarge)
	Variable eta=0.45,xx=0.4,alpha=0.7,Rlarge=100
	
	Variable r1,phi1,phi2,a3
	r1 = alpha*Rlarge
	a3 = alpha*alpha*alpha
	phi1 = eta*(1.0-xx)*a3/(xx+(1.0-xx)*a3)		//eqn [2]
	phi2 = eta - phi1
	
	Print "phi (larger) = ",phi2
	Print "phi (smaller) = ",phi1
	Print "Radius (smaller) = ",r1
	
	if(Exists("coef_BinaryHS") != 1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	
	coef_BinaryHS[2] = phi2
	coef_BinaryHS[3] = phi1
	coef_BinaryHS[1] = r1
End


//calculates number fractions of each population based on the 
//coef_BinaryHS parameters
Macro Calculate_BHS_Parameters()

	if(exists("coef_BinaryHS") != 1)
		Abort "You must plot the unsmeared BHS model first to create the coefficient wave"
	endif
	Variable r1,r2,phi1,phi2,aa	//same notation as paper - r2 is LARGER
	Variable a3,xx,phi
	r1 = coef_BinaryHS[1]
	r2 = coef_BinaryHS[0]
	phi1 = coef_BinaryHS[3]
	phi2 = coef_BinaryHS[2]
	
	phi = phi1+phi2
	aa = r1/r2
	a3 = aa^3
	
	xx = phi2/phi*a3
	xx /= (1-(phi2/phi)+(phi2/phi)*a3)
	
	Print "Number fraction (larger) = ",xx
	Print "Number fraction (smaller) = ",1-xx
	
End