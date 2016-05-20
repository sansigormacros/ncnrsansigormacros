#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// TODO:
// x- CHANGE the mask behavior to a more logical choice - and consistent with SANS
//   x- CHANGE to:
// 1 == mask == discard data
// 0 == no Mask == keep data
// x- and then make the corresponding changes in the I(Q) routines


// also, move the mask generating utilities from VC_HDF5_Utils into this procedure - to keep
// all of the mask procedures together


//
// -- this is to be a very simple editor to generate masks row/column wise, not drawing
//


//TODO
// -- draw a mask
// -- save a mask (all panels)
// -- be able to save the mask name to the file
// -- be able to read a mask based on what is in the data file
//
// x- biggest thing now is to re-write the DrawDetPanel() routine from the beamCenter.ipf
//    to do what this panel needs
//
// -- lots to clean up
// -- add this to the list of includes, move the file to SVN, and add it.
//
// -- for working with VCALC -- maybe have an automatic generator (if val < -2e6, mask = 0)
//    this can be checked column-wise to go faster (1st index)
//
// x- re-write V_OverlayMask to make the "overlay" wave that has the NaNs, and then the drawing
//    routines need to be aware of this

Macro Edit_a_Mask()
	V_EditMask()
end

Function V_EditMask()
	DoWindow/F MaskEditPanel
	if(V_flag==0)
		Execute "MaskEditorPanel()"
	endif
End

//
// TODO - may need to adjust the display for the different pixel dimensions
//	ModifyGraph width={Plan,1,bottom,left}
//
Proc MaskEditorPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	NewPanel /W=(662,418,1586,960)/N=MaskEditPanel/K=1
//	ShowTools/A
	
	PopupMenu popup_0,pos={20,50},size={109,20},proc=SetMaskPanelPopMenuProc,title="Detector Panel"
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;MR;ML;MT;MB;B;\""
	PopupMenu popup_2,pos={20,20},size={109,20},title="Data Source"//,proc=SetFldrPopMenuProc
	PopupMenu popup_2,mode=1,popvalue="VCALC",value= #"\"RAW;SAM;VCALC;\""
		
//	Button button_0,pos={486,20},size={80,20},proc=DetFitGuessButtonProc,title="Guess"
//	Button button_1,pos={615,20},size={80,20},proc=DetFitButtonProc,title="Do Fit"
//	Button button_2,pos={744,20},size={80,20},proc=DetFitHelpButtonProc,title="Help"
//	Button button_3,pos={615,400},size={110,20},proc=WriteCtrButtonProc,title="Write Centers"
//	Button button_4,pos={730,400},size={110,20},proc=CtrTableButtonProc,title="Ctr table"
//	Button button_5,pos={730,440},size={110,20},proc=WriteCtrTableButtonProc,title="Write table"

// TODO -- need buttons for save? quit?
// setVariable to add a row to the mask, column to the mask, toggle the mask on/off to see what's
//     happening with the data


// TODO - get rid of the hard-wired panel choice
	duplicate/O root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_FL:det_FL curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel

	// draw the correct images
	//draw the detector panel
	DrawPanelToMask("FL")
	
	// overlay the current mask
	V_OverlayMask("FL",1)
//	OverlayMaskPanel("FL")

EndMacro

//
// function to choose which detector panel to display, and then to actually display it
//
Function SetMaskPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
						
			// remove the old image (it may not be the right shape)
			// -- but make sure it exists first...
			String childList = ChildWindowList("MaskEditPanel")
			Variable flag
			
			flag = WhichListItem("DetData", ChildList)		//returns -1 if not in list, 0+ otherwise
			if(flag != -1)
				KillWindow MaskEditPanel#DetData
			endif
			
			flag = WhichListItem("ModelData", ChildList)
			if(flag != -1)
				KillWindow MaskEditPanel#ModelData
			endif
	
			// draw the correct images
			DrawPanelToMask(popStr)

			//overlay the mask
			V_OverlayMask(popStr,1)
