<#
.SYNOPSIS
A comprehensive script to update Windows, applications, and perform system maintenance.

.DESCRIPTION
This script provides functionality to update PowerShell modules, Windows Updates,
Microsoft Store applications (via Winget), Winget packages, Chocolatey packages,
Pip packages, and NPM packages. It also includes tools to scan for and fix system
corruption, and to perform system cleanup by deleting temporary files and
emptying the Recycle Bin. The script supports both interactive and automated execution
through switch parameters.

.NOTES
Ensure PowerShell is run as an administrator for full functionality.

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
    Displays the help message for the script.
    #>
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
    Write-Host "  .PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1 -Upgrade -Cleanup"
    Write-Host "  .PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1 -Upgrade -YesToAll"
    Write-Host "  .PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1 -Scan"
    Write-Host "  Get-Help .PowerShell\Scripts\Windows-Scripting\SystemUpgrade.ps1 -Full"
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

    if (!(Get-Command -Name Update-Module -ErrorAction SilentlyContinue)) {
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
        Write-Host "Updating all PowerShell modules..." -ForegroundColor Yellow
        try {
            # We use -Force to ensure all modules are updated, even if they are already up-to-date.
            Update-Module -Force -AcceptLicense -ErrorAction Stop
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
            Write-Host "Installing 'PSWindowsUpdate' module..." -ForegroundColor Yellow
            try {
                Install-Module -Name PSWindowsUpdate -Force -AcceptLicense -Confirm:$false
            }
            catch {
                Write-Warning "Failed to install 'PSWindowsUpdate' module. $_"
                return
            }
        }
        else {
            Write-Host "Skipping Windows Update checks because 'PSWindowsUpdate' module is not installed." -ForegroundColor Yellow
            return
        }
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    try {
        if ($isInteractive) {
            # Interactive Mode
            do {
                Clear-Host
                Write-Host "Checking for Windows Updates..." -ForegroundColor Yellow
                $updates = Get-WindowsUpdate -ErrorAction Stop
                $updates | Format-Table

                if (!$updates) {
                    Write-Host "No Windows Updates found." -ForegroundColor Green
                    Start-Sleep -Seconds 3
                    break
                }

                EmptyLine
                Write-Host "Enter the KB Article ID to install. Separate multiple IDs with a space." -ForegroundColor Green
                Write-Host "Type 'all' to install all updates, or 'exit' to skip." -ForegroundColor Green
                $updateChoice = Read-Host -Prompt "KB Article ID"

                if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                    Write-Host "Exiting Windows Update." -ForegroundColor Yellow
                    break
                }

                if ($updateChoice.ToLower() -eq 'all') {
                    Write-Host "Installing all available Windows Updates..." -ForegroundColor Yellow
                    Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
                }
                else {
                    $ArrayID = $updateChoice.Split(" ")
                    Write-Host "Installing selected Windows Updates..." -ForegroundColor Yellow
                    Install-WindowsUpdate -KBArticleID $ArrayID -AcceptAll -IgnoreReboot -ErrorAction Stop
                }
                Write-Host "Update process finished. Re-checking for more updates..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } while ($true)
        }
        else {
            # Automatic mode
            Write-Host "Checking for and installing all Windows Updates automatically..." -ForegroundColor Yellow
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
            Write-Host "Automatic Windows Update complete." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "An error occurred during the Windows Update process."
        Write-Warning $_.Exception.Message
    }
}

function Invoke-MSStoreUpdate {
    <#
    .SYNOPSIS
    Updates Microsoft Store applications using winget.
    #>

    if (!(Get-Command -Name winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget command not found. Skipping Microsoft Store app updates."
        return
    }

    $shouldUpdate = $false
    if ($YesToAll.IsPresent -or $Upgrade.IsPresent) {
        $shouldUpdate = $true
    }
    else {
        $updateChoice = Read-Host -Prompt "Update all Microsoft Store applications? [Y/n]"
        if (($updateChoice.ToLower() -eq 'y') -or ($updateChoice -eq '')) {
            $shouldUpdate = $true
        }
    }

    if ($shouldUpdate) {
        Write-Host "Updating all Microsoft Store applications..." -ForegroundColor Yellow
        try {
            winget upgrade --all --source msstore --accept-package-agreements --accept-source-agreements
        }
        catch {
            Write-Warning "An error occurred while updating Microsoft Store applications."
            Write-Warning $_.Exception.Message
        }
    }
    else {
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
        $installPrompt = "The 'winget' command is not available. Install it now? [Y/n]"
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
                Write-Warning "Failed to install 'winget'. $_"
                return
            }
        }
        else {
            Write-Host "Skipping winget package updates because 'winget' is not installed." -ForegroundColor Yellow
            return
        }
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    try {
        if ($isInteractive) {
            # Interactive Mode
            do {
                Clear-Host
                Write-Host "Checking for upgradable winget applications..." -ForegroundColor Yellow
                winget upgrade --include-unknown

                EmptyLine
                Write-Host "Enter the App ID to upgrade. Separate multiple IDs with a space." -ForegroundColor Green
                Write-Host "Type 'all' to upgrade all applications, or 'exit' to skip." -ForegroundColor Green
                $updateChoice = Read-Host -Prompt "App ID"

                if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                    Write-Host "Exiting winget upgrade." -ForegroundColor Yellow
                    break
                }

                if ($updateChoice.ToLower() -eq 'all') {
                    Write-Host "Upgrading all applications..." -ForegroundColor Yellow
                    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
                }
                else {
                    $ArrayID = $updateChoice.Split(" ")
                    Write-Host "Upgrading selected applications..." -ForegroundColor Yellow
                    foreach ($appId in $ArrayID) {
                        winget upgrade --id $appId --include-unknown --accept-package-agreements --accept-source-agreements
                    }
                }
                Write-Host "Winget upgrade process finished. Re-checking for more updates..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } while ($true)
        }
        else {
            # Automatic mode
            Write-Host "Checking for and upgrading all winget packages automatically..." -ForegroundColor Yellow
            winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
            Write-Host "Automatic winget upgrade complete." -ForegroundColor Green
        }
    }
    catch {
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
        $installPrompt = "The 'choco' command is not available. Install it now? [Y/n]"
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
            # Interactive Mode
            do {
                Clear-Host
                Write-Host "Checking for outdated Chocolatey packages..." -ForegroundColor Yellow
                choco outdated

                EmptyLine
                Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                Write-Host "Type 'all' to upgrade all packages, or 'exit' to skip." -ForegroundColor Green
                $updateChoice = Read-Host -Prompt "Package Name"

                if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                    Write-Host "Exiting Chocolatey upgrade." -ForegroundColor Yellow
                    break
                }

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
                Write-Host "Chocolatey upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } while ($true)
        }
        else {
            # Automatic mode
            Write-Host "Checking for and upgrading all Chocolatey packages automatically..." -ForegroundColor Yellow
            choco upgrade all -y
            Write-Host "Automatic Chocolatey upgrade complete." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "An error occurred during the Chocolatey upgrade process."
        Write-Warning $_.Exception.Message
    }
}

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
        Write-Host "`n(1/4) Running 'chkdsk /scan' (check disk)..." -ForegroundColor Yellow
        try {
            chkdsk /scan
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "chkdsk /scan completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during chkdsk /scan. $_.Exception.Message"
        }

        Write-Host "`n(2/4) Running 'sfc /SCANNOW' (System File Checker) - 1st scan..." -ForegroundColor Yellow
        try {
            sfc /SCANNOW
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "sfc /SCANNOW completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during sfc /SCANNOW. $_.Exception.Message"
        }

        Write-Host "`n(3/4) Running DISM (Deployment Image Servicing and Management tool)..." -ForegroundColor Yellow
        try {
            DISM /Online /Cleanup-Image /Restorehealth
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "DISM command completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during DISM /Online /Cleanup-Image /Restorehealth. $_.Exception.Message"
        }

        Write-Host "`n(4/4) Running 'sfc /SCANNOW' (System File Checker) - 2nd scan..." -ForegroundColor Yellow
        try {
            sfc /SCANNOW
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "sfc /SCANNOW completed with errors. Review the output above."
            }
        }
        catch {
            Write-Warning "An error occurred during sfc /SCANNOW. $_.Exception.Message"
        }
        Write-Host "`nSystem corruption scan complete." -ForegroundColor Green
    } else {
        EmptyLine
        Write-Host "Skipping system corruption file scan." -ForegroundColor Yellow
    }
}

