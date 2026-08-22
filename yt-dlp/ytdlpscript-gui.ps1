<#
.SYNOPSIS
    Graphical User Interface for yt-dlp media downloader.

.DESCRIPTION
    A modern WPF GUI based on ytdlpscript.ps1. Allows downloading videos in various resolutions 
    (720p, 1080p, 1440p, 2160p, Highest) and audio/music files in multiple formats (.m4a, .mp3, .webm),
    with full embedding options, custom output folder, and live console logging.

.EXAMPLE
    .\ytdlpscript-gui.ps1
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# --- XAML UI Definition ---
$inputXAML = @"
<Window x:Name="window"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="yt-dlp Downloader GUI" Height="800" Width="760"
        WindowStartupLocation="CenterScreen"
        Background="#1C1C1C" Foreground="#FFFFFF"
        FontFamily="Segoe UI Variable Text, Segoe UI, sans-serif">

    <Window.Resources>
        <!-- Modern Card Style -->
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="Background" Value="#272727"/>
            <Setter Property="BorderBrush" Value="#383838"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="20,16"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
        </Style>

        <!-- Modern Section Header Style -->
        <Style x:Key="SectionHeader" TargetType="TextBlock">
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#0078D4"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
        </Style>

        <!-- Modern Label Style -->
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#DDDDDD"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="0,0,0,4"/>
        </Style>

        <!-- Modern TextBox Style -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#444444"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <!-- Modern ComboBox Style -->
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderBrush" Value="#444444"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <!-- Modern CheckBox Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#EEEEEE"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6,0,6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <!-- Modern RadioButton Style -->
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#EEEEEE"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6,12,6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <!-- Modern Primary Button Style -->
        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="btnBorder" Background="{TemplateBinding Background}" 
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBorder" Property="Background" Value="#106EBE"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="btnBorder" Property="Background" Value="#005A9E"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="btnBorder" Property="Background" Value="#444444"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button Style -->
        <Style x:Key="SecondaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#555555"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="btnBorder" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBorder" Property="Background" Value="#444444"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="btnBorder" Property="Background" Value="#222222"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="btnBorder" Property="Background" Value="#2D2D2D"/>
                                <Setter Property="Foreground" Value="#666666"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- Header Title Section -->
        <StackPanel Grid.Row="0" Margin="0,0,0,16">
            <Label x:Name="TitleLabel" Content="yt-dlp Media Downloader" 
                   FontSize="24" FontWeight="Bold" Foreground="#FFFFFF" Padding="0" Margin="0,0,0,4"/>
            <TextBlock Text="Automated video and audio downloader script GUI powered by yt-dlp." 
                       FontSize="13" Foreground="#999999"/>
        </StackPanel>

        <!-- Main Content Options Area -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Focusable="False" Margin="0,0,0,6">
            <StackPanel>
                <!-- Card 1: URL & Output Path -->
                <Border Style="{StaticResource CardBorder}">
                    <StackPanel>
                        <TextBlock Text="Target &amp; Output Directory" Style="{StaticResource SectionHeader}"/>
                        
                        <Label Content="Media URL / Link:" Target="{Binding ElementName=UrlTextBox}"/>
                        <TextBox x:Name="UrlTextBox" Margin="0,0,0,12" Height="32"/>

                        <Label Content="Save Directory:" Target="{Binding ElementName=OutputPathTextBox}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="OutputPathTextBox" Grid.Column="0" Height="32" Margin="0,0,8,0"/>
                            <Button x:Name="BrowseButton" Grid.Column="1" Content="Browse..." 
                                    Style="{StaticResource SecondaryButtonStyle}" Width="90" Height="32"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Card 2: Download Mode & Options -->
                <Border Style="{StaticResource CardBorder}">
                    <StackPanel>
                        <TextBlock Text="Download Mode &amp; Quality" Style="{StaticResource SectionHeader}"/>
                        
                        <!-- Mode Selection -->
                        <Label Content="Select Mode:"/>
                        <WrapPanel Margin="0,2,0,12">
                            <RadioButton x:Name="RadioVideo" Content="1. Download A Video" IsChecked="True"/>
                            <RadioButton x:Name="RadioMusicPlaylist" Content="2. Download Music Playlist"/>
                            <RadioButton x:Name="RadioSingleMusic" Content="3. Download One Music Video"/>
                        </WrapPanel>

                        <Grid Margin="0,4,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Video Resolution Options -->
                            <StackPanel x:Name="PanelVideoRes" Grid.Column="0" Margin="0,0,8,0">
                                <Label Content="Preferred Resolution:"/>
                                <ComboBox x:Name="ComboResolution" Height="32" SelectedIndex="1">
                                    <ComboBoxItem Content="720p or HD (24/30/60 fps)"/>
                                    <ComboBoxItem Content="1080p or FHD (24/30/60 fps)"/>
                                    <ComboBoxItem Content="1440p or QHD / 2K (24/30/60 fps)"/>
                                    <ComboBoxItem Content="2160p or UHD / 4K (24/30/60 fps)"/>
                                    <ComboBoxItem Content="Highest / Best Available"/>
                                </ComboBox>
                            </StackPanel>

                            <!-- Audio Format Options -->
                            <StackPanel x:Name="PanelAudioFormat" Grid.Column="1" Margin="8,0,0,0" IsEnabled="False">
                                <Label Content="Preferred File Format:"/>
                                <ComboBox x:Name="ComboAudioFormat" Height="32" SelectedIndex="0">
                                    <ComboBoxItem Content="1. .m4a (Native Best AAC)"/>
                                    <ComboBoxItem Content="2. .mp3 (Converted Best Quality)"/>
                                    <ComboBoxItem Content="3. .webm (Best Audio Only)"/>
                                </ComboBox>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Card 3: Additional Embedding Options -->
                <Border Style="{StaticResource CardBorder}">
                    <StackPanel>
                        <TextBlock Text="Embedding &amp; Metadata Switches" Style="{StaticResource SectionHeader}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <CheckBox x:Name="ChkEmbedChapters" Grid.Column="0" Content="Embed Chapters" IsChecked="True"/>
                            <CheckBox x:Name="ChkEmbedThumbnail" Grid.Column="1" Content="Embed Thumbnail" IsChecked="True"/>
                            <CheckBox x:Name="ChkEmbedSubs" Grid.Column="2" Content="Embed Subtitles" IsChecked="True"/>
                        </Grid>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Status & Console Output Section -->
        <Grid Grid.Row="2" Margin="0,0,0,12">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Text="Console Output" FontSize="13" FontWeight="SemiBold" Foreground="#0078D4" Margin="0,0,0,6"/>
            <Border Grid.Row="1" Background="#111111" BorderBrush="#383838" BorderThickness="1" CornerRadius="6" MinHeight="130" Margin="0,0,0,8" Padding="8">
                <TextBox x:Name="OutputTextBox" Background="Transparent" Foreground="#D4D4D4" BorderThickness="0" 
                         FontFamily="Consolas, Courier New, monospace" FontSize="12" AcceptsReturn="True" 
                         TextWrapping="Wrap" IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                         HorizontalScrollBarVisibility="Disabled" VerticalAlignment="Stretch"/>
            </Border>

            <Label Grid.Row="2" x:Name="RunningTask" Content="Ready" 
                   Foreground="#CCCCCC" FontSize="13" FontWeight="Medium" Padding="0,0,0,6" HorizontalAlignment="Left"/>
            <Border Grid.Row="3" Background="#2D2D2D" CornerRadius="3" Height="6" ClipToBounds="True">
                <ProgressBar x:Name="ProgressBar" Height="6" Background="Transparent" Foreground="#0078D4" 
                             BorderThickness="0" IsIndeterminate="False" Minimum="0" Maximum="100" Value="0"/>
            </Border>
        </Grid>

        <!-- Action Bar -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Button x:Name="ListFormatsButton" Grid.Column="0" Style="{StaticResource SecondaryButtonStyle}" 
                    Content="List Available Formats (-F)" Width="200" Height="38" Padding="12,0"/>

            <Button x:Name="StartButton" Grid.Column="2" Style="{StaticResource PrimaryButtonStyle}" 
                    Content="Start Download" Width="180" Height="38" Padding="12,0"/>
        </Grid>
    </Grid>
