#pragma rtGlobals=1		// Use modern global access method.
#pragma version=3.00
#pragma IgorVersion=6.0

//Functions for doing USANS Slit smearing by method of weight matrix
//Routines originally from J Barker fortran code
//Translated to IGOR by M-H Kim
//Updated to use IGOR features and integrated into SANS Macros by A J Jackson
//
// AJJ
// July 26 2007 - Modified functions to work with new SANS Analysis Macros
//     - pass basestr to functions to determine wave names and avoid globals
//     - pass dQv to functions to  avoid globals
//     - pass N to CalcR to avoid globals

//

// called only by the main file loader
//
Function USANS_CalcWeights(basestr, dQv)
	String basestr
	Variable dQv

	Variable/G USANS_N=numpnts($(basestr+"_q"))
	Variable/G USANS_dQv = dQv
	String/G root:Packages:NIST:USANS_basestr = basestr		//this is the "current data" for slope and weights

	Make/D/O/N=(USANS_N,USANS_N) $(basestr+"_res")
	Make/D/O/N=(USANS_N,USANS_N) W1mat
	Make/D/O/N=(USANS_N,USANS_N) W2mat
	Make/D/O/N=(USANS_N,USANS_N) Rmat
	Wave weights = $(basestr+"_res")

	//Variable/G USANS_m = EnterSlope(baseStr)
	Variable/G USANS_m = -4
	Variable/G USANS_slope_numpnts = 15
	String/G trimStr=""			//null string if NOT using cursors, "t" if yes (and re-calculating)
	
	Print "---- Calculating Weighting Matrix for USANS Data ----"
	
	EnterSlope(basestr)
	
	//Deal with broken Pauseforuser
	SetDataFolder $("root:"+basestr)
	
	print USANS_m

	if (USANS_m == 999)
		KillWaves/Z  $(basestr+"_res"),W1Mat,W2mat,Rmat
		return(1)
	endif
	
	Variable tref = startMSTimer
	print "Calculating W1..."
	W1mat = (p <= q ) && (q <= USANS_N-2) ? CalcW1(p,q)  : 0
	print "Calculating W2..."
	W2mat = (p+1 <= q ) && (q <= USANS_N-1) ?  CalcW2(p,q) : 0
	print "Calculating Remainders..."
	Rmat = (q == USANS_N-1) ? CalcR(p) : 0
//	print "Summing weights..."
	weights = W1mat + W2mat + Rmat
	print "Done"
	Variable ms = stopMSTimer(tref)
	print "Time elapsed = ", ms/1e6, "s"
	
	// put the point range of the matrix in a wave note (this is the full range)
	String nStr=""
	sprintf nStr,"P1=%d;P2=%d;",0,USANS_N-1
	Note weights ,nStr
	
	// save a copy of the untainted matrix to return to...
	Duplicate/O weights, weights_save
	
	return(0)
End

// re-calculate the weighting matrix, maybe easier to do in a separate function
//
// supposedly I'm in the data folder, not root:, double check to make sure
//
Function USANS_RE_CalcWeights(baseStr,pt1,pt2)
	String baseStr
	Variable pt1,pt2

	SetDataFolder $("root:"+baseStr)
	NVAR USANS_dQv = USANS_dQv
	SVAR trimStr = trimStr
	trimStr="t"		//yes, we're re-calculating, using trimmed data sets
	
	Variable matN
	matN=pt2-pt1+1		//new size of matrix

	Make/D/O/N=(matN,matN) $(basestr+"_res"+trimStr)		//this is a temporary matrix
	Make/D/O/N=(matN,matN) W1mat
	Make/D/O/N=(matN,matN) W2mat
	Make/D/O/N=(matN,matN) Rmat
	Wave tmpWeights = $(basestr+"_res"+trimStr)
	Wave fullWeights = $(basestr+"_res")

	// make a trimmed set of QIS waves to match the size selected by the cursors
	// == "t" added to the suffix
	WAVE qval = $(baseStr+"_q")
	WAVE ival = $(baseStr+"_i")
	WAVE sval = $(baseStr+"_s")
	Duplicate/O/R=[pt1,pt2] qval $(baseStr+"_qt")
	Duplicate/O/R=[pt1,pt2] ival $(baseStr+"_it")
	Duplicate/O/R=[pt1,pt2] sval $(baseStr+"_st")
	WAVE qt = $(baseStr+"_qt")			//these are trimmed based on the cursor points
	WAVE it = $(baseStr+"_it")
	WAVE st = $(baseStr+"_st")
	
	//Variable/G USANS_m = EnterSlope(baseStr)
	Variable/G USANS_m = -4
	Variable/G USANS_slope_numpnts = 15
	// must reset the global for baseStr to this set, otherwise it will look for the last set loaded
	String/G root:Packages:NIST:USANS_basestr = basestr		//this is the "current data" for slope and weights

	
	Print "---- Calculating Weighting Matrix for USANS Data ----"
	
	EnterSlope(basestr)
	
	//Deal with broken Pauseforuser
	SetDataFolder $("root:"+basestr)
	
	print USANS_m

	if (USANS_m == 999)
		KillWaves/Z  $(basestr+"_res"),W1Mat,W2mat,Rmat
		return(1)
	endif
	
	Variable tref = startMSTimer
	print "Calculating W1..."
	W1mat = (p <= q ) && (q <= matN-2) ? CalcW1(p,q)  : 0
	print "Calculating W2..."
	W2mat = (p+1 <= q ) && (q <= matN-1) ?  CalcW2(p,q) : 0
	print "Calculating Remainders..."
	Rmat = (q == matN-1) ? CalcR(p) : 0
