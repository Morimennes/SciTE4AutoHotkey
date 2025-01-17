;
; SciTE4AutoHotkey Toolbar
;
;TillaGoto.iIncludeMode = 0x10111111

#NoEnv
#NoTrayIcon
#SingleInstance Ignore
#Include %A_ScriptDir%
#Include PlatformDetect.ahk
#Include ComInterface.ahk
#Include SciTEDirector.ahk
#Include SciTEMacros.ahk
#Include Extensions.ahk
SetWorkingDir, %A_ScriptDir%\..
SetBatchLines, -1
SetWinDelay, -1
DetectHiddenWindows, On
ListLines, Off

; CLSID and APPID for this script: don't reuse, please!
CLSID_SciTE4AHK := "{D7334085-22FB-416E-B398-B5038A5A0784}"
APPID_SciTE4AHK := "SciTE4AHK.Application"

ATM_OFFSET     := 0x1000
ATM_STARTDEBUG := ATM_OFFSET+0
ATM_STOPDEBUG  := ATM_OFFSET+1
ATM_RELOAD     := ATM_OFFSET+2
ATM_DIRECTOR   := ATM_OFFSET+3
ATM_DRUNTOGGLE := ATM_OFFSET+4

if 0 < 2
{
	MsgBox, 16, SciTE4AutoHotkey Toolbar, This script cannot be run independently.
	ExitApp
}

SciTEDir := A_WorkingDir
CurAhkExe := SciTEDir "\..\AutoHotkey.exe" ; Fallback AutoHotkey binary

FileGetVersion, temp, SciTE.exe
if temp && !ErrorLevel
{
	temp := StrSplit(temp, ".")
	if temp && temp.Length() = 4
		CurrentSciTEVersion := Format("{:d}.{:d}.{:02d}.{:02d}", temp*)
}
if !CurrentSciTEVersion
{
	MsgBox, 16, SciTE4AutoHotkey Toolbar, Invalid SciTE4AutoHotkey version!
	ExitApp
}

; Check if the properties file exists
IfNotExist, toolbar.properties
{
	MsgBox, 16, SciTE4AutoHotkey Toolbar, The property file doesn't exist!
	ExitApp
}

; Get the HWND of the SciTE window
scitehwnd = %1%
IfWinNotExist, ahk_id %scitehwnd%
{
	MsgBox, 16, SciTE4AutoHotkey Toolbar, SciTE not found!
	ExitApp
}

; Get the HWND of the SciTE director window
directorhwnd = %2%
IfWinNotExist, ahk_id %directorhwnd%
{
	MsgBox, 16, SciTE4AutoHotkey Toolbar, SciTE director window not found!
	ExitApp
}

LocalSciTEPath = %SciTEDir%\user
IsPortable := InStr(FileExist(LocalSciTEPath), "D")
if !IsPortable
	LocalSciTEPath = %A_MyDocuments%\AutoHotkey\SciTE
LocalPropsPath = %LocalSciTEPath%\UserToolbar.properties
global ExtensionDir := LocalSciTEPath "\Extensions"

FileEncoding, UTF-8

