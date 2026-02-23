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
- all

.EXAMPLE
.\LSP.ps1

.\LSP.ps1 -autoinstall

.\LSP.ps1 -activation windows

.\LSP.ps1 -activation office

.\LSP.ps1 -activation all

.EXAMPLE
& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP)))

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -autoinstall

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -activation windows

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -activation office

& ([ScriptBlock]::Create((irm https://bit.ly/scriptLSP))) -activation all

.EXAMPLE
irm bit.ly/scriptLSP | iex

irm https://bit.ly/scriptLSP | iex

irm https://raw.githubusercontent.com/get543/Windows-Scripting/refs/heads/main/LSP.ps1 | iex


.NOTES
0. Open PowerShell as Admin
1. Allow PowerShell scripts to run only in the current terminal session: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
2. Run this: irm bit.ly/scriptLSP | iex

.NOTES
1. You need to run PowerShell as Admin
2. You need gdown installed (pip install gdown), which needs python installed (the script will autoinstall python if not found)
3. You need WinRar or 7Zip installed to extract .rar files automatically
4. You need winget installed (the script will autoinstall it if not found)
#>

#TODO CHECK IF WINGET APPS (JAVA, VSCODE, ETC) IS INSTALLED OR NOT | ✅ AUTOINSTALL ❌ NORMAL SCRIPT
#TODO AUTOINSTALL CRACK SOFTWARE FROM GDRIVE OR WEB
#TODO WHAT IF PC'S INTERNET IS SLOW ⁉ CURRENTLY THERE'S NO SOLUTION

param (
    [switch]$autoinstall,
    [string]$activation
)

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal $Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$IsAdmin) { return Write-Host "`nMUST RUN AS ADMIN!" -ForegroundColor Red }

Write-Host "`nChange path to ${env:USERPROFILE}\Downloads" -ForegroundColor Yellow
Set-Location "${env:USERPROFILE}\Downloads"

if (Test-Path "${env:ProgramFiles}\WinRAR\UnRAR.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`nWinRAR is installed, will be using it to extract .rar files`n" -ForegroundColor Yellow
    $winrarInstalled = $true
} elseif (Test-Path "${env:ProgramFiles}\7-Zip\7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "`n7-Zip is installed, will be using it to extract .rar files`n" -ForegroundColor Yellow
    $7zipInstalled = $true
}


#! ========================== FUNCTIONS ################################
function WingetInstall() {
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

function UnZip($SourceFile, $DestinationFile, $Passwd) {
    <#
    .PARAMETER SourceFile
    Source file

    .PARAMETER DestinationFile
    Destination file

    .PARAMETER Passwd
    Password to extract the file (if any)
    #>
    if ($winrarInstalled) {
        Write-Host "`nExtracting $SourceFile to $DestinationFile using WinRAR...`n" -ForegroundColor Yellow
        if ($Passwd) {
            Start-Process -FilePath "${env:ProgramFiles}\WinRAR\WinRAR.exe" -ArgumentList "-o+", "x", "-p`"$Passwd`"", "`"$SourceFile`"", "`"$DestinationFile`"" -Wait -NoNewWindow
        } else {
            Start-Process -FilePath "${env:ProgramFiles}\WinRAR\WinRAR.exe" -ArgumentList "-o+", "x", "`"$SourceFile`"", "`"$DestinationFile`"" -Wait -NoNewWindow
        }
    } elseif ($7zipInstalled) {
        Write-Host "`nExtracting $SourceFile to $DestinationFile using 7-Zip...`n" -ForegroundColor Yellow
        if ($Passwd) {
            Start-Process -FilePath "${env:ProgramFiles}\7-Zip\7z.exe" -ArgumentList "x", "-p`"$Passwd`"", "`"$SourceFile`"", "-o`"$DestinationFile`"", "-aoa" -Wait -NoNewWindow
        } else {
            Start-Process -FilePath "${env:ProgramFiles}\7-Zip\7z.exe" -ArgumentList "x", "`"$SourceFile`"", "-o`"$DestinationFile`"", "-aoa" -Wait -NoNewWindow
        }
    } else {
        Write-Host "`nYou need to extract $SourceFile" -ForegroundColor Red
        return
    }
}

function CopyFolder($SourceFile, $DestinationFile) {
    <#
    .PARAMETER SourceFile
    The source file to copy

    .PARAMETER DestinationFile
    The destination file to copy to
    #>
    if (!(Test-Path $SourceFile)) {
        return Write-Host "`nSource file $SourceFile not found!" -ForegroundColor Red
    }

    if (!(Test-Path $DestinationFile)) {
        return Write-Host "`nDestination file $DestinationFile not found!" -ForegroundColor Red
    }

    Copy-Item -Path $SourceFile -Destination $DestinationFile -Force -Recurse -Verbose
}

function RefreshPath() {
    <#
    .SYNOPSIS
    Refreshes the PATH environment variable in the current session.
    #>
    Write-Host "`nRefreshing PATH environment variable..." -ForegroundColor Yellow
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
    The target file usually in .exe (Exampe: something.exe)

    .PARAMETER ShortcutName
    The name of the shorcut created with .lnk extension (Example: something.lnk)
    #>

    if (!(Test-Path $SourceFile)) {
        return Write-Host "`nSource file $SourceFile not found, cannot create shortcut!" -ForegroundColor Red
    }

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
#####################! all #####################
if ($activation -eq "all") {
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
            Write-Host "`nInstalling the latest Python3...`n" -ForegroundColor Yellow
            WingetInstallCommand "python3" "winget"
        }

        # CRITICAL: Refresh PATH immediately after install
        RefreshPath

        Write-Host "`nInstalling gdown using pip...`n" -ForegroundColor Yellow
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
            Write-Host "`nInstalling gdown using pip..." -ForegroundColor Yellow
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
    [PSCustomObject]@{No=1;  Software='ACL 9';                        Source='GDrive';          Version='-';                    Status='OK'}
    [PSCustomObject]@{No=2;  Software='Adobe Illustrator';            Source='GDrive';          Version='2022';                 Status='OK'}
    [PSCustomObject]@{No=3;  Software='Adobe Photoshop';              Source='GDrive';          Version='2023';                 Status='OK'}
    [PSCustomObject]@{No=4;  Software='Adobe Premier';                Source='GDrive';          Version='2023';                 Status='OK'}
    [PSCustomObject]@{No=5;  Software='Android Studio';               Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=6;  Software='AutoCad';                      Source='GDrive';          Version='2023';                 Status='OK'}
    [PSCustomObject]@{No=7;  Software='Balsamiq';                     Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=8;  Software='CapCut';                       Source='MS Store';        Version='newest';               Status='OK'}
    [PSCustomObject]@{No=9;  Software='Circuit Wizard';               Source='GDrive';          Version='2.0';                  Status='OK'}
    [PSCustomObject]@{No=10; Software='CorelDraw';                    Source='GDrive';          Version='Suite 2021';           Status='OK'}
    [PSCustomObject]@{No=11; Software='CX Programming';               Source='GDrive';          Version='4.60';                 Status='OK'}
    [PSCustomObject]@{No=12; Software='Draw.io';                      Source='https://draw.io'; Version='-';                    Status='OK'}
    [PSCustomObject]@{No=13; Software='Figma';                        Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=14; Software='Fluid UI';                     Source='MS Store';        Version='newest';               Status='OK'}
    [PSCustomObject]@{No=15; Software='FluidSIM';                     Source='GDrive';          Version='4.2';                  Status='OK'}
    [PSCustomObject]@{No=16; Software='Java';                         Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=17; Software='JDK';                          Source='winget';          Version='> 25';                 Status='OK'}
    [PSCustomObject]@{No=18; Software='Krishand Inventory 3.0';       Source='Web Link';        Version='3.0';                  Status='OK'}
    [PSCustomObject]@{No=19; Software='Minitab';                      Source='GDrive';          Version='17';                   Status='OK'}
    [PSCustomObject]@{No=20; Software='Excel, PowerPoint, Word';      Source='MAS (github)';    Version='O365AppsBasicRetail';  Status='OK'}
    [PSCustomObject]@{No=21; Software='Microsoft Visio';              Source='GDrive';          Version='2024';                 Status='OK'}
    [PSCustomObject]@{No=22; Software='Microsoft Visual Studio Code'; Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=23; Software='PHP';                          Source='winget';          Version='> 8.5';                Status='OK'}
    [PSCustomObject]@{No=24; Software='POM QM';                       Source='Web Link';        Version='Windows 5';            Status='OK'}
    [PSCustomObject]@{No=25; Software='SPSS';                         Source='Web Link';        Version='25';                   Status='OK'}
    [PSCustomObject]@{No=26; Software='Star UML';                     Source='winget';          Version='newest';               Status='OK'}
    [PSCustomObject]@{No=27; Software='Tableau';                      Source='GDrive';          Version='2023';                 Status='OK'}
    [PSCustomObject]@{No=28; Software='XAMPP';                        Source='winget';          Version='> 8.2';                Status='OK'}
    [PSCustomObject]@{No=29; Software='Zahir';                        Source='GDrive';          Version='6';                    Status='OK'}
    [PSCustomObject]@{No=30; Software='Data Simulasi 2012';           Source='GDrive';          Version='-';                    Status='OK'}
    [PSCustomObject]@{No=31; Software='Block Adobe Unlicense';        Source='GDrive & Github'; Version='-';                    Status='OK'}
    [PSCustomObject]@{No=32; Software='Delete Leftover Files';        Source='-';               Version='-';                    Status='OK'}
)


$table | Format-Table -AutoSize # print table


Write-Host "Choose number based on the table: " -NoNewline -ForegroundColor Yellow
$choose = Read-Host

Write-Host ""

switch ($choose) {
    1 { #* ACL 9
        if (Test-Path "ACL 9.rar") {
            Write-Host "`nACL 9 folder already exists, continuing anyway..." -ForegroundColor Red
        }

        gdown --fuzzy "https://drive.google.com/file/d/13NuhwjDLhPBAQeGZDC90PA3HT2_wdXk8/view?usp=sharing" # ACL 9.rar

        UnZip "ACL 9.rar" ".\ACL 9\"
    }
    2 { #* adobe illustrator 2022
        gdown --fuzzy "https://drive.google.com/file/d/1iHbLr-PkXe2BfbnyQlzki7WJiEV7wsEm/view?usp=sharing" # AILS2265.rar
        UnZip "AILS2265.rar" ".\AILS2265\" "www.yasir252.com"

        Write-Host "`nIf installation is finished and scripts gets stuck, just end CorelDRAW process from task manager.`n" -ForegroundColor Red
        Start-Process `
            -FilePath "Set-up.exe" `
            -WorkingDirectory "${env:USERPROFILE}\Downloads\AILS2265\Adobe.Illustrator.2022.v26.5.0.223.x64\Setup\" `
            -Wait

        CopyFolder `
            "${env:USERPROFILE}\Downloads\AILS2265\Crack Only\amtlib.dll" `
            "${env:ProgramFiles}\Adobe\Adobe Illustrator 2022\Support Files\Contents\Windows\amtlib.dll"

        Write-Host "`nAfter installation, run the adobe unlicense block script to prevent adobe from checking license online." -ForegroundColor Red
        Write-Host "`nIt is number 31 on the table." -ForegroundColor Red
    }
    3 { #* adobe photoshop 2023
        gdown --fuzzy "https://drive.google.com/file/d/1YTyJnngcHi9abbbY-5RdOloVJ89o_Kdn/view?usp=sharing"
       
        # Delete previous instalation folder
        if ((Test-Path "${env:\CommonProgramFiles(x86)}\Adobe\SLCache") -or (Test-Path "$env:ProgramData\Adobe\SLStore")) {
            Remove-Item -Recurse -Force -Verbose "${env:\CommonProgramFiles(x86)}\Adobe\SLCache"
            Remove-Item -Recurse -Force -Verbose "$env:ProgramData\Adobe\SLStore"
        }

        UnZip "_Getintopc.com_Adobe_Photoshop_2023_v24.2.0.315.rar" ".\" "123"
        Set-Location "Adobe_Photoshop_2023_v24.2.0.315"
        Write-Host "`nRunning autoplay.exe..." -ForegroundColor Yellow
        .\autoplay.exe

        Write-Host "`nAfter installation, run the adobe unlicense block script to prevent adobe from checking license online." -ForegroundColor Red
        Write-Host "`nIt is number 31 on the table." -ForegroundColor Red
    }
    4 { #* adobe premier
        gdown --fuzzy "https://drive.google.com/file/d/1gQN1_cxghX2LfNTOCZo0GfsvwJW96q33/view?usp=drive_link"
        UnZip "PremierePro2023[www.yasir252.com].rar" ".\" "www.yasir252.com"
        
        Write-Host "Running Set-up.exe..." -ForegroundColor Yellow
        Set-Location "PremierePro2023.23.6.0.65"
        .\Set-up.exe

        Write-Host "`nAfter installation, run the adobe unlicense block script to prevent adobe from checking license online." -ForegroundColor Red
        Write-Host "`nIt is number 31 on the table." -ForegroundColor Red
    }
    5 { WingetInstallCommand "Google.AndroidStudio" "winget" } #* android studio
    6 { #* autocad 2023 Portable
        #! NEED TO DISABLE ANTIVIRUS
        gdown --fuzzy "https://drive.google.com/file/d/1tEJr0CHnqhepEl03raAgs3DK_TGU1CMN/view?usp=drive_link"
        UnZip "ACAD.2023.x64.Portable.rar" ".\ACAD.2023.x64.Portable\"

        Write-Host "Running AutoCad.exe as Admin..." -ForegroundColor Yellow
        Start-Process `
            -FilePath "AutoCad.exe" `
            -WorkingDirectory "${env:USERPROFILE}\Downloads\ACAD.2023.x64.Portable\" `
            -Verb RunAs

        CreateShortcutStartMenu "${env:USERPROFILE}\Downloads\ACAD.2023.x64.Portable\AutoCad.exe" "AutoCad 2023 Portable.lnk"
    }
    7 { WingetInstallCommand "Balsamiq.Wireframes" "winget" } #* balsamiq
    8 { WingetInstallCommand "XP9KN75RRB9NHS" "msstore" } #* capcut
    9 { #* circuit wizard
        gdown --fuzzy "https://drive.google.com/file/d/1I6iz-uzUFr4FrwAOfx1sYqj6U_GUwqI0/view?usp=sharing"
        UnZip "Circuit Wizard Student Version.zip" ".\"

        Set-Location "Circuit Wizard Student Version"
        CreateShortcutStartMenu "${env:USERPROFILE}\Downloads\Circuit Wizard Student Version\CktWiz.exe" "Circuit Wizard.lnk"

        Write-host "Running Circuit Wizard..." -ForegroundColor Yellow
        .\CktWiz.exe
    }
    10 { #* coreldraw
        #! NEED TO DISABLE ANTIVIRUS
        gdown --fuzzy "https://drive.google.com/file/d/1_2AOYgETZlChXHvhNrlYqHM5dVNq9jui/view?usp=drive_link"
        
        UnZip "CorelDRAW Graphics Suite 2021 v23.0.0.363.7z" ".\"

        Write-Host "`nIf installation is finished and scripts gets stuck, just end CorelDRAW process from task manager.`n" -ForegroundColor Red

        Write-Host "Running Setup.exe..." -ForegroundColor Yellow
        Start-Process `
            -FilePath "Setup.exe" `
            -WorkingDirectory "${env:USERPROFILE}\Downloads\CorelDRAW Graphics Suite 2021 v23.0.0.363 (x64) + Fix {CracksHash}\Setup\" `
            -Wait

        Write-Host "
        Instructions :

        1. Install the program from the given setup.
        2. Install the application as trial.
        3. Don't run the application yet and close from system tray or task manager if running.
        4. Copy everything from `"Crack Fix`" to C:\Program Files\Corel\CorelDRAW Graphics Suite 2021\Programs64\. Replace all the files.
        5. Boom! Now you can use the program without any interruptions.
        6. That's it, Enjoy now ;)
        " -ForegroundColor Red

        CopyFolder `
            "${env:USERPROFILE}\Downloads\CorelDRAW Graphics Suite 2021 v23.0.0.363 (x64) + Fix {CracksHash}\Crack Fix\Crack Fix\*" `
            "${env:ProgramFiles}\Corel\CorelDRAW Graphics Suite 2021\Programs64\"
    }
    11 { #* cx programming
        gdown --fuzzy "https://drive.google.com/file/d/1yCXn0j8c6EqvI4eKElYWNluau7w8oY46/view?usp=sharing"

        UnZip "[plc247.com]CxOne_V4.60.rar" ".\CX Programmer\" "plc247.com"

        Set-Location "CX Programmer\CxOne_V4.60\"
        .\setup.exe

        Write-Host "License key: 1600 0285 8143 5387 or 1600 0325 7848 5341" -ForegroundColor Red
    }
    12 { Write-Host "https://draw.io atau winget install JGraph.Draw" }
    13 { WingetInstallCommand "Figma.Figma" "winget" } #* figma
    14 { WingetInstallCommand "9NBLGGH4LVX9" "msstore" } #* fluid ui
    15 { #* FluidSim
        gdown --fuzzy "https://drive.google.com/file/d/1wFrPVIX1UHx7tS8ra4PPiDQSqoc0l0Lb/view?usp=drive_link"
        UnZip "festo fluidsim 4.2 PH-20231010T134944Z-001.rar" ".\"

        CreateShortcutStartMenu "${env:USERPROFILE}\Downloads\festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Hydraulic\bin\fl_sim_h.exe" "FluidSim Hydraulic.lnk" # Hydraulic
        CreateShortcutStartMenu "${env:USERPROFILE}\Downloads\festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Pneumatic\bin\fl_sim_p.exe" "FluidSim Pneumatic.lnk" # Pneumatic

        Write-Host "`nRunning FluidSim Hydraulic just to check if it's working..." -ForegroundColor Yellow
        & "${env:USERPROFILE}\Downloads\festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Hydraulic\bin\fl_sim_h.exe"

        Write-Host "`nRunning FluidSim Pneumatic just to check if it's working..." -ForegroundColor Yellow
        & "${env:USERPROFILE}\Downloads\festo fluidsim 4.2 PH-20231010T134944Z-001\festo fluidsim 4.2 PH\Pneumatic\bin\fl_sim_p.exe"
    }
    16 { WingetInstallCommand "Oracle.JavaRuntimeEnvironment" "winget" } # java
    17 { WingetInstallCommand "Oracle.JDK.25" "winget" "Oracle.JDK" "Oracle\.JDK\.\d+" } # jdk
    18 {  #* krishand inventory 3.0
        Invoke-WebRequest -Uri "https://www.pajak.net/download/inv03_300.exe" -OutFile "krishand-inventory-3.0.exe"
        
        Write-Host "Username: Admin" -ForegroundColor Red
        Write-host "Password: krishand" -ForegroundColor Red
        Write-Host "`nNanti biasanya minta username & password saat login."

        Write-Host "`nRunning krishand-inventory-3.0.exe..." -ForegroundColor Yellow
        .\krishand-inventory-3.0.exe
    }
    19 { #* minitab+
        gdown --fuzzy "https://drive.google.com/file/d/1wNvika8X7ft6KScOrzLvrAXX4t9K73Lx/view?usp=drive_link";
        Write-Host "`nmasukkan serial key dibawah ini, ketika diminta saat proses install `n`nKOPI-DVDD-OTCO-MOKE" -ForegroundColor Red
        Write-Host "`nRunning f4-minitab17-setup.exe..." -ForegroundColor Yellow
        .\f4-minitab17-setup.exe
    }
    20 { #* https://massgrave.dev/ (Excel, OneNote, PowerPoint, Word, OneDrive)
        Invoke-WebRequest `
            -Uri "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365AppsBasicRetail&platform=x64&language=en-us&version=O16GA" `
            -OutFile "OfficeSetup.exe"

        Write-Host "`nIf the scripts gets stuck after installation, just close any office process from task manager.`n" -ForegroundColor Red

        Write-Host "`nRunning OfficeSetup.exe..." -ForegroundColor Yellow
        Start-Process -FilePath "OfficeSetup.exe" -WorkingDirectory "$env:USERPROFILE\Downloads" -Wait

        Write-Host "`nActivating Microsoft Office products permanently (hopefully)..." -ForegroundColor Yellow
        & ([ScriptBlock]::Create((Invoke-RestMethod https://get.activated.win))) /Ohook
    }
    21 { #* visio
        gdown --fuzzy "https://drive.google.com/file/d/1iIj9FWs0kB4ZD6obIKaU6SQkjekVO8ye/view?usp=sharing"
        UnZip "VISIO2024.zip" ".\"

        Set-Location "VISIO2024"
        Write-Host "`nRunning setup.exe..." -ForegroundColor Yellow
        .\setup.exe /configure Configuration.xml
    }
    22 { WingetInstallCommand "Microsoft.VisualStudioCode" "winget" } # vscode
    23 { WingetInstallCommand "PHP.PHP.8.5" "winget" "PHP.PHP" "PHP\.PHP\.\d+\.\d+" } # php
    24 { #* POM QM
        Invoke-WebRequest -Uri "https://qm-for-windows.software.informer.com/download/?ca1e2f92" -OutFile POM-QM.exe

        Write-Host "`nRunning POM-QM.exe..." -ForegroundColor Yellow
        .\POM-QM.exe
    }
    25 { #* SPSS
        gdown --fuzzy https://drive.google.com/file/d/1b1Lx46x-JtDfWpaXq5LFlTZ-pTsPMjpY/view?usp=drive_link # .exe
        gdown --fuzzy https://drive.google.com/file/d/10j7mG_WODqRlFrygwqUEITIccYyi-ET5/view?usp=drive_link # lservrc
        
        Write-Host "`nRunning SPSS_Statistics_25.exe..." -ForegroundColor Yellow
        Start-Process -FilePath "SPSS_Statistics_25.exe" -WorkingDirectory "$env:USERPROFILE\Downloads" -Wait

        Write-Host "`nMoving lservrc to SPSS installation folder..." -ForegroundColor Yellow
        Move-Item `
            -Path "${env:USERPROFILE}\Downloads\lservrc" `
            -Destination "${env:ProgramFiles}\IBM\SPSS\Statistics\25\" `
            -Force `
            -Verbose
        
    }
    26 { WingetInstallCommand "MKLabs.StarUML" "winget" } # star uml
    27 { #* Tableau
        gdown --fuzzy "https://drive.google.com/file/d/1NHNDnIcG0q6b4rfBJcYPxzKa9oEGMHop/view?usp=drive_link"
        UnZip "Tableau Desktop 2023.1.0 (x64).kuyhAa.7z" ".\"

        Write-Host "`nIf the script gets stuck after installation, just close Tableau process from task manager.`n" -ForegroundColor Red

        Write-Host "`nRunning TableauDesktop-64bit-2023-1-0_Downloadly.ir.exe..." -ForegroundColor Yellow
        Start-Process `
            -FilePath "TableauDesktop-64bit-2023-1-0_Downloadly.ir.exe" `
            -WorkingDirectory "$env:USERPROFILE\Downloads\Tableau Desktop 2023.1.0 (x64).kuyhAa\" `
            -Wait

        Write-Host "
        1. Copy `"tabui.dll`" to C:\Program Files\Tableau\Tableau 2023.1\bin
        2. Copy `"tableau_003e2900_tsf.data`" to C:\ProgramData\FLEXnet (It's hidden)
        3. Open application, Close the license window
        4. Use software

        NOTE: If you've registered software as trial, remove tableau_003e2900_tsf.data (& every relevent backups)
        from C:\ProgramData\FLEXnet, then do from step 2 above.
        " -ForegroundColor Red

        CopyFolder "$env:USERPROFILE\Downloads\Tableau Desktop 2023.1.0 (x64).kuyhAa\_Jamu\tabui.dll" `
            "${env:ProgramFiles}\Tableau\Tableau 2023.1\bin\tabui.dll"

        CopyFolder "$env:USERPROFILE\Downloads\Tableau Desktop 2023.1.0 (x64).kuyhAa\_Jamu\tableau_003e2900_tsf.data" `
            "${env:ProgramData}\FLEXnet\tableau_003e2900_tsf.data"
    }
    28 { WingetInstallCommand "ApacheFriends.Xampp.8.2" "winget" "ApacheFriends.Xampp" "ApacheFriends\.Xampp\.\d+\.\d+" } # xampp
    29 { #* zahir
        gdown --fuzzy "https://drive.google.com/file/d/1VhZ58l_tA7dpDFmOxocHMjPUt8Gqn8_P/view?usp=sharing"
        UnZip "Master ZAHIR 6.11a.zip" ".\"

        Write-Host "`nRunning setup.exe..." -ForegroundColor Yellow
        Set-Location "Master ZAHIR 6.11a"
        .\setup.exe
    }
    30 { #* Data-Simulasi 2012
        if (Test-Path ".\DATA-SIMULASI 2012\") {
            Write-Host "`nDATA-SIMULASI 2012 folder already exists, continuing anyway..." -ForegroundColor Red
        }

        gdown --fuzzy "https://drive.google.com/file/d/1PdGoSjSr5k2xVVCGgxnNuT7S31Crm8S9/view?usp=drive_link" # DATA-SIMULASI 2012.rar
        UnZip "DATA-SIMULASI 2012.rar" ".\DATA-SIMULASI 2012"
    }
    31 { #* Block Adobe Unlicense
        # Write-Host "`nDownloading and installing Adobe GenP Patch v3.7.1..." -ForegroundColor Red
        # Write-Host "`nThis is usually not needed, and require you do disable antivirus temporarily." -ForegroundColor Red
        # gdown --fuzzy "https://drive.google.com/file/d/1O0F8XqLu5mxAjoZpExLLL0DCzhSWRVVL/view?usp=drive_link"
        # UnZip "GenP371[www.yasir252.com].rar" ".\GenP371\" "www.yasir252.com"

        # Write-Host "`nRunning GenP-v3.7.1.exe..." -ForegroundColor Yellow
        # Set-Location ".\GenP371\Adobe GenP Patch v3.7.1"
        # .\GenP-v3.7.1.exe

        # Write-Host "`nSee this picture for instructions : https://www.yasir252.com/wp-content/uploads/2025/06/adobe-genp-patch-remove-pop-up.jpg" -ForegroundColor Red

        # Write-Host "`nSource : https://www.yasir252.com/en/applications/adobe-premiere-pro-2023-free-download-pc-final/" -ForegroundColor Red

        Write-Host "`nTHIS IS REQUIRED! And should be enough to block adobe activation servers." -ForegroundColor Red
        Invoke-RestMethod "https://raw.githubusercontent.com/get543/Windows-Scripting/refs/heads/main/config/hosts" | Out-File "$env:windir\System32\drivers\etc\hosts"

        Write-Host "`nRunning CTT Tool... `nLook for anything related to Adobe and remove it or apply tweaks" -ForegroundColor Red
        Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
    }
    32 { #* Delete leftover files
        Write-Host "`nDeleting leftover files..." -ForegroundColor Yellow

        $leftOverFiles = @(
            "${env:USERPROFILE}\Downloads\ACL 9.rar",

            "${env:USERPROFILE}\Downloads\AILS2265.rar",
            "${env:USERPROFILE}\Downloads\AILS2265",

            "${env:USERPROFILE}\Downloads\_Getintopc.com_Adobe_Photoshop_2023_v24.2.0.315.rar",
            "${env:USERPROFILE}\Downloads\Adobe_Photoshop_2023_v24.2.0.315",

            "${env:USERPROFILE}\Downloads\PremierePro2023[www.yasir252.com].rar",
            "${env:USERPROFILE}\Downloads\PremierePro2023.23.6.0.65",

            "${env:USERPROFILE}\Downloads\ACAD.2023.x64.Portable.rar",

            "${env:USERPROFILE}\Downloads\Circuit Wizard Student Version.zip",

            "${env:USERPROFILE}\Downloads\CorelDRAW Graphics Suite 2021 v23.0.0.363.7z",
            "${env:USERPROFILE}\Downloads\CorelDRAW Graphics Suite 2021 v23.0.0.363 (x64) + Fix {CracksHash}",

            "${env:USERPROFILE}\Downloads\[plc247.com]CxOne_V4.60.rar",
            "${env:USERPROFILE}\Downloads\CX Programmer",

            "${env:USERPROFILE}\Downloads\festo fluidsim 4.2 PH-20231010T134944Z-001.rar",

            "${env:USERPROFILE}\Downloads\krishand-inventory-3.0.exe",
            "${env:USERPROFILE}\Downloads\f4-minitab17-setup.exe",
            "${env:USERPROFILE}\Downloads\OfficeSetup.exe",

            "${env:USERPROFILE}\Downloads\VISIO2024.zip",
            "${env:USERPROFILE}\Downloads\VISIO2024",

            "${env:USERPROFILE}\Downloads\POM-QM.exe",
            
            "${env:USERPROFILE}\Downloads\SPSS_Statistics_25.exe",
            "${env:USERPROFILE}\Downloads\lservrc",

            "${env:USERPROFILE}\Downloads\Tableau Desktop 2023.1.0 (x64).kuyhAa.7z",
            "${env:USERPROFILE}\Downloads\Tableau Desktop 2023.1.0 (x64).kuyhAa",

            "${env:USERPROFILE}\Downloads\Master ZAHIR 6.11a.zip",
            "${env:USERPROFILE}\Downloads\Master ZAHIR 6.11a",

            "${env:USERPROFILE}\Downloads\GenP371[www.yasir252.com].rar",
            "${env:USERPROFILE}\Downloads\GenP371"
        )

        foreach ($file in $leftOverFiles) {
            if (Test-Path -LiteralPath $file) {
                Write-Host "`n`n`nDeleting leftover file: $file`n" -ForegroundColor Red
                Remove-Item -LiteralPath $file -Force -Recurse
            }
        }
    }
    Default { Write-Host "`nWrong option try again." -ForegroundColor Red }
}

# CRITICAL: Refresh PATH immediately after install
RefreshPath

Write-Host "`nDone." -ForegroundColor Yellow
