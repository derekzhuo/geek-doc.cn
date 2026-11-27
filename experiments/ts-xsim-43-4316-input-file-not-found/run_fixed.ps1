param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('relative', 'absolute')]
  [string]$Mode
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$work = Join-Path $root "fixed-$Mode"
New-Item -ItemType Directory -Path $work -Force | Out-Null
Set-Location $work
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
if ($Mode -eq 'relative') {
  $dut = '..\src\counter4.v'
  $tb = '..\src\tb_counter.v'
} else {
  $dut = Join-Path $root 'src\counter4.v'
  $tb = Join-Path $root 'src\tb_counter.v'
}
$snapshot = "${Mode}_snapshot"

Write-Output "Get-Location=$((Get-Location).Path)"
Write-Output "Resolve-Path(counter4.v)=$((Resolve-Path $dut).Path)"
Write-Output "Resolve-Path(tb_counter.v)=$((Resolve-Path $tb).Path)"
Write-Output "Test-Path(counter4.v)=$(Test-Path $dut)"
Write-Output "Test-Path(tb_counter.v)=$(Test-Path $tb)"
& cmd.exe /d /c "$bin\xvlog.bat `"$dut`" `"$tb`""
$xvlogExit = $LASTEXITCODE
Write-Output "${Mode}_XVLOG_EXIT=$xvlogExit"
if ($xvlogExit -ne 0) { exit $xvlogExit }

& cmd.exe /d /c "$bin\xelab.bat tb_counter -s $snapshot"
$xelabExit = $LASTEXITCODE
Write-Output "${Mode}_XELAB_EXIT=$xelabExit"
if ($xelabExit -ne 0) { exit $xelabExit }
if (-not (Test-Path "xsim.dir\$snapshot")) { exit 30 }

& cmd.exe /d /c "$bin\xsim.bat $snapshot -R"
$xsimExit = $LASTEXITCODE
Write-Output "${Mode}_XSIM_EXIT=$xsimExit"
if ($xsimExit -ne 0) { exit $xsimExit }
Write-Output "${Mode}_INPUT_PATH_FLOW_COMPLETE"
exit 0
