#pragma rtGlobals=1		// Use modern global access method.
#pragma version=4.00
#pragma IgorVersion=6.1

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
////////////////////////////////////////////////
// 23 JUL 2007 SRK
// major overhaul to use AAO functions in the smearing calculations
//
// - re-definition of function prototype in Smear_Model_N
// - re-definition in trapezoidal routines too
// - calls from model functions are somewhat different, so this will generate a lot of errors
//   until all can be changed
// - now is looking for a resolution matrix that contains the 3 resolution waves plus Q
// = mat[num_Qvals][0] = sigQ
// = mat[num_Qvals][1] = Qbar
// = mat[num_Qvals][2] = fShad
// = mat[num_Qvals][3] = qvals
//
// -- does not yet use the matrix calculation for USANS
// -- SO THERE IS NO SWITCH YET IN Smear_Model_N()
//
//

//maybe not the optimal set of parameters for the STRUCT
//
// resW is /N=(np,4) if SANS data
// resW is /N=(np,np) if USANS data
//
// info may be useful later as a "KEY=value;" string to carry additional information
Structure ResSmearAAOStruct
	Wave coefW
	Wave yW
	Wave xW
	Wave resW
	String info
EndStructure


//// tentative pass at 2D resolution smearing
////
//Structure ResSmear_2D_AAOStruct
//	Wave coefW
//	Wave zw			//answer
//	Wave qy			// q-value
//	Wave qx
//	Wave qz
//	Wave sQpl		//resolution parallel to Q
//	Wave sQpp		//resolution perpendicular to Q
//	Wave fs
//	String info
//EndStructure

// reformat the structure ?? WM Fit compatible
// -- 2D resolution smearing
//
Structure ResSmear_2D_AAOStruct
	Wave coefW
	Wave zw			//answer
	Wave xw[2]		// qx-value is [0], qy is xw[1]
	Wave qz
	Wave sQpl		//resolution parallel to Q
	Wave sQpp		//resolution perpendicular to Q
	Wave fs
	String info
EndStructure



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

// !!!!! reduces the length of wt and zi by one !!!!!
//
Function Make_N_GaussPoints(wt,zi)
	Wave wt,zi
	
	Variable num
	num = numpnts(wt) - 1
	
	gauleg(-1,1,zi,wt,num)
	
	DeletePoints 0,1,wt,zi
	
	return(0)
End

/// gauleg subroutine from NR to calculate weights and abscissae for 
// Gauss-Legendre quadrature
//
//
// arrays are indexed from 1
//
Function gauleg( x1, x2, x, w, n)
	Variable x1, x2
	Wave x, w
	Variable n
	
	variable m,j,i
	variable z1,z,xm,xl,pp,p3,p2,p1
	Variable eps = 3e-11

	m=(n+1)/2
	xm=0.5*(x2+x1)
	xl=0.5*(x2-x1)
	for (i=1;i<=m;i+=1) 
		z=cos(pi*(i-0.25)/(n+0.5))
		do 
			p1=1.0
			p2=0.0
			for (j=1;j<=n;j+=1) 
				p3=p2
				p2=p1
				p1=((2.0*j-1.0)*z*p2-(j-1.0)*p3)/j
			endfor
			pp=n*(z*p1-p2)/(z*z-1.0)
			z1=z
			z=z1-p1/pp
		while (abs(z-z1) > EPS)
		x[i]=xm-xl*z
		x[n+1-i]=xm+xl*z
		w[i]=2.0*xl/((1.0-z*z)*pp*pp)
		w[n+1-i]=w[i]
	Endfor
End


/// uses a user-supplied number of Gauss points, and generates them on-the-fly as needed
// using a Numerical Recipes routine
//
// - note that this has an extra input parameter, nord
//
////////////
Function IntegrateFn_N(fcn,loLim,upLim,w,x,nord)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation
	Variable nord			//number of quadrature points to used


// special case of integral limits that are identical
	if(upLim == loLim)
		return( fcn(w,x, loLim))
	endif
	
// local variables
	Variable ii,va,vb,summ,yyy,zi
	Variable answer,dum
	String weightStr,zStr
	
	weightStr = "gauss"+num2iStr(nord)+"wt"
	zStr = "gauss"+num2istr(nord)+"z"
		
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord+1) $weightStr,$zStr
		Wave wt = $weightStr
		Wave xx = $zStr		// wave references to pass
		Make_N_GaussPoints(wt,xx)				//generates the gauss points and removes the extra point
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave wt = $weightStr
		Wave xx = $zStr		// create the wave references
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
		zi = ( xx[ii]*(vb-va) + vb + va )/2.0
		//calculate partial sum for the passed-in model function	
		yyy = wt[ii] *  fcn(w,x,zi)						
		summ += yyy		//add to the running total of the quadrature
       ii+=1     	
	while (ii<nord)				// end of loop over quadrature points
   
	// calculate value of integral to return
	answer = (vb-va)/2.0*summ

	Return (answer)
