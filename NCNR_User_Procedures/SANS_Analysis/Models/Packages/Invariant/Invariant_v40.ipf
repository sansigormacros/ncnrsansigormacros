#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.0

// 07 JAN 05 SRK
// updated procedures (from SS 2002) to be used as a package
// with the SANS analysis routines
//
// need to:
// - verify accuracy (see John)

// this is the main entry point for the panel
Proc Make_Invariant_Panel()
	DoWindow/F Invariant_Panel
	if(V_flag==0)
		//create global variables in root:myGlobals:invariant
		Init_Invariant()
		Invariant_Panel()
	endif
	//pop the file menu
	Inv_FilePopMenuProc("",1,"")
End

//create the globals
Proc Init_Invariant()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:NIST
	NewDataFolder/O/S root:Packages:NIST:invariant
	Variable/G gNumLow=10
	Variable/G gNumHigh=10
	
	Variable/G gInvMeas=0
	Variable/G gInvLowQ=0
	Variable/G gInvHighQ=0
	Variable/G gInvTotal=0
	String/G gDataPopList = "none"
	Variable/G gIsSlitSmeared=0
	Variable/G gDqv = 0.117		//default value for USANS slit height (re-read from file)
		
	SetDataFolder root:
End

// for testing - compare to the "perfect" value. This macro
// calculates the invariant based on the contrast and volume fraction
// - the extrapolated/integrated value should match this...
Macro PrintModelInvariant(delta_rho,phi)
	Variable delta_rho=3e-6,phi=0.1
	// delta_rho [=] 1/A^2
	Variable inv
	inv = 2*pi*pi*delta_rho*delta_rho*phi*(1-phi)*1e8
	
	Printf "The model invariant is %g Å^-3 cm^-1\r\r",inv
End


//integrates only over the given q-range, does no interpolation
Function Invariant(qw,iw)
	Wave qw,iw
	
	Variable num,invar
	Duplicate/O qw integrand
	integrand = qw*qw*iw
//	integrand /= 1e8 		//convert 1/cm to 1/A
	
	num = numpnts(qw)
	invar = areaXY(qw,integrand,qw[0],qw[num-1])
	
	return(invar)		//units of Å^-3 cm^-1
End

//integrates only over the given q-range, does no interpolation
// function is for slit smeared data
Function Invariant_SlitSmeared(qw,iw)
	Wave qw,iw
	
	Variable num,invar
	NVAR dQv = root:Packages:NIST:invariant:gDqv
	
	Duplicate/O qw integrand
	integrand = qw*iw
//	integrand /= 1e8 		//convert 1/cm to 1/A
	
	num = numpnts(qw)
	invar = areaXY(qw,integrand,qw[0],qw[num-1])
	
	invar *= dQv		//correct for the effects of slit-smearing
		
	return(invar)		//units of Å^-3 cm^-1
End

Function Guinier_Fit(w,x) : FitFunc
	Wave w
	Variable x
	
	//fit data to I(q) = A*exp(B*q^2)
	// (B will be negative)
	//two parameters
	Variable a,b,ans
	a=w[0]
	b=w[1]
	ans = a*exp(b*x*x)
	return(ans)
End


//pass the wave with the q-values
Function SetExtrWaves(w)
	Wave w

	Variable num_extr=100
	
	Make/O/D/N=(num_extr) extr_hqq,extr_hqi,extr_lqq,extr_lqi
	extr_lqi=1
	extr_hqi=1		//default values
	//set the q-range
	Variable qmax,qmin,num
	qmax=10
	qmin=0
	num=numpnts(w)
	
	extr_hqq = w[num-1] + x * (qmax-w[num-1])/num_extr
	extr_lqq = qmin + x * (w[0]-qmin)/num_extr
	
	return(0)
End

