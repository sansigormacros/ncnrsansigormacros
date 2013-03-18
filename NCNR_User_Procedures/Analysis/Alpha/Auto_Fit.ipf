#pragma rtGlobals=1		// Use modern global access method.


// This was originally written 2001-2003 ish. This works very differently than SANSview, and I havne't
// mentioned that this exists, so that their ideas will be new. Still, some of this may be 
// serviceable for use within the Igor package, with some cleanup of the interface and functionality.
//
//
//
// to do - July 2010
//
// X- smeared models don't work at all (now they work)
// -- the report is good, but the parsing is not great - the format
//    	could be more convenient to read back in to a table (text col, num cols (matrix that can be plotted?)
//	-- Maybe the report could be compiled as waves. Then they would be numeric. Nothing to plot them against
//			other than file names, but with a table of values and names, one could manually enter a meaningful
//			column of values to plot against.
// -- Make_HoldConstraintEps_Waves() is  currently disabled, both on the macros menu and the checkbox on the panel
//			Constraints and holds are part of the matrix already, soo this would only be for epsilon
// -- Many of the items on the Macros menu are just junk.
//
// -- Comprehensive instructions (after features are finalized)
//
// -- savePath seems to be obsolete. Report saving is sent to the procedure defined in Wrapper.ipf, and uses the home path
//


Menu "Macros"
	SubMenu "Auto-Fit"
		"InitializeAutoFitPanel"
		"-"
		"Generate_Data_Checklist"
//		"Make_HoldConstraintEps_Waves"		//this is currently disabled
		"-"
		"CompileAndLoadReports"
		"LoadCompiledReports"
		"Compile_GlobalFit_Reports"
		"-"
		"PrintOpenNotebooks"
		"Close Open Notebooks"
		"-"
		"Generate_PICTS_list"
		"Layout_PICTS"
		
	End
End


//***********
//Automatic fitting routines for SANS or NSE data
//requires model functions and their associated files
//
//**************



//path to the data
// ? have this automatically do the listing?
Function PDPButton(ctrlName) : ButtonControl
	String ctrlName
	
	//set the global string to the selected pathname
	NewPath/O/M="pick the data folder" dataPath
	PathInfo/S dataPath
	Return(0)
End

Function SavePathButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//set the global string to the selected pathname
	NewPath/O/M="pick the save folder" savePath
	PathInfo/S savePath
	Return(0)
End

// 
// this re-sizes AND re-initializes the guessMatrix
// and is only done when the files are re-listed, using the list button - since the 
// new list will screw up the correspondence with the guess matrix
//
Function FileListButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoAlert 1,"This will re-initialize the file list and ALL of the entries in the guess matrix. Do you want to proceed?"
	if(V_flag!=1)		//if the answer is not yes, get out
		return(0)
	endif
	
	String fileList=""
	fileList = IndexedFile(dataPath,-1,"????")
	fileList = RemoveFromList(".DS_Store", fileList, ";",0)
	List2TextWave(Filelist,";","root:AutoFit:fileListWave")
	Wave/T lw = $"root:AutoFit:fileListWave"
	Redimension/N=(-1,2) lw
	lw[][1] = ""
	Variable num = DimSize(lw,0)
	
	Wave sw = $"root:AutoFit:fileSelWave"
	Redimension/B/N=(num,2) sw
	sw[][1] = (sw[p][1] == 0) ? 2^5 : sw[p][1]		//if the element is zero, make it 32, otherwise leave it alone
	
	// force a re-size (and re-initialization) of the guess-hold-constr-range matrices
	ToMatrixButtonProc("")
	
	return(0)
End

// 
// this re-sizes AND re-initializes the guessMatrix
// and is only done when the files are re-listed, using the list button - since the 
// new list will screw up the correspondence with the guess matrix
//
Function ToMatrixButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SetDataFolder root:AutoFit
	WAVE sel = fileSelWave
	NVAR numPar=numPar
	Variable jj,numSelFiles=0
	
	//update the number of steps for the progress bar
	// commented out - SRK - 28MAR05
//	NVAR cur=curProgress
//	NVAR totSteps=endProgress
//	cur=0
//	totSteps=numSelFiles*3		//3 fits per file
//	ValDisplay progressValdisp,limits={0,totSteps,0}
//	ControlUpdate/W=AutoFitPanel progressValdisp
	
	//redimension the matrices and lists
	Redimension/N=(numPar,DimSize(sel,0)) guessMatrix,HoldMatrix,constrMatrix,rangeMatrix
	Redimension/N=(numPar) guessList,holdList,constrList,rangeList,guessSel,holdSel,constrSel,rangeSel
	
	//Set the matrices to zero
	WAVE/T aa = guessMatrix
	WAVE/T bb = holdMatrix
	WAVE/T cc = constrMatrix
	WAVE/T rr = rangeMatrix
	aa="1"
	bb="0"
	cc=""		//set to no constraints
	rr="0"		// zero in points 0 and 1 force a fit of all of the data (default)
	//set the Lists to "0"
	WAVE/T dd=guessList
	WAVE/T ee=holdList
	WAVE/T ff=constrList
	WAVE/T rrl=rangeList
	dd="0"
	ee="0"
	ff="0"
	rrl="0"
	//Set the sel waves to 2 (editable)
	WAVE gg=guessSel
	WAVE hh=holdSel
	WAVE ii=constrSel
	WAVE rrs=rangeSel
	gg=2
	hh=2
	ii=2
	rrs=2
	
	SetDataFolder root:
	
	DisplayGuess()
	tabProc("",0)		//force the Guess tab to top
	TabControl tabC,value=0
	
	return(0)
End


//updates the lists (text waves) to display, depending on the current highlighted file
Function DisplayGuess()
	
	//find the selected data file -[][0] is the file, not the checkbox
	Variable row
	row = FindSelectedRowInLB(0)	// send 0 to look at the column with filenames

	//update the text waves based on the values in the matrix
	WAVE/T gm = root:AutoFit:guessMatrix
	WAVE/T gl = root:AutoFit:guessList
	
	// the hold matrix
	WAVE/T hm=root:AutoFit:holdMatrix
	WAVE/T hl=root:AutoFit:holdList
	
	// the constraint matrix 
	WAVE/T cm=root:AutoFit:constrMatrix
	WAVE/T cl=root:AutoFit:constrList
	
	// the range matrix 
	WAVE/T rm=root:AutoFit:rangeMatrix
	WAVE/T rl=root:AutoFit:rangeList
	
	WAVE sel = root:AutoFit:fileSelWave
	if( (sel[row][1] & 0x10) == 16 ) //box is checked
		
		gl = gm[p][row]
		hl = hm[p][row]
		cl = cm[p][row]
		rl = rm[p][row]
	else
		//file is not checked, don't display guess
		gl = "Not checked"
		hl = "Not checked"
		cl = "Not checked"
		rl = "Not checked"
	endif
	
	return(0)
End


//column 0 is the filenames, 1 is the checkboxes
//returns the row that is selected, -1 if not found
Function  FindSelectedRowInLB(col)
	Variable col
	
	WAVE sel = root:AutoFit:fileSelWave
	Variable jj=0,row=-1
	if(col==0)
		do
			if( (sel[jj][0] & 0x01) == 1 )			//returns 1 (bit 0) if selected, 0 otherwise	
				row=jj
				//print "Row = ",jj
				break
			endif
			jj+=1
		while(jj<DimSize(sel,0))
	else
		do
			if( (sel[jj][1] & 0x01) == 1 )			//the checkbox is selected, but not necessarily checked!
				row=jj
				//print "Row = ",jj
				break
			endif
			jj+=1
		while(jj<DimSize(sel,0))
	endif
	
	return(row)
end


Proc InitializeAutoFitPanel()
	if (wintype("AutoFitPanel") == 0)
		InitializeAutoFit()
		AutoFitPanel()
		tabProc("",0)		//force the tab control to display correctly
	else
		DoWindow/F AutoFitPanel
	endif
//	RangeCheckProc("",1)		//check the box to use all of the data
End

Function InitializeAutoFit()
	//set up all of the globals for the lists, globals, etc...
	NewDataFolder/O/S root:AutoFit
	Make/O/T/N=(1,2) fileListWave		//list boxes need text waves
	Make/O/B/N=(1,2) fileSelWave		//for the checkboxes
	Make/O/T/N=1 guessList,holdList,ConstrList,rangeList		//list boxes need text waves
	Make/O/T/N=(1,1) guessMatrix,holdMatrix,rangeMatrix			//guesses, etc... need real values (later)
	Make/O/T/N=(1,1) constrMatrix					//constraint matrix is text
	Make/O/B/N=1 guessSel,holdSel,ConstrSel,rangeSel						//SelWave is byte data
	Variable/G numPar=5,ptLow=0,ptHigh=0,fitTol=1e-3,curProgress=0,endProgress=10
	Variable/G startTicks=0
	
	String/G gStatFormat="\K(65535,0,0)\f01"
	String/G gStatus=gStatFormat+"the fit engine is currently idle"
	string/g gExt="ABC"
	
	fileListWave = ""
	
	//make the second column of the file sel wave a checkbox (set bit 5)
	fileSelWave[][1] = 2^5
	
	SetDataFolder root:
