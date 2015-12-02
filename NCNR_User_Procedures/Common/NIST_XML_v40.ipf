#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.00
#pragma IgorVersion=6.1


#if( Exists("XmlOpenFile") )

#include "cansasXML", version >= 1.10

// The function is called "LoadNISTXMLData" but is actually more generic
// and will load any canSAS XML v1 dataset
// Dec 2008 : 
//			 Caveats - Assumes Q in /A and I in /cm
// Takes outStr as output name. If outStr is specified then we must load only the first SASData in the firstSASEntry, 
// since anything else doesn't make sense. This is a bit of a hack to support NSORT.


function LoadNISTXMLData(filestr,outStr,doPlot,forceOverwrite)
	String filestr,outStr
	Variable doPlot,forceOverwrite
	
	
	Variable rr,gg,bb
	Variable dQv
//	NVAR/Z dQv = root:Packages:NIST:USANS_dQv		//let USANS_CalcWeights set the dQv value

		
//	Print "Trying to load canSAS XML format data" 
	Variable result = CS_XMLReader(filestr)
	
	String xmlReaderFolder = "root:Packages:CS_XMLreader:"
	
	if (result == 0)
			SetDataFolder xmlReaderFolder
						
			Variable i,j,numDataSets
			Variable np
			
			String w0,w1,w2,w3,w4,w5,basestr,fileName
			String xmlDataFolder,xmlDataSetFolder
			
			Variable numSASEntries
			
			if(!cmpStr(outStr,""))
				//no outStr defined
				numSASEntries = CountObjects(xmlReaderFolder,4)
			else
				numSASEntries = 1
			endif
			
			for (i = 0; i < numSASEntries; i+=1)
								
				xmlDataFolder = xmlReaderFolder+GetIndexedObjName(xmlReaderFolder,4,i)+":"
				if (!cmpstr(outstr,""))
					numDataSets = CountObjects(xmlDataFolder,4)
				else
					numDataSets = 0
				endif
				
				if (numDataSets > 0)
					//Multiple SASData sets in this SASEntry
					for (j = 0; j < numDataSets; j+=1)
						
						xmlDataSetFolder = xmlDataFolder+GetIndexedObjName(xmlDataFolder,4,j)+":"
					
						SetDataFolder xmlDataSetFolder	
						//			enforce a short enough name here to keep Igor objects < 31 chars
						// Multiple data sets so we need to use titles and run numbers for naming
						basestr = ShortFileNameString(CleanupName(getXMLDataSetTitle(xmlDataSetFolder,j,useFilename=0),0))
						baseStr = CleanupName(baseStr,0)		//in case the user added odd characters
						
						//String basestr = ParseFilePath(3, ParseFilePath(5,filestr,":",0,0),":",0,0)				
						fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
							
							
						//print "In NIST XML Loader"
						//print "fileStr: ",fileStr
						//print "basestr: ",basestr
						//print "fileName: ",fileName
						//remove the semicolon AND period from files from the VAX
//						print basestr
						w0 = basestr + "_q"
						w1 = basestr + "_i"
						w2 = basestr + "_s"
						w3 = basestr + "sq"
						w4 = basestr + "qb"
						w5 = basestr + "fs"
						
						if(DataFolderExists("root:"+baseStr))
							if(!forceOverwrite)
								DoAlert 1,"The data set " + basestr + " from file "+fileName+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
								if(V_flag==2)	//user selected No, don't load the data
									SetDataFolder root:
									if(DataFolderExists("root:Packages:NIST"))
										String/G root:Packages:NIST:gLastFileName = filename
									endif		//set the last file loaded to the one NOT loaded
									return	0	//quits the macro
								endif
							endif
							SetDataFolder $("root:"+baseStr)
						else
							NewDataFolder/S $("root:"+baseStr)
						endif
			
						Duplicate/O $(xmlDataSetFolder+"Qsas") $w0
						Duplicate/O $(xmlDataSetFolder+"Isas") $w1
						Duplicate/O $(xmlDataSetFolder+"Idev") $w2

						
						if (exists(xmlDataSetFolder+"Qdev"))
							Wave Qsas = $(xmlDataSetFolder+"Qsas")
							Wave Qdev = $(xmlDataSetFolder+"Qdev")
							
							Duplicate/O Qdev, $w3
						// make a resolution matrix for SANS data
							 np=numpnts($w0)
							Make/D/O/N=(np,4) $(baseStr+"_res")
							Wave reswave =  $(baseStr+"_res")
							
							reswave[][0] = Qdev[p]		//sigQ
							reswave[][3] = Qsas[p]	//Qvalues
							if(exists(xmlDataSetFolder+"Qmean"))
								Wave Qmean = $(xmlDataSetFolder+"Qmean")
								Duplicate/O Qmean,$w4
								reswave[][1] = Qmean[p]		//qBar
							else
								reswave[][1] = Qsas[p] // If there is no Qmean specified, use Q values
							endif
							if(exists(xmlDataSetFolder+"Shadowfactor"))
								Wave Shadowfactor = $(xmlDataSetFolder+"Shadowfactor")
								Duplicate/O Shadowfactor, $w5
								reswave[][2] = Shadowfactor[p]		//fShad
							else
								reswave[][2] = 1 // default shadowfactor to 1 if it doesn't exist
							endif
						elseif(exists(xmlDataSetFolder+"dQl"))
							//USANS Data
							Wave dQl = $(xmlDataSetFolder+"dQl")
							dQv = abs(dQl[0])
						
							USANS_CalcWeights(baseStr,dQv)
						else
							//No resolution data
						endif
							//get rid of the resolution waves that are in the matrix
					
							SetScale d,0,0,"1/A",$w0
							SetScale d,0,0,"1/cm",$w1
						
							
				
						//////
						if(DataFolderExists("root:Packages:NIST"))
							String/G root:Packages:NIST:gLastFileName = filename
						endif
					
						
						//plot if desired
						if(doPlot)
							// assign colors randomly
							rr = abs(trunc(enoise(65535)))
							gg = abs(trunc(enoise(65535)))
							bb = abs(trunc(enoise(65535)))
							
							// if target window is a graph, and user wants to append, do so
						   DoWindow/B Plot_Manager
							if(WinType("") == 1)
								DoAlert 1,"Do you want to append this data to the current graph?"
								if(V_Flag == 1)
									AppendToGraph $w1 vs $w0
									ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1) =(rr,gg,bb),tickUnit=1
									ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
									ModifyGraph tickUnit(left)=1
								else
								//new graph
									Display $w1 vs $w0
									ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
									ModifyGraph grid=1,mirror=2,standoff=0
									ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
									ModifyGraph tickUnit(left)=1
									Label left "I(q)"
									Label bottom "q (A\\S-1\\M)"
									Legend
								endif
							else
							// graph window was not target, make new one
								Display $w1 vs $w0
								ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
								ModifyGraph grid=1,mirror=2,standoff=0
								ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
								ModifyGraph tickUnit(left)=1
								Label left "I(q)"
								Label bottom "q (A\\S-1\\M)"
								Legend
							endif
						endif
					
					endfor
					
					
				else
					//No multiple SASData sets for this SASEntry
					SetDataFolder xmlDataFolder					
					
