#pragma rtGlobals=1		// Use modern global access method.
#pragma version=6.0
#pragma IgorVersion=8.0

//
// JULY 2021 -- TODO - replace the functions in this file--- with new equivalents
//								or move necessary functions to the new procedures
//
// -- the goal is to eliminate the VAX references from this file completely (at least any calls to them)
// and replace with calls so that I can write out Nexus-style files instead
//
//
//
// all that is left in this file is some odd utility functions that 
// may or may not be useful to patch (batchwise) bits of the raw data file
// headers.

//
// There are some old VAX-file R/W routines that have no value
// within the new nexus format, and need to be REPLACED with the correct get, put, or write
// functions in the files:
// 	NCNR_HDF5_Read.ipf
// 	NCNR_HDF5_Write.ipf
//		NCNR_DataReadWriteUtils_N.ipf
//
//
// I have strayed from the clean split of functions that are "facility-specific"
// and made a lot of NCNR-specific changes and they are now sprinkled throughout 
// the code. Efforts to open the code to other facilities has long since fallen
// by the wayside...
//
//


//**************************
//
// Vers. 1.2 092101
// Vers. 5.0 29MAR07 - branched from main reduction to split out facility
//                     specific calls
//
////////////////////////////
// Vers. 6.0 JULY 2014 - first attempt to use HDF5 as the raw file format
//
// -- NOTE - the file format has NOT BEEN DEFINED! I am simply converting the VAX file to 
// an HDF5 file. I'm using Pete Jemain's HDF5Gateway, with some modifications.
//
// -- following the ANSTO code, read everything into a tree of folders
//  then each "get" first looks for the local copy, and reads the necessary value from there
//  - if the file has not been loaded, then load it, and read the value (or read it directly?)
//


///// VAX FUNCTIONS HAVE BEEN MOVED TO THE BOTTOM OF THE FILE ///////////



///////////
// functions to set up Nexus tree structure to be able to
// work with a "fake" work folder for SASCALC, and to house simulated data sets
//
//



// Functions to set up the Nexus tree structure in the SAS folder for use
// with SASCALC.
//
// 1) these functions don't belong in this ipf file
// 2) These functions are duplicated in the HDF5_Convert... ipf file, which
//  due to it needing to read VAX data, can't be loaded in the Nexus-based file set. (Sigh..)
//
//
// see FillFakeNexusStructure()
//

// lays out the tree into the specified folder
// for SASCALC, this is
// fStr = "root:Packages:NIST:SAS"
// for a file to export (or a converted file), this could be:
// fStr = "root:toExport"
//
Function SetupNexusStructure(fStr)
	String fStr

	Variable nx, ny
	if(cmpstr(ksDetType,"Tubes")==0)
		// tube values
		nx = 112
		ny = 128

	else
		//Ordela values
		nx = 128
		ny = 128

	endif

	SetDataFolder root:
	
	NewDataFolder/O $fStr
	NewDataFolder/O $(fStr + ":entry")
	NewDataFolder/O $(fStr + ":entry:control")
	NewDataFolder/O $(fStr + ":entry:data")
	NewDataFolder/O $(fStr + ":entry:instrument")
	NewDataFolder/O $(fStr + ":entry:instrument:attenuator")
	NewDataFolder/O $(fStr + ":entry:instrument:beam_monitor_norm")
	NewDataFolder/O $(fStr + ":entry:instrument:beam_stop")
	NewDataFolder/O $(fStr + ":entry:instrument:beam_stop:shape")
	NewDataFolder/O $(fStr + ":entry:instrument:collimator")
	NewDataFolder/O $(fStr + ":entry:instrument:collimator:geometry")
	NewDataFolder/O $(fStr + ":entry:instrument:collimator:geometry:shape")
	NewDataFolder/O $(fStr + ":entry:instrument:detector")
	NewDataFolder/O $(fStr + ":entry:instrument:lenses")
	NewDataFolder/O $(fStr + ":entry:instrument:monochromator")
	NewDataFolder/O $(fStr + ":entry:instrument:monochromator:velocity_selector")
	NewDataFolder/O $(fStr + ":entry:instrument:sample_aperture")
	NewDataFolder/O $(fStr + ":entry:instrument:sample_aperture:shape")
	NewDataFolder/O $(fStr + ":entry:instrument:sample_table")
	NewDataFolder/O $(fStr + ":entry:instrument:source")
	NewDataFolder/O $(fStr + ":entry:instrument:source_aperture")
	NewDataFolder/O $(fStr + ":entry:instrument:source_aperture:shape")
	NewDataFolder/O $(fStr + ":entry:program_data")
	NewDataFolder/O $(fStr + ":entry:reduction")
	NewDataFolder/O $(fStr + ":entry:sample")
	NewDataFolder/O $(fStr + ":entry:user")


	SetDataFolder $(fStr + ":entry")
    
  	 Make/O/I/N=1	collection_time 	//600
	 Make/O/T/N=1	data_directory   	//"C:\Users\jkrzywon\devel\NICE\server_data\experiments\nonims0\data"
	 Make/O/T/N=1	definition   	//"NXsas"
	 Make/O/D/N=1	duration 	//8.133
	 Make/O/T/N=1	end_time   	//"2021-09-17T12:37:49.273-04:00"
	 Make/O/T/N=1	experiment_description   	//"Modify Current Experiment"
	 Make/O/T/N=1	experiment_identifier   	//"nonims0"
	 Make/O/T/N=1	facility   	//"NCNR"
	 Make/O/T/N=1	program_name   	//"NICE"
	 Make/O/T/N=1	start_time   	//"2021-09-17T12:37:41.140-04:00"
	 Make/O/T/N=1	title   	//"sans"  
    
    
	SetDataFolder $(fStr + ":entry:control")

		Make/O/D/N=1	count_end 	//8.096
		Make/O/D/N=1	count_start 	//2.259
		Make/O/D/N=1	count_time 	//600
		Make/O/D/N=1	count_time_preset 	//600
		Make/O/D/N=1	detector_counts 	//1.76832e+08
		Make/O/D/N=1	detector_preset 	//0
		Make/O/D/N=1	efficiency 	//1
		Make/O/T/N=1		mode   	//"TIME"
		Make/O/I/N=1	monitor_counts 	//19099
		Make/O/D/N=1	monitor_preset 	//1800
		Make/O/D/N=1	sampled_fraction 	//0.0833

	SetDataFolder $(fStr + ":entry:data")
	
		Make/O/D/N=(nx,ny)	areaDetector //(2-D wave N=(112,128)) val=4605	typ=32bI
		Make/O/T/N=1	configuration   	//"4m 6A Scatt"
		Make/O/T/N=1	sample_description   	//"Sample 1"
		Make/O/D/N=1	sample_thickness 	//1
		Make/O/T/N=1	slotIndex   	//"1"
		Make/O/T/N=1	x0   	//"TIME"
		Make/O/D/N=(nx,ny)	y0 //(2-D wave N=(112,128)) val=4605	typ=32bI

	SetDataFolder $(fStr + ":entry:instrument")
	
		Make/O/T/N=1	local_contact   	//"Jeff Krzywon"
		Make/O/T/N=1	name   	//"SANS:NGB"
		Make/O/T/N=1	type   	//"SANS"

	SetDataFolder $(fStr + ":entry:instrument:attenuator")

		Make/O/D/N=1		attenuator_transmission 	//1
		Make/O/D/N=1		attenuator_transmission_error 	//1
		Make/O/I/N=1		desired_num_atten_dropped 	//3
		Make/O/D/N=1		distance 	//15
		Make/O/D/N=(12,12)		index_error_table //(2-D wave N=(12,12)) val=3	typ=32bF
		Make/O/D/N=(12,12)		index_table //(2-D wave N=(12,12)) val=3	typ=32bF
		Make/O/D/N=1		num_atten_dropped 	//3
		Make/O/D/N=1		thickness 	//0.187559
		Make/O/T/N=1		type   	//"PMMA"

	SetDataFolder $(fStr + ":entry:instrument:beam_monitor_norm") 
		Make/O/I/N=1		data 	//19099
		Make/O/D/N=1		distance 	//15
		Make/O/D/N=1		efficiency 	//0.01
		Make/O/D/N=1		saved_count 	//1e+08
		Make/O/T/N=1		type   	//"monitor"
		
	SetDataFolder $(fStr + ":entry:instrument:beam_stop") 
		Make/O/T/N=1		description   	//"circular"
		Make/O/D/N=1		distance_to_detector 	//0
		Make/O/D/N=1		x_pos 	//0
		Make/O/D/N=1		y_pos 	//6.85408
				
	SetDataFolder $(fStr + ":entry:instrument:beam_stop:shape") 
		Make/O/D/N=1			height 	//nan
		Make/O/T/N=1			shape   	//"CIRCLE"
		Make/O/D/N=1			size 	//5.08
		Make/O/D/N=1			width 	//nan

	SetupCollimator(fStr)					

	SetupDetector(fStr)						

				
	SetDataFolder $(fStr + ":entry:instrument:lenses") 
		Make/O/D/N=1		curvature 	//25.4
		Make/O/T/N=1		focus_type   	//"point"
		Make/O/D/N=1		lens_distance 	//15
		Make/O/T/N=1		lens_geometry   	//"concave_lens"
		Make/O/T/N=1		lens_material   	//"MgF2"
		Make/O/I/N=1		number_of_lenses 	//28
		Make/O/I/N=1		number_of_prisms 	//7
		Make/O/D/N=1		prism_distance 	//14.5
		Make/O/T/N=1		prism_material   	//"MgF2"
		Make/O/T/N=1		status   	//"out"
				
	SetDataFolder $(fStr + ":entry:instrument:monochromator")
		Make/O/T/N=1		type   	//"velocity_selector"
		Make/O/D/N=1		wavelength 	//6.00747
		Make/O/D/N=1		wavelength_error 	//0.14
		SetDataFolder $(fStr + ":entry:instrument:monochromator:velocity_selector") 
			Make/O/D/N=1		distance 	//11.1
			Make/O/D/N=1		rotation_speed 	//3648.81
			Make/O/D/N=1		table 	//0.0028183

	SetupSampleAperture(fStr)					

					
	SetDataFolder $(fStr + ":entry:instrument:sample_table") 
			Make/O/T/N=1	location   	//"CHAMBER"
			Make/O/D/N=1	offset_distance 	//0
				
	SetDataFolder $(fStr + ":entry:instrument:source") 
			Make/O/T/N=1	name   	//"NCNR"
			Make/O/D/N=1	power 	//20
			Make/O/T/N=1	probe   	//"neutron"
			Make/O/T/N=1	type   	//"Reactor Neutron Source"

	SetupSourceAperture(fStr)				


	SetupProgramData(fStr)

			
	SetDataFolder $(fStr + ":entry:reduction") 
		Make/O/D/N=4	absolute_scaling //(1-D wave N=(4)) val=1	typ=32bF
		Make/O/T/N=1	background_file_name   //	"placeholder.h5"
		Make/O/D/N=4	box_coordinates //(1-D wave N=(4)) val=50	typ=32bF
		Make/O/D/N=1	box_count 	//1
		Make/O/D/N=1	box_count_error 	//0.01
		Make/O/T/N=1	comments   //	"extra data comments"
		Make/O/T/N=1	empty_beam_file_name   //	"placeholder.h5"
		Make/O/T/N=1	empty_file_name   	//"placeholder.h5"
		Make/O/T/N=1	file_purpose   	//"SCATTERING"
		Make/O/T/N=1	intent   //	"Sample"
		Make/O/T/N=1	mask_file_name   //	"placeholder.h5"
		Make/O/T/N=1	sans_log_file_name   	//"placeholder.txt"
		Make/O/T/N=1	sensitivity_file_name   	//""
		Make/O/T/N=1	transmission_file_name   	//"placeholder.h5"
		Make/O/D/N=1	whole_trans 	//1
		Make/O/D/N=1	whole_trans_error //	0.01
			
	SetDataFolder $(fStr + ":entry:sample") 
		Make/O/D/N=1	aequatorial_angle 	//0
		Make/O/T/N=1	changer   	//"CHAMBER"
		Make/O/T/N=1	changer_position  // 	"1"
		Make/O/T/N=1	description   //	"Sample 1"
		Make/O/D/N=1	elevation 	//-900
		Make/O/I/N=1	group_id 	//101
		Make/O/D/N=1	mass 	//nan
		Make/O/T/N=1	name   	//""
		Make/O/D/N=1	rotation_angle 	//-999
		Make/O/T/N=1	sample_holder_description   //	""
		Make/O/D/N=1	thickness 	//1
		Make/O/D/N=1	translation 	//-999
		Make/O/D/N=1	transmission 	//1
		Make/O/D/N=1	transmission_error 	//0.01
			
	SetDataFolder $(fStr + ":entry:user") 
		Make/O/T/N=1	name   //	"[{"name":"Jeff Krzywon","orcid":"","email":"jkrzywon@nist.gov"}]"
					


	SetDataFolder root:
	
