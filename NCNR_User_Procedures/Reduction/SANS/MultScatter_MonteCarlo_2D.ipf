#pragma rtGlobals=1		// Use modern global access method.

//
// Monte Carlo simulator for SASCALC
// October 2008 SRK
//
// This code simulates the scattering for a selected model based on the instrument configuration
// This code is based directly on John Barker's code, which includes multiple scattering effects.
// A lot of the setup, wave creation, and post-calculations are done in SASCALC->ReCalculateInten()
//
//
// - Most importantly, this needs to be checked for correctness of the MC simulation
// X how can I get the "data" on absolute scale? This would be a great comparison vs. the ideal model calculation
// - why does my integrated tau not match up with John's analytical calculations? where are the assumptions?
// - get rid of all small angle assumptions - to make sure that the calculation is correct at all angles
// - what is magical about Qu? Is this an assumpution?

// - at the larger angles, is the "flat" detector being properly accounted for - in terms of
//   the solid angle and how many counts fall in that pixel. Am I implicitly defining a spherical detector
//   so that what I see is already "corrected"?
// X the MC will, of course benefit greatly from being XOPized. Maybe think about parallel implementation
//   by allowing the data arrays to accumulate. First pass at the XOP is done. Not pretty, not the speediest (5.8x)
//   but it is functional. Add spinCursor() for long calculations. See WaveAccess XOP example.
// - the background parameter for the model MUST be zero, or the integration for scattering
//    power will be incorrect.
// - fully use the SASCALC input, most importantly, flux on sample.
// X if no MC desired, still use the selected model
// X better display of MC results on panel
// - settings for "count for X seconds" or "how long to 1E6 cts on detector" (run short sim, then multiply)
// - add quartz window scattering to the simulation somehow
// - do smeared models make any sense??
// - make sure that the ratio of scattering coherent/incoherent is properly adjusted for the sample composition
//   or the volume fraction of solvent.
//
// - add to the results the fraction of coherently scattered neutrons that are singly scattered, different than
//   the overall fraction of singly scattered, and maybe more important to know.
//
// - change the fraction reaching the detector to exclude those that don't interact. These transmitted neutrons
//   aren't counted. Is the # that interact a better number?
//
// - do we want to NOT offset the data by a multiplicative factor as it is "frozen" , so that the 
//   effects on the absolute scale can be seen?
//
// - why is "pure" incoherent scattering giving me a q^-1 slope, even with the detector all the way back?
// - can I speed up by assuming everything interacts? This would compromise the ability to calculate multiple scattering
// - ask John how to verify what is going on
// - a number of models are now found to be ill-behaved when q=1e-10. Then the random deviate calculation blows up.
//   a warning has been added - but the models are better fixed with the limiting value.
//
//



//////////
//    PROGRAM Monte_SANS
//    PROGRAM simulates multiple SANS.
//       revised 2/12/99  JGB
//	      added calculation of random deviate, and 2D 10/2008 SRK

//    N1 = NUMBER OF INCIDENT NEUTRONS.
//    N2 = NUMBER INTERACTED IN THE SAMPLE.
//    N3 = NUMBER ABSORBED.
//    THETA = SCATTERING ANGLE.

//        IMON = 'Enter number of neutrons to use in simulation.'
//        NUM_BINS = 'Enter number of THETA BINS TO use. (<5000).'
//        R1 = 'Enter beam radius. (cm)'
//        R2 = 'Enter sample radius. (cm)'
//        thick = 'Enter sample thickness. (cm)'
//        wavelength = 'Enter neutron wavelength. (A)'
//        R0 = 'Enter sphere radius. (A)'
//

