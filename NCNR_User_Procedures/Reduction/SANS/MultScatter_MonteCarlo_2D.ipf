#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

//
// Monte Carlo simulator for SASCALC
// October 2008 SRK
//
// This code simulates the scattering for a selected model based on the instrument configuration
// This code is based directly on John Barker's code, which includes multiple scattering effects.
// A lot of the setup, wave creation, and post-calculations are done in SASCALC->ReCalculateInten()
//
//



// *** look into erand48() as the (pseudo) random number generator (it's a standard c-lib function, at least on unix)
//     and is apparantly thread safe. drand48() returns values [0.0,1.0)
//http://qnxcs.unomaha.edu/help/product/neutrino/lib_ref/e/erand48.html



// - Why am I off by a factor of 2.7 - 3.7 (MC too high) relative to real data?
//   I need to include efficiency (70%?) - do I knock these off before the simulation or do I 
//    really simulate that some fraction of neutrons on the detector don't actually get counted?
//   Is the flux estimate up-to-date? !! Flux estimates at NG3 are out-of-date....
// - my simulated transmission is larger than what is measured, even after correcting for the quartz cell.
//   Why? Do I need to include absorption? Just inherent problems with incoherent cross sections?

// - Most importantly, this needs to be checked for correctness of the MC simulation
// X how can I get the "data" on absolute scale? This would be a great comparison vs. the ideal model calculation
// X why does my integrated tau not match up with John's analytical calculations? where are the assumptions?
// - get rid of all small angle assumptions - to make sure that the calculation is correct at all angles

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
// -NO- can I speed up by assuming everything interacts? This would compromise the ability to calculate multiple scattering
// X ask John how to verify what is going on
// - a number of models are now found to be ill-behaved when q=1e-10. Then the random deviate calculation blows up.
//   a warning has been added - but some models need a proper limiting value, and some (power-law) are simply unuseable
//   unless something else can be done. Using a log-spacing of points doesn't seem to help, and it introduces a lot of
//   other problems. Not the way to go.
// - if the MC gags on a simulation, it often gets "stuck" and can't do the normal calculation from the model, which it
//   should always default to...
//
//

// setting the flag to 1 == 2D simulation
// any other value for flag == 1D simulation
//
// must remember to close/reopen the simulation control panel to get the correct panel
//
Function Set_2DMonteCarlo_Flag(value)
	Variable value
	
	NVAR flag=root:Packages:NIST:SAS:gDoMonteCarlo
	flag=value
	return(0)
end

// threaded call to the main function, adds up the individual runs, and returns what is to be displayed
// results is calculated and sent back for display
Function Monte_SANS_Threaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	WAVE inputWave,ran_dev,nt,j1,j2,nn,linear_data,results

	//initialize ran1 in the XOP by passing a negative integer
	// does nothing in the Igor code
	Duplicate/O results retWave

	Variable NNeutron=inputWave[0]
	Variable i,nthreads= ThreadProcessorCount
	if(nthreads>2)		//only support 2 processors until I can figure out how to properly thread the XOP and to loop it
		nthreads=2
	endif
	
//	nthreads = 1
	
	variable mt= ThreadGroupCreate(nthreads)
	NVAR gInitTime = root:Packages:NIST:SAS:gRanDateTime		//time that SASCALC was started

	
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
			retWave0 = 0		//clear the return wave
			retWave0[0] = -1*(datetime-gInitTime)		//to initialize ran3
			ThreadStart mt,i,Monte_SANS_W1(inputWave0,ran_dev0,nt0,j10,j20,nn0,linear_data0,retWave0)
			Print "started thread 0"
		endif
		if(i==1)
			WAVE inputWave1,ran_dev1,nt1,j11,j21,nn1,linear_data1,retWave1
			retWave1 = 0			//clear the return wave
			retWave1[0] = -1*(datetime-gInitTime)		//to initialize ran1
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
	results[5] = retWave[4]/retWave[7]						//single coherent fraction
	results[6] = retWave[5]/retWave[7]				//multiple coherent fraction
	results[7] = retWave[6]/retWave[1]				//multiple scatter fraction
	results[8] = (retWave[0]-retWave[1])/retWave[0]			//transmitted fraction
	
	return(0)
End

