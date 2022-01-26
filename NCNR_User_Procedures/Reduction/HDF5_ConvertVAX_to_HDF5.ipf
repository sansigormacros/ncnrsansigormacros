#pragma rtGlobals=1		// Use modern global access method.

///
//
// JAN 2022
// This file needs to be modified to convert VAX data to the new Nexus format
// as best at possible. This file must be included in the "regular" VAX reduction
// procedures so that the conversion can be done
//
// TODO:
// -- update the tree structure to match the new Nexus
// -- update the corresponding RTI data to fill in
// -- update the writer so a proper HDF file can be written
// -- do I need to change the file name or extension?
//
//
// -- for testing, how can I get data to test the DIV Read/Write/Generation?
//		do I have old VAX data for this?
//
// -- how do I best truncate the detector data? 
// -- how will this affect my comparison to the VAX-reduced data?
//
//
// ** I had to move some of the declarations -- compiler
// complained that it was the wrong type (sample_aperture:shape:size declared as /D
// -- but it's in a different data folder???)
// -- is it because it's in the same function?





//
//
//
// converts the VAX format as read into RAW into an HDF5 file
//




// lays out the tree

Function SetupStructure()

	SetDataFolder root:
	
	NewDataFolder/O root:toExport
	NewDataFolder/O root:toExport:entry
	NewDataFolder/O root:toExport:entry:control
	NewDataFolder/O root:toExport:entry:data
	NewDataFolder/O root:toExport:entry:instrument
	NewDataFolder/O root:toExport:entry:instrument:attenuator
	NewDataFolder/O root:toExport:entry:instrument:beam_monitor_norm
	NewDataFolder/O root:toExport:entry:instrument:beam_stop
	NewDataFolder/O root:toExport:entry:instrument:beam_stop:shape
	NewDataFolder/O root:toExport:entry:instrument:collimator
	NewDataFolder/O root:toExport:entry:instrument:collimator:geometry
	NewDataFolder/O root:toExport:entry:instrument:collimator:geometry:shape
	NewDataFolder/O root:toExport:entry:instrument:detector
	NewDataFolder/O root:toExport:entry:instrument:lenses
	NewDataFolder/O root:toExport:entry:instrument:monochromator
	NewDataFolder/O root:toExport:entry:instrument:monochromator:velocity_selector
	NewDataFolder/O root:toExport:entry:instrument:sample_aperture
	NewDataFolder/O root:toExport:entry:instrument:sample_aperture:shape
	NewDataFolder/O root:toExport:entry:instrument:sample_table
	NewDataFolder/O root:toExport:entry:instrument:source
	NewDataFolder/O root:toExport:entry:instrument:source_aperture
	NewDataFolder/O root:toExport:entry:instrument:source_aperture:shape
	NewDataFolder/O root:toExport:entry:program_data
	NewDataFolder/O root:toExport:entry:reduction
	NewDataFolder/O root:toExport:entry:sample
	NewDataFolder/O root:toExport:entry:user


	SetDataFolder root:toExport:entry
    
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
    
    
	SetDataFolder root:toExport:entry:control

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

	SetDataFolder root:toExport:entry:data
	
		Make/O/D/N=(112,128)	areaDetector //(2-D wave N=(112,128)) val=4605	typ=32bI
		Make/O/T/N=1	configuration   	//"4m 6A Scatt"
		Make/O/T/N=1	sample_description   	//"Sample 1"
		Make/O/D/N=1	sample_thickness 	//1
		Make/O/T/N=1	slotIndex   	//"1"
		Make/O/T/N=1	x0   	//"TIME"
		Make/O/D/N=(112,128)	y0 //(2-D wave N=(112,128)) val=4605	typ=32bI

	SetDataFolder root:toExport:entry:instrument
	
		Make/O/T/N=1	local_contact   	//"Jeff Krzywon"
		Make/O/T/N=1	name   	//"SANS:NGB"
		Make/O/T/N=1	type   	//"SANS"

	SetDataFolder root:toExport:entry:instrument:attenuator

		Make/O/D/N=1		attenuator_transmission 	//1
		Make/O/D/N=1		attenuator_transmission_error 	//1
		Make/O/I/N=1		desired_num_atten_dropped 	//3
		Make/O/D/N=1		distance 	//15
		Make/O/D/N=(12,12)		index_error_table //(2-D wave N=(12,12)) val=3	typ=32bF
		Make/O/D/N=(12,12)		index_table //(2-D wave N=(12,12)) val=3	typ=32bF
		Make/O/D/N=1		num_atten_dropped 	//3
		Make/O/D/N=1		thickness 	//0.187559
		Make/O/T/N=1		type   	//"PMMA"

	SetDataFolder root:toExport:entry:instrument:beam_monitor_norm 
		Make/O/I/N=1		data 	//19099
		Make/O/D/N=1		distance 	//15
		Make/O/D/N=1		efficiency 	//0.01
		Make/O/D/N=1		saved_count 	//1e+08
		Make/O/T/N=1		type   	//"monitor"
		
	SetDataFolder root:toExport:entry:instrument:beam_stop 
		Make/O/T/N=1		description   	//"circular"
		Make/O/D/N=1		distance_to_detector 	//0
		Make/O/D/N=1		x_pos 	//0
		Make/O/D/N=1		y_pos 	//6.85408
				
	SetDataFolder root:toExport:entry:instrument:beam_stop:shape 
		Make/O/D/N=1			height 	//nan
		Make/O/T/N=1			shape   	//"CIRCLE"
		Make/O/D/N=1			size 	//5.08
		Make/O/D/N=1			width 	//nan

	SetupCollimator()					

	SetupDetector()						

				
	SetDataFolder root:toExport:entry:instrument:lenses 
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
				
	SetDataFolder root:toExport:entry:instrument:monochromator
		Make/O/T/N=1		type   	//"velocity_selector"
		Make/O/D/N=1		wavelength 	//6.00747
		Make/O/D/N=1		wavelength_error 	//0.14
		SetDataFolder root:toExport:entry:instrument:monochromator:velocity_selector 
			Make/O/D/N=1		distance 	//11.1
			Make/O/D/N=1		rotation_speed 	//3648.81
			Make/O/D/N=1		table 	//0.0028183

	SetupSampleAperture()					

					
	SetDataFolder root:toExport:entry:instrument:sample_table 
			Make/O/T/N=1	location   	//"CHAMBER"
			Make/O/D/N=1	offset_distance 	//0
				
	SetDataFolder root:toExport:entry:instrument:source 
			Make/O/T/N=1	name   	//"NCNR"
			Make/O/D/N=1	power 	//20
			Make/O/T/N=1	probe   	//"neutron"
			Make/O/T/N=1	type   	//"Reactor Neutron Source"

	SetupSourceAperture()				


	SetupProgramData()

			
	SetDataFolder root:toExport:entry:reduction 
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
			
	SetDataFolder root:toExport:entry:sample 
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
			
	SetDataFolder root:toExport:entry:user 
		Make/O/T/N=1	name   //	"[{"name":"Jeff Krzywon","orcid":"","email":"jkrzywon@nist.gov"}]"
					


	SetDataFolder root:
	
