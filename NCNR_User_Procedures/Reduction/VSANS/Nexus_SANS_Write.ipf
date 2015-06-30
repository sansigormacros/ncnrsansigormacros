#pragma rtGlobals=1		// Use modern global access method.


//
// this is a test of the "new" SANS file structure that is supposed to be
// NeXus compliant. It doesn't have the NICE logs, but has everything that I 
// can think of here.
//





//
// lays out the tree and fills with dummy values
//
Proc H_Setup_SANS_Structure()
	
	Variable n=100
	
NewDataFolder/O/S root:SANS_file	
	Make/O/T/N=1	file_name	= "SANSTest.h5"
	Make/O/T/N=1	file_time	= "2015-02-28T08:15:30-5:00"
	Make/O/T/N=1	facility	= "NCNR"
	Make/O/T/N=1	NeXus_version	= "Nexus 0.0"
	Make/O/T/N=1	hdf_version	= "hdf5.x"
	Make/O/T/N=1	file_history	= "history log"
	NewDataFolder/O/S  root:SANS_file:entry1		
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
		Make/O/T/N=1	data_directory	= "[NG7SANS41]"
		Make/O/T/N=1	program_name	= "runPoint={stuff}"
		NewDataFolder/O/S  root:SANS_file:entry1:user		
			Make/O/T/N=1	name	= "Dr. Pi"
			Make/O/T/N=1	role	= "evil scientist"
			Make/O/T/N=1	affiliation	= "NIST"
			Make/O/T/N=1	address	= "100 Bureau Drive"
			Make/O/T/N=1	telephoneNumber	= "301-999-9999"
			Make/O/T/N=1	faxNumber	= "301-999-9999"
			Make/O/T/N=1	email	= "sans@nist"
			Make/O/I/N=1	facility_user_id	= 6937596
		NewDataFolder/O/S  root:SANS_file:entry1:control		
			Make/O/T/N=1	mode	= "timer"
			Make/O/D/N=1	preset	= 555
			Make/O/D/N=1	integral	= 555
			Make/O/D/N=1	monitor_counts	= 666
			Make/O/D/N=1	monitor_preset	= 1e8
			Make/O/D/N=1	detector_counts	= 100111222
			Make/O/D/N=1	detector_preset	= 1e5
//			Make/O/T/N=1	type	= "monitor type"
//			Make/O/D/N=1	efficiency	= 0.01
//			Make/O/D/N=1	sampled_fraction	= 1
			Make/O/D/N=1	count_start	= 1
			Make/O/D/N=1	count_end	= 1
			Make/O/D/N=1	count_time	= 1
			Make/O/D/N=1	count_time_preset	= 1
//		NewDataFolder/O/S  root:SANS_file:entry1:program_name		
//			Make/O/T/N=1	data	= "program data"
//			Make/O/T/N=1	description	= "acquisition"
//			Make/O/T/N=1	file_name	= "NICE"
//			Make/O/T/N=1	type	= "client"
		NewDataFolder/O/S  root:SANS_file:entry1:sample		
			Make/O/T/N=1	description	= "My Sample"
			Make/O/D/N=1	group_id	= 12345
//			Make/O/T/N=1	chemical_formula	= "C8H10N4O2"
			NewDataFolder/O/S  root:SANS_file:entry1:sample:temperature_1		
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:temperature_1:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 2*p
			NewDataFolder/O/S  root:SANS_file:entry1:sample:temperature_2		
				Make/O/T/N=1	name	= "Sample temperature"
				Make/O/T/N=1	attached_to	= "block"
				Make/O/T/N=1	measurement	= "temperature"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:temperature_2:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 3*p
			NewDataFolder/O/S  root:SANS_file:entry1:sample:electric_field		
				Make/O/T/N=1	name	= "electric meter"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "voltage"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:electric_field:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= 2*p
					Make/O/D/N=(n)	value	= sin(p/10)
			NewDataFolder/O/S  root:SANS_file:entry1:sample:shear_field		
				Make/O/T/N=1	name	= "rheometer"
				Make/O/T/N=1	attached_to	= "sample"
				Make/O/T/N=1	measurement	= "stress"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:shear_field:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= cos(p/5)
			NewDataFolder/O/S  root:SANS_file:entry1:sample:pressure		
				Make/O/T/N=1	name	= "Sample pressure"
				Make/O/T/N=1	attached_to	= "pressure cell"
				Make/O/T/N=1	measurement	= "pressure"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:pressure:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= p/2
			NewDataFolder/O/S  root:SANS_file:entry1:sample:magnetic_field		
				Make/O/T/N=1	name	= "magnetic field (direction)"
				Make/O/T/N=1	attached_to	= "cryostat"
				Make/O/T/N=1	measurement	= "magnetic field"
				NewDataFolder/O/S  root:SANS_file:entry1:sample:magnetic_field:value_log		
					Make/O/T/N=1	start	= "2015-02-28T08:15:30-5:00"
					Make/O/D/N=(n)	nx_time	= p
					Make/O/D/N=(n)	value	= 10*p
			SetDataFolder  root:SANS_file:entry1:sample		
			Make/O/D/N=1	changer_position	= 5
			Make/O/T/N=1	sample_holder_description	= "10CB"
