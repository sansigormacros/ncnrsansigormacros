#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
// this is an empirical representation of the White Beam wavelength
// distribution. 
//
// using Integrate function -- find the normalization value
//
// integral = 20926 (cts*A) for "top"
// integral = 19933 (cts*A) for "middle"
// integration of interpolated data (100 pts) = 20051 (3 A to 9 A)
//
//
//
// of the three choices, using the fit to the "top" of the distribution gives the best-looking
// result when compared to the AgBeh data
//


// 9/2019
// added an empirical functional form for the "Super" white beam mode where the deflector is out
// and the wavelength is not cut off at the higher wavelength, but extends to 20 Å
//
// Integral = 30955 (cts*A) for middle fit
//
//

//  White Beam:
//  mean wavelength = 5.29687
//  3rd moment/2nd moment = 5.741
//
//  Super White Beam:
//  mean wavelength = 6.2033
//  3rd moment/2nd moment = 7.93267
//
Constant kWhiteBeam_Mean = 5.3
//Constant kWhiteBeam_Mean = 5.7		// mean of lam^2
Constant kWhiteBeam_Normalization = 19933

Constant kSuperWhiteBeam_Mean = 6.2
//Constant kSuperWhiteBeam_Mean = 7.9		//mean of lam^2
Constant kSuperWhiteBeam_Normalization = 30955




Function V_WhiteBeamDist_top(lam)
	Variable lam
	
	if(lam < 3.37)
		return(0)
	endif
	
	if(lam < 3.69)
		return(-31013 + 9198*lam)
	endif
	
	if(lam < 3.84)
		return(23715 - 5649*lam)
	endif
	
//// the "middle" of the spikes	
//	if(lam < 4.12)
//		return(-84962 + 22634*lam)
//	endif
//	if(lam < 8.37)
//		return(-2336 + 11422*exp(-( (lam-3.043)/4.234 )^2))
//	endif

//// the "top" of the spikes
	if(lam < 4.16)
		return(-84962 + 22634*lam)
	endif
	if(lam < 8.25)
		return(-2336 + 12422*exp(-( (lam-3.043)/4.034 )^2))
	endif

//	 anything larger than 8.37, return 0	
	return(0)
	
End


Function V_WhiteBeamDist_mid(lam)
	Variable lam
	
	if(lam < 3.37)
		return(0)
	endif
	
	if(lam < 3.69)
		return(-31013 + 9198*lam)
	endif
	
	if(lam < 3.84)
		return(23715 - 5649*lam)
	endif
	
//// the "middle" of the spikes	
	if(lam < 4.12)
		return(-84962 + 22634*lam)
	endif
	if(lam < 8.37)
		return(-2336 + 11422*exp(-( (lam-3.043)/4.234 )^2))
	endif

////// the "top" of the spikes
//	if(lam < 4.16)
//		return(-84962 + 22634*lam)
//	endif
//	if(lam < 8.25)
//		return(-2336 + 12422*exp(-( (lam-3.043)/4.034 )^2))
//	endif

//	 anything larger than 8.37, return 0	
	return(0)
	
End

// this is not used - there is no improvement in the results when using the "full" shape of the 
// WB distribution.
Function V_WhiteBeamInterp(lam)
	Variable lam
	
	WAVE interp_lam = root:interp_lam
	WAVE interp_cts = root:interp_cts
	
	return(interp(lam,interp_lam,interp_cts))
End

// change the x-scaling of cts_for_mean to 3,9 (beg,end)
// 3309 is the average value of cts_for_mean
// cts_for_mean = interp_cts*x/3309
//
// gives an average wavelength of 5.302 A
// median ~ 5.97 A
//
Function V_WB_Mean()

	WAVE cts_for_mean
	Variable tot=sum(cts_for_mean)
	Variable ans
	
	cts_for_mean = cts_for_mean*x
	ans = sum(cts_for_mean)/tot
	
	return(ans)
End


// assumes that the counts and wavelength data for white and superWhite both are loaded and named:
//
// white_wavelength, counts_white
// super_white_wavelength, counts_super_white
//
//
Proc V_WB_Stats()

	duplicate/O counts_white cts_W, intg_W,intg_W3
	duplicate/O counts_super_white cts_SW intg_SW,intg_SW3

	Print "White Beam:"
	intg_W = cts_W*white_wavelength
	printf "mean wavelength = %g\r",sum(intg_W)/sum(cts_W)
	intg_W = cts_W*white_wavelength^2
//	printf "sqrt(wavelength^2)/N = %g\r",sqrt( sum(intg_W)/sum(cts_W) )
	intg_W3 = cts_W*white_wavelength^3
	printf "3rd moment/2nd moment = %g\r",sum(intg_W3)/sum(intg_W)

	Print
	Print "Super White Beam:"
	intg_SW = cts_SW*super_white_wavelength
	printf "mean wavelength = %g\r",sum(intg_SW)/sum(cts_SW)
	intg_SW = cts_SW*super_white_wavelength^2
//	printf "sqrt(wavelength^2)/N = %g\r",sqrt( sum(intg_SW)/sum(cts_SW) )
	intg_SW3 = cts_SW*super_white_wavelength^3
	printf "3rd moment/2nd moment = %g\r",sum(intg_SW3)/sum(intg_SW)
		
End

//
//
//
Function V_SuperWhiteBeamDist_mid(lam)
	Variable lam
	
	if(lam < 3.37)
		return(0)
	endif
	
	if(lam < 3.72)
		return(-33536 + 9919*lam)
	endif
	
	if(lam < 3.88)
		return(28941 - 6848*lam)
	endif
	
//// the "middle" of the spikes	
	if(lam < 4.16)
		return(-1.0111e5 + 26689*lam)
	endif
	
	if(lam < 20)
		return(5 - 10081*exp(-( (lam-4.161)/0.9788 )) + 19776*exp(-( (lam-4.161)/1.921 )) )
	endif

//	 anything larger than 20, return 0	
	return(0)
	
End