End

Function 	SetupCollimator()
					
	SetDataFolder root:toExport:entry:instrument:collimator 
			Make/O/T/N=1	number_guides   	//"0"
		SetDataFolder root:toExport:entry:instrument:collimator:geometry 
			SetDataFolder root:toExport:entry:instrument:collimator:geometry:shape 
			Make/O/T/N=1			shape   //"RECTANGLE"
			Make/O/D/N=1			size 	//10
			
	SetDataFolder root:
end

Function	SetupDetector()						
	SetDataFolder root:toExport:entry:instrument:detector 
		Make/O/D/N=1		azimuthal_angle 	//0
		Make/O/D/N=1		beam_center_x 	//113
		Make/O/D/N=1		beam_center_y 	//63.3
		Make/O/D/N=(112,128)		data //(2-D wave N=(112,128)) val=4605	typ=32bI
		Make/O/D/N=(1,112)		dead_time //(2-D wave N=(1,112)) val=5.2e-06	typ=32bF
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
		Make/O/D/N=(3,112)		spatial_calibration //(2-D wave N=(3,112)) val=-521	typ=32bF
		Make/O/D/N=1		tube_width 	//8.4
		Make/O/D/N=128		x_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		Make/O/D/N=1		x_pixel_size 	//5.08
		Make/O/D/N=128		y_offset //(1-D wave N=(128)) val=-322.58	typ=32bF
		Make/O/D/N=1		y_pixel_size 	//5.08
		
	SetDataFolder root:
end

Function	SetupSampleAperture()					
	SetDataFolder root:toExport:entry:instrument:sample_aperture 
		Make/O/T/N=1		description   	//"sample aperture"
		Make/O/D/N=1		distance //	5
		SetDataFolder root:toExport:entry:instrument:sample_aperture:shape 
			Make/O/D/N=1		height 	//0
			Make/O/T/N=1			shape   	//"CIRCLE"
			Make/O/T/N=1		size 	//"6.35 mm"
			Make/O/D/N=1		width 	//0
			
	SetDataFolder root:
