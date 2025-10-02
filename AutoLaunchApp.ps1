# Launch Spotify
& "${env:APPDATA}\Spotify\Spotify.exe"

# Launch Telegram
& "${env:APPDATA}\Telegram Desktop\Telegram.exe"

# Launch Firefox
& "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"

# Launch Obsidian
cmd /c start "" "%LOCALAPPDATA%\Programs\obsidian\Obsidian.exe"

# Launch UWP Apps (WhatsApp)
explorer.exe shell:appsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App

# Launch Discord
& "${env:LOCALAPPDATA}\Discord\Update.exe" --processStart Discord.exe
