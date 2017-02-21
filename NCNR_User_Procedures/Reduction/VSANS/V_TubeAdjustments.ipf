#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// functions for testing and then actually applying the nonlinear corrections to the
// tube detectors. These routines are for a test bank of 8 tubes (vertical) that were
// run at a subdivision of 1024. VSANS will be different in practice
//
// but the fundamental process is the same, and can be translated into proper functions as needed
//



// the main routines are:

//(1)
//to get from individual tubes to an array
//	Tubes_to_Array()			

//(2)
// then to locate all of the peak positions
//	MakeTableForPeaks(numTube,numPeak)		
//	Identify_AllPeaks()
//		AutoFindPeaksCustom()		// if Identify_AllPeaks  doesn't work -try this, setting the "noise" to 1 and smoothing to 2

//(3)
// fit to find all of the quadratic coefficients
//	MakeTableForFitCoefs(numTube,numCoef)
//	PlotFit_AllPeaks()


//(4)
// then pick a display method
//
//	Make_mm_tubes()
//	Append_Adjusted_mm()
//
//	MakeMatrix_PixCenter()
//	FillMatrix_Pix_Center(ind)
//
//
// -or- (note that the pack_image wave that is generated here is for display ONLY)
// --since it is interpolated
//
// Interpolate_mm_tubes()


// The function most used externally is:
// V_TubePix_to_mm(c0,c1,c2,pix)
//
// which will return the real space distance (in mm?) for a given pixel
// and the tube's coefficients. The distance is relative to the zero position on the
// detector (which was defined when the coefficients were determined)







// (0) -- what I start with:
// -- a table of the mm spacing of the slots (20 of them)
// -- masked data from each of the (8) tubes
// -- the table of slots may need to be corrected for parallax, depending on the geometry of the test
// ** In the table of slots, pick a slot near the center, and SET that to ZERO. Then all of the other
//   distances are relative to that zero point. This is a necessary reference point.
//


// (1) -- get the individual tubes into an array
//
//
Proc V_Tubes_to_Array()
	Make/O/D/N=(8,1127) pack
	edit pack
	display;appendimage pack
	pack[0][] = tube1[q]
	pack[1][] = tube2[q]
	pack[2][] = tube3[q]
	pack[3][] = tube4[q]
	pack[4][] = tube5[q]
	pack[5][] = tube6[q]
	pack[6][] = tube7[q]
	pack[7][] = tube8[q]
	ModifyImage pack ctab= {*,*,ColdWarm,0}
End

// (2) -- for each of the tubes, find the x-position (in pixels) of each of the (20) peaks
// -- load the Analysis Package "MultiPeakFit 2"
//
// automatically find the peaks (after including MultiPeakFit 2)
//		AutomaticallyFindPeaks()
//
//-- or if having difficulty
//		AutoFindPeaksCustom()		// try this, setting the "noise" to 1 and smoothing to 2
//
// -- if really having difficulty, you can do the "full" MultiPeak Fit
//
// -- If (hopefully) using the easy way, the results are in:
// root:WA_PeakCentersY,root:WA_PeakCentersX
//
// -- so to see the results:
//¥Edit/K=0  root:WA_PeakCentersY,root:WA_PeakCentersX
// 
// -- then sort the results - they seem to be in no real order...
//¥Sort WA_PeakCentersX WA_PeakCentersY,WA_PeakCentersX
//
Proc V_MakeTableForPeaks(numTube,numPeak)
	Variable numTube,numPeak
	
	Make/O/D/N=(numPeak,numTube) PeakTableX,peakTableY		//*2 to store x-location and peak height (y)
	Edit peakTableX
End

Proc V_Identify_AllPeaks()

	Variable ii,numTubes=8
	String str="tube"
	
	ii=1
	do
		V_Identify_Peaks(str+num2str(ii),ii-1)
		ii+=1
	while(ii<=numTubes)

End

Proc V_Identify_Peaks(tubeStr,ind)
	String tubeStr
	Variable ind
	
	// must use a wave of pixels rather than "calculated" -- if calculated is used it only
	// returns integer values for the peak locations
	
//	AutomaticallyFindPeaks() //-- this is a function that doesn't take any parameters - so 
// I need to pull this from the WM function to call the worker directly
	Variable pBegin=0, pEnd= numpnts($(tubeStr))-1
	Variable/C estimates= EstPeakNoiseAndSmfact($(tubeStr),pBegin, pEnd)
	Variable noiselevel=real(estimates)
	Variable smoothingFactor=imag(estimates)
	Variable maxPeaks = 20
	Variable minPeakPercent = 10
	
	AutoFindPeaksWorker($(tubeStr), $("tube_pixel"), pBegin, pEnd, maxPeaks, minPeakPercent, noiseLevel, smoothingFactor)
