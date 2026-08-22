# Automated Release APK Builder & Custom Renamer for FinPlus
# Usage: powershell -ExecutionPolicy Bypass -File .\build_release_apks.ps1

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  FinPlus Release APK Automation Builder & Renamer" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Parse version from pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$versionMatch = [regex]::Match($pubspecContent, "version:\s*([0-9]+\.[0-9]+\.[0-9]+)")
if ($versionMatch.Success) {
    $version = "v" + $versionMatch.Groups[1].Value
} else {
    $version = "v1.0.0"
}

Write-Host "`n[1/3] Detected Application Version: $version" -ForegroundColor Green

# 2. Build Split-per-ABI Release APKs
Write-Host "[2/3] Building split-per-ABI Release APKs (flutter build apk --release --split-per-abi)..." -ForegroundColor Yellow
flutter build apk --release --split-per-abi

# 3. Build Universal Release APK
Write-Host "[3/3] Building Universal Release APK (flutter build apk --release)..." -ForegroundColor Yellow
flutter build apk --release

# 4. Target Directory
$outputDir = "build\app\outputs\flutter-apk"

# 5. Rename/Copy to Exact Custom Naming Scheme
$mapping = @{
    "app-arm64-v8a-release.apk"   = "FinPlus-$version-arm64-v8a-release.apk"
    "app-armeabi-v7a-release.apk" = "FinPlus-$version-armeabi-v7a-release.apk"
    "app-x86_64-release.apk"      = "FinPlus-$version-x86_64-release.apk"
    "app-release.apk"             = "FinPlus-$version-universal-release.apk"
}

Write-Host "`nApplying Custom Release Naming Convention..." -ForegroundColor Cyan

foreach ($src in $mapping.Keys) {
    $srcPath = Join-Path $outputDir $src
    $destPath = Join-Path $outputDir $mapping[$src]
    if (Test-Path $srcPath) {
        Copy-Item -Path $srcPath -Destination $destPath -Force
        Write-Host " -> Created: $($mapping[$src])" -ForegroundColor Green
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Built Release Artifacts Ready for GitHub Release:" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Get-ChildItem -Path $outputDir -Filter "FinPlus-$version-*.apk" | Select-Object Name, @{Name="Size (MB)"; Expression={[math]::round($_.Length / 1MB, 2)}} | Format-Table -AutoSize
