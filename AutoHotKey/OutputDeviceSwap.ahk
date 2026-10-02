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

global CurrentIndex  := 1
global LastIndex     := 1
global PendingIndex  := 1
global IsCycling     := false

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
; HELPER FUNCTIONS (OSD & SOUNDVOLUMEVIEW CLI)
; ==============================================================================

ShowOSD(deviceName, timeoutMs := 0) {
    ToolTip("🔊 " . deviceName)
    if (timeoutMs > 0) {
        SetTimer(() => ToolTip(), -timeoutMs)
    }
}

HideOSD() {
    ToolTip()
}

CommitDeviceChange(deviceName) {
    ; SoundVolumeView parameter 'all' sets both Default Playback and Communications roles
    Run('SoundVolumeView.exe /SetDefault "' . deviceName . '" all', , "Hide")
}