End

Function 	SetupCollimator(fStr)
	String fStr
					
	SetDataFolder $(fStr + ":entry:instrument:collimator") 
			Make/O/T/N=1	number_guides   	//"0"
		SetDataFolder $(fStr + ":entry:instrument:collimator:geometry") 
			SetDataFolder $(fStr + ":entry:instrument:collimator:geometry:shape") 
			Make/O/T/N=1			shape   //"RECTANGLE"
			Make/O/D/N=1			size 	//10
			
	SetDataFolder root:
end

Function	SetupDetector(fStr)
	String fStr
	
		Variable nx, ny
	if(cmpstr(ksDetType,"Tubes")==0)
		// tube values
		nx = 112
		ny = 128

	else
		//Ordela values
		nx = 128
		ny = 128

	endif
							
	SetDataFolder $(fStr + ":entry:instrument:detector") 
		Make/O/D/N=1		azimuthal_angle 	//0
		Make/O/D/N=1		beam_center_x 	//113
		Make/O/D/N=1		beam_center_y 	//63.3
		Make/O/D/N=(nx,ny)		data //(2-D wave N=(112,128)) val=4605	typ=32bI
		Make/O/D/N=(1,nx)		dead_time //(2-D wave N=(1,112)) val=5.2e-06	typ=32bF
		Make/O/T/N=1		description   	//"fancy model"
		Make/O/D/N=1		distance 	//120.009
		Make/O/D/N=1		integrated_count //	1.76832e+08
		Make/O/D/N=1		lateral_offset 	//0
		Make/O/I/N=1		number_of_tubes 	//112
		Make/O/D/N=1		pixel_fwhm_x 	//0.508
		Make/O/D/N=1		pixel_fwhm_y 	//0.508
		Make/O/I/N=1		pixel_num_x 	//112
		Make/O/I/N=1		pixel_num_y 	//128
		Make/O/D/N=1		polar_angle 	//0
		Make/O/D/N=1		rotation_angle 	//0
		Make/O/T/N=1		settings   //	"just right"
		Make/O/D/N=(3,nx)		spatial_calibration //(2-D wave N=(3,112)) val=-521	typ=32bF
		Make/O/D/N=1		tube_width 	//8.4
		Make/O/D/N=(nx)		x_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		Make/O/D/N=1		x_pixel_size 	//5.08
		Make/O/D/N=(ny)		y_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		Make/O/D/N=1		y_pixel_size 	//5.08

		Make/O/D/N=(nx,ny)		data_error //(2-D wave N=(112,128)) val=4605	typ=32bI

		
	SetDataFolder root:
end

Function	SetupSampleAperture(fStr)
	String fStr
						
	SetDataFolder $(fStr + ":entry:instrument:sample_aperture") 
		Make/O/T/N=1		description   	//"sample aperture"
		Make/O/D/N=1		distance //	5
		SetDataFolder $(fStr + ":entry:instrument:sample_aperture:shape") 
			Make/O/D/N=1		height 	//0
			Make/O/T/N=1			shape   	//"CIRCLE"
			Make/O/T/N=1		size 	//"6.35 mm"
			Make/O/D/N=1		width 	//0
			
	SetDataFolder root:
end


Function 	SetupSourceAperture(fStr)				
	String fStr

	SetDataFolder $(fStr + ":entry:instrument:source_aperture") 
			Make/O/T/N=1	description   	//"source aperture"
			Make/O/D/N=1	distance 	//508
		SetDataFolder $(fStr + ":entry:instrument:source_aperture:shape") 
			Make/O/T/N=1		shape   	//"CIRCLE"
			Make/O/T/N=1		size   	//"38.1 mm"

	SetDataFolder root:
end

Function SetupProgramData(fStr)
	String fStr
			
	SetDataFolder $(fStr + ":entry:program_data") 
		Make/O/T/N=1	data   	//"runPoint {"counter.countAgainst"="TIME", "configuration"="4m 6A Scatt", "groupid"="101", "filePurpose"="SCATTERING", "sample.description"="Sample 1", "sample.thickness"="1.0", "intent"="Sample", "counter.timePreset"="600.0", "slotIndex"="1.0"} -g 1 -p "MTHYR" -u "NGB""
		Make/O/T/N=1	description   //	"Additional program data, such as the script file which the program ran"
		Make/O/T/N=1	file_name   	//"null"
		Make/O/T/N=1	type   	//"application/json"

	SetDataFolder root:
	
End


///////////////////////////////////////////



// updated to the new Nexus structure.
//
// fills just enough for SASCALC to work
//
// for SAS, pass in the correct path to the SAS folder
//
// if more metadata is needed, where is it pulled from?
//
Function FillFakeNexusStructure(fStr)
	String fStr

	SetDataFolder $(fStr + ":entry")
    
  	 WAVE	collection_time 	//600
	 WAVE/T	data_directory   	//"C:\Users\jkrzywon\devel\NICE\server_data\experiments\nonims0\data"
	 WAVE/T	definition   	//"NXsas"
	 WAVE	duration 	//8.133
	 WAVE/T	end_time   	//"2021-09-17T12:37:49.273-04:00"
	 WAVE/T	experiment_description   	//"Modify Current Experiment"
	 WAVE/T	experiment_identifier   	//"nonims0"
	 WAVE/T	facility   	//"NCNR"
	 WAVE/T	program_name   	//"NICE"
	 WAVE/T	start_time   	//"2021-09-17T12:37:41.140-04:00"
	 WAVE/T	title   	//"sans"  
    
    experiment_identifier  = "nonims0"
//    start_time = tw[1]
    
	SetDataFolder $(fStr + ":entry:control")

		WAVE	count_end 	//8.096
		WAVE	count_start 	//2.259
		WAVE	count_time 	//600
		WAVE	count_time_preset 	//600
		WAVE	detector_counts 	//1.76832e+08
		WAVE	detector_preset 	//0
		WAVE	efficiency 	//1
		WAVE/T		mode   	//"TIME"
		WAVE	monitor_counts 	//19099
		WAVE	monitor_preset 	//1800
		WAVE	sampled_fraction 	//0.0833
		
