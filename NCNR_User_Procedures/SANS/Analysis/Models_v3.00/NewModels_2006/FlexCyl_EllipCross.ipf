#pragma rtGlobals=1		// Use modern global access method.

#include "FlexibleCylinder"

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
	Prompt qmin "Enter minimum q-value (Å^-1) for model: "
	Prompt qmax "Enter maximum q-value (Å^-1) for model: "
	
	Make/O/D/n=(num) xwave_fleell,ywave_fleell
	xwave_fleell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_fleell = {1.,1000,100,20,1.5,3.0e-6,0.0001}
	make/o/t parameters_fleell = {"scale","Contour Length (A)","Kuhn Length, b (A)","Minor Radius (a) (A)","Axis Ratio = major/a","contrast (A^-2)","bkgd (arb)"}
	Edit parameters_fleell,coef_fleell
	ywave_fleell := FlexCyl_Ellip(coef_fleell,xwave_fleell)
	Display ywave_fleell vs xwave_fleell
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

//setup the smeared model calculation
//
Proc PlotSmeared_FlexCyl_Ellip()	
	// if no gQvals wave, data must not have been loaded => abort
	
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	Make/O/D smear_coef_fleell = {1.,1000,100,20,1.5,3.0e-6,0.0001}
	make/o/t smear_parameters_fleell = {"scale","ContourLength (A)","KuhnLength, b (A)","Minor Radius (a) (A)","Axis Ratio = major/a","contrast (A^-2)","bkgd (arb)"}
	Edit smear_parameters_fleell,smear_coef_fleell					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_fleell,smeared_qvals				//
	SetScale d,0,0,"1/cm",smeared_fleell							//

	smeared_fleell := SmearedFlexCyl_Ellip(smear_coef_fleell,$gQvals)		// SMEARED function name
	Display smeared_fleell vs smeared_qvals									//
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (Å\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End     // end macro 


//
Function FlexCyl_Ellip(ww,x) :FitFunc
	Wave ww
	Variable x

	//nice names to the input params
	//ww[0] = scale
	//ww[1] = L [A]
	//ww[2] = B [A]
	//ww[3] = rad [A] cross-sectional radius
	//ww[4] = ellRatio = major/minor axis (greater than one)
	//ww[5] = contrast [A^-2]
	//ww[6] = bkg [cm-1]
	Variable scale,L,B,bkg,rad,qr,cont,ellRatio
	
	scale = ww[0]
	L = ww[1]
	B = ww[2]
	rad = ww[3]
	ellRatio = ww[4]
	cont = ww[5]
	bkg = ww[6]
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

// this is all there is to the smeared calculation!
Function SmearedFlexCyl_Ellip(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(FlexCyl_Ellip,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End

