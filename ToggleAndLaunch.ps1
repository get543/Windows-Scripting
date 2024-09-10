<#
.DESCRIPTION
Toggle a service on or off and run an application

.PARAMETER Service
What service you want to toggle ?
You can get the service name by using windows built-in Services app or use the Get-Service command
You can only toggle 1 service!

.PARAMETER App
What app you want to run after a service is toggled ?
You can get the app name by running the app normally and then using Get-Process command.
You can only run 1 app!

.EXAMPLE
.\ToggleAndLaunch.ps1 -Service 'Cloudflare WARP' -App 'Cloudflare WARP'
#>

param (
    [Parameter(Mandatory = $true)]
    [String]$Service,
    [String]$App
)

########################## Toggle Service ##########################
$ServiceName = Get-Service -Name $Service
$ServiceStatus = (Get-Service -Name $Service).Status
$ServiceDisplayName = (Get-Service -Name $Service).DisplayName

if ($ServiceStatus -eq "Running") {
    Write-Host "Stop ${ServiceDisplayName} Service."
    Stop-Service $ServiceName
}
elseif ($ServiceStatus -eq "Stopped") {
    Write-Host "Start ${ServiceDisplayName} Service."
    Start-Service $ServiceName
}
else {
    Write-Host "${ServiceDisplayName} is not running or stopped."
}

########################## Launch App ##########################
$AppProcess = Get-Process $App -ErrorAction SilentlyContinue

if (!$AppProcess) {
    Write-Host "Start $App Process."
    Start-Process $App
}
elseif ($AppProcess) {
    Write-Host "Stop $App Process."
    $AppProcess | Stop-Process -Force
}