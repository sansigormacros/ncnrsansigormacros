#pragma rtGlobals=1		// Use modern global access method.


// USANS version of SASCALC

// to simulate the intensity from a USANS experiment for planning
// see John's instrument paper:
//
// J. Appl. Cryst. (2005) 38 1004-1011.
//
// SRK JUL 2009


// ideas:
//
// - more presets
//
// - NEED - 
// - printable output that makes sense to an instrument scientist at least
//   for instrument setup
//
// - make sure that the # points <-> increment relation meshes with ICP

//
// X plot as countrate, not absolute scale
// X 3e-5 cutoff
// X ? don't plot lowest angle range (but needs to be in the count time)
// - need empty beam and empty cell count rate vs. aperture (Cd vs. Gd?)
//


// need to add in empty and background corrections to see "reduced" data
// or at least compare to what the empty cell would give in the same count time
//
// -? model the direct beam?? currently the "red" region from -1 to 0.6 is almost entirely
// the primary beam, so it's a bit artificial (qmin is really ~ 3e-5)
//

//
// Need T_wide, T_rock, I peak for proper absolute scaling, but I don't know if it's really important
// to be able to simlulate to this extent
//


//#include "MultScatter_MonteCarlo_2D"



// Bring the UCALC panel to the front
// ALWAYS initializes the folders and variables
// then draws the panel if necessary
Proc Show_UCALC()

	Init_UCALC()
	DoWindow/F UCALC
	if(V_Flag==0)
		UCALC_Panel()
		CalcTotalCountTime()
		ControlUpdate/W=UCALC U_popup0		//force a pop of the function list
	Endif
	
End


//set up the global values for the angles, # points, and count time
Proc Init_UCALC()
	
	//
	NewDataFolder/O root:Simulation				// required to calculate the RandomDeviate
	NewDataFolder/O root:Packages:NIST:SAS				// required to calculate the RandomDeviate

//
	NewDataFolder/O root:Packages:NIST:USANS:SIM		//for the fake raw data
	NewDataFolder/O/S root:Packages:NIST:USANS:Globals:U_Sim		//for constants, panel, etc

	Variable/G gAngLow1 = -1
	Variable/G gAngHigh1 = 0.6
	Variable/G gNumPts1 = 33
	Variable/G gCtTime1 = 25
	Variable/G gIncr1 = 0.05	
	
	Variable/G gAngLow2 = 0.7
	Variable/G gAngHigh2 = 1.9
	Variable/G gNumPts2 = 13
	Variable/G gCtTime2 = 100
	Variable/G gIncr2 = 0.1	
	
	Variable/G gAngLow3 = 2
	Variable/G gAngHigh3 = 4.8
	Variable/G gNumPts3 = 15
	Variable/G gCtTime3 = 300
	Variable/G gIncr3 = 0.2	
	
	Variable/G gAngLow4 = 5
	Variable/G gAngHigh4 = 9.5
	Variable/G gNumPts4 = 10
	Variable/G gCtTime4 = 600
	Variable/G gIncr4 = 0.5	
	
	Variable/G gAngLow5 = 10
	Variable/G gAngHigh5 = 19
	Variable/G gNumPts5 = 10
	Variable/G gCtTime5 = 1200
	Variable/G gIncr5 = 1
	
	Variable/G gAngLow6 = 20
	Variable/G gAngHigh6 = 48
	Variable/G gNumPts6 = 15
	Variable/G gCtTime6 = 2000
	Variable/G gIncr6 = 2	
	
	Variable/G gAngLow7 = 50
	Variable/G gAngHigh7 = 95
	Variable/G gNumPts7 = 10
	Variable/G gCtTime7 = 3000
	Variable/G gIncr7 = 5	
	
	// results, setup values
	String/G gFuncStr=""
	String/G gTotTimeStr=""
	Variable/G gAnalyzerOmega = 7.1e-7		//solid angle of the analyzer, in steradians
	Variable/G gBeamCurrent=25000		//beam current Ed*I	(n/s) for 5/8" diam = 25000 n/s
	Variable/G gThick=0.1		//sample thickness (cm)	
	Variable/G gSamTrans=0.8
	Variable/G g_1D_DoABS = 0 		//=1 for abs scale, 0 for just counts
	Variable/G g_1D_PlotCR = 1		//=1 to plot countrate
	Variable/G g_1D_AddNoise = 1 		// add in appropriate noise to simulation
	
// a box for the results
	// ??	maybe not useful to report
	Variable/G g_1DEstDetCR	 = 0		// estimated detector count rate
	Variable/G g_1DTotCts = 0		
	Variable/G g_1DFracScatt= 0	// ??
	Variable/G g_1DEstTrans = 0	// ? can I calculate this?

// not on panel yet
	Variable/G g_Empirical_EMP = 0		// use an emperical model for empty cell subtraction
	Variable/G g_EmptyLevel = 0.7
	Variable/G g_BkgLevel = 0.6

	SetDataFolder root:
	
End

