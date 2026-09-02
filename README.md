# 🏠 Wurzel der Vereins-Werkzeuge

Die Wurzel der Website: App-Manifest, Symbole und Service Worker mit Geltungsbereich `/`. Nur dadurch lässt sich die ganze Flotte als eine App auf dem Startbildschirm ablegen, ohne dass ein Klick auf eine Kachel wieder herausführt.

**➡️ [Zu den Vereins-Werkzeugen](https://sc1911heiligenstadt.github.io/ToolsUebersicht/)**

Hier liegt **keine App**, sondern das, was für alle Apps zusammen gilt. Wer ein
Werkzeug sucht, ist in der [Tools-Übersicht](https://sc1911heiligenstadt.github.io/ToolsUebersicht/)
richtig.

## Was hier liegt

| Datei | Wofür |
|---|---|
| `manifest.json` | Das App-Manifest der Flotte: Name, Farben, Startadresse `/ToolsUebersicht/` und Geltungsbereich `/`. |
| `sw.js` | Der Service Worker für die ganze Flotte — Installierbarkeit und Push-Nachrichten. |
| `index.html` | Die Startseite dieser Adresse. Sie leitet auf die Tools-Übersicht weiter. |
| `kassenbuch/index.html` | Fängt die alte Adresse des Kassenbuchs ab und leitet auf den neuen Ort weiter. |
| `push-icon-rendern.html` | Hilfsseite zum Erzeugen des Push-Symbols — kein Teil der Website. |
| Symbole (`*.png`, `*.svg`) | App-Symbol, Favicon, Wappen und die Bilder der Push-Nachricht. |
| `push-bilder-rendern.ps1` | Erzeugt das Badge der Push-Nachricht aus dem monochromen Wappen. |

## Der Service Worker

`sw.js` hat Geltungsbereich `/` und wird deshalb beim Aufruf **jeder** App der
Flotte aktiv. Er tut bewusst zwei Dinge und sonst nichts:

1. **Er existiert**, damit der Browser die Tools-Übersicht als installierbare
   App akzeptiert.
2. **Er nimmt Push-Nachrichten entgegen**, zeigt sie an und öffnet beim
   Antippen die passende Seite — ein bereits offenes Fenster wird dabei nach
   vorn geholt, statt ein zweites aufzumachen.

> ⚠️ **Kein Caching, und das ist Absicht.** Weil dieser Worker für die ganze
> Flotte gilt, läge ein Cache hier quer zu den `?v=`-Stempeln in den einzelnen
> Apps: Der Browser lieferte dann alte Dateien aus, obwohl die App ihre Version
> längst hochgezählt hat. Der Worker lässt jede Anfrage unverändert ans Netz
> durch.

## Die Symbole

Es sind absichtlich mehrere, weil sie verschieden aussehen müssen:

- **`icon-192.png`, `icon-512.png`, `icon-maskable-512.png`** — das App-Symbol
  auf dem Startbildschirm. Farbiges Wappen auf hellem Vereinsblau. Diese drei
  stehen in `manifest.json`.
- **`favicon.png`, `apple-touch-icon.png`** — das Symbol im Browser-Tab und auf
  dem iPhone-Startbildschirm.
- **`push-icon-192.png`** — das Bild neben Titel und Text einer Push-Nachricht.
  Weißes Wappen auf der Logofarbe, mit Rand ringsum, weil der Browser es rund
  zuschneidet. Entsteht aus `logo-weiss.svg` über `push-icon-rendern.html`.
- **`badge-96.png`** — das kleine Symbol in der Android-Statusleiste. Android
  färbt es vollständig weiß ein, deshalb ist es nur die Schildform mit dem Rad
  als Aussparung und nicht das ganze Wappen.
- **`logo.svg`, `logo-weiss.svg`, `logo-monochrom.png`** — das Vereinswappen als
  Vorlage. `logo.svg` binden die Apps der Flotte direkt von hier ein.

Alle Symbol-Adressen tragen einen `?v=`-Stempel. Wird ein Bild ersetzt, muss der
Stempel mit hochgezählt werden — an **allen drei Stellen**: `index.html`,
`manifest.json` und `sw.js`. Sonst zeigen bereits installierte Geräte weiter das
alte Bild.

## Weiterleitungen

- `/` leitet ohne JavaScript auf `/ToolsUebersicht/` weiter, damit die nackte
  Adresse nicht ins Leere läuft.
- `/kassenbuch/` fängt die alte Adresse des Kassenbuchs ab. Das Kassenbuch ist
  in den privaten Bereich umgezogen; GitHub Pages leitet nach einem solchen
  Umzug **nicht** von selbst um. Die Seite meldet zuerst den alten Service
  Worker ab — sonst bekäme eine installierte App weiter die alte
  zwischengespeicherte Fassung zu sehen — und springt danach pfadgleich auf die
  neue Adresse.

## Technik

Vanilla JavaScript ohne Build-Schritt — die Dateien werden so ausgeliefert, wie sie im Repo liegen. Veröffentlicht über GitHub Pages auf der Wurzel der Adresse.

> ⚠️ Nicht zu verwechseln mit `tecko1985.github.io`, der Wurzel des privaten
> Bereichs. Das ist ein eigenes Repo.

---

Ein Werkzeug des 1. SC 1911 Heiligenstadt. Alle Werkzeuge auf einen Blick: [Tools-Übersicht](https://sc1911heiligenstadt.github.io/ToolsUebersicht/) · Erklärungen im [Toolbox Wiki](https://sc1911heiligenstadt.github.io/Vereinswiki/).
