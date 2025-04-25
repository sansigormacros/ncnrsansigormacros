#pragma rtGlobals=3		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

#if (IgorVersion() < 9)
#include <HDF5 Browser>
#endif

//************************
// Vers 1.15 20171003
//
//************************


///////////////////////////////////////////////////////////////////////////
// - WriteNxCanSAS1D - Method for writing 1D NXcanSAS data
// Creates an HDF5 file, with reduced 1D data and stores all meta data
// If dialog and fullpath are left blank (0 and ""), fake data will be used

Function WriteNxCanSAS1D(type,fullpath,dialog)
	// Define input variables
	String type // data location, in memory, relative to root:Packages:NIST:
	String fullpath // file path and name where data will be saved
	Variable dialog // if 1, prompt user for file path, otherwise, use fullpath
	
	// Define local function variables
	Variable fileID
	String destStr="", parentBase, nxcansasBase
	String/G base = "root:NXcanSAS_file"
	
	// Define local waves
//	Wave/T vals,attr,attrVals
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	// Check fullpath and dialog
	fileID = NXcanSAS_OpenOrCreate(dialog,fullpath,base)
	
	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
	sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all

	destStr = "root:Packages:NIST:"+type
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
//	WAVE intw = $(destStr + ":integersRead")		// SRK_0920
//	WAVE rw = $(destStr + ":realsRead")
//	WAVE/T textw=$(destStr + ":textRead")
	WAVE qvals =$(destStr + ":qval")
	WAVE inten=$(destStr + ":aveint")
	WAVE sig=$(destStr + ":sigave")
	WAVE qbar = $(destStr + ":QBar")
	WAVE sigmaq = $(destStr + ":SigmaQ")
	WAVE fsubs = $(destStr + ":fSubS")

	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/T/O/N=1 empty = {""}
	Make/T/O/N=1 units = {"units"}
	Make/T/O/N=1 inv_cm = {"1/cm"}
	Make/T/O/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(parentBase)
	Make/O/T/N=1 $(parentBase + ":title") = {getSampleDescription(type)}
	CreateStrNxCansas(fileID,nxcansasBase,"","title",$(parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(parentBase + ":run") = {getTitle(type)}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(parentBase + ":run"),empty,empty)
	
	// SASData
	String dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	String dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0",getDataStartTime(type)}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/O/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/O/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","Qdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qvals,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",inten,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",sig,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",sigmaq,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",qbar,units,inv_angstrom)
	
	// Write all meta data
	if (CmpStr(type,"NSORT") == 0)
		Wave/T process = $(destStr + ":processNote")
		String processNote = process[0]
		WriteProcess(fileID,nxcansasBase,parentBase,"NSORTed Data",processNote)
	Else
		WriteMetaData(fileID,parentBase,nxcansasBase,type)
	EndIf
	
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	KillDataFolder/Z $base
	
End

//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
// - WriteNxCanSAS2D - Method for writing 2D NXcanSAS data
// Creates an HDF5 file, generates reduced 2D data and stores all meta data
// If dialog and fullpath are left blank (0 and ""), fake data will be used

Function WriteNxCanSAS2D(type,fullpath,dialog)
	// Define input variables
	String type // data location, in memory, relative to root:Packages:NIST:
	String fullpath // file path and name where data will be saved
	Variable dialog // if 1, prompt user for file path, otherwise, use fullpath
	
	// Define local function variables
	Variable fileID
	String destStr="",typeStr="", parentBase, nxcansasBase
	String/G base = "root:NXcanSAS_file"
	
	// Define local waves
//	Wave/T vals,attr,attrVals
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	SVAR samFiles = $("root:Packages:NIST:"+type+":fileList")
	string tmpName = RemoveDotExtension(samFiles) + ".h5"
	fullPath=tmpName
	PathInfo home
	if(strlen(S_Path) > 0)
		fullpath = S_path+tmpName
	endif
	
	// Check fullpath and dialog
	fileID = NXcanSAS_OpenOrCreate(dialog,fullpath,base)

	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
	sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all
	
	destStr = "root:Packages:NIST:"+type

	//must select the linear_data to export
//	NVAR isLog = $(destStr+":gIsLogScale")
//	if(isLog==1)
//		typeStr = ":linear_data"
//	else
//		typeStr = ":data"
//	endif
//	NVAR pixelsX = root:myGlobals:gNPixelsX
//	NVAR pixelsY = root:myGlobals:gNPixelsY
	Variable pixelsX = getDet_pixel_num_x(type)
	Variable pixelsY = getDet_pixel_num_y(type)
	
	WAVE data=getDetectorDataW(type)		//this is always linear data
	Wave data_err=getDetectorDataErrW(type)
	
//	WAVE intw=$(destStr + ":integersRead")
//	WAVE rw=$(destStr + ":realsRead")
//	WAVE/T textw=$(destStr + ":textRead")
	
	///////////////////////////////////////////////////////////////////////////
	// Compute Qx, Qy data from pixel space
	
	Duplicate/O data,qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
	
	Variable xctr,yctr,sdd,lambda,pixSize

	xCtr = getDet_beam_center_x(type)
	yCtr = getDet_beam_center_y(type)
	sdd = getDet_Distance(type)		//distance in [cm]
	lambda = getWavelength(type)
	pixSize = getDet_x_pixel_size(type)/10		//convert mm to cm (x and y are the same size pixels)

	WAVE coefW = getDetTube_spatialCalib(type)
	Variable tube_width=getDet_tubeWidth(type)

	qx_val = T_CalcQx(p+1,q+1,xCtr,yCtr,tube_width,sdd,lambda,coefW)		//+1 converts to detector coordinate system
	qy_val = T_CalcQy(p+1,q+1,xCtr,yCtr,tube_width,sdd,lambda,coefW)

//	qx_val = CalcQx(p+1,q+1,xCtr,yCtr,sdd/100,lambda,pixSize)		//+1 converts to detector coordinate system
//	qy_val = CalcQy(p+1,q+1,xCtr,yCtr,sdd/100,lambda,pixSize)		//need to convert SDD from cm to m
	
	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val


	Variable L2 = getDet_Distance(type) / 100		// N_getResolution is expecting [m]
	Variable BS = getBeamStop_size(type)
	Variable S1 = getSourceAp_size(type)
	Variable S2 = getSampleAp_size(type)
	Variable L1 = getSourceAp_distance(type) / 100 // N_getResolution is expecting [m]
	Variable lambdaWidth = getWavelength_spread(type)
	Variable usingLenses = 0		//new 2007

	if(cmpstr(getLensPrismStatus(type),"out") == 0 )		// TODO -- this read function is HARD-WIRED
		// lenses and prisms are out
		usingLenses = 0
	else
		usingLenses = 1
	endif
	
	
	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]
	Variable m_h	= 252.8			// m/h [=] s/cm^2

	Variable acc,ssd,lambda0,yg_d,qstar
		
	G = 981.  //!	ACCELERATION OF GRAVITY, CM/SEC^2
	acc = vz_1 		//	3.956E5 //!	CONVERT WAVELENGTH TO VELOCITY CM/SEC
	SDD = L2	*100	//1317
	SSD = L1	*100	//1627 		//cm
	lambda0 = lambda		//		15
	YG_d = -0.5*G*SDD*(SSD+SDD)*(LAMBDA0/acc)^2
	qstar = -2*pi/lambda0*2*yg_d/sdd


	// the gravity center is not the resolution center
	// gravity center = beam center
	// resolution center = offset y = dy + (2)*yg_d
	///************
	// do everything to write out the resolution too
	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	
	qval = T_CalcQval(p+1,q+1,xCtr,yCtr,tube_width,sdd,lambda,coefW)
	qz_val = T_CalcQz(p+1,q+1,xCtr,yCtr,tube_width,sdd,lambda,coefW)
	//	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr))		//(dx,dy)
	//	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr))^2 )		//radial distance from ctr to pt
	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt
	Redimension/N=(pixelsX*pixelsY) qz_val,qval,phi,r_dist
	Make/O/N=(2,pixelsY,pixelsX) qxy_vals
	//everything in 1D now
	Duplicate/O qval SigmaQX,SigmaQY
	Make/O/N=(pixelsY,pixelsX) shadow
	Make/O/N=(2,pixelsY,pixelsX) SigmaQ_combined

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current good values
	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	DDet = getDet_x_pixel_size(type)/10			// header value (X) is in mm, want cm here

	Variable ret1,ret2,ret3,jj
	Variable nq = 0
	Variable ii = 0
	
	do
		jj = 0
		do
			nq = ii * pixelsX + jj
			N_get2DResolution(qval[nq],phi[nq],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,pixSize,usingLenses,r_dist[nq],ret1,ret2,ret3)
			qxy_vals[0][jj][ii] = qx_val[nq]
			qxy_vals[1][jj][ii] = qy_val[nq]
			SigmaQ_combined[0][jj][ii] = ret1
			SigmaQ_combined[1][jj][ii] = ret2
			shadow[jj][ii] = ret3
			jj+=1
		while(jj<pixelsY)
		ii+=1
	while(ii<pixelsX)
	//
	///////////////////////////////////////////////////////////////////////////

	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(parentBase)
	Make/O/T/N=1 $(parentBase + ":title") = {getSampleDescription(type)}  		//{textw[6]}
	CreateStrNxCansas(fileID,nxcansasBase,"","title",$(parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(parentBase + ":run") = {getTitle(type)}		//{textW[0]}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(parentBase + ":run"),empty,empty)
	
	// SASData
	String dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	String dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q,Q","NXdata","0,1",getDataStartTime(type)}		//textW[1]
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
	
	// Write all meta data
	WriteMetaData(fileID,parentBase,nxcansasBase,type)
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	
	Print "Wrote NXCanSAS2D data file ",fullpath
	KillDataFolder/Z $base
	
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// - WriteMetaData - Method used to write non data elements into NXcanSAS
// format. This is common between 1D and 2D data sets.

Function WriteMetaData(fileID,base,parentBase,type)
	Variable fileID
	String base,parentBase,type
	
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
	
	// SASaperture
	String apertureParent = instrParent + "sasaperture/"
	// Create SASaperture entry
	String apertureBase = instrumentBase + ":sasaperture"
	NewDataFolder/O/S $(apertureBase)
	Make/O/T/N=5 $(apertureBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(apertureBase + ":attrVals") = {"SASaperture","NXaperture"}
	CreateStrNxCansas(fileID,apertureParent,"","",empty,$(apertureBase + ":attr"),$(apertureBase + ":attrVals"))
	// Create SASaperture shape entry
	Make/O/T/N=1 $(apertureBase + ":shape") = {"pinhole"} 
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {getSampleAp_size(type)}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,mm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {getSampleAp_size(type)}
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
	Make/O/N=1 $(collimationBase + ":distance") = {getSourceAp_distance(type) / 100}		//be sure units are [m]
	CreateVarNxCansas(fileID,collimationParent,"sasaperture","distance",$(collimationBase + ":distance"),units,m)
	
	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {getInstrumentNameFromFile(type)}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {getDet_Distance(type)/100}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,m)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {getDet_beam_center_x(type)}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,pixel)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {getDet_beam_center_y(type)}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,pixel)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {getDet_x_pixel_size(type)}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {getDet_y_pixel_size(type)}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
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
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {getWavelength(type)}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {getWavelength_spread(type)}
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
	Make/O/T/N=1 $(sampleBase + ":name") = {getSampleDescription(type)	}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {getSampleThickness(type)}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {getSampleTransmission(type)}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
