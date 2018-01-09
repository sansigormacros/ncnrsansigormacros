#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// functions for testing and then actually applying the nonlinear corrections to the
// tube detectors. These routines are for a test bank of 8 tubes (vertical) that were
// run at a subdivision of 1024. VSANS will be different in practice
//
// but the fundamental process is the same, and can be translated into proper functions as needed
//
//


//
// 
// x- need a way to generate the known, physical dimensions of the slots
// Make/O/D/N=5 peak_spacing_mm_ctr
// peak_spacing_mm_ctr = {-350,-190,0,190,350} (to be filled in with the correct measurements, 
//   possibly different for each panel)
//
// x- a 128 point wave "tube_pixel" (=p) is made in V_ArrayToTubes(), and is needed for the WM
//   procedures to identify the peak positions.
//
// x- fit with either gauss or lor function to get non-integer pixel values for the peak locations
//
// x- do I fit each individually to "tweak" the located values, or fit all 5 at once with a 
//    custom fit function and guess some good starting values for peak height, location, etc.
// 
//
// x- find a way to display all of the results - in a way that can quickly identify any fits
//    that may be incorrect
//
//



// the main routines are:

//(1)
//
// to get from an array to individual tubes
// V_ArrayToTubes(detector)
//
// (not needed) to get from individual tubes to an array
//	V_Tubes_to_Array()			

//(2)
// then to locate all of the peak positions
//	V_MakeTableForPeaks(numTube,numPeak)		
//	V_Identify_AllPeaks()
//		AutoFindPeaksCustom()		// if Identify_AllPeaks  doesn't work -try this, setting the "noise" to 1 and smoothing to 2

// (3) Refine the fitted peak positions
//

//(4)
// fit to find all of the quadratic coefficients
//	MakeTableForFitCoefs(numTube,numCoef)
//	PlotFit_AllPeaks()


//(5)
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



//
// (0) -- what I start with:
// -- a table of the mm spacing of the slots (20 of them)
// -- masked data from each of the (8) tubes
// -- the table of slots may need to be corrected for parallax, depending on the geometry of the test
// ** In the table of slots, pick a slot near the center, and SET that to ZERO. Then all of the other
//   distances are relative to that zero point. This is a necessary reference point.
//

// 
// x- need a routine to set up the actual measurements of the slot positions
//
//
// 
// x- the slot positioning is different for the L/R and T/B detectors
//
Proc V_SetupSlotDimensions()
	Make/O/D/N=5 peak_spacing_mm_ctr_TB,peak_spacing_mm_ctr_LR
	peak_spacing_mm_ctr_TB = {-159.54,-80.17,0,80.17,159.54}
	peak_spacing_mm_ctr_LR = {-379.4,-189.7,0,189.7,380.2}
	DoWindow/F Real_mm_Table
	if(V_Flag == 0)
		Edit/N=Real_mm_Table peak_spacing_mm_ctr_TB,peak_spacing_mm_ctr_LR
	endif
End



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

// or the other way around
// - get the array into individual tubes ready for fitting.
//
Proc V_ArrayToTubes(detStr)
	String detStr
//	Prompt wStr,"Select detector panel",popup,WaveList("data_*",";","")
	Prompt detStr,"Select detector panel",popup,ksDetectorListAll
	
	String/G root:detUsed = detStr
	
	Variable ii,numTubes=48
	String str="tube"
	
	Variable dim0,dim1
	
	detStr = "root:Packages:NIST:VSANS:RAW:entry:instrument:detector_"+detStr+":data"
	
	dim0 = DimSize($detStr,0)
	dim1 = DimSize($detStr,1)

	
	Make/O/D/N=128 tube_pixel
	tube_pixel = p
	
	
	ii=0
	do
		Make/O/D/N=128 $(str+num2str(ii))
		
		if(dim0 == 128)
			$(str+num2str(ii)) = $(detStr)[p][ii]
		else
			$(str+num2str(ii)) = $(detStr)[ii][p]
		endif
		
		ii+=1
	while(ii < numTubes)

End


// (2) -- for each of the tubes, find the x-position (in pixels) of each of the (20) peaks
// -- automatically loads the Analysis Package "MultiPeakFit 2"
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
	Variable numTube=48,numPeak=5
	
	Make/O/D/N=(numPeak,numTube) PeakTableX,PeakTableY		//*2 to store x-location and peak height (y)
	
	DoWindow/F Peak_Pixel_Loc
	if(V_flag == 0)
		Edit/N=Peak_Pixel_Loc peakTableX
	endif
	
	Execute/P "INSERTINCLUDE <Multi-peak fitting 2.0>"
	DoWindow/K MultiPeak2StarterPanel

