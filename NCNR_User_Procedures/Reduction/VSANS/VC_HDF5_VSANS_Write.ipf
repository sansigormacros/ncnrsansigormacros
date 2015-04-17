#pragma rtGlobals=1		// Use modern global access method.


//
// DON'T TOSS THIS FILE-- THERE ARE USEFUL PROCEDURES HERE
// -- some that may be in use elsewhere in reading/writing of HDF files
//

// this is a test of the "new" SANS file structure that is supposed to be
// NeXus compliant. It doesn't have the NICE logs, but has everything that I 
// can think of here.



// then... translate this to VSANS...



// then... think of all of R/W access needed

// do I ditch the RealsRead/IntegersRead/TextRead? It makes little sense now.
// maybe copy a "dataInfo" folder/subfolders. can't keep them all (bloat)
// but then what about multiple files added together?


//
// the simple read/write works...
// linear_data does not seem to need to be transposed at all
//
//  -- this seems too easy. what am I doing wrong? Is something getting garbled when I 
// write back any single values back to the file
//
// -- try a string value next
//


// lays out the tree and fills with dummy values
//
Macro H_Setup_SANS_Structure()
	
	Variable n=100
	
//	Data File	
	NewDataFolder/O/S root:SANS_file
	
//Creation	Name	dummy fill
//	Data File	

