#Requires AutoHotkey v2.0
#SingleInstance Force

;! ==============================================================================
;! ==========================  MODIFY OR ADD TRAY MENU  =========================
;! ==============================================================================

;! Remove the default Exit from the tray menu
A_TrayMenu.Delete("E&xit")
A_TrayMenu.Add("Edit Script", (*) => Edit())

;! Modify the existing tray menu
A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Shortcut List", (*) =>
    MsgBox("Available Keyboard Shortcuts: `n`n"
        . "- Alt + `` `t`t: Hold down any key (right now is W & LSHIFT)`n"
        . "- Ctrl + Alt + X`t: Always On Top for currently active window`n"
        . "- Ctrl + Alt + .`t: Spam left click indefinitely`n"
        . "- Ctrl + Alt + O`t: Microphone Loopback Toggle`n"
        . "- Ctrl + Alt + M`t: Start Scrcpy + Microphone Loopback`n"
        . "- Page Down`t: Auto Clicker for Roblox`n"
        . "- Page Up`t: Reload Script (Stop Auto Clicker)`n"
        . "- Alt + F1`t`t: Toggle Twitch Theatre Mode & Vertical Tabs`n"
        . "- Insert`t`t: Switch Output Device Script`n"
        . "- Scroll Lock`t: Start OBS Replay Buffer"
    ))

;! Add custom item to the bottom of the tray menu
A_TrayMenu.Add("Set Output Device from Script", (*) =>
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1" -SetDevice'
    ))

A_TrayMenu.Add("Auto Launch Apps", (*) =>
    RunWait(
        '*RunAs powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\AutoLaunchApp.ps1"'
    ))

A_TrayMenu.Add("Toggle DNS", (*) =>
    RunWait(
        '*RunAs powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ToggleDNS.ps1"'
    ))

;! ==============================================================================