; Read toolbar settings from properties file
FileRead, GlobalSettings, toolbar.properties
FileRead, LocalSettings, %LocalPropsPath%
FileRead, SciTEVersion, %LocalSciTEPath%\$VER
if SciTEVersion && (SciTEVersion != CurrentSciTEVersion)
{
	if (SciTEVersion > CurrentSciTEVersion) || (SciTEVersion < "3.0.00")
		SciTEVersion := ""
	else
	{
		FileDelete, %LocalSciTEPath%\_platform.properties
		FileDelete, %LocalSciTEPath%\$VER
		FileAppend, %CurrentSciTEVersion%, %LocalSciTEPath%\$VER
		SciTEVersion := CurrentSciTEVersion
		regenerateUserProps := true

		if !IsPortable
		{
			; Copy new styles into Styles folder
			Loop Files, %SciTEDir%\newuser\Styles\*.*
			{
				if !FileExist(LocalSciTEPath "\Styles\" A_LoopFileName) || A_LoopFileName == "Blank.style.properties"
					FileCopy %A_LoopFileLongPath%, %LocalSciTEPath%\Styles\%A_LoopFileName%, 1
			}
		}
	}
}

if !IsPortable && (!FileExist(LocalPropsPath) || !SciTEVersion)
{
	; Rename the old SciTE folder
	IfExist, %LocalSciTEPath%
	{
		FileMoveDir, %LocalSciTEPath%, %LocalSciTEPath%%A_TickCount%, R
		if ErrorLevel
		{
			MsgBox, 16, SciTE4AutoHotkey Toolbar, Could not safely rename old SciTE settings folder!
			ExitApp
		}
	}

	; Create the SciTE user folder
	FileCreateDir, %A_MyDocuments%\AutoHotkey\Lib ; ensure dir structure exists
	FileCopyDir, %SciTEDir%\newuser, %LocalSciTEPath%

	FileDelete, %LocalSciTEPath%\$VER
	FileAppend, %CurrentSciTEVersion%, %LocalSciTEPath%\$VER

	; Reload properties & reload user toolbar settings
	SendMessage, 1024+1, 0, 0,, ahk_id %scitehwnd%
	FileRead, LocalSettings, %LocalPropsPath%
	FirstTime := true
	SciTEVersion := CurrentSciTEVersion
}

SciTEVersionInt := Util_VersionTextToNumber(SciTEVersion)

IfNotExist, %LocalSciTEPath%\Settings\
	FileCreateDir, %LocalSciTEPath%\Settings\
IfNotExist, %LocalSciTEPath%\Extensions\
	FileCreateDir, %LocalSciTEPath%\Extensions\

IfExist, %LocalSciTEPath%\$NODEFTOOLBAR
	GlobalSettings := ""

ToolbarProps := GlobalSettings "`n" Util_ReadExtToolbarDef() LocalSettings

; Load the tools
ntools = 11
_ToolButs =
(LTrim Join`n
-
Run script (F5),2,,autosize
Debug script (F7),3,,autosize
Pause script (F5),10,hidden,autosize
Stop script,4,hidden,autosize
Run current line of code (F10),5,hidden,autosize
Run until next line of code (F11),6,hidden,autosize
Run until function/label exit (Shift+F11),7,hidden,autosize
Callstack,8,hidden,autosize
Variable list,9,hidden,autosize
---

)
_ToolIL := IL_Create()
_IconLib = toolicon.icl

Tools := []

; Set up the stock buttons
IL_Add(_ToolIL, _IconLib, 18)
IL_Add(_ToolIL, _IconLib, 2)
IL_Add(_ToolIL, _IconLib, 1)
IL_Add(_ToolIL, _IconLib, 3)
IL_Add(_ToolIL, _IconLib, 4)
IL_Add(_ToolIL, _IconLib, 5)
IL_Add(_ToolIL, _IconLib, 6)
IL_Add(_ToolIL, _IconLib, 7)
IL_Add(_ToolIL, _IconLib, 8)
IL_Add(_ToolIL, _IconLib, 19)
Tools[2]  := { Path: Func("Cmd_Run")        }
Tools[3]  := { Path: Func("Cmd_Debug")      }
Tools[4]  := { Path: Func("Cmd_Pause")      }
Tools[5]  := { Path: Func("Cmd_Stop")       }
Tools[6]  := { Path: Func("Cmd_StepInto")   }
Tools[7]  := { Path: Func("Cmd_StepOver")   }
Tools[8]  := { Path: Func("Cmd_StepOut")    }
Tools[9]  := { Path: Func("Cmd_Stacktrace") }
Tools[10] := { Path: Func("Cmd_Varlist")    }
i := 11

Loop, Parse, ToolbarProps, `n, `r
{
	curline := Trim(A_LoopField)
	if (curline = "") || SubStr(curline, 1, 1) = ";"
		continue
	else if SubStr(curline, 1, 2) = "--"
	{
		_ToolButs .= "---`n"
		ntools++
		continue
	}else if SubStr(curline, 1, 1) = "-"
	{
		_ToolButs .= "-`n"
		ntools++
		continue
	}else if !RegExMatch(curline, "^=(.*?)\|(.*?)(?:\|(.*?)(?:\|(.*?))?)?$", varz) || varz1 = ""
		continue
	ntools++
	IfInString, varz1, `,
	{
		MsgBox, 16, SciTE4AutoHotkey Toolbar, A tool name can't contain a comma! Specified:`n%varz1%
		ExitApp
	}
	varz4 := ParseCmdLine((noIconSp := varz4 = "") ? varz2 : varz4)
	if RegExMatch(varz4, "^""\s*(.+?)\s*""", ovt)
		varz4 := ovt1
	StringReplace, varz4, varz4, `",, All
	if noIconSp && varz4 = A_AhkPath
		varz4 .= ",2"
	curtool := Tools[ntools] := { Name: Trim(varz1), Path: Trim(varz2), Hotkey: Trim(varz3) }
	IfInString, varz4, `,
	{
		curtool.Picture := Trim(SubStr(varz4, 1, InStr(varz4, ",")-1))
		curtool.IconNumber := Trim(SubStr(varz4, InStr(varz4, ",")+1))
	}else
	{
		curtool.Picture := Trim(varz4)
		curtool.IconNumber := 1
	}

	_ToolButs .= curtool.Name "," (i ++) ",,autosize`n"
	IL_Add(_ToolIL, curtool.Picture, curtool.IconNumber)
}