//	NewDataFolder/O/S root:SANS_file:
	
	
	Make/O/T/N=1	file_name	= "SANSTest.h5"
	Make/O/T/N=1	file_time	= "2015-02-28T08:15:30-5:00"
	Make/O/T/N=1	facility	= "NCNR"
	Make/O/T/N=1	NeXus_version	= "Nexus 0.0"
	Make/O/T/N=1	hdf_version	= "hdf5.x"
	Make/O/T/N=1	file_history	= "history log"
	
		NewDataFolder/O/S root:SANS_file:entry1	
		Make/O/T/N=1	title	= "title of entry1"
		Make/O/D/N=1	experiment_identifier	= 684636
		Make/O/T/N=1	experiment_description	= "description of expt"
		Make/O/T/N=1	entry_identifier	= "S22-33"
		Make/O/T/N=1	definition	= "NXsas"
		Make/O/T/N=1	start_time	= "2015-02-28T08:15:30-5:00"
		Make/O/T/N=1	end_time	= "2015-02-28T08:15:30-5:00"
		Make/O/D/N=1	duration	= 300
		Make/O/D/N=1	collection_time	= 300
		Make/O/T/N=1	run_cycle	= "S22-23"
		Make/O/T/N=1	intent	= "RAW"
		Make/O/T/N=1	data_directory	= "[NG7SANS41]"
		
			NewDataFolder/O/S root:SANS_file:entry1:user	
			Make/O/T/N=1	name	= "Dr. Pi"
			Make/O/T/N=1	role	= "evil scientist"
			Make/O/T/N=1	affiliation	= "NIST"
			Make/O/T/N=1	address	= "100 Bureau Drive"
			Make/O/T/N=1	telephoneNumber	= "301-999-9999"
			Make/O/T/N=1	faxNumber	= "301-999-9999"
			Make/O/T/N=1	email	= "sans@nist"
			Make/O/I/N=1	facility_user_id	= 6937596
			NewDataFolder/O/S root:SANS_file:entry1:control	
			Make/O/T/N=1	mode	= "timer"
			Make/O/D/N=1	preset	= 555
			Make/O/D/N=1	integral	= 555
			Make/O/D/N=1	monitor_counts	= 666
			Make/O/D/N=1	monitor_preset	= 1e8
			Make/O/T/N=1	type	= "monitor type"
			Make/O/D/N=1	efficiency	= 0.01
			Make/O/D/N=1	sampled_fraction	= 1
			Make/O/D/N=1	nominal	= 1e8
			Make/O/D/N=1	data	= 1
			Make/O/D/N=1	nx_distance	= 13.1
			Make/O/D/N=1	detector_counts	= 100111222
			Make/O/D/N=1	detector_preset	= 1e5
			Make/O/D/N=1	detector_mask	= 1
			NewDataFolder/O/S root:SANS_file:entry1:program_name	
			Make/O/T/N=1	data	= "program data"
			Make/O/T/N=1	description	= "acquisition"
			Make/O/T/N=1	file_name	= "NICE"
			Make/O/T/N=1	type	= "client"
			
			NewDataFolder/O/S root:SANS_file:entry1:sample	
			Make/O/T/N=1	name	= "My Sample"
			Make/O/T/N=1	chemical_formula	= "C8H10N4O2"
				NewDataFolder/O/S root:SANS_file:entry1:sample:temperature_1	
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				Make/O/T/N=1	units	= "C"
					NewDataFolder/O/S root:SANS_file:entry1:sample:temperature_1:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 2*p
				NewDataFolder/O/S root:SANS_file:entry1:sample:temperature_2	
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				Make/O/T/N=1	units	= "C"
					NewDataFolder/O/S root:SANS_file:entry1:sample:temperature_2:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 3*p
				NewDataFolder/O/S root:SANS_file:entry1:sample:electric_field	
				Make/O/T/N=1	name	= "electric meter"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "voltage"
				Make/O/T/N=1	units	= "mV"
					NewDataFolder/O/S root:SANS_file:entry1:sample:electric_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= 2*p
					Make/O/D/N=(n)	value	= sin(p/10)
				NewDataFolder/O/S root:SANS_file:entry1:sample:shear_field	
				Make/O/T/N=1	name	= "rheometer"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "stress"
				Make/O/T/N=1	units	= "Hz"
					NewDataFolder/O/S root:SANS_file:entry1:sample:shear_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= cos(p/5)
				NewDataFolder/O/S root:SANS_file:entry1:sample:pressure	
				Make/O/T/N=1	name	= "Sample pressure"
				Make/O/T/N=1	attached_to	= "pressure cell"
				Make/O/T/N=1	measurement	= "pressure"
				Make/O/T/N=1	units	= "psi"
					NewDataFolder/O/S root:SANS_file:entry1:sample:pressure:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= p/2
				NewDataFolder/O/S root:SANS_file:entry1:sample:magnetic_field	
				Make/O/T/N=1	name	= "magnetic field (direction)"
				Make/O/T/N=1	attached_to	= "cryostat"
				Make/O/T/N=1	measurement	= "magnetic field"
				Make/O/T/N=1	units	= "G"
					NewDataFolder/O/S root:SANS_file:entry1:sample:magnetic_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 10*p
			SetDataFolder root:SANS_file:entry1:sample:
			Make/O/D/N=1	changer_position	= 5
			Make/O/T/N=1	sample_holder_description	= "10CB"
			Make/O/D/N=1	mass	= 0.3
			Make/O/D/N=1	density	= 1.02
			Make/O/D/N=1	molecular_weight	= 194.19
			Make/O/T/N=1	description	= "My Sample"
			Make/O/T/N=1	preparation_date	= "2015-02-28T08:15:30-5:00"
			Make/O/D/N=1	volume_fraction	= 0.2
			Make/O/D/N=1	scattering_length_density	= 6.35e-6
			Make/O/D/N=1	thickness	= 0.1
			Make/O/D/N=1	rotation_angle	= 30
			Make/O/D/N=1	transmission	= 0.888
			Make/O/D/N=1	transmission_error	= 0.011
			Make/O/D/N=1	xs_incoh	= 5.5
			Make/O/D/N=1	xs_coh	= 22.2
			Make/O/D/N=1	xs_absorb	= 3.1
			
			NewDataFolder/O/S root:SANS_file:entry1:instrument	
			Make/O/T/N=1	location	= "NCNR"
			Make/O/T/N=1	description	= "NGB30mSANS"
			Make/O/T/N=1	type	= "30 m SANS"
			Make/O/T/N=1	local_contact	= "Steve Kline"
				NewDataFolder/O/S root:SANS_file:entry1:instrument:source	
				Make/O/T/N=1	name	= "NCNR"
				Make/O/T/N=1	type	= "Reactor Neutron Source"
				Make/O/T/N=1	probe	= "neutron"
				Make/O/D/N=1	power	= 20
				NewDataFolder/O/S root:SANS_file:entry1:instrument:beam	
					NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:monochromator	
					Make/O/D/N=1	wavelength	= 6
					Make/O/D/N=1	wavelength_spread	= 0.15
						NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:monochromator:velocity_selector	
						Make/O/T/N=1	type	= "VS"
						Make/O/D/N=1	rotation_speed	= 5100
						Make/O/D/N=1	wavelength	= 6
						Make/O/D/N=1	wavelength_spread	= 0.15
						Make/O/D/N=1	vs_tilt	= 3
						Make/O/D/N=1	nx_distance	= 18.8
						//	table (wave)	
					NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:polarizer	
					Make/O/T/N=1	type	= "supermirror"
					Make/O/T/N=1	composition	= "multilayer"
					Make/O/D/N=1	efficiency	= 0.95
					Make/O/T/N=1	status	= "in"
					NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:flipper	
					Make/O/T/N=1	status	= "on"
					Make/O/D/N=1	driving_current	= 42
					Make/O/T/N=1	waveform	= "sine"
					Make/O/D/N=1	frequency	= 400
					Make/O/D/N=1	transmitted_power	= 0.99
					NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:polarizer_analyzer	
					Make/O/T/N=1	status	= "down"
					Make/O/D/N=1	guide_field_current_1	= 33
					Make/O/D/N=1	guide_field_current_2	= 32
					Make/O/D/N=1	solenoid_current	= 21
					Make/O/T/N=1	cell_name	= "Burgundy"
					Make/O/D/N=(5)	cell_parameters	= {1,2,3,4,5}
					NewDataFolder/O/S root:SANS_file:entry1:instrument:beam:chopper	
					Make/O/T/N=1	type	= "single"
					Make/O/D/N=1	rotation_speed	= 12000
					Make/O/D/N=1	distance_from_source	= 400
					Make/O/D/N=1	distance_from_sample	= 1500
					Make/O/D/N=1	slits	= 2
					Make/O/D/N=1	angular_opening	= 15
					Make/O/D/N=1	duty_cycle	= 0.25
				NewDataFolder/O/S root:SANS_file:entry1:instrument:attenuator	
				Make/O/D/N=1	nx_distance	= 1500
				Make/O/T/N=1	type	= "PMMA"
				Make/O/D/N=1	thickness	= 0
				Make/O/D/N=1	attenuator_transmission	= 1
				Make/O/T/N=1	status	= "in"
				Make/O/D/N=1	atten_number	= 0
				Make/O/D/N=(10,10)	index	= 1
				NewDataFolder/O/S root:SANS_file:entry1:instrument:source_aperture	
				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "source aperture"
					NewDataFolder/O/S root:SANS_file:entry1:instrument:source_aperture:shape	
					Make/O/D/N=(1,2)	size	= 1.27
				SetDataFolder root:SANS_file:entry1:instrument:source_aperture
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 13.0
				NewDataFolder/O/S root:SANS_file:entry1:instrument:sample_aperture	
				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "sample aperture"
					NewDataFolder/O/S root:SANS_file:entry1:instrument:sample_aperture:shape	
					Make/O/D/N=(1,2)	size	= 1.27
				SetDataFolder root:SANS_file:entry1:instrument:sample_aperture
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 10
				
			SetDataFolder root:SANS_file:entry1:instrument:
			Make/O/I/N=1	nx_NumGuides	= 1
			
				NewDataFolder/O/S root:SANS_file:entry1:instrument:lenses	
				Make/O/T/N=1	lens_geometry	= "concave_lens"
				Make/O/T/N=1	focus_type	= "point"
				Make/O/I/N=1	number_of_lenses	= 28
				Make/O/I/N=1	number_of_prisms	= 7
				Make/O/D/N=1	curvature	= 1
				Make/O/D/N=1	lens_distance	= 123
				Make/O/D/N=1	prism_distance	= 123
				Make/O/T/N=1	lens_material	= "MgF2"
				Make/O/T/N=1	prism_material	= "MgF2"
				NewDataFolder/O/S root:SANS_file:entry1:instrument:sample_table	
				Make/O/T/N=1	location	= "chamber"
				Make/O/D/N=1	offset_distance	= 0
				NewDataFolder/O/S root:SANS_file:entry1:instrument:beam_stop	
				Make/O/T/N=1	description	= "circular"
				Make/O/D/N=1	nx_distance	= 12.5
				Make/O/D/N=1	size	= 7.62
				Make/O/T/N=1	status	= "out"
				Make/O/D/N=1	xPos	= 66.4
				Make/O/D/N=1	yPos	= 64.4
				Make/O/D/N=1	x_motor_position	= 0.15
				Make/O/D/N=1	y_motor_position	= 0.55
				NewDataFolder/O/S root:SANS_file:entry1:instrument:detector	
				Make/O/I/N=(128,128)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(128,128)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.1
				Make/O/T/N=1	description	= "Ordela 2660N"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "Ordela"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,128)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 128
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
			NewDataFolder/O/S root:SANS_file:entry1:data	
			Make/O/I/N=(128,128)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(128,128)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,128}
			NewDataFolder/O/S root:SANS_file:entry1:reduction	
			Make/O/T/N=1	intent	= "SCATTER"
			Make/O/T/N=1	transmission_file_name	= "SANSFile_TRN.h5"
			Make/O/T/N=1	empty_beam_file_name	= "SANSFile_EB.h5"
			Make/O/T/N=1	background_file_name	= "SANSFile_BKG.h5"
			Make/O/T/N=1	empty_file_name	= "SANSFile_EMP.h5"
			Make/O/T/N=1	sensitivity_file_name	= "SANSFile_DIV.h5"
			Make/O/T/N=1	mask_file_name	= "SANSFile_MASK.h5"
			Make/O/T/N=1	sans_log_file_name	= "SANSFile_log.txt"
			Make/O/D/N=1	whole_trans	= 0.888
			Make/O/D/N=1	whole_trans_error	= 0.008
			Make/O/D/N=1	box_count	= 23232
			Make/O/D/N=1	box_count_error	= 22
			Make/O/I/N=4	box_coordinates	= {50,80,45,75}
			Make/O/T/N=1	notes	= "extra data notes"
				NewDataFolder/O/S root:SANS_file:entry1:reduction:pol_sans	
				Make/O/T/N=1	pol_sans_purpose	= "name from the list"
				Make/O/T/N=1	cell_name	= "Burgundy"
				Make/O/D/N=(5)	cell_parameters	= {1,2,3,4,5}
						
		NewDataFolder/O/S root:SANS_file:entry1:DAS_Logs	
			//...multiple entries and levels... to add	

	
	SetDataFolder root:
	
