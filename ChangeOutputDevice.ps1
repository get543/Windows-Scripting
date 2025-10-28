<#
.DESCRIPTION
https://www.powershellgallery.com/packages/AudioDeviceCmdlets/3.1.0.2
https://github.com/frgnca/AudioDeviceCmdlets

.EXAMPLE
Get-AudioDevice -List | Where-Object Type -like "Playback" | Where-Object name -like "*Realtek*"
Set-AudioDevice -ID "{0.0.0.00000000}.{4229d439-1b7d-4deb-894e-544bb0fa40e1}" # speakers
Set-AudioDevice -ID "{0.0.0.00000000}.{69274eea-2c89-451d-813a-c9407258be99}" # headphones
Get-AudioDevice -List | Where-Object Type -like "Recording" | Where-Object Name -Like "*V8*" | Set-AudioDevice # set v8 mixer as default recording device
Get-AudioDevice -List | Where-Object Type -Like "Playback" | Where-Object Name -Like "*speakers*" | Set-AudioDevice # set speakers as default playback device
#>

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

$HeadphonesDeviceName = "*Headphones*"
$SpeakersDeviceName = "*Output Monitor*" # act as speakers
$FrontPanelDeviceName = "*Output Front Panel*" # act as speakers
$SoundcardDeviceName = "*Output Mixer*" # act as headphones

# if headphones is the default output then change it to speakers
if (Get-AudioDevice -PlaybackCommunication | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $HeadphonesDeviceName }) {
    Write-Host "Change default audio device to Speakers."
    
    Get-AudioDevice -List | Where-Object { $_.Type -eq "Playback" -and $_.Name -like $FrontPanelDeviceName } | Set-AudioDevice
    WindowsNotificationBalloon "Change default audio device to Speakers."
} 
# if speakers/front panel is default audio then change it to headphones
elseif (Get-AudioDevice -PlaybackCommunication | Where-Object { 
    ($_.Type -eq "Playback" -and $_.Name -like $SpeakersDeviceName) -or ($_.Type -eq "Playback" -and $_.Name -like $FrontPanelDeviceName) }) {

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