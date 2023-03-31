#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion = 7.00

//
// this panel and proceudres is the equivalent of "RawWindowHook" for SANS
//
// This includes procedures to:
// display the detector data
// visualization tools
// mouse interaction
// status information necessary to understand the data
// buttons to more functionality to process data
//

// DONE
//
// x- have the status automatically fill in when a new file is loaded, rather than needing a click of the "status" button
// x- need a place somewhere to show the currently displayed folder
// x- checkboxes for "active" corrections?
// x- display of Q, counts, QxQy, X and Y
// x- do I need a color bar? or is this not used at all? I like it to be there, or the colors are a waste of information
//		(then... where do I put the color bar?)
// x- define the "hook" function, and attach it to the panel (or the main detector subwindow?)
//


//
// call this after loading data to either draw the data display panel or to update the contents
//
// DONE
// x- make sure that the "type" input is correctly used for the updating of the data, values, etc.
// x- add a procedure to define the global variables for pos, counts, QxQy, etc.
//
Function V_UpdateDisplayInformation(type)
	String type 
	
	DoWindow/F VSANS_Data
//	Print V_flag
	if(V_flag==0)
	
		VSANSDataPanelGlobals()
		
		Execute "VSANS_DataPanel()"		//draws the panel

	endif
	
	// DONE: 
	// faking clicks on the buttons updates the information
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType = type
	
	// fake a click on all three tabs - to populate the data
	V_FakeTabClick(2)
	V_FakeTabClick(1)
	V_FakeTabClick(0)

	V_LogLinDisplayPref()		// resets the display depending on the preference state
	
	// either clear the status, or fake a click
//	root:Packages:NIST:VSANS:Globals:gStatusText = "status info box"

	V_FakeStatusButtonClick()

// NOTE: This is where the beam center is picked up so that the panel array scaling is reset
// so that the images will automatically display in relation to the beam center
	V_FakeRestorePanelsButtonClick()		//so the panels display correctly

	
//	DoWindow/T VSANS_Data,type + " VSANS_Data"

	// get the string with the file name that is in the "type" folder
	// this string is what goes in the status of the display
	SVAR gFileForDisplay = root:Packages:NIST:VSANS:Globals:gLastLoadedFile		//for the status of the display
	SVAR gFileList = $("root:Packages:NIST:VSANS:"+type+":gFileList")
	
	gFileForDisplay=gFileList
	

	String newTitle = "WORK_"+type
	DoWindow/F VSANS_Data
	DoWindow/T VSANS_Data, newTitle
	KillStrings/Z newTitle
	
end

Function V_LogLinDisplayPref()

	// get the state of the log/lin button, and make sure preferences are obeyed
	// log/lin current state is in the S_UserData string (0=linear, 1=log)
	ControlInfo/W=VSANS_Data button_log
	Variable curState
	curState = str2num(S_UserData)

	NVAR gLogScalingAsDefault = root:Packages:NIST:VSANS:Globals:gLogScalingAsDefault
	if(curState != gLogScalingAsDefault)
		STRUCT WMButtonAction ba
		ba.eventCode = 2		//fake mouse click
		V_LogLinButtonProc(ba)
	endif
	
	return(0)
end


//
// creates/initializes the globals for display of the data panel
//
Function VSANSDataPanelGlobals()

	SetDataFolder root:Packages:NIST:VSANS:Globals
	
	Variable/G gXPos=0
	Variable/G gYPos=0
	Variable/G gQX=0
	Variable/G gQY=0
	Variable/G gQQ=0
	Variable/G gNCounts=0
	String/G gCurDispFile = "default string"
	String/G gCurTitle = ""
	String/G gCurDispType = ""
	String/G gStatusText = "status"
	String/G gLastLoadedFile=""
	
	SetDataFolder root:
End


// TODO_MEDIUM
//
// -- now that the sliders work, label them and move them to a better location
// -- logical location for all of the buttons
// -- add raw data load button, load/draw mask button
// x- fill in the proper window title in the DoWindow/T command
// -- add help text for all of the controls
// -- tab order? can I set this?
//
Window VSANS_DataPanel() : Panel
	PauseUpdate; Silent 1		// building window...

	Variable sc = 1
			
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif
	
	if(root:Packages:NIST:VSANS:Globals:gLaptopMode==1)
		NewPanel /W=(7,36,700,480) /K=1 /N=VSANS_Data
	else
		NewPanel /W=(37,45,1038,719) /K=1 /N=VSANS_Data
	endif
	

//	ShowTools/A
	ModifyPanel cbRGB=(65535,60076,49151)

	String curFolder = root:Packages:NIST:VSANS:Globals:gCurDispType
	DoWindow/T VSANS_Data,curFolder + " VSANS_Data"
	SetWindow VSANS_Data,hook(dataHook)=VSANSDataHook,hookevents=2
	
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 200*sc,70*sc,310*sc,160*sc
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 320*sc,70*sc,430*sc,160*sc
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 440*sc,70*sc,535*sc,160*sc
	
	SetDrawEnv fsize= 18
	DrawText 230*sc,115*sc,"Front"
	SetDrawEnv fsize= 18
	DrawText 348*sc,115*sc,"Middle"
	SetDrawEnv fsize= 18
	DrawText 476*sc,115*sc,"Back"
	
	ToolsGrid visible=1


	TabControl tab0,pos={sc*13,41*sc},size={sc*572,617*sc},proc=V_DataTabProc,tabLabel(0)="Front"
	TabControl tab0,tabLabel(1)="Middle",tabLabel(2)="Back",value= 2,focusRing=0
	TabControl tab0 labelBack=(63535,56076,45151)

