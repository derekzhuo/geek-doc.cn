param(
    [ValidateSet('warn', 'fixed')][string]$Flow = 'warn'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# warn  -> flow_warn.tcl, no pin assignments: compiles fine with Critical Warning (169085), exit code 0
# fixed -> flow_fixed.tcl, all six pins assigned: 169085 disappears, full compile succeeds, exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
$tcl = if ($Flow -eq 'warn') { 'flow_warn.tcl' } else { 'flow_fixed.tcl' }
$log = if ($Flow -eq 'warn') { 'warn-169085-unassigned.log' } else { 'fixed-pin-assigned-pass.log' }

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
