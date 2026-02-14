#Requires AutoHotkey v2.0

; Open 'AMD Software: Adrenalin Edition' software
Run A_ProgramFiles "\AMD\CNext\CNext\RadeonSoftware.exe"


; Activate 'AMD Software: Adrenalin Edition' window
Sleep 2000
WinActivate "AMD Software: Adrenalin Edition"

; Click 'Record & Stream'
Sleep 1000
Click 445, 50

; Click 'Settings'
Sleep 1000
Click 472, 119

; Click 'Search'
Sleep 1000
Click 903, 61

; Search for 'Instant Replay'
Sleep 1000
Send "Instant Replay"

; Click 'Instant Replay' Toggle
Sleep 2000
Click 1124, 556

; Close 'AMD Software: Adrenalin Edition' software
Sleep 2000
WinClose "AMD Software: Adrenalin Edition"

ExitApp