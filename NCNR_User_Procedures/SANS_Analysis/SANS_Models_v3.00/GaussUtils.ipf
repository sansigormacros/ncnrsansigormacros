#pragma rtGlobals=1		// Use modern global access method.
#pragma version=3.00
#pragma IgorVersion=4.0

// GaussUtils.ipf
// 22dec97 SRK

//// NEW
// 
// added two utility functions to do numerical
// integration of an arbitrary function
// Gaussian quadrature of 20 or 76 points is used
//
// fcn must be defined as in the prototype function
// which is similar to the normal fitting function definition
//
// 09 SEP 03 SRK
//
//
// 04DEC03 - added routines for 5 and 10 Gauss points
//
// 13 DEC 04 BSG/SRK - Modified Smear_Model_(5)(20) to allow 
// smearing of USANS data. dQv is passed in as negative value
// in all resolution columns. the dQv value is read from the SigQ columnn
// (the 4th column) - and all values are read, so fill the whole column
//
// Adaptive trapezoidal integration is used, 76 Gauss pts
// did not give sufficient accuracy.
//

Function Make5GaussPoints(w5,z5)
	Wave w5,z5

//	printf  "in make Gauss Pts\r"

	z5[0] = -.906179845938664
	z5[1] = -.538469310105683
	z5[2] = -.0000000000000
	z5[3] = .538469310105683
	z5[4] = .906179845938664

	w5[0] = .236926885056189
	w5[1] = .478628670499366
	w5[2] = .56888888888889
	w5[3] = .478628670499366
	w5[4] = .236926885056189

//	    printf "w[0],z[0] = %g %g\r", w5[0],z5[0]
End

Function Make10GaussPoints(w10,z10)
	Wave w10,z10

//	printf  "in make Gauss Pts\r"
	z10[0] = -.973906528517172
	z10[1] = -.865063366688985
	z10[2] = -.679409568299024
	z10[3] = -.433395394129247
	z10[4] = -.148874338981631
	z10[5] = .148874338981631
	z10[6] = .433395394129247
	z10[7] = .679409568299024
	z10[8] = .865063366688985
	z10[9] = .973906528517172
	
	w10[0] = .066671344308688
	w10[1] = 0.149451349150581
	w10[2] = 0.219086362515982
	w10[3] = .269266719309996
	w10[4] = 0.295524224714753
	w10[5] = 0.295524224714753
	w10[6] = .269266719309996
	w10[7] = 0.219086362515982
	w10[8] = 0.149451349150581
	w10[9] = .066671344308688
	
//	    printf "w[0],z[0] = %g %g\r", w10[0],z10[0]
End

Function Make20GaussPoints(w20,z20)
	Wave w20,z20

//	printf  "in make Gauss Pts\r"

	 z20[0] = -.993128599185095
	 z20[1] =  -.963971927277914
	 z20[2] =    -.912234428251326
	 z20[3] =    -.839116971822219
	 z20[4] =   -.746331906460151
	 z20[5] =   -.636053680726515
	 z20[6] =   -.510867001950827
	 z20[7] =     -.37370608871542
	 z20[8] =     -.227785851141645
	 z20[9] =     -.076526521133497
	 z20[10] =     .0765265211334973
	 z20[11] =     .227785851141645
	 z20[12] =     .37370608871542
	 z20[13] =     .510867001950827
	 z20[14] =     .636053680726515
	 z20[15] =     .746331906460151
	 z20[16] =     .839116971822219
	 z20[17] =     .912234428251326
	 z20[18] =    .963971927277914
	 z20[19] =  .993128599185095 
	    
	w20[0] =  .0176140071391521
	w20[1] =  .0406014298003869
	w20[2] =      .0626720483341091
	w20[3] =      .0832767415767047
	w20[4] =     .10193011981724
	w20[5] =      .118194531961518
	w20[6] =      .131688638449177
	w20[7] =      .142096109318382
	w20[8] =      .149172986472604
	w20[9] =      .152753387130726
	w20[10] =      .152753387130726
	w20[11] =      .149172986472604
	w20[12] =      .142096109318382
	w20[13] =     .131688638449177
	w20[14] =     .118194531961518
	w20[15] =     .10193011981724
	w20[16] =     .0832767415767047
	w20[17] =     .0626720483341091
	w20[18] =     .0406014298003869
	w20[19] =     .0176140071391521
//	    printf "w[0],z[0] = %g %g\r", w20[0],z20[0]
End




Function Make76GaussPoints(w76,z76)
	Wave w76,z76

