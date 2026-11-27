$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$work = Join-Path $root 'wrong-cwd'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Set-Location $work
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
$dut = Join-Path $root 'src\counter4.v'
$actualTb = Join-Path $root 'src\tb_counter.v'

Write-Output "Get-Location=$((Get-Location).Path)"
Write-Output "Resolve-Path(actual tb_counter.v)=$((Resolve-Path $actualTb).Path)"
Write-Output "Test-Path(actual tb_counter.v)=$(Test-Path $actualTb)"
Write-Output "Test-Path(relative tb_counter.v)=$(Test-Path 'tb_counter.v')"
& cmd.exe /d /c "$bin\xvlog.bat `"$dut`" tb_counter.v"
$xvlogExit = $LASTEXITCODE
Write-Output "WRONG_CWD_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -eq 0) { exit 20 }
Write-Output 'XELAB_NOT_RUN_AFTER_BAD_XVLOG=True'
if (Test-Path 'xsim.dir\wrong_cwd_snapshot') { exit 21 }
Write-Output 'EXPECTED_INPUT_FILE_NOT_FOUND_WRONG_CWD'
exit 0
