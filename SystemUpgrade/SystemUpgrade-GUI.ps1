$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    return Write-Host "Please run it again with admin privilages." -ForegroundColor Red
}

Add-Type -AssemblyName PresentationFramework

$xamlFile = Join-Path -Path $PSScriptRoot -ChildPath "MainWindow.xaml"
if (-not (Test-Path $xamlFile)) {
    Write-Host "XAML file not found: $xamlFile" -ForegroundColor Red
    return
}

# Load xaml file
$inputXAML = Get-Content -Path $xamlFile -Raw
$inputXAML = $inputXAML -replace 'mc:Ignorable="d"', '' -replace "x:N", "N" -replace 'x:Class="[^"]+"', ''
[XML]$XAML = $inputXAML

$Reader = New-Object System.Xml.XmlNodeReader $XAML

try {
    $PSForm = [Windows.Markup.XamlReader]::Load($Reader)
}
catch {
    Write-Host $_.Exception
    throw
}

# Get XML Name= as the variable by adding var_ in front of the name
$XAML.SelectNodes("//*[@Name]") | ForEach-Object {
    try {
        Set-Variable -Name "var_$($_.Name)" -Value $PSForm.FindName($_.Name) -ErrorAction Stop
    }
    catch {
        throw
    }
}

# Get all variables that starts with var_
# ForEach-Object {
#     Write-Output (Get-Variable var_*)
# }

function Set-TaskProgress {
    param(
        [string]$TaskName,
        [double]$Value,
        [bool]$IsIndeterminate = $false
    )
    if ($var_RunningTask) { $var_RunningTask.Content = $TaskName }
    if ($var_ProgressBar) {
        $var_ProgressBar.IsIndeterminate = $IsIndeterminate
        $var_ProgressBar.Value = $Value
    }
    # Force WPF UI Dispatcher to refresh UI immediately
    if ($PSForm.Dispatcher) {
        $PSForm.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }
}

