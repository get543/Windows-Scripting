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
function df() {
    if ($args -eq "-H") { Get-Volume }
}
function export() {
    $env:PATH -Replace ";", "`n"
}
function uptime() {
    Get-Uptime -Since
}
function sudo() {
    if ($isAdmin) {
        return Write-Host "This instance of PowerShell is already on admin access."
    }

    if ($args.Count -gt 0) {
        if (Test-Path("${env:PROGRAMFILES}\PowerShell\7\pwsh.exe")) { # powershell 7
            Start-Process -FilePath "${PSHOME}\pwsh.exe" -Verb RunAs -ArgumentList "-NoExit", "-Command ${args}"
        }
        else { # powershell v1
            Start-Process -FilePath "${env:SystemRoot}\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList "-NoExit", "-Command ${args}"
        }
    }
    else {
        if (Test-Path("${env:LOCALAPPDATA}\Microsoft\WindowsApps\wt.exe")) { # windows terminal
            Start-Process "${env:LOCALAPPDATA}\Microsoft\WindowsApps\wt.exe" -Verb RunAs
        }
        elseif (Test-Path("${env:PROGRAMFILES}\PowerShell\7\pwsh.exe")) { # powershell 7
            Start-Process -FilePath "${PSHOME}\pwsh.exe" -Verb RunAs
        }
        else { # powershell v1
            Start-Process -FilePath "${env:SystemRoot}\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs
        }
    }
}
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name read -Value Read-Host
function file() {
    if ($args.Count -gt 0) {
        foreach ($path in $args) {
            Start-Process "${path}"
        }
    }
    else {
        Start-Process $args
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
function reboot() {
    shutdown /r /t 0 /c "Restarting system"
}
function poweroff() {
    shutdown /s /t 0 /c "Shutdown system"
}
function ipaddr() {
    (ipconfig | Select-String -Pattern "IPv4 Address. . . . . . . . . . . : (.{1,50}\d)").Matches.Groups[1].Value
}
function pythonpipupgrade() {
    pip list --format freeze | ForEach-Object {
        pip install --upgrade $_.split('==')[0]
    }
}
function timer($amount, $unit) {
    if ($unit -eq "sec") {
        for ($i = $amount; $i -ge 0; $i--) {
            Clear-Host
            Write-Host $i
            Start-Sleep 1
        }
    } elseif ($unit -eq "min") {
        for ($i = ($amount * 60); $i -ge 0; $i--) {
            Clear-Host
            Write-Host $i
            Start-Sleep 1
        }
    }

    ShowNotification "Done!" "Timer Finished!"
}
function bash() {
    & "${env:ProgramFiles}\Git\bin\bash.exe"
}
function convert() {
    python E:\UDIN\Code\code-desktop\Python\Python-Currency-Converter\convert_currency.py $args
}
function temperature() {
    python E:\UDIN\Code\code-desktop\Python\Python-Temperature-Converter\convert_temperature.py $args
}

######################## From My Linux Machine
function codefolder() {
    if (Test-Path -Path "E:\UDIN\Code\code-desktop") {
        Set-Location "E:\UDIN\Code\code-desktop"
    } elseif (Test-Path -Path "${env:USERPROFILE}\Documents\Code Folder\code-desktop") {
        Set-Location "${env:USERPROFILE}\Documents\Code Folder\code-desktop"
    }
}
function kuliah() {
    if (Test-Path -Path "E:\UDIN\Kuliah\Mata Kuliah") {
        Set-Location "E:\UDIN\Kuliah\Mata Kuliah"
    } elseif (Test-Path -Path "${env:USERPROFILE}\Documents\Kuliah\Mata Kuliah") {
        Set-Location "${env:USERPROFILE}\Documents\Kuliah\Mata Kuliah"
    }
}
function scrcpyupdate() {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\ScreenCopyUpdate.ps1"
}
function matrix() {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\Matrix.bat"
}
function phone() {
    & "${env:HOMEDRIVE}\scrcpy\scrcpy.exe" --video-bit-rate=20M --turn-screen-off --stay-awake
}
function sound() {
    mmsys.cpl sounds,1
}
function mirror() {
    sound
    phone
}
function editrc() {
    code $PROFILE
}
function reload() {
    & $PROFILE
}
function sync() {
    syncthing --no-browser
}
function hosts() {
    code $env:SystemRoot\System32\drivers\etc\hosts
}


######################## Windows Style Aliases
function md5() { Get-FileHash -Algorithm MD5 $args }
function sha1() { Get-FileHash -Algorithm SHA1 $args }
function sha256() { Get-FileHash -Algorithm SHA256 $args }
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

######### Run Scripts #########
function SystemUpgrade() {
    param(
        [Parameter(ParameterSetName = 'Option')] [ValidateSet("yes", "assume-yes", "assumeyes", "answersyes", "answers-yes", "half-yes","normal", "regular", "update", "upgrade", "cleanup", "deletetempfiles", "deletetemp")] [String] $Option,
        [Parameter(ParameterSetName = 'GetHelp')] [ValidateSet("all", "full")] [String] $Help
    )    

    if ($Option -eq "GUI") {
        if (Test-Path -Path "E:\UDIN\Code\WINDOWS\GUI") {
            return & "E:\UDIN\Code\WINDOWS\GUI\SystemUpgrade-GUI.ps1"
        } elseif (Test-Path -Path "${env:USERPROFILE}\Documents\Code Folder\Windows\GUI") {
            return & "${env:USERPROFILE}\Documents\Code Folder\Windows\GUI\SystemUpgrade-GUI.ps1"
        }
    }
    
    if ($Help) {
        & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1" -Help $Help
    } else {
        & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1" -Option $Option
    }
}
function ChangeOutputDevice() {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\ChangeOutputDevice.ps1"
}
function NetSpeedMonitor() {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\NetSpeedMonitor.ps1"
}
function WinUtil() {
    Invoke-WebRequest -useb "https://christitus.com/win" | Invoke-Expression
}
function XAMPP() {
    & "${env:HOMEDRIVE}\xampp\xampp_shell.bat"
}

######### Change Folder #########
function Scripts() {
    Set-Location "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting"
}
function USBScripts() {
    Set-Location "F:\Code\WINDOWS\Scripts"
}
function WindowsUpdateFolder() {
    Set-Location "${env:windir}\SoftwareDistribution\Download"
}
function WinGetFolder {
    Set-Location "${env:LOCALAPPDATA}\Microsoft\WinGet"
}
function ChocolateyApps() {
    Set-Location "${env:HOMEDRIVE}\ProgramData\chocolatey\lib"
}
function AutoHotKeyFolder() {
    Set-Location "${env:USERPROFILE}\Documents\AutoHotkey"
}

function SignOut() {
    shutdown /L
}
function RestartToUEFI() {
    shutdown /r /fw
}
function RestartToRecovery() {
    shutdown /r /o
}
function WindowsUpdateChoose($kbarticleid) {
    Get-WindowsUpdate -Install -AcceptAll -KBArticleID "${kbarticleid}"
}
function WindowsUpdateAll() {
    Get-WindowsUpdate -Install -AcceptAll
}
function FirefoxProfile() {
    Set-Location "${env:APPDATA}\Mozilla\Firefox\Profiles\jrecet5l.default-release"
    
}

######################## Application Shortcut (admin)
function firefox() {
    Start-Process -FilePath "${env:ProgramFiles}\Mozilla Firefox\firefox.exe" -Verb RunAs
}
function discord() {
    Start-Process -FilePath "${env:LOCALAPPDATA}\Discord\Update.exe" -Verb RunAs
}


#######################################################################################################################
#                                  Requirement for Oh-My-Posh, Chocolatey, Winget                                     #
#######################################################################################################################
# Import PowerShell Theme from oh-my-posh
oh-my-posh init pwsh --config $env:POSH_THEMES_PATH/takuya.omp.json | Invoke-Expression

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
#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1 # Disable python venv prompt