//	printf  "in make Gauss Pts\r"
	
     		z76[0] = .999505948362153*(-1.0)
	    z76[75] = -.999505948362153*(-1.0)
	    z76[1] = .997397786355355*(-1.0)
	    z76[74] = -.997397786355355*(-1.0)
	    z76[2] = .993608772723527*(-1.0)
	    z76[73] = -.993608772723527*(-1.0)
	    z76[3] = .988144453359837*(-1.0)
	    z76[72] = -.988144453359837*(-1.0)
	    z76[4] = .981013938975656*(-1.0)
	    z76[71] = -.981013938975656*(-1.0)
	    z76[5] = .972229228520377*(-1.0)
	    z76[70] = -.972229228520377*(-1.0)
	    z76[6] = .961805126758768*(-1.0)
	    z76[69] = -.961805126758768*(-1.0)
	    z76[7] = .949759207710896*(-1.0)
	    z76[68] = -.949759207710896*(-1.0)
	    z76[8] = .936111781934811*(-1.0)
	    z76[67] = -.936111781934811*(-1.0)
	    z76[9] = .92088586125215*(-1.0)
	    z76[66] = -.92088586125215*(-1.0)
	    z76[10] = .904107119545567*(-1.0)
	    z76[65] = -.904107119545567*(-1.0)
	    z76[11] = .885803849292083*(-1.0)
	    z76[64] = -.885803849292083*(-1.0)
	    z76[12] = .866006913771982*(-1.0)
	    z76[63] = -.866006913771982*(-1.0)
	    z76[13] = .844749694983342*(-1.0)
	    z76[62] = -.844749694983342*(-1.0)
	    z76[14] = .822068037328975*(-1.0)
	    z76[61] = -.822068037328975*(-1.0)
	    z76[15] = .7980001871612*(-1.0)
	    z76[60] = -.7980001871612*(-1.0)
	    z76[16] = .77258672828181*(-1.0)
	    z76[59] = -.77258672828181*(-1.0)
	    z76[17] = .74587051350361*(-1.0)
	    z76[58] = -.74587051350361*(-1.0)
	    z76[18] = .717896592387704*(-1.0)
	    z76[57] = -.717896592387704*(-1.0)
	    z76[19] = .688712135277641*(-1.0)
	    z76[56] = -.688712135277641*(-1.0)
	    z76[20] = .658366353758143*(-1.0)
	    z76[55] = -.658366353758143*(-1.0)
	    z76[21] = .626910417672267*(-1.0)
	    z76[54] = -.626910417672267*(-1.0)
	    z76[22] = .594397368836793*(-1.0)
	    z76[53] = -.594397368836793*(-1.0)
	    z76[23] = .560882031601237*(-1.0)
	    z76[52] = -.560882031601237*(-1.0)
	    z76[24] = .526420920401243*(-1.0)
	    z76[51] = -.526420920401243*(-1.0)
	    z76[25] = .491072144462194*(-1.0)
	    z76[50] = -.491072144462194*(-1.0)
	    z76[26] = .454895309813726*(-1.0)
	    z76[49] = -.454895309813726*(-1.0)
	    z76[27] = .417951418780327*(-1.0)
	    z76[48] = -.417951418780327*(-1.0)
	    z76[28] = .380302767117504*(-1.0)
	    z76[47] = -.380302767117504*(-1.0)
	    z76[29] = .342012838966962*(-1.0)
	    z76[46] = -.342012838966962*(-1.0)
	    z76[30] = .303146199807908*(-1.0)
	    z76[45] = -.303146199807908*(-1.0)
	    z76[31] = .263768387584994*(-1.0)
	    z76[44] = -.263768387584994*(-1.0)
	    z76[32] = .223945802196474*(-1.0)
	    z76[43] = -.223945802196474*(-1.0)
	    z76[33] = .183745593528914*(-1.0)
	    z76[42] = -.183745593528914*(-1.0)
	    z76[34] = .143235548227268*(-1.0)
	    z76[41] = -.143235548227268*(-1.0)
	    z76[35] = .102483975391227*(-1.0)
	    z76[40] = -.102483975391227*(-1.0)
	    z76[36] = .0615595913906112*(-1.0)
	    z76[39] = -.0615595913906112*(-1.0)
	    z76[37] = .0205314039939986*(-1.0)
	    z76[38] = -.0205314039939986*(-1.0)
	    
		w76[0] =  .00126779163408536
		w76[75] = .00126779163408536
		w76[1] =  .00294910295364247
	    w76[74] = .00294910295364247
	    w76[2] = .00462793522803742
	    w76[73] =  .00462793522803742
	    w76[3] = .00629918049732845
	    w76[72] = .00629918049732845
	    w76[4] = .00795984747723973
	    w76[71] = .00795984747723973
	    w76[5] = .00960710541471375
	    w76[70] =  .00960710541471375
	    w76[6] = .0112381685696677
	    w76[69] = .0112381685696677
	    w76[7] =  .0128502838475101
	    w76[68] = .0128502838475101
	    w76[8] = .0144407317482767
	    w76[67] =  .0144407317482767
	    w76[9] = .0160068299122486
	    w76[66] = .0160068299122486
	    w76[10] = .0175459372914742
	    w76[65] = .0175459372914742
	    w76[11] = .0190554584671906
	    w76[64] = .0190554584671906
	    w76[12] = .020532847967908
	    w76[63] = .020532847967908
	    w76[13] = .0219756145344162
	    w76[62] = .0219756145344162
	    w76[14] = .0233813253070112
	    w76[61] = .0233813253070112
	    w76[15] = .0247476099206597
	    w76[60] = .0247476099206597
	    w76[16] = .026072164497986
	    w76[59] = .026072164497986
	    w76[17] = .0273527555318275
	    w76[58] = .0273527555318275
	    w76[18] = .028587223650054
	    w76[57] = .028587223650054
	    w76[19] = .029773487255905
	    w76[56] = .029773487255905
	    w76[20] = .0309095460374916
	    w76[55] = .0309095460374916
	    w76[21] = .0319934843404216
	    w76[54] = .0319934843404216
	    w76[22] = .0330234743977917
	    w76[53] = .0330234743977917
	    w76[23] = .0339977794120564
	    w76[52] = .0339977794120564
	    w76[24] = .0349147564835508
	    w76[51] = .0349147564835508
	    w76[25] = .0357728593807139
	    w76[50] = .0357728593807139
	    w76[26] = .0365706411473296
	    w76[49] = .0365706411473296
	    w76[27] = .0373067565423816
	    w76[48] = .0373067565423816
	    w76[28] = .0379799643084053
	    w76[47] = .0379799643084053
	    w76[29] = .0385891292645067
	    w76[46] = .0385891292645067
	    w76[30] = .0391332242205184
	    w76[45] = .0391332242205184
	    w76[31] = .0396113317090621
	    w76[44] = .0396113317090621
	    w76[32] = .0400226455325968
	    w76[43] = .0400226455325968
	    w76[33] = .040366472122844
	    w76[42] = .040366472122844
	    w76[34] = .0406422317102947
	    w76[41] = .0406422317102947
	    w76[35] = .0408494593018285
	    w76[40] = .0408494593018285
	    w76[36] = .040987805464794
	    w76[39] = .040987805464794
	    w76[37] = .0410570369162294
	    w76[38] = .0410570369162294

