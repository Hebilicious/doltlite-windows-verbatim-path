# Creates a store at a plain path and at a verbatim path (\\?\C:\...), then reads HEAD from each.
param([string]$Doltlite = "", [string]$Version = "0.51.15")
$ErrorActionPreference = "Stop"

$work = Join-Path $PSScriptRoot ".tmp"
Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
New-Item -ItemType Directory $work | Out-Null

if (-not $Doltlite) {
    $zip = Join-Path $work "tools.zip"
    Invoke-WebRequest "https://github.com/dolthub/doltlite/releases/download/v$Version/doltlite-tools-win-x64-$Version.zip" -OutFile $zip
    Expand-Archive $zip (Join-Path $work "tools")
    $Doltlite = (Get-ChildItem -Recurse (Join-Path $work "tools") -Filter doltlite.exe | Select-Object -First 1).FullName
}
& $Doltlite --version

$plain = Join-Path $work "plain.db"
$verbatim = "\\?\" + (Join-Path $work "verbatim.db")
$failed = $false
foreach ($db in @($plain, $verbatim)) {
    & $Doltlite $db "CREATE TABLE t(id INTEGER PRIMARY KEY);"
    $head = & $Doltlite $db "SELECT dolt_hashof('HEAD');" 2>&1
    Write-Output "$db -> $head"
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}
if ($failed) { exit 1 }
