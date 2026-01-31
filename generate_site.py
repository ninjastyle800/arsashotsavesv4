#!/usr/bin/env python3
"""Generate a website for browsing and downloading game saves"""

import os
import json
from pathlib import Path
import shutil
from urllib.parse import quote

def get_file_size(filepath):
    """Get human readable file size"""
    size = os.path.getsize(filepath)
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"

def scan_saves_directory(saves_path):
    """Scan the saves directory and build a proper hierarchical nested structure"""
    games = {}
    
    for game_folder in os.listdir(saves_path):
        game_path = os.path.join(saves_path, game_folder)
        if not os.path.isdir(game_path):
            continue
        
        # Initialize game with nested structure
        games[game_folder] = {
            'folders': {},
            'files': []
        }
        
        for root, dirs, files in os.walk(game_path):
            for file in files:
                file_path = os.path.join(root, file)
                rel_file_path = os.path.relpath(file_path, saves_path)
                size = get_file_size(file_path)
                
                if root != game_path:
                    # Get path parts relative to game folder
                    rel_path = os.path.relpath(root, game_path)
                    path_parts = rel_path.split(os.sep)
                    
                    # Navigate/build the nested structure
                    current = games[game_folder]
                    for part in path_parts[:-1]:
                        if part not in current['folders']:
                            current['folders'][part] = {'folders': {}, 'files': []}
                        current = current['folders'][part]
                    
                    # Add file to the final folder
                    final_folder = path_parts[-1]
                    if final_folder not in current['folders']:
                        current['folders'][final_folder] = {'folders': {}, 'files': []}
                    
                    current['folders'][final_folder]['files'].append({
                        'name': file,
                        'path': 'https://raw.githubusercontent.com/ninjastyle800/arsashotsavesv3/main/' + quote(rel_file_path.replace('\\', '/'), safe='/'),
                        'size': size
                    })
                else:
                    games[game_folder]['files'].append({
                        'name': file,
                        'path': 'https://raw.githubusercontent.com/ninjastyle800/arsashotsavesv3/main/' + quote(rel_file_path.replace('\\', '/'), safe='/'),
                        'size': size
                    })
    
    return games