End

Window AutoFitPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(685,44,1001,740) /K=1
	DoWindow/C AutoFitPanel
	SetDrawLayer UserBack
//	DrawText 11,418,"Point Range"
//	DrawText 5,167,"Suffix"
	DrawLine 8,362,287,362
	PopupMenu popup0,pos={2,2},size={175,20},title="pick a function"
	PopupMenu popup0,mode=1,value= #"User_FunctionPopupList()",proc=AF_FuncPopupProc
		
	ListBox lb pos={11,90},size={280,230},proc=FileListboxProc
	ListBox lb listWave=root:AutoFit:fileListWave,selWave=root:AutoFit:fileSelWave
	ListBox lb editStyle=1,mode=5
	ListBox lb userColumnResize=1,widths={200,80}
	
//	Button DelButton,pos={245,61},size={40,20},proc=DelButtonProc,title="Del",disable=2
	Button PathButton,pos={6,61},size={50,20},proc=PDPButton,title="Path..."
	Button FileListButton,pos={182,61},size={50,20},proc=FileListButtonProc,title="List"
	ListBox guessBox,pos={24,398},size={139,208},disable=1,proc=UpdateGuessMatrixProc
	ListBox guessBox,frame=2,listWave=root:AutoFit:guessList
	ListBox guessBox,selWave=root:AutoFit:guessSel,mode= 2,selRow= 0
	Button FillAllGuessButton,pos={196,406},size={50,20},disable=1,proc=FillAllGuessButtonProc,title="Fill All"
	Button FillAllHoldButton,pos={196,406},size={50,20},disable=1,proc=FillAllHoldButtonProc,title="Fill All"
	Button FillAllConstrButton,pos={196,406},size={50,20},proc=FillAllConstrButtonProc,title="Fill All"
	Button FillAllRangeB,pos={196,406},size={50,20},disable=1,proc=FillAllRangeButtonProc,title="Fill All"
	SetVariable NumParams,pos={7,31},size={161,15},proc=SetNumParamProc,title="Number of Parameters"
	SetVariable NumParams,limits={2,Inf,0},value= root:AutoFit:numPar
//	CheckBox typeCheck,pos={207,31},size={32,14},title="NSE Data?",value=0
//	SetVariable fitTol,pos={80,208},size={80,15},title="Fit Tol"
//	SetVariable fitTol,limits={0.0001,0.1,0},value= root:AutoFit:fitTol
	CheckBox epsilonCheck,pos={156,335},size={32,14},value=0,title="Use Epsilon Wave?"

	TabControl tabC,pos={13,371},size={273,244},proc=tabProc,tabLabel(0)="Guess"
	TabControl tabC,tabLabel(1)="Hold",tabLabel(2)="Constraint",tabLabel(3)="Range",value= 0
//	CheckBox rangeCheck,pos={92,404},size={32,14},proc=RangeCheckProc,title="All"
//	CheckBox rangeCheck,value= 1,disable=2
	SetVariable lowPt,pos={136,404},size={60,15},title="low"
	SetVariable lowPt,limits={0,Inf,0},value= root:AutoFit:ptLow,noedit=1,disable=1
	SetVariable highPt,pos={201,404},size={60,15},title=" to "
	SetVariable highPt,limits={0,Inf,0},value= root:AutoFit:ptHigh,noedit=1,disable=1
	ListBox holdBox,pos={24,398},size={139,208},disable=1,proc=UpdateHoldMatrixProc
	ListBox holdBox,frame=2,listWave=root:AutoFit:holdList
	ListBox holdBox,selWave=root:AutoFit:holdSel,mode= 2,selRow= 2
	ListBox ConstrBox,pos={24,398},size={170,208},proc=UpdateConstrMatrixProc
	ListBox ConstrBox,frame=2,listWave=root:AutoFit:ConstrList
	ListBox ConstrBox,selWave=root:AutoFit:ConstrSel,mode= 2,selRow= 2
	ListBox RangeBox,pos={24,398},size={139,208},proc=UpdateRangeMatrixProc
	ListBox RangeBox,frame=2,listWave=root:AutoFit:rangeList
	ListBox RangeBox,selWave=root:AutoFit:RangeSel,mode= 2,selRow= 2
//	Button MatrixButton,pos={12,205},size={60,20},proc=ToMatrixButtonProc,title="Matrix",disable=2
	Button DoItButton,pos={21,632},size={80,20},proc=DoTheFitsButtonProc,title="Do the fits"
	Button savePathButton,pos={82,61},size={80,20},proc=SavePathButtonProc,title="Save Path..."
	TitleBox tb1,pos={139,634},size={128,12},anchor=MC,variable=root:AutoFit:gStatus,frame=0
	Button button0,pos={14,331},size={40,20},title="Plot",proc=LoadForGuessProc
//	SetVariable extStr,pos={4,170},size={40,15},title=" ",value= root:AutoFit:gExt
	
	Button GuessCoefB,pos={198,440},size={50,20},title="Guess",proc=UseCoefAsGuess
	Button GuessHoldB,pos={198,440},size={50,20},title="Guess",disable=1,proc=UseHoldAsGuess
	Button GuessConstrB,pos={198,440},size={50,20},title="Guess",disable=1,proc=UseConstraintsAsGuess
	
	ValDisplay progressValdisp,pos={113,663},size={161,7},title="00:00"
	ValDisplay progressValdisp,limits={0,root:AutoFit:endProgress,0},barmisc={0,0},value= root:AutoFit:curProgress
EndMacro


Function AF_FuncPopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			String name=pa.ctrlName
			Variable num=0,nc
			
			String coefStr = getFunctionCoef(popStr)
			String str
			
			NVAR pts1 = root:AutoFit:numPar
			SVAR suff = root:AutoFit:gExt
			
			Wave/Z coef=$("root:"+coefStr)
			if(WaveExists(coef))
				num=numpnts(coef)
				suff = getModelSuffix(popStr)		//get the suffix from the unsmeared model function
			else
				//try getting rid of "Smeared" from the beginning of the function string
				nc = strlen(popStr)
				str = getFunctionCoef(popStr[7,nc-1])
				Wave/Z cw = $("root:"+str)
				if(WaveExists(cw))
					num=numpnts(cw)
				endif
				suff = getModelSuffix(popStr[7,nc-1])		//get the suffix from the unsmeared model function
			endif
			
			// set the globals
			pts1 = num
			
			
			
			// set the size of the matrix of initial guesses
			SetNumParamProc("",num,"","")
			
			break
	endswitch

	return 0
End


Function tabProc(name,tab)
	String name
	Variable tab
	
	Button FillAllGuessButton disable= (tab!=0)
	Button GuessCoefB disable=(tab!=0)
	ListBox guessBox disable= (tab!=0)
	
	Button FillAllHoldButton disable= (tab!=1)
	Button GuessHoldB disable=(tab!=1)
	ListBox holdBox disable=(tab!=1)
	
	Button FillAllConstrButton disable= (tab!=2)
	Button GuessConstrB disable=(tab!=2)
	ListBox ConstrBox disable=(tab!=2)
	
	//no buttons on the range tab
	ListBox RangeBox disable=(tab!=3)
	Button FillAllRangeB disable= (tab!=3)
	
	return(0)
End


Function FillAllGuessButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//fills all of the guesses with the "current" list of guesses
	WAVE/T gl=root:AutoFit:guessList
	WAVE/T gm=root:AutoFit:guessMatrix
	gm[][] = gl[p]
	return(0)
End

Function FillAllHoldButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//fills all of the guesses with the "current" list of guesses
	WAVE/T hl=root:AutoFit:holdList
	WAVE/T hm=root:AutoFit:holdMatrix
	hm[][] = hl[p]
	return(0)
End

Function FillAllConstrButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//fills all of the guesses with the "current" list of guesses
	WAVE/T cl=root:AutoFit:constrList
	WAVE/T cm=root:AutoFit:ConstrMatrix
	cm[][] = cl[p]
	return(0)
End

