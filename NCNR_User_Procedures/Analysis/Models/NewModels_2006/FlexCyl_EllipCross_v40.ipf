#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 6.0

#include "FlexibleCylinder_v40"

///////////////////////////
// plots the scattering from a flexible cylinder with an 
// elliptical cross-section
//
// same chain calculation as flexible cylinder, 
// correcting for a different cross-section
//
// Bergstrom / Pedersen reference in Langmuir
//
// Contains Wei-Ren's corrections for the chain model July 2006
//
//
Proc PlotFlexCyl_Ellip(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/n=(num) xwave_fleell,ywave_fleell
	xwave_fleell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_fleell = {1.,1000,100,20,1.5,1e-6,6.3e-6,0.0001}
	make/o/t parameters_fleell = {"scale","Contour Length (A)","Kuhn Length, b (A)","Minor Radius (a) (A)","Axis Ratio = major/a","SLD cylinder (A^-2)","SLD solvent (A^-2)","bkgd (arb)"}
	Edit parameters_fleell,coef_fleell
	
	Variable/G root:g_fleell
	g_fleell := FlexCyl_Ellip(coef_fleell,ywave_fleell,xwave_fleell)
	Display ywave_fleell vs xwave_fleell
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("FlexCyl_Ellip","coef_fleell","parameters_fleell","fleell")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedFlexCyl_Ellip(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fleell = {1.,1000,100,20,1.5,1e-6,6.3e-6,0.0001}
	make/o/t smear_parameters_fleell = {"scale","Contour Length (A)","Kuhn Length, b (A)","Minor Radius (a) (A)","Axis Ratio = major/a","SLD cylinder (A^-2)","SLD solvent (A^-2)","bkgd (arb)"}
	Edit smear_parameters_fleell,smear_coef_fleell					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_fleell,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fleell							//
					
	Variable/G gs_fleell=0
	gs_fleell := fSmearedFlexCyl_Ellip(smear_coef_fleell,smeared_fleell,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_fleell vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedFlexCyl_Ellip","smear_coef_fleell","smear_parameters_fleell","fleell")
End
	



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function FlexCyl_Ellip(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("FlexCyl_EllipX")
	yw = FlexCyl_EllipX(cw,xw)
#else
	yw = fFlexCyl_Ellip(cw,xw)
#endif
	return(0)
End

//
Function fFlexCyl_Ellip(ww,x) :FitFunc
	Wave ww
	Variable x

	//nice names to the input params
	//ww[0] = scale
	//ww[1] = L [A]
	//ww[2] = B [A]
	//ww[3] = rad [A] cross-sectional radius
	//ww[4] = ellRatio = major/minor axis (greater than one)
	//ww[5] = sld cylinder [A^-2]
	//ww[6] = sld solvent
	//ww[7] = bkg [cm-1]
	Variable scale,L,B,bkg,rad,qr,cont,ellRatio,sldc,slds
	
	scale = ww[0]
	L = ww[1]
	B = ww[2]
	rad = ww[3]
	ellRatio = ww[4]
	sldc = ww[5]
	slds = ww[6]
	bkg = ww[7]
	
	cont = sldc-slds
	qr = x*rad		//used for cross section contribution only
	
	//local variables
	Variable flex,crossSect

	flex = Sk_WR(x,L,B)			//Wei-Ren's calculations, do not have cross section
        
	//calculate cross section contribution - Eqns.(28) &(29) (approximate)
	//use elliptical cross-section here
	crossSect = EllipticalCross_fn(x,rad,(rad*ellRatio))
        
	//normalize form factor by multiplying by cylinder volume * cont^2
	// then convert to cm-1 by multiplying by 10^8
	// then scale = phi 

	flex *= crossSect
	flex *= Pi*rad*rad*ellRatio*L
	flex *= cont^2
	flex *= 1.0e8
	
	return (scale*flex + bkg)
       
end
////////////// flex chain - with excluded volume

Function EllipticalCross_fn(qq,a,b)
	Variable qq,a,b
	
	Make/O/D/N=100 ellip
	SetScale x,0,(pi/2),ellip
	
	ellip = bessJ(1,(qq*sqrt(a^2*sin(x)^2+b^2*cos(x)^2))) / (qq*sqrt(a^2*sin(x)^2+b^2*cos(x)^2))
	ellip *=2
	ellip = ellip^2
	Integrate/T ellip
	
	return(ellip[99]*2/pi)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedFlexCyl_Ellip(coefW,yW,xW)
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
	err = SmearedFlexCyl_Ellip(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedFlexCyl_Ellip(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(FlexCyl_Ellip,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

