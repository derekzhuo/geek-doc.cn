$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue

& cmd.exe /d /c "$bin\xvlog.bat tb_named_block.v"
$xvlogExit = $LASTEXITCODE
Write-Output "NAMED_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -ne 0) { exit $xvlogExit }

& cmd.exe /d /c "$bin\xelab.bat tb_named_block -s named_block_snapshot"
$xelabExit = $LASTEXITCODE
Write-Output "NAMED_XELAB_EXIT=$xelabExit"
if ($xelabExit -ne 0) { exit $xelabExit }
if (-not (Test-Path 'xsim.dir\named_block_snapshot')) { exit 30 }

& cmd.exe /d /c "$bin\xsim.bat named_block_snapshot -R"
$xsimExit = $LASTEXITCODE
Write-Output "NAMED_XSIM_EXIT=$xsimExit"
if ($xsimExit -ne 0) { exit $xsimExit }
Write-Output 'NAMED_BLOCK_FLOW_COMPLETE'
exit 0