Function FillAllRangeButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//fills all of the range values with the top values
	WAVE/T rl=root:AutoFit:rangeList
	WAVE/T rm=root:AutoFit:rangeMatrix
	rm[][] = rl[p]
	return(0)
End

Function SetNumParamProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//set the number of parameters for the function
	Variable/G numPar=varNum
	
	// adjust the number of parameters in the guesses
	SetMatrixRows(varNum)
	
	return(0)
End

//expand or collapse the matrices to the number of parameters
Function SetMatrixRows(newRows)
	Variable newRows
	
	SetDataFolder root:AutoFit
	
	WAVE/T aa = guessMatrix
	WAVE/T bb = holdMatrix
	WAVE/T cc = constrMatrix
	WAVE/T rr = rangeMatrix
	
	Redimension/N=(newRows,-1) aa,bb,cc,rr
	
	//redimension the lists too
	WAVE/T dd=guessList
	WAVE/T ee=holdList
	WAVE/T ff=constrList
	WAVE/T rrl=rangeList
	Redimension/N=(newRows) dd,ee,ff,rrl
	
	WAVE gg=guessSel
	WAVE hh=holdSel
	WAVE ii=constrSel
	WAVE rrs=rangeSel
	//set the selection wave for the individual lists to 2 == editable
	Redimension/N=(newRows) gg,hh,ii,rrs
	gg=2
	hh=2
	ii=2
	rrs=2
	
	SetDataFolder root:
	
	return 0
end


Function FileListboxProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if(event==4 && col==0)		//selection of a file, not a checkbox
		//then update the listbox display of guesses for the new file
	//	Print "file selected"
		DisplayGuess()
	Endif
	
	return 0            // other return values reserved
End

Function UpdateGuessMatrixProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if(event==7)		//finished edit of a cell, update the matrix of guesses
		//Print "updating"
		WAVE/T gl=root:AutoFit:guessList
		WAVE/T gm=root:AutoFit:guessMatrix
		//put new value in guessMatrix
		Variable datafile
		datafile = FindSelectedRowInLB(0)		//selected row in file list
		gm[row][datafile] = gl[row]
		//print "row= ",row
	Endif
	return 0            // other return values reserved
End

Function UpdateHoldMatrixProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if(event==7)		//finished edit of a cell, update the matrix of guesses
		//Print "updating"	
		WAVE/T hl=root:AutoFit:holdList
		WAVE/T hm=root:AutoFit:holdMatrix
		// put new value in holdMatrix
		Variable datafile
		datafile = FindSelectedRowInLB(0)
		hm[row][datafile] = hl[row]
		//print "row= ",row
	Endif
	return 0            // other return values reserved
End

Function UpdateConstrMatrixProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if(event==7)		//finished edit of a cell, update the matrix of guesses
		//Print "updating"
		WAVE/T cl=root:AutoFit:ConstrList
		WAVE/T cm=root:AutoFit:constrMatrix
		//put new value in constrMatrix
		Variable datafile
		datafile = FindSelectedRowInLB(0)
		cm[row][datafile] = cl[row]
		//print "row= ",row
	Endif
	return 0            // other return values reserved
End

Function UpdateRangeMatrixProc(ctrlName,row,col,event)
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if(event==7)		//finished edit of a cell, update the matrix of guesses
		//Print "updating"
		WAVE/T cl=root:AutoFit:RangeList
		WAVE/T cm=root:AutoFit:RangeMatrix
		//put new value in constrMatrix
		Variable datafile
		datafile = FindSelectedRowInLB(0)
		cm[row][datafile] = cl[row]
		//print "row= ",row
	Endif
	return 0            // other return values reserved
End

//returns the total number of files checked
Function numChecked()
	
	WAVE sel = root:AutoFit:fileSelWave
	
	Variable ii,num=0
	for(ii=0;ii<DimSize(sel,0);ii+=1)
		if( (sel[ii][1] & 0x10) == 16 )	
			num += 1
		endif
	endfor
	return num
	
End


//Function RangeCheckProc(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//	
//	SetVariable lowPt disable=(checked)
//	SetVariable highPt disable=(checked)
//End

Function DoTheFitsButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//read the values from the panel
	ControlInfo/W=AutoFitPanel popup0
	String funcStr=S_Value
	String fileName
	NVAR numPar=root:AutoFit:numPar
	NVAR startTicks=root:AutoFit:startTicks
	NVAR curProgress=root:AutoFit:curProgress
	NVAR endProgress=root:AutoFit:endProgress
	
	WAVE/T fileWave=root:AutoFit:fileListWave
	WAVE sel = root:AutoFit:fileSelWave
	
	WAVE/T guessMatrix=root:AutoFit:guessMatrix
	WAVE/T holdMatrix=root:AutoFit:holdMatrix
	WAVE/T constrMatrix=root:AutoFit:constrMatrix
	WAVE/T rangeMatrix=root:AutoFit:rangeMatrix
		
	Variable ii=0,numFiles=DimSize(fileWave,0),t1=ticks,t2,matrixindex,count=0
	//print numFiles
	//for the timer-progress bar - timer shows time, bar shows number of fits remaining
	curProgress = 0
	endProgress = 3*numChecked()			//3 fits per file that is fit
	ValDisplay progressValdisp,limits={0,endProgress,0}
	ControlUpdate/W=AutoFitPanel progressValdisp
	
	//print "numChecked() = ",numChecked()
	startTicks=t1			//starting now
	for(ii=0;ii<numFiles;ii+=1)		//loop over everything in the file list, dispatching only checked items
		if( (sel[ii][1] & 0x10) == 16 )		//the box is checked, then go fit it
			fileName = fileWave[ii][0]
			DoOneFit(funcStr,fileName,numPar,fileWave,ii,guessMatrix,holdMatrix,constrMatrix,rangeMatrix)
			count+=1
		endif
	endfor
	UpdateStatusString("All files processed")
	t2=ticks
	t1=(t2-t1)/60
	Printf "All %d files processed in %g seconds =(%g minutes) =(%g hours)\r",count,t1,t1/60,t1/60/60
	return(0)
End


Function DoOneFit(funcStr,fileName,numPar,fileWave,ii,guessMatrix,holdMatrix,constrMatrix,rangeMatrix)
	String funcStr,fileName
	Variable numPar
	WAVE/T fileWave	//length <= ii
	Variable ii		//index in the full list
	WAVE/T guessMatrix,holdMatrix,constrMatrix,rangeMatrix
	
	String list="",fullName="",dataname="",str=""
	//be sure all is clear (no data, window... etc)
	DoWindow/K AutoGraph				//no error is reported
	DoWindow/K AutoGraph_NSE				
	list=WaveList("*__*",";","")		//not case sensitive?
	DoKillList(list)						//get rid of all of the old data
	list=WaveList("wave*",";","")		//"wave(n)" can be generated if not all NSE times are collected
	DoKillList(list)
	
	//SANS or NSE data?
	ControlInfo/W=AutoFitPanel typeCheck
	Variable isNSE=v_value
	//load in the data
	PathInfo dataPath
	fullName = S_path
	//fullName += fileWave[ii]
	fullName += fileName
	if(isNSE)
		//load, don't plot
		str = "A_LoadNSEDataWithName(\""+fullName+"\",0)"
		Execute str
//		A_LoadNSEDataWithName(fullName,0)				//load, don't plot
	else
		//load, default name, no plot, overwrite data if needed
		str = "A_LoadOneDDataToName(\""+fullName+"\",\"\",0,1)"
		Execute str
