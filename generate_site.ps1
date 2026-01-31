# PowerShell script to generate the website

$savesDir = ".\arsashots-saves-main\arsashot-saves"
$outputDir = ".\docs"

if (-not (Test-Path $savesDir)) {
    Write-Host "Error: Saves directory not found at $savesDir"
    exit 1
}

Write-Host "Scanning saves directory: $savesDir"

# Build the games structure
$games = @{}

Get-ChildItem -Path $savesDir -Directory | ForEach-Object {
    $gameName = $_.Name
    $gamePath = $_.FullName
    
    $games[$gameName] = @{
        'subcategories' = @{}
        'files' = @()
    }
    
    # Scan for files recursively
    Get-ChildItem -Path $gamePath -Recurse -File | ForEach-Object {
        $file = $_
        $relativePath = (Resolve-Path -Path $file.FullName -Relative) -replace '^\.\\'
        
        # Get file size
        $size = $file.Length
        if ($size -lt 1KB) {
            $sizeStr = "$size B"
        } elseif ($size -lt 1MB) {
            $sizeStr = "{0:N1} KB" -f ($size / 1KB)
        } elseif ($size -lt 1GB) {
            $sizeStr = "{0:N1} MB" -f ($size / 1MB)
        } else {
            $sizeStr = "{0:N1} GB" -f ($size / 1GB)
        }
        
        $parentDir = Split-Path -Path $file.FullName -Parent
        $subcatPath = (Resolve-Path -Path $parentDir -Relative) -replace '^\.\\'
        
        if ($parentDir -ne $gamePath) {
            $subcat = Split-Path -Path $parentDir -Leaf
            if ($subcat) {
                if (-not $games[$gameName]['subcategories'].ContainsKey($subcat)) {
                    $games[$gameName]['subcategories'][$subcat] = @()
                }
                $games[$gameName]['subcategories'][$subcat] += @{
                    'name' = $file.Name
                    'path' = $relativePath -replace '\\', '/'
                    'size' = $sizeStr
                }
            }
        } else {
            $games[$gameName]['files'] += @{
                'name' = $file.Name
                'path' = $relativePath -replace '\\', '/'
                'size' = $sizeStr
            }
        }
    }
}

Write-Host "Found $($games.Count) games"

# Create output directory
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Convert games to JSON
$gamesJson = ConvertTo-Json -InputObject $games -Depth 10

