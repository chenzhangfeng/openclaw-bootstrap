$ErrorActionPreference = "Stop"
$WorkingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $WorkingDir

# ===== 配置 =====
$NodeVersion = "22.22.1"
$Platform = "win32"
$Arch = "x64"
$NodeZipName = "node-v$NodeVersion-win-x64"
$NodeUrl = "https://nodejs.org/dist/v$NodeVersion/$NodeZipName.zip"

# ===== 构建模式选择 =====
param(
    [ValidateSet("fat", "slim")]
    [string]$Mode = "fat"
)

$DistName = "openclaw-win-$Arch-$Mode"
$DistDir = Join-Path $RepoRoot "dist\$DistName"

Write-Host "=========================================="
Write-Host "  OpenClaw Portable Builder - Windows $Mode"
Write-Host "=========================================="

# 清理旧产物
if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force }
New-Item -ItemType Directory -Path $DistDir | Out-Null

# [1/6] 下载 Node.js
Write-Host "`n[1/6] Node.js v$NodeVersion ($Arch)..."
$nodeTarget = Join-Path $DistDir "node"
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
$srcDir = Join-Path $RepoRoot "openclaw"
$dstSrc = Join-Path $DistDir "openclaw"
if (Test-Path $srcDir) {
    Copy-Item -Path $srcDir -Destination $dstSrc -Recurse -Force
    # 删除 git 历史
    $gitDir = Join-Path $dstSrc ".git"
    if (Test-Path $gitDir) { Remove-Item $gitDir -Recurse -Force }
} else {
    Write-Host "[WARN] openclaw/ source not found at repo root!"
}

# [3/6] 复制启动器和共享文件
Write-Host "`n[3/6] Copying launchers and shared files..."
$launchersDir = Join-Path $RepoRoot "launchers\windows"
if (Test-Path $launchersDir) {
    Get-ChildItem $launchersDir -File | Copy-Item -Destination $DistDir
}
# 共享脚本和配置
$portableDir = Join-Path $RepoRoot "portable"
if (Test-Path $portableDir) {
    Copy-Item -Path (Join-Path $portableDir "scripts") -Destination (Join-Path $DistDir "scripts") -Recurse -Force
    Copy-Item -Path (Join-Path $portableDir "data") -Destination (Join-Path $DistDir "data") -Recurse -Force
    $readmeSrc = Join-Path $portableDir "README.md"
    if (Test-Path $readmeSrc) { Copy-Item $readmeSrc -Destination $DistDir }
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

    Set-Location $dstSrc
    & "$nodeTarget\npm.cmd" install -g pnpm --registry=https://registry.npmmirror.com
    & "$nodeTarget\pnpm.cmd" install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir $storeDir
    Set-Location $WorkingDir

    # [5/6] 平台瘦身
    Write-Host "`n[5/6] Pruning non-$Platform packages..."
    $pruneScript = Join-Path $WorkingDir "prune-platform.js"
    $nmPath = Join-Path $dstSrc "node_modules"
    & "$nodeTarget\node.exe" $pruneScript --platform $Platform --arch $Arch --path $nmPath

    # 清理临时 store
    if (Test-Path $storeDir) { Remove-Item $storeDir -Recurse -Force; Write-Host "Removed temp pnpm store" }
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

Write-Host "`n=========================================="
Write-Host "Build complete: $DistName"
Write-Host "Output: $DistDir"
Write-Host "=========================================="
