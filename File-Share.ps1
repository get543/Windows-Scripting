################################# !File Sharing via HTTP Server and Cloudflare Tunnel #################################

param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

if (!(Get-Command -Name cloudflared -ErrorAction SilentlyContinue) -or !(Get-Command -Name simple-http-server -ErrorAction SilentlyContinue)) {
    Write-Host "`ncloudflared or simple-http-server is not installed." -ForegroundColor Red
    Write-Host "Please install both of them first before running this script." -ForegroundColor Red
    return
}

#* Start the server
Start-Job -Name "MyServer" -ScriptBlock {
    Set-Location $using:FilePath
    simple-http-server.exe -u -i -t 4 -c $using:FilePath
}
Start-Sleep -Seconds 5 # wait for the job to start

Start-Job -Name "MyTunnel" -ScriptBlock {
    cloudflared.exe tunnel --url http://0.0.0.0:8000
}
Start-Sleep -Seconds 5 # wait for the job to start

Write-Host "`n🚀 Server and Tunnel are running!`n" -ForegroundColor Cyan

#* To see the output of the server:
Receive-Job -Name MyServer -Keep
Start-Sleep -Seconds 5 # wait for the job to start
Receive-Job -Name MyTunnel -Keep

Write-Host "`nPress ENTER to stop both and exit..." -ForegroundColor Yellow -NoNewline
Read-Host

#* Stop the jobs
Stop-Job -Name "MyServer", "MyTunnel"
Remove-Job -Name "MyServer", "MyTunnel"
Write-Host "🛑 Jobs stopped and cleaned up." -ForegroundColor Red
