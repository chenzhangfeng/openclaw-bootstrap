param(
    [ValidateSet("fat", "slim")]
    [string]$Mode = "fat"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$WorkingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $WorkingDir

# ===== 配置 =====
$NodeVersion = "22.22.1"
$Platform = "win32"
$Arch = "x64"
$NodeZipName = "node-v$NodeVersion-win-x64"
$NodeUrl = "https://nodejs.org/dist/v$NodeVersion/$NodeZipName.zip"

function Require-Path {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path $Path)) {
        throw "[ERROR] Missing $Description at: $Path"
    }
}

function Test-DirectoryHasContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    return $null -ne (Get-ChildItem -Path $Path -Force | Select-Object -First 1)
}

$DistName = "openclaw-win-$Arch-$Mode"
$DistDir = Join-Path $RepoRoot "dist\$DistName"
$nodeTarget = Join-Path $DistDir "node"
$srcDir = Join-Path $RepoRoot "openclaw"
$launchersDir = Join-Path $RepoRoot "launchers\windows"
$portableDir = Join-Path $RepoRoot "portable"
$portableScriptsDir = Join-Path $portableDir "scripts"
$portableDataDir = Join-Path $portableDir "data"
$portableBrowsersDir = Join-Path $portableDir "browsers"
$portableReadme = Join-Path $portableDir "README.md"

Write-Host "=========================================="
Write-Host "  OpenClaw Portable Builder - Windows $Mode"
Write-Host "=========================================="

Require-Path -Path $srcDir -Description "OpenClaw source directory"
Require-Path -Path (Join-Path $srcDir "package.json") -Description "OpenClaw package.json"
Require-Path -Path $launchersDir -Description "Windows launcher directory"
Require-Path -Path $portableScriptsDir -Description "portable scripts directory"
Require-Path -Path $portableDataDir -Description "portable data directory"

# 清理旧产物
if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force }
New-Item -ItemType Directory -Path $DistDir | Out-Null

# [1/6] 下载 Node.js
Write-Host "`n[1/6] Node.js v$NodeVersion ($Arch)..."
if (-Not (Test-Path "$RepoRoot\build\cache\$NodeZipName.zip")) {
    New-Item -ItemType Directory -Force -Path "$RepoRoot\build\cache" | Out-Null
    Write-Host "Downloading..."
    Invoke-WebRequest -Uri $NodeUrl -OutFile "$RepoRoot\build\cache\$NodeZipName.zip"
}
Write-Host "Extracting..."
Expand-Archive -Path "$RepoRoot\build\cache\$NodeZipName.zip" -DestinationPath $DistDir -Force
Rename-Item -Path (Join-Path $DistDir $NodeZipName) -NewName "node"

# [2/6] 复制源码
Write-Host "`n[2/6] Copying OpenClaw source..."
$dstSrc = Join-Path $DistDir "openclaw"
Copy-Item -Path $srcDir -Destination $dstSrc -Recurse -Force
$gitDir = Join-Path $dstSrc ".git"
if (Test-Path $gitDir) { Remove-Item $gitDir -Recurse -Force }

# [3/6] 复制启动器和共享文件
Write-Host "`n[3/6] Copying launchers and shared files..."
Get-ChildItem $launchersDir -File | Copy-Item -Destination $DistDir
Copy-Item -Path $portableScriptsDir -Destination (Join-Path $DistDir "scripts") -Recurse -Force
Copy-Item -Path $portableDataDir -Destination (Join-Path $DistDir "data") -Recurse -Force
if (Test-Path $portableReadme) {
    Copy-Item $portableReadme -Destination $DistDir
}
if (Test-Path $portableBrowsersDir) {
    Write-Host "Copying prebuilt Playwright browsers..."
    Copy-Item -Path $portableBrowsersDir -Destination (Join-Path $DistDir "browsers") -Recurse -Force
}

# 创建目录结构
@("browsers", "data\workspace") | ForEach-Object {
    $p = Join-Path $DistDir $_
    if (-Not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

# [4/6] 安装依赖 (fat 模式)
if ($Mode -eq "fat") {
    Write-Host "`n[4/6] Installing dependencies (fat mode)..."
    $env:PATH = "$nodeTarget;" + $env:PATH
    $env:npm_config_prefix = $nodeTarget
    $storeDir = Join-Path $DistDir "temp-pnpm-store"
    $env:PNPM_STORE_DIR = $storeDir

    Push-Location $dstSrc
    try {
        & "$nodeTarget\npm.cmd" install -g pnpm --registry=https://registry.npmmirror.com
        & "$nodeTarget\pnpm.cmd" install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir $storeDir
    }
    finally {
        Pop-Location
    }

    # [5/6] 平台瘦身
    Write-Host "`n[5/6] Pruning non-$Platform packages..."
    $pruneScript = Join-Path $WorkingDir "prune-platform.js"
    $nmPath = Join-Path $dstSrc "node_modules"
    & "$nodeTarget\node.exe" $pruneScript --platform $Platform --arch $Arch --path $nmPath

    if (Test-Path $storeDir) {
        Remove-Item $storeDir -Recurse -Force
        Write-Host "Removed temp pnpm store"
    }
} else {
    Write-Host "`n[4/6] Skipping dependency install (slim mode)"
    Write-Host "[5/6] Skipping platform prune (slim mode)"
}

# [6/6] 修复编码
Write-Host "`n[6/6] Fixing .bat encoding (UTF-8 BOM + CRLF)..."
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
Get-ChildItem -Path $DistDir -Filter "*.bat" | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $content = $content -replace "`r`n", "`n" -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8Bom)
    Write-Host "Fixed: $($_.Name)"
}

if (Test-DirectoryHasContent -Path (Join-Path $DistDir "browsers")) {
    Write-Host "Bundled prebuilt Playwright browsers."
} else {
    Write-Warning "No prebuilt Playwright browsers were bundled. This package can still be built, but it is not yet a true novice-friendly offline release."
}

Write-Host "`n=========================================="
Write-Host "Build complete: $DistName"
Write-Host "Output: $DistDir"
Write-Host "=========================================="
