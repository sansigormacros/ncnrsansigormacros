#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////////
//
// description
//
//
// reference -
// - errors in paper
//
// warning about unphysical regions
//
// + how to properly handle if result is unphysical????
//
//
// S. Kline 15 JUL 2004
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc PlotStickyHS_Struct(num,qmin,qmax)
	Variable num=256, qmin=.001, qmax=.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_shsSQ, ywave_shsSQ
	xwave_shsSQ =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_shsSQ = {50,0.1,0.05,0.2}			//CH#2
	make/o/t parameters_shsSQ = {"Radius","volume fraction","perturbation parameter (0.1)","stickiness, tau"}	//CH#3
	Edit parameters_shsSQ, coef_shsSQ
	Variable/G root:g_shsSQ
	g_shsSQ  := StickyHS_Struct(coef_shsSQ, ywave_shsSQ, xwave_shsSQ)
//	ywave_shsSQ  := StickyHS_Struct(coef_shsSQ, xwave_shsSQ)
	Display ywave_shsSQ vs xwave_shsSQ
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=0
	Label bottom "q (A\\S-1\\M) "
	Label left "S(q)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("StickyHS_Struct","coef_shsSQ","parameters_shsSQ","shsSQ")
//
End

//AAO function
Function StickyHS_Struct(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("StickyHS_StructX")
	yw = StickyHS_StructX(cw,xw)
#else
	yw = fStickyHS_Struct(cw,xw)
#endif
	return(0)
End

Function fStickyHS_Struct(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
	//radius = w[0]
	//volume fraction = w[1]
	//epsilon (perurbation param) = w[2]
	//tau (stickiness) = w[3]
	Variable rad,phi,eps,tau,eta
	Variable sig,aa,etam1,qa,qb,qc,radic
	Variable lam,lam2,test,mu,alpha,beta
	Variable qv,kk,k2,k3,ds,dc,aq1,aq2,aq3,aq,bq1,bq2,bq3,bq,sq
	rad = w[0]
	phi = w[1]
	eps = w[2]
	tau = w[3]
	
	eta = phi/(1.0-eps)/(1.0-eps)/(1.0-eps)
	
	sig = 2.0 * rad
	aa = sig/(1.0 - eps)
	etam1 = 1.0 - eta
//C
//C  SOLVE QUADRATIC FOR LAMBDA
//C
	qa = eta/12.0
	qb = -1.0*(tau + eta/(etam1))
	qc = (1.0 + eta/2.0)/(etam1*etam1)
	radic = qb*qb - 4.0*qa*qc
	if(radic<0)
		if(x>0.01 && x<0.015)
	 		Print "Lambda unphysical - both roots imaginary"
	 	endif
	 	return(-1)
	endif
//C   KEEP THE SMALLER ROOT, THE LARGER ONE IS UNPHYSICAL
	lam = (-1.0*qb-sqrt(radic))/(2.0*qa)
	lam2 = (-1.0*qb+sqrt(radic))/(2.0*qa)
	if(lam2<lam)
		lam = lam2
	endif
	test = 1.0 + 2.0*eta
	mu = lam*eta*etam1
	if(mu>test)
		if(x>0.01 && x<0.015)
		 Print "Lambda unphysical mu>test"
		endif
		return(-1)
	endif
	alpha = (1.0 + 2.0*eta - mu)/(etam1*etam1)
	beta = (mu - 3.0*eta)/(2.0*etam1*etam1)
	
//C
//C   CALCULATE THE STRUCTURE FACTOR
//C

	qv = x
	kk = qv*aa
	k2 = kk*kk
	k3 = kk*k2
	ds = sin(kk)
	dc = cos(kk)
	aq1 = ((ds - kk*dc)*alpha)/k3
	aq2 = (beta*(1.0-dc))/k2
	aq3 = (lam*ds)/(12.0*kk)
	aq = 1.0 + 12.0*eta*(aq1+aq2-aq3)
//
	bq1 = alpha*(0.5/kk - ds/k2 + (1.0 - dc)/k3)
	bq2 = beta*(1.0/kk - ds/k2)
	bq3 = (lam/12.0)*((1.0 - dc)/kk)
	bq = 12.0*eta*(bq1+bq2-bq3)
//
	sq = 1.0/(aq*aq +bq*bq)

	Return (sq)
End
