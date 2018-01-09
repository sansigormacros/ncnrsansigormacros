#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.





//
// TODO:
// x- make  the data folder list for the popup
// x- make the data folder popup do the work of plotting 
//
// x- (done by invoking the panel)
//   x-make a button to show the default table, and set up dependencies to link to the graph display
//
// -- have an "active" data set to trim, or make duplicates for all of the data sets
//
// -- button to convert the points to strings that can be used and written to data files?
// -- is this really necessary? if the save button is clicked, the strings are automatically generated
//  -- but what if it's not? What if I do something else to send the strings to a protocol? or to a file?
//
// -- find a better way to be sure that the dependency does not generate errors if it is not
//   properly killed
//
// -- help file
//
// x- larger panel
//
// x- error checking if the binType and the data present don't match. (test for failure)
// -- do I really need the binType popup? How else would I know what data sets to plot/remove?
//
// x- table is continually duplicated
// -- AutoPosition the windows next to each other
// x- (different)(not ugly) color for the control bar so it's distinguishable from the regular data plot
// x- "Done" button that kills the root:ToTrim folder (may need to kill the dependency first)
//
Proc V_CombineDataGraph()

// this is the "initialization" step
	NewDataFolder/O root:ToTrim
	
	DoWindow/F V_1D_Combine

	Variable num,ii
	String detStr
		
	if(V_flag==0)

		Display /W=(277,526,879,1069)/N=V_1D_Combine /K=2

		ControlBar 70
		ModifyGraph cbRGB=(44000,44000,44000)
		
//		Button button2,pos={15,5},size={70,20},proc=V_Load_ITX_button,title="Load Data"
//		Button button2,help={"Load an ITX file"}
		
//		PopupMenu popup1,pos={125,5},size={90,20},title="Data Folder"
//		PopupMenu popup1,help={"data folder"}
//		PopupMenu popup1,value= GetAList(4),proc=V_DataFolderPlotPop
		
		PopupMenu popup0,pos={15,5},size={70,20},title="Bin Type"
		PopupMenu popup0,help={"binning type"}
		PopupMenu popup0,value= ksBinTypeStr,proc=V_DataBinTypePlotPop

		Button button3,pos={544.00,5},size={30.00,20.00},title="?"
		Button button3,help={"help file for combining 1D data"}

		CheckBox check0,pos={18.00,36.00},size={57.00,16.00},proc=V_Plot1D_LogCheckProc,title="Log Axes"
		CheckBox check0,value= 1

		Button AllQ,pos={100,36},size={70,20},proc=V_AllQ_Plot_1D_ButtonProc,title="All Q"
		Button AllQ,help={"Show the full q-range of the dataset"}

		Button button1,pos={225,36},size={100,20},proc=V_TrimWaves2StringButton,title="Wave 2 Str"
		Button button1,help={"Convert the waves to global strings"}
		
//		Button button4,pos={388,36},size={90.00,20.00},title="Trim & Save"
//		Button button4,help={"combine and save 1D data"},proc=V_SaveTrimmed_Button
		
		Button button0,pos={524,36},size={70,20},proc=V_DoneCombine1D_ButtonProc,title="Done"
		Button button0,help={"Close the panel and kill the temporary folder"}
				
		Legend/C/N=text0/J/X=72.00/Y=60.00

	endif	
	

	//trust that the table is present? No, but don't overwrite the data in the waves
	// unless any one of the three doesn't exist
	
	SetDataFolder root:Packages:NIST:VSANS:Globals:Protocols

	if(exists("PanelNameW") == 0 || exists("Beg_pts") == 0 || exists("End_pts") == 0)
		Make/O/T/N=(ItemsInList(ksPanelBinTypeList)) PanelNameW
		Make/O/D/N=(ItemsInList(ksPanelBinTypeList)) Beg_pts
		Make/O/D/N=(ItemsInList(ksPanelBinTypeList)) End_pts
	
		num = ItemsInList(ksPanelBinTypeList)
		ii=0
		do
			detStr = StringFromList(ii, ksPanelBinTypeList)
			Beg_pts[ii]  = NumberByKey(detStr, ksBinTrimBegDefault,"=",";")
			End_pts[ii] = NumberByKey(detStr, ksBinTrimEndDefault,"=",";")
			PanelNameW[ii] = detStr
			ii += 1
		while(ii<num)
		
	endif
	// now make sure that the table is present
	DoWindow/F V_TrimPointsTable

	if(V_flag==0)
		Edit/K=0/N=V_TrimPointsTable PanelNameW,Beg_pts,End_pts		
	endif
	
	// last, set up the dependency
	Make/O/D/N=1 trimUpdate
	trimUpdate := V_TrimTestUpdate(Beg_pts, End_pts)
	
	
	SetDataFolder root:
		