End




// lays out the tree and fills with dummy values
//
Macro H_Setup_VSANS_Structure()
	
	Variable n=100
	Variable tubes=48
	
//	Data File	
//	NewDataFolder/O/S root:VSANS_file

//Creation	Name	dummy fill
//	Data File	

	NewDataFolder/O/S root:VSANS_file
	
	Make/O/T/N=1	file_name	= "VSANSTest.h5"
	Make/O/T/N=1	file_time	= "2015-02-28T08:15:30-5:00"
	Make/O/T/N=1	facility	= "NCNR"
	Make/O/T/N=1	NeXus_version	= "Nexus 0.0"
	Make/O/T/N=1	hdf_version	= "hdf5.x"
	Make/O/T/N=1	file_history	= "history log"
		NewDataFolder/O/S root:VSANS_file:entry1	
		Make/O/T/N=1	title	= "title of entry1"
		Make/O/D/N=1	experiment_identifier	= 684636
		Make/O/T/N=1	experiment_description	= "description of expt"
		Make/O/T/N=1	entry_identifier	= "S22-33"
		Make/O/T/N=1	definition	= "NXsas"
		Make/O/T/N=1	start_time	= "2015-02-28T08:15:30-5:00"
		Make/O/T/N=1	end_time	= "2015-02-28T08:15:30-5:00"
		Make/O/D/N=1	duration	= 300
		Make/O/D/N=1	collection_time	= 300
		Make/O/T/N=1	run_cycle	= "S22-23"
		Make/O/T/N=1	intent	= "RAW"
		Make/O/T/N=1	data_directory	= "[VSANS_VSANS]"
			NewDataFolder/O/S root:VSANS_file:entry1:user	
			Make/O/T/N=1	name	= "Dr. Pi"
			Make/O/T/N=1	role	= "evil scientist"
			Make/O/T/N=1	affiliation	= "NIST"
			Make/O/T/N=1	address	= "100 Bureau Drive"
			Make/O/T/N=1	telephoneNumber	= "301-999-9999"
			Make/O/T/N=1	faxNumber	= "301-999-9999"
			Make/O/T/N=1	email	= "sans@nist"
			Make/O/I/N=1	facility_user_id	= 6937596
			NewDataFolder/O/S root:VSANS_file:entry1:control	
			Make/O/T/N=1	mode	= "timer"
			Make/O/D/N=1	preset	= 555
			Make/O/D/N=1	integral	= 555
			Make/O/D/N=1	monitor_counts	= 666
			Make/O/D/N=1	monitor_preset	= 1e8
			Make/O/T/N=1	type	= "monitor type"
			Make/O/D/N=1	efficiency	= 0.01
			Make/O/D/N=1	sampled_fraction	= 1
			Make/O/D/N=1	nominal	= 1e8
			Make/O/D/N=1	data	= 1
			Make/O/D/N=1	nx_distance	= 13.1
			Make/O/D/N=1	detector_counts	= 100111222
			Make/O/D/N=1	detector_preset	= 1e5
			Make/O/D/N=1	detector_mask	= 1
			NewDataFolder/O/S root:VSANS_file:entry1:program_name	
			Make/O/T/N=1	data	= "program data"
			Make/O/T/N=1	description	= "acquisition"
			Make/O/T/N=1	file_name	= "NICE"
			Make/O/T/N=1	type	= "client"
			NewDataFolder/O/S root:VSANS_file:entry1:sample	
			Make/O/T/N=1	name	= "My Sample"
			Make/O/T/N=1	chemical_formula	= "C8H10N4O2"
				NewDataFolder/O/S root:VSANS_file:entry1:sample:temperature_1	
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				Make/O/T/N=1	units	= "C"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:temperature_1:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 2*p
				NewDataFolder/O/S root:VSANS_file:entry1:sample:temperature_2	
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				Make/O/T/N=1	units	= "C"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:temperature_2:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 3*p
				NewDataFolder/O/S root:VSANS_file:entry1:sample:electric_field	
				Make/O/T/N=1	name	= "electric meter"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "voltage"
				Make/O/T/N=1	units	= "mV"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:electric_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= 2*p
					Make/O/D/N=(n)	value	= sin(p/10)
				NewDataFolder/O/S root:VSANS_file:entry1:sample:shear_field	
				Make/O/T/N=1	name	= "rheometer"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "stress"
				Make/O/T/N=1	units	= "Hz"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:shear_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= cos(p/5)
				NewDataFolder/O/S root:VSANS_file:entry1:sample:pressure	
				Make/O/T/N=1	name	= "Sample pressure"
				Make/O/T/N=1	attached_to	= "pressure cell"
				Make/O/T/N=1	measurement	= "pressure"
				Make/O/T/N=1	units	= "psi"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:pressure:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= p/2
				NewDataFolder/O/S root:VSANS_file:entry1:sample:magnetic_field	
				Make/O/T/N=1	name	= "magnetic field (direction)"
				Make/O/T/N=1	attached_to	= "cryostat"
				Make/O/T/N=1	measurement	= "magnetic field"
				Make/O/T/N=1	units	= "G"
					NewDataFolder/O/S root:VSANS_file:entry1:sample:magnetic_field:value_log	
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 10*p
					
			SetDataFolder root:VSANS_file:entry1:sample
			Make/O/D/N=1	changer_position	= 5
			Make/O/T/N=1	sample_holder_description	= "10CB"
			Make/O/D/N=1	mass	= 0.3
			Make/O/D/N=1	density	= 1.02
			Make/O/D/N=1	molecular_weight	= 194.19
			Make/O/T/N=1	description	= "My Sample"
			Make/O/T/N=1	preparation_date	= "2015-02-28T08:15:30-5:00"
			Make/O/D/N=1	volume_fraction	= 0.2
			Make/O/D/N=1	scattering_length_density	= 6.35e-6
			Make/O/D/N=1	thickness	= 0.1
			Make/O/D/N=1	rotation_angle	= 30
			Make/O/D/N=1	transmission	= 0.888
			Make/O/D/N=1	transmission_error	= 0.011
			Make/O/D/N=1	xs_incoh	= 5.5
			Make/O/D/N=1	xs_coh	= 22.2
			Make/O/D/N=1	xs_absorb	= 3.1
			NewDataFolder/O/S root:VSANS_file:entry1:instrument	
			Make/O/T/N=1	location	= "NCNR"
			Make/O/T/N=1	description	= "NG3-VSANS"
			Make/O/T/N=1	type	= "VSANS"
			Make/O/T/N=1	local_contact	= "Steve Kline"
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:source	
				Make/O/T/N=1	name	= "NCNR"
				Make/O/T/N=1	type	= "Reactor Neutron Source"
				Make/O/T/N=1	probe	= "neutron"
				Make/O/D/N=1	power	= 20
					
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam_monitor_1	
				Make/O/D/N=1	data	
				Make/O/T/N=1	type	
				Make/O/D/N=1	efficiency	
				Make/O/D/N=1	nx_distance	
				Make/O/D/N=1	saved_count	
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam_monitor_2	
				Make/O/D/N=1	data	
				Make/O/T/N=1	type	
				Make/O/D/N=1	efficiency	
				Make/O/D/N=1	nx_distance	
				Make/O/D/N=1	saved_count	
					
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam	
					NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator	
					Make/O/D/N=1	wavelength	= 5.1
					Make/O/D/N=1	wavelength_spread	= 0.02
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:velocity_selector	
						Make/O/T/N=1	type	= "VS"
						Make/O/D/N=1	rotation_speed	= 5100
						Make/O/D/N=1	wavelength	= 6
						Make/O/D/N=1	wavelength_spread	= 0.15
						Make/O/D/N=1	vs_tilt	= 3
						Make/O/D/N=1	nx_distance	= 18.8
						//	table (wave)	
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:crystal	
						Make/O/D/N=1	nx_distance	= 1
						Make/O/D/N=1	wavelength	= 5.1
						Make/O/D/N=1	wavelength_spread	= 0.02
						Make/O/D/N=1	rotation	= 1.1
						Make/O/D/N=1	energy	= 1
						Make/O/D/N=1	wavevector	= 1
						Make/O/D/N=1	lattice_parameter	= 1
						Make/O/D/N=3	reflection	= {1,2,3}
						Make/O/D/N=1	horizontal_curvature	= 1
						Make/O/D/N=1	vertical_curvature	= 1
						Make/O/D/N=1	horizontal_aperture	= 1
						Make/O/D/N=1	vertical_aperture	= 1
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:white_beam	
							//description_of_distribution	
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:polarizer	
						Make/O/T/N=1	type	= "supermirror"
						Make/O/T/N=1	composition	= "multilayer"
						Make/O/D/N=1	efficiency	= 0.95
						Make/O/T/N=1	status	= "in"
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:flipper	
						Make/O/T/N=1	status	= "on"
						Make/O/D/N=1	driving_current	= 42
						Make/O/T/N=1	waveform	= "sine"
						Make/O/D/N=1	frequency	= 400
						Make/O/D/N=1	transmitted_power	= 0.99
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:polarizer_analyzer	
						Make/O/T/N=1	status	= "down"
						Make/O/D/N=1	guide_field_current_1	= 33
						Make/O/D/N=1	guide_field_current_2	= 32
						Make/O/D/N=1	solenoid_current	= 21
						Make/O/T/N=1	cell_name	= "Burgundy"
						Make/O/D/N=(5)	cell_parameters	= {1,2,3,4,5}
						NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam:monochromator:chopper	
						Make/O/T/N=1	type	= "single"
						Make/O/D/N=1	rotation_speed	= 12000
						Make/O/D/N=1	distance_from_source	= 400
						Make/O/D/N=1	distance_from_sample	= 1500
						Make/O/D/N=1	slits	= 2
						Make/O/D/N=1	angular_opening	= 15
						Make/O/D/N=1	duty_cycle	= 0.25
						//	+?	
					
				//ADD converging pinholes, etc	
					
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:attenuator	
				Make/O/D/N=1	nx_distance	= 1500
				Make/O/T/N=1	type	= "PMMA"
				Make/O/D/N=1	thickness	= 0
				Make/O/D/N=1	attenuator_transmission	= 1
				Make/O/T/N=1	status	= "in"
				Make/O/T/N=1	atten_number	= "0101"
				Make/O/D/N=(10,10)	index	= 1
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:source_aperture	
				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "source aperture"
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 13.0
					NewDataFolder/O/S root:VSANS_file:entry1:instrument:source_aperture:shape	
					Make/O/D/N=(1,2)	size	= 1.27
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:sample_aperture	
				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "sample aperture"
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 10
					NewDataFolder/O/S root:VSANS_file:entry1:instrument:sample_aperture:shape	
					Make/O/D/N=(1,2)	size	= 1.27
			SetDataFolder root:VSANS_file:entry1:instrument:
			Make/O/I/N=1	nx_NumGuides	= 1
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:lenses	
				Make/O/T/N=1	lens_geometry	= "concave_lens"
				Make/O/T/N=1	focus_type	= "point"
				Make/O/I/N=1	number_of_lenses	= 28
				Make/O/I/N=1	number_of_prisms	= 7
				Make/O/D/N=1	curvature	= 1
				Make/O/D/N=1	lens_distance	= 123
				Make/O/D/N=1	prism_distance	= 123
				Make/O/T/N=1	lens_material	= "MgF2"
				Make/O/T/N=1	prism_material	= "MgF2"
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:sample_table	
				Make/O/T/N=1	location	= "chamber"
				Make/O/D/N=1	offset_distance	= 0
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:beam_stop	
				Make/O/T/N=1	description	= "circular"
				Make/O/D/N=1	nx_distance	= 12.5
				Make/O/D/N=1	size	= 7.62
				Make/O/T/N=1	status	= "out"
				Make/O/D/N=1	xPos	= 66.4
				Make/O/D/N=1	yPos	= 64.4
				Make/O/D/N=1	x_motor_position	= 0.15
				Make/O/D/N=1	y_motor_position	= 0.55
					
					
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_B	
				Make/O/I/N=(320,320)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(320,320)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 21.1
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(256,256)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/I/N=1	PixelNumX	= 320
				Make/O/I/N=1	PixelNumY	= 320
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
				
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_MR	
				Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(48,256)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.1
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(48,256)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 48
				Make/O/I/N=1	PixelNumY	= 256
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
	
				Make/O/T/N=1	tube_orientation	= "vertical"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8

				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_ML
				Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(48,256)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.1
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(48,256)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 48
				Make/O/I/N=1	PixelNumY	= 256
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
	
				Make/O/T/N=1	tube_orientation	= "vertical"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
				
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_MT	
				Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(128,48)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.4
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,48)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	sdd_offset	= 30
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 48
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
						
				Make/O/T/N=1	tube_orientation	= "horizontal"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
				
				
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_MB
				Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(128,48)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.4
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,48)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	sdd_offset	= 30
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 48
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
						
				Make/O/T/N=1	tube_orientation	= "horizontal"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
						
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_FR	
				Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(48,256)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 2.1
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(48,256)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 48
				Make/O/I/N=1	PixelNumY	= 256
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
	
				Make/O/T/N=1	tube_orientation	= "vertical"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8

				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_FL
				Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(48,256)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 2.1
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(48,256)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 48
				Make/O/I/N=1	PixelNumY	= 256
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
	
				Make/O/T/N=1	tube_orientation	= "vertical"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
				
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_FT	
				Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(128,48)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 2.4
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,48)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	sdd_offset	= 30
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 48
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
						
				Make/O/T/N=1	tube_orientation	= "horizontal"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
				
				
				NewDataFolder/O/S root:VSANS_file:entry1:instrument:detector_FB
				Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
				Make/O/D/N=(128,48)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 2.4
				Make/O/T/N=1	description	= "fancy model"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "??"
				Make/O/D/N=1	flatfield_applied	= 0
				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,48)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/D/N=1	sdd_offset	= 30
				Make/O/D/N=1	separation	= 150
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 48
				Make/O/D/N=1	PixelFWHM	= 0.5
				//	calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
						
				Make/O/T/N=1	tube_orientation	= "horizontal"
				Make/O/I/N=1	number_of_tubes	= 48
				Make/O/I/N=(tubes)	tube_index	= p
				Make/O/D/N=(2,tubes)	spatial_calibration	= 1
				Make/O/D/N=1	tube_width	= 8
								
				//Detector_ML	
				//Detector_MT	
				//Detector_MB	
				//Detector_FL	
				//Detector_FR	
				//Detector_FT	
				//Detector_FB	
					
			NewDataFolder/O/S root:VSANS_file:entry1:data_B	
			Make/O/I/N=(320,320)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(320,320)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {320,320}
			NewDataFolder/O/S root:VSANS_file:entry1:data_MR	
			Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(48,256)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {48,256}
			NewDataFolder/O/S root:VSANS_file:entry1:data_ML	
			Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(48,256)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {48,256}
			NewDataFolder/O/S root:VSANS_file:entry1:data_MT	
			Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(128,48)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,48}
			NewDataFolder/O/S root:VSANS_file:entry1:data_MB	
			Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(128,48)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,48}
			NewDataFolder/O/S root:VSANS_file:entry1:data_FR	
			Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(48,256)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {48,256}
			NewDataFolder/O/S root:VSANS_file:entry1:data_FL	
			Make/O/I/N=(48,256)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(48,256)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {48,256}
			NewDataFolder/O/S root:VSANS_file:entry1:data_FT	
			Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(128,48)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,48}
			NewDataFolder/O/S root:VSANS_file:entry1:data_FB	
			Make/O/I/N=(128,48)	data	= trunc(abs(gnoise(p+q)))
			Make/O/D/N=(128,48)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,48}
				
			NewDataFolder/O/S root:VSANS_file:entry1:reduction	
			Make/O/T/N=1	intent	= "SCATTER"
			Make/O/T/N=1	transmission_file_name	= "SANSFile_TRN.h5"
			Make/O/T/N=1	empty_beam_file_name	= "SANSFile_EB.h5"
			Make/O/T/N=1	background_file_name	= "SANSFile_BKG.h5"
			Make/O/T/N=1	empty_file_name	= "SANSFile_EMP.h5"
			Make/O/T/N=1	sensitivity_file_name	= "SANSFile_DIV.h5"
			Make/O/T/N=1	mask_file_name	= "SANSFile_MASK.h5"
			Make/O/T/N=1	sans_log_file_name	= "SANSFile_log.txt"
			Make/O/D/N=1	whole_trans	= 0.888
			Make/O/D/N=1	whole_trans_error	= 0.008
			Make/O/D/N=1	box_count	= 23232
			Make/O/D/N=1	box_count_error	= 22
			Make/O/I/N=4	box_coordinates	= {50,80,45,75}
			Make/O/T/N=1	notes	= "extra data notes"
				NewDataFolder/O/S root:VSANS_file:entry1:reduction:pol_sans	
				Make/O/T/N=1	pol_sans_purpose	= "name from the list"
				Make/O/T/N=1	cell_name	= "Burgundy"
				Make/O/D/N=(5)	cell_parameters	= {1,2,3,4,5}
						
		NewDataFolder/O/S root:VSANS_file:entry1:DAS_Logs	
			//...multiple entries and levels... to add	
			//this will be enormous	

	
	SetDataFolder root:
	
