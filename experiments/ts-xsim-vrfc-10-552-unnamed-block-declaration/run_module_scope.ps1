$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue

& cmd.exe /d /c "$bin\xvlog.bat tb_module_scope.v"
$xvlogExit = $LASTEXITCODE
Write-Output "MODULE_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -ne 0) { exit $xvlogExit }

& cmd.exe /d /c "$bin\xelab.bat tb_module_scope -s module_scope_snapshot"
$xelabExit = $LASTEXITCODE
Write-Output "MODULE_XELAB_EXIT=$xelabExit"
if ($xelabExit -ne 0) { exit $xelabExit }
if (-not (Test-Path 'xsim.dir\module_scope_snapshot')) { exit 40 }

& cmd.exe /d /c "$bin\xsim.bat module_scope_snapshot -R"
$xsimExit = $LASTEXITCODE
Write-Output "MODULE_XSIM_EXIT=$xsimExit"
if ($xsimExit -ne 0) { exit $xsimExit }
Write-Output 'MODULE_SCOPE_FLOW_COMPLETE'
exit 0
