#Requires AutoHotkey v2.0
#SingleInstance Force

; SendMode Input
; SetWorkingDir %A_ScriptDir%

;! A bunch of keyboard shortcuts here
; - ctrl alt z   : a toggle to Hold down any key defined in Send
; - ctrl alt x   : always on top for currently active window
; - ctrl alt .   : spam text for 100x
; - page down    : auto click script for banana
; - page up      : reload script (turn off auto-clicker)
; - insert       : run ChangeOutputDevice.ps1 script
; - alt f1       : toggle twitch theatre mode & toggle vertical tabs

^!z:: ; press ctrl + alt + z
{
    static Toggle := 0
    Toggle := !Toggle

    if (Toggle) {
        ; Send "{Up down}"      ; Presses down up-arrow key.
        Send "{W down}"         ; Presses down W key.
        Send "{LShift down}"    ; Presses down Left Shift key.
    } else {
        ; Send "{Up up}"        ; Releases up-arrow key.
        Send "{W up}"           ; Releases W key.
        Send "{LShift up}"      ; Releases Left Shift key.
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