// worker function for threads, does nothing except switch between XOP and Igor versions
//
// uses ran3
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
//
// uses ran1
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
	results[5] = retWave[4]/retWave[7]						//single coherent fraction
	results[6] = retWave[5]/retWave[7]				//double coherent fraction
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
	Variable NMultipleCoherent,NCoherentEvents
	
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
	NMultipleCoherent = 0
	NCoherentEvents = 0

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
					coherentEvent += 1
					FIND_THETA = 0			//false
					DO
						//ran = abs(enoise(1))		//[0,1]
						//theta = Scat_angle(Ran,R_DAB,wavelength)	// CHOOSE DAB ANGLE -- this is 2Theta
						//Q0 = 2*PI*THETA/WAVElength					// John chose theta, calculated Q

						// pick a q-value from the deviate function
						// pnt2x truncates the point to an integer before returning the x
						// so get it from the wave scaling instead
						Q0 =left + binarysearchinterp(ran_dev,abs(enoise(1)))*delta
						theta = Q0/2/Pi*wavelength		//SAS approximation. 1% error at theta=30 deg (theta/2=15deg)
						
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
           	  	incoherentEvent += 1
           	  	
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
					testPhi = MC_FindPhi(Vx,Vy)		//use the exiting phi value as defined by Vx and Vy
					
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
					if(coherentEvent >= 1 && incoherentEvent == 0)
						NCoherentEvents += 1
					endif
					if(coherentEvent > 1 && incoherentEvent == 0)
						NMultipleCoherent += 1
					endif
					
					
					//Print "n1,index (x,y) = ",n1,index, xpixel,ypixel
					
				else	// if neutron escaped without interacting
				
					// then it must be a transmitted neutron
					// don't need to calculate, just increment the proper counters
					
					MC_linear_data[xCtr+xx/pixsize][yCtr+yy/pixsize] += 1
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
	results[3] = NScatterEvents		//sum of # of times that neutrons scattered (coh+incoh)
	results[4] = NSingleCoherent		//# of events that are single, coherent
	results[5] = NMultipleCoherent	//# of scattered neutrons that are coherently scattered more than once
	results[6] = NMultipleScatter		//# of scattered neutrons that are scattered more than once (coh and/or incoh)
	results[7] = NCoherentEvents		//# of scattered neutrons that are scattered coherently one or more times
	
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
	
// hard-wired into the Simulation directory rather than the SAS folder.
// plotting resolution-smeared models won't work any other way
	Make/O/N=(nPts_ran)/D root:Simulation:Gq,root:Simulation:xw		// if these waves are 1000 pts, the results are "pixelated"
	WAVE Gq = root:Simulation:gQ
	WAVE xw = root:Simulation:xw
	SetScale/I x (0+1e-4),qu*(1-1e-10),"", Gq,xw			//don't start at zero or run up all the way to qu to avoid numerical errors

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
	//
	Integrate/METH=1 Gq/D=Gq_INT
	
//	SASxs = lam*lam/2/pi*Gq_INT[nPts_ran-1]			//if the approximation is used
	SASxs = lam*Gq_INT[nPts_ran-1]
	
	Gq_INT /= Gq_INT[nPts_ran-1]
	
	Duplicate/O Gq_INT $outWave

	return(0)
End

// returns the random deviate as a wave
// and the total SAS cross-section [1/cm] sig_sas
//
// uses a log spacing of x for better coverage
// downside is that it doesn't use built-in integrate, which is automatically cumulative
//
// --- Currently does not work - since the usage of the random deviate in the MC routine is based on the 
// wave properties of ran_dev, that is it must have the proper scaling and be equally spaced.
//
// -- not really sure that this will solve any of the problems with some functions (notably those with power-laws)
// giving unreasonably large SAS cross sections. (>>10)
//
Function CalculateRandomDeviate_log(func,coef,lam,outWave,SASxs)
	FUNCREF SANSModelAAO_MCproto func
	WAVE coef
	Variable lam
	String outWave
	Variable &SASxs

	Variable nPts_ran=1000,qu,qmin,ii
	qmin=1e-5
	qu = 4*pi/lam		

// hard-wired into the Simulation directory rather than the SAS folder.
// plotting resolution-smeared models won't work any other way
	Make/O/N=(nPts_ran)/D root:Simulation:Gq,root:Simulation:xw		// if these waves are 1000 pts, the results are "pixelated"
	WAVE Gq = root:Simulation:gQ
	WAVE xw = root:Simulation:xw
//	SetScale/I x (0+1e-4),qu*(1-1e-10),"", Gq,xw			//don't start at zero or run up all the way to qu to avoid numerical errors
	xw =  alog(log(qmin) + x*((log(qu)-log(qmin))/nPts_ran))

