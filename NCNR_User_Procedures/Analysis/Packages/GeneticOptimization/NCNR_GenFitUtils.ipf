#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// genetic optimization, uses XOP supplied by Andy Nelson, ANSTO
// http://www.igorexchange.com/project/gencurvefit



// TO USE GENETIC OPTIMIZATION
//	Variable/G root:Packages:NIST:gUseGenCurveFit = 0			//set to 1 to use genetic optimization
// -- this flag is set by a menu item SANS Models->Packages->Enable Genetic Optimization
//
// ** it is currently only available for single fits - not for global fits (even the simple ones)
// incorporating into WM's global fit would be u-g-l-y
//
//
//  to complete the addition of genetic curve fitting:
//
// X add a check to make sure that the XOP is installed before the switch is set (force 0 if not present)
// X add a global variable as a switch
// X parse the limits. All must be filled in. If not, fit aborts and asks for user input to fill them in. Limits
//   on fixed parameters are +/- 1% of the value. Has no effect on fit (duh), but filled in for completeness.
// X create a mask wave for use when cursors are selected. [a,b] subranges can't be used w/Andy's XOP
// X fitYw not behaving correctly - probably need to hand-trim
// X use the switch in the wrapper, building the structure and function call as necessary
// X be sure that the smeared function name is printed out as it's used, not the generic wrapper
// X test for speed. the smeared fit is especially SLOW, WAY slower than it should be...AAO vs. point function??
// X decide which options to add (/N /DUMP /TOL, robust fitting, etc - see Andy's list
// X add the XOP to the distribution, or instructions (better to NOT bundle...)
// X odd bug where first "fit" fails on AppendToGraph as GenCurveFit is started. May need to disable /D flag
//
// -- need to pass back the chi-squared and number of points. "V_" globals don't appear
//
// for the speed test. try writing my own wrapper for an unsmeared calculation, and see if it's still dog-slow.
// --- NOPE, the wrapper is not a problem, tested this, and they seem to be both the same speed, each only about 5 seconds.
// -- timing results for fitting apoferritin:
//
// L-M method, unsmeared: 0.95 s
// L-M method, smeared: 5.85 s
//
// Genetic method, unsmeared: 7.32 s (2199 function evaluations) = 0.0033 sec/eval
// Genetic method, smeared: 416 s (2830 function evaluations x20 for smearing) = 0.0074 sec/eval !
//
// -- even correcting the Gen-smeared fit for the 20pt quadrature, calculations there are 2x slower than
// the same unsmeared fit. Why?? Both converge in the same number of iterations (~30 to 40). The number of function
// evaluations is different, due to the random start and random mutations. Setting the seed is unlikely
// to change the results.

Static Constant kGenOp_tol=0.001


Function Init_GenOp()
	if(!exists("GenCurveFit"))
		DoAlert 1,"The genetic optimiztion XOP is not installed. Do you want to open the web page to download the installer?"
		if(V_flag == 1)
			BrowseURL "http://www.igorexchange.com/project/gencurvefit"
		endif
	else
		DoAlert 0,"Genetic Optimization has been enabled."
		Variable/G root:Packages:NIST:gUseGenCurveFit = 1			//set to 1 to use genetic optimization
	endif
	BuildMenu "SANS Models"
End

// uncheck the flag, and change the menu
Function UnSet_GenOp()
	DoAlert 0,"Genetic Optimization has been disabled"
	Variable/G root:Packages:NIST:gUseGenCurveFit = 0			//set to 1 to use genetic optimization
	BuildMenu "SANS Models"
End

Function/S GenOpFlagEnable()
	Variable flag = NumVarOrDefault("root:Packages:NIST:gUseGenCurveFit",0)
//	NVAR/Z flag = root:Packages:NIST:gUseGenCurveFit
//	if(!NVAR_Exists(flag))
//		return("")		//to catch the initial menu build that occurs before globals are created
//	endif
	
	if(flag)
		return("!"+num2char(18) + " ")
	else
		return("")
	endif
	BuildMenu "SANS Models"
