$ErrorActionPreference = "Stop"
$WorkingDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=========================================="
Write-Host "  OpenClaw Portable Build Tool"
Write-Host "=========================================="

Set-Location $WorkingDir

$NodeVersion = "22.22.1"
Write-Host ""
Write-Host "[1/4] Downloading Node.js v$NodeVersion LTS..."
if (-Not (Test-Path "node\node.exe")) {
    Write-Host "Downloading Node.js zip (~30MB)..."
    $url = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip"
    Invoke-WebRequest -Uri $url -OutFile "node.zip"
    Write-Host "Extracting Node.js..."
    Expand-Archive -Path "node.zip" -DestinationPath "." -Force
    if (Test-Path "node") { Remove-Item -Path "node" -Recurse -Force }
    Rename-Item -Path "node-v$NodeVersion-win-x64" -NewName "node"
    Remove-Item "node.zip"
    Write-Host "Node.js ready!"
} else {
    Write-Host "Node.js already exists, skipping download."
}

$env:PATH = "$WorkingDir\node;" + $env:PATH
$env:npm_config_prefix = "$WorkingDir\node"
$env:PNPM_HOME = "$WorkingDir\pnpm-global"
$env:PNPM_STORE_DIR = "$WorkingDir\pnpm-store"

Write-Host ""
Write-Host "[2/4] Installing dependencies via pnpm..."
if (Test-Path "openclaw\package.json") {
    Set-Location "$WorkingDir\openclaw"

    Write-Host "Installing pnpm globally..."
    & "$WorkingDir\node\npm.cmd" install -g pnpm --registry=https://registry.npmmirror.com

    Write-Host "Installing OpenClaw dependencies (this may take a few minutes)..."
    & "$WorkingDir\node\pnpm.cmd" install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir "$env:PNPM_STORE_DIR"

    Set-Location $WorkingDir
} else {
    Write-Host "[WARN] openclaw/package.json not found! Clone the source into openclaw/ first."
}

Write-Host ""
Write-Host "[3/4] Creating directory structure..."
$dirs = @("browsers", "data", "data\workspace")
foreach ($d in $dirs) {
    if (-Not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        Write-Host "Created: $d"
    }
}

Write-Host ""
Write-Host "[4/4] Fixing batch file encoding (UTF-8 BOM + CRLF)..."
$batFiles = Get-ChildItem -Path $WorkingDir -Filter "*.bat" | Select-Object -ExpandProperty FullName
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
foreach ($f in $batFiles) {
    $content = [System.IO.File]::ReadAllText($f)
    $content = $content -replace "`r`n", "`n" -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($f, $content, $utf8Bom)
    Write-Host "Fixed: $(Split-Path $f -Leaf)"
}

Write-Host ""
Write-Host "[5/5] Cleaning up build artifacts (not needed in distribution)..."
$cleanDirs = @("pnpm-store", "pnpm-global", "openclaw\.git")
foreach ($d in $cleanDirs) {
    $p = Join-Path $WorkingDir $d
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force
        Write-Host "Removed: $d"
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Build complete! Ready for distribution."
Write-Host "  1. Test by running start.bat"
Write-Host "  2. Zip this entire folder as the release package"
Write-Host "=========================================="
