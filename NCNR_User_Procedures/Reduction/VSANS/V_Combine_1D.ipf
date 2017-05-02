#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//
//
// Preliminary routines for adjusting, masking, and combining 1D VSANS data sets.
//
// ideas taken from USANS to mask data sets
// avoiding duplication of NSORT, since autoscale is not in favor, and there may be anywhere
//   from 3 to 9 data sets to combine
//
// masking waves are saved in the "Combine_1D" folder, BUT the masking may eventually be part
//  of the data reduction protocol - and anything in work folders will be lost
//

////////////////
// TODO:
// x- add a popup to the load tab to set the work folder
// x- add this file to the Includes list and to the SVN folder
// -- add button (mask tab) to save mask
// -- add button (mask tab) to recall mask
// -- think of ways to run through the files batchwise (instead of adding this to the protocol)
// -- link the main entry procedure to the main panel
//
// -- when do I concatenate the data sets?
// ---- do I add a concatenate button to the Load tab, then this single set is the 
//    starting point for the MASK tab
// ---- the Load Data button could then be a loader for a single file, which is then the "concatenated"
//     starting point...
//
// x- make the graph larger for easier viewing of the data
// -- increase the size of the tab control, rearrange the other controls
//
// -- how do I incorporate the rescaling?
//
// -- error bars on the graph
// x- legend on the graph
//
// x- define a new folder for all of this -- NOT the protocol folder
// x- define a string constant with this path
//
// -- button to mask based on relative error threshold for each data point. may be a good startng point for
//    masking
//
// -- remove the mask by relative error button - this is not really a good idea.
//
//


StrConstant ksCombine1DFolder = "root:Packages:NIST:VSANS:Globals:Combine_1D"

// main entry routine
Macro V_Combine_1D()

	//check for the correct folder, initialize if necessary
	//
	if(DataFolderExists(ksCombine1DFolder) == 0)
		Execute "V_Init_Combine_1D()"
	endif
	
	SetDataFolder root:
	
	DoWindow/F V_Combine_1D_Graph
	if(V_flag==0)
		Execute "V_Combine_1D_Graph()"
	endif
End

Proc V_Init_Combine_1D()

	//set up the folder(s) needed
	NewDataFolder/O $(ksCombine1DFolder)
	
	SetDataFolder $(ksCombine1DFolder)
	
	String/G gCurFile=""
	String/G gStr1=""
	Variable/G gFreshMask=1
	Variable/G gNq=0
	
	SetDataFolder root:
End


