#pragma rtGlobals=1		// Use modern global access method.


Function MakePanel()

	NewPanel/N=TestPanel
	Button button_OK, title="OK"
	Button button_OK, proc=OK_Button_Proc

	Print "In MakePanel()"
	Print GetDataFolder(1)
	
	PauseForUser TestPanel
end


Function OK_Button_Proc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K TestPanel
End

Function TestPFU()
	SetDataFolder root:
	NewDataFolder/O/S testfolder
	
	Print "In TestPFU()"
	Print GetDataFolder(1)
	Print "Calling MakePanel()"
	MakePanel()
	Print "After MakePanel() and PauseForUser"
	Print GetDataFolder(1)

	KillDataFolder root:testfolder
end