End		//Make76GaussPoints()

////////////
Function IntegrateFn5(fcn,loLim,upLim,w,x)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

// local variables
	Variable nord,ii,va,vb,summ,yyy,zi
	Variable answer,dum
	String weightStr,zStr
	
	weightStr = "gauss5wt"
	zStr = "gauss5z"
	nord = 5
		
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=5 $weightStr,$zStr
		Wave w5 = $weightStr
		Wave z5 = $zStr		// wave references to pass
		Make5GaussPoints(w5,z5)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w5 = $weightStr
		Wave z5 = $zStr		// create the wave references
	endif

	//limits of integration are input to function
	va = loLim
	vb = upLim
	// Using 5 Gauss points		    
	// remember to index from 0,size-1

	summ = 0.0		// initialize integral
	ii=0			// loop counter
	do
		// calculate Gauss points on integration interval (q-value for evaluation)
		zi = ( z5[ii]*(vb-va) + vb + va )/2.0
		//calculate partial sum for the passed-in model function	
		yyy = w5[ii] *  fcn(w,x,zi)						
		summ += yyy		//add to the running total of the quadrature
       	ii+=1     	
	while (ii<nord)				// end of loop over quadrature points
   
	// calculate value of integral to return
	answer = (vb-va)/2.0*summ

	Return (answer)
End
///////////////////////////////////////////////////////////////

////////////
Function IntegrateFn10(fcn,loLim,upLim,w,x)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