Function Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,MC_linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,MC_linear_data,results

	Variable imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh,sig_sas
	Variable NUM_BINS,N_INDEX
	Variable RHO,SIGSAS,SIGABS_0
	Variable ii,jj,IND,idum,INDEX,IR,NQ
	Variable qmax,theta_max,R_DAB,R0,BOUND,I0,q0,zpow
	Variable N1,N2,N3,DTH,zz,tt,SIG_SINGLE,xx,yy,PHI,UU,SIG
	Variable THETA,Ran,ll,D_OMEGA,RR,Tabs,Ttot,I1_sumI
	//in John's implementation, he dimensioned the indices of the arrays to begin
	// at 0, making things much easier for me...
	//DIMENSION  NT(0:5000),J1(0:5000),J2(0:5000),NN(0:100)

	Variable G0,E_NT,E_NN,TRANS_th,Trans_exp,rat
	Variable GG,GG_ED,dS_dW,ds_dw_double,ds_dw_single
	Variable DONE,FIND_THETA,err		//used as logicals

	Variable Vx,Vy,Vz,Theta_z,qq
	Variable Sig_scat,Sig_abs,Ratio,Sig_total
	Variable isOn=0,testQ,testPhi,xPixel,yPixel
	
	imon = inputWave[0]
	r1 = inputWave[1]
	r2 = inputWave[2]
	xCtr = inputWave[3]
	yCtr = inputWave[4]
	sdd = inputWave[5]
	pixSize = inputWave[6]
	thick = inputWave[7]
	wavelength = inputWave[8]
	sig_incoh = inputWave[9]
	sig_sas = inputWave[10]
	
//	SetRandomSeed 0.1		//to get a reproduceable sequence

//scattering power and maximum qvalue to bin
//	zpow = .1		//scattering power, calculated below
	qmax = 4*pi/wavelength		//maximum Q to bin 1D data. (A-1) (not really used, so set to a big value)
	sigabs_0 = 0.0		// ignore absorption cross section/wavelength [1/(cm A)]
	N_INDEX = 50		// maximum number of scattering events per neutron
	num_bins = 200		//number of 1-D bins (not really used)
	
// my additions - calculate the randome deviate function as needed
// and calculate the scattering power from the model function
//
	Variable left = leftx(ran_dev)
	Variable delta = deltax(ran_dev)
	
//c       total SAS cross-section
//
// input a test value for the incoherent scattering from water
//
//	sig_incoh = 5.6			//[1/cm] as calculated for H2O, now a parameter
//
//	SIG_SAS = zpow/thick
	zpow = sig_sas*thick			//since I now calculate the sig_sas from the model
	SIG_ABS = SIGABS_0 * WAVElength
	SIG_TOTAL =SIG_ABS + SIG_SAS + sig_incoh
//	Print "The TOTAL XSECTION. (CM-1) is ",sig_total
//	Print "The TOTAL SAS XSECTION. (CM-1) is ",sig_sas
	results[0] = sig_total
	results[1] = sig_sas
//	RATIO = SIG_ABS / SIG_TOTAL
	RATIO = sig_incoh / SIG_TOTAL
//!!!! the ratio is not yet properly weighted for the volume fractions of each component!!!
	
//c       assuming theta = sin(theta)...OK
	theta_max = wavelength*qmax/(2*pi)
//C     SET Theta-STEP SIZE.
	DTH = Theta_max/NUM_BINS
//	Print "theta bin size = dth = ",dth

//C     INITIALIZE COUNTERS.
	N1 = 0
	N2 = 0
	N3 = 0

//C     INITIALIZE ARRAYS.
	j1 = 0
	j2 = 0
	nt = 0
	nn=0
	
//C     MONITOR LOOP - looping over the number of incedent neutrons
//note that zz, is the z-position in the sample - NOT the scattering power