////
//
//
Proc V_Combine_1D_Graph() 

	PauseUpdate; Silent 1		// building window...
	Display /W=(699,45,1328,779) /K=1
	ModifyGraph cbRGB=(51664,44236,58982)
	ModifyGraph tickUnit=1
	DoWindow/C V_Combine_1D_Graph
	ControlBar 160
	// break into tabs
	TabControl C1D_Tab,pos={5,3},size={392,128},proc=C1D_TabProc
	TabControl C1D_Tab,labelBack=(49151,49152,65535),tabLabel(0)="Load"
	TabControl C1D_Tab,tabLabel(1)="Mask",tabLabel(2)="Rescale",value=0
	
	//always visible - revert and save
	//maybe the wrong place here?
	Button C1DControlA,pos={225,135},size={80,20},proc=C1D_RevertButtonProc,title="Revert"
	Button C1DControlA,help={"Revert the data to its original state and start over"}
	Button C1DControlB,pos={325,135},size={50,20},proc=C1D_SaveButtonProc,title="Save"
	Button C1DControlB,help={"Save the masked and scaled data set"}
	Button C1DControlC,pos={25,135},size={50,20},proc=C1D_HelpButtonProc,title="Help"
	Button C1DControlC,help={"Show the help file for combining VSANS data sets"}
	
	// add the controls to each tab ---- all names start with "C1DControl_"

	//tab(0) Load - initially visible
	Button C1DControl_0a,pos={23,39},size={80,20},proc=C1D_LoadButtonProc,title="Load Data"
	Button C1DControl_0a,help={"Load slit-smeared USANS data = \".cor\" files"}
	CheckBox C1DControl_0b,pos={26,74},size={80,14},proc=C1D_LoadCheckProc,title="Log Axes?"
	CheckBox C1DControl_0b,help={"Toggle Log/Lin Q display"},value= 1
	TitleBox C1DControl_0c,pos={120,37},size={104,19},font="Courier",fSize=10
	TitleBox C1DControl_0c,variable= $(ksCombine1DFolder+":gStr1")
	PopupMenu C1DControl_0d,pos={120,75},size={71,20},title="Bin Type"
	PopupMenu C1DControl_0d,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
	PopupMenu C1DControl_0d,value= ksBinTypeStr
	PopupMenu C1DControl_0d,mode=1,proc=V_CombineModePopup
	PopupMenu C1DControl_0e,pos={120,100},size={109,20},title="Data Source"
	PopupMenu C1DControl_0e,mode=1,popvalue="RAW",value= #"\"RAW;SAM;EMP;BGD;COR;ABS;\""		
	Button C1DControl_0f,pos={200,39},size={120,20},proc=C1D_ConcatButtonProc,title="Concatenate"
	Button C1DControl_0f,help={"Load slit-smeared USANS data = \".cor\" files"}

	
	//tab(1) Mask
	Button C1DControl_1a,pos={20,35},size={90,20},proc=C1D_MyMaskProc,title="Mask Point"		//bMask
	Button C1DControl_1a,help={"Toggles the masking of the selected data point"}
	Button C1DControl_1a,disable=1
	Button C1DControl_1b,pos={20,65},size={140,20},proc=C1D_MaskGTCursor,title="Mask Q >= Cursor"		//bMask
	Button C1DControl_1b,help={"Toggles the masking of all q-values GREATER than the current cursor location"}
	Button C1DControl_1b,disable=1
	Button C1DControl_1c,pos={20,95},size={140,20},proc=C1D_MaskLTCursor,title="Mask Q <= Cursor"		//bMask
	Button C1DControl_1c,help={"Toggles the masking of all q-values LESS than the current cursor location"}
	Button C1DControl_1c,disable=1
	Button C1DControl_1d,pos={180,35},size={90,20},proc=C1D_ClearMaskProc,title="Clear Mask"		//bMask
	Button C1DControl_1d,help={"Clears all mask points"}
	Button C1DControl_1d,disable=1
	Button C1DControl_1e,pos={180,65},size={90,20},proc=C1D_MaskPercent,title="Percent Mask"		//bMask
	Button C1DControl_1e,help={"Clears all mask points"}
	Button C1DControl_1e,disable=1
	
	
//	Button C1DControl_1b,pos={144,66},size={110,20},proc=C1D_MaskDoneButton,title="Done Masking"
//	Button C1DControl_1b,disable=1
	
//	//tab(2) Rescale
	Button C1DControl_2a,pos={31,42},size={90,20},proc=C1D_ExtrapolateButtonProc,title="Extrapolate"
	Button C1DControl_2a,help={"Extrapolate the high-q region with a power-law"}
	Button C1DControl_2a,disable=1
	SetVariable C1DControl_2b,pos={31,70},size={100,15},title="# of points"
	SetVariable C1DControl_2b,help={"Set the number of points for the power-law extrapolation"}
	SetVariable C1DControl_2b,limits={5,100,1},value=_NUM:123
	SetVariable C1DControl_2b,disable=1
	CheckBox C1DControl_2c,pos={157,45},size={105,14},proc=C1D_ExtrapolationCheckProc,title="Show Extrapolation"
	CheckBox C1DControl_2c,help={"Show or hide the high q extrapolation"},value= 1
	CheckBox C1DControl_2c,disable=1
	SetVariable C1DControl_2d,pos={31,96},size={150,15},title="Power Law Exponent"
	SetVariable C1DControl_2d,help={"Power Law exponent from the fit = the DESMEARED slope - override as needed"}
	SetVariable C1DControl_2d format="%5.2f"
	SetVariable C1DControl_2d,limits={-inf,inf,0},value=_NUM:123
	SetVariable C1DControl_2d,disable=1
	
	Legend/C/N=text0/J/X=72.00/Y=60.00

	
	SetDataFolder root:
EndMacro

//
// recalculate the I(q) binning. no need to adjust model function or views
// just rebin
//
// see V_BinningModePopup() in V_DataPlotting.ipf for a duplicate verison of this function
Function V_CombineModePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

