$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force clock-results.zip,qor-environment-retry.log -ErrorAction SilentlyContinue

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
$models = @('work\ip\.srcs\sources_1\ip\clk_wiz_0\clk_wiz_0.v', 'work\ip\.srcs\sources_1\ip\clk_wiz_0\clk_wiz_0_clk_wiz.v')
foreach ($model in $models) {
    if (-not (Test-Path $model)) { throw "Missing generated simulation model: $model" }
}
& "$bin\xvlog.bat" "$bin\..\data\verilog\src\glbl.v" $models clock_top.v tb_clock_wizard.v > xvlog-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xvlog-console.log; exit $LASTEXITCODE }
& "$bin\xelab.bat" work.tb_clock_wizard work.glbl -L unisims_ver -L unimacro_ver -L secureip -s clock_sim > xelab-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xelab-console.log; exit $LASTEXITCODE }
& "$bin\xsim.bat" clock_sim -R > xsim-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xsim-console.log; exit $LASTEXITCODE }
Get-Content xsim-console.log
if (-not (Select-String -Path xsim.log -Pattern '^CLOCK_WIZ_LOCKED time_ns=' -Quiet)) { throw 'Missing executed clock lock check' }
if (-not (Select-String -Path xsim.log -Pattern '^CLOCK_WIZ_PASS clk50_period_ns=20.000000 clk200_period_ns=5.000000$' -Quiet)) { throw 'Missing exact clock frequency PASS marker' }
Invoke-Vivado clock_qor.tcl qor.log
if (-not (Select-String -Path qor.log -Pattern '^CLOCK_QOR_OK input_mhz=100 outputs_mhz=50,200 wns=' -Quiet)) { throw 'Missing verified clock implementation marker' }
New-Item -ItemType Directory -Force results | Out-Null
Copy-Item work/implementation/clocks.rpt,work/implementation/utilization.rpt,work/implementation/timing.rpt results/
Copy-Item work/ip/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci results/
$items = @('ip-setup.log','xvlog.log','xelab.log','xsim.log','qor.log') + (Get-ChildItem results -File).FullName
Compress-Archive -Path $items -DestinationPath clock-results.zip -Force
Write-Output 'CLOCK_EXPERIMENT_OK'
