# Launch Spotify
& "${env:APPDATA}\Spotify\Spotify.exe"

# Launch Telegram
& "${env:APPDATA}\Telegram Desktop\Telegram.exe" -startintray

# Launch Firefox
& "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"

# Launch Obsidian
cmd /c start "" "%LOCALAPPDATA%\Programs\obsidian\Obsidian.exe"

# Launch UWP Apps (WhatsApp)
explorer.exe shell:appsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App

# Launch Discord as Administrator
Start-Process -FilePath "${env:LOCALAPPDATA}\Discord\Update.exe" -ArgumentList "--processStart Discord.exe" -Verb RunAs
