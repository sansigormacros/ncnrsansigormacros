#pragma rtGlobals=1		// Use modern global access method.


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
//	variable sample_thickness
	string sample_ID
//	string unitssample_thickness
//	variable sample_transmission

	//SASinstrument
	string nameSASinstrument
	// SASinstrument/SASsource
	string radiation
//	string beam_shape
//	variable wavelength
//	string unitswavelength
//	variable wavelength_spread
//	string unitswavelength_spread
 
	//<SAScollimation>
//	variable distance_coll
//	string unitsdistance_coll
//	variable source_aperture
//	string unitssource_aperture
//	string typesource_aperture
//	variable sample_aperture
//	string unitssample_aperture
//	string typesample_aperture

	//SASdetector         <SASdetector>
	string detector_name
//	variable offset_angle
//	string unitsoffset_angle
//	variable  distance_SD
//	string unitsdistance_SD
//	variable beam_centreX
//	string unitsbeam_centreX
//	variable beam_centreY
//	string unitsbeam_centreY
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


//Function to write NIST canSAS XML files
//Minimalist XML file - AJJ Dec 2008
function writeNISTXML(fileName, NISTfile)
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
	
			xmladdnode(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]","","Idev",num2str(NISTfile.dQl[ii]),1)
			xmlsetAttr(fileID,"/SASroot/SASentry/SASdata/Idata["+num2istr(ii+1)+"]/Idev","","unit",NISTfile.unitsdQl)		
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

Function convertNISTtoNISTXML(fileStr)
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
			
			//Set units
			nf.unitsdQl = "1/A"
			
		endif
		
		//Tidy up
		Variable i = 0
		do
			WAVE wv= $(StringFromList(i,S_waveNames,";"))
			if( WaveExists(wv) == 0 )
				break
			endif
			KillWaves wv
			i += 1
		while (1)	// exit is via break statement

	
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

end

function setmetadataFromASCHeader(fileStr,NISTfile)
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
		print buffer
		//Get run value
		if (stringmatch(buffer,"*file:*") == 1)
			NISTfile.run = TrimWS(StringFromList(0,StringFromList(1, buffer, ":"),"C"))
		elseif (stringmatch(buffer,"combined file*") == 1)
			NISTfile.run = "Combined Data"
		endif
		
		//Get title value
		if (stringmatch(buffer,"*FIRST File LABEL:*") == 1)
			NISTfile.title = TrimWS(StringFromList(1,buffer, ":"))
		elseif(stringmatch(buffer,"*LABEL:*") == 1)
			NISTfile.title = TrimWS(StringFromList(1,buffer, ":"))
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