$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
& "$bin\xvlog.bat" dsp_pipeline.v tb_dsp_pipeline.v > xvlog-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xvlog-console.log; exit $LASTEXITCODE }
& "$bin\xelab.bat" tb_dsp_pipeline -s dsp_sim > xelab-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xelab-console.log; exit $LASTEXITCODE }
& "$bin\xsim.bat" dsp_sim -R > xsim-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xsim-console.log; exit $LASTEXITCODE }
Get-Content xsim-console.log
if (-not (Select-String -Path xsim.log -Pattern '^DSP_PIPE_EQUIV_PASS cycles=256$' -Quiet)) { throw 'Missing DSP equivalence PASS marker' }
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force qor-environment-retry.log,dsp-results.zip -ErrorAction SilentlyContinue
& cmd /c "`"$bin\vivado.bat`" -mode batch -source dsp_qor.tcl > qor.log 2>&1"
$rc = $LASTEXITCODE
if ($rc -ne 0 -and (Select-String -Path qor.log -Pattern "couldn't read file .*[\\/](realtime|scripts[\\/]rt)[\\/]|rt-undefined" -Quiet)) {
    Copy-Item qor.log qor-environment-retry.log -Force
    Remove-Item -Recurse -Force .Xil,work -ErrorAction SilentlyContinue
    & cmd /c "`"$bin\vivado.bat`" -mode batch -source dsp_qor.tcl > qor.log 2>&1"
    $rc = $LASTEXITCODE
}
Get-Content qor.log
if ($rc -ne 0) { exit $rc }
$count = (Select-String -Path qor.log -Pattern '^DSP_QOR_RESULT ').Count
if ($count -ne 4) { throw "Expected 4 QoR results, got $count" }
New-Item -ItemType Directory -Force results | Out-Null
foreach ($depth in 0..3) {
    Copy-Item "work/pipe$depth/utilization.rpt" "results/pipe${depth}_utilization.rpt"
    Copy-Item "work/pipe$depth/timing.rpt" "results/pipe${depth}_timing.rpt"
}
$reports = Get-ChildItem results -File
if ($reports.Count -ne 8) { throw "Expected 8 reports, got $($reports.Count)" }
Add-Content qor.log "DSP_QOR_OK variants=$count reports=$($reports.Count)"
$items = @('xvlog.log','xelab.log','xsim.log','qor.log')
if (Test-Path qor-environment-retry.log) { $items += 'qor-environment-retry.log' }
$items += $reports.FullName
Compress-Archive -Path $items -DestinationPath dsp-results.zip -Force
Write-Output 'DSP_QOR_OK'