//					print xmlDataFolder
					
					//if outstr has been specified, we'll find ourselves here....
					//We should default to using the filename here to make life easier on people who have used the NIST reduction...
					if (!cmpstr(outstr,""))
						basestr = ShortFileNameString(CleanupName(getXMLDataSetTitle(xmlDataFolder,0,useFilename=1),0))
					else
						basestr = ShortFileNameString(CleanupName(outstr,0))
					endif
					
					//String basestr = ParseFilePath(3, ParseFilePath(5,filestr,":",0,0),":",0,0)				
					fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
																
					//print "In NIST XML Loader"
					//print "fileStr: ",fileStr
					//print "basestr: ",basestr
					//print "fileName: ",fileName
					w0 = basestr + "_q"
					w1 = basestr + "_i"
					w2 = basestr + "_s"
					
					if(DataFolderExists("root:"+baseStr))
						if(!forceOverwrite)
							DoAlert 1,"The data set " + basestr + " from file "+fileName+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
							if(V_flag==2)	//user selected No, don't load the data
								SetDataFolder root:
								if(DataFolderExists("root:Packages:NIST"))
									String/G root:Packages:NIST:gLastFileName = filename
								endif		//set the last file loaded to the one NOT loaded
								return	0	//quits the macro
							endif
						endif
						SetDataFolder $("root:"+baseStr)
					else
						NewDataFolder/S $("root:"+baseStr)
					endif
		
					Duplicate/O $(xmlDataFolder+"Qsas") $w0
					Duplicate/O $(xmlDataFolder+"Isas") $w1
					Duplicate/O $(xmlDataFolder+"Idev") $w2
	
	
						
					if (exists(xmlDataFolder+"Qdev"))
						Wave Qsas = $(xmlDataFolder+"Qsas")
						Wave Qdev = $(xmlDataFolder+"Qdev")
					
					// make a resolution matrix for SANS data
						np=numpnts($w0)
						Make/D/O/N=(np,4) $(baseStr+"_res")
						Wave reswave =  $(baseStr+"_res")
						
						reswave[][0] = Qdev[p]		//sigQ
						reswave[][3] = Qsas[p]	//Qvalues
						if(exists(xmlDataFolder+"Qmean"))
							Wave Qmean = $(xmlDataFolder+"Qmean")
							reswave[][1] = Qmean[p]		//qBar
						else
							reswave[][1] = Qsas[p] // If there is no Qmean specified, use Q values
						endif
						if(exists(xmlDataFolder+"Shadowfactor"))
							Wave Shadowfactor = $(xmlDataFolder+"Shadowfactor")
							reswave[][2] = Shadowfactor[p]		//fShad
						else
								reswave[][2] = 1 // default shadowfactor to 1 if it doesn't exist
						endif
					elseif(exists(xmlDataFolder+"dQl"))
						//USANS Data
						Wave dQl = $(xmlDataFolder+"dQl")
						dQv = abs(dQl[0])		//make it positive again
					
						USANS_CalcWeights(baseStr,dQv)
					else
						//No resolution data
					endif
						//get rid of the resolution waves that are in the matrix
				
						SetScale d,0,0,"1/A",$w0
						SetScale d,0,0,"1/cm",$w1
					
						
			
					//////
					if(DataFolderExists("root:Packages:NIST"))
						String/G root:Packages:NIST:gLastFileName = filename
					endif
				
					
					//plot if desired
					if(doPlot)
						// assign colors randomly
						rr = abs(trunc(enoise(65535)))
						gg = abs(trunc(enoise(65535)))
						bb = abs(trunc(enoise(65535)))
						
						// if target window is a graph, and user wants to append, do so
					   DoWindow/B Plot_Manager
						if(WinType("") == 1)
							DoAlert 1,"Do you want to append this data to the current graph?"
							if(V_Flag == 1)
								AppendToGraph $w1 vs $w0
								ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1) =(rr,gg,bb),tickUnit=1
								ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
								ModifyGraph tickUnit(left)=1
							else
							//new graph
								Display $w1 vs $w0
								ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
								ModifyGraph grid=1,mirror=2,standoff=0
								ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
								ModifyGraph tickUnit(left)=1
								Label left "I(q)"
								Label bottom "q (A\\S-1\\M)"
								Legend
							endif
						else
						// graph window was not target, make new one
							Display $w1 vs $w0
							ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
							ModifyGraph grid=1,mirror=2,standoff=0
							ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
							ModifyGraph tickUnit(left)=1
							Label left "I(q)"
							Label bottom "q (A\\S-1\\M)"
							Legend
						endif
					endif
				
				endif
			endfor
	endif

	//go back to the root folder and clean up before leaving
	SetDataFolder root:
	//KillDataFolder xmlReaderFolder
	