End


// TODO
// issues here with the potential for Nexus to have data as INTEGER
// where I'd rather have the data here in Igor be DP, so there are no 
// conversion/assignment issues
//
// simuation from VCALC = DP, but I need to assign to an Integer wave...
// - sometimes this works, sometimes not...
// may need to Redimension/I
//
/// break this up into several smaller procedures as this is a VERY lengthy task to do

	// TODO
// set the "accessible" copies of the data (these are really to be links in the file!)

Macro Fill_VSANS_w_Sim()

	SetDataFolder root:VSANS_file
	
		file_name	= "VSANSTest.h5"
		file_time	= "2015-02-28T08:15:30-5:00"
		facility	= "NCNR"
		NeXus_version	= "Nexus 0.0"
		hdf_version	= "hdf5.x"
		file_history	= "history log"
		SetDataFolder root:VSANS_file:entry1	
			title	= "title of entry1"
			experiment_identifier	= 684636
			experiment_description	= "description of expt"
			entry_identifier	= "S22-33"
			definition	= "NXsas"
			start_time	= "2015-02-28T08:15:30-5:00"
			end_time	= "2015-02-28T08:15:30-5:00"
			duration	= 300
			collection_time	= 300
			run_cycle	= "S22-23"
			intent	= "RAW"
			data_directory	= "[VSANS_VSANS]"
			SetDataFolder root:VSANS_file:entry1:user	
				name	= "Dr. Pi"
				role	= "evil scientist"
				affiliation	= "NIST"
				address	= "100 Bureau Drive"
				telephoneNumber	= "301-999-9999"
				faxNumber	= "301-999-9999"
				email	= "sans@nist"
				facility_user_id	= 6937596
			SetDataFolder root:VSANS_file:entry1:control	
				mode	= "timer"
				preset	= 555
				integral	= 555
				monitor_counts	= 666
				monitor_preset	= 1e8
				type	= "monitor type"
				efficiency	= 0.01
				sampled_fraction	= 1
				nominal	= 1e8
				data	= 1
				nx_distance	= 13.1
				detector_counts	= 100111222
				detector_preset	= 1e5
				detector_mask	= 1
			SetDataFolder root:VSANS_file:entry1:program_name	
				data	= "program data"
				description	= "acquisition"
				file_name	= "NICE"
				type	= "client"
			SetDataFolder root:VSANS_file:entry1:sample	
				name	= "My Sample"
				chemical_formula	= "C8H10N4O2"
				SetDataFolder root:VSANS_file:entry1:sample:temperature_1	
					name	= "Sample temperature"
					attached_to	= "block"
					measurement	= "temperature"
					units	= "C"
					SetDataFolder root:VSANS_file:entry1:sample:temperature_1:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 2*p
				SetDataFolder root:VSANS_file:entry1:sample:temperature_2	
					name	= "Sample temperature"
					attached_to	= "block"
					measurement	= "temperature"
					units	= "C"
					SetDataFolder root:VSANS_file:entry1:sample:temperature_2:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 3*p
				SetDataFolder root:VSANS_file:entry1:sample:electric_field	
					name	= "electric meter"
					attached_to	= "sample"
					measurement	= "voltage"
					units	= "mV"
					SetDataFolder root:VSANS_file:entry1:sample:electric_field:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= 2*p
						value	= sin(p/10)
				SetDataFolder root:VSANS_file:entry1:sample:shear_field	
					name	= "rheometer"
					attached_to	= "sample"
					measurement	= "stress"
					units	= "Hz"
					SetDataFolder root:VSANS_file:entry1:sample:shear_field:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= cos(p/5)
				SetDataFolder root:VSANS_file:entry1:sample:pressure	
					name	= "Sample pressure"
					attached_to	= "pressure cell"
					measurement	= "pressure"
					units	= "psi"
					SetDataFolder root:VSANS_file:entry1:sample:pressure:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= p/2
				SetDataFolder root:VSANS_file:entry1:sample:magnetic_field	
					name	= "magnetic field (direction)"
					attached_to	= "cryostat"
					measurement	= "magnetic field"
					units	= "G"
					SetDataFolder root:VSANS_file:entry1:sample:magnetic_field:value_log	
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 10*p
					
			SetDataFolder root:VSANS_file:entry1:sample
				changer_position	= 5
				sample_holder_description	= "10CB"
				mass	= 0.3
				density	= 1.02
				molecular_weight	= 194.19
				description	= "My Sample"
				preparation_date	= "2015-02-28T08:15:30-5:00"
				volume_fraction	= 0.2
				scattering_length_density	= 6.35e-6
				thickness	= 0.1
				rotation_angle	= 30
				transmission	= 0.888
				transmission_error	= 0.011
				xs_incoh	= 5.5
				xs_coh	= 22.2
				xs_absorb	= 3.1
			SetDataFolder root:VSANS_file:entry1:instrument	
				location	= "NCNR"
				description	= "NG3-VSANS"
				type	= "VSANS"
				local_contact	= "Steve Kline"
				SetDataFolder root:VSANS_file:entry1:instrument:source	
					name	= "NCNR"
					type	= "Reactor Neutron Source"
					probe	= "neutron"
					power	= 20
					
				SetDataFolder root:VSANS_file:entry1:instrument:beam_monitor_1	
					data	= 1234567
					type	= "monitor"
					efficiency	= 0.01
					nx_distance	= 16
					saved_count	= 1e8
				SetDataFolder root:VSANS_file:entry1:instrument:beam_monitor_2	
					data	= 1234567
					type	= "monitor"
					efficiency	= 0.01
					nx_distance	= 16
					saved_count	= 1e8	
					
				SetDataFolder root:VSANS_file:entry1:instrument:beam	
					SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator	
						wavelength	= VCALC_getWavelength()
						wavelength_spread	= 0.02
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:velocity_selector	
							type	= "VS"
							rotation_speed	= 5100
							wavelength	= VCALC_getWavelength()
							wavelength_spread	= 0.15
							vs_tilt	= 3
							nx_distance	= 18.8
						//	table (wave)	
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:crystal	
							nx_distance	= 1
							wavelength	= 5.1
							wavelength_spread	= 0.02
							rotation	= 1.1
							energy	= 1
							wavevector	= 1
							lattice_parameter	= 1
							reflection	= {1,2,3}
							horizontal_curvature	= 1
							vertical_curvature	= 1
							horizontal_aperture	= 1
							vertical_aperture	= 1
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:white_beam	
							//description_of_distribution	
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:polarizer	
							type	= "supermirror"
							composition	= "multilayer"
							efficiency	= 0.95
							status	= "in"
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:flipper	
							status	= "on"
							driving_current	= 42
							waveform	= "sine"
							frequency	= 400
							transmitted_power	= 0.99
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:polarizer_analyzer	
							status	= "down"
							guide_field_current_1	= 33
							guide_field_current_2	= 32
							solenoid_current	= 21
							cell_name	= "Burgundy"
							cell_parameters	= {1,2,3,4,5}
						SetDataFolder root:VSANS_file:entry1:instrument:beam:monochromator:chopper	
							type	= "single"
							rotation_speed	= 12000
							distance_from_source	= 400
							distance_from_sample	= 1500
							slits	= 2
							angular_opening	= 15
							duty_cycle	= 0.25
						//	+?	
					
				//ADD converging pinholes, etc	
					
				SetDataFolder root:VSANS_file:entry1:instrument:attenuator	
					nx_distance	= 1500
					type	= "PMMA"
					thickness	= 0
					attenuator_transmission	= 1
					status	= "in"
					atten_number	= "0101"
				Make/O/D/N=(10,10)	index	= 1
				SetDataFolder root:VSANS_file:entry1:instrument:source_aperture	
					material	= "Gd"
					description	= "source aperture"
					diameter	= 1.27
					nx_distance	= 13.0
					SetDataFolder root:VSANS_file:entry1:instrument:source_aperture:shape	
						size	= 1.27
				SetDataFolder root:VSANS_file:entry1:instrument:sample_aperture	
					material	= "Gd"
					description	= "sample aperture"
					diameter	= 1.27
					nx_distance	= 10
					SetDataFolder root:VSANS_file:entry1:instrument:sample_aperture:shape	
						size	= 1.27
			SetDataFolder root:VSANS_file:entry1:instrument:
				nx_NumGuides	= 1
				SetDataFolder root:VSANS_file:entry1:instrument:lenses	
					lens_geometry	= "concave_lens"
					focus_type	= "point"
					number_of_lenses	= 28
					number_of_prisms	= 7
					curvature	= 1
					lens_distance	= 123
					prism_distance	= 123
					lens_material	= "MgF2"
					prism_material	= "MgF2"
				SetDataFolder root:VSANS_file:entry1:instrument:sample_table	
					location	= "chamber"
					offset_distance	= 0
				SetDataFolder root:VSANS_file:entry1:instrument:beam_stop	
					description	= "circular"
					nx_distance	= 12.5
					size	= 7.62
					status	= "out"
					xPos	= 66.4
					yPos	= 64.4
					x_motor_position	= 0.15
					y_motor_position	= 0.55
					
					
				SetDataFolder root:VSANS_file:entry1:instrument:detector_B	
					data	= root:Packages:NIST:VSANS:VCALC:Back:det_B
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("B")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					PixelNumX	= 320
					PixelNumY	= 320
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
				
				SetDataFolder root:VSANS_file:entry1:instrument:detector_MR	
					data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MR
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("MR")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					separation = VCALC_getPanelSeparation("MR")
					PixelNumX	= 48
					PixelNumY	= 256
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
	
					tube_orientation	= "vertical"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8

				SetDataFolder root:VSANS_file:entry1:instrument:detector_ML
					data	= root:Packages:NIST:VSANS:VCALC:Middle:det_ML
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("ML")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					separation = VCALC_getPanelSeparation("ML")
					PixelNumX	= 48
					PixelNumY	= 256
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
	
					tube_orientation	= "vertical"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8
				
				SetDataFolder root:VSANS_file:entry1:instrument:detector_MT	
					data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MT
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("MT")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					sdd_offset = VCALC_getTopBottomSDDOffset("MT")
					separation = VCALC_getPanelSeparation("MT")
					PixelNumX	= 128
					PixelNumY	= 48
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
						
					tube_orientation	= "horizontal"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8
				
				
				SetDataFolder root:VSANS_file:entry1:instrument:detector_MB
					data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MB
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("MB")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					sdd_offset = VCALC_getTopBottomSDDOffset("MB")
					separation = VCALC_getPanelSeparation("MB")
					PixelNumX	= 128
					PixelNumY	= 48
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
						
					tube_orientation	= "horizontal"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8
						
				SetDataFolder root:VSANS_file:entry1:instrument:detector_FR	
					data	= root:Packages:NIST:VSANS:VCALC:Front:det_FR
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("FR")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					separation = VCALC_getPanelSeparation("FR")
					PixelNumX	= 48
					PixelNumY	= 256
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
	
					tube_orientation	= "vertical"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8

				SetDataFolder root:VSANS_file:entry1:instrument:detector_FL
					data	= root:Packages:NIST:VSANS:VCALC:Front:det_FL
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("FL")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					separation = VCALC_getPanelSeparation("FL")
					PixelNumX	= 48
					PixelNumY	= 256
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
	
					tube_orientation	= "vertical"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8
				
				SetDataFolder root:VSANS_file:entry1:instrument:detector_FT	
					data	= root:Packages:NIST:VSANS:VCALC:Front:det_FT
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("FT")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					sdd_offset = VCALC_getTopBottomSDDOffset("FT")
					separation = VCALC_getPanelSeparation("FT")
					PixelNumX	= 128
					PixelNumY	= 48
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
						
					tube_orientation	= "horizontal"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8
				
				
				SetDataFolder root:VSANS_file:entry1:instrument:detector_FB
					data	= root:Packages:NIST:VSANS:VCALC:Front:det_FB
					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= VCALC_getSDD("FB")
					description	= "fancy model"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "??"
					flatfield_applied	= 0
					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					sdd_offset = VCALC_getTopBottomSDDOffset("FB")
					separation = VCALC_getPanelSeparation("FB")
					PixelNumX	= 128
					PixelNumY	= 48
					PixelFWHM	= 0.5
				//	calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
						
					tube_orientation	= "horizontal"
					number_of_tubes	= 48
					tube_index	= p
					spatial_calibration	= 1
					tube_width	= 8