// NOW, start the loop, throwing neutrons at the sample.
	do
		Vx = 0.0			// Initialize direction vector.
		Vy = 0.0
		Vz = 1.0
		
		Theta = 0.0		//	Initialize scattering angle.
		Phi = 0.0			//	Intialize azimuthal angle.
		N1 += 1			//	Increment total number neutrons counter.
		DONE = 0			//	True when neutron is absorbed or when  scattered out of the sample.
		INDEX = 0			//	Set counter for number of scattering events.
		zz = 0.0			//	Set entering dimension of sample.
		
		do					//	Makes sure position is within circle.
			ran = abs(enoise(1))		//[0,1]
			xx = 2.0*R1*(Ran-0.5)		//X beam position of neutron entering sample.
			ran = abs(enoise(1))		//[0,1]
			yy = 2.0*R1*(Ran-0.5)		//Y beam position ...
			RR = SQRT(xx*xx+yy*yy)		//Radial position of neutron in incident beam.
		while(rr>r1)

		do    //Scattering Loop, will exit when "done" == 1
				// keep scattering multiple times until the neutron exits the sample
			ran = abs(enoise(1))		//[0,1]  RANDOM NUMBER FOR DETERMINING PATH LENGTH
			ll = PATH_len(ran,Sig_total)
			//Determine new scattering direction vector.
			err = NewDirection(vx,vy,vz,Theta,Phi)		//vx,vy,vz is updated, theta, phi unchanged by function

			//X,Y,Z-POSITION OF SCATTERING EVENT.
			xx += ll*vx
			yy += ll*vy
			zz += ll*vz
			RR = sqrt(xx*xx+yy*yy)		//radial position of scattering event.

			//Check whether interaction occurred within sample volume.
			IF (((zz > 0.0) && (zz < THICK)) && (rr < r2))
				//NEUTRON INTERACTED.
				INDEX += 1			//Increment counter of scattering events.
				IF(INDEX == 1)
					N2 += 1 		//Increment # of scat. neutrons
				Endif
				ran = abs(enoise(1))		//[0,1]
				//Split neutron interactions into scattering and absorption events
				IF(ran > ratio )		//C             NEUTRON SCATTERED coherently
					FIND_THETA = 0			//false
					DO
						//ran = abs(enoise(1))		//[0,1]
						//theta = Scat_angle(Ran,R_DAB,wavelength)	// CHOOSE DAB ANGLE -- this is 2Theta
						//Q0 = 2*PI*THETA/WAVElength					// John chose theta, calculated Q

						// pick a q-value from the deviate function
						// pnt2x truncates the point to an integer before returning the x
						// so get it from the wave scaling instead
						Q0 =left + binarysearchinterp(ran_dev,abs(enoise(1)))*delta
						theta = Q0/2/Pi*wavelength		//SAS approximation
						
						//Print "q0, theta = ",q0,theta
						
						FIND_THETA = 1		//always accept

					while(!find_theta)
					ran = abs(enoise(1))		//[0,1]
					PHI = 2.0*PI*Ran			//Chooses azimuthal scattering angle.
				ELSE
					//NEUTRON scattered incoherently
          	   // N3 += 1
           	  // DONE = 1
           	  // phi and theta are random over the entire sphere of scattering
           	  	
           	  	ran = abs(enoise(1))		//[0,1]
					theta = pi*ran
           	  	
           	  	ran = abs(enoise(1))		//[0,1]
					PHI = 2.0*PI*Ran			//Chooses azimuthal scattering angle.
				ENDIF		//(ran > ratio)
			ELSE
				//NEUTRON ESCAPES FROM SAMPLE -- bin it somewhere
				DONE = 1		//done = true, will exit from loop
				//Increment #scattering events array
				If (index <= N_Index)
					NN[INDEX] += 1
				Endif
				//IF (VZ > 1.0) 	// FIX INVALID ARGUMENT
					//VZ = 1.0 - 1.2e-7
				//ENDIF
				Theta_z = acos(Vz)		// Angle WITH respect to z axis.
				testQ = 2*pi*sin(theta_z)/wavelength
				
				// pick a random phi angle, and see if it lands on the detector
				// since the scattering is isotropic, I can safely pick a new, random value
				// this would not be true if simulating anisotropic scattering.
				testPhi = abs(enoise(1))*2*Pi
				// is it on the detector?	
				FindPixel(testQ,testPhi,wavelength,sdd,pixSize,xCtr,yCtr,xPixel,yPixel)
				