End

Function WriteProcess(fileID,parentBase,base,processName,processNote)
	Variable fileID
	String parentBase,base,processName,processNote
	// Create SASprocess entry
	Make/T/O/N=1 empty = {""}
	String processParent = parentBase + "sasprocess/"
	String processBase = base + ":sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=5 $(processBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(processBase + ":attrVals") = {"SASprocess","NXprocess"}
	CreateStrNxCansas(fileID,processParent,"","",empty,$(processBase + ":attr"),$(processBase + ":attrVals"))
	// Create SASprocess name entry
	Make/O/T/N=1 $(processBase + ":name") = {processName}
	CreateStrNxCansas(fileID,processParent,"","name",$(processBase + ":name"),empty,empty)
	// Create SASprocess note entries
	Make/O/T/N=1 $(processBase + ":note0") = {processNote}
	CreateStrNxCansas(fileID,processParent,"","note0",$(processBase + ":note0"),empty,empty)
End


///////////////////////////////////////////////////////////////////////////
//
// Methods related to NSORT


//these canSANs NSORT files are only necessary for SANS reduction, not USANS or VSANS. as such, 
// move them to the SANS-specific NXcanSAS file. Conditional compilation did not work since I can't access
// user-defined objects through #if
//
// SRK 092019
//

Function WriteNSORTedNXcanSASFile(qw,iw,sw,firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34,[res])
	Wave qw,iw,sw,res
	String firstFileName,secondFileName,thirdFileName,fourthFileName,normTo
	Variable norm12,norm23,norm34
	
	Variable err=0,refNum,numCols,dialog=1,useRes=0
	String fullPath="",formatStr="",process
	
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
		useRes = 1
	endif
	
	NVAR/Z useTable = root:myGlobals:CombineTable:useTable
	if(NVAR_Exists(useTable) && useTable==1)
		SVAR str=root:myGlobals:CombineTable:SaveNameStr	//messy, but pass in as a global
		fullPath = str
		dialog=0
	endif
	
	NewDataFolder/O/S root:Packages:NIST:NSORT
	SetDataFolder root:Packages:NIST:NSORT
	
	process = CreateNSORTProcess(firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
	Make/O/T/N=1 processNote = process
	
	Variable pts = numpnts(qw)
	Make/O/N=(pts) qval = qw
	Make/O/N=(pts) aveint = iw
	Make/O/N=(pts) sigave = sw
	if (useRes)
		Make/O/N=(dimsize(res,0)) SigmaQ = res[p][0]
		Make/O/N=(dimsize(res,0)) QBar = res[p][1]
		Make/O/N=(dimsize(res,0)) fSubS = res[p][2]
	Else
		Make/O/N=(pts) SigmaQ = 0
		Make/O/N=(pts) QBar = 0
		Make/O/N=(pts) fSubS = 0
	EndIf
	
//	Make/O/T/N=11 textRead
//	textRead[6] = firstfileName
//	textRead[0] = "Combined data"
//	
//	Make/O/N=52 realsRead = 0
	
	WriteNxCanSAS1D("NSORT",fullpath,dialog)
	
End


Function/T CreateNSORTProcess(firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34)
	String firstFileName,secondFileName,thirdFileName,fourthFileName,normTo
	Variable norm12,norm23,norm34
	String process
	String processFormat = "COMBINED FILE CREATED: %s - NSORT-ed %s\t+ %s\t+ %s\t+%s, normalized to %s, multiplicative factor 1-2 = %12.8g\t multiplicative factor 2-3 = %12.8g\t multiplicative factor 3-4 = %12.8g"
	
	sprintf process,processFormat,date(),firstFileName,secondFileName,thirdFileName,fourthFileName,normTo,norm12,norm23,norm34
	return process
End

//


//
///////////////////////////////////////////////////////////////////////////