//		A_LoadOneDDataToName(fullName,"",0,1)		//load, default name, no plot, overwrite data if needed
	endif
	dataName=GetFileNameFromPathNoSemi(fullName)
	dataname=CleanupName(dataname,0)
	
	//graph it - creates window named "AutoGraph"
	if(isNSE)
		Execute "DoGraph_NSE(\""+dataname+"\")"
	else
		Execute "DoGraph(\""+dataname+"\")"
	endif
	
	//generate the needed strings to add to the execute stmt
	// rangeStr, guessStr,constrStr,holdStr
	// and waves - the coefficient wave and paramter wave
	Variable useRes,useEps,useCursors,useConstr
	Variable val,pt1,pt2
	useEps = 0
	useConstr = 0
	useCursors = 0
	useRes = 0
	
	String holdStr="",rangeStr="",cStr="",epsilonStr=""
	String DF="root:"+dataname+":"	

	
	Make/O/D/N=(numPar) myCoef		//always named "myCoef"
	Wave cw = root:myCoef

	//range string
	useCursors = ParseRangeString(ii,dataname,rangeMatrix,pt1,pt2)		//read range from the matrix, return values and set flag

	
	//params to hold
	holdStr = ParseHoldString(ii,numpar,holdMatrix)
	//initial guesses
	ParseGuessString(ii,numpar,guessMatrix,"myCoef")
	//constraints
	cStr = ParseConstraints(ii,numpar,constrMatrix,"myConstraints")
	WAVE/Z constr = $"myConstraints"
	if(strlen(cStr)!=0)
		useConstr = 1
	endif
	//epsilon wave
	epsilonStr = GetEpsilonWave()
	if(strlen(epsilonStr) > 0)
		Wave eps=$epsilonStr		//in the root folder
		useEps = 1
	endif
	
	//fit it
	//these two global variables must be created for IGOR to set them, so that
	//any errors in the fitting can be diagnosed
	Variable/G V_FitError=0				//0=no err, 1=error,(2^1+2^0)=3=singular matrix
	Variable/G V_FitQuitReason=0		//0=ok,1=maxiter,2=user stop,3=no chisq decrease
	NVAR tol=root:AutoFit:fitTol
	Variable/G V_FitTol=tol		//default is 0.0001
	Variable/G V_fitOptions=4		//suppress the dialog during fitting (we're not waiting for OK, anyways)


	Wave yw = $(DF+dataName+"_i")
	Wave xw = $(DF+dataName+"_q")
	Wave sw = $(DF+dataName+"_s")
	
	if(stringmatch(funcStr, "Smear*"))		// if it's a smeared function, need a struct
		useRes=1
	endif
	
	Struct ResSmearAAOStruct fs
	WAVE/Z resW = $(DF+dataName+"_res")			//these may not exist, if 3-column data is used	
	WAVE/Z fs.resW =  resW
	WAVE yw=$(DF+dataName+"_i")
	WAVE xw=$(DF+dataName+"_q")
	WAVE sw=$(DF+dataName+"_s")
	Wave fs.coefW = cw
	Wave fs.yW = yw
	Wave fs.xW = xw
	
	Duplicate/O yw $(DF+"FitYw")
	WAVE fitYw = $(DF+"FitYw")
	fitYw = NaN
	
	NVAR useGenCurveFit = root:Packages:NIST:gUseGenCurveFit
	///// SEE FitWrapper() for more details.
	
	Variable nPass = 1
	
	do	// outer do is the loop over passes
	do	// this inner loop is abig switch to select the correct FutFunc to dispatch
		if(useGenCurveFit)
#if !(exists("GenCurveFit"))
			// XOP not available
			useGenCurveFit = 0
			Abort "Genetic Optimiztion XOP not available. Reverting to normal optimization."	
#endif
			//send everything to a function, to reduce the clutter
			// useEps and useConstr are not needed
			// pass the structure to get the current waves, including the trimmed USANS matrix
			Variable chi,pt

			chi = DoGenCurveFit(useRes,useCursors,sw,fitYw,fs,funcStr,ParseHoldString(ii,numpar,holdMatrix),val,lolim,hilim,pt1,pt2)
			pt = val

			break
			
		endif
		
		
		if(useRes && useEps && useCursors && useConstr)		//do it all
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useEps && useCursors)		//no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /STRC=fs
			break
		endif
		
		if(useRes && useEps && useConstr)		//no crsr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useCursors && useConstr)		//no eps
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes && useCursors)		//no eps, no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /D=fitYw /STRC=fs
			break
		endif
		
		if(useRes && useEps)		//no crsr, no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /STRC=fs
			break
		endif
	
		if(useRes && useConstr)		//no crsr, no eps
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /C=constr /STRC=fs
			break
		endif
		
		if(useRes)		//just res
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /STRC=fs
			break
		endif
		
/////	same as above, but all without useRes (no /STRC flag)
		if(useEps && useCursors && useConstr)		//do it all
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr
			break
		endif
		
		if(useEps && useCursors)		//no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /E=eps /D=fitYw
			break
		endif
		
		if(useEps && useConstr)		//no crsr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw /C=constr
			break
		endif
		
		if(useCursors && useConstr)		//no eps
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /D=fitYw /C=constr
			break
		endif
		
		if(useCursors)		//no eps, no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw[pt1,pt2] /X=xw /W=sw /I=1 /D=fitYw
			break
		endif
		
		if(useEps)		//no crsr, no constr
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /E=eps /D=fitYw
			break
		endif
	
		if(useConstr)		//no crsr, no eps
			FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw /C=constr
			break
		endif
		
		//just a plain vanilla fit
		FuncFit/H=ParseHoldString(ii,numpar,holdMatrix) /NTHR=0 $funcStr cw, yw /X=xw /W=sw /I=1 /D=fitYw
	
	while(0)		//always exit the inner do to select the FutFunc syntax. The break will exit this loop
	
		if(nPass == 1)
			UpdateStatusString(dataname +" Fit #1")
			Variable/G gChiSq1 = V_chisq
		endif
		
		if(nPass == 2)
			UpdateStatusString(dataname +" Fit #2")
			Variable/G gChiSq2 = V_chisq
		endif
		
		if(nPass == 3)
			UpdateStatusString(dataname +" Fit #3")
		endif
		
		nPass += 1
	while(nPass < 4)

	// append the fit
	// need to manage duplicate copies
	// Don't plot the full curve if cursors were used (set fitYw to NaN on entry...)
	String traces=TraceNameList("", ";", 1 )		//"" as first parameter == look on the target graph
	if(strsearch(traces,"FitYw",0) == -1)
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	else
		RemoveFromGraph FitYw
		if(useGenCurveFit && useCursors)
			WAVE trimX = trimX
			AppendtoGraph fitYw vs trimX
		else
			AppendToGraph FitYw vs xw
		endif
	endif
	ModifyGraph lsize(FitYw)=2,rgb(FitYw)=(52428,1,1)


	//do the report calling the function, not the proc
	String topGraph= WinName(0,1)	//this is the topmost graph
	SVAR suffix = root:AutoFit:gExt		//don't try to read as getModelSuffix(funcStr), since the smeared() may not be plotted
	String parStr=GetWavesDataFolder(cw,1)+ WaveList("*param*"+"_"+suffix, "", "TEXT:1," )		// this is *hopefully* one wave

	if(isNSE)
		GenerateReport_NSE(funcStr,dataname,"par","myCoef",1)
	else
		W_GenerateReport(funcStr,dataname,$parStr,$"myCoef",1,V_chisq,W_sigma,V_npnts,V_FitError,V_FitQuitReason,V_startRow,V_endRow,topGraph)

//		AutoFit_GenerateReport(funcStr,dataname,"par","myCoef",1)	
	endif
	
	return(0)
End

//// to be able to simply fill in the pt range of the yw[lo,hi]
//Function LowRange()
//	NVAR val = root:AutoFit:ptLow
//	return(val)
//End
//
//Function HighRange()
//	NVAR val = root:AutoFit:ptHigh
//	return(val)
//End

//updates the status string, forcing a redraw twice, to overcome what seems to be a bug in Igor4
//also updates the progress bar and the countdown
Function UpdateStatusString(newStr)
	String newStr
	
	SVAR gStatus=root:AutoFit:gStatus
	SVAR gStatFormat=root:AutoFit:gStatFormat
	gStatus=""
	ControlUpdate/W=AutoFitPanel tb1		//clears the line
	gStatus=gStatFormat+newStr
	ControlUpdate/W=AutoFitPanel tb1
	
	//update the progress bar and timer
	NVAR cur=root:AutoFit:curProgress
	NVAR endProgress=root:AutoFit:endProgress
	NVAR startTicks=root:AutoFit:startTicks
	cur+=1
	
//	Print "****"
//	Print "cur = ",cur
	
	Variable t2=ticks,projTot,projRemain
	String titleStr=""
	
	projTot = (t2-startTicks)/(cur-1)*endProgress
	projRemain = projTot - (t2-startTicks)
	projRemain /= 60.15		//to seconds
	DoWindow/F AutoFitPanel
	ValDisplay progressValdisp,title=Secs2time(projRemain,5)
	ControlUpdate/W=AutoFitPanel progressValdisp
	
//	Print "End Progress = ",endProgress
//	Print "ProjTot = ",projTot/60.15
//	Print "ProjRemain = ",projRemain
	
	return(0)
End

// returns a string with the name of the epsilon wave, or null if it doesn't exist
Function/S GetEpsilonWave()
	
	String retStr="",testStr
	SVAR extStr = root:AutoFit:gExt
	//do you want to use epsilon wave?
	ControlInfo/W=AutoFitPanel epsilonCheck
	if(V_Value == 0)		//not checked
		return(retStr)
	endif
	
	testStr = "Epsilon_"+extStr
	if(waveexists($testStr) != 0)
//		return(" /E="+testStr)
		return(testStr)
	endif
	return(retStr)
