param(
    [string[]]$FlutterArgs = @()
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $PSScriptRoot 'supabase.local.json'

if (-not (Test-Path $configPath)) {
    Write-Error "Missing local Supabase config: $configPath. Copy tool/supabase.local.example.json to tool/supabase.local.json and fill in SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY first."
}

Push-Location $projectRoot
try {
    & flutter run --dart-define-from-file=$configPath @FlutterArgs
}
finally {
    Pop-Location
}