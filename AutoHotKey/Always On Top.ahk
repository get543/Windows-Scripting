#Requires AutoHotkey v2.0

; This program sets "Always on top" via keyboard shorcut to whatever window that is currently active

^!x:: ; press ctrl + alt + x
{
    WinSetAlwaysOnTop -1, "A"
}