End

//returns the y data to fit - "_i" suffix, and range if selected
// enter the range as the first element[0] as low point, second element[1] as high point
// leave the other elements blank
//
// if either point value is not entered, the whole data set is used
//
// -- if both of the elements are between 0 and 1, assume they are q-values (check for fractional part)
// and find the appropriate points...
//
Function ParseRangeString(set,dataStr,rMat,lo,hi)
	Variable set
	String dataStr
	WAVE/T rMat
	Variable &lo,&hi
	
	Variable useCursors
			
	lo = str2num(rMat[0][set])
	hi = str2num(rMat[1][set])
	
	if(lo == 0 && hi == 0)
		return(0)
	endif
	
	if(numtype(lo) != 0 || numtype(hi) != 0)		//not a normal number
		return(0)		//don't use cursor values, use all of the dataset
	endif
	
	
	if(lo>=hi) //error in specification, or all data desired (both zero or undefined)
		return(0)		//use all of the dataset
	endif
	
	
	if(trunc(lo) != lo || trunc(hi) != hi)		//values have fractional parts
		WAVE xW = $("root:"+dataStr+":"+dataStr + "_q")
		FindLevel/P/Q xW, lo
		lo = trunc(V_levelX)		//find the corresponding point values
		FindLevel/P/Q xW, hi
		hi = trunc(V_levelX)
	endif
	
	Variable/G root:AutoFit:ptLow = lo
	Variable/G root:AutoFit:ptHigh = hi

	return(1)
End

//returns the holdStr, i.e. "1010101"
Function/S ParseHoldString(set,npar,hMat)
	Variable set,npar
	WAVE/T hMat
	
	Variable ii
	String retStr=""
	
	for(ii=0;ii<npar;ii+=1)
		if(strlen(hMat[ii][set]) == 0)
			retStr += "0"
		else
			retStr += hMat[ii][set]
		endif
	endfor

//	Print retStr
	
	return(retStr)
End

//returns only error - wave must already exist
Function ParseGuessString(set,npar,gMat,outWStr)
	Variable set,npar
	WAVE/T gMat
	String outWStr
	
	Variable ii
	String retStr=outWStr
	
	WAVE outWave=$outWStr
	for(ii=0;ii<npar;ii+=1)
		outWave[ii] = str2num(gMat[ii][set])
	endfor
	return(0)
End

//the constraint wave is created here
Function/S ParseConstraints(set,npar,cMat,outWStr)
	Variable set,npar
	WAVE/T cMat
	String outWStr
	
	String retStr="",loStr="",hiStr=""
	Variable ii=0,jj=0	
	Make/O/T/N=0 $outWStr
	WAVE/T cw = $outWStr	
	//return "/C="+outWStr if parsed ok, or null if not

	String listStr=""
	for(ii=0;ii<npar;ii+=1)
		listStr=cMat[ii][set]
		loStr=StringFromList(0, listStr ,";")
		hiStr=StringFromList(1, listStr ,";")
		if(cmpstr(loStr,"")!=0)	//something there...
			InsertPoints jj,1,cw		//insert before element jj
			cw[jj] = "K"+num2Str(ii)+">"+loStr
			jj+=1
		endif
		if(cmpstr(hiStr,"")!=0)	//something there...
			InsertPoints jj,1,cw		//insert before element jj
			cw[jj] = "K"+num2Str(ii)+"<"+hiStr
			jj+=1
		endif
	endfor
	if(numpnts(cw) > 0 )
		retStr = "/C=" + outWStr
	Endif
//	print "strlen, conStr= ",strlen(retStr),retstr

	return(retStr)	//null string will be returned if no constraints
End


//*************************
Proc DoGraph(dataname)
	String dataname
	
	SetDataFolder $dataname

	PauseUpdate; Silent 1		// building window...
	Display /W=(5,42,301,313)/K=1 $(dataname+"_i") vs $(dataname+"_q")
	DoWindow/C AutoGraph
	ModifyGraph mode($(dataname+"_i"))=3
	ModifyGraph marker($(dataname+"_i"))=19
	ModifyGraph rgb($(dataname+"_i"))=(1,4,52428)
	ModifyGraph msize($(dataname+"_i"))=2
	ModifyGraph grid=1
	ModifyGraph log=1
	ModifyGraph tickUnit=1
	//
	ModifyGraph mirror=2
	//
	ErrorBars $(dataname+"_i") Y,wave=($(dataname+"_s"),$(dataname+"_s"))
//	Legend/A=LB
//	Legend/A=LB/X=0.00/Y=-32		//defaults to the top right
	Legend/A=MT/E		// /X=-16.16/Y=5.17/E
	
	SetDataFolder root:
	
EndMacro

Proc DoGraph_NSE(dataname)
	String dataname
	
	SetDataFolder $dataname

	PauseUpdate; Silent 1		// building window...
	Display /W=(5,42,301,313)/K=1 $(dataname+"_i") vs $(dataname+"_q")
	DoWindow/C AutoGraph_NSE
	ModifyGraph mode($(dataname+"_i"))=3
	ModifyGraph marker($(dataname+"_i"))=19
	ModifyGraph rgb($(dataname+"_i"))=(1,4,52428)
	ModifyGraph msize($(dataname+"_i"))=3
	ModifyGraph zColor($(dataname+"_i"))={$(dataname+"__Q"),$(dataname+"__Q")[0]*0.99,*,Rainbow}
	ModifyGraph grid=1
	ModifyGraph mirror=2
	ModifyGraph log(left)=1
	ErrorBars $(dataname+"_i") Y,wave=($(dataname+"_s"),$(dataname+"_s"))
	Legend/A=MB
	SetAxis/A/E=1 bottom
	ModifyGraph standoff=0
	SetAxis left 0.1,1
	//ModifyGraph tickUnit(left)=1
EndMacro

//*************************


//**************************
// Generate the report
//**************************

////must have AutoGraph as the name of the graph window (any size)
//// func is the name of the function (for print only)
////par and coef are the exact names of the waves
////yesSave==1 will save the file(name=func+time)
////
////
//// general report function from the wrapper is used instead
////	W_GenerateReport(funcStr,folderStr,$parStr,cw,yesSave,V_chisq,W_sigma,V_npnts,V_FitError,V_FitQuitReason,V_startRow,V_endRow,topGraph)
////
//Function AutoFit_GenerateReport(func,dataname,par,myCoef,yesSave)
//	String func,dataname,par,myCoef
//	Variable yesSave
//	
//	String str,pictStr="P_"
//	Wave sigWave=$"W_sigma"
//	Wave ans=$myCoef
////	Wave/T param=$par
//	SVAR ext=root:AutoFit:gExt
//	Wave/T param=$"parameters_"+ext
//	
//	NVAR V_chisq = V_chisq
//	NVAR V_npnts = V_npnts
//	NVAR V_FitError = V_FitError
//	NVAR V_FitQuitReason = V_FitQuitReason
//	NVAR chi1=gChiSq1
//	NVAR chi2=gChiSq2
//	NVAR V_startRow = V_startRow
//	NVAR V_endRow = V_endRow
//	
//	// bring report up
//	DoWindow/F Report
//	if (V_flag == 0)		// Report notebook doesn't exist ?
//		NewNotebook/W=(10,45,550,620)/F=1/N=Report as "Report"
//	endif
//	
//	// delete old stuff
//	Notebook Report selection={startOfFile, endOfFile}, text="\r", selection={startOfFile, startOfFile}
//	
//	// insert title
//	Notebook Report newRuler=Title, justification=1, rulerDefaults={"Times", 16, 1, (0, 0, 0)}
//	sprintf str, "Fit to %s, %s, %s\r\r", func,Secs2Date(datetime, 0), time()
//	Notebook Report ruler=Title, text=str
//	
//	// insert fit results
//	Variable num=numpnts(ans),ii=0
//	Notebook Report ruler=Normal; Notebook Report  margins={18,18,504}, tabs={63 + 3*8192}
//	str = "Data file: " + dataname + "\r\r"
//	Notebook Report text=str
//	do
//		sprintf str, "%s = %g±%g\r", param[ii],ans[ii],sigwave[ii]
//		Notebook Report text=str
//		ii+=1
//	while(ii<num)
//	
//	//
//	Wave dataXw = $(dataname+"_q")
//	Variable nData=numpnts(dataXw)
//	
//	//
//	sprintf str,"chisq = %g , %g , %g\r",chi1,chi2,V_chisq
//	Notebook Report textRGB=(65000,0,0),fstyle=1,text=str
//	sprintf str,"Npnts = %g, sqrt(X^2/N) = %g\r",V_npnts,sqrt(V_chisq/V_npnts)
//	Notebook Report textRGB=(0,0,0),fstyle=0, text=str
//	sprintf str "Fitted range = [%d,%d] = %g < Q < %g\r",V_startRow,V_endRow,dataXw(V_startRow),dataXw(V_endRow)
//	Notebook Report textRGB=(0,0,0),fstyle=0, text=str
//	sprintf str,"V_FitError = %g\t\tV_FitQuitReason = %g\r",V_FitError,V_FitQuitReason
//	Notebook Report textRGB=(65000,0,0),fstyle=1,text=str
//	Notebook Report ruler=Normal
//	
//	// insert graphs
//	Notebook Report picture={AutoGraph(0, 0, 400, 300), 0, 1}, text="\r"
//	
//
//	//Notebook Report picture={Table1, 0, 0}, text="\r"
//	
//	// show the top of the report
//	Notebook Report  selection= {startOfFile, startOfFile},  findText={"", 1}
//	
//	//save the notebook
//	if(yesSave)
//		String nameStr=CleanupName(func,0)
//		nameStr = nameStr[0,8]	//shorten the name
//		nameStr += "_"+dataname
//		//make sure the name is no more than 31 characters
//		namestr = namestr[0,30]		//if shorter than 31, this will NOT pad to 31 characters
//		Print "file saved as ",nameStr
//		SaveNotebook /O/P=savePath/S=2 Report as nameStr
//		//save the graph separately as a PICT file, 2x screen
//		pictStr += nameStr
//		pictStr = pictStr[0,28]		//need a shorter name - why?
//		DoWindow/F AutoGraph
//		// E=-5 is png @screen resolution
//		// E=2 is PICT @2x screen resolution
//		SavePICT /E=2/O/I/P=savePath /W=(0,0,3,3) as pictStr
//	Endif
//	
//	// ???maybe print the notebook too?
//End



