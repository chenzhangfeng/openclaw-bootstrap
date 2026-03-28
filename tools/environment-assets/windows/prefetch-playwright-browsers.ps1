param(
    [string]$OpenClawPath = "",
    [ValidateSet("all", "chromium")]
    [string]$BrowserSet = "all",
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

function Resolve-OpenClawSourceDir {
    param(
        [string]$PreferredPath,
        [string]$RepoRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (-not (Test-Path $PreferredPath)) {
            throw "[ERROR] OpenClaw source directory not found: $PreferredPath"
        }

        $resolvedPreferredPath = (Resolve-Path $PreferredPath).Path
        if (-not (Test-Path (Join-Path $resolvedPreferredPath "package.json"))) {
            throw "[ERROR] package.json not found under OpenClaw source directory: $resolvedPreferredPath"
        }

        return $resolvedPreferredPath
    }

    $candidatePaths = @(
        (Join-Path $RepoRoot "openclaw"),
        (Join-Path $RepoRoot "openclaw-portable\openclaw")
    )

    foreach ($candidatePath in $candidatePaths) {
        if ((Test-Path $candidatePath) -and (Test-Path (Join-Path $candidatePath "package.json"))) {
            return (Resolve-Path $candidatePath).Path
        }
    }

    $searchedPaths = $candidatePaths -join ", "
    throw "[ERROR] OpenClaw source directory not found. Checked: $searchedPaths"
}

$OpenClawPath = Resolve-OpenClawSourceDir -PreferredPath $OpenClawPath -RepoRoot $RepoRoot

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
$playwrightCliArgs = @("install")
$nodeModulesDir = Join-Path $OpenClawPath "node_modules"
$cleanupInstalledNodeModules = $false

if ($BrowserSet -eq "chromium") {
    $playwrightCliArgs += "chromium"
}

Push-Location $OpenClawPath
try {
    Write-Host "Using OpenClaw source: $OpenClawPath"
    Write-Host "Browser set: $BrowserSet"

    $pnpmCmd = Join-Path $PortableNodeDir "pnpm.cmd"
    $playwrightCmd = Join-Path $OpenClawPath "node_modules\.bin\playwright.cmd"
    if (-not (Test-Path $pnpmCmd)) {
        Write-Host "Installing pnpm into temporary portable Node..."
        & (Join-Path $PortableNodeDir "npm.cmd") install -g pnpm --registry=https://registry.npmmirror.com
        if ($LASTEXITCODE -ne 0) {
            throw "[ERROR] Failed to install pnpm into the temporary Node runtime."
        }
    }

    if ($ForceInstall -or -not (Test-Path (Join-Path $OpenClawPath "node_modules\.pnpm"))) {
        $cleanupInstalledNodeModules = -not (Test-Path $nodeModulesDir)
        Write-Host "Installing project dependencies so Playwright version matches the real app..."
        & $pnpmCmd install --registry=https://registry.npmmirror.com --ignore-scripts --store-dir $TempStore
        if ($LASTEXITCODE -ne 0) {
            throw "[ERROR] Failed to install OpenClaw dependencies for browser prefetch."
        }
    } else {
        Write-Host "Reusing existing project dependencies under $OpenClawPath"
    }

    Write-Host "Prefetching Playwright browsers into $BrowsersDir ..."
    if (Test-Path $playwrightCmd) {
        & $playwrightCmd @playwrightCliArgs
    } else {
        & $pnpmCmd exec playwright @playwrightCliArgs
    }
    if ($LASTEXITCODE -ne 0) {
        throw "[ERROR] Failed to prefetch Playwright browsers."
    }
}
finally {
    Pop-Location
    if ($cleanupInstalledNodeModules -and (Test-Path $nodeModulesDir)) {
        Write-Host "Removing temporary node_modules created for browser prefetch..."
        Remove-Item -Path $nodeModulesDir -Recurse -Force
    }
    if (Test-Path $TempRoot) {
        Remove-Item -Path $TempRoot -Recurse -Force
    }
}

Write-Host ""
Write-Host "Playwright browser prefetch complete."
Write-Host "Browser cache dir: $BrowsersDir"
