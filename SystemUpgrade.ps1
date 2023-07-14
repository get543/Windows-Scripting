<#
TODO Create function: user add option to automatically answers yes
TODO Find a way to make prettier: Help Menu
TODO Make shorter: Run System Cleanup (run disk cleanup, delete temporary files, and empty recycle bin)
#>

<#
.DESCRIPTION
This is a script that will update windows and applications on your system, if you install all the require powershell module. This will also update all the powershell module that is installed on your system.

.PARAMETER help
Display a help message which is basically the same thing as this one. Valid values : all

.PARAMETER option
Open up an option on how you want to run the script. Valid values : yes, assume-yes, assumeyes, answersyes, answers-yes

.EXAMPLE
.\SystemUpgrade.ps1 -help all

.EXAMPLE
.\SystemUpgrade.ps1 -option yes

.EXAMPLE
.\SystemUpgrade.ps1 -option normal

.SYNOPSIS
Use to update windows and/or update your applications.
#>

# Parameter help description
param(
    [parameter(ParameterSetName = 'Option')] [validateset("yes", "assume-yes", "assumeyes", "answersyes", "answers-yes", "normal", "regular")] [string] $Option,
    [parameter(ParameterSetName = 'GetHelp')] [validateset("all")] [string] $Help
)

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function EmptyLine() {
    Write-Host
}


<# -------------------------------------------------------- #>
<#                         Checking                         #>
<# -------------------------------------------------------- #>
function NotAdminMessage {
    EmptyLine
    Write-Host "Please run this script as an admin access." -ForegroundColor DarkRed
    Write-Host "Because almost all commands require admin access." -ForegroundColor DarkRed
    return
}


<# -------------------------------------------------------- #>
<#                      Menu or Title                       #>
<# -------------------------------------------------------- #>
function HelpMenu {
    Write-Host "This is a Help Command for this script." -ForegroundColor DarkCyan
    Write-Host "Example: .\SystemUpgrade.ps1 [parameter] [the option]"

    EmptyLine
    Write-Host "[parameter] :" -ForegroundColor DarkGreen
    Write-Host "- -help -> Display this help message."
    Write-Host "- -option -> An option on how you want to run the script."
    Write-Host "Example: .\SystemUpgrade.ps1 -help" -ForegroundColor DarkRed

    EmptyLine
    Write-Host "-option [the option] :" -ForegroundColor DarkGreen
    Write-Host "- yes -> Automatically answers yes to every questions."
    Write-Host "- assume-yes -> Automatically answers yes to every questions."
    Write-Host "- assumeyes -> Automatically answers yes to every questions."
    Write-Host "- answersyes -> Automatically answers yes to every questions."
    Write-Host "- answers-yes -> Automatically answers yes to every questions."
    Write-Host "- normal -> Run the script normally."
    Write-Host "- regular -> Run the script normally."
    Write-Host "Example: .\SystemUpgrade.ps1 -option yes" -ForegroundColor DarkRed
    Write-Host "Example: .\SystemUpgrade.ps1 -option normal" -ForegroundColor DarkRed

    EmptyLine
    Write-Host "-help [the option] :" -ForegroundColor DarkGreen
    Write-Host "- all"
    Write-Host "Example: .\SystemUpgrade.ps1 -help all" -ForegroundColor DarkRed
    return
}

function Title() {
    Clear-Host
    Write-Host "
    __| |_________________________________| |__ 
   (__| |_________________________________| |__)
      | |  Windows System Upgrade Script  | |   
    __| |_________________________________| |__ 
   (__|_|_________________________________|_|__) " -ForegroundColor Magenta
}

function EndingScript() {
    Write-Host "
    __| |_________________________________| |__ 
   (__| |_________________________________| |__)
      | |            End Script           | |   
    __| |_________________________________| |__ 
   (__|_|_________________________________|_|__) " -ForegroundColor Magenta
}

