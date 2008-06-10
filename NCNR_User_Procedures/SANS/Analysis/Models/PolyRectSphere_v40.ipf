#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this example is for the form factor of polydisperse spheres
// no interparticle interactions are included 
// the polydispersity in radius is a rectangular distribution
//
// 13 JAN 99 SRK
////////////////////////////////////////////////

Proc PlotPolyRectSpheres(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_rect,ywave_rect
	xwave_rect =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_rect = {1,60,0.12,1e-6,6.3e-6,0.}
	make/o/t parameters_rect = {"scale","Radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","background (cm^-1)"}
	Edit parameters_rect,coef_rect
	Variable/G root:g_rect
	g_rect := PolyRectSpheres(coef_rect,ywave_rect,xwave_rect)
//	ywave_rect := PolyRectSpheres(coef_rect,xwave_rect)
	Display ywave_rect vs xwave_rect
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
//	DoAlert 0,"The form facor is not properly normalized with the polydisperse volume"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRectSpheres","coef_rect","rect")
End


///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyRectSpheres(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_rect = {1,60,0.12,1e-6,6.3e-6,0.}
	make/o/t smear_parameters_rect = {"scale","Radius (A)","polydispersity","SLD sphere (A^-2)","SLD solvent (A^-2)","background (cm^-1)"}
	Edit smear_parameters_rect,smear_coef_rect
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_rect,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_rect			
		
	Variable/G gs_rect=0
	gs_rect := fSmearedPolyRectSpheres(smear_coef_rect,smeared_rect,smeared_qvals)	//this wrapper fills the STRUCT

	Display smeared_rect vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)	
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRectSpheres","smear_coef_rect","rect")
End


//AAO version
Function PolyRectSpheres(cw,yw,xw) : FitFunc
		Wave cw,yw,xw

#if exists("PolyRectSpheresX")
	yw = PolyRectSpheresX(cw,xw)
#else
	yw = fPolyRectSpheres(cw,xw)
#endif
	return(0)
End
///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fPolyRectSpheres(w,x) : FitFunc
	Wave w			// the coefficient wave
	Variable x		// the x values, as a variable
	 
	//* reassign names to the variable set */
	 Variable scale,rad,pd,cont,bkg,sld,slds
	 
	scale = w[0]
	rad = w[1]		// radius (A)
	pd = w[2]		//polydispersity of rectangular distribution
	sld = w[3]		// contrast (A^-2)
	slds = w[4]
	bkg = w[5]		// background (1/cm)

	cont = sld - slds
// local variables
	Variable inten,h1,qw,qr,width,sig,averad3,Vavg,Rg2

	// as usual, poly = sig/ravg
	// for the rectangular distribution, sig = width/sqrt(3)
	// width is the HALF- WIDTH of the rectangular distribution
	
	sig = pd*rad
	width = sqrt(3)*sig
	
	//x is the q-value
	qw = x*width
	qr = x*rad
	
	// as for the low QR "crud", the function is calculating the sines and cosines just fine
	// - the problem seems to be that the 
	// leading terms nearly cancel with the last term (the -6*qr... term), to within machine
	// precision - the difference is on the order of 10^-20
	// so just use the limiting Guiner value
	if(qr<0.1) 
		h1 = scale*cont*cont*1e8*4*pi/3*rad^3
		h1 *= 	(1 + 15*pd^2 + 27*pd^4 +27/7*pd^6)				//6th moment
		h1 /= (1+3*pd^2)		//3rd moment
		
		Rg2 = 3/5*rad*rad*(1+28*pd^2+126*pd^4+108*pd^6+27*pd^8)
		Rg2 /= (1+15*pd^2+27*pd^4+27/7*pd^6)
				
		h1 *= exp(-1/3*Rg2*x*x)
		h1 += bkg
		return(h1)
	endif
	
	
	//normal calculation
	h1 = -0.5*qw + qr*qr*qw + (qw^3)/3
	h1 -= 5/2*cos(2*qr)*sin(qw)*cos(qw)
	h1 += 0.5*qr*qr*cos(2*qr)*sin(2*qw)
	h1 += 0.5*qw*qw*cos(2*qr)*sin(2*qw)
	h1 += qw*qr*sin(2*qr)*cos(2*qw)
	h1 += 3*qw*(cos(qr)*cos(qw))^2
	h1 += 3*qw*(sin(qr)*sin(qw))^2
	
	h1 -= 6*qr*cos(qr)*sin(qr)*cos(qw)*sin(qw)
	
	// calculate P(q) = <f^2>
	inten = 8*Pi*Pi*cont*cont/width/x^7*h1
	
// beta(q) would be calculated as 2/width/x/h1*h2*h2
// with 
// h2 = 2*sin(x*rad)*sin(x*width)-x*rad*cos(x*rad)*sin(x*width)-x*width*sin(x*rad)*cos(x*width)

	// normalize to the average volume
	// <R^3> = ravg^3*(1+3*pd^2)
	// or... "zf"  = (1 + 3*p^2), which will be greater than one
	
	averad3 =  rad^3*(1+3*pd^2)
	inten /= 4*pi/3*averad3
	//resacle to 1/cm
	inten *= 1.0e8
	//scale the result
	inten *= scale
	// then add in the background
	inten += bkg
	
	return (inten)

End   // end of PolyRectSpheres()

// this is all there is to the smeared calculation!
Function SmearedPolyRectSpheres(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(PolyRectSpheres,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRectSpheres(coefW,yW,xW)
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
	err = SmearedPolyRectSpheres(fs)
	
	return (0)
End