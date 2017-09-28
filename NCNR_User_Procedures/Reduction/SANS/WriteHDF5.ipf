#pragma rtGlobals=3		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

#include <HDF5 Browser>

//************************
// Vers 0.75 20170717
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
	String destStr=""
	String parentBase = "/sasentry/" // HDF5 base path for all 
	String/G base = "root:NXcanSAS_file"
	
	KillDataFolder/Z $base
	
	// Define local waves
	Wave/T vals,attr,attrVals,textw
	Wave intw,rw,qvals,inten,sig,qbar,sigmaq,fsubs
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	// Check fullpath and dialog
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		NxCansas_CreateFile(fullpath)
	Endif
	if(!fileID)
		Print "Unable to create file at " + fullpath + "."
	else
		if(stringmatch(type,""))
			// Test values for each data set
			Make/N=9 intw = {0,180.0,23,6254,16547,6178,22,2,0}
			Make/N=50 rw = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			Make/T/N=2 textw= {"","","","","","","","","","",""}
			Make/N=10 qvals = {1,1,1,1,1,1,1,1,1,1} // qvals, inten, siq, qbar, sigmaq must be same length
			Make/N=10 inten = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
			Make/N=10 sig = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
 			Make/N=10 qbar = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
  			Make/N=10 sigmaq = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
 			Make/N=10 fsubs = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
		else
			destStr = "root:Packages:NIST:"+type
	
			Variable refNum
			Variable step=1
	
			//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
			WAVE intw = $(destStr + ":integersRead")
			WAVE rw = $(destStr + ":realsRead")
			WAVE/T textw=$(destStr + ":textRead")
			WAVE qvals =$(destStr + ":qval")
			WAVE inten=$(destStr + ":aveint")
			WAVE sig=$(destStr + ":sigave")
 			WAVE qbar = $(destStr + ":QBar")
  			WAVE sigmaq = $(destStr + ":SigmaQ")
 			WAVE fsubs = $(destStr + ":fSubS")
 		endif
	endif

	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/T/N=1 empty = {""}
	Make/T/N=1 units = {"units"}
	Make/T/N=1 m = {"m"}
	Make/T/N=1 mm = {"mm"}
	Make/T/N=1 cm = {"cm"}
	Make/T/N=1 pixel = {"pixel"}
	Make/T/N=1 angstrom = {"A"}
	Make/T/N=1 inv_cm = {"1/cm"}
	Make/T/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(base + ":entry1")
	Make/T/N=1 $(base + ":entry1:title") = {textw[6]}
	CreateStrNxCansas(fileID,parentBase,"","title",$(base + ":entry1:title"),empty,empty)
	Make/T/N=1 $(base + ":entry1:run") = {textw[0]}
	CreateStrNxCansas(fileID,parentBase,"","run",$(base + ":entry1:run"),empty,empty)
	
	// SASData
	String dataParent = parentBase + "sasdata/"
	// Create SASdata entry
	String dataBase = base + ":entry1:sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0,1",textw[1]}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","Qdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qvals,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",inten,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",sig,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",sigmaq,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",qbar,units,inv_angstrom)
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	// Create SASinstrument entry
	String instrumentBase = base + ":entry1:sasinstrument"
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
	Make/O/T/N=1 $(apertureBase + ":shape") = {"pinhole"} // TODO: Where do I get rectangular dimensions from?
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {rw[24]} // TODO: Where do I get rectangular dimensions from?
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,cm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {rw[24]} // TODO: Where do I get rectangular dimensions from?
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,cm)
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	// Create SAScollimation entry
	String collimationBase = instrumentBase + ":sascollimation"
	NewDataFolder/O/S $(collimationBase)
	Make/O/T/N=5 $(collimationBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(collimationBase + ":attrVals") = {"SAScollimation","NXcollimator"}
	CreateStrNxCansas(fileID,collimationParent,"","",empty,$(collimationBase + ":attr"),$(collimationBase + ":attrVals"))
	// Create SAScollimation length entry
	Make/O/N=1 $(collimationBase + ":length") = {15.3} // TODO: Get real value
	CreateVarNxCansas(fileID,collimationParent,"sasaperture","length",$(collimationBase + ":length"),units,m)
	// Create SAScollimation distance entry
	Make/O/N=1 $(collimationBase + ":distance") = {rw[25]}
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
	Make/O/T/N=1 $(detectorBase + ":name") = {textw[9]}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {rw[18]}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,m)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {rw[16]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,pixel)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {rw[17]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,pixel)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {rw[10]}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {rw[13]}
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
	Make/O/T/N=1 $(sourceBase + ":radiation") = {"Reactor Neutron Source"}
	CreateStrNxCansas(fileID,sourceParent,"","radiation",$(sourceBase + ":radiation"),empty,empty)
	// Create SASsource incident_wavelength entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {rw[26]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {rw[27]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength_spread",$(sourceBase + ":incident_wavelength_spread"),units,angstrom)
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	// Create SASsample entry
	String sampleBase = base + ":entry1:sassample"
	NewDataFolder/O/S $(sampleBase)
	Make/O/T/N=5 $(sampleBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sampleBase + ":attrVals") = {"SASsample","NXsample"}
	CreateStrNxCansas(fileID,sampleParent,"","",empty,$(sampleBase + ":attr"),$(sampleBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(sampleBase + ":name") = {textw[6]}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {rw[5]}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {rw[4]}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	// KillDataFolder/Z $base
	
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
	Variable step=1,refnum
	String destStr="",typeStr=""
	String parentBase = "/sasentry/" // HDF5 base path for all 
	String/G base = "root:NXcanSAS_file"
	
	KillDataFolder/Z $base
	
	// Define local waves
	Wave/T vals,attr,attrVals,textw
	Wave intw,rw,qvals,inten,sig,qbar,sigmaq,fsubs
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	// Check fullpath and dialog
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		NxCansas_CreateFile(fullpath)
	Endif
	if(!fileID)
		Print "Unable to create file at " + fullpath + "."
	else
		if(stringmatch(type,""))
			
			// TODO: Change the simulated data variables to match those for 2D data
			
			// Test values for each data set
			Make/N=9 intw = {0,180.0,23,6254,16547,6178,22,2,0}
			Make/N=5 rw = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			Make/T/N=2 textw= {"","","","","","","","","","",""}
			Make/N=10 qvals = {1,1,1,1,1,1,1,1,1,1} // qvals, inten, siq, qbar, sigmaq must be same length
			Make/N=10 inten = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
			Make/N=10 sig = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
 			Make/N=10 qbar = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
  			Make/N=10 sigmaq = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
 			Make/N=10 fsubs = {0,0,0,0,0,0,0,0,0,0} // qvals, inten, siq, qbar, sigmaq must be same length
		else
			destStr = "root:Packages:NIST:"+type
	
			//must select the linear_data to export
			NVAR isLog = $(destStr+":gIsLogScale")
			if(isLog==1)
				typeStr = ":linear_data"
			else
				typeStr = ":data"
			endif
	
			NVAR pixelsX = root:myGlobals:gNPixelsX
			NVAR pixelsY = root:myGlobals:gNPixelsY
	
			Wave data=$(destStr+typeStr)
			Wave data_err=$(destStr+":linear_data_error")
			WAVE intw=$(destStr + ":integersRead")
			WAVE rw=$(destStr + ":realsRead")
			WAVE/T textw=$(destStr + ":textRead")
			
 		endif
	endif
	
	///////////////////////////////////////////////////////////////////////////
	// Compute Qx, Qy data from pixel space
	
	Duplicate/O data,qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
	
	Variable xctr,yctr,sdd,lambda,pixSize
	xctr = rw[16]
	yctr = rw[17]
	sdd = rw[18]
	lambda = rw[26]
	pixSize = rw[13]/10		//convert mm to cm (x and y are the same size pixels)
	
	qx_val = CalcQx(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)		//+1 converts to detector coordinate system
	qy_val = CalcQy(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	
	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val

	Variable L2 = rw[18]
	Variable BS = rw[21]
	Variable S1 = rw[23]
	Variable S2 = rw[24]
	Variable L1 = rw[25]
	Variable lambdaWidth = rw[27]	
	Variable usingLenses = rw[28]		//new 2007

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
	Print "DISTANCE BEAM FALLS DUE TO GRAVITY (CM) = ",YG_d
	//		Print "Gravity q* = ",-2*pi/lambda0*2*yg_d/sdd
	qstar = -2*pi/lambda0*2*yg_d/sdd

	// the gravity center is not the resolution center
	// gravity center = beam center
	// resolution center = offset y = dy + (2)*yg_d
	///************
	// do everything to write out the resolution too
	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	qval = CalcQval(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	qz_val = CalcQz(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	//	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr))		//(dx,dy)
	//	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr))^2 )		//radial distance from ctr to pt
	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt
	Redimension/N=(pixelsX*pixelsY) qz_val,qval,phi,r_dist
	//everything in 1D now
	Duplicate/O qval SigmaQX,SigmaQY,fsubS

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current good values
	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	DDet = rw[10]/10			// header value (X) is in mm, want cm here

	Variable ret1,ret2,ret3,nq
	nq = pixelsX*pixelsY
	Variable ii = 0
	
	do
		get2DResolution(qval[ii],phi[ii],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,pixSize,usingLenses,r_dist[ii],ret1,ret2,ret3)
		SigmaQX[ii] = ret1	
		SigmaQY[ii] = ret2	
		fsubs[ii] = ret3	
		ii+=1
	while(ii<nq)
	//
	///////////////////////////////////////////////////////////////////////////

	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/T/N=1 empty = {""}
	Make/T/N=1 units = {"units"}
	Make/T/N=1 m = {"m"}
	Make/T/N=1 mm = {"mm"}
	Make/T/N=1 cm = {"cm"}
	Make/T/N=1 pixel = {"pixel"}
	Make/T/N=1 angstrom = {"A"}
	Make/T/N=1 inv_cm = {"1/cm"}
	Make/T/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(base + ":entry1")
	Make/T/N=1 $(base + ":entry1:title") = {textw[6]}
	CreateStrNxCansas(fileID,parentBase,"","title",$(base + ":entry1:title"),empty,empty)
	Make/T/N=1 $(base + ":entry1:run") = {textw[0]}
	CreateStrNxCansas(fileID,parentBase,"","run",$(base + ":entry1:run"),empty,empty)
	
	// SASData
	String dataParent = parentBase + "sasdata/"
	// Create SASdata entry
	String dataBase = base + ":entry1:sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Qx,Qy","NXdata","0,1",textw[1]}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",data,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create qx and qy entry
	NewDataFolder/O/S $(dataBase + ":qx")
	Make/T/N=2 $(dataBase + ":qx:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":qx:attrVals") = {"1/angstrom","Qxdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qx",qx_val,$(dataBase + ":qx:attr"),$(dataBase + ":qx:attrVals"))
	NewDataFolder/O/S $(dataBase + ":qy")
	Make/T/N=2 $(dataBase + ":qy:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":qy:attrVals") = {"1/angstrom","Qydev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qy",qy_val,$(dataBase + ":qy:attr"),$(dataBase + ":qy:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",data_err,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qxdev",SigmaQX,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qydev",SigmaQY,units,inv_angstrom)
	// Create shadwfactor entry
	
	// TODO: Reinstate ShadowFactor
	
	// CreateVarNxCansas(fileID,dataParent,"sasdata","ShadowFactor",fsubs,empty,empty)
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	// Create SASinstrument entry
	String instrumentBase = base + ":entry1:sasinstrument"
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
	Make/O/T/N=1 $(apertureBase + ":shape") = {"pinhole"} // TODO: Where do I get rectangular dimensions from?
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {rw[24]} // TODO: Where do I get rectangular dimensions from?
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,cm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {rw[24]} // TODO: Where do I get rectangular dimensions from?
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,cm)
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	// Create SAScollimation entry
	String collimationBase = instrumentBase + ":sascollimation"
	NewDataFolder/O/S $(collimationBase)
	Make/O/T/N=5 $(collimationBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(collimationBase + ":attrVals") = {"SAScollimation","NXcollimator"}
	CreateStrNxCansas(fileID,collimationParent,"","",empty,$(collimationBase + ":attr"),$(collimationBase + ":attrVals"))
	// Create SAScollimation length entry
	Make/O/N=1 $(collimationBase + ":length") = {15.3} // TODO: Get real value
	CreateVarNxCansas(fileID,collimationParent,"sasaperture","length",$(collimationBase + ":length"),units,m)
	// Create SAScollimation distance entry
	Make/O/N=1 $(collimationBase + ":distance") = {rw[25]}
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
	Make/O/T/N=1 $(detectorBase + ":name") = {textw[9]}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {rw[18]}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,m)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {rw[16]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,pixel)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {rw[17]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,pixel)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {rw[10]}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {rw[13]}
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
	Make/O/T/N=1 $(sourceBase + ":radiation") = {"Reactor Neutron Source"}
	CreateStrNxCansas(fileID,sourceParent,"","radiation",$(sourceBase + ":radiation"),empty,empty)
	// Create SASsource incident_wavelength entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {rw[26]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {rw[27]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength_spread",$(sourceBase + ":incident_wavelength_spread"),units,angstrom)
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	// Create SASsample entry
	String sampleBase = base + ":entry1:sassample"
	NewDataFolder/O/S $(sampleBase)
	Make/O/T/N=5 $(sampleBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sampleBase + ":attrVals") = {"SASsample","NXsample"}
	CreateStrNxCansas(fileID,sampleParent,"","",empty,$(sampleBase + ":attr"),$(sampleBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(sampleBase + ":name") = {textw[6]}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {rw[5]}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {rw[4]}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	// KillDataFolder/Z $base
	
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Basic file open and initialization routines

// Select/create file through prompt
Function NxCansas_DoSaveFileDialog()
	Variable refNum, fileID
	String message = "Save a file"
	String outputPath
	String fileFilters = "Data Files (*.h5):.h5;"
	fileFilters += "All Files:.*;"
	Open /D /F=fileFilters /M=message refNum
	outputPath = S_fileName
	fileID = NxCansas_CreateFile(outputPath)
	return fileID
End

// Create file with a known path
Function NxCansas_CreateFile(fullpath)
	String fullpath
	Variable fileID
	print fullPath
	fullpath = ReplaceString(":\\", fullpath, ":")
	print fullPath
	fullpath = ReplaceString("\\", fullpath, ":")
	print fullPath
	HDF5CreateFile /Z fileID as fullpath
	NXCansas_InitializeFile(fileID)
	return fileID
End

// Initialize the file to a base state
Function NxCansas_InitializeFile(fileID)
	Variable fileID
	String parent
	String/G base = "root:NXcanSAS_file"
	Make/T/N=1 $(base + ":vals") = {""}
	Make/T/N=3 $(base + ":attr") = {"NX_class", "canSAS_class", "version"}
	Make/T/N=3 $(base + ":attrVals") = {"NXentry", "SASentry", "1.0"}
	parent = "/sasentry/"
	CreateStrNxCansas(fileID,parent,"","",$(base + ":vals"),$(base + ":attr"),$(base + ":attrVals"))
	Make/T/N=1 $(base + ":entryAttr") = {""}
	Make/T/N=1 $(base + ":entryAttrVals") = {""}
	CreateStrNxCansas(fileID,parent,"","definition",NxCansas_strPtToWave("NXcanSAS"),$(base + ":entryAttr"),$(base + ":entryAttrVals"))
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Functions to put values into usable form for NxCansas

// Convert a number to a string
Function /WAVE NxCansas_varToWave(number)
	Variable number
	Wave returnWave
	Make/N=1 returnWave = {number}
	return returnWave
End

// Create a single point wave from a string
Function /WAVE NxCansas_strPtToWave(str)
	String str
	Wave/T returnWave
	Make/T/N=1 returnWave = {str}
	return returnWave
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Functions used to save data to file

// Intermediate error handler for saving variable waves - this function should be called instead of saveNxCansas
Function CreateVarNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	Variable err
	err = saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End
// Intermediate error handler for saving string waves - this function should be called instead of saveNxCansas
Function CreateStrNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T valueWave,attr,attrValues
	Variable err
	err = saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End

Function NxCansas_writeAttributes(fileID,path,attrNames,attrVals)
	Variable fileID
	String path
	Wave/T attrNames, attrVals
	int numAttrs,i
	numAttrs = numpnts(attrNames)
	Duplicate/O/T attrNames, names
	Duplicate/O/T attrVals, vals
	
	for(i=0; i < numAttrs; i += 1)
		String name_i = names[i]
		String vals_i = vals[i]
		Make/T/N=1 vals_i_wave
		vals_i_wave[0] = vals_i
		if(!stringmatch(name_i,""))
			HDF5SaveData /A=name_i vals_i_wave, fileID, path
		endif
	endfor
	
End

Function NxCansas_CreateGroup(fileID,parent)
	Variable fileID
	String parent
	Variable groupID
	try	
		if(!fileID)
			abort "HDF5 file does not exist"
		endif
		
		// Create the group if it doesn't already exist
		HDF5CreateGroup /Z fileID, parent, groupID
			
	catch
		// DO something if error is thrown
		Print "NxCansas write err in saveNxCansas = ",V_AbortCode
	endtry
	return groupID
End

// Write in a single NxCansas element (from the STRUCTURE)
// This method should only be called by CreateVarNxCansas
Function saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)

	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
		
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

// Write in a single NxCansas element
// This method should only be called by CreateStrNxCansas
Function saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T attr,attrValues, valueWave
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)

	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
		
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

//
///////////////////////////////////////////////////////////////////////////
