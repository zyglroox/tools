# select-streams.ps1
# Requires: ffmpeg.exe and ffprobe.exe
# Place this script in the same folder as your media files.

$ErrorActionPreference = "Stop"

# -----------------------------
# Helpers
# -----------------------------

function Read-Choice {
    param(
        [string]$Prompt,
        [int]$Min,
        [int]$Max
    )

    while ($true) {
        $value = Read-Host $Prompt

        if ([int]::TryParse($value, [ref]$null)) {
            $num = [int]$value

            if ($num -ge $Min -and $num -le $Max) {
                return $num
            }
        }

        Write-Host "Invalid input. Enter a number between $Min and $Max." -ForegroundColor Yellow
    }
}

function Read-MultiChoice {
    param(
        [string]$Prompt,
        [int]$Max
    )

    while ($true) {
        $inputValue = Read-Host $Prompt

        if ([string]::IsNullOrWhiteSpace($inputValue)) {
            return @()
        }

        $parts = $inputValue -split '[,\s]+' | Where-Object { $_ -ne "" }

        $valid = $true
        $result = @()

        foreach ($p in $parts) {
            if (-not [int]::TryParse($p, [ref]$null)) {
                $valid = $false
                break
            }

            $num = [int]$p

            if ($num -lt 0 -or $num -gt $Max) {
                $valid = $false
                break
            }

            $result += $num
        }

        if ($valid) {
            return $result | Select-Object -Unique
        }

        Write-Host "Invalid input. Example: 0,1,2" -ForegroundColor Yellow
    }
}

function Get-Language {
    param($Tags)

    if ($Tags -and $Tags.language) {
        return $Tags.language
    }

    return "und"
}

function Get-Title {
    param($Tags)

    if ($Tags -and $Tags.title) {
        return $Tags.title
    }

    return ""
}

# -----------------------------
# Check ffmpeg / ffprobe
# -----------------------------

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue

if (-not $ffmpeg) {
    Write-Host "ffmpeg not found in PATH." -ForegroundColor Red
    exit 1
}

if (-not $ffprobe) {
    Write-Host "ffprobe not found in PATH." -ForegroundColor Red
    exit 1
}

# -----------------------------
# Find media files
# -----------------------------

$extensions = @(
    ".mkv",
    ".mp4",
    ".mov",
    ".avi",
    ".m4v",
    ".ts",
    ".webm"
)

$files = Get-ChildItem -Path $PSScriptRoot -File | Where-Object {
    $_.Extension.ToLower() -in $extensions
}

if ($files.Count -eq 0) {
    Write-Host "No media files found." -ForegroundColor Yellow
    exit 0
}

# -----------------------------
# Select file
# -----------------------------

Write-Host ""
Write-Host "Available media files:" -ForegroundColor Cyan

for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host "[$i] $($files[$i].Name)"
}

$fileIndex = Read-Choice `
    -Prompt "Select file number" `
    -Min 0 `
    -Max ($files.Count - 1)

$selectedFile = $files[$fileIndex]

Write-Host ""
Write-Host "Selected: $($selectedFile.Name)" -ForegroundColor Green

# -----------------------------
# Read stream info
# -----------------------------

$probeJson = & ffprobe `
    -v quiet `
    -print_format json `
    -show_streams `
    -- "$($selectedFile.FullName)"

$probe = $probeJson | ConvertFrom-Json

$streams = $probe.streams

$videoStreams = @()
$audioStreams = @()
$subtitleStreams = @()

foreach ($stream in $streams) {
    switch ($stream.codec_type) {
        "video"    { $videoStreams += $stream }
        "audio"    { $audioStreams += $stream }
        "subtitle" { $subtitleStreams += $stream }
    }
}

# -----------------------------
# Select video stream
# -----------------------------

Write-Host ""
Write-Host "Video streams:" -ForegroundColor Cyan

for ($i = 0; $i -lt $videoStreams.Count; $i++) {
    $s = $videoStreams[$i]

    Write-Host "[$i] index=$($s.index) codec=$($s.codec_name) resolution=$($s.width)x$($s.height)"
}

$videoChoice = Read-Choice `
    -Prompt "Select video stream" `
    -Min 0 `
    -Max ($videoStreams.Count - 1)

# -----------------------------
# Select audio streams
# -----------------------------

$audioChoices = @()

if ($audioStreams.Count -gt 0) {

    Write-Host ""
    Write-Host "Audio streams:" -ForegroundColor Cyan

    for ($i = 0; $i -lt $audioStreams.Count; $i++) {
        $s = $audioStreams[$i]

        $lang = Get-Language $s.tags
        $title = Get-Title $s.tags

        Write-Host "[$i] index=$($s.index) codec=$($s.codec_name) lang=$lang title=$title"
    }

    $audioChoices = Read-MultiChoice `
        -Prompt "Select audio streams (comma separated, empty = none)" `
        -Max ($audioStreams.Count - 1)
}

# -----------------------------
# Select subtitle streams
# -----------------------------

$subtitleChoices = @()

if ($subtitleStreams.Count -gt 0) {

    Write-Host ""
    Write-Host "Subtitle streams:" -ForegroundColor Cyan

    for ($i = 0; $i -lt $subtitleStreams.Count; $i++) {
        $s = $subtitleStreams[$i]

        $lang = Get-Language $s.tags
        $title = Get-Title $s.tags

        Write-Host "[$i] index=$($s.index) codec=$($s.codec_name) lang=$lang title=$title"
    }

    $subtitleChoices = Read-MultiChoice `
        -Prompt "Select subtitle streams (comma separated, empty = none)" `
        -Max ($subtitleStreams.Count - 1)
}

# -----------------------------
# Output container logic
# -----------------------------

$originalExt = $selectedFile.Extension.ToLower()

# Safer behavior:
# - MKV stays MKV
# - everything else also defaults to original container
#
# If ffmpeg fails because container does not support streams,
# rerun and choose different streams or use MKV manually.

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($selectedFile.Name)

$outputFile = Join-Path `
    $selectedFile.DirectoryName `
    "$baseName-selected$originalExt"

# Prevent overwrite
if (Test-Path $outputFile) {

    $counter = 1

    do {
        $outputFile = Join-Path `
            $selectedFile.DirectoryName `
            "$baseName-selected-$counter$originalExt"

        $counter++
    }
    while (Test-Path $outputFile)
}

# -----------------------------
# Build ffmpeg args
# -----------------------------

$args = @(
    "-i", $selectedFile.FullName
)

# Video
$selectedVideo = $videoStreams[$videoChoice]
$args += @("-map", "0:$($selectedVideo.index)")

# Audio
foreach ($choice in $audioChoices) {
    $stream = $audioStreams[$choice]
    $args += @("-map", "0:$($stream.index)")
}

# Subtitles
foreach ($choice in $subtitleChoices) {
    $stream = $subtitleStreams[$choice]
    $args += @("-map", "0:$($stream.index)")
}

# Copy streams without re-encoding
$args += @(
    "-c", "copy",
    $outputFile
)

# -----------------------------
# Execute
# -----------------------------

Write-Host ""
Write-Host "Running ffmpeg..." -ForegroundColor Cyan
Write-Host ""

& ffmpeg @args

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Write-Host "Output: $outputFile"
}
else {
    Write-Host ""
    Write-Host "ffmpeg failed." -ForegroundColor Red
    Write-Host "The selected container may not support some chosen streams."
}