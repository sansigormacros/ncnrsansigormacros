#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 7.00


//
//
//
//
// AUG 2015 **************
////////////
// this needs to be connected to the "new" Nexus file
// remove the VSANS references, match to SASCALC, write proper documentation, etc.
///////////




//
// this is a test of the "new" SANS file structure that is supposed to be
// NeXus compliant. It doesn't have the NICE logs, but has everything that I 
// can think of here.
//

///
// for the simulator, routines to be able to write out a proper Nexus file
// based on a template
////



// overwrites the dummy values as needed with SASCALC information
//
// TODO
// issues here with the potential for Nexus to have data as INTEGER
// where I'd rather have the data here in Igor be DP, so there are no 
// conversion/assignment issues
//
// simuation data from VCALC = DP, but I need to assign to an Integer wave...
// - sometimes this works, sometimes not...
// may need to Redimension/I
//
/// break this up into several smaller procedures as this is a VERY lengthy task to do

	// TODO
// set the "accessible" copies of the data (these are really to be links in the file!)



//
// A "template" VSANS Nexus file has been loaded and is then filled in with
// the simulation results. Some of teh file, will therefor be garbage, but the 
// overall structure and attributes should be correct.
//
// Hopefully this will make the maintenance and testing of the file structure easier...
// AUG 2015
//
///////////////////////////
//
// these are all of the VCALC changes to the simulated files. ADD to these as needed, making these changes to the 
// folder structure after the "default" values have been re-filled in the waves (to make sure something is really there)
//
////////////////////////

// TODO:
//	-- Need to write all of the "accessors" to r/w all of the simulated bits to the data file... lots to do
// -- THIS DOES NOT MATCH THE CURRENT NICE_GENERATED FILE !!!!
//



//
// this is NOT linked in any way with SASCALC, and I have no idea
// of how to ever keep this in sync if the Nexus tree changes...
//
Proc H_Fill_SANS_Template_wSim()

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