end


Function 	SetupSourceAperture()				
	SetDataFolder root:toExport:entry:instrument:source_aperture 
			Make/O/T/N=1	description   	//"source aperture"
			Make/O/D/N=1	distance 	//508
		SetDataFolder root:toExport:entry:instrument:source_aperture:shape 
			Make/O/T/N=1		shape   	//"CIRCLE"
			Make/O/T/N=1		size   	//"38.1 mm"

	SetDataFolder root:
end

Function SetupProgramData()
		
	SetDataFolder root:toExport:entry:program_data 
		Make/O/T/N=1	data   	//"runPoint {"counter.countAgainst"="TIME", "configuration"="4m 6A Scatt", "groupid"="101", "filePurpose"="SCATTERING", "sample.description"="Sample 1", "sample.thickness"="1.0", "intent"="Sample", "counter.timePreset"="600.0", "slotIndex"="1.0"} -g 1 -p "MTHYR" -u "NGB""
		Make/O/T/N=1	description   //	"Additional program data, such as the script file which the program ran"
		Make/O/T/N=1	file_name   	//"null"
		Make/O/T/N=1	type   	//"application/json"

	SetDataFolder root:
	
End

// updated to the new Nexus structure.
// not all fields are present in VAX data, so there are
// many holes that will need to be patched post-conversion to be
// able to process the converted data sets
//
// (make a list of missing fields)
//
Function FillStructureFromRTI()

	WAVE rw = root:Packages:NIST:RAW:RealsRead
	WAVE iw = root:Packages:NIST:RAW:IntegersRead
	WAVE/T tw = root:Packages:NIST:RAW:TextRead


	SetDataFolder root:toExport:entry
    
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
    
//    collection_time = 600
    experiment_identifier  = "nonims0"
    start_time = tw[1]
    
	SetDataFolder root:toExport:entry:control

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
		
		count_time = iw[1]
		count_time_preset = iw[1]
		monitor_counts = rw[0]
		detector_counts = rw[2]
		