end


function/S GetXMLDataSetTitle(xmlDF,dsNum,[useFilename])
	String xmlDF
	Variable dsNum
	Variable useFilename

	SVAR title = root:Packages:NIST:gXMLLoader_Title

	String mdstring = xmlDF+"metadata"
	String filename

	Wave/T meta = $mdstring

	//Get filename to use if useFilename is specified or as a fall back if title is missing.
	FindValue/TEXT="xmlFile"/TXOP=4/Z meta
	filename = ParseFilePath(0,TrimWS(meta[V_Value][1]),":",1,0)
	
	if (useFilename)
		return filename
	endif
	
	//Check for value when there are multiple datasets
	//Note that the use of FindValue here assumes that the tag is in column 0 so that V_Value 
	//represents the row number
	//This will almost certainly break if your title was "Title" or "Run"
	FindValue/TEXT="Title"/TXOP=4/Z meta
	if (V_Value >= 0)
	//This should always be true as title is required in canSAS XML format
		title = TrimWS(meta[V_Value][1])
	else
		title = filename
	endif	
	 //Check for Run value
	 //If you get a run value, put it at the start of the string so it isn't lost if there is truncation
	 //One hopes that the run number will be unique...
	 FindValue/TEXT="Run_"+num2str(dsNum)/TXOP=4/Z meta
	if (V_Value >= 0)
		title = TrimWS(meta[V_Value][1])+" "+title
		//print title
	else
		FindValue/TEXT="Run"/TXOP=4/Z meta
		if (V_Value >= 0)
			title = TrimWS(meta[V_Value][1])+" "+title
			//print title
		endif
	endif
	
	return title
end