OnMessage(ATM_STARTDEBUG, "Msg_StartDebug")
OnMessage(ATM_STOPDEBUG, "Msg_StopDebug")
OnMessage(ATM_RELOAD, "Msg_Reload")
OnMessage(ATM_DRUNTOGGLE, "Msg_DebugRunToggle")

; Layout calculations for the AutoHotkey Toolbar
GuiLyt_Padding    := 4   * A_ScreenDPI // 96
GuiLyt_ComboSize  := 128 * A_ScreenDPI // 96
GuiLyt_PosX_Version := GuiLyt_Padding
GuiLyt_PosX_Variant := GuiLyt_PosX_Version + GuiLyt_ComboSize + GuiLyt_Padding
GuiLyt_PosX_Chkbox  := GuiLyt_PosX_Variant + GuiLyt_ComboSize + GuiLyt_Padding
GuiLyt_ToolbarButtonSize := A_ScreenDPI >= 120 ? 24 : 16

;  Get HWND of real SciTE toolbar. ~L
ControlGet, scitool, Hwnd,, ToolbarWindow321, ahk_id %scitehwnd%
ControlGetPos,,, GuiLyt_PosW, GuiLyt_PosH,, ahk_id %scitool% ; Get size of real SciTE toolbar. ~L
; Get width of real SciTE toolbar to determine placement for our toolbar. ~L
; Use DllCall() instead of AHK's built-in SendMessage in order not to use a timeout.
GuiLyt_PosX := DllCall("SendMessage", "ptr", scitehwnd, "uint", 1024, "ptr", 0, "ptr", 0, "ptr")

; Build the AutoHotkey Toolbar
Gui Main:New, hwndhwndgui +Parent%scitool% -Caption -DPIScale LabelMain_, AHKToolbar4SciTE
Gui +0x40000000 -0x80000000 ; Must be done *after* the GUI is created. Fixes focus issues. ~L
Gui Font, s9, Segoe UI
Gui Margin, 0, 0
Gui Add, DDL, vDDL_Version gMain_ChangeVersion x%GuiLyt_PosX_Version% y0 w%GuiLyt_ComboSize% r32
Gui Add, DDL, vDDL_Variant gMain_ChangeVariant x%GuiLyt_PosX_Variant% y0 w%GuiLyt_ComboSize% r32 Hidden
Gui Add, Checkbox, vCB_UIAccess gMain_ChangeVariant x%GuiLyt_PosX_Chkbox% y0 h%GuiLyt_PosH% Hidden, UI access

; Vertically center the DDLs
GuiControlGet _temp, Pos, DDL_Version
GuiLyt_PosY_DDL := (GuiLyt_PosH - _tempH) // 2
GuiControl Move, DDL_Version, y%GuiLyt_PosY_DDL%
GuiControl Move, DDL_Variant, y%GuiLyt_PosY_DDL%

; Calculate position for the toolbar
GuiControlGet _temp, Pos, CB_UIAccess
GuiLyt_PosX_Toolbar := GuiLyt_PosX_Chkbox + _tempW + GuiLyt_Padding
;GuiLyt_PosY_Toolbar := (GuiLyt_PosH - GuiLyt_ToolbarButtonSize) // 2 - 2
GuiLyt_PosY_Toolbar := A_ScreenDPI != 120 ? 0 : 3 ; XX: This is horrid. SciTE only supports 100% or 125% icons. TODO: Future overhaul

