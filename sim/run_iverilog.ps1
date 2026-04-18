$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$resultsDir = Join-Path $scriptDir "results"
$tbDir = Join-Path $rootDir "tb"

if (-not (Test-Path $resultsDir)) {
    New-Item -Path $resultsDir -ItemType Directory | Out-Null
}

$rtlFiles = Get-ChildItem -Path (Join-Path $rootDir "rtl\*.v") | Sort-Object Name | ForEach-Object { $_.FullName }
if ($rtlFiles.Count -eq 0) {
    throw "No RTL files matching rtl/*.v were found."
}

$tbFiles = Get-ChildItem -Path (Join-Path $tbDir "*_tb.sv") | Sort-Object Name
if ($tbFiles.Count -eq 0) {
    throw "No testbench files matching *_tb.sv were found in $tbDir"
}

foreach ($tb in $tbFiles) {
    $tbName = [System.IO.Path]::GetFileNameWithoutExtension($tb.Name)
    $outVvp = Join-Path $resultsDir "$tbName.vvp"
    $logFile = Join-Path $resultsDir "$tbName.log"

    Write-Host "[SIM] Compiling $tbName..."
    & iverilog -g2012 -s $tbName -o $outVvp @rtlFiles $tb.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "iverilog compilation failed for $tbName with exit code $LASTEXITCODE"
    }

    Write-Host "[SIM] Running $tbName..."
    & vvp $outVvp *>&1 | Tee-Object -FilePath $logFile
    if ($LASTEXITCODE -ne 0) {
        throw "vvp simulation failed for $tbName with exit code $LASTEXITCODE"
    }

    Write-Host "[SIM] Completed $tbName. Log: $logFile"
}

Write-Host "[SIM] All *_tb.sv simulations passed. Results are in $resultsDir"
