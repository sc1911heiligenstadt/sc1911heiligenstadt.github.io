# tecko1985.github.io

Wurzelverzeichnis von `https://tecko1985.github.io/`. Enthält **keine Anwendung** —
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
| `index.html` | Weiterleitung auf `/ToolsUebersicht/` |

Die Icons sind gezeichnet, nicht aus dem Vereinswappen skaliert — das liegt nur in
223 × 211 px vor und würde bei Icon-Größe matschen. Erzeugt mit GDI+, Vereinsblau
`#1a56a0`.

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