//			Make/O/D/N=1	mass	= 0.3
//			Make/O/D/N=1	density	= 1.02
//			Make/O/D/N=1	molecular_weight	= 194.19
//			Make/O/T/N=1	description	= "My Sample"
//			Make/O/T/N=1	preparation_date	= "2015-02-28T08:15:30-5:00"
//			Make/O/D/N=1	volume_fraction	= 0.2
//			Make/O/D/N=1	scattering_length_density	= 6.35e-6
			Make/O/D/N=1	thickness	= 0.1
			Make/O/D/N=1	rotation_angle	= 30
			Make/O/D/N=1	transmission	= 0.888
			Make/O/D/N=1	transmission_error	= 0.011
//			Make/O/D/N=1	xs_incoh	= 5.5
//			Make/O/D/N=1	xs_coh	= 22.2
//			Make/O/D/N=1	xs_absorb	= 3.1
		NewDataFolder/O/S  root:SANS_file:entry1:instrument		
//			Make/O/T/N=1	location	= "NCNR"
			Make/O/T/N=1	name	= "NGB30mSANS"
			Make/O/T/N=1	type	= "30 m SANS"
			Make/O/T/N=1	local_contact	= "Steve Kline"
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:source		
				Make/O/T/N=1	name	= "NCNR"
				Make/O/T/N=1	type	= "Reactor Neutron Source"
				Make/O/T/N=1	probe	= "neutron"
				Make/O/D/N=1	power	= 20
			NewDataFolder/O/S root:SANS_file:entry1:instrument:beam_monitor		
				Make/O/D/N=1	data	= 1234567
				Make/O/T/N=1	type	= "monitor"
				Make/O/D/N=1	efficiency	= 0.01
				Make/O/D/N=1	nx_distance	= 16
				Make/O/D/N=1	saved_count	= 1e8
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:monochromator		
				Make/O/D/N=1	wavelength	= 6
				Make/O/D/N=1	wavelength_spread	= 0.15
				Make/O/T/N=1	type	= "VS"
				NewDataFolder/O/S  root:SANS_file:entry1:instrument:monochromator:velocity_selector		
					Make/O/D/N=1	rotation_speed	= 5100
					Make/O/D/N=1	wavelength	= 6
					Make/O/D/N=1	wavelength_spread	= 0.15
					Make/O/D/N=1	vs_tilt	= 3
					Make/O/D/N=1	nx_distance	= 18.8
						//table	
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:polarizer		
				Make/O/T/N=1	type	= "supermirror"
				Make/O/T/N=1	composition	= "multilayer"
				Make/O/D/N=1	efficiency	= 0.95
				Make/O/T/N=1	status	= "in"
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:flipper		
				Make/O/T/N=1	status	= "on"
				Make/O/D/N=1	driving_current	= 42
				Make/O/T/N=1	waveform	= "sine"
				Make/O/D/N=1	frequency	= 400
				Make/O/D/N=1	transmitted_power	= 0.99
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:polarizer_analyzer		
				Make/O/T/N=1	status	= "down"
				Make/O/D/N=1	guide_field_current_1	= 33
				Make/O/D/N=1	guide_field_current_2	= 32
				Make/O/D/N=1	solenoid_current	= 21
				Make/O/D/N=1	cell_index	= 1
				Make/O/T/N=(5)	cell_names	= {"Burgundy","Olaf","Jim","Bob","Joe"}
				Make/O/D/N=(5,2)	cell_parameters	= 1
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:chopper		
				Make/O/T/N=1	type	= "single"
				Make/O/T/N=1	status	= "in"
				Make/O/D/N=1	rotation_speed	= 12000
				Make/O/D/N=1	distance_from_source	= 400
				Make/O/D/N=1	distance_from_sample	= 1500
				Make/O/D/N=1	slits	= 2
				Make/O/D/N=1	angular_opening	= 15
				Make/O/D/N=1	duty_cycle	= 0.25
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:attenuator		
				Make/O/D/N=1	nx_distance	= 1500
				Make/O/T/N=1	type	= "PMMA"
				Make/O/D/N=1	thickness	= 0
				Make/O/D/N=1	attenuator_transmission	= 1
				Make/O/T/N=1	status	= "in"
				Make/O/D/N=1	atten_number	= 0
				Make/O/D/N=(10,10)	index	= 1
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:source_aperture		
//				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "source aperture"
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 13.0
				NewDataFolder/O/S  root:SANS_file:entry1:instrument:source_aperture:shape		
					Make/O/D/N=(1,2)	size	= 1.27
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:sample_aperture		
//				Make/O/T/N=1	material	= "Gd"
				Make/O/T/N=1	description	= "sample aperture"
				Make/O/D/N=1	diameter	= 1.27
				Make/O/D/N=1	nx_distance	= 10
				NewDataFolder/O/S  root:SANS_file:entry1:instrument:sample_aperture:shape		
					Make/O/D/N=(1,2)	size	= 1.27
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:collimator		
				NewDataFolder/O/S root:SANS_file:entry1:instrument:collimator:geometry		
					NewDataFolder/O/S root:SANS_file:entry1:instrument:collimator:geometry:shape		
						Make/O/T/N=1	shape	= "box"
						Make/O/D/N=1	size	= 11
				Make/O/I/N=1	nx_NumGuides	= 1
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:lenses		
				Make/O/T/N=1	status	= "in"
				Make/O/T/N=1	lens_geometry	= "concave_lens"
				Make/O/T/N=1	focus_type	= "point"
				Make/O/I/N=1	number_of_lenses	= 28
				Make/O/I/N=1	number_of_prisms	= 7
				Make/O/D/N=1	curvature	= 1
				Make/O/D/N=1	lens_distance	= 123
				Make/O/D/N=1	prism_distance	= 123
				Make/O/T/N=1	lens_material	= "MgF2"
				Make/O/T/N=1	prism_material	= "MgF2"
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:sample_table		
				Make/O/T/N=1	location	= "chamber"
				Make/O/D/N=1	offset_distance	= 0
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:beam_stop		
				Make/O/T/N=1	description	= "circular"
				Make/O/D/N=1	nx_distance	= 12.5
				Make/O/D/N=1	size	= 7.62
				Make/O/T/N=1	status	= "out"
				Make/O/D/N=1	xPos	= 66.4
				Make/O/D/N=1	yPos	= 64.4
				Make/O/D/N=1	x_motor_position	= 0.15
				Make/O/D/N=1	y_motor_position	= 0.55
			NewDataFolder/O/S  root:SANS_file:entry1:instrument:detector		
				Make/O/I/N=(128,128)	data	= trunc(abs(gnoise(p+q)))
