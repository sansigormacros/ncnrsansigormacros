#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1

// calculates the scattering from a spherical particle made up of a core (aqueous) surrounded
// by N spherical layers, each of which is a PAIR of shells, solvent + surfactant since there
//must always be a surfactant layer on the outside
//
// bragg peaks arise naturally from the periodicity of the sample
// resolution smeared version gives he most appropriate view of the model

//
//
Proc PlotMultiShellSphere(num,qmin,qmax)
	Variable num=100,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	make/O/D/N=(num) xwave_mss,ywave_mss
	xwave_mss =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	make/O/D coef_mss = {1.,60,10,10,6.4e-6,0.4e-6,2,0.001}
	make/O/T parameters_mss = {"scale","core radius (A)","shell thickness (A)","water thickness","core & solvent SLD (A-2)","Shell SLD (A-2)","number of water/shell pairs","bkg (cm-1)"}
	Edit/K=1 parameters_mss,coef_mss
	
	Variable/G root:g_mss
	g_mss := MultiShellSphere(coef_mss,ywave_mss,xwave_mss)
	Display/K=1 ywave_mss vs xwave_mss
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("MultiShellSphere","coef_mss","parameters_mss","mss")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedMultiShellSphere(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	make/O/D smear_coef_mss = {1.,60,10,10,6.4e-6,0.4e-6,2,0.001}					
	make/O/T smear_parameters_mss = {"scale","core radius (A)","shell thickness (A)","water thickness","core & solvent SLD (A-2)","Shell SLD (A-2)","number of water/shell pairs","bkg (cm-1)"}
	Edit/K=1 smear_parameters_mss,smear_coef_mss					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_mss,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_mss							
					
	Variable/G gs_mss=0
	gs_mss := fSmearedMultiShellSphere(smear_coef_mss,smeared_mss,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display/K=1 smeared_mss vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedMultiShellSphere","smear_coef_mss","smear_parameters_mss","mss")
End




//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function MultiShellSphere(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("MultiShellSphereX")
	MultiThread yw = MultiShellSphereX(cw,xw)
#else
	yw = fMultiShellSphere(cw,xw)
#endif
	return(0)
End

Function fMultiShellSphere(w,x) :FitFunc
	Wave w
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of core [A]
	//[2] thickness of the shell	[A]
	//[3] thickness of the water layer
	//[4] SLD of the core = sld of the solvent[A-2]
	//[5] SLD of the shell
	//[6] number of pairs (tw+tsh)
	//[7] background	[cm-1]
	
	// All inputs are in ANGSTROMS
	//OUTPUT is normalized by the particle volume, and converted to [cm-1]
	
	
	Variable scale,rcore,tw,ts,rhocore,rhoshel,num,bkg
	scale = w[0]
	rcore = w[1]
	ts = w[2]
	tw = w[3]
	rhocore = w[4]
	rhoshel = w[5]
	num = w[6]
	bkg = w[7]
	
	//calculate with a loop, two shells at a time
	Variable ii=0,fval=0,voli,ri,sldi

	do
		ri = rcore + ii*ts + ii*tw
		voli = 4*pi/3*ri^3
		sldi = rhocore-rhoshel
		fval += voli*sldi*F_func(ri*x)
		ri += ts
		voli = 4*pi/3*ri^3
		sldi = rhoshel-rhocore
		fval += voli*sldi*F_func(ri*x)
		ii+=1		//do 2 layers at a time
	while(ii<=num-1)  //change to make 0 < num < 2 correspond to unilamellar vesicles (C. Glinka, 11/24/03)
	
	fval *=fval		//square it
	fval /=voli		//normalize by the overall volume
	fval *=scale*1e8
	fval += bkg
	
	return(fval)
End

Function F_func(qr)
	Variable qr
	
	Variable val=0
	if(qr == 0)
		val = 1
	else	
		val = 3*(sin(qr) - qr*cos(qr))/qr^3
	endif
		
	return(val)
End


//
//Function Schulz_Point_ms(x,avg,zz)
//
//	//Wave w
//	Variable x,avg,zz
//	Variable dr
//	
//	dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))
//	
//	return (exp(dr))
//	
//End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedMultiShellSphere(coefW,yW,xW)
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
	err = SmearedMultiShellSphere(fs)
	
	return (0)
End

// this model needs 76 Gauss points for a proper smearing calculation
// since there can be sharp interference fringes that develop from the stacking
Function SmearedMultiShellSphere(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_76(MultiShellSphere,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
	