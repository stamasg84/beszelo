# Generates voices/samples/<voice-id>.wav for every voice in voices/catalog.json.
# With -Clean, removes tool/.venv, tool/.cache, uv's managed Python 3.12 and uv's
# package cache afterwards (uv itself stays installed).
# Sets up tool/.venv (Python 3.12 via uv, sherpa-onnx pinned to the app's 1.x version).
param([switch]$Force, [switch]$Clean)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $PSScriptRoot '.venv'
$py = Join-Path $venv 'Scripts/python.exe'
$sherpaVersion = '1.13.8'   # same as pubspec.yaml (2.x dropped espeak-ng)

if (-not (Test-Path $py)) {
    # No 1.x wheels exist for the newest Pythons, so ask uv for a managed 3.12.
    python -m pip install --user uv
    python -m uv venv --python 3.12 $venv
    python -m uv pip install --python $py "sherpa-onnx==$sherpaVersion" numpy
}
$args2 = @($root)
if ($Force) { $args2 += '--force' }
& $py (Join-Path $PSScriptRoot 'make_samples.py') @args2
if ($LASTEXITCODE -ne 0) { throw 'make_samples.py failed' }

if ($Clean) {
    Remove-Item -Recurse -Force $venv, (Join-Path $PSScriptRoot '.cache') -ErrorAction SilentlyContinue
    python -m uv python uninstall 3.12
    python -m uv cache clean
    Write-Host 'Cleaned tool/.venv, tool/.cache and uv caches.'
}