// local variables
	Variable nord,ii,va,vb,summ,yyy,zi
	Variable answer,dum
	String weightStr,zStr
	
	weightStr = "gauss10wt"
	zStr = "gauss10z"
	nord = 10
		
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=10 $weightStr,$zStr
		Wave w10 = $weightStr
		Wave z10 = $zStr		// wave references to pass
		Make10GaussPoints(w10,z10)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w10 = $weightStr
		Wave z10 = $zStr		// create the wave references
	endif

	//limits of integration are input to function
	va = loLim
	vb = upLim
	// Using 10 Gauss points		    
	// remember to index from 0,size-1

	summ = 0.0		// initialize integral
	ii=0			// loop counter
	do
		// calculate Gauss points on integration interval (q-value for evaluation)
		zi = ( z10[ii]*(vb-va) + vb + va )/2.0
		//calculate partial sum for the passed-in model function	
		yyy = w10[ii] *  fcn(w,x,zi)						
		summ += yyy		//add to the running total of the quadrature
       	ii+=1     	
	while (ii<nord)				// end of loop over quadrature points
   
	// calculate value of integral to return
	answer = (vb-va)/2.0*summ

	Return (answer)
End
///////////////////////////////////////////////////////////////

////////////
Function IntegrateFn20(fcn,loLim,upLim,w,x)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

// local variables
	Variable nord,ii,va,vb,summ,yyy,zi
	Variable answer,dum
	String weightStr,zStr
	
	weightStr = "gauss20wt"
	zStr = "gauss20z"
	nord = 20
		
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=20 $weightStr,$zStr
		Wave w20 = $weightStr
		Wave z20 = $zStr		// wave references to pass
		Make20GaussPoints(w20,z20)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w20 = $weightStr
		Wave z20 = $zStr		// create the wave references
	endif

	//limits of integration are input to function
	va = loLim
	vb = upLim
	// Using 20 Gauss points		    
	// remember to index from 0,size-1

	summ = 0.0		// initialize integral
	ii=0			// loop counter
	do
		// calculate Gauss points on integration interval (q-value for evaluation)
		zi = ( z20[ii]*(vb-va) + vb + va )/2.0
		//calculate partial sum for the passed-in model function	
		yyy = w20[ii] *  fcn(w,x,zi)						
		summ += yyy		//add to the running total of the quadrature
       	ii+=1     	
	while (ii<nord)				// end of loop over quadrature points
   
	// calculate value of integral to return
	answer = (vb-va)/2.0*summ

	Return (answer)
End
///////////////////////////////////////////////////////////////

Function IntegrateFn76(fcn,loLim,upLim,w,x)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

//**** The coefficient wave is passed into this function and straight through to the unsmeared model function

// local variables
	Variable nord,ii,va,vb,summ,yyy,zi
	Variable answer,dum
	String weightStr,zStr
	
	weightStr = "gauss76wt"
	zStr = "gauss76z"
	nord = 76
		
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=76 $weightStr,$zStr
		Wave w76 = $weightStr
		Wave z76 = $zStr		// wave references to pass
		Make76GaussPoints(w76,z76)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w76 = $weightStr
		Wave z76 = $zStr		// create the wave references
	endif

	//limits of integration are input to function
	va = loLim
	vb = upLim
	// Using 76 Gauss points		    
	// remember to index from 0,size-1

	summ = 0.0		// initialize integral
	ii=0			// loop counter
	do
		// calculate Gauss points on integration interval (q-value for evaluation)
		zi = ( z76[ii]*(vb-va) + vb + va )/2.0
		//calculate partial sum for the passed-in model function	
		yyy = w76[ii] *  fcn(w,x,zi)						
		summ += yyy		//add to the running total of the quadrature
     ii+=1     	
	while (ii<nord)				// end of loop over quadrature points
   
	// calculate value of integral to return
	answer = (vb-va)/2.0*summ

	Return (answer)
End
///////////////////////////////////////////////////////////////

//////Resolution Smearing Utilities

// To check for the existence of all waves needed for smearing
// returns 1 if any waves are missing, 0 if all is OK
Function ResolutionWavesMissing()

	SVAR/Z sq = gSig_Q
	SVAR/Z qb = gQ_bar
	SVAR/Z sh = gShadow
	SVAR/Z gQ = gQVals
	
	Variable err=0
	if(!SVAR_Exists(sq) || !SVAR_Exists(qb) || !SVAR_Exists(sh) || !SVAR_Exists(gQ))
		DoAlert 0,"Some 6-column QSIG waves are missing. Re-load experimental data with LoadOneDData macro"
		return(1)
	endif
	
	if(WaveExists($sq) == 0)	//wave ref does not exist
		err=1
	endif
	if(WaveExists($qb) == 0)	//wave ref does not exist
		err=1
	endif
	if(WaveExists($sh) == 0)	//wave ref does not exist
		err=1
	endif
	if(WaveExists($gQ) == 0)	//wave ref does not exist
		err=1
	endif
	
	if(err)
		DoAlert 0,"Some 6-column QSIG waves are missing. Re-load experimental data with LoadOneDData macro"
	endif
	
	return(err)
end


