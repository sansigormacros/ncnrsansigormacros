#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

//
// used for the White Beam Smearing
//

// generates dummy functions of the form:
//
//Function BroadPeakX_(cw,x)
//	Wave cw
//	Variable x
//	return(BroadPeakX(cw,x))
//End
//
// so that I can use the FUNCREF
// which fails for some reason when I just use the XOP name?
//

Function MultiShellSphereX_(WAVE cw, variable x)

	return (MultiShellSphereX(cw, x))
End

Function PolyMultiShellX_(WAVE cw, variable x)

	return (PolyMultiShellX(cw, x))
End

Function SphereFormX_(WAVE cw, variable x)

	return (SphereFormX(cw, x))
End

Function CoreShellSphereX_(WAVE cw, variable x)

	return (CoreShellSphereX(cw, x))
End

Function PolyCoreFormX_(WAVE cw, variable x)

	return (PolyCoreFormX(cw, x))
End

Function PolyCoreShellRatioX_(WAVE cw, variable x)

	return (PolyCoreShellRatioX(cw, x))
End

Function VesicleFormX_(WAVE cw, variable x)

	return (VesicleFormX(cw, x))
End

Function SchulzSpheresX_(WAVE cw, variable x)

	return (SchulzSpheresX(cw, x))
End

Function PolyRectSpheresX_(WAVE cw, variable x)

	return (PolyRectSpheresX(cw, x))
End

Function PolyHardSpheresX_(WAVE cw, variable x)

	return (PolyHardSpheresX(cw, x))
End

Function BimodalSchulzSpheresX_(WAVE cw, variable x)

	return (BimodalSchulzSpheresX(cw, x))
End

Function GaussSpheresX_(WAVE cw, variable x)

	return (GaussSpheresX(cw, x))
End

Function LogNormalSphereX_(WAVE cw, variable x)

	return (LogNormalSphereX(cw, x))
End

Function BinaryHSX_(WAVE cw, variable x)

	return (BinaryHSX(cw, x))
End

Function BinaryHS_PSF11X_(WAVE cw, variable x)

	return (BinaryHS_PSF11X(cw, x))
End

Function BinaryHS_PSF12X_(WAVE cw, variable x)

	return (BinaryHS_PSF12X(cw, x))
End

Function BinaryHS_PSF22X_(WAVE cw, variable x)

	return (BinaryHS_PSF22X(cw, x))
End

Function CylinderFormX_(WAVE cw, variable x)

	return (CylinderFormX(cw, x))
End

Function EllipCyl76X_(WAVE cw, variable x)

	return (EllipCyl76X(cw, x))
End

Function EllipticalCylinderX_(WAVE cw, variable x)

	return (EllipticalCylinderX(cw, x))
End

Function TriaxialEllipsoidX_(WAVE cw, variable x)

	return (TriaxialEllipsoidX(cw, x))
End

Function ParallelepipedX_(WAVE cw, variable x)

	return (ParallelepipedX(cw, x))
End

Function HollowCylinderX_(WAVE cw, variable x)

	return (HollowCylinderX(cw, x))
End

Function EllipsoidFormX_(WAVE cw, variable x)

	return (EllipsoidFormX(cw, x))
End

Function Cyl_PolyRadiusX_(WAVE cw, variable x)

	return (Cyl_PolyRadiusX(cw, x))
End

Function Cyl_PolyLengthX_(WAVE cw, variable x)

	return (Cyl_PolyLengthX(cw, x))
End

Function CoreShellCylinderX_(WAVE cw, variable x)

	return (CoreShellCylinderX(cw, x))
End

Function OblateFormX_(WAVE cw, variable x)

	return (OblateFormX(cw, x))
End

Function ProlateFormX_(WAVE cw, variable x)

	return (ProlateFormX(cw, x))
End

Function FlexExclVolCylX_(WAVE cw, variable x)

	return (FlexExclVolCylX(cw, x))
End

Function FlexCyl_PolyLenX_(WAVE cw, variable x)

	return (FlexCyl_PolyLenX(cw, x))
End

Function FlexCyl_PolyRadX_(WAVE cw, variable x)

	return (FlexCyl_PolyRadX(cw, x))
End

Function FlexCyl_EllipX_(WAVE cw, variable x)

	return (FlexCyl_EllipX(cw, x))
End

Function PolyCoShCylinderX_(WAVE cw, variable x)

	return (PolyCoShCylinderX(cw, x))
End

Function StackedDiscsX_(WAVE cw, variable x)

	return (StackedDiscsX(cw, x))
End

Function LamellarFFX_(WAVE cw, variable x)

	return (LamellarFFX(cw, x))
End

Function LamellarFF_HGX_(WAVE cw, variable x)

	return (LamellarFF_HGX(cw, x))
End

Function LamellarPSX_(WAVE cw, variable x)

	return (LamellarPSX(cw, x))
End

Function LamellarPS_HGX_(WAVE cw, variable x)

	return (LamellarPS_HGX(cw, x))
End

Function TeubnerStreyModelX_(WAVE cw, variable x)

	return (TeubnerStreyModelX(cw, x))