End



////////////
Function IntegrateFn5(fcn,loLim,upLim,w,x)				
	FUNCREF GenericQuadrature_proto fcn
	Variable loLim,upLim	//limits of integration
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation


// special case of integral limits that are identical
	if(upLim == loLim)
		return( fcn(w,x, loLim))
	endif
	
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

// special case of integral limits that are identical
	if(upLim == loLim)
		return( fcn(w,x, loLim))
	endif
	
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

// special case of integral limits that are identical
	if(upLim == loLim)
		return( fcn(w,x, loLim))
	endif
	
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
// special case of integral limits that are identical
	if(upLim == loLim)
		return( fcn(w,x, loLim))
	endif
	
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
		DoAlert 0,"Some 6-column QSIG waves are missing. Re-load experimental data with 'Load SANS or USANS Data' macro"
	endif
	
	return(err)
end

//////Resolution Smearing Utilities

// To check for the existence of all waves needed for smearing
// returns 1 if any waves are missing, 0 if all is OK
// str passed in is the data folder containing the data
//
// 19 JUN07 using new data folder structure for loading
// and resolution matrix
Function ResolutionWavesMissingDF(str)
	String str
	
	String DF="root:"+str+":"

	WAVE/Z res = $(DF+str+"_res")
	
	if(!WaveExists(res))
		DoAlert 0,"The resolution matrix is missing. Re-load experimental data with the 'Load SANS or USANS Data' macro"
		return(1)
	endif
	
	return(0)
end

///////////////////////////////////////////////////////////////

// "backwards" wrapped to reduce redundant code
// there are only 4 choices of N (5,10,20,76) for smearing
//
//
// 4 MAR 2011
// Note: In John's paper, he integrated the Gaussian to +/- 3 sigma and then renormalized
//       to an integral of 1. This "truncated" gaussian was a somewhat better approximation
//       to the triangular resolution function. Here, I integrate to +/- 3 sigma and
//       now correctly renormalize the integral to 1. Hence the smeared calculation in the past was 0.27% low.
//       Confimation of the integral is easily seen by smearing a constant value.
//
// Using 5 quadrature points is not recommended, as it doesn't normalize properly using .9973
//  -- instead, it normalizes to 1.0084, 
//
Function Smear_Model_N(fcn,w,x,resW,wi,zi,nord)
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	Variable x	//x-value (q) for the calculation THIS IS PASSED IN AS A WAVE
	Wave resW		// Nx4 or NxN matrix of resolution
	Wave wi		//weight wave
	Wave zi		//abscissa wave
	Variable nord		//order of integration

	NVAR dQv = root:Packages:NIST:USANS_dQv

// local variables
	Variable ii,va,vb
	Variable answer,i_shad,i_qbar,i_sigq,normalize=1

	// current x point is the q-value for evaluation
	//
	// * for the input x, the resolution function waves are interpolated to get the correct values for
	//  sigq, qbar and shad - since the model x-spacing may not be the same as
	// the experimental QSIG data. This is always the case when curve fitting, since fit_wave is 
	// Igor-defined as 200 points and has its own (linear) q-(x)-scaling which will be quite different
	// from experimental data.
	// **note** if the (x) passed in is the experimental q-values, these values are
	// returned from the interpolation (as expected)

	Make/O/D/N=(DimSize(resW, 0)) sigQ,qbar,shad,qvals
	sigq = resW[p][0]		//std dev of resolution fn
	qbar = resW[p][1]		//mean q-value
	shad = resW[p][2]		//beamstop shadow factor
	qvals = resW[p][3]	//q-values where R(q) is known

	i_shad = interp(x,qvals,shad)
	i_qbar = interp(x,qvals,qbar)
	i_sigq = interp(x,qvals,sigq)
			
// set up the integration
// number of Gauss Quadrature points
		
	if (isSANSResolution(i_sigq))
		
		// end points of integration
		// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
		// +/- 3 sigq catches 99.73% of distrubution
		// change limits (and spacing of zi) at each evaluation based on R()
		//integration from va to vb
	
		// for +/- 3 sigma ONLY
		if(nord == 5)
			normalize = 1.0057		//empirical correction, N=5 shouldn't be any different
		else
			normalize = 0.9973
		endif
		
		va = -3*i_sigq + i_qbar
		if (va<0)
			va=0		//to avoid numerical error when  va<0 (-ve q-value)
