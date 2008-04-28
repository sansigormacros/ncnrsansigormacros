#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.2
#pragma IgorVersion=4.0

///////////////////////////////
//procedures for creating and initializing the Linearized FIT panel
//global variables (numerical only) are kept in root:myGlobals:FIT folder
//
// this is based on the FIT routines in the SANS Reduction package, and has been modified here
// only to make it independent of the Reduction routines, and into "Package" format
//
// These procedures WILL conflict in namespace with the SANS Reduction routines
// in both Fit_Ops and VAX_Utils (and probably others...) so DO NOT
// try to include these...
//
// SRK 11 JAN 05
//
// Prepended "A_" to all of the procs and functions to avoid name conflicts
// with the FIT included in the reduction package
// - DID NOT prepend "A_" to the loader/unloader which is unique to this package
//
//
///////////////////////////////

//main procedures to open the panel, initializing the data folder and global variables
//as necessary. All are kept in a :FIT subfolder to avoid overlap with other variables
//
// To use any of the fit functions in the FIT panel, I(Q) data must already
// be loaded into memory (using "plot" from the 1-D data operations
// ** this may be useful to change in the future, replacing the 3 popups
// with a list box - allowing the user to pick/load the data from the fit panel
// and not offering any choice of q/i/s waves to use. (more consistent with the operation
// of the FIT/RPA panel)
//
Proc A_OpenFitPanel()
	If(WinType("A_FitPanel") == 0)
		//create the necessary data folder
		NewDataFolder/O root:myGlobals
		NewDataFolder/O root:myGlobals:FIT
		//initialize the values
		Variable/G root:myGlobals:FIT:gLolim = 0.02
		Variable/G root:myGlobals:FIT:gUplim = 0.04
		Variable/G root:myGlobals:FIT:gExpA = 1
		Variable/G root:myGlobals:FIT:gExpB = 1
		Variable/G root:myGlobals:FIT:gExpC = 1
		Variable/G root:myGlobals:FIT:gBack = 0
		String/G root:myGlobals:FIT:gDataPopList = "none"
		A_FitPanel()
	else
		//window already exists, just bring to front for update
		DoWindow/F A_FitPanel
		CheckBox check0,value=0		//deselect the checkbox to use cursors
	endif
	//pop the file menu
	A_FIT_FilePopMenuProc("",1,"")
End

