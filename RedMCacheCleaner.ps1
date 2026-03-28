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
$ProgressPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"

# -------------------------------------------------------
# 1) WPF requires STA -> if not, restart script in STA
# -------------------------------------------------------
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process "powershell.exe" -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-STA",
        "-File", "`"$PSCommandPath`""
    ) | Out-Null
    return
}

# -------------------------------------------------------
# 2) Warning Dialog (Western Style)
# -------------------------------------------------------
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="RedM Cache Cleaner"
        Height="420" Width="640"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Topmost="True"
        Background="#FF1A1108" FontFamily="Palatino Linotype">
  <Grid Margin="20">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="#FF4F321C" CornerRadius="4" Padding="10,8" Margin="0,0,0,15">
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <TextBlock Text="★" FontSize="20" Foreground="#FFC19A6B" Margin="0,0,12,0"/>
            <TextBlock Name="HeaderTxt"
                       Text="OFFICIAL PROCLAMATION"
                       FontSize="26"
                       FontWeight="Bold"
                       Foreground="#FFE8D9C1"
                       HorizontalAlignment="Center"/>
            <TextBlock Text="★" FontSize="20" Foreground="#FFC19A6B" Margin="12,0,0,0"/>
        </StackPanel>
    </Border>
    
    <Border Grid.Row="1" Height="2" Background="#FFC19A6B" Margin="0,0,0,15"/>

    <Border Grid.Row="2" Background="#FFE8D9C1" BorderBrush="#FFC19A6B" BorderThickness="2" CornerRadius="6" Padding="15">
      <StackPanel>
        <TextBlock Name="WarningTitleTxt"
                   Text="⚠️ IMPORTANT NOTICE: REDM DATA CLEANSING"
                   FontSize="17"
                   FontWeight="Bold"
                   Foreground="#FF1A1108"
                   TextWrapping="Wrap"
                   Margin="0,0,0,15"/>
        <TextBlock Name="WarningBodyTxt"
                   Foreground="#FF1A1108" FontSize="15" TextWrapping="Wrap" Margin="0,0,0,20" LineHeight="24">
Listen close, partners! This script sweeps the dust from your saddlebags. It clears the cache, server-cache, and server-cache-priv folders. Afterwards, RedM will be saddled up anew automatically.
        </TextBlock>
        
        <TextBlock Name="HintTxt"
                   Foreground="#FF4F321C" FontSize="14" FontStyle="Italic">
OK = CLEAN &amp; SADDLE UP
Cancel or X = Stay at the Saloon (Change nothing)
        </TextBlock>
      </StackPanel>
    </Border>

    <Grid Grid.Row="3" Margin="0,20,0,0">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Button Name="LangBtn"
              Grid.Column="0"
              Width="120" Height="42"
              Background="#FF2A1C11"
              Foreground="#FFC19A6B"
              BorderBrush="#FF4F321C" BorderThickness="2"
              FontSize="14" FontWeight="Bold"
              Cursor="Hand"
              Content="🌐 Deutsch"/>

      <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
        <Button Name="CancelBtn"
                Width="160" Height="42"
                Background="#FF8A3A2B"
                Foreground="#FFFFFFFF"
                BorderBrush="#FF5C231A" BorderThickness="2"
                FontSize="15" FontWeight="Bold"
                Cursor="Hand"
                Content="RETREAT"/>
        <Button Name="OkBtn"
                Width="250" Height="42"
                Margin="15,0,0,0"
                Background="#FF327036"
                Foreground="#FFFFFFFF"
                BorderBrush="#FF234F26" BorderThickness="2"
                FontSize="15" FontWeight="Bold"
                Cursor="Hand"
                Content="SADDLE UP &amp; CLEAN ★"/>
      </StackPanel>
    </Grid>
  </Grid>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($xaml)))
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Grab UI Elements
    $headerTxt = $window.FindName("HeaderTxt")
    $warningTitleTxt = $window.FindName("WarningTitleTxt")
    $warningBodyTxt = $window.FindName("WarningBodyTxt")
    $hintTxt = $window.FindName("HintTxt")
    
    $langBtn = $window.FindName("LangBtn")
    $okBtn = $window.FindName("OkBtn")
    $cancelBtn = $window.FindName("CancelBtn")

    # State
    $script:isEnglish = $true

    # Language Toggle Event
    $langBtn.Add_Click({
            if ($script:isEnglish) {
                # Switch to German
                $headerTxt.Text = "AMTLICHE BEKANNTMACHUNG"
                $warningTitleTxt.Text = "⚠️ WICHTIGER HINWEIS: REDM DATENBEREINIGUNG"
                $warningBodyTxt.Text = "Hört gut zu, Kameraden! Dieses Script fegt den Staub aus Euren Satteltaschen. Es löscht die Ordner cache, server-cache und server-cache-priv. Im Anschluss wird RedM automatisch aufs Neue gesattelt."
                $hintTxt.Text = "OK = BEREINIGEN & AUFSATTELN`nAbbrechen oder X = Im Saloon verweilen (Nichts ändern)"
                $okBtn.Content = "AUFSATTELN & BEREINIGEN ★"
                $cancelBtn.Content = "RÜCKZUG"
                $langBtn.Content = "🌐 English"
                $script:isEnglish = $false
            }
            else {
                # Switch to English
                $headerTxt.Text = "OFFICIAL PROCLAMATION"
                $warningTitleTxt.Text = "⚠️ IMPORTANT NOTICE: REDM DATA CLEANSING"
                $warningBodyTxt.Text = "Listen close, partners! This script sweeps the dust from your saddlebags. It clears the cache, server-cache, and server-cache-priv folders. Afterwards, RedM will be saddled up anew automatically."
                $hintTxt.Text = "OK = CLEAN & SADDLE UP`nCancel or X = Stay at the Saloon (Change nothing)"
                $okBtn.Content = "SADDLE UP & CLEAN ★"
                $cancelBtn.Content = "RETREAT"
                $langBtn.Content = "🌐 Deutsch"
                $script:isEnglish = $true
            }
        })

    # Action Events
    $okBtn.Add_Click({ $window.DialogResult = $true; $window.Close() })
    $cancelBtn.Add_Click({ $window.DialogResult = $false; $window.Close() })

    $result = $window.ShowDialog()
    if ($result -ne $true) { return }
}
catch {
    return
}

