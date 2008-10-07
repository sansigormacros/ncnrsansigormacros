#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this example is for the scattered intensity from a dense dispersion of polydisperse spheres
// hard sphere interactions are included (exact, multicomponent Percus-Yevick)
// the polydispersity in radius is a Schulz distribution
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotPolyHardSpheres(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_phs,ywave_phs
	xwave_phs =alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_phs = {100,0.12,0.1,2.0e-6,0.1}
	make/o/t parameters_phs = {"Radius (A)","polydispersity","volume fraction","contrast (A^-2)","background (cm^-1)"}
	Edit parameters_phs,coef_phs
	ywave_phs := PolyHSIntensity(coef_phs,xwave_phs)
	Display ywave_phs vs xwave_phs
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedPolyHardSpheres()		
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_phs = {100,0.12,0.1,2.0e-6,0.1}
	make/o/t smear_parameters_phs = {"Radius (A)","polydispersity","volume fraction","contrast (A^-2)","background (cm^-1)"}
	Edit smear_parameters_phs,smear_coef_phs
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_phs,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_phs

	smeared_phs := SmearedPolyHardSpheres(smear_coef_phs,$gQvals)
	Display smeared_phs vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End


///////////////////////////////////////////////////////////////
// unsmeared model calculation
//   This program calculates the effective structure factor for a suspension
//   of spheres whose size distribution is given by a Schulz distribution
//   PY closure was used to solve.  Equations are analytical.
//   Follows paper by W.L. Griffith, Phys. Rev. A 35 (5) p.2200 1987
//  Original coding (F) by Jon Bender, U. Delaware
//	converted to c 2/97 SRK
// converted to IGOR 12/97 SRK
//
// replace single letter variables like "e" with "ee" (to be done MAY04)
//
///////////////////////////
Function PolyHSIntensity(w,k) : FitFunc
	Wave w			// the coefficient wave
	Variable k		// the x values, as a variable (single k is OK)

	// assign local variables
	Variable mu,mu1,d1,d2,d3,d4,d5,d6,capd,rho,beta
	Variable ll,l1,bb,cc,chi,chi1,chi2,ee,t1,t2,t3,pp
	Variable ka,zz,v1,v2,p1,p2
	Variable h1,h2,h3,h4,e1,yy,y1,ss,s1,s2,s3,hint1,hint2
	Variable capl,capl1,capmu,capmu1,r3,pq,happ
	Variable ka2,r1,heff
	Variable hh
	 
	//* reassign names to the variable set */
	Variable rad,z2,phi,cont,bkg,sigma
	 
	rad = w[0]		// radius (A)
	sigma = 2*rad
	z2 = w[1]		//polydispersity (0<z2<1)
	phi = w[2]		// volume fraction (0<phi<1)
	cont = w[3]*1.0e4		// contrast (odd units)
	bkg = w[4]		// background (1/cm)

	zz=1/(z2*z2)-1.0
	bb = sigma/(zz+1)
	cc = zz+1

//*c   Compute the number density by <r-cubed>, not <r> cubed*/
	r1 = sigma/2.0
	r3 = r1*r1*r1
	r3 *= (zz+2)*(zz+3)/((zz+1)*(zz+1))
	rho=phi/(1.3333333333*pi*r3)
	t1 = rho*bb*cc
	t2 = rho*bb*bb*cc*(cc+1)
	t3 = rho*bb*bb*bb*cc*(cc+1)*(cc+2)
	capd = 1-pi*t3/6
//************
	v1=1/(1+bb*bb*k*k)
	v2=1/(4+bb*bb*k*k)
	pp=(v1^(cc/2))*sin(cc*atan(bb*k))
	p1=bb*cc*(v1^((cc+1)/2))*sin((cc+1)*atan(bb*k))
	p2=cc*(cc+1)*bb*bb*(v1^((cc+2)/2))*sin((cc+2)*atan(bb*k))
	mu=(2^cc)*(v2^(cc/2))*sin(cc*atan(bb*k/2))
	mu1=(2^(cc+1))*bb*cc*(v2^((cc+1)/2))*sin((cc+1)*atan(k*bb/2))
	s1=bb*cc
	s2=cc*(cc+1)*bb*bb
	s3=cc*(cc+1)*(cc+2)*bb*bb*bb
	chi=(v1^(cc/2))*cos(cc*atan(bb*k))
	chi1=bb*cc*(v1^((cc+1)/2))*cos((cc+1)*atan(bb*k))
	chi2=cc*(cc+1)*bb*bb*(v1^((cc+2)/2))*cos((cc+2)*atan(bb*k))
	ll=(2^cc)*(v2^(cc/2))*cos(cc*atan(bb*k/2))
	l1=(2^(cc+1))*bb*cc*(v2^((cc+1)/2))*cos((cc+1)*atan(k*bb/2))
	d1=(pi/capd)*(2+(pi/capd)*(t3-(rho/k)*(k*s3-p2)))
	d2=((pi/capd)^2)*(rho/k)*(k*s2-p1)
	d3=(-1.0)*((pi/capd)^2)*(rho/k)*(k*s1-pp)
	d4=(pi/capd)*(k-(pi/capd)*(rho/k)*(chi1-s1))
	d5=((pi/capd)^2)*((rho/k)*(chi-1)+0.5*k*t2)
	d6=((pi/capd)^2)*(rho/k)*(chi2-s2)
 // e1,e,y1,y evaluated in one big ugly line instead - no continuation character in IGOR 
//            e1=pow((pi/capd),2)*pow((rho/k/k),2)*((chi-1)*(chi2-s2)
//       -(chi1-s1)*(chi1-s1)-(k*s1-p)*(k*s3-p2)+pow((k*s2-p1),2));
//            e=1-(2*pi/capd)*(1+0.5*pi*t3/capd)*(rho/k/k/k)*(k*s1-p)
//       -(2*pi/capd)*rho/k/k*((chi1-s1)+(0.25*pi*t2/capd)*(chi2-s2))-e1;
//            y1=pow((pi/capd),2)*pow((rho/k/k),2)*((k*s1-p)*(chi2-s2)
//       -2*(k*s2-p1)*(chi1-s1)+(k*s3-p2)*(chi-1));
//            y = (2*pi/capd)*(1+0.5*pi*t3/capd)*(rho/k/k/k)
//       *(chi+0.5*k*k*s2-1)-(2*pi*rho/capd/k/k)*(k*s2-p1
//       +(0.25*pi*t2/capd)*(k*s3-p2))-y1;
       
	e1=((pi/capd)^2)*((rho/k/k)^2)*((chi-1)*(chi2-s2)-(chi1-s1)*(chi1-s1)-(k*s1-pp)*(k*s3-p2)+((k*s2-p1)^2))
	ee=1-(2*pi/capd)*(1+0.5*pi*t3/capd)*(rho/k/k/k)*(k*s1-pp)-(2*pi/capd)*rho/k/k*((chi1-s1)+(0.25*pi*t2/capd)*(chi2-s2))-e1
	y1=((pi/capd)^2)*((rho/k/k)^2)*((k*s1-pp)*(chi2-s2)-2*(k*s2-p1)*(chi1-s1)+(k*s3-p2)*(chi-1))
	yy = (2*pi/capd)*(1+0.5*pi*t3/capd)*(rho/k/k/k)*(chi+0.5*k*k*s2-1)-(2*pi*rho/capd/k/k)*(k*s2-p1+(0.25*pi*t2/capd)*(k*s3-p2))-y1       

	capl=2.0*pi*cont*rho/k/k/k*(pp-0.5*k*(s1+chi1))
	capl1=2.0*pi*cont*rho/k/k/k*(p1-0.5*k*(s2+chi2))
	capmu=2.0*pi*cont*rho/k/k/k*(1-chi-0.5*k*p1)
	capmu1=2.0*pi*cont*rho/k/k/k*(s1-chi1-0.5*k*p2)
 
	h1=capl*(capl*(yy*d1-ee*d6)+capl1*(yy*d2-ee*d4)+capmu*(ee*d1+yy*d6)+capmu1*(ee*d2+yy*d4))
	h2=capl1*(capl*(yy*d2-ee*d4)+capl1*(yy*d3-ee*d5)+capmu*(ee*d2+yy*d4)+capmu1*(ee*d3+yy*d5))
	h3=capmu*(capl*(ee*d1+yy*d6)+capl1*(ee*d2+yy*d4)+capmu*(ee*d6-yy*d1)+capmu1*(ee*d4-yy*d2))
	h4=capmu1*(capl*(ee*d2+yy*d4)+capl1*(ee*d3+yy*d5)+capmu*(ee*d4-yy*d2)+capmu1*(ee*d5-yy*d3))

//*  This part computes the second integral in equation (1) of the paper.*/

	hint1 = -2.0*(h1+h2+h3+h4)/(k*k*k*(ee*ee+yy*yy))
 
//*  This part computes the first integral in equation (1).  It also
// generates the KC approximated effective structure factor.*/

	pq=4*pi*cont*(sin(k*sigma/2)-0.5*k*sigma*cos(k*sigma/2))
	hint2=8*pi*pi*rho*cont*cont/(k*k*k*k*k*k)*(1-chi-k*p1+0.25*k*k*(s2+chi2))
 
	ka=k*(sigma/2)
//
	hh=hint1+hint2		// this is the model intensity
//
	heff=1.0+hint1/hint2
	ka2=ka*ka
//*
//  heff is PY analytical solution for intensity divided by the 
//   form factor.  happ is the KC approximated effective S(q)
 
//*******************
//  add in the background then return the intensity value

	return (hh+bkg)

End   // end of fcngrif()

// this is all there is to the smeared calculation!
Function SmearedPolyHardSpheres(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(PolyHSIntensity,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