//
//Proc DoGenerateReport(fname,dataname,param,coef,yesno)
//	String fname,dataname="",param,coef,yesno="No"
//	Prompt fname,"function name",popup,FunctionList("!Sme*",";","KIND:15,")
//	Prompt dataname,"name of the dataset"
//	Prompt param,"parameter names",popup,WaveList("par*",";","")
//	Prompt coef,"coefficient wave",popup,WaveList("coe*",";","")
//	Prompt yesno,"Save the report?",popup,"Yes;No;"
//	
//	//Print "fname = ",fname
//	//Print "param = ",param
//	//Print "coef = ",coef
//	//Print "yesno = ",yesno
//	
//	Variable doSave=0
//	if(cmpstr(yesno,"Yes")==0)
//		doSave=1
//	Endif
//	GenerateReport(fname,dataname,param,coef,dosave)
//	
//End



//must have AutoGraph_NSE as the name of the graph window (any size)
// func is the name of the function (for print only)
//par and coef are the exact names of the waves
//yesSave==1 will save the file(name=func+time)
//
Function GenerateReport_NSE(func,dataname,par,coef,yesSave)
	String func,dataname,par,coef
	Variable yesSave
	
	String str
	Wave sigWave=$"W_sigma"
	Wave ans=$coef
	Wave/T param=$par
	
	NVAR V_chisq = V_chisq
	NVAR V_npnts = V_npnts
	NVAR V_FitError = V_FitError
	NVAR V_FitQuitReason = V_FitQuitReason
	
	// bring report up
	DoWindow/F Report
	if (V_flag == 0)		// Report notebook doesn't exist ?
		NewNotebook/W=(10,45,550,620)/F=1/N=Report as "Report"
	endif
	
	// delete old stuff
	Notebook Report selection={startOfFile, endOfFile}, text="\r", selection={startOfFile, startOfFile}
	
	// insert title
	Notebook Report newRuler=Title, justification=1, rulerDefaults={"Times", 16, 1, (0, 0, 0)}
	sprintf str, "Fit to %s, %s, %s\r\r", func,Secs2Date(datetime, 0), time()
	Notebook Report ruler=Title, text=str
	
	// insert fit results
	Variable num=numpnts(ans),ii=0
	Notebook Report ruler=Normal; Notebook Report  margins={18,18,504}, tabs={63 + 3*8192}
	str = "Data file: " + dataname + "\r\r"
	Notebook Report text=str
	do
		sprintf str, "%s = %g±%g\r", param[ii],ans[ii],sigwave[ii]
		Notebook Report text=str
		ii+=1
	while(ii<num)
		
	sprintf str,"chisq = %g\r",V_chisq
	Notebook Report textRGB=(65000,0,0),fstyle=1,text=str
	sprintf str,"Npnts = %g\r",V_npnts
	Notebook Report textRGB=(0,0,0),fstyle=0, text=str
	sprintf str,"V_FitError = %g\rV_FitQuitReason = %g\r",V_FitError,V_FitQuitReason
	Notebook Report textRGB=(65000,0,0),fstyle=1,text=str
	Notebook Report ruler=Normal
	
	// insert graphs
	Notebook Report picture={AutoGraph_NSE(0, 0, 400, 300), 0, 1}, text="\r"
	//Notebook Report picture={Table1, 0, 0}, text="\r"
	
	// show the top of the report
	Notebook Report  selection= {startOfFile, startOfFile},  findText={"", 1}
	
	//save the notebook
	if(yesSave)
		String nameStr=CleanupName(func,0)
		nameStr = nameStr[0,8]	//shorten the name
		nameStr += "_"+dataname
		//make sure the name is no more than 31 characters
		namestr = namestr[0,30]		//if shorter than 31, this will NOT pad to 31 characters
		Print "file saved as ",nameStr
		SaveNotebook /O/P=savePath/S=2 Report as nameStr
	Endif

	//save a pict file, just of the graph
	namestr = "PICT_" + namestr
	namestr = namestr[0,28]		//PICT names in IGOR must be shorter, to allow auto-naming?
	DoWindow/F AutoGraph_NSE
	SavePICT /E=2/O/I/P=savePath /W=(0,0,3,3) as nameStr
End


//*********************
//
//*********************
// List utilities
//*********************
//
// List2TextWave is also in SANS_Utilities.ipf, but to keep from having big lists of dependencies,
// have definitions here that are local and Static

//
Static Function List2TextWave(list,sep,waveStr)
	String list,sep,waveStr
	
	Variable n= ItemsInList(list,sep)
	Make/O/T/N=(n) $waveStr= StringFromList(p,list,sep)
End

Function List2NumWave(list,sep,waveStr)
	String list,sep,waveStr
	
	Variable n= ItemsInList(list,sep)
	Make/O/D/N=(n) $waveStr= str2num( StringFromList(p,list,sep) )
End

Function/S TextWave2List(w,sep)
	Wave/T w
	String sep
	
	String newList=""
	Variable n=numpnts(w),ii=0
	do
		newList += w[ii] + sep
		ii+=1
	while(ii<n)
	return(newList)
End

//for single precision numerical waves
Function/S NumWave2List(w,sep)
	Wave w
	String sep
	
	String newList="",temp=""
	Variable n=numpnts(w),ii=0,val
	do
		val=w[ii]
		temp=""
		sprintf temp,"%g",val
		newList += temp
		newList += sep
		ii+=1
	while(ii<n)
	return(newList)
End

Function DoKillList(list)
	String list
	
	String item=""
	do
		item = StringFromList(0, list ,";" )
		KillWaves/Z $item
		list = RemoveFromList(item, list, ";")
	while(ItemsInList(list, ";")>0)
End

//*********************



//*******************
//Notebook Utils
//*******************

Proc PrintOpenNotebooks()

	String list=WinList("*", ";", "WIN:16")
	String item = ""
	do
		item=StringFromList(0,list,";")
		Print item
		PrintNotebook $item
		list = RemoveFromList(item, list, ";")
	while(ItemsInList(list, ";")>0)
End

Proc CloseOpenNotebooks()

	String list=WinList("*", ";", "WIN:16")
	String item = ""
	do
		item=StringFromList(0,list,";")
		DoWindow/K $item
		list = RemoveFromList(item, list, ";")
	while(ItemsInList(list, ";")>0)
End

Proc Generate_PICTS_list()
	fGenerate_PICTS_list()
End

//spits up a list of PICTS
Function fGenerate_PICTS_list()

	String List=IndexedFile(savePath, -1, "PICT")
	List2TextWave(List,";","PICT_files")
	WAVE/T picts=$"PICT_files"
	Edit/K=1 picts
End

