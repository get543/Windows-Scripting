#Requires AutoHotkey v2.0

;! A bunch of keyboard shortcuts here
; - print screen : a toggle to Hold down the up arrow key
; - ctrl alt x   : always on top for currently active window
; - ctrl alt .   : spam text for 100x 

PrintScreen:: ; press print screen
{   
    static Toggle := 0
    Toggle := !Toggle

    if (Toggle) {
        Send "{Up down}"  ; Presses down the up-arrow key.
    } else {
        Send "{Up up}"  ; Releases the up-arrow key.
    }
}


^!x:: ; press ctrl + alt + x
{
    WinSetAlwaysOnTop -1, "A"
}


^!.:: ; press ctrl + alt + .
{
    Loop 100
    {
        Send "Gw juga bisa spam {Enter}"
        Sleep 100
    }
}

