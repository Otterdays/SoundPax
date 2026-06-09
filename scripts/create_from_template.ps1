# Creates a new Flutter + Rust app from this boilerplate template.
# Usage:
#   .\scripts\create_from_template.ps1 -AppName "My App" -Org "com.mycompany" -OutputDir "C:\dev\my_app"

param(
    [Parameter(Mandatory = $true)]
    [string]$AppName,

    [Parameter(Mandatory = $true)]
    [string]$Org,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"

function ConvertTo-SnakeCase {
    param([string]$Name)
    $s = $Name.Trim().ToLower()
    $s = $s -replace '[^a-z0-9]+', '_'
    $s = $s -replace '^_+|_+$', ''
    if ($s -match '^[0-9]') { $s = "app_$s" }
    if ([string]::IsNullOrWhiteSpace($s)) { throw "AppName must contain at least one letter or digit." }
    return $s
}

function ConvertTo-CamelCase {
    param([string]$Snake)
    $parts = $Snake -split '_'
    $first = $parts[0]
    $rest = $parts | Select-Object -Skip 1 | ForEach-Object {
        if ($_.Length -eq 0) { return $_ }
        $_.Substring(0, 1).ToUpper() + $_.Substring(1)
    }
    return $first + ($rest -join '')
}

$TemplateRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $TemplateRoot "template.lock.json"))) {
    throw "Run this script from the rusty-flutter template repo."
}

$SnakeName = ConvertTo-SnakeCase $AppName
$RustCrate = "rust_lib_$SnakeName"
$CamelName = ConvertTo-CamelCase $SnakeName
$DisplayName = ($AppName.Trim() -replace '\s+', ' ')

$OldSnake = "soundpax"
$OldRustCrate = "rust_lib_soundpax"
$OldOrg = "com.otterdays"
$OldCamel = "rustyFlutter"
$OldDisplay = "SoundPax"

if (Test-Path $OutputDir) {
    throw "Output directory already exists: $OutputDir"
}

Write-Host "Template: $TemplateRoot"
Write-Host "Creating: $OutputDir"
Write-Host "  Dart package : $SnakeName"
Write-Host "  Rust crate     : $RustCrate"
Write-Host "  Org            : $Org"
Write-Host ""

New-Item -ItemType Directory -Path $OutputDir | Out-Null

$ignoreFile = Join-Path $TemplateRoot ".templateignore"
$ignorePatterns = @()
if (Test-Path $ignoreFile) {
    $ignorePatterns = Get-Content $ignoreFile |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        ForEach-Object { $_.TrimEnd('/') }
}

function Should-Skip {
    param([string]$RelativePath)
    $RelativePath = $RelativePath -replace '\\', '/'
    foreach ($pattern in $ignorePatterns) {
        $p = $pattern.TrimEnd('/')
        if ($pattern.EndsWith('*')) {
            if ($RelativePath -like "$p*") { return $true }
        }
        elseif ($RelativePath -eq $p -or $RelativePath -like "$p/*") {
            return $true
        }
    }
    return $false
}

$textExtensions = @(
    '.dart', '.yaml', '.yml', '.json', '.md', '.txt', '.bat', '.ps1', '.sh', '.cmd',
    '.xml', '.html', '.gradle', '.kts', '.properties', '.plist', '.xcconfig',
    '.pbxproj', '.swift', '.cmake', '.rs', '.toml', '.podspec', '.cc', '.h', '.rc',
    '.gitignore', '.metadata', '.iml'
)

Get-ChildItem -Path $TemplateRoot -Recurse -Force | ForEach-Object {
    $rel = $_.FullName.Substring($TemplateRoot.Length).TrimStart('\', '/')
    if ($rel -eq '') { return }
    if (Should-Skip $rel) { return }

    $dest = Join-Path $OutputDir $rel
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        return
    }

    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $destName = Split-Path $dest -Leaf
    $destName = $destName -replace [regex]::Escape($OldSnake), $SnakeName
    $destName = $destName -replace [regex]::Escape($OldRustCrate), $RustCrate
    $dest = Join-Path $destDir $destName

    $ext = if ($_.Extension) { $_.Extension.ToLowerInvariant() } else { '' }
    if ($textExtensions -contains $ext -or $_.Name -eq '.gitignore' -or $_.Name -eq '.metadata') {
        $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
        if ($null -eq $content) { $content = '' }
        $content = $content.Replace($OldRustCrate, $RustCrate)
        $content = $content.Replace($OldSnake, $SnakeName)
        $content = $content.Replace("$OldOrg.$OldCamel", "$Org.$CamelName")
        $content = $content.Replace("$OldOrg.$OldSnake", "$Org.$SnakeName")
        $content = $content.Replace($OldOrg, $Org)
        $content = $content.Replace($OldDisplay, $DisplayName)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($dest, $content, $utf8NoBom)
    }
    else {
        Copy-Item -Path $_.FullName -Destination $dest -Force
    }
}

Write-Host "Running flutter pub get..."
$env:Path = "$env:LOCALAPPDATA\flutter\bin;$env:USERPROFILE\.cargo\bin;$env:Path"
Push-Location $OutputDir
try {
    & flutter pub get 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed (exit $LASTEXITCODE). Enable Windows Developer Mode if symlink errors appear." }

    Write-Host "Regenerating flutter_rust_bridge bindings..."
    & flutter_rust_bridge_codegen generate
    if ($LASTEXITCODE -ne 0) { throw "flutter_rust_bridge_codegen generate failed" }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Done. New project ready at:"
Write-Host "  $OutputDir"
Write-Host ""
Write-Host "Next:"
Write-Host "  cd `"$OutputDir`""
Write-Host "  flutter run -d chrome"