//		print iw[0]*iw[1],iw[2]

	SetDataFolder root:toExport:entry:data
	
		WAVE	areaDetector //(2-D wave N=(112,128)) val=4605	typ=32bI
		WAVE/T	configuration   	//"4m 6A Scatt"
		WAVE/T	sample_description   	//"Sample 1"
		WAVE	sample_thickness 	//1
		WAVE/T	slotIndex   	//"1"
		WAVE/T	x0   	//"TIME"
		WAVE	y0 //(2-D wave N=(112,128)) val=4605	typ=32bI

		sample_description = tw[6]
		sample_thickness = rw[5]
		 Wave linear_data = root:Packages:NIST:RAW:linear_data
		 areaDetector = linear_data[p][q] // result areaDetector is (112,128)
		
	SetDataFolder root:toExport:entry:instrument
	
		WAVE/T	local_contact   	//"Jeff Krzywon"
		WAVE/T	name   	//"SANS:NGB"
		WAVE/T	type   	//"SANS"
		
		local_contact = "Jeff Krzywon"
		name = "SANS_NGB"
		type = "SANS"

	SetDataFolder root:toExport:entry:instrument:attenuator

		WAVE		attenuator_transmission 	//1
		WAVE		attenuator_transmission_error 	//1
		WAVE		desired_num_atten_dropped 	//3
		WAVE		distance 	//15
		WAVE		index_error_table //(2-D wave N=(12,12)) val=3	typ=32bF
		WAVE		index_table //(2-D wave N=(12,12)) val=3	typ=32bF
		WAVE		num_atten_dropped 	//3
		WAVE		thickness 	//0.187559
		WAVE/T		type   	//"PMMA"

		num_atten_dropped = rw[3]
		
	SetDataFolder root:toExport:entry:instrument:beam_monitor_norm 
		WAVE		data 	//19099
		WAVE		distance 	//15
		WAVE		efficiency 	//0.01
		WAVE		saved_count 	//1e+08
		WAVE/T		type   	//"monitor"
		
		data = rw[0]

		
	SetDataFolder root:toExport:entry:instrument:beam_stop 
		WAVE/T		description   	//"circular"
		WAVE		distance_to_detector 	//0
		WAVE		x_pos 	//0
		WAVE		y_pos 	//6.85408
		
		description = "circular"
		distance_to_detector = 0
		x_pos = rw[37]
		y_pos = rw[38]
				
		SetDataFolder root:toExport:entry:instrument:beam_stop:shape 
			WAVE			height 	//nan
			WAVE/T			shape   	//"CIRCLE"
			WAVE			size 	//5.08
			WAVE			width 	//nan
			
			size = rw[21]		// wrong units?
			shape = "CIRCLE"
			
	FillCollimator()					

	FillDetector(rw,tw,iw)						

				
	SetDataFolder root:toExport:entry:instrument:lenses 
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
				
	SetDataFolder root:toExport:entry:instrument:monochromator
		WAVE/T		type   	//"velocity_selector"
		WAVE		wavelength 	//6.00747
		WAVE		wavelength_error 	//0.14
		
		type = "velocity selector"
		wavelength = rw[26]
		wavelength_error = rw[27]
		
		SetDataFolder root:toExport:entry:instrument:monochromator:velocity_selector 
			WAVE		distance 	//11.1
			WAVE		rotation_speed 	//3648.81
			WAVE		table 	//0.0028183

	FillSampleAperture(rw,tw,iw)					

					
	SetDataFolder root:toExport:entry:instrument:sample_table 
			WAVE/T	location   	//"CHAMBER"
			WAVE	offset_distance 	//0
			
			if(iw[4] == 1)		// guessng at this?
				location = "CHAMBER"
			else
				location = "HUBER"
			endif
			
	SetDataFolder root:toExport:entry:instrument:source 
			WAVE/T	name   	//"NCNR"
			WAVE	power 	//20
			WAVE/T	probe   	//"neutron"
			WAVE/T	type   	//"Reactor Neutron Source"

			name = "NCNR"
			power = 20
			probe = "neutron"
			type = "Reactor Neutron Source"

	FillSourceAperture(rw,tw,iw)				


	FillProgramData()

			
	SetDataFolder root:toExport:entry:reduction 
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
		
	SetDataFolder root:toExport:entry:sample 
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
		
		description = tw[6]
		transmission = rw[4]
		thickness = rw[5]
		changer_position = num2str(rw[6])
		rotation_angle = rw[7]
		sample_holder_description = num2str(iw[5])
			
	SetDataFolder root:toExport:entry:user 
		WAVE/T	name   //	"[{"name":"Jeff Krzywon","orcid":"","email":"jkrzywon@nist.gov"}]"
					

	SetDataFolder root:

End


Function FillCollimator()
					
	SetDataFolder root:toExport:entry:instrument:collimator 
			WAVE/T	number_guides   	//"0"
		SetDataFolder root:toExport:entry:instrument:collimator:geometry 
			SetDataFolder root:toExport:entry:instrument:collimator:geometry:shape 
			WAVE/T			shape   //"RECTANGLE"
			WAVE			size 	//10
		
			shape = "RECTANGLE"
			size = 10	
	SetDataFolder root:
end

// VAX data w/Ordela detector has different calibration than the
// projected tubes for 10m SANS. Pretend that the VAX data is tubes?
//
Function	FillDetector(rw,tw,iw)
	WAVE rw
	WAVE/T tw
	WAVE iw
							
	SetDataFolder root:toExport:entry:instrument:detector 
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
	
		description = tw[9]

// in pixels
		beam_center_x = rw[16]
		beam_center_y = rw[17]
		distance = rw[18]	*100				// convert the value of [m] to [cm]
		lateral_offset = rw[19]
		
// cut the right edge of the detector off since data is declared as 
// (112,128), and Ordela is (128,128)
		 Wave linear_data = root:Packages:NIST:RAW:linear_data
//		 data = linear_data[p][q] // result data is (112,128)

// trim evenly from each side L/R
// 128-112 = 16, so start at the 8th col [7]
// index runs from [7] to [7+111]
//		 data = linear_data[p+7][q] // result data is (112,128)
	
// cut the left edge of the detector, since offset is to the right
		 data = linear_data[p+15][q] // result data is (112,128)
	
		
		
// different fill if i'm faking TUBES vs. verifying Ordela/30m SANS
//

// for TUBES
	tube_width = 8.4
	number_of_tubes = 112
	
	x_pixel_size = 8.4
	y_pixel_size = 5
	pixel_num_x = 112
	pixel_num_y = 128
	pixel_fwhm_x = 0.84
	pixel_fwhm_y = 0.5		
		
		
