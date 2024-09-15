$WARPProcess = Get-Process warp-svc -ErrorAction SilentlyContinue
$WARPService = Get-Service -Name "CloudflareWARP"

if (!$WARPProcess -and $WARPService.Status -eq "Stopped") {
    Write-Host "Start Cloudflare Service."
    Start-Service $WARPService
    Start-Sleep 3
    Write-Host "Starting Cloudflare connection..."
    warp-cli connect
}
elseif ($WARPProcess -and $WARPService.Status -eq "Running") {
    Write-Host "Disconnecting Cloudflare..."
    warp-cli disconnect
    Start-Sleep 3
    Write-Host "Stop Cloudflare Service."
    Stop-Service $WARPService
}
