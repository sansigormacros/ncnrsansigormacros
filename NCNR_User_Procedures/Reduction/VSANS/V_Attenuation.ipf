#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
// 7-NOV-2017
// 
// The attenuator tables are more complex now - since there are more ways to select wavelength
// - there is the standard velocity selector (no tilt)
// - a white beam mode (with a non-symmetric distribution)
// - a graphite monochromator, allowing wavelength selection
//
// To accomodate this, I have chosen to alter the table to allow all of the wavelength "modes"
// to be in the same table for interpolation, by use of the "correct" input wavelength
// velocity_selector lambda is input as is
// white beam lambda = (lambda * 1e3)
// graphite crystal lambda = (lambda * 1e6)
//
// in this way, the interpolation will work just fine. Otherwise, the only solution I could see was to 
// have separate tables stored in the header for each of the "modes".
//
//

//
// functions to calculate attenuator values from the tables
//
// V_CalculateAttenuationFactor(fname)
// V_CalculateAttenuationError(fname)
//
// interpolate if necessary
//

//
// patch entire tables if necessary
//
//
// attenuator tables are currently /N=(n,17)


Proc V_LoadCSVAttenTable()

	// this load command will:
	// load CSV data into a matrix
	// skip a one-line header
	// name it "atten0"
	// prompt for file
	LoadWave/J/M/D/A=atten/E=1/K=1/L={0,1,0,0,0}				//will prompt for the file, auto name
	
	Rename atten0, atten_values

End

Proc V_LoadCSVAttenErrTable()

	// this load command will:
	// load CSV data into a matrix
	// skip a one-line header
	// name it "atten0"
	// prompt for file
	LoadWave/J/M/D/A=atten/E=1/K=1/L={0,1,0,0,0}				//will prompt for the file, auto name
	
	Rename atten0, atten_err

End

// V_writeAttenIndex_table(fname,inW)
//
// V_writeAttenIndex_table_err(fname,inW)
//

Proc V_WriteCSVAttenTable(lo,hi,atten_values)
	Variable lo,hi
	String atten_values="atten_values"

	V_fPatchAttenValueTable(lo,hi,$atten_values)
End

Proc V_WriteCSVAttenErrTable(lo,hi,atten_err)
	Variable lo,hi
	String atten_err="atten_err"

	V_fPatchAttenErrTable(lo,hi,$atten_err)
End


// simple utility to patch the attenuator table wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchAttenValueTable(lo,hi,attenW)
	Variable lo,hi
	Wave attenW
	
	Variable ii
	String fname
	
//	// check the dimensions of the attenW (8,17)
//	if (DimSize(attenW, 0) != 8 || DimSize(attenW, 1) != 17 )
//		Abort "attenuator wave is not of proper dimension (8,17)"
//	endif
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeAttenIndex_table(fname,attenW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to patch the attenuator error (std dev) wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchAttenErrTable(lo,hi,attenW)
	Variable lo,hi
	Wave attenW
	
	Variable ii
	String fname
	
//	// check the dimensions of the attenW (8,17)
//	if (DimSize(attenW, 0) != 8 || DimSize(attenW, 1) != 17 )
//		Abort "attenuator wave is not of proper dimension (8,17)"
//	endif
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeAttenIndex_table_err(fname,attenW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End



//////////////////////
//
// function to calculate the attenuation factor from the table in the file
//
// fill in a "dummy" wavelength for White Beam and graphite
// *= 1e3 for White Beam
// *= 1e6 for graphite
// use these dummy values just for the lookup table
//
// TODO -- need the enumerated values for the monochromator type
// TODO -- V_getMonochromatorType(fname) is NOT written correctly by NICE
// TODO -- determine the dimensions of the wave, don't hard-wire
// TODO -- update to use separate tables for each monochromator mode
// TODO -- (same updates for the error table)
//
Function V_CalculateAttenuationFactor(fname)
	String fname
	
	Variable val,lambda,numAtt
	String monoType
	
	numAtt = V_getAtten_number(fname)
	lambda = V_getWavelength(fname)
	
	// TODO -- need to switch on "type"
	//  == velocity_selector || ?? for white beam || graphite
//	monoType = V_getMonochromatorType(fname)

	monoType = V_DeduceMonochromatorType(fname)
	print monoType

	// set a fake wavelength for the interpolation or get out
	strswitch(monoType)	// string switch
		case "velocity_selector":	// execute if case matches expression
			// use lambda as-is
			break		// exit from switch
		case "white_beam":	// execute if case matches expression
			lambda *= 1e3
			break
		case "crystal":
			lambda *= 1e6
			break
		default:			// optional default expression executed
			Abort "Monochromator type could not be determined in V_CalculateAttenuationFactor"		// when no case matches
	endswitch
	
	
	Wave w = V_getAttenIndex_table(fname)		// N=(x,17)
	Variable num = DimSize(w,0)
	Make/O/D/N=(num) tmpVal,tmpLam						
	
	tmpVal = w[p][numAtt+1]		// offset by one, 1st column is wavelength
	tmpLam = w[p][0]
	val = interp(lambda, tmpLam, tmpVal )
	Print "Calculated Atten = ",val
	
	//killwaves/Z tmpVal,tmpLam
	return(val)
	
End

//////////////////////
//
// function to calculate the attenuation error from the table in the file
//
// fill in a "dummy" wavelength for White Beam and graphite
// *= 1e3 for White Beam
// *= 1e6 for graphite
// use these dummy values just for the lookup table
//
// TODO -- need the enumerated values for the monochromator type
// TODO -- V_getMonochromatorType(fname) is NOT written correctly by NICE
//
//
Function V_CalculateAttenuationError(fname)
	String fname
	
	Variable val,lambda,numAtt
	String monoType
	
	numAtt = V_getAtten_number(fname)
	lambda = V_getWavelength(fname)
	
	// TODO -- need to switch on "type"
	//  == velocity_selector || ?? for white beam || crystal
//	monoType = V_getMonochromatorType(fname)
	
	monoType = V_DeduceMonochromatorType(fname)
	print monoType
	// set a fake wavelength for the interpolation or get out
	strswitch(monoType)	// string switch
		case "velocity_selector":	// execute if case matches expression
			// use lambda as-is
			break		// exit from switch
		case "white_beam":	// execute if case matches expression
			lambda *= 1e3
			break
		case "crystal":
			lambda *= 1e6
			break
		default:			// optional default expression executed
			Abort "Monochromator type could not be determined in V_CalculateAttenuationError"		// when no case matches
	endswitch	
	
	Wave w = V_getAttenIndex_error_table(fname)		// N=(x,17)
	Variable num = DimSize(w,0)
	Make/O/D/N=(num) tmpVal,tmpLam
	
	tmpVal = w[p][numAtt+1]		// offset by one, 1st column is wavelength
	tmpLam = w[p][0]
	val = interp(lambda, tmpLam, tmpVal )
	
	//killwaves/Z tmpVal,tmpLam
	return(val)
	
End