//			OverlayMaskPanel(popStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// SEE DrawDetPanel() in the BeamCenter file
//
// TODO - currently is hard-wired for the simulation path!
//     need to make it more generic, especially for RAW data
//
// -- need to adjust the size of the image subwindows to keep the model
//    calculation from spillon over onto the table (maybe just move the table)
// -- need to do something for panel "B". currently ignored
// -- currently the pixel sizes for "real" data is incorrect in the file
//     and this is why the plots are incorrectly sized
//
// draw the selected panel and the model calculation, adjusting for the 
// orientation of the panel and the number of pixels, and pixel sizes
Function DrawPanelToMask(str)
	String str
	
	// from the selection, find the path to the data

	Variable xDim,yDim
	Variable left,top,right,bottom
	Variable height, width
	Variable left2,top2,right2,bottom2
	Variable nPix_X,nPix_Y,pixSize_X,pixSize_Y

	
	Wave dispW=root:curDispPanel

	//plot it in the subwindow with the proper aspect and positioning
	// for 48x256 (8mm x 4mm), aspect = (256/2)/48 = 2.67 (LR panels)
	// for 128x48 (4mm x 8 mm), aspect = 48/(128/2) = 0.75 (TB panels)
	
	
	// using two switches -- one to set the panel-specific dimensions
	// and the other to set the "common" values, some of which are based on the panel dimensions

// set the source of the data. not always VCALC anymore
	String folder
	ControlInfo popup_2
	folder = S_Value

	// TODO -- fix all of this mess
	if(cmpstr(folder,"VCALC") == 0)
		// panel-specific values
		Variable VC_nPix_X = VCALC_get_nPix_X(str)
		Variable VC_nPix_Y = VCALC_get_nPix_Y(str)
		Variable VC_pixSize_X = VCALC_getPixSizeX(str)
		Variable VC_pixSize_Y = VCALC_getPixSizeY(str)

	
	// if VCALC declare this way	
		wave newW = $("root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_"+str+":det_"+str)
		nPix_X = VC_nPix_X
		nPix_Y = VC_nPix_Y
		pixSize_X = VC_pixSize_X
		pixSize_Y = VC_pixSize_Y
	
	else
	// TODO: if real data, need new declaration w/ data as the wave name
		wave newW = $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+str+":data")

		nPix_X = V_getDet_pixel_num_x(folder,str)
		nPix_Y = V_getDet_pixel_num_Y(folder,str)
		pixSize_X = V_getDet_x_pixel_size(folder,str)/10
		pixSize_Y = V_getDet_y_pixel_size(folder,str)/10
	endif
	

	Variable scale = 5
	
	// common values (panel position, etc)
	// TODO -- units are absolute, based on pixels in cm. make sure this is always correct
	strswitch(str)
		case "FL":
		case "FR":
		case "ML":
		case "MR":
			width = trunc(nPix_X*pixSize_X *scale*1.15)			//48 tubes @ 8 mm
			height = trunc(nPix_Y*pixSize_Y *scale*0.8)			//128 pixels @ 8 mm
			
			left = 20
			top = 80
			right = left+width
			bottom = top+height
			
			left2 = right + 20
			right2 = left2 + width
			top2 = top
			bottom2 = bottom
			
			break			
		case "FT":
		case "FB":
		case "MT":
		case "MB":
			width = trunc(nPix_X*pixSize_X *scale*1.)			//128 pix @ 4 mm
			height = trunc(nPix_Y*pixSize_Y *scale)			// 48 tubes @ 8 mm
						
			left = 20
			top = 80
			right = left+width
			bottom = top+height
			
			left2 = left
			right2 = right
			top2 = top + height + 20
			bottom2 = bottom + height + 20
			
			break
		case "B":
			return(0)		//just exit
			break						
		default:
			return(0)		//just exit
	endswitch

	// generate the new panel display
	duplicate/O newW curDispPanel
	SetScale/P x 0,1, curDispPanel
	SetScale/P y 0,1, curDispPanel
	
	//draw the detector panel
	Display/W=(left,top,right,bottom)/HOST=# 
	AppendImage curDispPanel
	ModifyImage curDispPanel ctab= {*,*,ColdWarm,0}
	Label left "Y pixels"
	Label bottom "X pixels"	
	RenameWindow #,DetData
	SetActiveSubwindow ##	
	
	DoUpdate
	
	return(0)
End

//
// overlay the mask
//
// TODO
// -- make it work
// -- remove the old mask first
// -- make the mask "toggle" to remove it
// -- go see SANS for color, implementation, etc.
// -- un-comment the (two) calls
//
//
//toggles a mask on/off of the SANS_Data window
// points directly to window, doesn't need current display type
//
// if state==1, show the mask, if ==0, hide the mask
Function V_OverlayMask(str,state)
	String str
	Variable state


	String maskPath = "root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data"
	if(WaveExists($maskPath) == 1)
		//duplicate the mask, which is named "data"
		wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":data")

		Duplicate/O maskW $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")
		wave overlay = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+str+":overlay")

		Redimension/D overlay
		SetScale/P x 0,1, overlay
		SetScale/P y 0,1, overlay
	
		String tempStr = "root:Packages:NIST:MSK:overlay"
		overlay = (maskW == 1) ? 1 : NaN