// end WM function call

	Sort WA_PeakCentersX WA_PeakCentersY,WA_PeakCentersX
	
	peakTableX[][ind] = WA_PeakCentersX[p]
	peakTableY[][ind] = WA_PeakCentersY[p]
	
End

// -- save a copy of the root:WA_PeakCentersY,root:WA_PeakCentersX values
//    for later in case the fitting failed, then you can go back and re-do
//
// -- then plot:
//
//	Display peak_spacing_mm_ctr vs WA_PeakCentersX
//
//	Then do a "QuickFit" of the peak position to the data using a polynomial of order 3 (= quadratic)
//
// result is in W_coef, W_sigma
//
// -- an example of the "quickFit" command is below, so it can be programmed rather than the menu every time
//¥Display peak_spacing_mm_ctr vs WA_PeakCentersX3
//¥CurveFit/M=2/W=0/TBOX=(0x310) poly 3, peak_spacing_mm_ctr/X=WA_PeakCentersX3/D
//  fit_peak_spacing_mm_ctr= poly(W_coef,x)
//  W_coef={-571.42,1.1135,-4.2444e-05}
//  V_chisq= 8.5841;V_npnts= 20;V_numNaNs= 0;V_numINFs= 0;
//  V_startRow= 0;V_endRow= 19;
//  W_sigma={0.595,0.00246,2.15e-06}
//  Coefficient values ± one standard deviation
//  	K0	=-571.42 ± 0.595
//  	K1	=1.1135 ± 0.00246
//  	K2	=-4.2444e-05 ± 2.15e-06
//
//
//
// for (8) tubes, keep all of the fit coefficients
//
//¥make/O/D/N=(3,8) fit_coef
//¥edit fit_coef
//¥make/O/D/N=(3,8) fit_sigma
//¥edit fit_sigma
//
// -- copy and paste in the W_coef and W_sigma values (or by a command)
//


Proc V_MakeTableForFitCoefs(numTube,numCoef)
	Variable numTube,numCoef
	
	Make/O/D/N=(numCoef,numTube) TubeCoefTable,TubeSigmaTable		//
	Edit TubeCoefTable
End

Proc V_PlotFit_AllPeaks()

	Variable ii,numTubes=8
	
	ii=1
	do
		V_PlotFit_Peaks(ii-1)
		ii+=1
	while(ii<=numTubes)

End

Proc V_PlotFit_Peaks(ind)
	Variable ind
	
	//hopefully 20 points - need better control of this
	Duplicate/O WA_PeakCentersX, tmpX
	
	tmpX = peakTableX[p][ind]
	Display peak_spacing_mm_ctr vs tmpX
	
	CurveFit/M=2/W=0/TBOX=(0x310) poly 3, peak_spacing_mm_ctr/X=tmpX/D
	
	TubeCoefTable[][ind] = W_coef[p]
	TubeSigmaTable[][ind] = W_sigma[p]
	
End





//¥Duplicate tube1 tube1_mm
//¥tube1_mm = V_TubePix_to_mm(fit_coef[0][0],fit_coef[1][0],fit_coef[2][0],p)




////////
// then there are various display options:

// adjust the center (pixel) of the tube:
// - measCtr is the pixel location of the DEFINED "zero" peak
// nominal Ctr is the pixel number of this DEFINED zer0 position, nominally nPix/2-1
//
// ( be sure to pick better names, and use a loop...)
//	adj_tube = raw_tube[p+(measCtr-nominalCtr)]
//
// then fill and display a new matrix. The center will be reasonably well aligned, and will
// get worse towards the ends of the tubes
// (this may be the "preferred" way of displaying the raw data if the centers are far off)
// -- this also may be what I need to start with to fit the data to locate the beam center.


// I can also display the fully corrected tubes, where the y-axis is now in real-space mm
// rather than arbitrary pixels. The x-axis is still tube nubmer.
// -- do this with the procedure"
//   Append_Adjusted_mm()		// name may change...
//
// -- the point of the appending is that it allows each tube to be plotted on an image plot
// with its own y-axis. Every one will be different and will be non-linear. These conditions
// BOTH prevent using any of the "normal" image plotting or manipulation routines.
// - the gist is below:
//
//	duplicate tube1_mm adjusted_mm_edge
//	InsertPoints 0,1, adjusted_mm_edge
//	// be sure to use the correct set of coefficients
//	adjusted_mm_edge[0] = V_TubePix_to_mm(fit_coef[0][0],fit_coef[1][0],fit_coef[2][0],-1)
//	
//	Display;AppendImage adjusted_pack vs {*,adjusted_mm_edge}


