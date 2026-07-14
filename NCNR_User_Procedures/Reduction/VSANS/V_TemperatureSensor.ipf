#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=7.00

// April 2019
// routines to read + plot the data in the temperature_env block
//

// I don't know in general what may or may not be present, so I'll need to search for
// data, and let the user decide what to do with what is there.

// Paul K.? also puts a temperature_log block on the same level as temperature_env.
// I need to figure out which sensor and fields this is duplicating.
// - this may be the easiest and most appropriate to report - or not.

//

// list the temperature log folders
// list all of the metadata (name, attached to, set point, etc.)
// graph the values vs. time
// where will I get the proper units??
//
Function V_InitSensorGraph()

	DoWindow/F V_SensorGraph
	if(V_flag == 0)
		string/G root:Packages:NIST:VSANS:Globals:gSensorFolders  = "none;"
		string/G root:Packages:NIST:VSANS:Globals:gSensorMetaData = "no information"

		Execute "V_SensorGraph()"
		Make/O/D/N=1 root:Packages:NIST:VSANS:Globals:value
		Make/O/D/N=1 root:Packages:NIST:VSANS:Globals:time_point
		//		Wave value=value,time_point=time0
		AppendToGraph root:Packages:NIST:VSANS:Globals:value vs root:Packages:NIST:VSANS:Globals:time_point
		ModifyGraph mode=4, marker=8, opaque=1, mirror=2
		Legend
		Label left, "Sensor Value"
		Label bottom, "Time (s)"

		STRUCT WMPopupAction pa
		pa.eventCode = 2
		pa.popStr    = "RAW"
		V_WorkFolderPopMenuProc(pa)
	endif

	return (0)
End

Proc V_SensorGraph() : Graph

	variable sc = 1

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		sc = 0.7
	endif

	PauseUpdate; Silent 1 // building window...
	//	Display /W=(1500,350,2300,750)/N=V_SensorGraph/K=1
	//	ControlBar/L 300

	if(root:Packages:NIST:VSANS:Globals:gLaptopMode == 1)
		Display/W=(600 * sc, 50 * sc, 1050 * sc, 600 * sc)/N=V_SensorGraph/K=1
		ControlBar/T 300 * sc
	else
		Display/W=(600, 50, 1050, 780)/N=V_SensorGraph/K=1
		ControlBar/T 380
	endif

	//	ShowTools/A
	PopupMenu popup0, pos={sc * 10.00, 10.00 * sc}, size={sc * 87.00, 23.00 * sc}, proc=V_WorkFolderPopMenuProc, title="folder"
	PopupMenu popup0, mode=1, popvalue="RAW", value=#"\"RAW;SAM;ABS;\""
	PopupMenu popup1, pos={sc * 10.00, 40.00 * sc}, size={sc * 84.00, 23.00 * sc}, proc=V_SensorPopMenuProc, title="sensor"
	PopupMenu popup1, mode=1, popvalue="pick folder", value=root:Packages:NIST:VSANS:Globals:gSensorFolders
	TitleBox title0, pos={sc * 10.00, 80.00 * sc}, size={sc * 25.00, 19.00 * sc}, fSize=10, variable=root:Packages:NIST:VSANS:Globals:gSensorMetaData
EndMacro

// pick the work folder of interest, and get the list of sensors, if any
Function V_WorkFolderPopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum = pa.popNum
			string   popStr = pa.popStr
			string dfStr

			// repopulate the list of sensors, if any
			SVAR gList = root:Packages:NIST:VSANS:Globals:gSensorFolders

			// do any data folders exist?
			if(!DataFolderExists("root:Packages:NIST:VSANS:" + popStr + ":entry:sample:temperature_env:"))
				// data folder does not exist
				DoAlert 0, "No Sensor Data Exists"
				SVAR gMeta = root:Packages:NIST:VSANS:Globals:gSensorMetaData
				gMeta = "no sensors found"
				gList = "none"
				//				DoWindow/K V_SensorGraph
				return (0)
			endif

			SetDataFolder $("root:Packages:NIST:VSANS:" + popStr + ":entry:sample:temperature_env:")
			dfStr = DataFolderDir(1) // bit 0 = data folders
			gList = StringByKey("FOLDERS", dfStr, ":", ";")
			gList = ReplaceString(",", gList, ";")

			SetDataFolder root:

			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

// form the list of sensors, when popped, update the metadata and the plot
//
Function V_SensorPopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			variable popNum = pa.popNum
			string   popStr = pa.popStr

			string folderStr, wStr, wStr_2
			SVAR gMeta = root:Packages:NIST:VSANS:Globals:gSensorMetaData

			variable ii
			string   item

			ControlInfo popup0
			folderStr = S_Value
			// add single quote since sensor folder name may have a space in it
			if(!DataFolderExists("root:Packages:NIST:VSANS:" + folderStr + ":entry:sample:temperature_env:'" + popStr + "':"))
				// data folder does not exist
				DoAlert 0, "No Sensor Data Exists"
				//				DoWindow/K V_SensorGraph
				return (0)
			endif

			SetDataFolder $("root:Packages:NIST:VSANS:" + folderStr + ":entry:sample:temperature_env:'" + popStr + "':")

			wStr  = DataFolderDir(2) //*bit* 0=FOLDERS, 1=WAVES, 2=VARIABLES, 3=STRINGS
			wStr  = StringByKey("WAVES", wStr, ":", ";")
			gMeta = ""
			for(ii = 0; ii < ItemsInList(wStr, ","); ii += 1)
				item = StringFromList(ii, wStr, ",")
				if(WaveType($item, 1) == 2) //2= text, 1=numeric
					WAVE/T wt = $item
					gMeta += item + " = " + wt[0] + "\r"
				else
					WAVE w = $item
					gMeta += item + " = " + num2str(w[0]) + "\r"
				endif
			endfor
			gMeta  = ReplaceString(",", gMeta, "\t\r")
			gMeta += "\r"

			// waves in the value_log folder
			SetDataFolder value_log
			wStr = DataFolderDir(2) //*bit* 0=FOLDERS, 1=WAVES, 2=VARIABLES, 3=STRINGS
			wStr = StringByKey("WAVES", wStr, ":", ";")

			for(ii = 0; ii < ItemsInList(wStr, ","); ii += 1)
				item = StringFromList(ii, wStr, ",")
				if(cmpstr(item, "value") != 0 && cmpstr(item, "time0") != 0)
					if(WaveType($item, 1) == 2) //2= text, 1=numeric
						WAVE/T wt = $item
						gMeta += item + " = " + wt[0] + "\r"
					else
						WAVE w = $item
						gMeta += item + " = " + num2str(w[0]) + "\r"
					endif
				endif
			endfor
			// remove last "\r" (a single character)
			gMeta = gMeta[0, strlen(gMeta) - 2]

			//update the waves on the plot, plus the variables in this folder
			//			SetDataFolder value_log		//already here
			WAVE newVal  = value
			WAVE newTime = time0
			Duplicate/O newVal, root:Packages:NIST:VSANS:Globals:value
			Duplicate/O newTime, root:Packages:NIST:VSANS:Globals:time_point

			setDataFolder root:
			break
		case -1: // control being killed
			break
		default:
			// no default action
			break
	endswitch

	return 0
End