//// make the display panel a graph with a control bar just as in SASCALC
//// so that the subwindow syntax doesn't break all of the other functionality
////
//Window UCALC_Panel() : Graph
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(55,44,670,850) /K=1
//	ModifyGraph cbRGB=(36929,50412,31845)
//	DoWindow/C UCALC
//	DoWindow/T UCALC,"USANS Simulation"
//	ControlBar 320
//	
//	GroupBox group0,pos={5,0},size={577,159},title="Instrument Setup"
//	GroupBox group1,pos={5,165},size={240,147},title="Sample Setup"
//	GroupBox group2,pos={327,165},size={259,147},title="Results"
//	
//	PopupMenu popup0,pos={17,18},size={165,20},title="Sample Aperture Diam (in)"
//	PopupMenu popup0,mode=3,popvalue="0.625",value="0.25;0.50;0.625;0.75;1.0;1.75;2.0;"
//	PopupMenu popup2,pos={220,18},size={165,20},title="Presets"
//	PopupMenu popup2,mode=3,popvalue="Long Count",value="Short Count;Medium Count;Long Count;"
//	PopupMenu popup2,proc=UCALC_PresetPopup
//
//	SetDataFolder root:Packages:NIST:USANS:Globals:U_Sim
//	
//	Variable top=44,pt=0,inc=18
//	SetVariable setvar1a,pos={12,top},size={100,15},title="theta min",value= gAngLow1
//	SetVariable setvar1b,pos={119,top},size={100,15},title="theta max",value= gAngHigh1
//	SetVariable setvar1c,pos={227,top},size={100,15},title="increm",value= gIncr1
//	SetVariable setvar1d,pos={335,top},size={100,15},title="# points",value= gNumPts1
//	SetVariable setvar1e,pos={443,top},size={100,15},title="count (s)",value= gCtTime1
//	SetVariable setvar1a,labelBack=(65535,32768,32768)
//	
//	pt += inc
//	SetVariable setvar2a,pos={12,top+pt},size={100,15},title="theta min",value= gAngLow2
//	SetVariable setvar2b,pos={119,top+pt},size={100,15},title="theta max",value= gAngHigh2
//	SetVariable setvar2c,pos={227,top+pt},size={100,15},title="increm",value= gIncr2
//	SetVariable setvar2d,pos={335,top+pt},size={100,15},title="# points",value= gNumPts2
//	SetVariable setvar2e,pos={443,top+pt},size={100,15},title="count (s)",value= gCtTime2
//	SetVariable setvar2a labelBack=(65535,65533,32768)
//	
//	pt += inc
//	SetVariable setvar3a,pos={12,top+pt},size={100,15},title="theta min",value= gAngLow3
//	SetVariable setvar3b,pos={119,top+pt},size={100,15},title="theta max",value= gAngHigh3
//	SetVariable setvar3c,pos={227,top+pt},size={100,15},title="increm",value= gIncr3
//	SetVariable setvar3d,pos={335,top+pt},size={100,15},title="# points",value= gNumPts3
//	SetVariable setvar3e,pos={443,top+pt},size={100,15},title="count (s)",value= gCtTime3
//	SetVariable setvar3a labelBack=(32769,65535,32768)
//	
//	pt += inc
//	SetVariable setvar4a,pos={12,top+pt},size={100,15},title="theta min",value= gAngLow4
//	SetVariable setvar4b,pos={119,top+pt},size={100,15},title="theta max",value= gAngHigh4
//	SetVariable setvar4c,pos={227,top+pt},size={100,15},title="increm",value= gIncr4
//	SetVariable setvar4d,pos={335,top+pt},size={100,15},title="# points",value= gNumPts4
//	SetVariable setvar4e,pos={443,top+pt},size={100,15},title="count (s)",value= gCtTime4
//	SetVariable setvar4a labelBack=(32768,65535,65535)
//	
//	pt += inc
//	SetVariable setvar5a,pos={12,top+pt},size={100,15},title="theta min",value= gAngLow5
//	SetVariable setvar5b,pos={119,top+pt},size={100,15},title="theta max",value= gAngHigh5
//	SetVariable setvar5c,pos={227,top+pt},size={100,15},title="increm",value= gIncr5
//	SetVariable setvar5d,pos={335,top+pt},size={100,15},title="# points",value= gNumPts5
//	SetVariable setvar5e,pos={443,top+pt},size={100,15},title="count (s)",value= gCtTime5
//	SetVariable setvar5a labelBack=(32768,54615,65535)
//	
//	pt += inc
//	SetVariable setvar6a,pos={12,top+pt},size={100,15},title="theta min",value= gAngLow6
//	SetVariable setvar6b,pos={119,top+pt},size={100,15},title="theta max",value= gAngHigh6
//	SetVariable setvar6c,pos={227,top+pt},size={100,15},title="increm",value= gIncr6
//	SetVariable setvar6d,pos={335,top+pt},size={100,15},title="# points",value= gNumPts6
//	SetVariable setvar6e,pos={443,top+pt},size={100,15},title="count (s)",value= gCtTime6
//	SetVariable setvar6a labelBack=(44253,29492,58982)
//
//// the action procedures and limits/increments
//	SetVariable setvar1a proc=ThetaMinSetVarProc		//,limits={-2,0,0.1}
//	SetVariable setvar2a proc=ThetaMinSetVarProc
//	SetVariable setvar3a proc=ThetaMinSetVarProc
//	SetVariable setvar4a proc=ThetaMinSetVarProc
//	SetVariable setvar5a proc=ThetaMinSetVarProc
//	SetVariable setvar6a proc=ThetaMinSetVarProc
//
////
//	SetVariable setvar1b proc=ThetaMaxSetVarProc		//,limits={0.4,1,0.1}
//	SetVariable setvar2b proc=ThetaMaxSetVarProc
//	SetVariable setvar3b proc=ThetaMaxSetVarProc
//	SetVariable setvar4b proc=ThetaMaxSetVarProc
//	SetVariable setvar5b proc=ThetaMaxSetVarProc
//	SetVariable setvar6b proc=ThetaMaxSetVarProc
////
//	SetVariable setvar1c proc=IncrSetVarProc,limits={0.01,0.1,0.01}
//	SetVariable setvar2c proc=IncrSetVarProc,limits={0.02,0.2,0.02}
//	SetVariable setvar3c proc=IncrSetVarProc,limits={0.05,0.4,0.05}
//	SetVariable setvar4c proc=IncrSetVarProc,limits={0.1,1,0.1}
//	SetVariable setvar5c proc=IncrSetVarProc,limits={0.5,5,1}
//	SetVariable setvar6c proc=IncrSetVarProc,limits={1,10,2}
////
//	SetVariable setvar1d proc=NumPtsSetVarProc,limits={2,50,1}
//	SetVariable setvar2d proc=NumPtsSetVarProc,limits={2,50,1}
//	SetVariable setvar3d proc=NumPtsSetVarProc,limits={2,50,1}
//	SetVariable setvar4d proc=NumPtsSetVarProc,limits={2,50,1}
//	SetVariable setvar5d proc=NumPtsSetVarProc,limits={2,50,1}
//	SetVariable setvar6d proc=NumPtsSetVarProc,limits={2,50,1}
////
//	SetVariable setvar1e proc=CtTimeSetVarProc,limits={-1,50000,1}
//	SetVariable setvar2e proc=CtTimeSetVarProc,limits={-1,50000,10}
//	SetVariable setvar3e proc=CtTimeSetVarProc,limits={-1,50000,10}
//	SetVariable setvar4e proc=CtTimeSetVarProc,limits={-1,50000,30}
//	SetVariable setvar5e proc=CtTimeSetVarProc,limits={-1,50000,100}
//	SetVariable setvar6e proc=CtTimeSetVarProc,limits={-1,50000,100}
//	
//	Button button0,pos={255,180},size={60,20},fColor=(65535,65535,0),proc=U_SimPlotButtonProc,title="Plot"
//	Button button1,pos={260,286},size={50,20},proc=U_SaveButtonProc,title="Save"
//
////checkbox for "easy" mode
//	CheckBox check0 title="Simple mode?",pos={400,19},proc=EnterModeCheckProc,value=1
//	ThetaEditMode(2)		//checked on startup
//	
////	instrument setup
//	SetVariable U_setvar0_1,pos={20,211},size={160,15},title="Thickness (cm)"
//	SetVariable U_setvar0_1,limits={0,inf,0.1},value= root:Packages:NIST:USANS:Globals:U_Sim:gThick	
//	SetVariable U_setvar0_3,pos={20,235},size={160,15},title="Sample Transmission"
//	SetVariable U_setvar0_3,limits={0,1,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:gSamTrans
//	PopupMenu U_popup0,pos={20,185},size={165,20},proc=Sim_USANS_ModelPopMenuProc,title="Model"
//	PopupMenu U_popup0,mode=1,value= #"U_FunctionPopupList()"
//	SetVariable setvar0,pos={20,259},size={120,15},title="Empty Level"
//	SetVariable setvar0,limits={0,10,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:g_EmptyLevel
//	SetVariable setvar0_1,pos={20,284},size={120,15},title="Bkg Level"
//	SetVariable setvar0_1,limits={0,10,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:g_BkgLevel
//	
//	CheckBox check0_4 title="Show EMP?",pos={160,260},proc=ShowEMPCheckProc,value=0
//	
//	CheckBox check0_2,pos={253,239},size={60,14},title="CountRate?",variable= root:Packages:NIST:USANS:Globals:U_Sim:g_1D_PlotCR
//	CheckBox check0_3,pos={262,264},size={60,14},title="Noise?",variable= root:Packages:NIST:USANS:Globals:U_Sim:g_1D_AddNoise
//	
//// a box for the results
//	SetVariable totalTime,pos={338,185},size={150,15},title="Count time (h:m)",value= gTotTimeStr
////	ValDisplay valdisp0,pos={338,210},size={220,13},title="Total detector counts"
////	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= root:Packages:NIST:USANS:Globals:U_Sim:g_1DTotCts
//	ValDisplay valdisp0_2,pos={338,234},size={220,13},title="Fraction of beam scattered"
//	ValDisplay valdisp0_2,limits={0,0,0},barmisc={0,1000},value= root:Packages:NIST:USANS:Globals:U_Sim:g_1DFracScatt
//	ValDisplay valdisp0_3,pos={338,259},size={220,13},title="Estimated transmission"
//	ValDisplay valdisp0_3,limits={0,0,0},barmisc={0,1000},value=root:Packages:NIST:USANS:Globals:U_Sim:g_1DEstTrans
//
//	
//	SetDataFolder root:
//
//EndMacro

