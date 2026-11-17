param(
    [ValidateSet('bad', 'good')][string]$Flow = 'bad'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# bad  -> flow_bad.tcl, both led_a and led_b assigned to PIN_87: Fitter Error (176310), exit code nonzero
# good -> flow_good.tcl, led_a/led_b split to PIN_87/PIN_86: full compile succeeds, exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
$tcl = if ($Flow -eq 'bad') { 'flow_bad.tcl' } else { 'flow_good.tcl' }
$log = if ($Flow -eq 'bad') { 'err-176310-duplicate-pin.log' } else { 'fix-compile-pass.log' }

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