; Create and add the toolbar to the Gui
hToolbar := Toolbar_Add(hwndgui, "OnToolbar", "FLAT TOOLTIPS", _ToolIL, "x" GuiLyt_PosX_Toolbar " y" GuiLyt_PosY_Toolbar " w" GuiLyt_PosW " h" GuiLyt_PosH)
Toolbar_Insert(hToolbar, _ToolButs)
Toolbar_SetMaxTextRows(hToolbar, 0)
Toolbar_SetButtonSize(hToolbar, GuiLyt_ToolbarButtonSize, GuiLyt_ToolbarButtonSize)

; Build the menus

Menu, ExtMonMenu, Add, Install, ExtMon_Install
Menu, ExtMonMenu, Add, Remove, ExtMon_Remove
Menu, ExtMonMenu, Add, Create, ExtMon_Create
Menu, ExtMonMenu, Add, Export, ExtMon_Export

Menu, ExtMenu, Add, Extension manager, ExtMon_Show
Menu, ExtMenu, Add, Reload extensions, reloadexts

Menu, ToolMenu, Add, Extensions, :ExtMenu
Menu, ToolMenu, Add
Menu, ToolMenu, Add, Open User toolbar properties, editprops
Menu, ToolMenu, Add, Open User autorun script, editautorun
Menu, ToolMenu, Add, Open User Lua script, editlua
Menu, ToolMenu, Add
Menu, ToolMenu, Add, Open Global toolbar properties, editglobalprops
Menu, ToolMenu, Add, Open Global autorun script, editglobalautorun
Menu, ToolMenu, Add
Menu, ToolMenu, Add, Reload toolbar, reloadtoolbar
Menu, ToolMenu, Add, Reload toolbar (with autorun), reloadtoolbarautorun
Menu, ToolMenu, Add
Menu, ToolMenu, Add, Check for updates..., check4updates

; Create group for our windows
GroupAdd, SciTE4AutoHotkey, ahk_id %scitehwnd%
GroupAdd, SciTE4AutoHotkey, ahk_id %hwndgui%

; Set initial variables
dbg_active := false

; Build hotkeys
Hotkey, IfWinActive, ahk_id %scitehwnd%
Loop, %ntools%
	if Tools[A_Index].Hotkey != ""
		Hotkey, % Tools[A_Index].Hotkey, ToolHotkeyHandler

; Create the COM interface
InitComInterface()

; Register the SciTE director
Director_Init()

; Retrieve the default AutoHotkey directory
AhkDir := DirectorReady ? CoI.ResolveProp("AutoHotkeyDir") : (SciTEDir "\..")
if DirectorReady && !IsPortable
{
	; Auto-detect the AutoHotkey directory from registry
	temp := Util_GetAhkPath()
	if temp
	{
		CoI.SendDirectorMsg("property:AutoHotkeyDir=" CEscape(temp))
		AhkDir := temp
	}
}

; Initialize the macro recorder
Macro_Init()

; Initialize the platforms
global g_Platforms := Plat_DetectAll()
global g_VersionSelect := Plat_GroupByVersion(g_Platforms)
curplatform := ""
IfExist, %LocalSciTEPath%\_platform.properties
{
	FileReadLine, ov, %LocalSciTEPath%\_platform.properties, 2
	curplatform := SubStr(ov, 14)
}

if !g_Platforms.HasKey(curplatform) {
	; Convert old platform names to new names
	switch curplatform {
		case "Default": curplatform := "Automatic"
		case "ANSI":    curplatform := "Latest v1.1 (32-bit ANSI)"
		case "Unicode": curplatform := "Latest v1.1 (32-bit Unicode)"
		case "x64":     curplatform := "Latest v1.1 (64-bit Unicode)"
		case "v2(x86)": curplatform := "Latest v2 (32-bit)"
		case "v2(x64)": curplatform := "Latest v2 (64-bit)"
	}

	if !g_Platforms.HasKey(curplatform) {
		curplatform := "Automatic"
	}
}

GuiControl,, DDL_Version, % Plat_MapToDDL(g_VersionSelect)
Main_UpdateForPlatform(curplatform)

FileRead, temp, *t %LocalSciTEPath%\_platform.properties
if g_Platforms[curplatform] != temp
	gosub changeplatform

if DirectorReady
	CurAhkExe := CoI.ResolveProp("AutoHotkey")