// on the side	
	Button button_status,pos={sc*607,146*sc},size={sc*70,20*sc},proc=V_StatusButtonProc,title="Status",disable=2
	Button button_IvsQ,pos={sc*689,113*sc},size={sc*70,20*sc},proc=V_IvsQPanelButtonProc,title="I vs. Q"
	Button button_file_m,pos={sc*619,55*sc},size={sc*50,20*sc},proc=V_File_minus_ButtonProc,title="File <"
	Button button_file_p,pos={sc*679,55*sc},size={sc*50,20*sc},proc=V_File_plus_ButtonProc,title="File >"
	Button button_log,pos={sc*689,146*sc},size={sc*70,20*sc},proc=V_LogLinButtonProc,title="isLin",userData="0"
	Button button_tab_p,pos={sc*648,81*sc},size={sc*50,20*sc},proc=V_Tab_p_ButtonProc,title="Tab >"
	Button button_isolate,pos={sc*606,114*sc},size={sc*70,20*sc},proc=V_IsolateButtonProc,title="Isolate"
	Button button_toWork,pos={sc*770,146*sc},size={sc*90,20*sc},proc=V_ToWorkFileButtonProc,title="to WORK"
	Button button_annular,pos={sc*770,114*sc},size={sc*90,20*sc},proc=V_annularAvgButtonProc,title="Annular Avg"
	Button button_SpreadPanels,pos={sc*880,114*sc},size={sc*100,20*sc},proc=V_SpreadPanelButtonProc,title="Spread Panels"
	Button button_RestorePanels,pos={sc*880,146*sc},size={sc*100,20*sc},proc=V_RestorePanelButtonProc,title="Restore Panels"

	Button button_sensor,pos={sc*607,(146+33)*sc},size={sc*70,20*sc},proc=V_SensorButtonProc,title="Sensors"
	Button button_mask,pos={sc*689,(146+33)*sc},size={sc*70,20*sc},proc=V_AvgMaskButtonProc,title="Avg Mask"


	TitleBox title_file,pos={sc*606,(178+30)*sc},fsize=12*sc,size={sc*76,20*sc},variable= root:Packages:NIST:VSANS:Globals:gLastLoadedFile
	TitleBox title_dataPresent,pos={sc*606,(210+30)*sc},fsize=12*sc,size={sc*76,20*sc},variable= root:Packages:NIST:VSANS:Globals:gCurDispFile
	TitleBox title_status,pos={sc*606,(240+30)*sc},size={sc*200,200*sc},fsize=12*sc,variable= root:Packages:NIST:VSANS:Globals:gStatusText
	
//	Button button_tagFile,pos={sc*720,412*sc},size={sc*70,20*sc},proc=V_TagFileButtonProc,title="Tag File"
//	Button button_tagFile,disable=2
//	Button button_saveIQ,pos={sc*603,412*sc},size={sc*120,20*sc},proc=V_SaveIQ_ButtonProc,title="Save I(Q) as ITX"
//	Button button_BeamCtr,pos={sc*603,566*sc},size={sc*110,20*sc},proc=V_BeamCtrButtonProc,title="Beam Center",disable=2
//	Button pick_trim,pos={sc*603,450*sc},size={sc*120,20*sc},proc=V_TrimDataProtoButton,title="Trim I(Q) Data"
//	Button pick_trim,help={"This button will prompt the user for trimming parameters"}	
	

// on the tabs, always visible
	TitleBox title_xy,pos={sc*20,65*sc},fsize=12*sc,size={sc*76,20*sc},variable= root:Packages:NIST:VSANS:Globals:gLastLoadedFile
	Slider slider_hi,pos={sc*558,224*sc},size={sc*16,80*sc},proc=V_HiMapSliderProc
	Slider slider_hi,limits={0,1,0*sc},value= 1,ticks= 0
	Slider slider_lo,pos={sc*558,315*sc},size={sc*16,80*sc},proc=V_LowMapSliderProc
	Slider slider_lo,limits={0,1,0*sc},value= 0,ticks= 0

	SetVariable xpos,pos={sc*22,97*sc},size={sc*50,17*sc},title="X "
	SetVariable xpos,limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gXPos
	SetVariable xpos,help={"x-position on the detector"},frame=0,noedit=1
	SetVariable ypos,pos={sc*22,121*sc},size={sc*50,17*sc},title="Y "
	SetVariable ypos,limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gYPos
	SetVariable ypos,help={"y-position on the detector"},frame=0,noedit=1
	SetVariable counts,pos={sc*22,151*sc},size={sc*150,17*sc},title="Counts "
	SetVariable counts,limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gNCounts
	SetVariable counts,help={"Neutron counts"},frame=0,noedit=1
	SetVariable qxval,pos={sc*83,94*sc},size={sc*85,17*sc},title="qX"
	SetVariable qxval,help={"q value in the x-direction on the detector"},frame=0,noedit=1
	SetVariable qxval,format="%+7.5f",limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gQX
	SetVariable qyval,pos={sc*83,113*sc},size={sc*85,17*sc},title="qY"
	SetVariable qyval,help={"q value in the y-direction on the detector"},frame=0,noedit=1
	SetVariable qyval,format="%+7.5f",limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gQY
	SetVariable q_pos,pos={sc*83,132*sc},size={sc*85,17*sc},title="q "
	SetVariable q_pos,help={"q-value on the detector at (x,y)"},format="%+7.5f"
	SetVariable q_pos,limits={-Inf,Inf,0*sc},value= root:Packages:NIST:VSANS:Globals:gQQ,frame=0,noedit=1
	
	Make/O/D tmp_asdf
	// for back panels (in pixels)	