function Invoke-SystemCleanup {
    <#
    .SYNOPSIS
    Deletes temporary files, old Windows Update files, and empties the Recycle Bin.
    #>

    $shouldCleanup = $false
    if ($YesToAll.IsPresent -or $Cleanup.IsPresent) {
        $shouldCleanup = $true
    } else {
        $cleanupOption = Read-Host -Prompt "Delete unused files and folders (including temporary files and Recycle Bin)? [Y/n]"
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
            Write-Warning "An error occurred while emptying the Recycle Bin. $_.Exception.Message"
        }
        Write-Host "`nSystem cleanup complete." -ForegroundColor Green
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
        Write-Host "The 'pip' command is not available. Skipping pip package upgrades." -ForegroundColor Blue
        return
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    try {
        if ($isInteractive) {
            # Interactive Mode
            do {
                Clear-Host
                Write-Host "Checking for outdated pip packages..." -ForegroundColor Yellow
                $outdated = pip list --outdated
                if ($outdated) {
                    $outdated
                } else {
                    Write-Host "No outdated pip packages found." -ForegroundColor Green
                    Start-Sleep -Seconds 3
                    break
                }
                
                EmptyLine
                Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                Write-Host "Type 'all' to upgrade all packages, or 'exit' to skip." -ForegroundColor Green
                $updateChoice = Read-Host -Prompt "Package Name"

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
                Write-Host "Pip upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } while ($true)
        }
        else {
            # Automatic mode
            Write-Host "Checking for and upgrading all pip packages automatically..." -ForegroundColor Yellow
            pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object { pip install --upgrade $_.name }
            Write-Host "Automatic pip upgrade complete." -ForegroundColor Green
        }
    }
    catch {
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
        Write-Host "The 'npm' command is not available. Skipping npm package upgrades." -ForegroundColor Blue
        return
    }

    # Decide whether to run interactively or automatically
    $isInteractive = (-not ($YesToAll.IsPresent -or $Upgrade.IsPresent))

    try {
        if ($isInteractive) {
            # Interactive Mode
            do {
                Clear-Host
                Write-Host "Checking for outdated global npm packages..." -ForegroundColor Yellow
                npm -g outdated
                Write-Host "Checking for outdated local npm packages..." -ForegroundColor Yellow
                npm outdated
                
                EmptyLine
                Write-Host "Enter the package name to upgrade. Separate multiple names with a space." -ForegroundColor Green
                Write-Host "Type 'all-global' to upgrade all global packages, 'all-local' for local, or 'all' for both." -ForegroundColor Green
                Write-Host "Type 'exit' to skip." -ForegroundColor Green
                $updateChoice = Read-Host -Prompt "Package Name"

                if ($updateChoice.ToLower() -eq 'exit' -or [string]::IsNullOrEmpty($updateChoice)) {
                    Write-Host "Exiting npm upgrade." -ForegroundColor Yellow
                    break
                }

                if ($updateChoice.ToLower() -eq 'all' -or $updateChoice.ToLower() -eq 'all-global') {
                    Write-Host "Upgrading all global packages..." -ForegroundColor Yellow
                    npm -g outdated --json | ConvertFrom-Json | ForEach-Object { npm -g install "$($_.name)@latest" }
                }

                if ($updateChoice.ToLower() -eq 'all' -or $updateChoice.ToLower() -eq 'all-local') {
                    Write-Host "Upgrading all local packages..." -ForegroundColor Yellow
                     npm outdated --json | ConvertFrom-Json | ForEach-Object { npm install "$($_.name)@latest" }
                }
                
                if ($updateChoice.ToLower() -ne 'all' -and $updateChoice.ToLower() -ne 'all-local' -and $updateChoice.ToLower() -ne 'all-global') {
                    $packageNames = $updateChoice.Split(" ")
                    Write-Host "Upgrading selected packages..." -ForegroundColor Yellow
                    foreach ($pkg in $packageNames) {
                        # A bit tricky to know if it's global or local, so we can try local first, then global.
                        Write-Host "Attempting to upgrade '$pkg' locally..."
                        npm install "$pkg@latest"
                        Write-Host "Attempting to upgrade '$pkg' globally..."
                        npm -g install "$pkg@latest"
                    }
                }
                Write-Host "NPM upgrade process finished. Re-checking for more outdated packages..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            } while ($true)
        }
        else {
            # Automatic mode
            Write-Host "Checking for and upgrading all npm packages automatically..." -ForegroundColor Yellow
            Write-Host "Upgrading global packages..."
            npm -g outdated --json | ConvertFrom-Json | ForEach-Object { npm -g install "$($_.name)@latest" }
            Write-Host "Upgrading local packages..."
            npm outdated --json | ConvertFrom-Json | ForEach-Object { npm install "$($_.name)@latest" }
            Write-Host "Automatic npm upgrade complete." -ForegroundColor Green
        }
    }
    catch {
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
        NotAdminMessage
        return
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

    if ($Upgrade.IsPresent -or $InteractiveMode) {
        UpdatePowershellModule

        <# -------------------------------------------------------- #>
        <#                  Checking Prerequisite                   #>
        <# -------------------------------------------------------- #>
        EmptyLine
        # install PSWindowsUpdate module if isn't already
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

    if ($Scan.IsPresent -or $InteractiveMode) {
        EmptyLine
        Invoke-SystemScan
    }

    if ($Cleanup.IsPresent -or $InteractiveMode) {
        EmptyLine
        Invoke-SystemCleanup
    }

    EmptyLine
    EndingScript
}

############################### Run Function ###############################
Main