// SRK -set the top level copies of the data					
			SetDataFolder root:VSANS_file:entry1:data_B	
				data	= root:Packages:NIST:VSANS:VCALC:Back:det_B
				error	= 0.01*abs(gnoise(p+q))
				variables	= {320,320}
			SetDataFolder root:VSANS_file:entry1:data_MR	
				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MR
				error	= 0.01*abs(gnoise(p+q))
				variables	= {48,256}
			SetDataFolder root:VSANS_file:entry1:data_ML	
				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_ML
				error	= 0.01*abs(gnoise(p+q))
				variables	= {48,256}
			SetDataFolder root:VSANS_file:entry1:data_MT	
				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MT
				data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
				error	= 0.01*abs(gnoise(p+q))
				variables	= {128,48}
			SetDataFolder root:VSANS_file:entry1:data_MB	
				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MB
				data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
				error	= 0.01*abs(gnoise(p+q))
				variables	= {128,48}
			SetDataFolder root:VSANS_file:entry1:data_FR	
				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FR
				error	= 0.01*abs(gnoise(p+q))
				variables	= {48,256}
			SetDataFolder root:VSANS_file:entry1:data_FL	
				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FL
				error	= 0.01*abs(gnoise(p+q))
				variables	= {48,256}
			SetDataFolder root:VSANS_file:entry1:data_FT	
				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FT
				data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
				error	= 0.01*abs(gnoise(p+q))
				variables	= {128,48}
			SetDataFolder root:VSANS_file:entry1:data_FB	
				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FB
				data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
				error	= 0.01*abs(gnoise(p+q))
				variables	= {128,48}
				
			SetDataFolder root:VSANS_file:entry1:reduction	
				intent	= "SCATTER"
				transmission_file_name	= "SANSFile_TRN.h5"
				empty_beam_file_name	= "SANSFile_EB.h5"
				background_file_name	= "SANSFile_BKG.h5"
				empty_file_name	= "SANSFile_EMP.h5"
				sensitivity_file_name	= "SANSFile_DIV.h5"
				mask_file_name	= "SANSFile_MASK.h5"
				sans_log_file_name	= "SANSFile_log.txt"
				whole_trans	= 0.888
				whole_trans_error	= 0.008
				box_count	= 23232
				box_count_error	= 22
				box_coordinates	= {50,80,45,75}
				notes	= "extra data notes"
				SetDataFolder root:VSANS_file:entry1:reduction:pol_sans	
					pol_sans_purpose	= "name from the list"
					cell_name	= "Burgundy"
					cell_parameters	= {1,2,3,4,5}


		
		SetDataFolder root:		
				