//		count_time = iw[1]
//		count_time_preset = iw[1]
//		monitor_counts = rw[0]
//		detector_counts = rw[2]
		
//		print iw[0]*iw[1],iw[2]

	SetDataFolder $(fStr + ":entry:data")
	
		WAVE	areaDetector //(2-D wave N=(112,128)) val=4605	typ=32bI
		WAVE/T	configuration   	//"4m 6A Scatt"
		WAVE/T	sample_description   	//"Sample 1"
		WAVE	sample_thickness 	//1
		WAVE/T	slotIndex   	//"1"
		WAVE/T	x0   	//"TIME"
		WAVE	y0 //(2-D wave N=(112,128)) val=4605	typ=32bI

//		sample_description = tw[6]
//		sample_thickness = rw[5]
//		 Wave linear_data = root:Packages:NIST:RAW:linear_data
//		 areaDetector = linear_data[p][q] // result areaDetector is (112,128)
		
	SetDataFolder $(fStr + ":entry:instrument")
	
		WAVE/T	local_contact   	//"Jeff Krzywon"
		WAVE/T	name   	//"SANS:NGB"
		WAVE/T	type   	//"SANS"
		
		local_contact = "Igor"
		name = "SANS_NGB"
		type = "SANS"

	SetDataFolder $(fStr + ":entry:instrument:attenuator")

		WAVE		attenuator_transmission 	//1
		WAVE		attenuator_transmission_error 	//1
		WAVE		desired_num_atten_dropped 	//3
		WAVE		distance 	//15
		WAVE		index_error_table //(2-D wave N=(12,12)) val=3	typ=32bF
		WAVE		index_table //(2-D wave N=(12,12)) val=3	typ=32bF
		WAVE		num_atten_dropped 	//3
		WAVE		thickness 	//0.187559
		WAVE/T		type   	//"PMMA"

//		num_atten_dropped = rw[3]
		
	SetDataFolder $(fStr + ":entry:instrument:beam_monitor_norm") 
		WAVE		data 	//19099
		WAVE		distance 	//15
		WAVE		efficiency 	//0.01
		WAVE		saved_count 	//1e+08
		WAVE/T		type   	//"monitor"
		
//		data = rw[0]

		
	SetDataFolder $(fStr + ":entry:instrument:beam_stop") 
		WAVE/T		description   	//"circular"
		WAVE		distance_to_detector 	//0
		WAVE		x_pos 	//0
		WAVE		y_pos 	//6.85408
		
		description = "circular"
		distance_to_detector = 0
//		x_pos = rw[37]
//		y_pos = rw[38]
				
		SetDataFolder $(fStr + ":entry:instrument:beam_stop:shape") 
			WAVE			height 	//nan
			WAVE/T			shape   	//"CIRCLE"
			WAVE			size 	//5.08
			WAVE			width 	//nan
			
//			size = rw[21]		// wrong units?
			shape = "CIRCLE"
			
	FillCollimator(fStr)					

	FillDetector(fStr)						

				
	SetDataFolder $(fStr + ":entry:instrument:lenses") 
		WAVE		curvature 	//25.4
		WAVE/T		focus_type   	//"point"
		WAVE		lens_distance 	//15
		WAVE/T		lens_geometry   	//"concave_lens"
		WAVE/T		lens_material   	//"MgF2"
		WAVE		number_of_lenses 	//28
		WAVE		number_of_prisms 	//7
		WAVE		prism_distance 	//14.5
		WAVE/T		prism_material   	//"MgF2"
		WAVE/T		status   	//"out"
		
		status = "out"
				
	SetDataFolder $(fStr + ":entry:instrument:monochromator")
		WAVE/T		type   	//"velocity_selector"
		WAVE		wavelength 	//6.00747
		WAVE		wavelength_error 	//0.14
		
		type = "velocity selector"
		wavelength = 6
		wavelength_error = 0.15
		
		SetDataFolder $(fStr + ":entry:instrument:monochromator:velocity_selector") 
			WAVE		distance 	//11.1
			WAVE		rotation_speed 	//3648.81
			WAVE		table 	//0.0028183

	FillSampleAperture(fStr)					

					
	SetDataFolder $(fStr + ":entry:instrument:sample_table") 
			WAVE/T	location   	//"CHAMBER"
			WAVE	offset_distance 	//0
			
//			if(iw[4] == 1)		// guessng at this?
//				location = "CHAMBER"
//			else
//				location = "HUBER"
//			endif
			
	SetDataFolder $(fStr + ":entry:instrument:source") 
			WAVE/T	name   	//"NCNR"
			WAVE	power 	//20
			WAVE/T	probe   	//"neutron"
			WAVE/T	type   	//"Reactor Neutron Source"

			name = "NCNR"
			power = 20
			probe = "neutron"
			type = "Reactor Neutron Source"

	FillSourceAperture(fStr)				


	FillProgramData(fStr)

			
	SetDataFolder $(fStr + ":entry:reduction") 
		WAVE	absolute_scaling //(1-D wave N=(4)) val=1	typ=32bF
		WAVE/T	background_file_name   //	"placeholder.h5"
		WAVE	box_coordinates //(1-D wave N=(4)) val=50	typ=32bF
		WAVE	box_count 	//1
		WAVE	box_count_error 	//0.01
		WAVE/T	comments   //	"extra data comments"
		WAVE/T	empty_beam_file_name   //	"placeholder.h5"
		WAVE/T	empty_file_name   	//"placeholder.h5"
		WAVE/T	file_purpose   	//"SCATTERING"
		WAVE/T	intent   //	"Sample"
		WAVE/T	mask_file_name   //	"placeholder.h5"
		WAVE/T	sans_log_file_name   	//"placeholder.txt"
		WAVE/T	sensitivity_file_name   	//""
		WAVE/T	transmission_file_name   	//"placeholder.h5"
		WAVE	whole_trans 	//1
		WAVE	whole_trans_error //	0.01
		
		file_purpose = "SCATTERING"
		intent = "Sample"
		
	SetDataFolder $(fStr + ":entry:sample") 
		WAVE	aequatorial_angle 	//0
		WAVE/T	changer   	//"CHAMBER"
		WAVE/T	changer_position  // 	"1"
		WAVE/T	description   //	"Sample 1"
		WAVE	elevation 	//-900
		WAVE	group_id 	//101
		WAVE	mass 	//nan
		WAVE/T	name   	//""
		WAVE	rotation_angle 	//-999
		WAVE/T	sample_holder_description   //	""
		WAVE	thickness 	//1
		WAVE	translation 	//-999
		WAVE	transmission 	//1
		WAVE	transmission_error 	//0.01
		
//		description = tw[6]
//		transmission = rw[4]
//		thickness = rw[5]
//		changer_position = num2str(rw[6])
//		rotation_angle = rw[7]
//		sample_holder_description = num2str(iw[5])
			
	SetDataFolder $(fStr + ":entry:user") 
		WAVE/T	name   //	"[{"name":"Jeff Krzywon","orcid":"","email":"jkrzywon@nist.gov"}]"
					

	SetDataFolder root:

End


Function FillCollimator(fStr)
	String fStr
	
	SetDataFolder $(fStr + ":entry:instrument:collimator") 
			WAVE/T	number_guides   	//"0"
		SetDataFolder $(fStr + ":entry:instrument:collimator:geometry") 
			SetDataFolder $(fStr + ":entry:instrument:collimator:geometry:shape") 
			WAVE/T			shape   //"RECTANGLE"
			WAVE			size 	//10
		
			shape = "RECTANGLE"
			size = 10	
	SetDataFolder root:
end

// VAX data w/Ordela detector has different calibration than the
// projected tubes for 10m SANS. Pretend that the VAX data is tubes?
//
Function	FillDetector(fStr)
	String fStr

							
	SetDataFolder $(fStr + ":entry:instrument:detector") 
		WAVE		azimuthal_angle 	//0
		WAVE		beam_center_x 	//113
		WAVE		beam_center_y 	//63.3
		WAVE		data //(2-D wave N=(112,128)) val=4605	typ=32bI
		WAVE		dead_time //(2-D wave N=(1,112)) val=5.2e-06	typ=32bF
		WAVE/T		description   	//"fancy model"
		WAVE		distance 	//120.009
		WAVE		integrated_count //	1.76832e+08
		WAVE		lateral_offset 	//0
		WAVE		number_of_tubes 	//112
		WAVE		pixel_fwhm_x 	//0.508
		WAVE		pixel_fwhm_y 	//0.508
		WAVE		pixel_num_x 	//112
		WAVE		pixel_num_y 	//128
		WAVE		polar_angle 	//0
		WAVE		rotation_angle 	//0
		WAVE/T		settings   //	"just right"
		WAVE		spatial_calibration //(2-D wave N=(3,112)) val=-521	typ=32bF
		WAVE		tube_width 	//8.4
		WAVE		x_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		WAVE		x_pixel_size 	//5.08
		WAVE		y_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		WAVE		y_pixel_size 	//5.08
	
//		description = tw[9]

// in pixels
		beam_center_x = 65
		beam_center_y = 64
		distance = 5*100				// convert the value of [m] to [cm]
//		lateral_offset = rw[19]

		
// cut the right edge of the detector off since data is declared as 
// (112,128), and Ordela is (128,128)
//		 Wave linear_data = root:Packages:NIST:RAW:linear_data
//		 data = linear_data[p][q] // result data is (112,128)

// trim evenly from each side L/R
// 128-112 = 16, so start at the 8th col [7]
// index runs from [7] to [7+111]
//		 data = linear_data[p+7][q] // result data is (112,128)
	