//			Print "truncated Gaussian at nominal q = ",x
		endif
		vb = 3*i_sigq + i_qbar
		
		
		// Using 20 Gauss points		    
		ii=0			// loop counter
		// do the calculation as a single pass w/AAO function
		Make/O/D/N=(nord) Resoln,yyy,xGauss
		do
			// calculate Gauss points on integration interval (q-value for evaluation)
			xGauss[ii] = ( zi[ii]*(vb-va) + vb + va )/2.0
			// calculate resolution function at input q-value (use the interpolated values and zi)
			Resoln[ii] = i_shad/sqrt(2*pi*i_sigq*i_sigq)
			Resoln[ii] *= exp((-1*(xGauss[ii] - i_qbar)^2)/(2*i_sigq*i_sigq))
 			ii+=1     	
		while (ii<nord)				// end of loop over quadrature points
		
   		fcn(w,yyy,xGauss)		//yyy is the return value as a wave
   		
   		yyy *= wi *Resoln		//multiply function by resolution and weights
		// calculate value of integral to return
   		answer = (vb-va)/2.0*sum(yyy)
   		// all scaling, background addition... etc. is done in the model calculation
	
			// renormalize to 1
			answer /= normalize
	else
		//smear with the USANS routine
		// Make global string and local variables
		// now data folder aware, necessary for GlobalFit = FULL path to wave	
		String/G gTrap_coefStr = GetWavesDataFolder(w, 2 )	
		Variable maxiter=20, tol=1e-4
		
		// set up limits for the integration
		va=0
		vb=abs(dQv)
		
		Variable/G gEvalQval = x
		
		// call qtrap to do actual work
		answer = qtrap_USANS(fcn,va,vb,tol,maxiter)
		answer /= vb
		
	endif
	
	//killing these waves is cleaner, but MUCH SLOWER
//	Killwaves/Z Resoln,yyy,xGauss
//	Killwaves/Z sigQ,qbar,shad,qvals
	Return (answer)
	
End

//resolution smearing, using only 5 Gauss points
//
//
Function Smear_Model_5(fcn,w,x,answer,resW)				
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	Wave x	//x-value (q) for the calculation
	Wave answer // ywave for calculation result
	Wave resW		// Nx4 or NxN matrix of resolution
	NVAR useTrap = root:Packages:NIST:USANSUseTrap

	String weightStr,zStr
	Variable nord=5
	
	if (dimsize(resW,1) > 4 && useTrap !=1)
		if(dimsize(resW,1) != dimsize(answer,0) )
			Abort "ResW and answer are different dimensions - (res,ans)"+num2str(dimsize(resW,1))+","+num2str(dimsize(answer,0))
		endif
		//USANS Weighting matrix is present.
		fcn(w,answer,x)
	
		MatrixOP/O  answer = resW x answer
		//Duplicate/O answer,tmpMat
		//MatrixOP/O answer = resW x tmpMat
		Return(0)
	else
		weightStr = "gauss5wt"
		zStr = "gauss5z"
	
	//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
		if (WaveExists($weightStr) == 0) // wave reference is not valid, 
			Make/D/N=(nord) $weightStr,$zStr
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// wave references to pass
			Make5GaussPoints(weightW,abscissW)	
		else
			if(exists(weightStr) > 1) 
				 Abort "wave name is already in use"		//executed only if name is in use elsewhere
			endif
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// create the wave references
		endif
	
//		answer = Smear_Model_N(fcn,w,x,resW,weightW,abscissW,nord)
		Smear_Model_N_AAO(fcn,w,x,resW,weightW,abscissW,nord,answer)
		
		Return (0)
	endif
	
End

//resolution smearing, using only 10 Gauss points
//
//
Function Smear_Model_10(fcn,w,x,answer,resW)				
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	Wave x	//x-value (q) for the calculation
	Wave answer // ywave for calculation result
	Wave resW		// Nx4 or NxN matrix of resolution

	String weightStr,zStr
	Variable nord=10
	
	if (dimsize(resW,1) > 4)
		if(dimsize(resW,1) != dimsize(answer,0) )
			Abort "ResW and answer are different dimensions - (res,ans)"+num2str(dimsize(resW,1))+","+num2str(dimsize(answer,0))
		endif
		//USANS Weighting matrix is present.
		fcn(w,answer,x)
	
		MatrixOP/O  answer = resW x answer
		//Duplicate/O answer,tmpMat
		//MatrixOP/O answer = resW x tmpMat
		Return(0)
	else
		weightStr = "gauss10wt"
		zStr = "gauss10z"
	
	//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
		if (WaveExists($weightStr) == 0) // wave reference is not valid, 
			Make/D/N=(nord) $weightStr,$zStr
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// wave references to pass
			Make10GaussPoints(weightW,abscissW)	
		else
			if(exists(weightStr) > 1) 
				 Abort "wave name is already in use"		//executed only if name is in use elsewhere
			endif
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// create the wave references
		endif
	