//				Make/O/D/N=(128,128)	data_error	= 0.01*abs(gnoise(p+q))
				Make/O/D/N=1	nx_distance	= 13.1
				Make/O/T/N=1	description	= "Ordela 2660N"
				Make/O/T/N=1	settings	= "just right"
				Make/O/D/N=1	dead_time	= 5e-6
				Make/O/D/N=1	x_pixel_size	= 5.08
				Make/O/D/N=1	y_pixel_size	= 5.08
				Make/O/D/N=1	beam_center_x	= 65.55
				Make/O/D/N=1	beam_center_y	= 62.33
				Make/O/T/N=1	type	= "Ordela"
//				Make/O/D/N=1	flatfield_applied	= 0
//				Make/O/D/N=1	countrate_correction_applied	= 0
				Make/O/D/N=(128,128)	pixel_mask	= 0
				Make/O/I/N=1	integrated_count	= 100111222
				Make/O/D/N=1	lateral_offset	= 20
				Make/O/I/N=1	PixelNumX	= 128
				Make/O/I/N=1	PixelNumY	= 128
				Make/O/D/N=1	PixelFWHM	= 0.5
					//calibration_method	
				Make/O/D/N=3	CALX	= {0.5,0.5,10000}
				Make/O/D/N=3	CALY	= {0.5,0.5,10000}
				Make/O/D/N=1	size	= 65
				Make/O/T/N=1	event_file_name	="something.hst"
		NewDataFolder/O/S  root:SANS_file:entry1:data		
			Make/O/I/N=(128,128)	data	= trunc(abs(gnoise(p+q)))
