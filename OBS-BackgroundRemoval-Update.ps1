$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# run with admin access.
if (!$isAdmin) { return Write-Host "Please run this function with admin access." }


$githubUsername = "occ-ai"
$githubRepo = "obs-backgroundremoval"
$filename = "obs-backgroundremoval-${version}-windows-x64-Installer.exe"

$version = (Invoke-RestMethod -Uri "https://api.github.com/repos/${githubUsername}/${githubRepo}/releases/latest" | Select-String -Pattern "tag_name=(.{1,20}\d)").Matches.Groups[1].Value
$githubFullLink = "https://github.com/${githubUsername}/${githubRepo}/releases/latest/download/${filename}"

if (Test-Path -Path "${env:USERPROFILE}\Downloads\obs-backgroundremoval-*-windows-x64-Installer.exe" -ErrorAction Stop) {
    Write-Host "Removing old obs-backgroundremoval.exe file..."; Remove-Item "${env:USERPROFILE}\Downloads\obs-backgroundremoval-*-windows-x64-Installer.exe"
}

Write-Host "Downloading file from github..."; Invoke-WebRequest -Uri "${githubFullLink}" -OutFile "${env:USERPROFILE}\Downloads\${filename}" # download
Write-Host "Changing to Downloads folder..."; Set-Location "${env:USERPROFILE}\Downloads"
Write-Host "Executing .exe"; .\${filename}
Write-Host "Delay 20s..."; Start-Sleep 20
Write-Host "Removing ${filename}..."; Remove-Item "${env:USERPROFILE}\Downloads\${filename}"