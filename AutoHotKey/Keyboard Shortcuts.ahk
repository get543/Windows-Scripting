#Requires AutoHotkey v2.0
#SingleInstance Force

;! Remove the default Exit from the tray menu
A_TrayMenu.Delete("E&xit")
A_TrayMenu.Add("Edit Script", (*) => Edit())

;! Modify the existing tray menu
A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Shortcut List", (*) => 
    MsgBox("Available Keyboard Shortcuts: `n`n"
        . "- Alt + `` `t: Toggle to hold down any key (right now is left click)`n"
        . "- Ctrl + Alt + X`t: Always On Top Current Window`n"
        . "- Ctrl + Alt + .`t: Spam Text 100x`n"
        . "- Ctrl + Alt + O`t: Microphone Loopback Toggle`n"
        . "- Ctrl + Alt + M`t: Start Scrcpy + Microphone Loopback`n"
        . "- Page Down`t: Auto Clicker`n"
        . "- Page Up`t: Reload Script (Stop Auto Clicker)`n"
        . "- Alt + F1`t`t: Toggle Twitch Theatre Mode & Vertical Tabs`n"
        . "- Insert`t`t: Switch Output Device Script`n"
        . "- Scroll Lock`t: Start OBS Replay Buffer"
    )
) ; Add your custom item to the bottom of the tray menu

A_TrayMenu.Add("Set Output Device from Script", (*) => 
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1" -SetDevice'
    )
) ; Add your custom item to the bottom of the tray menu

A_TrayMenu.Add("Auto Launch Apps", (*) => 
    RunWait(
        '*RunAs powershell.exe -ExecutionPolicy Bypass -File "' 
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\AutoLaunchApp.ps1"'
    )
) ; Add your custom item to the bottom of the tray menu

A_TrayMenu.Add("Enable Discord RPC", (*) => 
    TrayTip("Enabled in E:\UDIN\Code\Discord-RPC", "The Discord RPC has been enabled.", 1 16 32) ; TrayTip Text, Title, Options

    RunWait(
        'powershell.exe -Command "cd E:\UDIN\Code\DISCORD-RPC; npm run test"', , 'Hide'
    )
) ; Add your custom item to the bottom of the tray menu

A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Exit", (*) => ExitApp()) ; Add Exit item to the bottom of the tray menu

; file needed :
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

^!.:: ; press ctrl + alt + .
{
    loop 100 {
        Send "Gw juga bisa spam {Enter}"
        Sleep 100
    }
}

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

PgDn:: ; press page down
{
    if WinExist("Roblox")
        WinActivate ; Use the window found by WinExist.
    else
        return

    loop {
        ; Click 443, 296
        Click
        Sleep 300
    }
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