//Function to write NIST canSAS XML files
//Minimalist XML file - AJJ Dec 2008
Function WriteNISTXML(fileName, NISTfile)
	String fileName
	Struct NISTXMLfile &NISTfile

	variable fileID
	
	//create the sasXML file with SASroot
	//no namespace, no prefix
	fileID = xmlcreatefile(fileName,"SASroot","cansas1d/1.0","")

	//create a version attribute for the root element
	xmlsetAttr(fileID,"/SASroot","","version","1.0")
	xmlsetAttr(fileID,"/SASroot","","xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
	xmlsetAttr(fileID,"/SASroot","","xsi:schemaLocation","cansas1d/1.0 http://svn.smallangles.net/svn/canSAS/1dwg/trunk/cansas1d.xsd")


	//create the SASentry node
	xmladdnode(fileID,"/SASroot","","SASentry","",1)
		
	//create the Title node
	xmladdnode(fileID,"/SASroot/SASentry","","Title",NISTfile.Title,1)

	//create the Run node
	xmladdnode(fileID,"/SASroot/SASentry","","Run",NISTfile.Run,1)
	
	//create the SASdata node
	xmladdnode(fileID,"/SASroot/SASentry","","SASdata","",1)

	variable ii
	
	if (WaveExists(NISTfile.dQl) == 1)
		for(ii=0 ; ii<numpnts(NISTfile.Q) ; ii+=1)
			xmladdnode(fileID,"/SASroot/SASentry/SASdata","","Idata","",1)
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Q",num2str(NISTfile.Q[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Q","","unit",NISTfile.unitsQ)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","I",num2str(NISTfile.I[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/I","","unit",NISTfile.unitsI)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Idev",num2str(NISTfile.Idev[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Idev","","unit",NISTfile.unitsIdev)	
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","dQl",num2str(NISTfile.dQl[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/dQl","","unit",NISTfile.unitsdQl)		
		endfor
	else
		for(ii=0 ; ii<numpnts(NISTfile.Q) ; ii+=1)
			xmladdnode(fileID,"/SASroot/SASentry/SASdata","","Idata","",1)
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Q",num2str(NISTfile.Q[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Q","","unit",NISTfile.unitsQ)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","I",num2str(NISTfile.I[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/I","","unit",NISTfile.unitsI)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Idev",num2str(NISTfile.Idev[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Idev","","unit",NISTfile.unitsIdev)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Qdev",num2str(NISTfile.Qdev[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Qdev","","unit",NISTfile.unitsQdev)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Qmean",num2str(NISTfile.Qmean[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Qmean","","unit",NISTfile.unitsQmean)
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Shadowfactor",num2str(NISTfile.shadowfactor[ii]),1)
		endfor
	endif

	//SASsample node
	xmladdnode(fileID,"/SASroot/SASentry","","SASsample","",1)
	xmladdnode(fileID,"/SASroot/SASentry/SASsample","","ID",NISTfile.sample_ID,1)

	//SASInstrument node
	xmladdnode(fileID,"/SASroot/SASentry","","SASinstrument","",1)
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument","","name",NISTfile.nameSASinstrument,1)
	
	//SASsource
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument","","SASsource","",1)
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument/SASsource","","radiation",NISTfile.radiation,1)

	//SAScollimation
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument","","SAScollimation","",1)

	//SASdetector
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument","","SASdetector","",1)
	xmladdnode(fileID,"/SASroot/SASentry/SASinstrument/SASdetector","","name",NISTfile.detector_name,1)


	//SASprocess
	xmladdnode(fileID,"/SASroot/SASentry","","SASprocess","",1)
	xmlsetAttr(fileID,"/SASroot/SASentry/SASprocess","","name",NISTfile.nameSASprocess)	
	xmladdnode(fileID,"/SASroot/SASentry/SASprocess","","SASprocessnote",NISTfile.SASprocessnote,1)
	
	//SASnote
	xmladdnode(fileID,"/SASroot/SASentry","","SASnote",NISTfile.SASnote,1)
	
	xmlsavefile(fileID)
	xmlclosefile(fileID,0)
	
end

//
// !!! nf.Sample_ID is not set correctly here, since it's not read in from the NIST 6-col data file
// and SASprocessnote does not get set either!
//
Function ConvertNISTtoNISTXML(fileStr)
	String fileStr
	
	Struct NISTXMLfile nf
	
	Variable rr,gg,bb,refnum,dQv
	SetDataFolder root:	
	
	if (cmpStr(fileStr,"") == 0)
		//No filename given, open dialog
		Open/D/R  refnum
		if (cmpstr(S_filename,"") == 0)
			return 0
		else
			fileStr = S_filename
		endif
	endif

	//Load the waves, using default waveX names
	//if no path or file is specified for LoadWave, the default Mac open dialog will appear
	LoadWave/G/D/A/Q fileStr
	String fileNamePath = S_Path+S_fileName
	String basestr = CleanupName(ParseFilePath(3,ParseFilePath(5,fileNamePath,":",0,0),":",0,0),0)
//	String baseStr = CleanupName(S_fileName,0)
//		print "basestr :"+basestr
	String fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
//		print "filename :"+filename
	Variable numCols = V_flag
	String outfileName = S_Path+basestr+".xml"

	
	if(numCols==3)		//simple 3-column data with no resolution information
		
		Wave nf.Q = $(StringFromList(0, S_waveNames ,";" ))
		Wave nf.I = $(StringFromList(1, S_waveNames ,";" ))
		Wave nf.Idev = $(StringFromList(2, S_waveNames ,";" ))
				
		//Set units
		nf.unitsQ = "1/A"
		nf.unitsI = "1/cm"
		nf.unitsIdev = "1/cm"
				
	endif		//3-col data
	
	if(numCols == 6)		//6-column SANS or USANS data that has resolution information
		
		// put the names of the (default named) loaded waves into local names
		Wave nf.Q = $(StringFromList(0, S_waveNames ,";" ))
		Wave nf.I  = $(StringFromList(1, S_waveNames ,";" ))
		Wave nf.Idev  = $(StringFromList(2, S_waveNames ,";" ))

		//Set units
		nf.unitsQ = "1/A"
		nf.unitsI = "1/cm"
		nf.unitsIdev = "1/cm"

		WAVE resTest = $(StringFromList(3, S_waveNames ,";" ))

		// need to switch based on SANS/USANS
		if (isSANSResolution(resTest[0]))		//checks to see if the first point of the wave is <0]
			Wave nf.Qdev  = $(StringFromList(3, S_waveNames ,";" ))
			Wave nf.Qmean  = $(StringFromList(4, S_waveNames ,";" ))
			Wave nf.Shadowfactor  = $(StringFromList(5, S_waveNames ,";" ))
			
			//Set units
			nf.unitsQdev = "1/A"
			nf.unitsQmean = "1/A"
		else
			Wave nf.dQl = $(StringFromList(3, S_waveNames ,";" ))
			nf.dQl = abs(nf.dQl)
			
			//Set units
			nf.unitsdQl = "1/A"
			
		endif
	
	endif	//6-col data

	//Get file header
	setmetadataFromASCHeader(fileStr,nf)

	//Set required metadata that we can't get from these files
	nf.detector_name = "Ordela 128x128"
	nf.nameSASinstrument = "NIST NG3/NG7 SANS"
	nf.radiation = "neutron"
	nf.sample_ID = nf.title
	nf.nameSASProcess = "NIST Data Converter"
	nf.sasnote = "Data converted from previous NIST format. SASProcessnote contains header from original text file."

	writeNISTXML(outfileName, nf)

	//Tidy up AFTER we're all done, since STRUCT points to wave0,wave1, etc.
	Variable i = 0
	do
		WAVE/Z wv= $(StringFromList(i,S_waveNames,";"))
		if( WaveExists(wv) == 0 )
			break
		endif
		KillWaves wv
		i += 1
	while (1)	// exit is via break statement

