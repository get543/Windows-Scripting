$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# run with admin access.
if (!$isAdmin) { return Write-Host "Please run this function with admin access." }

$version = (Invoke-RestMethod -Uri "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" | Select-String -Pattern "tag_name=v(.{1,20}\d)").Matches.Groups[1].Value
$filename = "scrcpy-win64-v${version}.zip"
$githubrepo = "https://github.com/Genymobile/scrcpy/releases/latest/download/${filename}"

if (Test-Path -Path "C:\scrcpy" -ErrorAction Stop) {
    # set location to $HOME to avoid error "directory is being use" & remove the entire scrcpy folder
    Set-Location $HOME && Remove-Item "C:\scrcpy" -Force -Recurse -ErrorAction Stop
}

Invoke-WebRequest -Uri "$githubrepo" -OutFile "C:\${filename}" # download
Expand-Archive -Path "C:\${filename}" -DestinationPath "C:\" -Force # extract .zip
Remove-Item "C:\${filename}" -Force # remove .zip
Rename-Item "C:\scrcpy-win64-v${version}" -NewName "scrcpy" # rename extracted folder
Set-Location "C:\scrcpy" # target folder
Get-ChildItem # list content inside that folder