// TODO
// x- replace the type with selection from the panel - don't use the current display type
	ControlInfo C1DControl_0e
	String type = S_Value

	SVAR gStr1 = $(ksCombine1DFolder+":gStr1")
	gStr1 = type
	
	
	V_QBinAllPanels(type,popNum)


	String str,winStr="V_Combine_1D_Graph"
	sprintf str,"(\"%s\",%d,\"%s\")",type,popNum,winStr

// TODO:
// x- replace these calls -- they work with the 1d plot, not this panel. I want them to do basically the same
//    exact things, but with a different target window
//  *** these calls now take the target window as a parameter - so that there is only one version
	Execute ("V_Back_IQ_Graph"+str)
	Execute ("V_Middle_IQ_Graph"+str)
	Execute ("V_Front_IQ_Graph"+str)
		
	
	return(0)	
End


// function to control the drawing of buttons in the TabControl on the main panel
// Naming scheme for the buttons MUST be strictly adhered to... else buttons will 
// appear in odd places...
// all buttons are named C1DControl_NA where N is the tab number and A is the letter denoting
// the button's position on that particular tab.
// in this way, buttons will always be drawn correctly :-)
//
Function C1D_TabProc(ctrlName,tab) //: TabControl
	String ctrlName
	Variable tab

	String ctrlList = ControlNameList("",";"),item="",nameStr=""
	Variable num = ItemsinList(ctrlList,";"),ii,onTab
	for(ii=0;ii<num;ii+=1)
		//items all start w/"C1DControl_"		//11 characters
		item=StringFromList(ii, ctrlList ,";")
		nameStr=item[0,10]
		if(cmpstr(nameStr,"C1DControl_")==0)
			onTab = str2num(item[11])			//12th is a number
			ControlInfo $item
			switch(abs(V_flag))	
				case 1:
					Button $item,disable=(tab!=onTab)
					break
				case 2:	
					CheckBox $item,disable=(tab!=onTab)
					break
				case 5:	
					SetVariable $item,disable=(tab!=onTab)
					break
				case 10:	
					TitleBox $item,disable=(tab!=onTab)
					break
				case 4:
					ValDisplay $item,disable=(tab!=onTab)
					break
				case 3:
					PopupMenu $item,disable=(tab!=onTab)
					break
				// add more items to the switch if different control types are used
			endswitch
			
		endif
	endfor 
	
	// remove the mask if I go back to the data?
	if(tab==0)
		RemoveMask()
//		RemoveConcatenated()
	endif
	
	// masking
	if(tab==1)
		C1D_ClearMaskProc("")		//starts with a blank mask
		C1D_MyMaskProc("")		//start masking if you click on the tab
	else
		C1D_MaskDoneButton("")		//masking is done if you click off the tab
	endif
	
	// rescaling
	if(tab == 2)
	// TODO
	// -- fill this in
	// -- this is still in the thought process at this point
	
// do rescaling of the different sections of the data set
		
	endif
	
	return 0
End


Proc AppendConcatenated()

	if( strsearch(TraceNameList("V_Combine_1D_Graph", "", 1),"I_exp_orig",0,2) == -1)			//Igor 5
		SetDataFolder $(ksCombine1DFolder)
		AppendToGraph/W=V_Combine_1D_Graph I_exp_orig vs Q_exp_orig
		ModifyGraph mode(I_exp_orig)=3,marker(I_exp_orig)=19,msize(I_exp_orig)=2,opaque(I_exp_orig)=1
		ModifyGraph rgb(I_exp_orig)=(0,0,0)
		
		ModifyGraph tickUnit=1,log=1
		Modifygraph grid=1,mirror=2

		ErrorBars/T=0 I_exp_orig Y,wave=(S_exp_orig,S_exp_orig)
		
		setdatafolder root: 
	endif
end

Function RemoveConcatenated()

	SetDataFolder $(ksCombine1DFolder)
	RemoveFromGraph/W=V_Combine_1D_Graph/Z I_exp_orig
	setdatafolder root:
end

Proc AppendMask()

	if( strsearch(TraceNameList("V_Combine_1D_Graph", "", 1),"MaskData",0,2) == -1)			//Igor 5
		SetDataFolder $(ksCombine1DFolder)
		AppendToGraph/W=V_Combine_1D_Graph MaskData vs Q_exp_orig
		ModifyGraph mode(MaskData)=3,marker(MaskData)=8,msize(MaskData)=2.5,opaque(MaskData)=1
		ModifyGraph rgb(MaskData)=(65535,16385,16385)
		
		setdatafolder root: 
	endif
