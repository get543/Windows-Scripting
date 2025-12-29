<#
.DESCRIPTION
https://www.powershellgallery.com/packages/AudioDeviceCmdlets/3.1.0.2
https://github.com/frgnca/AudioDeviceCmdlets

.PARAMETER SetDevice
If specified, the script will attempt to set the audio device environment variables.

.EXAMPLE
Get-AudioDevice -List | Where-Object Type -like "Playback" | Where-Object name -like "*Realtek*"
Set-AudioDevice -ID "{0.0.0.00000000}.{4229d439-1b7d-4deb-894e-544bb0fa40e1}" # speakers
Set-AudioDevice -ID "{0.0.0.00000000}.{69274eea-2c89-451d-813a-c9407258be99}" # headphones
Get-AudioDevice -List | Where-Object Type -like "Recording" | Where-Object Name -Like "*V8*" | Set-AudioDevice # set v8 mixer as default recording device
Get-AudioDevice -List | Where-Object Type -Like "Playback" | Where-Object Name -Like "*speakers*" | Set-AudioDevice # set speakers as default playback device

.NOTES
Requires the AudioDeviceCmdlets module
Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser

To set custom device names, set the following user environment variables:
[System.Environment]::SetEnvironmentVariable("HEADPHONES_DEVICE_NAME", "*Headphones*", "User")
[System.Environment]::SetEnvironmentVariable("SPEAKERS_DEVICE_NAME", "*Output Front Panel*", "User")
[System.Environment]::SetEnvironmentVariable("SOUNDCARD_DEVICE_NAME", "*Output Mixer*", "User")

or this :
$env:SPEAKERS_DEVICE_NAME = "Output Front Panel"
$env:HEADPHONES_DEVICE_NAME = "Headphones"
$env:SOUNDCARD_DEVICE_NAME = "Output Mixer"
#>

param (
    [switch]$SetDevice
)

if ($SetDevice) {
    Write-Host "`nAvailable Playback Audio Devices:"
    Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" } | Select-Object Index, Default, DefaultCommunication, Name | Format-Table -AutoSize
    
    Write-Host "`nCurrent Environment Variable Values:" -ForegroundColor Green
    Write-Host "HEADPHONES_DEVICE_NAME = $env:HEADPHONES_DEVICE_NAME"
    Write-Host "SPEAKERS_DEVICE_NAME = $env:SPEAKERS_DEVICE_NAME"
    Write-Host "SOUNDCARD_DEVICE_NAME = $env:SOUNDCARD_DEVICE_NAME"
    

    Write-Host "`nTo set custom device names, run this command:" -ForegroundColor Green
    Write-Host '$env:HEADPHONES_DEVICE_NAME = "your speaker name"'
    Write-Host '$env:SPEAKERS_DEVICE_NAME = "your headphones name"'
    Write-Host '$env:SOUNDCARD_DEVICE_NAME = "your soundcard name"'

    Write-Host "`nSet new device : " -ForegroundColor Yellow -NoNewline
    $envcommand = Read-Host

    Invoke-Expression $envcommand

    return

}

# Use environment variables with fallback to default values
$HeadphonesDeviceName = if ($env:HEADPHONES_DEVICE_NAME) { "*$env:HEADPHONES_DEVICE_NAME*" } else { "*Headphones*" }
$SpeakersDeviceName = if ($env:SPEAKERS_DEVICE_NAME) { "*$env:SPEAKERS_DEVICE_NAME*" } else { "*Output Front Panel*" } # act as speakers
$SoundcardDeviceName = if ($env:SOUNDCARD_DEVICE_NAME) { "*$env:SOUNDCARD_DEVICE_NAME*" } else { "*Output Mixer*" } # act as headphones

Write-Host $HeadphonesDeviceName
Write-Host $SpeakersDeviceName
Write-Host $SoundcardDeviceName

function WindowsNotificationBalloon($text) {
    # windows 10 notification balloon
    Add-Type -AssemblyName System.Windows.Forms
    $global:BalloonNotification = New-Object System.Windows.Forms.NotifyIcon

    $path = (Get-Process -id $pid).Path
    $BalloonNotification.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $BalloonNotification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $BalloonNotification.BalloonTipText = "${text}"
    $BalloonNotification.BalloonTipTitle = "Change Output Device"
    $BalloonNotification.Visible = $true
    $BalloonNotification.ShowBalloonTip(5000)
}

# if AudioDeviceCmdlets module is not installed, prompt to install it
if (!(Get-Module -ListAvailable -Name AudioDeviceCmdlets -ErrorAction SilentlyContinue)) {
    Write-Host "`nAudioDeviceCmdlets module is not installed." -ForegroundColor Red
    Write-Host "Install AudioDeviceCmdlets module ? [Y/n] " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y" -or $response -eq "") {
        Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser
    } else {
        Write-Host "Exiting script."
    }
    return
}


#!########################################################################################################
#!                                        Check and Change Output Device                                 #
#!########################################################################################################

# if headphones is the default output then change it to speakers
if (Get-AudioDevice -PlaybackCommunication | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $HeadphonesDeviceName }) {
    Write-Host "Change default audio device to Speakers."
    
    Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $SpeakersDeviceName } | Set-AudioDevice
    WindowsNotificationBalloon "Change default audio device to Speakers."
} 
# if speakers is default audio then change it to headphones
elseif (Get-AudioDevice -PlaybackCommunication | Where-Object { ($_.Type -eq "Playback" -and $_.Name -like $SpeakersDeviceName) }) {

    # if there's no headphone device output then change it to soundcard output
    if (!(Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $HeadphonesDeviceName })) {
        Write-Host "Change default audio device to Output Mixer."
        Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $SoundcardDeviceName } | Set-AudioDevice
        WindowsNotificationBalloon "Change default audio device to Output Mixer."
        return
    }

    Write-Host "Change default audio device to Headphones."
    Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $HeadphonesDeviceName } | Set-AudioDevice
    WindowsNotificationBalloon "Change default audio device to Headphones."
} 
# if soundcard is default audio then change it to speakers
elseif (Get-AudioDevice -PlaybackCommunication | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $SoundcardDeviceName }) {
    Write-Host "Change default audio device to Speakers."
    Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $SpeakersDeviceName } | Set-AudioDevice
    WindowsNotificationBalloon "Change default audio device to Speakers."
}