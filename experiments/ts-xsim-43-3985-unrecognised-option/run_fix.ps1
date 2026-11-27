$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$bin = 'D:\Xilinx\Vivado\2017.4\bin'
$status = Join-Path $root 'fix-status.log'
Remove-Item $status -Force -ErrorAction SilentlyContinue

function Invoke-Checked {
    param(
        [string]$Command,
        [string]$Name
    )
    & cmd.exe /d /c $Command
    $rc = $LASTEXITCODE
    "$Name=$rc" | Out-File $status -Append -Encoding ascii
    if ($rc -ne 0) { exit $rc }
}

# Stage 4: remove only the old snapshot, then fail fast at every native step.
Remove-Item 'xsim.dir\work.tb_toggle' -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path 'xsim.dir\work.tb_toggle') { exit 30 }
Invoke-Checked "$bin\xvlog.bat dut_toggle.v tb_toggle.v > fix-xvlog.log 2>&1" 'FIX_XVLOG_EXIT'
Invoke-Checked "$bin\xelab.bat -debug typical tb_toggle > fix-xelab.log 2>&1" 'FIX_XELAB_EXIT'
if (-not (Select-String -Path 'fix-xelab.log' -Pattern 'Built simulation snapshot work\.tb_toggle' -Quiet)) { exit 31 }
Invoke-Checked "$bin\xsim.bat tb_toggle -tclbatch fix_vcd.tcl > fix-xsim.log 2>&1" 'FIX_XSIM_EXIT'
if (Select-String -Path 'fix-xsim.log' -Pattern '^FIX_.*FAILED' -Quiet) { exit 32 }
if (-not (Test-Path 'trace.vcd')) { exit 33 }
$vcd = Get-Item 'trace.vcd'
if ($vcd.Length -eq 0) { exit 34 }
Get-Item 'xsim.dir\work.tb_toggle', 'trace.vcd' | Select-Object FullName, LastWriteTime | Format-List | Out-File 'fix-artifacts.log' -Encoding ascii
"FIX_VCD_NONEMPTY=True" | Out-File $status -Append -Encoding ascii
exit 0