//Utility function to smear model function with resolution
//
// call as in this example...
//
////Function SmearedSphere_HS(w,x) :FitFunc
////	Wave w
////	Variable x
////	
//////	Variable timer=StartMSTimer
////	Variable ans
////	SVAR sq = gSig_Q
////	SVAR qb = gQ_bar
////	SVAR sh = gShadow
////	SVAR gQ = gQVals
////	
////	ans = Smear_Model_20(Sphere_HS,$sq,$qb,$sh,$gQ,w,x)	
////
//////	Print "HS elapsed time(s) = ",StopMSTimer(timer)*1e-6
////	return(ans)
////End
//
//

Function Smear_Model_76(fcn,sigq,qbar,shad,qvals,w,x)				
	FUNCREF SANSModel_proto fcn
	Wave sigq		//std dev of resolution fn
	Wave qbar		//mean q-value
	Wave shad		//beamstop shadow factor
	Wave qvals	//q-values where R(q) is known
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

//**** The coefficient wave is passed into this function and straight through to the unsmeared model function

// local variables
	Variable nord,ii,va,vb,contr,nden,summ,yyy,zi,q
	Variable answer,Resoln,i_shad,i_qbar,i_sigq
	String weightStr,zStr,weightStr1,zStr1
	
//	weightStr = "gauss20wt"
//	zStr = "gauss20z"
	weightStr = "gauss76wt"
	zStr = "gauss76z"
	
//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
// 20 Gauss points (enough for smearing with Gaussian resolution function)
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=76 $weightStr,$zStr
		Wave w76 = $weightStr
		Wave z76 = $zStr		// wave references to pass
		Make76GaussPoints(w76,z76)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w76 = $weightStr
		Wave z76 = $zStr		// create the wave references
	endif
	
		// current x point is the q-value for evaluation
		//
		// * for the input x, the resolution function waves are interpolated to get the correct values for
		//  sigq, qbar and shad - since the model x-spacing may not be the same as
		// the experimental QSIG data. This is always the case when curve fitting, since fit_wave is 
		// Igor-defined as 200 points and has its own (linear) q-(x)-scaling which will be quite different
		// from experimental data.
		// **note** if the (x) passed in is the experimental q-values, these values are
		// returned from the interpolation (as expected)

	i_shad = interp(x,qvals,shad)
	i_qbar = interp(x,qvals,qbar)
	i_sigq = interp(x,qvals,sigq)
			
		// set up the integration
		// number of Gauss Quadrature points
		
	if (i_sigq >= 0)
		
		// end points of integration
		// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
		// +/- 3 sigq catches 99.73% of distrubution
		// change limits (and spacing of zi) at each evaluation based on R()
		//integration from va to vb
	
		nord = 76
		va = -3*i_sigq + i_qbar
		if (va<0)
			va=0		//to avoid numerical error when  va<0 (-ve q-value)
//			Print "truncated Gaussian at nominal q = ",x
		endif
		vb = 3*i_sigq + i_qbar
		
		// Using 20 Gauss points		    
		// remember to index from 0,size-1

   		summ = 0.0		// initialize integral
		ii=0			// loop counter
		do
			// calculate Gauss points on integration interval (q-value for evaluation)
			zi = ( z76[ii]*(vb-va) + vb + va )/2.0
			// calculate resolution function at input q-value (use the interpolated values and zi)
			Resoln = i_shad/sqrt(2*pi*i_sigq*i_sigq)
			Resoln *= exp((-1*(zi - i_qbar)^2)/(2*i_sigq*i_sigq))
			//calculate partial sum for the passed-in model function	
			yyy = w76[ii] * Resoln * fcn(w,zi)						
			summ += yyy		//add to the running total of the quadrature
      			 ii+=1     	
		while (ii<nord)				// end of loop over quadrature points
   
		// calculate value of integral to return
   		answer = (vb-va)/2.0*summ
   		// all scaling, background addition... etc. is done in the model calculation
	
	else
		//smear with the USANS routine
		// Make global string and local variables
		// now data folder aware, necessary for GlobalFit = FULL path to wave	
		String/G gTrap_coefStr = GetWavesDataFolder(w, 2 )	
		Variable maxiter=20, tol=1e-4
		
		// set up limits for the integration
		va=0
		vb=abs(i_sigq)
		
		Variable/G gEvalQval = x
		
		// call qtrap to do actual work
		answer = qtrap_USANS(fcn,va,vb,tol,maxiter)
		answer /= vb
		
	endif
	
	Return (answer)
	
End
///////////////////////////////////////////////////////////////

