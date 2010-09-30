#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


// this was a duplicate of the LinearizedFits procedure file. This one was not being properly updated,
// so this one has been cut. The only differences in the files are the "A_" prefixes, and the location
// of the data folder. the old FIT_Ops location was:
//				NewDataFolder/O root:myGlobals:FIT
//
// in the LinearizedFits, it's a more standard location:
//		NewDataFolder/O root:Packages:NIST:FIT
//
//
// -- in case an old experiment points to FIT_Ops, load this instead


#include "LinearizedFits_v40"




////**************************
////procedures for creating and initializing the FIT panel
////global variables (numerical only) are kept in root:myGlobals:FIT folder,
////created as needed
////
////also contains code for the FIT_RPA panel and its fitting procedures
////
////**************************
////
//
////main procedures to open the panel, initializing the data folder and global variables
////as necessary. All are kept in a :FIT subfolder to avoid overlap with other variables
////
//// To use any of the fit functions in the FIT panel, I(Q) data must already
//// be loaded into memory (using "plot" from the 1-D data operations
//// ** this may be useful to change in the future, replacing the 3 popups
//// with a list box - allowing the user to pick/load the data from the fit panel
//// and not offering any choice of q/i/s waves to use. (more consistent with the operation
//// of the FIT/RPA panel)
////
//Proc OpenFitPanel()
//	If(WinType("FitPanel") == 0)
//		//create the necessary data folder
//		NewDataFolder/O root:myGlobals:FIT
//		//initialize the values
//		Variable/G root:myGlobals:FIT:gLolim = 0.02
//		Variable/G root:myGlobals:FIT:gUplim = 0.04
//		Variable/G root:myGlobals:FIT:gExpA = 1
//		Variable/G root:myGlobals:FIT:gExpB = 1
//		Variable/G root:myGlobals:FIT:gExpC = 1
//		Variable/G root:myGlobals:FIT:gBack = 0
//		String/G root:myGlobals:FIT:gDataPopList = "none"
//		FitPanel()
//	else
//		//window already exists, just bring to front for update
//		DoWindow/F FitPanel
//		CheckBox check0,value=0		//deselect the checkbox to use cursors
//	endif
//	//pop the file menu
//	FIT_FilePopMenuProc("",1,"")
//End
//
////the actual window recreation macro to draw the fit panel. Globals and data folder must 
//// already be initialized
//Window FitPanel()
//	String angst = root:myGlobals:gAngstStr
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(461,46,735,455)/K=1
//	ModifyPanel cbRGB=(32768,54615,65535), fixedSize=1
//	SetDrawLayer UserBack
//	DrawText 56,20,"Select Experimental Data"
//	DrawText 66,138,"q-range to fit ("+angst+"^-1)"
//	DrawText 42,268,"Select the y and x-axis scaling"
//	DrawLine 1,21,271,21
//	DrawLine -1,272,273,272
//	DrawLine -1,140,272,140
////	PopupMenu xwave,pos={13,31},size={158,19},title="q-values"
////	PopupMenu xwave,help={"Select the experimental q-values. If no data is available, use Macro LoadQISData or LoadQSIGData."}
////	PopupMenu xwave,mode=1,value= #"WaveList(\"*q\",\";\",\"\")"
//	PopupMenu ywave,pos={13,40},size={154,19},title="Data File"
//	PopupMenu ywave,help={"Select the experimental intensity values"}
//	PopupMenu ywave,mode=1,value=root:myGlobals:FIT:gDataPopList,proc=FIT_FilePopMenuProc
//	Button loadButton,pos={25,80},size={130,20},proc=FIT_Load_Proc,title="Load and Plot File"
//	Button loadButton,help={"After choosing a file, load it into memory and plot it with this button."}
//	Button helpButton,pos={200,80},size={25,20},proc=showFITHelp,title="?"
//	Button helpButton,help={"Show help file for linearized fitting"}
////	PopupMenu ewave,pos={13,87},size={186,19},title="Std. Deviation"
////	PopupMenu ewave,help={"Select the standard deviation of the intensity"}
////	PopupMenu ewave,mode=1,value= #"WaveList(\"*s\",\";\",\"\")"
//	PopupMenu ymodel,pos={20,281},size={76,19},title="y-axis"
//	PopupMenu ymodel,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
//	PopupMenu ymodel,mode=1,value= #"\"I;log(I);ln(I);1/I;I^a;Iq^a;I^a q^b;1/sqrt(I);ln(Iq);ln(Iq^2)\""
//	Button GoFit,pos={60,367},size={70,20},proc=DispatchModel,title="Do the Fit"
//	Button GoFit,help={"This button will do the specified fit using the selections in this panel"}
//	Button DoneButton,pos={180,367},size={50,20},proc=FITDoneButton,title="Done"
//	Button DoneButton,help={"This button will close the panel and the associated graph"}
//	SetVariable lolim,pos={64,147},size={134,17},title="Lower Limit"
//	SetVariable lolim,help={"Enter the lower q-limit to perform the fit ("+angst+"^-1)"}
//	SetVariable lolim,limits={0,5,0},value= root:myGlobals:FIT:gLolim
//	SetVariable uplim,pos={63,169},size={134,17},title="Upper Limit"
//	SetVariable uplim,help={"Enter the upper q-limit to perform the fit ("+angst+"^-1)"}
//	SetVariable uplim,limits={0,5,0},value= root:myGlobals:FIT:gUplim
//	SetVariable expa,pos={13,311},size={80,17},title="pow \"a\""
//	SetVariable expa,help={"This sets the exponent \"a\" for some y-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//	SetVariable expa,limits={-2,10,0},value= root:myGlobals:FIT:gExpA
//	SetVariable expb,pos={98,311},size={80,17},title="pow \"b\""
//	SetVariable expb,help={"This sets the exponent \"b\" for some x-axis formats. The value is ignored if the model does not use an adjustable exponent"}
//	SetVariable expb,limits={0,10,0},value= root:myGlobals:FIT:gExpB
//	PopupMenu xmodel,pos={155,280},size={79,19},title="x-axis"
//	PopupMenu xmodel,help={"This popup selects how the x-axis will be linearized given the chosen data"}
//	PopupMenu xmodel,mode=1,value= #"\"q;log(q);q^2;q^c\""
//	CheckBox check0,pos={18,223},size={240,20},title="Use cursor range from FitWindow"
//	CheckBox check0,help={"Checking this will perform a fit between the cursors on the graph in FitWindow and ignore the numerical limits typed above"},value=0
//	SetVariable back,pos={70,338},size={139,17},title="background"
//	SetVariable back,help={"This constant background value will be subtracted from the experimental intensity before fitting is done"}
//	SetVariable back,limits={-Inf,Inf,0},value= root:myGlobals:FIT:gBack
//	SetVariable expc,pos={182,310},size={80,17},title="pow \"c\""
//	SetVariable expc,help={"This sets the exponent \"c\" for some x-axis formats. The value is ignored if the model does not use \"c\" as an adjustable exponent"}
//	SetVariable expc,limits={-10,10,0},value= root:myGlobals:FIT:gExpC
//	Button sh_all,pos={65,193},size={130,20},proc=ShowAllButtonProc,title="Show Full q-range"
//	Button sh_all,help={"Use this to show the entire q-range of the data rather than just the fitted range."}
//EndMacro
//
//
//Proc FITDoneButton(ctrlName): ButtonControl
//	String ctrlName
//	DoWindow/K FitWindow
//	DoWindow/K FitPanel
//end
//
//Proc showFITHelp(ctrlName): ButtonControl
//	String ctrlName
//	DisplayHelpTopic/K=1/Z "SANS Data Reduction Tutorial[Fit Lines to Your Data]"
//	if(V_flag !=0)
//		DoAlert 0,"The SANS Data Reduction Tutorial Help file could not be found"
//	endif
//end
//
////Loads the selected file for fitting
////graphs the data as needed
//Proc FIT_Load_Proc(ctrlName): ButtonControl
//	String ctrlName
//	
//	//Load the data
//	String tempName="",partialName=""
//	Variable err
//	ControlInfo $"ywave"
//	//find the file from the partial filename
//	If( (cmpstr(S_value,"")==0) || (cmpstr(S_value,"none")==0) )
//		//null selection, or "none" from any popup
//		Abort "no file selected in popup menu"
//	else
//		//selection not null
//		partialName = S_value
//		//Print partialName
//	Endif
//	//get a valid file based on this partialName and catPathName
//	tempName = FindValidFilename(partialName)
//
//	//prepend path to tempName for read routine 
//	PathInfo catPathName
//	
//	tempName = S_path + tempName
//	
//	//load in the data (into the its own folder)
//	A_LoadOneDDataWithName(tempName,0)
//	//Print S_fileName
//	//Print tempName
//	
//	String cleanLastFileName = CleanupName(root:Packages:NIST:gLastFileName,0)
//
//	tempName="root:"+cleanLastFileName+":"+cleanLastFileName
//	Duplicate/O $(tempName+"_q") xAxisWave
//	//tempName=cleanLastFileName+"_i"
//	Duplicate/O $(tempName+"_i") yAxisWave
//	//tempName=cleanLastFileName+"_s"
//	Duplicate/O $(tempName+"_s") yErrWave
//
//	//Plot, and adjust the scaling to match the axis scaling set by the popups
//	Rescale_Data()
//	
//End
//
////gets a valid file list (simply not the files with ".SAn" in the name)
////
//Function FIT_FilePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//	
//	String tempStr=ReducedDataFileList(ctrlName)
//	if(strlen(tempStr)==0)
//		tempStr = "Pick the data path"
//	Endif
//	String/G root:myGlobals:FIT:gDataPopList =tempStr		//function is in NSORT.ipf
//	ControlUpdate ywave
//	
//End
//
////direct porting of the fit program from the VAX, with no corrections and only
////minor modifications of additional  linearizations and the option
////to subtract a constant (q-independent) background value before doing any
////of the fits. The original data on disk (and as loaded) is never modified, all
////manipulation is done from a copy of the data.
//
////button procedure to show the entire axis range of the data, rather than just
////the fitted range, which is the default display after a fit is performed
////
//Function ShowAllButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	//bring the FitWindow to the front and Autoscale the axes
//	DoWindow/F FitWindow
//	SetAxis/A
//End
//
//// function that takes the current dataset (already loaded)
//// and replots it based on the X/Y axis scaling selected in the popups
//// (does not fit the data)
////
//Function Rescale_Data()
//	
//	//Scaling exponents and background value
//	Variable pow_a,pow_b,pow_c,bkg
//	ControlInfo/W=FitPanel expa
//	pow_a = V_value
//	ControlInfo/W=FitPanel expb
//	pow_b = V_value
//	ControlInfo/W=FitPanel expc
//	pow_c = V_value
//	ControlInfo/W=FitPanel back
//	bkg = V_value
//	
////check for physical limits on exponent values
//// if bad values found, alert, and reset to good values so the rescaling can continue
//	NVAR gA = root:myGlobals:FIT:gExpA
//	NVAR gB = root:myGlobals:FIT:gExpB
//	NVAR gC = root:myGlobals:FIT:gExpC
//	if((pow_a < -2) || (pow_a > 10))
//		DoAlert 0,"Exponent a must be in the range (-2,10) - the exponent a has been reset to 1"
//		gA = 1
//	endif
//	if((pow_b < 0) || (pow_b > 10))
//		DoAlert 0,"Exponent b must be in the range (0,10) - the exponent b has been reset to 1"
//		gB = 1
//	endif
//	//if q^c is the x-scaling, c must be be within limits and also non-zero
//	ControlInfo/W=FitPanel xModel
//	If (cmpstr("q^c",S_Value) == 0)
//		if(pow_c == 0) 
//			DoAlert 0,"Exponent c must be non-zero, c has been reset to 1"
//			gC = 1
//		endif
//		if((pow_c < -10) || (pow_c > 10))
//			DoAlert 0,"Exponent c must be in the range (-10,10), c has been reset to 1"
//			gC = 1
//		endif
//	endif
//	
//	//do the rescaling of the data
//	// get the current experimental q, I, and std dev. waves (as they would be loaded )
//
//	//ControlInfo/W=FitPanel ywave
//	//get the filename from the global as it's loaded, rather from the popup - as version numbers
//	// do cause problems here. This global is also used later in this function
//	SVAR gLastFileName = root:Packages:NIST:gLastFileName
//	String tempStr = CleanupName(gLastFileName,0)
//	String tempName = "root:"+tempStr+":"+tempStr
//	
//	Wave xw = $(tempName+"_q")
//	Wave yw = $(tempName+"_i")
//	Wave ew = $(tempName+"_s")
//	
//	//variables set for each model to control look of graph
//	Variable xlow,xhigh,ylow,yhigh,yes_cursors
//	String xlabel,ylabel,xstr,ystr
//	//check for proper y-scaling selection, make the necessary waves
//	ControlInfo/W=FitPanel yModel
//	ystr = S_Value
////	print "ystr = ",ystr
//	do
//		// make the new yaxis waves, including weighting wave
//		Duplicate/O yw yAxisWave,yErrWave,yWtWave,residWave
//		//subtract the background value from yAxisWave before doing any rescaling
//		yAxisWave = yw - bkg
//		
//		If (cmpstr("I",S_Value) == 0)
//			SetScale d 0,0,"1/cm",yAxisWave
//			yErrWave = ew
//			yWtWave = 1/yErrWave
//			yAxisWave = yAxisWave
//			ylabel = "I(q)"
//			break	
//		endif
//		If (cmpstr("ln(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yAxisWave
//			yWtWave = 1/yErrWave
//			yAxisWave = ln(yAxisWave)
//			ylabel = "ln(I)"
//			break	
//		endif
//		If (cmpstr("log(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/(2.30*yAxisWave)
//			yWtWave = 1/yErrWave
//			yAxisWave = log(yAxisWave)
//			ylabel = "log(I)"
//			break	
//		endif
//		If (cmpstr("1/I",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yAxisWave^2
//			yWtWave = 1/yErrWave
//			yAxisWave = 1/yAxisWave
//			ylabel = "1/I"
//			break
//		endif
//		If (cmpstr("I^a",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*abs(pow_a*(yAxisWave^(pow_a-1)))
//			yWtWave = 1/yErrWave
//			yAxisWave = yAxisWave^pow_a
//			ylabel = "I^"+num2str(pow_a)
//			break
//		endif
//		If (cmpstr("Iq^a",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*xw^pow_a
//			yWtWave = 1/yErrWave
//			yAxisWave = yAxisWave*xw^pow_a
//			ylabel = "I*q^"+num2str(pow_a)
//			break
//		endif
//		If (cmpstr("I^a q^b",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew*abs(pow_a*(yAxisWave^(pow_a-1)))*xw^pow_b
//			yWtWave = 1/yErrWave
//			yAxisWave = yAxisWave^pow_a*xw^pow_b
//			ylabel = "I^" + num2str(pow_a) + "q^"+num2str(pow_b)
//			break
//		endif
//		If (cmpstr("1/sqrt(I)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = 0.5*ew*yAxisWave^(-1.5)
//			yWtWave = 1/yErrWave
//			yAxisWave = 1/sqrt(yAxisWave)
//			ylabel = "1/sqrt(I)"
//			break
//		endif
//		If (cmpstr("ln(Iq)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave =ew/yAxisWave
//			yWtWave = 1/yErrWave
//			yAxisWave = ln(xw*yAxisWave)
//			ylabel = "ln(q*I)"
//			break
//		endif
//		If (cmpstr("ln(Iq^2)",S_Value) == 0)
//			SetScale d 0,0,"",yAxisWave
//			yErrWave = ew/yAxisWave
//			yWtWave = 1/yErrWave
//			yAxisWave = ln(xw*xw*yAxisWave)
//			ylabel = "ln(I*q^2)"
//			break
//		endif
//		//more ifs for each case
//		
//		// if selection not found, abort
//		DoAlert 0,"Y-axis scaling incorrect. Aborting"
//		Abort
//	while(0)	//end of "case" statement for y-axis scaling
//	
//	
//	//check for proper x-scaling selection
//	Variable low,high
//	
//	ControlInfo/W=FitPanel lolim
//	low = V_value
//	ControlInfo/W=FitPanel uplim
//	high = V_value
//	if ((high<low) || (high==low))
//		DoAlert 0,"Unphysical fitting limits - re-enter better values"
//		Abort
//	endif
//	
//	SVAR aStr = root:myGlobals:gAngstStr
//	
//	ControlInfo/W=FitPanel xModel
//	xstr = S_Value
//	do
//		// make the new yaxis wave
//		Duplicate/o xw xAxisWave
//		If (cmpstr("q",S_Value) == 0)	
//			SetScale d 0,0,aStr+"^-1",xAxisWave
//			xAxisWave = xw
//			xlabel = "q"
//			xlow = low
//			xhigh = high
//			break	
//		endif
//		If (cmpstr("q^2",S_Value) == 0)	
//			SetScale d 0,0,aStr+"^-2",xAxisWave
//			xAxisWave = xw*xw
//			xlabel = "q^2"
//			xlow = low^2
//			xhigh = high^2
//			break	
//		endif
//		If (cmpstr("log(q)",S_Value) == 0)	
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = log(xw)
//			xlabel = "log(q)"
//			xlow = log(low)
//			xhigh = log(high)
//			break	
//		endif
//		If (cmpstr("q^c",S_Value) == 0)
//			SetScale d 0,0,"",xAxisWave
//			xAxisWave = xw^pow_c
//			xlabel = "q^"+num2str(pow_c)
//			xlow = low^pow_c
//			xhigh = high^pow_c
//			break
//		endif
//	
//		//more ifs for each case
//		
//		// if selection not found, abort
//		DoAlert 0,"X-axis scaling incorrect. Aborting"
//		Abort
//	while(0)	//end of "case" statement for x-axis scaling
//
//	//plot the data
//	
//	String cleanLastFileName = "root:"+CleanupName(gLastFileName,0)
//	If(WinType("FitWindow") == 0)
//		Display /W=(5,42,480,400)/K=1 yAxisWave vs xAxisWave
//		ModifyGraph mode=3,standoff=0,marker=8
//		ErrorBars/T=0 yAxisWave Y,wave=(yErrWave,yErrWave)
//		ModifyGraph opaque(yAxisWave)=1
//		DoWindow/C FitWindow
//	else
//		//window already exists, just bring to front for update
//		DoWindow/F FitWindow
//		// remove old text boxes
//		TextBox/K/N=text_1
//		TextBox/K/N=text_2
//		TextBox/K/N=text_3
//	endif
//	SetAxis/A
//	ModifyGraph tickUnit=1		//suppress tick units in labels
//	TextBox/C/N=textLabel/A=RB "File = "+cleanLastFileName
//	//clear the old fit from the window, if it exists
//	RemoveFromGraph/W=FitWindow/Z fit_yAxisWave
//	
//	// add the cursors if desired...	
//	//see if the user wants to use the data specified by the cursors - else use numerical values
//	
//	ControlInfo/W=FitPanel check0		//V_value = 1 if it is checked, meaning yes, use cursors
//	yes_cursors = V_value
//
//	DoWindow/F FitWindow
//	ShowInfo
//	if(yes_cursors)
//		xlow = xAxisWave[xcsr(A)]
//		xhigh = xAxisWave[xcsr(B)]
//		if(xlow > xhigh)
//			xhigh = xlow
//			xlow = xAxisWave[xcsr(B)]
//		endif
////		Print xlow,xhigh
//	else
//		FindLevel/P/Q xAxisWave, xlow
//		if(V_flag == 1)			//level NOT found
//			DoAlert 0,"Lower q-limit not in experimental q-range. Re-enter a better value"
//			//DoWindow/K FitWindow
//			//Abort
//		endif
//		Cursor/P A, yAxisWave,trunc(V_LevelX)+1
//		ylow = V_LevelX
//		FindLevel/P/Q xAxisWave, xhigh
//		if(V_flag == 1)
//			DoAlert 0,"Upper q-limit not in experimental q-range. Re-enter a better value"
//			//DoWindow/K FitWindow
//			//Abort
//		endif
//		Cursor/P B, yAxisWave,trunc(V_LevelX)
//		yhigh = V_LevelX
//	endif	//if(V_value)
//	//SetAxis bottom,xlow,xhigh
//	//SetAxis left,ylow,yhigh
//	Label left ylabel
//	Label bottom xlabel	//E denotes "scaling"  - may want to use "units" instead	
//
//End
//
//
////button procedure that is activated to "DotheFit"
////the panel is parsed for proper fitting limits
//// the appropriate linearization is formed (in the Rescale_Data() function)
//// and the fit is done,
////and the results are plotted
//// function works in root level data folder (where the loaded 1-d data will be)
//Function DispatchModel(GoFit) : ButtonControl
//	String GoFit
//
//	//check for the FitWindow - to make sure that there is data to fit
//	If(WinType("FitWindow") == 0)		//if the window doesn't exist
//		Abort "You must Load and Plot a File before fitting the data"
//	endif
//	// rescale the data, to make sure it's as selected on the panel
//	Rescale_Data()
//	
//	// now go do the fit
//	
//// get the current low and high q values for fitting
//	Variable low,high
//	
//	ControlInfo/W=FitPanel lolim
//	low = V_value
//	ControlInfo/W=FitPanel uplim
//	high = V_value
//	if ((high<low) || (high==low))
//		DoAlert 0,"Unphysical fitting limits - re-enter better values"
//		Abort
//	endif
//
//	//try including residuals on the graph /R=residWave, explicitly place on new axis
//	//if only /R used, residuals are automatically placed on graph
//	
//	CurveFit line yAxisWave(xcsr(A),xcsr(B)) /X=xAxisWave /W=yWtWave /D  
//	//CurveFit line yAxisWave(xcsr(A),xcsr(B)) /X=xAxisWave /W=yWtWave  /R /D  
//	ModifyGraph rgb(fit_yAxisWave)=(0,0,0)
//	ModifyGraph lsize(fit_yAxisWave)=2
//// annotate graph, filtering out special cases of Guinier fits
//// Text Boxes must be used, since ControlBars on graphs DON'T print out
//	
//	// need access to Global wave, result of fit
//	//ystr and xstr are the axis strings - filter with a do-loop
//	String ystr="",xstr=""
//	SVAR gLastFileName = root:Packages:NIST:gLastFileName
//	SVAR aStr = root:myGlobals:gAngstStr
//	String tmpStr = CleanupName(gLastFileName,0)
//	//ControlInfo/W=FitPanel ywave
//	Wave xw = $("root:"+tmpStr+":"+tmpStr+"_q")
//	ControlInfo/W=FitPanel yModel
//	ystr = S_Value
//	ControlInfo/W=FitPanel xModel
//	xstr = S_Value
//	
//	WAVE W_coef=W_coef
//	WAVE W_sigma=W_sigma
//	String textstr_1,textstr_2,textstr_3 = ""
//	Variable rg,rgerr,minfit,maxfit
//	
//	textstr_1 = "Slope = " + num2str(W_coef[1]) + " ± " + num2str(W_sigma[1])
//	textstr_1 += "\rIntercept = " + num2str(W_coef[0]) + " ± " + num2str(W_sigma[0])
//	textstr_1 += "\rChi-Squared =  " + num2str(V_chisq/(V_npnts - 3))
//	
//	minfit = xw[xcsr(A)]
//	maxfit = xw[xcsr(B)]
//	textstr_2 = "Qmin =  " + num2str(minfit)
//	textstr_2 += "\rQmax =  " + num2str(maxfit)
//	
//	//model-specific calculations - I(0), Rg, etc.
//	//put these in textstr_3, at bottom
//	do
//		If (cmpstr("I",ystr) == 0)
//			textstr_3 = "I(q=0) =  "  + num2str(W_coef[0])
//			break	
//		endif
//		If (cmpstr("ln(I)",ystr) == 0)
//			textstr_3 = "I(q=0) =  "  + num2str(exp(W_coef[0]))
//			if(cmpstr("q^2",xstr) == 0)	//then a Guinier plot for a sphere (3-d)
//				rg = sqrt(-3*W_coef[1])
//				rgerr = 3*W_sigma[1]/(2*rg)
//				textstr_3 += "\rRg ("+aStr+") = " + num2str(rg) + " ± " + num2str(rgerr)
//				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
//				break
//			endif
//			break	
//		endif
//		If (cmpstr("log(I)",ystr) == 0)
//			if(cmpstr("log(q)",xstr) !=0 )	//extrapolation is nonsense 
//				textstr_3 = "I(q=0) =  "  + num2str(10^(W_coef[0]))
//			endif
//			break	
//		endif
//		If (cmpstr("1/I",ystr) == 0)
//			textstr_3 = "I(q=0) =  "  + num2str(1/W_coef[0])+ " ± " + num2str(1/(W_coef[0] - W_sigma[0])-1/W_coef[0])
//			break
//		endif
//		If (cmpstr("I^a",ystr) == 0)
//			//nothing
//			break
//		endif
//		If (cmpstr("Iq^a",ystr) == 0)
//			//nothing
//			break
//		endif
//		If (cmpstr("I^a q^b",ystr) == 0)
//			//nothing
//			break
//		endif
//		If (cmpstr("1/sqrt(I)",ystr) == 0)
//			textstr_3 = "I(q=0) =  "  + num2str((W_coef[0])^2)
//			break
//		endif
//		If (cmpstr("ln(Iq)",ystr) == 0)
//			//nothing
//			if(cmpstr("q^2",xstr) == 0)	//then a x-sect Guinier plot for a rod (2-d)
//				// rg now is NOT the radius of gyration, but the x-sect DIAMETER
//				rg = 4*sqrt(-W_coef[1])
//				rgerr = 8*W_sigma[1]/rg
//				textstr_3 = "Rod diameter ("+aStr+") = " + num2str(rg) + " ± " + num2str(rgerr)
//				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
//				break
//			endif
//			break
//		endif
//		If (cmpstr("ln(Iq^2)",ystr) == 0)
//			//nothing
//			if(cmpstr("q^2",xstr) == 0)	//then a 1-d Guinier plot for a sheet
//				// rg now is NOT the radius of gyration, but the thickness
//				rg = sqrt(-12*W_coef[1])
//				rgerr = 6*W_sigma[1]/(2*rg)
//				textstr_3 = "Platelet thickness ("+aStr+") = " + num2str(rg) + " ± " + num2str(rgerr)
//				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
//				break
//			endif
//			break
//		endif
//		
//	while(0)
//	//kill the old textboxes, if they exist
//	TextBox/W=FitWindow/K/N=text_1
//	TextBox/W=FitWindow/K/N=text_2
//	TextBox/W=FitWindow/K/N=text_3
//	// write the new text boxes
//	TextBox/W=FitWindow/N=text_1/A=LT textstr_1
//	TextBox/W=FitWindow/N=text_2/A=LC textstr_2
//	If (cmpstr("",textstr_3) != 0)		//only display textstr_3 if it isn't null
//		TextBox/W=FitWindow/N=text_3/A=LB textstr_3
//	endif
//	
//	//adjust the plot range to reflect the actual fitted range
//	//cursors are already on the graph, done by Rescale_Data()
//	AdjustAxisToCursors()
//	
//End
//
//// adjusts both the x-axis scaling  and y-axis scaling to the cursor range
//// **cursors are already on the graph, done by Rescale_Data()
////
//// will expand the scale to show an extra 5 points in each direction (if available)
//Function AdjustAxisToCursors()
//
//	DoWindow/F FitWindow
//	WAVE xAxisWave = root:xAxisWave
//	WAVE yAxisWave = root:yAxisWave
//	Variable xlow,xhigh,ylow,yhigh,yptlow,ypthigh
//	Variable extraPts = 5, num=numpnts(xAxisWave)
//	
//	String csrA = CsrInfo(A ,"FitWindow")
//	String csrB = CsrInfo(B ,"FitWindow")
//	
//	//x-levels, these are monotonic
//	Variable ptLow,ptHigh,tmp
//	ptLow = NumberByKey("POINT", csrA ,":" ,";")
//	ptHigh = NumberByKey("POINT", csrB ,":" ,";")
//	if(ptLow > ptHigh)
//		tmp= ptLow
//		ptLow=ptHigh
//		ptHigh=tmp
//	endif
//
//	// keep extended point range in bounds
//	ptLow = (ptLow-extraPts) >= 0 ? ptLow-extraPts : 0
//	ptHigh = (ptHigh+extraPts) <= (num-1) ? ptHigh + extraPts : num-1
//	
//	xlow = xAxisWave[ptLow]
//	xhigh = xAxisWave[ptHigh]
////old way
////	xlow = xAxisWave[xcsr(A)]
////	xhigh = xAxisWave[xcsr(B)]
////	if(xlow > xhigh)
////		xhigh = xlow
////		xlow = xAxisWave[xcsr(B)]
////	endif
//	
//	//y-levels (old way)
////	FindLevel/P/Q xAxisWave, xlow
////	if(V_flag == 1)			//level NOT found
////		DoAlert 0,"Lower q-limit not in experimental q-range. Re-enter a better value"
////	endif
////	yptlow = V_LevelX
////	FindLevel/P/Q xAxisWave, xhigh
////	if(V_flag == 1)
////		DoAlert 0,"Upper q-limit not in experimental q-range. Re-enter a better value"
////	endif
////	ypthigh = V_LevelX
//
////	Print xlow,xhigh,yptlow,ypthigh
////	Print yAxisWave[yptlow],yAxisWave[ypthigh]
//	
//
//	// make sure ylow/high are in the correct order, since the slope could be + or -
//	yhigh = max(yAxisWave[ptlow],yAxisWave[pthigh])
//	ylow = min(yAxisWave[ptlow],yAxisWave[pthigh])
//	
////	Print ptLow,ptHigh
////	print xlow,xhigh
////	print ylow,yhigh
//	
//	SetAxis bottom,xlow,xhigh
//	SetAxis left ylow,yhigh
//	
//End