// ??make the USANS simulation results into a graph and a separate panel.
// the control bar at the top makes the whole thing too large, and control bars are limited
// to 500 pix wide, which is really tight
// left of 1055 is good for Mac, 955 is better for Win
//
Window UCALC_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String platform=UpperStr(IgorInfo(2))
	Variable pos=strsearch(platform,"WINDOWS",0)
	if(pos >= 0)		//windows
		Display /W=(55,44,855,450) /K=1
	else		//mac
		Display /W=(55,44,1055,544) /K=1
	endif
	
	ModifyGraph cbRGB=(36929,50412,31845)
	DoWindow/C UCALC
	DoWindow/T UCALC,"USANS Simulation"
	ControlBar/L 500
	
	GroupBox group0,pos={5,1},size={493,177},title="Instrument Setup"
	GroupBox group1,pos={5,183},size={240,147},title="Sample Setup"
	GroupBox group2,pos={5,343},size={259,147},title="Results"
	
	PopupMenu popup0,pos={17,19},size={165,20},title="Sample Aperture Diam (in)"
	PopupMenu popup0,mode=3,popvalue="0.625",value="0.25;0.50;0.625;0.75;1.0;1.75;2.0;"
	PopupMenu popup0,proc=UCALC_SampleAperturePopup
	PopupMenu popup2,pos={220,19},size={165,20},title="Presets"
	PopupMenu popup2,mode=3,popvalue="Long Count",value="Short Count;Medium Count;Long Count;"
	PopupMenu popup2,proc=UCALC_PresetPopup

	SetDataFolder root:Packages:NIST:USANS:Globals:U_Sim
	
	Variable top=46,pt=0,inc=18,left=0//left=533
	SetVariable setvar1a,pos={left+17,top},size={90,15},title="theta min",value= gAngLow1
	SetVariable setvar1b,pos={left+113,top},size={89,15},title="theta max",value= gAngHigh1
	SetVariable setvar1c,pos={left+209,top},size={89,15},title="increm",value= gIncr1
	SetVariable setvar1d,pos={left+299,top},size={100,15},title="# points",value= gNumPts1
	SetVariable setvar1e,pos={left+399,top},size={93,15},title="count (s)",value= gCtTime1
//	SetVariable setvar1a,labelBack=(65535,32768,32768)		//old rainbow
	SetVariable setvar1a,labelBack=(49858,65535,65535)
	
	pt += inc
	SetVariable setvar2a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow2
	SetVariable setvar2b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh2
	SetVariable setvar2c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr2
	SetVariable setvar2d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts2
	SetVariable setvar2e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime2
//	SetVariable setvar2a labelBack=(65535,65533,32768)		//old rainbow
	SetVariable setvar2a labelBack=(21074,8995,21074)
	
	pt += inc
	SetVariable setvar3a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow3
	SetVariable setvar3b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh3
	SetVariable setvar3c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr3
	SetVariable setvar3d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts3
	SetVariable setvar3e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime3
//	SetVariable setvar3a labelBack=(32769,65535,32768)		//old rainbow
	SetVariable setvar3a labelBack=(0,60652,60652)
	
	pt += inc
	SetVariable setvar4a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow4
	SetVariable setvar4b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh4
	SetVariable setvar4c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr4
	SetVariable setvar4d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts4
	SetVariable setvar4e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime4
//	SetVariable setvar4a labelBack=(32768,65535,65535)		//old rainbow
	SetVariable setvar4a labelBack=(0,51400,0)
	
	pt += inc
	SetVariable setvar5a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow5
	SetVariable setvar5b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh5
	SetVariable setvar5c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr5
	SetVariable setvar5d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts5
	SetVariable setvar5e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime5
//	SetVariable setvar5a labelBack=(32768,54615,65535)		//old rainbow
	SetVariable setvar5a labelBack=(59367,49344,0)
	
	pt += inc
	SetVariable setvar6a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow6
	SetVariable setvar6b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh6
	SetVariable setvar6c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr6
	SetVariable setvar6d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts6
	SetVariable setvar6e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime6
//	SetVariable setvar6a labelBack=(44253,29492,58982)		//old rainbow
	SetVariable setvar6a labelBack=(54998,0,0)

	pt += inc
	SetVariable setvar7a,pos={left+17,top+pt},size={90,15},title="theta min",value= gAngLow7
	SetVariable setvar7b,pos={left+113,top+pt},size={89,15},title="theta max",value= gAngHigh7
	SetVariable setvar7c,pos={left+209,top+pt},size={89,15},title="increm",value= gIncr7
	SetVariable setvar7d,pos={left+299,top+pt},size={100,15},title="# points",value= gNumPts7
	SetVariable setvar7e,pos={left+399,top+pt},size={93,15},title="count (s)",value= gCtTime7
//	SetVariable setvar7a labelBack=(44253,29492,58982)		//old rainbow
	SetVariable setvar7a labelBack=(39321,21845,51657)

// the action procedures and limits/increments
	SetVariable setvar1a proc=ThetaMinSetVarProc		//,limits={-2,0,0.1}
	SetVariable setvar2a proc=ThetaMinSetVarProc
	SetVariable setvar3a proc=ThetaMinSetVarProc
	SetVariable setvar4a proc=ThetaMinSetVarProc
	SetVariable setvar5a proc=ThetaMinSetVarProc
	SetVariable setvar6a proc=ThetaMinSetVarProc
	SetVariable setvar7a proc=ThetaMinSetVarProc

//
	SetVariable setvar1b proc=ThetaMaxSetVarProc		//,limits={0.4,1,0.1}
	SetVariable setvar2b proc=ThetaMaxSetVarProc
	SetVariable setvar3b proc=ThetaMaxSetVarProc
	SetVariable setvar4b proc=ThetaMaxSetVarProc
	SetVariable setvar5b proc=ThetaMaxSetVarProc
	SetVariable setvar6b proc=ThetaMaxSetVarProc
	SetVariable setvar7b proc=ThetaMaxSetVarProc
//
	SetVariable setvar1c proc=IncrSetVarProc,limits={0.01,0.1,0.01}
	SetVariable setvar2c proc=IncrSetVarProc,limits={0.02,0.2,0.02}
	SetVariable setvar3c proc=IncrSetVarProc,limits={0.05,0.4,0.05}
	SetVariable setvar4c proc=IncrSetVarProc,limits={0.1,1,0.1}
	SetVariable setvar5c proc=IncrSetVarProc,limits={0.5,5,1}
	SetVariable setvar6c proc=IncrSetVarProc,limits={1,10,2}
	SetVariable setvar7c proc=IncrSetVarProc,limits={1,20,2}
//
	SetVariable setvar1d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar2d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar3d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar4d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar5d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar6d proc=NumPtsSetVarProc,limits={2,50,1}
	SetVariable setvar7d proc=NumPtsSetVarProc,limits={2,50,1}
//
	SetVariable setvar1e proc=CtTimeSetVarProc,limits={-1,50000,1}
	SetVariable setvar2e proc=CtTimeSetVarProc,limits={-1,50000,10}
	SetVariable setvar3e proc=CtTimeSetVarProc,limits={-1,50000,10}
	SetVariable setvar4e proc=CtTimeSetVarProc,limits={-1,50000,30}
	SetVariable setvar5e proc=CtTimeSetVarProc,limits={-1,50000,100}
	SetVariable setvar6e proc=CtTimeSetVarProc,limits={-1,50000,100}
	SetVariable setvar7e proc=CtTimeSetVarProc,limits={-1,50000,100}
	
	Button button0,pos={left+280,200},size={130,20},fColor=(65535,65535,0),proc=U_SimPlotButtonProc,title="Simulate USANS"
	CheckBox check0_2,pos={left+280,250},size={60,14},title="CountRate?",variable= root:Packages:NIST:USANS:Globals:U_Sim:g_1D_PlotCR
	CheckBox check0_3,pos={left+280,270},size={60,14},title="Noise?",variable= root:Packages:NIST:USANS:Globals:U_Sim:g_1D_AddNoise
	CheckBox check0_4 title="Show EMP?",pos={left+280,290},proc=ShowEMPCheckProc,value=0


//checkbox for "easy" mode
	CheckBox check0 title="Simple mode?",pos={left+400,19},proc=EnterModeCheckProc,value=1
	ThetaEditMode(2)		//checked on startup
	
