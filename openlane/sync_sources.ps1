param(
    [string]$DesignName = "dla_engine_top"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent $scriptDir
$rtlDir = Join-Path $repoDir "rtl"
$dstDir = Join-Path $scriptDir "designs\$DesignName\src"

if (-not (Test-Path $rtlDir)) {
    throw "RTL directory not found at $rtlDir"
}

if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
}

Get-ChildItem -Path $dstDir -Filter "*.sv" -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Path $dstDir -Filter "*.v" -File -ErrorAction SilentlyContinue | Remove-Item -Force
Copy-Item -Path (Join-Path $rtlDir "*.v") -Destination $dstDir -Force

Write-Host "[OPENLANE] Synced RTL into $dstDir"