Function DoExtrapolate(qw,iw,sw,nbeg,nend)
	Wave qw,iw,sw
	Variable nbeg,nend
	
	Wave extr_lqi=extr_lqi
	Wave extr_lqq=extr_lqq
	Wave extr_hqi=extr_hqi
	Wave extr_hqq=extr_hqq
	Variable/G V_FitMaxIters=300
	Variable num=numpnts(iw)
	
	Make/O/D G_coef={100,-100}		//input
	FuncFit Guinier_Fit G_coef iw[0,(nbeg-1)] /X=qw /W=sw /D 
	extr_lqi= Guinier_Fit(G_coef,extr_lqq)
	
	Printf "I(q=0) = %g (1/cm)\r",G_coef[0]
	Printf "Rg = %g (Å)\r",sqrt(-3*G_coef[1])
	
	Make/O/D P_coef={0,1,-4}			//input
	//(set background to zero and hold fixed)
	CurveFit/H="100" Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /D 
	extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]
	
	Printf "Power law exponent = %g\r",P_coef[2]
	Printf "Pre-exponential = %g\r",P_coef[1]
	
	return(0)
End

//plot based on the wave selelctions
Function Plot_Inv_Data(ctrlName) : ButtonControl
	String ctrlName
	
	//access the global strings representing the last data file read in
	SVAR QWave = root:Packages:NIST:invariant:QWave
	SVAR IWave = root:Packages:NIST:invariant:IWave
	SVAR SWave = root:Packages:NIST:invariant:SWave
	
	Wave qw=$QWave
	Wave iw=$IWave
	Wave sw=$SWave
	
	String str="",item=""
	Variable num=0,ii
	
	//not used - just kill and re-draw
	//remove everything from the graph and graph it again
//	str = TraceNameList("",";",1)
//	num=ItemsInList(str)
//	for(ii=0;ii<num;ii+=1)
//		item=StringFromList(ii, str  ,";")
//		Print item
//		RemoveFromGraph $item
//	endfor

	DoWindow/F invariant_graph
	if(V_flag==1)
		DoWindow/K invariant_graph
	endif
	Display /W=(5,44,375,321)/K=1 iw vs qw
	DoWindow/C invariant_graph
	ModifyGraph mode=3,marker=8
	ModifyGraph grid=1
	ModifyGraph log=1
	ModifyGraph mirror=2
	ModifyGraph standoff=0
	Label left "Intensity (1/cm)"
	Label bottom "q (1/Å)"
	ModifyGraph rgb($NameofWave(iw))=(0,0,0)
	ModifyGraph opaque($NameofWave(iw))=1
	ErrorBars $NameofWave(iw) Y,wave=(sw,sw)
	Legend
	
//	Print TraceNameList("",";",1)
	
	//create the extra waves now, and add to plot
	SetExtrWaves(qw)
	Wave extr_lqi=extr_lqi
	Wave extr_lqq=extr_lqq
	Wave extr_hqi=extr_hqi
	Wave extr_hqq=extr_hqq
	AppendtoGraph extr_lqi vs extr_lqq
	AppendtoGraph extr_hqi vs extr_hqq
	ModifyGraph lSize(extr_lqi)=2,lSize(extr_hqi)=2
	ModifyGraph rgb($NameofWave(iw))=(0,0,0),rgb(extr_hqi)=(2,39321,1)
	
	//reset the invariant values to zero
	NVAR meas = root:Packages:NIST:invariant:gInvMeas
	NVAR lo = root:Packages:NIST:invariant:gInvLowQ
	NVAR hi = root:Packages:NIST:invariant:gInvHighQ
	NVAR total = root:Packages:NIST:invariant:gInvTotal
	meas=0
	lo=0
	hi=0
	total=0
	
	return(0)
End


Function LowCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	Variable val=0
//	print "checked = ",checked
	if(cmpstr(ctrlName,"check_0")==0)
		if(checked)
			val=1
		endif
	endif
	CheckBox check_0,value= Val==1
	CheckBox check_1,value= Val==0
End