End




	
//Function H_Test_HDFWriteTrans(fname,val)
//	String fname
//	Variable val
//	
//	
//	String str
//	PathInfo home
//	str = S_path
//	
//	H_WriteTransmissionToHeader(str+fname,val)
//	
//	return(0)
//End
//
//Function H_WriteTransmissionToHeader(fname,trans)
//	String fname
//	Variable trans
//	
//	Make/O/D/N=1 wTmpWrite
//	String groupName = "/Sample"	//	/Run1/Sample becomes groupName /Run1/Run1/Sample
//	String varName = "TRNS"
//	wTmpWrite[0] = trans //
//
//	variable err
//	err = HDFWrite_Wave(fname, groupName, varName, wTmpWrite)
//	KillWaves wTmpWrite
//	
//	//err not handled here
//		
//	return(0)
//End



Function H_Test_ListAttributes(fname,groupName)
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
	err = H_HDF_ListAttributes(str+fname, groupName)
	
	//err not handled here
		
	return(0)
End

Function H_HDF_ListAttributes(fname, groupName)
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
			HDF5AttributeInfo(fileID, "/", 1, "NeXus_version", 0, di)
			Print di

//			see the HDF5 Browser  for how to get the actual <value> of the attribute. See GetPreviewString in 
//        or in FillGroupAttributesList or in FillDatasetAttributesList (from FillLists)
//			it seems to be ridiculously complex to get such a simple bit of information - the HDF5BrowserData STRUCT
// 			needs to be filled first. Ugh.
			attrValue = GetPreviewString(fileID, 1, di, "/entry", "cucumber")
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