//			Make/O/D/N=(128,128)	error	= 0.01*abs(gnoise(p+q))
			Make/O/D/N=2	variables	= {128,128}
			Make/O/I/N=(128,128)	data_image	= p
		NewDataFolder/O/S  root:SANS_file:entry1:reduction		
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
			Make/O/T/N=1	comments	= "extra data comments"
			Make/O/D/N=4	absolute_scaling	= {1,1,1e5,1}
			NewDataFolder/O/S  root:SANS_file:entry1:reduction:pol_sans		
				Make/O/T/N=1	pol_sans_purpose	= "name from the list"
				Make/O/T/N=1	cell_name	= "Burgundy"
				Make/O/D/N=(5)	cell_parameters	= {1,2,3,4,5}
						

	NewDataFolder/O/S  root:SANS_file:DAS_Logs		
			//...multiple entries and levels... to add	

	SetDataFolder root:
	
End




Proc H_Fill_SANS_Attributes()

SetDataFolder  root:SANS_file		
	Make/O/N=0 Igor___folder_attributes	
	Note/K Igor___folder_attributes, "producer=IgorPro\rNX_class=NXroot"
	//	file_name		
	//	file_time		
	//	facility		
	//	NeXus_version		
	//	hdf_version		
	//	file_history		
	SetDataFolder  root:SANS_file:entry1		
		Make/O/N=0 Igor___folder_attributes	
		Note/K Igor___folder_attributes, "NX_class=NXentry"
		//	title		
		//	experiment_identifier		
		//	experiment_description		
		//	entry_identifier		
		//	definition		
		//	start_time		
		//	end_time		
		//	duration		
		Note/K duration, "units=s"
		//	collection_time		
		Note/K collection_time, "units=s"
		//	run_cycle		
		//	data_directory		
		//	program_name		
		SetDataFolder  root:SANS_file:entry1:user		
			Make/O/N=0 Igor___folder_attributes	
			Note/K Igor___folder_attributes, "NX_class=NXuser"
			//	name		
			//	role		
			//	affiliation		
			//	address		
			//	telephoneNumber		
			//	faxNumber		
			//	email		
			//	facility_user_id		
		SetDataFolder  root:SANS_file:entry1:control		
			Make/O/N=0 Igor___folder_attributes	
			Note/K Igor___folder_attributes, "NX_class=NXmonitor"
			//	mode		
			//	preset		
			//	integral		
			//	monitor_counts		
			//	monitor_preset		
			//	detector_counts		
			//	detector_preset		
			//	type		
			//	efficiency		
			//	sampled_fraction		
			//	count_start		
			Note/K count_start, "units=s"
			//	count_end		
			Note/K count_end, "units=s"
			//	count_time		
			Note/K count_time, "units=s"
			//	count_time_preset		
			Note/K count_time_preset, "units=s"
//		SetDataFolder  root:SANS_file:entry1:program_name		
//			Make/O/N=0 Igor___folder_attributes	
			//	data		
			//	description		
			//	file_name		
			//	type		
		SetDataFolder  root:SANS_file:entry1:sample		
			Make/O/N=0 Igor___folder_attributes	
			Note/K Igor___folder_attributes, "NX_class=NXsample"
			//	description		
			//	group_id		
			//	chemical_formula		
			SetDataFolder  root:SANS_file:entry1:sample:temperature_1		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:temperature_1:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=C"
			SetDataFolder  root:SANS_file:entry1:sample:temperature_2		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:temperature_2:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=C"
			SetDataFolder  root:SANS_file:entry1:sample:electric_field		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:electric_field:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=V"
			SetDataFolder  root:SANS_file:entry1:sample:shear_field		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:shear_field:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=Pa s"
			SetDataFolder  root:SANS_file:entry1:sample:pressure		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:pressure:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=psi"
			SetDataFolder  root:SANS_file:entry1:sample:magnetic_field		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsensor"
				//	name		
				//	attached_to		
				//	measurement		
				SetDataFolder  root:SANS_file:entry1:sample:magnetic_field:value_log		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXlog"
					//	start		
					//	nx_time		
					Note/K nx_time, "units=s"
					//	value		
					Note/K value, "units=T"
			SetDataFolder  root:SANS_file:entry1:sample			
			//	changer_position		
			//	sample_holder_description		
			//	mass		
//			Note/K mass, "units=g"
			//	density		
//			Note/K density, "units=g ml-1"
			//	molecular_weight		
//			Note/K molecular_weight, "units=g mol-1"
			//	description		
			//	preparation_date		
			//	volume_fraction		
			//	scattering_length_density		