Function Smear_Model_20(fcn,sigq,qbar,shad,qvals,w,x)				
	FUNCREF SANSModel_proto fcn
	Wave sigq		//std dev of resolution fn
	Wave qbar		//mean q-value
	Wave shad		//beamstop shadow factor
	Wave qvals	//q-values where R(q) is known
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

//**** The coefficient wave is passed into this function and straight through to the unsmeared model function

// local variables
	Variable nord,ii,va,vb,contr,nden,summ,yyy,zi,q
	Variable answer,Resoln,i_shad,i_qbar,i_sigq
	String weightStr,zStr,weightStr1,zStr1
	
	weightStr = "gauss20wt"
	zStr = "gauss20z"
	weightStr1 = "gauss76wt"
	zStr1 = "gauss76z"
	
//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
// 20 Gauss points (enough for smearing with Gaussian resolution function)
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=20 $weightStr,$zStr
		Wave w20 = $weightStr
		Wave z20 = $zStr		// wave references to pass
		Make20GaussPoints(w20,z20)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w20 = $weightStr
		Wave z20 = $zStr		// create the wave references
	endif
	
		// current x point is the q-value for evaluation
		//
		// * for the input x, the resolution function waves are interpolated to get the correct values for
		//  sigq, qbar and shad - since the model x-spacing may not be the same as
		// the experimental QSIG data. This is always the case when curve fitting, since fit_wave is 
		// Igor-defined as 200 points and has its own (linear) q-(x)-scaling which will be quite different
		// from experimental data.
		// **note** if the (x) passed in is the experimental q-values, these values are
		// returned from the interpolation (as expected)

	i_shad = interp(x,qvals,shad)
	i_qbar = interp(x,qvals,qbar)
	i_sigq = interp(x,qvals,sigq)
			
		// set up the integration
		// number of Gauss Quadrature points
		
	if (i_sigq >= 0)
		
		// end points of integration
		// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
		// +/- 3 sigq catches 99.73% of distrubution
		// change limits (and spacing of zi) at each evaluation based on R()
		//integration from va to vb
	
		nord = 20
		va = -3*i_sigq + i_qbar
		if (va<0)
			va=0		//to avoid numerical error when  va<0 (-ve q-value)
//			Print "truncated Gaussian at nominal q = ",x
		endif
		vb = 3*i_sigq + i_qbar
		
		// Using 20 Gauss points		    
		// remember to index from 0,size-1

   		summ = 0.0		// initialize integral
		ii=0			// loop counter
		do
			// calculate Gauss points on integration interval (q-value for evaluation)
			zi = ( z20[ii]*(vb-va) + vb + va )/2.0
			// calculate resolution function at input q-value (use the interpolated values and zi)
			Resoln = i_shad/sqrt(2*pi*i_sigq*i_sigq)
			Resoln *= exp((-1*(zi - i_qbar)^2)/(2*i_sigq*i_sigq))
			//calculate partial sum for the passed-in model function	
			yyy = w20[ii] * Resoln * fcn(w,zi)						
			summ += yyy		//add to the running total of the quadrature
      			 ii+=1     	
		while (ii<nord)				// end of loop over quadrature points
   
		// calculate value of integral to return
   		answer = (vb-va)/2.0*summ
   		// all scaling, background addition... etc. is done in the model calculation
	
	else
		//smear with the USANS routine
		// Make global string and local variables
		// now data folder aware, necessary for GlobalFit = FULL path to wave	
		String/G gTrap_coefStr = GetWavesDataFolder(w, 2 )	
		Variable maxiter=20, tol=1e-4
		
		// set up limits for the integration
		va=0
		vb=abs(i_sigq)
		
		Variable/G gEvalQval = x
		
		// call qtrap to do actual work
		answer = qtrap_USANS(fcn,va,vb,tol,maxiter)
		answer /= vb
		
	endif
	
	Return (answer)
	
End
///////////////////////////////////////////////////////////////


//resolution smearing, using only 5 Gauss points
//
Function Smear_Model_5(fcn,sigq,qbar,shad,qvals,w,x)				
	FUNCREF SANSModel_proto fcn
	Wave sigq		//std dev of resolution fn
	Wave qbar		//mean q-value
	Wave shad		//beamstop shadow factor
	Wave qvals	//q-values where R(q) is known
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation

//**** The coefficient wave is passed into this function and straight through to the unsmeared model function

// local variables
	Variable nord,ii,va,vb,contr,nden,summ,yyy,zi,q
	Variable answer,Resoln,i_shad,i_qbar,i_sigq
	String weightStr,zStr
	
	weightStr = "gauss5wt"
	zStr = "gauss5z"
	