//the actual window recreation macro to draw the fit panel. Globals and data folder must 
// already be initialized
Window A_FitPanel()
	//String angst = root:myGlobals:gAngstStr
	String angst = "A"
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(461,46,735,455)/K=1
	ModifyPanel cbRGB=(32768,54615,65535), fixedSize=1
	SetDrawLayer UserBack
	DrawText 56,20,"Select Experimental Data"
	DrawText 66,138,"q-range to fit ("+angst+"^-1)"
	DrawText 42,268,"Select the y and x-axis scaling"
	DrawLine 1,21,271,21
	DrawLine -1,272,273,272
	DrawLine -1,140,272,140
	PopupMenu ywave,pos={13,60},size={154,19},title="Data File"
	PopupMenu ywave,help={"Select the experimental intensity values"}
	PopupMenu ywave,mode=1,value=root:myGlobals:FIT:gDataPopList,proc=A_FIT_FilePopMenuProc
	Button loadButton,pos={13,92},size={130,20},proc=A_FIT_Load_Proc,title="Load and Plot File"
	Button loadButton,help={"After choosing a file, load it into memory and plot it with this button."}
	Button helpButton,pos={237,28},size={25,20},proc=A_showFITHelp,title="?"
	Button helpButton,help={"Show help file for linearized fitting"}
	PopupMenu ymodel,pos={20,281},size={76,19},title="y-axis"
	PopupMenu ymodel,help={"This popup selects how the y-axis will be linearized based on the chosen data"}
	PopupMenu ymodel,mode=1,value= #"\"I;log(I);ln(I);1/I;I^a;Iq^a;I^a q^b;1/sqrt(I);ln(Iq);ln(Iq^2)\""
	Button GoFit,pos={60,367},size={70,20},proc=A_DispatchModel,title="Do the Fit"
	Button GoFit,help={"This button will do the specified fit using the selections in this panel"}
	Button DoneButton,pos={180,367},size={50,20},proc=A_FITDoneButton,title="Done"
	Button DoneButton,help={"This button will close the panel and the associated graph"}
	SetVariable lolim,pos={64,147},size={134,17},title="Lower Limit"
	SetVariable lolim,help={"Enter the lower q-limit to perform the fit ("+angst+"^-1)"}
	SetVariable lolim,limits={0,5,0},value= root:myGlobals:FIT:gLolim
	SetVariable uplim,pos={63,169},size={134,17},title="Upper Limit"
	SetVariable uplim,help={"Enter the upper q-limit to perform the fit ("+angst+"^-1)"}
	SetVariable uplim,limits={0,5,0},value= root:myGlobals:FIT:gUplim
	SetVariable expa,pos={13,311},size={80,17},title="pow \"a\""
	SetVariable expa,help={"This sets the exponent \"a\" for some y-axis formats. The value is ignored if the model does not use an adjustable exponent"}
	SetVariable expa,limits={-2,10,0},value= root:myGlobals:FIT:gExpA
	SetVariable expb,pos={98,311},size={80,17},title="pow \"b\""
	SetVariable expb,help={"This sets the exponent \"b\" for some x-axis formats. The value is ignored if the model does not use an adjustable exponent"}
	SetVariable expb,limits={0,10,0},value= root:myGlobals:FIT:gExpB
	PopupMenu xmodel,pos={155,280},size={79,19},title="x-axis"
	PopupMenu xmodel,help={"This popup selects how the x-axis will be linearized given the chosen data"}
	PopupMenu xmodel,mode=1,value= #"\"q;log(q);q^2;q^c\""
	CheckBox check0,pos={18,223},size={240,20},title="Use cursor range from FitWindow"
	CheckBox check0,help={"Checking this will perform a fit between the cursors on the graph in FitWindow and ignore the numerical limits typed above"},value=0
	SetVariable back,pos={70,338},size={139,17},title="background"
	SetVariable back,help={"This constant background value will be subtracted from the experimental intensity before fitting is done"}
	SetVariable back,limits={-Inf,Inf,0},value= root:myGlobals:FIT:gBack
	SetVariable expc,pos={182,310},size={80,17},title="pow \"c\""
	SetVariable expc,help={"This sets the exponent \"c\" for some x-axis formats. The value is ignored if the model does not use \"c\" as an adjustable exponent"}
	SetVariable expc,limits={-10,10,0},value= root:myGlobals:FIT:gExpC
	Button sh_all,pos={65,193},size={130,20},proc=A_ShowAllButtonProc,title="Show Full q-range"
	Button sh_all,help={"Use this to show the entire q-range of the data rather than just the fitted range."}
	
	Button FIT_PathButton,pos={10,28},size={80,20},proc=A_FIT_PickPathButtonProc,title="Pick Path"

EndMacro


Proc A_FITDoneButton(ctrlName): ButtonControl
	String ctrlName
	DoWindow/K A_FitWindow
	DoWindow/K A_FitPanel
end

Proc A_showFITHelp(ctrlName): ButtonControl
	String ctrlName
	DisplayHelpTopic "Linearized Fits"
end

//Loads the selected file for fitting
//graphs the data as needed
Proc A_FIT_Load_Proc(ctrlName): ButtonControl
	String ctrlName
	
	//Load the data
	String tempName="",partialName=""
	Variable err
	ControlInfo $"ywave"
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
	A_LoadOneDDataWithName(tempName)
	//Print S_fileName
	//Print tempName
	
	String cleanLastFileName = "root:"+CleanupName(root:myGlobals:gLastFileName,0)

	tempName=cleanLastFileName+"_q"
	Duplicate/O $tempName xAxisWave
	tempName=cleanLastFileName+"_i"
	Duplicate/O $tempName yAxisWave
	tempName=cleanLastFileName+"_s"
	Duplicate/O $tempName yErrWave

	//Plot, and adjust the scaling to match the axis scaling set by the popups
	A_Rescale_Data()
	