//			Note/K scattering_length_density, "units=A-2"
			//	thickness		
			Note/K thickness, "units=cm"
			//	rotation_angle		
			Note/K rotation_angle, "units=degrees"
			//	transmission		
			//	transmission_error		
			//	xs_incoh		
//			Note/K xs_incoh, "units=cm-1"
			//	xs_coh		
//			Note/K xs_coh, "units=cm-1"
			//	xs_absorb		
//			Note/K xs_absorb, "units=cm-1"
		SetDataFolder  root:SANS_file:entry1:instrument		
			Make/O/N=0 Igor___folder_attributes	
			Note/K Igor___folder_attributes, "NX_class=NXinstrument"
			//	location		
			//	name		
			//	type		
			//	local_contact		
			SetDataFolder  root:SANS_file:entry1:instrument:source		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXsource"
				//	name		
				//	type		
				//	probe		
				//	power		
				Note/K power, "units=MW"
			SetDataFolder root:SANS_file:entry1:instrument:beam_monitor		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXmonitor"
				//	data		
				//	type		
				//	efficiency		
				//	nx_distance		
				Note/K nx_distance, "units=m"
				//	saved_count		
			SetDataFolder  root:SANS_file:entry1:instrument:monochromator		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXmonochromator"
				//	wavelength		
				Note/K wavelength, "units=A"
				//	wavelength_spread		
				//	type		
				SetDataFolder  root:SANS_file:entry1:instrument:monochromator:velocity_selector		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXvelocity_selector"
					//	rotation_speed		
					Note/K rotation_speed, "units=RPM"
					//	wavelength		
					Note/K wavelength, "units=A"
					//	wavelength_spread		
					//	vs_tilt		
					Note/K vs_tilt, "units=degrees"
					//	nx_distance		
					Note/K nx_distance, "units=m"
						//table		
			SetDataFolder  root:SANS_file:entry1:instrument:polarizer		
				Make/O/N=0 Igor___folder_attributes	
				//	type		
				//	composition		
				//	efficiency		
				//	status		
			SetDataFolder  root:SANS_file:entry1:instrument:flipper		
				Make/O/N=0 Igor___folder_attributes	
				//	status		
				//	driving_current		
				Note/K driving_current, "units=A"
				//	waveform		
				//	frequency		
				Note/K frequency, "units=Hz"
				//	transmitted_power		
			SetDataFolder  root:SANS_file:entry1:instrument:polarizer_analyzer		
				Make/O/N=0 Igor___folder_attributes	
				//	status		
				//	guide_field_current_1		
				Note/K guide_field_current_1, "units=A"
				//	guide_field_current_2		
				Note/K guide_field_current_2, "units=A"
				//	solenoid_current		
				Note/K solenoid_current, "units=A"
				//	cell_index		
				//	cell_names		
				//	cell_parameters		
			SetDataFolder  root:SANS_file:entry1:instrument:chopper		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXdisk_chopper"
				//	type		
				//	status		
				//	rotation_speed		
				Note/K rotation_speed, "units=RPM"
				//	distance_from_source		
				Note/K distance_from_source, "units=m"
				//	distance_from_sample		
				Note/K distance_from_sample, "units=m"
				//	slits		
				//	angular_opening		
				Note/K angular_opening, "units=degrees"
				//	duty_cycle		
			SetDataFolder  root:SANS_file:entry1:instrument:attenuator		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXattenuator"
				//	nx_distance		
				Note/K nx_distance, "units=m"
				//	type		
				//	thickness		
				Note/K thickness, "units=cm"
				//	attenuator_transmission		
				//	status		
				//	atten_number		
				//	index		
			SetDataFolder  root:SANS_file:entry1:instrument:source_aperture		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXaperture"
				//	material		
				//	description		
				//	diameter		
				Note/K diameter, "units=cm"
				//	nx_distance		
				Note/K nx_distance, "units=m"
				SetDataFolder  root:SANS_file:entry1:instrument:source_aperture:shape		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXshape"
					//	size		
					Note/K size, "units=cm"
			SetDataFolder  root:SANS_file:entry1:instrument:sample_aperture		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXaperture"
				//	material		
				//	description		
				//	diameter		
				Note/K diameter, "units=cm"
				//	nx_distance		
				Note/K nx_distance, "units=m"
				SetDataFolder  root:SANS_file:entry1:instrument:sample_aperture:shape		
					Make/O/N=0 Igor___folder_attributes	
					Note/K Igor___folder_attributes, "NX_class=NXshape"
					//	size		
					Note/K size, "units=cm"
			SetDataFolder root:SANS_file:entry1:instrument:collimator			
				SetDataFolder root:SANS_file:entry1:instrument:collimator:geometry			
					SetDataFolder root:SANS_file:entry1:instrument:collimator:geometry:shape			
						//	shape		
						//	size		
						Note/K size, "units=m"
				//	nx_NumGuides		
			SetDataFolder  root:SANS_file:entry1:instrument:lenses		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXxraylens"
				//	status		
				//	lens_geometry		
				//	focus_type		
				//	number_of_lenses		
				//	number_of_prisms		
				//	curvature		
				//	lens_distance		
				Note/K lens_distance, "units=m"
				//	prism_distance		
				Note/K prism_distance, "units=m"
				//	lens_material		
				//	prism_material		
			SetDataFolder  root:SANS_file:entry1:instrument:sample_table		
				Make/O/N=0 Igor___folder_attributes	
				//	location		
				//	offset_distance		
				Note/K offset_distance, "units=cm"
			SetDataFolder  root:SANS_file:entry1:instrument:beam_stop		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXbeam_stop"
				//	description		
				//	nx_distance		
				Note/K nx_distance, "units=m"
				//	size		
				Note/K size, "units=cm"
				//	status		
				//	xPos		
				//	yPos		
				//	x_motor_position		
				Note/K x_motor_position, "units=cm"
				//	y_motor_position		
				Note/K y_motor_position, "units=cm"
			SetDataFolder  root:SANS_file:entry1:instrument:detector		
				Make/O/N=0 Igor___folder_attributes	
				Note/K Igor___folder_attributes, "NX_class=NXdetector"
				//	data		
				Note/K data, "signal=1"
				//	data_error		
				//	nx_distance		
				Note/K nx_distance, "units=m"
				//	description		
				//	settings		
				//	dead_time		
				Note/K dead_time, "units=s"
				//	x_pixel_size		
				Note/K x_pixel_size, "units=cm"
				//	y_pixel_size		
				Note/K y_pixel_size, "units=cm"
				//	beam_center_x		
				//	beam_center_y		
				//	type		
				//	flatfield_applied		
				//	countrate_correction_applied		
				//	pixel_mask		
				//	integrated_count		
				//	lateral_offset		
				Note/K lateral_offset, "units=cm"
				//	PixelNumX		
				//	PixelNumY		
				//	PixelFWHM		
					//calibration_method		
				//	CALX		
				//	CALY		
				//	size		
				Note/K size, "units=cm"
				//	event_file_name		
		SetDataFolder  root:SANS_file:entry1:data		
			Make/O/N=0 Igor___folder_attributes	
			Note/K Igor___folder_attributes, "NX_class=NXdata"
			//	data		
			Note/K data, "signal=1"
			//	error		
			//	variables		
			//	data_image		
		SetDataFolder  root:SANS_file:entry1:reduction		
			Make/O/N=0 Igor___folder_attributes	
			//	intent		
			//	transmission_file_name		
			//	empty_beam_file_name		
			//	background_file_name		
			//	empty_file_name		
			//	sensitivity_file_name		
			//	mask_file_name		
			//	sans_log_file_name		
			//	whole_trans		
			//	whole_trans_error		
			//	box_count		
			//	box_count_error		
			//	box_coordinates		
			//	comments		
			//	absolute_scaling		
			SetDataFolder  root:SANS_file:entry1:reduction:pol_sans		
				Make/O/N=0 Igor___folder_attributes	
				//	pol_sans_purpose		
				//	cell_name		
				//	cell_parameters		
							
	SetDataFolder  root:SANS_file:DAS_Logs		
		Make/O/N=0 Igor___folder_attributes	
		Note/K Igor___folder_attributes, "NX_class=NXlog"
			//...multiple entries and levels... to add		


	SetDataFolder root:	