// for 30m SANS/ duplicating Ordela:
//
//	x_pixel_size = 5.08
//	y_pixel_size = 5.08
//	pixel_num_x = 128
//	pixel_num_y = 128
//	pixel_fwhm_x = 0.508
//	pixel_fwhm_y = 0.508		
//       CALX[0] = rw[10]
//        CALX[1] = rw[11]
//        CALX[2] = rw[12]
//        CALY[0] = rw[13]
//        CALY[1] = rw[14]
//        CALY[2] = rw[15]	
	
		
	SetDataFolder root:
end

Function	FillSampleAperture(rw,tw,iw)
	WAVE rw
	WAVE/T tw
	WAVE iw
						
	SetDataFolder root:toExport:entry:instrument:sample_aperture 
		WAVE/T		description   	//"sample aperture"
		WAVE		distance //	5
		
		description = "sample aperture"
		distance = 5
		
		SetDataFolder root:toExport:entry:instrument:sample_aperture:shape 
			WAVE		height 	//0
			WAVE/T			shape   	//"CIRCLE"
			WAVE/T		size 	//6.35
			WAVE		width 	//0
			
			size = num2Str(rw[24])
			shape = "CIRCLE"
			
	SetDataFolder root:
			
end


Function 	FillSourceAperture(rw,tw,iw)
	WAVE rw
	WAVE/T tw
	WAVE iw
					
	SetDataFolder root:toExport:entry:instrument:source_aperture 
			WAVE/T	description   	//"source aperture"
			WAVE	distance 	//508
			
			description = "source aperture"
			distance = rw[25]
			
		SetDataFolder root:toExport:entry:instrument:source_aperture:shape 
			WAVE/T		shape   	//"CIRCLE"
			WAVE/T		size   	//"38.1 mm"

			shape = "CIRCLE"
			size = num2str(rw[23]) + " mm"		//correct units?
	SetDataFolder root:
end

Function FillProgramData()
		
	SetDataFolder root:toExport:entry:program_data 
		WAVE/T	data   	//"runPoint {"counter.countAgainst"="TIME", "configuration"="4m 6A Scatt", "groupid"="101", "filePurpose"="SCATTERING", "sample.description"="Sample 1", "sample.thickness"="1.0", "intent"="Sample", "counter.timePreset"="600.0", "slotIndex"="1.0"} -g 1 -p "MTHYR" -u "NGB""
		WAVE/T	description   //	"Additional program data, such as the script file which the program ran"
		WAVE/T	file_name   	//"null"
		WAVE/T	type   	//"application/json"
		
	SetDataFolder root:
	
End






Function Test_ListAttributes(fname,groupName)
	String fname,groupName
	Variable trans
	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
	String str
	PathInfo home
	str = S_path
	
	variable err
	err = HDF_ListAttributes(str+fname, groupName)
	
	//err not handled here
		
	return(0)
End

Function HDF_ListAttributes(fname, groupName)
	String fname, groupName
	
	variable err=0, fileID,groupID
	String cDF = getDataFolder(1), temp
	String NXentry_name, attrValue=""
	
	STRUCT HDF5DataInfo di	// Defined in HDF5 Browser.ipf.
	InitHDF5DataInfo(di)	// Initialize structure.
	
	try	
		HDF5OpenFile /Z fileID  as fname  //open file read-write
		if(!fileID)
			err = 1
			abort "HDF5 file does not exist"
		endif
		
		HDF5OpenGroup /Z fileID , groupName, groupID

	//	!! At the moment, there is no entry for sample thickness in our data file
	//	therefore create new HDF5 group to enable write / patch command
	//	comment out the following group creation once thickness appears in revised file
	
		if(!groupID)
			HDF5CreateGroup /Z fileID, groupName, groupID
			//err = 1
			//abort "HDF5 group does not exist"
		else

//			HDF5AttributeInfo(fileID, "/", 1, "file_name", 0, di)
			err = HDF5AttributeInfo(fileID, "/", 1, "NeXus_version", 0, di)
			Print di

//			see the HDF5 Browser  for how to get the actual <value> of the attribute. See GetPreviewString in 
//        or in FillGroupAttributesList or in FillDatasetAttributesList (from FillLists)
//			it seems to be ridiculously complex to get such a simple bit of information - the HDF5BrowserData STRUCT
// 			needs to be filled first. Ugh.