//		answer = Smear_Model_N(fcn,w,x,resW,weightW,abscissW,nord)
		Smear_Model_N_AAO(fcn,w,x,resW,weightW,abscissW,nord,answer)

		Return (0)
	endif
	
End

//
//Smear_Model_20(SphereForm,s.coefW,s.yW,s.xW,s.resW)
//
// 	Wave sigq		//std dev of resolution fn
//	Wave qbar		//mean q-value
//	Wave shad		//beamstop shadow factor
//	Wave qvals	//q-values where R(q) is known
//
Function Smear_Model_20(fcn,w,x,answer,resW)				
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	Wave x	//x-value (q) for the calculation
	Wave answer // ywave for calculation result
	Wave resW		// Nx4 or NxN matrix of resolution
	NVAR useTrap = root:Packages:NIST:USANSUseTrap

	String weightStr,zStr
	Variable nord=20

	
	if (dimsize(resW,1) > 4 && useTrap != 1)
		if(dimsize(resW,1) != dimsize(answer,0) )
			Abort "ResW and answer are different dimensions - (res,ans)"+num2str(dimsize(resW,1))+","+num2str(dimsize(answer,0))
		endif
		//USANS Weighting matrix is present.
		fcn(w,answer,x)
	
		MatrixOP/O  answer = resW x answer
		//Duplicate/O answer,tmpMat
		//MatrixOP/O answer = resW x tmpMat
		Return(0)
	else
		weightStr = "gauss20wt"
		zStr = "gauss20z"
	
	//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
		if (WaveExists($weightStr) == 0) // wave reference is not valid, 
			Make/D/N=(nord) $weightStr,$zStr
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// wave references to pass
			Make20GaussPoints(weightW,abscissW)	
		else
			if(exists(weightStr) > 1) 
				 Abort "wave name is already in use"		//executed only if name is in use elsewhere
			endif
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// create the wave references
		endif
	
//		answer = Smear_Model_N(fcn,w,x,resW,weightW,abscissW,nord)
		Smear_Model_N_AAO(fcn,w,x,resW,weightW,abscissW,nord,answer)

		Return (0)
	endif
	
End
///////////////////////////////////////////////////////////////
Function Smear_Model_76(fcn,w,x,answer,resW)				
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	Wave x	//x-value (q) for the calculation
	Wave answer // ywave for calculation result
	Wave resW		// Nx4 or NxN matrix of resolution
	NVAR useTrap = root:Packages:NIST:USANSUseTrap

	String weightStr,zStr
	Variable nord=76
	
	if (dimsize(resW,1) > 4  && useTrap != 1)
		if(dimsize(resW,1) != dimsize(answer,0) )
			Abort "ResW and answer are different dimensions - (res,ans)"+num2str(dimsize(resW,1))+","+num2str(dimsize(answer,0))
		endif
		//USANS Weighting matrix is present.
		fcn(w,answer,x)
	
		MatrixOP/O  answer = resW x answer
		//Duplicate/O answer,tmpMat
		//MatrixOP/O answer = resW x tmpMat
		Return(0)
	else
		weightStr = "gauss76wt"
		zStr = "gauss76z"
	
	//	if wt,z waves don't exist, create them (only check for weight, should really check for both)
		if (WaveExists($weightStr) == 0) // wave reference is not valid, 
			Make/D/N=(nord) $weightStr,$zStr
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// wave references to pass
			Make76GaussPoints(weightW,abscissW)	
		else
			if(exists(weightStr) > 1) 
				 Abort "wave name is already in use"		//executed only if name is in use elsewhere
			endif
			Wave weightW = $weightStr
			Wave abscissW = $zStr		// create the wave references
		endif
	
//		answer = Smear_Model_N(fcn,w,x,resW,weightW,abscissW,nord)
		Smear_Model_N_AAO(fcn,w,x,resW,weightW,abscissW,nord,answer)

		Return (0)
	endif
	
End


