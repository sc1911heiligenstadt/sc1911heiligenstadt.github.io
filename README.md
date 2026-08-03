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
| `sw.js` | Service Worker, **bewusst leer** — siehe Warnung unten |
| `icon-192.png`, `icon-512.png` | Startbildschirm-Icons |
| `icon-maskable-512.png` | Android-Variante mit Sicherheitsrand |
| `apple-touch-icon.png` | 180×180, iOS ignoriert die Manifest-Icons |
| `favicon.png` | Browser-Tab |
| `logo.svg` | Vereinswappen als Vektor, Quelle aller Icons |
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
