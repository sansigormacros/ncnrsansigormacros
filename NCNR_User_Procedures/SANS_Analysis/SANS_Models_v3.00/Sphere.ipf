#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
// this procedure is for the form factor of a sphere
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotSphereForm(num,qmin,qmax)						
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_sf,ywave_sf					
	xwave_sf = alog(log(qmin) + x*((log(qmax)-log(qmin))/num))					
	Make/O/D coef_sf = {1.,60,1e-6,0.01}						
	make/o/t parameters_sf = {"scale","Radius (A)","contrast (Å-2)","bkgd (cm-1)"}		
	Edit parameters_sf,coef_sf								
	ywave_sf := SphereForm(coef_sf,xwave_sf)			
	Display ywave_sf vs xwave_sf							
	ModifyGraph log=1,marker=29,msize=2,mode=4			
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"					
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedSphereForm()								
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_sf = {1.,60,1e-6,0.0}					
	make/o/t smear_parameters_sf = {"scale","Radius (A)","contrast (Å-2)","bkgd (cm-1)"}		
	Edit smear_parameters_sf,smear_coef_sf					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_sf,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_sf							

	smeared_sf := SmearedSphereForm(smear_coef_sf,$gQvals)		
	Display smeared_sf vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function SphereForm(w,x)	: FitFunc					
	Wave w
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (Å)
	//[2] delrho (Å-2)
	//[3] background (cm-1)
	
	Variable scale,radius,delrho,bkg				
	scale = w[0]
	radius = w[1]
	delrho = w[2]
	bkg = w[3]
	
	
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

// this is all there is to the smeared calculation!
Function SmearedSphereForm(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(SphereForm,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End
