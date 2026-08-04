# sc1911heiligenstadt.github.io

Wurzelverzeichnis von `https://sc1911heiligenstadt.github.io/`. Enthält **keine Anwendung** —
nur die Dateien, die auf der Wurzel liegen müssen, damit sich die Vereinswerkzeuge
als App auf dem Startbildschirm ablegen lassen.

## Warum ein eigenes Repo

Ein Web-App-Manifest kann keinen Geltungsbereich oberhalb seines eigenen
Verzeichnisses beanspruchen. Ein Manifest unter `/ToolsUebersicht/` würde deshalb
nur diesen Pfad umfassen — jeder Klick auf eine Kachel (`/vereinskalender/`,
`/Vereinsaufgaben/`, …) führte aus der installierten App heraus in den Browser,
auf dem iPhone in ein eigenes Safari-Fenster. Damit die ganze Flotte innerhalb
der App-Hülle bleibt, müssen Manifest und Service Worker auf der Wurzel liegen.

## Dateien

| Datei | Zweck |
|---|---|
| `manifest.json` | `scope: "/"` über die ganze Flotte, `start_url` zeigt auf `/ToolsUebersicht/` |
| `sw.js` | Service Worker: **cacht nichts** (siehe Warnung unten), zeigt Push-Nachrichten an |
| `icon-192.png`, `icon-512.png` | Startbildschirm-Icons |
| `icon-maskable-512.png` | Android-Variante mit Sicherheitsrand |
| `apple-touch-icon.png` | 180×180, iOS ignoriert die Manifest-Icons |
| `favicon.png` | Browser-Tab |
| `logo.svg` | Vereinswappen als Vektor, Quelle der farbigen Icons |
| `logo-monochrom.png` | Wappen einfarbig, Quelle der beiden Push-Bilder |
| `badge-96.png` | Symbol in der Android-Statusleiste |
| `push-icon-192.png` | Bild in der aufgeklappten Nachricht |
| `push-bilder-rendern.ps1` | erzeugt die beiden Push-Bilder reproduzierbar |
| `index.html` | Weiterleitung auf `/ToolsUebersicht/` |

## Icons

Alle Icons zeigen seit 2026-08-03 das **echte Vereinswappen**, gerendert aus
`logo.svg` auf Vereinsblau `#1a56a0` (= `theme_color`). Bis dahin war es ein mit
GDI+ gezeichneter Platzhalter (weißes Schild, blaues „SC"), weil das Wappen nur
als 223 × 211-px-Rastergrafik vorlag und bei Icon-Größe matschte.

`logo.svg` ist aus der EPS-Vorlage des Vereins erzeugt (Adobe Illustrator, reiner
Vektor: 51 Flächen, zwei Farben — Weiß und `#282562`). Wer die Icons neu bauen
will, rendert aus dieser Datei, nicht aus einem PNG.

`icon-maskable-512.png` zeigt das Wappen auf 60 % der Kantenlänge. Das ist keine
gegriffene Zahl: Androids Safe Zone ist ein Kreis mit 80 % Durchmesser, und für
ein Wappen im Seitenverhältnis 0,875 gilt
`√((0,875·h/2)² + (h/2)²) = 0,664·h ≤ 0,4·512` — also `h ≤ 308 px`. Bei mehr
schneidet der Kreiszuschnitt die oberen Schildecken ab.

## Die Bilder der Push-Nachricht

Eine Push-Nachricht zeigt **zwei verschiedene** Bilder, und sie folgen
gegensätzlichen Regeln:

`push-icon-192.png` steht neben Titel und Text der aufgeklappten Meldung und
wird farbtreu dargestellt. Chrome schneidet es rund zu, deshalb hat es ringsum
Rand — ohne den fiele die Schildspitze weg.

`badge-96.png` steht in der Statusleiste. ⚠️ **Android färbt dort alle sichtbaren
Pixel weiß** und liest nur die Transparenz — Farben und Binnenzeichnung gehen
restlos verloren. Deshalb ist es nicht das ganze Wappen: dessen Schriftbänder
(„1. SC 1911", „HEILBAD HEILIGENSTADT") lösen sich bei 24 px in Grauschleier
auf. Es bleiben die gefüllte Schildform und das Rad als **Aussparung** — der
Kontrast zwischen Fläche und Loch trägt auch in dieser Größe.

Beide entstehen aus `logo-monochrom.png` über `push-bilder-rendern.ps1`, nicht
aus `logo.svg`. Grund: das SVG ist zweifarbig separiert — die linke Schildhälfte
ist hell mit dunklen Formen, die rechte umgekehrt. Das Rad ist darin mal
gefüllter Pfad und mal Aussparung, aus seinen 51 Pfaden lässt sich „nur das Rad"
nicht herausgreifen. Das Skript nimmt stattdessen die **linke** Radhälfte der
gerasterten Vorlage, wo das Material durchgehend dunkel auf hell liegt, und
spiegelt sie — das Rad ist achsensymmetrisch. Seine Lage steht als Anteil der
Wappenfläche im Skript, gemessen über ein Radialprofil.

⚠️ Wer ein Push-Bild austauscht, **prüft das Badge in 24 px** — das Skript legt
dafür eine Vorschau daneben — und zieht den `?v=`-Buster in `sw.js` mit.

⚠️ Eine Änderung wirkt auf dem Gerät erst nach dem nächsten Öffnen der App: ein
Push weckt den Service Worker zwar, löst aber **keinen** Update-Check aus.

## ⚠️ Der Service Worker darf nicht cachen

`sw.js` hat Geltungsbereich `/` und wird damit bei jedem Aufruf **jeder** App der
Flotte aktiv. Solange sein `fetch`-Handler leer ist, greift er nirgends ein.

Wer dort Caching einbaut, legt eine zweite Cache-Ebene neben die `?v=`-Bumps in den
`index.html`-Dateien aller Apps — danach liefert der Browser alte `app.js` aus, und
ein Versions-Bump hilft nicht mehr. Der Worker existiert ausschließlich, weil Chrome
ihn als Installationsvoraussetzung verlangt.

Die eigenständigen PWAs der Flotte (Materialliste, spielertool-test, kassenbuch,
agelan, familien-quartett, spiele/\*) registrieren eigene Service Worker mit
engerem Geltungsbereich. Bei Überschneidung gewinnt der speziellere, es gibt
keinen Konflikt.

## Der Knopf liegt woanders

Registriert wird der Service Worker aus `ToolsUebersicht/app.js`, dort sitzt auch
der Knopf „📲 Als App ablegen". Dieses Repo enthält nur die Dateien, kein Verhalten.
