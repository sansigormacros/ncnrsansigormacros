#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



// TODO:
// -- This is a placeholder for the final NXcanSAS writer for VSANS data.
// -- resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// -- The final writer will need to be aware of resolution, and there may be different forms
//
Function V_WriteNXcanSAS1DData(pathStr,folderStr,saveName)
	String pathStr,folderStr,saveName
	
	// Define local function variables
	String formatStr=""
	String destStr="", parentBase, nxcansasBase
	Variable fileID
	Variable refnum,dialog=1
	String/G base = "root:V_NXcanSAS_file"
	
	SetDataFolder $(pathStr+folderStr)
	
	// Check fullpath and dialog
	if(stringmatch(saveName, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		fileID = NxCansas_CreateFile(saveName)
	Endif
	if(!fileID)
		abort "Unable to create file at " + saveName + "."
	else
		Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
		sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
		sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all

		Wave qw = tmp_q
		Wave iw = tmp_i
		Wave sw = tmp_s
		Wave sigQ = tmp_sq
		Wave qbar = tmp_qb
		Wave fs = tmp_fs
	EndIf
	
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)
	
	//make sure the waves exist
	if(WaveExists(qw) == 0)
		Abort "q is missing"
	endif
	if(WaveExists(iw) == 0)
		Abort "i is missing"
	endif
	if(WaveExists(sw) == 0)
		Abort "s is missing"
	endif
	if(WaveExists(sigQ) == 0)
		Abort "Resolution information is missing."
	endif
	if(WaveExists(proto) == 0)
		Abort "protocol information is missing."
	endif
	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/T/O/N=1 empty = {""}
	Make/T/O/N=1 units = {"units"}
	Make/T/O/N=1 inv_cm = {"1/cm"}
	Make/T/O/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(parentBase)
	
	Make/O/T/N=1 $(parentBase + ":title") = {V_getTitle(folderStr)}
	CreateStrNxCansas(fileID,nxcansasBase,"","title",$(parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(parentBase + ":run") = {V_getExperiment_identifier(folderStr)}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(parentBase + ":run"),empty,empty)
	
	// SASData
	String dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	String dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0",V_getDataEndTime(folderStr)}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","Qdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qw,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",iw,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",sw,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",sigQ,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",qbar,units,inv_angstrom)
	
	// Write all VSANS meta data
	V_WriteMetaData(fileID,parentBase,nxcansasBase,folderStr,proto)
	
End

//
//////////////////////////////////////////////////////////////////////////////////////////////////


///////// QxQy Export  //////////
//
// (see the similar-named SANS routine for additonal steps - like resolution, etc.)
//ASCII export of data as 8-columns qx-qy-Intensity-err-qz-sigmaQ_parall-sigmaQ_perp-fShad
// + limited header information
//
//	Jan 2019 -- first version, simply exports the basic matrix of data with no resolution information
//
//
Function V_WriteNXcanSAS2DData(type,fullpath,newFileName,dialog)
	String type,fullpath,newFileName
	Variable dialog		//=1 will present dialog for name
	
	String typeStr=""
	Variable refnum
	String detStr="",detSavePath

	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	
	// declare, or make a fake protocol if needed (if the export type is RAW)
	String rawTag=""
	if(cmpstr(type,"RAW")==0)
		Make/O/T/N=(kNumProtocolSteps) proto
		RawTag = "RAW Data File: "	
	else
		Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	
	endif
	
	SVAR samFiles = $("root:Packages:NIST:VSANS:"+type+":gFileList")
	
	//check each wave - MUST exist, or will cause a crash
//	If(!(WaveExists(data)))
//		Abort "data DNExist QxQy_Export()"
//	Endif

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

	// data values to populate the file header
	String fileName,fileDate,fileLabel
	Variable monCt,lambda,offset,dist,trans,thick
	Variable bCentX,bCentY,a2,a1a2_dist,deltaLam,bstop
	String a1Str
	Variable pixX,pixY
	Variable numTextLines,ii,jj,kk
	Variable pixSizeX,pixSizeY
	Variable duration

	numTextLines = 30
	Make/O/T/N=(numTextLines) labelWave

	//
	
	//loop over all of the detector panels
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	String detList
	if(gIgnoreDetB)
		detList = ksDetectorListNoB
	else
		detList = ksDetectorListAll
	endif
	
	for(kk=0;kk<ItemsInList(detList);kk+=1)

		detStr = StringFromList(kk, detList, ";")
		detSavePath = fullPath + "_" + detStr
		
		pixX = V_getDet_pixel_num_x(type,detStr)
		pixY = V_getDet_pixel_num_y(type,detStr)
		
		fileName = newFileName
		fileDate = V_getDataStartTime(type)		// already a string
		fileLabel = V_getSampleDescription(type)
		
		monCt = V_getBeamMonNormData(type)
		lambda = V_getWavelength(type)
	
	// TODO - switch based on panel type
	//	V_getDet_LateralOffset(fname,detStr)
	//	V_getDet_VerticalOffset(fname,detStr)
		offset = V_getDet_LateralOffset(type,detStr)
	
		dist = V_getDet_ActualDistance(type,detStr)
		trans = V_getSampleTransmission(type)
		thick = V_getSampleThickness(type)
		
		bCentX = V_getDet_beam_center_x(type,detStr)
		bCentY = V_getDet_beam_center_y(type,detStr)
		a1Str = V_getSourceAp_size(type)		//already a string
		a2 = V_getSampleAp2_size(type)
		a1a2_dist = V_getSourceAp_distance(type)
		deltaLam = V_getWavelength_spread(type)
		// TODO -- decipher which beamstop, if any is actually in place
	// or -- V_getBeamStopC3_size(type)
		bstop = V_getBeamStopC2_size(type)

		pixSizeX = V_getDet_x_pixel_size(type,detStr)
		pixSizeY = V_getDet_y_pixel_size(type,detStr)
		
		duration = V_getCount_time(type)
		
	/////////
		labelWave[0] = "FILE: "+fileName+"   CREATED: "+fileDate
		labelWave[1] = "LABEL: "+fileLabel
		labelWave[2] = "MON CNT   LAMBDA (A)  DET_OFF(cm)   DET_DIST(cm)   TRANS   THICK(cm)"
		labelWave[3] = num2str(monCt)+"  "+num2str(lambda)+"       "+num2str(offset)+"     "+num2str(dist)
		labelWave[3] += "     "+num2str(trans)+"     "+num2str(thick)
		labelWave[4] = "BCENT(X,Y)(cm)   A1(mm)   A2(mm)   A1A2DIST(m)   DL/L   BSTOP(mm)"
		labelWave[5] = num2str(bCentX)+"  "+num2str(bCentY)+"  "+a1Str+"    "+num2str(a2)+"    "
		labelWave[5] += num2str(a1a2_dist)+"    "+num2str(deltaLam)+"    "+num2str(bstop)
		labelWave[6] =  "SAM: "+rawTag+samFiles
		labelWave[7] =  "BGD: "+proto[0]
		labelWave[8] =  "EMP: "+proto[1]
		labelWave[9] =  "DIV: "+proto[2]
		labelWave[10] =  "MASK: "+proto[3]
		labelWave[11] =  "ABS Parameters (3-6): "+proto[4]
		labelWave[12] = "Average Choices: "+proto[5]
		labelWave[13] = "Collimation type: "+proto[9]
		labelWave[14] = "Panel="+detStr
		labelWave[15] = "NumXPixels="+num2str(pixX)
		labelWave[16] = "XPixelSize_mm="+num2str(pixSizeX)
		labelWave[17] = "NumYPixels="+num2str(pixY)
		labelWave[18] = "YPixelSize_mm="+num2str(pixSizeY)
		labelWave[19] = "Duration (s)="+num2str(duration)
		labelWave[20] = "reserved for future file definition changes"
		labelWave[21] = "reserved for future file definition changes"
		labelWave[22] = "reserved for future file definition changes"
		labelWave[23] = "reserved for future file definition changes"
		labelWave[24] = "reserved for future file definition changes"
		labelWave[25] = "reserved for future file definition changes"

		labelWave[26] = "*** Data written from "+type+" folder and may not be a fully corrected data file ***"
//		labelWave[20] = "Data columns are Qx - Qy - Qz - I(Qx,Qy) - Err I(Qx,Qy)"
	//	labelWave[20] = "Data columns are Qx - Qy - I(Qx,Qy) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow)"
		labelWave[27] = "Data columns are Qx - Qy - I(Qx,Qy) - err(I) - Qz - SigmaQ_parall - SigmaQ_perp - fSubS(beam stop shadow)"
		labelWave[28] = "The error wave may not be properly propagated (1/2019)"
		labelWave[29] = "ASCII data created " +date()+" "+time()
		//strings can be too long to print-- must trim to 255 chars
		for(jj=0;jj<numTextLines;jj+=1)
			labelWave[jj] = (labelWave[jj])[0,240]
		endfor
	
	
	// get the data waves for output
	// QxQyQz have already been calculated for VSANS data
		
		WAVE data = V_getDetectorDataW(type,detStr)
		WAVE data_err = V_getDetectorDataErrW(type,detStr)
		
		// TOOD - replace hard wired paths with Read functions
		// hard-wired
		Wave qx_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qx_"+detStr)
		Wave qy_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qy_"+detStr)
		Wave qz_val = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qz_"+detStr)
		Wave qTot = $("root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"+detStr+":qTot_"+detStr)
		
	///// calculation of the resolution function (2D)

	//
		Variable acc,ssd,lambda0,yg_d,qstar,g,L1,L2,vz_1,sdd
		// L1 = source to sample distance [cm] 
		L1 = V_getSourceAp_distance(type)
	
	// L2 = sample to detector distance [cm]
		L2 = V_getDet_ActualDistance(type,detStr)		//cm

	//		
		G = 981.  //!	ACCELERATION OF GRAVITY, CM/SEC^2
		vz_1 =	3.956E5	//	3.956E5 //!	CONVERT WAVELENGTH TO VELOCITY CM/SEC
		acc = vz_1
		SDD = L2		//1317
		SSD = L1		//1627 		//cm
		lambda0 = lambda		//		15
		YG_d = -0.5*G*SDD*(SSD+SDD)*(LAMBDA0/acc)^2
		Print "DISTANCE BEAM FALLS DUE TO GRAVITY (CM) = ",YG_d
	////		Print "Gravity q* = ",-2*pi/lambda0*2*yg_d/sdd
		qstar = -2*pi/lambda0*2*yg_d/sdd
	//	
	//
	//// the gravity center is not the resolution center
	//// gravity center = beam center
	//// resolution center = offset y = dy + (2)*yg_d
	/////************
	//// do everything to write out the resolution too
	//	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	//	qval = CalcQval(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
		Duplicate/O qTot,phi,r_dist
		Variable xctr,yctr


		xctr = V_getDet_beam_center_x_pix(type,detStr)
		yctr = V_getDet_beam_center_y_pix(type,detStr)
		phi = V_FindPhi( pixSizeX*((p+1)-xctr) , pixSizeY*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
		r_dist = sqrt(  (pixSizeX*((p+1)-xctr))^2 +  (pixSizeY*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt
	
		//make everything in 1D now
		Duplicate/O qTot SigmaQX,SigmaQY,fsubS,qval	
		Redimension/N=(pixX*pixY) SigmaQX,SigmaQY,fsubS,qval,phi,r_dist

		Variable ret1,ret2,ret3,nq
		String collimationStr
		
		
		collimationStr = proto[9]
		
		nq = pixX*pixY
		ii=0

// TODO
// this loop is the slow step. it takes Å 0.7 s for F or M panels, and Å 120 s for the Back panel (6144 pts vs. 1.12e6 pts)
// find some way to speed this up!
// MultiThreading will be difficult as it requires all the dependent functions (HDF5 reads, etc.) to be threadsafe as well
// and there are a lot of them... and I don't know if opening a file multiple times is a threadsafe operation? 
//  -- multiple open attempts seems like a bad idea.
		//type = work folder
		
//		(this doesn't work...and isn't any faster)
//		Duplicate/O qval dum
//		dum = V_get2DResolution(qval,phi,r_dist,type,detStr,collimationStr,SigmaQX,SigmaQY,fsubS)

v_tic()
		do
			V_get2DResolution(qval[ii],phi[ii],r_dist[ii],type,detStr,collimationStr,ret1,ret2,ret3)
			SigmaQX[ii] = ret1	
			SigmaQY[ii] = ret2	
			fsubs[ii] = ret3	
			ii+=1
		while(ii<nq)	
v_toc()	
	////*********************	
		Duplicate/O qx_val,qx_val_s
		Duplicate/O qy_val,qy_val_s
		Duplicate/O qz_val,qz_val_s
		Duplicate/O data,z_val_s
		Duplicate/O SigmaQx,sigmaQx_s
		Duplicate/O SigmaQy,sigmaQy_s
		Duplicate/O fSubS,fSubS_s
		Duplicate/O data_err,sw_s
		
		//so that double precision data is not written out
		Redimension/S qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		Redimension/S SigmaQx_s,SigmaQy_s,fSubS_s
	
		Redimension/N=(pixX*pixY) qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		
		//not demo-compatible, but approx 8x faster!!	
#if(strsearch(stringbykey("IGORKIND",IgorInfo(0),":",";"), "demo", 0 ) == -1)
		
//		Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s as detSavePath	// without resolution
		Save/O/G/M="\r\n" labelWave,qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s as detSavePath	// write out the resolution information
#else
		Open refNum as detSavePath
		wfprintf refNum,"%s\r\n",labelWave
		fprintf refnum,"\r\n"
//		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,qz_val_s,z_val_s,sw_s
		wfprintf refNum,"%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\t%8g\r\n",qx_val_s,qy_val_s,z_val_s,sw_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s
		Close refNum
#endif
		
		KillWaves/Z qx_val_s,qy_val_s,z_val_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,sw,sw_s
		
		Killwaves/Z qval,sigmaQx,SigmaQy,fSubS,phi,r_dist
		
		Print "QxQy_Export File written: ", V_GetFileNameFromPathNoSemi(detSavePath)
	
	endfor
	
	KillWaves/Z labelWave,dum
	return(0)
End

///////////////////////////////////////////////////////////////////////////
// - V_WriteMetaData - Method used to write non data elements into NXcanSAS
// format. This is common between 1D and 2D data sets.

//
// FIXME: Remove textw and rw once locations of information are known
//

Function V_WriteMetaData(fileID,base,parentBase,folderStr,proto)
	String base,parentBase,folderStr
	Variable fileID
	Wave/T proto
	
	// Define common attribute waves
	Make/T/O/N=1 empty = {""}
	Make/T/O/N=1 units = {"units"}
	Make/T/O/N=1 m = {"m"}
	Make/T/O/N=1 mm = {"mm"}
	Make/T/O/N=1 cm = {"cm"}
	Make/T/O/N=1 pixel = {"pixel"}
	Make/T/O/N=1 angstrom = {"A"}
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	// Create SASinstrument entry
	String instrumentBase = base + ":sasinstrument"
	NewDataFolder/O/S $(instrumentBase)
	Make/O/T/N=5 $(instrumentBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(instrumentBase + ":attrVals") = {"SASinstrument","NXinstrument"}
	CreateStrNxCansas(fileID,instrParent,"","",empty,$(instrumentBase + ":attr"),$(instrumentBase + ":attrVals"))
	// Create SASinstrument name entry
	Make/O/T/N=1 $(instrumentBase + ":name") = {V_getInstrumentName(folderStr)}
	CreateStrNxCansas(fileID,instrParent,"","name",$(instrumentBase + ":name"),empty,empty)
	
	// SASaperture
	String apertureParent = instrParent + "sasaperture/"
	// Create SASaperture entry
	String apertureBase = instrumentBase + ":sasaperture"
	NewDataFolder/O/S $(apertureBase)
	Make/O/T/N=5 $(apertureBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(apertureBase + ":attrVals") = {"SASaperture","NXaperture"}
	CreateStrNxCansas(fileID,apertureParent,"","",empty,$(apertureBase + ":attr"),$(apertureBase + ":attrVals"))
	
	// Create SASaperture shape entry
	Make/O/T/N=1 $(apertureBase + ":shape") = {V_getSampleAp_shape(folderStr)} 
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {V_getSampleAp_height(folderStr)}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,mm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {V_getSampleAp_width(folderStr)}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,mm)
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	// Create SAScollimation entry
	String collimationBase = instrumentBase + ":sascollimation"
	NewDataFolder/O/S $(collimationBase)
	Make/O/T/N=5 $(collimationBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(collimationBase + ":attrVals") = {"SAScollimation","NXcollimator"}
	CreateStrNxCansas(fileID,collimationParent,"","",empty,$(collimationBase + ":attr"),$(collimationBase + ":attrVals"))
	// Create SAScollimation distance entry
	Make/O/N=1 $(collimationBase + ":distance") = {V_getSourceAp_distance(folderStr)}
	CreateVarNxCansas(fileID,collimationParent,"sasaperture","distance",$(collimationBase + ":distance"),units,m)
	
	//
	// TODO: Create separate detector entry for each panel
	//
	
	// SASdetector - Front Top
	String detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"FrontTop"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"FT")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"FT")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"FT")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"FT")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"FT")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASsource
	String sourceParent = instrParent + "sassource/"
	// Create SASdetector entry
	String sourceBase = instrumentBase + ":sassource"
	NewDataFolder/O/S $(sourceBase)
	Make/O/T/N=5 $(sourceBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sourceBase + ":attrVals") = {"SASsource","NXsource"}
	CreateStrNxCansas(fileID,sourceParent,"","",empty,$(sourceBase + ":attr"),$(sourceBase + ":attrVals"))
	// Create SASsource radiation entry
	Make/O/T/N=1 $(sourceBase + ":radiation") = {V_getSourceType(folderStr}
	CreateStrNxCansas(fileID,sourceParent,"","radiation",$(sourceBase + ":radiation"),empty,empty)
	// Create SASsource incident_wavelength entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {V_getWavelength(folderStr)}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {V_getWavelength_spread(folderStr)}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength_spread",$(sourceBase + ":incident_wavelength_spread"),units,angstrom)
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	// Create SASsample entry
	String sampleBase = base + ":sassample"
	NewDataFolder/O/S $(sampleBase)
	Make/O/T/N=5 $(sampleBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sampleBase + ":attrVals") = {"SASsample","NXsample"}
	CreateStrNxCansas(fileID,sampleParent,"","",empty,$(sampleBase + ":attr"),$(sampleBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(sampleBase + ":name") = {V_getSampleDescription(folderStr)}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {V_getSampleThickness(folderStr)}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {V_getSampleTransmission(folderStr)}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	// SASprocess
	SVAR samFiles = root:Packages:NIST:VSANS:Globals:Protocols:gSAM
	String protoStr7,protoStr8
	if(strlen(proto[7]) == 0)
		protoStr7 = "(Default) "+ ksBinTrimBegDefault
	else
		protoStr7 = proto[7]
	endif
	if(strlen(proto[8]) == 0)
		protoStr8 = "(Default) "+ ksBinTrimEndDefault
	else
		protoStr8 = proto[8]
	endif
	String processNote = ""
	sPrintf processNote,"SAM: %s\r\n",samFiles
	sPrintf processNote,"%sBGD: %s\r\n",processNote,proto[0]
	sPrintf processNote,"%sEMP: %s\r\n",processNote,Proto[1]
	sPrintf processNote,"%sDIV: %s\r\n",processNote,Proto[2]
	sPrintf processNote,"%sMASK: %s\r\n",processNote,Proto[3]
	sPrintf processNote,"%sABS Parameters (3-6): %s\r\n",processNote,Proto[4]
	sPrintf processNote,"%sAverage Choices: %s\r\n",processNote,Proto[5]
	sPrintf processNote,"%sBeginning Trim Points: %s\r\n",processNote,ProtoStr7
	sPrintf processNote,"%sEnd Trim Points: %s\r\n",processNote,ProtoStr8
	sPrintf processNote,"%sCOLLIMATION=%s\r\n",processNote,proto[9]
	String processParent = parentBase + "sasprocess/"
	// Create SASprocess entry
	String processBase = base + ":sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=5 $(processBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(processBase + ":attrVals") = {"SASprocess","NXprocess"}
	CreateStrNxCansas(fileID,processParent,"","",empty,$(processBase + ":attr"),$(processBase + ":attrVals"))
	// Create SASprocess name entry
	Make/O/T/N=1 $(processBase + ":name") = {samFiles}
	CreateStrNxCansas(fileID,processParent,"","name",$(processBase + ":name"),empty,empty)
	// Create SASprocess note entry
	Make/O/T/N=1 $(processBase + ":note") = {processNote}
	CreateStrNxCansas(fileID,processParent,"","note",$(processBase + ":note"),empty,empty)
End
	
//
///////////////////////////////////////////////////////////////////////////
