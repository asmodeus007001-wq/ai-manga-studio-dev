[CmdletBinding()]
param([string]$KitRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")))

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $KitRoot).Path
$bundle = Join-Path $root "installer\bundle"
$runtimeSource = Join-Path $root "installer\runtime\node.exe"
$comfySource = Join-Path $root "installer\comfyui"

if (!(Test-Path (Join-Path $bundle "app\dist\index.js"))) {
  throw "Production build missing: installer/bundle/app/dist/index.js"
}
if (!(Test-Path $runtimeSource)) {
  throw "Put Windows x64 node.exe at installer/runtime/node.exe first."
}
if (!(Test-Path (Join-Path $comfySource "main.py"))) {
  throw "Put the independent comfyui-rocm installation at installer/comfyui first."
}

New-Item (Join-Path $bundle "runtime") -ItemType Directory -Force | Out-Null
New-Item (Join-Path $bundle "comfyui") -ItemType Directory -Force | Out-Null
Copy-Item $runtimeSource (Join-Path $bundle "runtime\node.exe") -Force
Copy-Item (Join-Path $comfySource "*") (Join-Path $bundle "comfyui") -Recurse -Force
Write-Host "Bundle finalized. Compile from installer with: iscc .\AI-Manga-Studio.iss"
