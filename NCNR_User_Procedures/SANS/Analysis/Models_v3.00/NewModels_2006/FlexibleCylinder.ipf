#pragma rtGlobals=1		// Use modern global access method.

//CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
//CCCCCCCC
//C      SUBROUTINE FOR THE CALCULATION OF THE SCATTERING FUNCTIONS
//C      OF RODLIKE MICELLES.  METHODLOGY FOLLOWS THAT OF PEDERSEN AND
//C      SCHURTENBERGER, MACORMOLECULES, VOL 29,PG 7602, 1996.
//C      WITH EXCULDED VOLUME EFFECTS (METHOD 3)
//
// - copied directly from FORTRAN code supplied by Jan Pedersen
//		SRK - 2002, but shows discontinuity at Qlb = 3.1
//
//  Jan 2006 - re-worked FORTRAN correcting typos in paper: now is smooth, but
// the splicing is actually at Qlb = 2, which is not what the paper
// says is to be done (and not from earlier models)
//
// July 2006 - now is CORRECT with Wei-Ren's changes to the code
// Matlab code was not too difficult to convert to Igor (only a few hours...)
//
Proc PlotFlexExclVolCyl(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
		
	Make/O/D/n=(num) xwave_fle,ywave_fle
	xwave_fle =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_fle = {1.,1000,100,20,3.0e-6,0.0001}
	make/o/t parameters_fle = {"scale","Contour Length (A)","Kuhn Length, b (A)","Radius (A)","contrast (A^-2)","bkgd (cm^-1)"}
	Edit parameters_fle,coef_fle
	ywave_fle := FlexExclVolCyl(coef_fle,xwave_fle)
	Display ywave_fle vs xwave_fle
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End
///////////////////////////////////////////////////////////

Proc PlotSmearedFlexExclVolCyl()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fle = {1.,1000,100,20,3.0e-6,0.0001}					
	make/o/t smear_parameters_fle = {"scale","ContourLength (A)","KuhnLength, b (A)","Radius (A)","contrast (A^-2)","bkgd (cm^-1)"}		
	Edit smear_parameters_fle,smear_coef_fle					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_fle,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_fle							

	smeared_fle := SmearedFlexExclVolCyl(smear_coef_fle,$gQvals)		
	Display smeared_fle vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

//
Function FlexExclVolCyl(ww,x)
	Wave ww
	Variable x

	//nice names to the input params
	//ww[0] = scale
	//ww[1] = L [A]
	//ww[2] = B [A]
	//ww[3] = rad [A] cross-sectional radius
	//ww[4] = contrast [A^-2]
	//ww[5] = bkg [cm-1]
	Variable scale,L,B,bkg,rad,qr,cont
	
	scale = ww[0]
	L = ww[1]
	B = ww[2]
	rad = ww[3]
	cont = ww[4]
	bkg = ww[5]
	qr = x*rad		//used for cross section contribution only
	
	Variable flex,crossSect
	flex = Sk_WR(x,L,B)
     
	crossSect = (2*bessJ(1,qr)/qr)^2
        
	//normalize form factor by multiplying by cylinder volume * cont^2
   // then convert to cm-1 by multiplying by 10^8
   // then scale = phi 

	flex *= crossSect
	flex *= Pi*rad*rad*L
	flex *= cont^2
	flex *= 1.0e8
	
   return (scale*flex + bkg)
End

//////////////////WRC corrected code below
// main function
function Sk_WR(q,L,b)
	Variable q,L,b
	//
	Variable p1,p2,p1short,p2short,q0,qconnect
	Variable c,epsilon,ans,q0short,Sexvmodify
	
	p1 = 4.12
	p2 = 4.42
	p1short = 5.36
	p2short = 5.62
	q0 = 3.1
	qconnect = q0/b
	//	
	q0short = max(1.9/sqrt(Rgsquareshort(q,L,b)),3)
	
	//
	if(L/b > 10)
		C = 3.06/(L/b)^0.44
		epsilon = 0.176
	else
		C = 1
		epsilon = 0.170
	endif
	//
	
	if( L > 4*b ) // Longer Chains
		if (q*b <= 3.1)
			//Modified by Yun on Oct. 15,
			Sexvmodify = Sexvnew(q, L, b)
			ans = Sexvmodify + C * (4/15 + 7./(15*u_WR(q,L,b)) - (11/15 + 7./(15*u_WR(q,L,b)))*exp(-u_WR(q,L,b)))*(b/L) 
		else //q(i)*b > 3.1
			ans = a1long(q, L, b, p1, p2, q0)/((q*b)^p1) + a2long(q, L, b, p1, p2, q0)/((q*b)^p2) + pi/(q*L)
		endif 
	else //L <= 4*b Shorter Chains
		if (q*b <= max(1.9/sqrt(Rgsquareshort(q,L,b)),3) )
			if (q*b<=0.01)
				ans = 1 - Rgsquareshort(q,L,b)*(q^2)/3
			else
				ans = Sdebye1(q,L,b)
			endif
		else	//q*b > max(1.9/sqrt(Rgsquareshort(q(i),L,b)),3)
			ans = a1short(q,L,b,p1short,p2short,q0short)/((q*b)^p1short) + a2short(q,L,b,p1short,p2short,q0short)/((q*b)^p2short) + pi/(q*L)
		endif
	endif
	
	return(ans)
end

//WR named this w (too generic)
Function w_WR(x)
    Variable x

    //C4 = 1.523;
    //C5 = 0.1477;
    Variable yy
    yy = 0.5*(1 + tanh((x - 1.523)/0.1477))

    return (yy)
end

//
function u1(q,L,b)
    Variable q,L,b
    Variable yy

    yy = Rgsquareshort(q,L,b)*q^2
    
    return yy
end

// was named u
function u_WR(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = Rgsquare(q,L,b)*(q^2)
    return yy
end



//
function Rgsquarezero(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = (L*b/6) * (1 - 1.5*(b/L) + 1.5*(b/L)^2 - 0.75*(b/L)^3*(1 - exp(-2*(L/b))))
    
    return yy
end

//
function Rgsquareshort(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = AlphaSquare(L/b) * Rgsquarezero(q,L,b)
    
    return yy
end

//
function Rgsquare(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = AlphaSquare(L/b)*L*b/6
    
    return yy
end

//
function AlphaSquare(x)
    Variable x
    
    Variable yy
    yy = (1 + (x/3.12)^2 + (x/8.67)^3)^(0.176/3)

    return yy
end

//
function miu(x)
    Variable x
    
    Variable yy
    yy = (1/8)*(9*x - 2 + 2*log(1 + x)/x)*exp(1/2.565*(1/x + (1 - 1/(x^2))*log(1 + x)))
    
    return yy
end

//
function Sdebye(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = 2*(exp(-u_WR(q,L,b)) + u_WR(q,L,b) -1)/((u_WR(q,L,b))^2) 

    return yy
end

//
function Sdebye1(q,L,b)
    Variable q,L,b
    
    Variable yy
    yy = 2*(exp(-u1(q,L,b)) + u1(q,L,b) -1)/((u1(q,L,b))^2)
    
    return yy
end

//
function Sexv(q,L,b)
    Variable q,L,b
    
    Variable yy,C1,C2,C3,miu,Rg2
    C1=1.22
    C2=0.4288
    C3=-1.651
    miu = 0.585

    Rg2 = Rgsquare(q,L,b)
    
    yy = (1 - w_WR(q*sqrt(Rg2)))*Sdebye(q,L,b) + w_WR(q*sqrt(Rg2))*(C1*(q*sqrt(Rg2))^(-1/miu) +  C2*(q*sqrt(Rg2))^(-2/miu) +    C3*(q*sqrt(Rg2))^(-3/miu))
    
    return yy
end

// this must be WR modified version
function Sexvnew(q,L,b)
    Variable q,L,b
    
    Variable yy,C1,C2,C3,miu
    C1=1.22
    C2=0.4288
    C3=-1.651
    miu = 0.585

    //calculating the derivative to decide on the corection (cutoff) term?
    // I have modified this from WRs original code
    Variable del=1.05,C_star2,Rg2
    if( (Sexv(q*del,L,b)-Sexv(q,L,b))/(q*del - q) >= 0 )
        C_star2 = 0
    else
        C_star2 = 1
    endif

    Rg2 = Rgsquare(q,L,b)
    
    yy = (1 - w_WR(q*sqrt(Rg2)))*Sdebye(q,L,b) + C_star2*w_WR(q*sqrt(Rg2))*(C1*(q*sqrt(Rg2))^(-1/miu) + C2*(q*sqrt(Rg2))^(-2/miu) + C3*(q*sqrt(Rg2))^(-3/miu))

    return yy
end



// these are the messy ones
function a2short(q, L, b, p1short, p2short, q0)
    Variable q, L, b, p1short, p2short, q0
    
    Variable yy,Rg2_sh
    Rg2_sh = Rgsquareshort(q,L,b)
    
    Variable t1
    t1 = ((q0^2*Rg2_sh)/b^2)
    
    //E is the number e
    yy = ((-(1/(L*((p1short - p2short))*Rg2_sh^2)*((b*E^(-t1)*q0^(-4 + p2short)*((8*b^3*L - 8*b^3*E^t1*L - 2*b^3*L*p1short + 2*b^3*E^t1*L*p1short + 4*b*L*q0^2*Rg2_sh + 4*b*E^t1*L*q0^2*Rg2_sh - 2*b*E^t1*L*p1short*q0^2*Rg2_sh - E^t1*pi*q0^3*Rg2_sh^2 + E^t1*p1short*pi*q0^3*Rg2_sh^2)))))))
          
    return yy
end

//
function a1short(q, L, b, p1short, p2short, q0)
    Variable q, L, b, p1short, p2short, q0
    
    Variable yy,Rg2_sh
    Rg2_sh = Rgsquareshort(q,L,b)

    Variable t1
    t1 = ((q0^2*Rg2_sh)/b^2)
    
    yy = ((1/(L*((p1short - p2short))*Rg2_sh^2)*((b*E^(-t1)*q0^((-4) + p1short)*((8*b^3*L - 8*b^3*E^t1*L - 2*b^3*L*p2short + 2*b^3*E^t1*L*p2short + 4*b*L*q0^2*Rg2_sh + 4*b*E^t1*L*q0^2*Rg2_sh - 2*b*E^t1*L*p2short*q0^2*Rg2_sh - E^t1*pi*q0^3*Rg2_sh^2 + E^t1*p2short*pi*q0^3*Rg2_sh^2)))))) 
        
    return yy
end

// this one will be lots of trouble
function a2long(q, L, b, p1, p2, q0)
    variable q, L, b, p1, p2, q0

    Variable yy,c1,c2,c3,c4,c5,miu,c,Rg2,rRg
    Variable t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13

    if( L/b > 10)
        C = 3.06/(L/b)^0.44
    else
        C = 1
    endif

    C1 = 1.22 
    C2 = 0.4288
    C3 = -1.651
    C4 = 1.523
    C5 = 0.1477
    miu = 0.585

    Rg2 = Rgsquare(q,L,b)
    t1 = (1/(b* p1*q0^((-1) - p1 - p2) - b*p2*q0^((-1) - p1 - p2)))
    t2 = (b*C*(((-1*((14*b^3)/(15*q0^3*Rg2))) + (14*b^3*E^(-((q0^2*Rg2)/b^2)))/(15*q0^3*Rg2) + (2*E^(-((q0^2*Rg2)/b^2))*q0*((11/15 + (7*b^2)/(15*q0^2*Rg2)))*Rg2)/b)))/L
    t3 = (sqrt(Rg2)*((C3*(((sqrt(Rg2)*q0)/b))^((-3)/miu) + C2*(((sqrt(Rg2)*q0)/b))^((-2)/miu) + C1*(((sqrt(Rg2)*q0)/b))^((-1)/miu)))*sech_WR(((-C4) + (sqrt(Rg2)*q0)/b)/C5)^2)/(2*C5)
    t4 = (b^4*sqrt(Rg2)*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*sech_WR(((-C4) + (sqrt(Rg2)*q0)/b)/C5)^2)/(C5*q0^4*Rg2^2)
    t5 = (2*b^4*(((2*q0*Rg2)/b - (2*E^(-((q0^2*Rg2)/b^2))*q0*Rg2)/b))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))/(q0^4*Rg2^2)
    t6 = (8*b^5*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))/(q0^5*Rg2^2)
    t7 = (((-((3*C3*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 3/miu))/miu)) - (2*C2*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 2/miu))/miu - (C1*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 1/miu))/miu))
    t8 = ((1 + tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5)))
    t9 = (b*C*((4/15 - E^(-((q0^2*Rg2)/b^2))*((11/15 + (7*b^2)/(15*q0^2*Rg2))) + (7*b^2)/(15*q0^2*Rg2))))/L
    t10 = (2*b^4*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))/(q0^4*Rg2^2)
 
    
    yy = ((-1*(t1* (((-q0^(-p1))*(((b^2*pi)/(L*q0^2) + t2 + t3 - t4 + t5 - t6 + 1/2*t7*t8)) - b*p1*q0^((-1) - p1)*(((-((b*pi)/(L*q0))) + t9 + t10 + 1/2*((C3*(((sqrt(Rg2)*q0)/b))^((-3)/miu) + C2*(((sqrt(Rg2)*q0)/b))^((-2)/miu) + C1*(((sqrt(Rg2)*q0)/b))^((-1)/miu)))*((1 + tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))))))


    return yy
end

//need to define this on my own
Function sech_WR(x)
	variable x
	
	return(1/cosh(x))
end
//
function a1long(q, L, b, p1, p2, q0)
    Variable q, L, b, p1, p2, q0
    
    Variable yy,c,c1,c2,c3,c4,c5,miu,Rg2,rRg
    Variable t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15,t16
    
    if( L/b > 10)
        C = 3.06/(L/b)^0.44
    else
        C = 1
    endif

    C1 = 1.22
    C2 = 0.4288
    C3 = -1.651
    C4 = 1.523
    C5 = 0.1477
    miu = 0.585

    Rg2 = Rgsquare(q,L,b)
    t1 = (b*C*((4/15 - E^(-((q0^2*Rg2)/b^2))*((11/15 + (7*b^2)/(15*q0^2*Rg2))) + (7*b^2)/(15*q0^2*Rg2))))
    t2 = (2*b^4*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))
    t3 = ((C3*(((sqrt(Rg2)*q0)/b))^((-3)/miu) + C2*(((sqrt(Rg2)*q0)/b))^((-2)/miu) + C1*(((sqrt(Rg2)*q0)/b))^((-1)/miu)))
    t4 = ((1 + tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5)))
    t5 = (1/(b*p1*q0^((-1) - p1 - p2) - b*p2*q0^((-1) - p1 - p2)))
    t6 = (b*C*(((-((14*b^3)/(15*q0^3*Rg2))) + (14*b^3*E^(-((q0^2*Rg2)/b^2)))/(15*q0^3*Rg2) + (2*E^(-((q0^2*Rg2)/b^2))*q0*((11/15 + (7*b^2)/(15*q0^2*Rg2)))*Rg2)/b)))
    t7 = (sqrt(Rg2)*((C3*(((sqrt(Rg2)*q0)/b))^((-3)/miu) + C2*(((sqrt(Rg2)*q0)/b))^((-2)/miu) + C1*(((sqrt(Rg2)*q0)/b))^((-1)/miu)))*sech_WR(((-C4) + (sqrt(Rg2)*q0)/b)/C5)^2)
    t8 = (b^4*sqrt(Rg2)*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*sech_WR(((-C4) + (sqrt(Rg2)*q0)/b)/C5)^2)
    t9 = (2*b^4*(((2*q0*Rg2)/b - (2*E^(-((q0^2*Rg2)/b^2))*q0*Rg2)/b))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))
    t10 = (8*b^5*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))
    t11 = (((-((3*C3*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 3/miu))/miu)) - (2*C2*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 2/miu))/miu - (C1*sqrt(Rg2)*(((sqrt(Rg2)*q0)/b))^((-1) - 1/miu))/miu))
    t12 = ((1 + tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5)))
    t13 = (b*C*((4/15 - E^(-((q0^2*Rg2)/b^2))*((11/15 + (7*b^2)/(15*q0^2* Rg2))) + (7*b^2)/(15*q0^2*Rg2))))
    t14 = (2*b^4*(((-1) + E^(-((q0^2*Rg2)/b^2)) + (q0^2*Rg2)/b^2))*((1 + 1/2*(((-1) - tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5))))))
    t15 = ((C3*(((sqrt(Rg2)*q0)/b))^((-3)/miu) + C2*(((sqrt(Rg2)*q0)/b))^((-2)/miu) + C1*(((sqrt(Rg2)*q0)/b))^((-1)/miu)))

    
    yy = (q0^p1*(((-((b*pi)/(L*q0))) +t1/L +t2/(q0^4*Rg2^2) + 1/2*t3*t4)) + (t5*((q0^(p1 - p2)*(((-q0^(-p1))*(((b^2*pi)/(L*q0^2) +t6/L +t7/(2*C5) -t8/(C5*q0^4*Rg2^2) +t9/(q0^4*Rg2^2) -t10/(q0^5*Rg2^2) + 1/2*t11*t12)) - b*p1*q0^((-1) - p1)*(((-((b*pi)/(L*q0))) +t13/L +t14/(q0^4*Rg2^2) + 1/2*t15*((1 + tanh(((-C4) + (sqrt(Rg2)*q0)/b)/C5)))))))))))

    
    return yy
end


// unused functions copied from WRC Matlab code


//function Vmic(phi)
//    Variable phi
//    
//    Variable yy
//    yy = 2.53*10^6*(phi)^(0.5) + 8.35*(phi)^(-2)
//    
//    return yy
//end

//function Scs(x)
//    Variable x
//    
//    Variable yy
//    yy = (2*bessj(1,x)/x)^2
//    
//    return yy
//end

//function Srod(q,L,b)
//    Variable q,L,b
//    
//    Variable yy
//    yy = 2 * Si(q,L,b)/(q*L) - 4 * (sin(q*L/2)^2)/((q*L)^2)
//
//    return yy
//end
//
//function Si(q,L,b)
//    Variable q,L,b
//    
//    Variable yy
//   
////   for i=1:length(q)
////   y(i) = quadl('sin(x)./(x)',10e-8,q(i)*L);
////   end
//   
//    return yy
//end

//////////////////

// this is all there is to the smeared calculation!
Function SmearedFlexExclVolCyl(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(FlexExclVolCyl,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
