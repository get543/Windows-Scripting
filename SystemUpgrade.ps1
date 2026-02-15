<#
.SYNOPSIS
A comprehensive script to update Windows, applications, and perform system maintenance.

.DESCRIPTION
This script provides functionality to update PowerShell modules, Windows Updates,
Microsoft Store applications, Winget packages, Chocolatey packages,
Pip packages, and NPM packages. It also includes tools to scan for and fix system
corruption, and to perform system cleanup by deleting temporary files and
emptying the Recycle Bin. The script supports both interactive and automated execution
through switch parameters.

.NOTES
PowerShell is run as an administrator is required for most operations in this script.

.LINK
https://github.com/get543/Windows-Scripting/blob/main/SystemUpgrade.ps1
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Upgrade all possible packages and modules.")]
    [switch]$Upgrade,

    [Parameter(HelpMessage = "Cleanup temporary files and folders.")]
    [switch]$Cleanup,

    [Parameter(HelpMessage = "Scan for system file corruption.")]
    [switch]$Scan,

    [Parameter(HelpMessage = "Automatically answer 'yes' to all interactive prompts.")]
    [switch]$YesToAll,

    [Parameter(HelpMessage = "Display this help message.")]
    [switch]$Help
)

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)



function EmptyLine() {
    Write-Host
}



<# -------------------------------------------------------- #>
<#                Admin Relaunch & Checking                 #>
<# -------------------------------------------------------- #>
function NotAdminRelaunch() { #!BROKEN
    <#
    .SYNOPSIS
    Admin or not ?
    
    .DESCRIPTION
    Check if the script executed with admin privilages or not.
    If not, then script you immedietly exit and show error message.

    .NOTES
    Run in Main function when the script is executed.
    #>

    EmptyLine
    Write-Host "Please run this script as an admin access." -ForegroundColor Red
    Write-Host "Because almost all commands require admin access." -ForegroundColor Red

    EmptyLine
    Write-Host "Attempting to restart the script with admin access..." -ForegroundColor Yellow

    $windowsTerminalInstalled = Get-Command -Name wt.exe -ErrorAction SilentlyContinue
    $pwshInstalled = Get-Command -Name pwsh.exe -ErrorAction SilentlyContinue
    $powershellInstalled = Get-Command -Name powershell.exe -ErrorAction SilentlyContinue

    $powershellVersion = powershell.exe -Command "$PSVersionTable.PSVersion.ToString()"

    EmptyLine
    if ($windowsTerminalInstalled) {
        Write-Host "Launching with Windows Terminal (wt.exe)..." -ForegroundColor Yellow
        if ($pwshInstalled) {
            Write-Host "Using $(pwsh.exe -v) as the shell for Windows Terminal." -ForegroundColor Yellow
            Start-Process `
                -FilePath "wt.exe" `
                -ArgumentList "pwsh -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.UnboundArguments)" `
                -Verb RunAs
        } elseif ($powershellInstalled) {
            Write-Host "Using PowerShell $powershellVersion as the shell for Windows Terminal." -ForegroundColor Yellow
            Start-Process `
                -FilePath "wt.exe" `
                -ArgumentList "powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.UnboundArguments)" `
                -Verb RunAs
        } else {
            Write-Error "Cannot find any PowerShell executable. Please restart this script manually with admin access."
        }
    } elseif ($pwshInstalled -or $powershellInstalled) {
        if ($pwshInstalled) {
            Start-Process `
                -FilePath "pwsh.exe" `
                -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.UnboundArguments)" `
                -Verb RunAs
            Write-Host "Launching with $(pwsh.exe -v) (pwsh.exe)..." -ForegroundColor Yellow
        } elseif ($powershellInstalled) {
            Write-Host "Launching with PowerShell $powershellVersion (powershell.exe)..." -ForegroundColor Yellow
            Start-Process `
                -FilePath "powershell.exe" `
                -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.UnboundArguments)" `
                -Verb RunAs
        } else {
            Write-Error "Cannot find any PowerShell executable. Please restart this script manually with admin access."
        }
    }
}


