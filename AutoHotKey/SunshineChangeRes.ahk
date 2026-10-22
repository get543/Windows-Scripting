#Requires AutoHotkey v2.0

; - Open the Sunshine Web UI (http://localhost:47990).
; - Go to Configuration > Prep Commands.
; - Update your Global Prep Commands:
    ; --- Do Command 1 (choose) ---
    ;! "%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe" "%USERPROFILE%\Documents\PowerShell\Scripts\Windows-Scripting\AutoHotKey\SunshineChangeRes.ahk" %SUNSHINE_CLIENT_WIDTH% %SUNSHINE_CLIENT_HEIGHT% %SUNSHINE_CLIENT_FPS%
    ; --- Do Command 2 (choose) ---
    ;! "%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe" "%USERPROFILE%\Documents\PowerShell\Scripts\Windows-Scripting\AutoHotKey\SunshineChangeRes.ahk"

    ; --- Undo Command ---
    ;! "%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe" "%USERPROFILE%\Documents\PowerShell\Scripts\Windows-Scripting\AutoHotKey\SunshineChangeRes.ahk" 1920 1080 75
; - Click Save.


; Safely retrieve width, height, and FPS (checks args first, then Sunshine env vars, then defaults)
width  := GetValue(1, "SUNSHINE_CLIENT_WIDTH", 1920)
height := GetValue(2, "SUNSHINE_CLIENT_HEIGHT", 1080)
fps    := GetValue(3, "SUNSHINE_CLIENT_FPS", 60)

; -------------------------------------------------------------
; YOUR DEVICE CONDITIONAL LOGIC
; -------------------------------------------------------------
if (width == 2712 && height == 1220) {
    ; Specific logic for phone resolution (2712x1220)
    ChangeResolution(1920, 864, fps)
} 
else if (width == 1920 && height == 1080) {
    ChangeResolution(1920, 1080, fps)
} 
else {
    ; Fallback for any other device
    ChangeResolution(width, height, fps)
}

ExitApp()

; -------------------------------------------------------------
; HELPER FUNCTIONS
; -------------------------------------------------------------

; Safely fetches a number without throwing an "Integer.Call" error
GetValue(argIndex, envVarName, defaultValue) {
    ; Try command-line argument if it is a valid number
    if (A_Args.Length >= argIndex && IsNumber(A_Args[argIndex]))
        return Integer(A_Args[argIndex])
    
    ; Try reading environment variable injected by Sunshine
    envVal := EnvGet(envVarName)
    if (envVal != "" && IsNumber(envVal))
        return Integer(envVal)
    
    ; Use default fallback if neither contains a valid number
    return defaultValue
}

; --- Core Function ---
ChangeResolution(w, h, refreshRate, colorDepth := 32) {
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