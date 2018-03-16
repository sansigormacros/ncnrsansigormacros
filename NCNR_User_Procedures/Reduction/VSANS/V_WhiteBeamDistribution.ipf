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
// gives an average wavelength of 5.302 A
// median ~ 5.97 A
//
//
// of the three choices, using the fit to the "top" of the distribution gives the best-looking
// result when compared to the AgBeh data
//
Function V_WhiteBeamDist(lam)
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