<# -------------------------------------------------------- #>
<#                      Menu or Title                       #>
<# -------------------------------------------------------- #>
function HelpMenu() {
    <#
    .SYNOPSIS
    Displays the help message for the script.
    #>

    EmptyLine
    Write-Host "This script helps with system upgrade, cleanup, and maintenance tasks." -ForegroundColor Cyan
    Write-Host "You can combine switches to perform multiple actions."
    EmptyLine
    Write-Host "PARAMETERS:" -ForegroundColor Green
    Write-Host "  -Upgrade      Upgrade all possible packages and modules."
    Write-Host "  -Cleanup      Cleanup temporary files and folders."
    Write-Host "  -Scan         Scan for system file corruption."
    Write-Host "  -YesToAll     Automatically answer 'yes' to all interactive prompts."
    Write-Host "  -Help         Display this help message."
    EmptyLine
    Write-Host "EXAMPLES:" -ForegroundColor Green
    Write-Host "  .\SystemUpgrade.ps1 -Upgrade -Cleanup"
    Write-Host "  .\SystemUpgrade.ps1 -Upgrade -YesToAll"
    Write-Host "  .\SystemUpgrade.ps1 -Scan"
    Write-Host "  Get-Help .\SystemUpgrade.ps1 -Full"
    EmptyLine
}

function Title() {
    <#
    .SYNOPSIS
    Shows the script title at the start of the script
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
    #>

    Write-Host "
    __| |_________________________________| |__ 
   (__| |_________________________________| |__)
      | |            End Script           | |   
    __| |_________________________________| |__ 
   (__|_|_________________________________|_|__) " -ForegroundColor Magenta
}


<# -------------------------------------------------------- #>
<#                    Update Function                       #>
<# -------------------------------------------------------- #>
function UpdatePowershellModule() {
    <#
    .SYNOPSIS
    Update PowerShell Module
    
    .DESCRIPTION
    This function updates all installed PowerShell modules if it needs to.
    #>

    if (!(Get-Command -Name Update-Module -ErrorAction SilentlyContinue)) {
        EmptyLine
        Write-Host "The 'Update-Module' command is not available. Skipping PowerShell module updates." -ForegroundColor Blue
        return
    }

    $shouldUpdate = $false
    if ($YesToAll.IsPresent -or $Upgrade.IsPresent) {
        $shouldUpdate = $true
    } else {
        $UpdateModuleOption = Read-Host -Prompt "Update all PowerShell modules? [Y/n]"
        if (($UpdateModuleOption.ToLower() -eq "y") -or ($UpdateModuleOption -eq "")) {
            $shouldUpdate = $true
        }
    }

    if ($shouldUpdate) {
        EmptyLine
        Write-Host "Updating all PowerShell modules..." -ForegroundColor Yellow
        try {
            Update-Module -AcceptLicense -ErrorAction Stop
        }
        catch {
            Write-Warning "An error occurred while updating PowerShell modules."
            Write-Warning $_.Exception.Message
        }
    } else {
        EmptyLine
        Write-Host "Skipping PowerShell module updates." -ForegroundColor Yellow
    }
}

