#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


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


Function MultiShellSphereX_(cw,x)
	Wave cw
	Variable x
	return(MultiShellSphereX(cw,x))
End

Function PolyMultiShellX_(cw,x)
	Wave cw
	Variable x
	return(PolyMultiShellX(cw,x))
End

Function SphereFormX_(cw,x)
	Wave cw
	Variable x
	return(SphereFormX(cw,x))
End

Function CoreShellSphereX_(cw,x)
	Wave cw
	Variable x
	return(CoreShellSphereX(cw,x))
End

Function PolyCoreFormX_(cw,x)
	Wave cw
	Variable x
	return(PolyCoreFormX(cw,x))
End

Function PolyCoreShellRatioX_(cw,x)
	Wave cw
	Variable x
	return(PolyCoreShellRatioX(cw,x))
End

Function VesicleFormX_(cw,x)
	Wave cw
	Variable x
	return(VesicleFormX(cw,x))
End

Function SchulzSpheresX_(cw,x)
	Wave cw
	Variable x
	return(SchulzSpheresX(cw,x))
End

Function PolyRectSpheresX_(cw,x)
	Wave cw
	Variable x
	return(PolyRectSpheresX(cw,x))
End

Function PolyHardSpheresX_(cw,x)
	Wave cw
	Variable x
	return(PolyHardSpheresX(cw,x))
End

Function BimodalSchulzSpheresX_(cw,x)
	Wave cw
	Variable x
	return(BimodalSchulzSpheresX(cw,x))
End

Function GaussSpheresX_(cw,x)
	Wave cw
	Variable x
	return(GaussSpheresX(cw,x))
End

Function LogNormalSphereX_(cw,x)
	Wave cw
	Variable x
	return(LogNormalSphereX(cw,x))
End

Function BinaryHSX_(cw,x)
	Wave cw
	Variable x
	return(BinaryHSX(cw,x))
End

Function BinaryHS_PSF11X_(cw,x)
	Wave cw
	Variable x
	return(BinaryHS_PSF11X(cw,x))
End

Function BinaryHS_PSF12X_(cw,x)
	Wave cw
	Variable x
	return(BinaryHS_PSF12X(cw,x))
End

Function BinaryHS_PSF22X_(cw,x)
	Wave cw
	Variable x
	return(BinaryHS_PSF22X(cw,x))
End

Function CylinderFormX_(cw,x)
	Wave cw
	Variable x
	return(CylinderFormX(cw,x))
End

Function EllipCyl76X_(cw,x)
	Wave cw
	Variable x
	return(EllipCyl76X(cw,x))
End

Function EllipticalCylinderX_(cw,x)
	Wave cw
	Variable x
	return(EllipticalCylinderX(cw,x))
End

Function TriaxialEllipsoidX_(cw,x)
	Wave cw
	Variable x
	return(TriaxialEllipsoidX(cw,x))
End

Function ParallelepipedX_(cw,x)
	Wave cw
	Variable x
	return(ParallelepipedX(cw,x))
End

Function HollowCylinderX_(cw,x)
	Wave cw
	Variable x
	return(HollowCylinderX(cw,x))
End

Function EllipsoidFormX_(cw,x)
	Wave cw
	Variable x
	return(EllipsoidFormX(cw,x))
End

Function Cyl_PolyRadiusX_(cw,x)
	Wave cw
	Variable x
	return(Cyl_PolyRadiusX(cw,x))
End

Function Cyl_PolyLengthX_(cw,x)
	Wave cw
	Variable x
	return(Cyl_PolyLengthX(cw,x))
End

Function CoreShellCylinderX_(cw,x)
	Wave cw
	Variable x
	return(CoreShellCylinderX(cw,x))
End

Function OblateFormX_(cw,x)
	Wave cw
	Variable x
	return(OblateFormX(cw,x))
End

Function ProlateFormX_(cw,x)
	Wave cw
	Variable x
	return(ProlateFormX(cw,x))
End

Function FlexExclVolCylX_(cw,x)
	Wave cw
	Variable x
	return(FlexExclVolCylX(cw,x))
End

Function FlexCyl_PolyLenX_(cw,x)
	Wave cw
	Variable x
	return(FlexCyl_PolyLenX(cw,x))
End

Function FlexCyl_PolyRadX_(cw,x)
	Wave cw
	Variable x
	return(FlexCyl_PolyRadX(cw,x))
End

Function FlexCyl_EllipX_(cw,x)
	Wave cw
	Variable x
	return(FlexCyl_EllipX(cw,x))
End

Function PolyCoShCylinderX_(cw,x)
	Wave cw
	Variable x
	return(PolyCoShCylinderX(cw,x))
End

Function StackedDiscsX_(cw,x)
	Wave cw
	Variable x
	return(StackedDiscsX(cw,x))
End

Function LamellarFFX_(cw,x)
	Wave cw
	Variable x
	return(LamellarFFX(cw,x))
End

Function LamellarFF_HGX_(cw,x)
	Wave cw
	Variable x
	return(LamellarFF_HGX(cw,x))
End

Function LamellarPSX_(cw,x)
	Wave cw
	Variable x
	return(LamellarPSX(cw,x))
End

Function LamellarPS_HGX_(cw,x)
	Wave cw
	Variable x
	return(LamellarPS_HGX(cw,x))
End

Function TeubnerStreyModelX_(cw,x)
	Wave cw
	Variable x
	return(TeubnerStreyModelX(cw,x))
End

