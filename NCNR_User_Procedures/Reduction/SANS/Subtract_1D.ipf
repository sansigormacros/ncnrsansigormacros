#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

///////////////////////
//
// Procedures to manipulate 1-D datasets
// specifically, to subtract 1-D data (sample - buffer)
// as is typically done for biological samples in buffer solution
//
// This was written largely by Dobrin Bossev
// - I simply adapted it to work cleanly with the SANS Reduction Macros
// - 14MAY03 SRK
//
//
// - could be expanded to do more manipulations, but could quickly
// become cumbersome (like the Arithmetic Panel)
//
// - could allow for interpolation to match data sets, or only a partial
// q-range for the "solvent" file
//
///////////////////////

// main entry procedure for subtraction panel
// re-initializes necessary folders and waves
Proc OpenSubtract1DPanel()
	DoWindow/F Subtract_1D_Panel
	if(V_Flag==0)
		Init_Subtract1D()
		Subtract_1D()		//the panel
		Plot_Sub1D()		//the graph
	endif
End

// initializes data folder and waves needed for the panel (contains a listbox) 
Proc Init_Subtract1D()
	//create the data folder
	NewDataFolder/O/S root:myGlobals:Subtract1D
	//create the waves and variables
	String/G gName1="<none>"
	String/G gName2="<none>"
	Variable/G gSolvnormal=0
	Variable/G gPresetc=0
	Variable/G gS1=0
	Variable/G gS2=0
	Variable/G gCorrection=1
	Variable/G gPlotState=0
	Variable/G gNullSolvent=0
		
	Make/N=1/D/O w01,w11,w21,w31,w41,w51
	Make/N=1/D/O w02,w12,w22,w32,w42,w52
	Duplicate/O w01 xsample
	Duplicate/O w11 ysample
	Duplicate/O w21 ssample
	Duplicate/O w02 xsolvent
	Duplicate/O w12 ysolvent
	Duplicate/O w22 ssolvent
	Duplicate/O w01 xresult
	Duplicate/O w11 yresult
	Duplicate/O w21 sresult
	
	SetDataFolder root:
End

//draws the panel to control the subtraction
Proc Subtract_1D()
	if(root:myGlobals:gIsMac==1)
		NewPanel /W=(467,139,821,423)/K=2  as "Solvent Subtraction"
	else
		NewPanel /W=(522,139,876,422)/K=2  as "Solvent Subtraction"
	endif
	DoWindow/C Subtract_1D_Panel
	SetDrawEnv fsize=10, fstyle= 5,textrgb=(65535,0,0)
	DrawText 10,20,"Sample Scattering File:"
	SetDrawEnv textrgb= (0,0,65280),fstyle=5,fsize=10
	DrawText 10,90,"Solvent Scattering File:"
	SetDrawEnv  fsize=10, fstyle= 5
	DrawText 10,165,"Result:"
	//add the controls
	Button button_0,pos={150,36},size={90,20},proc=LoadSample, title="Load Sample"
	Button button_0,help={"This will load the 6 column Sample Scattering File"}
	Button button_1,pos={150,106},size={90,20},proc=LoadSolvent,title="Load Solvent"
	Button button_1,help={"This will load the 6 column Solvent Scattering File"}
	Button button_4,pos={18,248},size={90,20},proc=Calculate,title="Calculate"
	Button button_4,help={"This will subtract the intensities of the two files according to the shown expression"}
	Button button_5,pos={122,248},size={110,20},proc=SaveResult,title="Save Result"
	Button button_5,help={"This will save the result in a file"}
	Button button_6,pos={10,196},size={125,20},proc=MatchingRange,title="Matching Range"
	Button button_6,help={"This will capture the range between the two cursors to determine f"}
	Button button_2,pos={275,248},size={50,20},proc=Sub1D_DoneButton,title="Done"
	Button button_2,help={"Closes both the panel and the associated graph"}
	Button button_3,pos={300,36},size={25,20},proc=ShowSub1DHelp,title="?"
	Button button_3,help={"Shows help file for subtracting 1-D data sets"}
	CheckBox check_0,pos={14,40},size={117,14},proc=CheckCon,title="Rescale Sample file?"
	CheckBox check_0,value= root:myGlobals:Subtract1D:gSolvnormal
	CheckBox check_1,pos={235,187},size={134,14},proc=CheckCon,title="Preset     manually?"
	CheckBox check_1,value= root:myGlobals:Subtract1D:gPresetc
	CheckBox check_2,pos={225,150},size={134,14},proc=NullSolventCheck,title="Solvent = 1?"
	CheckBox check_2,value= root:myGlobals:Subtract1D:gNullSolvent,disable=2
	//
	ValDisplay valdisp_0,pos={145,187},size={70,18},title="Start ",Font="Arial",fsize=10
	ValDisplay valdisp_0,limits={0,0,0},barmisc={0,1000},value= root:myGlobals:Subtract1D:gS1
	ValDisplay valdisp_1,pos={145,207},size={70,18},title="End  ",Font="Arial",fsize=10
	ValDisplay valdisp_1,limits={0,0,0},barmisc={0,1000},value= root:myGlobals:Subtract1D:gS2
	//
	SetVariable setvar_0,pos={250,207},size={70,19},title=":",font="Arial",fsize=10
	SetVariable setvar_0,limits={-inf,inf,0},value=root:myGlobals:Subtract1D:gCorrection
	//sample name
	SetVariable setvar_1,pos={150,7},size={200,20},title=":",noEdit=1
	SetVariable setvar_1,limits={1,1,0},value=root:myGlobals:Subtract1D:gName1
	//solvent name
	SetVariable setvar_2,pos={150,77},size={200,20},title=":",noEdit=1
	SetVariable setvar_2,limits={1,1,0},value=root:myGlobals:Subtract1D:gName2
	//
	SetDrawEnv fname="Times", fsize=14, fstyle= 3
	DrawText 289,202,"f"
	SetDrawEnv fname="Times", fsize=14, fstyle= 3
	DrawText 241,223,"f"
	//draw the fancy text on the panel
	WriteExpression(0)
	
