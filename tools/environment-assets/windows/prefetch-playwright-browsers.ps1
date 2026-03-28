param(
    [string]$OpenClawPath = "",
    [switch]$ForceInstall
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = "SilentlyContinue"

$ToolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ToolRoot "..\..\..")
$DownloadsDir = Join-Path $ToolRoot "downloads"
$BrowsersDir = Join-Path $ToolRoot "playwright-browsers"
$NodeArchive = Get-ChildItem -Path $DownloadsDir -Filter "node-v*-win-x64.zip" | Sort-Object Name -Descending | Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($OpenClawPath)) {
    $OpenClawPath = Join-Path $RepoRoot "openclaw"
}

if (-not (Test-Path $OpenClawPath)) {
    throw "[ERROR] OpenClaw source directory not found: $OpenClawPath"
}

if (-not (Test-Path (Join-Path $OpenClawPath "package.json"))) {
    throw "[ERROR] package.json not found under OpenClaw source directory: $OpenClawPath"
}

if ($null -eq $NodeArchive) {
    throw "[ERROR] No cached Node.js archive found under $DownloadsDir. Run fetch-official-assets.ps1 first."
}

if (-not (Test-Path $BrowsersDir)) {
    New-Item -ItemType Directory -Force -Path $BrowsersDir | Out-Null
}

$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("openclaw-playwright-prefetch-" + [guid]::NewGuid().ToString("N"))
$TempNodeRoot = Join-Path $TempRoot "runtime"
$TempStore = Join-Path $TempRoot "pnpm-store"

Write-Host "Preparing temporary Node runtime from $($NodeArchive.Name)..."
New-Item -ItemType Directory -Force -Path $TempNodeRoot | Out-Null
Expand-Archive -Path $NodeArchive.FullName -DestinationPath $TempNodeRoot -Force
$ExtractedNodeDir = Get-ChildItem -Path $TempNodeRoot -Directory | Select-Object -First 1
if ($null -eq $ExtractedNodeDir) {
    throw "[ERROR] Failed to extract a Node.js runtime from $($NodeArchive.FullName)"
}

$PortableNodeDir = $ExtractedNodeDir.FullName
$env:PATH = "$PortableNodeDir;" + $env:PATH
$env:npm_config_prefix = $PortableNodeDir
$env:PNPM_STORE_DIR = $TempStore
$env:PLAYWRIGHT_BROWSERS_PATH = $BrowsersDir

Push-Location $OpenClawPath
try {
    $pnpmCmd = Join-Path $PortableNodeDir "pnpm.cmd"
    if (-not (Test-Path $pnpmCmd)) {
        Write-Host "Installing pnpm into temporary portable Node..."
        & (Join-Path $PortableNodeDir "npm.cmd") install -g pnpm --registry=https://registry.npmmirror.com
    }

    if ($ForceInstall -or -not (Test-Path (Join-Path $OpenClawPath "node_modules\.pnpm"))) {
        Write-Host "Installing project dependencies so Playwright version matches the real app..."
        & $pnpmCmd install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir $TempStore
    } else {
        Write-Host "Reusing existing project dependencies under $OpenClawPath"
    }

    Write-Host "Prefetching Playwright browsers into $BrowsersDir ..."
    & $pnpmCmd exec playwright install
}
finally {
    Pop-Location
    if (Test-Path $TempRoot) {
        Remove-Item -Path $TempRoot -Recurse -Force
    }
}

Write-Host ""
Write-Host "Playwright browser prefetch complete."
Write-Host "Browser cache dir: $BrowsersDir"