End


// function that is a simple dependency, and updates the trimmed waves
// that are displayed
//
// does not actually modify the real data, makes a copy, and is only a visual
//
//
Function V_TrimTestUpdate(Beg_pts, End_pts)
	Wave Beg_pts,End_pts
	
	// trim the data displayed
	// do this by setting the iBin values to NaN, so it won't display
	// won't hurt to set twice...
	
	Wave/T panelStr = root:Packages:NIST:VSANS:Globals:Protocols:PanelNameW
	Wave begW = root:Packages:NIST:VSANS:Globals:Protocols:Beg_pts
	Wave endW = root:Packages:NIST:VSANS:Globals:Protocols:End_pts

	// in case the dependency is still active, and the folder was killed
	if(DataFolderExists("root:ToTrim") == 0)
		return(0)
	endif
	
//	SetDataFolder root:ToTrim
//	ControlInfo/W=V_1D_Combine popup1
//	String dataFldrStr = S_Value
	
	SVAR curDispType = root:Packages:NIST:VSANS:Globals:gCurDispType
	String dataFldrStr = "root:Packages:NIST:VSANS:"+curDispType
	
	Variable num,ii,p1,p2
	String str,detStr
	num=numpnts(panelStr)
	
	for(ii=0;ii<num;ii+=1)
		detStr = panelStr[ii]
		Wave/Z iw = $("root:ToTrim:iBin_qxqy_"+detStr+"_trim")
		Wave/Z iw_orig = $(dataFldrStr+":iBin_qxqy_"+detStr)
//		Wave/Z iw = $("iBin_qxqy_"+detStr)
//		Wave/Z ew = $("eBin_qxqy_"+detStr)
		if(WaveExists(iw) && WaveExists(iw_orig))
			
//			DeletePoints 0,nBeg, qw,iw,ew
			// start fresh
			iw = iw_orig
			
			p1 = begW[ii]
			iw[0,p1-1] = NaN
				
			Variable npt
			npt = numpnts(iw) 
//			DeletePoints npt-nEnd,nEnd, qw,iw,ew
			p2 = EndW[ii]
			iw[npt-p2,npt-1] = NaN
			
		endif
		
	endfor
	
	SetDataFolder root:

	return(0)
End

// 
// x- verify that the proper waves exist for the binning type
//
// x- the logic here is wrong. if the ToTrim folder is empty (As on startup)
//  then the waves are always missing - and the function returns an error - every time
//
// now works with the "current" data that is displayed, rather than relying on 
// a lot of user input regarding the details of the saved data
//
Function V_DataBinTypePlotPop(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string


	String str,winStr="V_1D_Combine"
	Variable binType,num,ii,err

	binType = V_BinTypeStr2Num(popStr)
	
	
	//  x- need to update this to make sure that the data waves are present before plotting. This
	//    currently looks in the ToTrim folder, but the binning could be wrong in the data folder
	//    and will be an error...
	
	//dataType now needs to be the full path to the folder
	// Plot the "real" data. data copy to trim will be plotted later
	//
	SVAR dispType = root:Packages:NIST:VSANS:Globals:gCurDispType


// dispatch based on the string, not on the number of selection in the pop string
	V_QBinAllPanels_Circular(dispType,binType)

	String workTypeStr
	workTypeStr = "root:Packages:NIST:VSANS:"+dispType
	

//	dataType = "root:"+popStr
//	
//	//remove EVERYTHING from the graph, no matter what
	String type,list,item
//	list = TraceNameList(winStr,";",1)
//	for(ii=0;ii<ItemsInList(list);ii+=1)
//		item = StringFromList(ii, list, ";")
////		CheckDisplayed/W=$winStr $(item)
////		if(V_flag==1)
//			RemoveFromGraph/Z/W=$winStr $(item)
////		endif
//	endfor	
//	
	
	sprintf str,"(\"%s\",%d,\"%s\")",workTypeStr,binType,winStr

	Execute ("V_Back_IQ_Graph"+str)
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)

	ModifyGraph marker=8,opaque=1,msize=3		//make the traces open white circles


	NewDataFolder/O root:ToTrim
	
	//remove all of the "toTrim" data from the graph, if it's there
	SetDataFolder root:ToTrim
	for(ii=0;ii<ItemsInList(ksPanelBinTypeList);ii+=1)
		type = StringFromList(ii, ksPanelBinTypeList, ";")
		CheckDisplayed/W=$winStr $("iBin_qxqy_"+type+"_trim")
		if(V_flag==1)
			RemoveFromGraph/W=$winStr $("iBin_qxqy_"+type+"_trim")
		endif
	endfor	
	SetDataFolder root:


	//then kill the data folder, so it can be duplicated
	
