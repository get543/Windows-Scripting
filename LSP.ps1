<#
.COMPONENT
python
gdown
winrar or 7zip

.DESCRIPTION
Install LSP Software, if WinRar is installed, it will autmatically extract .rar file downloaded from GDrive
GDown is needed to download files from GDrive and can be installed with pip install gdown
which you will need python to be installed on your system. The script will aumatically do all of this automatically
7Zip or winrar is also needed to extract files (if not installed, you'll have to do that manually.)


.PARAMETER autoinstall
It will autoinstall or upgrade all apps that can be downloaded using winget

.PARAMETER activation
It will activate windows and office

.PARAMETER activation <string>
Accepted <string> value : 
- windows
- office


.EXAMPLE
.\LSP.ps1 -autoinstall

.EXAMPLE
.\LSP.ps1 -activation office

.EXAMPLE
& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -autoinstall

.EXAMPLE
irm bit.ly/scriptLSP | iex


.NOTES
0. Open PowerShell as Admin
1. Allow PowerShell scripts to run only in the current terminal session: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
2. Run this: irm https://raw.githubusercontent.com/get543/Windows-Scripting/refs/heads/main/LSP.ps1 | iex

.NOTES
PowerShell One-Liner

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -autoinstall
& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -activation
#>


#TODO CHECK IF WINGET APPS (JAVA, VSCODE, ETC) IS INSTALLED OR NOT | ✅ AUTOINSTALL ❌ NORMAL SCRIPT
#TODO AUTOINSTALL CRACK SOFTWARE FROM GDRIVE OR WEB
#TODO WHAT IF PC'S INTERNET IS SLOW ⁉ CURRENTLY NO SOLUTION

param (
    [switch]$autoinstall,
    [string]$activation
)

if (!$isAdmin) { return Write-Host "`nMust Be Run As Admin!" -ForegroundColor Red }

Set-Location "~\Downloads"

if (Test-Path "${env:ProgramFiles}\WinRAR\UnRAR.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`nWinRAR is installed, will be using it to extract .rar files`n" -ForegroundColor Yellow
    $winrarInstalled = $true
} elseif (Test-Path "${env:ProgramFiles}\7-Zip\7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`n7-Zip is installed, will be using it to extract .rar files`n" -ForegroundColor Yellow
    $7zipInstalled = $true
}


#! ========================== FUNCTIONS ################################
function WingetInstall {
    <#
    .SYNOPSIS
    Installs winget using powershell module.
    This code is official from microsoft's website.
    #>

    $progressPreference = "SilentlyContinue"
    Write-Host "Installing WinGet PowerShell module from PSGallery..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." -ForegroundColor Yellow
    Repair-WinGetPackageManager -AllUsers -ErrorAction SilentlyContinue

    # CRITICAL: Refresh PATH immediately after install
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

    Write-Host "Done."
}

function UnZip($SourceFile, $DestinationFile) {
    <#
    .PARAMETER SourceFile
    Source file

    .PARAMETER DestinationFile
    Destination file
    #>
    if ($winrarInstalled) {
        & "${env:ProgramFiles}\WinRAR\WinRAR.exe" -o+ x "$SourceFile" "$DestinationFile"
    } elseif ($7zipInstalled) {
        & "${env:ProgramFiles}\7-Zip\7z.exe" x "$SourceFile" -o"$DestinationFile"
    } else {
        Write-Host "`nYou need to extract $SourceFile" -ForegroundColor Red
        return
    }
}

function RefreshPath() {
    <#
    .SYNOPSIS
    Refreshes the PATH environment variable in the current session.
    #>
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

function WingetInstallCommand($name, $source, $id, $patern) {
    <#
    .PARAMETER name
    The name or the Id of the app you want to install
    
    .PARAMETER source
    winget or msstore

    .PARAMETER id
    The base id to search for latest version. Example: PHP.PHP

    .PARAMETER patern
    The pattern to match the latest version. Example: PHP\.PHP\.\d+\.\d+ (for PHP.PHP.x.x)
    #>

    if ($id -and $patern) {
        $name = (winget search "$id" --source winget |
            Select-String -Pattern $patern |
            ForEach-Object { $_.Matches.Value } |
            Sort-Object |
            Select-Object -Last 1)
    }

    winget install $name --accept-package-agreements --accept-source-agreements --source $source
}

function CreateShortcutStartMenu($SourceFile, $ShortcutName) {
    <#
    .DESCRIPTION
    create shortcut to the start menu (user)

    .PARAMETER SourceFile
    The target file usually in .exe (something.exe)

    .PARAMETER ShortcutName
    The name of the shorcut created with .lnk extension (something.lnk)
    #>

    # Get Start Menu directory (current user)
    $startMenuPath = [Environment]::GetFolderPath("Programs")

    # Create shortcut
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$startMenuPath\$ShortcutName")
    $shortcut.TargetPath = "$SourceFile"
    $shortcut.WorkingDirectory = Split-Path "$SourceFile"
    $shortcut.Save()

    Write-Host "`nStart Menu shortcut created: $startMenuPath\$ShortcutName" -ForegroundColor Yellow
    
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
    # CHECK IF WINRAR OR 7ZIP IS INSTALLED
    if (!$winrarInstalled) {
        if (!$7zipInstalled) {
            Write-Host "`nWinRAR or 7-Zip is not installed but continuing anyway..." -ForegroundColor Yellow 
        }
    }

    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "`nWinget is not installed!" -ForegroundColor Red
        WingetInstall
    }

    # CRITICAL: Refresh PATH immediately after install
    RefreshPath

    #################### USING WINGET ####################
    $appArray = @("android-studio", "balsamiq", "capcut", "figma", "fluid ui", "jre", "vscode", "staruml", "php")
    
    foreach ($app in $appArray) {
        if (winget list $app -eq "No installed package found matching input criteria.") {
            if ($app -eq "jre") {
                WingetInstallCommand "Oracle.JavaRuntimeEnvironment" "winget"
                WingetInstallCommand "Oracle.JDK.25" "winget" "Oracle.JDK" "Oracle\.JDK\.\d+"

            } elseif ($app -eq "php") {
                WingetInstallCommand "PHP.PHP.8.5" "winget" "PHP.PHP" "PHP\.PHP\.\d+\.\d+"
                WingetInstallCommand "ApacheFriends.Xampp.8.2" "winget" "ApacheFriends.Xampp" "ApacheFriends\.Xampp\.\d+\.\d+"
                
            } elseif ($app -eq "capcut") {
                WingetInstallCommand "XP9KN75RRB9NHS" "msstore"
                
            } else {
                WingetInstallCommand $app ""
            }
        } else {
            Write-Host "`nIt seems like a version of $app is already installed, skiping this step..." -ForegroundColor Red
        }
    }
    
    if (!(Get-Command gdown -ErrorAction SilentlyContinue)) {
        if (!(Get-Command pip -ErrorAction SilentlyContinue)) {
            Write-Host "`nInstalling Latest Python3 Version`n" -ForegroundColor Yellow
            WingetInstallCommand "python3" "winget"
        }

        # CRITICAL: Refresh PATH immediately after install
        RefreshPath

        pip install gdown
    }

    Write-Host "`nOk so you've reached the end of the script" -ForegroundColor Red
    return
}


#! ===================================================================
#!                          NORMAL EXECUTION
#! ===================================================================
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "`nWinget is not installed!" -ForegroundColor Red
    WingetInstall
}

