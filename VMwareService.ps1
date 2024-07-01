$Services = @("VMware DHCP Service", "VMware NAT Service", "VMware USB Arbitration Service")


foreach ($Service in $Services) {
    $ServiceName = Get-Service -Name $Service
    $ServiceStatus = (Get-Service -Name $Service).Status
    $ServiceDisplayName = (Get-Service -Name $Service).DisplayName
    
    if ($ServiceStatus -eq "Running") {
        Write-Host "Stopping ${ServiceDisplayName}..."
        Stop-Service $ServiceName
    } elseif ($ServiceStatus -eq "Stopped") {
        Write-Host "Start ${ServiceDisplayName}..."
        Start-Service $ServiceName
    } else {
        Write-Host "${ServiceDisplayName} is not running or stopped."
    }
}
