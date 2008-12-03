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
// - Why am I off by a factor of 2.7 - 3.7 (MC too high) relative to real data?
//   I need to include efficiency (70%?) - do I knock these off be fore the simulation or do I 
//    really simulate that some fraction of neutrons on the detector don't actually get counted?
//   Is the flux estimate up-to-date?
// - Most importantly, this needs to be checked for correctness of the MC simulation
// X how can I get the "data" on absolute scale? This would be a great comparison vs. the ideal model calculation
// X why does my integrated tau not match up with John's analytical calculations? where are the assumptions?
// - get rid of all small angle assumptions - to make sure that the calculation is correct at all angles
// - my simulated transmission is larger than what is measured, even after correcting for the quartz cell.
//   Why? Do I need to include absorption? Just inherent problems with incoherent cross sections?
//
// X at the larger angles, is the "flat" detector being properly accounted for - in terms of
//   the solid angle and how many counts fall in that pixel. Am I implicitly defining a spherical detector
//   so that what I see is already "corrected"?
// X the MC will, of course benefit greatly from being XOPized. Maybe think about parallel implementation
//   by allowing the data arrays to accumulate. First pass at the XOP is done. Not pretty, not the speediest (5.8x)
//   but it is functional. Add spinCursor() for long calculations. See WaveAccess XOP example.
// X the background parameter for the model MUST be zero, or the integration for scattering
//    power will be incorrect. (now the LAST point in a copy of the coef wave is set to zero, only for the rad_dev calculation
// X fully use the SASCALC input, most importantly, flux on sample.
// X if no MC desired, still use the selected model
// X better display of MC results on panel
// X settings for "count for X seconds" or "how long to 1E6 cts on detector" (but 1E6 is typically too many counts...)
// X warn of projected simulation time
// - add quartz window scattering to the simulation somehow
// -?- do smeared models make any sense?? Yes, John agrees that they do, and may be used in a more realistic simulation
//   -?- but the random deviate can't be properly calculated...
// - make sure that the ratio of scattering coherent/incoherent is properly adjusted for the sample composition
//   or the volume fraction of solvent.
//
// X add to the results the fraction of coherently scattered neutrons that are singly scattered, different than
//   the overall fraction of singly scattered, and maybe more important to know.
//
// X change the fraction reaching the detector to exclude those that don't interact. These transmitted neutrons
//   aren't counted. Is the # that interact a better number?
//
// - do we want to NOT offset the data by a multiplicative factor as it is "frozen" , so that the 
//   effects on the absolute scale can be seen?
//
// X why is "pure" incoherent scattering giving me a q^-1 slope, even with the detector all the way back?
// - can I speed up by assuming everything interacts? This would compromise the ability to calculate multiple scattering
// X ask John how to verify what is going on
// - a number of models are now found to be ill-behaved when q=1e-10. Then the random deviate calculation blows up.
//   a warning has been added - but some models need a proper limiting value, and some (power-law) are simply unuseable
//   unless something else can be done.
//
//

// threaded call to the main function, adds up the individual runs, and returns what is to be displayed
// results is calculated and sent back for display
Function Monte_SANS_Threaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,linear_data,results

	//initialize ran1 in the XOP by passing a negative integer
	// does nothing in the Igor code
	Duplicate/O results retWave
	//results[0] = -1*(datetime)

	Variable NNeutron=inputWave[0]
	Variable i,nthreads= ThreadProcessorCount
	if(nthreads>2)		//only support 2 processors until I can figure out how to properly thread the XOP and to loop it
		nthreads=2
	endif
	