//
//	// duplicate all of the data into the new folder
	SetDataFolder $workTypeStr
	list = WaveList("*",";","")		//must be in the correct data folder
	SetDataFolder root:
//	Print list	
	num = ItemsInList(list)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,list)
		Duplicate/O $(workTypeStr+":"+str), $("root:ToTrim:"+str+"_trim")
	endfor
	
//	// be sure that the data is present in the ToTrim folder before trying to plot
//	err = V_TrimWavesExist(binType)
//	if(err)
//		DoAlert 0,"wrong bin type selected"
//		return(0)
//	endif
	
	
	// plot the linked data
	sprintf str,"(\"%s\",%d,\"%s\")","root:ToTrim",binType,winStr

	Execute ("V_Back_IQ_Graph_trim"+str)
	Execute ("V_Middle_IQ_Graph_trim"+str)
	Execute ("V_Front_IQ_Graph_trim"+str)
	// and link the data to the table with a dependency?
//	done in the panel macro?
	
	// last, force the dependency to update so that the trimmed points are shown
	Wave w = root:Packages:NIST:VSANS:Globals:Protocols:Beg_pts
	w[0] += 1
	w[0] -= 1
	
	
	return(0)	
End



// 
// x- verify that the proper waves exist for the binning type
//
// x- the logic here is wrong. if the ToTrim folder is empty (As on startup)
//  then the waves are always missing - and the function returns an error - every time
//
// currently unused, in favor of using the current data rather than saved itx data
//
Function V_DataFolderPlotPop(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string


	String str,winStr="V_1D_Combine",dataType
	Variable binType,num,ii
	ControlInfo popup0
	binType = V_BinTypeStr2Num(S_Value)
	
	
	//  x- need to update this to make sure that the data waves are present before plotting. This
	//    currently looks in the ToTrim folder, but the binning could be wrong in the data folder
	//    and will be an error...
	
	// be sure that the data is present in the ToTrim folder before trying to plot
	Variable err = V_itxWavesExist(popStr,binType)
	if(err)
		DoAlert 0,"wrong bin type selected"
		return(0)
	endif
	
	
	//dataType now needs to be the full path to the folder
	// Plot the "real" data. data copy to trim will be plotted later
	//
	dataType = "root:"+popStr
	
	//remove EVERYTHING from the graph, no matter what
	String type,list,item
	list = TraceNameList(winStr,";",1)
	for(ii=0;ii<ItemsInList(list);ii+=1)
		item = StringFromList(ii, list, ";")
//		CheckDisplayed/W=$winStr $(item)
//		if(V_flag==1)
			RemoveFromGraph/Z/W=$winStr $(item)
//		endif
	endfor	
	
	
	sprintf str,"(\"%s\",%d,\"%s\")",dataType,binType,winStr

	Execute ("V_Back_IQ_Graph"+str)
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)

	ModifyGraph marker=8,opaque=1,msize=3		//make the traces open white circles


	NewDataFolder/O root:ToTrim
	
	//remove all of the "toTrim" data from the graph, if it's there
	SetDataFolder root:ToTrim
	for(ii=0;ii<ItemsInList(ksPanelBinTypeList);ii+=1)
		type = StringFromList(ii, ksPanelBinTypeList, ";")
		CheckDisplayed/W=$winStr $("iBin_qxqy_"+type+"_trim")
		if(V_flag==1)
			RemoveFromGraph/W=$winStr $("iBin_qxqy_"+type+"_trim")
		endif
	endfor	
	SetDataFolder root:


	//then kill the data folder, so it can be duplicated
	
//
//	// duplicate all of the data into the new folder
	SetDataFolder $dataType
	list = WaveList("*",";","")		//must be in the correct data folder
	SetDataFolder root:
