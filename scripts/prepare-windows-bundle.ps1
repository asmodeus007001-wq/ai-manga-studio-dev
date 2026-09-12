[CmdletBinding()]
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")),
  [string]$WebProject = "..\ai-manga-studio-resumed",
  [string]$OutputDir = "installer\bundle"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectRoot).Path
$out = Join-Path $root $OutputDir
$app = Join-Path $out "app"
$runtime = Join-Path $out "runtime"
$comfy = Join-Path $out "comfyui"
$data = Join-Path $out "data"

function Require-Path([string]$Path, [string]$Message) {
  if (!(Test-Path $Path)) { throw $Message }
}

$web = (Resolve-Path (Join-Path $root $WebProject)).Path
Require-Path (Join-Path $web "package.json") "Web project package.json not found: $web"
Require-Path (Join-Path $web "dist\index.js") "Run pnpm build in the WebDev project before preparing the bundle."
Require-Path (Join-Path $root "installer\runtime\node.exe") "Place the Windows x64 Node runtime at installer/runtime/node.exe."
Require-Path (Join-Path $root "installer\comfyui") "Place the independent patientx-cfz/comfyui-rocm installation at installer/comfyui."

Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue
New-Item $app, $runtime, $comfy, $data -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $web "dist") (Join-Path $app "dist") -Recurse
Copy-Item (Join-Path $web "package.json") (Join-Path $app "package.json")
Copy-Item (Join-Path $web "pnpm-lock.yaml") (Join-Path $app "pnpm-lock.yaml")
Copy-Item (Join-Path $root "installer\runtime\node.exe") (Join-Path $runtime "node.exe")
Copy-Item (Join-Path $root "installer\comfyui\*") $comfy -Recurse
Copy-Item (Join-Path $root "installer\launchers\*") $out -Recurse

@"
AI Manga Studio bundle prepared: $(Get-Date -Format o)
The bundle contains the WebDev production server, Windows Node runtime, independent ComfyUI runtime, and user data directory.
"@ | Set-Content (Join-Path $out "BUNDLE-MANIFEST.txt") -Encoding UTF8
Write-Host "Bundle ready: $out"