//#if (IgorVersion() < 9)
//			attrValue = GetPreviewString(fileID, 1, di, "/entry", "cucumber")
//#else
//			attrValue = HDF5Browser#GetPreviewString(fileID, 1, di, "/entry", "cucumber")
//#endif
			Print "attrValue = ",attrValue
			
			
			//get attributes and save them
			HDF5ListAttributes/TYPE=1 /Z fileID, groupName 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
			
			// passing the groupID works too, then the group name is not needed			
			HDF5ListAttributes/TYPE=1 /Z groupID, "." 		//TYPE=1 means that we're referencing a group, not a dataset
			Print "S_HDF5ListAttributes = ", S_HDF5ListAttributes
		endif
	catch

		// catch any aborts here
		
	endtry
	
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif
	
	if(fileID)
		HDF5CloseFile /Z fileID 
	endif

	setDataFolder $cDF
	return err
end



// this is my procedure to save VAX to HDF5, once I've filled the folder tree
//
// called as:
// 	VAXSaveGroupAsHDF5("root:toExport", newfilename[0,7]+".nxs.ngb")
//
Function VAXSaveGroupAsHDF5(dfPath, filename)
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



//////// Two procedures that test out Pete Jemain's HDF5Gateway
//
// This works fine, but it may not be terribly compatible with the way NICE will eventually
// write out the data files. I'll have very little control over that and I'll need to cobble together
// a bunch of fixes to cover up their mistakes.
//
// Using Nick Hauser's code as a starting point may be a lot more painful, but more flexible in the end.
//
// I'm completely baffled about what to do with attributes. Are they needed, is this the best way to deal
// with them, do I care about reading them in, and if I do, why?
//
xProc HDF5Gate_WriteTest()

	// create the folder structure
	NewDataFolder/O/S root:mydata
	NewDataFolder/O sasentry
	NewDataFolder/O :sasentry:sasdata

	// create the waves
	Make/O :sasentry:sasdata:I0
	Make/O :sasentry:sasdata:Q0

	Make/O/N=0 Igor___folder_attributes
	Make/O/N=0 :sasentry:Igor___folder_attributes
	Make/O/N=0 :sasentry:sasdata:Igor___folder_attributes

	// create the attributes
	Note/K Igor___folder_attributes, "producer=IgorPro\rNX_class=NXroot"
	Note/K :sasentry:Igor___folder_attributes, "NX_class=NXentry"
	Note/K :sasentry:sasdata:Igor___folder_attributes, "NX_class=NXdata"
	Note/K :sasentry:sasdata:I0, "units=1/cm\rsignal=1\rtitle=reduced intensity"
	Note/K :sasentry:sasdata:Q0, "units=1/A\rtitle=|scattering vector|"

	// create the cross-reference mapping
	Make/O/T/N=(5,2) HDF5___xref
	Edit/K=0 'HDF5___xref';DelayUpdate
	HDF5___xref[0][1] = ":"
	HDF5___xref[1][1] = ":sasentry"
	HDF5___xref[2][1] = ":sasentry:sasdata"
	HDF5___xref[3][1] = ":sasentry:sasdata:I0"
	HDF5___xref[4][1] = ":sasentry:sasdata:Q0"
	HDF5___xref[0][0] = "/"
	HDF5___xref[1][0] = "/sasentry"
	HDF5___xref[2][0] = "/sasentry/sasdata"
	HDF5___xref[3][0] = "/sasentry/sasdata/I"
	HDF5___xref[4][0] = "/sasentry/sasdata/Q"

	// Check our work so far.
	// If something prints, there was an error above.
	print H5GW_ValidateFolder("root:mydata")

	// set I0 and Q0 to your data

	print H5GW_WriteHDF5("root:mydata", "mydata.h5")
	
	SetDataFolder root:
End

xProc HDF5Gate_ReadTest(file)
	String file
//	NewDataFolder/O/S root:newdata
	Print H5GW_ReadHDF5("", file)	// reads into current folder
	SetDataFolder root:
End



//// after reading in an HDF file, convert it into something I can use with data reduction
//
// This is to be an integral part of the file loader
//
// I guess I need to load the file into a temporary location, and then copy what I need to the local RTI
// and then get rid of the temp dump. ANSTO keeps all of the loads around, but this may get too large
// especially if NICE dumps all of the logs into the data file.
// 
// -- and I may need to have a couple of these, at least for testing to be able to convert the 
// minimal VAX file to HDF, and also to write out/ have a container/ for what NICE calls a data file.
//
//


// From the HDF5 tree as read in from a (converted) raw VAX file,
// put everything back into its proper place in the RTI waves
// (and the data!)
// 
xFunction FillRTIFromHDFTree(folderStr)
	String folderStr

	WAVE rw = root:Packages:NIST:RAW:RealsRead
	WAVE iw = root:Packages:NIST:RAW:IntegersRead
	WAVE/T tw = root:Packages:NIST:RAW:TextRead

	rw = -999
	iw = 11111
	tw = "jibberish"
	
	folderStr = RemoveDotExtension(folderStr)		// to make sure that the ".h5" or any other extension is removed