//	sample setup
	SetVariable U_setvar0_1,pos={left+20,231},size={160,15},title="Thickness (cm)"
	SetVariable U_setvar0_1,limits={0,inf,0.1},value= root:Packages:NIST:USANS:Globals:U_Sim:gThick	
	SetVariable U_setvar0_3,pos={left+20,255},size={160,15},title="Sample Transmission"
	SetVariable U_setvar0_3,limits={0,1,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:gSamTrans
	PopupMenu U_popup0,pos={left+20,205},size={165,20},proc=Sim_USANS_ModelPopMenuProc,title="Model"
	PopupMenu U_popup0,mode=1,value= #"U_FunctionPopupList()"
	SetVariable setvar0,pos={left+20,279},size={120,15},title="Empty Level",disable=2
	SetVariable setvar0,limits={0,10,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:g_EmptyLevel
	SetVariable setvar0_1,pos={left+20,304},size={120,15},title="Bkg Level",disable=2
	SetVariable setvar0_1,limits={0,10,0.01},value= root:Packages:NIST:USANS:Globals:U_Sim:g_BkgLevel
	
	
	
// a box for the results
	SetVariable totalTime,pos={left+20,370},size={150,15},title="Count time (h:m)",value= gTotTimeStr
	ValDisplay valdisp0_2,pos={left+20,395},size={220,13},title="Fraction of beam scattered"
	ValDisplay valdisp0_2,limits={0,0,0},barmisc={0,1000},value= root:Packages:NIST:USANS:Globals:U_Sim:g_1DFracScatt
	ValDisplay valdisp0_2,disable=1
	ValDisplay valdisp0_3,pos={left+20,420},size={220,13},title="Estimated transmission"
	ValDisplay valdisp0_3,limits={0,0,0},barmisc={0,1000},value=root:Packages:NIST:USANS:Globals:U_Sim:g_1DEstTrans
	ValDisplay valdisp0_3,disable=1
	Button button1,pos={left+20,400},size={150,20},proc=U_SavePanelProc,title="Save PNG"
	Button button2,pos={left+20,430},size={150,20},proc=U_ConfigTextProc,title="Config Text"
	Button button3,pos={left+20,460},size={150,20},proc=U_SaveButtonProc,title="Save Simulated Data"

// help, done buttons
	Button U_helpButton,pos={300,440},size={25,20},proc=showUCALCHelp,title="?"
	Button U_helpButton,help={"Show help file for simulation of USANS Data"}
	Button U_DoneButton,pos={350,440},size={50,20},proc=UCALCDoneButton,title="Done"
	Button U_DoneButton,help={"This button will close the panel"}
		
	SetDataFolder root:

EndMacro

Proc UCALCDoneButton(ctrlName): ButtonControl
	String ctrlName
	DoWindow/K UCALC
end

Proc showUCALCHelp(ctrlName): ButtonControl
	String ctrlName
	DisplayHelpTopic/K=1/Z "UCALC"
	if(V_flag !=0)
		DoAlert 0,"The USANS Simulation Help file could not be found"
	endif
end

// changing theta min - hold incr and #, result is new theta max
Function ThetaMinSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable ThetaMin = sva.dval
			String ns=CtrlNumber(sva.ctrlName)		//control number as a string
			NVAR incr = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gIncr"+ns)
			NVAR NumPts = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gNumPts"+ns)
			NVAR thetaMax = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngHigh"+ns)
			
			thetaMax = ThetaMin + incr*NumPts
			
			break
	endswitch

	return 0
End


// changing theta max - hold min and incr, result is new # of points
// then need to recalculate the total counting time
Function ThetaMaxSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable ThetaMax = sva.dval
			String ns=CtrlNumber(sva.ctrlName)		//control number as a string
			NVAR thetaMin = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngLow"+ns)
			NVAR NumPts = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gNumPts"+ns)
			NVAR Incr = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gIncr"+ns)
			
			NumPts = trunc( (thetaMax - ThetaMin) / incr )
		
			CalcTotalCountTime()
			
			break
	endswitch

	return 0
End

// changing increment - hold min and #, result is new max
Function IncrSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable incr = sva.dval
			String ns=CtrlNumber(sva.ctrlName)		//control number as a string
			NVAR thetaMin = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngLow"+ns)
			NVAR NumPts = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gNumPts"+ns)
			NVAR thetaMax = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngHigh"+ns)
			
			thetaMax = ThetaMin + incr*NumPts
		
			break
	endswitch

	return 0
End

// changing #pts - hold min and incr, result is new max
// then recalculate the total count time
Function NumPtsSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable NumPts = sva.dval
			String ns=CtrlNumber(sva.ctrlName)		//control number as a string
			NVAR thetaMin = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngLow"+ns)
			NVAR incr = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gIncr"+ns)
			NVAR thetaMax = $("root:Packages:NIST:USANS:Globals:U_Sim:"+"gAngHigh"+ns)

// old way, like ICP			
//			thetaMax = ThetaMin + incr*NumPts

// new way - to spread the points out over the specified angle range
			incr = (thetaMax - thetaMin) / numpts
			
			CalcTotalCountTime()
			
			break
	endswitch

	return 0
End

// changing count time - 
// then recalculate the total count time
Function CtTimeSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			CalcTotalCountTime()
			break
	endswitch

	return 0
End

// hard-wired for 7 controls
// return value is in seconds
// global display string is set with hrs:min
Function CalcTotalCountTime()

	Variable ii,num,totTime=0
	String pathStr="root:Packages:NIST:USANS:Globals:U_Sim:"
	num=7
	
	for(ii=1;ii<=num;ii+=1)
		NVAR ctTime = $(pathStr+"gCtTime"+num2str(ii))
		NVAR numPts = $(pathStr+"gNumPts"+num2str(ii))
		if(ctTime>0)
			totTime += ctTime*numPts
		endif
	endfor
	Variable hrs,mins
	hrs = trunc(totTime/3600)
	mins = trunc(mod(totTime,3600)/60)
//	Printf "Counting time (hr:min) = %d:%d\r",hrs,mins
	
	SVAR str = $(pathStr+"gTotTimeStr")
	sprintf str,"%d:%d",hrs,mins
	
	return(totTime)
End

//returns the control number from the name string
// all are setvarNa
Function/S CtrlNumber(str)
	String str
	
	return(str[6])
End

// changes edit mode of the theta min/max boxes and increment for simplified setup
// val = 2 = disable
// val = 0 = edit enabled
Function ThetaEditMode(val)
	Variable val
	
	SetVariable setvar1a,win=UCALC,disable=val
	SetVariable setvar1b,win=UCALC,disable=val
	SetVariable setvar1c,win=UCALC,disable=val
	
	SetVariable setvar2a,win=UCALC,disable=val
	SetVariable setvar2b,win=UCALC,disable=val
	SetVariable setvar2c,win=UCALC,disable=val
	
	SetVariable setvar3a,win=UCALC,disable=val
	SetVariable setvar3b,win=UCALC,disable=val
	SetVariable setvar3c,win=UCALC,disable=val
	
	SetVariable setvar4a,win=UCALC,disable=val
	SetVariable setvar4b,win=UCALC,disable=val
	SetVariable setvar4c,win=UCALC,disable=val
	
	SetVariable setvar5a,win=UCALC,disable=val
	SetVariable setvar5b,win=UCALC,disable=val
	SetVariable setvar5c,win=UCALC,disable=val
	
	SetVariable setvar6a,win=UCALC,disable=val
	SetVariable setvar6b,win=UCALC,disable=val
	SetVariable setvar6c,win=UCALC,disable=val
	
	SetVariable setvar7a,win=UCALC,disable=val
	SetVariable setvar7b,win=UCALC,disable=val
	SetVariable setvar7c,win=UCALC,disable=val
	return(0)
End



Function EnterModeCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			if(checked)
				ThetaEditMode(2)
			else
				ThetaEditMode(0)
			endif
			
			break
	endswitch

	return 0
End


Function ShowEMPCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked

			String list,item,popStr,qval,CR
			Variable OK=1

			if(exists("root:Packages:NIST:USANS:Globals:Q_2p0")==0)			//
				MakeUSANSEmptyWaves()
			endif
			
			
			if(checked)
				// put it on the graph
				SetDataFolder root:Packages:NIST:USANS:Globals
				ControlInfo/W=UCALC popup0
				popStr = S_Value
				strswitch(popStr)	// string switch
					case "0.25":		// execute if case matches expression
						qval = "Q_0p25"
						CR = "CR_0p25"
						break		
					case "0.50":	
						qval = "Q_0p50"
						CR = "CR_0p50"
						break	
					case "0.625":		
						qval = "Q_0p625"
						CR = "CR_0p625"
						break	
					case "1.75":		
						qval = "Q_1p75"
						CR = "CR_1p75"
						break	
					case "2.0":		
						qval = "Q_2p0"
						CR = "CR_2p0"
						break	
					default:							// optional default expression executed
						OK=0
				endswitch
				
				if(OK)
					AppendToGraph/W=UCALC $CR vs $qval
					ModifyGraph marker=19,mode($CR)=4,msize($CR)=3,rgb($CR)=(0,0,0)
				endif
				
			else
				//take it off of the graph
				SetDataFolder root:Packages:NIST:USANS:Globals
				list=WaveList("CR*", ";", "WIN:UCALC")
				item=StringFromList(0, list ,";")		//should be one item
				if(strlen(item) != 0)
					RemoveFromGraph/W=UCALC $item
				endif
			endif
			
			break
	endswitch

	SetDataFolder root:
	return 0
End



// based on the angle ranges above (with non-zero count times)
// plot where the data points would be
//
Function U_SimPlotButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			CalcUSANS()
			
			break
	endswitch

	return 0
End



// Fills a fake USANS folder with the concatenated ranges, and converts to Q
// root:Packages:NIST:USANS:SIM
//
// does the work of calculating and smearing the simluated USANS data set
Function CalcUSANS()	

	Variable num,ii,firstSet=0
	String pathStr="root:Packages:NIST:USANS:Globals:U_Sim:gCtTime"
	String fromType="SWAP",toType="SIM"
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	num = 7			//# of angular ranges
	
	// only try to plot ranges with non-zero count times
	firstSet=0
	for(ii=1;ii<=num;ii+=1)
		NVAR dum = $(pathStr+num2str(ii))
		if(dum>0)						
//			print "CtTime = ",dum
			firstSet += 1
			LoadSimulatedAngleRange(ii,"SWAP")	//overwrite what's in the SWAP folder
			
			// did not do this step
			//Convert2Countrate("SWAP")
			//
			
			if(firstSet==1)	//first time, overwrite
				NewDataWaves("SWAP","SIM")
				//plus my two waves
				Duplicate/O $(USANSFolder+":"+fromType+":countingTime"),$(USANSFolder+":"+toType+":countingTime")
				Duplicate/O $(USANSFolder+":"+fromType+":SetNumber"),$(USANSFolder+":"+toType+":SetNumber")

			else		//append to waves in "SIM"
				AppendDataWaves("SWAP","SIM")
				// and my two waves
				ConcatenateData( (USANSFolder+":"+toType+":countingTime"),(USANSFolder+":"+fromType+":countingTime") )
				ConcatenateData( (USANSFolder+":"+toType+":SetNumber"),(USANSFolder+":"+fromType+":SetNumber") )

			endif
			
		endif
	endfor


	//sort after all loaded - not by angle, but by Q
// Get rid of the negative angles - the smearing integration does not like these!
// (may add them back in later, but probably not)
	UDoAngleSort("SIM")
	
	ConvertAngle2Qvals("SIM",0)
	
	
	
	//fill the data with something
	WAVE qvals = root:Packages:NIST:USANS:SIM:qvals
	WAVE DetCts = root:Packages:NIST:USANS:SIM:DetCts
	

	//find the Trans Cts for T_Wide
//	FindTWideCts("EMP")

//generate a "fake" 1d data folder/set named "Sim_USANS" that can be used for smearing
// DOES NOT calculate a matrix, but instead fills 4-5-6 columns with -dQv
// so that the trapezoid rule is used
//	

	FakeUSANSDataFolder(qvals,DetCts,0.117,"Sim_USANS")

	// now calculate the smearing... instead of the counts
	SVAR funcStr = root:Packages:NIST:USANS:Globals:U_Sim:gFuncStr 		//set by the popup	
	
	Wave inten = root:Sim_USANS:Sim_USANS_i
	Wave sigave = root:Sim_USANS:Sim_USANS_s
	Wave countingTime = root:Sim_USANS:countingTime		//counting time per point in the set

	Duplicate/O inten root:Sim_USANS:Smeared_inten		// a place for the smeared result for probabilities
	Wave Smeared_inten = root:Sim_USANS:Smeared_inten

	String coefStr=""
	Variable sig_sas=0,wavelength = 2.4
	Variable Imon
	

	NVAR omega = root:Packages:NIST:USANS:Globals:U_Sim:gAnalyzerOmega
	
	if(exists(funcStr) != 0)
		FUNCREF SANSModelAAO_proto func=$("fSmeared"+funcStr)			//a wrapper for the structure version
		FUNCREF SANSModelAAO_proto funcUnsmeared=$(funcStr)		//unsmeared
		coefStr = MC_getFunctionCoef(funcStr)
		
		if(!MC_CheckFunctionAndCoef(funcStr,coefStr))
			Abort "Function and coefficients do not match. You must plot the unsmeared function before simulation."
		endif
		
		// do the smearing calculation
		func($coefStr,Smeared_inten,qvals)


		NVAR thick = root:Packages:NIST:USANS:Globals:U_Sim:gThick
		NVAR trans = root:Packages:NIST:USANS:Globals:U_Sim:gSamTrans
		NVAR SimDetCts = root:Packages:NIST:USANS:Globals:U_Sim:g_1DTotCts			//summed counts (simulated)
		NVAR estDetCR = root:Packages:NIST:USANS:Globals:U_Sim:g_1DEstDetCR			// estimated detector count rate
		NVAR fracScat = root:Packages:NIST:USANS:Globals:U_Sim:g_1DFracScatt		// fraction of beam captured on detector
		NVAR estTrans = root:Packages:NIST:USANS:Globals:U_Sim:g_1DEstTrans		// estimated transmission of sample
//		NVAR SimCountTime = root:Packages:NIST:USANS:Globals:U_Sim:gCntTime		//counting time used for simulation
		
		Imon = GetUSANSBeamIntensity()				//based on the aperture size, select the beam intensity
		Print "imon=",imon
		
		// calculate the scattering cross section simply to be able to estimate the transmission
		// unfortunately, this calculation is useless in the USANS range. So although it's calculated, the
		// results are never reported.
		// -- the main issue is that the integration range is optimized for SANS, and is not useful for USANS
		// -there are only a few points in the USANS range, and extending it lower caused issues before.
		CalculateRandomDeviate(funcUnsmeared,$coefStr,wavelength,"root:Packages:NIST:SAS:ran_dev",sig_sas)
		
//		if(sig_sas > 100)
//			sprintf abortStr,"sig_sas = %g. Please check that the model coefficients have a zero background, or the low q is well-behaved.",sig_sas
//		endif
		estTrans = exp(-1*thick*sig_sas)		//thickness and sigma both in units of cm
		Print "Sig_sas = ",sig_sas
		
		
		Duplicate/O qvals prob_i
					
		prob_i = trans*thick*omega*Smeared_inten			//probability of a neutron in q-bin(i)
		
//		Variable P_on = sum(prob_i,-inf,inf)
//		Print "P_on = ",P_on
		fracScat = 1-estTrans
		
		inten = (Imon*countingTime)*prob_i
		
		// do I round to an integer?
		inten = round(inten)

//		SimDetCts = sum(inten,-inf,inf)
//		estDetCR = SimDetCts/SimCountTime
		
		
		NVAR doABS = root:Packages:NIST:USANS:Globals:U_Sim:g_1D_DoABS
		NVAR plotCR = root:Packages:NIST:USANS:Globals:U_Sim:g_1D_PlotCR
		NVAR addNoise = root:Packages:NIST:USANS:Globals:U_Sim:g_1D_AddNoise
					
		sigave = sqrt(inten)		// assuming that N is large
		
		// add in random error in aveint based on the sigave
		if(addNoise)
			inten += gnoise(sigave)
			
			//round to an integer again
			inten = round(inten)		
		endif

		// convert to absolute scale? Maybe not needed
		// does nothing yet - need Ipeak, Twide
//		if(doABS)
//			Variable kappa = thick*omega*trans*iMon*ctTime
//			inten /= kappa
//			inten /= kappa
//		endif

		// plot as countrate - maybe easier to visualize, and all of the data overlaps
		if(plotCR)
			inten /= countingTime
			sigave /= countingTime
		endif
		
		GraphSIM()

	else
		//no function plotted, no simulation can be done
		DoAlert 0,"No function is selected or plotted, so no simulation is done. The default power law function is used."

		inten = U_Power_Law_Model(1e-6,3,0,qvals)
//		inten = U_SphereForm(1,9000,6e-6,0,qvals)		
	
		GraphSIM()

	endif
	

end


//sort the data in the "type"folder, based on angle
//carry along all associated waves
//
// ---a duplicate of DoAngleSort(), by modified to
// include counting time and setNumber
//
// also trims the beginning of each data set so that it does not include any negative or zero angles
//
Function UDoAngleSort(type)
	String type
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	Wave angle = $(USANSFolder+":"+Type+":Angle")
	Wave detCts = $(USANSFolder+":"+Type+":DetCts")
	Wave ErrdetCts = $(USANSFolder+":"+Type+":ErrDetCts")
	Wave MonCts = $(USANSFolder+":"+Type+":MonCts")
	Wave TransCts = $(USANSFolder+":"+Type+":TransCts")
	Wave countingTime = $(USANSFolder+":"+Type+":countingTime")
	Wave SetNumber = $(USANSFolder+":"+Type+":SetNumber")
	
	Sort Angle DetCts,ErrDetCts,MonCts,TransCts,Angle,countingTime,SetNumber
	
	Variable ii,num,numBad,ang,val
	num=numpnts(angle)
	ii=0
	numBad=0
	val = 0		//cutoff value
	do
		ang = angle[ii]
		if(ang <= val)
			numBad += 1
		else		//keep the points
			Angle[ii-numBad] = ang
			DetCts[ii-numBad] = DetCts[ii]
			ErrDetCts[ii-numBad] = ErrDetCts[ii]
			MonCts[ii-numBad] = MonCts[ii]
			TransCts[ii-numBad] = TransCts[ii]
			countingTime[ii-numBad] = countingTime[ii]
			SetNumber[ii-numBad] = SetNumber[ii]
		endif
		ii += 1
	while(ii<num)
	//trim the end of the waves
	DeletePoints num-numBad, numBad, DetCts,ErrDetCts,MonCts,TransCts,Angle,countingTime,SetNumber
	
	
	return(0)
End

// a simple default function
//
Function U_SphereForm(scale,radius,delrho,bkg,x)				
	Variable scale,radius,delrho,bkg
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (A)
	//[2] delrho (A-2)
	//[3] background (cm-1)

	
	// calculates scale * f^2/Vol where f=Vol*3*delrho*((sin(qr)-qrcos(qr))/qr^3
	// and is rescaled to give [=] cm^-1
	
	Variable bes,f,vol,f2
	//
	//handle q==0 separately
	If(x==0)
		f = 4/3*pi*radius^3*delrho*delrho*scale*1e8 + bkg
		return(f)
	Endif
	
	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3
	vol = 4*pi/3*radius^3
	f = vol*bes*delrho		// [=] A
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8		// [=] 1/cm
	
	return (scale*f2+bkg)	// Scale, then add in the background
	
End

// better default function
Function U_Power_Law_Model(A,m,bgd,x) : FitFunc
	Variable A, m,bgd,x
//	 Input (fitting) variables are:
	//[0] Coefficient
	//[1] (-) Power
	//[2] incoherent background
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = A*qval^-m + bgd
	Return (inten)
End


// mimics LoadBT5File
// creates two other waves to identify the set and the counting time for that set
//
Function LoadSimulatedAngleRange(set,type)
	Variable set
	String type

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	
	String s=num2str(set)
	NVAR angLow = $("root:Packages:NIST:USANS:Globals:U_Sim:gAngLow"+s)
	NVAR angHigh = $("root:Packages:NIST:USANS:Globals:U_Sim:gAngHigh"+s)
	NVAR numPts = $("root:Packages:NIST:USANS:Globals:U_Sim:gNumPts"+s)
	NVAR ctTime = $("root:Packages:NIST:USANS:Globals:U_Sim:gCtTime"+s)
	NVAR incr = $("root:Packages:NIST:USANS:Globals:U_Sim:gIncr"+s)
	
	Variable ii, err=0
	
	// generate q-points based on angular range from panel
	
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":Angle")
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":DetCts")
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":ErrDetCts")
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":MonCts")
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":TransCts")
	//
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":CountingTime")
	Make/O/D/N=(numPts) $(USANSFolder+":"+type+":SetNumber")
	
	Wave Angle = $(USANSFolder+":"+type+":Angle")
	Wave DetCts = $(USANSFolder+":"+type+":DetCts")
	Wave ErrDetCts = $(USANSFolder+":"+type+":ErrDetCts")
	Wave MonCts = $(USANSFolder+":"+type+":MonCts")
	Wave TransCts = $(USANSFolder+":"+type+":TransCts")
	Wave countingTime = $(USANSFolder+":"+type+":countingTime")
	Wave SetNumber = $(USANSFolder+":"+type+":SetNumber")
	
	countingTime = ctTime
	SetNumber = set
	
	for(ii=0;ii<numPts;ii+=1)
		Angle[ii] = angLow + ii*incr
		DetCts[ii] = set
	endfor
	
	//set the wave note for the DetCts
	String str=""
	str = "FILE:Sim "+s+";"
	str += "TIMEPT:"+num2str(ctTime)+";"
	str += "PEAKANG:0;"		//no value yet
	str += "STATUS:;"		//no value yet
	str += "LABEL:SimSet "+s+";"
	str += "PEAKVAL:;"		//no value yet
	str += "TWIDE:0;"		//no value yet
	Note DetCts,str
	
	return err			// Zero signifies no error.	
