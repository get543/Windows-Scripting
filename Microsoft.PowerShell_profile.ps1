<######################################## PowerShell Template From : ###############################
- https://gist.github.com/timsneath/19867b12eee7fd5af2ba 
- https://github.com/ChrisTitusTech/powershell-profile/blob/main/Microsoft.PowerShell_profile.ps1
####################################################################################################>
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)



#######################################################################################################################
#                                                   Custom Aliases                                                    #
#######################################################################################################################

######################## Linux Style Aliases
function touch($file) {
    "" | Out-File $file -Encoding ASCII
}
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
function find($name) {
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.directory
        Write-Output "${place_path}\${_}"
    }
}
function unzip($path, $destination) {
    Write-Host "Extracting ${path} to ${destination}"
    if (!$destination) {
        return Expand-Archive -Path "${path}" -DestinationPath "${pwd}"
    }
    Expand-Archive -Path "${path}" -DestinationPath "${destination}"
}
function df {
    if ($args -eq "-H") { Get-Volume }
}
function export {
    $env:PATH -Replace ";", "`n"
}
function uptime {
    Get-Uptime -Since
}
function sudo {
    if ($isAdmin) {
        return Write-Host "This instance of PowerShell is already on admin access."
    }

    if ($args.Count -gt 0) {
        $argList = "& '" + $args + "'"
        Start-Process "${env:ProgramFiles}\PowerShell\7\pwsh.exe" -Verb runAs -ArgumentList $argList
    }
    else {
        Start-Process "${env:LOCALAPPDATA}\pwsh.exe" -Verb runAs
    }
}
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name read -Value Read-Host
function file() {
    if ($args.Count -gt 0) {
        foreach ($path in $args) {
            explorer.exe "${path}"
        }
    }
    else {
        explorer.exe $args
    }
}
function open() {
    if ($args.Count -gt 0) {
        foreach ($app in $args) {
            & "${app}"
        }
    }
    else {
        & $args
    }
}
function reboot {
    shutdown /r /t 0 /c "Restarting system"
}
function poweroff {
    shutdown /s /t 0 /c "Shutdown system"
}


######################## From My Linux Machine
function scrcpyupdate {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\ScreenCopyUpdate.ps1"
}
function matrix {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\Matrix.bat"
}
function phone {
    & "${env:HOMEDRIVE}\scrcpy\scrcpy.exe" --shortcut-mod=lctrl,rctrl --video-bit-rate=20M --turn-screen-off
}
function sound {
    mmsys.cpl sounds,1
}
function mirror {
    sound
    phone
}
function editrc {
    code $PROFILE
}
function reload {
    & $PROFILE
}


######################## Windows Style Aliases
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }
function ShowNotification($title, $text) {
    # windows 10 notification balloon
    Add-Type -AssemblyName System.Windows.Forms
    $global:BalloonNotification = New-Object System.Windows.Forms.NotifyIcon

    $path = (Get-Process -id $pid).Path
    $BalloonNotification.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $BalloonNotification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $BalloonNotification.BalloonTipText = "${text}"
    $BalloonNotification.BalloonTipTitle = "${title}"
    $BalloonNotification.Visible = $true
    $BalloonNotification.ShowBalloonTip(5000)
}
function ChangeOutputDevice {
    $SpeakerDeviceID = "{0.0.0.00000000}.{69274eea-2c89-451d-813a-c9407258be99}"
    $HeadphoneDeviceID = "{0.0.0.00000000}.{4229d439-1b7d-4deb-894e-544bb0fa40e1}"

    # if headphones is default audio then change it to speakers
    if ((Get-AudioDevice -ID "${SpeakerDeviceID}" | Where-Object { ($_.Default -eq $true) -and ($_.Type -like "Playback") })) {
        Write-Output "Change default audio device to Speakers."
        Set-AudioDevice -ID "${HeadphoneDeviceID}"

        # if speakers is default audio then change it headphones
    }
    elseif ((Get-AudioDevice -ID "${HeadphoneDeviceID}" | Where-Object { ($_.Default -eq $true) -and ($_.Type -like "Playback") })) {
        Write-Output "Change default audio device to Headphones."
        Set-AudioDevice -ID "${SpeakerDeviceID}"
    }
}
function SystemUpgrade() { # does not work as intended
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1"
}
function Scripts {
    Set-Location "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting"
}
function USBScripts {
    Set-Location "F:\Code\WINDOWS\Scripts"
}
function ChocolateyApps {
    Set-Location "${env:HOMEDRIVE}\ProgramData\chocolatey\lib"
}
function WinUtil {
    Invoke-WebRequest -useb "https://christitus.com/win" | Invoke-Expression
}
function SignOut {
    shutdown /L
}
function RestartToUEFI {
    shutdown /r /fw
}
function WindowsUpdateChoose($kbarticle) {
    Get-WindowsUpdate -Install -AcceptAll -KBArticleID "${kbarticle}"
}
function WindowsUpdateAll {
    Install-WindowsUpdate
}


######################## Application Shortcut (admin)
function firefox {
    Start-Process -FilePath "${env:ProgramFiles}\Mozilla Firefox\firefox.exe" -Verb runAs
}
function discord {
    Start-Process -FilePath "${env:LOCALAPPDATA}\Discord\Update.exe" -Verb runAs
}



#######################################################################################################################
#                                  Requirement for Oh-My-Posh, Chocolatey, Winget                                     #
#######################################################################################################################
# Import PowerShell Theme from oh-my-posh
oh-my-posh --init --shell pwsh --config $env:POSH_THEMES_PATH/takuya.omp.json | Invoke-Expression

Import-Module -Name Terminal-Icons
Import-Module posh-git

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Tab-compleation for winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Remove-Variable identity
Remove-Variable principal