//	print "Summing weights..."
	tmpWeights = W1mat + W2mat + Rmat
	print "Done"
	Variable ms = stopMSTimer(tref)
	print "Time elapsed = ", ms/1e6, "s"
	
	//  - put the smaller matrix into the larger one (padded w/zero)
	// get the smaller triangular weights into the proper place in the full matrix
	//
	// this is necessary since the original dependency (as plotted) was set up using the 
	// full data set in the STRUCT
	fullWeights = 0
	fullWeights[pt1,pt2][pt1,pt2] = tmpWeights[p-pt1][q-pt1]
	
	
	// put the point range of the matrix in a wave note
	String nStr=""
	sprintf nStr,"P1=%d;P2=%d;",pt1,pt2
	Note/K fullWeights ,nStr
	
	return(0)
End

// trimStr = "" if the full (original) data set is to be used, == "t" if the set is trimmed to cursors
Function EnterSlope(baseStr)
	String baseStr
	
//	NVAR USANS_m,USANS_slope_numpnts
	NVAR USANS_m = $("root:"+baseStr+":USANS_m")
	NVAR USANS_slope_numpnts = $("root:"+baseStr+":USANS_slope_numpnts")
	SVAR trimStr = $("root:"+baseStr+":trimStr")
	
//	Variable slope=-4

//	Prompt slope "Enter a slope for the file \""+ baseStr + "\""
//	DoPrompt "Enter Slope", slope
//		If (V_Flag)
//			return (999)			//return a bogus slope if the user canceled
//		Endif
//	print "slope=", slope
//	return slope

	NewPanel /W=(600,300,1000,700)/N=USANS_Slope as "USANS Slope Extrapolation"
	SetDrawLayer UserBack
	Button button_OK,pos={270,360},size={100,20},title="Accept Slope",font="Geneva"
	Button button_OK,proc=USANS_Slope_ButtonProc
	Button button_SlopeCalc,pos={270,310},size={100,20},title="Calculate",font="Geneva"
	Button button_SlopeCalc,proc=USANS_Slope_ButtonProc
	SetVariable setvar_numpnts, pos={20,310}, size={130,19}, title="# Points",fSize=13
	SetVariable setvar_numpnts, value= USANS_slope_numpnts 
	SetVariable setvar_Slope,pos={160,310},size={90,19},title="Slope",fSize=13
	SetVariable setvar_Slope,limits={-inf,inf,0},value= USANS_m
	SetVariable setvar_slope, proc=USANS_ManualSlope
	
	Display/W=(9,6,402,305)/HOST=USANS_Slope $(basestr+"_i"+trimStr) vs $(basestr+"_q"+trimStr)
	RenameWindow #,SlopePlot
	ErrorBars/W=USANS_Slope#SlopePlot $(basestr+"_i"+trimStr), Y wave=($(basestr+"_s"+trimStr),$(basestr+"_s"+trimStr))
	ModifyGraph log=1
	ModifyGraph mode=3,msize=3,marker=1,rgb=(0,0,0)
