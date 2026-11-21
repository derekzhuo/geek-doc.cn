$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
& "$bin\xvlog.bat" -sv "$bin\..\data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv" "$bin\..\data\verilog\src\glbl.v" cdc_xpm.v cdc_hand.v tb_cdc.v > xvlog-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xvlog-console.log; exit $LASTEXITCODE }
& "$bin\xelab.bat" work.tb_cdc work.glbl -s cdc_sim > xelab-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xelab-console.log; exit $LASTEXITCODE }
& "$bin\xsim.bat" cdc_sim -R > xsim-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xsim-console.log; exit $LASTEXITCODE }
Get-Content xsim-console.log
if (-not (Select-String -Path xsim.log -Pattern '^CDC_EQUIV_PASS cycles=512$' -Quiet)) { throw 'Missing CDC equivalence PASS marker' }
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force qor-environment-retry.log,cdc-results.zip -ErrorAction SilentlyContinue
& cmd /c "`"$bin\vivado.bat`" -mode batch -source cdc_qor.tcl > qor.log 2>&1"
$rc = $LASTEXITCODE
if ($rc -ne 0 -and (Select-String -Path qor.log -Pattern "couldn't read file .*[\\/](realtime|scripts[\\/]rt)[\\/]|rt-undefined" -Quiet)) {
    Copy-Item qor.log qor-environment-retry.log -Force
    Remove-Item -Recurse -Force .Xil,work -ErrorAction SilentlyContinue
    & cmd /c "`"$bin\vivado.bat`" -mode batch -source cdc_qor.tcl > qor.log 2>&1"
    $rc = $LASTEXITCODE
}
Get-Content qor.log
if ($rc -ne 0) { exit $rc }
$count = (Select-String -Path qor.log -Pattern '^CDC_QOR_RESULT ').Count
$xpmAttributes = (Select-String -Path qor.log -Pattern '^CDC_ATTRIBUTE variant=xpm .*ASYNC_REG=(TRUE|1)$').Count
$handAttributes = (Select-String -Path qor.log -Pattern '^CDC_ATTRIBUTE variant=hand .*ASYNC_REG=(TRUE|1)$').Count
if ($count -ne 2 -or $xpmAttributes -ne 2 -or $handAttributes -ne 2) {
    throw "Expected 2 QoR results and 2 ASYNC_REG cells per variant, got $count, $xpmAttributes and $handAttributes"
}
New-Item -ItemType Directory -Force results | Out-Null
foreach ($variant in @('xpm', 'hand')) {
    Copy-Item "work/$variant/utilization.rpt" "results/${variant}_utilization.rpt"
    Copy-Item "work/$variant/timing.rpt" "results/${variant}_timing.rpt"
}
$items = @('xvlog.log','xelab.log','xsim.log','qor.log')
if (Test-Path qor-environment-retry.log) { $items += 'qor-environment-retry.log' }
$items += (Get-ChildItem results -File).FullName
Compress-Archive -Path $items -DestinationPath cdc-results.zip -Force
Write-Output 'CDC_QOR_OK'