// cut the left edge of the detector, since offset is to the right
//		 data = linear_data[p+15][q] // result data is (112,128)
	
		
		
// different fill if i'm faking TUBES vs. verifying Ordela/30m SANS
//

	if(cmpstr(ksDetType,"Tubes")==0)
		// tube values
	// for TUBES
		tube_width = 8.4
		number_of_tubes = 112
		
		x_pixel_size = 8.4
		y_pixel_size = 5
		pixel_num_x = 112
		pixel_num_y = 128
		pixel_fwhm_x = 0.84
		pixel_fwhm_y = 0.5		
	
	// perfect calibration	
		spatial_calibration[0][] = -521
		spatial_calibration[1][] = 8.14
		spatial_calibration[2][] = 0
		
	// perfect deadTime
		dead_time = 1e-18


	else
		//Ordela values
// for 30m SANS/ duplicating Ordela:
//
		x_pixel_size = 5.08
		y_pixel_size = 5.08
		pixel_num_x = 128
		pixel_num_y = 128
		pixel_fwhm_x = 0.508
		pixel_fwhm_y = 0.508		

		tube_width = 5.08		// fake tube width
		number_of_tubes = 128
	
		// approximate dead time (only a single value used)
		dead_time = 1e-6
		 
		 // "perfect" cailbration of Ordela detector 64 cm in y-direction (=640 mm)
		 
		spatial_calibration[0][] = -320
		spatial_calibration[1][] = 5.08		// per pixel in y direction
		spatial_calibration[2][] = 0
		
		
	endif

		
	SetDataFolder root:
end

Function	FillSampleAperture(fStr)
	String fStr
//	WAVE rw
//	WAVE/T tw
//	WAVE iw
						
	SetDataFolder $(fStr + ":entry:instrument:sample_aperture") 
		WAVE/T		description   	//"sample aperture"
		WAVE		distance //	5
		
		description = "sample aperture"
		distance = 5
		
		SetDataFolder $(fStr + ":entry:instrument:sample_aperture:shape") 
			WAVE		height 	//0
			WAVE/T			shape   	//"CIRCLE"
			WAVE/T		size 	//6.35
			WAVE		width 	//0
			
			size = "12.7 mm"
			shape = "CIRCLE"
			
	SetDataFolder root:
			
end


Function 	FillSourceAperture(fStr)
	String fStr

					
	SetDataFolder $(fStr + ":entry:instrument:source_aperture") 
			WAVE/T	description   	//"source aperture"
			WAVE	distance 	//508
			
			description = "source aperture"
			distance = 508			// distance in [cm]
			
		SetDataFolder $(fStr + ":entry:instrument:source_aperture:shape") 
			WAVE/T		shape   	//"CIRCLE"
			WAVE/T		size   	//"38.1 mm"

			shape = "CIRCLE"
			size = "50 mm"		//correct units?
	SetDataFolder root:
end

Function FillProgramData(fStr)
	String fStr
		
	SetDataFolder $(fStr + ":entry:program_data") 
		WAVE/T	data   	//"runPoint {"counter.countAgainst"="TIME", "configuration"="4m 6A Scatt", "groupid"="101", "filePurpose"="SCATTERING", "sample.description"="Sample 1", "sample.thickness"="1.0", "intent"="Sample", "counter.timePreset"="600.0", "slotIndex"="1.0"} -g 1 -p "MTHYR" -u "NGB""
		WAVE/T	description   //	"Additional program data, such as the script file which the program ran"
		WAVE/T	file_name   	//"null"
		WAVE/T	type   	//"application/json"
		
	SetDataFolder root:
	
End



//
// this is my procedure to save a folder to HDF5, once I've filled the folder tree
//
// called as:
// 	SaveGroupAsHDF5("root:toExport", newfilename[0,7]+".nxs.ngb")
//
Function SaveGroupAsHDF5(dfPath, filename)
	String dfPath	// e.g., "root:FolderA" or ":"
	String filename

	Variable result = 0	// 0 means no error
	
	Variable fileID
	HDF5CreateFile/P=home /O /Z fileID as filename
	if (V_flag != 0)
		Print "HDF5CreateFile failed"
		return -1
	endif

	HDF5SaveGroup /IGOR=0 /O /R /Z $dfPath, fileID, "."
//	HDF5SaveGroup /O /R /Z $dfPath, fileID, "."
	if (V_flag != 0)
		Print "HDF5SaveGroup failed"
		result = -1
	endif
	
	HDF5CloseFile fileID

	return result
End









































/////////////////////////////////////////////////////////////////
///////////////////////////////////////////////
////////////////////////////
//
//
// functions for reading raw data files from the VAX
// - RAW data files are read into the RAW folder - integer data from the detector
//   is decompressed and given the proper orientation
// - header information is placed into real,integer, or text waves in the order they appear
//   in the file header
//
// Work data (DIV File) is read into the DIV folder
//
//*****************************


///// Data in HDF 5 format should NOT be compressed
// TODO -- 
// -- This function is still used in the RealTime reader, which is still looking
//    for VAX files. It has its own special reader, and may never be used with NICE, so
//    commenting it all out may be the final result.
//


//function to take the I*2 data that was read in, in VAX format
//where the integers are "normal", but there are 2-byte record markers
//sprinkled evenly through the data
//there are skipped, leaving 128x128=16384 data values
//the input array (in) is larger than 16384
//(out) is 128x128 data (single precision) as defined in ReadHeaderAndData()
//
// local function to post-process compressed VAX binary data
//
//
xFunction SkipAndDecompressVAX(in,out)
	Wave in,out
	
	Variable skip,ii

	ii=0
	skip=0
	do
		if(mod(ii+skip,1022)==0)
			skip+=1
		endif
		out[ii] = Decompress(in[ii+skip])
		ii+=1
	while(ii<16384)
	return(0)
End

//decompresses each I*2 data value to its real I*4 value
//using the decompression routine written by Jim Ryhne, many moons ago
//
// the compression routine (not shown here, contained in the VAX fortran RW_DATAFILE.FOR) maps I4 to I2 values.
// (back in the days where disk space *really* mattered). the I4toI2 function spit out:
// I4toI2 = I4								when I4 in [0,32767]
// I4toI2 = -777							when I4 in [2,767,000,...]
// I4toI2 mapped to -13277 to -32768 	otherwise
//
// the mapped values [-776,-1] and [-13276,-778] are not used.
// in this compression scheme, only 4 significant digits are retained (to allow room for the exponent)
// technically, the maximum value should be 2,768,499 since this maps to -32768. But this is of
// little consequence. If you have individual pixel values on the detector that are that large, you need
// to re-think your experiment.
//
// local function to post-process compressed VAX binary data
//
//
xFunction Decompress(val)
	Variable val

	Variable i4,npw,ipw,ib,nd

	ib=10
	nd=4
	ipw=ib^nd
	i4=val

	if (i4 <= -ipw) 
		npw=trunc(-i4/ipw)
		i4=mod(-i4,ipw)*(ib^npw)
		return i4
	else
		return i4
	endif
End



/////   ASC FORMAT READER  //////
/////   FOR WORKFILE MATH PANEL //////

//function to read in the ASC output of SANS reduction
// currently the file has 20 header lines, followed by a single column
// of N values, Data is written by row, starting with Y=1 and X=(1->112) or X=(1->128)
//
//returns 0 if read was ok
//returns 1 if there was an error
//
// called by WorkFileUtils.ipf
//
Function ReadASCData(fname,destPath)
	String fname, destPath
	//this function is for reading in ASCII data so put data in user-specified folder
	SetDataFolder "root:Packages:NIST:"+destPath

//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable pixelsX,pixelsY
	if(cmpstr(ksDetType,"Tubes") == 0)
		pixelsX = 112
		pixelsY = 128
	else
		//Ordela
		pixelsX = 128
		pixelsY = 128
	endif
	
	Variable refNum=0,ii,p1,p2,tot,num=pixelsX,numHdrLines=20
	String str=""
	//data is initially linear scale
	Variable/G :gIsLogScale=0
	Make/O/T/N=(numHdrLines) hdrLines
	Make/O/D/N=(pixelsX*pixelsY) data			//,linear_data
	
	//full filename and path is now passed in...
	//actually open the file
//	SetDataFolder destPath
	Open/R/Z refNum as fname		// /Z flag means I must handle open errors
	if(refnum==0)		//FNF error, get out
		DoAlert 0,"Could not find file: "+fname
		Close/A
		SetDataFolder root:
		return(1)
	endif
	if(V_flag!=0)
		DoAlert 0,"File open error: V_flag="+num2Str(V_Flag)
		Close/A
		SetDataFolder root:
		return(1)
	Endif
	// 
	for(ii=0;ii<numHdrLines;ii+=1)		//read (or skip) 18 header lines
		FReadLine refnum,str
		hdrLines[ii]=str
	endfor
	//	
	Close refnum
	
//	SetDataFolder destPath
	LoadWave/Q/G/D/N=temp fName
	Wave/Z temp0=temp0
	data=temp0
	Redimension/N=(pixelsX,pixelsY) data		//,linear_data
	
	Duplicate/O data linear_data
	Duplicate/O data linear_data_error
	linear_data_error = 1 + sqrt(data + 0.75)
	
	//just in case there are odd inputs to this, like negative intensities
	WaveStats/Q linear_data_error
	linear_data_error = numtype(linear_data_error[p][q]) == 0 ? linear_data_error[p][q] : V_avg
	linear_data_error = linear_data_error[p][q] != 0 ? linear_data_error[p][q] : V_avg
	
	//linear_data = data
	
	KillWaves/Z temp0 
	
	//return the data folder to root
	SetDataFolder root:
	
	Return(0)
