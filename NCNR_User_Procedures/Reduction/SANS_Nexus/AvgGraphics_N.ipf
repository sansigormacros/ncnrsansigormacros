#pragma TextEncoding="UTF-8"
#pragma rtFunctionErrors=1
#pragma rtGlobals=3 // Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

// RTI clean

//*********************
// Vers 1.2 083101
// Procedures to interactively select the 2D to 1D averageing options and viewing the 1D data
// - pink "Average" panel and associated functions, including drawing on the 2D display
// - generation of the 1D graph, including rescaling options
// (rescaling options are quite similar to those in FIT_Ops)
//**********************

//main entry for invoking the pink average panel
Proc ShowAveragePanel()
	DoWindow/F Average_Panel
	if(V_flag == 0)
		InitializeAveragePanel()
		//draw panel
		Average_Panel()
		DisableUnusedParameters("Circular") //the default choice
	endif
EndMacro

//creates the necessary globals for the operation of the panel
Proc InitializeAveragePanel()
	//create the global variables needed to run the Average Panel
	//all are kept in root:myGlobals:Drawing
	if(!(DataFolderExists("root:myGlobals:Drawing")))
		NewDataFolder/O/S root:myGlobals:Drawing
	endif

	//ok, create the globals, fill the keyword string with all possible values (default)
	string/G root:myGlobals:Drawing:gDrawInfoStr = "AVTYPE=Circular;PHI=0;DPHI=0;WIDTH=0;SIDE=both;"
	root:myGlobals:Drawing:gDrawInfoStr+="QCENTER=0;QDELTA=0;"
	variable/G root:myGlobals:Drawing:gDrawPhi    = 0
	variable/G root:myGlobals:Drawing:gDrawWidth  = 1
	variable/G root:myGlobals:Drawing:gDrawDPhi   = 0
	variable/G root:myGlobals:Drawing:gDrawQCtr   = 0.01
	variable/G root:myGlobals:Drawing:gDrawQDelta = 0.001

	//return to root
	SetDataFolder root:
EndMacro

//button procedure to close the panel, does nothing else
Function AveDoneButtonProc(string ctrlName) : ButtonControl

	DoWindow/K Average_Panel
End

//button procedure to clear the lines drawn on the graph
//which were drawn in the "User Front" layer only
Function ClearLinesButtonProc(string ctrlName) : ButtonControl

	//Print "Clear the drawn lines from the graph"
	DoWindow/F SANS_Data
	SetDrawLayer/K UserFront
End

//button procedure that will perform the average on the currently displayed file
//using the choices that are currently in the panel
//the panel is not directly parsed, since each information box,SetVar,popup
//sets a corresponding value in the global string root:myGlobals:Drawing:gDrawInfoStr
Function Panel_DoAverageButtonProc(string ctrlName) : ButtonControl

	// average the currently displayed data
	SVAR type              = root:myGlobals:gDataDisplayType
	NVAR useXMLOutput      = root:Packages:NIST:gXML_Write
	NVAR useNXcanSASOutput = root:Packages:NIST:GNXcanSAS_Write

	//Check for logscale data in "type" folder
	string dest = "root:Packages:NIST:" + type

	NVAR     isLogScale  = $(dest + ":gIsLogScale")
	variable wasLogScale = isLogScale

	//set data folder back to root (redundant)
	SetDataFolder root:

	//build the string that the averaging routine is looking for
	//The draw string  uses the SAME keywords and value list - just copy it
	SVAR     tempstr                              = root:myGlobals:Drawing:gDrawInfoStr
	string/G root:myGlobals:Protocols:gAvgInfoStr = tempStr
	string   choice                               = StringByKey("AVTYPE", tempStr, "=", ";")

	//does the user want to save the averaged file to disk?
	//poll the checkbox - the keyword may not be in the string, and here we'll always ask for a filename
	ControlInfo/W=Average_Panel SaveCheck
	variable doSave = V_Value
	//if the "average" choice is 2D ASCII or QxQy ASCII, then doSave=1 to force a save
	if(strsearch(choice, "ASCII", 0) != -1)
		doSave = 1
	endif

	if(doSave)
		//setup a "fake protocol" wave, sice I have no idea of the current state of the data
		Make/O/T/N=8 root:myGlobals:Protocols:fakeProtocol
		WAVE/T fakeProtocol = $"root:myGlobals:Protocols:fakeProtocol"
		string junk         = "Unknown file from Average_Panel"
		fakeProtocol[0] = junk
		fakeProtocol[1] = junk
		fakeProtocol[2] = junk
		fakeProtocol[3] = junk
		fakeProtocol[4] = junk
		fakeProtocol[5] = junk
		fakeProtocol[6] = junk
		fakeProtocol[7] = tempStr
		//set the global
		string/G root:myGlobals:Protocols:gProtoStr = "fakeProtocol"
	endif

	//dispatch to correct averaging routine -
	strswitch(choice)
		case "Rectangular":
			RectangularAverageTo1D(type)
			break
		case "Annular":
			AnnularAverageTo1D(type)
			break
		case "Circular":
			CircularAverageTo1D(type) //graph is drawn here
			break
		case "Sector":
			//			CircularAverageTo1D(type)		//graph is drawn here
			SectorAverageTo1D(type)
			break
		case "2D_NXcanSAS":
			WriteNxCanSAS2D(type, "", 0)
			break
		case "2D ASCII":
			Fast2dExport(type, "", 1)
			break
		case "QxQy ASCII":
			QxQy_Export(type, "", 1)
			break
		case "Sector_PlusMinus":
			Sector_PlusMinus1D(type)
			break
		default:
			Abort "no case match in average dispatch"
	endswitch

	if(doSave)
		strswitch(choice)
			case "Annular":
				WritePhiave_W_Protocol(type, "", 1)
				break
			case "2D ASCII":  
			case "QxQy ASCII":  
			case "2D_NXcanSAS":
				break
			default:  
				if(useXMLOutput == 1)
					WriteXMLWaves_W_Protocol(type, "", 1)
				elseif(useNXcanSASOutput == 1)
					WriteNxCanSAS1D(type, "", 1)
				else
					WriteWaves_W_Protocol(type, "", 1) //"" is an empty path, 1 will force a dialog
				endif
		endswitch
	endif

	//clear the stuff that was created for case of saving files
	if(doSave)
		Killwaves/Z root:myGlobals:Protocols:fakeProtocol
		string/G root:myGlobals:Protocols:gProtoStr = ""
	endif

	return (0)

