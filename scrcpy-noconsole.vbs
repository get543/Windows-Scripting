strCommand = "cmd /c %SystemDrive%\scrcpy\scrcpy.exe --video-bit-rate=20M --turn-screen-off"

For Each Arg In WScript.Arguments
    strCommand = strCommand & " """ & replace(Arg, """", """""""""") & """"
Next

CreateObject("Wscript.Shell").Run strCommand, 0, false