//	nthreads = 1
	
	variable mt= ThreadGroupCreate(nthreads)
	
	inputWave[0] = NNeutron/nthreads		//split up the number of neutrons
	
	for(i=0;i<nthreads;i+=1)
		Duplicate/O nt $("nt"+num2istr(i))		//new instance for each thread
		Duplicate/O j1 $("j1"+num2istr(i))
		Duplicate/O j2 $("j2"+num2istr(i))
		Duplicate/O nn $("nn"+num2istr(i))
		Duplicate/O linear_data $("linear_data"+num2istr(i))
		Duplicate/O retWave $("retWave"+num2istr(i))
		Duplicate/O inputWave $("inputWave"+num2istr(i))
		Duplicate/O ran_dev $("ran_dev"+num2istr(i))
		
		// ?? I need explicit wave references?
		// maybe I need to have everything in separate data folders - bu tI haven't tried that. seems like a reach.
		// more likely there is something bad going on in the XOP code.
		if(i==0)
			WAVE inputWave0,ran_dev0,nt0,j10,j20,nn0,linear_data0,retWave0
			retWave0[0] = -1*datetime		//to initialize ran3
			ThreadStart mt,i,Monte_SANS_W1(inputWave0,ran_dev0,nt0,j10,j20,nn0,linear_data0,retWave0)
			Print "started thread 0"
		endif
		if(i==1)
			WAVE inputWave1,ran_dev1,nt1,j11,j21,nn1,linear_data1,retWave1
			//retWave1[0] = -1*datetime		//to initialize ran3
			ThreadStart mt,i,Monte_SANS_W2(inputWave1,ran_dev1,nt1,j11,j21,nn1,linear_data1,retWave1)
			Print "started thread 1"
		endif
//		if(i==2)
//			WAVE inputWave2,ran_dev2,nt2,j12,j22,nn2,linear_data2,retWave2
//			retWave2[0] = -1*datetime		//to initialize ran3
//			ThreadStart mt,i,Monte_SANS_W(inputWave2,ran_dev2,nt2,j12,j22,nn2,linear_data2,retWave2)
//		endif
//		if(i==3)
//			WAVE inputWave3,ran_dev3,nt3,j13,j23,nn3,linear_data3,retWave3
//			retWave3[0] = -1*datetime		//to initialize ran3
//			ThreadStart mt,i,Monte_SANS_W(inputWave3,ran_dev3,nt3,j13,j23,nn3,linear_data3,retWave3)
//		endif
	endfor

// wait until done
	do
		variable tgs= ThreadGroupWait(mt,100)
	while( tgs != 0 )
	variable dummy= ThreadGroupRelease(mt)
	Print "done with all threads"

	// calculate all of the bits for the results
	if(nthreads == 1)
		nt = nt0		// add up each instance
		j1 = j10
		j2 = j20
		nn = nn0
		linear_data = linear_data0
		retWave = retWave0
	endif
	if(nthreads == 2)
		nt = nt0+nt1		// add up each instance
		j1 = j10+j11
		j2 = j20+j21
		nn = nn0+nn1
		linear_data = linear_data0+linear_data1
		retWave = retWave0+retWave1
	endif
//	if(nthreads == 3)
//		nt = nt0+nt1+nt2		// add up each instance
//		j1 = j10+j11+j12
//		j2 = j20+j21+j22
//		nn = nn0+nn1+nn2
//		linear_data = linear_data0+linear_data1+linear_data2
//		retWave = retWave0+retWave1+retWave2
//	endif
//	if(nthreads == 4)
//		nt = nt0+nt1+nt2+nt3		// add up each instance
//		j1 = j10+j11+j12+j13
//		j2 = j20+j21+j22+j23
//		nn = nn0+nn1+nn2+nn3
//		linear_data = linear_data0+linear_data1+linear_data2+linear_data3
//		retWave = retWave0+retWave1+retWave2+retWave3
//	endif
	
	// fill up the results wave
	Variable xc,yc
	xc=inputWave[3]
	yc=inputWave[4]
	results[0] = inputWave[9]+inputWave[10]		//total XS
	results[1] = inputWave[10]						//SAS XS
	results[2] = retWave[1]							//number that interact n2
	results[3] = retWave[2]	- linear_data[xc][yc]				//# reaching detector minus Q(0)
	results[4] = retWave[3]/retWave[1]				//avg# times scattered
	results[5] = retWave[4]/retWave[1]						//single coherent fraction
	results[6] = retWave[5]/retWave[1]				//double coherent fraction
	results[7] = retWave[6]/retWave[1]				//multiple scatter fraction
	results[8] = (retWave[0]-retWave[1])/retWave[0]			//transmitted fraction
	
	return(0)
