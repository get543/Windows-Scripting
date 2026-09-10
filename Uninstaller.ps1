<#
.DESCRIPTION
This is a script that can uninstall windows default applications on your system. I use the winget method or Get-AppxPackage command

.SYNOPSIS
Use to uninstall windows default applications.
#>

# Source: https://gist.github.com/ThioJoe/5cc29231c5cb1a8f051df28a69073f77

function Read-CheckboxMenu {
    <#
    .SYNOPSIS
    Displays an interactive terminal checkbox menu for multi-option selection.

    .DESCRIPTION
    Presents a list of options in the console where the user can navigate with Up/Down arrow keys,
    toggle item selections with the Spacebar, and confirm choices with Enter. Returns an array of selected options.

    .PARAMETER Options
    An array of string options to display in the menu.

    .PARAMETER Title
    The header title displayed above the menu options.
    #>

    param(
        [Parameter(Mandatory)][string[]]$Options,
        [string]$Title = "Select options (Up/Down: Navigate, Space: Toggle, Enter: Confirm, Esc: Cancel):"
    )

    if ($Options.Count -eq 0) { return @() }

    $selected = New-Object bool[] $Options.Count
    $currentIndex = 0
    $topIndex = 0

    [Console]::CursorVisible = $false

    Clear-Host
    Write-Host $Title -ForegroundColor Cyan
    $initialCursorTop = [Console]::CursorTop

    $lastWidth = [Console]::WindowWidth
    $lastHeight = [Console]::WindowHeight

    try {
        while ($true) {
            $winWidth = [Console]::WindowWidth
            $winHeight = [Console]::WindowHeight

            # 1. Resize Detection
            if ($winWidth -ne $lastWidth -or $winHeight -ne $lastHeight) {
                Clear-Host
                Write-Host $Title -ForegroundColor Cyan
                $initialCursorTop = [Console]::CursorTop
                $lastWidth = $winWidth
                $lastHeight = $winHeight
            }

            # 2. Reserve room for Title + Status Footer + Safety Margin
            $maxVisible = [Math]::Max(1, $winHeight - $initialCursorTop - 3)

            # 3. Viewport Scrolling
            if ($currentIndex -lt $topIndex) {
                $topIndex = $currentIndex
            }
            elseif ($currentIndex -ge ($topIndex + $maxVisible)) {
                $topIndex = $currentIndex - $maxVisible + 1
            }

            [Console]::SetCursorPosition(0, $initialCursorTop)

            $endIndex = [Math]::Min($Options.Count - 1, $topIndex + $maxVisible - 1)
            $renderedRows = ($endIndex - $topIndex) + 1

            # 4. Render Items + Right-Edge Scrollbar Track
            for ($r = 0; $r -lt $renderedRows; $r++) {
                $i = $topIndex + $r
                $isCurrent = ($i -eq $currentIndex)
                $isChecked = $selected[$i]

                $pointer = if ($isCurrent) { ">" } else { " " }
                $box = if ($isChecked) { "[x]" } else { "[ ]" }
                $lineText = "$pointer $box $($Options[$i])"

                # Calculate scrollbar thumb position
                $scrollChar = " "
                if ($Options.Count -gt $maxVisible) {
                    $thumbPos = if ($Options.Count -gt 1) { 
                        [Math]::Floor(($currentIndex / ($Options.Count - 1)) * ($renderedRows - 1)) 
                    }
                    else { 0 }
                    
                    $scrollChar = if ($r -eq $thumbPos) { "█" } else { "░" }
                }

                # Reserve 2 spaces on far right for scrollbar track
                $maxWidth = [Math]::Max(1, $winWidth - 3)
                if ($lineText.Length -gt $maxWidth) {
                    $lineText = $lineText.Substring(0, $maxWidth)
                }
                else {
                    $lineText = $lineText.PadRight($maxWidth)
                }

                if ($isCurrent) {
                    Write-Host $lineText -ForegroundColor Yellow -BackgroundColor Black -NoNewline
                    Write-Host " $scrollChar" -ForegroundColor DarkGray -BackgroundColor Black
                }
                else {
                    Write-Host $lineText -ForegroundColor Gray -BackgroundColor Black -NoNewline
                    Write-Host " $scrollChar" -ForegroundColor DarkGray -BackgroundColor Black
                }
            }

            # Clear leftover screen space if rows shrink
            if ($renderedRows -lt $maxVisible) {
                $blankLine = "".PadRight($winWidth - 1)
                for ($r = $renderedRows; $r -lt $maxVisible; $r++) {
                    Write-Host $blankLine -BackgroundColor Black
                }
            }

            # 5. Render Status Footer Line
            $selectedCount = ($selected | Where-Object { $_ -eq $true }).Count
            $statusText = " [Item $($currentIndex + 1)/$($Options.Count) | Selected: $selectedCount/$($Options.Count)]"
            $paddedStatus = $statusText.PadRight([Math]::Max(1, $winWidth - 1))
            Write-Host $paddedStatus -ForegroundColor DarkCyan -BackgroundColor Black

            # 6. Input Handling
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow' { 
                    $currentIndex = if ($currentIndex -gt 0) { $currentIndex - 1 } else { $Options.Count - 1 }
                }
                'DownArrow' { 
                    $currentIndex = if ($currentIndex -lt $Options.Count - 1) { $currentIndex + 1 } else { 0 }
                }
                'Spacebar' { 
                    $selected[$currentIndex] = -not $selected[$currentIndex] 
                }
                'Escape' { 
                    return @() 
                }
                'Enter' {
                    $result = @()
                    for ($i = 0; $i -lt $Options.Count; $i++) {
                        if ($selected[$i]) { $result += $Options[$i] }
                    }
                    return $result
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
        Clear-Host
    }
}

function uninstaller() {
    if (Get-Command -Name winget) {
        do {
            Clear-Host

            # 1. Capture winget output
            $wingetOutput = winget list --accept-source-agreements

            # 2. Find header row and column boundaries
            $dashIndex = [array]::IndexOf($wingetOutput, ($wingetOutput -match '^-{3,}$')[0])
            if ($dashIndex -lt 1) { return }

            $header = $wingetOutput[$dashIndex - 1]
            $idStart = $header.IndexOf("Id")
            $versionStart = $header.IndexOf("Version")
            $idLength = $versionStart - $idStart

            # 3. Parse Name and Id into a clean list of objects
            $packages = foreach ($line in $wingetOutput[($dashIndex + 1)..$wingetOutput.Count]) {
                # Stop parsing at empty lines or footer summary text
                if ([string]::IsNullOrWhiteSpace($line) -or $line -match 'package\(s\)' -or $line -match 'Use --') { 
                    break 
                }

                if ($line.Length -gt $idStart) {
                    $name = $line.Substring(0, [Math]::Min($idStart, $line.Length)).Trim()
        
                    $subLength = [Math]::Min($idLength, $line.Length - $idStart)
                    $id = $line.Substring($idStart, $subLength).Trim()

                    if ($name -and $id) {
                        [PSCustomObject]@{ Name = $name; Id = $id }
                    }
                }
            }

            if (-not $packages) {
                Write-Host "No packages found." -ForegroundColor Yellow
                return
            }

            # 4. Build menu options (appends [Id] only if duplicate app names exist)
            $displayMap = @{}
            $nameCounts = $packages.Name | Group-Object

            $options = foreach ($pkg in $packages) {
                $isDuplicate = ($nameCounts | Where-Object Name -eq $pkg.Name).Count -gt 1
                $displayName = if ($isDuplicate) { "$($pkg.Name) [$($pkg.Id)]" } else { $pkg.Name }
    
                $displayMap[$displayName] = $pkg.Id
                $displayName
            }

            # 5. Display names in your custom checkbox menu
            $selectedDisplays = Read-CheckboxMenu `
                -Options $options `
                -Title "`nHow To Use : `
                        `n- Use Up/Down arrows to move, Space to toggle, Enter to confirm `
                        `n- To exit, unselect all and press Enter `
                        `nSelect winget packages you want to uninstall:"

            if (-not $selectedDisplays) { break }

            # 6. Map selected names back to IDs and execute uninstall
            $selectedIds = $selectedDisplays | ForEach-Object { $displayMap[$_] }

            Write-Host "`nSelected Package IDs to Uninstall:" -ForegroundColor Green
            $selectedIds | ForEach-Object { Write-Host " - $_" }

            foreach ($id in $selectedIds) {
                Write-Host "`nUninstalling $id..." -ForegroundColor Yellow
                winget uninstall --id "$id" --include-unknown --accept-package-agreements --accept-source-agreements
            }

            Write-Host "`nEnter to continue..." -NoNewline
            Read-Host
        } while ($true)
    }
}

function searchApps() {
    if (Get-Command -Name winget) {
        do {
            Clear-Host
            Write-Host "Type 'exit' or leave it empty to skip!" -ForegroundColor Green
            Write-Host "Type '1' to uninstall some apps" -ForegroundColor Green
            Write-Host "Only type 1 application!`n" -ForegroundColor Green

            $WingetAppName = Read-Host -Prompt "App Name "

            if ((!$WingetAppName) -or ($WingetAppName -eq 'exit'.ToLower())) {
                Write-Host "`nExit Searching Application..." -ForegroundColor Yellow
                break
            }
            elseif ($WingetAppName -eq "1") {
                uninstaller
                break
            }
            else {
                Clear-Host
                Write-Host "Searching Application..." -ForegroundColor Yellow
                winget list --name "${WingetAppName}"

                Write-Host "`nEnter to continue..." -NoNewline
                Read-Host
            }
        } while ($true)
    }
}

# ===================================================================================================================================================
Write-Host "                                       Uninstalling System Application                                          " -ForegroundColor Blue
Write-Host " --------------------------------------------------------------------------------------------------------------- "
Write-Host "|   No  |           Option              |                                   Why ?                               |"
Write-Host " --------------------------------------------------------------------------------------------------------------- "
Write-Host "|   1   |        Uninstall Package      |  Because you want to uninstall windows default windows applications   |"
Write-Host "|   2   |   Search Application By Name  |  Because on winget sometimes the Id got cutoff (idk why)              |"
Write-Host " --------------------------------------------------------------------------------------------------------------- "
Write-Host "Choose your option : " -ForegroundColor Blue -NoNewline
$Option = Read-Host

if ($Option -eq 1) {
    uninstaller
}
elseif ($Option -eq 2) {
    searchApps
}
# ===================================================================================================================================================