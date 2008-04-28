#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

////////////////////////////////////////////////
// GaussUtils.proc and PlotUtils.proc MUST be included for the smearing calculation to compile
// Adopting these into the experiment will insure that they are always present
////////////////////////////////////////////////
//
// this function calculates the form factor for polydisperse spherical particles
// the polydispersity is a Schulz distribution
// the spherical particles have a core-shell structure, with a polydisperse core and constant
// shell thickness
//
// 06 NOV 98 SRK
////////////////////////////////////////////////

Proc PlotPolyCoreForm(num,qmin,qmax)
	Variable num=256,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_pcf,ywave_pcf
	//xwave_pcf = qmin + x*((qmax-qmin)/num)
	xwave_pcf = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pcf = {1.,60,.2,10,1e-6,2e-6,3e-6,0.001}
	make/o/t parameters_pcf = {"scale","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit parameters_pcf,coef_pcf
	Variable/G root:g_pcf
	g_pcf := PolyCoreForm(coef_pcf,ywave_pcf,xwave_pcf)
//	ywave_pcf := PolyCoreForm(coef_pcf,xwave_pcf)
	Display ywave_pcf vs xwave_pcf
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyCoreForm","coef_pcf","pcf")
End

///////////////////////////////////////////////////////////
// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedPolyCoreForm(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pcf = {1.,60,.2,10,1e-6,2e-6,3e-6,0.001}
	make/o/t smear_parameters_pcf = {"scale","avg core rad (A)","core polydisp (0,1)","shell thickness (A)","SLD core (A-2)","SLD shell (A-2)","SLD solvent (A-2)","bkg (cm-1)"}
	Edit smear_parameters_pcf,smear_coef_pcf
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_pcf,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_pcf					
		
	Variable/G gs_pcf=0
	gs_pcf := fSmearedPolyCoreForm(smear_coef_pcf,smeared_pcf,smeared_qvals)	//this wrapper fills the STRUCT

	Display smeared_pcf vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)	
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyCoreForm","smear_coef_pcf","pcf")
End


//AAO verison
Function PolyCoreForm(cw,yw,xw) : FitFunc
	Wave cw,yw,xw

#if exists("PolyCoreFormX")
	yw = PolyCoreFormX(cw,xw)
#else
	yw = fPolyCoreForm(cw,xw)
#endif
	return(0)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
Function fPolyCoreForm(w,h) : FitFunc
	Wave w
	Variable h 	// x is already used below

//* 		calculates <f^2> for a spherical core/shell */
//* 		geometry with a polydispersity of the core only */
//* 		The shell thickness is constant */
//*     from  J. Chem. Phys. 96 (1992) 3306. */
//* 	beta factor is not calculated */

// input parameters are
	//[0] scale
	//[1] average core radius	[Å]
	//[2] polydispersity of core (0<sig<1)
	//[3] shell thickness	[Å]
	//[4] SLD core		[Å-2]
	//[5] SLD shell
	//[6] SLD solvent
	//[7] background [cm-1]


// OUTPUT <f^2>/Vavg IN [cm-1]
	
// names for inputs and returned value
	Variable scale,corrad,sig,zz,del,drho1,drho2,form,bkg
	scale = w[0]
	corrad = w[1]
	sig = w[2]
	zz = (1/sig)^2 - 1
	del = w[3]
	drho1 = w[4]-w[5]		//core-shell
	drho2 = w[5]-w[6]		//shell-solvent
	bkg = w[7]
	
	
   //* Local variables */
    Variable d, g
    Variable qq, x, y, c1, c2, c3, c4, c5, c6, c7, c8, c9, t1, t2, t3
    Variable t4, t5, tb, cy, sy, tb1, tb2, tb3, c2y, zp1, zp2
    Variable zp3,vpoly
    Variable s2y, arg1, arg2, arg3, drh1, drh2


//*    !!!!! drh NOW given in 1/A^2  */
//*    core radius, del, and 1/q must be in Angstroms */

    drh1 = drho1 
    drh2 = drho2 
    g = drh2 * -1. / drh1
    zp1 = zz + 1.
    zp2 = zz + 2.
    zp3 = zz + 3.
    vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(corrad+del)^3


	qq = h	// remember that h is the passed in value of q for the calculation
	y = h *del
	x = h *corrad
	d = atan(x * 2. / zp1)
	arg1 = zp1 * d
	arg2 = zp2 * d
	arg3 = zp3 * d
	sy = sin(y)
	cy = cos(y)
	s2y = sin(y * 2.)
	c2y = cos(y * 2.)
	c1 = .5 - g * (cy + y * sy) + g * g * .5 * (y * y + 1.)
	c2 = g * y * (g - cy)
	c3 = (g * g + 1.) * .5 - g * cy
	c4 = g * g * (y * cy - sy) * (y * cy - sy) - c1
	c5 = g * 2. * sy * (1. - g * (y * sy + cy)) + c2
	c6 = c3 - g * g * sy * sy
	c7 = g * sy - g * .5 * g * (y * y + 1.) * s2y - c5
	c8 = c4 - .5 + g * cy - g * .5 * g * (y * y + 1.) * c2y
	c9 = g * sy * (1. - g * cy)

	tb = ln(zp1 * zp1 / (zp1 * zp1 + x * 4. * x))
	tb1 = exp(zp1 * .5 * tb)
	tb2 = exp(zp2 * .5 * tb)
	tb3 = exp(zp3 * .5 * tb)

	t1 = c1 + c2 * x + c3 * x * x * zp2 / zp1
	t2 = tb1 * (c4 * cos(arg1) + c7 * sin(arg1))
	t3 = x * tb2 * (c5 * cos(arg2) + c8 * sin(arg2))
	t4 = zp2 / zp1 * x * x * tb3 * (c6 * cos(arg3) + c9 * sin(arg3))
	t5 = t1 + t2 + t3 + t4
	form = t5 * 16. * pi * pi * drh1 * drh1 / (qq^6)
//	normalize by the average volume !!! corrected for polydispersity
// and convert to cm-1
	form /= vpoly
	form *= 1.0e8
	//Scale
	form *= scale
	// then add in the background
	form += bkg
	
  return (form)

End // end of polyCoreform

// this is all there is to the smeared calculation!
Function SmearedPolyCoreForm(s) :FitFunc
	Struct ResSmearAAOStruct &s

////the name of your unsmeared model is the first argument
	Smear_Model_20(PolyCoreForm,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyCoreForm(coefW,yW,xW)
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
	err = SmearedPolyCoreForm(fs)
	
	return (0)
End