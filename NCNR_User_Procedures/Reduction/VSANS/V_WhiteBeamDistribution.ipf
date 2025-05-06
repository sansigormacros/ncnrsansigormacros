#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 7.00


//
// this is an empirical representation of the White Beam wavelength
// distribution. 
//
// using the built-in Integrate function to find the normalization value
//
// integral = 20926 (cts*A) for "top"
// integral = 19933.2 (cts*A) for "middle"
// integration of interpolated data (100 pts) = 20051 (3 A to 9 A)
//
//
// As of 2021, both of the "middle" distributions have been normalized
// for use in models such that the integral of the distribution == 1
//
//


// 9/2019
// added an empirical functional form for the "Super" white beam mode where the deflector is out
// and the wavelength is not cut off at the higher wavelength, but extends to 20 Å
//
// Integral = 30969.7 (cts*A) for middle fit
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
Constant kWhiteBeam_Normalization = 19933.2

Constant kSuperWhiteBeam_Mean = 6.2
//Constant kSuperWhiteBeam_Mean = 7.9		//mean of lam^2
Constant kSuperWhiteBeam_Normalization = 30969.7



// functions to integrate the distributions and find the normalization constant
//
Proc V_FindWhiteBeamNormConst()

	make/O/D/N=1000 wb_dist_norm
	SetScale/I x 3,9,"", wb_dist_norm
	edit wb_dist_norm
	wb_dist_norm = V_WhiteBeamDist_mid(x)
	Integrate/METH=1 wb_dist_norm/D=wb_dist_norm_INT;DelayUpdate
	Display wb_dist_norm_INT
	Edit/K=0 root:wb_dist_norm_INT

End

Proc V_FindSuperWhiteBeamNormConst()

	make/O/D/N=1000 swb_dist_norm
	SetScale/I x 3,21,"", swb_dist_norm
	edit swb_dist_norm
	swb_dist_norm = V_SuperWhiteBeamDist_mid(x)
	Integrate/METH=1 swb_dist_norm/D=swb_dist_norm_INT;DelayUpdate
	Display swb_dist_norm_INT
	Edit/K=0 root:swb_dist_norm_INT

End


////////////////////////////////////


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


Function V_WhiteBeamDist_mid_noNorm(lam)
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


// normalized so that the integral over the full distribution
// 3 -> 9 == 1
//
Function V_WhiteBeamDist_mid(lam)
	Variable lam
	
	Variable cts
	Variable normVal = 19933.2
	
	if(lam < 3.37)
		return(0)
	endif
	
	if(lam < 3.69)
		cts = (-31013 + 9198*lam)
		return(cts/normVal)
	endif
	
	if(lam < 3.84)
		cts = (23715 - 5649*lam)
		return(cts/normVal)
	endif
	
//// the "middle" of the spikes	
	if(lam < 4.12)
		cts = (-84962 + 22634*lam)
		return(cts/normVal)
	endif
	if(lam < 8.37)
		cts = (-2336 + 11422*exp(-( (lam-3.043)/4.234 )^2))
		return(cts/normVal)
	endif

//	 anything larger than 8.37, return 0	
	return(0)
	
End


// this is not commonly used - there is no improvement in the results when using the "full" shape of the 
// WB distribution.
//
// This is normalized such that the integral over the fuul range == 1
Function V_WhiteBeamInterp(lam)
	Variable lam
	
	WAVE/Z interp_lam = root:interp_WB_lam
	WAVE/Z interp_cts = root:interp_WB_cts
	
	Variable normVal = 19933.2

	if(waveExists(interp_lam) == 0 || waveExists(interp_cts) == 0)
	 V_Generate_WB_Interp()
	endif
	return(interp(lam,interp_lam,interp_cts)/normVal)
End


// this is not commonly used - there is no improvement in the results when using the "full" shape of the 
// WB distribution.
Function V_WhiteBeamInterp_noNorm(lam)
	Variable lam
	
	WAVE/Z interp_lam = root:interp_WB_lam
	WAVE/Z interp_cts = root:interp_WB_cts
	
	Variable normVal = 19933.2

	if(waveExists(interp_lam) == 0 || waveExists(interp_cts) == 0)
	 V_Generate_WB_Interp()
	endif
	return(interp(lam,interp_lam,interp_cts)/normVal)
End