end
// this is the default selection if nvar does not exist
Function/S GenOpFlagDisable()
	Variable flag = NumVarOrDefault("root:Packages:NIST:gUseGenCurveFit",0)

//	NVAR/Z flag = root:Packages:NIST:gUseGenCurveFit
//	if(!NVAR_Exists(flag))
//		Variable/G root:Packages:NIST:gUseGenCurveFit = 0
//	endif
	
	if(!flag)
		return("!"+num2char(18) + " ")
	else
		return("")
	endif
	BuildMenu "SANS Models"
end



// the structure must be named fitFuncStruct, or the XOP will report an error and not run
//
Structure fitFuncStruct   
	Wave w
	wave y
	wave x[50]
	int16 numVarMD
	wave ffsWaves[50]
	wave ffsTextWaves[10]
	variable ffsvar[5]
	string ffsstr[5]
	nvar ffsnvars[5]
	svar ffssvars[5]
	funcref SANSModelAAO_proto ffsfuncrefs[10]		//this is an AAO format
	uint32 ffsversion    // Structure version. 
EndStructure 

Function GeneticFit_SmearedModel(s) : FitFunc
	Struct fitFuncStruct &s

	FUNCREF SANSModelSTRUCT_proto foo=$s.ffsstr[0]
	NVAR num = root:num_evals
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = s.w	
	WAVE fs.yW = s.y
	WAVE fs.xW = s.x[0]
	WAVE fs.resW = s.ffsWaves[0]
	
	Variable err
	err = foo(fs)		//this is the smeared STRUCT function
		
	num += 1
	return(0)
End

Function GeneticFit_UnSmearedModel(s) : FitFunc
	Struct fitFuncStruct &s

	FUNCREF SANSModelAAO_proto foo=$s.ffsstr[0]
	NVAR num = root:num_evals

	foo(s.w,s.y,s.x[0])			//this is the unsmeared function
	
	num += 1
	
	return(0)
End

// need to pass back the chi-squared and number of points. "V_" globals don't appear
//
Function DoGenCurveFit(useRes,useCursors,sw,fitYw,fs,funcStr,holdStr,val,lolim,hilim,pt1,pt2)
	Variable useRes,useCursors
	WAVE sw,fitYw
	STRUCT ResSmearAAOStruct &fs
	String &funcStr,holdStr
	Variable &val
	WAVE/T lolim,hilim
	Variable pt1,pt2		//already sorted if cursors are needed

	// initialise the structure you will use
	struct fitFuncStruct bar

	// we must set the version of the structure (currently 1000)
	bar.ffsversion = 1000
	
	// numVarMD is the number of dependent variables you are fitting
	// this must be correct, or Gencurvefit won't run.
	bar.numVarMD=1		

	// fill in the details and waves that I need
	bar.ffsstr[0] = funcStr //generate the reference as needed for smeared or unsmeared
	WAVE bar.w = fs.coefW
	WAVE bar.y =fs.yW
	WAVE bar.x[0] = fs.xW
	WAVE/Z bar.ffsWaves[0] = fs.resW		//will not exist for 3-column data sets
	

	//need to parse limits, or make up some defaults
	// limits is (n,2)
	Variable nPnts = numpnts(fs.coefW),i,multip=1.01,isUSANS=0,tol=0.01
	Make/O/D/N=(nPnts,2) limits
	Wave limits=limits
	for (i=0; i < nPnts; i += 1)
	
		if (strlen(lolim[i]) > 0)
			limits[i][0] = str2num(lolim[i])
		else
			if(cmpstr(holdStr[i],"0")==0)		//no limit, not held
				Abort "You must enter low and high coefficient limits for all free parameters"
			else
				limits[i][0] = fs.coefW[i]/multip		//fixed parameter, just stick something in
			endif
		endif
		
		if (strlen(hilim[i]) > 0)
			limits[i][1] = str2num(hilim[i])
		else
			if(cmpstr(holdStr[i],"0")==0)		//no limit, not held
				Abort "You must enter low and high coefficient limits for all free parameters"
			else	
				limits[i][1] = fs.coefW[i] * multip
			endif
		endif
	endfor

	if (dimsize(fs.resW,1) > 4)
		isUSANS = 1
	endif
	
