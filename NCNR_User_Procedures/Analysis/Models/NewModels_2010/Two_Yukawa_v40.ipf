#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

/////////////////////////////////////////////
//
// One-Yukawa and Two-Yukawa strucutre factors
//	Yun Liu, Wei-Ren Chen, and Sow-Hsin Chen, J. Chem. Phys. 122 (2005) 044507.
//
//
// Converted from Matlab to C by Marcus Hennig on 5/12/10
//
// Converted to Igor XOP - SRK July 2010
// -- There are many external calls and allocation/deallocation of memory, so the XOP is NOT THREADED
// -- The function calculation is inherently AAO, so this XOP definition is DIFFERENT than
//		all of the standard fitting functions.
// -- so be sure that the P*S implementations are not threaded - although P(q) can be threaded
//
// *** passing in Z values of zero can cause the XOP to crash. test for them here and send good values.
// -- the XOP will be modified to handle this and noted here when it is done. 0.001 seems to be OK
//    as a low value.
// -- for OneYukawa, 0.1 seems to be a reasonable minimum
//
// - remember that the dimensionless Q variable is Q*diameter
//
//
// conversion to Igor from the c-code was not terribly painful, and very useful for debugging.
//
//
// JAN 2014 SRK - added code to enforce Z1 > Z2. If this condition is not met, then the calculation will
//  return a solution, but it will be incorrect (the result will look like a valid structure factor, but be incorrect)
//  This condition is necessary due to the asymmetric treatment of these parameters in the mathematics of the calculation
//  by Yun Liu. A lower limit constraint has been added (automatically) so that the condition will be met while fitting
//  - without this constraint, parameter "flips" will confound the optimization. This LoLim wave only been added to the 
//    calculation of S(Q), not any combination PS functions.
// --- This, unfortunately means that all of the "_Sq" macros *MAY* need to be updated to reflect this constraint
//     so it will actually be enforced during fitting. I think I'll note this in the manual, and see if the fitting can
//     handle this. If it can't. I'll instruct users to add a LoLim to the Z1, and this should take care of this issue
//     Otherwise- I may just introduce more problems by programmatically enforcing "hidden" constraints, and have a lot more
//     code to maintain if the constraints are not quite correct in all situations.
//
// JAN 2014 - added code to bypass the condition Z1 == Z2, which is also diallowed in Yun's code.
// -- code to prevent K1 == 0 or K2 == 0 was previously in place.
// These conditions are all specified in Yun's "Appendix B" for the "TYSQ21 Matlab Package"
//
//
// as of September 2010:
//
// the one-component has not been tested at all
//
// -- the two component result nearly matches the result that Yun gets. I do need to relax the criteria for
// rejecting solutions, however. The XOP code rejects solutions that Yun considers "good". I guess I 
// need all of the intermediate values (polynomial coefficients, solution vectors, etc.). Other than some of the
// numerical values not matching up - the output S(q) looks to be correct.
//
// -- also, for some cases, the results are VERY finicky - ususally there is a threshold value say, in Z, where
// going beyond that value is unstable. Here, in can be a bit random as to which values works and which do not.
// It must be hitting some strange zeros in the functions.
//
//
// 		TO ADD:
//
// x- a mechanism for plotting the potential, so that users have a good handle on what the parameters actually mean.
//
//
/////////////////////////////////////////////




Proc PlotOneYukawa(num,qmin,qmax)
	Variable num=200,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_1yuk,ywave_1yuk
	xwave_1yuk = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	Make/O/D coef_1yuk = {0.1,50,-1,10}
	make/o/t parameters_1yuk = {"volume fraction","Radius (A)","scale, K","Decay constant, Z"}
	Edit parameters_1yuk,coef_1yuk
	Variable/G root:g_1yuk
	g_1yuk := OneYukawa(coef_1yuk,ywave_1yuk,xwave_1yuk)
//	g_1yuk := OneYukawaX(coef_1yuk,xwave_1yuk,ywave_1yuk)		//be sure to have x and y in the correct order
	Display ywave_1yuk vs xwave_1yuk
	ModifyGraph marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Structure Factor"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("OneYukawa","coef_1yuk","parameters_1yuk","1yuk")
End

