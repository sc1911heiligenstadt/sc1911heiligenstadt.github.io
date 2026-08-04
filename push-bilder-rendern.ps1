# Rendert die beiden Bilder der Push-Nachricht aus dem monochromen Wappen.
#
#   badge-96.png       Symbol in der Android-Statusleiste -- nur Silhouette
#   push-icon-192.png  Bild neben Titel und Text der aufgeklappten Meldung
#
# ⚠️ Ueberschreibt NICHT icon-192.png. Das steht in manifest.json und ist
# zugleich das App-Icon auf dem Startbildschirm -- es bleibt das farbige Wappen
# auf Vereinsblau. Nur die Push-Nachricht bekommt diese beiden Dateien.
#
# Quelle ist logo-monochrom.png, nicht logo.svg: das SVG ist zweifarbig
# separiert (linke Schildhaelfte hell mit dunklen Formen, rechte Haelfte
# umgekehrt), das Rad ist dort also mal gefuellter Pfad und mal Aussparung.
# Aus seinen 51 Pfaden laesst sich "nur das Rad" nicht herausgreifen. Die
# monochrome Vorlage ist gerastert und dadurch fuer diesen Zweck brauchbarer.
#
# ⚠️ logo.svg NICHT anfassen -- 38 Seiten in 32 Repos laden diese Datei direkt.
#
# Herkunft von logo-monochrom.png: WhatsApp-Vorlage vom 2026-08-04, auf das
# Wappen beschnitten, auf 1024 px Hoehe gerechnet, Kontrast gespreizt
# (Luminanz <40 -> schwarz, >215 -> weiss) und als 8-Bit-Graustufen gespeichert.
# Die Spreizung ist reine Dateigroesse: JPEG-Artefaktrauschen um jede Kante
# liess das PNG sonst auf 861 KB statt 110 KB anwachsen.
param(
  [string]$Quelle = "$PSScriptRoot\logo-monochrom.png",
  [string]$Ordner = $PSScriptRoot
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$hilfe = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Wappen {
  // Liest ein Bild als Alpha-Maske: Helligkeit wird zur Deckung.
  // hellIstDeckend=true  -> weisse Pixel deckend  (das Wappen selbst)
  // hellIstDeckend=false -> dunkle Pixel deckend  (Radmaterial der hellen Haelfte)
  public static Bitmap AlsMaske(Bitmap q, bool hellIstDeckend) {
    int w = q.Width, h = q.Height;
    Bitmap ziel = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    BitmapData dq = q.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    BitmapData dz = ziel.LockBits(new Rectangle(0,0,w,h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    int n = w * h * 4;
    byte[] a = new byte[n], b = new byte[n];
    Marshal.Copy(dq.Scan0, a, 0, n);
    for (int i = 0; i < n; i += 4) {
      // BGRA im Speicher. Luminanz nach Rec.709.
      double lum = 0.0722*a[i] + 0.7152*a[i+1] + 0.2126*a[i+2];
      if (lum > 255.0) lum = 255.0;
      byte alpha = (byte)Math.Round(hellIstDeckend ? lum : 255.0 - lum);
      b[i] = 255; b[i+1] = 255; b[i+2] = 255; b[i+3] = alpha;
    }
    Marshal.Copy(b, 0, dz.Scan0, n);
    q.UnlockBits(dq); ziel.UnlockBits(dz);
    return ziel;
  }

  // Schneidet die Maske auf einen Kreis zu und behaelt nur die linke Haelfte.
  // Nur links liegt das Radmaterial durchgehend dunkel auf hellem Grund und
  // laesst sich sauber greifen. Die rechte Haelfte entsteht spaeter durch
  // Spiegelung -- das Rad ist achsensymmetrisch.
  public static Bitmap LinkeKreisHaelfte(Bitmap q, double cx, double cy, double r) {
    int w = q.Width, h = q.Height;
    BitmapData dq = q.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    int n = w * h * 4;
    byte[] a = new byte[n];
    Marshal.Copy(dq.Scan0, a, 0, n);
    double r2 = r * r;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int i = y * dq.Stride + x * 4;
        double dx = x - cx, dy = y - cy;
        if (x > cx || dx*dx + dy*dy > r2) a[i+3] = 0;
      }
    }
    Marshal.Copy(a, 0, dq.Scan0, n);
    q.UnlockBits(dq);
    return q;
  }

  // Nimmt der Flaeche ihre Deckung dort weg, wo die Maske deckt. So wird das
  // Rad zur Aussparung in der Schildsilhouette.
  public static void Ausstanzen(Bitmap flaeche, Bitmap maske) {
    int w = flaeche.Width, h = flaeche.Height;
    BitmapData df = flaeche.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    BitmapData dm = maske.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int n = w * h * 4;
    byte[] f = new byte[n], m = new byte[n];
    Marshal.Copy(df.Scan0, f, 0, n);
    Marshal.Copy(dm.Scan0, m, 0, n);
    for (int i = 0; i < n; i += 4) {
      f[i+3] = (byte)Math.Round(f[i+3] * (255.0 - m[i+3]) / 255.0);
    }
    Marshal.Copy(f, 0, df.Scan0, n);
    flaeche.UnlockBits(df); maske.UnlockBits(dm);
  }

  // Bounding-Box der sichtbaren Pixel einer Maske.
  public static int[] Inhalt(Bitmap q, int schwelle) {
    int w = q.Width, h = q.Height;
    BitmapData d = q.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int n = w * h * 4;
    byte[] a = new byte[n];
    Marshal.Copy(d.Scan0, a, 0, n);
    int minX = w, minY = h, maxX = -1, maxY = -1;
    for (int y = 0; y < h; y++)
      for (int x = 0; x < w; x++) {
        if (a[y * d.Stride + x * 4 + 3] > schwelle) {
          if (x < minX) minX = x; if (x > maxX) maxX = x;
          if (y < minY) minY = y; if (y > maxY) maxY = y;
        }
      }
    q.UnlockBits(d);
    return new int[] { minX, minY, maxX, maxY };
  }
}
'@
Add-Type -TypeDefinition $hilfe -ReferencedAssemblies System.Drawing

# ---------------------------------------------------------------------------
# Quelle laden und das Wappen darin finden
# ---------------------------------------------------------------------------
$src = [System.Drawing.Image]::FromFile($Quelle)
$QW = $src.Width; $QH = $src.Height
$roh = New-Object System.Drawing.Bitmap($QW, $QH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g0 = [System.Drawing.Graphics]::FromImage($roh); $g0.DrawImage($src, 0, 0, $QW, $QH); $g0.Dispose(); $src.Dispose()
"Quelle: $Quelle ($QW x $QH)"

$wappen = [Wappen]::AlsMaske($roh, $true)
$bb = [Wappen]::Inhalt($wappen, 40)
$ix = $bb[0]; $iy = $bb[1]; $iw = $bb[2]-$bb[0]+1; $ih = $bb[3]-$bb[1]+1
"Wappen: ($ix,$iy) $iw x $ih"

# ---------------------------------------------------------------------------
# Radgeometrie -- als Anteil der Wappenflaeche notiert, damit sie unabhaengig
# von der Aufloesung der Quelle gilt.
#
# Gemessen ueber ein Radialprofil (Anteil dunkler Pixel je Radius, gemittelt
# ueber die Winkel der linken Haelfte) an der Vorlage in 1290 px Breite:
#   r   0.. 45  hell            Nabenmitte
#   r  47.. 87  100 % dunkel    Nabe, hier laufen die Speichen zusammen
#   r  87..315  wechselnd       Speichen und Zwischenraeume
#   r 315..405  100 % dunkel    Aussenring
#   r 410..455  hell            Abstand zur Bogenschrift
#   ab r 460    wechselnd       "HEILBAD HEILIGENSTADT" -- bleibt draussen
# ---------------------------------------------------------------------------
$RAD_CX = 0.5000    # Schildmitte
$RAD_CY = 0.4463    # Anteil der Wappenhoehe
$RAD_R  = 0.3178    # Anteil der Wappenbreite (410/1290, knapp hinter dem Ring)

$cx = $ix + $RAD_CX * $iw
$cy = $iy + $RAD_CY * $ih
$rr = $RAD_R * $iw
"Rad   : Mitte ({0:N0},{1:N0})  r={2:N0}" -f $cx, $cy, $rr

# ---------------------------------------------------------------------------
# 1) BADGE -- Schildsilhouette mit ausgestanztem Rad
#
# Fuer ein Android-Badge zaehlt nur die Silhouette: das System faerbt alle
# sichtbaren Pixel weiss. Das ganze Wappen wuerde daraus einen Klecks machen --
# die Schriftbaender loesen sich bei 24 px auf. Es bleiben deshalb die gefuellte
# Schildform und das Rad als Aussparung; der Kontrast zwischen beiden traegt
# auch in der Statusleiste.
# ---------------------------------------------------------------------------
$G = 96; $RAND = 4; $SS = 4
$GG = $G * $SS; $RANDG = $RAND * $SS

# Aeussere Schildform: Pfad 1 aus logo.svg, Kommando fuer Kommando uebernommen.
$VB_W = 198.425; $VB_H = 226.7719
$nutz = $GG - 2 * $RANDG
$s = [Math]::Min($nutz / $VB_W, $nutz / $VB_H)
$offX = ($GG - $VB_W * $s) / 2
$offY = ($GG - $VB_H * $s) / 2
function P($x, $y) { New-Object System.Drawing.PointF(([float]($offX + $x * $s)), ([float]($offY + $y * $s))) }

$pfad = New-Object System.Drawing.Drawing2D.GraphicsPath
$pfad.AddBezier((P 98.9821 225.654), (P 76.7711 218.781), (P 51.3991 207.64),  (P 31.6178 177.124))
$pfad.AddBezier((P 31.6178 177.124),(P 20.3893 159.802), (P 12.1491 137.721), (P 7.1285 111.495))
# ⚠️ Die negative Zahl MUSS geklammert werden -- ohne Klammern liest PowerShell
# "-0.3822" als Parameternamen und der Punkt landet an der falschen Stelle.
$pfad.AddBezier((P 7.1285 111.495), (P 1.3004 81.0698),  (P (-0.3822) 44.1459), (P 2.1286 1.7504))
$pfad.AddLine((P 2.1286 1.7504), (P 2.1735 0.9999))
$pfad.AddLine((P 2.1735 0.9999), (P 196.252 0.9999))
$pfad.AddLine((P 196.252 0.9999), (P 196.297 1.7509))
$pfad.AddBezier((P 196.297 1.7509),(P 198.807 44.1459),(P 197.125 81.0698), (P 191.297 111.495))
$pfad.AddBezier((P 191.297 111.495),(P 186.276 137.721),(P 178.036 159.802),(P 166.807 177.124))
$pfad.AddBezier((P 166.807 177.124),(P 147.026 207.64),(P 121.654 218.781), (P 99.443 225.654))
$pfad.AddLine((P 99.443 225.654), (P 99.2125 225.725))
$pfad.CloseFigure()

# Vierfach gerendert und am Ende verkleinert: das glaettet die Speichen, die
# bei 24 px sonst ausfransen.
$schild = New-Object System.Drawing.Bitmap($GG, $GG, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gs = [System.Drawing.Graphics]::FromImage($schild)
$gs.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gs.Clear([System.Drawing.Color]::Transparent)
$gs.FillPath([System.Drawing.Brushes]::White, $pfad)
$gs.Dispose(); $pfad.Dispose()

# Radmaske aus der linken Wappenhaelfte greifen
$radQuelle = New-Object System.Drawing.Bitmap($QW, $QH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$grq = [System.Drawing.Graphics]::FromImage($radQuelle); $grq.DrawImage($roh, 0, 0, $QW, $QH); $grq.Dispose()
$radMaske = [Wappen]::AlsMaske($radQuelle, $false)
$radMaske = [Wappen]::LinkeKreisHaelfte($radMaske, $cx, $cy, $rr)
$radQuelle.Dispose()

# Das Rad an dieselbe Stelle setzen, die es im Wappen einnimmt. Der Schildpfad
# steht in viewBox-Koordinaten, also die Anteile darauf umrechnen.
$radB = New-Object System.Drawing.Bitmap($GG, $GG, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$grb = [System.Drawing.Graphics]::FromImage($radB)
$grb.Clear([System.Drawing.Color]::Transparent)
$grb.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$grb.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$zcx = $offX + $RAD_CX * $VB_W * $s
$zcy = $offY + $RAD_CY * $VB_H * $s
$zr  = $RAD_R * $VB_W * $s
$qRect = New-Object System.Drawing.RectangleF([float]($cx-$rr), [float]($cy-$rr), [float]$rr, [float](2*$rr))
$zRect = New-Object System.Drawing.RectangleF([float]($zcx-$zr), [float]($zcy-$zr), [float]$zr, [float](2*$zr))
$grb.DrawImage($radMaske, $zRect, $qRect, [System.Drawing.GraphicsUnit]::Pixel)
# rechte Haelfte durch Spiegelung an der Schildachse
$gespiegelt = $radMaske.Clone()
$gespiegelt.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
$qRectR = New-Object System.Drawing.RectangleF([float]($QW-$cx), [float]($cy-$rr), [float]$rr, [float](2*$rr))
$zRectR = New-Object System.Drawing.RectangleF([float]$zcx, [float]($zcy-$zr), [float]$zr, [float](2*$zr))
$grb.DrawImage($gespiegelt, $zRectR, $qRectR, [System.Drawing.GraphicsUnit]::Pixel)
$grb.Dispose(); $radMaske.Dispose(); $gespiegelt.Dispose()

[Wappen]::Ausstanzen($schild, $radB)
$radB.Dispose()

$badge = New-Object System.Drawing.Bitmap($G, $G, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gb = [System.Drawing.Graphics]::FromImage($badge)
$gb.Clear([System.Drawing.Color]::Transparent)
$gb.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gb.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gb.DrawImage($schild, 0, 0, $G, $G)
$gb.Dispose(); $schild.Dispose()
$zielBadge = Join-Path $Ordner "badge-96.png"
$badge.Save($zielBadge, [System.Drawing.Imaging.ImageFormat]::Png)
"Geschrieben: $zielBadge ($G x $G)"

# ---------------------------------------------------------------------------
# 2) PUSH-ICON -- Wappen weiss auf dunklem Grund
#
# Hier zaehlen die Farben wirklich, das Bild wird nicht eingefaerbt. Chrome
# schneidet es rund zu, deshalb reichlich Rand und ein vollflaechiger Grund --
# sonst faellt die Schildspitze weg.
# ---------------------------------------------------------------------------
$I = 192; $IRAND = 22
$inutz = $I - 2 * $IRAND
$si = [Math]::Min($inutz / $iw, $inutz / $ih)
$iwz = [int][Math]::Round($iw * $si); $ihz = [int][Math]::Round($ih * $si)
$ixz = [int][Math]::Round(($I - $iwz) / 2); $iyz = [int][Math]::Round(($I - $ihz) / 2)

$icon = New-Object System.Drawing.Bitmap($I, $I, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gi = [System.Drawing.Graphics]::FromImage($icon)
$gi.Clear([System.Drawing.Color]::FromArgb(255, 26, 28, 35))
$gi.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gi.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$qi = New-Object System.Drawing.Rectangle($ix, $iy, $iw, $ih)
$zi = New-Object System.Drawing.Rectangle($ixz, $iyz, $iwz, $ihz)
$gi.DrawImage($wappen, $zi, $qi, [System.Drawing.GraphicsUnit]::Pixel)
$gi.Dispose()
$zielIcon = Join-Path $Ordner "push-icon-192.png"
$icon.Save($zielIcon, [System.Drawing.Imaging.ImageFormat]::Png)
"Geschrieben: $zielIcon ($I x $I)"

# ---------------------------------------------------------------------------
# Vorschau -- weiss auf transparent ist auf hellem Grund unsichtbar. Diese
# Datei legt beides auf dunklen Grund und zeigt das Badge zusaetzlich in
# 24 px: so klein steht es in der Statusleiste, und nur dort entscheidet sich,
# ob die Form taugt. Sie gehoert nicht ins Repo (siehe .gitignore).
# ---------------------------------------------------------------------------
$vor = New-Object System.Drawing.Bitmap(360, 150)
$gv = [System.Drawing.Graphics]::FromImage($vor)
$gv.Clear([System.Drawing.Color]::FromArgb(24, 26, 32))
$gv.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gv.DrawImage($badge, 20, 20, 96, 96)
$gv.DrawImage($badge, 140, 56, 24, 24)
$gv.DrawImage($icon, 200, 20, 96, 96)
$gv.DrawImage($icon, 310, 56, 24, 24)
$fm = New-Object System.Drawing.Font("Segoe UI", 8)
$gr = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 155, 165))
$gv.DrawString("Badge 96 / 24 px", $fm, $gr, 20, 122)
$gv.DrawString("Push-Icon 96 / 24 px", $fm, $gr, 200, 122)
$gv.Dispose()
$vorschau = Join-Path $Ordner "push-bilder.vorschau.png"
$vor.Save($vorschau, [System.Drawing.Imaging.ImageFormat]::Png)
$vor.Dispose()
"Vorschau:    $vorschau"

$badge.Dispose(); $icon.Dispose(); $wappen.Dispose(); $roh.Dispose()