EndMacro

Function ShowSub1DHelp(ctrlName) : ButtonControl
	String ctrlName
	DisplayHelpTopic/Z/K=1 "SANS Data Reduction Tutorial[Subtract 1D Data]"
	if(V_flag !=0)
		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
	endif
End
//kills both the panel and the graph, and then the data folder
Function Sub1D_DoneButton(ctrlName)
	String ctrlName
	
	DoWindow/K Subtract_1D_Panel
	DoWindow/K Plot_Sub1D
	KillDataFolder root:myGlobals:Subtract1D
	return(0)
End


Function Calculate(ctrlName) : ButtonControl
	String ctrlName

//	SetDataFolder root:myGlobals:Subtract1D
	Variable p1,p2
	SVAR gName1 = root:myGlobals:Subtract1D:gName1
	SVAR gName2 = root:myGlobals:Subtract1D:gName2
	//check for files
	if(cmpstr(gName2,"<none>") == 0)
		DoAlert 0, "Load Solvent file!"
		return(1)
	endif
	if(cmpstr(gName1,"<none>") == 0)
		DoAlert 0, "Load Sample file!"
		return(1)
	endif
	
	WAVE xsample=root:myGlobals:Subtract1D:xsample
	WAVE xsolvent=root:myGlobals:Subtract1D:xsolvent
	//WAVE w01=root:myGlobals:Subtract1D:w01
	WAVE ysample=root:myGlobals:Subtract1D:ysample		//w11
	WAVE ssample=root:myGlobals:Subtract1D:ssample		//w21
	WAVE ysolvent=root:myGlobals:Subtract1D:ysolvent			//w12
	WAVE ssolvent=root:myGlobals:Subtract1D:ssolvent			//w22
	
	NVAR gPresetc = root:myGlobals:Subtract1D:gPresetc
	NVAR gSolvNormal = root:myGlobals:Subtract1D:gSolvNormal
	NVAR gCorrection = root:myGlobals:Subtract1D:gCorrection
	NVAR gNullSolvent = root:myGlobals:Subtract1D:gNullSolvent
	NVAR gS1 = root:myGlobals:Subtract1D:gS1
	NVAR gS2 = root:myGlobals:Subtract1D:gS2

