#pragma rtGlobals=1		// Use modern global access method.

// These procedures and calculations duplicate the work of K. Krycka and WC Chen
// in calculating the state of the He cell and subsequent correction of scattering data
//
//
// SRK May 2011
//
//
//
// there is a particular sequence of things that need to be calculated
// lots of constants, and lots of confusing, similar notation.
//
//
// for this implementation, I'll follow what is described in the "PASANS"
// writeup by K. Krycka, and I'll try to follow the equations as numbered there
// and keep the notation as close as possible.
//
// error propagation was written up elsewhere, and will be implemented as well
// - each of the calcualtions based on transmissions will need to have errors
// brought in, and carried through the calculations. Some will be simple, some
// will probably be easiest with expansions.
//



//
// (/S) FindFileFromRunNumber(num) gets fname
// [4] is trans, [41] is trans error, [40] is Twhole
//



Constant kTe = 0.87		// transmission of the unfilled cell



// calculation of mu
//
// Known: Te ===> Global constant currently, may change later
//
// Input: T He (unpolarized), using unpolarized beam
//			T He cell out, using unpolarized beam
//			T background, using unpolarized beam
//
// Equation 7
//
Function opacity_mu(T_he,T_out,T_bk)
	Variable T_he,T_out,T_bk

	Variable mu

// using the global constant!

	mu = (1/kTe)*(T_he - T_bk)/(T_out - t_bk)
	mu = -1*ln(mu)

	return(mu)
End



Proc calc_muP(mu, runT_he, runT_out, runT_bk)
	Variable mu=3.108, runT_he, runT_out, runT_bk

	Variable muP,T_he, T_out, T_bk
	String fname
	
	fname = FindFileFromRunNumber(runT_he)
	T_he = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)	//use CR, not trans (since no real empty condition)
	
	fname = FindFileFromRunNumber(runT_out)
	T_out = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)
	
	fname = FindFileFromRunNumber(runT_bk)
	T_bk = getDetCount(fname)/getMonitorCount(fname)/getCountTime(fname)
	
	muP = Cell_muP(mu, T_he, T_out, T_bk)
	
	Print "Count rates T_he, T_out, T_bk = ",T_he, T_out, T_bk
	Print "Mu*P = ",muP
	Print "Time = ",getFileCreationDate(fname)
	
end


// ???? is this correct ????
// -- check the form of the equation. It's not the same in some documents
//
// calculation of mu.P(t) from exerimental measurements
//
// Known: Te and mu
// Input: T He cell (polarized cell), using unpolarized beam
//			T He cell OUT, using unpolarized beam
//			T background, using unpolarized beam
//
// Equation 9, modified by multiplying the result by mu + moving tmp inside the acosh() 
//
Function Cell_muP(mu, T_he, T_out, T_bk)
	Variable mu, T_he, T_out, T_bk

// using the global constant!

	Variable muP,tmp
	
	tmp = kTe*exp(-mu)		//note mu has been moved
	muP = acosh( (T_he - T_bk)/(T_out - T_bk)  * (1/tmp)) 

	return(muP)
End


//
// calculation of mu.P(t) from Gamma and t=0 value
//
// Known: Gamma, muP_t0, t0, tn
//
// times are in hours, Gamma [=] hours
// tn is later than t0, so t0-tn is negative
//
// Equation 11
//
Function muP_at_t(Gam_He, muP_t0, t0, tn)
	Variable Gam_He, muP_t0, t0, tn

	Variable muP
	
	muP = muP_t0 * exp( (t0 - tn)/Gam_He )
	
	return(muP)
End

// Calculation of Pcell(t)
// note that this is a time dependent quantity
//
// Known: muP(t)
// Input: nothing additional
//
// Equation 10
//
Function PCell(muP)
	Variable muP
	
	Variable PCell
	PCell = tanh(muP)
	
	return(PCell)
End


// calculation of Pf (flipper)
//
// Known: nothing
// Input: Tuu, Tdu, and Tdd, Tud
//			(but exactly what measurement conditions?)
//			( are these T's also calculated quantities???? -- Equation(s) 12--)
//
// Equation 14
//
// (implementation of equation 13 is more complicated, and not implemented yet)
//
Function Flipper_Pf(Tuu, Tdu, Tdd, Tud)
	Variable Tuu, Tdu, Tdd, Tud
	
	Variable pf
	
	pf = (Tdd - Tdu)/(Tuu - Tud)
	
	return(pf)
End



// (this is only one of 4 methods, simply the first one listed)
// ???? this equation doesn't match up with the equation in the SS handout
//
// calculation of P'sm (supermirror)
//
// Known: Pcell(t1), Pcell(t2) (some implementations need Pf )
// Input: Tuu(t1), Tud(t2)
//
// Equation 15??
//
Function SupMir_Psm(Pcell1,Pcell2,Tuu,Tud)
	Variable Pcell1,Pcell2,Tuu,Tud
	
	Variable Psm
	
	Psm = (Tuu - Tud)/(PCell1 + PCell2)
	
	return(Psm)
End



//
// calculation of (4) cross sections, corrected for polariztion inefficiencies
//
// Known: Te, mu, Gamma, P(t), Pf, P'sm
// Input: (4) measured Intensities + Sbk
//			Tsam, He cell out
//			T (no sample), He cell out
//
// ?? there is a note that the S's and T's need to be acquired and polarization corrected
// separately in each condition, including the condition of background. I'm confused.
// isn't this the polarization correction right here? All 4 at once as a matrix...
//
//
// this should be a port of the c-code, not from scratch
//