end



Function RemoveMask()

	SetDataFolder $(ksCombine1DFolder)
	RemoveFromGraph/W=V_Combine_1D_Graph/Z MaskData
	setdatafolder root:
end


// concatenate the data, and replace the multiple data sets with the concatenated set
// - then you can proceed to the mask tab
//
Function C1D_ConcatButtonProc(ctrlName) : ButtonControl
	String ctrlName


	ControlInfo C1DControl_0e
	String folderStr = S_Value

	SVAR gStr1 = $(ksCombine1DFolder+":gStr1")
	gStr1 = folderStr


	ControlInfo C1DControl_0d
	Variable binType = V_BinTypeStr2Num(S_Value)
	
	V_1DConcatenate(folderStr,binType)

// sort the data set
	V_TmpSort1D(folderStr)
	
// now copy the concatenated data over to the combine folder	
	Duplicate/O $("root:Packages:NIST:VSANS:"+folderStr+":tmp_q") $(ksCombine1DFolder+":Q_exp")		
	Duplicate/O $("root:Packages:NIST:VSANS:"+folderStr+":tmp_i") $(ksCombine1DFolder+":I_exp")		
	Duplicate/O $("root:Packages:NIST:VSANS:"+folderStr+":tmp_s") $(ksCombine1DFolder+":S_exp")	
	wave Q_exp = $(ksCombine1DFolder+":Q_exp")
	Wave I_exp = $(ksCombine1DFolder+":I_exp")
	Wave S_exp = $(ksCombine1DFolder+":S_exp")
	

//	
	Duplicate/O $(ksCombine1DFolder+":Q_exp") $(ksCombine1DFolder+":Q_exp_orig")
	Duplicate/O $(ksCombine1DFolder+":I_exp") $(ksCombine1DFolder+":I_exp_orig")
	Duplicate/O $(ksCombine1DFolder+":S_exp") $(ksCombine1DFolder+":S_exp_orig")
	wave I_exp_orig = $(ksCombine1DFolder+":I_exp_orig")
	
	Variable nq = numpnts($(ksCombine1DFolder+":Q_exp"))
//	

//	// append the (blank) wave note to the intensity wave
//	Note I_exp,"BOX=0;SPLINE=0;"
//	Note I_exp_orig,"BOX=0;SPLINE=0;"
//	
//	//add data to the graph
	Execute "AppendConcatenated()"	
	
	// TODO:
	// -- do I clear off the old data here, or somewhere else?
	// clear off the old data from the individual panels
	// use ClearAllIQIfDisplayed()
	ClearIQIfDisplayed_AllBin(folderStr,"V_Combine_1D_Graph")

	RemoveMask()
	
	return(0)
End

// step (1) - get the data from a WORK folder, and plot it
// clear out all of the "old" waves, remove them from the graph first
//
// ??produces Q_exp, I_exp, S_exp waves (and originals "_orig")
// add a dummy wave note that can be changed on later steps
//
Function C1D_LoadButtonProc(ctrlName) : ButtonControl
	String ctrlName


	String qStr,iStr,sStr,sqStr
	Variable nq,dqv,numBad,val
	
	// remove any of the old traces on the graph and delete the waves and reset the global strings
	CleanUpJunk()
	
	SetDataFolder root:
	
	// go get the new data
	Execute "A_LoadOneDDataWithName(\"\",0)"

// TODO:	
	// x-Missing something here from the loader - go back to the LakeDesmearing ipf
	SVAR fname = root:Packages:NIST:gLastFileName		//this is the 1D file loaded

//	
	qStr = CleanupName((fName + "_q"),0)		//the q-wave
	iStr = CleanupName((fName + "_i"),0)		//the i-wave
	sStr = CleanupName((fName + "_s"),0)		//the s-wave
//	sqStr = CleanupName((fName + "sq"),0)		//the sq-wave
//
	String DFStr= CleanupName(fname,0)