end

function SetMetadataFromASCHeader(fileStr,NISTfile)
	String fileStr
	Struct NISTXMLfile &NISTfile

	String hdr="",buffer=""
	Variable lineNum = 0, fileref
	Variable num
	
	Open/R fileref as fileStr
	do
		FReadLine fileref, buffer
		if (stringmatch(buffer,"*The 6 columns are*") == 1)
			break
		endif
		buffer = RemoveEnding(buffer)
//		print buffer
		//Get run value
		if (stringmatch(buffer,"*file:*") == 1)
			NISTfile.run = TrimWS(StringFromList(0,StringFromList(1, buffer, ":"),"C"))
		elseif (stringmatch(buffer,"combined file*") == 1)
			NISTfile.run = "Combined Data"
		endif
		
		//Get title value
		if (stringmatch(buffer,"*FIRST File LABEL:*") == 1)
			NISTfile.title = TrimWS(StringFromList(1,buffer, ":"))
		endif
		if(stringmatch(buffer,"*LABEL:*") == 1)
			NISTfile.title = TrimWS(StringFromList(1,buffer, ":"))
		endif
		if(stringmatch(buffer,"NSORT*") == 1)
			NISTfile.title = buffer
		endif
		
		hdr += buffer+"\n"
	while(strlen(buffer) > 0)
	
	if (strlen(NISTfile.title) == 0)
		NISTfile.title = CleanupName(ParseFilePath(3,ParseFilePath(5,fileStr,":",0,0),":",0,0),0)
	endif
	if (strlen(NISTfile.run) == 0)
		NISTfile.run = "Unknown"
	endif
	
	NISTfile.sasprocessnote = RemoveEnding(hdr)
	
end

//for writing out data (q-i-s) from the "type" folder, and including reduction information
//if fullpath is a complete HD path:filename, no dialog will be presented
//if fullpath is just a filename, the save dialog will be presented
//if dialog = 1, a dialog will always be presented
//
// root:myGlobals:Protocols:gProtoStr is the name of the currently active protocol
//
//AJJ Nov 2009 : This version of the function currently only works for Circular, Sector and Rectangular averages
//i.e. anything that produces I vs Q. Need to add ability to handle Annular (I vs theta) but that requires namespace addition to XML format
//and handling on load.
Function WriteXMLWaves_W_Protocol(type,fullpath,dialog)
	String type,fullpath
	Variable dialog		//=1 will present dialog for name
	
	Struct NISTXMLfile nf
	
	String destStr=""
	destStr = "root:Packages:NIST:"+type
	
	Variable refNum
