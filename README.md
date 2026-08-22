# Windows-Scripting
Doing automation script on Windows using PowerShell.


> [!NOTE]
> **Before executing the scripts you must change the execution policy on running scripts on windows.**
>
> - `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser`
>   Allow it to run scripts only for current user.
>
> - `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`
>   Allow it to run scripts only for current session.

# `ChangeOutputDevice.ps1`
- Change output device from speaker to headphones or vice versa.
- Change the output device using the device ID.
- Uses the `AudioDeviceCmdlets` PowerShell module.

# `LSP.ps1`
- Install and configure common software tools used for local setup.
- Can auto-install supported apps via `winget`.
- Can activate Windows and Office licenses with the `-activation` option.
- Helps download and extract installers from Google Drive with `gdown` and WinRAR or 7-Zip.

# `OBS-BackgroundRemoval-Update.ps1`
- Download the latest OBS Background Removal installer from GitHub.
- Removes the previous installer before downloading a new one.
- Runs the installer automatically after download.

# `PrivateFolderAlias.ps1`
- Private PowerShell profile file for local folder aliases and custom commands.
- Stores machine-specific paths that should not be committed to Git.
- Dot-sourced from the main profile to expose custom shortcuts like `codefolder`, `docs`, and `obsidian`.

# `PrivateFolderAlias-Example.ps1`
- Example template for creating your own `PrivateFolderAlias.ps1`.
- Shows how to define custom aliases and path shortcuts for a personal environment.

# `RemoveBOM.ps1`
- Remove the UTF-8 BOM from `LSP.ps1` if it was added by an editor.
- Useful for keeping scripts consistent across systems and editors.

# `ResetTCPIP.ps1`
- Reset network-related TCP/IP and Winsock settings.
- Runs common `netsh` reset commands, IP release/renew, and DNS refresh.

# `ToggleAndLaunch.ps1`
- Toggle a Windows service on or off and optionally launch or close an application.
- Useful for service-based tools like VPN clients or productivity apps.

# `ToggleDNS.ps1`
- Toggle Cloudflare WARP connectivity by starting or stopping the service and app.
- Uses `warp-cli` to disconnect or reconnect the VPN.

# `VMwareScript.ps1`
- Start or stop required VMware services.
- Auto-launch predefined VMware virtual machines such as Fedora, Arch, Kali, or Windows.
- Can skip service toggling while only launching a VM.

# `Matrix.bat`
- Code for the classic Matrix-style terminal effect.
- A simple retro script created a long time ago.

# `WUReset.bat`
- Reset Windows Update and related network services.
- Useful when Windows Update or networking gets stuck.

# `AutoLaunchApp.ps1`
- Simple script for launching an app or toggling a startup-related workflow.
- Intended for quick app launch automation.

# `File-Share.ps1`
- Start a local file-sharing HTTP server and expose it via a Cloudflare tunnel.
- Uses `simple-http-server.exe` and `cloudflared.exe` to share a folder over the internet.

# `ScreenCopyUpdate.ps1`
- Update ScreenCopy (scrcpy) to the latest version.
- Uses GitHub's API to fetch the latest release tag and downloads the matching package.

# `NetSpeedMonitor.ps1`
- Monitor network upload and download speed in real time.
- Useful for checking network performance while transferring files.

# `Uninstaller.ps1`
- Uninstall default Windows applications.
- Can use `winget` or `Get-AppxPackage` based methods.
- Use [this](https://gist.github.com/ThioJoe/5cc29231c5cb1a8f051df28a69073f77) for `Get-AppxPackage` method

# `Microsoft.PowerShell_profile.ps1`
- Custom PowerShell profile configuration.
- Loads personal aliases and helper functions.
- Expects a `PrivateFolderAlias.ps1` file in the same directory as `$PROFILE`.

# `AutoHotKey/`
- Contains AutoHotkey scripts for desktop automation.
- Scripts are designed to work alongside `DesktopShortcut/`.

# `DesktopShortcut/`
- Contains desktop shortcut files for launching tools with keyboard shortcuts.
- Intended to improve workflow and quick access to apps.

# `SystemUpgrade`
### `SystemUpgrade.ps1`
- Update outdated PowerShell modules.
- Update Windows via the `PSWindowsUpdate` module.
- Update many installed apps with `winget` and `choco`.
- Scan for corrupted system files and repair them when possible.
- Clean unused files and folders to free up space.

### `SystemUpgrade-GUI.ps1`
- Same idea as `SystemUpgrade.ps1`, but with a simplified GUI and a focused "upgrade all" workflow.

### `SystemUpgradeV1.ps1`
- The older version of the system upgrade script.
- Kept for reference and should not be used as the main script.

### `MainWindow.xaml`
- XAML layout used by `SystemUpgrade-GUI.ps1`.

# `config/`
- Contains local configuration exports and settings files.
- Includes Windows Terminal and `winget` configuration examples.

# `html/`
- Contains simple HTML pages for local quick-access or media-related workflows.

# `yt-dlp/`
- Contains `yt-dlp` helper scripts and presets.
- Used for easier downloads and media automation with `yt-dlp`.
- Use `ytdlpscript.ps1`, for some reason `ytdlp-made-easy.ps1` does not work and is way to complicated


# `GB-to-MB Table Conversion.md`
- Quick reference for converting GB and MB values.
- Helpful when working with file sizes or download estimates.

# `scrcpy-noconsole.vbs`
- Launch `scrcpy` without showing a console window.
- Used with custom options for screen mirroring and control.

# `README.md`
- Repository overview and quick reference for the scripts and folders in this collection.