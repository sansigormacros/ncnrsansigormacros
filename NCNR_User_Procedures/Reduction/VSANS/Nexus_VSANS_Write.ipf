#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///
// for the simulator, routines to be able to write out a proper Nexus file
// based on a template
////



// overwrites the dummy values as needed with VCALC information
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


// TODO
// get Paul K to write out 2D data sets, rather than 3D (not appropriate for SANS or VSANS)
//

/////
/// to get "useable" data out of the 3D wave (incorrectly written)
//		Redimension/N=(1,320,320) 	root:V_Nexus_Template:entry:entry1:instrument:detector_B:data	
//		root:V_Nexus_Template:entry:entry1:instrument:detector_B:data[0][][] = root:Packages:NIST:VSANS:VCALC:Back:det_B[q][r]
//		root:V_Nexus_Template:entry:entry1:instrument:detector_B:distance = VCALC_getSDD("B")



//
// A "template" VSANS Nexus file has been loaded and is then filled in with
// the simulation results. Some of the file, will therefore be garbage, but the 
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
Proc H_Fill_VSANS_Template_wSim()


	root:V_Nexus_Template:entry:entry1:instrument:beam:monochromator:wavelength = VCALC_getWavelength()
				
//			SetDataFolder root:VSANS_file:entry1:instrument		
//				SetDataFolder root:VSANS_file:entry1:instrument:monochromator		
//					wavelength	= VCALC_getWavelength()
//					SetDataFolder root:VSANS_file:entry1:instrument:monochromator:velocity_selector		
//						wavelength	= VCALC_getWavelength()
//						//	table (wave)	
//					SetDataFolder root:VSANS_file:entry1:instrument:monochromator:crystal		
//						wavelength	= VCALC_getWavelength()
//						
//					SetDataFolder root:VSANS_file:entry1:instrument:monochromator:white_beam		
//						wavelength	= VCALC_getWavelength()
//						//	description_of_distribution
					

		Redimension/N=(1,320,320) 	root:V_Nexus_Template:entry:entry1:instrument:detector_B:data	
		root:V_Nexus_Template:entry:entry1:instrument:detector_B:data[0][][] = root:Packages:NIST:VSANS:VCALC:Back:det_B[q][r]
		root:V_Nexus_Template:entry:entry1:instrument:detector_B:distance = VCALC_getSDD("B")

//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_MR			
//				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MR
//				nx_distance	= VCALC_getSDD("MR")
//				separation	= VCALC_getPanelSeparation("MR")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//				
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_ML		
//				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_ML
//				nx_distance	= VCALC_getSDD("ML")
//				separation = VCALC_getPanelSeparation("ML")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_MT		
//				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MT
//				nx_distance	= VCALC_getSDD("MT")
//				sdd_offset = VCALC_getTopBottomSDDOffset("MT")
//				separation = VCALC_getPanelSeparation("MT")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_MB		
//				data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MB
//				nx_distance	= VCALC_getSDD("MB")
//				sdd_offset = VCALC_getTopBottomSDDOffset("MB")
//				separation = VCALC_getPanelSeparation("MB") 
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_FR			
//				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FR
//				nx_distance	= VCALC_getSDD("FR")
//				separation = VCALC_getPanelSeparation("FR") 
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_FL		
//				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FL
//				nx_distance	= VCALC_getSDD("FL")
//				separation = VCALC_getPanelSeparation("FL")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_FT		
//				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FT
//				nx_distance	= VCALC_getSDD("FT")
//				sdd_offset = VCALC_getTopBottomSDDOffset("FT")
//				separation = VCALC_getPanelSeparation("FT")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//			SetDataFolder root:VSANS_file:entry1:instrument:detector_FB		
//				data	= root:Packages:NIST:VSANS:VCALC:Front:det_FB
//				nx_distance	= VCALC_getSDD("FB")
//				sdd_offset = VCALC_getTopBottomSDDOffset("FB")
//				separation = VCALC_getPanelSeparation("FB")
//				spatial_calibration[0][] = 1.072
//				spatial_calibration[1][] = -4.0e-5
//
//					
//// SRK -set the top level copies of the data					
//		SetDataFolder root:VSANS_file:entry1:data_B	
//			data	= root:Packages:NIST:VSANS:VCALC:Back:det_B
//
//		SetDataFolder root:VSANS_file:entry1:data_MR	
//			data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MR
//			
//		SetDataFolder root:VSANS_file:entry1:data_ML	
//			data	= root:Packages:NIST:VSANS:VCALC:Middle:det_ML
//			
//		SetDataFolder root:VSANS_file:entry1:data_MT	
//			data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MT
//			data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
//			
//		SetDataFolder root:VSANS_file:entry1:data_MB	
//			data	= root:Packages:NIST:VSANS:VCALC:Middle:det_MB
//			data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
//			
//		SetDataFolder root:VSANS_file:entry1:data_FR	
//			data	= root:Packages:NIST:VSANS:VCALC:Front:det_FR
//			
//		SetDataFolder root:VSANS_file:entry1:data_FL	
//			data	= root:Packages:NIST:VSANS:VCALC:Front:det_FL
//			
//		SetDataFolder root:VSANS_file:entry1:data_FT	
//			data	= root:Packages:NIST:VSANS:VCALC:Front:det_FT
//			data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
//			
//		SetDataFolder root:VSANS_file:entry1:data_FB	
//			data	= root:Packages:NIST:VSANS:VCALC:Front:det_FB
//			data	= (data ==   2147483647) ? 0 : data		//the NaN "mask" in the sim data shows up as an ugly integer
//			
//				
////		SetDataFolder root:VSANS_file:entry1:reduction		
////			intent	= "SCATTER"
////			transmission_file_name	= "SANSFile_TRN.h5"
////			empty_beam_file_name	= "SANSFile_EB.h5"
////			background_file_name	= "SANSFile_BKG.h5"
////			empty_file_name	= "SANSFile_EMP.h5"
////			sensitivity_file_name	= "SANSFile_DIV.h5"
////			mask_file_name	= "SANSFile_MASK.h5"
////			sans_log_file_name	= "SANSFile_log.txt"
////			whole_trans	= 0.888
////			whole_trans_error	= 0.008
////			box_count	= 23232
////			box_count_error	= 22
////			box_coordinates	= {50,80,45,75}
////			comments	= "extra data comments"
////			absolute_scaling	= {1,1,1e5,1}
////			SetDataFolder root:VSANS_file:entry1:reduction:pol_sans			
////				pol_sans_purpose	= "name from the list"
////				cell_name	= "Burgundy"
////				cell_parameters	= {1,2,3,4,5}
//					

	SetDataFolder root:

End