Proc V_Make_mm_tubes()

	Variable ii,numTubes=8
	
	ii=1
	do
		Duplicate $("tube"+num2str(ii)) $("tube"+num2str(ii)+"_mm")
		$("tube"+num2str(ii)+"_mm") = V_TubePix_to_mm(TubeCoefTable[0][ii-1],TubeCoefTable[1][ii-1],TubeCoefTable[2][ii-1],p)
		ii+=1
	while(ii<=numTubes)
	
End


Proc V_Append_Adjusted_mm()

// a blank base image
	Duplicate/O pack junk
	junk=0
	SetScale/I y -600,600,"", junk		// -600,600 is tooo large and not general
	Display;Appendimage junk

	Variable ii
	
	ii=1
	do
		make/O/D/N=(1,1127) $("tube"+num2str(ii)+"_mm_mat")=0	
	
		$("tube"+num2str(ii)+"_mm_mat")[0][] = $("tube"+num2str(ii))
		SetScale/I x (ii-1),ii,"", $("tube"+num2str(ii)+"_mm_mat")		//builds up the x-axis
		
		duplicate/O $("tube"+num2str(ii)+"_mm") $("edge"+num2str(ii)+"_mm")
		InsertPoints 0,1, $("edge"+num2str(ii)+"_mm")		//needs to be one point longer
	// be sure to use the correct set of coefficients
		$("edge"+num2str(ii)+"_mm")[0] = V_TubePix_to_mm(TubeCoefTable[0][0],TubeCoefTable[1][0],TubeCoefTable[2][0],-1)
	
		AppendImage $("tube"+num2str(ii)+"_mm_mat") vs {*,$("edge"+num2str(ii)+"_mm")}
		ModifyImage $("tube"+num2str(ii)+"_mm_mat") ctab= {*,*,ColdWarm,0}
	
		ii+=1
	while(ii < 9)
	
end



////////////////////////////////

Proc V_MakeMatrix_PixCenter()
	Duplicate/O pack pack_centered
	
	Variable ii,numTubes=8
	
	ii=1
	do
		V_FillMatrix_Pix_Center(ii)
		ii+=1
	while(ii<=numTubes)
	
	Display;AppendImage pack_centered
	ModifyImage pack_centered ctab= {*,*,ColdWarm,0}

end

//
// this fills a matrix with the tubes center aligned ONLY, with the y-axis in pixels
//
// adj_tube = raw_tube[p+(measCtr-nominalCtr)]
// finds the center automatically from the tubeN_mm wave, where it crosses zero
//
// Tube #1 is the "base" ans others are shifted to match that one's "zero"
//
// FindRoots/P=W_coef		can also be used to find the roots (but which one?)
//
Function V_FillMatrix_Pix_Center(ind)
	Variable ind
	
	Wave adj=root:pack_centered
	Wave tube1_mm = $("root:tube1_mm")
	Wave tube = $("root:tube"+num2str(ind))
	wave tube_mm = $("root:tube"+num2str(ind)+"_mm")

	Variable base,shift,ii,num,pt
	
	num=numpnts(tube)
	
	FindLevel tube1_mm 0
	base = round(V_LevelX)
	
	
	FindLevel tube_mm 0
	shift = round(V_LevelX)
	
	for(ii=0;ii<num;ii+=1)
		pt = ii + (shift-base)
		if(pt >= 0 && pt < num)
			adj[ind-1][ii] = tube[pt]
		endif
	endfor
	
	return(0)
End


// this fills a matrix with the tubes center aligned ONLY, with the y-axis in mm
// -- there seems to be little reason to do this --
// -- either keep pixels and align centers
// -- OR -- use mm and append each tube with its own y-axis
//
Function V_FillAdjusted(ind)
	Variable ind
	
	Wave adj=root:adjusted_pack
	Wave tube1_mm
	Wave tube = $("root:tube"+num2str(ind))
	wave tube_mm = $("root:tube"+num2str(ind)+"_mm")

	Variable base,shift,ii,num,pt
	
	num=numpnts(tube1_mm)
	
	FindLevel tube1_mm 0
	base = round(V_LevelX)
	
	
	FindLevel tube_mm 0
	shift = round(V_LevelX)
	
	for(ii=0;ii<num;ii+=1)
		pt = ii + (shift-base)
		if(pt >= 0 && pt < num)
			adj[ind-1][ii] = tube[pt]
		endif
	endfor
	
	return(0)
End