; Finally show the toolbar Gui
Gui Show, x%GuiLyt_PosX% y0 w%GuiLyt_PosW% h%GuiLyt_PosH% NoActivate

; Run the autorun script
if 3 != /NoAutorun
	Run, "%A_AhkPath%" "%SciTEDir%\tools\Autorun.ahk"

; Safety SciTE window existance timer
SetTimer, check4scite, 1000

IfNotExist, %LocalSciTEPath%\_config.properties
	regenerateUserProps := true

if regenerateUserProps
	RunWait, "%A_AhkPath%" "%SciTEDir%\tools\PropEdit.ahk" /regenerate

if FirstTime
{
	CoI.OpenFile(SciTEDir "\TestSuite.ahk")
	MsgBox, 64, SciTE4AutoHotkey, Welcome to SciTE4AutoHotkey!
	Run, "%A_AhkPath%" "%SciTEDir%\tools\PropEdit.ahk"
}
return

; Toolbar event handler
OnToolbar(hToolbar, pEvent, pTxt, pPos, pId)
{
	global
	Critical

	if pEvent = click
		RunTool(pPos)
}

Main_ContextMenu()
{
	; Right click
	Menu, ToolMenu, Show
}

check4updates:
Run, "%A_AhkPath%" "%SciTEDir%\tools\SciTEUpdate.ahk"
return

exitroutine:
IfWinExist, ahk_id %scitehwnd%
{
	WinClose
	Sleep 100
	IfWinExist, SciTE ahk_class #32770
		WinWaitClose
	WinWaitClose, ahk_id %scitehwnd%,, 2
	if ErrorLevel = 1
		return
}
CoI_CallEvent("OnExit")
ExitApp

reloadexts:
Util_CheckReload()
reloadextsForce:
Util_RebuildExtensions()
Util_ReloadSciTE()
return

editprops:
Run, SciTE.exe "%LocalPropsPath%"
return

editautorun:
Run, SciTE.exe "%LocalSciTEPath%\tools\Autorun.ahk"
return

editlua:
Run, SciTE.exe "%LocalSciTEPath%\UserLuaScript.lua"
return

editglobalprops:
Run, SciTE.exe "%SciTEDir%\toolbar.properties"
return

editglobalautorun:
Run, SciTE.exe "%SciTEDir%\tools\Autorun.ahk"
return

reloadtoolbar:
Director_Send("closing:")
Msg_Reload()
return

reloadtoolbarautorun:
Director_Send("closing:")
_ReloadWithAutoRun()
return

check4scite:
; Close the application if the user has closed SciTE
IfWinNotExist, ahk_id %scitehwnd%
{
	SetTimer, check4scite, Off
	gosub, exitroutine
}
return

SciTE_OnClosing()
{
	Critical
	SetTimer, check4scite, 10
}

; Hotkey handler
ToolHotkeyHandler:
curhotkey := A_ThisHotkey
Loop, %ntools%
	toolnumber := A_Index
until Tools[toolnumber].Hotkey = curhotkey
RunTool(toolnumber)
return

Main_UpdateForPlatform(platname)
{
	global hToolbar, GuiLyt_PosX_Toolbar, GuiLyt_PosY_Toolbar, GuiLyt_PosX_Variant, GuiLyt_PosX_Chkbox

	plat := Plat_ParsePlatformName(platname)
	GuiControl ChooseString, DDL_Version, % version := plat[1]
	if IsObject(variant := plat[2]) {
		GuiControl,, DDL_Variant, % Plat_MapToDDL(g_VersionSelect[version])
		GuiControl ChooseString, DDL_Variant, % variant[1]

		hasUIAccess := InStr(variant[2], "UI access")
		variantSupportsUIAccess := hasUIAccess || g_Platforms.HasKey(Format("{} ({}; UI access)", version, variant[1]))

		if variantSupportsUIAccess {
			GuiControl,, CB_UIAccess, % InStr(variant[2], "UI access")
			WinMove ahk_id %hToolbar%,, %GuiLyt_PosX_Toolbar%, %GuiLyt_PosY_Toolbar%
			GuiControl Show, DDL_Variant
			GuiControl Show, CB_UIAccess
		} else {
			WinMove ahk_id %hToolbar%,, %GuiLyt_PosX_Chkbox%, %GuiLyt_PosY_Toolbar%
			GuiControl Show, DDL_Variant
			GuiControl Hide, CB_UIAccess
		}
	} else {
		GuiControl Hide, DDL_Variant
		GuiControl Hide, CB_UIAccess
		WinMove ahk_id %hToolbar%,, %GuiLyt_PosX_Variant%, %GuiLyt_PosY_Toolbar%
	}
}