//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
// 5 Gauss points 
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=5 $weightStr,$zStr
		Wave w5 = $weightStr
		Wave z5 = $zStr		// wave references to pass
		Make5GaussPoints(w5,z5)	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave w5 = $weightStr
		Wave z5 = $zStr		// create the wave references
	endif
	
// current x point is the q-value for evaluation
//
// * for the input x, the resolution function waves are interpolated to get the correct values for
//  sigq, qbar and shad - since the model x-spacing may not be the same as
// the experimental QSIG data. This is always the case when curve fitting, since fit_wave is 
// Igor-defined as 200 points and has its own (linear) q-(x)-scaling which will be quite different
// from experimental data.
// **note** if the (x) passed in is the experimental q-values, these values are
// returned from the interpolation (as expected)

	i_shad = interp(x,qvals,shad)
	i_qbar = interp(x,qvals,qbar)
	i_sigq = interp(x,qvals,sigq)
	
	if (i_sigq>=0)
		// set up the integration
		// number of Gauss Quadrature points
		nord = 5
		
		// end points of integration
		// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
		// +/- 3 sigq catches 99.73% of distrubution
		// change limits (and spacing of zi) at each evaluation based on R()
		//integration from va to vb
		va = -3*i_sigq + i_qbar
		if (va<0)
			va=0		//to avoid numerical error when  va<0 (-ve q-value)
		endif
		vb = 3*i_sigq + i_qbar
		// Using 5 Gauss points		    
		// remember to index from 0,size-1
	
	   summ = 0.0		// initialize integral
	   ii=0			// loop counter
	   do
			// calculate Gauss points on integration interval (q-value for evaluation)
			zi = ( z5[ii]*(vb-va) + vb + va )/2.0
			// calculate resolution function at input q-value (use the interpolated values and zi)
			Resoln = i_shad/sqrt(2*pi*i_sigq*i_sigq)
			Resoln *= exp((-1*(zi - i_qbar)^2)/(2*i_sigq*i_sigq))
			//calculate partial sum for the passed-in model function	
			yyy = w5[ii] * Resoln * fcn(w,zi)						
			summ += yyy		//add to the running total of the quadrature
	       ii+=1     	
		while (ii<nord)				// end of loop over quadrature points
	   
		// calculate value of integral to return
	   answer = (vb-va)/2.0*summ
	   // all scaling, background addition... etc. is done in the model calculation
	
	else
		// smear with the USANS routine
		// Make global string and local variables
		// now data folder aware, necessary for GlobalFit = FULL path to wave	
		String/G gTrap_coefStr = GetWavesDataFolder(w, 2 )
		Variable maxiter=10, tol=1e-2
		
		// set up limits for the integration
		va=0
		vb=abs(i_sigq)
		
		Variable/G gEvalQval = x
		
		// call qtrap to do actual work
		answer = qtrap_USANS(fcn,va,vb,tol,maxiter)
		answer /= vb
	
	endif

	Return (answer)
	
End
///////////////////////////////////////////////////////////////

Function GenericQuadrature_proto(w,x,dum)
	Wave w
	Variable x,dum
	
	Print "in GenericQuadrature_proto function"
	return(1)
end

// prototype function for smearing routines, Smear_Model_N
// and trapzd_USANS() and qtrap_USANS()
// it intentionally does nothing
Function SANSModel_proto(w,x)
	Wave w
	Variable x
	
	Print "in SANSModel_proto function"
	return(1)
end

//Numerical Recipes routine to calculate the nn(th) stage
//refinement of a trapezoid integration
//
//must be called sequentially from nn=1...n from qtrap()
// to cumulatively refine the integration value
//
// in the conversion:
// -- s was replaced with sVal and declared global (rather than static)
//  so that the nn-1 value would be available during the nn(th) call
//
// -- the specific coefficient wave for func() is passed in as a
//  global string (then converted to a wave reference), since
//  func() will eventually call sphereForm()
//
Function trapzd_USANS(fcn,aa,bb,nn)
	FUNCREF SANSModel_proto fcn
	Variable aa,bb,nn
	
	Variable xx,tnm,summ,del
	Variable it,jj,arg1,arg2
	NVAR sVal=sVal		//calling function must initialize this global
	NVAR qval = gEvalQval
	SVAR cwStr = gTrap_CoefStr		//pass in the coefficient wave (string)
	Wave cw=$cwStr			
	Variable temp=0
	if(nn==1)
		arg1 = qval^2 + aa^2
	  	arg2 = qval^2 + bb^2
		temp = 0.5*(bb-aa)*(fcn(cw,sqrt(arg1)) + fcn(cw,sqrt(arg2)))
		sval = temp
		return(sVal)
	else
		it=1
		it= 2^(nn-2)  //done in NR with a bit shift <<=
		tnm = it
		del = (bb - aa)/tnm		//this is the spacing of points to add
		xx = aa+0.5*del
		summ=0
		for(jj=1;jj<=it;jj+=1)
			arg1 = qval^2 + xx^2
			summ += fcn(cw,sqrt(arg1))
			xx += del
		endfor
		sval = 0.5*(sval+(bb-aa)*summ/tnm)	//replaces sval with its refined value
		return (sval)
	endif
	