//	
	Duplicate/O $("root:"+DFStr+":"+qStr) $(ksCombine1DFolder+":Q_exp")		
	Duplicate/O $("root:"+DFStr+":"+iStr) $(ksCombine1DFolder+":I_exp")		
	Duplicate/O $("root:"+DFStr+":"+sStr) $(ksCombine1DFolder+":S_exp")	
	wave Q_exp = $(ksCombine1DFolder+":Q_exp")
	Wave I_exp = $(ksCombine1DFolder+":I_exp")
	Wave S_exp = $(ksCombine1DFolder+":S_exp")
	

//	
	Duplicate/O $(ksCombine1DFolder+":Q_exp") $(ksCombine1DFolder+":Q_exp_orig")
	Duplicate/O $(ksCombine1DFolder+":I_exp") $(ksCombine1DFolder+":I_exp_orig")
	Duplicate/O $(ksCombine1DFolder+":S_exp") $(ksCombine1DFolder+":S_exp_orig")
	wave I_exp_orig = $(ksCombine1DFolder+":I_exp_orig")
	
	nq = numpnts($(ksCombine1DFolder+":Q_exp"))
//	

//	// append the (blank) wave note to the intensity wave
//	Note I_exp,"BOX=0;SPLINE=0;"
//	Note I_exp_orig,"BOX=0;SPLINE=0;"
//	
//	//add data to the graph
	Execute "AppendConcatenated()"
	
	SetDataFolder root:
End

// remove any q-values <= val
Function RemoveBadQPoints(qw,iw,sw,val)
	Wave qw,iw,sw
	Variable val
	
	Variable ii,num,numBad,qval
	num = numpnts(qw)
	
	ii=0
	numBad=0
	do
		qval = qw[ii]
		if(qval <= val)
			numBad += 1
		else		//keep the points
			qw[ii-numBad] = qval
			iw[ii-numBad] = iw[ii]
			sw[ii-numBad] = sw[ii]
		endif
		ii += 1
	while(ii<num)
	//trim the end of the waves
	DeletePoints num-numBad, numBad, qw,iw,sw
	return(numBad)
end

// if mw = Nan, keep the point, if a numerical value, delete it
Function RemoveMaskedPoints(mw,qw,iw,sw)
	Wave mw,qw,iw,sw
	
	Variable ii,num,numBad,mask
	num = numpnts(qw)
	
	ii=0
	numBad=0
	do
		mask = mw[ii]
		if(numtype(mask) != 2)		//if not NaN
			numBad += 1
		else		//keep the points that are NaN
			qw[ii-numBad] = qw[ii]
			iw[ii-numBad] = iw[ii]
			sw[ii-numBad] = sw[ii]
		endif
		ii += 1
	while(ii<num)
	//trim the end of the waves
	DeletePoints num-numBad, numBad, qw,iw,sw
	return(numBad)
end

// produces the _msk waves that have the new number of data points
//
Function C1D_MaskDoneButton(ctrlName) : ButtonControl
	String ctrlName


	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	if(!aExists)
		return(1)		//possibly reverted data, no cursor, no Mask wave
	endif
	
	Duplicate/O $(ksCombine1DFolder+":Q_exp_orig"),$(ksCombine1DFolder+":Q_msk")
	Duplicate/O $(ksCombine1DFolder+":I_exp_orig"),$(ksCombine1DFolder+":I_msk")
	Duplicate/O $(ksCombine1DFolder+":S_exp_orig"),$(ksCombine1DFolder+":S_msk")
	Wave Q_msk=$(ksCombine1DFolder+":Q_msk")
	Wave I_msk=$(ksCombine1DFolder+":I_msk")
	Wave S_msk=$(ksCombine1DFolder+":S_msk")
	
	//finish up - trim the data sets and reassign the working set
	Wave MaskData=$(ksCombine1DFolder+":MaskData")
	
	RemoveMaskedPoints(MaskData,Q_msk,I_msk,S_msk)

	//reset the number of points
	NVAR gNq = $(ksCombine1DFolder+":gNq")
	gNq = numpnts(Q_msk)
	
	Cursor/K A
	HideInfo
	
	return(0)
End


// not quite the same as revert
Function C1D_ClearMaskProc(ctrlName) : ButtonControl
	String ctrlName
	
	SetDataFolder $ksCombine1DFolder
	
	Wave Q_exp_orig
	Duplicate/O Q_exp_orig MaskData
	MaskData = NaN		//use all data
			
	SetDataFolder root:

	return(0)
end