//	legend
	SetActiveSubwindow ##
	
	//Print TraceNameList("USANS_Slope#SlopePlot",";",1)
	
	//USANS_CalculateSlope(basestr,USANS_slope_numpnts)
	
	PauseForUser  USANS_Slope	
	
	
//	return slope
	
End

Function USANS_CalculateSlope(basestr, nend)
	String basestr
	Variable nend
	
//	NVAR USANS_m
	NVAR USANS_m = $("root:"+baseStr+":USANS_m")
	SVAR trimStr = $("root:"+baseStr+":trimStr")
	
	Wave iw = $(basestr+"_i"+trimStr)
	Wave qw = $(basestr+"_q"+trimStr)
	Wave sw = $(basestr+"_s"+trimStr)

	Variable num_extr=25
	// Make extra waves for extrapolation 
	// Taken from DSM_SetExtrWaves
		
	Make/O/D/N=(num_extr) extr_hqq,extr_hqi
	extr_hqi=1		//default values

	//set the q-range
	Variable qmax,num

	num=numpnts(qw)
	qmax=6*qw[num-1]
	
	// num-1-nend puts the extrapolation over the data set, as well as extending it
	extr_hqq = qw[num-1-nend] + x * (qmax-qw[num-1-nend])/num_extr
		
	
	// Modifed from DSM_DoExtraploate in LakeDesmearing_JB.ipf 
	// which is part of the USANS Reduction macros
	
		
	//	Wave extr_lqi=extr_lqi
	//	Wave extr_lqq=extr_lqq
	//	Wave extr_hqi=extr_hqi
	//	Wave extr_hqq=extr_hqq
		Variable/G V_FitMaxIters=300
		Variable/G V_fitOptions=4		//suppress the iteration window
		Variable retval
		num=numpnts(iw)
	
		Make/O/D P_coef={0,1,-4}			//input
		Make/O/T Constr={"K2<0","K2 > -8"}
		//(set background to zero and hold fixed)
		// initial guess 
		P_coef[1] = iw[num-1]/qw[num-1]^P_coef[2]
		
		CurveFit/H="100" Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /C=constr
		extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]
	
		AppendToGraph/W=USANS_Slope#SlopePlot extr_hqi vs extr_hqq
		ModifyGraph/W=USANS_Slope#SlopePlot lsize(extr_hqi)=2
	
		Printf "Smeared Power law exponent = %g\r",P_coef[2]
		Printf "**** For Desmearing, use a Power law exponent of %5.1f\r",P_coef[2]-1
	
		retVal = P_coef[2]-1			
		return(retVal)
		
End

