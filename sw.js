// Minimaler Service Worker, nur damit Chrome die Tools-Uebersicht als
// installierbare PWA erkennt. Muster uebernommen aus Materialliste/sw.js.
//
// ⚠️ KEIN CACHING, und das ist Absicht. Dieser Worker hat Geltungsbereich "/"
// und wird deshalb bei jedem Aufruf JEDER App der Flotte aktiv. Wer hier
// Caching einbaut, legt eine zweite Cache-Ebene neben die ?v=-Bumps in den
// index.html-Dateien -- danach liefert der Browser alte app.js aus, ohne dass
// ein Versions-Bump noch hilft. Der leere fetch-Handler laesst jede Anfrage
// unveraendert ans Netz durch; der Worker existiert ausschliesslich, weil
// Chrome ihn als Installationsvoraussetzung verlangt.
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));
self.addEventListener("fetch", () => {});

// ---------------------------------------------------------------------------
// Push-Nachrichten (seit 2026-08-03)
//
// Diese beiden Handler haben mit Caching NICHTS zu tun -- der fetch-Handler
// oben bleibt leer und die ?v=-Bumps der Flotte bleiben wirksam. Sie stehen
// hier, weil ein Push-Abo an den Service Worker gebunden ist und dieser wegen
// scope "/" der einzige ist, der fuer die ganze Flotte gilt.
//
// Entwurf: ToolsUebersicht/docs/superpowers/specs/2026-08-03-push-nachrichten-design.md
// ---------------------------------------------------------------------------

// ⚠️ Es MUSS bei jedem push-Ereignis eine Nachricht angezeigt werden. Zeigt der
// Worker nichts, blendet der Browser von sich aus "Diese Website wurde im
// Hintergrund aktualisiert" ein -- schlechter als jede eigene Meldung. Deshalb
// gibt es fuer jedes Feld einen Rueckfallwert.
self.addEventListener("push", (event) => {
  let daten = {};
  try { daten = event.data ? event.data.json() : {}; } catch (_) { daten = {}; }

  const titel = daten.titel || "SC 1911";
  const optionen = {
    // Das Bild neben Titel und Text der aufgeklappten Meldung. Bewusst eine
    // eigene Datei und NICHT icon-192.png: das steht in manifest.json und ist
    // zugleich das App-Icon auf dem Startbildschirm -- dort bleibt das farbige
    // Wappen auf hellem Vereinsblau, die Nachricht traegt seit dem 2026-08-07
    // das weisse Wappen auf der Logofarbe #282562. Chrome schneidet es rund zu,
    // deshalb hat es ringsum Rand -- ohne den faellt die Schildspitze weg.
    //
    // Quelle ist logo-weiss.svg, erzeugt mit push-icon-rendern.html. Das
    // PowerShell-Skript kann diese Datei NICHT erzeugen: GDI+ rendert kein SVG.
    icon: "/push-icon-192.png?v=1.0",
    // Das kleine Symbol in der Android-Statusleiste. Ohne dieses Feld zeigt
    // Chrome dort eine generische Glocke.
    //
    // ⚠️ Android zeichnet das Badge als reine weisse Silhouette: alle
    // sichtbaren Pixel werden weiss, jedes Detail geht verloren. Es ist
    // deshalb NICHT das ganze Wappen -- die beiden Schriftbaender loesen sich
    // bei 24 px in Grauschleier auf --, sondern die gefuellte Schildform mit
    // dem Rad als Aussparung. Der Kontrast zwischen Flaeche und Loch traegt
    // auch in dieser Groesse. Erzeugt mit push-bilder-rendern.ps1; wer es
    // ersetzt, muss die Form in 24 px pruefen, denn so klein steht sie da.
    //
    // ⚠️ Ein Push-Ereignis weckt den Service Worker auf, loest aber KEINEN
    // Update-Check aus. Wer dieses Feld aendert, sieht die Wirkung erst,
    // nachdem die App einmal geoeffnet wurde -- bis dahin laeuft auf dem Geraet
    // der alte Worker weiter und zeigt den alten Stand.
    badge: "/badge-96.png?v=1.0",
    data: { ziel: daten.ziel || "/ToolsUebersicht/" }
    // Bewusst KEIN "tag": mit Tag ersetzt jede neue Nachricht die vorherige.
    // Drei zugewiesene Aufgaben sollen aber drei Meldungen sein, nicht eine.
  };
  event.waitUntil(self.registration.showNotification(titel, optionen));
});

// ⚠️ Ein offenes Fenster wird fokussiert statt ein zweites zu oeffnen. Ohne das
// sammeln sich in der abgelegten App mehrere Ansichten derselben Seite, weil
// openWindow() dort jedes Mal eine neue aufmacht.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const ziel = (event.notification.data && event.notification.data.ziel) || "/ToolsUebersicht/";
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((fenster) => {
      for (let i = 0; i < fenster.length; i++) {
        const f = fenster[i];
        let pfad = "";
        try { pfad = new URL(f.url).pathname; } catch (_) { pfad = ""; }
        if (pfad.indexOf(ziel) === 0 && typeof f.focus === "function") return f.focus();
      }
      if (typeof self.clients.openWindow === "function") return self.clients.openWindow(ziel);
      return undefined;
    })
  );
});