</Window>
"@

# Clean xaml attributes that cause PowerShell WPF XamlReader exceptions
$cleanXAML = $inputXAML -replace 'mc:Ignorable="d"', '' -replace 'x:N', 'N' -replace 'x:Class="[^"]+"', ''
[XML]$XAML = $cleanXAML

$Reader = New-Object System.Xml.XmlNodeReader $XAML

try {
    $PSForm = [Windows.Markup.XamlReader]::Load($Reader)
}
catch {
    Write-Host "Failed to load XAML: $_" -ForegroundColor Red
    throw
}

# Bind XAML controls with 'var_' prefix variables
$XAML.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name "var_$($_.Name)" -Value $PSForm.FindName($_.Name) -ErrorAction SilentlyContinue
}

# Set Default Output Folder to user Downloads
$defaultDownloadsPath = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
if ($var_OutputPathTextBox) {
    $var_OutputPathTextBox.Text = $defaultDownloadsPath
}

# --- Helper Functions ---
function Add-OutputText {
    param([string]$text)
    Write-Host $text
    if ($var_OutputTextBox) {
        $var_OutputTextBox.AppendText($text + "`r`n")
        $var_OutputTextBox.ScrollToEnd()
        if ($PSForm.Dispatcher) {
            $PSForm.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    }
}

function Set-TaskProgress {
    param(
        [string]$TaskName,
        [double]$Value,
        [bool]$IsIndeterminate = $false
    )
    if ($var_RunningTask) { $var_RunningTask.Content = $TaskName }
    if ($var_ProgressBar) {
        $var_ProgressBar.IsIndeterminate = $IsIndeterminate
        $var_ProgressBar.Value = $Value
    }
    if ($PSForm.Dispatcher) {
        $PSForm.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }
}

function Set-ControlsEnabled {
    param([bool]$enabled)
    $var_StartButton.IsEnabled = $enabled
    $var_ListFormatsButton.IsEnabled = $enabled
    $var_BrowseButton.IsEnabled = $enabled
    $var_UrlTextBox.IsEnabled = $enabled
    $var_OutputPathTextBox.IsEnabled = $enabled
    $var_RadioVideo.IsEnabled = $enabled
    $var_RadioMusicPlaylist.IsEnabled = $enabled
    $var_RadioSingleMusic.IsEnabled = $enabled
    $var_ComboResolution.IsEnabled = $enabled -and $var_RadioVideo.IsChecked
    $var_ComboAudioFormat.IsEnabled = $enabled -and (-not $var_RadioVideo.IsChecked)
    $var_ChkEmbedChapters.IsEnabled = $enabled
    $var_ChkEmbedThumbnail.IsEnabled = $enabled
    $var_ChkEmbedSubs.IsEnabled = $enabled
}

# --- Event Handlers ---

# Radio Button Change Handlers for Mode Selection
$var_RadioVideo.add_Checked({
    if ($var_PanelVideoRes) { $var_PanelVideoRes.IsEnabled = $true }
    if ($var_PanelAudioFormat) { $var_PanelAudioFormat.IsEnabled = $false }
})

$var_RadioMusicPlaylist.add_Checked({
    if ($var_PanelVideoRes) { $var_PanelVideoRes.IsEnabled = $false }
    if ($var_PanelAudioFormat) { $var_PanelAudioFormat.IsEnabled = $true }
})

$var_RadioSingleMusic.add_Checked({
    if ($var_PanelVideoRes) { $var_PanelVideoRes.IsEnabled = $false }
    if ($var_PanelAudioFormat) { $var_PanelAudioFormat.IsEnabled = $true }
})

# Browse Folder Button
$var_BrowseButton.add_Click({
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.BrowseForFolder(0, "Select Destination Folder for Downloads", 0, $var_OutputPathTextBox.Text)
    if ($folder) {
        $var_OutputPathTextBox.Text = $folder.Self.Path
    }
})

# Execute Process with Live Output Logging
function Invoke-YtDlpProcess {
    param(
        [string[]]$ArgumentArray
    )

    if (-not (Get-Command -Name "yt-dlp" -ErrorAction SilentlyContinue)) {
        [System.Windows.MessageBox]::Show("yt-dlp is not installed on your system or not recognized as a command in PATH.", "yt-dlp Not Found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        Add-OutputText "ERROR: yt-dlp is not installed on your system or not recognized in PATH."
        return
    }

    Set-ControlsEnabled -enabled $false
    Set-TaskProgress -TaskName "Running yt-dlp..." -Value 0 -IsIndeterminate $true

    $cmdLineDisplay = "yt-dlp " + ($ArgumentArray -join " ")
    Add-OutputText "`r`n---------------------------------------------------------------------------------------------"
    Add-OutputText "Run Command : $cmdLineDisplay"
    Add-OutputText "---------------------------------------------------------------------------------------------`r`n"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "yt-dlp"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    # Build argument string preserving quoted arguments
    $argString = ""
    foreach ($arg in $ArgumentArray) {
        if ($arg -match '\s' -and -not ($arg.StartsWith('"') -and $arg.EndsWith('"'))) {
            $argString += " `"$arg`""
        } else {
            $argString += " $arg"
        }
    }
    $psi.Arguments = $argString.Trim()

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        $process.Start() | Out-Null
    }
    catch {
        Add-OutputText "Error running yt-dlp process: $_"
        Set-ControlsEnabled -enabled $true
        Set-TaskProgress -TaskName "Error running process" -Value 0 -IsIndeterminate $false
        return
    }

    # Poll both streams on the WPF UI thread so output is live without cross-runspace callbacks.
    $script:ActiveYtDlpProcess = $process
    $script:YtDlpOutputTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:YtDlpOutputTimer.Interval = [TimeSpan]::FromMilliseconds(75)
    $script:YtDlpOutputTimer.add_Tick({
        $activeProcess = $script:ActiveYtDlpProcess
        if (-not $activeProcess) { return }

        while ($activeProcess.StandardOutput.Peek() -ge 0) {
            $line = $activeProcess.StandardOutput.ReadLine()
            if ($line) { Add-OutputText $line }
        }
        while ($activeProcess.StandardError.Peek() -ge 0) {
            $line = $activeProcess.StandardError.ReadLine()
            if ($line) { Add-OutputText $line }
        }

        if ($activeProcess.HasExited) {
            while (-not $activeProcess.StandardOutput.EndOfStream) {
                $line = $activeProcess.StandardOutput.ReadLine()
                if ($line) { Add-OutputText $line }
            }
            while (-not $activeProcess.StandardError.EndOfStream) {
                $line = $activeProcess.StandardError.ReadLine()
                if ($line) { Add-OutputText $line }
            }

            $script:YtDlpOutputTimer.Stop()
            $exitCode = $activeProcess.ExitCode
            $script:ActiveYtDlpProcess = $null

            if ($exitCode -eq 0) {
                Set-TaskProgress -TaskName "Completed successfully!" -Value 100 -IsIndeterminate $false
                Add-OutputText "`r`nProcess completed successfully."
            } else {
                Set-TaskProgress -TaskName "Process finished with error code $exitCode" -Value 0 -IsIndeterminate $false
                Add-OutputText "`r`nProcess exited with code $exitCode."
            }

            Set-ControlsEnabled -enabled $true
            $activeProcess.Dispose()
        }
    })
    $script:YtDlpOutputTimer.Start()
}

# List Available Formats Button Handler (-F)
$var_ListFormatsButton.add_Click({
    $url = $var_UrlTextBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.MessageBox]::Show("Please enter a valid URL / Link.", "URL Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $var_OutputTextBox.Clear()
    Add-OutputText "Fetching available formats for URL: $url ..."

    $arguments = @("-F", $url)
    Invoke-YtDlpProcess -ArgumentArray $arguments
})

# Start Download Button Handler
$var_StartButton.add_Click({
    $url = $var_UrlTextBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.MessageBox]::Show("Please enter a valid URL / Link.", "URL Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $savePath = $var_OutputPathTextBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($savePath)) {
        $savePath = $defaultDownloadsPath
    }

    # Normalize path separators
    $savePath = $savePath.Replace("\", "/")

    # Build argument array based on selected options in ytdlpscript.ps1
    $arguments = [System.Collections.Generic.List[string]]::new()

    # Switches
    if ($var_ChkEmbedChapters.IsChecked) { $arguments.Add("--embed-chapters") }
    if ($var_ChkEmbedThumbnail.IsChecked) { $arguments.Add("--embed-thumbnail") }
    if ($var_ChkEmbedSubs.IsChecked) { $arguments.Add("--embed-subs") }

    # Option 1: Download A Video
    if ($var_RadioVideo.IsChecked) {
        $resIdx = $var_ComboResolution.SelectedIndex
        switch ($resIdx) {
            0 { # 720p
                $arguments.Add("-S")
                $arguments.Add("res:720,ext")
                $arguments.Add("-f")
                $arguments.Add("bestvideo[height<=720]+bestaudio/best")
                $arguments.Add("--merge-output-format")
                $arguments.Add("mp4")
            }
            1 { # 1080p
                $arguments.Add("-S")
                $arguments.Add("res:1080,ext")
                $arguments.Add("-f")
                $arguments.Add("bestvideo[height<=1080]+bestaudio/best")
                $arguments.Add("--merge-output-format")
                $arguments.Add("mp4")
            }
            2 { # 1440p / 2K
                $arguments.Add("-S")
                $arguments.Add("res:1440,ext")
                $arguments.Add("-f")
                $arguments.Add("bestvideo[height<=1440]+bestaudio/best")
                $arguments.Add("--merge-output-format")
                $arguments.Add("mp4")
            }
            3 { # 2160p / 4K
                $arguments.Add("-S")
                $arguments.Add("res:2160,ext")
                $arguments.Add("-f")
                $arguments.Add("bestvideo[height<=2160]+bestaudio/best")
                $arguments.Add("--merge-output-format")
                $arguments.Add("mp4")
            }
            4 { # Highest
                $arguments.Add("-f")
                $arguments.Add("bestvideo+bestaudio/best")
                $arguments.Add("--merge-output-format")
                $arguments.Add("mp4")
            }
        }

        $outputTemplate = "$savePath/%(title)s.%(ext)s"
        $arguments.Add("-o")
        $arguments.Add($outputTemplate)
    }
    # Option 2: Download Music Playlist Video
    elseif ($var_RadioMusicPlaylist.IsChecked) {
        $fileOptionIdx = $var_ComboAudioFormat.SelectedIndex
        switch ($fileOptionIdx) {
            0 { # .m4a
                $arguments.Add("-f")
                $arguments.Add("ba[ext=m4a]")
            }
            1 { # .mp3
                $arguments.Add("-f")
                $arguments.Add("bestaudio")
                $arguments.Add("-x")
                $arguments.Add("--audio-format")
                $arguments.Add("mp3")
                $arguments.Add("--audio-quality")
                $arguments.Add("0")
            }
            2 { # .webm
                $arguments.Add("-f")
                $arguments.Add("bestaudio")
            }
        }

        $outputTemplate = "$savePath/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
        $arguments.Add("-o")
        $arguments.Add($outputTemplate)
    }
    # Option 3: Download One Music Video
    elseif ($var_RadioSingleMusic.IsChecked) {
        $fileOptionIdx = $var_ComboAudioFormat.SelectedIndex
        switch ($fileOptionIdx) {
            0 { # .m4a
                $arguments.Add("-f")
                $arguments.Add("ba[ext=m4a]")
            }
            1 { # .mp3
                $arguments.Add("-f")
                $arguments.Add("bestaudio")
                $arguments.Add("-x")
                $arguments.Add("--audio-format")
                $arguments.Add("mp3")
                $arguments.Add("--audio-quality")
                $arguments.Add("0")
            }
            2 { # .webm
                $arguments.Add("-f")
                $arguments.Add("bestaudio")
            }
        }

        $outputTemplate = "$savePath/%(title)s.%(ext)s"
        $arguments.Add("-o")
        $arguments.Add($outputTemplate)
    }

    # Add Target URL
    $arguments.Add($url)

    $var_OutputTextBox.Clear()
    Add-OutputText "Starting download..."
    Invoke-YtDlpProcess -ArgumentArray $arguments.ToArray()
})

# Display GUI Window
$null = $PSForm.ShowDialog()
