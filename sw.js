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