if (!(Get-Command gdown -ErrorAction SilentlyContinue)) {
    Write-Host "`ngdown is not installed!" -ForegroundColor Red
    Write-Host "Run pip install gdown ? [Y/n] " -ForegroundColor Yellow -NoNewline
    $installGdown = Read-Host
    if (($installGdown.Tolower() -eq "y") -or ($installGdown -eq "")) {
        if (!(Get-Command pip -ErrorAction SilentlyContinue) -or !(Get-Command python -ErrorAction SilentlyContinue)) {
            WingetInstallCommand "python3" "winget"
        }

        # CRITICAL: Refresh PATH immediately after install
        RefreshPath

        try {
            pip install gdown
        }
        catch {
            return Write-Host "`nOops, something's wrong. Maybe python or pip is not properly configured." -ForegroundColor Red
        }
    }
}

# https://ozh.github.io/ascii-tables/
<# !NOT NEEDED
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
| 17 | Krishand Inventory 3.0       |                 |         |        |
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
#>

##################################### !CUSTOM TABLE OBJECT #####################################
$table = @(
    [PSCustomObject]@{No=1;  Software='ACL 9';                        Source='GDrive';          Version='-';         Status='OK'}
    [PSCustomObject]@{No=2;  Software='Adobe Illustrator';            Source='GDrive';          Version='2023';      Status='Untested'}
    [PSCustomObject]@{No=3;  Software='Adobe Photoshop';              Source='GDrive';          Version='2023';      Status='Untested'}
    [PSCustomObject]@{No=4;  Software='Adobe Premier';                Source='GDrive';          Version='2023';      Status='Not Done'}
    [PSCustomObject]@{No=5;  Software='Android Studio';               Source='winget';          Version='newest';    Status='OK'}
    [PSCustomObject]@{No=6;  Software='AutoCad';                      Source='GDrive';          Version='-';         Status='Not Done'}
    [PSCustomObject]@{No=7;  Software='Balsamiq';                     Source='winget';          Version='newest';    Status='OK'}
    [PSCustomObject]@{No=8;  Software='CapCut';                       Source='MS Store';        Version='newest';    Status='OK'}
    [PSCustomObject]@{No=9;  Software='Circuit Wizard';               Source='GDrive';          Version='2.0';       Status='OK'}
    [PSCustomObject]@{No=10; Software='CorelDraw';                    Source='GDrive';          Version='X8';        Status='Not Done'}
    [PSCustomObject]@{No=11; Software='CX Programming';               Source='GDrive';          Version='4.60';      Status='OK'}
    [PSCustomObject]@{No=12; Software='Draw.io';                      Source='https://draw.io'; Version='-';         Status='OK'}
    [PSCustomObject]@{No=13; Software='Figma';                        Source='winget';          Version='newest';    Status='OK'}
    [PSCustomObject]@{No=14; Software='Fluid UI';                     Source='MS Store';        Version='newest';    Status='OK'}
    [PSCustomObject]@{No=15; Software='FluidSIM';                     Source='GDrive';          Version='4,2';       Status='OK'}
    [PSCustomObject]@{No=16; Software='Java';                         Source='winget';          Version='8';         Status='OK'}
    [PSCustomObject]@{No=17; Software='JDK';                          Source='winget';          Version='> 20';      Status='OK'}
    [PSCustomObject]@{No=18; Software='Krishand Inventory 3.0';       Source='Web Link';             Version='3.0';       Status='OK'}
    [PSCustomObject]@{No=19; Software='Minitab';                      Source='GDrive';          Version='17';        Status='OK'}
    [PSCustomObject]@{No=20; Software='Microsot Excel';               Source='MAS (github)';    Version='-';         Status='OK'}
    [PSCustomObject]@{No=21; Software='Microsoft Word';               Source='MAS (github)';    Version='-';         Status='OK'}
    [PSCustomObject]@{No=22; Software='Microsoft Visio';              Source='GDrive';          Version='2024';      Status='OK'}
    [PSCustomObject]@{No=23; Software='Microsoft Visual Studio Code'; Source='winget';          Version='newest';    Status='OK'}
    [PSCustomObject]@{No=24; Software='PHP';                          Source='winget';          Version='> 8.5';     Status='OK'}
    [PSCustomObject]@{No=25; Software='POM QM';                       Source='Web Link';        Version='Windows 5'; Status='OK'}
    [PSCustomObject]@{No=26; Software='SPSS';                         Source='Web Link';        Version='25';        Status='OK'}
    [PSCustomObject]@{No=27; Software='Star UML';                     Source='winget';          Version='newest';    Status='OK'}
    [PSCustomObject]@{No=28; Software='XAMPP';                        Source='winget';          Version='> 8.2';     Status='OK'}
    [PSCustomObject]@{No=29; Software='Zahir';                        Source='GDrive';          Version='6';         Status='OK'}
    [PSCustomObject]@{No=30; Software='Data Simulasi 2012';           Source='GDrive';          Version='-';         Status='OK'}
)