///////////////////////////////////////////////////////////////

//typically, the first point (or any point) of sigQ is passed
// if negative, it's USANS data...
Function isSANSResolution(val)
	Variable val
	if(val>=0)
		return(1)		//true, SANS data
	else
		return(0)		//false, USANS
	endif
End

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

// prototype function for smearing routines, Smear_Model_N
// and trapzd_USANS() and qtrap_USANS()
// it intentionally does nothing
Function SANSModelAAO_proto(w,yw,xw)
	Wave w,yw,xw
	
	Print "in SANSModelAAO_proto function"
	return(1)
end

// prototype function for fit wrapper
// it intentionally does nothing
Function SANSModelSTRUCT_proto(s)
	Struct ResSmearAAOStruct &s	

	Print "in SANSModelSTRUCT_proto function"
	return(1)
end

// prototype function for 2D smearing routine
ThreadSafe Function SANS_2D_ModelAAO_proto(w,zw,xw,yw)
	Wave w,zw,xw,yw
	
	Print "in SANSModelAAO_proto function"
	return(1)
end

// prototype function for fit wrapper using 2D smearing
// not used (yet)
Function SANS_2D_ModelSTRUCT_proto(s)
	Struct ResSmear_2D_AAOStruct &s	

	Print "in SANSModelSTRUCT_proto function"
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
	FUNCREF SANSModelAAO_proto fcn
	Variable aa,bb,nn
	
	Variable xx,tnm,summ,del
	Variable it,jj,arg1,arg2
	NVAR sVal=sVal		//calling function must initialize this global
	NVAR qval = gEvalQval
	SVAR cwStr = gTrap_CoefStr		//pass in the coefficient wave (string)
	Wave cw=$cwStr			
	Variable temp=0
	Make/D/O/N=2 tmp_xw,tmp_yw
	if(nn==1)
		tmp_xw[0] = sqrt(qval^2 + aa^2)
	  	tmp_xw[1] = sqrt(qval^2 + bb^2)
	  	fcn(cw,tmp_yw,tmp_xw)
		temp = 0.5*(bb-aa)*(tmp_yw[0] + tmp_yw[1])
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
			tmp_xw = sqrt(qval^2 + xx^2)
		  	fcn(cw,tmp_yw,tmp_xw)		//not the most efficient... but replaced by the matrix method
			summ += tmp_yw[0]
			xx += del
		endfor
		sval = 0.5*(sval+(bb-aa)*summ/tnm)	//replaces sval with its refined value
		return (sval)
	endif
	//KillWaves/Z tmp_xw,tmp_yw
End

////Numerical Recipes routine to calculate the nn(th) stage
////refinement of a trapezoid integration
////
////must be called sequentially from nn=1...n from qtrap()
//// to cumulatively refine the integration value
////
//// in the conversion:
//// -- s was replaced with sVal and declared global (rather than static)
////  so that the nn-1 value would be available during the nn(th) call
////
//// -- the specific coefficient wave for func() is passed in as a
////  global string (then converted to a wave reference), since
////  func() will eventually call sphereForm()
////
//Function trapzd_USANS_point(fcn,aa,bb,nn)
//	FUNCREF SANSModel_proto fcn
//	Variable aa,bb,nn
//	
//	Variable xx,tnm,summ,del
//	Variable it,jj,arg1,arg2
//	NVAR sVal=sVal		//calling function must initialize this global
//	NVAR qval = gEvalQval
//	SVAR cwStr = gTrap_CoefStr		//pass in the coefficient wave (string)
//	Wave cw=$cwStr			
//	Variable temp=0
//	if(nn==1)
//		arg1 = qval^2 + aa^2
//	  	arg2 = qval^2 + bb^2
//		temp = 0.5*(bb-aa)*(fcn(cw,sqrt(arg1)) + fcn(cw,sqrt(arg2)))
//		sval = temp
//		return(sVal)
//	else
//		it=1
//		it= 2^(nn-2)  //done in NR with a bit shift <<=
//		tnm = it
//		del = (bb - aa)/tnm		//this is the spacing of points to add
//		xx = aa+0.5*del
//		summ=0
//		for(jj=1;jj<=it;jj+=1)
//			arg1 = qval^2 + xx^2
//			summ += fcn(cw,sqrt(arg1))
//			xx += del
//		endfor
//		sval = 0.5*(sval+(bb-aa)*summ/tnm)	//replaces sval with its refined value
//		return (sval)
//	endif
//	
//End

