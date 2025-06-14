<#
## !COOL IDEA TO SHOW FORMAT BASED ON WHAT I ASKED FOR
Write-Output "ID      EXT   RESOLUTION FPS CH │   FILESIZE    TBR PROTO │ VCODEC           VBR ACODEC      ABR ASR MORE INFO"
> yt-dlp -F https://www.youtube.com/watch?v=qgv5KybY1L8 | Where-Object { $_ -match "video only" }

Downloads a youtube video using yt-dlp and stores it in the Downloads folder.
#>


if (!(Get-Command -Name yt-dlp)) {
	return "yt-dlp is not installed on your system or yt-dlp is not recognise as a command."
}

$Path = "~/Downloads"

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

yt-dlp -F $Link

if ($Option -eq 1) {
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	No	|	Prefered Resolution"
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	1.	| 	720p or HD (24/30/60 fps)"
	Write-Host  " 	2.	| 	1080p or FHD (24/30/60 fps)"
	Write-Host  " 	3. 	|	1440p or QHD or 2K (24/30/60 fps)"
	Write-Host  " 	4. 	|	2160p or UHD or 4K (24/30/60 fps)"
	Write-Host  "---------------------------------------------------------"
	Write-Host "Choose your prefered resolution ? " -ForegroundColor Red -NoNewline
	$ResolutionOption = Read-Host

	if ($ResolutionOption -eq 1) {
		$Resolution = "720p"
		$ResolutionFormat = "720"
	}
	elseif ($ResolutionOption -eq 2) {
		$Resolution = "1080p"
		$ResolutionFormat = "1080"
	}
	elseif ($ResolutionOption -eq 3) {
		$Resolution = "1440p"
		$ResolutionFormat = "1440"
	}
	elseif ($ResolutionOption -eq 4) {
		$Resolution = "2160p"
		$ResolutionFormat = "2160"
	}

	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "			--> The best $Resolution `"video only`" and the best `"audio only`" merged <--"

	$SortOption = "-S res:$ResolutionFormat,ext" # best
	$Format = "bestvideo+bestaudio/best --merge-output-format mp4" # best audio + best video merged into mp4
	# $Format = "bestvideo[ext=webm]+bestaudio[ext=webm] --merge-output-format mp4" # best audio (webm) + best video (webm) merged into mp4
	$OutputFormat = "$Path/%(title)s.%(ext)s"
}

# For Downloading Music Playlist
if ($Option -eq 2) {
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	No	|	Prefered File Format"
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	1.	| 	.m4a"
	Write-Host  " 	2.	| 	.mp3 (converted)"
	Write-Host  " 	3. 	|	.webm (I just want the best audio)"
	Write-Host  "---------------------------------------------------------"
	Write-Host "Choose your prefered file format ? " -ForegroundColor Red -NoNewline
	$FileOption = Read-Host

	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "		--> Download The best `"audio only`" Into A Separate Directory <--"

	if ($FileOption -eq 1) {
		Write-Host "File Format : .m4a"
		$Format = "ba[ext=m4a]" # best audio in .m4a
		$OutputFormat = "$Path/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
	}
	elseif ($FileOption -eq 2) {
		Write-Host "File Format : .mp3"
		$Format = "bestaudio -x --audio-format mp3 --audio-quality 0" # best audio converted to mp3
		$OutputFormat = "$Path/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
	}
	elseif ($FileOption -eq 3) {
		Write-Host "File Format : .webm"
		$Format = "bestaudio" # best audio.
		$OutputFormat = "$Path/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
	}

}
elseif ($Option -eq 3) {
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	No	|	Prefered File Format"
	Write-Host  "---------------------------------------------------------"
	Write-Host  " 	1.	| 	.m4a"
	Write-Host  " 	2.	| 	.mp3 (converted)"
	Write-Host  " 	3. 	|	.webm (I just want the best audio)"
	Write-Host  "---------------------------------------------------------"
	Write-Host "Choose your prefered file format ? " -ForegroundColor Red -NoNewline
	$FileOption = Read-Host

	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "					Automated YouTube Downloader Script Using YT-DLP"
	Write-Host "---------------------------------------------------------------------------------------------"
	Write-Host "				--> Download The Best `"audio only`" format <--"

	if ($FileOption -eq 1) {
		Write-Host "File Format : .m4a"
		$Format = "ba[ext=m4a]" # best audio in .m4a
		$OutputFormat = "$Path/%(title)s.%(ext)s"
	}
	elseif ($FileOption -eq 2) {
		Write-Host "File Format : .mp3"
		$Format = "bestaudio -x --audio-format mp3 --audio-quality 0" # best audio converted to mp3
		$OutputFormat = "$Path/%(title)s.%(ext)s"
	}
	elseif ($FileOption -eq 3) {
		Write-Host "File Format : .webm"
		$Format = "bestaudio" # best audio
		$OutputFormat = "$Path/%(title)s.%(ext)s"
	}
}

Write-Host "`nRun Command : " -ForegroundColor Red -NoNewline
Write-Host "yt-dlp --embed-chapters $SortOption -f $Format -o $OutputFormat $Link" -ForegroundColor Yellow

yt-dlp --embed-chapters $SortOption -f $Format -o $OutputFormat $Link