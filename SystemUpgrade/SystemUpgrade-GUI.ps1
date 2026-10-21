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

$packageUpdateCheckboxes = @(
    $var_UpdatePSModule,
    $var_WindowsUpdate,
    $var_MicrosoftStoreUpdate,
    $var_WingetUpgrade,
    $var_ChocoUpgrade,
    $var_NPMUpgrade,
    $var_PipUpgrade
)

$maintenanceCheckboxes = @(
    $var_CheckCorruptionFiles,
    $var_DeleteTempFiles
)

$allTaskCheckboxes = $packageUpdateCheckboxes + $maintenanceCheckboxes

function Update-CheckboxButtonLabel {
    param(
        [Parameter(Mandatory)][object]$Button,
        [Parameter(Mandatory)][object[]]$Checkboxes,
        [AllowEmptyString()][string]$SectionName = ""
    )

    $allChecked = $Checkboxes.Count -gt 0 -and ($Checkboxes | Where-Object { $_.IsChecked -ne $true }).Count -eq 0
    $Button.Content = if ($allChecked) { "Uncheck All $SectionName" } else { "Check All $SectionName" }
}

function Toggle-Checkboxes {
    param(
        [Parameter(Mandatory)][object[]]$Checkboxes,
        [Parameter(Mandatory)][object]$Button,
        [AllowEmptyString()][string]$SectionName = ""
    )

    $allChecked = $Checkboxes.Count -gt 0 -and ($Checkboxes | Where-Object { $_.IsChecked -ne $true }).Count -eq 0
    foreach ($checkbox in $Checkboxes) {
        if ($checkbox) {
            $checkbox.IsChecked = -not $allChecked
        }
    }

    Update-CheckboxButtonLabel -Button $Button -Checkboxes $Checkboxes -SectionName $SectionName
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
    if ($null -eq $syncHash.OutputTextBox) {
        throw "The OutputTextBox control could not be found in MainWindow.xaml."
    }
    $syncHash.RunningTask     = $var_RunningTask
    $syncHash.ProgressBar     = $var_ProgressBar
    $syncHash.RunButton       = $var_RunButton
    $syncHash.SelectedTasks   = $selectedTasks
    $syncHash.SelectedCount   = $selectedCount
    $syncHash.UpdateScriptPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Update-MicrosoftStoreApps.ps1'))
    $syncHash.OutputQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $syncHash.ProgressLineStart = $null
    $syncHash.ProgressLineLength = $null
    $syncHash.OutputMaxCharacters = 300000

    $outputTimer = New-Object System.Windows.Threading.DispatcherTimer
    $outputTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timerSync = $syncHash
    $outputTimer.Add_Tick({
        $outputTextBox = $timerSync.OutputTextBox
        if ($null -eq $outputTextBox) { return }

        $pendingItems = [System.Collections.Generic.List[object]]::new()
        $item = $null
        while ($pendingItems.Count -lt 200 -and $timerSync.OutputQueue.TryDequeue([ref]$item)) {
            $pendingItems.Add($item)
        }

        if ($pendingItems.Count -eq 0) { return }

        $pendingText = [System.Text.StringBuilder]::new()

        for ($index = 0; $index -lt $pendingItems.Count; $index++) {
            $item = $pendingItems[$index]

            switch ($item.Type) {
                'Output' {
                    if ($item.ReplaceLastLine) {
                        while (($index + 1) -lt $pendingItems.Count -and
                            $pendingItems[$index + 1].Type -eq 'Output' -and
                            $pendingItems[$index + 1].ReplaceLastLine) {
                            $index++
                            $item = $pendingItems[$index]
                        }

                        if ($pendingText.Length -gt 0) {
                            $outputTextBox.AppendText($pendingText.ToString())
                            $null = $pendingText.Clear()
                        }

                        if ($null -eq $timerSync.ProgressLineStart) {
                            $timerSync.ProgressLineStart = $outputTextBox.Text.Length
                            $timerSync.ProgressLineLength = 0
                        }

                        $lineStart = [int]$timerSync.ProgressLineStart
                        $lineLength = [int]$timerSync.ProgressLineLength
                        $outputTextBox.Select($lineStart, $lineLength)
                        $outputTextBox.SelectedText = $item.Text
                        $timerSync.ProgressLineLength = $item.Text.Length
                    }
                    else {
                        if ($null -ne $timerSync.ProgressLineStart) {
                            $null = $pendingText.Append("`r`n")
                            $timerSync.ProgressLineStart = $null
                            $timerSync.ProgressLineLength = $null
                        }

                        $null = $pendingText.Append($item.Text).Append("`r`n")
                    }
                }
                'Progress' {
                    if ($pendingText.Length -gt 0) {
                        $outputTextBox.AppendText($pendingText.ToString())
                        $null = $pendingText.Clear()
                    }

                    if ($timerSync.RunningTask) { $timerSync.RunningTask.Content = $item.TaskName }
                    if ($timerSync.ProgressBar) {
                        $timerSync.ProgressBar.IsIndeterminate = $item.IsIndeterminate
                        $timerSync.ProgressBar.Value = $item.Value
                    }
                }
                'Completed' {
                    if ($pendingText.Length -gt 0) {
                        $outputTextBox.AppendText($pendingText.ToString())
                        $null = $pendingText.Clear()
                    }

                    if ($timerSync.RunningTask) { $timerSync.RunningTask.Content = 'Done!' }
                    if ($timerSync.ProgressBar) {
                        $timerSync.ProgressBar.IsIndeterminate = $false
                        $timerSync.ProgressBar.Value = 100
                    }
                    $timerSync.RunButton.IsEnabled = $true
                    $outputTimer.Stop()
                    [System.Windows.MessageBox]::Show('Done', 'Tweaks are Finished', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
            }
        }

        if ($pendingText.Length -gt 0) {
            $outputTextBox.AppendText($pendingText.ToString())
            $null = $pendingText.Clear()
        }

        if ($outputTextBox.Text.Length -gt $timerSync.OutputMaxCharacters) {
            $removeLength = $outputTextBox.Text.Length - $timerSync.OutputMaxCharacters
            $nextLine = $outputTextBox.Text.IndexOf("`n", $removeLength)
            if ($nextLine -ge 0) { $removeLength = $nextLine + 1 }
            $outputTextBox.Select(0, $removeLength)
            $outputTextBox.SelectedText = ''

            if ($null -ne $timerSync.ProgressLineStart) {
                if ($timerSync.ProgressLineStart -le $removeLength) {
                    $timerSync.ProgressLineStart = $null
                    $timerSync.ProgressLineLength = $null
                }
                else {
                    $timerSync.ProgressLineStart -= $removeLength
                }
            }
        }

        $outputTextBox.ScrollToEnd()
    }.GetNewClosure())
    $outputTimer.Start()

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
            $null = $sync.OutputQueue.Enqueue([pscustomobject]@{
                Type = 'Progress'
                TaskName = $TaskName
                Value = $Value
                IsIndeterminate = $IsIndeterminate
            })
        }

        function Append-Output {
            param(
                [string]$text,
                [switch]$ReplaceLastLine
            )
            $null = $sync.OutputQueue.Enqueue([pscustomobject]@{
                Type = 'Output'
                Text = $text
                ReplaceLastLine = [bool]$ReplaceLastLine
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
            $updateScriptPath = $sync.UpdateScriptPath
            Append-Output "> . $updateScriptPath"

            try {
                if (Test-Path -LiteralPath $updateScriptPath -PathType Leaf) {
                    . $updateScriptPath *>&1 | ForEach-Object {
                        Append-Output $_.ToString()
                    }
                } else {
                    Append-Output "Microsoft Store update script not found: $updateScriptPath"
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

            try {
                Append-Output "`nUpgrading pip itself..."
                Append-Output "> python.exe -m pip install --upgrade pip"
                python.exe -m pip install --upgrade pip
    
                Append-Output "`nUpgrading all installed pip applications..."
                Append-Output "> pip list --outdated"
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

            try {            
                Append-Output "`nUpdating all chocolatey application(s)..."
                Append-Output "> choco upgrade --yes all"
                choco upgrade --yes all 2>&1 | ForEach-Object {
                    $outputLine = $_.ToString()
                    if ($outputLine -match '\b\d{1,3}(?:\.\d+)?\s*%') {
                        Append-Output -text $outputLine -ReplaceLastLine
                    } else {
                        Append-Output $outputLine
                    }
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
        $null = $sync.OutputQueue.Enqueue([pscustomobject]@{ Type = 'Completed' })
    }) | Out-Null

    $ps.AddArgument($syncHash) | Out-Null
    $null = $ps.BeginInvoke()
}

$var_CheckAllButton.Add_Click({
    Toggle-Checkboxes -Checkboxes $allTaskCheckboxes -Button $var_CheckAllButton -SectionName ""
})

$var_CheckAllPackageUpdatesButton.Add_Click({
    Toggle-Checkboxes -Checkboxes $packageUpdateCheckboxes -Button $var_CheckAllPackageUpdatesButton -SectionName "in Section"
})

$var_CheckAllMaintenanceButton.Add_Click({
    Toggle-Checkboxes -Checkboxes $maintenanceCheckboxes -Button $var_CheckAllMaintenanceButton -SectionName "in Section"
})

foreach ($checkbox in $allTaskCheckboxes) {
    $checkbox.Add_Checked({
        Update-CheckboxButtonLabel -Button $var_CheckAllButton -Checkboxes $allTaskCheckboxes -SectionName ""
        Update-CheckboxButtonLabel -Button $var_CheckAllPackageUpdatesButton -Checkboxes $packageUpdateCheckboxes -SectionName "in Section"
        Update-CheckboxButtonLabel -Button $var_CheckAllMaintenanceButton -Checkboxes $maintenanceCheckboxes -SectionName "in Section"
    })
    $checkbox.Add_Unchecked({
        Update-CheckboxButtonLabel -Button $var_CheckAllButton -Checkboxes $allTaskCheckboxes -SectionName ""
        Update-CheckboxButtonLabel -Button $var_CheckAllPackageUpdatesButton -Checkboxes $packageUpdateCheckboxes -SectionName "in Section"
        Update-CheckboxButtonLabel -Button $var_CheckAllMaintenanceButton -Checkboxes $maintenanceCheckboxes -SectionName "in Section"
    })
}

Update-CheckboxButtonLabel -Button $var_CheckAllButton -Checkboxes $allTaskCheckboxes -SectionName ""
Update-CheckboxButtonLabel -Button $var_CheckAllPackageUpdatesButton -Checkboxes $packageUpdateCheckboxes -SectionName "in Section"
Update-CheckboxButtonLabel -Button $var_CheckAllMaintenanceButton -Checkboxes $maintenanceCheckboxes -SectionName "in Section"

$var_RunButton.Add_Click({checkBOX})

$PSForm.ShowDialog() | Out-Null