Function Power_Law_ModelX_(cw,x)
	Wave cw
	Variable x
	return(Power_Law_ModelX(cw,x))
End

Function Peak_Lorentz_ModelX_(cw,x)
	Wave cw
	Variable x
	return(Peak_Lorentz_ModelX(cw,x))
End

Function Peak_Gauss_ModelX_(cw,x)
	Wave cw
	Variable x
	return(Peak_Gauss_ModelX(cw,x))
End

Function Lorentz_ModelX_(cw,x)
	Wave cw
	Variable x
	return(Lorentz_ModelX(cw,x))
End

Function FractalX_(cw,x)
	Wave cw
	Variable x
	return(FractalX(cw,x))
End

Function DAB_ModelX_(cw,x)
	Wave cw
	Variable x
	return(DAB_ModelX(cw,x))
End

Function OneLevelX_(cw,x)
	Wave cw
	Variable x
	return(OneLevelX(cw,x))
End

Function TwoLevelX_(cw,x)
	Wave cw
	Variable x
	return(TwoLevelX(cw,x))
End

Function ThreeLevelX_(cw,x)
	Wave cw
	Variable x
	return(ThreeLevelX(cw,x))
End

Function FourLevelX_(cw,x)
	Wave cw
	Variable x
	return(FourLevelX(cw,x))
End

Function HardSphereStructX_(cw,x)
	Wave cw
	Variable x
	return(HardSphereStructX(cw,x))
End

Function SquareWellStructX_(cw,x)
	Wave cw
	Variable x
	return(SquareWellStructX(cw,x))
End

Function StickyHS_StructX_(cw,x)
	Wave cw
	Variable x
	return(StickyHS_StructX(cw,x))
End

Function HayterPenfoldMSAX_(cw,x)
	Wave cw
	Variable x
	return(HayterPenfoldMSAX(cw,x))
End

//Function SmearedCyl_PolyRadiusX_(cw,x)
//	Wave cw
//	Variable x
//	return(SmearedCyl_PolyRadiusX(cw,x))
//End

Function SpherocylinderX_(cw,x)
	Wave cw
	Variable x
	return(SpherocylinderX(cw,x))
End

Function ConvexLensX_(cw,x)
	Wave cw
	Variable x
	return(ConvexLensX(cw,x))
End

Function DumbbellX_(cw,x)
	Wave cw
	Variable x
	return(DumbbellX(cw,x))
End

Function CappedCylinderX_(cw,x)
	Wave cw
	Variable x
	return(CappedCylinderX(cw,x))
End

Function BarbellX_(cw,x)
	Wave cw
	Variable x
	return(BarbellX(cw,x))
End

Function Lamellar_ParaCrystalX_(cw,x)
	Wave cw
	Variable x
	return(Lamellar_ParaCrystalX(cw,x))
End

Function BCC_ParaCrystalX_(cw,x)
	Wave cw
	Variable x
	return(BCC_ParaCrystalX(cw,x))
End

Function FCC_ParaCrystalX_(cw,x)
	Wave cw
	Variable x
	return(FCC_ParaCrystalX(cw,x))
End

Function SC_ParaCrystalX_(cw,x)
	Wave cw
	Variable x
	return(SC_ParaCrystalX(cw,x))
End

Function OneShellX_(cw,x)
	Wave cw
	Variable x
	return(OneShellX(cw,x))
End

Function TwoShellX_(cw,x)
	Wave cw
	Variable x
	return(TwoShellX(cw,x))
End

Function ThreeShellX_(cw,x)
	Wave cw
	Variable x
	return(ThreeShellX(cw,x))
End

Function FourShellX_(cw,x)
	Wave cw
	Variable x
	return(FourShellX(cw,x))
End

Function PolyOneShellX_(cw,x)
	Wave cw
	Variable x
	return(PolyOneShellX(cw,x))
End

Function PolyTwoShellX_(cw,x)
	Wave cw
	Variable x
	return(PolyTwoShellX(cw,x))
End

Function PolyThreeShellX_(cw,x)
	Wave cw
	Variable x
	return(PolyThreeShellX(cw,x))
End

Function PolyFourShellX_(cw,x)
	Wave cw
	Variable x
	return(PolyFourShellX(cw,x))
End

Function BroadPeakX_(cw,x)
	Wave cw
	Variable x
	return(BroadPeakX(cw,x))
End

Function CorrLengthX_(cw,x)
	Wave cw
	Variable x
	return(CorrLengthX(cw,x))
End

Function TwoLorentzianX_(cw,x)
	Wave cw
	Variable x
	return(TwoLorentzianX(cw,x))
End

Function TwoPowerLawX_(cw,x)
	Wave cw
	Variable x
	return(TwoPowerLawX(cw,x))
End

Function PolyGaussCoilX_(cw,x)
	Wave cw
	Variable x
	return(PolyGaussCoilX(cw,x))
End

Function GaussLorentzGelX_(cw,x)
	Wave cw
	Variable x
	return(GaussLorentzGelX(cw,x))
End

Function GaussianShellX_(cw,x)
	Wave cw
	Variable x
	return(GaussianShellX(cw,x))
End

Function FuzzySpheresX_(cw,x)
	Wave cw
	Variable x
	return(FuzzySpheresX(cw,x))
End

Function PolyCoreBicelleX_(cw,x)
	Wave cw
	Variable x
	return(PolyCoreBicelleX(cw,x))
End

Function CSParallelepipedX_(cw,x)
	Wave cw
	Variable x
	return(CSParallelepipedX(cw,x))
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

