/* To click on the specific mouse position :
- Activate the window
- From Window Spy look at the 'Client: 123123, 123123 (default)'
*/

; This program turns on "Listen to this device" checkbox by clicking on the specific part of the screen

#Requires AutoHotkey v2.0

; Sends a hotkey presses
Send "^!r" ; Opens a Sound Settings on the Recording's tab (ctrl + alt + r)
Sleep 2000 ; Delay for 2s

WinActivate "Sound" ; Activate Sound window
Click 128, 109, 0 ; Move mouse to my microphone
Click 2 ; Double click on it

Sleep 1000 ; Delay for 1s
WinActivate "Microphone Properties" ; Activate Microphone Properties window
Click 80, 19 ; Click Listen Tab

Sleep 1000 ; Delay for 1s
Click 28, 162 ; Click Listen to this device checkbox
Click 355, 402 ; Click Apply

; Close window
Sleep 500 ; Delay for 500s
Click 189, 400 ; Click Ok

Sleep 500 ; Delay for 500ms
WinActivate "Sound" ; Activate Sound window
Click 197, 400 ; Click Ok

ExitApp
