strCommand = "cmd /c %SystemDrive%\scrcpy\scrcpy.exe --video-bit-rate=32M --turn-screen-off --stay-awake --max-fps=60"

For Each Arg In WScript.Arguments
    strCommand = strCommand & " """ & replace(Arg, """", """""""""") & """"
Next

CreateObject("Wscript.Shell").Run strCommand, 0, false