//	folderStr = RemoveEnding(folderStr,".h5")		// to make sure that the ".h5" or any other extension is removed
	
	String base="root:"+folderStr+":"
	SetDataFolder $base
    Wave/T filename
    
    tw[0] = filename[0]
    
	SetDataFolder $(base+"Run1")
    Wave/T runLabel

	tw[6] = runLabel[0]

	SetDataFolder $(base+"Run1:Sample")
// SAMPLE      
        Wave TRNS
        Wave THK
        Wave POSITION
        Wave ROTANG
        Wave TABLE
        Wave HOLDER
        Wave BLANK
        Wave TEMP
        Wave FIELD
        Wave TCTRLR
        Wave MAGNET
        Wave/T TUNITS
        Wave/T FUNITS

        rw[4] = TRNS[0]
        rw[5] = THK[0]
        rw[6] = POSITION[0]
        rw[7] = ROTANG[0]
        iw[4] = TABLE[0]
        iw[5] = HOLDER[0]
        iw[6] = BLANK[0]
        rw[8] = TEMP[0]
        rw[9] = FIELD[0]
        iw[7] = TCTRLR[0]
        iw[8] = MAGNET[0]
        tw[7] = TUNITS[0]
        tw[8] = FUNITS[0]


	SetDataFolder $(base+"Run1:Run")
// RUN
        Wave NPRE
        Wave CTIME
        Wave RTIME
        Wave NUMRUNS
        Wave MONCNT
        Wave SAVMON
        Wave DETCNT
        Wave ATTEN
        Wave/T TIMDAT
        Wave/T TYPE
        Wave/T DEFDIR
        Wave/T MODE
        Wave/T RESERVE
//        Wave/T LOGDATIM
        
        
        iw[0] = NPRE[0]
        iw[1] = CTIME[0]
        iw[2] = RTIME[0]
        iw[3] = NUMRUNS[0]
        rw[0] = MONCNT[0]
        rw[1] = SAVMON[0]
        rw[2] = DETCNT[0]
        rw[3] = ATTEN[0]
        tw[1] = TIMDAT[0]
        tw[2] = TYPE[0]
        tw[3] = DEFDIR[0]
        tw[4] = MODE[0]
        tw[5] = RESERVE[0]
//        LOGDATIM
        
        
	SetDataFolder $(base+"Run1:Detector")
// DET
        Wave/T TYP
        Wave CALX
        Wave CALY
        Wave NUM
        Wave DetSPACER
        Wave BEAMX
        Wave BEAMY
        Wave DIS
        Wave ANG
        Wave SIZ
        Wave BSTOP
        Wave DetBLANK
        
		 Wave data

		//CALX is 3 pts
		//CALY is 3 pts
		//data is 128,128
		
        tw[9] = TYP[0]
        rw[10] = CALX[0]
        rw[11] = CALX[1]
        rw[12] = CALX[2]
        rw[13] = CALY[0]
        rw[14] = CALY[1]
        rw[15] = CALY[2]
        iw[9] = NUM[0]
        iw[10] = DetSPACER[0]
        rw[16] = BEAMX[0]
        rw[17] = BEAMY[0]
        rw[18] = DIS[0]
        rw[19] = ANG[0]
        rw[20] = SIZ[0]
        rw[21] = BSTOP[0]
        rw[22] = DetBLANK[0]

//		 Wave linear_data = root:Packages:NIST:RAW:linear_data
//		 Wave raw_data = root:Packages:NIST:RAW:data
// 		 linear_data = data
//		 raw_data = data
		
		/// **** what about the error wave?
		
		
		
	SetDataFolder $(base+"Run1:Instrument")
// RESOLUTION
        Wave AP1
        Wave AP2
        Wave AP12DIS
        Wave LMDA
        Wave DLMDA
        Wave SAVEFlag
// BMSTP
        Wave XPOS
        Wave YPOS        
// TIMESLICING
        Wave/T SLICING		//logical
        Wave MULTFACT
        Wave LTSLICE

// POLARIZATION
        Wave/T PRINTPOL			//logical
        Wave/T FLIPPER			//logical
        Wave HORIZ
        Wave VERT        
// TEMP
        Wave/T PRINTEMP			//logical
        Wave HOLD
        Wave ERR_TEMP
