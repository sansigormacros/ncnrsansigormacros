#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1



//Functions to deal with TISANE data

Static Constant ATXY = 0
Static Constant ATXYM = 2
Static Constant ATMIR = 1
Static Constant ATMAR = 3

Static Constant USECSPERTICK=0.1 // microseconds
Static Constant TICKSPERUSEC=10
Static Constant XBINS=128
Static Constant YBINS=128

Proc Show_TISANE_Panel()
	DoWindow/F TISANE
	if(V_flag ==0)
		Init_TISANE()
		TISANE()
	EndIf
End


Function Init_TISANE()
	String/G root:Packages:NIST:gTISANE_logfile
	Variable/G 	root:Packages:NIST:AIMTYPE_XY=0 // XY Event
	Variable/G 	root:Packages:NIST:AIMTYPE_XYM=2 // XY Minor event
	Variable/G 	root:Packages:NIST:AIMTYPE_MIR=1 // Minor rollover event
	Variable/G 	root:Packages:NIST:AIMTYPE_MAR=3 // Major rollover event

	Variable/G root:Packages:NIST:gTISANE_time_msw = 0
	Variable/G root:Packages:NIST:gTISANE_time_lsw = 0
	Variable/G root:Packages:NIST:gTISANE_t_longest = 0

	Variable/G root:Packages:NIST:gTISANE_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:gTISANE_nslices = 10  //Number of time slices
	Variable/G root:Packages:NIST:gTISANE_slicewidth  = 1000 //Slicewidth in us 
	
	Variable/G root:Packages:NIST:gTISANE_prescan // Do we prescan the file?
	Variable/G root:Packages:NIST:gTISANE_logint = 1

	NVAR nslices = root:Packages:NIST:gTISANE_nslices
	
	SetDataFolder root:
	NewDataFolder/O/S root:Packages:NIST:TISANE
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData
	
	SetDataFolder root:
End

Proc TISANE()
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=2 /W=(100,50,600,680)/N=TISANE
	DoWindow/C TISANE
	ModifyPanel fixedSize=1,noEdit =1
	//ShowTools/A
	SetDrawLayer UserBack
	Button button0,pos = {10,10}, size={150,20},title="Load TISANE Log File",fSize=12
	Button button0,proc=LoadTISANELog_Proc
	SetVariable setvar3,pos= {20,590},size={460,20},title=" ",fSize=12
	SetVariable setvar3,disable=2,variable=root:Packages:NIST:gTISANE_logfile
	CheckBox chkbox1,pos={170,15},title="Prescan file? (increases load time)"
	CheckBox chkbox1,variable = root:Packages:NIST:gTISANE_prescan
	Button doneButton,pos={400,10}, size={50,20},title="Done",fSize=12
	Button doneButton,proc=TISANEDone_Proc
	
	//DrawLine 10,35,490,35
	Button button1,pos = {10,50}, size={150,20},title="Process Data",fSize=12
	Button button1,proc=ProcessLog_Proc
	SetVariable setvar1,pos={170,50},size={160,20},title="Number of slices",fSize=12
	SetVariable setvar1,value=root:Packages:NIST:gTISANE_nslices
	SetVariable setvar2,pos={330,50},size={160,20},title="Slice Width (us)",fSize=12
	SetVariable setvar2,value=root:Packages:NIST:gTISANE_slicewidth
	//DrawLine 10,65,490,65
	
	CheckBox chkbox2,pos={20,95},title="Log Intensity",value=1
	CheckBox chkbox2,variable=root:Packages:NIST:gTISANE_logint,proc=LogInt_Proc
	SetVariable setvar0,pos={320,90},size={160,20},title="Display Time Slice",fSize=12
	SetVariable setvar0,value= root:Packages:NIST:gTISANE_tsdisp
	SetVariable setvar0,proc=sliceSelect_Proc
	Display/W=(20,120,480,580)/HOST=TISANE/N=TISANE_slicegraph
	AppendImage/W=TISANE#TISANE_slicegraph/T root:Packages:NIST:TISANE:dispsliceData
	ModifyImage/W=TISANE#TISANE_slicegraph  ''#0 ctab= {*,*,Rainbow,0}
	ModifyImage/W=TISANE#TISANE_slicegraph ''#0 ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A left
	SetActiveSubwindow ##
EndMacro

Function LoadTISANELog_Proc(ctrlName) : ButtonControl
	String ctrlName
	
	Variable fileref
	SVAR filename = root:Packages:NIST:gTISANE_logfile
	NVAR prescan = root:Packages:NIST:gTISANE_prescan
	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth
	NVAR nslices = root:Packages:NIST:gTISANE_nslices
	NVAR t_longest = root:Packages:NIST:gTISANE_t_longest
	
	Open/R/D fileref
	filename = S_filename
	
	if(prescan )
		PreProcessLog()
		slicewidth = trunc(t_longest/nslices)
		DoUpdate
	endif

End

Function TISANEDone_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K TISANE
			break
	endswitch

End

