#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////////
//
// model function that calculates the scattering from 
// lamellar surfactant structures. contrast is two-phase,
// from the solvent and uniform bilayer. The system is
// considered to be DILUTE - Interference (S(Q)) effects
// are NOT taken into account. ONLY the form factor is calculated
//
//
// REFERENCE:	Nallet, Laversanne, and Roux, J. Phys. II France, 3, (1993) 487-502.
//		also in J. Phys. Chem. B, 105, (2001) 11081-11088.
//
// 16 JULY 2003 SRK
//
////////////////////////////////////////////////////

//this macro sets up all the necessary parameters and waves that are
//needed to calculate the model function.
//
Proc Plot_LamellarFF(num,qmin,qmax)
	Variable num=128, qmin=.001, qmax=.5
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^1) for model: " 
	Prompt qmax "Enter maximum q-value (A^1) for model: "
//
	Make/O/D/n=(num) xwave_LamellarFF, ywave_LamellarFF
	xwave_LamellarFF =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_LamellarFF = {1,50,0.15,6e-6,0}			//CH#2
	make/o/t parameters_LamellarFF = {"Scale","Bilayer Thick (delta) (A)","polydisp of thickness","contrast (A^-2)","Incoherent Bgd (cm-1)"}	//CH#3
	Edit parameters_LamellarFF, coef_LamellarFF
	ModifyTable width(parameters_LamellarFF)=160
	ywave_LamellarFF  := LamellarFF(coef_LamellarFF, xwave_LamellarFF)
	Display ywave_LamellarFF vs xwave_LamellarFF
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1
	Label bottom "q (A\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
//
End

//
//this macro sets up all the necessary parameters and waves that are
//needed to calculate the  smeared model function.
//
//no input parameters are necessary, it MUST use the experimental q-values
// from the experimental data read in from an AVE/QSIG data file
////////////////////////////////////////////////////
Proc PlotSmeared_LamellarFF()								//Lamellar
	
	// if no gQvals wave, data must not have been loaded => abort
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_LamellarFF = {1,50,0.15,6e-6,0}		//CH#4
	make/o/t smear_parameters_LamellarFF = {"Scale","Bilayer Thick (delta) (A)","polydisp of thickness","contrast (A^-2)","Incoherent Bgd (cm-1)"}
	Edit smear_parameters_LamellarFF,smear_coef_LamellarFF					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_LamellarFF,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_LamellarFF							//

	smeared_LamellarFF := LamellarFF_Smeared(smear_coef_LamellarFF,$gQvals)		// SMEARED function name
	Display smeared_LamellarFF vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro 

//CH#1
// you should write your function to calculate the intensity
// for a single q-value (that's the input parameter x)
// based on the wave (array) of parameters that you send it (w)
//
Function LamellarFF(w,x) : FitFunc
	Wave w
	Variable x
//	 Input (fitting) variables are:
//[0]Scale
//[1]Bilay Thick (delta)
//[2] polydispersity of thickness
//[3]contrast
//[4]Incoherent Bgd (cm-1)
	
//	give them nice names
	Variable scale,dd,del,sig,contr,NN,Cp,bkg
	scale = w[0]
	del = w[1]
	sig = w[2]*del
	contr = w[3]
	bkg = w[4]
	
//	local variables
	Variable inten, qval,Pq,Sq,ii,alpha,temp,t1,t2,t3,dQ
	
	//	x is the q-value for the calculation
	qval = x
	
	Pq = 2*contr^2/qval/qval*(1-cos(qval*del)*exp(-0.5*qval^2*sig^2))
	
	inten = 2*Pi*scale*Pq/Qval^2		//this is now dimensionless...
	
	inten /= del			//normalize by the thickness (in A)
	
	inten *= 1e8		// 1/A to 1/cm
	
	Return (inten+bkg)
End

//the smeared model calculation
Function LamellarFF_Smeared(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(LamellarFF,$sq,$qb,$sh,$gQ,w,x)	

	return(ans)
End