/// if all of the coefficients are well-behaved, then the last point is the background
// and I can set it to zero here (only for the calculation)
	Duplicate/O coef,tmp_coef
	Variable num=numpnts(coef)
	tmp_coef[num-1] = 0
	
	func(tmp_coef,Gq,xw)									//call as AAO
	Gq = Gq*sin(2*asin(xw/qu))/sqrt(1-(xw/qu))			// exact

	
	Duplicate/O Gq Gq_INT
	Gq_INT = 0
	for(ii=0;ii<nPts_ran;ii+=1)
		Gq_INT[ii] = AreaXY(xw,Gq,qmin,xw[ii])
	endfor
	
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
	list = User_FunctionPopupList()
	
	//simplify the display, forcing smeared calculations behind the scenes
	tmp = FunctionList("Smear*",";","NPARAMS:1")		//smeared dependency calculations
	list = RemoveFromList(tmp, list,";")


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
// coordinates if I make this part of the panel - but this breaks other things...
//
//Proc MC_SASCALC()
////	PauseUpdate; Silent 1		// building window...
//
////	NewPanel /W=(92,556,390,1028)/K=1 as "SANS Simulator"
//	SetVariable MC_setvar0,pos={491,73},size={144,15},bodyWidth=80,title="# of neutrons"
//	SetVariable MC_setvar0,format="%5.4g"
//	SetVariable MC_setvar0,limits={-inf,inf,100},value= root:Packages:NIST:SAS:gImon
//	SetVariable MC_setvar0_1,pos={491,119},size={131,15},bodyWidth=60,title="Thickness (cm)"
//	SetVariable MC_setvar0_1,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gThick
//	SetVariable MC_setvar0_2,pos={491,96},size={149,15},bodyWidth=60,title="Incoherent XS (cm)"
//	SetVariable MC_setvar0_2,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gSig_incoh
//	SetVariable MC_setvar0_3,pos={491,142},size={150,15},bodyWidth=60,title="Sample Radius (cm)"
//	SetVariable MC_setvar0_3,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gR2
//	PopupMenu MC_popup0,pos={476,13},size={165,20},proc=MC_ModelPopMenuProc,title="Model Function"
//	PopupMenu MC_popup0,mode=1,value= #"MC_FunctionPopupList()"
//	Button MC_button0,pos={480,181},size={130,20},proc=MC_DoItButtonProc,title="Do MC Simulation"
//	Button MC_button1,pos={644,181},size={80,20},proc=MC_Display2DButtonProc,title="Show 2D"
//	SetVariable setvar0_3,pos={568,484},size={50,20},disable=1
//	GroupBox group0,pos={478,42},size={267,130},title="Monte Carlo"
//	SetVariable cntVar,pos={653,73},size={80,15},proc=CountTimeSetVarProc,title="time(s)"
//	SetVariable cntVar,format="%d"
//	SetVariable cntVar,limits={1,10,1},value= root:Packages:NIST:SAS:gCntTime
//	
//	String fldrSav0= GetDataFolder(1)
//	SetDataFolder root:Packages:NIST:SAS:
//	Edit/W=(476,217,746,450)/HOST=#  results_desc,results
//	ModifyTable format(Point)=1,width(Point)=0,width(results_desc)=150
//	SetDataFolder fldrSav0
//	RenameWindow #,T_results
//	SetActiveSubwindow ##
//EndMacro

// as a stand-alone panel, extra control bar  (right) and subwindow implementations don't work right 
// for various reasons...
Window MC_SASCALC() : Panel

	// when opening the panel, set the raw counts check to 1
	root:Packages:NIST:SAS:gRawCounts = 1
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(92,556,713,818)/K=1 as "SANS Simulator"
	SetVariable MC_setvar0,pos={28,73},size={144,15},bodyWidth=80,title="# of neutrons"
	SetVariable MC_setvar0,format="%5.4g"
	SetVariable MC_setvar0,limits={0,inf,100},value= root:Packages:NIST:SAS:gImon
	SetVariable MC_setvar0_1,pos={28,119},size={131,15},bodyWidth=60,title="Thickness (cm)"
	SetVariable MC_setvar0_1,limits={0,inf,0.1},value= root:Packages:NIST:SAS:gThick
	SetVariable MC_setvar0_2,pos={28,96},size={149,15},bodyWidth=60,title="Incoherent XS (cm)"
	SetVariable MC_setvar0_2,limits={0,inf,0.1},value= root:Packages:NIST:SAS:gSig_incoh
	SetVariable MC_setvar0_3,pos={28,142},size={150,15},bodyWidth=60,title="Sample Radius (cm)"
	SetVariable MC_setvar0_3,limits={-inf,inf,0.1},value= root:Packages:NIST:SAS:gR2
	PopupMenu MC_popup0,pos={13,13},size={165,20},proc=MC_ModelPopMenuProc,title="Model Function"
	PopupMenu MC_popup0,mode=1,value= #"MC_FunctionPopupList()"
	Button MC_button0,pos={17,181},size={130,20},proc=MC_DoItButtonProc,title="Do MC Simulation"
	Button MC_button0,fColor=(3,52428,1)
	Button MC_button1,pos={17,208},size={80,20},proc=MC_Display2DButtonProc,title="Show 2D"
	SetVariable setvar0_3,pos={105,484},size={50,20},disable=1
	GroupBox group0,pos={15,42},size={267,130},title="Monte Carlo"
	SetVariable cntVar,pos={185,73},size={90,15},proc=CountTimeSetVarProc,title="time(s)"
	SetVariable cntVar,format="%d"
	SetVariable cntVar,limits={1,3600,1},value= root:Packages:NIST:SAS:gCntTime
	Button MC_button2,pos={17,234},size={100,20},proc=SaveAsVAXButtonProc,title="Save 2D VAX"
	CheckBox check0,pos={216,180},size={68,14},title="Raw counts",variable = root:Packages:NIST:SAS:gRawCounts
	CheckBox check0_1,pos={216,199},size={60,14},title="Yes Offset",variable= root:Packages:NIST:SAS:gDoTraceOffset
	CheckBox check0_2,pos={216,199+19},size={60,14},title="Beam Stop in",variable= root:Packages:NIST:SAS:gBeamStopIn
	CheckBox check0_3,pos={216,199+2*19},size={60,14},title="use XOP",variable= root:Packages:NIST:SAS:gUse_MC_XOP
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:NIST:SAS:
	Edit/W=(344,23,606,248)/HOST=#  results_desc,results
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
// ---- use FakeUSANSDataFolder() if you want to fake a 1D USANS data set ----
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
	
	//clean up		
	SetDataFolder root:
	
End

