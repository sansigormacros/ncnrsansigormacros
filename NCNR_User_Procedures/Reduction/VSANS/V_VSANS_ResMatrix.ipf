#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

// routines to recalculate the weighting matrix for VSANS correctly as three (or two)
// separate upper triangular matrices with their own remainders. These three (or two)
// matrices are merged into a single matrix that is notfully upper triangular
// but rather a triangular block for each carriage. In this way the weight calculation
// for each carriages is independent of each other, and the matrix multiplication
// works out correctly.

// TODO:
//
// One issue is the necessity that the calculation needs to be re-done after loading
// the data. The initial load is done with a single (incorrect) slope calculation
// as if the data was USANS data -- but the data must be reprocessed, with three
// slopes input to properly recalculate the matrix.

Proc V_RecalcWeights(baseStr)
	string baseStr
	Prompt baseStr, "Select the data folder", popup, V_DataFolderList()

	V_CalcVSANSWeights(baseStr)
EndMacro

Function/S V_DataFolderList()

	string list
	string folders = DataFolderDir(1)
	list = StringByKey("FOLDERS", folders)

	list = ReplaceString(",", list, ";")
	return (list)
End

//
// put all of the pieces together to calculate the matrix correctly for
// the multiple levels of VSANS
//
Function V_CalcVSANSWeights(string baseStr)

	Make/O/D/N=4 pw
	// find the number of different levels

	variable levels
	levels = V_Find_dQv_Levels(baseStr, pw)

	Print "VSANS levels =", levels
	//
	// are there two or three levels?
	//  two or three carriages used
	//
	V_RecalcMatrixPieces(baseStr, pw, levels)

	return (0)
End

// step manually through the dQv wave and find the
// point ranges for the jumps
//
// expecting one or two transitions where dQv is larger at each step
// inclusive point values for each step:
// p1,p2
// p2+1, p3
// p3+1, p4
//
// if there are only two transistions, then p3=p4= endpoint
//
// returns the number of steps == number of carriages used
//
Function V_Find_dQv_Levels(string baseStr, WAVE pw)

	variable p1, p2, p3, p4
	variable ii, num, val, step

	WAVE dQvWave = $("root:" + baseStr + ":" + baseStr + "_dQv")

	//initialize to a bad value as a check for two levels
	p1 = -1
	p2 = -1
	p3 = -1
	p4 = -1

	val  = 0
	step = 0
	num  = numpnts(dQvWave)
	p4   = num - 1

	for(ii = 0; ii < num; ii += 1)
		if(dQvWave[ii] > val)
			val   = dQvWave[ii]
			step += 1

			if(step == 1)
				p1 = ii
			endif
			if(step == 2)
				p2 = ii - 1
			endif
			if(step == 3)
				p3 = ii - 1
			endif
		endif

	endfor

	//	Print "p1, p2, p3, p4 = ",p1,p2,p3,p4

	// for the return values, so I can still test from the command line (pbr won't work)
	pw[0] = p1
	pw[1] = p2
	pw[2] = p3
	pw[3] = p4

	// return the number of levels found and adjust pw
	if(p3 == -1)
		pw[2] = pw[3] //so I don't pass -1 as a point value, pw[2] is the last pt now
		return (2)
	endif

	return (3)

End

// recalculate each section of the matrix
//
//
// inclusive point values for each step:
// p1,p2
// p2+1, p3
// p3+1, p4
//
//	pw[0] = p1
//	pw[1] = p2
//	pw[2] = p3
//	pw[3] = p4
//
// lev = 3 if all three segments, any other input
//   will calculate only two segments
//
// asks for slope (2 or 3 times) and recalculates each matrix
//
// modifies the "_res" matrix in the data folder for smearing calculation
// by merging the sub-matrices into the full-sized "_res" matrix
//
Function V_RecalcMatrixPieces(string baseStr, WAVE pw, variable lev)

	variable p1, p2, p3, p4
	p1 = pw[0]
	p2 = pw[1]
	p3 = pw[2]
	p4 = pw[3]

	/////
	variable/G USANS_N                          = numpnts($(basestr + "_q"))
	variable/G USANS_dQv                        = 0.1
	string/G   root:Packages:NIST:USANS_basestr = basestr //this is the "current data" for slope and weights

	Make/D/O/N=(USANS_N, USANS_N) $(basestr + "_res")
	Make/D/O/N=(USANS_N, USANS_N) W1mat
	Make/D/O/N=(USANS_N, USANS_N) W2mat
	Make/D/O/N=(USANS_N, USANS_N) Rmat
	WAVE weights = $(basestr + "_res")

	//Variable/G USANS_m = EnterSlope(baseStr)
	variable/G USANS_m             = -4
	variable/G USANS_slope_numpnts = 15
	string/G   trimStr             = "" //null string if NOT using cursors, "t" if yes (and re-calculating)

	/////

	// full ResW
	WAVE ResW = $("root:" + baseStr + ":" + baseStr + "_res")
	Duplicate/O ResW, $("root:" + baseStr + ":" + baseStr + "_res_save")

	//	Assign the pieces to the resW
	ResW = 0 //clear first

	// 1st segment
	USANS_RE_CalcWeights(baseStr, p1, p2)

	WAVE ResWt = $("root:" + baseStr + ":" + baseStr + "_rest") //"trimmed" version
	Duplicate/O ResWt, $("root:" + baseStr + ":" + baseStr + "_res1")

	// 2nd segment
	USANS_RE_CalcWeights(baseStr, p2 + 1, p3)
	Duplicate/O ResWt, $("root:" + baseStr + ":" + baseStr + "_res2")

	// 3rd segment
	if(lev == 3)
		USANS_RE_CalcWeights(baseStr, p3 + 1, p4)
		Duplicate/O ResWt, $("root:" + baseStr + ":" + baseStr + "_res3")
		WAVE w3 = $("root:" + baseStr + ":" + baseStr + "_res3")
	endif

	WAVE w1 = $("root:" + baseStr + ":" + baseStr + "_res1")
	WAVE w2 = $("root:" + baseStr + ":" + baseStr + "_res2")

	ResW[p1, p2][p1, p2] = w1[p][q]

	ResW[p2 + 1, p3][p2 + 1, p3] = w2[p - (p2 + 1)][q - (p2 + 1)]

	if(lev == 3)
		ResW[p3 + 1, p4][p3 + 1, p4] = w3[p - (p3 + 1)][q - (p3 + 1)]
	endif

	// put the point range of the matrix in a wave note
	string nStr = ""
	sprintf nStr, "P1=%d;P2=%d;", p1, p4
	Note/K ResW, nStr

	// overwrite the "weights_save" wave with the new wave of weights
	Duplicate/O ResW, $("root:" + baseStr + ":" + "weights_save")

	KillWaves/Z w1, w2, w3
	SetDataFolder root:

	return (0)
End

