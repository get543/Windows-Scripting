while ($true) {
    $colInterfaces = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface | Select-Object BytesTotalPersec, CurrentBandwidth, PacketsPersec | Where-Object { $_.PacketsPersec -gt 0 }

    foreach ($interface in $colInterfaces) {
        $totalBits = $interface.CurrentBandwidth

        if ($totalBits -gt 0) {
            $bytesPerSec = $interface.BytesTotalPersec
            $units = @('B', 'KB', 'MB', 'GB', 'TB')
            $unitIndex = 0
            $value = $bytesPerSec

            # Determine the appropriate unit
            while ($value -ge 1024 -and $unitIndex -lt $units.Length - 1) {
                $value /= 1024
                $unitIndex++
            }

            # Round and check if it needs to go to the next unit
            $valueRounded = [math]::Round($value, 2)
            if ($valueRounded -ge 1024 -and $unitIndex -lt ($units.Length - 1)) {
                $valueRounded /= 1024
                $unitIndex++
                $valueRounded = [math]::Round($valueRounded, 2)
            }

            $result = $valueRounded
            $unit = $units[$unitIndex]

            Clear-Host
            Write-Host "Network Speed : $result $unit/s"
        }
    }
    Start-Sleep -Milliseconds 1000
}