[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $Python = 'python'
    }
    else {
        Write-Error "python3 was not found in PATH. Install Python 3.8 or newer first."
        exit 1
    }
}
else {
    $Python = 'python3'
}

foreach ($Script in @('quantize.py', 'base_convert.py', 'binary_add.py', 'signed_codes.py', 'sign_extend.py', 'overflow_carry.py', 'bcd_decimal.py', 'gray_reflection.py')) {
    Write-Host "`n########## $Script ##########"
    & $Python $Script
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$Script failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

Write-Host "`n########## self-check ##########"
& $Python tests/test_check.py
if ($LASTEXITCODE -ne 0) {
    Write-Error "Self-check failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}