End

//
// this is NOT linked in any way with SASCALC, and I have no idea
// of how to ever keep this in sync if the Nexus tree changes...
//
Proc H_Fill_SANS_wSim()

SetDataFolder  root:SANS_file		
		file_name	= "SANSTest.h5"
		file_time	= "2015-02-28T08:15:30-5:00"
		facility	= "NCNR"
		NeXus_version	= "Nexus 0.0"
		hdf_version	= "hdf5.x"
		file_history	= "history log"
	SetDataFolder  root:SANS_file:entry1		
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
			data_directory	= "[NG7SANS41]"
			program_name	= "runPoint={stuff}"
		SetDataFolder  root:SANS_file:entry1:user		
				name	= "Dr. Pi"
				role	= "evil scientist"
				affiliation	= "NIST"
				address	= "100 Bureau Drive"
				telephoneNumber	= "301-999-9999"
				faxNumber	= "301-999-9999"
				email	= "sans@nist"
				facility_user_id	= 6937596
		SetDataFolder  root:SANS_file:entry1:control		
				mode	= "timer"
				preset	= 555
				integral	= 555
				monitor_counts	= 666
				monitor_preset	= 1e8
				detector_counts	= 100111222
				detector_preset	= 1e5
//				type	= "monitor type"
//				efficiency	= 0.01
//				sampled_fraction	= 1
				count_start	= 1
				count_end	= 1
				count_time	= 1
				count_time_preset	= 1