End

// add SIM data to the graph if it exists and is not already on the graph
//
//
// ** currently, I have changed the graph to not display the angle at the top. I have not yet
// found a way to keep the scaling of the two axes in-sync when the empty cell data is added to the
// graph (versus Q)
//
Function GraphSIM()

//	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
//	SetDataFolder $(USANSFolder+":SIM")

	SetDataFolder root:Sim_USANS
	//is it already on the graph?
	String list=""
	list = Wavelist("Sim_USANS*",";","WIN:UCALC")
	
	if(strlen(list)!=0)
//		Print "SIM already on graph"
		SetDataFolder root:
		return(0)
	Endif
	
	//append the data if it exists
	If(waveExists($"Sim_USANS_i")==1)
		DoWindow/F UCALC

// lines for the no-noise result vs angle
//		AppendToGraph/T Smeared_inten vs angle
		AppendToGraph Smeared_inten vs Sim_USANS_q
		ModifyGraph rgb(Smeared_inten)=(1,12815,52428)
		ModifyGraph mode(Smeared_inten)=4,marker(Smeared_inten)=19,msize(Smeared_inten)=2
		ModifyGraph tickUnit=1

// colored points for the simulation with noise on top
		AppendToGraph Sim_USANS_i vs Sim_USANS_q
		ModifyGraph mode(Sim_USANS_i)=3,marker(Sim_USANS_i)=19,msize(Sim_USANS_i)=4
		//don't reverse the dbZ21 or the highest angle will have "invisible" light blue error bars
		ModifyGraph zColor(Sim_USANS_i)={setNumber,1,7,dBZ21,0}				//better for 7 colors