//	Display/W=(50,185,517,620)/HOST=# tmp_asdf 
	Display/W=(50*sc,185*sc,517*sc,620*sc)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsB
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
//	Label left "pixels"			//don't bother labeling pixels here - it will get redrawn, do it 
//	Label bottom "pixels"			// when the selected tab is resized to be the focus
	SetActiveSubwindow ##
	
	// for middle panels (in pixels?)	
	Display/W=(50*sc,185*sc,517*sc,620*sc)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsM
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
//	Label left "pixels"
//	Label bottom "pixels"	
	SetActiveSubwindow ##
	
	// for front panels (in pixels?)	
	Display/W=(50*sc,185*sc,517*sc,620*sc)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsF
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
//	Label left "pixels"
//	Label bottom "pixels"	
	SetActiveSubwindow ##
	
EndMacro

//
// event code 4: mouse moved
// event code 11: keyboard events
// 
// mouse moved is the only event that I really care about for the data display.
//
// TODO:
// -- figure out how to respond only to events in the main window
// -- figure out which is the correct image to respond "from"
// -- More complete documentation of how the hook is identifying what graph is "under" the mouse
//    AND what assumptions are behind this identification
//
//
Function VSANSDataHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif

	switch(s.eventCode)
		case 0:				// Activate
			// Handle activate
//			Print "Activate"
			break

		case 1:				// Deactivate
			// Handle deactivate
			break
			
		case 3:		//mouse down
//			Print "mouse down"
//
// TODO (Way in the future -- I could make the small graphs into "buttons" by responding to a "mouse up" (not down)
//    that hits in one of the small graph areas, and treat that as a click on that tab
// -- instead of this, I can try to get the focus rectangle to work more easily to move with the TAB,
//    if I can intercept the keystroke (event 11), see below.
//
			break
			
		case 4:		// mouse moved
			NVAR xloc = root:Packages:NIST:VSANS:Globals:gXPos
			NVAR yloc = root:Packages:NIST:VSANS:Globals:gYPos
			NVAR gQX = root:Packages:NIST:VSANS:Globals:gQX
			NVAR gQY = root:Packages:NIST:VSANS:Globals:gQY
			NVAR gQQ = root:Packages:NIST:VSANS:Globals:gQQ
			NVAR gNCounts = root:Packages:NIST:VSANS:Globals:gNCounts
			SVAR gCurDispFile = root:Packages:NIST:VSANS:Globals:gCurDispFile
			SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType		//the current folder
			Variable xaxval,yaxval,tab
			
			// is the mouse location within the "main" display window?
			// if so, do something, if not, do nothing?
			// right now, the "main" display is at (50,185,517,620). its name depends on the active tab
			
//				xloc = s.mouseLoc.h
//				yloc = s.mouseLoc.v

//			if out of bounds, exit now
//		TODO - currently the values are hard-wired. eliminate this later if the size of the graph changes
// SEP 2020 ditched the s.mouseLoc read -- can't seem to rely on these values since I don't
// understand how they relate to the graph position. I'll just have to tolerate the readings that
// are out-of-bounds
//			if(s.mouseLoc.h < 50*sc || s.mouseLoc.h > 517*sc || s.mouseLoc.v < 185*sc || s.mouseLoc.v > 620*sc)
//				break
//			endif	
			
//			if(in bounds)
//				get the point location
//				update the globals --
//				but which data instance am I pointing to?
//				deduce the carriage and panel, and calculate Q
//			endif

			GetWindow $s.winName activeSW
			String activeSubwindow = S_value		// returns something like: "VSANS_Data#det_panelsF"
				
			xaxval= AxisValFromPixel("","bottom",s.mouseLoc.h)
			yaxval= AxisValFromPixel("","left",s.mouseLoc.v)