Function ProcessLog_Proc(ctrlName) : ButtonControl
	String ctrlName

	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth
	NVAR nslices = root:Packages:NIST:gTISANE_nslices
	
	ProcessLog(nslices,slicewidth)
	
End

Function LogInt_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:TISANE
	if(checked)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	SetDataFolder root:
End

Function sliceSelect_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:gTISANE_nslices
	NVAR selectedslice = root:Packages:NIST:gTISANE_tsdisp
	
	if(varNum < 0)
		selectedslice = 0
		DoUpdate
	elseif (varNum > nslices-1)
		selectedslice = nslices-1
		DoUpdate
	else
		ModifyImage/W=TISANE#TISANE_slicegraph ''#0 plane = varNum 
	endif

End

Function ProcessLog(nslices,slicewidth)
	Variable nslices,slicewidth
	
	NVAR time_msw = root:Packages:NIST:gTISANE_time_msw
	NVAR time_lsw = root:Packages:NIST:gTISANE_time_lsw
	NVAR t_longest = root:Packages:NIST:gTISANE_t_longest
	
	NVAR logint = root:Packages:NIST:gTISANE_logint
	
	SVAR filepathstr = root:Packages:NIST:gTISANE_logfile
	SetDataFolder root:Packages:NIST:TISANE

	//Create bin lookup
	Variable tickwidth, i ,boundary
	Variable fileref
	
	Make/O/N = (nslices) t_lookup
	tickwidth = floor(slicewidth/USECSPERTICK)
	boundary = 0
	for (i = 0 ; i < nslices; i += 1)
		t_lookup[i] = boundary
		boundary += tickwidth
	endfor
	
	Make/O/N=(XBINS,YBINS,nslices)  slicedData
	Open/R fileref as filepathstr

	String buffer
	Variable dataval,b,tmp
	
	Variable xval,tyval,yval,timeval,ppto,type

	do
		FReadLine fileref, buffer
		if (strlen(buffer) == 0)
			break
		endif
		sscanf buffer,"%x",dataval
		
		//print (dataval)
		
		//This is hideous, but that is what you get for IGOR not doing structs like C
		type = (dataval & ~(2^32 - 2^30 -1))/2^30

		switch(type)
			case ATXY:		
				//printf "XY : "		
				xval = ~(dataval & ~(2^32 - 2^8)) & 127
				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
				time_lsw = (dataval & ~(2^32 - 2^29))/2^16
				timeval = (time_msw * (2^13)) + time_lsw
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				//printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
				b = FindBin(timeval,nslices)
				slicedData[xval][yval][b] += 1
				break
			case ATXYM:
				//printf "XYM : "
				xval = ~(dataval & ~(2^32 - 2^8)) & 127
				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
				time_lsw =  (dataval & ~(2^32 - 2^29 ))/2^16
				break
			case ATMIR:
				//printf "MIR : "
				time_msw =  (dataval & ~(2^32 - 2^29 ))/2^16
				timeval = (time_msw * (2^13)) + time_lsw
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				//printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
				b = FindBin(timeval,nslices)
				slicedData[xval][yval][b] += 1
				break
			case ATMAR:
				//printf "MAR : \r"
				break
		endswitch
	while(1)	

	Close fileref

	Duplicate/O slicedData logslicedData
	logslicedData[][][] = log(slicedData[p][q][r])
	if(logint)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif
	
	SetDataFolder root:
End 


Function FindBin(nticks,nslices)
	Variable nticks,nslices
	
	WAVE t_lookup = root:Packages:NIST:TISANE:t_lookup
	
	Variable i
	Variable whichbin = nslices -1
	for (i= 0; i < nslices; i+=1)
		if (nticks > t_lookup[i])
			whichbin = i
		else 
			break
		endif
	endfor
	return whichbin
End


Function PreProcessLog()
	
	NVAR time_msw = root:Packages:NIST:gTISANE_time_msw
	NVAR time_lsw = root:Packages:NIST:gTISANE_time_lsw
	NVAR t_longest = root:Packages:NIST:gTISANE_t_longest
	
	SVAR filepathstr = root:Packages:NIST:gTISANE_logfile
	SetDataFolder root:Packages:NIST:TISANE

	Variable fileref
	
	Open/R fileref as filepathstr

	String buffer
	Variable dataval,timeval,type

	do
		FReadLine fileref, buffer
		if (strlen(buffer) == 0)
			break
		endif
		sscanf buffer,"%x",dataval
		
		//This is hideous, but that is what you get for IGOR not doing structs like C
		type = (dataval & ~(2^32 - 2^30 -1))/2^30

		switch(type)
			case ATXY:		
				time_lsw = (dataval & ~(2^32 - 2^29))/2^16
				timeval = (time_msw * (2^13)) + time_lsw
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				break
			case ATXYM:
				time_lsw =  (dataval & ~(2^32 - 2^29 ))/2^16
				break
			case ATMIR:
				time_msw =  (dataval & ~(2^32 - 2^29 ))/2^16
				timeval = (time_msw * (2^13)) + time_lsw
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				break
			case ATMAR:
				break
		endswitch
	while(1)	

	Close fileref
	
	SetDataFolder root:
End 


