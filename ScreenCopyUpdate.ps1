$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# run with admin access.
if (!$isAdmin) { return Write-Host "Please run this function with admin access." }

$version = (Invoke-RestMethod -Uri "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" | Select-String -Pattern "tag_name=v(.{1,20}\d)").Matches.Groups[1].Value
$filename = "scrcpy-win64-v${version}.zip"
$githubrepo = "https://github.com/Genymobile/scrcpy/releases/latest/download/${filename}"

if (Test-Path -Path "${env:HOMEDRIVE}\scrcpy" -ErrorAction SilentlyContinue) {
    Write-Host "Stoping adb.exe process..."; taskkill /im adb.exe /f # stop 'adb.exe' process because sometimes it causes error
    Write-Host "Get out from scrcpy directory by changing directory to C:\ drive..."; Set-Location $env:HOMEDRIVE # set location to $HOME to avoid "directory is being use" error
    Write-Host "Removing old scrcpy directory..."; Remove-Item "${env:HOMEDRIVE}\scrcpy" -Force -Recurse -ErrorAction SilentlyContinue # remove the old scrcpy folder
}

Write-Host "Downloading .zip file from github..."; Invoke-WebRequest -Uri "${githubrepo}" -OutFile "${env:HOMEDRIVE}\${filename}" # download
Write-Host "Extracting .zip file to C:\ drive..."; Expand-Archive -Path "${env:HOMEDRIVE}\${filename}" -DestinationPath "${env:HOMEDRIVE}\" -Force # extract .zip
Write-Host "Removing .zip file..."; Remove-Item "${env:HOMEDRIVE}\${filename}" -Force # remove .zip
Write-Host "Renaming extracted .zip file to to something simpler like scrcpy..."; Rename-Item "${env:HOMEDRIVE}\scrcpy-win64-v${version}" -NewName "scrcpy" -Force # rename extracted folder
Write-Host "Go inside the scrcpy direcory..."; Set-Location "${env:HOMEDRIVE}\scrcpy" # target folder
Write-Host "Listing all files and folders in scrcpy directory..."; Get-ChildItem # list content inside that folder