//			xloc = round(xaxval)
//			yloc = round(yaxval)
			xloc = xaxval
			yloc = yaxval
			
			// which tab is selected? -this is the main graph panel (subwindow may not be the active one!)
			ControlInfo/W=VSANS_Data tab0
			tab = V_Value
			if(tab == 0)
				activeSubwindow = "VSANS_Data#det_panelsF"
			elseif (tab == 1)
				activeSubwindow = "VSANS_Data#det_panelsM"
			else
				activeSubwindow = "VSANS_Data#det_panelsB"
			endif
			
			
			// which images are here?
			String detStr="",imStr,carriageStr
			String currentImageRef
			String imageList = ImageNameList(activeSubwindow,";")
			Variable ii,nIm,testX,testY,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
			nIm = ItemsInList(imageList,";")
			gCurDispFile = imageList
			if(nIm==0)
				break		//problem, get out
			endif

			// images were added in the order TBLR, so look back through in the order RLBT, checking each to see if
			// the xy value is found on that (scaled) array
						
			// loop backwards through the list of panels (may only be one if on the back)
			for(ii=nIm-1;ii>=0;ii-=1)
				Wave w = ImageNameToWaveRef(activeSubwindow,StringFromList(ii, imageList,";"))
				
				// which, if any image is the mouse xy location on?
				// use a multidemensional equivalent to x2pnt: (ScaledDimPos - DimOffset(waveName, dim))/DimDelta(waveName,dim)

				
				testX = ScaleToIndex(w,xloc,0)
				testY = ScaleToIndex(w,yloc,1)
				
				if( (testX >= 0 && testX < DimSize(w,0)) && (testY >= 0 && testY < DimSize(w,1)) )
					// we're in-bounds on this wave
					
					// count value to the global
					gNCounts = w[testX][testY]		//wrong for T/B panels

					
					// deduce the detector panel
					currentImageRef = StringFromList(ii, imageList,";")	//the image instance ##
					// string is "data", or "data#2" etc. - so this returns "", "1", "2", or "3"
					imStr = StringFromList(1, currentImageRef,"#")		
					carriageStr = activeSubWindow[strlen(activeSubWindow)-1]
					
					if(cmpstr(carriageStr,"B")==0)
						detStr = carriageStr
					else
						if(strlen(imStr)==0)
							imStr = "9"			// a dummy value so I can replace it later
						endif
						detStr = carriageStr+imStr		// "F2" or something similar
						detStr = ReplaceString("9", detStr, "T") 	// ASSUMPTION :::: instances 0123 correspond to TBLR
						detStr = ReplaceString("1", detStr, "B") 	// ASSUMPTION :::: this is the order that the panels
						detStr = ReplaceString("2", detStr, "L") 	// ASSUMPTION :::: are ALWAYS added to the graph
						detStr = ReplaceString("3", detStr, "R") 	// ASSUMPTION :::: 
					endif
					gCurDispFile = detStr

					// now figure out q
					// calculate the q-values, will be different depending on which panel is up (pixel size, geometry, etc.)
					// DONE: !!!! get rid of the hard-wired values
					// DONE: be sure that the units from HDF are what I expect
					// DONE: beam center XY are pixels in the file, expected in the function, but are better suited for mm or cm
					// DONE: units of xy pixel size are likely wrong
//					xctr = V_getDet_beam_center_x(gCurDispType,detStr)		//written in pixels
//					yctr = V_getDet_beam_center_y(gCurDispType,detStr)
					xctr = V_getDet_beam_center_x_mm(gCurDispType,detStr)		//written in mm
					yctr = V_getDet_beam_center_y_mm(gCurDispType,detStr)	
					
					sdd = V_getDet_ActualDistance(gCurDispType,detStr)		//written in cm, pass in [cm]
					lam = V_getWavelength(gCurDispType)		//A
//					pixSizeX = V_getDet_x_pixel_size(gCurDispType,detStr)		// written mm? need mm
//					pixSizeY = V_getDet_y_pixel_size(gCurDispType,detStr)		// written mm? need mm
//

					String destPath = "root:Packages:NIST:VSANS:"+gCurDispType
					Wave data_realDistX = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistX")
					Wave data_realDistY = $(destPath + ":entry:instrument:detector_"+detStr+":data_realDistY")	
					
// DONE: figure out what coordinates I need to pass -- xloc, yloc, textX, testY, (+1 on any?)				
					//gQQ = VC_CalcQval(testX,testY,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
					//gQX = VC_CalcQX(testX,testY,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
					//gQY = VC_CalcQY(testX,testY,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
					gQQ = V_CalcQval(testX,testY,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)
					gQX = V_CalcQX(testX,testY,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)
					gQY = V_CalcQY(testX,testY,xctr,yctr,sdd,lam,data_realDistX,data_realDistY)

					ii = -1		//look no further, set ii to bad value to exit the for loop
					
					// TODO
					//  this - it sets the globals to display to the pixel values, unscaled
					xloc = testX
					yloc = testY
//
//					xloc = xaxval
//					yloc = yaxval
//					xloc = s.mouseLoc.h
//					yloc = s.mouseLoc.v									
				endif	//end if(mouse is over a detector panel)
				

			endfor		// end loop over list of displayed images
		
			break
			
			case 11: // keyboard event
				// TODO -- figure out why I'm not getting the TAB keystroke
				//  -- I want to be able to use the tab to change the focus only between File <.> and Tab > buttons, not everything
				// see the help file section "Keyboard Events" for an example and "WMWinHookStruct"
				
				//Print "key code = ",s.specialKeyCode
				//hookresult = 1		//if non-zero, we handled it and Igor will ignore it
				break
		// And so on . . .
	endswitch

	return hookResult		// 0 if nothing done, else 1
End


// ********
//
// this procedure does most of the work for drawing the panels, setting the proper log/lin
// scaling, the color scale, and the location based on the active tab
//
//lots to to here:
//
// - 1 - display the appropriate controls for each tab, and hide the others
// - 2 - display the correct detector data for each tab, and remove the others from the graph
// -----?? can I draw 3 graphs, and just put the right one on top?? move the other two to the side?
//
//
// TODO_LOW 
//  -- add all of the controls of the VCALC panel (log scaling, adjusting the axes, etc.)
//  x- get the panel to be correctly populated first, rather than needing to click everywhere to fill in
//  x- remove the dependency on VCALC being initialized first, and using dummy waves from there...
//
//
Function V_DataTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca


	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif

	Variable isDenex=0
	String detDescription=""

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
		
