param(
    [string]$NodeVersion = "22.22.1",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = "SilentlyContinue"

$ToolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DownloadsDir = Join-Path $ToolRoot "downloads"
$BrowsersDir = Join-Path $ToolRoot "playwright-browsers"
$ManifestPath = Join-Path $ToolRoot "manifest.local.json"

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Download-FileIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        [switch]$Force
    )

    if ((Test-Path $DestinationPath) -and (-not $Force)) {
        Write-Host "Reusing existing file: $DestinationPath"
        return
    }

    Write-Host "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $DestinationPath
}

Ensure-Directory -Path $DownloadsDir
Ensure-Directory -Path $BrowsersDir

$nodeArchiveName = "node-v$NodeVersion-win-x64.zip"
$nodeUrl = "https://nodejs.org/dist/v$NodeVersion/$nodeArchiveName"
$nodeDestination = Join-Path $DownloadsDir $nodeArchiveName

Write-Host "Resolving official Node.js asset..."
Download-FileIfNeeded -Url $nodeUrl -DestinationPath $nodeDestination -Force:$Force

Write-Host "Resolving official MinGit asset..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -Headers @{ "User-Agent" = "OpenClawBootstrap" }
$minGitAsset = $release.assets | Where-Object { $_.name -match '^MinGit-.*-64-bit\.zip$' -and $_.name -notmatch 'busybox' } | Select-Object -First 1
if ($null -eq $minGitAsset) {
    throw "[ERROR] Could not find an official MinGit 64-bit zip in the latest git-for-windows release."
}
$minGitDestination = Join-Path $DownloadsDir $minGitAsset.name
Download-FileIfNeeded -Url $minGitAsset.browser_download_url -DestinationPath $minGitDestination -Force:$Force

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    node = [ordered]@{
        version = $NodeVersion
        file = $nodeArchiveName
        url = $nodeUrl
    }
    minGit = [ordered]@{
        releaseTag = $release.tag_name
        file = $minGitAsset.name
        url = $minGitAsset.browser_download_url
    }
    playwrightBrowsers = [ordered]@{
        directory = $BrowsersDir
        status = "pending"
        note = "Populate this directory only after you have the real OpenClaw source and know the matching Playwright version."
    }
}

$manifest | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 $ManifestPath

Write-Host ""
Write-Host "Official reusable Windows assets are ready."
Write-Host "Node archive: $nodeDestination"
Write-Host "MinGit archive: $minGitDestination"
Write-Host "Playwright browsers dir: $BrowsersDir"
Write-Host "Manifest: $ManifestPath"
