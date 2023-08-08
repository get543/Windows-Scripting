# Windows-Scripting
Doing automation script on Windows using PowerShell.

**Before executing the scripts you must change the execution policy on running scripts on windows.**

> `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser` 
> Allow it to run scripts only for current user.

> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`
> Allow it to run scripts only for current session.

# `ChangeOutputDevice.ps1`
- Change output device from my speaker to headphones or vice versa.
- Change the output device using the device ID.
- It is using the `AudioDeviceCmdlets` PowerShell Module.

# `Matrix.bat`
- Code for doing the famous matrix effect.
- Created a long time ago, probably there is a better method.

# `ScreenCopyUpdate.ps1`
- Script for updating ScreenCopy (scrcpy) software.
- Using github's api link to get the latest version number, then download the latest package using that number.

# `SystemUpgrade.ps1`
- Update outdated PowerShell module.
- Update Windows, using the `PSWindowsUpdate` PowerShell module.
- Update most application installed on the system with the help of `winget` and `choco`.
- Scan for any corruption system files and fix them if possible.
- Clean unused files and folders in the system.

# `Microsoft.PowerShell_profile.ps1`
- PowerShell profile

# `Uninstaller.ps1`
- Uninstall default windows applications.
- Can be done with `winget` or with `Get-AppxPackage` command.