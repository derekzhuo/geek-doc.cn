param(
    [ValidateSet('bad', 'good')][string]$Flow = 'bad'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# bad  -> flow_bad.tcl, output led assigned to input-only PIN_25: Fitter Error (169009), exit code nonzero
# good -> flow_good.tcl, led moved to general IO PIN_87: full compile succeeds, exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
$tcl = if ($Flow -eq 'bad') { 'flow_bad.tcl' } else { 'flow_good.tcl' }
$log = if ($Flow -eq 'bad') { 'err-169009-input-only-pin.log' } else { 'fix-compile-pass.log' }

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