// writes out a VAX binary data file
// automatically generates a name
// will prompt for the sample label
//
// currently hard-wired for SAS data folder
//
Function SaveAsVAXButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String fullpath="",destStr=""
	Variable refnum
	
	fullpath = Write_RawData_File("SAS","",0)
	
	// write out the results into a text file
	destStr = "root:Packages:NIST:SAS:"
	SetDataFolder $destStr

	WAVE results=results
	WAVE/T results_desc=results_desc
	
	//check each wave
	If(!(WaveExists(results)))
		Abort "results DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(results_desc)))
		Abort "results_desc DNExist WriteVAXData()"
	Endif
	
	Open refNum as fullpath+".txt"
		wfprintf refNum, "%30s\t\t%g\r",results_desc,results
		FStatus refNum
		FSetPos refNum,V_logEOF
	Close refNum
	
	///////////////////////////////
	
	// could also automatically do the average here, but probably not worth the the effort...
	
	SetDataFolder root:
	
	return(0)
End

// calculates the fraction of the scattering that reaches the detector, given the random deviate function
// and qmin and qmax
//
//
// still some question of the corners and number of pixels per q-bin
Function FractionReachingDetector(ran_dev,Qmin,Qmax)
	wave ran_dev
	Variable Qmin,Qmax
	
	Variable r1,r2,frac
	r1=x2pnt(ran_dev,Qmin)
	r2=x2pnt(ran_dev,Qmax)
	
	// no normalization needed - the full q-range is defined as [0,1]
	frac = ran_dev[r2] - ran_dev[r1]
	
	return frac
End


/// called in SASCALC:ReCalculateInten()
Function 	Simulate_2D_MC(funcStr,aveint,qval,sigave,sigmaq,qbar,fsubs)
	String funcStr
	WAVE aveint,qval,sigave,sigmaq,qbar,fsubs

	NVAR doMonteCarlo = root:Packages:NIST:SAS:gDoMonteCarlo		// == 1 if 2D MonteCarlo set by hidden flag
	WAVE rw=root:Packages:NIST:SAS:realsRead

	NVAR imon = root:Packages:NIST:SAS:gImon
	NVAR thick = root:Packages:NIST:SAS:gThick
	NVAR sig_incoh = root:Packages:NIST:SAS:gSig_incoh
	NVAR r2 = root:Packages:NIST:SAS:gR2

	// do the simulation here, or not
	Variable r1,xCtr,yCtr,sdd,pixSize,wavelength
	String coefStr,abortStr,str

	r1 = rw[24]/2/10		// sample diameter convert diam in [mm] to radius in cm
	xCtr = rw[16]
	yCtr = rw[17]
	sdd = rw[18]*100		//conver header of [m] to [cm]
	pixSize = rw[10]/10		// convert pix size in mm to cm
	wavelength = rw[26]
	coefStr = MC_getFunctionCoef(funcStr)
	
	if(!MC_CheckFunctionAndCoef(funcStr,coefStr))
		doMonteCarlo = 0		//we're getting out now, reset the flag so we don't continually end up here
		Abort "The coefficients and function type do not match. Please correct the selections in the popup menus."
	endif
	
	Variable sig_sas
