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

^!z:: ; press ctrl + alt + z
{
    static Toggle := 0
    Toggle := !Toggle

    if (Toggle) {
        ; Send "{Up down}"  ; Presses down the up-arrow key.
        Send "{W down}"  ; Presses down the W key.
    } else {
        ; Send "{Up up}"  ; Releases the up-arrow key.
        Send "{W up}"  ; Releases the W key.
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
    if WinExist("Banana")
        WinActivate ; Use the window found by WinExist.
    else
        return

    loop {
        Click 443, 296
        Sleep 300
    }
}

PgUp:: ; press page up
{
    Reload
}

!F1:: ; press alt + f1
{
    Send "!t"
    Send "{F1}"
}

Insert:: ; press insert
{
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1"',
        , 'Hide'  ; Hides the PowerShell window
    )
}
