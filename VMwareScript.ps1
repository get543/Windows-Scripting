<#
.DESCRIPTION
Script to enable or disable required VMWare services, autolaunch specific VMs 

.PARAMETER AutoLaunch
Autolaunch specified VMs

.EXAMPLE
.\VMWareScript.ps1 -AutoLaunch fedora -DontToggleServices

.EXAMPLE
.\VMWareScript.ps1 -AutoLaunch arch

.EXAMPLE
Get-Help .\VMWareScript.ps1

.SYNOPSIS
Autolaunch specified VMs.
Enable or Disable VMWare services.
#>

#! Parameter help description
param(
    [Parameter(ParameterSetName = "AutoLaunch")]
    [ValidateSet(
        "fedora",
        "arch",
        "kali",
        "windows"
    )]
    [String] $AutoLaunch,
    [Switch] $DontToggleServices
)

$vmwarePath = "${env:ProgramFiles}\VMware\VMware Workstation\vmrun.exe"

#! Check if VMWare Workstation is installed
if (!(Test-Path $vmwarePath)) {
    Write-Host "VMWare Workstation is not installed. Exiting script." -ForegroundColor Red
    return
}

#! Autolaunch VMs
if ($AutoLaunch -eq "fedora") {
    & $vmwarePath -T ws start "${env:USERPROFILE}\Downloads\FROM PC\VMWare Workstation Pro\Fedora Linux\Fedora Linux.vmx"
} elseif ($AutoLaunch -eq "arch") {
    & $vmwarePath -T ws start "${env:USERPROFILE}\Downloads\VMWare\Arch Linux\Arch Linux.vmx"
} elseif ($AutoLaunch -eq "kali") {
    & $vmwarePath -T ws start "${env:USERPROFILE}\Downloads\VMWare\KaliLinux\Kali Linux.vmx"
} elseif ($AutoLaunch -eq "windows") {
    & $vmwarePath -T ws start "${env:USERPROFILE}\Downloads\FROM PC\VMWare Workstation Pro\Windows 11 Pro\Windows 11 Pro.vmx"
}


#! Start or Stop VMware Workstation program
# $VMWareProcess = Get-Process vmplayer -ErrorAction SilentlyContinue

# if (!$VMWareProcess) {
#     Write-Host "Start VMWare Workstation Player."
#     Start-Process -FilePath "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmplayer.exe"
# }
# elseif ($VMWareProcess) {
#     Write-Host "Stop VMWare Worksation Player."
#     $VMWareProcess | Stop-Process -Force
# }

if ($DontToggleServices) {
    return
}

#! Enable or Disable required services
$Services = @("VMware DHCP Service", "VMware NAT Service", "VMware USB Arbitration Service")

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