//		FUNCREF SANSModelAAO_MCproto func=$("fSmeared"+funcStr)		//a wrapper for the structure version
	FUNCREF SANSModelAAO_MCproto func=$(funcStr)		//unsmeared
	WAVE results = root:Packages:NIST:SAS:results
	WAVE linear_data = root:Packages:NIST:SAS:linear_data
	WAVE data = root:Packages:NIST:SAS:data

	results = 0
	linear_data = 0
	
	CalculateRandomDeviate(func,$coefStr,wavelength,"root:Packages:NIST:SAS:ran_dev",SIG_SAS)
	if(sig_sas > 100)
		sprintf abortStr,"sig_sas = %g. Please check that the model coefficients have a zero background, or the low q is well-behaved.",sig_sas
		Abort abortStr
	endif
	
	WAVE ran_dev=$"root:Packages:NIST:SAS:ran_dev"
	
	Make/O/D/N=5000 root:Packages:NIST:SAS:nt=0,root:Packages:NIST:SAS:j1=0,root:Packages:NIST:SAS:j2=0
	Make/O/D/N=100 root:Packages:NIST:SAS:nn=0
	Make/O/D/N=11 root:Packages:NIST:SAS:inputWave=0
	
	WAVE nt = root:Packages:NIST:SAS:nt
	WAVE j1 = root:Packages:NIST:SAS:j1
	WAVE j2 = root:Packages:NIST:SAS:j2
	WAVE nn = root:Packages:NIST:SAS:nn
	WAVE inputWave = root:Packages:NIST:SAS:inputWave

	inputWave[0] = imon
	inputWave[1] = r1
	inputWave[2] = r2
	inputWave[3] = xCtr
	inputWave[4] = yCtr
	inputWave[5] = sdd
	inputWave[6] = pixSize
	inputWave[7] = thick
	inputWave[8] = wavelength
	inputWave[9] = sig_incoh
	inputWave[10] = sig_sas

	linear_data = 0		//initialize

	Variable t0,trans
	
	// get a time estimate, and give the user a chance to exit if they're unsure.
	t0 = stopMStimer(-2)
	inputWave[0] = 1000
	NVAR useXOP = root:Packages:NIST:SAS:gUse_MC_XOP		//if zero, will use non-threaded Igor code
	
	if(useXOP)
		//use a single thread, otherwise time is dominated by overhead
		Monte_SANS_NotThreaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	else
		Monte_SANS(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	endif
	
	t0 = (stopMSTimer(-2) - t0)*1e-6
	t0 *= imon/1000/ThreadProcessorCount			//projected time, in seconds (using threads for the calculation)
	inputWave[0] = imon		//reset
	
	if(t0>10)
		sprintf str,"The simulation will take approximately %d seconds.\r- Proceed?",t0
		DoAlert 1,str
		if(V_flag == 2)
			doMonteCarlo = 0
			reCalculateInten(1)		//come back in and do the smeared calculation
			return(0)
		endif
	endif
	
	linear_data = 0		//initialize
// threading crashes!! - there must be some operation in the XOP that is not threadSafe. What, I don't know...
// I think it's the ran() calls, being "non-reentrant". So the XOP now defines two separate functions, that each
// use a different rng. This works. 1.75x speedup.	
	t0 = stopMStimer(-2)

	if(useXOP)
		Monte_SANS_Threaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	else
		Monte_SANS_NotThreaded(inputWave,ran_dev,nt,j1,j2,nn,linear_data,results)
	endif
	
	t0 = (stopMSTimer(-2) - t0)*1e-6
	Printf  "MC sim time = %g seconds\r",t0
	
	trans = results[8]			//(n1-n2)/n1
	if(trans == 0)
		trans = 1
	endif

	Print "counts on detector, including transmitted = ",sum(linear_data,-inf,inf)
	
//		linear_data[xCtr][yCtr] = 0			//snip out the transmitted spike
//		Print "counts on detector not transmitted = ",sum(linear_data,-inf,inf)

	// or simulate a beamstop
	NVAR MC_BS_in = root:Packages:NIST:SAS:gBeamStopIn		//if zero, beam stop is "out", as in a transmission measurement
	
	Variable rad=beamstopDiam()/2		//beamstop radius in cm
	if(MC_BS_in)
		rad /= 0.5				//convert cm to pixels
		rad += 0.					// (no - it cuts off the low Q artificially) add an extra pixel to each side to account for edge
		Duplicate/O linear_data,root:Packages:NIST:SAS:tmp_mask//,root:Packages:NIST:SAS:MC_linear_data
		WAVE tmp_mask = root:Packages:NIST:SAS:tmp_mask
		tmp_mask = (sqrt((p-xCtr)^2+(q-yCtr)^2) < rad) ? 0 : 1		//behind beamstop = 0, away = 1
		
		linear_data *= tmp_mask
	endif
	
	results[9] = sum(linear_data,-inf,inf)
	//		Print "counts on detector not behind beamstop = ",results[9]
	
	// convert to absolute scale
	Variable kappa		//,beaminten = beamIntensity()
//		kappa = beamInten*pi*r1*r1*thick*(pixSize/sdd)^2*trans*(iMon/beaminten)
	kappa = thick*(pixSize/sdd)^2*trans*iMon
	
	//use kappa to get back to counts => linear_data = round(linear_data*kappa)
	Note/K linear_data ,"KAPPA="+num2str(kappa)+";"
	
	NVAR rawCts = root:Packages:NIST:SAS:gRawCounts
	if(!rawCts)			//go ahead and do the linear scaling
		linear_data = linear_data / kappa
	endif		
	data = linear_data
	
	// re-average the 2D data
	S_CircularAverageTo1D("SAS")
	
	// put the new result into the simulation folder
	Fake1DDataFolder(qval,aveint,sigave,sigmaQ,qbar,fSubs,"Simulation")	
				

	return(0)
end

//phi is defined from +x axis, proceeding CCW around [0,2Pi]
ThreadSafe Function MC_FindPhi(vx,vy)
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





Window Sim_1D_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(92,556,713,818)/K=1 as "1D SANS Simulator"
	SetVariable cntVar,pos={26,68},size={160,15},title="Counting time(s)",format="%d"
	SetVariable cntVar,limits={1,36000,10},value= root:Packages:NIST:SAS:gCntTime
	SetVariable cntVar, proc=Sim_1D_CountTimeSetVarProc
	SetVariable MC_setvar0_1,pos={26,91},size={160,15},title="Thickness (cm)"
	SetVariable MC_setvar0_1,limits={0,inf,0.1},value= root:Packages:NIST:SAS:gThick
	SetVariable MC_setvar0_1, proc=Sim_1D_SamThickSetVarProc

	SetVariable MC_setvar0_3,pos={26,114},size={160,15},title="Sample Transmission"
	SetVariable MC_setvar0_3,limits={0,1,0.01},value= root:Packages:NIST:SAS:gSamTrans
	SetVariable MC_setvar0_3, proc=Sim_1D_SamTransSetVarProc

	PopupMenu MC_popup0,pos={13,13},size={165,20},proc=Sim_1D_ModelPopMenuProc,title="Model Function"
	PopupMenu MC_popup0,mode=1,value= #"MC_FunctionPopupList()"
	Button MC_button0,pos={17,181},size={130,20},proc=Sim_1D_DoItButtonProc,title="Do 1D Simulation"
	Button MC_button0,fColor=(3,52428,1)
	Button MC_button1,pos={17,211},size={150,20},proc=Save_1DSimData,title="Save Simulated Data"
	GroupBox group0,pos={15,42},size={280,130},title="Sample Setup"
	CheckBox check0_1,pos={216,179},size={60,14},title="Yes Offset",variable= root:Packages:NIST:SAS:gDoTraceOffset
	CheckBox check0_2,pos={216,199},size={60,14},title="Abs scale?",variable= root:Packages:NIST:SAS:g_1D_DoABS
	CheckBox check0_3,pos={216,219},size={60,14},title="Noise?",variable= root:Packages:NIST:SAS:g_1D_AddNoise
	
// a box for the results
	GroupBox group1,pos={314,23},size={277,163},title="Simulation Results"
	ValDisplay valdisp0,pos={326,48},size={220,13},title="Total detector counts"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= root:Packages:NIST:SAS:g_1DTotCts
	ValDisplay valdisp0_1,pos={326,72},size={220,13},title="Estimated count rate (1/s)"
	ValDisplay valdisp0_1,limits={0,0,0},barmisc={0,1000},value=root:Packages:NIST:SAS:g_1DEstDetCR
	ValDisplay valdisp0_2,pos={326,96},size={220,13},title="Fraction of beam scattered"
	ValDisplay valdisp0_2,limits={0,0,0},barmisc={0,1000},value= root:Packages:NIST:SAS:g_1DFracScatt
	ValDisplay valdisp0_3,pos={326,121},size={220,13},title="Estimated transmission"
	ValDisplay valdisp0_3,limits={0,0,0},barmisc={0,1000},value=root:Packages:NIST:SAS:g_1DEstTrans
	ValDisplay valdisp0_4,pos={326,145},size={220,13},title="Multiple Coherent Scattering"
	ValDisplay valdisp0_4,limits={0,0,0},barmisc={0,1000},value=root:Packages:NIST:SAS:g_MultScattFraction
	// set the flags here -- do the simulation, but not 2D
	
	root:Packages:NIST:SAS:doSimulation	= 1 	// == 1 if 1D simulated data, 0 if other from the checkbox
	root:Packages:NIST:SAS:gDoMonteCarlo	 = 0  // == 1 if 2D MonteCarlo set by hidden flag

	
EndMacro

Function Sim_1D_CountTimeSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval

			ReCalculateInten(1)
			
			break
	endswitch

	return 0
End

Function Sim_1D_SamThickSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval

			ReCalculateInten(1)
			
			break
	endswitch

	return 0
End

Function Sim_1D_SamTransSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval

			ReCalculateInten(1)
			
			break
	endswitch

	return 0
End


Function Sim_1D_ModelPopMenuProc(pa) : PopupMenuControl
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


Function Sim_1D_DoItButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			ReCalculateInten(1)
			
			break
	endswitch

	return 0
End


//
//
//
Function Save_1DSimData(ctrlName) : ButtonControl
	String ctrlName

	String type="SAS",fullpath=""
	Variable dialog=1		//=1 will present dialog for name
	
	String destStr=""
	destStr = "root:Packages:NIST:"+type
	
	Variable refNum
	String formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"
	String fname,ave="C",hdrStr1="",hdrStr2=""
	Variable step=1
	
	If(1)
		//setup a "fake protocol" wave, sice I have no idea of the current state of the data
		Make/O/T/N=8 root:myGlobals:Protocols:SIMProtocol
		Wave/T SIMProtocol = $"root:myGlobals:Protocols:SIMProtocol"
		String junk="****SIMULATED DATA****"
		//stick in the fake protocol...
		NVAR ctTime = root:Packages:NIST:SAS:gCntTime
		NVAR totalCts = root:Packages:NIST:SAS:g_1DTotCts			//summed counts (simulated)
		NVAR detCR = root:Packages:NIST:SAS:g_1DEstDetCR		// estimated detector count rate
		NVAR fractScat = root:Packages:NIST:SAS:g_1DFracScatt
		NVAR mScat = root:Packages:NIST:SAS:g_MultScattFraction
	
		SIMProtocol[0] = junk
		SIMProtocol[1] = "\tCounting time (s) = "+num2str(ctTime)
		SIMProtocol[2] = "\tTotal detector counts = "+num2str(totalCts)
		SIMProtocol[3] = "\tDetector countrate (1/s) = "+num2str(detCR)
		SIMProtocol[4] = "\tFraction of beam scattered coherently = "+num2str(fractScat)
		SIMProtocol[5] = "\tFraction of multiple coherent scattering = "+num2str(mScat)
		SIMProtocol[6] = ""
		SIMProtocol[7] = ""
		//set the global
		String/G root:myGlobals:Protocols:gProtoStr = "SIMProtocol"
	Endif
	
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")
	WAVE qvals =$(destStr + ":qval")
	WAVE inten=$(destStr + ":aveint")
	WAVE sig=$(destStr + ":sigave")
 	WAVE qbar = $(destStr + ":QBar")
  	WAVE sigmaq = $(destStr + ":SigmaQ")
 	WAVE fsubs = $(destStr + ":fSubS")

	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)
	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(qbar)))
		Abort "qbar DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(sigmaq)))
		Abort "sigmaq DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(fsubs)))
		Abort "fsubs DNExist Save_1DSimData()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist Save_1DSimData()"
	Endif

	//strings can be too long to print-- must trim to 255 chars
	Variable ii,num=8
	Make/O/T/N=(num) tempShortProto
	for(ii=0;ii<num;ii+=1)
		tempShortProto[ii] = (proto[ii])[0,240]
	endfor
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	NVAR monCt = root:Packages:NIST:SAS:gImon
	NVAR thick = root:Packages:NIST:SAS:gThick
	NVAR trans = root:Packages:NIST:SAS:gSamTrans			//for 1D, default value
	

	
	hdrStr1 = num2str(monCt)+"  "+num2str(rw[26])+"       "+num2str(rw[19])+"     "+num2str(rw[18])
	hdrStr1 += "     "+num2str(trans)+"     "+num2str(thick) + ave +"   "+num2str(step) + "\r\n"

	hdrStr2 = num2str(rw[16])+"  "+num2str(rw[17])+"  "+num2str(rw[23])+"    "+num2str(rw[24])+"    "
	hdrStr2 += num2str(rw[25])+"    "+num2str(rw[27])+"    "+num2str(rw[21])+"    "+"ORNL  " + "\r\n"
	
	//actually open the file here
	Open refNum as fullpath
	
	//write out the standard header information
	fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n","SIMULATED DATA",(date() +"  "+ time())
	fprintf refnum,"LABEL: %s\r\n","SIMULATED DATA"
	fprintf refnum,"MON CNT   LAMBDA   DET ANG   DET DIST   TRANS   THICK   AVE   STEP\r\n"
	fprintf refnum,hdrStr1
	fprintf refnum,"BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP \r\n"
	fprintf refnum,hdrStr2