function Invoke-WindowsUpdate {
    <#
    .SYNOPSIS
    Checks for, installs, and manages Windows Updates using the PSWindowsUpdate module.
    #>

    # Check for PSWindowsUpdate module and offer to install if missing
    if (!(Get-Module -Name "PSWindowsUpdate" -ListAvailable -ErrorAction SilentlyContinue)) {
        $installPrompt = "The 'PSWindowsUpdate' module is required to manage Windows Updates. Install it now? [Y/n]"
        $shouldInstall = $false
        if ($YesToAll.IsPresent) {
            $shouldInstall = $true
        }
        else {
            $installChoice = Read-Host -Prompt $installPrompt
            if (($installChoice.ToLower() -eq 'y') -or ($installChoice -eq '')) {
                $shouldInstall = $true
            }
        }

        if ($shouldInstall) {
            EmptyLine
            Write-Host "Installing 'PSWindowsUpdate' module..." -ForegroundColor Yellow
            try {
                Install-Module -Name PSWindowsUpdate -Force -AcceptLicense -Confirm:$false
            }
            catch {
                Write-Warning "Failed to install 'PSWindowsUpdate' module."
                Write-Warning $_.Exception.Message
                return
            }
        }
        else {
            EmptyLine
            Write-Host "Skipping Windows Update checks because 'PSWindowsUpdate' module is not installed." -ForegroundColor Yellow
            return
        }
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    try {
        if ($isInteractive) {
            #! Interactive Mode

            # Ask user if they want to check for Windows Updates before proceeding with installation
            $windowsUpdateOption = Read-Host -Prompt "Check for Windows Updates ? [Y/n] "
            if (($windowsUpdateOption.ToLower() -eq "y") -or ($windowsUpdateOption -eq "")) {
                do {
                    Clear-Host
                    Write-Host "Checking for Windows Updates..." -ForegroundColor Yellow
                    $updates = Get-WindowsUpdate -ErrorAction Stop
                    $updates | Format-Table
    
                    if (!$updates) {
                        EmptyLine
                        Write-Host "No Windows Updates found." -ForegroundColor Green
                        Start-Sleep -Seconds 3
                        break
                    }
    
                    EmptyLine
                    Write-Host "Enter the KB Article ID to install. Separate multiple IDs with a space." -ForegroundColor Green
                    Write-Host "Type 'all' to install all updates, or 'exit' to skip." -ForegroundColor Green
                    $updateChoice = Read-Host -Prompt "KB Article ID"
    
                    if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                        EmptyLine
                        Write-Host "Exiting Windows Update." -ForegroundColor Yellow
                        break
                    }
    
                    if ($updateChoice.ToLower() -eq 'all') {
                        EmptyLine
                        Write-Host "Installing all available Windows Updates..." -ForegroundColor Yellow
                        Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
                    }
                    else {
                        $ArrayID = $updateChoice.Split(" ")
                        EmptyLine
                        Write-Host "Installing selected Windows Updates..." -ForegroundColor Yellow
                        Install-WindowsUpdate -KBArticleID $ArrayID -AcceptAll -IgnoreReboot -ErrorAction Stop
                    }
                    EmptyLine
                    Write-Host "Update process finished. Re-checking for more updates..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                } while ($true)
            } else {
                EmptyLine
                Write-Host "Skipping Windows Update checks." -ForegroundColor Yellow
            }
        }
        else {
            #! Automatic mode

            EmptyLine
            Write-Host "Checking for and installing all Windows Updates automatically..." -ForegroundColor Yellow
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop

            EmptyLine
            Write-Host "Automatic Windows Update complete." -ForegroundColor Green
        }
    }
    catch {
        EmptyLine
        Write-Warning "An error occurred during the Windows Update process."
        Write-Warning $_.Exception.Message
    }
}

function Invoke-MSStoreUpdate {
    <#
    .SYNOPSIS
    Updates Microsoft Store applications using winget.
    #>

    if (!(Get-Command -Name Update-InboxApp)) { 
        $installPrompt = "The 'Update-InboxApp' command is not available. Install it now? [Y/n] "
        $shouldInstall = $false
        if ($YesToAll.IsPresent) {
            $shouldInstall = $true
        }
        else {
            $installChoice = Read-Host -Prompt $installPrompt
            if (($installChoice.ToLower() -eq 'y') -or ($installChoice -eq '')) {
                $shouldInstall = $true
            }
        }

        if ($shouldInstall) {
            EmptyLine
            Write-Host "Installing 'Update-InboxApp' script..." -ForegroundColor Yellow
            try {
                Install-Script Update-InboxApp
            }
            catch {
                Write-Warning "Failed to install 'Update-InboxApp' script."
                Write-Warning $_.Exception.Message
                return
            }
        }
        else {
            EmptyLine
            Write-Host "Skipping Windows Update checks because 'Update-InboxApp' script is not installed." -ForegroundColor Yellow
            return
        }

        EmptyLine
        Write-Host "The 'Update-InboxApp' command is not available. Skipping Microsoft Store app updates." -ForegroundColor Blue
        return
    }

    $shouldUpdate = $false
    if ($YesToAll.IsPresent -or $Upgrade.IsPresent) {
        $shouldUpdate = $true
    }
    else {
        $updateChoice = Read-Host -Prompt "Update all Microsoft Store applications? [Y/n] "
        if (($updateChoice.ToLower() -eq 'y') -or ($updateChoice -eq '')) {
            $shouldUpdate = $true
        }
    }

    if ($shouldUpdate) {
        EmptyLine
        Write-Host "Updating all Microsoft Store applications..." -ForegroundColor Yellow
        try {
            powershell.exe -Command "Get-AppxPackage | Update-InboxApp"
        }
        catch {
            Write-Warning "An error occurred while updating Microsoft Store applications."
            Write-Warning $_.Exception.Message
        }
    }
    else {
        EmptyLine
        Write-Host "Skipping Microsoft Store application updates." -ForegroundColor Yellow
    }
}

function Invoke-WingetUpdate {
    <#
    .SYNOPSIS
    Installs or updates winget, and then updates all winget packages.
    #>

    # Check for winget and offer to install if missing
    if (!(Get-Command -Name winget -ErrorAction SilentlyContinue)) {
        $installPrompt = "The 'winget' command is not available. Install it now ? [Y/n] "
        $shouldInstall = $false
        if ($YesToAll.IsPresent) {
            $shouldInstall = $true
        }
        else {
            $installChoice = Read-Host -Prompt $installPrompt
            if (($installChoice.ToLower() -eq 'y') -or ($installChoice -eq '')) {
                $shouldInstall = $true
            }
        }

        if ($shouldInstall) {
            EmptyLine
            Write-Host "Installing 'winget'..." -ForegroundColor Yellow
            try {
                # Get the latest release from the official GitHub repository
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $asset = $release.assets | Where-Object { $_.name -like '*.msixbundle' } | Select-Object -First 1
                $downloadUrl = $asset.browser_download_url
                $downloadPath = Join-Path $env:TEMP $asset.name

                Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
                Add-AppxPackage -Path $downloadPath
            }
            catch {
                EmptyLine
                Write-Warning "Failed to install 'winget'. "
                Write-Warning $_.Exception.Message
                return
            }
        }
        else {
            EmptyLine
            Write-Host "Skipping winget package updates because 'winget' is not installed." -ForegroundColor Yellow
            return
        }
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))
    
    
    try {
        if ($isInteractive) {
            #! Interactive Mode

            # Ask user if they want to check for winget updates before proceeding with package upgrades
            $updateWingetOption = Read-Host -Prompt "Check for Winget Updates ? [Y/n] "
            if (($updateWingetOption.ToLower() -eq "y") -or ($updateWingetOption -eq "")) {
                do {
                    Clear-Host
                    Write-Host "Checking for upgradable winget applications..." -ForegroundColor Yellow
                    winget upgrade --include-unknown
    
                    EmptyLine
                    Write-Host "Enter the App ID to upgrade. Separate multiple IDs with a space." -ForegroundColor Green
                    Write-Host "Type 'all' to upgrade all applications, or 'exit' to skip." -ForegroundColor Green
                    $updateChoice = Read-Host -Prompt "App ID"
    
                    if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                        EmptyLine
                        Write-Host "Exiting winget upgrade." -ForegroundColor Yellow
                        break
                    }
    
                    if ($updateChoice.ToLower() -eq 'all') {
                        EmptyLine
                        Write-Host "Upgrading all applications..." -ForegroundColor Yellow
                        winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
                    }
                    else {
                        $ArrayID = $updateChoice.Split(" ")
                        EmptyLine
                        Write-Host "Upgrading selected applications..." -ForegroundColor Yellow
                        foreach ($appId in $ArrayID) {
                            winget upgrade --id $appId --include-unknown --accept-package-agreements --accept-source-agreements
                        }
                    }
                    EmptyLine
                    Write-Host "Winget upgrade process finished. Re-checking for more updates..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                } while ($true)
            } else {
                EmptyLine
                Write-Host "Skipping winget package updates." -ForegroundColor Yellow
            }
        }
        else {
            #! Automatic mode

            EmptyLine
            Write-Host "Checking for and upgrading all winget packages automatically..." -ForegroundColor Yellow
            winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

            EmptyLine
            Write-Host "Automatic winget upgrade complete." -ForegroundColor Green
        }
    }
    catch {
        EmptyLine
        Write-Warning "An error occurred during the winget upgrade process."
        Write-Warning $_.Exception.Message
    }
}

