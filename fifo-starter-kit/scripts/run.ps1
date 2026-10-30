[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $ProjectRoot 'out'

foreach ($Tool in @('iverilog', 'vvp')) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        Write-Error "$Tool was not found in PATH. Install Icarus Verilog and add its bin directory to PATH."
        exit 1
    }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Simv = Join-Path $OutDir 'sim.vvp'
$Rtl = Join-Path $ProjectRoot 'rtl\sync_fifo.v'
$Testbench = Join-Path $ProjectRoot 'tb\tb_sync_fifo.v'

& iverilog -g2012 -o $Simv $Rtl $Testbench
if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

Push-Location $OutDir
try {
    & vvp sim.vvp 2>&1 | Tee-Object -FilePath 'sim.log'
    $SimulationExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($SimulationExitCode -ne 0) {
    Write-Error "Simulation failed with exit code $SimulationExitCode. See $OutDir\sim.log."
    exit $SimulationExitCode
}

if (-not (Select-String -LiteralPath (Join-Path $OutDir 'sim.log') -Pattern '^RESULT: PASS$' -Quiet)) {
    Write-Error "Simulation did not report RESULT: PASS. See $OutDir\sim.log."
    exit 1
}

Write-Host "`nWaveform: $OutDir\sync_fifo.vcd"
Write-Host "Log:      $OutDir\sim.log"