//	fprintf refnum,headerFormat,rw[0],rw[26],rw[19],rw[18],rw[4],rw[5],ave,step

	//insert protocol information here
	//-1 list of sample files
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	fprintf refnum, "SAM: %s\r\n",tempShortProto[0]
	fprintf refnum, "BGD: %s\r\n",tempShortProto[1]
	fprintf refnum, "EMP: %s\r\n",tempShortProto[2]
	fprintf refnum, "DIV: %s\r\n",tempShortProto[3]
	fprintf refnum, "MASK: %s\r\n",tempShortProto[4]
	fprintf refnum, "ABS: %s\r\n",tempShortProto[5]
	fprintf refnum, "Average Choices: %s\r\n",tempShortProto[6]
	
	//write out the data columns
	fprintf refnum,"The 6 columns are | Q (1/A) | I(Q) (1/cm) | std. dev. I(Q) (1/cm) | sigmaQ | meanQ | ShadowFactor|\r\n"
	wfprintf refnum, formatStr, qvals,inten,sig,sigmaq,qbar,fsubs
	
	Close refnum
	
	SetDataFolder root:		//(redundant)
	
	//write confirmation of write operation to history area
	Print "Averaged File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z tempShortProto

	//clear the stuff that was created for case of saving files
	If(1)
		Killwaves/Z root:myGlobals:Protocols:SIMProtocol
		String/G root:myGlobals:Protocols:gProtoStr = ""
	Endif
	
	
	return(0)
	
