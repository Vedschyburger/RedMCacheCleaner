<#
.SYNOPSIS
    RedM Cache Cleaner (Western Edition)
    
.DESCRIPTION
    Räumt die RedM-Caches auf (cache, server-cache, server-cache-priv), 
    die oft für Sync-Fehler oder kaputte UI-Elemente verantwortlich sind. 
    Zeigt ein Custom Western-UI (WPF), killt blockierende CEF/RedM-Prozesse, 
    löscht die Ordner hartnäckig und wirft das Game danach direkt wieder an.
    
.AUTHOR
    Vedschyburger
    Website: https://guns.lol/vedschyburger
    
.NOTES
    Version:     1.0
    Voraussetzung: Windows, PowerShell (läuft automatisch im STA-Modus)
    Disclaimer:  Benutzung auf eigene Gefahr.
#>


$ErrorActionPreference = "SilentlyContinue"

if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-File", "`"$PSCommandPath`"") | Out-Null
    return
}

try {
    Add-Type -AssemblyName PresentationFramework

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RedM Cache Cleaner" Height="420" Width="640"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Topmost="True" WindowStyle="None" AllowsTransparency="True" Background="Transparent">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="20">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="#FF1A1108" CornerRadius="25" BorderBrush="#FF4F321C" BorderThickness="3">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Background="#FF4F321C" CornerRadius="10" Padding="10,8" Margin="0,0,0,15">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="★" FontSize="20" Foreground="#FFC19A6B" Margin="0,0,12,0"/>
                    <TextBlock Name="HeaderTxt" Text="OFFICIAL PROCLAMATION" FontSize="26" FontWeight="Bold" Foreground="#FFE8D9C1"/>
                    <TextBlock Text="★" FontSize="20" Foreground="#FFC19A6B" Margin="12,0,0,0"/>
                </StackPanel>
            </Border>
            
            <Border Grid.Row="1" Height="2" Background="#FFC19A6B" Margin="0,0,0,15"/>

            <Border Grid.Row="2" Background="#FFE8D9C1" BorderBrush="#FFC19A6B" BorderThickness="2" CornerRadius="15" Padding="15">
                <StackPanel>
                    <TextBlock Name="WarningTitleTxt" Text="⚠️ IMPORTANT NOTICE: REDM DATA CLEANSING" FontSize="17" FontWeight="Bold" Foreground="#FF1A1108" TextWrapping="Wrap" Margin="0,0,0,15"/>
                    <TextBlock Name="WarningBodyTxt" Foreground="#FF1A1108" FontSize="15" TextWrapping="Wrap" Margin="0,0,0,20" LineHeight="24">
                        Listen close, partners! This script sweeps the dust from your saddlebags. It clears the cache, server-cache, and server-cache-priv folders. Afterwards, RedM will be saddled up anew automatically.
                    </TextBlock>
                </StackPanel>
            </Border>

            <Grid Grid.Row="3" Margin="0,20,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Button Name="LangBtn" Grid.Column="0" Width="120" Height="42" Background="#FF2A1C11" Foreground="#FFC19A6B" BorderBrush="#FF4F321C" BorderThickness="2" FontSize="14" FontWeight="Bold" Cursor="Hand" Content="🌐 Deutsch"/>

                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="CancelBtn" Width="140" Height="42" Background="#FF8A3A2B" Foreground="White" BorderBrush="#FF5C231A" BorderThickness="2" FontSize="15" FontWeight="Bold" Cursor="Hand" Content="RETREAT"/>
                    <Button Name="OkBtn" Width="230" Height="42" Margin="15,0,0,0" Background="#FF327036" Foreground="White" BorderBrush="#FF234F26" BorderThickness="2" FontSize="15" FontWeight="Bold" Cursor="Hand" Content="SADDLE UP &amp; CLEAN ★"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($xaml)))
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Ermöglicht das Verschieben des fensterlosen Fensters
    $window.Add_MouseLeftButtonDown({ $window.DragMove() })

    $headerTxt = $window.FindName("HeaderTxt")
    $warningTitleTxt = $window.FindName("WarningTitleTxt")
    $warningBodyTxt = $window.FindName("WarningBodyTxt")
    $langBtn = $window.FindName("LangBtn")
    $okBtn = $window.FindName("OkBtn")
    $cancelBtn = $window.FindName("CancelBtn")

    $script:isEnglish = $true

    $langBtn.Add_Click({
            if ($script:isEnglish) {
                $headerTxt.Text = "AMTLICHE BEKANNTMACHUNG"
                $warningTitleTxt.Text = "⚠️ WICHTIGER HINWEIS: REDM DATENBEREINIGUNG"
                $warningBodyTxt.Text = "Hört gut zu, Kameraden! Dieses Script fegt den Staub aus Euren Satteltaschen. Es löscht die Ordner cache, server-cache und server-cache-priv. Im Anschluss wird RedM automatisch aufs Neue gesattelt."
                $okBtn.Content = "AUFSATTELN & BEREINIGEN"
                $cancelBtn.Content = "RÜCKZUG"
                $langBtn.Content = "🌐 English"
                $script:isEnglish = $false
            }
            else {
                $headerTxt.Text = "OFFICIAL PROCLAMATION"
                $warningTitleTxt.Text = "⚠️ IMPORTANT NOTICE: REDM DATA CLEANSING"
                $warningBodyTxt.Text = "Listen close, partners! This script sweeps the dust from your saddlebags. It clears the cache, server-cache, and server-cache-priv folders. Afterwards, RedM will be saddled up anew automatically."
                $okBtn.Content = "SADDLE UP & CLEAN"
                $cancelBtn.Content = "RETREAT"
                $langBtn.Content = "🌐 Deutsch"
                $script:isEnglish = $true
            }
        })

    $okBtn.Add_Click({ $window.DialogResult = $true; $window.Close() })
    $cancelBtn.Add_Click({ $window.DialogResult = $false; $window.Close() })

    if ($window.ShowDialog() -ne $true) { exit }
}
catch { exit }

# --- Bereinigungslogik ---
Get-Process "RedM", "CitizenFX", "CefSharp.BrowserSubprocess" | Stop-Process -Force
Start-Sleep -Milliseconds 500

$BaseDataPath = Join-Path $env:LOCALAPPDATA "RedM\RedM.app\data"
"cache", "server-cache", "server-cache-priv" | ForEach-Object {
    $p = Join-Path $BaseDataPath $_
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}

# Start RedM über Startmenü-Link
$lnk = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Filter "*RedM*.lnk" -Recurse | Select-Object -First 1
if ($lnk) { Start-Process $lnk.FullName }

exit
