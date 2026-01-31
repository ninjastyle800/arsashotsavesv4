# Generate games data as JSON and update HTML

$savesDir = "c:\Users\Chris\Downloads\arsashots-saves-main\arsashots-saves-main\test"
$outputDir = "$savesDir\docs"

function Get-FileSizeStr {
    param([long]$size)
    if ($size -lt 1KB) { return "$size B" }
    elseif ($size -lt 1MB) { return "{0:N1} KB" -f ($size / 1KB) }
    elseif ($size -lt 1GB) { return "{0:N1} MB" -f ($size / 1MB) }
    else { return "{0:N1} GB" -f ($size / 1GB) }
}

function Build-FolderTree {
    param(
        [string]$folderPath
    )
    
    $folderData = @{
        'folders' = @{}
        'files' = @()
    }
    
    $items = Get-ChildItem -Path $folderPath -Force -ErrorAction SilentlyContinue
    
    # Group by directories and files
    $dirs = $items | Where-Object { $_.PSIsContainer }
    $files = $items | Where-Object { -not $_.PSIsContainer }
    
    # Process files in this folder
    foreach ($file in $files) {
        $relPath = (Resolve-Path -Path $file.FullName -Relative -RelativeBasePath $savesDir).Replace('.\', '').Replace('\', '/')
        # Prepend ../ to go up from docs folder
        $relPath = "../" + $relPath
        $folderData['files'] += @{
            'name' = $file.Name
            'path' = $relPath
            'size' = Get-FileSizeStr $file.Length
        }
    }
    
    # Process subdirectories recursively
    foreach ($dir in $dirs) {
        $subTree = Build-FolderTree -folderPath $dir.FullName
        $folderData['folders'][$dir.Name] = $subTree
    }
    
    return $folderData
}

Write-Host "Scanning saves directory..."
$games = @{}

$gameFolders = Get-ChildItem -Path $savesDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^docs$|node_modules|\.git' }

foreach ($gameFolder in $gameFolders) {
    Write-Host "Processing: $($gameFolder.Name)"
    $games[$gameFolder.Name] = Build-FolderTree -folderPath $gameFolder.FullName
}

# Convert to JSON
$gamesJson = $games | ConvertTo-Json -Depth 100

# Read the template HTML
$templatePath = "$outputDir\index.html"
$htmlContent = Get-Content -Path $templatePath -Raw

# Replace the placeholder with actual data
$htmlContent = $htmlContent -replace 'const gamesData = \{\};', "const gamesData = $gamesJson;"

# Write back
Set-Content -Path $templatePath -Value $htmlContent -Encoding UTF8

Write-Host "HTML generated successfully!"