//AAO version
Function OneYukawa(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

	if(abs(cw[3]) < 0.1)
		cw[3] = 0.1
	endif	
	
#if exists("OneYukawaX")		
	OneYukawaX(cw,xw,yw)
#else
	yw = 0
#endif
	return(0)
End


// no igor code, return 0
//
Function fOneYukawa(w,x) : FitFunc
	Wave w
	Variable x
	                
	return (0)
End

//////////////////////////////////////////////////////////////
Proc PlotTwoYukawa(num,qmin,qmax)
	Variable num=200,qmin=0.001,qmax=0.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	declare2YGlobals()		//only necessary if Igor code is used. Not needed if XOP code is used.
	
	Make/O/D/n=(num) xwave_2yuk,ywave_2yuk
	xwave_2yuk = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	Make/O/D coef_2yuk = {0.2,50,6,10,-1,2}
	make/o/t parameters_2yuk = {"volume fraction","Radius (A)","scale, K1","Decay constant, Z1","scale, K2","Decay constant, Z2"}
	Edit parameters_2yuk,coef_2yuk
	Variable/G root:g_2yuk
	g_2yuk := TwoYukawa(coef_2yuk,ywave_2yuk,xwave_2yuk)
	Display ywave_2yuk vs xwave_2yuk
	ModifyGraph marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Structure Factor"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)

	// make a constraint wave appropriate for the Z1 > Z2 condition for fitting
	// setting the lower bound on Z1 (> Z2) is sufficient to meet this condition
	// and check the box on the panel so that constraints are used
	Duplicate/O parameters_2yuk Lolim_2yuk
	LoLim_2yuk = ""
	LoLim_2yuk[3] = "K5"
	
	CheckBox check_2,win=wrapperPanel,value= 1

	
	AddModelToStrings("TwoYukawa","coef_2yuk","parameters_2yuk","2yuk")
	
End


//AAO version
//
Function TwoYukawa(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

// make sure that none of the values are too close to zero
// make them very small instead
	if(abs(cw[2]) < 0.001)
		cw[2] = 0.001
	endif
	if(abs(cw[3]) < 0.001)
		cw[3] = 0.001
	endif
	if(abs(cw[4]) < 0.001)
		cw[4] = 0.001
	endif
	if(abs(cw[5]) < 0.001)
		cw[5] = 0.001
	endif	

	if(cw[3] == cw[5])		// Z1 == Z2 not allowed, this may not be enough of a correction
		cw[3] *= 1.001
	endif	

// JAN 2014 -- SRK
// if I do a swap on cw, then the values on the table "flip" and is very un-natural
// - but it may be OK. Alternatively, I could create a tmp wave to pass through into the calculation.

	
// then make sure that Z1 > Z2 is true
// swap 1 and 2 if needed
	Variable tmp
	if(cw[5] > cw[3])
	//swap the K values
		tmp = cw[2]
		cw[2] = cw[4]
		cw[4] = tmp
	// then the Z values	
		tmp = cw[3]
		cw[3] = cw[5]
		cw[5] = tmp
	endif	
	
	
#if exists("TwoYukawaX")
	TwoYukawaX(cw,xw,yw)
#else
	fTwoYukawa(cw,xw,yw)
#endif
	return(0)
End

Proc TestTheIgor2YUK()
	//if the regular 2-yukawa procedure is already plotted
	// -- then append it to thte graph yourself
	Duplicate/O ywave_2yuk ywave_2yuk_Igor
	Variable/G root:g_2yuk_Igor=0
	g_2yuk_Igor := fTwoYukawa(coef_2yuk,xwave_2yuk,ywave_2yuk_Igor)
End

// with the regular 2-yukawa plotted, this uses the coefficients to plot g(r)
//
// - no dependency is created, it would just slow things down. So you'll
// need to re-run this every time.
//
//		gr is scaled to dimensionless distance, r/diameter
//
Macro Plot_2Yukawa_Gr()
	//if the regular 2-yukawa procedure is already plotted
	// -- then append it to thte graph yourself
	Duplicate/O ywave_2yuk ywave_2yuk_Igor

	fTwoYukawa(coef_2yuk,xwave_2yuk,ywave_2yuk_Igor)
	
	DoWindow/F Gr_plot
	if(V_flag==0)
		Display gr
		DoWindow/C Gr_plot
		Modifygraph log=0
		SetAxis bottom 0,10
		Modifygraph lsize=2
		Label left "g(r)";DelayUpdate
		Label bottom "dimensionless distance (r/diameter)"
		legend
	endif
	
	
	
End



//
Function fTwoYukawa(cw,xw,yw) : FitFunc
	Wave cw,xw,yw

	Variable Z1, Z2, K1, K2, phi,radius
	phi = cw[0]
	radius = cw[1]
	K1 = cw[2]
	Z1 = cw[3]
	K2 = cw[4]
	Z2 = cw[5]
	
	Variable a,b,c1,c2,d1,d2
	
	Variable ok,check,prnt
	prnt = 0 		//print out intermediates
	
	ok = TY_SolveEquations( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2, prnt )		// a,b,c1,c2,d1,d2 are returned
	if(ok)
		check = TY_CheckSolution( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 )
		if(prnt)
			printf "solution = (%g, %g, %g, %g, %g, %g) check = %d\r", a, b, c1, c2, d1, d2, check
		endif

//		if(check)
		if(ok)				//if(ok) simply takes the best solution, not necessarily one that passes TY_CheckSolution
			yw = SqTwoYukawa(xw*radius*2, Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2)
//			printf("%g	%g\n",q,sq)
		else
			yw = 1000		//return a really bogus answer, as Yun suggests
		endif
	endif
      
	return (0)
End


Macro Plot_2YukawaPotential()
	fPlot_2YukawaPotential()
End

Function fPlot_2YukawaPotential()

	Variable k1,z1,k2,z2,radius
	Variable ii=0,num=500,rmax=10,rval
	
	if(exists("root:coef_2yuk") == 0)
		Abort "You must plot the 2-Yukawa model before plotting the potential"
	else
		WAVE coef_2yuk = root:coef_2yuk
	endif
	
	radius = coef_2yuk[1]
	K1 = coef_2yuk[2]
	Z1 = coef_2yuk[3]
	K2 = coef_2yuk[4]
	Z2 = coef_2yuk[5]

	Make/O/D/N=(num) TwoYukawa_Potential,TwoYukawa_Potential_r
	TwoYukawa_Potential_r = x/num*rmax
	
	do
		rval = TwoYukawa_Potential_r[ii]
		if(rval <= 1)
			TwoYukawa_Potential[ii] = inf
		else
			TwoYukawa_Potential[ii] = -1*K1*(exp(-1*Z1*(rval-1))/rval) - K2*exp(-1*Z2*(rval-1))/rval
		endif
	
		ii+=1
	while(ii<num)
	
	
//	if graph is not open, draw a graph
	DoWindow YukawaPotential
	if(V_flag == 0)
		Display/N=YukawaPotential TwoYukawa_Potential vs TwoYukawa_Potential_r
		ModifyGraph marker=29,msize=2,mode=4,grid=1,mirror=2
		Label bottom "r/Diameter"
		Label left "V(r)/kT"
	endif
	
	return(0)
End



///////////////////// converted procedures from c-code ////////////////////////////

/// there were two functions defined as TY_q: one as TY_Q and one as TY_q. I renamed the TY_Q function as TY_capQ, and left TY_q unchanged

// function TY_W change to TY_capW, since there is a wave named TY_w





Static Function chop(x)
	Variable x

	if ( abs(x) < 1e-6 )
		return 0
	else 
		return x
	endif
	
end

Static Function pow(a,b)
	Variable a,b
	
	return (a^b)
end

///*
// ================================================================================================== 
// 
// The two-yukawa structure factor is uniquley determined by 6 parameters a, b, c1, c2, d1, d2,
// which are the solution of a system of 6 equations ( 4 linear, 2 nonlinear ). The solution can 
// constructed by the roots of a polynomial of 22nd degree. For more details see attached 
// Mathematica notebook, where a derivation is given
// 
// ================================================================================================== 
// */

// these all may need to be declared as global variables !! 
//
// - they are defined in a global scope in the c-code!
//
// - change the data folder
Function declare2YGlobals()

	NewDataFolder/O/S root:yuk
	
	Variable/G TY_q22
	Variable/G TY_qa12, TY_qa21, TY_qa22, TY_qa23, TY_qa32
	Variable/G TY_qb12, TY_qb21, TY_qb22, TY_qb23, TY_qb32
	Variable/G TY_qc112, TY_qc121, TY_qc122, TY_qc123, TY_qc132
	Variable/G TY_qc212, TY_qc221, TY_qc222, TY_qc223, TY_qc232
	Variable/G TY_A12, TY_A21, TY_A22, TY_A23, TY_A32, TY_A41, TY_A42, TY_A43, TY_A52
	Variable/G TY_B12, TY_B14, TY_B21, TY_B22, TY_B23, TY_B24, TY_B25, TY_B32, TY_B34
	Variable/G TY_F14, TY_F16, TY_F18, TY_F23, TY_F24, TY_F25, TY_F26, TY_F27, TY_F28, TY_F29, TY_F32, TY_F33, TY_F34, TY_F35, TY_F36, TY_F37, TY_F38, TY_F39, TY_F310
	Variable/G TY_G13, TY_G14, TY_G15, TY_G16, TY_G17, TY_G18, TY_G19, TY_G110, TY_G111, TY_G112, TY_G113, TY_G22, TY_G23, TY_G24, TY_G25, TY_G26, TY_G27, TY_G28, TY_G29, TY_G210, TY_G211, TY_G212, TY_G213, TY_G214
	
	SetDataFolder root:
	//this is an array, already global TY_w[23];

End


Function TY_sigma( s, Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 )
	Variable  s, Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 

	return -(a / 2. + b + c1 * exp( -Z1 ) + c2 * exp( -Z2 )) / s + a * pow( s, -3 ) + b * pow( s, -2 ) + ( c1 + d1 ) * pow( s + Z1, -1 ) + ( c2 + d2 ) * pow( s + Z2, -1 )
end

Function TY_tau(  s, Z1,  Z2, a,  b,  c1,  c2 )
	Variable   s, Z1,  Z2, a,  b,  c1,  c2 
	
	return b * pow( s, -2 ) + a * ( pow( s, -3 ) + pow( s, -2 ) ) - pow( s, -1 ) * ( c1 * Z1 * exp( -Z1 ) * pow( s + Z1, -1 ) + c2 * Z2 * exp( -Z2 ) * pow( s + Z2, -1 ) )
end 

Function TY_q(  s, Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 )
	Variable  s, Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 
	return TY_sigma(s, Z1, Z2, a, b, c1, c2, d1, d2) - exp( -s ) * TY_tau(s, Z1, Z2, a,b, c1, c2)
end

Function TY_g(  s, phi,  Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 )
	Variable   s, phi,  Z1,  Z2, a,  b,  c1,  c2,  d1,  d2 
	return s * TY_tau( s, Z1, Z2, a, b, c1, c2 ) * exp( -s ) / ( 1 - 12 * phi * TY_q( s, Z1, Z2, a, b, c1, c2, d1, d2 ) )
end

///*
// ================================================================================================== 
// 
// Structure factor for the potential 
// 
// V(r) = -kB * T * ( K1 * exp[ -Z1 * (r - 1)] / r + K2 * exp[ -Z2 * (r - 1)] / r ) for r > 1
// V(r) = inf for r <= 1
// 
// The structure factor is parametrized by (a, b, c1, c2, d1, d2) 
// which depend on (K1, K2, Z1, Z2, phi).  
// 
// ================================================================================================== 
// */

Function TY_hq(  q,  Z,  K,  v )
	Variable   q,  Z,  K,  v 
	
	if ( q == 0) 
		return (exp(-2.*Z)*(v + (v*(-1. + Z) - 2.*K*Z)*exp(Z))*(-(v*(1. + Z)) + (v + 2.*K*Z*(1. + Z))*exp(Z))*pow(K,-1)*pow(Z,-4))/4.
	else 
	
		variable t1, t2, t3, t4
		
		t1 = ( 1. - v / ( 2. * K * Z * exp( Z ) ) ) * ( ( 1. - cos( q ) ) / ( q*q ) - 1. / ( Z*Z + q*q ) )
		t2 = ( v*v * ( q * cos( q ) - Z * sin( q ) ) ) / ( 4. * K * Z*Z * q * ( Z*Z + q*q ) )
		t3 = ( q * cos( q ) + Z * sin( q ) ) / ( q * ( Z*Z + q*q ) )
		t4 = v / ( Z * exp( Z ) ) - v*v / ( 4. * K * Z*Z * exp( 2. * Z ) ) - K
		
		return v / Z * t1 - t2 + t3 * t4
	endif
end


Function TY_pc(  q, Z1,  Z2, K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable   q, Z1,  Z2, K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	variable v1 = 24. * phi * K1 * exp( Z1 ) * TY_g( Z1, phi, Z1, Z2, a, b, c1, c2, d1, d2 )
	variable v2 = 24. * phi * K2 * exp( Z2 ) * TY_g( Z2, phi, Z1, Z2, a, b, c1, c2, d1, d2 )
	
	variable a0 = a * a
	variable b0 = -12. * phi *( pow( a + b,2 ) / 2. + a * ( c1 * exp( -Z1 ) + c2 * exp( -Z2 ) ) )
	
	variable t1, t2, t3
	
	if ( q == 0 ) 
		t1 = a0 / 3.
		t2 = b0 / 4.
		t3 = a0 * phi / 12.
	else 
		t1 = a0 * ( sin( q ) - q * cos( q ) ) / pow( q, 3 )
		t2 = b0 * ( 2. * q * sin( q ) - ( q * q - 2. ) * cos( q ) - 2. ) / pow( q, 4 )
		t3 = a0 * phi * ( ( q*q - 6. ) * 4. * q * sin( q ) - ( pow( q, 4 ) - 12. * q*q + 24.) * cos( q ) + 24. ) / ( 2. * pow( q, 6 ) )
	endif
	
	variable t4 = TY_hq( q, Z1, K1, v1 ) + TY_hq( q, Z2, K2, v2 )
	
	return -24. * phi * ( t1 + t2 + t3 + t4 )
end

Function SqTwoYukawa(  q, Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	variable   q, Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	if ( Z1 == Z2 ) 
		// one-yukawa potential
		return 0 
	else 
		// two-yukawa potential
		return 1. / ( 1. - TY_pc( q, Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	endif
end

///*
//================================================================================================== 
//
// Non-linear eqaution system that determines the parameter for structure factor
//  
//================================================================================================== 
//*/

Function TY_LinearEquation_1(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable   Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	return b - 12. * phi * ( -a / 8. - b / 6. + d1 * pow( Z1, -2 ) + c1 * ( pow( Z1, -2 )  - exp( -Z1 ) * ( 0.5 + ( 1. + Z1 ) * pow( Z1, -2 ) ) ) + d2 * pow( Z2, -2 ) + c2 * ( pow( Z2, -2 ) - exp( -Z2 )* ( 0.5 + ( 1. + Z2 ) * pow( Z2, -2 ) ) ) )
end

Function TY_LinearEquation_2(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	return 1. - a - 12. * phi * ( -a / 3. - b / 2. + d1 * pow( Z1, -1 ) + c1 * ( pow( Z1, -1 ) - ( 1. + Z1 ) * exp( -Z1 ) * pow( Z1, -1 ) ) + d2 * pow( Z2, -1 ) + c2 * ( pow( Z2, -1 ) - ( 1. + Z2 ) * exp( -Z2 ) * pow( Z2, -1 ) ) )
end	

Function TY_LinearEquation_3(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
							
	return K1 * exp( Z1 ) - d1 * Z1 * ( 1. - 12. * phi * TY_q( Z1, Z1, Z2, a, b, c1, c2, d1, d2 ) )
end

Function TY_LinearEquation_4(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	return K2 * exp( Z2 ) - d2 * Z2 * ( 1. - 12. * phi * TY_q( Z2, Z1, Z2, a, b, c1, c2, d1, d2 ) )
end

Function TY_NonlinearEquation_1(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	return c1 + d1 - 12. * phi * ( ( c1 + d1 ) * TY_sigma( Z1, Z1, Z2, a, b, c1, c2, d1, d2 ) - c1 * TY_tau( Z1, Z1, Z2, a, b, c1, c2 ) * exp( -Z1 ) )
end

Function TY_NonlinearEquation_2(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	Variable  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	return c2 + d2 - 12. * phi * ( ( c2 + d2 ) * TY_sigma( Z2, Z1, Z2, a, b, c1, c2, d1, d2 ) - c2 * TY_tau( Z2, Z1, Z2, a, b, c1, c2 ) * exp( -Z2 ) )
end

// Check the computed solutions satisfy the system of equations 
Function TY_CheckSolution(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 )
	variable   Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2 
	
	variable eq_1 = chop( TY_LinearEquation_1( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	variable eq_2 = chop( TY_LinearEquation_2( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	variable eq_3 = chop( TY_LinearEquation_3( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	variable eq_4 = chop( TY_LinearEquation_4( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	variable eq_5 = chop( TY_NonlinearEquation_1( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	variable eq_6 = chop( TY_NonlinearEquation_2( Z1, Z2, K1, K2, phi, a, b, c1, c2, d1, d2 ) )
	
//	printf("Check of solution = %g %g %g %g %g %g\r",eq_1,eq_2,eq_3,eq_4,eq_5,eq_6);
	// check if all equation are zero
	return ( eq_1 == 0 && eq_2 == 0 && eq_3 == 0 && eq_4 == 0 && eq_5 == 0 && eq_6 == 0 )
end

Function TY_ReduceNonlinearSystem( Z1, Z2,  K1,  K2,  phi,  prnt )
	Variable  Z1, Z2,  K1,  K2,  phi,  prnt 
	
	
//	/* solution of the 4 linear equations depending on d1 and d2, the solution is polynomial
//	 in d1, d2. We represend the solution as determiants obtained by Cramer's rule
//	 which can be expressed by their coefficient matrices
//	 */
	
	Variable m11 = (3.*phi)/2.
	Variable m13 = 6.*phi*exp(-Z1)*(2. + Z1*(2. + Z1) - 2.*exp(Z1))*pow(Z1,-2)
	Variable m14 = 6.*phi*exp(-Z2)*(2. + Z2*(2. + Z2) - 2.*exp(Z2))*pow(Z2,-2)
	Variable m23 = -12.*phi*exp(-Z1)*(-1. - Z1 + exp(Z1))*pow(Z1,-1)
	Variable m24 = -12.*phi*exp(-Z2)*(-1. - Z2 + exp(Z2))*pow(Z2,-1)
	Variable m31 = -6.*phi*exp(-Z1)*pow(Z1,-2)*(2.*(1 + Z1) + exp(Z1)*(-2. + pow(Z1,2)))
	Variable m32 = -12.*phi*(-1. + Z1 + exp(-Z1))*pow(Z1,-1)
	Variable m33 = 6.*phi*exp(-2.*Z1)*pow(-1. + exp(Z1),2)
	Variable m34 = 12.*phi*exp(-Z1 - Z2)*(Z2 - (Z1 + Z2)*exp(Z1) + Z1*exp(Z1 + Z2))*pow(Z1 + Z2,-1)
	Variable m41 = -6.*phi*exp(-Z2)*pow(Z2,-2)*(2.*(1. + Z2) + exp(Z2)*(-2. + pow(Z2,2)))
	Variable m42 = -12.*phi*(-1. + Z2 + exp(-Z2))*pow(Z2,-1)
	Variable m43 = 12.*phi*exp(-Z1 - Z2)*(Z1 - (Z1 + Z2 - Z2*exp(Z1))*exp(Z2))*pow(Z1 + Z2,-1)
	Variable m44 = 6.*phi*exp(-2*Z2)*pow(-1. + exp(Z2),2)
	
//	/* determinant of the linear system expressed as coefficient matrix in d1, d2 */
	
	NVAR TY_q22 = root:yuk:TY_q22
	
	TY_q22 = m14*(-(m33*m42) + m23*(m32*m41 - m31*m42) + m32*m43 + (4.*m11*(-3.*m33*m41 + 2.*m33*m42 + 3.*m31*m43 - 2.*m32*m43))/3.)
	TY_q22 +=  m13*(m34*m42 + m24*(-(m32*m41) + m31*m42) - m32*m44 + (4.*m11*(3.*m34*m41 - 2.*m34*m42 - 3.*m31*m44 + 2.*m32*m44))/3.) 
	TY_q22 += (3.*m24*(m33*(3.*m41 + 4.*m11*m41 - 3.*m11*m42) + (-3.*m31 - 4.*m11*m31 + 3.*m11*m32)*m43) + 3.*m23*(-3.*m34*m41 - 4.*m11*m34*m41 + 3.*m11*m34*m42 + 3.*m31*m44 + 4.*m11*m31*m44 - 3.*m11*m32*m44) - (m34*m43 - m33*m44)*pow(3. - 2.*m11,2))/9.
	
	if( prnt ) 
		printf "\rDet = \r"
//		printf "%f\t%f\r%f\t%f\r", 0., 0., 0., TY_q22 
		printf "TY_q22 = %15.12g\r",TY_q22
	endif
	
//	/* Matrix representation of the determinant of the of the system where row refering to 
//	 the variable a is replaced by solution vector */
	
	NVAR TY_qa12 = root:yuk:TY_qa12
	NVAR TY_qa21 = root:yuk:TY_qa21
	NVAR TY_qa22 = root:yuk:TY_qa22
	NVAR TY_qa23 = root:yuk:TY_qa23
	NVAR TY_qa32 = root:yuk:TY_qa32

	Variable t1,t2,t3,t4,t5,t6,t7,t8,t9,t10
	Variable t11,t12,t13,t14,t15,t16,t17,t18,t19,t20		//simply to keep the line length small enough
	
	TY_qa12 = (K1*(3.*m14*(m23*m42 - 4.*m11*m43) - 3.*m13*(m24*m42 - 4.*m11*m44) + (3. + 4.*m11)*(m24*m43 - m23*m44))*exp(Z1))/3.
	
	TY_qa21 = -(K2*(3.*m14*(m23*m32 - 4.*m11*m33) - 3.*m13*(m24*m32 - 4.*m11*m34) + (3. + 4.*m11)*(m24*m33 - m23*m34))*exp(Z2))/3.
	
	TY_qa22 = m14*(-(m23*m42*Z1) + 4.*m11*m43*Z1 - m33*(m42 + 4.*m11*Z2) + m32*(m43 + m23*Z2)) + (3.*m13*(m24*m42*Z1 - 4.*m11*m44*Z1 + m34*(m42 + 4.*m11*Z2) - m32*(m44 + m24*Z2)) + (3. + 4.*m11)*(-(m24*m43*Z1) + m23*m44*Z1 - m34*(m43 + m23*Z2) + m33*(m44 + m24*Z2)))/3.
	

	t1 = (2.*(-3.*m13*m42 + 3.*m43 + 4.*m11*m43)*Z1*pow(Z2,2) - m33*(Z1 + Z2)*(6.*m42 + (3. + 4.*m11)*pow(Z2,2)) +  3.*m32*(Z1 + Z2)*(2.*m43 + m13*pow(Z2,2)))
	t2 = (2.*(3.*m14*m42 - 3.*m44 - 4.*m11*m44)*Z1*pow(Z2,2) + m34*(Z1 + Z2)*(6.*m42 + (3. + 4.*m11)*pow(Z2,2)) - 3.*m32*(Z1 + Z2)*(2.*m44 + m14*pow(Z2,2)))
	t3 = (3.*(m14*m33*m42 - m13*m34*m42 - m14*m32*m43 + m34*m43 + m13*m32*m44 - m33*m44)*Z2*(Z1 + Z2) +  2.*m11*(6.*(-(m14*m43) + m13*m44)*Z1*pow(Z2,2) + m34*(Z1 + Z2)*(2.*m43*(-3. + Z2) - 3.*m13*pow(Z2,2)) +  m33*(Z1 + Z2)*(6.*m44 - 2.*m44*Z2 + 3.*m14*pow(Z2,2))))
		  
	TY_qa23 = 2.*phi*pow(Z2,-2)*(m24*t1 + m23*t2 + 2.*t3)*pow(Z1 + Z2,-1)	
	
	
	
	t1 = ((-3.*m13*m42 + (3. + 4.*m11)*m43)*(Z1 + Z2)*pow(Z1,2) - 2.*m33*(3.*m42*(Z1 + Z2) + (3. + 4.*m11)*Z2*pow(Z1,2)) + 6.*m32*(m43*(Z1 + Z2) + m13*Z2*pow(Z1,2)))
	t2 = ((3.*m14*m42 - (3. + 4.*m11)*m44)*(Z1 + Z2)*pow(Z1,2) + m34*(6.*m42*(Z1 + Z2) + 2.*(3. + 4.*m11)*Z2*pow(Z1,2)) - 6.*m32*(m44*(Z1 + Z2) + m14*Z2*pow(Z1,2)))
	t3 = (3.*(m14*m33*m42 - m13*m34*m42 - m14*m32*m43 + m34*m43 + m13*m32*m44 - m33*m44)*Z1*(Z1 + Z2) + 2.*m11*(-3.*(m14*m43 - m13*m44)*(Z1 + Z2)*pow(Z1,2) + 2.*m34*(m43*(-3 + Z1)*(Z1 + Z2) - 3.*m13*Z2*pow(Z1,2)) + m33*(-2.*m44*(-3. + Z1)*(Z1 + Z2) + 6.*m14*Z2*pow(Z1,2))))
	
	TY_qa32 = 2.*phi*pow(Z1,-2)*(m24*t1 + m23*t2 + 2.*t3)*pow(Z1 + Z2,-1)
		
	if( prnt ) 
		printf "\rDet_a = \r"
//		printf  "%f\t%f\t%f\r%f\t%f\t%f\r%f\t%f\t%f\r", 0., TY_qa12, 0., TY_qa21, TY_qa22, TY_qa23,  0., TY_qa32, 0.
		printf "TY_qa12 = %15.12g\r",TY_qa12
		printf "TY_qa21 = %15.12g\r",TY_qa21
		printf "TY_qa22 = %15.12g\r",TY_qa22
		printf "TY_qa23 = %15.12g\r",TY_qa23
		printf "TY_qa32 = %15.12g\r",TY_qa32
	endif
	
//	/* Matrix representation of the determinant of the of the system where row refering to 
//	 the variable b is replaced by solution vector */

	NVAR TY_qb12 = root:yuk:TY_qb12
	NVAR TY_qb21 = root:yuk:TY_qb21
	NVAR TY_qb22 = root:yuk:TY_qb22
	NVAR TY_qb23 = root:yuk:TY_qb23
	NVAR TY_qb32 = root:yuk:TY_qb32

	TY_qb12 = (K1*(-3.*m11*m24*m43 + m14*(-3.*m23*m41 + (-3. + 8.*m11)*m43) + 3.*m11*m23*m44 + m13*(3.*m24*m41 + 3.*m44 - 8.*m11*m44))*exp(Z1))/3.
	
	TY_qb21 = (K2*(-3.*m13*m24*m31 + 3.*m11*m24*m33 + m14*(3.*m23*m31 + (3. - 8.*m11)*m33) - 3.*m13*m34 + 8.*m11*m13*m34 - 3.*m11*m23*m34)*exp(Z2))/3.
	
	TY_qb22 = m13*(m31*m44 - m24*m41*Z1 - m44*Z1 + (8.*m11*m44*Z1)/3. + m24*m31*Z2 + m34*(-m41 + Z2 - (8.*m11*Z2)/3.)) + m14*(m23*m41*Z1 + m43*Z1 - (8.*m11*m43*Z1)/3. + m33*(m41 - Z2 + (8.*m11*Z2)/3.) - m31*(m43 + m23*Z2)) +  m11*(m24*m43*Z1 - m23*m44*Z1 + m34*(m43 + m23*Z2) - m33*(m44 + m24*Z2))	
	
	t1 = (-(m14*m33*m41) + m13*m34*m41 + m14*m31*m43 - m11*m34*m43 - m13*m31*m44 + m11*m33*m44)
	t2 = (-3.*m11*m24*m43 + m14*(-3.*m23*m41 + (-3. + 8.*m11)*m43) + 3.*m11*m23*m44 + m13*(3.*m24*m41 + 3.*m44 - 8.*m11*m44))
	t3 = (3.*m24*(m33*m41 - m31*m43) + m23*(-3.*m34*m41 + 3.*m31*m44) + (-3. + 8.*m11)*(m34*m43 - m33*m44))
	
	TY_qb23 = 2.*phi*(3.*m14*m23*m31 - 3.*m13*m24*m31 + 3.*m14*m33 - 8.*m11*m14*m33 + 3.*m11*m24*m33 - 3.*m13*m34 + 8.*m11*m13*m34 -  3.*m11*m23*m34 + 2.*t3*  pow(Z2,-2) + 6.*t1*pow(Z2,-1) +  2.*t2*Z1*pow(Z1 + Z2,-1))
	
	
	t1 = (-(m34*(m23*m41 + m43)) + m24*(m33*m41 - m31*m43) + (m23*m31 + m33)*m44)
	t2 = (-(m14*m33*m41) + m13*m34*m41 + m14*m31*m43 - m13*m31*m44)
	t3 = (m14*(2.*m23*m31 + 2.*m33 - m23*m41 - m43) + m13*(-2.*m34 + m24*(-2.*m31 + m41) + m44))
	t4 = (16.*m34*m43 - 16.*m33*m44 - 6.*m34*m43*Z1 + 6.*m33*m44*Z1 + (6.*m24*m33 - 3.*m24*m43 + 8.*m14*(-2.*m33 + m43) + (8.*m13 - 3.*m23)*(2.*m34 - m44))*pow(Z1,2))
	t5 = (2.*m34*m43*(8. - 3.*Z1) + 2.*m33*m44*(-8. + 3.*Z1) + (8.*m14*m43 - 3.*m24*m43 - 8.*m13*m44 + 3.*m23*m44)*pow(Z1,2))
	
	TY_qb32 = 2.*phi*pow(Z1,-2)*(6.*t1 +  6.*t2*Z1 +  3.*t3*pow(Z1,2) + (m11*Z2*t4 + m11*Z1*t5)* pow(Z1 + Z2,-1) + 6.*(-(m14*(m23*m31 + m33)) + m13*(m24*m31 + m34))*pow(Z1,3)*pow(Z1 + Z2,-1))
		
		
	if( prnt ) 
		printf "\rDet_b = \r"
//		printf "%f\t%f\t%f\r%f\t%f\t%f\r%f\t%f\t%f\r", 0., TY_qb12, 0., TY_qb21, TY_qb22, TY_qb23, 0., TY_qb32, 0.
		printf "TY_qb12 = %15.12g\r",TY_qb12
		printf "TY_qb21 = %15.12g\r",TY_qb21
		printf "TY_qb22 = %15.12g\r",TY_qb22
		printf "TY_qb23 = %15.12g\r",TY_qb23
		printf "TY_qb32 = %15.12g\r",TY_qb32
	endif
	
//	/* Matrix representation of the determinant of the of the system where row refering to 
//	 the variable c1 is replaced by solution vector */
	NVAR TY_qc112 = root:yuk:TY_qc112
	NVAR TY_qc121 = root:yuk:TY_qc121
	NVAR TY_qc122 = root:yuk:TY_qc122
	NVAR TY_qc123 = root:yuk:TY_qc123
	NVAR TY_qc132 = root:yuk:TY_qc132

	TY_qc112 = -(K1*exp(Z1)*(9.*m24*m41 - 9.*m14*m42 + 3.*m11*(-12.*m14*m41 + 4.*m24*m41 + 8.*m14*m42 - 3.*m24*m42) + m44*pow(3. - 2.*m11,2)))/9.
	
	TY_qc121 = (K2*exp(Z2)*(9.*m24*m31 - 9.*m14*m32 + 3.*m11*(-12.*m14*m31 + 4.*m24*m31 + 8.*m14*m32 - 3.*m24*m32) + m34*pow(3. - 2.*m11,2)))/9.
	
	TY_qc122 = m14*(-4.*m11*m41*Z1 - m42*Z1 + (8.*m11*m42*Z1)/3. + m32*(-m41 + Z2 - (8.*m11*Z2)/3.) + m31*(m42 + 4.*m11*Z2)) + (3.*m34*((3. + 4.*m11)*m41 - 3.*m11*m42) + 9.*m11*m32*m44 + 9.*m24*m41*Z1 + 12.*m11*m24*m41*Z1 - 9.*m11*m24*m42*Z1 + 9.*m44*Z1 - 12.*m11*m44*Z1 + 9.*m11*m24*m32*Z2 - 3.*(3. + 4.*m11)*m31*(m44 + m24*Z2) - m34*Z2*pow(3. - 2.*m11,2) + 4.*m44*Z1*pow(m11,2))/9.
	
	
	t1 = (m34*(Z1 + Z2)*(2.*m42 + Z2*(-2.*m41 + Z2)) - m32*(Z1 + Z2)*(2.*m44 + m14*Z2*(-2.*m41 + Z2)) - 2.*(m14*m42 - m44)*Z2*(-(Z1*Z2) + m31*(Z1 + Z2)))
	t2 = (2.*(3.*m41 + 4.*m11*m41 - 3.*m11*m42)*Z1*pow(Z2,2) + 3.*m32*(Z1 + Z2)*(2.*m41 + m11*pow(Z2,2)) - m31*(Z1 + Z2)*(6.*m42 + (3. + 4.*m11)*pow(Z2,2)))
	t3 = (8.*m42 + 4.*m41*(-3. + Z2) - 3.*m42*Z2 + 2.*pow(Z2,2))
	t4 = (6.*m44 - 2.*m44*Z2 + 3.*m14*pow(Z2,2))
	t5 = (-8.*m32*m44*Z1 + m32*m44*(-8. + 3.*Z1)*Z2 + (3.*m32*m44 - 4.*(m14*(m32 + 3.*m41 - 2.*m42) + m44)*Z1)*pow(Z2,2) + 	m34*(Z1 + Z2)*t3 + 2.*m31*(Z1 + Z2)*t4 - 4.*m14*m32*pow(Z2,3))
			
	TY_qc123 = (2.*phi*pow(Z2,-2)*(9.*t1 + 4.*(-2.*m44*Z1 + m34*(Z1 + Z2))*pow(m11,2)*pow(Z2,2) - 3.*m24*t2 - 6.*m11*t5)*pow(Z1 + Z2,-1))/3.
	
	
	t1 = ((m14*m42 - m44)*(2.*m31 - Z1)*Z1*(Z1 + Z2) - 2.*m34*(m42*(Z1 + Z2) - Z1*(-(Z1*Z2) + m41*(Z1 + Z2))) + 2.*m32*(m44*(Z1 + Z2) - m14*Z1*(-(Z1*Z2) + m41*(Z1 + Z2))))
	t2 = (((3. + 4.*m11)*m41 - 3.*m11*m42)*(Z1 + Z2)*pow(Z1,2) + 6.*m32*(m41*(Z1 + Z2) + m11*Z2*pow(Z1,2)) - 2.*m31*(3.*m42*(Z1 + Z2) + (3. + 4.*m11)*Z2*pow(Z1,2)))
	t3 = (-8.*m32*m44 + m34*(m42*(8. - 3.*Z1) + 4.*m41*(-3. + Z1)) - 4.*m31*m44*(-3. + Z1) + 3.*m32*m44*Z1 - 2.*(3.*m14*m41 - 2.*m14*m42 + m44)*pow(Z1,2))
	t4 = (4.*(3.*m31 - 2.*m32)*m44 + Z1*(-4.*m31*m44 + 3.*m32*m44 - 2.*(m14*(-6.*m31 + 4.*m32 + 3.*m41 - 2.*m42) + m44)*Z1) + m34*(m42*(8. - 3.*Z1) + 4.*m41*(-3. + Z1) + 4.*pow(Z1,2)))
	
	TY_qc132 = (-2.*phi*pow(Z1,-2)*(9.*t1 + 4.*(-2.*m34*Z2 + m44*(Z1 + Z2))*pow(m11,2)*pow(Z1,2) + 	3.*m24*t2 + 6.*m11*(Z1*t3 + Z2*t4))*pow(Z1 + Z2,-1))/3.
		
		
	if( prnt ) 
		printf "\rDet_c1 = \r"
//		printf "%f\t%f\t%f\r%f\t%f\t%f\r%f\t%f\t%f\r", 0., TY_qc112, 0., TY_qc121, TY_qc122, TY_qc123, 0., TY_qc132, 0.
		printf "TY_qc112 = %15.12g\r",TY_qc112
		printf "TY_qc121 = %15.12g\r",TY_qc121
		printf "TY_qc122 = %15.12g\r",TY_qc122
		printf "TY_qc123 = %15.12g\r",TY_qc123
		printf "TY_qc132 = %15.12g\r",TY_qc132
	endif
	
//	/* Matrix representation of the determinant of the of the system where row refering to 
//	 the variable c1 is replaced by solution vector */
	NVAR TY_qc212 = root:yuk:TY_qc212
	NVAR TY_qc221 = root:yuk:TY_qc221
	NVAR TY_qc222 = root:yuk:TY_qc222
	NVAR TY_qc223 = root:yuk:TY_qc223
	NVAR TY_qc232 = root:yuk:TY_qc232

	TY_qc212 = (K1*exp(Z1)*(9*m23*m41 - 9*m13*m42 + 3*m11*(-12*m13*m41 + 4*m23*m41 + 8*m13*m42 - 3*m23*m42) + m43*pow(3 - 2*m11,2)))/9.
	
	TY_qc221 = -(K2*exp(Z2)*(9*m23*m31 - 9*m13*m32 + 3*m11*(-12*m13*m31 + 4*m23*m31 + 8*m13*m32 - 3*m23*m32) + m33*pow(3 - 2*m11,2)))/9.
	
	TY_qc222 = m13*(4*m11*m41*Z1 + m42*Z1 - (8*m11*m42*Z1)/3. + m32*(m41 - Z2 + (8*m11*Z2)/3.) - m31*(m42 + 4*m11*Z2)) + (9*m31*m43 - 9*(m23*m41 + m43)*Z1 + 9*m23*m31*Z2 + 3*m11*((-4*m23*m41 + 3*m23*m42 + 4*m43)*Z1 + 4*m31*(m43 + m23*Z2) - 3*m32*(m43 + m23*Z2)) + m33*(-3*(3 + 4*m11)*m41 + 9*m11*m42 + Z2*pow(3 - 2*m11,2)) - 4*m43*Z1*pow(m11,2))/9.
	
			
	t1 = (-(m33*(Z1 + Z2)*(2*m42 + Z2*(-2*m41 + Z2))) + m32*(Z1 + Z2)*(2*m43 + m13*Z2*(-2*m41 + Z2)) + 2*(m13*m42 - m43)*Z2*(-(Z1*Z2) + m31*(Z1 + Z2)))
	t2 = (2*(3*m41 + 4*m11*m41 - 3*m11*m42)*Z1*pow(Z2,2) + 3*m32*(Z1 + Z2)*(2*m41 + m11*pow(Z2,2)) - m31*(Z1 + Z2)*(6*m42 + (3 + 4*m11)*pow(Z2,2)))
	t3 = (-8*m32*m43*Z1 + m32*m43*(-8 + 3*Z1)*Z2 + (3*m32*m43 - 4*(m13*(m32 + 3*m41 - 2*m42) + m43)*Z1)*pow(Z2,2) + m33*(Z1 + Z2)*(8*m42 + 4*m41*(-3 + Z2) - 3*m42*Z2 + 2*pow(Z2,2)) + 2*m31*(Z1 + Z2)*(6*m43 - 2*m43*Z2 + 3*m13*pow(Z2,2)) - 4*m13*m32*pow(Z2,3))
	
	TY_qc223 = (2*phi*pow(Z2,-2)*(9*t1 - 4*(-2*m43*Z1 + m33*(Z1 + Z2))*pow(m11,2)*pow(Z2,2) + 3*m23*t2 + 6*m11*t3)*pow(Z1 + Z2,-1))/3.
	
	
	t1 = ((m13*m42 - m43)*(2*m31 - Z1)*Z1*(Z1 + Z2) - 2*m33*(m42*(Z1 + Z2) - Z1*(-(Z1*Z2) + m41*(Z1 + Z2))) + 	2*m32*(m43*(Z1 + Z2) - m13*Z1*(-(Z1*Z2) + m41*(Z1 + Z2))))
	t2 = (((3 + 4*m11)*m41 - 3*m11*m42)*(Z1 + Z2)*pow(Z1,2) + 6*m32*(m41*(Z1 + Z2) + m11*Z2*pow(Z1,2)) - 	2*m31*(3*m42*(Z1 + Z2) + (3 + 4*m11)*Z2*pow(Z1,2)))
	t3 = (-8*m32*m43 + m33*(m42*(8 - 3*Z1) + 4*m41*(-3 + Z1)) - 4*m31*m43*(-3 + Z1) + 3*m32*m43*Z1 - 2*(3*m13*m41 - 2*m13*m42 + m43)*pow(Z1,2))
	t4 = (4*(3*m31 - 2*m32)*m43 + Z1*(-4*m31*m43 + 3*m32*m43 - 2*(m13*(-6*m31 + 4*m32 + 3*m41 - 2*m42) + m43)*Z1) +	m33*(m42*(8 - 3*Z1) + 4*m41*(-3 + Z1) + 4*pow(Z1,2)))
	
	TY_qc232 = (2*phi*pow(Z1,-2)*(9*t1 + 4*(-2*m33*Z2 + m43*(Z1 + Z2))*pow(m11,2)*pow(Z1,2) + 3*m23*t2 + 6*m11*(Z1*t3 + Z2*t4))*pow(Z1 + Z2,-1))/3.
		
		
	if( prnt ) 
		printf "\rDet_c2 = \r"
//		printf "%f\t%f\t%f\r%f\t%f\t%f\r%f\t%f\t%f\r",  0., TY_qc212, 0.,  TY_qc221, TY_qc222, TY_qc223,  0., TY_qc232, 0.
		printf "TY_qc212 = %15.12g\r",TY_qc212
		printf "TY_qc221 = %15.12g\r",TY_qc221
		printf "TY_qc222 = %15.12g\r",TY_qc222
		printf "TY_qc223 = %15.12g\r",TY_qc223
		printf "TY_qc232 = %15.12g\r",TY_qc232
	endif
	
//	/* coefficient matrices of nonlinear equation 1 */
	NVAR TY_A12 = root:yuk:TY_A12
	NVAR TY_A21 = root:yuk:TY_A21
	NVAR TY_A22 = root:yuk:TY_A22
	NVAR TY_A23 = root:yuk:TY_A23
	NVAR TY_A32 = root:yuk:TY_A32
	NVAR TY_A41 = root:yuk:TY_A41
	NVAR TY_A42 = root:yuk:TY_A42
	NVAR TY_A43 = root:yuk:TY_A43
	NVAR TY_A52 = root:yuk:TY_A52
	
	t1 = (Z1*(2*TY_qb12*(-1 + Z1)*(Z1 + Z2) - Z1*(2*TY_qc212*Z1 + TY_qc112*(Z1 + Z2))) + TY_qa12*(Z1 + Z2)*(-2 + pow(Z1,2)))
	t2 = (exp(2*Z1)*t1 - TY_qc112*(Z1 + Z2)*pow(Z1,2) + 2*(Z1 + Z2)*exp(Z1)*(TY_qa12 + (TY_qa12 + TY_qb12)*Z1 + TY_qc112*pow(Z1,2)))
		  
	TY_A12 = 6*phi*TY_qc112*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*TY_qc212*exp(Z1)*(-Z2 + (Z1 + Z2)*exp(Z1))*pow(Z1,2) + exp(Z2)*t2)*pow(Z1 + Z2,-1)
	
	
	t1 = (2*Z1*(TY_qb21*TY_qc112*(-1 + Z1)*(Z1 + Z2) + TY_qb12*TY_qc121*(-1 + Z1)*(Z1 + Z2) -  Z1*(TY_qc121*TY_qc212*Z1 + TY_qc112*(TY_qc121 + TY_qc221)*Z1 + TY_qc112*TY_qc121*Z2)) + TY_qa21*TY_qc112*(Z1 + Z2)*(-2 + pow(Z1,2)) + TY_qa12*TY_qc121*(Z1 + Z2)*(-2 + pow(Z1,2)))
	t2 = (TY_qb21*TY_qc112 + TY_qc121*(TY_qa12 + TY_qb12 + 2*TY_qc112*Z1))
	t3 = (2*(TY_qa12*TY_qc121 + TY_qa21*TY_qc112*(1 + Z1) + Z1*t2)*(Z1 + Z2)*exp(Z1) + exp(2*Z1)*t1 - 2*TY_qc112*TY_qc121*(Z1 + Z2)*pow(Z1,2))
		  
	TY_A21 = 6*phi*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*(TY_qc121*TY_qc212 + TY_qc112*TY_qc221)*exp(Z1)*(-Z2 + (Z1 + Z2)*exp(Z1))*pow(Z1,2) +  exp(Z2)*t3)*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qb22*TY_qc112 + TY_qc122*(TY_qa12 + TY_qb12 + 2*TY_qc112*Z1))
	t2 = (2*Z1*(TY_qb22*TY_qc112*(-1 + Z1)*(Z1 + Z2) + TY_qb12*TY_qc122*(-1 + Z1)*(Z1 + Z2) - Z1*(TY_qc122*TY_qc212*Z1 + TY_qc112*(TY_qc122 + TY_qc222)*Z1 + TY_qc112*TY_qc122*Z2)) + TY_qa22*TY_qc112*(Z1 + Z2)*(-2 + pow(Z1,2)) + TY_qa12*TY_qc122*(Z1 + Z2)*(-2 + pow(Z1,2)))
	t3 = (12*phi*(TY_qa12*TY_qc122 + TY_qa22*TY_qc112*(1 + Z1) + Z1*t1)*(Z1 + Z2)*exp(Z1) - 2*phi*TY_qc112*TY_qc122*(Z1 + Z2)*pow(Z1,2) + exp(2*Z1)*(6*phi*t2 + TY_q22*TY_qc112*(Z1 + Z2)*pow(Z1,3)))
		  
	TY_A22 = exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(12*phi*(TY_qc122*TY_qc212 + TY_qc112*TY_qc222)*exp(Z1)*(-Z2 + (Z1 + Z2)*exp(Z1))*pow(Z1,2) +  exp(Z2)*t3)*pow(Z1 + Z2,-1)
	
	
	t1 = ((TY_q22*TY_qc112 + TY_qc123*(TY_qc112 + TY_qc212) + TY_qc112*TY_qc223)*Z1 + TY_qc112*TY_qc123*Z2)
	t2 = (TY_qa12*TY_qc123 + TY_qa23*TY_qc112*(1 + Z1) + Z1*(TY_qb23*TY_qc112 + TY_qc123*(TY_qa12 + TY_qb12 + 2*TY_qc112*Z1)))
	t3 = (2*Z1*(TY_qb23*TY_qc112*(-1 + Z1)*(Z1 + Z2) + TY_qb12*TY_qc123*(-1 + Z1)*(Z1 + Z2) - Z1*t1) + TY_qa23*TY_qc112*(Z1 + Z2)*(-2 + pow(Z1,2)) +  TY_qa12*TY_qc123*(Z1 + Z2)*(-2 + pow(Z1,2)))
	
	TY_A23 = 6*phi*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*(TY_qc123*TY_qc212 + TY_qc112*TY_qc223)*exp(Z1)*(-Z2 + (Z1 + Z2)*exp(Z1))*pow(Z1,2) + exp(Z2)*(2*t2*(Z1 + Z2)*exp(Z1) +  exp(2*Z1)*t3 - 2*TY_qc112*TY_qc123*(Z1 + Z2)*pow(Z1,2)))*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qb32*TY_qc112 + (TY_qa23 + TY_qb23)*TY_qc121 + (TY_qa21 + TY_qb21)*TY_qc123 + (TY_qa12 + TY_qb12)*TY_qc132 + TY_q22*TY_qc112*Z1 +  2*(TY_qc121*TY_qc123 + TY_qc112*TY_qc132)*Z1 + TY_qc122*(TY_qa22 + TY_qb22 + TY_qc122*Z1))
	t2 = (TY_qc132*TY_qc212 + TY_qc123*TY_qc221 + TY_qc122*TY_qc222 + TY_qc121*TY_qc223 + TY_qc112*TY_qc232)
	t3 = ((TY_q22 + TY_qc132)*TY_qc212 + TY_qc123*TY_qc221 + TY_qc122*TY_qc222 + TY_qc121*TY_qc223 + TY_qc112*TY_qc232)
	t4 = (2*TY_qc121*TY_qc123 + 2*TY_qc112*TY_qc132 + pow(TY_qc122,2))
	t5 = (6*phi*(2*Z1*(TY_qb12*(-1 + Z1)*(Z1 + Z2) - Z1*((TY_qc112 + TY_qc121 + TY_qc212)*Z1 + TY_qc112*Z2)) +  TY_qa12*(Z1 + Z2)*(-2 + pow(Z1,2))) + TY_qc122*(Z1 + Z2)*pow(Z1,3))
	t6 = (-2*(TY_qa22*TY_qc122 + TY_qa21*TY_qc123 + TY_qa12*TY_qc132) - 2*(TY_qb32*TY_qc112 + TY_qb23*TY_qc121 + TY_qb22*TY_qc122 + TY_qb21*TY_qc123 + TY_qb12*TY_qc132)*Z1 +  (2*TY_qb32*TY_qc112 + 2*TY_qb23*TY_qc121 + (TY_qa22 + 2*TY_qb22 - TY_qc122)*TY_qc122 + (TY_qa21 + 2*TY_qb21 - 2*TY_qc121)*TY_qc123 + (TY_qa12 + 2*TY_qb12 - 2*TY_qc112)*TY_qc132)*pow(Z1,2))
	t7 = -2*TY_qa22*TY_qc122*Z1 - 2*TY_qa21*TY_qc123*Z1 - 2*TY_qa12*TY_qc132*Z1 + TY_qa32*TY_qc112*(Z1 + Z2)*(-2 + pow(Z1,2)) + TY_qa23*TY_qc121*(Z1 + Z2)*(-2 + pow(Z1,2)) - 2*TY_qb32*TY_qc112*pow(Z1,2) - 2*TY_qb23*TY_qc121*pow(Z1,2) - 2*TY_qb22*TY_qc122*pow(Z1,2) - 2*TY_qb21*TY_qc123*pow(Z1,2) - 2*TY_qb12*TY_qc132*pow(Z1,2)
	t8 = Z2*t6 + 2*TY_qb32*TY_qc112*pow(Z1,3) + 2*TY_qb23*TY_qc121*pow(Z1,3) + TY_qa22*TY_qc122*pow(Z1,3) + 2*TY_qb22*TY_qc122*pow(Z1,3) + TY_qa21*TY_qc123*pow(Z1,3) + 2*TY_qb21*TY_qc123*pow(Z1,3) - 2*TY_qc121*TY_qc123*pow(Z1,3) + TY_qa12*TY_qc132*pow(Z1,3)
	t9 = (t7 + t8 + 2*TY_qb12*TY_qc132*pow(Z1,3) - 2*TY_qc112*TY_qc132*pow(Z1,3) - 2*TY_qc132*TY_qc212*pow(Z1,3) - 2*TY_qc123*TY_qc221*pow(Z1,3) - 2*TY_qc122*TY_qc222*pow(Z1,3) - 2*TY_qc121*TY_qc223*pow(Z1,3) - 2*TY_qc112*TY_qc232*pow(Z1,3) - pow(TY_qc122,2)*pow(Z1,3))
	t10 = (12*phi*(TY_qa23*TY_qc121 + TY_qa22*TY_qc122 + TY_qa21*TY_qc123 + TY_qa12*TY_qc132 + TY_qa32*TY_qc112*(1 + Z1) + Z1*t1)*(Z1 + Z2)*exp(Z1 + Z2) - 12*phi*t2*Z2*exp(Z1)*pow(Z1,2) + 12*phi*t3*(Z1 + Z2)*exp(2*Z1)*pow(Z1,2) - 6*phi*(Z1 + Z2)*exp(Z2)*t4*pow(Z1,2) + exp(2*Z1 + Z2)*(TY_q22*t5 + 6*phi*t9))  
		  
	TY_A32 = exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*t10*pow(Z1 + Z2,-1)
	
	
	t1 = ((-(TY_qc132*TY_qc221) - TY_qc121*TY_qc232)*Z2 + ((TY_q22 + TY_qc132)*TY_qc221 + TY_qc121*TY_qc232)*(Z1 + Z2)*exp(Z1))
	t2 = (TY_qa21*TY_qc132 + TY_qa32*TY_qc121*(1 + Z1) + Z1*(TY_qb32*TY_qc121 + (TY_qa21 + TY_qb21)*TY_qc132 + TY_qc121*(TY_q22 + 2*TY_qc132)*Z1))
	t3 = (-2*(TY_qa32*TY_qc121 + TY_qa21*(TY_q22 + TY_qc132)) - 2*(TY_qb32*TY_qc121 + TY_qb21*(TY_q22 + TY_qc132))*Z1 + (TY_q22*(TY_qa21 + 2*TY_qb21 - 2*TY_qc121) + TY_qc121*(TY_qa32 + 2*TY_qb32 - 2*TY_qc132) + (TY_qa21 + 2*TY_qb21)*TY_qc132)*pow(Z1,2))
	t4 = (-2*(TY_qa32*TY_qc121 + TY_qa21*(TY_q22 + TY_qc132)) - 2*(TY_qb32*TY_qc121 + TY_qb21*(TY_q22 + TY_qc132))*Z1 + (TY_qa32*TY_qc121 + 2*TY_qb32*TY_qc121 + TY_qa21*TY_qc132 + 2*TY_qb21*TY_qc132 - 2*TY_qc121*TY_qc132 + TY_q22*(TY_qa21 + 2*TY_qb21 - 2*TY_qc121 - 2*TY_qc221) - 2*TY_qc132*TY_qc221 - 2*TY_qc121*TY_qc232)*pow(Z1,2))
	
	TY_A41 = 6*phi*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*exp(Z1)*t1*pow(Z1,2) + exp(Z2)*(2*t2*(Z1 + Z2)*exp(Z1) - 2*TY_qc121*TY_qc132*(Z1 + Z2)*pow(Z1,2) + exp(2*Z1)*(Z2*t3 + Z1*t4)))*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qb32*TY_qc122 + (TY_qa22 + TY_qb22)*TY_qc132 + TY_qc122*(TY_q22 + 2*TY_qc132)*Z1)
	t2 = (TY_qc132*TY_qc222 + TY_qc122*TY_qc232)
	t3 = ((TY_q22 + TY_qc132)*TY_qc222 + TY_qc122*TY_qc232)
	t4 = (2*Z1*(TY_qb32*TY_qc122*(-1 + Z1)*(Z1 + Z2) + TY_qb22*TY_qc132*(-1 + Z1)*(Z1 + Z2) - Z1*(TY_qc132*TY_qc222*Z1 + TY_qc122*(TY_qc132 + TY_qc232)*Z1 + TY_qc122*TY_qc132*Z2)) + TY_qa32*TY_qc122*(Z1 + Z2)*(-2 + pow(Z1,2)) + TY_qa22*TY_qc132*(Z1 + Z2)*(-2 + pow(Z1,2)))
	t5 = (6*phi*t4 + (Z1 + Z2)*pow(TY_q22,2)*pow(Z1,3) + TY_q22*(6*phi*(2*Z1*(TY_qb22*(-1 + Z1)*(Z1 + Z2) - Z1*((TY_qc122 + TY_qc222)*Z1 + TY_qc122*Z2)) + TY_qa22*(Z1 + Z2)*(-2 + pow(Z1,2))) + TY_qc132*(Z1 + Z2)*pow(Z1,3)))
	t6 = (12*phi*(TY_qa22*TY_qc132 + TY_qa32*TY_qc122*(1 + Z1) + Z1*t1)*(Z1 + Z2)*exp(Z1 + Z2) - 12*phi*t2*Z2*exp(Z1)*pow(Z1,2) + 12*phi*t3*(Z1 + Z2)*exp(2*Z1)*pow(Z1,2) - 12*phi*TY_qc122*TY_qc132*(Z1 + Z2)*exp(Z2)*pow(Z1,2) + exp(2*Z1 + Z2)*t5)
		
	TY_A42 = exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*t6*pow(Z1 + Z2,-1)
	
	
	t1 = ((TY_qc132*TY_qc223 + TY_qc123*TY_qc232)*Z2 - ((TY_q22 + TY_qc132)*TY_qc223 + TY_qc123*TY_qc232)*(Z1 + Z2)*exp(Z1))
	t2 = (TY_qa23*TY_qc132 + TY_qa32*TY_qc123*(1 + Z1) + Z1*(TY_qb32*TY_qc123 + (TY_qa23 + TY_qb23)*TY_qc132 + TY_qc123*(TY_q22 + 2*TY_qc132)*Z1))
	t3 = (2*TY_qa32*TY_qc123 + 2*TY_qa23*(TY_q22 + TY_qc132) + 2*(TY_qb32*TY_qc123 + TY_qb23*(TY_q22 + TY_qc132))*Z1 - (TY_q22*(TY_qa23 + 2*TY_qb23 - 2*TY_qc123) + TY_qc123*(TY_qa32 + 2*TY_qb32 - 2*TY_qc132) + (TY_qa23 + 2*TY_qb23)*TY_qc132)*pow(Z1,2))
	t4 = (2*TY_qa32*TY_qc123 + 2*TY_qa23*(TY_q22 + TY_qc132) + 2*(TY_qb32*TY_qc123 + TY_qb23*(TY_q22 + TY_qc132))*Z1 + (-(TY_qa32*TY_qc123) - (TY_qa23 + 2*TY_qb23)*TY_qc132 + TY_q22*(-TY_qa23 + 2*(-TY_qb23 + TY_qc123 + TY_qc132 + TY_qc223)) + 2*(-(TY_qb32*TY_qc123) + TY_qc132*(TY_qc123 + TY_qc223) + TY_qc123*TY_qc232) + 2*pow(TY_q22,2))*pow(Z1,2))
	
	TY_A43 = -6*phi*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*exp(Z1)*t1*pow(Z1,2) + exp(Z2)*(-2*t2*(Z1 + Z2)*exp(Z1) + 2*TY_qc123*TY_qc132*(Z1 + Z2)*pow(Z1,2) + exp(2*Z1)*(Z2*t3 + Z1*t4)))*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qc132*Z2 - (TY_q22 + TY_qc132)*(Z1 + Z2)*exp(Z1))
	t2 = (Z1*(-2*TY_qb32*(-1 + Z1)*(Z1 + Z2) + Z1*((TY_q22 + TY_qc132 + 2*TY_qc232)*Z1 + (TY_q22 + TY_qc132)*Z2)) -  TY_qa32*(Z1 + Z2)*(-2 + pow(Z1,2)))
	t3 = ((TY_q22 + TY_qc132)*exp(2*Z1)*t2 + (Z1 + Z2)*pow(TY_qc132,2)*pow(Z1,2) - 2*TY_qc132*(Z1 + Z2)*exp(Z1)*(TY_qa32 + (TY_qa32 + TY_qb32)*Z1 + (TY_q22 + TY_qc132)*pow(Z1,2)))
	
	TY_A52 = -6*phi*exp(-2*Z1 - Z2)*pow(TY_q22,-2)*pow(Z1,-3)*(2*TY_qc232*exp(Z1)*t1*pow(Z1,2) + exp(Z2)*t3)*pow(Z1 + Z2,-1)
	
	
	// normalize A
//	/*double norm_A = sqrt(pow(TY_A52,2)+pow(TY_A43,2)+pow(TY_A42, 2)+pow(TY_A41, 2)+pow(TY_A32, 2)+
//						 pow(TY_A23,2)+pow(TY_A22,2)+pow(TY_A21, 2)+pow(TY_A12, 2));
//	TY_A12 /= norm_A;
//	TY_A21 /= norm_A;
//	TY_A22 /= norm_A;
//	TY_A23 /= norm_A;
//	TY_A32 /= norm_A;
//	TY_A41 /= norm_A;
//	TY_A42 /= norm_A;
//	TY_A43 /= norm_A;
//	TY_A52 /= norm_A;*/
	
	if( prnt ) 
		printf "\rNonlinear equation 1 = \r"
//		printf "%f\t\t%f\t\t%f\r", 0.,   TY_A12, 0. 
//		printf "%f\t\t%f\t\t%f\r", TY_A21, TY_A22, TY_A23
//		printf "%f\t\t%f\t\t%f\r",  0.,  TY_A32, 0. 
//		printf "%f\t\t%f\t\t%f\r", TY_A41, TY_A42, TY_A43
//		printf "%f\t\t%f\t\t%f\r", 0.,   TY_A52, 0.		
		printf "TY_A12 = %15.12g\r",TY_A12
		printf "TY_A21 = %15.12g\r",TY_A21
		printf "TY_A22 = %15.12g\r",TY_A22
		printf "TY_A23 = %15.12g\r",TY_A23
		printf "TY_A32 = %15.12g\r",TY_A32
		printf "TY_A41 = %15.12g\r",TY_A41
		printf "TY_A42 = %15.12g\r",TY_A42
		printf "TY_A43 = %15.12g\r",TY_A43
		printf "TY_A52 = %15.12g\r",TY_A52
	endif
	
//	/* coefficient matrices of nonlinear equation 2 */
	NVAR TY_B12 = root:yuk:TY_B12
	NVAR TY_B14 = root:yuk:TY_B14
	NVAR TY_B21 = root:yuk:TY_B21
	NVAR TY_B22 = root:yuk:TY_B22
	NVAR TY_B23 = root:yuk:TY_B23
	NVAR TY_B24 = root:yuk:TY_B24
	NVAR TY_B25 = root:yuk:TY_B25
	NVAR TY_B32 = root:yuk:TY_B32
	NVAR TY_B34 = root:yuk:TY_B34
	
	
	
	t1 = (TY_qa12*TY_qc221 + TY_qa21*TY_qc212*(1 + Z2) + Z2*(TY_qb21*TY_qc212 + TY_qc221*(TY_qa12 + TY_qb12 + 2*TY_qc212*Z2)))
	t2 = (-(TY_qc121*TY_qc212) - TY_qc112*TY_qc221)
	t3 = (TY_qb21*TY_qc212*(-1 + Z2)*(Z1 + Z2) + TY_qb12*TY_qc221*(-1 + Z2)*(Z1 + Z2) - Z2*(TY_qc212*TY_qc221*Z1 + TY_qc112*TY_qc221*Z2 + TY_qc212*(TY_qc121 + TY_qc221)*Z2))
	t4 = (exp(Z1)*(2*Z2*t3 + TY_qa21*TY_qc212*(Z1 + Z2)*(-2 + pow(Z2,2)) + TY_qa12*TY_qc221*(Z1 + Z2)*(-2 + pow(Z2,2))) + 2*(TY_qc121*TY_qc212 + TY_qc112*TY_qc221)*(Z1 + Z2)*pow(Z2,2))
	
	TY_B12 = 6*phi*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(-2*TY_qc212*TY_qc221*(Z1 + Z2)*exp(Z1)*pow(Z2,2) + 2*exp(Z2)*((Z1 + Z2)*t1*exp(Z1) + t2*Z1*pow(Z2,2)) + exp(2*Z2)*t4)*pow(Z1 + Z2,-1)
	
	
	
	
	t1 = ((Z1 + Z2)*(TY_qa12*TY_qc223 + TY_qa23*TY_qc212*(1 + Z2) + Z2*(TY_qb23*TY_qc212 + (TY_qa12 + TY_qb12)*TY_qc223 + TY_qc212*(TY_q22 + 2*TY_qc223)*Z2))*exp(Z1) + (-(TY_qc123*TY_qc212) - TY_qc112*TY_qc223)*Z1*pow(Z2,2))
	t2 = (TY_qc123*TY_qc212 + TY_qc112*(TY_q22 + TY_qc223))
	t3 = (TY_qa23*TY_qc212 + TY_qa12*(TY_q22 + TY_qc223))
	t4 = (TY_qa23*TY_qc212 + TY_qa12*(TY_q22 + TY_qc223) + (TY_qb23*TY_qc212 + TY_qb12*(TY_q22 + TY_qc223))*Z1)
	t5 = (-2*(TY_qb23*TY_qc212 + TY_qb12*(TY_q22 + TY_qc223)) + (TY_q22*(TY_qa12 + 2*TY_qb12 - 2*TY_qc212) + TY_qc212*(TY_qa23 + 2*TY_qb23 - 2*TY_qc223) +  (TY_qa12 + 2*TY_qb12)*TY_qc223)*Z1)
	t6 = (TY_q22*(TY_qa12 + 2*TY_qb12 - 2*TY_qc112 - 2*TY_qc212) + TY_qc212*(TY_qa23 + 2*TY_qb23 - 2*TY_qc123 - 2*TY_qc223) + (TY_qa12 + 2*TY_qb12 - 2*TY_qc112)*TY_qc223)
	
	TY_B14 = 6*phi*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(-2*TY_qc212*TY_qc223*(Z1 + Z2)*exp(Z1)*pow(Z2,2) + 2*exp(Z2)*t1 +  exp(2*Z2)*(2*t2*(Z1 + Z2)*pow(Z2,2) + exp(Z1)*(-2*t3*Z1 - 2*t4*Z2 + t5*pow(Z2,2) + t6*pow(Z2,3))))*pow(Z1 + Z2,-1)
	
	
	
	t1 = (TY_qc221*(Z1 + Z2)*exp(Z1)*pow(Z2,2))
	t2 = (exp(Z1)*(Z2*(2*TY_qb21*(-1 + Z2)*(Z1 + Z2) - Z2*(2*TY_qc121*Z2 + TY_qc221*(Z1 + Z2))) + TY_qa21*(Z1 + Z2)*(-2 + pow(Z2,2))) +  2*TY_qc121*(Z1 + Z2)*pow(Z2,2))
	t3 = (-(TY_qc121*Z1*pow(Z2,2)) + (Z1 + Z2)*exp(Z1)*(TY_qa21 + (TY_qa21 + TY_qb21)*Z2 + TY_qc221*pow(Z2,2)))
	
	TY_B21 = 6*phi*TY_qc221*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(-t1 +  exp(2*Z2)*t2 + 2*exp(Z2)*t3)*pow(Z1 + Z2,-1)
	
	
	
	t1 = (TY_qb22*TY_qc221 + TY_qc222*(TY_qa21 + TY_qb21 + 2*TY_qc221*Z2))
	t2 = ((Z1 + Z2)*(TY_qa21*TY_qc222 + TY_qa22*TY_qc221*(1 + Z2) + Z2*t1)*exp(Z1) + (-(TY_qc122*TY_qc221) - TY_qc121*TY_qc222)*Z1*pow(Z2,2))
	t3 = (TY_qc122*TY_qc221 + TY_qc121*TY_qc222)
	t4 = (TY_qb22*TY_qc221*(-1 + Z2)*(Z1 + Z2) + TY_qb21*TY_qc222*(-1 + Z2)*(Z1 + Z2) - Z2*(TY_qc221*TY_qc222*Z1 + TY_qc121*TY_qc222*Z2 + TY_qc221*(TY_qc122 + TY_qc222)*Z2))
	t5 = (6*phi*(2*Z2*t4 + TY_qa22*TY_qc221*(Z1 + Z2)*(-2 + pow(Z2,2)) + TY_qa21*TY_qc222*(Z1 + Z2)*(-2 + pow(Z2,2))) + TY_q22*TY_qc221*(Z1 + Z2)*pow(Z2,3))
	
	TY_B22 = exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(-12*phi*TY_qc221*TY_qc222*(Z1 + Z2)*exp(Z1)*pow(Z2,2) + 12*phi*exp(Z2)*t2 + exp(2*Z2)*(12*phi*t3*(Z1 + Z2)*pow(Z2,2) +  exp(Z1)*t5))*pow(Z1 + Z2,-1)
	
	
	
	
	t1 = (2*TY_qc221*TY_qc223 + 2*TY_qc212*TY_qc232 + pow(TY_qc222,2))
	t2 = (TY_qb32*TY_qc212 + (TY_qa23 + TY_qb23)*TY_qc221 + (TY_qa22 + TY_qb22)*TY_qc222 + (TY_qa21 + TY_qb21)*TY_qc223 + (TY_qa12 + TY_qb12)*TY_qc232 + Z2*(TY_q22*TY_qc221 + 2*TY_qc221*TY_qc223 + 2*TY_qc212*TY_qc232 + pow(TY_qc222,2)))
	t3 = (-(TY_qc132*TY_qc212) - TY_qc123*TY_qc221 - TY_qc122*TY_qc222 - TY_qc121*TY_qc223 - TY_qc112*TY_qc232)
	t4 = (TY_qc132*TY_qc212 + TY_qc123*TY_qc221 + TY_qc122*TY_qc222 + TY_qc121*(TY_q22 + TY_qc223) + TY_qc112*TY_qc232)
	t5 = (TY_qa32*TY_qc212 + TY_qa23*TY_qc221 + TY_qa22*TY_qc222 + TY_qa21*(TY_q22 + TY_qc223) + TY_qa12*TY_qc232)
	t6 = (TY_qa32*TY_qc212 + TY_qa23*TY_qc221 + TY_qa22*TY_qc222 + TY_qa21*(TY_q22 + TY_qc223) + TY_qa12*TY_qc232 + (TY_qb32*TY_qc212 + TY_qb23*TY_qc221 + TY_qb22*TY_qc222 + TY_qb21*(TY_q22 + TY_qc223) + TY_qb12*TY_qc232)*Z1)
	t7 = (TY_qb32*TY_qc212 + TY_qb23*TY_qc221 + TY_qb22*TY_qc222 + TY_qb21*(TY_q22 + TY_qc223) + TY_qb12*TY_qc232)
	t8 = (TY_q22*(TY_qa21 + 2*TY_qb21 - 2*TY_qc221) + (TY_qa22 + 2*TY_qb22 - TY_qc222)*TY_qc222 + TY_qc221*(TY_qa23 + 2*TY_qb23 - 2*TY_qc223) + TY_qa21*TY_qc223 + 2*TY_qb21*TY_qc223 + TY_qc212*(TY_qa32 + 2*TY_qb32 - 2*TY_qc232) + TY_qa12*TY_qc232 + 2*TY_qb12*TY_qc232)
	t9 = (TY_qa21 + 2*TY_qb21 - 2*TY_qc121 - 2*TY_qc212 - 2*TY_qc221)
	t10 = (TY_qa22 + 2*TY_qb22 - 2*TY_qc122 - TY_qc222)
	t11 = (TY_qa23 + 2*TY_qb23 - 2*TY_qc123 - 2*TY_qc223)
	t12 = (TY_qa32 + 2*TY_qb32 - 2*TY_qc132 - 2*TY_qc232)
	t13 = ((Z1 + Z2)*exp(Z1)*(TY_qa23*TY_qc221 + TY_qa22*TY_qc222 + TY_qa21*TY_qc223 + TY_qa12*TY_qc232 + TY_qa32*TY_qc212*(1 + Z2) + Z2*t2) + t3*Z1*pow(Z2,2))
	t14 = (TY_q22*t9 + t10*TY_qc222 + TY_qc221*t11 + (TY_qa21 + 2*TY_qb21 - 2*TY_qc121)*TY_qc223 + TY_qc212*t12 + (TY_qa12 + 2*TY_qb12 - 2*TY_qc112)*TY_qc232)
	t15 = (-6*phi*(Z1 + Z2)*exp(Z1)*t1*pow(Z2,2) +  12*phi*exp(Z2)*t13 +  exp(2*Z2)*(12*phi*t4*(Z1 + Z2)*pow(Z2,2) +  exp(Z1)*(TY_q22*TY_qc222*(Z1 + Z2)*pow(Z2,3) - 6*phi*(2*t5*Z1 + 2*t6*Z2 - (-2*t7 +  t8*Z1)*pow(Z2,2) - t14*pow(Z2,3)))))
	
	TY_B23 = exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*t15*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qa22*TY_qc223 + TY_qa23*TY_qc222*(1 + Z2) + Z2*(TY_qb23*TY_qc222 + (TY_qa22 + TY_qb22)*TY_qc223 + TY_qc222*(TY_q22 + 2*TY_qc223)*Z2))
	t2 = (TY_qc123*TY_qc222 + TY_qc122*TY_qc223)
	t3 = (TY_qc123*TY_qc222 + TY_qc122*(TY_q22 + TY_qc223))
	t4 = (2*Z2*(TY_qb23*TY_qc222*(-1 + Z2)*(Z1 + Z2) + TY_qb22*TY_qc223*(-1 + Z2)*(Z1 + Z2) - Z2*(TY_qc222*TY_qc223*Z1 + TY_qc122*TY_qc223*Z2 + TY_qc222*(TY_qc123 + TY_qc223)*Z2)) + TY_qa23*TY_qc222*(Z1 + Z2)*(-2 + pow(Z2,2)) + TY_qa22*TY_qc223*(Z1 + Z2)*(-2 + pow(Z2,2)))
	t5 = (6*phi*t4 + (Z1 + Z2)*pow(TY_q22,2)*pow(Z2,3) + TY_q22*(6*phi*(2*Z2*(TY_qb22*(-1 + Z2)*(Z1 + Z2) - Z2*(TY_qc222*Z1 + (TY_qc122 + TY_qc222)*Z2)) + TY_qa22*(Z1 + Z2)*(-2 + pow(Z2,2))) + TY_qc223*(Z1 + Z2)*pow(Z2,3)))
	t6 = (12*phi*(Z1 + Z2)*t1*exp(Z1 + Z2) - 12*phi*TY_qc222*TY_qc223*(Z1 + Z2)*exp(Z1)*pow(Z2,2) - 12*phi*t2*Z1*exp(Z2)*pow(Z2,2) + 12*phi*t3*(Z1 + Z2)*exp(2*Z2)*pow(Z2,2) + exp(Z1 + 2*Z2)*t5)
		
	TY_B24 = exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*t6*pow(Z1 + Z2,-1)

	
	t1 = (exp(Z1)*(Z2*(-2*TY_qb23*(-1 + Z2)*(Z1 + Z2) + Z2*((TY_q22 + TY_qc223)*Z1 + (TY_q22 + 2*TY_qc123 + TY_qc223)*Z2)) -  TY_qa23*(Z1 + Z2)*(-2 + pow(Z2,2))) - 2*TY_qc123*(Z1 + Z2)*pow(Z2,2))
	t2 = ((Z1 + Z2)*exp(Z1)*pow(TY_qc223,2)*pow(Z2,2) + (TY_q22 + TY_qc223)*exp(2*Z2)*t1 + 2*TY_qc223*exp(Z2)*(TY_qc123*Z1*pow(Z2,2) - (Z1 + Z2)*exp(Z1)*(TY_qa23 + (TY_qa23 + TY_qb23)*Z2 + (TY_q22 + TY_qc223)*pow(Z2,2))))
	
	TY_B25 = -6*phi*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*t2*pow(Z1 + Z2,-1)
	
	
	t1 = (TY_qa21*TY_qc232 + TY_qa32*TY_qc221*(1 + Z2) + Z2*(TY_qb32*TY_qc221 + TY_qc232*(TY_qa21 + TY_qb21 + 2*TY_qc221*Z2)))
	t2 = (-(TY_qc132*TY_qc221) - TY_qc121*TY_qc232)
	t3 = (TY_qb32*TY_qc221*(-1 + Z2)*(Z1 + Z2) + TY_qb21*TY_qc232*(-1 + Z2)*(Z1 + Z2) - Z2*(TY_qc221*TY_qc232*Z1 + TY_qc121*TY_qc232*Z2 + TY_qc221*(TY_q22 + TY_qc132 + TY_qc232)*Z2))
	t4 = (exp(Z1)*(2*Z2*t3 + TY_qa32*TY_qc221*(Z1 + Z2)*(-2 + pow(Z2,2)) + TY_qa21*TY_qc232*(Z1 + Z2)*(-2 + pow(Z2,2))) + 2*(TY_qc132*TY_qc221 + TY_qc121*TY_qc232)*(Z1 + Z2)*pow(Z2,2))  
	
	TY_B32 = 6*phi*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(-2*TY_qc221*TY_qc232*(Z1 + Z2)*exp(Z1)*pow(Z2,2) + 2*exp(Z2)*((Z1 + Z2)*t1*exp(Z1) + t2*Z1*pow(Z2,2)) + exp(2*Z2)*t4)*pow(Z1 + Z2,-1)
	

	t1 = (-((Z1 + Z2)*(TY_qa23*TY_qc232 + TY_qa32*TY_qc223*(1 + Z2) + Z2*(TY_qb32*TY_qc223 + TY_qc232*(TY_qa23 + TY_qb23 + TY_q22*Z2 + 2*TY_qc223*Z2)))*exp(Z1)) + (TY_qc132*TY_qc223 + TY_qc123*TY_qc232)*Z1*pow(Z2,2))
	t2 = (TY_qc132*(TY_q22 + TY_qc223) + TY_qc123*TY_qc232)
	t3 = (TY_qa32*(TY_q22 + TY_qc223) + TY_qa23*TY_qc232)
	t4 = (TY_qa32*(TY_q22 + TY_qc223) + TY_qa23*TY_qc232 + (TY_qb32*(TY_q22 + TY_qc223) + TY_qb23*TY_qc232)*Z1)
	t5 = (-2*(TY_qb32*(TY_q22 + TY_qc223) + TY_qb23*TY_qc232) + ((TY_qa32 + 2*TY_qb32)*(TY_q22 + TY_qc223) + (-2*TY_q22 + TY_qa23 + 2*TY_qb23 - 2*TY_qc223)*TY_qc232)*Z1)
	t6 = (2*t3*Z1 + 2*t4*Z2 - t5*pow(Z2,2) + ((2*TY_q22 - TY_qa32 - 2*TY_qb32 + 2*TY_qc132)*(TY_q22 + TY_qc223) + (2*TY_q22 - TY_qa23 + 2*(-TY_qb23 + TY_qc123 + TY_qc223))*TY_qc232)*pow(Z2,3))
			  
	TY_B34 = -6*phi*exp(-Z1 - 2*Z2)*pow(TY_q22,-2)*pow(Z2,-3)*(2*TY_qc223*TY_qc232*(Z1 + Z2)*exp(Z1)*pow(Z2,2) + 2*exp(Z2)*t1 + exp(2*Z2)*(-2*t2*(Z1 + Z2)*pow(Z2,2) + exp(Z1)*t6))*pow(Z1 + Z2,-1)
	

//	/*double norm_B = sqrt(pow(TY_B12, 2)+pow(TY_B14, 2)+pow(TY_B21, 2)+pow(TY_B22, 2)+pow(TY_B23, 2)+pow(TY_B24, 2)+pow(TY_B25, 2)+pow(TY_B32, 2)+pow(TY_B34, 2));
//	
//	TY_B12 /= norm_B;
//	TY_B14 /= norm_B;
//	TY_B21 /= norm_B;
//	TY_B22 /= norm_B;
//	TY_B23 /= norm_B;
//	TY_B24 /= norm_B;
//	TY_B25 /= norm_B;
//	TY_B32 /= norm_B;
//	TY_B34 /= norm_B; */
	
	if( prnt ) 
		printf "\rNonlinear equation 2 = \r"
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0.,  TY_B12, 0.,  TY_B14, 0. 
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\r", TY_B21, TY_B22, TY_B23, TY_B24, TY_B25
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0.,  TY_B32, 0.,  TY_B34, 0. 
		printf "TY_B12 = %15.12g\r",TY_B12
		printf "TY_B14 = %15.12g\r",TY_B14
		printf "TY_B21 = %15.12g\r",TY_B21
		printf "TY_B22 = %15.12g\r",TY_B22
		printf "TY_B23 = %15.12g\r",TY_B23
		printf "TY_B24 = %15.12g\r",TY_B24
		printf "TY_B25 = %15.12g\r",TY_B25
		printf "TY_B32 = %15.12g\r",TY_B32
		printf "TY_B34 = %15.12g\r",TY_B34
	endif
	
//	/* decrease order of nonlinear equation 1 by means of equation 2 */
	NVAR TY_F14 = root:yuk:TY_F14
	NVAR TY_F16 = root:yuk:TY_F16
	NVAR TY_F18 = root:yuk:TY_F18
	NVAR TY_F23 = root:yuk:TY_F23
	NVAR TY_F24 = root:yuk:TY_F24
	NVAR TY_F25 = root:yuk:TY_F25
	NVAR TY_F26 = root:yuk:TY_F26
	NVAR TY_F27 = root:yuk:TY_F27
	NVAR TY_F28 = root:yuk:TY_F28
	NVAR TY_F29 = root:yuk:TY_F29
	NVAR TY_F32 = root:yuk:TY_F32
	NVAR TY_F33 = root:yuk:TY_F33
	NVAR TY_F34 = root:yuk:TY_F34
	NVAR TY_F35 = root:yuk:TY_F35
	NVAR TY_F36 = root:yuk:TY_F36
	NVAR TY_F37 = root:yuk:TY_F37
	NVAR TY_F38 = root:yuk:TY_F38
	NVAR TY_F39 = root:yuk:TY_F39
	NVAR TY_F310 = root:yuk:TY_F310
	
	TY_F14 = -(TY_A32*TY_B12*TY_B32) + TY_A52*pow(TY_B12,2) + TY_A12*pow(TY_B32,2)
	TY_F16 = 2*TY_A52*TY_B12*TY_B14 - TY_A32*TY_B14*TY_B32 - TY_A32*TY_B12*TY_B34 + 2*TY_A12*TY_B32*TY_B34
	TY_F18 = -(TY_A32*TY_B14*TY_B34) + TY_A52*pow(TY_B14,2) + TY_A12*pow(TY_B34,2)
	TY_F23 = 2*TY_A52*TY_B12*TY_B21 - TY_A41*TY_B12*TY_B32 - TY_A32*TY_B21*TY_B32 + TY_A21*pow(TY_B32,2)
	TY_F24 = 2*TY_A52*TY_B12*TY_B22 - TY_A42*TY_B12*TY_B32 - TY_A32*TY_B22*TY_B32 + TY_A22*pow(TY_B32,2)
	TY_F25 = 2*TY_A52*TY_B14*TY_B21 + 2*TY_A52*TY_B12*TY_B23 - TY_A43*TY_B12*TY_B32 - TY_A41*TY_B14*TY_B32 - TY_A32*TY_B23*TY_B32 - TY_A41*TY_B12*TY_B34 - TY_A32*TY_B21*TY_B34 + 2*TY_A21*TY_B32*TY_B34 + TY_A23*pow(TY_B32,2)
	TY_F26 = 2*TY_A52*TY_B14*TY_B22 + 2*TY_A52*TY_B12*TY_B24 - TY_A42*TY_B14*TY_B32 - TY_A32*TY_B24*TY_B32 - TY_A42*TY_B12*TY_B34 - TY_A32*TY_B22*TY_B34 + 2*TY_A22*TY_B32*TY_B34
	TY_F27 = 2*TY_A52*TY_B14*TY_B23 + 2*TY_A52*TY_B12*TY_B25 - TY_A43*TY_B14*TY_B32 - TY_A32*TY_B25*TY_B32 - TY_A43*TY_B12*TY_B34 - TY_A41*TY_B14*TY_B34 - TY_A32*TY_B23*TY_B34 + 2*TY_A23*TY_B32*TY_B34 + TY_A21*pow(TY_B34,2)
	TY_F28 = 2*TY_A52*TY_B14*TY_B24 - TY_A42*TY_B14*TY_B34 - TY_A32*TY_B24*TY_B34 + TY_A22*pow(TY_B34,2)
	TY_F29 = 2*TY_A52*TY_B14*TY_B25 - TY_A43*TY_B14*TY_B34 - TY_A32*TY_B25*TY_B34 + TY_A23*pow(TY_B34,2)
	TY_F32 = -(TY_A41*TY_B21*TY_B32) + TY_A52*pow(TY_B21,2)
	TY_F33 = 2*TY_A52*TY_B21*TY_B22 - TY_A42*TY_B21*TY_B32 - TY_A41*TY_B22*TY_B32
	TY_F34 = 2*TY_A52*TY_B21*TY_B23 - TY_A43*TY_B21*TY_B32 - TY_A42*TY_B22*TY_B32 - TY_A41*TY_B23*TY_B32 - TY_A41*TY_B21*TY_B34 + TY_A52*pow(TY_B22,2)
	TY_F35 = 2*TY_A52*TY_B22*TY_B23 + 2*TY_A52*TY_B21*TY_B24 - TY_A43*TY_B22*TY_B32 - TY_A42*TY_B23*TY_B32 - TY_A41*TY_B24*TY_B32 - TY_A42*TY_B21*TY_B34 - TY_A41*TY_B22*TY_B34
	TY_F36 = 2*TY_A52*TY_B22*TY_B24 + 2*TY_A52*TY_B21*TY_B25 - TY_A43*TY_B23*TY_B32 - TY_A42*TY_B24*TY_B32 - TY_A41*TY_B25*TY_B32 - TY_A43*TY_B21*TY_B34 - TY_A42*TY_B22*TY_B34 - TY_A41*TY_B23*TY_B34 + TY_A52*pow(TY_B23,2)
	TY_F37 = 2*TY_A52*TY_B23*TY_B24 + 2*TY_A52*TY_B22*TY_B25 - TY_A43*TY_B24*TY_B32 - TY_A42*TY_B25*TY_B32 - TY_A43*TY_B22*TY_B34 - TY_A42*TY_B23*TY_B34 - TY_A41*TY_B24*TY_B34
	TY_F38 = 2*TY_A52*TY_B23*TY_B25 - TY_A43*TY_B25*TY_B32 - TY_A43*TY_B23*TY_B34 - TY_A42*TY_B24*TY_B34 - TY_A41*TY_B25*TY_B34 + TY_A52*pow(TY_B24,2)
	TY_F39 = 2*TY_A52*TY_B24*TY_B25 - TY_A43*TY_B24*TY_B34 - TY_A42*TY_B25*TY_B34
	TY_F310 = -(TY_A43*TY_B25*TY_B34) + TY_A52*pow(TY_B25,2)
	
	if( prnt ) 
		printf "\rF = \r"
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0., 0.,  0.,  TY_F14, 0.,  TY_F16, 0.,  TY_F18, 0.,  0. 
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0., 0.,  TY_F23, TY_F24, TY_F25, TY_F26, TY_F27, TY_F28, TY_F29, 0.  
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0., TY_F32, TY_F33, TY_F34, TY_F35, TY_F36, TY_F37, TY_F38, TY_F39, TY_F310
		printf "TY_F14 = %15.12g\r",TY_F14
		printf "TY_F16 = %15.12g\r",TY_F16
		printf "TY_F18 = %15.12g\r",TY_F18
		printf "TY_F23 = %15.12g\r",TY_F23
		printf "TY_F24 = %15.12g\r",TY_F24
		printf "TY_F25 = %15.12g\r",TY_F25
		printf "TY_F26 = %15.12g\r",TY_F26
		printf "TY_F27 = %15.12g\r",TY_F27
		printf "TY_F28 = %15.12g\r",TY_F28
		printf "TY_F29 = %15.12g\r",TY_F29
		printf "TY_F32 = %15.12g\r",TY_F32
		printf "TY_F33 = %15.12g\r",TY_F33
		printf "TY_F34 = %15.12g\r",TY_F34
		printf "TY_F35 = %15.12g\r",TY_F35
		printf "TY_F36 = %15.12g\r",TY_F36
		printf "TY_F37 = %15.12g\r",TY_F37
		printf "TY_F38 = %15.12g\r",TY_F38
		printf "TY_F39 = %15.12g\r",TY_F39
		printf "TY_F310 = %15.12g\r",TY_F310
	endif
	
	NVAR TY_G13  = root:yuk:TY_G13
	NVAR TY_G14  = root:yuk:TY_G14
	NVAR TY_G15  = root:yuk:TY_G15
	NVAR TY_G16  = root:yuk:TY_G16
	NVAR TY_G17  = root:yuk:TY_G17
	NVAR TY_G18  = root:yuk:TY_G18
	NVAR TY_G19  = root:yuk:TY_G19
	NVAR TY_G110 = root:yuk:TY_G110
	NVAR TY_G111 = root:yuk:TY_G111
	NVAR TY_G112 = root:yuk:TY_G112
	NVAR TY_G113 = root:yuk:TY_G113
	NVAR TY_G22  = root:yuk:TY_G22
	NVAR TY_G23  = root:yuk:TY_G23
	NVAR TY_G24  = root:yuk:TY_G24
	NVAR TY_G25  = root:yuk:TY_G25
	NVAR TY_G26  = root:yuk:TY_G26
	NVAR TY_G27  = root:yuk:TY_G27
	NVAR TY_G28  = root:yuk:TY_G28
	NVAR TY_G29  = root:yuk:TY_G29
	NVAR TY_G210 = root:yuk:TY_G210
	NVAR TY_G211 = root:yuk:TY_G211
	NVAR TY_G212 = root:yuk:TY_G212
	NVAR TY_G213 = root:yuk:TY_G213
	NVAR TY_G214 = root:yuk:TY_G214
	
	
	TY_G13  = -(TY_B12*TY_F32)
	TY_G14  = -(TY_B12*TY_F33)
	TY_G15  = TY_B32*TY_F14 - TY_B14*TY_F32 - TY_B12*TY_F34
	TY_G16  = -(TY_B14*TY_F33) - TY_B12*TY_F35
	TY_G17  = TY_B34*TY_F14 + TY_B32*TY_F16 - TY_B14*TY_F34 - TY_B12*TY_F36
	TY_G18  = -(TY_B14*TY_F35) - TY_B12*TY_F37
	TY_G19  = TY_B34*TY_F16 + TY_B32*TY_F18 - TY_B14*TY_F36 - TY_B12*TY_F38
	TY_G110 = -(TY_B14*TY_F37) - TY_B12*TY_F39
	TY_G111 = TY_B34*TY_F18 - TY_B12*TY_F310 - TY_B14*TY_F38
	TY_G112 = -(TY_B14*TY_F39)
	TY_G113 = -(TY_B14*TY_F310)
	TY_G22  = -(TY_B21*TY_F32)
	TY_G23  = -(TY_B22*TY_F32) - TY_B21*TY_F33
	TY_G24  = TY_B32*TY_F23 - TY_B23*TY_F32 - TY_B22*TY_F33 - TY_B21*TY_F34
	TY_G25  = TY_B32*TY_F24 - TY_B24*TY_F32 - TY_B23*TY_F33 - TY_B22*TY_F34 - TY_B21*TY_F35
	TY_G26  = TY_B34*TY_F23 + TY_B32*TY_F25 - TY_B25*TY_F32 - TY_B24*TY_F33 - TY_B23*TY_F34 - TY_B22*TY_F35 - TY_B21*TY_F36
	TY_G27  = TY_B34*TY_F24 + TY_B32*TY_F26 - TY_B25*TY_F33 - TY_B24*TY_F34 - TY_B23*TY_F35 - TY_B22*TY_F36 - TY_B21*TY_F37
	TY_G28  = TY_B34*TY_F25 + TY_B32*TY_F27 - TY_B25*TY_F34 - TY_B24*TY_F35 - TY_B23*TY_F36 - TY_B22*TY_F37 - TY_B21*TY_F38
	TY_G29  = TY_B34*TY_F26 + TY_B32*TY_F28 - TY_B25*TY_F35 - TY_B24*TY_F36 - TY_B23*TY_F37 - TY_B22*TY_F38 - TY_B21*TY_F39
	TY_G210 = TY_B34*TY_F27 + TY_B32*TY_F29 - TY_B21*TY_F310 - TY_B25*TY_F36 - TY_B24*TY_F37 - TY_B23*TY_F38 - TY_B22*TY_F39
	TY_G211 = TY_B34*TY_F28 - TY_B22*TY_F310 - TY_B25*TY_F37 - TY_B24*TY_F38 - TY_B23*TY_F39
	TY_G212 = TY_B34*TY_F29 - TY_B23*TY_F310 - TY_B25*TY_F38 - TY_B24*TY_F39
	TY_G213 = -(TY_B24*TY_F310) - TY_B25*TY_F39
	TY_G214 = -(TY_B25*TY_F310)
	
	if( prnt ) 
		printf "\rG = \r"
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0., 0.,  TY_G13, TY_G14, TY_G15, TY_G16, TY_G17, TY_G18, TY_G19, TY_G110, TY_G111, TY_G112, TY_G113, 0. 
//		printf "%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\t\t%f\r", 0., TY_G22, TY_G23, TY_G24, TY_G25, TY_G26, TY_G27, TY_G28, TY_G29, TY_G210, TY_G211, TY_G212, TY_G213, TY_G214 
		printf "TY_G13  = %15.12g\r",TY_G13
		printf "TY_G14  = %15.12g\r",TY_G14
		printf "TY_G15  = %15.12g\r",TY_G15
		printf "TY_G16  = %15.12g\r",TY_G16
		printf "TY_G17  = %15.12g\r",TY_G17
		printf "TY_G18  = %15.12g\r",TY_G18
		printf "TY_G19  = %15.12g\r",TY_G19
		printf "TY_G110 = %15.12g\r",TY_G110
		printf "TY_G111 = %15.12g\r",TY_G111
		printf "TY_G112 = %15.12g\r",TY_G112
		printf "TY_G113 = %15.12g\r",TY_G113
		printf "TY_G22  = %15.12g\r",TY_G22
		printf "TY_G23  = %15.12g\r",TY_G23
		printf "TY_G24  = %15.12g\r",TY_G24
		printf "TY_G25  = %15.12g\r",TY_G25
		printf "TY_G26  = %15.12g\r",TY_G26
		printf "TY_G27  = %15.12g\r",TY_G27
		printf "TY_G28  = %15.12g\r",TY_G28
		printf "TY_G29  = %15.12g\r",TY_G29
		printf "TY_G210 = %15.12g\r",TY_G210
		printf "TY_G211 = %15.12g\r",TY_G211
		printf "TY_G212 = %15.12g\r",TY_G212
		printf "TY_G213 = %15.12g\r",TY_G213
		printf "TY_G214 = %15.12g\r",TY_G214
	endif
	
	Make/O/D/N=23 TY_w
	
	// coefficients for polynomial
	TY_w[0] = (-(TY_A21*TY_B12) + TY_A12*TY_B21)*(TY_A52*TY_B21 - TY_A41*TY_B32)*pow(TY_B21,2)*pow(TY_B32,3)
	
	TY_w[1] = 2*TY_B32*TY_G13*TY_G14 - TY_B24*TY_G13*TY_G22 - TY_B23*TY_G14*TY_G22 - TY_B22*TY_G15*TY_G22 - TY_B21*TY_G16*TY_G22 - TY_B23*TY_G13*TY_G23 - TY_B22*TY_G14*TY_G23
	TY_w[1] += - TY_B21*TY_G15*TY_G23 + 2*TY_B14*TY_G22*TY_G23 - TY_B22*TY_G13*TY_G24 - TY_B21*TY_G14*TY_G24 + 2*TY_B12*TY_G23*TY_G24 - TY_B21*TY_G13*TY_G25 + 2*TY_B12*TY_G22*TY_G25
	
	TY_w[2] = -(TY_B25*TY_G13*TY_G22) - TY_B24*TY_G14*TY_G22 - TY_B23*TY_G15*TY_G22 - TY_B22*TY_G16*TY_G22 - TY_B21*TY_G17*TY_G22 - TY_B24*TY_G13*TY_G23 - TY_B23*TY_G14*TY_G23 - TY_B22*TY_G15*TY_G23 - TY_B21*TY_G16*TY_G23
	TY_w[2] += -TY_B23*TY_G13*TY_G24 - TY_B22*TY_G14*TY_G24 - TY_B21*TY_G15*TY_G24 + 2*TY_B14*TY_G22*TY_G24 - TY_B22*TY_G13*TY_G25 - TY_B21*TY_G14*TY_G25 + 2*TY_B12*TY_G23*TY_G25 - TY_B21*TY_G13*TY_G26 + 2*TY_B12*TY_G22*TY_G26
	TY_w[2] += +TY_B34*pow(TY_G13,2) + TY_B32*(2*TY_G13*TY_G15 + pow(TY_G14,2)) + TY_B14*pow(TY_G23,2) + TY_B12*pow(TY_G24,2)
	
	TY_w[3] = 2*TY_B34*TY_G13*TY_G14 + 2*TY_B32*(TY_G14*TY_G15 + TY_G13*TY_G16) - TY_B25*TY_G14*TY_G22 - TY_B24*TY_G15*TY_G22 - TY_B23*TY_G16*TY_G22 - TY_B22*TY_G17*TY_G22 - TY_B21*TY_G18*TY_G22 - TY_B25*TY_G13*TY_G23  
	TY_w[3] += -TY_B24*TY_G14*TY_G23 - TY_B23*TY_G15*TY_G23 - TY_B22*TY_G16*TY_G23 - TY_B21*TY_G17*TY_G23 - TY_B24*TY_G13*TY_G24 - TY_B23*TY_G14*TY_G24 - TY_B22*TY_G15*TY_G24 - TY_B21*TY_G16*TY_G24 + 2*TY_B14*TY_G23*TY_G24  
	TY_w[3] += -TY_B23*TY_G13*TY_G25 - TY_B22*TY_G14*TY_G25 - TY_B21*TY_G15*TY_G25 + 2*TY_B14*TY_G22*TY_G25 + 2*TY_B12*TY_G24*TY_G25 - TY_B22*TY_G13*TY_G26 - TY_B21*TY_G14*TY_G26 + 2*TY_B12*TY_G23*TY_G26 - TY_B21*TY_G13*TY_G27 
	TY_w[3] += 2*TY_B12*TY_G22*TY_G27
	
	TY_w[4] = -(TY_B25*TY_G15*TY_G22) - TY_B24*TY_G16*TY_G22 - TY_B23*TY_G17*TY_G22 - TY_B22*TY_G18*TY_G22 - TY_B21*TY_G19*TY_G22 - TY_B25*TY_G14*TY_G23 - TY_B24*TY_G15*TY_G23 - TY_B23*TY_G16*TY_G23 - TY_B22*TY_G17*TY_G23  
	TY_w[4] += -TY_B21*TY_G18*TY_G23 - TY_B25*TY_G13*TY_G24 - TY_B24*TY_G14*TY_G24 - TY_B23*TY_G15*TY_G24 - TY_B22*TY_G16*TY_G24 - TY_B21*TY_G17*TY_G24 - TY_B24*TY_G13*TY_G25 - TY_B23*TY_G14*TY_G25 - TY_B22*TY_G15*TY_G25  
	TY_w[4] += -TY_B21*TY_G16*TY_G25 + 2*TY_B14*TY_G23*TY_G25 - TY_B23*TY_G13*TY_G26 - TY_B22*TY_G14*TY_G26 - TY_B21*TY_G15*TY_G26 + 2*TY_B14*TY_G22*TY_G26 + 2*TY_B12*TY_G24*TY_G26 - TY_B22*TY_G13*TY_G27 - TY_B21*TY_G14*TY_G27  
	TY_w[4] += 2*TY_B12*TY_G23*TY_G27 - TY_B21*TY_G13*TY_G28 + 2*TY_B12*TY_G22*TY_G28 + TY_B34*(2*TY_G13*TY_G15 + pow(TY_G14,2)) + TY_B32*(2*TY_G14*TY_G16 + 2*TY_G13*TY_G17 + pow(TY_G15,2)) + TY_B14*pow(TY_G24,2)  
	TY_w[4] += TY_B12*pow(TY_G25,2)
	
	TY_w[5] = 2*TY_B34*(TY_G14*TY_G15 + TY_G13*TY_G16) + 2*TY_B32*(TY_G15*TY_G16 + TY_G14*TY_G17 + TY_G13*TY_G18) - TY_B21*TY_G110*TY_G22 - TY_B25*TY_G16*TY_G22 - TY_B24*TY_G17*TY_G22 - TY_B23*TY_G18*TY_G22 - TY_B22*TY_G19*TY_G22 
	TY_w[5] += -TY_B25*TY_G15*TY_G23 - TY_B24*TY_G16*TY_G23 - TY_B23*TY_G17*TY_G23 - TY_B22*TY_G18*TY_G23 - TY_B21*TY_G19*TY_G23 - TY_B25*TY_G14*TY_G24 - TY_B24*TY_G15*TY_G24 - TY_B23*TY_G16*TY_G24 - TY_B22*TY_G17*TY_G24 
	TY_w[5] += -TY_B21*TY_G18*TY_G24 - TY_B25*TY_G13*TY_G25 - TY_B24*TY_G14*TY_G25 - TY_B23*TY_G15*TY_G25 - TY_B22*TY_G16*TY_G25 - TY_B21*TY_G17*TY_G25 + 2*TY_B14*TY_G24*TY_G25 - TY_B24*TY_G13*TY_G26 - TY_B23*TY_G14*TY_G26  
	TY_w[5] += -TY_B22*TY_G15*TY_G26 - TY_B21*TY_G16*TY_G26 + 2*TY_B14*TY_G23*TY_G26 + 2*TY_B12*TY_G25*TY_G26 - TY_B23*TY_G13*TY_G27 - TY_B22*TY_G14*TY_G27 - TY_B21*TY_G15*TY_G27 + 2*TY_B14*TY_G22*TY_G27 + 2*TY_B12*TY_G24*TY_G27  
	TY_w[5] += -TY_B22*TY_G13*TY_G28 - TY_B21*TY_G14*TY_G28 + 2*TY_B12*TY_G23*TY_G28 - TY_B21*TY_G13*TY_G29 + 2*TY_B12*TY_G22*TY_G29
	
	TY_w[6] = -(TY_B22*TY_G110*TY_G22) - TY_B21*TY_G111*TY_G22 - TY_B25*TY_G17*TY_G22 - TY_B24*TY_G18*TY_G22 - TY_B23*TY_G19*TY_G22 + TY_G210*(-(TY_B21*TY_G13) + 2*TY_B12*TY_G22) - TY_B21*TY_G110*TY_G23 - TY_B25*TY_G16*TY_G23  
	TY_w[6] += -TY_B24*TY_G17*TY_G23 - TY_B23*TY_G18*TY_G23 - TY_B22*TY_G19*TY_G23 - TY_B25*TY_G15*TY_G24 - TY_B24*TY_G16*TY_G24 - TY_B23*TY_G17*TY_G24 - TY_B22*TY_G18*TY_G24 - TY_B21*TY_G19*TY_G24 - TY_B25*TY_G14*TY_G25  
	TY_w[6] += -TY_B24*TY_G15*TY_G25 - TY_B23*TY_G16*TY_G25 - TY_B22*TY_G17*TY_G25 - TY_B21*TY_G18*TY_G25 - TY_B25*TY_G13*TY_G26 - TY_B24*TY_G14*TY_G26 - TY_B23*TY_G15*TY_G26 - TY_B22*TY_G16*TY_G26 - TY_B21*TY_G17*TY_G26  
	TY_w[6] += 2*TY_B14*TY_G24*TY_G26 - TY_B24*TY_G13*TY_G27 - TY_B23*TY_G14*TY_G27 - TY_B22*TY_G15*TY_G27 - TY_B21*TY_G16*TY_G27 + 2*TY_B14*TY_G23*TY_G27 + 2*TY_B12*TY_G25*TY_G27 - TY_B23*TY_G13*TY_G28 - TY_B22*TY_G14*TY_G28  
	TY_w[6] += -TY_B21*TY_G15*TY_G28 + 2*TY_B14*TY_G22*TY_G28 + 2*TY_B12*TY_G24*TY_G28 - TY_B22*TY_G13*TY_G29 - TY_B21*TY_G14*TY_G29 + 2*TY_B12*TY_G23*TY_G29 + TY_B34*(2*TY_G14*TY_G16 + 2*TY_G13*TY_G17 + pow(TY_G15,2))  
	TY_w[6] += TY_B32*(2*(TY_G15*TY_G17 + TY_G14*TY_G18 + TY_G13*TY_G19) + pow(TY_G16,2)) + TY_B14*pow(TY_G25,2) + TY_B12*pow(TY_G26,2)
	
	TY_w[7] = 2*TY_B34*(TY_G15*TY_G16 + TY_G14*TY_G17 + TY_G13*TY_G18) + 2*TY_B32*(TY_G110*TY_G13 + TY_G16*TY_G17 + TY_G15*TY_G18 + TY_G14*TY_G19) - TY_B22*TY_G13*TY_G210 - TY_B21*TY_G14*TY_G210 - TY_B23*TY_G110*TY_G22  
	TY_w[7] += -TY_B22*TY_G111*TY_G22 - TY_B21*TY_G112*TY_G22 - TY_B25*TY_G18*TY_G22 - TY_B24*TY_G19*TY_G22 + TY_G211*(-(TY_B21*TY_G13) + 2*TY_B12*TY_G22) - TY_B22*TY_G110*TY_G23 - TY_B21*TY_G111*TY_G23 - TY_B25*TY_G17*TY_G23  
	TY_w[7] += -TY_B24*TY_G18*TY_G23 - TY_B23*TY_G19*TY_G23 + 2*TY_B12*TY_G210*TY_G23 - TY_B21*TY_G110*TY_G24 - TY_B25*TY_G16*TY_G24 - TY_B24*TY_G17*TY_G24 - TY_B23*TY_G18*TY_G24 - TY_B22*TY_G19*TY_G24 - TY_B25*TY_G15*TY_G25  
	TY_w[7] += -TY_B24*TY_G16*TY_G25 - TY_B23*TY_G17*TY_G25 - TY_B22*TY_G18*TY_G25 - TY_B21*TY_G19*TY_G25 - TY_B25*TY_G14*TY_G26 - TY_B24*TY_G15*TY_G26 - TY_B23*TY_G16*TY_G26 - TY_B22*TY_G17*TY_G26 - TY_B21*TY_G18*TY_G26 
	TY_w[7] += 2*TY_B14*TY_G25*TY_G26 - TY_B25*TY_G13*TY_G27 - TY_B24*TY_G14*TY_G27 - TY_B23*TY_G15*TY_G27 - TY_B22*TY_G16*TY_G27 - TY_B21*TY_G17*TY_G27 + 2*TY_B14*TY_G24*TY_G27 + 2*TY_B12*TY_G26*TY_G27 - TY_B24*TY_G13*TY_G28  
	TY_w[7] += -TY_B23*TY_G14*TY_G28 - TY_B22*TY_G15*TY_G28 - TY_B21*TY_G16*TY_G28 + 2*TY_B14*TY_G23*TY_G28 + 2*TY_B12*TY_G25*TY_G28 - TY_B23*TY_G13*TY_G29 - TY_B22*TY_G14*TY_G29 - TY_B21*TY_G15*TY_G29 + 2*TY_B14*TY_G22*TY_G29  
	TY_w[7] += 2*TY_B12*TY_G24*TY_G29
	
	TY_w[8] = -(TY_B23*TY_G13*TY_G210) - TY_B22*TY_G14*TY_G210 - TY_B21*TY_G15*TY_G210 - TY_B22*TY_G13*TY_G211 - TY_B21*TY_G14*TY_G211 - TY_B21*TY_G13*TY_G212 - TY_B24*TY_G110*TY_G22 - TY_B23*TY_G111*TY_G22 - TY_B22*TY_G112*TY_G22  
	TY_w[8] += -TY_B21*TY_G113*TY_G22 - TY_B25*TY_G19*TY_G22 + 2*TY_B14*TY_G210*TY_G22 + 2*TY_B12*TY_G212*TY_G22 - TY_B23*TY_G110*TY_G23 - TY_B22*TY_G111*TY_G23 - TY_B21*TY_G112*TY_G23 - TY_B25*TY_G18*TY_G23 - TY_B24*TY_G19*TY_G23  
	TY_w[8] += 2*TY_B12*TY_G211*TY_G23 - TY_B22*TY_G110*TY_G24 - TY_B21*TY_G111*TY_G24 - TY_B25*TY_G17*TY_G24 - TY_B24*TY_G18*TY_G24 - TY_B23*TY_G19*TY_G24 + 2*TY_B12*TY_G210*TY_G24 - TY_B21*TY_G110*TY_G25 - TY_B25*TY_G16*TY_G25  
	TY_w[8] += -TY_B24*TY_G17*TY_G25 - TY_B23*TY_G18*TY_G25 - TY_B22*TY_G19*TY_G25 - TY_B25*TY_G15*TY_G26 - TY_B24*TY_G16*TY_G26 - TY_B23*TY_G17*TY_G26 - TY_B22*TY_G18*TY_G26 - TY_B21*TY_G19*TY_G26 - TY_B25*TY_G14*TY_G27 
	TY_w[8] += -TY_B24*TY_G15*TY_G27 - TY_B23*TY_G16*TY_G27 - TY_B22*TY_G17*TY_G27 - TY_B21*TY_G18*TY_G27 + 2*TY_B14*TY_G25*TY_G27 - TY_B25*TY_G13*TY_G28 - TY_B24*TY_G14*TY_G28 - TY_B23*TY_G15*TY_G28 - TY_B22*TY_G16*TY_G28  
	TY_w[8] += -TY_B21*TY_G17*TY_G28 + 2*TY_B14*TY_G24*TY_G28 + 2*TY_B12*TY_G26*TY_G28 - TY_B24*TY_G13*TY_G29 - TY_B23*TY_G14*TY_G29 - TY_B22*TY_G15*TY_G29 - TY_B21*TY_G16*TY_G29 + 2*TY_B14*TY_G23*TY_G29 + 2*TY_B12*TY_G25*TY_G29  
	TY_w[8] += TY_B34*(2*(TY_G15*TY_G17 + TY_G14*TY_G18 + TY_G13*TY_G19) + pow(TY_G16,2)) + TY_B32*(2*(TY_G111*TY_G13 + TY_G110*TY_G14 + TY_G16*TY_G18 + TY_G15*TY_G19) + pow(TY_G17,2)) + TY_B14*pow(TY_G26,2) 
	TY_w[8] += TY_B12*pow(TY_G27,2)
	
	TY_w[9] = 2*TY_B34*(TY_G110*TY_G13 + TY_G16*TY_G17 + TY_G15*TY_G18 + TY_G14*TY_G19) + 2*TY_B32*(TY_G112*TY_G13 + TY_G111*TY_G14 + TY_G110*TY_G15 + TY_G17*TY_G18 + TY_G16*TY_G19) - TY_B24*TY_G13*TY_G210 - TY_B23*TY_G14*TY_G210  
	TY_w[9] += -TY_B22*TY_G15*TY_G210 - TY_B21*TY_G16*TY_G210 - TY_B23*TY_G13*TY_G211 - TY_B22*TY_G14*TY_G211 - TY_B21*TY_G15*TY_G211 - TY_B22*TY_G13*TY_G212 - TY_B21*TY_G14*TY_G212 - TY_B25*TY_G110*TY_G22 - TY_B24*TY_G111*TY_G22  
	TY_w[9] += -TY_B23*TY_G112*TY_G22 - TY_B22*TY_G113*TY_G22 + 2*TY_B14*TY_G211*TY_G22 + TY_G213*(-(TY_B21*TY_G13) + 2*TY_B12*TY_G22) - TY_B24*TY_G110*TY_G23 - TY_B23*TY_G111*TY_G23 - TY_B22*TY_G112*TY_G23 
	TY_w[9] += -TY_B21*TY_G113*TY_G23 - TY_B25*TY_G19*TY_G23 + 2*TY_B14*TY_G210*TY_G23 + 2*TY_B12*TY_G212*TY_G23 - TY_B23*TY_G110*TY_G24 - TY_B22*TY_G111*TY_G24 - TY_B21*TY_G112*TY_G24 - TY_B25*TY_G18*TY_G24 - TY_B24*TY_G19*TY_G24  
	TY_w[9] += 2*TY_B12*TY_G211*TY_G24 - TY_B22*TY_G110*TY_G25 - TY_B21*TY_G111*TY_G25 - TY_B25*TY_G17*TY_G25 - TY_B24*TY_G18*TY_G25 - TY_B23*TY_G19*TY_G25 + 2*TY_B12*TY_G210*TY_G25 - TY_B21*TY_G110*TY_G26 - TY_B25*TY_G16*TY_G26  
	TY_w[9] += -TY_B24*TY_G17*TY_G26 - TY_B23*TY_G18*TY_G26 - TY_B22*TY_G19*TY_G26 - TY_B25*TY_G15*TY_G27 - TY_B24*TY_G16*TY_G27 - TY_B23*TY_G17*TY_G27 - TY_B22*TY_G18*TY_G27 - TY_B21*TY_G19*TY_G27 + 2*TY_B14*TY_G26*TY_G27 
	TY_w[9] += -TY_B25*TY_G14*TY_G28 - TY_B24*TY_G15*TY_G28 - TY_B23*TY_G16*TY_G28 - TY_B22*TY_G17*TY_G28 - TY_B21*TY_G18*TY_G28 + 2*TY_B14*TY_G25*TY_G28 + 2*TY_B12*TY_G27*TY_G28 - TY_B25*TY_G13*TY_G29 - TY_B24*TY_G14*TY_G29  
	TY_w[9] += -TY_B23*TY_G15*TY_G29 - TY_B22*TY_G16*TY_G29 - TY_B21*TY_G17*TY_G29 + 2*TY_B14*TY_G24*TY_G29 + 2*TY_B12*TY_G26*TY_G29
	
	TY_w[10] = -(TY_B25*TY_G13*TY_G210) - TY_B24*TY_G14*TY_G210 - TY_B23*TY_G15*TY_G210 - TY_B22*TY_G16*TY_G210 - TY_B21*TY_G17*TY_G210 - TY_B24*TY_G13*TY_G211 - TY_B23*TY_G14*TY_G211 - TY_B22*TY_G15*TY_G211 - TY_B21*TY_G16*TY_G211  
	TY_w[10] += -TY_B23*TY_G13*TY_G212 - TY_B22*TY_G14*TY_G212 - TY_B21*TY_G15*TY_G212 - TY_B22*TY_G13*TY_G213 - TY_B21*TY_G14*TY_G213 - TY_B21*TY_G13*TY_G214 - TY_B25*TY_G111*TY_G22 - TY_B24*TY_G112*TY_G22 - TY_B23*TY_G113*TY_G22  
	TY_w[10] += 2*TY_B14*TY_G212*TY_G22 + 2*TY_B12*TY_G214*TY_G22 - TY_B25*TY_G110*TY_G23 - TY_B24*TY_G111*TY_G23 - TY_B23*TY_G112*TY_G23 - TY_B22*TY_G113*TY_G23 + 2*TY_B14*TY_G211*TY_G23 + 2*TY_B12*TY_G213*TY_G23 
	TY_w[10] += -TY_B24*TY_G110*TY_G24 - TY_B23*TY_G111*TY_G24 - TY_B22*TY_G112*TY_G24 - TY_B21*TY_G113*TY_G24 - TY_B25*TY_G19*TY_G24 + 2*TY_B14*TY_G210*TY_G24 + 2*TY_B12*TY_G212*TY_G24 - TY_B23*TY_G110*TY_G25 
	TY_w[10] += -TY_B22*TY_G111*TY_G25 - TY_B21*TY_G112*TY_G25 - TY_B25*TY_G18*TY_G25 - TY_B24*TY_G19*TY_G25 + 2*TY_B12*TY_G211*TY_G25 - TY_B22*TY_G110*TY_G26 - TY_B21*TY_G111*TY_G26 - TY_B25*TY_G17*TY_G26 - TY_B24*TY_G18*TY_G26  
	TY_w[10] += -TY_B23*TY_G19*TY_G26 + 2*TY_B12*TY_G210*TY_G26 - TY_B21*TY_G110*TY_G27 - TY_B25*TY_G16*TY_G27 - TY_B24*TY_G17*TY_G27 - TY_B23*TY_G18*TY_G27 - TY_B22*TY_G19*TY_G27 - TY_B25*TY_G15*TY_G28 - TY_B24*TY_G16*TY_G28 
	TY_w[10] += -TY_B23*TY_G17*TY_G28 - TY_B22*TY_G18*TY_G28 - TY_B21*TY_G19*TY_G28 + 2*TY_B14*TY_G26*TY_G28 - TY_B25*TY_G14*TY_G29 - TY_B24*TY_G15*TY_G29 - TY_B23*TY_G16*TY_G29 - TY_B22*TY_G17*TY_G29 - TY_B21*TY_G18*TY_G29 
	TY_w[10] += 2*TY_B14*TY_G25*TY_G29 + 2*TY_B12*TY_G27*TY_G29 + TY_B34*(2*(TY_G111*TY_G13 + TY_G110*TY_G14 + TY_G16*TY_G18 + TY_G15*TY_G19) + pow(TY_G17,2)) 
	TY_w[10] += TY_B32*(2*(TY_G113*TY_G13 + TY_G112*TY_G14 + TY_G111*TY_G15 + TY_G110*TY_G16 + TY_G17*TY_G19) + pow(TY_G18,2)) + TY_B14*pow(TY_G27,2) + TY_B12*pow(TY_G28,2)
	
	TY_w[11] = 2*TY_B34*(TY_G112*TY_G13 + TY_G111*TY_G14 + TY_G110*TY_G15 + TY_G17*TY_G18 + TY_G16*TY_G19) + 2*TY_B32*(TY_G113*TY_G14 + TY_G112*TY_G15 + TY_G111*TY_G16 + TY_G110*TY_G17 + TY_G18*TY_G19) - TY_B25*TY_G14*TY_G210  
	TY_w[11] += -TY_B24*TY_G15*TY_G210 - TY_B23*TY_G16*TY_G210 - TY_B22*TY_G17*TY_G210 - TY_B21*TY_G18*TY_G210 - TY_B25*TY_G13*TY_G211 - TY_B24*TY_G14*TY_G211 - TY_B23*TY_G15*TY_G211 - TY_B22*TY_G16*TY_G211 - TY_B21*TY_G17*TY_G211  
	TY_w[11] += -TY_B24*TY_G13*TY_G212 - TY_B23*TY_G14*TY_G212 - TY_B22*TY_G15*TY_G212 - TY_B21*TY_G16*TY_G212 - TY_B23*TY_G13*TY_G213 - TY_B22*TY_G14*TY_G213 - TY_B21*TY_G15*TY_G213 - TY_B25*TY_G112*TY_G22 - TY_B24*TY_G113*TY_G22  
	TY_w[11] += 2*TY_B14*TY_G213*TY_G22 - TY_B25*TY_G111*TY_G23 - TY_B24*TY_G112*TY_G23 - TY_B23*TY_G113*TY_G23 + 2*TY_B14*TY_G212*TY_G23 - TY_G214*(TY_B22*TY_G13 + TY_B21*TY_G14 - 2*TY_B12*TY_G23) - TY_B25*TY_G110*TY_G24 
	TY_w[11] += -TY_B24*TY_G111*TY_G24 - TY_B23*TY_G112*TY_G24 - TY_B22*TY_G113*TY_G24 + 2*TY_B14*TY_G211*TY_G24 + 2*TY_B12*TY_G213*TY_G24 - TY_B24*TY_G110*TY_G25 - TY_B23*TY_G111*TY_G25 - TY_B22*TY_G112*TY_G25 
	TY_w[11] += -TY_B21*TY_G113*TY_G25 - TY_B25*TY_G19*TY_G25 + 2*TY_B14*TY_G210*TY_G25 + 2*TY_B12*TY_G212*TY_G25 - TY_B23*TY_G110*TY_G26 - TY_B22*TY_G111*TY_G26 - TY_B21*TY_G112*TY_G26 - TY_B25*TY_G18*TY_G26 - TY_B24*TY_G19*TY_G26  
	TY_w[11] += 2*TY_B12*TY_G211*TY_G26 - TY_B22*TY_G110*TY_G27 - TY_B21*TY_G111*TY_G27 - TY_B25*TY_G17*TY_G27 - TY_B24*TY_G18*TY_G27 - TY_B23*TY_G19*TY_G27 + 2*TY_B12*TY_G210*TY_G27 - TY_B21*TY_G110*TY_G28 - TY_B25*TY_G16*TY_G28 
	TY_w[11] += -TY_B24*TY_G17*TY_G28 - TY_B23*TY_G18*TY_G28 - TY_B22*TY_G19*TY_G28 + 2*TY_B14*TY_G27*TY_G28 - TY_B25*TY_G15*TY_G29 - TY_B24*TY_G16*TY_G29 - TY_B23*TY_G17*TY_G29 - TY_B22*TY_G18*TY_G29 - TY_B21*TY_G19*TY_G29 
	TY_w[11] += 2*TY_B14*TY_G26*TY_G29 + 2*TY_B12*TY_G28*TY_G29
	
	TY_w[12] = -(TY_B25*TY_G15*TY_G210) - TY_B24*TY_G16*TY_G210 - TY_B23*TY_G17*TY_G210 - TY_B22*TY_G18*TY_G210 - TY_B21*TY_G19*TY_G210 - TY_B25*TY_G14*TY_G211 - TY_B24*TY_G15*TY_G211 - TY_B23*TY_G16*TY_G211 - TY_B22*TY_G17*TY_G211 
	TY_w[12] += -TY_B21*TY_G18*TY_G211 - TY_B25*TY_G13*TY_G212 - TY_B24*TY_G14*TY_G212 - TY_B23*TY_G15*TY_G212 - TY_B22*TY_G16*TY_G212 - TY_B21*TY_G17*TY_G212 - TY_B24*TY_G13*TY_G213 - TY_B23*TY_G14*TY_G213 - TY_B22*TY_G15*TY_G213  
	TY_w[12] += -TY_B21*TY_G16*TY_G213 - TY_B25*TY_G113*TY_G22 - TY_B25*TY_G112*TY_G23 - TY_B24*TY_G113*TY_G23 + 2*TY_B14*TY_G213*TY_G23 - TY_B25*TY_G111*TY_G24 - TY_B24*TY_G112*TY_G24 - TY_B23*TY_G113*TY_G24 
	TY_w[12] += 2*TY_B14*TY_G212*TY_G24 - TY_G214*(TY_B23*TY_G13 + TY_B22*TY_G14 + TY_B21*TY_G15 - 2*TY_B14*TY_G22 - 2*TY_B12*TY_G24) - TY_B25*TY_G110*TY_G25 - TY_B24*TY_G111*TY_G25 - TY_B23*TY_G112*TY_G25 
	TY_w[12] += -TY_B22*TY_G113*TY_G25 + 2*TY_B14*TY_G211*TY_G25 + 2*TY_B12*TY_G213*TY_G25 - TY_B24*TY_G110*TY_G26 - TY_B23*TY_G111*TY_G26 - TY_B22*TY_G112*TY_G26 - TY_B21*TY_G113*TY_G26 - TY_B25*TY_G19*TY_G26  
	TY_w[12] += 2*TY_B14*TY_G210*TY_G26 + 2*TY_B12*TY_G212*TY_G26 - TY_B23*TY_G110*TY_G27 - TY_B22*TY_G111*TY_G27 - TY_B21*TY_G112*TY_G27 - TY_B25*TY_G18*TY_G27 - TY_B24*TY_G19*TY_G27 + 2*TY_B12*TY_G211*TY_G27  
	TY_w[12] += -TY_B22*TY_G110*TY_G28 - TY_B21*TY_G111*TY_G28 - TY_B25*TY_G17*TY_G28 - TY_B24*TY_G18*TY_G28 - TY_B23*TY_G19*TY_G28 + 2*TY_B12*TY_G210*TY_G28 - TY_B21*TY_G110*TY_G29 - TY_B25*TY_G16*TY_G29 - TY_B24*TY_G17*TY_G29  
	TY_w[12] += -TY_B23*TY_G18*TY_G29 - TY_B22*TY_G19*TY_G29 + 2*TY_B14*TY_G27*TY_G29 + TY_B34*(2*(TY_G113*TY_G13 + TY_G112*TY_G14 + TY_G111*TY_G15 + TY_G110*TY_G16 + TY_G17*TY_G19) + pow(TY_G18,2)) 
	TY_w[12] += TY_B32*(2*(TY_G113*TY_G15 + TY_G112*TY_G16 + TY_G111*TY_G17 + TY_G110*TY_G18) + pow(TY_G19,2)) + TY_B14*pow(TY_G28,2) + TY_B12*pow(TY_G29,2)
	
	TY_w[13] = 2*TY_B32*(TY_G113*TY_G16 + TY_G112*TY_G17 + TY_G111*TY_G18 + TY_G110*TY_G19) + 2*TY_B34*(TY_G113*TY_G14 + TY_G112*TY_G15 + TY_G111*TY_G16 + TY_G110*TY_G17 + TY_G18*TY_G19) - TY_B21*TY_G110*TY_G210 
	TY_w[13] += -TY_B25*TY_G16*TY_G210 - TY_B24*TY_G17*TY_G210 - TY_B23*TY_G18*TY_G210 - TY_B22*TY_G19*TY_G210 - TY_B25*TY_G15*TY_G211 - TY_B24*TY_G16*TY_G211 - TY_B23*TY_G17*TY_G211 - TY_B22*TY_G18*TY_G211 - TY_B21*TY_G19*TY_G211  
	TY_w[13] += -TY_B25*TY_G14*TY_G212 - TY_B24*TY_G15*TY_G212 - TY_B23*TY_G16*TY_G212 - TY_B22*TY_G17*TY_G212 - TY_B21*TY_G18*TY_G212 - TY_B25*TY_G13*TY_G213 - TY_B24*TY_G14*TY_G213 - TY_B23*TY_G15*TY_G213 - TY_B22*TY_G16*TY_G213  
	TY_w[13] += -TY_B21*TY_G17*TY_G213 - TY_B25*TY_G113*TY_G23 - TY_B25*TY_G112*TY_G24 - TY_B24*TY_G113*TY_G24 + 2*TY_B14*TY_G213*TY_G24 - TY_B25*TY_G111*TY_G25 - TY_B24*TY_G112*TY_G25 - TY_B23*TY_G113*TY_G25 
	TY_w[13] += 2*TY_B14*TY_G212*TY_G25 - TY_G214*(TY_B24*TY_G13 + TY_B23*TY_G14 + TY_B22*TY_G15 + TY_B21*TY_G16 - 2*TY_B14*TY_G23 - 2*TY_B12*TY_G25) - TY_B25*TY_G110*TY_G26 - TY_B24*TY_G111*TY_G26 - TY_B23*TY_G112*TY_G26  
	TY_w[13] += -TY_B22*TY_G113*TY_G26 + 2*TY_B14*TY_G211*TY_G26 + 2*TY_B12*TY_G213*TY_G26 - TY_B24*TY_G110*TY_G27 - TY_B23*TY_G111*TY_G27 - TY_B22*TY_G112*TY_G27 - TY_B21*TY_G113*TY_G27 - TY_B25*TY_G19*TY_G27 
	TY_w[13] += 2*TY_B14*TY_G210*TY_G27 + 2*TY_B12*TY_G212*TY_G27 - TY_B23*TY_G110*TY_G28 - TY_B22*TY_G111*TY_G28 - TY_B21*TY_G112*TY_G28 - TY_B25*TY_G18*TY_G28 - TY_B24*TY_G19*TY_G28 + 2*TY_B12*TY_G211*TY_G28  
	TY_w[13] += -TY_B22*TY_G110*TY_G29 - TY_B21*TY_G111*TY_G29 - TY_B25*TY_G17*TY_G29 - TY_B24*TY_G18*TY_G29 - TY_B23*TY_G19*TY_G29 + 2*TY_B12*TY_G210*TY_G29 + 2*TY_B14*TY_G28*TY_G29
	
	TY_w[14] = -(TY_B22*TY_G110*TY_G210) - TY_B21*TY_G111*TY_G210 - TY_B25*TY_G17*TY_G210 - TY_B24*TY_G18*TY_G210 - TY_B23*TY_G19*TY_G210 - TY_B21*TY_G110*TY_G211 - TY_B25*TY_G16*TY_G211 - TY_B24*TY_G17*TY_G211 
	TY_w[14] += -TY_B23*TY_G18*TY_G211 - TY_B22*TY_G19*TY_G211 - TY_B25*TY_G15*TY_G212 - TY_B24*TY_G16*TY_G212 - TY_B23*TY_G17*TY_G212 - TY_B22*TY_G18*TY_G212 - TY_B21*TY_G19*TY_G212 - TY_B25*TY_G14*TY_G213 - TY_B24*TY_G15*TY_G213 
	TY_w[14] += -TY_B23*TY_G16*TY_G213 - TY_B22*TY_G17*TY_G213 - TY_B21*TY_G18*TY_G213 - TY_B25*TY_G113*TY_G24 - TY_B25*TY_G112*TY_G25 - TY_B24*TY_G113*TY_G25 + 2*TY_B14*TY_G213*TY_G25 - TY_B25*TY_G111*TY_G26 - TY_B24*TY_G112*TY_G26  
	TY_w[14] += -TY_B23*TY_G113*TY_G26 + 2*TY_B14*TY_G212*TY_G26 - TY_G214*(TY_B25*TY_G13 + TY_B24*TY_G14 + TY_B23*TY_G15 + TY_B22*TY_G16 + TY_B21*TY_G17 - 2*TY_B14*TY_G24 - 2*TY_B12*TY_G26) - TY_B25*TY_G110*TY_G27 
	TY_w[14] += -TY_B24*TY_G111*TY_G27 - TY_B23*TY_G112*TY_G27 - TY_B22*TY_G113*TY_G27 + 2*TY_B14*TY_G211*TY_G27 + 2*TY_B12*TY_G213*TY_G27 - TY_B24*TY_G110*TY_G28 - TY_B23*TY_G111*TY_G28 - TY_B22*TY_G112*TY_G28 
	TY_w[14] += -TY_B21*TY_G113*TY_G28 - TY_B25*TY_G19*TY_G28 + 2*TY_B14*TY_G210*TY_G28 + 2*TY_B12*TY_G212*TY_G28 - TY_B23*TY_G110*TY_G29 - TY_B22*TY_G111*TY_G29 - TY_B21*TY_G112*TY_G29 - TY_B25*TY_G18*TY_G29 - TY_B24*TY_G19*TY_G29 
	TY_w[14] += 2*TY_B12*TY_G211*TY_G29 + TY_B32*(2*(TY_G113*TY_G17 + TY_G112*TY_G18 + TY_G111*TY_G19) + pow(TY_G110,2)) 
	TY_w[14] += TY_B34*(2*(TY_G113*TY_G15 + TY_G112*TY_G16 + TY_G111*TY_G17 + TY_G110*TY_G18) + pow(TY_G19,2)) + TY_B12*pow(TY_G210,2) + TY_B14*pow(TY_G29,2) 
	
	TY_w[15] = 2*TY_B34*(TY_G113*TY_G16 + TY_G112*TY_G17 + TY_G111*TY_G18 + TY_G110*TY_G19) + 2*TY_B32*(TY_G110*TY_G111 + TY_G113*TY_G18 + TY_G112*TY_G19) - TY_B23*TY_G110*TY_G210 - TY_B22*TY_G111*TY_G210  
	TY_w[15] += -TY_B21*TY_G112*TY_G210 - TY_B25*TY_G18*TY_G210 - TY_B24*TY_G19*TY_G210 - TY_B22*TY_G110*TY_G211 - TY_B21*TY_G111*TY_G211 - TY_B25*TY_G17*TY_G211 - TY_B24*TY_G18*TY_G211 - TY_B23*TY_G19*TY_G211  
	TY_w[15] += 2*TY_B12*TY_G210*TY_G211 - TY_B21*TY_G110*TY_G212 - TY_B25*TY_G16*TY_G212 - TY_B24*TY_G17*TY_G212 - TY_B23*TY_G18*TY_G212 - TY_B22*TY_G19*TY_G212 - TY_B25*TY_G15*TY_G213 - TY_B24*TY_G16*TY_G213  
	TY_w[15] += -TY_B23*TY_G17*TY_G213 - TY_B22*TY_G18*TY_G213 - TY_B21*TY_G19*TY_G213 - TY_B25*TY_G113*TY_G25 - TY_B25*TY_G112*TY_G26 - TY_B24*TY_G113*TY_G26 + 2*TY_B14*TY_G213*TY_G26 - TY_B25*TY_G111*TY_G27 - TY_B24*TY_G112*TY_G27 
	TY_w[15] += -TY_B23*TY_G113*TY_G27 + 2*TY_B14*TY_G212*TY_G27 - TY_G214*(TY_B25*TY_G14 + TY_B24*TY_G15 + TY_B23*TY_G16 + TY_B22*TY_G17 + TY_B21*TY_G18 - 2*TY_B14*TY_G25 - 2*TY_B12*TY_G27) - TY_B25*TY_G110*TY_G28 
	TY_w[15] += -TY_B24*TY_G111*TY_G28 - TY_B23*TY_G112*TY_G28 - TY_B22*TY_G113*TY_G28 + 2*TY_B14*TY_G211*TY_G28 + 2*TY_B12*TY_G213*TY_G28 - TY_B24*TY_G110*TY_G29 - TY_B23*TY_G111*TY_G29 - TY_B22*TY_G112*TY_G29 
	TY_w[15] += -TY_B21*TY_G113*TY_G29 - TY_B25*TY_G19*TY_G29 + 2*TY_B14*TY_G210*TY_G29 + 2*TY_B12*TY_G212*TY_G29
	
	TY_w[16] = -(TY_B24*TY_G110*TY_G210) - TY_B23*TY_G111*TY_G210 - TY_B22*TY_G112*TY_G210 - TY_B21*TY_G113*TY_G210 - TY_B25*TY_G19*TY_G210 - TY_B23*TY_G110*TY_G211 - TY_B22*TY_G111*TY_G211 - TY_B21*TY_G112*TY_G211 
	TY_w[16] += -TY_B25*TY_G18*TY_G211 - TY_B24*TY_G19*TY_G211 - TY_B22*TY_G110*TY_G212 - TY_B21*TY_G111*TY_G212 - TY_B25*TY_G17*TY_G212 - TY_B24*TY_G18*TY_G212 - TY_B23*TY_G19*TY_G212 + 2*TY_B12*TY_G210*TY_G212 
	TY_w[16] += -TY_B21*TY_G110*TY_G213 - TY_B25*TY_G16*TY_G213 - TY_B24*TY_G17*TY_G213 - TY_B23*TY_G18*TY_G213 - TY_B22*TY_G19*TY_G213 - TY_B25*TY_G113*TY_G26 - TY_B25*TY_G112*TY_G27 - TY_B24*TY_G113*TY_G27 
	TY_w[16] += 2*TY_B14*TY_G213*TY_G27 - TY_B25*TY_G111*TY_G28 - TY_B24*TY_G112*TY_G28 - TY_B23*TY_G113*TY_G28 + 2*TY_B14*TY_G212*TY_G28 
	TY_w[16] += -TY_G214*(TY_B25*TY_G15 + TY_B24*TY_G16 + TY_B23*TY_G17 + TY_B22*TY_G18 + TY_B21*TY_G19 - 2*TY_B14*TY_G26 - 2*TY_B12*TY_G28) - TY_B25*TY_G110*TY_G29 - TY_B24*TY_G111*TY_G29 - TY_B23*TY_G112*TY_G29 
	TY_w[16] += -TY_B22*TY_G113*TY_G29 + 2*TY_B14*TY_G211*TY_G29 + 2*TY_B12*TY_G213*TY_G29 + TY_B34*(2*(TY_G113*TY_G17 + TY_G112*TY_G18 + TY_G111*TY_G19) + pow(TY_G110,2)) 
	TY_w[16] += TY_B32*(2*TY_G110*TY_G112 + 2*TY_G113*TY_G19 + pow(TY_G111,2)) + TY_B14*pow(TY_G210,2) + TY_B12*pow(TY_G211,2)
	
	TY_w[17] = 2*TY_B32*(TY_G111*TY_G112 + TY_G110*TY_G113) + 2*TY_B34*(TY_G110*TY_G111 + TY_G113*TY_G18 + TY_G112*TY_G19) - TY_B25*TY_G110*TY_G210 - TY_B24*TY_G111*TY_G210 - TY_B23*TY_G112*TY_G210 - TY_B22*TY_G113*TY_G210  
	TY_w[17] += -TY_B24*TY_G110*TY_G211 - TY_B23*TY_G111*TY_G211 - TY_B22*TY_G112*TY_G211 - TY_B21*TY_G113*TY_G211 - TY_B25*TY_G19*TY_G211 + 2*TY_B14*TY_G210*TY_G211 - TY_B23*TY_G110*TY_G212 - TY_B22*TY_G111*TY_G212  
	TY_w[17] += -TY_B21*TY_G112*TY_G212 - TY_B25*TY_G18*TY_G212 - TY_B24*TY_G19*TY_G212 + 2*TY_B12*TY_G211*TY_G212 - TY_B22*TY_G110*TY_G213 - TY_B21*TY_G111*TY_G213 - TY_B25*TY_G17*TY_G213 - TY_B24*TY_G18*TY_G213  
	TY_w[17] += -TY_B23*TY_G19*TY_G213 + 2*TY_B12*TY_G210*TY_G213 - TY_B25*TY_G113*TY_G27 - TY_B25*TY_G112*TY_G28 - TY_B24*TY_G113*TY_G28 + 2*TY_B14*TY_G213*TY_G28 - TY_B25*TY_G111*TY_G29 - TY_B24*TY_G112*TY_G29 
	TY_w[17] += -TY_B23*TY_G113*TY_G29 + 2*TY_B14*TY_G212*TY_G29 - TY_G214*(TY_B21*TY_G110 + TY_B25*TY_G16 + TY_B24*TY_G17 + TY_B23*TY_G18 + TY_B22*TY_G19 - 2*TY_B14*TY_G27 - 2*TY_B12*TY_G29)
	
	TY_w[18] = -(TY_B25*TY_G111*TY_G210) - TY_B24*TY_G112*TY_G210 - TY_B23*TY_G113*TY_G210 - TY_B25*TY_G110*TY_G211 - TY_B24*TY_G111*TY_G211 - TY_B23*TY_G112*TY_G211 - TY_B22*TY_G113*TY_G211 - TY_B24*TY_G110*TY_G212 
	TY_w[18] += -TY_B23*TY_G111*TY_G212 - TY_B22*TY_G112*TY_G212 - TY_B21*TY_G113*TY_G212 - TY_B25*TY_G19*TY_G212 + 2*TY_B14*TY_G210*TY_G212 - TY_B23*TY_G110*TY_G213 - TY_B22*TY_G111*TY_G213 - TY_B21*TY_G112*TY_G213 
	TY_w[18] += -TY_B25*TY_G18*TY_G213 - TY_B24*TY_G19*TY_G213 + 2*TY_B12*TY_G211*TY_G213 - TY_B25*TY_G113*TY_G28 
	TY_w[18] += -TY_G214*(TY_B22*TY_G110 + TY_B21*TY_G111 + TY_B25*TY_G17 + TY_B24*TY_G18 + TY_B23*TY_G19 - 2*TY_B12*TY_G210 - 2*TY_B14*TY_G28) - TY_B25*TY_G112*TY_G29 - TY_B24*TY_G113*TY_G29 + 2*TY_B14*TY_G213*TY_G29
	TY_w[18] += TY_B34*(2*TY_G110*TY_G112 + 2*TY_G113*TY_G19 + pow(TY_G111,2)) + TY_B32*(2*TY_G111*TY_G113 + pow(TY_G112,2)) + TY_B14*pow(TY_G211,2) + TY_B12*pow(TY_G212,2)
	
	TY_w[19] = 2*TY_B32*TY_G112*TY_G113 + 2*TY_B34*(TY_G111*TY_G112 + TY_G110*TY_G113) - TY_B25*TY_G112*TY_G210 - TY_B24*TY_G113*TY_G210 - TY_B25*TY_G111*TY_G211 - TY_B24*TY_G112*TY_G211 - TY_B23*TY_G113*TY_G211 
	TY_w[19] += -TY_B25*TY_G110*TY_G212 - TY_B24*TY_G111*TY_G212 - TY_B23*TY_G112*TY_G212 - TY_B22*TY_G113*TY_G212 + 2*TY_B14*TY_G211*TY_G212 - TY_B24*TY_G110*TY_G213 - TY_B23*TY_G111*TY_G213 - TY_B22*TY_G112*TY_G213 
	TY_w[19] += -TY_B21*TY_G113*TY_G213 - TY_B25*TY_G19*TY_G213 + 2*TY_B14*TY_G210*TY_G213 + 2*TY_B12*TY_G212*TY_G213 - TY_B25*TY_G113*TY_G29 
	TY_w[19] += -TY_G214*(TY_B23*TY_G110 + TY_B22*TY_G111 + TY_B21*TY_G112 + TY_B25*TY_G18 + TY_B24*TY_G19 - 2*TY_B12*TY_G211 - 2*TY_B14*TY_G29)
	
	TY_w[20] = -(TY_B25*TY_G113*TY_G210) - TY_B25*TY_G112*TY_G211 - TY_B24*TY_G113*TY_G211 - TY_B25*TY_G111*TY_G212 - TY_B24*TY_G112*TY_G212 - TY_B23*TY_G113*TY_G212 - TY_B25*TY_G110*TY_G213 - TY_B24*TY_G111*TY_G213 
	TY_w[20] += -TY_B23*TY_G112*TY_G213 - TY_B22*TY_G113*TY_G213 + 2*TY_B14*TY_G211*TY_G213 - (TY_B24*TY_G110 + TY_B23*TY_G111 + TY_B22*TY_G112 + TY_B21*TY_G113 + TY_B25*TY_G19 - 2*TY_B14*TY_G210 - 2*TY_B12*TY_G212)*TY_G214 
	TY_w[20] += TY_B34*(2*TY_G111*TY_G113 + pow(TY_G112,2)) + TY_B32*pow(TY_G113,2) + TY_B14*pow(TY_G212,2) + TY_B12*pow(TY_G213,2)
	
	TY_w[21] = TY_B25*(TY_A23*TY_B14*(-3*TY_A52*TY_B24*TY_B25 + (2*TY_A43*TY_B24 + TY_A42*TY_B25)*TY_B34) + TY_B25*(TY_A22*TY_B14*(-(TY_A52*TY_B25) + TY_A43*TY_B34) + TY_A12*(4*TY_A52*TY_B24*TY_B25 - (3*TY_A43*TY_B24 + TY_A42*TY_B25)*TY_B34)))*pow(TY_B34,3)
	
	TY_w[22] = (-(TY_A23*TY_B14) + TY_A12*TY_B25)*(TY_A52*TY_B25 - TY_A43*TY_B34)*pow(TY_B25,2)*pow(TY_B34,3)
	
	if( prnt ) 
		printf "\rCoefficients of polynomial\r"
		variable i
		for ( i = 0; i < 23; i+=1 )
			printf "w[%d] = %g\r", i, TY_w[i]
		endfor
		printf "\r" 
	endif
	
end

Function TY_capQ( d2 )
	Variable d2
	
	NVAR TY_B32 = root:yuk:TY_B32
	NVAR TY_B34 = root:yuk:TY_B34

	return d2 * TY_B32 + pow( d2, 3 ) *  TY_B34
end

Function TY_V( d2 )
	variable d2
	
	NVAR TY_G13 = root:yuk:TY_G13
	NVAR TY_G14 = root:yuk:TY_G14
	NVAR TY_G15 = root:yuk:TY_G15
	NVAR TY_G16 = root:yuk:TY_G16
	NVAR TY_G17 = root:yuk:TY_G17
	NVAR TY_G18 = root:yuk:TY_G18
	NVAR TY_G19 = root:yuk:TY_G19
	NVAR TY_G110 = root:yuk:TY_G110
	NVAR TY_G111 = root:yuk:TY_G111
	NVAR TY_G112 = root:yuk:TY_G112
	NVAR TY_G113 = root:yuk:TY_G113

	return	-( pow( d2, 2 ) * TY_G13 + pow( d2, 3 ) * TY_G14 + pow( d2, 4 ) * TY_G15 + pow( d2, 5 ) * TY_G16 + pow( d2, 6 ) * TY_G17 + pow( d2, 7 ) *  TY_G18 + pow( d2, 8 ) * TY_G19 + pow( d2, 9 ) * TY_G110 +  pow( d2, 10 ) *  TY_G111 + pow( d2, 11 ) *  TY_G112 + pow( d2, 12 ) *  TY_G113 )
end

Function TY_capW( d2 )
	Variable d2
	
	variable tmp

	NVAR TY_G22 = root:yuk:TY_G22
	NVAR TY_G23 = root:yuk:TY_G23
	NVAR TY_G24 = root:yuk:TY_G24
	NVAR TY_G25 = root:yuk:TY_G25
	NVAR TY_G26 = root:yuk:TY_G26
	NVAR TY_G27 = root:yuk:TY_G27
	NVAR TY_G28 = root:yuk:TY_G28
	NVAR TY_G29 = root:yuk:TY_G29
	NVAR TY_G210 = root:yuk:TY_G210
	NVAR TY_G211 = root:yuk:TY_G211
	NVAR TY_G212 = root:yuk:TY_G212
	NVAR TY_G213 = root:yuk:TY_G213
	NVAR TY_G214 = root:yuk:TY_G214

	
	tmp = d2  * TY_G22 + pow( d2, 2 ) * TY_G23 + pow( d2, 3 ) * TY_G24 + pow( d2, 4 ) * TY_G25 + pow( d2, 5 ) * TY_G26
	tmp += pow( d2, 6 ) * TY_G27 + pow( d2, 7 ) *  TY_G28 + pow( d2, 8 ) *  TY_G29 + pow( d2, 9 ) * TY_G210
	tmp += pow( d2, 10 ) * TY_G211 + pow( d2, 11 ) * TY_G212 + pow( d2, 12 ) * TY_G213 + pow( d2, 13 ) * TY_G214
	
	return tmp
end

Function TY_X( d2 )
	Variable d2

	return TY_V( d2 ) / TY_capW( d2 )
end

// solve the linear system depending on d1, d2 using Cramer's rule
//
// a,b,c1,c2 are  passed by reference and returned
//
Function TY_SolveLinearEquations(  d1,  d2, a, b, c1, c2)
	Variable   d1,  d2, &a, &b, &c1, &c2


	NVAR TY_q22 = root:yuk:TY_q22
	NVAR TY_qa12 = root:yuk:TY_qa12
	NVAR TY_qa21 = root:yuk:TY_qa21
	NVAR TY_qa22 = root:yuk:TY_qa22
	NVAR TY_qa23 = root:yuk:TY_qa23
	NVAR TY_qa32 = root:yuk:TY_qa32

	NVAR TY_qb12 = root:yuk:TY_qb12
	NVAR TY_qb21 = root:yuk:TY_qb21
	NVAR TY_qb22 = root:yuk:TY_qb22
	NVAR TY_qb23 = root:yuk:TY_qb23
	NVAR TY_qb32 = root:yuk:TY_qb32

	NVAR TY_qc112 = root:yuk:TY_qc112
	NVAR TY_qc121 = root:yuk:TY_qc121
	NVAR TY_qc122 = root:yuk:TY_qc122
	NVAR TY_qc123 = root:yuk:TY_qc123
	NVAR TY_qc132 = root:yuk:TY_qc132

	NVAR TY_qc212 = root:yuk:TY_qc212
	NVAR TY_qc221 = root:yuk:TY_qc221
	NVAR TY_qc222 = root:yuk:TY_qc222
	NVAR TY_qc223 = root:yuk:TY_qc223
	NVAR TY_qc232 = root:yuk:TY_qc232

	Variable det    = TY_q22 * d1 * d2
	Variable det_a  = TY_qa12  * d2 + TY_qa21  * d1 + TY_qa22  * d1 * d2 + TY_qa23  * d1 * pow( d2, 2 ) + TY_qa32  * pow( d1, 2 ) * d2 
	Variable det_b  = TY_qb12  * d2 + TY_qb21  * d1 + TY_qb22  * d1 * d2 + TY_qb23  * d1 * pow( d2, 2 ) + TY_qb32  * pow( d1, 2 ) * d2 
	Variable det_c1 = TY_qc112 * d2 + TY_qc121 * d1 + TY_qc122 * d1 * d2 + TY_qc123 * d1 * pow( d2, 2 ) + TY_qc132 * pow( d1, 2 ) * d2 
	Variable det_c2 = TY_qc212 * d2 + TY_qc221 * d1 + TY_qc222 * d1 * d2 + TY_qc223 * d1 * pow( d2, 2 ) + TY_qc232 * pow( d1, 2 ) * d2
	
	a  = det_a  / det
	b  = det_b  / det
	c1 = det_c1 / det
	c2 = det_c2 / det
end

//Solve the system of linear and nonlinear equations for given Zi, Ki, phi which gives at 
// most 22 solutions for the parameters a,b,ci,di. From the set of solutions choose the 
// physical one and return it.
//
//
// a,b,c1,c2,d1,d2 are  passed by reference and returned
//
Function TY_SolveEquations(  Z1,  Z2,  K1,  K2,  phi, a,  b,  c1,  c2,  d1,  d2, prnt )
	Variable   Z1,  Z2,  K1,  K2,  phi, &a, &b, &c1, &c2, &d1, &d2, prnt 
	
	
	// reduce system to a polynomial from which all solution are extracted
	// by doing that a lot of global background variables are set
	TY_ReduceNonlinearSystem( Z1, Z2, K1, K2, phi, prnt )
	
	// the two coupled non-linear eqautions were reduced to a
	// 22nd order polynomial, the roots are give all possible solutions 
	// for d2, than d1 can be computed by the function X 
	
	Make/O/D/N=23 real_coefficient,imag_coefficient
	Make/O/D/N=22 real_root,imag_root
	
	//integer degree of polynomial
	variable degree = 22
	Variable i
	
	WAVE TY_w = TY_w
	
	
	////
	// now I need to replace this solution with FindRoots/P to get the polynomial roots
	////
	
	// vector of real and imaginary coefficients in order of INCREASING powers
	for ( i = 0; i <= degree; i+=1 )
		// the global variablw TY_w was set by TY_ReduceNonlinearSystem
		real_coefficient[i] = TY_w[i]
//		imag_coefficient[i] = 0.;
	endfor
	
//	zrhqr(real_coefficient, degree, NR_r, NR_i);
	
	FindRoots/P=real_coefficient
	
	WAVE/C W_polyRoots = W_polyRoots
	
	for(i=0; i<degree; i+=1) 
		real_root[i] = real(W_polyRoots[i])
		imag_root[i] = imag(W_polyRoots[i])
	endfor
	
	//end - NR solution of polynomial
	
	
	// show the result if in debug mode
	Variable x, y
	if ( prnt )
		for ( i = 0; i < degree; i+=1 )
			x = real_root[i]
			y = imag_root[i]
			if ( chop( y ) == 0 )
				printf "root(%d) = %g\r", i+1, x 
			else
				printf "root(%d) = %g + %g i\r", i+1, x, y
			endif
		endfor
		printf "\r"
	endif
	
	
	
	// select real roots and those satisfying Q(x) != 0 and W(x) != 0
	// Paper: Cluster formation in two-Yukawa Fluids, J. Chem. Phys. 122, 2005
	// The right set of (a, b, c1, c2, d1, d2) should have the following properties:
	// (1) a > 0 
	// (2) d1, d2 are real
	// (3) vi/Ki > 0 <=> g(Zi) > 0
	// (4) if there is still more than root, calculate g(r) for each root
	//     and g(r) of the correct root should have the minimum average value 
	//	   inside the hardcore	
	Variable var_a, var_b, var_c1, var_c2, var_d1, var_d2
	Make/O/D/N=22 sol_a, sol_b, sol_c1, sol_c2, sol_d1, sol_d2
	
	Variable j = 0
	for ( i = 0; i < degree; i+=1 )
	
		x = real_root[i]
		y = imag_root[i]
				
		if ( chop( y ) == 0 && TY_capW( x ) != 0 && TY_capQ( x ) != 0 )
		
			var_d1 = TY_X( x )
			var_d2 = x
			
			// solution of linear system for given d1, d2 to obtain a,b,ci,di
			// var_a, var_b, var_c1, var_c2 passed by reference
			TY_SolveLinearEquations( var_d1, var_d2, var_a, var_b, var_c1, var_c2 )
			
			// select physical solutions, for details check paper: "Cluster formation in
			// two-Yukawa fluids", J. Chem. Phys. 122 (2005)
			if ( var_a > 0 && TY_g( Z1, phi, Z1, Z2, var_a, var_b, var_c1, var_c2, var_d1, var_d2 ) > 0 && TY_g( Z2, phi, Z1, Z2, var_a, var_b, var_c1, var_c2, var_d1, var_d2 ) > 0 )
				sol_a[j]  = var_a
				sol_b[j]  = var_b
				sol_c1[j] = var_c1
				sol_c2[j] = var_c2
				sol_d1[j] = var_d1
				sol_d2[j] = var_d2
				
				if ( prnt )
					Variable eq1 = chop( TY_LinearEquation_1( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					Variable eq2 = chop( TY_LinearEquation_2( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					Variable eq3 = chop( TY_LinearEquation_3( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					Variable eq4 = chop( TY_LinearEquation_4( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					Variable eq5 = chop( TY_NonlinearEquation_1( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					Variable eq6 = chop( TY_NonlinearEquation_2( Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] ) )
					
					printf "solution[%d] = (%g, %g, %g, %g, %g, %g), ( eq == 0 ) = (%g, %g, %g, %g, %g, %g)\r", j, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j], eq1 , eq2, eq3, eq4, eq5, eq6
				endif
				
				j+=1
			endif		//var_a >0...
		endif 		//chop
	endfor
	// number  remaining roots 
	Variable n_roots = j
	
	// if there is still more than one root left, than choose the one with the minimum
	// average value inside the hardcore
	if ( n_roots > 1 )
		
		/////
		// it seems like this section should all be replaced in bulk with internal FFT code, rather than slow integration
		//
		// -- also, be sure to handle r=0, or the sum will always be INF
		////		
		
		// the number of q values should be a power of 2
		// in order to speed up the FFT
///		int n = 1 << 14;
		Variable n=16384		//2^14 points
		
		// the maximum q value should be large enough 
		// to enable a reasoble approximation of g(r)
		variable qmax = 16 * 10 * 2 * pi
		Variable q, dq = qmax / ( n - 1 )
		
		// step size for g(r)
		variable dr
		
		// allocate memory for pair correlation function g(r)
		// and structure factor S(q)
		Make/O/D/N=(n) sq,gr		//gr will be redimensioned!!
		
		// loop over all remaining roots
		Variable minVal = 1e50		//a really big number
		Variable selected_root = 10	
		Variable sumVal = 0
		
		for ( j = 0; j < n_roots; j+=1) 

			// calculate structure factor at different q values
			for ( i = 0; i < n; i+=1) 
			
				q = dq * i
				sq[i] = SqTwoYukawa( q, Z1, Z2, K1, K2, phi, sol_a[j], sol_b[j], sol_c1[j], sol_c2[j], sol_d1[j], sol_d2[j] )	
				
				if(i<10 && prnt) 
					printf "after SqTwoYukawa: s(q) = %g\r",sq[i]
				endif
				
			endfor
			
			// calculate pair correlation function for given
			// structure factor, g(r) is computed at values
			// r(i) = i * dr

//			Yuk_SqToGr( phi, dq, sq, dr, gr, n )


			Yuk_SqToGr_FFT( phi, dq, sq, dr, gr, n )
	
			// determine sum inside the hardcore 
			// 0 =< r < 1 of the pair-correlation function
			sumVal = 0
			for (i = 0; i < floor( 1. / dr ); i+=1 ) 
			
				sumVal += abs( gr[i] )
				
				if(i<10 && prnt) 
					printf "g(r) in core = %g\r",abs(gr[i])
				endif
				
			endfor

			if ( sumVal < minVal )
				minVal = sumVal
				selected_root = j
			endif
			
			if(prnt)
				printf "min = %g  sum = %g\r",minVal,sumVal
			endif
			
		endfor	

		
		// physical solution was found
		a  = sol_a [ selected_root ]		//sol_a [ selected_root ];
		b  = sol_b [ selected_root ]
		c1 = sol_c1[ selected_root ]
		c2 = sol_c2[ selected_root ]
		d1 = sol_d1[ selected_root ]
		d2 = sol_d2[ selected_root ]
		
		return 1
	
	else 
		if ( n_roots == 1 ) 
	
			a  = sol_a [0]
			b  = sol_b [0]
			c1 = sol_c1[0]
			c2 = sol_c2[0]
			d1 = sol_d1[0]
			d2 = sol_d2[0]
			
			return 1
		else		
			// no solution was found
			return 0
		endif
	endif
	
end




//
Function Yuk_SqToGr_FFT( phi, dq, sq, dr, gr, n )
	Variable  phi, dq
	WAVE sq
	Variable &dr
	WAVE gr
	Variable n 

	Variable npts,ii,rval,jj,qval,spread=1
	Variable alpha

	
	WaveStats/Q sq
	npts = V_npnts
	
	dr = 2*pi/(npts*dq)
	
	Make/O/D/N=(npts) temp
	
	temp = p*(sq[p] - 1)
	alpha = npts * pow( dq, 3 ) / ( 24 * pi * pi * phi )
	
	FFT/OUT=1/DEST=W_FFT temp
	
	
	WAVE/C W_FFT = W_FFT

	Redimension/N=(numpnts(W_FFT)) gr
	
	gr = 1 + alpha/p*imag(W_FFT)
	
	gr[0] = 0
	
	SetScale/P x,0,dr, gr
	
//	Killwaves/Z temp

	return(0)

End

////////////////////////end converted procedures //////////////////////////////////