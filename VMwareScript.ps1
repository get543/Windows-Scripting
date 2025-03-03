<#
.DESCRIPTION
Script to enable or disable required VMWare services, autolaunch specific VMs 

.PARAMETER AutoLaunch
Autolaunch specified VMs

.EXAMPLE
.\VMWareScript.ps1 -AutoLaunch fedora

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
        "kali"
    )]
    [String] $AutoLaunch


)

#! Autolaunch VMs
if ($AutoLaunch -eq "fedora") {
    & "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmrun.exe" -T ws start "${env:USERPROFILE}\Downloads\VMWare\FedoraLinux\Fedora Linux.vmx"
} elseif ($AutoLaunch -eq "arch") {
    & "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmrun.exe" -T ws start "${env:USERPROFILE}\Downloads\ArchLinux\Arch Linux.vmx"
} elseif ($AutoLaunch -eq "kali") {
    & "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmrun.exe" -T ws start "${env:USERPROFILE}\Downloads\KaliLinux\Kali Linux.vmx"
}


#! Start or Stop VMware process
# $VMWareProcess = Get-Process vmplayer -ErrorAction SilentlyContinue

# if (!$VMWareProcess) {
#     Write-Host "Start VMWare Workstation Player."
#     Start-Process -FilePath "${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmplayer.exe"
# }
# elseif ($VMWareProcess) {
#     Write-Host "Stop VMWare Worksation Player."
#     $VMWareProcess | Stop-Process -Force
# }

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