Function V_Generate_WB_Interp()

	Make/O/D/N=100 root:interp_WB_lam,root:interp_WB_cts
	WAVE interp_WB_cts = root:interp_WB_cts
	WAVE interp_WB_lam = root:interp_WB_lam
	
  interp_WB_cts[0]=219.059
  interp_WB_cts[1]=204.16
  interp_WB_cts[2]=145.543
  interp_WB_cts[3]=118.709
  interp_WB_cts[4]=172.299
  interp_WB_cts[5]=255.203
  interp_WB_cts[6]=305.602
  interp_WB_cts[7]=449.519
  interp_WB_cts[8]=963.3
  interp_WB_cts[9]=1668.17
  interp_WB_cts[10]=2129.16
  interp_WB_cts[11]=2715.4
  interp_WB_cts[12]=2637.07
  interp_WB_cts[13]=2225.27
  interp_WB_cts[14]=2597.76
  interp_WB_cts[15]=2662.17
  interp_WB_cts[16]=4451.42
  interp_WB_cts[17]=6744.41
  interp_WB_cts[18]=7836.93
  interp_WB_cts[19]=8795.85
  interp_WB_cts[20]=9056.34
  interp_WB_cts[21]=7828.57
  interp_WB_cts[22]=7274.92
  interp_WB_cts[23]=7969.56
  interp_WB_cts[24]=8580.31
  interp_WB_cts[25]=7807.89
  interp_WB_cts[26]=6954.5
  interp_WB_cts[27]=7390.27
  interp_WB_cts[28]=8146.84
  interp_WB_cts[29]=7607.02
  interp_WB_cts[30]=6795.04
  interp_WB_cts[31]=7528.92
  interp_WB_cts[32]=7413.98
  interp_WB_cts[33]=6524.71
  interp_WB_cts[34]=5816.85
  interp_WB_cts[35]=6183.68
  interp_WB_cts[36]=6375.91
  interp_WB_cts[37]=6715.06
  interp_WB_cts[38]=6306.77
  interp_WB_cts[39]=6043.84
  interp_WB_cts[40]=6151.76
  interp_WB_cts[41]=6212.56
  interp_WB_cts[42]=5903.78
  interp_WB_cts[43]=4902.08
  interp_WB_cts[44]=5044.97
  interp_WB_cts[45]=5197.64
  interp_WB_cts[46]=5484.09
  interp_WB_cts[47]=5413.29
  interp_WB_cts[48]=5475.61
  interp_WB_cts[49]=5255.06
  interp_WB_cts[50]=4968.42
  interp_WB_cts[51]=4602.78
  interp_WB_cts[52]=4175.84
  interp_WB_cts[53]=4325.76
  interp_WB_cts[54]=4200.91
  interp_WB_cts[55]=3414.45
  interp_WB_cts[56]=3390.32
  interp_WB_cts[57]=3486.88
  interp_WB_cts[58]=3513.63
  interp_WB_cts[59]=3464.58
  interp_WB_cts[60]=3470.07
  interp_WB_cts[61]=3283.49
  interp_WB_cts[62]=3108.43
  interp_WB_cts[63]=2924.7
  interp_WB_cts[64]=2756.05
  interp_WB_cts[65]=2641.58
  interp_WB_cts[66]=2438.82
  interp_WB_cts[67]=2265.7
  interp_WB_cts[68]=2023.65
  interp_WB_cts[69]=1859.63
  interp_WB_cts[70]=1772.39
  interp_WB_cts[71]=1745.91
  interp_WB_cts[72]=1559.28
  interp_WB_cts[73]=1401.19
  interp_WB_cts[74]=1380.11
  interp_WB_cts[75]=1320.64
  interp_WB_cts[76]=1109.51
  interp_WB_cts[77]=1029.03
  interp_WB_cts[78]=974.328
  interp_WB_cts[79]=841.589
  interp_WB_cts[80]=915.956
  interp_WB_cts[81]=663.914
  interp_WB_cts[82]=525.815
  interp_WB_cts[83]=492.609
  interp_WB_cts[84]=405.487
  interp_WB_cts[85]=341.389
  interp_WB_cts[86]=290.955
  interp_WB_cts[87]=242.051
  interp_WB_cts[88]=173.869
  interp_WB_cts[89]=152.381
  interp_WB_cts[90]=131.893
  interp_WB_cts[91]=104.25
  interp_WB_cts[92]=79.9002
  interp_WB_cts[93]=68.0749
  interp_WB_cts[94]=63.8355
  interp_WB_cts[95]=51.6343
  interp_WB_cts[96]=42.6738
  interp_WB_cts[97]=40.7977
  interp_WB_cts[98]=37.3535
  interp_WB_cts[99]=23.8824


  interp_WB_lam[0]=3
  interp_WB_lam[1]=3.06061
  interp_WB_lam[2]=3.12121
  interp_WB_lam[3]=3.18182
  interp_WB_lam[4]=3.24242
  interp_WB_lam[5]=3.30303
  interp_WB_lam[6]=3.36364
  interp_WB_lam[7]=3.42424
  interp_WB_lam[8]=3.48485
  interp_WB_lam[9]=3.54545
  interp_WB_lam[10]=3.60606
  interp_WB_lam[11]=3.66667
  interp_WB_lam[12]=3.72727
  interp_WB_lam[13]=3.78788
  interp_WB_lam[14]=3.84848
  interp_WB_lam[15]=3.90909
  interp_WB_lam[16]=3.9697
  interp_WB_lam[17]=4.0303
  interp_WB_lam[18]=4.09091
  interp_WB_lam[19]=4.15152
  interp_WB_lam[20]=4.21212
  interp_WB_lam[21]=4.27273
  interp_WB_lam[22]=4.33333
  interp_WB_lam[23]=4.39394
  interp_WB_lam[24]=4.45455
  interp_WB_lam[25]=4.51515
  interp_WB_lam[26]=4.57576
  interp_WB_lam[27]=4.63636
  interp_WB_lam[28]=4.69697
  interp_WB_lam[29]=4.75758
  interp_WB_lam[30]=4.81818
  interp_WB_lam[31]=4.87879
  interp_WB_lam[32]=4.93939
  interp_WB_lam[33]=5
  interp_WB_lam[34]=5.06061
  interp_WB_lam[35]=5.12121
  interp_WB_lam[36]=5.18182
  interp_WB_lam[37]=5.24242
  interp_WB_lam[38]=5.30303
  interp_WB_lam[39]=5.36364
  interp_WB_lam[40]=5.42424
  interp_WB_lam[41]=5.48485
  interp_WB_lam[42]=5.54545
  interp_WB_lam[43]=5.60606
  interp_WB_lam[44]=5.66667
  interp_WB_lam[45]=5.72727
  interp_WB_lam[46]=5.78788
  interp_WB_lam[47]=5.84848
  interp_WB_lam[48]=5.90909
  interp_WB_lam[49]=5.9697
  interp_WB_lam[50]=6.0303
  interp_WB_lam[51]=6.09091
  interp_WB_lam[52]=6.15152
  interp_WB_lam[53]=6.21212
  interp_WB_lam[54]=6.27273
  interp_WB_lam[55]=6.33333
  interp_WB_lam[56]=6.39394
  interp_WB_lam[57]=6.45455
  interp_WB_lam[58]=6.51515
  interp_WB_lam[59]=6.57576
  interp_WB_lam[60]=6.63636
  interp_WB_lam[61]=6.69697
  interp_WB_lam[62]=6.75758
  interp_WB_lam[63]=6.81818
  interp_WB_lam[64]=6.87879
  interp_WB_lam[65]=6.93939
  interp_WB_lam[66]=7
  interp_WB_lam[67]=7.06061
  interp_WB_lam[68]=7.12121
  interp_WB_lam[69]=7.18182
  interp_WB_lam[70]=7.24242
  interp_WB_lam[71]=7.30303
  interp_WB_lam[72]=7.36364
  interp_WB_lam[73]=7.42424
  interp_WB_lam[74]=7.48485
  interp_WB_lam[75]=7.54545
  interp_WB_lam[76]=7.60606
  interp_WB_lam[77]=7.66667
  interp_WB_lam[78]=7.72727
  interp_WB_lam[79]=7.78788
  interp_WB_lam[80]=7.84848
  interp_WB_lam[81]=7.90909
  interp_WB_lam[82]=7.9697
  interp_WB_lam[83]=8.0303
  interp_WB_lam[84]=8.09091
  interp_WB_lam[85]=8.15152
  interp_WB_lam[86]=8.21212
  interp_WB_lam[87]=8.27273
  interp_WB_lam[88]=8.33333
  interp_WB_lam[89]=8.39394
  interp_WB_lam[90]=8.45455
  interp_WB_lam[91]=8.51515
  interp_WB_lam[92]=8.57576
  interp_WB_lam[93]=8.63636
  interp_WB_lam[94]=8.69697
  interp_WB_lam[95]=8.75758
  interp_WB_lam[96]=8.81818
  interp_WB_lam[97]=8.87879
  interp_WB_lam[98]=8.93939
  interp_WB_lam[99]=9




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
Function V_SuperWhiteBeamDist_mid_noNorm(lam)
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

//
// Normalized so that the integral == 1
//
Function V_SuperWhiteBeamDist_mid(lam)
	Variable lam
	
	Variable cts
	Variable normVal = 30969.7
	if(lam < 3.37)
		return(0)
	endif
	
	if(lam < 3.72)
		cts = (-33536 + 9919*lam)
		return(cts/normVal)
	endif
	
	if(lam < 3.88)
		cts = (28941 - 6848*lam)
		return(cts/normVal)
	endif
	
//// the "middle" of the spikes	
	if(lam < 4.16)
		cts = (-1.0111e5 + 26689*lam)
		return(cts/normVal)
	endif
	
	if(lam < 20)
		cts = (5 - 10081*exp(-( (lam-4.161)/0.9788 )) + 19776*exp(-( (lam-4.161)/1.921 )) )
		return(cts/normVal)
	endif

//	 anything larger than 20, return 0	
	return(0)
	
End