// c0,c1,c2,pix
// c0-c2 are the fit coefficients
// pix is the test pixel
//
// returns the distance in mm (relative to ctr pixel)
// ctr is the center pixel, as defined when fitting to quadratic
//
Function V_TubePix_to_mm(c0,c1,c2,pix)
	Variable c0,c1,c2,pix
	
	Variable dist
	dist = c0 + c1*pix + c2*pix*pix
	
	return(dist)
End

////



// set the (linear) range of the y-axis of the matrix to be the
// range of the 1st tube. This is completely arbitrary
//
Proc V_Interpolate_mm_tubes()

	Duplicate/O pack pack_image

	Variable ii,numTubes=8
	Variable p1,p2
	p1 = tube1_mm[0]
	p2 = tube1_mm[numpnts(tube1_mm)-1]
	
	SetScale/I y p1,p2,"", pack_image
	
	// then make a temporary 1D wave to help with the interpolation
	Duplicate/O tube1_mm lin_mm,lin_val
	SetScale/I x p1,p2,"", lin_mm
	lin_mm = x			//fill with the linear mm spacing
	lin_val=0
	
	ii=1
	do
		lin_val = interp(lin_mm, $("tube"+num2str(ii)+"_mm"), $("tube"+num2str(ii)))
		pack_image[ii-1][] = lin_val[q]
		
		ii+=1
	while(ii<=numTubes)
	
	display;appendimage pack_image
	ModifyImage pack_image ctab= {*,*,ColdWarm,0}
	
End













// this doesn't work - the interpolation step doesn't do what I want
// and the plot of the triplet with f(z) for color doesn't fill space like I want
Proc V_AnotherExample()

	Concatenate/O/NP {tube1_mm,tube2_mm,tube3_mm,tube4_mm,tube5_mm,tube6_mm,tube7_mm,tube8_mm},cat_mm
	Concatenate/O/NP {tube1,tube2,tube3,tube4,tube5,tube6,tube7,tube8},cat_tubes
	Duplicate/O cat_mm,cat_num
	Variable num=1127
	cat_num[0,num-1]=1
	cat_num[num,2*num-1]=2
	cat_num[2*num,3*num-1]=3
	cat_num[3*num,4*num-1]=4
	cat_num[4*num,5*num-1]=5
	cat_num[5*num,6*num-1]=6
	cat_num[6*num,7*num-1]=7
	cat_num[7*num,8*num-1]=8

	Display cat_mm vs cat_num
	ModifyGraph mode=3,marker=9
	ModifyGraph zColor(cat_mm)={cat_tubes,*,*,ColdWarm,0}

	Concatenate/O {cat_num,cat_mm,cat_tubes}, tripletWave
	ImageInterpolate Kriging tripletWave
	AppendImage M_InterpolatedImage

//	Make/O/N=20 xWave=enoise(4),yWave=enoise(5),zWave=enoise(6)  // Random points
//	Display yWave vs xWave
//	ModifyGraph mode=3,marker=19
//	ModifyGraph zColor(yWave)={zWave,*,*,Rainbow,0}
//
//	Concatenate/O {xWave,yWave,zWave}, tripletWave
//	ImageInterpolate/S={-5,0.1,5,-5,0.1,5} voronoi tripletWave
//	AppendImage M_InterpolatedImage

end

// this desn't work either...
// (same y-axis for the entire image, which is not the case for the tubes)
//
// from the WM help file:
// Plotting a 2D Z Wave With 1D X and Y Center Data
//
Function V_MakeEdgesWave(centers, edgesWave)
	Wave centers	// Input
	Wave edgesWave	// Receives output
	
	Variable N=numpnts(centers)
	Redimension/N=(N+1) edgesWave

	edgesWave[0]=centers[0]-0.5*(centers[1]-centers[0])
	edgesWave[N]=centers[N-1]+0.5*(centers[N-1]-centers[N-2])
	edgesWave[1,N-1]=centers[p]-0.5*(centers[p]-centers[p-1])
End

//This function demonstrates the use of MakeEdgesWave:
Function V_DemoPlotXYZAsImage()
	Make/O mat={{0,1,2},{2,3,4},{3,4,5}}	// Matrix containing Z values
	Make/O centersX = {1, 2.5, 5}		// X centers wave
	Make/O centersY = {300, 400, 600}		// Y centers wave
	Make/O edgesX; V_MakeEdgesWave(centersX, edgesX)	// Create X edges wave
	Make/O edgesY; V_MakeEdgesWave(centersY, edgesY)	// Create Y edges wave
	Display; AppendImage mat vs {edgesX,edgesY}
End