$table | Format-Table -AutoSize # print table


Write-Host "Choose number based on the table: " -NoNewline -ForegroundColor Yellow
$choose = Read-Host


switch ($choose) {
    1 {
        if (Test-Path "ACL 9.rar") {
            Write-Host "`nACL 9 folder already exists, continuing anyway..." -ForegroundColor Red
        }

        gdown --fuzzy "https://drive.google.com/file/d/13NuhwjDLhPBAQeGZDC90PA3HT2_wdXk8/view?usp=sharing" # ACL 9.rar

        UnZip "ACL 9.rar" ".\ACL 9\"

        Write-Host "`nDone." -ForegroundColor Yellow
    } # ACL 9.rar
    2 { #! BLM DI COBA
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
            return
        }

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "~\Downloads\AILS2265\Adobe.Illustrator.2022.v26.5.0.223.x64\Setup\"
        .\Set-up.exe

        Write-Host "Press Enter ONLY IF THE INSTALATION IS FINISHED! " -BackgroundColor Red; Read-Host

        Set-Location "~\Downloads\AILS2265\Crack Only\"
        Copy-Item "Illustrator.exe" -Destination "$env:ProgramFiles\Adobe\Adobe Illustrator 2022\Support Files\Contents\Windows" -Force -Recurse
    } # adobe illustrator
    3 { #! BLM DI COBA
        gdown --fuzzy "https://drive.google.com/file/d/1YTyJnngcHi9abbbY-5RdOloVJ89o_Kdn/view?usp=sharing"
       
        # Delete previous instalation folder
        if ((Test-Path "${env:\CommonProgramFiles(x86)}\Adobe\SLCache") -or (Test-Path "$env:ProgramData\Adobe\SLStore")) {
            Remove-Item -Recurse -Force "${env:\CommonProgramFiles(x86)}\Adobe\SLCache"
            Remove-Item -Recurse -Force "$env:ProgramData\Adobe\SLStore"
        }

        if ($winrarInstalled) {
            & "${env:ProgramFiles}\WinRAR\WinRAR.exe" x -p"123" "_Getintopc.com_Adobe_Photoshop_2023_v24.2.0.315.rar" ".\"
        } elseif ($7zipInstalled) {
            & "${env:ProgramFiles}\7-Zip\7z.exe" x -p"123" "_Getintopc.com_Adobe_Photoshop_2023_v24.2.0.315.rar" -o".\"
        } else {
            Write-Host "`nYou need to extract _Getintopc.com_Adobe_Photoshop_2023_v24.2.0.315.rar" -ForegroundColor Red
            return
        }

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "Adobe_Photoshop_2023_v24.2.0.315"
        .\autoplay.exe

    } # adobe photoshop
    4 { Write-Host "`nI don't know how to do this one." } # adobe premier
    5 { WingetInstallCommand "Google.AndroidStudio" "winget" } # android studio
    6 { Write-Host "`nI don't know how to do this one." } #? autocad https://drive.google.com/drive/u/4/folders/1jR6n1IuMZ6QUIO_xu5nm3JzqEYagBwNG
    7 { WingetInstallCommand "Balsamiq.Wireframes" "winget" } # balsamiq
    8 { WingetInstallCommand "XP9KN75RRB9NHS" "msstore" } # capcut
    9 { 
        gdown --fuzzy "https://drive.google.com/file/d/1I6iz-uzUFr4FrwAOfx1sYqj6U_GUwqI0/view?usp=sharing"

        UnZip "Circuit Wizard Student Version.zip" ".\"

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "Circuit Wizard Student Version"

        CreateShortcutStartMenu "$env:USERPROFILE\Downloads\Circuit Wizard Student Version\CktWiz.exe" "Circuit Wizard.lnk"

        .\CktWiz.exe
    } # circuit wizard
    10 { #! MASIH GA BISA
        gdown --fuzzy "https://drive.google.com/file/d/1_2AOYgETZlChXHvhNrlYqHM5dVNq9jui/view?usp=drive_link"
        
        UnZip "CorelDRAW Graphics Suite 2021 v23.0.0.363.7z" ".\"

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "CorelDRAW Graphics Suite 2021 v23.0.0.363\Setup"
        
        .\Setup.exe

        Write-Host "
        Instructions :

        1. Install the program from the given setup.
        2. Install the application as trial.
        3. Don't run the application yet and close from system tray or task manager if running.
        4. Extract the `"Crack Fix.zip`" to C:\Program Files\Corel\CorelDRAW Graphics Suite 2021\Programs64. Replace all the files.
        5. Boom! Now you can use the program without any interruptions.
        6. That's it, Enjoy now ;)
        " -ForegroundColor Red

        Write-Host "`nPress Enter ONLY IF THE INSTALATION IS FINISHED! " -BackgroundColor Red; Read-Host

        Write-Host "`nCopying crack files..." -ForegroundColor Yellow
        Copy-Item "..\Crack Fix\*" -Destination "${env:ProgramFiles}\Corel\CorelDRAW Graphics Suite 2021\Programs64" -Force -Recurse -Verbose


    } # coreldraw
    11 {
        gdown --fuzzy "https://drive.google.com/file/d/1yCXn0j8c6EqvI4eKElYWNluau7w8oY46/view?usp=sharing"
        if ($winrarInstalled) {
            mkdir "CX Programmer"
            & "${env:ProgramFiles}\WinRAR\WinRAR.exe" x -p"plc247.com" "[plc247.com]CxOne_V4.60.rar" ".\CX Programmer\"
        } elseif ($7zipInstalled) {
            mkdir "CX Programmer"
            & "${env:ProgramFiles}\7-Zip\7z.exe" x -p"plc247.com" "[plc247.com]CxOne_V4.60.rar" -o".\CX Programmer\"
        } else {
            Write-Host "`nYou need to extract [plc247.com]CxOne_V4.60.rar" -ForegroundColor Red
            return
        }

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "CX Programmer\CxOne_V4.60\"
        .\setup.exe

        Write-Host "License key: 1600 0285 8143 5387 or 1600 0325 7848 5341" -ForegroundColor Red
    } # cx programming
    12 { Write-Host "https://draw.io atau winget install JGraph.Draw" }
    13 { WingetInstallCommand "Figma.Figma" "winget" } # figma
    14 { WingetInstallCommand "9NBLGGH4LVX9" "msstore" } # fluid ui
    15 {
        gdown --fuzzy "https://drive.google.com/file/d/1wFrPVIX1UHx7tS8ra4PPiDQSqoc0l0Lb/view?usp=drive_link"
        
        UnZip "festo fluidsim 4.2 PH-20231010T134944Z-001.rar" ".\"

        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Hydraulic\bin\"

        CreateShortcutStartMenu "festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Hydraulic\bin\fl_sim_h.exe" "FluidSim Hydraulic.lnk" # Hydraulic
        CreateShortcutStartMenu "festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Pneumatic\bin\fl_sim_p.exe" "FluidSim Pneumatic.lnk" # Pneumatic

        .\fl_sim_h.exe

    } # FluidSim
    16 { WingetInstallCommand "Oracle.JavaRuntimeEnvironment" "winget" } # java
    17 { WingetInstallCommand "Oracle.JDK.25" "winget" "Oracle.JDK" "Oracle\.JDK\.\d+" } # jdk
    18 { 
        Invoke-WebRequest -Uri "https://www.pajak.net/download/inv03_300.exe" -OutFile "krishand-inventory-3.0.exe"
        
        Write-Host "Username: Admin" -ForegroundColor Red
        Write-host "Password: krishand" -ForegroundColor Red
        Write-Host "`nNanti biasanya minta username & password saat login."

        .\krishand-inventory-3.0.exe
    } # krishand inventory 3.0
    19 { 
        gdown --fuzzy "https://drive.google.com/file/d/1wNvika8X7ft6KScOrzLvrAXX4t9K73Lx/view?usp=drive_link";
        Write-Host "`nmasukkan serial key dibawah ini, ketika diminta saat proses install `n`nKOPI-DVDD-OTCO-MOKE" -ForegroundColor Red
        .\f4-minitab17-setup.exe
    } # minitab+
    20 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (excel)
    21 { Invoke-RestMethod https://get.activated.win | Invoke-Expression } # https://massgrave.dev/ (word)
    22 {
        gdown --fuzzy "https://drive.google.com/file/d/1iIj9FWs0kB4ZD6obIKaU6SQkjekVO8ye/view?usp=sharing"

        UnZip "VISIO2024.zip" ".\"
        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "VISIO2024"
        .\setup.exe /configure Configuration.xml
    } # visio
    23 { WingetInstallCommand "Microsoft.VisualStudioCode" "winget" } # vscode
    24 { WingetInstallCommand "PHP.PHP.8.5" "winget" "PHP.PHP" "PHP\.PHP\.\d+\.\d+" } # php
    25 { 
        Invoke-WebRequest -Uri "https://qm-for-windows.software.informer.com/download/?ca1e2f92" -OutFile POM-QM.exe

        .\POM-QM.exe
    } # POM QM
    26 { 
        gdown --fuzzy https://drive.google.com/file/d/1b1Lx46x-JtDfWpaXq5LFlTZ-pTsPMjpY/view?usp=drive_link # .exe
        gdown --fuzzy https://drive.google.com/file/d/10j7mG_WODqRlFrygwqUEITIccYyi-ET5/view?usp=drive_link # lservrc

        Move-Item .\lservrc -Destination "${env:ProgramFiles}\IBM\SPSS\Statistics\25\" -Force 

        .\SPSS_Statistics_25.exe
    } # SPSS
    27 { WingetInstallCommand "MKLabs.StarUML" "winget" } # star uml
    28 { WingetInstallCommand "ApacheFriends.Xampp.8.2" "winget" "ApacheFriends.Xampp" "ApacheFriends\.Xampp\.\d+\.\d+" } # xampp
    29 {
        gdown --fuzzy "https://drive.google.com/file/d/1VhZ58l_tA7dpDFmOxocHMjPUt8Gqn8_P/view?usp=sharing"

        UnZip "Master ZAHIR 6.11a.zip" ".\"
        Write-Host "`nPress Enter ONLY IF IT'S DONE EXTRACTING.." -NoNewline -BackgroundColor Red; Read-Host

        Set-Location "Master ZAHIR 6.11a"
        .\setup.exe
    } # zahir
    30 {
        if (Test-Path ".\DATA-SIMULASI 2012\") {
            Write-Host "`nDATA-SIMULASI 2012 folder already exists, continuing anyway..." -ForegroundColor Red
        }

        gdown --fuzzy "https://drive.google.com/file/d/1PdGoSjSr5k2xVVCGgxnNuT7S31Crm8S9/view?usp=drive_link" # DATA-SIMULASI 2012.rar

        mkdir "DATA-SIMULASI 2012"
        UnZip "DATA-SIMULASI 2012.rar" ".\DATA-SIMULASI 2012"

        Write-Host "`nDone." -ForegroundColor Yellow
    } # Data-Simulasi 2012
    Default { Write-Host "`nWrong option try again." -ForegroundColor Red }
}

# CRITICAL: Refresh PATH immediately after install
RefreshPath