//				if(xPixel != xCtr && yPixel != yCtr)
//					Print "testQ,testPhi,xPixel,yPixel",testQ,testPhi,xPixel,yPixel
//				endif
				
				if(xPixel != -1 && yPixel != -1)
					isOn += 1
					//if(index==1)  // only the single scattering events
						MC_linear_data[xPixel][yPixel] += 1		//this is the total scattering, including multiple scattering
					//endif
				endif

				If(theta_z < theta_max)
					//Choose index for scattering angle array.
					//IND = NINT(THETA_z/DTH + 0.4999999)
					ind = round(THETA_z/DTH + 0.4999999)		//round is eqivalent to nint()
					NT[ind] += 1 			//Increment bin for angle.
					//Increment angle array for single scattering events.
					IF(INDEX == 1)
						j1[ind] += 1
					Endif
					//Increment angle array for double scattering events.
					IF (INDEX == 2)
						j2[ind] += 1
					Endif
				EndIf
				
			ENDIF
		while (!done)
	while(n1 < imon)

//	Print "Monte Carlo Done"
	trans_th = exp(-sig_total*thick)
//	TRANS_exp = (N1-N2) / N1 			// Transmission
	// dsigma/domega assuming isotropic scattering, with no absorption.
//	Print "trans_exp = ",trans_exp
//	Print "total # of neutrons reaching 2D detector",isOn
//	Print "fraction of incident neutrons reaching detector ",isOn/iMon
	results[2] = isOn
	results[3] = isOn/iMon
	
				
// OUTPUT of the 1D data, not necessary now since I want the 2D
//	Make/O/N=(num_bins) qvals,int_ms,sig_ms,int_sing,int_doub
//	ii=1
//	Print "binning"
//	do
//		//CALCULATE MEAN THETA IN BIN.
//		THETA_z = (ii-0.5)*DTH			// Mean scattering angle of bin.
//		//Solid angle of Ith bin.
//		D_OMEGA = 2*PI*ABS( COS(ii*DTH) - COS((ii-1)*DTH) )
//		//SOLID ANGLE CORRECTION: YIELDING CROSS-SECTION.
//		dS_dW = NT[ii]/(N1*THICK*Trans_th*D_OMEGA)
//		SIG = NT[ii]^0.5/(N1*THICK*Trans_th*D_OMEGA)
//		ds_dw_single = J1[ii]/(N1*THICK*Trans_th*D_OMEGA)
//		ds_dw_double = J2[ii]/(N1*THICK*Trans_th*D_OMEGA)
//		//Deviation from isotropic model.
//		qq = 4*pi*sin(0.5*theta_z)/wavelength
//		qvals[ii-1] = qq
//		int_ms[ii-1] = dS_dW
//		sig_ms[ii-1] = sig
//		int_sing[ii-1] = ds_dw_single
//		int_doub[ii-1] = ds_dw_double
//		//140     WRITE (7,145) qq,dS_dW,SIG,ds_dw_single,ds_dw_double
//		ii+=1
//	while(ii<=num_bins)
//	Print "done binning"


//        Write(7,*)
//        Write(7,*) '#Times Sc.   #Events    '
//      DO 150 I = 1,N_INDEX
//150    WRITE (7,146) I,NN(I)
//146   Format (I5,T10,F8.0)

///       Write(7,171) N1
//        Write(7,172) N2
//        Write(7,173) N3
//        Write(7,174) N2-N3

//171     Format('Total number of neutrons:         N1= ',E10.5)
///172     Format('Number of neutrons that interact: N2= ',E10.5)
//173     Format('Number of absorption events:      N3= ',E10.5)
//174     Format('# of neutrons that scatter out:(N2-N3)= ',E10.5)

//	Print "Total number of neutrons = ",N1
//	Print "Total number of neutrons that interact = ",N2
//	Print "Fraction of singly scattered neutrons = ",sum(j1,-inf,inf)/N2
	results[4] = N2
	results[5] = sum(j1,-inf,inf)/N2
	
	Tabs = (N1-N3)/N1
	Ttot = (N1-N2)/N1
	I1_sumI = NN[0]/(N2-N3)
//	Print "Tabs = ",Tabs
//	Print "Transmitted neutrons = ",Ttot
	results[6] = Ttot
//	Print "I1 / all I1 = ", I1_sumI
//	Print "DONE!"

End
////////	end of main function for calculating multiple scattering


