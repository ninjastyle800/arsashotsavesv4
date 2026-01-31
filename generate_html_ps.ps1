# Complete HTML generator in PowerShell

$savesDir = "c:\Users\Chris\Downloads\arsashots-saves-main\arsashots-saves-main\arsashotsavesv4"
$outputDir = "$savesDir\docs"
$outputFile = "$outputDir\index.html"

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
    
    $dirs = $items | Where-Object { $_.PSIsContainer }
    $files = $items | Where-Object { -not $_.PSIsContainer }
    
    foreach ($file in $files) {
        $relPath = (Resolve-Path -Path $file.FullName -Relative -RelativeBasePath $savesDir).Replace('.\', '').Replace('\', '/')
        # URL encode spaces and other special characters
        $encodedPath = [System.Uri]::EscapeUriString($relPath)
        # Use GitHub raw URL format with updated repository name
        $githubUrl = "https://raw.githubusercontent.com/ninjastyle800/arsashotsavesv4/main/" + $encodedPath
        $folderData['files'] += @{
            'name' = $file.Name
            'path' = $githubUrl
            'size' = Get-FileSizeStr $file.Length
        }
    }
    
    foreach ($dir in $dirs) {
        $subTree = Build-FolderTree -folderPath $dir.FullName
        $folderData['folders'][$dir.Name] = $subTree
    }
    
    return $folderData
}

Write-Host "Generating HTML with game data..."
$games = @{}

$gameFolders = Get-ChildItem -Path $savesDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^docs$|node_modules|\.git|^generate' }

foreach ($gameFolder in $gameFolders) {
    Write-Host "Processing: $($gameFolder.Name)"
    $games[$gameFolder.Name] = Build-FolderTree -folderPath $gameFolder.FullName
}