Proc Layout_PICTS(pStr)
	String pStr=""
	Prompt pStr,"wave of PICTs to use",popup,WaveList("PICT_f*", ";", "")
		
	String List=TextWave2List($pStr,";")
	String item = ""
	//kill old picts
	KillPicts/A/Z
	//make a new layout
	Layout/C=1 as "PICT_Layout"
	DoWindow/C PICTLayout
	do
		item=StringFromList(0,List,";")
		//load each PICT, and append it to the layout
		Print "load item = ",item
		LoadPICT /O/Q/P=savePath item
		DoWindow/F PICTLayout		//be sure layout is on top
		AppendLayoutObject /F=1/W=PICTLayout picture  $item
		//AppendToLayout $item
		//Print item
		List = RemoveFromList(item, List, ";")
	while(ItemsInList(List, ";")>0)
	//tile the PICTs in the layout
	Tile/O=8
End

//spit up a list of everything in the folder that is a text file
Proc Generate_Data_Checklist()
	fGenerate_Data_list()
End
Function fGenerate_Data_list()

	String List=IndexedFile(dataPath, -1, "TEXT")
	List2TextWave(List,";","data_files")
	WAVE/T files=$"data_files"
	Duplicate/O/T files ModelToUse,Done
	ModelToUse = ""
	Done = ""
	Edit/K=1 files,ModelToUse,Done
End

//***************

// with all of the notebooks open for a given model (with N parameters)
// this will comile the reports, save the text notebook, then load it back in
// and put it in a table for easy printing
//
Proc CompileAndLoadReports()
	Compile_Reports()
	SaveNotebook /O/P=savePath/S=2 Compilation
//	Print "Saved as:  ",S_Path
	DoWindow/K Compilation
	LoadCompiledReports(S_Path)
End

Proc LoadCompiledReports(str)
	String str
	LoadWave/J/D/W/E=1/K=0/V={"\t"," $",0,0} str
End

Proc Compile_Reports(Number_of_Parameters)
	Variable Number_of_Parameters=7
	fCompile_Reports(Number_of_Parameters)
	fCompile_ReportsTable(Number_of_Parameters)
End

Proc Compile_GlobalFit_Reports(WhichParameter,FileStr,ParamStr,ParamErrStr)
	Variable WhichParameter=7
	String FileStr="FileName_",ParamStr="par_",ParamErrStr="parErr_"
	fCompile_GlobalFit_Reports(WhichParameter,FileStr,ParamStr,ParamErrStr)
End

////
Function fCompile_Reports(nPar)
	Variable nPar
	
	String list=WinList("*", ";", "WIN:16")
	String item = "",textStr="",newStr=""
	Variable sstop,dum,chi
	
	Variable ii
	NewNotebook/F=0 /N=Compilation as "Compilation"
	Notebook Compilation text="Variable Name \tValues\tErrors\r"
	do
		item=StringFromList(0,list,";")
		DoWindow/F $item
		
		Notebook $item selection={(2,0), (3,0)}		//paragraph 3 (starts from 0) = filename
		GetSelection notebook,$item,2
		textStr=S_Selection
		textStr=textStr[0,strlen(textStr)-2]		//remove CR
		textStr=textStr[10,strlen(textStr)-1]		//remove "DATA FILE: 
		Notebook Compilation text="File:\t"+textStr+"\t"
		Notebook Compilation text=textStr+"_err\r"
		
//		printf "%s %s\r",textStr,textStr+"_err"
//
// results are written as:  "%s = \t%g\t±\t%g\r"
//
		for(ii=0;ii<nPar;ii+=1)		//gather the parameters
		
			Notebook $item selection={(ii+4,0), (ii+5,0)}		//paragraph 5		= parameter 0
			GetSelection notebook,$item,2
			textStr=S_Selection
			textStr=textStr[0,strlen(textStr)-2]
			//textStr=textStr[13,strlen(textStr)-1]		// remove "parameter"
			textStr = ReplaceString("=",textStr,"")
			textStr = ReplaceString("±\t",textStr,"")
			Notebook Compilation text=textStr+"\r"
			//printf "%s\r",textStr
			//Print strlen(textStr)
		endfor
		//get the chi-squared/N value
		ii+=1
		Notebook $item selection={(ii+4,0), (ii+5,0)}		//
		GetSelection notebook,$item,2
		textStr=S_Selection
		Print textStr
		
		sscanf textStr,"Npnts = %g\t\tSqrt(X^2/N) = %g\r",dum,chi
		sprintf textStr,"Sqrt(X^2/N)\t%s\t\r",num2str(chi)
		Notebook Compilation text=textStr
		
		Notebook Compilation text="\r"		//separate items
		
		list = RemoveFromList(item, list, ";")
	while(ItemsInList(list, ";")>0)
	
	DoWindow/F Compilation
	Notebook Compilation selection={startOfFile,startOfFile}
End

////
// compiles the results into a table.
Function fCompile_ReportsTable(nPar)
	Variable nPar
	
	String list=WinList("*", ";", "WIN:16")
	String item = "",textStr="",newStr="",str
	Variable sstop,dum,chi
	
	Variable ii,numRep,jj,val1,val2,pt
	numRep=ItemsInList(list,";")
	
	Make/O/T/N=(numRep) fittedFiles
	Make/O/D/N=(numRep) chiSQ
	Edit fittedFiles,chiSQ
	
	for(ii=0;ii<nPar;ii+=1)		//waves for the parameters
		Make/O/D/N=(numRep) $("par"+num2str(ii)),$("par"+num2str(ii)+"_err")
		AppendToTable $("par"+num2str(ii)),$("par"+num2str(ii)+"_err")
	endfor
	
	for(jj=0;jj<numRep;jj+=1)

		item=StringFromList(jj,list,";")
		DoWindow/F $item
		Notebook $item selection={(2,0), (3,0)}		//paragraph 3 (starts from 0) = filename
		GetSelection notebook,$item,2
		textStr=S_Selection
		textStr=textStr[0,strlen(textStr)-2]		//remove CR
		textStr=textStr[10,strlen(textStr)-1]		//remove "DATA FILE:
		
		fittedFiles[jj] = textStr
//
// results are written as:  "%s = \t%g\t±\t%g\r"
//
		for(ii=0;ii<nPar;ii+=1)		//gather the parameters
			Notebook $item selection={(ii+4,0), (ii+5,0)}		//paragraph 5		= parameter 0
			GetSelection notebook,$item,2
			textStr=S_Selection
			textStr=textStr[0,strlen(textStr)-2]
			// find the "="
			pt = strsearch(textStr,"=",0,0)
			textStr = textStr[pt,strlen(textStr)-1]
			sscanf textStr,"= \t%g\t ± \t%g\r",val1,val2
			
			Print textStr
						
			Wave w1 = $("par"+num2str(ii))
			Wave w2 = $("par"+num2str(ii)+"_err")
			
			w1[jj] = val1
			w2[jj] = val2
			
			//textStr = ReplaceString("=",textStr,"")
			//textStr = ReplaceString("±\t",textStr,"")
			//Notebook Compilation text=textStr+"\r"
			//printf "%s\r",textStr
			//Print strlen(textStr)
		endfor
		//get the chi-squared/N value
		ii += 1 
		Notebook $item selection={(ii+4,0), (ii+5,0)}		//
		GetSelection notebook,$item,2
		textStr=S_Selection
		Print textStr
		
		sscanf textStr,"Npnts = %g\t\tSqrt(X^2/N) = %g\r",dum,chi
		
		chiSQ[jj] = chi	
	endfor
	
	return(0)
End


////
Function fCompile_GlobalFit_Reports(nPar,Files,Param,Param_err)
	Variable nPar
	String Files,Param,Param_Err
	
	String list=SortList(WinList("*", ";", "WIN:16"))
	String item = "",textStr="",fileStr,funcStr,dumStr
	Variable sstop,dum,chi,nFiles,val1,val2
	
	Variable ii,jj

	nFiles = ItemsInList(list)
	Make/O/D/N=(nFiles) $Param,$Param_err
	Make/O/T/N=(nFiles) $Files
	WAVE pw = $Param
	WAVE pw_err = $Param_err
	WAVE/T fw = $Files
	
	for(jj=0;jj<nFiles;jj+=1)
	
		item=StringFromList(jj,list,";")
		DoWindow/F $item
		
		Notebook $item selection={(6,0), (7,0)}		//paragraph 7 (starts from 0) = filename
		GetSelection notebook,$item,2
		textStr=S_Selection
		sscanf textStr,"Data Set:%s ; Function:%s\r",fileStr,funcStr
		fw[jj] = fileStr
//		Notebook Compilation text=fileStr+"\r"
//		Notebook Compilation text=funcStr+"\r"
		
		
//		printf "%s %s\r",textStr,textStr+"_err"

		for(ii=nPar;ii<=nPar;ii+=1)		//gather the parameters
		
			Notebook $item selection={(ii+7,0), (ii+8,0)}		//paragraph 8		= parameter 0
			GetSelection notebook,$item,2
			textStr=S_Selection
