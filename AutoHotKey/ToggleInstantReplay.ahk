#Requires AutoHotkey v2.0

; Open 'AMD Software: Adrenalin Edition' software
Run "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"

; Activate 'AMD Software: Adrenalin Edition' window
Sleep 1000
WinActivate "AMD Software: Adrenalin Edition"

; Click Search
Click 903, 61

; Search for 'Instant Replay'
Send "Instant Replay"

; Click 'Instant Replay' in search suggestion
Sleep 500
Click 1045, 120

; Click 'Instant Replay' Toggle
Sleep 2000
Click 1087, 559

; Close 'AMD Software: Adrenalin Edition' software if exist
Sleep 2000
WinClose "AMD Software: Adrenalin Edition"

ExitApp