// when the mask tab is selected, A must be on the graph
// Displays MaskData wave on the graph
//
Function C1D_MyMaskProc(ctrlName) : ButtonControl
	String ctrlName
	
	
	Wave data=$(ksCombine1DFolder+":I_exp_orig")
	
	SetDataFolder $ksCombine1DFolder
	
	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
		
	if(aExists)		//mask the selected point
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[pcsr(A)] = (numType(MaskData[pcsr(A)])==0) ? NaN : data[pcsr(A)]		//if NaN, doesn't plot 
	else
		Wave I_exp_orig,Q_exp_orig
		Cursor /A=1/H=1/L=1/P/W=V_Combine_1D_Graph A I_exp_orig leftx(I_exp_orig)
		ShowInfo
		//if the mask wave does not exist, make one
		if(exists("MaskData") != 1)
			Duplicate/O Q_exp_orig MaskData
			MaskData = NaN		//use all data
		endif
		Execute "AppendMask()"	
	endif

	SetDataFolder root:

	return(0)
End

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function C1D_MaskLTCursor(ctrlName) : ButtonControl
	String ctrlName

		
	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	
	if(!aExists)
		return(1)
	endif
// need to get rid of old smoothed data if data is re-masked
//	Execute "RemoveSmoothed()"
//	SetDataFolder $(ksCombine1DFolder)
//	Killwaves/Z I_smth,Q_smth,S_smth

	SetDataFolder $(ksCombine1DFolder)

	Wave data=I_exp_orig

	Variable pt,ii
	pt = pcsr(A)
	for(ii=pt;ii>=0;ii-=1)
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[ii] = (numType(MaskData[ii])==0) ? NaN : data[ii]		//if NaN, doesn't plot 
	endfor

	SetDataFolder root:
	return(0)
End

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function C1D_MaskGTCursor(ctrlName) : ButtonControl
	String ctrlName
	
	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	
	if(!aExists)
		return(1)
	endif
// need to get rid of old smoothed data if data is re-masked
//	Execute "RemoveSmoothed()"
//	SetDataFolder $(ksCombine1DFolder)
//	Killwaves/Z I_smth,Q_smth,S_smth

	SetDataFolder $(ksCombine1DFolder)

	Wave data=I_exp_orig
	
	Wave MaskData

	Variable pt,ii,endPt
	endPt=numpnts(MaskData)
	pt = pcsr(A)
	for(ii=pt;ii<endPt;ii+=1)
		// toggle NaN (keep) or Data value (= masked)
		Wave MaskData
		MaskData[ii] = (numType(MaskData[ii])==0) ? NaN : data[ii]		//if NaN, doesn't plot 
	endfor

	SetDataFolder root:

	return(0)
End

// when the mask button is pressed, A must be on the graph
// Displays MaskData wave on the graph
//
Function C1D_MaskPercent(ctrlName) : ButtonControl
	String ctrlName
	
	Variable aExists= strlen(CsrInfo(A)) > 0			//Igor 5
	
	if(!aExists)
		return(1)
	endif


	SetDataFolder $(ksCombine1DFolder)

	Wave data=I_exp_orig
	Wave s_orig = S_exp_orig
	Wave MaskData


	Variable pct,ii,endPt
	endPt=numpnts(MaskData)

	pct = 0.05
	
	for(ii=0;ii<endPt;ii+=1)
		// toggle NaN (keep) or Data value (= masked)

		MaskData[ii] = (abs(s_orig[ii]/data[ii]) < pct) ? NaN : data[ii]		//if NaN, doesn't plot 
	endfor


	SetDataFolder root:

	return(0)
End




Function CleanUpJunk()

	// clean up the old junk on the graph, /Z for no error
	// TODO:
	// -- activate both of these functions to clean old data off of the graph
//	Execute "RemoveOldData()"
	Execute "RemoveMask()"
	
	//remove the cursor
	Cursor/K A
	
	//always re-initialize these
	String/G $(ksCombine1DFolder+":gStr1") = ""

	// clean up the old waves from smoothing and desmearing steps
	SetDataFolder $(ksCombine1DFolder)
	Killwaves/Z MaskData,Q_msk,I_msk,S_msk
	SetDataFolder root:
End



