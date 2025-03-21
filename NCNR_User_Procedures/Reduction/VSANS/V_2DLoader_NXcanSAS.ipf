#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// TODO
//
// x- add a macro to the VSANS menu
// x- add a "load" button to the panel
//
//
//
// -- document where the data actually is
//			(the numbering is off by one, and what is the correspondence between numbers
// 		and actual detector panels)
// -- new function to extract qx qy min.max scaling from the 3D data set
//
// -- there is sasdata(0-7) (or 8)
// root:sans56672_2D:sasentry1:sasdata0:I0		2D
// root:sans56672_2D:sasentry1:sasdata0:Q0		3D [2][x][y] 
//		first index is Qx, 2nd is Qy
//
// the numbering should hopefully follow the order of the detector list:
// Strconstant ksDetectorListAll = "FL;FR;FT;FB;ML;MR;MT;MB;B;"
// -- so first guess is that LRTB => (F)0123 -- (M)4567


//
//
// crudely loads the whole data set
// and give it a nice name. wihtout the name cleaning, the folder
// name will have a "." in it, and I'll need to work with liberal names
//
//
Function V_Load_2D_NXCS()

	Variable fileID
	HDF5OpenFile /R /Z fileID as ""	// Displays a dialog
	if (V_flag == 0)	// User selected a file?
		String fileName = CleanupName(RemoveEnding(S_fileName,".h5"),0)
		HDF5LoadGroup /O /R=2 /T=$fileName /IMAG=1 :, fileID, "/"
//		HDF5LoadData /O fileID, S_FileName
		HDF5CloseFile fileID
	endif
	
	return(0)
End

//
// proc to call the function that draws the panel
//
Proc V_Display_2D_VSANS()

	V_Display_1()

End


//
// data loaded from a 2D NXcanSAS file can be displayed -- all panels together, plotted in terms
// of q-values. The NXcanSAS folder structure is very different from the WORK folder, so I can't
// use any of that framework to plot. This plotting framework is similar to the plotting of the
// polarized beam data
//
//
Function V_Display_1()

	Variable sc=1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	DoWindow/F VSANS_NXCS
	if(V_flag==0)
		Display /W=(800*sc,40*sc,1308*sc,612*sc)/K=1
		ControlBar 100*sc
		DoWindow/C VSANS_NXCS
		Button button0 pos={sc*20,10*sc},size={sc*130,20*sc},title="Load 2D NXcanSAS",proc=V_Load2DNXCS_ButtonProc
		Button button1 pos={sc*20,70*sc},size={sc*130,20*sc},title="Change Display",proc=V_Change_1_ButtonProc
		PopupMenu popup0 pos={sc*20,40*sc},title="Data Folder",value=A_OneDDataInMemory()


		SetVariable setVar_b,pos={sc*300,35*sc},size={sc*120,15},title="axis Q",proc=V_2DQ_SetRange_SetVar
		SetVariable setVar_b,limits={0.02,1,0.02},value=_NUM:0.12
		CheckBox check_0a title="Log?",size={sc*60,20*sc},pos={sc*300,65*sc},proc=V_X1_Log_CheckProc


		if(gLaptopMode == 1)
		// note that the dimensions here are not strictly followed since the aspect ratio is set below
			Display/W=(10/sc,20/sc,200/sc,200/sc)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		else
			Display/W=(19,14,500,500)/HOST=# root:Packages:NIST:VSANS:VCALC:fv_degY vs root:Packages:NIST:VSANS:VCALC:fv_degX
		endif	
		RenameWindow #,Panels_Q
		ModifyGraph mode=2		// mode = 2 = dots
		ModifyGraph tick=2,mirror=1,grid=2,standoff=0
		ModifyGraph width={Aspect,1},height={Aspect,1},gbRGB=(56797,56797,56797)
		SetAxis left -0.2,0.2
		SetAxis bottom -0.2,0.2
		Label left "Qy"
		Label bottom "Qx"	
		SetActiveSubwindow ##
	
	endif
	
	SetDataFolder root:
	
	return(0)
End



// folder is the data folder
//
// type is the work folder
// polType is UU, UD, etc.
//
// when the "Change display" button is clicked, this procedure
// appends each of the data arrays to the graph (after scaling the data
// to q-values)
//
Function V_Fill_1_Panel(folder)
	String folder


	//fill the back, if used
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(!gIgnoreDetB)
		V_Panels_AsQ(folder,"B")
	endif
	
	//fill the middle
	V_Panels_AsQ(folder,"M")
	//fill the front
	V_Panels_AsQ(folder,"F")

	
	return(0)
end