End


/// called in SASCALC:ReCalculateInten()
Function Simulate_1D(funcStr,aveint,qval,sigave,sigmaq,qbar,fsubs)
	String funcStr
	WAVE aveint,qval,sigave,sigmaq,qbar,fsubs

	Variable r1,xCtr,yCtr,sdd,pixSize,wavelength
	String coefStr,abortStr,str	

	FUNCREF SANSModelAAO_MCproto func=$("fSmeared"+funcStr)			//a wrapper for the structure version
	FUNCREF SANSModelAAO_MCproto funcUnsmeared=$(funcStr)		//unsmeared
	coefStr = MC_getFunctionCoef(funcStr)
	
	if(!MC_CheckFunctionAndCoef(funcStr,coefStr))
		Abort "Function and coefficients do not match. You must plot the unsmeared function before simulation."
	endif
	
	Wave inten=$"root:Simulation:Simulation_i"		// this will exist and send the smeared calculation to the corect DF
	
	// the resolution-smeared intensity is calculated, including the incoherent background
	func($coefStr,inten,qval)

	NVAR imon = root:Packages:NIST:SAS:gImon
	NVAR ctTime = root:Packages:NIST:SAS:gCntTime
	NVAR thick = root:Packages:NIST:SAS:gThick
	NVAR trans = root:Packages:NIST:SAS:gSamTrans
	NVAR SimDetCts = root:Packages:NIST:SAS:g_1DTotCts			//summed counts (simulated)
	NVAR estDetCR = root:Packages:NIST:SAS:g_1DEstDetCR			// estimated detector count rate
	NVAR fracScat = root:Packages:NIST:SAS:g_1DFracScatt		// fraction of beam captured on detector
	NVAR estTrans = root:Packages:NIST:SAS:g_1DEstTrans		// estimated transmission of sample
	NVAR mScat = root:Packages:NIST:SAS:g_MultScattFraction
	
	WAVE rw=root:Packages:NIST:SAS:realsRead
	WAVE nCells=root:Packages:NIST:SAS:nCells				
					
	pixSize = rw[10]/10		// convert pix size in mm to cm
	sdd = rw[18]*100		//convert header of [m] to [cm]
	wavelength = rw[26]		// in 1/A
	
	imon = beamIntensity()*ctTime
	
	// calculate the scattering cross section simply to be able to estimate the transmission
	Variable sig_sas=0
	
	// remember that the random deviate is the coherent portion ONLY - the incoherent background is 
	// subtracted before the calculation.
	CalculateRandomDeviate(funcUnsmeared,$coefStr,wavelength,"root:Packages:NIST:SAS:ran_dev",sig_sas)
	