//	DoAlert 0, "Load the Package: Analysis->MultiPeak Fitting->MultiPeak Fitting 2"
End

Proc V_Identify_AllPeaks()

	Variable ii,numTubes=48
	String str="tube"
	
	ii=0
	do
		V_Identify_Peaks(str+num2str(ii),ii)
		ii+=1
	while(ii < numTubes)

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
	
	peakTableX[][ind] = WA_PeakCentersX[p]		// the peak position
	peakTableY[][ind] = WA_PeakCentersY[p]		// the peak height
	
End




// ADD
// a step to refine the peak positioning - currently an integer value
//  fit with a gauss or lorentzian

// CurveFit/M=2/W=0/TBOX=(0x310) lor, tube47[29,53]/X=tube_pixel[29,53]/D

//CurveFit/M=2/W=0 lor, tube47[29,53]/X=tube_pixel[29,53]/D
//fit_tube47= W_coef[0]+W_coef[1]/((x-W_coef[2])^2+W_coef[3])
//W_coef={-20.37,876.94,40.078,0.5201}
//W_sigma={6.52,47.3,0.0241,0.0308}

Proc V_MakeTableForRefinedFit(numTube,numPeak)
	Variable numTube=48,numPeak=5
	
	Make/O/D/N=(numPeak,numTube) position_refined,position_refined_err		//
	
	DoWindow/F Refined_Positions
	if(V_flag == 0)
		Edit/N=Refined_Positions position_refined
	endif
	
End

Proc V_Refine_All_PeakPos()

	Variable ii,numTubes=48
	
	ii=0
	do
		V_Refine_PeakPos(ii)
		ii+=1
	while(ii<numTubes)

End


//CurveFit/M=2/W=0 lor, tube47[29,53]/X=tube_pixel[29,53]/D
//fit_tube47= W_coef[0]+W_coef[1]/((x-W_coef[2])^2+W_coef[3])

Proc V_Refine_PeakPos(ind)
	Variable ind
	
// 
// x- hard-wired for 5 peaks

	Variable ii,lo,hi
	
	
	ii=0
	do
	
		if(ii==0)
		// 1st peak
		// define fitting range pixels (integer)
			lo = 0
		else
			lo = trunc(0.5*(peakTableX[ii-1][ind] + peakTableX[ii][ind]))
		endif
		
		if(ii==4)
			hi = numpnts(tube_pixel)-1
		else
			hi = trunc(0.5*(peakTableX[ii][ind] + peakTableX[ii+1][ind]))
		endif
		
		// do I need initial guesses?
		CurveFit/M=0/W=2 lor, $("tube"+num2str(ind))[lo,hi]/X=tube_pixel[lo,hi]/D
		
		position_refined[ii][ind] = W_coef[2]
		position_refined_err[ii][ind] = W_sigma[2]

		ii += 1

	while(ii < 5)
	
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
	Variable numTube=48,numCoef=3
	
	Make/O/D/N=(numTube,numCoef) TubeCoefTable,TubeSigmaTable		//
	
	DoWindow/F Quad_Coefficients
	if(V_flag == 0)
		Edit/N=Quad_Coefficients TubeCoefTable
	endif

	String detUsed = root:detUsed
	
	if(strsearch(detUsed,"L",0) >= 0 || strsearch(detUsed,"R",0) >= 0)
		Duplicate/O 	peak_spacing_mm_ctr_LR, peak_spacing_mm_ctr
		DoAlert 0,"Using peak spacing for L/R"
	else
		Duplicate/O 	peak_spacing_mm_ctr_TB, peak_spacing_mm_ctr
		DoAlert 0,"Using peak spacing for T/B"
	endif
End

Proc V_PlotFit_AllPeakPosition()

	Variable ii,numTubes=48
	
	ii=0
	do
		V_PlotFit_PeakPosition(ii)
		ii+=1
	while(ii<numTubes)

End

Proc V_PlotFit_PeakPosition(ind)
	Variable ind
	
	Duplicate/O WA_PeakCentersX, tmpX
	
//	tmpX = peakTableX[p][ind]
	tmpX = position_refined[p][ind]
//	Display peak_spacing_mm_ctr vs tmpX
	