//	Print list	
	num = ItemsInList(list)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,list)
		Duplicate/O $(dataType+":"+str), $("root:ToTrim:"+str+"_trim")
	endfor
	
	// be sure that the data is present in the ToTrim folder before trying to plot
	err = V_TrimWavesExist(binType)
	if(err)
		DoAlert 0,"wrong bin type selected"
		return(0)
	endif
	
	
	// plot the linked data
	sprintf str,"(\"%s\",%d,\"%s\")","root:ToTrim",binType,winStr

	Execute ("V_Back_IQ_Graph_trim"+str)
	Execute ("V_Middle_IQ_Graph_trim"+str)
	Execute ("V_Front_IQ_Graph_trim"+str)
	// and link the data to the table with a dependency?
//	done in the panel macro?
	
	// last, force the dependency to update so that the trimmed points are shown
	Wave w = root:Packages:NIST:VSANS:Globals:Protocols:Beg_pts
	w[0] += 1
	w[0] -= 1
	
	
	return(0)	
End



// kill the dependency,
// kill the panel, then the associated ToTrim folder
// do not kill the beg/end waves
//
Function V_DoneCombine1D_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	Wave trimUpdate = root:Packages:NIST:VSANS:Globals:Protocols:trimUpdate
	trimUpdate = 1		//kills the dependency
	DoWindow/K V_1D_Combine
	
	KillDataFolder/Z root:ToTrim
	
	return(0)
End

// TODO
// -- verify that this works for all binning cases
// -- see V_Trim1DDataStr to see if they can be combined
//
Function V_SaveTrimmed_Button(ctrlName) : ButtonControl
	String ctrlName
	
	String detListStr,dataType,str
	Variable bintype,num,ii

	ControlInfo popup0 
	binType = V_BinTypeStr2Num(S_Value)
	
	
	if(binType == 1)
		detListStr = ksBinType1
	endif
	if(binType == 2)
		detListStr = ksBinType2
	endif
	if(binType == 3)
		detListStr = ksBinType3
	endif
	if(binType == 4)
		detListStr = ksBinType4
	endif
	if(strlen(detListStr)==0)
		DoAlert 0,"error in V_SaveTrimmed_Button"
		return(0)
	endif

// set the global strings
	V_TrimWaves2String()		//in case the button wasn't clicked
	SVAR gBegPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	SVAR gEndPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr

// get a fresh copy of the data
// duplicate all of the data into the new folder
	ControlInfo popup1
	dataType = "root:"+S_Value

	SetDataFolder $dataType
	String list = WaveList("*",";","")		//must be in the correct data folder
	SetDataFolder root:
//	Print list	
	num = ItemsInList(list)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,list)
		Duplicate/O $(dataType+":"+str), $("root:ToTrim:"+str+"_trim")
	endfor

	
// trim each data set
	Variable nBeg,nEnd,npt
	String detstr
	
	SetDataFolder root:ToTrim
	num = ItemsInList(detListStr)
	for(ii=0;ii<num;ii+=1)
		detStr = StringFromList(ii, detListStr)
		nBeg = NumberByKey(detStr, gBegPtsStr,"=",";")
		nEnd = NumberByKey(detStr, gEndPtsStr,"=",";")
		
//		V_TrimOneSet(folderStr,detStr,nBeg,nEnd)
		Wave/Z qw = $("qBin_qxqy_"+detStr+"_trim")
		Wave/Z iw = $("iBin_qxqy_"+detStr+"_trim")
		Wave/Z ew = $("eBin_qxqy_"+detStr+"_trim")

		DeletePoints 0,nBeg, qw,iw,ew

		npt = numpnts(qw) 
		DeletePoints npt-nEnd,nEnd, qw,iw,ew
//		
	endfor


// remove Q=0 from "B" if it's present
	SetDataFolder root:ToTrim
	WAVE/Z qBin = qBin_qxqy_B_trim
	WAVE/Z iBin = iBin_qxqy_B_trim
	WAVE/Z eBin = eBin_qxqy_B_trim
//	WAVE/Z nBin = nBin_qxqy_B_trim
//	WAVE/Z iBin2 = iBin2_qxqy_B_trim

	if(qBin[0] == 0)
		DeletePoints 0, 1, qBin,iBin,eBin//,nBin,iBin2
	endif

	
// concatenate
	V_1DConcatenate("root:","ToTrim","_trim",binType)

// sort the waves - concatenation creates tmp_q, tmp_i, tmp_s
// so this call will work (doesn't need the "_trim" tag)
	V_TmpSort1D("root:","ToTrim")

// write out the data to disk

	Execute "V_GetNameForSave()"
	SVAR newName = root:saveName
	String saveName = newName

	//will write out the tmp_q, tmp_i, tmp_s waves
	V_Write1DData("root:","ToTrim",saveName)		//don't pass the full path, just the name

	