// with a data wave passed in 
//locate the qx and qy waves, and return the min/max values (PBR)
// to be used for the data scaling
//
// the NXcanSAS data has both qx and qx in a 3D wave Q0[2][nx][ny]
// so pull these out one at a time and get min/max
//

Function V_getQxQyScaling_NXCS(dataW,minQx,maxQx,minQy,maxQy)
	Wave dataW
	Variable &minQx,&maxQx,&minQy,&maxQy

	
	DFREF dfr = GetWavesDataFolderDFR(dataW)
	
	WAVE qval = dfr:$("Q0")
	Variable dx,dy
	dx = DimSize(qval, 1 )
	dy = DimSize(qval, 2 )
	Make/O/D/N=(dx,dy) tempQ
	tempQ = qval[0][p][q]
	
	minQx = waveMin(tempQ)
	maxQx = waveMax(tempQ)
	
	tempQ = qval[1][p][q]	
	minQy = waveMin(tempQ)
	maxQy = waveMax(tempQ)
	
	killWaves/Z tempQ
	return(0)
End



// -- there is sasdata(0-7) (or 8)
// root:sans56672_2D:sasentry1:sasdata0:I0		2D
// root:sans56672_2D:sasentry1:sasdata0:Q0		3D [2][x][y] 
//		first index is Qx, 2nd is Qy
//
// the numbering should hopefully follow the order of the detector list:
// Strconstant ksDetectorListAll = "FL;FR;FT;FB;ML;MR;MT;MB;B;"
// -- so first guess is that LRTB => (F)0123 -- (M)4567 -- (B)8

// (DONE)
// x- handle the case of "B" (the back detector)

// folder = data folder (under root:)
// carr = det carriage str (F, M, or B)
//
Function V_Panels_AsQ(folder,carr)
	String folder,carr

	Variable dval,minQx,maxQx,minQy,maxQy

	// -- set the log/lin scaling
	ControlInfo/W=VSANS_NXCS check_0a
	// V_Value == 1 if checked
	
	if(V_Value == 0)
		// lookup wave
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:linearLookupWave
	else
		// lookup wave - the linear version
		Wave LookupWave = root:Packages:NIST:VSANS:Globals:logLookupWave
	endif
	
	String pathStr = "root:"+folder+":sasentry1:"

	if(cmpstr(carr,"F")==0)
		Wave/Z det_xL = $(pathStr + "sasdata0:I0")
		Wave/Z det_xR = $(pathStr + "sasdata1:I0")
		Wave/Z det_xT = $(pathStr + "sasdata2:I0")
		Wave/Z det_xB = $(pathStr + "sasdata3:I0")
		// check for the existence of the data - if it doesn't exist, abort gracefully
		if( !WaveExists(det_xB) || !WaveExists(det_xT) || !WaveExists(det_xL) || !WaveExists(det_xR) )
			Abort "No FRONT Data in the "+folder+" folder"
		endif
	else
		if(cmpstr(carr,"M")==0)
			Wave/Z det_xL = $(pathStr + "sasdata4:I0")
			Wave/Z det_xR = $(pathStr + "sasdata5:I0")
			Wave/Z det_xT = $(pathStr + "sasdata6:I0")
			Wave/Z det_xB = $(pathStr + "sasdata7:I0")
			// check for the existence of the data - if it doesn't exist, abort gracefully
			if( !WaveExists(det_xB) || !WaveExists(det_xT) || !WaveExists(det_xL) || !WaveExists(det_xR) )
				Abort "No MIDDLE carriage Data in the "+folder+" folder"
			endif
		else
			//must be the back detector carriage
			Wave/Z det_xL = $(pathStr + "sasdata8:I0")
			// check for the existence of the data - if it doesn't exist, abort gracefully
			if( !WaveExists(det_xL) )
				Abort "No BACK carriage Data in the "+folder+" folder"
			endif
		endif
	endif
	