Proc Invariant_Panel()
	SetDataFolder root:		//use absolute paths?
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(510,44,796,529)	/K=2
	DoWindow/C Invariant_Panel
	ModifyPanel cbRGB=(65535,43690,0)
	SetDrawLayer UserBack
	DrawText 23,196,"Extrapolation"
	DrawText 158,195,"Power-Law"
	DrawText 158,211,"Extrapolation"
	SetDrawEnv fstyle= 1
	DrawText 58,349,"Units are [Å^-3 cm^-1]"
	SetDrawEnv fstyle= 1
	DrawText 61,16,"Calculate the Invariant"
	DrawLine 16,135,264,135
	DrawLine 16,19,264,19
	
	PopupMenu ywave,pos={10,60},size={154,19},title="Data File"
	PopupMenu ywave,help={"Select the experimental intensity values"}
	PopupMenu ywave,mode=1,value=root:Packages:NIST:invariant:gDataPopList,proc=Inv_FilePopMenuProc
	
	Button loadButton,pos={10,90},size={130,20},proc=Inv_Load_Proc,title="Load and Plot File"
	Button loadButton,help={"After choosing a file, load it into memory and plot it with this button."}
	
	Button Inv_PathButton,pos={10,29},size={80,20},proc=Inv_PickPathButtonProc,title="Pick Path"
	Button DoneButton,pos={215,453},size={50,20},proc=InvDoneButton,title="Done"
	Button DoneButton,help={"This button will close the panel and the associated graph"}

	SetVariable setvar_0,pos={27,249},size={80,15},title="# points"
	SetVariable setvar_0,limits={5,50,0},value= root:Packages:NIST:invariant:gNumLow
	SetVariable setvar_1,pos={166,249},size={80,15},title="# points"
	SetVariable setvar_1,limits={5,200,0},value= root:Packages:NIST:invariant:gNumHigh
	CheckBox check_0,pos={23,202},size={50,14},proc=LowCheckProc,title="Guinier"
	CheckBox check_0,value= 1
	CheckBox check_1,pos={23,223},size={68,14},proc=LowCheckProc,title="Power Law"
	CheckBox check_1,value= 0
	Button button_0,pos={29,275},size={90,20},proc=InvLowQ,title="Calc Low Q"
	Button button_1,pos={56,141},size={170,20},proc=InvMeasQ,title="Calculate Measured Q"
	Button button_2,pos={168,275},size={90,20},proc=InvHighQ,title="Calc High Q"
//	Button button_3,pos={13,98},size={50,20},proc=Plot_Inv_Data,title="Plot"
	Button button_4,pos={230,29},size={25,20},proc=Inv_HelpButtonProc,title="?"
	GroupBox group0,pos={14,165},size={123,144},title="Low Q"
	GroupBox group0_1,pos={147,165},size={123,144},title="High Q"
	GroupBox group1,pos={23,318},size={239,124},title="INVARIANT"
	ValDisplay valdisp0,pos={51,354},size={180,14},title="In measured Q-range "
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:Packages:NIST:invariant:gInvMeas"
	ValDisplay valdisp0_1,pos={51,371},size={180,14},title="In low Q extrapolation "
	ValDisplay valdisp0_1,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0_1,value= #"root:Packages:NIST:invariant:gInvLowQ"
	ValDisplay valdisp0_2,pos={51,388},size={180,14},title="In high Q extrapolation "
	ValDisplay valdisp0_2,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0_2,value= #"root:Packages:NIST:invariant:gInvHighQ"
	ValDisplay valdisp0_3,pos={51,411},size={180,14},title="TOTAL "
	ValDisplay valdisp0_3,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0_3,value= #"root:Packages:NIST:invariant:gInvTotal"
	
	CheckBox check0,pos={10,116},size={101,14},proc=SlitSmearedCheckProc,title="Slit-Smeared Data"
	CheckBox check0,value= root:Packages:NIST:invariant:gIsSlitSmeared
	SetVariable setvar0,pos={136,116},size={130,15},title="Slit Height (1/A)"
	SetVariable setvar0,limits={-inf,inf,0},value= root:Packages:NIST:invariant:gDqv
	
	//set up a dependency to calculate the total invariant
	root:Packages:NIST:invariant:gInvTotal := root:Packages:NIST:invariant:gInvLowQ + root:Packages:NIST:invariant:gInvMeas + root:Packages:NIST:invariant:gInvHighQ