End

//when "sides" popup is "popped", the value associated with the SIDE
//keyword is updated in the global string
//then the angles are redrawn based on the choice
Function SidesPopMenuProc(string ctrlName, variable popNum, string popStr) : PopupMenuControl

	ControlInfo/W=Average_Panel sides
	string side    = S_Value
	SVAR   tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string newStr  = ReplaceStringByKey("SIDE", tempStr, side, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()

End

//when the "type of average" popup is "popped", the value associated with the AVTYPE
//keyword is updated in the global string
//then the angles are redrawn based on the choice
//
// changes the title of the "do" button to "Save" if ASCII is chosen
// disables all setVars (ASCII cases), then selectively enables them as choice dictates
Function AvTypePopMenuProc(string ctrlName, variable popNum, string popStr) : PopupMenuControl

	ControlInfo/W=Average_Panel av_choice
	string choice  = S_Value
	SVAR   tempStr = root:myGlobals:Drawing:gDrawInfoStr

	DisableUnusedParameters(choice)

	strswitch(choice) // string switch
		case "2D ASCII": // execute if case matches expression, 
		case "QxQy ASCII":  
		case "2D_NXcanSAS":
			string/G root:myGlobals:Drawing:gDrawInfoStr = ReplaceStringByKey("AVTYPE", tempStr, choice, "=", ";")
			Button P_DoAvg, title="Save ASCII"
			break
		case "Circular":  
		case "Sector":  
		case "Sector_PlusMinus":  
		case "Rectangular":  
		case "Annular":
			string/G root:myGlobals:Drawing:gDrawInfoStr = ReplaceStringByKey("AVTYPE", tempStr, choice, "=", ";")
			Button P_DoAvg, title="Do Average"
			//redraw the angles
			MasterAngleDraw()
			break
		default: // optional default expression executed
			Abort "no case matches from averagePanel type popup" // when no case matches
	endswitch
	return (0)
End

// disables all of the type-specific buttons and popups on the average_Panel
// currently ununsed, ans the logic is quite slippery
Function DisableUnusedParameters(string choice)

	variable yes = 1
	variable no  = 0

	strswitch(choice) // string switch
		case "2D ASCII":  
		case "QxQy ASCII":  
		case "2D_NXcanSAS":  
		case "Circular": //disable everything for these three choices
			SetVariable Phi_p, disable=yes
			SetVariable Qctr_p, disable=yes
			SetVariable Qdelta_p, disable=yes
			SetVariable DPhi_p, disable=yes
			SetVariable width_p, disable=yes
			popupmenu sides, disable=yes
			break
		case "Sector":  
		case "Sector_PlusMinus":
			SetVariable Phi_p, disable=no
			SetVariable Qctr_p, disable=yes
			SetVariable Qdelta_p, disable=yes
			SetVariable DPhi_p, disable=no
			SetVariable width_p, disable=yes
			popupmenu sides, disable=no
			break
		case "Rectangular":
			SetVariable Phi_p, disable=no
			SetVariable Qctr_p, disable=yes
			SetVariable Qdelta_p, disable=yes
			SetVariable DPhi_p, disable=yes
			SetVariable width_p, disable=no
			popupmenu sides, disable=no
			break
		case "Annular":
			SetVariable Phi_p, disable=yes
			SetVariable Qctr_p, disable=no
			SetVariable Qdelta_p, disable=no
			SetVariable DPhi_p, disable=yes
			SetVariable width_p, disable=yes
			popupmenu sides, disable=yes
			break
		default: // optional default expression executed
			Abort "no case matches from averagePanel type popup" // when no case matches
	endswitch
	return (0)
End

//draws the Panel, with defaults for standard circular average
Window Average_Panel()
	PauseUpdate; Silent 1 // building window...
	NewPanel/W=(638, 65, 933, 347)/K=1
	ModifyPanel cbRGB=(65535, 49151, 62258), fixedSize=1
	SetDrawLayer UserBack
	//	DrawText 192,121,"(pixels)"
	//	DrawText 47,190,"(pixels)"
	GroupBox ann, pos={148, 44}, size={143, 84}, title="Annular"
	GroupBox rect, pos={7, 133}, size={134, 71}, title="Rectangular"
	GroupBox sect, pos={148, 133}, size={143, 71}, title="Sector"
	GroupBox sect_rect, pos={7, 44}, size={134, 84}, title="Sector/Rectangular"
	PopupMenu av_choice, pos={61, 7}, size={144, 20}, proc=AvTypePopMenuProc, title="AverageType"
	PopupMenu av_choice, help={"Select the type of average to perform, then make the required selections below and click \"DoAverage\" to plot the results"}
	PopupMenu av_choice, mode=1, popvalue="Circular", value=#"\"Circular;Sector;Annular;Rectangular;2D_NXcanSAS;2D ASCII;QxQy ASCII;Sector_PlusMinus;\""
	Button ave_help, pos={260, 7}, size={25, 20}, proc=ShowAvePanelHelp, title="?"
	Button ave_help, help={"Show the help file for averaging options"}
	Button ave_done, pos={199, 245}, size={50, 20}, proc=AveDoneButtonProc, title="Done"
	Button ave_done, help={"When done, this will close the panel. The panel may be recalled at any time from the SANS menu."}
	Button ClearLines, pos={198, 212}, size={50, 20}, proc=ClearLinesButtonProc, title="Clear"
	Button ClearLines, help={"This will clear the drawn lines from the SANS data"}
	SetVariable Phi_p, pos={32, 92}, size={70, 15}, proc=PhiSetVarProc, title="Phi"
	SetVariable Phi_p, help={"Enter the azimuthal angle phi (-90,90). Phi is defined CCW from zero at the positive x-axis. The phi line will be drawn in light green."}
	SetVariable Phi_p, limits={-90, 90, 1}, value=root:myGlobals:Drawing:gDrawPhi
	SetVariable Qctr_p, pos={155, 66}, size={130, 15}, proc=QctrSetVarProc, title="Q-center"
	SetVariable Qctr_p, help={"Enter the q-center of the annular region (1/A). The circle will be drawn in light green."}
	SetVariable Qctr_p, limits={1e-05, 0.7, 0.001}, value=root:myGlobals:Drawing:gDrawQCtr
	SetVariable QDelta_p, pos={155, 90}, size={130, 15}, proc=QDeltaSetVarProc, title="Q Delta (+/- Q)"
	SetVariable QDelta_p, help={"Enter the total width of the annulus in pixels. The bounding circles will be draw in blue."}
	SetVariable QDelta_p, limits={1e-05, 0.7, 0.001}, value=root:myGlobals:Drawing:gDrawQDelta
	SetVariable DPhi_p, pos={166, 154}, size={110, 15}, proc=DeltaPhiSetVarProc, title="Delta Phi"
	SetVariable DPhi_p, help={"Enter the +/- range (0,45) of azimuthal angles to be included in the average.  The bounding angles will be drawin in blue."}
	SetVariable DPhi_p, limits={0, 90, 1}, value=root:myGlobals:Drawing:gDrawDPhi
	SetVariable width_p, pos={15, 155}, size={115, 15}, proc=WidthSetVarProc, title="Width (pixels)"
	SetVariable width_p, help={"Enter the total width of the rectangular section in pixels. The bounding lines will be drawn in blue."}
	SetVariable width_p, limits={1, 130, 1}, value=root:myGlobals:Drawing:gDrawWidth
	Button P_DoAvg, pos={30, 247}, size={90, 20}, proc=Panel_DoAverageButtonProc, title="Do Average"
	Button P_DoAvg, help={"This will do the averaging of the displayed dta based on the selection in this panel. The data will automatically be plotted. It will not be saved to disk unless the \"Save to disk\" box is checked BEFORE the average is performed."}
	PopupMenu sides, pos={16, 67}, size={97, 20}, proc=SidesPopMenuProc, title="Sides ?"
	PopupMenu sides, help={"Select the regions of the detector to include in the averaging. \"right\" denotes right or above the beamstop."}
	PopupMenu sides, mode=1, popvalue="both", value=#"\"both;left;right\""
	CheckBox saveCheck, pos={14, 215}, size={102, 14}, title="Save file to disk?"
	CheckBox saveCheck, help={"If checked, the averaged data will be saved to disk. The user will always be prompted for the filename."}
	CheckBox saveCheck, value=0
EndMacro

Function ShowAvePanelHelp(string ctrlName) : ButtonControl

	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Average Options]"
	if(V_flag != 0)
		DoAlert 0, "The SANS Data Reduction Tutorial Help file could not be found"
	endif