function Invoke-ChocolateyUpdate {
    <#
    .SYNOPSIS
    Installs or updates Chocolatey, and then updates all Chocolatey packages.
    #>

    # Check for Chocolatey and offer to install if missing
    if (!(Get-Command -Name choco -ErrorAction SilentlyContinue)) {
        $installPrompt = "The 'choco' command is not available. Install it now ? [Y/n] "
        $shouldInstall = $false
        if ($YesToAll.IsPresent) {
            $shouldInstall = $true
        }
        else {
            $installChoice = Read-Host -Prompt $installPrompt
            if (($installChoice.ToLower() -eq 'y') -or ($installChoice -eq '')) {
                $shouldInstall = $true
            }
        }

        EmptyLine
        if ($shouldInstall) {
            Write-Host "Installing 'Chocolatey'..." -ForegroundColor Yellow
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                $installScript = Join-Path $env:TEMP "install-choco.ps1"
                Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -OutFile $installScript
                & $installScript
            }
            catch {
                Write-Warning "Failed to install 'Chocolatey'. $_"
                return
            }
        }
        else {
            Write-Host "Skipping Chocolatey package updates because 'choco' is not installed." -ForegroundColor Yellow
            return
        }
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))
    
    try {
        if ($isInteractive) {
            #! Interactive Mode

            # Ask user if they want to check for Chocolatey updates before proceeding with package upgrades
            $updateChocoOption = Read-Host -Prompt "Check for Chocolatey Updates ? [Y/n] "
            if (($updateChocoOption.ToLower() -eq "y") -or ($updateChocoOption -eq "")) {
                do {
                    Clear-Host
                    Write-Host "Checking for outdated Chocolatey packages..." -ForegroundColor Yellow
                    choco outdated
    
                    EmptyLine
                    Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                    Write-Host "Type 'all' to upgrade all packages, or 'exit' to skip." -ForegroundColor Green
                    $updateChoice = Read-Host -Prompt "Package Name"
    
                    if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                        EmptyLine
                        Write-Host "Exiting Chocolatey upgrade." -ForegroundColor Yellow
                        break
                    }
    
                    EmptyLine
                    if ($updateChoice.ToLower() -eq 'all') {
                        Write-Host "Upgrading all packages..." -ForegroundColor Yellow
                        choco upgrade all -y
                    }
                    else {
                        $ArrayID = $updateChoice.Split(" ")
                        Write-Host "Upgrading selected packages..." -ForegroundColor Yellow
                        foreach ($pkg in $ArrayID) {
                            choco upgrade $pkg -y
                        }
                    }
    
                    EmptyLine
                    Write-Host "Chocolatey upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                } while ($true)
            } else {
                EmptyLine
                Write-Host "Skipping Chocolatey package updates." -ForegroundColor Yellow
            }
        }
        else {
            #! Automatic mode

            EmptyLine
            Write-Host "Checking for and upgrading all Chocolatey packages automatically..." -ForegroundColor Yellow
            choco upgrade all -y

            EmptyLine
            Write-Host "Automatic Chocolatey upgrade complete." -ForegroundColor Green
        }
    }
    catch {
        EmptyLine
        Write-Warning "An error occurred during the Chocolatey upgrade process."
        Write-Warning $_.Exception.Message
    }
}