<# -------------------------------------------------------- #>
<#                     Script Function                      #>
<# -------------------------------------------------------- #>
function UpdatePowershellModule() {
    if (!(Get-Command -Name Update-Module)) {
        Write-Host "There's no Update-Module command. So the script will skip this process." -ForegroundColor Blue
        return
    }

    # main code function
    function RunUpdateModule() {
        # check if there is no output to Update-Module, then show message
        if (!(Update-Module | Write-Output)) {
            EmptyLine
            Write-Host "No need to, there's no module that needs to be updated. 😁👍" -ForegroundColor Yellow
        }
        else {
            Write-Host "Checking update for all PowerShell modules..." -ForegroundColor Yellow
            Update-Module
        }
    }

    # user add option to automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        RunUpdateModule
        return
    }

    Write-Host "Update all PowerShell module ? [Y/n] " -ForegroundColor Blue -NoNewline
    $UpdateModuleOption = Read-Host

    if (($UpdateModuleOption -eq 'Y'.ToLower()) -or ($UpdateModuleOption -eq '')) { 
        RunUpdateModule
    }
    else {
        EmptyLine
        Write-Host "Skipping PowerShell update module..." -ForegroundColor Yellow
        return
    }
}

function WindowsUpdateScript() {
    if (!(Get-Module -Name "PSWindowsUpdate" -ListAvailable) -and !(Get-Command -Name Get-WindowsUpdate)) { return }

    # main code function
    function RunWindowsUpdate() {
        do {
            # check if there is no windows update, then break the loop
            if (!(Get-WindowsUpdate | Write-Output)) { 
                EmptyLine
                Write-Host "No Windows Update detected. 😁👍" -ForegroundColor Yellow
                break   
            }

            Clear-Host
            Write-Host "Checking Windows Update..." -ForegroundColor Yellow
            Get-WindowsUpdate -Verbose

            EmptyLine
            Write-Host "Type the KB Article ID! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : KB5026958 KB2267602" -ForegroundColor Red
            EmptyLine

            $WindowsUpdateChoose = Read-Host -Prompt "KB Article ID "

            if ((!$WindowsUpdateChoose) -or ($WindowsUpdateChoose -eq 'exit'.ToLower())) {
                EmptyLine
                Write-Host "Exiting Windows Update..." -ForegroundColor Yellow
                break
            }
            else {
                $ArrayID = $WindowsUpdateChoose.Split(" ")

                Clear-Host
                foreach ($KBArticleID in $ArrayID) {
                    Write-Host "Downloading Windows Update..." -ForegroundColor Yellow
                    Get-WindowsUpdate -Verbose -Install -AcceptAll -KBArticleID $KBArticleID
                }
            }

            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option to automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        EmptyLine
        Write-Host "Checking Windows Update..." -ForegroundColor Yellow
        Get-WindowsUpdate -Verbose

        EmptyLine
        Write-Host "Installing Windows Update..." -ForegroundColor Yellow
        Install-WindowsUpdate -Verbose -AcceptAll
        return
    }

    Write-Host "Check for Windows Update ? [Y/n] " -ForegroundColor Blue -NoNewline
    $WindowsUpdateOption = Read-Host

    if (($WindowsUpdateOption -eq 'Y'.ToLower()) -or ($WindowsUpdateOption -eq '')) {
        RunWindowsUpdate
    }
    else {
        EmptyLine
        Write-Host "Skipping Windows Update..." -ForegroundColor Yellow
        return
    }
}

function WingetUpdateScript() {
    if (!(Get-Command -Name winget) -and !(Test-Path "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local\Microsoft\WindowsApps\winget.exe")) { return }

    # main code function
    function RunWingetUpgrade() {
        EmptyLine
        Write-Host "This is a weird one, you don't need to have admin access to run winget." -ForegroundColor Green
        Write-Host "Do you want to continue run winget as admin or start new powershell instance without admin access." -ForegroundColor Green
        Write-Host "Note: Some applications CANNOT install or update if you run winget as admin. Example : Spotify" -ForegroundColor Red
        EmptyLine

        Write-Host "Continue run winget with admin ? [Y/n] " -NoNewline -ForegroundColor Red
        $ContinueWingetWithAdmin = Read-Host

        do {
            EmptyLine
            if (($ContinueWingetWithAdmin -eq 'Y'.ToLower()) -or ($ContinueWingetWithAdmin -eq '')) {
                Write-Host "Winget upgrade will run WITH administrator privilage." -ForegroundColor Yellow
            }
            else {
                Write-Host "Winget upgrade will NOT run as an administrator." -ForegroundColor Yellow
            }
            Write-Host "Checking for upgradable winget applications..." -ForegroundColor Yellow
            winget upgrade --include-unknown
    
            EmptyLine
            Write-Host "Type the Id! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : Zoom.Zoom Git.Git BlenderFoundation.Blender" -ForegroundColor Red
            EmptyLine
    
            $WingetUpgradeChoose = Read-Host -Prompt "App Id "
    
            if ((!$WingetUpgradeChoose) -or ($WingetUpgradeChoose -eq 'exit'.ToLower())) {
                EmptyLine
                Write-Host "Exiting winget upgrade..." -ForegroundColor Yellow
                break
            }
            else {
                # turn id into array
                $ArrayID = $WingetUpgradeChoose.Split(" ")
    
                EmptyLine
                Write-Host "Application(s) that will be upgraded :"
                # each of app name in array of id
                foreach ($AppName in $ArrayID) {
                    # list all installed app, pipe it by its id and only print words after 'Found' and before '[', also replace [ with nothing
                    $MatchString = ((winget show $AppName | Select-String -Pattern "Found (.*\s[\[])").Matches.Groups[1].Value).Replace("[", "")
                    Write-Host "- " $MatchString -ForegroundColor Magenta
                }

                EmptyLine
                foreach ($AppID in $ArrayID) {
                    if (($ContinueWingetWithAdmin -eq 'Y'.ToLower()) -or ($ContinueWingetWithAdmin -eq '')) {
                        winget upgrade --include-unknown $AppID
                    }
                    else {
                        # start the process but still in admin mode (broken behaviour)
                        Start-Process "$env:HOMEDRIVE\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoNewWindow -ArgumentList "winget upgrade --include-unknown $AppID"
                    }
                }
            }
    
            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        RunWingetUpgrade
        return
    }

    Write-Host "Run winget upgrade ? [Y/n] " -ForegroundColor Blue -NoNewline
    $WingetUpgradeOption = Read-Host

    if (($WingetUpgradeOption -eq 'Y'.ToLower()) -or ($WingetUpgradeOption -eq '')) {
        RunWingetUpgrade
    }
    else {
        EmptyLine
        Write-Host "Skipping application update using winget..." -ForegroundColor Yellow
        return
    }
}

function ChocolateyUpdateScript() {
    if (!(Get-Command -Name choco) -and !(Test-Path "$env:ChocolateyInstall\choco.exe")) { return }

    # main code function
    function RunChocoUgrade() {
        do {
            choco outdated
    
            EmptyLine
            Write-Host "Type the package name! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : python hwinfo chocolatey" -ForegroundColor Red
            EmptyLine

            $ChocoUpgradeChoose = Read-Host -Prompt "App Name "
    
            if ((!$ChocoUpgradeChoose) -or ($ChocoUpgradeChoose -eq 'exit'.ToLower())) {
                EmptyLine
                Write-Host "Exiting choco upgrade..." -ForegroundColor Yellow
                break
            }
            else {
                EmptyLine
                Write-Host "Your Choice : " -NoNewline
                Write-Host "$ChocoUpgradeChoose" -ForegroundColor Magenta
                EmptyLine
    
                $Array = $ChocoUpgradeChoose.Split(" ")
                
                foreach ($App in $Array) {
                    choco upgrade --yes $App
                }
            }

            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        choco outdated

        Write-Host "Updating chocolatey application(s)..." -ForegroundColor Yellow
        choco upgrade --yes all
        return
    }

    Write-Host "Run choco upgrade ? [Y/n] " -ForegroundColor Blue -NoNewline
    $ChocoUpgradeOption = Read-Host

    if (($ChocoUpgradeOption -eq 'Y'.ToLower()) -or ($ChocoUpgradeOption -eq '')) {
        RunChocoUgrade
    }
    else {
        EmptyLine
        Write-Host "Skipping application update using Chocolatey..." -ForegroundColor Yellow
        return
    }
}

function SystemCleanup {
    # run diskcleanup
    function RunDiskCleanUp() {
        if ((Get-Command -Name cleanmgr) -and (Test-Path "$env:HOMEDRIVE\Windows\system32\cleanmgr.exe")) {
            EmptyLine
            Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
            cleanmgr.exe /d $env:HOMEDRIVE /VERYLOWDISK
        }
        else {
            EmptyLine
            Write-Host "'cleanmgr' DOES NOT exist as a command." -ForegroundColor Red
            Write-Host "Skipping this process.."
            return
        }
    }

    # remove tempfiles
    function DeleteTempFiles {
        if ((Test-Path "$env:HOMEDRIVE\Windows\Temp\") -and (Test-Path "$env:TEMP")) {
            if (!(Get-ChildItem -Path "$env:HOMEDRIVE\Windows\Temp\" | Write-Output) -and (!(Get-ChildItem -Path "$env:TEMP" | Write-Output))) {
                EmptyLine
                Write-Host "No need to, temporary folders are already empty. 😁👍" -ForegroundColor Yellow
                return
            }

            EmptyLine
            Write-Host "Deleting Temporary Files..." -ForegroundColor Yellow
            Get-ChildItem -Path "$env:HOMEDRIVE\Windows\Temp\" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        else {
            EmptyLine
            Write-Host "$env:HOMEDRIVE\Windows\Temp and temporary folder in environment variable DOES NOT exist." -ForegroundColor Red
            Write-Host "Skipping this process..."
            return
        }
    }

    # clean recycle bin
    function EmptyRecycleBin {
        if (Get-Command -Name Clear-RecycleBin) {
            EmptyLine
            Write-Host "Deleting contents inside recycle bin..." -ForegroundColor Yellow
            Clear-RecycleBin -Force
        }
        elseif (Test-Path $env:RecycleBin -ErrorAction SilentlyContinue) {
            EmptyLine
            Write-Host "Path found for recycle bin. Deleting contents inside..." -ForegroundColor Yellow
            Remove-Item -Path $env:RecycleBin -Recurse -Force
        }
        else {
            EmptyLine
            Write-Host "Neither works, 'Clear-RecycleBin' command DOES NOT exist and CANNOT find path to recycle bin." -ForegroundColor Red
            return
        }
    }

    # user add option automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        RunDiskCleanUp
        DeleteTempFiles
        EmptyRecycleBin
        return
    }

    Write-Host "Run System Cleanup (run disk cleanup, delete temporary files, and empty recycle bin) ? [Y/n] " -ForegroundColor Blue -NoNewline
    $RunSystemCleanupOption = Read-Host

    if (($RunSystemCleanupOption -eq 'Y'.ToLower()) -or ($RunSystemCleanupOption -eq '')) {
        RunDiskCleanUp
        DeleteTempFiles
        EmptyRecycleBin
    }
    else {
        EmptyLine
        Write-Host "Skipping System Cleanup..." -ForegroundColor Yellow
        return
    }
}

function ScanSystemCorruptionFiles {
    # main function code
    function RunScan {
        Write-Host "`n(1/4) Run 'chkdsk' (check disk)" -ForegroundColor Yellow
        chkdsk

        Write-Host "`n(2/4) Run 'sfc /SCANNOW' (System File Checker) - 1st scan" -ForegroundColor Yellow
        sfc /SCANNOW

        Write-Host "`n(3/4) Run DISM (Deployment Image Servicing and Management tool)" -ForegroundColor Yellow
        DISM /Online /Cleanup-Image /Restorehealth

        Write-Host "`n(4/4) Run 'sfc /SCANNOW' (System File Checker) - 2nd scan" -ForegroundColor Yellow
        sfc /SCANNOW
    }

    # user add option automatically answers yes
    if (($Option -eq "yes") -or ($Option -eq "assume-yes") -or ($Option -eq "assumeyes") -or ($Option -eq "answersyes") -or ($Option -eq "answers-yes")) {
        RunScan
        return
    }

    Write-Host "Check for system corruption files ? [Y/n] " -ForegroundColor Blue -NoNewline
    $ScanCorruptionFilesOption = Read-Host

    if (($ScanCorruptionFilesOption -eq 'Y'.ToLower()) -or ($ScanCorruptionFilesOption -eq '')) {
        RunScan
    }
    else {
        EmptyLine
        Write-Host "Skipping scan for system corruption files..." -ForegroundColor Yellow
        return
    }
}


<# -------------------------------------------------------- #>
<#          Install Prerequisite Package or Module          #>
<# -------------------------------------------------------- #>
function WindowsUpdateModuleInstall {
    Write-Host "PSWindowsUpdate Module is not installed in this system." -ForegroundColor Red
    Write-Host "PSWindowsUpdate is a PowerShell module that can install Windows Update through terminal." -ForegroundColor Green
    Write-Host "Do you want to install 'PSWindowsUpdate' module ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $PSWUInstallOption = Read-Host

    if (($PSWUInstallOption -eq 'Y'.ToLower()) -or $PSWUInstallOption -eq '') {
        Install-Module -Name PSWindowsUpdate
    }
    else {
        EmptyLine
        Write-Host "Skipping PSWindowsUpdate module install..." -ForegroundColor Yellow
        return
    }
}

function WingetInstall {
    Write-Host "winget is not installed in this system." -ForegroundColor DarkRed
    Write-Host "winget is a Windows Package Manager that enables installing applications through terminal." -ForegroundColor DarkCyan
    Write-Host "Do you want to install 'winget' package manager ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $WingetInstallOption = Read-Host

    if (($WingetInstallOption -eq 'Y'.ToLower()) -or ($WingetInstallOption -eq '')) {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Install-Script -Name winget-install -Force
        winget-install.ps1
    }
    else {
        EmptyLine
        Write-Host "Skip installing winget package manager..." -ForegroundColor Yellow
        return
    }
}

function ChocolateyInstall {
    Write-Host "Chocolatey is not installed in this system." -ForegroundColor DarkRed
    Write-Host "Chocolatey is a universal package manager for windows that enables installing applications through terminal." -ForegroundColor DarkCyan
    Write-Host "Do you want to install 'Chocolatey' package manager ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $ChocolateyInstallOption = Read-Host

    if (($ChocolateyInstallOption -eq 'Y'.ToLower()) -or ($ChocolateyInstallOption -eq '')) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
    }
    else {
        EmptyLine
        Write-Host "Skip installing Chocolatey package manager..." -ForegroundColor Yellow
        return
    }
}



################################## Run Function ##################################
function Main() {
    if (!$IsAdmin) {
        NotAdminMessage
    }

    if ($Help) {
        HelpMenu
    }

    Title
    EmptyLine
    UpdatePowershellModule

    EmptyLine
    # install PSWindowsUpdate module if isn't already
    if (! (Get-Module -Name "PSWindowsUpdate" -ListAvailable)) {
        WindowsUpdateModuleInstall
    }
    else {
        WindowsUpdateScript
    }

    EmptyLine
    # install winget if it isn't already
    if (!(Get-Command -Name winget) -and !(Test-Path "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local\Microsoft\WindowsApps\winget.exe")) {
        WingetInstall
    }
    else {
        WingetUpdateScript
    }


    EmptyLine
    # install chocolatey if isn't already
    if (!(Get-Command -Name choco) -and !(Test-Path "$env:ChocolateyInstall\choco.exe")) {
        ChocolateyInstall
    }
    else {
        ChocolateyUpdateScript
    }

    EmptyLine
    SystemCleanup

    EmptyLine
    ScanSystemCorruptionFiles

    EmptyLine
    EndingScript
}

################################## Run Function ##################################
Main