HttpServer_MenuHandler(*) {
    IB := InputBox("Please enter a file path.", "File Path")

    if (IB.Result = "Cancel" || IB.Value = "")
        return

    ScriptPath := A_MyDocuments "\PowerShell\Scripts\Windows-Scripting\File-Share.ps1"
    FilePath := Trim(IB.Value, '"')

    ; Run PowerShell using -File for better space handling.
    ; We wrap paths in double quotes to ensure they are treated as a single argument.
    RunWait('*RunAs powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ScriptPath '" -FilePath "' FilePath '"')
}

A_TrayMenu.Add("HTTP Server", HttpServer_MenuHandler)

;! ==============================================================================

; Place this function somewhere down with your other functions:
EnableDiscordRPC() {
    TrayTip("The Discord RPC has been enabled.", "Enabled in E:\UDIN\Code\Discord-RPC", 16)
    RunWait('powershell.exe -Command "cd E:\UDIN\Code\DISCORD-RPC; npm run test"', , 'Hide')
}

; Update the tray menu line to point to a new function:
A_TrayMenu.Add("Enable Discord RPC", (*) => EnableDiscordRPC())

;! ==============================================================================

; Create a new, blank menu object for the sub-menu
ResMenu := Menu()

; Resolutions to this new sub-menu
ResMenu.Add("1920x1080@75Hz (Native)", (*) => ChangeResolution(1920, 1080, 75))
ResMenu.Add("1920x864@75Hz", (*) => ChangeResolution(1920, 864, 75))
ResMenu.Add("1440x992@75Hz", (*) => ChangeResolution(1440, 992, 75))
ResMenu.Add("1280x1024@75Hz", (*) => ChangeResolution(1280, 1024, 75))
ResMenu.Add("1280x960@75Hz", (*) => ChangeResolution(1280, 960, 75))
ResMenu.Add("1280x882@75Hz", (*) => ChangeResolution(1280, 882, 75))
ResMenu.Add("1024x768@75Hz", (*) => ChangeResolution(1024, 768, 75))

; Attach the sub-menu to the main tray menu
A_TrayMenu.Add("Custom Resolutions", ResMenu)

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

;! ==============================================================================

#Include "%A_ScriptDir%\OCR.ahk"

A_TrayMenu.Add("Text Extractor", (*) => RunScreenOCR())

; !https://github.com/Descolada/OCR/blob/main/Examples/Example10_OCRScreenSnip.ahk
RunScreenOCR() {
    ScreenSnipperProcessName := "ScreenClippingHost.exe"
    SavedClip := ClipboardAll()
    A_Clipboard := "" ; Start off blank for clipboard detection
    RunWait "ms-screenclip:"
    WinWaitActive "ahk_exe " ScreenSnipperProcessName, , 2
    loop {
        DllCall("user32.dll\GetCursorPos", "int64P", &pt64 := 0)
        try {
            if WinGetProcessName(hWnd := DllCall("GetAncestor", "Ptr", DllCall("user32.dll\WindowFromPoint", "int64",
                pt64, "ptr"), "UInt", 2, "ptr")) != ScreenSnipperProcessName
                break
        } catch
            break

    }
    ClipWait(1, 1)
    Sleep 100
    if !DllCall("IsClipboardFormatAvailable", "uint", 2) ; Check for a bitmap stream
        return A_Clipboard := SavedClip ; Restore clipboard if user pressed Escape
    DllCall("OpenClipboard", "ptr", A_ScriptHwnd)
    hData := DllCall("GetClipboardData", "uint", 2, "ptr")
    hBitmap := DllCall("User32.dll\CopyImage", "UPtr", hData, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2000, "Ptr")
    DllCall("CloseClipboard")

    result := OCR.FromBitmap(hBitmap, { scale: 2 })
    text := rearrangeOCRresult(result)

    A_Clipboard := text
    Tooltip "Clipboard set to formatted OCR result:`n" text
    SetTimer () => Tooltip(), -7000
}

; Courtesy of rommmcek https://www.autohotkey.com/boards/viewtopic.php?f=83&t=116406&p=556071#p556071
; UPW OCR groups recognized text into areas, not lines: a known issue
; this function takes an OCR result and rearranges the recognized text into the lines where they appear
; - result: an OCR result
; - diff: tolerance of the lines/words. If 0 auto setting will occur (medium height (in pixels) of the text).
; returns a string with the recognized lines, separated by linefeed
rearrangeOCRresult(result, diff := 0) {
    /*diff - (UInt) tolerance of the lines/words. If 0 auto setting will occur (medium height (in pixels) of the text).
      wr - (boolean) word, if false lines (as outputed by EasyOCR) will be processed, otherwise words.
      ht - (UInt) horizontal iteration for minimal formatting. If 0 no horizontal formatting will occure.
      vt - (UInt) vertical iteration for minimal formatting. If 0 no vertical formatting will occure.
      hd - (UInt) horizontal distance, a factor of how many diff units should trigger horizontal formating.
      vd - (UInt) vertical distance, a factor of how many diff units should trigger vertical formating.
      ds - (UInt) diff scaling factor to manually correct auto setting.
      arr - (internal) array to sort lines/words.
      hm - (internal) used to get medium height of the text.
      txt - (internal) to store lines/words.
      bb1 - (internal) below bottom 1, to approx. correct base bottom line of the text (add more characters if needed).
    bb2 - (internal) below bottom 2, to assess correction factor (add more characters if needed).*/
    local arr, hm, txt, wr, ht, vt, hd, vd, ds, aInd, lw, bb2, oy, arr, i, j, k, l, ii, oy
    loop (arr := Map(), hm := 0, txt := "", wr := 0, ht := 2, vt := 1, hd := 2, vd := 3, ds := 0.75, diff := 0, 2) {
        for lw in (aInd := A_Index, bb1 := "[,;gjpqyQ]", bb2 := "[A-Z0-9%bdfhkltij]", wr ? result.words : result.lines) {
            if (lb := wr ? lw : OCR.WordsBoundingRect(lw.Words*), aInd = 1 && !diff) {
                hm += lb.h
            } else {
                while (diff ? "" : diff := Round(ds * hm / result.lines.Length), x := lb.x, y := lb.y, w := lb.w, h :=
                lb.h, txt := lw.text, A_Index <= (ma := 2 * diff - 1)) {
                    if arr.Has(yh := (hh := Round(y + h - (RegExMatch(txt, bb1) ? RegExMatch(txt, bb2) ? h / 5 : h / 3 :
                        0))) - (A_Index - diff))
                        break
                    else A_Index = ma ? yh := hh : ""
                }
                arr.Has(yh) ? "" : arr[yh] := Map(), arr[yh][x] := [x, yh, w, h, txt]
            }
        }
    }
    mf(ks, ch, it) {
        loop (gp := "", ks * it)
            gp .= ch
        return gp
    }
    for i, j in (text := "", oy := 0, arr) {
        for k, l in (vp := (ii := i - oy) > vd * diff ? mf(Round(ii / vd / diff), "`n", vt) : "", text .= vp, oi := i,
        ok := 0, j)
            sp := (kk := k - ok) > hd * diff ? mf(Round(kk / hd / diff), "`s", ht) : "", text .= sp l[5] " ", ok := k +
            l[3], oy := l[2]
        text .= "`n"
    }
    return text
}

;! ==============================================================================

A_TrayMenu.Add("Check SpotiFLAC Server", (*) => CheckSpotiflacServer())

CheckSpotiflacServer() {

    ; Path to SpotiFLAC.exe (replace with the full path if it's not in the same folder as this script)
    global spotiFlacPath := "C:\Users\" . A_UserName . "\Downloads\SpotiFLAC.exe"

    SetTimer CheckServerStatus, 60000 ; Check every 60 seconds

    CheckServerStatus() {
        static lastNotifiedHour := -1

        currentHour := Integer(A_Hour)

        ; Check if current hour is divisible by 3 (0, 3, 6, 9, 12, 15, 18, 21)
        isUptimeHour := (Mod(currentHour, 3) == 0)

        ; Trigger action once at the start of each uptime window
        if (isUptimeHour && lastNotifiedHour != currentHour) {

            ; Launch SpotiFLAC
            try {
                Run spotiFlacPath
            } catch {
                TrayTip "Server is online, but failed to launch SpotiFLAC. Check the file path.", "Error", "16"
            }

            ; Show notification and play alert sound
            TrayTip "Server is ONLINE! SpotiFLAC has been launched.", "Server Status Alert", 1
            SoundPlay "*-1"

            ; Remember this hour so it doesn't trigger repeatedly every minute
            lastNotifiedHour := currentHour
        }
    }
}

;! ==============================================================================

A_TrayMenu.Add() ; Add a separator line to the existing tray menu
A_TrayMenu.Add("Exit", (*) => ExitApp()) ; Add Exit item to the bottom of the tray menu

;! ==============================================================================
;! ==========================  ADD KEYBOARD SHORTCUTS  ==========================
;! ==============================================================================

;! ==============================================================================

!`:: ; press alt + `
{
    static Toggle := 0
    Toggle := !Toggle

    if (Toggle) {
        ; Send "{Up down}"          ; Presses down up-arrow key.
        Send "{W down}"           ; Presses down W key.
        Send "{LShift down}"      ; Presses down Left Shift key.
        ; Send "{Click down}"         ; Hold down Left Click
    } else {
        ; Send "{Up up}"          ; Releases up-arrow key.
        Send "{W up}"           ; Releases W key.
        Send "{LShift up}"      ; Releases Left Shift key.
        ; Send "{Click up}"         ; Releases Left Click
    }
}

^!x:: ; press ctrl + alt + x
{
    WinSetAlwaysOnTop -1, "A"
}

;! ==============================================================================

; --- SPAM LEFT CLICK (CTRL + ALT + .) ---
global SpamClicker := false

^!.:: ; ctrl + alt + .
{
    global SpamClicker
    SpamClicker := !SpamClicker ; Toggle between true and false

    if (SpamClicker) {
        SetTimer(SpamClickAction, 100) ; Start clicking every 100ms
    } else {
        SetTimer(SpamClickAction, 0) ; Stop clicking
    }
}

SpamClickAction() {
    Send "{Click}"
}

;! ==============================================================================

; --- ROBLOX AUTO CLICKER (PAGE DOWN) ---
global RobloxClicker := false

PgDn:: ; press page down
{
    global RobloxClicker
    RobloxClicker := !RobloxClicker ; Toggle between true and false

    if (RobloxClicker) {
        if WinExist("Roblox") {
            WinActivate
            SetTimer(RobloxClickAction, 300) ; Start clicking every 300ms
        } else {
            RobloxClicker := false ; Reset toggle if Roblox isn't open
        }
    } else {
        SetTimer(RobloxClickAction, 0) ; Stop clicking
    }
}

RobloxClickAction() {
    Click
}

;! ==============================================================================

#Include "%A_ScriptDir%\Microphone Loopback.ahk"

^!o:: ; press ctrl + alt + o
{
    MicrophoneLoopbackFunction() ; call the function from included file
}

;! ==============================================================================

^!m:: ; press ctrl + alt + m
{
    ; if there's no scrcpy.exe window active
    if not (WinExist("ahk_exe scrcpy.exe")) {
        ; Sends a hotkey presses
        Send "^!p" ; Opens a scrcpy no console (ctrl + alt + p)
        Sleep 5000 ; Delay for 5s
    }

    MicrophoneLoopbackFunction() ; call the function from included file
}

;! ==============================================================================

PgUp:: ; press page up
{
    Reload
}

;! ==============================================================================

!F1:: ; press alt + f1
{
    Send "!t" ; toggle twitch theatre mode
    Send "{F1}" ; toggle vertical tabs
}

;! ==============================================================================

Insert:: ; press insert
{
    RunWait(
        'powershell.exe -ExecutionPolicy Bypass -File "'
        A_MyDocuments '\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1"',
        , 'Hide'  ; Hides the PowerShell window
    )
}

;! ==============================================================================

ScrollLock:: ; press scroll lock
{
    SetWorkingDir A_ProgramFiles "\obs-studio\bin\64bit" ; cd to OBS directory
    Run "obs64.exe --minimize-to-tray --startreplaybuffer"
}
