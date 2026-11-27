$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $root 'run_typo.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $root 'run_wrong_cwd.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $root 'run_fixed.ps1') -Mode relative
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $root 'run_fixed.ps1') -Mode absolute
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output 'ALL_INPUT_PATH_SCENARIOS_COMPLETE'
