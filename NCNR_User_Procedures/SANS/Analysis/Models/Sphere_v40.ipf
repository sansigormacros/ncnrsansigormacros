#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// this procedure calculates the form factor of a sphere
//
// 06 NOV 98 SRK
//
// modified June 2007 to calculate all-at-once
// and to use a structure for resolution information
//
////////////////////////////////////////////////

Proc PlotSphereForm(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_sf,ywave_sf					
	xwave_sf = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_sf = {1.,60,1e-6,6.3e-6,0.01}						
	make/o/t parameters_sf = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}		
	Edit parameters_sf,coef_sf	
	Variable/G root:g_sf=0			
	root:g_sf := SphereForm(coef_sf,ywave_sf,xwave_sf)	// AAO calculation, "fake" dependency
//	ywave_sf := SphereForm(coef_sf,xwave_sf)		//point calculation
	Display ywave_sf vs xwave_sf							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("SphereForm","coef_sf","sf")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedSphereForm(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sf = {1.,60,1e-6,6.3e-6,0.01}					
	make/o/t smear_parameters_sf = {"scale","Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit smear_parameters_sf,smear_coef_sf					
	
	Duplicate/O $(str+"_q") smeared_sf,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_sf					
		
	Variable/G gs_sf=0
	gs_sf := fSmearedSphereForm(smear_coef_sf,smeared_sf,smeared_qvals)	//this wrapper fills the STRUCT
	Display smeared_sf vs smeared_qvals								
	
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedSphereForm","smear_coef_sf","sf")
End

//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function SphereForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("SphereFormX")
	yw = SphereFormX(cw,xw)
#else
	yw = fSphereForm(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
// this is a "regular" calculation at a single q-value
///////////////////////////
Function fSphereForm(w,x)					
	Wave w
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (Å)
	//[2] sld sphere (Å-2)
	//[3] sld solv
	//[4] background (cm-1)
	
	Variable scale,radius,delrho,bkg,sldSph,sldSolv		
	scale = w[0]
	radius = w[1]
	sldSph = w[2]
	sldSolv = w[3]
	bkg = w[4]
	
	delrho = sldSph - sldSolv
	// calculates scale * f^2/Vol where f=Vol*3*delrho*((sin(qr)-qrcos(qr))/qr^3
	// and is rescaled to give [=] cm^-1
	
	Variable bes,f,vol,f2
	//
	//handle q==0 separately
	If(x==0)
		f = 4/3*pi*radius^3*delrho*delrho*scale*1e8 + bkg
		return(f)
	Endif
	
	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3
	vol = 4*pi/3*radius^3
	f = vol*bes*delrho		// [=] Å
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8		// [=] 1/cm
	
	return (scale*f2+bkg)	// Scale, then add in the background
End


//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct
// calls the ususal function with the STRUCT parameter
//
// -- problem- this assumes USANS w/no matrix
// -- needs experimental q-values to properly calculate the fitted curve?? is this true?
// -- how to fill the struct if the type of data is unknown?
// -- where do I find the matrix?
//
Function fSmearedSphereForm(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW		//is this the proper way to populate? seems redundant...
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedSphereForm(fs)
	
	return (0)
End

// smeared calculation, AAO and using a structure...
// defined as as STRUCT, there can never be a dependency linked directly to this function
// - so set a dependency to the wrapper
//
// like the unsmeared function, AAO is equivalent to a wave assignment to the point calculation
// - but now the function passed is an AAO function
//
// Smear_Model_20() takes care of what calculation is done, depending on the resolution information
//
//
Function SmearedSphereForm(s) : FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(SphereForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End
 

// wrapper to do the desired fit
// 
// str is the data folder for the desired data set
//
// -- this looks like something that can be made rather generic rather easily
//
//Function SphereFitWrapper(str)
//	String str
//		
//	SetDataFolder root:
//	String DF="root:"+str+":"
//	
//	Struct ResSmearAAOStruct fs
//	WAVE resW = $(DF+str+"_res")		
//	WAVE fs.resW =  resW
//	
//	WAVE cw=$(DF+"smear_coef_sf")
//	WAVE yw=$(DF+str+"_i")
//	WAVE xw=$(DF+str+"_q")
//	WAVE sw=$(DF+str+"_s")
//	
//	Duplicate/O yw $(DF+"FitYw")
//	
//	//can't use execute if /STRC is needed since structure instance is not a global!
//	//don't use the auto-destination with no flag, it doesn't appear to work correctly
//	//force it to use a wave of identical length, at least - no guarantee that the q-values 
//	// will be the same? be sure that the smearing iterpolates
//	//
//	// ?? how can I get the hold string in correctly?? - from a global? - no, as string function
//	//
//	FuncFit/H=getHoldStr() /NTHR=0 SmearedSphereForm, cw, yw /X=xw /W=sw /I=1 /STRC=fs
////	FuncFit/H=getHoldStr() /NTHR=0 SphereForm cw, yw /X=xw /W=sw /I=1 /D=$(DF+"FitYw")
//
////	FuncFit/H="0010"/NTHR=0 SmearedSphereForm cw, yw /X=xw /W=sw /I=1 /D=$(DF+"FitYw") /STRC=fs
//	Wave fityw =  $(DF+"FitYw")
//	fs.yW = fityw
//	SmearedSphereForm(fs)
//	AppendToGraph fityw vs xw 
//	
//	print "V_chisq = ",V_chisq
//	print cw
//	WAVE w_sigma
//	print w_sigma
//	
//	return(0)
//End
//
//Function/S getHoldStr()
//
//	String str="0010"
//	return str
//End