# Read and create the HTML file
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Game Saves Download Center</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
            animation: slideDown 0.5s ease-out;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        header p {
            font-size: 1.1em;
            opacity: 0.95;
        }
        
        .search-box {
            margin: 30px 0;
            text-align: center;
        }
        
        .search-box input {
            width: 100%;
            max-width: 400px;
            padding: 12px 20px;
            font-size: 1em;
            border: none;
            border-radius: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .games-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        
        .game-card {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            animation: slideUp 0.5s ease-out;
        }
        
        .game-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 40px rgba(0,0,0,0.2);
        }
        
        .game-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            user-select: none;
            position: relative;
        }
        
        .game-header h2 {
            font-size: 1.3em;
            flex: 1;
        }
        
        .toggle-icon {
            font-size: 1.5em;
            transition: transform 0.3s ease;
        }
        
        .game-card.expanded .toggle-icon {
            transform: rotate(180deg);
        }
        
        .game-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease;
        }
        
        .game-card.expanded .game-content {
            max-height: 1000px;
        }
        
        .game-files {
            padding: 20px;
        }
        
        .subcategory {
            margin-bottom: 20px;
        }
        
        .subcategory-title {
            font-weight: bold;
            color: #667eea;
            margin-bottom: 10px;
            font-size: 0.9em;
        }
        
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        
        .file-item:last-child {
            border-bottom: none;
        }
        
        .file-name {
            flex: 1;
            color: #333;
            font-size: 0.9em;
            word-break: break-all;
        }
        
        .file-info {
            display: flex;
            gap: 12px;
            align-items: center;
            margin-left: 12px;
        }
        
        .file-size {
            color: #999;
            font-size: 0.85em;
            min-width: 60px;
            text-align: right;
        }
        
        .download-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 6px 14px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.85em;
            transition: opacity 0.2s;
        }
        
        .download-btn:hover {
            opacity: 0.85;
        }
        
        .hidden {
            display: none;
        }
        
        .no-results {
            text-align: center;
            padding: 40px;
            color: white;
            font-size: 1.2em;
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        footer {
            text-align: center;
            color: white;
            margin-top: 40px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🎮 Game Saves Download Center</h1>
            <p>Browse and download your favorite game save files</p>
        </header>
        
        <div class="search-box">
            <input type="text" id="searchInput" placeholder="Search games..." />
        </div>
        
        <div class="games-grid" id="gamesGrid">
            <!-- Games will be inserted here -->
        </div>
        
        <div class="no-results hidden" id="noResults">
            No games found matching your search.
        </div>
        
        <footer>
            <p>✨ Created with ❤️ for game saves | Powered by GitHub Pages</p>
        </footer>
    </div>
    
    <script>
        const gamesData = $gamesJson;
        
        function createGameCard(gameName, gameData) {
            const card = document.createElement('div');
            card.className = 'game-card';
            card.dataset.gameName = gameName.toLowerCase();
            
            const header = document.createElement('div');
            header.className = 'game-header';
            
            const title = document.createElement('h2');
            title.textContent = gameName;
            header.appendChild(title);
            
            const fileCount = Object.keys(gameData.subcategories).reduce((sum, k) => sum + gameData.subcategories[k].length, 0) + gameData.files.length;
            const subText = document.createElement('div');
            subText.style.fontSize = '0.85em';
            subText.style.opacity = '0.9';
            subText.style.marginRight = '20px';
            subText.textContent = fileCount + ' file' + (fileCount !== 1 ? 's' : '');
            header.appendChild(subText);
            
            const toggleIcon = document.createElement('span');
            toggleIcon.className = 'toggle-icon';
            toggleIcon.textContent = '▼';
            header.appendChild(toggleIcon);
            
            const content = document.createElement('div');
            content.className = 'game-content';
            
            const filesDiv = document.createElement('div');
            filesDiv.className = 'game-files';
            
            // Add subcategories
            for (const [subcat, files] of Object.entries(gameData.subcategories)) {
                const subcatDiv = document.createElement('div');
                subcatDiv.className = 'subcategory';
                
                const subcatTitle = document.createElement('div');
                subcatTitle.className = 'subcategory-title';
                subcatTitle.textContent = subcat;
                subcatDiv.appendChild(subcatTitle);
                
                files.forEach(file => {
                    const fileItem = document.createElement('div');
                    fileItem.className = 'file-item';
                    
                    const fileName = document.createElement('div');
                    fileName.className = 'file-name';
                    fileName.textContent = file.name;
                    
                    const fileInfo = document.createElement('div');
                    fileInfo.className = 'file-info';
                    
                    const fileSize = document.createElement('div');
                    fileSize.className = 'file-size';
                    fileSize.textContent = file.size;
                    
                    const downloadBtn = document.createElement('a');
                    downloadBtn.className = 'download-btn';
                    downloadBtn.href = file.path;
                    downloadBtn.download = file.name;
                    downloadBtn.textContent = 'Download';
                    downloadBtn.target = '_blank';
                    
                    fileInfo.appendChild(fileSize);
                    fileInfo.appendChild(downloadBtn);
                    
                    fileItem.appendChild(fileName);
                    fileItem.appendChild(fileInfo);
                    
                    subcatDiv.appendChild(fileItem);
                });
                
                filesDiv.appendChild(subcatDiv);
            }
            
            // Add root level files
            if (gameData.files.length > 0) {
                gameData.files.forEach(file => {
                    const fileItem = document.createElement('div');
                    fileItem.className = 'file-item';
                    
                    const fileName = document.createElement('div');
                    fileName.className = 'file-name';
                    fileName.textContent = file.name;
                    
                    const fileInfo = document.createElement('div');
                    fileInfo.className = 'file-info';
                    
                    const fileSize = document.createElement('div');
                    fileSize.className = 'file-size';
                    fileSize.textContent = file.size;
                    
                    const downloadBtn = document.createElement('a');
                    downloadBtn.className = 'download-btn';
                    downloadBtn.href = file.path;
                    downloadBtn.download = file.name;
                    downloadBtn.textContent = 'Download';
                    downloadBtn.target = '_blank';
                    
                    fileInfo.appendChild(fileSize);
                    fileInfo.appendChild(downloadBtn);
                    
                    fileItem.appendChild(fileName);
                    fileItem.appendChild(fileInfo);
                    
                    filesDiv.appendChild(fileItem);
                });
            }
            
            content.appendChild(filesDiv);
            card.appendChild(header);
            card.appendChild(content);
            
            header.addEventListener('click', () => {
                card.classList.toggle('expanded');
            });
            
            return card;
        }
        
        function renderGames(searchTerm = '') {
            const grid = document.getElementById('gamesGrid');
            const noResults = document.getElementById('noResults');
            grid.innerHTML = '';
            
            let visibleCount = 0;
            
            for (const [gameName, gameData] of Object.entries(gamesData)) {
                if (searchTerm && !gameName.toLowerCase().includes(searchTerm.toLowerCase())) {
                    continue;
                }
                visibleCount++;
                const card = createGameCard(gameName, gameData);
                grid.appendChild(card);
            }
            
            noResults.classList.toggle('hidden', visibleCount > 0);
        }
        
        document.getElementById('searchInput').addEventListener('input', (e) => {
            renderGames(e.target.value);
        });
        
        // Initial render
        renderGames();
    </script>
</body>
</html>
"@

# Write the HTML file
$htmlOutput = Join-Path $outputDir "index.html"
$htmlContent | Out-File -FilePath $htmlOutput -Encoding UTF8

Write-Host "✓ Website generated: $htmlOutput"
Write-Host "✓ Ready to deploy to GitHub Pages!"
