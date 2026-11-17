param(
    [ValidateSet('bad25', 'bad18c', 'bad18t', 'good')][string]$Flow = 'bad25'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# bad25  -> flow_bad_lvcmos25.tcl, led_b assigned "2.5-V LVCMOS": Fitter Error (169216), exit code nonzero
# bad18c -> flow_bad_lvcmos18.tcl, led_b assigned "1.8-V LVCMOS": Fitter Error (169216), exit code nonzero
# bad18t -> flow_bad_lvttl18.tcl, led_b assigned "1.8-V LVTTL":  Fitter Error (169216), exit code nonzero
# good   -> flow_good.tcl, all pins 3.3-V LVTTL: full compile succeeds, exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
switch ($Flow) {
    'bad25'  { $tcl = 'flow_bad_lvcmos25.tcl'; $log = 'err-169216-lvcmos25.log' }
    'bad18c' { $tcl = 'flow_bad_lvcmos18.tcl'; $log = 'err-169216-lvcmos18.log' }
    'bad18t' { $tcl = 'flow_bad_lvttl18.tcl'; $log = 'err-169216-lvttl18.log' }
    'good'   { $tcl = 'flow_good.tcl';        $log = 'fix-compile-pass.log' }
}

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
