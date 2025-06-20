<#
.COMPONENT
gdown
winrar or 7zip

.DESCRIPTION
Install LSP Software, if WinRar is installed, it will autmatically extract .rar file downloaded from GDrive

.PARAMETER autoinstall
It will autoinstall or upgrade all apps that can be downloaded using winget

.NOTES
0. Open PowerShell as Admin
1. Allow PowerShell scripts to run only in the current terminal session: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
2. Run this: Invoke-RestMethod https://raw.githubusercontent.com/get543/Windows-Scripting/refs/heads/main/LSP.ps1 | Invoke-Expression

.NOTES
PowerShell One-Liner

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -autoinstall
& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -activation
#>

#TODO FOLDER DOWNLOAD ? (LIMIT 50 FOLDERS)
#TODO CHECK IF WINGET APPS (JAVA, VSCODE, ETC) IS INSTALLED OR NOT | ✅ AUTOINSTALL ❌ NORMAL SCRIPT
#TODO AUTOINSTALL CRACK SOFTWARE FROM GDRIVE OR WEB

param (
    [switch]$autoinstall,
    [string]$activation
)

Set-Location "$env:USERPROFILE\Downloads"

function WingetInstall {
    <#
    .SYNOPSIS
    Installs winget using powershell module.
    This block of code is official from microsoft's website.
    #>

    $progressPreference = 'silentlyContinue'
    Write-Host "Installing WinGet PowerShell module from PSGallery..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." -ForegroundColor Yellow
    Repair-WinGetPackageManager -AllUsers -ErrorAction SilentlyContinue
    Write-Host "Done."
}

if (Test-Path "${env:ProgramFiles}\WinRAR\UnRAR.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`nWinRAR is installed, will be using it to extract .rar files" -ForegroundColor Yellow
    $winrarInstalled = $true
} elseif (Test-Path "${env:ProgramFiles}\7-Zip\7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`n7-Zip is installed, will be using it to extract .rar files" -ForegroundColor Yellow
    $7zipInstalled = $true
}

function WingetInstallCommand($name, $source) {
    winget install $name --accept-package-agreements --accept-source-agreements --source $source
}