Main_ChangeVersion()
{
	global curplatform

	GuiControlGet newVersion,, DDL_Version
	variantList := g_VersionSelect[newVersion]

	if not IsObject(variantList) {
		curplatform := newVersion
		gosub platswitch2
	} else {
		GuiControlGet curVariant,, DDL_Variant
		GuiControlGet preferUIAccess,, CB_UIAccess
		prefer64bit := !InStr(curVariant, "32-bit")
		preferUnicode := !InStr(curVariant, "ANSI")
		newVariant := Main_SelectBestVariant(variantList, prefer64bit, preferUnicode)
		Main_SwitchToVariant(newVersion, newVariant, preferUIAccess)
	}
}

Main_ChangeVariant()
{
	GuiControlGet curVersion,, DDL_Version
	GuiControlGet newVariant,, DDL_Variant
	GuiControlGet preferUIAccess,, CB_UIAccess
	Main_SwitchToVariant(curVersion, newVariant, preferUIAccess)
}

Main_SelectBestVariant(variantList, prefer64bit, preferUnicode) {
	maxScore := -1
	maxVariant := ""
	for variant in variantList {
		has64bit := !InStr(variant, "32-bit")
		hasUnicode := !InStr(variant, "ANSI")
		score := ((has64bit&prefer64bit)<<1) | (hasUnicode&preferUnicode)
		if (score > maxScore) {
			maxScore := score
			maxVariant := variant
		}
	}
	return maxVariant
}

Main_SwitchToVariant(newVersion, newVariant, preferUIAccess) {
	global curplatform

	if !preferUIAccess || !g_Platforms[curplatform := Format("{} ({}; UI access)", newVersion, newVariant)]
		curplatform := Format("{} ({})", newVersion, newVariant)
	gosub platswitch2
}

platswitch2:
Gui Main:Default
Main_UpdateForPlatform(curplatform)
changeplatform:
FileDelete, %LocalSciTEPath%\_platform.properties
FileAppend, % g_Platforms[curplatform], %LocalSciTEPath%\_platform.properties
SendMessage, 1024+1, 0, 0,, ahk_id %scitehwnd%
PostMessage, 0x111, 1136, 0,, ahk_id %scitehwnd%
if DirectorReady
	CurAhkExe := CoI.ResolveProp("AutoHotkey")
CoI_CallEvent("OnPlatformChange", curplatform)
return

; Function to run a tool
RunTool(toolnumber)
{
	global Tools, dbg_active
	if IsObject(t := Tools[toolnumber].Path)
		%t%()
	else if !dbg_active
	{
		Run, % ParseCmdLine(t),, UseErrorLevel
		if ErrorLevel = ERROR
			MsgBox, 16, SciTE4AutoHotkey Toolbar, Couldn't launch specified command line! Specified:`n%cmd%
	}
}

Cmd_Run()
{
	global
	if !dbg_active
		PostMessage, 0x111, 303, 0,, ahk_id %scitehwnd%
	else
		PostMessage, 0x111, 1127, 0,, ahk_id %scitehwnd%
}

Cmd_Pause()
{
	global
	PostMessage, 0x111, 1134, 0,, ahk_id %scitehwnd%
}

Cmd_Stop()
{
	global
	PostMessage, 0x111, 1128, 0,, ahk_id %scitehwnd%
}

Cmd_Debug()
{
	global
	PostMessage, 0x111, 302, 0,, ahk_id %scitehwnd%
}

Cmd_StepInto()
{
	global
	PostMessage, 0x111, 1129, 0,, ahk_id %scitehwnd%
}

Cmd_StepOver()
{
	global
	PostMessage, 0x111, 1130, 0,, ahk_id %scitehwnd%
}

Cmd_StepOut()
{
	global
	PostMessage, 0x111, 1131, 0,, ahk_id %scitehwnd%
}

Cmd_Stacktrace()
{
	global
	PostMessage, 0x111, 1132, 0,, ahk_id %scitehwnd%
}