End

// fills the "default" fake header so that the SANS Reduction machinery does not have to be altered
// pay attention to what is/not to be trusted due to "fake" information.
// uses what it can from the header lines from the ASC file (hdrLines wave)
//
// destFolder is of the form "myGlobals:WorkMath:AAA"
//
//
// called by WorkFileUtils.ipf
//
//
// SRK JUL 2021 -- for now, leave this as-is with the RealsRead references
//
// I will likely need to replace this somehow, but I'm not sure yet. It may be as simple (tedious)
// as defining all of the "put" statements
//
Function FillFakeHeader_ASC(destFolder)
	String destFolder
	
	
	//Put in appropriate "fake" values using "put" commands, or write directly
	
	
	// fill in the data
	Wave data=$("root:Packages:NIST:"+destFolder+":data")
	Wave destData = $("root:Packages:NIST:"+destFolder+":entry:instrument:detector:data")
	destData=data

// and the data error
	Wave data_err=$("root:Packages:NIST:"+destFolder+":linear_data_error")
	Wave destData_err = $("root:Packages:NIST:"+destFolder+":entry:instrument:detector:data_error")
	destData_err=data_err

	Variable nx, ny
	if(cmpstr(ksDetType,"Tubes")==0)
		// tube values
		nx = 112
		ny = 128
	else
		//Ordela values
		nx = 128
		ny = 128
	endif		
	
	// pixel numbers - x and y
	putDet_pixel_num_x(destFolder,nx)
	putDet_pixel_num_y(destFolder,ny)
	
	//parse values as needed from headerLines
	Wave/T hdr=$("root:Packages:NIST:"+destFolder+":hdrLines")
	Variable monCt,lam,offset,sdd,trans,thick
	Variable xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam
	String detTyp=""
	String tempStr="",formatStr="",junkStr=""
	formatStr = "%g %g %g %g %g %g"
	tempStr=hdr[3]
	sscanf tempStr, formatStr, monCt,lam,offset,sdd,trans,thick
//	Print monCt,lam,offset,sdd,trans,thick,avStr,step
	formatStr = "%g %g %g %g %g %g %g %s"
	tempStr=hdr[5]
	sscanf tempStr,formatStr,xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam,detTyp
//	Print xCtr,yCtr,a1,a2,a1a2Dist,dlam,bsDiam,detTyp


	String fname = destFolder		//for convenience

	putDet_beam_center_x(fname,xCtr)		//pixels
	putDet_beam_center_y(fname,yCtr)	
	putDet_distance(fname,sdd*100)		//convert [m] to [cm]
	putWavelength(fname,lam)
	
	//
	// necessary values
	//detector calibration constants, needed for averaging
	// these are filled in when the Nexus structure is generated (top of this function)

	//
	// used in the resolution calculation, ONLY here to keep the routine from crashing
	
//	realw[20]=65		//det size
	
	putBeamStop_size(fname,bsDiam)		//should be in [cm]
	putWavelength_spread(fname,dlam)
	putSourceAp_size(fname,num2str(a1)+" mm")		//should be in [mm] diameter
	putSampleAp_size(fname,a2)		//shoudlbe in [mm]
	putSourceAp_distance(fname,a1a2Dist*100)	//store value in [cm]
	putSampleThickness(fname,thick)
	putSampleTransmission(fname,trans)
	
	//
	//
	putBeamMonNorm_data(fname,monCt)

	// fake values to get valid deadtime and detector constants
	//
//	textw[9]=detTyp+"  "		//6 characters 4+2 spaces
//	textw[3]="[NGxSANS00]"	//11 chars, NGx will return default values for atten trans, deadtime... 
	
	//set the string values
	formatStr="FILE: %s CREATED: %s"
	sscanf hdr[0],formatStr,tempStr,junkStr
//	Print tempStr
//	Print junkStr
	String/G $("root:Packages:NIST:"+destFolder+":fileList") = tempStr
//	textw[0] = tempStr		//filename
//	textw[1] = junkStr		//run date-time
	
	//file label = hdr[1]
	tempStr = hdr[1]
	tempStr = tempStr[0,strlen(tempStr)-2]		//clean off the last LF
	putSampleDescription(fname,tempStr)
	
	
	// now do the non-linear calculation so that the real space distance waves are present
	// and the 2D data can be displayed
	
	// hard-wire since the data is in a sub-folder, and the extra colon in the path
	// causes problems with using the get functions
	String destPath = "root:Packages:NIST:"+destFolder
	Wave w = $(destPath + ":entry:instrument:detector:data")
	Wave W_calib = $(destPath + ":entry:instrument:detector:spatial_calibration")
	Wave tmp = $(destPath + ":entry:instrument:detector:tube_width")
	Variable tube_width = tmp[0]
	NonLinearCorrection(fname,w,w_calib,tube_width,destPath)
//	

				
	
	return(0)
End


/////*****************
////unused testing procedure for writing a 4 byte floating point value in VAX format
//Proc TestReWriteReal()
//	String Path
//	Variable value,start
//	
//	GetFileAndPath()
//	Path = S_Path + S_filename
//	
//	value = 0.2222
//	start = 158		//trans starts at byte 159
//	ReWriteReal(path,value,start)
//	
//	SetDataFolder root:
//End

//function will re-write a real value (4bytes) to the header of a RAW data file
//to ensure re-readability, the real value must be written mimicking VAX binary format
//which is done in this function
//path is the full path:file;vers to the file
//value is the real value to write
//start is the position to move the file marker to, to begin writing
//--so start is actually the "end byte" of the previous value
//
// Igor cannot write VAX FP values - so to "fake it"
// (1) write IEEE FP, 4*desired value, little endian
// (2) read back as two 16-bit integers, big endian
// (3) write the two 16-bit integers, reversed, writing each as big endian
//
//this procedure takes care of all file open/close pairs needed
//
Function WriteVAXReal(path,value,start)
	String path
	Variable value,start
	
	//Print " in F(), path = " + path
	Variable refnum,int1,int2, value4

//////
	value4 = 4*value
	
	Open/A/T="????TEXT" refnum as path
	//write IEEE FP, 4*desired value
	FSetPos refnum,start
	FBinWrite/B=3/F=4 refnum,value4		//write out as little endian
	//move to the end of the file
	FStatus refnum
	FSetPos refnum,V_logEOF	
	Close refnum
	
///////
	Open/R refnum as path
	//read back as two 16-bit integers
	FSetPos refnum,start
	FBinRead/B=2/F=2 refnum,int1	//read as big-endian
	FBinRead/B=2/F=2 refnum,int2	
	//file was opened read-only, no need to move to the end of the file, just close it	
	Close refnum
	
///////
	Open/A/T="????TEXT" refnum as path
	//write the two 16-bit integers, reversed
	FSetPos refnum,start
	FBinWrite/B=2/F=2 refnum,int2	//re-write as big endian
	FBinWrite/B=2/F=2 refnum,int1
	//move to the end of the file
	FStatus refnum
	FSetPos refnum,V_logEOF
	Close refnum		//at this point, it is as the VAX would have written it. 
	
	Return(0)
End




Function KillNamedDataFolder(fname)
	String fname
	
	Variable err=0
	
	String folderStr = N_GetFileNameFromPathNoSemi(fname)
	folderStr = RemoveDotExtension(folderStr)
	
	KillDataFolder/Z $("root:"+folderStr)
	err = V_flag
	
	return(err)
end






//////////////////////////////////////////////////////////////////////////////////