function Append-Output {
    param([string]$text)
    if ($var_OutputTextBox) {
        $var_OutputTextBox.AppendText($text + "`r`n")
        $var_OutputTextBox.ScrollToEnd()
        if ($PSForm.Dispatcher) {
            $PSForm.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    }
}

function checkBOX() {
    $selectedCount = 0
    if ($var_UpdatePSModule.IsChecked) { $selectedCount++ }
    if ($var_WindowsUpdate.IsChecked) { $selectedCount++ }
    if ($var_WingetUpgrade.IsChecked) { $selectedCount++ }
    if ($var_MicrosoftStoreUpdate.IsChecked) { $selectedCount++ }
    if ($var_NPMUpgrade.IsChecked) { $selectedCount++ }
    if ($var_PipUpgrade.IsChecked) { $selectedCount++ }
    if ($var_ChocoUpgrade.IsChecked) { $selectedCount++ }
    if ($var_CheckCorruptionFiles.IsChecked) { $selectedCount++ }
    if ($var_DeleteTempFiles.IsChecked) { $selectedCount++ }

    if ($selectedCount -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one task to run.", "No Tasks Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($var_OutputTextBox) {
        $var_OutputTextBox.Clear()
        Append-Output "Starting tasks..."
    }

    $completedCount = 0

    #! PowerShell Module Update
    if ($var_UpdatePSModule.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Updating Module ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nChecking update for all PowerShell modules..." -ForegroundColor Yellow
        $runCommand = "Update-Module -AcceptLicense -ErrorAction Stop"
        Append-Output "`n> $runCommand"
        $PSModuleOutput = $runCommand 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
            $_
        }

        if (!$PSModuleOutput) {
            Write-Host "No need to, there's no module that needs to be updated. 😁👍" -ForegroundColor Yellow
            Append-Output "No need to, there's no module that needs to be updated. 😁👍"
        }
        $completedCount++
    }

    #! Windows Upate
    if ($var_WindowsUpdate.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Installing Windows Updates ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nInstalling all available Windows Updates..." -ForegroundColor Yellow
        $runCommand = Install-WindowsUpdate -AcceptAll -IgnoreReboot
        Append-Output "`n> $runCommand"
        $runCommand 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
        $completedCount++
    }

    #! Winget Upgrade
    if ($var_WingetUpgrade.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Upgrading Winget ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nUpgrading all installed applications..." -ForegroundColor Yellow
        $runCommand = winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
        Append-Output "`n> $runCommand"
        $runCommand 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }

        $completedCount++
    }

    #! Microsoft Store Update
    if ($var_MicrosoftStoreUpdate.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Upgrading Store Applications ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nUpgrading all installed microsoft store applications..." -ForegroundColor Yellow
        $runCommand = powershell.exe -Command "Get-AppxPackage | Update-InboxApp"
        Append-Output "`n> $runCommand"
        $runCommand 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
        $completedCount++
    }

    #! NPM Update
    if ($var_NPMUpgrade.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Upgrading NPM Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nUpgrading all installed npm applications..." -ForegroundColor Yellow
        $runCommand = npm update -g --all
        Append-Output "`n> $runCommand"
        $runCommand 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
        $completedCount++
    }

    #! PIP Update
    if ($var_PipUpgrade.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Upgrading Pip Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nUpgrading all installed pip applications..." -ForegroundColor Yellow
        Append-Output "`n> pip list --outdated"
        $outdatedPip = pip list --outdated 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
            $_
        }
        
        $lines = $outdatedPip | Select-Object -Skip 2
        foreach ($line in $lines) {
            $pkg = ($line -split "\s+")[0].Trim()
            if ($pkg) {
                Append-Output "> pip install --upgrade $pkg"
                pip install --upgrade $pkg 2>&1 | ForEach-Object {
                    Write-Host $_
                    Append-Output $_
                }
            }
        }
        $completedCount++
    }

    #! Choco Upgrade
    if ($var_ChocoUpgrade.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Upgrading Chocolatey Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

        Write-Host "`nChecking for outdated chocolatey packages" -ForegroundColor Yellow
        Append-Output "`n> choco outdated"
        choco outdated 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
         
        Write-Host "`nUpdating all chocolatey application(s)..." -ForegroundColor Yellow
        Append-Output "`n> choco upgrade --yes all"
        choco upgrade --yes all 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
        $completedCount++
    }
    
    #! System Corruption Scan
    if ($var_CheckCorruptionFiles.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Checking System Files ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true
        
        Write-Host "`n(1/4) Run 'chkdsk' (check disk)" -ForegroundColor Yellow
        Append-Output "`n> chkdsk /scan"
        chkdsk /scan 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }

        Write-Host "`n(2/4) Run 'sfc /SCANNOW' (System File Checker) - 1st scan" -ForegroundColor Yellow
        Append-Output "`n> sfc /SCANNOW"
        sfc /SCANNOW 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }

        Write-Host "`n(3/4) Run DISM (Deployment Image Servicing and Management tool)" -ForegroundColor Yellow
        Append-Output "`n> DISM /Online /Cleanup-Image /Restorehealth"
        DISM /Online /Cleanup-Image /Restorehealth 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }

        Write-Host "`n(4/4) Run 'sfc /SCANNOW' (System File Checker) - 2nd scan" -ForegroundColor Yellow
        Append-Output "`n> sfc /SCANNOW"
        sfc /SCANNOW 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }
        $completedCount++
    }
    
    #! Delete Temp Files and Folders & Clear Recyle Bin
    if ($var_DeleteTempFiles.IsChecked) {
        $pct = ($completedCount / $selectedCount) * 100
        Set-TaskProgress -TaskName "Deleting Temporary Files ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true
        
        Write-Host "`nRunning Disk Cleanup..." -ForegroundColor Yellow
        $runDiskCleanup = "cleanmgr.exe /d $env:HOMEDRIVE /VERYLOWDISK"
        Append-Output "`n> $runDiskCleanup"
        $runDiskCleanup 2>&1 | ForEach-Object {
            Write-Host $_
            Append-Output $_
        }

        Write-Host "`nDeleting Temporary Files..." -ForegroundColor Yellow
        try {
            $deleteTempFiles1 = Get-ChildItem -Path "$env:windir\Temp" -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Append-Output "`n> $deleteTempFiles1"
            $deleteTempFiles1 2>&1 | ForEach-Object {
                Write-Host $_
                Append-Output $_
            }

            $deleteTempFiles2 = Get-ChildItem -Path "$env:windir\Temp" -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Append-Output "`n> $deleteTempFiles2"
            $deleteTempFiles2 2>&1 | ForEach-Object {
                Write-Host $_
                Append-Output $_
            }

            $deleteTempFiles3 = Get-ChildItem -Path $env:TEMP -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Append-Output "`n> $deleteTempFiles3"
            $deleteTempFiles3 2>&1 | ForEach-Object {
                Write-Host $_
                Append-Output $_
            }

            $deleteTempFiles4 = Get-ChildItem -Path $env:TEMP -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Append-Output "`n> $deleteTempFiles4"
            $deleteTempFiles4 2>&1 | ForEach-Object {
                Write-Host $_
                Append-Output $_
            }

        } catch {
            Append-Output "`nAn error occurred during temporary file deletion. $_.Exception.Message"
            Write-Warning "An error occurred during temporary file deletion. $_.Exception.Message"
        }

        $completedCount++
    }
    
    Set-TaskProgress -TaskName "Done!" -Value 100 -IsIndeterminate $false
    Append-Output "`nAll tasks completed successfully!"

    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "Tweaks are Finished "
    $Messageboxbody = ("Done")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
}

$var_RunButton.Add_Click({checkBOX})

$PSForm.ShowDialog() | Out-Null