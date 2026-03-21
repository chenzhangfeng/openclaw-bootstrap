# Get the directory of the current script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# 强制设置控制台和输出编码为 UTF-8，解决中文乱码问题
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 关闭 PowerShell 7 的历史预测，避免终端自动带出之前输入过的整段命令/路径
try {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Import-Module PSReadLine -ErrorAction SilentlyContinue | Out-Null
        Set-PSReadLineOption -PredictionSource None
    }
} catch {
    Write-Host "  PSReadLine prediction: unable to disable ($($_.Exception.Message))" -ForegroundColor DarkGray
}

# Get the project root directory (one level up from the script directory)
$workspaceRoot = Split-Path -Parent $scriptPath
$venvActivate = Join-Path $workspaceRoot ".venv\Scripts\Activate.ps1"

# Check if the virtual environment is already active or if the activation script exists
if ($env:VIRTUAL_ENV) {
    Write-Host "  Python venv: already activated at $env:VIRTUAL_ENV" -ForegroundColor DarkGray
} elseif (Test-Path $venvActivate) {
    . $venvActivate
    Write-Host "  Python venv: automatically activated $env:VIRTUAL_ENV" -ForegroundColor DarkGray
} else {
    Write-Host "  Python venv: activation script not found at $venvActivate" -ForegroundColor DarkGray
}