// Numerical Recipes routine to calculate the integral of a
// specified function, trapezoid rule is used to a user-specified
// level of refinement using sequential calls to trapzd()
//
// in NR, eps and maxIt were global, pass them in here...
// eps typically 1e-5
// maxit typically 20
Function qtrap_USANS(fcn,aa,bb,eps,maxIt)
	FUNCREF SANSModelAAO_proto fcn
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

//// Numerical Recipes routine to calculate the integral of a
//// specified function, trapezoid rule is used to a user-specified
//// level of refinement using sequential calls to trapzd()
////
//// in NR, eps and maxIt were global, pass them in here...
//// eps typically 1e-5
//// maxit typically 20
//Function qtrap_USANS_point(fcn,aa,bb,eps,maxIt)
//	FUNCREF SANSModel_proto fcn
//	Variable aa,bb,eps,maxit
//	
//	Variable/G sVal=0		//create and initialize what trapzd will return
//	Variable jj,ss,olds
//	
//	olds = -1e30		//any number that is not the avg. of endpoints of the funciton
//	for(jj=1;jj<=maxit;jj+=1)	//call trapzd() repeatedly until convergence
//		ss = trapzd_USANS_point(fcn,aa,bb,jj)
//		if( abs(ss-olds) < eps*abs(olds) )		// good enough, stop now
//			return ss
//		endif
//		if( (ss == 0.0) && (olds == 0.0) && (jj>6) )		//no progress?
//			return ss
//		endif
//		olds = ss
//	endfor
//
//	Print "Maxit exceeded in qtrap. If you're here, there was an error in qtrap"
//	return(ss)		//should never get here if function is well-behaved
//	
//End	

Proc RRW()
	ResetResolutionWaves()
End

//utility procedures that are currently untied to any actions, although useful...
Proc ResetResolutionWaves(str)
	String Str
	Prompt str,"Pick the intensity wave with the resolution you want",popup,WaveList("*_i",";","")


	Abort "This function is not data floder aware and does nothing..."
		
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


////
//// moved from RawWindowHook to here - where the Q calculations are available to
//   reduction and analysis
//

//phi is defined from +x axis, proceeding CCW around [0,2Pi]
Threadsafe Function FindPhi(vx,vy)
	variable vx,vy
	
	variable phi
	
	phi = atan(vy/vx)		//returns a value from -pi/2 to pi/2
	
	// special cases
	if(vx==0 && vy > 0)
		return(pi/2)
	endif
	if(vx==0 && vy < 0)
		return(3*pi/2)
	endif
	if(vx >= 0 && vy == 0)
		return(0)
	endif
	if(vx < 0 && vy == 0)
		return(pi)
	endif
	
	
	if(vx > 0 && vy > 0)
		return(phi)
	endif
	if(vx < 0 && vy > 0)
		return(phi + pi)
	endif
	if(vx < 0 && vy < 0)
		return(phi + pi)
	endif
	if( vx > 0 && vy < 0)
		return(phi + 2*pi)
	endif
	
	return(phi)
end

	
//function to calculate the overall q-value, given all of the necesary trig inputs
//NOTE: detector locations passed in are pixels = 0.5cm real space on the detector
//and are in detector coordinates (1,128) rather than axis values
//the pixel locations need not be integers, reals are ok inputs
//sdd is in meters
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
Function CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSize
	
	Variable dx,dy,qval,two_theta,dist
	
	Variable pixSizeX=pixSize
	Variable pixSizeY=pixSize
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	
	two_theta = atan(dist/sdd)

	qval = 4*Pi/lam*sin(two_theta/2)
	
	return qval
End

//calculates just the q-value in the x-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function CalcQX(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSize

	Variable qx,qval,phi,dx,dy,dist,two_theta
	
	qval = CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSize		//delta x in cm
	dy = (yaxval - yctr)*pixSize		//delta y in cm
	phi = FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)

	qx = qval*cos(two_theta/2)*cos(phi)
	
	return qx
End

//calculates just the q-value in the y-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function CalcQY(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSize
	
	Variable dy,qval,dx,phi,qy,dist,two_theta
	
	qval = CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSize		//delta x in cm
	dy = (yaxval - yctr)*pixSize		//delta y in cm
	phi = FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qy = qval*cos(two_theta/2)*sin(phi)
	
	return qy
End

//calculates just the z-component of the q-vector, not measured on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//NOTE: detector locations passed in are pixel = 0.5cm real space on the Ordela detector
//sdd is in meters
//wavelength is in Angstroms
//
// not actually used, but here for completeness if anyone asks
//
Function CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSize
	
	Variable dy,qval,dx,phi,qz,dist,two_theta
	
	qval = CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSize)
	
	sdd *=100		//convert to cm
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dx = (xaxval - xctr)*pixSize		//delta x in cm
	dy = (yaxval - yctr)*pixSize		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qz = qval*sin(two_theta/2)
	
	return qz
