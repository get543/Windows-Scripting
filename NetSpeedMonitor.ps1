while ($true) {
    # Get an object for the network interfaces, excluding any that are currently disabled.
    $colInterfaces = Get-CimInstance -class Win32_PerfFormattedData_Tcpip_NetworkInterface | Select-Object BytesTotalPersec, CurrentBandwidth, PacketsPersec | Where-Object { $_.PacketsPersec -gt 0 }

    foreach ($interface in $colInterfaces) {
        $totalBits = $interface.CurrentBandwidth

        # Exclude Nulls (any WMI failures)
        if ($totalBits -gt 0) {
            $rawResult = $interface.BytesTotalPersec * 0.001
            $result = [math]::Round($rawResult,2)
            $unit = "KB"

            Clear-Host
            Write-Host "Network Speed : $result $unit"
        }
    }
    Start-Sleep -milliseconds 100
}
