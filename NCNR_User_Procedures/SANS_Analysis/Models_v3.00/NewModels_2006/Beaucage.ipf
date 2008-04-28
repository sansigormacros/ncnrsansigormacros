#pragma rtGlobals=1		// Use modern global access method.

/////////////////////////////////////////////////////
//
// Plot's Greg Beaucage's Rg-power Law "model" of scattering
// somewhat useful for identifying length scales, but short on
// physical inerpretation of the real structure of the sample.
//
// up to 4 "levels" can be calculated
// best to start with single level, and fit a small range of
// the data, and add more levels as needed
//
// see the help file for the original references
//
Proc PlotBeau_One(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_b1,ywave_b1
	xwave_b1 = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b1 = {1,3,21,6e-4,2,0}
	make/o/t parameters_b1 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","bkg (cm-1 sr-1)"}
	Edit parameters_b1,coef_b1
	ywave_b1 := OneLevel(coef_b1,xwave_b1)
	Display ywave_b1 vs xwave_b1
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotBeau_Two(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_b2,ywave_b2
	xwave_b2 = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b2 = {1,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b2 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","bkg (cm-1 sr-1)"}
	Edit parameters_b2,coef_b2
	ywave_b2 := TwoLevel(coef_b2,xwave_b2)
	Display ywave_b2 vs xwave_b2
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotBeau_Three(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_b3,ywave_b3
	xwave_b3 = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b3 = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b3 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1)","Pow3","bkg (cm-1)"}
	Edit parameters_b3,coef_b3
	ywave_b3 := ThreeLevel(coef_b3,xwave_b3)
	Display ywave_b3 vs xwave_b3
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotBeau_Four(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/o/d/n=(num) xwave_b4,ywave_b4
	xwave_b4 = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/o/d coef_b4 = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t parameters_b4 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1)","Pow4","bkg (cm-1)"}
	Edit parameters_b4,coef_b4
	ywave_b4 := FourLevel(coef_b4,xwave_b4)
	Display ywave_b4 vs xwave_b4
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

/////////// macros for smeared model calculations

Proc PlotSmearedBeau_OneLevel()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b1 ={1,3,21,6e-4,2,0}					
	make/o/t smear_parameters_b1 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b1,smear_coef_b1					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_b1,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b1							

	smeared_b1 := SmearedOneLevel(smear_coef_b1,$gQvals)		
	Display smeared_b1 vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedBeau_TwoLevel()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b2 = {1,400,200,5e-6,4,3,21,6e-4,2,0}				
	make/o/t smear_parameters_b2 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_b2,smear_coef_b2					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_b2,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b2							

	smeared_b2 := SmearedTwoLevel(smear_coef_b2,$gQvals)		
	Display smeared_b2 vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedBeau_ThreeLevel()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b3 = {1,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	make/o/t smear_parameters_b3 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1)","Pow3","bkg (cm-1)"}
	Edit smear_parameters_b3,smear_coef_b3					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_b3,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b3							

	smeared_b3 := SmearedThreeLevel(smear_coef_b3,$gQvals)		
	Display smeared_b3 vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

Proc PlotSmearedBeau_FourLevel()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	If(ResolutionWavesMissing())		//part of GaussUtils
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_b4 = {1,40000,2000,1e-8,4,4000,600,2e-7,4,400,200,5e-6,4,3,21,6e-4,2,0}
	Make/o/t smear_parameters_b4 = {"scale","G1 (cm-1 sr-1)","Rg1  (A)","B1 (cm-1 sr-1)","Pow1","G2 (cm-1 sr-1)","Rg2  (A)","B2 (cm-1 sr-1)","Pow2","G3 (cm-1 sr-1)","Rg3  (A)","B3 (cm-1 sr-1)","Pow3","G4 (cm-1 sr-1)","Rg4  (A)","B4 (cm-1 sr-1)","Pow4","bkg (cm-1)"}
	Edit smear_parameters_b4,smear_coef_b4					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_b4,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_b4							

	smeared_b4 := SmearedFourLevel(smear_coef_b4,$gQvals)		
	Display smeared_b4 vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

//////////Function definitions

Function OneLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans,erf1,prec=1e-15
	Variable G1,Rg1,B1,Pow1,bkg,scale
	
	scale = w[0]
	G1 = w[1]
	Rg1 = w[2]
	B1 = w[3]
	Pow1 = w[4]
	bkg = w[5]
	
	erf1 = erf( (x*Rg1/sqrt(6)) ,prec)
	
	ans = G1*exp(-x*x*Rg1*Rg1/3)
	ans += B1*(erf1^3/x)^Pow1
	ans *= scale
	ans += bkg
	
	Return (ans)
End

Function TwoLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans,G1,Rg1,B1,G2,Rg2,B2,Pow1,Pow2,bkg
	Variable erf1,erf2,prec=1e-15,scale
	
	//Rsub = Rs
	scale = w[0]
	G1 = w[1]	//equivalent to I(0)
	Rg1 = w[2]
	B1 = w[3]
	Pow1 = w[4]
	G2 = w[5]
	Rg2 = w[6]
	B2 = w[7]
	Pow2 = w[8]
	bkg = w[9]
	
	erf1 = erf( (x*Rg1/sqrt(6)) ,prec)
	erf2 = erf( (x*Rg2/sqrt(6)) ,prec)
	//Print erf1
	
	ans = G1*exp(-x*x*Rg1*Rg1/3)
	ans += B1*exp(-x*x*Rg2*Rg2/3)*(erf1^3/x)^Pow1
	ans += G2*exp(-x*x*Rg2*Rg2/3)
	ans += B2*(erf2^3/x)^Pow2
	ans *= scale
	ans += bkg
	
	Return(ans)
End


Function ThreeLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans,G1,Rg1,B1,G2,Rg2,B2,Pow1,Pow2,bkg
	Variable G3,Rg3,B3,Pow3,erf3
	Variable erf1,erf2,prec=1e-15,scale
	
	//Rsub = Rs
	scale = w[0]
	G1 = w[1]	//equivalent to I(0)
	Rg1 = w[2]
	B1 = w[3]
	Pow1 = w[4]
	G2 = w[5]
	Rg2 = w[6]
	B2 = w[7]
	Pow2 = w[8]
	G3 = w[9]
	Rg3 = w[10]
	B3 = w[11]
	Pow3 = w[12]
	bkg = w[13]
	
	erf1 = erf( (x*Rg1/sqrt(6)) ,prec)
	erf2 = erf( (x*Rg2/sqrt(6)) ,prec)
	erf3 = erf( (x*Rg3/sqrt(6)) ,prec)
	//Print erf1
	
	ans = G1*exp(-x*x*Rg1*Rg1/3) + B1*exp(-x*x*Rg2*Rg2/3)*(erf1^3/x)^Pow1
	ans += G2*exp(-x*x*Rg2*Rg2/3) + B2*exp(-x*x*Rg3*Rg3/3)*(erf2^3/x)^Pow2
	ans += G3*exp(-x*x*Rg3*Rg3/3) + B3*(erf3^3/x)^Pow3
	ans *= scale
	ans += bkg
	
	Return(ans)
End

Function FourLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans,G1,Rg1,B1,G2,Rg2,B2,Pow1,Pow2,bkg
	Variable G3,Rg3,B3,Pow3,erf3
	Variable G4,Rg4,B4,Pow4,erf4
	Variable erf1,erf2,prec=1e-15,scale
	
	//Rsub = Rs
	scale = w[0]
	G1 = w[1]	//equivalent to I(0)
	Rg1 = w[2]
	B1 = w[3]
	Pow1 = w[4]
	G2 = w[5]
	Rg2 = w[6]
	B2 = w[7]
	Pow2 = w[8]
	G3 = w[9]
	Rg3 = w[10]
	B3 = w[11]
	Pow3 = w[12]
	G4 = w[13]
	Rg4 = w[14]
	B4 = w[15]
	Pow4 = w[16]
	bkg = w[17]
	
	erf1 = erf( (x*Rg1/sqrt(6)) ,prec)
	erf2 = erf( (x*Rg2/sqrt(6)) ,prec)
	erf3 = erf( (x*Rg3/sqrt(6)) ,prec)
	erf4 = erf( (x*Rg4/sqrt(6)) ,prec)
	
	ans = G1*exp(-x*x*Rg1*Rg1/3) + B1*exp(-x*x*Rg2*Rg2/3)*(erf1^3/x)^Pow1
	ans += G2*exp(-x*x*Rg2*Rg2/3) + B2*exp(-x*x*Rg3*Rg3/3)*(erf2^3/x)^Pow2
	ans += G3*exp(-x*x*Rg3*Rg3/3) + B3*exp(-x*x*Rg4*Rg4/3)*(erf3^3/x)^Pow3
	ans += G4*exp(-x*x*Rg4*Rg4/3) + B4*(erf4^3/x)^Pow4
	ans *= scale
	ans += bkg
	
	Return(ans)
End

Function SmearedOneLevel(w,x) :FitFunc
	Wave w
	Variable x
	
//	Variable timer=StartMSTimer
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(OneLevel,$sq,$qb,$sh,$gQ,w,x)	

//	Print "HS elapsed time(s) = ",StopMSTimer(timer)*1e-6
	return(ans)
End

Function SmearedTwoLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(TwoLevel,$sq,$qb,$sh,$gQ,w,x)	

	return(ans)
End

Function SmearedThreeLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(ThreeLevel,$sq,$qb,$sh,$gQ,w,x)	

	return(ans)
End

Function SmearedFourLevel(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	ans = Smear_Model_20(FourLevel,$sq,$qb,$sh,$gQ,w,x)	

	return(ans)
End