//no interpolation - exit if files are not EXACTLY the same length
// and have EXACTLY the same q-values
//
//////////////	
//	Variable maxDiff
//	//check that both files are of the same length
//	if (numpnts(xsample)!=numpnts(xsolvent))
//		DoAlert 0, "The lengths of Sample and Solvent files are NOT identical!"
//		return(1)
//	endif
//	
//	//check that both files have the same q-values
//	//currently, abort, but could offer to interpolate
//	Duplicate/O xsample helpwave
//	helpwave = 100*abs((xsample - xsolvent)/xsample)		//% difference in q-values
//	WaveStats /Q helpwave
//	KillWaves /Z helpwave
//	maxDiff = V_max
//	if(maxDiff > 0.5)		//each q-value must match to within 0.5%
//		DoAlert 0, "The q-values of Sample and Solvent files are NOT identical!"
//		return(1)
//	endif
///////////////
	
	//set up for interpolation
	Duplicate/O xsample root:myGlobals:Subtract1D:xsolv_interp	//make the solvent x match the sample
	Duplicate/O xsample root:myGlobals:Subtract1D:ysolv_interp
	Duplicate/O xsample root:myGlobals:Subtract1D:ssolv_interp
	WAVE xsolv_interp = root:myGlobals:Subtract1D:xsolv_interp
	WAVE ysolv_interp = root:myGlobals:Subtract1D:ysolv_interp
	WAVE ssolv_interp = root:myGlobals:Subtract1D:ssolv_interp
	ysolv_interp = interp(xsolv_interp, xsolvent, ysolvent )
	ssolv_interp = interp(xsolv_interp, xsolvent, ssolvent )
	
	Duplicate/O xsample root:myGlobals:Subtract1D:xresult
	Duplicate/O ysample root:myGlobals:Subtract1D:yresult
	Duplicate/O ssample root:myGlobals:Subtract1D:sresult
	WAVE xresult = root:myGlobals:Subtract1D:xresult
	WAVE yresult = root:myGlobals:Subtract1D:yresult
	WAVE sresult = root:myGlobals:Subtract1D:sresult
	
	if (gPresetc==0)		//find the constant from the cursor range
		Duplicate/O ysample helpwave
		if(gSolvNormal && gNullSolvent)
			helpWave = ysample				//ysolvent == 0 under these conditions
		else
			helpwave = ysample/ysolv_interp		//get the ratio = I(sample)/I(solvent)
		endif
		//gS1 and gS2 are qvalues now, convert them back to points
		//on the interpolated xsolv_interp
		p1 = BinarySearch(xsolv_interp, gS1 )
		p2 = BinarySearch(xsolv_interp, gS2 )
		//print p1,p2
		WaveStats/Q/R=[p1,p2] helpwave		//just in the selected range
		gCorrection = V_avg
		KillWaves /Z helpwave
	endif
	if (gSolvnormal==0)
		yresult = ysample - gCorrection*ysolv_interp
		sresult = sqrt(ssample^2+gCorrection*gCorrection*ssolv_interp^2)
	else
		yresult = ysample/gCorrection - ysolv_interp
		sresult = sqrt((ssample^2)/gCorrection/gCorrection+ssolv_interp^2)
	endif
	return(0)
End

Proc LoadSample(ctrlName) : ButtonControl
	String ctrlName
	
	LoadFile_Sub1D(1)
	SetDataFolder root:myGlobals:Subtract1D
	Duplicate/O w01 xsample
	Duplicate/O w11 ysample
	Duplicate/O w21 ssample
	SetDataFolder root:
	
	//allow user to set unity/null background, now that sample data exists
	CheckBox check_2 win=Subtract_1D_Panel,disable=0
	//if solvent was set to one (or zero), toggle the box so the 
	//"solvent" set is updated to reflect the q-values of the newly
	//loaded sample
	ControlInfo check_2
	if(V_Value==1)
		NullSolventCheck("",1)		//fakes as if the box was checked
	Endif
	
End


Proc LoadSolvent(ctrlName) : ButtonControl
	String ctrlName

	LoadFile_Sub1D(2)
	SetDataFolder root:myGlobals:Subtract1D
	Duplicate/O w02 xsolvent
	Duplicate/O w12 ysolvent
	Duplicate/O w22 ssolvent
	
	if (cmpstr(gName2,"<none>")!=0)
		Cursor A, ysolvent, leftx(xsolvent)
		Cursor/A=0 B, ysolvent, rightx(xsolvent)
		//make sure that the "solvent ==1" checkbox is not checked
		CheckBox check_2,value=0
		//MatchingRange("none")
	endif
	SetDataFolder root:
