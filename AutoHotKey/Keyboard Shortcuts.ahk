#Requires AutoHotkey v2.0
#SingleInstance Force

;! Remove the default Exit from the tray menu
A_TrayMenu.Delete("E&xit")
A_TrayMenu.Add("Edit Script", (*) => Edit())

;! Modify the existing tray menu
A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Shortcut List", (*) => 
    MsgBox("Available Keyboard Shortcuts: `n`n"
        . "- Alt + `` `t`t: Hold down any key (right now is left click)`n"
        . "- Ctrl + Alt + X`t: Always On Top for currently active window`n"
        . "- Ctrl + Alt + .`t: Spam left click indefinitely`n"
        . "- Ctrl + Alt + O`t: Microphone Loopback Toggle`n"
        . "- Ctrl + Alt + M`t: Start Scrcpy + Microphone Loopback`n"
        . "- Page Down`t: Auto Clicker for Roblox`n"
        . "- Page Up`t: Reload Script (Stop Auto Clicker)`n"
        . "- Alt + F1`t`t: Toggle Twitch Theatre Mode & Vertical Tabs`n"
        . "- Insert`t`t: Switch Output Device Script`n"
        . "- Scroll Lock`t: Start OBS Replay Buffer"
    )
)

;! Add custom item to the bottom of the tray menu
A_TrayMenu.Add("Set Output Device from Script", (*) => 
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1" -SetDevice'
    )
)

A_TrayMenu.Add("Auto Launch Apps", (*) => 
    RunWait(
        '*RunAs powershell.exe -ExecutionPolicy Bypass -File "' 
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\AutoLaunchApp.ps1"'
    )
)

A_TrayMenu.Add("Toggle DNS", (*) => 
    RunWait(
        '*RunAs powershell.exe -ExecutionPolicy Bypass -File "' 
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ToggleDNS.ps1"'
    )
)

;! ==============================================================================

HttpServer_MenuHandler(*) {
    IB := InputBox("Please enter a file path.", "File Path")
    
    if (IB.Result = "Cancel" || IB.Value = "")
        return
    
    ScriptPath := A_MyDocuments "\PowerShell\Scripts\Windows-Scripting\File-Share.ps1"
    FilePath := Trim(IB.Value, '"')

    ; Run PowerShell using -File for better space handling.
    ; We wrap paths in double quotes to ensure they are treated as a single argument.
    RunWait('*RunAs powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ScriptPath '" -FilePath "' FilePath '"')
}

A_TrayMenu.Add("HTTP Server", HttpServer_MenuHandler)


;! ==============================================================================

; Place this function somewhere down with your other functions:
EnableDiscordRPC() {
    TrayTip("The Discord RPC has been enabled.", "Enabled in E:\UDIN\Code\Discord-RPC", 16)
    RunWait('powershell.exe -Command "cd E:\UDIN\Code\DISCORD-RPC; npm run test"', , 'Hide')
}

; Update the tray menu line to point to a new function:
A_TrayMenu.Add("Enable Discord RPC", (*) => EnableDiscordRPC())

;! ==============================================================================

; Create a new, blank menu object for the sub-menu
ResMenu := Menu()

; Resolutions to this new sub-menu
ResMenu.Add("1920x1080 (Native)", (*) => ChangeResolution(1920, 1080))
ResMenu.Add("1440x992", (*) => ChangeResolution(1440, 992))
ResMenu.Add("1280x1024", (*) => ChangeResolution(1280, 1024))
ResMenu.Add("1280x960", (*) => ChangeResolution(1280, 960))
ResMenu.Add("1280x882", (*) => ChangeResolution(1280, 882))
ResMenu.Add("1024x768", (*) => ChangeResolution(1024, 768))

; Attach the sub-menu to the main tray menu
A_TrayMenu.Add("Custom Resolutions", ResMenu)

ChangeResolution(w, h, colorDepth:=32, refreshRate:=60) {
    dM := Buffer(156, 0)
    NumPut("UShort", 156, dM, 36)
    DllCall("EnumDisplaySettingsA", "Ptr", 0, "Int", -1, "Ptr", dM)
    NumPut("UInt", 0x5C0000, dM, 40)
    NumPut("UInt", colorDepth, dM, 104)
    NumPut("UInt", w, dM, 108)
    NumPut("UInt", h, dM, 112)
    NumPut("UInt", refreshRate, dM, 120)
    DllCall("ChangeDisplaySettingsA", "Ptr", dM, "UInt", 0)
}

;! ==============================================================================

A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Exit", (*) => ExitApp()) ; Add Exit item to the bottom of the tray menu

;! ==============================================================================

#Include "%A_ScriptDir%\Microphone Loopback.ahk"

!`:: ; press alt + `
{
    static Toggle := 0
    Toggle := !Toggle

    if (Toggle) {
        ; Send "{Up down}"          ; Presses down up-arrow key.
        ; Send "{W down}"           ; Presses down W key.
        ; Send "{LShift down}"      ; Presses down Left Shift key.
        Send "{Click down}"         ; Hold down Left Click
    } else {
        ; Send "{Up up}"          ; Releases up-arrow key.
        ; Send "{W up}"           ; Releases W key.
        ; Send "{LShift up}"      ; Releases Left Shift key.
        Send "{Click up}"         ; Releases Left Click
    }
}

^!x:: ; press ctrl + alt + x
{
    WinSetAlwaysOnTop -1, "A"
}

;! ==============================================================================

; --- SPAM LEFT CLICK (CTRL + ALT + .) ---
global SpamClicker := false

^!.:: ; ctrl + alt + .
{
    global SpamClicker
    SpamClicker := !SpamClicker ; Toggle between true and false

    if (SpamClicker) {
        SetTimer(SpamClickAction, 100) ; Start clicking every 100ms
    } else {
        SetTimer(SpamClickAction, 0) ; Stop clicking
    }
}

SpamClickAction() {
    Send "{Click}"
}

;! ==============================================================================

; --- ROBLOX AUTO CLICKER (PAGE DOWN) ---
global RobloxClicker := false

PgDn:: ; press page down
{
    global RobloxClicker
    RobloxClicker := !RobloxClicker ; Toggle between true and false

    if (RobloxClicker) {
        if WinExist("Roblox") {
            WinActivate
            SetTimer(RobloxClickAction, 300) ; Start clicking every 300ms
        } else {
            RobloxClicker := false ; Reset toggle if Roblox isn't open
        }
    } else {
        SetTimer(RobloxClickAction, 0) ; Stop clicking
    }
}

RobloxClickAction() {
    Click
}

;! ==============================================================================


^!o:: ; press ctrl + alt + o
{ 
    MicrophoneLoopbackFunction() ; call the function from included file
}

^!m:: ; press ctrl + alt + m
{
    ; if there's no scrcpy.exe window active    
    if not (WinExist("ahk_exe scrcpy.exe"))
    {
        ; Sends a hotkey presses
        Send "^!p" ; Opens a scrcpy no console (ctrl + alt + p)
        Sleep 5000 ; Delay for 5s
    }

    MicrophoneLoopbackFunction() ; call the function from included file
}

PgUp:: ; press page up
{
    Reload
}

!F1:: ; press alt + f1
{
    Send "!t" ; toggle twitch theatre mode
    Send "{F1}" ; toggle vertical tabs
}

Insert:: ; press insert
{
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1"',
        , 'Hide'  ; Hides the PowerShell window
    )
}

ScrollLock:: ; press scroll lock
{
    SetWorkingDir A_ProgramFiles "\obs-studio\bin\64bit" ; cd to OBS directory
    Run "obs64.exe --minimize-to-tray --startreplaybuffer" 
}
