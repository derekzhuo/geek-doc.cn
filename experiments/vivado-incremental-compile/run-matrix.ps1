$ErrorActionPreference = 'Stop'
$vivado = 'D:\Xilinx\Vivado\2017.4\bin\vivado.bat'
$summary = Join-Path $PSScriptRoot 'matrix-summary.log'
Set-Location $PSScriptRoot
Remove-Item -Recurse -Force .Xil,work,baseline,results -ErrorAction SilentlyContinue
Remove-Item -Force incremental-results.zip -ErrorAction SilentlyContinue
Set-Content -Path $summary -Value "Vivado incremental compile matrix / $(Get-Date -Format s)" -Encoding UTF8

function Invoke-Flow([string]$Mode, [string]$Variant, [int]$Run) {
    if ($Mode -eq 'baseline') {
        $name = 'baseline'
    } else {
        $name = "${Variant}_${Mode}_${Run}"
    }
    $log = Join-Path $PSScriptRoot "$name.log"
    Write-Output "MATRIX_BEGIN $name"
    Remove-Item -Recurse -Force (Join-Path $PSScriptRoot '.Xil') -ErrorAction SilentlyContinue
    & cmd /c "`"$vivado`" -mode batch -source flow.tcl -tclargs $Mode $Variant $Run 2>&1" | Tee-Object -FilePath $log
    Get-Content $log | Add-Content -Path $summary -Encoding UTF8
    $rc = $LASTEXITCODE
    if ($rc -ne 0 -and (Select-String -Path $log -Pattern "couldn't read file .*[\\/](realtime|scripts[\\/]rt)[\\/]|rt-undefined" -Quiet)) {
        Write-Output "ENV_RETRY $name"
        Remove-Item -Recurse -Force (Join-Path $PSScriptRoot '.Xil') -ErrorAction SilentlyContinue
        & cmd /c "`"$vivado`" -mode batch -source flow.tcl -tclargs $Mode $Variant $Run 2>&1" | Tee-Object -FilePath $log
        Get-Content $log | Add-Content -Path $summary -Encoding UTF8
        $rc = $LASTEXITCODE
    }
    Write-Output "MATRIX_END $name rc=$rc"
    if ($rc -ne 0) { throw "$name failed with rc=$rc" }
    if ($Mode -ne 'baseline') {
        $marker = Select-String -Path $log -Pattern '^EXPERIMENT_RESULT '
        if (-not $marker) { throw "$name has no result marker" }
    }
}

Invoke-Flow baseline base 0
foreach ($variant in @('small', 'large')) {
    foreach ($mode in @('full', 'incremental')) {
        foreach ($run in 1..3) {
            Invoke-Flow $mode $variant $run
        }
    }
}
$count = (Select-String -Path $summary -Pattern '^EXPERIMENT_RESULT ').Count
if ($count -ne 13) { throw "Expected 13 result markers, got $count" }
$reuse = Get-ChildItem -Path (Join-Path $PSScriptRoot 'work') -Filter reuse.rpt -Recurse
if ($reuse.Count -ne 6) { throw "Expected 6 reuse reports, got $($reuse.Count)" }
Add-Content -Path $summary -Value "INCREMENTAL_MATRIX_OK results=$count reuse_reports=$($reuse.Count)"
$items = @($summary) + (Get-ChildItem -Path $PSScriptRoot -Filter '*.log' | Where-Object Name -ne 'matrix-summary.log').FullName
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'results') | Out-Null
Get-ChildItem -Path (Join-Path $PSScriptRoot 'baseline') -Filter '*.rpt' | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $PSScriptRoot "results/baseline_$($_.Name)")
}
Get-ChildItem -Path (Join-Path $PSScriptRoot 'work') -Filter '*.rpt' -Recurse | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $PSScriptRoot "results/$($_.Directory.Name)_$($_.Name)")
}
$items += (Get-ChildItem (Join-Path $PSScriptRoot 'results') -File).FullName
Compress-Archive -Path $items -DestinationPath (Join-Path $PSScriptRoot 'incremental-results.zip') -Force
Get-Content $summary | Select-String -Pattern '^EXPERIMENT_RESULT |^INCREMENTAL_MATRIX_OK'
