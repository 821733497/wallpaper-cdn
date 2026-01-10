param(
  [string]$Owner,
  [string]$Repo,
  [string]$Branch = "main",
  [switch]$UseJsdelivr,
  [switch]$PurgeJsdelivr,
  [int]$PreviewMaxWidth = 800,
  [int]$PreviewMaxHeight = 800,
  [string]$PreviewFormat = "png",
  [switch]$ForcePreview = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$fullDir = Join-Path $root "wallpapers/full"
$previewDir = Join-Path $root "wallpapers/preview"
$indexPath = Join-Path $root "index.json"

if (-not (Test-Path $fullDir)) { throw "Missing directory: $fullDir" }
if (-not (Test-Path $previewDir)) { throw "Missing directory: $previewDir" }

function Get-Sha256([string]$Path) {
  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($stream)
    return ([BitConverter]::ToString($hash) -replace "-", "").ToLowerInvariant()
  } finally {
    $stream.Dispose()
  }
}

function Get-ImageSize([string]$Path) {
  try {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($Path)
    try {
      return @{ width = $img.Width; height = $img.Height }
    } finally {
      $img.Dispose()
    }
  } catch {
    return @{ width = $null; height = $null }
  }
}

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

function Get-BaseUrl {
  param([string]$Owner, [string]$Repo, [string]$Branch, [switch]$UseJsdelivr)
  if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($Repo)) {
    return "https://cdn.jsdelivr.net/gh/<owner>/<repo>@$Branch/"
  }
  if ($UseJsdelivr) {
    return "https://cdn.jsdelivr.net/gh/$Owner/$Repo@$Branch/"
  }
  return "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/"
}

$baseUrl = Get-BaseUrl -Owner $Owner -Repo $Repo -Branch $Branch -UseJsdelivr:$UseJsdelivr

$files = Get-ChildItem -Path $fullDir -File | Sort-Object Name
$items = @()

foreach ($file in $files) {
  $id = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $previewExt = "." + $PreviewFormat.ToLowerInvariant().TrimStart(".")
  $previewFileName = if ($previewExt -eq $file.Extension) { $file.Name } else { $id + $previewExt }
  $previewPath = Join-Path $previewDir $previewFileName
  $previewExists = Test-Path $previewPath

  if (-not $previewExists -or $ForcePreview) {
    New-PreviewImage -SourcePath $file.FullName -DestPath $previewPath -MaxWidth $PreviewMaxWidth -MaxHeight $PreviewMaxHeight -Format $PreviewFormat
    $previewExists = $true
  }

  $size = $file.Length
  $hash = Get-Sha256 -Path $file.FullName
  $dims = Get-ImageSize -Path $file.FullName
  $updatedAt = $file.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")

  $items += [ordered]@{
    id = $id
    title = $id
    category = ""
    preview_url = ($baseUrl + "wallpapers/preview/" + $previewFileName)
    full_url = ($baseUrl + "wallpapers/full/" + $file.Name)
    size_bytes = $size
    hash_sha256 = $hash
    width = $dims.width
    height = $dims.height
    updated_at = $updatedAt
    preview_missing = -not $previewExists
  }
}

$output = [ordered]@{
  schema_version = "1.0"
  generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  items = $items
}

$json = $output | ConvertTo-Json -Depth 5
$json | Set-Content -Path $indexPath -Encoding utf8

Write-Host "Generated index.json with $($items.Count) items."

if ($UseJsdelivr -and $PurgeJsdelivr -and -not [string]::IsNullOrWhiteSpace($Owner) -and -not [string]::IsNullOrWhiteSpace($Repo)) {
  $purgeUrl = "https://purge.jsdelivr.net/gh/$Owner/$Repo@$Branch/index.json"
  try {
    Invoke-WebRequest -Uri $purgeUrl -Method Get -UseBasicParsing | Out-Null
    Write-Host "Purged jsDelivr cache: $purgeUrl"
  } catch {
    Write-Host "Failed to purge jsDelivr cache: $purgeUrl"
  }
}