<# -------------------------------------------------------- #>
<#                 System Maintenance Tools                 #>
<# -------------------------------------------------------- #>
function Invoke-SystemScan {
    <#
    .SYNOPSIS
    Scans for and attempts to fix system corruption files.
    #>

    $shouldScan = $false
    if ($YesToAll.IsPresent -or $Scan.IsPresent) {
        $shouldScan = $true
    } else {
        $scanOption = Read-Host -Prompt "Check for system corruption files? [Y/n]"
        if (($scanOption.ToLower() -eq "y") -or ($scanOption -eq "")) {
            $shouldScan = true
        }
    }

    if ($shouldScan) {
        EmptyLine
        Write-Host "(1/4) Running 'chkdsk /scan' (check disk)..." -ForegroundColor Yellow
        try {
            chkdsk /scan
            if ($LASTEXITCODE -ne 0) {
                EmptyLine
                Write-Warning "chkdsk /scan completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during chkdsk /scan. $_.Exception.Message"
        }

        EmptyLine
        Write-Host "(2/4) Running 'sfc /SCANNOW' (System File Checker) - 1st scan..." -ForegroundColor Yellow
        try {
            sfc /SCANNOW
            if ($LASTEXITCODE -ne 0) {
                EmptyLine
                Write-Warning "sfc /SCANNOW completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during sfc /SCANNOW. $_.Exception.Message"
        }

        EmptyLine
        Write-Host "(3/4) Running DISM (Deployment Image Servicing and Management tool)..." -ForegroundColor Yellow
        try {
            DISM /Online /Cleanup-Image /Restorehealth
            if ($LASTEXITCODE -ne 0) {
                EmptyLine
                Write-Warning "DISM command completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during DISM /Online /Cleanup-Image /Restorehealth. $_.Exception.Message"
        }

        EmptyLine
        Write-Host "(4/4) Running 'sfc /SCANNOW' (System File Checker) - 2nd scan..." -ForegroundColor Yellow
        try {
            sfc /SCANNOW
            if ($LASTEXITCODE -ne 0) {
                EmptyLine
                Write-Warning "sfc /SCANNOW completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during sfc /SCANNOW. $_.Exception.Message"
        }

        EmptyLine
        Write-Host "System corruption scan complete." -ForegroundColor Green
    } else {
        EmptyLine
        Write-Host "Skipping system corruption file scan." -ForegroundColor Yellow
    }
}

function Invoke-SystemCleanup {
    <#
    .SYNOPSIS
    Deletes temporary files, old Windows Update files, and empties the Recycle Bin.

    .NOTES
    This function will attempt to run Disk Cleanup, delete temporary files from both
    Cleaning $env:windir\Temp and $env:TEMP, and empty the Recycle Bin.
    #>

    $shouldCleanup = $false
    if ($YesToAll.IsPresent -or $Cleanup.IsPresent) {
        $shouldCleanup = $true
    } else {
        $cleanupOption = Read-Host -Prompt "Delete unused files and folders ? [Y/n]"
        if (($cleanupOption.ToLower() -eq "y") -or ($cleanupOption -eq "")) {
            $shouldCleanup = $true
        }
    }

    if ($shouldCleanup) {
        # Run Disk Cleanup
        EmptyLine
        Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
        try {
            if ((Get-Command -Name cleanmgr -ErrorAction SilentlyContinue) -and (Test-Path "$env:windir\system32\cleanmgr.exe")) {
                cleanmgr.exe /d $env:HOMEDRIVE /VERYLOWDISK
            }
            else {
                Write-Warning "'cleanmgr' command not found. Skipping Disk Cleanup."
            }
        }
        catch {
            Write-Warning "An error occurred during Disk Cleanup. $_.Exception.Message"
        }

        # Delete Temporary Files
        EmptyLine
        Write-Host "Deleting Temporary Files..." -ForegroundColor Yellow
        try {
            if ((Test-Path "$env:windir\Temp") -and (Test-Path "$env:TEMP")) {
                Get-ChildItem -Path "$env:windir\Temp" -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path "$env:windir\Temp" -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Get-ChildItem -Path $env:TEMP -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $env:TEMP -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
            else {
                Write-Warning "Temporary directories not found. Skipping temporary file deletion."
            }
        }
        catch {
            Write-Warning "An error occurred during temporary file deletion. $_.Exception.Message"
        }

        # Empty Recycle Bin
        EmptyLine
        Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
        try {
            if (Get-Command -Name Clear-RecycleBin -ErrorAction SilentlyContinue) {
                Clear-RecycleBin -Force -ErrorAction Stop
            }
            else {
                Write-Warning "'Clear-RecycleBin' command not found. Skipping Recycle Bin emptying."
            }
        }
        catch {
            EmptyLine
            Write-Warning "An error occurred while emptying the Recycle Bin. $_.Exception.Message"
        }

        EmptyLine
        Write-Host "System cleanup complete." -ForegroundColor Green
    } else {
        EmptyLine
        Write-Host "Skipping system cleanup." -ForegroundColor Yellow
    }
}



<# -------------------------------------------------------- #>
<#                      DevTools                            #>
<# -------------------------------------------------------- #>
function Invoke-PipUpgrade {
    <#
    .SYNOPSIS
    Upgrades outdated pip packages.
    #>

    if (!(Get-Command -Name pip -ErrorAction SilentlyContinue)) {
        EmptyLine
        Write-Host "The 'pip' command is not available. Skipping pip package upgrades." -ForegroundColor Blue
        return
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    EmptyLine
    try {
        if ($isInteractive) {
            #! Interactive Mode

            # Ask user if they want to check for Chocolatey updates before proceeding with package upgrades
            $updatePipOption = Read-Host -Prompt "Check for pip Updates ? [Y/n] "
            if (($updatePipOption.ToLower() -eq "y") -or ($updatePipOption -eq "")) {
                do {
                    Clear-Host
                    Write-Host "Checking for outdated pip packages..." -ForegroundColor Yellow
                    $outdated = pip list --outdated
                    if ($outdated) {
                        $outdated
                    } else {
                        EmptyLine
                        Write-Host "No outdated pip packages found." -ForegroundColor Green
                        Start-Sleep -Seconds 3
                        break
                    }
                    
                    EmptyLine
                    Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                    Write-Host "Type 'all' to upgrade all packages, or 'exit' to skip." -ForegroundColor Green
                    $updateChoice = Read-Host -Prompt "Package Name"
    
                    EmptyLine
                    if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                        Write-Host "Exiting pip upgrade." -ForegroundColor Yellow
                        break
                    }
    
                    if ($updateChoice.ToLower() -eq 'all') {
                        Write-Host "Upgrading all packages..." -ForegroundColor Yellow
                        pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object { pip install --upgrade $_.name }
                    }
                    else {
                        $packageNames = $updateChoice.Split(" ")
                        Write-Host "Upgrading selected packages..." -ForegroundColor Yellow
                        foreach ($pkg in $packageNames) {
                            pip install --upgrade $pkg
                        }
                    }
    
                    EmptyLine
                    Write-Host "Pip upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                } while ($true)
            } else {
                EmptyLine
                Write-Host "Skipping pip package updates." -ForegroundColor Yellow
                return
            }
        }
        else {
            #! Automatic mode

            EmptyLine
            Write-Host "Checking for and upgrading all pip packages automatically..." -ForegroundColor Yellow
            pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object { pip install --upgrade $_.name }

            EmptyLine
            Write-Host "Automatic pip upgrade complete." -ForegroundColor Green
        }
    }
    catch {
        EmptyLine
        Write-Warning "An error occurred during the pip upgrade process."
        Write-Warning $_.Exception.Message
    }
}

function Invoke-NpmUpgrade {
    <#
    .SYNOPSIS
    Upgrades outdated npm packages.
    #>

    if (!(Get-Command -Name npm -ErrorAction SilentlyContinue)) {
        EmptyLine
        Write-Host "The 'npm' command is not available. Skipping npm package upgrades." -ForegroundColor Blue
        return
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    EmptyLine
    try {
        if ($isInteractive) {
            #! Interactive Mode

            # Ask user if they want to check for Chocolatey updates before proceeding with package upgrades
            $updateNpmOption = Read-Host -Prompt "Check for npm Updates ? [Y/n] "
            if (($updateNpmOption.ToLower() -eq "y") -or ($updateNpmOption -eq "")) {
                do {
                    Clear-Host
                    Write-Host "Checking for outdated global npm packages..." -ForegroundColor Yellow
                    npm -g outdated
    
                    EmptyLine
                    Write-Host "Checking for outdated local npm packages..." -ForegroundColor Yellow
                    npm outdated
                    
                    EmptyLine
                    Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                    Write-Host "Type 'all-global' to upgrade all global packages, 'all-local' for local, or 'all' for both." -ForegroundColor Green
                    Write-Host "Type 'exit' to skip." -ForegroundColor Green
                    $updateChoice = Read-Host -Prompt "Package Name"
    
                    if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                        EmptyLine
                        Write-Host "Exiting npm upgrade." -ForegroundColor Yellow
                        break
                    }
    
                    if ($updateChoice.ToLower() -eq 'all' -or $updateChoice.ToLower() -eq 'all-global') {
                        EmptyLine
                        Write-Host "Upgrading all global packages..." -ForegroundColor Yellow
                        npm -g outdated --json | ConvertFrom-Json | ForEach-Object { npm -g install "$($_.name)@latest" }
                    }
    
                    if ($updateChoice.ToLower() -eq 'all' -or $updateChoice.ToLower() -eq 'all-local') {
                        EmptyLine
                        Write-Host "Upgrading all local packages..." -ForegroundColor Yellow
                        npm outdated --json | ConvertFrom-Json | ForEach-Object { npm install "$($_.name)@latest" }
                    }
                    
                    if (($updateChoice.ToLower() -ne 'all') -and ($updateChoice.ToLower() -ne 'all-local') -and ($updateChoice.ToLower() -ne 'all-global')) {
                        $packageNames = $updateChoice.Split(" ")
                        EmptyLine
                        Write-Host "Upgrading selected packages..." -ForegroundColor Yellow
                        foreach ($pkg in $packageNames) {
                            # A bit tricky to know if it's global or local, so we can try local first, then global.
                            EmptyLine
                            Write-Host "Attempting to upgrade '$pkg' locally..."
                            npm install "$pkg@latest"
    
                            EmptyLine
                            Write-Host "Attempting to upgrade '$pkg' globally..."
                            npm -g install "$pkg@latest"
                        }
                    }
    
                    EmptyLine
                    Write-Host "NPM upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                } while ($true)
            } else {
                EmptyLine
                Write-Host "Skipping npm package updates." -ForegroundColor Yellow
                return
            }
        }
        else {
            #! Automatic mode

            EmptyLine
            Write-Host "Checking for and upgrading all npm packages automatically..." -ForegroundColor Yellow
            Write-Host "Upgrading global packages..."
            npm -g outdated --json | ConvertFrom-Json | ForEach-Object { npm -g install "$($_.name)@latest" }

            EmptyLine
            Write-Host "Upgrading local packages..."
            npm outdated --json | ConvertFrom-Json | ForEach-Object { npm install "$($_.name)@latest" }

            EmptyLine
            Write-Host "Automatic npm upgrade complete." -ForegroundColor Green
        }
    }
    catch {
        EmptyLine
        Write-Warning "An error occurred during the npm upgrade process."
        Write-Warning $_.Exception.Message
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
        NotAdminRelaunch
        Exit
    }

    if ($Help) {
        # if user use -Help
        HelpMenu
        return
    }

    # Determine run mode. If no specific action switch is used, run interactively.
    $InteractiveMode = (-not ($Upgrade -or $Cleanup -or $Scan))

    Title
    EmptyLine

    # If user specified -Upgrade or is running in interactive mode, perform system upgrade tasks
    if ($Upgrade.IsPresent -or $InteractiveMode) {
        EmptyLine
        UpdatePowershellModule

        EmptyLine
        Invoke-WindowsUpdate
    
        EmptyLine
        Invoke-MSStoreUpdate

        EmptyLine
        Invoke-WingetUpdate

        EmptyLine
        Invoke-ChocolateyUpdate

        # if python is installed, run update pip
        if ((Get-Command -Name python -ErrorAction SilentlyContinue) -and (Test-Path "$env:LOCALAPPDATA\Programs\Python")) {
            Invoke-PipUpgrade
        }

        # if node is installed, run update npm
        if ((Get-Command -Name npm -ErrorAction SilentlyContinue) -and (Test-Path "$env:ProgramFiles\nodejs")) {
            Invoke-NpmUpgrade
        }
    }

    # If user specified -Scan or is running in interactive mode, perform system scan tasks
    if ($Scan.IsPresent -or $InteractiveMode) {
        EmptyLine
        Invoke-SystemScan
    }

    # If user specified -Cleanup or is running in interactive mode, perform system cleanup tasks
    if ($Cleanup.IsPresent -or $InteractiveMode) {
        EmptyLine
        Invoke-SystemCleanup
    }

    EmptyLine
    EndingScript
}

############################### Run Function ###############################
Main