#! ===================================================================
#!                          -activation 
#! ===================================================================
if ($activation) {
    Write-Host "Activating Microsoft Office products permanently (hopefully)..." -ForegroundColor Yellow
    & ([ScriptBlock]::Create((Invoke-RestMethod https://get.activated.win))) /Ohook
    
    Write-Host "Activating Windows permanently (hopefully)..." -ForegroundColor Yellow
    & ([ScriptBlock]::Create((Invoke-RestMethod https://get.activated.win))) /KMS38
    return
}

#####################! windows #####################
if ($activation -eq "windows") {
    Write-Host "Activating Windows permanently (hopefully)..." -ForegroundColor Yellow
    & ([ScriptBlock]::Create((Invoke-RestMethod https://get.activated.win))) /KMS38
    return
}
#####################! office #####################
if ($activation -eq "office") {
    Write-Host "Activating Microsoft Office products permanently (hopefully)..." -ForegroundColor Yellow
    & ([ScriptBlock]::Create((Invoke-RestMethod https://get.activated.win))) /Ohook
    return
}


#! ===================================================================
#!                          -autoinstall
#! ===================================================================
if ($autoinstall) {
    if (!$winrarInstalled -or !$7zipInstalled) {
        Write-Host "`nWinRAR or 7-Zip is not installed but still continue with the installation." -ForegroundColor Yellow 
    }

    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "`nWinget is not installed!" -ForegroundColor Red
        WingetInstall
    }
    
    #################### USING WINGET ####################
    $appArray = @("android-studio", "balsamiq", "capcut", "figma", "fluid ui", "jre", "vscode", "staruml", "php")
    
    foreach ($app in $appArray) {
        if (winget list $app -eq "No installed package found matching input criteria.") {
            if ($app -eq "jre") {
                WingetInstallCommand "Oracle.JavaRuntimeEnvironment" "winget"
                WingetInstallCommand "Oracle.JDK.20" "winget"

            } elseif ($app -eq "php") {
                WingetInstallCommand "PHP.PHP.8.4" "winget"
                WingetInstallCommand "ApacheFriends.Xampp.8.2" "winget"
                
            } elseif ($app -eq "capcut") {
                winget install XP9KN75RRB9NHS --accept-package-agreements --accept-source-agreements
                WingetInstallCommand "XP9KN75RRB9NHS" "msstore"
                
            } else {
                winget install $app --accept-package-agreements --accept-source-agreements

            }
        } else {
            Write-Host "`nIt seems like a version of $app is already installed, skiping this step..." -ForegroundColor Red
        }
    }
    
    if (!(Get-Command gdown -ErrorAction SilentlyContinue)) {
        if (!(Get-Command pip -ErrorAction SilentlyContinue)) {
            Write-Host "`nInstalling Python 3.13" -ForegroundColor Yellow
            WingetInstallCommand "Python.Python.3.13" "winget"
        }
        pip install gdown
    }
    
    Write-Host "`nOk so you've reached the end of the script" -ForegroundColor Red
    return
}


#! ===================================================================
#!                          NORMAL EXECUTION
#! ===================================================================
if (!(Get-Command gdown -ErrorAction SilentlyContinue)) {
    Write-Host "`ngdown is not installed!" -ForegroundColor Red
    Write-Host "Run pip install gdown ? [Y/n] " -ForegroundColor Yellow -NoNewline
    $installGdown = Read-Host
    if (($installGdown.Tolower() -eq "y") -or ($installGdown -eq "")) {
        try {
            pip install gdown
        }
        catch {
            return Write-Host "`nOops, something's wrong. Maybe python or pip is not properly configured." -ForegroundColor Red
        }
    }
}

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "`nWinget is not installed!" -ForegroundColor Red
    WingetInstall
}

Write-Host "`nUpdating winget source..." -ForegroundColor Yellow
winget upgrade

# https://ozh.github.io/ascii-tables/
#Write-Host "
#+----+------------------------------+-----------------+---------+--------+
#| No |           Software           |     Source      | Version | Status |
#+----+------------------------------+-----------------+---------+--------+
#|  1 | ACL 9                        | GDrive          |         | OK     |
#|  2 | Adobe Illustrator            | GDrive          |         | ?      |
#|  3 | Adobe Photoshop              | GDrive          |         | ?      |
#|  4 | Adobe Premier                | GDrive          |         | ?      |
#|  5 | Android Studio               | winget          |         | OK     |
#|  6 | AutoCad                      |                 |         |        |
#|  7 | Balsamiq                     | winget          |         | OK     |
#|  8 | CapCut                       | winget          |         | OK     |
#|  9 | Circuit Wizard               |                 |         |        |
#| 10 | CorelDraw                    | GDrive          |         | ?      |
#| 11 | CX Programming               |                 |         |        |
#| 12 | Draw.io                      | https://draw.io |         | OK     |
#| 13 | Figma                        | winget          |         | OK     |
#| 14 | Fluid UI                     | winget          |         | OK     |
#| 15 | Java                         | winget          |       8 | OK     |
#| 16 | JDK                          | winget          |      20 | OK     |
#| 17 | Krishand Inventory 3.0       |                 |         |        |
#| 18 | Minitab                      | GDrive          |         | OK     |
#| 19 | Microsot Excel               | MAS (github)    |         | OK     |
#| 20 | Microsoft Word               | MAS (github)    |         | OK     |
#| 21 | Microsoft Visio              |                 |         |        |
#| 22 | Microsoft Visual Studio Code | winget          |         | OK     |
#| 23 | PHP                          | winget          |     8.4 | OK     |
#| 24 | POM QM                       |                 |         |        |
#| 25 | SPSS                         |                 |         |        |
#| 26 | Star UML                     | winget          |         | OK     |
#| 27 | XAMPP                        | winget          |     8.2 | OK     |
#| 28 | Zahir                        | GDrive          |         | ?      |
#| 29 | Data Simulasi 2012           | GDrive          |         | OK     |
#+----+------------------------------+-----------------+---------+--------+
#"

##################################### !CUSTOM TABLE OBJECT #####################################
$table = @(
    [PSCustomObject]@{No=1;  Software='ACL 9';                     Source='GDrive';          Version='';    Status='OK'}
    [PSCustomObject]@{No=2;  Software='Adobe Illustrator';         Source='GDrive';          Version='';    Status='?'}
    [PSCustomObject]@{No=3;  Software='Adobe Photoshop';           Source='GDrive';          Version='';    Status='?'}
    [PSCustomObject]@{No=4;  Software='Adobe Premier';             Source='GDrive';          Version='';    Status='?'}
    [PSCustomObject]@{No=5;  Software='Android Studio';            Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=6;  Software='AutoCad';                   Source='';                Version='';    Status=''}
    [PSCustomObject]@{No=7;  Software='Balsamiq';                  Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=8;  Software='CapCut';                    Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=9;  Software='Circuit Wizard';            Source='';                Version='';    Status='OK'}
    [PSCustomObject]@{No=10; Software='CorelDraw';                 Source='GDrive';          Version='';    Status='SOON'}
    [PSCustomObject]@{No=11; Software='CX Programming';            Source='';                Version='';    Status='SOON'}
    [PSCustomObject]@{No=12; Software='Draw.io';                   Source='https://draw.io'; Version='';    Status='OK'}
    [PSCustomObject]@{No=13; Software='Figma';                     Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=14; Software='Fluid UI';                  Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=14; Software='FluidSIM';                  Source='';                Version='';    Status='SOON'}
    [PSCustomObject]@{No=15; Software='Java';                      Source='winget';          Version='8';   Status='OK'}
    [PSCustomObject]@{No=16; Software='JDK';                       Source='winget';          Version='20';  Status='OK'}
    [PSCustomObject]@{No=17; Software='Krishand Inventory 3.0';    Source='';                Version='3.0'; Status='OK'}
    [PSCustomObject]@{No=18; Software='Minitab';                   Source='GDrive';          Version='';    Status='OK'}
    [PSCustomObject]@{No=19; Software='Microsot Excel';            Source='MAS (github)';    Version='';    Status='OK'}
    [PSCustomObject]@{No=20; Software='Microsoft Word';            Source='MAS (github)';    Version='';    Status='OK'}
    [PSCustomObject]@{No=21; Software='Microsoft Visio';           Source='';                Version='';    Status='SOON'}
    [PSCustomObject]@{No=22; Software='Microsoft Visual Studio Code'; Source='winget';       Version='';    Status='OK'}
    [PSCustomObject]@{No=23; Software='PHP';                       Source='winget';          Version='8.4'; Status='OK'}
    [PSCustomObject]@{No=24; Software='POM QM';                    Source='';                Version='';    Status='OK'}
    [PSCustomObject]@{No=25; Software='SPSS';                      Source='';                Version='';    Status='OK'}
    [PSCustomObject]@{No=26; Software='Star UML';                  Source='winget';          Version='';    Status='OK'}
    [PSCustomObject]@{No=27; Software='XAMPP';                     Source='winget';          Version='8.2'; Status='OK'}
    [PSCustomObject]@{No=28; Software='Zahir';                     Source='GDrive';          Version='';    Status='?'}
    [PSCustomObject]@{No=29; Software='Data Simulasi 2012';        Source='GDrive';          Version='';    Status='OK'}
)


$table | Format-Table -AutoSize # print table


Write-Host "Choose number based on the table: " -NoNewline -ForegroundColor Yellow
$choose = Read-Host

switch ($choose) {
    1 { 
        gdown --fuzzy "https://drive.google.com/file/d/13NuhwjDLhPBAQeGZDC90PA3HT2_wdXk8/view?usp=sharing" # ACL 9.rar
        if ($winrarInstalled) {
            mkdir "ACL 9"
            & "${env:ProgramFiles}\WinRAR\UnRAR.exe" x "ACL 9.rar" ".\ACL 9\"
        } elseif ($7zipInstalled) {
            mkdir "ACL 9"
            & "${env:ProgramFiles}\7-Zip\7z.exe" x "ACL 9.rar" -o".\ACL 9\"
        } else {
            Write-Host "`nYou need to extract ACL 9.rar" -ForegroundColor Red
        }
    }
    2 {
        Write-Host "
        pw : www.yasir252.com
        Download Adobe Illustrator 2022 Full Version
        Extract the file with Winrar 6.1
        When finished, run the setup.exe file
        Press the install button and wait for it to finish
        Next, open the Crack Adobe Illustrator . folder
        Copy the .exe file
        Paste and replace at
        C:\Program Files\Adobe\Adobe Illustrator 2022\Support Files\Contents\Windows
        Enjoy brother!
        " -ForegroundColor Red
        
        gdown --fuzzy "https://drive.google.com/file/d/1iHbLr-PkXe2BfbnyQlzki7WJiEV7wsEm/view?usp=sharing" # AILS2265.rar
        if ($winrarInstalled) {
            mkdir "AILS2265"
            & "${env:ProgramFiles}\WinRAR\WinRAR.exe" x -p"www.yasir252.com" "AILS2265.rar" ".\AILS2265\"
        } elseif ($7zipInstalled) {
            mkdir "AILS2265"
            & "${env:ProgramFiles}\7-Zip\7z.exe" x -p"www.yasir252.com" "AILS2265.rar" -o".\AILS2265\"
        } else {
            Write-Host "`nYou need to extract AILS2265.rar" -ForegroundColor Red
        }
    } # adobe illustrator
    3 {
        Write-Host "
        1.) Install the Adobe Photoshop 2023 (use autoplay.exe).

        2.) Enjoy!

        Note: If you encounter any issues with a previous installation / crack,
        please uninstall Adobe Photoshop 2023 and delete those folders:

        C:\Program Files (x86)\Common Files\Adobe\SLCache
        C:\ProgramData\Adobe\SLStore" -ForegroundColor Red

        try {
            gdown --folder https://drive.google.com/drive/folders/1XV9ezecsbVu5FkpgW6NdxvkPzaThwDmU?usp=drive_link # probably doesn't work because of folders
        }
        catch {
            return
        }

        Write-Host "`nRemoving folder C:\Program Files (x86)\Common Files\Adobe\SLCache" -ForegroundColor Red
        Remove-Item -Recurse -Verbose -Force "C:\Program Files (x86)\Common Files\Adobe\SLCache"
        Write-Host "`nRemoving folder C:\Program Files (x86)\Common Files\Adobe\SLStore" -ForegroundColor Red
        Remove-Item -Recurse -Verbose -Force "C:\ProgramData\Adobe\SLStore" -ForegroundColor Red

    } # adobe photoshop
    4 { gdown --fuzzy "" } # adobe premier
    5 { WingetInstallCommand "Google.AndroidStudio" "winget" } # android studio
    6 { Write-Host "I don't know how to do this one." } # autocad
    7 { WingetInstallCommand "Balsamiq.Wireframes" "winget" } # balsamiq
    8 { WingetInstallCommand "XP9KN75RRB9NHS" "msstore" } # capcut
    9 { 
        gdown --fuzzy "https://drive.google.com/file/d/1I6iz-uzUFr4FrwAOfx1sYqj6U_GUwqI0/view?usp=sharing"

        if ($winrarInstalled) {
            & "${env:ProgramFiles}\WinRAR\WinRAR.exe" x "Circuit Wizard Student Version.zip" ".\"
        } elseif ($7zipInstalled) {
            & "${env:ProgramFiles}\7-Zip\7z.exe" x "Circuit Wizard Student Version.zip" -o".\"
        } else {
            Write-Host "`nYou need to extract Circuit Wizard Student Version.zip" -ForegroundColor Red
            return
        }

        Set-Location "Circuit Wizard Student Version"

        # Get Start Menu directory (current user)
        $startMenuPath = [Environment]::GetFolderPath("Programs")

        # Create shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$startMenuPath\Circuit Wizard.lnk")
        $shortcut.TargetPath = "$env:USERPROFILE\Downloads\Circuit Wizard Student Version\CktWiz.exe"
        $shortcut.WorkingDirectory = Split-Path "$env:USERPROFILE\Downloads\Circuit Wizard Student Version\CktWiz.exe"
        $shortcut.Save()

        Write-Host "`nStart Menu shortcut created: $startMenuPath\Circuit Wizard.lnk" -ForegroundColor Yellow

        .\CktWiz.exe
    } # circuit wizard
    10 { gdown --fuzzy "" } # coreldraw
    11 {  } # cx programming
    12 { Write-Host "https://draw.io atau winget install JGraph.Draw" }
    13 { WingetInstallCommand "Figma.Figma" "winget" } # figma
    14 { WingetInstallCommand "9NBLGGH4LVX9" "msstore" } # fluid ui
    15 { WingetInstallCommand "Oracle".JavaRuntimeEnvironment "winget" } # java
    16 { WingetInstallCommand "Oracle".JDK.20 "winget" } # jdk
    17 { 
        Invoke-WebRequest -Uri "https://www.pajak.net/download/inv03_300.exe" -OutFile "krishand-inventory-3.0.exe"
        
        Write-Host "Username: Admin" -ForegroundColor Red
        Write-host "Password: krishand" -ForegroundColor Red
        Write-Host "`nNanti biasanya minta username & password saat login."

        .\krishand-inventory-3.0.exe
     } # krishand inventory 3.0
    18 { 
        gdown --fuzzy "https://drive.google.com/file/d/1wNvika8X7ft6KScOrzLvrAXX4t9K73Lx/view?usp=drive_link"; # f4-minitab17-setup.exe | minitab+
        Write-Host "`nmasukkan serial key dibawah ini, ketika diminta saat proses install `n`nKOPI-DVDD-OTCO-MOKE" -ForegroundColor Red
        .\f4-minitab17-setup.exe
    }
    19 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (excel)
    20 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (word)
    21 {
        gdown --fuzzy ""

    } # visio
    22 { WingetInstallCommand "Microsoft.VisualStudioCode" "winget" } # vscode
    23 { WingetInstallCommand "PHP.PHP.8.4" "winget" } # php
    24 { 
        Invoke-WebRequest -Uri "https://qm-for-windows.software.informer.com/download/?ca1e2f92" -OutFile POM-QM.exe

        .\POM-QM.exe
    } # POM QM
    25 { 
        gdown --fuzzy https://drive.google.com/file/d/1b1Lx46x-JtDfWpaXq5LFlTZ-pTsPMjpY/view?usp=drive_link

        gdown --fuzzy https://drive.google.com/file/d/10j7mG_WODqRlFrygwqUEITIccYyi-ET5/view?usp=drive_link

        Move-Item .\lservrc -Destination "C:\Program Files\IBM\SPSS\Statistics\25\" -Force 

        .\SPSS_Statistics_25.exe
    } # SPSS
    26 { WingetInstallCommand "MKLabs.StarUML" "winget" } # star uml
    27 { WingetInstallCommand "ApacheFriends.Xampp.8.2" "winget" } # xampp
    28 { gdown --fuzzy "" } # zahir
    29 {
        gdown --fuzzy "https://drive.google.com/file/d/1PdGoSjSr5k2xVVCGgxnNuT7S31Crm8S9/view?usp=drive_link" # DATA-SIMULASI 2012.rar
        if ($winrarInstalled) { # if winrar is installed
            mkdir "DATA-SIMULASI 2012"
            & "${env:ProgramFiles}\WinRAR\UnRAR.exe" x "DATA-SIMULASI 2012.rar" ".\DATA-SIMULASI 2012\"
        } elseif ($7zipInstalled) {
            mkdir "DATA-SIMULASI 2012"
            & "${env:ProgramFiles}\7-Zip\7z.exe" x "DATA-SIMULASI 2012.rar" -o".\DATA-SIMULASI 2012\"
        } else {
            Write-Host "`nYou need to extract DATA-SIMULASI 2012.rar" -ForegroundColor Red
        }
    }
    Default { Write-Host "`nWrong option try again." -ForegroundColor Red }
}



