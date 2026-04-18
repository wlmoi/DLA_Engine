param(
    [string]$PdkRoot = $env:PDK_ROOT,
    [string]$Pdk = "gf180mcuD",
    [string]$Image = "efabless/openlane:latest",
    [ValidateSet("classic", "openlane2")]
    [string]$Mode = "classic",
    [string]$DesignName = "dla_engine_top",
    [string]$Tag = "run_" + (Get-Date -Format "yyyyMMdd_HHmmss"),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PdkRoot)) {
    throw "PDK root is empty. Set PDK_ROOT or pass -PdkRoot <path>."
}

if (-not (Test-Path $PdkRoot)) {
    throw "PDK root does not exist: $PdkRoot"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent $scriptDir

& (Join-Path $scriptDir "sync_sources.ps1") -DesignName $DesignName

$designDirLinux = "/project/openlane/designs/$DesignName"

if ($Mode -eq "classic") {
    $insideCmd = "flow.tcl -design $designDirLinux -tag $Tag -overwrite"
} else {
    $insideCmd = "python3 -m openlane --manual-pdk --pdk $Pdk --pdk-root /pdk $designDirLinux/config.json"
}

Write-Host "[OPENLANE] Running mode=$Mode design=$DesignName pdk=$Pdk"
Write-Host "[OPENLANE] Command: $insideCmd"

if ($DryRun) {
    Write-Host "[OPENLANE] DryRun enabled. No container execution performed."
    exit 0
}

& docker info --format "{{.ServerVersion}}" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docker engine is not running. Start Docker Desktop, then retry."
}

& docker run --rm `
    -v "${repoDir}:/project" `
    -v "${PdkRoot}:/pdk" `
    -e "PDK=$Pdk" `
    -e "PDK_ROOT=/pdk" `
    --entrypoint /bin/sh `
    $Image -c "$insideCmd"

if ($LASTEXITCODE -ne 0) {
    throw "OpenLane run failed with exit code $LASTEXITCODE"
}

Write-Host "[OPENLANE] Run finished successfully."
