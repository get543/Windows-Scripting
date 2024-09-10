<#
TODO ValidateSet: Find a way to make it shorter
- (https://adamtheautomator.com/powershell-validateset/) 
- (https://java2blog.com/check-if-array-contains-element-powershell/)
- (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.3&viewFallbackFrom=powershell-7.1#dynamic-validateset-values)

TODO Help Menu: Find a way to make it prettier
#>

<#
.DESCRIPTION
This is a script that will update windows and applications on your system, if you install all the required powershell module. This will also update all the powershell module that is installed on your system.

.PARAMETER Help
Display a help message which is basically the same thing as this one. Valid values : all

.PARAMETER Option
Open up an option on how you want to run the script. Valid values : yes, assume-yes, assumeyes, answersyes, answers-yes, half-yes, normal, regular

.EXAMPLE
.\SystemUpgrade.ps1 -help all

.EXAMPLE
.\SystemUpgrade.ps1 -option yes

.EXAMPLE
.\SystemUpgrade.ps1 -option normal

.SYNOPSIS
Use to update windows and/or update your applications.
And with extra tools, like clean all temporary folders and old Windows Updates.
And another extra tools is check for system corruption files.
#>

param(
    [Parameter(ParameterSetName = 'Option')] [ValidateSet("yes", "assume-yes", "assumeyes", "answersyes", "answers-yes", "half-yes", "normal", "regular", "update", "upgrade", "cleanup", "deletetempfiles", "deletetemp")] [String] $Option,
    [Parameter(ParameterSetName = 'GetHelp')] [ValidateSet("all", "full")] [String] $Help
)

$AnswersYesArray = @("yes", "assume-yes", "assumeyes", "answersyes", "answers-yes")
$AnswersUpgradeArray = @("update", "upgrade")
$AnswersCleanupArray = @("cleanup", "deletetempfiles", "deletetemp")

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function EmptyLine() {
    Write-Host
}


<# -------------------------------------------------------- #>
<#                         Checking                         #>
<# -------------------------------------------------------- #>
function NotAdminMessage() {
    <#
    .SYNOPSIS
    Admin or not ?
    
    .DESCRIPTION
    Check if the script executed with admin privilages or not.
    If not, then script you immedietly exit and show error message.
    
    .NOTES
    This function is not meant to run independently
    #>
    EmptyLine
    Write-Host "Please run this script as an admin access." -ForegroundColor Red
    Write-Host "Because almost all commands require admin access." -ForegroundColor Red
}


<# -------------------------------------------------------- #>
<#                      Menu or Title                       #>
<# -------------------------------------------------------- #>
function HelpMenu() {
    <#
    .SYNOPSIS
    Help Menu Function
    
    .DESCRIPTION
    Show the help menu for all things that this script can do
    
    .EXAMPLE
    .\SystemUpgrade.ps1 -Help all
    
    .EXAMPLE
    .\SystemUpgrade.ps1 -Help full
    
    .NOTES
    This function is not meant to run independently
    #>
    Write-Host "This is a Help Command for this script." -ForegroundColor Cyan
    Write-Host "Example: .\SystemUpgrade.ps1 [parameter] [the option]"

    EmptyLine
    Write-Host "[parameter] :" -ForegroundColor Green
    Write-Host "> -help -> Display this help message."
    Write-Host "> -option -> An option on how you want to run the script."
    Write-Host "Example: .\SystemUpgrade.ps1 -help" -ForegroundColor Red

    EmptyLine
    Write-Host "-option [the option] :" -ForegroundColor Green
    Write-Host "> yes -> Automatically answers yes to every questions."
    Write-Host "> assume-yes -> Automatically answers yes to every questions."
    Write-Host "> assumeyes -> Automatically answers yes to every questions."
    Write-Host "> answersyes -> Automatically answers yes to every questions."
    Write-Host "> answers-yes -> Automatically answers yes to every questions."
    Write-Host "> half-yes -> Answers yes to all questions except for winget."
    Write-Host "> upgrade -> Answers yes to all questions for upgrades only."
    Write-Host "> update -> Answers yes to all questions for upgrades only."
    Write-Host "> cleanup -> Answers yes to delete temporary files script."
    Write-Host "> deletetempfiles -> Answers yes to delete temporary files script."
    Write-Host "> deletetemp -> Answers yes to delete temporary files script."

    Write-Host "> normal -> Run the script normally."
    Write-Host "> regular -> Run the script normally."
    Write-Host "Example: .\SystemUpgrade.ps1 -option yes" -ForegroundColor Red
    Write-Host "Example: .\SystemUpgrade.ps1 -option normal" -ForegroundColor Red

    EmptyLine
    Write-Host "-help [the option] :" -ForegroundColor Green
    Write-Host "> all"
    Write-Host "> full"
    Write-Host "Example: .\SystemUpgrade.ps1 -help all" -ForegroundColor Red
}

function Title() {
    <#
    .SYNOPSIS
    Shows the script title at the start of the script
    
    .NOTES
    This function is not meant to run independently
    #>

    Clear-Host
    Write-Host "
    __| |_________________________________| |__ 
   (__| |_________________________________| |__)
      | |  Windows System Upgrade Script  | |   
    __| |_________________________________| |__ 
   (__|_|_________________________________|_|__) " -ForegroundColor Magenta
}

function EndingScript() {
    <#
    .SYNOPSIS
    Shows end message at the end of the script after all command has finished
    
    .NOTES
    This function is not meant to run independently
    #>

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
    <#
    .SYNOPSIS
    Update PowerShell Module
    
    .DESCRIPTION
    This function updates all installed PowerShell modules if it needs to.
    
    .NOTES
    This function is not meant to run independently
    #>

    if (!(Get-Command -Name Update-Module)) {
        Write-Host "There's no Update-Module command. So the script will skip this process." -ForegroundColor Blue
        return
    }

    function RunUpdateModule() {
        <#
        .SYNOPSIS
        Main code function

        .DESCRIPTION
        This function consist of what actual commands that get run.

        .NOTES
        This function is not meant to run independently.
        This function is always run if the user chose to run outer function.
        #>

        Write-Host "Checking update for all PowerShell modules..." -ForegroundColor Yellow

        if (Get-Command -Name pwsh) {
            # automatically answers yes to all prompt, powershell V7 is installed
            Write-Output A | pwsh -c Update-Module
        }
        else {
            Update-Module -AcceptLicense
        }
    }

    # user add option to automatically answers yes or half yes or upgrade only
    if (($AnswersYesArray -Contains $Option) -or ($Option -eq "half-yes") -or ($AnswersUpgradeArray -Contains $Option)) {
        RunUpdateModule
        return
    } # user use -Option cleanup
    elseif ($AnswersCleanupArray -Contains $Option) {
        return
    }

    Write-Host "Update all PowerShell module ? [Y/n] " -ForegroundColor Blue -NoNewline
    $UpdateModuleOption = Read-Host

    if (($UpdateModuleOption.ToLower() -eq "y") -or ($UpdateModuleOption -eq "")) { 
        RunUpdateModule
    }
    else {
        EmptyLine
        Write-Host "Skipping PowerShell update module..." -ForegroundColor Yellow
        return
    }
}

function WindowsUpdateScript() {
    <#
    .SYNOPSIS
    Windows Update Script
    
    .DESCRIPTION
    This function checks for Windows Update.
    
    .NOTES
    This function is not meant to run independently.
    #>

    if (!(Get-Module -Name "PSWindowsUpdate" -ListAvailable) -and !(Get-Command -Name Get-WindowsUpdate)) { return }

    # main code function
    function RunWindowsUpdate() {
        <#
        .SYNOPSIS
        Main code function

        .DESCRIPTION
        This function consist of what actual commands that get run.
        
        .NOTES
        This function is not meant to run independently.
        This function is always run if the user chose to run outer function.
        #>

        do {
            Clear-Host
            Write-Host "Checking Windows Update..." -ForegroundColor Yellow
            Get-WindowsUpdate -Verbose

            EmptyLine
            Write-Host "Type the KB Article ID! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "Type 'all' if you want to do all Windows Updates!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : KB5026958 KB2267602" -ForegroundColor Red
            EmptyLine

            $WindowsUpdateChoose = Read-Host -Prompt "KB Article ID "

            # user typed in 'all' then do all windows updates
            if ($WindowsUpdateChoose.ToLower() -eq "all") {
                Install-WindowsUpdate -Verbose -AcceptAll -IgnoreReboot
            }

            if ((!$WindowsUpdateChoose) -or ($WindowsUpdateChoose.ToLower() -eq 'exit')) {
                EmptyLine
                Write-Host "Exiting Windows Update..." -ForegroundColor Yellow
                break
            }
            else {
                $ArrayID = $WindowsUpdateChoose.Split(" ")

                Clear-Host
                foreach ($KBArticleID in $ArrayID) {
                    Write-Host "Downloading Windows Update..." -ForegroundColor Yellow
                    Get-WindowsUpdate -Verbose -Install -IgnoreReboot -AcceptAll -KBArticleID $KBArticleID
                }
            }

            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option to automatically answers yes or half yes or upgrade only
    if (($AnswersYesArray -Contains $Option) -or ($Option -eq "half-yes") -or ($AnswersUpgradeArray -Contains $Option)) {
        EmptyLine
        Write-Host "Checking Windows Update..." -ForegroundColor Yellow
        Get-WindowsUpdate -Verbose

        EmptyLine
        Write-Host "Installing Windows Update..." -ForegroundColor Yellow
        Install-WindowsUpdate -Verbose -AcceptAll -IgnoreReboot
        return
    } # user use -Option cleanup
    elseif ($AnswersCleanupArray -Contains $Option) {
        return
    }

    Write-Host "Check for Windows Update ? [Y/n] " -ForegroundColor Blue -NoNewline
    $WindowsUpdateOption = Read-Host

    if (($WindowsUpdateOption.ToLower() -eq "y") -or ($WindowsUpdateOption -eq "")) {
        RunWindowsUpdate
    }
    else {
        EmptyLine
        Write-Host "Skipping Windows Update..." -ForegroundColor Yellow
        return
    }
}

function WingetUpdateScript() {
    <#
    .SYNOPSIS
    Winget Upgrade Script
    
    .DESCRIPTION
    This function checks for outdated winget applications and upgrades it if the user chose to.
    Not only that, it also checks the whole application installed on the system if winget can find the application on winget repository.

    .NOTES
    This function is not meant to run independently.
    This function is always run if the user chose to run outer function.
    #>

    if (!(Get-Command -Name winget) -and !(Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe")) { return }

    function RunWingetUpgrade() {
        <#
        .SYNOPSIS
        Main code function

        .DESCRIPTION
        This function consist of what actual commands that get run.

        .NOTES
        This function is not meant to run independently.
        This function is always run if the user chose to run outer function.
        #>

        do {
            EmptyLine
            Write-Host "Checking for upgradable winget applications..." -ForegroundColor Yellow
            winget upgrade --include-unknown
    
            EmptyLine
            Write-Host "Type the Id! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "Type 'all' if you want to upgrade all winget applications!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : Zoom.Zoom Git.Git BlenderFoundation.Blender" -ForegroundColor Red
            EmptyLine
    
            $WingetUpgradeChoose = Read-Host -Prompt "App Id "

            # if user typed in all, then upgrade all winget applications
            if ($WingetUpgradeChoose.ToLower() -eq "all") {
                winget upgrade --include-unknown --all
            }

            if ((!$WingetUpgradeChoose) -or ($WingetUpgradeChoose.ToLower() -eq 'exit')) {
                EmptyLine
                Write-Host "Exiting winget upgrade..." -ForegroundColor Yellow
                break
            }
            else {
                # turn id into array
                $ArrayID = $WingetUpgradeChoose.Split(" ")
    
                Clear-Host
                Write-Host "Application(s) that will be upgraded :"
                # each of app name in array of id
                foreach ($AppName in $ArrayID) {
                    # list all installed app, pipe it by its id and only print words after 'Found' and before '[', also replace [ with nothing
                    $MatchString = ((winget show $AppName | Select-String -Pattern "Found (.*\s[\[])").Matches.Groups[1].Value).Replace("[", "")
                    Write-Host "- " $MatchString -ForegroundColor Magenta
                }

                EmptyLine
                foreach ($AppID in $ArrayID) {
                    winget upgrade --include-unknown $AppID
                }
            }
    
            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option automatically answers yes or upgrade only
    if (($AnswersYesArray -Contains $Option) -or ($AnswersUpgradeArray -Contains $Option)) {
        Write-Host "Upgrading all installed applications if available..." -ForegroundColor Yellow
        winget upgrade --include-unknown --all
        return
    } # user use -Option cleanup
    elseif ($AnswersCleanupArray -Contains $Option) {
        return
    }

    Write-Host "Run winget upgrade ? [Y/n] " -ForegroundColor Blue -NoNewline
    $WingetUpgradeOption = Read-Host

    if (($WingetUpgradeOption.Tolower() -eq "y") -or ($WingetUpgradeOption -eq "")) {
        RunWingetUpgrade
    }
    else {
        EmptyLine
        Write-Host "Skipping application update using winget..." -ForegroundColor Yellow
        return
    }
}

function ChocolateyUpdateScript() {
    <#
    .SYNOPSIS
    Chocolatey Upgrade Script
    
    .DESCRIPTION
    This function checks for outdated Chocolatey applications only and
    updates it if the user chose to.
    
    .NOTES
    This function is not meant to run independently.
    #>

    if (!(Get-Command -Name choco) -and !(Test-Path "$env:ChocolateyInstall\choco.exe")) { return }

    function RunChocoUgrade() {
        <#
        .SYNOPSIS
        Main code function

        .DESCRIPTION
        This function consist of what actual commands that get run.

        .NOTES
        This function is not meant to run independently.
        This function is always run if the user chose to run outer function.
        #>

        do {
            choco outdated
    
            EmptyLine
            Write-Host "Type the package name! Type 'exit' or leave it empty to skip this step!" -ForegroundColor Green
            Write-Host "Type 'all' if you want to upgrade all packages!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : python hwinfo chocolatey" -ForegroundColor Red
            EmptyLine

            $ChocoUpgradeChoose = Read-Host -Prompt "App Name "
    
            if ((!$ChocoUpgradeChoose) -or ($ChocoUpgradeChoose.ToLower() -eq 'exit')) {
                EmptyLine
                Write-Host "Exiting choco upgrade..." -ForegroundColor Yellow
                break
            }
            else {
                Clear-Host
                Write-Host "Your Choice : " -NoNewline
                Write-Host "$ChocoUpgradeChoose" -ForegroundColor Magenta
                EmptyLine

                # if you answers all, then just upgrade all
                if ($ChocoUpgradeChoose.ToLower() -eq "all") {
                    choco upgrade --yes all
                }

                $Array = $ChocoUpgradeChoose.Split(" ")
                
                foreach ($App in $Array) {
                    choco upgrade --yes $App
                }
            }

            Start-Sleep 8
            Clear-Host
        } while ($true)
    }

    # user add option automatically answers yes or half yes or upgrade only
    if (($AnswersYesArray -Contains $Option) -or ($Option -eq "half-yes") -or ($AnswersUpgradeArray -Contains $Option)) {
        choco outdated

        Write-Host "Updating all chocolatey application(s)..." -ForegroundColor Yellow
        choco upgrade --yes all
        return
    } # user use -Option cleanup
    elseif ($AnswersCleanupArray -Contains $Option) {
        return
    }

    Write-Host "Run choco upgrade ? [Y/n] " -ForegroundColor Blue -NoNewline
    $ChocoUpgradeOption = Read-Host

    if (($ChocoUpgradeOption.ToLower() -eq "y") -or ($ChocoUpgradeOption -eq "")) {
        RunChocoUgrade
    }
    else {
        EmptyLine
        Write-Host "Skipping application update using Chocolatey..." -ForegroundColor Yellow
        return
    }
}

function ScanSystemCorruptionFiles() {
    <#
    .SYNOPSIS
    System Corruption Scan
    
    .DESCRIPTION
    This function scans for system corruption files and tries to fix it.
    
    .NOTES
    This function is not meant to run independently.
    #>

    function RunScan() {
        <#
        .SYNOPSIS
        Main code function
        
        .DESCRIPTION
        This function consist of what actual commands that get run.

        .NOTES
        This function is not meant to run independently.
        This function is always run if the user chose to run outer function.
        #>

        Write-Host "`n(1/4) Run 'chkdsk' (check disk)" -ForegroundColor Yellow
        chkdsk /scan

        Write-Host "`n(2/4) Run 'sfc /SCANNOW' (System File Checker) - 1st scan" -ForegroundColor Yellow
        sfc /SCANNOW

        Write-Host "`n(3/4) Run DISM (Deployment Image Servicing and Management tool)" -ForegroundColor Yellow
        DISM /Online /Cleanup-Image /Restorehealth

        Write-Host "`n(4/4) Run 'sfc /SCANNOW' (System File Checker) - 2nd scan" -ForegroundColor Yellow
        sfc /SCANNOW
    }

    # user add option automatically answers yes or half yes
    if (($AnswersYesArray -Contains $Option) -or ($Option -eq "half-yes")) {
        RunScan
        return
    } # user use -Option upgrade or -Option cleanup
    elseif ($AnswersUpgradeArray -Contains $Option -or ($AnswersCleanupArray -Contains $Option)) {
        return
    }

    Write-Host "Check for system corruption files ? [Y/n] " -ForegroundColor Blue -NoNewline
    $ScanCorruptionFilesOption = Read-Host

    if (($ScanCorruptionFilesOption.ToLower() -eq "y") -or ($ScanCorruptionFilesOption -eq "")) {
        RunScan
    }
    else {
        EmptyLine
        Write-Host "Skipping scan for system corruption files..." -ForegroundColor Yellow
        return
    }
}

function SystemCleanup {
    <#
    .SYNOPSIS
    System Cleanup
    
    .DESCRIPTION
    This function delete all temporary files and old Windows Update.
    Also delete all unnesessary files and browser cache.
    It is using the Disk Clean-up tool.
    
    .NOTES
    This function is not meant to run independently.
    #>


    function RunDiskCleanUp() {
        <#
        .SYNOPSIS
        Run Disk Clean-up Utility

        .DESCRIPTION
        Run Disk Clean-up.
        And exit this function if it doesn't find Disk Clean-up tool.
        
        .NOTES
        This function is not meant to run independently.
        #>

        if ((Get-Command -Name cleanmgr) -and (Test-Path "$env:windir\system32\cleanmgr.exe")) {
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

    function DeleteTempFiles() {
        <#
        .SYNOPSIS
        Delete Temporary Files

        .DESCRIPTION
        Delete all temporary files and folders in Windows Temp directory.
        And exits if it doesn't find that directory.
        
        .NOTES
        This function is not meant to run independently.
        #>
    
        if ((Test-Path "$env:windir\Temp") -and (Test-Path "$env:TEMP")) {
            if (!(Get-ChildItem -Path "$env:windir\Temp" | Write-Output) -and !(Get-ChildItem -Path "$env:TEMP" | Write-Output)) {
                EmptyLine
                Write-Host "No need to, temporary folders are already empty. 😁👍" -ForegroundColor Yellow
                return
            }

            EmptyLine
            Write-Host "Deleting Temporary Files..." -ForegroundColor Yellow
            Get-ChildItem -Path "$env:windir\Temp" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        else {
            EmptyLine
            Write-Host "$env:windir\Temp and temporary folder in environment variable DOES NOT exist." -ForegroundColor Red
            Write-Host "Skipping this process..."
            return
        }
    }

    function EmptyRecycleBin() {
        <#
        .SYNOPSIS
        Empty Recycle Bin

        .DESCRIPTION
        Delete all files and folders in the recycle bin.
        If it doesn't find the recycle bin, or if anything goes wrong,
        just exit this function
        
        .NOTES
        This function is not meant to run independently.
        #>

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

    # user add option automatically answers yes or half yes
    if (($AnswersYesArray -Contains $Option) -or ($Option -eq "half-yes") -or ($AnswersCleanupArray -Contains $Option)) {
        RunDiskCleanUp
        DeleteTempFiles
        EmptyRecycleBin
        return
    } # user add option upgrade skip this function
    elseif ($AnswersUpgradeArray -Contains $Option) {
        return
    }

    Write-Host "Delete unused files and folders ? [Y/n] " -ForegroundColor Blue -NoNewline
    $RunSystemCleanupOption = Read-Host

    if (($RunSystemCleanupOption.ToLower() -eq "y") -or ($RunSystemCleanupOption -eq "")) {
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


<# -------------------------------------------------------- #>
<#          Install Prerequisite Package or Module          #>
<# -------------------------------------------------------- #>
function WindowsUpdateModuleInstall() {
    <#
    .SYNOPSIS
    PSWindowsUpdate PowerShell Module Install
    
    .DESCRIPTION
    Install Windows Update PowerShell module to be able to update windows from the terminal.
    It will install the script if the user chose to do so.
    
    .NOTES
    This function is not meant to run independently.
    This function only going to run if PSWindowsUpdate module is not installed.
    #>

    Write-Host "PSWindowsUpdate Module is not installed in this system." -ForegroundColor Red
    Write-Host "PSWindowsUpdate is a PowerShell module that can install Windows Update through terminal." -ForegroundColor Green
    Write-Host "Do you want to install 'PSWindowsUpdate' module ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $PSWUInstallOption = Read-Host

    if (($PSWUInstallOption.ToLower() -eq "y") -or $PSWUInstallOption -eq "") {
        Install-Module -Name PSWindowsUpdate
    }
    else {
        EmptyLine
        Write-Host "Skipping PSWindowsUpdate module install..." -ForegroundColor Yellow
        return
    }
}

function WingetInstall() {
    <#
    .SYNOPSIS
    Install Winget
    
    .DESCRIPTION
    Install Winget to be able to update all applications from the terminal.
    It will install the script if the user chose to do so.
    It installs the winget-install PowerShell module and running the winget-install.ps1 script.

    .NOTES
    This function is not meant to run independently.
    This function only going to run if winget is not installed.
    #>
    
    Write-Host "winget is not installed in this system." -ForegroundColor Red
    Write-Host "winget is a Windows Package Manager that enables installing applications through terminal." -ForegroundColor Cyan
    Write-Host "Do you want to install 'winget' package manager ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $WingetInstallOption = Read-Host

    if (($WingetInstallOption.ToLower() -eq "y") -or ($WingetInstallOption -eq "")) {
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

function ChocolateyInstall() {
    <#
    .SYNOPSIS
    Chocolatey Install
    
    .DESCRIPTION
    Install Chocolatey to be able to update and install applications from the terminal.
    It is doing it by downloading an install script from the official website and running it.
    It will install the script if the user chose to do so.

    .NOTES
    This function is not meant to run independently.
    This function only going to run if chocolatey is not installed.
    #>
    
    Write-Host "Chocolatey is not installed in this system." -ForegroundColor Red
    Write-Host "Chocolatey is a universal package manager for windows that enables installing applications through terminal." -ForegroundColor Cyan
    Write-Host "Do you want to install 'Chocolatey' package manager ? [Y/n] " -ForegroundColor Cyan -NoNewline
    $ChocolateyInstallOption = Read-Host

    if (($ChocolateyInstallOption.ToLower() -eq "y") -or ($ChocolateyInstallOption -eq "")) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
    }
    else {
        EmptyLine
        Write-Host "Skip installing Chocolatey package manager..." -ForegroundColor Yellow
        return
    }
}



<####################################################################>
<#                       Main Function                              #>
<####################################################################>
function Main() {
    <#
    .SYNOPSIS
    Main Function

    .DESCRIPTION
    Main function that will execute all functions created.
    
    .NOTES
    This function is not meant to run indepently.
    #>

    if (!$IsAdmin) {
        # if run script not as admin
        NotAdminMessage
        return
    }

    if ($Help) {
        # if user use -Help
        HelpMenu
        return
    }

    Title
    EmptyLine
    UpdatePowershellModule

    <# -------------------------------------------------------- #>
    <#                  Checking Prerequisite                   #>
    <# -------------------------------------------------------- #>
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
    if (!(Get-Command -Name winget) -and !(Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe")) {
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
    ScanSystemCorruptionFiles

    EmptyLine
    SystemCleanup

    EmptyLine
    EndingScript
}

############################### Run Function ###############################
Main