End

//Sets global key=value for drawing phi-line on graph
//and redraws the angles
Function PhiSetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	ControlInfo/W=Average_Panel phi_p
	variable phi     = V_Value
	SVAR     tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string   newStr  = ReplaceNumberByKey("PHI", tempStr, phi, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()
End

//draws all of the lines specified by the global keyword string
//clears the old lines, and parses the string
Function MasterAngleDraw()

	//takes the global gDrawInfoStr and Parses it to determine what to redraw on the graph

	//first clear the old draw Layer
	//	DoWindow/F SANS_Data
	if(WinType("SANS_Data") == 0)
		Abort "No SANS data. Use'Display Raw Data' to display a 2D data file"
	endif
	SetDrawLayer/W=SANS_Data/K UserFront
	SetDrawLayer/W=SANS_Data UserFront

	//what average type are we drawing for?
	SVAR/Z drawStr = root:myGlobals:Drawing:gDrawInfoStr
	if(SVAR_Exists(drawStr) == 0)
		Execute "InitializeAveragePanel()"
		SVAR drawStr = root:myGlobals:Drawing:gDrawInfoStr
	endif

	//get the beam center from the currently displayed data type
	SVAR type = root:myGlobals:gDataDisplayType

	variable x0, y0, x1, y1

	x0 = getDet_beam_center_x(type) - 1 //convert to [0,127] from (1,128) detector
	y0 = getDet_beam_center_y(type) - 1

	//right, left, or both halves?
	//what type of average?
	string   side    = StringByKey("SIDE", drawStr, "=", ";")
	string   av_type = StringByKey("AVTYPE", drawStr, "=", ";")
	variable phi     = NumberByKey("PHI", drawStr, "=", ";")
	variable dphi    = NumberByKey("DPHI", drawStr, "=", ";")
	variable width   = NumberByKey("WIDTH", drawStr, "=", ";")

	variable delx, dely, slope, intcp, rr, gg, bb, thick
	rr    = 0
	gg    = 0
	bb    = 0
	thick = 2

	//if circular average, just get out
	if(cmpstr(av_type, "Circular") == 0)
		//clear the drawing

		//go back to the average panel
		//		DoWindow/F Average_Panel

		return 0 //exit the Draw routine
	endif

	//handle sector-type and annular type averages differently
	if(cmpstr(av_type, "Annular") == 0)
		//do the annular drawing
		//need to go from q-value to y-axis value (since x will shift a lot)
		//and make sure that the (radius) is allowable for drawing
		variable sdd = getDet_Distance(type) // return value is in [cm]
		variable lam = getWavelength(type)

		//find the radius (from the y-direction)
		variable QCtr   = NumberByKey("QCENTER", drawStr, "=", ";")
		variable QDelta = NumberByKey("QDELTA", drawStr, "=", ";")
		variable thetay, dy, pixelSize

		// dQStep is found by taking the q-width of one tube in the x-direction
		// == delQ/pixel
		SetDeltaQ(type)

		NVAR dqStep = $("root:Packages:NIST:" + type + ":entry:instrument:detector:gDelQ")

		//TODO -- verify the units!!
		pixelSize = getDet_x_pixel_size(type) / 10 //this is ONLY the x-direction, converted to cm
		thetay    = 2 * asin(Qctr * lam / 4 / Pi)
		dy        = sdd / pixelSize * tan(thetay)  //pixelSize is to convert from cm on detector to pixel

		rr = 0
		gg = 50000
		bb = 0
		DrawACircle(x0, y0, dy, rr, gg, bb, thick)

		//then do the +/- Qdelta rings
		//QDelta is NOW 1/2 the width of the annulus, NOW in units of q, so apprioximate as pixels
		variable tmpQ = QDelta

		QDelta = tmpQ / dqStep // q/(q/pix) == pixels (approximately)

		rr = 0
		gg = 0
		bb = 50000
		DrawACircle(x0, y0, dy + (QDelta), rr, gg, bb, thick)
		// then the  (- delta) ring
		DrawACircle(x0, y0, dy - (QDelta), rr, gg, bb, thick)

		//go back to the average panel
		//		DoWindow/F Average_Panel

		return 0 //exit the Draw routine
	endif

	//else sector or rectangular - draw the lines

	//if sector, sector_plusminus, or rectangular, draw the phi line (on the desired side)
	if((cmpstr(av_type, "Sector") == 0) || (cmpstr(av_type, "Rectangular") == 0) || (cmpstr(av_type, "Sector_PlusMinus") == 0))
		if((cmpstr(side, "left") == 0) || (cmpstr(side, "both") == 0))
			//draw the phi line on the left side
			//make sure x1,y1 is on the edge of the graph
			rr = 0
			gg = 65535
			bb = 0
			DrawALineLeft(x0, y0, phi, rr, gg, bb, thick)
		endif
		if((cmpstr(side, "right") == 0) || (cmpstr(side, "both") == 0))
			//Draw the phi line on the right side
			//make sure x1,y1 is on the edge of the graph
			rr = 0
			gg = 65535
			bb = 0
			DrawALineRight(x0, y0, phi, rr, gg, bb, thick)
		endif
	endif

	//if Sector, draw the +/- dphi lines
	if(cmpstr(av_type, "Sector") == 0 || cmpstr(av_type, "Sector_PlusMinus") == 0)
		if((cmpstr(side, "left") == 0) || (cmpstr(side, "both") == 0))
			//draw the deltaPhi lines +/- lines
			if(dphi != 0)
				rr = 0
				gg = 0
				bb = 50000
				if(phi < 0)
					DrawALineLeft(x0, y0, phi + dphi, rr, gg, bb, thick)
					if((abs(phi) + dphi) <= 90)
						DrawALineLeft(x0, y0, phi - dphi, rr, gg, bb, thick)
					else
						DrawALineRight(x0, y0, phi - dphi, rr, gg, bb, thick)
					endif
				else
					if((phi + dphi) > 90)
						DrawALineRight(x0, y0, phi + dphi, rr, gg, bb, thick)
					else
						DrawALineLeft(x0, y0, phi + dphi, rr, gg, bb, thick)
					endif
					DrawALineLeft(x0, y0, phi - dphi, rr, gg, bb, thick)
				endif //phi<0
			endif //dphi !=0
		endif //left or both
		if((cmpstr(side, "right") == 0) || (cmpstr(side, "both") == 0))
			//draw the deltaPhi lines +/- lines
			if(dphi != 0)
				rr = 0
				gg = 0
				bb = 50000
				if(phi < 0)
					DrawALineRight(x0, y0, phi + dphi, rr, gg, bb, thick)
					if((abs(phi) + dphi) <= 90)
						DrawALineRight(x0, y0, phi - dphi, rr, gg, bb, thick)
					else
						DrawALineLeft(x0, y0, phi - dphi, rr, gg, bb, thick)
					endif
				else
					if((phi + dphi) > 90)
						DrawALineLeft(x0, y0, phi + dphi, rr, gg, bb, thick)
					else
						DrawALineRight(x0, y0, phi + dphi, rr, gg, bb, thick)
					endif
					DrawALineRight(x0, y0, phi - dphi, rr, gg, bb, thick)
				endif //phi<0
			endif //dphi !=0
		endif //right or both
	endif //if sector, draw dphi lines

	//if rectangular, draw the parallel rectangle lines
	variable xOffset, yOffset, betaAng
	if(cmpstr(av_type, "Rectangular") == 0)
		betaAng = (90 - phi) * Pi / 180
		xOffset = (width / 2) * cos(betaAng) //need angle in radians
		yOffset = (width / 2) * sin(betaAng)
		if(phi == 0)
			xOffset = 0
			yOffset = width / 2
		endif
		if((cmpstr(side, "left") == 0) || (cmpstr(side, "both") == 0))
			rr = 0
			gg = 0
			bb = 50000
			DrawALineLeft(x0 - xOffset, y0 + yOffset, phi, rr, gg, bb, thick)
			DrawALineLeft(x0 + xOffset, y0 - yOffset, phi, rr, gg, bb, thick)
		endif
		if((cmpstr(side, "right") == 0) || (cmpstr(side, "both") == 0))
			rr = 0
			gg = 0
			bb = 50000
			DrawALineRight(x0 - xOffset, y0 + yOffset, phi, rr, gg, bb, thick)
			DrawALineRight(x0 + xOffset, y0 - yOffset, phi, rr, gg, bb, thick)
		endif
	endif

	//go back to the average panel
	//	DoWindow/F Average_Panel

	return 0
End

//given beamcenter (x0,y0) and equation of line [slope and intercept]
//return the point x1 where line leaves the detector image [0,127] on the left side
Function FindXLeft(variable x0, variable y0, variable slope, variable intcp)

	variable yat0
	variable x1 = 0
	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY

	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	if(slope == 0)
		x1 = 0
		return x1
	endif
	if((slope == Inf) || (slope == -Inf))
		x1 = x0
		return x1
	endif
	//else we have to do some math
	//at x=0, what is the y-axis value?
	yat0 = trunc(intcp)
	if((yat0 >= 0) && (yat0 <= (pixelsY - 1)))
		//crosses y axis, so x1 = 0
		x1 = 0
	else
		//need crossing value
		if(slope > 0)
			x1 = trunc((0 - intcp) / slope)
		else
			x1 = trunc((pixelsY - 1 - intcp) / slope)
		endif
	endif
	return x1
End

//given beamcenter (x0,y0) and equation of line [slope and intercept]
//return the point y1 where line leaves the detector image [0,127] on the left side
Function FindYLeft(variable x0, variable y0, variable slope, variable intcp)

	variable yat0
	variable y1 = 0

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	if(slope == 0)
		y1 = y0
		return y1
	endif
	if(slope == Inf)
		y1 = 0
		return y1
	endif
	if(slope == -Inf)
		y1 = pixelsY - 1
		return y1
	endif

	//else we have to do some math
	//at x=0, what is the y-axis value?
	yat0 = trunc(intcp)
	if((yat0 >= 0) && (yat0 <= (pixelsY - 1)))
		//crosses y axis, so return y1
		y1 = yat0
	else
		//need crossing value
		if(yat0 < 0)
			y1 = 0
		else
			y1 = pixelsY - 1
		endif
	endif
	return y1
End

//given beamcenter (x0,y0) and equation of line [slope and intercept]
//return the point x1 where line leaves the detector image [0,127] on the right side
Function FindXRight(variable x0, variable y0, variable slope, variable intcp)

	variable yat127
	variable x1 = 0

	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	if(slope == 0)
		x1 = pixelsX - 1
		return x1
	endif
	if((slope == Inf) || (slope == -Inf))
		x1 = x0
		return x1
	endif
	//else we have to do some math
	//at x=127, what is the y-axis value?
	yat127 = trunc(slope * (pixelsX - 1) + intcp)
	if((yat127 >= 0) && (yat127 <= (pixelsY - 1)))
		//crosses y=127 edge, so x1 = 127
		x1 = pixelsX - 1
	else
		//need crossing value
		if(slope > 0)
			x1 = trunc((pixelsX - 1 - intcp) / slope)
		else
			x1 = trunc((0 - intcp) / slope)
		endif
	endif
	return x1
End

//given beamcenter (x0,y0) and equation of line [slope and intercept]
//return the point y1 where line leaves the detector image [0,127] on the right side
Function FindYRight(variable x0, variable y0, variable slope, variable intcp)

	variable yat127
	variable y1 = 0
	//	NVAR pixelsX = root:myGlobals:gNPixelsX
	//	NVAR pixelsY = root:myGlobals:gNPixelsY
	SVAR     type    = root:myGlobals:gDataDisplayType
	variable pixelsX = getDet_pixel_num_x(type)
	variable pixelsY = getDet_pixel_num_y(type)

	if(slope == 0)
		y1 = y0
		return y1
	endif
	if(slope == Inf)
		y1 = pixelsY - 1
		return y1
	endif
	if(slope == -Inf)
		y1 = 0
		return y1
	endif

	//else we have to do some math
	//at x=127, what is the y-axis value?
	yat127 = trunc(slope * (pixelsX - 1) + intcp)
	if((yat127 >= 0) && (yat127 <= (pixelsY - 1)))
		//crosses y axis, so return y1
		y1 = yat127
	else
		//need crossing value
		if(yat127 < 0)
			y1 = 0
		else
			y1 = pixelsY - 1
		endif
	endif
	return y1
End

//draws a circle of radius rad, centered at (x0,y0)
//line thickness is thick
// color is (rr,gg,bb)
Function DrawACircle(variable x0, variable y0, variable rad, variable rr, variable gg, variable bb, variable thick)

	//	DoWindow/F SANS_Data
	SetDrawLayer/W=SANS_Data UserFront
	SetDrawEnv/W=SANS_Data xcoord=bottom, ycoord=left, linefgc=(rr, gg, bb), linethick=(thick), fillpat=0
	DrawOval/W=SANS_Data x0 - rad, y0 + rad, x0 + rad, y0 - rad //left,top,right,bottom
End

//draws a line to the left of the beamcenter (x0,y0)
//angle is phi
//thickness is thick
//color is (rr,gg,bb)
// function determines where the line will cross the edge of the image, and stops the line there.
Function DrawALineLeft(variable x0, variable y0, variable phi, variable rr, variable gg, variable bb, variable thick)

	variable slope, intcp, x1, y1

	slope = tan(phi * Pi / 180) //need arg in radians, not degrees
	if(phi == 90)
		slope = Inf
	endif
	if(phi == -90)
		slope = -Inf
	endif
	intcp = y0 - slope * x0
	x1    = FindXLeft(x0, y0, slope, intcp)
	y1    = FindYLeft(x0, y0, slope, intcp)

	//	DoWindow/F SANS_Data
	SetDrawLayer/W=SANS_Data UserFront
	SetDrawEnv/W=SANS_Data xcoord=bottom, ycoord=left, linefgc=(rr, gg, bb), linethick=(thick)
	DrawLine/W=SANS_Data x0, y0, x1, y1
End

//draws a line to the right of the beamcenter (x0,y0)
//angle is phi
//thickness is thick
//color is (rr,gg,bb)
// function determines where the line will cross the edge of the image, and stops the line there.
Function DrawALineRight(variable x0, variable y0, variable phi, variable rr, variable gg, variable bb, variable thick)

	variable slope, intcp, x1, y1

	slope = tan(phi * Pi / 180) //need arg in radians, not degrees
	if(phi == 90)
		slope = Inf
	endif
	if(phi == -90)
		slope = -Inf
	endif
	intcp = y0 - slope * x0
	x1    = FindXRight(x0, y0, slope, intcp)
	y1    = FindYRight(x0, y0, slope, intcp)

	//	DoWindow/F SANS_Data
	SetDrawLayer/W=SANS_Data UserFront
	SetDrawEnv/W=SANS_Data xcoord=bottom, ycoord=left, linefgc=(rr, gg, bb), linethick=(thick)
	DrawLine/W=SANS_Data x0, y0, x1, y1
End

//reads the value from the panel and updates the global string
// redraws the appropriate line on the image
Function DeltaPhiSetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	ControlInfo/W=Average_Panel dphi_p
	variable dphi    = V_Value
	SVAR     tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string   newStr  = ReplaceNumberByKey("DPHI", tempStr, dphi, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()
End

//reads the value from the panel and updates the global string
// redraws the appropriate line on the image
Function QDeltaSetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	ControlInfo/W=Average_Panel QDelta_p
	variable dq      = V_Value
	SVAR     tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string   newStr  = ReplaceNumberByKey("QDELTA", tempStr, dq, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()
End

//reads the value from the panel and updates the global string
// redraws the appropriate line on the image
Function QctrSetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	ControlInfo/W=Average_Panel QCtr_p
	variable ctr     = V_Value
	SVAR     tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string   newStr  = ReplaceNumberByKey("QCENTER", tempStr, ctr, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()
End

//reads the value from the panel and updates the global string
// redraws the appropriate line on the image
Function WidthSetVarProc(string ctrlName, variable varNum, string varStr, string varName) : SetVariableControl

	ControlInfo/W=Average_Panel width_p
	variable val     = V_Value
	SVAR     tempStr = root:myGlobals:Drawing:gDrawInfoStr
	string   newStr  = ReplaceNumberByKey("WIDTH", tempStr, val, "=", ";")

	string/G root:myGlobals:Drawing:gDrawInfoStr = newStr

	//redraw the angles
	MasterAngleDraw()
End

//function is called directly by averaging routines to display the averaged data
//copies the newly averaged data (finds the data folder from the parameter waves)
//the the copied data can be rescaled without disturbing the original data
//
// brings the plot_1d to the front
// if no window, create the folder and globals
// update the data
//
//there is a separate function for annular averages (I vs phi)
Function Avg_1D_Graph(WAVE aveint, WAVE qval, WAVE sigave)

	if(!DataFolderExists("root:myGlobals:plot_1d"))
		Init_Plot1d()
	endif

	//	String curPath = GetWavesDataFolder(aveint,1)
	string CurPath = "root:myGlobals:Plot_1D:"

	Duplicate/O aveint, $(curPath + "yAxisWave")
	Duplicate/O sigave, $(curPath + "yErrWave")
	Duplicate/O qval, $(curPath + "xAxisWave")
	WAVE yAxisWave = $(curPath + "yAxisWave")
	WAVE xAxisWave = $(curPath + "xAxisWave")
	WAVE yErrWave  = $(curPath + "yErrWave")

	variable/G root:myGlobals:Plot_1d:isPhiAve = 0 //0 signifies (normal) x=qvals
	//make a completely new graph
	Draw_Plot1D(xAxisWave, yAxisWave, YErrWave)

	return (0)
End

//function is called directly by averaging routines to display the averaged data
//copies the newly averaged data (finds the data folder from the parameter waves)
//the the copied data can be rescaled without disturbing the original data
//
// brings the plot_1d to the front
// if no window, create the folder and globals
// update the data
//
Function Ann_1D_Graph(WAVE aveint, WAVE phival, WAVE sigave)

	if(!DataFolderExists("root:myGlobals:plot_1d"))
		Init_Plot1d()
	endif
	//	String curPath = GetWavesDataFolder(aveint,1)
	string CurPath = "root:myGlobals:Plot_1D:"

	Duplicate/O aveint, $(curPath + "yAxisWave")
	Duplicate/O sigave, $(curPath + "yErrWave")
	Duplicate/O phival, $(curPath + "xAxisWave")
	WAVE yAxisWave = $(curPath + "yAxisWave")
	WAVE xAxisWave = $(curPath + "xAxisWave")
	WAVE yErrWave  = $(curPath + "yErrWave")

	variable/G root:myGlobals:Plot_1d:isPhiAve = 1 //1 signifies x=phival
	//make a completely new graph
	Draw_Plot1D(xAxisWave, yAxisWave, YErrWave)

	return (0)
End

//initializes the scaling exponents and x-axis flag used in the control bar of the
//plot_1d graph
// ! keep the user-defined values when re-creating the graph, so don't re-initialize the globals
Function Init_Plot1d()

	NewDataFolder/O/S root:myGlobals:Plot_1d
	NVAR/Z gExpA  = gExpA
	NVAR/Z gExpB  = gExpB
	NVAR/Z gExpC  = gExpC
	NVAR/Z gXMode = gXMode
	NVAR/Z gYMode = gYMode
	if(!NVAR_Exists(gExpA))
		variable/G gExpA = 1
	endif
	if(!NVAR_Exists(gExpB))
		variable/G gExpB = 1
	endif
	if(!NVAR_Exists(gExpC))
		variable/G gExpC = 1
	endif
	//keep preferences of the display mode (axis scaling)
	if(!NVAR_Exists(gXMode))
		variable/G gXMode = 1
	endif
	if(!NVAR_Exists(gYMode))
		variable/G gYMode = 1
	endif
	variable/G isPhiAve = 0 //0= vs Q, 1= vs phi, alway set properly as needed by the Avg_ or Ann_1D_Graph()
	SetDataFolder root:
End

//function responsible for drawing the 1D plot, given the three necessary waves
// x-axis label is determined from global "isPhiAve" switch
//
// plot type is recalled through globals
//
Function Draw_Plot1D(WAVE xw, WAVE yw, WAVE ew)

	if(!DataFolderExists("root:myGlobals:plot_1d"))
		Init_Plot1d()
	endif
	DoWindow/F Plot_1d
	if(V_flag == 1)
		//do nothing
	else
		Display/W=(476, 96, 850, 429)/K=1 yw vs xw
		DoWindow/C Plot_1d
		DoWindow/T Plot_1d, "Averaged Data"
		ModifyGraph marker=19
		ModifyGraph mode=3, msize=2, rgb=(65535, 0, 0)
		//
		string list  = TraceNameList("", ";", 1)
		string yname = StringFromList(0, list, ";")
		ErrorBars/T=0 $yname, Y, wave=(ew, ew)
		ModifyGraph grid=1
		ModifyGraph log=0
		ModifyGraph mirror=2
		ModifyGraph standoff=0
		ModifyGraph tickUnit=1
		ControlBar 70
		PopupMenu ymodel, pos={16, 5}, size={71, 20}, title="y-axis"
		PopupMenu ymodel, help={"This popup selects how the y-axis will be linearized based on the chosen data"}
		PopupMenu ymodel, value=#"\"I;log(I);ln(I);1/I;I^a;Iq^a;I^a q^b;1/sqrt(I);ln(Iq);ln(Iq^2)\""
		PopupMenu ymodel, mode=NumVarOrDefault("root:myGlobals:Plot_1d:gYMode", 1), proc=YMode_PopMenuProc
		Button Rescale, pos={281, 4}, size={70, 20}, proc=Rescale_Plot_1D_ButtonProc, title="Rescale"
		Button Rescale, help={"Rescale the x and y-axes of the data"}, disable=1
		Button AllQ, pos={281, 28}, size={70, 20}, proc=AllQ_Plot_1D_ButtonProc, title="All Q"
		Button AllQ, help={"Show the full q-range of the dataset"}
		SetVariable expa, pos={28, 28}, size={80, 15}, title="pow \"a\""
		SetVariable expa, help={"This sets the exponent \"a\" for some y-axis formats. The value is ignored if the model does not use an adjustable exponent"}
		SetVariable expa, limits={-2, 10, 0}, value=root:myGlobals:Plot_1d:gExpA
		SetVariable expb, pos={27, 46}, size={80, 15}, title="pow \"b\""
		SetVariable expb, help={"This sets the exponent \"b\" for some x-axis formats. The value is ignored if the model does not use an adjustable exponent"}
		SetVariable expb, limits={0, 10, 0}, value=root:myGlobals:Plot_1d:gExpB
		PopupMenu xmodel, pos={150, 5}, size={74, 20}, title="x-axis"
		PopupMenu xmodel, help={"This popup selects how the x-axis will be linearized given the chosen data"}
		PopupMenu xmodel, value=#"\"q;log(q);q^2;q^c\""
		PopupMenu xmodel, mode=NumVarOrDefault("root:myGlobals:Plot_1d:gXMode", 1), proc=XMode_PopMenuProc
		SetVariable expc, pos={167, 28}, size={80, 15}, title="pow \"c\""
		SetVariable expc, help={"This sets the exponent \"c\" for some x-axis formats. The value is ignored if the model does not use \"c\" as an adjustable exponent"}
		SetVariable expc, limits={-10, 10, 0}, value=root:myGlobals:Plot_1d:gExpC

	endif
	NVAR isPhiAve = root:myGlobals:Plot_1d:isPhiAve //0 signifies (normal) x=qvals
	Label left, "I(q)"
	if(isPhiAve)
		Label bottom, "Angle (deg)"
	else
		SVAR/Z angst = root:Packages:NIST:gAngstStr
		Label bottom, "q (" + angst + "\\S-1\\M)"
	endif
	//force a rescale to get something other than I vs. q
	Rescale_Plot_1D_ButtonProc("")
End

//function to set the popItem (mode) of the graph, to re-create the graph based on user preferences
Function YMode_PopMenuProc(string ctrlName, variable popNum, string popStr) : PopupMenuControl

	variable/G root:myGlobals:Plot_1d:gYMode = popNum
	Rescale_Plot_1D_ButtonProc("")
End

//function to set the popItem (mode) of the graph, to re-create the graph based on user preferences
Function XMode_PopMenuProc(string ctrlName, variable popNum, string popStr) : PopupMenuControl

	variable/G root:myGlobals:Plot_1d:gXMode = popNum
	Rescale_Plot_1D_ButtonProc("")
End

//function to restore the graph axes to full scale, undoing any zooming
Function AllQ_Plot_1D_ButtonProc(string ctrlName) : ButtonControl

	DoWindow/F Plot_1d
	SetAxis/A
End

//function to rescale the axes of the graph as selected from the popups and the
// entered values of the exponents
//** assumes the current waves are unknown, so it goes and gets a "fresh" copy from
//the data folder specified by the waves on the graph, which is the same folder that
//contains the "fresh" copy of the 1D data
//
// for log(10) scaling, simply modify the axes, not the data - gives better plots
//
Function Rescale_Plot_1D_ButtonProc(string ctrlName) : ButtonControl

	DoWindow/F Plot_1d
	//Scaling exponents and background value
	variable pow_a, pow_b, pow_c
	ControlInfo expa
	pow_a = V_value
	ControlInfo expb
	pow_b = V_value
	ControlInfo expc
	pow_c = V_value

	//check for physical limits on exponent values, abort if bad values found
	if((pow_a < -2) || (pow_a > 10))
		Abort "Exponent a must be in the range (-2,10)"
	endif
	if((pow_b < 0) || (pow_b > 10))
		Abort "Exponent b must be in the range (0,10)"
	endif
	//if q^c is the x-scaling, c must be be within limits and also non-zero
	ControlInfo xModel
	if(cmpstr("q^c", S_Value) == 0)
		if(pow_c == 0)
			Abort "Exponent c must be non-zero, q^0 = 1"
		endif
		if((pow_c < -10) || (pow_c > 10))
			Abort "Exponent c must be in the range (-10,10)"
		endif
	endif //check q^c exponent

	// get the current experimental q, I, and std dev. waves

	//!! get the wave path from the window and construct the necessary wave
	//references to the unmodified, averaged data (qval, aveint)
	//and use these to modify the (xAxisWave,YAxisWave) that are on the graph
	string dfSav = GetDataFolder(1)
	//String curPath = GetWavesDataFolder(WaveRefIndexed("",0,1),1)		//path for the first y-wave on the graph
	SVAR curFolder = root:myGlobals:gDataDisplayType

	//	SetDataFolder curPath
	//get the untarnished data, so we can rescale it freshly here
	WAVE yw = $("root:Packages:NIST:" + curFolder + ":aveint")
	WAVE ew = $("root:Packages:NIST:" + curFolder + ":sigave")
	//get the correct x values
	NVAR isPhiAve = root:myGlobals:Plot_1d:isPhiAve //0 signifies (normal) x=qvals
	if(isPhiAve)
		//x is angle
		WAVE xw = $("root:Packages:NIST:" + curFolder + ":phival")
	else
		//x is q-values
		WAVE xw = $("root:Packages:NIST:" + curFolder + ":qval")
	endif
	WAVE yAxisWave = root:myGlobals:Plot_1d:yAxisWave //refs to waves to be modified, hard-wired positions
	WAVE xAxisWave = root:myGlobals:Plot_1d:xAxisWave
	WAVE yErrWave  = root:myGlobals:Plot_1d:yErrWave

	//variables set for each model to control look of graph
	string xlabel, ylabel, xstr, ystr
	variable logLeft   = 0
	variable logBottom = 0
	//check for proper y-scaling selection, make the necessary waves
	ControlInfo yModel
	ystr = S_Value
	do
		if(cmpstr("I", S_Value) == 0)
			SetScale d, 0, 0, "1/cm", yAxisWave
			yErrWave  = ew
			yAxisWave = yw
			ylabel    = "I(q)"
			break
		endif
		if(cmpstr("ln(I)", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew / yw
			yAxisWave = ln(yw)
			ylabel    = "ln(I)"
			break
		endif
		if(cmpstr("log(I)", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yAxisWave = yw
			yErrWave  = ew
			logLeft   = 1 //scale the axis, not the wave
			ylabel    = "I(q)"
			//			yErrWave = ew/(2.30*yw)
			//			yAxisWave = log(yw)
			//			ylabel = "log(I)"
			break
		endif
		if(cmpstr("1/I", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew / yw^2
			yAxisWave = 1 / yw
			ylabel    = "1/I"
			break
		endif
		if(cmpstr("I^a", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew * abs(pow_a * (yw^(pow_a - 1)))
			yAxisWave = yw^pow_a
			ylabel    = "I^" + num2str(pow_a)
			break
		endif
		if(cmpstr("Iq^a", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew * xw^pow_a
			yAxisWave = yw * xw^pow_a
			ylabel    = "I*q^" + num2str(pow_a)
			break
		endif
		if(cmpstr("I^a q^b", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew * abs(pow_a * (yw^(pow_a - 1))) * xw^pow_b
			yAxisWave = yw^pow_a * xw^pow_b
			ylabel    = "I^" + num2str(pow_a) + "q^" + num2str(pow_b)
			break
		endif
		if(cmpstr("1/sqrt(I)", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = 0.5 * ew * yw^(-1.5)
			yAxisWave = 1 / sqrt(yw)
			ylabel    = "1/sqrt(I)"
			break
		endif
		if(cmpstr("ln(Iq)", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew / yw
			yAxisWave = ln(xw * yw)
			ylabel    = "ln(q*I)"
			break
		endif
		if(cmpstr("ln(Iq^2)", S_Value) == 0)
			SetScale d, 0, 0, "", yAxisWave
			yErrWave  = ew / yw
			yAxisWave = ln(xw * xw * yw)
			ylabel    = "ln(I*q^2)"
			break
		endif
		//more ifs for each case as they are added

		// if selection not found, abort
		DoAlert 0, "Y-axis scaling incorrect. Aborting"
		Abort
	while(0) //end of "case" statement for y-axis scaling

	//check for proper x-scaling selection
	SVAR/Z angst = root:Packages:NIST:gAngstStr
	string dum

	ControlInfo xModel
	xstr = S_Value
	do
		if(cmpstr("q", S_Value) == 0)
			SetScale d, 0, 0, "", xAxisWave
			xAxisWave = xw
			if(isPhiAve)
				xlabel = "Angle (deg)"
			else
				xlabel = "q (" + angst + "\\S-1\\M)"
			endif
			break
		endif
		if(cmpstr("q^2", S_Value) == 0)
			SetScale d, 0, 0, "", xAxisWave
			xAxisWave = xw * xw
			if(isPhiAve)
				xlabel = "(Angle (deg) )^2"
			else
				xlabel = "q^2 (" + angst + "\\S-2\\M)"
			endif
			break
		endif
		if(cmpstr("log(q)", S_Value) == 0)
			SetScale d, 0, 0, "", xAxisWave
			xAxisWave = xw //scale the axis, not the wave
			//xAxisWave = log(xw)
			logBottom = 1
			if(isPhiAve)
				//xlabel="log(Angle (deg))"
				xlabel = "Angle (deg)"
			else
				//xlabel = "log(q)"
				xlabel = "q (" + angst + "\\S-1\\M)"
			endif
			break
		endif
		if(cmpstr("q^c", S_Value) == 0)
			SetScale d, 0, 0, "", xAxisWave
			xAxisWave = xw^pow_c
			dum       = num2str(pow_c)
			if(isPhiAve)
				xlabel = "Angle^" + dum
			else
				xlabel = "q^" + dum + " (" + angst + "\\S-" + dum + "\\M)"
			endif
			break
		endif

		//more ifs for each case

		// if selection not found, abort
		DoAlert 0, "X-axis scaling incorrect. Aborting"
		Abort
	while(0) //end of "case" statement for x-axis scaling

	Label left, ylabel
	Label bottom, xlabel //E denotes "scaling"  - may want to use "units" instead
	ModifyGraph log(left)=(logLeft)
	ModifyGraph log(bottom)=(logBottom)

End
