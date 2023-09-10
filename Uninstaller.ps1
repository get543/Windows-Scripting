<#
.DESCRIPTION
This is a script that can uninstall windows default applications on your system. I use the winget method or Get-AppxPackage command

.SYNOPSIS
Use to uninstall windows default applications.
#>

# Source: https://gist.github.com/ThioJoe/5cc29231c5cb1a8f051df28a69073f77

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
    if (Get-Command -Name Get-AppxPackage) {
        Write-Host "Uninstalling using Get-AppxPackage"
    }
    elseif (Get-Command -Name winget) {
        do {
            Clear-Host
            Write-Host "Listing all application installed on the system..." -ForegroundColor Yellow
            winget list

            Write-Host
            Write-Host "Type the Id! Type 'exit' or leave it empty to skip!" -ForegroundColor Green
            Write-Host "You can type more than one, just make sure to put a space after each one!" -ForegroundColor Green
            Write-Host "Example : king.com.CandyCrushSaga_kgqvnymyfvs32 Joplin.Joplin 9NKSQGP7F2NH {024A6CF5-627D-497F-980B-B9A6EC5C40AF}_is1" -ForegroundColor Red
            Write-Host

            $WingetAppId = Read-Host -Prompt "Id "

            if ((!$WingetAppId) -or ($WingetAppId -eq 'exit'.ToLower())) {
                Write-Host "`nExit Uninstalling Application..." -ForegroundColor Yellow
                break
            }
            else {
                $ArrayID = $WingetAppId.Split(" ")

                Clear-Host
                foreach ($EachAppId in $ArrayID) {
                    Write-Host "Uninstalling Application..." -ForegroundColor Yellow
                    winget uninstall --id "${EachAppId}"
                }
            }

            Write-Host "`nEnter to continue..." -NoNewline
            Read-Host
        } while ($true)
    }
}
elseif ($Option -eq 2) {
    if (Get-Command -Name Get-AppxPackage) {
        Write-Host "Searching app name using Get-AppxPackage"
    }
    elseif (Get-Command -Name winget) {
        do {
            Clear-Host
            Write-Host "Type 'exit' or leave it empty to skip!" -ForegroundColor Green
            Write-Host "Only type 1 application!`n" -ForegroundColor Green

            $WingetAppName = Read-Host -Prompt "App Name "

            if ((!$WingetAppName) -or ($WingetAppName -eq 'exit'.ToLower())) {
                Write-Host "`nExit Searching Application..." -ForegroundColor Yellow
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
