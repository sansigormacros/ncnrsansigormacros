#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



// NEW for SANS, from VSANS
// clear out the folders in the RawVSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "stale" local copy will be read in for any subsequent operations.
//
// This operation is typically necessary after data files have been patched, or
// transmissions have been calculated, etc.
//
// this will, by default, display a progress bar
//
//
Function CleanoutRawSANS()

	Variable numToClean,t1
	
	t1 = ticks
	numToClean = CleanupData_w_Progress(0,1)

	Print "Cleaned # files = ",numToClean
	Print "Cleanup time (s) = ",(ticks - t1)/60.15
	Variable cleanupTime = (ticks - t1)/60.15


	return(0)
End




//
// examples straight from Wavemetrics help file topic "Progress Windows"
// Try simpletest(0,0) and simpletest(1,0), simpletest(0,1) and simpletest(1,1)
//
//
// look for simpletest() function in Wavemetrics help file topic "Progress Windows"
//  this is a modified version.
//
// call with (1,1) to get the candystripe bar
// call with (0,1) to the the "countdown" bar as they are killed
//
Function CleanupData_w_Progress(indefinite, useIgorDraw)
	Variable indefinite
	Variable useIgorDraw		// True to use Igor's own draw method rather than native
	
	Variable num,numToClean
	
	// is there anything there to be killed?
	num = CleanOutOneRawSANS()
	numToClean = num
	if(num <= 0)
		return(0)
	endif
	
	// there are some folders to kill, so proceed
	
	Variable sc = 1
	
	NVAR/Z gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	NewPanel /N=ProgressPanel /W=(285*sc,111*sc,739*sc,193*sc)
	ValDisplay valdisp0,win=ProgressPanel,pos={sc*18,32*sc},size={sc*342,18*sc},limits={0,num,0},barmisc={0,0}
	ValDisplay valdisp0,win=ProgressPanel,value= _NUM:0
	DrawText 20*sc,24*sc,"Cleaning up old files... Please Wait..."
	
	if( indefinite )
		ValDisplay valdisp0,win=ProgressPanel,mode= 4	// candy stripe
	else
		ValDisplay valdisp0,win=ProgressPanel,mode= 3	// bar with no fractional part
	endif
	if( useIgorDraw )
		ValDisplay valdisp0,win=ProgressPanel,highColor=(15000,45535,15000)		//(0,65535,0)
	endif
	Button bStop,win=ProgressPanel,pos={sc*375,32*sc},size={sc*50,20*sc},title="Stop"
	DoUpdate /W=ProgressPanel /E=1	// mark this as our progress window

	do
		num = CleanOutOneRawSANS()
		if( V_Flag == 2 || num == 0 || num == -1)	// either "stop" or clean exit, or "done" exit from function
			break
		endif
		
		ValDisplay valdisp0,win=ProgressPanel,value= _NUM:num
		DoUpdate /W=ProgressPanel
	while(1)
	

	KillWindow ProgressPanel
	return(numToClean)
End


// 
// x- this still does not quite work. If there are no sub folders present in the RawVSANS folder
//    it still thinks there is (1) item there.
// x- if I replace the semicolon with a comma, it thinks there are two folders present and appears
//    to delete the RawVSANS folder itself! seems very dangerous...this is because DataFolderDir returns
//    a comma delimited list, but with a semicolon and \r at the end. need to remove these...
//
// x- for use with progress bar, kills only one folder, returns the new number of folders left
// x- if n(in) = n(out), nothing was able to be killed, so return "done" code
Function CleanOutOneRawSANS()

	SetDataFolder root:Packages:NIST:RawSANS:
	
	// get a list of the data folders there
	// kill them all if possible
	String list,item
	Variable numFolders,ii,pt,numIn
	
	list = DataFolderDir(1)
	// this has FOLDERS: at the beginning and is comma-delimited
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]			//remove the ";\r" from the end of the string
//	print list
	
	numFolders = ItemsInList(list , ",")
	numIn = numFolders
//	Print List
//	print strlen(list)

	if(numIn > 0)
		item = StringFromList(0, list ,",")
//		Print item
		KillDataFolder/Z $(item)
	endif

	list = DataFolderDir(1)
	list = list[8,strlen(list)]
	pt = strsearch(list,";",inf,1)
	list = list[0,pt-1]
	numFolders = ItemsInList(list, ",")
	
	if(numIn == numFolders)
		Printf "%g RawSANS folders could not be killed\r",numFolders
		SetDataFolder root:

		return (-1)
	endif
	
	SetDataFolder root:	
	return(numFolders)
End