//			SetDataFolder root:Packages:NIST:VSANS:VCALC
			SetDataFolder root:
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsB tmp_asdf
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsM tmp_asdf
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsF tmp_asdf
			SetDataFolder root:
			
			SVAR dataType = root:Packages:NIST:VSANS:Globals:gCurDispType
			
			if( cmpstr("Denex",V_getDetDescription(dataType,"B")) == 0)
				isDenex = 1
			endif

// make sure log scaling is correct
			NVAR state = root:Packages:NIST:VSANS:Globals:gIsLogScale
			if(State == 0)
				// lookup wave
				Wave LookupWave = root:Packages:NIST:VSANS:Globals:linearLookupWave
			else
				// lookup wave - the linear version
				Wave LookupWave = root:Packages:NIST:VSANS:Globals:logLookupWave
			endif
			
			
			//************
			// -- can I use "ReplaceWave/W=VSANS_Data#det_panelsB allinCDF" to do this?
			// -- only works for "B", since for M and F panels, all 4 data sets are named "data"
			// in their respective folders...
			
			
			// get the slider values for the color mapping
			Variable lo,hi,lo_B,hi_B
			Variable lo_MT,lo_MB,lo_MR,lo_ML
			Variable lo_FT,lo_FB,lo_FR,lo_FL
			Variable hi_MT,hi_MB,hi_MR,hi_ML
			Variable hi_FT,hi_FB,hi_FR,hi_FL
			Variable lo_M,hi_M,lo_F,hi_F
			
			ControlInfo slider_lo
			lo = V_Value
			ControlInfo slider_hi
			hi = V_Value
			
			
			String tmpStr
			Variable ii
			if(tab==2)
				tmpStr = ImageNameList("VSANS_Data#det_panelsB",";")
				// for some odd reason, it appears that I need to work from the back of the list
				// since the traces get "renumbered" as I take them off !! A do loop may be a better choice
				if(ItemsInList(tmpStr) > 0)
					do
						RemoveImage /W=VSANS_Data#det_panelsB $(StringFromList(0,tmpStr,";"))		//get 1st item
						tmpStr = ImageNameList("VSANS_Data#det_panelsB",";")								//refresh list
					while(ItemsInList(tmpStr) > 0)
				endif
				
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_B")
				Wave det_B=data
				
				CheckDisplayed /W=VSANS_Data#det_panelsB det_B	
				if(V_flag == 0)		// 0 == data is not displayed, so append it
					AppendImage/W=VSANS_Data#det_panelsB det_B
					lo_B = lo*(WaveMax(det_B) - WaveMin(det_B)) + WaveMin(det_B)
					hi_B = hi*(WaveMax(det_B) - WaveMin(det_B)) + WaveMin(det_B)
					ModifyImage/W=VSANS_Data#det_panelsB ''#0 ctab= {lo_B,hi_B,ColdWarm,0}		// don't autoscale {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(50*sc,185*sc,517*sc,620*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320*sc,70*sc,430*sc,160*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200*sc,70*sc,310*sc,160*sc)

				ModifyImage/W=VSANS_Data#det_panelsB ''#0 ctabAutoscale=0,lookup= LookupWave

				if(isDenex)				