Cmd_Varlist()
{
	global
	PostMessage, 0x111, 1133, 0,, ahk_id %scitehwnd%
}

Msg_StartDebug(a,b,msg)
{
	global
	Toolbar_SetButton(hToolbar, 2, "-hidden")
	Toolbar_SetButton(hToolbar, 3, "hidden")
	Toolbar_SetButton(hToolbar, 4, "hidden")
	Toolbar_SetButton(hToolbar, 5, "-hidden")
	Toolbar_SetButton(hToolbar, 6, "-hidden")
	Toolbar_SetButton(hToolbar, 7, "-hidden")
	Toolbar_SetButton(hToolbar, 8, "-hidden")
	Toolbar_SetButton(hToolbar, 9, "-hidden")
	Toolbar_SetButton(hToolbar, 10, "-hidden")
	dbg_active := true
	dbg_runshown := true
}

Msg_StopDebug()
{
	global
	Toolbar_SetButton(hToolbar, 2, "-hidden")
	Toolbar_SetButton(hToolbar, 3, "-hidden")
	Toolbar_SetButton(hToolbar, 4, "hidden")
	Toolbar_SetButton(hToolbar, 5, "hidden")
	Toolbar_SetButton(hToolbar, 6, "hidden")
	Toolbar_SetButton(hToolbar, 7, "hidden")
	Toolbar_SetButton(hToolbar, 8, "hidden")
	Toolbar_SetButton(hToolbar, 9, "hidden")
	Toolbar_SetButton(hToolbar, 10, "hidden")
	dbg_active := false
}

Msg_DebugRunToggle()
{
	global
	if !dbg_active
		return
	dbg_runshown := !dbg_runshown
	if dbg_runshown
	{
		Toolbar_SetButton(hToolbar, 2, "-hidden")
		Toolbar_SetButton(hToolbar, 4, "hidden")
	}else
	{
		Toolbar_SetButton(hToolbar, 2, "hidden")
		Toolbar_SetButton(hToolbar, 4, "-hidden")
	}
}

Msg_Reload()
{
	global
	Run, "%A_AhkPath%" /restart "%A_ScriptFullPath%" %scitehwnd% %directorhwnd% /NoAutorun
}

_ReloadWithAutoRun()
{
	global
	Run, "%A_AhkPath%" /restart "%A_ScriptFullPath%" %scitehwnd% %directorhwnd%
}

GetSciTEOpenedFile()
{
	global scitehwnd, DirectorReady

	if DirectorReady
		return Director_Send("askfilename:", true).value
	else
	{
		WinGetTitle, sctitle, ahk_id %scitehwnd%
		if RegExMatch(sctitle, "^(.+?) [-*] SciTE", o)
			return o1
		return "?ERROR"
	}
}

GetFilename(txt)
{
	SplitPath, txt, o
	return o
}

GetPath(txt)
{
	SplitPath, txt,, o
	return o
}

ParseCmdLine(cmdline)
{
	global _IconLib, curplatform, LocalSciTEPath, SciTEDir, CurAhkExe
	a := GetSciTEOpenedFile()

	StringReplace, cmdline, cmdline, `%FILENAME`%, % GetFilename(a), All
	StringReplace, cmdline, cmdline, `%FILEPATH`%, % GetPath(a), All
	StringReplace, cmdline, cmdline, `%FULLFILENAME`%, % a, All
	StringReplace, cmdline, cmdline, `%LOCALAHK`%, "%A_AhkPath%", All
	StringReplace, cmdline, cmdline, `%AUTOHOTKEY`%, "%CurAhkExe%", All
	StringReplace, cmdline, cmdline, `%ICONRES`%, %_IconLib%, All
	StringReplace, cmdline, cmdline, `%SCITEDIR`%, % SciTEDir, All
	StringReplace, cmdline, cmdline, `%USERDIR`%, % LocalSciTEPath, All
	StringReplace, cmdline, cmdline, `%PLATFORM`%, %curplatform%, All

	return cmdline
}

Util_GetAhkPath()
{
	RegRead, ov, HKLM, SOFTWARE\AutoHotkey, InstallDir
	if !ov && A_Is64bitOS
	{
		q := A_RegView
		SetRegView, 64
		RegRead, ov, HKLM, SOFTWARE\AutoHotkey, InstallDir
		SetRegView, %q%
	}
	return ov
}
