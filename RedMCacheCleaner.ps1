#  PowerShell Script to Clear RedM Cache
#  This script automatically removes outdated cache folders from RedM to free up disk space and help prevent potential issues.
#  © Vedschyburger

# Automatically use the correct user path
$BasePath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "RedM\RedM.app\data"

# List of folders to be deleted
$FolderList = @("cache", "server-cache", "server-cache-priv")

# Go through each folder name
foreach ($Folder in $FolderList) {
    # Create full path
    $FullPath = Join-Path -Path $BasePath -ChildPath $Folder
    
    # Check whether the folder exists
    if (Test-Path -Path $FullPath) {
        # Delete folder with contents
        Remove-Item -Path $FullPath -Recurse -Force
        Write-Host "Folder deleted: $FullPath"
    } else {
        # Note if folder is missing
        Write-Host "Folder not found: $FullPath"
    }
}
