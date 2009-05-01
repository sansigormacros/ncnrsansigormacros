#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.0

//**************
// Vers 1. 18JAN06
//
// Procedures for creating a catalog listing of USANS datafiles in the folder
// specified by catPathName.
//
// selects only files with a named prefix, since all data from a given cycle
// is in the data folder.
// Header information from each of the daafles is organized in a notebook for
// easy identification of each file.


//this main procedure does all the work for making the cat notebook,
// obtaining the folder path, parsing the filenames in the list,
// and (dispatching) to write out the appropriate information to the notebook window
Proc BuildUSANSNotebook(matchStr)
	String matchStr="*"

	DoWindow/F CatWin
	If(V_Flag ==0)
		String nb = "CatWin"
		NewNotebook/F=1/N=$nb/W=(5.25,40.25,581.25,380.75) as "USANS Catalog"
		Notebook $nb defaultTab=36, statusWidth=238, pageMargins={72,72,72,72}
		Notebook $nb showRuler=1, rulerUnits=1, updating={1, 60}
		Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}
		Notebook $nb ruler=Normal; Notebook $nb  margins={0,0,544}
	Endif
	
	Variable err
	PathInfo bt5PathName
	if(v_flag==0)
		err = PickBT5Path()		//sets the local path to the data (bt5PathName)
		if(err)
			Abort "no path to data was selected, no catalog can be made - use PickPath button"
		Endif
	Endif
	
	String temp=""
	//clear old window contents, reset the path
	Notebook CatWin,selection={startOfFile,EndOfFile}
	Notebook CatWin,text="\r"
	Notebook CatWin,font="Geneva",fsize=14,textRGB=(0,0,0),fStyle=1,text = "FOLDER: "
	
	PathInfo bt5PathName
	temp = S_path+"\r\r"
	Notebook CatWin,fStyle=0,text = temp
	
	//get a list of all files in the folder
	String list,partialName,tempName
	list = IndexedFile(bt5PathName,-1,"????")	//get all files in folder
	Variable numitems,ii,ok
		
	//Igor 5 only - trim the list to the selected matching prefix (a one-liner)
	list = ListMatch(list, matchStr , ";" )
	
//	Igor 4 - need a loop, work backwards to preserve the index
//	ii=itemsinlist(list,";")
//	do
//		partialName = StringFromList(ii, list, ";")
//		if(stringmatch(partialName, matchStr )!=1)
//			list = RemoveFromList(partialName, list  ,";")
//		endif
//		ii -= 1
//	while(ii>=0)

	// remove the "fpx*" files, they are not real data
	String tmp = ListMatch(list,"fpx*",";")		
	list = RemoveFromList(tmp, list  ,";")
	print tmp
	
	// remove the ".DS_Store"
	list = RemoveFromList(".DS_Store",list,";")
	
	// remove .cor, .dsm reduced data files
	tmp = ListMatch(list,"*.cor",";")		
	list = RemoveFromList(tmp, list  ,";")
	tmp = ListMatch(list,"*.dsm",";")		
	list = RemoveFromList(tmp, list  ,";")
	tmp = ListMatch(list,"*.pxp",";")		
	list = RemoveFromList(tmp, list  ,";")
	
	
	//loop through all of the files in the list, reading header information 
	String str,fullName
	numitems = ItemsInList(list,";")
	ii=0
	if(numItems == 0)
		Notebook CatWin,textRGB=(65000,0,0),fStyle=1,fsize=14,text="No files found matching \""+matchStr+"\"\r\r"
//		Notebook CatWin,fStyle=0,text=fileStr+"\r"
		return		//exit from macro
	endif
	list = SortList(list  ,";",0)		//default sort
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")

		//prepend path to tempName for read routine 
		PathInfo bt5PathName
		FullName = S_path + partialName
		//go write the header information to the Notebook
		WriteUCatToNotebook(fullName,partialName)
		ii+=1
	while(ii<numitems)
End

//writes out the CATalog information to the notebook named CatWin (which must exist)
//fname is the full path for opening (and reading) information from the file
//which alreay was found to exist
// sname is the file;vers to be written out,
//avoiding the need to re-extract it from fname.
Function WriteUCatToNotebook(fname,sname)
	String fname,sname
		
	String fileStr,dateStr,timePt,titleStr,angRange,temp
	Variable refnum
	
	Open/R refNum as fname		//READ-ONLY.......if fname is "", a dialog will be presented
	if(refnum==0)
		return(1)		//user cancelled
	endif
	//read in the ASCII data line-by-line
	Variable numLinesLoaded = 0,firstchar
	Variable v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,ii,valuesRead
	String buffer ="",s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
	
	//parse the first line
	FReadLine refnum,buffer
	sscanf buffer, "%s%s%s%s%s%s%g%g%s%g%s",s1,s2,s3,s4,s5,s6,v1,v2,s7,v3,s8
	fileStr = s1
	dateStr = s2+" "+s3+" "+s4+" "+s5
	
	//v1 is the time per point (sec)
	timePt = num2istr(v1)+" sec"
	
	//skip the next line
	FReadLine refnum,buffer
	//the next line is the title, use it all
	FReadLine refnum,buffer
	titleStr = buffer
	
	//skip the next 3 lines
	For(ii=0;ii<3;ii+=1)
		FReadLine refnum,buffer
	EndFor
	
	//parse the angular range from the next line
	FReadLine refnum,buffer
	sscanf buffer,"%g%g%g%g",v1,v2,v3,v4
	angRange = num2str(v2)+" to "+num2str(v4)+" step "+num2str(v3)
	
	Close refNum		// Close the file, read-only, so don't need to move to EOF first
	
	Notebook CatWin,textRGB=(0,0,0),fStyle=1,fsize=10,text="FILE: "
	Notebook CatWin,fStyle=0,text=fileStr+"\r"
	
	Notebook CatWin,fStyle=1,text="TITLE: "
	Notebook CatWin,textRGB=(65000,0,0),fStyle=1,text=titleStr		//?? needs no CR here
	
	Notebook CatWin,textRGB=(0,0,0),fStyle=1,text="TIME/PT: "
	Notebook CatWin,fStyle=0,text=timePt+"\r"
	
	Notebook CatWin,fStyle=1,text="DATE: "
	Notebook CatWin,fStyle=0,text=dateStr+"\r"
	
	Notebook CatWin,fStyle=1,text="ANGLE RANGE: "
	Notebook CatWin,fStyle=0,text=angRange+"\r\r"

//	Notebook CatWin,textRGB=(50000,0,0),fStyle = 1,text=temp

End