End

//gets a valid file list (simply not the files with ".SAn" in the name)
//
Function A_FIT_FilePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String tempStr=A_filterButtonProc(ctrlName)
	if(strlen(tempStr)==0)
		tempStr = "Pick the data path"
	Endif
	String/G root:myGlobals:FIT:gDataPopList =tempStr
	ControlUpdate ywave
	
End

//direct porting of the fit program from the VAX, with no corrections and only
//minor modifications of additional  linearizations and the option
//to subtract a constant (q-independent) background value before doing any
//of the fits. The original data on disk (and as loaded) is never modified, all
//manipulation is done from a copy of the data.

//button procedure to show the entire axis range of the data, rather than just
//the fitted range, which is the default display after a fit is performed
//
Function A_ShowAllButtonProc(ctrlName) : ButtonControl
	String ctrlName

	//bring the FitWindow to the front and Autoscale the axes
	DoWindow/F A_FitWindow
	SetAxis/A
End

// function that takes the current dataset (already loaded)
// and replots it based on the X/Y axis scaling selected in the popups
// (does not fit the data)
//
Function A_Rescale_Data()
	
	//Scaling exponents and background value
	Variable pow_a,pow_b,pow_c,bkg
	ControlInfo/W=A_FitPanel expa
	pow_a = V_value
	ControlInfo/W=A_FitPanel expb
	pow_b = V_value
	ControlInfo/W=A_FitPanel expc
	pow_c = V_value
	ControlInfo/W=A_FitPanel back
	bkg = V_value
	
//check for physical limits on exponent values
// if bad values found, alert, and reset to good values so the rescaling can continue
	NVAR gA = root:myGlobals:FIT:gExpA
	NVAR gB = root:myGlobals:FIT:gExpB
	NVAR gC = root:myGlobals:FIT:gExpC
	if((pow_a < -2) || (pow_a > 10))
		DoAlert 0,"Exponent a must be in the range (-2,10) - the exponent a has been reset to 1"
		gA = 1
	endif
	if((pow_b < 0) || (pow_b > 10))
		DoAlert 0,"Exponent b must be in the range (0,10) - the exponent b has been reset to 1"
		gB = 1
	endif
	//if q^c is the x-scaling, c must be be within limits and also non-zero
	ControlInfo/W=A_FitPanel xModel
	If (cmpstr("q^c",S_Value) == 0)
		if(pow_c == 0) 
			DoAlert 0,"Exponent c must be non-zero, c has been reset to 1"
			gC = 1
		endif
		if((pow_c < -10) || (pow_c > 10))
			DoAlert 0,"Exponent c must be in the range (-10,10), c has been reset to 1"
			gC = 1
		endif
	endif
	
	//do the rescaling of the data
	// get the current experimental q, I, and std dev. waves (as they would be loaded )

	//ControlInfo/W=A_FitPanel ywave
	//get the filename from the global as it's loaded, rather from the popup - as version numbers
	// do cause problems here. This global is also used later in this function
	SVAR gLastFileName = root:myGlobals:gLastFileName
	
	Wave xw = $( CleanupName((gLastFileName + "_q"),0) )
	Wave yw = $( CleanupName((gLastFileName + "_i"),0) )
	Wave ew = $( CleanupName((gLastFileName + "_s"),0) )
	
	//variables set for each model to control look of graph
	Variable xlow,xhigh,ylow,yhigh,yes_cursors
	String xlabel,ylabel,xstr,ystr
	//check for proper y-scaling selection, make the necessary waves
	ControlInfo/W=A_FitPanel yModel
	ystr = S_Value