//	String fname,ave="C",hdrStr1="",hdrStr2=""
//	Variable step=1
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE intw=$(destStr + ":integersRead")
	WAVE rw=$(destStr + ":realsRead")
	WAVE/T textw=$(destStr + ":textRead")
	WAVE qvals =$(destStr + ":qval")
	WAVE inten=$(destStr + ":aveint")
	WAVE sig=$(destStr + ":sigave")
 	WAVE qbar = $(destStr + ":QBar")
  	WAVE sigmaq = $(destStr + ":SigmaQ")
 	WAVE fsubs = $(destStr + ":fSubS")


	SVAR gProtoStr = root:myGlobals:Protocols:gProtoStr
	Wave/T proto=$("root:myGlobals:Protocols:"+gProtoStr)

	
	//check each wave
	If(!(WaveExists(intw)))
		Abort "intw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(rw)))
		Abort "rw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(textw)))
		Abort "textw DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(qbar)))
		Abort "qbar DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(sigmaq)))
		Abort "sigmaq DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(fsubs)))
		Abort "fsubs DNExist BinaryWrite_W_Protocol()"
	Endif
	If(!(WaveExists(proto)))
		Abort "current protocol wave DNExist BinaryWrite_W_Protocol()"
	Endif
	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	//actually open the file here
	//Open refNum as fullpath
	
	//Data
	Wave nf.Q = qvals
	nf.unitsQ = "1/A"
	Wave nf.I = inten
	nf.unitsI = "1/cm"
	Wave nf.Idev = sig
	nf.unitsIdev = "1/cm"
	Wave nf.Qdev = sigmaq
	nf.unitsQdev = "1/A"
	Wave nf.Qmean = qbar
	nf.unitsQmean = "1/A"
	Wave nf.Shadowfactor = fSubS
	nf.unitsShadowfactor = "none"
	
	
	//write out the standard header information
	//fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
	
	//AJJ to fix with sensible values
	nf.run = "Test"
	String acct = textw[3]
	nf.nameSASinstrument = acct[1,3]
	nf.SASnote = ""
	//
	nf.sample_ID = textw[6]
	nf.title = textw[6]
	nf.radiation = "neutron"
	nf.wavelength = rw[26]
	nf.unitswavelength = "A"
	nf.offset_angle = rw[19]
	nf.unitsoffset_angle = "cm"
	nf.SDD = rw[18]
	nf.unitsSDD = "m"
	nf.sample_transmission = rw[4]
	nf.sample_thickness = rw[5]
	nf.unitssample_thickness = "mm"
	
	nf.beamcenter_X = rw[16]  
	nf.beamcenter_Y = rw[17]
	nf.unitsbeamcenter_X = "pixels"
	nf.unitsbeamcenter_Y = "pixels"
	nf.source_aperture = rw[23]
	nf.typesource_aperture = "pinhole"
	nf.unitssource_aperture = "mm"
	nf.sample_aperture = rw[24]
	nf.typesample_aperture = "pinhole"
	nf.unitssample_aperture = "mm"
	//nf.collimation_length = total length - rw[25]
	nf.wavelength_spread = rw[27]
	nf.unitswavelength_spread = "percent"
	//Do something with beamstop (rw[21])
	nf.detector_name = textW[9]
//	fprintf refnum,"MON CNT   LAMBDA   DET ANG   DET DIST   TRANS   THICK   AVE   STEP\r\n"
//	fprintf refnum,hdrStr1

//	fprintf refnum,"BCENT(X,Y)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)   DET_TYP \r\n"
//	fprintf refnum,hdrStr2

	//insert protocol information here
	//-1 list of sample files
	//0 - bkg
	//1 - emp
	//2 - div
	//3 - mask
	//4 - abs params c2-c5
	//5 - average params
	nf.SASprocessnote =  "SAM: "+samFiles+"\n"
	nf.SASprocessnote += "BGD: "+proto[0]+"\n"
	nf.SASprocessnote += "EMP: "+Proto[1]+"\n"
	nf.SASprocessnote += "DIV: "+Proto[2]+"\n"
	nf.SASprocessnote += "MASK: "+Proto[3]+"\n"
	nf.SASprocessnote += "ABS Parameters (3-6): "+Proto[4]+"\n"
	nf.SASprocessnote += "Average Choices: "+Proto[5]+"\n"
	
	nf.nameSASProcess = "NIST IGOR"

	//Close refnum
	
	writeNISTXML(fullpath, nf)
	
	SetDataFolder root:		//(redundant)
	
	//write confirmation of write operation to history area
	Print "Averaged XML File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z tempShortProto
	Return(0)
End

Function WriteNSORTedXMLFile(qw,iw,sw,firstFileName,secondFileName,thirdFileName,normTo,norm12,norm23,[res])
	Wave qw,iw,sw,res
	String firstFileName,secondFileName,thirdFileName,normTo
	Variable norm12,norm23

	Variable err=0,refNum,numCols,dialog=1
	String fullPath="",formatStr="",str2
	//check each wave - else REALLY FATAL error when writing file
	If(!(WaveExists(qw)))
		err = 1
		return err
	Endif
	If(!(WaveExists(iw)))
		err = 1
		return err
	Endif
	If(!(WaveExists(sw)))
		err = 1
		return err
	Endif
	
	if(WaveExists(res))
		numCols = 6
	else
		numCols = 3
	endif
	
// 05SEP05 SRK -- added to automatically combine files from a table - see the end of NSORT.ipf for details
// - use the flag set in DoCombineFiles() to decide if the table entries should be used
//Ê Êroot:myGlobals:CombineTable:useTable= (1) (0)
//if(exists("root:myGlobals:CombineTable:SaveName"))
	NVAR/Z useTable = root:myGlobals:CombineTable:useTable
	if(NVAR_Exists(useTable) && useTable==1)
		SVAR str=root:myGlobals:CombineTable:SaveNameStr	//messy, but pass in as a global
		fullPath = str
//		str2 = "Is the file name "+str+" correct?"
//		DoAlert 1,str2
//		if(V_flag==1)
			dialog=0		//bypass the dialog if the name is good (assumed, since DoAlert is bypassed)
