#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function V_WriteNXcanSAS1DData(pathStr,folderStr,saveName)
	String pathStr,folderStr,saveName
	
	// Define local function variables
	String formatStr=""
	String destStr="", parentBase, nxcansasBase
	Variable fileID
	Variable refnum,dialog=0
	String/G base = "root:V_NXcanSAS_file"
	
	NewDataFolder/O/S $(base)
	
	// Check fullpath and dialog
	fileID = NXcanSAS_OpenOrCreate(dialog,saveName,base)
	SetDataFolder $(pathStr+folderStr)
	
	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
	sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all

	Wave qw = tmp_q
	Wave iw = tmp_i
	Wave sw = tmp_s
	Wave sigQ = tmp_sq
	Wave qbar = tmp_qb
	Wave fs = tmp_fs
	
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
	Make/O/T/N=1 $(parentBase + ":title") = {V_getSampleDescription(folderStr)}
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
	// Create qx and qy entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/O/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/O/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","Qdev"}
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
		
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	KillDataFolder/Z $base
	
End

//
//////////////////////////////////////////////////////////////////////////////////////////////////


///////// QxQy Export  //////////
//
// (see the similar-named SANS routine for additonal steps - like resolution, etc.)
// NXcanSAS output using the latest standard
//
//	July 2019 -- first version
//
//
// TODO:
// -- resolution is not generated here (and it shouldn't be) since resolution is not known yet.
// -- The final writer will need to be aware of resolution, and there may be different forms
//
Function V_WriteNXcanSAS2DData(folderStr,pathStr,saveName,dialog)
	String pathStr,folderStr,saveName
	Variable dialog		//=1 will present dialog for name
	
	// Define local function variables
	String formatStr="",detStr="",detSavePath
	String destStr="",parentBase,nxcansasBase
	String type=folderStr
	
	Variable fileID
	String/G base = "root:V_NXcanSAS_file"
	
	NewDataFolder/O/S $(base)
	SetDataFolder $("root:Packages:NIST:VSANS:"+folderStr)
	
	// TEST: Remove and add a preference when finished testing
	String writeCombined = "DoIt"
	// ENDTEST
	
	// Check fullpath and dialog
	fileID = NXcanSAS_OpenOrCreate(dialog,pathStr,base)
		
	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
	sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all
	
	// declare, or make a fake protocol if needed (if the export type is RAW)
	SVAR gProtoStr = root:Packages:NIST:VSANS:Globals:Protocols:gProtoStr
	String rawTag=""
	if(cmpstr(folderStr,"RAW")==0)
		Make/O/T/N=(kNumProtocolSteps) proto
		RawTag = "RAW Data File: "	
	else
		Wave/T proto=$("root:Packages:NIST:VSANS:Globals:Protocols:"+gProtoStr)	
	endif
	
	SVAR samFiles = $("root:Packages:NIST:VSANS:"+folderStr+":gFileList")
	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(parentBase)
	
	Make/O/T/N=1 $(parentBase + ":title") = {V_getSampleDescription(folderStr)}
	CreateStrNxCansas(fileID,nxcansasBase,"","title",$(parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(parentBase + ":run") = {V_getExperiment_identifier(folderStr)}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(parentBase + ":run"),empty,empty)

	// data values to populate the file header
	String fileName,fileDate,fileLabel
	Variable monCt,lambda,offset,dist,trans,thick
	Variable bCentX,bCentY,a2,a1a2_dist,deltaLam,bstop
	String a1Str
	Variable pixX,pixY,pixIntermed
	Variable numTextLines,ii,jj,kk
	Variable pixSizeX,pixSizeY
	Variable duration

	numTextLines = 30
	Make/O/T/N=(numTextLines) labelWave
	
	//loop over all of the detector panels
	NVAR gIgnoreDetB = root:Packages:NIST:VSANS:Globals:gIgnoreDetB

	String detList
	if(gIgnoreDetB)
		detList = ksDetectorListNoB
	else
		detList = ksDetectorListAll
	endif
	
	if (!stringMatch(writeCombined,""))
		Make/O/N=(0) Combined_Qx
		Make/O/N=(0) Combined_Qy
		Make/O/N=(0) Combined_I_1D
		Make/O/N=(0) Combined_Idev_1D
		Make/O/N=(0) Combined_Qxdev_1D
		Make/O/N=(0) Combined_Qydev_1D
		Make/O/N=(0) Combined_Shadow_1D
		Variable xPixTotal = 0
		Variable yPixTotal = 0
	EndIf
	
	for(kk=0;kk<ItemsInList(detList);kk+=1)

		detStr = StringFromList(kk, detList, ";")
		detSavePath = pathStr + "_" + detStr
		
		pixX = V_getDet_pixel_num_x(type,detStr)
		pixY = V_getDet_pixel_num_y(type,detStr)
		
		fileName = saveName
		fileDate = V_getDataStartTime(type)		// already a string
		fileLabel = V_getSampleDescription(type)
		
		monCt = V_getBeamMonNormData(type)
		lambda = V_getWavelength(type)

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
		
		WAVE data = V_getDetectorDataW(type,detStr)
		WAVE data_err = V_getDetectorDataErrW(type,detStr)
		
		// TODO - replace hard wired paths with Read functions
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
		Redimension/N=(pixY*pixX) SigmaQX,SigmaQY,fsubS,qval,phi,r_dist

		Variable ret1,ret2,ret3,nq
		String collimationStr = proto[9]

// TODO
// this loop is the slow step. it takes ÔøΩ 0.7 s for F or M panels, and ÔøΩ 120 s for the Back panel (6144 pts vs. 1.12e6 pts)
// find some way to speed this up!
// MultiThreading will be difficult as it requires all the dependent functions (HDF5 reads, etc.) to be threadsafe as well
// and there are a lot of them... and I don't know if opening a file multiple times is a threadsafe operation? 
//  -- multiple open attempts seems like a bad idea.
		//type = work folder
		
//		(this doesn't work...and isn't any faster)
//		Duplicate/O qval dum
//		dum = V_get2DResolution(qval,phi,r_dist,type,detStr,collimationStr,SigmaQX,SigmaQY,fsubS)

v_tic()
		Make/O/N=(2,pixX,pixY) qxy_vals
		Make/O/N=(pixX,pixY) shadow
		Make/O/N=(2,pixX,pixY) SigmaQ_combined
		If (!stringMatch(writeCombined,""))
			Make/O/N=(pixX*pixY) shadow_1d_i
			Make/O/N=(pixX*pixY) shadow_1d_i
		EndIf
		ii=0
		do
			jj = 0
			do
				nq = ii * pixX + jj
				V_get2DResolution(qval[nq],phi[nq],r_dist[nq],folderStr,detStr,collimationStr,ret1,ret2,ret3)
				qxy_vals[0][jj][ii] = qx_val[nq]
				qxy_vals[1][jj][ii] = qy_val[nq]
				SigmaQ_combined[0][jj][ii] = ret1
				SigmaQ_combined[1][jj][ii] = ret2
				shadow[jj][ii] = ret3
				jj+=1
			while(jj<pixX)
			ii+=1
		while(ii<pixY)
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
		
		// SASData
		String dataParent,dataBase
		sPrintf dataParent,"%ssasdata%d/",nxcansasBase,kk
		// Create SASdata entry
		sPrintf dataBase,"%s:sasdata%d",parentBase,kk
		NewDataFolder/O/S $(dataBase)
		Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
		Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q,Q","NXdata","0,1",V_getDataEndTime(folderStr)}
		CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
		// Create i entry
		NewDataFolder/O/S $(dataBase + ":i")
		Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
		Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
		CreateVarNxCansas(fileID,dataParent,"sasdata","I",data,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
		//
		// TODO: Reinstate Qdev/resolutions when I can fix the reader issue
		//
		// Create qx and qy entry
		NewDataFolder/O/S $(dataBase + ":q")
		Make/O/T/N=2 $(dataBase + ":q:attr") = {"units"}//,"resolutions"}
		Make/O/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom"}//,"Qdev"}
		CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qxy_vals,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
		// Create idev entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",data_err,units,inv_cm)
		// Create qdev entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",SigmaQ_combined,units,inv_angstrom)
		// Create shadwfactor entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","ShadowFactor",shadow,empty,empty)
		//
		///////////////////////////////////////////////////////////////////////////
		
		
		///////////////////////////////////////////////////////////////////////////
		// Combine the qx and qy vals into the array and then match the size for combined shadow and I
		if (!stringMatch(writeCombined,""))
			pixIntermed = numpnts(Combined_Qx)
			Redimension/N=(pixX*pixY) data
			Redimension/N=(pixX*pixY) data_err
			Redimension/N=(pixIntermed + pixX*pixY) Combined_Qx
			Redimension/N=(pixIntermed + pixX*pixY) Combined_Qy
			Redimension/N=(pixIntermed + pixX*pixY) Combined_I_1D
			Redimension/N=(pixIntermed + pixX*pixY) Combined_Idev_1D
			Redimension/N=(pixIntermed + pixX*pixY) Combined_Qxdev_1D
			Redimension/N=(pixIntermed + pixX*pixY) Combined_Qydev_1D
			Combined_Qx[pixIntermed, pixIntermed + pixX*pixY-1] = qx_val[p-pixIntermed]
			Combined_Qy[pixIntermed, pixIntermed + pixX*pixY-1] = qy_val[p-pixIntermed]
			Combined_I_1D[pixIntermed, pixIntermed + pixX*pixY-1] = data[p-pixIntermed]
			Combined_Idev_1D[pixIntermed, pixIntermed + pixX*pixY-1] = data_err[p-pixIntermed]
			xPixTotal += pixX
			yPixTotal += pixY
		EndIf
		//
		///////////////////////////////////////////////////////////////////////////

		
		KillWaves/Z qx_val_s,qy_val_s,z_val_s,qz_val_s,SigmaQx_s,SigmaQy_s,fSubS_s,sw,sw_s
		Killwaves/Z qval,sigmaQx,SigmaQy,fSubS,phi,r_dist
	
	endfor
	
	if (!stringMatch(writeCombined,""))
		// This should generate a data set of zeroes of the size of the entire detector.
		Variable x_index, y_index, qx, qy
		Make/O/N=(2,xPixTotal, yPixTotal) Combined_QxQy
		Make/O/N=(2,xPixTotal, yPixTotal) Combined_SiqmaQ
		Make/O/N=(xPixTotal, yPixTotal) Combined_I
		Make/O/N=(xPixTotal, yPixTotal) Combined_Idev
		Make/O/N=(xPixTotal, yPixTotal) Combined_Shadow
		// Populate Combined_QxQy
		FindDuplicates /DN=uniqueQx /TOL=0.001 Combined_Qx
		FindDuplicates /DN=uniqueQy /TOL=0.001 Combined_Qy
		printf "xPixTotal: %f, numpnts(uniqueQx): %f\r", xPixTotal, numpnts(uniqueQx)
		printf "yPixTotal: %f, numpnts(uniqueQy): %f\r", yPixTotal, numpnts(uniqueQy)
		For (ii=0;ii<xPixTotal;ii+=1)
			Combined_QxQy[0][ii][0,xPixTotal-1] = uniqueQx[p]
		EndFor
		For (ii=0;ii<yPixTotal;ii+=1)
			Combined_QxQy[1][0,yPixTotal-1][ii] = uniqueQy[p]
		EndFor
		// Populate Combined_I, Combined_Idev, Combined_Shadow, and Combined_SigmaQ
		For (jj=0;jj<numpnts(Combined_Qx);jj+=1)
			FindValue /T=0.00001 /V=(Combined_Qx[jj]) /RMD=[0][0][] Combined_QxQy
			x_index = V_value
			FindValue /T=0.00001 /V=(Combined_Qy[jj]) /RMD=[1][][0] Combined_QxQy
			y_index = V_value
			If (x_index > 0 && y_index > 0)
				Combined_I[x_index][y_index] = Combined_I_1D[jj]
				Combined_Idev[x_index][y_index] = Combined_Idev_1D[jj]
			EndIf
		EndFor

		// SASData
		sPrintf dataParent,"%ssasdata%d/",nxcansasBase,kk+1
		// Create SASdata entry
		sPrintf dataBase,"%s:sasdata%d",parentBase,kk+1
		NewDataFolder/O/S $(dataBase)
		Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
		Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q,Q","NXdata","0,1",V_getDataEndTime(folderStr)}
		CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
		// Create i entry
		NewDataFolder/O/S $(dataBase + ":i")
		Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
		Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
		CreateVarNxCansas(fileID,dataParent,"sasdata","I",Combined_I,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
		//
		// TODO: Reinstate Qdev/resolutions when I can fix the reader issue
		//
		// Create qx and qy entry
		NewDataFolder/O/S $(dataBase + ":q")
		Make/O/T/N=2 $(dataBase + ":q:attr") = {"units"}//,"resolutions"}
		Make/O/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom"}//,"Qdev"}
		CreateVarNxCansas(fileID,dataParent,"sasdata","Q",Combined_QxQy,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
		// Create idev entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",Combined_Idev,units,inv_cm)
		// Create qdev entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",Combined_SiqmaQ,units,inv_angstrom)
		// Create shadwfactor entry
		CreateVarNxCansas(fileID,dataParent,"sasdata","ShadowFactor",Combined_Shadow,empty,empty)
	EndIf
	
	KillWaves/Z labelWave,dum
	
	// Write all VSANS meta data
	V_WriteMetaData(fileID,parentBase,nxcansasBase,folderStr,proto)
		
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	KillDataFolder/Z $base
	
	return(0)
End

///////////////////////////////////////////////////////////////////////////
// - V_WriteMetaData - Method used to write non data elements into NXcanSAS
// format. This is common between 1D and 2D data sets.

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
	
	// SASdetector - Front Top
	String detectorParent = instrParent + "sasdetector1/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector1"
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
	
	// SASdetector - Front Bottom
	detectorParent = instrParent + "sasdetector2/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector2"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"FrontBottom"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"FB")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"FB")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"FB")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"FB")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"FB")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)	
	
	// SASdetector - Front Left
	detectorParent = instrParent + "sasdetector3/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector3"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"FrontLeft"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"FL")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"FL")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"FL")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"FL")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"FL")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASdetector - Front Right
	detectorParent = instrParent + "sasdetector4/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector4"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"FrontRight"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"FR")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"FR")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"FR")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"FR")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"FR")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASdetector - Middle Top
	detectorParent = instrParent + "sasdetector5/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector5"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"MiddleTop"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"MT")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"MT")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"MT")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"MT")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"MT")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASdetector - Middle Bottom
	detectorParent = instrParent + "sasdetector6/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector6"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"MiddleBottom"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"MB")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"MB")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"MB")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"MB")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"MB")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASdetector - Middle Left
	detectorParent = instrParent + "sasdetector7/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector7"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"MiddleLeft"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"ML")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"ML")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"ML")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"ML")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"ML")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASdetector - Middle Right
	detectorParent = instrParent + "sasdetector8/"
	// Create SASdetector entry
	detectorBase = instrumentBase + ":sasdetector8"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"MiddleRight"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector type entry
	Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
	CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"MR")}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"MR")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"MR")}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"MR")}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"MR")}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	NVAR ignoreBack = root:Packages:NIST:VSANS:Globals:gIgnoreDetB
	if(ignoreBack == 0)	
		// SASdetector - Back High Res
		detectorParent = instrParent + "sasdetector9/"
		// Create SASdetector entry
		detectorBase = instrumentBase + ":sasdetector9"
		NewDataFolder/O/S $(detectorBase)
		Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
		Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
		CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
		// Create SASdetector name entry
		Make/O/T/N=1 $(detectorBase + ":name") = {"HighResolutionBack"}
		CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
		// Create SASdetector type entry
		Make/O/T/N=1 $(detectorBase + ":type") = {"He3 gas cylinder"}
		CreateStrNxCansas(fileID,detectorParent,"","type",$(detectorBase + ":type"),empty,empty)
		// Create SASdetector distance entry
		Make/O/N=1 $(detectorBase + ":SDD") = {V_getDet_ActualDistance(folderStr,"B")}
		CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,cm)
		// Create SASdetector beam_center_x entry
		Make/O/N=1 $(detectorBase + ":beam_center_x") = {V_getDet_beam_center_x_mm(folderStr,"B")}
		CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,mm)
		// Create SASdetector beam_center_y entry
		Make/O/N=1 $(detectorBase + ":beam_center_y") = {V_getDet_beam_center_y_mm(folderStr,"B")}
		CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,mm)
		// Create SASdetector x_pixel_size entry
		Make/O/N=1 $(detectorBase + ":x_pixel_size") = {V_getDet_x_pixel_size(folderStr,"B")}
		CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
		// Create SASdetector y_pixel_size entry
		Make/O/N=1 $(detectorBase + ":y_pixel_size") = {V_getDet_y_pixel_size(folderStr,"B")}
		CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	EndIf
	
	// SASsource
	String sourceParent = instrParent + "sassource/"
	// Create SASdetector entry
	String sourceBase = instrumentBase + ":sassource"
	NewDataFolder/O/S $(sourceBase)
	Make/O/T/N=5 $(sourceBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sourceBase + ":attrVals") = {"SASsource","NXsource"}
	CreateStrNxCansas(fileID,sourceParent,"","",empty,$(sourceBase + ":attr"),$(sourceBase + ":attrVals"))
	// Create SASsource probe and type entries
	Make/O/T/N=1 $(sourceBase + ":probe") = {"neutron"}
	CreateStrNxCansas(fileID,sourceParent,"","probe",$(sourceBase + ":probe"),empty,empty)
	Make/O/T/N=1 $(sourceBase + ":type") = {"Reactor Neutron Source"}
	CreateStrNxCansas(fileID,sourceParent,"","type",$(sourceBase + ":type"),empty,empty)
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
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,mm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {V_getSampleTransmission(folderStr)}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	// Create SASsample temperature entry
	If(V_getSampleTemperature(folderStr) != -999999)
		Make/O/N=1 $(sampleBase + ":temperature") = {V_getSampleTemperature(folderStr)}
		CreateVarNxCansas(fileID,sampleParent,"","temperature",$(sampleBase + ":temperature"),empty,empty)
	EndIf
	
	//
	// TODO: Include other sample environment when they are available
	
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
	String processNote0,processNote1,processNote2,processNote3,processNote4
	String processNote5,processNote6,processNote7,processNote8,processNote9
	sPrintf processNote0,"SAM: %s",samFiles
	sPrintf processNote1,"BGD: %s",Proto[0]
	sPrintf processNote2,"EMP: %s",Proto[1]
	sPrintf processNote3,"DIV: %s",Proto[2]
	sPrintf processNote4,"MASK: %s",Proto[3]
	sPrintf processNote5,"ABS Parameters (3-6): %s",Proto[4]
	sPrintf processNote6,"Average Choices: %s",Proto[5]
	sPrintf processNote7,"Beginning Trim Points: %s",ProtoStr7
	sPrintf processNote8,"End Trim Points: %s",ProtoStr8
	sPrintf processNote9,"COLLIMATION=%s",proto[9]
	// Create SASprocess entry
	String processParent = parentBase + "sasprocess/"
	String processBase = base + ":sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=5 $(processBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(processBase + ":attrVals") = {"SASprocess","NXprocess"}
	CreateStrNxCansas(fileID,processParent,"","",empty,$(processBase + ":attr"),$(processBase + ":attrVals"))
	// Create SASprocess name entry
	Make/O/T/N=1 $(processBase + ":name") = {samFiles}
	CreateStrNxCansas(fileID,processParent,"","name",$(processBase + ":name"),empty,empty)
	// Create SASprocess note entries
	Make/O/T/N=1 $(processBase + ":note0") = {processNote0}
	CreateStrNxCansas(fileID,processParent,"","note0",$(processBase + ":note0"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note1") = {processNote1}
	CreateStrNxCansas(fileID,processParent,"","note1",$(processBase + ":note1"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note2") = {processNote2}
	CreateStrNxCansas(fileID,processParent,"","note2",$(processBase + ":note2"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note3") = {processNote3}
	CreateStrNxCansas(fileID,processParent,"","note3",$(processBase + ":note3"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note4") = {processNote4}
	CreateStrNxCansas(fileID,processParent,"","note4",$(processBase + ":note4"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note5") = {processNote5}
	CreateStrNxCansas(fileID,processParent,"","note5",$(processBase + ":note5"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note6") = {processNote6}
	CreateStrNxCansas(fileID,processParent,"","note6",$(processBase + ":note6"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note7") = {processNote7}
	CreateStrNxCansas(fileID,processParent,"","note7",$(processBase + ":note7"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note8") = {processNote8}
	CreateStrNxCansas(fileID,processParent,"","note8",$(processBase + ":note8"),empty,empty)
	Make/O/T/N=1 $(processBase + ":note9") = {processNote9}
	CreateStrNxCansas(fileID,processParent,"","note9",$(processBase + ":note9"),empty,empty)
	
End
	
//
///////////////////////////////////////////////////////////////////////////