//			Print textStr
			sscanf textStr,"%s %g +- %g\r",dumStr,val1,val2
			pw[jj] = val1
			pw_err[jj] = val2
		endfor
		
	endfor

End



//DOES NOT graph the data, does not create a weighting wave
//NSE data assumed to be 4-column 
//q (all the same) - t(ns) - I(q,t) - dI(q,t)
Static Function LoadNSEDataWithName(fileStr)
	String fileStr
	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A/Q fileStr
	String fileName = S_fileName
	
	
	String w0,w1,w2,n0,n1,n2,wt,w3,n3
	Variable rr,gg,bb
	
	// put the names of the four loaded waves into local names
	n0 = StringFromList(0, S_waveNames ,";" )
	n1 = StringFromList(1, S_waveNames ,";" )
	n2 = StringFromList(2, S_waveNames ,";" )
	n3 = StringFromList(3, S_waveNames ,";" )
	
	
	//remove the semicolon AND period from files from the VAX
	w0 = CleanupName((S_fileName+"__Q"),0)
	w1 = CleanupName((S_fileName+"__X"),0)
	w2 = CleanupName((S_fileName+"__Y"),0)
	w3 = CleanupName((S_fileName+"__S"),0)
	
	if(exists(w0) !=0)
		//waves already exist
		KillWaves $n0,$n1,$n2,$n3		// kill the default waveX that were loaded
		return(0)
	endif
	
	// Rename to give nice names
	Rename $n0, $w0
	Rename $n1, $w1
	Rename $n2, $w2
	Rename $n3, $w3

End

/////
//wStr is the coef_ wave with the initial guess
Function FillCoefGuess(wStr)
	String wStr
	
	Wave w=$wStr
	if (! WaveExists(w) )
		DoAlert 0, "The coefficient wave "+wStr+" does not exist. Either create the wave or enter the correct suffix"
		return(0)
	endif
	Wave/T guess=root:AutoFit:guessMatrix
	Variable ii=0,num=numpnts(w)
	Variable tmp
	
	Variable selRow,matrixRow
	selRow = FindSelectedRowInLB(0)	// send 0 to look at the column with filenames

	do
		tmp=w[ii]
		guess[ii][selRow] = num2str(tmp)
		ii+=1
	while(ii<num)
End

/////
//wStr is the hold_ wave with the initial guess
Function FillHoldGuess(wStr)
	String wStr
	
	Wave w=$wStr
	if (! WaveExists(w) )
		DoAlert 0, "The hold wave "+wStr+" does not exist. Either create the wave or enter the correct suffix"
		return(0)
	endif
	Wave/T hold=root:AutoFit:holdMatrix
	Variable ii=0,num=numpnts(w)
	Variable tmp
	
	Variable selRow,matrixRow
	selRow = FindSelectedRowInLB(0)	// send 0 to look at the column with filenames
	
	do
		tmp=w[ii]
		hold[ii][selRow] = num2str(tmp)
		ii+=1
	while(ii<num)
End

/////
//wStr is the Constr_ wave with the initial guess
// --- this is a Text wave
Function FillConstrGuess(wStr)
	String wStr
	
	Wave/T w=$wStr
	if (! WaveExists(w) )
		DoAlert 0, "The Constraint wave "+wStr+" does not exist. Either create the (TEXT) wave or enter the correct suffix"
		return(0)
	endif
	Wave/T constr=root:AutoFit:constrMatrix
	Variable ii=0,num=numpnts(w)
	String tmp
	
	Variable selRow,matrixRow
	selRow = FindSelectedRowInLB(0)	// send 0 to look at the column with filenames

	do
		tmp=w[ii]
		constr[ii][selRow] = tmp
		ii+=1
	while(ii<num)
End

////
//need the extension of the model wave to append
//
// it will plot the UN-smeared model for generating the initial guesses
// -- fitting will use Smeared or unsmeared, depending on the popup selection
//
//
Function fLoadSelected(extStr)
	string extStr

	Variable datafile,ii
	String fullName,dataName,str
	
	WAVE/T fileWave=root:AutoFit:fileListWave
	Wave sel = root:AutoFit:fileSelWave
	ii=0
	do
		if((sel[ii][0] & 0x01) == 1)	// the file is selected in the list box
			datafile = ii
			break
		endif
		ii+=1
	while(ii<numpnts(sel))
	
	//load in the data
	PathInfo dataPath
	fullName = S_path
	fullName += fileWave[datafile][0]

	str = "A_LoadOneDDataToName(\""+fullName+"\",\"\",0,1)"		//don't plot, force overwrite
	Execute str		
	
	dataName=GetFileNameFromPathNoSemi(fullName)
	dataname=CleanupName(dataname,0)
	
	//graph it - creates window named "AutoGraph"
	DoWindow/K tmpGraph
	Execute "DoGraph(\""+dataname+"\")"
	DoWindow/C tmpGraph
//	Wave/Z yw = $("ywave_"+extStr)
//	Wave/Z xw = $("xwave_"+extStr)

	if(exists("ywave_"+extStr) && exists("xwave_"+extStr))
		AppendtoGraph $("ywave_"+extStr) vs $("xwave_"+extStr)
	else
		DoAlert 0,"Model data with the suffix \""+extStr+"\" does not exist. Either plot the model or enter the correct suffix"
	endif

//	ControlInfo/W=AutoFitPanel popup0
//	if(cmpstr(S_Value[0,4], "Smear" ) == 0 )
//		SetDataFolder $dataname
//		if(exists("smeared_"+extStr) && exists("smeared_qvals"))
//			
//			AppendtoGraph $("smeared_"+extStr) vs $("smeared_qvals")
//		else
//			SetDataFolder root:
//			DoAlert 0,"Smeared Model data with the suffix \""+extStr+"\" does not exist. Either plot the model or enter the correct suffix"
//		endif
//		
//	else
//		if(exists("ywave_"+extStr) && exists("xwave_"+extStr))
//			AppendtoGraph $("ywave_"+extStr) vs $("xwave_"+extStr)
//		else
//			DoAlert 0,"Model data with the suffix \""+extStr+"\" does not exist. Either plot the model or enter the correct suffix"
//		endif
//	endif


	SetDataFolder root:
	return(0)
End

//loads the selected file in a temporary graph
Function LoadForGuessProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR ext=root:AutoFit:gExt
	fLoadSelected(ext)
	return(0)
End

//makes the holdWave and Constraint wave that are needed to set the values in the list boxes (and the matrix)
// these are not generated when plotting a model.
Function Make_HoldConstraintEps_Waves()
	
	SVAR  ext=root:AutoFit:gExt
	Variable num=numpnts($("coef_"+ext))
	if(WaveExists($("coef_"+ext)) == 0 )
		DoAlert 0,"coef_"+ext+" does not exist. You must set the prefix correctly and plot the model first"
	else
		Make/O/D/N=(num) $("Hold_"+ext)
		Make/O/T/N=(num) $("Constr_"+ext)
		Make/O/D/N=(num) $("Epsilon_"+ext)=0.0003
	
		String str=WinList("*", ";","WIN:2"),sel
		Prompt sel, "Select Table to Append Waves", popup str
		DoPrompt "asdf",sel
		if (V_Flag)
			return 0	// user canceled
		endif
		DoWindow/F $sel
		AppendToTable $("Hold_"+ext), $("Constr_"+ext), $("Epsilon_"+ext)
	endif
End
//needs the name (as a string) of the coefficient wave
//it assumes "coef_" plus an extension
//
Function UseCoefAsGuess(ctrlName) : ButtonControl
	String ctrlName
	
	String wStr = "coef_"
	SVAR ext=root:AutoFit:gExt
	FillCoefGuess(wStr+ext)
	DisplayGuess()
	return(0)
End

//needs the name (as a string) of the hold string wave
//it assumes "hold_" plus an extension
//
Function UseHoldAsGuess(ctrlName) : ButtonControl
	String ctrlName
	
//	String wStr = "hold_"
//	SVAR ext=root:AutoFit:gExt
//	FillHoldGuess(wStr+ext)
//	DisplayGuess()
	return(0)
End

//needs the name (as a string) of the coefficient wave
//it assumes "constr" plus an extension
//
Function UseConstraintsAsGuess(ctrlName) : ButtonControl
	String ctrlName
	
//	String wStr = "Constr_"
//	SVAR ext=root:AutoFit:gExt
//	FillConstrGuess(wStr+ext)
//	DisplayGuess()
	return(0)
End

