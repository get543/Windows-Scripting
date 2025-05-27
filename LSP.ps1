<#
.COMPONENT
gdown
winrar or 7zip

.DESCRIPTION
Install LSP Software, if WinRar is installed, it will autmatically extract .rar file downloaded from GDrive

.NOTES
0. Open PowerShell as Admin
1. Allow PowerShell scripts to run only in the current terminal session: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
2. Run this: Invoke-RestMethod https://raw.githubusercontent.com/get543/Windows-Scripting/refs/heads/main/LSP.ps1 | Invoke-Expression
#>


if ((Get-Command gdown)) {
    Write-Host "gdown is not installed!" -ForegroundColor Red
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

if (Get-Command winget) {
    Write-Host "Updating winget source..." -ForegroundColor Yellow
    winget upgrade
}

if (Test-Path "${env:ProgramFiles}\WinRAR") {
    Write-Host "WinRAR is installed, will be using it to extract .rar files" -ForegroundColor Yellow
    $winrarInstalled = $true
}


# https://ozh.github.io/ascii-tables/
Write-Host "
+----+------------------------------+-----------------+---------+--------+
| No |           Software           |     Source      | Version | Status |
+----+------------------------------+-----------------+---------+--------+
|  1 | ACL 9                        | GDrive          |         | OK     |
|  2 | Adobe Illustrator            | GDrive          |         | ?      |
|  3 | Adobe Photoshop              | GDrive          |         | ?      |
|  4 | Adobe Premier                | GDrive          |         | ?      |
|  5 | Android Studio               | winget          |         | OK     |
|  6 | AutoCad                      |                 |         |        |
|  7 | Balsamiq                     | winget          |         | OK     |
|  8 | CapCut                       | winget          |         | OK     |
|  9 | Circuit Wizard               |                 |         |        |
| 10 | CorelDraw                    | GDrive          |         | ?      |
| 11 | CX Programming               |                 |         |        |
| 12 | Draw.io                      | https://draw.io |         | OK     |
| 13 | Figma                        | winget          |         | OK     |
| 14 | Fluid UI                     | winget          |         | OK     |
| 15 | Java                         | winget          |       8 | OK     |
| 16 | JDK                          | winget          |      20 | OK     |
| 17 | Krishand Inventory           |                 |         |        |
| 18 | Minitab                      | GDrive          |         | OK     |
| 19 | Microsot Excel               | MAS (github)    |         | OK     |
| 20 | Microsoft Word               | MAS (github)    |         | OK     |
| 21 | Microsoft Visio              |                 |         |        |
| 22 | Microsoft Visual Studio Code | winget          |         | OK     |
| 23 | PHP                          | winget          |     8.4 | OK     |
| 24 | POM QM                       |                 |         |        |
| 25 | SPSS                         |                 |         |        |
| 26 | Star UML                     | winget          |         | OK     |
| 27 | XAMPP                        | winget          |     8.2 | OK     |
| 28 | Zahir                        | GDrive          |         | ?      |
| 29 | Data Simulasi 2012           | GDrive          |         | OK     |
+----+------------------------------+-----------------+---------+--------+
"

Write-Host "Choose number based on the table: " -NoNewline -ForegroundColor Yellow
$choose = Read-Host

switch ($choose) {
    1 { 
        gdown --fuzzy "https://drive.google.com/file/d/13NuhwjDLhPBAQeGZDC90PA3HT2_wdXk8/view?usp=sharing" # ACL 9.rar
        if ($winrarInstalled) { # if winrar is installed
            mkdir "ACL 9"
            & "${env:ProgramFiles}\WinRAR\UnRAR.exe" x "ACL 9.rar" ".\ACL 9\"
        }
        Write-Host "`nYou need to extract ACL 9.rar" -ForegroundColor Red
    }
    2 { gdown --fuzzy "" } # adobe illustrator
    3 { gdown --fuzzy "" } # adobe photoshop
    4 { gdown --fuzzy "" } # adobe premier
    5 { winget install Google.AndroidStudio } # android studio
    6 {  }
    7 { winget install Balsamiq.Wireframes } # balsamiq
    8 { winget install XP9KN75RRB9NHS } # capcut
    9 {  }
    10 { gdown --fuzzy "" } # coreldraw
    11 {  }
    12 { Write-Host "https://draw.io atau winget install  JGraph.Draw" }
    13 { winget install Figma.Figma } # figma
    14 { winget install 9NBLGGH4LVX9 } # fluid ui
    15 { winget install Oracle.JavaRuntimeEnvironment } # java
    16 { winget install Oracle.JDK.20 } # jdk
    17 {  }
    18 { 
        gdown --fuzzy "https://drive.google.com/file/d/1wNvika8X7ft6KScOrzLvrAXX4t9K73Lx/view?usp=drive_link"; # f4-minitab17-setup.exe | minitab+
        Write-Host "masukkan serial key dibawah ini, ketika diminta saat proses install `n`nKOPI-DVDD-OTCO-MOKE" -ForegroundColor Red
        .\f4-minitab17-setup.exe
    }
    19 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (excel)
    20 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (word)
    21 {  }
    22 { winget install Microsoft.VisualStudioCode } # vscode
    23 { winget install PHP.PHP.8.4 } # php
    24 {  }
    25 {  }
    26 { winget install MKLabs.StarUML } # star uml
    27 { winget install ApacheFriends.Xampp.8.2 } # xampp
    28 { gdown --fuzzy "" } # zahir
    29 {
        gdown --fuzzy "https://drive.google.com/file/d/1PdGoSjSr5k2xVVCGgxnNuT7S31Crm8S9/view?usp=drive_link" # DATA-SIMULASI 2012.rar
        if ($winrarInstalled) { # if winrar is installed
            mkdir "DATA-SIMULASI 2012"
            & "${env:ProgramFiles}\WinRAR\UnRAR.exe" x "DATA-SIMULASI 2012.rar" ".\DATA-SIMULASI 2012\"
        }
        Write-Host "`nYou need to extract DATA-SIMULASI 2012.rar" -ForegroundColor Red
    }
    Default { Write-Host "`nWrong option try again." -ForegroundColor Red }
}



