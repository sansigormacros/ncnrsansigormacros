#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.00
#pragma IgorVersion=6.0


#if( Exists("XmlOpenFile") )

#include "cansasXML_v11", version >= 1.10

// The function is called "LoadNISTXMLData" but is actually more generic
// and will load any canSAS XML v1 dataset
// Dec 2008 : 
//			 Caveats - Assumes Q in /A and I in /cm
function LoadNISTXMLData(filestr,doPlot)
	String filestr
	Variable doPlot
	
	
	Variable rr,gg,bb
	NVAR dQv = root:Packages:NIST:USANS_dQv

		
	Print "Trying to load canSAS XML format data" 
	Variable result = CS_XMLReader(filestr)
	
	String xmlReaderFolder = "root:Packages:CS_XMLreader:"
	
	if (result == 0)
			SetDataFolder xmlReaderFolder
						
			Variable i,j,numDataSets
			Variable np
			
			String w0,w1,w2,basestr,fileName
			String xmlDataFolder,xmlDataSetFolder
			
			
			
			for (i = 0; i < CountObjects(xmlReaderFolder,4); i+=1)
								
				xmlDataFolder = xmlReaderFolder+GetIndexedObjName(xmlReaderFolder,4,i)+":"
				numDataSets = CountObjects(xmlDataFolder,4)
				if (numDataSets > 0)
					//Multiple SASData sets in this SASEntry
					for (j = 0; j < numDataSets; j+=1)
						
						xmlDataSetFolder = xmlDataFolder+GetIndexedObjName(xmlDataFolder,4,j)+":"
						
						SetDataFolder xmlDataSetFolder
					
						basestr = CleanupName(getXMLDataSetTitle(xmlDataSetFolder,j),0)
						//String basestr = ParseFilePath(3, ParseFilePath(5,filestr,":",0,0),":",0,0)				
						fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
							
						//print "In NIST XML Loader"
						//print "fileStr: ",fileStr
						//print "basestr: ",basestr
						//print "fileName: ",fileName
						//remove the semicolon AND period from files from the VAX
						w0 = basestr + "_q"
						w1 = basestr + "_i"
						w2 = basestr + "_s"
						
						if(DataFolderExists("root:"+baseStr))
								DoAlert 1,"The data set " + basestr + " from file "+fileName+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
								if(V_flag==2)	//user selected No, don't load the data
									SetDataFolder root:
									if(DataFolderExists("root:Packages:NIST"))
										String/G root:Packages:NIST:gLastFileName = filename
									endif		//set the last file loaded to the one NOT loaded
									return	0	//quits the macro
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
						
						// make a resolution matrix for SANS data
							 np=numpnts($w0)
							Make/D/O/N=(np,4) $(baseStr+"_res")
							Wave reswave =  $(baseStr+"_res")
							
							reswave[][0] = Qdev[p]		//sigQ
							reswave[][3] = Qsas[p]	//Qvalues
							if(exists(xmlDataSetFolder+"Qmean"))
								Wave Qmean = $(xmlDataSetFolder+"Qmean")
								reswave[][1] = Qmean[p]		//qBar
							endif
							if(exists(xmlDataSetFolder+"Shadowfactor"))
								Wave Shadowfactor = $(xmlDataSetFolder+"Shadowfactor")
								reswave[][2] = Shadowfactor[p]		//fShad
							endif
						elseif(exists(xmlDataSetFolder+"dQl"))
							//USAS Data
							Wave dQl = $(xmlDataSetFolder+"dQl")
							dQv = dQl[0]
						
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
									Legend
								endif
							else
							// graph window was not target, make new one
								Display $w1 vs $w0
								ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
								ModifyGraph grid=1,mirror=2,standoff=0
								ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
								ModifyGraph tickUnit(left)=1
								Legend
							endif
						endif
					
					endfor
					
					
				else
					//No multiple SASData sets for this SASEntry
					SetDataFolder xmlDataFolder
					
					basestr = CleanupName(getXMLDataSetTitle(xmlDataFolder,0),0)
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
							DoAlert 1,"The data set " + basestr + " from file "+fileName+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
							if(V_flag==2)	//user selected No, don't load the data
								SetDataFolder root:
								if(DataFolderExists("root:Packages:NIST"))
									String/G root:Packages:NIST:gLastFileName = filename
								endif		//set the last file loaded to the one NOT loaded
								return	0	//quits the macro
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
						endif
						if(exists(xmlDataFolder+"Shadowfactor"))
							Wave Shadowfactor = $(xmlDataFolder+"Shadowfactor")
							reswave[][2] = Shadowfactor[p]		//fShad
						endif
					elseif(exists(xmlDataFolder+"dQl"))
						//USAS Data
						Wave dQl = $(xmlDataFolder+"dQl")
						dQv = dQl[0]
					
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
								Legend
							endif
						else
						// graph window was not target, make new one
							Display $w1 vs $w0
							ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
							ModifyGraph grid=1,mirror=2,standoff=0
							ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
							ModifyGraph tickUnit(left)=1
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