// returns the random deviate as a wave
// and the total SAS cross-section [1/cm] sig_sas
Function 	CalculateRandomDeviate(func,coef,lam,outWave,SASxs)
	FUNCREF SANSModelAAO_MCproto func
	WAVE coef
	Variable lam
	String outWave
	Variable &SASxs

	Variable nPts_ran=10000,qu
	qu = 4*pi/lam		
	
	Make/O/N=(nPts_ran)/D root:Packages:NIST:SAS:Gq,root:Packages:NIST:SAS:xw		// if these waves are 1000 pts, the results are "pixelated"
	WAVE Gq = root:Packages:NIST:SAS:gQ
	WAVE xw = root:Packages:NIST:SAS:xw
	SetScale/I x (0+1e-6),qu*(1-1e-10),"", Gq,xw			//don't start at zero or run up all the way to qu to avoid numerical errors
	xw=x												//for the AAO
	func(coef,Gq,xw)									//call as AAO

//	Gq = x*Gq													// SAS approximation
	Gq = Gq*sin(2*asin(x/qu))/sqrt(1-(x/qu))			// exact
	//
	Integrate/METH=1 Gq/D=Gq_INT
	
	SASxs = lam*lam/2/pi*Gq_INT[nPts_ran-1]
	
	Gq_INT /= Gq_INT[nPts_ran-1]
	
	Duplicate/O Gq_INT $outWave

	return(0)
End

Function FindPixel(testQ,testPhi,lam,sdd,pixSize,xCtr,yCtr,xPixel,yPixel)
	Variable testQ,testPhi,lam,sdd,pixSize,xCtr,yCtr,&xPixel,&yPixel

	Variable theta,dy,dx,qx,qy
	//decompose to qx,qy
	qx = testQ*cos(testPhi)
	qy = testQ*sin(testPhi)

	//convert qx,qy to pixel locations relative to # of pixels x, y from center
	theta = 2*asin(qy*lam/4/pi)
	dy = sdd*tan(theta)
	yPixel = round(yCtr + dy/pixSize)
	
	theta = 2*asin(qx*lam/4/pi)
	dx = sdd*tan(theta)
	xPixel = round(xCtr + dx/pixSize)

	//if on detector, return xPix and yPix values, otherwise -1
	if(yPixel > 127 || yPixel < 0)
		yPixel = -1
	endif
	if(xPixel > 127 || xPixel < 0)
		xPixel = -1
	endif
	
	return(0)
End

Function MC_CheckFunctionAndCoef(funcStr,coefStr)
	String funcStr,coefStr
	
	SVAR/Z listStr=root:Packages:NIST:coefKWStr
	if(SVAR_Exists(listStr) == 1)
		String properCoefStr = StringByKey(funcStr, listStr  ,"=",";",0)
		if(cmpstr("",properCoefStr)==0)
			return(0)		//false, no match found, so properCoefStr is returned null
		endif
		if(cmpstr(coefStr,properCoefStr)==0)
			return(1)		//true, the coef is the correct match
		endif
	endif
	return(0)			//false, wrong coef
End

Function/S MC_getFunctionCoef(funcStr)
	String funcStr

	SVAR/Z listStr=root:Packages:NIST:coefKWStr
	String coefStr=""
	if(SVAR_Exists(listStr) == 1)
		coefStr = StringByKey(funcStr, listStr  ,"=",";",0)
	endif
	return(coefStr)
End

Function SANSModelAAO_MCproto(w,yw,xw)
	Wave w,yw,xw
	
	Print "in SANSModelAAO_MCproto function"
	return(1)
end