Macro Save_VSANS_file(dfPath, filename)
	String dfPath	="root:VSANS_file"		// e.g., "root:FolderA" or ":"
	String filename = "Test_VSANS_file.h5"
	
	H_NXSANS_SaveGroupAsHDF5(dfPath, filename)
End
	
// this is my procedure to save the folders to HDF5, once I've filled the folder tree
//
Function H_NXSANS_SaveGroupAsHDF5(dfPath, filename)
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
Macro H_HDF5Gate_WriteTest()

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

Macro H_HDF5Gate_ReadTest(file)
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
Function H_FillRTIFromHDFTree(folderStr)
	String folderStr

	WAVE rw = root:Packages:NIST:RAW:RealsRead
	WAVE iw = root:Packages:NIST:RAW:IntegersRead
	WAVE/T tw = root:Packages:NIST:RAW:TextRead

	rw = -999
	iw = 11111
	tw = "jibberish"
	
	folderStr = H_RemoveDotExtension(folderStr)		// to make sure that the ".h5" or any other extension is removed
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


//given a filename of a SANS data filename of the form
// name.anything
//returns the name as a string without the ".fbdfasga" extension
//
// returns the input string if a "." can't be found (maybe it wasn't there"
Function/S H_RemoveDotExtension(item)
	String item
	String invalid = item	//
	Variable num=-1
	
	//find the "dot"
	String runStr=""
	Variable pos = strsearch(item,".",0)
	if(pos == -1)
		//"dot" not found
		return (invalid)
	else
		//found, get all of the characters preceeding it
		runStr = item[0,pos-1]
		return (runStr)
	Endif