//	generate a mask wave if needed (1=use, 0=mask)
// currently, the mask is not used, since smeared USANS is not handled correctly
// temporary, trimmed data sets are used instead
	if(useCursors)
		npnts = numpnts(fs.xW)
//		Make/O/D/N=(npnts) GenOpMask
//		Wave GenOpMask=GenOpMask
//		GenOpMask = 1
//		for(i=0;i<pt1;i+=1)
//			GenOpMask[i] = 0
//		endfor
//		for(i=pt2;i<npnts-1;i+=1)
//			GenOpMask[i] = 0
//		endfor

		Redimension/N=(pt2-pt1+1) fitYw
		
		Make/O/D/N=(pt2-pt1+1) trimY,trimX,trimS
		WAVE trimY=trimY
		trimY = fs.yW[p+pt1]
		WAVE trimX=trimX
		trimX = fs.xW[p+pt1]
		WAVE trimS=trimS
		trimS = sw[p+pt1]
		//trim all of the waves, don't use the mask
		WAVE bar.y = trimY
		WAVE bar.x[0] = trimX
		
	endif	

	Variable t0 = stopMStimer(-2)


	
	Variable/G root:num_evals		//for my own tracking
	NVAR num = root:num_evals
	num=0

	
	// other useful flags:  /N /DUMP /TOL /D=fitYw
	//  /OPT=1 seems to make no difference whether it's used or not
	
#if exists("GenCurveFit")
	// append the fit
	//do this only because GenCurveFit tries to append too quickly?
	String traces=TraceNameList("", ";", 1 )		//"" as first parameter == look on the target graph
	if(strsearch(traces,"FitYw",0) == -1)
		if(useCursors)
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs fs.xw
		endif
	else
		RemoveFromGraph FitYw
		if(useCursors)
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs fs.xw
		endif
	endif
	ModifyGraph lsize(FitYw)=2,rgb(FitYw)=(0,0,0)

	do
			
		if(useRes && useCursors)
			GenCurveFit/MAT /STRC=bar /X=bar.x[0] /I=1 /TOL=(kGenOp_tol) /W=trimS /D=fitYw GeneticFit_SmearedModel,bar.y,bar.w,holdStr,limits
			break
		endif
		if(useRes)
			GenCurveFit/MAT /STRC=bar /X=bar.x[0] /I=1 /TOL=(kGenOp_tol) /W=sw /D=fitYw GeneticFit_SmearedModel,bar.y,bar.w,holdStr,limits
			break
		endif
		
		//no resolution
		if(!useRes && useCursors)
			GenCurveFit/MAT /STRC=bar /X=bar.x[0] /I=1 /TOL=(kGenOp_tol) /W=trimS /D=fitYw GeneticFit_UnSmearedModel,bar.y,bar.w,holdStr,limits
			break
		endif
		if(!useRes)
			GenCurveFit/MAT /STRC=bar /X=bar.x[0] /I=1 /TOL=(kGenOp_tol) /W=sw /D=fitYw GeneticFit_UnSmearedModel,bar.y,bar.w,holdStr,limits
			break
		endif
		
	while(0)	
#endif
	
//	NVAR V_chisq = V_chisq
//	NVAR V_npnts = V_npnts
//	NVAR V_fitIters = V_fitIters
	WAVE/Z W_sigma = W_sigma
	
	val = V_npnts		//return this as a parameter
	
	t0 = (stopMSTimer(-2) - t0)*1e-6
	Printf  "fit time = %g seconds\r\r",t0
	Print W_sigma	
	Print "number of iterations = ",V_fitIters
	Print "number of function evaluations = ",num
	Print "Chi-squared = ",V_chisq
	
	return(V_chisq)
end