Function/S MC_FunctionPopupList()
	String list,tmp
	list = FunctionList("*",";","KIND:10")		//get every user defined curve fit function

	//now start to remove everything the user doesn't need to see...
		
	tmp = FunctionList("*_proto",";","KIND:10")		//prototypes
	list = RemoveFromList(tmp, list  ,";")
	//prototypes that show up if GF is loaded
	list = RemoveFromList("GFFitFuncTemplate", list)
	list = RemoveFromList("GFFitAllAtOnceTemplate", list)
	list = RemoveFromList("NewGlblFitFunc", list)
	list = RemoveFromList("NewGlblFitFuncAllAtOnce", list)
	list = RemoveFromList("GlobalFitFunc", list)
	list = RemoveFromList("GlobalFitAllAtOnce", list)
	list = RemoveFromList("GFFitAAOStructTemplate", list)
	list = RemoveFromList("NewGF_SetXWaveInList", list)
	list = RemoveFromList("NewGlblFitFuncAAOStruct", list)
	
	// more to remove as a result of 2D/Gizmo
	list = RemoveFromList("A_WMRunLessThanDelta", list)
	list = RemoveFromList("WMFindNaNValue", list)
	list = RemoveFromList("WM_Make3DBarChartParametricWave", list)
	list = RemoveFromList("UpdateQxQy2Mat", list)
	list = RemoveFromList("MakeBSMask", list)
	
	// MOTOFIT/GenFit bits
	tmp = "GEN_allatoncefitfunc;GEN_fitfunc;GetCheckBoxesState;MOTO_GFFitAllAtOnceTemplate;MOTO_GFFitFuncTemplate;MOTO_NewGF_SetXWaveInList;MOTO_NewGlblFitFunc;MOTO_NewGlblFitFuncAllAtOnce;"
	list = RemoveFromList(tmp, list  ,";")

	// SANS Reduction bits
	tmp = "ASStandardFunction;Ann_1D_Graph;Avg_1D_Graph;BStandardFunction;CStandardFunction;Draw_Plot1D;MyMat2XYZ;NewDirection;SANSModelAAO_MCproto;"
	list = RemoveFromList(tmp, list  ,";")
	list = RemoveFromList("Monte_SANS", list)

	tmp = FunctionList("f*",";","NPARAMS:2")		//point calculations
	list = RemoveFromList(tmp, list  ,";")
	
	tmp = FunctionList("fSmear*",";","NPARAMS:3")		//smeared dependency calculations
	list = RemoveFromList(tmp, list  ,";")
	
//	tmp = FunctionList("*X",";","KIND:4")		//XOPs, but these shouldn't show up if KIND:10 is used initially
//	Print "X* = ",tmp
//	print " "
//	list = RemoveFromList(tmp, list  ,";")
	
	//non-fit functions that I can't seem to filter out
	list = RemoveFromList("BinaryHS_PSF11;BinaryHS_PSF12;BinaryHS_PSF22;EllipCyl_Integrand;PP_Inner;PP_Outer;Phi_EC;TaE_Inner;TaE_Outer;",list,";")

	if(strlen(list)==0)
		list = "No functions plotted"
	endif
	
	list = SortList(list)
	return(list)
End              


//Function Scat_Angle(Ran,R_DAB,wavelength)
//	Variable Ran,r_dab,wavelength
//
//	Variable qq,arg,theta
//	qq = 1. / ( R_DAB*sqrt(1.0/Ran - 1.0) )
//	arg = qq*wavelength/(4*pi)
//	If (arg < 1.0)
//		theta = 2.*asin(arg)
//	else
//		theta = pi
//	endif
//	Return (theta)
//End

//calculates new direction (xyz) from an old direction
//theta and phi don't change
Function NewDirection(vx,vy,vz,theta,phi)
	Variable &vx,&vy,&vz
	Variable theta,phi
	
	Variable err=0,vx0,vy0,vz0
	Variable nx,ny,mag_xy,tx,ty,tz
	
	//store old direction vector
	vx0 = vx
	vy0 = vy
	vz0 = vz
	
	mag_xy = sqrt(vx0*vx0 + vy0*vy0)
	if(mag_xy < 1e-12)
		//old vector lies along beam direction
		nx = 0
		ny = 1
		tx = 1
		ty = 0
		tz = 0
	else
		Nx = -Vy0 / Mag_XY
		Ny = Vx0 / Mag_XY
		Tx = -Vz0*Vx0 / Mag_XY
		Ty = -Vz0*Vy0 / Mag_XY
		Tz = Mag_XY 
	endif
	
	//new scattered direction vector
	Vx = cos(phi)*sin(theta)*Tx + sin(phi)*sin(theta)*Nx + cos(theta)*Vx0
	Vy = cos(phi)*sin(theta)*Ty + sin(phi)*sin(theta)*Ny + cos(theta)*Vy0
	Vz = cos(phi)*sin(theta)*Tz + cos(theta)*Vz0
	
	Return(err)
