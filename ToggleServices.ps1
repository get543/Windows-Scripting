if ($args.Count -eq 0) {
    Write-Host "Example: .\ToggleServices.ps1 'Cloudflare Warp'"
    Write-Host "What service you want to toggle start or stop ?"
    Write-Host "To get service's name, use the built-in Services app on windows."
    return
}

$ServiceName = Get-Service -Name $args
$ServiceStatus = (Get-Service -Name $args).Status
$ServiceDisplayName = (Get-Service -Name $args).DisplayName

if ($ServiceStatus -eq "Running") {
    Write-Host "Stopping ${ServiceDisplayName}..."
    Stop-Service $ServiceName
} elseif ($ServiceStatus -eq "Stopped") {
    Write-Host "Start ${ServiceDisplayName}..."
    Start-Service $ServiceName
} else {
    Write-Host "${ServiceDisplayName} is not running or stopped."
}
