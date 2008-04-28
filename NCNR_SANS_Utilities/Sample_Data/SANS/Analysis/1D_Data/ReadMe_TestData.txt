ReadMe_TestData.txt
AUG 2006

This folder contains test data for each of the analysis packages. There is some SANS and USANS data, some synthetic, and some actual experimental data. Working with each of these data sets will help you become familiar with the various analysis techniques.

*********************
CMSpheres Data files:
*********************This is a synthetic set of data to represent a contrast variation series, used to find the contrast match point for particles.

Your question for the data sets is - what are the Radius, polydispersity, and SLD of the spheres?

- The model used is spheres with a Schulz polydispersity
- The data sets include resolution effects
- The SLD of the particles is a typical value for amorphous silica
- The volume fraction for each set is the same, 0.01
- The SLD and background for each set are:
	CMSphere1:	1e-6	1
	CMSphere2:	2e-6	0.8
	CMSphere3:	3.3e-6	0.5
	CMSphere4:	4e-6	0.4
	CMSphere5:	5e-6	0.2

This provides a somewhat realistic simulation of a real set of data - where you would make up the samples at identical volume fractions, they would have a background level corresponding to the H2O/D2O content of the solvent. An "ideal" measurement would not just be at low Q, but go to higher Q to accurately measure the incoherent background level. Failing to subtract the incoherent level will cause significant errors in I(q=0). For this test data, I have provided the values that I added to create the data sets. You can either input these background values as "known" values, or leave them free to see what effect this has on your results.

CMSpheres.jpg shows a plot of the data and the answer - the radius, polydispersity, and SLD of the silica that was used to synthesize the test data.


********************
Cylinder.txt
********************

This is synthesized data for a cylindrical particle. It has two regions where it can be fit with a Guinier approximation. Use the linearized fitting to find the Rg of the particle as a whole, and the Rg of the cross-section of the cylinder. (The Guinier approximation for the cross-section is different than the overall particle. Go look it up in Glatter & Kratky). Compare your Rg values to the real particle dimensions shown in Cylinder.jpg.


**********************************
Latex_SANS.abs and Latex_USANS.cor
**********************************

This is experimental data from the NCNR summer school in 2004. A latex dispersion in (mostly) D2O was measured on SANS and USANS. The volume fraction is approx. 0.5%, and the contrast is close to 6e-6 (A^-2). Fit each of the data sets individually with a polydisperse hard sphere model, and then try a global fit, using the information from the individual fits. The radius, polydispersity, contrast, and volume fraction are the same (global) for both data sets. There may be some difference in the absolute scaling of SANS and USANS data, so let the contrast vary for each set. Any variation found is the difference in scaling, not contrast, since the contrast is not changing (the neutrons are the same, and the sample is the same). The background will be different for each data set as well.

You will find that the radius is poorly determined by the SANS data - and is not surprising by simply looking at each data set. The USANS is much more rich with features. 

You should get a very good fit like shown in Latex_GlobalFit.jpg, with a radius of about 2310 A and a polydispersity of 0.053.


*******************************
PolyCoreS.txt and PolyCoreU.txt
*******************************

These are synthesized data sets, one (S) for SANS, and one (U) for USANS. They are for a polydisperse sphere with a core-shell structure. The contrast is such that the core and solvent SLD's are the same, 6e-6 (A^-2). The scattering is like what is seen from a unilamelar vesicle. The volume fraction (scale) is 0.01. Fit each of the data sets individually with a polydisperse core-shell model, and then try a global fit, using the information from the individual fits. The radii, shell thickness, polydispersity, contrast, and volume fraction are the same (global) for both data sets. There may be some difference in the absolute scaling of SANS and USANS data, so you can let the scale factor vary for each set. Any variation found is the difference in scaling, not concentration. The background will be different for each data set as well.

You should obtain values similar to the nominal values shown in PolyCoreUS.jpg. Random errors have been added to the simulated intensity, so your fitted values won't be exactly the same.


***************
PolySpheres.txt
***************

This is test data for using the invariant to determine the volume fraction of particles. In this case, the scattering is from polydisperse spheres with a known contrast (2e-6 A^-2). The radius is unknown, and the volume fraction is unknown. Use the invariant calculator to calculate the invariant for the measured data, and extrapolate to find the corrections to the invariant, and how significant the corrections contribute to the total invariant. Finally, calculate the volume fraction of spheres. Compare to the model value shown in PolySpheres.jpg


***************
SummedModel.txt
***************

This is test data for a system with two different structures. The scattering can be approximated as a linear combination of two models. In this case, a Debye function and a Gaussian peak. Use the Sum Models package to create a summed model, and then fit it to the data. It may be useful to fit subsections of the data to the individual models, or Guinier fits, to get reasonable estimates for the parameters for each model. Fit the data to your summed model, and compare the results to what was used to generate the data in SumData.jpg.

***************
SmallSphere.txt
***************

More synthetic data that incorporates instrumental resolution. Fit the data to a model of spheres, using the sphere model, and then the smeared version. Compare the quality of fits, both visually and the numerical values for Chi-squared. Then compare to the original parameters in SmallSphere.jpg.


***************
