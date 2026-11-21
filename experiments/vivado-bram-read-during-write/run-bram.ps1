$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
& "$bin\xvlog.bat" bram_write_first.v bram_read_first.v bram_no_change.v tb_bram.v > xvlog-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xvlog-console.log; exit $LASTEXITCODE }
& "$bin\xelab.bat" tb_bram -s bram_sim > xelab-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xelab-console.log; exit $LASTEXITCODE }
& "$bin\xsim.bat" bram_sim -R > xsim-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xsim-console.log; exit $LASTEXITCODE }
Get-Content xsim-console.log
if (-not (Select-String -Path xsim.log -Pattern '^BRAM_MODES_PASS cases=3$' -Quiet)) { throw 'Missing BRAM PASS marker' }
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force qor-environment-retry.log,bram-results.zip -ErrorAction SilentlyContinue
& cmd /c "`"$bin\vivado.bat`" -mode batch -source bram_qor.tcl > qor.log 2>&1"
$rc = $LASTEXITCODE
if ($rc -ne 0 -and (Select-String -Path qor.log -Pattern "couldn't read file .*[\\/]realtime[\\/]|rt-undefined" -Quiet)) {
    Copy-Item qor.log qor-environment-retry.log -Force
    Remove-Item -Recurse -Force .Xil,work -ErrorAction SilentlyContinue
    & cmd /c "`"$bin\vivado.bat`" -mode batch -source bram_qor.tcl > qor.log 2>&1"
    $rc = $LASTEXITCODE
}
Get-Content qor.log
if ($rc -ne 0) { exit $rc }
$count = (Select-String -Path qor.log -Pattern '^BRAM_QOR_RESULT ').Count
if ($count -ne 3) { throw "Expected 3 QoR results, got $count" }
$reports = Get-ChildItem -Path work -Include utilization.rpt,timing.rpt -Recurse
if ($reports.Count -ne 6) { throw "Expected 6 reports, got $($reports.Count)" }
Add-Content qor.log "BRAM_QOR_OK variants=$count reports=$($reports.Count)"
$items = @('xvlog.log','xelab.log','xsim.log','qor.log')
if (Test-Path qor-environment-retry.log) { $items += 'qor-environment-retry.log' }
New-Item -ItemType Directory -Force results | Out-Null
foreach ($variant in @('write_first', 'read_first', 'no_change')) {
    Copy-Item "work/$variant/utilization.rpt" "results/${variant}_utilization.rpt"
    Copy-Item "work/$variant/timing.rpt" "results/${variant}_timing.rpt"
    $items += "results/${variant}_utilization.rpt","results/${variant}_timing.rpt"
}
Compress-Archive -Path $items -DestinationPath bram-results.zip -Force
Write-Output 'BRAM_QOR_OK'
