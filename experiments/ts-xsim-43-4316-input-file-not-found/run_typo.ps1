$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$work = Join-Path $root 'typo'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Set-Location $work
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
$dut = Join-Path $root 'src\counter4.v'
$actualTb = Join-Path $root 'src\tb_counter.v'

Write-Output "Get-Location=$((Get-Location).Path)"
Write-Output "Resolve-Path(counter4.v)=$((Resolve-Path $dut).Path)"
Write-Output "Test-Path(actual tb_counter.v)=$(Test-Path $actualTb)"
Write-Output "Test-Path(tb_counter4.v)=$(Test-Path 'tb_counter4.v')"
& cmd.exe /d /c "$bin\xvlog.bat `"$dut`" tb_counter4.v"
$xvlogExit = $LASTEXITCODE
Write-Output "TYPO_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -eq 0) { exit 20 }
Write-Output 'XELAB_NOT_RUN_AFTER_BAD_XVLOG=True'
if (Test-Path 'xsim.dir\typo_snapshot') { exit 21 }
Write-Output 'EXPECTED_INPUT_FILE_NOT_FOUND_TYP0'
exit 0
