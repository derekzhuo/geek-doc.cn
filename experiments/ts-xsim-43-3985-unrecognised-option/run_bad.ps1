$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
$status = Join-Path $root 'run-status.log'
Remove-Item $status -Force -ErrorAction SilentlyContinue
Remove-Item 'xsim.dir', '.Xil' -Recurse -Force -ErrorAction SilentlyContinue

# Stage 1: compile the sources and create a known-good debug snapshot.
& cmd.exe /d /c "$bin\xvlog.bat dut_toggle.v tb_toggle.v > baseline-xvlog.log 2>&1"
$xvlogExit = $LASTEXITCODE
"BASELINE_XVLOG_EXIT=$xvlogExit" | Out-File $status -Append -Encoding ascii
if ($xvlogExit -ne 0) { exit $xvlogExit }
& cmd.exe /d /c "$bin\xelab.bat -debug typical tb_toggle > baseline-xelab.log 2>&1"
$baselineExit = $LASTEXITCODE
"BASELINE_XELAB_EXIT=$baselineExit" | Out-File $status -Append -Encoding ascii
if ($baselineExit -ne 0) { exit $baselineExit }
$snapshot = Get-Item 'xsim.dir\work.tb_toggle'
$baselineTicks = $snapshot.LastWriteTimeUtc.Ticks
$snapshot | Select-Object FullName, Length, LastWriteTime | Format-List | Out-File 'baseline-snapshot.log' -Encoding ascii
"BASELINE_SNAPSHOT_UTC_TICKS=$baselineTicks" | Out-File 'baseline-snapshot.log' -Append -Encoding ascii

# Stages 2 and 3: semicolons continue to xsim even when xelab fails.
& cmd.exe /d /c "$bin\xelab.bat -debug typical -force tb_toggle > bad-option.log 2>&1"; $badExit = $LASTEXITCODE; "BAD_XELAB_EXIT=$badExit" | Out-File $status -Append -Encoding ascii; $afterBad = Get-Item 'xsim.dir\work.tb_toggle'; $afterBad | Select-Object FullName, Length, LastWriteTime | Format-List | Out-File 'after-bad-snapshot.log' -Encoding ascii; "AFTER_BAD_SNAPSHOT_UTC_TICKS=$($afterBad.LastWriteTimeUtc.Ticks)" | Out-File 'after-bad-snapshot.log' -Append -Encoding ascii; "SNAPSHOT_TIMESTAMP_UNCHANGED=$($afterBad.LastWriteTimeUtc.Ticks -eq $baselineTicks)" | Out-File $status -Append -Encoding ascii; & cmd.exe /d /c "$bin\xsim.bat tb_toggle -tclbatch continuation_vcd.tcl > continuation-old-snapshot.log 2>&1"; $continuationExit = $LASTEXITCODE; "CONTINUATION_XSIM_EXIT=$continuationExit" | Out-File $status -Append -Encoding ascii

if ($badExit -eq 0) { exit 20 }
if (-not (Test-Path 'continuation.vcd')) { exit 21 }
if ((Get-Item 'continuation.vcd').Length -eq 0) { exit 22 }
exit $continuationExit