def generate_html(games):
    """Generate the HTML website"""
    html = """<!DOCTYPE html>
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
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease, padding 0.3s ease;
            flex: 0;
            padding: 0;
        }
        
        .game-card.expanded .game-content {
            max-height: 2000px;
            overflow-y: auto;
            flex: 1;
            padding: 20px;
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
        const gamesData = """ + json.dumps(games) + """;
        
        function createGameCard(gameName, gameData) {
            const card = document.createElement('div');
            card.className = 'game-card';
            card.dataset.gameName = gameName.toLowerCase();
            
            const header = document.createElement('div');
            header.className = 'game-header';
            const title = document.createElement('h2');
            title.textContent = gameName;
            header.appendChild(title);
            
            // Count all files recursively
            function countAllFiles(folder) {
                let count = folder.files ? folder.files.length : 0;
                if (folder.folders) {
                    for (const subfolder of Object.values(folder.folders)) {
                        count += countAllFiles(subfolder);
                    }
                }
                return count;
            }
            
            const fileCount = countAllFiles(gameData);
            const subText = document.createElement('div');
            subText.style.position = 'absolute';
            subText.style.right = '20px';
            subText.style.fontSize = '0.85em';
            subText.style.opacity = '0.9';
            subText.textContent = `${fileCount} file${fileCount !== 1 ? 's' : ''}`;
            header.appendChild(subText);
            
            const toggleIcon = document.createElement('span');
            toggleIcon.className = 'toggle-icon';
            toggleIcon.textContent = '▼';
            header.appendChild(toggleIcon);
            
            const content = document.createElement('div');
            content.className = 'game-content';
            
            const filesDiv = document.createElement('div');
            filesDiv.className = 'game-files';
            
            // Recursive function to render folders and files
            function renderFolder(folderData, depth = 0) {
                const container = document.createElement('div');
                container.className = 'folder-container';
                
                // Render sub-folders
                if (folderData.folders && Object.keys(folderData.folders).length > 0) {
                    for (const [folderName, subfolderData] of Object.entries(folderData.folders)) {
                        const folderDiv = document.createElement('div');
                        folderDiv.className = 'nested-folder';
                        folderDiv.style.marginLeft = (depth * 15) + 'px';
                        
                        const folderHeader = document.createElement('div');
                        folderHeader.className = 'nested-folder-header';
                        folderHeader.style.fontWeight = depth === 0 ? '700' : '600';
                        folderHeader.style.color = depth === 0 ? '#667eea' : '#764ba2';
                        folderHeader.style.fontSize = (0.95 - depth * 0.05) + 'em';
                        
                        const toggle = document.createElement('span');
                        toggle.textContent = '▶';
                        toggle.style.display = 'inline-block';
                        toggle.style.width = '12px';
                        toggle.style.transition = 'transform 0.2s';
                        toggle.style.fontSize = '0.8em';
                        
                        const nameSpan = document.createElement('span');
                        nameSpan.textContent = folderName;
                        
                        folderHeader.appendChild(toggle);
                        folderHeader.appendChild(nameSpan);
                        
                        const folderContent = document.createElement('div');
                        folderContent.style.display = 'none';
                        
                        // Add files from this folder
                        if (subfolderData.files && subfolderData.files.length > 0) {
                            const filesContainer = document.createElement('div');
                            filesContainer.style.marginLeft = '15px';
                            filesContainer.style.marginTop = '4px';
                            
                            subfolderData.files.forEach(file => {
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
                            
                            folderContent.appendChild(filesContainer);
                        }
                        
                        // Add sub-folders recursively
                        if (subfolderData.folders && Object.keys(subfolderData.folders).length > 0) {
                            const subfoldersContainer = renderFolder(subfolderData, depth + 1);
                            folderContent.appendChild(subfoldersContainer);
                        }
                        
                        folderHeader.addEventListener('click', (e) => {
                            e.stopPropagation();
                            const isOpen = folderContent.style.display !== 'none';
                            folderContent.style.display = isOpen ? 'none' : 'block';
                            toggle.style.transform = isOpen ? 'rotate(0deg)' : 'rotate(90deg)';
                        });
                        
                        folderDiv.appendChild(folderHeader);
                        folderDiv.appendChild(folderContent);
                        
                        container.appendChild(folderDiv);
                    }
                }
                
                return container;
            }
            
            // Render root files
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
            
            // Render folder structure
            const folderStructure = renderFolder(gameData);
            filesDiv.appendChild(folderStructure);
            
            content.appendChild(filesDiv);
            card.appendChild(header);
            card.appendChild(content);
            
            // ONLY the header can toggle expansion
            header.addEventListener('click', (e) => {
                e.stopPropagation();
                e.preventDefault();
                card.classList.toggle('expanded');
            });
            
            // Prevent ALL clicks within content from bubbling
            content.addEventListener('click', (e) => {
                e.stopPropagation();
                e.preventDefault();
            });
            
            // Prevent ALL clicks within card from reaching parent
            card.addEventListener('click', (e) => {
                e.stopPropagation();
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
"""
    return html

if __name__ == '__main__':
    # Use the parent directories to find saves
    saves_dir = os.path.join(os.path.dirname(__file__))
    output_dir = os.path.join(saves_dir, 'docs')
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Scanning saves directory: {saves_dir}")
    games = scan_saves_directory(saves_dir)
    
    print(f"Found {len(games)} games")
    
    # Generate and write HTML
    html_content = generate_html(games)
    output_path = os.path.join(output_dir, 'index.html')
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"Website generated at: {output_path}")
    print("✨ Done!")