//        Wave ERR0
        Wave TempBLANK
        Wave/T EXTEMP			//logical
        Wave/T EXTCNTL 			//logical
        Wave/T TempEXTRA2		//logical
        Wave TempRESERVE
// MAGNET
        Wave/T PRINTMAG			//logical
        Wave/T SENSOR			//logical
        Wave CURRENT
        Wave CONV
        Wave FIELDLAST
        Wave MagnetBLANK
        Wave MagnetSPACER
// VOLTAGE
        Wave/T PRINTVOLT		//logical
        Wave VOLTS
        Wave VoltBLANK
        Wave VoltSPACER
  
  
        rw[23] = AP1[0]
        rw[24] = AP2[0]
        rw[25] = AP12DIS[0]
        rw[26] = LMDA[0]
        rw[27] = DLMDA[0]
        rw[28] = SAVEFlag[0]
  
        rw[37] = XPOS[0]
        rw[38] = YPOS[0]
     
        iw[11] = MULTFACT[0]
        iw[12] = LTSLICE[0]
     
        rw[45] = HORIZ[0]
        rw[46] = VERT[0]
// TEMP
        rw[29] = HOLD[0]
        rw[30] = ERR_TEMP[0]
//        rw[30] = ERR0[0]
        rw[31] = TempBLANK[0]
        iw[14] = TempRESERVE[0]
// MAGNET
        rw[32] = CURRENT[0]
        rw[33] = CONV[0]
        rw[34] = FIELDLAST[0]
        rw[35] = MagnetBLANK[0]
        rw[36] = MagnetSPACER[0]
// VOLTAGE
        rw[43] = VOLTS[0]
        rw[44] = VoltBLANK[0]
        iw[18] = VoltSPACER[0]
     
	SetDataFolder $(base+"Run1:Analysis")
// ANALYSIS
        Wave ROWS
        Wave COLS
        Wave FACTOR
        Wave AnalysisQMIN
        Wave AnalysisQMAX
        Wave IMIN
        Wave IMAX

// PARAMS
        Wave BLANK1
        Wave BLANK2
        Wave BLANK3
        Wave TRNSCNT
        Wave ParamEXTRA1
        Wave ParamEXTRA2
        Wave ParamEXTRA3
        Wave/T ParamRESERVE	
	
			// ROWS is 2 pts
			// COLS is 2 pts
			
// ANALYSIS
        iw[19] = ROWS[0]
        iw[20] = ROWS[1]
        iw[21] = COLS[0]
        iw[22] = COLS[1]

        rw[47] = FACTOR[0]
        rw[48] = AnalysisQMIN[0]
        rw[49] = AnalysisQMAX[0]
        rw[50] = IMIN[0]
        rw[51] = IMAX[0]

// PARAMS
        iw[15] = BLANK1[0]
        iw[16] = BLANK2[0]
        iw[17] = BLANK3[0]
        rw[39] = TRNSCNT[0]
        rw[40] = ParamEXTRA1[0]
        rw[41] = ParamEXTRA2[0]
        rw[42] = ParamEXTRA3[0]
        tw[10] = ParamRESERVE[0]
			
			
	SetDataFolder root:
		
	return(0)
End






//////////////////////////////////////////////////



Macro BatchConvertToHDF5(firstFile,lastFile)
	Variable firstFile=1,lastFile=100

	SetupStructure()
	fBatchConvertToHDF5(firstFile,lastFile)

End

// lo is the first file number
// hi is the last file number (inclusive)
//
Function fBatchConvertToHDF5(lo,hi)
	Variable lo,hi
	
	Variable ii
	String file
	
	String fname="",pathStr="",fullPath="",newFileName=""

	PathInfo catPathName			//this is where the files are
	pathStr=S_path
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		file = FindFileFromRunNumber(ii)
		if(strlen(file) != 0)
			// load the data
			ReadHeaderAndData(file)		//file is the full path
			String/G root:myGlobals:gDataDisplayType="RAW"	
			fRawWindowHook()
			WAVE/T/Z tw = $"root:Packages:NIST:RAW:textRead"	//to be sure that wave exists if no data was ever displayed
			newFileName= GetNameFromHeader(tw[0])		//02JUL13
			
			// convert it
			FillStructureFromRTI()
			
			// save it
//			VAXSaveGroupAsHDF5("root:toExport", newfilename[0,7]+".nxs.ngb")
			VAXSaveGroupAsHDF5("root:toExport", "sans"+num2str(ii)+".nxs.ngb")

		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