// adjust the slope manually on the graph (not fitted!!) just for visualization
//
// can be turned off by removing the action proc in the setVariable
//
Function USANS_ManualSlope(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	
	String varStr		
	String varName
		
	SVAR baseStr = root:Packages:NIST:USANS_basestr
	NVAR nFit = $("root:"+baseStr+":USANS_slope_numpnts")
	NVAR USANS_m = $("root:"+baseStr+":USANS_m")
	WAVE/Z extr_hqq = $("root:"+baseStr+":extr_hqq")
	WAVE/Z extr_hqi = $("root:"+baseStr+":extr_hqi")
	SVAR trimStr = $("root:"+baseStr+":trimStr")
	
	if(waveExists(extr_hqq)==0 || waveExists(extr_hqi)==0)
		return(0)		// encourage the user to try to fit first...
	endif
	
	Wave iw = $("root:"+basestr+":"+basestr+"_i"+trimStr)
	Wave qw = $("root:"+basestr+":"+basestr+"_q"+trimStr)

	Variable matchPt,num=numpnts(iw),correctedSlope
	correctedSlope = USANS_m + 1
	
	matchPt = iw[num-1-nFit]/(qw[num-1-nFit]^correctedSlope)
	
	extr_hqi=matchPt*extr_hqq^correctedSlope
	
	return(0)
End

Function USANS_Slope_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR basestr =  root:Packages:NIST:USANS_basestr
	
	NVAR USANS_m = $("root:"+baseStr+":USANS_m")
	NVAR USANS_slope_numpnts = $("root:"+baseStr+":USANS_slope_numpnts")
	
	strswitch (ctrlName)
		case "button_OK":
			ControlUpdate/W=USANS_Slope setvar_Slope
			DoWindow/K USANS_Slope
			break
		case "button_SlopeCalc":
			USANS_m = USANS_CalculateSlope(basestr, USANS_slope_numpnts)
			ControlUpdate/W=USANS_Slope setvar_Slope
			break
	endswitch
	 

End

Function CalcW1(i,j)
	Variable i,j
	
	SVAR USANS_basestr=root:Packages:NIST:USANS_basestr 
	SVAR trimStr = $("root:"+USANS_baseStr+":trimStr")
	SetDataFolder $("root:"+USANS_basestr)

	
	
	NVAR dQv = USANS_dQv
	
	Variable UU,UL,dqj,rU,rL,wU,wL,dqw
	Wave Qval = $(USANS_basestr+"_q"+trimStr)
	
	UU =sqrt(Qval[j+1]^2-Qval[i]^2)
	UL = sqrt(Qval[j]^2-Qval[i]^2)
	dqw = Qval[j+1]-Qval[j]
	rU = sqrt(UU^2+Qval[i]^2)
	rL = sqrt(UL^2+Qval[i]^2)
	
	wU = (1.0/dQv)*(Qval[j+1]*UU/dqw - 0.5*UU*rU/dqw - 0.5*Qval[i]^2*ln(UU+rU)/dqw )
	wL = (1.0/dQv)*(Qval[j+1]*UL/dqw - 0.5*UL*rL/dqw - 0.5*Qval[i]^2*ln(UL+rL)/dqw )
	
	Return wU-wL

End

Function CalcW2(i,j)
	Variable i,j
	
	SVAR USANS_basestr=root:Packages:NIST:USANS_basestr 
	SVAR trimStr = $("root:"+USANS_baseStr+":trimStr")
	SetDataFolder $("root:"+USANS_basestr)



	NVAR dQv = USANS_dQv
	
	variable UU,UL,dqw,rU,rL,wU,wL
	
	Wave Qval = $(USANS_basestr+"_q"+trimStr)

	UU = sqrt(Qval[j]^2-Qval[i]^2)  		
	UL = sqrt(Qval[j-1]^2-Qval[i]^2) 		
	dqw = Qval[j]-Qval[j-1]  		
	rU = sqrt(UU^2+Qval[i]^2)
	rL = sqrt(UL^2+Qval[i]^2)
	wU = (1.0/dQv)*( -Qval[j-1]*UU/dqw + 0.5*UU*rU/dqw + 0.5*Qval[i]^2*ln(UU+rU)/dqw )
	wL = (1.0/dQv)*( -Qval[j-1]*UL/dqw + 0.5*UL*rL/dqw + 0.5*Qval[i]^2*ln(UL+rL)/dqw )

	Return wU-wL

End

Function CalcR(i)
	Variable i

	SVAR USANS_basestr=root:Packages:NIST:USANS_basestr 
	SVAR trimStr = $("root:"+USANS_baseStr+":trimStr")
	SetDataFolder $("root:"+USANS_basestr)


	NVAR m = USANS_m
	NVAR N = USANS_N
	NVAR dQv = USANS_dQv
	
	Variable retval
	Wave Qval = $(USANS_basestr+"_q"+trimStr)
	Wave Ival = $(USANS_basestr+"_i"+trimStr)
	Variable/G USANS_intQpt = Qval[i]
	
	Variable lower = sqrt(qval[N-1]^2-qval[i]^2)
	Variable upper = dQv

	if (i == N)
		lower = 0
	endif 
	
	retval = Integrate1D(Remainder,lower,upper)
	
	retval *= 1/dQv
	
	Return retval

End

Function Remainder(i)
	
	Variable i
	
	SVAR USANS_basestr=root:Packages:NIST:USANS_basestr 
	SVAR trimStr = $("root:"+USANS_baseStr+":trimStr")
	SetDataFolder $("root:"+USANS_basestr)

	NVAR m = USANS_m
	NVAR qi = USANS_intQpt
	NVAR N = USANS_N
	WAVE Qval = $(USANS_basestr+"_q"+trimStr)	
	Variable retVal
	
	retVal=Qval[N-1]^(-m)*(i^2+qi^2)^(m/2)

	return retval

End