//		SetDataFolder  root:SANS_file:entry1:program_name		
//				data	= "program data"
//				description	= "acquisition"
//				file_name	= "NICE"
//				type	= "client"
		SetDataFolder  root:SANS_file:entry1:sample		
				description	= "My Sample"
				group_id	= 12345
//				chemical_formula	= "C8H10N4O2"
			SetDataFolder  root:SANS_file:entry1:sample:temperature_1		
					name	= "Sample temperature"
					attached_to	= "block"
					measurement	= "temperature"
				SetDataFolder  root:SANS_file:entry1:sample:temperature_1:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 2*p
			SetDataFolder  root:SANS_file:entry1:sample:temperature_2		
					name	= "Sample temperature"
					attached_to	= "block"
					measurement	= "temperature"
				SetDataFolder  root:SANS_file:entry1:sample:temperature_2:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 3*p
			SetDataFolder  root:SANS_file:entry1:sample:electric_field		
					name	= "electric meter"
					attached_to	= "sample"
					measurement	= "voltage"
				SetDataFolder  root:SANS_file:entry1:sample:electric_field:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= 2*p
						value	= sin(p/10)
			SetDataFolder  root:SANS_file:entry1:sample:shear_field		
					name	= "rheometer"
					attached_to	= "sample"
					measurement	= "stress"
				SetDataFolder  root:SANS_file:entry1:sample:shear_field:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= cos(p/5)
			SetDataFolder  root:SANS_file:entry1:sample:pressure		
					name	= "Sample pressure"
					attached_to	= "pressure cell"
					measurement	= "pressure"
				SetDataFolder  root:SANS_file:entry1:sample:pressure:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= p/2
			SetDataFolder  root:SANS_file:entry1:sample:magnetic_field		
					name	= "magnetic field (direction)"
					attached_to	= "cryostat"
					measurement	= "magnetic field"
				SetDataFolder  root:SANS_file:entry1:sample:magnetic_field:value_log		
						start	= "2015-02-28T08:15:30-5:00"
						nx_time	= p
						value	= 10*p
			SetDataFolder  root:SANS_file:entry1:sample		
				changer_position	= 5
				sample_holder_description	= "10CB"
//				mass	= 0.3
//				density	= 1.02
//				molecular_weight	= 194.19
//				description	= "My Sample"
//				preparation_date	= "2015-02-28T08:15:30-5:00"
//				volume_fraction	= 0.2
//				scattering_length_density	= 6.35e-6
				thickness	= 0.1
				rotation_angle	= 30
				transmission	= 0.888
				transmission_error	= 0.011
//				xs_incoh	= 5.5
//				xs_coh	= 22.2
//				xs_absorb	= 3.1
		SetDataFolder  root:SANS_file:entry1:instrument		
