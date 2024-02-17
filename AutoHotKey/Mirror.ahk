#Requires AutoHotkey v2.0

; ======================================== NEW ======================================== 
/* To click on the specific mouse position
- Activate the window
- From Window Spy look at the Client (default) value
*/

; This program do screen mirroring with microphone loopback via keyboard shortcut.

#Requires AutoHotkey v2.0

^+m:: ; press ctrl + shift + m
{
    ; if there's no scrcpy.exe window active    
    if not (WinExist("ahk_exe scrcpy.exe"))
    {
        ; Sends a hotkey presses
        Send "^!p" ; Opens a scrcpy no console (ctrl + alt + p)
        Sleep 5000 ; Delay for 5s
    }

    #Include "%A_ScriptDir%\Microphone Loopback.ahk"
}