//	CurveFit/M=2/W=0/TBOX=(0x310) poly 3, peak_spacing_mm_ctr/X=tmpX/D
	CurveFit/M=0/W=2 poly 3, peak_spacing_mm_ctr/X=tmpX/D
	
	TubeCoefTable[ind][] = W_coef[q]
	TubeSigmaTable[ind][] = W_sigma[q]
	
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
		$("tube"+num2str(ii)+"_mm") = V_TubePix_to_mm(TubeCoefTable[ii-1][0],TubeCoefTable[ii-1][1],TubeCoefTable[ii-1][2],p)
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
		$("edge"+num2str(ii)+"_mm")[0] = V_TubePix_to_mm(TubeCoefTable[0][0],TubeCoefTable[0][1],TubeCoefTable[0][2],-1)
	
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



////////////////////////////
//
// Main entry - open the panel and go through
// each of the steps for each of the detector panels
//
Proc V_TubeCoefPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(973,45,1156,535)/K=1
	DoWindow/C V_TubeCoefPanel
//	ShowTools/A

	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,58,"(1)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,108,"(2)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,158,"(3)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,208,"(4)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,258,"(5)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,308,"(6)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,358,"(7)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,408,"(8)"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 5,458,"(9)"
			
	Button button_0,pos={30.00,40.00},size={120.00,20.00},proc=V_Setup_MasksButton,title="Setup"
	Button button_1,pos={30.00,90.00},size={120.00,20.00},proc=V_ArrayToTubesButton,title="Array to Tubes"
	Button button_2,pos={30.00,140.00},size={120.00,20.00},proc=V_TableForPeaksButton,title="Table for Peaks"
	Button button_3,pos={30.00,190.00},size={120.00,20.00},proc=V_IdentifyPeaksButton,title="Identify Peaks"
	Button button_4,pos={30.00,240.00},size={120.00,20.00},proc=V_RefineTableButton,title="Refine Peak Table"
	Button button_5,pos={30.00,290.00},size={120.00,20.00},proc=V_RefinePeaksButton,title="Refine Peaks"

	Button button_6,pos={30.00,340.00},size={120.00,20.00},proc=V_QuadFitTableButton,title="Table for Quad"
	Button button_7,pos={30.00,390.00},size={120.00,20.00},proc=V_QuadFitButton,title="Fit to Quad"
	Button button_8,pos={30.00,440},size={120.00,20.00},proc=V_PeakPlotButton,title="Plot Peaks"
	
EndMacro


// a simple display of the refined results
//
Function V_PeakPlotButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_OpenPeakResultsGraph()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// generate the waves and the table
//
Function V_TableForPeaksButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_MakeTableForPeaks()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// use the WM procedures to quickly identify the peak position (and height)
// to be used in the refining fits
//
Function V_IdentifyPeaksButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_Identify_AllPeaks()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// generate the waves and the table
//
Function V_RefineTableButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_MakeTableForRefinedFit()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// using the initial peak locations from WM, refine the values
// by fitting each individual peak
//
Function V_RefinePeaksButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_Refine_All_PeakPos()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// finally, with the peak positions, make waves and a table for the 
// quadratic coefficients
//
Function V_QuadFitTableButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_MakeTableForFitCoefs()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// fit all of the peak positions per tube vs. the actual mm locations to
// obtain the quadratic coefficients
//
Function V_QuadFitButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_PlotFit_AllPeakPosition()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// fill the waves and table with the hard-wired slot positions (mm)
//
Function V_Setup_MasksButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_SetupSlotDimensions()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// convert the named detector array to 48 individual tube waves
//
Function V_ArrayToTubesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_ArrayToTubes()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


