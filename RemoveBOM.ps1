<#
.DESCRIPTION
Remove BOM (Byte Order Mark) for LSP.ps1. It's a special 3-byte sequence (EF BB BF in hexadecimal) that VS Code adds to the start of UTF-8 files to mark them as UTF-8 encoded.
#>

$path = '.\LSP.ps1'
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bytesNoBOM = $bytes[3..($bytes.Length-1)]
    [System.IO.File]::WriteAllBytes($path, $bytesNoBOM)
    Write-Host "BOM removed from $path"
} else {
    Write-Host "No BOM found"
}