// put a fresh copy of the data back into the folder since the data was actually trimmed
// duplicate all of the data into the new folder
	ControlInfo popup1
	dataType = "root:"+S_Value

	SetDataFolder $dataType
	list = WaveList("*",";","")		//must be in the correct data folder
	SetDataFolder root:
//	Print list	
	num = ItemsInList(list)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,list)
		Duplicate/O $(dataType+":"+str), $("root:ToTrim:"+str+"_trim")
	endfor


	SetDataFolder root:
	
	return(0)
End



//
// dialog to select and load an itx format data file
//
Function V_Load_ITX_Button(ctrlName) : ButtonControl
	String ctrlName
	
	Execute "V_Load_Data_ITX()"
	
	return(0)
End


// TODO
// -- document
Function V_TrimWaves2StringButton(ctrlName) : ButtonControl
	String ctrlName
	
	V_TrimWaves2String()

	return(0)
End

// for each of the binning types, be sure that the corresponding waves in the
// root:ToTrim folder actually do exist.
// return 0 for OK, 1 if error
Function V_TrimWavesExist(binType)
	Variable binType
	
	String binStr="",str
	Variable num,ii
	
	if(binType == 1)
		binStr = ksBinType1
	endif
	if(binType == 2)
		binStr = ksBinType2
	endif
	if(binType == 3)
		binStr = ksBinType3
	endif
	if(binType == 4)
		binStr = ksBinType4
	endif
	
	num = ItemsInList(binStr)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,binStr)
		if(exists("root:ToTrim:iBin_qxqy_"+Str+"_trim") == 0)		// not in use = error
			return(1)
		endif
	endfor
	
	return(0)		//everything checked out OK, no error

end

// for each of the binning types, be sure that the corresponding waves in the
// root:ToTrim folder actually do exist.
// return 0 for OK, 1 if error
Function V_itxWavesExist(folderStr,binType)
	String folderStr
	Variable binType
	
	String binStr="",str
	Variable num,ii
	
	if(binType == 1)
		binStr = ksBinType1
	endif
	if(binType == 2)
		binStr = ksBinType2
	endif
	if(binType == 3)
		binStr = ksBinType3
	endif
	if(binType == 4)
		binStr = ksBinType4
	endif
	
	num = ItemsInList(binStr)
	for(ii=0;ii<num;ii+=1)
		str = StringFromList(ii,binStr)
		if(exists("root:"+folderStr+":iBin_qxqy_"+Str) == 0)		// not in use = error
			return(1)
		endif
	endfor
	
	return(0)		//everything checked out OK, no error

end



//
// take the waves, and convert to strings that can be added to the protocol
//
// 
// x- get the variables out of root:, and move it to Protocols
// x- get the waves out of root:, and move it to Protocols
// x- be sure that the variables are initialized (done in main initialization
// x- link this to the panel?
//
Function V_TrimWaves2String()


	SVAR gBegPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gBegPtsStr
	SVAR gEndPtsStr=root:Packages:NIST:VSANS:Globals:Protocols:gEndPtsStr

	Wave/T PanelNameW = root:Packages:NIST:VSANS:Globals:Protocols:PanelNameW
	Wave Beg_pts = root:Packages:NIST:VSANS:Globals:Protocols:Beg_pts
	Wave End_pts = root:Packages:NIST:VSANS:Globals:Protocols:End_pts
	
// ksPanelBinTypeList = "B;FT;FB;FL;FR;MT;MB;ML;MR;FTB;FLR;MTB;MLR;FLRTB;MLRTB;"
// ksBinTrimBegDefault = "B=5;FT=6;FB=6;FL=6;FR=6;MT=6;MB=6;ML=6;MR=6;FTB=7;FLR=7;MTB=7;MLR=7;FLRTB=8;MLRTB=8;"
// ksBinTrimEndDefault 

	// wipe out the "old" global strings
	gBegPtsStr = ksBinTrimBegDefault
	gEndPtsStr = ksBinTrimEndDefault

	Variable num, ii,nBeg,nEnd
	String item,panelStr
	
	num = numpnts(PanelNameW)
	for(ii=0;ii<num;ii+=1)
		panelStr = PanelNameW[ii]
		gBegPtsStr = ReplaceNumberByKey(panelStr, gBegPtsStr, Beg_pts[ii],"=",";")
		gEndPtsStr = ReplaceNumberByKey(panelStr, gEndPtsStr, End_pts[ii],"=",";")
	endfor

	return(0)
End