///////////////////////////
//
// unused - a simple line graph for each tube is much simpler
//
Window Gizmo_refinedPositions() : GizmoPlot
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(232,448,747,908)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo Surface=root:position_refined,name=surface0
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ srcMode,0}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ surfaceCTab,Rainbow}
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,axisRange,-1,-1,-1,1,-1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,axisRange,-1,-1,-1,-1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,axisRange,-1,-1,-1,-1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={3,axisRange,-1,1,-1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={4,axisRange,1,1,-1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={5,axisRange,1,-1,-1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={6,axisRange,-1,-1,1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={7,axisRange,1,-1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={8,axisRange,1,-1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={9,axisRange,-1,1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={10,axisRange,-1,1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={11,axisRange,-1,-1,1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,ticks,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,ticks,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,ticks,2}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	ModifyGizmo setDisplayList=0, object=surface0
	ModifyGizmo setDisplayList=1, object=axes0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={651,303,1468,602}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={0.573113,-0.115160,-0.275160,0.763255}
EndMacro

///////////////////////////
//
// unused - a simple line graph for each tube is much simpler
//
Window Gizmo_DetPanel() : GizmoPlot
	PauseUpdate; Silent 1		// building window...
	// Building Gizmo 7 window...
	NewGizmo/W=(96,290,611,750)
	ModifyGizmo startRecMacro=700
	ModifyGizmo scalingOption=63
	AppendToGizmo Surface=root:slices_L,name=surface0
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ srcMode,0}
	ModifyGizmo ModifyObject=surface0,objectType=surface,property={ surfaceCTab,ColdWarm}
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,axisRange,-1,-1,-1,1,-1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,axisRange,-1,-1,-1,-1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,axisRange,-1,-1,-1,-1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={3,axisRange,-1,1,-1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={4,axisRange,1,1,-1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={5,axisRange,1,-1,-1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={6,axisRange,-1,-1,1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={7,axisRange,1,-1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={8,axisRange,1,-1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={9,axisRange,-1,1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={10,axisRange,-1,1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={11,axisRange,-1,-1,1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={-1,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={2,ticks,3}
	ModifyGizmo modifyObject=axes0,objectType=Axes,property={-1,Clipped,0}
	AppendToGizmo Surface=root:position_refined,name=surface1
	ModifyGizmo ModifyObject=surface1,objectType=surface,property={ fillMode,4}
	ModifyGizmo ModifyObject=surface1,objectType=surface,property={ srcMode,0}
	ModifyGizmo ModifyObject=surface1,objectType=surface,property={ surfaceCTab,Rainbow}
	ModifyGizmo setDisplayList=0, object=axes0
	ModifyGizmo setDisplayList=1, object=surface0
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo showInfo
	ModifyGizmo infoWindow={550,23,1367,322}
	ModifyGizmo endRecMacro
	ModifyGizmo SETQUATERNION={0.499484,-0.278571,-0.448869,0.686609}
EndMacro


////////////////////////////////////
//
// An easy way to see the fit results to check if the peak locations all make sense.
//
Proc V_OpenPeakResultsGraph()

	DoWindow/F V_PeakResultsGraph
	if(V_flag == 0)
		Make/O/D/N=5 tmpPeak,dummyLevel
		Make/O/D/N=128 tmpTube
		
		tmpPeak = position_refined[p][0]
		dummyLevel = WaveMax(tube0)
		tmpTube = tube0
		
		V_PeakResultsGraph()
	endif

End


///////////////
//
// An easy way to see the fit results to check if the peak locations all make sense.
//
Window V_PeakResultsGraph() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(750,45,1161,376)/K=1 tmpTube vs tube_pixel
	
	ControlBar 50
	
	
	AppendToGraph dummyLevel vs tmpPeak
	ModifyGraph mode(dummyLevel)=3
	ModifyGraph marker(dummyLevel)=19
	ModifyGraph rgb(dummyLevel)=(1,16019,65535)
	
	SetVariable setvar0,pos={10.00,10.00},size={120.00,14.00},proc=V_TubePeakSetVarProc,title="Tube"
	SetVariable setvar0,limits={0,47,1},value= _NUM:0
	
	Label left "Counts"
	Label bottom "Pixel Number"
EndMacro

//
// cycle through the tubes
//
Function V_TubePeakSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			Wave tmpPeak = tmpPeak
			Wave dummyLevel = dummyLevel
			Wave tmpTube = tmpTube
			
			Wave pos_ref = position_refined
			Wave tube = $("tube"+num2str(dval))
			
			tmpPeak = pos_ref[p][dval]
			dummyLevel = WaveMax(tube)
			tmpTube = tube
		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

////////////////////////////////////
//
// DONE 
// x- document the "simple" save of the detector panels for import and subsequent fitting.
//   Documentation is done in the "main" VSANS documentation, and is largely not needed, since Phil
//   is doing the nonlinear calibration calculations, not me.
//
//
// takes the data from RAW, by default. This is OK, since even though whatever is in the calibration data
// of the file is used when loading into RAW, it is only used for the calculation of q. The actual data
// array is unchanged. Alternatively, the data could be pulled from the RawVSANS folder after a
// file catalog operation
//
Proc V_CopyDetectorsToRoot()

	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_B:data data_B

	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_ML:data data_ML
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MR:data data_MR
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MT:data data_MT
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_MB:data data_MB

	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data data_FL
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FR:data data_FR
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FT:data data_FT
	Duplicate/O root:Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:data data_FB
	
End

//
//
Proc V_SaveDetectorsITX()
// binary save makes each wave an individual file. Igor text groups them all into one file.
//	Save/C data_B,data_FB,data_FL,data_FR,data_FT,data_MB,data_ML,data_MR,data_MT
	Save/T/M="\r\n" data_B,data_FB,data_FL,data_FR,data_FT,data_MB,data_ML,data_MR,data_MT as "data_B++.itx"

End
