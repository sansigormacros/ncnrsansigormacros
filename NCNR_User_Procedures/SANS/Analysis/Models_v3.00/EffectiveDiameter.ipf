#pragma rtGlobals=1		// Use modern global access method.

// these routines are used to calculate an effective spherical diameter for
// a non-spherical object, either a cylinder or an  ellipsoid
//
// the functions calculate the 2nd virial coefficient for the non-spherical
// object, then find the diameter of sphere that has this value of virial
// coefficient
//
// - so the calculation at least has some thermodynamic basis, rather than
// some simplistic volume correction
//

//prolate OR oblate ellipsoids
//aa is the axis of rotation
//if aa>bb, then PROLATE
//if aa<bb, then OBLATE
// A. Isihara, J. Chem. Phys. 18, 1446 (1950)
//returns DIAMETER

Function DiamEllip(aa,bb)
	Variable aa,bb
	
	Variable ee,e1,bd,b1,bL,b2,del,ddd,diam
	
	if(aa>bb)
		ee = (aa^2 - bb^2)/aa^2
	else
		ee = (bb^2 - aa^2)/bb^2
	Endif
	
	bd = 1-ee
	e1 = sqrt(ee)
	b1 = 1 + asin(e1)/(e1*sqrt(bd))
	bL = (1+e1)/(1-e1)
	b2 = 1 + bd/2/e1*ln(bL)
	del = 0.75*b1*b2
	
	ddd = 2*(del+1)*aa*bb*bb		//volume is always calculated correctly
	diam = ddd^(1/3)
	
	return (diam)
End

//effective DIAMETER of a cylinder of total height hcyl and radius rcyl
//
Function DiamCyl(hcyl,rcyl)
	Variable hcyl,rcyl
	
	Variable diam,a,b,t1,t2,ddd
	
	a = rcyl
	b = hcyl/2
	t1 = a*a*2*b/2
	t2 = 1 + (b/a)*(1+a/b/2)*(1+pi*a/b/2)
	ddd = 3*t1*t2
	diam = ddd^(1/3)
	
	return (diam)
End