End

//for command-line testing, replace the function declaration
//Function FindQxQy(qq,phi)
//	Variable qq,phi
//	Variable qx,qy
//
//
ThreadSafe Function FindQxQy(qq,phi,qx,qy)
	Variable qq,phi,&qx,&qy

	qx = sqrt(qq^2/(1+tan(phi)*tan(phi)))
	qy = qx*tan(phi)
	
	if(phi >= 0 && phi <= pi/2)
		qx = abs(qx)
		qy = abs(qy)
	endif
	
	if(phi > pi/2 && phi <= pi)
		qx = -abs(qx)
		qy = abs(qy)
	endif
	
	if(phi > pi && phi <= pi*3/2)
		qx = -abs(qx)
		qy = -abs(qy)
	endif
	
	if(phi > pi*3/2 && phi < 2*pi)
		qx = abs(qx)
		qy = -abs(qy)
	endif	
	
	
//	Print "recalculated qx,qy,q = ",qx,qy,sqrt(qx*qx+qy*qy)
	
	return(0)
end


// 7 MAR 2011 SRK
//
// calculate the resolution smearing AAO
//
// - many of the form factor calculations are threaded, so they benefit
// from being passed large numbers of q-values at once, rather than suffering the 
// overhead penalty of setting up threads.
//
// In general, single integral functions benefit from this, multiple integrals not so much.
// As an example, a fit using SmearedCylinderForm took 4.3s passing nord (=20) q-values
// at a time, but only 1.1s by passing all (Nq*nord) q-values at once. For Cyl_polyRad,
// the difference was not so large, 16.2s vs. 11.9s. This is due to CylPolyRad being a 
// double integral and slow enough of a calculation that passing even 20 points at once
// provides some speedup.
//
//// APRIL 2011 *** this function is now cursor aware. The whole input x-wave is interpolated
//
//
// 4 MAR 2011 SRK
// Note: In John's paper, he integrated the Gaussian to +/- 3 sigma and then renormalized
//       to an integral of 1. This "truncated" gaussian was a somewhat better approximation
//       to the triangular resolution function. Here, I integrate to +/- 3 sigma and
//       do not renormalize the integral to 1. Hence the smeared calculation is 0.27% low.
//       This is easily seen by smearing a constant value.
//
// Using 5 quadrature points is not recommended, as it doesn't normalize properly using .9973
//  -- instead, it normalizes to 1.0084.
//
Function Smear_Model_N_AAO(fcn,w,x,resW,wi,zi,nord,sm_ans)
	FUNCREF SANSModelAAO_proto fcn
	Wave w			//coefficients of function fcn(w,x)
	WAVE x			//x-value (q) for the calculation THIS IS PASSED IN AS A WAVE
	Wave resW		// Nx4 or NxN matrix of resolution
	Wave wi		//weight wave
	Wave zi		//abscissa wave
	Variable nord		//order of integration
	Wave sm_ans		// wave returned with the smeared model

	NVAR dQv = root:Packages:NIST:USANS_dQv
	NVAR useTrap = root:Packages:NIST:USANSUseTrap

// local variables
	Variable ii,jj
	Variable normalize=1
	Variable nTot,num,block_sum


	// current x point is the q-value for evaluation
	//
	// * for the input x, the resolution function waves are interpolated to get the correct values for
	//  sigq, qbar and shad - since the model x-spacing may not be the same as
	// the experimental QSIG data. This is always the case when curve fitting, since fit_wave is 
	// Igor-defined as 200 points and has its own (linear) q-(x)-scaling which will be quite different
	// from experimental data.
	// **note** if the (x) passed in is the experimental q-values, these values are
	// returned from the interpolation (as expected)

	Make/O/D/N=(numpnts(x)) sigQ,qbar,shad,qvals,va,vb
	Make/O/D/N=(DimSize(resW, 0)) tmpsigQ,tmpqbar,tmpshad,tmpqvals
	tmpsigq = resW[p][0]		//std dev of resolution fn
	tmpqbar = resW[p][1]		//mean q-value
	tmpshad = resW[p][2]		//beamstop shadow factor
	tmpqvals = resW[p][3]	//q-values where R(q) is known

	//interpolate the whole input x-wave to make sure that the resolution and input x are in sync if cursors are used
	shad = interp(x,tmpqvals,tmpshad)
	qbar = interp(x,tmpqvals,tmpqbar)
	sigq = interp(x,tmpqvals,tmpsigq)
	
	// if USANS or VSANS data, handle separately
	// -- but this would only ever be used if the calculation was forced to use trapezoid integration
	// by intentionally bypssing the chance to use the matrix calculation byt setting
	// the global flag useTrap = 1. Without this flag, the matrix is detected and used.
	//
