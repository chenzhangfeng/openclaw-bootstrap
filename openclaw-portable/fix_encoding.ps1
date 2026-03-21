$ErrorActionPreference = "Stop"
$WorkingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$files = Get-ChildItem -Path $WorkingDir -Filter "*.bat" | Select-Object -ExpandProperty FullName
foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f)
    $content = $content -replace "`r`n", "`n" -replace "`n", "`r`n"
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($f, $content, $utf8WithBom)
    Write-Host "Fixed $(Split-Path $f -Leaf)"
}
