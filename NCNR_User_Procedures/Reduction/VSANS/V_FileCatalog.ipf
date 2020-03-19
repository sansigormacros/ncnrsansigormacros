#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion = 7.00

//
// UPDATED for VSANS -
// June 2016  SRK
// more columns + improved handling Jan 2018
//
// included ANSTO sort panel from david m
//

// Adding columns to the table now means:
// 1-Make the wave in V_BuildCatVeryShortTable
// 2-Declare the wave in V_GetHeaderInfoToWave, and read/fill in the value
//


//
// TODO
// x- clean up and remove all of the references to other facilities, since they will not have VSANS modules
// x- add in more appropriate and some missing fields more useful to VSANS (intent, multiple beam centers, etc.)
// -- can I make the choice of columns customizable? There are "sets" of columns that are not used for 
//    some experiments (magnetic, rotation, temperature scans, etc.) but are necessary for others.
// x- SortColumns operation may be of help in managing the long list of files to sort
//
// (DONE):
// x- clean up the list of files that now accumulates in the RawVSANS folder!!! Everything is there, including
//    files that are NOT RAW VSANS data (MASK and DIV, but these are HDF)
// x- WHY -- because if I PATCH anything, then re-run the catalog, the changes are NOT shown, since the 
//    reader will go to the LOCAL copy first! So maybe I need to clear the folder out before I start the 
//    file catalog
// x- maybe it's a good thing to wipe out the RawVSANS folder before an Experiment SAVE (to save a LOT of 
//    space on disk and a potentially VERY long save
// x- see V_CleanOutRawVSANS() in V_Utilities_General for the start of this (this is now called in 
//    V_BuildCatVeryShortTable(), the starting point for generating the table.) 
//
// NEW for VSANS
// clear out the folders in the RawVSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "bad" local copy will be read in.
// (DONE)
//  x- this *may* be a very slow operation. Warn users. Give them a choice to keep local copies. If
//     the "patched" values are written locally too, then maybe the update from disk is not needed.
//     But typically, I'd like to see that the disk version really did get updated...
// x- (NO)make a background task to periodically "kill" a few of the files? maybe too dangerous.
// x- (NO)change the V_GetHeaderInfoToWave function to allow "refreshing" of a single row, say after
//    a file has been patched - then the disk and local copies are in sync
//
// -- run a profiler on the catalog to see if there is an obvious place to speed up the process
//

Function catalogProfiler()
	V_BuildCatVeryShortTable()
End

//
//	SRK modified 30 JAN07 to include Rotation angle, Temperature, and B-field in the table (at the end)
//

//**************
// Vers 1.2 090401
//
// Procedures for creating the Catalog listings of the SANS datafiles in the folder
// specified by catPathName.
// Header information from each of the dataifles is organized in a table for
// easy identification of each file. CatVSANSTable is the preferred invocation,
// although CatVSNotebook and CatNotebook can also be used.
// Files in the folder that are not RAW SANS data are appended to the end of the listing.
//**************

//this main procedure does all the work, obtaining the folder path, 
//parsing the filenames in the list and (dispatching) to write out the 
//appropriate information to the growing (table) of data. V_GetHeaderInfoToWave() does the individual reads
Function V_BuildCatVeryShortTable()
	
	Variable err
	Variable t1 = ticks
	
	PathInfo catPathName
	if(v_flag==0)
		err = V_PickPath()		//sets the local path to the data (catPathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif

//
// WaveList will list waves in the order that they were created - so at a first pass,
// create the waves in the order that I want them in the table.
// The user can rearrange the columns, but likely won't
//	
	DoWindow/F CatVSANSTable
	
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"

	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Make/O/T/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"


	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
		
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_F"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_F"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_F"	
	
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_M"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_M"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_M"	
	
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_B"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_B"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_B"
		
//	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
//	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"

	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"		//added Mar 2010

	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Make/O/D/N=0 $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"




	WAVE/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	WAVE/T Labels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	WAVE/T DateAndTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
//	WAVE SDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
	WAVE Lambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	WAVE CntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
	WAVE Transmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	WAVE Thickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