EndMacro


Function InvMeasQ(ctrlName) : ButtonControl
	String ctrlName
	
	//no graph, get out
	DoWindow/F Invariant_Graph
	if(V_flag==0)
		return(0)
	endif
	
	//do the straight calculation of the invariant of the specified data
	Variable inv,num
	
	SVAR QWave = root:Packages:NIST:invariant:QWave
	Wave qw=$QWave
	SVAR IWave = root:Packages:NIST:invariant:IWave
	Wave iw=$IWave
	
	NVAR isSlitSmeared=root:Packages:NIST:invariant:gIsSlitSmeared
	if(isSlitSmeared)
		inv = Invariant_SlitSmeared(qw,iw)
	else
		inv = Invariant(qw,iw)
	endif
	
	num=numpnts(qw)
	Printf "The invariant over the measured q-range %g to %g is %g Å^-3 cm^-1\r\r",qw[0],qw[(num-1)],inv
	
	// update the global display on the panel (there is a dependency for the total)
	NVAR val = root:Packages:NIST:invariant:gInvMeas
	val = inv
	
	return(0)
End

Function InvLowQ(ctrlName) : ButtonControl
	String ctrlName
	
	//no graph, get out
	DoWindow/F Invariant_Graph
	if(V_flag==0)
		return(0)
	endif
	
	Variable yesGuinier=0,nume,inv
	// do the extrapolation of the correct type
	ControlInfo/W=Invariant_Panel check_0		//the Guinier box
	yesGuinier = V_Value
//	print "yesGuinier = ",yesGuinier
	//number of points to use for fit
	NVAR nbeg=root:Packages:NIST:invariant:gNumLow
	//define the waves
	Wave extr_lqi=extr_lqi
	Wave extr_lqq=extr_lqq
	
	SVAR QWave = root:Packages:NIST:invariant:QWave
	Wave qw=$QWave
	SVAR IWave = root:Packages:NIST:invariant:IWave
	Wave iw=$IWave
	SVAR SWave = root:Packages:NIST:invariant:SWave
	Wave sw=$SWave
	
	Wave/Z W_coef=W_coef
	Variable/G V_FitMaxIters=300
//	Variable numi=numpnts(iw)
	
	if(yesGuinier)
		Make/O/D G_coef={1000,-1000}		//input
		FuncFit Guinier_Fit G_coef iw[0,(nbeg-1)] /X=qw /W=sw /D 
		extr_lqi= Guinier_Fit(G_coef,extr_lqq)
		
		Printf "I(q=0) = %g (1/cm)\r",G_coef[0]
		Printf "Rg = %g (Å)\r",sqrt(-3*G_coef[1])
	else
		//do a power-law fit instead
		Make/O/D P_coef={0,1,-1}			//input
		//(set background to zero and hold fixed)
		CurveFit/H="100" Power kwCWave=P_coef  iw[0,(nbeg-1)] /X=qw /W=sw /D 
		extr_lqi=P_coef[0]+P_coef[1]*extr_lqq^P_coef[2]
		//	
		Printf "Pre-exponential = %g\r",P_coef[1]
		Printf "Power law exponent = %g\r",P_coef[2]
		//	
	endif
	
	//calculate the invariant
	NVAR isSlitSmeared=root:Packages:NIST:invariant:gIsSlitSmeared
	if(isSlitSmeared)
		inv = Invariant_SlitSmeared(extr_lqq,extr_lqi)
	else
		inv = Invariant(extr_lqq,extr_lqi)
	endif
	
	nume=numpnts(extr_lqq)
	Printf "The invariant over the q-range %g to %g is %g Å^-3 cm^-1\r\r",extr_lqq[0],extr_lqq[(nume-1)],inv
	
	// update the global display on the panel (there is a dependency for the total)
	NVAR val = root:Packages:NIST:invariant:gInvLowQ
	val = inv
	
	return(0)
