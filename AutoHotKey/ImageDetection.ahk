#Requires AutoHotkey v2.0

;! DOES NOT WORK ON VALORANT!

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

F12::
{
    MsgBox("Scanning started. I will click the target as soon as I see it.")
    Loop
    {
        ; Search for the image with a variation of 20 (to handle slight color shifts)
        ; Make sure to update the file path to your actual image!
        if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*20 C:\Users\" A_UserName "\Downloads\reyna agent select.png"))
        {
            SoundPlay("C:\Windows\Media\notify.wav") ; Play a notification sound

            if (WinExist("VALORANT")) {
                WinActivate("VALORANT") ; Activate Valorant window
                
                ; Optional: Move mouse slightly to the center of the image (e.g., +10 pixels)
                ; otherwise it clicks the top-left corner of the match.
                ClickX := FoundX + 50
                ClickY := FoundY + 50
    
                ; MouseClick("Left", ClickX, ClickY)
                Sleep(500)

                ; MouseMove(ClickX, ClickY, 0)
                ; Click("Down")
                ; Sleep(100)
                ; Click("Up")

                Click(ClickX, ClickY)  ; Click Reyna
    
                if (ImageSearch(&FoundPlayX, &FoundPlayY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*20 C:\Users\" A_UserName "\Downloads\play reyna.png"))
                {

                    ; Client:	957, 697 (recommended)
                    ; Window:	961, 698 (default)
                    Sleep(500)
                    Click(FoundPlayX + 50, FoundPlayY + 50)  ; Click Play
                }
            }

            ToolTip("Target found and clicked! Stopping search.")
            SetTimer(() => ToolTip(), -3000) ; Remove tooltip after 3 seconds
            break  ; Break out of the loop so it stops searching
        }

        ; IMPORTANT: Sleep for 500ms (half a second) to prevent high CPU usage
        Sleep(500)
    }
}

; Press Alt + ` to force stop the script if it gets stuck looking
!`::ExitApp()