$gamesJson = $games | ConvertTo-Json -Depth 100
$gamesJson = $gamesJson -replace '/', '\/' # Escape forward slashes for JSON

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Arsashot Saves Download Center</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #232526 0%, #414345 100%);
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
            align-items: start;
        }
        
        .game-card {
            /* background: white; moved to .game-content */
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            animation: slideUp 0.5s ease-out;
            display: flex;
            flex-direction: column;
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
            flex-shrink: 0;
            gap: 10px;
        }
        
        .game-header h2 {
            font-size: 1.3em;
            flex: 1;
            margin: 0;
        }
        
        .toggle-icon {
            font-size: 1.5em;
            transition: transform 0.3s ease;
            flex-shrink: 0;
        }
        
        .game-card.expanded .toggle-icon {
            transform: rotate(180deg);
        }
        
        .game-content {
            display: none;
            padding: 0;
            background: #111;
            color: #fff;
            border-radius: 0 0 12px 12px;
        }
        .game-card.expanded .game-content {
            display: block;
            max-height: 2000px;
            overflow-y: auto;
            flex: 1;
            padding: 20px;
            background: #111;
            color: #fff;
        }
        
        .game-files {
            padding: 0;
        }
        
        .nested-folder {
            margin-bottom: 8px;
        }
        
        .nested-folder-header {
            font-weight: 600;
            color: #667eea;
            padding: 6px 0;
            cursor: pointer;
            user-select: none;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: color 0.2s;
        }
        
        .nested-folder-header:hover {
            color: #764ba2;
        }
        
        .folder-container {
            margin: 8px 0;
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
            font-size: 0.8em;
            min-width: 50px;
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
            text-decoration: none;
            display: inline-block;
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
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🎮 Arsashot Saves Download Center</h1>
            <p>Browse and download the game saves you need</p>
        </header>
        
        <div class="search-box">
            <input type="text" id="searchInput" placeholder="Search games...">
        </div>
        
        <div class="games-grid" id="gamesGrid"></div>
        <div id="noResults" class="no-results hidden">
            <p>No games found matching your search.</p>
        </div>
    </div>
    
    <footer style="text-align:center; color:white; margin-top:40px; opacity:0.95;">
        <p>Powered by GitHub Pages</p>
        <div style="font-weight:bold; font-size:1.15em; margin-top:18px; margin-bottom:6px;">Need support? <span style='color:#FFD700;'>Click the button below</span> to join our Discord for help!</div>
        <a href="https://discord.gg/CwUG4qnPZF" target="_blank" style="display:inline-block; margin-top:10px; background:#5865F2; color:white; padding:10px 24px; border-radius:6px; font-weight:bold; text-decoration:none; font-size:1.1em;">
            <span style="font-size:1.3em; vertical-align:middle;">💬</span> Need help? Join our Discord!
        </a>
    </footer>
    
    <script>
        const gamesData = $gamesJson;
        
        function createGameCard(gameName, gameData) {
            const card = document.createElement('div');
            card.className = 'game-card';
            
            const header = document.createElement('div');
            header.className = 'game-header';
            
            const title = document.createElement('h2');
            title.textContent = gameName;
            
            const toggle = document.createElement('div');
            toggle.className = 'toggle-icon';
            toggle.textContent = '▼';
            
            header.appendChild(title);
            header.appendChild(toggle);
            
            const content = document.createElement('div');
            content.className = 'game-content';
            
            const filesDiv = document.createElement('div');
            filesDiv.className = 'game-files';
            
            if (gameData.files && gameData.files.length > 0) {
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
                    downloadBtn.addEventListener('click', (e) => {
                        e.stopPropagation();
                        e.preventDefault();
                        window.open(downloadBtn.href, '_blank');
                    });
                    
                    fileInfo.appendChild(fileSize);
                    fileInfo.appendChild(downloadBtn);
                    
                    fileItem.appendChild(fileName);
                    fileItem.appendChild(fileInfo);
                    
                    filesDiv.appendChild(fileItem);
                });
            }
            
            function renderFolder(folderData, depth = 0) {
                const container = document.createElement('div');
                container.style.marginLeft = (depth * 15) + 'px';
                
                if (folderData.folders && Object.keys(folderData.folders).length > 0) {
                    Object.entries(folderData.folders).forEach(([folderName, folderContent]) => {
                        const folder = document.createElement('div');
                        folder.className = 'nested-folder';
                        
                        const header = document.createElement('div');
                        header.className = 'nested-folder-header';
                        
                        const toggle = document.createElement('span');
                        toggle.textContent = '▶';
                        toggle.style.display = 'inline-block';
                        toggle.style.transition = 'transform 0.2s';
                        
                        const label = document.createElement('span');
                        label.textContent = folderName;
                        
                        header.appendChild(toggle);
                        header.appendChild(label);
                        
                        const content = document.createElement('div');
                        content.style.display = 'none';
                        
                        if (folderContent.files && folderContent.files.length > 0) {
                            const filesContainer = document.createElement('div');
                            filesContainer.style.marginLeft = '15px';
                            
                            folderContent.files.forEach(file => {
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
                                downloadBtn.addEventListener('click', (e) => {
                                    e.stopPropagation();
                                    e.preventDefault();
                                    window.open(downloadBtn.href, '_blank');
                                });
                                
                                fileInfo.appendChild(fileSize);
                                fileInfo.appendChild(downloadBtn);
                                
                                fileItem.appendChild(fileName);
                                fileItem.appendChild(fileInfo);
                                
                                filesContainer.appendChild(fileItem);
                            });
                            
                            content.appendChild(filesContainer);
                        }
                        
                        if (folderContent.folders && Object.keys(folderContent.folders).length > 0) {
                            const subfoldersContainer = renderFolder(folderContent, depth + 1);
                            content.appendChild(subfoldersContainer);
                        }
                        
                        header.addEventListener('click', (e) => {
                            e.stopPropagation();
                            const isOpen = content.style.display !== 'none';
                            content.style.display = isOpen ? 'none' : 'block';
                            toggle.style.transform = isOpen ? 'rotate(0deg)' : 'rotate(90deg)';
                        });
                        
                        folder.appendChild(header);
                        folder.appendChild(content);
                        container.appendChild(folder);
                    });
                }
                
                return container;
            }
            
            const folderStructure = renderFolder(gameData);
            filesDiv.appendChild(folderStructure);
            
            content.appendChild(filesDiv);
            card.appendChild(header);
            card.appendChild(content);
            
            header.addEventListener('click', (e) => {
                e.stopPropagation();
                e.preventDefault();
                // Accordion: close all others
                document.querySelectorAll('.game-card.expanded').forEach(c => {
                    if (c !== card) c.classList.remove('expanded');
                });
                card.classList.toggle('expanded');
            });
            
            content.addEventListener('click', (e) => {
                e.stopPropagation();
                e.preventDefault();
            });
            
            card.addEventListener('click', (e) => {
                e.stopPropagation();
            });
            
            return card;
        }
        
        function filterGames(searchTerm) {
            const grid = document.getElementById('gamesGrid');
            const noResults = document.getElementById('noResults');
            grid.innerHTML = '';
            
            const lowerSearch = searchTerm.toLowerCase();
            let count = 0;
            
            Object.entries(gamesData).forEach(([gameName, gameData]) => {
                if (gameName.toLowerCase().includes(lowerSearch)) {
                    grid.appendChild(createGameCard(gameName, gameData));
                    count++;
                }
            });
            
            noResults.classList.toggle('hidden', count > 0);
        }
        
        document.getElementById('searchInput').addEventListener('input', (e) => {
            filterGames(e.target.value);
        });
        
        window.addEventListener('load', () => {
            filterGames('');
        });
    </script>
</body>
</html>
"@

Set-Content -Path $outputFile -Value $html -Encoding UTF8
Write-Host "HTML file generated successfully at: $outputFile"