//	WAVE XCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
//	WAVE YCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"

	WAVE/T nGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	WAVE NumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
	WAVE RotAngle = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	WAVE Temperature = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	WAVE Field = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	WAVE MCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
	WAVE Pos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"
	WAVE/T Intent = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
	WAVE/T Purpose = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
	WAVE Group_ID = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"

	
	If(V_Flag==0)
		V_BuildTableWindow()
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness)=40
//		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter)=40
//		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens)=30
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Field)=50
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR)=50

		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides)=40
		ModifyTable width(root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos)=30
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos)=3			//to make the display look nice, given the floating point values from ICE
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda)=3		//may not work in all situations, but an improvement
//		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD)=5
		ModifyTable trailingZeros(root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature)=1
		ModifyTable sigDigits(root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature)=4

		ModifyTable width(Point)=0		//JUN04, remove point numbers - confuses users since point != run

// (DONE)
//  x- experimental hook with contextual menu
//		
		SetWindow kwTopWin hook=V_CatTableHook, hookevents=1	// mouse down events

	Endif


// NEW for VSANS
// clear out the folders in the RawVSANS folder, otherwise any changes/patches written to disk
// will not be read in, the "bad" local copy will be read in for any subsequent operations.
// (DONE)
//  x- this *may* be a very slow operation. Warn users. Give them a choice to keep local copies? If
//     the "patched" values are written locally too, then maybe the update from disk is not needed.
//     But typically, I'd like to see that the disk version really did get updated...
//
	//	V_CleanOutRawVSANS()
