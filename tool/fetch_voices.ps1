# Downloads and extracts Piper voices (sherpa-onnx builds) into assets/voices/.
# Idempotent: skips voices whose folder already exists.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root 'assets/voices'
$base = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models'
$voices = @('vits-piper-hu_HU-imre-medium')

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($v in $voices) {
    $dir = Join-Path $dest $v
    if (Test-Path $dir) { Write-Host "$v already present, skipping."; continue }
    $archive = Join-Path $env:TEMP "$v.tar.bz2"
    Write-Host "Downloading $v ..."
    Invoke-WebRequest -Uri "$base/$v.tar.bz2" -OutFile $archive
    # Use Windows' own tar (Git's GNU tar misreads "C:" as a remote host).
    & (Join-Path $env:SystemRoot 'System32\tar.exe') -xf $archive -C $dest
    if ($LASTEXITCODE -ne 0) { throw "tar failed for $v" }
    Remove-Item $archive
    Write-Host "Extracted to $dir"
}
