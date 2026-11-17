param(
    [ValidateSet('probe', 'missing', 'fixed')][string]$Flow = 'missing'
)
# Quartus Prime Lite 25.1 command-line experiment for undefined entity errors.
# probe   -> flow_probe.tcl:  sub_divider.v absent from VERILOG_FILE but present
#                              in the project dir; auto-discovery yields Warning 12125
# missing -> flow_missing.tcl: bad_proj\ contains only top_blink.v, so the
#                              instantiated entity is truly unreachable -> Error 12006
# fixed   -> flow_fixed.tcl:  good_proj\ contains both sources, full compile succeeds
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"

switch ($Flow) {
    'probe' {
        if (Test-Path probe_proj) { Remove-Item -Recurse -Force probe_proj }
        New-Item -ItemType Directory probe_proj | Out-Null
        Copy-Item top_blink.v, sub_divider.v, flow_probe.tcl probe_proj\
        Push-Location probe_proj
        & $quartusSh -t flow_probe.tcl 2>&1 | Tee-Object -FilePath ..\warn-autodiscovery-12125.log
        Pop-Location
    }
    'missing' {
        if (Test-Path bad_proj) { Remove-Item -Recurse -Force bad_proj }
        New-Item -ItemType Directory bad_proj | Out-Null
        Copy-Item top_blink.v bad_proj\
        Push-Location bad_proj
        & $quartusSh -t ..\flow_missing.tcl 2>&1 | Tee-Object -FilePath ..\err-12006-undefined-entity.log
        Pop-Location
    }
    'fixed' {
        if (Test-Path good_proj) { Remove-Item -Recurse -Force good_proj }
        New-Item -ItemType Directory good_proj | Out-Null
        Copy-Item top_blink.v, sub_divider.v good_proj\
        Push-Location good_proj
        & $quartusSh -t ..\flow_fixed.tcl 2>&1 | Tee-Object -FilePath ..\fix-compile-pass.log
        Pop-Location
    }
}
exit $LASTEXITCODE
