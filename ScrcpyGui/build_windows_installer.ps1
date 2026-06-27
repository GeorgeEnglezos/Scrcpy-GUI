# Local Windows build: mirrors the CI steps in .github/workflows/build.yml.
# Builds the Flutter release, bundles the MSVC runtime DLLs next to the exe so
# the app launches on machines without VC++ redist (winget validation VM hit
# STATUS_DLL_NOT_FOUND / 0xC0000135), then builds the Inno setup.exe.
#
# Run from the ScrcpyGui/ directory:
#   powershell -ExecutionPolicy Bypass -File build_windows_installer.ps1
#   powershell -ExecutionPolicy Bypass -File build_windows_installer.ps1 -SkipFlutterBuild   # reuse existing build

param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = 'Stop'
$ReleaseDir = 'build\windows\x64\runner\Release'

# 1. Flutter release build
if (-not $SkipFlutterBuild) {
    Write-Host '==> flutter build windows --release' -ForegroundColor Cyan
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }
}

# 2. Bundle the Visual C++ runtime DLLs
Write-Host '==> Bundling Visual C++ runtime DLLs' -ForegroundColor Cyan
$vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
$crtDir = Get-ChildItem -Path (Join-Path $vsPath 'VC\Redist\MSVC') -Recurse -Directory -Filter 'Microsoft.VC*.CRT' |
    Where-Object { $_.FullName -like '*\x64\*' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if (-not $crtDir) { throw "Could not locate the VC++ x64 CRT redist folder under $vsPath" }
Write-Host "    CRT redist: $($crtDir.FullName)"
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    Copy-Item (Join-Path $crtDir.FullName $dll) (Join-Path $ReleaseDir $dll) -Force
    Write-Host "    Bundled $dll"
}

# 3. Build the Inno Setup installer
Write-Host '==> Building Inno Setup installer' -ForegroundColor Cyan
$iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $iscc)) {
    Write-Warning "Inno Setup not found at $iscc"
    Write-Warning 'Install it (winget install JRSoftware.InnoSetup) to produce setup.exe.'
    Write-Host 'DLLs are bundled in the Release folder; the installer step was skipped.' -ForegroundColor Yellow
    exit 0
}
$raw = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$version = ($raw -split '\+')[0] -split '-' | Select-Object -First 1
Write-Host "    Version: $version"
& $iscc "/DMyAppVersion=$version" installer.iss
if ($LASTEXITCODE -ne 0) { throw 'ISCC failed' }
Write-Host "==> Done: artifacts\windows_installer\scrcpy-gui-setup.exe" -ForegroundColor Green