//		ModifyGraph zColor(Sim_USANS_i)={setNumber,1,7,Rainbow,0}			//force the colors from 1->7
		ModifyGraph useMrkStrokeRGB(Sim_USANS_i)=1
		ErrorBars/T=0 Sim_USANS_i Y,wave=(Sim_USANS_s,Sim_USANS_s)
		
		ModifyGraph log=1
		ModifyGraph mirror(left)=1
		// if no top axis, then
//		ModifyGraph mirror(bottom)=1
		ModifyGraph grid=2
		ModifyGraph standoff=0
		
		// to make sure that the scales are the same (but fails on zoom)
		NewFreeAxis/O/T top_angle
		ModifyFreeAxis/Z top_angle,master= bottom,hook= TransformAngleAxisHook
		ModifyGraph lblPos(top_angle)=50,freePos(top_angle)=0
		ModifyGraph log(top_angle)=1
		
		SetDrawEnv linefgc= (39321,1,1),dash= 3,linethick= 3
		SetDrawEnv xcoord= bottom
		DrawLine 3e-05,0.01,3e-05,0.99
		
		Label top_angle "Angle"
		Label bottom "Q (1/A)"
		Label left "Counts or Count Rate"
		
		Legend
	endif
	
	SetDataFolder root:
End

Function TransformAngleAxisHook(s)
	STRUCT WMAxisHookStruct &s

	s.max= s.max/5.55e-5
	s.min= s.min/5.55e-5
	
	return 0