//				if(sig_sas > 100)
//					sprintf abortStr,"sig_sas = %g. Please check that the model coefficients have a zero background, or the low q is well-behaved.",sig_sas
//				endif

	// calculate the multiple scattering fraction for display (10/2009)
	Variable ii,nMax=10,tau
	mScat=0
	tau = thick*sig_sas
	// this sums the normalized scattering P', so the result is the fraction of multiply coherently scattered
	// neutrons out of those that were scattered
	for(ii=2;ii<nMax;ii+=1)
		mScat += tau^(ii)/factorial(ii)
//		print tau^(ii)/factorial(ii)
	endfor
	estTrans = exp(-1*thick*sig_sas)		//thickness and sigma both in units of cm
	mscat *= (estTrans)/(1-estTrans)

	if(mScat > 0.1)		//  /Z to supress error if this was a 1D calc with the 2D panel open
		ValDisplay/Z valdisp0_4 win=Sim_1D_Panel,labelBack=(65535,32768,32768)
	else
		ValDisplay/Z valdisp0_4 win=Sim_1D_Panel,labelBack=0
	endif


	Print "Sig_sas = ",sig_sas
	
	Duplicate/O qval prob_i,countsInAnnulus
	
	// not needed - nCells takes care of this when the error is correctly calculated
//				Duplicate/O qval circle_fraction,rval,nCells_expected
//				rval = sdd*tan(2*asin(qval*wavelength/4/pi))		//radial distance in cm
//				nCells_expected = 2*pi*rval/pixSize					//does this need to be an integer?
//				circle_fraction = nCells / nCells_expected
	
				
//				prob_i = trans*thick*nCells*(pixSize/sdd)^2*inten			//probability of a neutron in q-bin(i) that has nCells
	prob_i = trans*thick*(pixSize/sdd)^2*inten			//probability of a neutron in q-bin(i) 
	
	Variable P_on = sum(prob_i,-inf,inf)
	Print "P_on = ",P_on
	
//				fracScat = P_on
	fracScat = 1-estTrans
	
//				aveint = (Imon)*prob_i / circle_fraction / nCells_expected
	aveint = (Imon)*prob_i

	countsInAnnulus = aveint*nCells
	SimDetCts = sum(countsInAnnulus,-inf,inf)
	estDetCR = SimDetCts/ctTime
	
	
	NVAR doABS = root:Packages:NIST:SAS:g_1D_DoABS
	NVAR addNoise = root:Packages:NIST:SAS:g_1D_AddNoise
	
	// this is where the number of cells comes in - the calculation of the error bars
	// sigma[i] = SUM(sigma[ij]^2) / nCells^2
	// and since in the simulation, SUM(sigma[ij]^2) = nCells*sigma[ij]^2 = nCells*Inten
	// then...
	sigave = sqrt(aveint/nCells)		// corrected based on John's memo, from 8/9/99
	
	// add in random error in aveint based on the sigave
	if(addNoise)
		aveint += gnoise(sigave)
	endif

	// signature in the standard deviation, do this after the noise is added
	// start at 10 to be out of the beamstop (makes for nicer plotting)
	// end at 50 to leave the natural statistics at the end of the set (may have a total of 80+ points if no offset)
	sigave[10,50;10] = 10*sigave[p]

	// convert to absolute scale
	if(doABS)
		Variable kappa = thick*(pixSize/sdd)^2*trans*iMon
		aveint /= kappa
		sigave /= kappa
	endif
				
				
	return(0)
End

/// for testing only
Function testProbability(sas,thick)
	Variable sas,thick
	
	Variable tau,trans,p2p,p3p,p4p
	
	tau = sas*thick
	trans = exp(-tau)
	
	Print "tau = ",tau
	Print "trans = ",trans
	
	p2p = tau^2/factorial(2)*trans/(1-trans)
	p3p = tau^3/factorial(3)*trans/(1-trans)
	p4p = tau^4/factorial(4)*trans/(1-trans)
	
	Print "double scattering = ",p2p
	Print "triple scattering = ",p3p
	Print "quadruple scattering = ",p4p
	
	Variable ii,nMax=10,mScat=0
	for(ii=2;ii<nMax;ii+=1)
		mScat += tau^(ii)/factorial(ii)
//		print tau^(ii)/factorial(ii)
	endfor
	mscat *= (Trans)/(1-Trans)

	Print "Total fraction of multiple scattering = ",mScat

	return(mScat)
End