//	if ( ! isSANSResolution(sigq[0]) )

	if (dimsize(resW,1) > 4 && useTrap == 1)
		//smear with the USANS routine
		// Make global string and local variables
		// now data folder aware, necessary for GlobalFit = FULL path to wave	
		String/G gTrap_coefStr = GetWavesDataFolder(w, 2 )	
		Variable maxiter=20, tol=1e-4,uva,uvb
//		Variable maxiter=10, tol=1e-2,uva,uvb
		
		String df = GetWavesDataFolder(w,0)
		
		Wave/Z dQvWave = $("root:"+df+":"+df+"_dQv")

		num=numpnts(x)
		// set up limits for the integration
		uva=0
		//uvb=abs(dQv)
		
		//loop over the q-values
		for(jj=0;jj<num;jj+=1)
			Variable/G gEvalQval = x[jj]


			//make dQv a per-point value
			uvb=abs(dQvWave[jj])
			dQv = dQvWave[jj]		//update the global value too

			// call qtrap to do actual work
			sm_ans[jj] = qtrap_USANS(fcn,uva,uvb,tol,maxiter)
			sm_ans[jj] /= (uvb - uva)
		endfor
		
		return(0)	
	endif


// now the idea is to calculate a long vector of all of the zi's (Nq * nord)
// and pass these AAO to the AAO function, to make the most use of the threading
// passing repeated short lengths of q to the function can actually be slower
// due to the overhead.
	
	num = numpnts(x)
	nTot = nord*num
	
	Make/O/D/N=(nTot) Resoln,yyy,xGauss,wts

	//loop over q
	for(jj=0;jj<num;jj+=1)
	
		//for each q, set up the integration range
		// end points of integration limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
		// +/- 3 sigq catches 99.73% of distrubution
		// change limits (and spacing of zi) at each evaluation based on R()
		//integration from va to vb

		va[jj] = -3*sigq[jj] + qbar[jj]
		if (va[jj]<0)
			va[jj]=0		//to avoid numerical error when  va<0 (-ve q-value)
//			Print "truncated Gaussian at nominal q = ",x
		endif
		vb[jj] = 3*sigq[jj] + qbar[jj]
	
		// loop over the Gauss points
		for(ii=0;ii<nord;ii+=1)
			// calculate Gauss points on integration interval (q-value for evaluation)
			xGauss[nord*jj+ii] = ( zi[ii]*(vb[jj]-va[jj]) + vb[jj] + va[jj] )/2.0
			// calculate resolution function at input q-value (use the interpolated values and zi)
			Resoln[nord*jj+ii] = shad[jj]/sqrt(2*pi*sigq[jj]*sigq[jj])
			Resoln[nord*jj+ii] *= exp((-1*(xGauss[nord*jj+ii] - qbar[jj])^2)/(2*sigq[jj]*sigq[jj]))
//			Resoln[nord*jj+ii] *= exp((-1*(xGauss[nord*jj+ii] - qvals[jj])^2)/(2*sigq[jj]*sigq[jj]))		//WRONG, but just for testing
			// carry a copy of the weights
			wts[nord*jj+ii] = wi[ii]
		endfor 		// end of loop over quadrature points
	
	endfor		//loop over q
	
	//calculate AAO
	yyy = 0
	fcn(w,yyy,xGauss)		//yyy is the return value as a wave

	//multiply by weights
	yyy *= wts*Resoln		//multiply function by resolution and weights
	
	//sum up blockwise to get the final answer
	for(jj=0;jj<num;jj+=1)
		block_sum = 0
		for(ii=0;ii<nord;ii+=1)
			block_sum += yyy[nord*jj+ii]
		endfor
		sm_ans[jj] = (vb[jj]-va[jj])/2.0*block_sum
	endfor
	
	
	// then normalize for +/- 3 sigma ONLY
	if(nord == 5)
		normalize = 1.0057		//empirical correction, N=5 shouldn't be any different
	else
		normalize = 0.9973
	endif
	
	sm_ans /= normalize
	
	KillWaves/Z tmpsigQ,tmpqbar,tmpshad,tmpqvals
	
	return(0)
	
End

