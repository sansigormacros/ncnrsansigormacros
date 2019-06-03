#pragma rtGlobals=1		// Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1

#include <HDF5 Browser>

//////////////////////////////////////////////////////////////////////////////////
//
// Write out an NXcanSAS compliant file using all known USANS information

//************************
// Vers 1.00 20190603
//
//************************

//
Function WriteUSANSNXcanSAS(type,fullpath,lo,hi,dialog)
	
	String type,fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR dQv = root:Packages:NIST:USANS:Globals:MainPanel:gDQv
	
	Variable fileID
	String destStr=""
	destStr = USANSFolder+":"+type
	String dateStr=date()+" "+time()

	String parentBase = "/sasentry/" // HDF5 base path for all 
	String/G base = "root:NXcanSAS_USANS_file"
	
	KillDataFolder/Z $base
	
	// Define common attribute waves
	Make/T/N=1 empty = {""}
	Make/T/N=1 units = {"units"}
	Make/T/N=1 m = {"m"}
	Make/T/N=1 mm = {"mm"}
	Make/T/N=1 cm = {"cm"}
	Make/T/N=1 angstrom = {"A"}
	Make/T/N=1 inv_cm = {"1/cm"}
	Make/T/N=1 inv_angstrom = {"1/A"}
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE qvals =$(destStr + ":Qvals")
	WAVE inten=$(destStr + ":DetCts")
	WAVE sig=$(destStr + ":ErrDetCts")
		
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		fileID = NxCansas_CreateFile(fullpath)
	Endif
	
	//check each wave
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist in WriteUSANSWaves()"
	Endif
	
	//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
	Duplicate/O qvals,dumWave
	dumWave = dQv
	
	Make/N= (numpnts(dumWave)) dQw = 0
	
	// Run Name and title
	NewDataFolder/O/S $(base + ":entry1")
	Make/T/N=1 $(base + ":entry1:title") = {StringByKey("LABEL",note(inten),":",";")}
	CreateStrNxCansas(fileID,parentBase,"","title",$(base + ":entry1:title"),empty,empty)
	Make/T/N=1 $(base + ":entry1:run") = {""}
	CreateStrNxCansas(fileID,parentBase,"","run",$(base + ":entry1:run"),empty,empty)
	
	// SASData
	String dataParent = parentBase + "sasdata/"
	// Create SASdata entry
	String dataBase = base + ":entry1:sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0",dateStr}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","dQl,dQw"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",tq,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",ti,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",te,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","dQl",dumWave,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","dQw",dQw,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",res2,units,inv_angstrom)
	
	//
	//////////////////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////////////////
	//
	// Write USANS meta data
	
	
	//tailor the output given the type of data written out...
	WAVE inten_EMP=$(USANSFolder+":EMP:DetCts")
	String samStr="",empStr="",samLabelStr="",paramStr="",empLevStr="",bkgLevStr=""
	String pkStr="", processNote=""
	NVAR TransWide = $(USANSFolder+":Globals:MainPanel:gTransWide")
	NVAR TransRock = $(USANSFolder+":Globals:MainPanel:gTransRock")
	NVAR empCts = $(USANSFolder+":Globals:MainPanel:gEmpCts")
	NVAR bkgCts = $(USANSFolder+":Globals:MainPanel:gBkgCts")
	NVAR thick = $(USANSFolder+":Globals:MainPanel:gThick")
	
	strswitch(type)
		case "SAM":		
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "Uncorrected SAM data"
			empLevStr = "Uncorrected SAM data"
			bkgLevStr = "Uncorrected SAM data"
			paramStr = "Uncorrected SAM data"
			pkStr += "SAM PEAK ANGLE: "+num2str(QpkFromNote("SAM"))
			break						
		case "EMP":	
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "Uncorrected EMP data"
			empLevStr = "Uncorrected EMP data"
			bkgLevStr = "Uncorrected EMP data"
			paramStr = "Uncorrected EMP data"
			pkStr += "EMP PEAK ANGLE: "+num2str(QpkFromNote("EMP"))
			break
		default:		//"COR" is the default	
			samStr = type +" FILES: "+StringByKey("FILE",note(inten),":",";")
			empStr = "EMP FILES: "+StringByKey("FILE",note(inten_EMP),":",";")	
			empLevStr = "EMP LEVEL: " + num2str(empCts)
			bkgLevStr = "BKG LEVEL: " + num2str(bkgCts)
			paramStr = "Ds = "+num2str(thick)+" cm ; "
			paramStr += "Twide = "+num2Str(TransWide)+" ; "
			paramStr += "Trock = "+num2str(TransRock)	
			pkStr += "SAM PEAK ANGLE: "+num2str(QpkFromNote("SAM"))
			pkStr += " ; EMP PEAK ANGLE: "+num2str(QpkFromNote("EMP"))				
	endswitch

	processNote = samStr+"\n"+dateStr+"\n"+samLabelStr+"\n"+empStr+"\n"+paramStr+"\n"+pkStr+"\n"
	processNote += empLevStr + " ; "+bkglevStr+"\n"
	
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
	Make/O/T/N=1 $(apertureBase + ":shape") = {"slit"} 
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {0.1}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,cm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {5.0}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,cm)

	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"BT5 DETECTOR ARRAY"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	
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
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {2.38}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {0.06}
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
	Make/O/T/N=1 $(sampleBase + ":name") = {StringByKey("LABEL",note(inten),":",";")}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {thick}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {TransWide}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	// SASProcess
	String processParent = parentBase + "sasprocess/"
	// Create SASsample entry
	String processBase = base + ":entry1:sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=5 $(processBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(processBase + ":attrVals") = {"SASprocess","NXprocess"}
	CreateStrNxCansas(fileID,processParent,"","",empty,$(processBase + ":attr"),$(processBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(processBase + ":name") = {"NIST IGOR"}
	CreateStrNxCansas(fileID,processParent,"","name",$(processBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/T/N=1 $(sampleBase + ":note") = {processNote}
	CreateVarNxCansas(fileID,processParent,"","note",$(processBase + ":note"),units,cm)
	
	//write confirmation of write operation to history area
	Print "Averaged XML File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z dumWave
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
End


Function WriteNXcanSASUSANSDesmeared(fullpath,lo,hi,dialog)
	
	String fullpath
	Variable lo,hi,dialog		//=1 will present dialog for name
	
	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR dQv = root:Packages:NIST:USANS:Globals:MainPanel:gDQv
	
	Variable fileID
	String destStr=""
	destStr = USANSFolder+":Smeared"
	String dateStr=date()+" "+time()

	String parentBase = "/sasentry/" // HDF5 base path for all 
	String/G base = "root:NXcanSAS_USANS_file"
	
	KillDataFolder/Z $base
	
	// Define common attribute waves
	Make/T/N=1 empty = {""}
	Make/T/N=1 units = {"units"}
	Make/T/N=1 m = {"m"}
	Make/T/N=1 mm = {"mm"}
	Make/T/N=1 cm = {"cm"}
	Make/T/N=1 angstrom = {"A"}
	Make/T/N=1 inv_cm = {"1/cm"}
	Make/T/N=1 inv_angstrom = {"1/A"}
	
	Variable refNum,integer,realval
	
	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE qvals =$(destStr + "Q_dsm")
	WAVE inten=$(destStr + "I_dsm")
	WAVE sig=$(destStr + "S_dsm")
		
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		fileID = NxCansas_CreateFile(fullpath)
	Endif
	
	//check each wave
	If(!(WaveExists(qvals)))
		Abort "qvals DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(inten)))
		Abort "inten DNExist in WriteUSANSWaves()"
	Endif
	If(!(WaveExists(sig)))
		Abort "sig DNExist in WriteUSANSWaves()"
	Endif
	
	//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
	//write out partial set?
	Duplicate/O qvals,tq,ti,te
	ti=inten
	te=sig
	if( (lo!=hi) && (lo<hi))
		redimension/N=(hi-lo+1) tq,ti,te,res1,res2,res3		//lo to hi, inclusive
		tq=qvals[p+lo]
		ti=inten[p+lo]
		te=sig[p+lo]
	endif
	
	Make/N= (numpnts(dumWave)) dQw = 0
	
	// Run Name and title
	NewDataFolder/O/S $(base + ":entry1")
	Make/T/N=1 $(base + ":entry1:title") = {StringByKey("LABEL",note(inten),":",";")}
	CreateStrNxCansas(fileID,parentBase,"","title",$(base + ":entry1:title"),empty,empty)
	Make/T/N=1 $(base + ":entry1:run") = {""}
	CreateStrNxCansas(fileID,parentBase,"","run",$(base + ":entry1:run"),empty,empty)
	
	// SASData
	String dataParent = parentBase + "sasdata/"
	// Create SASdata entry
	String dataBase = base + ":entry1:sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0",dateStr}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","dQ"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",tq,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",ti,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",te,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","dQl",dumWave,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","dQw",res1,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",res2,units,inv_angstrom)
	
	//
	//////////////////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////////////////
	//
	// Write USANS meta data
	
	
	//tailor the output given the type of data written out...
	WAVE inten_EMP=$(USANSFolder+":EMP:DetCts")
	String samStr="",empStr="",samLabelStr="",paramStr="",empLevStr="",bkgLevStr=""
	String pkStr="", processNote=""
	NVAR TransWide = $(USANSFolder+":Globals:MainPanel:gTransWide")
	NVAR TransRock = $(USANSFolder+":Globals:MainPanel:gTransRock")
	NVAR empCts = $(USANSFolder+":Globals:MainPanel:gEmpCts")
	NVAR bkgCts = $(USANSFolder+":Globals:MainPanel:gBkgCts")
	NVAR thick = $(USANSFolder+":Globals:MainPanel:gThick")
	
	samStr = "SMEARED FILES: "+StringByKey("FILE",note(inten),":",";")
	empStr = "EMP FILES: "+StringByKey("FILE",note(inten_EMP),":",";")	
	empLevStr = "EMP LEVEL: " + num2str(empCts)
	bkgLevStr = "BKG LEVEL: " + num2str(bkgCts)
	paramStr = "Ds = "+num2str(thick)+" cm ; "
	paramStr += "Twide = "+num2Str(TransWide)+" ; "
	paramStr += "Trock = "+num2str(TransRock)	
	pkStr += "SAM PEAK ANGLE: "+num2str(QpkFromNote("SAM"))
	pkStr += " ; EMP PEAK ANGLE: "+num2str(QpkFromNote("EMP"))

	processNote = samStr+"\n"+dateStr+"\n"+samLabelStr+"\n"+empStr+"\n"+paramStr+"\n"+pkStr+"\n"
	processNote += empLevStr + " ; "+bkglevStr+"\n"
	
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
	Make/O/T/N=1 $(apertureBase + ":shape") = {"slit"} 
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {0.1}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,cm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {5.0}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,cm)

	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"BT5 DETECTOR ARRAY"}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	
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
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {2.38}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {0.06}
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
	Make/O/T/N=1 $(sampleBase + ":name") = {StringByKey("LABEL",note(inten),":",";")}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {thick}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {TransWide}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
	
	// SASProcess
	String processParent = parentBase + "sasprocess/"
	// Create SASsample entry
	String processBase = base + ":entry1:sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=5 $(processBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(processBase + ":attrVals") = {"SASprocess","NXprocess"}
	CreateStrNxCansas(fileID,processParent,"","",empty,$(processBase + ":attr"),$(processBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(processBase + ":name") = {"NIST IGOR"}
	CreateStrNxCansas(fileID,processParent,"","name",$(processBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/T/N=1 $(sampleBase + ":note") = {processNote}
	CreateVarNxCansas(fileID,processParent,"","note",$(processBase + ":note"),units,cm)
	
	//write confirmation of write operation to history area
	Print "Averaged XML File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z dumWave
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
End	