//				location	= "NCNR"
				name	= "NGB30mSANS"
				type	= "30 m SANS"
				local_contact	= "Steve Kline"
			SetDataFolder  root:SANS_file:entry1:instrument:source		
					name	= "NCNR"
					type	= "Reactor Neutron Source"
					probe	= "neutron"
					power	= 20
			SetDataFolder root:SANS_file:entry1:instrument:beam_monitor		
					data	= 1234567
					type	= "monitor"
					efficiency	= 0.01
					nx_distance	= 16
					saved_count	= 1e8
			SetDataFolder  root:SANS_file:entry1:instrument:monochromator		
					wavelength	= 6
					wavelength_spread	= 0.15
					type	= "VS"
				SetDataFolder  root:SANS_file:entry1:instrument:monochromator:velocity_selector		
						rotation_speed	= 5100
						wavelength	= 6
						wavelength_spread	= 0.15
						vs_tilt	= 3
						nx_distance	= 18.8
						//table	
			SetDataFolder  root:SANS_file:entry1:instrument:polarizer		
					type	= "supermirror"
					composition	= "multilayer"
					efficiency	= 0.95
					status	= "in"
			SetDataFolder  root:SANS_file:entry1:instrument:flipper		
					status	= "on"
					driving_current	= 42
					waveform	= "sine"
					frequency	= 400
					transmitted_power	= 0.99
			SetDataFolder  root:SANS_file:entry1:instrument:polarizer_analyzer		
					status	= "down"
					guide_field_current_1	= 33
					guide_field_current_2	= 32
					solenoid_current	= 21
					cell_index	= 1
					cell_names	= {"Burgundy","Olaf","Jim","Bob","Joe"}
					cell_parameters	= 1
			SetDataFolder  root:SANS_file:entry1:instrument:chopper		
					type	= "single"
					status	= "in"
					rotation_speed	= 12000
					distance_from_source	= 400
					distance_from_sample	= 1500
					slits	= 2
					angular_opening	= 15
					duty_cycle	= 0.25
			SetDataFolder  root:SANS_file:entry1:instrument:attenuator		
					nx_distance	= 1500
					type	= "PMMA"
					thickness	= 0
					attenuator_transmission	= 1
					status	= "in"
					atten_number	= 0
					index	= 1
			SetDataFolder  root:SANS_file:entry1:instrument:source_aperture		
//					material	= "Gd"
					description	= "source aperture"
					diameter	= 1.27
					nx_distance	= 13.0
				SetDataFolder  root:SANS_file:entry1:instrument:source_aperture:shape		
						size	= 1.27
			SetDataFolder  root:SANS_file:entry1:instrument:sample_aperture		
//					material	= "Gd"
					description	= "sample aperture"
					diameter	= 1.27
					nx_distance	= 10
				SetDataFolder  root:SANS_file:entry1:instrument:sample_aperture:shape		
						size	= 1.27
			SetDataFolder root:SANS_file:entry1:instrument:collimator		
				SetDataFolder root:SANS_file:entry1:instrument:collimator:geometry		
					SetDataFolder root:SANS_file:entry1:instrument:collimator:geometry:shape		
							shape	= "box"
							size	= 11
					nx_NumGuides	= 1
			SetDataFolder  root:SANS_file:entry1:instrument:lenses		
					status	= "in"
					lens_geometry	= "concave_lens"
					focus_type	= "point"
					number_of_lenses	= 28
					number_of_prisms	= 7
					curvature	= 1
					lens_distance	= 123
					prism_distance	= 123
					lens_material	= "MgF2"
					prism_material	= "MgF2"
			SetDataFolder  root:SANS_file:entry1:instrument:sample_table		
					location	= "chamber"
					offset_distance	= 0
			SetDataFolder  root:SANS_file:entry1:instrument:beam_stop		
					description	= "circular"
					nx_distance	= 12.5
					size	= 7.62
					status	= "out"
					xPos	= 66.4
					yPos	= 64.4
					x_motor_position	= 0.15
					y_motor_position	= 0.55
			SetDataFolder  root:SANS_file:entry1:instrument:detector		
					data	= trunc(abs(gnoise(p+q)))
//					data_error	= 0.01*abs(gnoise(p+q))
					nx_distance	= 13.1
					description	= "Ordela 2660N"
					settings	= "just right"
					dead_time	= 5e-6
					x_pixel_size	= 5.08
					y_pixel_size	= 5.08
					beam_center_x	= 65.55
					beam_center_y	= 62.33
					type	= "Ordela"
//					flatfield_applied	= 0
//					countrate_correction_applied	= 0
					pixel_mask	= 0
					integrated_count	= 100111222
					lateral_offset	= 20
					PixelNumX	= 128
					PixelNumY	= 128
					PixelFWHM	= 0.5
					//calibration_method	
					CALX	= {0.5,0.5,10000}
					CALY	= {0.5,0.5,10000}
					size	= 65
					event_file_name	="something.hst"
		SetDataFolder  root:SANS_file:entry1:data		
				data	= trunc(abs(gnoise(p+q)))
//				error	= 0.01*abs(gnoise(p+q))
				variables	= {128,128}
				data_image	= p
		SetDataFolder  root:SANS_file:entry1:reduction		
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
				comments	= "extra data comments"
				absolute_scaling	= {1,1,1e5,1}
			SetDataFolder  root:SANS_file:entry1:reduction:pol_sans		
					pol_sans_purpose	= "name from the list"
					cell_name	= "Burgundy"
					cell_parameters	= {1,2,3,4,5}
						
	SetDataFolder  root:SANS_file:DAS_Logs		
			//...multiple entries and levels... to add	


	SetDataFolder root:

End



