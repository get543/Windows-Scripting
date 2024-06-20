$Path = "~/Downloads"

if (!(Get-Command -Name yt-dlp)) {
	return "yt-dlp is not installed on your system or yt-dlp is not recognise as a command."
}

Write-Host  "---------------------------------------------------------"
Write-Host  " 	No	|	Option"
Write-Host  "---------------------------------------------------------"
Write-Host  " 	1.	| 	Download A Video"
Write-Host  " 	2. 	|	Download A Music Playlist Video"
Write-Host  " 	3. 	|	Download One Music Video"
Write-Host  "---------------------------------------------------------"
Write-Host "Choose number 1 or 2 or 3 ? " -ForegroundColor Red -NoNewline
$Option = Read-Host

Write-Host "`nLink : " -ForegroundColor Red -NoNewline
$Link = Read-Host


if ($Option -eq 1) {
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "			--> The best 1080p 'video only' and the best 'audio only' merged <--"

	yt-dlp -F $Link
	yt-dlp -S "res:1080,ext" -f "bv*+ba/b" $Link -o "$Path/%(title)s.%(ext)s"
}

# For Downloading Music Playlist
if ($Option -eq 2) {
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "		--> Download The best 'audio only' format (.m4a) Into A Separate Directory <--"

	yt-dlp -F $Link
	yt-dlp -f ba[ext=m4a] -o "$Path/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" $Link

} elseif ($Option -eq 3) {
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "				--> Download The Best 'audio only' format (.m4a) <--"

	yt-dlp -F $Link
	yt-dlp -f ba[ext=m4a] -o "$Path/%(title)s.%(ext)s" $Link

}