End

Function Power_Law_ModelX_(WAVE cw, variable x)

	return (Power_Law_ModelX(cw, x))
End

Function Peak_Lorentz_ModelX_(WAVE cw, variable x)

	return (Peak_Lorentz_ModelX(cw, x))
End

Function Peak_Gauss_ModelX_(WAVE cw, variable x)

	return (Peak_Gauss_ModelX(cw, x))
End

Function Lorentz_ModelX_(WAVE cw, variable x)

	return (Lorentz_ModelX(cw, x))
End

Function FractalX_(WAVE cw, variable x)

	return (FractalX(cw, x))
End

Function DAB_ModelX_(WAVE cw, variable x)

	return (DAB_ModelX(cw, x))
End

Function OneLevelX_(WAVE cw, variable x)

	return (OneLevelX(cw, x))
End

Function TwoLevelX_(WAVE cw, variable x)

	return (TwoLevelX(cw, x))
End

Function ThreeLevelX_(WAVE cw, variable x)

	return (ThreeLevelX(cw, x))
End

Function FourLevelX_(WAVE cw, variable x)

	return (FourLevelX(cw, x))
End

Function HardSphereStructX_(WAVE cw, variable x)

	return (HardSphereStructX(cw, x))
End

Function SquareWellStructX_(WAVE cw, variable x)

	return (SquareWellStructX(cw, x))
End

Function StickyHS_StructX_(WAVE cw, variable x)

	return (StickyHS_StructX(cw, x))
End

Function HayterPenfoldMSAX_(WAVE cw, variable x)

	return (HayterPenfoldMSAX(cw, x))
End

//Function SmearedCyl_PolyRadiusX_(cw,x)
//	Wave cw
//	Variable x
//	return(SmearedCyl_PolyRadiusX(cw,x))
//End

Function SpherocylinderX_(WAVE cw, variable x)

	return (SpherocylinderX(cw, x))
End

Function ConvexLensX_(WAVE cw, variable x)

	return (ConvexLensX(cw, x))
End

Function DumbbellX_(WAVE cw, variable x)

	return (DumbbellX(cw, x))
End

Function CappedCylinderX_(WAVE cw, variable x)

	return (CappedCylinderX(cw, x))
End

Function BarbellX_(WAVE cw, variable x)

	return (BarbellX(cw, x))
End

Function Lamellar_ParaCrystalX_(WAVE cw, variable x)

	return (Lamellar_ParaCrystalX(cw, x))
End

Function BCC_ParaCrystalX_(WAVE cw, variable x)

	return (BCC_ParaCrystalX(cw, x))
End

Function FCC_ParaCrystalX_(WAVE cw, variable x)

	return (FCC_ParaCrystalX(cw, x))
End

Function SC_ParaCrystalX_(WAVE cw, variable x)

	return (SC_ParaCrystalX(cw, x))
End

Function OneShellX_(WAVE cw, variable x)

	return (OneShellX(cw, x))
End

Function TwoShellX_(WAVE cw, variable x)

	return (TwoShellX(cw, x))
End

Function ThreeShellX_(WAVE cw, variable x)

	return (ThreeShellX(cw, x))
End

Function FourShellX_(WAVE cw, variable x)

	return (FourShellX(cw, x))
End

Function PolyOneShellX_(WAVE cw, variable x)

	return (PolyOneShellX(cw, x))
End

Function PolyTwoShellX_(WAVE cw, variable x)

	return (PolyTwoShellX(cw, x))
End

Function PolyThreeShellX_(WAVE cw, variable x)

	return (PolyThreeShellX(cw, x))
End

Function PolyFourShellX_(WAVE cw, variable x)

	return (PolyFourShellX(cw, x))
End

Function BroadPeakX_(WAVE cw, variable x)

	return (BroadPeakX(cw, x))
End

Function CorrLengthX_(WAVE cw, variable x)

	return (CorrLengthX(cw, x))
End

Function TwoLorentzianX_(WAVE cw, variable x)

	return (TwoLorentzianX(cw, x))
End

Function TwoPowerLawX_(WAVE cw, variable x)

	return (TwoPowerLawX(cw, x))
End

Function PolyGaussCoilX_(WAVE cw, variable x)

	return (PolyGaussCoilX(cw, x))
End

Function GaussLorentzGelX_(WAVE cw, variable x)

	return (GaussLorentzGelX(cw, x))
End

Function GaussianShellX_(WAVE cw, variable x)

	return (GaussianShellX(cw, x))
End

Function FuzzySpheresX_(WAVE cw, variable x)

	return (FuzzySpheresX(cw, x))
End

Function PolyCoreBicelleX_(WAVE cw, variable x)

	return (PolyCoreBicelleX(cw, x))
End

Function CSParallelepipedX_(WAVE cw, variable x)

	return (CSParallelepipedX(cw, x))
End

//Function OneYukawaX_(cw,x)
//	Wave cw
//	Variable x
//	return(OneYukawaX(cw,x))
//End

//Function TwoYukawaX_(cw,x)
//	Wave cw
//	Variable x
//	return(TwoYukawaX(cw,x))
//End