// (DONE) -- for each of the 4 data waves, find qmin, qmax and set the scale to q, rather than pixels
	//set the wave scaling for the detector image so that it can be plotted in q-space
	// (DONE): this is only approximate - since the left "edge" is not the same from top to bottom, so I crudely
	// take the middle value. At very small angles, OK, at 1m, this is a crummy approximation.
	// since qTot is magnitude only, I need to put in the (-ve)
	if(cmpstr(carr,"B")==0)
	// only one panel on B
		V_getQxQyScaling_NXCS(det_xL,minQx,maxQx,minQy,maxQy)
		SetScale/I x minQx,maxQx,"", det_xL		//this sets the left and right ends of the data scaling
		SetScale/I y minQy,maxQy,"", det_xL	
	else
	// 4 panels on F, M
		V_getQxQyScaling_NXCS(det_xB,minQx,maxQx,minQy,maxQy)
		SetScale/I x minQx,maxQx,"", det_xB		//this sets the left and right ends of the data scaling
		SetScale/I y minQy,maxQy,"", det_xB	
	
		V_getQxQyScaling_NXCS(det_xT,minQx,maxQx,minQy,maxQy)
		SetScale/I x minQx,maxQx,"", det_xT		//this sets the left and right ends of the data scaling
		SetScale/I y minQy,maxQy,"", det_xT	
	
		V_getQxQyScaling_NXCS(det_xL,minQx,maxQx,minQy,maxQy)
		SetScale/I x minQx,maxQx,"", det_xL		//this sets the left and right ends of the data scaling
		SetScale/I y minQy,maxQy,"", det_xL	
	
		V_getQxQyScaling_NXCS(det_xR,minQx,maxQx,minQy,maxQy)
		SetScale/I x minQx,maxQx,"", det_xR		//this sets the left and right ends of the data scaling
		SetScale/I y minQy,maxQy,"", det_xR	

	endif	

// somewhere in here, need to get each data panel on a proper q-spacing, rather than simply
// fudging the scaling of the pixel image
// use the ImageFromXYZ operation -- do each panel individually



	
	String imageList,item
	Variable ii,num

	if(cmpstr(carr,"B")==0)
		AppendImage/W=VSANS_NXCS#Panels_Q det_xL

	else
		AppendImage/W=VSANS_NXCS#Panels_Q det_xT
		AppendImage/W=VSANS_NXCS#Panels_Q det_xB
		AppendImage/W=VSANS_NXCS#Panels_Q det_xL
		AppendImage/W=VSANS_NXCS#Panels_Q det_xR
	endif
	
	imageList= ImageNameList("VSANS_NXCS#Panels_Q",";")
	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage/W=VSANS_NXCS#Panels_Q $item ctab= {*,*,ColdWarm,0}
		ModifyImage/W=VSANS_NXCS#Panels_Q $item ctabAutoscale=0,lookup= LookupWave
		//ModifyImage/W=VSANS_X4#UU_Panels_Q $item log=V_Value
	endfor

// (DONE) -- set the q-range of the axes
	ControlInfo/W=VSANS_NXCS setVar_b
	dval = V_Value

	SetAxis/W=VSANS_NXCS#Panels_Q left -dval,dval
	SetAxis/W=VSANS_NXCS#Panels_Q bottom -dval,dval	


	SetDataFolder root:
	return(0)
End


// clear all of the images to start fresh again
//
// for some reason - I need to run this multiple times to clear all of the
// image from the display - to remove 8 images, I need to run this 3x
//
//
Function V_Clear_1_Panel()
	String type,polType,carr

	
	String imageList,item
	Variable ii,num

	imageList= ImageNameList("VSANS_NXCS#Panels_Q",";")
//	Print ImageNameList("VSANS_NXCS#Panels_Q",";")

	num = ItemsInList(imageList)			
	for(ii=0;ii<num;ii+=1)
		item = StringFromList(ii,imageList,";")
		// faster way than to write them explicitly
		//				ModifyImage/W=VSANS_X4#UU_Panels_Q ''#0 ctab= {*,*,ColdWarm,0}
		RemoveImage/Z/W=VSANS_NXCS#Panels_Q  $item 
	endfor
//	Print ImageNameList("VSANS_NXCS#Panels_Q",";")

	return(0)
End




// setVar for the range (in Q) for the 2D plot of the detectors
//
// this assumes that everything (the data) is already updated - this only updates the plot range
Function V_2DQ_SetRange_SetVar(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			SetAxis/W=VSANS_NXCS#Panels_Q left -dval,dval
			SetAxis/W=VSANS_NXCS#Panels_Q bottom -dval,dval

//			FrontPanels_AsQ()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// check box to toggle log/lin
//
Function V_X1_Log_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			Struct WMButtonAction ba
			ba.eventCode = 2		//fake mouse up
			V_Change_1_ButtonProc(ba)		//fake click on "do it"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// this is the "Change Display" button
//
// - clears all of the old images off of the display
// then fills in all of the data from the selected folder
//
Function V_Change_1_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String dataFolder
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popup0
			dataFolder = S_Value

			
			// ?? each call here is supposed to clear everything from all 4 subwindows,
			// but for some reason, I need to do this multiple times...
			V_Clear_1_Panel()
			V_Clear_1_Panel()
			V_Clear_1_Panel()
			V_Clear_1_Panel()

			// then fill each subwindow with each XS (9 panels)
			V_Fill_1_Panel(dataFolder)
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//
// button to load 2D NXcanSAS data files as written out by Igor (Jeff's procedures)
//
Function V_Load2DNXCS_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String dataFolder
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			V_Load_2D_NXCS()
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
