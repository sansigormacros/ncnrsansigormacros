#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

// plots the Debye function for polymer scattering
//
Proc PlotDebye(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	make/O/D/N=(num) xwave_deb,ywave_deb
	xwave_deb = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	make/O/D coef_deb = {1.,50,0.001}
	make/O/T parameters_deb = {"scale","Rg (A)","bkg (cm-1)"}
	Edit parameters_deb,coef_deb
	
	Variable/G root:g_deb
	g_deb := Debye(coef_deb,ywave_deb,xwave_deb)
	Display ywave_deb vs xwave_deb
	ModifyGraph marker=29,msize=2,mode=4,log=1
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("Debye","coef_deb","deb")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedDebye(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/O/D smear_coef_deb = {1.,50,0.001}
	make/O/T smear_parameters_deb = {"scale","Rg (A)","bkg (cm-1)"}
	Edit smear_parameters_deb,smear_coef_deb
	
	// output smeared intensity wave
	Duplicate/O $(str+"_q") smeared_deb,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_deb
					
	Variable/G gs_deb=0
	gs_deb := fSmearedDebye(smear_coef_deb,smeared_deb,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_deb vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedDebye","smear_coef_deb","deb")
End
	

///////////////////////////////////////////////////////////////


//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function Debye(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("DebyeX")
	yw = DebyeX(cw,xw)
#else
	yw = fDebye(cw,xw)
#endif
	return(0)
End

Function fDebye(w,x) : FitFunc
	Wave w
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of gyration [Å]
	//[2] background	[cm-1]
	
	Variable scale,rg,bkg
	scale = w[0]
	rg = w[1]
	bkg = w[2]
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add in the background
	return (Pq+bkg)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedDebye(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedDebye(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedDebye(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(Debye,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	