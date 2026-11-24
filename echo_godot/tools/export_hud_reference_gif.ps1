param(
    [string]$Frames = (Join-Path $PSScriptRoot '..\.godot\hud_reference_frames\solana_v2'),
    [string]$Output = (Join-Path $PSScriptRoot '..\art_preview\hud_solana_v2_sequencia.gif')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore
$sourceDirectory = [IO.Path]::GetFullPath($Frames)
$outputFile = [IO.Path]::GetFullPath($Output)
$images = @(Get-ChildItem -LiteralPath $sourceDirectory -Filter 'frame_*.png' -File | Sort-Object Name)
if ($images.Count -ne 144) { throw "Expected 144 frames; found $($images.Count)" }
$encoder = [System.Windows.Media.Imaging.GifBitmapEncoder]::new()
for ($index = 0; $index -lt $images.Count; $index++) {
    $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
    $bitmap.BeginInit()
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.UriSource = [Uri]::new($images[$index].FullName)
    $bitmap.EndInit()
    $bitmap.Freeze()
    $metadata = [System.Windows.Media.Imaging.BitmapMetadata]::new('gif')
    # 8/8/9 centiseconds gives 12 fps without cumulative timing drift.
    $metadata.SetQuery('/grctlext/Delay', [UInt16](8 + [int]($index % 3 -eq 2)))
    $metadata.SetQuery('/grctlext/Disposal', [byte]2)
    $frame = [System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap, $null, $metadata, $null)
    $encoder.Frames.Add($frame)
}
$stream = [IO.File]::Open($outputFile, [IO.FileMode]::Create, [IO.FileAccess]::Write)
try { $encoder.Save($stream) } finally { $stream.Dispose() }

# Standard GIF loop extension; all frames are generated locally by Godot.
$bytes = [IO.File]::ReadAllBytes($outputFile)
$paletteBytes = if (($bytes[10] -band 128) -ne 0) { 3 * [int][Math]::Pow(2, 1 + ($bytes[10] -band 7)) } else { 0 }
$offset = 13 + $paletteBytes
# WPF may discard frame delay metadata. Set the GIF control blocks explicitly.
$cursor = $offset
$controlCount = 0
$frameCount = 0
while ($cursor -lt $bytes.Length) {
    $tag = $bytes[$cursor]
    $cursor++
    if ($tag -eq 0x3B) { break }
    if ($tag -eq 0x21) {
        $label = $bytes[$cursor]
        $cursor++
        if ($label -eq 0xF9) {
            $bytes[$cursor + 1] = ($bytes[$cursor + 1] -band 0xE3) -bor 8
            $bytes[$cursor + 2] = 8 + [int]($controlCount % 3 -eq 2)
            $bytes[$cursor + 3] = 0
            $controlCount++
        }
    } elseif ($tag -eq 0x2C) {
        $flags = $bytes[$cursor + 8]
        $cursor += 9
        if (($flags -band 128) -ne 0) { $cursor += 3 * [int][Math]::Pow(2, 1 + ($flags -band 7)) }
        $cursor++ # LZW minimum code size, followed by image data sub-blocks.
        $frameCount++
    } else { throw "Unexpected GIF block: $tag" }
    while ($bytes[$cursor] -ne 0) { $cursor += 1 + $bytes[$cursor] }
    $cursor++
}
if ($controlCount -ne 144 -or $frameCount -ne 144) { throw 'GIF frame/control block count mismatch' }
[byte[]]$extension = @(0x21, 0xFF, 0x0B) + [Text.Encoding]::ASCII.GetBytes('NETSCAPE2.0') + @(0x03, 0x01, 0x00, 0x00, 0x00)
$patched = [IO.MemoryStream]::new()
try {
    $patched.Write($bytes, 0, $offset)
    $patched.Write($extension, 0, $extension.Length)
    $patched.Write($bytes, $offset, $bytes.Length - $offset)
    [IO.File]::WriteAllBytes($outputFile, $patched.ToArray())
} finally { $patched.Dispose() }
Write-Output "GIF exported: $outputFile ($($images.Count) frames, 12 seconds)"