//		endif
	endif

	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save XML data as",fname="",suffix=".ABSx")		//won't actually open the file
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif

	Struct NISTxmlfile nf
	
	//Data
	Wave nf.Q = qw
	nf.unitsQ = "1/A"
	Wave nf.I = iw
	nf.unitsI = "1/cm"
	Wave nf.Idev = sw
	nf.unitsIdev = "1/cm"

	//write out the standard header information
	//fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
	
	//AJJ to fix with sensible values
	nf.run = ""
	nf.nameSASinstrument = "NIST IGOR"
	nf.SASnote = ""
	//
	nf.sample_ID = ParseFilePath(3, fullPath, ":", 0, 0)
	nf.title = ParseFilePath(3, fullPath, ":", 0, 0)
	nf.radiation = "neutron"
	//Do something with beamstop (rw[21])
	nf.detector_name = "NSORTed Data"	
	nf.nameSASProcess = "NIST IGOR"
	
	nf.sasProcessNote = "COMBINED FILE CREATED: "+date()+"\n"
	nf.sasProcessNote += "NSORT-ed : " +firstFileName+";"+secondFileName+";"+thirdFileName+"\n"
	nf.sasProcessNote += "normalized to  "+normTo+"\n"
	fprintf refNum, "multiplicative factor 1-2 = "+num2str(norm12)+" multiplicative factor 2-3 = "+num2str(norm23)+"\n"

	if (numCols == 3)
		writeNISTXML(fullpath,nf)
	elseif (numCols == 6)
		Make/O/N=(dimsize(res,0)) sigq = res[p][0]
		Make/O/N=(dimsize(res,0)) qbar = res[p][1]
		Make/O/N=(dimsize(res,0)) fs = res[p][2]
	
		Wave nf.Qdev = sigQ
		nf.unitsQdev = "1/A"
		Wave nf.Qmean = qbar
		nf.unitsQmean = "1/A"
		Wave nf.Shadowfactor = fs
		nf.unitsShadowfactor = "none"
	
		writeNISTXML(fullpath,nf)
	
		Killwaves/Z sigq,qbar,fs
	endif

	Return err
End



/// See WriteModelData_v40.ipf for 6 column equivalent
//
// will abort if resolution wave is missing
// switches for USANS data if the proper global is found, otheriwse treats as SANS data
//
Function ReWrite1DXMLData(folderStr)
	String folderStr

	String fullpath=""
	Variable dialog=1
	String dataSetFolderParent,basestr,fullBase
	
	Struct NISTXMLfile nf

	//Abuse ParseFilePath to get path without folder name
	dataSetFolderParent = ParseFilePath(1,folderStr,":",1,0)
	//Abuse ParseFilePath to get basestr
	basestr = ParseFilePath(0,folderStr,":",1,0)

	SetDataFolder $(dataSetFolderParent+basestr)
	WAVE/Z qw = $(baseStr+"_q")
	WAVE/Z iw = $(baseStr+"_i")
	WAVE/Z sw = $(baseStr+"_s")
	WAVE/Z resw = $(baseStr+"_res")
	
	if(WaveExists(qw) == 0)
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		Abort "s is missing"
	endif
	if(WaveExists(resw) == 0)
		Abort "Resolution information is missing."
	endif
	
	
	// if (USANS)
	// else (SANS is assumed)
	// endif
	NVAR/Z dQv = USANS_dQv		// in current DF
	if (NVAR_Exists(dQv))
		//USANS data, proceed
		//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
		Duplicate/O qw,dumWave
		dumWave = dQv			//written out as a positive value, since the column is identified by its label, dQl
		
		//Data
		Wave nf.Q = qw
		nf.unitsQ = "1/A"
		Wave nf.I = iw
		nf.unitsI = "1/cm"
		Wave nf.Idev = sw
		nf.unitsIdev = "1/cm"
		// for slit-smeared USANS, set only a 4th column to  -dQv
		Wave nf.dQl = dumWave
		nf.unitsdQl= "1/A"
	
		//AJJ to fix with sensible values
		nf.run = ""
		nf.nameSASinstrument = "NIST IGOR Procedures"
		nf.SASnote = ""
		//
		nf.sample_ID = baseStr
		nf.title = baseStr
		nf.radiation = "neutron"
		//Do something with beamstop (rw[21])
		nf.detector_name = "Re-written USANS data"
	
		nf.SASprocessnote =  "Modified data written from folder "+baseStr+" on "+(date()+" "+time())
		
		nf.nameSASProcess = "NIST IGOR"
		
	else
		//assume SANS data
		Duplicate/O qw qbar,sigQ,fs
		sigq = resw[p][0]
		qbar = resw[p][1]
		fs = resw[p][2]
	
			
		//Data
		Wave nf.Q = qw
		nf.unitsQ = "1/A"
		Wave nf.I = iw
		nf.unitsI = "1/cm"
		Wave nf.Idev = sw
		nf.unitsIdev = "1/cm"
		Wave nf.Qdev = sigQ
		nf.unitsQdev = "1/A"
		Wave nf.Qmean = qbar
		nf.unitsQmean = "1/A"
		Wave nf.Shadowfactor = fs
		nf.unitsShadowfactor = "none"
		
		
		//write out the standard header information
		//fprintf refnum,"FILE: %s\t\t CREATED: %s\r\n",textw[0],textw[1]
		
		//AJJ to fix with sensible values
		nf.run = ""
		nf.nameSASinstrument = "NIST IGOR Procedures"
		nf.SASnote = ""
		//
		nf.sample_ID = baseStr
		nf.title = baseStr
		nf.radiation = "neutron"
		//Do something with beamstop (rw[21])
		nf.detector_name = "Re-written data"
	
		nf.SASprocessnote =  "Modified data written from folder "+baseStr+" on "+(date()+" "+time())
		
		nf.nameSASProcess = "NIST IGOR"

	endif

	
	if(dialog)
		PathInfo/S catPathName
		fullPath = DoSaveFileDialog("Save data as",fname=baseStr+".xml")
		If(cmpstr(fullPath,"")==0)
			//user cancel, don't write out a file
			Close/A
			Abort "no data file was written"
		Endif
		//Print "dialog fullpath = ",fullpath
	Endif
	
	
	writeNISTXML(fullpath,nf)
	//write confirmation of write operation to history area
	Print "XML File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z tempShortProto
	
	SetDataFolder root:

	Return(0)