End

Function path_len(aval,sig_tot)
	Variable aval,sig_tot
	
	Variable retval
	
	retval = -1*ln(1-aval)/sig_tot
	
	return(retval)
End

Window MC_SASCALC() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(787,44,1088,563)  /N=MC_SASCALC as "SANS Simulator"
	CheckBox MC_check0,pos={11,11},size={98,14},title="Use MC Simulation"
	CheckBox MC_check0,variable= root:Packages:NIST:SAS:gDoMonteCarlo
	SetVariable MC_setvar0,pos={11,38},size={144,15},bodyWidth=80,title="# of neutrons"
	SetVariable MC_setvar0,limits={-inf,inf,100},value= root:Packages:NIST:SAS:gImon
	SetVariable MC_setvar0_1,pos={11,121},size={131,15},bodyWidth=60,title="Thickness (cm)"
	SetVariable MC_setvar0_1,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gThick
	SetVariable MC_setvar0_2,pos={11,93},size={149,15},bodyWidth=60,title="Incoherent XS (cm)"
	SetVariable MC_setvar0_2,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gSig_incoh
	SetVariable MC_setvar0_3,pos={11,149},size={150,15},bodyWidth=60,title="Sample Radius (cm)"
	SetVariable MC_setvar0_3,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gR2
	PopupMenu MC_popup0,pos={11,63},size={162,20},proc=MC_ModelPopMenuProc,title="Model Function"
	PopupMenu MC_popup0,mode=1,value= #"MC_FunctionPopupList()"
	Button MC_button0,pos={17,455},size={50,20},proc=MC_DoItButtonProc,title="Do It"
	Button MC_button1,pos={15,484},size={80,20},proc=MC_Display2DButtonProc,title="Show 2D"
	
	SetDataFolder root:Packages:NIST:SAS:
	Edit/W=(13,174,284,435)/HOST=# results_desc,results
	ModifyTable width(Point)=0,width(results_desc)=150
	SetDataFolder root:
	RenameWindow #,T_results
	SetActiveSubwindow ##
EndMacro

Function MC_ModelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			SVAR gStr = root:Packages:NIST:SAS:gFuncStr 
			gStr = popStr
			
			break
	endswitch

	return 0
End

Function MC_DoItButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ReCalculateInten(1)
			break
	endswitch

	return 0
End


Function MC_Display2DButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ChangeDisplay(\"SAS\")"
			break
	endswitch

	return 0
End

/////UNUSED, testing routines that have note been updated to work with SASCALC
//
//Macro Simulate2D_MonteCarlo(imon,r1,r2,xCtr,yCtr,sdd,thick,wavelength,sig_incoh,funcStr)
//	Variable imon=100000,r1=0.6,r2=0.8,xCtr=100,yCtr=64,sdd=400,thick=0.1,wavelength=6,sig_incoh=0.1
//	String funcStr
//	Prompt funcStr, "Pick the model function", popup,	MC_FunctionPopupList()
//	
//	String coefStr = MC_getFunctionCoef(funcStr)
//	Variable pixSize = 0.5		// can't have 11 parameters in macro!
//	
//	if(!MC_CheckFunctionAndCoef(funcStr,coefStr))
//		Abort "The coefficients and function type do not match. Please correct the selections in the popup menus."
//	endif
//	
//	Make/O/D/N=10 root:Packages:NIST:SAS:results
//	Make/O/T/N=10 root:Packages:NIST:SAS:results_desc
//	
//	RunMonte(imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh,funcStr,coefStr,results)
//	
//End
//
//Function RunMonte(imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh,funcStr,coefStr)
//	Variable imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh
//	String funcStr,coefStr
//	WAVE results
//	
//	FUNCREF SANSModelAAO_MCproto func=$funcStr
//	
//	Monte_SANS(imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh,sig_sas,ran_dev,linear_data,results)
//End
//
////// END UNUSED BLOCK