function/S getXMLDataSetTitle(xmlDF,dsNum)
	String xmlDF
	Variable dsNum

	SVAR title = root:Packages:NIST:gXMLLoader_Title


	String mdstring = xmlDF+"metadata"

	Wave/T meta = $mdstring
	//Check for value when there are multiple datasets
	FindValue/TEXT="Title"/TXOP=4/Z meta
	title = TrimWS(meta[V_Value][1])
	print meta[V_Value][1]
	print title
	 //Check for Run value
	 FindValue/TEXT="Run_"+num2str(dsNum)/TXOP=4/Z meta
	if (V_Value >= 0)
		title = title+" "+TrimWS(meta[V_Value][1])
		print title
	else
		FindValue/TEXT="Run"/TXOP=4/Z meta
		title = title+" "+TrimWS(meta[V_Value][1])	
		print title
	endif

	if (strlen(title) > 28)
		//Prompt title, "Set New Sample Name"
		//DoPrompt "Sample Name Is Too Long", title
		do
			Execute "getXMLShorterTitle()"
		while (strlen(title) > 28)			
	endif
	
	return title
end



Proc getXMLShorterTitle()
	
	 //NVAR title = root:myGlobals:gXMLLoader_Title
	
	DoWindow/K getNewTitle
	getNewTitle()

	PauseforUser getNewTitle 
end

Window getNewTitle()

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(166,90,666,230) as "Sample Title Too Long!"
	SetDrawLayer UserBack
	DrawText 11,22,"The sample title is too long."
	DrawText 11,42,"Please enter a new one with a maximum length 28 characters"
	DrawText 11,72,"Current Sample Title:"
	GroupBox group0 pos={8,55},size={484,50}
	TitleBox tb_CurrentTitle,pos={150,57}, variable=root:Packages:NIST:gXMLLoader_Title,fSize=12,frame=0	
	SetVariable sv_NewTitle,pos={11,77},size={476,18},title="New Sample Title"
	SetVariable sv_NewTitle,fSize=12,value=root:Packages:NIST:gXMLLoader_Title
	Button btn_SetNewTitle title="Set New Title",pos={150,110},size={200,20}
	Button btn_SetNewTitle proc=SetNewTitleButtonProc

EndMacro


Proc SetNewTitleButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K getNewTitle

End

#else	// if( Exists("XmlOpenFile") )
	// No XMLutils XOP: provide dummy function so that IgorPro can compile dependent support code
	FUNCTION LoadNISTXMLData(fileName,doPlot)
	    String fileName
	    Variable doPlot
	    Abort  "XML function provided by XMLutils XOP is not available, get the XOP from : http://www.igorexchange.com/project/XMLutils (see http://www.smallangles.net/wgwiki/index.php/cansas1d_binding_IgorPro for details)"
	    RETURN(-6)
	END
	

	
#endif	// if( Exists("XmlOpenFile") 
//Needed to test whether file is XML. The load routine will then either give an error if XMLutils is not present or load the file if it is.
function isXML(filestr)
	String filestr
	
	String line
	Variable fileref
	
	Open/R fileref as filestr
	FReadLine fileref,  line
	Close fileref
	
	//Hopefully this will distinguish between other formats and the XML
	//Previous string match would match normal files that have a .xml file as their progenitor...
	return GrepString(line, "(?iU).*\<.*xml.*")	

end