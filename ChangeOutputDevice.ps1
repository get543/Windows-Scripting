<#
.DESCRIPTION
https://www.powershellgallery.com/packages/AudioDeviceCmdlets/3.1.0.2
https://github.com/frgnca/AudioDeviceCmdlets

.EXAMPLE
Get-AudioDevice -List | Where-Object Type -like "Playback" | Where-Object name -like "*Realtek*"
Set-AudioDevice -ID "{0.0.0.00000000}.{4229d439-1b7d-4deb-894e-544bb0fa40e1}" # speakers
Set-AudioDevice -ID "{0.0.0.00000000}.{69274eea-2c89-451d-813a-c9407258be99}" # headphones
Get-AudioDevice -List | Where-Object Type -like "Recording" | Where-Object name -like "*V8*" | Set-AudioDevice # set v8 mixer default recording device
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

$SpeakerDeviceID = "{0.0.0.00000000}.{48d2a713-5544-4b20-b197-e6fa542a2974}"
$HeadphoneDeviceID = "{0.0.0.00000000}.{4fe3e699-f8db-4d3f-bfe4-d8801939fb00}"

# if headphones is the default output then change it to speakers
if (Get-AudioDevice -PlaybackCommunication | Where-Object { $_.ID -eq "${HeadphoneDeviceID}" }) {
    Write-Host "Change default audio device to Speakers."
    Set-AudioDevice -ID "${SpeakerDeviceID}"
    WindowsNotificationBalloon "Change default audio device to Speakers."

} # if speakers is default audio then change it headphones
elseif (Get-AudioDevice -PlaybackCommunication | Where-Object { $_.ID -eq "${SpeakerDeviceID}" }) {
    Write-Host "Change default audio device to Headphones."
    Set-AudioDevice -ID "${HeadphoneDeviceID}"
    WindowsNotificationBalloon "Change default audio device to Headphones."
}