//	print "ystr = ",ystr
	do
		// make the new yaxis waves, including weighting wave
		Duplicate/O yw yAxisWave,yErrWave,yWtWave,residWave
		//subtract the background value from yAxisWave before doing any rescaling
		yAxisWave = yw - bkg
		
		If (cmpstr("I",S_Value) == 0)
			SetScale d 0,0,"1/cm",yAxisWave
			yErrWave = ew
			yWtWave = 1/yErrWave
			yAxisWave = yAxisWave
			ylabel = "I(q)"
			break	
		endif
		If (cmpstr("ln(I)",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew/yAxisWave
			yWtWave = 1/yErrWave
			yAxisWave = ln(yAxisWave)
			ylabel = "ln(I)"
			break	
		endif
		If (cmpstr("log(I)",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew/(2.30*yAxisWave)
			yWtWave = 1/yErrWave
			yAxisWave = log(yAxisWave)
			ylabel = "log(I)"
			break	
		endif
		If (cmpstr("1/I",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew/yAxisWave^2
			yWtWave = 1/yErrWave
			yAxisWave = 1/yAxisWave
			ylabel = "1/I"
			break
		endif
		If (cmpstr("I^a",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew*abs(pow_a*(yAxisWave^(pow_a-1)))
			yWtWave = 1/yErrWave
			yAxisWave = yAxisWave^pow_a
			ylabel = "I^"+num2str(pow_a)
			break
		endif
		If (cmpstr("Iq^a",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew*xw^pow_a
			yWtWave = 1/yErrWave
			yAxisWave = yAxisWave*xw^pow_a
			ylabel = "I*q^"+num2str(pow_a)
			break
		endif
		If (cmpstr("I^a q^b",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew*abs(pow_a*(yAxisWave^(pow_a-1)))*xw^pow_b
			yWtWave = 1/yErrWave
			yAxisWave = yAxisWave^pow_a*xw^pow_b
			ylabel = "I^" + num2str(pow_a) + "q^"+num2str(pow_b)
			break
		endif
		If (cmpstr("1/sqrt(I)",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = 0.5*ew*yAxisWave^(-1.5)
			yWtWave = 1/yErrWave
			yAxisWave = 1/sqrt(yAxisWave)
			ylabel = "1/sqrt(I)"
			break
		endif
		If (cmpstr("ln(Iq)",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave =ew/yAxisWave
			yWtWave = 1/yErrWave
			yAxisWave = ln(xw*yAxisWave)
			ylabel = "ln(q*I)"
			break
		endif
		If (cmpstr("ln(Iq^2)",S_Value) == 0)
			SetScale d 0,0,"",yAxisWave
			yErrWave = ew/yAxisWave
			yWtWave = 1/yErrWave
			yAxisWave = ln(xw*xw*yAxisWave)
			ylabel = "ln(I*q^2)"
			break
		endif
		//more ifs for each case
		
		// if selection not found, abort
		DoAlert 0,"Y-axis scaling incorrect. Aborting"
		Abort
	while(0)	//end of "case" statement for y-axis scaling
	
	
	//check for proper x-scaling selection
	Variable low,high
	
	ControlInfo/W=A_FitPanel lolim
	low = V_value
	ControlInfo/W=A_FitPanel uplim
	high = V_value
	if ((high<low) || (high==low))
		DoAlert 0,"Unphysical fitting limits - re-enter better values"
		Abort
	endif
	
	ControlInfo/W=A_FitPanel xModel
	xstr = S_Value
	do
		// make the new yaxis wave
		Duplicate/o xw xAxisWave
		If (cmpstr("q",S_Value) == 0)	
			SetScale d 0,0,"^-1",xAxisWave
			xAxisWave = xw
			xlabel = "q"
			xlow = low
			xhigh = high
			break	
		endif
		If (cmpstr("q^2",S_Value) == 0)	
			SetScale d 0,0,"^-2",xAxisWave
			xAxisWave = xw*xw
			xlabel = "q^2"
			xlow = low^2
			xhigh = high^2
			break	
		endif
		If (cmpstr("log(q)",S_Value) == 0)	
			SetScale d 0,0,"",xAxisWave
			xAxisWave = log(xw)
			xlabel = "log(q)"
			xlow = log(low)
			xhigh = log(high)
			break	
		endif
		If (cmpstr("q^c",S_Value) == 0)
			SetScale d 0,0,"",xAxisWave
			xAxisWave = xw^pow_c
			xlabel = "q^"+num2str(pow_c)
			xlow = low^pow_c
			xhigh = high^pow_c
			break
		endif
	
		//more ifs for each case
		
		// if selection not found, abort
		DoAlert 0,"X-axis scaling incorrect. Aborting"
		Abort
	while(0)	//end of "case" statement for x-axis scaling

	//plot the data
	
	String cleanLastFileName = "root:"+CleanupName(gLastFileName,0)
	If(WinType("A_FitWindow") == 0)
		Display /W=(5,42,480,400)/K=1 yAxisWave vs xAxisWave
		ModifyGraph mode=3,standoff=0,marker=8
		ErrorBars yAxisWave Y,wave=(yErrWave,yErrWave)
		DoWindow/C A_FitWindow
	else
		//window already exists, just bring to front for update
		DoWindow/F A_FitWindow
		// remove old text boxes
		TextBox/K/N=text_1
		TextBox/K/N=text_2
		TextBox/K/N=text_3
	endif
	SetAxis/A
	ModifyGraph tickUnit=1		//suppress tick units in labels
	TextBox/C/N=textLabel/A=RB "File = "+cleanLastFileName
	//clear the old fit from the window, if it exists
	RemoveFromGraph/W=A_FitWindow/Z fit_yAxisWave
	
	// add the cursors if desired...	
	//see if the user wants to use the data specified by the cursors - else use numerical values
	
	ControlInfo/W=A_FitPanel check0		//V_value = 1 if it is checked, meaning yes, use cursors
	yes_cursors = V_value

	DoWindow/F A_FitWindow
	ShowInfo
	if(yes_cursors)
		xlow = xAxisWave[xcsr(A)]
		xhigh = xAxisWave[xcsr(B)]
		if(xlow > xhigh)
			xhigh = xlow
			xlow = xAxisWave[xcsr(B)]
		endif
//		Print xlow,xhigh
	else
		FindLevel/P/Q xAxisWave, xlow
		if(V_flag == 1)			//level NOT found
			DoAlert 0,"Lower q-limit not in experimental q-range. Re-enter a better value"
			//DoWindow/K A_FitWindow
			//Abort
		endif
		Cursor/P A, yAxisWave,trunc(V_LevelX)+1
		ylow = V_LevelX
		FindLevel/P/Q xAxisWave, xhigh
		if(V_flag == 1)
			DoAlert 0,"Upper q-limit not in experimental q-range. Re-enter a better value"
			//DoWindow/K A_FitWindow
			//Abort
		endif
		Cursor/P B, yAxisWave,trunc(V_LevelX)
		yhigh = V_LevelX
	endif	//if(V_value)
	//SetAxis bottom,xlow,xhigh
	//SetAxis left,ylow,yhigh
	Label left ylabel
	Label bottom xlabel	//E denotes "scaling"  - may want to use "units" instead	

End


//button procedure that is activated to "DotheFit"
//the panel is parsed for proper fitting limits
// the appropriate linearization is formed (in the Rescale_Data() function)
// and the fit is done,
//and the results are plotted
// function works in root level data folder (where the loaded 1-d data will be)
Function A_DispatchModel(GoFit) : ButtonControl
	String GoFit

	//check for the FitWindow - to make sure that there is data to fit
	If(WinType("A_FitWindow") == 0)		//if the window doesn't exist
		Abort "You must Load and Plot a File before fitting the data"
	endif
	// rescale the data, to make sure it's as selected on the panel
	A_Rescale_Data()
	
	// now go do the fit
	
// get the current low and high q values for fitting
	Variable low,high
	
	ControlInfo/W=A_FitPanel lolim
	low = V_value
	ControlInfo/W=A_FitPanel uplim
	high = V_value
	if ((high<low) || (high==low))
		DoAlert 0,"Unphysical fitting limits - re-enter better values"
		Abort
	endif

	//try including residuals on the graph /R=residWave, explicitly place on new axis
	//if only /R used, residuals are automatically placed on graph
	
	CurveFit line yAxisWave(xcsr(A),xcsr(B)) /X=xAxisWave /W=yWtWave /D  
	//CurveFit line yAxisWave(xcsr(A),xcsr(B)) /X=xAxisWave /W=yWtWave  /R /D  
	ModifyGraph rgb(fit_yAxisWave)=(0,0,0)
// annotate graph, filtering out special cases of Guinier fits
// Text Boxes must be used, since ControlBars on graphs DON'T print out
	
	// need access to Global wave, result of fit
	//ystr and xstr are the axis strings - filter with a do-loop
	String ystr="",xstr=""
	SVAR gLastFileName = root:myGlobals:gLastFileName
	//ControlInfo/W=A_FitPanel ywave
	Wave xw = $( CleanupName((gLastFileName + "_q"),0) )
	ControlInfo/W=A_FitPanel yModel
	ystr = S_Value
	ControlInfo/W=A_FitPanel xModel
	xstr = S_Value
	
	WAVE W_coef=W_coef
	WAVE W_sigma=W_sigma
	String textstr_1,textstr_2,textstr_3 = ""
	Variable rg,rgerr,minfit,maxfit
	
	textstr_1 = "Slope = " + num2str(W_coef[1]) + " ± " + num2str(W_sigma[1])
	textstr_1 += "\rIntercept = " + num2str(W_coef[0]) + " ± " + num2str(W_sigma[0])
	textstr_1 += "\rChi-Squared =  " + num2str(V_chisq/(V_npnts - 3))
	
	minfit = xw[xcsr(A)]
	maxfit = xw[xcsr(B)]
	textstr_2 = "Qmin =  " + num2str(minfit)
	textstr_2 += "\rQmax =  " + num2str(maxfit)
	
	//model-specific calculations - I(0), Rg, etc.
	//put these in textstr_3, at bottom
	do
		If (cmpstr("I",ystr) == 0)
			textstr_3 = "I(q=0) =  "  + num2str(W_coef[0])
			break	
		endif
		If (cmpstr("ln(I)",ystr) == 0)
			textstr_3 = "I(q=0) =  "  + num2str(exp(W_coef[0]))
			if(cmpstr("q^2",xstr) == 0)	//then a Guinier plot for a sphere (3-d)
				rg = sqrt(-3*W_coef[1])
				rgerr = 3*W_sigma[1]/(2*rg)
				textstr_3 += "\rRg () = " + num2str(rg) + " ± " + num2str(rgerr)
				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
				break
			endif
			break	
		endif
		If (cmpstr("log(I)",ystr) == 0)
			if(cmpstr("log(q)",xstr) !=0 )	//extrapolation is nonsense 
				textstr_3 = "I(q=0) =  "  + num2str(10^(W_coef[0]))
			endif
			break	
		endif
		If (cmpstr("1/I",ystr) == 0)
			textstr_3 = "I(q=0) =  "  + num2str(1/W_coef[0])
			break
		endif
		If (cmpstr("I^a",ystr) == 0)
			//nothing
			break
		endif
		If (cmpstr("Iq^a",ystr) == 0)
			//nothing
			break
		endif
		If (cmpstr("I^a q^b",ystr) == 0)
			//nothing
			break
		endif
		If (cmpstr("1/sqrt(I)",ystr) == 0)
			textstr_3 = "I(q=0) =  "  + num2str((W_coef[0])^2)
			break
		endif
		If (cmpstr("ln(Iq)",ystr) == 0)
			//nothing
			if(cmpstr("q^2",xstr) == 0)	//then a x-sect Guinier plot for a rod (2-d)
				// rg now is NOT the radius of gyration, but the x-sect DIAMETER
				rg = 4*sqrt(-W_coef[1])
				rgerr = 8*W_sigma[1]/rg
				textstr_3 = "Rod diameter () = " + num2str(rg) + " ± " + num2str(rgerr)
				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
				break
			endif
			break
		endif
		If (cmpstr("ln(Iq^2)",ystr) == 0)
			//nothing
			if(cmpstr("q^2",xstr) == 0)	//then a 1-d Guinier plot for a sheet
				// rg now is NOT the radius of gyration, but the thickness
				rg = sqrt(-12*W_coef[1])
				rgerr = 6*W_sigma[1]/(2*rg)
				textstr_3 = "Platelet thickness () = " + num2str(rg) + " ± " + num2str(rgerr)
				textstr_3 += "\r" + num2str(rg*minfit) + " < Rg*q < " + num2str(rg*maxfit)
				break
			endif
			break
		endif
		
	while(0)
	//kill the old textboxes, if they exist
	TextBox/W=A_FitWindow/K/N=text_1
	TextBox/W=A_FitWindow/K/N=text_2
	TextBox/W=A_FitWindow/K/N=text_3
	// write the new text boxes
	TextBox/W=A_FitWindow/N=text_1/A=LT textstr_1
	TextBox/W=A_FitWindow/N=text_2/A=LC textstr_2
	If (cmpstr("",textstr_3) != 0)		//only display textstr_3 if it isn't null
		TextBox/W=A_FitWindow/N=text_3/A=LB textstr_3
	endif
	
	//adjust the plot range to reflect the actual fitted range
	//cursors are already on the graph, done by Rescale_Data()
	A_AdjustAxisToCursors()
	
End

// adjusts both the x-axis scaling  and y-axis scaling to the cursor range
// **cursors are already on the graph, done by Rescale_Data()
//
Function A_AdjustAxisToCursors()

	DoWindow/F A_FitWindow
	WAVE xAxisWave = root:xAxisWave
	WAVE yAxisWave = root:yAxisWave
	Variable xlow,xhigh,ylow,yhigh,yptlow,ypthigh
	
	//x-levels
	xlow = xAxisWave[xcsr(A)]
	xhigh = xAxisWave[xcsr(B)]
	if(xlow > xhigh)
		xhigh = xlow
		xlow = xAxisWave[xcsr(B)]
	endif
	
	//y-levels
	FindLevel/P/Q xAxisWave, xlow
	if(V_flag == 1)			//level NOT found
		DoAlert 0,"Lower q-limit not in experimental q-range. Re-enter a better value"
	endif
	yptlow = V_LevelX
	FindLevel/P/Q xAxisWave, xhigh
	if(V_flag == 1)
		DoAlert 0,"Upper q-limit not in experimental q-range. Re-enter a better value"
	endif
	ypthigh = V_LevelX

//	Print xlow,xhigh,yptlow,ypthigh
//	Print yAxisWave[yptlow],yAxisWave[ypthigh]
	
	SetAxis bottom,xlow,xhigh
	// make sure ylow/high are in the correct order
	Variable temp
	yhigh = max(yAxisWave[yptlow],yAxisWave[ypthigh])
	ylow = min(yAxisWave[yptlow],yAxisWave[ypthigh])
	SetAxis left ylow,yhigh
	
End

///// procedures added from other SANS Reduction files
//
//

//function called byt the popups to get a file list of data that can be sorted
// this procedure simply removes the raw data files from the string - there
//can be lots of other junk present, but this is very fast...
//
// could also use the alternate procedure of keeping only file with the proper extension
//
// another possibility is to get a listing of the text files, but is unreliable on 
// Windows, where the data file must be .txt (and possibly OSX)
//
Function/S A_filterButtonProc(ctrlName)
	String ctrlName

	String list="",newList="",item=""
	Variable num,ii
	
	//check for the path
	PathInfo catPathName
	if(V_Flag==0)
		DoAlert 0, "Data path does not exist - pick the data path from the button on the FIT panel"
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






//procedures to clean up after itself
Function UnloadLinFit()

	if (WinType("A_FitPanel") == 7)
		DoWindow/K A_FitPanel
	endif
	if (WinType("A_FitWindow") != 0)
		DoWindow/K $"A_FitWindow"
	endif
	Execute/P "DELETEINCLUDE \"LinearizedFits\""
	Execute/P "COMPILEPROCEDURES "
end

Menu "Macros"
	Submenu "Packages"
		"Unload Linear Fitting", UnloadLinFit()
	End
end

Function A_FIT_PickPathButtonProc(ctrlName) : ButtonControl
	String ctrlName

	A_PickPath()
	//pop the file menu
	A_FIT_FilePopMenuProc("",1,"")
End
