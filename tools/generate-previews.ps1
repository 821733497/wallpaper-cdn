param(
  [string]$ContentDir = "wallpapers",
  [int]$PreviewMaxWidth = 800,
  [int]$PreviewMaxHeight = 800,
  [string]$PreviewFormat = "png",
  [switch]$ForcePreview,
  [int]$BatchSize = 30,
  [int]$BatchIndex = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$fullDir = Join-Path $root (Join-Path $ContentDir "full")
$previewDir = Join-Path $root (Join-Path $ContentDir "preview")

if (-not (Test-Path $fullDir)) { throw "Missing directory: $fullDir" }
if (-not (Test-Path $previewDir)) { throw "Missing directory: $previewDir" }
if ($BatchSize -lt 1) { throw "BatchSize must be >= 1" }
if ($BatchIndex -lt 0) { throw "BatchIndex must be >= 0" }

function New-PreviewImage {
  param(
    [string]$SourcePath,
    [string]$DestPath,
    [int]$MaxWidth,
    [int]$MaxHeight,
    [string]$Format
  )

  Add-Type -AssemblyName System.Drawing
  $src = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    $scaleW = [double]$MaxWidth / [double]$src.Width
    $scaleH = [double]$MaxHeight / [double]$src.Height
    $scale = [Math]::Min(1.0, [Math]::Min($scaleW, $scaleH))

    $newW = [Math]::Max(1, [int][Math]::Round($src.Width * $scale))
    $newH = [Math]::Max(1, [int][Math]::Round($src.Height * $scale))

    $bmp = New-Object System.Drawing.Bitmap $newW, $newH
    try {
      $gfx = [System.Drawing.Graphics]::FromImage($bmp)
      try {
        $gfx.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $gfx.DrawImage($src, 0, 0, $newW, $newH)
      } finally {
        $gfx.Dispose()
      }

      $fmt = [System.Drawing.Imaging.ImageFormat]::Png
      if ($Format -ieq "jpg" -or $Format -ieq "jpeg") { $fmt = [System.Drawing.Imaging.ImageFormat]::Jpeg }
      if ($Format -ieq "bmp") { $fmt = [System.Drawing.Imaging.ImageFormat]::Bmp }
      if ($Format -ieq "gif") { $fmt = [System.Drawing.Imaging.ImageFormat]::Gif }

      $bmp.Save($DestPath, $fmt)
    } finally {
      $bmp.Dispose()
    }
  } finally {
    $src.Dispose()
  }
}

$files = @(Get-ChildItem -Path $fullDir -File | Sort-Object Name)
$total = $files.Count
$start = $BatchIndex * $BatchSize
$end = [Math]::Min($start + $BatchSize, $total)

if ($start -ge $total) {
  Write-Host "No files to process for batch $BatchIndex."
  exit 0
}

Write-Host ("Processing batch {0}: {1}..{2} of {3} files." -f $BatchIndex, $start, ($end - 1), $total)

for ($i = $start; $i -lt $end; $i++) {
  $file = $files[$i]
  $id = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $previewExt = "." + $PreviewFormat.ToLowerInvariant().TrimStart(".")
  $previewFileName = if ($previewExt -eq $file.Extension) { $file.Name } else { $id + $previewExt }
  $previewPath = Join-Path $previewDir $previewFileName
  $previewExists = Test-Path $previewPath

  if (-not $previewExists -or $ForcePreview) {
    try {
      New-PreviewImage -SourcePath $file.FullName -DestPath $previewPath -MaxWidth $PreviewMaxWidth -MaxHeight $PreviewMaxHeight -Format $PreviewFormat
      Write-Host "Preview generated: $($file.Name)"
    } catch {
      Write-Host "Preview failed: $($file.Name) - $($_.Exception.Message)"
    }
  } else {
    Write-Host "Preview exists: $($file.Name)"
  }
}
