#pragma rtGlobals=1		// Use modern global access method.

//
// ********
// TODO -- this is only a fake DIV file. need to identify how to generate a real DIV file
//     for the different detectors, and how to fill it into a file. ProDIV for SANS may be a good
//     starting point, or it may be cumbersome. Not sure how it will be measured in practice
//     on VSANS.
//
//   JAN 2017
//
// TODO:
// -- complete the description of the steps needed...
// Data needs to be reduced to the "COR" level - that means that the 
// PLEX data has been added to work files, and the empty and blocked beam have been
// subtracted off.
// -- but what detector corrections should/ should not be done?
// -- non-linear corrections are not needed, since this will strictly be a per-pixel correction
// -- solid angle?
// -- dead time?
// -- efficiency?
// -- large angle transmission?
//
// we may need to think more carefully about some of these since the front carriage may need to be 
// closer than the nominal 4m distance on SANS that was deemed far enough back to be "safe" from 
// the high angle issues.
//
//



/// TODO:
// -- this is the basic renormalization that is done in PRODIV. see that file for all of the 
//    details of how it's used
// -- update to VSANS file locations and data reads
// -- expand this to do a basic renormalization of all 9 panels, and move the data into the 
//    appropriate locations for saving as a DIV file.
//
//






//works on the data in "type" folder (expecting data to be reduced to the COR level)
//sums all of the data, and normalizes by the number of cells (=pixelX*pixelY)
// calling procedure must make sure that the folder is on linear scale FIRST
Function V_NormalizeDIV(type)
	String type
	
	WAVE data=$("root:Packages:NIST:"+type+":data")
	WAVE data_lin=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	
	Variable totCts=sum(data,Inf,-Inf)		//sum all of the data
	NVAR pixelX = root:myGlobals:gNPixelsX
	NVAR pixelY = root:myGlobals:gNPixelsY

	
	data /= totCts
	data *= pixelX*pixelY
	
	data_lin /= totCts
	data_lin *= pixelX*pixelY
	
	data_err /= totCts
	data_err *= pixelX*pixelY
		
	return(0)
End







// TODO
// currently, there are no dummy fill values or attributes for the fake DIV file
//
Proc Setup_VSANS_DIV_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_VSANS_DIV_Structure()
	
	// writes in the attributes
//	H_Fill_VSANS_Attributes()
	
	// fill in with VCALC simulation bits
//	H_Fill_VSANS_wSim()
	
End

Proc Save_VSANS_DIV_Nexus(fileName)
	String fileName="Test_VSANS_DIV_file"

	// save as HDF5 (no attributes saved yet)
	Save_VSANS_file("root:VSANS_DIV_file", fileName+".h5")
	
//	// read in a data file using the gateway-- reads from the home path
//	H_HDF5Gate_Read_Raw(fileName+".h5")
//	
//	// after reading in a "partial" file using the gateway (to generate the xref)
//	// Save the xref to disk (for later use)
//	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
//	
//	// after you've generated the HDF5___xref, load it in and copy it
//	// to the necessary folder location.
//	Copy_HDF5___xref("root:VSANS_DIV_file", "HDF5___xref")
//	
//	// writes out the contents of a data folder using the gateway
//	H_HDF5Gate_Write_Raw("root:VSANS_DIV_file", fileName+".h5")
//
//	// re-load the data file using the gateway-- reads from the home path
//	// now with attributes
//	H_HDF5Gate_Read_Raw(fileName+".h5")
	
End

////////////// fake DIV file tests
//
//
//	Make/O/T/N=1	file_name	= "VSANS_DIV_test.h5"
//
// simple generation of a fake div file. for sans, nothing other than the creation date was written to the 
// file header. nothing more is needed (possibly)
//
// TODO -- I want to re-visit the propagation of errors in the DIV file. No errors are ever calculated/saved 
//   during the generation of the file, but there's no reason it couldn't. the idea is that the plex
//   is counted so long that the errors are insignificant compared to the data errors, but that may not
//   always be the case. A bit of math may prove this. or not. Plus, the situation for VSANS may be different.
//
//
// TODO -- make the number of pixels GLOBAL
// TODO -- there will be lots of work to do to develop the procedures necessary to actually generate the 
//      9 data sets to become the DIV file contents. More complexity here than for the simple SANS case.
//
Proc H_Setup_VSANS_DIV_Structure()
	
	NewDataFolder/O/S root:VSANS_DIV_file		

	NewDataFolder/O/S root:VSANS_DIV_file:entry	
		Make/O/T/N=1	title	= "This is a DIV file for VSANS: VSANS_DIV"
		Make/O/T/N=1	start_date	= "2015-02-28T08:15:30-5:00"
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument		
			Make/O/T/N=1	name	= "NG3_VSANS"
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_B	
			Make/O/D/N=(150,150)	data	= 1 + (enoise(0.1))
			Make/O/D/N=(150,150)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MR		
			Make/O/D/N=(48,128)	data
			data[][0] = 1+enoise(0.1)
			data[][] = data[p][0]
			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_ML		
			Make/O/D/N=(48,128)	data
			data[][0] = 1+enoise(0.1)
			data[][] = data[p][0]
			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MT		
			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MB		
			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FR		
			Make/O/D/N=(48,128)	data
			data[][0] = 1+enoise(0.1)
			data[][] = data[p][0]
			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FL		
			Make/O/D/N=(48,128)	data
			data[][0] = 1+enoise(0.1)
			data[][] = data[p][0]
			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FT		
			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FB		
			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
		
		// fake, empty folders so that the generic loaders can be used
		NewDataFolder/O root:VSANS_DIV_file:entry:DAS_logs
		NewDataFolder/O root:VSANS_DIV_file:entry:control
		NewDataFolder/O root:VSANS_DIV_file:entry:reduction
		NewDataFolder/O root:VSANS_DIV_file:entry:sample
		NewDataFolder/O root:VSANS_DIV_file:entry:user

			
	SetDataFolder root:

End