End




////////////////////////////////////////////////////
//
//
//
//Macro H_BatchConvertToHDF5(firstFile,lastFile)
//	Variable firstFile=1,lastFile=100
//
//	H_SetupStructure()
//	H_fBatchConvertToHDF5(firstFile,lastFile)
//
//End
//
//// lo is the first file number
//// hi is the last file number (inclusive)
////
//Function H_fBatchConvertToHDF5(lo,hi)
//	Variable lo,hi
//	
//	Variable ii
//	String file
//	
//	String fname="",pathStr="",fullPath="",newFileName=""
//
//	PathInfo catPathName			//this is where the files are
//	pathStr=S_path
//	
//	//loop over all files
//	for(ii=lo;ii<=hi;ii+=1)
//		file = FindFileFromRunNumber(ii)
//		if(strlen(file) != 0)
//			// load the data
//			ReadHeaderAndData(file)		//file is the full path
//			String/G root:myGlobals:gDataDisplayType="RAW"	
//			fRawWindowHook()
//			WAVE/T/Z tw = $"root:Packages:NIST:RAW:textRead"	//to be sure that wave exists if no data was ever displayed
//			newFileName= GetNameFromHeader(tw[0])		//02JUL13
//			
//			// convert it
////			H_FillStructureFromRTI()
//			
//			// save it
//			H_NXSANS_SaveGroupAsHDF5("root:entry1", newfilename[0,7]+".h5")
//
//		else
//			printf "run number %d not found\r",ii
//		endif
//	endfor
//	
//	return(0)
//End
//