End

Function InvHighQ(ctrlName) : ButtonControl
	String ctrlName
	
	//no graph, get out
	DoWindow/F Invariant_Graph
	if(V_flag==0)
		return(0)
	endif
	
	// do the power-law extrapolation
	
	Wave extr_hqi=extr_hqi
	Wave extr_hqq=extr_hqq
	SVAR QWave = root:Packages:NIST:invariant:QWave
	Wave qw=$QWave
	SVAR IWave = root:Packages:NIST:invariant:IWave
	Wave iw=$IWave
	SVAR SWave = root:Packages:NIST:invariant:SWave
	Wave sw=$SWave
	
	Variable/G V_FitMaxIters=300
	Variable num=numpnts(iw),nume,inv
	NVAR nend=root:Packages:NIST:invariant:gNumHigh		//number of points for the fit

	Make/O/D P_coef={0,1,-4}			//input
	//(set background to zero and hold fixed)
	CurveFit/H="100" Power kwCWave=P_coef  iw[(num-1-nend),(num-1)] /X=qw /W=sw /D 
	extr_hqi=P_coef[0]+P_coef[1]*extr_hqq^P_coef[2]
	
	Printf "Pre-exponential = %g\r",P_coef[1]
	Printf "Power law exponent = %g\r",P_coef[2]
	
	//calculate the invariant
	NVAR isSlitSmeared=root:Packages:NIST:invariant:gIsSlitSmeared
	if(isSlitSmeared)
		inv = Invariant_SlitSmeared(extr_hqq,extr_hqi)
	else
		inv = Invariant(extr_hqq,extr_hqi)
	endif

	nume=numpnts(extr_hqq)
	Printf "The invariant over the q-range %g to %g is %g Å^-3 cm^-1\r\r",extr_hqq[0],extr_hqq[(nume-1)],inv
	
	// update the global display on the panel (there is a dependency for the total)
	NVAR val = root:Packages:NIST:invariant:gInvHighQ
	val = inv
	
	return(0)	
End

Function UnloadInvariant()
	if (WinType("Invariant_Panel") == 7)
		DoWindow/K Invariant_Panel
	endif
	if (WinType("Invariant_Graph") != 0)
		DoWindow/K $"Invariant_Graph"
	endif
	if (DatafolderExists("root:Packages:NIST:invariant"))
		KillDatafolder root:Packages:NIST:invariant
	endif
	SetDataFolder root:
	Killwaves/Z integrand,G_coef,P_coef,extr_hqq,extr_hqi,extr_lqq,extr_lqi
	
	SVAR fileVerExt=root:Packages:NIST:SANS_ANA_EXTENSION
	String fname="Invariant"
	Execute/P "DELETEINCLUDE \""+fname+fileVerExt+"\""
	Execute/P "COMPILEPROCEDURES "
end

Menu "SANS Models"
	Submenu "Packages"
		"Unload Invariant", UnloadInvariant()
	End
end

Function Inv_HelpButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayHelpTopic/Z/K=1 "Calculate Scattering Invariant"
	if(V_flag != 0)
		DoAlert 0, "The Scattering Invariant Help file can not be found"
	endif
End

Function Inv_PickPathButtonProc(ctrlName) : ButtonControl
	String ctrlName

	A_PickPath()
	//pop the file menu
	Inv_FilePopMenuProc("",1,"")
End

//gets a valid file list (simply not the files with ".SAn" in the name)
//
Function Inv_FilePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String tempStr=Inv_filterButtonProc(ctrlName)
	if(strlen(tempStr)==0)
		tempStr = "Pick the data path"
	Endif
	String/G root:Packages:NIST:invariant:gDataPopList =tempStr
	ControlUpdate/W=Invariant_Panel ywave
	
End