// I_dsm is the desmeared data
//
// step (7) - desmearing is done, write out the result
//
Function C1D_SaveButtonProc(ctrlName) : ButtonControl
	String ctrlName


	String saveStr
	SVAR curFile = $(ksCombine1DFolder+":gCurFile")
	saveStr = CleanupName((curFile),0)		//the output filename
	//

	V_Write_VSANSMasked1D(saveStr,0,0,1)			//use the full set (lo=hi=0) and present a dialog
	
	SetDataFolder root:
	return(0)
End

Function C1D_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "Combining VSANS Data"
	if(V_flag !=0)
		DoAlert 0,"The Combining VSANS Data Help file could not be found"
	endif
	return(0)
End


//toggles the log/lin display of the loaded data set
Function C1D_LoadCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	ModifyGraph log=(checked)
	return(0)
End





// TODO:
// -- either update this to be correct for VSANS, or dispatch to some other data writer.
//
Function V_Write_VSANSMasked1D(fullpath,lo,hi,dialog)
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	
	String termStr="\r\n"
	String destStr = ksCombine1DFolder
	String formatStr = "%15.6g %15.6g %15.6g %15.6g %15.6g %15.6g"+termStr
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE Q_msk=$(destStr + ":Q_msk")
	WAVE I_msk=$(destStr + ":I_msk")
	WAVE S_msk=$(destStr + ":S_msk")
	
	//check each wave
	If(!(WaveExists(Q_msk)))
		Abort "Q_msk DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(I_msk)))
		Abort "I_msk DNExist in WriteUSANSDesmeared()"
	Endif
	If(!(WaveExists(S_msk)))
		Abort "S_msk DNExist in WriteUSANSDesmeared()"
	Endif
	
	// TODO:
	// -- this remnant from desmearing creates fake resolution waves!!!
	// -- correctly handle the input resolution waves
	// make dummy waves to hold the "fake" resolution, and write it as the last 3 columns
	//
	Duplicate/O Q_msk,res1,res2,res3
	res3 = 1		// "fake" beamstop shadowing
	res1 /= 100		//make the sigmaQ so small that there is no smearing
	
	if(dialog)
		Open/D refnum as fullpath+".cmb"		//won't actually open the file
		If(cmpstr(S_filename,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		fullpath = S_filename
	Endif
	
	//write out partial set?
	Duplicate/O Q_msk,tq,ti,te
	ti=I_msk
	te=S_msk
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=Q_msk[p+lo]
		ti=I_msk[p+lo]
		te=S_msk[p+lo]
	endif
	
	//tailor the output given the type of data written out...
	String samStr="",dateStr="",str1,str2

	
	samStr = fullpath
	dateStr="CREATED: "+date()+" at  "+time()


	
	//actually open the file
	Open refNum as fullpath
	
	fprintf refnum,"%s"+termStr,samStr
//	fprintf refnum,"%s"+termStr,str1
//	fprintf refnum,"%s"+termStr,str2
	fprintf refnum,"%s"+termStr,dateStr
	
	wfprintf refnum, formatStr, tq,ti,te,res1,res2,res3
	
	Close refnum
	
	Killwaves/Z ti,tq,te,res1,res2,res3
	
	Return(0)
End




Function V_GetScalingInOverlap(num2,wave1q,wave1i,wave2q,wave2i)
	Variable num2		//largest point number of wave2 in overlap region
	Wave wave1q,wave1i,wave2q,wave2i		//1 = first dataset, 2= second dataset

	Variable ii,ival1,newi,ratio
	ratio=0
	ii=0
	do
		//get scaling factor at each point of wave 2 in the overlap region
		newi = interp(wave2q[ii],wave1q,wave1i)		//get the intensity of wave1 at an overlap point
		ratio += newi/wave2i[ii]					//get the scale factor
		//Print "ratio = ",ratio
		ii+=1
	while(ii<=num2)
	Variable val
	val = ratio/(num2+1)		// +1 counts for point zero
	//Print "val = ",val

	Variable tol=1.05			//5% is the preferred number (for Andrew and Lionel, at least)

//	ControlInfo/W=NSORT_Panel WarningCheck
//	if(( V_Value==1 ) && ( (val > tol) || (val < 1/tol) ) )
//		String str=""
//		sprintf str,"The scaling factor is more than a factor of %g from 1. Proceed with caution.\r",tol
//		DoAlert 0,str
//	endif
	
	Return val
End