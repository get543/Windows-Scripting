<#
TODO : Download progress bar
- https://stackoverflow.com/questions/21422364/is-there-any-way-to-monitor-the-progress-of-a-download-using-a-webclient-object
- https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-progress?view=powershell-7.3
#>

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# run with admin access.
if (!$isAdmin) { return Write-Host "Please run this function with admin access." }

$version = (Invoke-RestMethod -Uri "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" | Select-String -Pattern "tag_name=v(.{1,20}\d)").Matches.Groups[1].Value
$filename = "scrcpy-win64-v${version}.zip"
$githubrepo = "https://github.com/Genymobile/scrcpy/releases/latest/download/${filename}"

if (Test-Path -Path "${env:HOMEDRIVE}\scrcpy" -ErrorAction Stop) {
    Get-Process adb.exe -ErrorAction SilentlyContinue | Stop-Process # stop 'adb.exe' process because sometimes it causes error
    Set-Location $env:HOMEDRIVE # set location to $HOME to avoid "directory is being use" error
    Remove-Item "${env:HOMEDRIVE}\scrcpy" -Force -Recurse -ErrorAction Stop # remove the old scrcpy folder
}

Invoke-WebRequest -Uri "$githubrepo" -OutFile "${env:HOMEDRIVE}\${filename}" # download
Expand-Archive -Path "${env:HOMEDRIVE}\${filename}" -DestinationPath "${env:HOMEDRIVE}\" -Force # extract .zip
Remove-Item "${env:HOMEDRIVE}\${filename}" -Force # remove .zip
Rename-Item "${env:HOMEDRIVE}\scrcpy-win64-v${version}" -NewName "scrcpy" # rename extracted folder
Set-Location "${env:HOMEDRIVE}\scrcpy" # target folder
Get-ChildItem # list content inside that folder