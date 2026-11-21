$ErrorActionPreference = 'Stop'
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Set-Location $PSScriptRoot
& "$bin\xvlog.bat" axis_register_slice.v tb_axis_register_slice.v > xvlog-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xvlog-console.log; exit $LASTEXITCODE }
& "$bin\xelab.bat" tb_axis_register_slice -s axis_sim > xelab-console.log 2>&1
if ($LASTEXITCODE -ne 0) { Get-Content xelab-console.log; exit $LASTEXITCODE }
& "$bin\xsim.bat" axis_sim -R > xsim-console.log 2>&1
$rc = $LASTEXITCODE
Get-Content xsim-console.log
if ($rc -ne 0) { exit $rc }
if (-not (Select-String -Path xsim.log -Pattern '^AXIS_SCENARIOS_PASS transfers=96$' -Quiet)) { throw 'Missing AXI scenarios PASS marker' }
$cases = (Select-String -Path xsim.log -Pattern '^AXIS_CASE ').Count
if ($cases -ne 3) { throw "Expected 3 scenario markers, got $cases" }
Remove-Item -Force axis-results.zip -ErrorAction SilentlyContinue
Compress-Archive -Path xvlog.log,xelab.log,xsim.log -DestinationPath axis-results.zip -Force
Write-Output 'AXIS_SCENARIOS_OK'
