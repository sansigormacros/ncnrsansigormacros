#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// functions to apply corrections to the detector panels

// may be relocated in the future




//
// detector dead time
// 
// input is the data array (N tubes x M pixels)
// input of N x 1 array of dead time values
//
// output is the corrected counts in data, overwriting the input data
//
// Note that the equation in Roe (eqn 2.15, p. 63) looks different, but it is really the 
// same old equation, just written in a more complex form.
//
// TODO
// -- verify the direction of the tubes and indexing
// x- decide on the appropriate functional form for the tubes
// x- need count time as input
// -- be sure I'm working in the right data folder
// -- clean up when done
// -- calculate + return the error contribution?
//
Function DeadTimeCorrectionTubes(dataW,dtW,orientation,ctTime)
	Wave dataW,dtW
	String orientation
	Variable ctTime
	
	// do I count on the orientation as an input, or do I just figure it out on my own?
	
	// sum the counts in each tube and divide by time for total cr per tube
	Variable npt
	
	if(cmpstr(orientation,"vertical")==0)
		//	this is data dimensioned as (Ntubes,Npix)
		
		MatrixOp/O sumTubes = sumRows(dataW)		// n x 1 result
		sumTubes /= ctTime		//now count rate per tube
		
		dataW[][] = dataW[p][q]/(1-sumTubes[p][0]*dtW[p])		//correct the data

	elseif(cmpstr(orientation,"horizontal")==0)
	//	this is data (horizontal) dimensioned as (Npix,Ntubes)

		MatrixOp/O sumTubes = sumCols(dataW)		// 1 x m result
		sumTubes /= ctTime
		
		dataW[][] = dataW[p][q]/(1-sumTubes[0][q]*dtW[q])
	
	else		
		DoAlert 0,"Orientation not correctly passed in DeadTimeCorrectionTubes(). No correction done."
	endif
	
	return(0)
end



/////
//
//
// non-linear corrections to the tube pixels
// - returns the distance in mm (although this may change)
//
//
// c0,c1,c2,pix
// c0-c2 are the fit coefficients
// pix is the test pixel
//
// returns the distance in mm (relative to ctr pixel)
// ctr is the center pixel, as defined when fitting to quadratic was done
//
Function V_TubePixel_to_mm(c0,c1,c2,pix)
	Variable c0,c1,c2,pix
	
	Variable dist
	dist = c0 + c1*pix + c2*pix*pix
	
	return(dist)
End

////