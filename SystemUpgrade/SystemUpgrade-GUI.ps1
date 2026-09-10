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

function checkBOX() {
    $selectedTasks = [ordered]@{
        UpdatePSModule       = $var_UpdatePSModule.IsChecked -eq $true
        WindowsUpdate        = $var_WindowsUpdate.IsChecked -eq $true
        WingetUpgrade        = $var_WingetUpgrade.IsChecked -eq $true
        MicrosoftStoreUpdate = $var_MicrosoftStoreUpdate.IsChecked -eq $true
        NPMUpgrade           = $var_NPMUpgrade.IsChecked -eq $true
        PipUpgrade           = $var_PipUpgrade.IsChecked -eq $true
        ChocoUpgrade         = $var_ChocoUpgrade.IsChecked -eq $true
        CheckCorruptionFiles = $var_CheckCorruptionFiles.IsChecked -eq $true
        DeleteTempFiles      = $var_DeleteTempFiles.IsChecked -eq $true
    }

    $selectedCount = 0
    foreach ($val in $selectedTasks.Values) {
        if ($val) { $selectedCount++ }
    }

    if ($selectedCount -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one task to run.", "No Tasks Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # Disable RunButton while background tasks are running
    $var_RunButton.IsEnabled = $false

    if ($var_OutputTextBox) {
        $var_OutputTextBox.Clear()
        $var_OutputTextBox.AppendText("Starting tasks...`r`n")
    }

    if ($var_RunningTask) { $var_RunningTask.Content = "Starting tasks..." }
    if ($var_ProgressBar) {
        $var_ProgressBar.IsIndeterminate = $false
        $var_ProgressBar.Value = 0
    }

    # Setup Synchronized Hashtable for Background Runspace
    $syncHash = [hashtable]::Synchronized(@{})
    $syncHash.Window          = $PSForm
    $syncHash.OutputTextBox   = $var_OutputTextBox
    $syncHash.RunningTask     = $var_RunningTask
    $syncHash.ProgressBar     = $var_ProgressBar
    $syncHash.RunButton       = $var_RunButton
    $syncHash.SelectedTasks   = $selectedTasks
    $syncHash.SelectedCount   = $selectedCount

    # Create background runspace to keep WPF UI responsive
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()

    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    $ps.AddScript({
        param($sync)

        function Set-TaskProgress {
            param(
                [string]$TaskName,
                [double]$Value,
                [bool]$IsIndeterminate = $false
            )
            $sync.Window.Dispatcher.Invoke([action]{
                if ($sync.RunningTask) { $sync.RunningTask.Content = $TaskName }
                if ($sync.ProgressBar) {
                    $sync.ProgressBar.IsIndeterminate = $IsIndeterminate
                    $sync.ProgressBar.Value = $Value
                }
            })
        }

        function Append-Output {
            param([string]$text)
            $sync.Window.Dispatcher.Invoke([action]{
                if ($sync.OutputTextBox) {
                    $sync.OutputTextBox.AppendText($text + "`r`n")
                    $sync.OutputTextBox.ScrollToEnd()
                }
            })
        }

        $selectedCount = $sync.SelectedCount
        $tasks = $sync.SelectedTasks
        $completedCount = 0

        #! PowerShell Module Update
        if ($tasks.UpdatePSModule) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Updating Module ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nChecking update for all PowerShell modules..."
            Append-Output "> Update-Module -AcceptLicense"
            $hasOutput = $false
            try {
                Update-Module -AcceptLicense -ErrorAction SilentlyContinue 2>&1 | ForEach-Object {
                    $hasOutput = $true
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }

            if (-not $hasOutput) {
                Append-Output "No need to, there's no module that needs to be updated. 😁👍"
            }
            $completedCount++
        }

        #! Windows Update
        if ($tasks.WindowsUpdate) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Installing Windows Updates ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nInstalling all available Windows Updates..."
            Append-Output "> Install-WindowsUpdate -AcceptAll -IgnoreReboot"
            try {
                Install-WindowsUpdate -AcceptAll -IgnoreReboot 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! Winget Upgrade
        if ($tasks.WingetUpgrade) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Upgrading Winget ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nUpgrading all installed applications..."
            Append-Output "> winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
            try {
                winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }

            $completedCount++
        }

        #! Microsoft Store Update
        if ($tasks.MicrosoftStoreUpdate) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Upgrading Store Applications ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nUpgrading all installed microsoft store applications..."
            Append-Output "> Get-AppxPackage | Update-InboxApp"
            try {
                powershell.exe -Command "Get-AppxPackage | Update-InboxApp" 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! NPM Update
        if ($tasks.NPMUpgrade) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Upgrading NPM Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nUpgrading all installed npm applications..."
            Append-Output "> npm update -g --all"
            try {
                npm update -g --all 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! PIP Update
        if ($tasks.PipUpgrade) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Upgrading Pip Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nUpgrading all installed pip applications..."
            Append-Output "> pip list --outdated"
            try {
                $outdatedPip = pip list --outdated 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                    $_.ToString()
                }
                
                $lines = $outdatedPip | Select-Object -Skip 2
                foreach ($line in $lines) {
                    $pkg = ($line -split "\s+")[0].Trim()
                    if ($pkg) {
                        Append-Output "> pip install --upgrade $pkg"
                        pip install --upgrade $pkg 2>&1 | ForEach-Object {
                            Append-Output $_.ToString()
                        }
                    }
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! Choco Upgrade
        if ($tasks.ChocoUpgrade) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Upgrading Chocolatey Packages ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true

            Append-Output "`nChecking for outdated chocolatey packages"
            Append-Output "> choco outdated"
            try {
                choco outdated 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
                
                Append-Output "`nUpdating all chocolatey application(s)..."
                Append-Output "> choco upgrade --yes all"
                choco upgrade --yes all 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! System Corruption Scan
        if ($tasks.CheckCorruptionFiles) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Checking System Files ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true
            
            try {
                Append-Output "`n(1/4) Run 'chkdsk' (check disk)"
                Append-Output "> chkdsk /scan"
                chkdsk /scan 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }

                Append-Output "`n(2/4) Run 'sfc /SCANNOW' (System File Checker) - 1st scan"
                Append-Output "> sfc /SCANNOW"
                sfc /SCANNOW 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }

                Append-Output "`n(3/4) Run DISM (Deployment Image Servicing and Management tool)"
                Append-Output "> DISM /Online /Cleanup-Image /Restorehealth"
                DISM /Online /Cleanup-Image /Restorehealth 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }

                Append-Output "`n(4/4) Run 'sfc /SCANNOW' (System File Checker) - 2nd scan"
                Append-Output "> sfc /SCANNOW"
                sfc /SCANNOW 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }
            } catch {
                Append-Output $_.Exception.Message
            }
            $completedCount++
        }

        #! Delete Temp Files and Folders & Clear Recycle Bin
        if ($tasks.DeleteTempFiles) {
            $pct = ($completedCount / $selectedCount) * 100
            Set-TaskProgress -TaskName "Deleting Temporary Files ($($completedCount + 1)/$selectedCount)..." -Value $pct -IsIndeterminate $true
            
            Append-Output "`nRunning Disk Cleanup..."
            Append-Output "> cleanmgr.exe /d $env:HOMEDRIVE /VERYLOWDISK"
            try {
                cleanmgr.exe /d $env:HOMEDRIVE /VERYLOWDISK 2>&1 | ForEach-Object {
                    Append-Output $_.ToString()
                }

                Append-Output "`nDeleting Temporary Files..."
                Get-ChildItem -Path "$env:windir\Temp" -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path "$env:windir\Temp" -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Get-ChildItem -Path $env:TEMP -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $env:TEMP -Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Append-Output "Temporary files deleted successfully."
            } catch {
                Append-Output "`nAn error occurred during temporary file deletion: $($_.Exception.Message)"
            }

            $completedCount++
        }

        Set-TaskProgress -TaskName "Done!" -Value 100 -IsIndeterminate $false
        Append-Output "`nAll tasks completed successfully!"

        $sync.Window.Dispatcher.Invoke([action]{
            $sync.RunButton.IsEnabled = $true
            [System.Windows.MessageBox]::Show("Done", "Tweaks are Finished", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        })
    }) | Out-Null

    $ps.AddArgument($syncHash) | Out-Null
    $null = $ps.BeginInvoke()
}

$var_RunButton.Add_Click({checkBOX})

$PSForm.ShowDialog() | Out-Null