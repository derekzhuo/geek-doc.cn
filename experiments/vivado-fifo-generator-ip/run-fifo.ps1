$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force fifo-results.zip,qor-environment-retry.log -ErrorAction SilentlyContinue

function Invoke-Vivado([string]$Tcl, [string]$Log) {
    & cmd /c "`"$bin\vivado.bat`" -mode batch -source $Tcl > $Log 2>&1"
    $rc = $LASTEXITCODE
    if ($rc -ne 0 -and (Select-String -Path $Log -Pattern 'couldn''t read file|rt-undefined' -Quiet)) {
        Copy-Item $Log "$Log.retry" -Force
        & cmd /c "`"$bin\vivado.bat`" -mode batch -source $Tcl > $Log 2>&1"
        $rc = $LASTEXITCODE
    }
    Get-Content $Log
    if ($rc -ne 0) { throw "$Tcl failed with rc=$rc" }
}

Invoke-Vivado setup-ip.tcl ip-setup.log
$ipdir = 'work\ip\.srcs\sources_1\ip\fifo_16x8'
$models = @("$ipdir\hdl\fifo_generator_v13_2_rfs.v", "$ipdir\simulation\fifo_generator_vlog_beh.v", "$ipdir\sim\fifo_16x8.v")
foreach ($model in $models) {
    if (-not (Test-Path $model)) { throw "Missing generated simulation model: $model" }
}
& "$bin\xvlog.bat" "$bin\..\data\verilog\src\glbl.v" $models fifo_ip_top.v fifo_hand.v tb_fifo.v > xvlog-console.log 2>&1
Get-Content xvlog-console.log
if ($LASTEXITCODE -ne 0 -or (Select-String -Path xvlog.log -Pattern '^ERROR:' -Quiet)) { throw 'FIFO compilation failed' }
& "$bin\xelab.bat" work.tb_fifo work.glbl -L unisims_ver -L secureip -s fifo_sim > xelab-console.log 2>&1
Get-Content xelab-console.log
if ($LASTEXITCODE -ne 0 -or (Select-String -Path xelab.log -Pattern '^ERROR:' -Quiet)) { throw 'FIFO elaboration failed' }
& "$bin\xsim.bat" fifo_sim -R > xsim-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xsim-console.log; exit $LASTEXITCODE }
Get-Content xsim-console.log
if (-not (Select-String -Path xsim.log -Pattern '^FIFO_EQUIV_PASS cycles=' -Quiet)) { throw 'Missing FIFO equivalence PASS marker' }
Invoke-Vivado fifo_qor.tcl qor.log
if ((Select-String -Path qor.log -Pattern '^FIFO_RAM_OK variant=').Count -ne 2) { throw 'Missing block-RAM mapping verification' }
if ((Select-String -Path qor.log -Pattern '^FIFO_QOR_RESULT variant=').Count -ne 2) { throw 'Missing FIFO implementation results' }
New-Item -ItemType Directory -Force results | Out-Null
Copy-Item work/ip/utilization.rpt results/ip-utilization.rpt
Copy-Item work/ip/timing.rpt results/ip-timing.rpt
Copy-Item work/hand/utilization.rpt results/hand-utilization.rpt
Copy-Item work/hand/timing.rpt results/hand-timing.rpt
Copy-Item work/ip/.srcs/sources_1/ip/fifo_16x8/fifo_16x8.xci results/
$items = @('ip-setup.log','xvlog.log','xelab.log','xsim.log','qor.log') + (Get-ChildItem results -File).FullName
Compress-Archive -Path $items -DestinationPath fifo-results.zip -Force
Write-Output 'FIFO_EXPERIMENT_OK'
