;* ============================================================================== 
;* OutputDeviceSwap.ahk
;* ============================================================================== 
;* What this script does:
;*   This script lets you quickly switch the default Windows audio output device
;*   without opening Sound settings. It maintains a list of preferred devices and
;*   lets you:
;*       - Tap Alt + Insert: swap between the current device and the last used one
;*       - Hold Alt + Insert: cycle through the configured devices one by one
;*   The current device name is shown in a small on-screen display near the bottom
;*   of the screen.
;*
;* Prerequisites:
;*   1. Install AutoHotkey v2.0 or later.
;*   2. Download and install NirSoft SoundVolumeView.exe.
;*   3. Ensure SoundVolumeView.exe is available in PATH or in the same folder as
;*      this script, so the script can call it to change the default audio device.
;*   4. Update the ActiveDevices list below to match the exact names shown by
;*      SoundVolumeView (case-sensitive). Examples: "Headphones", "Output Monitor".
;*
;* How to run it:
;*   1. Save this file as OutputDeviceSwap.ahk.
;*   2. Double-click the file, or run it with AutoHotkey v2:
;*         "C:\Program Files\AutoHotkey\AutoHotkey64.exe" "OutputDeviceSwap.ahk"
;*      If you prefer, compile it to an .exe using Ahk2Exe.
;*   3. Press Alt + Insert to switch outputs.
;*
;* Notes:
;*   - The script calls SoundVolumeView.exe /SetDefault "Device Name" all
;*     to change both the playback and communications default devices.
;*   - If your device names change, update the ActiveDevices array at the top of
;*     this file so the script uses the correct names.
;*   - You can install SoundVolumeView.exe with winget install NirSoft.SoundVolumeView
;* ============================================================================== 

#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; DEVICE LIST & STATE MANAGEMENT
; ==============================================================================
; Ensure these match the exact device names shown in SoundVolumeView
; You can check in a csv file by running : SoundVolumeView.exe /scomma devices.csv
; Or for GUI version by running : SoundVolumeView.exe
global ActiveDevices := [
    "Output Monitor",
    "Headphones",
    "Output Mixer"
]

global CurrentIndex := 1
global LastIndex := 1
global PendingIndex := 1
global IsCycling := false

TAP_THRESHOLD_MS := 250

; ==============================================================================
; HOTKEY HANDLERS (Alt + Insert)
; ==============================================================================

!Insert::
{
    global CurrentIndex, LastIndex, PendingIndex, IsCycling

    ; 1. CYCLE MODE: Advance device selection if Alt is already held down
    if (IsCycling) {
        PendingIndex := Mod(PendingIndex, ActiveDevices.Length) + 1
        ShowOSD(ActiveDevices[PendingIndex])
        return
    }

    ; 2. INITIAL PRESS: Distinguish between rapid tap vs. hold
    insertReleased := KeyWait("Insert", "T" . (TAP_THRESHOLD_MS / 1000))
    altHeld := GetKeyState("Alt", "P")

    ; --- PATH A: QUICK TAP (Swap Current <-> Last) ---
    if (insertReleased && !altHeld) {
        if (CurrentIndex != LastIndex) {
            temp := CurrentIndex
            CurrentIndex := LastIndex
            LastIndex := temp

            CommitDeviceChange(ActiveDevices[CurrentIndex])
            ShowOSD("Swapping to: " . ActiveDevices[CurrentIndex], 1200)
        }
        return
    }

    ; --- PATH B: HOLD / CYCLE MODE ---
    IsCycling := true
    PendingIndex := Mod(CurrentIndex, ActiveDevices.Length) + 1
    ShowOSD(ActiveDevices[PendingIndex])

    SetTimer(MonitorAltRelease, 30)
}

; ==============================================================================
; ALT-RELEASE MONITORING
; ==============================================================================

MonitorAltRelease() {
    global CurrentIndex, LastIndex, PendingIndex, IsCycling

    if (!GetKeyState("Alt", "P")) {
        SetTimer(MonitorAltRelease, 0)

        if (IsCycling) {
            if (PendingIndex != CurrentIndex) {
                LastIndex := CurrentIndex
                CurrentIndex := PendingIndex
                CommitDeviceChange(ActiveDevices[CurrentIndex])
            }

            IsCycling := false
            HideOSD()
        }
    }
}

; ==============================================================================
; CUSTOM OSD GUI IMPLEMENTATION
; ==============================================================================

global OsdGui := ""
global OsdText := ""
global OsdTimerFunc := () => HideOSD()

InitOSD() {
    global OsdGui, OsdText
    if (OsdGui)
        return

    ; Create frameless, click-through (+E0x20), always-on-top window
    OsdGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
    OsdGui.BackColor := "1E1E1E" ; Dark background

    ; Outer card padding around the text box
    OsdGui.MarginX := 32
    OsdGui.MarginY := 18

    ; Set font ON THE GUI FIRST so control dimensions are calculated correctly
    OsdGui.SetFont("s18 w600", "Segoe UI")

    ; Add text control:
    ;    - w450: Wider box so long device names don't wrap/truncate
    ;    - h48: Generous height so emojis and letters aren't clipped
    ;    - +0x200: SS_CENTERIMAGE style (vertically centers the text)
    OsdText := OsdGui.AddText("cFFFFFF Center w450 h48 +0x200", "")

    ; Enable Windows 11 native rounded corners (ignored gracefully on Windows 10)
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", OsdGui.Hwnd, "int", 33, "int*", 2, "int", 4)
}

ShowOSD(deviceName, timeoutMs := 0) {
    global OsdGui, OsdText, OsdTimerFunc

    InitOSD()
    SetTimer(OsdTimerFunc, 0) ; Reset auto-hide timer if currently active

    OsdText.Value := "🔊  " . deviceName

    ; Get the bottom coordinate of the usable screen area (excludes taskbar)
    MonitorGetWorkArea(, , , , &workBottom)

    ; Position top edge ~120px above taskbar for bottom-center alignment
    yPos := workBottom - 120

    OsdGui.Show("NoActivate AutoSize Center Y" . yPos)

    if (timeoutMs > 0) {
        SetTimer(OsdTimerFunc, -timeoutMs)
    }
}

HideOSD() {
    global OsdGui
    if (OsdGui) {
        OsdGui.Hide()
    }
}

; ==============================================================================
; SOUNDVOLUMEVIEW CLI
; ==============================================================================

CommitDeviceChange(deviceName) {
    ; SoundVolumeView parameter 'all' sets both Default Playback and Communications roles
    Run('SoundVolumeView.exe /SetDefault "' . deviceName . '" all', , "Hide")
}
