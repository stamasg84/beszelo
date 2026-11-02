# Copies voices/catalog.json (source of truth) to assets/catalog.json (bundled fallback).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force (Join-Path $root 'assets') | Out-Null
Copy-Item (Join-Path $root 'voices/catalog.json') (Join-Path $root 'assets/catalog.json') -Force
Write-Host 'assets/catalog.json updated.'
