$Services = @("VMware DHCP Service", "VMware NAT Service", "VMware USB Arbitration Service")

$VMWareProcess = Get-Process vmplayer -ErrorAction SilentlyContinue

if (!$VMWareProcess) {
    Write-Host "Start VMWare Workstation Player."
    Start-Process -FilePath "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmplayer.exe"
}
elseif ($VMWareProcess) {
    Write-Host "Stop VMWare Worksation Player."
    $VMWareProcess | Stop-Process -Force
}

foreach ($Service in $Services) {
    $ServiceName = Get-Service -Name $Service
    $ServiceStatus = (Get-Service -Name $Service).Status
    $ServiceDisplayName = (Get-Service -Name $Service).DisplayName
    
    if ($ServiceStatus -eq "Running") {
        Write-Host "Stop ${ServiceDisplayName}."
        Stop-Service $ServiceName
    }
    elseif ($ServiceStatus -eq "Stopped") {
        Write-Host "Start ${ServiceDisplayName}."
        Start-Service $ServiceName
    }
    else {
        Write-Host "${ServiceDisplayName} is not running or stopped."
    }
}