End




#else	// if( Exists("XmlOpenFile") )
	// No XMLutils XOP: provide dummy function so that IgorPro can compile dependent support code
//	FUNCTION LoadNISTXMLData(fileName,doPlot)
//	    String fileName
//	    Variable doPlot
//	    Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
//	    RETURN(-6)
//	END


	Function LoadNISTXMLData(filestr,outStr,doPlot,forceOverwrite)
		String filestr,outStr
		Variable doPlot,forceOverwrite
		
	   Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end		

	Function/S GetXMLDataSetTitle(xmlDF,dsNum,[useFilename])
		String xmlDF
		Variable dsNum
		Variable useFilename
		
	   Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return("")
	end		

	Function WriteNISTXML(fileName, NISTfile)
		String fileName, NISTfile
		Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
	 	RETURN(-6)
	End
	
	Function WriteXMLWaves_W_Protocol(type,fullpath,dialog)
		String type,fullpath
		Variable dialog		//=1 will present dialog for name
	
	    Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end
	
	Function WriteNSORTedXMLFile(q3,i3,sig3,firstFileName,secondFileName,thirdFileName,normTo,norm12,norm23,[res])
		Wave q3,i3,sig3,res
		String firstFileName,secondFileName,thirdFileName,normTo
		Variable norm12,norm23

		 Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	End

	Function ReWrite1DXMLData(folderStr)
		String folderStr
	
		 Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end
	
	Function SetMetadataFromASCHeader(fileStr,NISTfile)
		String fileStr
		Struct NISTXMLfile &NISTfile
			 
		Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end
		
	Function ConvertNISTtoNISTXML(fileStr)
		String fileStr
		
		Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
		return(-6)
	end	
	
	
#endif

//AJJ 12/5/08

//Define struct for file contents
Structure NISTXMLfile
//	string filename
	string Run
	string title

	//<SASdata>
	Wave Q,I,Idev,Qdev,Qmean,Shadowfactor,dQl
	string unitsQ,unitsI,unitsIdev,unitsQdev,unitsQmean,unitsShadowfactor,unitsdQl

//	Variable flux_monitor
//	string Q_resolution

	//<SASsample>
	string sample_ID
	variable sample_thickness
	string unitssample_thickness
	variable sample_transmission

	//SASinstrument
	string nameSASinstrument
	// SASinstrument/SASsource
	string radiation
//	string beam_shape
	variable wavelength
	string unitswavelength
	variable wavelength_spread
	string unitswavelength_spread
 
	//<SAScollimation>
//	variable collimation_length
//	string unitscollimation_length
	variable source_aperture
	string unitssource_aperture
	string typesource_aperture
	variable sample_aperture
	string unitssample_aperture
	string typesample_aperture

	//SASdetector         <SASdetector>
	string detector_name
	variable offset_angle
	string unitsoffset_angle
	variable  SDD
	string unitsSDD
	variable beamcenter_X
	string unitsbeamcenter_X
	variable beamcenter_Y
	string unitsbeamcenter_Y
//	variable pixel_sizeX
//	string unitspixel_sizeX
//	variable pixel_sizeY
//	string unitspixel_sizeY
//	string detectortype 

	// <SASprocess name="NCNR-IGOR">
	string nameSASprocess
	string SASprocessnote
//	string SASprocessdate
//	string average_type
//	string SAM_file
//	string BKD_file
//	string EMP_file
//	string DIV_file
//	string MASK_file
//	string ABS_parameters
//	variable TSTAND
//	variable DSTAND
//	string unitsDSTAND
//	variable IZERO
//	variable XSECT
//	string unitsXSECT
	string SASnote
Endstructure

	// if( Exists("XmlOpenFile") 
//Needed to test whether file is XML. The load routine will then either give an error if XMLutils is not present or load the file if it is.
Function isXML(filestr)
	String filestr
	
	String line
	Variable fileref
	
	Open/R/Z fileref as filestr
	FReadLine fileref,  line
	Close fileref
	
	//Hopefully this will distinguish between other formats and the XML
	//Previous string match would match normal files that have a .xml file as their progenitor...
	return GrepString(line, "(?iU).*\<.*xml.*")	

end