# -------------------------------------------------------
# 3) Delete cache (robust, silent)
# -------------------------------------------------------

function Stop-IfRunning {
    param([Parameter(Mandatory)][string[]]$ProcessNames)

    foreach ($name in $ProcessNames) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
            try { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

function Remove-PathRobust {
    param(
        [Parameter(Mandatory)][string]$Path,
        [int]$Retries = 8,
        [int]$DelayMs = 250
    )

    for ($i = 1; $i -le $Retries; $i++) {
        if (-not (Test-Path -LiteralPath $Path)) { return }

        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            Start-Sleep -Milliseconds $DelayMs
        }
    }

    try {
        if (Test-Path -LiteralPath $Path) {
            Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {}
}

Stop-IfRunning -ProcessNames @("RedM", "CitizenFX", "CefSharp.BrowserSubprocess")
Start-Sleep -Milliseconds 400

$BaseDataPath = Join-Path $env:LOCALAPPDATA "RedM\RedM.app\data"
$FoldersToDelete = @("cache", "server-cache", "server-cache-priv")

foreach ($folder in $FoldersToDelete) {
    $full = Join-Path $BaseDataPath $folder
    Remove-PathRobust -Path $full
}

# -------------------------------------------------------
# 4) Start RedM
# -------------------------------------------------------
$StartMenuPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
)

function Start-App {
    param([Parameter(Mandatory = $true)][string]$NameLike)

    foreach ($path in $StartMenuPaths) {
        if (-not (Test-Path $path)) { continue }

        $lnk = Get-ChildItem -Path $path -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -like "*$NameLike*" } |
        Select-Object -First 1

        if ($lnk) {
            Start-Process -FilePath $lnk.FullName -ErrorAction SilentlyContinue
            return
        }
    }
}

Start-App "RedM"
Start-Sleep 1

exit
