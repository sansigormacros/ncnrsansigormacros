#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.
#pragma Version=2.20
#pragma IgorVersion=6.1

#if (IgorVersion() < 9)
#include <HDF5 Browser>
#endif

//////////////////////////////////////////////////////////////////////////////////
//
// Write out an NXcanSAS compliant file using all known USANS information

//************************
// Vers 1.03 20190617
//
//************************

//
// dialog=1 will present dialog for name
Function WriteUSANSNXcanSAS(string type, string fullpath, variable lo, variable hi, variable dialog)

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR dQv         = root:Packages:NIST:USANS:Globals:MainPanel:gDQv

	variable fileID
	string destStr = USANSFolder + ":" + type
	string dateStr = date() + " " + time()

	string parentBase, nxcansasBase
	string/G base = "root:NXcanSAS_USANS_file"

	variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase, "%s:sasentry%d", base, sasentry // Igor memory base path for all
	sPrintf nxcansasBase, "/sasentry%d/", sasentry // HDF5 base path for all

	NewDataFolder/O/S $(base)

	// Define common attribute waves
	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 m = {"m"}
	Make/O/T/N=1 mm = {"mm"}
	Make/O/T/N=1 cm = {"cm"}
	Make/O/T/N=1 angstrom = {"A"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}

	variable refNum, integer, realval

	fileID = NXcanSAS_OpenOrCreate(dialog, fullpath, base)

	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE qvals = $(destStr + ":Qvals")
	WAVE inten = $(destStr + ":DetCts")
	WAVE sig   = $(destStr + ":ErrDetCts")

	//check each wave
	if(!(WaveExists(qvals)))
		Abort "qvals DNExist in WriteUSANSWaves()"
	endif
	if(!(WaveExists(inten)))
		Abort "inten DNExist in WriteUSANSWaves()"
	endif
	if(!(WaveExists(sig)))
		Abort "sig DNExist in WriteUSANSWaves()"
	endif

	//write out partial set?
	Duplicate/O qvals, tq, ti, te
	ti = inten
	te = sig
	WAVE dumWave = dumWave
	
	if((lo != hi) && (lo < hi))
		redimension/N=(hi - lo + 1) tq, ti, te, dumWave //lo to hi, inclusive
		tq = qvals[p + lo]
		ti = inten[p + lo]
		te = sig[p + lo]
	endif

	//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
	Duplicate/O qvals, dumWave
	dumWave = dQv

	Make/O/N=(numpnts(dumWave)) dQw = 0

	// Run Name and title
	NewDataFolder/O/S $(parentBase)

	Make/T/N=1 $(parentBase + ":title") = {StringByKey("LABEL", note(inten), ":", ";")}
	CreateStrNxCansas(fileID, nxcansasBase, "", "title", $(parentBase + ":title"), empty, empty)
	Make/T/N=1 $(parentBase + ":run") = {StringByKey("FILE", note(inten), ":", ";")}
	CreateStrNxCansas(fileID, nxcansasBase, "", "run", $(parentBase + ":run"), empty, empty)

	// SASData
	string dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	string dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class", "signal", "I_axes", "NX_class", "Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata", "I", "Q", "NXdata", "0", dateStr}
	CreateStrNxCansas(fileID, dataParent, "", "", empty, $(dataBase + ":attr"), $(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units", "resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom", "dQl,dQw"}
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Q", tq, $(dataBase + ":q:attr"), $(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units", "uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm", "Idev"}
	CreateVarNxCansas(fileID, dataParent, "sasdata", "I", ti, $(dataBase + ":i:attr"), $(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Idev", te, units, inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID, dataParent, "sasdata", "dQl", dumWave, units, inv_angstrom)
	CreateVarNxCansas(fileID, dataParent, "sasdata", "dQw", dQw, units, inv_angstrom)

	// Write the meta data to the file
	WriteUSANSNXcanSASMetaData(fileID, type, parentBase, nxcansasBase, dateStr)

	//write confirmation of write operation to history area
	Print "Averaged NXcanSAS File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z dumWave
	KillDataFolder/Z $base

	// Close the file
	if(fileID)
		HDF5CloseFile/Z fileID
	endif

End

// dialog=1 will present dialog for name
Function WriteNXcanSASUSANSDesmeared(string fullpath, variable lo, variable hi, variable dialog)

	SVAR USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	NVAR dQv         = root:Packages:NIST:USANS:Globals:MainPanel:gDQv

	variable fileID
	string destStr = USANSFolder + ":DSM"
	string dateStr = date() + " " + time()

	string parentBase, nxcansasBase
	string/G base = "root:NXcanSAS_USANS_file"

	variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parentBase, "%s:sasentry%d", base, sasentry // Igor memory base path for all
	sPrintf nxcansasBase, "/sasentry%d/", sasentry // HDF5 base path for all

	NewDataFolder/O/S $(base)

	// Define common attribute waves
	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 m = {"m"}
	Make/O/T/N=1 mm = {"mm"}
	Make/O/T/N=1 cm = {"cm"}
	Make/O/T/N=1 angstrom = {"A"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}

	variable refNum, integer, realval

	fileID = NXcanSAS_OpenOrCreate(dialog, fullpath, base)

	//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
	WAVE qvals = $(destStr + "Q_dsm")
	WAVE inten = $(destStr + "I_dsm")
	WAVE sig   = $(destStr + "S_dsm")
	
	//check each wave
	if(!(WaveExists(qvals)))
		Abort "qvals DNExist in WriteUSANSWaves()"
	endif
	if(!(WaveExists(inten)))
		Abort "inten DNExist in WriteUSANSWaves()"
	endif
	if(!(WaveExists(sig)))
		Abort "sig DNExist in WriteUSANSWaves()"
	endif

	WAVE Q_dsm = Q_dsm

	Duplicate/O Q_dsm, res1, res2, res3
	res3  = 1   // "fake" beamstop shadowing
	res1 /= 100 //make the sigmaQ so small that there is no smearing

	//write out partial set?
	Duplicate/O qvals, tq, ti, te
	ti = inten
	te = sig
	if((lo != hi) && (lo < hi))
		redimension/N=(hi - lo + 1) tq, ti, te, res1, res2, res3 //lo to hi, inclusive
		tq = qvals[p + lo]
		ti = inten[p + lo]
		te = sig[p + lo]
	endif

	//Use the evil extra column for the resolution "information". Should probably switch to using slit_length in collimation.
	Duplicate/O qvals, dumWave
	dumWave = dQv

	Make/O/N=(numpnts(dumWave)) dQw = 0

	// Run Name and title
	NewDataFolder/O/S $(parentBase)

	Make/T/N=1 $(parentBase + ":title") = {StringByKey("LABEL", note(inten), ":", ";")}
	CreateStrNxCansas(fileID, nxcansasBase, "", "title", $(parentBase + ":title"), empty, empty)
	Make/T/N=1 $(parentBase + ":run") = {StringByKey("FILE", note(inten), ":", ";")}
	CreateStrNxCansas(fileID, nxcansasBase, "", "run", $(parentBase + ":run"), empty, empty)

	// SASData
	string dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	string dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class", "signal", "I_axes", "NX_class", "Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata", "I", "Q", "NXdata", "0", dateStr}
	CreateStrNxCansas(fileID, dataParent, "", "", empty, $(dataBase + ":attr"), $(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units", "resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/A", "Qdev"}
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Q", tq, $(dataBase + ":q:attr"), $(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/T/N=2 $(dataBase + ":i:attr") = {"units", "uncertainties"}
	Make/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm", "Idev"}
	CreateVarNxCansas(fileID, dataParent, "sasdata", "I", ti, $(dataBase + ":i:attr"), $(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Idev", te, units, inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Qdev", res1, units, inv_angstrom)
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Qmean", res2, units, inv_angstrom)
	CreateVarNxCansas(fileID, dataParent, "sasdata", "Shadowfactor", res3, units, empty)

	// Write the meta data to the file
	WriteUSANSNXcanSASMetaData(fileID, "DSM", parentBase, nxcansasBase, dateStr)

	//write confirmation of write operation to history area
	Print "Averaged NXcanSAS File written: ", GetFileNameFromPathNoSemi(fullPath)
	KillWaves/Z dumWave
	KillDataFolder/Z $base

	// Close the file
	if(fileID)
		HDF5CloseFile/Z fileID
	endif

End

Function WriteUSANSNXcanSASMetaData(variable fileID, string type, string parentBase, string nxcansasBase, string dateStr)

	// tailor the output given the type of data written out...
	SVAR   USANSFolder = root:Packages:NIST:USANS:Globals:gUSANSFolder
	string destStr     = USANSFolder + ":" + type
	WAVE   inten       = $(destStr + ":DetCts")
	WAVE   inten_EMP   = $(USANSFolder + ":EMP:DetCts")
	string samStr      = ""
	string empStr      = ""
	string samLabelStr = ""
	string paramStr    = ""
	string empLevStr   = ""
	string bkgLevStr   = ""
	string pkStr       = ""
	string processNote = ""
	NVAR   TransWide   = $(USANSFolder + ":Globals:MainPanel:gTransWide")
	NVAR   TransRock   = $(USANSFolder + ":Globals:MainPanel:gTransRock")
	NVAR   empCts      = $(USANSFolder + ":Globals:MainPanel:gEmpCts")
	NVAR   bkgCts      = $(USANSFolder + ":Globals:MainPanel:gBkgCts")
	NVAR   thick       = $(USANSFolder + ":Globals:MainPanel:gThick")

	strswitch(type)
		case "SAM":
			samStr    = type + " FILES: " + StringByKey("FILE", note(inten), ":", ";")
			empStr    = "Uncorrected SAM data"
			empLevStr = "Uncorrected SAM data"
			bkgLevStr = "Uncorrected SAM data"
			paramStr  = "Uncorrected SAM data"
			pkStr    += "SAM PEAK ANGLE: " + num2str(QpkFromNote("SAM"))
			break
		case "EMP":
			samStr    = type + " FILES: " + StringByKey("FILE", note(inten), ":", ";")
			empStr    = "Uncorrected EMP data"
			empLevStr = "Uncorrected EMP data"
			bkgLevStr = "Uncorrected EMP data"
			paramStr  = "Uncorrected EMP data"
			pkStr    += "EMP PEAK ANGLE: " + num2str(QpkFromNote("EMP"))
			break
		case "DSM": // FIXME(CodeStyleFallthroughCaseRequireComment)
			samStr    = "SMEARED FILES: " + StringByKey("FILE", note(inten), ":", ";")
			empStr    = "EMP FILES: " + StringByKey("FILE", note(inten_EMP), ":", ";")
			empLevStr = "EMP LEVEL: " + num2str(empCts)
			bkgLevStr = "BKG LEVEL: " + num2str(bkgCts)
			paramStr  = "Ds = " + num2str(thick) + " cm ; "
			paramStr += "Twide = " + num2Str(TransWide) + " ; "
			paramStr += "Trock = " + num2str(TransRock)
			pkStr    += "SAM PEAK ANGLE: " + num2str(QpkFromNote("SAM"))
			pkStr    += " ; EMP PEAK ANGLE: " + num2str(QpkFromNote("EMP"))
		default: //"COR" is the default, FIXME(CodeStyleFallthroughCaseRequireComment)
			samStr    = type + " FILES: " + StringByKey("FILE", note(inten), ":", ";")
			empStr    = "EMP FILES: " + StringByKey("FILE", note(inten_EMP), ":", ";")
			empLevStr = "EMP LEVEL: " + num2str(empCts)
			bkgLevStr = "BKG LEVEL: " + num2str(bkgCts)
			paramStr  = "Ds = " + num2str(thick) + " cm ; "
			paramStr += "Twide = " + num2Str(TransWide) + " ; "
			paramStr += "Trock = " + num2str(TransRock)
			pkStr    += "SAM PEAK ANGLE: " + num2str(QpkFromNote("SAM"))
			pkStr    += " ; EMP PEAK ANGLE: " + num2str(QpkFromNote("EMP"))
	endswitch

	processNote  = samStr + "\n" + dateStr + "\n" + empStr + "\n" + paramStr + "\n" + pkStr + "\n"
	processNote += empLevStr + " ; " + bkglevStr + "\n"

	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 m = {"m"}
	Make/O/T/N=1 mm = {"mm"}
	Make/O/T/N=1 cm = {"cm"}
	Make/O/T/N=1 angstrom = {"A"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}

	// SASinstrument
	string instrParent = nxcansasBase + "sasinstrument/"
	// Create SASinstrument entry
	string instrumentBase = parentBase + ":sasinstrument"
	NewDataFolder/O/S $(instrumentBase)
	Make/O/T/N=5 $(instrumentBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=5 $(instrumentBase + ":attrVals") = {"SASinstrument", "NXinstrument"}
	CreateStrNxCansas(fileID, instrParent, "", "", empty, $(instrumentBase + ":attr"), $(instrumentBase + ":attrVals"))

	// SASaperture
	string apertureParent = instrParent + "sasaperture/"
	// Create SASaperture entry
	string apertureBase = instrumentBase + ":sasaperture"
	NewDataFolder/O/S $(apertureBase)
	Make/O/T/N=5 $(apertureBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=5 $(apertureBase + ":attrVals") = {"SASaperture", "NXaperture"}
	CreateStrNxCansas(fileID, apertureParent, "", "", empty, $(apertureBase + ":attr"), $(apertureBase + ":attrVals"))
	// Create SASaperture shape entry
	Make/O/T/N=1 $(apertureBase + ":shape") = {"slit"}
	CreateStrNxCansas(fileID, apertureParent, "sasaperture", "shape", $(apertureBase + ":shape"), empty, empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {0.1}
	CreateVarNxCansas(fileID, apertureParent, "sasaperture", "x_gap", $(apertureBase + ":x_gap"), units, cm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {5.0}
	CreateVarNxCansas(fileID, apertureParent, "sasaperture", "y_gap", $(apertureBase + ":y_gap"), units, cm)

	// SASdetector
	string detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	string detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=2 $(detectorBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=2 $(detectorBase + ":attrVals") = {"SASdetector", "NXdetector"}
	CreateStrNxCansas(fileID, detectorParent, "", "", empty, $(detectorBase + ":attr"), $(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {"BT5 DETECTOR ARRAY"}
	CreateStrNxCansas(fileID, detectorParent, "", "name", $(detectorBase + ":name"), empty, empty)

	// SASsource
	string sourceParent = instrParent + "sassource/"
	// Create SASdetector entry
	string sourceBase = instrumentBase + ":sassource"
	NewDataFolder/O/S $(sourceBase)
	Make/O/T/N=2 $(sourceBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=2 $(sourceBase + ":attrVals") = {"SASsource", "NXsource"}
	CreateStrNxCansas(fileID, sourceParent, "", "", empty, $(sourceBase + ":attr"), $(sourceBase + ":attrVals"))
	// Create SASsource probe and type entries
	Make/O/T/N=1 $(sourceBase + ":probe") = {"neutron"}
	CreateStrNxCansas(fileID, sourceParent, "", "probe", $(sourceBase + ":probe"), empty, empty)
	Make/O/T/N=1 $(sourceBase + ":type") = {"Reactor Neutron Source"}
	CreateStrNxCansas(fileID, sourceParent, "", "type", $(sourceBase + ":type"), empty, empty)
	// Create SASsource incident_wavelength entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {2.38}
	CreateVarNxCansas(fileID, sourceParent, "", "incident_wavelength", $(sourceBase + ":incident_wavelength"), units, angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {0.06}
	CreateVarNxCansas(fileID, sourceParent, "", "incident_wavelength_spread", $(sourceBase + ":incident_wavelength_spread"), units, angstrom)

	// SASsample
	string sampleParent = nxcansasBase + "sassample/"
	// Create SASsample entry
	string sampleBase = parentBase + ":sassample"
	NewDataFolder/O/S $(sampleBase)
	Make/O/T/N=5 $(sampleBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=5 $(sampleBase + ":attrVals") = {"SASsample", "NXsample"}
	CreateStrNxCansas(fileID, sampleParent, "", "", empty, $(sampleBase + ":attr"), $(sampleBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(sampleBase + ":name") = {StringByKey("LABEL", note(inten), ":", ";")}
	CreateStrNxCansas(fileID, sampleParent, "", "name", $(sampleBase + ":name"), empty, empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {thick}
	CreateVarNxCansas(fileID, sampleParent, "", "thickness", $(sampleBase + ":thickness"), units, cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {TransWide}
	CreateVarNxCansas(fileID, sampleParent, "", "transmission", $(sampleBase + ":transmission"), empty, empty)

	// SASProcess
	string processParent = nxcansasBase + "sasprocess/"
	// Create SASProcess entry
	string processBase = parentBase + ":sasprocess"
	NewDataFolder/O/S $(processBase)
	Make/O/T/N=2 $(processBase + ":attr") = {"canSAS_class", "NX_class"}
	Make/O/T/N=2 $(processBase + ":attrVals") = {"SASprocess", "NXprocess"}
	CreateStrNxCansas(fileID, processParent, "", "", empty, $(processBase + ":attr"), $(processBase + ":attrVals"))
	// Create SASProcess name entry
	Make/O/T/N=1 $(processBase + ":name") = {"NIST IGOR"}
	CreateStrNxCansas(fileID, processParent, "", "name", $(processBase + ":name"), empty, empty)
	// Create SASProcess note entry
	Make/O/T/N=1 $(processBase + ":processnote") = {processNote}
	CreateStrNxCansas(fileID, processParent, "", "note", $(processBase + ":processnote"), empty, empty)
End