End

//fakes a folder with loaded 1-d usans data, no calculation of the matrix
Function	FakeUSANSDataFolder(qval,aveint,dqv,dataFolder)
	WAVE qval,aveint
	Variable dqv
	String dataFolder
	

	String baseStr=dataFolder
	if(DataFolderExists("root:"+baseStr))
		SetDataFolder $("root:"+baseStr)
	else
		NewDataFolder/S $("root:"+baseStr)
	endif

	////overwrite the existing data, if it exists
	Duplicate/O qval, $(baseStr+"_q")
	Duplicate/O aveint, $(baseStr+"_i")
	
	Duplicate/O qval, $(baseStr+"_s")
	Wave sigave = $(baseStr+"_s")

	sigave = sqrt(aveint)

	// make a resolution matrix for SANS data
	Variable np=numpnts(qval)
	Make/D/O/N=(np,4) $(baseStr+"_res")
	Wave res=$(baseStr+"_res")
	
	res[][0] = -dQv		//sigQ
	res[][1] = -dQv		//qBar
	res[][2] = -dQv		//fShad
	res[][3] = qval[p]		//Qvalues
	
	// extra waves of set number and counting time for the simulation
	WAVE ctW = root:Packages:NIST:USANS:SIM:countingTime
	WAVE setW = root:Packages:NIST:USANS:SIM:setNumber
	WAVE ang = root:Packages:NIST:USANS:SIM:Angle
	Duplicate/O ctW countingTime
	Duplicate/O setW setNumber
	Duplicate/O ang Angle


	//clean up		
	SetDataFolder root:
	
End


Function/S U_FunctionPopupList()
	String list,tmp
	list = User_FunctionPopupList()
	
	//simplify the display, forcing smeared calculations behind the scenes
	tmp = FunctionList("Smear*",";","NPARAMS:1")	//smeared dependency calculations
	list = RemoveFromList(tmp, list ,";")


	if(strlen(list)==0)
		list = "No functions plotted"
	endif
	
	list = SortList(list)
	
	return(list)
End     

Function Sim_USANS_ModelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			SVAR gStr = root:Packages:NIST:USANS:Globals:U_Sim:gFuncStr 
			gStr = popStr
			
			break
	endswitch

	return 0
End         

// if the sample aperture is changed, AND the empty data is displayed, change to the proper data
Function UCALC_SampleAperturePopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr

			ControlInfo/W=UCALC check0_4
			if(V_Value==1)		//currently checked, need to update
				
				STRUCT WMCheckboxAction cba
				cba.checked=0		//"un-check"
				cba.eventCode=2
				ShowEMPCheckProc(cba)
				
				cba.checked=1		//"re-check"
				ShowEMPCheckProc(cba)
			
			endif
			break
			
	endswitch
	
	return 0
End  


Function UCALC_PresetPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr

			SetDataFolder root:Packages:NIST:USANS:Globals:U_Sim
			
			NVAR gAngLow1 = gAngLow1
			NVAR gAngHigh1 = gAngHigh1
			NVAR gNumPts1 = gNumPts1
			NVAR gCtTime1 = gCtTime1
			NVAR gIncr1 = gIncr1
			
			NVAR gAngLow2 = gAngLow2
			NVAR gAngHigh2 = gAngHigh2
			NVAR gNumPts2 = gNumPts2
			NVAR gCtTime2 = gCtTime2
			NVAR gIncr2 = gIncr2
			
			NVAR gAngLow3 = gAngLow3
			NVAR gAngHigh3 = gAngHigh3
			NVAR gNumPts3 = gNumPts3
			NVAR gCtTime3 = gCtTime3
			NVAR gIncr3 = gIncr3
			
			NVAR gAngLow4 = gAngLow4
			NVAR gAngHigh4 = gAngHigh4
			NVAR gNumPts4 = gNumPts4
			NVAR gCtTime4 = gCtTime4
			NVAR gIncr4 = gIncr4
			
			NVAR gAngLow5 = gAngLow5
			NVAR gAngHigh5 = gAngHigh5
			NVAR gNumPts5 = gNumPts5
			NVAR gCtTime5 = gCtTime5
			NVAR gIncr5 = gIncr5
			
			NVAR gAngLow6 = gAngLow6
			NVAR gAngHigh6 = gAngHigh6
			NVAR gNumPts6 = gNumPts6
			NVAR gCtTime6 = gCtTime6
			NVAR gIncr6 = gIncr6
			
			NVAR gAngLow7 = gAngLow7
			NVAR gAngHigh7 = gAngHigh7
			NVAR gNumPts7 = gNumPts7
			NVAR gCtTime7 = gCtTime7
			NVAR gIncr7 = gIncr7
			
			strswitch(popStr)	// string switch
				case "Short Count":		// execute if case matches expression
					
					gAngLow1 = -1
					gAngHigh1 = 0.6
					gNumPts1 = 33
					gCtTime1 = 10
					gIncr1 = 0.05	
					
					gAngLow2 = 0.7
					gAngHigh2 = 1.9
					gNumPts2 = 6
					gCtTime2 = 60
					gIncr2 = 0.2	
					
					gAngLow3 = 2
					gAngHigh3 = 4.8
					gNumPts3 = 7
					gCtTime3 = 120
					gIncr3 = 0.4	
					
					gAngLow4 = 5
					gAngHigh4 = 9.5
					gNumPts4 = 5
					gCtTime4 = 180
					gIncr4 = 0.9	
					
					gAngLow5 = 10
					gAngHigh5 = 19
					gNumPts5 = 5
					gCtTime5 = 240
					gIncr5 = 1.8
					
					gAngLow6 = 20
					gAngHigh6 = 48
					gNumPts6 = 15
					gCtTime6 = 0
					gIncr6 = 2
					
					gAngLow7 = 50
					gAngHigh7 = 95
					gNumPts7 = 10
					gCtTime7 = 0
					gIncr7 = 5
					
					break						
				case "Medium Count":	
			
					gAngLow1 = -1
					gAngHigh1 = 0.6
					gNumPts1 = 33
					gCtTime1 = 10
					gIncr1 = 0.05	
					
					gAngLow2 = 0.7
					gAngHigh2 = 1.9
					gNumPts2 = 13
					gCtTime2 = 60
					gIncr2 = 0.1	
					
					gAngLow3 = 2
					gAngHigh3 = 4.8
					gNumPts3 = 15
					gCtTime3 = 120
					gIncr3 = 0.2	
					
					gAngLow4 = 5
					gAngHigh4 = 9.5
					gNumPts4 = 10
					gCtTime4 = 300
					gIncr4 = 0.5	
					
					gAngLow5 = 10
					gAngHigh5 = 19
					gNumPts5 = 10
					gCtTime5 = 600
					gIncr5 = 1
					
					gAngLow6 = 20
					gAngHigh6 = 48
					gNumPts6 = 15
					gCtTime6 = 1200
					gIncr6 = 2	
					
					gAngLow7 = 50
					gAngHigh7 = 95
					gNumPts7 = 10
					gCtTime7 = 0
					gIncr7 = 5
								
					break
				case "Long Count":	
					
					gAngLow1 = -1
					gAngHigh1 = 0.6
					gNumPts1 = 33
					gCtTime1 = 25
					gIncr1 = 0.05	
					
					gAngLow2 = 0.7
					gAngHigh2 = 1.9
					gNumPts2 = 13
					gCtTime2 = 100
					gIncr2 = 0.1	
					
					gAngLow3 = 2
					gAngHigh3 = 4.8
					gNumPts3 = 15
					gCtTime3 = 300
					gIncr3 = 0.2	
					
					gAngLow4 = 5
					gAngHigh4 = 9.5
					gNumPts4 = 10
					gCtTime4 = 600
					gIncr4 = 0.5	
					
					gAngLow5 = 10
					gAngHigh5 = 19
					gNumPts5 = 10
					gCtTime5 = 1200
					gIncr5 = 1
					
					gAngLow6 = 20
					gAngHigh6 = 48
					gNumPts6 = 15
					gCtTime6 = 2000
					gIncr6 = 2
					
					gAngLow7 = 50
					gAngHigh7 = 95
					gNumPts7 = 10
					gCtTime7 = 3000
					gIncr7 = 5
					
					break
				default:			
			endswitch
			
			break
	endswitch

	//update the count time
	CalcTotalCountTime()

	SetDataFolder root:
	
	return 0