//		ResetLoop(tempStr)		//keeps 1's and sets 0's to NaN

		AppendImage/W=MaskEditPanel#DetData overlay
		ModifyImage/W=MaskEditPanel#DetData overlay ctab= {0,*,BlueRedGreen,0}	

//	
//		//check to see if mask overlay is currently displayed
//		DoWindow SANS_Data
//		if(V_flag==0)
//			return(0)
//		endif
//		
//		CheckDisplayed/W=SANS_Data root:Packages:NIST:MSK:overlay
//		//Print "V_flag = ",V_flag
//	
//		If(V_Flag == 1)		//overlay is present
//			if(state==0)
//				RemoveImage overlay
//			endif		//don't need to do anything if we want to keep the mask
//		Else		//overlay is not present
//			if(state==1)
//				//append the new overlay
//				AppendImage/L=left/B=bottom root:Packages:NIST:MSK:overlay
//				//set the color table to vary from 0 to * (=max data = 1), with blue maximum
//				//Nan's will appear transparent (just a general feature of images)
//				ModifyImage/W=SANS_Data overlay ctab={0,*,BlueRedGreen,0}
//			endif		//don't do anything if we don't want the overlay
//		Endif
//		
	Endif
	
	return(0)
End


////////////// fake MASK file tests
//
//
//	Make/O/T/N=1	file_name	= "VSANS_MASK_test.h5"
//
// simple generation of a fake MASK file. for sans, nothing other than the creation date was written to the 
// file header. nothing more is needed (possibly)
//
//
// TODO -- make the number of pixels GLOBAL
// TODO -- there will be lots of work to do to develop the procedures necessary to actually generate the 
//      9 data sets to become the MASK file contents. More complexity here than for the simple SANS case.
//
// TODO -- this is currently random 0|1 values, need to write an editor
//
// currently set up to use 1 = YES MASK == exclude the data
//      and 0 = NO MASK == keep the data
//
Proc H_Setup_VSANS_MASK_Structure()
	
	NewDataFolder/O/S root:VSANS_MASK_file		

	NewDataFolder/O/S root:VSANS_MASK_file:entry	
		Make/O/T/N=1	title	= "This is a fake MASK file for VSANS"
		Make/O/T/N=1	start_date	= "2015-02-28T08:15:30-5:00"
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument		
			Make/O/T/N=1	name	= "NG3_VSANS"
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_B	
			Make/O/I/N=(150,150)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MR		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_ML		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_MB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FR		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FL		
			Make/O/I/N=(48,128)	data	= 0
		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FT		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0

		NewDataFolder/O/S root:VSANS_MASK_file:entry:instrument:detector_FB		
			Make/O/I/N=(128,48)	data	= 0
			data[0,49][] = 1
			data[78,127][] = 1
			data[50,77][] = 0
			
	SetDataFolder root:

End

////////////////////// MASK FILE


// TODO
// currently, there are no dummy fill values or attributes for the fake MASK file
//
Proc Setup_VSANS_MASK_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_VSANS_MASK_Structure()
	
	// writes in the attributes
//	H_Fill_VSANS_Attributes()
	
	// fill in with VCALC simulation bits
//	H_Fill_VSANS_wSim()
	
End

Proc Save_VSANS_MASK_Nexus(fileName)
	String fileName="Test_VSANS_MASK_file"

	// save as HDF5 (no attributes saved yet)
	Save_VSANS_file("root:VSANS_MASK_file", fileName+".h5")
	
	// read in a data file using the gateway-- reads from the home path
	H_HDF5Gate_Read_Raw(fileName+".h5")
	
	// after reading in a "partial" file using the gateway (to generate the xref)
	// Save the xref to disk (for later use)
	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
	
	// after you've generated the HDF5___xref, load it in and copy it
	// to the necessary folder location.
	Copy_HDF5___xref("root:VSANS_MASK_file", "HDF5___xref")
	
	// writes out the contents of a data folder using the gateway
	H_HDF5Gate_Write_Raw("root:VSANS_MASK_file", fileName+".h5")

	// re-load the data file using the gateway-- reads from the home path
	// now with attributes
	H_HDF5Gate_Read_Raw(fileName+".h5")
	
End
