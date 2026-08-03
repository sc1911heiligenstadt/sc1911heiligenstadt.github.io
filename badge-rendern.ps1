# Rendert die aeussere Wappenkontur aus logo.svg als einfarbiges Badge-Icon.
# Fuer ein Android-Badge zaehlt NUR die Silhouette: das System zeichnet alle
# sichtbaren Pixel weiss. Deshalb die Kontur, nicht das ganze Wappen.
param([int]$Groesse = 96, [int]$Rand = 6, [string]$Ziel)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# viewBox aus logo.svg
$VB_W = 198.425; $VB_H = 226.7719
$nutz = $Groesse - 2 * $Rand
$s = [Math]::Min($nutz / $VB_W, $nutz / $VB_H)
$offX = ($Groesse - $VB_W * $s) / 2
$offY = ($Groesse - $VB_H * $s) / 2
function P($x, $y) { New-Object System.Drawing.PointF(([float]($offX + $x * $s)), ([float]($offY + $y * $s))) }

# Pfad 1 aus logo.svg, Kommando fuer Kommando uebernommen
$pfad = New-Object System.Drawing.Drawing2D.GraphicsPath
$pfad.AddBezier((P 98.9821 225.654), (P 76.7711 218.781), (P 51.3991 207.64),  (P 31.6178 177.124))
$pfad.AddBezier((P 31.6178 177.124),(P 20.3893 159.802), (P 12.1491 137.721), (P 7.1285 111.495))
$pfad.AddBezier((P 7.1285 111.495), (P 1.3004 81.0698),  (P -0.3822 44.1459), (P 2.1286 1.7504))
$pfad.AddLine((P 2.1286 1.7504), (P 2.1735 0.9999))
$pfad.AddLine((P 2.1735 0.9999), (P 196.252 0.9999))
$pfad.AddLine((P 196.252 0.9999), (P 196.297 1.7509))
$pfad.AddBezier((P 196.297 1.7509),(P 198.807 44.1459),(P 197.125 81.0698), (P 191.297 111.495))
$pfad.AddBezier((P 191.297 111.495),(P 186.276 137.721),(P 178.036 159.802),(P 166.807 177.124))
$pfad.AddBezier((P 166.807 177.124),(P 147.026 207.64),(P 121.654 218.781), (P 99.443 225.654))
$pfad.AddLine((P 99.443 225.654), (P 99.2125 225.725))
$pfad.CloseFigure()

$bmp = New-Object System.Drawing.Bitmap($Groesse, $Groesse, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$g.FillPath([System.Drawing.Brushes]::White, $pfad)
$g.Dispose()

$bmp.Save($Ziel, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$pfad.Dispose()
"Geschrieben: $Ziel ($Groesse x $Groesse)"

# Zum Ansehen: weiss auf transparent ist auf hellem Grund unsichtbar. Diese
# Vorschau legt dieselbe Form auf dunklen Grund und zeigt sie zusaetzlich in
# 24 px -- so klein steht sie in der Android-Statusleiste, und nur dort
# entscheidet sich, ob die Form noch etwas taugt.
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($Ziel)
$vor = New-Object System.Drawing.Bitmap(320, 130)
$g2 = [System.Drawing.Graphics]::FromImage($vor)
$g2.Clear([System.Drawing.Color]::FromArgb(30, 33, 40))
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.DrawImage($img, 20, 20, 96, 96)
$g2.DrawImage($img, 150, 40, 24, 24)
$g2.DrawImage($img, 200, 25, 88, 88)
$g2.Dispose(); $img.Dispose()
$vorschau = [System.IO.Path]::ChangeExtension($Ziel, ".vorschau.png")
$vor.Save($vorschau, [System.Drawing.Imaging.ImageFormat]::Png)
$vor.Dispose()
"Vorschau:   $vorschau"