End      


// return the beam intensity based on the sample aperture diameter
//
// based on the equation in John's instrument paper
//
Function GetUSANSBeamIntensity()	

	String popStr
	Variable flux,diam,rad
	
	ControlInfo/W=UCALC popup0
	popStr = S_Value
	diam=str2num(popStr)		//in inches
	rad = diam/2*25.4			//radius in mm
	
	flux = 662*rad*rad-39.9*rad*rad*rad+0.70*rad*rad*rad*rad
	
	return(flux)
End

// based on the angle ranges above (with non-zero count times)
// save fake data points into a fake BT5 data file
//
Function U_SaveButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Variable num,ii,baseNumber=100,firstSet=0
			String pathStr="root:Packages:NIST:USANS:Globals:U_Sim:gCtTime"
			SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
			String baseName="SIMUL"
			
			num = 7			//# of angular ranges
			
			// only try to plot ranges with non-zero count times
			firstSet=0
			for(ii=1;ii<=num;ii+=1)
				NVAR dum = $(pathStr+num2str(ii))
				if(dum>0)						
					firstSet += 1
					if(firstSet==1)	//first time, ask for base name
						Prompt baseName,"Enter a base name for the files"
						Prompt baseNumber,"Enter the starting index"
						DoPrompt "Enter Information for Save",baseName,baseNumber
						
						if(V_Flag==1)		//user canceled
							return(1)
						endif
					endif
						
					SaveFakeUSANS(baseName,baseNumber-1,ii)
					
				endif
			endfor
									
			break
	endswitch

	return 0
End


//
// duplicates the BT5 file format
// 
Function SaveFakeUSANS(nameStr,num,set)
	String nameStr
	Variable num,set
		
	String folder = "root:Packages:NIST:USANS:SIM:"
	String pathStr="root:Packages:NIST:USANS:Globals:U_Sim:"
	String termStr="\r\n"		//VAX uses only <CR> as terminator, but only CRLF seems to FTP correctly to VAX
	
//	WAVE DetCts = $(folder+"DetCts")		//these are only dummy values
	WAVE DetCts = root:Sim_USANS:Sim_USANS_i
	WAVE angle = $(folder+"Angle")
	WAVE SetNumber = $(folder+"SetNumber")
	WAVE countingTime = $(folder+"countingTime")
	
	NVAR ang1 = $(pathStr+"gAngLow"+num2str(set))
	NVAR ang2 = $(pathStr+"gAngHigh"+num2str(set))
	NVAR incr = $(pathStr+"gIncr"+num2str(set))
	
	Variable refNum,ii,wavePts,numPts,first,last,ctTime,monCt,transDet
	String str,fileStr,dateStr
	
	wavePts = numpnts(angle)
	for(ii=0;ii<wavePts;ii+=1)
		if(setNumber[ii] == set)
			first = ii
			break
		endif
	endfor
		
	for(ii=wavePts-1;ii>=0;ii-=1)
		if(setNumber[ii] == set)
			last = ii
			break
		endif
	endfor
	
//	Print "First, last = ",first,last
	
	// set up some of the strings needed
	fileStr=nameStr+num2str(num+set)+".bt5"
	dateStr = date()// + " "+Secs2Time(DateTime,2)
	ctTime = countingTime[first]
	numPts = last-first+1
	
	MonCt = ctTime*GetUSANSBeamIntensity()
	
	transDet = 999		//bogus and constant value
		
	//actually open the file
	Open refNum as fileStr
	
	sprintf str,"'%s' '%s' 'I'        %d    1  'TIME'   %d  'RAW'",fileStr,dateStr,ctTime,numpts
	fprintf refnum,"%s"+termStr,str
	fprintf refnum,"%s"+termStr,"  Filename         Date            Scan       Mon    Prf  Base   #pts  Type"
	
	fprintf refnum,"Simulated USANS data"+termStr

	fprintf refnum,"%s"+termStr,"   0    0    0    0   0  0  0     0.0000     0.00000 0.00000   0.00000    2"
	fprintf refnum,"%s"+termStr," Collimation      Mosaic    Wavelength   T-Start   Incr.   H-field #Det    "
	fprintf refnum,"%s"+termStr,"  1       0.00000    0.00000    0.00000"
	fprintf refnum,"  2       %9.5f    %9.5f    %9.5f"+termStr,ang1,incr,ang2
	fprintf refnum,"%s"+termStr,"  3      10.00000    0.00000   10.00000"
	fprintf refnum,"%s"+termStr,"  4      10.00000    0.00000   10.00000"
	fprintf refnum,"%s"+termStr,"  5       0.00000    0.00000    0.00000"
	fprintf refnum,"%s"+termStr,"  6       0.00000    0.00000    0.00000"
	fprintf refnum,"%s"+termStr," Mot:    Start       Step      End"
	fprintf refnum,"%s"+termStr,"     A2       MIN       COUNTS "

	//loop over the waves, picking out the desired set
	//write 2 lines each time
	for(ii=first;ii<=last;ii+=1)
		sprintf str,"      %6.3f    %6.2f         %d",angle[ii],ctTime/60,DetCts[ii]
		fprintf refnum,"%s"+termStr,str

		sprintf str,"%d,%d,0,%d,0,0,0,0",MonCt,DetCts[ii],transDet
		fprintf refnum,"%s"+termStr,str
	endfor
	
	Close refnum

	return(0)
end


// print out the USANS configuration in some reasonable format
Function/S USANSConfigurationText()

	String str="",temp

	SetDataFolder root:Packages:NIST:USANS:Globals:U_Sim
	
	// results, setup values
	SVAR gTotTimeStr=gTotTimeStr
	
	Variable ii,num
	String pathStr="root:Packages:NIST:USANS:Globals:U_Sim:"
	num=7
	
	str += "USANS Instrument Configuration:\r\r"
	str += "Theta Min  Theta Max   Increment   # Points   Count Time\r"
	
	
	for(ii=1;ii<=num;ii+=1)
		NVAR ctTime = $(pathStr+"gCtTime"+num2str(ii))
		if(ctTime>0)
			NVAR angLow = $(pathStr+"gAngLow"+num2str(ii))
			NVAR angHigh = $(pathStr+"gAngHigh"+num2str(ii))
			NVAR incr = $(pathStr+"gIncr"+num2str(ii))
			NVAR numPts = $(pathStr+"gNumPts"+num2str(ii))
			
			sprintf temp,"%9.3f  %9.3f  %9.3f  %9d  %9d\r",angLow,angHigh,incr,numPts,ctTime
			str += temp
		endif
	endfor
	
	
	sprintf temp,"\r\rTotal Counting Time (HR:MIN) = %s\r",gTotTimeStr
	str += temp

   	
   setDataFolder root:
   return str			 
End

Function DisplayUCALCText()

	if(WinType("USANS_Configuration")==0)
		NewNotebook/F=0/K=1/N=USANS_Configuration /W=(480,44,880,369)
	endif
	//replace the text
	Notebook USANS_Configuration selection={startOfFile, endOfFile}
	Notebook USANS_Configuration font="Monaco",fSize=10,text=USANSConfigurationText()
	return(0)
end


//
Function U_ConfigTextProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
				DisplayUCALCText()					
			break
	endswitch

	return 0
End

// this will save a graphic of the whole panel that then needs to be opened and printed
// must be a PNG @ screen resolution
//
Function U_SavePanelProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SavePICT/P=home/E=-5/B=72/SNAP=1	
			
			// can I reload and print?
			// how will the users know where this went and what to do with it?
			//			
			break
	endswitch

	return 0
End
