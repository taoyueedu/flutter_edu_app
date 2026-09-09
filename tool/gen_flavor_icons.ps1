# tool/gen_flavor_icons.ps1
# 用法：powershell -ExecutionPolicy Bypass -File tool/gen_flavor_icons.ps1
# 前置：assets/icon/dev.png staging.png prod.png（1024x1024）
Add-Type -AssemblyName System.Drawing

$targets = @(
    @{ Flavor = 'dev';     Src = 'assets/icon/dev.png' },
    @{ Flavor = 'staging'; Src = 'assets/icon/staging.png' },
    @{ Flavor = 'prod';    Src = 'assets/icon/prod.png' }
)

# Android launcher icon 各密度尺寸（px）
$densities = @(
    @{ Dpi = 'mdpi';    Size = 48 },
    @{ Dpi = 'hdpi';    Size = 72 },
    @{ Dpi = 'xhdpi';   Size = 96 },
    @{ Dpi = 'xxhdpi';  Size = 144 },
    @{ Dpi = 'xxxhdpi'; Size = 192 }
)

foreach ($t in $targets) {
    $srcPath = Join-Path $PSScriptRoot '..' $t.Src
    if (-not (Test-Path $srcPath)) {
        Write-Host "缺少源图: $($t.Src)，跳过 $($t.Flavor)" -ForegroundColor Yellow
        continue
    }
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath))
    foreach ($d in $densities) {
        $outDir = Join-Path $PSScriptRoot '..' "android/app/src/$($t.Flavor)/res/mipmap-$($d.Dpi)"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $bmp = New-Object System.Drawing.Bitmap $img, $d.Size, $d.Size
        $outFile = Join-Path $outDir 'ic_launcher.png'
        $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "生成 $outFile"
    }
    $img.Dispose()
}
Write-Host "完成。三套图标已写入对应 flavor 的 res 目录。"