// This will display a progress bar
	Variable numToClean
	numToClean = V_CleanupData_w_Progress(0,1)

	Print "Cleaned # files = ",numToClean
	Print "Cleanup time (s) = ",(ticks - t1)/60.15
	Variable cleanupTime = (ticks - t1)/60.15

	//get a list of all files in the folder, some will be junk version numbers that don't exist	
	String list,partialName,tempName,temp=""
	list = IndexedFile(catPathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
	
	numitems = ItemsInList(list,";")
	Variable sc=1
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
	if(gLaptopMode == 1)
		sc = 0.7
	endif
	
	// show a progress bar for filling the file catalog
	Variable indefinite=0,useIgorDraw=1
	NewPanel /N=ProgressPanel /W=(285*sc,111*sc,739*sc,193*sc)
	ValDisplay valdisp0,win=ProgressPanel,pos={sc*18,32*sc},size={sc*342,18*sc},limits={0,numitems,0},barmisc={0,0}
	ValDisplay valdisp0,win=ProgressPanel,value= _NUM:0
	DrawText 20*sc,24*sc,"Refreshing file catalog... Please Wait..."

	if( indefinite )
		ValDisplay valdisp0,win=ProgressPanel,mode= 4	// candy stripe
	else
		ValDisplay valdisp0,win=ProgressPanel,mode= 3	// bar with no fractional part
	endif
	if( useIgorDraw )
		ValDisplay valdisp0,win=ProgressPanel,highColor=(49535,1000,1000)		//(0,65535,0)
	endif
	Button bStop,win=ProgressPanel,pos={sc*375,32*sc},size={sc*50,20*sc},title="Stop"
	DoUpdate /W=ProgressPanel /E=1	// mark this as our progress window
	
	
	//loop through all of the files in the list, reading CAT/SHORT information if the file is RAW SANS
	String str,fullName
	Variable lastPoint
	ii=0
	
	Make/T/O/N=0 notRAWlist
	do
	
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		//get a valid file based on this partialName and catPathName
		tempName = V_FindValidFilename(partialName)
		
		
		If(cmpstr(tempName,"")==0) 		//a null string was returned
			//write to notebook that file was not found
			//if string is not a number, report the error
			if(numtype(str2num(partialName)) == 2)
				str = "this file was not found: "+partialName+"\r\r"
				//Notebook CatWin,font="Times",fsize=12,text=str
			Endif
		else
			//prepend path to tempName for read routine 
			PathInfo catPathName
			FullName = S_path + tempName
			//make sure the file is really a RAW data file
			ok = V_CheckIfRawData(fullName)
		
			if (!ok)
				//write to notebook that file was not a RAW SANS file
				lastPoint = numpnts(notRAWlist)
				InsertPoints lastPoint,1,notRAWlist
				notRAWlist[lastPoint]=tempname
			else
				//go write the header information to the Notebook
				V_GetHeaderInfoToWave(fullName,tempName)
			Endif
		Endif
		ii+=1
		
		ValDisplay valdisp0,win=ProgressPanel,value= _NUM:ii
		DoUpdate /W=ProgressPanel
		
	while(ii<numitems)
	
	KillWindow ProgressPanel

//Now sort them all based on some criterion that may be facility dependent (aim is to order them as collected)
	V_SortWaves()
	
//Append the files that are not raw files to the list
	V_AppendNotRAWFiles(notRAWlist)	
	KillWaves/Z notRAWlist
//
	Print "Total time (s) = ",(ticks - t1)/60.15
	Print "Time per raw data file (without cleanup time) (s) = ",( (ticks - t1)/60.15 - cleanupTime)/(numpnts(labels))
	// (don't use numpnts(notRawList) to normalize, these aren't all raw data files)
	//
	// clean out again, so that the file SAVE is not slow due to the large experiment size
	// (DONE) x- decide if this is really necessary (not necessary at this point)
//	
//	V_CleanOutRawVSANS()
			
			
	return(0)
End

//
// TODO:
//  this is experimental...not been tested by any users yet
// -- what else to add to the menu? (MSK and DIV now work)
// -- add directly to WORK files?
// -- "set" as some special file type, intent, use? (quick "patch" operations)
// -- "check" the reduction protocol for completeness?
//
// x- seems to not "let go" of a selection (missing the mouse up?)
//    (possibly) less annoying if I only handle mouseup and present a menu then.
//
Function V_CatTableHook(infoStr)
	String infoStr
	String event= StringByKey("EVENT",infoStr)
	
	Variable ii
	
//	Print "EVENT= ",event
	strswitch(event)
		case "mouseup":
//			Variable xpix= NumberByKey("MOUSEX",infoStr)
//			Variable ypix= NumberByKey("MOUSEY",infoStr)
//			PopupContextualMenu/C=(xpix, ypix) "yes;no;maybe;"
			PopupContextualMenu "Load RAW;Load MSK;Load DIV;-;Send to MRED;"
			
			WAVE/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
			Variable err
			strswitch(S_selection)
				case "Load RAW":
					GetSelection table,CatVSANSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					err = V_LoadHDF5Data(FileNames[V_StartRow],"RAW")
					if(!err)		//directly from, and the same steps as DisplayMainButtonProc(ctrlName)
						SVAR hdfDF = root:file_name			// last file loaded, may not be the safest way to pass
						String folder = StringFromList(0,hdfDF,".")
						
						// this (in SANS) just passes directly to fRawWindowHook()
						V_UpdateDisplayInformation("RAW")		// plot the data in whatever folder type
												
						// set the global to display ONLY if the load was called from here, not from the 
						// other routines that load data (to read in values)
						SVAR gLast = root:Packages:NIST:VSANS:Globals:gLastLoadedFile
						gLast = hdfDF
						
					endif
					break
					
				case "Load MSK":
					GetSelection table,CatVSANSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					err = V_LoadHDF5Data(FileNames[V_StartRow],"MSK")
					
					break
					
				case "Load DIV":
					GetSelection table,CatVSANSTable,1
//					Print V_flag, V_startRow, V_startCol, V_endRow, V_endCol
					Print "Loading " + FileNames[V_StartRow]
					err = V_LoadHDF5Data(FileNames[V_StartRow],"DIV")

					break
				case "Send to MRED":
					//
					SVAR/Z numList=root:Packages:NIST:VSANS:Globals:MRED:gFileNumList
					if(SVAR_Exists(numList))
						GetSelection table,CatVSANSTable,1
						for(ii=V_StartRow;ii<=V_endRow;ii+=1)
	//						Print "selected " + FileNames[ii]
							numList += fileNames[ii] + ","
						endfor
						// pop the menu on the mred panel
						V_MREDPopMenuProc("",1,"")
					endif
					break
					
			endswitch		//popup selection
	endswitch	// event
	
	return 0
End



//appends the list of files that are not RAW SANS data to the filename wave (1st column)
//for display in the table. Note that the filenames column will now be longer than all other
//waves in the table
//
// skip this step if there are no files to tack on
Function V_AppendNotRAWFiles(w)
	Wave/T w
	if(numpnts(w) != 0)
		Wave/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
		Variable lastPoint
		lastPoint = numpnts(Filenames)
		InsertPoints lastPoint,numpnts(w),Filenames
		Filenames[lastPoint,numpnts(Filenames)-1] = w[p-lastPoint]
	endif
	return(0)
End

//
// this is called BEFORE the notRAWfiles are added to the fileNames wave
// so that the waves are still all the same length and can properly be sorted.
//
Function V_SortWaves()
//	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
////	Wave/T GSuffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
//	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
//	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
////	Wave GSDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
//	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
//	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
//	Wave GTotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
//	Wave GCntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
//	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
//	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
////	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
////	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
//
//	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
//	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
////	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
////	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
//	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
//	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
//	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
//	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
//	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"
//	Wave/T GIntent = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
//	Wave/T GPurpose = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
//	Wave G_ID = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"
//
//
//// DONE
//// x- the default sort is by SUFFIX, which does not exist for VSANS. So decide on a better key
////     now, the sort is by FileName by default
////	Sort GFilenames, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens,GRunNumber,GIsTrans,GRot,GTemp,GField,GMCR,GPos,gNumGuides
//
//	Sort GFilenames, GFilenames, GLabels, GDateTime,  GIntent, GPurpose, G_ID, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,GRot,GTemp,GField,GMCR,GPos,gNumGuides

	SetDataFolder root:Packages:NIST:VSANS:CatVSHeaderInfo:
	
	String list = WaveList("*",",","")
	String cmd
	
	list = list[0,strlen(list)-2]		//remove the trailing comma or "invalid column name" error
	
	sprintf cmd, "Sort Filenames, %s", list
//	Print cmd			// For debugging
	
	Execute cmd
	
	SetDataFolder root:
	return(0)
End

//function to create the CAT/VSTable to display the header information
//this table is just like any other table
Function V_BuildTableWindow()

	SetDataFolder root:Packages:NIST:VSANS:CatVSHeaderInfo:
	
	String list = WaveList("*",",","")
	String cmd
	
	list = list[0,strlen(list)-2]		//remove the trailing comma or "invalid column name" error
	
	sprintf cmd, "Edit %s", list
//	Print cmd			// For debugging
	
	Execute cmd

	String name="CatVSANSTable"
	DoWindow/C $name
	
	SetDataFolder root:
	
//	Wave/T Filenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
//	Wave/T Labels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
//	Wave/T DateAndTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
////	Wave SDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
//	Wave Lambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
//	Wave CntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
//	Wave TotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
//	Wave CntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
//	Wave Transmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
//	Wave Thickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
////	Wave XCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
////	Wave YCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
//
//	Wave/T NumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
//	Wave NumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
//	Wave RotAngle =  $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
//	Wave Temperature = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
//	Wave Field= $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
//	Wave MCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"		//added Mar 2008
//	Wave Pos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"
//	Wave/T Intent = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
//	Wave/T Purpose = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
//	Wave Group_ID = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"
//
//// original order, magnetic at the end
////	Edit Filenames, Labels, DateAndTime, SDD, Lambda, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR as "Data File Catalog"
//// with numGuides
////	Edit Filenames, Labels, DateAndTime, SDD, Lambda, numGuides, CntTime, TotCnts, CntRate, Transmission, Thickness, XCenter, YCenter, NumAttens, RotAngle, Temperature, Field, MCR, Pos as "Data File Catalog"

//	Edit Filenames, Labels, DateAndTime,  Intent, Purpose, Group_ID, Lambda, numGuides, CntTime, TotCnts, CntRate, Transmission, Thickness, NumAttens, RotAngle, Temperature, Field, MCR, Pos as "Data File Catalog"


	return(0)
End

//reads header information and puts it in the appropriate waves for display in the table.
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist. sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function V_GetHeaderInfoToWave(fname,sname)
	String fname,sname
	

	Variable lastPoint,ctime,detcnt,cntrate

	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
//	Wave/T GSuffix = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Suffix"
	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"
	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"

	WAVE sdd_f = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_F"
	WAVE sdd_m = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_M"
	WAVE sdd_b = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD_B"

	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"

	Wave TotCnts_F = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_F"
	Wave CntRate_F = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_F"
	Wave TotCnts_M = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_M"
	Wave CntRate_M = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_M"
	Wave TotCnts_B = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts_B"
	Wave CntRate_B = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate_B"
	
	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
//	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
//	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
//	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
//	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"
	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"
	Wave/T GIntent = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
	Wave/T GPurpose = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
	Wave G_ID = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"

	lastPoint = numpnts(GLambda)
		
	//filename
	InsertPoints lastPoint,1,GFilenames
	GFilenames[lastPoint]=sname
	
//	//read the file alphanumeric suffix
//	// (DONE) x- this does not exist for VSANS - so is there an equivalent, or delete? ((delete))
//	InsertPoints lastPoint,1,GSuffix
//	GSuffix[lastPoint]="unknown"

	//read the counting time (integer)
	InsertPoints lastPoint,1,GCntTime
	ctime = V_getCount_time(fname)
	GCntTime[lastPoint]=ctime
	
	//read the file creation date (string)
	InsertPoints lastPoint,1,GDateTime
	GDateTime[lastPoint]=V_getDataStartTime(fname)

	// read the sample.label text field (string)
	InsertPoints lastPoint,1,GLabels
	GLabels[lastPoint]=V_getSampleDescription(fname)
	
		
	//read the reals
	//detector count and (derived) count rate
	detcnt = V_getDet_IntegratedCount(fname,"FL")
	detcnt += V_getDet_IntegratedCount(fname,"FR")
	detcnt += V_getDet_IntegratedCount(fname,"FT")
	detcnt += V_getDet_IntegratedCount(fname,"FB")

	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,TotCnts_F
	TotCnts_F[lastPoint]=detcnt
	InsertPoints lastPoint,1,CntRate_F
	CntRate_F[lastPoint]=cntrate

	detcnt = V_getDet_IntegratedCount(fname,"ML")
	detcnt += V_getDet_IntegratedCount(fname,"MR")
	detcnt += V_getDet_IntegratedCount(fname,"MT")
	detcnt += V_getDet_IntegratedCount(fname,"MB")

	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,TotCnts_M
	TotCnts_M[lastPoint]=detcnt
	InsertPoints lastPoint,1,CntRate_M
	CntRate_M[lastPoint]=cntrate
	
	detcnt = V_getDet_IntegratedCount(fname,"B")
	cntrate = detcnt/ctime
	InsertPoints lastPoint,1,TotCnts_B
	TotCnts_B[lastPoint]=detcnt
	InsertPoints lastPoint,1,CntRate_B
	CntRate_B[lastPoint]=cntrate
		
		
	//Attenuators
	// (DONE) x- this is the "number" of the attenuator
	InsertPoints lastPoint,1,GNumAttens
	GNumAttens[lastPoint]=V_getAtten_number(fname)
	
	//Transmission
	InsertPoints lastPoint,1,GTransmission
	GTransmission[lastPoint]=V_getSampleTransmission(fname)
	
	//Thickness
	InsertPoints lastPoint,1,GThickness
	GThickness[lastPoint]=V_getSampleThickness(fname)

//	// TODO --  the x and y center have different meaning, since there are multiple panels
//	// TODO -- remove the hard-wiring
//	String detStr = "FL"
//	//XCenter of beam on detector
//	InsertPoints lastPoint,1,GXCenter
//	GXCenter[lastPoint]=V_getDet_beam_center_x(fname,detStr)
//	
//	// TODO --  the x and y center have different meaning, since there are multiple panels
//	//YCenter
//	InsertPoints lastPoint,1,GYCenter
//	GYCenter[lastPoint]=V_getDet_beam_center_y(fname,detStr)

//	 there are multiple distances to report
//	//SDD
	InsertPoints lastPoint,1,sdd_f
	sdd_f[lastPoint]=V_getDet_ActualDistance(fname,"FL")

	InsertPoints lastPoint,1,sdd_m
	sdd_m[lastPoint]=V_getDet_ActualDistance(fname,"ML")
	
	InsertPoints lastPoint,1,sdd_b
	sdd_b[lastPoint]=V_getDet_ActualDistance(fname,"B")
		
	//wavelength
	InsertPoints lastPoint,1,GLambda
	GLambda[lastPoint]=V_getWavelength(fname)
	
	//Rotation Angle
	InsertPoints lastPoint,1,GRot
	GRot[lastPoint]=V_getSampleRotationAngle(fname)
	
	//Sample Temperature
	// this reads sample:temperature which is the average temperature reading (may be affected by noise)
	InsertPoints lastPoint,1,GTemp
	GTemp[lastPoint]=V_getSampleTemperature(fname)

	// TODO -- this is not yet implemented
	//Sample Field
	InsertPoints lastPoint,1,GField
	GField[lastPoint]=-999
		
	// Monitor Count Rate
	InsertPoints lastPoint,1,GMCR
	GMCR[lastPoint]  = V_getBeamMonNormData(fname)/ctime		//total monitor count / total count time


// number of guides and sample position, only for NCNR (a string now)
	InsertPoints lastPoint,1,GNumGuides
	GNumGuides[lastPoint]  = V_getNumberOfGuides(fname)

// TODO -- maybe this is better to convert to a text wave?	
	//Sample Position (== number position in 10CB)
	InsertPoints lastPoint,1,GPos
	GPos[lastPoint] = str2num(V_getSamplePosition(fname))

// Intent (text)
	InsertPoints lastPoint,1,GIntent
	GIntent[lastPoint] = V_getReduction_intent(fname)

// Purpose (text)
	InsertPoints lastPoint,1,GPurpose
	GPurpose[lastPoint] = V_getReduction_purpose(fname)
		
// group_id (sample)
	InsertPoints lastPoint,1,G_ID
	G_ID[lastPoint] = V_getSample_groupID(fname)

	return(0)
End



// just to call the function to generate the panel
Proc V_Catalog_Sort()
	V_BuildCatSortPanel()
End

// [davidm] create CAT Sort-Panel
function V_BuildCatSortPanel()

	// check if CatVSANSTable exists
	DoWindow CatVSANSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return 0
	endif
	
	// bring CatSortPanel to front
	DoWindow/F CatSortPanel
	if (V_flag != 0)
		return 0
	endif
	
	print "Creating CAT Sort-Panel..."

	Variable sc = 1
	
	NVAR gLaptopMode = root:Packages:NIST:VSANS:Globals:gLaptopMode
		
	if(gLaptopMode == 1)
		sc = 0.7
	endif
		
	//PauseUpdate
	NewPanel /W=(600*sc,360*sc,790*sc,730*sc)/K=1 as "CAT - Sort Panel"
	DoWindow/C CatSortPanel
	ModifyPanel fixedSize=1, cbRGB = (42919, 53970, 60909)
	
	Button SortFilenamesButton,		pos={sc*25, 8*sc},		size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Filenames"
	Button SortLabelsButton,			pos={sc*25,38*sc},		size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Labels"
	Button SortDateAndTimeButton,	pos={sc*25,68*sc},		size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Date and Time"
	Button SortIntentButton,			pos={sc*25,98*sc},		size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Intent"
	Button SortPurposeButton,		pos={sc*25,128*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Purpose"
	Button SortIDButton,			pos={sc*25,158*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Group ID"
	Button SortLambdaButton,			pos={sc*25,188*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Lambda"
	Button SortCountTimButton,		pos={sc*25,218*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Count Time"
	Button SortSDDFButton,		pos={sc*25,248*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="SDD F"
	Button SortCountRateFButton,		pos={sc*25,278*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Count Rate F"
	Button SortMonitorCountsButton,	pos={sc*25,308*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Monitor Counts"
	Button SortTransmissionButton,	pos={sc*25,338*sc},	size={sc*140,24*sc},proc=V_CatVSANSTable_SortProc,title="Transmission"

end

Proc V_CatVSANSTable_SortProc(ctrlName) : ButtonControl // added by [davidm]
	String ctrlName
	
	// check if CatVSANSTable exists
	DoWindow CatVSANSTable
	if (V_flag==0)
		DoAlert 0,"There is no File Catalog table. Use the File Catalog button to create one."
		return
	endif
		
	// have to use function
	V_CatVSANSTable_SortFunction(ctrlName)
	
end

function V_CatVSANSTable_SortFunction(ctrlName) // added by [davidm]
	String ctrlName

// still need to declare these to access notRaw files and to get count of length
	Wave/T GFilenames = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Filenames"
	Wave/T GLabels = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Labels"

//	Wave/T GDateTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:DateAndTime"
////	Wave GSDD = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:SDD"
//	Wave GLambda = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Lambda"
//	Wave GCntTime = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntTime"
//	Wave GTotCnts = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:TotCnts"
//	Wave GCntRate = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:CntRate"
//	Wave GTransmission = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Transmission"
//	Wave GThickness = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Thickness"
////	Wave GXCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:XCenter"
////	Wave GYCenter = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:YCenter"
//	Wave/T GNumGuides = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:nGuides"
//	Wave GNumAttens = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:NumAttens"
////	Wave GRunNumber = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RunNumber"
////	Wave GIsTrans = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:IsTrans"
//	Wave GRot = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:RotAngle"
//	Wave GTemp = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Temperature"
//	Wave GField = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Field"
//	Wave GMCR = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:MCR"
//	Wave GPos = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Pos"
//	Wave/T GIntent = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Intent"
//	Wave/T GPurpose = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Purpose"
//	Wave G_ID = $"root:Packages:NIST:VSANS:CatVSHeaderInfo:Group_ID"

	
	// take out the "not-RAW-Files"
	Variable fileCount = numpnts(GFilenames)
	Variable rawCount = numpnts(GLabels)
	Variable notRAWcount = fileCount - rawCount
	
	if (notRAWcount > 0)
		Make/T/O/N=(notRAWcount) notRAWlist
		notRAWlist[0, notRAWcount-1] = GFilenames[p+rawCount]
		DeletePoints rawCount, notRAWcount, GFilenames
	endif


// get the list
	SetDataFolder root:Packages:NIST:VSANS:CatVSHeaderInfo:
	
	String list = WaveList("*",",",""),sortKey=""
	String cmd
	
	list = list[0,strlen(list)-2]		//remove the trailing comma or "invalid column name" error
	
// set the sortKey string	
	strswitch (ctrlName)
	
		case "SortFilenamesButton":
//			Sort GFilenames, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
//			Sort GFilenames,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Filenames"
			break
			
		case "SortLabelsButton":
//			Sort GLabels, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
//			Sort GLabels,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Labels"
			break
			
		case "SortDateAndTimeButton":
//			Sort GDateTime, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR
//			Sort GDateTime,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "DateAndTime"

			break
			
		case "SortIntentButton":
//			Sort GIntent,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Intent"

			break
			
		case "SortIDButton":
//			Sort G_ID,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Group_ID"

			break
			
		case "SortLambdaButton":
//			Sort GLambda, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GLambda,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Lambda"

			break
			
		case "SortCountTimButton":
//			Sort GCntTime, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GCntTime,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "CntTime"

			break
			
		case "SortSDDFButton":
//			Sort GTotCnts, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GTotCnts,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "SDD_F"

			break
			
		case "SortCountRateFButton":
//			Sort GCntRate, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GCntRate,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "CntRate_F"

			break
			
		case "SortMonitorCountsButton":
			sortKey = "MCR"

			break
			
		case "SortTransmissionButton":
//			Sort GTransmission, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GTransmission,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Transmission"

			break
			
		case "SortPurposeButton":
//			Sort GThickness, GSuffix, GFilenames, GLabels, GDateTime, GSDD, GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness, GXCenter, GYCenter, GNumAttens, GRunNumber, GIsTrans, GRot, GTemp, GField, GMCR 
//			Sort GPurpose,  GPurpose, GFilenames, GLabels, GDateTime,  GLambda, GCntTime, GTotCnts, GCntRate, GTransmission, GThickness,   GNumAttens,   GRot, GTemp, GField, GMCR, GIntent, G_ID
			sortKey = "Purpose"

			break
	
	endswitch
	
	//do the sort
//	sprintf cmd, "Sort %s, %s", sortKey,list
// use braces and second key to keep anything with the same first "key" value in numerical run number order
	sprintf cmd, "Sort {%s,Filenames} %s", sortKey,list
//	Print cmd			// For debugging
	
	Execute cmd
	
	
	// insert the "not-RAW-Files" again
	if (notRAWcount > 0)
		InsertPoints rawCount, notRAWcount, GFilenames
		GFilenames[rawCount, fileCount-1] = notRAWlist[p-rawCount]
	endif
	
	SetDataFolder root:

end

