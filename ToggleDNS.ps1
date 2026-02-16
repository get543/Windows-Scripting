# Get the Cloudflare WARP service
$WARPService = Get-Service -Name "Cloudflare WARP" -ErrorAction SilentlyContinue

if ($WARPService -and $WARPService.Status -eq 'Running') {
    # --- STOP SEQUENCE ---
    Write-Host "Cloudflare WARP is running. Stopping it..."

    # Disconnect using warp-cli
    Write-Host "Disconnecting Cloudflare..."
    warp-cli disconnect
    Start-Sleep -Seconds 2

    # Stop the service
    Write-Host "Stopping Cloudflare Service."
    Stop-Service -Name "Cloudflare WARP" -Force

    # Stop the GUI application
    $warpProcess = Get-Process -Name "Cloudflare WARP" -ErrorAction SilentlyContinue
    if ($warpProcess) {
        Write-Host "Closing Cloudflare WARP application."
        $warpProcess | Stop-Process -Force
    }

    Write-Host "Cloudflare WARP stopped successfully."

} else {
    # --- START SEQUENCE ---
    Write-Host "Cloudflare WARP is stopped. Starting it..."

    # Start the service
    Write-Host "Starting Cloudflare Service."
    Start-Service -Name "Cloudflare WARP"
    Start-Sleep -Seconds 3

    # Connect using warp-cli
    Write-Host "Connecting Cloudflare..."
    warp-cli connect

    # Start the GUI application
    $warpProcess = Get-Process -Name "Cloudflare WARP" -ErrorAction SilentlyContinue
    if (!($warpProcess)) {
        Write-Host "Launching Cloudflare WARP application."
        Start-Process "Cloudflare WARP.exe" -ErrorAction Stop
    }

    Write-Host "Cloudflare WARP started successfully."
}