////// OCT 2009, facility specific bits from MonteCarlo functions()
//"type" is the data folder that has the data array that is to be (re)written as a full
// data file, as if it was a raw data file
//
Function/S Write_RawData_File(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name

	String filename = ""
	filename = Write_VAXRaw_Data(type,fullpath,dialog)
	
	return(filename)
End

// given a data folder, write out the corresponding VAX binary data file.
//
// I don't think that I can generate a STRUCT and then lay that down - since the
// VAX FP format has to be duplicated with a write/read/flip/re-write dance...
//
// seems to work correctly byte for byte
// compression has been implmented also, for complete replication of the format (n>32767 in a cell)
//
// SRK 29JAN09
//
// other functions needed:
//
//
// one to generate a fake data file name, and put the matching name in the data header
// !! must fake the Annn suffix too! this is used...
// use a prefix, keep a run number, initials SIM, and alpha as before (start randomly, don't bother changing?)
//
// for right now, keep a run number, and generate
// PREFIXnnn.SA2_SIM_Annn
// also, start the index @ 100 to avoid leading zeros (although I have the functions available)

// one to generate the date/time string in VAX format, right # characters// Print Secs2Time(DateTime,3)				// Prints 13:07:29
// Print Secs2Time(DateTime,3)				// Prints 13:07:29
//	Print Secs2Date(DateTime,-2)		// 1993-03-14			//this call is independent of System date/time!//
//
//
// simulation should call as ("SAS","",0) to bypass the dialog, and to fill the header
// this could be modified in the future to be more generic
//
///
// changed to return the string w/ the filename as written for later use
//
//
//
// ***JAN 2022 ***
//
// -- need to replace this call (or the bits of it) to use the new Nexus file
// structure and calls -- and then write out the Nexus (HDF group) rather than the VAX format
//
//
Function/S Write_VAXRaw_Data(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	String destStr=""
	Variable refNum,ii,val,err
	
	
	destStr = "root:Packages:NIST:"+type
	
	SetDataFolder $destStr
	WAVE intw=integersRead
	WAVE rw=realsRead
	WAVE/T textw=textRead
	
	WAVE linear_data = linear_data
	Duplicate/O linear_data tmp_data
		
	NVAR/Z rawCts = root:Packages:NIST:SAS:gRawCounts
	if(cmpstr("SAS",type)==0 && !rawCts)		//simulation data, and is not RAW counts, so scale it back

		//use kappa to get back to counts => linear_data = round(linear_data*kappa)
		String strNote = note(linear_data) 
		Variable kappa = NumberByKey("KAPPA", strNote , "=", ";")
		NVAR detectorEff = root:Packages:NIST:SAS:g_detectorEff

		tmp_data *= kappa
		tmp_data *= detectorEff
//		Print kappa, detectorEff
		Redimension/I tmp_data
	endif
	
	WAVE w=tmp_data

	// check for data values that are too large. the maximum VAX compressed data value is 2767000
	//
	WaveStats/Q w
	if(V_max > 2767000)
		Abort "Some individual pixel values are > 2767000 and the data can't be saved in VAX format"
	Endif
	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist WriteVAXData()"
	Endif
	If(!(WaveExists(w)))
		Abort "linear_data DNExist WriteVAXData()"
	Endif
	
	
//	if(dialog)
//		PathInfo/S catPathName
//		fullPath = DoSaveFileDialog("Save data as")
//		If(cmpstr(fullPath,"")==0)
//			//user cancel, don't write out a file
//			Close/A
//			Abort "no data file was written"
//		Endif
//		//Print "dialog fullpath = ",fullpath
//	Endif
	
	// save to home, or get out
	//
	PathInfo home
	if(V_flag	== 0)
		Abort "no save path defined. Save the experiment to generate a home path"
	endif
	
	fullPath = S_path		//not the full path yet, still need the name, after the header is filled
	
	
	Make/O/B/U/N=33316 tmpFile		//unsigned integers for a blank data file
	tmpFile=0
	
//	Make/O/W/N=16401 dataWRecMarkers			// don't convert to 16 bit here, rather write to file as 16 bit later
	Make/O/I/N=16401 dataWRecMarkers
	AddRecordMarkers(w,dataWRecMarkers)
		
	// need to re-compress?? maybe never a problem, but should be done for the odd case
	dataWRecMarkers = CompressI4toI2(dataWRecMarkers)		//unless a pixel value is > 32767, the same values are returned
	
	// fill the last bits of the header information
	err = SimulationVAXHeader(type)		//if the type != 'SAS', this function does nothing
	
	if (err == -1)
		Abort "no sample label entered - no file written"			// User did not fill in header correctly/completely
	endif
	fullPath = fullPath + textW[0]
	
	// lay down a blank file
	Open refNum as fullpath
		FBinWrite refNum,tmpFile			//file is the right size, but all zeroes
	Close refNum
	
	// fill up the header
	// text values
	// elements of textW are already the correct length set by the read, but just make sure
	String str
	
	if(strlen(textw[0])>21)
		textw[0] = (textw[0])[0,20]
	endif
	if(strlen(textw[1])>20)
		textw[1] = (textw[1])[0,19]
	endif
	if(strlen(textw[2])>3)
		textw[2] = (textw[2])[0,2]
	endif
	if(strlen(textw[3])>11)
		textw[3] = (textw[3])[0,10]
	endif
	if(strlen(textw[4])>1)
		textw[4] = (textw[4])[0]
	endif
	if(strlen(textw[5])>8)
		textw[5] = (textw[5])[0,7]
	endif
	if(strlen(textw[6])>60)
		textw[6] = (textw[6])[0,59]
	endif
	if(strlen(textw[7])>6)
		textw[7] = (textw[7])[0,5]
	endif
	if(strlen(textw[8])>6)
		textw[8] = (textw[8])[0,5]
	endif
	if(strlen(textw[9])>6)
		textw[9] = (textw[9])[0,5]
	endif
	if(strlen(textw[10])>42)
		textw[10] = (textw[10])[0,41]
	endif	
	
	ii=0
	Open/A/T="????TEXT" refnum as fullpath      //Open for writing! Move to EOF before closing!
		str = textW[ii]
		FSetPos refnum,2							////file name
		FBinWrite/F=0 refnum, str      //native object format (character)
		ii+=1
		str = textW[ii]
		FSetPos refnum,55							////date/time
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,75							////type
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,78						////def dir
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,89						////mode
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,90						////reserve
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,98						////@98, sample label
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,202						//// T units
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,208						//// F units
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,214						////det type
		FBinWrite/F=0 refnum, str
		ii+=1
		str = textW[ii]
		FSetPos refnum,404						////reserve
		FBinWrite/F=0 refnum, str
	
		//move to the end of the file before closing
		FStatus refnum
		FSetPos refnum,V_logEOF
	Close refnum
	
	
	// integer values (4 bytes)
	ii=0
	Open/A/T="????TEXT" refnum as fullpath      //Open for writing! Move to EOF before closing!
		val = intw[ii]
		FSetPos refnum,23							//nprefactors
		FBinWrite/B=3/F=3 refnum, val      //write a 4-byte integer
		ii+=1
		val=intw[ii]
		FSetPos refnum,27							//ctime
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,31							//rtime
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,35							//numruns
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,174							//table
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,178							//holder
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,182							//blank
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,194							//tctrlr
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,198							//magnet
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,244							//det num
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,248							//det spacer
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,308							//tslice mult
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,312							//tsclice ltslice
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,332							//extra
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,336							//reserve
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,376							//blank1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,380							//blank2
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,384							//blank3
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,458							//spacer
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,478							//box x1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,482							//box x2
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,486							//box y1
		FBinWrite/B=3/F=3 refnum, val
		ii+=1
		val=intw[ii]
		FSetPos refnum,490							//box y2
		FBinWrite/B=3/F=3 refnum, val
		
		//move to the end of the file before closing
		FStatus refnum
		FSetPos refnum,V_logEOF
	Close refnum
	
		
	//VAX 4-byte FP values. No choice here but to write/read/re-write to get 
	// the proper format. there are 52! values to write
	//WriteVAXReal(fullpath,rw[n],start)
	// [0]
	WriteVAXReal(fullpath,rw[0],39)
	WriteVAXReal(fullpath,rw[1],43)
	WriteVAXReal(fullpath,rw[2],47)
	WriteVAXReal(fullpath,rw[3],51)
	WriteVAXReal(fullpath,rw[4],158)
	WriteVAXReal(fullpath,rw[5],162)
	WriteVAXReal(fullpath,rw[6],166)
	WriteVAXReal(fullpath,rw[7],170)
	WriteVAXReal(fullpath,rw[8],186)
	WriteVAXReal(fullpath,rw[9],190)
	// [10]
	WriteVAXReal(fullpath,rw[10],220)
	WriteVAXReal(fullpath,rw[11],224)
	WriteVAXReal(fullpath,rw[12],228)
	WriteVAXReal(fullpath,rw[13],232)
	WriteVAXReal(fullpath,rw[14],236)
	WriteVAXReal(fullpath,rw[15],240)
	WriteVAXReal(fullpath,rw[16],252)
	WriteVAXReal(fullpath,rw[17],256)
	WriteVAXReal(fullpath,rw[18],260)
	WriteVAXReal(fullpath,rw[19],264)
	// [20]
	WriteVAXReal(fullpath,rw[20],268)
	WriteVAXReal(fullpath,rw[21],272)
	WriteVAXReal(fullpath,rw[22],276)
	WriteVAXReal(fullpath,rw[23],280)
	WriteVAXReal(fullpath,rw[24],284)
	WriteVAXReal(fullpath,rw[25],288)
	WriteVAXReal(fullpath,rw[26],292)
	WriteVAXReal(fullpath,rw[27],296)
	WriteVAXReal(fullpath,rw[28],300)
	WriteVAXReal(fullpath,rw[29],320)
	// [30]
	WriteVAXReal(fullpath,rw[30],324)
	WriteVAXReal(fullpath,rw[31],328)
	WriteVAXReal(fullpath,rw[32],348)
	WriteVAXReal(fullpath,rw[33],352)
	WriteVAXReal(fullpath,rw[34],356)
	WriteVAXReal(fullpath,rw[35],360)
	WriteVAXReal(fullpath,rw[36],364)
	WriteVAXReal(fullpath,rw[37],368)
	WriteVAXReal(fullpath,rw[38],372)
	WriteVAXReal(fullpath,rw[39],388)
	// [40]
	WriteVAXReal(fullpath,rw[40],392)
	WriteVAXReal(fullpath,rw[41],396)
	WriteVAXReal(fullpath,rw[42],400)
	WriteVAXReal(fullpath,rw[43],450)
	WriteVAXReal(fullpath,rw[44],454)
	WriteVAXReal(fullpath,rw[45],470)
	WriteVAXReal(fullpath,rw[46],474)
	WriteVAXReal(fullpath,rw[47],494)
	WriteVAXReal(fullpath,rw[48],498)
	WriteVAXReal(fullpath,rw[49],502)
	// [50]
	WriteVAXReal(fullpath,rw[50],506)
	WriteVAXReal(fullpath,rw[51],510)
	
	
	// write out the data
	Open refNum as fullpath
		FSetPos refnum,514					//  OK
		FBinWrite/F=2/B=3 refNum,dataWRecMarkers		//don't trust the native format
		FStatus refNum
		FSetPos refNum,V_logEOF
	Close refNum
	
	// all done
	Killwaves/Z tmpFile,dataWRecMarkers,tmp_data
	
	Print "Saved VAX binary data as:  ",textW[0]
	SetDatafolder root:
	return(fullpath)
End


Function AddRecordMarkers(in,out)
	Wave in,out
	
	Variable skip,ii

//	Duplicate/O in,out
//	Redimension/N=16401 out

	out=0
	
	ii=0
	skip=0
	out[ii] = 1
	ii+=1
	do
		if(mod(ii+skip,1022)==0)
			out[ii+skip] = 0		//999999
			skip+=1			//increment AFTER filling the current marker
		endif
		out[ii+skip] = in[ii-1]
		ii+=1
	while(ii<=16384)
	
	
	return(0)
End




//        INTEGER*2 FUNCTION I4ToI2(I4)
//C
//C       Original author : Jim Rhyne
//C       Modified by     : Frank Chen 09/26/90
//C
//C       I4ToI2 = I4,                            I4 in [0,32767]
//C       I4ToI2 = -777,                          I4 in (2767000,...)
//C       I4ToI2 mapped to -13277 to -32768,      otherwise
//C
//C       the mapped values [-776,-1] and [-13276,-778] are not used
//C
//C       I4max should be 2768499, this value will maps to -32768
//C       and mantissa should be compared  using 
//C               IF (R4 .GE. IPW)
//C       instead of
//C               IF (R4 .GT. (IPW - 1.0))
//C
//
//
//C       I4      :       input I*4
//C       R4      :       temperory real number storage
//C       IPW     :       IPW = IB ** ND
//C       NPW     :       number of power
//C       IB      :       Base value
//C       ND      :       Number of precision digits
//C       I4max   :       max data value w/ some error
//C       I2max   :       max data value w/o error
//C       Error   :       when data value > I4max
//C
//        INTEGER*4       I4
//        INTEGER*4       NPW
//        REAL*4          R4
//        INTEGER*4       IPW
//        INTEGER*4       IB      /10/
//        INTEGER*4       ND      /4/
//        INTEGER*4       I4max   /2767000/
//        INTEGER*4       I2max   /32767/
//        INTEGER*4       Error   /-777/
//
Function CompressI4toI2(i4)
	Variable i4

	Variable npw,ipw,ib,nd,i4max,i2max,error,i4toi2
	Variable r4
	
	ib=10
	nd=4
	i4max=2767000
	i2max=32767
	error=-777
	
	if(i4 <= i4max)
		r4=i4
		if(r4 > i2max)
			ipw = ib^nd
			npw=0
			do
				if( !(r4 > (ipw-1)) )		//to simulate a do-while loop evaluating at top
					break
				endif
				npw=npw+1
				r4=r4/ib		
			while (1)
			i4toi2 = -1*trunc(r4+ipw*npw)
		else
			i4toi2 = trunc(r4)		//shouldn't I just return i4 (as a 2 byte value?)
		endif
	else
		i4toi2=error
	endif
	return(i4toi2)
End


// function to fill the extra bits of header information to make a "complete"
// simulated VAX data file.
//
// NCNR-Specific. is hard wired to the SAS folder. If saving from any other folder, set all of the header
// information before saving, and pass a null string to this procedure to bypass it entirely
//
Function SimulationVAXHeader(folder)
	String folder

	if(cmpstr(folder,"SAS")!=0)		//if not the SAS folder passed in, get out now, and return 1 (-1 is the error condition)
		return(1)
	endif
	
	Wave rw=root:Packages:NIST:SAS:realsRead
	Wave iw=root:Packages:NIST:SAS:integersRead
	Wave/T tw=root:Packages:NIST:SAS:textRead
	Wave res=root:Packages:NIST:SAS:results
	
// integers needed:
	//[2] count time
	NVAR ctTime = root:Packages:NIST:SAS:gCntTime
	iw[2] = ctTime
	
//reals are partially set in SASCALC initializtion
	//remaining values are updated automatically as SASCALC is modified
	// -- but still need:
	//	[0] monitor count
	//	[2] detector count (w/o beamstop)
	//	[4] transmission
	//	[5] thickness (in cm)
	NVAR imon = root:Packages:NIST:SAS:gImon
	rw[0] = imon
	rw[2] = res[9]
	rw[4] = res[8]
	NVAR thick = root:Packages:NIST:SAS:gThick
	rw[5] = thick
	
// text values needed:
// be sure they are padded to the correct length
	// [0] filename (do I fake a VAX name? probably yes...)
	// [1] date/time in VAX format
	// [2] type (use SIM)
	// [3] def dir (use [NG7SANS99])
	// [4] mode? C
	// [5] reserve (another date), prob not needed
	// [6] sample label
	// [9] det type "ORNL  " (6 chars)

	SVAR gInstStr = root:Packages:NIST:SAS:gInstStr
		
	tw[1] = Secs2Date(DateTime,-2)+"  "+ Secs2Time(DateTime,3) 		//20 chars, not quite VAX format
	tw[2] = "SIM"
	tw[3] = "["+gInstStr+"SANS99]"
	tw[4] = "C"
	tw[5] = "01JAN09 "
	tw[9] = "ORNL  "
	
	
	//get the run index and the sample label from the optional parameters, or from a dialog
	NVAR index = root:Packages:NIST:SAS:gSaveIndex
	SVAR prefix = root:Packages:NIST:SAS:gSavePrefix
// did the user pass in values?
	NVAR autoSaveIndex = root:Packages:NIST:SAS:gAutoSaveIndex
	SVAR autoSaveLabel = root:Packages:NIST:SAS:gAutoSaveLabel
	
	String labelStr=""	
	Variable runNum
	if( (autoSaveIndex != 0) && (strlen(autoSaveLabel) > 0) )
		// all is OK, proceed with the save
		labelStr = autoSaveLabel
		runNum = autoSaveIndex		//user must take care of incrementing this!
	else
		//one or the other, or both are missing, so ask
		runNum = index
		Prompt labelStr, "Enter sample label "		// Set prompt for x param
		Prompt runNum,"Run Number (automatically increments)"
		DoPrompt "Enter sample label", labelStr,runNum
		if (V_Flag)
			//Print "no sample label entered - no file written"
			//index -=1
			return -1								// User canceled
		endif
		if(runNum != index)
			index = runNum
		endif
		index += 1
	endif
	
	//make a three character string of the run number
	String numStr=""
	if(runNum<10)
		numStr = "00"+num2str(runNum)
	else
		if(runNum<100)
			numStr = "0"+num2str(runNum)
		else
			numStr = num2str(runNum)
		Endif
	Endif
	//date()[0] is the first letter of the day of the week
	// OK for most cases, except for an overnight simulation! then the suffix won't sort right...
//	tw[0] = prefix+numstr+".SA2_SIM_"+(date()[0])+numStr

//fancier, JAN=A, FEB=B, etc...
	String timeStr= secs2date(datetime,-1)
	String monthStr=StringFromList(1, timeStr  ,"/")

	tw[0] = prefix+numstr+".SA2_SIM_"+(num2char(str2num(monthStr)+64))+numStr
	
	labelStr = PadString(labelStr,60,0x20) 	//60 fortran-style spaces
	tw[6] = labelStr[0,59]
	
	return(0)
End

Function ExamineHeader(type)
	String type

	String data_folder = type
	String dataPath = "root:Packages:NIST:"+data_folder
	String cur_folder = "ExamineHeader"
	String curPath = "root:Packages:NIST:"+cur_folder
	
	//SetDataFolder curPath

	Wave intw=$(dataPath+":IntegersRead")
	Wave realw=$(dataPath+":RealsRead")
	Wave/T textw=$(dataPath+":TextRead")
	Wave logw=$(dataPath+":LogicalsRead")


	print "----------------------------------"
	print "Header Details"
	print "----------------------------------"
	print "fname :\t\t"+textw[0]
	//
	print "run.npre :\t\t"+num2str(intw[0])
	print "run.ctime :\t\t"+num2str(intw[1])
	print "run.rtime :\t\t"+num2str(intw[2])
	print "run.numruns :\t\t"+num2str(intw[3])
	//
	print "run.moncnt :\t\t"+num2str(realw[0])
	print "run.savmon :\t\t"+num2str(realw[1])
	print "run.detcnt :\t\t"+num2str(realw[2])
	print "run.atten :\t\t"+num2str(realw[3])	
	//
	print "run.timdat:\t\t"+textw[1]
	print "run.type:\t\t"+textw[2]
	print "run.defdir:\t\t"+textw[3]
	print "run.mode:\t\t"+textw[4]
	print "run.reserve:\t\t"+textw[5]
	print "sample.labl:\t\t"+textw[6]
	//
	print "sample.trns:\t\t"+num2str(realw[4])
	print "sample.thk:\t\t"+num2str(realw[5])
	print "sample.position:\t\t"+num2str(realw[6])
	print "sample.rotang:\t\t"+num2str(realw[7])
	//
	print "sample.table:\t\t"+num2str(intw[4])
	print "sample.holder:\t\t"+num2str(intw[5])
	print "sample.blank:\t\t"+num2str(intw[6])
	//
	print "sample.temp:\t\t"+num2str(realw[8])
	print "sample.field:\t\t"+num2str(realw[9])	
	//
	print "sample.tctrlr:\t\t"+num2str(intw[7])
	print "sample.magnet:\t\t"+num2str(intw[8])
	//
	print "sample.tunits:\t\t"+textw[7]
	print "sample.funits:\t\t"+textw[8]
	print "det.typ:\t\t"+textw[9]
	//
	print "det.calx(1):\t\t"+num2str(realw[10])
	print "det.calx(2):\t\t"+num2str(realw[11])
	print "det.calx(3):\t\t"+num2str(realw[12])
	print "det.caly(1):\t\t"+num2str(realw[13])
	print "det.caly(2):\t\t"+num2str(realw[14])
	print "det.caly(3):\t\t"+num2str(realw[15])
	//
	print "det.num:\t\t"+num2str(intw[9])
	print "det.spacer:\t\t"+num2str(intw[10])
	//
	print "det.beamx:\t\t"+num2str(realw[16])
	print "det.beamy:\t\t"+num2str(realw[17])
	print "det.dis:\t\t"+num2str(realw[18])
	print "det.offset:\t\t"+num2str(realw[19])
	print "det.siz:\t\t"+num2str(realw[20])
	print "det.bstop:\t\t"+num2str(realw[21])
	print "det.blank:\t\t"+num2str(realw[22])
	print "resolution.ap1:\t\t"+num2str(realw[23])
	print "resolution.ap2:\t\t"+num2str(realw[24])
	print "resolution.ap12dis:\t\t"+num2str(realw[25])
	print "resolution.lmda:\t\t"+num2str(realw[26])
	print "resolution.dlmda:\t\t"+num2str(realw[27])
	print "resolution.nlenses:\t\t"+num2str(realw[28])	
	//
	print "tslice.slicing:\t\t"+num2str(logw[0])
	//
	print "tslice.multfact:\t\t"+num2str(intw[11])
	print "tslice.ltslice:\t\t"+num2str(intw[12])
	//
	print "temp.printemp:\t\t"+num2str(logw[1])
	//
	print "temp.hold:\t\t"+num2str(realw[29])
	print "temp.err:\t\t"+num2str(realw[30])
	print "temp.blank:\t\t"+num2str(realw[31])
	//
	print "temp.extra:\t\t"+num2str(intw[13])
	print "temp.err:\t\t"+num2str(intw[14])
	//
	print "magnet.printmag:\t\t"+num2str(logw[2])
	print "magnet.sensor:\t\t"+num2str(logw[3])
	//
	print "magnet.current:\t\t"+num2str(realw[32])
	print "magnet.conv:\t\t"+num2str(realw[33])
	print "magnet.fieldlast:\t\t"+num2str(realw[34])
	print "magnet.blank:\t\t"+num2str(realw[35])
	print "magnet.spacer:\t\t"+num2str(realw[36])
	print "bmstp.xpos:\t\t"+num2str(realw[37])
	print "bmstop.ypos:\t\t"+num2str(realw[38])
	//	
	print "params.blank1:\t\t"+num2str(intw[15])
	print "params.blank2:\t\t"+num2str(intw[16])
	print "params.blank3:\t\t"+num2str(intw[17])
	//
	print "params.trnscnt:\t\t"+num2str(realw[39])
	print "params.extra1:\t\t"+num2str(realw[40])
	print "params.extra2:\t\t"+num2str(realw[41])
	print "params.extra3:\t\t"+num2str(realw[42])
	//	
	print "params.reserve:\t\t"+textw[10]
	//
	print "voltage.printemp:\t\t"+num2str(logw[4])
	//
	print "voltage.volts:\t\t"+num2str(realw[43])
	print "voltage.blank:\t\t"+num2str(realw[44])
	//	
	print "voltage.spacer:\t\t"+num2str(intw[18])
	//
	print "polarization.printpol:\t\t"+num2str(logw[5])
	print "polarization.flipper:\t\t"+num2str(logw[6])
	//	
	print "polarization.horiz:\t\t"+num2str(realw[45])
	print "polarization.vert:\t\t"+num2str(realw[46])
	//
	print "analysis.rows(1):\t\t"+num2str(intw[19])
	print "analysis.rows(2):\t\t"+num2str(intw[20])
	print "analysis.cols(1):\t\t"+num2str(intw[21])
	print "analysis.cols(2):\t\t"+num2str(intw[22])
	//
	print "analysis.factor:\t\t"+num2str(realw[47])
	print "analysis.qmin:\t\t"+num2str(realw[48])
	print "analysis.qmax:\t\t"+num2str(realw[49])
	print "analysis.imin:\t\t"+num2str(realw[50])
	print "analysis.imax:\t\t"+num2str(realw[51])

End



////// OCT 2009, facility specific bits from ProDiv()
//"type" is the data folder that has the corrected, patched, and normalized DIV data array
//
// the header of this file is rather unimportant. Filling in a title at least would be helpful/
//
Function Write_DIV_File()
	String type
	
	// Your file writing function here. Don't try to duplicate the VAX binary format...
	WriteVAXWorkFile(type)
	
	//

	
	
	return(0)
End

//writes an VAX-style WORK file, "exactly" as it would be output from the VAX
//except for the "dummy" header and the record markers - the record marker bytes are
// in the files - they are just written as zeros and are meaningless
//file is:
//	516 bytes header
// 128x128=16384 (x4) bytes of data 
// + 2 byte record markers interspersed just for fun
// = 66116 bytes
//prompts for name of the output file.
//
Function WriteVAXWorkFile(type)
	String type
	
	Wave data = getDetectorDataW(type)		//this will be the linear data
	
	Variable refnum,ii=0,hdrBytes=516,a,b,offset
	String fullpath=""
	
	Duplicate/O data,tempData
	Redimension/S/N=(128*128) tempData
	tempData *= 4
	
	PathInfo/S catPathName
	fullPath = DoSaveFileDialog("Save data as")	  //won't actually open the file
	If(cmpstr(fullPath,"")==0)
		//user cancel, don't write out a file
	  Close/A
	  Abort "no data file was written"
	Endif
	
	Make/B/O/N=(hdrBytes) hdrWave
	hdrWave=0
	FakeDIVHeader(hdrWave)
	
	Make/Y=2/O/N=(510) bw510		//Y=2 specifies 32 bit (=4 byte) floating point
	Make/Y=2/O/N=(511) bw511
	Make/Y=2/O/N=(48) bw48

	Make/O/B/N=2 recWave		//two bytes

	//actually open the file
	Open/C="????"/T="TEXT" refNum as fullpath
	FSetPos refNum, 0
	//write header bytes (to be skipped when reading the file later)
	
	FBinWrite /F=1 refnum,hdrWave
	
	ii=0
	a=0
	do
		//write 511 4-byte values (little-endian order), 4* true value
		bw511[] = tempData[p+a]
		FBinWrite /B=3/F=4 refnum,bw511
		a+=511
		//write a 2-byte record marker
		FBinWrite refnum,recWave
		
		//write 510 4-byte values (little-endian) 4* true value
		bw510[] = tempData[p+a]
		FBinWrite /B=3/F=4 refnum,bw510
		a+=510
		
		//write a 2-byte record marker
		FBinWrite refnum,recWave
		
		ii+=1	
	while(ii<16)
	//write out last 48  4-byte values (little-endian) 4* true value
	bw48[] = tempData[p+a]
	FBinWrite /B=3/F=4 refnum,bw48
	//close the file
	Close refnum
	
	//go back through and make it look like a VAX datafile
	Make/W/U/O/N=(511*2) int511		// /W=16 bit signed integers /U=unsigned
	Make/W/U/O/N=(510*2) int510
	Make/W/U/O/N=(48*2) int48
	
	//skip the header for now
	Open/A/T="????TEXT" refnum as fullPath
	FSetPos refnum,0
	
	offset=hdrBytes
	ii=0
	do
		//511*2 integers
		FSetPos refnum,offset
		FBinRead/B=2/F=2 refnum,int511
		Swap16BWave(int511)
		FSetPos refnum,offset
		FBinWrite/B=2/F=2 refnum,int511
		
		//skip 511 4-byte FP = (511*2)*2 2byte int  + 2 bytes record marker
		offset += 511*2*2 + 2
		
		//510*2 integers
		FSetPos refnum,offset
		FBinRead/B=2/F=2 refnum,int510
		Swap16BWave(int510)
		FSetPos refnum,offset
		FBinWrite/B=2/F=2 refnum,int510
		
		//
		offset += 510*2*2 + 2
		
		ii+=1
	while(ii<16)
	//48*2 integers
	FSetPos refnum,offset
	FBinRead/B=2/F=2 refnum,int48
	Swap16BWave(int48)
	FSetPos refnum,offset
	FBinWrite/B=2/F=2 refnum,int48

	//move to EOF and close
	FStatus refnum
	FSetPos refnum,V_logEOF
	
	Close refnum
	
	Killwaves/Z hdrWave,bw48,bw511,bw510,recWave,temp16,int511,int510,int48
End

// given a 16 bit integer wave, read in as 2-byte pairs of 32-bit FP data
// swap the order of the 2-byte pairs
// 
Function Swap16BWave(w)
	Wave w

	Duplicate/O w,temp16
	//Variable num=numpnts(w),ii=0

	//elegant way to swap even/odd values, using wave assignments
	w[0,*;2] = temp16[p+1]
	w[1,*;2] = temp16[p-1]

//crude way, using a loop	
//	for(ii=0;ii<num;ii+=2)
//		w[ii] = temp16[ii+1]
//		w[ii+1] = temp16[ii]
//	endfor
	
	return(0)	
End

// writes a fake label into the header of the DIV file
//
Function FakeDIVHeader(hdrWave)
	WAVE hdrWave
	
	//put some fake text into the sample label position (60 characters=60 bytes)
	String day=date(),tim=time(),lbl=""
	Variable start=98,num,ii
	
	lbl = "Sensitivity (DIV) created "+day +" "+tim
	num=strlen(lbl)
	for(ii=0;ii<num;ii+=1)
		hdrWave[start+ii] = char2num(lbl[ii])
	endfor

	return(0)
End

////////end of ProDiv() specifics






