<#
.DESCRIPTION
Private PowerShell Configuration (Untracked)
This file securely stores local paths, API keys, and work-specific folder 
aliases that should NEVER be exposed on GitHub.

.SETUP
1. Create this file in the exact same directory as your main $PROFILE.
2. Add the exact name 'PrivateFolderAlias.ps1'
3. Do not track or commit this file using Git.

.USAGE
Define your private, machine-specific aliases and variables below. 
Because this file is "dot-sourced" by your main profile, everything here 
will act exactly as if you had typed it into the main file.
#>

######### !Folder Alias #########
function filehistory() {
    Set-Location "D:\FileHistory"
}
function replaybuffer() {
    Set-Location "D:\Video\Screen Recorder\OBS Replay Buffer"
}
function links() {
    Set-Location "${env:LOCALAPPDATA}\Microsoft\WinGet\Links"
}


######### !Run Scripts #########
function SystemUpgrade() {
    & "${env:USERPROFILE}\Documents\PowerShell\Scripts\Windows-Scripting\SystemUpgrade\SystemUpgrade.ps1" @args
}


######### !Run Python Scripts
function convert() {
    if (Test-Path -Path "E:\Code\Python-Currency-Converter\convert_currency.py") {
        python E:\Code\Python-Currency-Converter\convert_currency.py @args
    }
}