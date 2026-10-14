
# Open the Microsoft Store updates page
Start-Process "ms-windows-store://downloadsandupdates"

# Load Windows UI Automation assemblies
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$buttonNames = @(
    "Get updates",
    "Check for updates"
)

$deadline = (Get-Date).AddSeconds(10)
$clicked = $false

Write-Host "`nWaiting for the Microsoft Store update button..." -ForegroundColor Yellow

while ((Get-Date) -lt $deadline -and -not $clicked) {

    foreach ($buttonName in $buttonNames) {

        $condition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty,
            $buttonName
        )

        try {
            $elements = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
                [System.Windows.Automation.TreeScope]::Descendants,
                $condition
            )

            foreach ($element in $elements) {
                try {
                    # Only invoke buttons, not other controls with matching text
                    if ($element.Current.ControlType -ne
                        [System.Windows.Automation.ControlType]::Button) {
                        continue
                    }

                    $pattern = $null

                    if ($element.TryGetCurrentPattern(
                        [System.Windows.Automation.InvokePattern]::Pattern,
                        [ref]$pattern
                    )) {
                        $pattern.Invoke()

                        Write-Host "`nClicked '$buttonName'" -ForegroundColor Green
                        $clicked = $true
                        break
                    }
                }
                catch {
                    # Ignore controls that become unavailable
                }
            }
        }
        catch {
            # Retry if the Store UI is not ready yet
        }

        if ($clicked) { break }
    }

    if (-not $clicked) {
        Start-Sleep -Milliseconds 1000
    }
}

if (-not $clicked) {
    Write-Host "`nCould not find the update button within 10 seconds." -ForegroundColor Yellow
    Write-Host "Check the Store window, its language, and the button label." -ForegroundColor Yellow
}