//				// make the plot square
					ModifyGraph/W=VSANS_Data#det_panelsB width={Aspect,1}
				else
				// match the aspect ratio of the data
					ModifyGraph/W=VSANS_Data#det_panelsB width={Aspect,0.41}			//680/1656 = 0.41
				endif
				
				SetActiveSubWindow VSANS_Data#det_panelsB
				Label left "pixels"
				Label bottom "pixels"
				SetDataFolder root:
			endif
	
			if(tab==1)
				tmpStr = ImageNameList("VSANS_Data#det_panelsM",";")
				// for some odd reason, it appears that I need to work from the back of the list
				// since the traces get "renumbered" as I take them off !! A do loop may be a better choice
				if(ItemsInList(tmpStr) > 0)
					do
						RemoveImage /W=VSANS_Data#det_panelsM $(StringFromList(0,tmpStr,";"))		//get 1st item
						tmpStr = ImageNameList("VSANS_Data#det_panelsM",";")								//refresh list
					while(ItemsInList(tmpStr) > 0)
				endif

				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_ML")
				Wave det_ML=data				
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_MR")
				Wave det_MR=data
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_MT")
				Wave det_MT=data
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_MB")
				Wave det_MB=data

				CheckDisplayed /W=VSANS_Data#det_panelsM det_MR
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsM det_MT		//order is important here to get LR on "top" of display
					AppendImage/W=VSANS_Data#det_panelsM det_MB
					AppendImage/W=VSANS_Data#det_panelsM det_ML
					AppendImage/W=VSANS_Data#det_panelsM det_MR
					lo_MT = lo*(WaveMax(det_MT) - WaveMin(det_MT)) + WaveMin(det_MT)
					hi_MT = hi*(WaveMax(det_MT) - WaveMin(det_MT)) + WaveMin(det_MT)
					lo_MB = lo*(WaveMax(det_MB) - WaveMin(det_MB)) + WaveMin(det_MB)
					hi_MB = hi*(WaveMax(det_MB) - WaveMin(det_MB)) + WaveMin(det_MB)
					lo_ML = lo*(WaveMax(det_ML) - WaveMin(det_ML)) + WaveMin(det_ML)
					hi_ML = hi*(WaveMax(det_ML) - WaveMin(det_ML)) + WaveMin(det_ML)
					lo_MR = lo*(WaveMax(det_MR) - WaveMin(det_MR)) + WaveMin(det_MR)
					hi_MR = hi*(WaveMax(det_MR) - WaveMin(det_MR)) + WaveMin(det_MR)
					
					// use a global scale for all 4 panels on the carriage
					lo_M = min(lo_MT,lo_MB,lo_MR,lo_ML)
					hi_M = max(hi_MT,hi_MB,hi_MR,hi_ML)
							
					ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctab= {lo_M,hi_M,ColdWarm,0}		// ''#n means act on the nth image (there are 4)
					ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctab= {lo_M,hi_M,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctab= {lo_M,hi_M,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctab= {lo_M,hi_M,ColdWarm,0}
					
					//
					// un comment to use individual color scale (per panel)
//					ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctab= {lo_MT,hi_MT,ColdWarm,0}		// ''#n means act on the nth image (there are 4)
//					ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctab= {lo_MB,hi_MB,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctab= {lo_ML,hi_ML,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctab= {lo_MR,hi_MR,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(50*sc,185*sc,517*sc,620*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440*sc,70*sc,550*sc,160*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200*sc,70*sc,310*sc,160*sc)

				ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctabAutoscale=0,lookup= LookupWave
				
				// make the plot square
				ModifyGraph/W=VSANS_Data#det_panelsM width={Aspect,1}
							
				SetActiveSubWindow VSANS_Data#det_panelsM
				Label left "pixels"
				Label bottom "pixels"
				SetDataFolder root:
			endif

			if(tab==0)
				tmpStr = ImageNameList("VSANS_Data#det_panelsF",";")
				// for some odd reason, it appears that I need to work from the back of the list
				// since the traces get "renumbered" as I take them off !! A do loop may be a better choice
				if(ItemsInList(tmpStr) > 0)
					do
						RemoveImage /W=VSANS_Data#det_panelsF $(StringFromList(0,tmpStr,";"))		//get 1st item
						tmpStr = ImageNameList("VSANS_Data#det_panelsF",";")								//refresh list
					while(ItemsInList(tmpStr) > 0)
				endif

				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_FL")
				Wave det_FL=data
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_FR")
				Wave det_FR=data
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_FT")
				Wave det_FT=data				
				SetDataFolder $("root:Packages:NIST:VSANS:"+dataType+":entry:instrument:detector_FB")
				Wave det_FB=data
								
				CheckDisplayed /W=VSANS_Data#det_panelsF det_FL
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsF det_FT
					AppendImage/W=VSANS_Data#det_panelsF det_FB
					AppendImage/W=VSANS_Data#det_panelsF det_FL
					AppendImage/W=VSANS_Data#det_panelsF det_FR
					lo_FT = lo*(WaveMax(det_FT) - WaveMin(det_FT)) + WaveMin(det_FT)
					hi_FT = hi*(WaveMax(det_FT) - WaveMin(det_FT)) + WaveMin(det_FT)
					lo_FB = lo*(WaveMax(det_FB) - WaveMin(det_FB)) + WaveMin(det_FB)
					hi_FB = hi*(WaveMax(det_FB) - WaveMin(det_FB)) + WaveMin(det_FB)
					lo_FL = lo*(WaveMax(det_FL) - WaveMin(det_FL)) + WaveMin(det_FL)
					hi_FL = hi*(WaveMax(det_FL) - WaveMin(det_FL)) + WaveMin(det_FL)
					lo_FR = lo*(WaveMax(det_FR) - WaveMin(det_FR)) + WaveMin(det_FR)
					hi_FR = hi*(WaveMax(det_FR) - WaveMin(det_FR)) + WaveMin(det_FR)
					
					// use a global scale for all 4 panels on the carriage
					lo_F = min(lo_FT,lo_FB,lo_FR,lo_FL)
					hi_F = max(hi_FT,hi_FB,hi_FR,hi_FL)
					
					ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctab= {lo_F,hi_F,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctab= {lo_F,hi_F,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctab= {lo_F,hi_F,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctab= {lo_F,hi_F,ColdWarm,0}
					
					// un comment to use individual (per panel) color scale
//					ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctab= {lo_FT,hi_FT,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctab= {lo_FB,hi_FB,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctab= {lo_FL,hi_FL,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctab= {lo_FR,hi_FR,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(50*sc,185*sc,517*sc,620*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440*sc,70*sc,550*sc,160*sc)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320*sc,70*sc,430*sc,160*sc)
				
				ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctabAutoscale=0,lookup= LookupWave
				ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctabAutoscale=0,lookup= LookupWave

				// make the plot square
				ModifyGraph/W=VSANS_Data#det_panelsF width={Aspect,1}				
	
				SetActiveSubWindow VSANS_Data#det_panelsF
				Label left "pixels"
				Label bottom "pixels"
				SetDataFolder root:
			endif

						
			break
		case -1: // control being killed
			break
	endswitch


// update the status when the tab is clicked			
	STRUCT WMButtonAction sa
	sa.eventCode = 2
	V_StatusButtonProc(sa)
			
			
	return 0
End


// fake restore panels button click
Function V_FakeRestorePanelsButtonClick()

	STRUCT WMButtonAction ba
	ba.eventCode = 2
	V_RestorePanelButtonProc(ba)
	
	return(0)
End


// fake status button click
Function V_FakeStatusButtonClick()

	STRUCT WMButtonAction ba
	ba.eventCode = 2
	V_StatusButtonProc(ba)
	
	return(0)
End

// fake click on each tab to populate the data
Function V_FakeTabClick(tab)
	Variable tab
	
	STRUCT WMTabControlAction tca

	tca.eventCode = 2		//fake mouse up
	tca.tab = tab
	V_DataTabProc(tca)
	
	TabControl tab0,win=VSANS_Data,value= tab		//select the proper tab
	return(0)
End

// 
//
// move one file number back
//
Function V_File_minus_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_LoadPlotAndDisplayRAW(-1)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// 
//
// move one file number forward
//
Function V_File_plus_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_LoadPlotAndDisplayRAW(1)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// button that mimics a click on the tab, cycling through the tabs 0->1->2->0 etc.
// only goes one direction
//
Function V_Tab_p_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo/W=VSANS_Data tab0
			
			V_Value += 1
			if(V_Value == 3)
				V_Value = 0		//reset to 0
			endif
			V_FakeTabClick(V_Value)

// now part of every tab click
//// update the status when the tab is clicked			
			STRUCT WMButtonAction sa
			sa.eventCode = 2
			V_StatusButtonProc(sa)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// opens up the graph of the sensors available
//
Function V_SensorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_InitSensorGraph()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// opens up the graph of the masking options
//
Function V_AvgMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_Display_Four_Panels()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// See V_Detector_Isolate.ipf
// isolates a single panel to allow a better view of the details
// useful for T/B panels which are partially blocked from view
//
// will open a separate panel to display the selected detector
// (more to do here, depending what is necessary for instrument troubleshooting)
// - like being able to turn corrections on/off and view with different axes (pix, mm, Q)
//
Function V_IsolateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_DetectorIsolate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// if the data display is RAW, convert to the specified WORK data type
//
// DONE
// x- better error checking
// x- if the data type is not RAW, can I Copy Folder instead?
//
Function V_ToWorkFileButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Execute "V_Convert_to_Workfile()"

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
//
// opens a separate panel with the I(q) representation of the data
//  controls on the panel select how the data is processed/grouped, etc.
//
//
Function V_IvsQPanelButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_PlotData_Panel()		//-9999 requests a read from the popup on the panel
			Variable binType = V_GetBinningPopMode()
			ControlInfo/W=V_1D_Data popup0
			//
			// generate a default mask to ensure that there are no errors if it is not present
			V_GenerateDefaultMask()
			
			//
			V_BinningModePopup("",binType,S_Value)		// does binning of current popString and updates the graph
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// DONE:
// x- simply calls the missing parameter dialog to do the average.
//  see the file V_IQ_Annular.ipf for all of the features yet to be added.
//
// x- currently just the graph, no controls
//
Function V_annularAvgButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Execute "V_Annular_Binning()"			

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// 
//
// gets the status of the currently displayed file and dumps it to the panel (not the cmd window)
// - lots to decide here about what is the important stuff to display. There's a lot more information for VSANS
//
Function V_StatusButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// figure out wether to display per carraige, or the whole file
			SVAR str = root:Packages:NIST:VSANS:Globals:gStatusText
			SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType		//what folder
			// which tab active
			ControlInfo/W=VSANS_Data tab0
			Variable curTab = V_value
			
//			// fake this, since if the tab was clicked, it hasn't been updated yet and we're off by one
//			if(ba.eventCode == 3)
//				curTab += 1
//				if(curTab == 3)
//					curTab = 0
//				endif
//			endif
			
			//
			str = "Current data is from "+ type + "\r"
			str += "Description = "+V_getSampleDescription(type) + "\r"
			str += "Wavelength is "+num2str(V_getWavelength(type)) + " A \r"
			if(curTab == 2)
				str += "SDD B = "+num2str(V_getDet_ActualDistance(type,"B")) + " cm \r"		//V_getDet_distance(fname,detStr)
			endif
			if(curTab == 1)
				str += "SDD ML = "+num2str(V_getDet_ActualDistance(type,"ML")) + " cm   "
				str += "offset = "+num2str(V_getDet_LateralOffset(type,"ML")) + " cm \r"
				str += "SDD MR = "+num2str(V_getDet_ActualDistance(type,"MR")) + " cm   "
				str += "offset = "+num2str(V_getDet_LateralOffset(type,"MR")) + " cm \r"
				str += "SDD MT = "+num2str(V_getDet_ActualDistance(type,"MT")) + " cm   "
				str += "offset = "+num2str(V_getDet_VerticalOffset(type,"MT")) + " cm \r"
				str += "SDD MB = "+num2str(V_getDet_ActualDistance(type,"MB")) + " cm   "
				str += "offset = "+num2str(V_getDet_VerticalOffset(type,"MB")) + " cm \r"
			endif
			if(curTab == 0)
				str += "SDD FL = "+num2str(V_getDet_ActualDistance(type,"FL")) + " cm   "
				str += "offset = "+num2str(V_getDet_LateralOffset(type,"FL")) + " cm \r"
				str += "SDD FR = "+num2str(V_getDet_ActualDistance(type,"FR")) + " cm   "
				str += "offset = "+num2str(V_getDet_LateralOffset(type,"FR")) + " cm \r"
				str += "SDD FT = "+num2str(V_getDet_ActualDistance(type,"FT")) + " cm   "
				str += "offset = "+num2str(V_getDet_VerticalOffset(type,"FT")) + " cm \r"
				str += "SDD FB = "+num2str(V_getDet_ActualDistance(type,"FB")) + " cm   "
				str += "offset = "+num2str(V_getDet_VerticalOffset(type,"FB")) + " cm \r"
			endif
			
			
			
			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// TODO_VERIFY:
// x- link this to the preferences for the display. this is done in UpdateDisplayInformation (the main call) so that
//     the panels are rescaled only once, rather than toggled three times (F, M, B) if I call from the tabProc
// -- come up with a better definition of the log lookup wave (> 1000 pts, what is the first point)
// -- make an equivalent linear wave
// -- hard wire it in so it is created at initialization and stored someplace safe
// -- catch the error if it doesn't exist (re-make the wave as needed)
//
// Using the ModifyImage log=1 keyword fails for values of zero in the data, which is a common
// occurrence with count data. the display just goes all gray, so that's not an option. Use the lookup wave instead
//
// toggle the (z) value of the display log/lin
//
Function V_LogLinButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// which tab is active? does it matter - or do I log-scale everything?
			// log/lin current state is in the S_UserData string (0=linear, 1=log)
			ControlInfo/W=VSANS_Data button_log
			Variable curState,newState
			String newStateStr,newTitleStr
			
			
			curState = str2num(S_UserData)
			
			if(curState == 0)
				newState = 1
				newStateStr="1"
				newTitleStr = "isLog"
				// lookup wave
				Wave LookupWave = root:Packages:NIST:VSANS:Globals:logLookupWave
			else
				newState = 0
				newStateStr="0"
				newTitleStr = "isLin"
				// lookup wave - the linear version
				Wave LookupWave = root:Packages:NIST:VSANS:Globals:linearLookupWave
			endif
			
			// update the button and the global value
			Button button_log,userData=newStateStr,title=newTitleStr
			NVAR state = root:Packages:NIST:VSANS:Globals:gIsLogScale
			state = newState
			
			// on the front:			
			ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctabAutoscale=0,lookup= LookupWave
			//on the middle:
//			ModifyImage/W=VSANS_Data#det_panelsM ''#0 log=newState
//			ModifyImage/W=VSANS_Data#det_panelsM ''#1 log=newState
//			ModifyImage/W=VSANS_Data#det_panelsM ''#2 log=newState
//			ModifyImage/W=VSANS_Data#det_panelsM ''#3 log=newState
				
			ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctabAutoscale=0,lookup= LookupWave
			ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctabAutoscale=0,lookup= LookupWave


			// on the back:
			ModifyImage/W=VSANS_Data#det_panelsB ''#0 ctabAutoscale=0,lookup= LookupWave

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO_LOW
// -- possibly use this function to "tag" files right here in the disaply with things
// like their intent, or other values that reduction will need, kind of like a "quick patch"
// with limited functionality (since full function would be a nightmare!) 
Function V_TagFileButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0, "TagFileButtonProc(ba) unfinished - this may be used to 'tag' a file as scatter, trans, emp, bkg, etc."
			
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO_LOW
// -- currently this button is NOT visible on the RAW data display. Any saving of data
//    must go through a protocol (RAW can't be saved)
// -- fill in more functionality
// -- currently a straight concatentation of all data, no options
// -- maybe allow save of single panels?
// -- any other options?
Function V_SaveIQ_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

//			V_SimpleSave1DData("root:Packages:NIST:VSANS:","","","")	

// this is the same as clicking the I(q) button. Ensures that the current file has been averaged, 
// and the data being saved is not "stale"

			V_PlotData_Panel()		//
			Variable binType = V_GetBinningPopMode()
			ControlInfo/W=V_1D_Data popup0
			V_BinningModePopup("",binType,S_Value)		// does default circular binning and updates the graph
	
			SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType		//what folder

			// look for the binning type
//			Variable binType
//			ControlInfo/W=V_1D_Data popup0
//			binType = (V_flag == 0) ? 1 : V_flag		// if binType not defined, set binType == 1

			String saveName="",exten=""
		// write out the data set to a file
			if(strlen(saveName)==0)
				Execute "V_GetNameForSave()"
				SVAR newName = root:saveName
				saveName = newName
			endif
			
//			V_Write1DData_ITX("root:Packages:NIST:VSANS:",type,saveName,binType)

			V_Write1DData_Individual("root:Packages:NIST:VSANS:",type,saveName,exten,binType)
	
			Print "Saved file: "	+	saveName + ".itx"	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//TODO_LOW
//
//link this to the beam center finding panel
//
Function V_BeamCtrButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"Beam Center panel is under construction..."
//			V_FindBeamCenter()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//
// this "spreads" the display of panels to a nominal separation for easier viewing
//
Function V_SpreadPanelButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_SpreadOutPanels()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
//
// this "restores" the display of panels to their actual position based on the apparent beam center
//
Function V_RestorePanelButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			V_RestorePanels()
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// link this slider to the "high" end of the color mapping for whatever is currently displayed
//
// -- see Buttons.ipf for the old SANS implementation
//
Function V_HiMapSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				ControlInfo tab0
				V_FakeTabClick(V_Value)
				
//				ControlInfo slider_lo
//				V_MakeImageLookupTables(10000,V_Value,curval)
			endif
			break
	endswitch

	return 0
End

// TODO
//
// link this slider to the "low" end of the color mapping for whatever is currently displayed
//
// -- see Buttons.ipf for the old SANS implementation
//
Function V_LowMapSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				ControlInfo tab0
				V_FakeTabClick(V_Value)

//				ControlInfo slider_hi
//				V_MakeImageLookupTables(10000,curval,V_Value)
			endif
			break
	endswitch

	return 0
End