End


// Numerical Recipes routine to calculate the integral of a
// specified function, trapezoid rule is used to a user-specified
// level of refinement using sequential calls to trapzd()
//
// in NR, eps and maxIt were global, pass them in here...
// eps typically 1e-5
// maxit typically 20
Function qtrap_USANS(fcn,aa,bb,eps,maxIt)
	FUNCREF SANSModel_proto fcn
	Variable aa,bb,eps,maxit
	
	Variable/G sVal=0		//create and initialize what trapzd will return
	Variable jj,ss,olds
	
	olds = -1e30		//any number that is not the avg. of endpoints of the funciton
	for(jj=1;jj<=maxit;jj+=1)	//call trapzd() repeatedly until convergence
		ss = trapzd_USANS(fcn,aa,bb,jj)
		if( abs(ss-olds) < eps*abs(olds) )		// good enough, stop now
			return ss
		endif
		if( (ss == 0.0) && (olds == 0.0) && (jj>6) )		//no progress?
			return ss
		endif
		olds = ss
	endfor

	Print "Maxit exceeded in qtrap. If you're here, there was an error in qtrap"
	return(ss)		//should never get here if function is well-behaved
	
End	

Proc RRW()
	ResetResolutionWaves()
End

//utility procedures that are currently untied to any actions, although useful...
Proc ResetResolutionWaves(str)
	String Str
	Prompt str,"Pick the intensity wave with the resolution you want",popup,WaveList("*_i",";","")
	
	String/G root:gQvals = str[0,strlen(str)-3]+"_q"
	String/G root:gSig_Q = str[0,strlen(str)-3]+"sq"
	String/G root:gQ_bar = str[0,strlen(str)-3]+"qb"
	String/G root:gShadow = str[0,strlen(str)-3]+"fs"
	

	
	//touch everything to make sure that the dependencies are
	//properly updated - especially the $gQvals reference in the 
	// dependency assignment
	fKillDependencies("Smear*")
	
	//replace the q-values and intensity (so they're the right length)
	fResetSmearedModels("Smear*",root:gQvals)
	
	fRestoreDependencies("Smear*")
End

// pass "*" as the matchString to do ALL dependent waves
// or "abc*" to get just the matching waves
//
Function fKillDependencies(matchStr)
	String matchStr

	String str=WaveList(matchStr, ";", "" ),item,formula
	Variable ii
	
	for(ii=0;ii<ItemsInList(str ,";");ii+=1)
		item = StringFromList(ii, str ,";")
		formula = GetFormula($item)
		if(cmpstr("",formula)!=0)
			Printf "wave %s had the formula %s removed\r",item,formula
			Note $item, "FORMULA:"+formula
			SetFormula $item, ""			//clears the formula
		endif
	endfor
	return(0)
end

// pass "*" as the matchString to do ALL dependent waves
// or "abc*" to get just the matching waves
//
Function fRestoreDependencies(matchStr)
	String matchStr

	String str=WaveList(matchStr, ";", "" ),item,formula
	Variable ii
	
	for(ii=0;ii<ItemsInList(str ,";");ii+=1)
		item = StringFromList(ii, str ,";")
		formula = StringByKey("FORMULA", note($item),":",";")
		if(cmpstr("",formula)!=0)
			Printf "wave %s had the formula %s restored\r",item,formula
			Note/K $item
			SetFormula $item, formula			//restores the formula
		endif
	endfor
	return(0)
end

Function fResetSmearedModels(matchStr,qStr)
	String matchStr,qStr

	Duplicate/O $qStr root:smeared_qvals	
	
	String str=WaveList(matchStr, ";", "" ),item,formula
	Variable ii
	
	for(ii=0;ii<ItemsInList(str ,";");ii+=1)
		item = StringFromList(ii, str ,";")
		formula = StringByKey("FORMULA", note($item),":",";")
		if(cmpstr("",formula)!=0)
			Printf "wave %s has been duplicated to gQvals\r",item
			Duplicate/O $qStr $item
			Note $item, "FORMULA:"+formula		//be sure to keep the formula note
			Print "   and the formula is",formula
		endif
	endfor
	return(0)
end