End

//returns the Matching range to use in terms of q-values
//rather than points, which will be incorrect if the
//solvent data needs to be interpolated
Function MatchingRange(ctrlName) : ButtonControl
	String ctrlName

	SVAR name2 = root:myGlobals:Subtract1D:gName2
	NVAR s1 = root:myGlobals:Subtract1D:gS1
	NVAR s2 = root:myGlobals:Subtract1D:gS2
	if (cmpstr(name2,"<none>") != 0)
		s1=min(pcsr(A,"Plot_Sub1D" ),pcsr(B,"Plot_Sub1D"))
		s2=max(pcsr(A,"Plot_Sub1D" ),pcsr(B,"Plot_Sub1D"))
		Wave qval=root:myGlobals:Subtract1D:xsolvent		//this will exist
		s1 = qval[s1]
		s2 = qval[s2]
		//print s1,s2
	endif
End

Proc Plot_Sub1D()
	SetDataFolder root:myGlobals:Subtract1D
	if(root:myGlobals:gIsMac==1)
		Display/W=(14,44,454,484)/K=1 ysample vs xsample
	else
		Display/W=(14,44,350,380)/K=1 ysample vs xsample
	endif
	DoWindow/C Plot_Sub1D
	ModifyGraph rgb(ysample)=(65535,0,0)
	ErrorBars/T=0 ysample Y,wave=(ssample,ssample)
	AppendToGraph/L ysolvent vs xsolvent
	ModifyGraph rgb(ysolvent)=(0,0,65535)
	ErrorBars/T=0 ysolvent Y,wave=(ssolvent,ssolvent)
	//AppendToGraph/R yresult vs xresult
	AppendToGraph/L yresult vs xresult
	ModifyGraph rgb(yresult)=(0,65535,0)
	ErrorBars/T=0 yresult Y,wave=(sresult,sresult)
	ModifyGraph mode=3, msize=2, marker=19, mirror=1, tick=2, log(bottom)=1
	Legend/C/N=text0/J/A=LT/X=2/Y=2 "\\s(ysample) Sample\r\\s(ysolvent) Solvent\r\\s(yresult) Result"
	ShowInfo
	Label left "Sample, Solvent I (cm\\S-1\M)"
	
	String angst = StrVarOrDefault("root:Packages:NIST:gAngstStr", "A" )
	Label bottom "q ("+angst+"\\S-1\M)"
//	Label right "Result I/cm\\S-1"
	ControlBar 40
	Button button_7,pos={10,10},size={125,20},proc=MatchingRange,title="Matching Range"
	Button button_7,help={"This will capture the range between the two cursors to determine f"}
	CheckBox check_0,pos={170,12},size={117,14},proc=PlotSub1DCheck,title="Log I(q)?"
	CheckBox check_0,value= root:myGlobals:Subtract1D:gPlotState
	SetDataFolder root:
End

//toggles the y-axis scaling of the graph between log and linear
// the bottom axis is always log scale
//
Proc PlotSub1DCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SetdataFolder root:myGlobals:Subtract1D
	if(checked)
		//make log scale
		ModifyGraph log=1
	else
		//make linear scale on y-axis
		Modifygraph log=0,log(bottom)=1
	endif
	gPlotState = checked
	SetDataFolder root:
End

//
Proc NullSolventCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SetDataFolder root:myGlobals:Subtract1D
	
	Variable solvValue
	String nameStr=""
	if(gSolvNormal)
		CheckBox check_2,title="Solvent = 0?"
		solvValue=0
		nameStr="Solvent values set to zero"
	else
		CheckBox check_2,title="Solvent = 1?"
		solvValue=1
		nameStr="Solvent value set to one"
	endif
	
	if(checked)
		//zero/one for the solvent
		Duplicate/O w01 xsolvent		//duplicate the sample data
		Duplicate/O w11 ysolvent
		Duplicate/O w21 ssolvent
		ysolvent=solvValue
		ssolvent=0
		if(gS1==0 && gS2 ==0)
			Cursor A, ysample, leftx(xsample)	// put the cursors on the sample data
			Cursor/A=0 B, ysample, rightx(xsample)
		else
			Cursor A, ysample, BinarySearch(xsample, gS1 )		// put the cursors on the sample data
			Cursor/A=0 B, ysample, BinarySearch(xsample, gS2 )
		endif
		gName2 = nameStr
	else
		gName2 = "<none>"
	Endif
	gNullSolvent=checked
	
	SetDataFolder root:
End

Proc CheckCon(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	SetdataFolder root:myGlobals:Subtract1D
	if (cmpstr(ctrlName,"check_0") == 0)		//box to set the normalization
		gSolvnormal =checked
		WriteExpression(checked)		//draw the text of the expression being calculated
		ControlInfo check_2
		NullSolventCheck("",V_Value)
	else
		//check_1, 	box to manually set the preset
	  gPresetc = checked
	endif
	SetDataFolder root:
End

//type = 1 specifies sample data
//type = 2 specifies solvent data
//
// any existing data will be overwritten
//
// need to retain header information for later save
// will need a more sophisticated open/close to get the header
//
//don't try to re-write as a function - not worth the effort
//
Proc LoadFile_Sub1D(type)
	Variable type	
	
	String n0,n1,n2,n3,n4,n5,help
	
	Variable refnum,numLines,numData,numHdr,ii
	String fileStr="",junkStr=""
	
	//junkStr = PadString(junkStr, 100, 0 )
	fileStr=DoOpenFileDialog("pick a 1D data set")
	if(cmpstr(fileStr,"")==0)
		return		//no file selected, exit
	endif
	
	SetDataFolder root:myGlobals:Subtract1D
	LoadWave/G/D/A fileStr
	If (V_flag==6)
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		n4 = StringFromList(4, S_waveNames ,";" )
		n5 = StringFromList(5, S_waveNames ,";" )
		Duplicate/O $n0, $("w0" + num2istr(type))
		Duplicate/O $n1, $("w1" + num2istr(type))
		Duplicate/O $n2, $("w2" + num2istr(type))
		Duplicate/O $n3, $("w3" + num2istr(type))
		Duplicate/O $n4, $("w4" + num2istr(type))
		Duplicate/O $n5, $("w5" + num2istr(type))
		if (type==1) 
			gName1 = S_fileName
			//read in the header of the sample file
			// not yet implemented
			numLines = CountNumLines(fileStr)
			numData = numpnts($n0)
			numHdr = numLines - numData
			Make/T/O/N=(numHdr) SampleHeader
			Open/R refNum as fileStr
			ii=0
			do
				FReadLine refnum, junkStr
				SampleHeader[ii] = junkStr
				ii+=1
			while(ii<numHdr)
			Close refnum
		else
			gName2 = S_fileName
		endif
	
	elseif (V_flag == 4)
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		n3 = StringFromList(3, S_waveNames ,";" )
		Duplicate/O $n0, $("w0" + num2istr(type))
		Duplicate/O $n1, $("w1" + num2istr(type))
		Duplicate/O $n2, $("w2" + num2istr(type))
		Duplicate/O $n3, $("w3" + num2istr(type))
		if (type==1) 
			gName1 = S_fileName
			//read in the header of the sample file
			// not yet implemented
			numLines = CountNumLines(fileStr)
			numData = numpnts($n0)
			numHdr = numLines - numData
			Make/T/O/N=(numHdr) SampleHeader
			Open/R refNum as fileStr
			ii=0
			do
				FReadLine refnum, junkStr
				SampleHeader[ii] = junkStr
				ii+=1
			while(ii<numHdr)
			Close refnum
		else
			gName2 = S_fileName
		endif
		
	elseif (V_flag == 3)
		n0 = StringFromList(0, S_waveNames ,";" )
		n1 = StringFromList(1, S_waveNames ,";" )
		n2 = StringFromList(2, S_waveNames ,";" )
		Duplicate/O $n0, $("w0" + num2istr(type))
		Duplicate/O $n1, $("w1" + num2istr(type))
		Duplicate/O $n2, $("w2" + num2istr(type))
		if (type==1) 
			gName1 = S_fileName
			//read in the header of the sample file
			// not yet implemented
			numLines = CountNumLines(fileStr)
			numData = numpnts($n0)
			numHdr = numLines - numData
			Make/T/O/N=(numHdr) SampleHeader
			Open/R refNum as fileStr
			ii=0
			do
				FReadLine refnum, junkStr
				SampleHeader[ii] = junkStr
				ii+=1
			while(ii<numHdr)
			Close refnum
		else
			gName2 = S_fileName
		endif
	else
		if (V_flag>0)
			DoAlert 0, "This is NOT a 3-, 4- or 6-column file !"
		endif
	endif
	//do some cleanup
	
	KillWaves/Z wave0,wave1,wave2,wave3,wave4,wave5,wave6,wave7,wave8,wave9,wave10
	
	setDataFolder root:
end

Function CountNumLines(fileStr)
	String fileStr
	
	Variable num,refnum
	num=0
	Open/R refNum as fileStr
	do
		FReadLine refnum, junkStr
		FStatus refnum
//		Print junkStr
		num+=1
	while(V_FilePos<V_logEOF)
//	print "numlines = ",num
	Close refnum
	return(num)
End


Function SaveResult(ctrlName) : ButtonControl
	String ctrlName

	WAVE xresult = root:myGlobals:Subtract1D:xresult
	WAVE yresult = root:myGlobals:Subtract1D:yresult
	WAVE sresult = root:myGlobals:Subtract1D:sresult
	WAVE w31 = root:myGlobals:Subtract1D:w31
	WAVE w41 = root:myGlobals:Subtract1D:w41
	WAVE w51 = root:myGlobals:Subtract1D:w51
	WAVE/T hdr = root:myGlobals:Subtract1D:SampleHeader
	
	//check each wave for existence
	Variable err=0,refnum
	String fileName=""
	String formatStr = ""
	if (WaveExists(w41) && WaveExists(w51))
		//6-column
		formatStr = "%15.4g %15.4g %15.4g %15.4g %15.4g %15.4g\r\n"
	elseif(WaveExists(w31))
		//4-column (ILL)
		formatStr = "%15.4g %15.4g %15.4g %15.4g\r\n"
	else
		//3-column
		formatStr = "%15.4g %15.4g %15.4g\r\n"
	endif
	err += 1 - WaveExists(xresult)
	err += 1 - WaveExists(yresult)
	err += 1 - WaveExists(sresult)
	//err += 1 - WaveExists(w31)
	//err += 1 - WaveExists(w41)
	//err += 1 - WaveExists(w51)
	err += 1 - WaveExists(hdr)
	
	if(err>0)
		DoAlert 0,"We need at least 3 column data - I can't write out the file"
		return(1)
	endif
	
	SVAR loadedFile=root:myGlobals:Subtract1D:gName1
	fileName = DoSaveFileDialog("Save Data as",fname=loadedFile,suffix="b")
	if(cmpstr(fileName,"")==0)
		return(1)
	endif
	Open refNum as fileName
	wfprintf refnum,"%s\n",hdr		//strings already have \r?
	if (WaveExists(w41) && WaveExists(w51))
		wfprintf refnum, formatStr, xresult,yresult,sresult,w31,w41,w51
	elseif (WaveExists(w31))
		wfprintf refnum, formatStr, xresult,yresult,sresult,w31
	else
		wfprintf refnum,formatStr, xresult,yresult,sresult
	endif
	Close refnum
	
	return(0)
End

Proc WriteExpression(choice)
	Variable choice

	SetDrawEnv /W=Subtract_1D_Panel linefgc= (65535,65535,65535)
	DrawRect 90,140,207,174
	SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,65535,0)
	DrawText 100,168,"I"
	SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
	DrawText 100,168,"  ="
	SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (65535,0,0)
	DrawText 100,168,"     I"
	SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,65535)
	DrawText 100,168,"              I"
	if (choice==0)
		SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
		DrawText 100,168,"       -"
		SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
		DrawText 100,168,"          f "
		SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
		DrawText 100,168,"            *"
	else
		SetDrawEnv fname="Times", fsize=22, fstyle= 1,textrgb= (0,0,0)
		DrawText 100,168,"       /"
		SetDrawEnv fname="Times", fsize=22, fstyle= 2,textrgb= (0,0,0)
		DrawText 100,168,"         f "
		SetDrawEnv fname="Symbol", fsize=22, fstyle= 1,textrgb= (0,0,0)
		DrawText 100,168,"           -"
	endif
End