End

// worker function for threads, does nothing except switch between XOP and Igor versions
ThreadSafe Function Monte_SANS_W1(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,linear_data,results
	
#if exists("Monte_SANSX")
	Monte_SANSX(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
#else
	Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
#endif

	return (0)
End
// worker function for threads, does nothing except switch between XOP and Igor versions
ThreadSafe Function Monte_SANS_W2(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,linear_data,results
	
#if exists("Monte_SANSX2")
	Monte_SANSX2(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
#else
	Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
#endif

	return (0)
End

// NON-threaded call to the main function returns what is to be displayed
// results is calculated and sent back for display
Function Monte_SANS_NotThreaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,linear_data,results

	//initialize ran1 in the XOP by passing a negative integer
	// does nothing in the Igor code, enoise is already initialized
	Duplicate/O results retWave
	WAVE retWave
	retWave[0] = -1*abs(trunc(100000*enoise(1)))
	
#if exists("Monte_SANSX")
	Monte_SANSX(inputWave,ran_dev,nt,j1,j2,nn,linear_data,retWave)
#else
	Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,linear_data,retWave)
#endif

	// fill up the results wave
	Variable xc,yc
	xc=inputWave[3]
	yc=inputWave[4]
	results[0] = inputWave[9]+inputWave[10]		//total XS
	results[1] = inputWave[10]						//SAS XS
	results[2] = retWave[1]							//number that interact n2
	results[3] = retWave[2]	- linear_data[xc][yc]				//# reaching detector minus Q(0)
	results[4] = retWave[3]/retWave[1]				//avg# times scattered
	results[5] = retWave[4]/retWave[1]						//single coherent fraction
	results[6] = retWave[5]/retWave[1]				//double coherent fraction
	results[7] = retWave[6]/retWave[1]				//multiple scatter fraction
	results[8] = (retWave[0]-retWave[1])/retWave[0]			//transmitted fraction
	
	return(0)
End



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

ThreadSafe Function Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,MC_linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,MC_linear_data,results

	Variable imon,r1,r2,xCtr,yCtr,sdd,pixSize,thick,wavelength,sig_incoh,sig_sas
	Variable NUM_BINS,N_INDEX
	Variable RHO,SIGSAS,SIGABS_0
	Variable ii,jj,IND,idum,INDEX,IR,NQ
	Variable qmax,theta_max,R_DAB,R0,BOUND,I0,q0,zpow
	Variable N1,N2,N3,DTH,zz,tt,SIG_SINGLE,xx,yy,PHI,UU,SIG
	Variable THETA,Ran,ll,D_OMEGA,RR,Tabs,Ttot,I1_sumI
	Variable G0,E_NT,E_NN,TRANS_th,Trans_exp,rat
	Variable GG,GG_ED,dS_dW,ds_dw_double,ds_dw_single
	Variable DONE,FIND_THETA,err		//used as logicals

	Variable Vx,Vy,Vz,Theta_z,qq
	Variable Sig_scat,Sig_abs,Ratio,Sig_total
	Variable isOn=0,testQ,testPhi,xPixel,yPixel
	Variable NSingleIncoherent,NSingleCoherent,NScatterEvents,incoherentEvent,coherentEvent
	Variable NDoubleCoherent,NMultipleScatter,countIt,detEfficiency
	
	detEfficiency = 1.0		//70% counting efficiency = 0.7
	
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
	
// my additions - calculate the random deviate function as needed
// and calculate the scattering power from the model function (passed in as a wave)
//
	Variable left = leftx(ran_dev)
	Variable delta = deltax(ran_dev)
	
//c       total SAS cross-section
//	SIG_SAS = zpow/thick
	zpow = sig_sas*thick			//since I now calculate the sig_sas from the model
	SIG_ABS = SIGABS_0 * WAVElength
	sig_abs = 0.0		//cm-1
	SIG_TOTAL =SIG_ABS + SIG_SAS + sig_incoh
//	Print "The TOTAL XSECTION. (CM-1) is ",sig_total
//	Print "The TOTAL SAS XSECTION. (CM-1) is ",sig_sas
//	results[0] = sig_total		//assign these after everything's done
//	results[1] = sig_sas
//	variable ratio1,ratio2
//	ratio1 = sig_abs/sig_total
//	ratio2 = sig_incoh/sig_total
//	// 0->ratio1 = abs
//	// ratio1 -> ratio2 = incoh
//	// > ratio2 = coherent
	RATIO = sig_incoh / SIG_TOTAL
	
//c       assuming theta = sin(theta)...OK
	theta_max = wavelength*qmax/(2*pi)
//C     SET Theta-STEP SIZE.
	DTH = Theta_max/NUM_BINS
//	Print "theta bin size = dth = ",dth

//C     INITIALIZE COUNTERS.
	N1 = 0
	N2 = 0
	N3 = 0
	NSingleIncoherent = 0
	NSingleCoherent = 0
	NDoubleCoherent = 0
	NMultipleScatter = 0
	NScatterEvents = 0

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
		DONE = 0			//	True when neutron is scattered out of the sample.
		INDEX = 0			//	Set counter for number of scattering events.
		zz = 0.0			//	Set entering dimension of sample.
		incoherentEvent = 0
		coherentEvent = 0
		
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
				ran = abs(enoise(1))		//[0,1]
				
//				if(ran<ratio1)
//					//absorption event
//					n3 +=1
//					done=1
//				else

				INDEX += 1			//Increment counter of scattering events.
				IF(INDEX == 1)
					N2 += 1 		//Increment # of scat. neutrons
				Endif
				//Split neutron interactions into scattering and absorption events
//				IF(ran > (ratio1+ratio2) )		//C             NEUTRON SCATTERED coherently
				IF(ran > ratio)		//C             NEUTRON SCATTERED coherently
					coherentEvent = 1
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
           	  // !can't just choose random theta and phi, won't be random over sphere solid angle
           	  	incoherentEvent = 1
           	  	
           	  	ran = abs(enoise(1))		//[0,1]
					theta = acos(2*ran-1)		
           	  	
           	  	ran = abs(enoise(1))		//[0,1]
					PHI = 2.0*PI*Ran			//Chooses azimuthal scattering angle.
				ENDIF		//(ran > ratio)
//				endif		// event was absorption
			ELSE
				//NEUTRON ESCAPES FROM SAMPLE -- bin it somewhere
				DONE = 1		//done = true, will exit from loop
				
//				countIt = 1
//				if(abs(enoise(1)) > detEfficiency)		//efficiency of 70% wired @top
//					countIt = 0					//detector does not register
//				endif
				
				//Increment #scattering events array
				If (index <= N_Index)
					NN[INDEX] += 1
				Endif
				
				if(index != 0)		//the neutron interacted at least once, figure out where it ends up

					Theta_z = acos(Vz)		// Angle WITH respect to z axis.
					testQ = 2*pi*sin(theta_z)/wavelength
					
					// pick a random phi angle, and see if it lands on the detector
					// since the scattering is isotropic, I can safely pick a new, random value
					// this would not be true if simulating anisotropic scattering.
					//testPhi = abs(enoise(1))*2*Pi
					testPhi = FindPhi(Vx,Vy)		//use the exiting phi value as defined by Vx and Vy
					
					// is it on the detector?	
					FindPixel(testQ,testPhi,wavelength,sdd,pixSize,xCtr,yCtr,xPixel,yPixel)
					
					if(xPixel != -1 && yPixel != -1)
						//if(index==1)  // only the single scattering events
							MC_linear_data[xPixel][yPixel] += 1		//this is the total scattering, including multiple scattering
						//endif
							isOn += 1		// neutron that lands on detector
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
					
					// increment all of the counters now since done==1 here and I'm sure to exit and get another neutron
					NScatterEvents += index		//total number of scattering events
					if(index == 1 && incoherentEvent == 1)
						NSingleIncoherent += 1
					endif
					if(index == 1 && coherentEvent == 1)
						NSingleCoherent += 1
					endif
					if(index == 2 && coherentEvent == 1 && incoherentEvent == 0)
						NDoubleCoherent += 1
					endif
					if(index > 1)
						NMultipleScatter += 1
					endif
					//Print "n1,index (x,y) = ",n1,index, xpixel,ypixel
					
				else	// if neutron escaped without interacting
				
					// then it must be a transmitted neutron
					// don't need to calculate, just increment the proper counters
					MC_linear_data[xCtr][yCtr] += 1
					isOn += 1
					nt[0] += 1
					
				endif		//if interacted
			ENDIF
		while (!done)
	while(n1 < imon)

//	Print "Monte Carlo Done"
	results[0] = n1
	results[1] = n2
	results[2] = isOn
	results[3] = NScatterEvents		//sum of # of times that neutrons scattered
	results[4] = NSingleCoherent		//# of events that are single, coherent
	results[5] = NDoubleCoherent
	results[6] = NMultipleScatter		//# of multiple scattering events
	
//	Print "# absorbed = ",n3

//	trans_th = exp(-sig_total*thick)
//	TRANS_exp = (N1-N2) / N1 			// Transmission
	// dsigma/domega assuming isotropic scattering, with no absorption.
//	Print "trans_exp = ",trans_exp
//	Print "total # of neutrons reaching 2D detector",isOn
//	Print "fraction of incident neutrons reaching detector ",isOn/iMon
	
//	Print "Total number of neutrons = ",N1
//	Print "Total number of neutrons that interact = ",N2
//	Print "Fraction of singly scattered neutrons = ",sum(j1,-inf,inf)/N2
//	results[2] = N2						//number that scatter
//	results[3] = isOn - MC_linear_data[xCtr][yCtr]			//# scattered reaching detector minus zero angle

	
//	Tabs = (N1-N3)/N1
//	Ttot = (N1-N2)/N1
//	I1_sumI = NN[0]/(N2-N3)
//	Print "Tabs = ",Tabs
//	Print "Transmitted neutrons = ",Ttot
//	results[8] = Ttot
//	Print "I1 / all I1 = ", I1_sumI

End
////////	end of main function for calculating multiple scattering


// returns the random deviate as a wave
// and the total SAS cross-section [1/cm] sig_sas
Function CalculateRandomDeviate(func,coef,lam,outWave,SASxs)
	FUNCREF SANSModelAAO_MCproto func
	WAVE coef
	Variable lam
	String outWave
	Variable &SASxs

	Variable nPts_ran=10000,qu
	qu = 4*pi/lam		
	
//	Make/O/N=(nPts_ran)/D root:Packages:NIST:SAS:Gq,root:Packages:NIST:SAS:xw		// if these waves are 1000 pts, the results are "pixelated"
//	WAVE Gq = root:Packages:NIST:SAS:gQ
//	WAVE xw = root:Packages:NIST:SAS:xw

// hard-wired into the Simulation directory rather than the SAS folder.
// plotting resolution-smeared models won't work any other way
	Make/O/N=(nPts_ran)/D root:Simulation:Gq,root:Simulation:xw		// if these waves are 1000 pts, the results are "pixelated"
	WAVE Gq = root:Simulation:gQ
	WAVE xw = root:Simulation:xw
	SetScale/I x (0+1e-6),qu*(1-1e-10),"", Gq,xw			//don't start at zero or run up all the way to qu to avoid numerical errors

///
/// if all of the coefficients are well-behaved, then the last point is the background
// and I can set it to zero here (only for the calculation)
	Duplicate/O coef,tmp_coef
	Variable num=numpnts(coef)
	tmp_coef[num-1] = 0
	
	xw=x												//for the AAO
	func(tmp_coef,Gq,xw)									//call as AAO

//	Gq = x*Gq													// SAS approximation
	Gq = Gq*sin(2*asin(x/qu))/sqrt(1-(x/qu))			// exact
	//
	Integrate/METH=1 Gq/D=Gq_INT
	
//	SASxs = lam*lam/2/pi*Gq_INT[nPts_ran-1]			//if the approximation is used
	SASxs = lam*Gq_INT[nPts_ran-1]
	
	Gq_INT /= Gq_INT[nPts_ran-1]
	
	Duplicate/O Gq_INT $outWave

	return(0)
End



ThreadSafe Function FindPixel(testQ,testPhi,lam,sdd,pixSize,xCtr,yCtr,xPixel,yPixel)
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
	tmp = "ASStandardFunction;Ann_1D_Graph;Avg_1D_Graph;BStandardFunction;CStandardFunction;Draw_Plot1D;MyMat2XYZ;NewDirection;SANSModelAAO_MCproto;Monte_SANS_Threaded;Monte_SANS_NotThreaded;Monte_SANS_W1;Monte_SANS_W2;"
	list = RemoveFromList(tmp, list  ,";")
	list = RemoveFromList("Monte_SANS", list)

	tmp = FunctionList("f*",";","NPARAMS:2")		//point calculations
	list = RemoveFromList(tmp, list  ,";")
	
	tmp = FunctionList("fSmear*",";","NPARAMS:3")		//smeared dependency calculations
	list = RemoveFromList(tmp, list  ,";")
	
	//non-fit functions that I can't seem to filter out
	list = RemoveFromList("BinaryHS_PSF11;BinaryHS_PSF12;BinaryHS_PSF22;EllipCyl_Integrand;PP_Inner;PP_Outer;Phi_EC;TaE_Inner;TaE_Outer;",list,";")
////////////////

	//more functions from analysis models (2008)
	tmp = "Barbell_Inner;Barbell_Outer;Barbell_integrand;BCC_Integrand;Integrand_BCC_Inner;Integrand_BCC_Outer;"
	list = RemoveFromList(tmp, list  ,";")
	tmp = "CapCyl;CapCyl_Inner;CapCyl_Outer;ConvLens;ConvLens_Inner;ConvLens_Outer;"
	list = RemoveFromList(tmp, list  ,";")
	tmp = "Dumb;Dumb_Inner;Dumb_Outer;FCC_Integrand;Integrand_FCC_Inner;Integrand_FCC_Outer;"
	list = RemoveFromList(tmp, list  ,";")
	tmp = "Integrand_SC_Inner;Integrand_SC_Outer;SC_Integrand;SphCyl;SphCyl_Inner;SphCyl_Outer;"
	list = RemoveFromList(tmp, list  ,";")

	//simplify the display, forcing smeared calculations behind the scenes
	tmp = FunctionList("Smear*",";","NPARAMS:1")		//smeared dependency calculations
	list = RemoveFromList(tmp, list  ,";")

	if(strlen(list)==0)
		list = "No functions plotted"
	endif
	
	list = SortList(list)
	
	list = "default;"+list
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
ThreadSafe Function NewDirection(vx,vy,vz,theta,phi)
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

ThreadSafe Function path_len(aval,sig_tot)
	Variable aval,sig_tot
	
	Variable retval
	
	retval = -1*ln(1-aval)/sig_tot
	
	return(retval)
End

// globals are initialized in SASCALC.ipf
Window MC_SASCALC() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(92,556,390,1028)/K=1 as "SANS Simulator"
	SetVariable MC_setvar0,pos={28,73},size={144,15},bodyWidth=80,title="# of neutrons"
	SetVariable MC_setvar0,format="%5.4g"
	SetVariable MC_setvar0,limits={-inf,inf,100},value= root:Packages:NIST:SAS:gImon
	SetVariable MC_setvar0_1,pos={28,119},size={131,15},bodyWidth=60,title="Thickness (cm)"
	SetVariable MC_setvar0_1,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gThick
	SetVariable MC_setvar0_2,pos={28,96},size={149,15},bodyWidth=60,title="Incoherent XS (cm)"
	SetVariable MC_setvar0_2,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gSig_incoh
	SetVariable MC_setvar0_3,pos={28,142},size={150,15},bodyWidth=60,title="Sample Radius (cm)"
	SetVariable MC_setvar0_3,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gR2
	PopupMenu MC_popup0,pos={13,13},size={165,20},proc=MC_ModelPopMenuProc,title="Model Function"
	PopupMenu MC_popup0,mode=1,value= #"MC_FunctionPopupList()"
	Button MC_button0,pos={17,181},size={130,20},proc=MC_DoItButtonProc,title="Do MC Simulation"
	Button MC_button1,pos={181,181},size={80,20},proc=MC_Display2DButtonProc,title="Show 2D"
	SetVariable setvar0_3,pos={105,484},size={50,20},disable=1
	GroupBox group0,pos={15,42},size={267,130},title="Monte Carlo"
	SetVariable cntVar,pos={190,73},size={80,15},proc=CountTimeSetVarProc,title="time(s)"
	SetVariable cntVar,format="%d"
	SetVariable cntVar,limits={1,10,1},value= root:Packages:NIST:SAS:gCntTime
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:SAS:
	Edit/W=(13,217,283,450)/HOST=#  results_desc,results
	ModifyTable format(Point)=1,width(Point)=0,width(results_desc)=150
	SetDataFolder fldrSav0
	RenameWindow #,T_results
	SetActiveSubwindow ##
EndMacro


Function CountTimeSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval

			// get the neutron flux, multiply, and reset the global for # neutrons
			NVAR imon=root:Packages:NIST:SAS:gImon
			imon = dval*beamIntensity()
			
			break
	endswitch

	return 0
End


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
			NVAR doMC = root:Packages:NIST:SAS:gDoMonteCarlo
			doMC = 1
			ReCalculateInten(1)
			doMC = 0		//so the next time won't be MC
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

// after a 2d data image is averaged in the usual way, take the waves and generate a "fake" folder of the 1d
// data, to appear as if it was loaded from a real data file.
//
// currently only works with SANS data, but can later be expanded to generate fake USANS data sets
//
Function	Fake1DDataFolder(qval,aveint,sigave,sigmaQ,qbar,fSubs,dataFolder)
	WAVE qval,aveint,sigave,sigmaQ,qbar,fSubs
	String dataFolder

	String baseStr=dataFolder
	if(DataFolderExists("root:"+baseStr))
		SetDataFolder $("root:"+baseStr)
	else
		NewDataFolder/S $("root:"+baseStr)
	endif

	////overwrite the existing data, if it exists
	Duplicate/O qval, $(baseStr+"_q")
	Duplicate/O aveint, $(baseStr+"_i")
	Duplicate/O sigave, $(baseStr+"_s")
//	Duplicate/O sigmaQ, $(baseStr+"sq")
//	Duplicate/O qbar, $(baseStr+"qb")
//	Duplicate/O fSubS, $(baseStr+"fs")

	// need to switch based on SANS/USANS
	if (isSANSResolution(sigave[0]))		//checks to see if the first point of the wave is <0]
		// make a resolution matrix for SANS data
		Variable np=numpnts(qval)
		Make/D/O/N=(np,4) $(baseStr+"_res")
		Wave res=$(baseStr+"_res")
		
		res[][0] = sigmaQ[p]		//sigQ
		res[][1] = qBar[p]		//qBar
		res[][2] = fSubS[p]		//fShad
		res[][3] = qval[p]		//Qvalues
		
		// keep a copy of everything in SAS too... the smearing wrapper function looks for 
		// data in folders based on waves it is passed - an I lose control of that
		Duplicate/O res, $("root:Packages:NIST:SAS:"+baseStr+"_res")
		Duplicate/O qval,  $("root:Packages:NIST:SAS:"+baseStr+"_q")
		Duplicate/O aveint,  $("root:Packages:NIST:SAS:"+baseStr+"_i")
		Duplicate/O sigave,  $("root:Packages:NIST:SAS:"+baseStr+"_s")
	else
		//the data is USANS data
		// nothing done here yet
//		dQv = -$w3[0]
		
//		USANS_CalcWeights(baseStr,dQv)
		
	endif

	//clean up		
	SetDataFolder root:
	
End



/////UNUSED, testing routines that have not been updated to work with SASCALC
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