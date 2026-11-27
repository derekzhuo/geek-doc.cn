$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue

& cmd.exe /d /c "$bin\xvlog.bat tb_unnamed_bad.v"
$xvlogExit = $LASTEXITCODE
Write-Output "BAD_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -eq 0) { exit 20 }

# The compile failed, so elaboration must not run.
Write-Output 'XELAB_NOT_RUN_AFTER_BAD_XVLOG=True'
if (Test-Path 'xsim.dir\bad_snapshot') { exit 21 }
Write-Output 'EXPECTED_UNNAMED_BLOCK_DECLARATION_ERROR'
exit 0