//function called byt the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// could also use the alternate procedure of keeping only file with the proper extension
//
Function/S Inv_filterButtonProc(ctrlName)
	String ctrlName

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the invariant panel"
		Return("")
	Endif
	
	list = IndexedFile(catpathName,-1,"????")
	num=ItemsInList(list,";")
	//print "num = ",num
	for(ii=(num-1);ii>=0;ii-=1)
		item = StringFromList(ii, list  ,";")
		//simply remove all that are not raw data files (SA1 SA2 SA3)
		if( !stringmatch(item,"*.SA1*") && !stringmatch(item,"*.SA2*") && !stringmatch(item,"*.SA3*") )
			if( !stringmatch(item,".*") && !stringmatch(item,"*.pxp") && !stringmatch(item,"*.DIV"))		//eliminate mac "hidden" files, pxp, and div files
				newlist += item + ";"
			endif
		endif
	endfor
	//remove VAX version numbers
	newList = A_RemoveVersNumsFromList(newList)
	//sort
	newList = SortList(newList,";",0)

	return newlist
End

// Loads the selected file for fitting
// and graphs the data as needed
Proc Inv_Load_Proc(ctrlName): ButtonControl
	String ctrlName
	
	//Load the data
	String tempName="",partialName=""
	Variable err
	ControlInfo/W=Invariant_Panel ywave
	//find the file from the partial filename
	If( (cmpstr(S_value,"")==0) || (cmpstr(S_value,"none")==0) )
		//null selection, or "none" from any popup
		Abort "no file selected in popup menu"
	else
		//selection not null
		partialName = S_value
		//Print partialName
	Endif
	//get a valid file based on this partialName and catPathName
	tempName = A_FindValidFilename(partialName)

	//prepend path to tempName for read routine 
	PathInfo catPathName
	
	tempName = S_path + tempName
	
	//load in the data (into the root directory)
	A_LoadOneDDataWithName(tempName,0)
	//Print S_fileName
	//Print tempName
	
	String cleanLastFileName = CleanupName(root:Packages:NIST:gLastFileName,0)
	String dataStr = "root:"+cleanLastFileName+":"
	
	// keep global copies of the names rather than reading from the popup
	tempName=dataStr + cleanLastFileName+"_q"
	String/G root:Packages:NIST:invariant:QWave=tempName
	tempName=dataStr + cleanLastFileName+"_i"
	String/G root:Packages:NIST:invariant:IWave=tempName
	tempName=dataStr + cleanLastFileName+"_s"
	String/G root:Packages:NIST:invariant:SWave=tempName

	//Plot, and adjust the scaling to match the axis scaling set by the popups
	Plot_Inv_Data("")

	//if the slit-smeared box is checked, try to read the slit height
	// - if can't find it, maybe not really smeared data, so put up the Alert
	ControlInfo/W=Invariant_Panel check0
	if(V_Value==1)
		SlitSmearedCheckProc("",1)
	endif
End

Proc InvDoneButton(ctrlName): ButtonControl
	String ctrlName
	DoWindow/K Invariant_Graph
	DoWindow/K Invariant_Panel
end

//get the slit height if the data is slit-smeared
//set the globals as needed
Function SlitSmearedCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	NVAR isSlitSmeared=root:Packages:NIST:invariant:gIsSlitSmeared
	SVAR fileStr=root:Packages:NIST:gLastFileName
	
	//reset the global to the checkbox state
	isSlitSmeared = checked		//==0 if the data is not slit smeared
	
	if(checked)		//get the smearing info
		String cleanLastFileName = "root:"+CleanupName(fileStr,0)
		NVAR dQv=root:Packages:NIST:invariant:gDqv
		String tempName = cleanLastFileName+"sq"
		Wave/Z w=$tempName
		if(WaveExists(w) && w[0] < 0)
			dQv = - w[0]
			Print "Data is slit-smeared, dqv = ",w[0]
		else
			DoAlert 0,"Can't find the slit height from the data. Enter the value manually if the data is truly slit-smeared, or uncheck the box."
		endif
	endif
	
	return(0) 
End
